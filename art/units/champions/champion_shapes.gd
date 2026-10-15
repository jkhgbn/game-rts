class_name ChampionShapes
extends RefCounted
## G-C champions (docs/art/gc_champions.md): smooth / bevelled mesh helpers for the hired champions' hero layer
## (shaped limbs, plate armour, lames, layered capes, rivets, ornate weapons). Same ideas as the Fire units' G-C pass
## (FireShapes, build_fire_units.gd plate()), kept in the champions' folder so the two never couple.
## Everything appends into a SurfaceTool `st` in the caller's space (model space for body parts, piece space for
## weapons); `xf` places a shape. Callers commit once per (part, material) and cache the mesh (static, per process):
##   var st := ChampionShapes.begin()
##   ChampionShapes.tube(st, pts, radii, 8)
##   ChampionShapes.plate(st, poly, 0.04, 0.012, xf)
##   var mesh := ChampionShapes.commit(st)
## Normals: smooth on tubes / lathes / cloth, flat on plates and lames' edges (they catch a thin light line).


static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func commit(st: SurfaceTool) -> ArrayMesh:
	st.index()
	return st.commit()


## Commits several [SurfaceTool, Material] pairs as the surfaces of one mesh (empty tools skipped).
static func commit_multi(pairs: Array) -> ArrayMesh:
	var m := ArrayMesh.new()
	for p: Array in pairs:
		var st: SurfaceTool = p[0]
		st.index()
		var before := m.get_surface_count()
		st.commit(m)
		if m.get_surface_count() > before:
			m.surface_set_material(m.get_surface_count() - 1, p[1])
	return m


## Appends surface 0 of a mesh (a kit primitive, a cached piece) transformed by xf.
static func append(st: SurfaceTool, mesh: Mesh, xf: Transform3D = Transform3D.IDENTITY) -> void:
	if mesh == null:
		return
	for s: int in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var nb := xf.basis.inverse().transposed()
		var count: int = ix.size() if not ix.is_empty() else v.size()
		for k: int in count:
			var j: int = ix[k] if not ix.is_empty() else k
			st.set_normal((nb * nr[j]).normalized() if j < nr.size() else Vector3.UP)
			st.set_uv(uv[j] if j < uv.size() else Vector2.ZERO)
			st.add_vertex(xf * v[j])


# ================================================================ tubes and lathes

## A smooth tapered tube through `pts` (radius per point; 0 = pointed end), parallel-transported rings, normals
## leaning with the taper, the seam welded (st.index()). sx scales the ring across (flat straps, oval limbs).
static func tube(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 7, caps: bool = true,
		sx: float = 1.0, uv: Vector2 = Vector2.ZERO) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	var rings: Array[PackedVector3Array] = []
	var nrms: Array[PackedVector3Array] = []
	var ref := Vector3.ZERO
	for i: int in n:
		var t: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		if i == 0:
			var r0 := Vector3.FORWARD if absf(t.z) < 0.9 else Vector3.RIGHT
			ref = (r0 - t * r0.dot(t)).normalized()
		else:
			ref = (ref - t * ref.dot(t)).normalized()
		var bn: Vector3 = t.cross(ref)
		var dr: float = radii[mini(i + 1, n - 1)] - radii[maxi(i - 1, 0)]
		var dl: float = maxf(pts[mini(i + 1, n - 1)].distance_to(pts[maxi(i - 1, 0)]), 0.0001)
		var slope: float = clampf(-dr / dl, -1.5, 1.5)
		var ring := PackedVector3Array()
		var rn := PackedVector3Array()
		for j: int in seg:
			var a: float = TAU * j / seg
			var d: Vector3 = ref * cos(a) + bn * sin(a) * sx
			ring.append(pts[i] + d * radii[i])
			var dn: Vector3 = ref * cos(a) + bn * sin(a) / maxf(sx, 0.05)
			rn.append((dn.normalized() + t * slope).normalized())
		rings.append(ring)
		nrms.append(rn)
	for i: int in n - 1:
		for j: int in seg:
			var k: int = (j + 1) % seg
			tri(st, rings[i][j], rings[i][k], rings[i + 1][k], nrms[i][j], nrms[i][k], nrms[i + 1][k], uv)
			tri(st, rings[i][j], rings[i + 1][k], rings[i + 1][j], nrms[i][j], nrms[i + 1][k], nrms[i + 1][j], uv)
	if not caps:
		return
	for e: int in [0, n - 1]:
		if radii[e] <= 0.001:
			continue
		var out: Vector3 = (pts[e] - pts[1 if e == 0 else n - 2]).normalized()
		for j: int in seg:
			tri(st, pts[e], rings[e][j], rings[e][(j + 1) % seg], out, out, out, uv)


