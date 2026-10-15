extends IceModel
## Rime Harrier rider (stables.md 2 slot X, the Ice mounted skirmisher): a light javelineer on the Rime ram
## (rime_ram.gd). Seated with the kit's set_seated (13.V1b); rime_harrier.tscn pairs the two.
## Look: a lean young skirmisher in a STEEL-BLUE SCALE VEST (ice_steel, the mid-tone mass) over dark leather, the TEAM
## COWL (hood pushed down onto the shoulders, ice_cloth_dark with a light ice_cloth trim) and a TEAM SCARF streaming
## back (the top-facing team colour), one steel pauldron on the left shoulder (the asymmetric shape), fur-cuffed
## boots, and a BACK QUIVER of three frost javelins whose cyan crystal heads stand over the right shoulder. Bare head:
## a bright face with ice-blue eyes, round ears, a blue-black crop and a short braid (FaceKit face + cheap blade hair).
## Right hand: the FROST JAVELIN (own node "Javelin" at the fist, turned by the wrist): a dark shaft, a steel-blue grip
## wrap, a big cyan ice-crystal head with a glowing core (the glow point) and a steel butt spike. Carried upright at
## the side.
## Attack (`javelin_throw`, 0.62 s, release at attack_windup 0.12 s): the torso TWISTS in the saddle toward the target
## (aim: set_aim_target / the owning unit's attack_target, clamped to +-AIM_MAX), the left arm points at it, the right
## arm cocks the javelin overhead (0.08 s), whips it forward (release = event `release` + signal javelin_released, the
## javelin vanishes), follows through, then reaches back over the shoulder and draws the next one from the quiver
## (visible again at DRAW_T). The aim holds HOLD_TIME s after a throw so a harrier throwing on the move keeps its twist.
## Fidget (IceModel, standing still): spins the javelin upright and looks round. Cast: the javelin raised high.
## Death: freezes over and SHATTERS (IceModel, 8 shards) while riding the ram's roll.
## Pivots: Root / Hips (legs astride in the hips mesh: this rider never stands) / Chest (head + face drawn INSIDE the
## merged chest, CreatureFaceRig host mode) / ArmL / ArmR, + Javelin (keep_separate). With the ram: 12 draws.
## Hooks (on top of the kit's / IceModel's): set_aim_target(target: Variant), get_javelin_tip() -> Vector3 (world),
## aim_twist() -> float (deg), authored_mesh_count() -> int; signal javelin_released(from: Vector3, dir: Vector3).

signal javelin_released(from: Vector3, dir: Vector3)

const RAM := preload("res://art/units/ice/rime_harrier/parts/rime_ram.gd")

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP_Y := 0.84
const SH_L := Vector3(-0.28, 1.36, 0.0)
const SH_R := Vector3(0.28, 1.36, 0.0)
const HAND_L := Vector3(-0.29, 0.81, 0.02)
const HAND_R := Vector3(0.29, 0.81, 0.02)
const HEAD_C := Vector3(0, 1.60, 0.05)
const HEAD_R := 0.14
const HAIR := Color(0.14, 0.16, 0.24)
const HAIR_TIP := Color(0.30, 0.38, 0.54)
const SKIN := Color(0.86, 0.80, 0.78)
## The javelin (node-local, origin = the fist): shaft along +Y from JAV_BUTT to JAV_TIP.
const JAV_BUTT := -0.52
const JAV_TIP := 0.92
## Quiver on the back (model space): bottom, mouth.
const QUIVER_LO := Vector3(0.16, 0.98, -0.24)
const QUIVER_HI := Vector3(0.26, 1.46, -0.16)

## Riding rest pose of the arms (deg): left hand on the reins, right hand low at the side with the javelin upright.
const REST_L := Vector3(-34.0, 0.0, 10.0)
const REST_R := Vector3(-18.0, 0.0, 16.0)
## The javelin's rest angle in the chest frame (deg about X: 0 = up, + = tip toward the front).
const JAV_REST := 10.0
const SHOT_LEN := 0.62
const DRAW_T := 0.47
const AIM_MAX := 75.0
const AIM_SPEED := 300.0
const HOLD_TIME := 1.6
# Keyframe tracks [t, value, ease, ...] (see _kf): absolute right-arm pitch / roll, javelin angle, chest yaw / lean,
# left-arm pitch (deg).
static var T_ARM_X := PackedFloat32Array([0.0, -18.0, 0, 0.08, -172.0, 1, 0.12, -78.0, 2, 0.30, -44.0, 0, 0.40, -56.0, 0,
	0.47, -160.0, 1, 0.62, -18.0, 0])
