class_name RabbitModel
extends CritterModel
## Rabbit (map-fill.md 3.4 / 10, task 12.V15): the small huntable game critter. A round grey-brown loaf with long
## dark-tipped ears, a pale belly and chin, big hind feet and a bright WHITE TAIL PUFF that pops up when it bolts.
## Scaled up ~1.5 x a real rabbit so it reads from the RTS camera (model_scale 1.15: 0.63 m nose to tail, ears to
## 0.72 m).
## Motion: idle = sits nibbling (fast chewing, ear twitches) and now and then sits up tall on its haunches, ears up,
## to look around; move = little hops (~2 m/s); flee = long bounding bolts with the ears laid flat and the tail up,
## a sideways jink at the start; hit = flinch + white flash; death = a hop-flinch, flops onto its side, hind legs
## kick, still; dissolves 4 s later.
## Budget (map-fill.md 9): <= 300 triangles, 1 material, 0 lights (see tests/test_12_v15.gd).

const MAT_PATH := "res://art/units/neutral/critters/materials/rabbit_mat.tres"

const NECK_PIV := Vector3(0.0, 0.25, 0.09)
const HEAD_PIV := Vector3(0.0, 0.28, 0.13)
const EAR_PIV := Vector3(0.03, 0.355, 0.155)
const FRONT_TOP := Vector3(0.05, 0.17, 0.10)
const THIGH_TOP := Vector3(0.095, 0.20, -0.09)
const HEEL := Vector3(0.105, 0.05, -0.17)
const TAIL_PIV := Vector3(0.0, 0.22, -0.22)

const FUR := Color(0.47, 0.42, 0.36)
const FUR_DARK := Color(0.35, 0.30, 0.25)
const BELLY := Color(0.87, 0.81, 0.71)
const TAIL_WHITE := Color(0.98, 0.97, 0.94)
const EAR_TIP := Color(0.18, 0.14, 0.11)
const EAR_IN := Color(0.82, 0.64, 0.58)
const FOOT := Color(0.70, 0.65, 0.57)
const NOSE := Color(0.46, 0.30, 0.30)
const EYE := Color(0.03, 0.025, 0.02)

static var _mesh_cache: ArrayMesh


func _init() -> void:
	super._init()
	walk_stride = 0.5
	run_stride = 1.15
	run_from = 3.0
	run_full = 4.6
	flee_speed = 6.0
	pose_rate = 9.0
	model_scale = 1.15


func _build_mesh() -> Mesh:
	return build_mesh()


func _anim_aabb() -> AABB:
	return AABB(Vector3(-0.5, -0.3, -0.6), Vector3(1.0, 1.2, 1.2))


# ================================================================ behaviour

## 0 nibble, 1 sit up tall (alert), 2 sit still.
func _idle_mode() -> int:
	if _forced_idle >= 0:
		return _forced_idle
	var k: float = pick(3.6, 1)
	return 0 if k < 0.55 else (1 if k < 0.8 else 2)


func _behave(_dt: float, idle_w: float) -> void:
	var w: float = _walk_w
	var r: float = _run_w
	var mode: int = _idle_mode()
	var nib: float = idle_w if mode == 0 else 0.0
	var alert: float = idle_w if mode == 1 else 0.0
	var still: float = idle_w if mode == 2 else 0.0
	_goal[NECK_P] = nib * 0.45 - alert * 0.25 + still * 0.08 + w * 0.10 + r * 0.22
	_goal[NECK_Y] = alert * (pick(1.3, 5) - 0.5) * 1.2 + still * (pick(2.1, 6) - 0.5) * 0.6
	_goal[HEAD_P] = nib * 0.35 - alert * 0.05 + w * 0.05 + r * 0.10
	_goal[TAIL] = w * 0.3 + r * 0.95
	_goal[EAR_LP] = nib * 0.30 - alert * 0.18 + still * 0.12 + w * 0.40 + r * 1.20
	_goal[EAR_RP] = _goal[EAR_LP] + nib * 0.12
	_goal[EAR_LR] = nib * 0.18 + still * 0.08 + w * 0.05
	_goal[EAR_RR] = nib * 0.10 + still * 0.08 + w * 0.05
	_over[HEAD_P] += nib * 0.05 * sin(_t * 17.0) * (0.6 + 0.4 * sin(_t * 1.3))
	_over[EAR_LP] -= 0.35 * pulse(2.3, 0.14, 11) * idle_w
	_over[EAR_RP] -= 0.35 * pulse(2.9, 0.14, 13) * idle_w
	_over[EAR_LR] += 0.3 * pulse(3.7, 0.18, 29) * idle_w
	_over[TAIL] += 0.5 * pulse(3.1, 0.15, 17) * idle_w
	_over[NECK_P] += (w * 0.08 + r * 0.06) * cos(TAU * (_phase - 0.02))
	# Sitting up tall: the fore paws tuck in under the chest.
	_fold = -clampf(-_pose[NECK_P] / 0.25, 0.0, 1.0) * idle_w
	if _startle_t < STARTLE_LEN:
		var s: float = sin(PI * _startle_t / STARTLE_LEN)
		_over[EAR_LP] -= 0.5 * s
		_over[EAR_RP] -= 0.5 * s
		_over[NECK_P] -= 0.3 * s


