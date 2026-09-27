extends FlyerModel
## Roc, epic beast (map-fill.md 5.5 / 10 row 12.V28; task 12.V28). Both variants in one scene:
##   A Stormcrest: a huge storm-blue bird of prey, pale belly / underwing / throat, a crest of five pale plumes, a gold
##     hooked beak and talons, banded tail, gold eyes (faint glow);
##   B Duskwing (`set_variant(1)`): near-black plumage with a violet sheen, bone-tipped dark beak, RED glowing eyes.
## The Roc is a ground unit in gameplay (walks the navmesh); the model GLIDES LOW: the body flies `fly_height` 2.5 m above
## the model origin (the unit's ground point), the kit ground blob stays on the ground under it (smaller and fainter
## while it climbs in the Updraft). Rig: flyer_model.gd (Root > Body > Neck1 > Neck2 > Head > Jaw, WingX > WingX2,
## Tail1, LegFL / LegFR = the two talons; the dragon's Tail2 / Tail3 / hind legs are absent and skipped).
## Hooks (all safe before _ready): the FlyerModel kit set (set_moving, play_attack, play_cast, play_hit, play_death +
## death_finished, play_level_up, set_veterancy, set_carrying, play_mine, set_status, revive, set_team_color = no-op:
## neutral) + `set_variant(v: int)` / `get_variant()`.
## Motion (procedural, one _process, no Tween / AnimationPlayer; distance tiers of the rig):
##  - idle: hangs in the air: a few slow deep beats, then a 1.6-2.6 s hover-glide on spread wings (nose up, tail
##    fanned down, talons dangling, the head looking around);
##  - moving: glides on spread wings with slight dihedral between short bursts of beats, banks into turns (roll, head
##    into the turn, tail twists), talons tucked back under the tail;
##  - attack `talon_rake` (0.8 s, strike STRIKE_T = 0.16 s, damage stays instant): wings flare up, drops 0.55 m and
##    lunges, throws the talons forward and rakes, then climbs back;
##  - cast `gale_swoop` (1.25 s): a beat up (+0.75 m), a steep swept-wing dive to ~1.4 m, the wings flare and SLAM down
##    at SWOOP_IMPACT 0.5 s (the gale, talons forward, feathers burst), then two beats back up;
##  - cast `shrieking_dive` (1.25 s, the Duskwing's): the same dive with the neck stretched, the beak wide open and the
##    head shaking in a shriek, the red eyes flaring (x2.6);
##  - cast `updraft` (0.9 s launch): two huge beats, feathers burst at UPDRAFT_BURST, then it climbs +2.8 m and holds
##    there for UPDRAFT_HOLD 4 s (flapping hard while climbing) or while `set_status(&"shroud", true)`, then glides
##    back down;
##  - hit: kit flash + a jolt, wings flinch up, head recoils;
##  - death (ROC_DEATH_LEN 1.8 s < Unit.DEATH_FALLBACK_TIME): a screech with the wings thrown up, it tumbles out of
##    the air (roll + nose down), crashes at CRASH_AT (squash, feather burst, `crashed`), lies breast-down with the
##    wings splayed on the ground, the eyes go dark, then it sinks; death_finished at the end.
## Budget (map-fill.md 10 hero: <= 26 meshes, <= 16 draw instances, 0 lights): 12 pivot meshes + the blob = 13 authored
## meshes, 14 draw instances with the feather burst (one-shot GPUParticles3D); 6 materials (materials/: A / B x feather,
## horn, eye) + the kit blob. Shadows: body, neck, head, wings, tail (the big parts); legs / jaw / neck2 off.
## See tests/test_12_v28.gd, previews tools/roc_preview.tscn.

const RM := preload("res://art/units/neutral/beasts/roc/roc_mesh.gd")
const ATTACK_LEN := 0.8
const STRIKE_T := 0.16
const SWOOP_LEN := 1.25
const SWOOP_IMPACT := 0.5
const UPDRAFT_LEN := 0.9
const UPDRAFT_BURST := 0.34
const UPDRAFT_HOLD := 4.0
const UPDRAFT_RISE := 2.8
const ROC_DEATH_LEN := 1.8
const CRASH_AT := 0.78
## Body centre height of the corpse (model), breast-down on the ground.
const CORPSE_Y := 0.5
const CAST_IDS: Array[StringName] = [&"gale_swoop", &"shrieking_dive", &"updraft"]
const MAT_A: Array[String] = ["roc_storm_feather", "roc_storm_horn", "roc_storm_eye"]
const MAT_B: Array[String] = ["roc_dusk_feather", "roc_dusk_horn", "roc_dusk_eye"]
const BLOB_SIZE := Vector2(3.6, 2.8)

