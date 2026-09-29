extends WizardModel
## Shared layer of the T3 helper models (t3-helpers.md 10.1 parity checklist): standard kit hooks + the helper hooks
## `play_arrival()`, `play_fall()`, `play_revive()`, `set_charge(0..1)`, `play_gesture(id)` (19.V10: point, nod, kneel,
## stand_up, raise_weapon / raise_sword, bow, shrug, push, turn_head_left / right, draw_knives, offer_hand) and
## `set_expression(id)` (FaceKit face, faces pass 2026-09-28: FaceKit.EXPRESSIONS, one Face node per helper). Abilities come in through
## `play_cast(<ability id>)` (the ids of t3-helpers.md 4.2 / 4.3); subclasses pose them in `_pose_ability`.
## 0 lights (emission only): WizardModel's orb / light fields stay null here, the subclass drives `_glow_main`.
## Preload-only base (no class_name): Old Vey and Mother Hush extend it by path.

const HELPER_EXPRESSIONS: Array[StringName] = FaceKit.EXPRESSIONS
const ARRIVAL_LEN := 1.5
const REVIVE_LEN := 1.1

var _charge: float = 0.0            # set_charge (cinematics / ability wind-ups): brighter weapon glow
var _boost: float = 0.0             # extra weapon glow requested by this frame's pose (reset each frame)
var _glow_main: GeometryInstance3D  # the signature glow part (own_glow)
var _glow_main_w: float = -1.0
var _gest: StringName = &""
var _kneel_on: bool = false
var _expr: StringName = &"neutral"
## The FaceKit Face node (the subclass attaches it in _build_parts: FaceKit.attach(self, head, key, style)).
var _face: FaceRig
var _veiled: bool = false


# ================================================================ helper hooks

## Arrival set-piece (t3-helpers.md 10.2): rises out of a crouch, weapon flourish. 1.5 s.
func play_arrival() -> void:
	_kneel_on = false
	play_cast(&"arrival")


## Fallen: the kit death (fall) with the model's own death extras; `death_finished` after 1.0 s.
func play_fall() -> void:
	play_death()


## Back at the keep door: alive again, rises from one knee.
func play_revive() -> void:
	revive()
	play_cast(&"revive")


func set_charge(v: float) -> void:
	_charge = clampf(v, 0.0, 1.0)


func get_charge() -> float:
	return _charge


## Cinematic gestures (story-episode-1.md 19.V10). `kneel` holds until `stand_up` (or any attack / cast).
func play_gesture(id: StringName) -> void:
	if _dead:
		return
	_gest = id
	if id == &"raise_sword":
		_gest = &"raise_weapon"
	_kneel_on = _gest == &"kneel"
	play_cast(&"gesture")


func set_expression(id: StringName) -> void:
	_expr = FaceKit.canonical(id)
	if _face:
		_face.set_expression(_expr)
	_update_face()


func get_expression() -> StringName:
	return _expr


func set_status(id: StringName, on: bool) -> bool:
	if id == &"veiled" or id == &"shroud":
		_veiled = on
		_on_veil(on)
		return true
	return super.set_status(id, on)


# ================================================================ subclass API

## Pose one ability / cast id; return its length (s), or -1.0 when the id is not the subclass's (base poses it).
func _pose_ability(_spell: StringName, _t: float) -> float:
	return -1.0


func _on_veil(_on: bool) -> void:
	pass


## Per-frame subclass extras (after the glow write).
func _helper_process(_dt: float) -> void:
	pass


# ================================================================ poses

func _pose_cast(spell: StringName, t: float) -> float:
	var own := _pose_ability(spell, t)
	if own >= 0.0:
		return own
	match spell:
		&"arrival":
			return _pose_rise(t, ARRIVAL_LEN, 0.55)
		&"revive":
			return _pose_rise(t, REVIVE_LEN, 0.45)
		&"gesture":
			return _pose_gesture(_gest, t)
	return super._pose_cast(spell, t)


## Rise from a crouch on one knee (arrival / revive): low until 30 %, up by `up_at`, a proud settle.
func _pose_rise(t: float, length: float, up_at: float) -> float:
	var low := 1.0 - smoothstep(0.25 * length, up_at * length, t)
	_kneel_pose(low)
	var proud := _k3(t, up_at * length, (up_at + 0.15) * length, 0.85 * length, length, 1.0, 1.0)
	rot(P_HEAD, Vector3(-10.0 * DEG * proud, 0, 0))
	rot(P_CHEST, Vector3(-5.0 * DEG * proud, 0, 0))
	_boost = maxf(_boost, 2.5 * (1.0 - smoothstep(0.0, length, t)) + 1.5 * proud)
	return length


## One knee down (left knee), torso bowed, head down; w = 0-1.
func _kneel_pose(w: float) -> void:
	if w <= 0.0:
		return
	pos(P_ROOT, Vector3(0, -0.42 * w, -0.05 * w))
	rot(P_LEG_R, Vector3(-78.0 * DEG * w, 0, 0))
	rot(P_LEG_L, Vector3(62.0 * DEG * w, 0, 0))
	rot(P_CHEST, Vector3(16.0 * DEG * w, 0, 0))
	rot(P_HEAD, Vector3(12.0 * DEG * w, 0, 0))
	rot(P_ARM_R, Vector3(-22.0 * DEG * w, 0, 0))
	rot(P_ARM_L, Vector3(-10.0 * DEG * w, 0, 8.0 * DEG * w))


