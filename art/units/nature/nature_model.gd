class_name NatureModel
extends CharacterModel
## Shared Nature army layer on top of the kit (kingdom-nature.md 7.2, tasks 8.V3 / 8.V4). Per-unit scripts extend it
## (sprigling.gd, thornling.gd, sapling.gd and the 8.V4 units). Stable API, safe to use from every Nature unit:
##   nature(&"nature_cloth")           Nature palette material (art/units/nature/materials/), falls back to the kit palette.
##   add_limb(pivot, a, b, r, mat, end_r, end_mat)   capsule from model point a to b (+ optional sphere at b).
##   add_thorns(pivot, centre, n, ring_r, r, h, tilt_deg, mat, phase_deg)   ring of thorn cones leaning outward
##       (ONE authored part: the cones are baked into one cached mesh).
##   add_leaf(pivot, at, size, mat, rot_deg, keep_separate, name)   one flat leaf: size = (width, thickness, length),
##       unrotated it lies flat and points +Z.
##   add_leaf_crown(pivot, centre, n, ring_r, size, tilt_deg, mat, phase_deg)   ring of leaves, bases on the ring,
##       tips outward; tilt 0 = flat, + up, - hanging down (ONE authored part).
## Static mesh builders (usable from any CharacterModel, e.g. Ysolde who extends WizardModel):
##   NatureModel.leaf_ring_mesh(n, ring_r, size, tilt_deg, phase_deg), thorn_ring_mesh(n, ring_r, r, h, tilt_deg, phase_deg),
##   NatureModel.cluster_mesh(key, base_mesh, xforms)   n copies of a primitive baked into one cached mesh.
##   NatureModel.leaf_xform(base, dir, size, tilt_deg)  transform of one leaf (for cluster_mesh with leaf_mesh()).
##   NatureModel.make_petals(color, amount, lifetime, emit_radius, fall_speed, size, one_shot)   drifting petals /
##       leaves (alpha, not additive; shared resources per colour).
## Palette (kingdom-nature.md 7): nature_cloth (team), nature_cloth_dark, nature_cape, nature_skin (bark-tan),
## nature_bark ("metal"), nature_bark_dark (dark base), nature_leaf, nature_leaf_dark, nature_blossom, nature_glow,
## nature_glow_hero, nature_moss, nature_thorn, nature_hair, nature_stone, nature_wither (Sapling end),
## nature_sec_<unit> (secondary cloth per unit; 8.V4 adds its own nature_sec_* files next to them).
## Team colour: nature_cloth / nature_cloth_dark / nature_cape are recoloured by set_team_color like the kit's cloth.
## Faces (face rework 2026-09-28): a unit puts its FaceKit rig in `_face` (spec from NatureFaces); the per-frame
## scripts call `_face_tick()` (expression reactions + the bold RTS face) and `_face_reset()` on revive.
## add_limb uses `lean_capsule` (6 x 2 segments, 70 vertices instead of the kit capsule's 162) to pay for the faces.

const NATURE_MAT_DIR := "res://art/units/nature/materials/"
const NATURE_GLOW := Color(0.75, 1.0, 0.40)
const NATURE_TEAM := Color(0.35, 0.70, 0.25)

static var _nature_cache: Dictionary = {}

var _face: FaceRig


## Nature palette material by name (loaded once, shared). Unknown names fall back to the kit palette.
static func nature(name: StringName) -> Material:
	if not _nature_cache.has(name):
		var p := NATURE_MAT_DIR + String(name) + ".tres"
		_nature_cache[name] = load(p) if ResourceLoader.exists(p) else palette(name)
	return _nature_cache[name]


## Capsule limb from model point a to b (radius r), plus an optional end sphere (fist / foot) at b.
func add_limb(pivot: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, end_r: float = 0.0,
		end_mat: Material = null) -> void:
	var d := b - a
	var e := Basis(Quaternion(Vector3.DOWN, d.normalized())).get_euler() * (180.0 / PI)
	add_part(pivot, lean_capsule(r, d.length() + r), mat, a + d * 0.5, e)
	if end_r > 0.0:
		add_part(pivot, sphere(end_r, 8, 4), end_mat if end_mat else mat, b)