# Tracks: pairs [t, value, t, value ...], smoothstep between keys (degrees / metres).
static var K_ATK_Y := PackedFloat32Array([0.0, 0.0, 0.08, 0.12, 0.16, -0.55, 0.3, -0.45, 0.52, -0.12, 0.8, 0.0])
static var K_ATK_Z := PackedFloat32Array([0.0, 0.0, 0.08, -0.12, 0.16, 0.42, 0.3, 0.34, 0.52, 0.08, 0.8, 0.0])
static var K_ATK_PITCH := PackedFloat32Array([0.0, 0.0, 0.08, -10.0, 0.16, -26.0, 0.3, -16.0, 0.52, -4.0, 0.8, 0.0])
static var K_ATK_WING := PackedFloat32Array([0.0, 0.0, 0.08, 50.0, 0.16, 40.0, 0.3, -28.0, 0.52, 8.0, 0.8, 0.0])
static var K_ATK_HAND := PackedFloat32Array([0.0, 0.0, 0.08, 12.0, 0.16, -8.0, 0.3, -14.0, 0.52, 4.0, 0.8, 0.0])
static var K_ATK_LEG := PackedFloat32Array([0.0, 0.0, 0.08, -40.0, 0.16, -98.0, 0.3, -88.0, 0.52, -36.0, 0.8, 0.0])
static var K_ATK_NECK := PackedFloat32Array([0.0, 0.0, 0.08, -10.0, 0.16, 14.0, 0.3, 8.0, 0.52, 0.0, 0.8, 0.0])
static var K_ATK_JAW := PackedFloat32Array([0.0, 0.0, 0.1, 20.0, 0.16, 32.0, 0.34, 10.0, 0.5, 0.0])
static var K_ATK_TAIL := PackedFloat32Array([0.0, 0.0, 0.08, -10.0, 0.16, -24.0, 0.3, -14.0, 0.52, -4.0, 0.8, 0.0])
static var K_ATK_BEAT := PackedFloat32Array([0.0, 1.0, 0.06, 0.1, 0.6, 0.15, 0.8, 1.0])

static var K_SW_Y := PackedFloat32Array([0.0, 0.0, 0.14, 0.75, 0.4, -0.95, 0.5, -1.05, 0.58, -0.9, 0.8, 0.15, 1.0, 0.08,
	1.25, 0.0])
static var K_SW_Z := PackedFloat32Array([0.0, 0.0, 0.14, -0.25, 0.4, 0.35, 0.5, 0.45, 0.58, 0.35, 0.8, 0.05, 1.25, 0.0])
static var K_SW_PITCH := PackedFloat32Array([0.0, 0.0, 0.14, -18.0, 0.4, 26.0, 0.5, -24.0, 0.58, -30.0, 0.8, -8.0,
	1.0, -3.0, 1.25, 0.0])
static var K_SW_WING := PackedFloat32Array([0.0, 0.0, 0.14, 72.0, 0.4, 18.0, 0.49, 62.0, 0.58, -48.0, 0.8, 38.0,
	1.0, -10.0, 1.25, 0.0])
static var K_SW_HAND := PackedFloat32Array([0.0, 0.0, 0.14, 16.0, 0.4, -30.0, 0.49, 14.0, 0.58, -22.0, 0.8, 12.0,
	1.0, -4.0, 1.25, 0.0])
static var K_SW_SWEEP := PackedFloat32Array([0.0, 0.0, 0.14, 0.0, 0.4, 34.0, 0.49, 6.0, 0.58, -6.0, 0.8, 0.0])
static var K_SW_HSWEEP := PackedFloat32Array([0.0, 0.0, 0.14, 6.0, 0.4, 30.0, 0.49, 0.0])
static var K_SW_LEG := PackedFloat32Array([0.0, 0.0, 0.14, -10.0, 0.4, 20.0, 0.5, -96.0, 0.58, -102.0, 0.8, -40.0,
	1.0, -10.0, 1.25, 0.0])
static var K_SW_TAIL := PackedFloat32Array([0.0, 0.0, 0.14, -12.0, 0.4, 10.0, 0.5, -26.0, 0.58, -28.0, 0.8, -6.0,
	1.0, 0.0])
static var K_SW_NECK := PackedFloat32Array([0.0, 0.0, 0.14, -8.0, 0.4, 10.0, 0.5, 4.0, 0.58, 0.0])
static var K_SW_JAW := PackedFloat32Array([0.0, 0.0, 0.14, 6.0, 0.4, 4.0, 0.5, 26.0, 0.58, 18.0, 0.8, 0.0])
static var K_SW_FLARE := PackedFloat32Array([0.0, 0.0, 0.4, 0.2, 0.5, 0.6, 0.58, 0.3, 0.8, 0.0])
static var K_SH_NECK := PackedFloat32Array([0.0, 0.0, 0.14, -12.0, 0.4, 22.0, 0.5, 10.0, 0.58, 6.0, 0.8, 0.0])
static var K_SH_JAW := PackedFloat32Array([0.0, 0.0, 0.14, 10.0, 0.3, 42.0, 0.5, 46.0, 0.62, 40.0, 0.82, 10.0,
	1.0, 0.0])
static var K_SH_FLARE := PackedFloat32Array([0.0, 0.0, 0.14, 0.4, 0.4, 1.6, 0.5, 1.8, 0.62, 1.4, 0.82, 0.4, 1.0, 0.0])
static var K_SW_BEAT := PackedFloat32Array([0.0, 1.0, 0.06, 0.1, 1.0, 0.1, 1.25, 1.0])

