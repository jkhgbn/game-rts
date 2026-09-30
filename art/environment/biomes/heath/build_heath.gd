extends SceneTree
## Task 12.V9 (map-fill.md 3.1 biome 6 "Heath" + section 10): generates the heath scatter meshes with the SHARED
## painted nature material (art/environment/nature_props/nature_mat.tres + nature_contact_mat.tres, loaded, never
## re-saved). One mesh per decor kind, 3 shape variants in each through the variant mask (UV2.x): the shader picks the
## variant from a hash of the instance position, so one MultiMesh shows 3 shapes.
##   heath_heather.res        heather cushions ~0.9 m, 0.3-0.45 m tall (V0 round ling cushion in full purple bloom,
##                            V1 long two-lobed drift of magenta bell heather, V2 old straggly clump: pale lilac, a
##                            dead brown patch and a sprig of white heather)
##   heath_gorse.res          spiky dark gorse bushes crusted with yellow bloom (V0 round dome ~1.1 m, V1 taller
##                            double hump with dead silver twigs ~1.35 m, V2 low wide sprawl, half in flower) + disc
##   heath_tall_grass.res     wind-bent tall grass tufts, every blade combed toward local +X (V0 dense olive-gold tuft,
##                            V1 + three feathery seed plumes, V2 + flattened russet / straw blades): place them with
##                            the set's `yaw` so local +X follows the shader wind (the sway then pushes the bend)
##   heath_lichen_stones.res  faceted grey granite with gold / mint / white lichen crusts (V0 flat-topped boulder +
##                            2 stones, V1 tilted slab outcrop + pebbles, V2 a huddle of 3 low stones) + disc
## Vertex data follows nature_painted.gdshader: COLOR.rgb colour, COLOR.a height gradient, UV.x wind weight
## (clamp(y * k, 0, 0.45), one k per mesh) or the stone moss amount, UV.y local height + a lift on flower heads (the
## shader's dark contact band stays on stems and roots), UV2 = (variant mask, kind). Every mesh is indexed (welded).
## Gorse and stones carry a soft contact disc (surface 1, nature_contact_mat). No lights, no textures, no runtime
## materials.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/heath/build_heath.gd --quit-after 600

const DIR := "res://art/environment/biomes/heath/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45
const GOLDEN := 2.39996

# Palette (sRGB). The heath is the dry, warm, windswept flank of the map: olive and straw grass, purple heather and
# yellow gorse as the big colour accents (they echo the ground's painted blotches, a step brighter so they pop), cool
# grey granite as the neutral.
const H_LEAF_D := Color(0.13, 0.19, 0.11)
const H_LEAF := Color(0.24, 0.30, 0.16)
const LING_D := Color(0.27, 0.17, 0.32)
const LING := Color(0.47, 0.32, 0.57)
const LING_L := Color(0.60, 0.46, 0.70)
const BELL_D := Color(0.30, 0.15, 0.30)
const BELL := Color(0.53, 0.28, 0.52)
const BELL_L := Color(0.66, 0.42, 0.64)
const PALE_D := Color(0.38, 0.30, 0.38)
const PALE := Color(0.58, 0.50, 0.66)
const WHITE_H := Color(0.95, 0.92, 0.95)
const DEAD_H := Color(0.34, 0.27, 0.20)
const DEAD_H_L := Color(0.48, 0.39, 0.29)
## In-game grade 2026-09-30 (row 65, D8: a Nature unit dropped to dE 6.5 on the heath): the gorse leaves are darker
## and the tall grass roots / mid blades tawny straw instead of olive green, so green units stand off the decor.
const GORSE_D := Color(0.06, 0.12, 0.07)
const GORSE := Color(0.12, 0.22, 0.10)
const GORSE_L := Color(0.24, 0.33, 0.14)
const BLOOM_D := Color(0.92, 0.58, 0.05)
const BLOOM := Color(1.00, 0.80, 0.14)
const BLOOM_L := Color(1.00, 0.94, 0.45)
const WOOD := Color(0.30, 0.22, 0.15)
const TWIG := Color(0.55, 0.53, 0.49)
const TG_ROOT := Color(0.25, 0.21, 0.10)
const TG_OLIVE := Color(0.57, 0.48, 0.22)
const TG_STRAW := Color(0.82, 0.70, 0.36)
const TG_GOLD := Color(0.93, 0.81, 0.45)
const TG_RUSSET := Color(0.64, 0.38, 0.19)
const TG_PLUME := Color(0.93, 0.87, 0.70)
const GRANITE := Color(0.38, 0.37, 0.36)
const GRANITE_W := Color(0.39, 0.37, 0.34)
const GRANITE_B := Color(0.37, 0.38, 0.41)
const GRANITE_D := Color(0.29, 0.28, 0.28)
const LICHEN_MINT := Color(0.52, 0.60, 0.46)
const LICHEN_GOLD := Color(0.74, 0.58, 0.28)
const LICHEN_WHITE := Color(0.76, 0.76, 0.70)

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var _conv: float = 1.0
var _wind_k: float = 0.0   # wind weight per metre of height for the current mesh

# Current mesh (surface 0) and its contact disc (surface 1).
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()      # alpha < 0 = automatic height gradient at commit
var _uv := PackedVector2Array()   # (wind weight or moss, local height + lift)
var _uv2 := PackedVector2Array()  # (variant mask, kind)
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_detect_winding()
	mat = load(NDIR + "nature_mat.tres") as ShaderMaterial
	contact_mat = load(NDIR + "nature_contact_mat.tres") as ShaderMaterial
	if mat == null or contact_mat == null:
		push_error("nature materials missing")
		quit(1)
		return
	_build_heather()
	_build_gorse()
	_build_tall_grass()
	_build_lichen_stones()
	for line: String in _report:
		print(line)
	print("HEATH BUILD OK")
	quit()


# --- helpers -----------------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


