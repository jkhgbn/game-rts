extends CharacterModel
## Bristleback (map-fill.md 5.1 / 10, task 12.V20): the tier-1 camp creature of the Bristleback Wallows. A small,
## scrappy wild boar (1.1 m to the top of its quills, ~1.9 m snout to tail, selection radius 0.55), NOT the epic
## Ironhide Tusker (12.V27: twice the size, iron-grey plate hide). Read at 40 m by three things:
##  - a DARK MOHAWK OF QUILLS with pale bone tips raking back along the spine, tallest over the hunched shoulders,
##    plus short hackles splayed out at the withers (they bristle up when it fights, flatten when it trots),
##  - big pale TUSKS curling up and back out of the jaw (the only light value on the front),
##  - a warm russet hide over a mud-caked belly and legs (a scalloped mud line on the flanks), dark dorsal stripe.
## Wedge head carried low (lower than the hump), a flat dark snout disc, a mean brow over beady eyes, cheek bristles,
## pointed ears laid back, a thin tail with a tuft.
## Neutral: no team colour (set_team_color is a no-op), no glow, 0 lights.
## Motion (all procedural, kit rules):
##  - idle: breathing, a slow look around and SNUFFLE bursts (nose down, quick twitches); every ~dig_every s at
##    close range a DIG fidget (roots the ground with the snout 3 times, paws with a fore hoof, dirt puffs + clods,
##    a snorting head shake); `play_dig()` starts one now (preview / camp idle);
##  - walk: a quick short-legged trot (diagonal pairs, hooves lifted on the swing, double bounce, head bobbing low),
##    the quill ridge flattened and swaying;
##  - attack `tusk_gore` (0.62 s, strike 0.12 s = the kit strike frame, damage stays instant): head drops, tusks
##    forward, weight back (0.07), then a lunge +0.3 m with an upward HOOKING toss of the head (strike: dirt + clods
##    at the tusks), a counter-twist and recovery; the quills flare for the whole blow;
##  - hit: the kit flinch + a head jerk, the quills spike up, mud flecks fly off the flank;
##  - death (1.0 s): a squeal (head up), the fore knees buckle, it topples onto its side (dust as it lands), the hind
##    legs kick twice, then it sinks away (the unit is freed at death_finished);
##  - cast (the spec lists no Bristleback ability; any id is safe): rears up squealing on its hind legs and stamps
##    down (dust + clods at the fore hooves).
## Budget (map-fill.md 10, soldier: <= 18 authored meshes, <= 10 draw instances, 0 lights): 8 authored meshes
## (body, head, 4 legs, the Quills ridge, the blob), each one multi-surface mesh built once per game from primitives
## and lofts; 10 draw instances (6 merged pivots + Quills + blob + 2 pre-built one-shot emitters Dust / Clods in the
## scene); 4 own materials (materials/) + the kit's unit_eye_dark; see tests/test_12_v20.gd.

const BB_DIR := "res://art/units/neutral/bristleback/materials/"
const QUILL_ORIGIN := Vector3(0.0, 0.90, 0.0)     # model space: the ridge scales about this spine point
const GORE_LEN := 0.62
const GORE_HIT := 0.12
const DIG_LEN := 2.2
const CAST_LEN := 0.8
const CAST_STAMP := 0.46
const DEATH_LAND := 0.54
const FRONT_Z := 0.33                             # fore / hind hoof z: the root pitches about them
const HIND_Z := -0.48

# Keyframe tracks [t, value, ease, t, value, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth,
# 1 ease-out, 2 ease-in). Angles in deg. Head x: + = nose down. Legs x: - = hoof forward. Pitch: + = nose down.
static var G_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.08, 1, 0.12, 0.30, 2, 0.26, 0.24, 1, 0.62, 0.0, 0])
static var G_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.045, 1, 0.12, 0.03, 2, 0.26, -0.01, 1, 0.45, 0.0, 0])
static var G_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, 7.0, 1, 0.12, -5.0, 2, 0.28, -2.0, 1, 0.5, 0.0, 0])
static var G_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, 32.0, 1, 0.12, -32.0, 2, 0.24, -20.0, 1, 0.40, 6.0, 0,
	0.62, 0.0, 0])
