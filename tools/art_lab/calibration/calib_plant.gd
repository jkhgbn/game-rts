class_name ArtLabCalibPlant
extends Node
## Art Lab calibration (docs/plan/art-lab.md "Calibration"): plants ONE known problem into a real asset, in memory.
## ArtLabCalibration.register_plants() packs `<real scene> + this node` into a virtual PackedScene (take_over_path, no
## file written, the real asset is never touched); every instance the lab spawns (target, 2nd instance for B9, team
## copies) carries the plant. It acts on the parent's `ready` signal, i.e. after the kit's _ready (parts built, pivots
## merged) and before the lab's first hook call (set_team_color comes after add_child returns).
## Modes:
##   green     every non-glow surface -> one shared grass-green material (the "green on grass" case, R3)
##   glow40    40 small emissive beads (4 vertices each) appended as one extra surface of each of the 4 biggest meshes
##             (no new draw instance, +160 vertices, R5)
##   verts20k  a dense hidden sphere (~19 k vertices) appended as an extra surface of the biggest mesh (B4)
##   float     the root lifted 0.4 m (feet in the air, R9)
##   permat    every material duplicated per instance (not shared by a 2nd instance, B9)
##   team      the team-colour cloth frozen (shared path-less copies: set_team_color changes nothing, R6)
## Built meshes / materials are cached per source (static) so only `permat` builds anything per instance.

## Picked so the lit body lands on the meadow's mean colour (ground L* 63, C* 48): first try 0.33 / 0.45 / 0.16 gave
## body L* 43 (dE 21.5, only a WARN)
const GREEN := Color(0.55, 0.72, 0.28)
const GLOW := Color(1.0, 0.62, 0.25)
const LIFT := 0.4

@export var mode: StringName = &""

static var _cache: Dictionary = {}


func _ready() -> void:
	var p := get_parent()
	if p == null:
		return
	if p.is_node_ready():
		_apply()
	else:
		p.ready.connect(_apply, CONNECT_ONE_SHOT)


func _apply() -> void:
	var root := get_parent() as Node3D
	if root == null:
		return
	match mode:
		&"green":
			_each_surface(root, func(m: Material) -> Material:
				return null if _is_glow(m) or _is_blob(m) else _green())
		&"team":
			# the mount kit recolours from the mesh's OWN surface materials, the character kit from the active one:
			# freeze both (a mesh copy with frozen cloth, cached per mesh; frozen overrides)
			for n: Node in root.find_children("*", "MeshInstance3D", true, false):
				var mi0 := n as MeshInstance3D
				if mi0.mesh is ArrayMesh:
					mi0.mesh = _frozen_mesh(mi0.mesh)
			_each_surface(root, func(m: Material) -> Material:
				return _frozen(m) if _is_team_cloth(m) else null)
		&"permat":
			_each_surface(root, func(m: Material) -> Material:
				return m.duplicate() if m != null else null)
		&"float":
			root.position.y += LIFT
		&"verts20k":
			var mi := _biggest_mesh(root)
			if mi != null:
				mi.mesh = _extended(mi.mesh, mode, 0)
		&"glow40":
			# 40 beads spread over the 4 biggest meshes (10 each): one extra surface per mesh, no new draw instance
			var big := _biggest_meshes(root, 4)
			for i: int in big.size():
				big[i].mesh = _extended(big[i].mesh, mode, 40 / big.size() + (1 if i < 40 % big.size() else 0))
		_:
			push_warning("ArtLabCalibPlant: unknown mode %s" % mode)


## Replaces the active material of every surface / material_override under `root` by `f(material)` (null = keep).
## Particles are left alone.
func _each_surface(root: Node, f: Callable) -> void:
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "GeometryInstance3D", true, false))
	for n: Node in nodes:
		if not n is GeometryInstance3D or n is GPUParticles3D or n is CPUParticles3D or n == self:
			continue
		var gi := n as GeometryInstance3D
		if gi.material_override != null:
			var w: Variant = f.call(gi.material_override)
			if w != null:
				gi.material_override = w
			continue
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
			var mi := gi as MeshInstance3D
			for s: int in mi.mesh.get_surface_count():
				var cur := mi.get_active_material(s)
				var w2: Variant = f.call(cur)
				if w2 != null:
					mi.set_surface_override_material(s, w2)


static func _is_glow(m: Material) -> bool:
	if m == null:
		return true
	if m is BaseMaterial3D and (m as BaseMaterial3D).emission_enabled:
		return true
	var nm := m.resource_path.get_file().to_lower()
	return "glow" in nm or "ember" in nm or "flame" in nm or "eye" in nm


static func _is_blob(m: Material) -> bool:
	return m != null and ("blob" in m.resource_path.to_lower() or "shadow_decal" in m.resource_path.to_lower())


static func _is_team_cloth(m: Material) -> bool:
	if m == null or m.resource_path == "":
		return false
	var nm := m.resource_path.get_file().get_basename()
	return nm.ends_with("_cloth") or nm.ends_with("_cloth_dark") or nm.ends_with("_cape") or nm.ends_with("_cape_plain") \
		or nm.ends_with("_pennon")


static func _green() -> Material:
	if not _cache.has("green"):
		var g := StandardMaterial3D.new()
		g.albedo_color = GREEN
		g.roughness = 0.95
		_cache["green"] = g
	return _cache["green"]


