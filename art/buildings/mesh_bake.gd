class_name MeshBake
extends RefCounted
## Shared pieces of the per-vertex material merges (PaintedVC, NatureVC, BuildingPalette; review-art-faces.md L1):
## the copies of surfaces that stay as they were must keep their custom-channel format, and the bake caches keyed by
## source mesh id are pruned the same way. (The four merges still write their own channels; a single "surface baker"
## with a channel callback is the next step once a before / after look test protects it.)


## The custom-channel format bits of surface `s` (CUSTOM0-3), to pass to add_surface_from_arrays when re-adding it.
static func custom_flags(mesh: Mesh, s: int) -> int:
	if not (mesh is ArrayMesh):
		return 0
	var f: int = (mesh as ArrayMesh).surface_get_format(s)
	var out: int = 0
	for c: int in 4:
		var shift: int = Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT + c * Mesh.ARRAY_FORMAT_CUSTOM_BITS
		out |= f & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << shift)
	return out


## Re-adds surface `s` of `mesh` to `am` unchanged (primitive, custom format, material, name).
static func copy_surface(am: ArrayMesh, mesh: Mesh, s: int) -> void:
	am.add_surface_from_arrays(mesh.surface_get_primitive_type(s), mesh.surface_get_arrays(s), [], {},
		custom_flags(mesh, s))
	var i := am.get_surface_count() - 1
	am.surface_set_material(i, mesh.surface_get_material(s))
	if mesh is ArrayMesh:
		am.surface_set_name(i, (mesh as ArrayMesh).surface_get_name(s))


## Drops cache entries [source mesh, ...] whose source mesh only the cache still holds (per-instance meshes of freed
## models), once the cache holds `limit` entries or more.
static func prune(cache: Dictionary, limit: int = 256) -> void:
	if cache.size() < limit:
		return
	for k: Variant in cache.keys():
		var e: Variant = cache[k]
		var src: Variant = (e as Array)[0] if e is Array and not (e as Array).is_empty() else null
		if src is Mesh and (src as Mesh).get_reference_count() <= 2:
			cache.erase(k)
