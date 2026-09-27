extends SceneTree
## Task 12.V32 (docs/design/map-fill.md 5.5 + section 10, row 12.V32): generates the four epic-beast lair scenes.
##   art/environment/lairs/heath_wallow.tscn     West / East Heath, Tusker: a churned mud wallow ringed by a spoil lip,
##                                                tusk-gouged rubbing stones caked in mud, ploughed turf, uprooted heather,
##                                                a snapped tusk tip in the mud, cloven prints.
##   art/environment/lairs/crag_nest.tscn        Colossus Crag, Roc: a great stick nest heaped on the crown of the
##                                                Fallen Colossus's head (fitted to landmarks/meshes/colossus.res), long
##                                                branches laid over the skull, eggshells, storm-blue feathers, guano.
##   art/environment/lairs/greymane_hollow.tscn  Greymane Hollow, Direwolf: a bed of flattened ferns in a trampled
##                                                hollow, standing ferns around it, a bone pile with deer skulls, a
##                                                claw-scored mossy log, low rocks.
##   art/environment/lairs/old_wood_den.tscn     Old Wood Den, Grizzlemaw: a cave mouth dug under a tilted boulder at the
##                                                cliff foot beside the aqueduct pier, a spoil fan with claw furrows,
##                                                dangling roots, claw-marked rock, fallen aqueduct blocks, bones.
## Each scene: root Node3D with lair_art.gd (LairArt, `set_occupied(bool)`), children Model (shadows on) + Active
## (a beast lives here: fresh signs) + Dormant (empty: dry / abandoned signs). Meshes in lairs/meshes/<name>.res:
## surface 0 = the SHARED painted nature material (nature_props/nature_mat.tres), then the shared contact shadow
## (nature_contact_mat.tres) and, den Dormant only, the shared Old Wood cobweb material (old_wood_web_mat.tres). No
## material is created here, 0 lights, no colliders (draw-only), every surface indexed.
## Space: the lair centre (EpicBeasts lair "center") is the origin; west-bank orientation (the east lairs are the same
## scene turned by PI). Re-run after changing a shape or colour (the Colossus mesh must exist first):
##   $GODOT --headless --path . -s res://art/environment/lairs/build_lairs.gd --quit-after 900

const LDIR := "res://art/environment/lairs/"
const MESH_DIR := "res://art/environment/lairs/meshes/"
const NDIR := "res://art/environment/nature_props/"
const WEB_MAT := "res://art/environment/biomes/old_wood/old_wood_web_mat.tres"
const LAIR_SCRIPT := "res://art/environment/lairs/lair_art.gd"
const COLOSSUS_MESH := "res://art/environment/landmarks/meshes/colossus.res"
## The Fallen Colossus origin in the crag lair's space: landmark (-57, -16) minus lair centre (-53, -18).
const COLOSSUS_AT := Vector3(-4.0, 0.0, 2.0)
## Height that maps to COLOR.a = 1 (the painted shader's light-top / dark-foot gradient), the same for every lair.
const GRAD_H := 2.4

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
enum Web { TWIG = 0, ORB = 1, SHEET = 2 }

# --- palette (sRGB; the painted shader lights tops, darkens feet) -----------------------------------
const MUD_WET := Color(0.15, 0.125, 0.10)
const MUD := Color(0.23, 0.19, 0.15)
const MUD_L := Color(0.37, 0.31, 0.24)
const MUD_DRY := Color(0.50, 0.44, 0.35)
const MUD_CRACK := Color(0.10, 0.08, 0.06)
const PUDDLE := Color(0.17, 0.20, 0.23)
const PUDDLE_L := Color(0.45, 0.52, 0.58)
const EARTH := Color(0.34, 0.27, 0.20)
const EARTH_D := Color(0.22, 0.17, 0.13)
const EARTH_L := Color(0.45, 0.37, 0.28)
const TURF := Color(0.30, 0.36, 0.15)
const TURF_L := Color(0.40, 0.46, 0.19)
const PRINT := Color(0.11, 0.08, 0.05)
const GRANITE := Color(0.44, 0.43, 0.41)
const GRANITE_W := Color(0.47, 0.45, 0.41)
const SCAR := Color(0.68, 0.65, 0.58)
const GROOVE := Color(0.16, 0.14, 0.12)
const LING := Color(0.47, 0.32, 0.57)
const LING_L := Color(0.62, 0.47, 0.71)
const LING_D := Color(0.26, 0.17, 0.30)
const H_LEAF := Color(0.22, 0.28, 0.14)
const ROOTC := Color(0.38, 0.28, 0.18)
const IVORY := Color(0.88, 0.84, 0.72)
const BONE := Color(0.80, 0.76, 0.63)
const BONE_OLD := Color(0.66, 0.62, 0.50)
const BONE_FRESH := Color(0.74, 0.63, 0.55)
const ANTLER := Color(0.62, 0.52, 0.38)
const SOCKET := Color(0.10, 0.08, 0.07)
const STICK := Color(0.42, 0.34, 0.25)
const STICK_D := Color(0.28, 0.22, 0.16)
const STICK_G := Color(0.58, 0.54, 0.47)   # sun-bleached grey
const NEST_CORE := Color(0.30, 0.25, 0.19)
const LINING := Color(0.56, 0.49, 0.35)
const LINING_D := Color(0.38, 0.32, 0.22)
const DOWN := Color(0.80, 0.82, 0.83)
const EGG := Color(0.52, 0.68, 0.76)
const EGG_SPOT := Color(0.22, 0.28, 0.36)
const SHELL_IN := Color(0.93, 0.92, 0.86)
const FEATHER := Color(0.36, 0.46, 0.60)
const FEATHER_L := Color(0.72, 0.78, 0.84)
const FEATHER_D := Color(0.16, 0.20, 0.27)
const GUANO := Color(0.84, 0.84, 0.78)
const FERN := Color(0.24, 0.40, 0.14)
const FERN_L := Color(0.40, 0.56, 0.20)
const FERN_FLAT := Color(0.24, 0.33, 0.13)
const FERN_BRUISE := Color(0.46, 0.45, 0.20)
const FERN_DEAD := Color(0.47, 0.32, 0.17)
const MOSS := Color(0.20, 0.36, 0.11)
const MOSS_L := Color(0.33, 0.50, 0.16)
const BARK := Color(0.36, 0.28, 0.20)
const BARK_D := Color(0.24, 0.18, 0.13)
const WOOD_L := Color(0.72, 0.60, 0.42)
const FUR := Color(0.40, 0.40, 0.39)
const FUR_D := Color(0.42, 0.42, 0.41)
const BEAR_FUR := Color(0.36, 0.25, 0.16)
const LITTER := Color(0.62, 0.36, 0.14)
const LITTER_D := Color(0.44, 0.27, 0.13)
const CAP := Color(0.55, 0.36, 0.20)
const STEM := Color(0.86, 0.80, 0.67)
const BOULDER := Color(0.42, 0.41, 0.40)
const BOULDER_W := Color(0.47, 0.44, 0.40)
const HOLE := Color(0.035, 0.028, 0.022)
const HOLE_EDGE := Color(0.13, 0.095, 0.065)
const LIME := Color(0.62, 0.58, 0.51)
const LIME_D := Color(0.47, 0.44, 0.39)

# --- the fits (lair-local; west bank) ---------------------------------------------------------------
const MUD_C := Vector3(0.2, 0.0, -0.3)
const MUD_R := Vector2(2.9, 2.3)
const MUD_ROT := 0.35
const NEST_C := Vector3(-1.2, 0.0, 1.45)   ## on the crown of the Colossus head (head centre at (-3.0, 1.3))
const RING_Y := 2.22
const BED_C := Vector3(-0.9, 0.0, -1.05)
const BONE_C := Vector3(1.75, 0.0, -1.3)
const LOG_A := Vector3(-2.55, 0.0, -2.95)
const LOG_B := Vector3(0.55, 0.0, -3.45)
const DEN_ROCK := Vector3(3.3, 0.0, -3.75)  ## boulder at the cliff foot, west of the pier willow (fallen aqueduct blocks lead to the pier)
const DEN_FACE := Vector3(-0.58, 0.0, 0.81)  ## the cave mouth faces the territory (and the game camera)

var mat: Material
var contact_mat: Material
var web_mat: Material
var _conv: float = 1.0
var _report: Array[String] = []
var _head_tris: PackedVector3Array = PackedVector3Array()
var _head_cells: Dictionary = {}


## One mesh being built: surface 0 painted, 1 contact, 2 cobweb.
class Acc:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var cv := PackedVector3Array()
	var cuv := PackedVector2Array()
	var wv := PackedVector3Array()
	var wn := PackedVector3Array()
	var wc := PackedColorArray()
	var wuv := PackedVector2Array()
	var wuv2 := PackedVector2Array()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	mat = load(NDIR + "nature_mat.tres") as Material
	contact_mat = load(NDIR + "nature_contact_mat.tres") as Material
	web_mat = load(WEB_MAT) as Material
	if mat == null or contact_mat == null or web_mat == null:
		push_error("shared materials missing")
		quit(1)
		return
	_build_wallow()
	_build_nest()
	_build_hollow()
	_build_den()
	for line: String in _report:
		print(line)
	print("LAIRS BUILD OK")
	quit()


# =================================================================================================
# small maths
# =================================================================================================

func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _r(seed: float, k: float, lo: float, hi: float) -> float:
	return lerpf(lo, hi, _h(Vector3(seed, k, 17.0)))


func _ss(a: float, b: float, x: float) -> float:
	var t: float = clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Smooth value-ish noise from sines (0..1).
func _vn(x: float, z: float, s: float = 1.0) -> float:
	return 0.5 + 0.22 * sin(x * 1.7 * s + 0.3) * cos(z * 1.3 * s - 0.7) + 0.16 * sin(x * 0.9 * s - z * 2.1 * s + 1.1) \
		+ 0.12 * cos(x * 3.3 * s + z * 2.7 * s + 2.3)


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


## Basis whose +Y runs along a -> b.
func _along(a: Vector3, b: Vector3) -> Basis:
	var y: Vector3 = (b - a).normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## Yaw that turns +X toward the horizontal direction d.
func _yaw_x(d: Vector3) -> float:
	return atan2(-d.z, d.x)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _flat0(_x: float, _z: float) -> float:
	return 0.0


# =================================================================================================
# primitives
# =================================================================================================

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


func _box(size: Vector3) -> Array:
	var m := BoxMesh.new()
	m.size = size
	return m.get_mesh_arrays()


## A (cols + 1) x (rows + 1) grid from pos(i, j); face normals turned to agree with out(face centre); smooth normals
## shared by equal positions.
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


## A chiselled rock chunk (low-poly ellipsoid cut by random planes + a flat top), as in the landmarks.
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


## Arrays transformed by xf (for ray tests against placed parts).
func _placed(arr: Array, xf: Transform3D) -> PackedVector3Array:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var out := PackedVector3Array()
	for i: int in idx:
		out.append(xf * v[i])
	return out


## Nearest hit of a ray on a placed triangle soup: {"p", "n"} (n faces the ray's origin), or {}.
func _ray(tris: PackedVector3Array, from: Vector3, dir: Vector3) -> Dictionary:
	var best := INF
	var hit := {}
	for t: int in range(0, tris.size(), 3):
		var r: Variant = Geometry3D.ray_intersects_triangle(from, dir, tris[t], tris[t + 1], tris[t + 2])
		if r == null:
			continue
		var p: Vector3 = r
		var d: float = from.distance_to(p)
		if d < best:
			best = d
			var fn: Vector3 = (tris[t + 1] - tris[t]).cross(tris[t + 2] - tris[t]).normalized()
			if fn.dot(dir) > 0.0:
				fn = -fn
			hit = {"p": p, "n": fn}
	return hit


# =================================================================================================
# accumulation
# =================================================================================================

## Adds mesh arrays, transformed, to the painted surface. Options: kind (Kind), normals "flat" | "smooth", moss (stone
## 0-1), wind (Vector2 y0, y1 in lair space: sway weight 0 at y0 -> 1 at y1), col2 + grad ("y" part height | "x" part
## length | "r" distance from the part's Y axis), tint (random value variation per face), no_caps (drop +-Y caps of
## cylinders), vcol (Callable(local: Vector3, col: Color) -> Color), cols (PackedColorArray per source vertex), gmin /
## ymin (minimum height gradient / contact height: keeps flat ground parts out of the painted dark foot band),
## two_sided, jitter + seed.
func _part(acc: Acc, arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.STONE)
	var mode: String = o.get("normals", "flat")
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var moss: float = o.get("moss", 0.0)
	var wind: Vector2 = o.get("wind", Vector2.ZERO)
	var no_caps: bool = o.get("no_caps", false)
	var tint: float = o.get("tint", 0.08)
	var vcol: Callable = o.get("vcol", Callable())
	var cols: PackedColorArray = o.get("cols", PackedColorArray())
	var gmin: float = o.get("gmin", 0.0)
	var ymin: float = o.get("ymin", 0.0)
	var two: bool = o.get("two_sided", false)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var nb: Basis = xf.basis.inverse().transposed()
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var maxr: float = 0.001
	for p: Vector3 in v:
		lo = lo.min(p)
		hi = hi.max(p)
		maxr = maxf(maxr, Vector2(p.x, p.z).length())
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	tv.resize(v.size())
	tn.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter
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
		for side: int in (2 if two else 1):
			var order := PackedInt32Array([a, b, c]) if side == 0 else PackedInt32Array([a, c, b])
			for vi: int in order:
				var nn: Vector3 = fn if mode == "flat" else tn[vi]
				if side == 1:
					nn = -nn
				var gt: float = 0.0
				match grad:
					"x":
						gt = clampf((v[vi].x - lo.x) / maxf(hi.x - lo.x, 0.001), 0.0, 1.0)
					"r":
						gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
					_:
						gt = clampf((v[vi].y - lo.y) / maxf(hi.y - lo.y, 0.001), 0.0, 1.0)
				var cc: Color = cols[vi] if not cols.is_empty() else col.lerp(col2, gt)
				if vcol.is_valid():
					cc = vcol.call(v[vi], cc)
				var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
				var wp: Vector3 = tv[vi]
				acc.v.append(wp)
				acc.n.append(nn)
				acc.c.append(Color(cc.r * k, cc.g * k, cc.b * k, clampf(maxf(wp.y / GRAD_H, gmin), 0.0, 1.0)))
				var w: float = moss
				if kind != Kind.STONE:
					w = 0.0
					if wind.y > wind.x:
						w = pow(clampf((wp.y - wind.x) / (wind.y - wind.x), 0.0, 1.0), 1.6)
				acc.uv.append(Vector2(w, maxf(wp.y, ymin)))
				acc.uv2.append(Vector2(0.0, kind))


