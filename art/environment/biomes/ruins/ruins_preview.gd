extends SceneTree
## Task 12.V12 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/ruins/ruins_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 20000 -- mode=sheet|map [nodecor=1]
## mode=sheet: a paved stage (the ground's kind-1 flagstone spot, like the isle), every kind with its 3 variants side
##   by side (rows: flagstones, drums, ember moss, monuments), a Fire squad for scale, the warm lighting rig, the game
##   camera. Saves docs/art/screens/12_v12_sheet.png (contact sheet), 12_v12_sheet_<kind>.png (close-ups),
##   12_v12_sheet_z40.png (the same lineup from 40 m) and 12_v12_sheet_black.png (unshaded black silhouettes).
## mode=map: the real skirmish map (bot off, fog off, HUD hidden) with the 12.V2 ground (river cut, biomes), the 12.V1
##   water, the crossings and landmarks when their scenes exist, and this set scattered over GroundParams.RUINS with the
##   ruins_set.gd rules (density x weight, cluster, gap; paving allowed, lane / crossings / dais / pillars / landmark
##   footprints kept clear). Saves 12_v12_isle_z40.png (+ biome_ruins.png), 12_v12_isle_z22.png, 12_v12_colossus_z40.png,
##   12_v12_stones_z25.png, 12_v12_enemy_isle_z40.png and prints the instance counts and GPU time per shot
##   (nodecor=1: same shots without the set, the cost baseline; nothing is saved; frames=N averages N frames per shot).

const SET_PATH := "res://art/environment/biomes/ruins/ruins_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const WM_PATH := "res://art/environment/water/water_meshes.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const LANE_BRIDGE := "res://art/environment/bridges/lane_bridge.tscn"
const ROAD_BRIDGE := "res://art/environment/bridges/road_bridge.tscn"
const FORD := "res://art/environment/bridges/ford_stones.tscn"
const STEPS := "res://art/environment/bridges/crown_steps.tscn"
const LANDMARKS: Array = [
	["res://art/environment/landmarks/colossus.tscn", Vector3(-57, 0, -16), 4.2],
	["res://art/environment/landmarks/giant_stump.tscn", Vector3(-30, 0, 20), 3.8],
	["res://art/environment/landmarks/standing_stones.tscn", Vector3(-54, 0, 20), 4.3],
	["res://art/environment/landmarks/aqueduct.tscn", Vector3(-13.4, 0, -55), 5.8],
	["res://art/environment/landmarks/barge.tscn", Vector3(-6.2, 0, -24.5), 3.6],
]
const BLEND := 4.0
const PATCH_SIZE := 6.0
const PATCH_SPREAD := 1.2

var _mode := "sheet"
var _no_decor := false
var _rig: Node3D
var _main: Node
var _rng := RandomNumberGenerator.new()
var _entries: Array = []
var _params: Dictionary = {}
var _gp: GDScript
# Map mode: what blocks decor.
var _lane_a := Vector2(1000, 1000)
var _lane_b := Vector2(1001, 1001)
var _has_lane := false
var _spots: Array[Vector4] = []
var _roads: Array[Vector4] = []
var _avoid: Array[Vector3] = []
var _zones: Array[Vector4] = []   # (x, z, r, 0): GroundParams.RUINS
var _count := 0
var _measure := 20   # frames averaged for the GPU time of a shot (frames=N)


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			_mode = arg.substr(5)
		elif arg == "nodecor=1":
			_no_decor = true
		elif arg.begins_with("frames="):
			_measure = int(arg.substr(7))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_entries = (load(SET_PATH) as GDScript).get_script_constant_map()["ENTRIES"]
	_rng.seed = 12012
	if _mode == "map":
		_run_map()
	else:
		_run_sheet()


# ---------------------------------------------------------------- shots