static var T_ARM_Z := PackedFloat32Array([0.0, 16.0, 0, 0.08, 6.0, 1, 0.12, 4.0, 0, 0.40, 12.0, 0, 0.47, 28.0, 1,
	0.62, 16.0, 0])
static var T_PSI := PackedFloat32Array([0.0, 10.0, 0, 0.08, 94.0, 1, 0.12, 100.0, 0, 0.30, 100.0, 0, 0.40, 70.0, 0,
	0.47, -12.0, 1, 0.62, 10.0, 0])
static var T_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.08, -30.0, 1, 0.12, 20.0, 2, 0.30, 10.0, 0, 0.62, 0.0, 0])
static var T_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.08, -12.0, 1, 0.12, 16.0, 2, 0.30, 8.0, 0, 0.62, 0.0, 0])
static var T_ARM_L := PackedFloat32Array([0.0, -34.0, 0, 0.08, -84.0, 1, 0.12, -44.0, 0, 0.30, -40.0, 0, 0.62, -34.0, 0])

var _parts_n: int = 0
var _jav: MeshInstance3D
var _jav_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _jav_vis_w: int = -1
var _jav_glow_w: float = -1.0
var _psi_add: float = 0.0
# aim
var _aim_mode: int = 0          # 0 none, 1 world point, 2 node
var _aim_point: Vector3 = Vector3.ZERO
var _aim_node: Node3D = null
var _phi: float = 0.0
var _twist: float = 0.0
var _aim_w: float = 0.0
var _hold: float = 0.0
var _atk_t: float = 99.0


# ================================================================ public hooks

## Where to throw: a Node3D (tracked each frame), a Vector3 world point, or null (forward).
func set_aim_target(target: Variant) -> void:
	if target is Node3D:
		_aim_node = target
		_aim_mode = 2
	elif target is Vector3:
		_aim_point = target
		_aim_mode = 1
		_aim_node = null
	else:
		_aim_mode = 0
		_aim_node = null
		_phi = 0.0


## World position of the javelin tip (the throw origin).
func get_javelin_tip() -> Vector3:
	if _jav and _jav.is_inside_tree():
		return _jav.global_transform * Vector3(0, JAV_TIP, 0)
	return global_position + Vector3.UP * 2.2


