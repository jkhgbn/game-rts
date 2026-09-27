extends SceneTree
## Task 12b.V2 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/snow/snow_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000 -- mode=stage
## The snow GROUND is a preview stand-in (SNOW_STAND_IN below: terrain.md 7.1's colours, posterised drifts, wind
## streaks, frost rim, sparkle, noisy edge), drawn as a transparent sheet over the painted ground, because the real
## layer is 12b.V1's (ground.gdshader `terrain_mask`). The decor is scattered from snow_set.gd ENTRIES with the rules
## the set documents (places &"snow" / &"snow_edge" with its EDGE_BAND, per_100m2, cluster, scale, gap).
## mode=stage (default): painted Crown Hollow ground (no river), the Mossmere Frost and Rimefall snowfields at their
##   terrain.md 4.2 spots, the map-edge cliffs, the lighting rig, the game camera (pitch 55). Saves
##   docs/art/screens/12b_v2_patch_z40.png, 12b_v2_rimefall_z40.png, 12b_v2_patch_z25.png, 12b_v2_close_z12.png, the
##   contact sheet 12b_v2_contact.png (each mesh with its 3 variants, close) and 12b_v2_lineup_z40.png.
## mode=map: the real skirmish map (bot off, fog off, HUD hidden), all 4 snowfields scattered clear of the lane,
##   roads, slots, water, buildings, trees, capture points, lairs and crystal nodes; the existing small grass decor on
##   the snow is thinned (what 12b.V6 will do): 12b_v2_map_well_z40.png, 12b_v2_map_rimefall_z40.png,
##   12b_v2_map_mirror_z40.png.

const SET_PATH := "res://art/environment/biomes/snow/snow_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const SHOT_DIR := "res://docs/art/screens/"
const PATCH_SIZE := 8.0      ## instances per patch (the `cluster` part)
const PATCH_SPREAD := 1.2    ## gaussian sigma of a patch, metres (x2 for gap rows)
const EDGE_SPREAD := 0.7     ## tighter patches along the 1 m edge band
## terrain.md 4.2 snowfields, player half: (x, z, rx, rz). Mirrors at (-x, -z).
const SNOWFIELDS: Array[Vector4] = [Vector4(-31.0, -24.0, 5.5, 5.5), Vector4(-22.0, -54.0, 7.0, 4.5)]
const LINEUP_Z := 52.0
## Small decor of the other biomes that 12b.V6 thins out on snow (map mode emulates it).
const THIN_KINDS: Array[String] = ["grass", "tuft", "clover", "dais", "dandelion", "flower", "heather", "fern", "hay"]

const SNOW_STAND_IN := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 patches[6];
uniform int patch_count = 0;
varying vec3 v_wp;
float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float edge_noise(vec2 p) {
	return 0.7 * sin(0.9 * p.x + 1.3 * sin(0.7 * p.y)) * cos(0.8 * p.y - 0.35 * p.x)
		+ 0.35 * sin(2.1 * p.x + 1.7 * p.y) * cos(1.9 * p.y - 0.6 * p.x);
}
float sdf(vec2 p, vec4 e) {
	vec2 q = (p - e.xy) / e.zw;
	float l = max(length(q), 0.0001);
	vec2 g = q / (e.zw * l);
	return (l - 1.0) / max(length(g), 0.0001);
}
void vertex() { v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = v_wp.xz;
	float d = 1e3;
	for (int i = 0; i < patch_count; i++) { d = min(d, sdf(p, patches[i])); }
	d += edge_noise(p);
	float w = 1.0 - smoothstep(-0.1, 0.1, d);
	float hole = texture(noise_tex, p * 0.19 + vec2(1.7, 4.2)).r;
	w *= 1.0 - smoothstep(0.66, 0.7, hole) * smoothstep(-1.3, -0.5, d);
	if (w < 0.004) { discard; }
	vec3 base = pow(vec3(0.90, 0.93, 0.98), vec3(2.2));
	vec3 shade = pow(vec3(0.62, 0.72, 0.88), vec3(2.2));
	vec3 rimc = pow(vec3(0.80, 0.88, 0.96), vec3(2.2));
	float n1 = texture(noise_tex, p * 0.07).r;
	float n2 = texture(noise_tex, p * 0.21 + vec2(3.1, 7.7)).r;
	float steps = floor(clamp((n1 * 0.65 + n2 * 0.35 - 0.3) * 2.4, 0.0, 0.999) * 3.0) / 2.0;
	vec3 col = mix(shade, base, 0.5 + 0.5 * steps);
	vec2 wd = normalize(vec2(0.8, 0.6));
	float st = texture(noise_tex, vec2(dot(p, wd) * 0.04, dot(p, vec2(-wd.y, wd.x)) * 0.55)).r;
	col = mix(col, base, smoothstep(0.58, 0.72, st) * 0.4);
	col = mix(col, shade, smoothstep(0.34, 0.22, st) * 0.25);
	col = mix(col, rimc, smoothstep(-1.0, -0.15, d) * 0.7);
	col = mix(col, shade * 0.8, smoothstep(-0.25, -0.05, d) * 0.35);
	vec2 cell = floor(p * 16.0);
	float h = hash1(cell);
	float s = step(0.994, h) * (0.5 + 0.5 * sin(TIME * 2.3 + h * 60.0));
	ALBEDO = col;
	EMISSION = vec3(0.9, 0.95, 1.0) * s * 1.4;
	ALPHA = w;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	float dd = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, dd) * 0.55 + smoothstep(0.58, 0.68, dd) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}
