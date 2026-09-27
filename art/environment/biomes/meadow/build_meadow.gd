extends SceneTree
## Task 12.V8 (map-fill.md 3.1 biome 4 "Hearth Meadow" + section 10): generates the meadow scatter meshes with the
## SHARED painted nature material (art/environment/nature_props/nature_mat.tres + nature_contact_mat.tres, loaded,
## never re-saved). One mesh per decor kind, 3 shape variants in each through the variant mask (UV2.x): the shader
## picks the variant from a hash of the instance position, so one MultiMesh shows 3 shapes.
##   meadow_tufts.res       lush short grass tufts ~0.5 m (V0 upright fan, V1 low wide spray, V2 + two seed stalks)
##   meadow_clover.res      dark clover mats ~0.8 m (V0 round, V1 + 3 white clover heads, V2 looser + 2 pink heads)
##   meadow_daisies.res     daisy drifts ~0.9 m (V0 10 heads, V1 12 heads, V2 8 heads + 2 pink buds)
##   meadow_dandelions.res  dandelion drifts ~0.9 m on toothed leaves (V0 8 heads + a clock, V1 6 + 3 clocks, V2 9)
##   meadow_hay.res         hay (V0 round bale on its side, V1 stack of 3 square bales, V2 thatched haystack + pole)
##   meadow_fruit_bush.res  round fruit bush ~1.3 m (V0 red apples, V1 golden pears, V2 plums) + fallen fruit
## Flowers come as drifts (one instance = a patch of heads) so a meadow reads at the game camera (40-55 m) as white /
## yellow / dark-green blotches, like the painted ground, instead of lost single specks. Parts shared by every variant
## (tuft core, clover heart, rosettes...) have mask 0, so the collapsed-triangle overhead stays small.
## Vertex data follows nature_painted.gdshader: COLOR.rgb colour, COLOR.a height gradient, UV.x wind weight
## (clamp(y * k, 0, 0.45) with one k per mesh, so touching parts never tear), UV.y local height + a lift on flower
## heads and flat leaves (the shader's dark contact band stays on stems and blade roots), UV2 = (variant mask, kind).
## Every mesh is indexed (welded). Hay and fruit bushes carry a soft contact disc (surface 1, nature_contact_mat).
## No lights, no textures, no runtime materials.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/meadow/build_meadow.gd --quit-after 600

const DIR := "res://art/environment/biomes/meadow/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45
const GOLDEN := 2.39996

# Palette (sRGB). Lawn greens a touch brighter / yellower than the Old Wood and the oaks: the meadow is the sunny,
# cared-for land around the keeps. Flowers are the small bright accents; hay is the warm big accent.
const BLADE_D := Color(0.14, 0.30, 0.10)
const BLADE := Color(0.31, 0.50, 0.16)
const BLADE_L := Color(0.58, 0.71, 0.27)
const BLADE_Y := Color(0.74, 0.74, 0.33)
const SEED := Color(0.76, 0.63, 0.38)
const CLOVER_D := Color(0.09, 0.25, 0.12)
const CLOVER := Color(0.17, 0.39, 0.17)
const CLOVER_MARK := Color(0.52, 0.68, 0.42)
const CLOVER_W := Color(0.97, 0.95, 0.90)
const CLOVER_P := Color(0.88, 0.42, 0.62)
const STEM := Color(0.24, 0.42, 0.14)
const LEAF_D := Color(0.15, 0.34, 0.12)
const LEAF_L := Color(0.40, 0.58, 0.20)
const PETAL := Color(0.98, 0.97, 0.93)
const PETAL_PINK := Color(0.96, 0.64, 0.74)
const EYE := Color(1.00, 0.80, 0.16)
const EYE_D := Color(0.86, 0.50, 0.08)
const DANDY := Color(1.00, 0.86, 0.20)
const DANDY_D := Color(0.98, 0.62, 0.06)
const CLOCK := Color(0.97, 0.96, 0.92)
const CLOCK_D := Color(0.72, 0.73, 0.68)
const HAY_D := Color(0.62, 0.42, 0.14)
const HAY := Color(0.86, 0.64, 0.24)
const HAY_L := Color(0.98, 0.83, 0.42)
const HAY_OLD := Color(0.62, 0.52, 0.33)
const TWINE := Color(0.50, 0.30, 0.14)
const POLE := Color(0.38, 0.27, 0.16)
const BUSH_D := Color(0.11, 0.27, 0.11)
const BUSH := Color(0.22, 0.42, 0.15)
const BUSH_L := Color(0.42, 0.60, 0.20)
## Fruit per bush variant: [dark (shadow side), light (sunlit side)].
const FRUIT := [[Color(0.60, 0.07, 0.07), Color(0.95, 0.24, 0.15)], [Color(0.76, 0.50, 0.08), Color(1.00, 0.82, 0.28)],
	[Color(0.26, 0.11, 0.33), Color(0.55, 0.30, 0.66)]]

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var _conv: float = 1.0
var _wind_k: float = 0.0   # wind weight per metre of height for the current mesh