## The face rig's per-frame update (call it from the model's _extra_process): reactions at close range, the bold
## far face at the RTS zoom.
func _face_tick() -> void:
	if _face:
		_face.auto(self)


## After a revive: show the requested expression again.
func _face_reset() -> void:
	if _face:
		_face.reset()


## A low capsule (6 radial x 2 ring segments, 70 vertices; the kit's capsule() is 8 x 4 = 162): limbs, thin legs.
static func lean_capsule(r: float, h: float) -> Mesh:
	var key := "leancap%s_%s" % [r, h]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 6
	m.rings = 2
	return _cached(key, m)


## Ring of n thorn cones (6 segments) around `centre` (model space), tips leaning outward by tilt_deg. One part.
func add_thorns(pivot: Node3D, centre: Vector3, n: int, ring_r: float, r: float, h: float, tilt_deg: float,
		mat: Material, phase_deg: float = 0.0) -> void:
	add_part(pivot, thorn_ring_mesh(n, ring_r, r, h, tilt_deg, phase_deg), mat, centre)


## One flat leaf (squashed sphere): size = (width, thickness, length); unrotated it lies flat along +Z.
func add_leaf(pivot: Node3D, at: Vector3, size: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO,
		keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	return add_part(pivot, leaf_mesh(), mat, at, rot_deg, size, keep_separate, part_name)


## Ring of n leaves: bases on the ring (radius ring_r around `centre`), tips outward, tilted by tilt_deg. One part.
func add_leaf_crown(pivot: Node3D, centre: Vector3, n: int, ring_r: float, size: Vector3, tilt_deg: float,
		mat: Material, phase_deg: float = 0.0) -> void:
	add_part(pivot, leaf_ring_mesh(n, ring_r, size, tilt_deg, phase_deg), mat, centre)


# ================================================================ static mesh builders (cached, shared)

## The leaf primitive (cached): a pointed, double-sided lens with a raised mid-rib, spanning -0.5..0.5 on each axis
## (x width, y thickness, z length; the tip at +Z, the widest part a little toward the base). Scale it per leaf.
static func leaf_mesh() -> Mesh:
	const KEY := "nature_leaf_lens"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	const N := 6
	var l := PackedVector3Array()
	var m := PackedVector3Array()
	var r := PackedVector3Array()
	var mb := PackedVector3Array()
	for i: int in N + 1:
		var t := float(i) / float(N)
		var s := sin(PI * pow(t, 0.8))
		var w := 0.5 * s
		var z := t - 0.5
		l.append(Vector3(-w, 0, z))
		r.append(Vector3(w, 0, z))
		m.append(Vector3(0, 0.5 * s, z))
		mb.append(Vector3(0, -0.5 * s, z))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in N:
		var j := i + 1
		# top (clockwise seen from +Y), then the same quads reversed for the underside
		var tri: Array[Vector3] = [l[i], m[i], l[j], m[i], m[j], l[j], m[i], r[i], m[j], r[i], r[j], m[j],
			l[j], mb[i], l[i], l[j], mb[j], mb[i], mb[j], r[i], mb[i], mb[j], r[j], r[i]]
		for k: int in range(0, tri.size(), 3):
			if (tri[k + 1] - tri[k]).cross(tri[k + 2] - tri[k]).length_squared() < 1e-10:
				continue   # the pointed ends make some triangles degenerate
			st.add_vertex(tri[k])
			st.add_vertex(tri[k + 1])
			st.add_vertex(tri[k + 2])
	st.index()          # shared vertices: ~22 per leaf, smooth normals across the rib
	st.generate_normals()
	return _cached(KEY, st.commit())


## Transform of one leaf whose BASE is at `base`, pointing along the horizontal-ish `dir`, tilted up by tilt_deg.
static func leaf_xform(base: Vector3, dir: Vector3, size: Vector3, tilt_deg: float) -> Transform3D:
	var yaw := atan2(dir.x, dir.z)
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -tilt_deg * DEG)
	var tip_dir := b * Vector3.BACK
	return Transform3D(b.scaled_local(size), base + tip_dir * size.z * 0.5)


