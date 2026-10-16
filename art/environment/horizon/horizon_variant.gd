class_name HorizonVariant
extends RefCounted
## G-F per-map horizon (docs/art/gf_horizon.md). The horizon ring (horizon.tscn) was baked around Crown Hollow; its
## landmark silhouettes (broken watchtower NE, toppled shrine NW, aqueduct W, standing-stone ring W, pond E, granite
## crags) made every map share one skyline. HorizonFit asks this script for the running map's variant:
##   crown_hollow  Crown Hollow (map id "", crown_hollow, crown_hollow_level): the baked ring, untouched.
##   fen           Thornwater and marsh maps: willow / alder canopy, peat ground, no crags; a fen mere with dead snags
##                 (E), an abandoned stilt hut (NE), a drowned grove (NW), a giant willow by a pool (W).
##   autumn        Quartermeet and the other autumn maps (the AutumnSwap shader paints the canopy): a windmill on the NE
##                 knoll, a farmstead (NW), an orchard (W), a stubble field with stooks and hay ricks (E).
##   neutral       every other map: the canopy as baked, a granite tor (NE / NW), a boulder field (W), a pine stand (E).
## The variant meshes are built once per (variant, map size, tier) from the 8 baked sector meshes: the tagged landmark
## pieces dropped (horizon_tag_bake.gd wrote the tags in UV.y), the canopy / ground recoloured, the new pieces added in
## the baked frame (one rigid anchor per site), then the HorizonFit move applied on the CPU so the ring hugs the map
## whatever material draws it (the AutumnSwap shader has no fit). Same material (horizon_mat.tres), same 8 draws, no
## lights, particles or colliders. Low tier: the dressing stays under the triangles it replaces.

const CROWN_HOLLOW := &"crown_hollow"
const FEN := &"fen"
const AUTUMN := &"autumn"
const NEUTRAL := &"neutral"
const CROWN_IDS: Array[StringName] = [&"", &"crown_hollow", &"crown_hollow_level"]
## Quartermeet's own horizon palette (palette_override): same autumn horizon shader, golden-yellow tones.
const QUARTERMEET_ID := &"quartermeet"
const AUTUMN_HORIZON_MAT := "res://art/environment/autumn/horizon_autumn_mat.tres"
const QM_PALETTE := "res://art/environment/quartermeet/quartermeet_palette.gd"
const QM_FAR_VALUE := 0.86      ## far crowns a touch darker than the near ones (haze)
const QM_FAR_GREEN := 0.55      ## the late-green minority reads as a dark olive at range
static var _palette_cache: Dictionary = {}

## UV.y tags of the baked meshes (horizon_tag_bake.gd); TAG_DRESSING marks the pieces this script adds.
const TAG_TOWER := 1
const TAG_SHRINE := 2
const TAG_AQUEDUCT := 3
const TAG_STONES := 4
const TAG_POND := 5
const TAG_CRAG := 6
const TAG_DRESSING := 10
const LANDMARK_TAGS: Array[int] = [TAG_TOWER, TAG_SHRINE, TAG_AQUEDUCT, TAG_STONES, TAG_POND]

## The builder's sites (horizon_builder.gd), in the baked frame (map square +-60 m).
const BAKED_HALF := 60.0
const TOWER := Vector2(86.0, -76.0)
const SHRINE := Vector2(-84.0, -80.0)
const AQ_A := Vector2(-82.0, -24.0)
const AQ_B := Vector2(-124.0, -31.0)
const STONES := Vector2(-90.0, 40.0)
const POND := Vector2(93.0, -32.0)
const CRAGS: Array[Vector2] = [Vector2(24.0, -86.0), Vector2(104.0, 58.0), Vector2(-100.0, -58.0), Vector2(-34.0, 100.0),
	Vector2(-30.0, -92.0), Vector2(42.0, 104.0)]
## The builder's small glades (no crowns, no flattened yard).
const GLADES: Array[Vector2] = [Vector2(94.0, 18.0), Vector2(-104.0, 76.0), Vector2(100.0, -58.0), Vector2(10.0, 100.0),
	Vector2(-58.0, -100.0)]

const HAZE := Color(0.30, 0.40, 0.46)
# Fen palette (sRGB; thornwater_palette.gd's mood: olive willow, blue-grey alder, peat, ochre sedge).
const WILLOW := Color(0.38, 0.44, 0.20)
const WILLOW_L := Color(0.52, 0.58, 0.26)
const ALDER := Color(0.13, 0.22, 0.21)
const PEAT := Color(0.20, 0.19, 0.12)
const SEDGE := Color(0.46, 0.43, 0.22)
const SEDGE_D := Color(0.33, 0.30, 0.15)
const FEN_WATER := Color(0.09, 0.14, 0.13)
const FEN_WATER_L := Color(0.17, 0.24, 0.22)
const MUD := Color(0.24, 0.21, 0.14)
const SNAG := Color(0.36, 0.33, 0.29)
const SNAG_D := Color(0.24, 0.22, 0.20)
const THATCH := Color(0.47, 0.39, 0.22)
const TIMBER := Color(0.30, 0.22, 0.15)
# Autumn palette (kept off green, so the AutumnSwap shader leaves it as painted).
const STRAW := Color(0.72, 0.60, 0.32)
const STRAW_D := Color(0.55, 0.44, 0.22)
const STUBBLE := Color(0.58, 0.47, 0.26)
const PLASTER := Color(0.66, 0.61, 0.52)
const ROOF_RED := Color(0.48, 0.22, 0.14)
const BARN := Color(0.46, 0.27, 0.16)
const SAIL := Color(0.70, 0.66, 0.56)
const APPLE := Color(0.62, 0.30, 0.12)
const APPLE_L := Color(0.78, 0.50, 0.18)
# Neutral / shared rock.
const ROCK := Color(0.44, 0.42, 0.40)
const ROCK_L := Color(0.55, 0.52, 0.47)
const ROCK_D := Color(0.30, 0.29, 0.30)
const ROCK_B := Color(0.39, 0.40, 0.45)
const MOSS := Color(0.26, 0.40, 0.17)
const PINE := Color(0.12, 0.28, 0.16)
const PINE_L := Color(0.22, 0.42, 0.21)
const FIR := Color(0.09, 0.25, 0.23)
const FIR_L := Color(0.17, 0.39, 0.31)
const OAK_D := Color(0.15, 0.28, 0.11)
const OAK := Color(0.25, 0.41, 0.15)
const OAK_L := Color(0.42, 0.57, 0.21)

const CELL := 5.0   ## ground sampler cell (m)