## Surface of revolution around local Y (profile Vector2(radius, y), bottom to top), smooth normals, flat caps where
## the profile ends off the axis. sx / sz scale the cross-section; a0 / a1 (rad, 0 = +Z, growing toward +X) cut an
## open arc (an arc never gets caps); `flat` = faceted (flat normals per quad: chamfered metal rings, gems).
static func lathe(st: SurfaceTool, prof: PackedVector2Array, seg: int = 10, xf: Transform3D = Transform3D.IDENTITY,
		sx: float = 1.0, sz: float = 1.0, caps: bool = true, a0: float = 0.0, a1: float = TAU, flat: bool = false,
		uv: Vector2 = Vector2.ZERO) -> void:
	var nb: Basis = xf.basis.inverse().transposed()
	var n: int = prof.size()
	var full: bool = absf(a1 - a0 - TAU) < 0.001
	var sn: Array[Vector2] = []
	for i: int in n - 1:
		var t: Vector2 = prof[i + 1] - prof[i]
		sn.append(Vector2(t.y, -t.x).normalized())
	for i: int in n - 1:
		var n0: Vector2 = (sn[i - 1] + sn[i]).normalized() if i > 0 and not flat else sn[i]
		var n1: Vector2 = (sn[i] + sn[i + 1]).normalized() if i < n - 2 and not flat else sn[i]
		for j: int in seg:
			var aa: float = a0 + (a1 - a0) * j / seg
			var ab: float = a0 + (a1 - a0) * (j + 1) / seg
			var va: Vector3 = xf * _lv(prof[i], aa, sx, sz)
			var vb: Vector3 = xf * _lv(prof[i], ab, sx, sz)
			var vc: Vector3 = xf * _lv(prof[i + 1], ab, sx, sz)
			var vd: Vector3 = xf * _lv(prof[i + 1], aa, sx, sz)
			if flat:
				var am: float = (aa + ab) * 0.5
				var fnm: Vector3 = (nb * _ln(sn[i], am, sx, sz)).normalized()
				tri(st, va, vb, vc, fnm, fnm, fnm, uv)
				tri(st, va, vc, vd, fnm, fnm, fnm, uv)
				continue
			var na: Vector3 = (nb * _ln(n0, aa, sx, sz)).normalized()
			var nbb: Vector3 = (nb * _ln(n0, ab, sx, sz)).normalized()
			var nc: Vector3 = (nb * _ln(n1, ab, sx, sz)).normalized()
			var nd: Vector3 = (nb * _ln(n1, aa, sx, sz)).normalized()
			tri(st, va, vb, vc, na, nbb, nc, uv)
			tri(st, va, vc, vd, na, nc, nd, uv)
	if caps and full:
		for e: int in [0, n - 1]:
			if prof[e].x <= 0.001:
				continue
			var up: Vector3 = (nb * (Vector3.UP if e == n - 1 else Vector3.DOWN)).normalized()
			var c: Vector3 = xf * Vector3(0, prof[e].y, 0)
			for j: int in seg:
				tri(st, c, xf * _lv(prof[e], TAU * j / seg, sx, sz), xf * _lv(prof[e], TAU * (j + 1) / seg, sx, sz),
					up, up, up, uv)