static var G_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, -4.0, 0, 0.12, 16.0, 2, 0.28, -9.0, 0, 0.45, 0.0, 0])
static var G_HEAD_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, -10.0, 2, 0.28, 6.0, 0, 0.45, 0.0, 0])
static var G_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.07, -14.0, 1, 0.12, -30.0, 1, 0.30, -8.0, 0, 0.62, 0.0, 0])
static var G_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.12, 26.0, 1, 0.30, 6.0, 0, 0.62, 0.0, 0])
static var C_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.22, -15.0, 1, 0.38, -13.0, 0, 0.46, 3.0, 2, 0.8, 0.0, 0])
static var C_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.22, -34.0, 1, 0.40, -28.0, 0, 0.48, 18.0, 2, 0.8, 0.0, 0])
static var C_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.22, -42.0, 1, 0.40, -36.0, 0, 0.47, 0.0, 2, 0.8, 0.0, 0])
static var C_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.22, 12.0, 1, 0.40, 10.0, 0, 0.5, 0.0, 0])
static var D_SQUEAL := PackedFloat32Array([0.0, 0.0, 0, 0.12, 1.0, 1, 0.22, 1.0, 0, 0.36, 0.0, 0])

## Idle dig fidget interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var dig_every: float = 7.0

static var _bb_mats: Dictionary = {}
static var _bb_meshes: Dictionary = {}

var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _quills: MeshInstance3D
var _dust: GPUParticles3D
var _clods: GPUParticles3D
var _quill_r: float = 0.0
var _quill_w: Vector2 = Vector2(99.0, 99.0)
var _dig_wait: float = 0.0
var _cast_last: float = -1.0
var _strikes: int = 0
## G-D signature emitter (High / Ultra only; null otherwise).
var _sig: GPUParticles3D


static func _m(name: StringName) -> Material:
	if not _bb_mats.has(name):
		_bb_mats[name] = load(BB_DIR + String(name) + ".tres")
	return _bb_mats[name]


# ================================================================ public (tests, preview, camp idle)

## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Tusk-gore strikes played so far (the `release` frame of each attack), for tests.
func strike_count() -> int:
	return _strikes


## The ridge's current bristle (-0.3 flat .. 1 fully raised).
func quill_raise() -> float:
	return _quill_r


## Starts the idle dig now (it also plays by itself every ~dig_every s when standing close to the camera).
func play_dig() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"dig"
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
	_part(mount, _body_mesh(), Vector3.ZERO)
	_part($Root/Mount/Head, _head_mesh(), Vector3.ZERO)
	_face = CreatureFaceRig.attach(self, $Root/Mount/Head, "bristleback", face_spec())
	for leg: Node3D in [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]:
		var p := model_origin(leg)
		_part(leg, _leg_mesh(p.z > 0.0, signf(p.x)), Vector3.ZERO)
	_quills = _part(mount, _quill_mesh(), QUILL_ORIGIN, true, "Quills")
	_quills.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_dust = $Fx/Dust
	_clods = $Fx/Clods
	ensure_shadow_blob(0.55, Color(0.06, 0.04, 0.02, 0.5))
	_shadow.scale = Vector3(1.3, 1.0, 2.2)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	# The kit flashes the merged Chest / Head / ArmR on hits; a quadruped has none: add the body, head and quills.
	for i: int in [P_MOUNT, P_MOUNT_HEAD]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
		if m and i == P_MOUNT_HEAD:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if _quills and not _flash_hit_targets.has(_quills):
		_flash_hit_targets.append(_quills)
	_dig_wait = _next_dig() * 0.6
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))
	_write_quills(0.0, 0.0, true)
	# G-D signature (High+): warm snort puffs at the snout disc.
	var head: Node3D = $Root/Mount/Head
	_sig = CreatureSignature.attach(self, head, Vector3(0.0, 0.5, 1.12) - model_origin(head), &"breath", 0.8)


## G-D signature gate (CreatureSignature, High / Ultra only): near tier, animating, alive.
func signature_should_emit() -> bool:
	return _tier == 0 and not _offscreen and not _frozen and not _dead


# ================================================================ hooks

func play_hit() -> void:
	var before := _hit_t
	super.play_hit()
	if _hit_t == 0.0 and before != 0.0 and _tier == 0 and _clods:
		_emit(_clods, Vector3(0.0, 0.72, 0.05))


func _on_action_event(ev: StringName) -> void:
	if ev == &"release" and _action == &"attack":
		_strikes += 1
		if _tier < 2:
			_emit(_dust, Vector3(0.0, 0.06, 1.18))
			_emit(_clods, Vector3(0.0, 0.5, 1.12))


func _on_revive() -> void:
	if _face:
		_face.reset()
	_quill_r = 0.0
	_cast_last = -1.0
	_write_quills(0.0, 0.0, true)


## Restarts a pre-built one-shot emitter at a model-space point (the emitters live under Fx, which never moves).
func _emit(p: GPUParticles3D, at: Vector3) -> void:
	if p == null:
		return
	p.position = at
	p.restart()


# ================================================================ idle / walk

