extends CharacterModel
## Gloomcap Elder (map-fill.md 5.1 / 10, task 12.V22): the ranged leader of the Gloomcap Hollow (1 Elder + 3 Sprouts).
## An old walking mushroom, 1.9 m to the top of its cap (selection radius 0.6). Read at 40 m by:
##  - a WIDE BLUE-GREY CAP (1.65 m across, 2.7 x the stalk) with a low central boss, a lumpy drooping rim and big pale
##    spots: the dominant mass from the RTS camera;
##  - a gnarled ROOT STAFF held out beside the cap, taller than it, with a glowing teal spore bulb caught in a claw of
##    roots at the top: the asymmetric secondary element and the one strong glow point;
##  - glowing teal spore motes drifting down off the gill rim (looping, stops beyond 45 m).
## Close up: a pale grey-beige stalk body rising out of a dark ragged soil cup (volva) on two stumpy root legs with
## splayed root toes, a dark slate skirt (the ring), long gangly root arms, faint teal eyes under the brim, a beard of
## pale lichen, dark ridged gills, three baby gloomcaps growing on its left shoulder.
## Neutral: no team colour (set_team_color is a no-op), 0 lights, glow by emission only (gloomcap_glow).
## Motion (procedural, kit rules):
##  - idle: a slow sway like a mushroom in the wind, the cap lagging; every ~fidget_every s at close range a CAP SHAKE
##    fidget (it shakes its cap, sheds a small spore puff, taps the staff); `play_fidget()` starts one now;
##  - walk: a heavy waddle on the short root legs, the cap bobbing behind, the staff swung like a walking stick;
##  - attack `spore_bolt` (ranged, attack_windup 0.12 = the bolt release): the staff tips back while the bulb charges,
##    then thrusts forward (bulb flare + a small spore puff at the bulb);
##  - cast `spore_burst` (1.1 s; any id plays it): the cap SWELLS as the Elder raises the staff back and its other arm
##    up, then at 0.46 s slams the staff down, the cap snaps forward and a big spore cloud bursts from it (bulb flare),
##    the cap shudders; the ground AoE at the target is MapFillVfx's `spore_burst` (12.V25);
##  - hit: the kit flinch + flash, the cap wobbles and sheds a few spores;
##  - death (1.0 s): a jolt, the cap droops and the Elder topples over sideways, a last spore cloud (glows off), it
##    sinks away (death_finished at 1.0 s).
## Budget (soldier budget of map-fill.md 10: <= 18 authored meshes, <= 10 draw instances, 0 lights): 7 authored
## meshes + the blob, 7 merged pivots + blob + 2 pre-built emitters (Spores loop, Burst one-shot) = 10 draw instances;
## 7 own materials (materials/; 6 shared with the Sprout). See tests/test_12_v22.gd.

const GM := preload("res://art/units/neutral/gloomcap/gloomcap_mesh.gd")

const CAP_R := 0.82            # lip radius
const CAP_RIM_Y := 1.44
const CAP_DOME := 0.39
const CAP_SEG := 30
const BULB := Vector3(0.86, 2.03, 0.34)      # model space, rest: the glowing spore bulb on the staff
const CAP_PUFF := Vector3(0.0, 1.66, 0.1)    # model space: where the cast cloud leaves the cap
const BOLT_LEN := 0.6
const CAST_LEN := 1.1
const CAST_SLAM := 0.46
const FIDGET_LEN := 1.6
const FIDGET_PUFF := 0.42
const DEATH_PUFF := 0.32

# Keyframe tracks [t, value, ease, ...] (GM.trk). Degrees. Arm x: - raises the fist forward (the staff head tips
# back), + drops it (the staff head tips forward). Chest y: - turns the right (staff) shoulder forward.
static var B_ARM := PackedFloat32Array([0.0, 0.0, 0, 0.10, -14.0, 1, 0.13, 30.0, 2, 0.28, 20.0, 0, 0.6, 0.0, 0])
static var B_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -5.0, 1, 0.13, 8.0, 2, 0.3, 4.0, 0, 0.6, 0.0, 0])
static var B_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.10, 8.0, 1, 0.13, -12.0, 2, 0.3, -6.0, 0, 0.6, 0.0, 0])
static var B_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -4.0, 1, 0.16, 7.0, 2, 0.35, 0.0, 0, 0.6, 0.0, 0])
static var B_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.10, -0.03, 1, 0.13, 0.06, 2, 0.3, 0.02, 0, 0.6, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.38, -42.0, 1, 0.47, 28.0, 2, 0.72, 16.0, 0, 1.1, 0.0, 0])
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.36, -70.0, 1, 0.48, -20.0, 2, 0.8, -6.0, 0, 1.1, 0.0, 0])
static var C_ARM_LZ := PackedFloat32Array([0.0, 0.0, 0, 0.36, -25.0, 1, 0.48, -8.0, 2, 1.1, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.38, -12.0, 1, 0.47, 15.0, 2, 0.75, 6.0, 0, 1.1, 0.0, 0])
static var C_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.38, -12.0, 1, 0.47, 16.0, 2, 0.8, 3.0, 0, 1.1, 0.0, 0])
static var C_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.38, -0.03, 1, 0.47, -0.08, 2, 0.8, -0.02, 0, 1.1, 0.0, 0])
static var C_SWELL := PackedFloat32Array([0.0, 0.0, 0, 0.38, 1.0, 1, 0.47, -0.35, 2, 0.62, 0.08, 0, 1.1, 0.0, 0])
static var D_JOLT := PackedFloat32Array([0.0, 0.0, 0, 0.1, 1.0, 1, 0.3, 0.0, 0])

