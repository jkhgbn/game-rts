extends RefCounted
## Grizzlemaw meshes (task 12.V30): static builders used by grizzlemaw.gd only. Every mesh is built once per game per
## variant and cached. Each mesh is LOCAL to the pivot it hangs on (the model origin of that pivot is subtracted), so
## the kit's merged mesh of a pivot and the variant meshes swapped in by set_variant() line up exactly. Face = +Z, feet
## at y 0. Deterministic (fixed seeds).
## Variants: v 0 = Grizzlemaw (warm brown, tan muzzle, a green MOSS SADDLE over the shoulder hump); v 1 = Elder
## Grizzlemaw (grey-brown, silver STREAKS along the back and flanks, a WHITE muzzle and brows, claw scars, a torn ear, a
## RUSTED CHAIN collar with a dangling broken end and old BONES tied on it; less moss). The Elder is also scaled x1.15 by
## the model (node scale), not here.
## Materials (materials/, painted = kit unit_painted, glow = kit unit_glow): fur, fur_dark (legs, paws, brows, tail),
## muzzle, claw (claws, teeth, bones), nose (nose, lips, ear insides), mouth (palate, tongue), moss, eye_glow (amber) /
## eye_rage (red, enraged), elder_fur, elder_streak, elder_muzzle, rust.

const DIR := "res://art/units/neutral/beasts/grizzlemaw/materials/grizzlemaw_"

# ---- pivots / joints (model space, rest). Legs: x mirrored by side (sx -1 = left FL / BL, +1 = right).
const HEAD_PIVOT := Vector3(0.0, 1.52, 0.84)    # neck base (Root/Mount/Head)
const JAW_PIVOT := Vector3(0.0, 1.36, 1.36)     # jaw hinge (Head/Jaw)
const LEG_F := Vector3(0.40, 1.55, 0.52)        # shoulder (LegFL / LegFR)
const LEG_B := Vector3(0.40, 1.42, -0.95)       # hip (LegBL / LegBR)
const ELBOW := Vector3(0.44, 0.84, 0.60)        # front Lower joint
const KNEE := Vector3(0.43, 0.74, -0.80)        # hind Lower joint
const HIP := Vector3(0.0, 1.38, -0.92)          # the body rears up about this point (hind legs stay under it)
const PAW_F := Vector3(0.45, 0.10, 0.84)        # front paw contact (dust)
const MOUTH := Vector3(0.0, 1.33, 1.86)         # mouth front (breath)
const EYE := Vector3(0.155, 1.63, 1.60)

# Body loft (rump -> chest): z, centre y, half-width, half-height above / below the centre. Hump ~2.15 m over the
# shoulders, rump ~1.85 m, belly ~0.77 m.
const BZ := [-1.40, -1.30, -1.12, -0.86, -0.56, -0.26, 0.04, 0.30, 0.54, 0.76, 0.94, 1.04]
const BY := [1.30, 1.29, 1.30, 1.31, 1.31, 1.33, 1.39, 1.45, 1.44, 1.40, 1.37, 1.36]
const BRX := [0.12, 0.40, 0.55, 0.60, 0.61, 0.62, 0.64, 0.64, 0.60, 0.50, 0.34, 0.14]
const BRT := [0.12, 0.36, 0.50, 0.50, 0.48, 0.52, 0.64, 0.78, 0.72, 0.56, 0.38, 0.16]
const BRB := [0.12, 0.36, 0.50, 0.54, 0.55, 0.56, 0.58, 0.60, 0.58, 0.50, 0.36, 0.16]
# Neck loft (inside the shoulders -> behind the skull).
const NECK_C: Array[Vector3] = [Vector3(0, 1.66, 0.58), Vector3(0, 1.60, 0.80), Vector3(0, 1.555, 0.98),
	Vector3(0, 1.54, 1.12)]
const NECK_RX: Array[float] = [0.48, 0.46, 0.40, 0.33]
const NECK_RY: Array[float] = [0.52, 0.48, 0.40, 0.34]
const SKULL := Vector3(0.0, 1.57, 1.30)
# Snout loft (behind the eyes -> the nose).
const SN_C: Array[Vector3] = [Vector3(0, 1.50, 1.46), Vector3(0, 1.47, 1.62), Vector3(0, 1.455, 1.76),
	Vector3(0, 1.45, 1.86)]
const SN_RX: Array[float] = [0.20, 0.17, 0.14, 0.105]
const SN_RY: Array[float] = [0.18, 0.155, 0.13, 0.10]
# Lower jaw loft (hinge -> chin): an open trough, the mouth floor on top.
const JAW_C: Array[Vector3] = [Vector3(0, 1.37, 1.36), Vector3(0, 1.33, 1.56), Vector3(0, 1.305, 1.74),
	Vector3(0, 1.30, 1.84)]
const JAW_RX: Array[float] = [0.17, 0.145, 0.12, 0.08]
const JAW_RY: Array[float] = [0.085, 0.07, 0.055, 0.04]
# Collar (Elder): centre and radii around the neck just behind the head.
const COLLAR_C := Vector3(0.0, 1.555, 1.0)
const COLLAR_R := Vector2(0.44, 0.45)

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}


static func mat(name: String) -> Material:
	if not _mats.has(name):
		_mats[name] = load(DIR + name + ".tres")
	return _mats[name]


static func fur_name(v: int) -> String:
	return "elder_fur" if v == 1 else "fur"


static func muzzle_name(v: int) -> String:
	return "elder_muzzle" if v == 1 else "muzzle"


