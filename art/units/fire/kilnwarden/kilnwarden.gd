extends FireModel
## Kilnwarden, Fire T2 debuff / anti-caster (caster-units.md 5.1 / 10.1, task CU.V1). Height 1.75 (x1.12 scene scale,
## like the other Fire infantry since the clarity pass), chimney top 2.3 m.
## "A walking forge": a broad, stooped smith-priest with a small bottle kiln of terracotta brick strapped to his back on a
## wooden pack frame, its short sooty chimney rising behind his bald head (smoke puffs from it, the coals glow at its lip)
## and its arched firing mouth glowing orange low on his back (glow point 1: KilnFire = mouth + chimney coals, one node).
## In his right bronze gauntlet, long iron smith's tongs held up and forward gripping a glowing ingot (glow point 2).
## Team-colour cassock and rolled sleeves, a team-dark shoulder mantle and a team priest's stole down a heavy leather
## apron, bronze gauntlets, soot on the hem, a smith's hammer at the left hip (the asymmetric secondary shape).
## Face (FaceKit): stern, bald crown with grey side hair, round ears, a grey braided spade beard with bronze beads, heavy
## brows, amber eyes, a firm closed mouth, soot on the cheeks.
## Attack `caster_fire` (0.6 s, release 0.15): the tongs flick a spark bolt off the ingot.
## play_cast(&"slag_rain") (0.8 s, release 0.44): the tongs swing up over the shoulder and fling the ingot's drip in an
##   arc, the kiln flares (mouth + chimney x3, a spark gout from the chimney). signal cast_released(&"slag_rain", from).
## play_cast(&"mana_scald") (0.6 s, release 0.18): the left palm opens toward the target and pulls; the kiln mouth
##   flashes white-blue for 0.2 s, steam hisses off the palm. signal cast_released(&"mana_scald", from).
## Death: FireModel's burn; the kiln gutters out (glow -> 0, smoke stops) and cracks (brick chips burst).
## VFX hooks (art/vfx/caster_fire_vfx.gd reads them): get_ingot_point(), get_palm_point(), get_kiln_point().
## Draws at rest: 7 merged pivots + Face + KilnFire + Ingot + blob + 1 looping smoke (ScaldFlash / VetTrim hidden).

signal cast_released(spell_id: StringName, from: Vector3)

const HC := Vector3(0, 1.585, 0.15)          # head centre (model space)
const HR := 0.155
const HAND_R := Vector3(0.38, 1.03, 0.30)
const HAND_L := Vector3(-0.37, 0.95, 0.21)
const TONG_D := Vector3(0.048, 0.803, 0.594)  # tongs axis (unit), up and forward from the fist
const TONG_LEN := 0.64
const KZ := -0.40                              # kiln axis z
const MOUTH := Vector3(0, 1.26, -0.735)
const CHIM_TOP := Vector3(0, 2.12, -0.47)
const ATTACK_LEN := 0.6
const SLAG_LEN := 0.8
const SLAG_RELEASE := 0.44
const SCALD_LEN := 0.6
const SCALD_RELEASE := 0.18
const KILN_GLOW := 1.25                        # idle glow_boost of the kiln fire (own_glow)
const INGOT_GLOW := 1.4
const GREY := Color(0.62, 0.60, 0.58)
const GREY_TIP := Color(0.84, 0.82, 0.78)

# caster_fire: tongs flick. Arm x negative raises the arm forward (the tongs point UP from the fist: + tips them forward).
static var P_ARM_R_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -48.0, 1, 0.15, 42.0, 2, 0.32, 30.0, 0, 0.60, 0.0, 0])
static var P_ARM_L_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -30.0, 1, 0.16, 20.0, 2, 0.60, 0.0, 0])
static var P_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -10.0, 1, 0.15, 16.0, 2, 0.34, 10.0, 0, 0.60, 0.0, 0])
static var P_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 12.0, 1, 0.15, -10.0, 2, 0.34, -5.0, 0, 0.60, 0.0, 0])
static var P_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.03, 1, 0.15, 0.08, 2, 0.34, 0.05, 0, 0.60, 0.0, 0])
# Slag Rain: tongs hauled up over the shoulder (ingot behind the head), then whipped forward and down, drip flung.
static var S_ARM_R_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -118.0, 1, 0.38, -124.0, 0, 0.46, -10.0, 2, 0.60, 22.0, 1,
	0.80, 0.0, 0])