## Smooth 3D value noise 0..1 (lichen crusts: patches a few facets wide instead of per-facet confetti).
func _vnoise(p: Vector3) -> float:
	var i: Vector3 = p.floor()
	var f: Vector3 = p - i
	f = f * f * (Vector3(3.0, 3.0, 3.0) - f * 2.0)
	var x00: float = lerpf(_h(i), _h(i + Vector3(1, 0, 0)), f.x)
	var x10: float = lerpf(_h(i + Vector3(0, 1, 0)), _h(i + Vector3(1, 1, 0)), f.x)
	var x01: float = lerpf(_h(i + Vector3(0, 0, 1)), _h(i + Vector3(1, 0, 1)), f.x)
	var x11: float = lerpf(_h(i + Vector3(0, 1, 1)), _h(i + Vector3(1, 1, 1)), f.x)
	return lerpf(lerpf(x00, x10, f.y), lerpf(x01, x11, f.y), f.z)


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _begin(wind_k: float) -> void:
	_wind_k = wind_k
	_v = PackedVector3Array()
	_n = PackedVector3Array()
	_c = PackedColorArray()
	_uv = PackedVector2Array()
	_uv2 = PackedVector2Array()
	_cv = PackedVector3Array()
	_cn = PackedVector3Array()
	_cuv = PackedVector2Array()
	_cuv2 = PackedVector2Array()


func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array,
		cols: PackedColorArray = PackedColorArray()) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	if not cols.is_empty():
		arr[Mesh.ARRAY_COLOR] = cols
	return arr


func _cyl(top: float, bottom: float, h: float, segs: int = 6, rings: int = 0) -> Array:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


func _sph(r: float, segs: int = 7, rings: int = 4) -> Array:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


func _box(size: Vector3, sub: int = 0) -> Array:
	var m := BoxMesh.new()
	m.size = size
	m.subdivide_width = sub
	m.subdivide_height = sub
	m.subdivide_depth = sub
	return m.get_mesh_arrays()


## Adds mesh arrays, transformed. Options (all optional):
##   kind (Kind, default IVY = foliage without autumn), mask (variant bits, 0 = always), jitter (m), seed, jit_axes,
##   normals: "flat" | "smooth" | "crown" (smooth, bent away from `crown`, squashed by crown_s, weight crown_k) |
##   "up" (mostly straight up), col2 + grad ("y" part height | "wy" mesh height | "r" distance from the part axis),
##   ao_c + ao_r (darker toward a crown's core), tint (random value variation, default 0.08), lift (metres added to
##   UV.y: keeps the contact band off heads), a (fixed COLOR.a, default: height in the mesh), wind (weight per metre,
##   default the mesh's), moss (stone: UV.x = this moss amount instead of a wind weight), clip_y (drop triangles
##   entirely below this height: the buried half of a stone), lichen (stone: seed of the crust pattern; faces turned
##   up get gold / mint / white lichen patches), no_caps (drop +-Y cap faces).
##   Per-vertex colours in the arrays (ARRAY_COLOR) win over col / col2.
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var vc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.IVY)
	var mask: int = o.get("mask", 0)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var jit_axes: Vector3 = o.get("jit_axes", Vector3.ONE)
	var mode: String = o.get("normals", "flat")
	var crown: Vector3 = o.get("crown", Vector3.ZERO)
	var crown_k: float = o.get("crown_k", 0.6)
	var crown_s: Vector3 = o.get("crown_s", Vector3.ONE)
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var ao_c: Vector3 = o.get("ao_c", Vector3.ZERO)
	var ao_r: float = o.get("ao_r", 0.0)
	var tint: float = o.get("tint", 0.08)
	var lift: float = o.get("lift", 0.0)
	var alpha: float = o.get("a", -1.0)
	var wk: float = o.get("wind", _wind_k)
	var moss: float = o.get("moss", -1.0)
	var clip_y: float = o.get("clip_y", -INF)
	var lichen: bool = o.has("lichen")
	var lichen_seed: float = o.get("lichen", 0.0)
	var no_caps: bool = o.get("no_caps", false)
	var nb: Basis = xf.basis.inverse().transposed()
	var miny: float = INF
	var maxy: float = -INF
	var maxr: float = 0.001
	for p: Vector3 in v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
		maxr = maxf(maxr, Vector2(p.x, p.z).length())
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	tv.resize(v.size())
	tn.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = xf * v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter * jit_axes
		tv[i] = p
		tn[i] = (nb * n[i]).normalized()
	var wminy: float = INF
	var wmaxy: float = -INF
	for p: Vector3 in tv:
		wminy = minf(wminy, p.y)
		wmaxy = maxf(wmaxy, p.y)
	for t: int in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		if no_caps and absf(n[a].y) > 0.99 and absf(n[b].y) > 0.99 and absf(n[c].y) > 0.99:
			continue
		if tv[a].y < clip_y and tv[b].y < clip_y and tv[c].y < clip_y:
			continue
		var fn: Vector3 = (tv[b] - tv[a]).cross(tv[c] - tv[a])
		if fn.length_squared() < 1e-12:
			continue
		fn = fn.normalized()
		var s: float = 1.0 if fn.dot(tn[a] + tn[b] + tn[c]) >= 0.0 else -1.0
		if s != _conv:
			var tmp: int = b
			b = c
			c = tmp
		fn *= s
		var centre: Vector3 = (tv[a] + tv[b] + tv[c]) / 3.0
		var fk: float = 1.0 + (_h(centre.snappedf(0.01)) - 0.5) * tint
		# Lichen: crust patches on the faces that see the sky (value noise over the stone, a few facets wide).
		var lich := Color(0, 0, 0, 0)
		if lichen and fn.y > -0.15:
			var ln: float = _vnoise(centre * 5.5 + Vector3(lichen_seed, lichen_seed * 0.37, lichen_seed * 0.71))
			var up: float = clampf((fn.y + 0.15) * 1.6, 0.0, 1.0)
			if ln > 0.70:
				lich = Color(LICHEN_GOLD.r, LICHEN_GOLD.g, LICHEN_GOLD.b, 0.6 * up)
			elif ln < 0.33:
				lich = Color(LICHEN_MINT.r, LICHEN_MINT.g, LICHEN_MINT.b, 0.65 * up)
			elif fn.y > 0.35 and _h(centre.snappedf(0.001) + Vector3(lichen_seed, 3.0, 1.0)) > 0.86:
				lich = Color(LICHEN_WHITE.r, LICHEN_WHITE.g, LICHEN_WHITE.b, 0.9)
		for vi: int in [a, b, c]:
			var nn: Vector3 = fn
			if mode == "smooth":
				nn = tn[vi]
			elif mode == "crown":
				var cd: Vector3 = ((tv[vi] - crown) / crown_s).normalized()
				nn = tn[vi].lerp(cd, crown_k).normalized()
			elif mode == "up":
				nn = (tn[vi] * 0.25 + Vector3.UP).normalized()
			var cc: Color
			if not vc.is_empty():
				cc = vc[vi]
			else:
				var gt: float = 0.0
				if grad == "y":
					gt = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
				elif grad == "wy":
					gt = clampf((tv[vi].y - wminy) / maxf(wmaxy - wminy, 0.001), 0.0, 1.0)
				else:
					gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
				cc = col.lerp(col2, gt)
			if lich.a > 0.0:
				cc = cc.lerp(Color(lich.r, lich.g, lich.b), lich.a)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			if ao_r > 0.0:
				var d: Vector3 = (tv[vi] - ao_c) * Vector3(1.0, 1.3, 1.0)
				k *= lerpf(0.62, 1.04, smoothstep(0.30, 1.0, d.length() / ao_r))
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k, alpha))
			var ux: float = moss if moss >= 0.0 else clampf(tv[vi].y * wk, 0.0, WMAX)
			_uv.append(Vector2(ux, tv[vi].y + lift))
			_uv2.append(Vector2(mask, kind))


