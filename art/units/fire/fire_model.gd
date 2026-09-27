class_name FireModel
extends CharacterModel
## Fire army model script (art-units.md section 4, tasks 4.V2 + A.4 polish). Scenes: build_fire_units.gd.
## On top of the shared kit (hooks, merge, tiers unchanged):
##  - per-unit walk flavour (lean, hip twist, waddle, shield held steady, rider absorbing the gallop),
##  - attack timelines with anticipation and follow-through (same strike / release frames as art-units.md 6.4:
##    melee strike <= 0.12 s, ranged release = attack_windup),
##  - deaths: stagger + the kit's fall, then the body glows like a coal and burns away in embers (1.0 s kept),
##  - Ember Archer: the bow swings up vertical, the drawn "V" string + a glowing nocked arrow show until release,
##  - Ash Hurler: the ash ball smoulders, heats up in the wind-up, hides at the release, comes back hot at 0.8 s,
##  - Cinder Hand: crystal-blue sparks at the pick on every mine hit.
## All extra motion goes through the kit's rot() / pos() offsets; no allocation, no get_node per frame.

## worker, guard, archer, rider, hurler (set by the build script).
@export var fire_kind: StringName = &"guard"

const BALL_BACK := 0.8
const BALL_IDLE := 0.0
const BURN_T0 := 0.42
const EMBER := Vector3(1.0, 0.30, 0.05)