static var S_ARM_R_Z := PackedFloat32Array([0.0, 0.0, 0, 0.30, 0.20, 1, 0.46, -0.10, 2, 0.80, 0.0, 0])
static var S_ARM_L_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -40.0, 1, 0.46, 30.0, 2, 0.62, 18.0, 0, 0.80, 0.0, 0])
static var S_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -14.0, 1, 0.46, 18.0, 2, 0.62, 12.0, 0, 0.80, 0.0, 0])
static var S_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.30, 16.0, 1, 0.46, -14.0, 2, 0.62, -8.0, 0, 0.80, 0.0, 0])
static var S_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.30, 0.04, 1, 0.46, -0.07, 2, 0.62, -0.05, 0, 0.80, 0.0, 0])
static var S_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.30, -0.06, 1, 0.46, 0.12, 2, 0.62, 0.08, 0, 0.80, 0.0, 0])
static var S_STEP_L := PackedFloat32Array([0.0, 0.0, 0, 0.30, 6.0, 1, 0.46, -24.0, 2, 0.62, -18.0, 0, 0.80, 0.0, 0])
static var S_STEP_R := PackedFloat32Array([0.0, 0.0, 0, 0.30, -4.0, 1, 0.46, 14.0, 2, 0.62, 10.0, 0, 0.80, 0.0, 0])
static var S_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.30, 0.5, 1, 0.46, 1.0, 1, 0.56, 1.0, 0, 0.80, 0.0, 0])
# Mana Scald: the left palm thrust at the target, a clutch and a hard pull back to the chest (the mana torn out).
static var M_ARM_L_X := PackedFloat32Array([0.0, 0.0, 0, 0.14, -86.0, 1, 0.24, -90.0, 0, 0.40, -44.0, 2, 0.60, 0.0, 0])
static var M_ARM_L_Y := PackedFloat32Array([0.0, 0.0, 0, 0.14, 0.12, 1, 0.24, 0.12, 0, 0.40, -0.10, 2, 0.60, 0.0, 0])
static var M_ARM_R_X := PackedFloat32Array([0.0, 0.0, 0, 0.14, 12.0, 1, 0.40, 16.0, 0, 0.60, 0.0, 0])
static var M_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.14, 10.0, 1, 0.24, 12.0, 0, 0.40, -8.0, 2, 0.60, 0.0, 0])
static var M_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.14, 18.0, 1, 0.24, 20.0, 0, 0.40, 4.0, 2, 0.60, 0.0, 0])
static var M_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.14, 0.06, 1, 0.24, 0.07, 0, 0.40, -0.06, 2, 0.60, 0.0, 0])
static var M_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.14, -8.0, 1, 0.40, 6.0, 2, 0.60, 0.0, 0])