# ================================================================ geometry helpers

static func _b(d: Dictionary, name: String) -> Array:
	if not d.has(name):
		d[name] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]
	return d[name]


## A (cols+1) x (rows+1) grid of points (row-major) with given normals; each triangle is wound so its front faces its
## normals; degenerate triangles are skipped.
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
				if front.length_squared() < 1e-14:
					continue
				if front.dot(nrm[a] + nrm[b] + nrm[c]) < 0.0:
					var t := b
					b = c
					c = t
				acc[3].append(b0 + a)
				acc[3].append(b0 + b)
				acc[3].append(b0 + c)


## Ellipsoid (lat-long grid) at c with radii r, rotated by rot.
static func _ellipsoid(acc: Array, c: Vector3, r: Vector3, radial: int = 7, rings: int = 4,
		rot: Basis = Basis.IDENTITY) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	var inv := Vector3(1.0 / maxf(r.x, 0.0001), 1.0 / maxf(r.y, 0.0001), 1.0 / maxf(r.z, 0.0001))
	for j: int in rings + 1:
		var th := PI * float(j) / float(rings)
		for i: int in radial + 1:
			var ph := TAU * float(i) / float(radial)
			var u := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			pts.append(c + rot * (u * r))
			nrm.append((rot * (u * inv)).normalized())
	_grid(acc, pts, nrm, radial, rings)


## Smooth tube through pts (radii per point, 0 = a point), `seg` sides, parallel-transported frames.
static func _tube(acc: Array, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> void:
	var grid := PackedVector3Array()
	var nrm := PackedVector3Array()
	var n := pts.size()
	var s := Vector3.ZERO
	for i: int in n:
		var t := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		if i == 0:
			var ref := Vector3.UP
			for cand: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
				if absf(t.dot(cand)) < absf(t.dot(ref)):
					ref = cand
			s = t.cross(ref).normalized()
		else:
			var ps := s - t * s.dot(t)
			s = ps.normalized() if ps.length_squared() > 1e-8 else t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT).normalized()
		var u := s.cross(t).normalized()
		for k: int in seg + 1:
			var a := TAU * float(k) / float(seg)
			var dd := s * cos(a) + u * sin(a)
			grid.append(pts[i] + dd * radii[i])
			nrm.append(dd if radii[i] > 0.0 else t)
	_grid(acc, grid, nrm, seg, n - 1)


## A small cone (fur tuft, tooth, claw spike, moss strand): `sides` faces from a ring at `base` to `tip`.
static func _cone(acc: Array, base: Vector3, tip: Vector3, r: float, sides: int = 4) -> void:
	var d := tip - base
	var ln := d.length()
	if ln < 0.0001:
		return
	var t := d / ln
	var ref := Vector3.RIGHT if absf(t.dot(Vector3.RIGHT)) < 0.8 else Vector3.FORWARD
	var s := t.cross(ref).normalized()
	var u := s.cross(t).normalized()
	var slope := r / ln
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in sides + 1:
			var a := TAU * float(k) / float(sides)
			var dir := s * cos(a) + u * sin(a)
			pts.append(base + dir * r if row == 0 else tip)
			nrm.append((dir + t * slope).normalized())
	_grid(acc, pts, nrm, sides, 1)


## A flat painted mark lying on a surface (moss clump, silver streak, scar): an oval fan of `k` points around c in the
## plane of n, long along `along`, domed by `dome` along n.
static func _patch(acc: Array, c: Vector3, n: Vector3, along: Vector3, length: float, h: float, dome: float,
		k: int = 6) -> void:
	var t := (along - n * along.dot(n)).normalized()
	var b := n.cross(t).normalized()
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for i: int in k + 1:
			var a := TAU * float(i) / float(k)
			if row == 0:
				pts.append(c + n * 0.008 + t * cos(a) * length * 0.5 + b * sin(a) * h * 0.5)
				nrm.append((n * 1.4 + (t * cos(a) + b * sin(a)) * 0.6).normalized())
			else:
				pts.append(c + n * (0.008 + dome))
				nrm.append(n)
	_grid(acc, pts, nrm, k, 1)


## A double-sided leaf / fern frond (diamond) centred at c, long along `along`, facing n.
static func _leaf(acc: Array, c: Vector3, along: Vector3, n: Vector3, length: float, width: float) -> void:
	var t := along.normalized()
	var s := n.cross(t).normalized()
	var nn := t.cross(s).normalized()
	var base := c - t * length * 0.5
	var tip := c + t * length * 0.5
	var mid := c - t * length * 0.1
	for face: float in [1.0, -1.0]:
		var o := nn * 0.003 * face
		_grid(acc, PackedVector3Array([base + o, mid + s * width * 0.5 + o, mid - s * width * 0.5 + o, tip + o]),
			PackedVector3Array([nn * face, nn * face, nn * face, nn * face]), 1, 1)


## Point of a loft at station i, angle a (0 = top, PI/2 = +x side, PI = bottom); `fur` adds a lumpy shag.
static func _lp(c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, a: float, fur: float = 0.0) -> Vector3:
	var n := c.size()
	i = clampi(i, 0, n - 1)
	var t := (c[mini(i + 1, n - 1)] - c[maxi(i - 1, 0)]).normalized()
	var up := t.cross(Vector3.RIGHT).normalized()
	var f := 1.0 + fur * (sin(7.0 * a + 2.3 * float(i)) * 0.6 + sin(13.0 * a - 1.7 * float(i)) * 0.4)
	return c[i] + Vector3.RIGHT * sin(a) * rx[i] * f + up * cos(a) * ry[i] * f


