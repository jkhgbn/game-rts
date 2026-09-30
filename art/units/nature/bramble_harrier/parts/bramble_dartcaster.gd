extends NatureWarModel
## Bramble Harrier rider (stables.md 2 slot X, the Nature mounted skirmisher): a thorn-dart caster on the Bramble hare
## (bramble_hare.gd). Seated with the kit's set_seated (13.V1b); bramble_harrier.tscn pairs the two.
## Look: a lean forest skirmisher under a WIDE PALE STRAW HAT (the 40 m cap: a big cream disc from the game camera) with
## a dark bark band, bramble thorns and a sprig of dark berries; a BARK-BROWN LEATHER JERKIN over an amber tunic, a TEAM
## MANTLE and a team sash (nature_cloth, the top-facing team colour, framed by straw and bark: never green on green),
## bark leggings, soft dark boots, a bark DART QUIVER at the right hip with four leaf-fletched thorn darts. Face under the
## brim (FaceKit: warm amber eyes, lips, pointed leaf ears out under the hat, a chestnut fringe and braid).
## Right hand: the ATLATL and a THORN DART (own node "Dart" at the fist, turned by the wrist): a bark throwing stick,
## a long dark dart with a pale leaf fletching, a thorn head and a glowing green seed at the tip (the glow point).
## Attack (`dart_sling`, 0.6 s, release at attack_windup 0.12 s): the torso TWISTS toward the target (set_aim_target /
## the owning unit's attack_target, clamped to +-AIM_MAX), the arm swings out to the side and back (0.08 s), then
## SWEEPS forward in a flat side-arm throw (release = event `release` + signal dart_released, the dart vanishes),
## follows through, drops to the hip quiver and draws the next dart (DRAW_T). The aim holds HOLD_TIME s after a throw.
## Fidget (NatureWarModel, standing still): taps the hat brim up and looks round. Cast: the atlatl raised high.
## Death: "return to the grove" (the life flash, a burst of straw-gold leaves) riding the hare's roll.
## Pivots: Root / Hips (legs astride in the hips mesh) / Chest (head, hat and face INSIDE the merged chest,
## CreatureFaceRig host mode) / ArmL / ArmR, + Dart (keep_separate). With the hare: 12 draws.
## Hooks (on top of the kit's): set_aim_target(target: Variant), get_dart_tip() -> Vector3 (world), aim_twist() -> float,
## authored_mesh_count() -> int; signal dart_released(from: Vector3, dir: Vector3).

signal dart_released(from: Vector3, dir: Vector3)

const HARE := preload("res://art/units/nature/bramble_harrier/parts/bramble_hare.gd")

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP_Y := 0.82
const SH_L := Vector3(-0.27, 1.34, 0.0)
const SH_R := Vector3(0.27, 1.34, 0.0)
const HAND_L := Vector3(-0.28, 0.79, 0.02)
const HAND_R := Vector3(0.28, 0.79, 0.02)
const HEAD_C := Vector3(0, 1.58, 0.05)
const HEAD_R := 0.14
const QUIVER_LO := Vector3(0.30, 0.52, -0.10)
const QUIVER_HI := Vector3(0.26, 0.92, 0.06)
## The dart (node-local, origin = the fist): along +Y from DART_BUTT to DART_TIP; the atlatl lies under it.
const DART_BUTT := -0.40
const DART_TIP := 0.78
const REST_L := Vector3(-34.0, 0.0, 10.0)
const REST_R := Vector3(-20.0, 0.0, 16.0)
## The dart's rest angle in the chest frame (deg about X: 0 = up, + = tip toward the front).
const DART_REST := 18.0
const SHOT_LEN := 0.6
const DRAW_T := 0.44
const AIM_MAX := 75.0
const AIM_SPEED := 300.0
const HOLD_TIME := 1.6
# Keyframe tracks [t, value, ease, ...] (see _kf): the right arm's absolute pitch / yaw / roll (deg), the dart angle
# and yaw in the chest frame, the chest yaw / lean, the left arm pitch.
static var T_ARM_X := PackedFloat32Array([0.0, -20.0, 0, 0.08, -14.0, 1, 0.12, -14.0, 0, 0.26, -6.0, 0, 0.38, 22.0, 0,
	0.46, 10.0, 1, 0.6, -20.0, 0])
