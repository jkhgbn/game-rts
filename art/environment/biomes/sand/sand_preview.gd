extends SceneTree
## Task 12b.V3 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/sand/sand_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000 -- mode=stage
## The sand ground layer is 12b.V1's (ground.gdshader `terrain_mask`, G = sand). When the ground shader has it, the
## preview feeds it a 240 x 240 mask of the patches; until then a PREVIEW-ONLY sand decal (terrain.md 7.1 sand look:
## light / dark ochre, wind ripples ~0.9 m along (0.8, 0.6), pebbles, a soft edge) stands in for it. Neither is game art.
## Patch weight model (the one tests/test_12b_v3.gd budgets with): ellipse {centre, (rx, rz)}, signed distance in
## metres + a point-symmetric +-0.45 m edge wobble, weight = 1 - smoothstep(-1, 1, d): place &"sand" where w > 0.5,
## &"sand_edge" where 0.2 <= w <= 0.5.
## mode=stage (default): the painted ground with the Crown Hollow biome zones (no river), Heron Dunes (-55, -11) by the
##   Fallen Colossus with the heath around it (thinned on the sand), Millwatch Terrace (-8, 41), a lineup of both
##   meshes x 3 variants on a sand strip, the lighting rig and the game camera (pitch 55). Saves
##   docs/art/screens/12b_v3_patch_z40.png (Heron Dunes from the game's 40 m), 12b_v3_terrace_z40.png,
##   12b_v3_patch_z25.png, 12b_v3_close_z12.png, the contact sheet 12b_v3_contact.png (2 x 2: tussock variants close,
##   stones / bones variants close, both at 12 m, the lineup at 40 m) and 12b_v3_lineup_z40.png.
## mode=map: the real skirmish map (bot off, fog off, HUD hidden) with the 4 sand patches scattered around the real
##   obstacles: 12b_v3_map_terrace_z40.png, 12b_v3_map_dunes_z40.png; prints the instance count vs the 400 budget.

const SET_PATH := "res://art/environment/biomes/sand/sand_set.gd"
const HEATH_SET := "res://art/environment/biomes/heath/heath_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const SHOT_DIR := "res://docs/art/screens/"
const PATCH_SIZE := 8
const PATCH_SPREAD := 1.2
## terrain.md 4.2 (player half; the mirror is (-x, -z)): [id, centre, radii].
const PATCHES := [[&"sand_tower_s", Vector2(-8, 41), Vector2(6.0, 5.0)], [&"sand_heath_w", Vector2(-55, -11),
	Vector2(5.0, 6.0)]]
const LINEUP_Z := 52.0
const SAND_LIGHT := Color(0.86, 0.74, 0.50)
const SAND_DARK := Color(0.66, 0.52, 0.32)

var _mode := "stage"
var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _gp: GDScript
var _patches: Array = []        # [centre: Vector2, radii: Vector2]
var _river: Dictionary = {}
var _lane_a := Vector2(1000, 1000)
var _lane_b := Vector2(1001, 1001)
var _spots: Array[Vector4] = []
var _roads: Array[Vector4] = []
var _avoid: Array[Vector3] = []
var _count := 0
var _space: Array[Vector3] = []  # placed gap items (x, z, gap)


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			_mode = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_gp = load(GP_PATH) as GDScript
	_rng.seed = 12303
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


# ---------------------------------------------------------------- the patch weight model

static func edge_noise(q: Vector2) -> float:
	var a: float = sin(q.x * 1.3 + sin(q.y * 0.9) * 1.7) * 0.5 + sin(q.y * 1.1 - q.x * 0.7) * 0.5
	var b: float = sin(-q.x * 1.3 + sin(-q.y * 0.9) * 1.7) * 0.5 + sin(-q.y * 1.1 + q.x * 0.7) * 0.5
	return (a + b) * 0.5 * 0.45


static func patch_weight(q: Vector2, c: Vector2, r: Vector2) -> float:
	var u: Vector2 = (q - c) / r
	var lu: float = u.length()
	var d: float = (lu - 1.0) * (q.distance_to(c) / lu) if lu > 0.001 else -minf(r.x, r.y)
	return 1.0 - smoothstep(-1.0, 1.0, d + edge_noise(q))


func sand_weight(q: Vector2) -> float:
	var w := 0.0
	for p: Array in _patches:
		w = maxf(w, patch_weight(q, p[0], p[1]))
	return w


