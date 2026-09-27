extends SceneTree
## Task 12.V13 (Landmarks A, docs/design/map-fill.md 3.2 + 10): generates the two landmark scenes.
##   art/environment/landmarks/colossus.tscn     Fallen Colossus: the toppled head of an ancient crowned stone king,
##                                                lying on its cheek and half sunk in the heath, gazing at its own open
##                                                hand; verdigris crown and cuffs with tiny ember runes, moss in the eyes.
##   art/environment/landmarks/giant_stump.tscn  Giant's Stump: the hollow cut stump of an enormous old tree (4 m wide),
##                                                buttress roots, growth rings, a barber-chair splinter, bracket fungus,
##                                                toadstools, a burrow under the roots and a sapling growing from the rim.
## Meshes: art/environment/landmarks/meshes/<name>.res, ONE mesh per landmark (surface 0 = the shared painted nature
## material nature_props/nature_mat.tres, 1 = the shared contact shadow nature_contact_mat.tres, 2 = the rune glow
## colossus_rune_mat.tres, colossus only). 0 lights. Colliders (StaticBody3D "Collision", layer 1 = world, mask 0) are
## the sizes of map-fill.md 3.2, so the navmesh bake treats them like terrain:
##   colossus: head CylinderShape3D r 2.2 + hand BoxShape3D 1.5 x 3.0 (all within 3.5 m of the centre)
##   stump:    CylinderShape3D r 2.0
## Scene root: Node3D in group "landmarks", metadata `landmark_id` and `decor_clear_radius`. The mirrored copy is the
## same scene turned by PI around Y (point mirror), so both sides get identical colliders.
## Re-run after changing a shape or colour:
##   $GODOT --headless --path . -s res://art/environment/landmarks/build_landmarks_a.gd --quit-after 600

const LDIR := "res://art/environment/landmarks/"
const MESH_DIR := "res://art/environment/landmarks/meshes/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }

# --- colliders (map-fill.md 3.2) -------------------------------------------------------------------
const HEAD_CENTER := Vector3(1.0, 0.0, -0.7)      ## head cylinder axis (xz), 1.22 m from the centre
const HEAD_R := 2.2
## Collider heights stay under the navmesh agent height (2.0) above the ground: a taller hollow shape would bake a
## walkable island INSIDE itself (Recast rasterises the shell, and the free height between ground and cap >= 2 m).
const HEAD_H := 2.0
const HAND_CENTER := Vector3(-1.045, 0.0, 1.587)  ## hand box centre (xz), 1.9 m from the centre
const HAND_DIR := Vector3(-0.55, 0.0, 0.835)      ## hand box long axis (wrist -> fingers), radial
const HAND_W := 1.5
const HAND_L := 3.0
const HAND_H := 1.8
const STUMP_R := 2.0
const STUMP_H := 2.0

# --- colossus pose ----------------------------------------------------------------------------------
const CROWN_DIR := Vector3(0.85, 0.0, 0.53)       ## the head lies with its crown this way (beard the other way)
const FACE_TILT := 52.0                           ## degrees the face is turned up toward the sky (camera pitch 55)
const HEAD_Y := 0.95                              ## head centre height (the back of the skull is sunk)
const HR := Vector3(1.44, 1.72, 1.54)             ## head radii (head space: +Y crown, +Z face, +X ear)

# --- palette (sRGB; the painted shader adds light tops, dark feet, moss on the sky-facing faces) -----
const STONE_W := Color(0.57, 0.56, 0.55)    # the face: pale grey limestone (Art Lab R3: cool, off the grass hue)
const STONE_C := Color(0.52, 0.52, 0.53)    # skull, hand
const STONE_S := Color(0.44, 0.44, 0.45)    # hair, beard (carved, a little darker)
const STONE_F := Color(0.70, 0.66, 0.58)    # fresh breaks
const STONE_R := Color(0.44, 0.42, 0.40)    # rubble
const CRACK := Color(0.13, 0.12, 0.11)
const PATINA := Color(0.28, 0.47, 0.41)     # verdigris bronze: crown, cuff, beard ring, earring
const PATINA_D := Color(0.17, 0.32, 0.29)
const GROOVE := Color(0.09, 0.07, 0.06)     # carved rune grooves
const DEAD_RUNE := Color(0.46, 0.2, 0.08)   # dull burnt-ember inlay of the runes that do not glow
const DIRT := Color(0.40, 0.30, 0.20)
const DIRT_D := Color(0.30, 0.22, 0.15)
const MOSS := Color(0.20, 0.38, 0.11)
const MOSS_L := Color(0.33, 0.52, 0.16)
const BARK := Color(0.45, 0.36, 0.27)
const BARK_D := Color(0.30, 0.23, 0.17)
const WOOD_L := Color(0.70, 0.56, 0.38)
const WOOD := Color(0.56, 0.42, 0.28)
const WOOD_D := Color(0.36, 0.25, 0.16)
const WOOD_OLD := Color(0.56, 0.46, 0.34)   # weathered torn fibres
const HOLLOW := Color(0.19, 0.13, 0.09)
const HOLLOW_D := Color(0.06, 0.045, 0.035)
const SHELF_TOP := Color(0.72, 0.62, 0.44)
const SHELF_RIM := Color(0.58, 0.32, 0.13)
const CAP := Color(0.70, 0.25, 0.12)
const CAP_D := Color(0.46, 0.16, 0.09)
const STEM := Color(0.86, 0.80, 0.67)
const LEAF := Color(0.36, 0.55, 0.18)
const LEAF_L := Color(0.52, 0.68, 0.24)
const LITTER := Color(0.56, 0.32, 0.13)

## Rune glyphs (original): strokes in a unit box, [from, to].
const GLYPHS: Array = [
	[[Vector2(0.0, -0.5), Vector2(0.0, 0.5)], [Vector2(0.0, 0.08), Vector2(0.32, 0.42)], [Vector2(0.0, -0.22), Vector2(0.32, 0.12)]],
	[[Vector2(0.0, -0.5), Vector2(0.0, 0.5)], [Vector2(-0.3, 0.18), Vector2(0.0, 0.5)], [Vector2(0.3, 0.18), Vector2(0.0, 0.5)]],
	[[Vector2(0.0, 0.5), Vector2(0.3, 0.0)], [Vector2(0.3, 0.0), Vector2(0.0, -0.5)], [Vector2(0.0, -0.5), Vector2(-0.3, 0.0)],
		[Vector2(-0.3, 0.0), Vector2(0.0, 0.5)]],
	[[Vector2(-0.15, -0.5), Vector2(-0.15, 0.5)], [Vector2(-0.15, 0.5), Vector2(0.25, 0.22)], [Vector2(-0.15, -0.05), Vector2(0.25, -0.32)]],
	[[Vector2(-0.28, -0.5), Vector2(0.0, 0.5)], [Vector2(0.28, -0.5), Vector2(0.0, 0.5)], [Vector2(-0.16, -0.12), Vector2(0.16, -0.12)]],
	[[Vector2(0.0, -0.5), Vector2(0.0, 0.5)], [Vector2(-0.3, -0.12), Vector2(0.3, 0.12)]],
]

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var rune_mat: ShaderMaterial
var _conv: float = 1.0
var _head_xf: Transform3D
var _hand_xf: Transform3D

# Current mesh: surface 0 (painted), 1 (contact disc), 2 (glow).
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _w := PackedFloat32Array()     # UV.x: stone moss amount / foliage wind weight
var _uv2 := PackedVector2Array()   # (variant mask = 0, kind)
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
var _gv := PackedVector3Array()
var _gn := PackedVector3Array()
var _report: Array[String] = []
var _moss_k: float = 1.0           # scales every part's "moss" (the colossus uses COLOSSUS_MOSS_K)
const COLOSSUS_MOSS_K := 0.4


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	_make_materials()
	_build_colossus()
	_build_stump()
	for line: String in _report:
		print(line)
	print("LANDMARKS A BUILD OK")
	quit()