static var T_ARM_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 48.0, 1, 0.12, -58.0, 2, 0.26, -84.0, 0, 0.38, -20.0, 0,
	0.6, 0.0, 0])
static var T_ARM_Z := PackedFloat32Array([0.0, 16.0, 0, 0.08, 82.0, 1, 0.12, 76.0, 0, 0.26, 44.0, 0, 0.38, 18.0, 0,
	0.6, 16.0, 0])
static var T_PSI := PackedFloat32Array([0.0, 18.0, 0, 0.08, 92.0, 1, 0.12, 96.0, 0, 0.30, 96.0, 0, 0.38, 170.0, 1,
	0.46, 30.0, 1, 0.6, 18.0, 0])
static var T_DYAW := PackedFloat32Array([0.0, 0.0, 0, 0.08, 20.0, 1, 0.12, -6.0, 2, 0.30, -20.0, 0, 0.6, 0.0, 0])
static var T_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.08, -32.0, 1, 0.12, 22.0, 2, 0.30, 10.0, 0, 0.6, 0.0, 0])
static var T_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.08, -6.0, 1, 0.12, 12.0, 2, 0.30, 6.0, 0, 0.6, 0.0, 0])
static var T_ARM_L := PackedFloat32Array([0.0, -34.0, 0, 0.08, -70.0, 1, 0.12, -40.0, 0, 0.6, -34.0, 0])

var _parts_n: int = 0
var _dart: MeshInstance3D
var _dart_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _dart_vis_w: int = -1
var _dart_glow_w: float = -1.0
var _psi_add: float = 0.0
var _dyaw_add: float = 0.0
var _aim_mode: int = 0
var _aim_point: Vector3 = Vector3.ZERO
var _aim_node: Node3D = null
var _phi: float = 0.0
var _twist: float = 0.0
var _aim_w: float = 0.0
var _hold: float = 0.0
var _atk_t: float = 99.0


# ================================================================ public hooks

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


func get_dart_tip() -> Vector3:
	if _dart and _dart.is_inside_tree():
		return _dart.global_transform * Vector3(0, DART_TIP, 0)
	return global_position + Vector3.UP * 2.0