func aim_twist() -> float:
	return _twist * _aim_w


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var chest: Node3D = $Root/Chest
	_sculpt($Root/Hips, "rhr_hips_v1", _hips_sculpt)
	_sculpt(chest, "rhr_chest_v1", _chest_sculpt)
	_face = CreatureFaceRig.attach(self, chest, "rime_harrier_rider", face_style())
	_sculpt($Root/Chest/ArmL, "rhr_arm_l_v1", _arm_l_sculpt)
	_sculpt($Root/Chest/ArmR, "rhr_arm_r_v1", _arm_r_sculpt)
	_parts_n += 1
	_jav = add_part($Root/Chest/ArmR, _cached_sculpt("rhr_javelin_v1", _javelin_sculpt), null, HAND_R, Vector3.ZERO,
		Vector3.ONE, true, "Javelin")
	if _jav:
		_jav.set_meta(&"own_glow", true)
	_parts_n += 1
	var trim := add_part(chest, cyl(0.305, 0.305, 0.035, 8, false), palette(&"unit_gold_trim"), Vector3(0, 1.36, -0.01),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	_shatter = _shards(8, 0.9, 0.3, 1.6, 3.4, 180.0, Vector3.UP, 0.10)
	_shatter.name = "Shatter"
	_shatter.position = Vector3(0, 1.15, 0.04) - model_origin(chest)
	chest.add_child(_shatter)


## A bright young face, ice-blue eyes, round ears, a blue-black crop swept back and a short braid (cheap blades).
static func face_spec() -> Dictionary:
	var hc := HEAD_C
	var r := HEAD_R
	return {"center": hc, "radius": r, "head_mesh": sphere(r, 8, 5), "head_scale": Vector3(0.94, 1.04, 0.96),
		"preset": &"bright", "detail": &"low", "skin": SKIN, "hair": HAIR, "eyes": Color(0.36, 0.66, 0.92),
		"ears": &"none", "x": NatureFaces.lean_x(1.05),
		"palette": {"lash": Color(0.08, 0.08, 0.14), "brow": HAIR.darkened(0.2), "lip": Color(0.78, 0.50, 0.54)},
		"hair_fn": func(acc: Dictionary) -> void:
			for sx: float in [-1.0, 1.0]:
				NatureFaces.ear_round(acc, hc, r, sx, SKIN, Vector3(r * 1.07, hc.y - 0.012, hc.z - 0.012))
			FaceKit.cap(acc, hc, r, HAIR, 0.55, 1.05)
			NatureFaces.crown(acc, hc, r * 1.04, 3, HAIR, HAIR_TIP, 1.1, 0.42, 120.0)
			NatureFaces.fringe(acc, hc, r, 2, HAIR, HAIR_TIP, 0.5, 0.7, 0.30)
			var back := Vector3(0, 0.2, -1.0).normalized()
			NatureFaces.blade(acc, hc + Vector3(0, -0.02, -0.12), hc + Vector3(0.02, -0.18, -0.19), 0.04, 0.018, back, HAIR, HAIR_TIP)
			NatureFaces.blade(acc, hc + Vector3(0.02, -0.14, -0.17), hc + Vector3(0.03, -0.30, -0.21), 0.032, 0.015, back, HAIR_TIP, HAIR),
	}


static func face_style() -> Dictionary:
	var st := FaceKit.style_from(face_spec())
	st["density"] = 5.0
	return st


func _ice_ready() -> void:
	if _face:
		(_face as CreatureFaceRig).set_host(_merged_nodes.get(P_CHEST))
		_update_tier()
		_face.auto(self)
	_jav_q_w = Quaternion(0, 0, 0, 0)
	_update_javelin()


func _sculpt(pivot: Node3D, key: String, build: Callable) -> void:
	_parts_n += 1
	if _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return
	var mesh := _cached_sculpt(key, build)
	if mesh:
		add_part(pivot, mesh, null, Vector3.ZERO)


static func _cached_sculpt(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var s := MountModel.sculpt()
	build.call(s)
	return _cached(key, MountModel.sculpt_mesh(s))


static func m(name: String) -> Material:
	return ice(StringName(name))


static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6,
		caps: bool = false) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg, caps), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


## Keyframe track [t, v, ease, ...] from t = 0; ease of the segment arriving at a key: 0 smooth, 1 ease-out, 2 ease-in.
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


# ---------------------------------------------------------------- body

## Team tunic skirt, belt, and the legs ASTRIDE the ram (authored in the saddle pose): dark leather thighs, steel knees,
## steel-blue greaves, fur-cuffed boots.
func _hips_sculpt(s: Dictionary) -> void:
	var dark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	var steel := m("ice_steel")
	var fur := m("ice_fur")
	_put(s, cyl(0.19, 0.24, 0.20, 8, false), dark, Vector3(0, 0.82, 0))
	_put(s, cyl(0.205, 0.205, 0.06, 8, false), leather, Vector3(0, 0.90, 0))
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.11 * sx, HIP_Y - 0.03, 0.0)
		var knee := Vector3(0.33 * sx, HIP_Y - 0.24, 0.17)
		var ankle := Vector3(0.40 * sx, HIP_Y - 0.56, 0.08)
		# G-C leftovers (light rider, 2500-vertex budget: same ring counts): one smooth thigh tube with a swell, a
		# smooth greave, a jagged fur cuff, a rounded boot (was a soft box)
		RiderShapes.tube(s, leather, PackedVector3Array([hip, hip.lerp(knee, 0.45), knee]), PackedFloat32Array([0.09, 0.094, 0.07]),
			6, false)
		_put(s, sphere(0.075, 6, 3), steel, knee + Vector3(0.0, 0.0, 0.02))
		RiderShapes.tube(s, steel, PackedVector3Array([knee, knee.lerp(ankle, 0.3), ankle]), PackedFloat32Array([0.068, 0.072, 0.056]),
			6, false)
		_put(s, IceModel.fur_ring(0.066, 0.08, 0.08, 4, 0.022), fur, ankle + Vector3(0, -0.005, 0))
		RiderShapes.boot(s, leather, ankle + Vector3(0.0, -0.05, -0.06), ankle + Vector3(0.0, -0.05, 0.19), 0.058, 6)


