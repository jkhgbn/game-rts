extends CharacterModel
## Mirefang (map-fill.md 5.1 / 10, task 12.V21): the tier-2 camp creature of the two Ford Nests (3 per nest, standing
## IN Reed Ford / Willow Ford; amphibious). A low, long river lizard: ~2.35 m snout to tail tip, the back only
## ~0.44 m high, legs sprawled out to the sides (selection radius 0.45). Read at 40 m by three things:
##  - the long low LIZARD silhouette: a flat wedge head, a thick body on splayed legs, a long tail tapering to the
##    ground (dark cross-bands down the back and tail, a double row of bronze studs, a bronze crest on the tail),
##  - the FRILLED JAW: a bronze-orange ruff with dark spines around the neck, folded back like a collar at rest,
##    snapping open into a wide fan when it bites, hisses or is hit,
##  - two AMBER EYES on top of the skull (the glow points; emission only, 0 lights).
## Wet green-bronze scales (painted shader with a wet specular), a pale cream belly and throat, a warm mouth.
## Neutral: no team colour (set_team_color is a no-op), 0 lights.
## Motion (all procedural, kit rules):
##  - idle: slow breathing, a slow look around, the tail tip sways; every ~bob_every s at close range the HEAD-BOB
##    display (two push-ups on the fore legs with the frill half open); `play_bob()` starts one now;
##  - walk: a sprawling lizard trot (diagonal pairs, the splayed legs swing round the shoulders and lift out), the
##    spine undulates (the body yaws, the head stays on target, the tail swings the other way), the frill folds flat;
##  - attack `snap_bite` (0.55 s, strike 0.12 s = the kit strike frame, damage stays instant): coils back with the
##    head up, jaw gaping and the frill flared (0.07), lunges +0.3 m and SNAPS the jaw shut on the target (0.12),
##    a tearing head-shake, a tail lash, then recovers;
##  - hit: the kit flinch + a head jerk, a short hiss (jaw), the frill spikes open, the tail lashes;
##  - death (1.0 s): a hiss with the frill wide, it rolls over onto its back (pale belly up, legs curled), the
##    legs twitch, the eyes go dark, then it sinks into the mud (the unit is freed at death_finished);
##  - cast (the spec lists no Mirefang ability; any id is safe): the full threat display, rearing on the fore legs,
##    jaw wide, frill fully fanned and trembling, tail curled up.
## Budget (map-fill.md 10, soldier: <= 18 authored meshes, <= 10 draw instances, 0 lights; art-units 8: <= 2 500
## vertices, keep_separate <= 6): 10 authored meshes = 10 draw instances (6 merged pivots: body, head, 4 legs;
## keep_separate Jaw, Frill, Tail; the blob), no emitters; 4 painted materials + 1 glow (materials/); see
## tests/test_12_v21.gd.

const MF_DIR := "res://art/units/neutral/mirefang/materials/"
const JAW_ORIGIN := Vector3(0.0, 0.285, 0.46)      # model space: the jaw hinge
const FRILL_ORIGIN := Vector3(0.0, 0.30, 0.44)     # model space: the centre of the frill ring (the neck axis)
const TAIL_ORIGIN := Vector3(0.0, 0.245, -0.52)    # model space: the tail root (yaws / lifts about it)
const BITE_LEN := 0.55
const BITE_HIT := 0.12
const BOB_LEN := 1.6
const CAST_LEN := 0.9
const DEATH_ROLL := 2.8                            # rad: rolls belly up (160 deg)
const DEATH_LAND := 0.56
const FRONT_Z := 0.36                              # fore / hind feet z: the root pitches about them
const HIND_Z := -0.46
const LIFT_DEG := 22.0                             # leg lift (rotation out / up about the shoulder) at lift 1
const FRILL_REST := 0.12

# Keyframe tracks [t, value, ease, t, value, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth,
# 1 ease-out, 2 ease-in). Angles in deg. Head x: + = nose down. Jaw: + = open. Legs: + = foot forward. Pitch:
# + = nose down.
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.12, 0.30, 2, 0.26, 0.24, 1, 0.55, 0.0, 0])
static var A_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 0.02, 1, 0.12, -0.01, 2, 0.30, 0.0, 0])
static var A_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, -7.0, 1, 0.12, 4.0, 2, 0.30, 1.0, 1, 0.55, 0.0, 0])
static var A_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.06, -30.0, 1, 0.095, -27.0, 0, 0.12, 16.0, 2, 0.26, 8.0, 1,
	0.50, 0.0, 0])
static var A_JAW := PackedFloat32Array([0.0, 0.0, 0, 0.06, 46.0, 1, 0.10, 42.0, 0, 0.12, 0.0, 2, 0.34, 0.0, 0,
	0.42, 10.0, 1, 0.55, 0.0, 0])
static var A_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.07, -8.0, 1, 0.12, 28.0, 1, 0.30, 10.0, 0, 0.55, 0.0, 0])
static var A_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.07, 6.0, 1, 0.12, -24.0, 1, 0.30, -8.0, 0, 0.55, 0.0, 0])
static var A_TAIL := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.16, 26.0, 1, 0.55, 0.0, 0])
static var C_RISE := PackedFloat32Array([0.0, 0.0, 0, 0.18, 1.0, 1, 0.62, 1.0, 0, 0.9, 0.0, 0])
static var D_HISS := PackedFloat32Array([0.0, 0.0, 0, 0.10, 1.0, 1, 0.20, 1.0, 0, 0.40, 0.0, 0])

## Idle head-bob display interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var bob_every: float = 8.0

static var _mf_mats: Dictionary = {}
static var _mf_meshes: Dictionary = {}

var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _jaw_node: MeshInstance3D
var _frill_node: MeshInstance3D
var _tail_node: MeshInstance3D
var _jaw_local: Vector3 = Vector3.ZERO
var _frill_local: Vector3 = Vector3.ZERO
var _tail_local: Vector3 = Vector3.ZERO
var _jaw: float = 0.0                 # deg, current
var _frill: float = FRILL_REST        # -0.25 folded flat .. 1 fully fanned
var _jaw_req: float = -1.0            # this frame's requests from the poses (< 0 / < -1 = none)
var _frill_req: float = -9.0
var _tail_add: Vector2 = Vector2.ZERO # deg (yaw, lift) added this frame
var _jaw_w: float = 99.0
var _frill_w: Vector2 = Vector2(99.0, 99.0)
var _tail_w: Vector2 = Vector2(99.0, 99.0)
var _bob_wait: float = 0.0
## G-D signature emitter (High / Ultra only; null otherwise).
var _sig: GPUParticles3D
var _strikes: int = 0