## Idle cap-shake fidget interval (s, randomised +-40 % per unit); 0 = never. Only within 30 m of the camera.
@export var fidget_every: float = 9.0

var _authored: int = 0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _spores: GPUParticles3D
var _burst: GPUParticles3D
var _staff_gi: GeometryInstance3D
var _flare: float = 0.0
var _flare_w: float = -1.0
var _swell: float = 0.0
var _swell_w: float = -1.0
var _fidget_wait: float = 0.0
var _bolts: int = 0
var _bursts: int = 0
var _last_puff: float = -9.0
var _cast_last: float = -1.0


# ================================================================ public (tests, preview, camp idle)

## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Spore bolts released so far (the `release` frame of each attack), for tests.
func bolt_count() -> int:
	return _bolts


## Full spore clouds burst so far (cast slam, death), for tests.
func burst_count() -> int:
	return _bursts


## How swollen the cap is now (0 rest, 1 full swell before the burst; negative = snapped flat).
func cap_swell() -> float:
	return _swell


## Starts the idle cap shake now (it also plays by itself every ~fidget_every s close to the camera).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0


## World position of the staff's spore bulb (where spore bolts can start), or 3/4 of the height before _ready.
func get_beam_origin() -> Vector3:
	if _ready_done and is_inside_tree() and _piv[P_ARM_R]:
		return _piv[P_ARM_R].global_transform * (BULB - model_origin(_piv[P_ARM_R]))
	return global_position + Vector3.UP * body_height * 0.75


## Neutral creature: no team colour.
func set_team_color(_c: Color) -> void:
	pass


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh) -> MeshInstance3D:
	_authored += 1
	return add_part(pivot, mesh, null, Vector3.ZERO)


func _build_parts() -> void:
	_authored = 0
	_part($Root/Hips, _hips_mesh())
	_part($Root/Hips/LegL, _leg_mesh(-1.0))
	_part($Root/Hips/LegR, _leg_mesh(1.0))
	_part($Root/Chest, _chest_mesh())
	_face = CreatureFaceRig.attach(self, $Root/Chest, "gloomcap_elder", face_spec())
	_part($Root/Chest/Head, _cap_mesh())
	_part($Root/Chest/ArmL, _arm_l_mesh())
	_part($Root/Chest/ArmR, _arm_r_mesh())
	_spores = $Fx/Spores
	_burst = $Fx/Burst
	ensure_shadow_blob(0.6, Color(0.03, 0.04, 0.05, 0.5))
	_shadow.scale = Vector3(1.75, 1.0, 1.65)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	# The kit flashes the merged Chest / Head / ArmR on hits: add the stalk base, the legs and the left arm.
	for i: int in [P_HIPS, P_LEG_L, P_LEG_R, P_ARM_L]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
	# The staff bulb flares on its own (bolts, the burst): drive its glow_boost here instead of the kit.
	_staff_gi = _merged_nodes.get(P_ARM_R)
	if _staff_gi:
		_glow_nodes.erase(_staff_gi)
	_fidget_wait = _next_fidget() * 0.6
	if _face:
		_face.set_host(_merged_nodes.get(P_CHEST))
	_write_glow()


func _on_revive() -> void:
	if _face:
		_face.reset()
	_flare = 0.0
	_swell = 0.0
	_flare_w = -1.0
	_swell_w = -1.0
	_write_swell()
	_write_glow()


# ================================================================ hooks

