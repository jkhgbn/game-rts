class_name DeerModel
extends CritterModel
## Red deer stag (map-fill.md 3.4 / 10, task 12.V15): the huntable game deer. Slim, long-legged, a warm red-brown coat
## with a dark maned neck, a buff belly and a bright WHITE RUMP PATCH around a pale tail, a dark muzzle and big
## pale-tipped antlers (brow, bez and trez tines + a crown fork). Reads apart from the Hollow Stag (12.V23: huge,
## pale, glowing leaves in bare-branch antlers, hollow glowing chest) by colour (brown, no glow) and size (1.2 m at
## the withers, ~2.6 m to the antler tips, ~1.9 m nose to tail).
## Motion: idle = grazing (neck down, chewing, tail and ear flicks) alternating with head-up looks around; move = a
## light trot (~3 m/s graze moves); flee = a bounding gallop with the neck stretched, ears back and the tail raised
## over the white rump (the classic warning flag); hit = flinch + white flash; death = the hind legs buckle, it
## topples onto its side, two kicks, still; dissolves 4 s later.
## Budget (map-fill.md 9): <= 1 200 triangles, 1 material, 0 lights (see tests/test_12_v15.gd).

const MAT_PATH := "res://art/units/neutral/critters/materials/deer_mat.tres"

const NECK_PIV := Vector3(0.0, 1.08, 0.48)
const HEAD_PIV := Vector3(0.0, 1.60, 0.76)
const EAR_PIV := Vector3(0.075, 1.72, 0.76)
const SHOULDER := Vector3(0.14, 1.02, 0.42)
const KNEE := Vector3(0.14, 0.52, 0.45)
const HIP := Vector3(0.13, 1.05, -0.48)
const HOCK := Vector3(0.13, 0.52, -0.62)
const TAIL_PIV := Vector3(0.0, 1.14, -0.70)

## Idle grazing pose (rad): neck pitch, head pitch.
const GRAZE_NECK := 2.1
const GRAZE_HEAD := -0.75

# Colour blocks (sRGB).
const COAT := Color(0.50, 0.28, 0.15)
const COAT_DARK := Color(0.37, 0.20, 0.11)
const BELLY := Color(0.76, 0.62, 0.45)
const MANE := Color(0.26, 0.16, 0.10)
const LEG := Color(0.36, 0.26, 0.18)
const HOOF := Color(0.08, 0.06, 0.05)
const RUMP := Color(0.97, 0.94, 0.86)
const TAIL_TOP := Color(0.80, 0.64, 0.46)
const MUZZLE := Color(0.24, 0.19, 0.16)
const NOSE := Color(0.05, 0.04, 0.04)
const EYE := Color(0.03, 0.025, 0.02)
const EAR_IN := Color(0.84, 0.72, 0.60)
const ANTLER_BASE := Color(0.34, 0.25, 0.16)
const ANTLER_TIP := Color(0.96, 0.92, 0.80)

## false = a hind (no antlers): a lighter variant for herds; the stag is the default.
@export var antlers: bool = true

static var _meshes: Dictionary = {}


func _init() -> void:
	super._init()
	walk_stride = 1.9
	run_stride = 3.6
	run_from = 4.0
	run_full = 5.8
	flee_speed = 7.0
	pose_rate = 4.5


func _build_mesh() -> Mesh:
	return build_mesh(antlers)


func _anim_aabb() -> AABB:
	return AABB(Vector3(-1.3, -0.6, -1.5), Vector3(2.6, 3.6, 3.2))


# ================================================================ behaviour

