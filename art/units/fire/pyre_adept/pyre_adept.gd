extends FireModel
## Pyre Adept, Fire T2 anti-swarm caster (rush-balance.md 5.1 / 5.4, task 16.V2). Height 1.7, staff top 2.75 m.
## A robed pyromancer: long team-colour cassock with a bronze hem, a deep crimson hood and shoulder mantle (no hat, no
## cape: Vessa owns the witch-crown hat, the cape and the floating caged sun), a gold stole down the front. The
## silhouette hook: a tall wooden staff held high in the right hand, crowned by an open bronze brazier on three
## prongs with a fire burning in it (the only glow point, high up so it reads over the crowd at 40 m).
## Attack `caster_fire` (release 0.15 s): the staff tips the brazier at the target, a spit of sparks, left palm pushes.
## play_cast(&"flame_burst") (0.9 s): the staff is hoisted, the bowl flares (flame x1.9, glow x3), then driven down
## toward the burst point with a big spark burst. Death: FireModel's burn; the bowl fire gutters out.
## Draws: merged pivots + BowlFire (keep_separate, own_glow) + blob + hidden vet trim; 3 particle systems.

const STAFF_X := 0.33
const STAFF_Z := 0.22
const HAND_R := Vector3(0.33, 1.20, 0.22)
const HAND_L := Vector3(-0.29, 1.03, 0.19)
const BOWL_Y := 2.46
const CAST_LEN := 0.9
const CAST_RELEASE := 0.40
const FIRE_GLOW := 1.3        # idle glow_boost of the bowl fire (the kit does not boost own_glow parts)

# caster_fire: brazier tipped at the target. Arm x: + tips the staff top forward (the staff points UP from the fist).
static var P_ARM_R_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -14.0, 1, 0.15, 34.0, 2, 0.30, 28.0, 0, 0.60, 0.0, 0])
static var P_ARM_L_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -20.0, 1, 0.15, -72.0, 2, 0.34, -60.0, 0, 0.60, 0.0, 0])
static var P_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -8.0, 1, 0.15, 12.0, 2, 0.34, 8.0, 0, 0.60, 0.0, 0])
static var P_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 10.0, 1, 0.15, -12.0, 2, 0.34, -6.0, 0, 0.60, 0.0, 0])
static var P_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.04, 1, 0.15, 0.10, 2, 0.34, 0.07, 0, 0.60, 0.0, 0])
# Flame Burst: hoist (staff straight up, lifted), flare, drive it down toward the point.
static var C_ARM_R_X := PackedFloat32Array([0.0, 0.0, 0, 0.28, -12.0, 1, 0.34, -16.0, 0, 0.40, 40.0, 2, 0.62, 32.0, 0, 0.90, 0.0, 0])
static var C_ARM_R_Y := PackedFloat32Array([0.0, 0.0, 0, 0.28, 0.24, 1, 0.34, 0.26, 0, 0.40, 0.0, 2, 0.90, 0.0, 0])
static var C_ARM_L_X := PackedFloat32Array([0.0, 0.0, 0, 0.28, -140.0, 1, 0.40, -80.0, 2, 0.62, -70.0, 0, 0.90, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.28, -12.0, 1, 0.40, 16.0, 2, 0.62, 10.0, 0, 0.90, 0.0, 0])
static var C_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.28, 0.05, 1, 0.40, -0.06, 2, 0.62, -0.04, 0, 0.90, 0.0, 0])
static var C_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.26, 1.0, 1, 0.46, 1.0, 0, 0.90, 0.0, 0])