static func _ln(c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, a: float) -> Vector3:
	var p := _lp(c, rx, ry, i, a)
	var du := _lp(c, rx, ry, i, a + 0.02) - _lp(c, rx, ry, i, a - 0.02)
	var dv := _lp(c, rx, ry, i + 1, a) - _lp(c, rx, ry, i - 1, a)
	var nn := du.cross(dv)
	var radial := p - c[clampi(i, 0, c.size() - 1)]
	if nn.length_squared() < 1e-10:
		nn = radial
	nn = nn.normalized()
	if nn.dot(radial) < 0.0:
		nn = -nn
	return nn


static func _loft_patch(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i0: int, i1: int,
		angs: PackedFloat32Array, fur: float = 0.0) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for i: int in range(i0, i1 + 1):
		for a: float in angs:
			pts.append(_lp(c, rx, ry, i, a, fur))
			nrm.append(_ln(c, rx, ry, i, a))
	_grid(acc, pts, nrm, angs.size() - 1, i1 - i0)


## A fan closing a loft at station i (tip pushed along n by bulge).
static func _disc(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, n: Vector3,
		bulge: float, ring: int = 12, a0: float = 0.0, a1: float = TAU) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in ring + 1:
			var a := lerpf(a0, a1, float(k) / float(ring))
			pts.append(_lp(c, rx, ry, i, a) if row == 0 else c[i] + n * bulge)
			nrm.append(n)
	_grid(acc, pts, nrm, ring, 1)


static func _even(a0: float, a1: float, steps: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k: int in steps + 1:
		out.append(lerpf(a0, a1, float(k) / float(steps)))
	return out


static func _commit(key: String, d: Dictionary, origin: Vector3) -> ArrayMesh:
	var am := ArrayMesh.new()
	for name: String in d:
		var acc: Array = d[name]
		var v: PackedVector3Array = acc[0]
		if v.is_empty():
			continue
		for i: int in v.size():
			v[i] -= origin
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_TEX_UV] = acc[2]
		arrays[Mesh.ARRAY_INDEX] = acc[3]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, mat(name))
	_meshes[key] = am
	return am


static func _jit(rng: RandomNumberGenerator, a: float) -> Vector3:
	return Vector3(rng.randf_range(-a, a), rng.randf_range(-a, a), rng.randf_range(-a, a))


# ================================================================ body sampling

## Catmull-Rom through the station values at z: [centre y, half-width, half-height top, half-height bottom].
static func _bs(z: float) -> PackedFloat32Array:
	var n: int = BZ.size()
	var zc := clampf(z, BZ[0], BZ[n - 1])
	var i := 0
	while i < n - 2 and zc > float(BZ[i + 1]):
		i += 1
	var u: float = (zc - float(BZ[i])) / (float(BZ[i + 1]) - float(BZ[i]))
	return PackedFloat32Array([_cr(BY, i, u), _cr(BRX, i, u), _cr(BRT, i, u), _cr(BRB, i, u)])


static func _cr(a: Array, i: int, u: float) -> float:
	var n := a.size()
	var p0: float = a[maxi(i - 1, 0)]
	var p1: float = a[i]
	var p2: float = a[mini(i + 1, n - 1)]
	var p3: float = a[mini(i + 2, n - 1)]
	var u2 := u * u
	return 0.5 * (2.0 * p1 + (p2 - p0) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2
		+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * u2 * u)


## Body surface point at z, angle a (0 top, PI/2 right flank, PI belly), lumpy shag; `lift` pushes it out (m).
static func body_pt(z: float, a: float, lift: float = 0.0) -> Vector3:
	var s := _bs(z)
	var ca := cos(a)
	var fur := 1.0 + 0.04 * sin(7.0 * a + 11.0 * z) + 0.025 * sin(13.0 * a - 7.0 * z + 1.3)
	var ry: float = s[2] if ca >= 0.0 else s[3]
	return Vector3(sin(a) * (s[1] * fur + lift), s[0] + ca * (ry * fur + lift), z)


static func body_n(z: float, a: float) -> Vector3:
	var du := body_pt(z, a + 0.01) - body_pt(z, a - 0.01)
	var dv := body_pt(z + 0.01, a) - body_pt(z - 0.01, a)
	var nn := du.cross(dv)
	var p := body_pt(z, a)
	var radial := p - Vector3(0.0, _bs(z)[0], z)
	if nn.length_squared() < 1e-12:
		nn = radial
	nn = nn.normalized()
	if nn.dot(radial) < 0.0:
		nn = -nn
	return nn


## A tuft of fur sticking out of the body at (z, a): out along the normal, swept by `sweep`.
static func _body_tuft(acc: Array, z: float, a: float, out: float, sweep: Vector3, r: float) -> void:
	var p := body_pt(z, a, -0.03)
	_cone(acc, p, p + body_n(z, a) * out + sweep, r, 4)


## A streak lying ON the curved body (it follows the surface, so long streaks never lift off like quills): from
## (z0, a0) to (z1, a1), `w` radians wide in the middle, tapered at both ends, `lift` m above the fur.
static func _body_strip(acc: Array, z0: float, a0: float, z1: float, a1: float, w: float, lift: float) -> void:
	var steps: int = maxi(6, int(absf(z1 - z0) / 0.12))
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for i: int in steps + 1:
		var u := float(i) / float(steps)
		var z := lerpf(z0, z1, u)
		var a := lerpf(a0, a1, u)
		var hw := w * 0.5 * (0.25 + 0.75 * sin(PI * u))
		for s: float in [-1.0, 1.0]:
			pts.append(body_pt(z, a + hw * s, lift))
			nrm.append(body_n(z, a + hw * s))
	_grid(acc, pts, nrm, 1, steps)