# Current mesh (surface 0) and its contact disc (surface 1).
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()      # alpha < 0 = automatic height gradient at commit
var _uv := PackedVector2Array()   # (wind weight, local height + lift)
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
	_build_tufts()
	_build_clover()
	_build_daisies()
	_build_dandelions()
	_build_hay()
	_build_fruit_bush()
	for line: String in _report:
		print(line)
	print("MEADOW BUILD OK")
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
##   "up" (flat leaves / petals: mostly straight up), col2 + grad ("y" part height | "r" distance from the part axis),
##   ao_c + ao_r (darker toward a crown's core), tint (random value variation, default 0.08), lift (metres added to
##   UV.y: keeps the contact band off heads / leaves), a (fixed COLOR.a, default: height in the mesh),
##   wind (weight per metre, default the mesh's), no_caps (drop +-Y cap faces), end_col (colour of the faces along
##   the part's local X: cut bale ends). Per-vertex colours in the arrays (ARRAY_COLOR) win over col / col2.
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
	var no_caps: bool = o.get("no_caps", false)
	var has_end: bool = o.has("end_col")
	var end_col: Color = o.get("end_col", col)
	var ax: Vector3 = xf.basis.x.normalized()
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
		var is_end: bool = has_end and absf(fn.dot(ax)) > 0.85
		var fk: float = 1.0 + (_h(((tv[a] + tv[b] + tv[c]) / 3.0).snappedf(0.01)) - 0.5) * tint
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
			if is_end:
				cc = end_col
			elif not vc.is_empty():
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
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			if ao_r > 0.0:
				var d: Vector3 = (tv[vi] - ao_c) * Vector3(1.0, 1.3, 1.0)
				k *= lerpf(0.62, 1.04, smoothstep(0.30, 1.0, d.length() / ao_r))
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k, alpha))
			_uv.append(Vector2(clampf(tv[vi].y * wk, 0.0, WMAX), tv[vi].y + lift))
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
	_report.append("mesh %-18s %4d tris, %4d verts (variants %d / %d / %d), contact %d, size %.2f x %.2f x %.2f" % [
		name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		_cv.size() / 3, aabb.size.x, aabb.size.y, aabb.size.z])
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

## A grass blade / stem: a flattened 3-sided spike (visible from every side), in 2 segments (base -> mid -> tip,
## curved by the lean) or 1 (straight, 3 triangles). `face` = angle of the flat side, colours `c0` root -> `c1` tip.
func _blade(base: Vector3, h: float, w: float, lean: Vector3, face: float, c0: Color, c1: Color,
		segs: int = 2) -> Array:
	var side := Vector3(cos(face), 0.0, sin(face))
	var out := Vector3(-side.z, 0.0, side.x)
	var tip: Vector3 = base + Vector3(0.0, h, 0.0) + lean
	var sec: Array[Vector3] = [side * w, -side * w, out * w * 0.4]
	var cen: Vector3 = (sec[0] + sec[1] + sec[2]) / 3.0
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var rings: Array = [[base, 1.0, c0]]
	if segs > 1:
		rings.append([base + Vector3(0.0, h * 0.55, 0.0) + lean * 0.3, 0.62, c0.lerp(c1, 0.55)])
	for rg: Array in rings:
		for s: Vector3 in sec:
			v.append((rg[0] as Vector3) + s * float(rg[1]))
			n.append(((s - cen).normalized() + Vector3(0.0, 0.25, 0.0)).normalized())
			cols.append(rg[2] as Color)
	var t: int = v.size()
	v.append(tip)
	n.append(Vector3.UP)
	cols.append(c1)
	for i: int in 3:
		var j: int = (i + 1) % 3
		if segs > 1:
			idx.append_array([i, j, 3 + i, j, 3 + j, 3 + i, 3 + i, 3 + j, t])
		else:
			idx.append_array([i, j, t])
	return _mk(v, n, idx, cols)


## A 3-sided double pyramid from `a` to `b` (seed heads, buds), radius `r` at `bulge` (0-1 along a -> b).
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


## A flat fan (leaflet, petal star...): triangles from `centre` over the `rim` points (open fan unless `closed`).
func _fan(centre: Vector3, c_col: Color, rim: Array[Vector3], rim_cols: Array[Color], closed: bool) -> Array:
	var v := PackedVector3Array([centre])
	var n := PackedVector3Array([Vector3.UP])
	var cols := PackedColorArray([c_col])
	var idx := PackedInt32Array()
	for i: int in rim.size():
		v.append(rim[i])
		n.append(Vector3.UP)
		cols.append(rim_cols[i % rim_cols.size()])
	var last: int = rim.size() if closed else rim.size() - 1
	for i: int in last:
		idx.append_array([0, 1 + i, 1 + (i + 1) % rim.size()])
	return _mk(v, n, idx, cols)