## A tapered limb (open cylinder) from a to b.
func _limb(acc: Acc, a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Color, o: Dictionary = {}) -> void:
	var oo: Dictionary = o.duplicate()
	oo["no_caps"] = true
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	_part(acc, _cyl(r1, r0, a.distance_to(b), segs), Transform3D(_along(a, b), (a + b) * 0.5), col, oo)


## A polyline limb (tube through pts) with radii tapering r0 -> r1 and small knuckles at the joints.
func _tube(acc: Acc, pts: Array[Vector3], r0: float, r1: float, segs: int, col: Color, o: Dictionary = {},
		knuckles: bool = true) -> void:
	var n: int = pts.size()
	for i: int in n - 1:
		var ra: float = lerpf(r0, r1, float(i) / float(n - 1))
		var rb: float = lerpf(r0, r1, float(i + 1) / float(n - 1))
		_limb(acc, pts[i], pts[i + 1], ra, rb, segs, col, o)
		if i > 0 and knuckles:
			var ko: Dictionary = o.duplicate()
			ko["normals"] = "smooth"
			_part(acc, _sph(ra * 1.02, segs, 3), _xf(pts[i]), col, ko)


## Soft contact shadow (contact surface): an irregular disc just above the ground.
func _contact(acc: Acc, c: Vector3, rx: float, rz: float, segs: int, seed: float, rot: float = 0.0) -> void:
	var ring: Array[Vector3] = []
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.25
		ring.append(c + Vector3(cos(a) * rx * j, 0.0, sin(a) * rz * j).rotated(Vector3.UP, rot) + Vector3(0.0, 0.035 - c.y, 0.0))
	var centre := Vector3(c.x, 0.035, c.z)
	for i: int in segs:
		var p1: Vector3 = ring[i]
		var p2: Vector3 = ring[(i + 1) % segs]
		var up: bool = (p1 - centre).cross(p2 - centre).y >= 0.0
		var tri: Array = [centre, p1, p2] if (1.0 if up else -1.0) == _conv else [centre, p2, p1]
		for k: int in 3:
			acc.cv.append(tri[k])
			acc.cuv.append(Vector2(0.0 if tri[k] == centre else 1.0, 0.0))


## A flat irregular blob lying on a height field hf(x, z) (+ lift), colour cc at the centre -> cr at the rim.
func _blob(acc: Acc, c: Vector3, rx: float, rz: float, rot: float, segs: int, seed: float, cc: Color, cr: Color,
		hf: Callable, lift: float, o: Dictionary = {}) -> void:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	v.append(Vector3(c.x, float(hf.call(c.x, c.z)) + lift, c.z))
	n.append(Vector3.UP)
	cols.append(cc)
	# A middle ring keeps the colour ramp soft and the blob hugging uneven ground. Options: "jag" (rim irregularity,
	# default 0.3), "rim_fn" (Callable(p) -> Color: the rim takes the colour of what lies below, so the edge melts in).
	var jag: float = o.get("jag", 0.3)
	var rim_fn: Callable = o.get("rim_fn", Callable())
	for ring: int in 2:
		var f: float = 0.55 if ring == 0 else 1.0
		for i: int in segs:
			var a: float = i * TAU / segs
			var j: float = 1.0 + (_h(Vector3(seed, i, 3.0)) - 0.5) * jag + 0.5 * jag * sin(a * 2.0 + seed) * 0.5
			var l := Vector3(cos(a) * rx * j * f, 0.0, sin(a) * rz * j * f).rotated(Vector3.UP, rot)
			var p: Vector3 = c + l
			p.y = float(hf.call(p.x, p.z)) + lift
			v.append(p)
			n.append(Vector3.UP)
			var rim_c: Color = rim_fn.call(p) if rim_fn.is_valid() else cr
			cols.append(cc.lerp(rim_c, 0.45 if ring == 0 else 1.0))
	for i: int in segs:
		var i2: int = (i + 1) % segs
		idx.append_array([0, 1 + i, 1 + i2])
		idx.append_array([1 + i, 1 + segs + i, 1 + segs + i2])
		idx.append_array([1 + i, 1 + segs + i2, 1 + i2])
	var oo: Dictionary = o.duplicate()
	oo.erase("jag")
	oo.erase("rim_fn")
	oo["cols"] = cols
	oo["normals"] = "smooth"
	if not oo.has("gmin"):
		oo["gmin"] = 0.55
	if not oo.has("ymin"):
		oo["ymin"] = 0.45
	if not oo.has("tint"):
		oo["tint"] = 0.0
	_part(acc, _mk(v, n, idx), Transform3D.IDENTITY, cc, oo)


## A flat ribbon along pts on a height field (+ lift): cracks, furrows, scars on the ground.
func _ribbon(acc: Acc, pts: Array[Vector3], width: float, col: Color, hf: Callable, lift: float, o: Dictionary = {}) -> void:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var m: int = pts.size()
	for i: int in m:
		var t: Vector3 = (pts[mini(i + 1, m - 1)] - pts[maxi(i - 1, 0)])
		t.y = 0.0
		t = t.normalized()
		var side := Vector3(-t.z, 0.0, t.x)
		var u: float = float(i) / float(maxi(m - 1, 1))
		var w: float = width * (0.35 + 0.65 * sin(PI * clampf(u, 0.0, 1.0)))
		for s: float in [-0.5, 0.5]:
			var p: Vector3 = pts[i] + side * w * s
			p.y = float(hf.call(p.x, p.z)) + lift
			v.append(p)
			n.append(Vector3.UP)
	for i: int in m - 1:
		var a: int = i * 2
		idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	var oo: Dictionary = o.duplicate()
	oo["normals"] = "smooth"
	if not oo.has("gmin"):
		oo["gmin"] = 0.55
	if not oo.has("ymin"):
		oo["ymin"] = 0.45
	if not oo.has("tint"):
		oo["tint"] = 0.0
	_part(acc, _mk(v, n, idx), Transform3D.IDENTITY, col, oo)


## A jagged crack / trail polyline from p0 heading `dir` (radians), `steps` kinks.
func _jag(p0: Vector3, dir: float, length: float, steps: int, wander: float, seed: float) -> Array[Vector3]:
	var pts: Array[Vector3] = [p0]
	var a: float = dir
	var p: Vector3 = p0
	for k: int in steps:
		a += (_h(Vector3(seed, k, 5.0)) - 0.5) * wander
		p += Vector3(cos(a), 0.0, sin(a)) * (length / steps)
		pts.append(p)
	return pts


## A height-field patch: a (cols + 1) x (rows + 1) grid from pos(i, j) (lair space), colours colf(p) -> Color;
## triangles whose three vertices all fail keep(p) are dropped.
func _patch(acc: Acc, cols: int, rows: int, pos: Callable, colf: Callable, keep: Callable, o: Dictionary = {}) -> void:
	var arr: Array = _grid(cols, rows, pos, func(_q: Vector3) -> Vector3: return Vector3.UP)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	for t: int in range(0, idx.size(), 3):
		if bool(keep.call(v[idx[t]])) or bool(keep.call(v[idx[t + 1]])) or bool(keep.call(v[idx[t + 2]])):
			kept.append_array([idx[t], idx[t + 1], idx[t + 2]])
	arr[Mesh.ARRAY_INDEX] = kept
	var cc := PackedColorArray()
	for p: Vector3 in v:
		cc.append(colf.call(p))
	var oo: Dictionary = o.duplicate()
	oo["cols"] = cc
	oo["normals"] = "smooth"
	if not oo.has("gmin"):
		oo["gmin"] = 0.55
	if not oo.has("ymin"):
		oo["ymin"] = 0.45
	if not oo.has("tint"):
		oo["tint"] = 0.0
	_part(acc, arr, Transform3D.IDENTITY, Color.WHITE, oo)


## A frond / feather / leaf strip in its own space (+X along, +Z across, +Y up): `length`, arching by `rise`
## (radians) and drooping, width profile peaking at `peak` (0-1), serrated edge (pinnae) when `serr` > 0. Placed by xf.
func _strip(acc: Acc, xf: Transform3D, length: float, width: float, rise: float, droop: float, segs: int, c0: Color,
		c1: Color, serr: float, peak: float, o: Dictionary = {}) -> void:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for k: int in segs + 1:
		var t: float = float(k) / float(segs)
		var x: float = cos(rise) * length * t
		var y: float = sin(rise) * length * t - droop * length * t * t
		var prof: float = pow(sin(PI * clampf(t * 0.5 / peak if t < peak else 0.5 + (t - peak) * 0.5 / (1.0 - peak), 0.0, 1.0)), 0.7)
		var w: float = width * prof * (1.0 + serr * (1.0 if k % 2 == 0 else -1.0))
		var cc: Color = c0.lerp(c1, t)
		for s: float in [-1.0, 0.0, 1.0]:
			v.append(Vector3(x, y + (0.012 if s == 0.0 else 0.0), s * w * 0.5))
			n.append(Vector3(-sin(rise) * 0.3, 1.0, 0.0).normalized())
			cols.append(cc if s != 0.0 else cc.lightened(0.08))
	for k: int in segs:
		var a: int = k * 3
		var b: int = a + 3
		idx.append_array([a, a + 1, b, a + 1, b + 1, b, a + 1, a + 2, b + 1, a + 2, b + 2, b + 1])
	var oo: Dictionary = o.duplicate()
	oo["cols"] = cols
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	_part(acc, _mk(v, n, idx), xf, c0, oo)


## A cobweb card (cobweb surface): hub -> rim fan with a sagging middle ring; UV = card coordinates (hub 0, rim 1).
func _web(acc: Acc, hub: Vector3, rim: Array[Vector3], kind: int, sag: float) -> void:
	var nrm: Vector3 = (rim[0] - hub).cross(rim[rim.size() / 2] - hub).normalized()
	var e1: Vector3 = (rim[0] - hub).normalized()
	var e2: Vector3 = nrm.cross(e1).normalized()
	var m: int = rim.size()
	for i: int in m:
		var ra: Vector3 = rim[i]
		var rb: Vector3 = rim[(i + 1) % m]
		var ua := Vector2((ra - hub).dot(e1), (ra - hub).dot(e2)).normalized()
		var ub := Vector2((rb - hub).dot(e1), (rb - hub).dot(e2)).normalized()
		var ma: Vector3 = hub.lerp(ra, 0.5) + Vector3(0.0, -sag, 0.0)
		var mb: Vector3 = hub.lerp(rb, 0.5) + Vector3(0.0, -sag, 0.0)
		var quads: Array = [[hub, Vector2.ZERO], [ma, ua * 0.5], [mb, ub * 0.5], [ma, ua * 0.5], [ra, ua], [rb, ub],
			[ma, ua * 0.5], [rb, ub], [mb, ub * 0.5]]
		for q: Array in quads:
			acc.wv.append(q[0])
			acc.wn.append(nrm)
			acc.wc.append(Color(1.0, 1.0, 1.0, clampf((q[0] as Vector3).y / 1.5, 0.0, 1.0)))
			acc.wuv.append(q[1])
			acc.wuv2.append(Vector2(0.0, kind))


# =================================================================================================
# props shared by several lairs
# =================================================================================================

func _bone_o(col: Color) -> Dictionary:
	return {"kind": Kind.STONE, "normals": "smooth", "tint": 0.06, "gmin": 0.5, "ymin": 0.42, "col2": col.lightened(0.06)}