# --- materials / saving -------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _save_ref(res: Resource, path: String) -> Resource:
	_save(res, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


## The two shared nature materials are only LOADED (owned by nature_props/build_nature.gd), never re-saved.
func _make_materials() -> void:
	mat = load(NDIR + "nature_mat.tres") as ShaderMaterial
	contact_mat = load(NDIR + "nature_contact_mat.tres") as ShaderMaterial
	var g := ShaderMaterial.new()
	g.shader = load("res://art/environment/env_glow.gdshader") as Shader
	g.set_shader_parameter(&"glow_color", Color(1.0, 0.42, 0.08))
	g.set_shader_parameter(&"core_color", Color(1.0, 0.62, 0.24))
	g.set_shader_parameter(&"energy", 2.0)
	g.set_shader_parameter(&"pulse_speed", 0.8)
	g.set_shader_parameter(&"pulse_amount", 0.3)
	g.set_shader_parameter(&"sparkle", 0.0)
	rune_mat = _save_ref(g, LDIR + "colossus_rune_mat.tres") as ShaderMaterial


# --- small maths --------------------------------------------------------------------------------

func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _ss(a: float, b: float, x: float) -> float:
	var t: float = clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _bump(p: Vector3, c: Vector3, s: float) -> float:
	return exp(-(p - c.normalized()).length_squared() / (s * s))


func _spow(x: float, e: float) -> float:
	return signf(x) * pow(absf(x), e)


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


## Basis whose +Y runs along a -> b.
func _along(a: Vector3, b: Vector3) -> Basis:
	var y: Vector3 = (b - a).normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Basis with +Z along n and +Y as close as possible to up.
func _facing(n: Vector3, up: Vector3 = Vector3.UP) -> Basis:
	var z: Vector3 = n.normalized()
	var u: Vector3 = up if absf(up.normalized().dot(z)) < 0.95 else Vector3.FORWARD
	var x: Vector3 = u.cross(z).normalized()
	var y: Vector3 = z.cross(x).normalized()
	return Basis(x, y, z)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


# --- primitives ---------------------------------------------------------------------------------

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
	_gv = PackedVector3Array()
	_gn = PackedVector3Array()


func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
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


## A (cols + 1) x (rows + 1) vertex grid from pos(i, j) -> Vector3. Smooth normals from the faces, each face turned
## so it agrees with out(face centre) (any direction pointing out of the surface there); equal positions (seams, poles)
## share one normal.
func _grid(cols: int, rows: int, pos: Callable, out: Callable) -> Array:
	var v := PackedVector3Array()
	for j: int in rows + 1:
		for i: int in cols + 1:
			v.append(pos.call(i, j))
	var n := PackedVector3Array()
	n.resize(v.size())
	var idx := PackedInt32Array()
	for j: int in rows:
		for i: int in cols:
			var a: int = j * (cols + 1) + i
			var b: int = a + 1
			var c: int = a + cols + 1
			var d: int = c + 1
			for tri: Array in [[a, c, b], [b, c, d]]:
				var p0: Vector3 = v[tri[0]]
				var p1: Vector3 = v[tri[1]]
				var p2: Vector3 = v[tri[2]]
				var fn: Vector3 = (p1 - p0).cross(p2 - p0)
				if fn.length_squared() < 1e-12:
					continue
				var o: Vector3 = out.call((p0 + p1 + p2) / 3.0)
				if fn.dot(o) < 0.0:
					fn = -fn
				for k: int in tri:
					n[k] += fn
				idx.append_array(tri)
	var acc := {}
	for i: int in v.size():
		var key: Vector3 = v[i].snappedf(0.0005)
		acc[key] = (acc.get(key, Vector3.ZERO) as Vector3) + n[i]
	for i: int in v.size():
		var s: Vector3 = acc[v[i].snappedf(0.0005)]
		n[i] = s.normalized() if s.length_squared() > 1e-12 else Vector3.UP
	return _mk(v, n, idx)


## A closed sculpted blob: sculpt(unit direction) -> position (phi = 0 is +Z, phi = 90 deg is +X).
func _sculpt_mesh(cols: int, rows: int, sculpt: Callable, centre: Vector3 = Vector3.ZERO) -> Array:
	return _grid(cols, rows, func(i: int, j: int) -> Vector3:
		var th: float = PI * float(j) / float(rows)
		var ph: float = TAU * float(i) / float(cols)
		return sculpt.call(Vector3(sin(th) * sin(ph), cos(th), sin(th) * cos(ph))),
		func(q: Vector3) -> Vector3: return q - centre)


func _sculpt_normal(sculpt: Callable, p: Vector3) -> Vector3:
	var t1: Vector3 = p.cross(Vector3.UP if absf(p.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2: Vector3 = p.cross(t1).normalized()
	var e: float = 0.01
	var a: Vector3 = (sculpt.call((p + t1 * e).normalized()) as Vector3) - (sculpt.call((p - t1 * e).normalized()) as Vector3)
	var b: Vector3 = (sculpt.call((p + t2 * e).normalized()) as Vector3) - (sculpt.call((p - t2 * e).normalized()) as Vector3)
	var n: Vector3 = a.cross(b).normalized()
	return n if n.dot(p) >= 0.0 else -n


## A torus in the XZ plane (major radius R, minor r).
func _torus(big_r: float, r: float, cols: int = 14, rows: int = 6) -> Array:
	return _grid(cols, rows, func(i: int, j: int) -> Vector3:
		var u: float = TAU * float(i) / float(cols)
		var w: float = TAU * float(j) / float(rows)
		return Vector3((big_r + r * cos(w)) * cos(u), r * sin(w), (big_r + r * cos(w)) * sin(u)),
		func(q: Vector3) -> Vector3:
			var u2: float = atan2(q.z, q.x)
			return q - Vector3(cos(u2), 0.0, sin(u2)) * big_r)


## A chiselled rock chunk (low-poly ellipsoid cut by random planes + a flat top).
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


## A jagged broken end: ring of radius r at y 0, a jagged rim (0.3..1 x h) and a sunken centre.
func _broken_end(r: float, h: float, segs: int, seed: float) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for i: int in segs:
		var a: float = i * TAU / segs
		v.append(Vector3(cos(a) * r, 0, sin(a) * r))
		n.append(Vector3(cos(a), 0, sin(a)))
	for i: int in segs:
		var a: float = i * TAU / segs
		var hh: float = h * (0.3 + 0.7 * _h(Vector3(i, seed, 1.0)))
		var rr: float = r * (0.9 + 0.08 * _h(Vector3(i, seed, 2.0)))
		v.append(Vector3(cos(a) * rr, hh, sin(a) * rr))
		n.append(Vector3(cos(a), 0.3, sin(a)).normalized())
	for i: int in segs:
		var j: int = (i + 1) % segs
		idx.append_array([i, j, segs + i, j, segs + j, segs + i])
	var cbase: int = v.size()
	v.append(Vector3(r * 0.1, h * 0.25, -r * 0.08))
	n.append(Vector3.UP)
	for i: int in segs:
		v.append(v[segs + i])
		n.append(Vector3.UP)
	for i: int in segs:
		idx.append_array([cbase, cbase + 1 + i, cbase + 1 + (i + 1) % segs])
	return _mk(v, n, idx)


# --- mesh accumulation --------------------------------------------------------------------------

## Adds mesh arrays, transformed, to surface 0. Options: kind (Kind), normals "flat" | "smooth", moss (stone moss
## 0-1), wind (Vector2 y0, y1: foliage sway weight 0 at y0 -> 1 at y1; default 0 = still), jitter + seed + jit_axes,
## col2 + grad ("y" part height | "r" distance from the part's axis), tint (random value variation), no_caps
## (drop the +-Y caps of cylinders), vcol (Callable(local: Vector3, col: Color) -> Color, per vertex).
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.STONE)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var jit_axes: Vector3 = o.get("jit_axes", Vector3.ONE)
	var mode: String = o.get("normals", "flat")
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var moss: float = float(o.get("moss", 0.0)) * _moss_k
	var wind: Vector2 = o.get("wind", Vector2.ZERO)
	var no_caps: bool = o.get("no_caps", false)
	var tint: float = o.get("tint", 0.08)
	var vcol: Callable = o.get("vcol", Callable())
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
		var p: Vector3 = v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter * jit_axes
		tv[i] = xf * p
		tn[i] = (nb * n[i]).normalized()
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
		var fk: float = 1.0 + (_h(((tv[a] + tv[b] + tv[c]) / 3.0).snappedf(0.01)) - 0.5) * tint
		for vi: int in [a, b, c]:
			var nn: Vector3 = fn if mode == "flat" else tn[vi]
			var gt: float = 0.0
			if grad == "y":
				gt = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
			else:
				gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
			var cc: Color = col.lerp(col2, gt)
			if vcol.is_valid():
				cc = vcol.call(v[vi], cc)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k))
			var w: float = moss
			if kind != Kind.STONE:
				w = 0.0
				if wind.y > wind.x:
					w = pow(clampf((tv[vi].y - wind.x) / (wind.y - wind.x), 0.0, 1.0), 1.6)
			_w.append(w)
			_uv2.append(Vector2(0.0, kind))


## Adds mesh arrays to the glow surface (surface 2).
func _glow_part(arr: Array, xf: Transform3D) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nb: Basis = xf.basis.inverse().transposed()
	for t: int in range(0, idx.size(), 3):
		var ids: Array[int] = [idx[t], idx[t + 1], idx[t + 2]]
		var p0: Vector3 = xf * v[ids[0]]
		var p1: Vector3 = xf * v[ids[1]]
		var p2: Vector3 = xf * v[ids[2]]
		var ns: Vector3 = nb * (n[ids[0]] + n[ids[1]] + n[ids[2]])
		var fn: Vector3 = (p1 - p0).cross(p2 - p0)
		if fn.length_squared() < 1e-12:
			continue
		var s: float = 1.0 if fn.dot(ns) >= 0.0 else -1.0
		if s != _conv:
			var tmp: int = ids[1]
			ids[1] = ids[2]
			ids[2] = tmp
		for k: int in ids:
			_gv.append(xf * v[k])
			_gn.append((nb * n[k]).normalized())


## A limb (tapered cylinder) from a to b, smooth; a, b in the space `xf` maps from.
func _limb(a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Color, o: Dictionary = {},
		xf: Transform3D = Transform3D.IDENTITY) -> void:
	var oo: Dictionary = o.duplicate()
	oo["no_caps"] = true
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	_part(_cyl(r1, r0, a.distance_to(b), segs), xf * Transform3D(_along(a, b), (a + b) * 0.5), col, oo)


## Soft contact shadow (surface 1): an irregular disc just above the ground.
func _disc(c: Vector3, rx: float, rz: float, segs: int, seed: float) -> void:
	var ring: Array[Vector3] = []
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.25
		ring.append(Vector3(c.x + cos(a) * rx * j, 0.035, c.z + sin(a) * rz * j))
	var centre := Vector3(c.x, 0.035, c.z)
	for i: int in segs:
		var p1: Vector3 = ring[i]
		var p2: Vector3 = ring[(i + 1) % segs]
		var fn: Vector3 = (p1 - centre).cross(p2 - centre)
		var up: bool = fn.y >= 0.0
		var tri: Array = [centre, p1, p2] if (1.0 if up else -1.0) == _conv else [centre, p2, p1]
		var uvs: Array[float] = [0.0, 1.0, 1.0]
		for k: int in 3:
			_cv.append(tri[k])
			_cn.append(Vector3.UP)
			_cuv.append(Vector2(uvs[k], 0.0))
			_cuv2.append(Vector2.ZERO)


## A painted crack: a thin dark ribbon laid on a sculpt (Callable(unit dir) -> Vector3) along the great-circle path
## through `dirs`, lifted a little off the surface. Returns arrays in sculpt space.
func _crack(sculpt: Callable, dirs: Array, width: float, seed: float, lift: float = 0.02) -> Array:
	var pts: Array[Vector3] = []
	var nrm: Array[Vector3] = []
	for k: int in dirs.size() - 1:
		var a: Vector3 = (dirs[k] as Vector3).normalized()
		var b: Vector3 = (dirs[k + 1] as Vector3).normalized()
		var steps: int = maxi(3, int(a.angle_to(b) / 0.045))
		var last: int = steps + (1 if k == dirs.size() - 2 else 0)
		for s: int in last:
			var p: Vector3 = a.slerp(b, float(s) / float(steps))
			var side0: Vector3 = p.cross(b - a).normalized()
			p = (p + side0 * (_h(p * 13.0 + Vector3(seed, 0.0, 0.0)) - 0.5) * 0.03).normalized()
			pts.append(sculpt.call(p))
			nrm.append(_sculpt_normal(sculpt, p))
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for i: int in pts.size():
		var tdir: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var side: Vector3 = nrm[i].cross(tdir).normalized()
		var u: float = float(i) / float(maxi(pts.size() - 1, 1))
		var w: float = width * (0.25 + 0.75 * sin(PI * clampf(u, 0.0, 1.0)))
		var c: Vector3 = pts[i] + nrm[i] * lift
		v.append(c - side * w * 0.5)
		v.append(c + side * w * 0.5)
		n.append(nrm[i])
		n.append(nrm[i])
	for i: int in pts.size() - 1:
		var a2: int = i * 2
		idx.append_array([a2, a2 + 2, a2 + 1, a2 + 1, a2 + 2, a2 + 3])
	return _mk(v, n, idx)