static func _body_patch(acc: Array, z: float, a: float, along: Vector3, length: float, h: float, dome: float,
		k: int = 7) -> void:
	_patch(acc, body_pt(z, a), body_n(z, a), along, length, h, dome, k)


# ================================================================ body (Root/Mount)

## The great barrel: rump lower than the shoulder HUMP, lumpy fur, a dorsal ridge of tufts, a shaggy belly fringe, a
## stubby tail. v0: a green moss saddle over the hump and shoulders (strands hanging, a few fern fronds). v1: greyer
## fur, silver streaks raked along the back and flanks, three pale claw scars on the right shoulder, a little moss.
static func body_mesh(v: int) -> Mesh:
	var key := "body_%d" % v
	if _meshes.has(key):
		return _meshes[key]
	var d := {}
	var fur := _b(d, fur_name(v))
	var dark := _b(d, "fur_dark")
	var moss := _b(d, "moss")
	var streak: Array = _b(d, "elder_streak") if v == 1 else []
	# Skin.
	var nz: int = 26
	var na: int = 22
	var z0: float = BZ[0]
	var z1: float = BZ[BZ.size() - 1]
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for j: int in nz + 1:
		var z: float = lerpf(z0, z1, float(j) / float(nz))
		for k: int in na + 1:
			var a: float = TAU * float(k) / float(na)
			pts.append(body_pt(z, a))
			nrm.append(body_n(z, a))
	_grid(fur, pts, nrm, na, nz)
	for e: Array in [[z0, Vector3.FORWARD], [z1, Vector3.BACK]]:
		var ze: float = e[0]
		var s := _bs(ze)
		var ring := PackedVector3Array()
		var rn := PackedVector3Array()
		for row: int in 2:
			for k: int in na + 1:
				ring.append(body_pt(ze, TAU * float(k) / float(na)) if row == 0 else Vector3(0.0, s[0], ze) + (e[1] as Vector3) * 0.06)
				rn.append(e[1])
		_grid(fur, ring, rn, na, 1)
	# Dorsal ridge of fur tufts (rump -> behind the hump), alternating sides.
	# Soft, low shag (a bear is round: no bristle ridge, that is the Tusker's read).
	var ridge_zs: Array = [-1.0, -0.62, -0.24]
	for i: int in ridge_zs.size():
		var a := 0.16 * (1.0 if i % 2 == 0 else -1.0)
		_body_tuft(fur, ridge_zs[i], a, 0.05, Vector3(0.0, 0.0, -0.1), 0.11)
	# Hump side tufts, rump tufts, chest ruff, belly fringe (hangs down).
	for sx: float in [-1.0, 1.0]:
		for z: float in [0.08, 0.36, 0.6]:
			_body_tuft(fur, z, 1.25 * sx, 0.07, Vector3(0.03 * sx, -0.06, -0.1), 0.1)
		for za: Array in [[-1.2, 0.8], [-1.24, 1.6], [-1.05, 2.1]]:
			_body_tuft(fur, za[0], float(za[1]) * sx, 0.1, Vector3(0.0, -0.02, -0.12), 0.085)
		for za: Array in [[0.9, 1.9], [0.86, 2.5], [0.8, 2.9]]:
			_body_tuft(fur, za[0], float(za[1]) * sx, 0.06, Vector3(0.0, -0.16, 0.05), 0.08)
		var z := -0.9
		while z < 0.62:
			_body_tuft(dark, z, 2.25 * sx, 0.03, Vector3(0.02 * sx, -0.13, -0.05), 0.09)
			z += 0.24
	# Tail: a stubby dark tuft.
	_ellipsoid(dark, Vector3(0.0, 1.60, -1.42), Vector3(0.11, 0.11, 0.12), 7, 4)
	_cone(dark, Vector3(0.0, 1.62, -1.46), Vector3(0.0, 1.52, -1.6), 0.07, 4)
	# Moss saddle: big domed clumps over the hump and shoulder tops, hanging strands, fern fronds (v1 keeps a few).
	var clumps: Array = [[0.30, 0.0, 0.66, 0.58], [0.08, 0.56, 0.54, 0.38], [0.08, -0.56, 0.54, 0.38],
		[0.52, 0.64, 0.44, 0.32], [0.52, -0.62, 0.44, 0.32], [-0.14, 0.18, 0.4, 0.3], [-0.2, -0.34, 0.32, 0.26],
		[0.64, 0.0, 0.38, 0.3], [0.26, 0.92, 0.34, 0.24], [0.26, -0.92, 0.34, 0.24]]
	var keep_v1: Array = [0, 4, 6]
	for i: int in clumps.size():
		if v == 1 and not (i in keep_v1):
			continue
		var c: Array = clumps[i]
		_body_patch(moss, c[0], c[1], Vector3(float(c[1]) * 0.3, 0.0, 1.0), c[2], c[3], 0.075, 8)
	for sx: float in [-1.0, 1.0]:
		var zs: Array = [-0.04, 0.2, 0.44, 0.62] if v == 0 else [0.44]
		for z: float in zs:
			var p := body_pt(z, 1.12 * sx, -0.01)
			_cone(moss, p, p + Vector3(0.05 * sx, -0.26 - 0.06 * sin(z * 9.0), -0.04), 0.06, 4)
	if v == 0:
		for f: Array in [[0.30, 0.22, 0.3], [0.12, -0.46, 0.26], [0.5, -0.24, 0.24], [0.02, 0.5, 0.22]]:
			var p := body_pt(f[0], f[1], 0.05)
			var n := body_n(f[0], f[1])
			for k: int in 3:
				var ang: float = float(k) * TAU / 3.0 + float(f[1])
				var along := (n * 1.2 + Vector3(cos(ang), 0.0, sin(ang)) * 0.7).normalized()
				_leaf(moss, p + along * float(f[2]) * 0.45, along, Vector3(-sin(ang), 0.3, cos(ang)).normalized(),
					f[2], float(f[2]) * 0.34)
	# Elder: silver streaks raked back along the back and the flanks, the spine silvered, three claw scars.
	if v == 1:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3017
		# Broad silvered swathes (a silvertip), not thin dashes: thin ones read as quills.
		for sx: float in [-1.0, 1.0]:
			for a: float in [0.4, 0.72, 1.04, 1.32]:
				for z: float in [-0.92, -0.3, 0.3]:
					if a > 1.2 and z > 0.2:
						continue
					var zz := z + rng.randf_range(-0.1, 0.1) + (0.15 if sx > 0.0 else 0.0) + a * 0.12
					var aa := a + rng.randf_range(-0.04, 0.04)
					var ln := rng.randf_range(0.7, 0.85)
					# Raked back and a little down the flank.
					_body_strip(streak, zz + ln * 0.5, (aa - 0.08) * sx, zz - ln * 0.5, (aa + 0.1) * sx,
						rng.randf_range(0.17, 0.21), 0.012)
		_body_strip(streak, 0.78, 0.0, -1.18, 0.0, 0.5, 0.014)
		for k: int in 3:
			var z := 0.46 + 0.12 * float(k)
			_body_patch(streak, z, 1.02 + 0.06 * float(k), Vector3(0.0, -0.8, 0.45), 0.36, 0.045, 0.006, 6)
	return _commit(key, d, Vector3.ZERO)


