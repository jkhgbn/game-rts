extends "res://art/units/champions/wildcaller/wildcaller.gd"
## Maelis Oakenhollow, the Wildcaller (Nature T3 helper, t3-helpers.md 1 / 4.5 / 10; task TH.V2): the 13c Wildcaller
## (art/units/champions/wildcaller/, champion A look: the deep team hood with the tall pale antler lyre, the barred
## feather capelet and cloak, the 2.8 m living staff with its glowing crown) RAISED TO THE WIZARD BAR:
##  - a PAINTED FACE with expressions: the Wildcaller's FaceKit face, variant A (faces pass 2026-09-28: was her own
##    HelperPaint face): glowing green druid eyes, bushy silver brows, the lines of age, a thin wry mouth and a leaf-vein
##    tattoo on her left cheek; set_expression(FaceKit.EXPRESSIONS: neutral / smile / fierce / worried / shout);
##  - HAIR (hair-redesign-plan >= 70): long SILVER locks spilling out of the hood: a thick braid down her left side over
##    the capelet to the belt (team ribbon, a pink blossom tie, a wooden bead), two swept locks on the right, a forelock
##    under the brim (maelis_hair silver on the dark robe / moss: the 25 m hook);
##  - the helper hooks of t3-helpers.md 10.1: play_arrival() (3.5 s: lands crouched like the spirit stag, rises, plants
##    the staff in full bloom, looks up), play_fall(), play_revive() (rises from one knee, the crown blooms),
##    set_charge(0..1), play_gesture(id) + point() / nod() / kneel() / stand_up() / raise_weapon();
##  - the hood is merged into the Head pivot (no variant swap: helpers take no B variant); the face is ONE node.
## Abilities: the Wildcaller's own play_cast(&"thornsnare" | &"call_the_pack" | &"wild_stampede") poses, plus
## &"maelis_opinions" (the passive tell: a short crown pulse). Attack thorn_bolt (release 0.15). 0 lights.

const HP := preload("res://art/units/helpers/helper_aldra/helper_paint.gd")
const OWN_DIR := "res://art/units/helpers/helper_maelis/"
const HEAD_SCALE := Vector3(0.88, 1.06, 0.95)
const EXPRESSIONS: Array[StringName] = FaceKit.EXPRESSIONS
const ARRIVAL_ID := &"maelis_arrival"
const REVIVE_ID := &"maelis_revive"
const PASSIVE_ID := &"maelis_opinions"
const ARRIVAL_LEN := 3.5
const REVIVE_LEN := 1.2

var _charge: float = 0.0
var _kneeling: bool = false
var _pending: StringName = &""


static func _own(name: String) -> Material:
	if not _wc_mats.has("own_" + name):
		_wc_mats["own_" + name] = load(OWN_DIR + name + ".tres")
	return _wc_mats["own_" + name]


# ================================================================ helper hooks

## Arrival set-piece (t3-helpers.md 10.2): the spirit stag stops and becomes her. 3.5 s. Safe before _ready.
func play_arrival() -> void:
	_kneeling = false
	_request(ARRIVAL_ID)


## Fallen: the kit fall (death_finished after 1.0 s).
func play_fall() -> void:
	_kneeling = false
	play_death()


## Revived at the keep door: alive, rises from one knee, the crown blooms.
func play_revive() -> void:
	_kneeling = false
	revive()
	_request(REVIVE_ID)


## Crown charge 0..1 (ability wind-ups, cinematics): brighter crown, full bloom above 0.6.
func set_charge(v: float) -> void:
	_charge = clampf(v, 0.0, 1.0)


## 19.V10 gestures: point, nod, kneel (held until stand_up), stand_up, raise_weapon.
func play_gesture(id: StringName) -> void:
	if id == &"kneel":
		_kneeling = true
	elif id == &"stand_up":
		_kneeling = false
	_request(id)


func point() -> void:
	play_gesture(&"point")


func nod() -> void:
	play_gesture(&"nod")


func kneel() -> void:
	play_gesture(&"kneel")


func stand_up() -> void:
	play_gesture(&"stand_up")


func raise_weapon() -> void:
	play_gesture(&"raise_weapon")


func is_kneeling() -> bool:
	return _kneeling


## Helpers take no B variant: the hood stays up.
func set_variant(_v: int) -> void:
	variant = 0


