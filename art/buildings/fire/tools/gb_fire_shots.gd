extends SceneTree
## Task G-B Fire: windowed shots + fps of a Fire base on the real skirmish map (docs/art/gb_fire_buildings.md), adapted
## from the Shadow tool. The player (Fire, team 0) base gets every Fire building around its keep: Ember Hall x2 (one at
## 40 % HP), Hearths (one at 18 %), Ember Spires, Ember Stables, Ember Bazaar, a Hall site at 55 %, and three extra Fire
## Keeps at tier 2 / tier 3 / upgrading. Bot off, fog off, HUD hidden. Saves docs/art/lab/gb_fire/<tag>_q<q>_<shot>.png,
## then measures frame times over the base at zoom 30 per tier.
## Windowed only:
##   tools\godot_run.ps1 --path . -s res://art/buildings/fire/tools/gb_fire_shots.gd --resolution 1920x1080
##       --quit-after 60000 -- --gfx=high tag=before [perf=0] [shots=0] [frames=600] [only=base_z30]
## One tier per run (the art reads GameSettings.effective_graphics_quality() in _ready, and --gfx is the only override).

const OUT_DIR := "res://docs/art/lab/gb_fire/shots"
const SHOTS: Array = [
	# [name, zoom, focus key] focus key: "keep" = the real keep, "base" = the base centre, "tiers" = the tier row,
	# "hall" = the damaged hall
	["base_z10", 10.0, "keep"],
	["base_z30", 30.0, "base"],
	["base_z50", 50.0, "base"],
	["tiers_z30", 30.0, "tiers"],
	["tiers_z15", 15.0, "tiers"],
	["dmg_z10", 10.0, "hall"],
	["small_z10", 10.0, "small"],
]

var main: Node
var _tag := "before"
var _perf := true
var _shots := true
var _frames := 600
var _only := ""
var _cam: Node3D
var _focus := {}
var _spawned: Array[Node] = []
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
			"legacy": FireBuildingLook.legacy = v != "0"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	main.set(&"enemy_kingdom", &"shadow")
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
	print("GBF tag=%s size=%s tier=%d" % [_tag, str(root.get_visible_rect().size), GameSettings.effective_graphics_quality()])
	for q: int in [GameSettings.effective_graphics_quality()]:
		GameSettings.apply_graphics(self, q)
		await _stage()
		if _shots:
			for s: Array in SHOTS:
				if _only != "" and not _only.split(",").has(s[0]):
					continue
				paused = false
				_cam.call(&"fly_to", _focus.get(s[2], _focus["base"]), 0.0, s[1], 0.0)
				for i in 50:
					await process_frame
				await RenderingServer.frame_post_draw
				var img: Image = root.get_texture().get_image()
				var path := "%s/%s_q%d_%s.png" % [OUT_DIR, _tag, q, s[0]]
				img.save_png(ProjectSettings.globalize_path(path))
				print("saved %s" % path)
		if _perf:
			await _measure(q)
	for q: int in _results.keys():
		if _results.has(q):
			var r: Array = _results[q]
			print("GBF PERF q=%d tag=%s avg_fps=%.1f low1_fps=%.1f gpu_ms_med=%.2f draws=%d" % [q, _tag, r[0], r[1], r[2], r[3]])
	print("GBF DONE")
	quit()


## Frees the last staged buildings and builds the Fire base again (the art reads the tier in _ready).
func _stage() -> void:
	for n: Node in _spawned:
		if is_instance_valid(n):
			n.queue_free()
	_spawned.clear()
	await process_frame
	var grid: Node = main.get(&"build_grid")
	var keep: Node3D = null
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and int(b.get(&"team")) == 0:
			keep = b as Node3D
	if keep == null or grid == null:
		push_error("GBF: no Fire keep / grid")
		return
	var kp: Vector3 = keep.global_position
	var toward: Vector3 = (Vector3.ZERO - kp)
	toward.y = 0.0
	toward = toward.normalized()
	var side: Vector3 = Vector3.UP.cross(toward).normalized()
	var t := func(id: String) -> BuildingType: return load("res://data/buildings/%s.tres" % id) as BuildingType
	var put := func(id: String, off: Vector3, site: bool = false) -> Building:
		var ty: BuildingType = t.call(id)
		var want: Vector3 = kp + side * off.x + toward * off.z
		var spot: Vector3 = grid.call(&"find_spot", ty, want, 0, 6)
		if spot == Vector3.INF or not spot.is_finite():
			spot = want
		var b: Building = (grid.call(&"spawn_site", ty, spot, 0) if site else grid.call(&"spawn_complete", ty, spot, 0)) as Building
		_spawned.append(b)
		return b
	var hall: Building = put.call("fire_barracks", Vector3(-12, 0, 4))
	put.call("fire_barracks", Vector3(13, 0, 2))
	var hov: Array = []
	for o: Vector3 in [Vector3(-8, 0, -9), Vector3(-3, 0, -11), Vector3(3, 0, -11), Vector3(8, 0, -9)]:
		hov.append(put.call("fire_hearth", o))
	var tw1: Building = put.call("fire_tower", Vector3(-6, 0, 12))
	put.call("fire_tower", Vector3(7, 0, 13))
	put.call("fire_stables", Vector3(-20, 0, -4))
	put.call("fire_market", Vector3(20, 0, -5))
	var site: Building = put.call("fire_barracks", Vector3(0, 0, 20), true)
	var k2: Building = put.call("fire_keep", Vector3(-22, 0, 22))
	var k3: Building = put.call("fire_keep", Vector3(-6, 0, 30))
	var k4: Building = put.call("fire_keep", Vector3(12, 0, 26))
	for i in 3:
		await process_frame
	hall.take_damage(hall.max_hp * 0.6, null)
	(hov[1] as Building).take_damage((hov[1] as Building).max_hp * 0.82, null)
	tw1.take_damage(tw1.max_hp * 0.55, null)
	var sm: Node = site.model()
	if sm and sm.has_method(&"set_construction_progress"):
		sm.call(&"set_construction_progress", 0.55)
	(k2 as Keep).set_tier_now(2)
	(k3 as Keep).set_tier_now(3)
	var k4m: Node = k4.model()
	if k4m and k4m.has_method(&"set_upgrading"):
		k4m.call(&"set_upgrading", true)
	_focus["keep"] = kp
	_focus["base"] = kp + toward * 3.0
	_focus["tiers"] = (k2.global_position + k3.global_position + k4.global_position) / 3.0
	_focus["hall"] = hall.global_position
	_focus["small"] = ((hov[1] as Building).global_position + (hov[0] as Building).global_position) * 0.5
	for i in 30:
		await process_frame


func _measure(q: int) -> void:
	paused = false
	_cam.call(&"fly_to", _focus["base"], 0.0, 30.0, 0.0)
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
	print("GBF PERF q=%d avg_fps=%.1f" % [q, _results[q][0]])