# ================================================================ head (Root/Mount/Head)

## Thick shaggy neck, big round skull with a forehead dome, small ROUND ears, a heavy tan (Elder: white) muzzle with a
## black nose, amber glowing eyes (red when enraged) under a heavy scowling brow, cheek ruffs, upper fangs, the dark
## red palate (seen when the jaw opens). Elder: white brows, a torn left ear, silver streaks, scars across the nose,
## and the RUSTED CHAIN collar (links, a dangling broken end with a tooth pendant, a lock plate) with old bones (a
## small skull, two crossed long bones).
static func head_mesh(v: int, rage: bool) -> Mesh:
	var key := "head_%d_%s" % [v, rage]
	if _meshes.has(key):
		return _meshes[key]
	var d := {}
	var fur := _b(d, fur_name(v))
	var muz := _b(d, muzzle_name(v))
	var dark := _b(d, "fur_dark")
	var nose := _b(d, "nose")
	var mouth := _b(d, "mouth")
	var claw := _b(d, "claw")
	var eye := _b(d, "eye_rage" if rage else "eye_glow")
	# Neck (shaggy) + ruff tufts along its sides.
	_loft_patch(fur, NECK_C, NECK_RX, NECK_RY, 0, NECK_C.size() - 1, _even(0.0, TAU, 18), 0.05)
	for sx: float in [-1.0, 1.0]:
		for i: int in [1, 2]:
			for a: float in [1.2, 1.75, 2.3]:
				var p := _lp(NECK_C, NECK_RX, NECK_RY, i, a * sx, 0.0) - Vector3(0, 0, 0.02)
				_cone(fur, p, p + Vector3(0.1 * sx, -0.1 - 0.05 * a, -0.14), 0.085, 4)
	# Skull, forehead dome, cheeks.
	_ellipsoid(fur, SKULL, Vector3(0.37, 0.335, 0.35), 12, 7)
	_ellipsoid(fur, Vector3(0.0, 1.71, 1.36), Vector3(0.27, 0.17, 0.24), 10, 5)
	for sx: float in [-1.0, 1.0]:
		_ellipsoid(fur, Vector3(0.21 * sx, 1.47, 1.42), Vector3(0.18, 0.15, 0.17), 8, 4)
		for k: int in 4:
			var b := Vector3(0.3 * sx, 1.58 - 0.08 * float(k), 1.26 - 0.02 * float(k))
			_cone(fur, b, b + Vector3(0.13 * sx, -0.07 - 0.03 * float(k), -0.1), 0.08, 4)
	# Snout (muzzle colour) + nose, palate, fangs.
	_loft_patch(muz, SN_C, SN_RX, SN_RY, 0, SN_C.size() - 1, _even(0.0, TAU, 12))
	_disc(muz, SN_C, SN_RX, SN_RY, SN_C.size() - 1, Vector3.BACK, 0.03, 12)
	_ellipsoid(nose, Vector3(0.0, 1.50, 1.885), Vector3(0.095, 0.066, 0.06), 8, 4)
	_patch(nose, Vector3(0.0, 1.405, 1.9), Vector3(0.0, -0.2, 1.0).normalized(), Vector3.DOWN, 0.1, 0.03, 0.004, 5)
	_patch(mouth, Vector3(0.0, 1.318, 1.62), Vector3.DOWN, Vector3.BACK, 0.4, 0.22, 0.012, 8)
	for sx: float in [-1.0, 1.0]:
		_cone(claw, Vector3(0.085 * sx, 1.35, 1.79), Vector3(0.08 * sx, 1.21, 1.815), 0.032, 5)
		_cone(claw, Vector3(0.03 * sx, 1.34, 1.85), Vector3(0.03 * sx, 1.29, 1.855), 0.02, 4)
	# Eyes (glow) under the heavy brow; ears.
	for sx: float in [-1.0, 1.0]:
		# (the glowing eyes and the scowling brows: the grizzlemaw's CreatureFaceRig, faces pass 2026-09-28)
		# Small ROUND ears on top of the head: a flat disc, the dark inside painted on its front face.
		var torn := v == 1 and sx < 0.0
		var er := Basis(Vector3.BACK, -0.28 * sx) * Basis(Vector3.UP, 0.3 * sx)
		var es := Vector3(0.115, 0.115, 0.05) * (Vector3(0.8, 0.66, 1.0) if torn else Vector3.ONE)
		var ec := Vector3(0.26 * sx, 1.88 - (0.03 if torn else 0.0), 1.22)
		_ellipsoid(fur, ec, es, 9, 4, er)
		var ef := er * Vector3.BACK
		_patch(nose, ec + ef * (es.z - 0.004), ef, er * Vector3.UP, es.y * 1.2, es.x * 1.15, 0.004, 7)
	# Elder extras.
	if v == 1:
		var streak := _b(d, "elder_streak")
		var rust := _b(d, "rust")
		# White spectacles round the eyes, silver streaks over the forehead and the neck, scars over the nose.
		for sx: float in [-1.0, 1.0]:
			_patch(muz, Vector3(0.21 * sx, 1.60, 1.56), Vector3(0.55 * sx, 0.3, 0.78).normalized(), Vector3(0, 1, 0),
				0.22, 0.17, 0.012, 7)
			for k: int in 3:
				var a: float = (0.35 + 0.42 * float(k)) * sx
				var p := _lp(NECK_C, NECK_RX, NECK_RY, 2, a, 0.0)
				_patch(streak, p, _ln(NECK_C, NECK_RX, NECK_RY, 2, a), Vector3(0, -0.2, -1.0), 0.42, 0.07, 0.01, 6)
		for k: int in 3:
			var x := -0.1 + 0.1 * float(k)
			_patch(streak, Vector3(x, 1.885, 1.34 + 0.02 * float(k)), Vector3(0, 1, 0.1).normalized(), Vector3(0.1, 0, -1),
				0.32, 0.08, 0.012, 6)
		_patch(streak, Vector3(0.03, 1.63, 1.66), Vector3(0.0, 0.9, 0.45).normalized(), Vector3(1.0, 0.0, 0.3), 0.2,
			0.03, 0.005, 5)
		_patch(streak, Vector3(-0.02, 1.61, 1.72), Vector3(0.0, 0.85, 0.5).normalized(), Vector3(1.0, 0.0, -0.2), 0.18,
			0.028, 0.005, 5)
		_collar(rust, claw, nose)
	return _commit(key, d, HEAD_PIVOT)