static func _m(name: StringName) -> Material:
	if not _mf_mats.has(name):
		_mf_mats[name] = load(MF_DIR + String(name) + ".tres")
	return _mf_mats[name]


# ================================================================ public (tests, preview, camp idle)

## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Snap-bite strikes played so far (the `release` frame of each attack), for tests.
func strike_count() -> int:
	return _strikes


## The frill's current flare (-0.25 folded flat .. 1 fully fanned).
func frill_flare() -> float:
	return _frill


## The jaw's current opening (deg).
func jaw_open() -> float:
	return _jaw


## Starts the idle head-bob display now (it also plays by itself every ~bob_every s when standing close to the camera).
func play_bob() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"bob"
		_action_t = 0.0


## Neutral creature: no team colour.
func set_team_color(_c: Color) -> void:
	pass


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh, at: Vector3, keep: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, part_name)


func _build_parts() -> void:
	_authored = 0
	var mount: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	_part(mount, _body_mesh(), Vector3.ZERO)
	_part(head, _head_mesh(), Vector3.ZERO)
	_face = CreatureFaceRig.attach(self, head, "mirefang", face_spec())
	for leg: Node3D in [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]:
		var p := model_origin(leg)
		_part(leg, _leg_mesh(p.z > 0.0, signf(p.x)), Vector3.ZERO)
	_jaw_node = _part(head, _jaw_mesh(), JAW_ORIGIN, true, "Jaw")
	_frill_node = _part(head, _frill_mesh(), FRILL_ORIGIN, true, "Frill")
	_frill_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_tail_node = _part(mount, _tail_mesh(), TAIL_ORIGIN, true, "Tail")
	_tail_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_jaw_local = _jaw_node.position
	_frill_local = _frill_node.position
	_tail_local = _tail_node.position
	ensure_shadow_blob(0.45, Color(0.03, 0.05, 0.04, 0.5))
	_shadow.scale = Vector3(0.95, 1.0, 2.3)
	_shadow.position = Vector3(0.0, 0.02, -0.12)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	# The kit flashes the merged Chest / Head / ArmR on hits; a quadruped has none: add the body, head, jaw, frill, tail.
	for i: int in [P_MOUNT, P_MOUNT_HEAD]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
		if m and i == P_MOUNT_HEAD:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for n: MeshInstance3D in [_jaw_node, _frill_node, _tail_node]:
		if n and not _flash_hit_targets.has(n):
			_flash_hit_targets.append(n)
	_bob_wait = _next_bob() * 0.6
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))
	_write_parts(true)
	# G-D signature (High+): marsh vapour clinging round the body.
	var mount: Node3D = $Root/Mount
	_sig = CreatureSignature.attach(self, mount, Vector3(0.0, 0.18, -0.1) - model_origin(mount), &"mist", 1.1)


## G-D signature gate (CreatureSignature, High / Ultra only): near tier, animating, alive.
func signature_should_emit() -> bool:
	return _tier == 0 and not _offscreen and not _frozen and not _dead


# ================================================================ hooks

func _on_action_event(ev: StringName) -> void:
	if ev == &"release" and _action == &"attack":
		_strikes += 1


func _on_revive() -> void:
	if _face:
		_face.reset()
	_jaw = 0.0
	_frill = FRILL_REST
	_jaw_req = -1.0
	_frill_req = -9.0
	_tail_add = Vector2.ZERO
	_write_parts(true)


# ================================================================ idle / walk

func _idle_head(ph: float) -> Vector3:
	# A slow look around, the snout lifting a little now and then (tasting the air).
	var x: float = 2.0 - 4.0 * smoothstep(0.4, 0.9, sin(ph * 0.63 + _phase_off * 2.0))
	var y: float = 11.0 * sin(ph * 0.31 + 0.6 + _phase_off)
	return Vector3(x, y, 0.0) * DEG


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.006 * sin(ph), 0))
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + _idle_head(ph))


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	pos(P_ROOT, Vector3(0, 0.006 * sin(ph) * w, 0))
	rot(P_MOUNT_HEAD, _idle_head(ph) * w)


## Sprawling lizard trot: diagonal pairs (FL + BR, FR + BL); the splayed legs swing round the shoulder / hip (yaw)
## and lift out on the forward swing; the body yaws with the stride, the head stays on target, the tail counters.
func _pose_walk(w: float, _rate: float) -> void:
	var ph: float = TAU * _walk_p
	var s: float = sin(ph)
	var c: float = cos(ph)
	var a: float = 32.0 * w
	_leg(P_LEG_FL, -1.0, a * s, maxf(0.0, c) * w)
	_leg(P_LEG_BR, 1.0, a * 0.9 * s, maxf(0.0, c) * w)
	_leg(P_LEG_FR, 1.0, -a * s, maxf(0.0, -c) * w)
	_leg(P_LEG_BL, -1.0, -a * 0.9 * s, maxf(0.0, -c) * w)
	var und: float = 9.0 * DEG * s * w
	rot(P_MOUNT, Vector3(0, und, 0))
	if _action != &"attack":
		rot(P_MOUNT_HEAD, Vector3(3.0 * DEG * sin(2.0 * ph) * w, -und * 1.1, 0))
	pos(P_ROOT, Vector3(0, walk_bounce * (0.5 + 0.5 * cos(2.0 * ph)) * w, 0))
	rot(P_ROOT, Vector3(0, 0, 2.0 * DEG * s * w))


## One splayed leg: `swing` deg (+ = foot forward, a yaw round the shoulder), `lift` (1 = raised up / out, negative =
## pressed down: push-ups, rearing).
func _leg(i: int, sx: float, swing: float, lift: float) -> void:
	rot(i, Vector3(0.0, -sx * swing * DEG, sx * lift * LIFT_DEG * DEG))
	pos(i, Vector3(0, 0.02 * maxf(lift, 0.0), 0))