func _place_weight(place: StringName, q: Vector2) -> float:
	var w: float = sand_weight(q)
	if place == &"sand_edge":
		return 1.0 if w >= 0.2 and w <= 0.5 else 0.0
	return 1.0 if w > 0.5 else 0.0


# ---------------------------------------------------------------- scatter (MapDressingArt's rules, 3 retries per member)

func _blocked(q: Vector2, margin: float) -> bool:
	return _block_reason(q, margin) != "free"


func _block_reason(q: Vector2, margin: float) -> String:
	if absf(q.x) > 59.6 or absf(q.y) > 59.6:
		return "object"
	if not _river.is_empty():
		if float(_gp.call(&"water_distance", _river, q)) < 0.6 + margin:
			return "water"
	var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, _lane_a, _lane_b)
	if q.distance_to(c) < 5.2 + margin:
		return "lane"
	for s: Vector4 in _spots:
		if q.distance_to(Vector2(s.x, s.y)) < s.z + 0.8 + margin:
			return "spot"
	for r: Vector4 in _roads:
		var c2: Vector2 = Geometry2D.get_closest_point_to_segment(q, Vector2(r.x, r.y), Vector2(r.z, r.w))
		if q.distance_to(c2) < 2.3 + margin:
			return "road"
	for a: Vector3 in _avoid:
		if q.distance_to(Vector2(a.x, a.y)) < a.z + margin:
			return "object"
	return "free"


func _scatter_sand(parent: Node3D) -> void:
	var entries: Array = (load(SET_PATH) as GDScript).get_script_constant_map()["ENTRIES"]
	# One MultiMesh per mesh AND patch (like MapDressingArt's chunks): a visibility range is measured to the whole
	# MultiMesh's AABB, so one map-wide MultiMesh would fade out as a block.
	var lists := {}
	for e: Dictionary in entries:
		var path: String = e["mesh"]
		var place: StringName = e["place"]
		var gap: float = float(e.get("gap", 0.0))
		var margin: float = minf(gap * 0.5, 1.6) if gap > 0.0 else 0.25
		var cluster: float = e["cluster"]
		var spread: float = PATCH_SPREAD * (2.0 if gap > 0.0 else 1.0)
		var placed := 0
		for pi: int in _patches.size():
			var p: Array = _patches[pi]
			var key := "%s|%d" % [path, pi]
			if not lists.has(key):
				var fresh: Array[Transform3D] = []
				lists[key] = {"xfs": fresh, "e": e, "path": path}
			var xfs: Array[Transform3D] = lists[key]["xfs"]
			var c: Vector2 = p[0]
			var r: Vector2 = p[1]
			var rect := Rect2(c - r - Vector2(1.6, 1.6), (r + Vector2(1.6, 1.6)) * 2.0)
			var n_full: float = float(e["per_100m2"]) * rect.get_area() / 100.0
			for i: int in int(round(n_full * (1.0 - cluster))):
				var q := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
				placed += _try(xfs, e, q, place, gap, margin)
			for k: int in int(round(n_full * cluster / PATCH_SIZE)):
				var pc := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y,
					rect.end.y))
				if _place_weight(place, pc) <= 0.0:
					continue
				for j: int in PATCH_SIZE:
					var q2: Vector2 = pc
					for attempt: int in 3:
						q2 = pc + Vector2(_rng.randfn(0.0, spread), _rng.randfn(0.0, spread))
						if _place_weight(place, q2) > 0.0:
							break
					placed += _try(xfs, e, q2, place, gap, margin)
		print("scatter %-13s %4d instances (%.0f / 100 m2 of %s)" % [e["id"], placed, float(e["per_100m2"]), place])
		_count += placed
	for key2: String in lists:
		var xfs2: Array[Transform3D] = lists[key2]["xfs"]
		var e2: Dictionary = lists[key2]["e"]
		var path2: String = lists[key2]["path"]
		parent.add_child(_mmi(load(path2) as Mesh, xfs2, bool(e2["shadow"]), float(e2["range"]), path2))


func _try(xfs: Array[Transform3D], e: Dictionary, q: Vector2, place: StringName, gap: float, margin: float) -> int:
	if _place_weight(place, q) <= 0.0 or _blocked(q, margin):
		return 0
	if gap > 0.0:
		for s: Vector3 in _space:
			if q.distance_to(Vector2(s.x, s.y)) < gap:
				return 0
		_space.append(Vector3(q.x, q.y, gap))
	var sc: Vector2 = e["scale"]
	var s2: float = _rng.randf_range(sc.x, sc.y)
	xfs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s2, s2, s2)), Vector3(q.x, 0.0, q.y)))
	return 1


