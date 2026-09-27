extends SceneTree
## Task 12b.V5 (terrain.md 7.2, row 12b.V5): generates the two NEW Marsh meshes. Cattails and reeds are the 12.V7
## riverbank meshes, reused as they are (marsh_set.gd points at them; 0 new kinds for those):
##   biomes/marsh/marsh_puddles.res  a puddle decal: flat pools drawn with the SHARED ford film
##                                   (art/environment/water/water_ford_mat.tres = water.gdshader in `shallow` mode,
##                                   loaded, never re-saved), a soft wet-mud halo (nature_contact_mat.tres) and small
##                                   rim dressing in nature_mat.tres (3 variants through the variant mask: pebbles and a
##                                   rush tuft / a sunken dead reed stalk and a sedge tuft / a mossy stone and a floating
##                                   duckweed mat)
##   biomes/marsh/marsh_rushes.res   soft rush / sedge tussocks on mud hummocks (nature_mat.tres + contact disc,
##                                   3 variants: a big rush tussock / two small tussocks and snapped dry stalks /
##                                   an arching sedge fan beside a half-sunk mossy stone)
## Puddle surface (water.gdshader conventions, see its header):
##   UV.x   metres along the "flow" x FLOW_K (local x): the film's ripples / caustics drift slowly (~0.3 m/s, a breeze
##          on the pool) and their pattern is ~3x finer than on the river (scaled to a pool, roughly isotropic)
##   UV.y   0 at a pool's rim -> 0.5 at its centre (the shader's "bank" is the rim all round: wet dark earth, a
##          broken light lip, deeper green water in the middle)
##   COLOR.r bank weight (1 = wet rim + lip), COLOR.g = 2 x VIRTUAL_R / channel_width (5 m) x a slow wobble round the
##          rim: the shader's "metres to the bank" become VIRTUAL_R x (1 - rho), so every pool gets the same
##          wet band (~the outer quarter) whatever its size, and the band width varies along the rim.
## Nature parts follow nature_painted.gdshader (COLOR.rgb colour, COLOR.a height gradient, UV.x wind / stone moss,
## UV.y local height, UV2 = (variant mask, kind)). Every surface is indexed (welded). 0 lights, no shadows.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/marsh/build_marsh.gd --quit-after 600

const DIR := "res://art/environment/biomes/marsh/"
const NDIR := "res://art/environment/nature_props/"
const WATER_FORD_MAT := "res://art/environment/water/water_ford_mat.tres"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4

## Water film height above the ground (above the contact discs at 0.035 and the halo at 0.028).
const WATER_Y := 0.045
const HALO_Y := 0.028
const FLOW_K := 3.0
const VIRTUAL_R := 2.0
const CHANNEL_WIDTH := 5.0   ## water.gdshader channel_width (water_ford_mat.tres)
## COLOR.r of the pool: scales the wet rim AND the light lip. A full 1.0 draws a thick cream outline (a river bank's
## foam), too loud on a still pool.
const MAIN_BANK := 0.45

# Palette (sRGB). Rushes darker and bluer than the riverbank reeds so the marsh reads as its own patch; dry stalks
# and seed heads are the small warm accents; mud hummocks sit a step lighter than the 12b.V1 mud (0.24, 0.18, 0.11).
const RUSH_D := Color(0.09, 0.20, 0.12)
const RUSH := Color(0.17, 0.31, 0.17)
const RUSH_L := Color(0.33, 0.46, 0.25)
const SEDGE_D := Color(0.22, 0.32, 0.11)
const SEDGE_L := Color(0.62, 0.62, 0.27)
const SEED := Color(0.36, 0.25, 0.14)
const SEED_L := Color(0.52, 0.38, 0.20)
const STRAW := Color(0.60, 0.50, 0.30)
const STRAW_L := Color(0.74, 0.64, 0.40)
const MUD := Color(0.26, 0.20, 0.13)
const MUD_L := Color(0.36, 0.29, 0.19)
const PEB := Color(0.44, 0.42, 0.38)
const PEB_D := Color(0.30, 0.29, 0.27)
const PEB_W := Color(0.52, 0.47, 0.39)
const DUCK := Color(0.36, 0.52, 0.14)
const DUCK_L := Color(0.55, 0.66, 0.22)

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var water_mat: Material
var _conv: float = 1.0

