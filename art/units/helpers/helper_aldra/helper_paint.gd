extends RefCounted
## Shared builders of the T3 helper models (t3-helpers.md 10.1, TH.V1-V4): Aldra Stillwater (this folder) and Maelis
## Oakenhollow (`art/units/helpers/helper_maelis/`) preload them (no class_name: the Vey / Hush layer in helper_vey/ is
## a sibling with its own builders). Static only, every mesh cached by key (one build per game).
## - Mesh buckets: [verts, normals, indices] filled by put / grid / lathe / seg / tube / lens, committed per material.
## - Hair (hair-redesign-plan.md 2 / 4): `lock` (the prototype's swept, tapered pentagon strand, flat-shaded, optional
##   tip material) and `braid` (alternating flattened lobes along a Catmull-Rom path).
## - Painted face (the Vessa smile-pass method): 2D features in metres of arc on the face, projected onto the facets of
##   the actual head mesh a few mm out (`face_*`), one surface per palette material; the model swaps a cached mesh per
##   expression on ONE keep_separate node.
## - Gestures (19.V10 set for the cinematics): `gesture_pose(model, id, t, hold)` writes rot / pos offsets on the kit
##   pivots; ids point, nod, kneel (held until stand_up), stand_up, raise_weapon.

const DEG := PI / 180.0
const GESTURES: Array[StringName] = [&"point", &"nod", &"kneel", &"stand_up", &"raise_weapon"]
const LOCK_SIDES := 5

static var _cache: Dictionary = {}


# ================================================================ buckets

static func bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedInt32Array()]


static func cached(key: String) -> ArrayMesh:
	return _cache.get(key)


static func xf(at: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), at)


## Appends primitive `m` (surface 0) transformed by `t`.
static func put(acc: Array, m: Mesh, t: Transform3D) -> void:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb := t.basis.inverse().transposed()
	var b0: int = (acc[0] as PackedVector3Array).size()
	for j: int in v.size():
		acc[0].append(t * v[j])
		acc[1].append((nb * nr[j]).normalized())
	if ix.is_empty():
		for j: int in v.size():
			acc[2].append(b0 + j)
	else:
		for j: int in ix.size():
			acc[2].append(b0 + ix[j])