func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40, also: String = "", yaw: float = 0.0) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = deg_to_rad(yaw)
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	for i in frames + _measure:
		await process_frame
		if i >= frames:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / float(_measure)
	await RenderingServer.frame_post_draw
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	print("shot %-16s draws=%d prims=%d gpu_ms=%.2f" % [shot, draws, prims, gpu])
	if _no_decor:
		return
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v12_%s.png" % shot))
	if also != "":
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/%s.png" % also))


# ---------------------------------------------------------------- contact sheet

## nature_painted.gdshader's hash1 (sine-free, so the CPU gets the variant the GPU draws; ruins_ember.gdshader too).
static func _hash1(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d: float = p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)


static func variant_at(pos: Vector3) -> int:
	return mini(int(floor(_hash1(Vector2(pos.z, pos.x) + Vector2(3.1, 7.7)) * 3.0)), 2)


func _find_variant(pos: Vector3, variant: int) -> Vector3:
	for i in 600:
		var p: Vector3 = pos + Vector3(fmod(i * 0.173, 0.6) - 0.3, 0.0, fmod(i * 0.311, 0.6) - 0.3)
		if variant_at(p) == variant:
			return p
	return pos


func _run_sheet() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	gm.set_shader_parameter(&"spot_0", Vector4(0.0, 0.0, 9.5, 1.0))   # the crown's broken-flagstone paving
	ground.material_override = gm
	stage.add_child(ground)
	var sheet := Node3D.new()
	sheet.name = "Sheet"
	stage.add_child(sheet)
	var black: Array[MultiMeshInstance3D] = []
	var rows: Array = [["ruins_flagstones", -3.3, 1.9], ["ruins_drums", -1.25, 1.75], ["ruins_ember_moss", 0.55, 1.45],
		["ruins_monuments", 2.55, 2.05]]
	for r: Array in rows:
		var mesh := load("res://art/environment/biomes/ruins/%s.res" % r[0]) as Mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 3
		for i in 3:
			var pos: Vector3 = _find_variant(Vector3((i - 1) * float(r[2]), 0.0, float(r[1])), i)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, 0.35), pos))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(r[0]).to_pascal_case()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if r[0] == "ruins_monuments" \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sheet.add_child(mmi)
		black.append(mmi)
	# A small Fire squad for scale (flame guard ~1.6 m) beside the rows, if the units exist.
	_scale_figures(stage, Vector3(4.3, 0.0, -1.0))
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("sheet", 11.5, Vector3(0.6, 0, 0.0))
	await _shoot("sheet_flagstones", 5.5, Vector3(0.0, 0, -3.1))
	await _shoot("sheet_drums", 5.5, Vector3(0.0, 0, -1.05))
	await _shoot("sheet_ember_moss", 4.5, Vector3(0.0, 0, 0.7))
	await _shoot("sheet_monuments", 6.0, Vector3(0.0, 0, 2.7))
	await _shoot("sheet_z40", 40.0, Vector3(0.6, 0, 0.0))
	# Silhouettes: unshaded black on a white ground.
	# (preview only: black, unshaded, with the same per-position variant collapse as the real materials; a plain
	# StandardMaterial3D override would draw all 3 variants on top of each other)
	var bs := Shader.new()
	bs.code = """shader_type spatial;
render_mode unshaded, cull_disabled;
float hash1(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z); }
void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	if (UV2.x > 0.5) {
		float v = min(floor(hash1(o.zx + vec2(3.1, 7.7)) * 3.0), 2.0);
		if (mod(floor(UV2.x / exp2(v)), 2.0) < 0.5) { VERTEX = vec3(0.0, -3.0, 0.0); }
	}
}
void fragment() { ALBEDO = vec3(0.0); }
"""
	var bm := ShaderMaterial.new()
	bm.shader = bs
	for mmi: MultiMeshInstance3D in black:
		mmi.material_override = bm
	var wm := StandardMaterial3D.new()
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wm.albedo_color = Color.WHITE
	ground.material_override = wm
	for f: Node in stage.find_children("Figures", "Node3D", true, false):
		(f as Node3D).visible = false
	await _shoot("sheet_black", 11.5, Vector3(0.6, 0, 0.0))
	print("SHOTS DONE")
	quit()