# nature_mat surface (non-indexed triangle soup, welded at commit)
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _w := PackedFloat32Array()     # stone: moss; else explicit wind weight (>= 0) or -1 = automatic
var _uv2 := PackedVector2Array()   # (variant mask, kind)
# contact / halo surface
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
# water film surface
var _wv := PackedVector3Array()
var _wuv := PackedVector2Array()
var _wc := PackedColorArray()
var _report: Array = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_detect_winding()
	mat = load(NDIR + "nature_mat.tres") as ShaderMaterial
	contact_mat = load(NDIR + "nature_contact_mat.tres") as ShaderMaterial
	water_mat = load(WATER_FORD_MAT) as Material
	if mat == null or contact_mat == null or water_mat == null:
		push_error("shared materials missing")
		quit(1)
		return
	_build_puddles()
	_build_rushes()
	for line: String in _report:
		print(line)
	print("MARSH BUILD OK")
	quit()


# --- helpers (same conventions as riverbank/build_riverbank.gd) -----------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _begin() -> void:
	_v = PackedVector3Array()
	_n = PackedVector3Array()
	_c = PackedColorArray()
	_w = PackedFloat32Array()
	_uv2 = PackedVector2Array()
	_cv = PackedVector3Array()
	_cn = PackedVector3Array()
	_cuv = PackedVector2Array()
	_cuv2 = PackedVector2Array()
	_wv = PackedVector3Array()
	_wuv = PackedVector2Array()
	_wc = PackedColorArray()


func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


func _sph(r: float, segs: int = 7, rings: int = 4) -> Array:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


## Up-facing triangle (a, b, c) in the renderer's front-face order.
func _up_tri(a: Vector3, b: Vector3, c: Vector3) -> Array:
	var fn: Vector3 = (b - a).cross(c - a)
	var up: bool = fn.y >= 0.0
	return [a, b, c] if (1.0 if up else -1.0) == _conv else [a, c, b]


## Adds mesh arrays to the nature surface, transformed (options as build_riverbank.gd `_part`):
##   kind, mask, jitter, seed, jit_axes, normals "flat" | "smooth", col2 + grad ("y" | "r"), moss (stone), tint,
##   wind (Vector2 weight at the part's bottom / top), clip_y (drop triangles fully below this y).
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.BARK)
	var mask: int = o.get("mask", 0)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var jit_axes: Vector3 = o.get("jit_axes", Vector3.ONE)
	var mode: String = o.get("normals", "flat")
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var moss: float = o.get("moss", 0.0)
	var tint: float = o.get("tint", 0.08)
	var has_wind: bool = o.has("wind")
	var wind: Vector2 = o.get("wind", Vector2.ZERO)
	var clip_y: float = o.get("clip_y", -INF)
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
	for t: int in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		if tv[a].y < clip_y and tv[b].y < clip_y and tv[c].y < clip_y:
			continue
		var fn: Vector3 = (tv[b] - tv[a]).cross(tv[c] - tv[a])
		if fn.length_squared() < 1e-10:
			continue
		fn = fn.normalized()
		var s: float = 1.0 if fn.dot(tn[a] + tn[b] + tn[c]) >= 0.0 else -1.0
		if s != _conv:
			var tmp: int = b
			b = c
			c = tmp
		fn *= s
		var fk: float = 1.0 + (_h(((tv[a] + tv[b] + tv[c]) / 3.0).snappedf(0.01)) - 0.5) * tint
		for vi: int in [a, b, c]:
			var nn: Vector3 = fn if mode == "flat" else tn[vi]
			var gy: float = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
			var gt: float = gy
			if grad == "r":
				gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
			var cc: Color = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k))
			if kind == Kind.STONE:
				_w.append(moss)
			elif has_wind:
				_w.append(lerpf(wind.x, wind.y, gy))
			else:
				_w.append(-1.0)
			_uv2.append(Vector2(mask, kind))


