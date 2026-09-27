extends SceneTree
## Task 12.V4: road bridges, fords, Crown Steps (art/environment/bridges/). Headless check of the three models:
## they load and instantiate, 0 lights / colliders / particles, baked indexed meshes with shared saved materials
## only (<= 3 per model), triangle budgets, shadows (bridge on, ford / steps off), the bridge deck flush with the
## ground (top y 0.02-0.08) and wide / long enough for the road, the walkway clear, two lantern glows (1.0, 0.8, 0.4)
## at opposite ends, the ford and steps low where units walk, foam inside the channel, and place_crossing() frames.
## Run: $GODOT --headless --path . -s tests/test_12_v4.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "12.V4"
const DIR := "res://art/environment/bridges/"
const PAINTED_MAT := "res://art/environment/env_painted_mat.tres"
const GLOW_MAT := "res://art/environment/lantern_glow_mat.tres"
const FOAM_MAT := "res://art/environment/bridges/crossing_foam_mat.tres"

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_check_scene("road_bridge.tscn", &"bridge_road", 3000, true)
	_check_scene("ford_stones.tscn", &"ford", 3500, false)
	_check_scene("crown_steps.tscn", &"steps", 2500, false)
	_check_bridge()
	_check_ford()
	_check_steps()
	_check_placement()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	quit()


func _fail(msg: String) -> void:
	_fails.append(msg)


func _load(file: String) -> Node3D:
	var path: String = DIR + file
	if not ResourceLoader.exists(path):
		_fail("%s missing" % path)
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		_fail("%s is not a scene" % path)
		return null
	return ps.instantiate() as Node3D