static var K_UP_Y := PackedFloat32Array([0.0, 0.0, 0.18, -0.3, 0.34, 0.25, 0.5, 0.3, 0.7, 0.15, 0.9, 0.0])
static var K_UP_PITCH := PackedFloat32Array([0.0, 0.0, 0.18, -8.0, 0.34, -28.0, 0.5, -20.0, 0.7, -12.0, 0.9, 0.0])
static var K_UP_WING := PackedFloat32Array([0.0, 0.0, 0.18, 80.0, 0.34, -55.0, 0.52, 60.0, 0.7, -35.0, 0.9, 0.0])
static var K_UP_HAND := PackedFloat32Array([0.0, 0.0, 0.18, 20.0, 0.34, -18.0, 0.52, 16.0, 0.7, -14.0, 0.9, 0.0])
static var K_UP_LEG := PackedFloat32Array([0.0, 0.0, 0.18, -30.0, 0.34, -60.0, 0.5, -50.0, 0.7, -30.0, 0.9, 0.0])
static var K_UP_TAIL := PackedFloat32Array([0.0, 0.0, 0.18, -20.0, 0.34, -28.0, 0.5, -20.0, 0.7, -10.0, 0.9, 0.0])
static var K_UP_NECK := PackedFloat32Array([0.0, 0.0, 0.18, -14.0, 0.34, -20.0, 0.5, -10.0, 0.7, -4.0, 0.9, 0.0])
static var K_UP_JAW := PackedFloat32Array([0.0, 0.0, 0.18, 20.0, 0.34, 36.0, 0.5, 20.0, 0.7, 6.0, 0.9, 0.0])
static var K_UP_FLARE := PackedFloat32Array([0.0, 0.0, 0.18, 0.5, 0.34, 1.0, 0.5, 0.6, 0.7, 0.2, 0.9, 0.0])
static var K_UP_BEAT := PackedFloat32Array([0.0, 1.0, 0.06, 0.1, 0.8, 0.1, 0.9, 1.0])

## 0 = Stormcrest (storm-blue), 1 = Duskwing (near-black, violet sheen, red eyes). Change it with set_variant().
@export_range(0, 1) var variant: int = 0:
	set(v):
		variant = clampi(v, 0, 1)
		if _ready_done:
			_apply_variant()
## Feather burst colours (process materials of Fx/Feathers) per variant.
@export var feathers_a: ParticleProcessMaterial
@export var feathers_b: ParticleProcessMaterial

var _authored: int = 0
var _parts: Array[MeshInstance3D] = []
var _head_gi: GeometryInstance3D
var _feathers: GPUParticles3D
var _cast_id: StringName = &""
var _beat_mult: float = 1.0
var _alt: float = 0.0                  # extra altitude (Updraft), m
var _alt_hold: float = 0.0             # s left at the Updraft altitude
var _shroud: bool = false
var _death_alt: float = 0.0
var _strikes: int = 0
var _swoops: int = 0
var _updrafts: int = 0
var _bursts: int = 0


# ================================================================ public (tests, preview, gameplay)

func set_variant(v: int) -> void:
	variant = v


func get_variant() -> int:
	return variant


## Authored MeshInstance3D count (pivot meshes + the blob), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Talon rakes that reached their strike frame.
func strike_count() -> int:
	return _strikes


## Gale Swoops / Shrieking Dives that reached their impact frame.
func swoop_count() -> int:
	return _swoops


func updraft_count() -> int:
	return _updrafts


## Feather bursts played (swoop impact, updraft launch, crash).
func burst_count() -> int:
	return _bursts


## Extra altitude above the glide height (m, the Updraft climb).
func altitude() -> float:
	return _alt


## Height of the body centre above the model origin right now (m).
func body_altitude() -> float:
	var b: Node3D = _piv[P_BODY] if _piv.size() > P_BODY else null
	return model_origin(b).y if b else fly_height


## glow_boost last written on the eyes (0 once dead).
func eye_glow() -> float:
	return float(_glow_written.get(_head_gi, -1.0))


## The beak tip in world space (VFX: the shriek ring).
func get_beak_point() -> Vector3:
	if _mouth and _mouth.is_inside_tree():
		return _mouth.global_position
	return global_transform * Vector3(0.0, fly_height + 0.4, 1.7)


## Neutral beast: no team colour.
func set_team_color(_c: Color) -> void:
	pass


func play_attack() -> void:
	if _dead:
		return
	_action = &"attack"
	_action_t = 0.0
	_on_action_event(&"attack_start")


## `gale_swoop`, `shrieking_dive` or `updraft`; any other id plays the variant's dive.
func play_cast(spell_id: StringName) -> void:
	if _dead:
		return
	_cast_id = spell_id if spell_id in CAST_IDS else (&"shrieking_dive" if variant == 1 else &"gale_swoop")
	_action = &"cast"
	_action_t = 0.0
	_on_action_event(&"cast_start")


func play_death() -> void:
	_death_alt = _alt
	super.play_death()


