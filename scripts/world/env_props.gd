class_name EnvProps
extends Node3D
## The map's repeated props drawn with the environment art (art/environment/meshes/*.res): one
## MultiMeshInstance3D per mesh. The colliders stay the map's own StaticBody3Ds (main.gd _add_tree /
## _add_rock / _add_pillar), so the navmesh is unchanged; this node only draws. Call add_*() while
## building the map, then commit() once.

const MESH_DIR := "res://art/environment/meshes/"
const TREES: Array[String] = ["tree_pine", "tree_broadleaf", "tree_fir"]
const ROCKS: Array[String] = ["rock_boulder", "rock_slab", "rock_shards"]
const PILLAR := "ruin_pillar"
const PILLAR_ART_HEIGHT := 3.0   ## The pillar mesh is 3 m tall (scale y by height / 3).
const GROUND_MATERIAL_PATH := "res://art/environment/ground_material.tres"
const ROAD_SLOTS := 16            ## Size of the ground shader's road_segs array.
const ROAD_WIDTH := 3.0           ## Trodden dirt road width (market-trade.md 2.1).

var _xforms := {}   # mesh name -> Array[Transform3D]


## True when the art meshes exist (else main.gd keeps its placeholder shapes).
static func available() -> bool:
	return ResourceLoader.exists(MESH_DIR + TREES[0] + ".res")


## The painted ground material with the lane from `lane_a` to `lane_b`, up to 4 spots
## Vector4(x, z, radius, kind) (kind 0 = trodden dirt, 1 = broken flagstones) and the trade roads
## (market-trade.md 2.1: one Vector4(a.x, a.z, b.x, b.z) per segment, see set_roads). Null if missing.
static func ground_material(lane_a: Vector3, lane_b: Vector3, spots: Array[Vector4],
		roads: PackedVector4Array = PackedVector4Array()) -> ShaderMaterial:
	if not ResourceLoader.exists(GROUND_MATERIAL_PATH):
		return null
	var base := load(GROUND_MATERIAL_PATH) as ShaderMaterial
	if base == null:
		return null
	var mat := base.duplicate() as ShaderMaterial
	mat.set_shader_parameter(&"lane_a", Vector2(lane_a.x, lane_a.z))
	mat.set_shader_parameter(&"lane_b", Vector2(lane_b.x, lane_b.z))
	for i in 4:
		var s: Vector4 = spots[i] if i < spots.size() else Vector4.ZERO
		mat.set_shader_parameter(StringName("spot_%d" % i), s)
	if not roads.is_empty():
		set_roads(mat, roads)
	return mat


## Paints the trade roads on a ground material whose shader has the uniforms `road_segs` (vec4[ROAD_SLOTS],
## a.xz b.xz), `road_count` (int) and `road_width` (metres; 10.V10). Returns false (and changes nothing) when
## the shader has no `road_segs`. The slot count is the shader's own `road_segs[N]` (ROAD_SLOTS when it can't be read);
## more segments than slots are merged with fit_roads (review W1-6) so the whole network is painted.
static func set_roads(mat: ShaderMaterial, roads: PackedVector4Array, width: float = ROAD_WIDTH) -> bool:
	if mat == null or mat.shader == null:
		return false
	var names := {}
	for u: Dictionary in mat.shader.get_shader_uniform_list():
		names[String(u.get("name", ""))] = true
	if not names.has("road_segs"):
		return false
	var slots := road_slots(mat.shader)
	var fitted := fit_roads(roads, slots)
	var segs := PackedVector4Array()
	segs.resize(slots)
	var count := mini(fitted.size(), slots)
	for i in count:
		segs[i] = fitted[i]
	mat.set_shader_parameter(&"road_segs", segs)
	if names.has("road_count"):
		mat.set_shader_parameter(&"road_count", count)
	if names.has("road_width"):
		mat.set_shader_parameter(&"road_width", width)
	return true


## The size of the shader's `road_segs` array (read from its code), ROAD_SLOTS when it can't be read.
static func road_slots(shader: Shader) -> int:
	if shader == null:
		return ROAD_SLOTS
	var re := RegEx.create_from_string(r"uniform\s+vec4\s+road_segs\s*\[\s*(\d+)\s*\]")
	var m := re.search(shader.code)
	return maxi(1, int(m.get_string(1))) if m else ROAD_SLOTS