var _fire: MeshInstance3D
var _spit: GPUParticles3D
var _flare_fx: GPUParticles3D
var _embers: GPUParticles3D
var _flare: float = 0.0        # 0..1 extra flame (attack spit / cast flare)
var _glow_v: float = -1.0
var _cast_fired: bool = false


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := palette(&"fire_cloth")
	var cdark := palette(&"fire_cloth_dark")
	var gold := palette(&"fire_sec_archer")
	var robe := palette(&"fire_leather")
	var bronze := palette(&"fire_bronze")
	var leather := palette(&"fire_leather")
	var wood := palette(&"fire_wood")
	var skin := palette(&"fire_skin")
	# ---- Legs: only the boots show under the hem.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, cyl(0.065, 0.075, 0.42, 8), leather, Vector3(0.11 * sx, 0.30, 0.0))
		add_part(leg, sphere(0.08, 6, 4), leather, Vector3(0.11 * sx, 0.07, 0.07), Vector3.ZERO, Vector3(1.0, 0.7, 1.6))
	# ---- Hips: the long team cassock (a flared cone to the ankles), bronze hem, dark front panel, belt.
	add_part(hips, cyl(0.21, 0.43, 0.74, 10), robe, Vector3(0, 0.53, 0))
	add_part(hips, torus(0.40, 0.46, 8), bronze, Vector3(0, 0.17, 0), Vector3.ZERO, Vector3(1.0, 1.4, 1.0))
	add_part(hips, cyl(0.07, 0.12, 0.66, 8), cdark, Vector3(0, 0.50, 0.30), Vector3(-15.5, 0, 0), Vector3(1.3, 1.0, 0.45))
	add_part(hips, cyl(0.235, 0.235, 0.08, 8), leather, Vector3(0, 0.89, 0.01), Vector3(9, 0, -4))
	add_part(hips, sphere(0.06, 6, 3), bronze, Vector3(0, 0.90, 0.23), Vector3.ZERO, Vector3(1.0, 0.9, 0.5))
	add_part(hips, sphere(0.08, 6, 3), leather, Vector3(-0.20, 0.80, 0.12), Vector3.ZERO, Vector3(0.8, 1.0, 0.6))
	add_part(hips, cyl(0.05, 0.05, 0.02, 8), bronze, Vector3(0.17, 0.78, 0.17), Vector3(80, 0, 35))
	# ---- Chest: team torso, crimson shoulder mantle, gold stole hanging down the front (vertical accent).
	add_part(chest, sphere(0.24, 10, 5), cloth, Vector3(0, 1.14, 0), Vector3(8, 0, 0), Vector3(1.0, 1.25, 0.82))
	add_part(chest, cyl(0.13, 0.36, 0.24, 8), cdark, Vector3(0, 1.34, -0.01), Vector3(-7, 0, 3))
	for s: float in [-1.0, 1.0]:
		add_part(chest, cyl(0.04, 0.045, 0.78, 8), gold, Vector3(0.105 * s, 1.02, 0.235), Vector3(-9, 0, 6 * s), Vector3(1.0, 1.0, 0.5))
	for s: float in [-1.0, 1.0]:
		add_part(chest, sphere(0.045, 6, 3), bronze, Vector3(0.09 * s, 1.36, 0.20))
		add_part(chest, cyl(0.0, 0.05, 0.12, 6), gold, Vector3(0.09 * s + 0.03 * s, 0.58, 0.30), Vector3(-9, 0, 6 * s))
	# ---- Head: deep crimson hood with a gold rim round the face, the face in shadow, hood tip falling back.
	add_part(head, sphere(0.18, 10, 5), cdark, Vector3(0, 1.58, -0.01), Vector3.ZERO, Vector3(1.0, 1.08, 1.12))
	add_part(head, cyl(0.0, 0.11, 0.26, 8), cdark, Vector3(0, 1.66, -0.21), Vector3(-118, 0, 0))
	add_part(head, sphere(0.11, 8, 4), skin, Vector3(0, 1.54, 0.12), Vector3.ZERO, Vector3(0.95, 1.05, 0.9))
	# Face (faces pass 2026-09-28): a young pyromancer, black fringe under the hood, ember irises that glow a little
	# (FaceKit, replaces the eye bar).
	var hair := Color(0.10, 0.06, 0.06)
	_face = UnitFaces.attach_lean(self, head, "pyre_adept", {"center": Vector3(0, 1.54, 0.12), "radius": 0.11,
		"head_mesh": sphere(0.11, 8, 4), "head_scale": Vector3(0.95, 1.05, 0.9), "preset": &"bright", "detail": &"low",
		"skin": FIRE_SKIN, "hair": hair, "hair_tip": Color(0.35, 0.10, 0.06), "eyes": Color(1.0, 0.55, 0.12), "ears": &"none",
		"palette": {"iris_glow": 0.45}, "eye": {"c": Vector2(0.040, 0.014)},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, Vector3(0, 1.54, 0.12), 0.11, hair,
			Color(0.35, 0.10, 0.06), 1.0, 0.9)})
	add_part(head, sphere(0.03, 6, 3), skin, Vector3(0, 1.525, 0.217))
	for s: float in [-1.0, 1.0]:
		add_part(head, cyl(0.0, 0.07, 0.22, 6), cdark, Vector3(0.15 * s, 1.47, 0.02), Vector3(0, 0, 180 - 12 * s))
	add_part(head, torus(0.12, 0.16, 8), gold, Vector3(0, 1.57, 0.14), Vector3(78, 0, 0), Vector3(1.0, 1.0, 1.15))
	var trim := add_part(head, torus(0.13, 0.17, 10), palette(&"unit_gold_trim"), Vector3(0, 1.70, -0.02),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: bell sleeve, open hand.
	add_part(arm_l, _path_mesh("pa_arm_l", PackedVector3Array([Vector3(-0.24, 1.38, 0.0), Vector3(-0.30, 1.16, 0.0),
		HAND_L + Vector3(0, 0.08, 0)]), PackedFloat32Array([0.075, 0.07, 0.08])), cloth, Vector3.ZERO)
	add_part(arm_l, cyl(0.075, 0.12, 0.14, 8), cdark, HAND_L + Vector3(0, 0.08, -0.03), Vector3(35, 0, -10))
	add_part(arm_l, sphere(0.06, 6, 4), skin, HAND_L)
	add_part(arm_l, torus(0.10, 0.125, 8), gold, HAND_L + Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1.0, 1.3, 1.0))
	# ---- Right arm: forearm raised forward, the staff held high.
	add_part(arm_r, _path_mesh("pa_arm_r", PackedVector3Array([Vector3(0.24, 1.38, 0.0), Vector3(0.32, 1.12, 0.04),
		HAND_R + Vector3(0, -0.02, -0.08)]), PackedFloat32Array([0.075, 0.07, 0.075])), cloth, Vector3.ZERO)
	add_part(arm_r, cyl(0.075, 0.115, 0.13, 8), cdark, HAND_R + Vector3(0, -0.04, -0.09), Vector3(55, 0, 0))
	add_part(arm_r, sphere(0.06, 6, 4), skin, HAND_R)
	# Staff: dark wood shaft from shin height to the brazier, bronze ferrules.
	add_part(arm_r, cyl(0.04, 0.045, 2.15, 8), wood, Vector3(STAFF_X, 1.29, STAFF_Z))
	add_part(arm_r, cyl(0.055, 0.055, 0.08, 6), bronze, Vector3(STAFF_X, 1.34, STAFF_Z))
	add_part(arm_r, cyl(0.05, 0.03, 0.10, 6), bronze, Vector3(STAFF_X, 0.20, STAFF_Z))
	# Brazier: three prongs curving out from a collar up to an open bowl, a coal bed inside.
	add_part(arm_r, cyl(0.07, 0.05, 0.10, 6), bronze, Vector3(STAFF_X, 2.28, STAFF_Z))
	add_part(arm_r, _prongs_mesh(), bronze, Vector3.ZERO)
	add_part(arm_r, cyl(0.15, 0.07, 0.18, 8, false), bronze, Vector3(STAFF_X, BOWL_Y, STAFF_Z))
	add_part(arm_r, torus(0.13, 0.165, 8), bronze, Vector3(STAFF_X, BOWL_Y + 0.09, STAFF_Z))
	add_part(arm_r, cyl(0.13, 0.07, 0.04, 6), leather, Vector3(STAFF_X, BOWL_Y + 0.04, STAFF_Z))
	# The fire in the bowl (the glow point): driven by this script (flicker, flare), never merged.
	_fire = add_part(arm_r, _fire_mesh(), palette(&"fire_flame"), Vector3(STAFF_X, BOWL_Y + 0.03, STAFF_Z),
		Vector3.ZERO, Vector3.ONE, true, "BowlFire")
	_fire.set_meta(&"own_glow", true)
	var bowl := Vector3(STAFF_X, BOWL_Y + 0.25, STAFF_Z)
	_embers = _particles(arm_r, "BowlEmbers", 5, 1.1, bowl, Vector3(0.08, 0.04, 0.08), 0.9, 0.07, 0.02,
		[Color(2.4, 1.0, 0.3, 1.0), Color(1.6, 0.35, 0.05, 0.0)], false, 20.0, Vector3(0, 0.6, 0))
	_spit = _particles(arm_r, "Spit", 12, 0.45, bowl, Vector3(0.06, 0.06, 0.06), 3.2, 0.12, 0.03,
		[Color(2.6, 1.2, 0.35, 1.0), Color(1.8, 0.4, 0.05, 0.8), Color(0.6, 0.1, 0.02, 0.0)], true, 55.0,
		Vector3(0, -1.5, 0))
	_flare_fx = _particles(arm_r, "Flare", 20, 0.7, bowl, Vector3(0.12, 0.08, 0.12), 3.0, 0.2, 0.05,
		[Color(2.8, 1.3, 0.4, 1.0), Color(2.0, 0.5, 0.08, 0.8), Color(0.6, 0.1, 0.02, 0.0)], true, 70.0,
		Vector3(0, 1.0, 0))
	# ---- Fx: FireModel's burn (restarted when the body glows like a coal).
	var fx: Node3D = $Fx
	var be := _particles(fx, "BurnEmbers", 16, 0.9, Vector3(0, 0.8, 0), Vector3(0.25, 0.4, 0.25), 1.8, 0.16, 0.04,
		[Color(2.6, 0.95, 0.25, 1.0), Color(1.7, 0.36, 0.06, 0.9), Color(0.5, 0.08, 0.02, 0.0)], true, 45.0,
		Vector3(0, 1.2, 0))
	be.set_meta(&"burn_fx", true)
	var ash := _particles(fx, "AshPuff", 8, 1.0, Vector3(0, 0.5, 0), Vector3(0.25, 0.15, 0.25), 0.7, 0.35, 0.9,
		[Color(0.20, 0.16, 0.14, 0.55), Color(0.25, 0.21, 0.19, 0.30), Color(0.3, 0.26, 0.24, 0.0)], true, 60.0,
		Vector3(0, 0.4, 0), false)
	ash.set_meta(&"burn_fx", true)
	ensure_shadow_blob(0.42)