## shroud (the Updraft's) -> it stays high while shrouded (true); haste -> brighter eyes (true); frozen -> false.
func set_status(id: StringName, on: bool) -> bool:
	if id == &"shroud":
		_shroud = on
		if not on:
			_alt_hold = 0.0
		return true
	return super.set_status(id, on)


# ================================================================ build

func _build_parts() -> void:
	_authored = 0
	_parts.clear()
	for side: int in 2:
		var sx := -1.0 if side == 0 else 1.0
		wing_axis[side] = (RM.mx(RM.ROOT_TRAIL, sx) - RM.mx(RM.SHOULDER, sx)).normalized()
		hand_axis[side] = (RM.mx(RM.WRIST_TRAIL, sx) - RM.mx(RM.WRIST, sx)).normalized()
	_add(P_BODY, RM.body_mesh(), true, "BodyMesh")
	_add(P_NECK1, RM.neck1_mesh(), true, "Neck1Mesh")
	_add(P_NECK2, RM.neck2_mesh(), false, "Neck2Mesh")
	_head_gi = _add(P_HEAD, RM.head_mesh(), true, "HeadMesh")
	_add(P_JAW, RM.jaw_mesh(), false, "JawMesh")
	_add(P_WING_L, RM.wing_arm_mesh(-1.0), true, "WingLMesh")
	_add(P_WING_L2, RM.wing_hand_mesh(-1.0), true, "WingL2Mesh")
	_add(P_WING_R, RM.wing_arm_mesh(1.0), true, "WingRMesh")
	_add(P_WING_R2, RM.wing_hand_mesh(1.0), true, "WingR2Mesh")
	_add(P_TAIL1, RM.tail_mesh(), true, "Tail1Mesh")
	_add(P_LEG_FL, RM.leg_mesh(-1.0), false, "LegFLMesh")
	_add(P_LEG_FR, RM.leg_mesh(1.0), false, "LegFRMesh")
	var beak := Node3D.new()
	beak.name = "Beak"
	add_pivot_node(P_HEAD, beak, RM.BEAK_TIP)
	_mouth = beak
	ensure_shadow_blob(BLOB_SIZE, Color(0.03, 0.035, 0.06, 0.4))
	_authored += 1


func _add(i: int, mesh: Mesh, shadow: bool, nm: String) -> MeshInstance3D:
	var mi := add_pivot_mesh(i, mesh, shadow, nm)
	if mi:
		_authored += 1
		_parts.append(mi)
	return mi


func _after_ready() -> void:
	_feathers = get_node_or_null(^"Fx/Feathers") as GPUParticles3D
	_apply_variant()


## Swaps every A surface for its B twin (surface override, shared .tres, no runtime material) or back.
func _apply_variant() -> void:
	var a: Array[Material] = []
	var b: Array[Material] = []
	for k: int in MAT_A.size():
		a.append(RM.mat(MAT_A[k]))
		b.append(RM.mat(MAT_B[k]))
	for mi: MeshInstance3D in _parts:
		for s: int in mi.mesh.get_surface_count():
			var k := a.find(mi.mesh.surface_get_material(s))
			mi.set_surface_override_material(s, b[k] if variant == 1 and k >= 0 else null)
	if _feathers:
		var pm: ParticleProcessMaterial = feathers_b if variant == 1 else feathers_a
		if pm:
			_feathers.process_material = pm


func _on_revive() -> void:
	_alt = 0.0
	_alt_hold = 0.0
	_shroud = false
	_gliding = false
	_beat_mult = 1.0
	_flap_amp_w = 1.0
	if _shadow:
		_shadow.scale = Vector3(BLOB_SIZE.x, 1.0, BLOB_SIZE.y)


func _flare_weight(pi: int) -> float:
	return 1.0 if pi == P_HEAD else 0.0


# ================================================================ per frame

func _animate(dt: float) -> void:
	for i: int in _pidx:
		_off_pos[i] = Vector3.ZERO
		_off_rot[i] = Vector3.ZERO
		_off_hinge[i] = Basis.IDENTITY
	_root_scale = Vector3.ONE
	_body_scale = Vector3.ONE
	_update_turn(dt)
	if _dead:
		_pose_death(dt)
	else:
		_flare = 0.0
		_beat_mult = 1.0
		if _action == &"attack":
			_beat_mult = _tk(_action_t + dt, K_ATK_BEAT)
		elif _action == &"cast":
			_beat_mult = _tk(_action_t + dt, K_UP_BEAT if _cast_id == &"updraft" else K_SW_BEAT)
		_update_alt(dt)
		_pose_air(dt)
		if _action == &"attack":
			var prev := _action_t
			_action_t += dt
			_pose_strike(prev, _action_t)
			if _action_t >= ATTACK_LEN:
				_action = &""
				_on_action_event(&"attack_end")
		elif _action == &"cast":
			var prev := _action_t
			_action_t += dt
			var ln := _pose_roc_cast(prev, _action_t)
			if _action_t >= ln:
				_action = &""
				_on_action_event(&"cast_end")
		if _hit_t < HIT_LEN:
			_hit_t += dt
			_pose_hit(_hit_t)
	_update_flash(dt)
	_extra_process(dt)
	_apply()
	_apply_glow(false)


