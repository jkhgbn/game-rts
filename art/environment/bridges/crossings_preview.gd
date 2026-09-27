extends SceneTree
## Task 12.V4 screenshots on the real skirmish map (scenes/skirmish.tscn, bot off, fog off, HUD hidden): Saltgate /
## Millstone road bridges, Reed / Willow Ford and both Crown Steps placed with CrossingArt.place_crossing().
## Preview-only stand-ins for what other tasks will provide: the ground is cut along the river / moat by a runtime copy
## of ground.gdshader with a discard (12.V2 does it for real), the water, films and trench walls come from 12.V1's
## WaterMeshes when that script loads (else flat teal planes), the lane bridges (12.V3) are added when they exist.
## Trees / rocks / decor standing in the water or on a crossing are hidden (12.C1 removes them in the real map).
## Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/bridges/crossings_preview.gd
##       --resolution 1600x900 --quit-after 12000 -- [only=<shot>,<shot>]
## Saves docs/art/screens/<shot>.png.

const WM_PATH := "res://art/environment/water/water_meshes.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const LANE_BRIDGE := "res://art/environment/bridges/lane_bridge.tscn"
const BRIDGE := "res://art/environment/bridges/road_bridge.tscn"
const FORD := "res://art/environment/bridges/ford_stones.tscn"
const STEPS := "res://art/environment/bridges/crown_steps.tscn"

## map-fill.md 2.1 (downstream order; the first point lies under the north cliffs).
const RIVER_N: Array[Vector2] = [Vector2(-17, -80), Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38),
	Vector2(-8, -30), Vector2(-5, -21), Vector2(-2.5, -12.5)]
const HALF := 2.5
const MOAT := Vector4(0, 0, 12.75, 1.75)
const CIRCLES: Array[Vector4] = [Vector4(-8.5, -34, 3.5, 0), Vector4(8.5, 34, 3.5, 0), Vector4(-9.02, -9.02, 3.0, 0),
	Vector4(9.02, 9.02, 3.0, 0)]
const ROAD_DIR := Vector3(45, 0, -1)     # ring segment nw2 -> n_door
const FLOW := Vector3(1, 0, 8)           # both fords: N2 -> N3 / S3 -> S2 (north -> south)

const SHOTS: Array = [
	# [name, zoom, focus, yaw deg]
	["road_bridge_z20", 20.0, Vector3(-12.0, 0, -48.7), 0.0],
	["road_bridge_z12", 12.0, Vector3(-12.0, 0.4, -48.4), 0.0],
	["road_bridge_z12_east", 12.0, Vector3(-12.0, 0.4, -48.7), 70.0],
	["road_bridge_z40", 40.0, Vector3(-12.0, 0, -45.0), 0.0],
	["road_bridge_s_z20", 20.0, Vector3(12.0, 0, 48.7), 0.0],
	["ford_z20", 20.0, Vector3(-8.5, 0, -34.0), 0.0],
	["ford_z12", 12.0, Vector3(-8.5, 0.2, -33.6), 0.0],
	["ford_z12_west", 12.0, Vector3(-8.5, 0.2, -34.0), -60.0],
	["ford_s_z20", 20.0, Vector3(8.5, 0, 34.0), 0.0],
	["crown_steps_z20", 20.0, Vector3(-9.02, 0, -9.02), 0.0],
	["crown_steps_z12", 12.0, Vector3(-9.02, 0.2, -8.6), 0.0],
	["crown_steps_se_z20", 20.0, Vector3(9.02, 0, 9.02), 0.0],
	["crossings_z55", 55.0, Vector3(-9.0, 0, -30.0), 0.0],
]

