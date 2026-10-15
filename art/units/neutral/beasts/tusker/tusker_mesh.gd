extends RefCounted
## Tusker meshes (task 12.V27): every part of the Ironhide Tusker / Old Scarback, built once per game from lofts,
## tubes and primitives in MODEL space (feet origin, face +Z, rest pose, variant A size; variant B = the same scene
## scaled x1.15 by tusker.gd). Each function returns one multi-surface ArrayMesh (one surface per material), cached.
## Materials: materials/tusker_*.tres (the painted unit shader + one eye glow). The B look swaps some of them through
## surface overrides (SWAP_B, applied by tusker.gd), so the merged pivot meshes stay shared by both variants.

const DIR := "res://art/units/neutral/beasts/tusker/materials/"
## Variant B material swaps (A material -> B material), applied as surface overrides by tusker.gd.
const SWAP_B := {"tusker_plate": "tusker_plate_b", "tusker_bristle": "tusker_bristle_b", "tusker_tip": "tusker_tip_b"}
## The bristle ridge scales about this spine point (model space, above the shoulder hump).
const BRISTLE_ORIGIN := Vector3(0.0, 1.72, 0.2)
const RING := 18              # segments around the body / head lofts

# Body loft stations along the spine (rump -> chest): centre, half-width, half-height. A massive shoulder hump (top
# ~1.83 m at z 0.28), the rump top ~1.54, the belly ~0.67 over short thick legs.
const BODY_C: Array[Vector3] = [Vector3(0, 1.10, -1.44), Vector3(0, 1.10, -1.38), Vector3(0, 1.10, -1.25),
	Vector3(0, 1.11, -1.02), Vector3(0, 1.13, -0.70), Vector3(0, 1.16, -0.36), Vector3(0, 1.21, -0.02),
	Vector3(0, 1.25, 0.28), Vector3(0, 1.245, 0.52), Vector3(0, 1.19, 0.74), Vector3(0, 1.12, 0.92),
	Vector3(0, 1.08, 1.03)]
const BODY_RX: Array[float] = [0.03, 0.30, 0.45, 0.53, 0.57, 0.60, 0.63, 0.645, 0.625, 0.56, 0.46, 0.37]
const BODY_RY: Array[float] = [0.03, 0.30, 0.40, 0.44, 0.46, 0.49, 0.54, 0.58, 0.57, 0.52, 0.46, 0.39]
# Head loft (neck -> snout), carried low: the big skull and cheeks, then a long tapering snout.
const HEAD_C: Array[Vector3] = [Vector3(0, 1.23, 0.86), Vector3(0, 1.21, 1.10), Vector3(0, 1.11, 1.34),
	Vector3(0, 0.97, 1.58), Vector3(0, 0.855, 1.80), Vector3(0, 0.78, 1.97)]
const HEAD_RX: Array[float] = [0.37, 0.40, 0.355, 0.27, 0.205, 0.175]
const HEAD_RY: Array[float] = [0.41, 0.42, 0.36, 0.275, 0.205, 0.17]
# Armour bands over the back: [z0, z1, half angle (rad), inflation]. Gaps of dark hide between them.
const PLATES: Array = [[0.66, 0.98, 1.22, 1.075], [0.03, 0.62, 1.42, 1.085], [-0.37, -0.02, 1.30, 1.072],
	[-0.73, -0.42, 1.24, 1.066], [-1.07, -0.78, 1.14, 1.06], [-1.33, -1.12, 1.0, 1.055]]
# The tusk path (right side, x > 0; mirrored for the left): out of the jaw corner, curling out, up and back.
const TUSK_P: Array[Vector3] = [Vector3(0.20, 0.80, 1.70), Vector3(0.36, 0.86, 1.83), Vector3(0.50, 1.02, 1.88),
	Vector3(0.585, 1.22, 1.80), Vector3(0.57, 1.40, 1.64), Vector3(0.49, 1.50, 1.47)]
const TUSK_R: Array[float] = [0.105, 0.098, 0.088, 0.072, 0.046, 0.0]

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}


static func mat(name: String) -> Material:
	if not _mats.has(name):
		_mats[name] = load(DIR + name + ".tres")
	return _mats[name]


