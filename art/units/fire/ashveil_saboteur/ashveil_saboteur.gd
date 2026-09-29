extends FireModel
## Ashveil Saboteur, Fire T3 spy / sapper (t3-helpers.md 7.2 / 7.3; tiers wave, medium effort). Height 1.7.
## The TRUE form (the disguise is the enemy kingdom's own worker scene, swapped by gameplay; `play_reveal()` bursts
## the embers the disguise burns away in). A lean figure in a long ash-grey coat under a scorched rust hood, a soot mask pulled down under the painted face (FaceKit), the lower
## face and brass goggles pushed up on the hood, a team scarf whose tail streams behind, a diagonal bandolier of five
## brass powder flasks. Silhouette hooks: a small powder keg strapped slanting over the LEFT shoulder (asymmetry) and a
## round powder bomb in the left hand; a short dagger in the right. The only glow: the lit fuse-cord hanging from a
## coil at the right hip (fizzing sparks).
## Attack `saboteur_stab` (0.5 s, strike 0.11): a low lunge and a forward thrust. play_cast (Powder Charge, 1.0 s):
## crouches, plants the bomb at its feet with a spark burst. Death: FireModel's stagger, fall and burn.
## Draws: merged pivots + fuse sparks + blob + hidden vet trim; one-shot emitters (reveal, plant, burn).

const ATTACK_LEN := 0.5
const STRIKE := 0.11
const CAST_LEN := 1.0
const PLANT_AT := 0.55
const HAND_R := Vector3(0.29, 0.92, 0.12)
const HAND_L := Vector3(-0.29, 0.90, 0.14)
const FUSE_TIP := Vector3(0.265, 0.60, 0.15)
const EMBER_C := Color(1.0, 0.45, 0.12)

# saboteur_stab tracks [t, value, ease] (FireModel._kf). Arm x: - raises forward (blade held forward-down).
static var S_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.07, 45.0, 1, 0.11, -78.0, 2, 0.22, -70.0, 0, 0.50, 0.0, 0])
static var S_ARM_RP := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.11, 0.18, 2, 0.24, 0.14, 0, 0.50, 0.0, 0])
static var S_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.07, -30.0, 1, 0.11, 35.0, 2, 0.30, 25.0, 0, 0.50, 0.0, 0])
static var S_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 26.0, 1, 0.11, -24.0, 2, 0.28, -14.0, 0, 0.50, 0.0, 0])
static var S_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -6.0, 1, 0.11, 22.0, 2, 0.28, 16.0, 0, 0.50, 0.0, 0])
static var S_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.08, 1, 0.11, 0.34, 2, 0.28, 0.28, 0, 0.50, 0.0, 0])
static var S_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 0.0, 1, 0.11, -0.10, 2, 0.28, -0.08, 0, 0.50, 0.0, 0])
static var S_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.11, -38.0, 1, 0.30, -30.0, 0, 0.50, 0.0, 0])
static var S_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.11, 26.0, 1, 0.30, 20.0, 0, 0.50, 0.0, 0])
# Powder Charge: glance, crouch, plant the bomb in front, spring back up.
static var C_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.30, -0.30, 0, 0.75, -0.30, 0, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, 38.0, 0, 0.75, 34.0, 0, 1.0, 0.0, 0])
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.30, -30.0, 0, 0.50, -62.0, 2, 0.75, -55.0, 0, 1.0, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.30, 20.0, 0, 0.75, 20.0, 0, 1.0, 0.0, 0])
static var C_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.30, -55.0, 0, 0.75, -55.0, 0, 1.0, 0.0, 0])
static var C_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.30, 30.0, 0, 0.75, 30.0, 0, 1.0, 0.0, 0])
static var C_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, 35.0, 1, 0.22, -30.0, 0, 0.32, 0.0, 0, 1.0, 0.0, 0])