var _kiln_fire: MeshInstance3D
var _ingot: MeshInstance3D
var _scald_flash: MeshInstance3D
var _smoke: GPUParticles3D
var _spit: GPUParticles3D
var _gout: GPUParticles3D
var _drip: GPUParticles3D
var _steam: GPUParticles3D
var _chips: GPUParticles3D
var _flare: float = 0.0          # 0..1 extra kiln fire (slag cast / attack)
var _heat: float = 0.0           # 0..1 extra ingot heat
var _kiln_v: float = -1.0
var _ingot_v: float = -1.0
var _fired: bool = false
var _scald_t: float = -1.0       # > 0 while the white-blue mouth flash shows


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
	var brick := palette(&"fire_sec_hurler")
	var soot := palette(&"fire_ash_ball")
	var flame := palette(&"fire_flame")
	# ---- Legs: heavy boots with bronze toe caps under the cassock hem (the hem hides the shins).
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, sphere(0.10, 7, 4), leather, Vector3(0.13 * sx, 0.075, 0.07), Vector3.ZERO, Vector3(0.95, 0.72, 1.55))
		add_part(leg, sphere(0.06, 6, 3), bronze, Vector3(0.13 * sx, 0.08, 0.20), Vector3.ZERO, Vector3(1.3, 0.8, 0.8))
	# ---- Hips: the long team cassock (a flared lathe), soot-dark hem band, leather apron over the front with a pocket,
	# a team priest's stole down it, belt + bronze buckle, the smith's hammer at the left hip.
	add_part(hips, _lathe("kw_skirt", PackedVector2Array([Vector2(0.27, 0.92), Vector2(0.31, 0.78), Vector2(0.38, 0.52),
		Vector2(0.44, 0.30), Vector2(0.46, 0.22)]), 12), cloth, Vector3.ZERO)
	add_part(hips, _lathe("kw_hem", PackedVector2Array([Vector2(0.455, 0.335), Vector2(0.475, 0.215)]), 12, false), soot,
		Vector3.ZERO)
	add_part(hips, _panel("kw_apron", 0.305, 0.915, 0.45, 0.30, -0.95, 0.95, 5, 0.035), leather, Vector3.ZERO)
	add_part(hips, box(Vector3(0.18, 0.12, 0.04)), leather, Vector3(-0.15, 0.58, 0.40), Vector3(-14, -20, 0))
	for s: float in [-1.0, 1.0]:
		add_part(hips, _panel("kw_stole_%s" % s, 0.40, 0.93, 0.468, 0.338, 0.2 * s - 0.065, 0.2 * s + 0.065, 1, 0.03), cloth,
			Vector3.ZERO)
		add_part(hips, cyl(0.0, 0.045, 0.08, 5), bronze, Vector3(0.093 * s, 0.37, 0.47), Vector3(-166, 0, 0))
	add_part(hips, cyl(0.30, 0.30, 0.08, 10, false), leather, Vector3(0, 0.89, 0.0), Vector3(6, 0, 0))
	add_part(hips, box(Vector3(0.10, 0.08, 0.04)), bronze, Vector3(0, 0.89, 0.30), Vector3(6, 0, 0))
	add_part(hips, _path_mesh("kw_hammer_h", PackedVector3Array([Vector3(-0.30, 0.90, 0.10), Vector3(-0.43, 0.52, 0.15)]),
		PackedFloat32Array([0.024, 0.022]), 5), wood, Vector3.ZERO)
	add_part(hips, box(Vector3(0.085, 0.085, 0.19)), bronze, Vector3(-0.435, 0.50, 0.15), Vector3(0, 0, 18))
	# ---- Chest: broad stooped team keg torso, apron bib, team-dark mantle, leather pack straps; pack frame and kiln.
	var tc := Vector3(0, 1.19, 0.0)
	add_part(chest, _lathe("kw_torso", PackedVector2Array([Vector2(0.27, -0.31), Vector2(0.32, -0.16), Vector2(0.345, 0.02),
		Vector2(0.32, 0.17), Vector2(0.24, 0.28), Vector2(0.13, 0.33)]), 12), cloth, tc, Vector3(12, 0, 0),
		Vector3(1.0, 1.0, 0.78))
	add_part(chest, _panel("kw_bib", -0.24, 0.17, 0.30, 0.325, -0.6, 0.6, 3, 0.05), leather, tc, Vector3(12, 0, 0),
		Vector3(1.0, 1.0, 0.78))
	add_part(chest, cyl(0.19, 0.42, 0.22, 12, false), cdark, Vector3(0, 1.42, 0.0), Vector3(10, 0, 0), Vector3(1.0, 1.0, 0.86))
	add_part(chest, cyl(0.20, 0.20, 0.07, 10, false), cdark, Vector3(0, 1.53, 0.02), Vector3(12, 0, 0))
	add_part(chest, sphere(0.045, 6, 3), bronze, Vector3(0, 1.43, 0.37))
	for s: float in [-1.0, 1.0]:
		add_part(chest, _path_mesh("kw_strap_%s" % s, PackedVector3Array([Vector3(0.17 * s, 1.52, -0.30),
			Vector3(0.20 * s, 1.56, -0.02), Vector3(0.16 * s, 1.36, 0.30), Vector3(0.14 * s, 1.12, 0.33)]),
			PackedFloat32Array([0.03, 0.032, 0.03, 0.028]), 4), leather, Vector3.ZERO)
		# pack frame rails (their tops show above the kiln shoulder)
		add_part(chest, _path_mesh("kw_rail_%s" % s, PackedVector3Array([Vector3(0.21 * s, 0.98, -0.22),
			Vector3(0.23 * s, 1.86, -0.26)]), PackedFloat32Array([0.026, 0.024]), 5), wood, Vector3.ZERO)
	add_part(chest, box(Vector3(0.58, 0.06, 0.34)), wood, Vector3(0, 1.04, -0.38))
	# The bottle kiln: a terracotta belly under a pale fire-clay shoulder, an iron band, the chimney with a flared bronze lip,
	# the arched firing mouth on the back; a leather bellows hung on its left flank (the asymmetric secondary shape).
	add_part(chest, _lathe("kw_kiln", PackedVector2Array([Vector2(0.20, 1.06), Vector2(0.30, 1.13),
		Vector2(0.36, 1.28), Vector2(0.355, 1.46), Vector2(0.30, 1.60)]), 12), brick, Vector3(0, 0, KZ))
	add_part(chest, _lathe("kw_shoulder", PackedVector2Array([Vector2(0.302, 1.595), Vector2(0.20, 1.72),
		Vector2(0.13, 1.79)]), 12), palette(&"fire_sec_worker"), Vector3(0, 0, KZ))
	add_part(chest, _lathe("kw_band_a", PackedVector2Array([Vector2(0.368, 1.40), Vector2(0.368, 1.34)]), 12, false), soot,
		Vector3(0, 0, KZ))
	add_part(chest, _path_mesh("kw_chimney", PackedVector3Array([Vector3(0, 1.76, KZ), Vector3(0, 1.95, KZ - 0.03),
		CHIM_TOP - Vector3(0, 0.03, 0)]), PackedFloat32Array([0.12, 0.105, 0.095]), 8, false), soot, Vector3.ZERO)
	add_part(chest, cyl(0.125, 0.10, 0.07, 8, false), bronze, CHIM_TOP, Vector3(-7, 0, 0))
	add_part(chest, cyl(0.10, 0.10, 0.02, 6), palette(&"fire_hair"), CHIM_TOP + Vector3(0, -0.02, 0))
	add_part(chest, torus(0.10, 0.145, 8), bronze, MOUTH + Vector3(0, 0.0, 0.004), Vector3(90, 0, 0), Vector3(1.0, 1.0, 1.25))
	add_part(chest, box(Vector3(0.28, 0.05, 0.07)), soot, MOUTH + Vector3(0, 0.16, 0.03), Vector3(-12, 0, 0))
	var bl := Vector3(-0.425, 1.36, KZ + 0.02)
	add_part(chest, prism(Vector3(0.22, 0.32, 0.11)), leather, bl, Vector3(180, 90, 0))
	for s: float in [-1.0, 1.0]:
		add_part(chest, box(Vector3(0.025, 0.30, 0.22)), wood, bl + Vector3(0.055 * s, 0.02, 0.0), Vector3(0, 0, -11 * s))
	add_part(chest, cyl(0.0, 0.035, 0.12, 5), bronze, bl + Vector3(0.02, -0.21, 0.0), Vector3(180, 0, 0))
	# The kiln fire (mouth + chimney coals): the glow point, driven by this script (flicker, flare, gutter), never merged.
	_kiln_fire = add_part(chest, _kiln_fire_mesh(), flame, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "KilnFire")
	_kiln_fire.set_meta(&"own_glow", true)
	# Mana Scald: the mouth flashes white-blue (shown 0.2 s over the fire; hidden at rest).
	_scald_flash = add_part(chest, sphere(0.1, 8, 4), palette(&"crystal_glow"), MOUTH + Vector3(0, -0.01, -0.028),
		Vector3.ZERO, Vector3(1.05, 1.2, 0.45), true, "ScaldFlash")
	_scald_flash.set_meta(&"own_glow", true)
	_scald_flash.visible = false
	var trim := add_part(chest, torus(0.30, 0.34, 10), palette(&"unit_gold_trim"), Vector3(0, 1.605, KZ), Vector3.ZERO,
		Vector3(1.0, 0.8, 1.0), true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Head: bald crown, round ears, grey side hair, a braided spade beard with bronze beads (face + hair + beard +
	# ears = ONE FaceKit surface; the lean style drops the tiny highlights / creases at rest).
	add_part(head, sphere(HR, 10, 6), skin, HC, Vector3.ZERO, Vector3(1.0, 1.02, 0.98))
	add_part(head, cyl(0.0, 0.036, 0.10, 5), skin, HC + Vector3(0, -0.02, HR - 0.005), Vector3(100, 0, 0))
	_face = UnitFaces.attach_lean(self, head, "kilnwarden", {"center": HC, "radius": HR, "head_mesh": sphere(HR, 10, 6),
		"head_scale": Vector3(1.0, 1.02, 0.98), "preset": &"stern", "detail": &"low", "skin": FIRE_SKIN.darkened(0.06),
		"hair": GREY, "hair_tip": GREY_TIP, "eyes": Color(0.95, 0.65, 0.25), "ears": &"none",
		"palette": {"iris_glow": 0.35, "blush": Color(0.34, 0.27, 0.24), "brow": Color(0.40, 0.38, 0.37)},
		"eye": {"hw": 0.029, "top": 0.019, "ir": 0.014, "c": Vector2(0.052, 0.018)},
		"brow": {"w": Vector3(0.011, 0.010, 0.0045)},
		"mouth": {"c": Vector2(0.0, -0.070), "hw": 0.030},
		"x": {&"neutral": {"blush": 0.8, "mouth": {"kind": "closed", "curve": -0.25, "w": 0.9}}},
		"hair_fn": func(acc: Dictionary) -> void: _hair_and_beard(acc)})
	var vt := add_part(head, torus(0.14, 0.17, 10), palette(&"unit_gold_trim"), HC + Vector3(0, 0.07, -0.01),
		Vector3(-8, 0, 0), Vector3.ONE, true, "VetTrimHead")
	if vt:
		vt.set_meta(&"vet_trim", true)
	# ---- Left arm: rolled team sleeve, bronze gauntlet, an open bare palm (Mana Scald).
	add_part(arm_l, _path_mesh("kw_arm_l", PackedVector3Array([Vector3(-0.28, 1.40, 0.02), Vector3(-0.38, 1.18, 0.04),
		Vector3(-0.39, 1.08, 0.10)]), PackedFloat32Array([0.10, 0.095, 0.09]), 7), cloth, Vector3.ZERO)
	add_part(arm_l, _path_mesh("kw_gaunt_l", PackedVector3Array([Vector3(-0.39, 1.10, 0.08), HAND_L + Vector3(0, 0.03, -0.03)]),
		PackedFloat32Array([0.085, 0.07]), 7), bronze, Vector3.ZERO)
	add_part(arm_l, cyl(0.095, 0.10, 0.05, 8, false), bronze, Vector3(-0.39, 1.09, 0.09), Vector3(28, 0, -8))
	add_part(arm_l, sphere(0.07, 7, 4), skin, HAND_L, Vector3(-30, 0, 0), Vector3(1.0, 0.8, 1.25))
	add_part(arm_l, cyl(0.02, 0.028, 0.08, 5), skin, HAND_L + Vector3(0.05, 0.03, 0.04), Vector3(-40, 0, -35))
	# ---- Right arm: rolled team sleeve, bronze gauntlet fist on the long iron tongs, the glowing ingot in the jaws.
	add_part(arm_r, _path_mesh("kw_arm_r", PackedVector3Array([Vector3(0.28, 1.40, 0.02), Vector3(0.39, 1.19, 0.06),
		Vector3(0.40, 1.10, 0.14)]), PackedFloat32Array([0.10, 0.095, 0.09]), 7), cloth, Vector3.ZERO)
	add_part(arm_r, _path_mesh("kw_gaunt_r", PackedVector3Array([Vector3(0.40, 1.12, 0.12), HAND_R + Vector3(0, 0.01, -0.05)]),
		PackedFloat32Array([0.085, 0.072]), 7), bronze, Vector3.ZERO)
	add_part(arm_r, cyl(0.095, 0.10, 0.05, 8, false), bronze, Vector3(0.40, 1.11, 0.13), Vector3(40, 0, 8))
	add_part(arm_r, sphere(0.078, 7, 4), bronze, HAND_R)
	add_part(arm_r, _tongs_mesh(), soot, Vector3.ZERO)
	var jaw := HAND_R + TONG_D * TONG_LEN
	_ingot = add_part(arm_r, sphere(0.07, 7, 4), palette(&"fire_glow"), jaw + TONG_D * 0.035, Vector3(-36, 8, 0),
		Vector3(1.65, 0.8, 1.05), true, "Ingot")
	_ingot.set_meta(&"own_glow", true)
	# ---- Particles: chimney smoke (looping), attack spit, cast spark gout, slag drip spray, palm steam.
	var top := CHIM_TOP + Vector3(0, 0.05, 0)
	_smoke = _particles(chest, "Smoke", 6, 1.7, top, Vector3(0.04, 0.02, 0.04), 0.9, 0.22, 0.5,
		[Color(0.30, 0.27, 0.25, 0.55), Color(0.36, 0.33, 0.31, 0.35), Color(0.45, 0.42, 0.40, 0.0)], false, 12.0,
		Vector3(0.0, 0.25, -0.35), false)
	_gout = _particles(chest, "Gout", 16, 0.8, top, Vector3(0.05, 0.02, 0.05), 3.4, 0.14, 0.03,
		[Color(2.8, 1.3, 0.35, 1.0), Color(2.0, 0.5, 0.08, 0.8), Color(0.5, 0.1, 0.02, 0.0)], true, 28.0, Vector3(0, -3.0, 0))
	var ing := jaw + TONG_D * 0.03
	_spit = _particles(arm_r, "Spit", 10, 0.45, ing, Vector3(0.05, 0.04, 0.05), 3.0, 0.11, 0.03,
		[Color(2.6, 1.2, 0.35, 1.0), Color(1.8, 0.4, 0.05, 0.8), Color(0.6, 0.1, 0.02, 0.0)], true, 50.0, Vector3(0, -2.0, 0))
	_drip = _particles(arm_r, "Drip", 14, 0.7, ing, Vector3(0.05, 0.05, 0.05), 3.6, 0.16, 0.05,
		[Color(2.6, 1.1, 0.25, 1.0), Color(1.6, 0.35, 0.05, 0.9), Color(0.25, 0.08, 0.03, 0.0)], true, 40.0, Vector3(0, -7.0, 0))
	_steam = _particles(arm_l, "Steam", 10, 0.6, HAND_L + Vector3(0, 0.02, 0.08), Vector3(0.05, 0.05, 0.05), 1.6, 0.18, 0.4,
		[Color(1.6, 2.0, 2.4, 0.9), Color(0.9, 1.2, 1.5, 0.45), Color(0.6, 0.7, 0.8, 0.0)], true, 35.0, Vector3(0, 1.2, 0))
	# ---- Fx: FireModel's burn (restarted when the body glows like a coal) + the kiln cracking into brick chips.
	var fx: Node3D = $Fx
	var be := _particles(fx, "BurnEmbers", 16, 0.9, Vector3(0, 0.8, 0), Vector3(0.25, 0.4, 0.25), 1.8, 0.16, 0.04,
		[Color(2.6, 0.95, 0.25, 1.0), Color(1.7, 0.36, 0.06, 0.9), Color(0.5, 0.08, 0.02, 0.0)], true, 45.0,
		Vector3(0, 1.2, 0))
	be.set_meta(&"burn_fx", true)
	var ash := _particles(fx, "AshPuff", 8, 1.0, Vector3(0, 0.5, 0), Vector3(0.25, 0.15, 0.25), 0.7, 0.35, 0.9,
		[Color(0.20, 0.16, 0.14, 0.55), Color(0.25, 0.21, 0.19, 0.30), Color(0.3, 0.26, 0.24, 0.0)], true, 60.0,
		Vector3(0, 0.4, 0), false)
	ash.set_meta(&"burn_fx", true)
	_chips = _particles(fx, "BrickChips", 12, 0.9, Vector3(0, 1.35, KZ), Vector3(0.22, 0.28, 0.18), 2.6, 0.09, 0.07,
		[Color(0.62, 0.34, 0.22, 1.0), Color(0.45, 0.24, 0.16, 1.0), Color(0.3, 0.16, 0.1, 0.0)], true, 70.0,
		Vector3(0, -9.0, 0), false)
	ensure_shadow_blob(0.5)


## The 3D pieces of the face surface (vertex colour, ~480 vertices): round ears, grey tufts behind them (the crown stays
## bald), a curled moustache, the spade beard (a jaw mass + a spade) ending in a braid bound by two bronze beads.
static func _hair_and_beard(acc: Dictionary) -> void:
	var o := func(x: float, y: float, z: float) -> Vector3: return HC + Vector3(x, y, z) * HR
	var skin := FIRE_SKIN.darkened(0.06)
	var sph := CharacterModel.sphere(1.0, 6, 3)
	var beard := GREY.darkened(0.08)
	var bronze := Color(0.66, 0.44, 0.18)
	for sx: float in [-1.0, 1.0]:
		var yaw := Basis(Vector3.UP, deg_to_rad(28.0 * sx))
		FaceKit.put_mesh(acc, sph, Transform3D(yaw.scaled_local(Vector3(0.10, 0.27, 0.18) * HR), o.call(0.93 * sx, -0.06, -0.08)),
			skin)
		# tuft behind the ear
		FaceKit.put_mesh(acc, sph, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-20.0)).scaled_local(Vector3(0.22, 0.42, 0.34) * HR),
			o.call(0.84 * sx, 0.02, -0.46)), GREY)
		# moustache: from under the nose curling out and down past the mouth
		FaceKit.put_mesh(acc, sph, Transform3D((Basis(Vector3.UP, deg_to_rad(-24.0 * sx)) * Basis(Vector3.BACK,
			deg_to_rad(-32.0 * sx))).scaled_local(Vector3(0.40, 0.12, 0.15) * HR), o.call(0.30 * sx, -0.33, 0.93)),
			GREY_TIP.darkened(0.06))
	var from: int = (acc["v"] as PackedVector3Array).size()
	# jaw mass (cheeks to chin) and the spade, flattened against the chest
	FaceKit.put_mesh(acc, CharacterModel.sphere(1.0, 8, 4), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(18.0)).scaled_local(
		Vector3(0.86, 0.62, 0.46) * HR), o.call(0.0, -0.52, 0.60)), beard)
	FaceKit.put_mesh(acc, CharacterModel.cyl(1.0, 0.0, 1.0, 6), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(22.0)).scaled_local(
		Vector3(0.62, 1.05, 0.30) * HR), o.call(0.0, -1.18, 0.78)), beard)
	# the braid under the spade, bound by two bronze beads
	var end := FaceKit.braid(acc, [o.call(0.0, -1.55, 1.0), o.call(0.0, -1.85, 1.14), o.call(0.02, -2.15, 1.22),
		o.call(0.03, -2.4, 1.24)], 3, 0.30 * HR, 0.22 * HR, beard, GREY_TIP)
	FaceKit.shade_under(acc, from, Color(0.34, 0.32, 0.31), 0.7)
	FaceKit.put_mesh(acc, sph, Transform3D(Basis.from_scale(Vector3(0.17, 0.12, 0.17) * HR), o.call(0.0, -1.62, 1.03)), bronze)
	FaceKit.put_mesh(acc, sph, Transform3D(Basis.from_scale(Vector3(0.14, 0.12, 0.14) * HR), end + Vector3(0, 0.035, 0.0)),
		bronze)


