class_name GladeOutriderRider
extends NatureModel
## Glade Outrider rider (tier3-extras.md 12, task 13b.V3): the Nature horse archer on the 13.V5 Grove Stag. Seated with
## the kit's CharacterModel.set_seated (13.V1b); the scene that pairs it with the stag is glade_outrider.tscn
## (GladeOutriderModel, the unit's model_scene).
## Look: a light, lean archer in a tan leather jerkin under a LEAF CLOAK (three rows of fresh leaves down the back,
## lifting at the gallop) and a leaf mantle; a team-green hood with a pointed tail and TWO ANTLER-LIKE TWIGS (pale
## antler wood, echoing the stag's rack) tipped with glowing buds; the lower face masked. A SHORT CURVED BOW (pale ash,
## recurved tips with leaf flourishes) held SIDEWAYS (limbs near horizontal, canted CANT deg) in the left hand; a quiver
## of leaf-fletched arrows at the right hip; a nocked arrow with a glowing seed head.
## Glow points: the twig buds (merged) and the nocked arrow's seed head (own glow: brighter with the draw).
## Riding: bow across the stag's withers, right hand low in front; at the gallop the cloak streams back.
## Shooting (`attack_style &"mounted_bow"`, release at attack_windup 0.12 s, 0.55 s): the torso TWISTS in the saddle
## toward the target (chest yaw clamped to +-TWIST_MAX = 90 deg, archer's stance: the bow shoulder leads), the bow arm
## points the bow along the arrow line, the right arm draws (two-bone arm: an own forearm node) to the chin, loose (the
## string twangs, the arrow vanishes, a small recoil), the hand goes down to the quiver and nocks a new arrow (0.42 s),
## then the bow stays up half-drawn on the target for HOLD_TIME s so a rider shooting every 1.5 s at the gallop keeps
## its twist; then it relaxes. Targets behind swing the torso the other way (the parting shot over the left shoulder).
## Hooks (on top of the kit's): set_aim_target(target: Variant) (Node3D tracked each frame, Vector3 world point, null =
## forward), get_arrow_origin() -> Vector3 (world), aim_twist() -> float (deg, + = right), aim_blend() -> float,
## draw_amount() -> float, authored_mesh_count() -> int; signal arrow_released(from: Vector3, dir: Vector3) (world, at
## the loose). Budget (cavalry rider, section 12): 11 authored meshes, 11 draw instances (7 merged pivots + ForearmR,
## Bow (5 cached draw variants, swapped), Arrow, Cloak), no blob (the stag's shows), 0 lights, 0 particles.

signal arrow_released(from: Vector3, dir: Vector3)

const OWN := "res://art/units/nature/glade_outrider/materials/"
const ANTLER := "res://art/units/mounts/grove_stag/materials/grove_stag_antler.tres"

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP := Vector3(0, 0.84, 0)
const CHEST_O := Vector3(0, 0.92, 0)
const HEAD_O := Vector3(0, 1.46, 0.02)
const SH_L := Vector3(-0.28, 1.36, 0.0)
const SH_R := Vector3(0.28, 1.36, 0.0)
const GRIP := Vector3(-0.28, 0.80, 0.0)
const ELBOW_R := Vector3(0.28, 1.08, 0.0)
const HAND_R := Vector3(0.28, 0.80, 0.0)
const ARM_L_LEN := 0.56
const UPPER_R := 0.28
const FORE_R := 0.28
const CLOAK_O := Vector3(0, 1.37, -0.15)
const QUIVER_MOUTH := Vector3(0.31, 1.00, -0.02)
const QUIVER_BASE := Vector3(0.31, 0.53, -0.30)
## The draw anchor under the chin (model space) and the bow geometry (bow frame: grip at the origin, limbs along
## +-X, string side +Y, the arrow flies along -Y).
const ANCHOR := Vector3(0.03, 1.53, 0.15)
const DRAW_FULL := 0.60
const BRACE := 0.15
const ARROW_LEN := 0.74
const ARROW_Z := 0.035
const BOW_STEPS := 4
## Aim: archer's stance (chest yaw = aim + STANCE), torso twist limit, turn speed (deg/s), bow cant from horizontal.
const STANCE := 65.0
const TWIST_MAX := 90.0
const TWIST_SPEED := 320.0
const CANT := 22.0
## The bow arm's comfortable direction range relative to the chest (deg, + = across to the right).
const ARM_MIN := -125.0
const ARM_MAX := 30.0
const SHOT_LEN := 0.55
const NOCK_T := 0.42
const HOLD_TIME := 1.9
const HOLD_DRAW := 0.3
const AIM_H := 2.4           # model-space height of the eyes when seated (elevation of the aim)
# Riding rest targets (chest frame): bow grip low in front, right hand beside it.
const REST_GRIP_C := Vector3(-0.12, 0.10, 0.40)
const REST_HAND_C := Vector3(0.12, 0.10, 0.36)
const REST_POLE := Vector3(1.0, -0.2, -0.5)
const CAST_DIR := Vector3(-0.45, 0.85, 0.28)

# Bow limb control points (x > 0 side; mirrored), braced and fully drawn; index 4 = where the string ties.
const LIMB_BRACED: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.14, 0.015), Vector2(0.29, 0.06), Vector2(0.42, 0.12),
	Vector2(0.51, 0.16), Vector2(0.565, 0.14), Vector2(0.60, 0.085)]
const LIMB_DRAWN: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.14, 0.03), Vector2(0.27, 0.11), Vector2(0.37, 0.20),
	Vector2(0.44, 0.27), Vector2(0.49, 0.26), Vector2(0.52, 0.21)]
const LIMB_R: Array[float] = [0.044, 0.040, 0.035, 0.030, 0.025, 0.021, 0.014]

var _parts_n: int = 0
var _bow: MeshInstance3D
var _arrow: MeshInstance3D
var _fore: MeshInstance3D
var _cloak: MeshInstance3D
var _bow_meshes: Array[Mesh] = []

