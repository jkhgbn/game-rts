extends CharacterModel
## Tusker (map-fill.md 5.5 / 10, task 12.V27): the epic beast of the West Heath lairs, both variants in one scene.
##  A  Ironhide Tusker: a massive boar (~2.3 m to the bristle tips, ~1.85 m at the shoulder hump, ~3.5 m snout to
##     tail: about twice the camp Bristleback in every direction), its back armoured by overlapping IRON-GREY PLATES
##     (collar, shoulder saddle, three back bands, a rump plate, round shoulder shields, a brow helmet), a RUST-RED
##     BRISTLE RIDGE bursting through the plate seams, huge pale CURVED TUSKS sweeping out, up and back, small amber eyes.
##  B  Old Scarback (`set_variant(1)`): the same beast x1.15, darker gunmetal plates, BLACK bristles with silver tips,
##     the RIGHT TUSK BROKEN (jagged stump), a pale scar across the right eye (scarred shut), claw-rake scars on the left
##     flank, a scar on the right haunch, a WAR-ARROW still stuck behind the left shoulder and a snapped stub in the hip.
## Read at 40 m: A = the light steel-grey armoured boar with a rust mohawk and two big pale tusks; B = a bigger, darker
## boar with a black mohawk, one tusk and a pale arrow jutting from its back. Next to the Bristleback (small, russet,
## muddy) the Tusker is the huge grey armoured one.
## Neutral: no team colour (set_team_color is a no-op), 0 lights, glow by emission only (the eyes).
## Motion (procedural, kit rules):
##  - idle: heavy breathing, snuffle bursts, a slow look around; every ~fidget_every s close to the camera a SNORT AND
##    PAW fidget (head low, three scrapes of a fore hoof with dirt kicks, a snorting head shake, bristles half up);
##    `play_fidget()` starts one now;
##  - walk: a heavy trot (diagonal pairs, hooves lifted, a thumping bounce, the head bobbing low), bristles flat;
##  - attack `tusk_gore` (0.8 s, strike 0.12 s = the kit strike frame, damage stays instant): weight back and head
##    down, a lunge +0.42 m with a hooking upward toss of the tusks (dirt + clods), a counter-twist, recovery;
##  - cast `gore_charge` (any id but `bristle_hide` plays it): the head drops, tusks forward, and it GALLOPS (bounding
##    gait, head low, bristles fully up, a dust trail from the hooves) for as long as the unit is being dashed by
##    CreatureAbilities (the model measures its own world motion: charge ends when it stops, else after 0.7 s when it
##    never moved, max 1.8 s), then skids and TOSSES the tusks up (dust + clods burst at the tusks);
##  - `play_cast(&"bristle_hide")` (or `play_bristle()`): the Bristle Hide reaction, a bristle spike + shiver, no pose
##    change (plays over anything); every hit also spikes the bristles;
##  - hit: the kit push + flash, a head jerk, bristles spike;
##  - death (1.0 s): a squeal (head up), the fore knees buckle, it crashes onto its left side (dust), the eyes go
##    dark, the hind legs kick twice, then it sinks away (the unit is freed at death_finished).
## Budget (map-fill.md 10 hero: <= 26 authored meshes, <= 16 draw instances, 0 lights): 11 authored meshes (6 merged
## pivots: body, head, 4 legs; keep_separate Bristles, TuskR, ScarB; the blob) and 3 pre-built emitters (Dust, Clods
## one-shot, Trail loop driven by the charge): 12 draw instances on A (ScarB hidden), 13 on B. 13 own materials
## (materials/), B swaps 3 of them by surface override (tusker_mesh.gd SWAP_B). See tests/test_12_v27.gd.