func aim_twist() -> float:
	return _twist * _aim_w


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var chest: Node3D = $Root/Chest
	_sculpt($Root/Hips, "bhr_hips_v1", _hips_sculpt)
	_sculpt(chest, "bhr_chest_v1", _chest_sculpt)
	_face = CreatureFaceRig.attach(self, chest, "bramble_dartcaster", face_style())
	_sculpt($Root/Chest/ArmL, "bhr_arm_l_v1", _arm_l_sculpt)
	_sculpt($Root/Chest/ArmR, "bhr_arm_r_v1", _arm_r_sculpt)
	_parts_n += 1
	_dart = add_part($Root/Chest/ArmR, _cached_sculpt("bhr_dart_v1", _dart_sculpt), null, HAND_R, Vector3.ZERO, Vector3.ONE,
		true, "Dart")
	if _dart:
		_dart.set_meta(&"own_glow", true)
	_parts_n += 1
	var trim := add_part(chest, cyl(0.37, 0.37, 0.03, 10, false), palette(&"unit_gold_trim"), Vector3(0, 1.715, 0.05),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# the death: one burst of straw-gold leaves (the cavalry budget allows one particle system)
	var lv := make_petals(Color(0.72, 0.62, 0.34), 10, 1.0, 0.4, 1.5, 0.15, true)
	lv.name = "DeathLeaves"
	lv.set_meta(&"death_fx", true)
	lv.position = Vector3(0, 1.10, 0.0)
	$Fx.add_child(lv)


## Warm amber eyes, pointed leaf ears out under the brim, a chestnut fringe and a braid down the back (cheap blades).
static func face_spec() -> Dictionary:
	var hc := HEAD_C
	var r := HEAD_R
	return {"center": hc, "radius": r, "head_mesh": sphere(r, 8, 5), "head_scale": Vector3(0.95, 1.05, 0.96),
		"preset": &"gentle", "detail": &"low", "skin": NatureFaces.SKIN, "hair": NatureFaces.CHESTNUT,
		"eyes": NatureFaces.EYE_AMBER, "x": NatureFaces.lean_x(1.05), "palette": NatureFaces.pal(NatureFaces.CHESTNUT),
		"hair_fn": func(acc: Dictionary) -> void:
			for sx: float in [-1.0, 1.0]:
				NatureFaces.ear_leaf(acc, hc, r, sx, NatureFaces.SKIN, 0.62, 0.30, 0.28)
			FaceKit.cap(acc, hc, r, NatureFaces.CHESTNUT, 0.6, 1.0)
			NatureFaces.fringe(acc, hc, r, 3, NatureFaces.CHESTNUT, NatureFaces.CHESTNUT_TIP, 0.6, 0.6, 0.26)
			var back := Vector3(0, 0.2, -1.0).normalized()
			NatureFaces.blade(acc, hc + Vector3(0, -0.02, -0.12), hc + Vector3(0.0, -0.20, -0.18), 0.045, 0.02, back,
				NatureFaces.CHESTNUT, NatureFaces.CHESTNUT_TIP)
			NatureFaces.blade(acc, hc + Vector3(0, -0.16, -0.17), hc + Vector3(0.0, -0.34, -0.20), 0.035, 0.016, back,
				NatureFaces.CHESTNUT_TIP, NatureFaces.CHESTNUT),
	}


static func face_style() -> Dictionary:
	var st := FaceKit.style_from(face_spec())
	st["density"] = 5.0
	return st


func _war_ready() -> void:
	if _face:
		(_face as CreatureFaceRig).set_host(_merged_nodes.get(P_CHEST))
		_update_tier()
		_face.auto(self)
	_dart_q_w = Quaternion(0, 0, 0, 0)
	_update_dart()


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
	return nature(StringName(name))


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


## One leaf (NatureModel.leaf_mesh) whose base is at `base`, pointing along `dir`, its face toward `nrm`.
static func _leaf(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, nrm: Vector3, size: Vector3) -> void:
	var z := dir.normalized()
	var y := nrm - z * nrm.dot(z)
	if y.length_squared() < 1e-6:
		y = Vector3.UP - z * z.y
	y = y.normalized()
	var x := y.cross(z)
	MountModel.sculpt_add(s, leaf_mesh(), Transform3D(Basis(x * size.x, y * size.y, z * size.z), base + z * size.z * 0.5), mat)


# ---------------------------------------------------------------- body

## Straw tunic skirt, a bark belt, the dart quiver at the right hip, the legs ASTRIDE the hare (saddle pose).
func _hips_sculpt(s: Dictionary) -> void:
	var straw := m("nature_sec_slinger_c")
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var fletch := m("nature_bell_cloth")
	var thorn := m("nature_thorn")
	_put(s, cyl(0.19, 0.24, 0.22, 8, false), straw, Vector3(0, 0.80, 0))
	_put(s, cyl(0.205, 0.205, 0.06, 8, false), dark, Vector3(0, 0.89, 0))
	var qd := (QUIVER_HI - QUIVER_LO).normalized()
	MountModel.sculpt_add(s, cyl(0.07, 0.06, QUIVER_LO.distance_to(QUIVER_HI), 6, false), Transform3D(_to_dir(qd),
		(QUIVER_LO + QUIVER_HI) * 0.5), bark)
	for k: int in 4:
		var o := Vector3((float(k % 2) - 0.5) * 0.05, 0.0, (float(k / 2) - 0.5) * 0.05)
		var base := QUIVER_HI + o - qd * 0.06
		var tip := base + qd * (0.26 + 0.04 * float(k % 2))
		_seg(s, dark, base, tip, 0.012, 0.012, 4)
		_leaf(s, fletch, tip - qd * 0.10, qd, Vector3(o.x, 0, o.z).normalized() if o.length() > 0.01 else Vector3.RIGHT,
			Vector3(0.05, 0.012, 0.12))
		MountModel.sculpt_add(s, HARE.spike_mesh(3), Transform3D(_to_dir(-qd).scaled_local(Vector3(0.02, 0.07, 0.02)),
			QUIVER_LO + o * 0.5 + qd * 0.02), thorn)
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.11 * sx, HIP_Y - 0.03, 0.0)
		var knee := Vector3(0.36 * sx, HIP_Y - 0.24, 0.16)
		var ankle := Vector3(0.43 * sx, HIP_Y - 0.55, 0.07)
		_seg(s, bark, hip, knee, 0.085, 0.068)
		_put(s, sphere(0.07, 5, 2), dark, knee)
		_seg(s, straw, knee, ankle, 0.064, 0.054)
		for f: float in [0.35, 0.7]:
			_put(s, cyl(0.066, 0.066, 0.025, 6, false), dark, knee.lerp(ankle, f), Vector3.ZERO)
		_put(s, box(Vector3(0.11, 0.09, 0.24)), dark, ankle + Vector3(0.0, -0.04, 0.06))