func _behave(_dt: float, idle_w: float) -> void:
	var w: float = _walk_w
	var r: float = _run_w
	var grazing: bool = (_forced_idle == 0) if _forced_idle >= 0 else pick(6.5, 1) < 0.62
	var look: float = (pick(2.6, 2) - 0.5) * 1.4
	var g: float = idle_w if grazing else 0.0
	_goal[NECK_P] = idle_w * (GRAZE_NECK if grazing else -0.12) + w * 0.28 + r * 0.62
	_goal[NECK_Y] = idle_w * (0.10 if grazing else look)
	_goal[HEAD_P] = idle_w * (GRAZE_HEAD if grazing else -0.06) + w * 0.12 + r * 0.30
	_goal[TAIL] = r * 1.55
	_goal[EAR_LP] = idle_w * (0.30 if grazing else -0.20) + w * 0.10 + r * 0.95
	_goal[EAR_RP] = _goal[EAR_LP]
	var turn: float = (1.0 - g) * idle_w * look * 0.35
	_goal[EAR_LR] = idle_w * (0.05 if grazing else 0.15) + turn
	_goal[EAR_RR] = idle_w * (0.05 if grazing else 0.15) - turn
	# Overlays: chewing, flicks, the gait's head bob, the flee startle.
	var chew: float = g * 0.06 * sin(_t * 8.5)
	_over[HEAD_P] += chew
	_over[EAR_LP] += 0.55 * pulse(3.4, 0.22, 11) * idle_w
	_over[EAR_RP] += 0.55 * pulse(4.1, 0.22, 13) * idle_w
	_over[EAR_LR] += 0.25 * pulse(5.3, 0.3, 19) * idle_w
	_over[TAIL] += 0.9 * pulse(4.6, 0.35, 17) * idle_w + 0.5 * pulse(2.2, 0.2, 23) * w
	_over[NECK_P] += w * 0.05 * sin(TAU * 2.0 * _phase) + r * 0.10 * sin(TAU * (_phase - 0.35))
	_over[HEAD_P] -= r * 0.06 * sin(TAU * (_phase - 0.35))
	if _startle_t < STARTLE_LEN:
		var s: float = sin(PI * _startle_t / STARTLE_LEN)
		_over[NECK_P] -= 0.55 * s
		_over[EAR_LP] -= 0.4 * s
		_over[EAR_RP] -= 0.4 * s


func _gait_body() -> Transform3D:
	var p: float = _phase
	var w: float = _walk_w
	var r: float = _run_w
	var idle_w: float = clampf(1.0 - w - r, 0.0, 1.0)
	var graze: float = clampf(_pose[NECK_P] / GRAZE_NECK, 0.0, 1.0) * idle_w
	var y: float = w * 0.035 * (0.5 + 0.5 * cos(TAU * 2.0 * p)) + r * 0.11 * (0.5 + 0.5 * cos(TAU * (p - 0.8)))
	var pitch: float = -r * 0.10 * cos(TAU * (p - 0.15)) + graze * 0.07
	var roll: float = w * 0.025 * sin(TAU * p)
	if _startle_t < STARTLE_LEN:
		var s: float = sin(PI * _startle_t / STARTLE_LEN)
		y += 0.10 * s
		pitch -= 0.10 * s
	return about(Vector3(0.0, 0.0, -0.55), Basis.from_euler(Vector3(pitch, 0.0, roll)), Vector3(0.0, y, 0.0))


## Death (the fall ~0.75 s, kicks until ~1.6 s): hind legs buckle, a head toss, then it topples onto its side.
func _death_body(t: float) -> Transform3D:
	var buckle: float = ease_out(t / 0.28)
	var fall: float = ease_in((t - 0.22) / 0.5)
	var side: float = _fall_side
	_goal[NECK_P] = -0.55 * buckle * (1.0 - fall) - 0.30 * fall
	_goal[NECK_Y] = 0.0
	_goal[HEAD_P] = 0.35 * fall
	_goal[TAIL] = 0.0
	_goal[EAR_LP] = 0.9 * fall
	_goal[EAR_RP] = 0.9 * fall
	_goal[EAR_LR] = 0.0
	_goal[EAR_RR] = 0.0
	_fold = fall
	_kick = 0.0
	if t > 0.72:
		_kick = 0.5 * exp(-(t - 0.72) * 3.2) * (1.0 if t < 1.8 else 0.0)
	_kick_phase = fposmod(t * 2.6, 1.0)
	var land: float = 0.0
	if t > 0.72:
		land = 0.045 * sin((t - 0.72) * 18.0) * exp(-(t - 0.72) * 7.0)
	var sink: float = 0.10 * _dissolve
	# 1: the rear sinks on buckling hind legs (pitch about the fore hooves).
	var pre := about(Vector3(0.0, 0.0, 0.46), Basis.from_euler(Vector3(-0.16 * buckle * (1.0 - fall), 0.0, 0.0)),
		Vector3(0.0, -0.10 * buckle * (1.0 - fall), 0.0))
	# 2: the topple about the hooves of the falling side.
	var roll := about(Vector3(-0.14 * side, 0.0, 0.0), Basis.from_euler(Vector3(0.0, 0.0, 1.50 * side * fall)),
		Vector3(0.62 * side * fall, 0.13 * fall + land - sink, 0.0))
	return roll * pre