## A long bone with knobbed ends.
func _bone(acc: Acc, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var o: Dictionary = _bone_o(col)
	_limb(acc, a, b, r, r * 0.85, 6, col, o)
	var d: Vector3 = (b - a).normalized()
	for e: Array in [[a, -d], [b, d]]:
		var p: Vector3 = e[0]
		var dd: Vector3 = e[1]
		_part(acc, _sph(r * 1.55, 5, 3), Transform3D(_along(p, p + dd) * Basis.from_scale(Vector3(1.2, 0.8, 0.9)),
			p + dd * r * 0.4), col, o)


## A curved rib (arc of `span` radians, radius rr) in the plane spanned by `axis` (along) and up.
func _rib(acc: Acc, base: Vector3, axis: Vector3, rr: float, span: float, r: float, col: Color) -> void:
	var pts: Array[Vector3] = []
	for k: int in 5:
		var a: float = span * float(k) / 4.0
		pts.append(base + axis * sin(a) * rr + Vector3.UP * (1.0 - cos(a)) * rr * 0.35)
	_tube(acc, pts, r, r * 0.7, 5, col, _bone_o(col))


## A deer skull (+Z snout) with optional antlers.
func _skull(acc: Acc, xf: Transform3D, col: Color, antlers: bool, seed: float) -> void:
	var o: Dictionary = _bone_o(col)
	_part(acc, _sph(1.0, 8, 5), xf * _xf(Vector3(0.0, 0.12, 0.0), Vector3.ZERO, Vector3(0.15, 0.12, 0.17)), col, o)
	_part(acc, _cyl(0.05, 0.1, 0.3, 7), xf * Transform3D(_along(Vector3(0, 0.1, 0.1), Vector3(0, 0.04, 0.42)),
		Vector3(0.0, 0.07, 0.25)), col, o)
	for s: float in [-1.0, 1.0]:
		_part(acc, _sph(0.05, 6, 4), xf * _xf(Vector3(0.105 * s, 0.14, 0.1)), SOCKET, {"kind": Kind.STONE,
			"normals": "smooth", "tint": 0.0, "gmin": 0.5, "ymin": 0.42})
	if antlers:
		var ao := {"kind": Kind.STONE, "normals": "smooth", "tint": 0.06, "gmin": 0.55, "ymin": 0.45, "col2": ANTLER.lightened(0.25)}
		for s: float in [-1.0, 1.0]:
			var j: float = _h(Vector3(seed, s, 1.0)) * 0.06
			var p0 := Vector3(0.07 * s, 0.2, 0.0)
			var p1: Vector3 = p0 + Vector3(0.13 * s, 0.17 + j, -0.1)
			var p2: Vector3 = p1 + Vector3(0.1 * s, 0.2, -0.03)
			var p3: Vector3 = p2 + Vector3(0.0, 0.17, 0.07)
			var pts: Array[Vector3] = [xf * p0, xf * p1, xf * p2, xf * p3]
			_tube(acc, pts, 0.04, 0.015, 5, ANTLER, ao)
			_limb(acc, xf * p1, xf * (p1 + Vector3(0.02 * s, 0.14, 0.13)), 0.025, 0.01, 5, ANTLER, ao)
			_limb(acc, xf * p2, xf * (p2 + Vector3(0.05 * s, 0.1, 0.12)), 0.022, 0.01, 5, ANTLER, ao)


## A stick (tapered, bark shading), optionally with a side twig.
func _stick(acc: Acc, a: Vector3, b: Vector3, r: float, col: Color, seed: float, twig: bool = false) -> void:
	var o := {"kind": Kind.BARK, "normals": "smooth", "tint": 0.1}
	var mid: Vector3 = a.lerp(b, 0.5) + _h3(Vector3(seed, 3.0, 1.0)) * a.distance_to(b) * 0.05
	var pts: Array[Vector3] = [a, mid, b]
	_tube(acc, pts, r, r * 0.65, 4, col, o, false)
	if twig:
		var t0: Vector3 = a.lerp(b, 0.6)
		var d: Vector3 = ((b - a).normalized() + _h3(Vector3(seed, 7.0, 2.0)) * 0.9).normalized()
		_limb(acc, t0, t0 + d * a.distance_to(b) * 0.35, r * 0.6, r * 0.3, 4, col, o)


## Moss cushion (foliage shading, still).
func _moss(acc: Acc, pos: Vector3, r: float, squash: Vector3, seed: float, col: Color = MOSS) -> void:
	_part(acc, _sph(r, 8, 4), _xf(pos, Vector3(0.0, seed, 0.0), squash), col, {"kind": Kind.IVY, "normals": "smooth",
		"jitter": r * 0.12, "seed": seed, "col2": col.lerp(MOSS_L, 0.6), "grad": "y", "gmin": 0.45})


## A clod of earth / turf (chunk, green top when `turf`).
func _clod(acc: Acc, p: Vector3, s: float, seed: float, col: Color, turf: bool) -> void:
	var arr: Array = _chunk(Vector3(s, s * 0.6, s * 0.85), 4, seed, 0.7, 6, 3)
	var o := {"kind": Kind.STONE, "moss": 0.0, "tint": 0.12, "gmin": 0.45, "ymin": 0.3}
	if turf:
		o["vcol"] = func(q: Vector3, c: Color) -> Color: return TURF.lerp(TURF_L, _h(q * 3.0)) if q.y > s * 0.25 else c
	_part(acc, arr, _xf(p, Vector3(_r(seed, 1.0, -0.4, 0.4), _r(seed, 2.0, 0.0, TAU), _r(seed, 3.0, -0.4, 0.4))), col, o)


## Pale gouges (claw / tusk marks) raked across a placed surface: `count` parallel scars over a dark groove.
func _gouges(acc: Acc, tris: PackedVector3Array, target: Vector3, out: Vector3, slant: float, count: int, length: float,
		spacing: float, width: float) -> void:
	var from: Vector3 = target + out * 3.0
	var hit: Dictionary = _ray(tris, from, -out)
	if hit.is_empty():
		return
	var p: Vector3 = hit["p"]
	var nrm: Vector3 = hit["n"]
	var side: Vector3 = nrm.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	var t: Vector3 = (Vector3.UP * cos(slant) + side * sin(slant))
	t = (t - nrm * t.dot(nrm)).normalized()
	var perp: Vector3 = nrm.cross(t).normalized()
	for k: int in count:
		var off: Vector3 = perp * (float(k) - float(count - 1) * 0.5) * spacing * (0.85 + 0.3 * _h(Vector3(k, slant, 3.0))) \
			+ t * (_h(Vector3(k, slant, 4.0)) - 0.5) * length * 0.3
		var h2: Dictionary = _ray(tris, p + off + nrm * 2.0, -nrm)
		if h2.is_empty():
			continue
		var q: Vector3 = h2["p"]
		var qn: Vector3 = h2["n"]
		var len: float = length * (0.65 + 0.45 * _h(Vector3(k, length, 6.0)))
		var b := Basis(qn, (_h(Vector3(k, slant, 7.0)) - 0.5) * 0.3) * Basis(perp, t, qn)
		# A tapered sliver of fresh stone in a darker torn groove (scratch-shaped, never a clean bar).
		_part(acc, _sph(0.5, 6, 3), Transform3D(b * Basis.from_scale(Vector3(width * 2.0, len + width, 0.05)), q + qn * 0.005),
			GROOVE, {"kind": Kind.STONE, "tint": 0.0, "gmin": 0.5, "ymin": 0.45})
		_part(acc, _sph(0.5, 6, 3), Transform3D(b * Basis.from_scale(Vector3(width, len, 0.05)), q + qn * 0.018), SCAR,
			{"kind": Kind.STONE, "tint": 0.05, "gmin": 0.6, "ymin": 0.45})


## Prints on a height field: `feet` = hoof (two slots) | "wolf" (pad + 4 toes) | "bear" (pad + 5 toes + claws).
func _print(acc: Acc, p: Vector3, heading: float, feet: String, hf: Callable, seed: float) -> void:
	var fwd := Vector3(cos(heading), 0.0, sin(heading))
	var side := Vector3(-fwd.z, 0.0, fwd.x)
	match feet:
		"hoof":
			for s: float in [-1.0, 1.0]:
				_blob(acc, p + side * 0.055 * s, 0.1, 0.045, -heading, 6, seed + s, PRINT, PRINT.lerp(MUD, 0.4), hf, 0.014)
		"wolf":
			_blob(acc, p, 0.075, 0.065, -heading, 6, seed, PRINT, PRINT.lerp(EARTH_D, 0.4), hf, 0.014)
			for k: int in 4:
				var a: float = (float(k) - 1.5) * 0.42
				_blob(acc, p + fwd * 0.1 * cos(a) + side * 0.1 * sin(a), 0.028, 0.024, 0.0, 5, seed + k, PRINT, PRINT, hf, 0.014)
		_:
			_blob(acc, p, 0.15, 0.12, -heading, 7, seed, PRINT, PRINT.lerp(EARTH_D, 0.4), hf, 0.014)
			for k: int in 5:
				var a2: float = (float(k) - 2.0) * 0.36
				var tp: Vector3 = p + fwd * 0.2 * cos(a2) + side * 0.2 * sin(a2)
				_blob(acc, tp, 0.04, 0.035, 0.0, 5, seed + k, PRINT, PRINT, hf, 0.014)
				var cl: Array[Vector3] = [tp + fwd * 0.04, tp + fwd * 0.12]
				_ribbon(acc, cl, 0.022, PRINT, hf, 0.016)


## An upturned heather clump with its root ball.
func _heather(acc: Acc, p: Vector3, tilt: float, yaw: float, s: float, seed: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, tilt), p)
	for k: int in 6:
		var q := Vector3(_r(seed, k, -0.2, 0.2), 0.18 + _r(seed, k + 9.0, 0.0, 0.15), _r(seed, k + 3.0, -0.2, 0.2)) * s
		var col: Color = LING.lerp(LING_L, _h(Vector3(seed, k, 2.0))) if k % 3 != 0 else H_LEAF
		_part(acc, _sph(0.17 * s, 7, 4), xf * _xf(q, Vector3.ZERO, Vector3(1.0, 0.8, 1.0)), col, {"kind": Kind.IVY,
			"normals": "smooth", "jitter": 0.03 * s, "seed": seed + k, "col2": col.lightened(0.12), "gmin": 0.5, "ymin": 0.3})
	_part(acc, _sph(0.16 * s, 6, 4), xf * _xf(Vector3(0.0, 0.02, 0.0), Vector3.ZERO, Vector3(1.0, 0.6, 1.0)), EARTH_D,
		{"kind": Kind.STONE, "tint": 0.1, "gmin": 0.4, "ymin": 0.3, "jitter": 0.03, "seed": seed})
	for k2: int in 4:
		var d := Vector3(cos(k2 * 1.7 + seed), -0.6, sin(k2 * 1.7 + seed)).normalized()
		_limb(acc, xf * Vector3(0, 0.0, 0), xf * (d * 0.28 * s), 0.025, 0.008, 4, ROOTC, {"kind": Kind.BARK})


## An eggshell half: the lower part of an egg (rx, ry) with a jagged rim, outside col_out, inside SHELL_IN.
func _shell(acc: Acc, xf: Transform3D, rx: float, ry: float, col_out: Color, seed: float) -> void:
	var cols: int = 10
	var rows: int = 3
	var rim := func(i: int) -> float: return PI * 0.5 + (_h(Vector3(seed, i % cols, 2.0)) - 0.35) * 0.55
	var pos_o := func(i: int, j: int) -> Vector3:
		var ph: float = TAU * float(i) / float(cols)
		var th: float = lerpf(PI, float(rim.call(i)), float(j) / float(rows))
		return Vector3(sin(th) * cos(ph) * rx, cos(th) * ry, sin(th) * sin(ph) * rx)
	var outer: Array = _grid(cols, rows, pos_o, func(q: Vector3) -> Vector3: return q)
	var inner: Array = _grid(cols, rows, func(i: int, j: int) -> Vector3: return (pos_o.call(i, j) as Vector3) * 0.9,
		func(q: Vector3) -> Vector3: return -q)
	var o := {"kind": Kind.STONE, "normals": "smooth", "tint": 0.05, "gmin": 0.6, "ymin": 0.45,
		"vcol": func(q: Vector3, c: Color) -> Color: return EGG_SPOT if _h(q.snappedf(0.02) * 7.0) > 0.86 else c}
	_part(acc, outer, xf, col_out, o)
	_part(acc, inner, xf, SHELL_IN, {"kind": Kind.STONE, "normals": "smooth", "tint": 0.03, "gmin": 0.6, "ymin": 0.45})


## A whole egg (speckled).
func _egg(acc: Acc, xf: Transform3D, rx: float, ry: float, seed: float) -> void:
	var arr: Array = _sph(1.0, 12, 8)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i: int in v.size():
		var p: Vector3 = v[i]
		# Egg shape: fuller toward the bottom, narrower toward the top.
		v[i] = Vector3(p.x * rx * (1.0 - 0.12 * p.y), p.y * ry, p.z * rx * (1.0 - 0.12 * p.y))
	arr[Mesh.ARRAY_VERTEX] = v
	_part(acc, arr, xf, EGG, {"kind": Kind.STONE, "normals": "smooth", "tint": 0.04, "gmin": 0.6, "ymin": 0.45,
		"col2": EGG.lightened(0.1), "vcol": func(q: Vector3, c: Color) -> Color:
			return EGG_SPOT if _h(q.snappedf(0.01) * 11.0 + Vector3(seed, 0, 0)) > 0.82 else c})


## A big storm-blue feather lying at p (heading yaw), or stuck in at an angle (pitch).
func _feather(acc: Acc, p: Vector3, yaw: float, pitch: float, length: float, seed: float, dark: bool = false) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, pitch) * Basis(Vector3.RIGHT, _r(seed, 1.0, -0.3, 0.3)), p)
	var c0: Color = FEATHER_L.lerp(FEATHER, 0.35)
	var c1: Color = FEATHER_D if dark else FEATHER
	_strip(acc, xf, length, length * 0.24, 0.0, 0.04 * (1.0 if _h(Vector3(seed, 2, 2)) > 0.5 else -1.0), 7, c0, c1, 0.0, 0.45,
		{"kind": Kind.STONE, "two_sided": true, "tint": 0.05, "gmin": 0.6, "ymin": 0.45,
		"vcol": func(q: Vector3, c: Color) -> Color:
			var t: float = q.x / length
			if t > 0.62 and t < 0.74:
				return FEATHER_D
			if t >= 0.9:
				return FEATHER_L
			return c})
	_part(acc, _box(Vector3(length, 0.02, 0.025)), xf * _xf(Vector3(length * 0.45, 0.02, 0.0)), FEATHER_L.lightened(0.1),
		{"kind": Kind.STONE, "tint": 0.0, "gmin": 0.6, "ymin": 0.45})


## A tuft of fur (a few thin cones fanned out).
func _fur(acc: Acc, p: Vector3, s: float, seed: float, col: Color) -> void:
	for k: int in 4:
		var d := Vector3(cos(k * 1.9 + seed), 0.25, sin(k * 1.9 + seed)).normalized()
		_limb(acc, p, p + d * 0.16 * s, 0.035 * s, 0.004, 4, col.lerp(FUR_D, 0.3 * (k % 2)), {"kind": Kind.NEEDLES,
			"gmin": 0.6, "ymin": 0.45})