## A leaf lying on the ground (rosettes): strips between the midrib and both edges. `profile` = half-width factors
## from the base to the tip; `toothed` pulls every other edge point back toward the base (dandelion teeth).
func _leaf(base: Vector3, ang: float, length: float, width: float, profile: Array[float], rise: float,
		c_mid: Color, c_edge: Color, toothed: bool) -> Array:
	var d := Vector3(cos(ang), 0.0, sin(ang))
	var r := Vector3(-d.z, 0.0, d.x)
	var segs: int = profile.size() - 1
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for k: int in segs + 1:
		var t: float = float(k) / segs
		var m: Vector3 = base + d * length * t + Vector3(0.0, rise * sin(PI * minf(t * 1.3, 1.0)), 0.0)
		var back: Vector3 = -d * (length / segs * 0.45) if toothed and k % 2 == 1 else Vector3.ZERO
		v.append(m)
		cols.append(c_mid)
		for sgn: float in [1.0, -1.0]:
			v.append(m + r * width * profile[k] * sgn + back - Vector3(0.0, 0.006, 0.0))
			cols.append(c_edge)
	for i: int in v.size():
		n.append(Vector3.UP)
	for k: int in segs:
		var m0: int = k * 3
		var m1: int = (k + 1) * 3
		for sd: int in [1, 2]:
			idx.append_array([m0, m0 + sd, m1, m0 + sd, m1 + sd, m1])
	return _mk(v, n, idx, cols)


## A lathe (surface of revolution around +Y) from (radius, height) profile points, bottom to top. A ring of radius
## ~0 closes that end (its triangles are degenerate and dropped). Outward normal hints.
func _lathe(profile: Array[Vector2], segs: int, phase: float = 0.0) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for p: Vector2 in profile:
		for i: int in segs:
			var a: float = i * TAU / segs + phase
			v.append(Vector3(cos(a) * p.x, p.y, sin(a) * p.x))
			n.append(Vector3(cos(a), 0.35, sin(a)).normalized())
	for ring: int in profile.size() - 1:
		for i: int in segs:
			var j: int = (i + 1) % segs
			var a0: int = ring * segs + i
			var a1: int = ring * segs + j
			var b0: int = (ring + 1) * segs + i
			var b1: int = (ring + 1) * segs + j
			idx.append_array([a0, a1, b0, a1, b1, b0])
	return _mk(v, n, idx)


# --- grass tufts -------------------------------------------------------------------------------

func _build_tufts() -> void:
	_begin(0.7)
	# Shared core (every variant): 5 tall broad blades. V0: + 4 medium blades (an upright lush fan, ~0.5 m).
	# V1: + 6 low blades splayed wide with sun-bleached tips (a spray). V2: + 2 blades and two seed stalks.
	_tuft(5, 0, 0.0, 0.05, 0.36, 0.50, 0.05, 0.11, 0, 1.0, BLADE_L, 0.05)
	_tuft(4, 5, 0.07, 0.13, 0.24, 0.33, 0.13, 0.19, V0, 2.0, BLADE_L, 0.048)
	_tuft(6, 5, 0.08, 0.17, 0.14, 0.22, 0.21, 0.30, V1, 3.0, BLADE_Y, 0.046)
	_tuft(2, 5, 0.06, 0.10, 0.22, 0.28, 0.10, 0.14, V2, 4.0, BLADE_L, 0.048)
	for k: int in 2:
		var a: float = 0.8 + k * 2.6
		var base := Vector3(cos(a) * 0.04, -0.02, sin(a) * 0.04)
		var lean := Vector3(cos(a), 0.0, sin(a)) * (0.07 + 0.05 * k)
		var h: float = 0.64 - k * 0.1
		_part(_blade(base, h, 0.013, lean, a, BLADE_D, STEM), Transform3D.IDENTITY, STEM, {"mask": V2,
			"normals": "smooth"})
		var tip: Vector3 = base + Vector3(0.0, h, 0.0) + lean
		var dir: Vector3 = (lean * 0.45 + Vector3(0.0, 0.12, 0.0)).normalized()
		_part(_spindle(tip - dir * 0.01, tip + dir * 0.13, 0.026, 0.4, SEED.darkened(0.25), SEED.lightened(0.15)),
			Transform3D.IDENTITY, SEED, {"mask": V2, "normals": "smooth", "lift": 0.3})
	_commit("meadow_tufts")


## `count` blades around the origin (golden-angle spiral from index `start`): inner blades tall and upright, outer
## ones shorter and leaning out.
func _tuft(count: int, start: int, r0: float, r1: float, h0: float, h1: float, lean0: float, lean1: float, mask: int,
		seed: float, tip_col: Color, width: float) -> void:
	for i: int in count:
		var a: float = (start + i) * GOLDEN + seed * 0.37
		var t: float = _h(Vector3(i, seed, 1.0))
		var f: float = sqrt((i + 0.5) / count)   # 0 = centre, 1 = rim
		var r: float = lerpf(r0, r1, f)
		var p := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var hh: float = lerpf(h1, h0, clampf(f * 0.8 + (t - 0.5) * 0.4, 0.0, 1.0))
		var la: float = a + (t - 0.5) * 0.9
		var lean := Vector3(cos(la), 0.0, sin(la)) * lerpf(lean0, lean1, clampf(f + (t - 0.5) * 0.3, 0.0, 1.0))
		var c0: Color = BLADE_D.lerp(BLADE, t * 0.35)
		var c1: Color = BLADE.lerp(tip_col, 0.5 + t * 0.5)
		var segs: int = 2 if hh > 0.26 else 1   # short blades: straight (3 triangles), the curve would not show
		_part(_blade(p, hh, width * (0.85 + t * 0.35), lean, a + PI * 0.5 + (t - 0.5) * 0.8, c0, c1, segs),
			Transform3D.IDENTITY, c0, {"mask": mask, "normals": "crown", "crown": Vector3(0.0, -0.25, 0.0),
			"crown_k": 0.55, "tint": 0.06})