func _pose_gesture(id: StringName, t: float) -> float:
	match id:
		&"kneel":
			_kneel_pose(smoothstep(0.0, 0.45, t))
			return 1.0e9 if _kneel_on else 0.45
		&"stand_up":
			_kneel_pose(1.0 - smoothstep(0.0, 0.55, t))
			return 0.6
		&"nod":
			rot(P_HEAD, Vector3(18.0 * DEG * _k3(t, 0.0, 0.12, 0.2, 0.45, 1.0, 1.0), 0, 0))
			return 0.5
		&"bow":
			var k := _k3(t, 0.0, 0.25, 0.55, 0.9, 1.0, 1.0)
			rot(P_CHEST, Vector3(30.0 * DEG * k, 0, 0))
			rot(P_HEAD, Vector3(14.0 * DEG * k, 0, 0))
			rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, 20.0 * DEG * k))
			return 0.9
		&"shrug":
			var k := _k3(t, 0.0, 0.15, 0.35, 0.6, 1.0, 1.0)
			pos(P_ARM_L, Vector3(0, 0.08 * k, 0))
			pos(P_ARM_R, Vector3(0, 0.08 * k, 0))
			rot(P_ARM_L, Vector3(-25.0 * DEG * k, 0, -25.0 * DEG * k))
			rot(P_HEAD, Vector3(0, 0, 10.0 * DEG * k))
			return 0.6
		&"turn_head_left", &"turn_head_right":
			var sgn := 1.0 if id == &"turn_head_left" else -1.0
			rot(P_HEAD, Vector3(0, 40.0 * DEG * sgn * _k3(t, 0.0, 0.2, 0.6, 0.8, 1.0, 1.0), 0))
			return 0.8
		&"point", &"offer_hand":
			var k := _k3(t, 0.0, 0.2, 0.6, 0.8, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-80.0 * DEG * k, 0, -10.0 * DEG * k))
			rot(P_CHEST, Vector3(0, 12.0 * DEG * k, 0))
			rot(P_HEAD, Vector3(0, -6.0 * DEG * k, 0))
			return 0.8
		&"push":
			var k := _k3(t, 0.0, 0.1, 0.25, 0.6, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-85.0 * DEG * k, 0, 0))
			pos(P_ARM_L, Vector3(0, 0, 0.25 * k))
			rot(P_CHEST, Vector3(8.0 * DEG * k, 18.0 * DEG * k, 0))
			pos(P_ROOT, Vector3(0, 0, 0.15 * k))
			return 0.6
		&"raise_weapon":
			var k := _k3(t, 0.0, 0.3, 0.9, 1.2, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-150.0 * DEG * k, 0, 10.0 * DEG * k))
			rot(P_HEAD, Vector3(-14.0 * DEG * k, 0, 0))
			rot(P_CHEST, Vector3(-6.0 * DEG * k, 0, 0))
			_boost = maxf(_boost, 2.0 * k)
			return 1.2
	# unknown gesture: a small nod
	rot(P_HEAD, Vector3(12.0 * DEG * _k3(t, 0.0, 0.12, 0.2, 0.4, 1.0, 1.0), 0, 0))
	return 0.4


# ================================================================ per frame

func _wizard_process(dt: float) -> void:
	_update_face()
	if _glow_main:
		var g := glow_level() * (1.0 + _boost + 1.6 * _charge)
		if _dead:
			g = maxf(0.0, 3.0 * (1.0 - _death_t / 0.6))
		if absf(g - _glow_main_w) > 0.01:
			_glow_main_w = g
			_glow_main.set_instance_shader_parameter(&"glow_boost", g)
	_helper_process(dt)
	_boost = 0.0


## The mood shown over a neutral request (close camera only): dying = worried, a level-up / the revive / a nod or bow
## = smile, the big abilities (_shout_ids) = shout, attacks and other abilities = fierce; gestures keep the resting face.
func _face_target() -> StringName:
	if _dead:
		return &"worried"
	if _level_t < 1.6 or (_action == &"cast" and (_cast_id == &"revive" or (_cast_id == &"gesture" and (_gest == &"nod" or _gest == &"bow")))):
		return &"smile"
	if _action == &"cast" and _shout_ids().has(_cast_id):
		return &"shout"
	if _action == &"attack" or (_action == &"cast" and _cast_id != &"gesture" and _cast_id != &"arrival" and _cast_id != &"revive"):
		return &"fierce"
	return &""


## Ability ids whose cast shouts (the subclass's big moves).
func _shout_ids() -> Array[StringName]:
	return []


func _update_face() -> void:
	if _face == null:
		return
	if _tier != 0:
		_face.far()   # the bold RTS-distance face (30 m+)
		return
	_face.react(_face_target())


func _on_revive() -> void:
	super._on_revive()
	_glow_main_w = -1.0
	_kneel_on = false
	if _face:
		_face.reset()
	_update_face()