# Keyframes (static, built once per class): [t, value, ease] triples (value in degrees or metres; ease of the segment arriving at the key:
# 0 smooth, 1 ease-out = snappy start, 2 ease-in = accelerating into the key).
# -- Flame Guard, melee_swing (strike 0.11 s): overhead wind-up, chop, lunge + step, follow-through, settle.
static var G_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.07, -150.0, 1, 0.11, -18.0, 2, 0.17, 6.0, 1, 0.32, -4.0, 0, 0.62, 0.0, 0])
static var G_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.07, -30.0, 1, 0.12, -14.0, 0, 0.62, 0.0, 0])
static var G_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 22.0, 1, 0.11, -26.0, 2, 0.30, -12.0, 0, 0.62, 0.0, 0])
static var G_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.12, 16.0, 2, 0.32, 6.0, 0, 0.62, 0.0, 0])
static var G_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.12, 0.30, 2, 0.30, 0.24, 0, 0.62, 0.0, 0])
static var G_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 0.04, 1, 0.12, -0.07, 2, 0.30, -0.03, 0, 0.62, 0.0, 0])
static var G_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -8.0, 1, 0.12, 8.0, 0, 0.62, 0.0, 0])
static var STEP_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -28.0, 1, 0.35, -20.0, 0, 0.62, 0.0, 0])
static var STEP_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, 18.0, 1, 0.35, 12.0, 0, 0.62, 0.0, 0])
# -- Cinder Hand, worker_pick (pick rests UP from the fist: + brings the head over the shoulder to the front).
static var W_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.07, -50.0, 1, 0.11, 125.0, 2, 0.17, 140.0, 1, 0.32, 100.0, 0, 0.62, 0.0, 0])
static var W_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.07, -30.0, 1, 0.12, -70.0, 2, 0.32, -40.0, 0, 0.62, 0.0, 0])
static var W_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -14.0, 1, 0.12, 22.0, 2, 0.30, 14.0, 0, 0.62, 0.0, 0])
static var W_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.04, 1, 0.12, 0.18, 2, 0.30, 0.12, 0, 0.62, 0.0, 0])
static var W_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 0.06, 1, 0.12, -0.06, 2, 0.30, -0.02, 0, 0.62, 0.0, 0])
# -- Blaze Rider, lance_charge (strike 0.12 s): rear back, couch, lunge + thrust, boar gores and tosses its head.
static var R_ROOT_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -8.0, 1, 0.13, 7.0, 2, 0.30, 2.0, 0, 0.70, 0.0, 0])
static var R_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.10, 1, 0.13, 0.40, 2, 0.35, 0.22, 0, 0.70, 0.0, 0])
static var R_ARM_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, 14.0, 1, 0.13, 20.0, 2, 0.28, -12.0, 1, 0.70, 0.0, 0])
static var R_ARM_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.12, 1, 0.13, 0.45, 2, 0.30, 0.18, 0, 0.70, 0.0, 0])
static var R_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.13, 16.0, 2, 0.35, 6.0, 0, 0.70, 0.0, 0])
static var R_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 10.0, 1, 0.13, -14.0, 2, 0.40, -4.0, 0, 0.70, 0.0, 0])
static var R_MHEAD := PackedFloat32Array([0.0, 0.0, 0, 0.07, -12.0, 1, 0.13, 24.0, 2, 0.26, -26.0, 1, 0.45, -8.0, 0, 0.70, 0.0, 0])
static var R_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.07, -28.0, 1, 0.13, 12.0, 2, 0.35, 0.0, 0])
static var R_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.07, 10.0, 1, 0.13, -14.0, 2, 0.35, 0.0, 0])
# -- Ember Archer, bow_draw (release 0.15 s): turn side-on, bow up, draw to the chin, loose, hand flies back.
static var A_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.10, 48.0, 1, 0.34, 48.0, 0, 0.62, 0.0, 0])
static var A_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.10, -42.0, 1, 0.34, -42.0, 0, 0.62, 0.0, 0])
static var A_ARM_L_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -86.0, 1, 0.36, -86.0, 0, 0.62, 0.0, 0])
static var A_ARM_L_Y := PackedFloat32Array([0.0, 0.0, 0, 0.10, -48.0, 1, 0.36, -48.0, 0, 0.62, 0.0, 0])
static var A_ARM_R_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -84.0, 1, 0.15, -84.0, 0, 0.22, -70.0, 1, 0.62, 0.0, 0])
static var A_ARM_R_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, -74.0, 1, 0.15, -64.0, 2, 0.22, -20.0, 1, 0.62, 0.0, 0])
static var A_ARM_R_PZ := PackedFloat32Array([0.0, 0.0, 0, 0.08, 0.0, 0, 0.145, -0.12, 2, 0.20, -0.22, 1, 0.62, 0.0, 0])
static var A_ROOT_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -4.0, 1, 0.15, -4.0, 0, 0.20, -7.0, 1, 0.62, 0.0, 0])
static var A_STANCE := PackedFloat32Array([0.0, 0.0, 0, 0.10, 12.0, 1, 0.40, 12.0, 0, 0.62, 0.0, 0])
# -- Ash Hurler, sling_throw (release 0.15 s): cock back low, heave, whip over the head, big follow-through.
static var H_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.09, -115.0, 1, 0.15, -15.0, 2, 0.24, 70.0, 1, 0.42, 55.0, 0, 0.90, 0.0, 0])
static var H_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.09, -65.0, 1, 0.20, 30.0, 1, 0.90, 0.0, 0])
static var H_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.09, 28.0, 1, 0.20, -26.0, 2, 0.45, -12.0, 0, 0.90, 0.0, 0])
static var H_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.09, -14.0, 1, 0.20, 22.0, 2, 0.45, 14.0, 0, 0.90, 0.0, 0])
static var H_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.09, -0.07, 1, 0.20, 0.18, 2, 0.45, 0.12, 0, 0.90, 0.0, 0])
static var H_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.09, -0.05, 1, 0.20, -0.03, 0, 0.90, 0.0, 0])
static var H_STEP_L := PackedFloat32Array([0.0, 0.0, 0, 0.20, -26.0, 1, 0.50, -18.0, 0, 0.90, 0.0, 0])
static var H_STEP_R := PackedFloat32Array([0.0, 0.0, 0, 0.20, 18.0, 1, 0.50, 12.0, 0, 0.90, 0.0, 0])
# -- Deaths (added to the kit's `fall`): stagger back, head snaps, arms fling, then the fall and the burn.
static var D_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.16, 1, 0.30, -0.10, 0, 0.60, 0.0, 0])
static var D_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -28.0, 1, 0.35, 10.0, 0, 1.0, 10.0, 0])
static var D_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -70.0, 1, 0.45, -20.0, 0, 0.70, 25.0, 0])
static var D_BUMP := PackedFloat32Array([0.0, 0.0, 0, 0.55, 0.0, 0, 0.61, 0.06, 1, 0.70, 0.0, 2])
static var D_HOP := PackedFloat32Array([0.0, 0.0, 0, 0.14, 0.22, 1, 0.28, 0.0, 2])
static var D_RIDER_X := PackedFloat32Array([0.0, 0.0, 0, 0.20, -18.0, 1, 0.45, 0.0, 2])
static var D_RIDER_CHEST := PackedFloat32Array([0.0, 0.0, 0, 0.20, -35.0, 1, 0.55, -10.0, 0])

