extends RefCounted
## Hollow Stag meshes (task 12.V23): static builders used by hollow_stag.gd only. Every mesh is built once per game
## and cached (model space, feet at y 0, face toward +Z; keep_separate parts are local to their joint). Deterministic:
## the gnarled antler branches and leaves come from fixed RNG seeds.
## Materials (materials/, painted = kit unit_painted, glow = kit unit_glow): hide (pale ash-bone coat), shade (grey
## stockings, muzzle), bark (antler wood, hooves, birch marks, ribs' rim, root vines), moss (shawl, crest, beard,
## tufts), hollow (the dark chest cavity, green rim light), heart_glow (the green heart), leaf_glow (antler leaves).

const DIR := "res://art/units/neutral/hollow_stag/materials/hollow_stag_"
const DEG := PI / 180.0

# ---- anatomy (model space). Legs: x is mirrored by side (sx = -1 left / FL / BL, +1 right).
const HEAD_PIVOT := Vector3(0.0, 1.58, 0.74)     # neck base (Root/Mount/Head)
const SKULL_ORIGIN := Vector3(0.0, 2.10, 1.06)   # poll joint (Head/Crown)
const LEG_F := Vector3(0.25, 1.30, 0.64)         # shoulder (LegFL / LegFR)
const LEG_B := Vector3(0.22, 1.22, -0.70)        # hip (LegBL / LegBR)
const KNEE_F := Vector3(0.25, 0.56, 0.64)        # front knee (carpus): the Lower joint
const HOCK_B := Vector3(0.23, 0.62, -0.88)       # hind hock: the Lower joint
const ANTLER_BASE_Y := 2.28                      # antler burrs (the squash of the antlers starts here)
const HEART := Vector3(0.0, 1.30, 0.25)          # the glowing heart inside the hollow ribcage
const CROWN_L := Vector3(-0.72, 2.95, 1.02)      # centre of each antler crown (model space, rest)
const CROWN_R := Vector3(0.72, 2.95, 1.02)

# Body loft (rump -> chest): centre, half-width, half-height. Withers ~1.78 m, belly ~0.9 m.
const BODY_C: Array[Vector3] = [Vector3(0, 1.30, -1.04), Vector3(0, 1.32, -0.94), Vector3(0, 1.34, -0.74),
	Vector3(0, 1.31, -0.46), Vector3(0, 1.28, -0.18), Vector3(0, 1.29, 0.04), Vector3(0, 1.32, 0.25),
	Vector3(0, 1.35, 0.46), Vector3(0, 1.38, 0.64), Vector3(0, 1.36, 0.82), Vector3(0, 1.33, 0.93)]
const BODY_RX: Array[float] = [0.10, 0.24, 0.32, 0.33, 0.34, 0.355, 0.36, 0.36, 0.33, 0.25, 0.13]
const BODY_RY: Array[float] = [0.12, 0.27, 0.35, 0.37, 0.38, 0.40, 0.41, 0.41, 0.40, 0.32, 0.18]
## The hollow: a ragged oval hole in each flank, centred at z HOLE_Z / loft angle HOLE_A (0 = top of the back,
## PI / 2 = the flank, PI = belly), half-sizes HOLE_RZ (m) / HOLE_RA (rad), torn by _hole_wobble.
const HOLE_Z := 0.15
const HOLE_RZ := 0.31
const HOLE_A := 1.42
const HOLE_RA := 0.56
# Neck loft (base -> poll), stations run up-forward.
const NECK_C: Array[Vector3] = [Vector3(0, 1.44, 0.58), Vector3(0, 1.64, 0.76), Vector3(0, 1.83, 0.88),
	Vector3(0, 1.99, 0.98), Vector3(0, 2.11, 1.05)]
const NECK_RX: Array[float] = [0.25, 0.225, 0.19, 0.165, 0.14]
const NECK_RY: Array[float] = [0.29, 0.26, 0.22, 0.19, 0.16]
# Skull loft (poll -> nose), pointing forward and a little down.
const SKULL_C: Array[Vector3] = [Vector3(0, 2.16, 0.97), Vector3(0, 2.18, 1.12), Vector3(0, 2.11, 1.28),
	Vector3(0, 2.03, 1.43), Vector3(0, 1.96, 1.55), Vector3(0, 1.93, 1.62)]
const SKULL_RX: Array[float] = [0.13, 0.145, 0.12, 0.09, 0.07, 0.05]
const SKULL_RY: Array[float] = [0.14, 0.155, 0.13, 0.10, 0.075, 0.05]

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}