func _request(id: StringName) -> void:
	if not _ready_done:
		_pending = id
		return
	play_cast(id)


func _after_ready() -> void:
	super._after_ready()
	if _pending != &"":
		var id := _pending
		_pending = &""
		play_cast(id)


# ================================================================ parts

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	_authored = 0
	variant = 0
	_part(leg_l, _leg_mesh(-1.0), null, Vector3.ZERO)
	_part(leg_r, _leg_mesh(1.0), null, Vector3.ZERO)
	_part(hips, _skirt_mesh(), null, Vector3.ZERO)
	_part(hips, _belt_mesh(), null, Vector3.ZERO)
	_part(chest, _torso_mesh(), null, Vector3.ZERO)
	_part(chest, _mantle_mesh(), null, Vector3.ZERO)
	_part(chest, _cloak_mesh(), null, Vector3.ZERO)
	# Head: the old face (skin only), the hood + antlers (merged), the silver hair, the FaceKit face (the Wildcaller's A)
	_part(head, _skin_mesh(), null, Vector3.ZERO)
	_part(head, _variant_mesh(0), null, Vector3.ZERO)
	_part(head, _hair_mesh(), null, Vector3.ZERO)
	_part(chest, _wolf_mesh(), null, Vector3.ZERO)
	_face = ChampionFaces.attach(self, head, "wildcaller", _face_spec, 0)
	_part(arm_l, _arm_mesh(-1.0), null, Vector3.ZERO)
	_part(arm_r, _arm_mesh(1.0), null, Vector3.ZERO)
	_staff = _part(arm_r, _staff_mesh(0), null, GRIP_R, Vector3.ZERO, true, "Staff")
	_staff.set_meta(&"own_glow", true)
	var motes := make_motes(GLOW, 6, 1.8, 0.16, 0.14, 0.05)
	motes.name = "CrownMotes"
	motes.position = Vector3(0.0, HEART_Y, 0.0)
	_staff.add_child(motes)
	_spark = make_motes(GLOW, 14, 0.5, 0.08, 1.9, 0.07, false, true)
	_spark.name = "ReleaseSparks"
	_spark.position = Vector3(0.0, HEART_Y, 0.0)
	_staff.add_child(_spark)
	var death := make_motes(PINK, 16, 1.1, 0.26, 1.0, 0.07, false, true)
	death.name = "DeathMotes"
	death.set_meta(&"death_fx", true)
	death.position = Vector3(0.0, HEART_Y, 0.0)
	_staff.add_child(death)
	_call_motes = make_motes(GLOW, 26, 1.4, 0.8, 2.4, 0.08, true, true)
	_call_motes.name = "CallMotes"
	_call_motes.position = Vector3(0.0, 0.05, 0.0)
	$Fx.add_child(_call_motes)
	ensure_shadow_blob(0.55, Color(0.04, 0.05, 0.02, 0.5))


## The face without the old glow eyes and brow lumps: neck, head, chin, the long hooked nose, cheekbones.
static func _skin_mesh() -> ArrayMesh:
	if HP.cached("maelis_skin"):
		return HP.cached("maelis_skin")
	var skin := HP.bucket()
	HP.seg(skin, Vector3(0.0, 1.50, 0.0), Vector3(0.0, 1.64, 0.03), 0.06, 0.056, 8)
	HP.put(skin, CharacterModel.sphere(HEAD_R), HP.xf(HEAD_C, Vector3.ZERO, HEAD_SCALE))
	HP.put(skin, CharacterModel.sphere(0.068, 8, 4), HP.xf(Vector3(0.0, 1.615, 0.10), Vector3.ZERO, Vector3(0.9, 0.95, 1.0)))
	HP.seg(skin, Vector3(0.0, 1.735, 0.172), Vector3(0.0, 1.662, 0.232), 0.024, 0.015, 6)
	HP.put(skin, CharacterModel.sphere(0.019, 6, 3), HP.xf(Vector3(0.0, 1.662, 0.229)))
	for sx: float in [-1.0, 1.0]:
		HP.put(skin, CharacterModel.sphere(0.03, 6, 3), HP.xf(Vector3(0.078 * sx, 1.675, 0.14), Vector3.ZERO, Vector3(0.8, 1.1, 0.8)))
	return HP.commit("maelis_skin", [[skin, _skin()]])