const TM := preload("res://art/units/neutral/beasts/tusker/tusker_mesh.gd")
const B_SCALE := 1.15
const GORE_LEN := 0.8
const GORE_HIT := 0.12
const CHARGE_MIN := 0.22        # s of gallop at least
const CHARGE_IDLE := 0.7        # gallop length when the model never moved (preview, tests, a blocked dash)
const CHARGE_MAX := 1.8
const CHARGE_FAST := 4.0        # m/s of own world motion that counts as "being dashed"
const CHARGE_PERIOD := 0.3      # s per gallop stride
const TOSS_LEN := 0.6
const TOSS_FX := 0.07           # s after the stop: dust + clods at the tusks
const FIDGET_LEN := 2.0
const DEATH_LAND := 0.58
const DEATH_GLOW_OFF := 0.4
const FRONT_Z := 0.62           # fore / hind hoof z (the root pitches about them)
const HIND_Z := -1.0

# Keyframe tracks [t, value, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth, 1 ease-out,
# 2 ease-in). Degrees / metres. Head x: + = nose down. Legs x: - = hoof forward. Pitch: + = nose down.
static var G_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.1, 1, 0.12, 0.42, 2, 0.3, 0.32, 1, 0.8, 0.0, 0])
static var G_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.12, 0.04, 2, 0.3, -0.01, 1, 0.55, 0.0, 0])
static var G_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, 6.0, 1, 0.12, -5.0, 2, 0.3, -2.0, 1, 0.6, 0.0, 0])
static var G_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, 30.0, 1, 0.12, -30.0, 2, 0.28, -20.0, 1, 0.48, 5.0, 0,
	0.8, 0.0, 0])
static var G_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, -5.0, 0, 0.12, 15.0, 2, 0.3, -8.0, 0, 0.55, 0.0, 0])
static var G_HEAD_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, -11.0, 2, 0.3, 6.0, 0, 0.55, 0.0, 0])
static var G_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.07, -12.0, 1, 0.12, -28.0, 1, 0.32, -8.0, 0, 0.8, 0.0, 0])
static var G_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.07, -8.0, 1, 0.12, 24.0, 1, 0.32, 6.0, 0, 0.8, 0.0, 0])
static var T_HEAD_X := PackedFloat32Array([0.0, 24.0, 0, 0.13, -32.0, 1, 0.3, -14.0, 0, 0.6, 0.0, 0])
static var T_HEAD_Z := PackedFloat32Array([0.0, 0.0, 0, 0.13, 12.0, 1, 0.34, -4.0, 0, 0.6, 0.0, 0])
static var T_PITCH := PackedFloat32Array([0.0, 3.0, 0, 0.1, -7.0, 1, 0.36, 0.0, 0, 0.6, 0.0, 0])
static var T_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.1, 0.16, 1, 0.6, 0.0, 0])
static var T_ROOT_Y := PackedFloat32Array([0.0, -0.05, 0, 0.1, -0.08, 1, 0.3, 0.0, 0, 0.6, 0.0, 0])
static var T_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, -26.0, 1, 0.42, 0.0, 0, 0.6, 0.0, 0])
static var T_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.08, 12.0, 1, 0.42, 0.0, 0, 0.6, 0.0, 0])
static var D_SQUEAL := PackedFloat32Array([0.0, 0.0, 0, 0.12, 1.0, 1, 0.24, 1.0, 0, 0.38, 0.0, 0])

## Idle snort-and-paw fidget interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var fidget_every: float = 9.0

static var _swap_mats: Dictionary = {}          # A material -> B material (resolved once)

var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _variant: int = 0
var _variant_applied: int = -1
var _bristles: MeshInstance3D
var _tusk_r: MeshInstance3D
var _scars: MeshInstance3D
var _dust: GPUParticles3D
var _clods: GPUParticles3D
var _trail: GPUParticles3D
var _br_r: float = 0.0                          # bristle raise (-0.3 flat .. 1 fully up)
var _br_w: Vector2 = Vector2(99.0, 99.0)
var _kick: float = 0.0                          # Bristle Hide shiver (1 -> 0)
var _fidget_wait: float = 0.0
var _fidget_last: float = -1.0
var _cast_last: float = -1.0
var _ch_end: float = -1.0                       # cast time the gallop ended (-1 while galloping)
var _ch_fast: bool = false
var _ch_slow: int = 0
var _ch_prev: Vector3 = Vector3.ZERO
var _strikes: int = 0
var _charges: int = 0
var _tosses: int = 0
var _bristle_kicks: int = 0