## An ember rune: glowing strokes (surface 2) over a slightly wider dark carved groove (surface 0), laid on a surface
## at c facing n, `size` metres tall. Space: whatever `xf` maps from.
## glow = false: a dead rune (Art Lab R5, landmarks 0-3 glow points): the same groove with a dull burnt-ember painted
## inlay on surface 0, so only the two big sigils (brow medallion, palm) glow and they read as the landmark's 2 points.
func _glyph(strokes: Array, c: Vector3, n: Vector3, up_hint: Vector3, size: float, xf: Transform3D,
		sw: float = 0.075, glow: bool = true) -> void:
	var nn: Vector3 = n.normalized()
	var up: Vector3 = (up_hint - nn * up_hint.dot(nn)).normalized()
	var right: Vector3 = up.cross(nn).normalized()
	for s: Array in strokes:
		var a2: Vector2 = s[0]
		var b2: Vector2 = s[1]
		var p0: Vector3 = c + (right * a2.x + up * a2.y) * size
		var p1: Vector3 = c + (right * b2.x + up * b2.y) * size
		var y: Vector3 = (p1 - p0)
		var len: float = y.length()
		y = y.normalized()
		var x: Vector3 = y.cross(nn).normalized()
		var z: Vector3 = x.cross(y).normalized()
		var b := Basis(x, y, z)
		var mid: Vector3 = (p0 + p1) * 0.5
		_part(_box(Vector3(sw + 0.03, len + sw + 0.03, 0.04)), xf * Transform3D(b, mid), GROOVE,
			{"kind": Kind.STONE, "tint": 0.0})
		if glow:
			_glow_part(_box(Vector3(sw, len + sw * 0.6, 0.04)), xf * Transform3D(b, mid + nn * 0.012))
		else:
			_part(_box(Vector3(sw, len + sw * 0.6, 0.04)), xf * Transform3D(b, mid + nn * 0.012), DEAD_RUNE,
				{"kind": Kind.STONE, "moss": 0.0, "tint": 0.0})


## Where a mesh (arrays in its own space, placed by xf) cuts the ground plane y = 0: the crossing points of its edges.
func _ground_cut(arr: Array, xf: Transform3D) -> PackedVector3Array:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var out := PackedVector3Array()
	for t: int in range(0, idx.size(), 3):
		for e: int in 3:
			var a: Vector3 = xf * v[idx[t + e]]
			var b: Vector3 = xf * v[idx[t + (e + 1) % 3]]
			if (a.y > 0.0) != (b.y > 0.0):
				var f: float = a.y / (a.y - b.y)
				out.append(a.lerp(b, f))
	return out


## Spoil where a sunk mass meets the ground: a few small, low earth clods along the ground cut (pushed out from
## `centre`, at least `spacing` apart), bare dirt with a little grass on top.
func _berm(cut: PackedVector3Array, centre: Vector3, spacing: float, size: float, seed: float) -> void:
	var picked: Array[Vector3] = []
	for p: Vector3 in cut:
		var ok: bool = true
		for q: Vector3 in picked:
			if Vector2(p.x - q.x, p.z - q.z).length() < spacing:
				ok = false
				break
		if ok:
			picked.append(p)
	var i: int = 0
	for p: Vector3 in picked:
		var out: Vector3 = Vector3(p.x - centre.x, 0.0, p.z - centre.z).normalized()
		var s: float = size * (0.7 + 0.6 * _h(Vector3(seed, i, 1.0)))
		var pos: Vector3 = p + out * s * 0.9 + Vector3(0.0, -s * 0.12, 0.0)
		_part(_chunk(Vector3(s, s * 0.45, s * 0.8), 4, seed + i * 1.7, 0.72, 6, 3),
			Transform3D(Basis(Vector3.UP, atan2(out.x, out.z) + 1.3 * i), pos),
			DIRT.lerp(DIRT_D, _h(Vector3(i, seed, 3.0))), {"kind": Kind.STONE, "moss": 0.35, "seed": seed + i, "tint": 0.1})
		i += 1


## Moss cushion / ivy clump (foliage shading, no wind); pos in the space `xf` maps from.
func _moss(pos: Vector3, r: float, squash: Vector3, seed: float, col: Color = MOSS,
		xf: Transform3D = Transform3D.IDENTITY) -> void:
	_part(_sph(r, 8, 4), xf * _xf(pos, Vector3(0.0, seed, 0.0), squash), col, {"kind": Kind.IVY, "normals": "smooth",
		"jitter": r * 0.1, "seed": seed, "col2": col.lerp(MOSS_L, 0.6), "grad": "y"})


## Bakes the height gradient (COLOR.a, 0 at the ground -> 1 at the top), moss / wind (UV.x), local height (UV.y) and
## kind (UV2.y); saves meshes/<name>.res with its surfaces (0 painted, 1 contact, 2 glow if any).
func _commit(name: String) -> ArrayMesh:
	var maxy: float = 0.01
	for p: Vector3 in _v:
		maxy = maxf(maxy, p.y)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = clampf(_v[i].y / maxy, 0.0, 1.0)
		_c[i] = cc
		uv[i] = Vector2(_w[i], _v[i].y)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = _uv2
	var mesh := ArrayMesh.new()
	var welded: Array = _weld(arrays)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, welded)
	mesh.surface_set_material(0, mat)
	var tris: int = _v.size() / 3
	var ctris: int = 0
	var gtris: int = 0
	if not _cv.is_empty():
		var ca: Array = []
		ca.resize(Mesh.ARRAY_MAX)
		ca[Mesh.ARRAY_VERTEX] = _cv
		ca[Mesh.ARRAY_NORMAL] = _cn
		ca[Mesh.ARRAY_TEX_UV] = _cuv
		ca[Mesh.ARRAY_TEX_UV2] = _cuv2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(ca))
		mesh.surface_set_material(mesh.get_surface_count() - 1, contact_mat)
		ctris = _cv.size() / 3
	if not _gv.is_empty():
		var ga: Array = []
		ga.resize(Mesh.ARRAY_MAX)
		ga[Mesh.ARRAY_VERTEX] = _gv
		ga[Mesh.ARRAY_NORMAL] = _gn
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(ga))
		mesh.surface_set_material(mesh.get_surface_count() - 1, rune_mat)
		gtris = _gv.size() / 3
	mesh = _save_ref(mesh, MESH_DIR + name + ".res") as ArrayMesh
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-12s %5d tris (%d verts), contact %d, glow %d, aabb %s .. %s" % [name, tris,
		(welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), ctris, gtris, aabb.position, aabb.end])
	return mesh


## Non-indexed triangle arrays -> indexed, merging vertices whose every attribute matches.
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


# --- scenes -------------------------------------------------------------------------------------

func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


## art/environment/landmarks/<name>.tscn: Node3D (group "landmarks", metadata) > Model (MeshInstance3D) + Collision
## (StaticBody3D on layer 1) > one CollisionShape3D per [name, shape, transform].
func _scene(name: String, mesh: Mesh, shapes: Array, id: StringName, clear_r: float) -> void:
	var root := Node3D.new()
	root.name = name.to_pascal_case()
	root.add_to_group(&"landmarks", true)
	root.set_meta(&"landmark_id", id)
	root.set_meta(&"decor_clear_radius", clear_r)
	var mi := MeshInstance3D.new()
	mi.name = "Model"
	mi.mesh = mesh
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	root.add_child(mi)
	var body := StaticBody3D.new()
	body.name = "Collision"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	for s: Array in shapes:
		var cs := CollisionShape3D.new()
		cs.name = s[0]
		cs.shape = s[1]
		cs.transform = s[2]
		body.add_child(cs)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, LDIR + name + ".tscn")
	root.free()


# =================================================================================================
# Fallen Colossus
# =================================================================================================

## The head, sculpted from a unit direction (head space: +Y crown, +Z face, +X one ear). Bold, carved features (a
## stern king: heavy brow, deep sockets, broad cheekbones, a square jaw) so the face reads from the RTS camera.
func _head_pos(p: Vector3) -> Vector3:
	var q: Vector3 = p * HR
	# Face flatter and broad, back of the skull fuller.
	if p.z > 0.0:
		q.z -= HR.z * 0.24 * pow(p.z, 3.0)
	else:
		q.z *= 1.04
	# Lower head narrower, the jaw square and forward.
	var low: float = _ss(0.05, -0.85, p.y)
	q.x *= 1.0 - 0.14 * low
	q.z += 0.16 * low * maxf(p.z, 0.0) * HR.z
	return q + p * _head_relief(p)


## Radial relief of the face features (also drives the painted occlusion in _head_ao).
func _head_relief(p: Vector3) -> float:
	var brow: float = exp(-pow((p.y - 0.30) / 0.09, 2.0)) * _ss(0.50, 0.82, p.z) * _ss(0.78, 0.2, absf(p.x))
	var eyes: float = _bump(p, Vector3(0.34, 0.13, 0.93), 0.17) + _bump(p, Vector3(-0.34, 0.13, 0.93), 0.17)
	var cheeks: float = _bump(p, Vector3(0.56, -0.14, 0.80), 0.19) + _bump(p, Vector3(-0.56, -0.14, 0.80), 0.19)
	var chin: float = _bump(p, Vector3(0.0, -0.80, 0.60), 0.22)
	var temple: float = _bump(p, Vector3(0.80, 0.30, 0.52), 0.18) + _bump(p, Vector3(-0.80, 0.30, 0.52), 0.18)
	return 0.30 * brow - 0.42 * eyes + 0.16 * cheeks + 0.12 * chin - 0.08 * temple


## Painted occlusion on the face: dark sockets, shadow under the brow, beside the nose.
func _head_ao(q: Vector3, c: Color) -> Color:
	var p: Vector3 = (q / HR).normalized()
	var eyes: float = _bump(p, Vector3(0.34, 0.12, 0.93), 0.15) + _bump(p, Vector3(-0.34, 0.12, 0.93), 0.15)
	var nose_side: float = _bump(p, Vector3(0.2, -0.22, 0.96), 0.12) + _bump(p, Vector3(-0.2, -0.22, 0.96), 0.12)
	var brow_sh: float = exp(-pow((p.y - 0.20) / 0.07, 2.0)) * _ss(0.6, 0.85, p.z) * _ss(0.6, 0.15, absf(p.x))
	var k: float = 1.0 - 0.7 * clampf(eyes, 0.0, 1.0) - 0.3 * clampf(nose_side, 0.0, 1.0) - 0.2 * brow_sh
	return Color(c.r * k, c.g * k, c.b * k)