## One flat triangle (Godot front = clockwise seen from outside), its own vertices and face normal.
static func tri_flat(acc: Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (c - a).cross(b - a).normalized()
	var b0: int = (acc[0] as PackedVector3Array).size()
	for p: Vector3 in [a, b, c]:
		acc[0].append(p)
		acc[1].append(n)
	acc[2].append_array(PackedInt32Array([b0, b0 + 1, b0 + 2]))


## (cols+1) x (rows+1) grid (row-major), fronts toward hints; inner != []: a back side inset along -normal (lining).
static func grid(acc: Array, pts: PackedVector3Array, hints: PackedVector3Array, cols: int, rows: int, wrap_u: bool,
		inner: Array = [], inset: float = 0.0) -> void:
	var w := cols + 1
	var norms := PackedVector3Array()
	norms.resize(pts.size())
	for j: int in rows + 1:
		for i: int in cols + 1:
			var il := i - 1
			var ir := i + 1
			if wrap_u:
				if il < 0:
					il = cols - 1
				if ir > cols:
					ir = 1
			else:
				il = maxi(il, 0)
				ir = mini(ir, cols)
			var du := pts[j * w + ir] - pts[j * w + il]
			var dv := pts[mini(j + 1, rows) * w + i] - pts[maxi(j - 1, 0) * w + i]
			var n := du.cross(dv)
			var h := hints[j * w + i]
			if n.length_squared() < 1e-12:
				n = h
			n = n.normalized()
			if n.dot(h) < 0.0:
				n = -n
			norms[j * w + i] = n
	for side: int in (1 if inner.is_empty() else 2):
		var dst: Array = acc if side == 0 else inner
		var s: float = 1.0 if side == 0 else -1.0
		var b0: int = (dst[0] as PackedVector3Array).size()
		for k: int in pts.size():
			dst[0].append(pts[k] - norms[k] * inset if side == 1 else pts[k])
			dst[1].append(norms[k] * s)
		for j: int in rows:
			for i: int in cols:
				var q0 := j * w + i
				for tri: Array in [[q0, q0 + 1, q0 + w], [q0 + 1, q0 + w + 1, q0 + w]]:
					var a: int = tri[0]
					var b: int = tri[1]
					var c: int = tri[2]
					var front := -(pts[b] - pts[a]).cross(pts[c] - pts[a])
					if front.dot((norms[a] + norms[b] + norms[c]) * s) < 0.0:
						var t := b
						b = c
						c = t
					dst[2].append_array(PackedInt32Array([b0 + a, b0 + b, b0 + c]))


## Surface of revolution: profile (r, y), `seg` segments, placed by t.
static func lathe(acc: Array, prof: PackedVector2Array, seg_n: int, t: Transform3D = Transform3D.IDENTITY) -> void:
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	var n := prof.size()
	for j: int in n:
		var d := prof[mini(j + 1, n - 1)] - prof[maxi(j - 1, 0)]
		var n2 := Vector2(d.y, -d.x)
		for i: int in seg_n + 1:
			var a := TAU * float(i) / float(seg_n)
			pts.append(t * Vector3(sin(a) * prof[j].x, prof[j].y, cos(a) * prof[j].x))
			hints.append(t.basis * Vector3(sin(a) * n2.x, n2.y, cos(a) * n2.x))
	grid(acc, pts, hints, seg_n, n - 1, true)


## Cylinder from a to b (radius ra at a, rb at b).
static func seg(acc: Array, a: Vector3, b: Vector3, ra: float, rb: float, n: int = 6, sx: float = 1.0, sz: float = 1.0) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.0001:
		return
	var bs := Basis(Quaternion(Vector3.UP, d / l)).scaled_local(Vector3(sx, l, sz))
	put(acc, CharacterModel.cyl(rb, ra, 1.0, n, false), Transform3D(bs, (a + b) * 0.5))


## A smooth tube through Catmull-Rom samples of ctrl, radius r0 -> r1, rounded joints and tip.
static func tube(acc: Array, ctrl: Array[Vector3], samples: int, r0: float, r1: float, n: int = 6) -> void:
	var pts: Array[Vector3] = []
	for i: int in samples:
		pts.append(crom(ctrl, float(i) / float(samples - 1)))
	for k: int in pts.size() - 1:
		var ra := lerpf(r0, r1, float(k) / float(pts.size() - 1))
		var rb := lerpf(r0, r1, float(k + 1) / float(pts.size() - 1))
		seg(acc, pts[k], pts[k + 1], ra, rb, n)
		put(acc, CharacterModel.sphere(ra, n, 3), xf(pts[k]))
	put(acc, CharacterModel.sphere(r1, n, 3), xf(pts[pts.size() - 1]))


## Catmull-Rom through pts at t (0..1 over the polyline).
static func crom(pts: Array[Vector3], t: float) -> Vector3:
	var n := pts.size()
	var f := clampf(t, 0.0, 1.0) * float(n - 1)
	var i := mini(int(f), n - 2)
	var u := f - float(i)
	var p0 := pts[maxi(i - 1, 0)]
	var p1 := pts[i]
	var p2 := pts[i + 1]
	var p3 := pts[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)


## A flat lens (scale / leaf / petal / feather): centre c, long axis along (length), across (width), thin.
static func lens(acc: Array, c: Vector3, along: Vector3, across: Vector3, length: float, width: float, thick: float) -> void:
	var z := along.normalized()
	var x := (across - z * across.dot(z)).normalized()
	var y := z.cross(x)
	put(acc, CharacterModel.sphere(0.5, 6, 3), Transform3D(Basis(x * width, y * thick, z * length), c))


## A faceted gem / shard: two pyramids (n sides) base to base along `axis`, radius r, heights up / down.
static func shard(acc: Array, c: Vector3, axis: Vector3, r: float, up: float, down: float, n: int = 6, twist: float = 0.0) -> void:
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var top := c + y * up
	var bot := c - y * down
	var ring: Array[Vector3] = []
	for k: int in n:
		var a := TAU * float(k) / float(n) + twist
		ring.append(c + (x * cos(a) + z * sin(a)) * r)
	for k: int in n:
		var a := ring[k]
		var b := ring[(k + 1) % n]
		tri_flat(acc, a, top, b)
		tri_flat(acc, a, b, bot)


## One ArrayMesh from [[acc, material], ...] (empty accs skipped), cached by key.
static func commit(key: String, surfaces: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for s: Array in surfaces:
		var acc: Array = s[0]
		if (acc[0] as PackedVector3Array).is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc[0]
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_INDEX] = acc[2]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, s[1])
	_cache[key] = am
	return am