# aim state
var _aim_mode: int = 0          # 0 none (forward), 1 world point, 2 node
var _aim_point: Vector3 = Vector3.ZERO
var _aim_node: Node3D = null
var _phi: float = 0.0           # aim azimuth (deg, model frame, + = right)
var _elev: float = 0.0          # aim elevation (deg)
var _phi_valid: bool = false
var _twist: float = 0.0         # chest twist (deg, + = right)
var _branch: int = 0            # 0: twist = phi + STANCE, 1: the other way round (targets behind)
var _aim_w: float = 0.0
var _hold: float = 0.0
var _look_w: float = 0.0
var _atk_t: float = 99.0        # time in the current mounted_bow shot
var _d0: float = 0.0            # draw when the shot started
var _draw: float = 0.0
var _rel_t: float = 99.0        # time since the last loose
var _cast_k: float = 0.0
var _dt: float = 0.0
# written-value caches (write on change only)
var _bow_k_w: int = -1
var _arrow_y_w: float = -1.0
var _arrow_vis_w: int = -1
var _arrow_glow_w: float = -1.0
var _cloak_w: float = 99.0
var _bow_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _fore_q_w: Quaternion = Quaternion(0, 0, 0, 0)
# IK scratch (no allocation per frame)
var _ik_u: Basis = Basis.IDENTITY
var _ik_f: Basis = Basis.IDENTITY


# ================================================================ public hooks

## Where to shoot: a Node3D (tracked every frame at its centre + 1 m), a Vector3 world point, or null (forward).
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
		_elev = 0.0
		_phi_valid = false


## World position of the nocked arrow's head (the shot origin); the bow grip while no arrow is nocked.
func get_arrow_origin() -> Vector3:
	if _arrow and _arrow.is_inside_tree():
		return _arrow.global_transform * Vector3(0, -ARROW_LEN, 0)
	if _bow and _bow.is_inside_tree():
		return _bow.global_position
	return global_position + Vector3.UP * AIM_H


## Current chest twist in the saddle (deg, + = toward the right), times the aim blend.
func aim_twist() -> float:
	return _twist * _aim_w


func aim_blend() -> float:
	return _aim_w


func draw_amount() -> float:
	return _draw


## Authored meshes of the rider (the cavalry budget of section 12).
func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	_sculpt(hips, "gor_hips_v1", _hips_sculpt)
	for leg: Node3D in [$Root/Hips/LegL, $Root/Hips/LegR]:
		var sx: float = -1.0 if leg.name == "LegL" else 1.0
		_sculpt(leg, "gor_leg_%s_v1" % sx, func(s: Dictionary) -> void: _leg_sculpt(s, sx))
	_sculpt(chest, "gor_chest_v1", _chest_sculpt)
	_sculpt($Root/Chest/Head, "gor_head_v1", _head_sculpt)
	_sculpt(arm_l, "gor_arm_l_v1", _arm_l_sculpt)
	_sculpt(arm_r, "gor_arm_r_v1", _arm_r_sculpt)
	# Own (keep_separate) parts: forearm (elbow), bow (grip) with the arrow, the cloak (upper back).
	_fore = _sculpt(arm_r, "gor_fore_v1", _fore_sculpt, ELBOW_R, true, "ForearmR")
	_bow_meshes.clear()
	for k: int in BOW_STEPS + 1:
		var kk := k
		_bow_meshes.append(_cached_sculpt("gor_bow_%d_v1" % k, func(s: Dictionary) -> void: _bow_sculpt(s, kk)))
	_parts_n += 1
	_bow = add_part(arm_l, _bow_meshes[0], null, GRIP, Vector3.ZERO, Vector3.ONE, true, "Bow")
	_arrow = _sculpt(_bow, "gor_arrow_v1", _arrow_sculpt, GRIP + Vector3(0, BRACE, ARROW_Z), true, "Arrow")
	_arrow.set_meta(&"own_glow", true)
	_cloak = _sculpt(chest, "gor_cloak_v1", _cloak_sculpt, CLOAK_O, true, "Cloak")


## One authored part from a multi-material sculpt (MountModel's builders). Static parts are skipped once the pivot's
## merge is cached; keep_separate parts get their cached mesh every instance. `at` = the node's model position (the
## mesh is then in node-local coordinates) or ZERO for a model-space mesh.
func _sculpt(pivot: Node3D, key: String, build: Callable, at: Vector3 = Vector3.ZERO, keep: bool = false,
		nm: String = "") -> MeshInstance3D:
	_parts_n += 1
	if not keep and _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var mesh := _cached_sculpt(key, build)
	if mesh == null:
		return null
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, nm)


static func _cached_sculpt(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var s := MountModel.sculpt()
	build.call(s)
	return _cached(key, MountModel.sculpt_mesh(s))


static func m(name: String) -> Material:
	if name.begins_with("glade_outrider"):
		return MountModel.material_at(OWN + name + ".tres")
	if name == "antler":
		return MountModel.material_at(ANTLER)
	if name == "unit_eye_dark":
		return palette(&"unit_eye_dark")
	return nature(StringName(name))


## Rotation taking +Y onto `d` (robust for d straight down).
static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


## Cylinder / cone from a (radius ra) to b (radius rb).
static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 7) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg), Transform3D(_to_dir(d), a + d * 0.5), mat)


