class_name EmberdartHarrierRider
extends FireModel
## Emberdart Harrier rider (stables.md 2, Fire X: the tier-1 javelin skirmisher, hit-and-run, fragile up close). Seated
## with the kit's CharacterModel.set_seated on the Emberdart Boar (parts/emberdart_boar.tscn: the Ember Boar with a
## javelin quiver on each flank); the scene pairing them is emberdart_harrier.tscn (EmberdartHarrierModel, x0.92).
## Look (the light one of the Fire riders: no helm, no shield, no lance): a lean young skirmisher in a team quilted jerkin
## and riding skirt with a crossed leather harness and a dark team sash, orange sleeves, one bronze pauldron on the throwing shoulder (asymmetric), bare
## forearms in leather bracers; a bare head with a fiery red topknot and a team headband whose long tails stream back
## with a team SCARF from the neck (FaceKit: bright green eyes, a grin, round ears, a copper fringe); a JAVELIN QUIVER on
## the back with four shafts fanning over the left shoulder (the 40 m hook together with the raised javelin); the right
## arm raised high with a javelin held overhand, tip forward (a glowing ember head, a little team streamer).
## Glow: the hand javelin's head (own glow: it hides at the throw and comes back drawn from the quiver); the boar's mane
## is the other point.
## Attack `javelin_throw` (0.62 s, release at attack_windup 0.12 s = the Unit's projectile frame): the arm cocks back
## behind the head with a twist, whips forward, the javelin leaves (hidden), the hand reaches back to the quiver and draws
## the next one (shown again at DRAW_T 0.46 s), back to the ready pose. play_charge(): a whooping lean-in with the javelin
## levelled like a short spear; charge_struck(at) at 0.10 s (javelin tip, world).
## Hooks (on top of the kit's, the names BlazeRiderModel forwards): play_charge(), get_lance_tip() / get_weapon_tip()
## (the javelin tip, world), lance_pitch() (deg, negative = tip up), couch_amount(), is_charging(), set_rank(rank) (no
## rank research for the X harrier: accepted, no look), authored_mesh_count(); signals charge_struck(at), lance_struck(at)
## (the release frame, javelin tip).
## Budget (rider, JS cap ~3000 vertices with the face): 7 draw instances at rest (Hips + legs, Chest with the quiver and
## scarf, Head, Face, ArmL, ArmR, Javelin); VetTrim hidden; no blob (the boar's shows); 1 one-shot particle system (the
## death embers); 0 lights.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

const SH_L := Vector3(-0.27, 1.36, 0.0)
const SH_R := Vector3(0.27, 1.36, 0.0)
const ELBOW_L := Vector3(-0.31, 1.08, -0.02)
const FIST_L := Vector3(-0.30, 1.04, 0.22)
## The throwing arm is authored straight and hanging (shoulder to fist), raised by the pose.
const FIST_R := Vector3(0.29, 0.85, 0.03)
const HEAD_C := Vector3(0, 1.585, 0.06)
const HEAD_R := 0.13
## Javelin (node-local at the fist, shaft along +Z): butt, head base, tip.
const JAV_BUTT := -0.55
const JAV_HEAD := 0.78
const JAV_TIP := 1.00
## Ready pose of the throwing arm (deg: x raises it forward / over, z tips it out) and the javelin aim (deg above level).
const READY_X := -158.0
const READY_Z := 14.0
const READY_PITCH := 14.0
const READY_YAW := -4.0
const THROW_LEN := 0.62
const RELEASE_T := 0.12
const DRAW_T := 0.46
const CHARGE_LEN := 0.85
const CHARGE_HIT := 0.10

# Throw tracks [t, v, ease, ...] (FireModel._kf format): arm x offset (deg, on top of READY_X), chest lean / twist,
# javelin pitch offset.
static var T_ARM := PackedFloat32Array([0.0, 0.0, 0, 0.07, -46.0, 1, 0.12, 96.0, 2, 0.22, 134.0, 0, 0.38, -34.0, 1, 0.50,
	-26.0, 0, 0.62, 0.0, 0])