# --- clover ------------------------------------------------------------------------------------

func _build_clover() -> void:
	_begin(1.0)
	# A dense dark mat of trefoils (~0.8 m): 6 shared in the heart; V0 + 7 around (round mat), V1 + 5 around and
	# 3 white clover heads, V2 + 8 in a looser, wider ring and 2 pink heads.
	_trefoils(6, 0, 0.0, 0.17, 0, 11.0)
	_trefoils(7, 6, 0.17, 0.36, V0, 12.0)
	_trefoils(5, 6, 0.17, 0.33, V1, 13.0)
	_trefoils(8, 6, 0.22, 0.44, V2, 14.0)
	_clover_flower(Vector3(0.10, 0.0, -0.06), 0.15, CLOVER_W, V1, 1.0)
	_clover_flower(Vector3(-0.12, 0.0, 0.08), 0.12, CLOVER_W, V1, 2.0)
	_clover_flower(Vector3(0.02, 0.0, 0.16), 0.14, CLOVER_W, V1, 3.0)
	_clover_flower(Vector3(0.05, 0.0, 0.03), 0.16, CLOVER_P, V2, 4.0)
	_clover_flower(Vector3(-0.18, 0.0, -0.1), 0.13, CLOVER_P, V2, 5.0)
	_commit("meadow_clover")


## `count` trefoils on a golden-angle spiral from index `start`, radius rmin -> rmax (the heart sits a little higher).
func _trefoils(count: int, start: int, rmin: float, rmax: float, mask: int, seed: float) -> void:
	for i: int in count:
		var a: float = (start + i) * GOLDEN + seed * 0.21
		var t: float = _h(Vector3(i, seed, 2.0))
		var f: float = sqrt((i + 0.5) / count)
		var rr: float = lerpf(rmin, rmax, f)
		var base := Vector3(cos(a) * rr, 0.03 + (1.0 - rr / 0.44) * 0.05 + t * 0.02, sin(a) * rr)
		var size: float = 0.085 + t * 0.03
		var spin: float = a + t * 2.0
		var edge: Color = CLOVER_D.lerp(CLOVER, 0.3 + t * 0.35)
		for l: int in 3:
			var la: float = spin + l * TAU / 3.0
			var d := Vector3(cos(la), -0.14, sin(la)).normalized()
			var r := Vector3(-sin(la), 0.0, cos(la))
			# A heart with its point at the stem: two rounded lobes and a notch (4 triangles).
			var rim: Array[Vector3] = []
			for q: Vector2 in [Vector2(0.50, 0.52), Vector2(0.34, 0.88), Vector2(0.0, 0.72), Vector2(-0.34, 0.88),
					Vector2(-0.50, 0.52)]:
				rim.append(base + (r * q.x + d * q.y) * size)
			_part(_fan(base, CLOVER_MARK.lerp(CLOVER, 0.2 + t * 0.25), rim, [edge, edge, CLOVER, edge, edge]
				as Array[Color], false), Transform3D.IDENTITY, CLOVER, {"mask": mask, "normals": "up", "lift": 0.25,
				"a": 0.8, "tint": 0.1})


func _clover_flower(p: Vector3, h: float, col: Color, mask: int, seed: float) -> void:
	var lean := Vector3(cos(seed * 2.0), 0.0, sin(seed * 2.0)) * 0.025
	_part(_blade(p, h, 0.01, lean, seed, STEM.darkened(0.2), STEM, 1), Transform3D.IDENTITY, STEM, {"mask": mask,
		"normals": "smooth"})
	_part(_sph(0.05, 5, 3), _xf(p + Vector3(0.0, h + 0.025, 0.0) + lean, Vector3.ZERO, Vector3(1.0, 0.9, 1.0)),
		col.darkened(0.35), {"mask": mask, "normals": "smooth", "col2": col, "lift": 0.35, "a": 1.0, "tint": 0.04})


# --- daisies -----------------------------------------------------------------------------------

func _build_daisies() -> void:
	_begin(1.0)
	var spoon: Array[float] = [0.25, 0.7, 1.0, 0.0]
	for i: int in 6:   # shared leaf rosette
		var a: float = i * TAU / 6.0 + 0.3
		_part(_leaf(Vector3(cos(a) * 0.05, 0.015, sin(a) * 0.05), a, 0.15 + 0.05 * _h(Vector3(i, 4, 4)), 0.04, spoon,
			0.025, LEAF_L, LEAF_D, false), Transform3D.IDENTITY, LEAF_L, {"normals": "up", "lift": 0.2, "a": 0.7})
	# A drift of heads: 5 shared in the heart; V0 + 5 around, V1 + 7 in a wider ring, V2 + 3 and 2 pink buds.
	_daisy_drift(5, 0, 0.0, 0.16, 0, 21.0, 0)
	_daisy_drift(5, 5, 0.18, 0.40, V0, 22.0, 0)
	_daisy_drift(7, 5, 0.18, 0.46, V1, 23.0, 0)
	_daisy_drift(3, 5, 0.2, 0.38, V2, 24.0, 2)
	_commit("meadow_daisies")


