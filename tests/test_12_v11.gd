extends SceneTree
## Task 12.V11 (Wildflower Glade set): the set file (map-fill.md section 10 constants + the shared step-12 items()
## format read by 12.V6), the three meshes (shared painted material, indexed, 3 variants with their own shapes, wind
## weights, triangle / size budgets, no shadows), readability limits (tall grass under a worker's shoulders and no more
## saturated than the lawn), the glade instance budget of map-fill.md 10 (<= 1 800), 0 lights, and a MultiMesh
## instantiation of every item.
## Run:  godot --headless --path . -s tests/test_12_v11.gd --fixed-fps 60 --quit-after 600
## Prints "PASS 12.V11" or "FAIL 12.V11: <reasons>".

const TASK_ID := "12.V11"
const SET_PATH := "res://art/environment/biomes/glade/glade_set.gd"
const DIR := "res://art/environment/biomes/glade/"
const BIOMES_DIR := "res://art/environment/biomes/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const BUDGET := 1800
const PLACES: Array[StringName] = [&"land", &"bank", &"water", &"under_trees", &"edge"]
## Per mesh: [max triangles drawn by one variant, max height (m), max footprint (m), vis_end, contact disc].
const LIMITS := {
	"glade_tall_grass": [360, 0.75, 1.5, 65.0, false],
	"glade_flowers": [400, 0.6, 1.1, 65.0, false],
	"glade_butterfly_bush": [1000, 1.75, 2.6, 90.0, true],
}
## Readability: a worker is ~1.2 m tall; the tall grass at its largest scale must stay under ~0.8 m.
const WORKER_SHOULDER := 0.85
## ground.gdshader grass_light (the lawn's most saturated tone) and the Nature kingdom's team green (art-keep 0.2).
const LAWN := Color(0.32, 0.43, 0.20)
const NATURE_TEAM := Color(0.35, 0.70, 0.25)
# Crown Hollow zones (map-fill.md 3.1 / 2.1), player half; everything is point-mirrored.
const RIVER_N: Array[Vector2] = [Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30),
	Vector2(-5, -21), Vector2(-2.5, -12.5)]
const HUBS: Array[Vector2] = [Vector2(-36.0, 36.0), Vector2(36.0, -36.0)]
const WOODS: Array[Vector2] = [Vector2(-50.0, -50.0), Vector2(50.0, 50.0)]
const STUMPS: Array[Vector2] = [Vector2(-30.0, 20.0), Vector2(30.0, -20.0)]

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_constants()
	_check_items()
	_check_budget()
	_check_no_lights()
	_count_kinds()
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
	return load(SET_PATH) as GDScript if ResourceLoader.exists(SET_PATH) else null


func _items() -> Array:
	var s := _script()
	if s == null or not s.has_method(&"items"):
		return []
	return s.call(&"items")