## The Elder's rusted chain collar round the neck, a dangling broken end with a tooth pendant, the lock plate, a small
## skull and two crossed long bones tied on the chain.
static func _collar(rust: Array, bone: Array, dark: Array) -> void:
	var dir := (NECK_C[2] - NECK_C[0]).normalized()
	var up := dir.cross(Vector3.RIGHT).normalized()
	var links: int = 18
	var pts: Array[Vector3] = []
	for k: int in links:
		var t := TAU * float(k) / float(links)
		pts.append(_collar_pt(t, dir, up))
	for k: int in links:
		var t := TAU * float(k) / float(links)
		var tan := (_collar_pt(t + 0.02, dir, up) - _collar_pt(t - 0.02, dir, up)).normalized()
		var radial := (pts[k] - COLLAR_C - dir * (pts[k] - COLLAR_C).dot(dir)).normalized()
		var nrm := radial if k % 2 == 0 else dir
		_link(rust, pts[k], tan, nrm, 0.108, 0.058, 0.026, true)
	# Lock plate at the throat, the dangling broken end (5 links, the last one torn open) and a tooth pendant.
	var bottom := _collar_pt(PI, dir, up)
	_ellipsoid(rust, bottom + Vector3(0.0, -0.02, 0.05), Vector3(0.1, 0.085, 0.05), 7, 3)
	var prev := bottom + Vector3(0.0, -0.06, 0.05)
	for k: int in 5:
		var p := bottom + Vector3(0.015 * float(k), -0.1 - 0.11 * float(k), 0.08 + 0.028 * float(k))
		var tan := (p - prev).normalized()
		_link(rust, p, tan, Vector3.RIGHT if k % 2 == 0 else Vector3.BACK, 0.105, 0.056, 0.024, k < 4)
		prev = p
	var end := prev + Vector3(0.0, -0.07, 0.01)
	_cone(bone, end, end + Vector3(0.02, -0.2, 0.06), 0.045, 5)
	# A small skull hanging on the right side, two crossed long bones on the left.
	var sk := _collar_pt(2.25, dir, up) + Vector3(0.05, -0.13, 0.03)
	_ellipsoid(bone, sk, Vector3(0.085, 0.075, 0.09), 7, 4)
	_ellipsoid(bone, sk + Vector3(0.02, -0.05, 0.07), Vector3(0.05, 0.04, 0.07), 6, 3)
	for sx: float in [-1.0, 1.0]:
		_ellipsoid(dark, sk + Vector3(0.05 + 0.03 * sx, 0.0, 0.06), Vector3(0.022, 0.024, 0.02), 5, 3)
	var cb := _collar_pt(-2.2, dir, up) + Vector3(-0.07, -0.12, 0.02)
	for s: float in [-1.0, 1.0]:
		var a := cb + Vector3(0.0, -0.14, -0.13 * s)
		var b := cb + Vector3(0.0, 0.14, 0.13 * s)
		_tube(bone, PackedVector3Array([a, a.lerp(b, 0.5), b]), PackedFloat32Array([0.028, 0.024, 0.028]), 5)
		for e: Vector3 in [a, b]:
			var side := (e - cb).normalized().cross(Vector3.RIGHT).normalized()
			_ellipsoid(bone, e + side * 0.022, Vector3(0.036, 0.036, 0.036), 5, 3)
			_ellipsoid(bone, e - side * 0.022, Vector3(0.036, 0.036, 0.036), 5, 3)