func _daisy_drift(count: int, start: int, rmin: float, rmax: float, mask: int, seed: float, buds: int) -> void:
	var total: int = count + buds
	for i: int in total:
		var a: float = (start + i) * GOLDEN + seed * 0.13
		var t: float = _h(Vector3(i, seed, 3.0))
		var f: float = sqrt((i + 0.5) / total)
		var rr: float = lerpf(rmin, rmax, f)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var base: Vector3 = dir * rr * 0.8
		var lean: Vector3 = dir * (0.03 + rr * 0.2) + Vector3(cos(a * 3.1), 0.0, sin(a * 2.3)) * 0.02
		var h: float = lerpf(0.27, 0.15, clampf(rr / 0.46, 0.0, 1.0)) * (0.88 + t * 0.24)
		_part(_blade(base, h, 0.011, lean, a + 1.2, STEM.darkened(0.25), STEM, 1), Transform3D.IDENTITY, STEM,
			{"mask": mask, "normals": "smooth"})
		var top: Vector3 = base + Vector3(0.0, h, 0.0) + lean
		var tilt := Basis(Vector3(-dir.z, 0.0, dir.x), -0.12 - 0.3 * clampf(rr / 0.46, 0.0, 1.0))
		if i >= count:   # a closed pink-tipped bud
			_part(_spindle(top - Vector3(0.0, 0.01, 0.0), top + tilt.y * 0.06, 0.022, 0.45, STEM, PETAL_PINK),
				Transform3D.IDENTITY, STEM, {"mask": mask, "normals": "smooth", "lift": 0.3, "a": 1.0})
			continue
		_daisy_head(Transform3D(tilt * Basis(Vector3.UP, t * 3.0), top), 0.068 + t * 0.014,
			PETAL_PINK if t > 0.82 else PETAL, mask)


## A daisy head (local +Y up): an 8-petal white star and a raised yellow eye.
func _daisy_head(xf: Transform3D, size: float, tip_col: Color, mask: int) -> void:
	var rim: Array[Vector3] = []
	var cols: Array[Color] = []
	for i: int in 16:
		var a: float = i * PI / 8.0
		var tip: bool = i % 2 == 0
		var r: float = size if tip else size * 0.45
		rim.append(Vector3(cos(a) * r, -0.01 if tip else 0.003, sin(a) * r))
		cols.append(PETAL.lerp(tip_col, 0.8) if tip else PETAL)
	_part(_fan(Vector3(0.0, 0.004, 0.0), PETAL, rim, cols, true), xf, PETAL, {"mask": mask, "normals": "up",
		"lift": 0.4, "a": 1.0, "tint": 0.04})
	var eye: Array[Vector3] = []
	for i: int in 5:
		var a2: float = i * TAU / 5.0
		eye.append(Vector3(cos(a2) * size * 0.38, size * 0.08, sin(a2) * size * 0.38))
	var eye_arr: Array = _fan(Vector3(0.0, size * 0.32, 0.0), EYE, eye, [EYE_D] as Array[Color], true)
	var en: PackedVector3Array = eye_arr[Mesh.ARRAY_NORMAL]
	var ev: PackedVector3Array = eye_arr[Mesh.ARRAY_VERTEX]
	for k: int in en.size():   # dome normals (outward + up)
		en[k] = (Vector3(ev[k].x, 0.0, ev[k].z) * 12.0 + Vector3.UP).normalized()
	eye_arr[Mesh.ARRAY_NORMAL] = en
	_part(eye_arr, xf, EYE, {"mask": mask, "normals": "smooth", "lift": 0.45, "a": 1.0, "tint": 0.04})


# --- dandelions --------------------------------------------------------------------------------

func _build_dandelions() -> void:
	_begin(1.0)
	var teeth: Array[float] = [0.2, 1.0, 0.45, 0.9, 0.0]
	for i: int in 6:   # shared toothed rosettes (two little plants)
		var c := Vector3(0.1, 0.0, 0.05) if i < 3 else Vector3(-0.12, 0.0, -0.08)
		var a: float = i * TAU / 3.0 + (1.1 if i < 3 else 0.2)
		_part(_leaf(c + Vector3(0.0, 0.012, 0.0), a, 0.19 + 0.05 * _h(Vector3(i, 5, 5)), 0.042, teeth, 0.03,
			LEAF_L.lightened(0.05), LEAF_D, true), Transform3D.IDENTITY, LEAF_L, {"normals": "up", "lift": 0.2,
			"a": 0.7})
	# 3 shared flowers; V0 + 5 flowers + 1 clock, V1 + 3 flowers + 3 clocks, V2 + 6 flowers (a low golden drift).
	_dandy_drift(3, 0, 0.0, 0.14, 0, 31.0, 0, 1.0)
	_dandy_drift(5, 3, 0.16, 0.40, V0, 32.0, 1, 1.0)
	_dandy_drift(3, 3, 0.16, 0.40, V1, 33.0, 3, 1.0)
	_dandy_drift(6, 3, 0.16, 0.44, V2, 34.0, 0, 0.8)
	_commit("meadow_dandelions")


