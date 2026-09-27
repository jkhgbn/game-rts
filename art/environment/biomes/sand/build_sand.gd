extends SceneTree
## Task 12b.V3 (terrain.md 7.2 "Sand set": dry tussock grass, half-buried pale stones / old bones, <= 400 instances):
## generates the two sand scatter meshes with the SHARED painted nature material
## (art/environment/nature_props/nature_mat.tres + nature_contact_mat.tres, loaded, never re-saved). One mesh per decor
## kind, 3 shape variants in each through the variant mask (UV2.x): nature_painted.gdshader picks the variant from a
## hash of the instance position, so one MultiMesh shows 3 shapes.
##   sand_tussock.res  dry tussock grass ~1 m wide: a dark cushion of old leaf bases, sage-olive blades with straw /
##                     bleached tips, a few rust blades (V0 round fountain tussock, V1 stiff marram tuft with 5 seed
##                     spikes, V2 wind-beaten low tussock lying flat on the sand)
##   sand_bones.res    half-buried pale limestone and old bones (V0 a wind-worn banded limestone outcrop + flat stones,
##                     V1 the rib cage of a great beast arching out of the sand, V2 a horned skull, a thigh bone and a
##                     pale stone) + the soft contact disc (surface 1)
## Vertex data follows nature_painted.gdshader: COLOR.rgb colour, COLOR.a height gradient (0 at the ground -> 1 at the
## top of the part's OWN variant, so the low skull is not darker than the tall rib cage), UV.x wind weight (grass,
## clamp(y * 0.6, 0, 0.45)) or the stone moss amount (0: a desert has no moss), UV.y local height + a lift on the stone
## tops (the shader's dark contact band stays at the sand line), UV2 = (variant mask, kind). Every mesh is indexed
## (welded). No lights, no textures, no runtime materials.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/sand/build_sand.gd --quit-after 600

const DIR := "res://art/environment/biomes/sand/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45
const GOLDEN := 2.39996

# Palette (sRGB). The sand is light warm ochre (terrain.md 7.1: light (0.86, 0.74, 0.50), dark (0.66, 0.52, 0.32)):
# the tussocks carry a cool sage-olive body (a hue step away from the sand) with straw tips and a dark root, the stones
# are a cool pale limestone with rose bands, the bones ivory with brown sockets and dark ringed horns. Values stay
# below ~0.72: the stone shader lifts sky-facing faces by up to 35 %, so paler bases blow out to white.
const TU_ROOT := Color(0.20, 0.21, 0.11)
const TU_OLIVE := Color(0.38, 0.40, 0.19)
const TU_SAGE := Color(0.54, 0.56, 0.36)
const TU_STRAW := Color(0.84, 0.72, 0.42)
const TU_BLEACH := Color(0.93, 0.87, 0.66)
const TU_RUST := Color(0.66, 0.40, 0.20)
const TU_SEED := Color(0.55, 0.40, 0.24)
const TU_THATCH_D := Color(0.28, 0.24, 0.14)
const TU_THATCH := Color(0.50, 0.43, 0.27)
const LIME := Color(0.58, 0.57, 0.55)
const LIME_W := Color(0.63, 0.60, 0.54)
const LIME_ROSE := Color(0.62, 0.52, 0.46)
const LIME_D := Color(0.42, 0.40, 0.38)
const BONE := Color(0.72, 0.68, 0.57)
const BONE_D := Color(0.52, 0.47, 0.37)
const BONE_OLD := Color(0.62, 0.56, 0.44)
const SOCKET := Color(0.27, 0.21, 0.17)
const HORN_D := Color(0.24, 0.20, 0.17)
const HORN := Color(0.42, 0.35, 0.27)
const HORN_TIP := Color(0.66, 0.60, 0.50)

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
	_build_tussock()
	_build_bones()
	for line: String in _report:
		print(line)
	print("SAND BUILD OK")
	quit()


# --- helpers (the heath builder's recipe) ---------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


## Smooth 3D value noise 0..1 (wobbles the limestone bands).
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


func _sph(r: float, segs: int = 7, rings: int = 4) -> Array:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


