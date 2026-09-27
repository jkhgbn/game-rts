extends RefCounted
## Roc geometry (task 12.V28). Every mesh is built once per game (static cache) in MODEL space: face +Z, origin on the
## ground, body centre at y 4.0 (= FlyerModel.BAKE_HEIGHT; the rig lifts the whole bird to fly_height 2.5). The right
## side is authored (x > 0), the left mirrors it. No class_name: roc.gd preloads this file.
## Vertex COLOR for roc_feather.gdshader: r feather-row pattern, g pale blend, b dark tip blend, a shaft line.
## Every surface uses a Stormcrest (A) material; roc.gd overrides them per surface with the Duskwing (B) ones.
## Shape language (40 m read): a huge raptor seen from above = two broad wings (span ~6.6 m) ending in 5 separated
## "finger" primaries with dark tips, a fanned banded tail, a big head with a hooked gold beak and a crest of five pale
## plumes sweeping back (plus two ear tufts), shaggy neck hackles, pale booted legs with dark talons.

const MAT_DIR := "res://art/units/neutral/beasts/roc/materials/"
const FEATHER := "roc_storm_feather"
const HORN := "roc_storm_horn"
const EYE := "roc_storm_eye"
const DEG := PI / 180.0

# ---- anatomy (model space, right side)
const SHOULDER := Vector3(0.34, 4.20, 0.34)
const ELBOW := Vector3(1.00, 4.27, 0.14)
const WRIST := Vector3(1.70, 4.31, 0.30)
const HAND := Vector3(2.15, 4.33, 0.22)
const ROOT_TRAIL := Vector3(0.30, 4.06, -0.52)
const WRIST_TRAIL := Vector3(1.66, 4.22, -0.66)
const TAIL_BASE := Vector3(0.0, 4.00, -0.72)
const TAIL_LEN := 1.05
const BEAK_TIP := Vector3(0.0, 4.38, 1.66)
const HIP := Vector3(0.19, 3.80, 0.02)
## Primaries, outer (0) to inner (6): angle from +X toward the back (deg), length (m).
const PRIM_ANG: Array[float] = [-8.0, 5.0, 18.0, 31.0, 44.0, 58.0, 72.0]
const PRIM_LEN: Array[float] = [1.0, 1.18, 1.22, 1.16, 1.06, 0.94, 0.82]

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}


## One surface under construction.
class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var c := PackedColorArray()
	var i := PackedInt32Array()


static func mat(nm: String) -> Material:
	if not _mats.has(nm):
		_mats[nm] = load(MAT_DIR + nm + ".tres")
	return _mats[nm]


static func mx(p: Vector3, sx: float) -> Vector3:
	return Vector3(p.x * sx, p.y, p.z)


# ================================================================ helpers