func _gait_body() -> Transform3D:
	var p: float = _phase
	var w: float = _walk_w
	var r: float = _run_w
	var idle_w: float = clampf(1.0 - w - r, 0.0, 1.0)
	var hop: float = pow(maxf(0.0, sin(TAU * (p - 0.02))), 0.85)
	var y: float = (w * 0.07 + r * 0.17) * hop
	var pitch: float = -(w * 0.16 + r * 0.24) * cos(TAU * (p - 0.02))
	var alert: float = clampf(-_pose[NECK_P] / 0.25, 0.0, 1.0) * idle_w
	var yaw: float = 0.0
	if _startle_t < STARTLE_LEN:
		var s: float = sin(PI * _startle_t / STARTLE_LEN)
		y += 0.09 * s
		yaw = 0.45 * s * (1.0 if (_seed / 3) % 2 == 0 else -1.0)
	# Squash on landing, stretch in the air.
	var st: float = (w + r) * 0.10 * sin(TAU * (p - 0.02))
	var sc := Basis.from_scale(Vector3(1.0 - st * 0.4, 1.0 - st * 0.3, 1.0 + st))
	var gait := about(Vector3(0.0, 0.0, -0.05), Basis.from_euler(Vector3(pitch, yaw, 0.0)) * sc, Vector3(0.0, y, 0.0))
	var sit_up := about(Vector3(0.0, 0.03, -0.18), Basis.from_euler(Vector3(-0.62 * alert, 0.0, 0.0)))
	return gait * sit_up


## Death (~0.4 s flop, kicks until ~1.3 s).
func _death_body(t: float) -> Transform3D:
	var jump: float = sin(PI * clampf(t / 0.22, 0.0, 1.0)) * 0.08
	var fall: float = ease_in((t - 0.10) / 0.28)
	var side: float = _fall_side
	_goal[NECK_P] = -0.35 * (1.0 - fall) + 0.1 * fall
	_goal[NECK_Y] = 0.0
	_goal[HEAD_P] = 0.1 * fall
	_goal[TAIL] = 0.0
	_goal[EAR_LP] = 1.1 * fall
	_goal[EAR_RP] = 1.0 * fall
	_goal[EAR_LR] = 0.0
	_goal[EAR_RR] = 0.0
	_fold = fall
	_kick = 0.0
	if t > 0.38 and t < 1.4:
		_kick = 0.7 * exp(-(t - 0.38) * 4.0)
	_kick_phase = fposmod(t * 4.5, 1.0)
	var sink: float = 0.04 * _dissolve
	return about(Vector3(-0.09 * side, 0.0, 0.0), Basis.from_euler(Vector3(0.0, 0.0, 1.5 * side * fall)),
		Vector3(0.18 * side * fall, jump * (1.0 - fall) + 0.06 * fall - sink, 0.0))


# ================================================================ mesh (static, built once)

