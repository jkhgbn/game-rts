extends SceneTree
## G-E value pass (docs/art/ge_value_pass.md): the kingdom value / saturation balance stays in place.
##  1  the grade uniforms exist with a neutral default (1.0) in the shared shaders, so every other user is unchanged
##  2  Shadow: base palette materials are desaturated slate / bone / iron (HSV saturation <= 0.35); team cloth / capes
##     carry the dye grade (< 1, hue kept by the shader); a Shadow building's merged material is graded at EVERY tier
##     (Low too: ShadowDress.attach_at(..., 0) grades then returns null); a Fire building's is not
##  3  Nature: leaf / moss / bark are warm (red > green), the lichen default is pale warm bone
##  4  Ice: pale unit materials stay under value 0.9; the building snow cap / knee uniforms are in ice_paint
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_ge_value_pass.gd --quit-after 3000

const TASK_ID := "ge_value_pass"
const KIT := "res://art/units/kit/materials/"
const NAT := "res://art/units/nature/materials/"
const ICE := "res://art/units/ice/materials/"

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _src(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f else ""


func _p(path: String, key: StringName) -> Variant:
	var m := load(path) as ShaderMaterial
	return m.get_shader_parameter(key) if m else null


func _run() -> void:
	# 1 neutral defaults
	for pair: Array in [["res://art/shaders/painted_vc.gdshader", ["team_sat", "team_val", "body_sat"]],
			["res://art/buildings/stables/stables_painted.gdshader", ["team_sat", "team_val", "body_sat"]],
			["res://art/units/kit/unit_painted.gdshader", ["dye_sat", "dye_val"]],
			["res://art/units/nature/nature_living.gdshader", ["dye_sat", "dye_val"]],
			["res://art/shaders/banner.gdshader", ["dye_sat", "dye_val"]]]:
		var code := _src(pair[0])
		for u: String in pair[1]:
			var re := RegEx.create_from_string("uniform float " + u + "[^=;]*= 1\\.0;")
			_check(re.search(code) != null, "%s: %s missing or not neutral" % [String(pair[0]).get_file(), u])
	# 2 Shadow
	for n: String in ["shadow_iron", "shadow_leather", "shadow_obsidian", "shadow_silver", "shadow_skin"]:
		var c: Variant = _p(KIT + n + ".tres", &"base_color")
		_check(c is Color and (c as Color).s <= 0.35, "%s base saturation %s" % [n, c])
		var t: Variant = _p(KIT + n + ".tres", &"top_color")
		_check(t == null or (t as Color).s <= 0.35, "%s top_color saturation %s" % [n, t])
	for n: String in ["shadow_cloth", "shadow_cloth_dark", "shadow_cape", "shadow_cape_plain"]:
		var d: Variant = _p(KIT + n + ".tres", &"dye_sat")
		_check(d != null and float(d) < 0.8, "%s dye_sat %s" % [n, d])
	_check(ShadowDress.TEAM_SAT < 0.8 and ShadowDress.BODY_SAT < 0.8, "ShadowDress grade constants")
	await _check_building("shadow_barracks", true)
	await _check_building("fire_barracks", false)
	# 3 Nature
	for n: String in ["nature_leaf", "nature_moss", "nature_bark", "nature_leaf_dark"]:
		var c: Variant = _p(NAT + n + ".tres", &"base_color")
		_check(c is Color and (c as Color).r > (c as Color).g, "%s not warm: %s" % [n, c])
	var nl := _src("res://art/units/nature/nature_living.gdshader")
	_check(nl.contains("lichen_color : source_color = vec3(0.88, 0.82, 0.66)"), "nature lichen default changed")
	_check(_p(NAT + "nature_cloth.tres", &"top_lift") != null and float(_p(NAT + "nature_cloth.tres", &"top_lift")) >= 0.15,
		"nature_cloth top lift")
	# 4 Ice
	for n: String in ["ice_hair", "ice_skin", "ice_fur_pale"]:
		var c: Variant = _p(ICE + n + ".tres", &"base_color")
		_check(c is Color and (c as Color).v <= 0.9, "%s too white: %s" % [n, c])
	var ip := _src("res://art/buildings/ice/ice_paint.gdshaderinc")
	_check(ip.contains("uniform float ip_white = ") and ip.contains("uniform float ip_white_knee = "), "ice_paint white cap")
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0)


## The model of `type_id`, Low-tier dress (attach_at q 0): its painted_vc material is graded only when `graded`.
func _check_building(type_id: String, graded: bool) -> void:
	var t: Resource = load("res://data/buildings/%s.tres" % type_id)
	var ps: PackedScene = t.get(&"model_scene") if t else null
	if ps == null:
		_fails.append("no model for " + type_id)
		return
	var m: Node3D = ps.instantiate()
	root.add_child(m)
	for i in 3:
		await process_frame
	if graded:
		_check(ShadowDress.attach_at(m, {}, 0) == null, "attach_at Low must add nothing")
	var found := false
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var mats: Array[Material] = [mi.material_override]
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				mats.append(mi.get_active_material(s))
		for mm: Material in mats:
			if mm is ShaderMaterial and (mm as ShaderMaterial).shader \
					and (mm as ShaderMaterial).shader.resource_path == ShadowDress.PAINTED_VC_PATH:
				found = true
				var ts: Variant = (mm as ShaderMaterial).get_shader_parameter(&"team_sat")
				var is_graded := ts != null and float(ts) < 0.99
				_check(is_graded == graded, "%s painted_vc team_sat %s (graded expected %s)" % [type_id, ts, graded])
	_check(found or not graded, type_id + ": no painted_vc material found")
	m.queue_free()
	await process_frame