"""

var _mode := "stage"
var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _entries: Array = []
var _consts: Dictionary = {}
var _gp: GDScript
var _river: Dictionary = {}
var _fields: Array[Vector4] = []
var _edge := 59.6
var _lane_a := Vector2(1000, 1000)
var _lane_b := Vector2(1001, 1001)
var _spots: Array[Vector4] = []
var _roads: Array[Vector4] = []
var _avoid: Array[Vector3] = []
var _count := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			_mode = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_consts = (load(SET_PATH) as GDScript).get_script_constant_map()
	_entries = _consts["ENTRIES"]
	_gp = load(GP_PATH) as GDScript
	_rng.seed = 12102
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


# ---------------------------------------------------------------- snowfield shape (= the stand-in shader)

func _edge_noise(p: Vector2) -> float:
	return 0.7 * sin(0.9 * p.x + 1.3 * sin(0.7 * p.y)) * cos(0.8 * p.y - 0.35 * p.x) \
		+ 0.35 * sin(2.1 * p.x + 1.7 * p.y) * cos(1.9 * p.y - 0.6 * p.x)


func _sdf(p: Vector2, e: Vector4) -> float:
	var c := Vector2(e.x, e.y)
	var s := Vector2(e.z, e.w)
	var q: Vector2 = (p - c) / s
	var l: float = maxf(q.length(), 0.0001)
	var g: Vector2 = q / (s * l)
	return (l - 1.0) / maxf(g.length(), 0.0001)


## Signed distance (m) to the noisy snow outline: < 0 inside the snow.
func snow_distance(p: Vector2) -> float:
	var d := 1e3
	for e: Vector4 in _fields:
		d = minf(d, _sdf(p, e))
	return d + _edge_noise(p)


func _in_place(p: Vector2, place: StringName) -> bool:
	var half: float = float(_consts["EDGE_BAND"]) * 0.5
	var d: float = snow_distance(p)
	if place == &"snow_edge":
		return absf(d) <= half
	return d < -half


func _stand_in(parent: Node3D, fields: Array[Vector4]) -> void:
	var sh := Shader.new()
	sh.code = SNOW_STAND_IN
	var m := ShaderMaterial.new()
	m.shader = sh
	m.render_priority = -2   # under the contact discs (-1), which multiply onto it
	m.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	var arr := PackedVector4Array()
	arr.resize(6)
	for i: int in mini(fields.size(), 6):
		arr[i] = fields[i]
	m.set_shader_parameter(&"patches", arr)
	m.set_shader_parameter(&"patch_count", mini(fields.size(), 6))
	for f: Vector4 in fields:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(f.z * 2.0 + 4.0, f.w * 2.0 + 4.0)
		mi.mesh = pm
		mi.material_override = m
		mi.position = Vector3(f.x, 0.012, f.y)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)


# ---------------------------------------------------------------- scatter (the set file's rules)

func _blocked(q: Vector2, margin: float) -> bool:
	if absf(q.x) > _edge or absf(q.y) > _edge:
		return true
	if not _river.is_empty():
		if float(_gp.call(&"water_distance", _river, q)) < 0.6 + margin:
			return true
	var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, _lane_a, _lane_b)
	if q.distance_to(c) < 5.2 + margin:
		return true
	for s: Vector4 in _spots:
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


func _ok(p: Vector2, place: StringName, margin: float) -> bool:
	return _in_place(p, place) and not _blocked(p, margin)


func _scatter(parent: Node3D) -> void:
	var total := 0
	var by_mesh := {}
	for e: Dictionary in _entries:
		var path: String = e["mesh"]
		var place: StringName = e["place"]
		var sc: Vector2 = e["scale"]
		var gap: float = float(e.get("gap", 0.0))
		var margin: float = gap * 0.5 if gap > 0.0 else 0.25
		var cluster: float = e["cluster"]
		var spread: float = (EDGE_SPREAD if place == &"snow_edge" else PATCH_SPREAD) * (2.0 if gap > 0.0 else 1.0)
		if not by_mesh.has(path):
			by_mesh[path] = [] as Array[Transform3D]
		var xfs: Array[Transform3D] = by_mesh[path]
		var placed := 0
		for f: Vector4 in _fields:
			var lo := Vector2(f.x - f.z - 1.5, f.y - f.w - 1.5)
			var hi := Vector2(f.x + f.z + 1.5, f.y + f.w + 1.5)
			var n_full: float = float(e["per_100m2"]) * (hi.x - lo.x) * (hi.y - lo.y) / 100.0
			for i: int in int(round(n_full * (1.0 - cluster))):
				var p := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
				if _ok(p, place, margin) and _gap_ok(xfs, p, gap):
					xfs.append(_xf(p, sc))
					placed += 1
			for k: int in int(round(n_full * cluster / PATCH_SIZE)):
				var pc := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
				if not _ok(pc, place, margin):
					continue
				for j: int in int(PATCH_SIZE):
					for attempt: int in 3:
						var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, spread), _rng.randfn(0.0, spread))
						if _ok(p2, place, margin):
							if _gap_ok(xfs, p2, gap):
								xfs.append(_xf(p2, sc))
								placed += 1
							break
		print("scatter %-20s %-10s %4d instances (%.1f / 100 m2)" % [String(e["id"]), String(place), placed,
			float(e["per_100m2"])])
		total += placed
	for path: String in by_mesh:
		var xfs2: Array[Transform3D] = by_mesh[path]
		var info: Dictionary = {}
		for e2: Dictionary in _entries:
			if e2["mesh"] == path:
				info = e2
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = load(path) as Mesh
		mm.instance_count = xfs2.size()
		for i: int in xfs2.size():
			mm.set_instance_transform(i, xfs2[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = path.get_file().get_basename().to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(info["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(info["range"])
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mmi)
	_count += total
	print("scatter total %d instances over %d snowfields (budget %d)" % [total, _fields.size(),
		int(_consts["INSTANCE_BUDGET"])])


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
		img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v2_%s.png" % shot))
	return img


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


## [mesh, centre x, spacing, close-up zoom, focus z offset] per lineup group.
func _groups() -> Array:
	return [["snow_capped_rocks", -3.6, 2.7, 6.5, -0.5], ["snow_frost_scrub", 5.2, 1.45, 4.2, -0.35]]


func _build_lineup(stage: Node3D) -> void:
	for g: Array in _groups():
		var mesh := load("res://art/environment/biomes/snow/%s.res" % g[0]) as Mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 3
		for i in 3:
			var x: float = float(g[1]) + (i - 1) * float(g[2])
			var pos: Vector3 = _find_variant(Vector3(x, 0.0, LINEUP_Z), i)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, [0.5, -1.25, 4.3][i]), pos))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if g[0] == "snow_capped_rocks" \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stage.add_child(mmi)


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
	gm.set_shader_parameter(&"road_count", 0)
	_gp.call(&"apply", gm, _gp.call(&"skirmish_biomes"))
	ground.material_override = gm
	stage.add_child(ground)
	if ResourceLoader.exists("res://art/environment/map_dressing.tscn"):
		var md: Node = (load("res://art/environment/map_dressing.tscn") as PackedScene).instantiate()
		md.set_script(null)
		stage.add_child(md)
	_fields = SNOWFIELDS.duplicate()
	var sheet_field := Vector4(0.8, LINEUP_Z, 11.0, 4.5)
	var all: Array[Vector4] = _fields.duplicate()
	all.append(sheet_field)
	_stand_in(stage, all)
	var patch := Node3D.new()
	patch.name = "Snow"
	stage.add_child(patch)
	_scatter(patch)
	_build_lineup(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("patch_z40", 40.0, Vector3(-31.0, 0, -22.0))
	await _shoot("rimefall_z40", 40.0, Vector3(-22.0, 0, -52.0))
	await _shoot("patch_z25", 25.0, Vector3(-31.0, 0, -23.0))
	await _shoot("close_z12", 12.0, Vector3(-29.0, 0, -22.0))
	# Contact sheet: the middle band of one close shot per mesh (3 variants each), stacked.
	var bands: Array[Image] = []
	for g: Array in _groups():
		var img: Image = await _shoot("", float(g[3]), Vector3(float(g[1]), 0.0, LINEUP_Z + float(g[4])))
		img.convert(Image.FORMAT_RGBA8)
		var w: int = img.get_width()
		var h: int = img.get_height()
		bands.append(img.get_region(Rect2i(0, h / 5, w, h * 3 / 5)))
	var bw: int = bands[0].get_width()
	var bh: int = bands[0].get_height()
	var sheet := Image.create(bw, bh * 2 + 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	for i: int in bands.size():
		sheet.blit_rect(bands[i], Rect2i(0, 0, bw, bh), Vector2i(0, i * (bh + 4)))
	sheet.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v2_contact.png"))
	print("saved 12b_v2_contact.png")
	await _shoot("lineup_z40", 40.0, Vector3(1.0, 0, LINEUP_Z - 3.0))
	print("SHOTS DONE")
	quit()


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
	for i in 30:
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
	_river = _gp.call(&"skirmish_river")
	_fields = []
	for f: Vector4 in SNOWFIELDS:
		_fields.append(f)
		_fields.append(Vector4(-f.x, -f.y, f.z, f.w))
	_read_map(main)
	_thin_decor(main)
	var patch := Node3D.new()
	patch.name = "SnowPreview"
	main.add_child(patch)
	_stand_in(patch, _fields)
	_scatter(patch)
	await _shoot("map_well_z40", 40.0, Vector3(-31.0, 0.0, -22.0))
	await _shoot("map_rimefall_z40", 40.0, Vector3(-22.0, 0.0, -51.0))
	await _shoot("map_mirror_z40", 40.0, Vector3(31.0, 0.0, 26.0))
	print("SHOTS DONE")
	quit()


## Hides the small grass / flower decor of the other biomes on the snow (12b.V6 "grass tufts thin out on snow").
func _thin_decor(level: Node) -> void:
	var hidden := 0
	for n: Node in level.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or mmi.multimesh.mesh == null:
			continue
		var path: String = mmi.multimesh.mesh.resource_path.get_file().to_lower()
		var thin := false
		for k: String in THIN_KINDS:
			if path.contains(k):
				thin = true
		if not thin:
			continue
		var gxf: Transform3D = mmi.global_transform
		for i: int in mmi.multimesh.instance_count:
			var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
			var o: Vector3 = gxf * xf.origin
			if snow_distance(Vector2(o.x, o.z)) < 0.2:
				mmi.multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)),
					xf.origin - Vector3(0.0, 2.0, 0.0)))
				hidden += 1
	print("thinned %d small decor instances on the snow" % hidden)


## The same obstacles MapDressingArt reads (heath_preview.gd's list): lane / spots / roads from the painted ground,
## trees and props from EnvProps, crystal nodes (+6 m, terrain.md 4.1), buildings, capture points, taverns, posts,
## lairs / camps (their decor-free radius).
func _read_map(level: Node) -> void:
	for mi: Node in level.find_children("*", "MeshInstance3D", true, false):
		var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == "res://art/environment/ground.gdshader" \
				and (mi as MeshInstance3D).mesh is PlaneMesh:
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
	for grp: StringName in [&"capture_points", &"taverns", &"trade_posts"]:
		for n: Node in root.get_tree().get_nodes_in_group(grp):
			if n is Node3D:
				var p: Vector3 = (n as Node3D).global_position
				_avoid.append(Vector3(p.x, p.z, 3.0))
	for n3: Node in root.get_tree().get_nodes_in_group(&"crystal_nodes"):
		if n3 is Node3D:
			var p3: Vector3 = (n3 as Node3D).global_position
			_avoid.append(Vector3(p3.x, p3.z, 2.5))
	for b: Node in root.get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D:
			var pb: Vector3 = (b as Node3D).global_position
			var r: float = float(b.call(&"target_radius")) + 1.0 if b.has_method(&"target_radius") else 4.0
			_avoid.append(Vector3(pb.x, pb.z, r))
	for n2: Node in level.find_children("*", "Node3D", true, false):
		if n2.has_meta(&"decor_clear_radius"):
			var p2: Vector3 = (n2 as Node3D).global_position
			_avoid.append(Vector3(p2.x, p2.z, float(n2.get_meta(&"decor_clear_radius"))))
