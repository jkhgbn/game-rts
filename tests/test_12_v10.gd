extends SceneTree
## Task 12.V10 (Old Wood set): the set file (map-fill.md section 10 constants + the 12.V6 items() format), the six
## meshes (one surface, one shared material each, indexed, 3 variants with their own shapes, triangle / size budgets),
## the glow material (emission 1.5-2.0, no lights), shadows / ranges of map-fill.md 9, and the Old Wood instance
## budget (<= 900) over the real wood area. Also instantiates every mesh in a MultiMesh (what the scatter does).
## Run:  godot --headless --path . -s tests/test_12_v10.gd --fixed-fps 60 --quit-after 600
## Prints "PASS 12.V10" or "FAIL 12.V10: <reasons>".

const TASK_ID := "12.V10"
const SET_PATH := "res://art/environment/biomes/old_wood/old_wood_set.gd"
const DIR := "res://art/environment/biomes/old_wood/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const GLOW_MAT := "res://art/environment/biomes/old_wood/old_wood_glow_mat.tres"
const WEB_MAT := "res://art/environment/biomes/old_wood/old_wood_web_mat.tres"
const WOODS: Array[Vector2] = [Vector2(-50.0, -50.0), Vector2(50.0, 50.0)]
const BUDGET := 900
const PLACES: Array[StringName] = [&"land", &"bank", &"water", &"under_trees", &"edge"]
## Per mesh: [material, max triangles drawn by one variant, max height (m), max footprint (m), range, shadow].
const LIMITS := {
	"ow_ferns": [NATURE_MAT, 400, 1.1, 2.3, 90.0, false],
	"ow_glowcaps": [GLOW_MAT, 600, 1.1, 1.6, 90.0, false],
	"ow_moss_boulders": [NATURE_MAT, 400, 1.0, 2.6, 110.0, true],
	"ow_fallen_trunk": [NATURE_MAT, 600, 1.45, 5.0, 110.0, true],
	"ow_roots": [NATURE_MAT, 350, 0.7, 2.6, 90.0, false],
	"ow_cobwebs": [WEB_MAT, 200, 1.4, 1.4, 65.0, false],
}
const ITEM_KEYS := {"mesh": TYPE_OBJECT, "material": TYPE_OBJECT, "density": TYPE_FLOAT, "scale": TYPE_VECTOR2,
	"vis_end": TYPE_FLOAT, "shadow": TYPE_BOOL, "variants": TYPE_INT}

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_set()
	_check_items()
	_check_materials()
	_check_budget()
	_check_no_lights()
	_stage = Node3D.new()
	root.add_child(_stage)
	_instance_all()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 10:
		return false
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)
	print("  fail: " + msg)


func _script() -> GDScript:
	return load(SET_PATH) as GDScript