func _idle_head(ph: float) -> Vector3:
	# Snuffle bursts: the nose dips toward the ground and twitches; between them a slow look around.
	var burst: float = smoothstep(0.35, 0.85, sin(ph * 0.5 + _phase_off * 3.0))
	var x: float = 5.0 + 3.0 * sin(ph) + burst * (7.0 + 3.0 * sin(_t * 25.0))
	var y: float = 10.0 * sin(ph * 0.37 + 0.6) * (1.0 - 0.6 * burst)
	return Vector3(x, y, 0.0) * DEG


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.012 * sin(ph), 0))
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + _idle_head(ph))


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	pos(P_ROOT, Vector3(0, 0.012 * sin(ph) * w, 0))
	rot(P_MOUNT_HEAD, _idle_head(ph) * w * _idle_head_w())


## The idle snuffle (up to +18 deg nose down) fades out over the gore's windup and back in over its last 0.15 s:
## it used to stay on through the attack and, by idle phase (instance id), damp the strike's head toss to -11 deg.
func _idle_head_w() -> float:
	if _action != &"attack" or attack_style != &"tusk_gore":
		return 1.0
	return 1.0 - smoothstep(0.0, 0.07, _action_t) * (1.0 - smoothstep(GORE_LEN - 0.15, GORE_LEN, _action_t))


## Quick short-legged trot: diagonal pairs (FL + BR, FR + BL), the swinging pair lifted, a bounce twice per stride,
## a little roll, the head carried low and bobbing.
func _pose_walk(w: float, _rate: float) -> void:
	var ph: float = TAU * _walk_p
	var s: float = sin(ph)
	var c: float = cos(ph)
	var a: float = 30.0 * DEG * w
	rot(P_LEG_FL, Vector3(-a * s, 0, 0))
	rot(P_LEG_BR, Vector3(-a * s * 0.9, 0, 0))
	rot(P_LEG_FR, Vector3(a * s, 0, 0))
	rot(P_LEG_BL, Vector3(a * s * 0.9, 0, 0))
	var lift: float = 0.05 * w
	pos(P_LEG_FL, Vector3(0, lift * maxf(0.0, c), 0))
	pos(P_LEG_BR, Vector3(0, lift * maxf(0.0, c), 0))
	pos(P_LEG_FR, Vector3(0, lift * maxf(0.0, -c), 0))
	pos(P_LEG_BL, Vector3(0, lift * maxf(0.0, -c), 0))
	pos(P_ROOT, Vector3(0, walk_bounce * (0.5 + 0.5 * cos(2.0 * ph)) * w, 0))
	rot(P_ROOT, Vector3(1.5 * DEG * sin(2.0 * ph) * w, 0, 2.5 * DEG * s * w))
	if _action != &"attack":
		rot(P_MOUNT_HEAD, Vector3((8.0 + 5.0 * sin(2.0 * ph + 0.8)) * DEG * w, 3.0 * DEG * s * w, 0))


# ================================================================ attack / cast / dig

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"tusk_gore":
		return super._pose_attack(prev, t)
	pos(P_ROOT, Vector3(0, _trk(t, G_ROOT_Y), _trk(t, G_ROOT_Z)))
	_pitch_root(_trk(t, G_PITCH))
	rot(P_MOUNT_HEAD, Vector3(_trk(t, G_HEAD_X), _trk(t, G_HEAD_Y), _trk(t, G_HEAD_Z)) * DEG)
	var f: float = _trk(t, G_LEG_F) * DEG
	var b: float = _trk(t, G_LEG_B) * DEG
	rot(P_LEG_FL, Vector3(f, 0, 0))
	rot(P_LEG_FR, Vector3(f * 0.8, 0, 0))
	rot(P_LEG_BL, Vector3(b, 0, 0))
	rot(P_LEG_BR, Vector3(b * 0.85, 0, 0))
	if prev < GORE_HIT and t >= GORE_HIT:
		_on_action_event(&"release")
	return t < GORE_LEN


## Any cast id: rears up on the hind legs squealing (head shaking), then stamps down (dust + clods at the fore hooves).
func _pose_cast(_spell: StringName, t: float) -> float:
	_pitch_root(_trk(t, C_PITCH))
	var shake: float = 5.0 * sin(t * 40.0) * (1.0 - smoothstep(0.30, 0.42, t)) * smoothstep(0.05, 0.15, t)
	rot(P_MOUNT_HEAD, Vector3(_trk(t, C_HEAD_X), 0.0, shake) * DEG)
	var f: float = _trk(t, C_LEG_F) * DEG
	var b: float = _trk(t, C_LEG_B) * DEG
	rot(P_LEG_FL, Vector3(f, 0, 0))
	rot(P_LEG_FR, Vector3(f * 0.85, 0, 0))
	rot(P_LEG_BL, Vector3(b, 0, 0))
	rot(P_LEG_BR, Vector3(b, 0, 0))
	if t < _cast_last:
		_cast_last = -1.0   # a new cast
	if _cast_last < CAST_STAMP and t >= CAST_STAMP and _tier < 2:
		_emit(_dust, Vector3(0.0, 0.05, 0.45))
		_emit(_clods, Vector3(0.0, 0.1, 0.5))
	_cast_last = t
	return CAST_LEN


