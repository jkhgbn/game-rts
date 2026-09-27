class_name CritterModel
extends Node3D
## Base model of the huntable game critters (map-fill.md 3.4 / 10, task 12.V15). Subclasses: deer.gd, rabbit.gd.
## The model is ONE MeshInstance3D ("Mesh", one material, 0 lights) animated by critter_painted.gdshader's vertex rig:
## the script only moves the Mesh node (bounce / pitch / roll / the fall) and writes 3 vec4 + 3 float instance
## uniforms per frame. The model faces +Z and never moves its own root (GameCritter moves / turns its parent).
##
## Hooks (GameCritter, 12.C8; all safe before _ready and after death):
##   play_idle()               graze / sit, look around, ear and tail flicks
##   play_move(speed: float)   walk (deer trot / rabbit hop) at `speed` m/s; fast speeds blend into the flee run;
##                             0 = play_idle()
##   play_flee()               startle + flee run at `flee_speed` (deer tail up shows the white rump, ears back);
##                             the next play_move / play_idle ends it
##   play_hit()                flinch + white flash (keeps the current gait)
##   play_death()              falls (~1 s), lies still, dissolves from 4.0 s to 4.8 s after the call, then hides
##                             the mesh and emits `death_finished` once
##   revive()                  back to a standing idle (respawn reuse)
## Read-only: is_dead(), state() (&"idle", &"move", &"flee", &"dead"), death_time(), dissolve_amount(),
##   triangle_count(), gait_phase().
## Cost: no nodes but the Mesh; hidden (fog) = no work except the death timer; beyond `lod_distance` from the camera
## it updates at 15 Hz.

signal death_finished

const DEATH_HOLD := 4.0
const FADE_LEN := 0.8
const HIT_LEN := 0.32
const FLASH_LEN := 0.16
const STARTLE_LEN := 0.35
const FAR_STEP := 1.0 / 15.0
# Pose channels (smoothed toward their goals): neck pitch, neck yaw, head pitch, tail, ear L pitch, ear R pitch,
# ear L roll, ear R roll.
const NECK_P := 0
const NECK_Y := 1
const HEAD_P := 2
const TAIL := 3
const EAR_LP := 4
const EAR_RP := 5
const EAR_LR := 6
const EAR_RR := 7
const CH := 8
# Bone ids of critter_painted.gdshader (the mesh builders tag vertices with them).
const B_BODY := 0
const B_NECK := 1
const B_HEAD := 2
const B_EAR_L := 3
const B_EAR_R := 4
const B_UP := 5        # + leg index (0 FL, 1 FR, 2 BL, 3 BR; left = +X)
const B_LO := 9        # + leg index
const B_TAIL := 13

## Metres per gait cycle at the walk / at the run (the phase advances speed / stride per second).
@export var walk_stride: float = 1.8
@export var run_stride: float = 3.4
## Speed (m/s) where the run starts blending in / is complete.
@export var run_from: float = 4.2
@export var run_full: float = 5.6
## Gait speed of play_flee() (map-fill.md 3.4).
@export var flee_speed: float = 7.0
## Beyond this camera distance (m) the model updates at 15 Hz.
@export var lod_distance: float = 60.0
## How fast pose channels follow their goals (1/s).
@export var pose_rate: float = 7.0
## Uniform scale of the whole model (the rig works in unscaled model space).
@export var model_scale: float = 1.0

var _mesh: MeshInstance3D
var _state: StringName = &"idle"
var _speed: float = 0.0
var _spd: float = 0.0
var _phase: float = 0.0
var _walk_w: float = 0.0
var _run_w: float = 0.0
var _t: float = 0.0
var _hit_t: float = 99.0
var _startle_t: float = 99.0
var _death_t: float = -1.0
var _fall_side: float = 1.0
var _finished: bool = false
var _dissolve: float = 0.0
var _fold: float = 0.0
var _kick: float = 0.0
var _kick_phase: float = 0.0
var _pose := PackedFloat32Array()
var _goal := PackedFloat32Array()
var _over := PackedFloat32Array()     # per-frame additive overlay (chewing, flicks, flinch), not smoothed
var _seed: int = 0
var _far: bool = false
var _offscreen: bool = false
var _far_acc: float = 0.0
var _last_flash: float = -1.0
var _last_dissolve: float = -1.0
var _forced_idle: int = -1
var _cam_check: float = 0.0
var _body_xf := Transform3D.IDENTITY
var _pending: Array = []              # hook calls made before _ready


func _init() -> void:
	_pose.resize(CH)
	_goal.resize(CH)
	_over.resize(CH)


func _ready() -> void:
	_mesh = get_node_or_null(^"Mesh") as MeshInstance3D
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Mesh"
		add_child(_mesh)
	_mesh.mesh = _build_mesh()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mesh.custom_aabb = _anim_aabb()
	_seed = absi(hash(get_instance_id()))
	_t = float(_seed % 1000) * 0.037
	_on_ready()
	_rest_pose()
	for p: Array in _pending:
		callv(p[0], p[1])
	_pending.clear()
	_update(0.0)