# ================================================================ public (EpicBeasts, tests, preview)

## 0 = Ironhide Tusker (A), 1 = Old Scarback (B). Safe before _ready (applied then).
func set_variant(v: int) -> void:
	_variant = clampi(v, 0, 1)
	if _ready_done:
		_apply_variant()


func variant() -> int:
	return _variant


## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Tusk-gore strikes played so far (the `release` frame of each attack), for tests.
func strike_count() -> int:
	return _strikes


## Gore charges started / finished with the tusk toss, for tests.
func charge_count() -> int:
	return _charges


func toss_count() -> int:
	return _tosses


## True while the gore-charge gallop plays.
func is_charging() -> bool:
	return _action == &"cast" and _ch_end < 0.0 and not _dead


## The bristle ridge's current raise (-0.3 flat .. 1 fully up).
func bristle_raise() -> float:
	return _br_r


func bristle_kicks() -> int:
	return _bristle_kicks


## Bristle Hide reaction: spikes the bristles with a shiver, over whatever else plays.
func play_bristle() -> void:
	if _dead:
		return
	_kick = 1.0
	_bristle_kicks += 1


## Starts the idle snort-and-paw now (it also plays by itself every ~fidget_every s close to the camera).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0
		_fidget_last = -1.0


## Neutral creature: no team colour.
func set_team_color(_c: Color) -> void:
	pass


func play_cast(spell_id: StringName) -> void:
	if spell_id == &"bristle_hide":
		play_bristle()
		return
	super.play_cast(spell_id)


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh, at: Vector3 = Vector3.ZERO, keep: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, part_name)


func _build_parts() -> void:
	_authored = 0
	var mount: Node3D = $Root/Mount
	_part(mount, TM.body_mesh())
	_part($Root/Mount/Head, TM.head_mesh())
	_face = CreatureFaceRig.attach(self, $Root/Mount/Head, "tusker", face_spec())
	for leg: Node3D in [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]:
		var p := model_origin(leg)
		_part(leg, TM.leg_mesh(p.z > 0.0, signf(p.x)))
	_bristles = _part(mount, TM.bristle_mesh(), TM.BRISTLE_ORIGIN, true, "Bristles")
	_bristles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_tusk_r = _part($Root/Mount/Head, TM.tusk_r_mesh(false), Vector3.ZERO, true, "TuskR")
	_tusk_r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_scars = _part(mount, TM.scar_b_mesh(), Vector3.ZERO, true, "ScarB")
	_scars.visible = false
	_dust = $Fx/Dust
	_clods = $Fx/Clods
	_trail = $Fx/Trail
	ensure_shadow_blob(1.0, Color(0.05, 0.04, 0.03, 0.55))
	_shadow.scale = Vector3(1.35, 1.0, 2.3)
	_shadow.position = Vector3(0.0, 0.02, 0.15)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	# The kit flashes the merged Chest / Head / ArmR on hits; a quadruped has none: add the body, head, legs and the
	# separate parts.
	for i: int in [P_MOUNT, P_MOUNT_HEAD, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
		if m and i == P_MOUNT_HEAD:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for g: GeometryInstance3D in [_bristles, _tusk_r, _scars]:
		if g and not _flash_hit_targets.has(g):
			_flash_hit_targets.append(g)
	# The trail is driven by the charge, not by the kit's distance toggle of looping emitters.
	if _trail:
		_loop_fx.erase(_trail)
		_trail.emitting = false
	_fidget_wait = _next_fidget() * 0.6
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))
	_write_bristles(0.0, 0.0, true)
	_apply_variant()