## One leaf (NatureModel.leaf_mesh) whose base is at `base`, pointing along `dir`, its face toward `nrm`.
static func _leaf(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, nrm: Vector3, size: Vector3) -> void:
	var z := dir.normalized()
	var y := nrm - z * nrm.dot(z)
	if y.length_squared() < 1e-6:
		y = Vector3.UP - z * z.y
	y = y.normalized()
	var x := y.cross(z)
	MountModel.sculpt_add(s, leaf_mesh(), Transform3D(Basis(x * size.x, y * size.y, z * size.z), base + z * size.z * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


# ---------------------------------------------------------------- body

func _hips_sculpt(s: Dictionary) -> void:
	var tunic := m("glade_outrider_jerkin")
	var belt := m("nature_bark_dark")
	var bark := m("nature_bark")
	var leaf := m("glade_outrider_leaf")
	var leaf_d := m("nature_leaf_dark")
	var dark := m("nature_cloth_dark")
	var wood := m("glade_outrider_bow")
	# short jerkin skirt (split for riding), belt with a bark buckle
	_put(s, cyl(0.20, 0.245, 0.26, 10), tunic, Vector3(0, 0.81, 0))
	_put(s, cyl(0.215, 0.215, 0.07, 10, false), belt, Vector3(0, 0.935, 0))
	_put(s, sphere(0.045, 6, 3), bark, Vector3(0, 0.935, 0.215), Vector3.ZERO, Vector3(1.3, 1.0, 0.6))
	# riding tabs front and back: long leaves over the skirt
	_leaf(s, dark, Vector3(0, 0.90, 0.21), Vector3(0, -1.0, 0.28), Vector3(0, 0.25, 1.0), Vector3(0.20, 0.04, 0.34))
	_leaf(s, leaf, Vector3(0, 0.90, -0.21), Vector3(0, -1.0, -0.30), Vector3(0, 0.25, -1.0), Vector3(0.22, 0.04, 0.36))
	for sx: float in [-1.0, 1.0]:
		_leaf(s, leaf_d, Vector3(0.17 * sx, 0.89, -0.14), Vector3(0.35 * sx, -1.0, -0.3), Vector3(sx, 0.2, -0.5),
			Vector3(0.15, 0.035, 0.28))
	# the quiver at the right hip: bark tube hanging behind the hip, mouth forward-up, bands, a leaf flap, a strap
	var qd := (QUIVER_MOUTH - QUIVER_BASE).normalized()
	_seg(s, bark, QUIVER_BASE, QUIVER_MOUTH, 0.065, 0.078, 8)
	_put(s, sphere(0.066, 8, 3), belt, QUIVER_BASE, Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
	for f: float in [0.22, 0.62]:
		var c := QUIVER_BASE.lerp(QUIVER_MOUTH, f)
		MountModel.sculpt_add(s, cyl(0.075 + 0.01 * f, 0.075 + 0.01 * f, 0.035, 8, false),
			Transform3D(_to_dir(qd), c), belt)
	MountModel.sculpt_add(s, torus(0.068, 0.092, 10), Transform3D(_to_dir(qd), QUIVER_MOUTH), belt)
	_leaf(s, leaf, QUIVER_BASE.lerp(QUIVER_MOUTH, 0.75) + Vector3(0.07, 0, 0), -qd, Vector3(1, 0, 0),
		Vector3(0.12, 0.03, 0.26))
	_seg(s, belt, Vector3(0.20, 0.93, 0.06), QUIVER_MOUTH + Vector3(-0.03, -0.02, 0.0), 0.02, 0.02, 4)
	# five leaf-fletched arrows out of the quiver (nocks up, fletching = little leaves)
	var side := qd.cross(Vector3.RIGHT).normalized()
	for i: int in 5:
		var a := TAU * float(i) / 5.0 + 0.3
		var off := (Vector3.RIGHT * cos(a) + side * sin(a)) * 0.038
		var fan := (qd + off * 2.2).normalized()
		var b := QUIVER_MOUTH + off
		var tip := b + fan * (0.20 + 0.03 * float(i % 2))
		_seg(s, wood, b, tip, 0.011, 0.011, 4)
		for j: int in 2:
			var fa := a + PI * float(j)
			var fo := (Vector3.RIGHT * cos(fa) + side * sin(fa)).normalized()
			_leaf(s, leaf if (i + j) % 2 == 0 else leaf_d, tip - fan * 0.10 + fo * 0.012, fan, fo.cross(fan),
				Vector3(0.05, 0.012, 0.11))


## A leg rooted at the hip (sx -1 left, +1 right): trousers, a bark knee, the shin authored bent back by
## seat_leg_forward_deg so it hangs straight down in the saddle, a bark boot with the toe tilted up the same way.
func _leg_sculpt(s: Dictionary, sx: float) -> void:
	var trousers := m("nature_cloth_dark")
	var bark := m("nature_bark")
	var boot := m("nature_bark_dark")
	var leaf := m("glade_outrider_leaf")
	var fwd := deg_to_rad(seat_leg_forward_deg)
	var hip := Vector3(0.11 * sx, 0.84, 0)
	var knee := Vector3(0.12 * sx, 0.47, 0.03)
	var shin := Vector3(0, -cos(fwd), -sin(fwd))
	var ankle := knee + shin * 0.30
	_seg(s, trousers, hip, knee, 0.088, 0.07, 8)
	_put(s, sphere(0.072, 7, 3), bark, knee + Vector3(0, 0, 0.015))
	_seg(s, bark, knee, ankle, 0.066, 0.06, 7)
	for f: float in [0.35, 0.7]:
		MountModel.sculpt_add(s, cyl(0.07, 0.07, 0.03, 7, false), Transform3D(_to_dir(shin), knee + shin * 0.30 * f), boot)
	# leaf greave on the shin front
	var front := Vector3(0, shin.z, -shin.y)   # perpendicular to the shin, toward the toes
	_leaf(s, leaf, knee + shin * 0.05 + front * 0.055, shin, front, Vector3(0.11, 0.03, 0.24))
	# boot: cuff + foot pointing forward, toe up by fwd (level once seated)
	var foot_dir := Vector3(0, sin(fwd), cos(fwd))
	var foot_c := ankle + foot_dir * 0.06 + Vector3(0, -0.035, 0)
	MountModel.sculpt_add(s, capsule(0.062, 0.25), Transform3D(_to_dir(foot_dir), foot_c), boot)
	_put(s, cyl(0.078, 0.07, 0.08, 7), boot, ankle + shin * -0.02, Vector3(rad_to_deg(-fwd), 0, 0))


func _chest_sculpt(s: Dictionary) -> void:
	var tunic := m("glade_outrider_jerkin")
	var cloth := m("nature_cloth")
	var dark := m("nature_cloth_dark")
	var leaf := m("glade_outrider_leaf")
	var leaf_d := m("nature_leaf_dark")
	var belt := m("nature_bark_dark")
	# torso (lathe, flattened front-back): a lean archer's jerkin
	var prof := PackedVector2Array([Vector2(0.17, 0.90), Vector2(0.195, 1.0), Vector2(0.232, 1.15), Vector2(0.24, 1.25),
		Vector2(0.215, 1.35), Vector2(0.12, 1.43), Vector2(0.0, 1.45)])
	var torso := MountModel.lathe_mesh("gor_torso_v1", prof, 12)
	MountModel.sculpt_add(s, torso, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.8)), Vector3.ZERO), tunic)
	# team sash across the chest (left shoulder to right hip), front and back
	for zs: float in [1.0, -1.0]:
		_put(s, box(Vector3(0.09, 0.56, 0.035)), cloth, Vector3(0.0, 1.15, 0.183 * zs), Vector3(0, 0, 32.0 * zs))
	# the bow-arm guard strap and a belt pouch
	_put(s, box(Vector3(0.05, 0.05, 0.36)), belt, Vector3(-0.12, 1.02, 0.02), Vector3(0, 0, -8))
	# hood cape (team) draped over the shoulders, a dark rim
	_put(s, cyl(0.135, 0.265, 0.17, 12, false), cloth, Vector3(0, 1.415, -0.01))
	_put(s, cyl(0.268, 0.272, 0.03, 12, false), dark, Vector3(0, 1.33, -0.01))
	# leaf mantle over the shoulders (one light ring; a dark leaf at the throat)
	MountModel.sculpt_add(s, leaf_ring_mesh(8, 0.16, Vector3(0.17, 0.045, 0.24), -42.0, 22.5),
		Transform3D(Basis.IDENTITY, Vector3(0, 1.37, -0.01)), leaf)
	_leaf(s, leaf_d, Vector3(0, 1.42, 0.12), Vector3(0, -1.0, 0.35), Vector3(0, 0.3, 1.0), Vector3(0.12, 0.035, 0.18))