func _mmi(mesh: Mesh, xfs: Array[Transform3D], shadow: bool, vis_end: float, label: String) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = label.get_file().get_basename().to_pascal_case()
	mmi.multimesh = mm
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = vis_end
	mmi.visibility_range_end_margin = 10.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return mmi


## The heath around Heron Dunes (heath_set.gd rules), thinned where the sand lies (12b.V6: "grass tufts thin out on
## sand"): keep probability x (1 - sand weight)^2.
func _scatter_heath(parent: Node3D, rect: Rect2) -> void:
	var entries: Array = (load(HEATH_SET) as GDScript).get_script_constant_map()["ENTRIES"]
	for e: Dictionary in entries:
		var xfs: Array[Transform3D] = []
		var gap: float = float(e.get("gap", 0.0))
		var margin: float = gap * 0.5 if gap > 0.0 else 0.25
		var n: int = int(round(float(e["per_100m2"]) * rect.get_area() / 100.0))
		for i: int in n:
			var q := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
			var keep: float = _heath_weight(q) * pow(1.0 - sand_weight(q), 2.0)
			if _rng.randf() >= keep or _blocked(q, margin):
				continue
			var sc: Vector2 = e["scale"]
			var s: float = _rng.randf_range(sc.x, sc.y)
			var yaw: float = float(e["yaw"]) + _rng.randf_range(-0.35, 0.35) if e.has("yaw") else _rng.randf() * TAU
			xfs.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), Vector3(q.x, 0.0, q.y)))
		parent.add_child(_mmi(load(String(e["mesh"])) as Mesh, xfs, false, float(e["range"]), String(e["mesh"])))


func _zone_in(e: float, bl: float) -> float:
	return 1.0 - smoothstep(-bl, bl, e)


func _heath_weight(q: Vector2) -> float:
	var c: Dictionary = _gp.get_script_constant_map()
	var bl: float = float(c["BLEND"]) * 0.5
	var ruin := 0.0
	for r: Vector4 in c["RUINS"]:
		ruin = maxf(ruin, _zone_in(q.distance_to(Vector2(r.x, r.y)) - r.z, bl))
	var hubs: Vector4 = c["HUBS"]
	var meadow: float = _zone_in(minf(q.distance_to(Vector2(hubs.x, hubs.y)), q.distance_to(Vector2(hubs.z, hubs.w)))
		- float(c["HUB_RADIUS"]), bl)
	var woods: Vector4 = c["WOODS"]
	var wood: float = _zone_in(minf(q.distance_to(Vector2(woods.x, woods.y)), q.distance_to(Vector2(woods.z, woods.w)))
		- float(c["WOOD_RADIUS"]), bl)
	var heath: float = 1.0 - _zone_in(maxf(absf(q.x), absf(q.y)) - float(c["HEATH_EDGE"]), bl)
	var left: float = 1.0 - ruin
	meadow *= left
	left -= meadow
	wood *= left
	left -= wood
	return heath * left


# ---------------------------------------------------------------- the sand ground (12b.V1 mask, or the stand-in decal)

## Feeds ground.gdshader's terrain layer when it exists (12b.V1). Returns false when the shader has no sand layer yet.
func _paint_mask(gm: ShaderMaterial) -> bool:
	var names := {}
	for u: Dictionary in gm.shader.get_shader_uniform_list():
		names[String(u["name"])] = true
	if not (names.has("terrain_mask") and names.has("terrain_enabled")):
		return false
	var img := Image.create(240, 240, false, Image.FORMAT_RGBA8)
	for j: int in 240:
		for i: int in 240:
			var w: float = sand_weight(Vector2(-60.0 + (i + 0.5) * 0.5, -60.0 + (j + 0.5) * 0.5))
			img.set_pixel(i, j, Color(0.0, w, 0.0, 0.0))
	gm.set_shader_parameter(&"terrain_mask", ImageTexture.create_from_image(img))
	gm.set_shader_parameter(&"terrain_enabled", true)
	if names.has("terrain_origin"):
		gm.set_shader_parameter(&"terrain_origin", Vector2(-60.0, -60.0))
	if names.has("terrain_size"):
		gm.set_shader_parameter(&"terrain_size", 120.0)
	print("sand: painted through ground.gdshader terrain_mask (12b.V1)")
	return true