func _chest_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var leather := m("ice_leather")
	var skin := m("ice_skin")
	var frost := m("ice_frost_crystal")
	# scale vest (lathe, flattened)
	var prof := PackedVector2Array([Vector2(0.17, 0.88), Vector2(0.205, 1.00), Vector2(0.24, 1.16), Vector2(0.24, 1.27),
		Vector2(0.20, 1.36), Vector2(0.10, 1.43), Vector2(0.0, 1.445)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("rhr_torso_v1", prof, 7), Transform3D(Basis.from_scale(Vector3(1.0, 1.0,
		0.8)), Vector3.ZERO), steel)
	# the team cowl: a thick collar round the shoulders, the pushed-down hood at the back, a light trim
	_put(s, cyl(0.15, 0.30, 0.17, 8, false), dark, Vector3(0, 1.39, -0.01))
	_put(s, sphere(0.16, 6, 3), dark, Vector3(0, 1.43, -0.18), Vector3.ZERO, Vector3(1.15, 0.8, 0.85))
	_put(s, IceModel.fur_ring(0.30, 0.32, 0.06, 7, 0.025), cloth, Vector3(0, 1.275, -0.01))
	# the team scarf streaming back over the ram (two panels, a light tip)
	_put(s, soft_box(Vector3(0.16, 0.44, 0.025)), dark, Vector3(-0.07, 1.20, -0.34), Vector3(52, 0, 8))
	_put(s, soft_box(Vector3(0.15, 0.36, 0.025)), dark, Vector3(-0.10, 1.00, -0.62), Vector3(74, 0, 12))
	_put(s, soft_box(Vector3(0.155, 0.08, 0.03)), cloth, Vector3(-0.11, 0.95, -0.79), Vector3(74, 0, 12))
	# steel pauldron on the left shoulder (the asymmetric shape), a leather strap across the chest
	_put(s, sphere(0.14, 6, 3), steel, Vector3(-0.30, 1.37, 0.0), Vector3(0, 0, 18), Vector3(1.2, 0.75, 1.15))
	_put(s, soft_box(Vector3(0.05, 0.62, 0.03)), leather, Vector3(0.02, 1.16, 0.19), Vector3(0, 0, -38))
	# back quiver: a leather tube with three frost javelins, their cyan crystal heads over the right shoulder
	var qd := (QUIVER_HI - QUIVER_LO).normalized()
	MountModel.sculpt_add(s, cyl(0.075, 0.065, QUIVER_LO.distance_to(QUIVER_HI), 6, false), Transform3D(_to_dir(qd),
		(QUIVER_LO + QUIVER_HI) * 0.5), leather)
	for k: int in 3:
		var o := Vector3((float(k) - 1.0) * 0.045, 0.0, (float(k) - 1.0) * -0.02)
		var base := QUIVER_HI + o - qd * 0.10
		var tip := base + qd * (0.34 + 0.05 * float(k % 2))
		_seg(s, m("ice_wood"), base, tip, 0.014, 0.014, 4)
		MountModel.sculpt_add(s, RAM.spike_mesh(4), Transform3D(_to_dir(qd).scaled_local(Vector3(0.035, 0.16, 0.035)), tip), frost)
	# neck + head (the face canvas)
	_put(s, cyl(0.06, 0.07, 0.12, 6, false), skin, Vector3(0, 1.47, 0.03))
	_put(s, sphere(HEAD_R, 8, 5), skin, HEAD_C, Vector3.ZERO, Vector3(0.94, 1.04, 0.96))


func _arm_l_sculpt(s: Dictionary) -> void:
	var leather := m("ice_leather")
	var dark := m("ice_cloth_dark")
	var steel := m("ice_steel")
	var cloth := m("ice_cloth")
	var elbow := SH_L + Vector3(-0.01, -0.28, 0)
	RiderShapes.tube(s, dark, PackedVector3Array([SH_L, SH_L.lerp(elbow, 0.45), elbow]), PackedFloat32Array([0.07, 0.074, 0.062]),
		6, false)
	var wl := HAND_L + Vector3(0, 0.05, 0)
	RiderShapes.tube(s, leather, PackedVector3Array([elbow, elbow.lerp(wl, 0.3), wl]), PackedFloat32Array([0.064, 0.068, 0.055]),
		6, false)
	_put(s, sphere(0.062, 5, 2), leather, HAND_L)
	# a small round buckler strapped to the forearm (face -X): steel, a light team boss
	var bc := elbow.lerp(HAND_L, 0.5) + Vector3(-0.07, 0.0, 0.0)
	_put(s, cyl(0.17, 0.17, 0.035, 8), steel, bc, Vector3(0, 0, 90))
	_put(s, sphere(0.06, 5, 2), cloth, bc + Vector3(-0.03, 0, 0), Vector3.ZERO, Vector3(0.6, 1.0, 1.0))


func _arm_r_sculpt(s: Dictionary) -> void:
	var leather := m("ice_leather")
	var dark := m("ice_cloth_dark")
	var steel := m("ice_steel")
	var elbow := SH_R + Vector3(0.01, -0.28, 0)
	_put(s, sphere(0.085, 5, 2), dark, SH_R + Vector3(0, -0.02, 0))
	RiderShapes.tube(s, dark, PackedVector3Array([SH_R, SH_R.lerp(elbow, 0.45), elbow]), PackedFloat32Array([0.07, 0.074, 0.062]),
		6, false)
	var wr := HAND_R + Vector3(0, 0.05, 0)
	RiderShapes.tube(s, steel, PackedVector3Array([elbow, elbow.lerp(wr, 0.3), wr]), PackedFloat32Array([0.066, 0.07, 0.056]),
		6, false)
	_put(s, sphere(0.062, 5, 2), leather, HAND_R)


## The frost javelin (keep_separate "Javelin", node-local: the fist at the origin, shaft along +Y): dark shaft, steel
## grip wrap, the big cyan crystal head with a glowing core, a steel butt spike.
func _javelin_sculpt(s: Dictionary) -> void:
	var frost := m("ice_frost_crystal")
	var steel := m("ice_steel")
	_seg(s, m("ice_wood"), Vector3(0, JAV_BUTT, 0), Vector3(0, JAV_TIP - 0.14, 0), 0.022, 0.02, 5)
	_put(s, cyl(0.032, 0.032, 0.16, 5, false), steel, Vector3.ZERO)
	# the head: a glowing frost crystal (the glow point) in a cyan ice collar
	MountModel.sculpt_crystal(s, m("ice_glow_unit"), Vector3(0, JAV_TIP - 0.22, 0), Vector3.UP, 0.055, 0.28, 0.55)
	MountModel.sculpt_add(s, cyl(0.045, 0.06, 0.07, 5, false), Transform3D(Basis.IDENTITY, Vector3(0, JAV_TIP - 0.22, 0)), frost)
	MountModel.sculpt_add(s, RAM.spike_mesh(4), Transform3D(Basis(Vector3.RIGHT, PI).scaled_local(Vector3(0.03, 0.10, 0.03)),
		Vector3(0, JAV_BUTT, 0)), steel)


# ================================================================ motion

## `javelin_throw`: offsets relative to the riding rest pose (added in _pose_seated): the arm cocks, whips and draws
## the next javelin, the chest coils and uncoils (the aim twist is added in _pose_seated), the left arm points.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"javelin_throw":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	_atk_t = t
	_hold = HOLD_TIME
	rot(P_ARM_R, Vector3((_kf(t, T_ARM_X) - REST_R.x) * DEG, 0, (_kf(t, T_ARM_Z) - REST_R.z) * DEG))
	_psi_add += _kf(t, T_PSI) - JAV_REST
	rot(P_ARM_L, Vector3((_kf(t, T_ARM_L) - REST_L.x) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, T_LEAN) * DEG, _kf(t, T_YAW) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, 0.06 * _kf(t, T_LEAN) / 16.0))
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < SHOT_LEN


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"release":
			if _jav and _jav.is_inside_tree():
				var xf := _jav.global_transform
				javelin_released.emit(xf * Vector3(0, JAV_TIP, 0), xf.basis.y.normalized())
		&"attack_end":
			_atk_t = 99.0