# ================================================================ meshes (cached, model space)

## Surface of revolution around the model Y axis through `prof` (x = radius, y = height), `seg` sides. `cap` closes the
## top ring when its radius is > 0 (flat lid).
static func _lathe(key: String, prof: PackedVector2Array, seg: int, smooth: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if not smooth:
		st.set_smooth_group(-1)
	for i: int in prof.size():
		for j: int in seg + 1:
			var a: float = TAU * float(j) / float(seg)
			st.add_vertex(Vector3(cos(a) * prof[i].x, prof[i].y, sin(a) * prof[i].x))
	for i: int in prof.size() - 1:
		for j: int in seg:
			var a0 := i * (seg + 1) + j
			var b0 := (i + 1) * (seg + 1) + j
			st.add_index(a0)
			st.add_index(b0)
			st.add_index(a0 + 1)
			st.add_index(a0 + 1)
			st.add_index(b0)
			st.add_index(b0 + 1)
	st.generate_normals()
	return _cached(key, _fix_winding(st.commit()))


## Makes the faces of a generated mesh point away from its local Y axis (outward), whatever the profile direction.
static func _fix_winding(m: ArrayMesh) -> ArrayMesh:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var out := 0.0
	for i: int in range(0, idx.size(), 3):
		var a := v[idx[i]]
		var b := v[idx[i + 1]]
		var c := v[idx[i + 2]]
		var n := (b - a).cross(c - a)
		var ctr := (a + b + c) / 3.0
		out += n.dot(Vector3(ctr.x, 0, ctr.z))
	if out < 0.0:
		return m
	# Godot's front faces are clockwise: flip every triangle and the normals.
	for i: int in range(0, idx.size(), 3):
		var t := idx[i + 1]
		idx[i + 1] = idx[i + 2]
		idx[i + 2] = t
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for i: int in nrm.size():
		nrm[i] = -nrm[i]
	arr[Mesh.ARRAY_INDEX] = idx
	arr[Mesh.ARRAY_NORMAL] = nrm
	var fixed := ArrayMesh.new()
	fixed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return fixed


## A curved panel on a cone around the model Y axis (radius r0 at y0 -> r1 at y1), from angle a0 to a1 (radians from
## +Z toward +X), `cols` columns, `thick` outward, bottom edge `sag` m longer at the middle, optional `shift`.
static func _panel(key: String, y0: float, y1: float, r0: float, r1: float, a0: float, a1: float, cols: int,
		thick: float, shift: Vector3 = Vector3.ZERO) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 3
	var pts := []
	for side: int in 2:
		for i: int in rows + 1:
			var v := float(i) / float(rows)
			for j: int in cols + 1:
				var u := float(j) / float(cols)
				var a := lerpf(a0, a1, u)
				var sag := 0.03 * (1.0 - pow(2.0 * u - 1.0, 2.0)) * (1.0 - v)
				var y := lerpf(y0, y1, v) - sag
				var r := lerpf(r0, r1, v) + (thick if side == 0 else 0.0)
				pts.append(Vector3(sin(a) * r, y, cos(a) * r) + shift)
	var n := (rows + 1) * (cols + 1)
	for side: int in 2:
		for i: int in rows:
			for j: int in cols:
				var o := side * n
				var p00: Vector3 = pts[o + i * (cols + 1) + j]
				var p01: Vector3 = pts[o + i * (cols + 1) + j + 1]
				var p10: Vector3 = pts[o + (i + 1) * (cols + 1) + j]
				var p11: Vector3 = pts[o + (i + 1) * (cols + 1) + j + 1]
				if side == 0:
					for p: Vector3 in [p00, p10, p01, p01, p10, p11]:
						st.add_vertex(p)
	# edges: bottom rim and the two sides (thickness reads at the close-up)
	for j: int in cols:
		var a: Vector3 = pts[j]
		var b: Vector3 = pts[j + 1]
		var c: Vector3 = pts[n + j]
		var d: Vector3 = pts[n + j + 1]
		for p: Vector3 in [a, b, c, c, b, d]:
			st.add_vertex(p)
	for side_j: int in [0, cols]:
		for i: int in rows:
			var a: Vector3 = pts[i * (cols + 1) + side_j]
			var b: Vector3 = pts[(i + 1) * (cols + 1) + side_j]
			var c: Vector3 = pts[n + i * (cols + 1) + side_j]
			var d: Vector3 = pts[n + (i + 1) * (cols + 1) + side_j]
			for p: Vector3 in [a, c, b, b, c, d]:
				st.add_vertex(p)
	st.index()
	st.generate_normals()
	return _cached(key, _outward(st.commit()))


## Flips triangles whose face normal points toward the model Y axis (open panels built without a winding rule).
static func _outward(m: ArrayMesh) -> ArrayMesh:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for i: int in range(0, idx.size(), 3):
		var a := v[idx[i]]
		var b := v[idx[i + 1]]
		var c := v[idx[i + 2]]
		var n := (c - a).cross(b - a)   # Godot front = clockwise: this is the visible side's normal
		var ctr := (a + b + c) / 3.0
		if n.dot(Vector3(ctr.x, 0, ctr.z)) < 0.0:
			var t := idx[i + 1]
			idx[i + 1] = idx[i + 2]
			idx[i + 2] = t
	arr[Mesh.ARRAY_INDEX] = idx
	arr[Mesh.ARRAY_NORMAL] = null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in idx.size():
		st.add_vertex(v[idx[i]])
	st.index()
	st.generate_normals()
	return st.commit()


## Tapered tube through `pts` (radii per point), one cached mesh (no caps between segments).
static func _path_mesh(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_append_path(st, pts, radii, seg, caps)
	st.index()
	return _cached(key, st.commit())


static func _append_path(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int, caps: bool) -> void:
	# G-C: one smooth continuous tube (FireShapes) instead of stacked cylinders (hard kinks at every joint).
	st.append_from(FireShapes.tube(pts, radii, seg, caps), 0, Transform3D.IDENTITY)


## The smith's tongs: two iron arms crossing at a rivet, handles spread behind the fist, curved jaws gripping the ingot.
static func _tongs_mesh() -> Mesh:
	const KEY := "kw_tongs"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var side := Vector3(1, 0, -0.08).normalized()
	var fwd := TONG_D.cross(side).normalized()   # the jaws open along this (toward the body / away)
	for s: float in [-1.0, 1.0]:
		var p0 := HAND_R - TONG_D * 0.16 + side * 0.045 * s
		var p1 := HAND_R + side * 0.028 * s
		var p3 := HAND_R + TONG_D * 0.50 - side * 0.02 * s + fwd * 0.035 * s
		var p4 := HAND_R + TONG_D * (TONG_LEN + 0.02) - side * 0.01 * s + fwd * 0.055 * s
		_append_path(st, PackedVector3Array([p0, p1, p3, p4]), PackedFloat32Array([0.021, 0.02, 0.018, 0.016]), 4, false)
	st.append_from(sphere(0.03, 6, 3), 0, Transform3D(Basis.IDENTITY, HAND_R + TONG_D * 0.42))
	st.index()
	return _cached(KEY, st.commit())


## The kiln fire: the arched firing mouth on the back (a flattened dome) + the coals glowing at the chimney lip.
static func _kiln_fire_mesh() -> Mesh:
	const KEY := "kw_kiln_fire"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.append_from(sphere(0.1, 8, 4), 0, Transform3D(Basis.from_scale(Vector3(1.0, 1.3, 0.45)), MOUTH))
	st.append_from(sphere(0.09, 8, 3), 0, Transform3D(Basis.from_scale(Vector3(1.0, 0.45, 1.0)), CHIM_TOP + Vector3(0, -0.005, 0)))
	# a short flame tongue licking out of the chimney (the "walking forge" read from above), leaning back with the draught
	st.append_from(cyl(0.0, 0.07, 0.13, 6), 0, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-12.0)), CHIM_TOP + Vector3(0, 0.07, -0.01)))
	st.append_from(cyl(0.0, 0.04, 0.09, 5), 0, Transform3D(Basis(Vector3.BACK, deg_to_rad(20.0)), CHIM_TOP + Vector3(-0.04, 0.05, 0.0)))
	st.index()
	return _cached(KEY, st.commit())