static func mat(name: String) -> Material:
	if not _mats.has(name):
		_mats[name] = load(DIR + name + ".tres")
	return _mats[name]


# ================================================================ geometry helpers

static func _bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## A (cols+1) x (rows+1) grid of points (row-major) with given normals; each triangle is wound so its front faces its
## normals; degenerate triangles (cone tips, fans) are skipped. `keep` (optional, one byte per cell, row-major): 0 =
## leave that cell out (the hollow's holes).
static func _grid(acc: Array, pts: PackedVector3Array, nrm: PackedVector3Array, cols: int, rows: int,
		keep: PackedByteArray = PackedByteArray()) -> void:
	var w := cols + 1
	var b0: int = (acc[0] as PackedVector3Array).size()
	for k: int in pts.size():
		acc[0].append(pts[k])
		acc[1].append(nrm[k])
		acc[2].append(Vector2.ZERO)
	for j: int in rows:
		for i: int in cols:
			if not keep.is_empty() and keep[j * cols + i] == 0:
				continue
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


## Ellipsoid (lat-long grid) at c with radii r, rotated by rot; inward = normals (and faces) point inside.
static func _ellipsoid(acc: Array, c: Vector3, r: Vector3, radial: int = 7, rings: int = 4,
		rot: Basis = Basis.IDENTITY, inward: bool = false) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	var inv := Vector3(1.0 / maxf(r.x, 0.0001), 1.0 / maxf(r.y, 0.0001), 1.0 / maxf(r.z, 0.0001))
	for j: int in rings + 1:
		var th := PI * float(j) / float(rings)
		for i: int in radial + 1:
			var ph := TAU * float(i) / float(radial)
			var u := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			pts.append(c + rot * (u * r))
			var nn := (rot * (u * inv)).normalized()
			nrm.append(-nn if inward else nn)
	_grid(acc, pts, nrm, radial, rings)


## Point of a loft at station i, angle a (0 = top, PI/2 = +x side, PI = bottom). Stations run toward +Z (or up-forward).
static func _lp(c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, a: float, inflate: float = 1.0) -> Vector3:
	var n := c.size()
	i = clampi(i, 0, n - 1)
	var t := (c[mini(i + 1, n - 1)] - c[maxi(i - 1, 0)]).normalized()
	var up := t.cross(Vector3.RIGHT).normalized()
	return c[i] + Vector3.RIGHT * sin(a) * rx[i] * inflate + up * cos(a) * ry[i] * inflate


## Outward (or inward) normal of a loft at station i, angle a.
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


## A patch of a loft: stations i0..i1, the same angle list at every station. inward: faces the axis (the hollow).
static func _loft_patch(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i0: int, i1: int,
		angs: PackedFloat32Array, inward: bool = false) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for i: int in range(i0, i1 + 1):
		for a: float in angs:
			pts.append(_lp(c, rx, ry, i, a))
			var nn := _ln(c, rx, ry, i, a)
			nrm.append(-nn if inward else nn)
	_grid(acc, pts, nrm, angs.size() - 1, i1 - i0)


## A fan closing a loft at station i, all normals = n (the tip pushed along n by bulge).
static func _disc(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, n: Vector3,
		bulge: float, ring: int = 12) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in ring + 1:
			var a := TAU * float(k) / float(ring)
			pts.append(_lp(c, rx, ry, i, a) if row == 0 else c[i] + n * bulge)
			nrm.append(n)
	_grid(acc, pts, nrm, ring, 1)