## A salute for any cast: the javelin raised high.
func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-125.0 * DEG * k, 0, 8.0 * DEG * k))
	_psi_add += -6.0 * k
	return 0.75


## Fidget (standing still): spins the javelin upright in the fist and looks round (the upper body turns).
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.25, 1.2, 1.5, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-14.0 * DEG * env, 0, 0))
	_psi_add += 26.0 * sin(clampf(t / 1.2, 0.0, 1.0) * TAU * 2.0) * env
	rot(P_CHEST, Vector3(0, 16.0 * DEG * sin(t * TAU / 1.5) * env, 0))
	return 1.5


func _ice_process(dt: float) -> void:
	if _hold > 0.0:
		_hold -= dt
	var shooting: bool = _action == &"attack" and attack_style == &"javelin_throw"
	var want: float = 1.0 if (_hold > 0.0 or shooting) and not _dead else 0.0
	_aim_w = move_toward(_aim_w, want, dt / (0.10 if want > _aim_w else 0.40))
	_update_phi()
	var tw: float = clampf(_phi, -AIM_MAX, AIM_MAX) if want > 0.0 or _aim_w > 0.0 else 0.0
	_twist = move_toward(_twist, tw, AIM_SPEED * dt)
	if not _rd_on:
		_update_javelin()