# ================================================================ hooks

func play_idle() -> void:
	if _defer(&"play_idle", []):
		return
	if _state == &"dead":
		return
	_state = &"idle"
	_speed = 0.0


func play_move(speed: float) -> void:
	if _defer(&"play_move", [speed]):
		return
	if _state == &"dead":
		return
	if speed <= 0.05:
		play_idle()
		return
	_state = &"move"
	_speed = speed


func play_flee() -> void:
	if _defer(&"play_flee", []):
		return
	if _state == &"dead":
		return
	if _state != &"flee":
		_startle_t = 0.0
	_state = &"flee"
	_speed = flee_speed


func play_hit() -> void:
	if _defer(&"play_hit", []):
		return
	if _state == &"dead":
		return
	_hit_t = 0.0


func play_death() -> void:
	if _defer(&"play_death", []):
		return
	if _state == &"dead":
		return
	_state = &"dead"
	_speed = 0.0
	_death_t = 0.0
	_finished = false
	_hit_t = 0.0
	_fall_side = 1.0 if (_seed / 7) % 2 == 0 else -1.0
	_kick_phase = _phase


func revive() -> void:
	if _defer(&"revive", []):
		return
	_state = &"idle"
	_speed = 0.0
	_spd = 0.0
	_walk_w = 0.0
	_run_w = 0.0
	_death_t = -1.0
	_finished = false
	_dissolve = 0.0
	_fold = 0.0
	_kick = 0.0
	_hit_t = 99.0
	_startle_t = 99.0
	_last_flash = -1.0
	_last_dissolve = -1.0
	_mesh.visible = true
	_rest_pose()
	_on_revive()
	_update(0.0)


func is_dead() -> bool:
	return _state == &"dead"


func state() -> StringName:
	return _state


## Seconds since play_death() (-1 while alive).
func death_time() -> float:
	return _death_t


func dissolve_amount() -> float:
	return _dissolve


func gait_phase() -> float:
	return _phase


## Previews / cinematics: pins the idle behaviour (deer 0 graze, 1 look around; rabbit 0 nibble, 1 sit up tall,
## 2 sit still); -1 = automatic (default).
func set_idle_mode(mode: int) -> void:
	_forced_idle = mode


func triangle_count() -> int:
	if _mesh == null or _mesh.mesh == null:
		return 0
	var total: int = 0
	var m: Mesh = _mesh.mesh
	for s: int in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		total += ix.size() / 3
	return total


func _defer(method: StringName, args: Array) -> bool:
	if _mesh != null:
		return false
	_pending.append([method, args])
	return true


# ================================================================ subclass hooks

## The cached mesh of the kind (static per kind).
func _build_mesh() -> Mesh:
	return null


## Local AABB covering every pose (so the vertex rig never gets culled).
func _anim_aabb() -> AABB:
	return AABB(Vector3(-1.5, -0.5, -1.5), Vector3(3.0, 3.5, 3.0))


func _on_ready() -> void:
	pass


func _on_revive() -> void:
	pass


## Sets _goal (alive: idle / move / flee blend) and _over; `idle_w`, `walk_w`, `run_w` are the gait weights.
func _behave(_dt: float, _idle_w: float) -> void:
	pass


## Mesh transform from the gait (alive).
func _gait_body() -> Transform3D:
	return Transform3D.IDENTITY


## Death pose at `t` s: sets _goal / _over, _fold, _kick and returns the Mesh transform.
func _death_body(_t_dead: float) -> Transform3D:
	return Transform3D.IDENTITY


# ================================================================ per frame

func _process(dt: float) -> void:
	if _mesh == null:
		return
	if _state == &"dead" and not _finished:
		_death_t += dt
		if _death_t >= DEATH_HOLD + FADE_LEN:
			_finish_death()
			return
	if not is_visible_in_tree() or (_finished and _state == &"dead"):
		return
	_cam_check -= dt
	if _cam_check <= 0.0:
		_cam_check = 0.25
		_check_camera()
	if _offscreen:
		return
	if _far:
		_far_acc += dt
		if _far_acc < FAR_STEP:
			return
		dt = _far_acc
		_far_acc = 0.0
	_update(dt)


## Off screen (with a 25 % margin) = frozen; far = 15 Hz. Checked 4 times a second.
func _check_camera() -> void:
	var vp := get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp else null
	if cam == null:
		_offscreen = false
		_far = false
		return
	var p: Vector3 = global_position + Vector3(0.0, 0.5, 0.0)
	_far = cam.global_position.distance_to(p) > lod_distance
	if cam.is_position_behind(p):
		_offscreen = true
		return
	var sp: Vector2 = cam.unproject_position(p)
	var size: Vector2 = vp.get_visible_rect().size
	_offscreen = sp.x < -size.x * 0.25 or sp.y < -size.y * 0.25 or sp.x > size.x * 1.25 or sp.y > size.y * 1.25


func _finish_death() -> void:
	_finished = true
	_dissolve = 1.0
	_mesh.visible = false
	death_finished.emit()