func _head_n(p: Vector3) -> Vector3:
	return _sculpt_normal(_head_pos, p)


## The crown band's mid height (as the y of a unit direction) around the head: lower at the brow, higher behind.
func _band_py(phi: float) -> float:
	return 0.66 - 0.06 * cos(phi)


func _band_dir(phi: float, py: float) -> Vector3:
	var s: float = sqrt(maxf(1.0 - py * py, 0.0))
	return Vector3(sin(phi) * s, py, cos(phi) * s)


## A point on the crown band: phi around the head (0 = the brow), row 0 = bottom, 1 = top; off = out from the skull.
func _band_point(phi: float, py: float, off: float) -> Vector3:
	var p: Vector3 = _band_dir(phi, py)
	return _head_pos(p) + _head_n(p) * off


func _palm_pos(p: Vector3) -> Vector3:
	var q := Vector3(_spow(p.x, 0.62) * 0.70, _spow(p.y, 0.85) * 0.30, _spow(p.z, 0.62) * 0.80)
	# A cupped palm, a thenar pad by the thumb, the heel of the hand, knuckles at the finger end.
	if p.y > 0.0:
		q.y -= 0.13 * exp(-(p.x * p.x + (p.z + 0.1) * (p.z + 0.1)) / 0.30) * p.y
	q += p * (0.12 * _bump(p, Vector3(0.62, 0.55, -0.35), 0.45) + 0.07 * _bump(p, Vector3(-0.35, 0.5, -0.75), 0.4)
		+ 0.05 * _bump(p, Vector3(0.0, 0.45, 0.85), 0.35))
	return q + Vector3(0.0, 0.14, -0.22)


func _build_colossus() -> void:
	_begin()
	var tilt: float = deg_to_rad(FACE_TILT)
	var hb := Basis(Vector3(0.0, -cos(tilt), sin(tilt)), Vector3(1.0, 0.0, 0.0), Vector3(0.0, sin(tilt), cos(tilt)))
	var yaw := Basis(Vector3.UP, atan2(-CROWN_DIR.z, CROWN_DIR.x))
	_head_xf = Transform3D(yaw * hb, HEAD_CENTER + Vector3(0.0, HEAD_Y, 0.0))
	_hand_xf = Transform3D(Basis(Vector3.UP, atan2(HAND_DIR.x, HAND_DIR.z)) * Basis(Vector3.RIGHT, -0.07), HAND_CENTER)
	# Art Lab R3 / P3: less sky-facing moss on the colossus (it sat in the grass hue, hue gap 1 deg, and darkened
	# the tops): the pale limestone reads as the key mass, the moss stays as accents (eyes, creases, rubble).
	_moss_k = COLOSSUS_MOSS_K
	_build_head()
	_build_hand()
	_build_colossus_rubble()
	_moss_k = 1.0
	_disc(Vector3(0.0, 0.0, 0.0), 3.9, 3.6, 16, 3.0)
	var mesh: ArrayMesh = _commit("colossus")
	var head_shape := CylinderShape3D.new()
	head_shape.radius = HEAD_R
	head_shape.height = HEAD_H
	var hand_shape := BoxShape3D.new()
	hand_shape.size = Vector3(HAND_W, HAND_H, HAND_L)
	_scene("colossus", mesh, [
		["Head", head_shape, Transform3D(Basis(), HEAD_CENTER + Vector3(0.0, HEAD_H * 0.5 - 0.2, 0.0))],
		["Hand", hand_shape, Transform3D(Basis(Vector3.UP, atan2(HAND_DIR.x, HAND_DIR.z)),
			HAND_CENTER + Vector3(0.0, HAND_H * 0.5 - 0.2, 0.0))],
	], &"lm_colossus", 4.2)