# ================================================================ helpers

static func _bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## Appends primitive `m` (surface 0) transformed by xf.
static func _put(acc: Array, m: Mesh, xf: Transform3D) -> void:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb := xf.basis.inverse().transposed()
	var b0: int = (acc[0] as PackedVector3Array).size()
	for j: int in v.size():
		acc[0].append(xf * v[j])
		acc[1].append((nb * nr[j]).normalized())
		acc[2].append(Vector2.ZERO)
	if ix.is_empty():
		for j: int in v.size():
			acc[3].append(b0 + j)
	else:
		for j: int in ix.size():
			acc[3].append(b0 + ix[j])


static func _ellipsoid(acc: Array, c: Vector3, r: Vector3, radial: int = 10, rings: int = 5,
		rot: Basis = Basis.IDENTITY) -> void:
	_put(acc, CharacterModel.sphere(1.0, radial, rings), Transform3D(rot * Basis.from_scale(r), c))


## A (cols+1) x (rows+1) grid of points (row-major) with given normals; each triangle wound so its front (Godot:
## clockwise) faces its normals.
static func _grid(acc: Array, pts: PackedVector3Array, nrm: PackedVector3Array, cols: int, rows: int) -> void:
	var w := cols + 1
	var b0: int = (acc[0] as PackedVector3Array).size()
	for k: int in pts.size():
		acc[0].append(pts[k])
		acc[1].append(nrm[k])
		acc[2].append(Vector2.ZERO)
	for j: int in rows:
		for i: int in cols:
			var q0 := j * w + i
			for tri: Array in [[q0, q0 + 1, q0 + w], [q0 + 1, q0 + w + 1, q0 + w]]:
				var a: int = tri[0]
				var b: int = tri[1]
				var c: int = tri[2]
				var front := -(pts[b] - pts[a]).cross(pts[c] - pts[a])
				if front.dot(nrm[a] + nrm[b] + nrm[c]) < 0.0:
					var t := b
					b = c
					c = t
				acc[3].append(b0 + a)
				acc[3].append(b0 + b)
				acc[3].append(b0 + c)


## Grid with normals from the grid itself (central differences), oriented away from `inside[row]`.
static func _grid_auto(acc: Array, pts: PackedVector3Array, cols: int, rows: int, inside: PackedVector3Array) -> void:
	var w := cols + 1
	var nrm := PackedVector3Array()
	for j: int in rows + 1:
		for i: int in w:
			var k := j * w + i
			var du := pts[j * w + mini(i + 1, cols)] - pts[j * w + maxi(i - 1, 0)]
			var dv := pts[mini(j + 1, rows) * w + i] - pts[maxi(j - 1, 0) * w + i]
			var nn := du.cross(dv)
			var out := pts[k] - inside[j]
			if nn.length_squared() < 1e-12:
				nn = out
			nn = nn.normalized()
			if nn.dot(out) < 0.0:
				nn = -nn
			nrm.append(nn)
	_grid(acc, pts, nrm, cols, rows)


## Station tangent (central difference), for a smooth loft frame.
static func _tan(c: Array[Vector3], i: int) -> Vector3:
	var n := c.size()
	return (c[mini(i + 1, n - 1)] - c[maxi(i - 1, 0)]).normalized()


## Point of a loft at any z (piecewise linear between stations), angle a (0 = top, PI/2 = +x side, PI = belly).
static func _sp(c: Array[Vector3], rx: Array[float], ry: Array[float], z: float, a: float, inf: float = 1.0) -> Vector3:
	var n := c.size()
	var i := 0
	while i < n - 2 and z > c[i + 1].z:
		i += 1
	var u := clampf((z - c[i].z) / maxf(c[i + 1].z - c[i].z, 0.0001), 0.0, 1.0)
	var cc := c[i].lerp(c[i + 1], u)
	var t := _tan(c, i).lerp(_tan(c, i + 1), u).normalized()
	var up := t.cross(Vector3.RIGHT).normalized()
	return cc + Vector3.RIGHT * sin(a) * lerpf(rx[i], rx[i + 1], u) * inf + up * cos(a) * lerpf(ry[i], ry[i + 1], u) * inf


