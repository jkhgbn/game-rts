extends RefCounted
## Direwolf meshes (task 12.V29): static builders used by direwolf.gd only. One mesh per part AND variant (0 = Greymane,
## 1 = Moonpelt), each built once per game and cached. Model space (paws at y 0, face toward +Z): every part is a
## keep_separate MeshInstance3D added at its pivot with add_part(pivot, mesh, null, Vector3.ZERO, ...), so the
## model-space vertices land in place and the variant swap is a plain `mesh =` on the same node. Deterministic: the fur
## locks use fixed RNG seeds.
## Materials (materials/, painted = kit unit_painted, glow = kit unit_glow), per variant (_a / _b): fur (the coat),
## mane (A: the dark shaggy mane, saddle, brows, tail tip; B: the blue-silver saddle streak and tail tip), pale (belly,
## throat, muzzle, lower legs), eye (A: painted amber; B: the faint pale-blue glow); shared: dark (nose, claws, lips),
## mouth (tongue, gums), teeth.
## Shapes: B (Moonpelt) is leaner (body x0.86 wide, belly tucked, legs / neck / tail thinner), with a small sleek ruff
## instead of A's big shaggy mane (MANE factor).

const DIR := "res://art/units/neutral/beasts/direwolf/materials/direwolf_"
const DEG := PI / 180.0
const SUFFIX: Array[String] = ["_a", "_b"]

# ---- pivots (model space; the .tscn uses the same numbers). Legs: x mirrored by side (sx -1 = left / FL / BL).
const HEAD_PIVOT := Vector3(0.0, 1.20, 0.52)     # neck base (Root/Mount/Head)
const SKULL_PIVOT := Vector3(0.0, 1.46, 0.90)    # poll (Head/Skull)
const JAW_PIVOT := Vector3(0.0, 1.39, 0.98)      # jaw hinge (Skull/Jaw)
const TAIL_PIVOT := Vector3(0.0, 1.21, -0.96)    # tail root (Mount/Tail)
const LEG_F := Vector3(0.19, 1.16, 0.44)         # shoulder (LegFL / LegFR)
const LEG_B := Vector3(0.18, 1.12, -0.70)        # hip (LegBL / LegBR)
const WRIST_F := Vector3(0.19, 0.37, 0.50)       # front wrist (carpus): the Lower joint
const HOCK_B := Vector3(0.19, 0.45, -0.86)       # hind hock: the Lower joint
const EYE := Vector3(0.108, 1.532, 1.10)         # eye centre (right side)

# ---- variant shape factors [A Greymane, B Moonpelt]
const BODY_W: Array[float] = [1.1, 0.95]
const BELLY: Array[float] = [1.0, 0.92]
const LEG_W: Array[float] = [1.3, 1.12]
const NECK_W: Array[float] = [1.0, 0.86]
const HEAD_W: Array[float] = [1.12, 1.02]
const MANE: Array[float] = [1.0, 0.36]
const TAIL_W: Array[float] = [1.0, 0.72]

# Body loft rump -> chest: [z, centre y, half-width, half-height]. Withers ~1.45 m, deep chest (belly 0.78), tucked
# waist (belly 0.94), strong haunch.
const BODY: Array = [[-1.00, 1.13, 0.09, 0.10], [-0.93, 1.14, 0.19, 0.19], [-0.80, 1.15, 0.24, 0.23],
	[-0.62, 1.15, 0.235, 0.22], [-0.42, 1.13, 0.20, 0.19], [-0.22, 1.12, 0.22, 0.24], [-0.02, 1.11, 0.265, 0.30],
	[0.18, 1.11, 0.285, 0.335], [0.38, 1.12, 0.285, 0.33], [0.56, 1.13, 0.25, 0.29], [0.70, 1.12, 0.18, 0.21],
	[0.78, 1.10, 0.09, 0.11]]
# Neck loft base (inside the chest) -> poll.
const NECK_C: Array[Vector3] = [Vector3(0, 1.14, 0.46), Vector3(0, 1.24, 0.62), Vector3(0, 1.33, 0.76),
	Vector3(0, 1.41, 0.87), Vector3(0, 1.46, 0.94)]