## Fallen leaves (litter): small flat diamonds on a height field.
func _litter(acc: Acc, c: Vector3, r: float, count: int, seed: float, hf: Callable) -> void:
	for k: int in count:
		var a: float = _r(seed, k, 0.0, TAU)
		var d: float = sqrt(_h(Vector3(seed, k, 8.0))) * r
		var p: Vector3 = c + Vector3(cos(a), 0.0, sin(a)) * d
		var yaw: float = _r(seed, k + 50.0, 0.0, TAU)
		var col: Color = LITTER.lerp(LITTER_D, _h(Vector3(seed, k, 9.0)))
		var v := PackedVector3Array()
		for q: Vector2 in [Vector2(-0.07, 0.0), Vector2(0.0, 0.045), Vector2(0.08, 0.0), Vector2(0.0, -0.045)]:
			var w: Vector3 = p + Vector3(q.x, 0.0, q.y).rotated(Vector3.UP, yaw)
			w.y = float(hf.call(w.x, w.z)) + 0.02 + 0.012 * absf(q.x) * 10.0
			v.append(w)
		var n := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
		_part(acc, _mk(v, n, PackedInt32Array([0, 1, 2, 0, 2, 3])), Transform3D.IDENTITY, col, {"kind": Kind.IVY,
			"normals": "smooth", "tint": 0.1, "gmin": 0.55, "ymin": 0.45, "two_sided": true})


## A small brown mushroom.
func _mushroom(acc: Acc, p: Vector3, s: float, seed: float) -> void:
	_limb(acc, p, p + Vector3(0.0, 0.12 * s, 0.0), 0.028 * s, 0.022 * s, 6, STEM, {"kind": Kind.STONE, "gmin": 0.5, "ymin": 0.45})
	_part(acc, _sph(0.075 * s, 8, 4), _xf(p + Vector3(0.0, 0.13 * s, 0.0), Vector3(0.0, seed, 0.1),
		Vector3(1.0, 0.55, 1.0)), CAP, {"kind": Kind.STONE, "normals": "smooth", "gmin": 0.6, "ymin": 0.45,
		"col2": CAP.lightened(0.15)})


# =================================================================================================
# saving
# =================================================================================================

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _commit(acc: Acc, name: String) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var tris: int = 0
	if not acc.v.is_empty():
		var a: Array = []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = acc.v
		a[Mesh.ARRAY_NORMAL] = acc.n
		a[Mesh.ARRAY_COLOR] = acc.c
		a[Mesh.ARRAY_TEX_UV] = acc.uv
		a[Mesh.ARRAY_TEX_UV2] = acc.uv2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(a))
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
		tris += acc.v.size() / 3
	if not acc.cv.is_empty():
		var ca: Array = []
		ca.resize(Mesh.ARRAY_MAX)
		ca[Mesh.ARRAY_VERTEX] = acc.cv
		var cn := PackedVector3Array()
		var c2 := PackedVector2Array()
		for i: int in acc.cv.size():
			cn.append(Vector3.UP)
			c2.append(Vector2.ZERO)
		ca[Mesh.ARRAY_NORMAL] = cn
		ca[Mesh.ARRAY_TEX_UV] = acc.cuv
		ca[Mesh.ARRAY_TEX_UV2] = c2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(ca))
		mesh.surface_set_material(mesh.get_surface_count() - 1, contact_mat)
		tris += acc.cv.size() / 3
	if not acc.wv.is_empty():
		var wa: Array = []
		wa.resize(Mesh.ARRAY_MAX)
		wa[Mesh.ARRAY_VERTEX] = acc.wv
		wa[Mesh.ARRAY_NORMAL] = acc.wn
		wa[Mesh.ARRAY_COLOR] = acc.wc
		wa[Mesh.ARRAY_TEX_UV] = acc.wuv
		wa[Mesh.ARRAY_TEX_UV2] = acc.wuv2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(wa))
		mesh.surface_set_material(mesh.get_surface_count() - 1, web_mat)
		tris += acc.wv.size() / 3
	var path: String = MESH_DIR + name + ".res"
	_save(mesh, path)
	var ref := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as ArrayMesh
	var aabb: AABB = ref.get_aabb()
	_report.append("mesh %-22s %5d tris, %d surfaces, aabb %s .. %s" % [name, tris, ref.get_surface_count(),
		aabb.position.snappedf(0.01), aabb.end.snappedf(0.01)])
	return ref


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


func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


## art/environment/lairs/<file>.tscn: LairArt root > Model (shadows) + Active (hidden) + Dormant (shown).
func _scene(file: String, root_name: String, model: ArrayMesh, active: ArrayMesh, dormant: ArrayMesh, kind: StringName,
		rest: Vector3, clear: PackedVector3Array) -> void:
	var root := Node3D.new()
	root.name = root_name
	root.set_script(load(LAIR_SCRIPT))
	root.add_to_group(&"lairs", true)
	root.set_meta(&"lair_kind", kind)
	root.set_meta(&"beast_rest", rest)
	root.set_meta(&"decor_clear", clear)
	for e: Array in [["Model", model, true, true], ["Active", active, false, false], ["Dormant", dormant, false, true]]:
		var mi := MeshInstance3D.new()
		mi.name = e[0]
		mi.mesh = e[1]
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(e[2]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = e[3]
		if not bool(e[2]):
			mi.visibility_range_end = 95.0
			mi.visibility_range_end_margin = 8.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		root.add_child(mi)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, LDIR + file)
	root.free()


# =================================================================================================
# West Heath wallow (Tusker)
# =================================================================================================

## The wallow's elliptical radius at (x, z): 0 at the centre, 1 at the lip crest.
func _mud_r(x: float, z: float) -> float:
	var q := Vector2(x - MUD_C.x, z - MUD_C.z).rotated(-MUD_ROT)
	var a: float = atan2(q.y, q.x)
	var f: float = 1.0 + 0.10 * sin(3.0 * a + 1.3) + 0.06 * sin(5.0 * a + 0.4) + 0.035 * sin(9.0 * a + 2.0)
	return Vector2(q.x / MUD_R.x, q.y / MUD_R.y).length() / f


## Mud height: a churned floor (furrows, hummocks) inside a thrown-up spoil lip, 0 beyond it.
func _mud_h(x: float, z: float) -> float:
	var r: float = _mud_r(x, z)
	if r > 1.14:
		return 0.0
	var q := Vector2(x - MUD_C.x, z - MUD_C.z).rotated(-MUD_ROT)
	var furrow: float = 0.022 * sin(q.x * 4.3 + sin(q.y * 1.7) * 1.5) + 0.018 * sin(q.y * 5.1 - q.x * 1.9)
	var floor_h: float = 0.045 + furrow + 0.03 * (_vn(x, z, 2.2) - 0.5)
	var ang: float = atan2(q.y, q.x)
	var lip: float = 0.23 * exp(-pow((r - 0.94) / 0.1, 2.0)) * (0.75 + 0.35 * sin(ang * 7.0 + 0.8) * sin(ang * 3.0))
	var base: float = floor_h * (1.0 - _ss(0.9, 1.1, r))
	return maxf(base + lip * (1.0 - _ss(1.02, 1.14, r)), 0.004)


func _mud_col(p: Vector3) -> Color:
	var r: float = _mud_r(p.x, p.z)
	var nz: float = _vn(p.x * 1.3, p.z * 1.3, 2.0)
	var c: Color = MUD_WET.lerp(MUD, _ss(0.3, 0.8, r) * 0.7 + nz * 0.3)
	c = c.lerp(MUD_L, _ss(0.82, 0.97, r) * (0.6 + 0.4 * nz))
	if r > 1.0:
		c = c.lerp(TURF.lerp(EARTH, 0.5), _ss(1.0, 1.12, r) * 0.7)
	return c