## Catmull-Rom point on pts at v (0..1).
static func cr(pts: Array[Vector3], v: float) -> Vector3:
	var n := pts.size()
	var f := clampf(v, 0.0, 1.0) * float(n - 1)
	var i := mini(int(f), n - 2)
	var t := f - float(i)
	var p0 := pts[maxi(i - 1, 0)]
	var p1 := pts[i]
	var p2 := pts[i + 1]
	var p3 := pts[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


## Rows [v, a, b, c, d] -> Vector4 at v (smooth between rows).
static func table(tab: Array, v: float) -> Vector4:
	var r0: Array = tab[0]
	if v <= float(r0[0]):
		return Vector4(r0[1], r0[2], r0[3], r0[4])
	for k: int in range(1, tab.size()):
		var r1: Array = tab[k]
		if v <= float(r1[0]):
			var a := (v - float(r0[0])) / maxf(float(r1[0]) - float(r0[0]), 0.0001)
			a = a * a * (3.0 - 2.0 * a)
			return Vector4(lerpf(r0[1], r1[1], a), lerpf(r0[2], r1[2], a), lerpf(r0[3], r1[3], a), lerpf(r0[4], r1[4], a))
		r0 = r1
	return Vector4(r0[1], r0[2], r0[3], r0[4])


static func bump(x: float, c: float, w: float) -> float:
	return exp(-pow((x - c) / w, 2.0))


## Rounded feather tips along an edge: 1 at the middle of each of `count` feathers, 0 between them.
static func scallop(u: float, count: float) -> float:
	return sin(PI * fposmod(u * count, 1.0))


static func _quad(s: Surf, a: int, b: int, c: int, d: int) -> void:
	var fnn := (s.v[d] - s.v[a]).cross(s.v[b] - s.v[a])
	if fnn.length_squared() < 1e-14:
		fnn = (s.v[c] - s.v[b]).cross(s.v[d] - s.v[b])
	if fnn.dot(s.n[a] + s.n[b] + s.n[c] + s.n[d]) >= 0.0:
		s.i.append_array(PackedInt32Array([a, b, d, b, c, d]))
	else:
		s.i.append_array(PackedInt32Array([a, d, b, b, d, c]))


## Grid p = fn(u, v), u over cols, v over rows. Normals by finite differences, turned away from ctr(u, v).
static func grid(s: Surf, fn: Callable, ctr: Callable, col: Callable, uvf: Callable, cols: int, rows: int) -> void:
	var base := s.v.size()
	const E := 0.002
	for j: int in rows + 1:
		var v := float(j) / float(rows)
		for i: int in cols + 1:
			var u := float(i) / float(cols)
			var p: Vector3 = fn.call(u, v)
			var du: Vector3 = (fn.call(minf(u + E, 1.0), v) as Vector3) - (fn.call(maxf(u - E, 0.0), v) as Vector3)
			var dv: Vector3 = (fn.call(u, minf(v + E, 1.0)) as Vector3) - (fn.call(u, maxf(v - E, 0.0)) as Vector3)
			var nn := dv.cross(du)
			var o: Vector3 = p - (ctr.call(u, v) as Vector3)
			if nn.length_squared() < 1e-12:
				nn = o
			if nn.length_squared() < 1e-12:
				nn = Vector3.UP
			nn = nn.normalized()
			if nn.dot(o) < 0.0:
				nn = -nn
			s.v.append(p)
			s.n.append(nn)
			s.uv.append(uvf.call(u, v))
			s.c.append(col.call(u, v))
	for j: int in rows:
		for i: int in cols:
			var q0 := base + j * (cols + 1) + i
			_quad(s, q0, q0 + 1, q0 + cols + 2, q0 + cols + 1)


## Tube along a Catmull-Rom spine. prof(v) -> Vector4(side r, top r, bottom r, 0); col(ca, v) -> Color with ca the
## cosine of the angle from the top. The frame's side axis follows side_ref. UV = (u * u_len, metres along).
static func loft(s: Surf, pts: Array[Vector3], prof: Callable, col: Callable, ring: int, samples: int,
		side_ref: Vector3 = Vector3.RIGHT, u_len: float = 1.0) -> void:
	var total := 0.0
	for k: int in pts.size() - 1:
		total += pts[k].distance_to(pts[k + 1])
	var fn := func(u: float, v: float) -> Vector3:
		var tn := (cr(pts, minf(v + 0.01, 1.0)) - cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var x := (side_ref - tn * side_ref.dot(tn)).normalized()
		var up := tn.cross(x)
		if up.y < -0.2:
			# keep the profile's top (and ca > 0) facing the sky whichever way the spine runs
			up = -up
			x = -x
		var pr: Vector4 = prof.call(v)
		var a := TAU * u
		var ca := cos(a)
		var ry := pr.y if ca >= 0.0 else pr.z
		return cr(pts, v) + x * (pr.x * sin(a)) + up * (ry * ca)
	var ctr := func(_u: float, v: float) -> Vector3:
		return cr(pts, v)
	var colf := func(u: float, v: float) -> Color:
		return col.call(cos(TAU * u), v)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * u_len, v * total)
	grid(s, fn, ctr, colf, uvf, ring, samples)


static func round_prof(r0: float, r1: float) -> Callable:
	return func(v: float) -> Vector4:
		var r := lerpf(r0, r1, v)
		return Vector4(r, r, r, 0.0)


## Constant colour for blob() (one argument: the direction).
static func flat_col(c: Color) -> Callable:
	return func(_d: Vector3) -> Color:
		return c


## Constant colour for loft() (two arguments: ca, v).
static func flat_col2(c: Color) -> Callable:
	return func(_ca: float, _v: float) -> Color:
		return c


## Lumpy ellipsoid at c (radii r, rotated by b); colf(dir) -> Color with dir the unit direction before the basis.
static func blob(s: Surf, c: Vector3, r: Vector3, colf: Callable, b: Basis = Basis.IDENTITY, lump: float = 0.03,
		cols: int = 10, rows: int = 6) -> void:
	var fn := func(u: float, v: float) -> Vector3:
		var a := TAU * u
		var th := PI * v
		var k := 1.0 + lump * sin(5.0 * a + 1.3) * sin(3.0 * th + 0.4)
		return c + b * Vector3(sin(th) * sin(a) * r.x * k, cos(th) * r.y * k, sin(th) * cos(a) * r.z * k)
	var ctr := func(_u: float, _v: float) -> Vector3:
		return c
	var col := func(u: float, v: float) -> Color:
		var a := TAU * u
		var th := PI * v
		return colf.call(Vector3(sin(th) * sin(a), cos(th), sin(th) * cos(a)))
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u, v)
	grid(s, fn, ctr, col, uvf, cols, rows)