func _check_constants() -> void:
	var s := _script()
	if s == null:
		_fail("glade_set.gd missing")
		return
	var consts: Dictionary = s.get_script_constant_map()
	if consts.get("BIOME_ID") != &"glade":
		_fail("BIOME_ID is not &\"glade\"")
	if not (consts.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	var entries: Array = consts.get("ENTRIES", [])
	if entries.size() != LIMITS.size():
		_fail("ENTRIES has %d entries (%d expected)" % [entries.size(), LIMITS.size()])
	for e: Variant in entries:
		var d: Dictionary = e
		for key: String in ["mesh", "per_100m2", "scale", "cluster", "shadow", "range", "place"]:
			if not d.has(key):
				_fail("ENTRIES entry without '%s'" % key)
		if not PLACES.has(d.get("place")):
			_fail("bad place %s" % d.get("place"))
		var cl: float = float(d.get("cluster", -1.0))
		if cl < 0.0 or cl > 1.0:
			_fail("cluster out of 0..1")


func _check_items() -> void:
	var s := _script()
	if s == null:
		return
	if not s.has_method(&"items"):
		_fail("no static func items()")
		return
	var items: Array = _items()
	if items.size() != LIMITS.size():
		_fail("items() returned %d items (%d expected)" % [items.size(), LIMITS.size()])
	var seen := {}
	for it: Variant in items:
		if not (it is Dictionary):
			_fail("item is not a Dictionary")
			continue
		var d: Dictionary = it
		if not (d.get("mesh") is Mesh):
			_fail("item 'mesh' is not a Mesh")
			continue
		if not (d.get("material") is Material):
			_fail("item 'material' is not a Material")
		elif (d["material"] as Material).resource_path != NATURE_MAT:
			_fail("item 'material' is not the shared nature_mat.tres")
		if not (d.get("density") is float) or float(d["density"]) <= 0.0:
			_fail("item 'density' is not a positive float")
		var sc: Variant = d.get("scale")
		if not (sc is Vector2) or (sc as Vector2).x < 0.5 or (sc as Vector2).y > 2.0 or (sc as Vector2).x > (sc as Vector2).y:
			_fail("bad scale %s" % sc)
		if not (d.get("vis_end") is float):
			_fail("item 'vis_end' is not a float")
		if not (d.get("shadow") is bool):
			_fail("item 'shadow' is not a bool")
		elif bool(d["shadow"]):
			_fail("small decor casts shadows (map-fill.md 9)")
		if not (d.get("variants") is int) or int(d["variants"]) != 3:
			_fail("item 'variants' is not 3")
		var mesh: Mesh = d["mesh"]
		var name: String = mesh.resource_path.get_file().get_basename()
		seen[name] = true
		if not LIMITS.has(name):
			_fail("unexpected mesh %s" % mesh.resource_path)
			continue
		var lim: Array = LIMITS[name]
		if absf(float(d.get("vis_end", 0.0)) - float(lim[3])) > 0.01:
			_fail("%s: vis_end %s, spec %s" % [name, d.get("vis_end"), lim[3]])
		_check_mesh(name, mesh, lim, sc as Vector2 if sc is Vector2 else Vector2.ONE)
	for name2: String in LIMITS:
		if not seen.has(name2):
			_fail("no item for %s" % name2)


func _check_mesh(name: String, m: Mesh, lim: Array, sc: Vector2) -> void:
	var mesh := m as ArrayMesh
	if mesh == null:
		_fail("%s: not an ArrayMesh" % name)
		return
	var m0: Material = mesh.surface_get_material(0)
	if m0 == null or m0.resource_path != NATURE_MAT:
		_fail("%s: surface 0 is not the shared nature_mat.tres" % name)
	if bool(lim[4]):
		if mesh.get_surface_count() != 2 or mesh.surface_get_material(1) == null \
				or mesh.surface_get_material(1).resource_path != CONTACT_MAT:
			_fail("%s: no contact disc surface with nature_contact_mat.tres" % name)
	elif mesh.get_surface_count() != 1:
		_fail("%s: %d surfaces (1 expected)" % [name, mesh.get_surface_count()])
	for si: int in mesh.get_surface_count():
		var a2: Array = mesh.surface_get_arrays(si)
		if a2[Mesh.ARRAY_INDEX] == null or (a2[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty():
			_fail("%s: surface %d not indexed" % [name, si])
	var arr: Array = mesh.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		return
	if arr[Mesh.ARRAY_COLOR] == null or arr[Mesh.ARRAY_TEX_UV] == null or arr[Mesh.ARRAY_TEX_UV2] == null:
		_fail("%s: missing COLOR / UV / UV2" % name)
		return
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
	for t: int in range(0, idx.size(), 3):
		var mk: int = int(uv2[idx[t]].x)
		var kind: int = int(uv2[idx[t]].y)
		if kind != 0 and kind != 5:
			_fail("%s: kind %d (only bark 0 / ivy 5: no autumn leaves on flowers)" % [name, kind])
			return
		for k: int in 3:
			if mk == 0 or ((mk >> k) & 1) == 1:
				per[k] += 1
			if mk != 0 and mk != 7 and ((mk >> k) & 1) == 1:
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
	print("  %-22s variants %d / %d / %d tris, size %.2f x %.2f x %.2f" % [name, per[0], per[1], per[2], aabb.size.x,
		aabb.size.y, aabb.size.z])
	if name == "glade_tall_grass":
		_check_grass_read(arr, aabb, sc)


## The midfield must keep units readable: tall grass stays under a worker's shoulders at its largest scale, and its
## colour is no more saturated than the lawn (and clearly less than the Nature kingdom's green).
func _check_grass_read(arr: Array, aabb: AABB, sc: Vector2) -> void:
	var top: float = aabb.end.y * sc.y
	if top > WORKER_SHOULDER:
		_fail("tall grass %.2f m tall at max scale (> %.2f)" % [top, WORKER_SHOULDER])
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	var sat := 0.0
	var val := 0.0
	for c: Color in cols:
		sat += c.s
		val += c.v
	sat /= maxf(cols.size(), 1.0)
	val /= maxf(cols.size(), 1.0)
	print("  tall grass: %.2f m at max scale, mean saturation %.2f (lawn %.2f, Nature team %.2f), mean value %.2f" % [
		top, sat, LAWN.s, NATURE_TEAM.s, val])
	if sat > LAWN.s + 0.02:
		_fail("tall grass saturation %.2f > lawn %.2f" % [sat, LAWN.s])
	if sat > NATURE_TEAM.s - 0.1:
		_fail("tall grass too close to the Nature team green")


## Weighted glade area on Crown Hollow (map-fill.md 3.1: everything that is not water / riverbank / ruins / meadow /
## Old Wood / heath; 4 m blend = linear over +-2 m at each border), minus the lane (5.2 m clear), then the instances
## the set asks for there.
func _check_budget() -> void:
	var step := 0.5
	var area := 0.0
	var x := -60.0
	while x < 60.0:
		var z := -60.0
		while z < 60.0:
			var q := Vector2(x + step * 0.5, z + step * 0.5)
			area += _glade_weight(q) * step * step
			z += step
		x += step
	var per := 0.0
	for it: Variant in _items():
		per += float((it as Dictionary).get("density", 0.0))
	var n: float = per * area / 100.0
	print("  glade area %.0f m2 (weighted, both halves, lane cleared), %.1f per 100 m2 -> %.0f instances (budget %d)" % [
		area, per, n, BUDGET])
	if n > BUDGET:
		_fail("%.0f instances > %d" % [n, BUDGET])


func _glade_weight(q: Vector2) -> float:
	if absf(q.x) > 59.6 or absf(q.y) > 59.6:
		return 0.0
	var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, HUBS[0], HUBS[1])
	if q.distance_to(c) < 5.2:
		return 0.0
	# Signed distance outside each other zone (> 0 = outside).
	var d_river: float = INF
	for s: float in [1.0, -1.0]:
		for i: int in RIVER_N.size() - 1:
			var p: Vector2 = Geometry2D.get_closest_point_to_segment(q, RIVER_N[i] * s, RIVER_N[i + 1] * s)
			d_river = minf(d_river, q.distance_to(p))
	var dists: Array[float] = [
		d_river - (2.5 + 6.0),             # river water + riverbank
		q.length() - (14.5 + 6.0),          # isle, moat and its banks
		minf(q.distance_to(HUBS[0]), q.distance_to(HUBS[1])) - 22.0,     # Hearth Meadow
		minf(q.distance_to(WOODS[0]), q.distance_to(WOODS[1])) - 28.0,   # Old Wood
		44.0 - maxf(absf(q.x), absf(q.y)),  # heath
		minf(q.distance_to(STUMPS[0]), q.distance_to(STUMPS[1])) - (2.0 + 3.0),   # Giant's Stump ruins ring
	]
	var w := 1.0
	for d: float in dists:
		w *= clampf(d / 4.0 + 0.5, 0.0, 1.0)
	return w


func _check_no_lights() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		_fail("folder missing")
		return
	for f: String in dir.get_files():
		if f.get_extension() in ["tscn", "tres", "gd"]:
			var text: String = FileAccess.get_file_as_string(DIR + f)
			for light: String in ["OmniLight3D", "SpotLight3D", "DirectionalLight3D"]:
				if text.contains(light) and f != "glade_preview.gd":
					_fail("%s contains a %s" % [f, light])


## Info: decor mesh kinds over every biome set present (map-fill.md 9: <= 24 map-wide). Only the glade's own 3 are
## this task's; the total is printed for the lead.
func _count_kinds() -> void:
	var kinds := {}
	var dir := DirAccess.open(BIOMES_DIR)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		var path: String = BIOMES_DIR + sub + "/" + sub + "_set.gd"
		if not ResourceLoader.exists(path):
			continue
		var s := load(path) as GDScript
		if s == null:
			continue
		for e: Variant in s.get_script_constant_map().get("ENTRIES", []):
			if e is Dictionary:
				kinds[String((e as Dictionary).get("mesh", ""))] = true
	print("  decor mesh kinds over the biome sets present: %d (map budget 24; glade 3)" % kinds.size())


## Every mesh in a MultiMesh of 60 instances (what the scatter does), a few frames in the tree: no errors.
func _instance_all() -> void:
	var i := 0
	for it: Variant in _items():
		var d: Dictionary = it
		var mesh: Mesh = d["mesh"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 60
		for k: int in 60:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, k * 0.7), Vector3(i * 10.0 + (k % 8) * 1.2, 0.0,
				(k / 8) * 1.2)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(d["vis_end"])
		_stage.add_child(mmi)
		if mm.instance_count != 60 or mmi.multimesh.mesh != mesh:
			_fail("%s: MultiMesh setup failed" % mesh.resource_path.get_file())
		i += 1