func _build_wallow() -> void:
	var model := Acc.new()
	var active := Acc.new()
	var dormant := Acc.new()
	var mh := func(x: float, z: float) -> float: return _mud_h(x, z)
	var gh := func(x: float, z: float) -> float: return maxf(_mud_h(x, z), 0.0)
	# --- the mud: a polar height-field grid over the wallow (rings to 1.14 of the lip radius) ---
	var ring_r: Array[float] = [0.0, 0.2, 0.38, 0.54, 0.67, 0.78, 0.86, 0.91, 0.95, 0.99, 1.03, 1.08, 1.14]
	var segs: int = 48
	_patch(model, segs, ring_r.size() - 1, func(i: int, j: int) -> Vector3:
		var a: float = TAU * float(i % segs) / float(segs)
		var f: float = 1.0 + 0.10 * sin(3.0 * a + 1.3) + 0.06 * sin(5.0 * a + 0.4) + 0.035 * sin(9.0 * a + 2.0)
		var q := Vector2(cos(a) * MUD_R.x, sin(a) * MUD_R.y) * ring_r[j] * f
		var w := Vector2(MUD_C.x, MUD_C.z) + q.rotated(MUD_ROT)
		return Vector3(w.x, _mud_h(w.x, w.y), w.y),
		func(p: Vector3) -> Color: return _mud_col(p),
		func(_p: Vector3) -> bool: return true,
		{"kind": Kind.STONE, "moss": 0.0})
	# --- cloven prints: a trail in from the north-east, one out to the west, a few trampled in the pit ---
	var trails: Array = [[Vector3(3.4, 0, -2.6), 2.45, 7], [Vector3(-0.9, 0, 0.4), 2.9, 7], [Vector3(0.9, 0, -0.9), 1.2, 4]]
	var pk: int = 0
	for tr: Array in trails:
		var p0: Vector3 = tr[0]
		var hd: float = tr[1]
		for k: int in int(tr[2]):
			var fwd := Vector3(cos(hd), 0.0, sin(hd))
			var side := Vector3(-fwd.z, 0.0, fwd.x) * (0.14 if k % 2 == 0 else -0.14)
			_print(model, p0 + fwd * 0.42 * k + side, hd + (_h(Vector3(k, pk, 1.0)) - 0.5) * 0.3, "hoof", gh, 30.0 + pk)
			pk += 1
	# --- tusk-gouged rubbing stones on the rim, mud-caked on the pit side ---
	var stones: Array = [
		[Vector3(-3.15, 0.0, -1.45), Vector3(0.8, 1.2, 0.62), 0.5, 0.17, 3.0, 2],
		[Vector3(3.0, 0.0, 0.95), Vector3(0.62, 0.72, 0.52), 0.26, -0.12, 5.0, 1],
		[Vector3(1.55, 0.0, -3.1), Vector3(0.5, 0.5, 0.45), 0.17, 0.1, 8.0, 1],
	]
	for st: Array in stones:
		var sp: Vector3 = st[0]
		var rad: Vector3 = st[1]
		var y0: float = st[2]
		var lean: float = st[3]
		var sd: float = st[4]
		var to_pit: Vector3 = (MUD_C - sp).normalized()
		var arr: Array = _chunk(rad, 6, sd, 0.8, 9, 6)
		var xf := Transform3D(Basis(Vector3.UP, sd) * Basis(Vector3.BACK, lean), sp + Vector3(0.0, y0, 0.0))
		var inv: Transform3D = xf
		_part(model, arr, xf, GRANITE.lerp(GRANITE_W, _h(Vector3(sd, 1, 1))), {"kind": Kind.STONE, "moss": 0.45,
			"tint": 0.08, "vcol": func(q: Vector3, c: Color) -> Color:
				var w: Vector3 = inv * q
				var toward: float = (Vector3(w.x - sp.x, 0.0, w.z - sp.z)).normalized().dot(to_pit)
				var mud: float = (1.0 - _ss(0.25, 0.7, w.y)) * _ss(-0.5, 0.3, toward)
				return c.lerp(MUD.lerp(MUD_L, _h(q * 4.0) * 0.6), mud * 0.92)})
		var tris: PackedVector3Array = _placed(arr, xf)
		var side := Vector3(-to_pit.z, 0.0, to_pit.x)
		for g: int in int(st[5]):
			var aim: Vector3 = (to_pit + side * (0.55 if g == 0 else -0.5)).normalized()
			_gouges(model, tris, sp + Vector3(0.0, rad.y * (0.55 + 0.15 * g), 0.0), aim, 0.9 if g == 0 else -0.8, 3,
				rad.y * 0.55, 0.11, 0.055)
		_contact(model, sp + to_pit * -0.1, rad.x * 1.45, rad.z * 1.45, 12, sd)
		# Fresh mud flung onto the stone (Active): dark wet splats on the pit side.
		for k: int in 4:
			var hp: Dictionary = _ray(tris, sp + to_pit * 3.0 + Vector3(0.0, _r(sd, k, 0.15, rad.y * 0.9), 0.0) + side *
				_r(sd, k + 5.0, -rad.x * 0.6, rad.x * 0.6), -to_pit)
			if hp.is_empty():
				continue
			var pp: Vector3 = hp["p"]
			var pn: Vector3 = hp["n"]
			_part(active, _sph(1.0, 6, 3), Transform3D(_along(pp, pp + pn) * Basis.from_scale(Vector3(0.11, 0.03, 0.08) *
				_r(sd, k + 2.0, 0.8, 1.5)), pp), MUD_WET, {"kind": Kind.STONE, "tint": 0.1, "gmin": 0.5, "ymin": 0.45})
	# --- ploughed turf: rooting furrows radiating from the lip, overturned sods at their ends ---
	for k: int in 7:
		var a: float = k * TAU / 7.0 + _r(12.0, k, -0.3, 0.3)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var start: Vector3 = MUD_C + Vector3(cos(a) * MUD_R.x * 0.9, 0.0, sin(a) * MUD_R.y * 0.9).rotated(Vector3.UP, -MUD_ROT)
		# Stay clear of the stones' feet.
		var clear := true
		for st2: Array in stones:
			if Vector2(start.x - (st2[0] as Vector3).x, start.z - (st2[0] as Vector3).z).length() < 1.2:
				clear = false
		if not clear:
			continue
		# A rooted-up patch of turf: bare torn earth spilling out from the lip, sods flipped over around it.
		var len: float = _r(13.0, k, 0.7, 1.2)
		var pc: Vector3 = start + dir * len * 0.5
		_blob(model, pc, len * 0.62, _r(15.0, k, 0.3, 0.45), -a, 14, 18.0 + k, EARTH_D.lerp(MUD, 0.4), EARTH_D.lerp(TURF, 0.5), gh,
			0.018, {"jag": 0.5})
		for q: int in 3:
			var side_off: Vector3 = Vector3(-dir.z, 0.0, dir.x) * _r(19.0 + k, q, -0.45, 0.45)
			_clod(model, pc + dir * _r(24.0 + k, q, -0.3, 0.5) + side_off + Vector3(0.0, 0.03, 0.0), _r(25.0 + k, q, 0.1, 0.16),
				18.0 + k * 5.0 + q, EARTH, true)
		var tip: Vector3 = start + dir * len
		_clod(model, tip + dir * 0.15 + Vector3(0.0, 0.05, 0.0), 0.22, 16.0 + k, EARTH, true)
		_clod(model, tip + dir * -0.2 + Vector3(-dir.z, 0.05, dir.x) * 0.22, 0.15, 17.0 + k, EARTH_D, true)
	# Clods of turf and mud thrown about.
	for k: int in 16:
		var a2: float = _r(20.0, k, 0.0, TAU)
		var rr: float = _r(21.0, k, 1.02, 1.45)
		var p := MUD_C + Vector3(cos(a2) * MUD_R.x * rr, 0.0, sin(a2) * MUD_R.y * rr).rotated(Vector3.UP, -MUD_ROT)
		p.y = 0.04
		_clod(model, p, _r(22.0, k, 0.1, 0.2), 23.0 + k, EARTH.lerp(MUD, 0.5), k % 3 != 0)
	# --- uprooted heather tossed onto the lip ---
	_heather(model, Vector3(-1.7, 0.1, 2.05), 1.9, 0.4, 1.0, 40.0)
	_heather(model, Vector3(2.55, 0.08, -1.95), 1.3, 2.2, 0.85, 41.0)
	_heather(model, Vector3(-2.2, 0.06, -2.9), 2.4, 4.0, 0.8, 42.0)
	# --- a snapped tusk tip half sunk in the mud ---
	var tusk: Array[Vector3] = []
	for k: int in 5:
		var t: float = float(k) / 4.0
		var p2: Vector3 = Vector3(0.55, 0.0, 0.55) + Vector3(0.62 * t, 0.0, -0.2 * t) + Vector3(0.0, 0.03 + 0.2 * sin(t * PI * 0.85), 0.0)
		p2.y += _mud_h(p2.x, p2.z) - 0.03
		tusk.append(p2)
	_tube(model, tusk, 0.075, 0.012, 7, IVORY, {"kind": Kind.STONE, "normals": "smooth", "tint": 0.04, "gmin": 0.65,
		"ymin": 0.45, "col2": IVORY.lightened(0.08)})
	_part(model, _sph(0.078, 7, 3), _xf(tusk[0]), IVORY.darkened(0.2), {"kind": Kind.STONE, "gmin": 0.6, "ymin": 0.45})
	# --- Active (a Tusker lives here): wet sheen, puddles, fresh splashes; Dormant: pale sun-cracked crust ---
	var wet: Array = [[Vector3(-0.4, 0, -0.35), 1.2, 0.9, 0.3], [Vector3(1.0, 0, 0.35), 0.8, 0.6, 1.2],
		[Vector3(0.3, 0, -1.3), 0.7, 0.5, 2.0], [Vector3(-1.2, 0, 0.8), 0.6, 0.45, 0.9]]
	for i: int in wet.size():
		var w: Array = wet[i]
		_blob(active, w[0], w[1], w[2], w[3], 16, 50.0 + i, MUD_WET.darkened(0.3), MUD_WET, mh, 0.012,
			{"rim_fn": func(p: Vector3) -> Color: return _mud_col(p)})
	var puddles: Array = [[Vector3(-0.5, 0, -0.4), 0.62, 0.42, 0.3], [Vector3(1.05, 0, 0.3), 0.4, 0.28, 1.1],
		[Vector3(0.15, 0, -1.35), 0.34, 0.24, 2.2]]
	for i: int in puddles.size():
		var pd: Array = puddles[i]
		_blob(active, pd[0], pd[1], pd[2], pd[3], 16, 60.0 + i, PUDDLE, PUDDLE.lerp(MUD_WET, 0.5), mh, 0.024, {"jag": 0.2})
		var hl: Vector3 = (pd[0] as Vector3) + Vector3(-0.08, 0.0, -0.06)
		_blob(active, hl, float(pd[1]) * 0.5, float(pd[2]) * 0.14, float(pd[3]) + 0.5, 8, 65.0 + i, PUDDLE_L,
			PUDDLE, mh, 0.03, {"jag": 0.1})
	for k: int in 10:
		var a3: float = _r(70.0, k, 0.0, TAU)
		var p3: Vector3 = MUD_C + Vector3(cos(a3) * MUD_R.x, 0.0, sin(a3) * MUD_R.y).rotated(Vector3.UP, -MUD_ROT) * _r(71.0, k, 1.0, 1.25)
		_blob(active, p3, _r(72.0, k, 0.12, 0.26), _r(73.0, k, 0.08, 0.16), a3, 7, 74.0 + k, MUD_WET, MUD, gh, 0.025)
	var crust: Array = [[Vector3(-0.3, 0, -0.3), 1.55, 1.2, 0.35], [Vector3(1.1, 0, 0.2), 0.9, 0.7, 1.2],
		[Vector3(-1.3, 0, 0.7), 0.7, 0.5, 0.8], [Vector3(0.4, 0, -1.4), 0.75, 0.5, 2.1]]
	for i: int in crust.size():
		var cr: Array = crust[i]
		_blob(dormant, cr[0], cr[1], cr[2], cr[3], 16, 80.0 + i, MUD_DRY, MUD_DRY, mh, 0.012,
			{"rim_fn": func(p: Vector3) -> Color: return _mud_col(p).lerp(MUD_DRY, 0.3)})
	for k: int in 16:
		var a4: float = _r(90.0, k, 0.0, TAU)
		var d4: float = sqrt(_h(Vector3(91.0, k, 1.0))) * 1.5
		var p4: Vector3 = Vector3(-0.1, 0.0, -0.3) + Vector3(cos(a4) * d4, 0.0, sin(a4) * d4 * 0.8)
		var pts2: Array[Vector3] = _jag(p4, _r(92.0, k, 0.0, TAU), _r(93.0, k, 0.5, 1.0), 4, 1.3, 94.0 + k)
		_ribbon(dormant, pts2, 0.05, MUD_CRACK, mh, 0.02)
	_scene("heath_wallow.tscn", "HeathWallow", _commit(model, "heath_wallow"), _commit(active, "heath_wallow_active"),
		_commit(dormant, "heath_wallow_dormant"), &"tusker", Vector3(0.1, 0.0, -0.3),
		PackedVector3Array([Vector3(MUD_C.x, MUD_C.z, 3.6)]))


# =================================================================================================
# Colossus Crag nest (Roc)
# =================================================================================================

## Loads the Colossus mesh (painted surface) into lair space and buckets its triangles by 0.5 m cells.
func _load_head() -> void:
	var mesh := load(COLOSSUS_MESH) as ArrayMesh
	if mesh == null:
		push_error("colossus mesh missing: build the landmarks first")
		return
	var arr: Array = mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for t: int in range(0, idx.size(), 3):
		var a: Vector3 = v[idx[t]] + COLOSSUS_AT
		var b: Vector3 = v[idx[t + 1]] + COLOSSUS_AT
		var c: Vector3 = v[idx[t + 2]] + COLOSSUS_AT
		var k: int = _head_tris.size()
		_head_tris.append_array([a, b, c])
		var lo := Vector2(minf(a.x, minf(b.x, c.x)), minf(a.z, minf(b.z, c.z)))
		var hi := Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.z, maxf(b.z, c.z)))
		for cx: int in range(floori(lo.x * 2.0), floori(hi.x * 2.0) + 1):
			for cz: int in range(floori(lo.y * 2.0), floori(hi.y * 2.0) + 1):
				var key := Vector2i(cx, cz)
				if not _head_cells.has(key):
					_head_cells[key] = PackedInt32Array()
				(_head_cells[key] as PackedInt32Array).append(k)


## The top of the Colossus at (x, z) in lair space, 0 where there is none.
func _head_h(x: float, z: float) -> float:
	var key := Vector2i(floori(x * 2.0), floori(z * 2.0))
	if not _head_cells.has(key):
		return 0.0
	var best: float = 0.0
	var from := Vector3(x, 10.0, z)
	for k: int in (_head_cells[key] as PackedInt32Array):
		var r: Variant = Geometry3D.ray_intersects_triangle(from, Vector3.DOWN, _head_tris[k], _head_tris[k + 1], _head_tris[k + 2])
		if r != null:
			best = maxf(best, (r as Vector3).y)
	return best


## The heap under the nest (east side, down to the ground): surface point at t (0 ground -> 1 nest), angle a.
func _heap_p(t: float, a: float) -> Vector3:
	var wob: float = 1.0 + 0.12 * sin(a * 3.0 + 0.7) + 0.07 * sin(a * 5.0 + 2.1)
	var bottom := Vector3(NEST_C.x + 0.35 + cos(a) * 1.3 * wob, -0.05, NEST_C.z + 0.05 + sin(a) * 1.45 * wob)
	var top := Vector3(NEST_C.x + cos(a) * 1.05, RING_Y - 0.22, NEST_C.z + sin(a) * 1.05)
	var p: Vector3 = bottom.lerp(top, pow(t, 0.8))
	var out := Vector3(cos(a), 0.0, sin(a))
	var lump: float = 0.08 * sin(a * 7.0 + t * 9.0) + 0.06 * sin(a * 11.0 - t * 5.0)
	return p + out * (sin(PI * t) * 0.14 + lump * sin(PI * t))


func _lining_h(r: float) -> float:
	return RING_Y - 0.1 + 0.28 * pow(clampf(r / 0.82, 0.0, 1.0), 2.0)