## Tapered round horn / toe / talon along pts (r0 base, r1 tip); col(v) -> Color.
static func horn(s: Surf, pts: Array[Vector3], r0: float, r1: float, col: Callable, ring: int = 6, samples: int = 5,
		side_ref: Vector3 = Vector3.RIGHT) -> void:
	var d := (pts[pts.size() - 1] - pts[0]).normalized()
	var sr := side_ref
	if absf(d.dot(sr)) > 0.9:
		sr = Vector3.UP if absf(d.y) < 0.9 else Vector3.FORWARD
	var prof := func(v: float) -> Vector4:
		var r := lerpf(r0, r1, pow(v, 0.85)) + 0.003
		return Vector4(r, r, r, 0.0)
	var colf := func(_ca: float, v: float) -> Color:
		return col.call(v)
	loft(s, pts, prof, colf, ring, samples, sr)


## A feather blade: a thin double-sided strip along a Catmull-Rom path; width(v) m, facing nref (its top), a raised
## shaft of th m. col_top / col_bot (u, v) -> Color; UV = (u across 0..1, metres along).
static func blade(s: Surf, pts: Array[Vector3], width: Callable, nref: Vector3, th: float, col_top: Callable,
		col_bot: Callable, samples: int = 8) -> void:
	var total := 0.0
	for k: int in pts.size() - 1:
		total += pts[k].distance_to(pts[k + 1])
	for top: int in 2:
		var sgn := 1.0 if top == 1 else -1.0
		var fn := func(u: float, v: float) -> Vector3:
			var tn := (cr(pts, minf(v + 0.01, 1.0)) - cr(pts, maxf(v - 0.01, 0.0))).normalized()
			var side := tn.cross(nref).normalized()
			var nn := side.cross(tn).normalized()
			var o := (u - 0.5) * 2.0
			var w: float = width.call(v)
			return cr(pts, v) + side * (o * w * 0.5) + nn * sgn * (th * 0.5 * (1.0 - o * o) + 0.004)
		var ctr := func(_u: float, v: float) -> Vector3:
			var tn := (cr(pts, minf(v + 0.01, 1.0)) - cr(pts, maxf(v - 0.01, 0.0))).normalized()
			var side := tn.cross(nref).normalized()
			return cr(pts, v) - side.cross(tn).normalized() * sgn
		var uvf := func(u: float, v: float) -> Vector2:
			return Vector2(u, v * total)
		grid(s, fn, ctr, col_top if top == 1 else col_bot, uvf, 2, samples)


## A thin double-sided panel (wing, tail): mid(u, v) -> the middle surface, th(v) its thickness; top faces +Y.
static func panel(s: Surf, mid: Callable, th: Callable, col_top: Callable, col_bot: Callable, uvf: Callable,
		cols: int, rows: int) -> void:
	for top: int in 2:
		var sgn := 1.0 if top == 1 else -1.0
		var fn := func(u: float, v: float) -> Vector3:
			return (mid.call(u, v) as Vector3) + Vector3.UP * sgn * 0.5 * float(th.call(v))
		var ctr := func(u: float, v: float) -> Vector3:
			return (mid.call(u, v) as Vector3) - Vector3.UP * sgn
		grid(s, fn, ctr, col_top if top == 1 else col_bot, uvf, cols, rows)