func _update_alt(dt: float) -> void:
	if _shroud:
		_alt_hold = maxf(_alt_hold, 0.25)
	if _alt_hold > 0.0:
		_alt_hold -= dt
		_alt = move_toward(_alt, UPDRAFT_RISE, dt * 2.4)
	else:
		_alt = move_toward(_alt, 0.0, dt * 1.4)


## The blob stays on the ground under the bird: smaller and fainter the higher it climbs.
func _extra_process(_dt: float) -> void:
	if _shadow == null or _dead:
		return
	var k := clampf(_alt / UPDRAFT_RISE, 0.0, 1.0)
	_shadow.scale = Vector3(BLOB_SIZE.x * (1.0 - 0.3 * k), 1.0, BLOB_SIZE.y * (1.0 - 0.3 * k))
	_shadow.transparency = 0.45 * k


# ---------------------------------------------------------------- flight

## Idle: a few slow deep beats, then a hover-glide on spread wings (nose up, tail fanned down, talons dangling, the
## head looking around). Moving: glides with a slight dihedral between short bursts of beats, banking into turns.
## Climbing (Updraft): fast strong beats, nose up.
func _pose_air(dt: float) -> void:
	var moving := _speed >= 0.3
	_move_w = move_toward(_move_w, 1.0 if moving else 0.0, dt / 0.8)
	var mw := _move_w * _move_w * (3.0 - 2.0 * _move_w)
	var hw := 1.0 - mw
	var ab := absf(_bank)
	var climbing := _alt_hold > 0.0 and _alt < UPDRAFT_RISE - 0.25
	# --- beat / glide scheduler
	var prev_p := _flap_p
	var period := flap_period * (0.62 if climbing else lerpf(1.0, 0.88, mw))
	if not _frozen_status:
		_flap_p = fmod(_flap_p + dt / maxf(period, 0.2), 1.0)
	var wrapped := _flap_p < prev_p
	var may_glide := _action == &"" and not climbing
	if _gliding:
		_glide_left -= dt
		if _glide_left <= 0.0 or not may_glide:
			_gliding = false
			_flaps_left = 2 + int(fmod(_t * 7.3 + _phase_off * 10.0, 2.0))
	elif wrapped:
		_flaps_left -= 1
		if _flaps_left <= 0 and may_glide:
			_gliding = true
			var r := fmod(_t * 3.1 + _phase_off * 7.0, 1.0)
			_glide_left = lerpf(1.6, 2.6, r) if mw < 0.5 else lerpf(2.4, 3.6, r)
	_flap_amp_w = move_toward(_flap_amp_w, 0.0 if _gliding else 1.0, dt / (0.5 if _gliding else 0.3))
	var aw := _flap_amp_w * _flap_amp_w * (3.0 - 2.0 * _flap_amp_w) * _beat_mult
	var gw := 1.0 - aw
	# --- wing beat: fast downstroke (0 .. 0.42), slower upstroke with the wrist flexed; psi 0 = top, 0.5 = bottom
	var down := 0.42
	var psi := 0.5 * _flap_p / down if _flap_p < down else 0.5 + 0.5 * (_flap_p - down) / (1.0 - down)
	var c := cos(TAU * psi)
	var flex := sin(PI * clampf((psi - 0.5) / 0.5, 0.0, 1.0))
	var amp := lerpf(48.0, 38.0, mw) * (1.25 if climbing else 1.0)
	var mid := lerpf(12.0, 8.0, mw)
	var soar := sin(_t * 1.3 + _phase_off * 6.0)
	var raise := (mid + amp * c) * aw + gw * (7.0 + 2.5 * soar)
	var hand := (-14.0 * sin(TAU * psi - 0.9) - 4.0 - 16.0 * flex) * aw + gw * (4.0 + 2.0 * soar)
	var hsweep := 24.0 * flex * aw
	var sweep := 6.0 * sin(TAU * psi + 0.4) * aw
	for side: int in 2:
		var s := -1.0 if side == 0 else 1.0
		var wi := P_WING_L if side == 0 else P_WING_R
		var hi := P_WING_L2 if side == 0 else P_WING_R2
		var turn_extra := 5.0 * _bank * s
		_wing_raise(side, (raise - turn_extra) * DEG)
		_hand_bend(side, hand * DEG)
		rot(wi, Vector3(0.0, -s * sweep * DEG, 0.0))
		rot(hi, Vector3(0.0, s * hsweep * DEG, 0.0))
	# --- body: bob with the beat, hover nose-up, bank roll, climb pitch; the extra Updraft altitude
	var bob := -lerpf(0.12, 0.07, mw) * c * aw
	var drift := 0.07 * sin(_t * 0.83 + _phase_off * 5.0) * hw + gw * 0.05 * sin(_t * 1.1)
	pos(P_ROOT, Vector3(0.0, fly_height - BAKE_HEIGHT + _alt + bob + drift, 0.0))
	var pitch := lerpf(-9.0, -1.0, mw) + 2.5 * sin(TAU * psi - 0.6) * aw - 4.0 * ab * mw
	if climbing:
		pitch -= 14.0
	var roll := -bank_max_deg * _bank
	rot(P_BODY, Vector3(pitch * DEG, 0.0, roll * DEG))
	# --- neck + head: steady (counter the pitch / bob), looking around while hovering, into turns
	var look_y := hw * (16.0 * sin(_t * 0.41 + _phase_off * 4.0) + 7.0 * sin(_t * 1.03 + 1.3))
	var look_x := hw * 6.0 * sin(_t * 0.57 + 0.7)
	var steady := -0.6 * pitch
	rot(P_NECK1, Vector3((steady * 0.5 + 2.0 * c * aw) * DEG, (0.35 * look_y + 10.0 * _bank) * DEG, 0.0))
	rot(P_NECK2, Vector3((steady * 0.3 + look_x - 2.0 * c * aw) * DEG, (0.35 * look_y + 8.0 * _bank) * DEG,
		-0.3 * roll * DEG))
	rot(P_HEAD, Vector3((steady * 0.2 - 0.5 * look_x - 1.2 * c * aw) * DEG, (0.3 * look_y + 6.0 * _bank) * DEG,
		-0.5 * roll * DEG))
	rot(P_JAW, Vector3((1.5 + 1.5 * sin(_t * 1.3 + _phase_off)) * DEG, 0.0, 0.0))
	# --- tail: fanned down while hovering, level in flight, twists into turns
	var tp := lerpf(-14.0, 1.0, mw) + 3.0 * sin(TAU * psi - 1.2) * aw
	if climbing:
		tp -= 10.0
	rot(P_TAIL1, Vector3(tp * DEG, (-6.0 * _bank + 3.0 * sin(_t * 0.9) * hw) * DEG, 12.0 * _bank * DEG))
	# --- talons: tucked back in flight, dangling while hovering
	var dang := -48.0 * hw + 3.0 * sin(TAU * psi + 0.5) * aw * hw
	if climbing:
		dang = minf(dang, -30.0)
	rot(P_LEG_FL, Vector3(dang * DEG, 0.0, -5.0 * hw * DEG))
	rot(P_LEG_FR, Vector3(dang * DEG, 0.0, 5.0 * hw * DEG))