var main: Node
var _only: PackedStringArray = PackedStringArray()
var _river_s := PackedVector2Array()
var _river_n := PackedVector2Array()
var _models: Array[Node3D] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
	_river_n = PackedVector2Array(RIVER_N)
	for i: int in range(RIVER_N.size() - 1, -1, -1):
		_river_s.append(-RIVER_N[i])
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
	_cut_ground()
	_hide_props()
	var water := Node3D.new()
	water.name = "PreviewWater"
	main.add_child(water)
	if not _build_water(water):
		_build_standin_water(water)
	_place_models()
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for s: Array in SHOTS:
		if not _only.is_empty() and not _only.has(s[0]):
			continue
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = deg_to_rad(float(s[3]))
		rig.call(&"focus_on", s[2])
		for i in 60:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/%s.png" % s[0]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s fps=%d draws=%d prims=%d" % [path, Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	rig.rotation.y = 0.0
	if _only.is_empty() or _only.has("silhouette"):
		await _silhouette()
	print("SHOTS DONE")
	quit()


func _place_models() -> void:
	var list: Array = [
		[BRIDGE, Vector3(-12, 0, -48.7), ROAD_DIR], [BRIDGE, Vector3(12, 0, 48.7), ROAD_DIR],
		[FORD, Vector3(-8.5, 0, -34), FLOW], [FORD, Vector3(8.5, 0, 34), FLOW],
		[STEPS, Vector3(-9.02, 0, -9.02), Vector3.ZERO], [STEPS, Vector3(9.02, 0, 9.02), Vector3.ZERO],
	]
	for e: Array in list:
		var m: Node3D = (load(e[0]) as PackedScene).instantiate() as Node3D
		main.add_child(m)
		m.call(&"place_crossing", e[1], e[2])
		_models.append(m)
	if ResourceLoader.exists(LANE_BRIDGE):
		for c: Vector3 in [Vector3(-9.02, 0, 9.02), Vector3(9.02, 0, -9.02)]:
			var lb: Node3D = (load(LANE_BRIDGE) as PackedScene).instantiate() as Node3D
			main.add_child(lb)
			if lb.has_method(&"place_on_moat"):
				lb.call(&"place_on_moat", c)
			else:
				lb.position = c


## Preview-only ground cut: a runtime copy of ground.gdshader that discards the deep water (like 12.V2 will).
func _cut_ground() -> void:
	var inj := """
uniform vec4 pv_segs[12];
uniform int pv_seg_count = 0;
uniform vec4 pv_circ[4];
float pv_seg_d(vec2 p, vec4 s) {
	vec2 ab = s.zw - s.xy;
	float t = clamp(dot(p - s.xy, ab) / dot(ab, ab), 0.0, 1.0);
	return length(p - s.xy - ab * t);
}
bool pv_cut(vec2 p) {
	float r = length(p);
	bool water = abs(r - 12.75) < 1.75;
	if (!water && r > 12.75) {
		for (int i = 0; i < pv_seg_count; i++) {
			if (pv_seg_d(p, pv_segs[i]) < 2.5) { water = true; }
		}
	}
	if (!water) { return false; }
	for (int i = 0; i < 4; i++) {
		if (length(p - pv_circ[i].xy) < pv_circ[i].z) { return false; }
	}
	return true;
}
"""
	var segs := PackedVector4Array()
	for path: PackedVector2Array in [_river_n, _river_s]:
		for i: int in path.size() - 1:
			segs.append(Vector4(path[i].x, path[i].y, path[i + 1].x, path[i + 1].y))
	var circ := PackedVector4Array(CIRCLES)
	for node: Node in main.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		var plane := mi.mesh as PlaneMesh
		if sm == null or sm.shader == null or sm.shader.resource_path != GROUND_SHADER or plane == null \
				or plane.size.x > 121.0:
			continue
		var code: String = sm.shader.code
		if code.find("void fragment() {") < 0:
			print("ground cut: fragment() not found")
			continue
		code = code.replace("void fragment() {", inj + "\nvoid fragment() {\n\tif (pv_cut(v_wp.xz)) { discard; }")
		var sh := Shader.new()
		sh.code = code
		var nm := ShaderMaterial.new()
		nm.shader = sh
		for u: Dictionary in sm.shader.get_shader_uniform_list():
			var val: Variant = sm.get_shader_parameter(u["name"])
			if val != null:
				nm.set_shader_parameter(u["name"], val)
		nm.set_shader_parameter(&"pv_segs", segs)
		nm.set_shader_parameter(&"pv_seg_count", segs.size())
		nm.set_shader_parameter(&"pv_circ", circ)
		mi.material_override = nm
		print("ground cut on %s" % mi.get_path())


func _dist_river(p: Vector2) -> float:
	var d: float = INF
	for path: PackedVector2Array in [_river_n, _river_s]:
		for i: int in path.size() - 1:
			var cp: Vector2 = Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1])
			d = minf(d, p.distance_to(cp))
	return d


