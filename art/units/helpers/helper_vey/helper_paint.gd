extends RefCounted
## Shared mesh builders of the T3 helper models (Old Vey, Mother Hush; t3-helpers.md 10.1). No class_name on purpose
## (the kit hair builder of hair-redesign-plan H0 will own the HairKit name): preload this file.
##  - HAIR LOCKS (hair-redesign-plan 2 / 4, the mock builder): a flattened pentagon section swept along a cubic Bezier,
##    swelling after the root and tapering to a point, optional twist, flat-shaded; the last part takes a tip material.
##  - FACE DECALS (Vessa's smile-pass technique, parametrised): painted features projected onto a low-poly face mesh
##    (a sphere, optionally scaled into an oval mask), 2-6 mm above its facets, both windings.
## Everything is in MODEL space (feet origin). Callers cache the resulting ArrayMesh per type (static dictionaries).

const SIDES := 5


# ================================================================ hair locks

## Two SurfaceTools ready for lock(); finish() commits them into one ArrayMesh (2 surfaces, materials set).
static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0xFFFFFFFF)   # flat shading
	return st


static func finish(st_body: SurfaceTool, body_mat: Material, st_tip: SurfaceTool, tip_mat: Material) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for pair: Array in [[st_body, body_mat], [st_tip, tip_mat]]:
		var st: SurfaceTool = pair[0]
		if st == null:
			continue
		st.generate_normals()
		st.set_material(pair[1])
		st.commit(mesh)
	return mesh


## One lock. pts = 4 Bezier control points (root first). face = the direction the flat side looks. width / thick in
## metres at the widest; rings = sections (4-6); tip_from = 0-1 where the tip material starts (1 = none); twist in deg.
static func lock(st_body: SurfaceTool, st_tip: SurfaceTool, pts: Array, face: Vector3, width: float, thick: float,
		rings: int = 4, tip_from: float = 1.0, twist: float = 0.0) -> void:
	var sec: Array = []
	for i: int in rings:
		var u := float(i) / float(rings)
		var p := bez3(pts, u)
		var t := (bez3(pts, minf(u + 0.02, 1.0)) - bez3(pts, maxf(u - 0.02, 0.0))).normalized()
		var b := t.cross(face).normalized()
		if b.length() < 0.5:
			b = t.cross(Vector3.UP).normalized()
		var n := b.cross(t).normalized()
		var tw := deg_to_rad(twist * u)
		var bb := b * cos(tw) + n * sin(tw)
		var nn := n * cos(tw) - b * sin(tw)
		var s := _profile(u)
		var ring := PackedVector3Array()
		for k: int in SIDES:
			var a := TAU * float(k) / float(SIDES) + PI * 0.5
			ring.append(p + bb * (cos(a) * width * 0.5 * s) + nn * (sin(a) * thick * 0.5 * s))
		sec.append(ring)
	var tip := bez3(pts, 1.0)
	for i: int in rings:
		var u0 := float(i) / float(rings)
		var st := st_tip if u0 >= tip_from and st_tip != null else st_body
		var r0: PackedVector3Array = sec[i]
		if i < rings - 1:
			var r1: PackedVector3Array = sec[i + 1]
			for k: int in SIDES:
				var k1 := (k + 1) % SIDES
				_tri(st, r0[k], r1[k], r1[k1])
				_tri(st, r0[k], r1[k1], r0[k1])
		else:
			for k: int in SIDES:
				_tri(st, r0[k], tip, r0[(k + 1) % SIDES])
	var r: PackedVector3Array = sec[0]
	for k: int in range(1, SIDES - 1):
		_tri(st_body, r[0], r[k + 1], r[k])


static func _profile(u: float) -> float:
	if u < 0.3:
		return lerpf(0.8, 1.0, u / 0.3)
	return lerpf(1.0, 0.3, pow((u - 0.3) / 0.7, 1.2))


static func bez3(p: Array, u: float) -> Vector3:
	var v := 1.0 - u
	return p[0] * v * v * v + p[1] * 3.0 * v * v * u + p[2] * 3.0 * v * u * u + p[3] * u * u * u


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