# ================================================================ hair

## One swept lock (hair plan 4): 4 Bezier points (root first), `face` = where the flat side looks, width / thick at the
## widest, rings along it, tip material from tip_from (0-1; 1 = none), twist root -> tip (deg). Flat-shaded.
static func lock(body: Array, tip: Array, pts: Array, face: Vector3, width: float, thick: float, rings: int = 5,
		tip_from: float = 1.0, twist: float = 0.0) -> void:
	var sec: Array = []
	for i: int in rings:
		var u := float(i) / float(rings)
		var p := _bez3(pts, u)
		var t := (_bez3(pts, minf(u + 0.02, 1.0)) - _bez3(pts, maxf(u - 0.02, 0.0))).normalized()
		var b := t.cross(face).normalized()
		if b.length() < 0.5:
			b = t.cross(Vector3.UP).normalized()
		var n := b.cross(t).normalized()
		var tw := deg_to_rad(twist * u)
		var bb := b * cos(tw) + n * sin(tw)
		var nn := n * cos(tw) - b * sin(tw)
		var s := lerpf(0.8, 1.0, u / 0.3) if u < 0.3 else lerpf(1.0, 0.3, pow((u - 0.3) / 0.7, 1.2))
		var ring := PackedVector3Array()
		for k: int in LOCK_SIDES:
			var a := TAU * float(k) / float(LOCK_SIDES) + PI * 0.5
			ring.append(p + bb * (cos(a) * width * 0.5 * s) + nn * (sin(a) * thick * 0.5 * s))
		sec.append(ring)
	var end := _bez3(pts, 1.0)
	for i: int in rings:
		var dst: Array = tip if float(i) / float(rings) >= tip_from and not tip.is_empty() else body
		var r0: PackedVector3Array = sec[i]
		if i < rings - 1:
			var r1: PackedVector3Array = sec[i + 1]
			for k: int in LOCK_SIDES:
				var k1 := (k + 1) % LOCK_SIDES
				tri_flat(dst, r0[k], r1[k], r1[k1])
				tri_flat(dst, r0[k], r1[k1], r0[k1])
		else:
			for k: int in LOCK_SIDES:
				tri_flat(dst, r0[k], end, r0[(k + 1) % LOCK_SIDES])
	var r: PackedVector3Array = sec[0]
	for k: int in range(1, LOCK_SIDES - 1):
		tri_flat(body, r[0], r[k + 1], r[k])


## A braid: `lobes` flattened lobes alternating left / right along a Catmull-Rom path, radius r0 -> r1; every
## `bead_every` lobes a bead into `beads` (0 = none). Returns the end point.
static func braid(acc: Array, path: Array[Vector3], lobes: int, r0: float, r1: float, beads: Array = [],
		bead_every: int = 0, bead_r: float = 0.02) -> Vector3:
	var last := path[path.size() - 1]
	for i: int in lobes:
		var t := float(i) / float(maxi(lobes - 1, 1))
		var p := crom(path, t)
		var d := (crom(path, minf(t + 0.02, 1.0)) - crom(path, maxf(t - 0.02, 0.0))).normalized()
		var r := lerpf(r0, r1, t)
		var side := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
		var sgn := 1.0 if i % 2 == 0 else -1.0
		var b := Basis(Quaternion(Vector3.UP, d)) * Basis(Vector3.FORWARD, 0.45 * sgn)
		put(acc, CharacterModel.sphere(r, 6, 3), Transform3D(b.scaled_local(Vector3(1.0, 1.55, 0.8)), p + side * r * 0.35 * sgn))
		if bead_every > 0 and not beads.is_empty() and i % bead_every == bead_every - 1:
			put(beads, CharacterModel.sphere(bead_r, 6, 3), xf(p - side * r * 0.6 * sgn + Vector3(0, 0, 0.004)))
	return last


