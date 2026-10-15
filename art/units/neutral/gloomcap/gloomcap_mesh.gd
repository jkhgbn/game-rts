extends RefCounted
## Gloomcap mesh builders (task 12.V22), shared by the Elder and the Sprout: lathes (caps, stalks, skirts), tubes
## (roots, beard, staff), ellipsoids (spots, eyes, bulbs). Everything is built in MODEL space (feet origin, face +Z),
## once per game, cached by key; materials are the folder's .tres files (loaded once, shared). No class_name: the two
## model scripts preload it.

const MAT_DIR := "res://art/units/neutral/gloomcap/materials/"

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}
static var _prims: Dictionary = {}


static func mat(name: StringName) -> Material:
	if not _mats.has(name):
		_mats[name] = load(MAT_DIR + String(name) + ".tres")
	return _mats[name]


static func cached(key: String) -> ArrayMesh:
	return _meshes.get(key)


static func bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## A (cols+1) x (rows+1) grid of points (row-major) with given normals; each triangle wound so its front (Godot:
## clockwise) faces its normals.
static func grid(acc: Array, pts: PackedVector3Array, nrm: PackedVector3Array, cols: int, rows: int) -> void:
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
					continue   # degenerate (a pole)
				if front.dot(nrm[a] + nrm[b] + nrm[c]) < 0.0:
					var t := b
					b = c
					c = t
				acc[3].append(b0 + a)
				acc[3].append(b0 + b)
				acc[3].append(b0 + c)


## Appends a primitive's surface 0 transformed by xf.
static func put(acc: Array, m: Mesh, xf: Transform3D) -> void:
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


static func _sphere(radial: int, rings: int) -> Mesh:
	var key := "s%d_%d" % [radial, rings]
	if not _prims.has(key):
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = radial
		s.rings = rings
		_prims[key] = s
	return _prims[key]


static func ellipsoid(acc: Array, c: Vector3, r: Vector3, radial: int = 8, rings: int = 4,
		rot: Basis = Basis.IDENTITY) -> void:
	put(acc, _sphere(radial, rings), Transform3D(rot * Basis.from_scale(r), c))


## A flattened blob lying on a surface: centre c, surface normal n, radius r across (x spect the other way, turned by
## spin rad about n), thickness h along n.
static func patch_on(acc: Array, c: Vector3, n: Vector3, r: float, h: float, radial: int = 10, rings: int = 3,
		aspect: float = 0.8, spin: float = 0.0) -> void:
	var b := Basis(Quaternion(Vector3.UP, n.normalized())) * Basis(Vector3.UP, spin)
	ellipsoid(acc, c, Vector3(r, h, r * aspect), radial, rings, b)


## G-D: a raised fungal wart on a cap (replaces a flat painted spot, same vertex count): a domed wart `r` across,
## sunk a little into the cap so it reads as a growth, not a sticker; `satellite` adds a smaller wart beside it.
static func warts(acc: Array, c: Vector3, n: Vector3, r: float, seed_f: float, aspect: float = 0.85,
		satellite: bool = false, rise: float = 0.42) -> void:
	var nn := n.normalized()
	patch_on(acc, c - nn * r * 0.08, nn, r * 0.92, r * rise, 8, 3, aspect, seed_f * 1.7)
	if not satellite:
		return
	var t := nn.cross(Vector3.UP if absf(nn.y) < 0.9 else Vector3.RIGHT).normalized()
	var b := nn.cross(t).normalized()
	var a := seed_f * 2.3 + 0.6 * sin(seed_f * 5.0)
	var rr := r * 0.36
	patch_on(acc, c + (t * cos(a) + b * sin(a)) * r * 1.2 - nn * rr * 0.25, nn, rr, rr * 0.55, 6, 2, 0.9, a)


## Smooth tube through pts (radius per point, 0 = a point), `seg` sides; `ref` must not be parallel to the path.
static func tube(acc: Array, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int,
		ref: Vector3 = Vector3.FORWARD) -> void:
	var g := PackedVector3Array()
	var nrm := PackedVector3Array()
	var n := pts.size()
	for i: int in n:
		var t := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var rf := ref if absf(t.dot(ref)) < 0.9 else Vector3.RIGHT
		var s := t.cross(rf).normalized()
		var u := s.cross(t).normalized()
		for k: int in seg + 1:
			var a := TAU * float(k) / float(seg)
			var d := s * cos(a) + u * sin(a)
			g.append(pts[i] + d * radii[i])
			nrm.append(d if radii[i] > 0.0 else t)
	grid(acc, g, nrm, seg, n - 1)