func _check_set() -> void:
	var script := _script()
	if script == null:
		_fail("old_wood_set.gd missing")
		return
	var consts: Dictionary = script.get_script_constant_map()
	if consts.get("BIOME_ID") != &"old_wood":
		_fail("BIOME_ID is not &\"old_wood\"")
	if not (consts.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	var entries: Array = consts.get("ENTRIES", [])
	var seen := {}
	for e: Variant in entries:
		if not (e is Dictionary):
			_fail("entry is not a Dictionary")
			continue
		var d: Dictionary = e
		for key: String in ["mesh", "per_100m2", "scale", "cluster", "shadow", "range", "place"]:
			if not d.has(key):
				_fail("entry without '%s'" % key)
		var path: String = String(d.get("mesh", ""))
		var name: String = path.get_file().get_basename()
		seen[name] = true
		if not LIMITS.has(name):
			_fail("unexpected mesh %s" % path)
			continue
		var lim: Array = LIMITS[name]
		var sc: Variant = d.get("scale")
		if not (sc is Vector2) or (sc as Vector2).x < 0.5 or (sc as Vector2).y > 2.0 or (sc as Vector2).x > (sc as Vector2).y:
			_fail("%s: bad scale %s" % [name, sc])
		if float(d.get("per_100m2", 0.0)) <= 0.0:
			_fail("%s: per_100m2 <= 0" % name)
		var cl: float = float(d.get("cluster", -1.0))
		if cl < 0.0 or cl > 1.0:
			_fail("%s: cluster out of 0..1" % name)
		if not PLACES.has(d.get("place")):
			_fail("%s: bad place %s" % [name, d.get("place")])
		if absf(float(d.get("range", 0.0)) - float(lim[4])) > 0.01:
			_fail("%s: range %s, expected %s" % [name, d.get("range"), lim[4]])
		if bool(d.get("shadow", false)) != bool(lim[5]):
			_fail("%s: shadow %s (map-fill.md 9: only logs / big rocks)" % [name, d.get("shadow")])
		_check_mesh(name, path, lim)
	for name2: String in LIMITS:
		if not seen.has(name2):
			_fail("no entry for %s" % name2)
	if entries.size() > 24:
		_fail("more than 24 entries")


func _check_mesh(name: String, path: String, lim: Array) -> void:
	if not ResourceLoader.exists(path):
		_fail("%s: mesh file missing" % name)
		return
	var mesh := load(path) as ArrayMesh
	if mesh == null:
		_fail("%s: not an ArrayMesh" % name)
		return
	if mesh.get_surface_count() != 1:
		_fail("%s: %d surfaces (1 expected: one material per mesh)" % [name, mesh.get_surface_count()])
	var m0: Material = mesh.surface_get_material(0)
	if m0 == null or m0.resource_path != String(lim[0]):
		_fail("%s: surface 0 material is not %s" % [name, lim[0]])
	var arr: Array = mesh.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		_fail("%s: not indexed" % name)
		return
	if arr[Mesh.ARRAY_COLOR] == null or arr[Mesh.ARRAY_TEX_UV] == null or arr[Mesh.ARRAY_TEX_UV2] == null:
		_fail("%s: missing COLOR / UV / UV2" % name)
		return
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
	for t: int in range(0, idx.size(), 3):
		var m: int = int(uv2[idx[t]].x)
		var kind: int = int(uv2[idx[t]].y)
		if String(lim[0]) == NATURE_MAT and kind not in [0, 3, 5]:
			_fail("%s: kind %d (bark 0 / stone 3 / ivy 5 only: no autumn tint on Old Wood decor)" % [name, kind])
			return
		if String(lim[0]) == WEB_MAT and kind not in [0, 1, 2]:
			_fail("%s: web kind %d" % [name, kind])
			return
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
			if m != 0 and m != 7 and ((m >> k) & 1) == 1:
				own[k] += 1
	for k: int in 3:
		if own[k] == 0:
			_fail("%s: variant %d has no own shape" % [name, k])
		if per[k] > int(lim[1]):
			_fail("%s: variant %d draws %d triangles (max %d)" % [name, k, per[k], lim[1]])
	if String(lim[0]) == NATURE_MAT:
		for i: int in uv.size():
			var kind2: int = int(uv2[i].y)
			if kind2 != 3 and (uv[i].x < 0.0 or uv[i].x > 0.4501):
				_fail("%s: wind weight %.3f out of 0..0.45" % [name, uv[i].x])
				break
	elif String(lim[0]) == GLOW_MAT:
		var glowing := 0
		for w: Vector2 in uv:
			if w.x < -0.001 or w.x > 1.001:
				_fail("%s: glow weight %.3f out of 0..1" % [name, w.x])
				break
			if w.x > 0.8:
				glowing += 1
		if glowing == 0:
			_fail("%s: nothing glows" % name)
	var aabb: AABB = mesh.get_aabb()
	if aabb.end.y > float(lim[2]) or aabb.size.x > float(lim[3]) or aabb.size.z > float(lim[3]):
		_fail("%s: size %s out of limits" % [name, aabb.size])
	print("  %-18s variants %d / %d / %d tris, size %.2f x %.2f x %.2f" % [name, per[0], per[1], per[2], aabb.size.x,
		aabb.size.y, aabb.size.z])


## The 12.V6 format: items() -> Array[Dictionary] with typed keys, one per ENTRIES row, material = the mesh's own.
func _check_items() -> void:
	var script := _script()
	if script == null:
		return
	var items: Variant = script.call(&"items")
	if not (items is Array):
		_fail("items() did not return an Array")
		return
	var list: Array = items
	if list.size() != 6:
		_fail("items() returned %d items (6 expected)" % list.size())
	for it: Variant in list:
		if not (it is Dictionary):
			_fail("item is not a Dictionary")
			continue
		var d: Dictionary = it
		for key: String in ITEM_KEYS:
			if not d.has(key) or typeof(d[key]) != int(ITEM_KEYS[key]):
				_fail("item without a typed '%s'" % key)
		if not (d.get("mesh") is Mesh) or not (d.get("material") is Material):
			_fail("item mesh / material of the wrong class")
			continue
		var mesh: Mesh = d["mesh"]
		if d["material"] != mesh.surface_get_material(0):
			_fail("%s: item material differs from the mesh's surface material" % mesh.resource_path.get_file())
		if int(d["variants"]) != 3:
			_fail("variants != 3")
		if float(d["density"]) <= 0.0 or float(d["vis_end"]) <= 0.0:
			_fail("bad density / vis_end")
		var name: String = mesh.resource_path.get_file().get_basename()
		if LIMITS.has(name) and bool(d["shadow"]) != bool(LIMITS[name][5]):
			_fail("%s: item shadow mismatch" % name)


## Glow: emission 1.5-2.0 (map-fill.md 10), no lights anywhere (section 9 "Emissive decor").
func _check_materials() -> void:
	var glow := load(GLOW_MAT) as ShaderMaterial
	if glow == null or glow.shader == null:
		_fail("glow material missing")
	else:
		var e: float = float(glow.get_shader_parameter(&"energy"))
		if e < 1.5 or e > 2.0:
			_fail("glow energy %.2f outside 1.5-2.0" % e)
		if not glow.shader.code.contains("EMISSION"):
			_fail("glow shader has no EMISSION")
		if not glow.shader.code.contains("variant_count"):
			_fail("glow shader ignores the variant mask")
	var web := load(WEB_MAT) as ShaderMaterial
	if web == null or web.shader == null:
		_fail("web material missing")
	elif not web.shader.code.contains("variant_count"):
		_fail("web shader ignores the variant mask")


## Old Wood area (map-fill.md 3.1: 28 m around (-50, -50) / (50, 50), 4 m blend; the riverbank wins within 6 m of
## the water), then the instances the set asks for there: <= 900 (section 10).
func _check_budget() -> void:
	var gp := load("res://art/environment/ground_params.gd") as GDScript
	var river: Dictionary = gp.call(&"skirmish_river") if gp != null else {}
	var step := 0.5
	var area := 0.0
	var x := -60.0
	while x < 60.0:
		var z := -60.0
		while z < 60.0:
			var q := Vector2(x + step * 0.5, z + step * 0.5)
			var d: float = minf(q.distance_to(WOODS[0]), q.distance_to(WOODS[1]))
			var w: float = clampf(1.0 - (d - 28.0) / 4.0, 0.0, 1.0)
			if w > 0.0 and absf(q.x) < 59.6 and absf(q.y) < 59.6:
				if river.is_empty() or float(gp.call(&"water_distance", river, q)) >= 6.0:
					area += w * step * step
			z += step
		x += step
	var per := 0.0
	for e: Variant in _script().get_script_constant_map().get("ENTRIES", []):
		per += float((e as Dictionary).get("per_100m2", 0.0))
	var n: float = per * area / 100.0
	print("  old wood area %.0f m2 (weighted, both woods), %.1f per 100 m2 -> %.0f instances (budget %d)" % [area, per,
		n, BUDGET])
	if n > BUDGET:
		_fail("%.0f instances > %d" % [n, BUDGET])


func _check_no_lights() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		_fail("folder missing")
		return
	for f: String in dir.get_files():
		if f.get_extension() in ["tscn", "tres", "gd", "gdshader"]:
			var text: String = FileAccess.get_file_as_string(DIR + f)
			for light: String in ["OmniLight3D", "SpotLight3D", "DirectionalLight3D"]:
				if text.contains(light) and not f.ends_with("_preview.gd"):
					_fail("%s contains a %s" % [f, light])


## Every mesh in a MultiMesh of 60 instances with its item material as material_override, a few frames in the tree.
func _instance_all() -> void:
	var script := _script()
	if script == null:
		return
	var i := 0
	for it: Variant in script.call(&"items"):
		var d: Dictionary = it
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = d["mesh"]
		mm.instance_count = 60
		for k: int in 60:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, k * 0.7), Vector3(i * 10.0 + (k % 8) * 1.2, 0.0,
				(k / 8) * 1.2)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = d["material"]
		mmi.visibility_range_end = float(d["vis_end"])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(d["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stage.add_child(mmi)
		if mm.instance_count != 60 or mmi.multimesh.mesh != d["mesh"]:
			_fail("%s: MultiMesh setup failed" % (d["mesh"] as Mesh).resource_path.get_file())
		i += 1