## Adds mesh arrays, transformed. Options (all optional):
##   kind (Kind, default IVY = foliage without autumn), mask (variant bits, 0 = always), jitter (m), seed, jit_axes,
##   normals: "flat" | "smooth" | "crown" (smooth, bent away from `crown`, squashed by crown_s, weight crown_k),
##   col2 + grad ("y" part height | "wy" mesh height | "r" distance from the part axis), tint (random value variation,
##   default 0.08), lift (metres added to UV.y: keeps the contact band off stone tops), a (fixed COLOR.a), wind
##   (weight per metre, default the mesh's), moss (stone: UV.x = this moss amount instead of a wind weight), clip_y
##   (drop triangles entirely below this height: the buried half of a stone or bone), strata (Color: limestone bands
##   across the faces, period `strata_p` metres, wobbled by value noise).
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
	var tint: float = o.get("tint", 0.08)
	var lift: float = o.get("lift", 0.0)
	var alpha: float = o.get("a", -1.0)
	var wk: float = o.get("wind", _wind_k)
	var moss: float = o.get("moss", -1.0)
	var clip_y: float = o.get("clip_y", -INF)
	var strata: bool = o.has("strata")
	var strata_col: Color = o.get("strata", Color.WHITE)
	var strata_p: float = o.get("strata_p", 0.12)
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
		# Limestone bands: horizontal strata, a few facets tall, wobbled so they read as rock, not stripes.
		var band := 0.0
		if strata:
			var wob: float = _vnoise(centre * 3.0 + Vector3(seed, 0.0, seed * 0.3)) - 0.5
			var ph: float = fposmod(centre.y / strata_p + wob * 0.9 + seed * 0.13, 2.0)
			band = 0.6 if ph < 0.8 else 0.0
		for vi: int in [a, b, c]:
			var nn: Vector3 = fn
			if mode == "smooth":
				nn = tn[vi]
			elif mode == "crown":
				var cd: Vector3 = ((tv[vi] - crown) / crown_s).normalized()
				nn = tn[vi].lerp(cd, crown_k).normalized()
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
			if band > 0.0:
				cc = cc.lerp(strata_col, band)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
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


## Bakes the height gradient (COLOR.a, unless a part fixed it) PER VARIANT: 0 at the sand, 1 at the top of the
## vertex's own variant (a shared part uses the lowest of the variants it is drawn in), welds, saves DIR/<name>.res
## (surface 0: nature_mat, surface 1: contact disc if any) and reports the triangles per variant.
func _commit(name: String) -> ArrayMesh:
	var top := [0.01, 0.01, 0.01]
	for i: int in _v.size():
		var m: int = int(_uv2[i].x)
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				top[k] = maxf(top[k], _v[i].y)
	for i: int in _v.size():
		var cc: Color = _c[i]
		if cc.a < 0.0:
			var m2: int = int(_uv2[i].x)
			var span: float = INF
			for k: int in 3:
				if m2 == 0 or ((m2 >> k) & 1) == 1:
					span = minf(span, float(top[k]))
			cc.a = clampf(_v[i].y / span, 0.0, 1.0)
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
		var m3: int = int(_uv2[t].x)
		for k: int in 3:
			if m3 == 0 or ((m3 >> k) & 1) == 1:
				per[k] += 1
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-14s %4d tris, %4d verts (variants %d / %d / %d, tops %.2f / %.2f / %.2f), contact %d, aabb %s .. %s"
		% [name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		top[0], top[1], top[2], _cv.size() / 3, aabb.position.snappedf(0.01), aabb.end.snappedf(0.01)])
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

## A grass blade: a flattened 3-sided spike in 2 segments, bent by `lean` (the middle ring carries a quarter of it, so
## the blade stands up from the root and arches over at the top; the tip drops by `droop` of the lean length).
func _bent_blade(base: Vector3, h: float, w: float, lean: Vector3, face: float, c0: Color, c1: Color,
		droop: float = 0.3) -> Array:
	var side := Vector3(cos(face), 0.0, sin(face))
	var out := Vector3(-side.z, 0.0, side.x)
	var tip: Vector3 = base + Vector3(0.0, maxf(h - lean.length() * droop, h * 0.3), 0.0) + lean
	var mid: Vector3 = base + Vector3(0.0, h * 0.55, 0.0) + lean * 0.25
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


