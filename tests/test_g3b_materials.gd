extends SceneTree
## G3b (docs/art/g3b_materials.md): the shared painted-PBR unit layer.
## Checks: (1) the kit unit shaders include art/units/kit/unit_paint.gdshaderinc and keep the A.16 slot map (kit_detail =
## slot 12, nobody else on slot 12, banner.gdshader keeps `phase` as its only instance uniform, unit_cloth off by default);
## (2) the materials: kit palette kinds, every unit_painted material's surface_kind in 0..7, unit capes on unit_cloth 1;
## (3) the kit: every painted draw instance of a soldier / champion / mount gets kit_detail = CharacterModel.detail_tier(),
## team-colour variants keep their surface_kind, the hit flash still reaches the same nodes.
## Run: $GODOT --headless --path . -s tests/test_g3b_materials.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS g3b_materials" or "FAIL g3b_materials: <reasons>".

const TASK_ID := "g3b_materials"
const PAINTED := "res://art/units/kit/unit_painted.gdshader"
const CHAMP := "res://art/units/champions/champion_palette.gdshader"
const INC := "res://art/units/kit/unit_paint.gdshaderinc"
const BANNER := "res://art/shaders/banner.gdshader"
const KIT_MATS := "res://art/units/kit/materials/"
const KINDS := {"fire_cloth": 1, "fire_cloth_dark": 1, "shadow_cloth": 1, "fire_bronze": 2, "shadow_iron": 2,
	"unit_gold_trim": 2, "fire_leather": 3, "fire_skin": 4, "fire_wood": 5, "fire_fur": 6, "shadow_bone": 7}
const MODELS: Array[String] = [
	"res://art/units/fire/flame_guard.tscn",
	"res://art/units/champions/oathwall/oathwall.tscn",
	"res://art/units/mounts/dusk_steed/dusk_steed.tscn",
	"res://art/units/ice/rimeshield.tscn",
]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 8, 14)
	_world.add_child(cam)
	_run()


func _run() -> void:
	_check_shaders()
	_check_materials()
	await _check_kit()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _check_shaders() -> void:
	var inc := FileAccess.get_file_as_string(INC)
	_check(inc.contains("void up_light(") and inc.contains("vec3 up_albedo("), "include has up_light / up_albedo")
	for p: String in [PAINTED, CHAMP]:
		var code := FileAccess.get_file_as_string(p)
		_check(code.contains('#include "%s"' % INC), "%s includes the paint layer" % p)
		_check(code.contains("instance uniform float kit_detail : instance_index(12)"), "%s kit_detail on slot 12" % p)
		_check(code.contains("instance uniform float hit_flash : instance_index(3)"), "%s hit_flash on slot 3" % p)
		_check(code.contains("flash_color * hit_flash * 2.0"), "%s keeps the hit flash" % p)
	_check(int(CharacterModel.INSTANCE_SLOTS.get("kit_detail", -1)) == 12, "INSTANCE_SLOTS kit_detail = 12")
	_check(CharacterModel.DETAIL_BY_QUALITY.size() == 4 and CharacterModel.DETAIL_BY_QUALITY[0] == 0.0
		and CharacterModel.DETAIL_BY_QUALITY[2] == 2.0, "DETAIL_BY_QUALITY Low 0 .. High 2")
	# Nobody else takes slot 12 under art/ (7-11 are the titans' / critters' own slots).
	for f: String in _files("res://art/", ["gdshader", "gdshaderinc"]):
		var code := FileAccess.get_file_as_string(f)
		var at := code.find("instance_index(12)")
		while at >= 0:
			var line_start := code.rfind("\n", at) + 1
			_check(code.substr(line_start, at - line_start).contains("kit_detail"), "%s: slot 12 is kit_detail's" % f)
			at = code.find("instance_index(12)", at + 1)
	var banner := FileAccess.get_file_as_string(BANNER)
	_check(banner.count("\ninstance uniform ") == 1, "banner.gdshader keeps one instance uniform (phase, slot 0)")
	_check(banner.contains("uniform float unit_cloth : hint_range(0.0, 1.0) = 0.0;"), "banner unit_cloth off by default")


func _check_materials() -> void:
	for nm: String in KINDS:
		var m := load(KIT_MATS + nm + ".tres") as ShaderMaterial
		var k: Variant = m.get_shader_parameter(&"surface_kind") if m else null
		_check(k != null and int(k) == int(KINDS[nm]), "%s surface_kind %s (want %d)" % [nm, k, KINDS[nm]])
	var n_kind := 0
	for f: String in _files("res://art/units/", ["tres"]):
		var text := FileAccess.get_file_as_string(f)
		if text.contains("unit_painted.gdshader") and text.contains("shader_parameter/surface_kind"):
			var m := load(f) as ShaderMaterial
			var kv: Variant = m.get_shader_parameter(&"surface_kind") if m else null
			_check(kv is int and int(kv) >= 0 and int(kv) <= 7, "%s surface_kind %s in 0..7" % [f, kv])
			n_kind += 1
		if text.contains("art/shaders/banner.gdshader") and not f.contains("/wizards/"):
			_check(text.contains("shader_parameter/unit_cloth = 1.0"), "%s: unit cape on unit_cloth 1" % f)
	_check(n_kind >= 150, "unit materials with a surface_kind: %d (want >= 150)" % n_kind)


func _check_kit() -> void:
	var want := CharacterModel.detail_tier()
	var cloth := load(KIT_MATS + "fire_cloth.tres") as ShaderMaterial
	var v := CharacterModel._team_variant(cloth, Color(0.2, 0.4, 0.9))
	var vk: Variant = (v as ShaderMaterial).get_shader_parameter(&"surface_kind") if v else null
	_check(vk is int and int(vk) == 1,
		"team variant keeps surface_kind cloth")
	for p: String in MODELS:
		var m := (load(p) as PackedScene).instantiate() as CharacterModel
		_world.add_child(m)
		await process_frame
		await process_frame
		var n := 0
		for gi: GeometryInstance3D in m._flash_all_targets:
			var dv: Variant = gi.get_instance_shader_parameter(&"kit_detail")
			_check(dv != null and is_equal_approx(float(dv), want), "%s %s kit_detail %s (want %s)" % [p.get_file(), gi.name, dv, want])
			n += 1
		_check(n > 0, "%s has painted draw instances" % p.get_file())
		m.play_hit()
		await process_frame
		var lit := false
		for gi: GeometryInstance3D in m._flash_hit_targets:
			var hv: Variant = gi.get_instance_shader_parameter(&"hit_flash")
			lit = lit or (hv != null and float(hv) > 0.0)
		_check(lit, "%s hit flash reaches its targets" % p.get_file())
		m.queue_free()
		await process_frame


func _files(dir: String, exts: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.get_extension() in exts:
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		if sub.begins_with("."):
			continue
		out.append_array(_files(dir.path_join(sub), exts))
	return out