func _dandy_drift(count: int, start: int, rmin: float, rmax: float, mask: int, seed: float, clocks: int,
		hk: float) -> void:
	var total: int = count + clocks
	for i: int in total:
		var a: float = (start + i) * GOLDEN + seed * 0.17
		var t: float = _h(Vector3(i, seed, 3.0))
		var f: float = sqrt((i + 0.5) / total)
		var rr: float = lerpf(rmin, rmax, f)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var base: Vector3 = dir * rr * 0.8
		var clock: bool = i >= count
		var lean: Vector3 = dir * (0.03 + rr * 0.18)
		var h: float = (0.3 + t * 0.06 if clock else lerpf(0.21, 0.13, clampf(rr / 0.44, 0.0, 1.0)) * (0.9 + t * 0.2)) * hk
		_part(_blade(base, h, 0.011, lean, a + 1.0, STEM.darkened(0.25), STEM.lightened(0.1), 1),
			Transform3D.IDENTITY, STEM, {"mask": mask, "normals": "smooth"})
		var top: Vector3 = base + Vector3(0.0, h, 0.0) + lean
		if clock:   # a white seed clock
			_part(_sph(0.056, 6, 3), _xf(top + Vector3(0.0, 0.04, 0.0)), CLOCK_D, {"mask": mask, "normals": "smooth",
				"col2": CLOCK, "lift": 0.35, "a": 1.0, "tint": 0.03})
			continue
		var rim: Array[Vector3] = []
		for k: int in 14:   # a fluffy round head: a shallow ragged edge, not a star
			var ka: float = k * TAU / 14.0 + a
			var tip: bool = k % 2 == 0
			var r: float = (0.066 if tip else 0.056) * (0.9 + t * 0.2)
			rim.append(Vector3(cos(ka) * r, 0.0 if tip else 0.006, sin(ka) * r))
		var arr: Array = _fan(Vector3(0.0, 0.028, 0.0), DANDY_D, rim, [DANDY] as Array[Color], true)
		var an: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var av: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for k2: int in an.size():
			an[k2] = (Vector3(av[k2].x, 0.0, av[k2].z) * 10.0 + Vector3.UP).normalized()
		arr[Mesh.ARRAY_NORMAL] = an
		var tilt := Basis(Vector3(-dir.z, 0.0, dir.x), -0.1 - 0.3 * clampf(rr / 0.44, 0.0, 1.0))
		_part(arr, Transform3D(tilt, top), DANDY, {"mask": mask, "normals": "smooth", "lift": 0.4, "a": 1.0,
			"tint": 0.05})


# --- hay ---------------------------------------------------------------------------------------