## The leaf cloak (keep_separate "Cloak" at CLOAK_O, node-local): three rows of leaves hanging from the shoulders,
## fanning out and back; lifted by the gallop.
func _cloak_sculpt(s: Dictionary) -> void:
	# light spring leaves (yellow-green, lime, a few tan ones): lighter than the stag's dark moss so the rider pops
	var mats: Array[Material] = [m("nature_sec_slinger_b"), m("nature_leaf"), m("glade_outrider_leaf"), m("nature_thorn")]
	var back := Vector3(0, 0.2, -1.0).normalized()
	for r: int in 2:
		var n: int = 4 + r
		var y: float = -0.03 - 0.19 * float(r)
		var spread: float = 0.17 + 0.06 * float(r)
		var z: float = -0.01 - 0.06 * float(r)
		var size := Vector3(0.15 + 0.02 * float(r), 0.035, 0.26 + 0.04 * float(r))
		for i: int in n:
			var u: float = (float(i) / float(n - 1)) * 2.0 - 1.0
			var base := Vector3(u * spread, y - 0.03 * absf(u), z - 0.03 * (1.0 - absf(u)))
			var dir := Vector3(u * 0.4, -1.0, -0.30 - 0.10 * float(r)).normalized()
			_leaf(s, mats[(i + 2 * r) % 4], base, dir, back + Vector3(u * 0.4, 0, 0), size)
	# a knot of darker leaves at the neck where the cloak hangs from
	var dk := m("nature_leaf_dark")
	_leaf(s, dk, Vector3(-0.07, 0.03, 0.0), Vector3(-0.5, -1.0, -0.2), back, Vector3(0.10, 0.035, 0.17))
	_leaf(s, dk, Vector3(0.07, 0.03, 0.0), Vector3(0.5, -1.0, -0.2), back, Vector3(0.10, 0.035, 0.17))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("nature_skin")
	var cloth := m("nature_cloth")
	var dark := m("nature_cloth_dark")
	var eye := m("unit_eye_dark")
	var leaf := m("glade_outrider_leaf")
	var ant := m("antler")
	var moss := m("nature_moss")
	var glow := m("nature_glow")
	_put(s, cyl(0.065, 0.075, 0.14, 8), skin, Vector3(0, 1.50, 0.02))
	# face, the masked lower face, eyes, nose
	_put(s, sphere(0.15, 10, 6), skin, Vector3(0, 1.63, 0.06), Vector3.ZERO, Vector3(0.95, 1.08, 0.95))
	_put(s, sphere(0.155, 10, 5), dark, Vector3(0, 1.575, 0.075), Vector3.ZERO, Vector3(1.03, 0.55, 1.02))
	for sx: float in [-1.0, 1.0]:
		_put(s, sphere(0.03, 6, 3), eye, Vector3(0.056 * sx, 1.66, 0.185), Vector3.ZERO, Vector3(1.1, 0.7, 0.6))
	_put(s, box(Vector3(0.20, 0.035, 0.05)), dark, Vector3(0, 1.705, 0.175), Vector3(-10, 0, 0))
	# the hood (team), its long pointed tail, a dark rim round the face, leaf trims
	_put(s, sphere(0.20, 12, 6), cloth, Vector3(0, 1.68, -0.02), Vector3.ZERO, Vector3(1.06, 1.0, 1.10))
	MountModel.sculpt_add(s, MountModel.tube_mesh("gor_hood_tail_v1", PackedVector3Array([Vector3(0, 1.74, -0.12),
		Vector3(0, 1.72, -0.28), Vector3(0, 1.64, -0.40), Vector3(0, 1.52, -0.46)]),
		PackedFloat32Array([0.13, 0.085, 0.05, 0.0]), 8), Transform3D.IDENTITY, cloth)
	_put(s, torus(0.13, 0.172, 14), dark, Vector3(0, 1.645, 0.125), Vector3(78, 0, 0))
	for sx: float in [-1.0, 1.0]:
		_leaf(s, leaf, Vector3(0.18 * sx, 1.72, 0.02), Vector3(0.45 * sx, -0.35, -1.0), Vector3(sx, 0.5, 0.0),
			Vector3(0.10, 0.03, 0.22))
		_twig(s, sx, ant, moss, leaf, glow)