# ================================================================ mesh (static, built once per variant)

static func build_mesh(with_antlers: bool = true) -> ArrayMesh:
	var key := "stag" if with_antlers else "hind"
	if _meshes.has(key):
		return _meshes[key]
	var b := CritterMeshBuilder.new()
	_add_body(b)
	_add_neck_head(b)
	if with_antlers:
		_add_antlers(b)
	for i: int in 4:
		_add_leg(b, i)
	_add_tail(b)
	var am := b.commit(load(MAT_PATH) as Material)
	_meshes[key] = am
	return am


static func _body_paint(p: Vector3, nr: Vector3) -> Color:
	var c := COAT
	c = CritterMeshBuilder.mixc(c, COAT_DARK, smoothstep(0.72, 0.95, nr.y))
	c = CritterMeshBuilder.mixc(c, BELLY, smoothstep(-0.30, -0.70, nr.y))
	# Dark shaggy chest / mane base in front.
	c = CritterMeshBuilder.mixc(c, MANE, smoothstep(0.40, 0.58, p.z) * smoothstep(0.35, -0.2, nr.y) * 0.8)
	# The white rump patch: the back of the haunches, around the tail.
	var rump: float = smoothstep(-0.48, -0.62, p.z) * smoothstep(0.78, 0.92, p.y) * smoothstep(0.5, -0.1, nr.z + 0.6)
	rump = maxf(rump, smoothstep(-0.60, -0.70, p.z) * smoothstep(0.70, 0.85, p.y))
	return CritterMeshBuilder.mixc(c, RUMP, rump)


static func _add_body(b: CritterMeshBuilder) -> void:
	b.set_bones([])
	b.set_weight(Callable())
	b.set_paint(func(p: Vector3, nr: Vector3) -> Color: return _body_paint(p, nr))
	var zs: Array[float] = [-0.74, -0.70, -0.62, -0.52, -0.40, -0.20, 0.0, 0.20, 0.38, 0.52, 0.62]
	var cy: Array[float] = [1.00, 1.00, 1.00, 0.99, 0.98, 0.96, 0.96, 0.98, 1.00, 1.00, 0.99]
	var rx: Array[float] = [0.07, 0.14, 0.19, 0.21, 0.215, 0.21, 0.21, 0.22, 0.22, 0.19, 0.12]
	var ry: Array[float] = [0.08, 0.17, 0.21, 0.23, 0.235, 0.23, 0.235, 0.26, 0.27, 0.25, 0.16]
	var c: Array[Vector3] = []
	for i: int in zs.size():
		c.append(Vector3(0.0, cy[i], zs[i]))
	b.loft(c, rx, ry, 12, true, true)