# ================================================================ meshes (cached, model space)

## Tapered tube through `pts` (radii per point), one cached mesh (6 sides, no caps between segments).
static func _path_mesh(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var extra: float = 0.03 if radii[i + 1] > 0.0 else 0.0
		var len_total := d.length() + extra
		var c := cyl(radii[i + 1], radii[i], len_total, seg, i == 0 or i == pts.size() - 2)
		st.append_from(c, 0, Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))
	st.index()
	return _cached(key, st.commit())


## Three bronze prongs from the collar out and up to the bowl's underside.
static func _prongs_mesh() -> Mesh:
	const KEY := "pa_prongs"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for k: int in 3:
		var a: float = TAU * k / 3.0 + 0.5
		var o := Vector3(cos(a), 0, sin(a))
		var c := Vector3(STAFF_X, 0, STAFF_Z)
		var m := _path_mesh("pa_prong_%d" % k, PackedVector3Array([c + Vector3(0, 2.26, 0) + o * 0.04,
			c + Vector3(0, 2.36, 0) + o * 0.12, c + Vector3(0, 2.52, 0) + o * 0.155]), PackedFloat32Array([0.022, 0.02, 0.016]), 4)
		st.append_from(m, 0, Transform3D.IDENTITY)
	st.index()
	return _cached(KEY, st.commit())