func _chest_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var cloth := m("nature_cloth")
	var straw := m("nature_bell_cloth")
	var thorn := m("nature_thorn")
	var skin := m("nature_skin")
	var berry := m("nature_leaf_dark")
	# bark leather jerkin (lathe, flattened)
	var prof := PackedVector2Array([Vector2(0.17, 0.87), Vector2(0.20, 0.98), Vector2(0.235, 1.13), Vector2(0.24, 1.24),
		Vector2(0.21, 1.33), Vector2(0.11, 1.41), Vector2(0.0, 1.43)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("bhr_torso_v1", prof, 7), Transform3D(Basis.from_scale(Vector3(1.0, 1.0,
		0.8)), Vector3.ZERO), bark)
	# the team sash across the chest (left shoulder to right hip) and the team mantle falling back over the hare
	_put(s, box(Vector3(0.09, 0.56, 0.035)), cloth, Vector3(0.0, 1.12, 0.185), Vector3(0, 0, 32))
	_put(s, cyl(0.14, 0.27, 0.15, 8, false), cloth, Vector3(0, 1.36, -0.01))
	_put(s, box(Vector3(0.40, 0.38, 0.03)), cloth, Vector3(0, 1.21, -0.28), Vector3(38, 0, 0))
	_put(s, box(Vector3(0.12, 0.36, 0.035)), m("nature_cloth_dark"), Vector3(0, 1.215, -0.282), Vector3(38, 0, 0))
	_put(s, box(Vector3(0.41, 0.06, 0.035)), straw, Vector3(0, 1.06, -0.40), Vector3(38, 0, 0))
	# a big pale-moss leaf pauldron on the left shoulder (the asymmetric shape)
	_leaf(s, m("nature_leaf"), Vector3(-0.22, 1.40, 0.02), Vector3(-0.8, -0.35, -0.1), Vector3(-0.3, 1.0, 0.1),
		Vector3(0.26, 0.05, 0.34))
	_leaf(s, m("nature_leaf_dark"), Vector3(-0.20, 1.37, 0.10), Vector3(-0.7, -0.5, 0.3), Vector3(-0.3, 1.0, 0.3),
		Vector3(0.18, 0.04, 0.26))
	# neck + head (the face canvas)
	_put(s, cyl(0.06, 0.07, 0.12, 6, false), skin, Vector3(0, 1.45, 0.03))
	_put(s, sphere(HEAD_R, 8, 5), skin, HEAD_C, Vector3.ZERO, Vector3(0.95, 1.05, 0.96))
	# THE STRAW HAT: a wide pale cone (the 40 m cap), a dark bark band, bramble thorns and a sprig of dark berries
	var hat := PackedVector2Array([Vector2(0.32, 1.70), Vector2(0.30, 1.72), Vector2(0.19, 1.78), Vector2(0.09, 1.85),
		Vector2(0.0, 1.89)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("bhr_hat_v2", hat, 10, true), Transform3D(Basis(Vector3.RIGHT,
		deg_to_rad(-6.0)), Vector3(0, 0.0, 0.05)), straw)
	MountModel.sculpt_add(s, cyl(0.17, 0.19, 0.05, 8, false), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6.0)),
		Vector3(0, 1.765, 0.058)), dark)
	for k: int in 3:
		var a := deg_to_rad(30.0 + 25.0 * float(k))
		var p := Vector3(sin(a) * 0.19, 1.77, cos(a) * 0.19 + 0.05)
		MountModel.sculpt_add(s, HARE.spike_mesh(3), Transform3D(_to_dir(Vector3(sin(a), 0.5, cos(a))).scaled_local(
			Vector3(0.018, 0.08, 0.018)), p), thorn)
	for k: int in 3:
		_put(s, sphere(0.028, 5, 2), berry, Vector3(-0.16 + 0.03 * float(k), 1.79 + 0.02 * float(k % 2), 0.12))


