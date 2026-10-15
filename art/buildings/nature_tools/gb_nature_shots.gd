extends SceneTree
## Task G-B Nature: windowed shots + fps of a Nature base on the real skirmish map (docs/art/gb_nature_buildings.md).
## The enemy (Nature, team 1) base gets every Nature building around its Heartwood: Grove Hall x2 (one at 40 % HP),
## Seed Hollows (one at 18 %), Bramble Spires (one at 45 %), Grove Stables, Grove Bazaar, a Hall site at 55 %, a Hollow
## site at 25 %, and three extra Heartwoods: tier 2, tier 3 and one upgrading. Bot off, fog off, HUD hidden.
## Saves docs/art/lab/gb_nature/<tag>_q<q>_<shot>.png, then measures frame times over the base at zoom 30.
## Windowed only:
##   tools\godot_run.ps1 --path . -s res://art/buildings/nature_tools/gb_nature_shots.gd --resolution 1920x1080
##       --quit-after 60000 -- --gfx=high tag=before [perf=0] [shots=0] [frames=600] [only=base_z30]
## One tier per run (the art reads GameSettings.effective_graphics_quality() in _ready; --gfx is the only override).

const OUT_DIR := "res://docs/art/lab/gb_nature"
const SHOTS: Array = [
	# [name, zoom, focus key]
	["base_z10", 10.0, "keep"],
	["base_z30", 30.0, "base"],
	["base_z50", 50.0, "base"],
	["tiers_z30", 30.0, "tiers"],
	["tier3_z10", 10.0, "tier3"],
	["dmg_z10", 10.0, "hall"],
	["small_z10", 10.0, "small"],
	["site_z10", 10.0, "site"],
	["stables_z10", 10.0, "stables"],
	["tiers_z50", 50.0, "tiers"],
	["keep_z18", 18.0, "keep"],
	["tier3_z30", 30.0, "tier3"],
	["upgrade_z15", 15.0, "upgrade"],
]

var main: Node
var _tag := "before"
var _perf := true
var _shots := true
var _frames := 600
var _only := ""
var _ab := false   ## ab=1: measure the G-B layer on / off / on in one process (gfx_detail 2 -> 0 -> 2)
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
			"ab": _ab = v == "1"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	main.set(&"enemy_kingdom", &"nature")
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
	var q: int = GameSettings.effective_graphics_quality()
	print("GBN tag=%s size=%s tier=%d" % [_tag, str(root.get_visible_rect().size), q])
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
	if _ab:
		for step: Array in [["layer_off", 0], ["layer_on", NatureKit.gfx_detail()]]:
			_set_detail(step[1])
			await _measure(step[0])
	for qq: Variant in _results.keys():
		var r: Array = _results[qq]
		print("GBN PERF q=%s tag=%s avg_fps=%.1f low1_fps=%.1f gpu_ms_med=%.2f draws=%d" % [str(qq), _tag, r[0], r[1], r[2], r[3]])
	print("GBN DONE")
	quit()


## Builds the Nature base around the team-1 keep.
func _stage() -> void:
	for n: Node in _spawned:
		if is_instance_valid(n):
			n.queue_free()
	_spawned.clear()
	await process_frame
	var grid: Node = main.get(&"build_grid")
	var keep: Node3D = null
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and int(b.get(&"team")) == 1:
			keep = b as Node3D
	if keep == null or grid == null:
		push_error("GBN: no Nature keep / grid")
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
		var spot: Vector3 = grid.call(&"find_spot", ty, want, 1, 6)
		if spot == Vector3.INF or not spot.is_finite():
			spot = want
		var b: Building = (grid.call(&"spawn_site", ty, spot, 1) if site else grid.call(&"spawn_complete", ty, spot, 1)) as Building
		_spawned.append(b)
		return b
	var hall: Building = put.call("nature_barracks", Vector3(-12, 0, 4))
	put.call("nature_barracks", Vector3(13, 0, 2))
	var hol: Array = []
	for o: Vector3 in [Vector3(-8, 0, -9), Vector3(-3, 0, -11), Vector3(3, 0, -11), Vector3(8, 0, -9)]:
		hol.append(put.call("nature_hollow", o))
	var tw1: Building = put.call("nature_tower", Vector3(-6, 0, 12))
	put.call("nature_tower", Vector3(7, 0, 13))
	var stables: Building = put.call("nature_stables", Vector3(-20, 0, -4))
	put.call("nature_market", Vector3(20, 0, -5))
	var site: Building = put.call("nature_barracks", Vector3(0, 0, 20), true)
	var site2: Building = put.call("nature_hollow", Vector3(-12, 0, 16), true)
	var k2: Building = put.call("nature_keep", Vector3(-22, 0, 22))
	var k3: Building = put.call("nature_keep", Vector3(-6, 0, 32))
	var k4: Building = put.call("nature_keep", Vector3(12, 0, 28))
	for i in 3:
		await process_frame
	hall.take_damage(hall.max_hp * 0.6, null)
	(hol[1] as Building).take_damage((hol[1] as Building).max_hp * 0.82, null)
	tw1.take_damage(tw1.max_hp * 0.55, null)
	for pair: Array in [[site, 0.55], [site2, 0.25]]:
		var sm: Node = (pair[0] as Building).model()
		if sm and sm.has_method(&"set_construction_progress"):
			sm.call(&"set_construction_progress", pair[1])
	(k2 as Keep).set_tier_now(2)
	(k3 as Keep).set_tier_now(3)
	var k4m: Node = k4.model()
	if k4m and k4m.has_method(&"set_upgrading"):
		k4m.call(&"set_upgrading", true)
	_focus["keep"] = kp
	_focus["base"] = kp + toward * 3.0
	_focus["tiers"] = (k2.global_position + k3.global_position + k4.global_position) / 3.0
	_focus["tier3"] = k3.global_position
	_focus["hall"] = hall.global_position
	_focus["small"] = ((hol[1] as Building).global_position + (hol[0] as Building).global_position) * 0.5
	_focus["site"] = (site.global_position + site2.global_position) * 0.5
	_focus["stables"] = stables.global_position
	_focus["upgrade"] = k4.global_position
	for i in 240:   # let the completion flashes / tier-up bursts of the freshly placed buildings finish
		await process_frame


## A/B: gfx_detail on every material of the scene that has it (the G-B painted layer, wind, relief).
func _set_detail(d: int) -> void:
	var seen := {}
	for n: Node in root.find_children("*", "GeometryInstance3D", true, false):
		var mats: Array[Material] = []
		var g := n as GeometryInstance3D
		if g.material_override:
			mats.append(g.material_override)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			for i: int in mi.get_surface_override_material_count():
				if mi.get_surface_override_material(i):
					mats.append(mi.get_surface_override_material(i))
		for m: Material in mats:
			if m is ShaderMaterial and not seen.has(m) and (m as ShaderMaterial).get_shader_parameter(&"gfx_detail") != null:
				seen[m] = true
				(m as ShaderMaterial).set_shader_parameter(&"gfx_detail", d)
	print("GBN A/B gfx_detail=%d on %d materials" % [d, seen.size()])


func _measure(q: Variant) -> void:
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
	print("GBN PERF q=%s avg_fps=%.1f gpu=%.2f" % [str(q), _results[q][0], _results[q][2]])