static var T_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -14.0, 1, 0.12, 22.0, 2, 0.26, 16.0, 0, 0.62, 0.0, 0])
static var T_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, 36.0, 1, 0.12, -30.0, 2, 0.30, -14.0, 0, 0.62, 0.0, 0])
static var T_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, 22.0, 1, 0.12, -18.0, 2, 0.62, 0.0, 0])
static var T_RISE := PackedFloat32Array([0.0, 0.0, 0, 0.07, 0.10, 1, 0.12, 0.20, 2, 0.30, 0.08, 0, 0.62, 0.0, 0])
static var C_K := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])

var _parts_n: int = 0
var _jav: MeshInstance3D
var _embers: GPUParticles3D

var _throw_t: float = 99.0
var _charge_t: float = 99.0
var _charge_k: float = 0.0
var _cast_k: float = 0.0
var _flare: float = 0.0
var _pitch: float = READY_PITCH
var _jav_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _glow_w: float = -1.0


# ================================================================ public hooks

## The charge (the unit's charge hit): the javelin levelled like a short spear, a lean-in. 0.85 s; charge_struck(at) at
## CHARGE_HIT.
func play_charge() -> void:
	if _dead:
		return
	_charge_t = 0.0
	_flare = 1.0
	set_process(true)


## World position of the javelin tip (throw / impact VFX).
func get_lance_tip() -> Vector3:
	if _jav and _jav.is_inside_tree():
		return _jav.global_transform * Vector3(0, 0, JAV_TIP)
	return global_position + Vector3(0.3, 2.0, 0.8)


func get_weapon_tip() -> Variant:
	return get_lance_tip()


func lance_pitch() -> float:
	return -_pitch


func couch_amount() -> float:
	return _charge_k


func is_charging() -> bool:
	return _charge_t < CHARGE_LEN


func set_rank(_rank: int) -> void:
	pass


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var head: Node3D = $Root/Chest/Head
	var arm_r: Node3D = $Root/Chest/ArmR
	_sculpt($Root/Hips, "ed_hips_v2", _hips_sculpt)
	_sculpt($Root/Chest, "ed_chest_v3", _chest_sculpt)
	_sculpt(head, "ed_head_v1", _head_sculpt)
	# Face: a cocky young skirmisher: bright green eyes, a grin, freckle-warm cheeks, round ears, a swept copper fringe
	# under the headband (the red topknot is sculpted on the head).
	var copper := Color(0.72, 0.24, 0.08)
	_face = UnitFaces.attach_lean(self, head, "emberdart_harrier_rider", {"center": HEAD_C, "radius": HEAD_R,
		"head_mesh": sphere(HEAD_R, 10, 6), "head_scale": Vector3(0.95, 1.04, 0.95), "preset": &"bright", "detail": &"low",
		"skin": FIRE_SKIN, "hair": copper, "hair_tip": Color(0.98, 0.55, 0.18), "eyes": Color(0.30, 0.62, 0.24),
		"ears": &"round", "eye": {"hw": 0.028, "top": 0.020, "ir": 0.014},
		"x": {&"neutral": {"mouth": {"kind": "smirk"}}},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, HEAD_C + Vector3(0, 0.004, 0), HEAD_R, copper,
			Color(0.98, 0.55, 0.18), 1.0, 1.0)})
	_sculpt($Root/Chest/ArmL, "ed_arm_l_v1", _arm_l_sculpt)
	_sculpt(arm_r, "ed_arm_r_v1", _arm_r_sculpt)
	_jav = _sculpt(arm_r, "ed_javelin_v1", _javelin_sculpt, FIST_R, true, "Javelin")
	_jav.set_meta(&"own_glow", true)
	_jav.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var vet := add_part(head, cyl(0.155, 0.155, 0.04, 10, false), palette(&"unit_gold_trim"), Vector3(0, 1.67, 0.0),
		Vector3(-6, 0, 0), Vector3(1.0, 1.0, 1.1), true, "VetTrim")
	vet.set_meta(&"vet_trim", true)
	_parts_n += 1
	_embers = CharacterModel.make_motes(Color(1.0, 0.42, 0.08), 8, 0.9, 0.28, 1.5, 0.14, false, true)
	_embers.name = "BurnEmbers"
	_embers.set_meta(&"burn_fx", true)
	_embers.set_meta(&"keep_separate", true)
	_embers.position = Vector3(0, 0.25, 0)
	$Root/Chest.add_child(_embers)