static func leaf_ring_mesh(n: int, ring_r: float, size: Vector3, tilt_deg: float, phase_deg: float = 0.0) -> Mesh:
	var key := "leafring%d_%s_%s_%s_%s" % [n, ring_r, size, tilt_deg, phase_deg]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var xs: Array[Transform3D] = []
	for i: int in n:
		var a := TAU * float(i) / float(n) + phase_deg * DEG
		var out := Vector3(sin(a), 0, cos(a))
		xs.append(leaf_xform(out * ring_r, out, size, tilt_deg))
	return cluster_mesh(key, leaf_mesh(), xs)


static func thorn_ring_mesh(n: int, ring_r: float, r: float, h: float, tilt_deg: float, phase_deg: float = 0.0) -> Mesh:
	var key := "thornring%d_%s_%s_%s_%s_%s" % [n, ring_r, r, h, tilt_deg, phase_deg]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var xs: Array[Transform3D] = []
	for i: int in n:
		var a := TAU * float(i) / float(n) + phase_deg * DEG
		var out := Vector3(sin(a), 0, cos(a))
		var b := Basis(Vector3.UP.cross(out).normalized(), tilt_deg * DEG)
		xs.append(Transform3D(b, out * ring_r + b * Vector3(0, h * 0.5, 0)))
	return cluster_mesh(key, cyl(0.0, r, h, 6, false), xs)   # base caps hidden in the body (face budget)


## Bakes one copy of `base` (surface 0) per transform into a single cached ArrayMesh (no negative scales).
static func cluster_mesh(key: String, base: Mesh, xforms: Array[Transform3D]) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var arr := base.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for xf: Transform3D in xforms:
		var nb := xf.basis.inverse().transposed()
		var b0 := verts.size()
		for j: int in v.size():
			verts.append(xf * v[j])
			norms.append((nb * nr[j]).normalized())
		if ix.is_empty():
			for j: int in v.size():
				idx.append(b0 + j)
		else:
			for j: int in ix.size():
				idx.append(b0 + ix[j])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _cached(key, am)


## Drifting petals / leaves: alpha-blended (not additive) billboards that flutter down. Looping (one_shot false:
## stops beyond 45 m through the kit) or a pre-built one-shot burst (restart()).
static func make_petals(color: Color, amount: int, lifetime: float, emit_radius: float, fall_speed: float, size: float,
		one_shot: bool = false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.emitting = not one_shot
	p.explosiveness = 0.85 if one_shot else 0.0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2.5, -3.0, -2.5), Vector3(5, 5, 5))
	var key := "petals%s_%s_%s_%s" % [emit_radius, fall_speed, one_shot, lifetime]
	var pm: ParticleProcessMaterial = _mat_cache.get(key)
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = emit_radius
		pm.direction = Vector3.UP
		pm.spread = 180.0 if one_shot else 80.0
		pm.initial_velocity_min = 0.6 if one_shot else 0.15
		pm.initial_velocity_max = 1.6 if one_shot else 0.45
		pm.gravity = Vector3(0, -fall_speed, 0)
		pm.damping_min = 0.8
		pm.damping_max = 1.4
		pm.angle_min = -180.0
		pm.angle_max = 180.0
		pm.angular_velocity_min = -160.0
		pm.angular_velocity_max = 160.0
		pm.scale_min = 0.7
		pm.scale_max = 1.2
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.12, Color(1, 1, 1, 1))
		g.add_point(0.75, Color(1, 1, 1, 1))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		_mat_cache[key] = pm
	p.process_material = pm
	var dkey := "petaldraw%s_%s" % [color.to_html(), size]
	var q: QuadMesh = _mesh_cache.get(dkey)
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(size, size * 0.6)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true   # A.17: per-particle scale is ignored without it (Godot 4.7)
		sm.vertex_color_use_as_albedo = true
		sm.albedo_color = color
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		sm.albedo_texture = _petal_tex()
		q.material = sm
		_mesh_cache[dkey] = q
	p.draw_pass_1 = q
	return p


## Soft oval petal mask (radial gradient, hard-ish edge), shared by every petal material.
static func _petal_tex() -> Texture2D:
	var t: GradientTexture2D = _mat_cache.get("petal_tex")
	if t == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.72, Color(1, 1, 1, 1))
		g.add_point(0.86, Color(0.85, 0.85, 0.85, 0.0))
		t = GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 32
		t.height = 32
		_mat_cache["petal_tex"] = t
	return t