var _string: Node3D
var _drawn: Node3D
var _arrow: Node3D
var _ball: GeometryInstance3D
var _sparks: GPUParticles3D
var _burn_fx: Array[GPUParticles3D] = []
var _ball_t: float = -1.0
var _ball_heat: float = -1.0
var _burn_v: float = 0.0
var _burn_fired: bool = false


func _after_ready() -> void:
	var arm_l := get_node_or_null(^"Root/Chest/ArmL")
	var arm_r := get_node_or_null(^"Root/Chest/ArmR")
	if arm_l:
		_string = arm_l.get_node_or_null(^"String") as Node3D
		_drawn = arm_l.get_node_or_null(^"DrawnString") as Node3D
		_arrow = arm_l.get_node_or_null(^"DrawnArrow") as Node3D
	if arm_r:
		_ball = arm_r.get_node_or_null(^"AshBall") as GeometryInstance3D
		_sparks = arm_r.get_node_or_null(^"MineSparks") as GPUParticles3D
	var fx := get_node_or_null(^"Fx")
	if fx:
		for c: Node in fx.get_children():
			if c is GPUParticles3D and c.has_meta(&"burn_fx"):
				_burn_fx.append(c as GPUParticles3D)
	if _ball:
		# The ball keeps its own ember glow: the kit's flashes never reset it.
		_flash_all_targets.erase(_ball)
		_ball.set_instance_shader_parameter(&"flash_color", EMBER)
		_set_ball_heat(BALL_IDLE)


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"attack_start":
			_set_drawn(true)
		&"release", &"attack_end":
			_set_drawn(false)
			if ev == &"release" and _ball:
				_ball.visible = false
				_ball_t = attack_windup
		&"mine_hit":
			if _sparks:
				_sparks.restart()


func _extra_process(dt: float) -> void:
	if _ball == null:
		return
	if _ball_t >= 0.0:
		_ball_t += dt
		if _ball_t >= BALL_BACK and not _ball.visible and not _dead:
			_ball.visible = true
		if _ball_t >= BALL_BACK:
			# Reloaded hot, cools back to a smoulder over 0.5 s.
			var k: float = clampf((_ball_t - BALL_BACK) / 0.5, 0.0, 1.0)
			_set_ball_heat(lerpf(1.2, BALL_IDLE, k))
			if k >= 1.0:
				_ball_t = -1.0
	elif _action == &"attack" and _ball.visible:
		_set_ball_heat(lerpf(BALL_IDLE, 1.4, clampf(_action_t / maxf(attack_windup, 0.01), 0.0, 1.0)))


func _on_revive() -> void:
	_set_drawn(false)
	_ball_t = -1.0
	_burn_fired = false
	_write_burn(0.0)
	if _ball:
		_ball.visible = true
		_set_ball_heat(BALL_IDLE)


# ================================================================ walk flavour (on top of the kit's cycle)