## One antler-like twig growing out of the hood (pale antler wood like the stag's rack): a curving beam up-out-back
## with a forward tine and a small outer tine, a moss knot at the base, two leaves, glowing buds at the tips.
func _twig(s: Dictionary, sx: float, ant: Material, moss: Material, leaf: Material, glow: Material) -> void:
	var mx := Vector3(sx, 1, 1)
	var beam := PackedVector3Array([Vector3(0.10, 1.80, -0.02) * mx, Vector3(0.15, 1.94, -0.04) * mx,
		Vector3(0.22, 2.06, -0.09) * mx, Vector3(0.29, 2.15, -0.16) * mx])
	MountModel.sculpt_add(s, MountModel.tube_mesh("gor_twig_%s_v1" % sx, beam, PackedFloat32Array([0.032, 0.026, 0.019,
		0.0]), 6), Transform3D.IDENTITY, ant)
	var t1 := PackedVector3Array([Vector3(0.165, 1.975, -0.05) * mx, Vector3(0.19, 2.07, 0.02) * mx,
		Vector3(0.20, 2.13, 0.08) * mx])
	MountModel.sculpt_add(s, MountModel.tube_mesh("gor_tine_%s_v1" % sx, t1, PackedFloat32Array([0.017, 0.013, 0.0]), 5),
		Transform3D.IDENTITY, ant)
	var t2 := PackedVector3Array([Vector3(0.22, 2.06, -0.09) * mx, Vector3(0.28, 2.09, -0.07) * mx,
		Vector3(0.33, 2.10, -0.04) * mx])
	MountModel.sculpt_add(s, MountModel.tube_mesh("gor_tine2_%s_v1" % sx, t2, PackedFloat32Array([0.014, 0.01, 0.0]), 5),
		Transform3D.IDENTITY, ant)
	_put(s, sphere(0.05, 7, 3), moss, Vector3(0.10, 1.80, -0.02) * mx, Vector3.ZERO, Vector3(1.1, 0.7, 1.1))
	_leaf(s, leaf, Vector3(0.14, 1.91, -0.03) * mx, Vector3(0.9 * sx, 0.5, 0.3), Vector3(0, 1, 0.2), Vector3(0.07, 0.02, 0.13))
	_leaf(s, leaf, Vector3(0.23, 2.07, -0.09) * mx, Vector3(0.2 * sx, 0.4, -1.0), Vector3(sx, 0.6, 0), Vector3(0.06, 0.02, 0.11))
	_put(s, sphere(0.04, 7, 4), glow, Vector3(0.29, 2.155, -0.162) * mx)
	_put(s, sphere(0.032, 7, 4), glow, Vector3(0.20, 2.135, 0.085) * mx)


func _arm_l_sculpt(s: Dictionary) -> void:
	var tunic := m("glade_outrider_jerkin")
	var bark := m("nature_bark")
	var band := m("nature_bark_dark")
	var skin := m("nature_skin")
	var leaf := m("glade_outrider_leaf")
	var elbow := SH_L + Vector3(0, -0.28, 0)
	_put(s, sphere(0.085, 8, 4), tunic, SH_L + Vector3(0, -0.02, 0))
	_seg(s, tunic, SH_L, elbow, 0.07, 0.062, 8)
	_put(s, sphere(0.062, 7, 3), tunic, elbow)
	_seg(s, bark, elbow, GRIP + Vector3(0, 0.05, 0), 0.062, 0.056, 8)
	_put(s, cyl(0.066, 0.066, 0.03, 8, false), band, elbow + Vector3(0, -0.06, 0))
	_put(s, cyl(0.06, 0.06, 0.03, 8, false), band, GRIP + Vector3(0, 0.09, 0))
	_leaf(s, leaf, elbow + Vector3(-0.05, -0.02, 0.0), Vector3(-0.15, -1.0, 0), Vector3(-1, 0, 0), Vector3(0.09, 0.025, 0.2))
	_put(s, sphere(0.066, 8, 4), skin, GRIP, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


func _arm_r_sculpt(s: Dictionary) -> void:
	var tunic := m("glade_outrider_jerkin")
	_put(s, sphere(0.085, 8, 4), tunic, SH_R + Vector3(0, -0.02, 0))
	_seg(s, tunic, SH_R, ELBOW_R, 0.07, 0.062, 8)
	_put(s, sphere(0.062, 7, 3), tunic, ELBOW_R)


## The right forearm (keep_separate "ForearmR", node-local at the elbow): bark bracer, a leather draw tab, the hand.
func _fore_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var band := m("nature_bark_dark")
	var skin := m("nature_skin")
	var hand := HAND_R - ELBOW_R
	_seg(s, bark, Vector3.ZERO, hand + Vector3(0, 0.05, 0), 0.06, 0.054, 8)
	_put(s, cyl(0.064, 0.064, 0.03, 8, false), band, Vector3(0, -0.07, 0))
	_put(s, cyl(0.058, 0.058, 0.03, 8, false), band, hand + Vector3(0, 0.09, 0))
	_put(s, sphere(0.063, 8, 4), skin, hand, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))
	_put(s, box(Vector3(0.05, 0.06, 0.035)), band, hand + Vector3(0, -0.02, 0.06))