func _build_nest() -> void:
	_load_head()
	var model := Acc.new()
	var active := Acc.new()
	var dormant := Acc.new()
	var hh := func(x: float, z: float) -> float: return _head_h(x, z)
	var bark := {"kind": Kind.BARK, "normals": "smooth", "tint": 0.1}
	# --- the heap core (dark, hidden by sticks) from the ground up to the nest, east of the head ---
	var core: Array = _grid(28, 6, func(i: int, j: int) -> Vector3: return _heap_p(float(j) / 6.0, TAU * float(i % 28) / 28.0),
		func(q: Vector3) -> Vector3: return Vector3(q.x - NEST_C.x - 0.3, 0.0, q.z - NEST_C.z))
	_part(model, core, Transform3D.IDENTITY, NEST_CORE, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.15,
		"col2": STICK_D})
	# --- the rim: a thick torus of woven sticks ---
	var torus: Array = _grid(32, 8, func(i: int, j: int) -> Vector3:
		var u: float = TAU * float(i % 32) / 32.0
		var w: float = TAU * float(j % 8) / 8.0
		var big: float = 1.0 + 0.06 * sin(u * 3.0 + 1.0)
		return NEST_C + Vector3((big + 0.34 * cos(w)) * cos(u), RING_Y + 0.22 * sin(w), (big + 0.34 * cos(w)) * sin(u)),
		func(q: Vector3) -> Vector3:
			var u2: float = atan2(q.z - NEST_C.z, q.x - NEST_C.x)
			return q - (NEST_C + Vector3(cos(u2), 0.0, sin(u2)) + Vector3(0.0, RING_Y, 0.0)))
	_part(model, torus, Transform3D.IDENTITY, NEST_CORE, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.15,
		"col2": STICK_D})
	# --- the lining: a dish of dry grass and down ---
	var dish: Array = _grid(20, 4, func(i: int, j: int) -> Vector3:
		var a: float = TAU * float(i % 20) / 20.0
		var r: float = 0.9 * float(j) / 4.0
		return NEST_C + Vector3(cos(a) * r, _lining_h(r), sin(a) * r),
		func(_q: Vector3) -> Vector3: return Vector3.UP)
	_part(model, dish, Transform3D.IDENTITY, LINING_D, {"kind": Kind.NEEDLES, "normals": "smooth", "tint": 0.1,
		"col2": LINING, "grad": "r", "vcol": func(q: Vector3, c: Color) -> Color:
			return DOWN if _h(q.snappedf(0.05) * 5.0) > 0.8 else c})
	# --- sticks on the heap (the exposed east side) ---
	var sk: int = 0
	# Splayed sticks at the foot, leaning in against the heap.
	for k: int in 22:
		var a0: float = _r(95.0, k, -2.7, 2.7)
		var foot: Vector3 = _heap_p(0.0, a0)
		var out0 := Vector3(foot.x - NEST_C.x - 0.35, 0.0, foot.z - NEST_C.z).normalized()
		var pa: Vector3 = foot + out0 * _r(96.0, k, 0.2, 0.75) + Vector3(0.0, 0.04, 0.0)
		var pb: Vector3 = _heap_p(_r(97.0, k, 0.3, 0.7), a0 + _r(98.0, k, -0.3, 0.3)) + out0 * 0.08
		_stick(model, pa, pb, _r(99.0, k, 0.045, 0.08), [STICK_G, STICK, STICK_D][k % 3], 94.0 + k, k % 3 == 0)
	for k: int in 105:
		var a0: float = _r(100.0, k, -2.6, 2.6)
		var t0: float = _r(101.0, k, 0.02, 0.9)
		var phi: float = _r(102.0, k, -1.2, 1.2)
		var len: float = _r(103.0, k, 0.8, 1.6)
		var t1: float = clampf(t0 + cos(phi) * len / 2.6, 0.0, 1.0)
		var a1: float = a0 + sin(phi) * len / 1.4
		var pa: Vector3 = _heap_p(t0, a0)
		var pb: Vector3 = _heap_p(t1, a1)
		var outa := Vector3(pa.x - NEST_C.x - 0.2, 0.0, pa.z - NEST_C.z).normalized()
		var outb := Vector3(pb.x - NEST_C.x - 0.2, 0.0, pb.z - NEST_C.z).normalized()
		pa += outa * 0.06
		pb += outb * 0.06
		if pa.y < 0.02:
			pa.y = 0.04
		var col: Color = [STICK, STICK_D, STICK_G, STICK.lerp(STICK_G, 0.5)][k % 4]
		_stick(model, pa, pb, _r(104.0, k, 0.04, 0.075), col, 105.0 + k, k % 5 == 0)
		sk += 1
	# More sticks over the south face (the side the game camera sees), leaning every way.
	for k: int in 45:
		var a0: float = _r(90.0, k, 0.5, 2.8)
		var t0: float = _r(91.0, k, 0.0, 0.85)
		var pa: Vector3 = _heap_p(t0, a0)
		var pb: Vector3 = _heap_p(clampf(t0 + _r(92.0, k, 0.2, 0.55), 0.0, 1.0), a0 + _r(93.0, k, -0.7, 0.7))
		var o2 := Vector3(pa.x - NEST_C.x - 0.2, 0.0, pa.z - NEST_C.z).normalized()
		_stick(model, pa + o2 * 0.09 + Vector3(0.0, 0.03, 0.0), pb + o2 * 0.09, _r(89.0, k, 0.04, 0.07),
			[STICK_G, STICK, STICK.lerp(STICK_G, 0.5)][k % 3], 88.0 + k, k % 4 == 0)
	# --- sticks woven round the rim, and some bristling out ---
	for k: int in 84:
		var a0: float = _r(110.0, k, 0.0, TAU)
		var span: float = _r(111.0, k, 0.4, 0.8)
		var r0: float = _r(112.0, k, 0.74, 1.36)
		var r1: float = r0 + _r(113.0, k, -0.15, 0.15)
		var yy: float = RING_Y + 0.2 * (1.0 - pow(clampf((r0 - 1.0) / 0.36, -1.0, 1.0), 2.0)) + _r(114.0, k, -0.06, 0.05)
		var pa: Vector3 = NEST_C + Vector3(cos(a0) * r0, yy, sin(a0) * r0)
		var pb: Vector3 = NEST_C + Vector3(cos(a0 + span) * r1, yy + _r(115.0, k, -0.08, 0.08), sin(a0 + span) * r1)
		var col2: Color = [STICK, STICK_G, STICK_D, STICK.lerp(STICK_G, 0.6)][k % 4]
		_stick(model, pa, pb, _r(116.0, k, 0.035, 0.07), col2, 117.0 + k, k % 6 == 0)
	for k: int in 18:
		var a0: float = k * TAU / 18.0 + _r(120.0, k, -0.15, 0.15)
		var r0: float = 0.95
		var reach: float = _r(121.0, k, 0.5, 1.1)
		var pa: Vector3 = NEST_C + Vector3(cos(a0) * r0, RING_Y + 0.12, sin(a0) * r0)
		var da: float = a0 + _r(122.0, k, -0.5, 0.5)
		var pb: Vector3 = pa + Vector3(cos(da) * reach, _r(123.0, k, -0.35, 0.25), sin(da) * reach)
		var hb: float = _head_h(pb.x, pb.z)
		if pb.y < hb + 0.05:
			pb.y = hb + 0.06
		_stick(model, pa, pb, _r(124.0, k, 0.035, 0.06), STICK.lerp(STICK_G, _h(Vector3(k, 1, 125.0))), 126.0 + k, k % 3 == 0)
	# --- long branches laid over the crown of the head (west) ---
	for k: int in 7:
		var a0: float = PI + _r(130.0, k, -1.1, 1.1)
		var pa: Vector3 = NEST_C + Vector3(cos(a0) * 1.0, RING_Y - 0.05, sin(a0) * 1.0)
		var dir := Vector3(cos(a0 + _r(131.0, k, -0.35, 0.35)), 0.0, sin(a0 + _r(131.0, k, -0.35, 0.35)))
		var pts: Array[Vector3] = [pa]
		var total: float = _r(132.0, k, 1.3, 2.3)
		for s: int in 3:
			var q: Vector3 = pa + dir * total * float(s + 1) / 3.0
			q.y = maxf(_head_h(q.x, q.z) + 0.07, 0.06)
			pts.append(q)
		_tube(model, pts, _r(133.0, k, 0.06, 0.09), 0.025, 6, STICK_G.lerp(STICK, _h(Vector3(k, 2, 134.0))), bark)
		# a forked side twig
		var f0: Vector3 = pts[1]
		var fd: Vector3 = (dir.rotated(Vector3.UP, 0.8 if k % 2 == 0 else -0.8)) * 0.6
		var f1: Vector3 = f0 + fd
		f1.y = maxf(_head_h(f1.x, f1.z) + 0.05, 0.05)
		_limb(model, f0, f1, 0.035, 0.012, 4, STICK_G, bark)
	# --- fallen twigs around the heap foot ---
	for k: int in 16:
		var p: Vector3 = Vector3(_r(140.0, k, -0.8, 2.6), 0.0, _r(141.0, k, -1.2, 3.8))
		if _head_h(p.x, p.z) > 0.0:
			continue
		var yaw: float = _r(142.0, k, 0.0, TAU)
		var d := Vector3(cos(yaw), 0.0, sin(yaw)) * _r(143.0, k, 0.35, 0.8)
		_stick(model, p + Vector3(0, 0.045, 0), p + d + Vector3(0, 0.035, 0), _r(144.0, k, 0.025, 0.045), STICK.lerp(STICK_G,
			_h(Vector3(k, 5, 145.0))), 146.0 + k, k % 4 == 0)
	# --- eggshells: halves in the bowl, fragments on the ground ---
	_shell(model, _xf(NEST_C + Vector3(0.3, _lining_h(0.4) + 0.06, -0.25), Vector3(0.5, 0.4, 0.6)), 0.19, 0.25, EGG, 150.0)
	_shell(model, _xf(NEST_C + Vector3(-0.35, _lining_h(0.45) + 0.1, 0.2), Vector3(2.4, 1.1, 0.3)), 0.19, 0.25, EGG, 151.0)
	for e: Array in [[Vector3(0.7, 0.0, 0.2), 152.0], [Vector3(1.5, 0.0, 2.5), 153.0], [Vector3(-0.2, 0.0, -0.9), 154.0]]:
		var ep: Vector3 = e[0]
		_shell(model, _xf(ep + Vector3(0, 0.1, 0), Vector3(_r(e[1], 1.0, 1.8, 2.8), _r(e[1], 2.0, 0.0, TAU), 0.3),
			Vector3.ONE * 0.8), 0.19, 0.25, EGG, e[1])
	# --- feathers stuck in the rim and lying below ---
	for k: int in 6:
		var a0: float = _r(160.0, k, 0.0, TAU)
		var pr: Vector3 = NEST_C + Vector3(cos(a0) * 1.15, RING_Y + 0.12, sin(a0) * 1.15)
		_feather(model, pr, -a0, _r(161.0, k, 0.25, 0.6), _r(162.0, k, 0.6, 0.85), 163.0 + k)
	for fp: Array in [[Vector3(0.9, 0.05, -0.5), 1.0], [Vector3(2.0, 0.05, 1.6), 2.4], [Vector3(-0.4, 0.05, 3.6), 4.0]]:
		_feather(model, fp[0], fp[1], 0.03, 0.8, 170.0 + float(fp[1]))
	# --- guano: white splashes on the crown of the head and on the ground below ---
	var splats: Array = [[Vector3(-2.15, 0, 0.45), 0.34], [Vector3(-2.45, 0, 2.3), 0.28], [Vector3(-1.75, 0, 2.65), 0.22],
		[Vector3(-2.6, 0, 1.2), 0.18], [Vector3(0.9, 0, 0.9), 0.38], [Vector3(1.6, 0, 2.0), 0.3], [Vector3(0.2, 0, -0.3), 0.26]]
	for i: int in splats.size():
		var sp: Array = splats[i]
		var c: Vector3 = sp[0]
		var on_head: bool = _head_h(c.x, c.z) > 0.0
		# A splash: a ragged main blot and a few flecks flung out around it.
		var hf: Callable = hh if on_head else Callable(self, &"_flat0")
		var lift: float = 0.03 if on_head else 0.022
		var rs: float = float(sp[1]) * 0.7
		_blob(model, c, rs, rs * 0.7, _r(180.0, i, 0.0, TAU), 10, 181.0 + i, GUANO, GUANO.lerp(GROOVE, 0.15), hf, lift, {"jag": 0.7})
		for f2: int in 4:
			var fa: float = _r(182.0 + i, f2, 0.0, TAU)
			var fp2: Vector3 = c + Vector3(cos(fa), 0.0, sin(fa)) * rs * _r(183.0 + i, f2, 1.2, 1.9)
			_blob(model, fp2, rs * 0.18, rs * 0.14, fa, 6, 184.0 + i * 7.0 + f2, GUANO, GUANO, hf, lift)
	# --- remains of a meal at the lair centre ---
	_skull(model, Transform3D(Basis(Vector3.UP, 2.2) * Basis(Vector3.BACK, 0.35), Vector3(0.55, 0.12, -0.55)), BONE, false, 190.0)
	_bone(model, Vector3(-0.1, 0.06, 0.0), Vector3(0.45, 0.05, 0.25), 0.045, BONE)
	_bone(model, Vector3(1.1, 0.05, -0.2), Vector3(1.3, 0.05, 0.35), 0.04, BONE_OLD)
	_rib(model, Vector3(0.3, 0.03, -1.1), Vector3(0.8, 0, 0.6).normalized(), 0.28, 1.6, 0.025, BONE)
	_contact(model, Vector3(NEST_C.x + 0.8, 0.0, NEST_C.z + 0.1), 1.9, 2.1, 16, 195.0)
	# --- Active: two whole eggs in the bowl + fresh feathers; Dormant: more broken shell, dry leaves in the bowl ---
	_egg(active, Transform3D(Basis(Vector3.BACK, 1.2) * Basis(Vector3.UP, 0.4), NEST_C + Vector3(-0.1, _lining_h(0.1) + 0.2, -0.12)),
		0.19, 0.26, 200.0)
	_egg(active, Transform3D(Basis(Vector3.RIGHT, 1.35) * Basis(Vector3.UP, 1.9), NEST_C + Vector3(0.28, _lining_h(0.3) + 0.2, 0.22)),
		0.19, 0.26, 201.0)
	for k: int in 3:
		var a0: float = _r(205.0, k, 0.0, TAU)
		_feather(active, NEST_C + Vector3(cos(a0) * 1.2, RING_Y + 0.18, sin(a0) * 1.2), -a0 + 0.3, 0.45, 0.75, 206.0 + k)
	_shell(dormant, _xf(NEST_C + Vector3(0.0, _lining_h(0.1) + 0.08, 0.05), Vector3(0.3, 2.0, -0.2)), 0.19, 0.25, EGG, 210.0)
	_shell(dormant, _xf(NEST_C + Vector3(0.25, _lining_h(0.35) + 0.1, 0.3), Vector3(2.6, 0.7, 0.4)), 0.19, 0.25, EGG, 211.0)
	_litter(dormant, NEST_C + Vector3(0.0, 0.0, 0.0), 0.7, 14, 212.0, func(x: float, z: float) -> float:
		return _lining_h(Vector2(x - NEST_C.x, z - NEST_C.z).length()))
	_report.append("nest: %d heap sticks; head top under the nest centre %.2f m, rim %.2f m" % [sk,
		_head_h(NEST_C.x - 0.6, NEST_C.z), RING_Y + 0.22])
	_scene("crag_nest.tscn", "CragNest", _commit(model, "crag_nest"), _commit(active, "crag_nest_active"),
		_commit(dormant, "crag_nest_dormant"), &"roc", Vector3(0.6, 0.0, 0.2),
		PackedVector3Array([Vector3(0.3, 1.4, 2.4), Vector3(0.6, -0.5, 1.2)]))


# =================================================================================================
# Greymane Hollow (Direwolf)
# =================================================================================================

func _hollow_h(x: float, z: float) -> float:
	var d: float = Vector2(x - BED_C.x, z - BED_C.z).length()
	return 0.022 + 0.012 * _ss(0.6, 1.2, d)