## A flat-shaded solid swept along points (blades, sickles, lightning): per point a half width w (x) and half thickness
## (y) of a lens section (4 sides) in the plane given by `side` (width axis); the last point closes into a tip.
static func sweep(st: SurfaceTool, pts: PackedVector3Array, half: PackedVector2Array, side: Vector3) -> void:
	var rings: Array = []
	var n := pts.size()
	for i: int in n:
		var t := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var w := (side - t * side.dot(t)).normalized()
		var th := t.cross(w).normalized()
		var h: Vector2 = half[i]
		rings.append(PackedVector3Array([pts[i] + w * h.x, pts[i] + th * h.y, pts[i] - w * h.x, pts[i] - th * h.y]))
	for i: int in n - 1:
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for k: int in 4:
			var k1 := (k + 1) % 4
			_tri(st, r0[k], r1[k], r1[k1])
			_tri(st, r0[k], r1[k1], r0[k1])
	var a: PackedVector3Array = rings[0]
	_tri(st, a[0], a[2], a[1])
	_tri(st, a[0], a[3], a[2])


# ================================================================ face decals

## A face context: centre (model space), radius, the face mesh's triangles (centred on the origin, scale applied).
static func face_ctx(centre: Vector3, radius: float, face_mesh: Mesh, scl: Vector3 = Vector3.ONE) -> Dictionary:
	var tris := face_mesh.get_faces()
	for i: int in tris.size():
		tris[i] = tris[i] * scl
	return {"c": centre, "r": radius, "tris": tris, "sf": {}}


## Commit the painted surfaces in `order` ([[name, Material], ...]) into `am` (a new mesh when null).
static func face_commit(ctx: Dictionary, order: Array, am: ArrayMesh = null) -> ArrayMesh:
	if am == null:
		am = ArrayMesh.new()
	var sf: Dictionary = ctx["sf"]
	for pair: Array in order:
		var key: StringName = pair[0]
		if not sf.has(key):
			continue
		var s: Array = sf[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s[0]
		arrays[Mesh.ARRAY_NORMAL] = s[1]
		arrays[Mesh.ARRAY_INDEX] = s[2]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, pair[1])
	return am


## Face 2D point (metres of arc from the face centre, +x = model +X, +y = up) -> [model point, normal].
static func face_point(ctx: Dictionary, p: Vector2, lift: float) -> Array:
	var r: float = ctx["r"]
	var az := p.x / r
	var el := p.y / r
	var d := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
	var dist := r
	var tris: PackedVector3Array = ctx["tris"]
	for i: int in range(0, tris.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3.ZERO, d, tris[i], tris[i + 1], tris[i + 2])
		if hit != null:
			dist = (hit as Vector3).length()
			break
	return [(ctx["c"] as Vector3) + d * (dist + lift), d]


static func _fv(ctx: Dictionary, mat: StringName, p: Vector2, lift: float) -> int:
	var sf: Dictionary = ctx["sf"]
	if not sf.has(mat):
		sf[mat] = [PackedVector3Array(), PackedVector3Array(), PackedInt32Array()]
	var s: Array = sf[mat]
	var pn := face_point(ctx, p, lift)
	var v: PackedVector3Array = s[0]
	var nm: PackedVector3Array = s[1]
	v.append(pn[0])
	nm.append(pn[1])
	s[0] = v
	s[1] = nm
	return v.size() - 1


static func _ftri(ctx: Dictionary, mat: StringName, a: int, b: int, c: int) -> void:
	var s: Array = ctx["sf"][mat]
	var idx: PackedInt32Array = s[2]
	idx.append_array(PackedInt32Array([a, b, c, a, c, b]))
	s[2] = idx