## Pitches the body about the hooves that stay planted (+ nose down about the fore hooves, - rears about the hind).
func _pitch_root(deg: float) -> void:
	var th: float = deg * DEG
	rot(P_ROOT, Vector3(th, 0, 0))
	var zp: float = FRONT_Z if th > 0.0 else HIND_Z
	pos(P_ROOT, Vector3(0, zp * sin(th), 0))


## The dig fidget (2.2 s): snout down, three scoops with the fore hoof pawing, two dirt puffs, a snorting head shake.
func _pose_dig(t: float, prev: float) -> void:
	var low: float = _k3(t, 0.0, 0.3, 1.7, DIG_LEN, 1.0, 1.0)
	var scoop: float = 0.0
	if t > 0.35 and t < 1.55:
		scoop = maxf(0.0, sin((t - 0.35) / 1.2 * TAU * 3.0))
	var shake: float = 0.0
	if t > 1.7 and t < 2.1:
		shake = sin((t - 1.7) * 40.0) * (1.0 - (t - 1.7) / 0.4)
	rot(P_MOUNT_HEAD, Vector3((34.0 * low - 12.0 * scoop * low) * DEG, 0.0, 10.0 * DEG * shake))
	_pitch_root(5.0 * low)
	pos(P_ROOT, Vector3(0, 0, 0.03 * scoop * low))
	var paw: float = 0.0
	if t > 0.4 and t < 1.4:
		paw = sin((t - 0.4) / 1.0 * TAU * 2.0)
	rot(P_LEG_FR, Vector3((-22.0 * maxf(paw, 0.0) + 10.0 * maxf(-paw, 0.0)) * DEG * low, 0, 0))
	pos(P_LEG_FR, Vector3(0, 0.04 * maxf(paw, 0.0) * low, 0))
	for k: float in [0.62, 1.42]:
		if prev < k and t >= k:
			_emit(_dust, Vector3(0.0, 0.04, 1.02))
			_emit(_clods, Vector3(0.0, 0.08, 1.0))


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	var sq: float = _trk(t, D_SQUEAL)
	var buckle: float = _ease_out(clampf((t - 0.10) / 0.22, 0.0, 1.0))
	var fall: float = _ease_in(clampf((t - 0.30) / 0.24, 0.0, 1.0))
	var sink: float = _ease_in(clampf((t - 0.68) / 0.32, 0.0, 1.0))
	rot(P_MOUNT_HEAD, Vector3((-30.0 * sq + 16.0 * fall) * DEG, 0, 0))
	var fl: float = 72.0 * buckle * (1.0 - 0.5 * fall)
	rot(P_LEG_FL, Vector3(fl * DEG, 0, 0))
	rot(P_LEG_FR, Vector3(fl * 0.9 * DEG, 0, 0))
	rot(P_ROOT, Vector3(11.0 * DEG * buckle * (1.0 - fall), 0, 82.0 * DEG * fall))
	pos(P_ROOT, Vector3(0, -0.16 * buckle * (1.0 - fall) + 0.20 * fall - 0.62 * sink, 0))
	if t > DEATH_LAND:
		var kick: float = sin((t - DEATH_LAND) * 30.0) * exp(-(t - DEATH_LAND) * 5.0)
		rot(P_LEG_BL, Vector3(22.0 * DEG * kick, 0, 0))
		rot(P_LEG_BR, Vector3(-18.0 * DEG * kick, 0, 0))
		rot(P_LEG_FL, Vector3(-10.0 * DEG * kick, 0, 0))
	if prev < DEATH_LAND and t >= DEATH_LAND and _tier < 2:
		_emit(_dust, Vector3(-0.55, 0.05, 0.0))
	if _shadow:
		_shadow.transparency = clampf((t - 0.7) / 0.3, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


# ================================================================ per frame extras

func _extra_process(dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		if _action == &"dig":
			if _speed >= 0.3:
				_action = &""
			elif _action_t >= DIG_LEN:
				_action = &""
			else:
				_pose_dig(_action_t, _action_t - dt)
		elif dig_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0:
			_dig_wait -= dt
			if _dig_wait <= 0.0:
				_dig_wait = _next_dig()
				_action = &"dig"
				_action_t = 0.0
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_MOUNT_HEAD, Vector3(-10.0 * k, 8.0 * k, 6.0 * k) * DEG)
	# The quill ridge: raised in a fight, spiking on a hit, flattened on the trot and in death; sways with the gait.
	var target: float = 0.0
	if _dead:
		target = -0.3
	elif _action == &"attack":
		target = 1.0 if _action_t < 0.42 else 0.35
	elif _action == &"cast":
		target = 1.0
	elif _hit_t < HIT_LEN:
		target = 0.8
	elif _action == &"dig":
		target = 0.25
	elif _walk_w > 0.5:
		target = -0.15
	_quill_r = move_toward(_quill_r, target, dt * (9.0 if target > _quill_r else 2.5))
	var roll: float = 3.5 * DEG * sin(TAU * _walk_p) * _walk_w
	_write_quills(_quill_r, roll, false)


func _write_quills(r: float, roll: float, force: bool) -> void:
	if _quills == null:
		return
	var key := Vector2(r, roll)
	if not force and absf(key.x - _quill_w.x) < 0.004 and absf(key.y - _quill_w.y) < 0.002:
		return
	_quill_w = key
	var sc := Vector3(1.0 + 0.22 * r, 1.0 + 0.34 * r, 1.0 - 0.12 * r)
	_quills.transform = Transform3D(Basis(Vector3.BACK, roll) * Basis.from_scale(sc), QUILL_ORIGIN)


func _next_dig() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return dig_every * (0.6 + 0.8 * h)


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

# Body loft stations along the spine: centre (x 0, y, z), half-width, half-height. Hunched: the withers (station 6)
# stand 0.98 m, the rump 0.87, the belly ~0.39 over short legs.
const BODY_C: Array[Vector3] = [Vector3(0, 0.62, -0.83), Vector3(0, 0.62, -0.78), Vector3(0, 0.625, -0.66),
	Vector3(0, 0.63, -0.46), Vector3(0, 0.64, -0.22), Vector3(0, 0.655, 0.0), Vector3(0, 0.68, 0.20),
	Vector3(0, 0.685, 0.36), Vector3(0, 0.67, 0.48), Vector3(0, 0.65, 0.57)]
const BODY_RX: Array[float] = [0.02, 0.17, 0.26, 0.30, 0.315, 0.33, 0.335, 0.315, 0.26, 0.20]
const BODY_RY: Array[float] = [0.02, 0.18, 0.25, 0.28, 0.29, 0.305, 0.32, 0.305, 0.27, 0.22]
# Head loft (the wedge): skull and cheeks -> a long tapering snout, carried low.
const HEAD_C: Array[Vector3] = [Vector3(0, 0.70, 0.42), Vector3(0, 0.695, 0.56), Vector3(0, 0.66, 0.70),
	Vector3(0, 0.605, 0.84), Vector3(0, 0.55, 0.96), Vector3(0, 0.52, 1.04)]
const HEAD_RX: Array[float] = [0.18, 0.205, 0.175, 0.13, 0.10, 0.09]
const HEAD_RY: Array[float] = [0.21, 0.225, 0.19, 0.14, 0.10, 0.088]
const DORSAL := 0.45          # half-angle (rad) of the dark stripe down the spine
const RING := 14              # segments around the lofts


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


static func _ellipsoid(acc: Array, c: Vector3, r: Vector3, radial: int = 10, rings: int = 5,
		rot: Basis = Basis.IDENTITY) -> void:
	_put(acc, sphere(1.0, radial, rings), Transform3D(rot * Basis.from_scale(r), c))


## A (cols+1) x (rows+1) grid of points (row-major) with given normals; each triangle wound so its front (Godot:
## clockwise) faces its normals.
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
				if front.dot(nrm[a] + nrm[b] + nrm[c]) < 0.0:
					var t := b
					b = c
					c = t
				acc[3].append(b0 + a)
				acc[3].append(b0 + b)
				acc[3].append(b0 + c)


## Point of a loft at station i (integer), angle a (0 = top, PI/2 = +x side, PI = belly), radii scaled by `inflate`.
static func _lp(c: Array[Vector3], rx: Array[float], ry: Array[float], i: int, a: float, inflate: float = 1.0) -> Vector3:
	var n := c.size()
	i = clampi(i, 0, n - 1)
	var t := (c[mini(i + 1, n - 1)] - c[maxi(i - 1, 0)]).normalized()
	var up := t.cross(Vector3.RIGHT).normalized()
	return c[i] + Vector3.RIGHT * sin(a) * rx[i] * inflate + up * cos(a) * ry[i] * inflate


## Emits a patch of a loft: stations i0..i1, angles angs[i - i0] (one PackedFloat32Array per station, same length).
## Normals come from the analytic surface, so separate patches (stripe / flank / mud) shade seamlessly.
static func _loft_patch(acc: Array, c: Array[Vector3], rx: Array[float], ry: Array[float], i0: int, i1: int,
		angs: Array[PackedFloat32Array], inflate: float = 1.0) -> void:
	var pts := PackedVector3Array()
	var nrm := PackedVector3Array()
	var cols: int = angs[0].size() - 1
	for i: int in range(i0, i1 + 1):
		var row: PackedFloat32Array = angs[i - i0]
		for k: int in row.size():
			var a: float = row[k]
			var p := _lp(c, rx, ry, i, a, inflate)
			var du := _lp(c, rx, ry, i, a + 0.02, inflate) - _lp(c, rx, ry, i, a - 0.02, inflate)
			var dv := _lp(c, rx, ry, i + 1, a, inflate) - _lp(c, rx, ry, i - 1, a, inflate)
			var nn := du.cross(dv)
			var radial := p - c[i]
			if nn.length_squared() < 1e-10:
				nn = radial
			nn = nn.normalized()
			if nn.dot(radial) < 0.0:
				nn = -nn
			pts.append(p)
			nrm.append(nn)
	_grid(acc, pts, nrm, cols, i1 - i0)


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


## A two-tone quill / bristle: a 5-sided dark frustum (base -> 60 %) and a pale point (tip). `ab` may equal `ad`.
static func _spike(ad: Array, ab: Array, base: Vector3, tip: Vector3, r: float) -> void:
	var d := tip - base
	var ln := d.length()
	var t := d / ln
	var ref := Vector3.RIGHT if absf(t.dot(Vector3.RIGHT)) < 0.8 else Vector3.FORWARD
	var s := t.cross(ref).normalized()
	var u := s.cross(t).normalized()
	var slope := r / ln
	for part: int in 2:
		var p0: Vector3 = base if part == 0 else base + d * 0.56
		var p1: Vector3 = base + d * 0.62 if part == 0 else tip
		var r0: float = r if part == 0 else r * 0.47
		var r1: float = r * 0.42 if part == 0 else 0.0
		var pts := PackedVector3Array()
		var nrm := PackedVector3Array()
		for row: int in 2:
			for k: int in 6:
				var a := TAU * float(k) / 5.0
				var dir := s * cos(a) + u * sin(a)
				pts.append((p0 if row == 0 else p1) + dir * (r0 if row == 0 else r1))
				nrm.append((dir + t * slope).normalized())
		_grid(ad if part == 0 else ab, pts, nrm, 5, 1)


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
	_bb_meshes[key] = am
	return am


## Height of the back (top of the body loft) at z, for the quills.
static func _back_top(z: float) -> float:
	for i: int in BODY_C.size() - 1:
		var a: Vector3 = BODY_C[i]
		var b: Vector3 = BODY_C[i + 1]
		if z >= a.z and z <= b.z:
			var u: float = (z - a.z) / maxf(b.z - a.z, 0.0001)
			return lerpf(a.y + BODY_RY[i], b.y + BODY_RY[i + 1], u)
	return BODY_C[0].y + BODY_RY[0] if z < BODY_C[0].z else BODY_C[BODY_C.size() - 1].y + BODY_RY[BODY_C.size() - 1]


## Body (Mount): hide flanks, dark dorsal stripe, a mud shell over the belly and lower flanks with a scalloped upper
## edge, the thin tail with a tuft.
static func _body_mesh() -> Mesh:
	const KEY := "body_v1"
	if _bb_meshes.has(KEY):
		return _bb_meshes[KEY]
	var hide := _bucket()
	var dark := _bucket()
	var mud := _bucket()
	var n: int = BODY_C.size()
	var flank: Array[PackedFloat32Array] = []
	var stripe: Array[PackedFloat32Array] = []
	for i: int in n:
		flank.append(_even(DORSAL, TAU - DORSAL, RING - 2))
		stripe.append(_even(-DORSAL, DORSAL, 2))
	_loft_patch(hide, BODY_C, BODY_RX, BODY_RY, 0, n - 1, flank)
	_loft_patch(dark, BODY_C, BODY_RX, BODY_RY, 0, n - 1, stripe)
	# Rump cap: a fan closing the loft's back end.
	var cap := PackedVector3Array()
	var cap_n := PackedVector3Array()
	for row: int in 2:
		for k: int in RING + 1:
			var a := TAU * float(k) / float(RING)
			cap.append(_lp(BODY_C, BODY_RX, BODY_RY, 0, a) if row == 0 else BODY_C[0] + Vector3(0, 0, -0.025))
			cap_n.append((Vector3(sin(a), cos(a), 0.0) * 0.4 + Vector3.FORWARD).normalized() if row == 0 \
				else Vector3.FORWARD)   # the rump faces -Z
	_grid(hide, cap, cap_n, RING, 1)
	# Mud: stations 1..8, from the left edge down under the belly to the right edge; the edges wander (scallops),
	# higher over the hindquarters (it sat in the wallow).
	var arcs: Array[PackedFloat32Array] = []
	for i: int in range(1, n - 1):
		var hind: float = 0.16 * (1.0 - smoothstep(2.0, 5.0, float(i)))
		var al: float = PI * 0.55 - hind + 0.14 * sin(float(i) * 1.9 + 0.4)
		var ar: float = TAU - (PI * 0.55 - hind + 0.14 * sin(float(i) * 2.3 + 1.7))
		arcs.append(_even(al, ar, 8))
	_loft_patch(mud, BODY_C, BODY_RX, BODY_RY, 1, n - 2, arcs, 1.035)
	# Tail: a thin dark whip curling down from the rump, a tuft at the end.
	_tube(dark, PackedVector3Array([Vector3(0, 0.71, -0.78), Vector3(0, 0.66, -0.87), Vector3(0.02, 0.56, -0.9),
		Vector3(0.04, 0.47, -0.88)]), PackedFloat32Array([0.03, 0.022, 0.017, 0.012]), 5, Vector3.RIGHT)
	_ellipsoid(dark, Vector3(0.045, 0.45, -0.875), Vector3(0.035, 0.065, 0.035), 6, 3)
	return _commit(KEY, [[hide, _m(&"bristleback_hide")], [dark, _m(&"bristleback_dark")], [mud, _m(&"bristleback_mud")]])


## Head (Mount/Head): the wedge (hide) with a dark crown stripe, flat dark snout disc + nostrils, beady eyes under a
## mean brow, laid-back pointed ears, cheek bristles, a short crest of quills, the big curling tusks.
static func _head_mesh() -> Mesh:
	const KEY := "head_v1"
	if _bb_meshes.has(KEY):
		return _bb_meshes[KEY]
	var hide := _bucket()
	var dark := _bucket()
	var bone := _bucket()
	var eye := _bucket()
	var n: int = HEAD_C.size()
	var flank: Array[PackedFloat32Array] = []
	var stripe: Array[PackedFloat32Array] = []
	for i: int in n:
		flank.append(_even(DORSAL, TAU - DORSAL, RING - 2))
	for i: int in 3:
		stripe.append(_even(-DORSAL, DORSAL, 2))
	_loft_patch(hide, HEAD_C, HEAD_RX, HEAD_RY, 0, n - 1, flank)
	# The dark crown stripe runs from the neck to the brow (stations 0-2); the snout top stays hide.
	_loft_patch(dark, HEAD_C, HEAD_RX, HEAD_RY, 0, 2, stripe)
	var snout: Array[PackedFloat32Array] = []
	for i: int in n - 2:
		snout.append(_even(-DORSAL, DORSAL, 2))
	_loft_patch(hide, HEAD_C, HEAD_RX, HEAD_RY, 2, n - 1, snout)
	# Snout disc (axis z) and nostrils.
	_put(dark, cyl(0.10, 0.105, 0.07, 9), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.52, 1.055)))
	for sx: float in [-1.0, 1.0]:
		_ellipsoid(eye, Vector3(0.042 * sx, 0.525, 1.092), Vector3(0.024, 0.032, 0.014), 5, 2)
		# (the beady eye and the mean brow: the CreatureFaceRig eyes, faces pass 2026-09-28)
		# Ear: a flattened cone laid back and out.
		var ed := Vector3(0.5 * sx, 0.78, -0.40).normalized()
		var eb := Basis(Quaternion(Vector3.UP, ed)) * Basis.from_scale(Vector3(1.0, 1.0, 0.42))
		_put(dark, cyl(0.0, 0.07, 0.21, 6), Transform3D(eb, Vector3(0.13 * sx, 0.87, 0.57) + ed * 0.09))
		# Cheek bristles, raking back and down.
		var jb: Array[Vector3] = [Vector3(0.165 * sx, 0.575, 0.63), Vector3(0.145 * sx, 0.53, 0.72)]
		var jl: Array[float] = [0.16, 0.12]
		for k: int in 2:
			_spike(dark, dark, jb[k], jb[k] + Vector3(0.45 * sx, -0.5, -0.72).normalized() * jl[k], 0.032)
		# Tusk: out of the jaw corner, curling out, up and back.
		_tube(bone, PackedVector3Array([Vector3(0.08 * sx, 0.49, 0.86), Vector3(0.17 * sx, 0.515, 0.935),
			Vector3(0.235 * sx, 0.60, 0.955), Vector3(0.265 * sx, 0.70, 0.905), Vector3(0.25 * sx, 0.775, 0.83)]),
			PackedFloat32Array([0.046, 0.041, 0.033, 0.021, 0.0]), 7, Vector3.FORWARD)
	# Crest: three quills continuing the back ridge over the crown.
	for k: int in 3:
		var z: float = 0.66 - 0.07 * float(k)
		var b := Vector3(0.0, 0.885 + 0.01 * float(k), z)
		_spike(dark, bone, b, b + Vector3(0.0, 0.75, -0.66).normalized() * (0.12 + 0.03 * float(k)), 0.03)
	return _commit(KEY, [[hide, _m(&"bristleback_hide")], [dark, _m(&"bristleback_dark")],
		[bone, _m(&"bristleback_bone")], [eye, palette(&"unit_eye_dark")]])


