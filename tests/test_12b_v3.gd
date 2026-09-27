extends SceneTree
## Task 12b.V3 (Sand set, terrain.md 7.2): the set file (section-10 ENTRIES + the shared items() format, places
## &"sand" / &"sand_edge"), the two meshes (shared painted material, indexed, 3 variants each with an own shape and an
## own height gradient, wind weights / no moss, triangle and size budgets, the bones' contact disc), at most 2 new mesh
## kinds, the instance budget (<= 400) on terrain.md 4.2's four sand patches, BiomeMap.load_items(&"sand") keeps the
## hints, no lights, and every mesh in a MultiMesh.
## Run:  godot --headless --path . -s tests/test_12b_v3.gd --fixed-fps 60 --quit-after 900
## Prints "PASS 12b.V3" or "FAIL 12b.V3: <reasons>".

const TASK_ID := "12b.V3"
const SET_PATH := "res://art/environment/biomes/sand/sand_set.gd"
const DIR := "res://art/environment/biomes/sand/"
const BIOME_MAP := "res://art/environment/biomes/biome_map.gd"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const PLACES: Array[StringName] = [&"sand", &"sand_edge"]
const ITEM_KEYS := {"mesh": TYPE_OBJECT, "material": TYPE_OBJECT, "density": TYPE_FLOAT, "scale": TYPE_VECTOR2,
	"vis_end": TYPE_FLOAT, "shadow": TYPE_BOOL, "variants": TYPE_INT}