func _build_head() -> void:
	var hx: Transform3D = _head_xf
	var stone := {"kind": Kind.STONE, "normals": "smooth", "moss": 0.75, "tint": 0.05}
	# The skull and face (one sculpted surface).
	var head_arr: Array = _sculpt_mesh(42, 30, _head_pos)
	var hs: Dictionary = stone.duplicate()
	hs["vcol"] = _head_ao
	_part(head_arr, hx, STONE_W, hs)
	# Nose: a big carved wedge from the brow, its tip chipped flat.
	var nf: float = _head_pos(Vector3(0.0, -0.2, 1.0).normalized()).z - 0.08
	var nv := PackedVector3Array([Vector3(0.0, 0.30, nf - 0.02), Vector3(-0.09, -0.34, nf + 0.60),
		Vector3(0.09, -0.34, nf + 0.60), Vector3(-0.34, -0.50, nf + 0.02), Vector3(0.34, -0.50, nf + 0.02),
		Vector3(0.0, -0.56, nf + 0.30), Vector3(-0.17, 0.26, nf - 0.2), Vector3(0.17, 0.26, nf - 0.2)])
	var nidx := PackedInt32Array([0, 3, 1, 0, 1, 2, 0, 2, 4, 1, 3, 5, 1, 5, 2, 2, 5, 4, 3, 6, 0, 4, 0, 7, 3, 4, 5])
	var nn := PackedVector3Array()
	for p: Vector3 in nv:
		nn.append((p - Vector3(0.0, -0.2, nf)).normalized())
	_part(_mk(nv, nn, nidx), hx, STONE_W, {"kind": Kind.STONE, "moss": 0.3, "tint": 0.07})
	# Moustache: two heavy rolls drooping into the beard; a dark mouth line between them and the lower lip.
	var mz: float = _head_pos(Vector3(0.0, -0.42, 0.9).normalized()).z
	for s: float in [-1.0, 1.0]:
		_part(_sph(1.0, 9, 5), hx * _xf(Vector3(0.36 * s, -0.70, mz - 0.02), Vector3(0.1, -0.25 * s, -0.45 * s),
			Vector3(0.50, 0.17, 0.24)), STONE_S, {"kind": Kind.STONE, "normals": "smooth", "moss": 0.5, "tint": 0.04})
	_part(_sph(1.0, 8, 4), hx * _xf(Vector3(0.0, -0.86, mz - 0.1), Vector3.ZERO, Vector3(0.34, 0.12, 0.16)), GROOVE,
		{"kind": Kind.STONE, "normals": "smooth", "tint": 0.0})
	# Beard: a long square-cut mass with carved fluting, hanging from the jaw.
	var beard_c := func(t: float) -> Vector3: return Vector3(0.0, lerpf(-0.62, -2.30, t), lerpf(mz - 0.5, mz - 0.3, t) + 0.12 * sin(t * PI))
	var beard: Array = _grid(24, 8, func(i: int, j: int) -> Vector3:
		var t: float = float(j) / 8.0
		var a: float = TAU * float(i) / 24.0
		var rx: float = lerpf(1.08, 0.46, pow(t, 0.9))
		var rz: float = lerpf(0.60, 0.30, t)
		var flute: float = 1.0 + 0.10 * cos(a * 8.0)
		if j == 8:
			rx *= 0.55
			rz *= 0.55
		return beard_c.call(t) + Vector3(_spow(sin(a), 0.7) * rx * flute, 0.0, _spow(cos(a), 0.7) * rz * flute),
		func(q: Vector3) -> Vector3:
			var t2: float = clampf((q.y + 0.62) / -1.68, 0.0, 1.0)
			var c2: Vector3 = beard_c.call(t2)
			return q - Vector3(c2.x, q.y if t2 < 0.99 else c2.y + 0.3, c2.z))
	_part(beard, hx, STONE_S, {"kind": Kind.STONE, "normals": "smooth", "moss": 0.6, "tint": 0.06})
	# Three thick braids down the front of the beard.
	for bx: float in [-0.42, 0.0, 0.42]:
		var n_l: int = 6
		for l: int in n_l:
			var t3: float = 0.14 + 0.78 * float(l) / float(n_l - 1)
			var c3: Vector3 = beard_c.call(t3)
			var rx3: float = lerpf(1.08, 0.46, pow(t3, 0.9))
			var rz3: float = lerpf(0.60, 0.30, t3)
			var x3: float = bx * rx3 / 1.08 * 1.6
			var lr: float = lerpf(0.2, 0.12, t3)
			# Plaited: long lumps leaning alternately left / right, overlapping.
			_part(_sph(1.0, 7, 4), hx * _xf(c3 + Vector3(x3, 0.0, rz3 * 0.9), Vector3(0.0, 0.0, 0.45 * (1 - 2 * (l % 2))),
				Vector3(lr * 0.95, lr * 1.75, lr * 0.7)), STONE_S.lerp(STONE_C, 0.35), {"kind": Kind.STONE,
				"normals": "smooth", "moss": 0.55, "tint": 0.05})
	# Beard ring (verdigris), low on the beard.
	var rc: Vector3 = beard_c.call(0.78)
	_part(_cyl(1.0, 1.0, 0.24, 14), hx * _xf(rc, Vector3.ZERO, Vector3(lerpf(1.08, 0.46, pow(0.78, 0.9)) * 1.1, 1.0,
		lerpf(0.60, 0.30, 0.78) * 1.14)), PATINA, {"kind": Kind.STONE, "moss": 0.1, "tint": 0.06})
	# Ears (+X ear is in the ground), the upper one with a big verdigris ring.
	for s2: float in [-1.0, 1.0]:
		_part(_sph(1.0, 8, 5), hx * _xf(Vector3(1.28 * s2, 0.0, -0.05), Vector3(0.0, 0.2 * s2, 0.0),
			Vector3(0.17, 0.44, 0.30)), STONE_C, {"kind": Kind.STONE, "normals": "smooth", "moss": 0.6, "tint": 0.04})
	_part(_torus(0.24, 0.065, 14, 6), hx * _xf(Vector3(-1.40, -0.55, 0.0), Vector3(0.0, 0.0, 1.35)), PATINA,
		{"kind": Kind.STONE, "normals": "smooth", "moss": 0.1, "tint": 0.04})
	# Hair: thick carved locks over the back of the skull + a braid from the nape.
	for k: int in 7:
		var phi: float = PI + (k - 3) * 0.30
		var p: Vector3 = _band_dir(phi, -0.05)
		var base: Vector3 = _head_pos(p) - p * 0.12
		var b := Basis(Vector3(cos(phi), 0.0, -sin(phi)), Vector3.UP, Vector3(sin(phi), 0.0, cos(phi)))
		_part(_sph(1.0, 8, 6), hx * Transform3D(b * Basis(Vector3.BACK, (k - 3) * 0.05) * Basis.from_scale(
			Vector3(0.30, 1.30, 0.26)), base + Vector3(0.0, 0.05 * (k % 2), 0.0)), STONE_S.lerp(STONE_C, 0.3 * (k % 2)),
			{"kind": Kind.STONE, "normals": "smooth", "moss": 0.8, "tint": 0.04})
	var braid: Array[Vector3] = [Vector3(0.1, -1.05, -1.18), Vector3(0.15, -1.45, -1.12), Vector3(0.18, -1.83, -1.0),
		Vector3(0.2, -2.18, -0.86), Vector3(0.22, -2.5, -0.7)]
	for k2: int in braid.size():
		var r: float = 0.24 - k2 * 0.025
		_part(_sph(r, 7, 4), hx * _xf(braid[k2], Vector3(0.3, k2 * 0.9, 0.0), Vector3(1.0, 1.25, 0.9)), STONE_S,
			{"kind": Kind.STONE, "normals": "smooth", "moss": 0.6, "tint": 0.05})
	# Neck: a thick column snapped off, the break a lighter fresh stone.
	var n0 := Vector3(0.0, -0.95, -0.32)
	var n1 := Vector3(0.0, -2.02, -0.46)
	_part(_cyl(0.92, 0.98, n0.distance_to(n1), 12, 2), hx * Transform3D(_along(n1, n0), (n0 + n1) * 0.5), STONE_C,
		{"kind": Kind.STONE, "normals": "smooth", "moss": 0.5, "no_caps": true})
	_part(_broken_end(0.97, 0.34, 12, 5.0), hx * Transform3D(_along(n0, n1), n1), STONE_F,
		{"kind": Kind.STONE, "moss": 0.25, "jitter": 0.04, "seed": 5.0})
	# Crown: a verdigris band with points, two snapped.
	var band: Array = _grid(40, 3, func(i: int, j: int) -> Vector3:
		var phi2: float = TAU * float(i) / 40.0
		var py: float = _band_py(phi2) + (-0.11 if j < 2 else 0.11)
		var off: float = [-0.03, 0.15, 0.13, -0.03][j]
		return _band_point(phi2, py, off),
		func(q: Vector3) -> Vector3:
			var phi3: float = atan2(q.x, q.z)
			return Vector3(q.x, 0.0, q.z).normalized() * 0.2 + Vector3(0.0, q.y - _band_py(phi3) * HR.y, 0.0))
	_part(band, hx, PATINA, {"kind": Kind.STONE, "normals": "flat", "moss": 0.15, "tint": 0.07,
		"vcol": func(q: Vector3, c: Color) -> Color: return c.lerp(PATINA_D, 0.55) if q.y < _band_py(atan2(q.x, q.z)) * HR.y - 0.1 else c})
	var spikes: Array = [[0.0, 0.78, false], [0.55, 0.62, false], [-0.55, 0.62, false], [1.1, 0.55, true],
		[-1.1, 0.5, false], [1.65, 0.48, false], [-1.65, 0.45, true], [2.3, 0.42, false], [-2.3, 0.42, false],
		[PI, 0.4, false]]
	for sp: Array in spikes:
		var phi4: float = sp[0]
		var h: float = sp[1]
		var broken: bool = sp[2]
		var bp: Vector3 = _band_point(phi4, _band_py(phi4) + 0.09, 0.05)
		var radial: Vector3 = Vector3(sin(phi4), 0.0, cos(phi4))
		var axis: Vector3 = (Vector3.UP + radial * 0.32).normalized()
		var top_r: float = 0.08 if broken else 0.012
		var hh: float = h * (0.45 if broken else 1.0)
		_part(_cyl(top_r, 0.17, hh, 4), hx * Transform3D(_along(bp, bp + axis) * Basis(Vector3.UP, PI * 0.25),
			bp + axis * hh * 0.5), PATINA, {"kind": Kind.STONE, "moss": 0.0, "tint": 0.08, "col2": PATINA.lightened(0.12)})
	# Front medallion with the big ember sigil, and runes all round the band.
	var mp: Vector3 = _band_point(0.0, _band_py(0.0), 0.15)
	var mn: Vector3 = _head_n(_band_dir(0.0, _band_py(0.0)))
	_part(_cyl(0.27, 0.31, 0.12, 10), hx * Transform3D(_along(mp, mp + mn), mp), PATINA_D,
		{"kind": Kind.STONE, "moss": 0.0, "tint": 0.05})
	var sig: Vector3 = mp + mn * 0.065
	var ring: Array = []
	for k3: int in 8:
		var a0: float = k3 * TAU / 8.0 + 0.2
		var a1: float = a0 + TAU / 8.0 * 0.6
		ring.append([Vector2(cos(a0), sin(a0)) * 0.42, Vector2(cos(a1), sin(a1)) * 0.42])
	ring.append([Vector2(0.0, -0.22), Vector2(0.0, 0.26)])
	ring.append([Vector2(-0.16, -0.05), Vector2(0.0, 0.26)])
	ring.append([Vector2(0.16, -0.05), Vector2(0.0, 0.26)])
	_glyph(ring, sig, mn, Vector3.UP, 0.48, hx, 0.05)
	var g: int = 0
	for phi5: float in [0.62, -0.62, 1.3, -1.3, 2.4, -2.4]:
		var gp: Vector3 = _band_point(phi5, _band_py(phi5), 0.15)
		var gn: Vector3 = _head_n(_band_dir(phi5, _band_py(phi5)))
		_glyph(GLYPHS[g % GLYPHS.size()], gp, gn, Vector3.UP, 0.2, hx, 0.045, false)
		g += 1
	# Moss in the eyes (spilling down the cheek like tears), cushions in the ear and on the brow.
	for s3: float in [-1.0, 1.0]:
		var ep: Vector3 = _head_pos(Vector3(0.34 * s3, 0.12, 0.93).normalized())
		_moss(ep + Vector3(0.0, -0.02, 0.04), 0.3, Vector3(1.1, 0.72, 0.5), 11.0 + s3, MOSS, hx)
		_moss(ep + Vector3(0.1 * s3, 0.06, 0.06), 0.14, Vector3(1.0, 0.8, 0.6), 12.0 + s3, MOSS_L, hx)
		_moss(ep + Vector3(-0.12 * s3, -0.06, 0.07), 0.12, Vector3(1.0, 0.9, 0.6), 13.0 + s3, MOSS_L, hx)
		_moss(ep + Vector3(0.05 * s3, -0.32, 0.04), 0.1, Vector3(0.8, 1.5, 0.5), 14.0 + s3, MOSS, hx)
	# Cracks over the forehead, the upturned temple and cheek, the back of the skull.
	var cracks: Array = [
		[Vector3(-0.32, 0.46, 0.83), Vector3(-0.05, 0.40, 0.92), Vector3(0.10, 0.33, 0.95), Vector3(0.12, 0.29, 0.96)],
		[Vector3(-0.72, 0.42, 0.55), Vector3(-0.88, 0.08, 0.47), Vector3(-0.80, -0.28, 0.53), Vector3(-0.66, -0.52, 0.55)],
		[Vector3(-0.88, 0.08, 0.47), Vector3(-0.97, 0.12, 0.15)],
		[Vector3(-0.78, -0.28, 0.54), Vector3(-0.5, -0.3, 0.8)],
		[Vector3(-0.62, 0.45, -0.64), Vector3(-0.92, 0.10, -0.40), Vector3(-0.95, -0.2, -0.25)],
	]
	var ck: int = 0
	for cr: Array in cracks:
		_part(_crack(_head_pos, cr, 0.075 if ck < 2 else 0.05, 20.0 + ck), hx, CRACK,
			{"kind": Kind.STONE, "normals": "smooth", "tint": 0.0})
		ck += 1
	# Earth lip where the head sinks into the heath.
	_berm(_ground_cut(head_arr, hx), HEAD_CENTER, 1.3, 0.2, 30.0)