## Silver hair spilling from the hood: the long left braid (team ribbon, blossom tie, bead), two swept right locks, a
## forelock under the brim, a short lock under the left cheek.
static func _hair_mesh() -> ArrayMesh:
	if HP.cached("maelis_hair"):
		return HP.cached("maelis_hair")
	var hair := HP.bucket()
	var team := HP.bucket()
	var petal := HP.bucket()
	var wood := HP.bucket()
	var moss := HP.bucket()
	# hair mass framing the face inside the hood (hides the hood lining at the cheeks)
	for sx: float in [-1.0, 1.0]:
		HP.lock(hair, [], [Vector3(0.05 * sx, 1.86, 0.09), Vector3(0.14 * sx, 1.83, 0.09), Vector3(0.165 * sx, 1.74, 0.07),
			Vector3(0.16 * sx, 1.63, 0.05)], Vector3(0.7 * sx, 0.1, 0.7).normalized(), 0.10, 0.045, 5, 1.0, 8.0 * sx)
	# the forelock: from under the brim across the brow to her left
	HP.lock(hair, [], [Vector3(0.07, 1.855, 0.14), Vector3(0.02, 1.835, 0.19), Vector3(-0.05, 1.81, 0.19),
		Vector3(-0.10, 1.77, 0.16)], Vector3(0, 0.4, 1).normalized(), 0.075, 0.03, 4)
	# right side: two swept locks over the capelet
	HP.lock(hair, [], [Vector3(0.14, 1.68, 0.07), Vector3(0.20, 1.60, 0.17), Vector3(0.20, 1.50, 0.33),
		Vector3(0.22, 1.38, 0.41)], Vector3(0.5, 0.3, 0.8).normalized(), 0.10, 0.04, 5, 1.0, -20.0)
	HP.lock(hair, [], [Vector3(0.15, 1.67, 0.02), Vector3(0.23, 1.58, 0.10), Vector3(0.26, 1.48, 0.22),
		Vector3(0.29, 1.40, 0.28)], Vector3(0.8, 0.3, 0.5).normalized(), 0.085, 0.035, 4, 1.0, -10.0)
	# left side: the long braid from the hood down the capelet to the belt
	var path: Array[Vector3] = [Vector3(-0.11, 1.70, 0.10), Vector3(-0.15, 1.60, 0.21), Vector3(-0.155, 1.48, 0.35),
		Vector3(-0.165, 1.35, 0.43), Vector3(-0.16, 1.22, 0.38), Vector3(-0.15, 1.10, 0.31)]
	var end := HP.braid(hair, path, 13, 0.048, 0.032)
	HP.put(team, CharacterModel.torus(0.02, 0.04, 10), HP.xf(end + Vector3(0, -0.035, 0.0)))
	for k: int in 5:
		var a := TAU * float(k) / 5.0
		var dir := Vector3(sin(a), 0.35, cos(a) * 0.6 + 0.4).normalized()
		HP.lens(petal, end + Vector3(0, -0.035, 0.035) + dir * 0.035, dir, Vector3(cos(a), 0, -sin(a)), 0.06, 0.045, 0.012)
	HP.put(moss, CharacterModel.sphere(0.018, 6, 3), HP.xf(end + Vector3(0, -0.035, 0.05)))
	HP.put(wood, CharacterModel.sphere(0.026, 6, 3), HP.xf(end + Vector3(0, -0.075, 0.0)))
	HP.lock(hair, [], [end + Vector3(0, -0.08, -0.01), end + Vector3(0.01, -0.14, 0.0), end + Vector3(-0.01, -0.20, 0.01),
		end + Vector3(0.0, -0.26, 0.02)], Vector3(0, 0, 1), 0.085, 0.035, 4)
	return HP.commit("maelis_hair", [[hair, _own("maelis_hair")], [team, _team()], [petal, _petal()], [wood, _wood()],
		[moss, _moss()]])