func play_hit() -> void:
	var before := _hit_t
	super.play_hit()
	if _hit_t == 0.0 and before != 0.0 and _tier == 0 and _t - _last_puff > 0.5:
		_last_puff = _t
		_puff(CAP_PUFF - Vector3(0, 0.1, 0), P_HEAD, 0.22)


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_cast_last = -1.0
	elif ev == &"release" and _action == &"attack":
		_bolts += 1
		_flare = 1.0
		if _tier < 2:
			_puff(BULB, P_ARM_R, 0.2)


## Restarts the Burst emitter at a model-space rest point carried by pivot i (its current pose), `ratio` of its
## particles (a small puff or the full cloud).
func _puff(model_pt: Vector3, i: int, ratio: float) -> void:
	if _burst == null or not is_inside_tree():
		return
	var p: Node3D = _piv[i] if _piv[i] else self
	_burst.position = to_local(p.global_transform * (model_pt - model_origin(p)))
	_burst.amount_ratio = ratio
	_burst.restart()


# ================================================================ idle / walk

func _idle_rot(ph: float) -> Array[Vector3]:
	var chest := Vector3(1.5 * sin(ph), 0.0, 2.2 * sin(0.5 * ph + 0.4)) * DEG
	var head := Vector3(-1.8 * sin(ph + 0.9), 3.0 * sin(0.37 * ph), -2.6 * sin(0.5 * ph + 1.4)) * DEG
	return [chest, head]


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var r := _idle_rot(ph)
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.012 * sin(ph), 0))
	_write_rot(P_CHEST, _rest_rot[P_CHEST] + r[0])
	if _tier == 0:
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + r[1])


func _pose_idle(w: float) -> void:
	if _dead:
		return
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var r := _idle_rot(ph)
	pos(P_ROOT, Vector3(0, 0.012 * sin(ph) * w, 0))
	rot(P_CHEST, r[0] * w)
	rot(P_HEAD, r[1] * w)


## Heavy waddle: short root legs (the forward-swinging one lifted), the body rolling onto the planted leg, a dip at
## each footfall, the cap bobbing a beat behind, the free arm and the staff swinging like a walking stick.
func _pose_walk(w: float, _rate: float) -> void:
	var ph: float = TAU * _walk_p
	var s: float = sin(ph)
	var c: float = cos(ph)
	var a: float = 26.0 * DEG * w
	rot(P_LEG_L, Vector3(-a * s, 0, 0))
	rot(P_LEG_R, Vector3(a * s, 0, 0))
	pos(P_LEG_L, Vector3(0, 0.05 * maxf(0.0, c) * w, 0))
	pos(P_LEG_R, Vector3(0, 0.05 * maxf(0.0, -c) * w, 0))
	pos(P_ROOT, Vector3(0, walk_bounce * (0.5 + 0.5 * cos(2.0 * ph)) * w, 0))
	rot(P_ROOT, Vector3(4.0 * DEG * w, 0, 4.5 * DEG * c * w))
	rot(P_CHEST, Vector3(1.5 * DEG * cos(2.0 * ph) * w, 3.0 * DEG * s * w, -1.5 * DEG * c * w))
	rot(P_HEAD, Vector3((-2.0 + 3.0 * cos(2.0 * ph - 0.9)) * DEG * w, 0, -3.5 * DEG * cos(ph - 0.7) * w))
	rot(P_ARM_L, Vector3(-18.0 * DEG * s * w, 0, 0))
	if _action != &"attack" and _action != &"cast":
		rot(P_ARM_R, Vector3(12.0 * DEG * s * w, 0, 0))


# ================================================================ attack / cast / fidget

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"spore_bolt":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3(GM.trk(t, B_ARM), 0, 0) * DEG)
	rot(P_CHEST, Vector3(GM.trk(t, B_CHEST_X), GM.trk(t, B_CHEST_Y), 0) * DEG)
	rot(P_HEAD, Vector3(GM.trk(t, B_HEAD_X), 0, 0) * DEG)
	pos(P_ROOT, Vector3(0, 0, GM.trk(t, B_ROOT_Z)))
	if t < attack_windup:
		_flare = maxf(_flare, 0.6 * t / maxf(attack_windup, 0.01))
	if prev < attack_windup and t >= attack_windup:
		_on_action_event(&"release")
	return t < BOLT_LEN