## The fire: a fat central tongue and four lower tongues leaning out (origin at the coal bed).
static func _fire_mesh() -> Mesh:
	const KEY := "pa_fire"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.append_from(cyl(0.0, 0.12, 0.44, 7), 0, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6.0)), Vector3(0, 0.22, 0)))
	var hs: Array[float] = [0.30, 0.20, 0.26, 0.17]
	for k: int in 4:
		var a: float = TAU * k / 4.0 + 0.4
		var b := Basis(Vector3(-sin(a), 0, cos(a)), deg_to_rad(-16.0 - 8.0 * k))
		st.append_from(cyl(0.0, 0.06, hs[k], 5), 0, Transform3D(b, Vector3(cos(a) * 0.07, hs[k] * 0.5, sin(a) * 0.07)))
	st.index()
	return _cached(KEY, st.commit())


## Pre-built GPUParticles3D (keep_separate). cols along the life; one_shot = restarted by this script.
func _particles(parent: Node3D, pname: String, amount: int, lifetime: float, model_pos: Vector3, ext: Vector3,
		vel: float, size_a: float, size_b: float, cols: Array, one_shot: bool, spread: float, grav: Vector3,
		additive: bool = true) -> GPUParticles3D:
	var key := "pa_pp_%s" % pname
	var pp: ParticleProcessMaterial = _mat_cache.get(key)
	if pp == null:
		pp = ParticleProcessMaterial.new()
		pp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pp.emission_box_extents = ext
		pp.direction = Vector3.UP
		pp.spread = spread
		pp.initial_velocity_min = vel * 0.6
		pp.initial_velocity_max = vel
		pp.gravity = grav
		pp.damping_min = 0.5
		pp.damping_max = 1.5
		var sc := Curve.new()
		sc.max_value = 4.0
		sc.add_point(Vector2(0, 1.0))
		sc.add_point(Vector2(1, size_b / size_a))
		var sct := CurveTexture.new()
		sct.curve = sc
		pp.scale_curve = sct
		var g := Gradient.new()
		g.set_color(0, cols[0])
		g.set_color(1, cols[cols.size() - 1])
		if cols.size() > 2:
			g.add_point(0.45, cols[1])
		var gt := GradientTexture1D.new()
		gt.gradient = g
		gt.use_hdr = true
		pp.color_ramp = gt
		_mat_cache[key] = pp
	var q: QuadMesh = _mesh_cache.get(key)
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(size_a, size_a)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = mote_texture()
		q.material = m
		_mesh_cache[key] = q
	var gp := GPUParticles3D.new()
	gp.name = pname
	gp.amount = amount
	gp.lifetime = lifetime
	gp.one_shot = one_shot
	gp.emitting = not one_shot
	gp.explosiveness = 0.85 if one_shot else 0.0
	gp.fixed_fps = 30
	gp.interpolate = true
	gp.process_material = pp
	gp.draw_pass_1 = q
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.visibility_aabb = AABB(Vector3(-2, -1.5, -2), Vector3(4, 4, 4))
	gp.position = model_pos - model_origin(parent)
	gp.set_meta(&"keep_separate", true)
	parent.add_child(gp)
	return gp