func _sculpt(pivot: Node3D, key: String, build: Callable, at: Vector3 = Vector3.ZERO, keep: bool = false,
		nm: String = "") -> MeshInstance3D:
	_parts_n += 1
	if not keep and _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var mesh := _cached_sculpt(key, build)
	if mesh == null:
		return null
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, nm)


static func _cached_sculpt(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var s := MountModel.sculpt()
	build.call(s)
	return _cached(key, MountModel.sculpt_mesh(s))


static func m(name: String) -> Material:
	return palette(StringName(name))


static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


# ---------------------------------------------------------------- body

## Hips + legs astride (merged into Hips): quilted riding skirt, a belt with a bronze buckle and the team sash knot
## hanging at the left hip, leather trousers, bronze knee cops, soft boots in the stirrups.
func _hips_sculpt(s: Dictionary) -> void:
	var leather := m("fire_leather")
	var bronze := m("fire_bronze")
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	_put(s, cyl(0.19, 0.235, 0.22, 8), cdark, Vector3(0, 0.82, 0))
	_put(s, cyl(0.205, 0.205, 0.065, 8, false), leather, Vector3(0, 0.93, 0))
	_put(s, box(Vector3(0.07, 0.06, 0.03)), bronze, Vector3(0, 0.93, 0.21))
	# the team sash knot and its two tails over the left hip
	_put(s, sphere(0.05, 6, 3), cloth, Vector3(-0.19, 0.92, 0.1))
	_put(s, box(Vector3(0.07, 0.26, 0.02)), cloth, Vector3(-0.23, 0.80, 0.08), Vector3(10, 0, -14))
	_put(s, box(Vector3(0.06, 0.20, 0.02)), cdark, Vector3(-0.21, 0.80, 0.14), Vector3(-8, 0, -8))
	# the skirt's back flap over the cantle
	_put(s, box(Vector3(0.30, 0.34, 0.03)), cloth, Vector3(0, 0.75, -0.23), Vector3(16, 0, 0))
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.11 * sx, 0.83, 0.02)
		var knee := Vector3(0.40 * sx, 0.62, 0.24)
		var ankle := Vector3(0.49 * sx, 0.40, 0.12)
		_seg(s, leather, hip, knee, 0.09, 0.07, 6)
		_put(s, sphere(0.07, 6, 3), bronze, knee + Vector3(0.01 * sx, 0.01, 0.035), Vector3.ZERO, Vector3(1.0, 1.1, 0.9))
		_seg(s, leather, knee, ankle + Vector3(0, -0.04, 0), 0.066, 0.06, 6)
		MountModel.sculpt_add(s, cyl(0.055, 0.066, 0.25, 6), Transform3D(_to_dir(Vector3(0.05 * sx, 0.03, 1.0)),
			ankle + Vector3(0.01 * sx, -0.05, 0.09)), leather)