static func _even(a0: float, a1: float, steps: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k: int in steps + 1:
		out.append(lerpf(a0, a1, float(k) / float(steps)))
	return out


## Smooth tube through pts (radii per point, 0 = a point), `seg` sides. Parallel-transported frames, so bends and
## closed loops never twist or collapse.
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


## A small open cone (moss strands, tufts): `sides` faces from a ring at `base` to `tip`.
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


## A flat painted mark lying on a surface (birch-bark streak, moss clump): an oval fan of `k` points around c in the
## plane of n, long along `along` (projected on the plane), domed by `dome` along n.
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
				pts.append(c + n * 0.006 + t * cos(a) * length * 0.5 + b * sin(a) * h * 0.5)
				nrm.append((n * 1.4 + (t * cos(a) + b * sin(a)) * 0.6).normalized())
			else:
				pts.append(c + n * (0.006 + dome))
				nrm.append(n)
	_grid(acc, pts, nrm, k, 1)


## A double-sided leaf (diamond) centred at c, long along `along`, facing n.
static func _leaf(acc: Array, c: Vector3, along: Vector3, n: Vector3, length: float, width: float) -> void:
	var t := along.normalized()
	var s := n.cross(t).normalized()
	var nn := t.cross(s).normalized()
	var base := c - t * length * 0.5
	var tip := c + t * length * 0.5
	var mid := c - t * length * 0.08
	for face: float in [1.0, -1.0]:
		var o := nn * 0.003 * face
		_grid(acc, PackedVector3Array([base + o, mid + s * width * 0.5 + o, mid - s * width * 0.5 + o, tip + o]),
			PackedVector3Array([nn * face, nn * face, nn * face, nn * face]), 1, 1)


## Centre / half-width / half-height of a loft at any z (linear between stations): [Vector3, float, float].
static func _loft_at(c: Array[Vector3], rx: Array[float], ry: Array[float], z: float) -> Array:
	var n := c.size()
	if z <= c[0].z:
		return [c[0], rx[0], ry[0]]
	for i: int in n - 1:
		if z <= c[i + 1].z:
			var u: float = (z - c[i].z) / maxf(c[i + 1].z - c[i].z, 0.0001)
			return [c[i].lerp(c[i + 1], u), lerpf(rx[i], rx[i + 1], u), lerpf(ry[i], ry[i + 1], u)]
	return [c[n - 1], rx[n - 1], ry[n - 1]]


## Surface point and outward normal of the (horizontal) body loft at z, angle a: [point, normal].
static func _on_body(z: float, a: float, inflate: float = 1.0) -> Array:
	var s: Array = _loft_at(BODY_C, BODY_RX, BODY_RY, z)
	var ctr: Vector3 = s[0]
	var hx: float = s[1] * inflate
	var hy: float = s[2] * inflate
	var p := ctr + Vector3(sin(a) * hx, cos(a) * hy, 0.0)
	var nn := Vector3(sin(a) / maxf(hx, 0.001), cos(a) / maxf(hy, 0.001), 0.0).normalized()
	return [p, nn]


## Outward normal of the body surface at (z, a) (finite differences, so the taper along z is included).
static func _body_n(z: float, a: float) -> Vector3:
	var p: Vector3 = _on_body(z, a)[0]
	var du: Vector3 = (_on_body(z, a + 0.01)[0] as Vector3) - (_on_body(z, a - 0.01)[0] as Vector3)
	var dv: Vector3 = (_on_body(z + 0.01, a)[0] as Vector3) - (_on_body(z - 0.01, a)[0] as Vector3)
	var nn := du.cross(dv).normalized()
	var s: Array = _loft_at(BODY_C, BODY_RX, BODY_RY, z)
	if nn.dot(p - (s[0] as Vector3)) < 0.0:
		nn = -nn
	return nn


## The z rows of the sampled body skin: every loft station plus a fine fill across the hollow.
static func _body_zs() -> PackedFloat32Array:
	var out: Array[float] = []
	for c: Vector3 in BODY_C:
		out.append(c.z)
	var z: float = HOLE_Z - HOLE_RZ * 1.25
	while z < HOLE_Z + HOLE_RZ * 1.25:
		var near := false
		for v: float in out:
			if absf(v - z) < 0.03:
				near = true
		if not near:
			out.append(z)
		z += 0.085
	out.sort()
	return PackedFloat32Array(out)


## How far (z, side angle a) lies from the hole centre: < 1 inside the torn oval of side sx.
static func _hole_r(z: float, a: float, sx: float) -> float:
	var dz: float = (z - HOLE_Z) / HOLE_RZ
	var da: float = (a - HOLE_A) / HOLE_RA
	return sqrt(dz * dz + da * da) / _hole_wobble(atan2(da, dz), sx)


## The torn edge: radius factor of the hole outline at angle th (each side torn a little differently).
static func _hole_wobble(th: float, sx: float) -> float:
	return 1.0 + 0.11 * sin(3.0 * th + 0.7 + sx * 0.9) + 0.05 * sin(7.0 * th + sx * 2.0)


## A flat fan closing the body at z (normal n, tip pushed by bulge); inward: the hollow's end walls.
static func _body_disc(acc: Array, z: float, n: Vector3, bulge: float, _inward: bool, ring: int = 12) -> void:
	var s: Array = _loft_at(BODY_C, BODY_RX, BODY_RY, z)
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in ring + 1:
			var a := TAU * float(k) / float(ring)
			pts.append(_on_body(z, a)[0] if row == 0 else (s[0] as Vector3) + n * bulge)
			nrm.append(n)
	_grid(acc, pts, nrm, ring, 1)


## One ArrayMesh from [acc, material] pairs (empty accs skipped), cached by key.
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
		am.surface_set_material(am.get_surface_count() - 1, sf[1])
	_meshes[key] = am
	return am


## Moves every vertex of an accumulator by -o (keep_separate meshes are local to their joint).
static func _shift(acc: Array, o: Vector3) -> void:
	var v: PackedVector3Array = acc[0]
	for i: int in v.size():
		v[i] -= o
	acc[0] = v


# ================================================================ body (Root/Mount)

## The barrel: pale hide with dark birch-bark marks, a moss shawl over the withers; behind the shoulders each flank is
## torn OPEN in a ragged oval (the hollow chest): a dark cavity (inner walls), three pale ribs slanting across each
## hole (the middle one broken), a grey lip round it, and inside the green glowing heart held by dark root vines. A
## short pale tail with a moss tuft. The skin is sampled on a fine z / angle grid so the hole can be any shape.
static func body_mesh() -> Mesh:
	const KEY := "body_v2"
	if _meshes.has(KEY):
		return _meshes[KEY]
	var hide := _bucket()
	var shade := _bucket()
	var bark := _bucket()
	var moss := _bucket()
	var hollow := _bucket()
	var heart := _bucket()
	var zs := _body_zs()
	var nz: int = zs.size()
	var na: int = 20
	# Outer skin, the cells inside either hole left out.
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for z: float in zs:
		for k: int in na + 1:
			var a: float = TAU * float(k) / float(na)
			pts.append(_on_body(z, a)[0])
			nrm.append(_body_n(z, a))
	var keep := PackedByteArray()
	for j: int in nz - 1:
		for i: int in na:
			var zc: float = (zs[j] + zs[j + 1]) * 0.5
			var ac: float = TAU * (float(i) + 0.5) / float(na)
			var side: float = 1.0 if ac < PI else -1.0
			keep.append(1 if _hole_r(zc, ac if ac < PI else TAU - ac, side) >= 1.0 else 0)
	_grid(hide, pts, nrm, na, nz - 1, keep)
	_body_disc(hide, zs[nz - 1], Vector3.BACK, 0.05, false, na)
	_body_disc(hide, zs[0], Vector3.FORWARD, 0.05, false, na)
	# The hollow: the barrel facing inward over the hole's z span + two end walls facing into the cavity.
	var z_lo: float = HOLE_Z - HOLE_RZ * 1.2
	var z_hi: float = HOLE_Z + HOLE_RZ * 1.2
	var ipts := PackedVector3Array()
	var inrm := PackedVector3Array()
	var rows: int = 0
	var cz: PackedFloat32Array = PackedFloat32Array([z_lo])
	for z: float in zs:
		if z > z_lo + 0.02 and z < z_hi - 0.02:
			cz.append(z)
	cz.append(z_hi)
	for z: float in cz:
		rows += 1
		for k: int in 13:
			var a: float = TAU * float(k) / 12.0
			ipts.append(_on_body(z, a)[0])
			inrm.append(-_body_n(z, a))
	_grid(hollow, ipts, inrm, 12, rows - 1)
	_body_disc(hollow, z_lo, Vector3.BACK, 0.0, true, 12)
	_body_disc(hollow, z_hi, Vector3.FORWARD, 0.0, true, 12)
	for sx: float in [-1.0, 1.0]:
		# The grey lip round the torn hole.
		var loop := PackedVector3Array()
		var rr := PackedFloat32Array()
		for k: int in 23:
			var th: float = TAU * float(k) / 22.0
			var w: float = _hole_wobble(th, sx)
			var p: Vector3 = _on_body(HOLE_Z + HOLE_RZ * cos(th) * w, (HOLE_A + HOLE_RA * sin(th) * w) * sx)[0]
			loop.append(p)
			rr.append(0.038 + 0.012 * sin(th * 5.0 + sx))
		_tube(shade, loop, rr, 4)
		# Three pale ribs slanting back and down across the hole; the middle one broken off.
		for r: int in 3:
			var zt: float = HOLE_Z + HOLE_RZ * (-0.55 + 0.55 * float(r)) + 0.1
			var rib := PackedVector3Array()
			var rad := PackedFloat32Array()
			var steps: int = 4 if r == 1 else 7
			for k: int in steps:
				var u: float = float(k) / 6.0
				var a: float = lerpf(HOLE_A - HOLE_RA * 1.2, HOLE_A + HOLE_RA * 1.2, u)
				rib.append(_on_body(zt - 0.2 * u, a * sx, 0.96 - 0.03 * sin(PI * u))[0])
				rad.append(lerpf(0.04, 0.026, u))
			if r == 1:
				rad[rad.size() - 1] = 0.0
			_tube(hide, rib, rad, 5)
		# Birch-bark marks (dark horizontal streaks) on the haunch, the barrel behind the hollow and the shoulder.
		var marks: Array = [[-0.82, 1.28, 0.22], [-0.64, 1.66, 0.28], [-0.46, 1.08, 0.2], [-0.34, 1.62, 0.2],
			[0.74, 1.62, 0.18], [-0.97, 1.55, 0.13]]
		for mk: Array in marks:
			var z: float = float(mk[0]) + (0.03 if sx > 0.0 else -0.02)
			var pn: Array = _on_body(z, float(mk[1]) * sx)
			_patch(bark, pn[0], pn[1], Vector3.BACK, float(mk[2]), 0.045, 0.004)
	# Moss shawl over the withers and the top of the neck root, lumpy.
	for mc: Array in [[0.60, 0.0, 0.34, 0.30], [0.42, 0.32, 0.26, 0.2], [0.42, -0.30, 0.26, 0.2], [0.78, 0.36, 0.2, 0.16],
			[0.78, -0.38, 0.2, 0.16], [0.26, 0.0, 0.2, 0.18], [-0.60, 0.12, 0.16, 0.12]]:
		var pn: Array = _on_body(float(mc[0]), float(mc[1]))
		_patch(moss, pn[0], pn[1], Vector3.BACK, float(mc[2]), float(mc[3]), 0.05, 7)
	# The heart and the root vines holding it (they vanish into the walls).
	_ellipsoid(heart, HEART, Vector3(0.15, 0.19, 0.15), 8, 5)
	for v: Array in [[-0.05, 0.16, -0.06], [0.06, -0.15, 0.03], [0.0, 0.02, 0.15]]:
		var dx: float = v[0]
		var sw: float = v[1]
		var dz: float = v[2]
		var p := PackedVector3Array([HEART + Vector3(dx, 0.42, dz), HEART + Vector3(dx + sw * 0.5, 0.2, dz),
			HEART + Vector3(sw, 0.0, dz * 0.6), HEART + Vector3(dx + sw * 0.6, -0.18, -dz * 0.4),
			HEART + Vector3(dx, -0.36, -dz)])
		_tube(bark, p, PackedFloat32Array([0.028, 0.024, 0.022, 0.024, 0.028]), 4)
	# Tail: a short pale wedge with a moss tuft.
	_tube(hide, PackedVector3Array([Vector3(0, 1.52, -1.0), Vector3(0, 1.44, -1.1), Vector3(0, 1.30, -1.14)]),
		PackedFloat32Array([0.075, 0.06, 0.0]), 5)
	_ellipsoid(moss, Vector3(0, 1.30, -1.15), Vector3(0.05, 0.08, 0.05), 5, 3)
	return _commit(KEY, [[hide, mat("hide")], [shade, mat("shade")], [bark, mat("bark")], [moss, mat("moss")],
		[hollow, mat("hollow")],
		[heart, mat("heart_glow")]])


# ================================================================ neck (Root/Mount/Head)

## The thick neck: pale, a moss crest along the top, a hanging moss beard under the throat, two birch marks.
static func neck_mesh() -> Mesh:
	const KEY := "neck_v1"
	if _meshes.has(KEY):
		return _meshes[KEY]
	var hide := _bucket()
	var bark := _bucket()
	var moss := _bucket()
	var n: int = NECK_C.size()
	_loft_patch(moss, NECK_C, NECK_RX, NECK_RY, 0, n - 1, _even(-0.55, 0.55, 2))
	_loft_patch(hide, NECK_C, NECK_RX, NECK_RY, 0, n - 1, _even(0.55, TAU - 0.55, 8))
	_disc(hide, NECK_C, NECK_RX, NECK_RY, 0, (NECK_C[0] - NECK_C[1]).normalized(), 0.04)
	# Beard: moss strands hanging from the throat, longest at the middle of the neck.
	for i: int in range(1, n):
		for sx: float in [-1.0, 1.0]:
			var a: float = PI + 0.7 * sx
			var p := _lp(NECK_C, NECK_RX, NECK_RY, i, a, 0.92)
			var ln: float = [0.0, 0.2, 0.26, 0.22, 0.15][i]
			_cone(moss, p, p + Vector3(0.05 * sx, -ln, -0.06), 0.06, 4)
		var pc := _lp(NECK_C, NECK_RX, NECK_RY, i, PI, 0.92)
		_cone(moss, pc, pc + Vector3(0, -[0.0, 0.22, 0.32, 0.28, 0.2][i], -0.06), 0.07, 4)
	for sx: float in [-1.0, 1.0]:
		for mk: Array in [[1, 1.3, 0.16], [3, 1.6, 0.12]]:
			var i: int = mk[0]
			var a: float = float(mk[1]) * sx
			_patch(bark, _lp(NECK_C, NECK_RX, NECK_RY, i, a), _ln(NECK_C, NECK_RX, NECK_RY, i, a),
				(NECK_C[i + 1] - NECK_C[i - 1]).normalized(), 0.045, float(mk[2]), 0.004)
	return _commit(KEY, [[hide, mat("hide")], [bark, mat("bark")], [moss, mat("moss")]])


# ================================================================ skull + antlers (Head/Crown/Skull, keep_separate)

## Skull, ears, hollow eye sockets, grey muzzle, the antlers of bare gnarled branches (dark bark) spreading wide over
## the head, with small GLOWING LEAVES at the twig tips. Local to SKULL_ORIGIN.
static func skull_mesh() -> Mesh:
	const KEY := "skull_v2"
	if _meshes.has(KEY):
		return _meshes[KEY]
	var hide := _bucket()
	var shade := _bucket()
	var bark := _bucket()
	var hollow := _bucket()
	var leaf := _bucket()
	var n: int = SKULL_C.size()
	_loft_patch(hide, SKULL_C, SKULL_RX, SKULL_RY, 0, 3, _even(0.0, TAU, 10))
	_loft_patch(shade, SKULL_C, SKULL_RX, SKULL_RY, 3, n - 1, _even(0.0, TAU, 10))
	_disc(hide, SKULL_C, SKULL_RX, SKULL_RY, 0, (SKULL_C[0] - SKULL_C[1]).normalized(), 0.05, 10)
	_disc(shade, SKULL_C, SKULL_RX, SKULL_RY, n - 1, (SKULL_C[n - 1] - SKULL_C[n - 2]).normalized(), 0.03, 10)
	_ellipsoid(bark, Vector3(0, 1.965, 1.60), Vector3(0.045, 0.03, 0.03), 6, 3)       # nose
	# The hollow dark eye sockets under dark brows.
	for sx: float in [-1.0, 1.0]:
		_ellipsoid(hollow, Vector3(0.115 * sx, 2.16, 1.24), Vector3(0.035, 0.034, 0.05), 6, 3)
		_ellipsoid(bark, Vector3(0.10 * sx, 2.205, 1.235), Vector3(0.05, 0.016, 0.045), 5, 2)
		# Ears: broad, out to the side and a little back, pale with a dark inner.
		var er := Basis(Vector3.BACK, -0.5 * sx) * Basis(Vector3.UP, 0.35 * sx)
		_ellipsoid(hide, Vector3(0.22 * sx, 2.25, 1.02), Vector3(0.13, 0.045, 0.05), 6, 3, er)
		_ellipsoid(shade, Vector3(0.22 * sx, 2.25, 1.045), Vector3(0.1, 0.03, 0.03), 5, 2, er)
		# Antler burr (bark knot) and the antler.
		_ellipsoid(bark, Vector3(0.085 * sx, 2.28, 1.08), Vector3(0.065, 0.05, 0.065), 6, 3)
		_antler(bark, leaf, sx, 23 if sx > 0.0 else 58)
	# Antlers a little squatter than grown (x0.85 above the burrs), so the crown stays wide rather than tall.
	for acc: Array in [bark, leaf]:
		var v: PackedVector3Array = acc[0]
		for i: int in v.size():
			if v[i].y > ANTLER_BASE_Y:
				v[i].y = ANTLER_BASE_Y + (v[i].y - ANTLER_BASE_Y) * 0.85
		acc[0] = v
	for acc: Array in [hide, shade, bark, hollow, leaf]:
		_shift(acc, SKULL_ORIGIN)
	return _commit(KEY, [[hide, mat("hide")], [shade, mat("shade")], [bark, mat("bark")], [hollow, mat("hollow")],
		[leaf, mat("leaf_glow")]])


## One antler (sx side): a gnarled main beam sweeping up and OUT (the crown ~1.2 m out from the skull, tips ~3.2 m
## high), five tines (brow tine forward, three up, one forward at the top), twigs off the tines, and small leaves
## in clusters at every tip. The template is the right side; sx mirrors it; the seed kinks each side differently.
static func _antler(bark: Array, leaf: Array, sx: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var m := Vector3(sx, 1.0, 1.0)
	var beam := PackedVector3Array([Vector3(0.09, 2.28, 1.08), Vector3(0.22, 2.44, 1.04), Vector3(0.42, 2.63, 0.98),
		Vector3(0.66, 2.80, 0.96), Vector3(0.90, 2.93, 1.02), Vector3(1.07, 3.02, 1.12), Vector3(1.17, 3.08, 1.24)])
	var br := PackedFloat32Array([0.062, 0.056, 0.049, 0.042, 0.035, 0.028, 0.02])
	for i: int in beam.size():
		var j := Vector3.ZERO if i == 0 else _jit(rng, 0.03)
		beam[i] = (beam[i] + j) * m
	_tube(bark, beam, br, 5)
	# Tines: [beam point index, offsets from it (template, right side)].
	var tines: Array = [
		[1, [Vector3(0.07, 0.07, 0.2), Vector3(0.12, 0.2, 0.37)]],
		[2, [Vector3(0.02, 0.2, -0.03), Vector3(0.07, 0.37, -0.06), Vector3(0.11, 0.47, -0.02)]],
		[3, [Vector3(0.05, 0.2, -0.1), Vector3(0.13, 0.38, -0.16)]],
		[4, [Vector3(0.11, 0.15, 0.0), Vector3(0.21, 0.25, 0.04)]],
		[4, [Vector3(0.07, 0.05, 0.22), Vector3(0.12, 0.12, 0.38)]],
	]
	var tips: Array = []   # [point, direction]
	for tn: Array in tines:
		var bi: int = tn[0]
		var pts := PackedVector3Array([beam[bi]])
		var rad := PackedFloat32Array([br[bi] * 0.78])
		var offs: Array = tn[1]
		for k: int in offs.size():
			pts.append(beam[bi] + ((offs[k] as Vector3) + _jit(rng, 0.025)) * m)
			rad.append(br[bi] * 0.78 * (1.0 - float(k + 1) / float(offs.size() + 1)) + 0.008)
		rad[rad.size() - 1] = 0.0
		_tube(bark, pts, rad, 4)
		var tip: Vector3 = pts[pts.size() - 1]
		tips.append([tip, (tip - pts[pts.size() - 2]).normalized()])
		# One twig from the middle of the tine.
		var p0: Vector3 = pts[1] if pts.size() > 2 else pts[0].lerp(pts[1], 0.6)
		var dir := ((tip - pts[0]).normalized() + _jit(rng, 1.0) + Vector3(0.35 * sx, 0.35, 0.0)).normalized()
		var tl := rng.randf_range(0.16, 0.26)
		var tw := PackedVector3Array([p0, p0 + dir * tl * 0.55 + _jit(rng, 0.02), p0 + dir * tl])
		_tube(bark, tw, PackedFloat32Array([0.018, 0.012, 0.0]), 4)
		tips.append([tw[2], dir])
	# Two twigs forking off the beam end.
	var end_dir := (beam[6] - beam[5]).normalized()
	for k: int in 2:
		var dir := (end_dir + Vector3(0.0, 0.5 if k == 0 else -0.1, -0.35 if k == 0 else 0.45)).normalized()
		var e := PackedVector3Array([beam[6], beam[6] + dir * 0.12 + _jit(rng, 0.02), beam[6] + dir * 0.22])
		_tube(bark, e, PackedFloat32Array([0.018, 0.012, 0.0]), 4)
		tips.append([e[2], dir])
	# Leaves: a small cluster at every tip (2 at twig ends, 3 at tines), a few along the beam.
	for i: int in tips.size():
		var p: Vector3 = tips[i][0]
		var d: Vector3 = tips[i][1]
		var cnt: int = 3 if i % 2 == 0 else 2
		for k: int in cnt:
			var along := (d + _jit(rng, 1.1)).normalized()
			var nn := along.cross(_jit(rng, 1.0) + Vector3.UP * 0.5).normalized()
			var ln := rng.randf_range(0.12, 0.17)
			_leaf(leaf, p + along * ln * 0.45 + _jit(rng, 0.03), along, nn, ln, ln * 0.6)
	for bi: int in [2, 3, 5]:
		var along := (Vector3(0.0, 1.0, 0.0) + _jit(rng, 0.8)).normalized()
		var nn := along.cross(Vector3.BACK + _jit(rng, 0.5)).normalized()
		_leaf(leaf, beam[bi] + Vector3(0, 0.05, 0) + along * 0.06, along, nn, 0.13, 0.08)


static func _jit(rng: RandomNumberGenerator, a: float) -> Vector3:
	return Vector3(rng.randf_range(-a, a), rng.randf_range(-a, a), rng.randf_range(-a, a))


# ================================================================ legs

## Upper leg (model space; merged into the leg pivot): front = shoulder blade + upper arm + forearm to the knee; hind =
## the big haunch + thigh + gaskin to the hock. Pale with a birch mark.
static func upper_leg_mesh(front: bool, sx: float) -> Mesh:
	var key := "upper_v1_%s_%s" % [front, sx]
	if _meshes.has(key):
		return _meshes[key]
	var hide := _bucket()
	var bark := _bucket()
	var m := Vector3(sx, 1.0, 1.0)
	if front:
		_ellipsoid(hide, Vector3(0.22, 1.36, 0.66) * m, Vector3(0.11, 0.25, 0.14), 7, 4, Basis(Vector3.RIGHT, 0.25))
		var p := PackedVector3Array([Vector3(0.25, 1.30, 0.64), Vector3(0.265, 1.02, 0.57), Vector3(0.255, 0.78, 0.60),
			KNEE_F + Vector3(0, 0.02, 0)])
		for i: int in p.size():
			p[i] *= m
		_tube(hide, p, PackedFloat32Array([0.13, 0.11, 0.085, 0.07]), 7)
		_ellipsoid(hide, Vector3(0.265, 1.0, 0.56) * m, Vector3(0.1, 0.1, 0.1), 6, 3)
		_patch(bark, Vector3(0.352, 0.86, 0.585) * m, Vector3(sx, 0, 0.1).normalized(), Vector3.BACK, 0.12, 0.035, 0.003)
	else:
		_ellipsoid(hide, Vector3(0.2, 1.22, -0.72) * m, Vector3(0.15, 0.3, 0.26), 7, 4)
		var p := PackedVector3Array([Vector3(0.22, 1.22, -0.70), Vector3(0.25, 0.98, -0.57), Vector3(0.24, 0.80, -0.72),
			HOCK_B + Vector3(0, 0.02, 0.01)])
		for i: int in p.size():
			p[i] *= m
		_tube(hide, p, PackedFloat32Array([0.15, 0.12, 0.085, 0.066]), 7)
		_patch(bark, Vector3(0.352, 1.16, -0.66) * m, Vector3(sx, 0, 0).normalized(), Vector3.BACK, 0.2, 0.04, 0.003)
		_patch(bark, Vector3(0.338, 0.84, -0.7) * m, Vector3(sx, 0, 0.2).normalized(), Vector3.BACK, 0.12, 0.03, 0.003)
	return _commit(key, [[hide, mat("hide")], [bark, mat("bark")]])


## Lower leg (keep_separate "Lower/Shin", local to the knee / hock): grey cannon, fetlock, a moss tuft behind the
## fetlock, the dark cloven hoof. Folds back at the joint in the stride.
static func lower_leg_mesh(front: bool, sx: float) -> Mesh:
	var key := "lower_v1_%s_%s" % [front, sx]
	if _meshes.has(key):
		return _meshes[key]
	var shade := _bucket()
	var bark := _bucket()
	var moss := _bucket()
	var j: Vector3 = KNEE_F if front else HOCK_B
	var z0: float = j.z
	var zf: float = z0 + (0.02 if front else 0.08)
	var fet := Vector3(j.x, 0.15, zf)
	var hoof := Vector3(j.x, 0.05, zf + 0.06)
	var p := PackedVector3Array([j, Vector3(j.x, lerpf(j.y, 0.15, 0.5), lerpf(z0, zf, 0.5)), fet, hoof + Vector3(0, 0.03, -0.01)])
	var m := Vector3(sx, 1.0, 1.0)
	for i: int in p.size():
		p[i] *= m
	_tube(shade, p, PackedFloat32Array([0.066, 0.052, 0.05, 0.045]), 6)
	_ellipsoid(shade, j * m, Vector3(0.075, 0.075, 0.08), 6, 3)
	_ellipsoid(shade, fet * m, Vector3(0.058, 0.06, 0.066), 6, 3)
	_cone(moss, (fet + Vector3(0, 0.03, -0.04)) * m, (fet + Vector3(0.0, -0.1, -0.13)) * m, 0.05, 4)
	for c: float in [-1.0, 1.0]:
		_ellipsoid(bark, (hoof + Vector3(0.03 * c, 0.0, 0.0)) * m, Vector3(0.036, 0.05, 0.072), 6, 3)
	for acc: Array in [shade, bark, moss]:
		_shift(acc, j * m)
	return _commit(key, [[shade, mat("shade")], [bark, mat("bark")], [moss, mat("moss")]])