## Spore Burst (any id): the cap swells while the staff is raised back, then the slam at CAST_SLAM bursts the cloud.
func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ARM_R, Vector3(GM.trk(t, C_ARM_R), 0, 0) * DEG)
	rot(P_ARM_L, Vector3(GM.trk(t, C_ARM_L), 0, GM.trk(t, C_ARM_LZ)) * DEG)
	rot(P_CHEST, Vector3(GM.trk(t, C_CHEST_X), 0, 0) * DEG)
	var shake: float = 0.0
	if t > CAST_SLAM:
		shake = sin((t - CAST_SLAM) * 42.0) * exp(-(t - CAST_SLAM) * 5.0)
	rot(P_HEAD, Vector3(GM.trk(t, C_HEAD_X), 0, 7.0 * shake) * DEG)
	pos(P_ROOT, Vector3(0, GM.trk(t, C_ROOT_Y), 0))
	_swell = GM.trk(t, C_SWELL)
	if t < _cast_last:
		_cast_last = -1.0   # a new cast
	var prev: float = _cast_last
	_cast_last = t
	if t < CAST_SLAM:
		_flare = maxf(_flare, 0.5 * t / CAST_SLAM)
	if prev < CAST_SLAM and t >= CAST_SLAM:
		_bursts += 1
		_flare = 1.0
		if _tier < 2:
			_puff(CAP_PUFF, P_HEAD, 1.0)
	return CAST_LEN


## The cap shake (1.6 s): the cap wobbles fast and sheds a small spore puff, then the staff taps the ground twice.
func _pose_fidget(t: float, prev: float) -> void:
	var on: float = _k3(t, 0.0, 0.15, 0.8, 1.0, 1.0, 1.0)
	var wob: float = sin(t * 30.0) * on
	rot(P_HEAD, Vector3(3.0 * on, 0, 8.0 * wob) * DEG)
	rot(P_CHEST, Vector3(0, 0, -2.0 * wob) * DEG)
	var tap: float = 0.0
	for k: float in [1.05, 1.35]:
		tap += exp(-pow((t - k) / 0.07, 2.0))
	rot(P_ARM_R, Vector3(-9.0 * tap, 0, 0) * DEG)
	pos(P_ROOT, Vector3(0, -0.015 * tap, 0))
	if prev < FIDGET_PUFF and t >= FIDGET_PUFF:
		_puff(CAP_PUFF, P_HEAD, 0.3)


# ================================================================ death (1.0 s)

func _pose_death(dt: float) -> void:
	var prev: float = _death_t
	_death_t += dt
	var t: float = _death_t
	var jolt: float = GM.trk(t, D_JOLT)
	var fall: float = _ease_in(clampf((t - 0.22) / 0.36, 0.0, 1.0))
	var sink: float = _ease_in(clampf((t - 0.62) / 0.38, 0.0, 1.0))
	rot(P_HEAD, Vector3(-14.0 * jolt + 24.0 * fall, 0, 16.0 * fall) * DEG)
	rot(P_CHEST, Vector3(-6.0 * jolt + 10.0 * fall, 0, 12.0 * fall) * DEG)
	rot(P_ROOT, Vector3(0, 0, 70.0 * DEG * fall))
	pos(P_ROOT, Vector3(0, -0.03 * jolt - 0.9 * sink, 0))
	rot(P_LEG_L, Vector3(28.0 * fall, 0, 0) * DEG)
	rot(P_LEG_R, Vector3(-22.0 * fall, 0, 0) * DEG)
	rot(P_ARM_R, Vector3(-30.0 * jolt + 35.0 * fall, 0, 20.0 * fall) * DEG)
	rot(P_ARM_L, Vector3(-45.0 * jolt, 0, -30.0 * fall) * DEG)
	_root_scale *= 1.0 - 0.25 * sink
	if prev < DEATH_PUFF and t >= DEATH_PUFF:
		_bursts += 1
		if _tier < 2:
			_puff(CAP_PUFF, P_HEAD, 0.8)
		_glows_dead()
	if _shadow:
		_shadow.transparency = clampf((t - 0.6) / 0.35, 0.0, 1.0)
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
				_pose_fidget(_action_t, _action_t - dt)
		elif fidget_every > 0.0 and _action == &"" and _speed < 0.3 and _tier == 0:
			_fidget_wait -= dt
			if _fidget_wait <= 0.0:
				_fidget_wait = _next_fidget()
				play_fidget()
		if _hit_t < HIT_LEN:
			var k: float = sin(PI * clampf(_hit_t / HIT_LEN, 0.0, 1.0))
			rot(P_HEAD, Vector3(-5.0 * k, 0, 6.0 * k) * DEG)
	if _action != &"cast":
		_swell = move_toward(_swell, 0.0, dt * 4.0)
	_flare = move_toward(_flare, 0.0, dt / 0.4)
	_write_swell()
	_write_glow()