## Size, the right tusk (whole / broken + eye scar), the B scars and arrow, and the B material swaps.
func _apply_variant() -> void:
	if _variant_applied == _variant:
		return
	_variant_applied = _variant
	var b: bool = _variant == 1
	var s: float = B_SCALE if b else 1.0
	scale = Vector3(s, s, s)
	if _tusk_r:
		_tusk_r.mesh = TM.tusk_r_mesh(b)
	if _scars:
		_scars.visible = b
	if _swap_mats.is_empty():
		for k: String in TM.SWAP_B:
			_swap_mats[TM.mat(k)] = TM.mat(String(TM.SWAP_B[k]))
	for g: Node in find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi == _shadow:
			continue
		for i: int in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(i)
			mi.set_surface_override_material(i, _swap_mats.get(base) if b and _swap_mats.has(base) else null)
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"ao_height", body_height * s)


# ================================================================ hooks

func play_hit() -> void:
	var before := _hit_t
	super.play_hit()
	if _hit_t == 0.0 and before != 0.0:
		_kick = maxf(_kick, 0.6)
		if _tier == 0 and _clods:
			_emit(_clods, Vector3(0.0, 1.2, 0.1), 0.5)


func _on_action_event(ev: StringName) -> void:
	if ev == &"release" and _action == &"attack":
		_strikes += 1
		if _tier < 2:
			_emit(_dust, Vector3(0.0, 0.08, 2.0))
			_emit(_clods, Vector3(0.0, 0.7, 2.0))
	elif ev == &"cast_start":
		_cast_last = -1.0
		_ch_end = -1.0
		_ch_fast = false
		_ch_slow = 0
		_ch_prev = global_position if is_inside_tree() else Vector3.ZERO
		if _cast_id != &"bristle_hide":
			_charges += 1
	elif ev == &"cast_end":
		_set_trail(false)


func _on_revive() -> void:
	if _face:
		_face.reset()
	_br_r = 0.0
	_kick = 0.0
	_cast_last = -1.0
	_ch_end = -1.0
	_set_trail(false)
	_write_bristles(0.0, 0.0, true)


## Restarts a pre-built one-shot emitter at a model-space point (the emitters live under Fx, which never moves).
func _emit(p: GPUParticles3D, at: Vector3, ratio: float = 1.0) -> void:
	if p == null:
		return
	p.position = at
	p.amount_ratio = ratio
	p.restart()


func _set_trail(on: bool) -> void:
	if _trail and _trail.emitting != on:
		_trail.emitting = on


# ================================================================ idle / walk

func _idle_head(ph: float) -> Vector3:
	# Snuffle bursts (nose dips and twitches) between slow looks around.
	var burst: float = smoothstep(0.4, 0.85, sin(ph * 0.45 + _phase_off * 3.0))
	var x: float = 4.0 + 2.5 * sin(ph) + burst * (6.0 + 2.5 * sin(_t * 22.0))
	var y: float = 9.0 * sin(ph * 0.33 + 0.6) * (1.0 - 0.6 * burst)
	return Vector3(x, y, 0.0) * DEG


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.014 * sin(ph), 0))
	_write_rot(P_MOUNT_HEAD, _rest_rot[P_MOUNT_HEAD] + _idle_head(ph))


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	pos(P_ROOT, Vector3(0, 0.014 * sin(ph) * w, 0))
	rot(P_MOUNT_HEAD, _idle_head(ph) * w)


## Heavy trot: diagonal pairs (FL + BR, FR + BL), the swinging pair lifted, a thumping bounce twice per stride, a
## little roll, the head carried low and bobbing. Off while the gore-charge gallop owns the legs.
func _pose_walk(w: float, _rate: float) -> void:
	if is_charging():
		return
	var ph: float = TAU * _walk_p
	var s: float = sin(ph)
	var c: float = cos(ph)
	var a: float = 26.0 * DEG * w
	rot(P_LEG_FL, Vector3(-a * s, 0, 0))
	rot(P_LEG_BR, Vector3(-a * s * 0.9, 0, 0))
	rot(P_LEG_FR, Vector3(a * s, 0, 0))
	rot(P_LEG_BL, Vector3(a * s * 0.9, 0, 0))
	var lift: float = 0.07 * w
	pos(P_LEG_FL, Vector3(0, lift * maxf(0.0, c), 0))
	pos(P_LEG_BR, Vector3(0, lift * maxf(0.0, c), 0))
	pos(P_LEG_FR, Vector3(0, lift * maxf(0.0, -c), 0))
	pos(P_LEG_BL, Vector3(0, lift * maxf(0.0, -c), 0))
	pos(P_ROOT, Vector3(0, walk_bounce * (0.5 + 0.5 * cos(2.0 * ph)) * w, 0))
	rot(P_ROOT, Vector3(1.2 * DEG * sin(2.0 * ph) * w, 0, 2.0 * DEG * s * w))
	if _action != &"attack":
		rot(P_MOUNT_HEAD, Vector3((7.0 + 4.0 * sin(2.0 * ph + 0.8)) * DEG * w, 2.5 * DEG * s * w, 0))