func _arm_l_sculpt(s: Dictionary) -> void:
	var straw := m("nature_sec_slinger_c")
	var bark := m("nature_bark")
	var skin := m("nature_skin")
	var elbow := SH_L + Vector3(-0.01, -0.27, 0)
	_put(s, sphere(0.078, 5, 2), bark, SH_L + Vector3(0, -0.02, 0))
	_seg(s, straw, SH_L, elbow, 0.066, 0.058)
	_seg(s, bark, elbow, HAND_L + Vector3(0, 0.05, 0), 0.06, 0.052)
	_put(s, sphere(0.058, 5, 2), skin, HAND_L)


func _arm_r_sculpt(s: Dictionary) -> void:
	var straw := m("nature_sec_slinger_c")
	var bark := m("nature_bark")
	var skin := m("nature_skin")
	var elbow := SH_R + Vector3(0.01, -0.27, 0)
	_put(s, sphere(0.078, 5, 2), bark, SH_R + Vector3(0, -0.02, 0))
	_seg(s, straw, SH_R, elbow, 0.066, 0.058)
	_seg(s, bark, elbow, HAND_R + Vector3(0, 0.05, 0), 0.06, 0.052)
	_put(s, sphere(0.058, 5, 2), skin, HAND_R)


## The atlatl and the thorn dart (keep_separate "Dart", node-local: the fist at the origin, the dart along +Y): a bark
## throwing stick with a hook, the dark dart with a pale leaf fletching, a thorn head and a glowing green seed.
func _dart_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var fletch := m("nature_bell_cloth")
	var thorn := m("nature_thorn")
	# the atlatl: from behind the fist up along the dart, a hook at its end
	_seg(s, bark, Vector3(0.0, -0.06, -0.035), Vector3(0.0, -0.46, -0.035), 0.022, 0.018, 4)
	MountModel.sculpt_add(s, HARE.spike_mesh(3), Transform3D(_to_dir(Vector3(0, 0.3, 1.0)).scaled_local(Vector3(0.02, 0.06,
		0.02)), Vector3(0, -0.46, -0.035)), dark)
	# the dart
	_seg(s, dark, Vector3(0, DART_BUTT, 0), Vector3(0, DART_TIP - 0.12, 0), 0.015, 0.014, 4)
	for k: int in 2:
		var o := Vector3(1.0 if k == 0 else -1.0, 0, 0)
		_leaf(s, fletch, Vector3(0, DART_BUTT + 0.02, 0) + o * 0.01, Vector3.UP, o.cross(Vector3.UP),
			Vector3(0.07, 0.012, 0.16))
	MountModel.sculpt_add(s, HARE.spike_mesh(3), Transform3D(Basis.from_scale(Vector3(0.035, 0.16, 0.035)),
		Vector3(0, DART_TIP - 0.16, 0)), thorn)
	_put(s, sphere(0.04, 6, 3), m("nature_glow"), Vector3(0, DART_TIP - 0.14, 0), Vector3.ZERO, Vector3(1.0, 1.4, 1.0))


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"dart_sling":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	_atk_t = t
	_hold = HOLD_TIME
	rot(P_ARM_R, Vector3((_kf(t, T_ARM_X) - REST_R.x) * DEG, _kf(t, T_ARM_Y) * DEG, (_kf(t, T_ARM_Z) - REST_R.z) * DEG))
	_psi_add += _kf(t, T_PSI) - DART_REST
	_dyaw_add += _kf(t, T_DYAW)
	rot(P_ARM_L, Vector3((_kf(t, T_ARM_L) - REST_L.x) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, T_LEAN) * DEG, _kf(t, T_YAW) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, 0.05 * _kf(t, T_LEAN) / 12.0))
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < SHOT_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release" and _dart and _dart.is_inside_tree():
		var xf := _dart.global_transform
		dart_released.emit(xf * Vector3(0, DART_TIP, 0), xf.basis.y.normalized())