func _write_swell() -> void:
	var h: Node3D = _piv[P_HEAD] if _piv.size() > P_HEAD else null
	if h == null or absf(_swell - _swell_w) < 0.003:
		return
	_swell_w = _swell
	h.scale = Vector3(1.0 + 0.12 * _swell, 1.0 + 0.09 * _swell, 1.0 + 0.12 * _swell)


func _write_glow() -> void:
	if _staff_gi == null:
		return
	var v: float = glow_level() * (1.0 + 2.2 * _flare)
	if absf(v - _flare_w) < 0.01:
		return
	_flare_w = v
	_staff_gi.set_instance_shader_parameter(&"glow_boost", v)


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


# ================================================================ meshes (static, built once per game, model space)

static func _cap_shape(a: float, r: float, _y: float) -> Vector3:
	var u: float = clampf(r / CAP_R, 0.0, 1.0)
	var rf: float = 1.0 + (0.035 * sin(3.0 * a + 1.0) + 0.022 * sin(5.0 * a + 0.3)) * u
	var dy: float = -0.075 * u * u * u * (0.5 + 0.5 * sin(2.0 * a + 0.7)) - 0.025 * u * u * sin(3.0 * a + 2.0)
	return Vector3(rf, dy, 0.0)


static func _cap_top_y(r: float) -> float:
	var u: float = clampf(r / CAP_R, 0.0, 1.0)
	return CAP_RIM_Y + CAP_DOME * pow(1.0 - u * u, 0.55) + 0.07 * exp(-pow(r / 0.2, 2.0))


## Cap top surface point at angle a (0 = +Z), radius r (model space, rest).
static func _cap_point(a: float, r: float) -> Vector3:
	var s := _cap_shape(a, r, 0.0)
	return Vector3(sin(a) * r * s.x, _cap_top_y(r) + s.y, cos(a) * r * s.x)


static func _cap_normal(a: float, r: float) -> Vector3:
	var dr := _cap_point(a, r + 0.01) - _cap_point(a, r - 0.01)
	var da := _cap_point(a + 0.02, r) - _cap_point(a - 0.02, r)
	var n := da.cross(dr).normalized()
	return n if n.y > 0.0 else -n


## The cap (Head): lumpy blue-grey dome with a low boss and a drooping, wavy rim; dark ridged gills underneath; big
## pale spots.
static func _cap_mesh() -> Mesh:
	const KEY := "elder_cap_v2"
	if GM.cached(KEY):
		return GM.cached(KEY)
	var cap := GM.bucket()
	var band := GM.bucket()
	var gills := GM.bucket()
	var spots := GM.bucket()
	var shape := func(a: float, r: float, y: float) -> Vector3: return _cap_shape(a, r, y)
	# A darker weathered band round the rim (the elder look from above), the paler blue-grey crown inside it.
	var outer := PackedVector2Array()
	for r: float in [0.82, 0.815, 0.80, 0.77, 0.72, 0.66]:
		outer.append(Vector2(r, _cap_top_y(r)))
	GM.lathe(band, outer, CAP_SEG, Vector3.ZERO, shape)
	var top := PackedVector2Array()
	for r: float in [0.66, 0.6, 0.52, 0.43, 0.33, 0.23, 0.12, 0.0]:
		top.append(Vector2(r, _cap_top_y(r)))
	GM.lathe(cap, top, CAP_SEG, Vector3.ZERO, shape)
	var under := PackedVector2Array([Vector2(0.17, 1.505), Vector2(0.3, 1.5), Vector2(0.42, 1.49), Vector2(0.55, 1.472),
		Vector2(0.66, 1.452), Vector2(0.745, 1.432), Vector2(0.80, 1.425), Vector2(0.82, CAP_RIM_Y)])
	var ridged := func(a: float, r: float, y: float) -> Vector3:
		var s := _cap_shape(a, r, y)
		var g: float = smoothstep(0.24, 0.4, r) * (1.0 - smoothstep(0.72, 0.8, r))
		s.y += 0.022 * (0.5 + 0.5 * cos(a * float(CAP_SEG) * 0.5)) * g
		return s
	GM.lathe(gills, under, CAP_SEG, Vector3.ZERO, ridged)
	# Spots: [angle, radius on the cap, spot radius].
	for sp: Vector3 in [Vector3(0.3, 0.22, 0.13), Vector3(1.5, 0.46, 0.125), Vector3(2.35, 0.64, 0.10),
			Vector3(3.3, 0.38, 0.14), Vector3(4.25, 0.6, 0.115), Vector3(5.2, 0.3, 0.11), Vector3(5.85, 0.64, 0.095),
			Vector3(0.85, 0.66, 0.1), Vector3(2.95, 0.72, 0.075), Vector3(4.9, 0.72, 0.07)]:
		var n := _cap_normal(sp.x, sp.y)
		GM.patch_on(spots, _cap_point(sp.x, sp.y) + n * 0.004, n, sp.z, 0.026, 8, 3, 0.62 + 0.3 * absf(sin(sp.x * 3.1)),
			sp.x * 1.7)
	return GM.commit(KEY, [[cap, GM.mat(&"gloomcap_cap")], [band, GM.mat(&"gloomcap_cap_rim")],
		[gills, GM.mat(&"gloomcap_gills")],
		[spots, GM.mat(&"gloomcap_spots")]])


