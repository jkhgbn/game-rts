extends SceneTree
## Task 12.V9 (Heath set): the set file (section-10 ENTRIES + the shared items() format), the four meshes (shared
## painted material, indexed, 3 variants each, wind weights / moss, budgets, the grass combed toward +X), the instance
## budget of map-fill.md section 10 (heath <= 1 600) on Crown Hollow's real biome zones, no lights.
## Run:  godot --headless --path . -s tests/test_12_v9.gd --fixed-fps 60 --quit-after 900
## Prints "PASS 12.V9" or "FAIL 12.V9: <reasons>".

const TASK_ID := "12.V9"
const SET_PATH := "res://art/environment/biomes/heath/heath_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const DIR := "res://art/environment/biomes/heath/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const SHADER := "res://art/environment/nature_props/nature_painted.gdshader"
const PLACES: Array[StringName] = [&"land", &"bank", &"water", &"under_trees", &"edge"]
const ITEM_KEYS := {"mesh": TYPE_OBJECT, "material": TYPE_OBJECT, "density": TYPE_FLOAT, "scale": TYPE_VECTOR2,
	"vis_end": TYPE_FLOAT, "shadow": TYPE_BOOL, "variants": TYPE_INT}
## Per mesh: [max triangles drawn by one variant, max height (m), max footprint (m), range, contact disc, kinds].
const LIMITS := {
	"heath_tall_grass": [220, 1.05, 1.0, 65.0, false, [5]],
	"heath_heather": [420, 0.6, 1.5, 90.0, false, [5]],
	"heath_gorse": [900, 1.65, 2.2, 90.0, true, [0, 5]],
	"heath_lichen_stones": [320, 0.8, 2.2, 90.0, true, [3]],
}

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_set_and_meshes()
	_check_items()
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


func _consts() -> Dictionary:
	var script := load(SET_PATH) as GDScript
	return script.get_script_constant_map() if script != null else {}


