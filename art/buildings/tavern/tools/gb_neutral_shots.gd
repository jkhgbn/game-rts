extends SceneTree
## Task G-B neutral (docs/art/gb_neutral_buildings.md): windowed shots + fps of the neutral / shared buildings on the
## real skirmish map (Crown Hollow): a tavern, a trading post, the two guild houses, the three capture points (one
## watchtower owned by the player, one well owned by the enemy, a shrine awake) and a Fire Stables beside the player
## keep. Bot off, fog off, HUD hidden. Saves docs/art/lab/gb_neutral/shots/<tag>_q<q>_<shot>.png, then measures frame
## times over the map centre at zoom 30.
## Windowed only (one tier per run: the art reads GameSettings.effective_graphics_quality() in _ready):
##   tools\godot_run.ps1 --path . -s res://art/buildings/tavern/tools/gb_neutral_shots.gd --resolution 1920x1080
##       --quit-after 60000 -- --gfx=high tag=before [perf=0] [shots=0] [frames=600] [only=tavern_z10,...] [pause=1]
## The match is unpaused (the STR / INT pick pauses it at start) so owner blends and lights animate; pause=1 keeps it
## paused (the first G-B "before" run was taken paused: use pause=1 for a like-for-like fps against it).

const OUT_DIR := "res://docs/art/lab/gb_neutral/shots"
const ZOOMS: Array = [["z10", 10.0], ["z30", 30.0]]
const FOCI: Array = ["tavern", "post", "den", "lodge", "tower", "well", "shrine", "stables"]

