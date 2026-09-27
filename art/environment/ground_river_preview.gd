extends SceneTree
## Task 12.V2 screenshots + GPU timing on the real Crown Hollow skirmish map (scenes/skirmish.tscn, bot off, fog
## off, HUD hidden): the ground gets the 12.V2 uniforms from ground_params.gd (the map-fill.md values RiverSystem /
## 12.C1 will set), the 12.V1 water / trench walls / ford films are built with WaterMeshes, the 12.V3 / 12.V4
## crossings and the 12.V13 / 12.V14 landmarks are placed when their scenes exist, props standing in the water are
## hidden (12.C1 removes them in the real map) and a few squads stand on the banks for scale / readability.
## Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/ground_river_preview.gd
##       --resolution 1600x900 --quit-after 20000 -- [tag=<t>] [only=<shot>,<shot>] [river=0] [biomes=0] [gpu=0]
## Saves docs/art/screens/12_v2_[<tag>_]<shot>.png and prints "GPU <shot> <ms>" (average GPU time over 120 frames,
## vsync off). `river=0 biomes=0` renders today's ground with the same water / models (the perf baseline).

const GP_PATH := "res://art/environment/ground_params.gd"
const WM_PATH := "res://art/environment/water/water_meshes.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const LANE_BRIDGE := "res://art/environment/bridges/lane_bridge.tscn"
const ROAD_BRIDGE := "res://art/environment/bridges/road_bridge.tscn"
const FORD := "res://art/environment/bridges/ford_stones.tscn"
const STEPS := "res://art/environment/bridges/crown_steps.tscn"
const LANDMARKS: Array = [
	["res://art/environment/landmarks/colossus.tscn", Vector3(-57, 0, -16)],
	["res://art/environment/landmarks/giant_stump.tscn", Vector3(-30, 0, 20)],
	["res://art/environment/landmarks/standing_stones.tscn", Vector3(-54, 0, 20)],
	["res://art/environment/landmarks/aqueduct.tscn", Vector3(-13.4, 0, -55)],
	["res://art/environment/landmarks/barge.tscn", Vector3(-6.2, 0, -24.5)],
]
const ROAD_DIR := Vector3(45, 0, -1)     # ring segment nw2 -> n_door (both road bridges take the same yaw)
const FLOW := Vector3(1, 0, 8)           # both fords: downstream

const SHOTS: Array = [
	# [name, zoom, focus, yaw deg, measure gpu]
	["overview_z55", 55.0, Vector3(-4.0, 0, -8.0), 0.0, true],
	["isle_z40", 40.0, Vector3(0.0, 0, 0.0), 0.0, true],
	["steps_z20", 20.0, Vector3(-9.02, 0, -9.02), 0.0, false],
	["lane_bridge_z20", 20.0, Vector3(-9.02, 0, 9.02), 0.0, false],
	["ford_z20", 20.0, Vector3(-8.5, 0, -34.0), 0.0, true],
	["bank_z12", 12.0, Vector3(-4.8, 0, -18.5), 0.0, false],
	["saltgate_z40", 40.0, Vector3(-12.0, 0, -46.0), 0.0, false],
	["river_s_z40", 40.0, Vector3(8.0, 0, 30.0), 0.0, true],
	["oldwood_z40", 40.0, Vector3(-44.0, 0, -44.0), 0.0, true],
	["heath_z40", 40.0, Vector3(-50.0, 0, 12.0), 0.0, false],
	["meadow_z40", 40.0, Vector3(-36.0, 0, 34.0), 0.0, true],
	["enemy_z40", 40.0, Vector3(36.0, 0, -38.0), 0.0, false],
	["glade_z20", 20.0, Vector3(-27.0, 0, 21.0), 0.0, false],
]