static func _bez3(p: Array, u: float) -> Vector3:
	var v := 1.0 - u
	return p[0] * v * v * v + p[1] * 3.0 * v * v * u + p[2] * 3.0 * v * u * u + p[3] * u * u * u


# ================================================================ painted face

## A face: centre (model space), arc radius r (2D metres of arc -> angles), the head mesh's triangles relative to the
## centre (after its scale), for the facet projection.
static func face_new(c: Vector3, r: float, head_mesh: Mesh, head_scale: Vector3) -> Dictionary:
	var faces := head_mesh.get_faces()
	var tris := PackedVector3Array()
	for p: Vector3 in faces:
		tris.append(p * head_scale)
	return {"c": c, "r": r, "tris": tris, "sf": {}}


static func face_point(f: Dictionary, p: Vector2, lift: float) -> Array:
	var r: float = f["r"]
	var az := p.x / r
	var el := p.y / r
	var d := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
	var tris: PackedVector3Array = f["tris"]
	var dist := r
	for i: int in range(0, tris.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3.ZERO, d, tris[i], tris[i + 1], tris[i + 2])
		if hit != null:
			dist = (hit as Vector3).length()
			break
	return [(f["c"] as Vector3) + d * (dist + lift), d]


static func _fv(f: Dictionary, key: StringName, p: Vector2, lift: float) -> int:
	var sf: Dictionary = f["sf"]
	if not sf.has(key):
		sf[key] = [PackedVector3Array(), PackedVector3Array(), PackedInt32Array()]
	var s: Array = sf[key]
	var pn := face_point(f, p, lift)
	s[0].append(pn[0])
	s[1].append(pn[1])
	return (s[0] as PackedVector3Array).size() - 1


static func _ftri(f: Dictionary, key: StringName, a: int, b: int, c: int) -> void:
	var s: Array = f["sf"][key]
	s[2].append_array(PackedInt32Array([a, b, c, a, c, b]))


static func _resample(pts: PackedVector2Array, step: float, closed: bool) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	var n := pts.size()
	for i: int in range(1, n + (1 if closed else 0)):
		var a := pts[i - 1]
		var b := pts[i % n]
		var k := maxi(1, ceili(a.distance_to(b) / step))
		for j: int in range(1, k + 1):
			out.append(a.lerp(b, float(j) / float(k)))
	if closed:
		out.remove_at(out.size() - 1)
	return out


