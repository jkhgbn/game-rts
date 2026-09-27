extends SceneTree
## Task 12.V5 screenshots on the real Crown Hollow skirmish (scenes/skirmish.tscn, bot off, fog off, HUD hidden): the
## river mouths are opened (river_enabled when the Skirmish has it, else RiverMouths.set_open(true)), the ground gets
## the 12.V2 river cut (GroundParams), the 12.V1 river water / trench walls are built with WaterMeshes the way
## 12.C1 will, and the 12.V4 road bridges / 12.V14 aqueduct are placed when they exist. Windowed only:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/river_mouths/river_mouths_preview.gd
##       --resolution 1600x900 --quit-after 20000 -- [only=<shot>,<shot>] [gpu=0]
## Saves docs/art/screens/12_v5_<shot>.png and prints "GPU <shot> <ms>" (120 frames, vsync off).

const GP_PATH := "res://art/environment/ground_params.gd"
const WM_PATH := "res://art/environment/water/water_meshes.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const ROAD_BRIDGE := "res://art/environment/bridges/road_bridge.tscn"
const AQUEDUCT := "res://art/environment/landmarks/aqueduct.tscn"
const ROAD_DIR := Vector3(45, 0, -1)

const SHOTS: Array = [
	# [name, zoom, focus, open, measure gpu]
	["north_z40", 40.0, Vector3(-14.0, 0, -52.0), true, true],
	["north_z55", 55.0, Vector3(-12.0, 0, -50.0), true, true],
	["north_z25", 25.0, Vector3(-15.0, 0, -57.0), true, false],
	["south_z40", 40.0, Vector3(15.0, 0, 58.0), true, true],
	["south_z55", 55.0, Vector3(14.0, 0, 58.0), true, false],
	["south_z25", 25.0, Vector3(15.5, 0, 58.0), true, false],
	["closed_north_z40", 40.0, Vector3(-14.0, 0, -52.0), false, true],
	["closed_south_z40", 40.0, Vector3(15.0, 0, 58.0), false, false],
]