func _check_scene(file: String, kind: StringName, max_tris: int, shadow: bool) -> void:
	var m: Node3D = _load(file)
	if m == null:
		return
	if not m.has_method(&"place_crossing") or m.get(&"kind") != kind:
		_fail("%s: root needs crossing_art.gd with kind %s" % [file, kind])
	for t: String in ["Light3D", "CollisionObject3D", "CollisionShape3D", "GPUParticles3D", "CPUParticles3D"]:
		if not m.find_children("*", t, true, false).is_empty():
			_fail("%s: has a %s" % [file, t])
	var mats: Dictionary = {}
	var body := m.get_node_or_null(^"Body") as MeshInstance3D
	var foam := m.get_node_or_null(^"Foam") as MeshInstance3D
	if body == null or foam == null:
		_fail("%s: needs MeshInstance3D Body and Foam" % file)
		m.free()
		return
	var tris: int = 0
	for mi: MeshInstance3D in [body, foam]:
		var mesh := mi.mesh as ArrayMesh
		if mesh == null or mesh.resource_path.is_empty() or not mesh.resource_path.ends_with(".res"):
			_fail("%s/%s: mesh must be a baked .res" % [file, mi.name])
			continue
		for i: int in mesh.get_surface_count():
			var idx: PackedInt32Array = mesh.surface_get_arrays(i)[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				_fail("%s/%s: surface %d not indexed" % [file, mi.name, i])
			if mi == body:
				tris += idx.size() / 3
			var mat: Material = mesh.surface_get_material(i)
			if mat == null or mat.resource_path.is_empty():
				_fail("%s/%s: surface %d material is not a shared saved resource" % [file, mi.name, i])
			else:
				mats[mat.resource_path] = true
		if mi.material_override != null:
			_fail("%s/%s: material_override set" % [file, mi.name])
	if mats.size() > 3:
		_fail("%s: %d materials (max 3)" % [file, mats.size()])
	if not mats.has(PAINTED_MAT) or not mats.has(FOAM_MAT):
		_fail("%s: expects env_painted_mat + crossing_foam_mat, got %s" % [file, str(mats.keys())])
	if tris > max_tris:
		_fail("%s: body %d triangles (max %d)" % [file, tris, max_tris])
	var want: int = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if body.cast_shadow != want or foam.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		_fail("%s: shadow settings" % file)
	print("%s: body %d tris, %d materials" % [file, tris, mats.size()])
	m.free()


func _verts(file: String, node: String, surface: int) -> Array:
	var m: Node3D = _load(file)
	if m == null:
		return [PackedVector3Array(), PackedVector3Array()]
	var mesh := (m.get_node(NodePath(node)) as MeshInstance3D).mesh as ArrayMesh
	var out: Array = [PackedVector3Array(), PackedVector3Array()]
	if mesh != null and surface < mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(surface)
		out = [arr[Mesh.ARRAY_VERTEX], arr[Mesh.ARRAY_NORMAL]]
	m.free()
	return out


func _check_bridge() -> void:
	var f := "road_bridge.tscn"
	var m: Node3D = _load(f)
	if m == null:
		return
	var mesh := (m.get_node(^"Body") as MeshInstance3D).mesh as ArrayMesh
	if mesh.get_surface_count() != 2 or mesh.surface_get_material(1) == null \
			or mesh.surface_get_material(1).resource_path != GLOW_MAT:
		_fail("bridge: surface 1 must be the lantern glow (lantern_glow_mat)")
	else:
		var gc: Variant = (mesh.surface_get_material(1) as ShaderMaterial).get_shader_parameter(&"glow_color")
		if not (gc is Color) or not (gc as Color).is_equal_approx(Color(1.0, 0.8, 0.4)):
			_fail("bridge: lantern glow colour %s" % str(gc))
	m.free()
	var d: Array = _verts(f, "Body", 0)
	var v: PackedVector3Array = d[0]
	var n: PackedVector3Array = d[1]
	var top_max: float = -INF
	var top_min: float = INF
	var x_lo: float = INF
	var x_hi: float = -INF
	var z_lo: float = INF
	var z_hi: float = -INF
	var blocked: int = 0
	for i: int in v.size():
		var p: Vector3 = v[i]
		if absf(p.x) < 2.4 and absf(p.z) < 4.9 and p.y > 0.12:
			blocked += 1
		if n[i].y > 0.9 and p.y > 0.0 and p.y < 0.085 and absf(p.x) < 2.7 and absf(p.z) < 4.6:
			top_max = maxf(top_max, p.y)
			top_min = minf(top_min, p.y)
			x_lo = minf(x_lo, p.x)
			x_hi = maxf(x_hi, p.x)
			z_lo = minf(z_lo, p.z)
			z_hi = maxf(z_hi, p.z)
	if top_max > 0.08 or top_min < 0.02 or top_min > top_max:
		_fail("bridge: deck top y %.3f..%.3f (want 0.02..0.08)" % [top_min, top_max])
	if x_lo > -2.5 or x_hi < 2.5:
		_fail("bridge: deck width x %.2f..%.2f (want >= +-2.5: 6 m gap - 0.5 m agent radius)" % [x_lo, x_hi])
	if z_lo > -4.4 or z_hi < 4.4:
		_fail("bridge: deck length z %.2f..%.2f (want 9 m)" % [z_lo, z_hi])
	if blocked > 0:
		_fail("bridge: %d vertices above 0.12 m on the walkway" % blocked)
	var g: Array = _verts(f, "Body", 1)
	var gv: PackedVector3Array = g[0]
	var ends: Dictionary = {}
	for p: Vector3 in gv:
		if p.z > 3.5 and p.x > 3.0:
			ends["a"] = true
		elif p.z < -3.5 and p.x < -3.0:
			ends["b"] = true
		else:
			ends["other"] = true
	if not ends.has("a") or not ends.has("b") or ends.has("other"):
		_fail("bridge: the glow must be two lanterns at opposite ends, out over the banks (%s)" % str(ends.keys()))
	print("bridge: deck y %.3f..%.3f, x %.2f..%.2f, z %.2f..%.2f" % [top_min, top_max, x_lo, x_hi, z_lo, z_hi])


func _check_ford() -> void:
	var f := "ford_stones.tscn"
	var v: PackedVector3Array = _verts(f, "Body", 0)[0]
	var low: float = -INF
	var top: float = -INF
	for p: Vector3 in v:
		var r: float = Vector2(p.x, p.z).length()
		if r > 4.2:
			_fail("ford: vertex outside r 4.2 (%s)" % str(p))
			break
		if absf(p.x) < 2.3 and r < 3.3:
			low = maxf(low, p.y)
		top = maxf(top, p.y)
	if low > 0.2:
		_fail("ford: stones in the channel reach y %.2f (max 0.2)" % low)
	if top < 1.7 or top > 2.6:
		_fail("ford: marker poles top %.2f (want 1.7-2.6)" % top)
	for p: Vector3 in _verts(f, "Foam", 0)[0]:
		if absf(p.x) > 2.51:
			_fail("ford: foam outside the channel (%s)" % str(p))
			break
	print("ford: channel max y %.2f, poles %.2f" % [low, top])


func _check_steps() -> void:
	var f := "crown_steps.tscn"
	var isle := Vector2(0.0, -12.75)
	var walk: float = -INF
	for p: Vector3 in _verts(f, "Body", 0)[0]:
		var q := Vector2(p.x, p.z)
		if q.length() > 4.8 or p.y > 0.7:
			_fail("steps: vertex out of bounds (%s)" % str(p))
			break
		var d: float = q.distance_to(isle)
		if q.length() < 2.6 and d > 11.1 and d < 14.4:
			walk = maxf(walk, p.y)
	if walk > 0.08:
		_fail("steps: tread slabs reach y %.3f in the walking area (max 0.08)" % walk)
	var fv: PackedVector3Array = _verts(f, "Foam", 0)[0]
	if fv.is_empty():
		_fail("steps: no foam")
	print("steps: walking area max y %.3f" % walk)


func _check_placement() -> void:
	var cases: Array = [
		["road_bridge.tscn", Vector3(-12, 0, -48.7), Vector3(45, 0, -1), Vector3(45, 0, -1).normalized()],
		# Millstone: same yaw as Saltgate even when given the road the other way round (+Z east, wakes south).
		["road_bridge.tscn", Vector3(12, 0, 48.7), Vector3(-45, 0, 1), Vector3(45, 0, -1).normalized()],
		["ford_stones.tscn", Vector3(8.5, 0, 34), Vector3(1, 0, 8), Vector3(1, 0, 8).normalized()],
		["crown_steps.tscn", Vector3(-9.02, 0, -9.02), Vector3.ZERO, Vector3(-1, 0, -1).normalized()],
	]
	for c: Array in cases:
		var m: Node3D = _load(c[0])
		if m == null:
			continue
		root.add_child(m)
		m.call(&"place_crossing", c[1], c[2])
		var z: Vector3 = m.transform.basis.z.normalized()
		if z.dot(c[3]) < 0.999 or m.position.distance_to(c[1]) > 0.001 \
				or absf(m.transform.basis.determinant() - 1.0) > 0.001:
			_fail("%s: place_crossing frame (z %s)" % [c[0], str(z)])
		m.queue_free()