func _build_hand() -> void:
	var xf: Transform3D = _hand_xf
	var stone := {"kind": Kind.STONE, "normals": "smooth", "moss": 0.8, "tint": 0.05}
	var palm: Array = _sculpt_mesh(22, 14, _palm_pos, Vector3(0.0, 0.14, -0.22))
	_part(palm, xf, STONE_C, stone)
	# Wrist and forearm diving into the ground, a verdigris cuff at the wrist.
	var w0 := Vector3(0.0, 0.10, -0.80)
	var w1 := Vector3(0.0, -1.10, -2.35)
	var fore: Array = _cyl(0.50, 0.58, w0.distance_to(w1), 12, 3)
	var fxf: Transform3D = xf * Transform3D(_along(w1, w0), (w0 + w1) * 0.5)
	_part(fore, fxf, STONE_C, {"kind": Kind.STONE, "normals": "smooth", "moss": 0.7, "no_caps": true})
	var cuff_c: Vector3 = w0.lerp(w1, 0.2)
	_part(_cyl(0.62, 0.64, 0.36, 12), xf * Transform3D(_along(w1, w0), cuff_c), PATINA,
		{"kind": Kind.STONE, "moss": 0.1, "tint": 0.07, "col2": PATINA.lightened(0.08)})
	_part(_cyl(0.66, 0.66, 0.08, 12), xf * Transform3D(_along(w1, w0), cuff_c + (w0 - w1).normalized() * 0.2), PATINA_D,
		{"kind": Kind.STONE, "moss": 0.0, "tint": 0.05})
	var axis: Vector3 = (w0 - w1).normalized()
	var cuff_n: Vector3 = (Vector3.UP - axis * axis.y).normalized()
	_glyph(GLYPHS[1], cuff_c + cuff_n * 0.635, cuff_n, axis, 0.26, xf, 0.06, false)
	# Fingers (index by the thumb at +X), three phalanges curling up; the ring finger snapped off.
	var fx: Array[float] = [0.47, 0.16, -0.16, -0.45]
	var fl: Array[float] = [0.92, 1.02, 0.95, 0.74]
	var fr: Array[float] = [0.155, 0.165, 0.155, 0.135]
	var fy: Array[float] = [0.14, 0.04, -0.06, -0.18]
	var curl: Array[float] = [0.22, 0.40, 0.42]
	var seg: Array[float] = [0.45, 0.30, 0.25]
	for f: int in 4:
		var p: Vector3 = Vector3(fx[f], 0.26, 0.48)
		var d: Vector3 = Vector3(sin(fy[f]), -0.06, cos(fy[f])).normalized()
		var r: float = fr[f]
		var segs: int = 1 if f == 2 else 3
		for k: int in segs:
			d = d.rotated(d.cross(Vector3.UP).normalized(), curl[k] * (0.8 + 0.4 * _h(Vector3(f, k, 1.0))))
			var q: Vector3 = p + d * fl[f] * seg[k]
			_part(_sph(r * 1.12, 8, 5), xf * _xf(p), STONE_C, stone)
			_limb(p, q, r, r * 0.9, 8, STONE_C, {"kind": Kind.STONE, "moss": 0.8, "tint": 0.05}, xf)
			p = q
			r *= 0.9
		if f == 2:
			_part(_broken_end(r * 1.05, 0.12, 8, 9.0), xf * Transform3D(_along(p - d, p), p - d * 0.02), STONE_F,
				{"kind": Kind.STONE, "moss": 0.2, "jitter": 0.015, "seed": 9.0})
		else:
			_part(_sph(r * 1.0, 8, 5), xf * _xf(p), STONE_C, stone)
	# The snapped ring finger lying beside the hand, half in the turf.
	var lp0 := Vector3(-0.98, 0.10, 1.05)
	var lp1 := Vector3(-0.86, 0.14, 1.52)
	_part(_cyl(0.13, 0.14, lp0.distance_to(lp1), 8), xf * Transform3D(_along(lp0, lp1), (lp0 + lp1) * 0.5), STONE_C,
		{"kind": Kind.STONE, "normals": "smooth", "moss": 0.8, "no_caps": true})
	_part(_sph(0.13, 8, 5), xf * _xf(lp1), STONE_C, stone)
	_part(_broken_end(0.14, 0.08, 8, 12.0), xf * Transform3D(_along(lp1, lp0), lp0), STONE_F,
		{"kind": Kind.STONE, "moss": 0.2, "jitter": 0.01, "seed": 12.0})
	# Thumb.
	var t0 := Vector3(0.60, 0.12, -0.30)
	var t1: Vector3 = t0 + Vector3(0.50, 0.45, 0.72).normalized() * 0.46
	var t2: Vector3 = t1 + Vector3(0.22, 0.62, 0.75).normalized() * 0.40
	_part(_sph(0.24, 8, 5), xf * _xf(t0), STONE_C, stone)
	_limb(t0, t1, 0.22, 0.2, 8, STONE_C, {"kind": Kind.STONE, "moss": 0.8, "tint": 0.05}, xf)
	_part(_sph(0.21, 8, 5), xf * _xf(t1), STONE_C, stone)
	_limb(t1, t2, 0.2, 0.17, 8, STONE_C, {"kind": Kind.STONE, "moss": 0.8, "tint": 0.05}, xf)
	_part(_sph(0.17, 8, 5), xf * _xf(t2), STONE_C, stone)
	# The ember sigil in the palm, a crack across it, moss in the creases.
	var pc: Vector3 = _palm_pos(Vector3(0.0, 1.0, 0.0))
	var sig: Array = []
	for k3: int in 7:
		var a0: float = k3 * TAU / 7.0 + 0.3
		var a1: float = a0 + TAU / 7.0 * 0.55
		sig.append([Vector2(cos(a0), sin(a0)) * 0.45, Vector2(cos(a1), sin(a1)) * 0.45])
	sig.append([Vector2(0.0, -0.25), Vector2(0.0, 0.3)])
	sig.append([Vector2(-0.2, 0.0), Vector2(0.0, 0.3)])
	sig.append([Vector2(0.2, 0.0), Vector2(0.0, 0.3)])
	_glyph(sig, pc + Vector3(0.0, 0.012, 0.0), Vector3.UP, Vector3.BACK, 0.52, xf, 0.05)
	_part(_crack(func(p2: Vector3) -> Vector3: return _palm_pos(p2), [Vector3(-0.8, 0.5, -0.4), Vector3(-0.35, 0.9, -0.15),
		Vector3(0.3, 0.85, 0.3), Vector3(0.55, 0.6, 0.62)], 0.06, 40.0, 0.018), xf, CRACK,
		{"kind": Kind.STONE, "normals": "smooth", "tint": 0.0})
	_moss_at(xf * _palm_pos(Vector3(-0.75, 0.62, 0.2).normalized()), 0.16, 41.0)
	_moss_at(xf * _palm_pos(Vector3(0.4, 0.7, 0.6).normalized()), 0.12, 42.0)
	_moss_at(xf * _palm_pos(Vector3(-0.3, 0.75, -0.62).normalized()), 0.14, 43.0)
	# Turf lip along the palm and forearm.
	var cut: PackedVector3Array = _ground_cut(palm, xf)
	cut.append_array(_ground_cut(fore, fxf))
	_berm(cut, HAND_CENTER, 1.1, 0.16, 50.0)


func _moss_at(world: Vector3, r: float, seed: float) -> void:
	_moss(world, r, Vector3(1.2, 0.55, 1.0), seed, MOSS)


func _build_colossus_rubble() -> void:
	# A snapped crown point lying by the head, a chip of the nose, a few shoulder blocks sinking in the turf (all low:
	# units walk around / over them).
	var cp := Vector3(2.35, 0.14, 1.75)
	_part(_cyl(0.012, 0.17, 0.55, 4), Transform3D(_along(cp, cp + Vector3(0.9, 0.12, 0.45).normalized()), cp),
		PATINA, {"kind": Kind.STONE, "moss": 0.0, "tint": 0.08})
	var rocks: Array = [
		[Vector3(-0.15, 0.02, -2.95), Vector3(0.45, 0.30, 0.36), 0.6],
		[Vector3(2.95, 0.0, -1.95), Vector3(0.36, 0.24, 0.30), 1.4],
		[Vector3(-2.95, 0.0, -0.6), Vector3(0.40, 0.26, 0.34), 2.2],
		[Vector3(0.6, 0.0, 2.55), Vector3(0.34, 0.22, 0.28), 3.1],
		[Vector3(-3.25, 0.0, 1.0), Vector3(0.22, 0.16, 0.2), 0.3],
		[Vector3(3.3, 0.0, 0.2), Vector3(0.25, 0.17, 0.2), 1.9],
		[Vector3(-1.2, 0.0, -2.6), Vector3(0.24, 0.16, 0.2), 2.7],
	]
	var i: int = 0
	for r: Array in rocks:
		var rad: Vector3 = r[1]
		_part(_chunk(rad, 5, 60.0 + i, 0.72), _xf(r[0] as Vector3 + Vector3(0.0, rad.y * 0.35, 0.0), Vector3(0.12, r[2], 0.08)),
			STONE_R.lerp(STONE_C, 0.4 * _h(Vector3(i, 1, 1))), {"kind": Kind.STONE, "moss": 0.9, "seed": 60.0 + i, "tint": 0.12})
		i += 1
	# A carved block: a piece of the shoulder drapery, sunk to its folds.
	var bp := Vector3(-2.4, -0.05, -1.75)
	_part(_box(Vector3(1.0, 0.5, 0.62), 1), _xf(bp, Vector3(0.1, 0.7, -0.12)), STONE_C,
		{"kind": Kind.STONE, "moss": 0.85, "jitter": 0.06, "seed": 70.0, "tint": 0.08})


# =================================================================================================
# Giant's Stump
# =================================================================================================

const S_R0 := 1.64
const S_RIDGES := 9
const S_BURROW := 0.5            ## burrow direction (angle, 0 = +Z front, +90 deg = +X): the sunlit front-right


## Buttress ridges (0 in the valleys, 1 on a ridge); flattened into a wide hollow where the burrow is dug.
func _s_ridge(th: float) -> float:
	var near_burrow: float = absf(wrapf(th - S_BURROW, -PI, PI))
	return pow(0.5 + 0.5 * cos(S_RIDGES * th + 0.4), 2.5) * _ss(0.2, 0.55, near_burrow)


func _s_top(th: float) -> float:
	return 2.0 + 0.09 * sin(th + 0.6) + 0.03 * sin(th * 4.0 + 1.1)


func _s_radius(th: float, y: float) -> float:
	var flare: float = exp(-maxf(y, 0.0) / 0.34)
	var rg: float = _s_ridge(th)
	return S_R0 + 0.12 * rg + flare * (0.10 + 0.52 * rg) + 0.04 * sin(3.0 * th + 1.3) + 0.03 * sin(7.0 * th + y * 3.0)


func _s_inner(th: float) -> float:
	return 1.02 + 0.10 * sin(2.0 * th + 0.5) + 0.06 * sin(5.0 * th)


func _s_dir(th: float) -> Vector3:
	return Vector3(sin(th), 0.0, cos(th))


func _s_surface(th: float, y: float) -> Vector3:
	return _s_dir(th) * _s_radius(th, y) + Vector3(0.0, y, 0.0)