# ================================================================ attack / cast / bob

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"snap_bite":
		return super._pose_attack(prev, t)
	pos(P_ROOT, Vector3(0, _trk(t, A_ROOT_Y), _trk(t, A_ROOT_Z)))
	_pitch_root(_trk(t, A_PITCH))
	var shake: float = 0.0
	if t > 0.13 and t < 0.42:
		shake = 15.0 * sin((t - 0.13) * 40.0) * (1.0 - (t - 0.13) / 0.29)
	rot(P_MOUNT_HEAD, Vector3(_trk(t, A_HEAD_X), shake, shake * -0.3) * DEG)
	var f: float = _trk(t, A_LEG_F)
	var b: float = _trk(t, A_LEG_B)
	_leg(P_LEG_FL, -1.0, f, 0.0)
	_leg(P_LEG_FR, 1.0, f * 0.85, 0.0)
	_leg(P_LEG_BL, -1.0, b, 0.0)
	_leg(P_LEG_BR, 1.0, b * 0.9, 0.0)
	_jaw_req = _trk(t, A_JAW)
	_frill_req = 1.0 if t < 0.34 else 0.25
	_tail_add.x += _trk(t, A_TAIL)
	if prev < BITE_HIT and t >= BITE_HIT:
		_on_action_event(&"release")
	return t < BITE_LEN


## Any cast id: the full threat display (rears on the fore legs, head up and shaking, jaw wide, frill fanned and
## trembling, tail curled up).
func _pose_cast(_spell: StringName, t: float) -> float:
	var k: float = _trk(t, C_RISE)
	_pitch_root(-13.0 * k)
	_leg(P_LEG_FL, -1.0, 10.0 * k, -1.1 * k)
	_leg(P_LEG_FR, 1.0, 10.0 * k, -1.1 * k)
	var shake: float = 4.0 * sin(t * 46.0) * k
	rot(P_MOUNT_HEAD, Vector3(-22.0 * k, shake, 0) * DEG)
	_jaw_req = 50.0 * k
	_frill_req = 1.0 if t < 0.7 else FRILL_REST
	_tail_add += Vector2(24.0, 14.0) * k
	return CAST_LEN


## Pitches the body about the feet that stay planted (+ nose down about the fore feet, - rears about the hind).
func _pitch_root(deg: float) -> void:
	var th: float = deg * DEG
	rot(P_ROOT, Vector3(th, 0, 0))
	var zp: float = FRONT_Z if th > 0.0 else HIND_Z
	pos(P_ROOT, Vector3(0, zp * sin(th), 0))