## Pitches the body about the hooves that stay planted (+ nose down about the fore hooves, - rears about the hind).
func _pitch_root(deg: float) -> void:
	var th: float = deg * DEG
	rot(P_ROOT, Vector3(th, 0, 0))
	var zp: float = FRONT_Z if th > 0.0 else HIND_Z
	pos(P_ROOT, Vector3(0, zp * sin(th), 0))


# ================================================================ attack / cast / fidget

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


## Gore Charge (any cast id): gallop while the unit is being dashed, then skid and toss the tusks. The length is open
## while galloping (the kit keeps the cast running) and closes at the stop + TOSS_LEN.
func _pose_cast(_spell: StringName, t: float) -> float:
	var dt: float = t - maxf(_cast_last, 0.0)
	var gp: Vector3 = global_position if is_inside_tree() else Vector3.ZERO
	if _ch_end < 0.0:
		if dt > 0.0 and _cast_last >= 0.0:
			var v: float = Vector2(gp.x - _ch_prev.x, gp.z - _ch_prev.z).length() / dt
			if v > CHARGE_FAST:
				_ch_fast = true
				_ch_slow = 0
			elif _ch_fast:
				_ch_slow += 1
		if t >= CHARGE_MIN and ((_ch_fast and _ch_slow >= 2) or (not _ch_fast and t >= CHARGE_IDLE) or t >= CHARGE_MAX):
			_ch_end = t
	_ch_prev = gp
	var prev: float = _cast_last
	_cast_last = t
	if _ch_end < 0.0:
		_pose_gallop(t)
		_set_trail(_tier < 2)
		return t + 1.0
	_set_trail(false)
	var u: float = t - _ch_end
	var pu: float = prev - _ch_end
	_pose_toss(u)
	if pu < TOSS_FX and u >= TOSS_FX:
		_tosses += 1
		if _tier < 2:
			_emit(_dust, Vector3(0.0, 0.08, 1.9))
			_emit(_clods, Vector3(0.0, 0.8, 2.0))
	return _ch_end + TOSS_LEN


## The charge: a bounding gallop (fore pair and hind pair swinging together, opposite), the body rocking and bouncing,
## the head low with the tusks levelled forward.
func _pose_gallop(t: float) -> void:
	var k: float = smoothstep(0.0, 0.1, t)
	var ph: float = TAU * t / CHARGE_PERIOD
	var s: float = sin(ph)
	var c: float = cos(ph)
	rot(P_LEG_FL, Vector3(-38.0 * s * DEG * k, 0, 0))
	rot(P_LEG_FR, Vector3(-38.0 * sin(ph - 0.35) * DEG * k, 0, 0))
	rot(P_LEG_BL, Vector3(34.0 * s * DEG * k, 0, 0))
	rot(P_LEG_BR, Vector3(34.0 * sin(ph - 0.35) * DEG * k, 0, 0))
	pos(P_LEG_FL, Vector3(0, 0.09 * maxf(0.0, c) * k, 0))
	pos(P_LEG_FR, Vector3(0, 0.09 * maxf(0.0, cos(ph - 0.35)) * k, 0))
	pos(P_LEG_BL, Vector3(0, 0.08 * maxf(0.0, -c) * k, 0))
	pos(P_LEG_BR, Vector3(0, 0.08 * maxf(0.0, -cos(ph - 0.35)) * k, 0))
	_pitch_root((3.0 + 4.0 * sin(ph + 0.8)) * k)
	pos(P_ROOT, Vector3(0, (0.08 * (0.5 + 0.5 * cos(2.0 * ph)) - 0.05) * k, 0.06 * k))
	rot(P_MOUNT_HEAD, Vector3((24.0 + 4.0 * sin(ph + 1.4)) * DEG * k, 0, 2.5 * DEG * s * k))