# ---------------------------------------------------------------- attack / casts

## Talon rake: wings flare up, drop and lunge, talons thrown forward at STRIKE_T, climb back.
func _pose_strike(prev: float, t: float) -> void:
	pos(P_ROOT, Vector3(0.0, _tk(t, K_ATK_Y), _tk(t, K_ATK_Z)))
	rot(P_BODY, Vector3(_tk(t, K_ATK_PITCH) * DEG, 0.0, 0.0))
	_both_wings(_tk(t, K_ATK_WING), _tk(t, K_ATK_HAND), 0.0, 0.0)
	var lx := _tk(t, K_ATK_LEG)
	rot(P_LEG_FL, Vector3(lx * DEG, 0.0, -8.0 * DEG * lx / -98.0))
	rot(P_LEG_FR, Vector3(lx * DEG, 0.0, 8.0 * DEG * lx / -98.0))
	var n := _tk(t, K_ATK_NECK)
	rot(P_NECK1, Vector3(n * 0.5 * DEG, 0.0, 0.0))
	rot(P_NECK2, Vector3(n * 0.5 * DEG, 0.0, 0.0))
	rot(P_JAW, Vector3(_tk(t, K_ATK_JAW) * DEG, 0.0, 0.0))
	rot(P_TAIL1, Vector3(_tk(t, K_ATK_TAIL) * DEG, 0.0, 0.0))
	_flare = maxf(_flare, 0.3 * sin(PI * clampf(t / 0.4, 0.0, 1.0)))
	if prev < STRIKE_T and t >= STRIKE_T:
		_strikes += 1
		_on_action_event(&"release")


## Returns the cast length.
func _pose_roc_cast(prev: float, t: float) -> float:
	if _cast_id == &"updraft":
		_pose_updraft(prev, t)
		return UPDRAFT_LEN
	_pose_swoop(prev, t, _cast_id == &"shrieking_dive")
	return SWOOP_LEN