## The head-bob display (1.6 s): two push-ups on the fore legs with a nod at the top, the frill half open.
func _pose_bob(t: float) -> void:
	var k: float = 0.0
	for c: float in [0.4, 1.0]:
		k = maxf(k, sin(PI * clampf((t - c + 0.25) / 0.5, 0.0, 1.0)))
	_pitch_root(-6.0 * k)
	_leg(P_LEG_FL, -1.0, 0.0, -0.8 * k)
	_leg(P_LEG_FR, 1.0, 0.0, -0.8 * k)
	var nod: float = 0.0
	for c: float in [0.62, 1.22]:
		nod = maxf(nod, sin(PI * clampf((t - c) / 0.18, 0.0, 1.0)))
	rot(P_MOUNT_HEAD, Vector3((-6.0 * k + 14.0 * nod) * DEG, 0, 0))
	if t < 1.35:
		_frill_req = 0.55


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	var hiss: float = _trk(t, D_HISS)
	var u: float = smoothstep(0.18, DEATH_LAND, t)
	var th: float = DEATH_ROLL * u
	var hc: float = 0.28
	var hy: float = lerpf(0.28, 0.24, u) + 0.07 * sin(PI * u)
	var sink: float = _ease_in(clampf((t - 0.68) / 0.32, 0.0, 1.0))
	rot(P_ROOT, Vector3(0, 0, th))
	pos(P_ROOT, Vector3(-0.2 * u + hc * sin(th), hy - hc * cos(th) - 0.5 * sink, 0))
	rot(P_MOUNT_HEAD, Vector3((-28.0 * hiss + 12.0 * u) * DEG, 16.0 * DEG * u, 0))
	# The legs curl in over the belly as it rolls, then twitch.
	var kick: float = 0.0
	if t > DEATH_LAND:
		kick = sin((t - DEATH_LAND) * 28.0) * exp(-(t - DEATH_LAND) * 5.0)
	_leg(P_LEG_FL, -1.0, 20.0 * u + 12.0 * kick, -1.6 * u)
	_leg(P_LEG_FR, 1.0, 14.0 * u - 10.0 * kick, -1.5 * u)
	_leg(P_LEG_BL, -1.0, -16.0 * u - 14.0 * kick, -1.5 * u)
	_leg(P_LEG_BR, 1.0, -20.0 * u + 12.0 * kick, -1.6 * u)
	_jaw_req = maxf(46.0 * hiss, 18.0 * u)
	_frill_req = 1.0 if hiss > 0.3 else -0.25
	_tail_add += Vector2(28.0 * u, -6.0 * u)
	if prev < 0.5 and t >= 0.5:
		_glows_dead()
	if _shadow:
		_shadow.transparency = clampf((t - 0.6) / 0.4, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


# ================================================================ per frame extras

func _extra_process(dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		if _action == &"bob":
			if _speed >= 0.3 or _action_t >= BOB_LEN:
				_action = &""
			else:
				_pose_bob(_action_t)
		elif bob_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0:
			_bob_wait -= dt
			if _bob_wait <= 0.0:
				_bob_wait = _next_bob()
				_action = &"bob"
				_action_t = 0.0
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_MOUNT_HEAD, Vector3(-14.0 * k, 10.0 * k, 0) * DEG)
			_jaw_req = maxf(_jaw_req, 24.0 * k)
			_frill_req = maxf(_frill_req, 0.9)
			_tail_add.x += 20.0 * k
	# Frill: requested by the poses, else folded while walking / dead, a collar at rest; fast to open, slow to fold.
	var goal: float = FRILL_REST
	if _dead:
		goal = -0.25
	elif _walk_w > 0.5:
		goal = 0.0
	if _frill_req > -1.0:
		goal = _frill_req
	_frill = move_toward(_frill, goal, dt * (11.0 if goal > _frill else 3.0))
	# Jaw: keyframed by the poses, else closes.
	if _jaw_req >= 0.0:
		_jaw = _jaw_req
	else:
		_jaw = move_toward(_jaw, 0.0, dt * 160.0)
	# Tail: idle sway of the tip, the walk counter-swing, plus the poses' lashes.
	var yaw: float = 7.0 * sin(_t * 0.9 + _phase_off * 3.0) * (1.0 - _walk_w) \
		- 16.0 * sin(TAU * _walk_p - 0.9) * _walk_w + _tail_add.x
	var lift: float = 2.0 * sin(_t * 0.55 + _phase_off) * (1.0 - _walk_w) + _tail_add.y
	_write_parts(false, yaw, lift)
	_jaw_req = -1.0
	_frill_req = -9.0
	_tail_add = Vector2.ZERO


## Writes the Jaw / Frill / Tail transforms (skipped when they barely changed).
func _write_parts(force: bool, tail_yaw: float = 0.0, tail_lift: float = 0.0) -> void:
	if _jaw_node and (force or absf(_jaw - _jaw_w) > 0.2):
		_jaw_w = _jaw
		_jaw_node.transform = Transform3D(Basis(Vector3.RIGHT, _jaw * DEG), _jaw_local)
	if _frill_node:
		var flutter: float = 0.0
		if _frill > 0.7 and _tier == 0 and not _dead:
			flutter = 0.03 * sin(_t * 70.0) * (_frill - 0.7) / 0.3
		var key := Vector2(_frill, flutter)
		if force or absf(key.x - _frill_w.x) > 0.004 or absf(key.y - _frill_w.y) > 0.004:
			_frill_w = key
			var u: float = _frill
			var sxy: float = lerpf(0.60, 1.08, u) + flutter
			var sz: float = lerpf(1.9, 1.0, clampf(u, 0.0, 1.0)) + 0.6 * minf(u, 0.0) * -1.0
			var tilt: float = lerpf(-0.22, 0.12, u)
			_frill_node.transform = Transform3D(Basis(Vector3.RIGHT, tilt) * Basis.from_scale(Vector3(sxy, sxy, sz)),
				_frill_local)
	if _tail_node:
		var tk := Vector2(tail_yaw, tail_lift)
		if force or absf(tk.x - _tail_w.x) > 0.15 or absf(tk.y - _tail_w.y) > 0.15:
			_tail_w = tk
			_tail_node.transform = Transform3D(Basis(Vector3.UP, tk.x * DEG) * Basis(Vector3.RIGHT, tk.y * DEG),
				_tail_local)


func _next_bob() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return bob_every * (0.6 + 0.8 * h)


## Keyframe track [t, v, ease, ...] (see the constants). A few float ops per call.
static func _trk(t: float, k: PackedFloat32Array) -> float:
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


# ================================================================ meshes (static, built once per game, model space)

# Body loft stations along the spine (tail root -> neck): centre, half-width, half-height. Low and wide: the back
# ~0.44 m, the belly ~0.13 m over splayed legs.
const BODY_C: Array[Vector3] = [Vector3(0, 0.235, -0.66), Vector3(0, 0.245, -0.56), Vector3(0, 0.26, -0.40),
	Vector3(0, 0.275, -0.20), Vector3(0, 0.28, 0.0), Vector3(0, 0.28, 0.18), Vector3(0, 0.285, 0.32),
	Vector3(0, 0.295, 0.44), Vector3(0, 0.30, 0.52)]
const BODY_RX: Array[float] = [0.07, 0.12, 0.19, 0.235, 0.245, 0.23, 0.19, 0.145, 0.12]
const BODY_RY: Array[float] = [0.07, 0.10, 0.13, 0.15, 0.155, 0.145, 0.13, 0.115, 0.105]
const BODY_BANDS: Array[bool] = [false, true, false, true, false, true, false, true]
# Tail loft (tip -> root, so the loft's "up" is +Y): drags toward the ground and its last third curls round to one
# side (Art Lab R10: the tip stays within radius 0.45 x 2.4 + 25 % behind the centre; same length along the curve).
const TAIL_C: Array[Vector3] = [Vector3(0.30, 0.065, -1.29), Vector3(0.23, 0.085, -1.21),
	Vector3(0.14, 0.115, -1.10), Vector3(0.06, 0.15, -0.98), Vector3(0.012, 0.185, -0.86), Vector3(0, 0.215, -0.71),
	Vector3(0, 0.24, -0.56), Vector3(0, 0.245, -0.46)]
const TAIL_RX: Array[float] = [0.008, 0.022, 0.036, 0.052, 0.068, 0.085, 0.10, 0.105]
const TAIL_RY: Array[float] = [0.008, 0.026, 0.042, 0.06, 0.078, 0.095, 0.11, 0.115]
const TAIL_BANDS: Array[bool] = [true, false, true, false, true, false, false]
# Skull (upper head, flat wedge) and lower jaw lofts.
const HEAD_C: Array[Vector3] = [Vector3(0, 0.305, 0.40), Vector3(0, 0.312, 0.50), Vector3(0, 0.308, 0.60),
	Vector3(0, 0.298, 0.70), Vector3(0, 0.287, 0.80), Vector3(0, 0.279, 0.88), Vector3(0, 0.273, 0.94)]
const HEAD_RX: Array[float] = [0.125, 0.14, 0.13, 0.108, 0.088, 0.07, 0.045]
const HEAD_RY: Array[float] = [0.10, 0.105, 0.09, 0.075, 0.062, 0.05, 0.035]
const JAW_C: Array[Vector3] = [Vector3(0, 0.272, 0.44), Vector3(0, 0.266, 0.54), Vector3(0, 0.261, 0.64),
	Vector3(0, 0.257, 0.74), Vector3(0, 0.254, 0.84), Vector3(0, 0.253, 0.92)]
const JAW_RX: Array[float] = [0.118, 0.124, 0.11, 0.09, 0.07, 0.045]
const JAW_RY: Array[float] = [0.072, 0.066, 0.056, 0.046, 0.036, 0.026]
const TOP := 1.1              # half-angle (rad) of the banded back
const BELLY := 2.05           # angle (rad) where the pale belly starts
const UPPER := 1.95           # skull lip line (rad from the top)
const LOW := 1.35             # jaw lip line (rad from the top)
const THROAT := 2.3
const RING := 12
# Frill: a ring sector round the neck (a = 0 at the top), inner radius, band split, spine tips, sweep back.
const FRILL_A := 2.05
const FRILL_SPINES := 9
const FRILL_RI := 0.12
const FRILL_RM := 0.21
const FRILL_RS := 0.37
const FRILL_RG := 0.295
const FRILL_SWEEP := 0.42


static func _bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## Appends primitive `m` (surface 0) transformed by xf.
static func _put(acc: Array, m: Mesh, xf: Transform3D) -> void:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb := xf.basis.inverse().transposed()
	var b0: int = (acc[0] as PackedVector3Array).size()
	for j: int in v.size():
		acc[0].append(xf * v[j])
		acc[1].append((nb * nr[j]).normalized())
		acc[2].append(Vector2.ZERO)
	if ix.is_empty():
		for j: int in v.size():
			acc[3].append(b0 + j)
	else:
		for j: int in ix.size():
			acc[3].append(b0 + ix[j])


static func _ellipsoid(acc: Array, c: Vector3, r: Vector3, radial: int = 8, rings: int = 4,
		rot: Basis = Basis.IDENTITY) -> void:
	_put(acc, sphere(1.0, radial, rings), Transform3D(rot * Basis.from_scale(r), c))


## A (cols+1) x (rows+1) grid of points (row-major) with given normals; each triangle wound so its front (Godot:
## clockwise) faces its normals; degenerate triangles (cone tips) are skipped.
static func _grid(acc: Array, pts: PackedVector3Array, nrm: PackedVector3Array, cols: int, rows: int) -> void:
	var w := cols + 1
	var b0: int = (acc[0] as PackedVector3Array).size()
	for k: int in pts.size():
		acc[0].append(pts[k])
		acc[1].append(nrm[k])
		acc[2].append(Vector2.ZERO)
	for j: int in rows:
		for i: int in cols:
			var q0 := j * w + i
			for tri: Array in [[q0, q0 + 1, q0 + w], [q0 + 1, q0 + w + 1, q0 + w]]:
				var a: int = tri[0]
				var b: int = tri[1]
				var c: int = tri[2]
				var front := -(pts[b] - pts[a]).cross(pts[c] - pts[a])
				if front.length_squared() < 1e-14:
					continue
				if front.dot(nrm[a] + nrm[b] + nrm[c]) < 0.0:
					var t := b
					b = c
					c = t
				acc[3].append(b0 + a)
				acc[3].append(b0 + b)
				acc[3].append(b0 + c)


## Point of a loft at station i (integer), angle a (0 = top, PI/2 = +x side, PI = belly), radii scaled by `inflate`.
## Stations must run toward +Z (the loft's "up" is then +Y).
static func _lp(c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, a: float, inflate: float = 1.0) -> Vector3:
	var n := c.size()
	i = clampi(i, 0, n - 1)
	var t := (c[mini(i + 1, n - 1)] - c[maxi(i - 1, 0)]).normalized()
	var up := t.cross(Vector3.RIGHT).normalized()
	return c[i] + Vector3.RIGHT * sin(a) * rx[i] * inflate + up * cos(a) * ry[i] * inflate


## Emits a patch of a loft: stations i0..i1, the same angle list at every station. Normals come from the analytic
## surface, so separate patches (bands / flanks / belly) shade seamlessly.
static func _loft_patch(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i0: int, i1: int,
		angs: PackedFloat32Array) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for i: int in range(i0, i1 + 1):
		for a: float in angs:
			var p := _lp(c, rx, ry, i, a)
			var du := _lp(c, rx, ry, i, a + 0.02) - _lp(c, rx, ry, i, a - 0.02)
			var dv := _lp(c, rx, ry, i + 1, a) - _lp(c, rx, ry, i - 1, a)
			var nn := du.cross(dv)
			var radial := p - c[i]
			if nn.length_squared() < 1e-10:
				nn = radial
			nn = nn.normalized()
			if nn.dot(radial) < 0.0:
				nn = -nn
			pts.append(p)
			nrm.append(nn)
	_grid(acc, pts, nrm, angs.size() - 1, i1 - i0)


## A flat strip across a loft (palate / mouth floor): at every station from angle a0 to a1 through the middle,
## the middle pushed by `vault`, all normals = `n`.
static func _strip(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], a0: float, a1: float,
		vault: float, n: Vector3) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for i: int in c.size():
		var l := _lp(c, rx, ry, i, a0)
		var r := _lp(c, rx, ry, i, a1)
		pts.append(l)
		pts.append((l + r) * 0.5 - n * vault)
		pts.append(r)
		for k: int in 3:
			nrm.append(n)
	_grid(acc, pts, nrm, 2, c.size() - 1)


