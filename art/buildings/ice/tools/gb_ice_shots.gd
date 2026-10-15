extends SceneTree
## Task G-B Ice: windowed shots + fps of an Ice base on the real skirmish map (docs/art/gb_ice_buildings.md).
## The enemy (Ice, team 1) base gets every Ice building around its keep: Frost Hall x2 (one at 40 % HP), Snow Lodges
## (one at 20 %), Rime Spires with a run of Ice Walls between them, Frost Stables, Frost Bazaar, Frost Forge, a Hall site
## at 55 %, and three extra Rime Keeps at tier 2 / tier 3 / upgrading. Bot off, fog off, HUD hidden.
## Saves docs/art/lab/gb_ice/<tag>_q<q>_<shot>.png, then measures frame times over the base at zoom 30.
## Windowed only:
##   tools\godot_run.ps1 --path . -s res://art/buildings/ice/tools/gb_ice_shots.gd --resolution 1920x1080
##       --quit-after 60000 -- --gfx=high tag=after [perf=0] [shots=0] [frames=600] [only=base_z30]
## One tier per run (the art reads GameSettings.effective_graphics_quality() in _ready; --gfx is the override).

const OUT_DIR := "res://docs/art/lab/gb_ice"
const SHOTS: Array = [
	# [name, zoom, focus key]
	["base_z10", 10.0, "keep"],
	["base_z30", 30.0, "base"],
	["base_z50", 50.0, "base"],
	["tiers_z30", 30.0, "tiers"],
	["dmg_z10", 10.0, "hall"],
	["small_z10", 10.0, "small"],
	["walls_z10", 10.0, "walls"],
	["forge_z10", 10.0, "forge"],
	["tiers_z10", 12.0, "citadel"],
]

var main: Node
var _tag := "after"
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
	IceShapes.legacy = _tag.begins_with("before")   # the pre-G-B look, same scene (IceShapes.legacy)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	main.set(&"enemy_kingdom", &"ice")
	for nm: String in ["ShadowBot", "IceBot", "EnemyBot"]:
		var bot: Node = main.get_node_or_null(NodePath(nm))
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
	for n: Node in get_nodes_in_group(&"commanders"):
		n.set(&"enabled", false)
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
	print("GBI tag=%s size=%s tier=%d" % [_tag, str(root.get_visible_rect().size), q])
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
		var r: Array = _results[q]
		print("GBI PERF q=%d tag=%s avg_fps=%.1f low1_fps=%.1f gpu_ms_med=%.2f draws=%d" % [q, _tag, r[0], r[1], r[2], r[3]])
	print("GBI DONE")
	quit()


## Builds the Ice base around the enemy keep.
func _stage() -> void:
	var grid: Node = main.get(&"build_grid")
	var keep: Node3D = null
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and int(b.get(&"team")) == 1:
			keep = b as Node3D
	if keep == null or grid == null:
		push_error("GBI: no Ice keep / grid")
		return
	var kp: Vector3 = keep.global_position
	var toward: Vector3 = (Vector3.ZERO - kp)
	toward.y = 0.0
	toward = toward.normalized()
	var side: Vector3 = Vector3.UP.cross(toward).normalized()
	var t := func(id: String) -> BuildingType: return load("res://data/buildings/%s.tres" % id) as BuildingType
	var put := func(id: String, off: Vector3, site: bool = false, exact: bool = false) -> Building:
		var ty: BuildingType = t.call(id)
		var want: Vector3 = kp + side * off.x + toward * off.z
		var spot: Vector3 = want
		if exact:
			spot = grid.call(&"snap", want, ty.footprint)
		else:
			spot = grid.call(&"find_spot", ty, want, 1, 6)
			if spot == Vector3.INF or not spot.is_finite():
				spot = want
		var b: Building = (grid.call(&"spawn_site", ty, spot, 1) if site else grid.call(&"spawn_complete", ty, spot, 1)) as Building
		_spawned.append(b)
		return b
	var hall: Building = put.call("ice_barracks", Vector3(-12, 0, 4))
	put.call("ice_barracks", Vector3(13, 0, 2))
	var lod: Array = []
	for o: Vector3 in [Vector3(-8, 0, -9), Vector3(-3, 0, -11), Vector3(3, 0, -11), Vector3(8, 0, -9)]:
		lod.append(put.call("ice_lodge", o))
	var tw1: Building = put.call("ice_tower", Vector3(-6, 0, 12))
	put.call("ice_stables", Vector3(-20, 0, -4))
	put.call("ice_market", Vector3(20, 0, -5))
	var forge: Building = put.call("ice_forge", Vector3(21, 0, 9))
	if forge.model() == null and not IceShapes.legacy:
		# The Forge does not load BuildingType.model_path yet (handoff for-systems-coder.md): show the Frost Forge model
		# in place of the placeholder boxes for the shots.
		var vis := forge.get(&"_visual") as Node3D
		for c: Node in vis.get_children():
			c.queue_free()
		var fm := (load("res://art/buildings/forge/ice/ice_forge.tscn") as PackedScene).instantiate() as Node3D
		fm.rotation.y = atan2(-toward.x, -toward.z)
		vis.add_child(fm)
	var site: Building = put.call("ice_barracks", Vector3(0, 0, 20), true)
	# A wall run between two spires (cells of 2 m along the world X axis).
	var wall_at: Vector3 = grid.call(&"snap", kp + side * 2.0 + toward * 13.0, Vector2i(1, 1))
	var walls: Array[Building] = []
	_spawned.append(grid.call(&"spawn_complete", t.call("ice_tower"), wall_at, 1))
	for i in range(1, 5):
		walls.append(grid.call(&"spawn_complete", t.call("ice_wall"), wall_at + Vector3(2.0 * i, 0, 0), 1) as Building)
	_spawned.append(grid.call(&"spawn_complete", t.call("ice_tower"), wall_at + Vector3(10.0, 0, 0), 1))
	_spawned.append_array(walls)
	var k2: Building = put.call("ice_keep", Vector3(-22, 0, 22))
	var k3: Building = put.call("ice_keep", Vector3(-6, 0, 32))
	var k4: Building = put.call("ice_keep", Vector3(12, 0, 28))
	for i in 3:
		await process_frame
	hall.take_damage(hall.max_hp * 0.6, null)
	(lod[1] as Building).take_damage((lod[1] as Building).max_hp * 0.82, null)
	tw1.take_damage(tw1.max_hp * 0.55, null)
	walls[1].take_damage(walls[1].max_hp * 0.8, null)
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
	_focus["small"] = ((lod[1] as Building).global_position + (lod[0] as Building).global_position) * 0.5
	_focus["walls"] = wall_at + Vector3(5.0, 0, 0)
	_focus["forge"] = forge.global_position
	_focus["citadel"] = k3.global_position
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