func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-125.0 * DEG * k, 0, 8.0 * DEG * k))
	_psi_add += -10.0 * k
	return 0.75


## Fidget (standing still): taps the hat brim up with the left hand and looks round.
func _pose_fidget(t: float) -> float:
	var tap := _k3(t, 0.0, 0.3, 0.7, 1.0, 1.0, 1.0)
	rot(P_ARM_L, Vector3(-120.0 * DEG * tap, 0, -20.0 * DEG * tap))
	var look := _k3(t, 0.8, 1.0, 1.6, 1.9, 1.0, 1.0)
	rot(P_CHEST, Vector3(0, 20.0 * DEG * sin((t - 0.8) * TAU / 1.1) * look, 0))
	return 1.9


func _war_process(dt: float) -> void:
	if _hold > 0.0:
		_hold -= dt
	var shooting: bool = _action == &"attack" and attack_style == &"dart_sling"
	var want: float = 1.0 if (_hold > 0.0 or shooting) and not _dead else 0.0
	_aim_w = move_toward(_aim_w, want, dt / (0.10 if want > _aim_w else 0.40))
	_update_phi()
	var tw: float = clampf(_phi, -AIM_MAX, AIM_MAX) if want > 0.0 or _aim_w > 0.0 else 0.0
	_twist = move_toward(_twist, tw, AIM_SPEED * dt)
	if not _rd_on:
		_update_dart()


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
	_update_dart()


func _update_dart() -> void:
	var psi: float = DART_REST + _psi_add
	var yaw: float = _dyaw_add
	_psi_add = 0.0
	_dyaw_add = 0.0
	if _dead:
		psi = DART_REST
		yaw = 0.0
	if _dart == null:
		return
	var want := Basis(Vector3.UP, yaw * DEG) * Basis(Vector3.RIGHT, psi * DEG)
	var arm := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R]) if _piv[P_ARM_R] else Basis.IDENTITY
	var q := (arm.inverse() * want).get_rotation_quaternion()
	if not q.is_equal_approx(_dart_q_w):
		_dart_q_w = q
		_dart.quaternion = q
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	var thrown: bool = _action == &"attack" and _atk_t >= w and _atk_t < DRAW_T and not _dead
	var vis: int = 0 if thrown else 1
	if vis != _dart_vis_w:
		_dart_vis_w = vis
		_dart.visible = vis == 1
	var gl: float = snappedf(glow_level() * (1.0 + 0.8 * float(_action == &"attack")), 0.05)
	if gl != _dart_glow_w:
		_dart_glow_w = gl
		_dart.set_instance_shader_parameter(&"glow_boost", gl)


func _war_revive() -> void:
	_psi_add = 0.0
	_dyaw_add = 0.0
	_aim_w = 0.0
	_hold = 0.0
	_twist = 0.0
	_atk_t = 99.0
	_dart_q_w = Quaternion(0, 0, 0, 0)
	_dart_vis_w = -1
	_dart_glow_w = -1.0
	_update_dart()