## A fan closing a loft end at station i (normal along `n`), tip pushed out by `bulge`.
static func _cap(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, n: Vector3,
		bulge: float) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in RING + 1:
			var a := TAU * float(k) / float(RING)
			if row == 0:
				pts.append(_lp(c, rx, ry, i, a))
				nrm.append((Vector3(sin(a), cos(a), 0.0) * 0.5 + n).normalized())
			else:
				pts.append(c[i] + n * bulge)
				nrm.append(n)
	_grid(acc, pts, nrm, RING, 1)


static func _even(a0: float, a1: float, steps: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k: int in steps + 1:
		out.append(lerpf(a0, a1, float(k) / float(steps)))
	return out


## Smooth tube through pts (radii per point, 0 = a point), `seg` sides; `ref` must not be parallel to the path.
static func _tube(acc: Array, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int, ref: Vector3) -> void:
	var grid := PackedVector3Array()
	var nrm := PackedVector3Array()
	var n := pts.size()
	for i: int in n:
		var t := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var s := t.cross(ref).normalized()
		var u := s.cross(t).normalized()
		for k: int in seg + 1:
			var a := TAU * float(k) / float(seg)
			var d := s * cos(a) + u * sin(a)
			grid.append(pts[i] + d * radii[i])
			nrm.append(d if radii[i] > 0.0 else t)
	_grid(acc, grid, nrm, seg, n - 1)


## A small open cone (studs, crest plates, claws, teeth, frill spines): `sides` faces from a ring at `base` to `tip`.
static func _cone(acc: Array, base: Vector3, tip: Vector3, r: float, sides: int = 4) -> void:
	var d := tip - base
	var ln := d.length()
	if ln < 0.0001:
		return
	var t := d / ln
	var ref := Vector3.RIGHT if absf(t.dot(Vector3.RIGHT)) < 0.8 else Vector3.FORWARD
	var s := t.cross(ref).normalized()
	var u := s.cross(t).normalized()
	var slope := r / ln
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	for row: int in 2:
		for k: int in sides + 1:
			var a := TAU * float(k) / float(sides)
			var dir := s * cos(a) + u * sin(a)
			pts.append(base + dir * r if row == 0 else tip)
			nrm.append((dir + t * slope).normalized())
	_grid(acc, pts, nrm, sides, 1)


## Centre / half-width / half-height of a loft at any z (linear between stations): [Vector3, float, float].
static func _loft_at(c: Array[Vector3], rx: Array[float], ry: Array[float], z: float) -> Array:
	var n := c.size()
	if z <= c[0].z:
		return [c[0], rx[0], ry[0]]
	for i: int in n - 1:
		if z <= c[i + 1].z:
			var u: float = (z - c[i].z) / maxf(c[i + 1].z - c[i].z, 0.0001)
			return [c[i].lerp(c[i + 1], u), lerpf(rx[i], rx[i + 1], u), lerpf(ry[i], ry[i + 1], u)]
	return [c[n - 1], rx[n - 1], ry[n - 1]]


## Surface point (and outward normal) of an elliptic loft section at angle a: [point, normal].
static func _on_loft(c: Array[Vector3], rx: Array[float], ry: Array[float], z: float, a: float) -> Array:
	var s: Array = _loft_at(c, rx, ry, z)
	var ctr: Vector3 = s[0]
	var hx: float = s[1]
	var hy: float = s[2]
	var p := ctr + Vector3(sin(a) * hx, cos(a) * hy, 0.0)
	var nn := Vector3(sin(a) / maxf(hx, 0.001), cos(a) / maxf(hy, 0.001), 0.0).normalized()
	return [p, nn]


## One ArrayMesh from [acc, material] pairs (empty accs skipped), cached by key.
static func _commit(key: String, surfaces: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for sf: Array in surfaces:
		var acc: Array = sf[0]
		if (acc[0] as PackedVector3Array).is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc[0]
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_TEX_UV] = acc[2]
		arrays[Mesh.ARRAY_INDEX] = acc[3]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, sf[1])
	_mf_meshes[key] = am
	return am