## A tapered tube along `path` with one radius per point (0 = pointed tip); `flat` < 1 squashes the section along
## `face` (ribbon blades). Smooth normals.
func _tube(path: Array, radii: Array, sides: int, flat: float = 1.0, face: Vector3 = Vector3.ZERO) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var cnt: int = path.size()
	var tangents: Array[Vector3] = []
	for i: int in cnt:
		var t: Vector3
		if i == 0:
			t = (path[1] as Vector3) - (path[0] as Vector3)
		elif i == cnt - 1:
			t = (path[i] as Vector3) - (path[i - 1] as Vector3)
		else:
			t = (path[i + 1] as Vector3) - (path[i - 1] as Vector3)
		tangents.append(t.normalized())
	for i: int in cnt:
		var t: Vector3 = tangents[i]
		var ref: Vector3 = face
		if ref == Vector3.ZERO or absf(ref.normalized().dot(t)) > 0.97:
			ref = Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.BACK
		var thin: Vector3 = (ref - t * ref.dot(t)).normalized()
		var broad: Vector3 = t.cross(thin).normalized()
		var r: float = radii[i]
		for k: int in sides:
			var a: float = TAU * k / sides
			v.append((path[i] as Vector3) + broad * cos(a) * r + thin * sin(a) * r * flat)
			n.append((broad * cos(a) * flat + thin * sin(a)).normalized())
	for i: int in cnt - 1:
		for k: int in sides:
			var a0: int = i * sides + k
			var b0: int = i * sides + (k + 1) % sides
			var c0: int = (i + 1) * sides + k
			var d0: int = (i + 1) * sides + (k + 1) % sides
			idx.append_array([a0, b0, c0, b0, d0, c0])
	return _mk(v, n, idx)


## Soft contact shadow under a prop (contact surface): an irregular disc just above the ground.
func _disc(c: Vector3, rx: float, rz: float, segs: int, seed: float, mask: int = 0) -> void:
	var ring: Array[Vector3] = []
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.3
		ring.append(Vector3(c.x + cos(a) * rx * j, 0.035, c.z + sin(a) * rz * j))
	var centre := Vector3(c.x, 0.035, c.z)
	for i: int in segs:
		var tri: Array = _up_tri(centre, ring[i], ring[(i + 1) % segs])
		for k: int in 3:
			_cv.append(tri[k])
			_cn.append(Vector3.UP)
			_cuv.append(Vector2(0.0 if tri[k] == centre else 1.0, 0.0))
			_cuv2.append(Vector2(mask, 0.0))


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


## The nature surface's arrays with COLOR.a (height gradient), UV.x (wind / moss) and UV.y (local height) baked.
func _nature_arrays(o: Dictionary) -> Array:
	var wind_h: float = o.get("wind_h", 0.0)
	var wind_base: float = o.get("wind_base", 0.05)
	var wind_pow: float = o.get("wind_pow", 1.5)
	var wind_gain: float = o.get("wind_gain", 0.4)
	var grad_min: float = o.get("grad_min", 0.0)
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - miny, 0.01)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = lerpf(grad_min, 1.0, clampf((_v[i].y - miny) / span, 0.0, 1.0))
		_c[i] = cc
		var w: float = _w[i]
		if int(_uv2[i].y) != Kind.STONE and w < 0.0:
			w = 0.0
			if wind_h > 0.0:
				w = pow(clampf((_v[i].y - wind_base) / (wind_h - wind_base), 0.0, 1.0), wind_pow) * wind_gain
		uv[i] = Vector2(w, _v[i].y)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = _uv2
	return _weld(arrays)


func _contact_arrays() -> Array:
	var ca: Array = []
	ca.resize(Mesh.ARRAY_MAX)
	ca[Mesh.ARRAY_VERTEX] = _cv
	ca[Mesh.ARRAY_NORMAL] = _cn
	ca[Mesh.ARRAY_TEX_UV] = _cuv
	ca[Mesh.ARRAY_TEX_UV2] = _cuv2
	return _weld(ca)