func _check_set_and_meshes() -> void:
	var script := load(SET_PATH) as GDScript
	if script == null:
		_fail("heath_set.gd missing")
		return
	var consts: Dictionary = script.get_script_constant_map()
	if consts.get("BIOME_ID") != &"heath":
		_fail("BIOME_ID is not &\"heath\"")
	if not (consts.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	if int(consts.get("VARIANTS", 0)) != 3:
		_fail("VARIANTS is not 3")
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
		if absf(float(d.get("range", 0.0)) - float(lim[3])) > 0.01:
			_fail("%s: range %s, spec %s" % [name, d.get("range"), lim[3]])
		if bool(d.get("shadow", true)):
			_fail("%s: casts shadows (only trees / logs / big rocks may)" % name)
		if d.has("yaw"):
			var dir: Vector3 = Basis(Vector3.UP, float(d["yaw"])) * Vector3.RIGHT
			if dir.distance_to(Vector3(0.8, 0.0, 0.6)) > 0.01:
				_fail("%s: yaw does not turn +X to the wind (0.8, 0.6): %s" % [name, dir])
		_check_mesh(name, path, lim)
	for name2: String in LIMITS:
		if not seen.has(name2):
			_fail("no entry for %s" % name2)
	# The wind the grass is combed for is still the shader's default.
	var code: String = (load(SHADER) as Shader).code
	if not code.contains("uniform vec2 wind_dir = vec2(0.8, 0.6);"):
		_fail("nature_painted wind_dir default changed: update heath_set.gd WIND_YAW / yaw")


func _check_mesh(name: String, path: String, lim: Array) -> void:
	if not ResourceLoader.exists(path):
		_fail("%s: mesh file missing" % name)
		return
	var mesh := load(path) as ArrayMesh
	if mesh == null:
		_fail("%s: not an ArrayMesh" % name)
		return
	var m0: Material = mesh.surface_get_material(0)
	if m0 == null or m0.resource_path != NATURE_MAT:
		_fail("%s: surface 0 is not the shared nature_mat.tres" % name)
	var want_contact: bool = lim[4]
	if want_contact:
		if mesh.get_surface_count() != 2 or mesh.surface_get_material(1) == null \
				or mesh.surface_get_material(1).resource_path != CONTACT_MAT:
			_fail("%s: no contact disc surface with nature_contact_mat.tres" % name)
	elif mesh.get_surface_count() != 1:
		_fail("%s: %d surfaces (1 expected)" % [name, mesh.get_surface_count()])
	var arr: Array = mesh.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		_fail("%s: not indexed" % name)
		return
	if arr[Mesh.ARRAY_COLOR] == null or arr[Mesh.ARRAY_TEX_UV] == null or arr[Mesh.ARRAY_TEX_UV2] == null:
		_fail("%s: missing COLOR / UV / UV2" % name)
		return
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var kinds: Array = lim[5]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
	for t: int in range(0, idx.size(), 3):
		var m: int = int(uv2[idx[t]].x)
		var kind: int = int(uv2[idx[t]].y)
		if not kinds.has(kind):
			_fail("%s: kind %d (allowed %s)" % [name, kind, kinds])
			return
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
			if m != 0 and m != 7 and ((m >> k) & 1) == 1:
				own[k] += 1
	for k: int in 3:
		if own[k] == 0:
			_fail("%s: variant %d has no own shape" % [name, k])
		if per[k] > int(lim[0]):
			_fail("%s: variant %d draws %d triangles (max %d)" % [name, k, per[k], lim[0]])
	var stone: bool = kinds == [3]
	for w: Vector2 in uv:
		if w.x < 0.0 or w.x > (1.0001 if stone else 0.4501):
			_fail("%s: UV.x %.3f out of range (wind 0..0.45 / moss 0..1)" % [name, w.x])
			break
	var aabb: AABB = mesh.get_aabb()
	if aabb.end.y > float(lim[1]) or aabb.size.x > float(lim[2]) or aabb.size.z > float(lim[2]) or aabb.position.y < -0.25:
		_fail("%s: size %s .. %s out of limits" % [name, aabb.position, aabb.end])
	if name == "heath_tall_grass":
		# Wind-bent: the upper blades lean toward local +X.
		var sx := 0.0
		var n := 0
		for p: Vector3 in verts:
			if p.y > 0.4:
				sx += p.x
				n += 1
		if n == 0 or sx / n < 0.15:
			_fail("heath_tall_grass: blades not combed toward +X (mean x above 0.4 m = %.2f)" % (sx / maxi(n, 1)))
	print("  %-20s variants %d / %d / %d tris, size %.2f x %.2f x %.2f" % [name, per[0], per[1], per[2], aabb.size.x,
		aabb.size.y, aabb.size.z])


## items(): the loaded format shared by the biome sets (mesh, material, density, scale, vis_end, shadow, variants).
func _check_items() -> void:
	var script := load(SET_PATH) as GDScript
	if script == null or not script.has_method(&"items"):
		_fail("heath_set.gd has no static items()")
		return
	var items: Variant = script.call(&"items")
	if not (items is Array) or not (items as Array).is_typed() or (items as Array).get_typed_builtin() != TYPE_DICTIONARY:
		_fail("items() is not an Array[Dictionary]")
		return
	var entries: Array = _consts().get("ENTRIES", [])
	if (items as Array).size() != entries.size():
		_fail("items() has %d entries, ENTRIES %d" % [(items as Array).size(), entries.size()])
		return
	for i: int in entries.size():
		var it: Dictionary = (items as Array)[i]
		var e: Dictionary = entries[i]
		for key: String in ITEM_KEYS:
			if not it.has(key) or typeof(it[key]) != int(ITEM_KEYS[key]):
				_fail("items()[%d]: '%s' missing or wrong type" % [i, key])
		if not (it.get("mesh") is Mesh) or (it["mesh"] as Mesh).resource_path != String(e["mesh"]):
			_fail("items()[%d]: mesh is not %s" % [i, e["mesh"]])
		if not (it.get("material") is Material) or (it["material"] as Material).resource_path != NATURE_MAT:
			_fail("items()[%d]: material is not the shared nature_mat.tres" % i)
		if absf(float(it.get("density", 0.0)) - float(e["per_100m2"])) > 0.001 \
				or absf(float(it.get("vis_end", 0.0)) - float(e["range"])) > 0.001 \
				or it.get("scale") != e["scale"] or it.get("shadow") != e["shadow"] or it.get("variants") != 3:
			_fail("items()[%d] does not match ENTRIES[%d]" % [i, i])


## Weighted heath area of Crown Hollow (map-fill.md 3.1 with the ground's zone numbers: ruins > riverbank > meadow >
## Old Wood > heath, 4 m blend), minus the water and the map edge, then the instances the set asks for there.
func _check_budget() -> void:
	var gp := load(GP_PATH) as GDScript
	if gp == null:
		_fail("ground_params.gd missing")
		return
	var c: Dictionary = gp.get_script_constant_map()
	var river: Dictionary = gp.call(&"skirmish_river")
	var bl: float = float(c["BLEND"]) * 0.5
	var hubs: Vector4 = c["HUBS"]
	var woods: Vector4 = c["WOODS"]
	var step := 1.0
	var area := 0.0
	var x := -59.5
	while x < 59.6:
		var z := -59.5
		while z < 59.6:
			var q := Vector2(x, z)
			var heath: float = 1.0 - _zin(maxf(absf(q.x), absf(q.y)) - float(c["HEATH_EDGE"]), bl)
			if heath > 0.0:
				var wd: float = gp.call(&"water_distance", river, q)
				if wd > 0.6:
					var ruin := 0.0
					for r: Vector4 in c["RUINS"]:
						ruin = maxf(ruin, _zin(q.distance_to(Vector2(r.x, r.y)) - r.z, bl))
					var bank: float = _zin(wd - float(c["BANK_REACH"]), bl) if wd < 1e3 else 0.0
					var meadow: float = _zin(minf(q.distance_to(Vector2(hubs.x, hubs.y)),
						q.distance_to(Vector2(hubs.z, hubs.w))) - float(c["HUB_RADIUS"]), bl)
					var wood: float = _zin(minf(q.distance_to(Vector2(woods.x, woods.y)),
						q.distance_to(Vector2(woods.z, woods.w))) - float(c["WOOD_RADIUS"]), bl)
					var left: float = 1.0 - ruin
					bank *= left
					left -= bank
					meadow *= left
					left -= meadow
					wood *= left
					left -= wood
					area += heath * left * step * step
			z += step
		x += step
	var per := 0.0
	for e: Variant in _consts().get("ENTRIES", []):
		per += float((e as Dictionary).get("per_100m2", 0.0))
	var n: float = per * area / 100.0
	var budget: int = int(_consts().get("INSTANCE_BUDGET", 1600))
	print("  heath area %.0f m2 (weighted, both halves), %.1f per 100 m2 -> %.0f instances (budget %d)" % [area, per, n,
		budget])
	if budget > 1600:
		_fail("INSTANCE_BUDGET %d above map-fill.md's 1 600" % budget)
	if n > 1600.0:
		_fail("%.0f instances > 1600" % n)
	if area < 500.0:
		_fail("heath area %.0f m2 looks wrong (zones changed?)" % area)


func _zin(e: float, bl: float) -> float:
	return 1.0 - smoothstep(-bl, bl, e)


func _check_no_lights() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		_fail("folder missing")
		return
	for f: String in dir.get_files():
		if f.get_extension() in ["tscn", "tres", "gd"]:
			var text: String = FileAccess.get_file_as_string(DIR + f)
			for light: String in ["OmniLight3D", "SpotLight3D", "DirectionalLight3D"]:
				if text.contains(light):
					_fail("%s contains a %s" % [f, light])


## Every mesh in a MultiMesh of 60 instances (what the scatter does), a few frames in the tree: no errors.
func _instance_all() -> void:
	var i := 0
	for e: Variant in _consts().get("ENTRIES", []):
		var mesh := load(String((e as Dictionary)["mesh"])) as Mesh
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 60
		for k: int in 60:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, k * 0.7), Vector3(i * 10.0 + (k % 8) * 1.2, 0.0,
				(k / 8) * 1.2)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = float((e as Dictionary)["range"])
		_stage.add_child(mmi)
		if mm.instance_count != 60 or mmi.multimesh.mesh != mesh:
			_fail("%s: MultiMesh setup failed" % mesh.resource_path.get_file())
		i += 1