func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	if _tier > 0:
		return   # flavour only when close (< 30 m); farther away the kit's cycle alone (fewer pivot writes)
	var ph: float = TAU * _walk_p
	var s: float = sin(ph)
	var c: float = cos(ph)
	var b: float = absf(s)
	match fire_kind:
		&"worker":
			rot(P_ROOT, Vector3(4.0 * DEG * w, 0, 5.0 * DEG * s * w))
			rot(P_HIPS, Vector3(0, 6.0 * DEG * s * w, 0))
			rot(P_CHEST, Vector3(0, -5.0 * DEG * s * w, 0))
			rot(P_ARM_L, Vector3(-10.0 * DEG * s * w, 0, 0))
		&"guard":
			rot(P_ROOT, Vector3(5.0 * DEG * w, 0, 2.5 * DEG * s * w))
			rot(P_HIPS, Vector3(0, 5.0 * DEG * s * w, 0))
			rot(P_CHEST, Vector3(0, -4.0 * DEG * s * w, 0))
			rot(P_ARM_L, Vector3((18.0 * s - 14.0) * DEG * w, 0, 0))
			rot(P_ARM_R, Vector3(10.0 * DEG * s * w, 0, 0))
		&"archer":
			rot(P_ROOT, Vector3(7.0 * DEG * w, 0, 0))
			rot(P_HIPS, Vector3(0, 8.0 * DEG * s * w, 0))
			rot(P_CHEST, Vector3(0, -6.0 * DEG * s * w, 0))
			rot(P_ARM_L, Vector3(8.0 * DEG * s * w, 0, 0))
			rot(P_ARM_R, Vector3(10.0 * DEG * s * w, 0, 0))
		&"hurler":
			rot(P_ROOT, Vector3(6.0 * DEG * w, 0, 3.0 * DEG * s * w))
			rot(P_HIPS, Vector3(0, 5.0 * DEG * s * w, 0))
			rot(P_ARM_R, Vector3(-8.0 * DEG * s * w, 0, 4.0 * DEG * c * w))
		&"rider":
			pos(P_CHEST, Vector3(0, -0.05 * b * w, 0))
			rot(P_CHEST, Vector3(-4.0 * DEG * c * w, 0, 0))
			rot(P_ARM_R, Vector3(5.0 * DEG * sin(ph + 1.2) * w, 0, 0))
			rot(P_MOUNT_HEAD, Vector3(9.0 * DEG * sin(ph + 0.6) * w, 0, 0))
			rot(P_ROOT, Vector3(3.0 * DEG * c * w, 0, 0))


func _pose_mine(t: float) -> void:
	super(t)
	rot(P_CHEST, Vector3(DEG * _k3(t, 0.0, 0.35, 0.5, 1.0, -10.0, 20.0), 0, 0))
	rot(P_ARM_L, Vector3(DEG * _k3(t, 0.0, 0.35, 0.5, 1.0, -25.0, -60.0), 0, 0))
	rot(P_LEG_L, Vector3(DEG * _k3(t, 0.0, 0.35, 0.5, 1.0, 0.0, -14.0), 0, 0))


# ================================================================ attacks