## Centre of a loft at z (for normal orientation).
static func _centre(c: Array[Vector3], z: float) -> Vector3:
	var n := c.size()
	var i := 0
	while i < n - 2 and z > c[i + 1].z:
		i += 1
	var u := clampf((z - c[i].z) / maxf(c[i + 1].z - c[i].z, 0.0001), 0.0, 1.0)
	return c[i].lerp(c[i + 1], u)


## A loft patch: rows at zs, columns at angs, inflation per vertex (a function of row / column edge flags).
static func _patch(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], zs: PackedFloat32Array,
		angs: PackedFloat32Array, infl: PackedFloat32Array) -> void:
	var pts := PackedVector3Array()
	var inside := PackedVector3Array()
	var cols := angs.size() - 1
	for j: int in zs.size():
		inside.append(_centre(c, zs[j]))
		for i: int in angs.size():
			pts.append(_sp(c, rx, ry, zs[j], angs[i], infl[j * angs.size() + i]))
	_grid_auto(acc, pts, cols, zs.size() - 1, inside)


static func _even(a0: float, a1: float, steps: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k: int in steps + 1:
		out.append(lerpf(a0, a1, float(k) / float(steps)))
	return out


## A full loft (all stations, full ring) at inflation 1.
static func _loft(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float]) -> void:
	var zs := PackedFloat32Array()
	for p: Vector3 in c:
		zs.append(p.z)
	var angs := _even(0.0, TAU, RING)
	var infl := PackedFloat32Array()
	infl.resize(zs.size() * angs.size())
	infl.fill(1.0)
	_patch(acc, c, rx, ry, zs, angs, infl)


## A raised armour plate over a loft: z0..z1, +-h around the top (centred on angle `a0`), bevelled edges down to the
## skin (so it reads as a thick overlapping plate), the rear edge lifted a little more than the front.
static func _plate(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], z0: float, z1: float,
		h: float, p: float, a0: float = 0.0, cols: int = 12) -> void:
	var zs := PackedFloat32Array([z0, z0 + 0.045, lerpf(z0, z1, 0.5), z1 - 0.035, z1])
	var row_inf := PackedFloat32Array([1.004, p - 0.012, p, p + 0.01, 1.004])
	var angs := PackedFloat32Array([a0 - h])
	for k: int in cols - 1:
		angs.append(a0 + lerpf(-h + 0.08, h - 0.08, float(k) / float(cols - 2)))
	angs.append(a0 + h)
	var infl := PackedFloat32Array()
	for j: int in zs.size():
		for i: int in angs.size():
			infl.append(1.004 if (i == 0 or i == angs.size() - 1) else row_inf[j])
	_patch(acc, c, rx, ry, zs, angs, infl)


## Smooth tube through pts (radii per point, 0 = a point), `seg` sides; `ref` must not be parallel to the path.
static func _tube(acc: Array, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int, ref: Vector3,
		flat: float = 1.0) -> void:
	var grid := PackedVector3Array()
	var nrm := PackedVector3Array()
	var n := pts.size()
	for i: int in n:
		var t := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var s := t.cross(ref).normalized()
		var u := s.cross(t).normalized()
		for k: int in seg + 1:
			var a := TAU * float(k) / float(seg)
			var d := s * cos(a) + u * sin(a) * flat
			grid.append(pts[i] + d * radii[i])
			var dn := (s * cos(a) + u * sin(a) / maxf(flat, 0.05)).normalized()
			nrm.append(dn if radii[i] > 0.0 else t)
	_grid(acc, grid, nrm, seg, n - 1)