## Bow variant k (0 braced .. BOW_STEPS full draw), bow frame (grip at the origin). The limbs flex with the draw and
## the string runs from the limb ties to the nock point (y = BRACE .. DRAW_FULL). Same surface order in every variant.
func _bow_sculpt(s: Dictionary, k: int) -> void:
	var f: float = float(k) / float(BOW_STEPS)
	var wood := m("glade_outrider_bow")
	var band := m("nature_bark_dark")
	var leaf := m("glade_outrider_leaf")
	var ant := m("antler")
	var str_m := m("glade_outrider_string")
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	var n: int = LIMB_BRACED.size()
	for i: int in range(n - 1, 0, -1):
		var p := LIMB_BRACED[i].lerp(LIMB_DRAWN[i], f)
		pts.append(Vector3(-p.x, p.y, 0))
		rad.append(LIMB_R[i])
	for i: int in n:
		var p := LIMB_BRACED[i].lerp(LIMB_DRAWN[i], f)
		pts.append(Vector3(p.x, p.y, 0))
		rad.append(LIMB_R[i])
	MountModel.sculpt_add(s, MountModel.tube_mesh("gor_limbs_%d_v1" % k, pts, rad, 6), Transform3D.IDENTITY, wood)
	# grip wrap and the antler nocks at the tips
	MountModel.sculpt_add(s, cyl(0.042, 0.042, 0.15, 8), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO), band)
	for sx: float in [-1.0, 1.0]:
		var t := LIMB_BRACED[n - 1].lerp(LIMB_DRAWN[n - 1], f)
		var c := LIMB_BRACED[n - 2].lerp(LIMB_DRAWN[n - 2], f)
		_put(s, sphere(0.022, 6, 3), ant, Vector3(t.x * sx, t.y, 0))
		# a leaf flourish on each recurve, pointing outward
		var out := Vector3((t.x - c.x) * sx, t.y - c.y, 0).normalized()
		_leaf(s, leaf, Vector3(c.x * sx, c.y, 0.0), (out + Vector3(0.9 * sx, 0, 0)).normalized(), Vector3(0, 0, 1),
			Vector3(0.06, 0.02, 0.13))
	# the string: limb ties -> nock -> limb ties
	var tie := LIMB_BRACED[4].lerp(LIMB_DRAWN[4], f)
	var nock := Vector3(0, BRACE + f * (DRAW_FULL - BRACE), 0)
	_seg(s, str_m, Vector3(-tie.x, tie.y, 0), nock, 0.011, 0.011, 4)
	_seg(s, str_m, nock, Vector3(tie.x, tie.y, 0), 0.011, 0.011, 4)
	_put(s, sphere(0.014, 5, 3), str_m, nock)


## The nocked arrow (keep_separate "Arrow", child of the bow; node-local: the nock at the origin, flying along -Y):
## pale shaft, three leaf fletchings, a glowing seed head with two dark leaf barbs.
func _arrow_sculpt(s: Dictionary) -> void:
	var wood := m("glade_outrider_bow")
	var band := m("nature_bark_dark")
	var leaf := m("glade_outrider_leaf")
	var leaf_d := m("nature_leaf_dark")
	var glow := m("nature_glow")
	var tip := Vector3(0, -ARROW_LEN, 0)
	_seg(s, wood, Vector3.ZERO, tip + Vector3(0, 0.06, 0), 0.012, 0.012, 5)
	_put(s, sphere(0.018, 5, 3), band, Vector3.ZERO)
	for i: int in 3:
		var a := TAU * float(i) / 3.0
		var o := Vector3(cos(a), 0, sin(a))
		_leaf(s, leaf, Vector3(0, -0.04, 0) + o * 0.014, Vector3.DOWN, o.cross(Vector3.DOWN), Vector3(0.045, 0.012, 0.13))
	_put(s, sphere(0.032, 7, 4), glow, tip + Vector3(0, 0.035, 0), Vector3.ZERO, Vector3(1.0, 2.0, 1.0))
	for sx: float in [-1.0, 1.0]:
		_leaf(s, leaf_d, tip + Vector3(0.012 * sx, 0.08, 0), Vector3(0.45 * sx, 1.0, 0), Vector3(0, 0, 1),
			Vector3(0.035, 0.01, 0.07))


# ================================================================ motion

## `mounted_bow`: the draw (to attack_windup), the loose, the reload to the quiver, the nock (NOCK_T). The arms, bow and
## twist are posed in _pose_seated (after the kit seats the hips); on foot a simplified shot is posed here.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"mounted_bow":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	if prev <= 0.0 or t < _atk_t:
		_d0 = _draw
	_atk_t = t
	_hold = HOLD_TIME
	if prev < w and t >= w:
		_on_action_event(&"release")
	if not _rd_on:
		var aw: float = _k3(t, 0.0, 0.08, SHOT_LEN - 0.1, SHOT_LEN, 1.0, 1.0)
		_solve(1.0, aw, _off_rot[P_ARM_L], _off_rot[P_ARM_R], _off_pos[P_ARM_L], _off_rot[P_HEAD], Vector3.ZERO,
			_off_rot[P_CHEST], 0.0, 0.0, 0.0)
	return t < SHOT_LEN


## A bow salute for any cast (the bow raised high to the left), SHOT-free.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.18, 0.45, 0.7, 1.0, 1.0)
	if not _rd_on:
		rot(P_ARM_L, Vector3(-140.0 * DEG * _cast_k, 0, 0))
	return 0.7


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"release":
			_rel_t = 0.0
			if _arrow and _arrow.is_inside_tree():
				var xf := _arrow.global_transform
				arrow_released.emit(xf * Vector3(0, -ARROW_LEN, 0), -(xf.basis.y.normalized()))
		&"attack_end":
			_atk_t = 99.0


## Timers, the aim azimuth and the smoothed twist (runs on every animated frame before the seated pose).
func _extra_process(dt: float) -> void:
	_dt = dt
	_rel_t += dt
	if _hold > 0.0:
		_hold -= dt
	var shooting: bool = _action == &"attack" and attack_style == &"mounted_bow"
	var want: float = 1.0 if (_hold > 0.0 or shooting) and not _dead else 0.0
	_aim_w = move_toward(_aim_w, want, dt / (0.10 if want > _aim_w else 0.35))
	_update_phi()
	var tw: float = 0.0
	if want > 0.0 or _aim_w > 0.0:
		tw = _choose_twist(_phi)
	_twist = move_toward(_twist, tw, TWIST_SPEED * dt)
	_look_w = move_toward(_look_w, 1.0 if _phi_valid and not _dead and _aim_w < 0.5 else 0.0, dt / 0.4)
	# the draw of this frame
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	if shooting:
		var t := _atk_t
		if t < w:
			_draw = lerpf(_d0, 1.0, _ease_out(clampf(t / w, 0.0, 1.0)))
		elif t < NOCK_T + 0.02:
			_draw = 0.0
		else:
			_draw = HOLD_DRAW * smoothstep(NOCK_T, SHOT_LEN, t)
	else:
		_draw = HOLD_DRAW * _aim_w
	if _dead:
		_draw = 0.0