## A root: a tube from a to b that wanders sideways (`wig` m) and tapers r0 -> r1 over `n` points.
static func root(acc: Array, a: Vector3, b: Vector3, r0: float, r1: float, n: int, wig: float, seed_f: float,
		seg: int = 5) -> void:
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var d := b - a
	var side := d.cross(Vector3.UP if absf(d.normalized().y) < 0.9 else Vector3.RIGHT).normalized()
	var up2 := side.cross(d).normalized()
	for i: int in n:
		var u := float(i) / float(n - 1)
		var env := sin(PI * u)
		var off := side * sin(u * 5.0 + seed_f) * wig * env + up2 * sin(u * 3.7 + seed_f * 1.7) * wig * 0.6 * env
		pts.append(a + d * u + off)
		radii.append(lerpf(r0, r1, u))
	tube(acc, pts, radii, seg, side)


## Surface of revolution about the model-space axis through `centre` (basis `rot`, local +Y up).
## prof: (r, y) points ordered so that the outside is on the right when walking along the profile (bottom -> top
## for walls, centre -> rim for undersides, rim -> centre for tops): the outward normal is (dy, -dr).
## shape(a, r, y) -> Vector3 (radius factor, y offset, unused): organic lumps / droops (a = 0 faces +Z). Normals are
## measured on the displaced surface, so a shared profile point shades the same in two patches.
static func lathe(acc: Array, prof: PackedVector2Array, seg: int, centre: Vector3, shape: Callable = Callable(),
		rot: Basis = Basis.IDENTITY) -> void:
	var rows := prof.size()
	var cols := seg
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	var p := func(i: int, k: int) -> Vector3:
		var ii := clampi(i, 0, rows - 1)
		var a := TAU * float(posmod(k, cols)) / float(cols)
		var r := prof[ii].x
		var y := prof[ii].y
		if shape.is_valid():
			var s: Vector3 = shape.call(a, r, y)
			r *= s.x
			y += s.y
		return Vector3(sin(a) * r, y, cos(a) * r)
	for i: int in rows:
		for k: int in cols + 1:
			var a := TAU * float(k) / float(cols)
			var q: Vector3 = p.call(i, k)
			# Analytic outward normal of the undisplaced profile, used to orient the measured one.
			var t2 := prof[mini(i + 1, rows - 1)] - prof[maxi(i - 1, 0)]
			var n2 := Vector2(t2.y, -t2.x).normalized()
			var an := Vector3(sin(a) * n2.x, n2.y, cos(a) * n2.x)
			var du: Vector3 = p.call(i, k + 1) - p.call(i, k - 1)
			var dv: Vector3 = p.call(i + 1, k) - p.call(i - 1, k)
			var mn := du.cross(dv)
			if mn.length_squared() < 1e-12 or prof[i].x < 1e-4:
				mn = an
			mn = mn.normalized()
			if mn.dot(an) < 0.0:
				mn = -mn
			pts.append(centre + rot * q)
			nrm.append((rot * mn).normalized())
	grid(acc, pts, nrm, cols, rows - 1)


## One ArrayMesh from [acc, material] pairs (empty accs skipped), cached by key.
static func commit(key: String, surfaces: Array) -> ArrayMesh:
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


## Keyframe track [t, value, ease, t, value, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth,
## 1 ease-out, 2 ease-in).
static func trk(t: float, k: PackedFloat32Array) -> float:
	var n: int = k.size()
	if t >= k[n - 3]:
		return k[n - 2]
	if t <= 0.0:
		return k[1]
	var i: int = 3
	while t >= k[i]:
		i += 3
	var t0: float = k[i - 3]
	var u: float = (t - t0) / (k[i] - t0)
	var e: float = k[i + 2]
	if e == 1.0:
		u = u * (2.0 - u)
	elif e == 2.0:
		u = u * u
	else:
		u = u * u * (3.0 - 2.0 * u)
	return k[i - 2] + (k[i + 1] - k[i - 2]) * u