## Per mesh: [max triangles drawn by one variant, max height (m), max footprint (m), range, shadow, contact disc, kinds].
const LIMITS := {
	"sand_tussock": [420, 1.1, 1.4, 65.0, false, false, [5]],
	"sand_bones": [700, 1.15, 2.6, 90.0, true, true, [3]],
}
## terrain.md 4.2 sand patches, player half (the mirror is (-x, -z)).
const PATCHES := [[Vector2(-8, 41), Vector2(6.0, 5.0)], [Vector2(-55, -11), Vector2(5.0, 6.0)]]

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_set_and_meshes()
	_check_items()
	_check_budget()
	_check_biome_map()
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
		_fail("sand_set.gd missing")
		return
	var consts: Dictionary = script.get_script_constant_map()
	if consts.get("BIOME_ID") != &"sand":
		_fail("BIOME_ID is not &\"sand\"")
	if not (consts.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	if int(consts.get("VARIANTS", 0)) != 3:
		_fail("VARIANTS is not 3")
	if int(consts.get("INSTANCE_BUDGET", 9999)) > 400:
		_fail("INSTANCE_BUDGET above terrain.md's 400")
	var entries: Array = consts.get("ENTRIES", [])
	var meshes := {}
	var ids := {}
	for e: Variant in entries:
		if not (e is Dictionary):
			_fail("entry is not a Dictionary")
			continue
		var d: Dictionary = e
		for key: String in ["id", "mesh", "per_100m2", "scale", "cluster", "shadow", "range", "place"]:
			if not d.has(key):
				_fail("entry without '%s'" % key)
		if ids.has(d.get("id")):
			_fail("duplicate id %s" % d.get("id"))
		ids[d.get("id")] = true
		var path: String = String(d.get("mesh", ""))
		var name: String = path.get_file().get_basename()
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
			_fail("%s: bad place %s (terrain.md 7.2: sand / sand_edge)" % [name, d.get("place")])
		if absf(float(d.get("range", 0.0)) - float(lim[3])) > 0.01:
			_fail("%s: range %s, spec %s" % [name, d.get("range"), lim[3]])
		if bool(d.get("shadow", false)) != bool(lim[4]):
			_fail("%s: shadow %s (terrain.md 7.2: only the rocks cast one)" % [name, d.get("shadow")])
		if not meshes.has(path):
			meshes[path] = true
			_check_mesh(name, path, lim)
	if meshes.size() > 2:
		_fail("%d mesh kinds (terrain.md 7.2: <= 2 new kinds per set)" % meshes.size())
	for name2: String in LIMITS:
		if not meshes.has(DIR + name2 + ".res"):
			_fail("no entry for %s" % name2)
	var has_edge := false
	for e2: Variant in entries:
		if (e2 as Dictionary).get("place") == &"sand_edge":
			has_edge = true
	if not has_edge:
		_fail("no sand_edge entry (the tussock fringe)")


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
	if bool(lim[5]):
		if mesh.get_surface_count() != 2 or mesh.surface_get_material(1) == null \
				or mesh.surface_get_material(1).resource_path != CONTACT_MAT:
			_fail("%s: no contact disc surface with nature_contact_mat.tres" % name)
		else:
			var ca: Array = mesh.surface_get_arrays(1)
			if ca[Mesh.ARRAY_INDEX] == null or (ca[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty():
				_fail("%s: contact disc not indexed" % name)
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
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	if verts.size() >= idx.size():
		_fail("%s: not welded (%d vertices for %d indices)" % [name, verts.size(), idx.size()])
	var kinds: Array = lim[6]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
	var grad_top := [0.0, 0.0, 0.0]
	for t: int in range(0, idx.size(), 3):
		var m: int = int(uv2[idx[t]].x)
		var kind: int = int(uv2[idx[t]].y)
		if not kinds.has(kind):
			_fail("%s: kind %d (allowed %s)" % [name, kind, kinds])
			return
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
				for j: int in 3:
					grad_top[k] = maxf(grad_top[k], cols[idx[t + j]].a)
			if m != 0 and m != 7 and ((m >> k) & 1) == 1:
				own[k] += 1
	for k: int in 3:
		if own[k] == 0:
			_fail("%s: variant %d has no own shape" % [name, k])
		if per[k] > int(lim[0]):
			_fail("%s: variant %d draws %d triangles (max %d)" % [name, k, per[k], lim[0]])
		if grad_top[k] < 0.9:
			_fail("%s: variant %d height gradient tops at %.2f (the per-variant gradient should reach ~1)" % [name,
				k, grad_top[k]])
	var stone: bool = kinds == [3]
	for w: Vector2 in uv:
		if w.x < 0.0 or w.x > (0.0001 if stone else 0.4501):
			_fail("%s: UV.x %.3f out of range (wind 0..0.45 / no moss in the sand)" % [name, w.x])
			break
	var aabb: AABB = mesh.get_aabb()
	if aabb.end.y > float(lim[1]) or aabb.size.x > float(lim[2]) or aabb.size.z > float(lim[2]) or aabb.position.y < -0.3:
		_fail("%s: size %s .. %s out of limits" % [name, aabb.position, aabb.end])
	if name == "sand_tussock":
		# Wind: the tops sway, the roots stay put.
		var top_w := 0.0
		for i: int in verts.size():
			if verts[i].y > 0.35:
				top_w = maxf(top_w, uv[i].x)
			elif verts[i].y < 0.0 and uv[i].x > 0.001:
				_fail("sand_tussock: a root vertex has wind weight %.3f" % uv[i].x)
				break
		if top_w < 0.2:
			_fail("sand_tussock: tops barely sway (wind weight %.2f)" % top_w)
	print("  %-13s variants %d / %d / %d tris, size %.2f x %.2f x %.2f, %d verts" % [name, per[0], per[1], per[2],
		aabb.size.x, aabb.size.y, aabb.size.z, verts.size()])


## items(): the loaded format shared by the biome sets (mesh, material, density, scale, vis_end, shadow, variants).
func _check_items() -> void:
	var script := load(SET_PATH) as GDScript
	if script == null or not script.has_method(&"items"):
		_fail("sand_set.gd has no static items()")
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
		if it.get("place") != e["place"] or it.get("id") != e["id"] or it.get("path") != e["mesh"]:
			_fail("items()[%d]: place / id / path hints lost" % i)


## The patch weight model (sand_preview.gd): ellipse, signed distance in metres + a point-symmetric +-0.45 m wobble,
## weight = 1 - smoothstep(-1, 1, d). &"sand" where w > 0.5, &"sand_edge" where 0.2 <= w <= 0.5.
func _edge_noise(q: Vector2) -> float:
	var a: float = sin(q.x * 1.3 + sin(q.y * 0.9) * 1.7) * 0.5 + sin(q.y * 1.1 - q.x * 0.7) * 0.5
	var b: float = sin(-q.x * 1.3 + sin(-q.y * 0.9) * 1.7) * 0.5 + sin(-q.y * 1.1 + q.x * 0.7) * 0.5
	return (a + b) * 0.5 * 0.45


func _weight(q: Vector2, c: Vector2, r: Vector2) -> float:
	var u: Vector2 = (q - c) / r
	var lu: float = u.length()
	var d: float = (lu - 1.0) * (q.distance_to(c) / lu) if lu > 0.001 else -minf(r.x, r.y)
	return 1.0 - smoothstep(-1.0, 1.0, d + _edge_noise(q))


## Instances the set asks for on the 4 patches (before roads / slots / buildings are cleared) <= INSTANCE_BUDGET.
func _check_budget() -> void:
	var area := {&"sand": 0.0, &"sand_edge": 0.0}
	var step := 0.1
	for p: Array in PATCHES:
		for sgn: float in [1.0, -1.0]:
			var c: Vector2 = (p[0] as Vector2) * sgn
			var r: Vector2 = p[1]
			var x: float = c.x - r.x - 2.0
			while x < c.x + r.x + 2.0:
				var z: float = c.y - r.y - 2.0
				while z < c.y + r.y + 2.0:
					var w: float = _weight(Vector2(x, z), c, r)
					if w > 0.5:
						area[&"sand"] += step * step
					elif w >= 0.2:
						area[&"sand_edge"] += step * step
					z += step
				x += step
	var n := 0.0
	for e: Variant in _consts().get("ENTRIES", []):
		var d: Dictionary = e
		n += float(d["per_100m2"]) * float(area.get(d["place"], 0.0)) / 100.0
	var budget: int = int(_consts().get("INSTANCE_BUDGET", 400))
	print("  sand %.0f m2 (w > 0.5), rim %.0f m2 (w 0.2-0.5), 4 patches -> %.0f instances (budget %d)" % [area[&"sand"],
		area[&"sand_edge"], n, budget])
	if area[&"sand"] < 300.0 or area[&"sand"] > 450.0:
		_fail("sand area %.0f m2 looks wrong (terrain.md 4.4: ~350 m2)" % area[&"sand"])
	if n > float(budget) or n > 400.0:
		_fail("%.0f instances > %d" % [n, budget])


## The step-12 loader (BiomeMap.load_items) reads the set and keeps its hints (12b.V6 can reuse it).
func _check_biome_map() -> void:
	var bm := load(BIOME_MAP) as GDScript
	if bm == null or not bm.has_method(&"load_items"):
		print("  (BiomeMap.load_items not found: skipped)")
		return
	var its: Array = bm.call(&"load_items", &"sand")
	var entries: Array = _consts().get("ENTRIES", [])
	if its.size() != entries.size():
		_fail("BiomeMap.load_items(&\"sand\") gave %d items, ENTRIES %d" % [its.size(), entries.size()])
		return
	for i: int in its.size():
		var it: Dictionary = its[i]
		if it.get("place") != (entries[i] as Dictionary)["place"] or it.get("biome") != &"sand":
			_fail("BiomeMap.load_items(&\"sand\")[%d]: place / biome lost" % i)


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
	var seen := {}
	for e: Variant in _consts().get("ENTRIES", []):
		var path: String = String((e as Dictionary)["mesh"])
		if seen.has(path):
			continue
		seen[path] = true
		var mesh := load(path) as Mesh
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 60
		for k: int in 60:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, k * 0.7), Vector3(i * 20.0 + (k % 8) * 2.4, 0.0,
				(k / 8) * 2.4)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = float((e as Dictionary)["range"])
		_stage.add_child(mmi)
		if mm.instance_count != 60 or mmi.multimesh.mesh != mesh:
			_fail("%s: MultiMesh setup failed" % mesh.resource_path.get_file())
		i += 1
