class_name FireShapes
extends RefCounted
## G-C Fire units (docs/art/gc_fire_units.md): smooth mesh helpers for the code-built Fire models.
## The old tapered "paths" were stacked CylinderMesh segments: every joint showed a hard kink (separate normals per
## segment, 2 rings per segment) and read as jointed pipes. tube_into() sweeps ONE continuous tube through the points
## with shared rings and per-ring normals that follow the bend and the taper: rounder limbs, smoother horns / straps /
## hems, and fewer vertices than the stacked version (n rings instead of 2 (n - 1)).
## Model space in, model space out; callers cache the result (CharacterModel._cached) as before.


## Appends a smooth tapered tube through `pts` (radius per point; 0 = pointed end) to `st` (triangles, normals + UV).
## caps: close the ends that have a radius (flat, own normal).
static func tube_into(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var rings: Array[PackedVector3Array] = []
	var nrms: Array[PackedVector3Array] = []
	var ref := Vector3.ZERO
	for i: int in n:
		var t: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		if i == 0:
			var r0 := Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
			ref = (r0 - t * r0.dot(t)).normalized()
		else:
			ref = (ref - t * ref.dot(t)).normalized()   # parallel transport: no twist along the tube
		var bn: Vector3 = t.cross(ref)
		# taper slope: the normal leans toward the thin end (a cone's normal), so a tapering limb shades round
		var dr: float = radii[mini(i + 1, n - 1)] - radii[maxi(i - 1, 0)]
		var dl: float = maxf(pts[mini(i + 1, n - 1)].distance_to(pts[maxi(i - 1, 0)]), 0.0001)
		var slope: float = clampf(-dr / dl, -1.5, 1.5)
		var ring := PackedVector3Array()
		var rn := PackedVector3Array()
		for j: int in seg:
			var a: float = TAU * j / seg
			var d: Vector3 = ref * cos(a) + bn * sin(a)
			ring.append(pts[i] + d * radii[i])
			rn.append((d + t * slope).normalized())
		rings.append(ring)
		nrms.append(rn)
	for i: int in n - 1:
		var v0: float = float(i) / float(n - 1)
		var v1: float = float(i + 1) / float(n - 1)
		for j: int in seg:
			var k: int = (j + 1) % seg
			var u0: float = float(j) / float(seg)
			var u1: float = float(k) / float(seg)   # the seam welds (the unit shaders do not read UV)
			_tri(st, rings[i][j], rings[i][k], rings[i + 1][k], nrms[i][j], nrms[i][k], nrms[i + 1][k],
				Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1))
			_tri(st, rings[i][j], rings[i + 1][k], rings[i + 1][j], nrms[i][j], nrms[i + 1][k], nrms[i + 1][j],
				Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1))
	if not caps:
		return
	for e: int in [0, n - 1]:
		if radii[e] <= 0.001:
			continue
		var out: Vector3 = (pts[e] - pts[1 if e == 0 else n - 2]).normalized()
		for j: int in seg:
			var k: int = (j + 1) % seg
			_tri(st, pts[e], rings[e][j], rings[e][k], out, out, out, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)


## A finished smooth tube mesh (indexed).
static func tube(pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6, caps: bool = true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	tube_into(st, pts, radii, seg, caps)
	st.index()
	return st.commit()


## Surface of revolution around local Y (profile Vector2(radius, y), bottom to top), smooth normals, the seam welded,
## flat caps where the profile ends off the axis; sx / sz scale the cross-section, xf places it (model space).
static func lathe(prof: PackedVector2Array, seg: int = 12, xf: Transform3D = Transform3D.IDENTITY, sx: float = 1.0,
		sz: float = 1.0, caps: bool = true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nb: Basis = xf.basis.inverse().transposed()
	var n: int = prof.size()
	var sn: Array[Vector2] = []
	for i: int in n - 1:
		var t: Vector2 = prof[i + 1] - prof[i]
		sn.append(Vector2(t.y, -t.x).normalized())
	for i: int in n - 1:
		var n0: Vector2 = (sn[i - 1] + sn[i]).normalized() if i > 0 else sn[i]
		var n1: Vector2 = (sn[i] + sn[i + 1]).normalized() if i < n - 2 else sn[i]
		for j: int in seg:
			var a0: float = TAU * j / seg
			var a1: float = TAU * ((j + 1) % seg) / seg
			var va: Vector3 = xf * _lv(prof[i], a0, sx, sz)
			var vb: Vector3 = xf * _lv(prof[i], a1, sx, sz)
			var vc: Vector3 = xf * _lv(prof[i + 1], a1, sx, sz)
			var vd: Vector3 = xf * _lv(prof[i + 1], a0, sx, sz)
			var na: Vector3 = (nb * _ln(n0, a0, sx, sz)).normalized()
			var nbb: Vector3 = (nb * _ln(n0, a1, sx, sz)).normalized()
			var nc: Vector3 = (nb * _ln(n1, a1, sx, sz)).normalized()
			var nd: Vector3 = (nb * _ln(n1, a0, sx, sz)).normalized()
			_tri(st, va, vb, vc, na, nbb, nc, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
			_tri(st, va, vc, vd, na, nc, nd, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	if caps:
		for e: int in [0, n - 1]:
			if prof[e].x <= 0.001:
				continue
			var up: Vector3 = (nb * (Vector3.UP if e == n - 1 else Vector3.DOWN)).normalized()
			var c: Vector3 = xf * Vector3(0, prof[e].y, 0)
			for j: int in seg:
				_tri(st, c, xf * _lv(prof[e], TAU * j / seg, sx, sz), xf * _lv(prof[e], TAU * ((j + 1) % seg) / seg, sx, sz),
					up, up, up, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	st.index()
	return st.commit()


static func _lv(p: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(p.x * sin(a) * sx, p.y, p.x * cos(a) * sz)


static func _ln(nn: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(nn.x * sin(a) / sx, nn.y, nn.x * cos(a) / sz).normalized()


## One triangle whose front face (Godot: clockwise) points along the given normals.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot(na + nb + nc) > 0.0:
		var t: Vector3 = b
		b = c
		c = t
		var tn: Vector3 = nb
		nb = nc
		nc = tn
		var tu: Vector2 = ub
		ub = uc
		uc = tu
	st.set_normal(na)
	st.set_uv(ua)
	st.add_vertex(a)
	st.set_normal(nb)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_normal(nc)
	st.set_uv(uc)
	st.add_vertex(c)