func _chest_sculpt(s: Dictionary) -> void:
	var leather := m("fire_leather")
	var bronze := m("fire_bronze")
	var cloth := m("fire_cloth")
	var wood := m("fire_wood")
	var skin := m("fire_skin")
	# the lean quilted jerkin (orange), a leather collar
	var prof := PackedVector2Array([Vector2(0.18, 0.90), Vector2(0.205, 1.0), Vector2(0.235, 1.14), Vector2(0.245, 1.25),
		Vector2(0.22, 1.35), Vector2(0.13, 1.43), Vector2(0.0, 1.45)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("ed_torso_v1", prof, 8),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.8)), Vector3.ZERO), cloth)
	_put(s, cyl(0.10, 0.14, 0.08, 8, false), leather, Vector3(0, 1.43, 0))
	# the crossed harness straps and the diagonal team sash (right shoulder to left hip)
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.05, 0.50, 0.03)), leather, Vector3(0.02 * sx, 1.17, 0.19), Vector3(-6, 0, 30.0 * sx))
	_put(s, box(Vector3(0.09, 0.56, 0.035)), m("fire_cloth_dark"), Vector3(0.0, 1.16, 0.205), Vector3(-6, 0, -34))
	_put(s, sphere(0.035, 6, 3), bronze, Vector3(0, 1.17, 0.215))
	# ONE bronze pauldron, on the throwing shoulder (the asymmetric read), a leather cap on the other
	var pf := MountModel.frame(Vector3(0.29, 1.40, -0.01), Vector3(0.55, 1.0, 0.0), Vector3.BACK)
	MountModel.sculpt_add(s, MountModel.lathe_mesh("ed_pauldron_v1", PackedVector2Array([Vector2(0.15, -0.06),
		Vector2(0.155, 0.0), Vector2(0.12, 0.05), Vector2(0.0, 0.075)]), 8), pf, bronze)
	_put(s, sphere(0.09, 6, 3), leather, Vector3(-0.28, 1.40, 0.0), Vector3(0, 0, 15), Vector3(1.0, 0.6, 1.1))
	# the javelin quiver on the back, slung from the right hip over the left shoulder, four shafts fanning up
	var qa := Vector3(-0.30, 1.0, -0.12).normalized()
	var q0 := Vector3(0.10, 1.02, -0.24)
	_seg(s, m("fire_cloth_dark"), q0, q0 + qa * 0.52, 0.075, 0.09, 6)
	_put(s, cyl(0.095, 0.095, 0.04, 6, false), bronze, q0 + qa * 0.50, Vector3(0, 0, 16.7))
	for k: int in 4:
		var f := float(k) - 1.5
		var jd := (qa + Vector3(0.08 * f, 0.0, -0.06 * absf(f))).normalized()
		var base := q0 + qa * 0.30 + Vector3(0.02 * f, 0, 0)
		var ln: float = 0.78 + 0.05 * (1.5 - absf(f))
		_seg(s, wood, base, base + jd * ln, 0.014, 0.014, 4)
		MountModel.sculpt_add(s, cyl(0.0, 0.03, 0.11, 4), Transform3D(_to_dir(jd), base + jd * (ln + 0.05)), bronze)
	# the team scarf knotted at the throat, its long tail streaming back over the quiver
	_put(s, sphere(0.06, 6, 3), cloth, Vector3(0.05, 1.42, 0.12))
	_put(s, cape(0.28, 0.74), m("fire_cape"), Vector3(-0.06, 1.18, -0.30), Vector3(38, 8, 4))
	_put(s, cyl(0.06, 0.07, 0.10, 6), skin, Vector3(0, 1.47, 0.02))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("fire_skin")
	var hair := m("fire_hair")
	var cloth := m("fire_cloth")
	_put(s, sphere(HEAD_R, 10, 6), skin, HEAD_C, Vector3.ZERO, Vector3(0.95, 1.04, 0.95))
	# the red hair: a close cap, a tall topknot flaring back like a flame
	_put(s, sphere(HEAD_R + 0.012, 8, 4), hair, HEAD_C + Vector3(0, 0.035, -0.022), Vector3(-12, 0, 0), Vector3(1.0, 0.9, 1.05))
	MountModel.sculpt_add(s, MountModel.tube_mesh("ed_topknot_v1", PackedVector3Array([HEAD_C + Vector3(0, 0.12, -0.03),
		HEAD_C + Vector3(0, 0.22, -0.07), HEAD_C + Vector3(0, 0.27, -0.17), HEAD_C + Vector3(0, 0.24, -0.29)]),
		PackedFloat32Array([0.05, 0.055, 0.035, 0.0]), 5, true, 0.6), Transform3D.IDENTITY, hair)
	_put(s, cyl(0.03, 0.04, 0.04, 5), cloth, HEAD_C + Vector3(0, 0.125, -0.03))
	# the team headband and its two tails streaming back
	_put(s, cyl(0.138, 0.138, 0.035, 10, false), cloth, HEAD_C + Vector3(0, 0.05, -0.005), Vector3(-8, 0, 0), Vector3(1.0, 1.0, 1.06))
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.035, 0.012, 0.22)), cloth, HEAD_C + Vector3(0.035 * sx, 0.03, -0.24), Vector3(-18, 10.0 * sx, 0))