var main: Node
var _tag := ""
var _only: PackedStringArray = PackedStringArray()
var _river := true
var _biomes := true
var _gpu := true
var _nodiscard := false   # perf probe: a runtime copy of the shader without the discard (= the pre-12.V2 pipeline)
var _gshadow := true      # perf probe: gshadow=0 turns the ground plane's shadow casting off
var _skipshadow := true   # perf probe: skipshadow=0 sets skip_sun_shadow = false (the plane back in the sun's pass)
var _params: Dictionary = {}
var _gpu_frames := 120


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5).split(",")
		elif arg == "river=0":
			_river = false
		elif arg == "biomes=0":
			_biomes = false
		elif arg == "gpu=0":
			_gpu = false
		elif arg == "nodiscard":
			_nodiscard = true
		elif arg == "gshadow=0":
			_gshadow = false
		elif arg == "skipshadow=0":
			_skipshadow = false
		elif arg.begins_with("frames="):
			_gpu_frames = int(arg.substr(7))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var gp: GDScript = load(GP_PATH)
	_params = gp.skirmish_river()
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
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	for i in 30:   # MapDressingArt populates deferred
		await process_frame
	_set_ground()
	_hide_props()
	# Once RiverSystem (12.C1 / 12.C8) builds the water and places the models itself, do not double them.
	var river: Node = get_first_node_in_group(&"river")
	var has_water: bool = river != null and not river.find_children("*", "MeshInstance3D", true, false).is_empty()
	if not has_water:
		var water := Node3D.new()
		water.name = "PreviewWater"
		main.add_child(water)
		_build_water(water)
	_place_models()
	print("preview water: %s" % ("RiverSystem's" if has_water else "WaterMeshes stand-in"))
	_stage()
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var total := 0.0
	var measured := 0
	for s: Array in SHOTS:
		if not _only.is_empty() and not _only.has(s[0]):
			continue
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = deg_to_rad(float(s[3]))
		rig.call(&"focus_on", s[2])
		for i in 50:
			await process_frame
		await RenderingServer.frame_post_draw
		_save(root.get_texture().get_image(), s[0])
		if _gpu and bool(s[4]):
			var sum := 0.0
			for i in _gpu_frames:
				await RenderingServer.frame_post_draw
				sum += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
			var avg := sum / _gpu_frames
			total += avg
			measured += 1
			print("GPU %s %.3f ms" % [s[0], avg])
	if measured > 0:
		print("GPU MEAN %.3f ms over %d shots" % [total / measured, measured])
	if _only.is_empty() or _only.has("map_top"):
		await _map_top()
	print("SHOTS DONE")
	quit()


func _save(img: Image, shot: String) -> void:
	var path := "res://docs/art/screens/12_v2_%s.png" % shot if _tag == "" else \
			"res://docs/art/screens/12_v2_%s_%s.png" % [_tag, shot]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s draws=%d prims=%d" % [path, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])


## The live ground plane gets the 12.V2 uniforms, exactly what 12.C1 will do with GroundParams / shader_params().
func _set_ground() -> void:
	var gp: GDScript = load(GP_PATH)
	for node: Node in main.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if sm == null or sm.shader == null or sm.shader.resource_path != GROUND_SHADER or not (mi.mesh is PlaneMesh):
			continue
		if (mi.mesh as PlaneMesh).size.x > 121.0:
			continue
		if not _gshadow:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if _nodiscard:
			var sh := Shader.new()
			sh.code = sm.shader.code.replace("\t\tdiscard;\n", "")
			var nm := ShaderMaterial.new()
			nm.shader = sh
			for u: Dictionary in sm.shader.get_shader_uniform_list():
				var val: Variant = sm.get_shader_parameter(u["name"])
				if val != null:
					nm.set_shader_parameter(u["name"], val)
			mi.material_override = nm
			sm = nm
		if not _skipshadow:
			sm.set_shader_parameter(&"skip_sun_shadow", false)
		var ok := true
		if _river:
			ok = bool(gp.apply(sm, _params))
		else:   # 12.C1 may already have set it: switch it off for the baseline
			sm.set_shader_parameter(&"river_count", 0)
			sm.set_shader_parameter(&"moat", Vector4.ZERO)
		if _biomes:
			ok = bool(gp.apply(sm, gp.skirmish_biomes())) and ok
		else:
			sm.set_shader_parameter(&"biome_amount", 0.0)
		print("ground %s: river=%s biomes=%s applied=%s" % [mi.get_path(), _river, _biomes, ok])