## A 3-sided double pyramid from `a` to `b` (seed spikes), radius `r` at `bulge` (0-1).
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


## A bent tube through `pts` (ribs, horns, bones): `sides`-gon rings of radius `radii[i]`, flattened across the bend
## by `flat` (< 1 = a flat rib), coloured `cols[i]` per ring, closed by a tip point when `tip`. The ring frames are
## carried along the curve (parallel transport), so the tube never twists.
func _tube(pts: Array, radii: Array, cols: Array, sides: int, flat: float = 1.0, tip: bool = true,
		tip_len: float = 1.2) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var idx := PackedInt32Array()
	var side := Vector3.ZERO
	var count: int = pts.size()
	for i: int in count:
		var p: Vector3 = pts[i]
		var tng: Vector3
		if i == 0:
			tng = ((pts[1] as Vector3) - p).normalized()
		elif i == count - 1:
			tng = (p - (pts[i - 1] as Vector3)).normalized()
		else:
			tng = ((pts[i + 1] as Vector3) - (pts[i - 1] as Vector3)).normalized()
		if i == 0:
			side = tng.cross(Vector3.UP if absf(tng.y) < 0.9 else Vector3.RIGHT).normalized()
		else:
			side = (side - tng * side.dot(tng)).normalized()
		var bin: Vector3 = tng.cross(side).normalized()
		var r: float = radii[i]
		for k: int in sides:
			var a: float = k * TAU / sides
			v.append(p + (side * cos(a) * flat + bin * sin(a)) * r)
			n.append((side * cos(a) / flat + bin * sin(a)).normalized())
			c.append(cols[i] as Color)
	for i: int in count - 1:
		for k: int in sides:
			var k2: int = (k + 1) % sides
			var a0: int = i * sides + k
			var b0: int = i * sides + k2
			var a1: int = (i + 1) * sides + k
			var b1: int = (i + 1) * sides + k2
			idx.append_array([a0, b0, a1, b0, b1, a1])
	if tip:
		var last: int = count - 1
		var td: Vector3 = ((pts[last] as Vector3) - (pts[last - 1] as Vector3)).normalized()
		var t: int = v.size()
		v.append((pts[last] as Vector3) + td * float(radii[last]) * tip_len)
		n.append(td)
		c.append(cols[last] as Color)
		for k: int in sides:
			idx.append_array([last * sides + k, last * sides + (k + 1) % sides, t])
	return _mk(v, n, idx, c)


# --- dry tussock grass ---------------------------------------------------------------------------