## A two-tone bristle: a 5-sided dark frustum (base -> 60 %) and a pale point (tip).
static func _spike(ad: Array, ab: Array, base: Vector3, tip: Vector3, r: float) -> void:
	var d := tip - base
	var ln := d.length()
	var t := d / ln
	var ref := Vector3.RIGHT if absf(t.dot(Vector3.RIGHT)) < 0.8 else Vector3.FORWARD
	var s := t.cross(ref).normalized()
	var u := s.cross(t).normalized()
	var slope := r / ln
	for part: int in 2:
		var p0: Vector3 = base if part == 0 else base + d * 0.56
		var p1: Vector3 = base + d * 0.62 if part == 0 else tip
		var r0: float = r if part == 0 else r * 0.47
		var r1: float = r * 0.42 if part == 0 else 0.0
		var pts := PackedVector3Array()
		var nrm := PackedVector3Array()
		for row: int in 2:
			for k: int in 6:
				var a := TAU * float(k) / 5.0
				var dir := s * cos(a) + u * sin(a)
				pts.append((p0 if row == 0 else p1) + dir * (r0 if row == 0 else r1))
				nrm.append((dir + t * slope).normalized())
		_grid(ad if part == 0 else ab, pts, nrm, 5, 1)


## One ArrayMesh from [acc, material name] pairs (empty accs skipped), cached by key.
static func _commit(key: String, surfaces: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for sf: Array in surfaces:
		var acc: Array = sf[0]
		if (acc[0] as PackedVector3Array).is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc[0]
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_TEX_UV] = acc[2]
		arrays[Mesh.ARRAY_INDEX] = acc[3]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, mat(String(sf[1])))
	_meshes[key] = am
	return am


## Height of the back (top of the body loft) at z.
static func back_top(z: float) -> float:
	return _sp(BODY_C, BODY_RX, BODY_RY, z, 0.0).y


## A point on the body skin at (z, angle), inflated (plates sit at ~1.06-1.085).
static func body_point(z: float, a: float, inf: float = 1.0) -> Vector3:
	return _sp(BODY_C, BODY_RX, BODY_RY, z, a, inf)


static func head_point(z: float, a: float, inf: float = 1.0) -> Vector3:
	return _sp(HEAD_C, HEAD_RX, HEAD_RY, z, a, inf)


# ================================================================ parts

## Body (Mount): the leathery dark hide barrel with the massive shoulder hump, six iron armour bands across the back
## (collar, shoulder saddle, three back bands, rump plate), round shoulder shields over the forelegs, the tail.
## G-D: a row of low horn knobs (osteoderms) along the rear lip of an armour band, so the plates read as grown horn
## scutes, not sheet metal: one knob every ~0.3 rad across the band, bigger along the spine.
static func _scutes(acc: Array, pl: Array) -> void:
	var z0: float = pl[0]
	var z1: float = pl[1]
	var h: float = pl[2]
	var inf: float = pl[3]
	var z: float = lerpf(z0, z1, 0.3)
	var n_k: int = maxi(3, int(h * 2.0 / 0.3))
	for k: int in n_k + 1:
		var a: float = lerpf(-h + 0.16, h - 0.16, float(k) / float(n_k))
		var p := _sp(BODY_C, BODY_RX, BODY_RY, z, a, inf + 0.004)
		var nn := (p - _centre(BODY_C, z)).normalized()
		var big: float = 1.0 - 0.45 * absf(a) / maxf(h, 0.01)
		var sz := Vector3(0.075, 0.034, 0.09) * (0.75 + 0.35 * big)
		_ellipsoid(acc, p, sz, 5, 2, Basis(Quaternion(Vector3.UP, nn)))