## Hides MultiMesh instances (trees, rocks, decor, waystones) in the water, on crossings and on the bridge
## approaches (12.C1 keeps them out of the real map).
func _hide_props() -> void:
	var gp: GDScript = load(GP_PATH)
	var hidden := 0
	var bridges: Array[Vector2] = [Vector2(-12, -48.7), Vector2(12, 48.7), Vector2(-9.02, 9.02), Vector2(9.02, -9.02)]
	for node: Node in main.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		if mmi.multimesh == null or mmi.get_parent() is Node3D and (mmi.get_parent() as Node3D).name == &"PreviewWater":
			continue
		var gx: Transform3D = mmi.global_transform
		for i: int in mmi.multimesh.instance_count:
			var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
			var wp: Vector3 = gx * xf.origin
			var q := Vector2(wp.x, wp.z)
			var hide: bool = float(gp.water_distance(_params, q)) < 1.2 or bool(gp.in_ford(_params, q))
			for b: Vector2 in bridges:
				if q.distance_to(b) < 6.0:
					hide = true
			if hide:
				mmi.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001),
						Vector3(xf.origin.x, -30.0, xf.origin.z)))
				hidden += 1
	print("hidden props: %d" % hidden)


## The river look of 12.V1 (WaterMeshes), built the way its test strip does.
func _build_water(parent: Node3D) -> void:
	if not ResourceLoader.exists(WM_PATH):
		print("no WaterMeshes: the cut shows the void")
		return
	var wm: GDScript = load(WM_PATH) as GDScript
	var gp: GDScript = load(GP_PATH)
	var moat: Vector4 = gp.MOAT
	var half: float = gp.HALF_WIDTH
	var circles: Array[Vector4] = gp.CIRCLES
	var river_n := PackedVector2Array(gp.RIVER_N)
	var river_s: PackedVector2Array = gp.mirrored(river_n)
	var moat_path: PackedVector2Array = wm.arc_path(Vector2.ZERO, moat.z, 180.0, 540.0, 0.6)
	var moat_w: PackedVector2Array = wm.arc_path(Vector2.ZERO, moat.z, 258.69, 78.69, 0.6)
	var moat_e: PackedVector2Array = wm.arc_path(Vector2.ZERO, moat.z, 258.69, 438.69, 0.6)
	var fords := PackedVector4Array(circles)
	for mp: String in [wm.WATER_MAT, wm.FORD_MAT]:
		var m := load(mp) as ShaderMaterial
		if m:
			m.set_shader_parameter(&"fords", fords)
			m.set_shader_parameter(&"ford_count", fords.size())
	var dist_river := func(p: Vector2) -> float:
		return minf(wm.distance_to_path(river_n, p), wm.distance_to_path(river_s, p))
	var in_moat := func(p: Vector2) -> float: return 0.0 if p.length() < moat.z + moat.w + 0.3 else 1.0
	var near_river := func(p: Vector2) -> float: return 0.0 if float(dist_river.call(p)) < half + 0.35 else 1.0
	var skip_river := func(p: Vector2) -> bool: return p.length() < moat.z + moat.w - 0.05
	var skip_moat := func(p: Vector2) -> bool: return p.length() > moat.z and float(dist_river.call(p)) < half - 0.05
	var s_len := 0.0
	for i: int in river_n.size() - 1:
		s_len += river_n[i].distance_to(river_n[i + 1])
	var radial := PackedVector2Array([moat_w[0], moat_w[moat_w.size() - 1]])
	_add(parent, wm.channel_surface(river_n, half, wm.WATER_Y - 0.004, 0.0, 1.0, in_moat))
	_add(parent, wm.channel_surface(river_s, half, wm.WATER_Y - 0.004, s_len + 40.0, 1.0, in_moat))
	_add(parent, wm.channel_surface(moat_w, moat.w, wm.WATER_Y, s_len, 0.6, near_river, true, radial))
	_add(parent, wm.channel_surface(moat_e, moat.w, wm.WATER_Y, s_len, 0.6, near_river, false, radial))
	_add(parent, wm.ford_film(river_n, half, Vector2(circles[0].x, circles[0].y), circles[0].z))
	_add(parent, wm.ford_film(river_s, half, Vector2(circles[1].x, circles[1].y), circles[1].z))
	_add(parent, wm.ford_film(moat_w, moat.w, Vector2(circles[2].x, circles[2].y), circles[2].z, wm.FILM_Y, s_len))
	_add(parent, wm.ford_film(moat_e, moat.w, Vector2(circles[3].x, circles[3].y), circles[3].z, wm.FILM_Y, s_len))
	_add(parent, wm.channel_walls(river_n, half, skip_river, wm.WALL_BOTTOM_Y, 0.8, 1))
	_add(parent, wm.channel_walls(river_s, half, skip_river, wm.WALL_BOTTOM_Y, 0.8, 3))
	_add(parent, wm.channel_walls(moat_path, moat.w, skip_moat, wm.WALL_BOTTOM_Y, 0.8, 2))
	_add(parent, wm.ford_end_walls(river_n, half, Vector2(circles[0].x, circles[0].y), circles[0].z))
	_add(parent, wm.ford_end_walls(river_s, half, Vector2(circles[1].x, circles[1].y), circles[1].z))
	for i: int in [2, 3]:
		_add(parent, wm.ford_end_walls(moat_path, moat.w, Vector2(circles[i].x, circles[i].y), circles[i].z))


