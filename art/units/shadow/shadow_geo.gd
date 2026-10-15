class_name ShadowGeo
extends RefCounted
## Shaped low-poly meshes for the Shadow army pass G-C (docs/art/gc_shadow_units.md): lathes (robes with tattered
## hems, hoods, domed pauldrons, greaves, hat brims), tapered tubes along a polyline (limbs, horns, spikes, tails, crooked
## poles, ribs), bevelled blades with a diamond section, and a combiner. Pure geometry: no node, no material. The painted
## shader reads local / world positions (no UV), so the meshes carry positions + normals (UVs zero; capes for
## banner.gdshader get real UVs).
## Smooth meshes share ring vertices (normals averaged over the shared triangles); blades are flat-shaded (crisp facets).
## Every builder returns an ArrayMesh with ONE surface (the caller gives it a palette material through add_part).

const DEG := PI / 180.0


## A surface of revolution around +Y. `prof` = rings top to bottom (or any order) as Vector3(radius, y, z offset).
## Options (all optional):
##   sx / sz   ellipse scale of every ring (x / z)
##   keel      front ridge: radius x (1 + keel x cos(a)^6) on the +Z side (breastplates)
##   jag       tattered edge on ring `jag_ring` (default the last): even vertices pulled by jag (down when > 0,
##             up when < 0) with a hashed length, odd ones barely; `jag_seed` varies the pattern
##   arc       Vector2(a0, a1) in degrees (0 = +Z front, 90 = +X): only that part of the ring (open shell)
##   cap_top / cap_bot  close the first / last ring with a fan (a ring of radius 0 is an apex already)
##   flat      flat-shaded facets (plate armour) instead of smooth normals
static func lathe(prof: Array, seg: int, o: Dictionary = {}) -> ArrayMesh:
	var sx: float = o.get("sx", 1.0)
	var sz: float = o.get("sz", 1.0)
	var keel: float = o.get("keel", 0.0)
	var jag: float = o.get("jag", 0.0)
	var jag_ring: int = o.get("jag_ring", prof.size() - 1)
	var seed: int = o.get("jag_seed", 0)
	var full := not o.has("arc")
	var arc: Vector2 = o.get("arc", Vector2(0.0, 360.0))
	var n_ring: int = seg if full else seg + 1
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	var ring_start: Array[int] = []
	var apex: Array[bool] = []
	for ri: int in prof.size():
		var pr: Vector3 = prof[ri]
		ring_start.append(verts.size())
		if pr.x <= 0.0001:
			apex.append(true)
			verts.append(Vector3(0.0, pr.y, pr.z))
			continue
		apex.append(false)
		for j: int in n_ring:
			var a: float = (arc.x + (arc.y - arc.x) * float(j) / float(seg)) * DEG
			var r: float = pr.x * (1.0 + keel * pow(maxf(cos(a), 0.0), 6.0))
			var y: float = pr.y
			if jag != 0.0 and ri == jag_ring:
				var h := _hash01(j * 7 + seed * 131)
				var k: float = (0.55 + 0.45 * h) if j % 2 == 0 else 0.12 * h
				y -= jag * k
				r *= 1.0 + 0.05 * k
			verts.append(Vector3(sin(a) * r * sx, y, cos(a) * r * sz + pr.z))
	for ri: int in prof.size() - 1:
		var s0: int = ring_start[ri]
		var s1: int = ring_start[ri + 1]
		var segs: int = seg
		for j: int in segs:
			var j1: int = (j + 1) % n_ring if full else j + 1
			if apex[ri] and apex[ri + 1]:
				continue
			if apex[ri]:
				_tri(idx, s0, s1 + j1, s1 + j)
			elif apex[ri + 1]:
				_tri(idx, s0 + j, s0 + j1, s1)
			else:
				_quad(idx, s0 + j, s0 + j1, s1 + j1, s1 + j)
	if o.get("cap_top", false) and not apex[0]:
		_cap(verts, idx, ring_start[0], n_ring, seg, full, Vector3.UP)
	if o.get("cap_bot", false) and not apex[prof.size() - 1]:
		_cap(verts, idx, ring_start[prof.size() - 1], n_ring, seg, full, Vector3.DOWN)
	if o.get("flat", false):
		var tris := PackedVector3Array()
		for i: int in idx:
			tris.append(verts[i])
		return _flat(tris)
	return _smooth(verts, idx)