## Soft contact shadow under the prop (surface 1): an irregular disc just above the ground.
func _disc(c: Vector3, rx: float, rz: float, segs: int, seed: float, mask: int = 0) -> void:
	var ring: Array[Vector3] = []
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.3
		ring.append(Vector3(c.x + cos(a) * rx * j, 0.035, c.z + sin(a) * rz * j))
	var centre := Vector3(c.x, 0.035, c.z)
	for i: int in segs:
		var p1: Vector3 = ring[i]
		var p2: Vector3 = ring[(i + 1) % segs]
		var fn: Vector3 = (p1 - centre).cross(p2 - centre)
		var up: bool = fn.y >= 0.0
		var tri: Array = [centre, p1, p2] if (1.0 if up else -1.0) == _conv else [centre, p2, p1]
		for k: int in 3:
			_cv.append(tri[k])
			_cn.append(Vector3.UP)
			_cuv.append(Vector2(0.0 if tri[k] == centre else 1.0, 0.0))
			_cuv2.append(Vector2(mask, 0.0))


## Bakes the height gradient (COLOR.a, unless a part fixed it), welds, saves DIR/<name>.res (surface 0: nature_mat,
## surface 1: contact disc if any) and reports the triangles per variant.
func _commit(name: String) -> ArrayMesh:
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - miny, 0.01)
	for i: int in _v.size():
		var cc: Color = _c[i]
		if cc.a < 0.0:
			cc.a = clampf((_v[i].y - miny) / span, 0.0, 1.0)
		_c[i] = cc
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = _uv
	arrays[Mesh.ARRAY_TEX_UV2] = _uv2
	var mesh := ArrayMesh.new()
	var welded: Array = _weld(arrays)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, welded)
	mesh.surface_set_material(0, mat)
	if not _cv.is_empty():
		var ca: Array = []
		ca.resize(Mesh.ARRAY_MAX)
		ca[Mesh.ARRAY_VERTEX] = _cv
		ca[Mesh.ARRAY_NORMAL] = _cn
		ca[Mesh.ARRAY_TEX_UV] = _cuv
		ca[Mesh.ARRAY_TEX_UV2] = _cuv2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(ca))
		mesh.surface_set_material(1, contact_mat)
	_save(mesh, DIR + name + ".res")
	var per := [0, 0, 0]
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-20s %4d tris, %4d verts (variants %d / %d / %d), contact %d, aabb %s .. %s" % [
		name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		_cv.size() / 3, aabb.position.snappedf(0.01), aabb.end.snappedf(0.01)])
	return mesh