## Pre-built GPUParticles3D (keep_separate). cols along the life; one_shot = restarted by this script.
func _particles(parent: Node3D, pname: String, amount: int, lifetime: float, model_pos: Vector3, ext: Vector3,
		vel: float, size_a: float, size_b: float, cols: Array, one_shot: bool, spread: float, grav: Vector3,
		additive: bool = true) -> GPUParticles3D:
	var key := "kw_pp_%s" % pname
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
	gp.visibility_aabb = AABB(Vector3(-2, -1.5, -2), Vector3(4, 4.5, 4))
	gp.position = model_pos - model_origin(parent)
	gp.set_meta(&"keep_separate", true)
	parent.add_child(gp)
	return gp


# ================================================================ VFX hooks (world space)

## Where the Slag Rain glob leaves (the ingot in the tongs' jaws), world space.
func get_ingot_point() -> Vector3:
	if _ingot and is_inside_tree():
		return _ingot.global_position
	return global_position + Vector3.UP * 1.7


## Where the Mana Scald steam lash leaves (the left palm), world space.
func get_palm_point() -> Vector3:
	var arm := get_node_or_null(^"Root/Chest/ArmL") as Node3D
	if arm and is_inside_tree():
		return arm.global_transform * (HAND_L - model_origin(arm))
	return global_position + Vector3.UP * 1.1