const DECAL_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform vec3 sand_light : source_color;
uniform vec3 sand_dark : source_color;
uniform vec3 edge_col : source_color;
uniform vec2 centre;
uniform vec2 radii;
varying vec3 wp;
float hash(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y); }
float en(vec2 q) {
	float a = sin(q.x * 1.3 + sin(q.y * 0.9) * 1.7) * 0.5 + sin(q.y * 1.1 - q.x * 0.7) * 0.5;
	float b = sin(-q.x * 1.3 + sin(-q.y * 0.9) * 1.7) * 0.5 + sin(-q.y * 1.1 + q.x * 0.7) * 0.5;
	return (a + b) * 0.5 * 0.45; }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 q = wp.xz;
	vec2 u = (q - centre) / radii;
	float lu = max(length(u), 0.001);
	float d = (lu - 1.0) * (length(q - centre) / lu);
	float w = 1.0 - smoothstep(-1.0, 1.0, d + en(q));
	vec2 wd = normalize(vec2(0.8, 0.6));
	float warp = vn(q * 0.35) * 2.2 + vn(q * 1.3) * 0.35;
	float ph = fract(dot(q, wd) / 0.9 + warp);
	float crest = smoothstep(0.0, 0.62, ph) * (1.0 - smoothstep(0.72, 0.9, ph));
	float big = vn(q * 0.18 + 3.1);
	vec3 col = mix(sand_dark, sand_light, clamp(0.35 + crest * 0.4 + (big - 0.5) * 0.5, 0.0, 1.0));
	vec2 cell = floor(q * 2.2);
	float pk = hash(cell + 7.7);
	float pd = length(fract(q * 2.2) - 0.5 - (vec2(hash(cell), hash(cell + 3.3)) - 0.5) * 0.5);
	col = mix(col, sand_dark * 0.55, step(0.93, pk) * (1.0 - smoothstep(0.08, 0.13, pd)));
	col = mix(edge_col, col, smoothstep(0.2, 0.7, w));
	ALBEDO = col * 0.9;
	ALPHA = smoothstep(0.15, 0.55, w);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	float dd = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, dd) * 0.55 + smoothstep(0.58, 0.68, dd) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