func _update_phi() -> void:
	var p: Vector3
	if _aim_mode == 2:
		if not is_instance_valid(_aim_node) or not _aim_node.is_inside_tree():
			_aim_mode = 0 if not _phi_valid else 1
			_aim_node = null
			return
		p = _aim_node.global_position + Vector3.UP
		_aim_point = p
	elif _aim_mode == 1:
		p = _aim_point
	else:
		return
	if not is_inside_tree():
		return
	var l := global_transform.affine_inverse() * p
	var hd := Vector2(l.x, l.z).length()
	if hd < 0.3:
		return
	_phi = rad_to_deg(atan2(l.x, l.z))
	_elev = clampf(rad_to_deg(atan2(l.y - AIM_H, hd)), -30.0, 25.0)
	_phi_valid = true


## Chest twist (deg) for an aim azimuth: the archer's stance (twist = aim + STANCE) clamped to +-TWIST_MAX, or the
## other way round for targets behind (the bow shoulder toward the rear); the branch keeps the bow arm in its
## comfortable range, with 15 deg of hysteresis.
func _choose_twist(phi: float) -> float:
	var y0: float = phi + STANCE
	var y1: float = phi + STANCE + (-360.0 if phi > 0.0 else 360.0)
	var c0: float = clampf(y0, -TWIST_MAX, TWIST_MAX)
	var c1: float = clampf(y1, -TWIST_MAX, TWIST_MAX)
	var e0: float = _arm_err(wrapf(phi - c0, -180.0, 180.0))
	var e1: float = _arm_err(wrapf(phi - c1, -180.0, 180.0))
	if _branch == 0 and e1 + 15.0 < e0:
		_branch = 1
	elif _branch == 1 and e0 + 15.0 < e1:
		_branch = 0
	return c0 if _branch == 0 else c1


static func _arm_err(rel: float) -> float:
	return maxf(ARM_MIN - rel, 0.0) + maxf(rel - ARM_MAX, 0.0)


## Riding: the kit's seat pose (lean, bob, head), then the bow, the arms, the twist and the cloak (the kit's reins are
## replaced: the offsets the actions wrote before are kept and ours are added).
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	var spl: Vector3 = _off_pos[P_ARM_L]
	var sh: Vector3 = _off_rot[P_HEAD]
	super._pose_seated(w, gait, gallop, moving)
	var head_add: Vector3 = _off_rot[P_HEAD] - sh
	_solve(w, _aim_w * w, sal, sar, spl, sh, head_add, _off_rot[P_CHEST], gait, gallop, moving)
	# the cloak streams back at the gallop
	if _cloak:
		var c: float = (5.0 * moving + gallop * moving * (18.0 + 6.0 * sin(TAU * gait * 2.0 + 0.6))) * w
		if _dead:
			c = 0.0
		c = snappedf(c, 0.25)
		if c != _cloak_w:
			_cloak_w = c
			_cloak.rotation = Vector3(c * DEG, 0, 0)