static func bake(key: String, groups: Array) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	for g: Array in groups:
		var s: Surf = g[0]
		if s.v.is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = s.v
		arr[Mesh.ARRAY_NORMAL] = s.n
		arr[Mesh.ARRAY_TEX_UV] = s.uv
		arr[Mesh.ARRAY_COLOR] = s.c
		arr[Mesh.ARRAY_INDEX] = s.i
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		am.surface_set_material(am.get_surface_count() - 1, mat(String(g[1])))
	_meshes[key] = am
	return am


# ================================================================ meshes

## Body: deep keeled breast, broad back, rump over the tail base; pale belly; shoulder mantles over the wing roots.
static func body_mesh() -> ArrayMesh:
	if _meshes.has("body"):
		return _meshes["body"]
	var fe := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.12, 0.80), Vector3(0, 4.06, 0.50), Vector3(0, 3.99, 0.12),
		Vector3(0, 3.97, -0.30), Vector3(0, 4.00, -0.66), Vector3(0, 4.04, -1.00)]
	var tab := [[0.0, 0.26, 0.26, 0.26, 0.0], [0.18, 0.42, 0.36, 0.46, 0.0], [0.38, 0.46, 0.36, 0.50, 0.0],
		[0.62, 0.40, 0.32, 0.40, 0.0], [0.85, 0.26, 0.20, 0.20, 0.0], [1.0, 0.10, 0.08, 0.07, 0.0]]
	var prof := func(v: float) -> Vector4:
		return table(tab, v)
	var col := func(ca: float, v: float) -> Color:
		var pale := smoothstep(-0.2, -0.62, ca) * (1.0 - smoothstep(0.78, 0.96, v))
		return Color(1.0 - 0.5 * pale, pale, 0.0, 0.0)
	loft(fe, pts, prof, col, 22, 16, Vector3.RIGHT, 2.6)
	for sx: float in [-1.0, 1.0]:
		blob(fe, Vector3(0.30 * sx, 4.21, 0.28), Vector3(0.22, 0.16, 0.32), flat_col(Color(0.0, 0.0, 0.0, 0.0)),
			Basis(Vector3.FORWARD, 0.3 * sx), 0.05)
	# under-tail coverts (pale) hide the tail fan's root from below
	blob(fe, Vector3(0.0, 3.93, -0.84), Vector3(0.20, 0.09, 0.30), flat_col(Color(0.0, 0.85, 0.0, 0.0)))
	return bake("body", [[fe, FEATHER]])


## Lower neck with a ruff of shaggy hackles pointing back (a ragged silhouette behind the head).
static func neck1_mesh() -> ArrayMesh:
	if _meshes.has("neck1"):
		return _meshes["neck1"]
	var fe := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.06, 0.56), Vector3(0, 4.20, 0.76), Vector3(0, 4.34, 0.94)]
	var tab := [[0.0, 0.31, 0.30, 0.33, 0.0], [1.0, 0.24, 0.23, 0.25, 0.0]]
	var prof := func(v: float) -> Vector4:
		return table(tab, v)
	var col := func(ca: float, _v: float) -> Color:
		var pale := smoothstep(0.05, -0.4, ca)
		return Color(0.7 * (1.0 - pale), pale, 0.0, 0.0)
	loft(fe, pts, prof, col, 18, 8, Vector3.RIGHT, 1.7)
	var hk := func(v: float) -> Color:
		return Color(0.0, 0.0, 0.3 * v, 0.0)
	for k: int in 7:
		var a := lerpf(-105.0, 105.0, float(k) / 6.0) * DEG
		var c := cr(pts, 0.62)
		var r := 0.25
		var outw := Vector3(sin(a), cos(a) * 0.9, -0.15).normalized()
		var base := c + outw * r * 0.8
		var ln := 0.30 - 0.05 * absf(sin(a))
		var tip := base + (Vector3(0.0, 0.05, -1.0) * 0.85 + outw * 0.45).normalized() * ln
		horn(fe, [base, base.lerp(tip, 0.5) + outw * 0.03, tip], 0.07, 0.012, hk, 5, 3, Vector3.UP)
	return bake("neck1", [[fe, FEATHER]])