var main: Node
var _tag := "before"
var _perf := true
var _shots := true
var _frames := 600
var _only := ""
var _keep_paused := false   # pause=1: leave the match paused (the first "before" run was, for a like-for-like fps)
var _cam: Node3D
var _focus := {}
var _yaw := {}
var _results := {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var k := arg.get_slice("=", 0)
		var v := arg.substr(k.length() + 1)
		match k:
			"tag": _tag = v
			"perf": _perf = v != "0"
			"shots": _shots = v != "0"
			"frames": _frames = int(v)
			"only": _only = v
			"pause": _keep_paused = v != "0"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	paused = _keep_paused   # the STR / INT pick pauses the match at start: the art must animate (owner blends, flicker)
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_cam = main.get(&"camera_rig")
	_cam.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var q: int = GameSettings.effective_graphics_quality()
	print("GBN tag=%s size=%s tier=%d" % [_tag, str(root.get_visible_rect().size), q])
	GameSettings.apply_graphics(self, q)
	await _stage()
	if _shots:
		var list: Array = []
		for f: String in FOCI:
			for z: Array in ZOOMS:
				list.append(["%s_%s" % [f, z[0]], f, z[1]])
		list.append(["centre_z50", "centre", 50.0])
		for s: Array in list:
			if _only != "" and not _only.split(",").has(s[0]):
				continue
			if not _focus.has(s[1]):
				print("GBN skip %s (no %s)" % [s[0], s[1]])
				continue
			paused = _keep_paused
			_cam.call(&"fly_to", _focus[s[1]], float(_yaw.get(s[1], 0.0)), s[2], 0.0)
			for i in 50:
				await process_frame
			await RenderingServer.frame_post_draw
			var img: Image = root.get_texture().get_image()
			var path := "%s/%s_q%d_%s.png" % [OUT_DIR, _tag, q, s[0]]
			img.save_png(ProjectSettings.globalize_path(path))
			print("saved %s" % path)
	if _perf:
		await _measure(q)
		var r: Array = _results[q]
		print("GBN PERF q=%d tag=%s avg_fps=%.1f low1_fps=%.1f gpu_ms_med=%.2f draws=%d" % [q, _tag, r[0], r[1], r[2], r[3]])
	print("GBN DONE")
	quit()


func _nearest(group: StringName, to: Vector3, pred: Callable = Callable()) -> Node3D:
	var best: Node3D = null
	var bd := INF
	for n: Node in get_nodes_in_group(group):
		if not (n is Node3D):
			continue
		if pred.is_valid() and not bool(pred.call(n)):
			continue
		var d: float = (n as Node3D).global_position.distance_to(to)
		if d < bd:
			bd = d
			best = n as Node3D
	return best


## Picks one of each building, puts the capture points in their show states and adds a Fire Stables by the keep.
func _stage() -> void:
	var keep: Node3D = null
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and int(b.get(&"team")) == 0:
			keep = b as Node3D
	var kp: Vector3 = keep.global_position if keep else Vector3.ZERO
	var tav := _nearest(&"taverns", kp)
	if tav:
		_focus["tavern"] = tav.global_position
	var post := _nearest(&"trade_posts", kp)
	if post:
		_focus["post"] = post.global_position
	var den := _nearest(&"guilds", kp, func(n: Node) -> bool: return String(n.name).begins_with("MagpieDen"))
	if den:
		_focus["den"] = den.global_position
	var lodge := _nearest(&"guilds", kp, func(n: Node) -> bool: return String(n.name).begins_with("GreywaterLodge"))
	if lodge:
		_focus["lodge"] = lodge.global_position
	# Freeze the capture service (units walking by would capture / neutralise between shots).
	for svc: Node in get_nodes_in_group(&"capture_points_service"):
		svc.process_mode = Node.PROCESS_MODE_DISABLED
	var tower := _nearest(&"capture_points", kp, func(n: Node) -> bool: return n.get(&"kind") == &"watchtower")
	if tower:
		_focus["tower"] = tower.global_position
		tower.call(&"set_owner_team", 0)
		(tower.call(&"model") as Node).call(&"set_owner_color", Color(0.25, 0.45, 1.0))
	var well := _nearest(&"capture_points", kp, func(n: Node) -> bool: return n.get(&"kind") == &"well")
	if well:
		_focus["well"] = well.global_position
		well.call(&"set_owner_team", 1)
		(well.call(&"model") as Node).call(&"set_owner_color", Color(0.9, 0.2, 0.2))
	var shrine := _nearest(&"capture_points", kp, func(n: Node) -> bool: return n.get(&"kind") == &"shrine")
	if shrine:
		_focus["shrine"] = shrine.global_position
		shrine.call(&"wake")
	_focus["centre"] = Vector3.ZERO
	var grid: Node = main.get(&"build_grid")
	if keep and grid:
		var toward: Vector3 = (Vector3.ZERO - kp)
		toward.y = 0.0
		toward = toward.normalized()
		var side: Vector3 = Vector3.UP.cross(toward).normalized()
		var ty: BuildingType = load("res://data/buildings/fire_stables.tres") as BuildingType
		if ty:
			var want: Vector3 = kp + side * -16.0 + toward * 4.0
			var spot: Vector3 = grid.call(&"find_spot", ty, want, 0, 6)
			if spot == Vector3.INF or not spot.is_finite():
				spot = want
			var st: Node3D = grid.call(&"spawn_complete", ty, spot, 0) as Node3D
			if st:
				_focus["stables"] = st.global_position
	for i in 60:
		await process_frame
	var lights := 0
	var lit := 0
	for n: Node in root.find_children("*", "NeutralFlickerLight", true, false):
		lights += 1
		if (n as Light3D).visible:
			lit += 1
	print("GBN lights=%d visible=%d" % [lights, lit])
	for cp: Node in get_nodes_in_group(&"capture_points"):
		var m: Node = cp.call(&"model")
		print("GBN point %s kind=%s at %s owner=%s art_owned=%s" % [cp.name, cp.get(&"kind"), (cp as Node3D).global_position,
			cp.get(&"owner_team"), m.call(&"get_owner_color") if m and m.has_method(&"get_owner_color") else "?"])


func _measure(q: int) -> void:
	paused = _keep_paused
	_cam.call(&"fly_to", _focus.get("tavern", Vector3.ZERO), 0.0, 30.0, 0.0)
	for i in 90:
		await process_frame
	var times: Array[float] = []
	var gpu: Array[float] = []
	var vp_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var last := Time.get_ticks_usec()
	for i in _frames:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - last))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp_rid))
		last = now
	gpu.sort()
	var total := 0.0
	for x: float in times:
		total += x
	times.sort()
	var p99: float = times[maxi(int(times.size() * 0.99) - 1, 0)]
	_results[q] = [1e6 * times.size() / total, 1e6 / p99, gpu[gpu.size() / 2],
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