const NECK_RX: Array[float] = [0.22, 0.19, 0.16, 0.135, 0.12]
const NECK_RY: Array[float] = [0.26, 0.22, 0.18, 0.15, 0.13]
# Skull loft poll -> nose: broad cranium and cheeks, a clear stop, a long tapering muzzle.
const SKULL_C: Array[Vector3] = [Vector3(0, 1.47, 0.86), Vector3(0, 1.50, 0.95), Vector3(0, 1.49, 1.06),
	Vector3(0, 1.455, 1.16), Vector3(0, 1.43, 1.27), Vector3(0, 1.41, 1.38), Vector3(0, 1.40, 1.45)]
const SKULL_RX: Array[float] = [0.11, 0.16, 0.155, 0.11, 0.085, 0.07, 0.055]
const SKULL_RY: Array[float] = [0.11, 0.14, 0.13, 0.095, 0.075, 0.062, 0.05]
# Lower jaw loft hinge -> chin (overlaps the upper muzzle a little when closed).
const JAW_C: Array[Vector3] = [Vector3(0, 1.39, 0.98), Vector3(0, 1.37, 1.10), Vector3(0, 1.345, 1.24),
	Vector3(0, 1.33, 1.36), Vector3(0, 1.325, 1.42)]
const JAW_RX: Array[float] = [0.10, 0.10, 0.075, 0.06, 0.045]
const JAW_RY: Array[float] = [0.06, 0.055, 0.045, 0.038, 0.03]

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}


## Material by name: variant >= 0 appends _a / _b (fur, mane, pale, eye); -1 = shared (dark, mouth, teeth).
static func mat(name: String, v: int = -1) -> Material:
	var path := DIR + name + ("" if v < 0 else SUFFIX[clampi(v, 0, 1)]) + ".tres"
	if not _mats.has(path):
		_mats[path] = load(path)
	return _mats[path]


## The mesh of part `key` (body, neck, skull, jaw, tail, upper, lower) for variant v (legs: front / side sx).
static func part(key: String, v: int, front: bool = false, sx: float = 1.0) -> Mesh:
	match key:
		"body":
			return body_mesh(v)
		"neck":
			return neck_mesh(v)
		"skull":
			return skull_mesh(v)
		"jaw":
			return jaw_mesh(v)
		"tail":
			return tail_mesh(v)
		"upper":
			return upper_leg_mesh(front, sx, v)
		"lower":
			return lower_leg_mesh(front, sx, v)
	return null


# ================================================================ geometry helpers (as hollow_stag_mesh.gd)

static func _bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## A (cols+1) x (rows+1) grid of points (row-major) with given normals; each triangle is wound so its front faces its
## normals; degenerate triangles (cone tips, fans) are skipped.
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