static func neck2_mesh() -> ArrayMesh:
	if _meshes.has("neck2"):
		return _meshes["neck2"]
	var fe := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.28, 0.86), Vector3(0, 4.42, 1.00), Vector3(0, 4.52, 1.12)]
	var tab := [[0.0, 0.25, 0.24, 0.26, 0.0], [1.0, 0.21, 0.20, 0.21, 0.0]]
	var prof := func(v: float) -> Vector4:
		return table(tab, v)
	var col := func(ca: float, _v: float) -> Color:
		var pale := smoothstep(0.1, -0.35, ca)
		return Color(0.5 * (1.0 - pale), pale, 0.0, 0.0)
	loft(fe, pts, prof, col, 16, 6, Vector3.RIGHT, 1.4)
	return bake("neck2", [[fe, FEATHER]])


## Head: skull with a pale face / throat, angry brow ridges, glowing eyes, the yellow cere and the big hooked beak,
## a crest of five pale plumes sweeping back from the crown and two ear tufts.
static func head_mesh() -> ArrayMesh:
	if _meshes.has("head"):
		return _meshes["head"]
	var fe := Surf.new()
	var hn := Surf.new()
	var gl := Surf.new()
	var skull_col := func(d: Vector3) -> Color:
		var pale := smoothstep(0.1, -0.35, d.y)
		return Color(0.0, pale, 0.0, 0.0)
	blob(fe, Vector3(0.0, 4.60, 1.15), Vector3(0.20, 0.19, 0.26), skull_col, Basis(Vector3.RIGHT, -0.12), 0.02, 14, 9)
	for sx: float in [-1.0, 1.0]:
		blob(fe, Vector3(0.10 * sx, 4.53, 1.20), Vector3(0.12, 0.12, 0.16), flat_col(Color(0.0, 0.9, 0.0, 0.0)))
		# brow ridge: slanted down toward the beak (the raptor scowl), darker
		blob(fe, Vector3(0.115 * sx, 4.69, 1.27), Vector3(0.075, 0.045, 0.15), flat_col(Color(0.0, 0.0, 0.55, 0.0)),
			Basis(Vector3.UP, 0.25 * sx) * Basis(Vector3.FORWARD, 0.35 * sx), 0.02, 8, 5)
		blob(gl, Vector3(0.162 * sx, 4.618, 1.25), Vector3(0.066, 0.058, 0.07), flat_col(Color.WHITE),
			Basis(Vector3.UP, 0.4 * sx), 0.0, 8, 5)
	# cere + hooked upper beak (gold, pale tip)
	blob(hn, Vector3(0.0, 4.605, 1.345), Vector3(0.105, 0.085, 0.09), flat_col(Color(0.0, 0.0, 0.0, 0.0)),
		Basis.IDENTITY, 0.02, 10, 6)
	var bpts: Array[Vector3] = [Vector3(0, 4.605, 1.36), Vector3(0, 4.60, 1.49), Vector3(0, 4.555, 1.60),
		Vector3(0, 4.47, 1.67), BEAK_TIP]
	var btab := [[0.0, 0.095, 0.085, 0.06, 0.0], [0.35, 0.075, 0.07, 0.045, 0.0], [0.65, 0.05, 0.05, 0.03, 0.0],
		[0.88, 0.028, 0.03, 0.02, 0.0], [1.0, 0.006, 0.006, 0.006, 0.0]]
	var bprof := func(v: float) -> Vector4:
		return table(btab, v)
	var bcol := func(_ca: float, v: float) -> Color:
		return Color(0.0, smoothstep(0.55, 1.0, v) * 0.85, 0.0, 0.0)
	loft(hn, bpts, bprof, bcol, 10, 10)
	# the crest: five pale plumes (the middle one longest) + two ear tufts
	var pc_top := func(_u: float, v: float) -> Color:
		return Color(0.0, 1.0, 0.3 * smoothstep(0.75, 1.0, v), 1.0)
	var pc_bot := func(_u: float, v: float) -> Color:
		return Color(0.0, 0.85, 0.3 * smoothstep(0.75, 1.0, v), 0.0)
	for k: int in [-2, -1, 0, 1, 2]:
		var kk := float(k)
		var f := 1.15 if k == 0 else (1.0 if absi(k) == 1 else 0.82)
		var b := Vector3(0.055 * kk, 4.76 - 0.015 * absf(kk), 1.16 - 0.03 * absf(kk))
		var pts: Array[Vector3] = [b, b + Vector3(0.05 * kk, 0.15, -0.14) * f, b + Vector3(0.10 * kk, 0.27, -0.40) * f,
			b + Vector3(0.13 * kk, 0.29, -0.66) * f]
		var wd := func(v: float) -> float:
			return 0.13 * (0.55 + 0.45 * smoothstep(0.0, 0.3, v)) * (1.0 - 0.8 * smoothstep(0.65, 1.0, v))
		blade(fe, pts, wd, Vector3(0.35 * kk, 1.0, 0.0).normalized(), 0.035, pc_top, pc_bot, 9)
	for sx: float in [-1.0, 1.0]:
		var e := Vector3(0.14 * sx, 4.66, 1.08)
		var pts: Array[Vector3] = [e, Vector3(0.19 * sx, 4.70, 0.95), Vector3(0.24 * sx, 4.73, 0.80),
			Vector3(0.265 * sx, 4.72, 0.68)]
		var wd := func(v: float) -> float:
			return 0.095 * (1.0 - 0.75 * smoothstep(0.55, 1.0, v))
		blade(fe, pts, wd, Vector3(0.5 * sx, 1.0, 0.0).normalized(), 0.03, pc_top, pc_bot, 6)
	return bake("head", [[fe, FEATHER], [hn, HORN], [gl, EYE]])


