extends RefCounted
## forge_evenmead mesh builder (set-only tool helper, preloaded by make_world.gd): packed arrays, indexed triangles,
## vertex colour (sRGB) + UV (x = wind weight / shader data, y = kind) + UV2 (x = per-instance random, y = AO / height
## 0..1). Front faces are clockwise seen from the front in Godot: tri(a, b, c) takes a counter-clockwise (right-hand)
## triple and stores it reversed. No class_name on purpose.

var v := PackedVector3Array()
var n := PackedVector3Array()
var c := PackedColorArray()
var uv := PackedVector2Array()
var uv2 := PackedVector2Array()
var idx := PackedInt32Array()


func vert(p: Vector3, nn: Vector3, col: Color, u: Vector2 = Vector2.ZERO, u2: Vector2 = Vector2.ZERO) -> int:
	v.append(p)
	n.append(nn)
	c.append(col)
	uv.append(u)
	uv2.append(u2)
	return v.size() - 1


## Counter-clockwise (seen from the side the normal points to) triangle of existing vertices.
func tri(a: int, b: int, d: int) -> void:
	idx.append(a)
	idx.append(d)
	idx.append(b)


func tri_count() -> int:
	return idx.size() / 3


func is_empty() -> bool:
	return idx.is_empty()


## Flat-shaded triangle (own vertices).
func ftri(a: Vector3, b: Vector3, d: Vector3, col: Color, u: Vector2 = Vector2.ZERO, u2: Vector2 = Vector2(0, 1)) -> void:
	var nn := (b - a).cross(d - a).normalized()
	var i := vert(a, nn, col, u, u2)
	vert(b, nn, col, u, u2)
	vert(d, nn, col, u, u2)
	tri(i, i + 1, i + 2)


func fquad(a: Vector3, b: Vector3, d: Vector3, e: Vector3, col: Color, u: Vector2 = Vector2.ZERO, u2: Vector2 = Vector2(0, 1)) -> void:
	ftri(a, b, d, col, u, u2)
	ftri(a, d, e, col, u, u2)


## Flat-shaded tapered prism around xf's Y axis, base centre c, from y 0 to h. shade = per-face tone variation.
func prism(xf: Transform3D, cc: Vector3, r0: float, r1: float, h: float, sides: int, col: Color, caps := true,
		u: Vector2 = Vector2.ZERO, top_col = null, phase := 0.0) -> void:
	for i in sides:
		var a0 := TAU * (i + phase) / sides
		var a1 := TAU * (i + 1 + phase) / sides
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		var k := 0.9 + 0.1 * cos((a0 + a1) * 0.5 - 0.9)
		var tone := Color(col.r * k, col.g * k, col.b * k, col.a)
		var b0 := xf * (cc + d0 * r0)
		var b1 := xf * (cc + d1 * r0)
		var t0 := xf * (cc + d0 * r1 + Vector3(0, h, 0))
		var t1 := xf * (cc + d1 * r1 + Vector3(0, h, 0))
		fquad(b0, b1, t1, t0, tone, u)
		if caps and r1 > 0.001:
			ftri(xf * (cc + Vector3(0, h, 0)), t0, t1, top_col if top_col is Color else col, u)


func box(xf: Transform3D, cc: Vector3, hh: Vector3, col: Color, u: Vector2 = Vector2.ZERO) -> void:
	var p := func(x: float, y: float, z: float) -> Vector3: return xf * (cc + Vector3(x * hh.x, y * hh.y, z * hh.z))
	var sh := func(k: float) -> Color: return Color(col.r * k, col.g * k, col.b * k, col.a)
	fquad(p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), sh.call(0.94), u)
	fquad(p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1), sh.call(0.84), u)
	fquad(p.call(1, -1, 1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(1, 1, 1), sh.call(0.9), u)
	fquad(p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), sh.call(0.88), u)
	fquad(p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, 1, -1), p.call(-1, 1, -1), sh.call(1.0), u)


## Soft lumpy blob (foliage clump / cloud / boulder): a UV sphere (rings x segs) centred at cc with radii rr,
## displaced by hash noise; normals = spherical (soft painted shading) mixed with the facet normal by `facet`.
## col_fn(dir: Vector3) -> Color gives the vertex colour from the outward direction (baked light / occlusion).
func blob(cc: Vector3, rr: Vector3, rings: int, segs: int, col_fn: Callable, u: Vector2, u2x: float, seed: int,
		lump := 0.18, facet := 0.35, flat_bottom := 0.0, crown := Vector3.INF, cmix := 0.0) -> void:
	var grid: Array = []
	for j in rings + 1:
		var row: Array = []
		var th := PI * float(j) / rings
		for i in segs:
			var ph := TAU * (float(i) + (0.5 if j % 2 == 1 else 0.0)) / segs
			var d := Vector3(sin(th) * sin(ph), cos(th), sin(th) * cos(ph))
			var k := 1.0 + lump * (h01(float(i) + seed * 0.37, float(j), seed) - 0.5) * 2.0
			if j == 0 or j == rings:
				k = 1.0
			var p := cc + Vector3(d.x * rr.x, d.y * rr.y, d.z * rr.z) * k
			if flat_bottom > 0.0 and p.y < cc.y - rr.y * flat_bottom:
				p.y = cc.y - rr.y * flat_bottom
			row.append([p, d])
		grid.append(row)
	for j in rings:
		for i in segs:
			var i1 := (i + 1) % segs
			var q00: Array = grid[j][i]
			var q01: Array = grid[j][i1]
			var q10: Array = grid[j + 1][i]
			var q11: Array = grid[j + 1][i1]
			for t: Array in [[q00, q10, q11], [q00, q11, q01]]:
				var a: Vector3 = t[0][0]
				var b: Vector3 = t[1][0]
				var e: Vector3 = t[2][0]
				var fn := (b - a).cross(e - a)
				if fn.length() < 1e-6:
					continue
				fn = fn.normalized()
				var tt: Array = t
				if fn.dot((a + b + e) / 3.0 - cc) < 0.0:
					fn = -fn
					tt = [t[0], t[2], t[1]]
				var ids: Array[int] = []
				for q: Array in tt:
					var dd: Vector3 = q[1]
					if cmix > 0.0 and crown.is_finite():
						dd = dd.lerp(((q[0] as Vector3) - crown).normalized(), cmix).normalized()
					var nn := dd.lerp(fn, facet).normalized()
					var yy := clampf(0.5 + 0.5 * dd.y, 0.0, 1.0)
					ids.append(vert(q[0], nn, col_fn.call(dd), u, Vector2(u2x, yy)))
				tri(ids[0], ids[1], ids[2])


## Appends the arrays as a surface of `mesh` with material `mat`. Returns the triangle count.
func commit(mesh: ArrayMesh, mat: Material) -> int:
	if idx.is_empty():
		return 0
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	arr[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	return idx.size() / 3


static func h01(a: float, b: float, s: int) -> float:
	var hh := int(floor(a * 131.0)) * 73856093 ^ int(floor(b * 137.0)) * 19349663 ^ s * 83492791
	hh = (hh ^ (hh >> 13)) * 1274126177
	return float((hh ^ (hh >> 16)) & 0xffff) / 65535.0