var _reveal: GPUParticles3D
var _plant: GPUParticles3D
var _sparks_fuse: GPUParticles3D
var _planted: bool = false


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var coat := palette(&"fire_ash_ball")
	var hood := palette(&"fire_sec_hurler")
	var cloth := palette(&"fire_cloth")
	var cdark := palette(&"fire_cloth_dark")
	var leather := palette(&"fire_leather")
	var soot := palette(&"fire_hair")
	var bronze := palette(&"fire_bronze")
	var wrap := palette(&"fire_sec_worker")
	var skin := palette(&"fire_skin")
	var steel := palette(&"warden_metal")
	var wood := palette(&"fire_wood")
	# ---- Legs: dark breeches, pale shin wraps, soft soot-black boots.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _sb_path("sb_leg_%s" % sx, PackedVector3Array([Vector3(0.11 * sx, 0.90, 0.0),
			Vector3(0.12 * sx, 0.50, 0.03), Vector3(0.12 * sx, 0.12, 0.0)]), PackedFloat32Array([0.08, 0.062, 0.052]), 7),
			leather, Vector3.ZERO)
		for k: int in 1:
			add_part(leg, torus(0.05, 0.07, 6), wrap, Vector3(0.12 * sx, 0.3, 0.01),
				Vector3(6, 0, 0), Vector3(1.0, 1.4, 1.0))
		add_part(leg, sphere(0.075, 7, 3), soot, Vector3(0.12 * sx, 0.06, 0.05), Vector3.ZERO, Vector3(1.0, 0.75, 1.6))
	# ---- Hips: the long coat skirt split at the front (dark slit), team-dark hem, belt, pouches, the fuse coil.
	add_part(hips, cyl(0.2, 0.31, 0.56, 9), coat, Vector3(0, 0.63, -0.01), Vector3(4, 0, 0))
	add_part(hips, box(Vector3(0.07, 0.5, 0.05)), soot, Vector3(0, 0.62, 0.27), Vector3(-11, 0, 0))
	add_part(hips, torus(0.28, 0.33, 7), cdark, Vector3(0, 0.37, 0.0), Vector3(4, 0, 0), Vector3(1.0, 1.3, 1.0))
	add_part(hips, cyl(0.215, 0.215, 0.07, 8), leather, Vector3(0, 0.90, 0.01))
	add_part(hips, box(Vector3(0.07, 0.06, 0.03)), bronze, Vector3(0, 0.90, 0.22))
	add_part(hips, box(Vector3(0.1, 0.11, 0.07)), leather, Vector3(-0.19, 0.83, 0.1), Vector3(0, -30, 0))
	add_part(hips, torus(0.04, 0.075, 6), leather, Vector3(0.21, 0.84, 0.10), Vector3(0, 0, 90), Vector3(1.0, 1.0, 1.3))
	add_part(hips, _sb_path("sb_fuse", PackedVector3Array([Vector3(0.235, 0.80, 0.13), Vector3(0.27, 0.72, 0.17),
		Vector3(0.275, 0.66, 0.16), FUSE_TIP]), PackedFloat32Array([0.018, 0.017, 0.016, 0.015]), 5), leather, Vector3.ZERO)
	add_part(hips, sphere(0.07, 8, 4), palette(&"fire_glow_hero"), FUSE_TIP, Vector3.ZERO, Vector3(1.0, 1.25, 1.0))
	_sparks_fuse = make_motes(Color(1.0, 0.6, 0.2), 4, 0.5, 0.03, 0.7, 0.07)
	_sparks_fuse.name = "FuseSparks"
	_sparks_fuse.set_meta(&"keep_separate", true)
	_sparks_fuse.position = FUSE_TIP - model_origin(hips)
	hips.add_child(_sparks_fuse)
	# ---- Chest: grey coat torso, high collar, bandolier of five brass flasks, team scarf with a streaming tail.
	add_part(chest, sphere(0.22, 8, 4), coat, Vector3(0, 1.14, 0), Vector3(6, 0, 0), Vector3(1.0, 1.3, 0.82))
	add_part(chest, cyl(0.15, 0.12, 0.14, 8), hood, Vector3(0, 1.40, -0.01), Vector3(-8, 0, 0))
	add_part(chest, torus(0.09, 0.16, 6), cloth, Vector3(0, 1.38, 0.01), Vector3(-10, 0, 0), Vector3(1.0, 1.6, 1.0))
	add_part(chest, _sb_path("sb_scarf", PackedVector3Array([Vector3(0.06, 1.37, -0.12), Vector3(0.13, 1.25, -0.24),
		Vector3(0.22, 1.12, -0.31), Vector3(0.30, 1.02, -0.36)]), PackedFloat32Array([0.06, 0.055, 0.05, 0.035]), 5),
		cloth, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
	add_part(chest, box(Vector3(0.07, 0.72, 0.04)), leather, Vector3(0, 1.15, 0.185), Vector3(-6, 0, 38))
	add_part(chest, box(Vector3(0.07, 0.72, 0.04)), leather, Vector3(0, 1.15, -0.175), Vector3(6, 0, -38))
	for k: int in 4:
		var u: float = float(k) / 3.0
		var p := Vector3(-0.17, 1.35, 0.205).lerp(Vector3(0.16, 0.95, 0.215), u)
		add_part(chest, cyl(0.03, 0.038, 0.11, 5), bronze, p + Vector3(0, 0, 0.025), Vector3(-6, 0, 38))
	# The powder keg slanting over the left shoulder (the silhouette hook), bronze hoops, a stub of fuse on top.
	var keg := Vector3(-0.15, 1.36, -0.24)
	add_part(chest, cyl(0.1, 0.1, 0.32, 8), wood, keg, Vector3(0, 0, 28))
	for s: float in [-1.0, 1.0]:
		add_part(chest, torus(0.1, 0.12, 6), bronze, keg + Vector3(0.056 * s, -0.105 * s, 0), Vector3(0, 0, 28))
	add_part(chest, cyl(0.075, 0.075, 0.02, 6), soot, keg + Vector3(-0.078, 0.145, 0), Vector3(0, 0, 28))
	add_part(chest, _sb_path("sb_kegfuse", PackedVector3Array([keg + Vector3(-0.08, 0.15, 0), keg + Vector3(-0.12, 0.25, 0.02),
		keg + Vector3(-0.09, 0.31, 0.06)]), PackedFloat32Array([0.016, 0.014, 0.012]), 4), leather, Vector3.ZERO)
	add_part(chest, box(Vector3(0.05, 0.5, 0.03)), leather, Vector3(-0.02, 1.28, -0.2), Vector3(12, 0, -40))
	# ---- Head: deep grey hood with a team lining round the face, the soot mask pulled down onto the neck, goggles up on
	# the brow. The face (faces pass 2026-09-28): a sly soot-smudged sapper, black fringe, amber eyes, a smirk at rest
	# (FaceKit, replaces the pale eye band + eye dots).
	add_part(head, sphere(0.17, 8, 4), hood, Vector3(0, 1.58, -0.01), Vector3.ZERO, Vector3(1.0, 1.1, 1.15))
	add_part(head, cyl(0.0, 0.1, 0.26, 6), hood, Vector3(0, 1.66, -0.21), Vector3(-116, 0, 0))
	add_part(head, sphere(0.12, 8, 4), skin, Vector3(0, 1.56, 0.105), Vector3.ZERO, Vector3(0.95, 1.05, 0.9))
	add_part(head, torus(0.115, 0.155, 7), cloth, Vector3(0, 1.57, 0.13), Vector3(78, 0, 0), Vector3(1.0, 1.0, 1.15))
	add_part(head, sphere(0.1, 8, 4), soot, Vector3(0, 1.455, 0.10), Vector3(-10, 0, 0), Vector3(1.0, 0.62, 0.85))
	var hair := Color(0.12, 0.08, 0.07)
	var fc := Vector3(0, 1.56, 0.105)
	_face = UnitFaces.attach_lean(self, head, "ashveil_saboteur", {"center": fc, "radius": 0.12,
		"head_mesh": sphere(0.12, 8, 4), "head_scale": Vector3(0.95, 1.05, 0.9), "preset": &"gentle", "detail": &"low",
		"skin": FIRE_SKIN, "hair": hair, "hair_tip": Color(0.30, 0.20, 0.16), "eyes": Color(0.82, 0.52, 0.12),
		"ears": &"none", "eye": {"c": Vector2(0.040, 0.010)}, "x": {&"neutral": {"mouth": {"kind": "smirk"}}},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, fc, 0.12, hair, Color(0.30, 0.20, 0.16), -1.0, 0.9)},
		false)
	for gx: float in [-0.055, 0.055]:
		add_part(head, cyl(0.04, 0.04, 0.035, 6), bronze, Vector3(gx, 1.71, 0.10), Vector3(62, 0, 0))
	add_part(head, cyl(0.172, 0.172, 0.025, 8, false), leather, Vector3(0, 1.69, -0.01), Vector3(-26, 0, 0))
	var trim := add_part(head, torus(0.13, 0.17, 10), palette(&"unit_gold_trim"), Vector3(0, 1.74, -0.04),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: coat sleeve, leather cuff, gloved hand holding a round powder bomb.
	add_part(arm_l, _sb_path("sb_arm_l", PackedVector3Array([Vector3(-0.24, 1.36, 0.0), Vector3(-0.30, 1.12, 0.03),
		HAND_L + Vector3(0, 0.07, -0.02)]), PackedFloat32Array([0.072, 0.066, 0.06]), 6), coat, Vector3.ZERO)
	add_part(arm_l, cyl(0.065, 0.07, 0.07, 8), leather, HAND_L + Vector3(0, 0.07, -0.02), Vector3(20, 0, 0))
	add_part(arm_l, sphere(0.055, 6, 4), soot, HAND_L)
	add_part(arm_l, sphere(0.085, 8, 4), soot, HAND_L + Vector3(0, -0.02, 0.09))
	add_part(arm_l, cyl(0.03, 0.035, 0.04, 6), bronze, HAND_L + Vector3(0, 0.07, 0.10))
	add_part(arm_l, _sb_path("sb_bombfuse", PackedVector3Array([HAND_L + Vector3(0, 0.09, 0.10),
		HAND_L + Vector3(0.02, 0.15, 0.12), HAND_L + Vector3(0.05, 0.18, 0.10)]), PackedFloat32Array([0.012, 0.011, 0.01]), 4),
		wrap, Vector3.ZERO)
	# ---- Right arm: coat sleeve, cuff, a short dagger held forward-down.
	add_part(arm_r, _sb_path("sb_arm_r", PackedVector3Array([Vector3(0.24, 1.36, 0.0), Vector3(0.30, 1.12, 0.02),
		HAND_R + Vector3(0, 0.07, -0.03)]), PackedFloat32Array([0.072, 0.066, 0.06]), 6), coat, Vector3.ZERO)
	add_part(arm_r, cyl(0.065, 0.07, 0.07, 8), leather, HAND_R + Vector3(0, 0.07, -0.03), Vector3(20, 0, 0))
	add_part(arm_r, sphere(0.055, 6, 4), soot, HAND_R)
	add_part(arm_r, cyl(0.02, 0.022, 0.1, 6), wood, HAND_R + Vector3(0, 0.0, -0.02), Vector3(-80, 0, 0))
	add_part(arm_r, box(Vector3(0.11, 0.022, 0.03)), bronze, HAND_R + Vector3(0, -0.01, 0.05), Vector3(10, 0, 0))
	add_part(arm_r, cyl(0.0, 0.032, 0.30, 4), steel, HAND_R + Vector3(0, -0.04, 0.20), Vector3(100, 0, 0),
		Vector3(1.0, 1.0, 0.35))
	# ---- Fx: FireModel's burn, the reveal ember burst, the plant spark burst.
	var fx: Node3D = $Fx
	var be := make_motes(EMBER_C, 14, 0.9, 0.3, 1.6, 0.14, false, true)
	be.name = "BurnEmbers"
	be.position = Vector3(0, 0.7, 0)
	be.set_meta(&"burn_fx", true)
	fx.add_child(be)
	_reveal = make_motes(EMBER_C, 20, 0.35, 0.35, 2.2, 0.15, false, true)
	_reveal.name = "RevealEmbers"
	_reveal.position = Vector3(0, 0.9, 0)
	fx.add_child(_reveal)
	_plant = make_motes(Color(1.0, 0.7, 0.25), 12, 0.5, 0.08, 1.8, 0.1, false, true)
	_plant.name = "PlantSparks"
	_plant.position = Vector3(0, 0.1, 0.45)
	fx.add_child(_plant)
	ensure_shadow_blob(0.4)


# ================================================================ meshes (cached, model space)

## Tapered tube through `pts` (radii per point), one cached mesh.
static func _sb_path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var len_total := d.length() + 0.02
		var c := cyl(radii[i + 1], radii[i], len_total, seg, i == 0 or i == pts.size() - 2)
		st.append_from(c, 0, Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))
	st.index()
	return _cached(key, st.commit())