## Lower beak (the Jaw pivot opens it for the shriek).
static func jaw_mesh() -> ArrayMesh:
	if _meshes.has("jaw"):
		return _meshes["jaw"]
	var hn := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.525, 1.36), Vector3(0, 4.505, 1.47), Vector3(0, 4.475, 1.57)]
	var tab := [[0.0, 0.08, 0.025, 0.05, 0.0], [0.7, 0.05, 0.02, 0.035, 0.0], [1.0, 0.012, 0.01, 0.01, 0.0]]
	var prof := func(v: float) -> Vector4:
		return table(tab, v)
	var col := func(_ca: float, v: float) -> Color:
		return Color(0.0, 0.3 * smoothstep(0.5, 1.0, v), 0.0, 0.0)
	loft(hn, pts, prof, col, 10, 6)
	return bake("jaw", [[hn, HORN]])


## Arm part of a wing (WingX pivot at the shoulder, hinged on the shoulder -> trailing root line): the feathered
## leading edge (humerus + forearm) and the inner wing of coverts + secondaries with a scalloped trailing edge. Top =
## back colour with feather rows and a dark trailing band; underside pale (A) with the dark band.
static func wing_arm_mesh(sx: float) -> ArrayMesh:
	var key := "wing_arm%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var fe := Surf.new()
	var s := mx(SHOULDER, sx)
	var e := mx(ELBOW, sx)
	var w := mx(WRIST, sx)
	var rt := mx(ROOT_TRAIL, sx)
	var wt := mx(WRIST_TRAIL, sx)
	var lead: Array[Vector3] = [s + Vector3(-0.06 * sx, -0.02, 0.02), e + Vector3(0, 0.03, 0.02), w]
	loft(fe, lead, round_prof(0.10, 0.066), flat_col2(Color(0.8, 0.0, 0.0, 0.0)), 8, 10, Vector3.FORWARD, 0.5)
	var arm: Array[Vector3] = [s, e, w]
	var mid := func(u: float, v: float) -> Vector3:
		var l := cr(arm, u)
		var t := rt.lerp(wt, u) + Vector3(0.0, 0.0, -0.075 * scallop(u, 8.0))
		return l.lerp(t, v) + Vector3(0.0, 0.05 * sin(PI * v) * (0.5 + 0.5 * sin(PI * u)), 0.0)
	var th := func(v: float) -> float:
		return 0.11 * pow(1.0 - v, 2.0) + 0.012
	var ct := func(_u: float, v: float) -> Color:
		return Color(1.0, 0.0, 0.5 * smoothstep(0.78, 1.0, v), 0.0)
	var cb := func(_u: float, v: float) -> Color:
		return Color(0.8, 0.78 * (1.0 - 0.4 * smoothstep(0.8, 1.0, v)), 0.6 * smoothstep(0.82, 1.0, v), 0.0)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * 1.45, v * 0.9)
	panel(fe, mid, th, ct, cb, uvf, 24, 7)
	return bake(key, [[fe, FEATHER]])