func _arm_l_sculpt(s: Dictionary) -> void:
	var sec := m("fire_sec_rider")
	var skin := m("fire_skin")
	var leather := m("fire_leather")
	_seg(s, sec, SH_L + Vector3(0, 0.02, 0), ELBOW_L, 0.07, 0.06, 6)
	_seg(s, skin, ELBOW_L, FIST_L - (FIST_L - ELBOW_L).normalized() * 0.1, 0.054, 0.05, 6)
	_seg(s, leather, FIST_L - (FIST_L - ELBOW_L).normalized() * 0.15, FIST_L - (FIST_L - ELBOW_L).normalized() * 0.03, 0.058,
		0.056, 6)
	_put(s, sphere(0.058, 6, 3), leather, FIST_L)


## The throwing arm, authored straight and hanging (the pose raises it): orange sleeve, a bare forearm, a leather
## bracer, the fist.
func _arm_r_sculpt(s: Dictionary) -> void:
	var sec := m("fire_sec_rider")
	var skin := m("fire_skin")
	var leather := m("fire_leather")
	var el := SH_R.lerp(FIST_R, 0.5)
	_seg(s, sec, SH_R + Vector3(0, 0.02, 0), el, 0.072, 0.062, 6)
	_seg(s, skin, el, FIST_R + Vector3(0, 0.1, 0), 0.056, 0.05, 6)
	_seg(s, leather, FIST_R + Vector3(0, 0.2, 0), FIST_R + Vector3(0, 0.05, 0), 0.06, 0.058, 6)
	_put(s, sphere(0.06, 6, 3), leather, FIST_R)


## The hand javelin (keep_separate "Javelin", node-local at the fist, shaft along +Z): a wooden shaft, a leather grip,
## a barbed bronze collar, the glowing ember head, a little team streamer.
func _javelin_sculpt(s: Dictionary) -> void:
	var wood := m("fire_wood")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var cloth := m("fire_cloth")
	var glow := m("fire_glow")
	var z := Basis(Vector3.RIGHT, PI * 0.5)   # +Y -> +Z
	MountModel.sculpt_add(s, cyl(0.02, 0.024, JAV_HEAD - JAV_BUTT, 5), Transform3D(z, Vector3(0, 0, (JAV_BUTT + JAV_HEAD) * 0.5)),
		wood)
	MountModel.sculpt_add(s, cyl(0.032, 0.032, 0.16, 5), Transform3D(z, Vector3(0, 0, 0.0)), leather)
	MountModel.sculpt_add(s, cyl(0.03, 0.02, 0.06, 5), Transform3D(z, Vector3(0, 0, JAV_HEAD - 0.02)), bronze)
	MountModel.sculpt_add(s, MountModel.tube_mesh("ed_jav_head_v1", PackedVector3Array([Vector3(0, 0, JAV_HEAD),
		Vector3(0, 0, JAV_HEAD + 0.07), Vector3(0, 0, JAV_TIP)]), PackedFloat32Array([0.035, 0.05, 0.0]), 5, true, 0.45),
		Transform3D.IDENTITY, glow)
	MountModel.sculpt_add(s, box(Vector3(0.01, 0.10, 0.16)), Transform3D(Basis.IDENTITY, Vector3(0, -0.06, JAV_HEAD - 0.12)), cloth)


# ================================================================ motion

func _after_ready() -> void:
	super()
	if _embers and not _burn_fx.has(_embers):
		_burn_fx.append(_embers)
	_write_glow()


## `javelin_throw`: cock, whip, release at attack_windup (the Unit spawns the javelin), reach back to the quiver, draw
## the next one at DRAW_T. The arm is posed in _pose_seated (after the kit's reins); this runs the clock, the body and
## the javelin's visibility.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"javelin_throw":
		return super._pose_attack(prev, t)
	_throw_t = t
	rot(P_CHEST, Vector3(_kf(t, T_LEAN) * DEG, _kf(t, T_TWIST) * DEG, 0))
	rot(P_HEAD, Vector3(-_kf(t, T_LEAN) * 0.5 * DEG, -_kf(t, T_TWIST) * 0.6 * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, T_RISE), _kf(t, T_RISE) * 0.5))   # up in the stirrups (the seat keeps half of it)
	var rel: float = attack_windup if attack_windup > 0.0 else RELEASE_T
	if prev < rel and t >= rel:
		_on_action_event(&"release")
		lance_struck.emit(get_lance_tip())
		if _jav:
			_jav.visible = false
	if prev < DRAW_T and t >= DRAW_T and _jav and not _dead:
		_jav.visible = true
		_flare = 0.8
	if t >= THROW_LEN:
		_throw_t = 99.0
		if _jav and not _dead:
			_jav.visible = true
	return t < THROW_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	if ev == &"attack_end":
		_throw_t = 99.0
		if _jav and not _dead:
			_jav.visible = true