## One leg (model space): a hide shoulder / ham, a mud-caked shin with a knobbly knee, a split dark hoof.
static func _leg_mesh(front: bool, sx: float) -> Mesh:
	var key := "leg_v1_%s_%s" % [front, sx]
	if _bb_meshes.has(key):
		return _bb_meshes[key]
	var hide := _bucket()
	var mud := _bucket()
	var dark := _bucket()
	var x: float = (0.20 if front else 0.19) * sx
	if front:
		_ellipsoid(hide, Vector3(x, 0.50, 0.31), Vector3(0.125, 0.19, 0.15), 8, 4)
		_tube(mud, PackedVector3Array([Vector3(x, 0.41, 0.32), Vector3(x + 0.005 * sx, 0.22, 0.33),
			Vector3(x, 0.07, 0.345)]), PackedFloat32Array([0.085, 0.068, 0.06]), 8, Vector3.FORWARD)
		_ellipsoid(mud, Vector3(x, 0.26, 0.335), Vector3(0.088, 0.07, 0.088), 6, 3)
	else:
		_ellipsoid(hide, Vector3(x, 0.52, -0.47), Vector3(0.14, 0.21, 0.18), 8, 4)
		_tube(mud, PackedVector3Array([Vector3(x, 0.40, -0.50), Vector3(x, 0.22, -0.56), Vector3(x, 0.07, -0.52)]),
			PackedFloat32Array([0.09, 0.068, 0.06]), 8, Vector3.FORWARD)
		_ellipsoid(mud, Vector3(x, 0.23, -0.555), Vector3(0.08, 0.068, 0.085), 6, 3)
	var hz: float = 0.37 if front else -0.49
	for t: float in [-1.0, 1.0]:
		_ellipsoid(dark, Vector3(x + 0.032 * t, 0.045, hz), Vector3(0.04, 0.045, 0.065), 6, 3)
	return _commit(key, [[hide, _m(&"bristleback_hide")], [mud, _m(&"bristleback_mud")], [dark, _m(&"bristleback_dark")]])