## A tapered tube along `pts` (radius per point; 0 = a pointed tip / start). Frame by parallel transport from `up`.
## Options: seg (6), ell = Vector2(scale along the frame normal, scale along the binormal) (flattened straps, blades
## of cloth), cap_start / cap_end (fan caps on a non-zero end).
static func tube(pts: PackedVector3Array, radii: PackedFloat32Array, o: Dictionary = {}) -> ArrayMesh:
	var seg: int = o.get("seg", 6)
	var ell: Vector2 = o.get("ell", Vector2.ONE)
	var up: Vector3 = o.get("up", Vector3.UP)
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	var n := pts.size()
	var starts: Array[int] = []
	var apex: Array[bool] = []
	var nrm := Vector3.ZERO
	for i: int in n:
		var t: Vector3
		if i == 0:
			t = (pts[1] - pts[0]).normalized()
		elif i == n - 1:
			t = (pts[i] - pts[i - 1]).normalized()
		else:
			t = (pts[i + 1] - pts[i - 1]).normalized()
		if i == 0:
			nrm = up - t * up.dot(t)
			if nrm.length() < 0.01:
				nrm = Vector3.BACK - t * Vector3.BACK.dot(t)
			nrm = nrm.normalized()
		else:
			nrm = (nrm - t * nrm.dot(t)).normalized()
		var bin := t.cross(nrm).normalized()
		starts.append(verts.size())
		var r: float = radii[i]
		if r <= 0.0001:
			apex.append(true)
			verts.append(pts[i])
			continue
		apex.append(false)
		for j: int in seg:
			var a: float = TAU * float(j) / float(seg)
			verts.append(pts[i] + nrm * cos(a) * r * ell.x + bin * sin(a) * r * ell.y)
	for i: int in n - 1:
		var s0: int = starts[i]
		var s1: int = starts[i + 1]
		for j: int in seg:
			var j1: int = (j + 1) % seg
			if apex[i] and apex[i + 1]:
				continue
			if apex[i]:
				_tri(idx, s0, s1 + j, s1 + j1)
			elif apex[i + 1]:
				_tri(idx, s0 + j, s1, s0 + j1)
			else:
				_quad(idx, s0 + j, s1 + j, s1 + j1, s0 + j1)
	if o.get("cap_start", false) and not apex[0]:
		_cap(verts, idx, starts[0], seg, seg, true, (pts[0] - pts[1]).normalized(), pts[0])
	if o.get("cap_end", false) and not apex[n - 1]:
		_cap(verts, idx, starts[n - 1], seg, seg, true, (pts[n - 1] - pts[n - 2]).normalized(), pts[n - 1])
	return _smooth(verts, idx)


## A blade along `spine` (model space): half-width `widths[i]` toward `edge` (+ `back` x that toward -edge: 0.25 = a
## single-edged blade with a thick back, 1 = double-edged), ridge thickness `thick` along `face` (the flat's normal).
## Flat-shaded diamond section; a width of 0 is the tip.
static func blade(spine: PackedVector3Array, widths: PackedFloat32Array, edge: Vector3, face: Vector3, thick: float,
		back: float = 1.0) -> ArrayMesh:
	var e := edge.normalized()
	var f := face.normalized()
	var rings: Array = []
	for i: int in spine.size():
		var w: float = widths[i]
		var th: float = thick * clampf(w / maxf(widths[0], 0.001), 0.25, 1.0)
		if w <= 0.0001:
			rings.append([spine[i], spine[i], spine[i], spine[i]])
		else:
			rings.append([spine[i] + e * w, spine[i] + f * th, spine[i] - e * w * back, spine[i] - f * th])
	var tris := PackedVector3Array()
	for i: int in spine.size() - 1:
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var mid: Vector3 = (spine[i] + spine[i + 1]) * 0.5
		for k: int in 4:
			var k1: int = (k + 1) % 4
			var q: Vector3 = (r0[k] + r0[k1] + r1[k1] + r1[k]) * 0.25
			_flat_quad(tris, r0[k], r0[k1], r1[k1], r1[k], q - mid)
	# Close the base (a flat end at the guard).
	var b0: Array = rings[0]
	var down: Vector3 = spine[0] - spine[1]
	_flat_tri(tris, b0[0], b0[2], b0[1], down)
	_flat_tri(tris, b0[0], b0[3], b0[2], down)
	return _flat(tris)