func _add(parent: Node3D, mesh: Mesh) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _place_models() -> void:
	var placed_crossings := false
	var placed_landmarks := not get_nodes_in_group(&"landmarks").is_empty()
	for n: Node in main.find_children("*", "Node3D", true, false):
		if n.has_method(&"place_crossing") or n.has_method(&"place_on_moat"):
			placed_crossings = true
			break
	if placed_crossings and placed_landmarks:
		return
	var list: Array = [] if placed_crossings else [
		[ROAD_BRIDGE, Vector3(-12, 0, -48.7), ROAD_DIR], [ROAD_BRIDGE, Vector3(12, 0, 48.7), ROAD_DIR],
		[FORD, Vector3(-8.5, 0, -34), FLOW], [FORD, Vector3(8.5, 0, 34), FLOW],
		[STEPS, Vector3(-9.02, 0, -9.02), Vector3.ZERO], [STEPS, Vector3(9.02, 0, 9.02), Vector3.ZERO],
	]
	for e: Array in list:
		if not ResourceLoader.exists(e[0]):
			continue
		var m: Node3D = (load(e[0]) as PackedScene).instantiate() as Node3D
		main.add_child(m)
		if m.has_method(&"place_crossing"):
			m.call(&"place_crossing", e[1], e[2])
		else:
			m.position = e[1]
	if ResourceLoader.exists(LANE_BRIDGE) and not placed_crossings:
		for c: Vector3 in [Vector3(-9.02, 0, 9.02), Vector3(9.02, 0, -9.02)]:
			var lb: Node3D = (load(LANE_BRIDGE) as PackedScene).instantiate() as Node3D
			main.add_child(lb)
			if lb.has_method(&"place_on_moat"):
				lb.call(&"place_on_moat", c)
			else:
				lb.position = c
	for l: Array in LANDMARKS:
		if placed_landmarks or not ResourceLoader.exists(l[0]):
			continue
		for side: float in [1.0, -1.0]:
			var m: Node3D = (load(l[0]) as PackedScene).instantiate() as Node3D
			main.add_child(m)
			m.position = (l[1] as Vector3) * side
			m.rotation.y = 0.0 if side > 0.0 else PI


## Squads on the banks (scale and readability of units against the wet band and the biome tints).
func _stage() -> void:
	_squad(["flame_guard", "flame_guard", "ember_archer", "ember_archer", "blaze_rider"], 0, Vector3(-14.5, 0, -35.0))
	_squad(["flame_guard", "flame_guard", "flame_guard", "ember_archer"], 0, Vector3(-15.0, 0, 4.0))
	_squad(["shade", "shade", "nightbolt", "shadow_knight"], 1, Vector3(2.0, 0, -19.0))
	_squad(["shade", "shade", "nightbolt", "grave_hound"], 1, Vector3(11.5, 0, 27.0))
	_squad(["flame_guard", "ember_archer", "flame_guard", "ember_archer"], 0, Vector3(-48.0, 0, 8.0))
	_squad(["flame_guard", "ember_archer", "blaze_rider"], 0, Vector3(-44.0, 0, -40.0))


func _squad(ids: Array, team: int, at: Vector3) -> void:
	for i in ids.size():
		var u: Node3D = main.call(&"make_unit", ids[i])
		if u == null:
			continue
		u.set(&"team", team)
		main.add_child(u)
		u.global_position = at + Vector3((i % 4) * 1.6, 0.0, (i / 4) * 1.8)


## A straight-down orthographic view of the whole map: the river and biome layout at a glance.
func _map_top() -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 128.0
	cam.far = 400.0
	main.add_child(cam)
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0.0, 0.0)), Vector3(0, 120, 0))
	cam.make_current()
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), "map_top")