static func _collar_pt(t: float, dir: Vector3, up: Vector3) -> Vector3:
	var sag := maxf(0.0, -cos(t))
	return COLLAR_C + up * cos(t) * COLLAR_R.y + Vector3.RIGHT * sin(t) * COLLAR_R.x + dir * 0.06 * sag \
		+ Vector3(0.0, -0.05, 0.0) * sag * sag


## One chain link: an elongated loop centred at c, long along `tan`, in the plane normal to `n`; open = false tears a
## gap in it.
static func _link(acc: Array, c: Vector3, tan: Vector3, n: Vector3, half_len: float, half_w: float, wire: float,
		closed: bool) -> void:
	var t := tan.normalized()
	var s := n.cross(t).normalized()
	if s.length_squared() < 0.5:
		s = t.cross(Vector3.UP).normalized()
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	var steps: int = 8
	var span := TAU if closed else TAU * 0.78
	for k: int in steps + 1:
		var u := span * float(k) / float(steps)
		pts.append(c + t * cos(u) * half_len + s * sin(u) * half_w)
		rad.append(wire)
	_tube(acc, pts, rad, 4)


# ================================================================ jaw (Head/Jaw, keep_separate)

## Lower jaw: an open trough (muzzle colour outside, the tongue / mouth floor on top), lower fangs, the chin; Elder: a
## white chin tuft. Local to JAW_PIVOT; + rotation.x opens it.
static func jaw_mesh(v: int) -> Mesh:
	var key := "jaw_%d" % v
	if _meshes.has(key):
		return _meshes[key]
	var d := {}
	var muz := _b(d, muzzle_name(v))
	var mouth := _b(d, "mouth")
	var claw := _b(d, "claw")
	var fur := _b(d, fur_name(v))
	var n: int = JAW_C.size()
	_loft_patch(muz, JAW_C, JAW_RX, JAW_RY, 0, n - 1, _even(PI * 0.5, PI * 1.5, 8))
	_disc(muz, JAW_C, JAW_RX, JAW_RY, n - 1, Vector3.BACK, 0.03, 8, PI * 0.5, PI * 1.5)
	_patch(mouth, Vector3(0.0, 1.318, 1.58), Vector3.UP, Vector3.BACK, 0.44, 0.24, 0.02, 8)
	for sx: float in [-1.0, 1.0]:
		_cone(claw, Vector3(0.075 * sx, 1.30, 1.765), Vector3(0.072 * sx, 1.41, 1.76), 0.028, 5)
	# Throat fur under the jaw hinge (hides the gap when it opens).
	_ellipsoid(fur, Vector3(0.0, 1.30, 1.40), Vector3(0.17, 0.09, 0.12), 8, 4)
	if v == 1:
		_cone(muz, Vector3(0.0, 1.27, 1.72), Vector3(0.0, 1.13, 1.66), 0.07, 5)
		_cone(muz, Vector3(0.05, 1.27, 1.62), Vector3(0.06, 1.15, 1.56), 0.06, 4)
		_cone(muz, Vector3(-0.05, 1.27, 1.62), Vector3(-0.06, 1.15, 1.56), 0.06, 4)
	return _commit(key, d, JAW_PIVOT)


# ================================================================ legs

## Upper leg (merged into the leg pivot): front = the massive shoulder + upper arm to the elbow (fur ruff at the elbow);
## hind = the haunch + thigh to the knee. Elder: silver streaks on the shoulder / haunch.
static func upper_leg_mesh(front: bool, sx: float, v: int) -> Mesh:
	var key := "upper_%s_%s_%d" % [front, sx, v]
	if _meshes.has(key):
		return _meshes[key]
	var d := {}
	var fur := _b(d, fur_name(v))
	var m := Vector3(sx, 1.0, 1.0)
	if front:
		_ellipsoid(fur, Vector3(0.39, 1.36, 0.55) * m, Vector3(0.24, 0.42, 0.33), 9, 5)
		var p := PackedVector3Array([Vector3(0.41, 1.42, 0.55) * m, Vector3(0.44, 1.12, 0.58) * m,
			Vector3(0.44, 0.86, 0.60) * m])
		_tube(fur, p, PackedFloat32Array([0.26, 0.23, 0.205]), 9)
		_leg_ruff(fur, Vector3(0.44 * sx, 0.98, 0.59), 0.2, 0.26)
		if v == 1:
			var st := _b(d, "elder_streak")
			for k: int in 2:
				_patch(st, Vector3(0.6 * sx, 1.4 - 0.2 * float(k), 0.52 + 0.08 * float(k)), Vector3(sx, 0.25, 0.0).normalized(),
					Vector3(0, -1, 0.3), 0.4, 0.07, 0.01, 6)
		return _commit(key, d, LEG_F * m)
	_ellipsoid(fur, Vector3(0.37, 1.30, -0.98) * m, Vector3(0.26, 0.44, 0.42), 9, 5)
	var q := PackedVector3Array([Vector3(0.40, 1.32, -0.95) * m, Vector3(0.42, 1.02, -0.86) * m,
		Vector3(0.43, 0.76, -0.80) * m])
	_tube(fur, q, PackedFloat32Array([0.29, 0.25, 0.205]), 9)
	for k: int in 2:
		var b := Vector3(0.42 * sx, 1.14 - 0.18 * float(k), -1.28 + 0.1 * float(k))
		_cone(fur, b, b + Vector3(0.02 * sx, -0.12, -0.1), 0.09, 4)
	_leg_ruff(fur, Vector3(0.43 * sx, 0.9, -0.83), 0.2, 0.24)
	if v == 1:
		var st := _b(d, "elder_streak")
		for k: int in 2:
			_patch(st, Vector3(0.62 * sx, 1.36 - 0.16 * float(k), -1.0 + 0.1 * float(k)), Vector3(sx, 0.2, 0.0).normalized(),
				Vector3(0, -0.4, 1.0), 0.42, 0.07, 0.01, 6)
	return _commit(key, d, LEG_B * m)