## One flat triangle facing n (both windings handled like _grid).
static func _tri(acc: Array, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var b0: int = (acc[0] as PackedVector3Array).size()
	var nn := n.normalized()
	for p: Vector3 in [a, b, c]:
		acc[0].append(p)
		acc[1].append(nn)
		acc[2].append(Vector2.ZERO)
	var front := -(b - a).cross(c - a)
	if front.dot(nn) < 0.0:
		acc[3].append_array(PackedInt32Array([b0, b0 + 2, b0 + 1]))
	else:
		acc[3].append_array(PackedInt32Array([b0, b0 + 1, b0 + 2]))


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


## Point of a loft at station i, angle a (0 = top, PI/2 = +x side, PI = bottom). Stations run toward +Z / up-forward.
static func _lp(c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, a: float, inflate: float = 1.0) -> Vector3:
	var n := c.size()
	i = clampi(i, 0, n - 1)
	var t := (c[mini(i + 1, n - 1)] - c[maxi(i - 1, 0)]).normalized()
	var up := t.cross(Vector3.RIGHT).normalized()
	return c[i] + Vector3.RIGHT * sin(a) * rx[i] * inflate + up * cos(a) * ry[i] * inflate


## Outward normal of a loft at station i, angle a.
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


## Loft point / normal at a fractional station f (linear between stations): [point, normal].
static func _lpf(c: Array[Vector3], rx: Array[float], ry: Array[float], f: float, a: float, inflate: float = 1.0) -> Array:
	var i0 := clampi(int(floor(f)), 0, c.size() - 1)
	var i1 := mini(i0 + 1, c.size() - 1)
	var u := clampf(f - float(i0), 0.0, 1.0)
	var p := _lp(c, rx, ry, i0, a, inflate).lerp(_lp(c, rx, ry, i1, a, inflate), u)
	var nn := _ln(c, rx, ry, i0, a).lerp(_ln(c, rx, ry, i1, a), u).normalized()
	return [p, nn]


## A patch of a loft: stations i0..i1, the same angle list at every station; `inflate` scales the radii.
static func _loft_patch(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i0: int, i1: int,
		angs: PackedFloat32Array, inflate: float = 1.0) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for i: int in range(i0, i1 + 1):
		for a: float in angs:
			pts.append(_lp(c, rx, ry, i, a, inflate))
			nrm.append(_ln(c, rx, ry, i, a))
	_grid(acc, pts, nrm, angs.size() - 1, i1 - i0)


## A fan closing a loft at station i, all normals = n (the tip pushed along n by bulge).
static func _disc(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, n: Vector3,
		bulge: float, ring: int = 12, inflate: float = 1.0) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in ring + 1:
			var a := TAU * float(k) / float(ring)
			pts.append(_lp(c, rx, ry, i, a, inflate) if row == 0 else c[i] + n * bulge)
			nrm.append(n)
	_grid(acc, pts, nrm, ring, 1)


static func _even(a0: float, a1: float, steps: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k: int in steps + 1:
		out.append(lerpf(a0, a1, float(k) / float(steps)))
	return out


## Smooth tube through pts (radii per point, 0 = a point), `seg` sides; parallel-transported frames.
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


## A small open cone (fur lock, claw, fang): `sides` faces from a ring at `base` to `tip`. `flat` < 1 squashes the
## ring along `flat_axis` (a flat lock of fur rather than a spike).
static func _cone(acc: Array, base: Vector3, tip: Vector3, r: float, sides: int = 4, flat: float = 1.0,
		flat_axis: Vector3 = Vector3.ZERO) -> void:
	var d := tip - base
	var ln := d.length()
	if ln < 0.0001:
		return
	var t := d / ln
	var s: Vector3
	if flat_axis != Vector3.ZERO and absf(flat_axis.normalized().dot(t)) < 0.95:
		s = (flat_axis - t * flat_axis.dot(t)).normalized()
	else:
		var ref := Vector3.RIGHT if absf(t.dot(Vector3.RIGHT)) < 0.8 else Vector3.FORWARD
		s = t.cross(ref).normalized()
	var u := s.cross(t).normalized()
	var slope := r / ln
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in sides + 1:
			var a := TAU * float(k) / float(sides)
			var dir := s * cos(a) * flat + u * sin(a)
			pts.append(base + dir * r if row == 0 else tip)
			nrm.append((s * cos(a) + u * sin(a) + t * slope).normalized())
	_grid(acc, pts, nrm, sides, 1)


## A shaggy fur lock growing from surface point p (outward normal n) toward dir: a flattened 5-sided cone whose base
## sinks into the surface, `length` long, `r` wide; flattened along n (lies on the coat like a tuft).
static func _lock(acc: Array, p: Vector3, n: Vector3, dir: Vector3, length: float, r: float) -> void:
	var d := dir.normalized()
	_cone(acc, p - n * r * 0.45, p + d * length, r, 5, 0.55, n)


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


static func _jit(rng: RandomNumberGenerator, a: float) -> Vector3:
	return Vector3(rng.randf_range(-a, a), rng.randf_range(-a, a), rng.randf_range(-a, a))


## Scaled copies of a loft's radii.
static func _scaled(src: Array[float], k: float) -> Array[float]:
	var out: Array[float] = []
	for v: float in src:
		out.append(v * k)
	return out


# ================================================================ body (Root/Mount)

## The body loft of variant v: [centres, half-widths, half-heights]; B is narrower with a more tucked belly (the back
## line stays where it is).
static func body_loft(v: int) -> Array:
	var c: Array[Vector3] = []
	var rx: Array[float] = []
	var ry: Array[float] = []
	for s: Array in BODY:
		var ryv: float = float(s[3]) * BELLY[v]
		c.append(Vector3(0.0, float(s[1]) + float(s[3]) - ryv, float(s[0])))
		rx.append(float(s[2]) * BODY_W[v])
		ry.append(ryv)
	return [c, rx, ry]


## The barrel: a dark saddle down the back (A charcoal, B blue-silver), grey / silver flanks, a pale belly and chest.
## A: a SHAGGY HUMP of long raked locks over the withers, a hackle crest down the spine and a fringe under the chest.
## B: only a few short sleek locks at the withers.
static func body_mesh(v: int) -> Mesh:
	var key := "body_%d" % v
	if _meshes.has(key):
		return _meshes[key]
	var fur := _bucket()
	var mane := _bucket()
	var pale := _bucket()
	var bl := body_loft(v)
	var c: Array[Vector3] = bl[0]
	var rx: Array[float] = bl[1]
	var ry: Array[float] = bl[2]
	var n := c.size()
	_loft_patch(mane, c, rx, ry, 0, n - 1, _even(-0.7, 0.7, 4))
	_loft_patch(fur, c, rx, ry, 0, n - 1, _even(0.7, 2.25, 5))
	_loft_patch(fur, c, rx, ry, 0, n - 1, _even(-2.25, -0.7, 5))
	_loft_patch(pale, c, rx, ry, 0, n - 1, _even(2.25, TAU - 2.25, 5))
	_disc(fur, c, rx, ry, 0, Vector3.FORWARD, 0.05, 12)
	_disc(pale, c, rx, ry, n - 1, Vector3.BACK, 0.04, 12)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301 + v * 17
	var m: float = MANE[v]
	var back := Vector3(0.0, 0.3, -1.0)
	if m > 0.5:
		# Withers hump: rings of long locks raked back and up over the shoulders (the mane continues the neck's).
		for f: float in [7.2, 7.8, 8.4, 9.0, 9.5]:
			for a: float in [-1.25, -0.8, -0.35, 0.1, 0.55, 1.0]:
				var aa := a + rng.randf_range(-0.12, 0.12)
				var sp: Array = _lpf(c, rx, ry, f, aa)
				var nn: Vector3 = sp[1]
				var ln := (0.34 - 0.07 * absf(aa) - 0.03 * (9.5 - f)) * rng.randf_range(0.85, 1.12)
				_lock(mane, sp[0], nn, nn * 0.6 + back * 0.8 + _jit(rng, 0.15), ln, 0.11)
		# Hackle crest down the spine, shrinking toward the rump.
		for k: int in 7:
			var f := 6.8 - float(k) * 0.55
			var sp: Array = _lpf(c, rx, ry, f, rng.randf_range(-0.2, 0.2))
			var nn: Vector3 = sp[1]
			_lock(mane, sp[0], nn, nn * 0.7 + back * 0.7, lerpf(0.26, 0.1, float(k) / 6.0), 0.085)
		# A shaggy fringe under the chest (pale), hanging down and back.
		for f: float in [6.3, 7.0, 7.7, 8.4]:
			for a: float in [PI - 0.45, PI, PI + 0.45]:
				var sp: Array = _lpf(c, rx, ry, f, a + rng.randf_range(-0.1, 0.1))
				var nn: Vector3 = sp[1]
				_lock(pale, sp[0], nn, Vector3(0.0, -1.0, -0.45) + _jit(rng, 0.2), rng.randf_range(0.13, 0.19), 0.075)
	else:
		# Moonpelt: a few short sleek locks at the withers and a faint chest fringe.
		for f: float in [8.0, 8.8]:
			for a: float in [-0.7, 0.0, 0.7]:
				var sp: Array = _lpf(c, rx, ry, f, a + rng.randf_range(-0.1, 0.1))
				var nn: Vector3 = sp[1]
				_lock(fur, sp[0], nn, nn * 0.4 + back, 0.13, 0.07)
		for f: float in [7.0, 8.0]:
			var sp: Array = _lpf(c, rx, ry, f, PI)
			_lock(pale, sp[0], sp[1], Vector3(0.0, -1.0, -0.5), 0.08, 0.06)
	return _commit(key, [[fur, mat("fur", v)], [mane, mat("mane", v)], [pale, mat("pale", v)]])


# ================================================================ neck (Root/Mount/Head)

## The neck: coat on top and sides, pale throat. A: the GREY MANE, a thick shaggy ruff all round the neck (a solid
## under-layer + four rings of long locks raked back, longest on top: the hump reads at 40 m). B: a slim pale collar.
static func neck_mesh(v: int) -> Mesh:
	var key := "neck_%d" % v
	if _meshes.has(key):
		return _meshes[key]
	var fur := _bucket()
	var mane := _bucket()
	var pale := _bucket()
	var rx: Array[float] = _scaled(NECK_RX, NECK_W[v])
	var ry: Array[float] = _scaled(NECK_RY, NECK_W[v])
	var n := NECK_C.size()
	_loft_patch(fur, NECK_C, rx, ry, 0, n - 1, _even(-2.1, 2.1, 8))
	_loft_patch(pale, NECK_C, rx, ry, 0, n - 1, _even(2.1, TAU - 2.1, 4))
	var m: float = MANE[v]
	var ruff: Array = mane if m > 0.5 else pale
	var back := (NECK_C[0] - NECK_C[n - 1]).normalized()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5519 + v * 31
	# Under-layer: the neck inflated (so the locks never show gaps), stations 0..3.
	var infl := 1.0 + 0.36 * m
	_loft_patch(ruff, NECK_C, rx, ry, 0, 3, _even(0.0, TAU, 12), infl)
	_disc(ruff, NECK_C, rx, ry, 3, (NECK_C[4] - NECK_C[2]).normalized(), 0.0, 12, infl)
	var rings: Array = [0.35, 1.05, 1.75, 2.45] if m > 0.5 else [1.2, 2.2]
	var per: int = 11 if m > 0.5 else 7
	for ri: int in rings.size():
		var f: float = rings[ri]
		for k: int in per:
			var a := TAU * (float(k) + 0.5 * float(ri % 2)) / float(per) + rng.randf_range(-0.12, 0.12)
			var sp: Array = _lpf(NECK_C, rx, ry, f, a, infl * 0.95)
			var nn: Vector3 = sp[1]
			var top: float = 0.5 + 0.5 * cos(a)            # 1 on top, 0 under the throat
			var ln: float = (0.24 + 0.14 * top) * (1.0 - 0.18 * f / 2.45) * rng.randf_range(0.88, 1.12)
			var dir := nn * 0.62 + back * 0.78 + Vector3(0.0, 0.18 * top - 0.25 * (1.0 - top), 0.0) + _jit(rng, 0.12)
			_lock(ruff, sp[0], nn, dir, ln * m if m < 0.5 else ln, 0.12 if m > 0.5 else 0.07)
	return _commit(key, [[fur, mat("fur", v)], [mane, mat("mane", v)], [pale, mat("pale", v)]])


# ================================================================ skull (Head/Skull)

## Cranium and upper muzzle: coat on top, pale cheeks and muzzle sides, the roof of the mouth underneath (hidden by the
## jaw when closed); black nose; brow ridges; tall pointed ears; almond eyes (A painted amber, B glowing pale blue);
## cheek ruff locks (A shaggy, B short); the upper fangs, whose tips show below the lip.
static func skull_mesh(v: int) -> Mesh:
	var key := "skull_%d" % v
	if _meshes.has(key):
		return _meshes[key]
	var fur := _bucket()
	var mane := _bucket()
	var pale := _bucket()
	var dark := _bucket()
	var mouth := _bucket()
	var teeth := _bucket()
	var eye := _bucket()
	var rx: Array[float] = _scaled(SKULL_RX, HEAD_W[v])
	var ry: Array[float] = SKULL_RY
	var n := SKULL_C.size()
	_loft_patch(fur, SKULL_C, rx, ry, 0, 3, _even(-1.9, 1.9, 6))
	_loft_patch(pale, SKULL_C, rx, ry, 0, 3, _even(1.9, TAU - 1.9, 5))
	_loft_patch(fur, SKULL_C, rx, ry, 3, n - 1, _even(-1.2, 1.2, 4))
	_loft_patch(pale, SKULL_C, rx, ry, 3, n - 1, _even(1.2, PI - 0.6, 3))
	_loft_patch(mouth, SKULL_C, rx, ry, 3, n - 1, _even(PI - 0.6, PI + 0.6, 2))
	_loft_patch(pale, SKULL_C, rx, ry, 3, n - 1, _even(PI + 0.6, TAU - 1.2, 3))
	_disc(fur, SKULL_C, rx, ry, 0, (SKULL_C[0] - SKULL_C[1]).normalized(), 0.04, 10)
	_disc(dark, SKULL_C, rx, ry, n - 1, (SKULL_C[n - 1] - SKULL_C[n - 2]).normalized(), 0.02, 10)
	# Nose: a big black button at the tip of the muzzle.
	_ellipsoid(dark, Vector3(0.0, 1.438, 1.448), Vector3(0.052, 0.04, 0.04), 7, 4)
	var hw: float = HEAD_W[v]
	for sx: float in [-1.0, 1.0]:
		var mx := Vector3(sx, 1.0, 1.0)
		# (the almond eyes and the brow ridge: the direwolf's CreatureFaceRig, faces pass 2026-09-28)
		# Dark lip line along the muzzle side.
		var lip := PackedVector3Array()
		var lr := PackedFloat32Array()
		for i: int in range(3, n):
			lip.append(_lp(SKULL_C, rx, ry, i, (PI - 0.72) * sx, 1.02))
			lr.append(0.012)
		_tube(dark, lip, lr, 4)
		# Ears: tall pointed wedges, the back in the coat, the inner face pale, a dark rim at the tip.
		var eb := Vector3(0.098 * hw * sx, 1.585, 0.925)
		var tip := Vector3(0.15 * hw * sx, 1.84, 0.87)
		var side := Vector3(0.068 * sx, 0.0, 0.012)
		var bk := Vector3(0.0, -0.01, -0.07)
		var inner_n := Vector3(0.25 * sx, 0.15, 1.0)
		_tri(pale, eb - side, eb + side, tip, inner_n)
		_tri(fur, eb - side, eb + bk, tip, Vector3(-0.9 * sx, 0.2, -0.6))
		_tri(fur, eb + bk, eb + side, tip, Vector3(0.9 * sx, 0.2, -0.6))
		_tri(fur, eb - side, eb + side, eb + bk, Vector3.DOWN)
		_cone(mane, tip.lerp(eb, 0.28) + Vector3(0, 0, -0.01), tip + Vector3(0, 0.015, 0), 0.03, 3)
		# Cheek ruff: locks sweeping out, back and down from the cheeks (the face reads wide).
		var rng := RandomNumberGenerator.new()
		rng.seed = 991 + v * 7 + int(sx + 1.0)
		var m: float = MANE[v]
		var cnt: int = 4 if m > 0.5 else 2
		for k: int in cnt:
			var sp: Array = _lpf(SKULL_C, rx, ry, 1.1 + 0.35 * float(k % 2), (1.75 + 0.3 * float(k)) * sx)
			var nn: Vector3 = sp[1]
			var ln: float = (0.2 if m > 0.5 else 0.1) * rng.randf_range(0.85, 1.1)
			_lock(fur if k % 2 == 0 else pale, sp[0], nn, nn + Vector3(0.0, -0.35, -0.8), ln, 0.075 if m > 0.5 else 0.055)
		# Upper fang: its tip shows below the lip even with the jaws shut.
		_cone(teeth, Vector3(0.048 * hw * sx, 1.375, 1.345), Vector3(0.046 * hw * sx, 1.318, 1.36), 0.017, 5)
		_cone(teeth, Vector3(0.05 * hw * sx, 1.378, 1.23), Vector3(0.05 * hw * sx, 1.345, 1.235), 0.011, 4)
	return _commit(key, [[fur, mat("fur", v)], [mane, mat("mane", v)], [pale, mat("pale", v)], [dark, mat("dark")],
		[mouth, mat("mouth")], [teeth, mat("teeth")], [eye, mat("eye", v)]])


# ================================================================ jaw (Skull/Jaw)

## Lower jaw: pale chin and sides, the tongue and gums on top (seen when it opens), the lower fangs, a dark lip line.
static func jaw_mesh(v: int) -> Mesh:
	var key := "jaw_%d" % v
	if _meshes.has(key):
		return _meshes[key]
	var pale := _bucket()
	var dark := _bucket()
	var mouth := _bucket()
	var teeth := _bucket()
	var rx: Array[float] = _scaled(JAW_RX, HEAD_W[v])
	var n := JAW_C.size()
	_loft_patch(mouth, JAW_C, rx, JAW_RY, 0, n - 1, _even(-0.9, 0.9, 3))
	_loft_patch(pale, JAW_C, rx, JAW_RY, 0, n - 1, _even(0.9, TAU - 0.9, 8))
	_disc(pale, JAW_C, rx, JAW_RY, 0, (JAW_C[0] - JAW_C[1]).normalized(), 0.02, 10)
	_disc(pale, JAW_C, rx, JAW_RY, n - 1, (JAW_C[n - 1] - JAW_C[n - 2]).normalized(), 0.025, 10)
	# Tongue lying in the jaw.
	_ellipsoid(mouth, Vector3(0.0, 1.372, 1.2), Vector3(0.05 * HEAD_W[v], 0.018, 0.15), 7, 3)
	for sx: float in [-1.0, 1.0]:
		var lip := PackedVector3Array()
		var lr := PackedFloat32Array()
		for i: int in range(1, n):
			lip.append(_lp(JAW_C, rx, JAW_RY, i, 0.95 * sx, 1.02))
			lr.append(0.011)
		_tube(dark, lip, lr, 4)
		var hw: float = HEAD_W[v]
		_cone(teeth, Vector3(0.042 * hw * sx, 1.35, 1.365), Vector3(0.044 * hw * sx, 1.405, 1.352), 0.015, 5)
		_cone(teeth, Vector3(0.05 * hw * sx, 1.36, 1.22), Vector3(0.05 * hw * sx, 1.392, 1.218), 0.01, 4)
	return _commit(key, [[pale, mat("pale", v)], [dark, mat("dark")], [mouth, mat("mouth")], [teeth, mat("teeth")]])


# ================================================================ tail (Mount/Tail)

## The brush: hangs down and back in a curve. A: big and bushy with shaggy locks and a dark tip; B: a slimmer plume
## with a blue-silver tip.
static func tail_mesh(v: int) -> Mesh:
	var key := "tail_%d" % v
	if _meshes.has(key):
		return _meshes[key]
	var fur := _bucket()
	var mane := _bucket()
	var k: float = TAIL_W[v]
	var p := PackedVector3Array([Vector3(0, 1.21, -0.96), Vector3(0, 1.13, -1.10), Vector3(0, 0.97, -1.24),
		Vector3(0, 0.77, -1.32), Vector3(0, 0.60, -1.34)])
	var r := PackedFloat32Array([0.07 * k, 0.125 * k, 0.15 * k, 0.14 * k, 0.105 * k])
	_tube(fur, p, r, 8)
	var tip := PackedVector3Array([Vector3(0, 0.66, -1.34), Vector3(0, 0.58, -1.34), Vector3(0, 0.49, -1.32),
		Vector3(0, 0.44, -1.30)])
	_tube(mane, tip, PackedFloat32Array([0.132 * k, 0.118 * k, 0.07 * k, 0.0]), 8)
	if MANE[v] > 0.5:
		var rng := RandomNumberGenerator.new()
		rng.seed = 313
		for i: int in 8:
			var u := 0.25 + 0.09 * float(i)
			var seg := clampi(int(u * 4.0), 0, 3)
			var w := u * 4.0 - float(seg)
			var c := p[seg].lerp(p[seg + 1], w)
			var side := (1.0 if i % 2 == 0 else -1.0)
			var nn := Vector3(side * 0.8, -0.2, -0.5).normalized()
			_lock(fur, c + nn * 0.1, nn, nn * 0.5 + Vector3(0, -1.0, -0.3) + _jit(rng, 0.2), 0.18, 0.08)
	return _commit(key, [[fur, mat("fur", v)], [mane, mat("mane", v)]])


# ================================================================ legs

## Upper leg (LegXX/Thigh): front = shoulder blade + upper arm + forearm to the wrist; hind = the big haunch + thigh +
## gaskin to the hock. Coat above, pale below; A adds an elbow tuft / shaggy "britches" behind the thigh.
static func upper_leg_mesh(front: bool, sx: float, v: int) -> Mesh:
	var key := "upper_%s_%s_%d" % [front, sx, v]
	if _meshes.has(key):
		return _meshes[key]
	var fur := _bucket()
	var pale := _bucket()
	var m := Vector3(sx, 1.0, 1.0)
	var w: float = LEG_W[v]
	var shaggy: bool = MANE[v] > 0.5
	if front:
		_ellipsoid(fur, Vector3(0.205, 1.14, 0.46) * m, Vector3(0.11, 0.24, 0.15) * w, 7, 4, Basis(Vector3.RIGHT, 0.3))
		var p := PackedVector3Array([Vector3(0.20, 1.12, 0.46), Vector3(0.215, 0.86, 0.36), Vector3(0.205, 0.70, 0.42)])
		for i: int in p.size():
			p[i] *= m
		_tube(fur, p, PackedFloat32Array([0.125 * w, 0.1 * w, 0.078 * w]), 7)
		var q := PackedVector3Array([Vector3(0.205, 0.74, 0.405), Vector3(0.198, 0.55, 0.47), WRIST_F + Vector3(0, 0.02, 0)])
		for i: int in q.size():
			q[i] *= m
		_tube(pale, q, PackedFloat32Array([0.078 * w, 0.066 * w, 0.056 * w]), 7)
		if shaggy:
			_lock(fur, Vector3(0.215, 0.86, 0.3) * m, Vector3(0, -0.2, -1.0), Vector3(0.0, -0.8, -0.8), 0.16, 0.07)
	else:
		_ellipsoid(fur, Vector3(0.19, 0.98, -0.72) * m, Vector3(0.145, 0.27, 0.21) * Vector3(w, 1.0, w), 7, 4,
			Basis(Vector3.RIGHT, -0.2))
		var p := PackedVector3Array([Vector3(0.18, 1.10, -0.70), Vector3(0.21, 0.80, -0.58), Vector3(0.205, 0.64, -0.72)])
		for i: int in p.size():
			p[i] *= m
		_tube(fur, p, PackedFloat32Array([0.15 * w, 0.1 * w, 0.078 * w]), 7)
		var q := PackedVector3Array([Vector3(0.205, 0.67, -0.70), Vector3(0.20, 0.55, -0.80), HOCK_B + Vector3(0, 0.02, 0)])
		for i: int in q.size():
			q[i] *= m
		_tube(pale, q, PackedFloat32Array([0.074 * w, 0.064 * w, 0.056 * w]), 7)
		if shaggy:
			var rng := RandomNumberGenerator.new()
			rng.seed = 77 + int(sx + 1.0)
			for k: int in 4:
				var c := Vector3(0.2 + 0.03 * float(k % 2), 1.02 - 0.1 * float(k), -0.9 + 0.02 * float(k)) * m
				var nn := Vector3(0.35 * sx, 0.0, -1.0).normalized()
				_lock(fur, c, nn, nn + Vector3(0.0, -0.6, 0.0) + _jit(rng, 0.15), rng.randf_range(0.15, 0.2), 0.085)
	return _commit(key, [[fur, mat("fur", v)], [pale, mat("pale", v)]])


## Lower leg (Lower/Shin, turns at the wrist / hock): pale pastern / metatarsus, the paw with toe pads, dark claws.
static func lower_leg_mesh(front: bool, sx: float, v: int) -> Mesh:
	var key := "lower_%s_%s_%d" % [front, sx, v]
	if _meshes.has(key):
		return _meshes[key]
	var pale := _bucket()
	var dark := _bucket()
	var m := Vector3(sx, 1.0, 1.0)
	var w: float = LEG_W[v]
	var j: Vector3 = WRIST_F if front else HOCK_B
	var zf: float = j.z + (0.1 if front else 0.12)
	var p := PackedVector3Array([j, Vector3(j.x, lerpf(j.y, 0.12, 0.55), lerpf(j.z, zf - 0.04, 0.55)),
		Vector3(j.x, 0.10, zf - 0.03)])
	for i: int in p.size():
		p[i] *= m
	_tube(pale, p, PackedFloat32Array([0.056 * w, 0.046 * w, 0.05 * w]), 6)
	_ellipsoid(pale, j * m, Vector3(0.064, 0.066, 0.07) * w, 6, 3)
	var paw := Vector3(j.x, 0.05, zf + 0.02)
	_ellipsoid(pale, paw * m, Vector3(0.07 * w, 0.05, 0.115), 7, 3)
	for c: float in [-1.0, 0.0, 1.0]:
		var base := Vector3(j.x + 0.034 * c * w, 0.045, zf + 0.1 - 0.012 * absf(c))
		_ellipsoid(pale, base * m, Vector3(0.026, 0.03, 0.03), 5, 2)
		_cone(dark, (base + Vector3(0.0, 0.0, 0.015)) * m, (base + Vector3(0.004 * c, -0.04, 0.05)) * m, 0.013, 4)
	return _commit(key, [[pale, mat("pale", v)], [dark, mat("dark")]])