static func body_mesh() -> Mesh:
	const KEY := "body_v2"
	if _meshes.has(KEY):
		return _meshes[KEY]
	var hide := _bucket()
	var plate := _bucket()
	var dark := _bucket()
	var bristle := _bucket()
	_loft(hide, BODY_C, BODY_RX, BODY_RY)
	for pl: Array in PLATES:
		_plate(plate, BODY_C, BODY_RX, BODY_RY, float(pl[0]), float(pl[1]), float(pl[2]), float(pl[3]))
		_scutes(plate, pl)
	# Shoulder shields: big round iron plates on each flank over the foreleg tops (widen the top-down silhouette).
	for sx: float in [-1.0, 1.0]:
		var sb := Basis(Vector3.BACK, -0.32 * sx) * Basis(Vector3.UP, 0.12 * sx)
		_ellipsoid(plate, Vector3(0.62 * sx, 1.07, 0.47), Vector3(0.11, 0.33, 0.37), 12, 6, sb)
		# A second, smaller overlapping haunch plate on the hips.
		var hb := Basis(Vector3.BACK, -0.28 * sx)
		_ellipsoid(plate, Vector3(0.53 * sx, 1.12, -0.92), Vector3(0.09, 0.26, 0.30), 10, 5, hb)
	# Tail: a dark whip curling down from the rump, a bristle tuft at the end.
	_tube(dark, PackedVector3Array([Vector3(0, 1.36, -1.37), Vector3(0, 1.31, -1.50), Vector3(0.03, 1.15, -1.56),
		Vector3(0.06, 0.97, -1.53)]), PackedFloat32Array([0.055, 0.042, 0.032, 0.022]), 6, Vector3.RIGHT)
	_ellipsoid(bristle, Vector3(0.065, 0.94, -1.525), Vector3(0.06, 0.11, 0.06), 6, 3)
	return _commit(KEY, [[hide, "tusker_hide"], [plate, "tusker_plate"], [dark, "tusker_dark"],
		[bristle, "tusker_bristle"]])


## Head (Mount/Head): the wedge loft with an iron brow helmet and a nose plate, the flat dark snout disc, the lower
## jaw, glowing amber eyes under the helmet, laid-back ears, cheek and chin bristles, a crest, the LEFT tusk (the
## right one is the keep_separate TuskR: whole on A, broken on B).
static func head_mesh() -> Mesh:
	const KEY := "head_v1"
	if _meshes.has(KEY):
		return _meshes[KEY]
	var hide := _bucket()
	var plate := _bucket()
	var dark := _bucket()
	var bristle := _bucket()
	var tip := _bucket()
	var tusk := _bucket()
	var eye := _bucket()
	_loft(hide, HEAD_C, HEAD_RX, HEAD_RY)
	# The helmet: a thick plate from the poll to the brow, then a nose plate down the snout ridge.
	_plate(plate, HEAD_C, HEAD_RX, HEAD_RY, 0.94, 1.46, 1.08, 1.085)
	_plate(plate, HEAD_C, HEAD_RX, HEAD_RY, 1.50, 1.86, 0.78, 1.07, 0.0, 8)
	# Snout disc and the lower jaw.
	_put(dark, CharacterModel.cyl(0.185, 0.2, 0.1, 12), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis(Vector3.RIGHT, 0.12), Vector3(0, 0.775, 1.995)))
	_ellipsoid(hide, Vector3(0, 0.80, 1.50), Vector3(0.25, 0.15, 0.36), 10, 5)
	for sx: float in [-1.0, 1.0]:
		# Nostrils: two dark hollows on the disc (a darker ring reads as holes at this size).
		_ellipsoid(hide, Vector3(0.075 * sx, 0.79, 2.045), Vector3(0.04, 0.05, 0.02), 6, 3)
		# Eye: a dark socket under the helmet rim; the amber glowing eye on it is the tusker's CreatureFaceRig (faces
		# pass 2026-09-28: was a glow bead).
		var ep := head_point(1.33, 1.02 * sx, 1.0)
		_ellipsoid(dark, ep + Vector3(0.0, 0.0, -0.01), Vector3(0.085, 0.07, 0.085), 8, 4)
		# Ear: a flattened dark cone laid back and out.
		var ed := Vector3(0.58 * sx, 0.62, -0.53).normalized()
		var eb := Basis(Quaternion(Vector3.UP, ed)) * Basis.from_scale(Vector3(1.0, 1.0, 0.4))
		_put(dark, CharacterModel.cyl(0.0, 0.12, 0.36, 7), Transform3D(eb, Vector3(0.25 * sx, 1.52, 1.0) + ed * 0.15))
		# Cheek bristles (sideburns) raking back and down, chin beard.
		for k: int in 3:
			var b := head_point(1.12 + 0.12 * float(k), (1.75 + 0.12 * float(k)) * sx, 0.97)
			_spike(bristle, tip, b, b + Vector3(0.45 * sx, -0.42, -0.75).normalized() * (0.26 - 0.04 * float(k)), 0.05)
		var cb := Vector3(0.1 * sx, 0.68, 1.42)
		_spike(bristle, tip, cb, cb + Vector3(0.15 * sx, -0.8, -0.45).normalized() * 0.2, 0.045)
	# Crest: bristles continuing the back ridge over the poll.
	for k: int in 4:
		var z: float = 1.12 - 0.08 * float(k)
		var b := head_point(z, 0.0, 1.05)
		var side: float = 1.0 if k % 2 == 0 else -1.0
		_spike(bristle, tip, b + Vector3(0.03 * side, -0.03, 0), b + Vector3(0.18 * side, 0.62, -0.72).normalized()
			* (0.2 + 0.05 * float(k)), 0.055)
	_tusk(tusk, -1.0, false)
	return _commit(KEY, [[hide, "tusker_hide"], [plate, "tusker_plate"], [dark, "tusker_dark"],
		[bristle, "tusker_bristle"], [tip, "tusker_tip"], [tusk, "tusker_tusk"], [eye, "tusker_eye_glow"]])