## The kiln mouth (world space): the Stoke passive's ember lands here.
func get_kiln_point() -> Vector3:
	var chest := get_node_or_null(^"Root/Chest") as Node3D
	if chest and is_inside_tree():
		return chest.global_transform * (MOUTH - model_origin(chest))
	return global_position + Vector3.UP * 1.1


# ================================================================ motion

func _after_ready() -> void:
	super()
	_write_glows(true)


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"caster_fire":
		return super(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, P_ARM_R_X) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, P_CHEST_X) * DEG, _kf(t, P_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _kf(t, P_ROOT_Z)))
	if _tier == 0:
		rot(P_ARM_L, Vector3(_kf(t, P_ARM_L_X) * DEG, 0, 0))
	var rel: float = attack_windup if attack_windup > 0.0 else 0.15
	_heat = 0.8 * smoothstep(0.0, rel, t) * (1.0 - smoothstep(rel + 0.05, 0.5, t))
	_flare = 0.25 * _heat
	if prev < rel and t >= rel:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	if spell == &"mana_scald":
		rot(P_ARM_L, Vector3(_kf(t, M_ARM_L_X) * DEG, 0, 0))
		pos(P_ARM_L, Vector3(0, 0, _kf(t, M_ARM_L_Y)))
		rot(P_ARM_R, Vector3(_kf(t, M_ARM_R_X) * DEG, 0, 0))
		rot(P_CHEST, Vector3(_kf(t, M_CHEST_X) * DEG, _kf(t, M_CHEST_Y) * DEG, 0))
		pos(P_ROOT, Vector3(0, 0, _kf(t, M_ROOT_Z)))
		if _tier == 0:
			rot(P_HEAD, Vector3(_kf(t, M_HEAD_X) * DEG, 0, 0))
		if not _fired and t >= SCALD_RELEASE:
			_fired = true
			_scald_t = 0.2
			if _steam and _tier < 2:
				_steam.restart()
			cast_released.emit(&"mana_scald", get_palm_point())
		return SCALD_LEN
	# slag_rain (and any other id: the big fling)
	rot(P_ARM_R, Vector3(_kf(t, S_ARM_R_X) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, S_ARM_R_Z)))
	rot(P_ARM_L, Vector3(_kf(t, S_ARM_L_X) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, S_CHEST_X) * DEG, _kf(t, S_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, S_ROOT_Y), _kf(t, S_ROOT_Z)))
	if _tier == 0:
		rot(P_LEG_L, Vector3(_kf(t, S_STEP_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_kf(t, S_STEP_R) * DEG, 0, 0))
	_flare = _kf(t, S_FLARE)
	_heat = _flare
	if not _fired and t >= SLAG_RELEASE:
		_fired = true
		if _tier < 2:
			if _drip:
				_drip.restart()
			if _gout:
				_gout.restart()
		cast_released.emit(&"slag_rain", get_ingot_point())
	return SLAG_LEN


func _on_action_event(ev: StringName) -> void:
	super(ev)
	match ev:
		&"release":
			if _spit and _tier < 2:
				_spit.restart()
		&"cast_start":
			_fired = false
		&"attack_end", &"cast_end":
			_flare = 0.0
			_heat = 0.0
		&"death_glow_off":
			_flare = 0.0
			_heat = 0.0
			if _smoke:
				_smoke.emitting = false
			if _chips and _tier < 2:
				_chips.restart()


## Heavy stooped trudge: leaning into the load, a side roll with each step, the kiln rocking, tongs held steady.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_CHEST, Vector3(6.0 * DEG * w, 0, 3.0 * DEG * s * w))
	rot(P_ARM_R, Vector3(-9.0 * DEG * s * w, 0, 0))
	if _tier > 0:
		return
	rot(P_ROOT, Vector3(3.0 * DEG * w, 0, 2.5 * DEG * s * w))
	rot(P_HIPS, Vector3(0, 5.0 * DEG * s * w, 0))
	rot(P_HEAD, Vector3(-5.0 * DEG * w, 0, -2.0 * DEG * s * w))


func _extra_process(dt: float) -> void:
	super(dt)
	if _kiln_fire == null:
		return
	if _dead:
		# The kiln gutters out with the burn.
		var k: float = 1.0 - smoothstep(0.15, 0.6, _death_t)
		_write_kiln(KILN_GLOW * k * (1.0 + 0.6 * smoothstep(0.0, 0.15, _death_t)))
		_write_ingot(INGOT_GLOW * k)
		if _scald_flash.visible:
			_scald_flash.visible = false
		return
	if _action == &"":
		_flare = move_toward(_flare, 0.0, dt * 3.0)
		_heat = move_toward(_heat, 0.0, dt * 3.0)
	var flick: float = 0.0
	if _tier == 0:
		flick = 0.10 * sin(_t * 11.0) + 0.06 * sin(_t * 6.7 + 1.3)
	_write_kiln(KILN_GLOW * (1.0 + flick + 2.2 * _flare))
	_write_ingot(INGOT_GLOW * (1.0 + 0.08 * sin(_t * 2.1) + 1.6 * _heat))
	if _scald_t > 0.0:
		_scald_t -= dt
		if not _scald_flash.visible:
			_scald_flash.visible = true
		_scald_flash.set_instance_shader_parameter(&"glow_boost", snappedf(3.0 * glow_level() * clampf(_scald_t / 0.2, 0.2, 1.0), 0.05))
	elif _scald_flash.visible:
		_scald_flash.visible = false


func _on_revive() -> void:
	super()
	_flare = 0.0
	_heat = 0.0
	_scald_t = -1.0
	if _scald_flash:
		_scald_flash.visible = false
	if _smoke:
		_smoke.emitting = true
	_write_glows(true)


func _write_glows(force: bool) -> void:
	if force:
		_kiln_v = -1.0
		_ingot_v = -1.0
	_write_kiln(KILN_GLOW)
	_write_ingot(INGOT_GLOW)


## Glow writes (own_glow: the kit does not boost these): x veterancy / haste, 0 when dead; quantised.
func _write_kiln(v: float) -> void:
	v = snappedf(v * glow_level(), 0.05) if not _dead else snappedf(v, 0.05)
	if v == _kiln_v or _kiln_fire == null:
		return
	_kiln_v = v
	_kiln_fire.set_instance_shader_parameter(&"glow_boost", v)


func _write_ingot(v: float) -> void:
	v = snappedf(v * glow_level(), 0.05) if not _dead else snappedf(v, 0.05)
	if v == _ingot_v or _ingot == null:
		return
	_ingot_v = v
	_ingot.set_instance_shader_parameter(&"glow_boost", v)