func _build_hay() -> void:
	_begin(0.0)
	var hay := {"kind": Kind.BARK, "col2": HAY_L, "grad": "wy", "tint": 0.14}
	# V0: a round bale on its side (axis along X): a barrel of straw with rounded shoulders, spiral cut ends, two
	# twine bands and a few wisps.
	var by: float = 0.56
	var side: Array[Vector2] = [Vector2(0.46, -0.5), Vector2(0.54, -0.45), Vector2(0.585, -0.3), Vector2(0.6, -0.1),
		Vector2(0.6, 0.1), Vector2(0.585, 0.3), Vector2(0.54, 0.45), Vector2(0.46, 0.5)]
	var o0: Dictionary = hay.duplicate()
	o0.merge({"mask": V0, "jitter": 0.02, "seed": 31.0}, true)
	_part(_lathe(side, 14), _xf(Vector3(0.0, by, 0.0), Vector3(0.0, 0.0, PI * 0.5)), HAY_D, o0)
	for s: float in [-1.0, 1.0]:
		_part(_bale_end(0.47, 14, s, 31.0 + s), Transform3D(Basis.IDENTITY, Vector3(s * 0.49, by, 0.0)), HAY,
			{"kind": Kind.BARK, "mask": V0, "normals": "smooth", "tint": 0.06})
		_part(_lathe([Vector2(0.607, -0.022), Vector2(0.607, 0.022)] as Array[Vector2], 14), _xf(Vector3(s * 0.22, by,
			0.0), Vector3(0.0, 0.0, PI * 0.5)), TWINE, {"kind": Kind.BARK, "mask": V0, "normals": "smooth", "tint": 0.03})
	_wisps(6, Vector3(0.0, by + 0.58, 0.0), 0.45, V0, 35.0)
	_straw(6, 0.66, 0.42, V0, 32.0)
	_disc(Vector3(0.0, 0.0, 0.05), 0.8, 0.8, 12, 33.0, V0)
	# V1: a stack of 3 square bales (2 + 1 across), twine lines, lighter cut ends.
	var bale := Vector3(1.0, 0.46, 0.56)
	var stack: Array = [[Vector3(0.0, 0.23, -0.29), 0.05], [Vector3(0.05, 0.23, 0.3), -0.08],
		[Vector3(0.02, 0.68, 0.0), PI * 0.5 + 0.12]]
	var k: int = 0
	for b: Array in stack:
		var xf: Transform3D = _xf(b[0] as Vector3, Vector3(0.0, b[1] as float, 0.0))
		var o1: Dictionary = hay.duplicate()
		o1.merge({"mask": V1, "jitter": 0.022, "seed": 40.0 + k, "end_col": HAY_L, "grad": "y"}, true)
		_part(_box(bale, 1), xf, HAY_D, o1)
		for s2: float in [-1.0, 1.0]:
			_part(_box(Vector3(0.035, bale.y + 0.025, bale.z + 0.025)), xf * _xf(Vector3(s2 * 0.26, 0.0, 0.0)), TWINE,
				{"kind": Kind.BARK, "mask": V1, "tint": 0.03})
		k += 1
	_wisps(5, Vector3(0.02, 0.92, 0.0), 0.35, V1, 45.0)
	_straw(7, 0.78, 0.45, V1, 42.0)
	_disc(Vector3(0.0, 0.0, 0.0), 0.85, 0.9, 12, 43.0, V1)
	# V2: a tall haystack of three overlapping thatch tiers (reads as rings from above), a pole through the top, a
	# straw skirt.
	var tiers: Array = [
		[[Vector2(0.8, -0.05), Vector2(0.86, 0.22), Vector2(0.84, 0.5), Vector2(0.7, 0.8)], HAY_D, HAY, 0.0],
		[[Vector2(0.95, 0.46), Vector2(0.9, 0.56), Vector2(0.8, 0.8), Vector2(0.62, 1.08), Vector2(0.42, 1.32)],
			HAY_D, HAY_L, 0.26],
		[[Vector2(0.74, 1.0), Vector2(0.7, 1.1), Vector2(0.52, 1.34), Vector2(0.3, 1.6), Vector2(0.1, 1.8),
			Vector2(0.0, 1.84)], HAY_D.lerp(HAY_OLD, 0.4), HAY_L.lerp(HAY_OLD, 0.2), 0.52],
	]
	var ti: int = 0
	for tr: Array in tiers:
		var prof: Array[Vector2] = []
		prof.assign(tr[0])
		_part(_lathe(prof, 12, tr[3] as float), Transform3D.IDENTITY, tr[1] as Color,
			{"kind": Kind.BARK, "mask": V2, "normals": "smooth", "col2": tr[2], "grad": "y", "jitter": 0.03,
			"seed": 50.0 + ti, "tint": 0.12})
		ti += 1
	_part(_cyl(0.035, 0.045, 0.8, 5), _xf(Vector3(0.02, 1.98, 0.0), Vector3(0.0, 0.0, 0.07)), POLE,
		{"kind": Kind.BARK, "mask": V2, "normals": "smooth"})
	_wisps(5, Vector3(0.0, 1.75, 0.0), 0.2, V2, 55.0)
	_straw(9, 0.98, 0.5, V2, 52.0)
	_disc(Vector3.ZERO, 1.15, 1.15, 14, 53.0, V2)
	_commit("meadow_hay")


## A cut bale end facing +X (s = 1) or -X: a slightly domed spiral of lighter / darker straw rings.
func _bale_end(r: float, segs: int, s: float, seed: float) -> Array:
	var v := PackedVector3Array([Vector3(s * 0.025, 0.0, 0.0)])
	var n := PackedVector3Array([Vector3(s, 0.0, 0.0)])
	var cols := PackedColorArray([HAY_D.lerp(HAY, 0.5)])
	var idx := PackedInt32Array()
	var radii: Array[float] = [0.3, 0.62, 0.86, 1.04]
	var ring_cols: Array[Color] = [HAY_L, HAY_D.lerp(HAY, 0.55), HAY_L, HAY]
	for ring: int in radii.size():
		for i: int in segs:
			var a: float = i * TAU / segs
			var rr: float = r * (radii[ring] + 0.09 * float(i) / segs)   # the spiral seam
			rr += (_h(Vector3(seed, ring, i)) - 0.5) * 0.02
			var bulge: float = 0.025 * (1.0 - radii[ring] * radii[ring] * 0.9)
			v.append(Vector3(s * bulge, sin(a) * rr, cos(a) * rr))
			n.append(Vector3(s, 0.0, 0.0))
			cols.append(ring_cols[ring])
	for i: int in segs:
		idx.append_array([0, 1 + i, 1 + (i + 1) % segs])
	for ring: int in radii.size() - 1:
		for i: int in segs:
			var j: int = (i + 1) % segs
			var a0: int = 1 + ring * segs + i
			var a1: int = 1 + ring * segs + j
			var b0: int = 1 + (ring + 1) * segs + i
			var b1: int = 1 + (ring + 1) * segs + j
			idx.append_array([a0, a1, b0, a1, b1, b0])
	return _mk(v, n, idx, cols)


## Loose straw lying on the ground around a hay prop.
func _straw(count: int, r: float, len: float, mask: int, seed: float) -> void:
	for i: int in count:
		var a: float = i * GOLDEN + seed
		var t: float = _h(Vector3(i, seed, 6.0))
		var p := Vector3(cos(a) * r * (0.9 + t * 0.3), 0.0, sin(a) * r * (0.9 + t * 0.3))
		var d := Vector3(cos(a + 1.3 + t), 0.0, sin(a + 1.3 + t))
		_part(_blade(p - d * len * 0.5, 0.05 + t * 0.06, 0.02, d * len * (0.6 + t * 0.4), a, HAY_D, HAY_L, 1),
			Transform3D.IDENTITY, HAY, {"kind": Kind.BARK, "mask": mask, "normals": "smooth", "lift": 0.15})