# ================================================================ hooks / motion

## The disguise burns away (gameplay swaps the worker disguise for this model, then calls this).
func play_reveal() -> void:
	if _reveal and not _dead:
		_reveal.restart()


func _pose_attack(prev: float, t: float) -> bool:
	rot(P_ARM_R, Vector3(_kf(t, S_ARM_R) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, S_ARM_RP)))
	rot(P_ARM_L, Vector3(_kf(t, S_ARM_L) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, S_CHEST_X) * DEG, _kf(t, S_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, S_ROOT_Y), _kf(t, S_ROOT_Z)))
	if _tier == 0:
		rot(P_LEG_L, Vector3(_kf(t, S_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_kf(t, S_LEG_R) * DEG, 0, 0))
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	pos(P_ROOT, Vector3(0, _kf(t, C_ROOT_Y), 0))
	rot(P_CHEST, Vector3(_kf(t, C_CHEST_X) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_kf(t, C_ARM_L) * DEG, 0, 0))
	rot(P_ARM_R, Vector3(_kf(t, C_ARM_R) * DEG, 0, 0))
	rot(P_LEG_L, Vector3(_kf(t, C_LEG_L) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_kf(t, C_LEG_R) * DEG, 0, 0))
	if _tier == 0:
		rot(P_HEAD, Vector3(0, _kf(t, C_HEAD_Y) * DEG, 0))
	if not _planted and t >= PLANT_AT:
		_planted = true
		if _plant and _tier < 2:
			_plant.restart()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	super(ev)
	match ev:
		&"cast_start":
			_planted = false
		&"death_glow_off":
			if _sparks_fuse:
				_sparks_fuse.emitting = false


func _on_revive() -> void:
	super()
	if _sparks_fuse:
		_sparks_fuse.emitting = true


## Sneaking walk: low and leaning in, head down, the bomb hand tucked, quick short steps.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	if _tier > 0:
		return
	var s: float = sin(TAU * _walk_p)
	rot(P_ROOT, Vector3(9.0 * DEG * w, 0, 0))
	pos(P_ROOT, Vector3(0, -0.04 * w, 0))
	rot(P_HIPS, Vector3(0, 7.0 * DEG * s * w, 0))
	rot(P_CHEST, Vector3(4.0 * DEG * w, -6.0 * DEG * s * w, 0))
	rot(P_HEAD, Vector3(-8.0 * DEG * w, 0, 0))
	rot(P_ARM_L, Vector3((-14.0 + 10.0 * s) * DEG * w, 0, 0))