## Moves every vertex of an accumulator by -o (meshes of keep_separate parts are local to their origin).
static func _shift(acc: Array, o: Vector3) -> void:
	var v: PackedVector3Array = acc[0]
	for i: int in v.size():
		v[i] -= o
	acc[0] = v


## Body (Mount): a banded back (dark cross-bands down the top), green-bronze flanks, a pale belly, the neck and
## tail-root caps, a double row of bronze studs down the spine.
static func _body_mesh() -> Mesh:
	const KEY := "body_v1"
	if _mf_meshes.has(KEY):
		return _mf_meshes[KEY]
	var skin := _bucket()
	var dark := _bucket()
	var belly := _bucket()
	var bronze := _bucket()
	var n: int = BODY_C.size()
	for i: int in n - 1:
		_loft_patch(dark if BODY_BANDS[i] else skin, BODY_C, BODY_RX, BODY_RY, i, i + 1, _even(-TOP, TOP, 4))
	_loft_patch(skin, BODY_C, BODY_RX, BODY_RY, 0, n - 1, _even(TOP, BELLY, 3))
	_loft_patch(skin, BODY_C, BODY_RX, BODY_RY, 0, n - 1, _even(TAU - BELLY, TAU - TOP, 3))
	_loft_patch(belly, BODY_C, BODY_RX, BODY_RY, 0, n - 1, _even(BELLY, TAU - BELLY, 4))
	_cap(skin, BODY_C, BODY_RX, BODY_RY, n - 1, Vector3.BACK, 0.04)
	_cap(skin, BODY_C, BODY_RX, BODY_RY, 0, Vector3.FORWARD, 0.03)
	# Studs: two rows of low bronze keels down the spine, leaning back.
	for z: float in [0.34, 0.21, 0.08, -0.05, -0.18, -0.31, -0.44]:
		for side: float in [-1.0, 1.0]:
			var pn: Array = _on_loft(BODY_C, BODY_RX, BODY_RY, z, 0.42 * side)
			var p: Vector3 = pn[0]
			var nn: Vector3 = pn[1]
			var h: float = 0.045 * (1.0 - 0.3 * absf(z + 0.05))
			_cone(bronze, p - nn * 0.01, p + nn * h + Vector3(0, 0, -0.025), 0.028, 4)
	return _commit(KEY, [[skin, _m(&"mirefang_scale")], [dark, _m(&"mirefang_dark")],
		[belly, _m(&"mirefang_belly")], [bronze, _m(&"mirefang_dark")]])