## Stalk base (Hips): a bulbous pale foot rising out of a dark ragged soil cup.
static func _hips_mesh() -> Mesh:
	const KEY := "elder_hips_v1"
	if GM.cached(KEY):
		return GM.cached(KEY)
	var stalk := GM.bucket()
	var soil := GM.bucket()
	var lump := func(a: float, _r: float, y: float) -> Vector3:
		return Vector3(1.0 + 0.04 * sin(2.0 * a + y * 5.0) + 0.025 * sin(5.0 * a + 1.0), 0.0, 0.0)
	GM.lathe(stalk, PackedVector2Array([Vector2(0.0, 0.34), Vector2(0.18, 0.36), Vector2(0.27, 0.44), Vector2(0.29, 0.54),
		Vector2(0.272, 0.66), Vector2(0.257, 0.8), Vector2(0.25, 0.88)]), 14, Vector3.ZERO, lump)
	var jag := func(a: float, _r: float, y: float) -> Vector3:
		var top: float = smoothstep(0.52, 0.62, y)
		return Vector3(1.0 + 0.05 * sin(3.0 * a + 0.5), -0.08 * top * (0.5 + 0.5 * cos(a * 6.0)) - 0.04 * top
			* (0.5 + 0.5 * cos(a * 7.0)), 0.0)
	GM.lathe(soil, PackedVector2Array([Vector2(0.24, 0.3), Vector2(0.325, 0.37), Vector2(0.35, 0.49),
		Vector2(0.325, 0.63)]), 14, Vector3.ZERO, jag)
	return GM.commit(KEY, [[stalk, GM.mat(&"gloomcap_stalk")], [soil, GM.mat(&"gloomcap_root")]])


## One root leg (LegL / LegR): a knobbly root from under the soil cup to the ground, three root toes splayed out.
static func _leg_mesh(sx: float) -> Mesh:
	var key := "elder_leg_v1_%s" % sx
	if GM.cached(key):
		return GM.cached(key)
	var rt := GM.bucket()
	var hip := Vector3(0.13 * sx, 0.44, 0.0)
	var foot := Vector3(0.19 * sx, 0.07, 0.04)
	GM.root(rt, hip, foot, 0.09, 0.07, 5, 0.02, 1.3 + sx, 6)
	GM.ellipsoid(rt, Vector3(0.165 * sx, 0.25, 0.03), Vector3(0.09, 0.08, 0.09), 7, 3)
	GM.ellipsoid(rt, foot + Vector3(0, -0.01, 0.0), Vector3(0.09, 0.06, 0.1), 7, 3)
	for d: Vector3 in [Vector3(0.1 * sx, -0.045, 0.25), Vector3(0.25 * sx, -0.045, 0.02), Vector3(0.02 * sx, -0.045, -0.22)]:
		GM.root(rt, foot + Vector3(0, 0.01, 0), foot + d, 0.045, 0.012, 4, 0.012, d.x * 7.0, 5)
	return GM.commit(key, [[rt, GM.mat(&"gloomcap_root")]])


