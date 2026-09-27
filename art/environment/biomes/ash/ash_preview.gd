extends SceneTree
## Task 12b.V4 previews of the ash set. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/ash/ash_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000
## The painted ground with the Crown Hollow biome zones, the West Cinder Scar at (-31, 2) r 4.5 (terrain.md 4.2) drawn
## by a PREVIEW-ONLY stand-in of the 12b.V1 ash ground layer (terrain.md 7.1 colours: blotches, charred rim, ember
## specks; the real one is the ground shader's), scattered from ash_set.gd ENTRIES with the rules the set file documents
## (per_100m2 of the &"ash" / &"ash_edge" areas, cluster, scale, gap), its static-scar particles (AshSet.scar_fx), the warm
## lighting rig and the game camera (pitch 55). Saves docs/art/screens/12b_v4_ash_z40.png (+ terrain_ash.png),
## 12b_v4_ash_z25.png, 12b_v4_ash_z12.png, 12b_v4_ash_contact.png (every mesh's 3 variants, close, on ash) and
## 12b_v4_ash_lineup_z40.png; prints render stats.
## nodecor=1: the same shots without the ash decor / particles (cost baseline, nothing saved).

const SET_PATH := "res://art/environment/biomes/ash/ash_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const SHOT_DIR := "res://docs/art/screens/"
const SCAR := Vector3(-31.0, 0.0, 2.0)
const SCAR_R := 4.5
const LINEUP := Vector3(-31.0, 0.0, 22.0)
const PATCH_SIZE := 8.0
const PATCH_SPREAD := 1.0
## terrain.md 7.1 ash look, for the stand-in ground patch only.
const STANDIN_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform vec2 centre = vec2(-31.0, 2.0);
uniform float radius = 4.5;
varying vec2 w;
float hash(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y); }
void vertex() { w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz; }
void fragment() {
	vec2 q = w - centre;
	float ang = atan(q.y, q.x);
	float edge = radius + (vn(vec2(cos(ang), sin(ang)) * 1.6 + 3.0) * 0.6 + vn(q * 0.9) * 0.4 - 0.5) * 2.0;
	float d = length(q);
	float wgt = clamp(0.5 - (d - edge) / 1.0, 0.0, 1.0);
	if (wgt <= 0.3) { discard; }
	float n = vn(q * 0.8) * 0.6 + vn(q * 2.3 + 7.0) * 0.4;
	vec3 c = mix(vec3(0.20, 0.18, 0.17), vec3(0.34, 0.31, 0.29), smoothstep(0.35, 0.7, n));
	float rim = exp(-pow((d - edge + 0.35) / 0.35, 2.0));
	c = mix(c, vec3(0.1, 0.08, 0.07), rim * 0.7);
	vec2 cell = floor(q * 2.0);
	float sp = step(0.975, hash(cell + 3.1)) * (1.0 - smoothstep(0.08, 0.2, length(fract(q * 2.0) - 0.5)));
	ALBEDO = pow(c, vec3(2.2)) * 1.1;
	EMISSION = vec3(1.0, 0.45, 0.12) * sp * (0.6 + 0.6 * sin(TIME * 3.0 + hash(cell) * 20.0)) * wgt;
}
"""

var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _entries: Array = []
var _no_decor := false
var _count := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "nodecor=1":
			_no_decor = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_entries = (load(SET_PATH) as GDScript).get_script_constant_map()["ENTRIES"]
	_rng.seed = 12404
	_run()


# ---------------------------------------------------------------- the set's scatter rules

func _noise(p: Vector2) -> float:
	return fposmod(sin(p.dot(Vector2(12.9898, 78.233))) * 43758.5453, 1.0)


func _vn(p: Vector2) -> float:
	var i := p.floor()
	var f := p - i
	f = f * f * (Vector2(3, 3) - f * 2.0)
	return lerpf(lerpf(_noise(i), _noise(i + Vector2(1, 0)), f.x), lerpf(_noise(i + Vector2(0, 1)),
			_noise(i + Vector2(1, 1)), f.x), f.y)


## Ash mask weight at q for a patch (the stand-in's noisy 1 m edge, the same formula as its shader).
func _weight(q: Vector2, c: Vector2, r: float) -> float:
	var d: Vector2 = q - c
	var ang := atan2(d.y, d.x)
	var edge := r + (_vn(Vector2(cos(ang), sin(ang)) * 1.6 + Vector2(3.0, 3.0)) * 0.6 + _vn(d * 0.9) * 0.4 - 0.5) * 2.0
	return clampf(0.5 - (d.length() - edge) / 1.0, 0.0, 1.0)


func _place_ok(place: StringName, wgt: float) -> bool:
	return wgt > 0.5 if place == &"ash" else (wgt >= 0.2 and wgt <= 0.5)


func _scatter(parent: Node3D, c: Vector2, r: float) -> void:
	if _no_decor:
		return
	var rect := Rect2(c - Vector2(r + 1.5, r + 1.5), Vector2(r + 1.5, r + 1.5) * 2.0)
	var by_mesh: Dictionary = {}
	for e: Dictionary in _entries:
		var sc: Vector2 = e["scale"]
		var gap: float = float(e.get("gap", 0.0))
		var place: StringName = e["place"]
		var n_full: float = float(e["per_100m2"]) * rect.get_area() / 100.0
		var cluster: float = e["cluster"]
		var xfs: Array = by_mesh.get(e["mesh"], [])
		var mine: Array[Transform3D] = []
		for i: int in int(round(n_full * (1.0 - cluster))):
			var p := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
			if _place_ok(place, _weight(p, c, r)) and _gap_ok(mine, p, gap) and _clear(p, gap):
				mine.append(_xf(p, sc))
		for k: int in int(round(n_full * cluster / PATCH_SIZE)):
			var pc := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
			for j: int in int(PATCH_SIZE):
				var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, PATCH_SPREAD), _rng.randfn(0.0, PATCH_SPREAD))
				if _place_ok(place, _weight(p2, c, r)) and _gap_ok(mine, p2, gap) and _clear(p2, gap):
					mine.append(_xf(p2, sc))
		print("scatter %-18s %3d instances (%.0f / 100 m2 of %s)" % [e["id"], mine.size(), float(e["per_100m2"]), place])
		_count += mine.size()
		xfs.append_array(mine)
		by_mesh[e["mesh"]] = xfs
	for path: String in by_mesh:
		var list: Array = by_mesh[path]
		var e0: Dictionary = {}
		for e: Dictionary in _entries:
			if e["mesh"] == path:
				e0 = e
				break
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = load(path) as Mesh
		mm.instance_count = list.size()
		for i: int in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = path.get_file().get_basename().to_pascal_case()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(e0["shadow"]) \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(e0["range"])
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mmi)


## The Lost Cache (-30, 0) sits in the West Cinder Scar: big pieces keep ~1.5 m off it (as 12b.V6 will).
func _clear(p: Vector2, gap: float) -> bool:
	return gap <= 0.0 or p.distance_to(Vector2(-30.0, 0.0)) > 1.5 + gap * 0.5


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


# ---------------------------------------------------------------- stage and shots

func _standin(parent: Node3D, c: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2((r + 2.0) * 2.0, (r + 2.0) * 2.0)
	pm.subdivide_width = 4
	pm.subdivide_depth = 4
	mi.mesh = pm
	var sh := Shader.new()
	sh.code = STANDIN_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter(&"centre", Vector2(c.x, c.z))
	sm.set_shader_parameter(&"radius", r)
	sm.render_priority = -1
	mi.material_override = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = Vector3(c.x, 0.012, c.z)


func _run() -> void:
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
	var gp := load(GP_PATH) as GDScript
	gp.call(&"apply", gm, gp.call(&"skirmish_biomes"))
	ground.material_override = gm
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(ground)
	var set_script := load(SET_PATH) as GDScript
	_standin(stage, SCAR, SCAR_R)
	var decor := Node3D.new()
	decor.name = "AshDecor"
	stage.add_child(decor)
	_scatter(decor, Vector2(SCAR.x, SCAR.z), SCAR_R)
	print("ash instances on one scar: %d (both scars ~%d, budget %d)" % [_count, _count * 2,
			int(set_script.get_script_constant_map()["INSTANCE_BUDGET"])])
	if not _no_decor:
		var fx: Node3D = set_script.call(&"scar_fx", SCAR, SCAR_R)
		if fx:
			stage.add_child(fx)
	_standin(stage, LINEUP, 4.0)
	_build_lineup(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 3.0)
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("ash_z40", 40.0, SCAR + Vector3(0, 0, 1.0), 60, "terrain_ash")
	await _shoot("ash_z25", 25.0, SCAR + Vector3(0, 0, 0.5))
	await _shoot("ash_z12", 12.0, SCAR + Vector3(-0.5, 0, -0.5))
	var cells: Array[Image] = []
	cells.append(await _shoot("", 5.5, LINEUP + Vector3(-3.4, 0.0, -0.6)))
	cells.append(await _shoot("", 4.2, LINEUP + Vector3(3.2, 0.0, -0.4)))
	var w: int = cells[0].get_width()
	var h: int = cells[0].get_height()
	var sheet := Image.create(w, h / 2, false, Image.FORMAT_RGBA8)
	for i in cells.size():
		var q: Image = cells[i]
		q.convert(Image.FORMAT_RGBA8)
		q.resize(w / 2, h / 2, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(q, Rect2i(0, 0, w / 2, h / 2), Vector2i(i * (w / 2), 0))
	for y: int in h / 2:
		sheet.set_pixel(w / 2, y, Color(0.1, 0.1, 0.1))
	if not _no_decor:
		sheet.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v4_ash_contact.png"))
	await _shoot("ash_lineup_z40", 40.0, LINEUP + Vector3(0, 0, -2.0))
	print("SHOTS DONE")
	quit()


func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40, also: String = "") -> Image:
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
	print("shot %-16s draws=%d prims=%d gpu_ms=%.2f" % [shot, Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(
			Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), gpu])
	var img: Image = root.get_texture().get_image()
	if _no_decor or shot == "":
		return img
	img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v4_%s.png" % shot))
	if also != "":
		img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "%s.png" % also))
	return img


## nature_painted.gdshader's hash1 (the variant the GPU draws, also in ash_char.gdshader).
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


## Every mesh with its 3 variants side by side on the lineup's ash patch.
func _build_lineup(stage: Node3D) -> void:
	var groups := [["ash_charred_wood", -3.4, 2.4, 0.5], ["ash_burnt_grass", 3.2, 0.9, 0.0]]
	for g: Array in groups:
		var mesh := load("res://art/environment/biomes/ash/%s.res" % g[0]) as Mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 3
		for i in 3:
			var pos: Vector3 = _find_variant(LINEUP + Vector3(float(g[1]) + (i - 1) * float(g[2]), 0.0, 0.0), i)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, float(g[3]) + i * 0.8), pos))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		stage.add_child(mmi)