static func _add_neck_head(b: CritterMeshBuilder) -> void:
	# Neck: thick and maned (dark throat ruff), bending smoothly out of the chest.
	b.set_bones([[B_NECK, NECK_PIV]])
	b.set_weight(func(p: Vector3) -> float: return smoothstep(1.02, 1.30, p.y))
	b.set_paint(func(p: Vector3, nr: Vector3) -> Color:
		var c := CritterMeshBuilder.mixc(COAT, MANE, smoothstep(-0.1, 0.45, nr.z - nr.y * 0.4))
		return CritterMeshBuilder.mixc(c, COAT_DARK, smoothstep(0.5, 0.9, -nr.z) * 0.6))
	b.loft([Vector3(0, 1.00, 0.38), Vector3(0, 1.17, 0.51), Vector3(0, 1.33, 0.62), Vector3(0, 1.47, 0.69),
		Vector3(0, 1.60, 0.75)] as Array[Vector3], [0.16, 0.17, 0.15, 0.125, 0.105] as Array[float],
		[0.20, 0.24, 0.19, 0.145, 0.11] as Array[float], 10)
	# Head: a long, fine wedge; dark muzzle and nose, pale chin.
	b.set_bones([[B_HEAD, HEAD_PIV], [B_NECK, NECK_PIV]])
	b.set_weight(Callable())
	b.set_paint(func(p: Vector3, nr: Vector3) -> Color:
		var c := CritterMeshBuilder.mixc(COAT, BELLY, smoothstep(-0.4, -0.8, nr.y) * 0.8)
		c = CritterMeshBuilder.mixc(c, MUZZLE, smoothstep(1.02, 1.10, p.z))
		return CritterMeshBuilder.mixc(c, NOSE, smoothstep(1.14, 1.18, p.z) * smoothstep(0.2, 0.6, nr.z)))
	b.loft([Vector3(0, 1.63, 0.72), Vector3(0, 1.68, 0.80), Vector3(0, 1.66, 0.90), Vector3(0, 1.60, 1.01),
		Vector3(0, 1.54, 1.10), Vector3(0, 1.50, 1.17)] as Array[Vector3],
		[0.075, 0.10, 0.095, 0.075, 0.062, 0.05] as Array[float],
		[0.075, 0.10, 0.09, 0.072, 0.06, 0.045] as Array[float], 10, true, true)
	b.set_paint(func(_p: Vector3, _n: Vector3) -> Color: return EYE)
	for s: float in [-1.0, 1.0]:
		b.ellipsoid(Vector3(0.088 * s, 1.69, 0.90), Vector3(0.024, 0.028, 0.032), 4, 2)
	# Ears: big leaves sticking out to the sides, pale inside, dark rims.
	for s: float in [1.0, -1.0]:
		var piv := Vector3(EAR_PIV.x * s, EAR_PIV.y, EAR_PIV.z)
		b.set_bones([[B_EAR_L if s > 0.0 else B_EAR_R, piv], [B_HEAD, HEAD_PIV], [B_NECK, NECK_PIV]])
		var d := Vector3(0.78 * s, 0.50, -0.38).normalized()
		b.set_paint(func(p: Vector3, nr: Vector3) -> Color:
			var along: float = (p - piv).dot(d)
			var c := CritterMeshBuilder.mixc(COAT, EAR_IN, smoothstep(0.1, 0.6, nr.z))
			return CritterMeshBuilder.mixc(c, MANE, smoothstep(0.15, 0.21, along)))
		var pts: Array[Vector3] = [piv, piv + d * 0.07, piv + d * 0.15, piv + d * 0.23]
		b.loft(pts, [0.035, 0.058, 0.048, 0.0] as Array[float], [0.02, 0.024, 0.02, 0.0] as Array[float], 6, false,
			false, Vector3.UP)


static func _antler_paint(a: Vector3, e: Vector3, f0: float) -> Callable:
	var ab := e - a
	var l2: float = maxf(ab.length_squared(), 0.0001)
	return func(p: Vector3, _n: Vector3) -> Color:
		var f: float = f0 + (1.0 - f0) * clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		return CritterMeshBuilder.mixc(ANTLER_BASE, ANTLER_TIP, smoothstep(0.15, 0.85, f))


static func _add_antlers(b: CritterMeshBuilder) -> void:
	b.set_bones([[B_HEAD, HEAD_PIV], [B_NECK, NECK_PIV]])
	b.set_weight(Callable())
	for s: float in [1.0, -1.0]:
		var m := Vector3(s, 1.0, 1.0)
		var beam: Array[Vector3] = [Vector3(0.07, 1.76, 0.80) * m, Vector3(0.15, 1.92, 0.76) * m,
			Vector3(0.25, 2.10, 0.70) * m, Vector3(0.32, 2.28, 0.64) * m, Vector3(0.37, 2.45, 0.61) * m,
			Vector3(0.38, 2.60, 0.64) * m]
		b.set_paint(_antler_paint(beam[0], beam[5], 0.0))
		b.tube(beam, [0.05, 0.045, 0.04, 0.036, 0.03, 0.0] as Array[float], 5)
		# Tines: brow, bez, trez (forward), the crown fork (forward + back).
		var tines: Array = [
			[Vector3(0.12, 1.86, 0.79), Vector3(0.17, 1.93, 0.93), Vector3(0.20, 2.02, 1.06), 0.036],
			[Vector3(0.20, 2.01, 0.74), Vector3(0.25, 2.07, 0.87), Vector3(0.28, 2.16, 0.97), 0.032],
			[Vector3(0.29, 2.22, 0.66), Vector3(0.35, 2.33, 0.77), Vector3(0.39, 2.45, 0.84), 0.03],
			[Vector3(0.37, 2.46, 0.62), Vector3(0.43, 2.58, 0.69), Vector3(0.47, 2.70, 0.73), 0.028],
			[Vector3(0.36, 2.43, 0.60), Vector3(0.39, 2.55, 0.50), Vector3(0.41, 2.66, 0.43), 0.026],
		]
		for tn: Array in tines:
			var p0: Vector3 = tn[0] * m
			var p2: Vector3 = tn[2] * m
			var r0: float = tn[3]
			b.set_paint(_antler_paint(p0, p2, 0.4))
			b.tube([p0, tn[1] * m, p2] as Array[Vector3], [r0, r0 * 0.7, 0.0] as Array[float], 5)