## One tusk along TUSK_P mirrored by sx; broken = snapped off a little past the curve (a jagged stump).
static func _tusk(acc: Array, sx: float, broken: bool) -> void:
	var pts := PackedVector3Array()
	var rr := PackedFloat32Array()
	var n: int = TUSK_P.size()
	for i: int in n:
		pts.append(Vector3(TUSK_P[i].x * sx, TUSK_P[i].y, TUSK_P[i].z))
		rr.append(TUSK_R[i])
	# A socket ring of gum / hide where the tusk leaves the jaw is part of the jaw; the tusk itself:
	if not broken:
		_tube(acc, pts, rr, 9, Vector3.FORWARD)
		return
	# Broken: stops 40 % into the third segment, then a slanted break with three splinters.
	var end := pts[2].lerp(pts[3], 0.4)
	var bp := PackedVector3Array([pts[0], pts[1], pts[2], end])
	var br := PackedFloat32Array([TUSK_R[0], TUSK_R[1], TUSK_R[2], 0.082])
	_tube(acc, bp, br, 9, Vector3.FORWARD)
	var t := (end - pts[2]).normalized()
	var s := t.cross(Vector3.FORWARD).normalized()
	var u := s.cross(t).normalized()
	# Close the stump with a low, slanted cap and splinters of different heights.
	_put(acc, CharacterModel.cyl(0.03, 0.082, 0.05, 9), Transform3D(Basis(Quaternion(Vector3.UP, t)), end + t * 0.025))
	for k: int in 3:
		var a := TAU * float(k) / 3.0 + 0.4
		var o := (s * cos(a) + u * sin(a)) * 0.045
		var h: float = [0.13, 0.07, 0.10][k]
		_spike(acc, acc, end + o, end + o * 0.6 + t * h, 0.03)


## The right tusk (keep_separate "TuskR" under the head): whole on variant A; on B broken, plus B's face scar across
## the right eye (a pale welt from brow to cheek, the eye scarred shut).
static func tusk_r_mesh(broken: bool) -> Mesh:
	var key := "tusk_r_v1_%s" % broken
	if _meshes.has(key):
		return _meshes[key]
	var tusk := _bucket()
	var scar := _bucket()
	_tusk(tusk, 1.0, broken)
	if broken:
		var pts := PackedVector3Array()
		var rr := PackedFloat32Array()
		var path: Array[Vector2] = [Vector2(1.06, 0.62), Vector2(1.2, 0.84), Vector2(1.33, 1.0), Vector2(1.45, 1.2),
			Vector2(1.56, 1.42)]
		for k: int in path.size():
			pts.append(head_point(path[k].x, path[k].y, 1.09 if k > 0 and k < path.size() - 1 else 1.03))
			rr.append(0.0 if k == 0 or k == path.size() - 1 else 0.042)
		_tube(scar, pts, rr, 6, Vector3.FORWARD, 0.6)
		# The right eye scarred shut: a pale lid over the glow bead.
		var ep := head_point(1.33, 1.02, 1.0)
		_ellipsoid(scar, ep + Vector3(0.024, 0.0, 0.014), Vector3(0.068, 0.058, 0.068), 8, 4)
	return _commit(key, [[tusk, "tusker_tusk"], [scar, "tusker_scar"]])