static func bez(p0: Vector2, p1: Vector2, p2: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in 13:
		var t := float(i) / 12.0
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


static func ellipse(c: Vector2, r: Vector2, rot_deg: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var b := Transform2D(deg_to_rad(rot_deg), Vector2.ZERO)
	for i: int in n:
		var a := TAU * float(i) / float(n)
		out.append(c + b * Vector2(cos(a) * r.x, sin(a) * r.y))
	return out


## Mirror face points to the other side (sx = -1).
static func fm(pts: PackedVector2Array, sx: float) -> PackedVector2Array:
	if sx > 0.0:
		return pts
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(Vector2(-p.x, p.y))
	return out


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
static func strip(ctx: Dictionary, mat: StringName, pts: PackedVector2Array, w: Vector3, lift: float) -> void:
	var p := _resample(pts, 0.008, false)
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
		var ia := _fv(ctx, mat, p[i] + nrm * hw, lift)
		var ib := _fv(ctx, mat, p[i] - nrm * hw, lift)
		if pa >= 0:
			_ftri(ctx, mat, pa, pb, ib)
			_ftri(ctx, mat, pa, ib, ia)
		pa = ia
		pb = ib


## A filled star-shaped polygon (centroid fan, 1-2 rings so the decal follows the facets).
static func fill(ctx: Dictionary, mat: StringName, poly: PackedVector2Array, lift: float) -> void:
	var b := _resample(poly, 0.010, true)
	var c := Vector2.ZERO
	for q: Vector2 in poly:
		c += q
	c /= float(poly.size())
	var n := b.size()
	var rings := 1 if float(n) * 0.010 < 0.06 else 2
	var ci := _fv(ctx, mat, c, lift)
	var prev: Array[int] = []
	for r: int in range(1, rings + 1):
		var ring: Array[int] = []
		for k: int in n:
			ring.append(_fv(ctx, mat, c.lerp(b[k], float(r) / float(rings)), lift))
		for k: int in n:
			var k2 := (k + 1) % n
			if r == 1:
				_ftri(ctx, mat, ci, ring[k], ring[k2])
			else:
				_ftri(ctx, mat, prev[k], ring[k], ring[k2])
				_ftri(ctx, mat, prev[k], ring[k2], prev[k2])
		prev = ring


## An almond (eye / slit) polygon: centre c, half width hw, top / bottom heights, outer corner lift `tilt`.
static func almond(c: Vector2, hw: float, top: float, bot: float, tilt: float) -> PackedVector2Array:
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
	return poly


# ================================================================ particles (shared, cached per key)

static var _proc: Dictionary = {}
static var _draw: Dictionary = {}

## Soft round additive sparks / motes. col0 -> col1 over the life; `blend_mix` = alpha smoke instead of additive.
static func motes(key: String, amount: int, lifetime: float, radius: float, speed: float, size: float, one_shot: bool,
		col0: Color, col1: Color, gravity: Vector3, blend_mix: bool = false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.emitting = not one_shot
	p.explosiveness = 0.9 if one_shot else 0.0
	p.randomness = 0.4
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2, -1.5, -2), Vector3(4, 4, 4))
	var pm: ParticleProcessMaterial = _proc.get(key)
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = radius
		pm.direction = Vector3.UP
		pm.spread = 180.0 if one_shot else 35.0
		pm.initial_velocity_min = speed * 0.5
		pm.initial_velocity_max = speed
		pm.gravity = gravity
		pm.damping_min = 0.5
		pm.damping_max = 1.5
		var sc := Curve.new()
		sc.add_point(Vector2(0, 0.5))
		sc.add_point(Vector2(0.25, 1.0))
		sc.add_point(Vector2(1, 0.25 if not blend_mix else 1.4))
		var ct := CurveTexture.new()
		ct.curve = sc
		pm.scale_curve = ct
		var g := Gradient.new()
		g.set_color(0, col0)
		g.set_color(1, col1)
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		_proc[key] = pm
	p.process_material = pm
	var dkey := "%s|%s" % [size, blend_mix]
	var q: QuadMesh = _draw.get(dkey)
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(size, size)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_MIX if blend_mix else BaseMaterial3D.BLEND_MODE_ADD
		sm.disable_fog = not blend_mix  # G-E 5: an additive quad must not fog
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.vertex_color_use_as_albedo = true
		sm.albedo_color = Color(1, 1, 1, 1) if blend_mix else Color(2.2, 2.1, 1.8, 1.0)
		var rg := Gradient.new()
		rg.set_color(0, Color(1, 1, 1, 1))
		rg.set_color(1, Color(1, 1, 1, 0))
		rg.add_point(0.4, Color(1, 1, 1, 0.75))
		var tex := GradientTexture2D.new()
		tex.gradient = rg
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 32
		tex.height = 32
		sm.albedo_texture = tex
		q.material = sm
		_draw[dkey] = q
	p.draw_pass_1 = q
	return p