func _scale_figures(parent: Node3D, at: Vector3) -> void:
	var figs := Node3D.new()
	figs.name = "Figures"
	parent.add_child(figs)
	var paths: Array[String] = ["res://art/units/fire/flame_guard.tscn", "res://art/units/fire/ember_archer.tscn"]
	var i := 0
	for p: String in paths:
		if not ResourceLoader.exists(p):
			continue
		var n: Node = (load(p) as PackedScene).instantiate()
		if n is Node3D:
			figs.add_child(n)
			(n as Node3D).position = at + Vector3(0.0, 0.0, i * 1.6)
			(n as Node3D).rotation.y = -0.5
		i += 1


# ---------------------------------------------------------------- the real map

func _run_map() -> void:
	var gp: GDScript = load(GP_PATH)
	_gp = gp
	_params = gp.skirmish_river()
	_main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = _main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(_main)
	current_scene = _main
	var wait := 0
	while _main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	var fog: Node = _main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in _main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = _main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	for i in 30:   # MapDressingArt populates deferred
		await process_frame
	_set_ground()
	_hide_props()
	var water := Node3D.new()
	water.name = "PreviewWater"
	_main.add_child(water)
	_build_water(water)
	_place_models()
	_rig = _main.get(&"camera_rig")
	_rig.set(&"edge_pan_enabled", false)
	_read_map()
	for z: Vector4 in (gp.RUINS as Array):
		_zones.append(z)
	var patch := Node3D.new()
	patch.name = "RuinsPreview"
	_main.add_child(patch)
	_scatter(patch)
	await _shoot("isle_z40", 40.0, Vector3(0.0, 0, 0.0), 60, "biome_ruins")
	await _shoot("isle_z22", 22.0, Vector3(-2.0, 0, -3.0), 50)
	await _shoot("isle_se_z14", 14.0, Vector3(5.0, 0, 5.5), 50)
	await _shoot("colossus_z40", 40.0, Vector3(-52.0, 0, -14.0), 50)
	await _shoot("stones_z25", 25.0, Vector3(-52.0, 0, 20.0), 50)
	await _shoot("enemy_isle_z40", 40.0, Vector3(3.0, 0, 3.0), 50, "", 180.0)
	print("SHOTS DONE")
	quit()


func _set_ground() -> void:
	var gp: GDScript = load(GP_PATH)
	for node: Node in _main.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if sm == null or sm.shader == null or sm.shader.resource_path != GROUND_SHADER or not (mi.mesh is PlaneMesh):
			continue
		if (mi.mesh as PlaneMesh).size.x > 121.0:
			continue
		gp.apply(sm, _params)
		gp.apply(sm, gp.skirmish_biomes())


## Hides props standing in the water / on the bridge approaches (12.C1 keeps them out of the real map).
func _hide_props() -> void:
	var gp: GDScript = load(GP_PATH)
	var bridges: Array[Vector2] = [Vector2(-12, -48.7), Vector2(12, 48.7), Vector2(-9.02, 9.02), Vector2(9.02, -9.02)]
	for node: Node in _main.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		if mmi.multimesh == null:
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