func _update(dt: float) -> void:
	_t += dt
	_hit_t += dt
	_startle_t += dt
	var moving: bool = _state == &"move" or _state == &"flee"
	var target: float = _speed if moving else 0.0
	var run_target: float = smoothstep(run_from, run_full, target) if target > 0.05 else 0.0
	var walk_target: float = (1.0 - run_target) if target > 0.05 else 0.0
	_walk_w = move_toward(_walk_w, walk_target, dt * 3.5)
	_run_w = move_toward(_run_w, run_target, dt * 3.5)
	_spd = lerpf(_spd, target, 1.0 - exp(-dt * 6.0))
	var gw: float = _walk_w + _run_w
	var stride: float = lerpf(walk_stride, run_stride, _run_w / gw) if gw > 0.001 else walk_stride
	_phase = fposmod(_phase + maxf(_spd, 0.6 * gw) / stride * dt, 1.0)
	for i: int in CH:
		_over[i] = 0.0
	if _state == &"dead":
		_body_xf = _death_body(_death_t)
		_dissolve = clampf((_death_t - DEATH_HOLD) / FADE_LEN, 0.0, 1.0)
	else:
		_behave(dt, clampf(1.0 - gw, 0.0, 1.0))
		_body_xf = _gait_body()
	var k: float = 1.0 - exp(-dt * pose_rate)
	for i: int in CH:
		_pose[i] = lerpf(_pose[i], _goal[i], k)
	# Hit flinch: head jerks up, ears back, the body shoves back and wobbles.
	var hk: float = 0.0
	if _hit_t < HIT_LEN:
		hk = sin(PI * _hit_t / HIT_LEN)
		_over[NECK_P] -= 0.30 * hk
		_over[HEAD_P] -= 0.15 * hk
		_over[EAR_LP] += 0.7 * hk
		_over[EAR_RP] += 0.7 * hk
		_over[TAIL] += 0.6 * hk
		var wob: float = sin(_hit_t * 38.0) * (1.0 - _hit_t / HIT_LEN)
		_body_xf = _body_xf * Transform3D(Basis.from_euler(Vector3(-0.06 * hk, 0.0, 0.07 * wob)),
			Vector3(0.0, -0.03 * hk, -0.06 * hk))
	_mesh.transform = _body_xf.scaled(Vector3.ONE * model_scale) if model_scale != 1.0 else _body_xf
	var flash: float = 0.0
	if _hit_t < FLASH_LEN:
		flash = 0.6 * (1.0 - _hit_t / FLASH_LEN)
	_write(flash)


func _write(flash: float) -> void:
	var p: PackedFloat32Array = _pose
	var o: PackedFloat32Array = _over
	var gait_w: float = _walk_w
	var gait_p: float = _phase
	if _state == &"dead":
		gait_w = _kick
		gait_p = _kick_phase
	_mesh.set_instance_shader_parameter(&"gait", Vector4(gait_p, gait_w, _run_w if _state != &"dead" else 0.0, _fold))
	_mesh.set_instance_shader_parameter(&"head_pose", Vector4(p[NECK_P] + o[NECK_P], p[NECK_Y] + o[NECK_Y],
		p[HEAD_P] + o[HEAD_P], p[TAIL] + o[TAIL]))
	_mesh.set_instance_shader_parameter(&"ear_pose", Vector4(p[EAR_LP] + o[EAR_LP], p[EAR_RP] + o[EAR_RP],
		p[EAR_LR] + o[EAR_LR], p[EAR_RR] + o[EAR_RR]))
	if flash != _last_flash:
		_last_flash = flash
		_mesh.set_instance_shader_parameter(&"hit_flash", flash)
	if _dissolve != _last_dissolve:
		_last_dissolve = _dissolve
		_mesh.set_instance_shader_parameter(&"dissolve", _dissolve)


func _rest_pose() -> void:
	for i: int in CH:
		_pose[i] = 0.0
		_goal[i] = 0.0
		_over[i] = 0.0


# ================================================================ helpers for subclasses

## A 0-1 pulse that fires about every `every` s (random per animal), lasting `len` s: for flicks and twitches.
func pulse(every: float, length: float, salt: int) -> float:
	var period: float = every * (0.7 + 0.6 * float((_seed / (salt + 3)) % 100) / 100.0)
	var local: float = fposmod(_t + float((_seed * (salt + 1)) % 997) * 0.13, period)
	if local > length:
		return 0.0
	return sin(PI * local / length)


## Deterministic 0-1 value that changes every `period` s (per animal), for idle choices.
func pick(period: float, salt: int) -> float:
	var slot: int = int(floor((_t + float(salt) * 1.7) / period))
	return float(absi(hash(slot * 7919 + _seed + salt * 131)) % 1000) / 1000.0


## Rotation about an axis through `pivot` (model space), then `offset`.
static func about(pivot: Vector3, rot: Basis, offset: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(rot, pivot - rot * pivot + offset)


static func ease_in(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x


static func ease_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - (1.0 - x) * (1.0 - x)