## Non-indexed triangle arrays -> indexed ones, merging vertices whose every attribute matches.
func _weld(src: Array) -> Array:
	var sv: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	var sn: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
	var sc: PackedColorArray = src[Mesh.ARRAY_COLOR] if src[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var su: PackedVector2Array = src[Mesh.ARRAY_TEX_UV] if src[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var s2: PackedVector2Array = src[Mesh.ARRAY_TEX_UV2] if src[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	var seen := {}
	var remap := PackedInt32Array()
	remap.resize(sv.size())
	var keep := PackedInt32Array()
	for i: int in sv.size():
		var key := "%.4f,%.4f,%.4f|%.3f,%.3f,%.3f" % [sv[i].x, sv[i].y, sv[i].z, sn[i].x, sn[i].y, sn[i].z]
		if not sc.is_empty():
			key += "|%.3f,%.3f,%.3f,%.3f" % [sc[i].r, sc[i].g, sc[i].b, sc[i].a]
		if not su.is_empty():
			key += "|%.4f,%.4f" % [su[i].x, su[i].y]
		if not s2.is_empty():
			key += "|%d,%d" % [int(s2[i].x), int(s2[i].y)]
		if seen.has(key):
			remap[i] = seen[key]
		else:
			seen[key] = keep.size()
			remap[i] = keep.size()
			keep.append(i)
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var oc := PackedColorArray()
	var ou := PackedVector2Array()
	var o2 := PackedVector2Array()
	for i: int in keep:
		ov.append(sv[i])
		on.append(sn[i])
		if not sc.is_empty():
			oc.append(sc[i])
		if not su.is_empty():
			ou.append(su[i])
		if not s2.is_empty():
			o2.append(s2[i])
	out[Mesh.ARRAY_VERTEX] = ov
	out[Mesh.ARRAY_NORMAL] = on
	if not sc.is_empty():
		out[Mesh.ARRAY_COLOR] = oc
	if not su.is_empty():
		out[Mesh.ARRAY_TEX_UV] = ou
	if not s2.is_empty():
		out[Mesh.ARRAY_TEX_UV2] = o2
	out[Mesh.ARRAY_INDEX] = remap
	return out


# --- shape builders (return arrays for _part) ----------------------------------------------------

## A grass blade: a flattened 3-sided spike (visible from every side) in 2 segments, combed by `lean`: the middle
## ring carries only a quarter of the lean, so the blade stands up from the root and bends over at the top (a wind-
## bent curve, not a straight tilted stick). The tip drops by 30 % of the lean length. `face` = angle of the flat side.
func _bent_blade(base: Vector3, h: float, w: float, lean: Vector3, face: float, c0: Color, c1: Color) -> Array:
	var side := Vector3(cos(face), 0.0, sin(face))
	var out := Vector3(-side.z, 0.0, side.x)
	var tip: Vector3 = base + Vector3(0.0, maxf(h - lean.length() * 0.3, h * 0.35), 0.0) + lean
	var mid: Vector3 = base + Vector3(0.0, h * 0.5, 0.0) + lean * 0.25
	var sec: Array[Vector3] = [side * w, -side * w, out * w * 0.4]
	var cen: Vector3 = (sec[0] + sec[1] + sec[2]) / 3.0
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var rings: Array = [[base, 1.0, c0], [mid, 0.66, c0.lerp(c1, 0.55)]]
	for rg: Array in rings:
		for s: Vector3 in sec:
			v.append((rg[0] as Vector3) + s * float(rg[1]))
			n.append(((s - cen).normalized() + Vector3(0.0, 0.3, 0.0)).normalized())
			cols.append(rg[2] as Color)
	var t: int = v.size()
	v.append(tip)
	n.append(Vector3.UP)
	cols.append(c1)
	for i: int in 3:
		var j: int = (i + 1) % 3
		idx.append_array([i, j, 3 + i, j, 3 + j, 3 + i, 3 + i, 3 + j, t])
	return _mk(v, n, idx, cols)


## A 3-sided double pyramid from `a` to `b` (flower spires, thorns, seed plumes), radius `r` at `bulge` (0-1).
func _spindle(a: Vector3, b: Vector3, r: float, bulge: float, col_a: Color, col_b: Color) -> Array:
	var d: Vector3 = (b - a).normalized()
	var x: Vector3 = d.cross(Vector3.FORWARD if absf(d.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(d).normalized()
	var m: Vector3 = a + (b - a) * bulge
	var v := PackedVector3Array([a])
	var n := PackedVector3Array([-d])
	var cols := PackedColorArray([col_a])
	for i: int in 3:
		var ang: float = i * TAU / 3.0
		var rad: Vector3 = x * cos(ang) + z * sin(ang)
		v.append(m + rad * r)
		n.append(rad)
		cols.append(col_a.lerp(col_b, 0.6))
	v.append(b)
	n.append(d)
	cols.append(col_b)
	var idx := PackedInt32Array()
	for i: int in 3:
		var j: int = (i + 1) % 3
		idx.append_array([0, 1 + i, 1 + j, 4, 1 + j, 1 + i])
	return _mk(v, n, idx, cols)


## A chiselled rock (build_nature.gd's recipe): a unit sphere cut by `cuts` random planes and a tilted top plane at
## `top`, jittered, scaled by `radii`.
func _chunk(radii: Vector3, cuts: int, seed: float, top: float = 0.78, segs: int = 7, rings: int = 4) -> Array:
	var arr: Array = _sph(1.0, segs, rings)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var planes: Array = []
	for k: int in cuts:
		var a: float = _h(Vector3(seed, k, 1.0)) * TAU
		var tilt: float = lerpf(-0.35, 0.55, _h(Vector3(seed, k, 2.0)))
		var pn := Vector3(cos(a) * cos(tilt), sin(tilt), sin(a) * cos(tilt)).normalized()
		planes.append([pn, 0.66 + 0.22 * _h(Vector3(seed, k, 3.0))])
	var ta: float = _h(Vector3(seed, 9.0, 4.0)) * TAU
	planes.append([Vector3(cos(ta) * 0.18, 1.0, sin(ta) * 0.18).normalized(), top])
	var out := PackedVector3Array()
	out.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = v[i] + _h3(v[i].snappedf(0.001) + Vector3(seed, seed, seed)) * 0.07
		for pl: Array in planes:
			var pn2: Vector3 = pl[0]
			var over: float = p.dot(pn2) - float(pl[1])
			if over > 0.0:
				p -= pn2 * over
		out[i] = p * radii
	var n2 := PackedVector3Array()
	n2.resize(n.size())
	for i: int in n.size():
		n2[i] = (n[i] / radii).normalized()
	return _mk(out, n2, arr[Mesh.ARRAY_INDEX])


## A low dome (gorse bloom cap) around local +Y: a top point, a shoulder ring and a rim ring slightly below 0
## (sunk into the bush), `sides` x 3 triangles. shoulder = false: a cheap cap (top point + rim ring only, `sides`
## triangles; the gorse uses it since the Art Lab D2 pass: the crown normals keep it reading round at 40 m).
func _dome(r: float, sides: int, shoulder: bool = true) -> Array:
	var v := PackedVector3Array([Vector3(0.0, r * 0.5, 0.0)])
	var n := PackedVector3Array([Vector3.UP])
	var idx := PackedInt32Array()
	if not shoulder:
		for i: int in sides:
			var a: float = i * TAU / sides
			v.append(Vector3(cos(a) * r, -r * 0.06, sin(a) * r))
			n.append(Vector3(cos(a), 0.45, sin(a)).normalized())
		for i: int in sides:
			idx.append_array([0, 1 + (i + 1) % sides, 1 + i])
		return _mk(v, n, idx)
	for ring: Vector2 in [Vector2(0.72, 0.36), Vector2(1.0, -0.06)]:
		for i: int in sides:
			var a: float = (i + ring.x * 0.5) * TAU / sides
			v.append(Vector3(cos(a) * r * ring.x, r * ring.y, sin(a) * r * ring.x))
			n.append(Vector3(cos(a), 1.2 - ring.x, sin(a)).normalized())
	for i: int in sides:
		var j: int = (i + 1) % sides
		idx.append_array([0, 1 + j, 1 + i])
		idx.append_array([1 + i, 1 + j, 1 + sides + i, 1 + j, 1 + sides + j, 1 + sides + i])
	return _mk(v, n, idx)


## A point on the upper surface of an ellipsoid blob (centre c, radius r, squash sq), elevation `el` (0 = equator),
## azimuth `az`; also returns the outward direction.
func _on_blob(c: Vector3, r: float, sq: float, el: float, az: float) -> Array:
	var d := Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az))
	var p: Vector3 = c + Vector3(d.x * r, d.y * r * sq, d.z * r)
	var nrm: Vector3 = Vector3(d.x, d.y / maxf(sq, 0.05), d.z).normalized()
	return [p, nrm]


# --- heather -----------------------------------------------------------------------------------

func _build_heather() -> void:
	_begin(0.8)
	# Shared: a low dark-green woody cushion (mostly covered by the bloom; it shows as the dark underside / rim).
	var base_o := {"normals": "crown", "crown": Vector3(0.0, 0.02, 0.0), "crown_k": 0.55,
		"crown_s": Vector3(1.0, 0.5, 1.0), "col2": H_LEAF, "jitter": 0.025, "lift": 0.12, "tint": 0.08,
		"clip_y": -0.02}
	var bo: Dictionary = base_o.duplicate()
	bo["seed"] = 1.0
	_part(_sph(0.36, 8, 3), _xf(Vector3(0.0, 0.05, 0.0), Vector3.ZERO, Vector3(1.0, 0.42, 1.0)), H_LEAF_D, bo)
	# V0: ling in full bloom, a round cushion ~0.95 m: 4 purple mounds + 22 flower spires.
	var v0: Array = [[Vector3(0.12, 0.17, 0.06), 0.27], [Vector3(-0.17, 0.15, -0.1), 0.25],
		[Vector3(0.03, 0.14, -0.26), 0.22], [Vector3(-0.06, 0.15, 0.24), 0.23], [Vector3(0.28, 0.1, -0.16), 0.18]]
	_bloom_mounds(v0, LING_D, LING, V0, 10.0)
	_spires(v0, 16, LING_D, LING, V0, 11.0, 0.12)
	# V1: bell heather, a long two-lobed drift ~1.25 x 0.7 m in magenta, its own dark ends.
	var ends: Array = [[Vector3(-0.42, 0.04, 0.02), 0.24], [Vector3(0.44, 0.04, -0.04), 0.22]]
	for i: int in ends.size():
		var eo: Dictionary = base_o.duplicate()
		eo["mask"] = V1
		eo["seed"] = 20.0 + i
		_part(_sph(ends[i][1], 7, 3), _xf(ends[i][0], Vector3.ZERO, Vector3(1.0, 0.5, 1.0)), H_LEAF_D, eo)
	var v1: Array = [[Vector3(-0.36, 0.14, 0.02), 0.24], [Vector3(0.0, 0.2, 0.05), 0.27],
		[Vector3(0.38, 0.14, -0.05), 0.23], [Vector3(-0.12, 0.12, -0.2), 0.2]]
	_bloom_mounds(v1, BELL_D, BELL, V1, 22.0)
	_spires(v1, 15, BELL_D, BELL, V1, 23.0, 0.12)
	# V2: an old straggly clump, lower: pale lilac mounds, a dead brown patch, a sprig of white heather.
	var v2: Array = [[Vector3(0.14, 0.1, 0.1), 0.24], [Vector3(-0.2, 0.09, -0.04), 0.22]]
	_bloom_mounds(v2, PALE_D, PALE, V2, 30.0)
	var dead := {"normals": "crown", "crown": Vector3(0.0, 0.02, 0.0), "crown_k": 0.5, "col2": DEAD_H_L,
		"jitter": 0.03, "seed": 31.0, "mask": V2, "lift": 0.12, "clip_y": -0.02}
	_part(_sph(0.2, 7, 3), _xf(Vector3(0.05, 0.07, -0.27), Vector3.ZERO, Vector3(1.1, 0.55, 0.9)), DEAD_H, dead)
	_spires(v2, 9, PALE_D, PALE, V2, 32.0, 0.1)
	_spires([[Vector3(-0.3, 0.1, 0.22), 0.1]], 4, PALE, WHITE_H, V2, 33.0, 0.13)
	_commit("heath_heather")


## Purple bloom mounds: squashed blobs, dark bloom at the underside -> bright bloom on top.
func _bloom_mounds(list: Array, dark: Color, light: Color, mask: int, seed: float) -> void:
	for i: int in list.size():
		var c: Vector3 = list[i][0]
		var r: float = list[i][1]
		_part(_sph(r, 7, 3), _xf(c, Vector3(0.0, seed + i, 0.0), Vector3(1.0, 0.62, 1.0)), H_LEAF.lerp(dark, 0.5),
			{"normals": "crown", "crown": Vector3(0.0, 0.0, 0.0), "crown_k": 0.5, "crown_s": Vector3(1.0, 0.55, 1.0),
			"col2": light, "mask": mask, "jitter": 0.042, "seed": seed + i * 1.7, "lift": 0.2, "tint": 0.12,
			"clip_y": -0.02})


## Flower spires standing out of the mounds' tops (upright, splayed a little outward).
func _spires(list: Array, count: int, dark: Color, light: Color, mask: int, seed: float, length: float) -> void:
	for i: int in count:
		var b: Array = list[i % list.size()]
		var t: float = _h(Vector3(i, seed, 1.0))
		var az: float = i * GOLDEN + seed
		var el: float = lerpf(0.35, 1.3, _h(Vector3(i, seed, 2.0)))
		var on: Array = _on_blob(b[0] as Vector3, b[1] as float, 0.62, el, az)
		var p: Vector3 = (on[0] as Vector3) - (on[1] as Vector3) * 0.03
		var dir: Vector3 = ((on[1] as Vector3) * 0.45 + Vector3.UP).normalized()
		var ln: float = length * (0.75 + t * 0.5)
		_part(_spindle(p, p + dir * ln, 0.036 + t * 0.012, 0.45, dark, light), Transform3D.IDENTITY, light,
			{"mask": mask, "normals": "smooth", "lift": 0.3, "a": 1.0, "tint": 0.06})


# --- gorse -------------------------------------------------------------------------------------

func _build_gorse() -> void:
	_begin(0.15)
	# Shared: three woody stems at the foot (seen between the lower blobs).
	for i: int in 3:
		var a: float = i * TAU / 3.0 + 0.4
		var lean := Vector3(cos(a) * 0.18, 0.0, sin(a) * 0.18)
		_part(_cyl(0.025, 0.045, 0.42, 5), _xf(Vector3(cos(a) * 0.08, 0.2, sin(a) * 0.08) + lean * 0.5,
			Vector3(sin(a) * 0.4, 0.0, -cos(a) * 0.4)), WOOD, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.06})
	# Crowns: dark spiny blobs + thorn spikes + yellow bloom caps on the sunny upper half.
	# V0: a round dome ~1.1 m tall, 1.4 m wide, in full bloom.
	var v0: Array = [[Vector3(0.0, 0.52, 0.0), 0.5], [Vector3(0.34, 0.5, 0.12), 0.38], [Vector3(-0.32, 0.5, -0.12), 0.4],
		[Vector3(0.02, 0.84, 0.02), 0.34], [Vector3(0.04, 0.44, 0.38), 0.34], [Vector3(-0.06, 0.46, -0.4), 0.32]]
	_gorse_crown(v0, V0, 40.0, 10, 20, 1.0)
	_disc(Vector3.ZERO, 0.95, 0.9, 12, 40.0, V0)
	# V1: taller double hump ~1.35 m, dead silver twigs poking out.
	var v1: Array = [[Vector3(0.18, 0.62, 0.0), 0.42], [Vector3(-0.18, 0.92, 0.04), 0.36], [Vector3(-0.3, 0.46, 0.2), 0.34],
		[Vector3(0.32, 0.4, -0.24), 0.3], [Vector3(0.22, 0.98, -0.06), 0.28]]
	_gorse_crown(v1, V1, 50.0, 9, 16, 1.0)
	var twigs: Array = [[Vector3(-0.1, 0.9, 0.1), Vector3(-0.55, 1.42, 0.22)], [Vector3(0.2, 0.8, -0.1), Vector3(0.62, 1.2, -0.3)],
		[Vector3(-0.3, 0.5, -0.1), Vector3(-0.72, 0.72, -0.34)], [Vector3(0.05, 1.0, 0.0), Vector3(0.12, 1.5, 0.12)]]
	for i: int in twigs.size():
		var a2: Vector3 = twigs[i][0]
		var b2: Vector3 = twigs[i][1]
		var d2: Vector3 = b2 - a2
		var basis := Basis(Quaternion(Vector3.UP, d2.normalized()))
		_part(_cyl(0.008, 0.024, d2.length(), 4), Transform3D(basis, (a2 + b2) * 0.5), TWIG,
			{"kind": Kind.BARK, "mask": V1, "normals": "smooth", "tint": 0.05, "col2": TWIG.lightened(0.15)})
	_disc(Vector3(0.0, 0.0, 0.0), 0.85, 0.8, 12, 50.0, V1)
	# V2: a low wide sprawl ~0.8 m tall, 1.6 m wide, half in flower.
	var v2: Array = [[Vector3(0.0, 0.34, 0.0), 0.42], [Vector3(0.5, 0.28, 0.02), 0.34], [Vector3(-0.5, 0.28, 0.12), 0.34],
		[Vector3(0.08, 0.28, -0.5), 0.32], [Vector3(0.0, 0.58, 0.1), 0.3]]
	_gorse_crown(v2, V2, 60.0, 10, 10, 0.85)
	_disc(Vector3.ZERO, 1.05, 0.95, 12, 60.0, V2)
	_commit("heath_gorse")


func _gorse_crown(blobs: Array, mask: int, seed: float, thorns: int, blooms: int, bloom_k: float) -> void:
	var crown := Vector3(0.0, 0.55, 0.0)
	for i: int in blobs.size():
		var c: Vector3 = blobs[i][0]
		var r: float = blobs[i][1]
		var dark: Color = GORSE_D.lerp(GORSE, clampf(c.y * 0.8, 0.0, 1.0))
		_part(_sph(r, 6, 3), _xf(c, Vector3(0.0, seed + i, 0.0), Vector3(1.0, 0.86, 1.0)), dark,
			{"normals": "crown", "crown": crown, "crown_k": 0.55, "crown_s": Vector3(0.8, 0.6, 0.8), "col2": GORSE_L,
			"ao_c": crown, "ao_r": 0.9, "mask": mask, "jitter": 0.06, "seed": seed + i * 1.3, "tint": 0.12,
			"clip_y": -0.02})
	# Thorn spikes: dark needles sticking out all round (a spiky, not a round, silhouette).
	for i: int in thorns:
		var b: Array = blobs[i % blobs.size()]
		var t: float = _h(Vector3(i, seed, 4.0))
		var on: Array = _on_blob(b[0] as Vector3, b[1] as float, 0.86, lerpf(-0.2, 1.1, t), i * GOLDEN + seed)
		var p: Vector3 = on[0]
		if p.y < 0.12:
			continue
		var dir: Vector3 = on[1]
		_part(_spindle(p - dir * 0.05, p + dir * (0.12 + t * 0.08), 0.03, 0.3, GORSE_D, GORSE.lightened(0.1)),
			Transform3D.IDENTITY, GORSE, {"mask": mask, "normals": "smooth", "tint": 0.06})
	# Bloom caps: flattened yellow blobs crusting the upper half (bigger ones first), brighter to the top.
	for i: int in blooms:
		var b: Array = blobs[i % blobs.size()]
		var t: float = _h(Vector3(i, seed, 5.0))
		var el: float = lerpf(0.15, 1.35, _h(Vector3(i, seed, 6.0)))
		var on: Array = _on_blob(b[0] as Vector3, b[1] as float, 0.86, el, i * GOLDEN * 1.3 + seed)
		var p: Vector3 = (on[0] as Vector3) - (on[1] as Vector3) * 0.03
		if p.y < 0.2:
			continue
		var rr: float = (0.15 if i < blobs.size() * 2 else 0.1) * (0.85 + t * 0.35) * bloom_k
		var up: Vector3 = on[1]
		var basis := Basis(Quaternion(Vector3.UP, up))
		_part(_dome(rr, 6, false), Transform3D(basis, p), BLOOM_D,
			{"mask": mask, "normals": "crown", "crown": b[0], "crown_k": 0.5, "col2": BLOOM_L if t > 0.5 else BLOOM,
			"grad": "wy", "jitter": rr * 0.18, "seed": seed + 30.0 + i, "lift": 0.3, "a": 1.0, "tint": 0.06})


# --- wind-bent tall grass ----------------------------------------------------------------------

func _build_tall_grass() -> void:
	_begin(0.6)
	# Shared core: 9 tall blades rooted in a tight clump, all combed toward local +X.
	_combed(9, 0, 0.0, 0.11, 0.62, 0.86, 0.45, 0.72, 0, 1.0, TG_OLIVE, TG_STRAW, 0.055)
	# V0: a dense olive-gold tuft (+9 medium blades).
	_combed(9, 9, 0.08, 0.2, 0.46, 0.66, 0.4, 0.62, V0, 2.0, TG_OLIVE, TG_GOLD, 0.052)
	# V1: + 5 blades and three feathery seed plumes on long bent stalks.
	_combed(5, 9, 0.08, 0.17, 0.5, 0.68, 0.42, 0.6, V1, 3.0, TG_OLIVE, TG_STRAW, 0.052)
	for k: int in 3:
		var a: float = 1.3 + k * 2.1
		var base := Vector3(cos(a) * 0.05, -0.02, sin(a) * 0.05)
		var h: float = 0.92 - k * 0.08
		var lean := Vector3(0.36 + k * 0.05, 0.0, (k - 1) * 0.09)
		_part(_bent_blade(base, h, 0.016, lean, PI * 0.5 + k * 0.3, TG_ROOT, TG_STRAW), Transform3D.IDENTITY,
			TG_STRAW, {"mask": V1, "normals": "smooth"})
		var tip: Vector3 = base + Vector3(0.0, maxf(h - lean.length() * 0.3, h * 0.35), 0.0) + lean
		var mid: Vector3 = base + Vector3(0.0, h * 0.5, 0.0) + lean * 0.25
		var dir: Vector3 = (tip - mid).normalized()
		_part(_spindle(tip - dir * 0.02, tip + dir * 0.22, 0.05, 0.35, TG_STRAW, TG_PLUME), Transform3D.IDENTITY,
			TG_PLUME, {"mask": V1, "normals": "smooth", "lift": 0.3, "a": 1.0, "tint": 0.04})
	# V2: + 7 flattened russet / straw blades lying downwind (a tuft the gales have beaten down).
	for i: int in 7:
		var a2: float = (7 + i) * GOLDEN + 0.5
		var t: float = _h(Vector3(i, 4.0, 1.0))
		var p := Vector3(cos(a2) * (0.08 + t * 0.14), -0.02, sin(a2) * (0.08 + t * 0.14))
		var h2: float = 0.3 + t * 0.12
		var lean2 := Vector3(0.42 + t * 0.14, 0.0, (t - 0.5) * 0.3)
		var c1: Color = TG_RUSSET if i % 2 == 0 else TG_GOLD
		_part(_bent_blade(p, h2, 0.06, lean2, PI * 0.5 + (t - 0.5) * 0.6, TG_ROOT.lerp(TG_RUSSET, 0.3), c1),
			Transform3D.IDENTITY, c1, {"mask": V2, "normals": "crown", "crown": Vector3(0.0, -0.25, 0.0),
			"crown_k": 0.5, "tint": 0.06})
	_commit("heath_tall_grass")


## `count` blades on a golden-angle spiral from index `start`, all leaning toward +X (spread +-0.25 rad): inner blades
## tall, outer ones shorter; lean = height x [lean0, lean1] (a strong bend).
func _combed(count: int, start: int, r0: float, r1: float, h0: float, h1: float, lean0: float, lean1: float,
		mask: int, seed: float, mid_col: Color, tip_col: Color, width: float) -> void:
	for i: int in count:
		var a: float = (start + i) * GOLDEN + seed * 0.37
		var t: float = _h(Vector3(i, seed, 1.0))
		var f: float = sqrt((i + 0.5) / count)
		var r: float = lerpf(r0, r1, f)
		var p := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var hh: float = lerpf(h1, h0, clampf(f * 0.8 + (t - 0.5) * 0.4, 0.0, 1.0))
		var la: float = (t - 0.5) * 0.5 + sin(a) * 0.12
		var lean := Vector3(cos(la), 0.0, sin(la)) * hh * lerpf(lean0, lean1, _h(Vector3(i, seed, 2.0)))
		var c0: Color = TG_ROOT.lerp(mid_col, 0.25 + t * 0.3)
		var c1: Color = mid_col.lerp(tip_col, 0.45 + t * 0.55)
		if _h(Vector3(i, seed, 3.0)) > 0.8:
			c1 = c1.lerp(TG_RUSSET, 0.55)
		_part(_bent_blade(p, hh, width * (0.85 + t * 0.35), lean, PI * 0.5 + (t - 0.5) * 0.7, c0, c1),
			Transform3D.IDENTITY, c0, {"mask": mask, "normals": "crown", "crown": Vector3(0.0, -0.25, 0.0),
			"crown_k": 0.5, "tint": 0.06})


# --- lichen stones -----------------------------------------------------------------------------

func _stone(radii: Vector3, pos: Vector3, rot: Vector3, col: Color, mask: int, seed: float, moss: float,
		cuts: int = 5, top: float = 0.7, segs: int = 9, rings: int = 5, lift: float = 0.0) -> void:
	_part(_chunk(radii, cuts, seed, top, segs, rings), _xf(pos, rot), col, {"kind": Kind.STONE, "mask": mask,
		"moss": moss, "seed": seed, "tint": 0.12, "col2": col.lightened(0.08), "grad": "y", "lichen": seed * 1.7,
		"clip_y": -0.03, "lift": lift})


func _slab(size: Vector3, pos: Vector3, rot: Vector3, col: Color, mask: int, seed: float, moss: float) -> void:
	_part(_box(size, 2), _xf(pos, rot), col, {"kind": Kind.STONE, "mask": mask, "moss": moss, "jitter": 0.04,
		"seed": seed, "tint": 0.1, "col2": col.lightened(0.07), "jit_axes": Vector3(1.0, 0.5, 1.0),
		"lichen": seed * 1.3, "clip_y": -0.03})


func _pebble(r: float, pos: Vector3, yaw: float, col: Color, mask: int, seed: float) -> void:
	_stone(Vector3(r * 1.15, r * 0.7, r), pos, Vector3(0.15, yaw, 0.1), col, mask, seed, 0.0, 2, 0.72, 5, 3, 0.12)


func _build_lichen_stones() -> void:
	_begin(0.0)
	# V0: a flat-topped granite boulder (~1.1 m wide, 0.55 m tall) with two stones at its foot.
	_stone(Vector3(0.56, 0.62, 0.46), Vector3(0.0, 0.16, 0.0), Vector3(0.06, 0.3, 0.04), GRANITE, V0, 101.0, 0.2, 5, 0.62)
	_stone(Vector3(0.26, 0.26, 0.24), Vector3(0.58, 0.08, 0.26), Vector3(0.2, 1.3, -0.1), GRANITE_B, V0, 102.0, 0.1)
	_pebble(0.11, Vector3(-0.55, 0.03, 0.36), 0.7, GRANITE_D, V0, 103.0)
	_disc(Vector3(0.1, 0.0, 0.08), 0.95, 0.8, 12, 101.0, V0)
	# V1: a tilted slab outcrop: two stratified plates breaking out of the ground at ~30 deg, pebbles below.
	_slab(Vector3(1.05, 0.24, 0.66), Vector3(-0.05, 0.22, 0.0), Vector3(0.05, 0.25, 0.52), GRANITE_W.darkened(0.12), V1,
		111.0, 0.15)
	_slab(Vector3(0.72, 0.2, 0.5), Vector3(-0.42, 0.2, -0.3), Vector3(-0.08, 0.6, 0.72), GRANITE_W.darkened(0.18), V1,
		112.0, 0.2)
	_pebble(0.1, Vector3(0.5, 0.03, 0.34), 1.1, GRANITE, V1, 113.0)
	_pebble(0.08, Vector3(0.62, 0.02, -0.12), 2.2, GRANITE_D, V1, 114.0)
	_pebble(0.09, Vector3(-0.1, 0.02, 0.48), 0.3, GRANITE_B, V1, 115.0)
	_disc(Vector3(-0.05, 0.0, 0.0), 0.95, 0.75, 12, 111.0, V1)
	# V2: a huddle of three low rounded stones.
	_stone(Vector3(0.38, 0.36, 0.34), Vector3(-0.12, 0.1, 0.0), Vector3(0.1, 0.4, 0.0), GRANITE_B, V2, 121.0, 0.3, 4, 0.78)
	_stone(Vector3(0.3, 0.28, 0.28), Vector3(0.36, 0.06, 0.22), Vector3(-0.1, 2.0, 0.08), GRANITE, V2, 122.0, 0.2, 4, 0.8)
	_stone(Vector3(0.24, 0.2, 0.22), Vector3(0.18, 0.04, -0.36), Vector3(0.0, 3.1, 0.12), GRANITE_W, V2, 123.0, 0.1, 4,
		0.8, 7, 4)
	_pebble(0.09, Vector3(-0.5, 0.02, -0.3), 0.9, GRANITE_D, V2, 124.0)
	_disc(Vector3(0.05, 0.0, 0.0), 0.9, 0.8, 12, 121.0, V2)
	_commit("heath_lichen_stones")