static func build_mesh() -> ArrayMesh:
	if _mesh_cache != null:
		return _mesh_cache
	var b := CritterMeshBuilder.new()
	# Body: a round loaf, the haunches the widest part.
	b.set_bones([])
	b.set_paint(func(p: Vector3, nr: Vector3) -> Color:
		var c := CritterMeshBuilder.mixc(FUR, FUR_DARK, smoothstep(0.55, 0.9, nr.y))
		c = CritterMeshBuilder.mixc(c, BELLY, smoothstep(-0.25, -0.6, nr.y))
		c = CritterMeshBuilder.mixc(c, BELLY, smoothstep(0.08, 0.15, p.z) * smoothstep(0.3, -0.3, nr.y))
		return CritterMeshBuilder.mixc(c, TAIL_WHITE, smoothstep(-0.2, -0.25, p.z) * 0.5))
	b.loft([Vector3(0, 0.19, -0.25), Vector3(0, 0.20, -0.18), Vector3(0, 0.205, -0.06), Vector3(0, 0.21, 0.07),
		Vector3(0, 0.22, 0.155)] as Array[Vector3], [0.06, 0.14, 0.15, 0.115, 0.05] as Array[float],
		[0.06, 0.15, 0.155, 0.13, 0.06] as Array[float], 8, true, true)
	# Head: round skull, short muzzle, pink nose; big dark eyes.
	b.set_bones([[B_HEAD, HEAD_PIV], [B_NECK, NECK_PIV]])
	b.set_paint(func(p: Vector3, nr: Vector3) -> Color:
		var c := CritterMeshBuilder.mixc(FUR, BELLY, smoothstep(-0.2, -0.6, nr.y))
		return CritterMeshBuilder.mixc(c, NOSE, smoothstep(0.27, 0.30, p.z) * smoothstep(0.3, 0.7, nr.z)))
	b.loft([Vector3(0, 0.285, 0.10), Vector3(0, 0.315, 0.155), Vector3(0, 0.31, 0.215), Vector3(0, 0.29, 0.265)]
		as Array[Vector3], [0.055, 0.075, 0.07, 0.045] as Array[float], [0.055, 0.072, 0.066, 0.042] as Array[float], 7,
		false, true)
	b.set_paint(func(_p: Vector3, _n: Vector3) -> Color: return EYE)
	for s: float in [-1.0, 1.0]:
		b.ellipsoid(Vector3(0.068 * s, 0.33, 0.195), Vector3(0.018, 0.022, 0.022), 4, 2)
	# Ears: long, upright, dark tips, pink inside.
	for s: float in [1.0, -1.0]:
		var piv := Vector3(EAR_PIV.x * s, EAR_PIV.y, EAR_PIV.z)
		b.set_bones([[B_EAR_L if s > 0.0 else B_EAR_R, piv], [B_HEAD, HEAD_PIV], [B_NECK, NECK_PIV]])
		b.set_paint(func(p: Vector3, nr: Vector3) -> Color:
			var c := CritterMeshBuilder.mixc(FUR, EAR_IN, smoothstep(0.3, 0.8, nr.z) * smoothstep(0.62, 0.45, p.y))
			return CritterMeshBuilder.mixc(c, EAR_TIP, smoothstep(0.54, 0.60, p.y)))
		b.loft([piv, Vector3(0.042 * s, 0.46, 0.13), Vector3(0.052 * s, 0.56, 0.11), Vector3(0.056 * s, 0.63, 0.10)]
			as Array[Vector3], [0.026, 0.04, 0.033, 0.0] as Array[float], [0.013, 0.016, 0.013, 0.0] as Array[float], 4)
	# Legs: thighs + long hind feet, thin fore legs.
	for i: int in 4:
		var s: float = 1.0 if i % 2 == 0 else -1.0
		var m := Vector3(s, 1.0, 1.0)
		if i < 2:
			b.set_bones([[B_UP + i, FRONT_TOP * m]])
			b.set_paint(func(p: Vector3, _n: Vector3) -> Color:
				return CritterMeshBuilder.mixc(FUR, FOOT, smoothstep(0.10, 0.04, p.y)))
			b.tube([Vector3(0.055, 0.17, 0.10) * m, Vector3(0.055, 0.012, 0.115) * m] as Array[Vector3],
				[0.03, 0.024] as Array[float], 4)
		else:
			b.set_bones([[B_UP + i, THIGH_TOP * m]])
			b.set_paint(func(_p: Vector3, nr: Vector3) -> Color:
				return CritterMeshBuilder.mixc(FUR, FUR_DARK, smoothstep(0.5, 0.9, nr.y) * 0.7))
			b.ellipsoid(Vector3(0.095, 0.13, -0.11) * m, Vector3(0.045, 0.085, 0.10), 6, 3)
			b.set_bones([[B_LO + i, HEEL * m], [B_UP + i, THIGH_TOP * m]])
			b.set_paint(func(_p: Vector3, nr: Vector3) -> Color:
				return CritterMeshBuilder.mixc(FUR, FOOT, smoothstep(0.2, -0.5, nr.y)))
			b.loft([Vector3(0.085, 0.036, -0.21) * m, Vector3(0.09, 0.026, -0.05) * m] as Array[Vector3],
				[0.036, 0.03] as Array[float], [0.036, 0.024] as Array[float], 4, true, true)
	# Tail: the white puff.
	b.set_bones([[B_TAIL, TAIL_PIV]])
	b.set_paint(func(_p: Vector3, _n: Vector3) -> Color: return TAIL_WHITE)
	b.ellipsoid(Vector3(0.0, 0.215, -0.26), Vector3(0.05, 0.05, 0.044), 4, 3)
	_mesh_cache = b.commit(load(MAT_PATH) as Material)
	return _mesh_cache