func _build_water(parent: Node3D) -> void:
	if not ResourceLoader.exists(WM_PATH):
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
	var list: Array = [
		[ROAD_BRIDGE, Vector3(-12, 0, -48.7), Vector3(45, 0, -1)], [ROAD_BRIDGE, Vector3(12, 0, 48.7), Vector3(45, 0, -1)],
		[FORD, Vector3(-8.5, 0, -34), Vector3(1, 0, 8)], [FORD, Vector3(8.5, 0, 34), Vector3(1, 0, 8)],
		[STEPS, Vector3(-9.02, 0, -9.02), Vector3.ZERO], [STEPS, Vector3(9.02, 0, 9.02), Vector3.ZERO],
	]
	for e: Array in list:
		if not ResourceLoader.exists(e[0]):
			continue
		var m: Node3D = (load(e[0]) as PackedScene).instantiate() as Node3D
		_main.add_child(m)
		if m.has_method(&"place_crossing"):
			m.call(&"place_crossing", e[1], e[2])
		else:
			m.position = e[1]
	if ResourceLoader.exists(LANE_BRIDGE):
		for c: Vector3 in [Vector3(-9.02, 0, 9.02), Vector3(9.02, 0, -9.02)]:
			var lb: Node3D = (load(LANE_BRIDGE) as PackedScene).instantiate() as Node3D
			_main.add_child(lb)
			if lb.has_method(&"place_on_moat"):
				lb.call(&"place_on_moat", c)
			else:
				lb.position = c
	for l: Array in LANDMARKS:
		for side: float in [1.0, -1.0]:
			var pos: Vector3 = (l[1] as Vector3) * side
			_avoid.append(Vector3(pos.x, pos.z, float(l[2])))
			if not ResourceLoader.exists(l[0]):
				continue
			var m: Node3D = (load(l[0]) as PackedScene).instantiate() as Node3D
			_main.add_child(m)
			m.position = pos
			m.rotation.y = 0.0 if side > 0.0 else PI


## The obstacles MapDressingArt reads (lane, spots, roads, EnvProps trees / rocks / pillars, crystal nodes, buildings),
## plus the crown dais and the crossings.
func _read_map() -> void:
	var set_consts: Dictionary = (load(SET_PATH) as GDScript).get_script_constant_map()
	for mi: Node in _main.find_children("*", "MeshInstance3D", true, false):
		var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and (mi as MeshInstance3D).mesh is PlaneMesh:
			var la: Variant = sm.get_shader_parameter(&"lane_a")
			var lb: Variant = sm.get_shader_parameter(&"lane_b")
			if la is Vector2 and lb is Vector2:
				_lane_a = la
				_lane_b = lb
				_has_lane = true
			for i: int in 4:
				var s: Variant = sm.get_shader_parameter(StringName("spot_%d" % i))
				if s is Vector4 and (s as Vector4).z > 0.0:
					_spots.append(s)
			var count: Variant = sm.get_shader_parameter(&"road_count")
			var segs: Variant = sm.get_shader_parameter(&"road_segs")
			if count is int and segs != null:
				var list: Array = Array(segs)
				for i: int in mini(int(count), list.size()):
					_roads.append(list[i])
			break
	var env: Node = _main.get(&"env_props") if &"env_props" in _main else null
	if env:
		for c: Node in env.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null or mmi.multimesh == null:
				continue
			var nm: String = String(mmi.name)
			for i: int in mmi.multimesh.instance_count:
				var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
				var r: float = 1.1 * xf.basis.get_scale().x
				if not nm.begins_with("Tree") and not nm.begins_with("Rock"):
					r = float(set_consts["PILLAR_CLEAR"])
				_avoid.append(Vector3(xf.origin.x, xf.origin.z, r))
	for n: Node in root.get_tree().get_nodes_in_group(&"crystal_nodes"):
		if n is Node3D:
			var p: Vector3 = (n as Node3D).global_position
			_avoid.append(Vector3(p.x, p.z, 2.3))
	for b: Node in root.get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D:
			var pb: Vector3 = (b as Node3D).global_position
			var r2: float = float(b.call(&"target_radius")) + 1.0 if b.has_method(&"target_radius") else 4.0
			_avoid.append(Vector3(pb.x, pb.z, r2))
	_avoid.append(Vector3(0.0, 0.0, float(set_consts["ISLE_DAIS_CLEAR"])))
	var gp: GDScript = load(GP_PATH)
	for c2: Vector4 in (gp.CIRCLES as Array):
		_avoid.append(Vector3(c2.x, c2.y, c2.z + 0.6))


## Ruins weight at q: 1 inside a GroundParams.RUINS circle, fading over the 4 m blend (the isle ends at the moat).
func _weight(q: Vector2, margin: float, lane_paving: float = 0.0) -> float:
	var w := 0.0
	for z: Vector4 in _zones:
		var d: float = q.distance_to(Vector2(z.x, z.y))
		w = maxf(w, clampf(1.0 - (d - z.z) / BLEND, 0.0, 1.0))
	if w <= 0.0 or _blocked(q, margin, lane_paving):
		return 0.0
	return w