"""


func _decal(parent: Node3D, c: Vector2, r: Vector2) -> void:
	var sh := Shader.new()
	sh.code = DECAL_CODE
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter(&"sand_light", SAND_LIGHT)
	m.set_shader_parameter(&"sand_dark", SAND_DARK)
	m.set_shader_parameter(&"edge_col", Color(0.52, 0.45, 0.28))
	m.set_shader_parameter(&"centre", c)
	m.set_shader_parameter(&"radii", r)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = (r + Vector2(2.0, 2.0)) * 2.0
	mi.mesh = pm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x, 0.02, c.y)
	parent.add_child(mi)


func _paint_sand(parent: Node3D, gm: ShaderMaterial) -> void:
	if gm != null and _paint_mask(gm):
		return
	print("sand: ground.gdshader has no terrain layer yet -> preview decal stand-in")
	for p: Array in _patches:
		_decal(parent, p[0], p[1])


# ---------------------------------------------------------------- shots

func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40) -> Image:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	for i in frames:
		await process_frame
		if i >= frames - 20:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / 20.0
	await RenderingServer.frame_post_draw
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	print("shot %-16s draws=%d prims=%d gpu_ms=%.2f" % [shot, draws, prims, gpu])
	var img: Image = root.get_texture().get_image()
	if shot != "":
		img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v3_%s.png" % shot))
	return img


# ---------------------------------------------------------------- stage

func _run_stage() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	var road := Vector4(-78.0, 9.0, -30.0, -6.0)
	var segs := PackedVector4Array()
	segs.resize(16)
	segs[0] = road
	gm.set_shader_parameter(&"road_segs", segs)
	gm.set_shader_parameter(&"road_count", 1)
	_gp.call(&"apply", gm, _gp.call(&"skirmish_biomes"))
	ground.material_override = gm
	stage.add_child(ground)
	_roads.append(road)
	var lm: Array = [["res://art/environment/landmarks/colossus.tscn", Vector3(-57.0, 0.0, -16.0), 4.2],
		["res://art/environment/landmarks/standing_stones.tscn", Vector3(-54.0, 0.0, 20.0), 4.2]]
	for l: Array in lm:
		if ResourceLoader.exists(l[0]):
			var n: Node3D = (load(l[0]) as PackedScene).instantiate() as Node3D
			stage.add_child(n)
			n.position = l[1]
			_avoid.append(Vector3((l[1] as Vector3).x, (l[1] as Vector3).z, float(l[2])))
	if ResourceLoader.exists("res://art/environment/map_dressing.tscn"):
		var md: Node = (load("res://art/environment/map_dressing.tscn") as PackedScene).instantiate()
		md.set_script(null)
		stage.add_child(md)
	for p: Array in PATCHES:
		_patches.append([p[1], p[2]])
	# The lineup strip (preview only): a flat sand band under the variant lineup, so the sheet judges them on sand.
	_patches.append([Vector2(1.5, LINEUP_Z), Vector2(9.0, 3.2)])
	_paint_sand(stage, gm)
	_patches.pop_back()   # no scatter on the lineup strip
	var decor := Node3D.new()
	decor.name = "Sand"
	stage.add_child(decor)
	_scatter_heath(decor, Rect2(Vector2(-60.0, -34.0), Vector2(26.0, 46.0)))
	_scatter_sand(decor)
	print("sand instances on the 2 stage patches: %d (the 4 map patches ~ x2; budget %d)" % [_count,
		int((load(SET_PATH) as GDScript).get_script_constant_map()["INSTANCE_BUDGET"])])
	_build_lineup(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)   # closer than the game allows, for the lineup close-ups only
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("patch_z40", 40.0, Vector3(-52.0, 0, -9.0))
	await _shoot("terrace_z40", 40.0, Vector3(-8.0, 0, 41.0))
	await _shoot("patch_z25", 25.0, Vector3(-54.0, 0, -10.0))
	await _shoot("close_z12", 12.0, Vector3(-6.0, 0, 41.0))
	var quads: Array[Image] = []
	quads.append(await _shoot("", 4.2, Vector3(-2.8, 0.0, LINEUP_Z - 0.3)))
	quads.append(await _shoot("", 6.8, Vector3(4.0, 0.0, LINEUP_Z - 0.4)))
	quads.append(await _shoot("", 12.0, Vector3(1.4, 0.0, LINEUP_Z - 0.8)))
	quads.append(await _shoot("lineup_z40", 40.0, Vector3(1.4, 0.0, LINEUP_Z - 3.0)))
	var w: int = quads[0].get_width()
	var h: int = quads[0].get_height()
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i: int in quads.size():
		var q: Image = quads[i]
		q.convert(Image.FORMAT_RGBA8)
		q.resize(w / 2, h / 2, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(q, Rect2i(0, 0, w / 2, h / 2), Vector2i((i % 2) * (w / 2), (i / 2) * (h / 2)))
	for x: int in w:
		sheet.set_pixel(x, h / 2, Color(0.1, 0.1, 0.1))
	for y: int in h:
		sheet.set_pixel(w / 2, y, Color(0.1, 0.1, 0.1))
	sheet.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v3_contact.png"))
	print("saved 12b_v3_contact.png")
	print("SHOTS DONE")
	quit()


## nature_painted.gdshader's hash1 (sine-free, so the CPU gets the variant the GPU draws).
static func _hash1(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d: float = p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)


static func variant_at(pos: Vector3) -> int:
	return mini(int(floor(_hash1(Vector2(pos.z, pos.x) + Vector2(3.1, 7.7)) * 3.0)), 2)


func _find_variant(pos: Vector3, variant: int) -> Vector3:
	for i in 400:
		var p: Vector3 = pos + Vector3(fmod(i * 0.173, 0.6) - 0.3, 0.0, fmod(i * 0.311, 0.6) - 0.3)
		if variant_at(p) == variant:
			return p
	return pos


## Both meshes x 3 variants along x at LINEUP_Z: tussocks at -4.0 / -2.8 / -1.6, stones / bones at 1.5 / 4.0 / 6.5.
func _build_lineup(stage: Node3D) -> void:
	for g: Array in [["sand_tussock", -2.8, 1.2, false], ["sand_bones", 4.0, 2.5, true]]:
		var xfs: Array[Transform3D] = []
		for i in 3:
			var pos: Vector3 = _find_variant(Vector3(float(g[1]) + (i - 1) * float(g[2]), 0.0, LINEUP_Z), i)
			xfs.append(Transform3D(Basis(Vector3.UP, 0.35 + i * 0.25), pos))
		stage.add_child(_mmi(load("res://art/environment/biomes/sand/%s.res" % g[0]) as Mesh, xfs, bool(g[3]), 90.0,
			String(g[0])))


# ---------------------------------------------------------------- the real map

func _run_map() -> void:
	var main: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	for i in 10:
		await process_frame
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer and n.name != "Vignette":
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_rig = main.get(&"camera_rig")
	_rig.set(&"edge_pan_enabled", false)
	var gm: ShaderMaterial = _read_map(main)
	_river = _gp.call(&"skirmish_river")
	for p: Array in PATCHES:
		_patches.append([p[1], p[2]])
		_patches.append([-(p[1] as Vector2), p[2]])
	var decor := Node3D.new()
	decor.name = "SandPreview"
	main.add_child(decor)
	_paint_sand(decor, gm)
	# What clears the patches on the real map (for 12b.V6): spots (neutral-site paving) and decor-clear objects.
	for p2: Array in _patches:
		var c2: Vector2 = p2[0]
		var why: Array[String] = []
		for s: Vector4 in _spots:
			if c2.distance_to(Vector2(s.x, s.y)) < s.z + maxf((p2[1] as Vector2).x, (p2[1] as Vector2).y):
				why.append("spot (%.0f, %.0f) r %.1f" % [s.x, s.y, s.z])
		for a: Vector3 in _avoid:
			if a.z >= 2.5 and c2.distance_to(Vector2(a.x, a.y)) < a.z + 4.0:
				why.append("clear (%.0f, %.0f) r %.1f" % [a.x, a.y, a.z])
		print("patch (%.0f, %.0f): %s" % [c2.x, c2.y, ", ".join(why) if not why.is_empty() else "free"])
		# Share of the patch (w > 0.5, 0.25 m grid) each rule blocks for a small item (margin 0.25).
		var tally := {"free": 0, "water": 0, "lane": 0, "spot": 0, "road": 0, "object": 0}
		var r2: Vector2 = p2[1]
		var x := c2.x - r2.x
		while x <= c2.x + r2.x:
			var z := c2.y - r2.y
			while z <= c2.y + r2.y:
				var q := Vector2(x, z)
				if patch_weight(q, c2, r2) > 0.5:
					tally[_block_reason(q, 0.25)] += 1
				z += 0.25
			x += 0.25
		print("   cells: %s" % tally)
	_scatter_sand(decor)
	print("sand instances on the map: %d (budget %d)" % [_count,
		int((load(SET_PATH) as GDScript).get_script_constant_map()["INSTANCE_BUDGET"])])
	await _shoot("map_terrace_z40", 40.0, Vector3(-8.0, 0.0, 41.0))
	await _shoot("map_dunes_z40", 40.0, Vector3(-53.0, 0.0, -10.0))
	print("SHOTS DONE")
	quit()


## The obstacles MapDressingArt reads (lane / spots / roads from the painted ground, trees and props from EnvProps,
## crystal nodes, buildings, capture points, taverns, trade posts, decor-clear metadata). Returns the ground material.
func _read_map(level: Node) -> ShaderMaterial:
	var ground_mat: ShaderMaterial = null
	for mi: Node in level.find_children("*", "MeshInstance3D", true, false):
		var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == "res://art/environment/ground.gdshader" \
				and (mi as MeshInstance3D).mesh is PlaneMesh:
			ground_mat = sm
			var la: Variant = sm.get_shader_parameter(&"lane_a")
			var lb: Variant = sm.get_shader_parameter(&"lane_b")
			if la is Vector2 and lb is Vector2:
				_lane_a = la
				_lane_b = lb
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
	var env: Node = level.get(&"env_props") if &"env_props" in level else null
	if env:
		for c: Node in env.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null or mmi.multimesh == null:
				continue
			for i: int in mmi.multimesh.instance_count:
				var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
				_avoid.append(Vector3(xf.origin.x, xf.origin.z, 1.1 * xf.basis.get_scale().x))
	for grp: StringName in [&"crystal_nodes", &"capture_points", &"taverns", &"trade_posts"]:
		for n: Node in root.get_tree().get_nodes_in_group(grp):
			if n is Node3D:
				var p: Vector3 = (n as Node3D).global_position
				_avoid.append(Vector3(p.x, p.z, 3.0))
	for b: Node in root.get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D:
			var pb: Vector3 = (b as Node3D).global_position
			var r: float = float(b.call(&"target_radius")) + 1.0 if b.has_method(&"target_radius") else 4.0
			_avoid.append(Vector3(pb.x, pb.z, r))
	for n2: Node in level.find_children("*", "Node3D", true, false):
		if n2.has_meta(&"decor_clear_radius"):
			var p2: Vector3 = (n2 as Node3D).global_position
			_avoid.append(Vector3(p2.x, p2.z, float(n2.get_meta(&"decor_clear_radius"))))
	return ground_mat