## Built variants: "kind|hx|hz|tier" -> Array[ArrayMesh] (sector order). F9 / a second match on the map reuses them.
static var _cache: Dictionary = {}
static var _conv := 0.0

## Per-build counters (read by tests / the doc): removed / added triangles.
var removed_tris := 0
var added_tris := 0

var _kind := NEUTRAL
var _tier := 0
var _chunks: Array[Chunk] = []
var _ground: Dictionary = {}      # Vector2i cell -> PackedVector3Array of ground vertices (baked frame)
var _anchor := Vector2.INF        # the current site's rigid anchor (INF = each piece on its own centre)
var _sector_of_site := -1


class Chunk:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var f := PackedFloat32Array()   # UV.x facet amount
	var a := PackedVector2Array()   # fit anchor
	var idx := PackedInt32Array()


# --- selection -------------------------------------------------------------------------------------------------------

## The variant for a map id and its look biome.
static func kind_for(map_id: StringName, biome: String) -> StringName:
	if CROWN_IDS.has(map_id):
		return CROWN_HOLLOW
	var b := biome.to_lower()
	if map_id == &"thornwater" or b.contains("marsh") or b.contains("fen") or b.contains("swamp"):
		return FEN
	if b.contains("autumn"):
		return AUTUMN
	return NEUTRAL


## The variant of a running level (MapInfo.map_id + the layout's biome, else the catalog entry's).
static func kind_for_level(level: Node) -> StringName:
	return kind_for(MapInfo.map_id, biome_of(level))


## The level's map id: its MapLayout id (LayoutLevel.map_layout()), else MapInfo.map_id.
static func layout_id_of(level: Node) -> StringName:
	if level != null and level.has_method(&"map_layout"):
		var lay: Variant = level.call(&"map_layout")
		if lay is Resource and &"id" in lay and String((lay as Resource).get(&"id")) != "":
			return StringName(String((lay as Resource).get(&"id")))
	return MapInfo.map_id


## The horizon palette for a map whose autumn tones differ from the shared AutumnSwap mix (Quartermeet: the harvest
## highland's golden-yellow crowns, docs/art/gf_quartermeet.md). A material override for every sector (a duplicate of
## horizon_autumn_mat.tres, the same shader and cost, its colours from QuartermeetPalette.NATURE); null = keep the
## shared material (Ashwind Reach and every other map unchanged). Cached per map id.
static func palette_override(map_id: StringName) -> Material:
	if map_id != QUARTERMEET_ID:
		return null
	if _palette_cache.has(map_id):
		return _palette_cache[map_id] as Material
	var base := load(AUTUMN_HORIZON_MAT) as ShaderMaterial if ResourceLoader.exists(AUTUMN_HORIZON_MAT) else null
	var pal := load(QM_PALETTE) as Script if ResourceLoader.exists(QM_PALETTE) else null
	if base == null or pal == null:
		return null
	var nature: Dictionary = pal.get_script_constant_map().get("NATURE", {})
	var mat := base.duplicate() as ShaderMaterial
	# The far crowns sit in haze: the near crown tones a little darker, and late green (not dark fir) as the minority.
	var far := func(key: StringName, fallback: Color) -> Color:
		var c: Color = nature.get(key, fallback)
		return Color(c.r * QM_FAR_VALUE, c.g * QM_FAR_VALUE, c.b * QM_FAR_VALUE)
	mat.set_shader_parameter(&"far_russet", far.call(&"crown_russet", Color(0.70, 0.45, 0.10)))
	mat.set_shader_parameter(&"far_amber", far.call(&"crown_amber", Color(0.88, 0.66, 0.13)))
	mat.set_shader_parameter(&"far_gold", far.call(&"crown_gold", Color(0.95, 0.82, 0.28)))
	mat.set_shader_parameter(&"far_evergreen", far.call(&"crown_late_green", Color(0.52, 0.53, 0.20)) * QM_FAR_GREEN)
	mat.set_shader_parameter(&"evergreen_share", 0.14)
	_palette_cache[map_id] = mat
	return mat


static func biome_of(level: Node) -> String:
	var lay: Variant = null
	if level != null and level.has_method(&"map_layout"):
		lay = level.call(&"map_layout")
	elif level != null and &"layout" in level:
		lay = level.get(&"layout")
	if lay is Resource and &"biome" in lay:
		var b := String((lay as Resource).get(&"biome"))
		if b != "":
			return b
	if MapInfo.map_id != &"":
		var cat := MapCatalog.load_default()
		if cat != null:
			return String(cat.entry(MapInfo.map_id).get("biome", ""))
	return ""


## The Crown Hollow landmark a piece belongs to (horizon_tag_bake.gd): `c` = its x/z centre in the baked frame,
## `disc` = a flat water disc (the pond). 0 = none.
static func landmark_tag(c: Vector2, disc: bool) -> int:
	if disc:
		return TAG_POND if c.distance_to(POND) < 9.0 else 0
	if c.distance_to(TOWER) < 12.5:
		return TAG_TOWER
	if c.distance_to(SHRINE) < 11.5:
		return TAG_SHRINE
	var q := Geometry2D.get_closest_point_to_segment(c, AQ_A - (AQ_B - AQ_A).normalized() * 1.5, AQ_B)
	if c.distance_to(q) < 5.0:
		return TAG_AQUEDUCT
	if c.distance_to(STONES) < 10.5:
		return TAG_STONES
	if c.distance_to(POND) < 9.5:
		return TAG_POND
	for k: Vector2 in CRAGS:
		if c.distance_to(k) < 12.5:
			return TAG_CRAG
	return 0


## The tags a variant drops.
static func dropped_tags(kind: StringName) -> Array[int]:
	if kind == CROWN_HOLLOW:
		return []
	var out: Array[int] = LANDMARK_TAGS.duplicate()
	if kind == FEN:
		out.append(TAG_CRAG)
	return out


# --- build -----------------------------------------------------------------------------------------------------------

## The 8 sector meshes of `kind` for a map of half size `half`, built from the baked `base` meshes (sector order).
## Cached. `tier` = GameSettings graphics tier (0 Low: the lean dressing).
static func meshes_for(kind: StringName, half: Vector2, base: Array[Mesh], tier: int) -> Array[ArrayMesh]:
	var key := "%s|%.2f|%.2f|%d" % [kind, half.x, half.y, mini(tier, 2)]
	if _cache.has(key):
		return _cache[key]
	var b := HorizonVariant.new()
	var out := b.build(kind, half, base, tier)
	_cache[key] = out
	return out