## Hand part of a wing (WingX2 pivot at the wrist, hinged on the wrist -> trailing corner line): the hand edge, a fan
## of primary coverts and seven primaries; the outer five are separated "fingers" curling up with dark tips.
static func wing_hand_mesh(sx: float) -> ArrayMesh:
	var key := "wing_hand%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var fe := Surf.new()
	var w := mx(WRIST, sx)
	var h := mx(HAND, sx)
	var wt := mx(WRIST_TRAIL, sx)
	var dir := func(ang_deg: float) -> Vector3:
		var a := ang_deg * DEG
		return Vector3(cos(a) * sx, 0.0, -sin(a))
	var edge: Array[Vector3] = [w, w.lerp(h, 0.5) + Vector3(0, 0.02, 0.01), h + Vector3(0.10 * sx, 0.0, -0.04)]
	loft(fe, edge, round_prof(0.066, 0.04), flat_col2(Color(0.8, 0.0, 0.0, 0.0)), 8, 6, Vector3.FORWARD, 0.4)
	# primary coverts: a fan from the hand bone; its inner edge meets the arm panel's trailing corner
	var corr: Vector3 = wt - (w + (dir.call(88.0) as Vector3) * 0.96)
	var cmid := func(u: float, v: float) -> Vector3:
		var b := w.lerp(h, u)
		var ln := lerpf(0.96, 0.40, u) - 0.05 * (1.0 - scallop(u, 6.0))
		var tip: Vector3 = b + (dir.call(lerpf(88.0, -6.0, u)) as Vector3) * ln + corr * pow(1.0 - u, 2.0)
		return b.lerp(tip, v) + Vector3(0.0, 0.04 * sin(PI * v), 0.0)
	var cth := func(v: float) -> float:
		return 0.08 * pow(1.0 - v, 2.0) + 0.012
	var ct := func(_u: float, v: float) -> Color:
		return Color(1.0, 0.0, 0.12 * v, 0.0)
	var cb := func(_u: float, v: float) -> Color:
		return Color(0.8, 0.75, 0.15 * v, 0.0)
	var cuv := func(u: float, v: float) -> Vector2:
		return Vector2(u * 0.7, v * 0.7)
	panel(fe, cmid, cth, ct, cb, cuv, 12, 5)
	# primaries (inner ones sit higher so overlapping blades never z-fight)
	var pt := func(_u: float, v: float) -> Color:
		return Color(0.0, 0.0, smoothstep(0.35, 0.95, v) * 0.95, 1.0)
	var pb := func(_u: float, v: float) -> Color:
		return Color(0.0, 0.7 * (1.0 - smoothstep(0.5, 0.9, v)), smoothstep(0.5, 0.95, v), 1.0)
	for k: int in 7:
		var b := h.lerp(w, float(k) / 7.0) + Vector3(0.0, -0.01 + 0.012 * float(k), -0.02)
		var d: Vector3 = dir.call(PRIM_ANG[k])
		var back: Vector3 = dir.call(PRIM_ANG[k] + 90.0)
		var ln: float = PRIM_LEN[k]
		var finger := k < 5
		var curl := (0.17 if finger else 0.05) * ln
		var pts: Array[Vector3] = [b - d * 0.05, b + d * ln * 0.5 + Vector3(0, 0.02, 0),
			b + d * ln * 0.85 + back * 0.03 * ln + Vector3(0, curl * 0.45, 0), b + d * ln + back * 0.07 * ln + Vector3(0, curl, 0)]
		var wd := func(v: float) -> float:
			var ww := lerpf(0.2, 0.29, smoothstep(0.0, 0.35, v))
			if finger:
				ww *= lerpf(1.0, 0.45, smoothstep(0.45, 0.8, v))
			return ww * (1.0 - 0.72 * smoothstep(0.84, 1.0, v))
		blade(fe, pts, wd, Vector3.UP, 0.035, pt, pb, 8)
	return bake(key, [[fe, FEATHER]])