## Head (Mount/Head): the flat wedge skull with a dark crown, a warm palate, jaw-muscle cheeks, the raised eye bumps
## with the AMBER GLOW eyes and dark brows, two crown ridges, nostrils, upper fangs over the lip.
static func _head_mesh() -> Mesh:
	const KEY := "head_v1"
	if _mf_meshes.has(KEY):
		return _mf_meshes[KEY]
	var skin := _bucket()
	var dark := _bucket()
	var belly := _bucket()
	var mouth := _bucket()
	var eye := _bucket()
	var n: int = HEAD_C.size()
	_loft_patch(dark, HEAD_C, HEAD_RX, HEAD_RY, 0, 2, _even(-0.5, 0.5, 2))
	_loft_patch(skin, HEAD_C, HEAD_RX, HEAD_RY, 2, n - 1, _even(-0.5, 0.5, 2))
	_loft_patch(skin, HEAD_C, HEAD_RX, HEAD_RY, 0, n - 1, _even(0.5, UPPER, 4))
	_loft_patch(skin, HEAD_C, HEAD_RX, HEAD_RY, 0, n - 1, _even(-UPPER, -0.5, 4))
	_strip(mouth, HEAD_C, HEAD_RX, HEAD_RY, -UPPER, UPPER, 0.012, Vector3.DOWN)
	_ellipsoid(skin, Vector3(0, 0.268, 0.943), Vector3(0.05, 0.036, 0.034), 6, 3)
	for sx: float in [-1.0, 1.0]:
		# Jaw-muscle cheeks at the back of the head.
		_ellipsoid(skin, Vector3(0.112 * sx, 0.29, 0.47), Vector3(0.052, 0.062, 0.078), 6, 3)
		# Eye bump, the glowing eye on it, the heavy brow over it.
		_ellipsoid(skin, Vector3(0.088 * sx, 0.372, 0.60), Vector3(0.056, 0.048, 0.062), 6, 3)
		_ellipsoid(eye, Vector3(0.106 * sx, 0.388, 0.612), Vector3(0.044, 0.04, 0.05), 8, 4)
		# (the heavy 3D brow: the CreatureFaceRig brow ridge now, faces pass 2026-09-28)
		# Crown ridge from behind the eye to the neck.
		_ellipsoid(dark, Vector3(0.05 * sx, 0.40, 0.49), Vector3(0.026, 0.02, 0.075), 6, 3)
		# Nostril.
		_ellipsoid(dark, Vector3(0.022 * sx, 0.302, 0.925), Vector3(0.014, 0.01, 0.014), 5, 2)
		# Upper fangs hanging over the lower lip.
		for z: float in [0.64, 0.72, 0.80, 0.87]:
			var pn: Array = _on_loft(HEAD_C, HEAD_RX, HEAD_RY, z, UPPER * sx)
			var base: Vector3 = (pn[0] as Vector3) + Vector3(-0.006 * sx, 0.006, 0.0)
			var ln: float = 0.03 if z > 0.85 or z < 0.66 else 0.024
			_cone(belly, base, base + Vector3(0.004 * sx, -ln, 0.004), 0.009, 3)
	return _commit(KEY, [[skin, _m(&"mirefang_scale")], [dark, _m(&"mirefang_dark")],
		[belly, _m(&"mirefang_belly")], [mouth, _m(&"mirefang_frill")], [eye, _m(&"mirefang_eye_glow")]])


## Lower jaw (keep_separate "Jaw", local to JAW_ORIGIN): scaled sides, a pale throat, the warm mouth floor, lower
## teeth, a rounded chin.
static func _jaw_mesh() -> Mesh:
	const KEY := "jaw_v1"
	if _mf_meshes.has(KEY):
		return _mf_meshes[KEY]
	var skin := _bucket()
	var belly := _bucket()
	var mouth := _bucket()
	var n: int = JAW_C.size()
	_loft_patch(skin, JAW_C, JAW_RX, JAW_RY, 0, n - 1, _even(LOW, THROAT, 3))
	_loft_patch(skin, JAW_C, JAW_RX, JAW_RY, 0, n - 1, _even(TAU - THROAT, TAU - LOW, 3))
	_loft_patch(belly, JAW_C, JAW_RX, JAW_RY, 0, n - 1, _even(THROAT, TAU - THROAT, 3))
	_strip(mouth, JAW_C, JAW_RX, JAW_RY, TAU - LOW, LOW, 0.01, Vector3.UP)
	_ellipsoid(skin, Vector3(0, 0.254, 0.925), Vector3(0.046, 0.028, 0.03), 6, 3)
	for sx: float in [-1.0, 1.0]:
		for z: float in [0.70, 0.79, 0.87]:
			var pn: Array = _on_loft(JAW_C, JAW_RX, JAW_RY, z, LOW * sx)
			var base: Vector3 = (pn[0] as Vector3) + Vector3(-0.008 * sx, -0.004, 0.0)
			_cone(belly, base, base + Vector3(0.0, 0.024, 0.004), 0.008, 3)
	for acc: Array in [skin, belly, mouth]:
		_shift(acc, JAW_ORIGIN)
	return _commit(KEY, [[skin, _m(&"mirefang_scale")], [belly, _m(&"mirefang_belly")], [mouth, _m(&"mirefang_frill")]])


## Frill point (local to FRILL_ORIGIN, fully fanned): angle a round the neck (0 = top), radius r; a shallow cone
## sweeping back.
static func _fp(a: float, r: float) -> Vector3:
	return Vector3(sin(a) * r, cos(a) * r * 0.92, -FRILL_SWEEP * (r - FRILL_RI))


## Frill (keep_separate "Frill", local to FRILL_ORIGIN, built fully fanned; the pose folds it by scaling): a ring
## sector of membrane, dark inner band, bronze-orange outer band scalloped between 9 dark spines; both faces.
static func _frill_mesh() -> Mesh:
	const KEY := "frill_v1"
	if _mf_meshes.has(KEY):
		return _mf_meshes[KEY]
	var dark := _bucket()
	var frill := _bucket()
	var cols: int = (FRILL_SPINES - 1) * 2
	for band: int in 2:
		for face: float in [1.0, -1.0]:
			var pts := PackedVector3Array()
			var nrm := PackedVector3Array()
			for row: int in 2:
				for k: int in cols + 1:
					var a: float = lerpf(-FRILL_A, FRILL_A, float(k) / float(cols))
					var ro: float = FRILL_RS if k % 2 == 0 else FRILL_RG
					var r: float
					if band == 0:
						r = FRILL_RI if row == 0 else FRILL_RM
					else:
						r = FRILL_RM if row == 0 else ro
					var du := _fp(a + 0.01, r) - _fp(a - 0.01, r)
					var dv := _fp(a, r + 0.01) - _fp(a, r - 0.01)
					var nn := du.cross(dv).normalized()
					if nn.z < 0.0:
						nn = -nn
					pts.append(_fp(a, r) + nn * 0.002 * face)
					nrm.append(nn * face)
			_grid(dark if band == 0 else frill, pts, nrm, cols, 1)
	for k: int in FRILL_SPINES:
		var a: float = lerpf(-FRILL_A, FRILL_A, float(k) / float(FRILL_SPINES - 1))
		var du := _fp(a + 0.01, 0.25) - _fp(a - 0.01, 0.25)
		var dv := _fp(a, 0.26) - _fp(a, 0.24)
		var nn := du.cross(dv).normalized()
		if nn.z < 0.0:
			nn = -nn
		_cone(dark, _fp(a, FRILL_RI + 0.02) + nn * 0.008, _fp(a, FRILL_RS + 0.035) + nn * 0.006, 0.014, 4)
	return _commit(KEY, [[dark, _m(&"mirefang_dark")], [frill, _m(&"mirefang_frill")]])