func _build_stump() -> void:
	_begin()
	var cols: int = 54
	var fr: Array[float] = [0.0, 0.13, 0.2, 0.3, 0.42, 0.56, 0.7, 0.85, 1.0]
	# Trunk: fluted buttresses flaring into the ground.
	var trunk: Array = _grid(cols, fr.size() - 1, func(i: int, j: int) -> Vector3:
		var th: float = TAU * float(i) / float(cols)
		var y: float = lerpf(-0.3, _s_top(th), fr[j])
		return _s_surface(th, y),
		func(q: Vector3) -> Vector3: return Vector3(q.x, 0.0, q.z))
	_part(trunk, Transform3D.IDENTITY, BARK, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.06,
		"vcol": func(q: Vector3, c: Color) -> Color:
			var rg: float = _s_ridge(atan2(q.x, q.z))
			return c.lerp(BARK_D, 0.55 * (1.0 - rg)).lightened(0.06 * rg)})
	# Bark lip on the cut, then the cut face with growth rings, radial checks, a hollow heart.
	var lip: Array = _grid(cols, 1, func(i: int, j: int) -> Vector3:
		var th: float = TAU * float(i) / float(cols)
		var r0: float = _s_radius(th, _s_top(th))
		var r: float = r0 if j == 0 else r0 - 0.17
		return _s_dir(th) * r + Vector3(0.0, _s_top(th) + (0.0 if j == 0 else 0.035), 0.0),
		func(_q: Vector3) -> Vector3: return Vector3.UP)
	_part(lip, Transform3D.IDENTITY, BARK_D, {"kind": Kind.BARK, "normals": "flat", "tint": 0.05})
	var rings: int = 12
	var face: Array = _grid(cols, rings, func(i: int, j: int) -> Vector3:
		var th: float = TAU * float(i) / float(cols)
		var ro: float = _s_radius(th, _s_top(th)) - 0.17
		var ri: float = _s_inner(th)
		var t: float = float(j) / float(rings)
		var r: float = lerpf(ro, ri, t)
		return _s_dir(th) * r + Vector3(0.0, _s_top(th) + 0.035 - 0.07 * t * t, 0.0),
		func(_q: Vector3) -> Vector3: return Vector3.UP)
	_part(face, Transform3D.IDENTITY, WOOD, {"kind": Kind.STONE, "normals": "smooth", "moss": 0.35, "tint": 0.04,
		"vcol": func(q: Vector3, _c: Color) -> Color:
			var th: float = atan2(q.x, q.z)
			var r: float = Vector2(q.x, q.z).length()
			var ri: float = _s_inner(th)
			var ro: float = _s_radius(th, _s_top(th)) - 0.17
			var t: float = clampf((r - ri) / maxf(ro - ri, 0.1), 0.0, 1.0)
			var ring: float = 0.5 + 0.5 * sin((r + 0.03 * sin(th * 5.0)) * TAU / 0.2)
			var c: Color = WOOD.lerp(WOOD_L, ring * 0.8)
			c = c.lerp(WOOD_D, (1.0 - _ss(0.0, 0.35, t)) * 0.75)
			return c.lightened(0.08 * _ss(0.75, 1.0, t))})
	for k: int in 4:
		var th2: float = [0.35, 1.9, 3.5, 4.9][k]
		var cv := PackedVector3Array()
		var cn := PackedVector3Array()
		var ci := PackedInt32Array()
		var steps: int = 6
		for s: int in steps + 1:
			var t2: float = float(s) / float(steps)
			var th3: float = th2 + 0.05 * sin(t2 * 7.0 + k)
			var r2: float = lerpf(_s_inner(th3) - 0.02, _s_radius(th3, _s_top(th3)) - 0.1, t2)
			var y2: float = _s_top(th3) + 0.035 - 0.07 * pow(1.0 - t2, 2.0) + 0.012
			var side: Vector3 = Vector3(cos(th3), 0.0, -sin(th3)) * (0.035 + 0.03 * sin(t2 * PI))
			var c2: Vector3 = _s_dir(th3) * r2 + Vector3(0.0, y2, 0.0)
			cv.append(c2 - side)
			cv.append(c2 + side)
			cn.append(Vector3.UP)
			cn.append(Vector3.UP)
		for s2: int in steps:
			var a: int = s2 * 2
			ci.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
		_part(_mk(cv, cn, ci), Transform3D.IDENTITY, WOOD_D.darkened(0.5), {"kind": Kind.STONE, "normals": "smooth", "tint": 0.0})
	# The hollow: dark inner wall and a litter floor.
	var hollow: Array = _grid(cols, 4, func(i: int, j: int) -> Vector3:
		var th: float = TAU * float(i) / float(cols)
		var t: float = float(j) / 4.0
		var y: float = lerpf(_s_top(th) + 0.035 - 0.07, 0.5, t)
		return _s_dir(th) * _s_inner(th) * lerpf(1.0, 0.86, t) + Vector3(0.0, y, 0.0),
		func(q: Vector3) -> Vector3: return -Vector3(q.x, 0.0, q.z))
	_part(hollow, Transform3D.IDENTITY, HOLLOW, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.05,
		"vcol": func(q: Vector3, c: Color) -> Color: return c.lerp(HOLLOW_D, clampf((1.9 - q.y) / 1.3, 0.0, 1.0))})
	var floor_arr: Array = _grid(cols, 2, func(i: int, j: int) -> Vector3:
		var th: float = TAU * float(i) / float(cols)
		var r: float = _s_inner(th) * 0.86 * (1.0 - float(j) / 2.0)
		return _s_dir(th) * r + Vector3(0.0, 0.5 + 0.06 * float(j), 0.0),
		func(_q: Vector3) -> Vector3: return Vector3.UP)
	_part(floor_arr, Transform3D.IDENTITY, HOLLOW_D.lerp(LITTER, 0.25), {"kind": Kind.STONE, "normals": "smooth", "tint": 0.1})
	for k2: int in 7:
		var a2: float = k2 * 2.4 + 0.3
		var lp: Vector3 = Vector3(sin(a2), 0.0, cos(a2)) * (0.25 + 0.45 * _h(Vector3(k2, 3, 3))) + Vector3(0.0, 0.56, 0.0)
		_part(_chunk(Vector3(0.22, 0.07, 0.17), 3, 80.0 + k2, 0.7, 6, 3), _xf(lp, Vector3(0.0, a2, 0.0)),
			LITTER.lerp(CAP_D, _h(Vector3(k2, 1, 2)) * 0.6), {"kind": Kind.STONE, "moss": 0.0, "tint": 0.1})
	# Barber chair: on the back, a torn slab of the outer trunk still stands above the cut where the tree split as it
	# fell: bark outside, pale weathered fibres inside, a ragged sawtooth of splinters on top.
	var wa: float = PI - 0.62
	var wb: float = PI + 0.78
	var wcols: int = 14
	var wall_h := func(i: int) -> float:
		var t: float = float(i) / float(wcols)
		var tent: float = pow(sin(PI * t), 0.7) * (1.0 - 0.35 * t)
		var saw: float = 1.0 if i % 2 == 0 else 0.62
		return 0.05 + 1.5 * tent * saw * (0.85 + 0.3 * _h(Vector3(i, 3.0, 9.0)))
	var wall_r := func(i: int, outer: bool) -> float:
		var th10: float = lerpf(wa, wb, float(i) / float(wcols))
		var ro: float = _s_radius(th10, _s_top(th10))
		return ro if outer else ro - 0.30 - 0.06 * _h(Vector3(i, 4.0, 9.0))
	for side: int in 2:
		var outer: bool = side == 0
		var wall: Array = _grid(wcols, 3, func(i: int, j: int) -> Vector3:
			var th10: float = lerpf(wa, wb, float(i) / float(wcols))
			var y0: float = _s_top(th10) - 0.03
			var r10: float = wall_r.call(i, outer)
			var t: float = float(j) / 3.0
			var lean_out: float = 0.10 * t * float(wall_h.call(i))
			return _s_dir(th10) * (r10 + lean_out) + Vector3(0.0, y0 + t * float(wall_h.call(i)), 0.0),
			func(q: Vector3) -> Vector3: return Vector3(q.x, 0.0, q.z) * (1.0 if outer else -1.0))
		_part(wall, Transform3D.IDENTITY, BARK if outer else WOOD_OLD, {"kind": Kind.BARK, "normals": "flat", "tint": 0.1,
			"col2": BARK_D.lerp(BARK, 0.5) if outer else WOOD_OLD.lightened(0.14), "grad": "y"})
	var wtop: Array = _grid(wcols, 1, func(i: int, j: int) -> Vector3:
		var th10: float = lerpf(wa, wb, float(i) / float(wcols))
		var hh: float = wall_h.call(i)
		var r10: float = float(wall_r.call(i, j == 0)) + 0.10 * hh
		return _s_dir(th10) * r10 + Vector3(0.0, _s_top(th10) - 0.03 + hh, 0.0),
		func(_q: Vector3) -> Vector3: return Vector3.UP)
	_part(wtop, Transform3D.IDENTITY, WOOD_OLD.lightened(0.12), {"kind": Kind.BARK, "normals": "flat", "tint": 0.1})
	for e: int in 2:
		var ie: int = 0 if e == 0 else wcols
		var th11: float = lerpf(wa, wb, float(ie) / float(wcols))
		var cap := PackedVector3Array()
		var y11: float = _s_top(th11) - 0.03
		var hh2: float = wall_h.call(ie)
		cap.append_array([_s_dir(th11) * float(wall_r.call(ie, true)) + Vector3(0, y11, 0),
			_s_dir(th11) * float(wall_r.call(ie, false)) + Vector3(0, y11, 0),
			_s_dir(th11) * (float(wall_r.call(ie, false)) + 0.1 * hh2) + Vector3(0, y11 + hh2, 0),
			_s_dir(th11) * (float(wall_r.call(ie, true)) + 0.1 * hh2) + Vector3(0, y11 + hh2, 0)])
		var cn2 := PackedVector3Array()
		var en: Vector3 = Vector3(cos(th11), 0.0, -sin(th11)) * (-1.0 if e == 0 else 1.0)
		for _k: int in 4:
			cn2.append(en)
		_part(_mk(cap, cn2, PackedInt32Array([0, 1, 2, 0, 2, 3])), Transform3D.IDENTITY, WOOD_OLD,
			{"kind": Kind.BARK, "normals": "flat", "tint": 0.05})
	# Buttress roots: thick where they leave the trunk, snaking sideways along the ground and sinking into it (never a
	# pointed tip in the air); a few fork. Two flank the burrow, one is missing on the back.
	var ri2: int = 0
	for k3: int in S_RIDGES:
		var th5: float = (TAU * k3 - 0.4) / S_RIDGES
		var dd: float = wrapf(th5 - S_BURROW, -PI, PI)
		if absf(dd) < 0.36 or k3 == 4:
			continue
		var ln: float = 0.8 + 0.4 * _h(Vector3(k3, 5, 5))
		var bend: float = (_h(Vector3(k3, 6, 6)) - 0.5) * 1.1
		var pts: Array[Vector3] = []
		var rr: Array[float] = [0.50, 0.38, 0.28, 0.22, 0.18]
		var ys: Array[float] = [0.95, 0.40, 0.15, 0.02, -0.2]
		var ds: Array[float] = [S_R0 * 0.9, S_R0 + 0.35 * ln, S_R0 + 0.85 * ln, S_R0 + 1.3 * ln, S_R0 + 1.7 * ln]
		for s3: int in 5:
			var a5: float = th5 + bend * pow(float(s3) / 4.0, 1.5) * 0.45
			pts.append(_s_dir(a5) * ds[s3] + Vector3(0.0, ys[s3], 0.0))
		for s4: int in 4:
			_limb(pts[s4], pts[s4 + 1], rr[s4], rr[s4 + 1], 9, BARK, {"kind": Kind.BARK, "tint": 0.06})
			if s4 > 0:
				_part(_sph(rr[s4] * 1.0, 9, 5), _xf(pts[s4], Vector3.ZERO, Vector3(1.0, 0.85, 1.0)), BARK,
					{"kind": Kind.BARK, "normals": "smooth", "tint": 0.06})
		if ri2 % 3 == 1:
			var fork0: Vector3 = pts[2]
			var fdir: Vector3 = _s_dir(th5 - bend * 0.6 - 0.35)
			var fork1: Vector3 = fork0 + fdir * 0.7 + Vector3(0.0, -0.1, 0.0)
			var fork2: Vector3 = fork1 + fdir * 0.45 + Vector3(0.0, -0.25, 0.0)
			_limb(fork0, fork1, 0.2, 0.15, 7, BARK, {"kind": Kind.BARK, "tint": 0.06})
			_limb(fork1, fork2, 0.15, 0.12, 7, BARK, {"kind": Kind.BARK, "tint": 0.06})
			_part(_sph(0.15, 7, 4), _xf(fork1), BARK, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.06})
		if ri2 % 2 == 0:
			_moss(pts[1].lerp(pts[2], 0.2) + Vector3(0.0, rr[1] * 0.72, 0.0), 0.22, Vector3(1.2, 0.42, 1.0), 95.0 + k3)
		ri2 += 1
	# The burrow: a dark mouth dug into the flare just above the ground (lying along the flare's slope, its top edge
	# tucked under the trunk), a lip of bare dirt round it, spoil heaped in front.
	var bdir: Vector3 = _s_dir(S_BURROW)
	var r_lo: float = _s_radius(S_BURROW, 0.0)
	var r_hi: float = _s_radius(S_BURROW, 0.5)
	var bn: Vector3 = (bdir * 0.55 + Vector3(0.0, 0.84, 0.0)).normalized()
	var bpos: Vector3 = bdir * (r_lo + 0.1) + Vector3(0.0, 0.1, 0.0)
	var mouth: Array = _grid(14, 3, func(i: int, j: int) -> Vector3:
		var a3: float = TAU * float(i) / 14.0
		var f: float = [1.4, 1.0, 0.55, 0.0][j]
		var dip: float = [0.03, 0.0, -0.12, -0.2][j]
		return Vector3(cos(a3) * 0.62 * f, maxf(sin(a3), -0.6) * 0.46 * f, dip),
		func(_q: Vector3) -> Vector3: return Vector3.BACK)
	_part(mouth, Transform3D(_facing(bn), bpos), Color(0.03, 0.024, 0.02), {"kind": Kind.STONE, "normals": "smooth",
		"tint": 0.0, "vcol": func(q: Vector3, c: Color) -> Color:
			var e: float = Vector2(q.x / 0.62, q.y / 0.46).length()
			return c.lerp(DIRT_D, _ss(0.8, 1.0, e)).lerp(DIRT.lightened(0.12), _ss(1.05, 1.35, e))})
	for k4: int in 3:
		var off: Vector3 = Vector3(bdir.z, 0.0, -bdir.x) * ((k4 - 1.0) * 0.42)
		var dp: Vector3 = bdir * (S_R0 + 0.95 + 0.2 * (k4 % 2)) + off + Vector3(0.0, -0.04, 0.0)
		_part(_chunk(Vector3(0.38, 0.12, 0.3) * (1.0 - 0.12 * k4), 5, 100.0 + k4, 0.72, 7, 4),
			_xf(dp, Vector3(0.06, S_BURROW + k4, 0.0)), DIRT.lerp(DIRT_D, 0.3 * (k4 % 2)),
			{"kind": Kind.STONE, "normals": "smooth", "moss": 0.3, "tint": 0.1, "seed": 100.0 + k4})
	for k5: int in 3:
		var pp: Vector3 = bdir * (S_R0 + 1.25 + 0.2 * k5) + Vector3(bdir.z, 0.0, -bdir.x) * (0.5 - 0.45 * k5)
		_part(_chunk(Vector3(0.1, 0.07, 0.09), 3, 110.0 + k5, 0.7, 5, 3), _xf(pp), STONE_R,
			{"kind": Kind.STONE, "moss": 0.2, "tint": 0.1})
	# Bracket fungus shelves (cream tops, orange rims).
	var shelves: Array = [[1.15, 0.95, 0.48], [1.22, 1.24, 0.38], [1.07, 1.46, 0.28], [-2.0, 1.20, 0.46],
		[-1.85, 1.50, 0.34], [2.35, 0.62, 0.42], [2.25, 0.92, 0.30], [-0.35, 1.2, 0.40], [-0.25, 1.5, 0.3]]
	var fi: int = 0
	for sh: Array in shelves:
		var th6: float = sh[0]
		var y6: float = sh[1]
		var w6: float = sh[2]
		var sp6: Vector3 = _s_surface(th6, y6)
		var b6: Basis = _facing(_s_dir(th6)) * Basis(Vector3.RIGHT, 0.12)
		_part(_sph(1.0, 9, 4), Transform3D(b6 * Basis.from_scale(Vector3(w6, w6 * 0.26, w6 * 0.72)),
			sp6 + _s_dir(th6) * w6 * 0.12), SHELF_TOP, {"kind": Kind.STONE, "normals": "smooth", "moss": 0.0,
			"tint": 0.06, "col2": SHELF_RIM, "grad": "r"})
		fi += 1
	# Toadstools between the roots and one in the hollow.
	var shrooms: Array = [[1.62, 2.4, 0.30, 0.26], [1.74, 2.56, 0.2, 0.17], [1.5, 2.6, 0.16, 0.13],
		[-2.55, 2.5, 0.28, 0.23], [-2.4, 2.72, 0.18, 0.15], [2.95, 2.55, 0.24, 0.2], [0.3, 0.55, 0.22, 0.17],
		[0.62, 0.62, 0.15, 0.12]]
	var mi: int = 0
	for m: Array in shrooms:
		var th7: float = m[0]
		var r7: float = m[1]
		var hh: float = m[2]
		var cr: float = m[3]
		var gp: Vector3 = _s_dir(th7) * r7 if r7 > 1.0 else _s_dir(th7) * r7 + Vector3(0.0, 0.52, 0.0)
		var lean: Vector3 = (Vector3.UP + Vector3(_h(Vector3(mi, 1, 7)) - 0.5, 0.0, _h(Vector3(mi, 2, 7)) - 0.5) * 0.35).normalized()
		var top: Vector3 = gp + lean * hh
		_limb(gp + Vector3(0.0, -0.05, 0.0), top, cr * 0.34, cr * 0.26, 6, STEM, {"kind": Kind.STONE, "moss": 0.0, "tint": 0.05})
		_part(_sph(1.0, 9, 4), Transform3D(_along(gp, top) * Basis.from_scale(Vector3(cr, cr * 0.55, cr)), top), CAP_D,
			{"kind": Kind.STONE, "normals": "smooth", "moss": 0.0, "col2": CAP, "grad": "y", "tint": 0.05})
		if cr > 0.2:
			for d: int in 3:
				var a4: float = d * 2.1 + mi
				_part(_sph(cr * 0.14, 5, 3), _xf(top + _along(gp, top) * Vector3(cos(a4) * cr * 0.5, cr * 0.42, sin(a4) * cr * 0.5)),
					STEM, {"kind": Kind.STONE, "normals": "smooth", "tint": 0.0})
		mi += 1
	# Ivy up the right-back flank, moss cushions draped over the rim.
	for i2: int in 3:
		for j2: int in 6 - i2:
			var th8: float = 1.95 + i2 * 0.22 + (_h(Vector3(i2, j2, 9)) - 0.5) * 0.12
			var y8: float = 0.25 + j2 * 0.3 + i2 * 0.1
			var p8: Vector3 = _s_surface(th8, y8)
			_part(_sph(0.2 - j2 * 0.012, 5, 3), Transform3D(_facing(_s_dir(th8)) * Basis.from_scale(Vector3(1.0, 1.15, 0.45)),
				p8), MOSS_L if (i2 + j2) % 2 == 0 else MOSS, {"kind": Kind.IVY, "normals": "smooth", "jitter": 0.03,
				"seed": 120.0 + i2 * 7 + j2})
	for k6: int in 5:
		var th9: float = [0.2, 1.2, 2.9, 4.1, 5.3][k6]
		var ro: float = _s_radius(th9, _s_top(th9))
		_moss(_s_dir(th9) * (ro - 0.12) + Vector3(0.0, _s_top(th9) + 0.02, 0.0), 0.3, Vector3(1.2, 0.35, 0.9), 130.0 + k6,
			MOSS if k6 % 2 == 0 else MOSS_L)
		_moss(_s_dir(th9) * (ro + 0.02) + Vector3(0.0, _s_top(th9) - 0.22, 0.0), 0.2, Vector3(1.1, 0.8, 0.45), 135.0 + k6)
	# A sapling growing from the rim: new life from the old giant.
	var sb: Vector3 = _s_dir(2.2) * 1.32 + Vector3(0.0, _s_top(2.2) + 0.02, 0.0)
	var st: Vector3 = sb + Vector3(0.18, 1.35, -0.08)
	var wind := Vector2(sb.y, st.y + 0.6)
	_limb(sb, st, 0.075, 0.035, 6, BARK.lightened(0.15), {"kind": Kind.BARK, "wind": wind, "tint": 0.05})
	_limb(sb.lerp(st, 0.55), sb.lerp(st, 0.55) + Vector3(-0.35, 0.35, 0.1), 0.035, 0.015, 5, BARK.lightened(0.15),
		{"kind": Kind.BARK, "wind": wind})
	var leaves: Array = [[st + Vector3(0.0, 0.12, 0.0), 0.40], [st + Vector3(-0.35, -0.08, 0.12), 0.30],
		[st + Vector3(0.25, -0.18, -0.12), 0.28], [sb.lerp(st, 0.55) + Vector3(-0.4, 0.38, 0.12), 0.24]]
	var li: int = 0
	for lf: Array in leaves:
		var lr: float = lf[1]
		_part(_sph(lr, 8, 5), _xf(lf[0] as Vector3, Vector3(0.0, li * 1.3, 0.0), Vector3(1.0, 0.78, 1.0)),
			LEAF.lerp(LEAF_L, 0.3 * li), {"kind": Kind.IVY, "normals": "smooth", "wind": wind, "jitter": lr * 0.16,
			"seed": 140.0 + li, "col2": LEAF_L, "grad": "y"})
		li += 1
	_disc(Vector3(0.0, 0.0, 0.0), 3.5, 3.4, 16, 7.0)
	var mesh: ArrayMesh = _commit("giant_stump")
	var shape := CylinderShape3D.new()
	shape.radius = STUMP_R
	shape.height = STUMP_H
	_scene("giant_stump", mesh, [["Trunk", shape, Transform3D(Basis(), Vector3(0.0, STUMP_H * 0.5 - 0.2, 0.0))]],
		&"lm_stump", 3.8)