## A war-cry salute for any cast: the javelin pumped high.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.15, 0.45, 0.7, 1.0, 1.0)
	rot(P_CHEST, Vector3(-8.0 * DEG * _cast_k, 0, 0))
	return 0.7


func _extra_process(dt: float) -> void:
	super(dt)
	if _action != &"attack":
		_throw_t = 99.0
	if _action != &"cast":
		_cast_k = 0.0
	if _charge_t < CHARGE_LEN:
		var prev := _charge_t
		_charge_t += dt
		_charge_k = _kf(_charge_t, C_K) if not _dead else 0.0
		if prev < CHARGE_HIT and _charge_t >= CHARGE_HIT and not _dead:
			charge_struck.emit(get_lance_tip())
		if _charge_t >= CHARGE_LEN:
			_charge_k = 0.0
	else:
		_charge_k = 0.0
	_flare = maxf(0.0, _flare - dt / 0.5)
	_write_glow()


## Riding: the kit's seat pose; the throwing arm raised (the ready pose, the throw, the charge's levelled javelin), the
## left hand on the reins; the javelin aimed in the model frame.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(1.5 * sin(2.0 * TAU * gait), 5.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var ck := _charge_k
	var ax: float = READY_X + bounce * 0.6 + 70.0 * ck - 12.0 * _cast_k
	var pitch: float = READY_PITCH - 12.0 * ck + 40.0 * _cast_k
	if _throw_t < THROW_LEN:
		ax += _kf(_throw_t, T_ARM)
		pitch += _kf(_throw_t, T_PITCH)
	# replace the kit's reins angles on the throwing arm (sar = this frame's other offsets: hits, deaths)
	_off_rot[P_ARM_R] = sar + Vector3(ax * DEG, 0, (READY_Z - 6.0 * ck) * DEG) * w
	if ck > 0.0:
		rot(P_CHEST, Vector3(12.0 * DEG * ck * w, -6.0 * DEG * ck * w, 0))
		rot(P_HEAD, Vector3(-10.0 * DEG * ck * w, 4.0 * DEG * ck * w, 0))
	if not _dead:
		_pitch = pitch
		_aim_javelin(pitch, READY_YAW)


## Turns the javelin (child of ArmR) so it points along pitch / yaw (deg) in the model frame.
func _aim_javelin(pitch_deg: float, yaw_deg: float) -> void:
	if _jav == null:
		return
	var pr := pitch_deg * DEG
	var yr := yaw_deg * DEG
	var d := Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr))
	var up := Vector3.UP - d * d.y
	if up.length_squared() < 1e-4:
		up = Vector3.BACK
	up = up.normalized()
	var want := Basis(up.cross(d), up, d)
	var rb := Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT])
	var bc := Basis.from_euler(_rest_rot[P_CHEST] + _off_rot[P_CHEST])
	var ba := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R])
	var q := ((rb * bc * ba).inverse() * want).orthonormalized().get_rotation_quaternion()
	if not q.is_equal_approx(_jav_q_w):
		_jav_q_w = q
		_jav.quaternion = q


func _write_glow() -> void:
	if _jav == null:
		return
	var g: float = snappedf(glow_level() * (1.0 + 1.4 * _flare + 0.6 * _charge_k), 0.05)
	if g != _glow_w:
		_glow_w = g
		_jav.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	super()
	_throw_t = 99.0
	_charge_t = 99.0
	_charge_k = 0.0
	_cast_k = 0.0
	_flare = 0.0
	_pitch = READY_PITCH
	_jav_q_w = Quaternion(0, 0, 0, 0)
	_glow_w = -1.0
	if _jav:
		_jav.visible = true
	_write_glow()