## Gale Swoop / Shrieking Dive: beat up, steep swept-wing dive, flare and slam the wings down at the impact (talons
## forward), climb back. The shriek stretches the neck, opens the beak wide, shakes the head and flares the eyes.
func _pose_swoop(prev: float, t: float, shriek: bool) -> void:
	pos(P_ROOT, Vector3(0.0, _tk(t, K_SW_Y), _tk(t, K_SW_Z)))
	rot(P_BODY, Vector3(_tk(t, K_SW_PITCH) * DEG, 0.0, 0.0))
	_both_wings(_tk(t, K_SW_WING), _tk(t, K_SW_HAND), _tk(t, K_SW_SWEEP), _tk(t, K_SW_HSWEEP))
	var lx := _tk(t, K_SW_LEG)
	rot(P_LEG_FL, Vector3(lx * DEG, 0.0, 0.0))
	rot(P_LEG_FR, Vector3(lx * DEG, 0.0, 0.0))
	rot(P_TAIL1, Vector3(_tk(t, K_SW_TAIL) * DEG, 0.0, 0.0))
	if shriek:
		var n := _tk(t, K_SH_NECK)
		var shake := 9.0 * sin(t * 38.0) * sin(PI * clampf((t - 0.28) / 0.5, 0.0, 1.0))
		rot(P_NECK1, Vector3(n * 0.5 * DEG, 0.0, 0.0))
		rot(P_NECK2, Vector3(n * 0.5 * DEG, shake * 0.5 * DEG, 0.0))
		rot(P_HEAD, Vector3(-n * 0.3 * DEG, shake * DEG, 0.0))
		rot(P_JAW, Vector3(_tk(t, K_SH_JAW) * DEG, 0.0, 0.0))
		_flare = maxf(_flare, _tk(t, K_SH_FLARE))
	else:
		var n := _tk(t, K_SW_NECK)
		rot(P_NECK1, Vector3(n * 0.5 * DEG, 0.0, 0.0))
		rot(P_NECK2, Vector3(n * 0.5 * DEG, 0.0, 0.0))
		rot(P_JAW, Vector3(_tk(t, K_SW_JAW) * DEG, 0.0, 0.0))
		_flare = maxf(_flare, _tk(t, K_SW_FLARE))
	if prev < SWOOP_IMPACT and t >= SWOOP_IMPACT:
		_swoops += 1
		_burst(0.7 if shriek else 0.55)
		_on_action_event(&"impact")


## Updraft launch: two huge beats (nose up, talons down, a screech), feathers burst at UPDRAFT_BURST and the climb
## starts (the hold keeps it up UPDRAFT_HOLD s, or while shrouded).
func _pose_updraft(prev: float, t: float) -> void:
	pos(P_ROOT, Vector3(0.0, _tk(t, K_UP_Y), 0.0))
	rot(P_BODY, Vector3(_tk(t, K_UP_PITCH) * DEG, 0.0, 0.0))
	_both_wings(_tk(t, K_UP_WING), _tk(t, K_UP_HAND), 0.0, 0.0)
	var lx := _tk(t, K_UP_LEG)
	rot(P_LEG_FL, Vector3(lx * DEG, 0.0, 0.0))
	rot(P_LEG_FR, Vector3(lx * DEG, 0.0, 0.0))
	rot(P_TAIL1, Vector3(_tk(t, K_UP_TAIL) * DEG, 0.0, 0.0))
	var n := _tk(t, K_UP_NECK)
	rot(P_NECK1, Vector3(n * 0.5 * DEG, 0.0, 0.0))
	rot(P_NECK2, Vector3(n * 0.5 * DEG, 0.0, 0.0))
	rot(P_JAW, Vector3(_tk(t, K_UP_JAW) * DEG, 0.0, 0.0))
	_flare = maxf(_flare, _tk(t, K_UP_FLARE))
	if prev < UPDRAFT_BURST and t >= UPDRAFT_BURST:
		_updrafts += 1
		_alt_hold = UPDRAFT_HOLD
		_burst(1.0)
		_on_action_event(&"updraft")


## Both wings: raise / hand bend (deg, + = up) and sweeps back (deg: arm at the shoulder, hand at the wrist).
func _both_wings(w: float, h: float, arm_back: float, hand_back: float) -> void:
	for side: int in 2:
		var s := -1.0 if side == 0 else 1.0
		_wing_raise(side, w * DEG)
		_hand_bend(side, h * DEG)
		rot(P_WING_L if side == 0 else P_WING_R, Vector3(0.0, s * arm_back * DEG, 0.0))
		rot(P_WING_L2 if side == 0 else P_WING_R2, Vector3(0.0, s * hand_back * DEG, 0.0))


## Restarts the feather burst (world-space particles) at the body.
func _burst(ratio: float) -> void:
	if _feathers == null or not is_inside_tree() or _piv[P_BODY] == null:
		return
	_bursts += 1
	_feathers.global_position = _piv[P_BODY].global_position
	_feathers.amount_ratio = ratio
	_feathers.restart()


# ---------------------------------------------------------------- death