func _build_hollow() -> void:
	var model := Acc.new()
	var active := Acc.new()
	var dormant := Acc.new()
	var hh := func(x: float, z: float) -> float: return _hollow_h(x, z)
	var gh := Callable(self, &"_flat0")
	# --- the trampled earth of the bed, a faint dark hollow around it ---
	_contact(model, BED_C, 2.1, 1.8, 16, 300.0, 0.4)
	_blob(model, BED_C, 1.2, 1.0, 0.4, 18, 301.0, EARTH_D, EARTH.lerp(TURF, 0.35), gh, 0.02)
	# --- flattened fern fronds, pressed flat in a ring, tips out ---
	for k: int in 36:
		var a: float = k * TAU / 36.0 + _r(310.0, k, -0.12, 0.12)
		var dir := Vector3(cos(a), 0.0, sin(a))
		# Laid in a swirl, as by a big animal turning round and round before lying down.
		var base: Vector3 = BED_C + dir * _r(311.0, k, 0.3, 0.9) + Vector3(0.0, 0.035 + 0.004 * (k % 3), 0.0)
		var yaw: float = _yaw_x(dir.rotated(Vector3.UP, -0.8 + _r(312.0, k, -0.3, 0.3)))
		var col: Color = [FERN_FLAT, FERN_BRUISE, FERN_FLAT.lerp(FERN_BRUISE, 0.5), FERN_DEAD, FERN_FLAT][k % 5]
		_strip(model, Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, _r(313.0, k, -0.25, 0.25)), base),
			_r(314.0, k, 0.85, 1.3), _r(315.0, k, 0.24, 0.32), _r(316.0, k, 0.02, 0.1), 0.0, 7, col.darkened(0.1),
			col.lightened(0.08), 0.35, 0.4, {"kind": Kind.IVY, "tint": 0.08, "gmin": 0.5, "ymin": 0.45})
	# --- standing ferns around the far side (west / north), arching over the bed's edge ---
	var clumps: Array = [[2.35, 2.1], [2.95, 2.0], [3.55, 2.15], [4.3, 2.3], [1.7, 2.2]]
	for ci: int in clumps.size():
		var ca: float = clumps[ci][0]
		var cp: Vector3 = BED_C + Vector3(cos(ca), 0.0, sin(ca)) * float(clumps[ci][1])
		for k: int in 7:
			var a: float = k * TAU / 7.0 + ci
			var col: Color = FERN.lerp(FERN_L, _h(Vector3(ci, k, 320.0)))
			var ln: float = _r(321.0 + ci, k, 0.7, 1.0)
			_strip(model, Transform3D(Basis(Vector3.UP, a), cp + Vector3(0.0, 0.02, 0.0)), ln, 0.26,
				_r(322.0 + ci, k, 1.05, 1.3), 0.55, 7, col.darkened(0.15), col, 0.35, 0.4, {"kind": Kind.IVY,
				"two_sided": true, "tint": 0.08, "wind": Vector2(0.0, 0.8)})
	# --- the bone pile: long bones heaped on a mound, deer skulls on top ---
	_contact(model, BONE_C, 1.1, 0.95, 12, 330.0)
	_part(model, _sph(1.0, 10, 4), _xf(BONE_C + Vector3(0, -0.02, 0), Vector3.ZERO, Vector3(0.62, 0.16, 0.55)), EARTH_D,
		{"kind": Kind.STONE, "normals": "smooth", "tint": 0.1, "gmin": 0.4, "ymin": 0.3, "col2": EARTH})
	for k: int in 16:
		var a: float = _r(331.0, k, 0.0, TAU)
		var d: float = sqrt(_h(Vector3(332.0, k, 1.0))) * 0.55
		var c: Vector3 = BONE_C + Vector3(cos(a) * d, 0.0, sin(a) * d * 0.85)
		c.y = 0.07 + 0.26 * (1.0 - d / 0.55) + _r(333.0, k, 0.0, 0.07)
		var yaw: float = _r(334.0, k, 0.0, TAU)
		var half: float = _r(335.0, k, 0.2, 0.34)
		var dv := Vector3(cos(yaw), _r(336.0, k, -0.3, 0.3), sin(yaw)).normalized() * half
		var col: Color = [BONE, BONE_OLD, IVORY, BONE][k % 4]
		_bone(model, c - dv, c + dv, _r(337.0, k, 0.035, 0.05), col)
	_skull(model, Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.RIGHT, -0.35), BONE_C + Vector3(-0.05, 0.32, 0.1)), BONE, true, 340.0)
	_skull(model, Transform3D(Basis(Vector3.UP, 3.7) * Basis(Vector3.BACK, 1.2), BONE_C + Vector3(0.5, 0.12, -0.3)), BONE_OLD, true, 341.0)
	for k: int in 4:
		var rb: Vector3 = BONE_C + Vector3(_r(342.0, k, -0.7, 0.7), 0.03, _r(343.0, k, 0.35, 0.7) * (1.0 if k % 2 == 0 else -1.0))
		_rib(model, rb, Vector3(cos(k * 1.3), 0.0, sin(k * 1.3)), 0.26, 1.7, 0.024, BONE_OLD)
	# Bones strewn about the hollow.
	var strewn: Array[Vector3] = [Vector3(0.6, 0, 0.9), Vector3(-1.9, 0, 0.7), Vector3(0.3, 0, -1.9), Vector3(2.4, 0, -0.1),
		Vector3(-0.3, 0, 1.6), Vector3(2.0, 0, -2.2)]
	for k: int in strewn.size():
		var yaw2: float = _r(350.0, k, 0.0, TAU)
		var dv2 := Vector3(cos(yaw2), 0.0, sin(yaw2)) * _r(351.0, k, 0.18, 0.3)
		_bone(model, strewn[k] - dv2 + Vector3(0, 0.05, 0), strewn[k] + dv2 + Vector3(0, 0.05, 0), 0.04, [BONE, BONE_OLD][k % 2])
	# --- a mossy fallen log along the north edge, claw-scored on the bed side ---
	var log_arr: Array = _cyl(0.3, 0.34, LOG_A.distance_to(LOG_B), 10, 2)
	var log_xf := Transform3D(_along(LOG_A, LOG_B), (LOG_A + LOG_B) * 0.5 + Vector3(0.0, 0.24, 0.0))
	_part(model, log_arr, log_xf, BARK, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.1, "no_caps": true,
		"col2": BARK_D, "jitter": 0.02, "seed": 360.0})
	for e: Array in [[LOG_A, LOG_B], [LOG_B, LOG_A]]:
		var ea: Vector3 = e[0]
		var eb: Vector3 = e[1]
		var d3: Vector3 = (ea - eb).normalized()
		var cp2: Vector3 = ea + Vector3(0.0, 0.24, 0.0)
		_part(model, _cyl(0.27, 0.31, 0.06, 10), Transform3D(_along(cp2 - d3, cp2), cp2), WOOD_L, {"kind": Kind.BARK,
			"tint": 0.06, "jitter": 0.03, "seed": 361.0})
		_part(model, _cyl(0.1, 0.2, 0.22, 6), Transform3D(_along(cp2, cp2 + d3), cp2 + d3 * 0.1), WOOD_L.darkened(0.15),
			{"kind": Kind.BARK, "tint": 0.1, "jitter": 0.04, "seed": 362.0})
	var log_tris: PackedVector3Array = _placed(log_arr, log_xf)
	var log_mid: Vector3 = (LOG_A + LOG_B) * 0.5 + Vector3(0.0, 0.3, 0.0)
	var toward_bed: Vector3 = (BED_C - log_mid)
	toward_bed.y = 0.0
	toward_bed = toward_bed.normalized()
	var log_dir: Vector3 = (LOG_B - LOG_A).normalized()
	for g: int in 2:
		_gouges(model, log_tris, log_mid + log_dir * (-0.55 + 1.1 * g), (toward_bed + Vector3.UP * 0.5).normalized(),
			0.6 if g == 0 else -0.5, 4, 0.34, 0.07, 0.04)
	for k: int in 5:
		var mp: Vector3 = LOG_A.lerp(LOG_B, 0.15 + 0.17 * k) + Vector3(0.0, 0.5, 0.0) + log_dir.cross(Vector3.UP) * _r(365.0, k, -0.1, 0.1)
		_moss(model, mp, _r(366.0, k, 0.14, 0.22), Vector3(1.4, 0.45, 1.0), 367.0 + k, MOSS if k % 2 == 0 else MOSS_L)
	_contact(model, (LOG_A + LOG_B) * 0.5, 1.8, 0.55, 12, 368.0, -_yaw_x(log_dir))
	# --- low mossy rocks at the hollow's lip ---
	for rk: Array in [[Vector3(-2.65, 0.0, 0.95), Vector3(0.72, 0.42, 0.58), 370.0], [Vector3(2.75, 0.0, 0.55),
			Vector3(0.52, 0.34, 0.44), 371.0]]:
		var rp: Vector3 = rk[0]
		var rr: Vector3 = rk[1]
		_part(model, _chunk(rr, 6, rk[2], 0.75, 8, 5), _xf(rp + Vector3(0.0, rr.y * 0.45, 0.0), Vector3(0.0, rk[2], 0.0)),
			GRANITE, {"kind": Kind.STONE, "moss": 0.9, "tint": 0.08})
		_contact(model, rp, rr.x * 1.5, rr.z * 1.5, 12, rk[2])
	# --- Active: grey fur tufts on the bed, a fresh kill's ribcage, prints leading out ---
	for k: int in 3:
		var a4: float = _r(380.0, k, 0.0, TAU)
		var d4: float = _r(381.0, k, 0.1, 0.9)
		_fur(active, BED_C + Vector3(cos(a4) * d4, 0.04, sin(a4) * d4), _r(382.0, k, 0.8, 1.1), 383.0 + k, FUR)
	var rc := Vector3(0.45, 0.0, 0.75)
	_limb(active, rc + Vector3(-0.35, 0.08, -0.1), rc + Vector3(0.35, 0.08, 0.1), 0.045, 0.035, 6, BONE_FRESH, _bone_o(BONE_FRESH))
	for k: int in 6:
		var along: float = -0.25 + 0.1 * k
		for s: float in [-1.0, 1.0]:
			var b0: Vector3 = rc + Vector3(along, 0.09, along * 0.28)
			var rl: float = _r(386.0 + s, k, 0.7, 1.15)
			var pts: Array[Vector3] = [b0, b0 + Vector3(0.02, 0.17, 0.2 * s) * rl, b0 + Vector3(0.04, 0.2, 0.36 * s) * rl,
				b0 + Vector3(0.05, 0.08, 0.44 * s) * rl]
			_tube(active, pts, 0.022, 0.014, 4, BONE_FRESH.lerp(BONE, 0.3), _bone_o(BONE_FRESH))
	_contact(active, rc, 0.7, 0.55, 10, 390.0)
	for k: int in 6:
		var p5: Vector3 = BED_C + Vector3(1.0 + 0.5 * k, 0.0, 0.25 + (0.12 if k % 2 == 0 else -0.12) + 0.2 * k)
		_print(active, p5, 0.35, "wolf", gh, 391.0 + k)
	# --- Dormant: toadstools on the log, fallen leaves drifted onto the bed ---
	for k: int in 3:
		_mushroom(dormant, LOG_A.lerp(LOG_B, 0.3 + 0.12 * k) + Vector3(0.0, 0.46, 0.0) + toward_bed * 0.18, _r(395.0, k, 0.9, 1.3), 396.0 + k)
	_litter(dormant, BED_C, 1.0, 18, 397.0, func(x: float, z: float) -> float: return 0.05 + 0.0 * x * z)
	_scene("greymane_hollow.tscn", "GreymaneHollow", _commit(model, "greymane_hollow"), _commit(active, "greymane_hollow_active"),
		_commit(dormant, "greymane_hollow_dormant"), &"direwolf", BED_C,
		PackedVector3Array([Vector3(BED_C.x, BED_C.z, 2.1), Vector3(BONE_C.x, BONE_C.z, 1.0)]))


# =================================================================================================
# Old Wood Den (Grizzlemaw)
# =================================================================================================

## The mouth frame: origin at the foot of the cave mouth, +Z out of the mouth (DEN_FACE), +X across.
func _den_frame() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(DEN_FACE.x, DEN_FACE.z)), DEN_ROCK + DEN_FACE * 1.05)


## Spoil fan height in the mouth frame (u across, w out): two lobes of thrown earth beside a trodden trough.
func _spoil_h(u: float, w: float) -> float:
	var e: float = pow(u / 2.3, 2.0) + pow((w - 0.9) / 2.2, 2.0)
	if e > 1.0 or w < -0.4:
		return -0.03   # sinks under the ground: the fan's edge melts into the turf
	var lobes: float = 0.62 * (exp(-pow((u - 0.95) / 0.5, 2.0)) + exp(-pow((u + 1.0) / 0.55, 2.0))) * exp(-pow((w - 0.65) / 0.95, 2.0))
	var trough: float = 0.05 * exp(-pow(u / 0.5, 2.0)) - 0.14 * exp(-pow(u / 0.6, 2.0)) * (1.0 - _ss(0.25, 1.1, w))
	var clods: float = 0.04 * (_vn(u * 3.0, w * 3.0, 1.0) - 0.5)
	return maxf((lobes + trough + clods) * (1.0 - _ss(0.55, 1.0, e)), 0.004)