## The wolf pelt (Call the Pack's mark, her asymmetric secondary shape): a grey wolf's head crouched on her RIGHT shoulder
## looking forward (ears up, dark muzzle, fangs), its pelt flowing down her right back, a forepaw hanging over the chest.
static func _wolf_mesh() -> ArrayMesh:
	if HP.cached("maelis_wolf"):
		return HP.cached("maelis_wolf")
	var fur := HP.bucket()
	var dark := HP.bucket()
	var pale := HP.bucket()
	var eye := HP.bucket()
	var hc := Vector3(0.31, 1.68, 0.02)
	var s := 1.45
	HP.put(fur, CharacterModel.sphere(0.105 * s, 10, 5), HP.xf(hc, Vector3(8, -6, 0), Vector3(1.0, 0.85, 1.15)))
	HP.put(fur, CharacterModel.sphere(0.07 * s, 8, 4), HP.xf(hc + Vector3(0.0, -0.035, 0.09) * s, Vector3.ZERO, Vector3(1.0, 0.8, 1.0)))
	HP.seg(fur, hc + Vector3(0.0, -0.03, 0.08) * s, hc + Vector3(-0.01, -0.07, 0.24) * s, 0.058 * s, 0.036 * s, 8)
	HP.put(dark, CharacterModel.sphere(0.03 * s, 6, 3), HP.xf(hc + Vector3(-0.01, -0.063, 0.25) * s, Vector3.ZERO, Vector3(1.1, 0.8, 1.0)))
	HP.seg(dark, hc + Vector3(0.0, -0.085, 0.10) * s, hc + Vector3(-0.01, -0.10, 0.22) * s, 0.035 * s, 0.022 * s, 6)
	for sx: float in [-1.0, 1.0]:
		var eb := hc + Vector3(0.055 * sx, 0.06, -0.02) * s
		HP.seg(fur, eb, eb + Vector3(0.025 * sx, 0.11, -0.02) * s, 0.04 * s, 0.004, 5, 1.0, 0.45)
		HP.seg(pale, eb + Vector3(0.0, 0.01, 0.012) * s, eb + Vector3(0.022 * sx, 0.09, -0.008) * s, 0.024 * s, 0.003, 5, 1.0, 0.3)
		HP.put(eye, CharacterModel.sphere(0.014 * s, 6, 3), HP.xf(hc + Vector3(0.042 * sx, 0.012, 0.105) * s))
		HP.seg(pale, hc + Vector3(0.018 * sx, -0.09, 0.21) * s, hc + Vector3(0.018 * sx, -0.12, 0.21) * s, 0.007 * s, 0.001, 4)
	# ruff and the pelt down the right back (overlapping fur lenses), a forepaw over the chest
	for k: int in 7:
		var a := lerpf(-0.2, 2.6, float(k) / 6.0)
		var p := Vector3(0.24 + 0.12 * cos(a) * 0.3, 1.56 - 0.07 * float(k), -0.06 - 0.05 * float(k))
		HP.lens(fur, p + Vector3(0.10, 0.0, 0.0), Vector3(0.1, -1.0, -0.35), Vector3(1, 0, 0), 0.26, 0.20, 0.05)
	for k: int in 4:
		var y := 1.58 - 0.06 * float(k)
		HP.lens(pale if k % 2 == 0 else fur, Vector3(0.36, y, 0.02 - 0.04 * float(k)), Vector3(0.3, -1.0, -0.2), Vector3(0, 0, 1), 0.16, 0.12, 0.035)
	var paw: Array[Vector3] = [Vector3(0.24, 1.55, 0.14), Vector3(0.23, 1.46, 0.30), Vector3(0.21, 1.34, 0.40)]
	HP.tube(fur, paw, 5, 0.04, 0.032, 6)
	HP.put(fur, CharacterModel.sphere(0.04, 6, 3), HP.xf(Vector3(0.21, 1.31, 0.41), Vector3.ZERO, Vector3(1.1, 0.8, 1.2)))
	for k: int in 3:
		HP.put(dark, CharacterModel.sphere(0.009, 4, 2), HP.xf(Vector3(0.195 + 0.015 * float(k), 1.285, 0.44)))
	return HP.commit("maelis_wolf", [[fur, _own("maelis_wolf")], [dark, _nat("nature_bark_dark")],
		[pale, _own("maelis_hair")], [eye, CharacterModel.palette(&"unit_eye_dark")]])