## One leg (model space): a thick hide shoulder / ham, an iron greave on the front of the foreleg, a stout hide shin
## with a knobbly joint, a split dark hoof.
static func leg_mesh(front: bool, sx: float) -> Mesh:
	var key := "leg_v2_%s_%s" % [front, sx]
	if _meshes.has(key):
		return _meshes[key]
	var hide := _bucket()
	var plate := _bucket()
	var dark := _bucket()
	var x: float = (0.40 if front else 0.38) * sx
	var hz: float
	if front:
		_ellipsoid(hide, Vector3(x, 0.80, 0.56), Vector3(0.23, 0.35, 0.27), 10, 5)
		_tube(hide, PackedVector3Array([Vector3(x, 0.60, 0.56), Vector3(x, 0.32, 0.585), Vector3(x, 0.1, 0.615)]),
			PackedFloat32Array([0.19, 0.155, 0.16]), 9, Vector3.FORWARD)
		_ellipsoid(hide, Vector3(x, 0.32, 0.585), Vector3(0.175, 0.11, 0.175), 8, 4)
		_ellipsoid(plate, Vector3(x + 0.02 * sx, 0.60, 0.70), Vector3(0.16, 0.24, 0.085), 10, 5,
			Basis(Vector3.RIGHT, -0.22))
		hz = 0.64
	else:
		_ellipsoid(hide, Vector3(x, 0.90, -0.94), Vector3(0.27, 0.43, 0.36), 10, 5)
		_tube(hide, PackedVector3Array([Vector3(x, 0.62, -0.98), Vector3(x, 0.35, -1.09), Vector3(x, 0.1, -1.03)]),
			PackedFloat32Array([0.19, 0.15, 0.155]), 9, Vector3.FORWARD)
		_ellipsoid(hide, Vector3(x, 0.36, -1.09), Vector3(0.17, 0.11, 0.17), 8, 4)
		hz = -1.0
	for t: float in [-1.0, 1.0]:
		_ellipsoid(dark, Vector3(x + 0.068 * t, 0.086, hz), Vector3(0.08, 0.075, 0.125), 7, 3)
	# G-D: heavy skin folds sagging round the ankle and over the knee (an old pachyderm's legs, not pipes).
	var lz: float = 0.6 if front else -1.06
	for f: Array in [[0.2, 0.172, 0.03], [0.255, 0.165, 0.026], [0.47 if front else 0.52, 0.178, 0.028]]:
		_ellipsoid(hide, Vector3(x, float(f[0]), lz + (0.0 if f[0] < 0.4 else (0.0 if front else 0.04))),
			Vector3(float(f[1]), float(f[2]), float(f[1])), 8, 2, Basis(Vector3.RIGHT, 0.12 if front else -0.12))
	return _commit(key, [[hide, "tusker_hide"], [plate, "tusker_plate"], [dark, "tusker_dark"]])


## The bristle ridge (keep_separate "Bristles", local to BRISTLE_ORIGIN): a double row of thick bristles bursting up
## through the plate seams along the spine, tallest over the shoulder hump, plus hackles splayed out at the withers.
static func bristle_mesh() -> Mesh:
	const KEY := "bristles_v1"
	if _meshes.has(KEY):
		return _meshes[KEY]
	var dark := _bucket()
	var tip := _bucket()
	var count: int = 19
	for k: int in count:
		var z: float = lerpf(0.98, -0.98, float(k) / float(count - 1))
		var bell: float = exp(-pow((z - 0.28) / 0.6, 2.0))
		var side: float = 1.0 if k % 2 == 0 else -1.0
		var ln: float = 0.16 + 0.42 * bell
		var base := Vector3(0.05 * side, back_top(z) - 0.03, z) - BRISTLE_ORIGIN
		var dir := Vector3(0.30 * side, 0.72, -0.62).normalized()
		_spike(dark, tip, base, base + dir * ln, 0.05 + 0.04 * bell)
	for j: int in 5:
		var z: float = 0.66 - 0.15 * float(j)
		for side: float in [-1.0, 1.0]:
			var base := body_point(z, 0.42 * side, 1.02) - BRISTLE_ORIGIN
			var dir := Vector3(0.74 * side, 0.5, -0.45).normalized()
			_spike(dark, tip, base, base + dir * (0.34 - 0.035 * float(j)), 0.05)
	return _commit(KEY, [[dark, "tusker_bristle"], [tip, "tusker_tip"]])


