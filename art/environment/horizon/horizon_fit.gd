class_name HorizonFit
extends Node3D
## Fits the horizon ring (horizon.tscn, baked by horizon_builder.gd around Crown Hollow's 120 x 120 m map) to the
## running map's size (MapInfo), so the far land always starts ~15 m outside the real map edge on every side.
## How: every vertex carries an ANCHOR in UV2 (its own x/z for the big ground sheets, the centre of its piece for a
## crown / rock / ruin piece; `anchors()` below, written by the builder and by horizon_anchor_bake.gd). The shader
## (horizon.gdshader `fit_xz`) moves each vertex by `fit(anchor) - anchor`, where `fit` maps the baked square onto the
## map rectangle: inside +-60 m it scales (the ground under the map's long sides stretches), outside it translates by
## the edge shift (the ring keeps its depth and shape). Crowns move whole, so they never stretch. On a 120 x 120 map
## the shift is exactly zero: Crown Hollow looks as before. One instance uniform per sector, no runtime mesh work.

const BAKED_HALF := 60.0       ## The map half size the ring was baked around (horizon_builder.gd MAP_HALF).
const PIECE_MAX := 20.0        ## A welded piece wider than this (the ground sheets) anchors each vertex on itself.

var fitted_half := Vector2(BAKED_HALF, BAKED_HALF)   ## The half size the ring is fitted to (read only).
## G-F per-map horizon (horizon_variant.gd): &"" until fitted, then HorizonVariant.CROWN_HOLLOW (the baked ring, shader
## fit) or the variant whose meshes replaced the baked ones (fen / autumn / neutral, fit baked on the CPU). Read only.
var variant := &""
## The map id whose own palette overrides the horizon material (apply_palette), &"" = the shared material. Read only.
var palette := &""
var _baked: Array[Mesh] = []   # the sector meshes from horizon.tscn (child order)


func _ready() -> void:
	# The level is this node's parent: its _ready (main.gd: MapInfo.setup first) runs after ours. Fit then.
	_fit_to_map.call_deferred()


func _fit_to_map() -> void:
	if not is_inside_tree():
		return
	var kind := HorizonVariant.kind_for_level(get_parent())
	if kind == HorizonVariant.CROWN_HOLLOW:
		variant = kind
		fit_to(MapInfo.half_x(), MapInfo.half_z())
		return
	apply_variant(kind, MapInfo.half_x(), MapInfo.half_z(), GameSettings.effective_graphics_quality())
	apply_palette(HorizonVariant.layout_id_of(get_parent()))


## A map with its own horizon palette (HorizonVariant.palette_override: Quartermeet) draws every sector with that
## material; any other id clears the override (the shared horizon_mat, AutumnSwap's tones on the autumn maps).
func apply_palette(map_id: StringName) -> void:
	var mat := HorizonVariant.palette_override(map_id)
	palette = map_id if mat != null else &""
	for c: Node in get_children():
		var mi := c as MeshInstance3D
		if mi != null:
			mi.material_override = mat


## Swaps the sector meshes for `kind`'s (HorizonVariant: the Crown Hollow landmarks dropped, the map's own dressing
## added, the fit already applied for a map of half size `half_x` x `half_z`). CROWN_HOLLOW puts the baked ring back.
func apply_variant(kind: StringName, half_x: float, half_z: float, tier: int) -> void:
	var sectors: Array[MeshInstance3D] = []
	for c: Node in get_children():
		if c is MeshInstance3D:
			sectors.append(c as MeshInstance3D)
	if _baked.is_empty():
		for mi: MeshInstance3D in sectors:
			_baked.append(mi.mesh)
	variant = kind
	if kind == HorizonVariant.CROWN_HOLLOW:
		for i: int in sectors.size():
			sectors[i].mesh = _baked[i]
		fit_to(half_x, half_z)
		return
	var meshes := HorizonVariant.meshes_for(kind, Vector2(half_x, half_z), _baked, tier)
	fitted_half = Vector2(half_x, half_z)
	for i: int in sectors.size():
		var mi := sectors[i]
		mi.mesh = meshes[i] if i < meshes.size() else null
		# The fit is in the vertices: the shader's own fit stays at rest.
		mi.set_instance_shader_parameter(&"map_half", Vector2(BAKED_HALF, BAKED_HALF))
		mi.extra_cull_margin = 0.0


## Fits the ring to a map of half size `half_x` x `half_z` (metres, map centred on the origin).
func fit_to(half_x: float, half_z: float) -> void:
	fitted_half = Vector2(half_x, half_z)
	var shift := Vector2(absf(half_x - BAKED_HALF), absf(half_z - BAKED_HALF))
	for c: Node in get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		mi.set_instance_shader_parameter(&"map_half", fitted_half)
		# The shader moves vertices outside the baked AABB: grow the cull box by the largest move.
		mi.extra_cull_margin = shift.length()


## Where the ring's baked point `p` (x/z) lands on a map of half size `half` (same mapping as the shader).
static func fit_point(p: Vector2, half: Vector2) -> Vector2:
	var r := Vector2.ZERO
	for i: int in 2:
		var a := absf(p[i])
		var h: float = half[i]
		var m: float = a * h / BAKED_HALF if a < BAKED_HALF else a + h - BAKED_HALF
		r[i] = signf(p[i]) * m
	return r


## The UV2 anchors of a baked sector mesh: vertices at the same position are welded, triangles join them into
## pieces; a piece no wider than PIECE_MAX anchors on its x/z bounds centre, a bigger one (ground) on each vertex.
static func anchors(verts: PackedVector3Array, idx: PackedInt32Array) -> PackedVector2Array:
	var n := verts.size()
	var parent := PackedInt32Array()
	parent.resize(n)
	var weld: Dictionary = {}
	for i: int in n:
		var v := verts[i]
		var key := Vector3i(roundi(v.x * 1000.0), roundi(v.y * 1000.0), roundi(v.z * 1000.0))
		var first: int = weld.get(key, -1)
		if first < 0:
			weld[key] = i
			parent[i] = i
		else:
			parent[i] = first
	var tri_idx := idx
	if tri_idx.is_empty():
		tri_idx.resize(n)
		for i: int in n:
			tri_idx[i] = i
	for t: int in range(0, tri_idx.size() - 2, 3):
		var a := _root(parent, tri_idx[t])
		for k: int in [1, 2]:
			var b := _root(parent, tri_idx[t + k])
			if a != b:
				parent[b] = a
	var lo: Dictionary = {}
	var hi: Dictionary = {}
	for i: int in n:
		var r := _root(parent, i)
		var p := Vector2(verts[i].x, verts[i].z)
		if lo.has(r):
			lo[r] = (lo[r] as Vector2).min(p)
			hi[r] = (hi[r] as Vector2).max(p)
		else:
			lo[r] = p
			hi[r] = p
	var out := PackedVector2Array()
	out.resize(n)
	for i: int in n:
		var r := _root(parent, i)
		var l: Vector2 = lo[r]
		var h: Vector2 = hi[r]
		if maxf(h.x - l.x, h.y - l.y) > PIECE_MAX:
			out[i] = Vector2(verts[i].x, verts[i].z)
		else:
			out[i] = (l + h) * 0.5
	return out


static func _root(parent: PackedInt32Array, i: int) -> int:
	var r := i
	while parent[r] != r:
		r = parent[r]
	while parent[i] != r:
		var nx := parent[i]
		parent[i] = r
		i = nx
	return r