## Screech + wings thrown up, tumble out of the air (roll, nose down, one wing flailing), crash at CRASH_AT (squash,
## bounce, feather burst, `crashed`), breast-down with the wings splayed on the ground, eyes dark, then it sinks.
func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var lift := fly_height - BAKE_HEIGHT + _death_alt
	var throe := _ease_out(clampf(t / 0.22, 0.0, 1.0)) * (1.0 - clampf((t - 0.25) / 0.3, 0.0, 1.0))
	var f := clampf((t - 0.16) / (CRASH_AT - 0.16), 0.0, 1.0)
	var fall := f * f
	var landed := t >= CRASH_AT
	var sd := _spiral_dir
	var land_k := _ease_out(clampf((t - CRASH_AT) / 0.16, 0.0, 1.0))
	var y := lerpf(lift + 0.3 * throe, CORPSE_Y - BAKE_HEIGHT, fall)
	if landed:
		var ti := t - CRASH_AT
		var sq := exp(-ti * 9.0) * cos(ti * 22.0)
		_body_scale = Vector3(1.0 + 0.07 * sq, 1.0 - 0.16 * sq, 1.0 + 0.05 * sq)
		y = CORPSE_Y - BAKE_HEIGHT + 0.12 * maxf(0.0, sin(clampf(ti / 0.2, 0.0, 1.0) * PI)) * exp(-ti * 3.0)
		y -= 1.1 * _ease_in(clampf((t - 1.3) / (ROC_DEATH_LEN - 1.3), 0.0, 1.0))
		if not _crash_emitted:
			_crash_emitted = true
			_burst(1.0)
			crashed.emit(global_transform * Vector3(0.0, 0.1, 0.0))
			_on_action_event(&"crash")
	pos(P_ROOT, Vector3(0.0, y, 0.0))
	rot(P_ROOT, Vector3(0.0, sd * 0.45 * PI * _ease_in(f), 0.0))
	# body: rolls and noses down in the tumble, lands breast-down with a slight list
	var roll := lerpf(sd * 75.0 * _ease_in(f) * (1.0 - 0.4 * fall), sd * 8.0, land_k)
	var pitch := lerpf(-12.0 * throe + 34.0 * fall, 6.0, land_k)
	rot(P_BODY, Vector3(pitch * DEG, 0.0, roll * DEG))
	# neck / head: thrown back (screech), limp in the fall, flopped aside on the ground
	var n1 := lerpf(-26.0 * throe + 18.0 * fall, 14.0, land_k)
	var flop := sd * 34.0 * land_k
	rot(P_NECK1, Vector3(n1 * DEG, flop * 0.4 * DEG, 0.0))
	rot(P_NECK2, Vector3(n1 * 0.8 * DEG, flop * 0.6 * DEG, 0.0))
	rot(P_HEAD, Vector3((-18.0 * throe + 10.0 * fall * (1.0 - land_k) + 16.0 * land_k) * DEG, flop * 0.4 * DEG,
		sd * 26.0 * land_k * DEG))
	rot(P_JAW, Vector3((40.0 * throe + 12.0 * fall * (1.0 - land_k) + 16.0 * land_k) * DEG, 0.0, 0.0))
	# wings: jerk up, one flails, the other crumples; splayed flat on the ground once down
	var flail := sin(t * 30.0) * 28.0 * clampf(1.0 - f, 0.0, 1.0) * clampf((t - 0.2) / 0.1, 0.0, 1.0)
	var up_side := 1 if sd > 0.0 else 0
	for side: int in 2:
		var w_air: float
		var h_air: float
		if side == up_side:
			w_air = 55.0 * throe + (25.0 + flail) * fall
			h_air = 12.0 * throe - 18.0 * fall
		else:
			w_air = 55.0 * throe + 60.0 * fall
			h_air = 12.0 * throe - 60.0 * fall
		var w_gnd := -12.0 - (5.0 if side == up_side else -5.0)
		_wing_raise(side, lerpf(w_air, w_gnd, land_k) * DEG)
		_hand_bend(side, lerpf(h_air, -2.0, land_k) * DEG)
		var s := -1.0 if side == 0 else 1.0
		rot(P_WING_L if side == 0 else P_WING_R, Vector3(0.0, s * 10.0 * land_k * DEG, 0.0))
	# tail: flutters in the fall, laid on the ground
	rot(P_TAIL1, Vector3(lerpf(8.0 * sin(t * 14.0) * (1.0 - f), -14.0, land_k) * DEG, sd * 10.0 * land_k * DEG, 0.0))
	# talons: kick in the screech, clench back once down
	var lk := land_k
	rot(P_LEG_FL, Vector3((-60.0 * throe - 20.0 * fall * (1.0 - lk) + 48.0 * lk) * DEG, 0.0, -10.0 * lk * DEG))
	rot(P_LEG_FR, Vector3((-60.0 * throe - 20.0 * fall * (1.0 - lk) + 48.0 * lk) * DEG, 0.0, 10.0 * lk * DEG))
	_flare = 1.2 * throe
	_cool = 1.0 - smoothstep(CRASH_AT - 0.1, CRASH_AT + 0.25, t)
	if _shadow:
		_shadow.transparency = clampf((t - 1.3) / 0.4, 0.0, 1.0)
		var k := clampf(_death_alt / UPDRAFT_RISE, 0.0, 1.0) * (1.0 - fall)
		_shadow.scale = Vector3(BLOB_SIZE.x * (1.0 - 0.3 * k), 1.0, BLOB_SIZE.y * (1.0 - 0.3 * k))
	if t >= ROC_DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


## Keyframe track [t, v, t, v ...], smoothstep between keys, clamped at the ends. No allocation.
static func _tk(t: float, k: PackedFloat32Array) -> float:
	var n := k.size()
	if t <= k[0]:
		return k[1]
	if t >= k[n - 2]:
		return k[n - 1]
	var i := 2
	while t >= k[i]:
		i += 2
	var u := (t - k[i - 2]) / (k[i] - k[i - 2])
	u = u * u * (3.0 - 2.0 * u)
	return lerpf(k[i - 1], k[i + 1], u)
