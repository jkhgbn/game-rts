extends FireModel
## Cinder Arbalest, Fire T2 heavy crossbow (new-units-12.md 6; tiers wave, medium effort). Height 1.7.
## A Fire arbalester in a long team coat with a leather jerkin, a bronze gorget and a riveted bronze left pauldron,
## a bronze kettle hat with a wide brim (the head read), a pale powder horn on the left hip, a bolt case on the back.
## The silhouette hook: a heavy crossbow held level at the hip, its bronze prod spread 0.85 m across in front, a
## cranequin (gear drum + crank) on the right of the stock. The bolt's ember tip is the glow point.
## Attack `arbalest_shot` (1.4 s, release 0.12 = attack_windup): the crossbow snaps up to the shoulder, looses (the
## bolt vanishes, sparks at the prod, recoil), comes down to the hip nose-down, the crank spins 3 turns while the
## right hand winds, the new bolt drops in at 1.1 s. The cooldown is 2.2 s, so the reload always finishes.
## play_cast(&"piercing_bolt") = a longer aimed shot with a brighter tip. Death: FireModel's fall + burn.
## Draws: merged pivots + Bolt (shaft + tip) + Crank + blob + hidden vet trim; 0 lights.

const ATTACK_LEN := 1.4
const RELEASE := 0.12
const BOLT_BACK := 1.1
const CAST_LEN := 0.9
const SX := 0.16                        # crossbow centre line x
const SY := 1.0                         # stock height (hip)
const HAND_R := Vector3(0.2, 0.97, 0.1)
const HAND_L := Vector3(0.05, 0.99, 0.36)
const HUB := Vector3(0.265, 1.0, 0.0)   # crank axle (along x)
const TIP_GLOW := 3.2                   # own_glow boost of the bolt tip at rest
const GUNMETAL := "res://art/units/fire/cinderlock/materials/fire_gunmetal.tres"