func _water_arrays() -> Array:
	var wn := PackedVector3Array()
	wn.resize(_wv.size())
	wn.fill(Vector3.UP)
	var wa: Array = []
	wa.resize(Mesh.ARRAY_MAX)
	wa[Mesh.ARRAY_VERTEX] = _wv
	wa[Mesh.ARRAY_NORMAL] = wn
	wa[Mesh.ARRAY_COLOR] = _wc
	wa[Mesh.ARRAY_TEX_UV] = _wuv
	return _weld(wa)


func _variant_tris(k: int) -> int:
	var n := 0
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		if m <= 0 or ((m >> k) & 1) == 1:
			n += 1
	return n


func _report_mesh(path: String, mesh: ArrayMesh) -> void:
	var parts: Array[String] = []
	for s: int in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		parts.append("s%d %s %d tris / %d verts" % [s, mesh.surface_get_material(s).resource_path.get_file(),
			(arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3, (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()])
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-14s %s | nature tris per variant %d / %d / %d | size %.2f x %.2f x %.2f, y %.2f..%.2f"
		% [path.get_file().get_basename(), ", ".join(parts), _variant_tris(0), _variant_tris(1), _variant_tris(2),
		aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y, aabb.end.y])


# --- puddles -------------------------------------------------------------------------------------------

## Pool outline radius at angle a (irregular, star-shaped round its centre).
func _pool_r(a: float, r0: float, ph: Vector3) -> float:
	# cos(2a): fuller ends, a pinched waist (a bean / peanut along local x); the rest breaks the symmetry.
	return r0 * (1.0 + 0.12 * cos(2.0 * a) + 0.06 * sin(2.0 * a + ph.x) + 0.09 * sin(3.0 * a + ph.y)
		+ 0.045 * sin(5.0 * a + ph.z))


## One pool: water film (centre + 2 rings x `segs`) at WATER_Y and a wet halo annulus round it at HALO_Y.
## `aspect` stretches it along local x / z before `rot`. `bank` = COLOR.r (wet rim + lip), `vr` = virtual radius
## (metres the shader thinks it is from the rim to the centre; smaller = a wetter, muddier pool). `halo` = metres the
## wet mud reaches past the rim.
func _pool(c: Vector3, r0: float, aspect: Vector2, rot: float, seed: float, segs: int = 18, bank: float = 1.0,
		vr: float = VIRTUAL_R, halo: float = 0.3) -> void:
	var ph := Vector3(_h(Vector3(seed, 1, 0)), _h(Vector3(seed, 2, 0)), _h(Vector3(seed, 3, 0))) * TAU
	var ph_g: float = _h(Vector3(seed, 4, 0)) * TAU
	var rb := Basis(Vector3.UP, rot)
	var rings: Array[float] = [0.0, 0.55, 1.0]
	# grid[ring][seg] -> [position, uv, colour]
	var grid: Array = []
	for ri: int in rings.size():
		var row: Array = []
		var rho: float = rings[ri]
		for si: int in segs:
			var a: float = si * TAU / segs
			var rr: float = _pool_r(a, r0, ph)
			var local := Vector3(cos(a) * aspect.x * rr * rho, 0.0, sin(a) * aspect.y * rr * rho)
			var p: Vector3 = c + rb * local + Vector3(0, WATER_Y, 0)
			var g: float = clampf(2.0 * vr / CHANNEL_WIDTH * (0.82 + 0.22 * sin(2.0 * a + ph_g)), 0.05, 1.0)
			var t: float = 0.5 * (1.0 - rho)
			row.append([p, Vector2(p.x * FLOW_K, t), Color(bank, g, 0.0, 1.0)])
			if ri == 0:
				break   # one centre vertex
		grid.append(row)
	for ri: int in range(1, rings.size()):
		for si: int in segs:
			var s2: int = (si + 1) % segs
			var o0: Array = grid[ri][si]
			var o1: Array = grid[ri][s2]
			if ri == 1:
				var cc: Array = grid[0][0]
				_water_tri(cc, o0, o1)
			else:
				var i0: Array = grid[ri - 1][si]
				var i1: Array = grid[ri - 1][s2]
				_water_tri(i0, o0, o1)
				_water_tri(i0, o1, i1)
	# Wet halo: an annulus from just inside the rim (hidden under the film) out to rim + halo.
	for si: int in segs:
		var a0: float = si * TAU / segs
		var a1: float = (si + 1) * TAU / segs
		var pts: Array = []
		for a: float in [a0, a1]:
			var rr: float = _pool_r(a, r0, ph)
			var dir := Vector3(cos(a) * aspect.x, 0.0, sin(a) * aspect.y)
			var inner: Vector3 = c + rb * (dir * rr * 0.9) + Vector3(0, HALO_Y, 0)
			var reach: float = halo * (0.75 + 0.5 * _h(Vector3(seed, a * 3.0, 5.0)))
			var outer: Vector3 = c + rb * (dir * rr + dir.normalized() * reach) + Vector3(0, HALO_Y, 0)
			pts.append([inner, outer])
		# UV.x 0 on the inner ring (full wet darkening at the rim) -> 1 on the outer one (fades to nothing).
		_halo_tri([pts[0][0], 0.0], [pts[0][1], 1.0], [pts[1][1], 1.0])
		_halo_tri([pts[0][0], 0.0], [pts[1][1], 1.0], [pts[1][0], 0.0])


func _water_tri(a: Array, b: Array, c: Array) -> void:
	for src: Array in _up_order(a, b, c):
		_wv.append(src[0])
		_wuv.append(src[1])
		_wc.append(src[2])


## [point, uv.x] triples of the halo (contact surface, always drawn: mask 0).
func _halo_tri(a: Array, b: Array, c: Array) -> void:
	for src: Array in _up_order(a, b, c):
		_cv.append(src[0])
		_cn.append(Vector3.UP)
		_cuv.append(Vector2(float(src[1]), 0.0))
		_cuv2.append(Vector2(0, 0))


## Vertex records whose element 0 is the position, in up-facing front-face order.
func _up_order(a: Array, b: Array, c: Array) -> Array:
	var fn: Vector3 = ((b[0] as Vector3) - (a[0] as Vector3)).cross((c[0] as Vector3) - (a[0] as Vector3))
	var up: bool = fn.y >= 0.0
	return [a, b, c] if (1.0 if up else -1.0) == _conv else [a, c, b]


## A small half-sunk pebble / stone (nature STONE kind; buried triangles dropped).
func _stone(c: Vector3, radii: Vector3, yaw: float, col: Color, mask: int, seed: float, moss: float = 0.0,
		segs: int = 6, rings: int = 3) -> void:
	_part(_sph(1.0, segs, rings), _xf(c, Vector3(0.1 * sin(seed), yaw, 0.08 * cos(seed)), radii), col,
		{"kind": Kind.STONE, "mask": mask, "normals": "smooth", "moss": moss, "jitter": radii.y * 0.12,
		"jit_axes": Vector3(1.0, 0.6, 1.0), "seed": seed, "tint": 0.06, "col2": col.lightened(0.1), "clip_y": -0.02})


## One blade / spike: a 3-sided ribbon from `base` (rooted 0.1 m below) rising `h`, bowing `bend` toward `out`.
func _blade(base: Vector3, out: Vector3, h: float, width: float, bend: float, flat: float, mask: int, seed: float,
		col: Color, col2: Color) -> Vector3:
	var o: Vector3 = Vector3(out.x, 0.0, out.z).normalized()
	var p0: Vector3 = base + Vector3(0, -0.1, 0)
	var p1: Vector3 = base + Vector3(0, h * 0.55, 0) + o * bend * 0.3
	var p2: Vector3 = base + Vector3(0, h, 0) + o * bend
	_part(_tube([p0, p1, p2], [width, width * 0.8, 0.0], 3, flat, o), Transform3D.IDENTITY, col,
		{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": col2, "grad": "y", "seed": seed,
		"jitter": 0.003, "tint": 0.12})
	return p2


## A tuft of `count` blades round `c` (phyllotaxis), heights hmin..hmax, splaying outward.
func _tuft(c: Vector3, count: int, hmin: float, hmax: float, spread: float, lean: float, width: float, flat: float,
		mask: int, seed: float, col: Color, col2: Color, dry_every: int = 0) -> Array[Vector3]:
	var tips: Array[Vector3] = []
	for i: int in count:
		var a: float = i * 2.39996 + seed
		var r: float = spread * sqrt((i + 0.5) / count)
		var base: Vector3 = c + Vector3(cos(a) * r, 0.0, sin(a) * r)
		var out := Vector3(cos(a), 0.0, sin(a))
		var h: float = lerpf(hmin, hmax, _h(Vector3(i, seed, 1.0)))
		var w: float = width * (0.85 + 0.3 * _h(Vector3(i, seed, 2.0)))
		var bend: float = lean * (0.4 + 0.9 * _h(Vector3(i, seed, 3.0))) + r * 0.6
		var dry: bool = dry_every > 0 and i % dry_every == dry_every - 1
		tips.append(_blade(base, out, h, w, bend, flat, mask, seed + i, STRAW.darkened(0.15) if dry else col,
			STRAW_L if dry else col2))
	return tips


## A flat floating duckweed / algae mat (IVY kind, a slow bob in the wind) just above the film.
func _mat_patch(c: Vector3, r: float, mask: int, seed: float) -> void:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var segs := 9
	v.append(Vector3(0, WATER_Y + 0.012, 0))
	n.append(Vector3.UP)
	for i: int in segs:
		var a: float = i * TAU / segs
		var rr: float = r * (0.7 + 0.5 * _h(Vector3(seed, i, 3.0)))
		v.append(Vector3(cos(a) * rr, WATER_Y + 0.01, sin(a) * rr * 0.8))
		n.append(Vector3.UP)
	for i: int in segs:
		idx.append_array([0, 1 + i, 1 + (i + 1) % segs])
	_part(_mk(v, n, idx), _xf(c), DUCK, {"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": DUCK_L,
		"grad": "r", "seed": seed, "tint": 0.16, "wind": Vector2(0.06, 0.06)})


func _build_puddles() -> void:
	_begin()
	# Water: one bean-shaped pool (~1.8 x 1.1 m, a pinched waist), within 1.0 m of the origin (so a scatter `gap` of
	# 2.4 m keeps two puddles' films from ever overlapping at the max scale 1.2). Small satellite pools were tried:
	# with their wet halo they read as grey pebbles from the game camera, so the variety is in the outline and rim.
	var pools: Array = [
		# centre, r0, aspect, rot, seed, segs, bank, virtual r, halo
		[Vector3(0.0, 0, 0.0), 0.56, Vector2(1.42, 0.92), 0.25, 3.0, 22, MAIN_BANK, VIRTUAL_R, 0.34],
	]
	for pl: Array in pools:
		_pool(pl[0], pl[1], pl[2], pl[3], pl[4], pl[5], pl[6], pl[7], pl[8])
	# Rim dressing (nature_mat, one set per variant). Rim points of the main pool at a few angles:
	# V0: pebbles along the north rim, a rush tuft at the south-west rim.
	for i: int in 4:
		var a: float = -1.9 + i * 0.32
		var p: Vector3 = _rim_point(pools[0], a, 0.02)
		var rr: float = 0.05 + 0.035 * _h(Vector3(i, 9, 1))
		_stone(p + Vector3(0, rr * 0.25, 0), Vector3(rr * 1.25, rr * 0.7, rr), a, [PEB, PEB_D, PEB_W, PEB][i], V0, 20.0 + i,
			0.0, 5, 2)
	var t0: Vector3 = _rim_point(pools[0], 2.5, 0.1)
	_tuft(t0, 9, 0.34, 0.52, 0.09, 0.08, 0.016, 1.0, V0, 31.0, RUSH_D, RUSH_L, 4)
	_disc(t0, 0.22, 0.2, 7, 31.0, V0)
	# V1: a dead reed stalk fallen across the east end of the pool (half sunk), a sedge tuft on the north-east rim.
	var s_a: Vector3 = _rim_point(pools[0], -0.35, 0.28) + Vector3(0, 0.06, 0)
	var s_b: Vector3 = _rim_point(pools[0], 0.9, -0.35) + Vector3(0, WATER_Y - 0.005, 0)
	var s_m: Vector3 = s_a.lerp(s_b, 0.5) + Vector3(0, -0.01, 0)
	_part(_tube([s_a, s_m, s_b], [0.022, 0.019, 0.014], 4), Transform3D.IDENTITY, STRAW.darkened(0.1),
		{"kind": Kind.BARK, "mask": V1, "normals": "smooth", "col2": STRAW_L, "grad": "r", "seed": 40.0, "tint": 0.1})
	var t1: Vector3 = _rim_point(pools[0], -0.75, 0.12)
	_tuft(t1, 8, 0.3, 0.46, 0.08, 0.2, 0.024, 0.4, V1, 41.0, SEDGE_D, SEDGE_L)
	_disc(t1, 0.22, 0.2, 7, 41.0, V1)
	_stone(_rim_point(pools[0], 2.9, 0.0) + Vector3(0, 0.012, 0), Vector3(0.07, 0.04, 0.06), 0.4, PEB_D, V1, 44.0,
		0.0, 5, 2)
	# V2: a flat mossy stone on the west rim, a floating duckweed mat against it, a low tuft by the satellite.
	var st: Vector3 = _rim_point(pools[0], 3.3, 0.05)
	_stone(st + Vector3(0, 0.02, 0), Vector3(0.2, 0.08, 0.15), 0.7, PEB, V2, 50.0, 0.8, 7, 3)
	_disc(st, 0.3, 0.24, 8, 50.0, V2)
	_mat_patch(_rim_point(pools[0], 3.0, -0.22), 0.16, V2, 51.0)
	_mat_patch(_rim_point(pools[0], 3.7, -0.3), 0.1, V2, 52.0)
	var t2: Vector3 = _rim_point(pools[0], 1.3, 0.1)
	_tuft(t2, 7, 0.24, 0.4, 0.07, 0.1, 0.015, 1.0, V2, 53.0, RUSH_D, RUSH_L, 3)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _water_arrays())
	mesh.surface_set_material(0, water_mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _contact_arrays())
	mesh.surface_set_material(1, contact_mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,
		_nature_arrays({"wind_h": 0.55, "wind_base": 0.02, "wind_pow": 1.4, "wind_gain": 0.35, "grad_min": 0.25}))
	mesh.surface_set_material(2, mat)
	_save(mesh, DIR + "marsh_puddles.res")
	_report_mesh(DIR + "marsh_puddles.res", mesh)