static func clear_cache() -> void:
	_cache.clear()
	_palette_cache.clear()


func build(kind: StringName, half: Vector2, base: Array[Mesh], tier: int) -> Array[ArrayMesh]:
	_kind = kind
	_tier = tier
	_chunks.clear()
	for i: int in 8:
		_chunks.append(Chunk.new())
	var drop := dropped_tags(kind)
	var bases: Array = []
	for m: Mesh in base:
		var arrays: Array = m.surface_get_arrays(0) if m != null and m.get_surface_count() > 0 else []
		bases.append(arrays)
		if not arrays.is_empty():
			_index_ground(arrays)
	_dress()
	var out: Array[ArrayMesh] = []
	for i: int in base.size():
		var arrays: Array = bases[i]
		var mat: Material = base[i].surface_get_material(0) if not arrays.is_empty() else null
		out.append(_compose(arrays, _chunks[i] if i < 8 else Chunk.new(), drop, half, mat))
	return out


## Base arrays minus the dropped pieces, recoloured, plus the chunk's dressing; the fit applied on the CPU.
func _compose(arrays: Array, ch: Chunk, drop: Array[int], half: Vector2, mat: Material) -> ArrayMesh:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var idx := PackedInt32Array()
	if not arrays.is_empty():
		var bv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var bc: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var buv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var buv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var bidx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var remap := PackedInt32Array()
		remap.resize(bv.size())
		remap.fill(-1)
		for t: int in range(0, bidx.size(), 3):
			var i0 := bidx[t]
			if drop.has(int(buv[i0].y)):
				removed_tris += 1
				continue
			for k: int in 3:
				var vi := bidx[t + k]
				if remap[vi] < 0:
					remap[vi] = v.size()
					var an := buv2[vi]
					var mv := HorizonFit.fit_point(an, half) - an
					v.append(Vector3(bv[vi].x + mv.x, bv[vi].y, bv[vi].z + mv.y))
					n.append(bn[vi])
					c.append(_recolour(bc[vi], buv[vi].x, Vector2(bv[vi].x, bv[vi].z)))
					uv.append(buv[vi])
					uv2.append(an)
				idx.append(remap[vi])
	var off := v.size()
	for k: int in ch.v.size():
		var an := ch.a[k]
		var mv := HorizonFit.fit_point(an, half) - an
		v.append(Vector3(ch.v[k].x + mv.x, ch.v[k].y, ch.v[k].z + mv.y))
		n.append(ch.n[k])
		c.append(ch.c[k])
		uv.append(Vector2(ch.f[k], float(TAG_DRESSING)))
		uv2.append(an)
	for k: int in ch.idx.size():
		idx.append(ch.idx[k] + off)
	added_tris += ch.idx.size() / 3
	var mesh := ArrayMesh.new()
	if idx.is_empty():
		return mesh
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = v
	out[Mesh.ARRAY_NORMAL] = n
	out[Mesh.ARRAY_COLOR] = c
	out[Mesh.ARRAY_TEX_UV] = uv
	out[Mesh.ARRAY_TEX_UV2] = uv2
	out[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	if mat != null:
		mesh.surface_set_material(0, mat)
	return mesh


## Variant colours of a baked vertex (value kept, hue moved). `f` = UV.x: 0 ground / pond, 0.55 conifer, 0.8 dome,
## 1 rock / ruin.
func _recolour(col: Color, f: float, p: Vector2) -> Color:
	if _kind != FEN:
		return col
	if f > 0.99:
		return col
	if f > 0.7:
		# Domes: olive willow, the brightest tops a little yellower; the old gold groves fall in line.
		return _tint(col, WILLOW.lerp(WILLOW_L, clampf((col.get_luminance() - 0.12) * 3.0, 0.0, 1.0)), 0.7)
	if f > 0.3:
		return _tint(col, ALDER, 0.55)
	# Ground: dark forest floor -> peat, the glades -> wet sedge.
	var l := col.get_luminance()
	return _tint(col, PEAT.lerp(SEDGE, smoothstep(0.16, 0.32, l)), 0.6)


static func _tint(c: Color, tone: Color, amount: float) -> Color:
	var tl := maxf(tone.get_luminance(), 0.001)
	var t := tone * (c.get_luminance() / tl)
	return Color(lerpf(c.r, t.r, amount), lerpf(c.g, t.g, amount), lerpf(c.b, t.b, amount), c.a)


# --- ground sampler (the baked hill ground, untagged UV.x 0 vertices) --------------------------------------------------

func _index_ground(arrays: Array) -> void:
	var bv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var buv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i: int in bv.size():
		if buv[i].x != 0.0 or buv[i].y != 0.0:
			continue
		var p := bv[i]
		var key := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
		var arr: PackedVector3Array = _ground.get(key, PackedVector3Array())
		arr.append(p)
		_ground[key] = arr


## Ground height at a baked-frame point: inverse-distance mean of the nearby ground vertices.
func _gy(p: Vector2) -> float:
	var key := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	var sw := 0.0
	var sy := 0.0
	for r: int in [1, 2]:
		for dz: int in range(-r, r + 1):
			for dx: int in range(-r, r + 1):
				var arr: PackedVector3Array = _ground.get(key + Vector2i(dx, dz), PackedVector3Array())
				for q: Vector3 in arr:
					var d2 := Vector2(q.x - p.x, q.z - p.y).length_squared()
					var w := 1.0 / (d2 + 0.25)
					sw += w * w
					sy += q.y * w * w
		if sw > 0.0:
			return sy / sw
	return 0.0


func _gy3(p: Vector2, dy: float = 0.0) -> Vector3:
	return Vector3(p.x, _gy(p) + dy, p.y)


# --- geometry helpers (horizon_builder.gd's, runtime) -----------------------------------------------------------------

static func _h(a: float, b: float, c: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453, 1.0)


static func _sector(p: Vector2) -> int:
	return posmod(int(round(atan2(p.x, -p.y) / (TAU / 8.0))), 8)


static func _out_d(p: Vector2) -> float:
	var q := p.clamp(Vector2(-BAKED_HALF, -BAKED_HALF), Vector2(BAKED_HALF, BAKED_HALF))
	return (p - q).length()


static func _haze(col: Color, d: float) -> Color:
	var t := smoothstep(18.0, 90.0, d)
	var l := col.get_luminance()
	var c := col.lerp(Color(l, l, l), t * 0.3)
	c = c.lerp(HAZE, t * 0.45)
	return Color(c.r, c.g, c.b, col.a)


static func _ca(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, a)


static func _winding() -> float:
	if _conv == 0.0:
		var arr: Array = BoxMesh.new().get_mesh_arrays()
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
		_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0
	return _conv


## Starts a rigid site: every piece added until `_end_site` moves with `at` (the fit never pulls a structure apart).
func _site(at: Vector2) -> void:
	_anchor = at
	_sector_of_site = _sector(at)


func _end_site() -> void:
	_anchor = Vector2.INF
	_sector_of_site = -1


func _chunk_at(p: Vector2) -> Chunk:
	return _chunks[_sector_of_site if _sector_of_site >= 0 else _sector(p)]


func _push(ch: Chunk, p: Vector3, nrm: Vector3, col: Color, facet: float, anchor: Vector2) -> int:
	ch.v.append(p)
	ch.n.append(nrm)
	ch.c.append(col)
	ch.f.append(facet)
	ch.a.append(anchor)
	return ch.v.size() - 1


func _tri(ch: Chunk, a: int, b: int, c: int, out: Vector3) -> void:
	var fn: Vector3 = (ch.v[b] - ch.v[a]).cross(ch.v[c] - ch.v[a])
	var s: float = 1.0 if fn.dot(out) >= 0.0 else -1.0
	if s != _winding():
		ch.idx.append_array([a, c, b])
	else:
		ch.idx.append_array([a, b, c])


## Flat-shaded faces (rocks, timber, plaster): faces turned up take `top` (alpha = amount), height AO in COLOR.a.
func _flat(verts: PackedVector3Array, tris: PackedInt32Array, centre: Vector3, col: Color, top: Color, seed: float,
		hints: PackedVector3Array = PackedVector3Array()) -> void:
	var ch := _chunk_at(Vector2(centre.x, centre.z))
	var anchor := _anchor if _anchor != Vector2.INF else Vector2(centre.x, centre.z)
	var y0 := INF
	var y1 := -INF
	for q: Vector3 in verts:
		y0 = minf(y0, q.y)
		y1 = maxf(y1, q.y)
	var d := _out_d(Vector2(centre.x, centre.z))
	for t: int in range(0, tris.size(), 3):
		var a: Vector3 = verts[tris[t]]
		var b: Vector3 = verts[tris[t + 1]]
		var c: Vector3 = verts[tris[t + 2]]
		var fn: Vector3 = (b - a).cross(c - a)
		if fn.length_squared() < 1e-10:
			continue
		fn = fn.normalized()
		var mid: Vector3 = (a + b + c) / 3.0
		var hint: Vector3 = hints[t / 3] if hints.size() > t / 3 and hints[t / 3] != Vector3.ZERO else mid - centre
		if fn.dot(hint) < 0.0:
			fn = -fn
		var hv := _h(mid.x * 0.37 + seed, mid.y * 0.51, mid.z * 0.29)
		var fc: Color = col * (0.9 + hv * 0.2)
		if top.a > 0.0 and fn.y > 0.55:
			fc = fc.lerp(Color(top.r, top.g, top.b), top.a * smoothstep(0.55, 0.9, fn.y))
		fc = _haze(fc, d)
		var base := ch.v.size()
		for p: Vector3 in [a, b, c]:
			_push(ch, p, fn, _ca(fc, lerpf(0.45, 1.0, clampf((p.y - y0) / maxf(y1 - y0, 0.01), 0.0, 1.0))), 1.0, anchor)
		_tri(ch, base, base + 1, base + 2, fn)


func _box(p: Vector3, size: Vector3, basis: Basis, col: Color, top: Color, seed: float) -> void:
	var v := PackedVector3Array()
	for i: int in 8:
		var s := Vector3(1.0 if (i & 1) != 0 else -1.0, 1.0 if (i & 2) != 0 else -1.0, 1.0 if (i & 4) != 0 else -1.0)
		v.append(p + basis * (s * size * 0.5))
	var tris := PackedInt32Array([0, 1, 3, 0, 3, 2, 4, 5, 7, 4, 7, 6, 0, 1, 5, 0, 5, 4, 2, 3, 7, 2, 7, 6,
		0, 2, 6, 0, 6, 4, 1, 3, 7, 1, 7, 5])
	_flat(v, tris, p, col, top, seed)


## A jagged prism, `segs` sides, r0 at the bottom -> r1 at the top, height h (tilted by `basis`).
func _prism(bottom: Vector3, segs: int, r0: float, r1: float, h: float, jag: float, basis: Basis, col: Color,
		top: Color, seed: float, cap_col: Color = Color(0, 0, 0, 0)) -> void:
	var v := PackedVector3Array()
	var rot := _h(seed, 1.0, 2.0) * TAU
	for k: int in segs:
		var a := rot + k * TAU / segs
		var jr := 0.85 + 0.3 * _h(seed, k, 3.0)
		v.append(bottom + basis * Vector3(cos(a) * r0 * jr, 0.0, sin(a) * r0 * jr))
	for k: int in segs:
		var a := rot + k * TAU / segs + (_h(seed, k, 4.0) - 0.5) * 0.3
		var jr := 0.8 + 0.4 * _h(seed, k, 5.0)
		v.append(bottom + basis * Vector3(cos(a) * r1 * jr, h - jag * _h(seed, k, 6.0), sin(a) * r1 * jr))
	v.append(bottom + basis * Vector3(0.0, h - jag * 0.5, 0.0))
	var side := PackedInt32Array()
	var cap := PackedInt32Array()
	var cap_hints := PackedVector3Array()
	var up: Vector3 = basis * Vector3.UP
	for k: int in segs:
		var k1 := (k + 1) % segs
		side.append_array([k, k1, segs + k, k1, segs + k1, segs + k])
		cap.append_array([segs + k, segs + k1, segs * 2])
		cap_hints.append(up)
	var centre: Vector3 = bottom + basis * Vector3(0.0, h * 0.4, 0.0)
	_flat(v, side, centre, col, top, seed)
	_flat(v, cap, centre, cap_col if cap_col.a > 0.0 else col, top, seed + 7.0, cap_hints)


## A gable roof over a w x d footprint (ridge along x), eave at `eave`, ridge `rise` higher: 2 slopes + 2 gables.
func _roof(c: Vector3, w: float, d: float, rise: float, basis: Basis, col: Color, gable: Color, seed: float) -> void:
	var hw := w * 0.5 + 0.35
	var hd := d * 0.5 + 0.45
	var p := PackedVector3Array([
		c + basis * Vector3(-hw, 0.0, -hd), c + basis * Vector3(hw, 0.0, -hd), c + basis * Vector3(hw, 0.0, hd),
		c + basis * Vector3(-hw, 0.0, hd), c + basis * Vector3(-hw, rise, 0.0), c + basis * Vector3(hw, rise, 0.0)])
	var centre: Vector3 = c + basis * Vector3(0.0, rise * 0.3, 0.0)
	_flat(p, PackedInt32Array([0, 1, 5, 0, 5, 4, 3, 2, 5, 3, 5, 4]), centre, col, Color(0, 0, 0, 0), seed)
	_flat(p, PackedInt32Array([0, 3, 4, 1, 2, 5]), centre, gable, Color(0, 0, 0, 0), seed + 3.0)


## A flat irregular disc (water, mud, stubble) `lift` over the ground's highest sample under it.
func _disc(at: Vector2, rx: float, rz: float, lift: float, col: Color, seed: float, y_override: float = NAN) -> void:
	var ch := _chunk_at(at)
	var anchor := _anchor if _anchor != Vector2.INF else at
	var segs := 12
	var y := y_override
	if is_nan(y):
		y = _gy(at)
		for k: int in 6:
			var a := k * TAU / 6.0
			y = maxf(y, _gy(at + Vector2(cos(a) * rx, sin(a) * rz) * 0.8))
	y += lift
	var col2 := _ca(_haze(col, _out_d(at)), 1.0)
	var b0 := _push(ch, Vector3(at.x, y, at.y), Vector3.UP, col2, 0.0, anchor)
	var rot := _h(seed, 3.0, 1.0) * TAU
	for k: int in segs:
		var a := rot + k * TAU / segs
		var rk := 0.78 + 0.44 * _h(seed, k, 2.0)
		_push(ch, Vector3(at.x + cos(a) * rx * rk, y, at.y + sin(a) * rz * rk), Vector3.UP, col2, 0.0, anchor)
	for k: int in segs:
		_tri(ch, b0, b0 + 1 + k, b0 + 1 + (k + 1) % segs, Vector3.UP)


## A round crown (7-sided dome, the builder's), anchored on its own centre unless a site is open.
func _dome(c: Vector3, r: float, h: float, lo: Color, mi: Color, hi: Color, seed: float) -> void:
	var ch := _chunk_at(Vector2(c.x, c.z))
	var anchor := _anchor if _anchor != Vector2.INF else Vector2(c.x, c.z)
	var d := _out_d(Vector2(c.x, c.z))
	lo = _haze(lo, d)
	mi = _haze(mi, d)
	hi = _haze(hi, d)
	var segs := 7
	var b0 := ch.v.size()
	var rot := _h(seed, 0.0, 1.0) * TAU
	for k: int in segs:
		var a := rot + k * TAU / segs
		var dir := Vector3(cos(a), 0.0, sin(a))
		_push(ch, c + dir * r * (0.88 + 0.24 * _h(seed, k, 2.0)) + Vector3(0.0, -0.15 * r * _h(seed, k, 3.0), 0.0),
			(dir - Vector3.UP * 0.2).normalized(), _ca(lo, 0.35), 0.8, anchor)
	for k: int in segs:
		var a := rot + (k + 0.5) * TAU / segs
		var dir := Vector3(cos(a), 0.0, sin(a))
		_push(ch, c + dir * r * (0.72 + 0.16 * _h(seed, k, 4.0)) + Vector3(0.0, h * (0.5 + 0.12 * _h(seed, k, 5.0)), 0.0),
			(dir * 0.72 + Vector3.UP * 0.7).normalized(), _ca(mi, 0.85), 0.8, anchor)
	var apex := c + Vector3((_h(seed, 6.0, 1.0) - 0.5) * r * 0.3, h, (_h(seed, 7.0, 1.0) - 0.5) * r * 0.3)
	_push(ch, apex, Vector3.UP, _ca(hi, 1.0), 0.8, anchor)
	var mid := c + Vector3(0.0, h * 0.3, 0.0)
	for k: int in segs:
		var k1 := (k + 1) % segs
		var a0 := b0 + k
		var a1 := b0 + k1
		var r0 := b0 + segs + k
		var r1 := b0 + segs + k1
		_tri(ch, a0, a1, r0, (ch.v[a0] + ch.v[a1] + ch.v[r0]) / 3.0 - mid)
		_tri(ch, r0, a1, r1, (ch.v[r0] + ch.v[a1] + ch.v[r1]) / 3.0 - mid)
		_tri(ch, r0, r1, b0 + segs * 2, (ch.v[r0] + ch.v[r1] + apex) / 3.0 - mid)


## A far conifer (two star tiers, the builder's).
func _conifer(base: Vector3, r: float, h: float, lo: Color, mi: Color, hi: Color, seed: float) -> void:
	var ch := _chunk_at(Vector2(base.x, base.z))
	var anchor := _anchor if _anchor != Vector2.INF else Vector2(base.x, base.z)
	var d := _out_d(Vector2(base.x, base.z))
	lo = _haze(lo, d)
	mi = _haze(mi, d)
	hi = _haze(hi, d)
	var rot := _h(seed, 0.0, 1.0) * TAU
	for tier: int in 2:
		var y0 := 0.0 if tier == 0 else h * 0.4
		var th := h * (0.62 if tier == 0 else 0.6)
		var rr := r * (1.0 if tier == 0 else 0.64)
		var b0 := ch.v.size()
		for k: int in 10:
			var a := rot + tier * 0.6 + k * TAU / 10.0
			var outer := k % 2 == 0
			var rk := rr * (1.0 if outer else 0.58) * (0.9 + 0.2 * _h(seed, k, tier + 2.0))
			var dir := Vector3(cos(a), 0.0, sin(a))
			var droop := -th * 0.14 if outer else th * 0.05
			_push(ch, base + dir * rk + Vector3(0.0, y0 + droop, 0.0), (dir * th + Vector3.UP * rr * 1.1).normalized(),
				_ca(lo if tier == 0 else mi, 0.3 if tier == 0 else 0.7), 0.55, anchor)
		var apex := base + Vector3(0.0, y0 + th, 0.0)
		_push(ch, apex, Vector3.UP, _ca(mi if tier == 0 else hi, 0.8 if tier == 0 else 1.0), 0.55, anchor)
		var mid := base + Vector3(0.0, y0 + th * 0.25, 0.0)
		for k: int in 10:
			var k1 := (k + 1) % 10
			_tri(ch, b0 + k, b0 + k1, b0 + 10, (ch.v[b0 + k] + ch.v[b0 + k1] + apex) / 3.0 - mid)


# --- dressing ----------------------------------------------------------------------------------------------------------

func _dress() -> void:
	_fill_aqueduct_line()
	match _kind:
		FEN:
			_fen()
		AUTUMN:
			_autumn()
		_:
			_neutral()


## The aqueduct's crown-free line (the builder kept it open for the arches): canopy, so no straight scar is left.
func _fill_aqueduct_line() -> void:
	var dir := (AQ_B - AQ_A).normalized()
	var across := Vector2(-dir.y, dir.x)
	var length := AQ_A.distance_to(AQ_B)
	var step := 3.6 if _tier > 0 else 4.4
	var k := 0
	var t := 1.0
	while t < length:
		var off := (_h(k, 1.0, 301.0) - 0.5) * 3.0
		var p := AQ_A + dir * t + across * off
		_crown(p, k, 301.0)
		if _tier > 0 and _h(k, 2.0, 301.0) > 0.45:
			_crown(p + across * (2.6 if off < 0.0 else -2.6) + dir * 1.4, k + 50, 302.0)
		t += step * (0.85 + _h(k, 3.0, 301.0) * 0.3)
		k += 1


## One canopy crown in the variant's palette (the autumn shader paints the green ones on autumn maps).
func _crown(p: Vector2, i: int, seed: float) -> void:
	var gy := _gy(p)
	var d := _out_d(p)
	var s := (0.95 + smoothstep(15.0, 75.0, d) * 0.25) * (0.85 + _h(i, 4.0, seed) * 0.3)
	var shade := lerpf(0.8, 0.6, smoothstep(15.0, 60.0, d)) * (0.9 + _h(i, 5.0, seed) * 0.2)
	var conifer := _h(i, 6.0, seed) < (0.25 if _kind == FEN else 0.45)
	if conifer:
		var c0 := ALDER if _kind == FEN else FIR
		var c1 := ALDER.lerp(FIR_L, 0.5) if _kind == FEN else FIR_L
		_conifer(Vector3(p.x, gy + 0.5 * s, p.y), 1.45 * s, (5.0 + _h(i, 7.0, seed) * 2.4) * s, c0 * 0.6 * shade,
			c0 * shade, c1 * shade, i * 13.0 + seed)
		return
	var lo := OAK_D
	var mi := OAK
	var hi := OAK.lerp(OAK_L, 0.55)
	if _kind == FEN:
		lo = WILLOW * 0.55
		mi = WILLOW
		hi = WILLOW_L
	var r := 1.9 * s * (0.9 + _h(i, 8.0, seed) * 0.25)
	_dome(Vector3(p.x, gy + (2.2 + _h(i, 9.0, seed)) * s, p.y), r, r * 1.1, lo * shade, mi * shade, hi * shade,
		i * 7.0 + seed)


## Low sedge / straw clump: a 5-sided spike.
func _tuft(p: Vector2, s: float, col: Color, seed: float) -> void:
	var ta := _h(seed, 1.0, 9.0) * TAU
	var tilt := Basis(Vector3(cos(ta), 0.0, sin(ta)), 0.12)
	_prism(_gy3(p, -0.15), 5, 0.75 * s, 0.12 * s, 1.2 * s, 0.25 * s, tilt, col, Color(0, 0, 0, 0), seed)


## A dead tree: a leaning trunk and one or two bare limbs.
func _snag(p: Vector2, h: float, seed: float) -> void:
	var a := _h(seed, 1.0, 5.0) * TAU
	var lean := Basis(Vector3(cos(a), 0.0, sin(a)), 0.06 + _h(seed, 2.0, 5.0) * 0.12)
	var base := _gy3(p, -0.4)
	_prism(base, 5, 0.42, 0.14, h, 0.4, lean, SNAG, Color(0, 0, 0, 0), seed, SNAG_D)
	var limbs := 1 + int(_h(seed, 3.0, 5.0) * 1.99)
	for k: int in limbs:
		var ya := a + PI * 0.5 + k * 2.3
		var at := base + lean * Vector3(0.0, h * (0.55 + 0.15 * k), 0.0)
		var lb := Basis(Vector3.UP, ya) * Basis(Vector3(0, 0, 1), 0.75)
		_box(at + lb * Vector3(0.0, 0.9, 0.0), Vector3(0.18, 1.9, 0.18), lb, SNAG_D, Color(0, 0, 0, 0), seed + 10.0 + k)


func _boulder(p: Vector2, s: float, seed: float) -> void:
	_box(_gy3(p, s * 0.2), Vector3(s * 1.5, s, s * 1.2), Basis.from_euler(Vector3(0.3, _h(seed, 1.0, 3.0) * TAU, 0.25)),
		ROCK_D.lerp(ROCK, 0.5), MOSS * Color(1, 1, 1, 0.7), seed)


## A granite tor: 3-4 leaning spires on a boulder skirt (the builder's crag, shorter and blockier).
func _tor(at: Vector2, seed: float) -> void:
	var n := 3 + int(_h(seed, 1.0, 0.0) * 1.99)
	for k: int in n:
		var a := _h(seed, k, 1.0) * TAU
		var p := at + Vector2(cos(a), sin(a)) * (k * 2.2) * (0.6 + _h(seed, k, 2.0) * 0.5)
		var hh := (8.5 - k * 1.5) * (0.8 + _h(seed, k, 3.0) * 0.4)
		var r0 := 2.9 - k * 0.35
		var tilt := Basis(Vector3(cos(a + 1.3), 0.0, sin(a + 1.3)), 0.06 + _h(seed, k, 4.0) * 0.1)
		var col: Color = [ROCK_B, ROCK, ROCK_L, ROCK.lerp(ROCK_B, 0.5)][k % 4]
		_prism(_gy3(p, -1.2), 6, r0, r0 * 0.55, hh, hh * 0.12, tilt, col, MOSS * Color(1, 1, 1, 0.8), seed + k)
	for k: int in (3 if _tier == 0 else 5):
		var a2 := _h(seed, k, 6.0) * TAU
		_boulder(at + Vector2(cos(a2), sin(a2)) * (4.5 + _h(seed, k, 7.0) * 3.5), 0.9 + _h(seed, k, 8.0), seed + 20.0 + k)


func _ring_points(at: Vector2, n: int, r0: float, r1: float, seed: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k: int in n:
		var a := _h(seed, k, 1.0) * TAU
		out.append(at + Vector2(cos(a), sin(a)) * lerpf(r0, r1, _h(seed, k, 2.0)))
	return out


# --- fen (Thornwater, marsh maps) --------------------------------------------------------------------------------------

func _fen() -> void:
	var rich := _tier > 0
	# E: a fen mere on the old pond terrace, dead snags standing in it, sedge round it.
	_site(POND)
	var py := _gy(POND)
	_disc(POND + Vector2(0.5, 0.0), 8.0, 6.4, 0.05, MUD, 401.0, py)
	_disc(POND + Vector2(-1.2, 0.6), 5.6, 4.2, 0.11, FEN_WATER, 402.0, py)
	_disc(POND + Vector2(3.6, -1.6), 2.6, 2.0, 0.12, FEN_WATER_L.lerp(FEN_WATER, 0.5), 403.0, py)
	_snag(POND + Vector2(-2.5, 1.2), 6.5, 404.0)
	_snag(POND + Vector2(2.4, -2.8), 4.6, 405.0)
	if rich:
		_snag(POND + Vector2(-5.2, -2.8), 3.6, 406.0)
	for p: Vector2 in _ring_points(POND, 6 if rich else 4, 6.0, 8.5, 407.0):
		_tuft(p, 0.9 + _h(p.x, p.y, 1.0) * 0.5, SEDGE if _h(p.y, p.x, 2.0) > 0.4 else SEDGE_D, p.x * 3.1 + p.y)
	_end_site()
	# NE: an abandoned stilt hut on the knoll, its posts in a pool.
	_site(TOWER)
	_disc(TOWER + Vector2(-1.0, 1.0), 5.4, 4.6, 0.08, FEN_WATER, 411.0)
	_stilt_hut(TOWER + Vector2(0.5, -0.5), 0.6, 412.0)
	_snag(TOWER + Vector2(5.0, 3.0), 5.2, 413.0)
	for p: Vector2 in _ring_points(TOWER, 5 if rich else 3, 4.5, 7.5, 414.0):
		_tuft(p, 1.0, SEDGE, p.x + p.y * 1.7)
	_end_site()
	# NW: a drowned grove: a ring of bog-oak snags round a black pool.
	_site(SHRINE)
	_disc(SHRINE, 5.0, 5.8, 0.06, MUD, 421.0)
	_disc(SHRINE + Vector2(0.4, -0.3), 3.6, 4.2, 0.12, FEN_WATER, 422.0)
	var n := 6 if rich else 4
	for k: int in n:
		var a := k * TAU / n + 0.4
		_snag(SHRINE + Vector2(cos(a), sin(a)) * 5.6, 4.0 + _h(k, 1.0, 423.0) * 3.5, 424.0 + k)
	_end_site()
	# W: a giant willow by a pool in the old stone meadow.
	_site(STONES)
	_disc(STONES + Vector2(3.0, 2.0), 4.6, 3.4, 0.07, FEN_WATER, 431.0)
	_giant_willow(STONES + Vector2(-2.0, -1.0), 432.0)
	for p: Vector2 in _ring_points(STONES, 6 if rich else 3, 5.0, 9.0, 433.0):
		_tuft(p, 1.1, SEDGE, p.x * 0.7 + p.y)
	_end_site()
	if rich:
		# Small pools in the far glades.
		for i: int in GLADES.size():
			var g: Vector2 = GLADES[i]
			_site(g)
			_disc(g, 2.6, 2.0, 0.06, FEN_WATER, 440.0 + i)
			_tuft(g + Vector2(2.8, 1.0), 0.9, SEDGE_D, 450.0 + i)
			_end_site()


func _stilt_hut(at: Vector2, yaw: float, seed: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	var gy := _gy(at)
	var deck_y := gy + 2.4
	for k: int in 4:
		var o := Vector2(1.7 if (k & 1) != 0 else -1.7, 1.4 if (k & 2) != 0 else -1.4)
		var o3: Vector3 = b * Vector3(o.x, 0.0, o.y)
		var lean := Basis(Vector3(o.y, 0.0, -o.x).normalized(), (_h(seed, k, 1.0) - 0.5) * 0.12)
		_box(Vector3(at.x + o3.x, gy + 1.1, at.y + o3.z), Vector3(0.28, 3.0, 0.28), lean * b, TIMBER, Color(0, 0, 0, 0),
			seed + k)
	_box(Vector3(at.x, deck_y, at.y), Vector3(4.4, 0.25, 3.8), b, TIMBER, Color(0, 0, 0, 0), seed + 5.0)
	_box(Vector3(at.x, deck_y + 1.05, at.y), Vector3(3.2, 1.9, 2.6), b * Basis(Vector3(0, 0, 1), 0.04), SNAG,
		Color(0, 0, 0, 0), seed + 6.0)
	# A sagging thatch roof, one corner fallen in.
	_roof(Vector3(at.x, deck_y + 2.0, at.y), 3.2, 2.6, 1.7, b * Basis(Vector3(1, 0, 0), 0.07), THATCH, SNAG_D, seed + 7.0)


func _giant_willow(at: Vector2, seed: float) -> void:
	var gy := _gy(at)
	_prism(Vector3(at.x, gy - 0.3, at.y), 6, 1.1, 0.7, 4.0, 0.3, Basis(), TIMBER, Color(0, 0, 0, 0), seed)
	var puffs := 5 if _tier > 0 else 3
	for k: int in puffs:
		var a := k * TAU / puffs + 0.3
		var r := 3.6 - (0.0 if k == 0 else 0.6)
		var o := Vector3(cos(a), 0.0, sin(a)) * (0.0 if k == 0 else 3.0)
		var c := Vector3(at.x, gy + (4.4 if k == 0 else 3.2), at.y) + o
		_dome(c, r, r * 0.95, WILLOW * 0.5, WILLOW, WILLOW_L, seed + k * 5.0)


# --- autumn (Quartermeet, autumn maps) ---------------------------------------------------------------------------------

func _autumn() -> void:
	var rich := _tier > 0
	# NE knoll: a windmill, sails turned to the map.
	_site(TOWER)
	_windmill(TOWER, 501.0)
	for k: int in (3 if rich else 1):
		_rick(TOWER + Vector2(-5.0 + k * 2.8, 4.5 + _h(k, 1.0, 502.0)), 1.3, 503.0 + k)
	_end_site()
	# NW knoll: a farmstead (barn + house, a fence line).
	_site(SHRINE)
	_disc(SHRINE, 8.0, 7.0, 0.06, STUBBLE, 511.0)
	var yaw := 0.35
	var b := Basis(Vector3.UP, yaw)
	var barn_at := SHRINE + Vector2(-1.5, 0.5)
	var gy := _gy(SHRINE)
	_box(Vector3(barn_at.x, gy + 1.7, barn_at.y), Vector3(7.0, 3.8, 4.4), b, BARN, Color(0, 0, 0, 0), 512.0)
	_roof(Vector3(barn_at.x, gy + 3.6, barn_at.y), 7.0, 4.4, 2.6, b, ROOF_RED, BARN, 513.0)
	var house_o: Vector3 = b * Vector3(5.6, 0.0, 2.4)
	_box(Vector3(barn_at.x + house_o.x, gy + 1.3, barn_at.y + house_o.z), Vector3(3.6, 3.0, 3.2), b, PLASTER,
		Color(0, 0, 0, 0), 514.0)
	_roof(Vector3(barn_at.x + house_o.x, gy + 2.8, barn_at.y + house_o.z), 3.6, 3.2, 1.9, b, ROOF_RED, PLASTER, 515.0)
	if rich:
		for k: int in 7:
			var fo: Vector3 = b * Vector3(-5.0 + k * 1.9, 0.0, -4.2)
			_box(_gy3(barn_at + Vector2(fo.x, fo.z), 0.5), Vector3(0.18, 1.1, 0.18), b, TIMBER, Color(0, 0, 0, 0),
				516.0 + k)
		_box(_gy3(barn_at + Vector2((b * Vector3(0.7, 0, -4.2)).x, (b * Vector3(0.7, 0, -4.2)).z), 0.85),
			Vector3(11.6, 0.12, 0.1), b, TIMBER, Color(0, 0, 0, 0), 525.0)
		_rick(SHRINE + Vector2(4.0, -4.0), 1.5, 526.0)
	_end_site()
	# W meadow: an orchard in rows.
	_site(STONES)
	_disc(STONES, 10.0, 8.5, 0.05, STUBBLE.lerp(BARN, 0.15), 531.0)
	var cols := 3 if rich else 2
	for i: int in cols:
		for j: int in 3:
			var p := STONES + Vector2(-4.0 + i * (8.0 / maxf(cols - 1, 1)), -4.5 + j * 4.5)
			p += Vector2(_h(i, j, 532.0) - 0.5, _h(j, i, 532.0) - 0.5) * 0.8
			var ty := _gy(p)
			_box(Vector3(p.x, ty + 0.7, p.y), Vector3(0.3, 1.6, 0.3), Basis(), TIMBER, Color(0, 0, 0, 0), 533.0 + i * 3 + j)
			_dome(Vector3(p.x, ty + 1.5, p.y), 1.5, 1.6, APPLE * 0.6, APPLE, APPLE_L, 540.0 + i * 3 + j)
	_end_site()
	# E: a harvested field on the pond terrace, stooks in rows and two hay ricks.
	_site(POND)
	var fy := _gy(POND)
	_disc(POND, 8.6, 6.8, 0.06, STUBBLE, 551.0, fy)
	var rows := 3 if rich else 2
	for r: int in rows:
		for k: int in 4:
			var p := POND + Vector2(-4.5 + k * 3.0, -3.0 + r * 3.0) + Vector2(_h(r, k, 552.0) - 0.5, 0.0) * 0.8
			_prism(Vector3(p.x, fy - 0.05, p.y), 5, 0.55, 0.08, 1.4, 0.15, Basis(), STRAW, Color(0, 0, 0, 0),
				553.0 + r * 5 + k)
	_rick(POND + Vector2(5.5, 3.0), 1.7, 560.0)
	if rich:
		_rick(POND + Vector2(-6.0, 3.6), 1.4, 561.0)
	_end_site()


## A post windmill: a tapered stone tower, a conical cap, four lattice sails facing the map.
func _windmill(at: Vector2, seed: float) -> void:
	var gy := _gy(at)
	_prism(Vector3(at.x, gy - 0.4, at.y), 8, 2.5, 1.8, 8.6, 0.0, Basis(), PLASTER, Color(0, 0, 0, 0), seed, PLASTER)
	_prism(Vector3(at.x, gy + 8.1, at.y), 8, 2.15, 0.12, 3.2, 0.0, Basis(), ROOF_RED, Color(0, 0, 0, 0), seed + 1.0)
	# The sails face the map centre (seen from the play space).
	var to_map := (-at).normalized()
	var face := Vector3(to_map.x, 0.0, to_map.y)
	var hub := Vector3(at.x, gy + 7.6, at.y) + face * 2.2
	var yaw := atan2(face.x, face.z)
	var b := Basis(Vector3.UP, yaw)
	for k: int in 4:
		var roll := k * PI * 0.5 + 0.35
		var arm := b * Basis(Vector3(0, 0, 1), roll)
		_box(hub + arm * Vector3(0.0, 3.4, 0.0), Vector3(1.15, 6.4, 0.12), arm, SAIL, Color(0, 0, 0, 0), seed + 2.0 + k)
	_box(hub, Vector3(0.6, 0.6, 0.7), b, TIMBER, Color(0, 0, 0, 0), seed + 9.0)


## A round hay rick: a squat golden dome.
func _rick(p: Vector2, r: float, seed: float) -> void:
	_dome(_gy3(p, 0.1), r, r * 1.35, STRAW_D, STRAW, STRAW.lerp(Color(0.9, 0.8, 0.5), 0.4), seed)


# --- neutral (every other map) -----------------------------------------------------------------------------------------

func _neutral() -> void:
	var rich := _tier > 0
	_site(TOWER)
	_tor(TOWER, 601.0)
	_end_site()
	_site(SHRINE)
	_tor(SHRINE + Vector2(1.0, 0.5), 611.0)
	_end_site()
	# W: a boulder field in the meadow.
	_site(STONES)
	for k: int in (7 if rich else 4):
		var a := _h(k, 1.0, 621.0) * TAU
		var p := STONES + Vector2(cos(a), sin(a)) * (1.5 + _h(k, 2.0, 621.0) * 7.0)
		_boulder(p, 0.9 + _h(k, 3.0, 621.0) * 1.3, 622.0 + k)
	_end_site()
	# E: a pine stand on the old pond terrace.
	_site(POND)
	for k: int in (6 if rich else 4):
		var a := k * TAU / 6.0 + _h(k, 1.0, 631.0) * 0.6
		var p := POND + Vector2(cos(a), sin(a)) * (2.0 + _h(k, 2.0, 631.0) * 4.0)
		var s := 1.0 + _h(k, 3.0, 631.0) * 0.35
		_conifer(_gy3(p, 0.4), 1.5 * s, 6.5 * s, PINE * 0.5, PINE, PINE_L, 632.0 + k)
	_boulder(POND + Vector2(5.5, 3.0), 1.4, 640.0)
	_end_site()