func _update_phi() -> void:
	var p: Vector3
	if _aim_mode == 2:
		if not is_instance_valid(_aim_node) or not _aim_node.is_inside_tree():
			_aim_mode = 0
			_aim_node = null
			return
		p = _aim_node.global_position
	elif _aim_mode == 1:
		p = _aim_point
	else:
		_phi = 0.0
		return
	if not is_inside_tree():
		return
	var l := global_transform.affine_inverse() * p
	if Vector2(l.x, l.z).length() < 0.3:
		return
	_phi = rad_to_deg(atan2(l.x, l.z))


## Riding: the kit's seat pose (lean, bob), then the own arms (the kit's reins replaced: rest pose + the action offsets
## written before), the aim twist on the chest, the javelin's wrist and its visibility (thrown -> drawn again).
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 7.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	_off_rot[P_ARM_L] = sal + (REST_L + Vector3(bounce, 0, 0)) * DEG * w
	_off_rot[P_ARM_R] = sar + (REST_R + Vector3(-bounce * 0.8, 0, 0)) * DEG * w
	_psi_add += (bounce * 0.6 - 8.0 * gallop * moving) * w
	if _aim_w > 0.0:
		rot(P_CHEST, Vector3(0, _twist * _aim_w * DEG * w, 0))
	_update_javelin()


func _update_javelin() -> void:
	var psi: float = JAV_REST + _psi_add
	_psi_add = 0.0
	if _dead:
		psi = JAV_REST
	if _jav == null:
		return
	var want := Basis(Vector3.RIGHT, psi * DEG)
	var arm := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R]) if _piv[P_ARM_R] else Basis.IDENTITY
	var q := (arm.inverse() * want).get_rotation_quaternion()
	if not q.is_equal_approx(_jav_q_w):
		_jav_q_w = q
		_jav.quaternion = q
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	var thrown: bool = _action == &"attack" and _atk_t >= w and _atk_t < DRAW_T and not _dead
	var vis: int = 0 if thrown else 1
	if vis != _jav_vis_w:
		_jav_vis_w = vis
		_jav.visible = vis == 1
	var gl: float = snappedf(glow_level() * (1.0 + 0.8 * float(_action == &"attack")), 0.05)
	if gl != _jav_glow_w:
		_jav_glow_w = gl
		_jav.set_instance_shader_parameter(&"glow_boost", gl)


func _ice_revive() -> void:
	_psi_add = 0.0
	_aim_w = 0.0
	_hold = 0.0
	_twist = 0.0
	_atk_t = 99.0
	_jav_q_w = Quaternion(0, 0, 0, 0)
	_jav_vis_w = -1
	_jav_glow_w = -1.0
	_update_javelin()