var main: Node
var _only: PackedStringArray = PackedStringArray()
var _gpu := true
var _mouths: Node


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
		elif arg == "gpu=0":
			_gpu = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	if &"river_enabled" in main:
		main.set(&"river_enabled", true)
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
	_mouths = main.find_child("RiverMouths", true, false)
	print("RiverMouths: %s" % _mouths)
	var has_river_system: bool = not main.get_tree().get_nodes_in_group(&"river").is_empty()
	if not has_river_system:
		_set_ground()
		var water := Node3D.new()
		water.name = "PreviewWater"
		main.add_child(water)
		_build_water(water)
		_place_models()
		_hide_props()
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for s: Array in SHOTS:
		if not _only.is_empty() and not _only.has(s[0]):
			continue
		if _mouths:
			_mouths.call(&"set_open", bool(s[3]))
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.call(&"focus_on", s[2])
		for i in 50:
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://docs/art/screens/12_v5_%s.png" % s[0]
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		print("saved %s draws=%d prims=%d" % [path, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		if _gpu and bool(s[4]):
			var sum := 0.0
			for i in 120:
				await RenderingServer.frame_post_draw
				sum += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
			print("GPU %s %.3f ms" % [s[0], sum / 120.0])
	print("SHOTS DONE")
	quit()


## The live ground plane gets the 12.V2 river cut (what 12.C1 will do with GroundParams / shader_params()).
func _set_ground() -> void:
	if not ResourceLoader.exists(GP_PATH):
		return
	var gp: GDScript = load(GP_PATH)
	for node: Node in main.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if sm == null or sm.shader == null or sm.shader.resource_path != GROUND_SHADER or not (mi.mesh is PlaneMesh):
			continue
		if (mi.mesh as PlaneMesh).size.x > 121.0:
			continue
		gp.apply(sm, gp.skirmish_river())
		gp.apply(sm, gp.skirmish_biomes())


## The river water of 12.V1 (WaterMeshes), built the way 12.V2's preview does (stand-in for RiverSystem 12.C1).
func _build_water(parent: Node3D) -> void:
	if not ResourceLoader.exists(WM_PATH) or not ResourceLoader.exists(GP_PATH):
		print("no WaterMeshes / GroundParams: no river water")
		return
	var wm: GDScript = load(WM_PATH) as GDScript
	var gp: GDScript = load(GP_PATH)
	var moat: Vector4 = gp.MOAT
	var half: float = gp.HALF_WIDTH
	var circles: Array[Vector4] = gp.CIRCLES
	var river_n := PackedVector2Array(gp.RIVER_N)
	var river_s: PackedVector2Array = gp.mirrored(river_n)
	var fords := PackedVector4Array(circles)
	for mp: String in [wm.WATER_MAT, wm.FORD_MAT]:
		var m := load(mp) as ShaderMaterial
		if m:
			m.set_shader_parameter(&"fords", fords)
			m.set_shader_parameter(&"ford_count", fords.size())
	var in_moat := func(p: Vector2) -> float: return 0.0 if p.length() < moat.z + moat.w + 0.3 else 1.0
	var skip_river := func(p: Vector2) -> bool: return p.length() < moat.z + moat.w - 0.05
	_add(parent, wm.channel_surface(river_n, half, wm.WATER_Y - 0.004, 0.0, 1.0, in_moat))
	_add(parent, wm.channel_surface(river_s, half, wm.WATER_Y - 0.004, 100.0, 1.0, in_moat))
	_add(parent, wm.ford_film(river_n, half, Vector2(circles[0].x, circles[0].y), circles[0].z))
	_add(parent, wm.ford_film(river_s, half, Vector2(circles[1].x, circles[1].y), circles[1].z))
	_add(parent, wm.channel_walls(river_n, half, skip_river, wm.WALL_BOTTOM_Y, 0.8, 1))
	_add(parent, wm.channel_walls(river_s, half, skip_river, wm.WALL_BOTTOM_Y, 0.8, 3))
	_add(parent, wm.ford_end_walls(river_n, half, Vector2(circles[0].x, circles[0].y), circles[0].z))
	_add(parent, wm.ford_end_walls(river_s, half, Vector2(circles[1].x, circles[1].y), circles[1].z))


## Hides in-map decor / props standing in the water (12.C1 / 12.V6 keep them out of the real map).
func _hide_props() -> void:
	var gp: GDScript = load(GP_PATH)
	var params: Dictionary = gp.skirmish_river()
	for node: Node in main.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		if mmi.multimesh == null or String(mmi.get_parent().name) == "BorderForest":
			continue
		var gx: Transform3D = mmi.global_transform
		for i: int in mmi.multimesh.instance_count:
			var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
			var wp: Vector3 = gx * xf.origin
			if float(gp.water_distance(params, Vector2(wp.x, wp.z))) < 1.2:
				mmi.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001),
						Vector3(wp.x, -30.0, wp.z)))


func _add(parent: Node3D, mesh: Mesh) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _place_models() -> void:
	for c: Vector3 in [Vector3(-12, 0, -48.7), Vector3(12, 0, 48.7)]:
		if ResourceLoader.exists(ROAD_BRIDGE):
			var b: Node3D = (load(ROAD_BRIDGE) as PackedScene).instantiate() as Node3D
			main.add_child(b)
			if b.has_method(&"place_crossing"):
				b.call(&"place_crossing", c, ROAD_DIR)
			else:
				b.position = c
	if ResourceLoader.exists(AQUEDUCT):
		for side: float in [1.0, -1.0]:
			var a: Node3D = (load(AQUEDUCT) as PackedScene).instantiate() as Node3D
			main.add_child(a)
			a.position = Vector3(-13.4, 0, -55) * side
			a.rotation.y = 0.0 if side > 0.0 else PI