## A path-less copy of a team cloth (shared by every instance): the kit's team variants need a resource_path, so the
## colour never changes.
static func _frozen(m: Material) -> Material:
	var k := "team|%d" % m.get_instance_id()
	if not _cache.has(k):
		_cache[k] = m.duplicate()
	return _cache[k]


static func _glow_mat() -> Material:
	if not _cache.has("glow"):
		var g := StandardMaterial3D.new()
		g.albedo_color = GLOW
		g.emission_enabled = true
		g.emission = GLOW
		g.emission_energy_multiplier = 5.0
		_cache["glow"] = g
	return _cache["glow"]


static func _biggest_mesh(root: Node) -> MeshInstance3D:
	var l := _biggest_meshes(root, 1)
	return l[0] if not l.is_empty() else null


## The `n` visible ArrayMesh instances with the most vertices, biggest first.
static func _biggest_meshes(root: Node, n: int) -> Array[MeshInstance3D]:
	var all: Array = []
	for nd: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := nd as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or not mi.mesh is ArrayMesh:
			continue
		var cnt := 0
		for s: int in mi.mesh.get_surface_count():
			cnt += mi.mesh.surface_get_array_len(s)
		all.append([cnt, mi])
	all.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	var out: Array[MeshInstance3D] = []
	for e: Array in all.slice(0, n):
		out.append(e[1])
	return out


## A copy of `mesh` whose team-cloth surface materials are frozen (cached per source mesh).
static func _frozen_mesh(mesh: Mesh) -> Mesh:
	var k := "teammesh|%d" % mesh.get_instance_id()
	if _cache.has(k):
		return _cache[k]
	var hit := false
	for s: int in mesh.get_surface_count():
		hit = hit or _is_team_cloth(mesh.surface_get_material(s))
	var out: Mesh = mesh
	if hit:
		var am := mesh.duplicate() as ArrayMesh
		for s2: int in am.get_surface_count():
			var m := am.surface_get_material(s2)
			if _is_team_cloth(m):
				am.surface_set_material(s2, _frozen(m))
		out = am
	_cache[k] = out
	return out


## A copy of `mesh` with one extra surface (cached per source mesh, so two instances share it).
static func _extended(mesh: Mesh, what: StringName, beads: int) -> Mesh:
	var k := "%s|%d" % [what, mesh.get_instance_id()]
	if _cache.has(k):
		return _cache[k]
	var am := mesh.duplicate() as ArrayMesh
	if what == &"verts20k":
		var sp := SphereMesh.new()
		sp.radius = 0.03
		sp.height = 0.06
		sp.radial_segments = 128
		sp.rings = 148
		var arr := sp.get_mesh_arrays()
		var c := mesh.get_aabb().get_center()
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i: int in vs.size():
			vs[i] += c
		arr[Mesh.ARRAY_VERTEX] = vs
		arr[Mesh.ARRAY_TANGENT] = null
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		am.surface_set_material(am.get_surface_count() - 1, mesh.surface_get_material(0))
	else:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _beads(mesh, beads))
		am.surface_set_material(am.get_surface_count() - 1, _glow_mat())
	_cache[k] = am
	return am


## `n` small spheres spread over the mesh's up / outward-facing vertices (farthest-point sampling), in one array set.
static func _beads(mesh: Mesh, n: int) -> Array:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for s: int in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var nn: Variant = a[Mesh.ARRAY_NORMAL]
		for i: int in range(0, v.size(), 3):
			var no: Vector3 = (nn as PackedVector3Array)[i] if nn is PackedVector3Array and (nn as PackedVector3Array).size() > i else Vector3.UP
			if no.y > -0.3:
				pts.append(v[i])
				nrm.append(no)
	var chosen: Array[int] = []
	if pts.is_empty():
		return SphereMesh.new().get_mesh_arrays()
	# start at the highest point, then always the point farthest from those already chosen
	var top := 0
	for i: int in pts.size():
		if pts[i].y > pts[top].y:
			top = i
	chosen.append(top)
	var dmin := PackedFloat32Array()
	dmin.resize(pts.size())
	dmin.fill(INF)
	while chosen.size() < mini(n, pts.size()):
		var last := pts[chosen[-1]]
		var far := -1
		var far_d := -1.0
		for i: int in pts.size():
			dmin[i] = minf(dmin[i], pts[i].distance_squared_to(last))
			if dmin[i] > far_d:
				far_d = dmin[i]
				far = i
		chosen.append(far)
	# a 4-vertex bead (tetrahedron, r 7 cm = ~2 px at 40 m): 40 beads add 160 vertices, so the planted case stays
	# inside the host's vertex budget and only R5 moves
	var r := 0.07
	var ov := PackedVector3Array([Vector3(1, 1, 1) * r, Vector3(1, -1, -1) * r, Vector3(-1, 1, -1) * r, Vector3(-1, -1, 1) * r])
	var on := PackedVector3Array()
	for v4: Vector3 in ov:
		on.append(v4.normalized())
	var oi := PackedInt32Array([0, 1, 2, 0, 3, 1, 0, 2, 3, 1, 3, 2])
	var outv := PackedVector3Array()
	var outn := PackedVector3Array()
	var outi := PackedInt32Array()
	for c: int in chosen:
		var base := outv.size()
		var at := pts[c] + nrm[c].normalized() * 0.03
		for j: int in ov.size():
			outv.append(ov[j] + at)
			outn.append(on[j])
		for j2: int in oi.size():
			outi.append(oi[j2] + base)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = outv
	arr[Mesh.ARRAY_NORMAL] = outn
	arr[Mesh.ARRAY_INDEX] = outi
	return arr