func _build_den() -> void:
	var model := Acc.new()
	var active := Acc.new()
	var dormant := Acc.new()
	var fr: Transform3D = _den_frame()
	var inv: Transform3D = fr.affine_inverse()
	var sh := func(x: float, z: float) -> float:
		var q: Vector3 = inv * Vector3(x, 0.0, z)
		return maxf(_spoil_h(q.x, q.z), 0.0)
	var gh := Callable(self, &"_flat0")
	# --- the boulder, heaved up on the mouth side over the dug hole; its back half sunk deep in the ground ---
	var yawf: float = atan2(DEN_FACE.x, DEN_FACE.z)
	var rock_arr: Array = _chunk(Vector3(2.15, 1.3, 1.8), 9, 400.0, 0.72, 14, 9)
	var rv: PackedVector3Array = rock_arr[Mesh.ARRAY_VERTEX]
	for i: int in rv.size():
		var p: Vector3 = rv[i]
		if p.y < 0.0:
			p.y *= 1.0 + 1.1 * (1.0 - _ss(-0.2, 0.9, p.z))
		rv[i] = p
	rock_arr[Mesh.ARRAY_VERTEX] = rv
	var rock_xf := Transform3D(Basis(Vector3.UP, yawf) * Basis(Vector3.RIGHT, -0.36), DEN_ROCK + Vector3(0.0, 1.5, 0.0))
	var rock_tris: PackedVector3Array = _placed(rock_arr, rock_xf)
	_part(model, rock_arr, rock_xf, BOULDER, {"kind": Kind.STONE, "moss": 0.85, "tint": 0.07, "col2": BOULDER_W})
	_contact(model, DEN_ROCK + DEN_FACE * 0.2, 2.6, 2.2, 16, 401.0, -yawf)
	# Earth banks under the heaved-up front corners: the walls of the dug hole.
	for s: float in [-1.0, 1.0]:
		var bank_c: Vector3 = fr * Vector3(1.4 * s, 0.0, -0.45)
		_part(model, _chunk(Vector3(0.62, 0.75, 1.0), 5, 405.0 + s, 0.72, 9, 5), _xf(bank_c + Vector3(0.0, 0.1, 0.0),
			Vector3(0.0, yawf + 0.35 * s, 0.0)), EARTH.lerp(EARTH_D, 0.35), {"kind": Kind.STONE, "moss": 0.35, "tint": 0.12,
			"gmin": 0.45, "ymin": 0.3, "col2": EARTH_L})
	# --- the cave mouth: a dark arch under the lip, leaning back into the dark ---
	var arch_w: float = 0.85
	var arch_h: float = 1.1
	var mv := PackedVector3Array()
	var mn := PackedVector3Array()
	var mc := PackedColorArray()
	var mi := PackedInt32Array()
	var lean := Basis(Vector3.RIGHT, -0.35)
	var arch_at := Vector3(0.0, 0.02, -0.15)
	mv.append(fr * (arch_at + lean * Vector3(0.0, 0.2, -0.3)))
	mn.append(fr.basis * Vector3(0, 0.3, 1).normalized())
	mc.append(HOLE)
	for i: int in 13:
		var a: float = PI * float(i) / 12.0
		var p := Vector3(cos(a) * arch_w * (1.0 + 0.08 * sin(a * 5.0)), sin(a) * arch_h, 0.0)
		mv.append(fr * (arch_at + lean * p))
		mn.append(fr.basis * Vector3(0, 0.3, 1).normalized())
		mc.append(HOLE_EDGE)
	for i: int in 12:
		mi.append_array([0, 1 + i, 2 + i])
	_part(model, _mk(mv, mn, mi), Transform3D.IDENTITY, HOLE, {"kind": Kind.STONE, "cols": mc, "normals": "smooth",
		"tint": 0.0, "gmin": 0.3, "ymin": 0.3})
	# The throat: dark trodden earth running in under the rock.
	_blob(model, fr * Vector3(0.0, 0.0, 0.15), 0.8, 0.6, -yawf, 12, 402.0, HOLE, HOLE_EDGE.lerp(EARTH_D, 0.5), gh, 0.03)
	# Earth lumps at the arch's feet.
	for k: int in 6:
		var a2: float = PI * ([0.02, 0.14, 0.27, 0.73, 0.86, 0.98][k])
		var p2: Vector3 = fr * (arch_at + lean * Vector3(cos(a2) * (arch_w + 0.1), sin(a2) * (arch_h + 0.05), 0.1))
		_clod(model, p2, _r(403.0, k, 0.18, 0.28), 404.0 + k, EARTH.lerp(EARTH_D, 0.5), false)
	# Roots dangling over the mouth from the rock's underside, and roots gripping the ground at the rock's sides.
	for k: int in 6:
		var u: float = lerpf(-0.65, 0.65, float(k) / 5.0) + _r(410.0, k, -0.08, 0.08)
		var from: Vector3 = fr * Vector3(u, 0.05, _r(417.0, k, 0.0, 0.3))
		var hit0: Dictionary = _ray(rock_tris, from, Vector3.UP)
		if hit0.is_empty():
			continue
		var top: Vector3 = hit0["p"]
		var len: float = minf(_r(411.0, k, 0.3, 0.6), top.y - 0.12)
		if len < 0.15:
			continue
		var pts: Array[Vector3] = [top + Vector3(0.0, 0.03, 0.0), top + Vector3(_r(412.0, k, -0.06, 0.06), -len * 0.5, _r(413.0, k, -0.02, 0.06)),
			top + Vector3(_r(414.0, k, -0.1, 0.1), -len, _r(415.0, k, 0.0, 0.08))]
		_tube(model, pts, _r(416.0, k, 0.03, 0.05), 0.01, 4, ROOTC, {"kind": Kind.BARK, "tint": 0.1})
	for k: int in 5:
		var a3: float = _r(420.0, k, 0.0, TAU)
		var hit: Dictionary = _ray(rock_tris, DEN_ROCK + Vector3(cos(a3) * 4.0, 0.2, sin(a3) * 4.0), Vector3(-cos(a3), 0.0, -sin(a3)))
		if hit.is_empty():
			continue
		var hp: Vector3 = hit["p"]
		var od := Vector3(cos(a3), 0.0, sin(a3))
		var base_y: float = 0.12
		var pts2: Array[Vector3] = [Vector3(hp.x, base_y + 0.1, hp.z) - od * 0.1, Vector3(hp.x, base_y, hp.z) + od * 0.35,
			Vector3(hp.x, 0.06, hp.z) + od * 0.8 + od.cross(Vector3.UP) * 0.15, Vector3(hp.x, 0.03, hp.z) + od * 1.2]
		_tube(model, pts2, _r(421.0, k, 0.06, 0.1), 0.02, 6, ROOTC, {"kind": Kind.BARK, "tint": 0.1})
	# --- the spoil fan: earth thrown out to both sides of a trodden trough, raked by claws ---
	var cols: int = 22
	var rows: int = 14
	_patch(model, cols, rows, func(i: int, j: int) -> Vector3:
		var u: float = lerpf(-2.4, 2.4, float(i) / float(cols))
		var w: float = lerpf(-0.35, 3.2, float(j) / float(rows))
		var p: Vector3 = fr * Vector3(u, 0.0, w)
		return Vector3(p.x, _spoil_h(u, w), p.z),
		func(p: Vector3) -> Color:
			var q: Vector3 = inv * Vector3(p.x, 0.0, p.z)
			var h: float = _spoil_h(q.x, q.z)
			var c: Color = EARTH.lerp(EARTH_L, _ss(0.08, 0.3, h) * 0.7 + (_vn(q.x * 2.0, q.z * 2.0) - 0.5) * 0.4)
			c = c.lerp(EARTH_D, exp(-pow(q.x / 0.45, 2.0)) * 0.7)
			if q.z < 0.35:
				c = c.lerp(HOLE_EDGE, _ss(0.35, -0.2, q.z))
			var e: float = pow(q.x / 2.3, 2.0) + pow((q.z - 0.9) / 2.2, 2.0)
			return c.lerp(TURF.lerp(EARTH_D, 0.5), _ss(0.7, 1.0, e)),
		func(p: Vector3) -> bool:
			var q: Vector3 = inv * Vector3(p.x, 0.0, p.z)
			return pow(q.x / 2.3, 2.0) + pow((q.z - 0.9) / 2.2, 2.0) < 1.0 and q.z > -0.4,
		{"kind": Kind.STONE, "moss": 0.0})
	# Short claw drags on the lobes (in fours, like a raking paw), never long straight lines.
	for g: int in 2:
		var gu: float = 1.0 if g == 0 else -1.05
		for k: int in 4:
			var u0: float = gu + (float(k) - 1.5) * 0.11
			var pts3: Array[Vector3] = []
			for s: int in 3:
				pts3.append(fr * Vector3(u0 + 0.05 * s * gu, 0.0, 0.55 + 0.22 * s + 0.05 * k))
			_ribbon(model, pts3, 0.05, EARTH_D, sh, 0.022)
	for k: int in 12:
		var q2 := Vector3(_r(430.0, k, -2.2, 2.2), 0.0, _r(431.0, k, 0.3, 3.3))
		var p3: Vector3 = fr * q2
		p3.y = maxf(_spoil_h(q2.x, q2.z), 0.0) + 0.04
		_clod(model, p3, _r(432.0, k, 0.1, 0.2), 433.0 + k, EARTH.lerp(EARTH_D, _h(Vector3(k, 1, 434.0))), k % 4 == 0)
	# --- claw marks raked down the rock's face, moss and a fern on its crown ---
	_gouges(model, rock_tris, DEN_ROCK + Vector3(0.0, 1.2, 0.0), (DEN_FACE.rotated(Vector3.UP, 1.1) + Vector3.UP * 0.3).normalized(),
		0.25, 3, 0.6, 0.1, 0.045)
	_gouges(model, rock_tris, DEN_ROCK + Vector3(0.0, 1.3, 0.0), (DEN_FACE.rotated(Vector3.UP, -1.0) + Vector3.UP * 0.35).normalized(),
		-0.3, 3, 0.55, 0.1, 0.045)
	var tops: Array[Vector3] = []
	for k: int in 7:
		var off := Vector3(_r(440.0, k, -1.2, 1.2), 0.0, _r(441.0, k, -1.0, 1.0))
		var hit2: Dictionary = _ray(rock_tris, DEN_ROCK + off + Vector3(0.0, 5.0, 0.0), Vector3.DOWN)
		if hit2.is_empty():
			continue
		var tp: Vector3 = hit2["p"]
		tops.append(tp)
		_moss(model, tp + Vector3(0.0, 0.02, 0.0), _r(442.0, k, 0.2, 0.36), Vector3(1.3, 0.4, 1.1), 443.0 + k,
			MOSS if k % 2 == 0 else MOSS_L)
	if not tops.is_empty():
		var fern_at: Vector3 = tops[tops.size() - 1]
		for k: int in 6:
			var col: Color = FERN.lerp(FERN_L, _h(Vector3(k, 3, 450.0)))
			_strip(model, Transform3D(Basis(Vector3.UP, k * TAU / 6.0 + 0.3), fern_at + Vector3(0.0, 0.03, 0.0)), 0.75, 0.24,
				1.15, 0.6, 6, col.darkened(0.15), col, 0.35, 0.4, {"kind": Kind.IVY, "two_sided": true, "tint": 0.08,
				"wind": Vector2(fern_at.y, fern_at.y + 0.7)})
	# --- dressed blocks fallen from the aqueduct, toward the pier ---
	for bk: Array in [[Vector3(5.75, 0.0, -4.55), Vector3(0.95, 0.55, 0.62), Vector3(0.12, 0.45, 0.05), 460.0],
			[Vector3(6.85, 0.0, -2.95), Vector3(0.8, 0.5, 0.58), Vector3(-0.05, -0.35, 0.28), 461.0],
			[Vector3(7.45, 0.0, -1.75), Vector3(0.7, 0.42, 0.5), Vector3(0.2, 1.2, -0.1), 462.0],
			[Vector3(1.05, 0.0, -5.25), Vector3(0.62, 0.4, 0.48), Vector3(-0.15, 2.3, 0.12), 463.0]]:
		var bp: Vector3 = bk[0]
		var bs: Vector3 = bk[1]
		_part(model, _box(bs), _xf(bp + Vector3(0.0, bs.y * 0.32, 0.0), bk[2]), LIME, {"kind": Kind.STONE, "moss": 0.8,
			"tint": 0.08, "jitter": 0.035, "seed": bk[3], "col2": LIME_D})
		_contact(model, bp, bs.x * 1.1, bs.z * 1.2, 10, bk[3], float((bk[2] as Vector3).y))
	# --- gnawed bones by the mouth ---
	var bones_at: Vector3 = fr * Vector3(1.55, 0.0, 1.9)
	_skull(model, Transform3D(Basis(Vector3.UP, 1.0) * Basis(Vector3.BACK, 0.4), bones_at + Vector3(0.0, 0.1 + maxf(_spoil_h(1.55, 1.9), 0.0), 0.0)),
		BONE, true, 470.0)
	for k: int in 4:
		var q3 := Vector3(_r(471.0, k, -1.8, -0.4) if k % 2 == 0 else _r(472.0, k, 0.4, 1.9), 0.0, _r(473.0, k, 1.2, 3.0))
		var c3: Vector3 = fr * q3
		c3.y = maxf(_spoil_h(q3.x, q3.z), 0.0) + 0.05
		var yaw3: float = _r(474.0, k, 0.0, TAU)
		var dv := Vector3(cos(yaw3), 0.1, sin(yaw3)) * 0.26
		_bone(model, c3 - dv, c3 + dv, 0.045, [BONE, BONE_OLD][k % 2])
	# --- Active: bear prints down the trough and away, fresh clods, a tuft of brown fur on the lip ---
	for k: int in 7:
		var q4 := Vector3((0.18 if k % 2 == 0 else -0.18), 0.0, 0.7 + 0.55 * k)
		var p4: Vector3 = fr * q4
		_print(active, p4, atan2(fr.basis.z.z, fr.basis.z.x), "bear", sh, 480.0 + k)
	for k: int in 8:
		var q5 := Vector3(_r(490.0, k, -1.8, 1.8), 0.0, _r(491.0, k, 0.2, 2.2))
		var p5: Vector3 = fr * q5
		p5.y = maxf(_spoil_h(q5.x, q5.z), 0.0) + 0.05
		_clod(active, p5, _r(492.0, k, 0.08, 0.16), 493.0 + k, EARTH_D.darkened(0.25), false)
	_fur(active, fr * Vector3(0.62, 0.12, 0.2), 1.3, 495.0, BEAR_FUR)
	_fur(active, fr * Vector3(-0.7, 0.14, 0.1), 1.1, 496.0, BEAR_FUR)
	# --- Dormant: a cobweb across the mouth, fallen leaves drifted over the spoil ---
	var rim: Array[Vector3] = []
	for i: int in 9:
		var a4: float = PI * (0.03 + 0.94 * float(i) / 8.0)
		rim.append(fr * (arch_at + lean * Vector3(cos(a4) * arch_w * 0.95, sin(a4) * arch_h * 0.95 + 0.02, 0.06)))
	var hub: Vector3 = fr * (arch_at + lean * Vector3(0.05, arch_h * 0.32, 0.1))
	_web(dormant, hub, rim, Web.ORB, 0.02)
	_litter(dormant, fr * Vector3(0.0, 0.0, 1.4), 1.9, 26, 500.0, sh)
	_scene("old_wood_den.tscn", "OldWoodDen", _commit(model, "old_wood_den"), _commit(active, "old_wood_den_active"),
		_commit(dormant, "old_wood_den_dormant"), &"grizzlemaw", fr * Vector3(0.0, 0.0, 1.8),
		PackedVector3Array([Vector3((fr * Vector3(0, 0, 1.0)).x, (fr * Vector3(0, 0, 1.0)).z, 2.4),
			Vector3(DEN_ROCK.x, DEN_ROCK.z, 2.3)]))