## `roads` cut down to at most `slots` segments: while there are too many, the two joined segments (one's end is the
## other's start) that bend the least become one (a-b + b-c -> a-c). Segments that join nothing are kept as they are;
## if that is still too many, the shortest are dropped (a warning says so).
static func fit_roads(roads: PackedVector4Array, slots: int) -> PackedVector4Array:
	var segs: Array[Vector4] = []
	for r in roads:
		segs.append(r)
	while segs.size() > slots:
		var best_i := -1
		var best_j := -1
		var best_cos := -2.0
		for i in segs.size():
			var a := segs[i]
			for j in segs.size():
				if i == j:
					continue
				var b := segs[j]
				if Vector2(a.z, a.w).distance_to(Vector2(b.x, b.y)) > 0.05:
					continue
				var d1 := Vector2(a.z - a.x, a.w - a.y).normalized()
				var d2 := Vector2(b.z - b.x, b.w - b.y).normalized()
				var c := d1.dot(d2)
				if c > best_cos:
					best_cos = c
					best_i = i
					best_j = j
		if best_i < 0:
			break
		var merged := Vector4(segs[best_i].x, segs[best_i].y, segs[best_j].z, segs[best_j].w)
		segs[best_i] = merged
		segs.remove_at(best_j)
	if segs.size() > slots:
		push_warning("EnvProps: %d road segments for %d shader slots, the shortest are not painted" % [segs.size(), slots])
		segs.sort_custom(func(p: Vector4, q: Vector4) -> bool:
			return Vector2(p.z - p.x, p.w - p.y).length() > Vector2(q.z - q.x, q.w - q.y).length())
		segs.resize(slots)
	var out := PackedVector4Array()
	for v in segs:
		out.append(v)
	return out


## Paints the river on a ground material whose shader has the 12.V2 uniforms (`river_segs`, `river_count`,
## `river_half_width`, `moat`, `fords`; the dictionary of `RiverSystem.shader_params()`, keys = uniform names).
## Keys the shader does not declare are skipped. Returns false (and changes nothing) when the shader has no
## `river_segs` (an older ground shader: missions, menus).
static func set_river(mat: ShaderMaterial, params: Dictionary) -> bool:
	if mat == null or mat.shader == null:
		return false
	var names := _uniform_names(mat.shader)
	if not names.has("river_segs"):
		return false
	for key: Variant in params:
		if names.has(String(key)):
			mat.set_shader_parameter(StringName(key), params[key])
	return true


## A tree of scale `s` at `pos` (collider: radius 0.45 s, height 2). The variant and the yaw come
## from the position, so the same map always looks the same.
func add_tree(pos: Vector3, s: float) -> void:
	var h := _hash(pos)
	var basis := Basis(Vector3.UP, h * TAU).scaled(Vector3(s, s, s))
	_add(TREES[int(h * 997.0) % TREES.size()], Transform3D(basis, pos))


## A tree of a named mesh kind (`"tree_willow"`: art/environment/meshes/<kind>.res) with the usual tree collider
## (radius 0.45 s, height 2, made by the map). `yaw` (radians) turns it (willow: local +X = the lean over the
## water); INF = a stable yaw from the position. A kind whose mesh does not exist draws a normal tree instead.
func add_tree_kind(kind: String, pos: Vector3, s: float, yaw: float = INF) -> void:
	if not ResourceLoader.exists(MESH_DIR + kind + ".res"):
		add_tree(pos, s)
		return
	var angle := _hash(pos) * TAU if yaw == INF else yaw
	_add(kind, Transform3D(Basis(Vector3.UP, angle).scaled(Vector3(s, s, s)), pos))


## A rock of scale `s` turned `rot` around y (collider: box 1.6 x 1.2 x 1.3 s).
func add_rock(pos: Vector3, s: float, rot: float) -> void:
	var h := _hash(pos)
	var basis := Basis(Vector3.UP, rot).scaled(Vector3(s, s, s))
	_add(ROCKS[int(h * 991.0) % ROCKS.size()], Transform3D(basis, pos))


## A ruin pillar `height` metres tall (collider: cylinder r 0.7).
func add_pillar(pos: Vector3, height: float) -> void:
	var basis := Basis(Vector3.UP, _hash(pos) * TAU).scaled(Vector3(1.0, height / PILLAR_ART_HEIGHT, 1.0))
	_add(PILLAR, Transform3D(basis, pos))


## Instances added so far (all meshes, committed or not).
func instance_count() -> int:
	var n := 0
	for key: String in _xforms:
		n += (_xforms[key] as Array).size()
	for c in get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi and mmi.multimesh:
			n += mmi.multimesh.instance_count
	return n


## Builds one MultiMeshInstance3D per mesh from what was added.
func commit() -> void:
	for key: String in _xforms:
		var list: Array = _xforms[key]
		var mesh := load(MESH_DIR + key + ".res") as Mesh
		if mesh == null or list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = key.to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		add_child(mmi)
	_xforms.clear()


func _add(key: String, xf: Transform3D) -> void:
	if not _xforms.has(key):
		_xforms[key] = []
	(_xforms[key] as Array).append(xf)


## Uniform names of a shader (the renderer's list; when the headless dummy lists none, the source is read).
static func _uniform_names(sh: Shader) -> Dictionary:
	var names := {}
	for u: Dictionary in sh.get_shader_uniform_list():
		names[String(u.get("name", ""))] = true
	if names.is_empty():
		for line: String in sh.code.split("\n"):
			var l := line.strip_edges()
			if l.begins_with("uniform "):
				var decl := l.get_slice("=", 0).get_slice(":", 0).strip_edges()
				names[decl.get_slice(" ", decl.get_slice_count(" ") - 1).get_slice("[", 0).trim_suffix(";")] = true
	return names


## 0-1, stable per position.
static func _hash(p: Vector3) -> float:
	return fposmod(sin(p.x * 12.9898 + p.z * 78.233) * 43758.5453, 1.0)