## Stalk body (Chest): the pale stalk up into the cap, the dark ragged skirt (ring), dark eye sockets under the brim
## (the eyes: CreatureFaceRig), a beard of pale lichen strands.
static func _chest_mesh() -> Mesh:
	const KEY := "elder_chest_v1"
	if GM.cached(KEY):
		return GM.cached(KEY)
	var stalk := GM.bucket()
	var gills := GM.bucket()
	var lichen := GM.bucket()
	var glow := GM.bucket()
	var lump := func(a: float, _r: float, y: float) -> Vector3:
		return Vector3(1.0 + 0.035 * sin(2.0 * a + y * 4.0) + 0.02 * sin(5.0 * a + y * 2.0), 0.0, 0.0)
	GM.lathe(stalk, PackedVector2Array([Vector2(0.255, 0.74), Vector2(0.246, 0.9), Vector2(0.233, 1.05),
		Vector2(0.219, 1.2), Vector2(0.206, 1.35), Vector2(0.2, 1.46), Vector2(0.16, 1.53)]), 14, Vector3.ZERO, lump)
	# Skirt: bottom -> top so the outside faces out; a zig-zag hem.
	var hem := func(a: float, _r: float, y: float) -> Vector3:
		var low: float = 1.0 - smoothstep(0.83, 0.9, y)
		return Vector3(1.0 + 0.04 * sin(3.0 * a + 2.0), -0.06 * low * (0.5 + 0.5 * cos(a * 9.0)), 0.0)
	GM.lathe(gills, PackedVector2Array([Vector2(0.38, 0.8), Vector2(0.355, 0.88), Vector2(0.3, 0.98),
		Vector2(0.232, 1.05)]), 18, Vector3.ZERO, hem)
	# the dark eye sockets; the faint glowing eyes in them are the Elder's CreatureFaceRig (faces pass 2026-09-28)
	for sx: float in [-1.0, 1.0]:
		GM.ellipsoid(gills, Vector3(0.078 * sx, 1.392, 0.176), Vector3(0.05, 0.047, 0.03), 7, 3)
	# Beard: pale lichen strands hanging from the chin (the elder look close up).
	for k: int in 7:
		var a: float = lerpf(-0.62, 0.62, float(k) / 6.0)
		var st := Vector3(sin(a) * 0.2, 1.335 - 0.012 * absf(a), cos(a) * 0.195)
		var ln: float = 0.30 - 0.1 * absf(a) + 0.03 * sin(float(k) * 2.3)
		var en := st + Vector3(sin(a) * 0.05, -ln, 0.06 + 0.03 * cos(a))
		GM.root(lichen, st, en, 0.04, 0.008, 5, 0.018, float(k) * 1.7, 5)
	return GM.commit(KEY, [[stalk, GM.mat(&"gloomcap_stalk")], [gills, GM.mat(&"gloomcap_gills")],
		[lichen, GM.mat(&"gloomcap_spots")], [glow, GM.mat(&"gloomcap_glow")]])


## Three curled root fingers from a hand point, fanned around `fwd`.
static func _fingers(acc: Array, hand: Vector3, fwd: Vector3, sx: float, ln: float) -> void:
	var side := fwd.cross(Vector3.UP).normalized()
	for k: int in 3:
		var f := (fwd + side * (float(k) - 1.0) * 0.45 + Vector3(0, -0.5, 0)).normalized()
		var tip := hand + f * ln + Vector3(0, -0.02, 0)
		GM.root(acc, hand, tip, 0.034, 0.008, 4, 0.012, float(k) + sx, 5)


## Left arm (ArmL): a gangly root arm with a knobbly shoulder, a root hand, and three baby gloomcaps growing on the
## shoulder.
static func _arm_l_mesh() -> Mesh:
	const KEY := "elder_arm_l_v1"
	if GM.cached(KEY):
		return GM.cached(KEY)
	var rt := GM.bucket()
	var stalk := GM.bucket()
	var cap := GM.bucket()
	var sh := Vector3(-0.2, 1.26, 0.0)
	var el := Vector3(-0.4, 1.03, 0.07)
	var hd := Vector3(-0.52, 0.87, 0.17)
	GM.ellipsoid(rt, sh + Vector3(-0.02, 0.0, 0.0), Vector3(0.085, 0.08, 0.085), 7, 3)
	GM.root(rt, sh, el, 0.074, 0.06, 4, 0.015, 0.4, 6)
	GM.root(rt, el, hd, 0.06, 0.048, 4, 0.015, 2.1, 6)
	GM.ellipsoid(rt, el, Vector3(0.07, 0.07, 0.07), 6, 3)
	GM.ellipsoid(rt, hd, Vector3(0.06, 0.055, 0.065), 6, 3)
	_fingers(rt, hd, Vector3(-0.2, -0.3, 1.0).normalized(), -1.0, 0.15)
	# Baby gloomcaps on the shoulder: [base, height, cap radius].
	for b: Array in [[Vector3(-0.23, 1.31, -0.02), 0.13, 0.065], [Vector3(-0.17, 1.3, 0.05), 0.09, 0.048],
			[Vector3(-0.27, 1.29, 0.04), 0.07, 0.04]]:
		var base: Vector3 = b[0]
		var h: float = b[1]
		var cr: float = b[2]
		var tip := base + Vector3(-0.02, h, 0.01)
		GM.tube(stalk, PackedVector3Array([base, base.lerp(tip, 0.5), tip]), PackedFloat32Array([cr * 0.4, cr * 0.33,
			cr * 0.3]), 5)
		GM.ellipsoid(cap, tip + Vector3(0, cr * 0.25, 0), Vector3(cr, cr * 0.62, cr), 7, 3)
	return GM.commit(KEY, [[rt, GM.mat(&"gloomcap_root")], [stalk, GM.mat(&"gloomcap_stalk")],
		[cap, GM.mat(&"gloomcap_cap")]])