## The stop: skid with the fore legs braced, rear back, then a big hooking toss of the tusks and recovery.
func _pose_toss(u: float) -> void:
	rot(P_MOUNT_HEAD, Vector3(_trk(u, T_HEAD_X), 0.0, _trk(u, T_HEAD_Z)) * DEG)
	_pitch_root(_trk(u, T_PITCH))
	pos(P_ROOT, Vector3(0, _trk(u, T_ROOT_Y), _trk(u, T_ROOT_Z)))
	var f: float = _trk(u, T_LEG_F) * DEG
	var b: float = _trk(u, T_LEG_B) * DEG
	rot(P_LEG_FL, Vector3(f, 0, 0))
	rot(P_LEG_FR, Vector3(f * 0.85, 0, 0))
	rot(P_LEG_BL, Vector3(b, 0, 0))
	rot(P_LEG_BR, Vector3(b * 0.9, 0, 0))


## The snort and paw (2.0 s): head low, three scrapes of the right fore hoof (dirt kicks), then a snorting head shake.
func _pose_fidget(t: float) -> void:
	var low: float = _k3(t, 0.0, 0.3, 1.55, FIDGET_LEN, 1.0, 1.0)
	var scrape: float = 0.0
	if t > 0.35 and t < 1.45:
		scrape = sin((t - 0.35) / 1.1 * TAU * 3.0)
	var shake: float = 0.0
	if t > 1.55 and t < 1.95:
		shake = sin((t - 1.55) * 38.0) * (1.0 - (t - 1.55) / 0.4)
	rot(P_MOUNT_HEAD, Vector3(22.0 * low * DEG, 0.0, 12.0 * DEG * shake))
	_pitch_root(4.0 * low)
	rot(P_LEG_FR, Vector3((-24.0 * maxf(scrape, 0.0) + 14.0 * maxf(-scrape, 0.0)) * DEG * low, 0, 0))
	pos(P_LEG_FR, Vector3(0, 0.06 * maxf(scrape, 0.0) * low, 0))
	for kt: float in [0.62, 0.99, 1.36]:
		if _fidget_last < kt and t >= kt and _tier < 2:
			_emit(_dust, Vector3(0.42, 0.05, 0.95), 0.6)
			_emit(_clods, Vector3(0.42, 0.1, 0.9), 0.5)
	if _fidget_last < 1.6 and t >= 1.6 and _tier < 2:
		_emit(_dust, Vector3(0.0, 0.5, 2.25), 0.5)
	_fidget_last = t


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	if prev <= 0.0:
		_set_trail(false)
	var sq: float = _trk(t, D_SQUEAL)
	var buckle: float = _ease_out(clampf((t - 0.10) / 0.24, 0.0, 1.0))
	var fall: float = _ease_in(clampf((t - 0.32) / 0.26, 0.0, 1.0))
	var sink: float = _ease_in(clampf((t - 0.72) / 0.28, 0.0, 1.0))
	rot(P_MOUNT_HEAD, Vector3((-28.0 * sq + 14.0 * fall) * DEG, 0, 0))
	var fl: float = 70.0 * buckle * (1.0 - 0.5 * fall)
	rot(P_LEG_FL, Vector3(fl * DEG, 0, 0))
	rot(P_LEG_FR, Vector3(fl * 0.9 * DEG, 0, 0))
	rot(P_ROOT, Vector3(10.0 * DEG * buckle * (1.0 - fall), 0, 80.0 * DEG * fall))
	pos(P_ROOT, Vector3(0, -0.3 * buckle * (1.0 - fall) + 0.5 * fall - 1.05 * sink, 0))
	# Once on its side the legs stick out level with the ground (a +z roll swings every hoof toward the sky side).
	for i: int in [P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		rot(i, Vector3(0, 0, 14.0 * DEG * fall))
	if t > DEATH_LAND:
		var kick: float = sin((t - DEATH_LAND) * 30.0) * exp(-(t - DEATH_LAND) * 5.0)
		rot(P_LEG_BL, Vector3(22.0 * DEG * kick, 0, 0))
		rot(P_LEG_BR, Vector3(-18.0 * DEG * kick, 0, 0))
		rot(P_LEG_FL, Vector3(-10.0 * DEG * kick, 0, 0))
	if t >= DEATH_GLOW_OFF:
		_glows_dead()
	if prev < DEATH_LAND and t >= DEATH_LAND and _tier < 2:
		_emit(_dust, Vector3(-1.1, 0.05, 0.1))
		_emit(_clods, Vector3(-1.0, 0.2, 0.4), 0.6)
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
		if _action == &"fidget":
			if _speed >= 0.3 or _action_t >= FIDGET_LEN:
				_action = &""
			else:
				_pose_fidget(_action_t)   # the kit ticks _action_t for any action
		elif fidget_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0:
			_fidget_wait -= dt
			if _fidget_wait <= 0.0:
				_fidget_wait = _next_fidget()
				play_fidget()
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_MOUNT_HEAD, Vector3(-10.0 * k, 7.0 * k, 5.0 * k) * DEG)
	# The hoof-dust trail only while galloping (an attack or death can cut the charge short).
	_set_trail(is_charging() and _tier < 2)
	# The bristle ridge: fully up in a charge / cast and the gore, spiking on a hit or a Bristle Hide reflect, half up
	# while pawing, flattened on the trot and in death; sways with the gait, shivers on a reflect.
	var target: float = 0.0
	if _dead:
		target = -0.3
	elif _action == &"cast":
		target = 1.0
	elif _action == &"attack":
		target = 1.0 if _action_t < 0.45 else 0.35
	elif _hit_t < HIT_LEN:
		target = 0.8
	elif _action == &"fidget":
		target = 0.4
	elif _walk_w > 0.5:
		target = -0.12
	if _kick > 0.0:
		target = maxf(target, _kick)
	_br_r = move_toward(_br_r, target, dt * (9.0 if target > _br_r else 2.2))
	var roll: float = 3.0 * DEG * sin(TAU * _walk_p) * _walk_w + 5.0 * DEG * sin(_t * 55.0) * _kick
	_kick = move_toward(_kick, 0.0, dt * 2.2)
	_write_bristles(_br_r, roll, false)