## Leg i (0 FL, 1 FR, 2 BL, 3 BR; left = +X): an upper segment (shoulder / haunch) and a lower one (cannon + hoof).
static func _add_leg(b: CritterMeshBuilder, i: int) -> void:
	var s: float = 1.0 if i % 2 == 0 else -1.0
	var front: bool = i < 2
	var m := Vector3(s, 1.0, 1.0)
	var top: Vector3 = (SHOULDER if front else HIP) * m
	var joint: Vector3 = (KNEE if front else HOCK) * m
	b.set_bones([[B_UP + i, top]])
	b.set_weight(Callable())
	b.set_paint(func(p: Vector3, nr: Vector3) -> Color:
		var c := CritterMeshBuilder.mixc(LEG, COAT, smoothstep(0.58, 0.85, p.y))
		c = CritterMeshBuilder.mixc(c, BELLY, smoothstep(0.2, 0.7, -nr.x * s) * smoothstep(0.65, 0.95, p.y) * 0.5)
		var rump: float = smoothstep(-0.52, -0.62, p.z) * smoothstep(0.72, 0.86, p.y) * smoothstep(0.1, -0.4, nr.z)
		return CritterMeshBuilder.mixc(c, RUMP, rump))
	if front:
		b.tube([Vector3(0.12, 1.08, 0.43) * m, Vector3(0.145, 0.80, 0.47) * m, Vector3(0.14, 0.53, 0.45) * m]
			as Array[Vector3], [0.085, 0.072, 0.05] as Array[float], 7, true)
	else:
		b.tube([Vector3(0.11, 1.06, -0.45) * m, Vector3(0.13, 0.86, -0.47) * m, Vector3(0.13, 0.68, -0.56) * m,
			Vector3(0.13, 0.53, -0.62) * m] as Array[Vector3], [0.115, 0.10, 0.07, 0.046] as Array[float], 7, true)
	b.set_bones([[B_LO + i, joint], [B_UP + i, top]])
	b.set_paint(func(p: Vector3, _n: Vector3) -> Color:
		return CritterMeshBuilder.mixc(LEG, HOOF, smoothstep(0.08, 0.05, p.y)))
	var jz: float = joint.z
	b.tube([Vector3(joint.x, 0.56, jz), Vector3(joint.x, 0.30, jz + (0.0 if front else 0.04)),
		Vector3(joint.x, 0.10, jz + (0.01 if front else 0.07)), Vector3(joint.x, 0.015, jz + (0.04 if front else 0.10))]
		as Array[Vector3], [0.045, 0.034, 0.038, 0.046] as Array[float], 6, false, true)


static func _add_tail(b: CritterMeshBuilder) -> void:
	b.set_bones([[B_TAIL, TAIL_PIV]])
	b.set_weight(func(p: Vector3) -> float: return smoothstep(-0.68, -0.76, p.z))
	b.set_paint(func(_p: Vector3, nr: Vector3) -> Color:
		return CritterMeshBuilder.mixc(RUMP, TAIL_TOP, smoothstep(0.2, 0.7, nr.y)))
	b.tube([Vector3(0, 1.15, -0.67), Vector3(0, 1.10, -0.78), Vector3(0, 0.99, -0.84)] as Array[Vector3],
		[0.058, 0.05, 0.0] as Array[float], 6)