## Right arm (ArmR): the root arm reaching out past the cap rim to its fist, and the gnarled root staff taller than the
## cap: root claws cradle the glowing spore bulb at the top, tendrils splay at its foot.
static func _arm_r_mesh() -> Mesh:
	const KEY := "elder_arm_r_v1"
	if GM.cached(KEY):
		return GM.cached(KEY)
	var rt := GM.bucket()
	var glow := GM.bucket()
	var sh := Vector3(0.2, 1.26, 0.0)
	var el := Vector3(0.47, 1.1, 0.12)
	var hd := Vector3(0.8, 1.0, 0.3)
	GM.ellipsoid(rt, sh + Vector3(0.02, 0.0, 0.0), Vector3(0.085, 0.08, 0.085), 7, 3)
	GM.root(rt, sh, el, 0.074, 0.06, 4, 0.015, 3.3, 6)
	GM.root(rt, el, hd, 0.06, 0.05, 4, 0.012, 1.2, 6)
	GM.ellipsoid(rt, el, Vector3(0.07, 0.07, 0.07), 6, 3)
	# Fist wrapped around the staff.
	GM.ellipsoid(rt, Vector3(0.855, 1.0, 0.335), Vector3(0.075, 0.085, 0.07), 7, 3)
	# The staff: a wandering root, thicker at the foot.
	var foot := Vector3(0.87, 0.0, 0.36)
	var top := Vector3(BULB.x - 0.005, BULB.y - 0.13, BULB.z - 0.01)
	GM.root(rt, foot, top, 0.052, 0.04, 10, 0.03, 0.7, 7)
	GM.ellipsoid(rt, Vector3(0.866, 1.42, 0.35), Vector3(0.06, 0.07, 0.06), 6, 3)
	for d: Vector3 in [Vector3(0.14, 0.015, 0.08), Vector3(-0.1, 0.015, 0.12), Vector3(0.02, 0.015, -0.15)]:
		GM.root(rt, foot + Vector3(0, 0.1, 0), foot + d, 0.035, 0.008, 4, 0.01, d.x * 9.0, 5)
	# Claws around the bulb.
	for k: int in 4:
		var a: float = TAU * float(k) / 4.0 + 0.4
		var out := Vector3(sin(a), 0.0, cos(a))
		var pts := PackedVector3Array([top, top + out * 0.07 + Vector3(0, 0.05, 0), top + out * 0.1 + Vector3(0, 0.14, 0),
			top + out * 0.055 + Vector3(0, 0.23, 0)])
		GM.tube(rt, pts, PackedFloat32Array([0.03, 0.024, 0.017, 0.0]), 5)
	GM.ellipsoid(glow, BULB, Vector3(0.095, 0.105, 0.095), 10, 6)
	return GM.commit(KEY, [[rt, GM.mat(&"gloomcap_root")], [glow, GM.mat(&"gloomcap_glow")]])


## The face (faces pass 2026-09-28): old, heavy-lidded faint-teal glowing eyes in the dark sockets under the brim and
## a pale stalk-grey brow ridge that carries the expression; the mouth hides under the lichen beard. Drawn inside the
## merged Chest (CreatureFaceRig host mode: the Elder keeps its draw instances).
static func face_spec() -> Dictionary:
	return CreatureFaceRig.beast_spec(Vector3(0, 1.392, 0.0), 0.205, {"c": Vector2(0.080, 0.0), "hw": 0.034, "top": 0.020,
		"bot": 0.018, "ir": 0.016, "lash": 1.0, "flick": 0.0}, Color(0.62, 0.58, 0.50), Color(0.42, 0.95, 0.82), 0.7,
		Vector2(0.0, -0.075), {"head_mesh": CharacterModel.sphere(0.205, 14, 7), "lift": 0.012, "preset": &"elder",
		"brow": {"inner": Vector2(0.046, 0.040), "mid": Vector2(0.080, 0.050), "outer": Vector2(0.114, 0.038),
			"w": Vector3(0.008, 0.009, 0.004)},
		"palette": {"sclera": Color(0.10, 0.10, 0.14), "brow": Color(0.40, 0.36, 0.30), "lash": Color(0.12, 0.12, 0.16)}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