func _write_bristles(r: float, roll: float, force: bool) -> void:
	if _bristles == null:
		return
	var key := Vector2(r, roll)
	if not force and absf(key.x - _br_w.x) < 0.004 and absf(key.y - _br_w.y) < 0.002:
		return
	_br_w = key
	var sc := Vector3(1.0 + 0.2 * r, 1.0 + 0.32 * r, 1.0 - 0.1 * r)
	_bristles.transform = Transform3D(Basis(Vector3.BACK, roll) * Basis.from_scale(sc), TM.BRISTLE_ORIGIN)


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


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


## The eyes (faces pass 2026-09-28): small mean amber glowing eyes (the old glow beads) on the dark sockets under the
## helmet rim, a dark brow line under the rim that carries the expression (the B tusker's right eye stays under its
## scar lid). Drawn inside the merged head (CreatureFaceRig host mode: no extra draw instance).
static func face_spec() -> Dictionary:
	var ep := TM.head_point(1.33, 1.02, 1.0)
	var out := Vector3(0.85, 0.20, 0.48).normalized()
	return CreatureFaceRig.side_eye_spec(ep + out * 0.08, out, 0.056, Color(0.25, 0.22, 0.21), Color(1.0, 0.66, 0.18), 0.9,
		{"palette": {"sclera": Color(0.10, 0.06, 0.04), "brow": Color(0.10, 0.08, 0.08)}, "eye": {"pupil": 0.4},
		"brow": {"w": Vector3(0.010, 0.012, 0.005)}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