func _build_tussock() -> void:
	_begin(0.6)
	# Shared: a low dark cushion of old leaf bases (gives the clump its mass and dark foot on the light sand) and a
	# heart of 14 thin stiff blades splaying a little.
	_part(_sph(0.2, 8, 3), _xf(Vector3(0.0, -0.01, 0.0), Vector3.ZERO, Vector3(1.0, 0.3, 1.0)), TU_THATCH_D,
		{"normals": "crown", "crown": Vector3(0.0, -0.08, 0.0), "crown_k": 0.7, "crown_s": Vector3(1.0, 0.35, 1.0),
		"col2": TU_THATCH, "jitter": 0.025, "seed": 1.0, "tint": 0.12, "clip_y": -0.02, "lift": 0.1})
	_fountain(14, 0, 0.0, 0.1, 0.46, 0.64, 0.12, 0.3, 0, 1.0, TU_OLIVE, TU_SAGE.lerp(TU_STRAW, 0.5), 0.026, 0.3)
	# V0: a round fountain tussock ~0.9 m: 22 blades rising, then arching out all round and drooping; sage-straw
	# bodies, straw / bleached tips.
	_fountain(22, 14, 0.07, 0.18, 0.42, 0.58, 0.36, 0.62, V0, 2.0, TU_SAGE.lerp(TU_STRAW, 0.3), TU_BLEACH, 0.028, 0.5)
	# V1: a stiff marram tuft: 10 near-upright spears + 5 seed spikes on long stalks (the tall accent of the set).
	_fountain(10, 14, 0.06, 0.16, 0.52, 0.7, 0.12, 0.26, V1, 3.0, TU_SAGE, TU_BLEACH, 0.026, 0.2)
	for k: int in 5:
		var a: float = 0.7 + k * GOLDEN * 1.3
		var base := Vector3(cos(a) * 0.06, -0.02, sin(a) * 0.06)
		var h: float = 0.8 - k * 0.05
		var lean := Vector3(cos(a), 0.0, sin(a)) * (0.1 + k * 0.03)
		_part(_bent_blade(base, h, 0.018, lean, a + PI * 0.5, TU_OLIVE, TU_STRAW, 0.2), Transform3D.IDENTITY, TU_STRAW,
			{"mask": V1, "normals": "smooth"})
		var tip: Vector3 = base + Vector3(0.0, maxf(h - lean.length() * 0.2, h * 0.3), 0.0) + lean
		var mid: Vector3 = base + Vector3(0.0, h * 0.55, 0.0) + lean * 0.25
		var dir: Vector3 = (tip - mid).normalized()
		_part(_spindle(tip - dir * 0.04, tip + dir * 0.26, 0.05, 0.4, TU_SEED, TU_BLEACH), Transform3D.IDENTITY,
			TU_SEED, {"mask": V1, "normals": "smooth", "a": 1.0, "tint": 0.05})
	# V2: a wind-beaten tussock: 22 short blades lying out over the sand in a straw skirt (bleached, straw, a few
	# rust), the heart pokes up.
	for i: int in 22:
		var a2: float = (40 + i) * GOLDEN + 0.4
		var t: float = _h(Vector3(i, 4.0, 1.0))
		var p := Vector3(cos(a2) * (0.07 + t * 0.09), -0.02, sin(a2) * (0.07 + t * 0.09))
		var h2: float = 0.16 + t * 0.1
		var lean2 := Vector3(cos(a2 + (t - 0.5) * 0.5), 0.0, sin(a2 + (t - 0.5) * 0.5)) * (0.2 + t * 0.14)
		var c1: Color = TU_RUST.lerp(TU_STRAW, 0.3) if i % 4 == 0 else (TU_BLEACH if i % 4 == 1 else TU_STRAW)
		_part(_bent_blade(p, h2, 0.024, lean2, a2 + PI * 0.5, TU_THATCH_D.lerp(TU_OLIVE, 0.4), c1, 0.55),
			Transform3D.IDENTITY, c1, {"mask": V2, "normals": "crown", "crown": Vector3(0.0, -0.3, 0.0),
			"crown_k": 0.5, "tint": 0.06})
	_commit("sand_tussock")


## `count` blades on a golden-angle spiral from index `start`, leaning OUTWARD (radially, +-0.3 rad): inner blades
## tall and stiffer, outer ones shorter and more bent; lean = height x [lean0, lean1]; every 6th blade turns rust.
func _fountain(count: int, start: int, r0: float, r1: float, h0: float, h1: float, lean0: float, lean1: float,
		mask: int, seed: float, mid_col: Color, tip_col: Color, width: float, droop: float) -> void:
	for i: int in count:
		var a: float = (start + i) * GOLDEN + seed * 0.37
		var t: float = _h(Vector3(i, seed, 1.0))
		var f: float = sqrt((i + 0.5) / count)
		var r: float = lerpf(r0, r1, f)
		var p := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var hh: float = lerpf(h1, h0, clampf(f * 0.8 + (t - 0.5) * 0.4, 0.0, 1.0))
		var la: float = a + (t - 0.5) * 0.6
		var lean := Vector3(cos(la), 0.0, sin(la)) * hh * lerpf(lean0, lean1, clampf(f + (t - 0.5) * 0.3, 0.0, 1.0))
		var c0: Color = TU_ROOT.lerp(mid_col, 0.3 + t * 0.3)
		var c1: Color = mid_col.lerp(tip_col, 0.5 + t * 0.5)
		if (start + i) % 6 == 5:
			c1 = c1.lerp(TU_RUST, 0.7)
		_part(_bent_blade(p, hh, width * (0.85 + t * 0.35), lean, la + PI * 0.5, c0, c1, droop),
			Transform3D.IDENTITY, c0, {"mask": mask, "normals": "crown", "crown": Vector3(0.0, -0.25, 0.0),
			"crown_k": 0.5, "tint": 0.06})


# --- half-buried pale stones / old bones ---------------------------------------------------------