static func _lv(p: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(p.x * sin(a) * sx, p.y, p.x * cos(a) * sz)


static func _ln(nn: Vector2, a: float, sx: float, sz: float) -> Vector3:
	return Vector3(nn.x * sin(a) / sx, nn.y, nn.x * cos(a) / sz).normalized()


## A domed stud (rivet / bolt / jewel) at `at` facing `dir`: 6 sides, 2 rings (13 vertices after index()).
static func stud(st: SurfaceTool, at: Vector3, dir: Vector3, r: float, h: float = -1.0) -> void:
	var up := dir.normalized()
	var b := Basis(Quaternion(Vector3.UP, up))
	var hh := r * 0.6 if h < 0.0 else h
	lathe(st, PackedVector2Array([Vector2(r, -hh * 0.3), Vector2(r * 0.8, hh * 0.55), Vector2(0.0, hh)]), 6,
		Transform3D(b, at), 1.0, 1.0, false)


## A flat ring (torus-like band with a square-ish section) around local Y: rims, bands, grip rings.
static func band(st: SurfaceTool, r: float, h: float, thick: float, seg: int, xf: Transform3D, sx: float = 1.0,
		sz: float = 1.0) -> void:
	lathe(st, PackedVector2Array([Vector2(r, -h * 0.5), Vector2(r + thick, -h * 0.3), Vector2(r + thick, h * 0.3),
		Vector2(r, h * 0.5)]), seg, xf, sx, sz, false)


# ================================================================ plates and lames

## Polygon moved inward by d along each corner's bisector (sharp corners clamped).
static func inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var n: int = poly.size()
	var sgn: float = 1.0 if _area(poly) > 0.0 else -1.0
	var out := PackedVector2Array()
	for i: int in n:
		var a: Vector2 = poly[(i + n - 1) % n]
		var p: Vector2 = poly[i]
		var c: Vector2 = poly[(i + 1) % n]
		var e0: Vector2 = (p - a).normalized()
		var e1: Vector2 = (c - p).normalized()
		var n0 := Vector2(e0.y, -e0.x) * sgn
		var n1 := Vector2(e1.y, -e1.x) * sgn
		var bis: Vector2 = n0 + n1
		if bis.length_squared() < 1e-6:
			bis = n0
		bis = bis.normalized()
		out.append(p - bis * d / maxf(bis.dot(n0), 0.33))
	return out


static func _area(poly: PackedVector2Array) -> float:
	var a: float = 0.0
	var n: int = poly.size()
	for i: int in n:
		a += poly[i].x * poly[(i + 1) % n].y - poly[(i + 1) % n].x * poly[i].y
	return a


## Bevelled plate: the polygon (x, y in plate space, face +Z) extruded `depth`, the front face inset by `bevel` and
## joined to the sides by a chamfer ring (flat shaded: every edge catches a light line). back = chamfer the back too
## (blades, crests). `bulge` pushes the front face centre out (a domed plate: breastplates, shields).
static func plate(st: SurfaceTool, poly: PackedVector2Array, depth: float, bevel: float,
		xf: Transform3D = Transform3D.IDENTITY, back: bool = false, uv: Vector2 = Vector2.ZERO) -> void:
	var pidx: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	if pidx.is_empty():
		push_warning("ChampionShapes.plate: outline cannot be triangulated")
		return
	# a thin outline can fold its inset over itself: halve the bevel until the inset triangulates
	var ins: PackedVector2Array = inset(poly, bevel)
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(ins)
	while idx.is_empty() and bevel > 0.0005:
		bevel *= 0.5
		ins = inset(poly, bevel)
		idx = Geometry2D.triangulate_polygon(ins)
	if idx.is_empty():
		ins = poly
		idx = pidx
		bevel = 0.0
	var nb: Basis = xf.basis.inverse().transposed()
	var h: float = depth * 0.5
	var bz: float = minf(bevel, depth * (0.45 if back else 0.7))
	var zf: float = h
	var zc: float = h - bz
	var zbc: float = -h + bz if back else -h
	var fwd: Vector3 = (nb * Vector3.BACK).normalized()
	var bwd: Vector3 = -fwd
	for k: int in range(0, idx.size(), 3):
		tri(st, xf * _p3(ins[idx[k]], zf), xf * _p3(ins[idx[k + 1]], zf), xf * _p3(ins[idx[k + 2]], zf), fwd, fwd, fwd, uv)
	var bpoly: PackedVector2Array = ins if back else poly
	var bidx: PackedInt32Array = idx if back else pidx
	var zb: float = -zf if back else -h
	for k: int in range(0, bidx.size(), 3):
		tri(st, xf * _p3(bpoly[bidx[k]], zb), xf * _p3(bpoly[bidx[k + 1]], zb), xf * _p3(bpoly[bidx[k + 2]], zb),
			bwd, bwd, bwd, uv)
	var n: int = poly.size()
	var sgn: float = 1.0 if _area(poly) > 0.0 else -1.0
	for i: int in n:
		var j: int = (i + 1) % n
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[j]
		var pi: Vector2 = ins[i]
		var qi: Vector2 = ins[j]
		var e: Vector2 = q - p
		var o := Vector3(e.y, -e.x, 0.0).normalized() * sgn
		var on: Vector3 = (nb * o).normalized()
		tri(st, xf * _p3(p, zc), xf * _p3(q, zc), xf * _p3(q, zbc), on, on, on, uv)
		tri(st, xf * _p3(p, zc), xf * _p3(q, zbc), xf * _p3(p, zbc), on, on, on, uv)
		var of: Vector3 = (nb * (o + Vector3.BACK).normalized()).normalized()
		tri(st, xf * _p3(p, zc), xf * _p3(q, zc), xf * _p3(qi, zf), of, of, of, uv)
		tri(st, xf * _p3(p, zc), xf * _p3(qi, zf), xf * _p3(pi, zf), of, of, of, uv)
		if back:
			var ob: Vector3 = (nb * (o + Vector3.FORWARD).normalized()).normalized()
			tri(st, xf * _p3(p, zbc), xf * _p3(q, zbc), xf * _p3(qi, -zf), ob, ob, ob, uv)
			tri(st, xf * _p3(p, zbc), xf * _p3(qi, -zf), xf * _p3(pi, -zf), ob, ob, ob, uv)


static func _p3(p: Vector2, z: float) -> Vector3:
	return Vector3(p.x, p.y, z)


## A curved armour lame: a band of a cone / barrel around local Y (an arc a0 -> a1, 0 = +Z toward +X), from radius
## r0 at y0 to r1 at y1, `thick` thick, with a rolled lower edge (a small outward lip that catches the light).
## Smooth across the arc, flat chamfer edges. Pauldron plates, faulds, tassets, greaves, helm bands.
static func lame(st: SurfaceTool, r0: float, r1: float, y0: float, y1: float, a0: float, a1: float, seg: int,
		thick: float, xf: Transform3D = Transform3D.IDENTITY, sx: float = 1.0, sz: float = 1.0, lip: float = 1.0,
		uv: Vector2 = Vector2.ZERO) -> void:
	var l := thick * 0.9 * lip
	# outer face: lip roll at the bottom, the face, a small chamfer at the top; inner face slightly in.
	var outer := PackedVector2Array([Vector2(r0 + l * 0.2, y0), Vector2(r0 + l, y0 + thick * 0.6),
		Vector2(r0 + (r1 - r0) * 0.12 + l * 0.4, y0 + (y1 - y0) * 0.14), Vector2(r1, y1 - thick * 0.4),
		Vector2(r1 - thick * 0.5, y1)])
	lathe(st, outer, seg, xf, sx, sz, false, a0, a1, false, uv)
	var inner := PackedVector2Array([Vector2(r1 - thick * 0.5, y1), Vector2(r1 - thick, y1 - thick * 0.3),
		Vector2(r0 - thick * 0.6, y0 + thick * 0.3), Vector2(r0 + l * 0.2, y0)])
	lathe(st, inner, seg, xf, sx, sz, false, a0, a1, false, uv)
	# arc ends (flat)
	if absf(a1 - a0 - TAU) > 0.001:
		for a: float in [a0, a1]:
			var pts: Array[Vector3] = []
			for q: Vector2 in [Vector2(r0 + l * 0.2, y0), Vector2(r0 + l, y0 + thick * 0.6), Vector2(r1, y1 - thick * 0.4),
					Vector2(r1 - thick * 0.5, y1), Vector2(r1 - thick, y1 - thick * 0.3), Vector2(r0 - thick * 0.6, y0 + thick * 0.3)]:
				pts.append(xf * _lv(q, a, sx, sz))
			var side: Vector3 = (xf.basis * Vector3(cos(a), 0.0, -sin(a))).normalized() * (-1.0 if a == a0 else 1.0)
			for k: int in range(1, pts.size() - 1):
				tri(st, pts[0], pts[k], pts[k + 1], side, side, side, uv)


# ================================================================ cloth

## A hanging cloth sheet (banner shader UVs: x 0 -> 1 across, y 0 at the top edge -> 1 at the hem): the top edge
## follows `top` (points left to right, e.g. an arc across the shoulders), the sheet falls `drop` along -Y while it
## widens to `flare` x the top width and leans back by `lean` (m at the hem, along -Z of the sheet's own frame);
## `folds` vertical folds of depth `fold` (pleats that deepen toward the hem). Both sides drawn (back faces = the
## lining), smooth normals. Model space.
static func cloth(st: SurfaceTool, top: PackedVector3Array, drop: float, flare: float, lean: float, cols: int,
		rows: int, folds: float = 3.0, fold: float = 0.03, curl: float = 0.0, double: bool = true) -> void:
	var grid: Array[PackedVector3Array] = []
	var c_top := Vector3.ZERO
	for p: Vector3 in top:
		c_top += p
	c_top /= float(top.size())
	for r: int in rows + 1:
		var v: float = float(r) / float(rows)
		var row := PackedVector3Array()
		for c: int in cols + 1:
			var u: float = float(c) / float(cols)
			var tp: Vector3 = _along(top, u)
			var off: Vector3 = tp - c_top
			var w: float = lerpf(1.0, flare, v)
			var p := c_top + Vector3(off.x * w, 0.0, off.z * lerpf(1.0, 0.35, v))
			p.y = tp.y - drop * v
			p.z += -lean * v * v - curl * pow(absf(u - 0.5) * 2.0, 2.0) * v
			var fz: float = sin(u * folds * TAU) * fold * (0.25 + 0.75 * v)
			p.z += fz
			row.append(p)
		grid.append(row)
	for r: int in rows:
		for c: int in cols:
			var a: Vector3 = grid[r][c]
			var b: Vector3 = grid[r][c + 1]
			var cc: Vector3 = grid[r + 1][c + 1]
			var d: Vector3 = grid[r + 1][c]
			var ua := Vector2(float(c) / cols, float(r) / rows)
			var ub := Vector2(float(c + 1) / cols, float(r) / rows)
			var uc := Vector2(float(c + 1) / cols, float(r + 1) / rows)
			var ud := Vector2(float(c) / cols, float(r + 1) / rows)
			var na := _grid_n(grid, r, c)
			var nbv := _grid_n(grid, r, c + 1)
			var nc := _grid_n(grid, r + 1, c + 1)
			var nd := _grid_n(grid, r + 1, c)
			_tri_uv(st, a, b, cc, na, nbv, nc, ua, ub, uc)
			_tri_uv(st, a, cc, d, na, nc, nd, ua, uc, ud)
			if double:
				_tri_uv(st, a, b, cc, -na, -nbv, -nc, ua, ub, uc)
				_tri_uv(st, a, cc, d, -na, -nc, -nd, ua, uc, ud)


## The outward (-Z side = away from the body, +Z = toward the viewer in front) normal of a cloth grid point: the
## grid faces +Z when the top runs left to right (-X -> +X). Callers that hang cloth on the back pass top points
## right to left so the outer face points -Z.
static func _grid_n(g: Array[PackedVector3Array], r: int, c: int) -> Vector3:
	var rows := g.size() - 1
	var cols := g[0].size() - 1
	var du: Vector3 = g[r][mini(c + 1, cols)] - g[r][maxi(c - 1, 0)]
	var dv: Vector3 = g[mini(r + 1, rows)][c] - g[maxi(r - 1, 0)][c]
	var n: Vector3 = dv.cross(du)
	return n.normalized() if n.length_squared() > 1e-12 else Vector3.BACK


static func _along(pts: PackedVector3Array, u: float) -> Vector3:
	var n := pts.size()
	if n == 1:
		return pts[0]
	var f: float = clampf(u, 0.0, 1.0) * float(n - 1)
	var i: int = mini(int(f), n - 2)
	return pts[i].lerp(pts[i + 1], f - float(i))


## An arc of points (for cloth tops): centre c, radius rx / rz, angles a0 -> a1 (0 = +Z, toward +X), n points.
static func arc(c: Vector3, rx: float, rz: float, a0: float, a1: float, n: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i: int in n:
		var a: float = lerpf(a0, a1, float(i) / float(n - 1))
		out.append(c + Vector3(sin(a) * rx, 0.0, cos(a) * rz))
	return out


# ================================================================ triangles

## One triangle whose front face (Godot: clockwise) points along the given normals.
static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
		uv: Vector2 = Vector2.ZERO) -> void:
	_tri_uv(st, a, b, c, na, nb, nc, uv, uv, uv)


static func _tri_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
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