## Hides MultiMesh instances (trees, rocks, decor, waystones) in the water, on crossings and bridge approaches.
func _hide_props() -> void:
	var hidden := 0
	var bridges: Array[Vector2] = [Vector2(-12, -48.7), Vector2(12, 48.7)]
	for node: Node in main.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		if mmi.multimesh == null:
			continue
		var gx: Transform3D = mmi.global_transform
		for i: int in mmi.multimesh.instance_count:
			var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
			var wp: Vector3 = gx * xf.origin
			var q := Vector2(wp.x, wp.z)
			var r: float = q.length()
			var hide: bool = absf(r - MOAT.z) < MOAT.w + 0.9 or (r > MOAT.z and _dist_river(q) < HALF + 0.9)
			for c: Vector4 in CIRCLES:
				if q.distance_to(Vector2(c.x, c.y)) < c.z + 0.8:
					hide = true
			for b: Vector2 in bridges:
				if q.distance_to(b) < 6.0:
					hide = true
			if hide:
				mmi.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001),
					Vector3(xf.origin.x, -30.0, xf.origin.z)))
				hidden += 1
	print("hidden props: %d" % hidden)


## The river look of 12.V1 (WaterMeshes), built the way its test strip does. False if the script is not usable.
func _build_water(parent: Node3D) -> bool:
	if not ResourceLoader.exists(WM_PATH):
		return false
	var wm: GDScript = load(WM_PATH) as GDScript
	if wm == null or not wm.can_instantiate():
		print("WaterMeshes not usable: stand-in water")
		return false
	var moat_path: PackedVector2Array = wm.arc_path(Vector2.ZERO, MOAT.z, 180.0, 540.0, 0.6)
	var moat_w: PackedVector2Array = wm.arc_path(Vector2.ZERO, MOAT.z, 258.69, 78.69, 0.6)
	var moat_e: PackedVector2Array = wm.arc_path(Vector2.ZERO, MOAT.z, 258.69, 438.69, 0.6)
	var fords := PackedVector4Array(CIRCLES)
	for mp: String in [wm.WATER_MAT, wm.FORD_MAT]:
		var m := load(mp) as ShaderMaterial
		if m:
			m.set_shader_parameter(&"fords", fords)
			m.set_shader_parameter(&"ford_count", fords.size())
	var in_moat := func(p: Vector2) -> float: return 0.0 if p.length() < MOAT.z + MOAT.w + 0.3 else 1.0
	var near_river := func(p: Vector2) -> float: return 0.0 if _dist_river(p) < HALF + 0.35 else 1.0
	var skip_river := func(p: Vector2) -> bool: return p.length() < MOAT.z + MOAT.w - 0.05
	var skip_moat := func(p: Vector2) -> bool: return p.length() > MOAT.z and _dist_river(p) < HALF - 0.05
	var s_len: float = 0.0
	for i: int in _river_n.size() - 1:
		s_len += _river_n[i].distance_to(_river_n[i + 1])
	_add(parent, wm.channel_surface(_river_n, HALF, wm.WATER_Y - 0.004, 0.0, 1.0, in_moat))
	_add(parent, wm.channel_surface(_river_s, HALF, wm.WATER_Y - 0.004, s_len + 40.0, 1.0, in_moat))
	_add(parent, wm.channel_surface(moat_w, MOAT.w, wm.WATER_Y, s_len, 0.6, near_river, true))
	_add(parent, wm.channel_surface(moat_e, MOAT.w, wm.WATER_Y, s_len, 0.6, near_river))
	_add(parent, wm.ford_film(_river_n, HALF, Vector2(CIRCLES[0].x, CIRCLES[0].y), CIRCLES[0].z))
	_add(parent, wm.ford_film(_river_s, HALF, Vector2(CIRCLES[1].x, CIRCLES[1].y), CIRCLES[1].z))
	_add(parent, wm.ford_film(moat_w, MOAT.w, Vector2(CIRCLES[2].x, CIRCLES[2].y), CIRCLES[2].z, wm.FILM_Y, s_len))
	_add(parent, wm.ford_film(moat_e, MOAT.w, Vector2(CIRCLES[3].x, CIRCLES[3].y), CIRCLES[3].z, wm.FILM_Y, s_len))
	_add(parent, wm.channel_walls(_river_n, HALF, skip_river, wm.WALL_BOTTOM_Y, 0.8, 1))
	_add(parent, wm.channel_walls(_river_s, HALF, skip_river, wm.WALL_BOTTOM_Y, 0.8, 3))
	_add(parent, wm.channel_walls(moat_path, MOAT.w, skip_moat, wm.WALL_BOTTOM_Y, 0.8, 2))
	_add(parent, wm.ford_end_walls(_river_n, HALF, Vector2(CIRCLES[0].x, CIRCLES[0].y), CIRCLES[0].z))
	_add(parent, wm.ford_end_walls(_river_s, HALF, Vector2(CIRCLES[1].x, CIRCLES[1].y), CIRCLES[1].z))
	for i: int in [2, 3]:
		_add(parent, wm.ford_end_walls(moat_path, MOAT.w, Vector2(CIRCLES[i].x, CIRCLES[i].y), CIRCLES[i].z))
	print("water: WaterMeshes (12.V1)")
	return true