## A half-buried limestone block: the chunk's centre sits low (`pos.y` < 0) so only its worn top shows; banded.
func _lime(radii: Vector3, pos: Vector3, rot: Vector3, col: Color, mask: int, seed: float, cuts: int = 4,
		top: float = 0.62, segs: int = 9, rings: int = 5) -> void:
	_part(_chunk(radii, cuts, seed, top, segs, rings), _xf(pos, rot), col, {"kind": Kind.STONE, "mask": mask,
		"moss": 0.0, "seed": seed, "tint": 0.1, "col2": col.lightened(0.1), "grad": "y", "strata": LIME_ROSE,
		"strata_p": 0.11, "clip_y": -0.04, "lift": 0.1})


## A bone part (smooth, ivory, half-buried, no bands).
func _bone(arr: Array, xf: Transform3D, col: Color, mask: int, seed: float, lift: float = 0.1) -> void:
	_part(arr, xf, col, {"kind": Kind.STONE, "mask": mask, "moss": 0.0, "seed": seed, "tint": 0.07,
		"normals": "smooth", "clip_y": -0.04, "lift": lift, "col2": col.lightened(0.06)})


func _build_bones() -> void:
	_begin(0.0)
	# V0: a wind-worn limestone outcrop half sunk in the sand (~1.2 m, 0.45 m tall), two flat stones and two pebbles.
	_lime(Vector3(0.62, 0.8, 0.5), Vector3(0.0, -0.14, 0.0), Vector3(0.05, 0.4, 0.06), LIME, V0, 201.0, 4, 0.7)
	_lime(Vector3(0.34, 0.44, 0.3), Vector3(0.58, -0.1, 0.3), Vector3(0.25, 1.2, -0.12), LIME_W, V0, 202.0, 3, 0.6)
	_lime(Vector3(0.3, 0.22, 0.26), Vector3(-0.56, -0.08, 0.28), Vector3(-0.1, 2.3, 0.14), LIME, V0, 203.0, 3, 0.6, 7, 4)
	_lime(Vector3(0.12, 0.1, 0.1), Vector3(-0.3, 0.0, -0.52), Vector3(0.2, 0.6, 0.1), LIME_W, V0, 204.0, 2, 0.7, 5, 3)
	_lime(Vector3(0.1, 0.08, 0.09), Vector3(0.7, 0.0, -0.22), Vector3(0.1, 1.9, 0.0), LIME_D.lerp(LIME, 0.5), V0, 205.0,
		2, 0.7, 5, 3)
	_disc(Vector3(0.05, 0.0, 0.05), 1.0, 0.85, 12, 201.0, V0)
	# V1: the rib cage of a great beast: a half-buried spine and 5 flat ribs arching out of the sand (~1.8 m long,
	# up to ~1 m tall), the tallest in the middle, curling over toward +z.
	for i: int in 7:
		var x: float = -0.82 + i * 0.27
		_bone(_chunk(Vector3(0.12, 0.11, 0.1), 3, 210.0 + i, 0.8, 6, 3), _xf(Vector3(x, 0.0, -0.4),
			Vector3(0.0, 0.2 * i, 0.0)), BONE_OLD, V1, 210.0 + i, 0.05)
	var ribs: Array = [[-0.6, 0.78], [-0.3, 0.98], [0.0, 1.0], [0.3, 0.86], [0.58, 0.64]]
	for j: int in ribs.size():
		var x0: float = ribs[j][0]
		var h: float = ribs[j][1]
		var sweep: float = 0.03 + j * 0.01
		var pts: Array = [Vector3(x0, -0.08, -0.38), Vector3(x0, h * 0.5, -0.37), Vector3(x0 + sweep, h * 0.86, -0.22),
			Vector3(x0 + sweep * 1.6, h, -0.02), Vector3(x0 + sweep * 2.0, h * 0.93, 0.17),
			Vector3(x0 + sweep * 2.3, h * 0.75, 0.31), Vector3(x0 + sweep * 2.5, h * 0.55, 0.39)]
		var radii: Array = [0.085, 0.08, 0.075, 0.07, 0.062, 0.052, 0.04]
		var cols: Array = [BONE_D, BONE_OLD, BONE, BONE, BONE, BONE.lightened(0.04), BONE.lightened(0.06)]
		_bone(_tube(pts, radii, cols, 6, 0.62, true, 1.5), Transform3D.IDENTITY, BONE, V1, 220.0 + j)
	_lime(Vector3(0.2, 0.22, 0.18), Vector3(0.82, -0.08, 0.38), Vector3(0.1, 0.7, 0.0), LIME_W, V1, 229.0, 3, 0.6, 7, 4)
	_disc(Vector3(0.0, 0.0, -0.05), 1.15, 0.7, 14, 221.0, V1)
	# V2: a horned skull lying in the sand, a thigh bone and a pale stone (~1.3 m).
	var sk := Vector3(0.0, 0.0, -0.05)
	_bone(_chunk(Vector3(0.26, 0.26, 0.24), 3, 240.0, 0.84, 9, 5), _xf(sk + Vector3(-0.06, 0.06, 0.0),
		Vector3(0.0, 0.0, 0.12)), BONE, V2, 240.0, 0.12)
	_bone(_chunk(Vector3(0.26, 0.13, 0.15), 3, 241.0, 0.8, 8, 4), _xf(sk + Vector3(0.26, 0.05, 0.0),
		Vector3(0.0, 0.0, -0.12)), BONE, V2, 241.0, 0.12)
	# Eye sockets and nostrils: brown hollows set into the bone (read as holes from above).
	for s: float in [-1.0, 1.0]:
		_part(_sph(0.052, 6, 3), _xf(sk + Vector3(0.1, 0.19, 0.125 * s), Vector3.ZERO, Vector3(1.0, 0.8, 0.9)), SOCKET,
			{"kind": Kind.STONE, "mask": V2, "moss": 0.0, "tint": 0.04, "lift": 0.12, "normals": "smooth", "a": 0.4})
		_part(_sph(0.024, 5, 2), _xf(sk + Vector3(0.5, 0.1, 0.045 * s)), SOCKET,
			{"kind": Kind.STONE, "mask": V2, "moss": 0.0, "tint": 0.04, "lift": 0.12, "normals": "smooth", "a": 0.3})
		# A horn: out from the crown, back, up and forward in a thick curl, dark at the root, weathered pale tip.
		var hp: Array = []
		var hr: Array = []
		var hc: Array = []
		for i: int in 8:
			var t: float = i / 7.0
			var ang: float = t * 2.5
			hp.append(sk + Vector3(-0.1 - sin(ang) * 0.24 + t * 0.06, 0.2 + (1.0 - cos(ang)) * 0.13 + t * 0.12,
				s * (0.13 + t * 0.42)))
			hr.append(lerpf(0.095, 0.03, t))
			hc.append(HORN_D.lerp(HORN, minf(t * 1.6, 1.0)).lerp(HORN_TIP, smoothstep(0.55, 1.0, t)))
		_part(_tube(hp, hr, hc, 6, 1.0, true, 1.8), Transform3D.IDENTITY, HORN, {"kind": Kind.STONE, "mask": V2,
			"moss": 0.0, "tint": 0.05, "normals": "smooth", "lift": 0.12})
	# A thigh bone lying half-buried, knobbed ends.
	var fa := Vector3(-0.62, 0.0, 0.46)
	var fb := Vector3(0.12, 0.04, 0.6)
	_bone(_tube([fa, fa.lerp(fb, 0.5) + Vector3(0.0, 0.02, 0.0), fb], [0.06, 0.05, 0.06], [BONE_OLD, BONE, BONE_OLD], 6,
		1.0, false), Transform3D.IDENTITY, BONE, V2, 250.0, 0.08)
	_bone(_sph(0.1, 7, 4), _xf(fa + Vector3(-0.04, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.2)), BONE_OLD, V2, 251.0,
		0.08)
	_bone(_sph(0.09, 7, 4), _xf(fb + Vector3(0.05, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.85, 1.0)), BONE_OLD, V2,
		252.0, 0.08)
	_lime(Vector3(0.22, 0.26, 0.2), Vector3(-0.5, -0.1, -0.42), Vector3(0.1, 1.4, 0.1), LIME, V2, 253.0, 3, 0.62, 7, 4)
	_disc(Vector3(-0.05, 0.0, 0.05), 0.95, 0.9, 12, 240.0, V2)
	_commit("sand_bones")