## Straw wisps sticking out of the top of a bale / stack.
func _wisps(count: int, c: Vector3, spread: float, mask: int, seed: float) -> void:
	for i: int in count:
		var a: float = i * GOLDEN + seed
		var t: float = _h(Vector3(i, seed, 9.0))
		var p: Vector3 = c + Vector3(cos(a) * spread * t, -0.05, sin(a) * spread * (1.0 - t) * 0.6)
		var d := Vector3(cos(a * 1.7), 0.0, sin(a * 1.7))
		_part(_blade(p, 0.12 + t * 0.1, 0.014, d * (0.12 + t * 0.1), a, HAY, HAY_L, 1), Transform3D.IDENTITY, HAY,
			{"kind": Kind.BARK, "mask": mask, "normals": "smooth"})


# --- fruit bush --------------------------------------------------------------------------------

func _build_fruit_bush() -> void:
	_begin(0.2)
	var crown := Vector3(0.0, 0.55, 0.0)
	var bo := {"normals": "crown", "crown": crown, "crown_k": 0.6, "crown_s": Vector3(0.75, 0.55, 0.75),
		"grad": "y", "ao_c": crown, "ao_r": 0.85, "jitter": 0.04, "tint": 0.10}
	# Core blob (every variant) + 4 blobs per variant (V0 round and full, V1 taller, V2 wide and low), then fruit.
	var core := [Vector3(0.0, 0.5, 0.0), 0.5]
	_blob(core[0] as Vector3, core[1] as float, 0, 60.0, bo)
	var sets: Array = [
		[[Vector3(0.42, 0.4, 0.1), 0.4], [Vector3(-0.38, 0.42, -0.16), 0.42], [Vector3(0.05, 0.88, 0.04), 0.36],
			[Vector3(-0.08, 0.38, 0.42), 0.37]],
		[[Vector3(0.1, 0.95, 0.02), 0.42], [Vector3(0.32, 0.45, -0.24), 0.36], [Vector3(-0.31, 0.5, 0.22), 0.38],
			[Vector3(-0.02, 1.26, 0.06), 0.27]],
		[[Vector3(0.52, 0.33, 0.0), 0.38], [Vector3(-0.5, 0.33, 0.12), 0.37], [Vector3(0.1, 0.33, -0.48), 0.36],
			[Vector3(0.0, 0.72, 0.1), 0.42]],
	]
	var fruit_n: Array[int] = [11, 9, 13]
	var fruit_r: Array[float] = [0.085, 0.08, 0.066]
	for vi: int in 3:
		var mask: int = 1 << vi
		var blobs: Array = sets[vi]
		for bi: int in blobs.size():
			_blob(blobs[bi][0] as Vector3, blobs[bi][1] as float, mask, 61.0 + vi * 5 + bi, bo)
		var all: Array = blobs.duplicate()
		all.append(core)
		var cols: Array = FRUIT[vi]
		var sc := Vector3(1.0, 1.35 if vi == 1 else 1.0, 1.0)
		for j: int in fruit_n[vi]:
			var b: Array = all[j % all.size()]
			var t: float = _h(Vector3(j, vi, 8.0))
			var fa: float = j * GOLDEN + vi
			var el: float = lerpf(-0.1, 0.8, t)
			var dir := Vector3(cos(el) * cos(fa), sin(el), cos(el) * sin(fa))
			var p: Vector3 = (b[0] as Vector3) + dir * (b[1] as float) * Vector3(1.0, 0.85, 1.0) * 0.97
			if p.y < 0.22:
				continue
			_part(_sph(fruit_r[vi] * (0.9 + t * 0.25), 6, 3), _xf(p, Vector3.ZERO, sc), cols[0] as Color,
				{"mask": mask, "normals": "smooth", "col2": cols[1], "lift": 0.4, "a": 1.0, "tint": 0.06})
		for g: int in (2 if vi != 1 else 1):   # fallen fruit in the grass
			var ga: float = 0.9 + g * 2.4 + vi
			_part(_sph(fruit_r[vi], 6, 3), _xf(Vector3(cos(ga) * 0.8, fruit_r[vi] * 0.8, sin(ga) * 0.8), Vector3.ZERO,
				sc), (cols[0] as Color).darkened(0.1), {"mask": mask, "normals": "smooth", "col2": cols[1], "lift": 0.4,
				"a": 1.0, "wind": 0.0})
	_disc(Vector3.ZERO, 0.88, 0.88, 12, 70.0)
	_commit("meadow_fruit_bush")


func _blob(c: Vector3, r: float, mask: int, seed: float, bo: Dictionary) -> void:
	var o: Dictionary = bo.duplicate()
	o["mask"] = mask
	o["seed"] = seed
	o["col2"] = BUSH_L
	var dark: Color = BUSH_D.lerp(BUSH, clampf(c.y * 0.9, 0.0, 1.0))
	_part(_sph(r, 8, 4), _xf(c, Vector3(0.0, seed, 0.0), Vector3(1.0, 0.85, 1.0)), dark, o)