## Flat teal planes under the cut (no trench walls): only if 12.V1's builder is missing.
func _build_standin_water(parent: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.32, 0.3)
	mat.roughness = 0.4
	for box: Rect2 in [Rect2(-20, -66, 22, 56), Rect2(-2, 10, 22, 56), Rect2(-16, -16, 32, 32)]:
		var pm := PlaneMesh.new()
		pm.size = box.size
		var mi := MeshInstance3D.new()
		mi.mesh = pm
		mi.material_override = mat
		mi.position = Vector3(box.position.x + box.size.x * 0.5, -0.35, box.position.y + box.size.y * 0.5)
		parent.add_child(mi)
	print("water: stand-in planes")


func _add(parent: Node3D, mesh: Mesh) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Black silhouettes on white at zoom 40 (art-keep.md 0.1 test): bridge, ford, steps side by side.
func _silhouette() -> void:
	root.remove_child(main)
	var world := Node3D.new()
	root.add_child(world)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	we.environment = e
	world.add_child(we)
	var xs: Array = [[BRIDGE, -12.0, Vector3(1, 0, 0)], [FORD, 0.0, Vector3(0, 0, 1)], [STEPS, 11.0, Vector3.ZERO]]
	for s: Array in xs:
		var m: Node3D = (load(s[0]) as PackedScene).instantiate() as Node3D
		world.add_child(m)
		var at := Vector3(float(s[1]), 0, 200.0)
		if (s[2] as Vector3) == Vector3.ZERO:
			m.call(&"place_crossing", at, Vector3.ZERO, at + Vector3(0, 0, -12.75))
		else:
			m.call(&"place_crossing", at, s[2])
	for i in 3:
		await process_frame
	for g: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi.name == "Foam":
			gi.visible = false
		else:
			gi.material_override = black
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.far = 400.0
	world.add_child(cam)
	var p: float = deg_to_rad(55.0)
	var focus := Vector3(0.0, 0.5, 200.0)
	cam.position = focus + Vector3(0.0, sin(p) * 40.0, cos(p) * 40.0)
	cam.rotation = Vector3(-p, 0.0, 0.0)
	cam.current = true
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/crossings_silhouette_z40.png"
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)