var _bolt: Node3D
var _tip: GeometryInstance3D
var _crank: Node3D
var _shot_sparks: GPUParticles3D
var _bolt_hidden: bool = false
var _crank_a: float = 0.0
var _tip_v: float = -1.0
var _cast_hot: float = 0.0


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
	var leather := palette(&"fire_leather")
	var bronze := palette(&"fire_bronze")
	var wood := palette(&"fire_wood")
	var skin := palette(&"fire_skin")
	var horn := palette(&"fire_sec_worker")
	var gold := palette(&"fire_sec_archer")
	# ---- Legs: team-dark breeches, tall leather boots with bronze cuffs.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _tube("ca_leg_%s" % sx, PackedVector3Array([Vector3(0.11 * sx, 0.9, 0.0),
			Vector3(0.12 * sx, 0.56, 0.03)]), PackedFloat32Array([0.08, 0.068]), 7), cdark, Vector3.ZERO)
		add_part(leg, cyl(0.07, 0.078, 0.42, 7), leather, Vector3(0.12 * sx, 0.3, 0.01))
		add_part(leg, cyl(0.085, 0.085, 0.06, 7), bronze, Vector3(0.12 * sx, 0.5, 0.01))
		add_part(leg, sphere(0.075, 7, 3), leather, Vector3(0.12 * sx, 0.06, 0.07), Vector3.ZERO, Vector3(1.0, 0.7, 1.7))
	# ---- Hips: coat skirts split at the front (two team panels), belt, buckle, powder horn, bolt case.
	for s: float in [-1.0, 1.0]:
		add_part(hips, box(Vector3(0.2, 0.46, 0.05)), cloth, Vector3(0.12 * s, 0.73, 0.14), Vector3(-8, 14 * s, 4 * s))
		add_part(hips, box(Vector3(0.2, 0.5, 0.05)), cloth, Vector3(0.16 * s, 0.72, -0.08), Vector3(8, -65 * s, 0))
	add_part(hips, box(Vector3(0.36, 0.52, 0.05)), cdark, Vector3(0, 0.72, -0.17), Vector3(10, 0, 0))
	add_part(hips, cyl(0.21, 0.23, 0.2, 8), leather, Vector3(0, 0.93, 0.0))
	add_part(hips, cyl(0.235, 0.235, 0.06, 8), bronze, Vector3(0, 0.99, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.95))
	add_part(hips, box(Vector3(0.09, 0.07, 0.03)), gold, Vector3(0, 0.99, 0.225))
	add_part(hips, _tube("ca_horn", PackedVector3Array([Vector3(-0.2, 0.94, 0.14), Vector3(-0.27, 0.84, 0.1),
		Vector3(-0.28, 0.72, 0.0), Vector3(-0.24, 0.66, -0.08)]), PackedFloat32Array([0.05, 0.045, 0.03, 0.0]), 6), horn,
		Vector3.ZERO)
	add_part(hips, cyl(0.055, 0.055, 0.04, 6), bronze, Vector3(-0.2, 0.95, 0.15), Vector3(20, 0, 30))
	add_part(hips, cyl(0.06, 0.055, 0.46, 7), leather, Vector3(0.2, 1.08, -0.22), Vector3(-18, 0, -22))
	for k: int in 3:
		add_part(hips, cyl(0.0, 0.03, 0.08, 4), gold, Vector3(0.28 + 0.025 * k, 1.34 + 0.01 * k, -0.3 + 0.02 * k),
			Vector3(-18, 0, -22))
	# ---- Chest: team coat torso, leather jerkin, bandolier, bronze gorget, riveted left pauldron (asymmetry).
	add_part(chest, sphere(0.235, 8, 5), cloth, Vector3(0, 1.22, 0.0), Vector3.ZERO, Vector3(1.0, 1.3, 0.8))
	add_part(chest, box(Vector3(0.3, 0.36, 0.06)), leather, Vector3(0, 1.17, 0.16), Vector3(-6, 0, 0))
	add_part(chest, box(Vector3(0.07, 0.62, 0.04)), leather, Vector3(0.0, 1.2, 0.19), Vector3(-6, 0, 38))
	for k: int in 3:
		add_part(chest, box(Vector3(0.04, 0.03, 0.03)), bronze, Vector3(-0.1 + 0.1 * k, 1.1 + 0.08 * k, 0.215),
			Vector3(0, 0, 38))
	add_part(chest, cyl(0.13, 0.19, 0.12, 8), bronze, Vector3(0, 1.45, 0.0))
	add_part(chest, sphere(0.14, 8, 4), bronze, Vector3(-0.27, 1.42, 0.0), Vector3(0, 0, 20), Vector3(1.15, 0.7, 1.1))
	add_part(chest, torus(0.12, 0.15, 7), leather, Vector3(-0.27, 1.37, 0.0), Vector3(0, 0, 20), Vector3(1.1, 1.5, 1.1))
	for k: int in 3:
		add_part(chest, sphere(0.02, 4, 2), gold, Vector3(-0.28 + 0.06 * (k - 1), 1.5 - 0.02 * absf(k - 1), 0.06))
	# ---- Head: clean-shaven face, leather chin strap, bronze kettle hat with a wide brim and a team band.
	add_part(head, sphere(0.11, 8, 5), skin, Vector3(0, 1.6, 0.02), Vector3.ZERO, Vector3(0.95, 1.1, 1.0))
	# Face (faces pass 2026-09-28): a steady ginger-haired arbalester, green eyes, a ginger fringe under the kettle hat
	# (FaceKit lean face, replaces the eye bar).
	var hair := Color(0.80, 0.40, 0.14)
	_face = UnitFaces.attach_lean(self, head, "cinder_arbalest", {"center": Vector3(0, 1.6, 0.02), "radius": 0.11,
		"head_mesh": sphere(0.11, 8, 5), "head_scale": Vector3(0.95, 1.1, 1.0), "preset": &"plain", "detail": &"low",
		"skin": FIRE_SKIN, "hair": hair, "eyes": Color(0.30, 0.50, 0.24), "ears": &"none", "eye": {"c": Vector2(0.038, 0.008)},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, Vector3(0, 1.6, 0.02), 0.11, hair,
			Color(0.95, 0.62, 0.28), 1.0, 1.0)}, false)
	add_part(head, box(Vector3(0.2, 0.025, 0.03)), palette(&"fire_leather"), Vector3(0, 1.53, 0.07), Vector3(-30, 0, 0))
	# Blackened-iron kettle hat (in-game grade 2026-09-30: the bronze brim read the same as the Scorchbow's bronze
	# helm from the RTS camera; a dark disc ringed by the orange band tells the two apart at zoom 30).
	var iron: Material = load(GUNMETAL)
	add_part(head, sphere(0.14, 10, 4), iron, Vector3(0, 1.67, 0.0), Vector3.ZERO, Vector3(1.0, 0.85, 1.0))
	add_part(head, cyl(0.26, 0.26, 0.025, 12), iron, Vector3(0, 1.645, 0.0), Vector3(-6, 0, 0))
	add_part(head, cyl(0.145, 0.145, 0.06, 8), cloth, Vector3(0, 1.67, 0.0))
	add_part(head, cyl(0.0, 0.03, 0.07, 5), bronze, Vector3(0, 1.8, 0.0))
	var trim := add_part(head, torus(0.14, 0.18, 10), palette(&"unit_gold_trim"), Vector3(0, 1.74, 0.0),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: reaches across to steady the fore-stock.
	add_part(arm_l, _tube("ca_arm_l", PackedVector3Array([Vector3(-0.25, 1.42, 0.0), Vector3(-0.22, 1.16, 0.16),
		HAND_L + Vector3(-0.03, 0.03, -0.02)]), PackedFloat32Array([0.07, 0.062, 0.055]), 7), cloth, Vector3.ZERO)
	add_part(arm_l, cyl(0.06, 0.07, 0.1, 7), leather, HAND_L + Vector3(-0.05, 0.04, -0.06), Vector3(-60, 0, 70))
	add_part(arm_l, sphere(0.055, 6, 3), leather, HAND_L)
	# ---- Right arm: hand on the grip at the hip, the crossbow.
	add_part(arm_r, _tube("ca_arm_r", PackedVector3Array([Vector3(0.25, 1.42, 0.0), Vector3(0.29, 1.17, 0.0),
		HAND_R + Vector3(0.0, 0.04, -0.03)]), PackedFloat32Array([0.07, 0.062, 0.055]), 7), cloth, Vector3.ZERO)
	add_part(arm_r, cyl(0.06, 0.07, 0.1, 7), leather, HAND_R + Vector3(0.02, 0.06, -0.04), Vector3(-30, 0, 0))
	add_part(arm_r, sphere(0.055, 6, 3), leather, HAND_R)
	# stock (butt under the arm, fore-stock to the prod), bronze bands, the spanned string, the prod, the stirrup.
	add_part(arm_r, box(Vector3(0.075, 0.09, 0.66)), wood, Vector3(SX, SY, 0.24))
	add_part(arm_r, box(Vector3(0.09, 0.14, 0.2)), wood, Vector3(SX, SY - 0.03, -0.13), Vector3(-10, 0, 0))
	for z: float in [0.06, 0.42]:
		add_part(arm_r, box(Vector3(0.09, 0.1, 0.03)), bronze, Vector3(SX, SY, z))
	add_part(arm_r, _prod_mesh(), bronze, Vector3.ZERO)
	add_part(arm_r, _string_mesh(), leather, Vector3.ZERO)
	add_part(arm_r, torus(0.04, 0.065, 6), bronze, Vector3(SX, SY - 0.01, 0.64), Vector3(90, 0, 0))
	# cranequin: gear drum on the right of the stock, a rack along the top.
	add_part(arm_r, cyl(0.075, 0.075, 0.06, 8), bronze, HUB + Vector3(-0.03, 0, 0), Vector3(0, 0, 90))
	add_part(arm_r, box(Vector3(0.025, 0.03, 0.4)), leather, Vector3(SX + 0.045, SY + 0.05, 0.12))
	# ---- The crank (keep_separate node spun during the reload) and the bolt (hidden after the release).
	_crank = Node3D.new()
	_crank.name = "Crank"
	_crank.set_meta(&"keep_separate", true)
	_crank.position = HUB - model_origin(arm_r)
	arm_r.add_child(_crank)
	add_part(_crank, _crank_mesh(), bronze, HUB, Vector3.ZERO, Vector3.ONE, true, "CrankArm")
	_bolt = Node3D.new()
	_bolt.name = "Bolt"
	_bolt.set_meta(&"keep_separate", true)
	_bolt.position = Vector3.ZERO - model_origin(arm_r)
	arm_r.add_child(_bolt)
	add_part(_bolt, cyl(0.016, 0.016, 0.4, 5), wood, Vector3(SX, SY + 0.065, 0.46), Vector3(90, 0, 0), Vector3.ONE, true,
		"BoltShaft")
	_tip = add_part(_bolt, cyl(0.0, 0.06, 0.14, 6), palette(&"fire_glow"), Vector3(SX, SY + 0.065, 0.7), Vector3(90, 0, 0),
		Vector3.ONE, true, "BoltTip")
	_tip.set_meta(&"own_glow", true)
	_shot_sparks = make_motes(Color(1.0, 0.55, 0.15), 12, 0.45, 0.08, 2.4, 0.1, false, true)
	_shot_sparks.name = "Sparks"
	_shot_sparks.position = Vector3(SX, SY + 0.07, 0.72) - model_origin(arm_r)
	arm_r.add_child(_shot_sparks)
	# ---- Fx: FireModel's burn.
	var be := make_motes(Color(1.0, 0.45, 0.1), 14, 0.9, 0.3, 1.6, 0.14, false, true)
	be.name = "BurnEmbers"
	be.position = Vector3(0, 0.8, 0)
	be.set_meta(&"burn_fx", true)
	$Fx.add_child(be)
	ensure_shadow_blob(0.45)


# ================================================================ meshes (cached, model space)

static func _tube(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	# G-C: one smooth continuous tube (FireShapes) instead of stacked cylinders (hard kinks at every joint).
	st.append_from(FireShapes.tube(pts, radii, seg, caps), 0, Transform3D.IDENTITY)
	st.index()
	return _cached(key, st.commit())


## The bronze prod: a recurved bow across the front of the stock, thick in the middle, tips swept forward.
static func _prod_mesh() -> Mesh:
	return _tube("ca_prod", PackedVector3Array([Vector3(SX - 0.44, SY + 0.02, 0.6), Vector3(SX - 0.36, SY + 0.02, 0.52),
		Vector3(SX - 0.16, SY + 0.01, 0.55), Vector3(SX, SY, 0.58), Vector3(SX + 0.16, SY + 0.01, 0.55),
		Vector3(SX + 0.36, SY + 0.02, 0.52), Vector3(SX + 0.44, SY + 0.02, 0.6)]),
		PackedFloat32Array([0.024, 0.034, 0.044, 0.052, 0.044, 0.034, 0.024]), 5, false)


## The spanned string: from each prod tip back to the nut (a flat "V").
static func _string_mesh() -> Mesh:
	const KEY := "ca_string"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		var m := _tube("ca_string_%s" % s, PackedVector3Array([Vector3(SX + 0.43 * s, SY + 0.03, 0.58),
			Vector3(SX + 0.02 * s, SY + 0.06, 0.26)]), PackedFloat32Array([0.009, 0.009]), 3, false)
		st.append_from(m, 0, Transform3D.IDENTITY)
	st.index()
	return _cached(KEY, st.commit())


## Crank in its node's frame (origin = the axle): a hub, an arm out to the back, a knob sticking out sideways.
static func _crank_mesh() -> Mesh:
	const KEY := "ca_crank"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.append_from(cyl(0.03, 0.03, 0.05, 6), 0, Transform3D(Basis(Vector3.BACK, deg_to_rad(90.0)), Vector3(0.02, 0, 0)))
	st.append_from(box(Vector3(0.025, 0.03, 0.17)), 0, Transform3D(Basis.IDENTITY, Vector3(0.045, 0, -0.08)))
	st.append_from(cyl(0.022, 0.022, 0.09, 6), 0, Transform3D(Basis(Vector3.BACK, deg_to_rad(90.0)), Vector3(0.09, 0, -0.16)))
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ motion

func _after_ready() -> void:
	super()
	_write_tip(1.0)


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"arbalest_shot":
		return super(prev, t)
	_shoot_pose(t, 1.0)
	# Reload: nose down at the hip, the right hand winds the crank (small circles), the chest leans over it.
	var wind: float = _k3(t, 0.36, 0.5, 1.05, 1.3, 1.0, 1.0)
	if wind > 0.0:
		rot(P_ARM_R, Vector3(22.0 * DEG * wind, 0, 0))
		rot(P_ARM_L, Vector3(22.0 * DEG * wind, 0, 0))
		rot(P_CHEST, Vector3(10.0 * DEG * wind, -8.0 * DEG * wind, 0))
		rot(P_HEAD, Vector3(10.0 * DEG * wind, 0, 0))
		if _tier == 0:
			var c: float = TAU * 3.0 * clampf((t - 0.45) / 0.6, 0.0, 1.0)
			pos(P_ARM_R, Vector3(0, 0.025 * sin(c) * wind, 0.025 * cos(c) * wind))
			rot(P_LEG_L, Vector3(-12.0 * DEG * wind, 0, 0))
			rot(P_LEG_R, Vector3(10.0 * DEG * wind, 0, 0))
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	if prev < BOLT_BACK and t >= BOLT_BACK:
		_show_bolt(true)
	return t < ATTACK_LEN


## Snap up to the shoulder (0-0.1), loose at RELEASE with a recoil kick, back down to the hip by 0.4. `k` scales it.
func _shoot_pose(t: float, k: float) -> void:
	var up: float = _k3(t, 0.0, 0.09, 0.26, 0.42, 1.0, 1.0) * k
	var kick: float = _k3(t, RELEASE, RELEASE + 0.03, RELEASE + 0.05, 0.3, 1.0, 0.6) * k
	pos(P_ARM_R, Vector3(-0.05 * up, 0.3 * up, -0.04 * up - 0.06 * kick))
	pos(P_ARM_L, Vector3(0.02 * up, 0.3 * up, -0.02 * up - 0.06 * kick))
	rot(P_ARM_R, Vector3(-14.0 * DEG * kick, 0, 0))
	rot(P_ARM_L, Vector3(-14.0 * DEG * kick, 0, 0))
	rot(P_CHEST, Vector3(-6.0 * DEG * kick, 16.0 * DEG * up, 0))
	rot(P_HEAD, Vector3(6.0 * DEG * up, -14.0 * DEG * up, 0))
	pos(P_ROOT, Vector3(0, -0.03 * up, -0.07 * kick))
	if _tier == 0:
		rot(P_LEG_L, Vector3(-16.0 * DEG * up, 0, 0))
		rot(P_LEG_R, Vector3(12.0 * DEG * up, 0, 0))


## Piercing Bolt: a longer aim, the tip heats white, then the loose.
func _pose_cast(_spell: StringName, t: float) -> float:
	var hold: float = _k3(t, 0.0, 0.12, 0.55, 0.85, 1.0, 1.0)
	pos(P_ARM_R, Vector3(-0.05 * hold, 0.3 * hold, -0.04 * hold))
	pos(P_ARM_L, Vector3(0.02 * hold, 0.3 * hold, -0.02 * hold))
	rot(P_CHEST, Vector3(0, 16.0 * DEG * hold, 0))
	rot(P_HEAD, Vector3(6.0 * DEG * hold, -14.0 * DEG * hold, 0))
	_cast_hot = smoothstep(0.1, 0.5, t) * (1.0 - smoothstep(0.55, 0.6, t))
	var kick: float = _k3(t, 0.55, 0.58, 0.6, 0.8, 1.0, 0.6)
	rot(P_ARM_R, Vector3(-14.0 * DEG * kick, 0, 0))
	rot(P_ARM_L, Vector3(-14.0 * DEG * kick, 0, 0))
	pos(P_ROOT, Vector3(0, 0, -0.07 * kick))
	if t >= 0.55 and not _bolt_hidden:
		_on_action_event(&"release")
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	super(ev)
	match ev:
		&"release":
			_show_bolt(false)
			if _shot_sparks and _tier < 2:
				_shot_sparks.restart()
		&"attack_end", &"cast_end":
			_show_bolt(true)
			_cast_hot = 0.0
		&"death_glow_off":
			_show_bolt(false)


func _show_bolt(on: bool) -> void:
	if _bolt == null or _bolt_hidden == not on:
		return
	_bolt_hidden = not on
	_bolt.visible = on


## March: the crossbow stays level at the hip (the kit's arm swing cancelled), a steady soldier's step.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_ARM_L, Vector3(18.0 * DEG * s * w, 0, 0))
	rot(P_ARM_R, Vector3(-8.0 * DEG * s * w, 0, 0))
	if _tier > 0:
		return
	rot(P_ROOT, Vector3(4.0 * DEG * w, 0, 0))
	rot(P_HIPS, Vector3(0, 6.0 * DEG * s * w, 0))
	rot(P_CHEST, Vector3(0, -5.0 * DEG * s * w, 0))


func _extra_process(dt: float) -> void:
	super(dt)
	if _crank == null or _dead:
		return
	if _action == &"attack" and _action_t > 0.45 and _action_t < 1.05 and _tier < 2:
		_crank_a = fmod(_crank_a + dt * TAU * 5.0, TAU)
		_crank.rotation = Vector3(_crank_a, 0, 0)
	var heat: float = 1.0 + 1.6 * _cast_hot
	if _action == &"attack":
		heat += 1.2 * _k3(_action_t, 0.0, 0.08, RELEASE, 0.2, 0.8, 1.0)
	_write_tip(heat)


func _on_revive() -> void:
	super()
	_bolt_hidden = true
	_show_bolt(true)
	_cast_hot = 0.0
	_write_tip(1.0)


func _write_tip(v: float) -> void:
	v = snappedf(v * TIP_GLOW * glow_level(), 0.05)
	if v == _tip_v or _tip == null:
		return
	_tip_v = v
	_tip.set_instance_shader_parameter(&"glow_boost", v)