## The quill ridge (keep_separate "Quills", local to QUILL_ORIGIN): a double row of long dark quills with bone tips
## raking back along the spine, tallest over the shoulders, plus short hackles splayed out at the withers.
static func _quill_mesh() -> Mesh:
	const KEY := "quills_v1"
	if _bb_meshes.has(KEY):
		return _bb_meshes[KEY]
	var dark := _bucket()
	var bone := _bucket()
	# Main crest: 13 big quills zig-zagging left / right (a broad V seen from the RTS camera), peak over the withers.
	var count: int = 13
	for k: int in count:
		var z: float = lerpf(0.52, -0.62, float(k) / float(count - 1))
		var bell: float = exp(-pow((z - 0.20) / 0.45, 2.0))
		var side: float = 1.0 if k % 2 == 0 else -1.0
		var ln: float = 0.12 + 0.24 * bell
		var base := Vector3(0.03 * side, _back_top(z) - 0.035, z) - QUILL_ORIGIN
		var dir := Vector3(0.34 * side, 0.68, -0.62).normalized()
		_spike(dark, bone, base, base + dir * ln, 0.036 + 0.026 * bell)
	# Hackles splayed out over the shoulders.
	for j: int in 4:
		var z: float = 0.38 - 0.14 * float(j)
		for side: float in [-1.0, 1.0]:
			var base := Vector3(0.13 * side, _back_top(z) - 0.06, z) - QUILL_ORIGIN
			var dir := Vector3(0.70 * side, 0.55, -0.45).normalized()
			_spike(dark, bone, base, base + dir * (0.21 - 0.025 * float(j)), 0.032)
	return _commit(KEY, [[dark, _m(&"bristleback_dark")], [bone, _m(&"bristleback_bone")]])


## The eyes (faces pass 2026-09-28): small beady black eyes with a catch-light under a mean dark brow ridge that
## scowls harder when it charges. Drawn inside the merged head (CreatureFaceRig host mode: no extra draw instance).
static func face_spec() -> Dictionary:
	return CreatureFaceRig.side_eye_spec(Vector3(0.152, 0.724, 0.73), Vector3(0.80, 0.34, 0.50), 0.034,
		Color(0.41, 0.26, 0.17), Color(0.22, 0.12, 0.06), 0.0, {"palette": {"sclera": Color(0.06, 0.04, 0.03),
		"brow": Color(0.17, 0.12, 0.10)}, "brow": {"w": Vector3(0.008, 0.010, 0.004)},
		"x": {&"neutral": {"brow": [-0.008, -0.002, 0.004]}}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