func _pose_attack(prev: float, t: float) -> bool:
	var length: float = 0.0
	var near: bool = _tier == 0   # secondary motion (steps, head) only when close
	match fire_kind:
		&"guard":
			length = 0.62
			rot(P_ARM_R, Vector3(_kf(t, G_ARM_R) * DEG, 0, 0))
			rot(P_ARM_L, Vector3(_kf(t, G_ARM_L) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_kf(t, G_CHEST_X) * DEG, _kf(t, G_CHEST_Y) * DEG, 0))
			pos(P_ROOT, Vector3(0, _kf(t, G_ROOT_Y), _kf(t, G_ROOT_Z)))
			if near:
				rot(P_HEAD, Vector3(_kf(t, G_HEAD_X) * DEG, 0, 0))
				rot(P_LEG_L, Vector3(_kf(t, STEP_L) * DEG, 0, 0))
				rot(P_LEG_R, Vector3(_kf(t, STEP_R) * DEG, 0, 0))
		&"worker":
			length = 0.62
			rot(P_ARM_R, Vector3(_kf(t, W_ARM_R) * DEG, 0, 0))
			rot(P_ARM_L, Vector3(_kf(t, W_ARM_L) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_kf(t, W_CHEST_X) * DEG, _kf(t, G_CHEST_Y) * 0.5 * DEG, 0))
			pos(P_ROOT, Vector3(0, _kf(t, W_ROOT_Y), _kf(t, W_ROOT_Z)))
			if near:
				rot(P_LEG_L, Vector3(_kf(t, STEP_L) * 0.8 * DEG, 0, 0))
				rot(P_LEG_R, Vector3(_kf(t, STEP_R) * 0.8 * DEG, 0, 0))
		&"rider":
			length = 0.70
			rot(P_ROOT, Vector3(_kf(t, R_ROOT_X) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0, _kf(t, R_ROOT_Z)))
			rot(P_ARM_R, Vector3(_kf(t, R_ARM_X) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0, _kf(t, R_ARM_Z)))
			rot(P_CHEST, Vector3(_kf(t, R_CHEST_X) * DEG, _kf(t, R_CHEST_Y) * DEG, 0))
			rot(P_MOUNT_HEAD, Vector3(_kf(t, R_MHEAD) * DEG, 0, 0))
			if near:
				var lf: float = _kf(t, R_LEG_F) * DEG
				var lb: float = _kf(t, R_LEG_B) * DEG
				rot(P_LEG_FL, Vector3(lf, 0, 0))
				rot(P_LEG_FR, Vector3(lf, 0, 0))
				rot(P_LEG_BL, Vector3(lb, 0, 0))
				rot(P_LEG_BR, Vector3(lb, 0, 0))
		&"archer":
			length = 0.62
			rot(P_CHEST, Vector3(0, _kf(t, A_CHEST_Y) * DEG, 0))
			rot(P_HEAD, Vector3(0, _kf(t, A_HEAD_Y) * DEG, 0))
			rot(P_ARM_L, Vector3(_kf(t, A_ARM_L_X) * DEG, _kf(t, A_ARM_L_Y) * DEG, 0))
			rot(P_ARM_R, Vector3(_kf(t, A_ARM_R_X) * DEG, _kf(t, A_ARM_R_Y) * DEG, 0))
			pos(P_ARM_R, Vector3(0, 0, _kf(t, A_ARM_R_PZ)))
			rot(P_ROOT, Vector3(_kf(t, A_ROOT_X) * DEG, 0, 0))
			if near:
				var st: float = _kf(t, A_STANCE) * DEG
				rot(P_LEG_L, Vector3(-st, 0, 0))
				rot(P_LEG_R, Vector3(st, 0, 0))
		&"hurler":
			length = 0.90
			rot(P_ARM_R, Vector3(_kf(t, H_ARM_R) * DEG, 0, 0))
			rot(P_ARM_L, Vector3(_kf(t, H_ARM_L) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_kf(t, H_CHEST_X) * DEG, _kf(t, H_CHEST_Y) * DEG, 0))
			pos(P_ROOT, Vector3(0, _kf(t, H_ROOT_Y), _kf(t, H_ROOT_Z)))
			if near:
				rot(P_LEG_L, Vector3(_kf(t, H_STEP_L) * DEG, 0, 0))
				rot(P_LEG_R, Vector3(_kf(t, H_STEP_R) * DEG, 0, 0))
		_:
			return super(prev, t)
	var release: float = attack_windup if attack_windup > 0.0 else 0.11
	if prev < release and t >= release:
		_on_action_event(&"release")
	return t < length


# ================================================================ death: stagger, fall (kit), burn away