## A tapered band along a polyline; w = half widths at start / middle / end.
static func face_strip(f: Dictionary, key: StringName, pts: PackedVector2Array, w: Vector3, lift: float) -> void:
	var p := _resample(pts, 0.007, false)
	var n := p.size()
	var acc := PackedFloat32Array([0.0])
	for i: int in range(1, n):
		acc.append(acc[i - 1] + p[i - 1].distance_to(p[i]))
	var total := maxf(acc[n - 1], 0.0001)
	var pa := -1
	var pb := -1
	for i: int in n:
		var t := acc[i] / total
		var hw := lerpf(w.x, w.y, t * 2.0) if t < 0.5 else lerpf(w.y, w.z, t * 2.0 - 1.0)
		var dir := (p[mini(i + 1, n - 1)] - p[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		var ia := _fv(f, key, p[i] + nrm * hw, lift)
		var ib := _fv(f, key, p[i] - nrm * hw, lift)
		if pa >= 0:
			_ftri(f, key, pa, pb, ib)
			_ftri(f, key, pa, ib, ia)
		pa = ia
		pb = ib


## A filled star-shaped polygon (centroid fan, 1-2 rings so it follows the facets).
static func face_fill(f: Dictionary, key: StringName, poly: PackedVector2Array, lift: float) -> void:
	var b := _resample(poly, 0.009, true)
	var c := Vector2.ZERO
	for q: Vector2 in poly:
		c += q
	c /= float(poly.size())
	var n := b.size()
	var rings := 1 if float(n) * 0.009 < 0.06 else 2
	var ci := _fv(f, key, c, lift)
	var prev: Array[int] = []
	for r: int in range(1, rings + 1):
		var ring: Array[int] = []
		for k: int in n:
			ring.append(_fv(f, key, c.lerp(b[k], float(r) / float(rings)), lift))
		for k: int in n:
			var k2 := (k + 1) % n
			if r == 1:
				_ftri(f, key, ci, ring[k], ring[k2])
			else:
				_ftri(f, key, prev[k], ring[k], ring[k2])
				_ftri(f, key, prev[k], ring[k2], prev[k2])
		prev = ring


## An open eye at c (mirrored by sx): almond (key "white", half width hw, top / bottom, outer corner lifted by tilt),
## iris ("iris", radius ir), pupil ("pupil"), highlight ("hi"), upper lash line with a small flick ("lash").
## keys: Dictionary with those names -> surface keys ("" = skip that layer).
static func face_eye(f: Dictionary, c: Vector2, hw: float, top: float, bot: float, tilt: float, ir: float, sx: float,
		keys: Dictionary) -> void:
	var up := PackedVector2Array()
	var lo := PackedVector2Array()
	for i: int in 9:
		var t := float(i) / 8.0
		var x := c.x - hw + 2.0 * hw * t
		var ty := c.y + tilt * (t - 0.5)
		up.append(Vector2(x, ty + top * sin(PI * t)))
		lo.append(Vector2(x, ty - bot * sin(PI * t)))
	var poly := PackedVector2Array(up)
	lo.reverse()
	poly.append_array(lo.slice(1, lo.size() - 1))
	face_fill(f, keys["white"], mirror(poly, sx), 0.0025)
	var ic := c + Vector2(0.001, (top - bot) * 0.25)
	if String(keys.get("iris", "")) != "":
		face_fill(f, keys["iris"], mirror(ellipse(ic, Vector2(ir, minf(ir, (top + bot) * 0.5)), 0.0, 12), sx), 0.0034)
	face_fill(f, keys["pupil"], mirror(ellipse(ic, Vector2(ir * 0.5, minf(ir, top) * 0.55), 0.0, 10), sx), 0.0042)
	face_fill(f, keys["hi"], mirror(ellipse(ic + Vector2(ir * 0.35, ir * 0.35), Vector2(ir * 0.3, ir * 0.3), 0.0, 8), sx), 0.0052)
	var lash := PackedVector2Array(up)
	lash.append(up[8] + Vector2(0.010, 0.008))
	face_strip(f, keys["lash"], mirror(lash, sx), Vector3(0.0022, 0.0055, 0.0018), 0.0048)


## The face's surfaces in `order` with their materials -> ArrayMesh (appended to `into` when given), cached by key.
static func face_commit(f: Dictionary, key: String, order: Array, mats: Dictionary, into: ArrayMesh = null) -> ArrayMesh:
	var am := into if into else ArrayMesh.new()
	var sf: Dictionary = f["sf"]
	for k: StringName in order:
		if not sf.has(k):
			continue
		var s: Array = sf[k]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s[0]
		arrays[Mesh.ARRAY_NORMAL] = s[1]
		arrays[Mesh.ARRAY_INDEX] = s[2]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, mats[k])
	_cache[key] = am
	return am


## Quadratic Bezier p0 -> p2 (control p1), 12 segments.
static func bez(p0: Vector2, p1: Vector2, p2: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in 13:
		var t := float(i) / 12.0
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


static func ellipse(c: Vector2, r: Vector2, rot_deg: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var b := Transform2D(rot_deg * DEG, Vector2.ZERO)
	for i: int in n:
		var a := TAU * float(i) / float(n)
		out.append(c + b * Vector2(cos(a) * r.x, sin(a) * r.y))
	return out


static func mirror(pts: PackedVector2Array, sx: float) -> PackedVector2Array:
	if sx > 0.0:
		return pts
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(Vector2(-p.x, p.y))
	return out


# ================================================================ gestures (19.V10 set)

static func is_gesture(id: StringName) -> bool:
	return GESTURES.has(id)


## Writes the gesture's offsets for time t (s) on model m; returns the length (s). kneel holds while `hold` is true.
static func gesture_pose(m: CharacterModel, id: StringName, t: float, hold: bool) -> float:
	match id:
		&"point":
			var k := CharacterModel._k3(t, 0.0, 0.30, 1.10, 1.50, 1.0, 1.0)
			m.rot(CharacterModel.P_ARM_L, Vector3(-82.0 * DEG * k, 0, 14.0 * DEG * k))
			m.rot(CharacterModel.P_CHEST, Vector3(-3.0 * DEG * k, -12.0 * DEG * k, 0))
			m.rot(CharacterModel.P_HEAD, Vector3(-5.0 * DEG * k, 8.0 * DEG * k, 0))
			return 1.5
		&"nod":
			var k := CharacterModel._k3(t, 0.0, 0.16, 0.26, 0.42, 1.0, 0.3) + CharacterModel._k3(t, 0.42, 0.58, 0.64, 0.9, 0.8, 0.0)
			m.rot(CharacterModel.P_HEAD, Vector3(16.0 * DEG * k, 0, 0))
			m.rot(CharacterModel.P_CHEST, Vector3(3.0 * DEG * k, 0, 0))
			return 0.9
		&"kneel", &"stand_up":
			var k := smoothstep(0.0, 0.7, t)
			if id == &"stand_up":
				k = 1.0 - smoothstep(0.0, 0.8, t)
			kneel_weights(m, k)
			if id == &"kneel":
				return 1.0e9 if hold else 0.7
			return 0.8
		&"raise_weapon":
			var k := CharacterModel._k3(t, 0.0, 0.35, 1.15, 1.60, 1.0, 1.0)
			m.rot(CharacterModel.P_ARM_R, Vector3(-30.0 * DEG * k, 0, 48.0 * DEG * k))
			m.pos(CharacterModel.P_ARM_R, Vector3(0, 0.08 * k, 0.03 * k))
			m.rot(CharacterModel.P_ARM_L, Vector3(-20.0 * DEG * k, 0, -38.0 * DEG * k))
			m.rot(CharacterModel.P_CHEST, Vector3(-8.0 * DEG * k, 0, 0))
			m.rot(CharacterModel.P_HEAD, Vector3(-14.0 * DEG * k, 0, 0))
			m.pos(CharacterModel.P_ROOT, Vector3(0, 0.03 * k, 0))
			return 1.6
	return 0.0


## The kneel pose at weight k (one knee down, head bowed, the free hand on the knee): also the fall / revive base.
static func kneel_weights(m: CharacterModel, k: float) -> void:
	m.pos(CharacterModel.P_ROOT, Vector3(0, -0.32 * k, 0.03 * k))
	m.rot(CharacterModel.P_LEG_L, Vector3(-30.0 * DEG * k, 0, 0))
	m.rot(CharacterModel.P_LEG_R, Vector3(22.0 * DEG * k, 0, 0))
	m.rot(CharacterModel.P_CHEST, Vector3(12.0 * DEG * k, 0, 0))
	m.rot(CharacterModel.P_HEAD, Vector3(16.0 * DEG * k, 0, 0))
	m.rot(CharacterModel.P_ARM_L, Vector3(-24.0 * DEG * k, 0, 6.0 * DEG * k))
	m.rot(CharacterModel.P_ARM_R, Vector3(-8.0 * DEG * k, 0, 0))