## Solves the chest twist, the bow arm, the bow (+ string variant and arrow), the two-bone draw arm and the head for
## aim weight aw (0 = riding rest). Writes _off_rot / _off_pos (keeping the saved offsets) and the own nodes.
func _solve(w: float, aw: float, sal: Vector3, sar: Vector3, spl: Vector3, sh: Vector3, head_add: Vector3,
		chest_now: Vector3, gait: float, gallop: float, moving: float) -> void:
	var ck: float = _cast_k
	_cast_k = 0.0
	var a_w: float = maxf(aw, ck)
	# ---- chest: the kit's lean / sway, then the twist about the (leaning) spine, then a small recoil at the loose
	var bc := Basis.from_euler(chest_now)
	if a_w > 0.0:
		bc = bc * Basis(Vector3.UP, _twist * DEG * aw)
		var rk: float = _k3(_rel_t, 0.0, 0.04, 0.06, 0.26, 1.0, 1.0) * aw
		if rk > 0.0:
			bc = bc * Basis(Vector3.RIGHT, -5.0 * DEG * rk)
		_off_rot[P_CHEST] = bc.get_euler() - _rest_rot[P_CHEST]
	# ---- the aim direction in the chest frame
	var rb := Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT])
	var inv := (rb * bc).inverse()
	var ph := deg_to_rad(_phi)
	var el := deg_to_rad(_elev)
	var a_m := Vector3(sin(ph) * cos(el), sin(el), cos(ph) * cos(el))
	if ck > 0.0:
		a_m = a_m.slerp(CAST_DIR.normalized(), ck)
	var ac := (inv * a_m).normalized()
	# limbs: horizontal (model frame) across the arrow line, canted up by CANT
	var h_m := Vector3.UP.cross(a_m)
	if h_m.length_squared() < 1e-4:
		h_m = Vector3.RIGHT
	h_m = h_m.normalized()
	var up_m := a_m.cross(h_m)
	if up_m.y < 0.0:
		up_m = -up_m
	var l_c := (inv * (h_m * cos(CANT * DEG) + up_m * sin(CANT * DEG))).normalized()
	# ---- targets (chest frame): the grip on the arrow line from the chin anchor, or the riding rest
	var bob := Vector3(0, lerpf(0.012 * sin(2.0 * TAU * gait), 0.03 * sin(TAU * (gait - 0.4)), gallop) * moving, 0)
	var anchor := ANCHOR - CHEST_O
	var g_aim := anchor + ac * DRAW_FULL
	var g := (REST_GRIP_C + bob).lerp(g_aim, a_w)
	var shl: Vector3 = _rest_pos[P_ARM_L]
	var dl := g - shl
	var len_l := dl.length()
	var ul := dl / maxf(len_l, 0.001)
	var ext: float = clampf(len_l - ARM_L_LEN, -0.12, 0.14)
	var lx := Vector3.RIGHT.lerp(l_c, a_w)
	var bl := _basis_y(-ul, lx)
	_off_rot[P_ARM_L] = sal + bl.get_euler() * w
	_off_pos[P_ARM_L] = spl + ul * ext * w
	# ---- the bow along the arrow line (relative to the bow arm)
	var bb := _basis_y(-ac, l_c)
	var q := Quaternion.IDENTITY.slerp((bl.inverse() * bb).get_rotation_quaternion(), a_w)
	if _bow and not q.is_equal_approx(_bow_q_w):
		_bow_q_w = q
		_bow.quaternion = q
	var d: float = _draw
	var k: int = clampi(roundi(d * float(BOW_STEPS)), 0, BOW_STEPS)
	if _rel_t < 0.12:
		k = 1 if int(_rel_t * 45.0) % 2 == 0 and _rel_t < 0.09 else 0   # the string twangs
	if _bow and k != _bow_k_w and k < _bow_meshes.size():
		_bow_k_w = k
		_bow.mesh = _bow_meshes[k]
	var nock: float = BRACE + d * (DRAW_FULL - BRACE)
	var loaded: bool = not (_atk_t < 90.0 and _atk_t >= (attack_windup if attack_windup > 0.0 else 0.12) and
		_atk_t < NOCK_T and _action == &"attack")
	if _arrow:
		if absf(nock - _arrow_y_w) > 0.002:
			_arrow_y_w = nock
			_arrow.position = Vector3(0, nock, ARROW_Z)
		var vis: int = 1 if loaded else 0
		if vis != _arrow_vis_w:
			_arrow_vis_w = vis
			_arrow.visible = loaded
		var gl: float = snappedf(glow_level() * (0.9 + 1.8 * d), 0.05)
		if gl != _arrow_glow_w:
			_arrow_glow_w = gl
			_arrow.set_instance_shader_parameter(&"glow_boost", gl)
	# ---- the draw arm: the hand on the string at the nock (or down at the quiver while reloading)
	var grip := shl + ul * (ARM_L_LEN + ext)
	var bq := bl * Basis(q)
	var h_draw := grip + bq * Vector3(0, nock + 0.03, 0)
	var hand := (REST_HAND_C + bob).lerp(h_draw, a_w)
	var pole := REST_POLE.lerp(Vector3(1.0, 0.45, 0.0) - ac * 0.9, a_w)
	var rl: float = 0.0
	if _action == &"attack" and _atk_t < 90.0:
		rl = smoothstep(0.13, 0.25, _atk_t) * (1.0 - smoothstep(0.31, NOCK_T + 0.02, _atk_t)) * aw
	if rl > 0.0:
		var hips_root: Vector3 = _rest_pos[P_HIPS] + _off_pos[P_HIPS]
		var chest_root: Vector3 = _rest_pos[P_CHEST] + _off_pos[P_CHEST]
		var qm := bc.inverse() * (hips_root + (QUIVER_MOUTH - HIP) - chest_root)
		hand = hand.lerp(qm + Vector3(0, 0.08, 0.02), rl)
		pole = pole.lerp(Vector3(1.0, 0.1, -0.2), rl)
	_ik(_rest_pos[P_ARM_R], hand, UPPER_R, FORE_R, pole)
	_off_rot[P_ARM_R] = sar + _ik_u.get_euler() * w
	if _fore:
		var fq := (_ik_u.inverse() * _ik_f).get_rotation_quaternion()
		if not fq.is_equal_approx(_fore_q_w):
			_fore_q_w = fq
			_fore.quaternion = fq
	# ---- head: along the arrow while aiming; else a glance toward a known target
	if a_w > 0.0:
		var hy: float = clampf(atan2(ac.x, ac.z), -80.0 * DEG, 80.0 * DEG)
		var hx: float = -asin(clampf(ac.y, -0.6, 0.6))
		_off_rot[P_HEAD] = sh + head_add.lerp(Vector3(hx, hy, 0.0), a_w)
	elif _look_w > 0.0:
		_off_rot[P_HEAD] = sh + head_add + Vector3(0, clampf(_phi, -60.0, 60.0) * 0.8 * DEG * _look_w * w, 0)


## Basis whose +Y is `y_axis` and whose +X is the part of `x_hint` perpendicular to it.
static func _basis_y(y_axis: Vector3, x_hint: Vector3) -> Basis:
	var y := y_axis.normalized()
	var x := x_hint - y * x_hint.dot(y)
	if x.length_squared() < 1e-6:
		x = Vector3.BACK.cross(y)
		if x.length_squared() < 1e-6:
			x = Vector3.RIGHT
	x = x.normalized()
	return Basis(x, y, x.cross(y))


## Two-bone arm from shoulder s to hand h (chest frame), bone lengths a / b, the elbow bent toward `pole`. Results in
## _ik_u (upper arm basis) and _ik_f (forearm basis), both with the arm's rest (hanging) axes.
func _ik(s: Vector3, h: Vector3, a: float, b: float, pole: Vector3) -> void:
	var dv := h - s
	var dist := dv.length()
	var u := dv / maxf(dist, 0.001)
	var d := clampf(dist, absf(a - b) + 0.02, a + b - 0.004)
	var ca: float = clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var sa: float = sqrt(maxf(0.0, 1.0 - ca * ca))
	var pp := pole - u * pole.dot(u)
	if pp.length_squared() < 1e-6:
		pp = Vector3.BACK - u * u.z
	pp = pp.normalized()
	var e := s + u * (a * ca) + pp * (a * sa)
	var hand := s + u * d
	_ik_u = _basis_y(-(e - s), Vector3.RIGHT)
	_ik_f = _basis_y(-(hand - e), Vector3.RIGHT)


func _on_revive() -> void:
	_aim_w = 0.0
	_hold = 0.0
	_twist = 0.0
	_branch = 0
	_draw = 0.0
	_atk_t = 99.0
	_rel_t = 99.0
	_cast_k = 0.0
	_bow_k_w = -1
	_arrow_y_w = -1.0
	_arrow_vis_w = -1
	_arrow_glow_w = -1.0
	_cloak_w = 99.0
	_bow_q_w = Quaternion(0, 0, 0, 0)
	_fore_q_w = Quaternion(0, 0, 0, 0)
	if _bow:
		_bow.quaternion = Quaternion.IDENTITY
		if not _bow_meshes.is_empty():
			_bow.mesh = _bow_meshes[0]
	if _arrow:
		_arrow.visible = true
		_arrow.position = Vector3(0, BRACE, ARROW_Z)
	if _fore:
		_fore.quaternion = Quaternion.IDENTITY
	if _cloak:
		_cloak.rotation = Vector3.ZERO