## Her moods on top of the kit's (close camera): a nod, the revive and the passive tell smile; her own casts and
## raise_weapon turn fierce.
func _face_mood() -> StringName:
	if _action == &"cast" and (_cast_id == &"nod" or _cast_id == REVIVE_ID or _cast_id == PASSIVE_ID):
		return &"smile"
	if _action == &"cast" and (OWN_CAST_IDS.has(_cast_id) or _cast_id == &"raise_weapon"):
		return &"fierce"
	return &""


# ================================================================ poses

func _pose_cast(spell: StringName, t: float) -> float:
	if spell == &"raise_weapon":
		# the living staff raised straight overhead, full bloom
		var k := _k3(t, 0.0, 0.35, 1.15, 1.6, 1.0, 1.0)
		rot(P_ARM_R, Vector3(-160.0 * DEG * k, 0, -6.0 * DEG * k))
		_staff_to(k, Vector3(0.0, 1.0, 0.05))
		rot(P_ARM_L, Vector3(-20.0 * DEG * k, 0, -38.0 * DEG * k))
		rot(P_HEAD, Vector3(-16.0 * DEG * k, 0, 0))
		rot(P_CHEST, Vector3(-6.0 * DEG * k, 0, 0))
		_bloom = maxf(_bloom, k)
		_hold = maxf(_hold, 1.6 * k)
		return 1.6
	if HP.is_gesture(spell):
		return HP.gesture_pose(self, spell, t, _kneeling)
	match spell:
		ARRIVAL_ID:
			# landed crouched (the stag's stop), rise, lift the staff and plant it (bloom, flash at 2.15), look up
			var c := 1.0 - smoothstep(0.5, 1.7, t)
			HP.kneel_weights(self, c)
			rot(P_CHEST, Vector3(14.0 * DEG * c, 0, 0))
			rot(P_HEAD, Vector3(10.0 * DEG * c, 0, 0))
			const TS: Array[float] = [0.0, 1.5, 1.95, 2.15, 2.5, 3.5]
			var arm := _kf(t, TS, [-20.0, -70.0, -95.0, -30.0, -24.0, 0.0])
			var k := 1.0 - smoothstep(2.6, 3.5, t)
			rot(P_ARM_R, Vector3(arm * DEG, 0, 4.0 * DEG * k))
			_staff_to(k, Vector3(0.0, 1.0, 0.06))
			var proud := _k3(t, 2.2, 2.6, 3.1, 3.5, 1.0, 1.0)
			rot(P_HEAD, Vector3(-12.0 * DEG * proud, 0, 0))
			rot(P_CHEST, Vector3(-5.0 * DEG * proud, 0, 0))
			rot(P_ARM_L, Vector3(-24.0 * DEG * proud, 0, -26.0 * DEG * proud))
			pos(P_ROOT, Vector3(0, -0.05 * _k3(t, 2.05, 2.15, 2.2, 2.5, 1.0, 1.0), 0))
			_bloom = maxf(_bloom, _k3(t, 2.0, 2.15, 3.1, 3.4, 1.0, 1.0))
			_hold = maxf(_hold, 1.0 + 2.4 * _k3(t, 2.05, 2.15, 2.4, 3.0, 1.0, 1.0))
			_release_at(t, 2.15, 2.8)
			return ARRIVAL_LEN
		REVIVE_ID:
			var c := 1.0 - smoothstep(0.15, 1.05, t)
			HP.kneel_weights(self, c)
			var fl := _k3(t, 0.5, 0.75, 0.9, 1.2, 1.0, 1.0)
			_bloom = maxf(_bloom, fl)
			_hold = maxf(_hold, 2.4 * fl)
			return REVIVE_LEN
		PASSIVE_ID:
			var k := _k3(t, 0.0, 0.2, 0.5, 0.8, 1.0, 1.0)
			rot(P_HEAD, Vector3(-6.0 * DEG * k, 10.0 * DEG * k, 0))
			_hold = maxf(_hold, 1.6 * k)
			return 0.8
	return super._pose_cast(spell, t)


# ================================================================ per frame

func _extra_process(dt: float) -> void:
	if not _dead:
		if _charge > 0.001:
			_hold = maxf(_hold, 2.4 * _charge)
			if _charge > 0.6:
				_bloom = maxf(_bloom, 1.0)
		if _kneeling and _action == &"":
			play_cast(&"kneel")
	super._extra_process(dt)


func _on_revive() -> void:
	super._on_revive()