## A ring of fur locks hanging over the top of the dark forearm / shin, so the brown -> dark step is ragged, not a
## boot line.
static func _leg_ruff(acc: Array, c: Vector3, r: float, drop: float) -> void:
	for k: int in 7:
		var a := TAU * float(k) / 7.0 + 0.3
		var d := Vector3(sin(a), 0.0, cos(a))
		var b := c + d * r * 0.92
		_cone(acc, b, b + d * 0.05 + Vector3(0.0, -drop * (0.8 + 0.2 * sin(a * 3.0)), 0.0), 0.085, 4)


## Lower leg (keep_separate "Lower/Paw", local to the elbow / knee): dark forearm / shin, a big dark paw (hind: a flat
## plantigrade foot) and five long pale CURVED CLAWS (front 0.3 m: the huge-claws read; hind shorter). Folds back at
## the joint in the stride.
static func lower_leg_mesh(front: bool, sx: float, v: int) -> Mesh:
	var key := "lower_%s_%s_%d" % [front, sx, v]
	if _meshes.has(key):
		return _meshes[key]
	var d := {}
	var dark := _b(d, "fur_dark")
	var claw := _b(d, "claw")
	var m := Vector3(sx, 1.0, 1.0)
	var j: Vector3 = ELBOW if front else KNEE
	if front:
		_ellipsoid(dark, ELBOW * m, Vector3(0.2, 0.2, 0.2), 8, 4)
		_tube(dark, PackedVector3Array([ELBOW * m, Vector3(0.45, 0.52, 0.63) * m, Vector3(0.45, 0.26, 0.68) * m]),
			PackedFloat32Array([0.205, 0.185, 0.165]), 8)
		for k: int in 3:
			var b := Vector3((0.45 + 0.07 * float(k - 1)) * sx, 0.4, 0.5)
			_cone(dark, b, b + Vector3(0.02 * sx, -0.15, -0.12), 0.07, 4)
		_ellipsoid(dark, Vector3(0.45, 0.125, 0.80) * m, Vector3(0.21, 0.12, 0.25), 9, 5, Basis(Vector3.RIGHT, 0.05))
		for k: int in 5:
			var x: float = (0.45 + 0.075 * float(k - 2)) * sx
			var fan: float = 0.05 * float(k - 2) * sx
			_ellipsoid(dark, Vector3(x, 0.1, 0.98), Vector3(0.05, 0.06, 0.06), 6, 3)
			_tube(claw, PackedVector3Array([Vector3(x, 0.12, 0.99), Vector3(x + fan * 0.6, 0.11, 1.14),
				Vector3(x + fan, 0.02, 1.25)]), PackedFloat32Array([0.042, 0.03, 0.0]), 5)
		if v == 1:
			_patch(_b(d, "elder_streak"), Vector3(0.64 * sx, 0.6, 0.62), Vector3(sx, 0.0, 0.1).normalized(),
				Vector3(0, -1, 0), 0.3, 0.06, 0.008, 6)
		return _commit(key, d, j * m)
	_ellipsoid(dark, KNEE * m, Vector3(0.2, 0.2, 0.21), 8, 4)
	_tube(dark, PackedVector3Array([KNEE * m, Vector3(0.43, 0.45, -0.90) * m, Vector3(0.43, 0.2, -1.0) * m]),
		PackedFloat32Array([0.205, 0.18, 0.155]), 8)
	_ellipsoid(dark, Vector3(0.43, 0.14, -0.98) * m, Vector3(0.15, 0.13, 0.14), 7, 4)
	_ellipsoid(dark, Vector3(0.43, 0.1, -0.80) * m, Vector3(0.18, 0.1, 0.28), 9, 5)
	for k: int in 5:
		var x: float = (0.43 + 0.065 * float(k - 2)) * sx
		_ellipsoid(dark, Vector3(x, 0.08, -0.56), Vector3(0.045, 0.05, 0.05), 5, 3)
		_tube(claw, PackedVector3Array([Vector3(x, 0.09, -0.55), Vector3(x, 0.07, -0.47), Vector3(x, 0.02, -0.41)]),
			PackedFloat32Array([0.032, 0.022, 0.0]), 4)
	return _commit(key, d, j * m)