## Tail (keep_separate "Tail", local to TAIL_ORIGIN): dark cross-bands on top, scaled flanks, a pale underside, a
## rounded tip and a row of bronze crest plates.
static func _tail_mesh() -> Mesh:
	const KEY := "tail_v1"
	if _mf_meshes.has(KEY):
		return _mf_meshes[KEY]
	var skin := _bucket()
	var dark := _bucket()
	var belly := _bucket()
	var bronze := _bucket()
	var n: int = TAIL_C.size()
	for i: int in n - 1:
		_loft_patch(dark if TAIL_BANDS[i] else skin, TAIL_C, TAIL_RX, TAIL_RY, i, i + 1, _even(-TOP, TOP, 4))
	_loft_patch(skin, TAIL_C, TAIL_RX, TAIL_RY, 0, n - 1, _even(TOP, BELLY, 3))
	_loft_patch(skin, TAIL_C, TAIL_RX, TAIL_RY, 0, n - 1, _even(TAU - BELLY, TAU - TOP, 3))
	_loft_patch(belly, TAIL_C, TAIL_RX, TAIL_RY, 0, n - 1, _even(BELLY, TAU - BELLY, 3))
	_ellipsoid(dark, TAIL_C[0] + Vector3(0, 0, -0.005), Vector3(0.014, 0.014, 0.02), 5, 2)
	for i: int in range(1, n - 1):
		var p := _lp(TAIL_C, TAIL_RX, TAIL_RY, i, 0.0)
		var h: float = 0.022 + 0.05 * float(i) / float(n - 2)
		_cone(bronze, p + Vector3(0, -0.012, 0), p + Vector3(0, h, -0.6 * h), 0.022 + 0.01 * float(i) / float(n - 2), 4)
	for acc: Array in [skin, dark, belly, bronze]:
		_shift(acc, TAIL_ORIGIN)
	return _commit(KEY, [[skin, _m(&"mirefang_scale")], [dark, _m(&"mirefang_dark")],
		[belly, _m(&"mirefang_belly")], [bronze, _m(&"mirefang_dark")]])


## One splayed leg (model space): a thick shoulder / thigh, the upper limb going out sideways to the elbow / knee,
## the lower limb down to a flat hand / foot with four dark splayed claws.
static func _leg_mesh(front: bool, sx: float) -> Mesh:
	var key := "leg_v1_%s_%s" % [front, sx]
	if _mf_meshes.has(key):
		return _mf_meshes[key]
	var skin := _bucket()
	var dark := _bucket()
	var root: Vector3
	var joint: Vector3
	var wrist: Vector3
	var foot: Vector3
	var r_up: PackedFloat32Array
	var r_lo: PackedFloat32Array
	var toes: Array[float]
	if front:
		root = Vector3(0.19 * sx, 0.27, 0.30)
		joint = Vector3(0.335 * sx, 0.225, 0.275)
		wrist = Vector3(0.37 * sx, 0.055, 0.33)
		foot = Vector3(0.38 * sx, 0.028, 0.355)
		r_up = PackedFloat32Array([0.062, 0.055, 0.048])
		r_lo = PackedFloat32Array([0.047, 0.042, 0.036])
		toes = [-25.0, 5.0, 35.0, 70.0]
		_ellipsoid(skin, Vector3(0.21 * sx, 0.265, 0.30), Vector3(0.075, 0.07, 0.085), 6, 3)
	else:
		root = Vector3(0.17 * sx, 0.26, -0.40)
		joint = Vector3(0.35 * sx, 0.24, -0.35)
		wrist = Vector3(0.38 * sx, 0.055, -0.46)
		foot = Vector3(0.39 * sx, 0.028, -0.44)
		r_up = PackedFloat32Array([0.075, 0.065, 0.055])
		r_lo = PackedFloat32Array([0.05, 0.044, 0.037])
		toes = [-15.0, 12.0, 38.0, 62.0]
		_ellipsoid(skin, Vector3(0.21 * sx, 0.255, -0.41), Vector3(0.09, 0.085, 0.11), 6, 3)
	var mid_u := (root + joint) * 0.5 + Vector3(0, 0.012, 0)
	var mid_l := (joint + wrist) * 0.5 + Vector3(0.012 * sx, 0, 0)
	_tube(skin, PackedVector3Array([root, mid_u, joint]), r_up, 6, Vector3.FORWARD)
	_ellipsoid(skin, joint, Vector3.ONE * r_up[2] * 1.05, 6, 3)
	_tube(skin, PackedVector3Array([joint, mid_l, wrist]), r_lo, 6, Vector3.FORWARD)
	_ellipsoid(skin, foot, Vector3(0.056, 0.024, 0.062), 6, 3)
	var tl: float = 0.075 if front else 0.09
	for deg: float in toes:
		var d := Vector3(sin(deg * DEG) * sx, 0.0, cos(deg * DEG))
		var b := foot + d * 0.03 + Vector3(0, 0.004, 0)
		_cone(dark, b, b + d * tl + Vector3(0, -0.02, 0), 0.015, 4)
	return _commit(key, [[skin, _m(&"mirefang_scale")], [dark, _m(&"mirefang_dark")]])


## The eyes (faces pass 2026-09-28): the amber glow orbs stay (the glow point); painted on their front, a slit pupil
## and dark lids, and a dark brow ridge above that carries the expression. Drawn inside the merged head
## (CreatureFaceRig host mode: the Mirefang keeps its 10 draw instances).
static func face_spec() -> Dictionary:
	var out := Vector3(0.62, 0.62, 0.48).normalized()
	return CreatureFaceRig.side_eye_spec(Vector3(0.106, 0.388, 0.612) + out * 0.042, out, 0.040,
		Color(0.35, 0.36, 0.16), Color(1.0, 0.62, 0.12), 1.0, {"eye": {"pupil": 0.62, "pupil_w": 0.30, "top": 0.030},
		"palette": {"brow": Color(0.06, 0.15, 0.12), "lash": Color(0.05, 0.08, 0.05)}, "lift": 0.006})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