func _pose_death(dt: float) -> void:
	super(dt)
	var t: float = _death_t
	match fire_kind:
		&"rider":
			rot(P_ROOT, Vector3(_kf(t, D_RIDER_X) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_kf(t, D_RIDER_CHEST) * DEG, 0, 0))
			rot(P_MOUNT_HEAD, Vector3(_kf(t, D_RIDER_X) * 1.4 * DEG, 0, 0))
			rot(P_ARM_L, Vector3(_kf(t, D_ARM_L) * DEG, 0, 0))
		_:
			pos(P_ROOT, Vector3(0, _kf(t, D_BUMP), _kf(t, D_ROOT_Z)))
			rot(P_HEAD, Vector3(_kf(t, D_HEAD_X) * DEG, 0, 0))
			rot(P_ARM_L, Vector3(_kf(t, D_ARM_L) * DEG, 0, 0))
			match fire_kind:
				&"worker":
					pos(P_ROOT, Vector3(0, _kf(t, D_HOP), 0))
					rot(P_ARM_R, Vector3(_kf(t, D_ARM_L) * 1.4 * DEG, 0, 0))
				&"archer":
					var tw: float = smoothstep(0.0, 0.3, t)
					rot(P_CHEST, Vector3(0, 40.0 * DEG * tw, 0))
					rot(P_ROOT, Vector3(0, 0, 12.0 * DEG * tw))
				&"guard":
					rot(P_ARM_L, Vector3(0, 0, -35.0 * DEG * smoothstep(0.2, 0.5, t)))
				&"hurler":
					rot(P_CHEST, Vector3(0, -30.0 * DEG * smoothstep(0.0, 0.35, t), 0))
	# The body glows like a coal and crumbles into embers.
	if t >= BURN_T0 and not _burn_fired:
		_burn_fired = true
		for p: GPUParticles3D in _burn_fx:
			p.restart()
	_write_burn(smoothstep(BURN_T0, BURN_T0 + 0.33, t) * 0.32)
	# Burn away on the ground instead of sinking through it: cancel most of the kit's sink, shrink to a cinder.
	var g: float = _ease_in(clampf((t - 0.55) / 0.45, 0.0, 1.0))
	pos(P_ROOT, Vector3(0, (0.6 * body_height - 0.25) * g * 0.8, 0))
	_root_scale *= lerpf(1.0, 0.1, smoothstep(0.55, 0.98, t))


## Ember emission on every painted part (instance uniforms; quantised so a death writes ~20 times).
func _write_burn(v: float) -> void:
	v = snappedf(v, 0.05)
	if v == _burn_v:
		return
	_burn_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", EMBER if v > 0.0 else WHITE)


func _set_ball_heat(v: float) -> void:
	v = snappedf(v, 0.04)
	if v == _ball_heat or _ball == null:
		return
	_ball_heat = v
	_ball.set_instance_shader_parameter(&"hit_flash", v)


func _set_drawn(on: bool) -> void:
	if _string == null or _drawn == null:
		return
	_string.visible = not on
	_drawn.visible = on
	if _arrow:
		_arrow.visible = on


## Keyframe track [t, v, ease, t, v, ease, ...] starting at t = 0 (see the constants above). Called ~8 times per
## attacking unit per animated frame, so it is kept to a few float ops on a PackedFloat32Array.
static func _kf(t: float, k: PackedFloat32Array) -> float:
	var n: int = k.size()
	if t >= k[n - 3]:
		return k[n - 2]
	if t <= 0.0:
		return k[1]
	var i: int = 3
	while t >= k[i]:
		i += 3
	var t0: float = k[i - 3]
	var u: float = (t - t0) / (k[i] - t0)
	var e: float = k[i + 2]
	if e == 1.0:
		u = u * (2.0 - u)
	elif e == 2.0:
		u = u * u
	else:
		u = u * u * (3.0 - 2.0 * u)
	return k[i - 2] + (k[i + 1] - k[i - 2]) * u