## A cape for banner.gdshader (UV.y 0 at the fixed top edge, normals toward +Z like a PlaneMesh FACE_Z): `w_top` wide
## at the top, `w_bot` at the hem, `h` tall, centred on the origin; the sides wrap forward by `wrap` (m, round the
## shoulders, less toward the hem); the hem is tattered: every other column hangs lower by up to `jag` (m).
static func cloth(w_top: float, w_bot: float, h: float, cols: int, rows: int, wrap: float, jag: float, seed: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for r: int in rows + 1:
		var v: float = float(r) / float(rows)
		var w: float = lerpf(w_top, w_bot, v)
		for c: int in cols + 1:
			var u: float = float(c) / float(cols)
			var x: float = (u - 0.5) * w
			var y: float = h * 0.5 - v * h
			if r == rows:
				var k: float = (0.55 + 0.45 * _hash01(c * 13 + seed)) if c % 2 == 1 else 0.15 * _hash01(c * 5 + seed)
				y -= jag * k
			elif r == rows - 1 and c % 2 == 1:
				y -= jag * 0.25 * _hash01(c * 3 + seed)
			var z: float = wrap * pow(2.0 * u - 1.0, 2.0) * (1.0 - 0.6 * v)
			verts.append(Vector3(x, y, z))
			uvs.append(Vector2(u, clampf(0.5 - y / h, 0.0, 1.0)))
	for r: int in rows:
		for c: int in cols:
			var a: int = r * (cols + 1) + c
			var b: int = a + 1
			var d: int = a + cols + 1
			var e: int = d + 1
			_tri(idx, a, e, b)
			_tri(idx, a, d, e)
	var mesh := _smooth(verts, idx)
	var arr := mesh.surface_get_arrays(0)
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for i: int in nr.size():
		if nr[i].z < 0.0:
			nr[i] = -nr[i]
	return _commit(verts, nr, idx, uvs)


## Quadratic Bezier points a -> c with control b (n + 1 points).
static func bez(a: Vector3, b: Vector3, c: Vector3, n: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i: int in n + 1:
		var t: float = float(i) / float(n)
		out.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
	return out


## Radii from r0 to r1 over n points (eased toward the tip).
static func taper(r0: float, r1: float, n: int, ease_pow: float = 1.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i: int in n:
		var t: float = float(i) / float(maxi(n - 1, 1))
		out.append(lerpf(r0, r1, pow(t, ease_pow)))
	return out


## Concatenates meshes (each [mesh, Transform3D]) into one single-surface ArrayMesh (same material for all).
static func combine(items: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for it: Array in items:
		var m: Mesh = it[0]
		var xf: Transform3D = it[1] if it.size() > 1 else Transform3D.IDENTITY
		var nb := xf.basis.inverse().transposed()
		for s: int in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var base := verts.size()
			for j: int in v.size():
				verts.append(xf * v[j])
				norms.append((nb * nr[j]).normalized() if j < nr.size() else Vector3.UP)
			if ix.is_empty():
				for j: int in v.size():
					idx.append(base + j)
			else:
				for j: int in ix.size():
					idx.append(base + ix[j])
	return _commit(verts, norms, idx)


## Vertex count of a mesh (all surfaces).
static func vert_count(m: Mesh) -> int:
	var c := 0
	if m == null:
		return 0
	for s: int in m.get_surface_count():
		c += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


# ---------------------------------------------------------------- internals

static func _hash01(k: int) -> float:
	var h: int = (k * 374761393 + 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 1000) / 999.0


static func _tri(idx: PackedInt32Array, a: int, b: int, c: int) -> void:
	idx.append(a)
	idx.append(b)
	idx.append(c)


## Triangle a b c, flipped when its front normal points away from `want`.
static func _tri_facing(idx: PackedInt32Array, verts: PackedVector3Array, a: int, b: int, c: int, want: Vector3) -> void:
	var fn := (verts[c] - verts[a]).cross(verts[b] - verts[a])
	if fn.dot(want) < 0.0:
		_tri(idx, a, c, b)
	else:
		_tri(idx, a, b, c)


## Quad a b c d wound so the lathe / tube outside faces out (Godot: clockwise = front).
static func _quad(idx: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	_tri(idx, a, b, c)
	_tri(idx, a, c, d)


## A fan over a ring, each triangle wound to face `want`.
static func _cap(verts: PackedVector3Array, idx: PackedInt32Array, start: int, n_ring: int, seg: int, full: bool,
		want: Vector3, center: Variant = null) -> void:
	var c := Vector3.ZERO
	if center is Vector3:
		c = center
	else:
		for j: int in n_ring:
			c += verts[start + j]
		c /= float(n_ring)
	var ci := verts.size()
	verts.append(c)
	for j: int in seg:
		var j1: int = (j + 1) % n_ring if full else j + 1
		_tri_facing(idx, verts, ci, start + j, start + j1, want)


## Smooth normals: each vertex = the area-weighted sum of its triangles' normals (the builders wind every triangle
## clockwise seen from outside, Godot's front face; tests/test_gc_shadow.gd checks the normals point outward).
static func _smooth(verts: PackedVector3Array, idx: PackedInt32Array) -> ArrayMesh:
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	for t: int in range(0, idx.size(), 3):
		var a := verts[idx[t]]
		var b := verts[idx[t + 1]]
		var c := verts[idx[t + 2]]
		var fn := (c - a).cross(b - a)   # Godot front faces are clockwise: this points out of a clockwise triangle
		norms[idx[t]] += fn
		norms[idx[t + 1]] += fn
		norms[idx[t + 2]] += fn
	for i: int in norms.size():
		norms[i] = norms[i].normalized() if norms[i].length() > 0.0000001 else Vector3.UP
	return _commit(verts, norms, idx)


## A flat triangle wound to face `want`.
static func _flat_tri(tris: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, want: Vector3) -> void:
	if (c - a).cross(b - a).dot(want) < 0.0:
		tris.append(a)
		tris.append(c)
		tris.append(b)
	else:
		tris.append(a)
		tris.append(b)
		tris.append(c)


static func _flat_quad(tris: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, want: Vector3) -> void:
	_flat_tri(tris, a, b, c, want)
	_flat_tri(tris, a, c, d, want)


static func _flat(tris: PackedVector3Array) -> ArrayMesh:
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	var verts := PackedVector3Array()
	for t: int in range(0, tris.size(), 3):
		var a := tris[t]
		var b := tris[t + 1]
		var c := tris[t + 2]
		var fn := (c - a).cross(b - a)
		if fn.length() < 0.0000001:
			continue
		fn = fn.normalized()
		for p: Vector3 in [a, b, c]:
			idx.append(verts.size())
			verts.append(p)
			norms.append(fn)
	return _commit(verts, norms, idx)


static func _commit(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array,
		uvs: PackedVector2Array = PackedVector2Array()) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	var uv := uvs
	if uv.size() != verts.size():
		uv = PackedVector2Array()
		uv.resize(verts.size())
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	if verts.is_empty():
		return am
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am
