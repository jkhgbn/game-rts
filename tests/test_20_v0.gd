extends SceneTree
## Task 20.V0 (GOLDEN AUTUMN art direction for Fourfold Hollow): art/environment/autumn/.
## Run: $GODOT --headless --path . -s tests/test_20_v0.gd --fixed-fps 60 --quit-after 600
## Checks: every autumn file loads with the right type; the material variants only set uniforms their shader declares
## and the shader variants keep every uniform of the originals (drop-in swaps); the ground preset's keys are all
## ground.gdshader uniforms (4 biome tints); the lighting preset is a LightingPreset with its own environment; the value
## structure of docs/art/style-autumn.md 3 (CIE76 dE >= 20 between each kingdom's team colour and every autumn ground
## tone, grass mean L* in the mid band 25-55);
## autumn_swap.gd swaps the shared nature material and paints a ground material.
## Prints "PASS 20.v0" or "FAIL 20.v0: <reasons>".

const TASK_ID := "20.v0"
const DIR := "res://art/environment/autumn/"
const FILES: Dictionary = {
	"nature_autumn.gdshader": "Shader", "horizon_autumn.gdshader": "Shader",
	"nature_autumn_mat.tres": "ShaderMaterial", "horizon_autumn_mat.tres": "ShaderMaterial",
	"water_autumn_mat.tres": "ShaderMaterial", "world_env_autumn.tres": "Environment",
	"preset_autumn.tres": "Resource", "autumn_ground_params.gd": "GDScript", "autumn_swap.gd": "GDScript",
	"autumn_preview.gd": "GDScript",
}
## Variant shader -> the original it must stay a superset of.
const SHADER_PAIRS: Array = [
	["res://art/environment/autumn/nature_autumn.gdshader", "res://art/environment/nature_props/nature_painted.gdshader"],
	["res://art/environment/autumn/horizon_autumn.gdshader", "res://art/environment/horizon/horizon.gdshader"],
]
## art-keep.md 0.2 team colours (sRGB) + the Nature glow (Nature units wear both greens).
const TEAM: Dictionary = {
	"fire": Color(0.85, 0.30, 0.12), "shadow": Color(0.42, 0.22, 0.60), "ice": Color(0.45, 0.75, 0.95),
	"nature": Color(0.35, 0.70, 0.25),
}

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	# 1. Files and types.
	for f: String in FILES:
		var path: String = DIR + f
		_check(ResourceLoader.exists(path), "missing " + path)
		if not ResourceLoader.exists(path):
			continue
		var r: Resource = load(path)
		_check(r != null and r.is_class(FILES[f]), "%s is not a %s" % [f, FILES[f]])
	# 2. Shader variants are supersets of the originals (a drop-in material swap keeps every tuned parameter).
	for pair: Array in SHADER_PAIRS:
		var a: Dictionary = _uniforms(load(pair[0]) as Shader)
		var b: Dictionary = _uniforms(load(pair[1]) as Shader)
		for k: String in b:
			_check(a.has(k), "%s lost uniform %s" % [pair[0].get_file(), k])
		_check((load(pair[0]) as Shader).code.contains("AUTUMN 20.V0"), pair[0].get_file() + " has no marked block")
	# 3. Every parameter a variant sets is declared by its shader.
	for f: String in ["nature_autumn_mat.tres", "horizon_autumn_mat.tres", "water_autumn_mat.tres"]:
		var m := load(DIR + f) as ShaderMaterial
		if m == null:
			continue
		var names: Dictionary = _uniforms(m.shader)
		for p: Dictionary in m.get_property_list():
			var pn: String = p.get("name", "")
			if pn.begins_with("shader_parameter/"):
				var u: String = pn.substr(17)
				if m.get_shader_parameter(StringName(u)) != null:
					_check(names.has(u), "%s sets unknown uniform %s" % [f, u])
	var nm := load(DIR + "nature_autumn_mat.tres") as ShaderMaterial
	if nm:
		_check(float(nm.get_shader_parameter(&"autumn_chance")) >= 1.0, "nature_autumn_mat: autumn_chance < 1")
	# 4. Ground preset.
	var ap: GDScript = load(DIR + "autumn_ground_params.gd")
	var gp: Dictionary = ap.call(&"ground_params")
	var gnames: Dictionary = _uniforms(load("res://art/environment/ground.gdshader") as Shader)
	for k: Variant in gp:
		_check(gnames.has(String(k)), "ground preset key %s is not a ground uniform" % k)
	var tints: PackedColorArray = gp.get(&"biome_tints", PackedColorArray())
	_check(tints.size() == 4, "biome_tints size %d != 4" % tints.size())
	for zone_key: String in ["river_segs", "biome_hubs", "lane_a", "spot_0", "map_half"]:
		_check(not gp.has(StringName(zone_key)), "ground preset must not set zone uniform " + zone_key)
	# 5. Lighting preset.
	var pr: Resource = load(DIR + "preset_autumn.tres")
	_check(pr is LightingPreset, "preset_autumn.tres is not a LightingPreset")
	if pr is LightingPreset:
		var lp := pr as LightingPreset
		_check(lp.environment != null and lp.environment.resource_path.ends_with("world_env_autumn.tres"),
				"preset_autumn has not world_env_autumn.tres")
		_check(lp.sun_color.r > lp.sun_color.b + 0.3, "autumn sun is not golden")
		_check(lp.sun_rotation_degrees.x <= -38.0 and lp.sun_rotation_degrees.x >= -56.0,
				"sun pitch %.1f outside -56..-38 (shadow length readability)" % lp.sun_rotation_degrees.x)
		if lp.environment:
			_check(lp.environment.fog_enabled, "autumn environment has no fog")
	# 6. Value structure (style-autumn.md 3).
	var ground_tones: Array = [gp[&"grass_dark"], gp[&"grass_light"], gp[&"grass_warm"], gp[&"grass_cool"],
			gp[&"grass_dry"], gp[&"dirt_color"], gp[&"road_color"]]
	for t: Color in tints:
		ground_tones.append(t)
	var mean_l := 0.0
	for g: Color in ground_tones.slice(0, 5):
		mean_l += _lab(g).x / 5.0
	print("  autumn grass mean L* %.1f" % mean_l)
	_check(mean_l >= 25.0 and mean_l <= 55.0, "grass mean L* %.1f outside 25-55" % mean_l)
	for kname: String in TEAM:
		var tc: Vector3 = _lab(TEAM[kname])
		var worst := INF
		for g: Color in ground_tones:
			worst = minf(worst, tc.distance_to(_lab(g)))
		print("  %s team colour: min dE to autumn ground %.1f" % [kname, worst])
		_check(worst >= 20.0, "%s team colour dE %.1f < 20 on the autumn ground" % [kname, worst])
	# 7. Runtime swap.
	var sw: GDScript = load(DIR + "autumn_swap.gd")
	var n: int = sw.call(&"swap_shared_materials")
	_check(n >= 2, "swap_shared_materials changed %d materials (< 2)" % n)
	var shared := load("res://art/environment/nature_props/nature_mat.tres") as ShaderMaterial
	_check(shared != null and shared.shader.resource_path.ends_with("nature_autumn.gdshader"),
			"nature_mat.tres did not take the autumn shader")
	var holder := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = PlaneMesh.new()
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	mi.material_override = gm
	holder.add_child(mi)
	root.add_child(holder)
	var painted: int = sw.call(&"apply_ground", holder)
	_check(painted >= 1, "apply_ground painted %d materials" % painted)
	var gd: Variant = gm.get_shader_parameter(&"grass_dark")
	_check(gd is Color and (gd as Color).is_equal_approx(gp[&"grass_dark"]), "ground grass_dark not autumn")
	holder.queue_free()
	await process_frame
	if _fails.is_empty():
		print("PASS " + TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _uniforms(sh: Shader) -> Dictionary:
	if sh == null:
		return {}
	return GroundParams.uniform_names(sh)


## sRGB colour -> CIE L*a*b* (D65).
func _lab(c: Color) -> Vector3:
	var lin := Vector3(_lin(c.r), _lin(c.g), _lin(c.b))
	var x: float = (lin.x * 0.4124 + lin.y * 0.3576 + lin.z * 0.1805) / 0.95047
	var y: float = lin.x * 0.2126 + lin.y * 0.7152 + lin.z * 0.0722
	var z: float = (lin.x * 0.0193 + lin.y * 0.1192 + lin.z * 0.9505) / 1.08883
	var fx := _f(x)
	var fy := _f(y)
	var fz := _f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
