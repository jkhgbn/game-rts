extends SceneTree
## Task 12.V8 (Hearth Meadow set): the set file's data, the six meshes (shared painted material, indexed, 3 variants,
## wind weights, budgets) and the instance budget of map-fill.md section 10 (meadow <= 1 800).
## Run:  godot --headless --path . -s tests/test_12_v8.gd --fixed-fps 60 --quit-after 600
## Prints "PASS 12.V8" or "FAIL 12.V8: <reasons>".

const TASK_ID := "12.V8"
const SET_PATH := "res://art/environment/biomes/meadow/meadow_set.gd"
const DIR := "res://art/environment/biomes/meadow/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const HUBS: Array[Vector2] = [Vector2(-36.0, 36.0), Vector2(36.0, -36.0)]
const BUDGET := 1800
const PLACES: Array[StringName] = [&"land", &"bank", &"water", &"under_trees", &"edge"]
## Per mesh: [max triangles drawn by one variant, max height (m), max footprint (m), range, shadow, contact disc].
const LIMITS := {
	"meadow_tufts": [150, 0.9, 1.0, 65.0, false, false],
	"meadow_clover": [400, 0.35, 1.1, 65.0, false, false],
	"meadow_daisies": [420, 0.4, 1.1, 65.0, false, false],
	"meadow_dandelions": [400, 0.5, 1.1, 65.0, false, false],
	"meadow_fruit_bush": [1000, 1.7, 2.0, 90.0, false, true],
	"meadow_hay": [700, 2.6, 2.7, 90.0, true, true],
}

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_set_and_meshes()
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


func _entries() -> Array:
	var script := load(SET_PATH) as GDScript
	if script == null:
		return []
	return script.get_script_constant_map().get("ENTRIES", [])


func _check_set_and_meshes() -> void:
	var script := load(SET_PATH) as GDScript
	if script == null:
		_fail("meadow_set.gd missing")
		return
	var consts: Dictionary = script.get_script_constant_map()
	if consts.get("BIOME_ID") != &"meadow":
		_fail("BIOME_ID is not &\"meadow\"")
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
		if absf(float(d.get("range", 0.0)) - float(lim[3])) > 0.01:
			_fail("%s: range %s, spec %s" % [name, d.get("range"), lim[3]])
		if bool(d.get("shadow", false)) != bool(lim[4]):
			_fail("%s: shadow %s" % [name, d.get("shadow")])
		_check_mesh(name, path, lim)
	for name2: String in LIMITS:
		if not seen.has(name2):
			_fail("no entry for %s" % name2)


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
	var want_contact: bool = lim[5]
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
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
	for t: int in range(0, idx.size(), 3):
		var m: int = int(uv2[idx[t]].x)
		var kind: int = int(uv2[idx[t]].y)
		if kind != 0 and kind != 5:
			_fail("%s: kind %d (only bark 0 / ivy 5: no autumn leaves on flowers)" % [name, kind])
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
	for w: Vector2 in uv:
		if w.x < 0.0 or w.x > 0.4501:
			_fail("%s: wind weight %.3f out of 0..0.45" % [name, w.x])
			break
	var aabb: AABB = mesh.get_aabb()
	if aabb.end.y > float(lim[1]) or aabb.size.x > float(lim[2]) or aabb.size.z > float(lim[2]) or aabb.position.y < -0.1:
		_fail("%s: size %s out of limits" % [name, aabb.size])
	print("  %-18s variants %d / %d / %d tris, size %.2f x %.2f x %.2f" % [name, per[0], per[1], per[2], aabb.size.x,
		aabb.size.y, aabb.size.z])


## Weighted meadow area (map-fill.md 3.1: within 22 m of a hub, 4 m blend) minus the base paving (spot r 11 + 0.8)
## and the lane (5.2 m clear), then the instances the set asks for there.
func _check_budget() -> void:
	var step := 0.5
	var area := 0.0
	var x := -60.0
	while x < 60.0:
		var z := -60.0
		while z < 60.0:
			var q := Vector2(x + step * 0.5, z + step * 0.5)
			var d: float = minf(q.distance_to(HUBS[0]), q.distance_to(HUBS[1]))
			var w: float = clampf(1.0 - (d - 22.0) / 4.0, 0.0, 1.0)
			if w > 0.0 and d > 11.8:
				var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, HUBS[0], HUBS[1])
				if q.distance_to(c) >= 5.2 and absf(q.x) < 59.6 and absf(q.y) < 59.6:
					area += w * step * step
			z += step
		x += step
	var per := 0.0
	for e: Variant in _entries():
		per += float((e as Dictionary).get("per_100m2", 0.0))
	var n: float = per * area / 100.0
	print("  meadow area %.0f m2 (weighted, both hubs), %.1f per 100 m2 -> %.0f instances (budget %d)" % [area, per, n,
		BUDGET])
	if n > BUDGET:
		_fail("%.0f instances > %d" % [n, BUDGET])


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
	for e: Variant in _entries():
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