## Variant B battle damage (keep_separate "ScarB" under the Mount, hidden on A): three pale claw-rake welts across the
## left flank plates, a long scar over the right haunch, the WAR-ARROW still stuck behind the left shoulder (thick shaft,
## pale fletching with dark bands) and a snapped arrow stub in the right hip.
static func scar_b_mesh() -> Mesh:
	const KEY := "scar_b_v1"
	if _meshes.has(KEY):
		return _meshes[KEY]
	var scar := _bucket()
	var wood := _bucket()
	var fletch := _bucket()
	var dark := _bucket()
	for k: int in 3:
		var pts := PackedVector3Array()
		var rr := PackedFloat32Array()
		var steps: int = 7
		for s: int in steps + 1:
			var u: float = float(s) / float(steps)
			var z: float = lerpf(0.34, -0.36, u) + 0.09 * float(k) - 0.09
			var a: float = -lerpf(0.72, 1.46, u) - 0.25 * float(k) + 0.25
			pts.append(body_point(z, a, 1.105))
			rr.append(0.0 if s == 0 or s == steps else 0.034 * sin(PI * u) + 0.01)
		_tube(scar, pts, rr, 6, Vector3.RIGHT, 0.55)
	var hp := PackedVector3Array()
	var hr := PackedFloat32Array()
	for s: int in 7:
		var u: float = float(s) / 6.0
		hp.append(body_point(lerpf(-0.62, -1.16, u), lerpf(1.25, 0.55, u), 1.09))
		hr.append(0.0 if s == 0 or s == 6 else 0.04 * sin(PI * u) + 0.01)
	_tube(scar, hp, hr, 6, Vector3.RIGHT, 0.55)
	# The war-arrow: in behind the left shoulder, raking up, out and back (reads as a pale-tipped line from above).
	var p0 := body_point(0.08, -0.62, 1.0)
	var dir := Vector3(-0.38, 0.8, -0.46).normalized()
	var a0 := p0 - dir * 0.12
	var a1 := p0 + dir * 1.02
	_tube(wood, PackedVector3Array([a0, p0 + dir * 0.5, a1]), PackedFloat32Array([0.042, 0.04, 0.036]), 6,
		Vector3.RIGHT)
	var fs := dir.cross(Vector3.UP).normalized()
	var fu := fs.cross(dir).normalized()
	for k: int in 3:
		var ang := TAU * float(k) / 3.0 + 0.3
		var radial := fs * cos(ang) + fu * sin(ang)
		var c := p0 + dir * 0.84 + radial * 0.075
		var vb := Basis(radial.cross(dir).normalized(), radial, dir)   # x across, y radial, z along the shaft
		_ellipsoid(fletch, c, Vector3(0.014, 0.075, 0.2), 6, 3, vb)
	# Dark bands at the fletching and the nock.
	_tube(dark, PackedVector3Array([p0 + dir * 0.68, p0 + dir * 0.72]), PackedFloat32Array([0.058, 0.058]), 6,
		Vector3.RIGHT)
	_ellipsoid(dark, a1, Vector3(0.05, 0.05, 0.05), 6, 3)
	# A snapped arrow stub in the right hip with a splintered end.
	var q0 := body_point(-0.98, 0.72, 1.0)
	var qd := Vector3(0.55, 0.7, -0.45).normalized()
	_tube(wood, PackedVector3Array([q0 - qd * 0.08, q0 + qd * 0.3]), PackedFloat32Array([0.04, 0.036]), 6, Vector3.RIGHT)
	_spike(wood, wood, q0 + qd * 0.28, q0 + qd * 0.42 + fs * 0.02, 0.03)
	return _commit(KEY, [[scar, "tusker_scar"], [wood, "tusker_wood"], [fletch, "tusker_fletch"], [dark, "tusker_dark"]])
