class_name BuildingMerge
extends RefCounted
## Mesh merging for the building models (task A.9): many primitive parts -> one ArrayMesh with one surface per
## material, so a whole tier of a building (walls + trims + doors...) costs one draw call per material instead of
## one per part. Used by FireHallModel / ShadowHallModel and the small buildings (hearth, hovel, spires).
## An item is `[mesh: Mesh, xf: Transform3D, material: Material]`. The ArrayMesh is baked once per `key` and shared
## by every instance (static cache); the materials stay per instance (surface override materials), so selection
## rims, team colours and glow boosts still work per building. Surfaces follow the order in which each material
## first appears in `items` (the build code is deterministic, so the same key always gives the same order).

static var _cache: Dictionary = {}


## Item helper: `mesh` at `pos`, rotated by `rot_deg` (Node3D order YXZ), scaled by `scale`.
static func item(mesh: Mesh, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO,
		scale: Vector3 = Vector3.ONE) -> Array:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
	return [mesh, Transform3D(b.scaled_local(scale), pos), mat]


## Item helper with a full transform.
static func item_xf(mesh: Mesh, xf: Transform3D, mat: Material) -> Array:
	return [mesh, xf, mat]


## The distinct materials of `items`, in surface order.
static func materials_of(items: Array) -> Array[Material]:
	var mats: Array[Material] = []
	for it: Array in items:
		var m: Material = it[2]
		if not mats.has(m):
			mats.append(m)
	return mats


## The merged mesh for `key` (baked from `items` the first time).
static func mesh_for(key: String, items: Array) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var am := ArrayMesh.new()
	for m: Material in materials_of(items):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for it: Array in items:
			if it[2] != m:
				continue
			var src: Mesh = it[0]
			for s: int in src.get_surface_count():
				st.append_from(src, s, it[1])
		st.commit(am)
	_cache[key] = am
	return am


## A MeshInstance3D showing the merged `items` (not added to the tree), materials set per surface.
static func instance(nm: String, key: String, items: Array) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh_for(key, items)
	var mats: Array[Material] = materials_of(items)
	for i: int in mats.size():
		mi.set_surface_override_material(i, mats[i])
	return mi