# ================================================================ motion

func _after_ready() -> void:
	super()
	_write_fire(1.0)


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"caster_fire":
		return super(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, P_ARM_R_X) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, P_CHEST_X) * DEG, _kf(t, P_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _kf(t, P_ROOT_Z)))
	if _tier == 0:
		rot(P_ARM_L, Vector3(_kf(t, P_ARM_L_X) * DEG, 0, 0))
	var rel: float = attack_windup if attack_windup > 0.0 else 0.15
	_flare = 0.5 * smoothstep(0.0, rel, t) * (1.0 - smoothstep(rel + 0.05, 0.5, t))
	if prev < rel and t >= rel:
		_on_action_event(&"release")
	return t < 0.6


func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ARM_R, Vector3(_kf(t, C_ARM_R_X) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, _kf(t, C_ARM_R_Y), 0))
	rot(P_ARM_L, Vector3(_kf(t, C_ARM_L_X) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, C_CHEST_X) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _kf(t, C_ROOT_Y), 0))
	_flare = _kf(t, C_FLARE)
	if not _cast_fired and t >= CAST_RELEASE:
		_cast_fired = true
		if _flare_fx and _tier < 2:
			_flare_fx.restart()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	super(ev)
	match ev:
		&"release":
			if _spit and _tier < 2:
				_spit.restart()
		&"cast_start":
			_cast_fired = false
		&"attack_end", &"cast_end":
			_flare = 0.0
		&"death_glow_off":
			_flare = 0.0
			if _embers:
				_embers.emitting = false


## Glide: the robe hides the legs, a gentle sway, the staff arm steady (the brazier barely moves).
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	if _tier > 0:
		return
	var s: float = sin(TAU * _walk_p)
	rot(P_ROOT, Vector3(4.0 * DEG * w, 0, 0))
	rot(P_HIPS, Vector3(0, 6.0 * DEG * s * w, 0))
	rot(P_CHEST, Vector3(0, -4.0 * DEG * s * w, 0))
	rot(P_ARM_R, Vector3(-6.0 * DEG * s * w, 0, 0))


func _extra_process(dt: float) -> void:
	super(dt)
	if _fire == null:
		return
	if _dead:
		# The bowl gutters out with the burn.
		var k: float = 1.0 - smoothstep(0.1, 0.5, _death_t)
		_fire.scale = Vector3(k, k, k) + Vector3(0.001, 0.001, 0.001)
		_write_fire(k)
		return
	if _action == &"":
		_flare = move_toward(_flare, 0.0, dt * 3.0)
	var f: float = 1.0 + 0.9 * _flare
	if _tier == 0:
		var fl: float = 0.08 * sin(_t * 13.0) + 0.05 * sin(_t * 7.3 + 1.1)
		_fire.scale = Vector3(f - fl * 0.5, f + fl, f - fl * 0.5)
	else:
		_fire.scale = Vector3(f, f, f)
	_write_fire(1.0 + 2.0 * _flare)


func _on_revive() -> void:
	super()
	_flare = 0.0
	if _fire:
		_fire.scale = Vector3.ONE
	if _embers:
		_embers.emitting = true
	_write_fire(1.0)


## The fire's glow (own_glow: the kit does not boost it): x veterancy / haste, 0 when dead.
func _write_fire(v: float) -> void:
	v = snappedf(v * FIRE_GLOW * glow_level(), 0.05)
	if v == _glow_v or _fire == null:
		return
	_glow_v = v
	_fire.set_instance_shader_parameter(&"glow_boost", v)