## A point on a pool's rim at local angle a (before the pool's rotation), pushed `out` metres outward (negative =
## into the water). y = 0.
func _rim_point(pl: Array, a: float, out: float) -> Vector3:
	var c: Vector3 = pl[0]
	var r0: float = pl[1]
	var aspect: Vector2 = pl[2]
	var rb := Basis(Vector3.UP, float(pl[3]))
	var seed: float = pl[4]
	var ph := Vector3(_h(Vector3(seed, 1, 0)), _h(Vector3(seed, 2, 0)), _h(Vector3(seed, 3, 0))) * TAU
	var rr: float = _pool_r(a, r0, ph)
	var dir := Vector3(cos(a) * aspect.x, 0.0, sin(a) * aspect.y)
	return c + rb * (dir * rr + dir.normalized() * out)


# --- rushes ---------------------------------------------------------------------------------------------

## A low mud hummock (stone kind: moss on top, dark foot), half sunk.
func _hummock(c: Vector3, r: float, h: float, mask: int, seed: float, moss: float = 0.55) -> void:
	_part(_sph(1.0, 8, 4), _xf(c, Vector3(0.0, seed, 0.0), Vector3(r, h, r * 0.9)), MUD, {"kind": Kind.STONE,
		"mask": mask, "normals": "smooth", "moss": moss, "jitter": r * 0.1, "jit_axes": Vector3(1.0, 0.5, 1.0),
		"seed": seed, "tint": 0.08, "col2": MUD_L, "clip_y": -0.02})