## Tail: a fan of nine broad feathers (scalloped tip), two pale bands and a dark tip (A); pale underside.
static func tail_mesh() -> ArrayMesh:
	if _meshes.has("tail"):
		return _meshes["tail"]
	var fe := Surf.new()
	var mid := func(u: float, v: float) -> Vector3:
		var a := lerpf(-24.0, 24.0, u) * DEG
		var d := Vector3(sin(a), 0.0, -cos(a))
		var ln := TAIL_LEN * (1.0 - 0.06 * (1.0 - scallop(u, 9.0)))
		return TAIL_BASE + d * ln * v + Vector3(0.0, -0.06 * v + 0.025 * sin(PI * v), 0.0)
	var th := func(v: float) -> float:
		return 0.08 * pow(1.0 - v, 2.0) + 0.012
	var ct := func(_u: float, v: float) -> Color:
		var band := maxf(bump(v, 0.46, 0.055), bump(v, 0.70, 0.045))
		return Color(1.0, band * 0.95, smoothstep(0.86, 0.97, v) * 0.9, 0.0)
	var cb := func(_u: float, v: float) -> Color:
		var band := maxf(bump(v, 0.46, 0.055), bump(v, 0.70, 0.045))
		return Color(0.6, 0.55 + 0.45 * band, smoothstep(0.86, 0.97, v) * 0.8, 0.0)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * 0.85, v * TAIL_LEN)
	panel(fe, mid, th, ct, cb, uvf, 27, 8)
	return bake("tail", [[fe, FEATHER]])


## Leg (LegFX pivot at the hip): pale feathered "trousers" and booted upper tarsus, gold scaled tarsus, a clenched
## foot of three front toes + the hind toe, dark hooked talons. Authored tucked back under the tail (glide pose).
static func leg_mesh(sx: float) -> ArrayMesh:
	var key := "leg%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var fe := Surf.new()
	var hn := Surf.new()
	blob(fe, Vector3(0.20 * sx, 3.67, -0.08), Vector3(0.15, 0.21, 0.17), flat_col(Color(0.0, 0.85, 0.0, 0.0)),
		Basis(Vector3.RIGHT, 0.5), 0.06)
	var k := Vector3(0.20 * sx, 3.53, -0.19)
	var a0 := Vector3(0.20 * sx, 3.45, -0.36)
	var an := Vector3(0.20 * sx, 3.39, -0.50)
	loft(fe, [k, k.lerp(a0, 0.5) + Vector3(0, 0.0, 0.01), a0], round_prof(0.09, 0.066),
		flat_col2(Color(0.0, 0.85, 0.0, 0.0)), 8, 4)
	loft(hn, [a0 + Vector3(0, 0.02, 0.03), a0.lerp(an, 0.5), an], round_prof(0.058, 0.05), flat_col2(Color(0, 0, 0, 0)), 7, 3)
	var toe := func(_v: float) -> Color:
		return Color(0.0, 0.0, 0.0, 0.0)
	var talon := func(v: float) -> Color:
		return Color(0.0, 0.0, smoothstep(0.0, 0.35, v), 0.0)
	for t: int in 3:
		var sp := (float(t) - 1.0) * 0.4
		var e1 := an + Vector3(sin(sp) * 0.07 * sx, -0.05, -0.09)
		var e2 := an + Vector3(sin(sp) * 0.10 * sx, -0.12, -0.12)
		horn(hn, [an, e1, e2], 0.048, 0.034, toe, 6, 3)
		horn(hn, [e2, e2 + Vector3(0, -0.05, 0.035), e2 + Vector3(0, -0.06, 0.09)], 0.036, 0.004, talon, 5, 4)
	var h1 := an + Vector3(0.0, -0.03, 0.08)
	var h2 := an + Vector3(0.0, -0.08, 0.12)
	horn(hn, [an, h1, h2], 0.046, 0.034, toe, 6, 3)
	horn(hn, [h2, h2 + Vector3(0, -0.05, -0.03), h2 + Vector3(0, -0.06, -0.09)], 0.036, 0.004, talon, 5, 4)
	return bake(key, [[fe, FEATHER], [hn, HORN]])