func _blocked(q: Vector2, margin: float, lane_paving: float = 0.0) -> bool:
	if absf(q.x) > 59.6 or absf(q.y) > 59.6:
		return true
	if float(_gp.water_distance(_params, q)) < 0.6 + margin:
		return true
	if _has_lane:
		var lane_clear := 5.2
		if lane_paving > 0.0:
			for s0: Vector4 in _spots:
				if s0.w > 0.5 and q.distance_to(Vector2(s0.x, s0.y)) < s0.z:
					lane_clear = lane_paving   # flat kinds on the kind-1 paving (ruins_set.gd lane_clear_paving)
		var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, _lane_a, _lane_b)
		if q.distance_to(c) < lane_clear + margin:
			return true
	for s: Vector4 in _spots:
		if s.w > 0.5:
			continue   # kind-1 flagstone paving: ruins decor belongs there (paving_ok)
		if q.distance_to(Vector2(s.x, s.y)) < s.z + 0.8 + margin:
			return true
	for r: Vector4 in _roads:
		var c2: Vector2 = Geometry2D.get_closest_point_to_segment(q, Vector2(r.x, r.y), Vector2(r.z, r.w))
		if q.distance_to(c2) < 2.3 + margin:
			return true
	for a: Vector3 in _avoid:
		if q.distance_to(Vector2(a.x, a.y)) < a.z + margin:
			return true
	return false


func _scatter(parent: Node3D) -> void:
	if _no_decor:
		return
	var total := 0
	for e: Dictionary in _entries:
		var mesh := load(String(e["mesh"])) as Mesh
		var sc: Vector2 = e["scale"]
		var gap: float = float(e.get("gap", 0.0))
		var margin: float = 0.6 if gap > 0.0 else 0.2
		var cluster: float = e["cluster"]
		var lp: float = float(e.get("lane_clear_paving", 0.0))
		var xfs: Array[Transform3D] = []
		for z: Vector4 in _zones:
			var rr: float = z.z + BLEND
			var rect := Rect2(Vector2(z.x, z.y) - Vector2.ONE * rr, Vector2.ONE * rr * 2.0)
			var n_full: float = float(e["per_100m2"]) * rect.get_area() / 100.0
			for i: int in int(round(n_full * (1.0 - cluster))):
				var p := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
				if _rng.randf() < _weight(p, margin, lp) and _gap_ok(xfs, p, gap):
					xfs.append(_xf(p, sc))
			for k: int in int(round(n_full * cluster / PATCH_SIZE)):
				var pc := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y,
					rect.end.y))
				if _rng.randf() >= _weight(pc, margin, lp):
					continue
				for j: int in int(PATCH_SIZE):
					var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, PATCH_SPREAD), _rng.randfn(0.0, PATCH_SPREAD))
					if _rng.randf() < _weight(p2, margin, lp) and _gap_ok(xfs, p2, gap):
						xfs.append(_xf(p2, sc))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for i: int in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(e["id"]).to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(e["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(e["range"])
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mmi)
		print("scatter %-12s %4d instances (%.1f / 100 m2 at full weight)" % [e["id"], xfs.size(), float(e["per_100m2"])])
		total += xfs.size()
	_count = total
	print("scatter total %d instances (budget 300)" % total)


func _gap_ok(xfs: Array[Transform3D], p: Vector2, gap: float) -> bool:
	if gap <= 0.0:
		return true
	for xf: Transform3D in xfs:
		if Vector2(xf.origin.x, xf.origin.z).distance_to(p) < gap:
			return false
	return true


func _xf(p: Vector2, sc: Vector2) -> Transform3D:
	var s: float = _rng.randf_range(sc.x, sc.y)
	return Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(p.x, 0.0, p.y))