## Rush seed clusters: small brown knots on the side of a few spikes, below the tip.
func _seed_heads(tips: Array[Vector3], c: Vector3, every: int, mask: int, seed: float) -> void:
	for i: int in tips.size():
		if i % every != 0:
			continue
		var tip: Vector3 = tips[i]
		var p: Vector3 = c.lerp(tip, 0.8) + Vector3(0.025, 0, 0.02)
		_part(_sph(0.03, 4, 2), _xf(p, Vector3(0, i, 0), Vector3(1.0, 1.5, 1.0)), SEED,
			{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": SEED_L, "seed": seed + i, "tint": 0.1})


## A snapped dry stalk: rises, then the top half folds over.
func _snapped(base: Vector3, a: float, h: float, mask: int, seed: float) -> void:
	var o := Vector3(cos(a), 0.0, sin(a))
	var p0: Vector3 = base + Vector3(0, -0.08, 0)
	var p1: Vector3 = base + Vector3(0, h, 0) + o * 0.04
	var p2: Vector3 = p1 + o * h * 0.55 + Vector3(0, -h * 0.35, 0)
	_part(_tube([p0, p1, p2], [0.016, 0.013, 0.008], 3), Transform3D.IDENTITY, STRAW.darkened(0.05),
		{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": STRAW_L, "grad": "y", "seed": seed, "tint": 0.1})


func _build_rushes() -> void:
	_begin()
	# V0: a big soft-rush tussock: dark blue-green spikes splaying from a mossy mud hummock, brown seed knots.
	_hummock(Vector3(0, 0.0, 0), 0.27, 0.12, V0, 1.0)
	var tips0: Array[Vector3] = _tuft(Vector3(0, 0.07, 0), 24, 0.5, 0.82, 0.2, 0.1, 0.017, 1.0, V0, 2.0, RUSH_D,
		RUSH_L, 7)
	_seed_heads(tips0, Vector3(0, 0.07, 0), 4, V0, 3.0)
	_disc(Vector3.ZERO, 0.55, 0.5, 9, 1.0, V0)
	# V1: two small tussocks and a few snapped dry stalks between them.
	_hummock(Vector3(-0.22, 0.0, 0.05), 0.18, 0.08, V1, 11.0)
	_hummock(Vector3(0.28, 0.0, -0.1), 0.15, 0.07, V1, 12.0)
	var tips1: Array[Vector3] = _tuft(Vector3(-0.22, 0.05, 0.05), 14, 0.36, 0.6, 0.13, 0.08, 0.016, 1.0, V1, 13.0,
		RUSH_D, RUSH_L, 5)
	_seed_heads(tips1, Vector3(-0.22, 0.05, 0.05), 5, V1, 14.0)
	_tuft(Vector3(0.28, 0.04, -0.1), 10, 0.3, 0.5, 0.1, 0.1, 0.015, 1.0, V1, 15.0, RUSH, RUSH_L, 4)
	for i: int in 3:
		_snapped(Vector3(0.02 + i * 0.07, 0.0, 0.16 - i * 0.12), 0.6 + i * 1.9, 0.26 + 0.08 * i, V1, 16.0 + i)
	_disc(Vector3(0.03, 0, -0.02), 0.62, 0.42, 9, 11.0, V1)
	# V2: an arching sedge fan (wide yellow-green ribbons) beside a half-sunk mossy stone.
	_hummock(Vector3(-0.1, 0.0, 0.0), 0.2, 0.08, V2, 21.0, 0.7)
	_tuft(Vector3(-0.1, 0.04, 0.0), 13, 0.42, 0.66, 0.12, 0.3, 0.03, 0.35, V2, 22.0, SEDGE_D, SEDGE_L, 6)
	_stone(Vector3(0.34, 0.0, 0.12), Vector3(0.18, 0.15, 0.15), 0.9, PEB_D.lerp(PEB, 0.5), V2, 23.0, 0.5, 9, 5)
	_disc(Vector3(0.08, 0, 0.05), 0.6, 0.45, 9, 21.0, V2)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,
		_nature_arrays({"wind_h": 0.85, "wind_base": 0.04, "wind_pow": 1.5, "wind_gain": 0.4}))
	mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _contact_arrays())
	mesh.surface_set_material(1, contact_mat)
	_save(mesh, DIR + "marsh_rushes.res")
	_report_mesh(DIR + "marsh_rushes.res", mesh)
