class_name BlazeRiderRider
extends FireModel
## Blaze Rider rider (cavalry-mounts.md 10, task 13.V10): the Fire shock lancer on the shared 13.V2 Ember Boar. Seated
## with the kit's CharacterModel.set_seated (13.V1b); the scene that pairs it with the boar is art/units/fire/
## blaze_rider.tscn (BlazeRiderModel, the unit's model_scene). The old one-piece Blaze Rider's look, taken to hero
## quality: a stocky lancer in an orange gambeson under a bronze cuirass and a team tabard with a bronze sun disc, big
## team pauldrons with bronze rims, a short team cape; a bronze helm with a dark eye slit, a nasal and cheek guards,
## sweeping ivory horns and a team horsehair crest streaming back; a short red beard. A round team shield with a bronze
## rim, boss and a dark flame sigil on the left forearm; in the right fist a 3.1 m lance (bronze vamplate, bands, a
## glowing ember leaf head) with a swallow-tailed team pennon.
## Glow: the lance head only (own glow: flares at the charge); the boar's mane is the big read.
## Riding: the lance carried raised (REST_PITCH), lowered at the gallop (GALLOP_PITCH), the shield arm low; the kit's
## seat pose (lean, bob, head) underneath. The lance is aimed in the model frame (the seat pitch and the lean are
## compensated), so it stays steady and only bobs a little with the gait.
## Attack `lance_charge` (strike 0.12 s, 0.70 s): cock back, couch the lance level (slightly down), thrust (the arm
## drives forward, the right shoulder follows), recover. play_charge() (0.85 s, hit frame CHARGE_HIT 0.10 s): the lance
## drops level and stays couched, the rider leans into it behind the raised shield, the pennon streams, the lance head
## flares; signal charge_struck(at) at the hit frame (the lance tip, world).
## Death: FireModel's burn (coal glow + embers, burns away) while riding the boar's fall; the lance goes with the arm.
## Hooks (on top of the kit's): play_charge(), get_lance_tip() -> Vector3 (world), lance_pitch() -> float (deg, model
## frame, negative = tip up, like the Gloam Rider's), couch_amount() -> float (0-1), is_charging(),
## authored_mesh_count() -> int; signals charge_struck(at: Vector3) (the charge hit frame) and lance_struck(at: Vector3)
## (the attack strike), both at the lance tip (world).
## Budget (cavalry unit, section 10): 10 authored meshes, 10 draw instances (7 merged pivots + Lance, Pennon, VetTrim)
## + 1 particle system (BurnEmbers, 10, one-shot at the death), no blob (the boar's shows), 0 lights.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X).
const HIP := Vector3(0, 0.84, 0)
const SH_L := Vector3(-0.31, 1.37, 0.0)
const SH_R := Vector3(0.31, 1.37, 0.0)
const ELBOW_R := Vector3(0.35, 1.09, -0.02)
const FIST_R := Vector3(0.35, 1.06, 0.25)
const ELBOW_L := Vector3(-0.35, 1.09, -0.02)
const FIST_L := Vector3(-0.34, 1.05, 0.23)
const SHIELD_C := Vector3(-0.48, 1.09, 0.09)
const SHIELD_R := 0.34
## Lance (node-local at the fist, shaft along +Z): butt, head base, tip.
const LANCE_BUTT := -0.55
const LANCE_HEAD := 2.08
const LANCE_TIP := 2.58
const PENNON_Z := 1.80
## Lance pitch (deg above level, model frame): riding at rest, at the gallop, couched for the attack / the charge,
## raised for a cast salute. Yaw (deg, + = tip outward to the right).
const REST_PITCH := 48.0
const GALLOP_PITCH := 30.0
const ATTACK_PITCH := -7.0
const CHARGE_PITCH := -2.0
const CAST_PITCH := 84.0
const REST_YAW := 7.0
const COUCH_YAW := -3.0
const ATTACK_LEN := 0.70
const STRIKE_T := 0.12
const CHARGE_LEN := 0.85
const CHARGE_HIT := 0.10

# Attack / charge tracks [t, v, ease, ...] (FireModel._kf format).
static var A_COUCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, 1.0, 1, 0.40, 1.0, 0, 0.70, 0.0, 0])
static var A_ARM_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.10, 1, 0.13, 0.32, 2, 0.32, 0.18, 0, 0.70, 0.0, 0])
static var A_CHEST_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.03, 1, 0.13, 0.08, 2, 0.35, 0.04, 0, 0.70, 0.0, 0])
static var C_K := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])
static var C_ARM_Z := PackedFloat32Array([0.0, 0.0, 0, 0.06, -0.08, 1, 0.11, 0.30, 2, 0.40, 0.12, 0, 0.85, 0.0, 0])

var _parts_n: int = 0
var _lance: MeshInstance3D
var _pennon: MeshInstance3D
var _embers: GPUParticles3D

var _atk_k: float = 0.0          # couch weight of the attack this frame
var _charge_t: float = 99.0
var _charge_k: float = 0.0
var _cast_k: float = 0.0
var _flare: float = 0.0
var _pitch: float = REST_PITCH   # lance pitch of the last posed frame (deg)
var _lance_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _pennon_w: float = 99.0
var _glow_w: float = -1.0


# ================================================================ public hooks

## The charge (the unit's charge hit): lance couched level, lean in behind the shield, the head flares. 0.85 s;
## charge_struck(at) at CHARGE_HIT.
func play_charge() -> void:
	if _dead:
		return
	_charge_t = 0.0
	_flare = 1.0
	set_process(true)


## World position of the lance tip (VFX: charge streak, impact).
func get_lance_tip() -> Vector3:
	if _lance and _lance.is_inside_tree():
		return _lance.global_transform * Vector3(0, 0, LANCE_TIP)
	return global_position + Vector3(0, 1.8, 2.0)


## The kit's weapon-tip hook (champions); here the lance tip.
func get_weapon_tip() -> Variant:
	return get_lance_tip()


## Lance pitch of the last posed frame (deg, model frame; negative = tip up, like the Gloam Rider's).
func lance_pitch() -> float:
	return -_pitch


## How far the lance is couched (0-1): the attack's or the charge's, the larger.
func couch_amount() -> float:
	return maxf(_atk_k, _charge_k)


func is_charging() -> bool:
	return _charge_t < CHARGE_LEN


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	_sculpt($Root/Hips, "br_hips_v1", _hips_sculpt)
	for leg: Node3D in [$Root/Hips/LegL, $Root/Hips/LegR]:
		var sx: float = -1.0 if leg.name == "LegL" else 1.0
		_sculpt(leg, "br_leg_%s_v1" % sx, func(s: Dictionary) -> void: _leg_sculpt(s, sx))
	_sculpt($Root/Chest, "br_chest_v1", _chest_sculpt)
	_sculpt($Root/Chest/Head, "br_head_v1", _head_sculpt)
	_sculpt($Root/Chest/ArmL, "br_arm_l_v1", _arm_l_sculpt)
	_sculpt($Root/Chest/ArmR, "br_arm_r_v1", _arm_r_sculpt)
	# Own (keep_separate) parts: the lance at the fist (+ the pennon on it), the level-4 helm band.
	_lance = _sculpt($Root/Chest/ArmR, "br_lance_v1", _lance_sculpt, FIST_R, true, "Lance")
	_lance.set_meta(&"own_glow", true)
	_pennon = _sculpt(_lance, "br_pennon_v1", _pennon_sculpt, FIST_R + Vector3(0, 0, PENNON_Z), true, "Pennon")
	var vet := add_part($Root/Chest/Head, torus(0.215, 0.25, 16), palette(&"unit_gold_trim"), Vector3(0, 1.705, -0.01),
		Vector3(-4, 0, 0), Vector3(1.0, 1.0, 1.08), true, "VetTrim")
	vet.set_meta(&"vet_trim", true)
	_parts_n += 1
	# The death burn: 10 embers from the body (FireModel restarts them when the body glows).
	_embers = CharacterModel.make_motes(Color(1.0, 0.42, 0.08), 10, 0.9, 0.32, 1.5, 0.15, false, true)
	_embers.name = "BurnEmbers"
	_embers.set_meta(&"burn_fx", true)
	_embers.set_meta(&"keep_separate", true)
	_embers.position = Vector3(0, 0.25, 0)
	$Root/Chest.add_child(_embers)


## One authored part from a multi-material sculpt (MountModel's builders), like GladeOutriderRider._sculpt.
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
	return palette(StringName(name))


## Rotation taking +Y onto `d`.
static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


## Cylinder / cone from a (radius ra) to b (radius rb).
static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 8) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


## Flame tongue along +Y (length 1, width ~0.8), the tip curling toward +Z; flattened (a sigil / plate cut-out).
static func _flame_mesh() -> Mesh:
	return MountModel.tube_mesh("br_flame_v1", PackedVector3Array([Vector3(0, -0.04, 0), Vector3(0, 0.28, -0.05),
		Vector3(0, 0.58, 0.02), Vector3(0, 0.82, 0.16), Vector3(0, 1.0, 0.34)]),
		PackedFloat32Array([0.36, 0.40, 0.28, 0.13, 0.0]), 7, true, 0.35)


# ---------------------------------------------------------------- body

func _hips_sculpt(s: Dictionary) -> void:
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var leather := m("fire_leather")
	var bronze := m("fire_bronze")
	var sec := m("fire_sec_rider")
	# gambeson skirt (split for riding), belt with a bronze sun buckle
	_put(s, cyl(0.215, 0.255, 0.24, 12), sec, Vector3(0, 0.82, 0))
	_put(s, cyl(0.232, 0.232, 0.075, 12, false), leather, Vector3(0, 0.935, 0))
	_put(s, cyl(0.07, 0.07, 0.03, 10), bronze, Vector3(0, 0.935, 0.235), Vector3(90, 0, 0))
	# tabard flaps: the front one lies forward over the thighs (seated), the back one hangs over the cantle
	_put(s, box(Vector3(0.26, 0.36, 0.03)), cloth, Vector3(0, 0.86, 0.33), Vector3(-58, 0, 0))
	_put(s, box(Vector3(0.265, 0.06, 0.035)), cdark, Vector3(0, 0.77, 0.47), Vector3(-58, 0, 0))
	_put(s, box(Vector3(0.28, 0.40, 0.03)), cloth, Vector3(0, 0.74, -0.24), Vector3(14, 0, 0))
	_put(s, box(Vector3(0.285, 0.06, 0.035)), cdark, Vector3(0, 0.58, -0.28), Vector3(14, 0, 0))
	# bronze tassets over the hips
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.05, 0.20, 0.22)), bronze, Vector3(0.245 * sx, 0.84, 0.02), Vector3(0, 0, 12.0 * sx))
		_put(s, sphere(0.026, 6, 3), leather, Vector3(0.262 * sx, 0.925, 0.02))


## A leg rooted at the hip (sx -1 left, +1 right): dark trousers, a bronze knee cop, the shin (bronze greave) authored
## bent back by seat_leg_forward_deg so it hangs straight down in the saddle, a leather boot, the toe level seated.
func _leg_sculpt(s: Dictionary, sx: float) -> void:
	var trousers := m("fire_cloth_dark")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var fwd := deg_to_rad(seat_leg_forward_deg)
	var hip := Vector3(0.12 * sx, 0.84, 0)
	var knee := Vector3(0.13 * sx, 0.47, 0.03)
	var shin := Vector3(0, -cos(fwd), -sin(fwd))
	var ankle := knee + shin * 0.30
	_seg(s, trousers, hip, knee, 0.10, 0.078, 8)
	_put(s, sphere(0.085, 8, 4), bronze, knee + Vector3(0, 0.01, 0.03), Vector3.ZERO, Vector3(1.0, 1.1, 0.9))
	_seg(s, bronze, knee, ankle, 0.074, 0.064, 8)
	var front := Vector3(0, shin.z, -shin.y)
	_seg(s, bronze, knee + shin * 0.04 + front * 0.05, ankle + front * 0.045, 0.028, 0.02, 5)   # greave ridge
	var foot_dir := Vector3(0, sin(fwd), cos(fwd))
	var foot_c := ankle + foot_dir * 0.07 + Vector3(0, -0.035, 0)
	MountModel.sculpt_add(s, capsule(0.068, 0.28), Transform3D(_to_dir(foot_dir), foot_c), leather)
	_put(s, cyl(0.085, 0.075, 0.09, 8), leather, ankle - shin * 0.02, Vector3(rad_to_deg(-fwd), 0, 0))


func _chest_sculpt(s: Dictionary) -> void:
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var sec := m("fire_sec_rider")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	# gambeson torso, then the bronze cuirass over it (flattened front-back)
	var prof := PackedVector2Array([Vector2(0.19, 0.90), Vector2(0.215, 1.0), Vector2(0.25, 1.14), Vector2(0.265, 1.26),
		Vector2(0.245, 1.36), Vector2(0.14, 1.45), Vector2(0.0, 1.47)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("br_torso_v1", prof, 12),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.82)), Vector3.ZERO), sec)
	var cu := PackedVector2Array([Vector2(0.232, 1.02), Vector2(0.268, 1.15), Vector2(0.283, 1.26), Vector2(0.265, 1.35),
		Vector2(0.205, 1.415), Vector2(0.13, 1.44)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("br_cuirass_v1", cu, 14, false),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.86)), Vector3.ZERO), bronze)
	_put(s, cyl(0.24, 0.24, 0.04, 14, false), leather, Vector3(0, 1.03, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.86))
	# team tabard on the chest with a dark hem and the bronze sun disc (a dark flame on it)
	_put(s, box(Vector3(0.30, 0.34, 0.03)), cloth, Vector3(0, 1.18, 0.245), Vector3(-4, 0, 0))
	_put(s, box(Vector3(0.305, 0.05, 0.035)), cdark, Vector3(0, 1.02, 0.25), Vector3(-4, 0, 0))
	_put(s, cyl(0.085, 0.085, 0.025, 12), bronze, Vector3(0, 1.21, 0.265), Vector3(86, 0, 0))
	MountModel.sculpt_add(s, _flame_mesh(), Transform3D(Basis(Vector3(0, 0, 0.12), Vector3(0, 0.14, 0),
		Vector3(-0.11, 0, 0)), Vector3(0, 1.15, 0.283)), cdark)
	# bronze gorget
	_put(s, cyl(0.12, 0.165, 0.09, 12, false), bronze, Vector3(0, 1.45, -0.005))
	# big team pauldrons: a dome, a bronze rim, two bronze lames below
	for sx: float in [-1.0, 1.0]:
		var pf := MountModel.frame(Vector3(0.345 * sx, 1.42, -0.01), Vector3(0.5 * sx, 1.0, 0.0), Vector3.BACK)
		MountModel.sculpt_add(s, MountModel.lathe_mesh("br_pauldron_v1", PackedVector2Array([Vector2(0.20, -0.07),
			Vector2(0.215, -0.01), Vector2(0.185, 0.07), Vector2(0.11, 0.13), Vector2(0.0, 0.15)]), 12), pf, cloth)
		MountModel.sculpt_add(s, torus(0.19, 0.235, 14), Transform3D(pf.basis, pf * Vector3(0, -0.055, 0)), bronze)
		for k: int in 2:
			var lp := pf * Vector3(0.015 * sx * float(k + 1), -0.12 - 0.07 * float(k), 0.0)
			MountModel.sculpt_add(s, cyl(0.17 - 0.02 * float(k), 0.175 - 0.02 * float(k), 0.05, 12, false),
				Transform3D(pf.basis, lp), bronze)
		_put(s, sphere(0.03, 6, 3), leather, pf * Vector3(0, 0.12, 0.13))
	# short team cape from the shoulders, hanging back over the cantle
	_put(s, cape(0.58, 0.62), m("fire_cape"), Vector3(0, 1.10, -0.34), Vector3(15, 0, 0))
	_put(s, box(Vector3(0.52, 0.06, 0.06)), leather, Vector3(0, 1.40, -0.25))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("fire_skin")
	var hair := m("fire_hair")
	var bronze := m("fire_bronze")
	var cloth := m("fire_cloth")
	var eye := m("unit_eye_dark")
	_put(s, cyl(0.075, 0.085, 0.12, 8), skin, Vector3(0, 1.50, 0.02))
	# leather coif under the helm: covers the nape and the sides of the neck
	_put(s, sphere(0.165, 10, 5), m("fire_leather"), Vector3(0, 1.575, -0.035), Vector3.ZERO, Vector3(1.08, 0.95, 1.0))
	# face, the short red beard
	_put(s, sphere(0.145, 10, 6), skin, Vector3(0, 1.60, 0.05), Vector3.ZERO, Vector3(0.95, 1.05, 0.95))
	_put(s, sphere(0.11, 8, 4), hair, Vector3(0, 1.515, 0.125), Vector3(20, 0, 0), Vector3(1.15, 0.8, 0.75))
	MountModel.sculpt_add(s, cyl(0.0, 0.06, 0.12, 6), Transform3D(_to_dir(Vector3(0, -1.0, 0.45)).scaled_local(
		Vector3(1.0, 1.0, 0.6)), Vector3(0, 1.43, 0.19)), hair)
	# the helm: dome, brow rim, the dark eye slit behind a nasal, cheek guards
	var hp := PackedVector2Array([Vector2(0.205, 1.635), Vector2(0.217, 1.70), Vector2(0.203, 1.775), Vector2(0.158, 1.845),
		Vector2(0.08, 1.888), Vector2(0.0, 1.897)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("br_helm_v1", hp, 14),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.08)), Vector3(0, 0, -0.01)), bronze)
	_put(s, torus(0.195, 0.232, 16), bronze, Vector3(0, 1.645, -0.01), Vector3.ZERO, Vector3(1.0, 1.0, 1.08))
	_put(s, box(Vector3(0.25, 0.05, 0.05)), eye, Vector3(0, 1.618, 0.178))
	_put(s, box(Vector3(0.045, 0.13, 0.035)), bronze, Vector3(0, 1.585, 0.205), Vector3(-8, 0, 0))
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.04, 0.17, 0.15)), bronze, Vector3(0.175 * sx, 1.55, 0.06), Vector3(-6, 0, 8.0 * sx))
		# ivory horns sweeping out, up and forward (the helm read)
		var hn := PackedVector3Array([Vector3(0.17, 1.74, -0.02) * Vector3(sx, 1, 1), Vector3(0.31, 1.79, -0.07) * Vector3(sx, 1, 1),
			Vector3(0.40, 1.91, -0.03) * Vector3(sx, 1, 1), Vector3(0.39, 2.05, 0.08) * Vector3(sx, 1, 1)])
		MountModel.sculpt_add(s, MountModel.tube_mesh("br_horn_%s_v1" % sx, hn, PackedFloat32Array([0.068, 0.052, 0.033,
			0.0]), 7), Transform3D.IDENTITY, skin)
		_put(s, torus(0.05, 0.08, 10), bronze, Vector3(0.19 * sx, 1.745, -0.025), Vector3(0, 0, 80.0 * sx))
	# team horsehair crest along the ridge, streaming back
	_put(s, box(Vector3(0.05, 0.05, 0.30)), bronze, Vector3(0, 1.892, -0.03), Vector3(-6, 0, 0))
	for i: int in 5:
		var f: float = float(i) / 4.0
		var z: float = lerpf(0.11, -0.21, f)
		var y: float = 1.905 - 0.25 * f * f
		MountModel.sculpt_lock(s, cloth, Vector3(0, y, z), Vector3(0, lerpf(0.35, -0.2, f), -1.0).normalized(), Vector3.UP,
			lerpf(0.13, 0.10, f), lerpf(0.28, 0.34, f), 0.075)


func _arm_l_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, -1.0)
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	# round team shield on the forearm, face outward (-X): rim, boss, rivets, a dark flame sigil
	var sb := Basis(Vector3.BACK, PI * 0.5)   # cylinder axis along X
	MountModel.sculpt_add(s, cyl(SHIELD_R, SHIELD_R, 0.06, 18), Transform3D(sb, SHIELD_C), cloth)
	MountModel.sculpt_add(s, torus(SHIELD_R - 0.015, SHIELD_R + 0.035, 20), Transform3D(sb, SHIELD_C + Vector3(-0.012, 0, 0)),
		bronze)
	_put(s, sphere(0.085, 10, 5), bronze, SHIELD_C + Vector3(-0.04, 0, 0), Vector3.ZERO, Vector3(0.7, 1.0, 1.0))
	for k: int in 6:
		var a := TAU * float(k) / 6.0 + 0.26
		_put(s, sphere(0.022, 5, 2), bronze, SHIELD_C + Vector3(-0.034, cos(a) * 0.25, sin(a) * 0.25))
	# the sigil lies on the shield face: flame +Y up, flat along X
	MountModel.sculpt_add(s, _flame_mesh(), Transform3D(Basis(Vector3(0.012, 0, 0), Vector3(0, 0.30, 0), Vector3(0, 0, 0.25)),
		SHIELD_C + Vector3(-0.037, -0.17, 0.0)), cdark)
	_put(s, box(Vector3(0.03, 0.05, 0.22)), leather, SHIELD_C + Vector3(0.05, 0.0, 0.0))


func _arm_r_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, 1.0)


## Upper arm (gambeson orange), elbow cop, bronze vambrace, leather fist with a bronze cuff; forearm held forward.
func _arm_sculpt(s: Dictionary, sx: float) -> void:
	var sec := m("fire_sec_rider")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var sh: Vector3 = SH_L if sx < 0.0 else SH_R
	var el: Vector3 = ELBOW_L if sx < 0.0 else ELBOW_R
	var fi: Vector3 = FIST_L if sx < 0.0 else FIST_R
	_put(s, sphere(0.09, 8, 4), sec, sh + Vector3(0, -0.03, 0))
	_seg(s, sec, sh, el, 0.082, 0.07, 8)
	_put(s, sphere(0.072, 8, 4), bronze, el + Vector3(0, 0, -0.02), Vector3.ZERO, Vector3(1.0, 1.0, 1.15))
	_seg(s, bronze, el, fi - (fi - el).normalized() * 0.05, 0.074, 0.066, 8)
	var d := (fi - el).normalized()
	MountModel.sculpt_add(s, cyl(0.078, 0.078, 0.05, 8, false), Transform3D(_to_dir(d), fi - d * 0.07), bronze)
	_put(s, sphere(0.078, 8, 4), leather, fi, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


## The lance (keep_separate "Lance", node-local at the fist, shaft along +Z): bronze butt cap, leather grip, a bronze
## vamplate, the ash shaft with bronze bands, a collar and the glowing ember leaf head.
func _lance_sculpt(s: Dictionary) -> void:
	var wood := m("fire_wood")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var glow := m("fire_glow")
	var z := Basis(Vector3.RIGHT, PI * 0.5)   # +Y -> +Z
	MountModel.sculpt_add(s, MountModel.tube_mesh("br_shaft_v1", PackedVector3Array([Vector3(0, 0, LANCE_BUTT),
		Vector3(0, 0, 0.8), Vector3(0, 0, LANCE_HEAD)]), PackedFloat32Array([0.05, 0.052, 0.04]), 7), Transform3D.IDENTITY,
		wood)
	_put(s, sphere(0.06, 7, 4), bronze, Vector3(0, 0, LANCE_BUTT), Vector3.ZERO, Vector3(1.0, 1.0, 1.4))
	MountModel.sculpt_add(s, cyl(0.062, 0.062, 0.22, 8), Transform3D(z, Vector3(0, 0, -0.02)), leather)
	MountModel.sculpt_add(s, cyl(0.06, 0.175, 0.24, 12), Transform3D(z, Vector3(0, 0, 0.22)), bronze)
	for bz: float in [0.95, 1.55]:
		MountModel.sculpt_add(s, cyl(0.058, 0.058, 0.05, 8), Transform3D(z, Vector3(0, 0, bz)), bronze)
	MountModel.sculpt_add(s, cyl(0.07, 0.055, 0.12, 8), Transform3D(z, Vector3(0, 0, LANCE_HEAD - 0.02)), bronze)
	MountModel.sculpt_add(s, MountModel.tube_mesh("br_lance_head_v1", PackedVector3Array([Vector3(0, 0, LANCE_HEAD + 0.02),
		Vector3(0, 0, LANCE_HEAD + 0.15), Vector3(0, 0, LANCE_HEAD + 0.34), Vector3(0, 0, LANCE_TIP)]),
		PackedFloat32Array([0.06, 0.125, 0.075, 0.0]), 8, true, 0.38), Transform3D.IDENTITY, glow)


## The pennon (keep_separate "Pennon", child of the lance; node-local: the hoist along the shaft (+Z) at the origin,
## the fly hanging along -Y): the kit's cape plane with the banner shader (fixed edge = the hoist, swallow-tailed fly).
func _pennon_sculpt(s: Dictionary) -> void:
	var b := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
	MountModel.sculpt_add(s, cape(0.42, 0.58), Transform3D(b, Vector3(0, -0.33, 0)), m("fire_pennon"))


# ================================================================ motion

func _after_ready() -> void:
	super()
	if _embers and not _burn_fx.has(_embers):
		_burn_fx.append(_embers)
	_write_glow()


## `lance_charge`: couch, thrust (strike STRIKE_T), recover. Arms and the lance are posed in _pose_seated.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"lance_charge":
		return super._pose_attack(prev, t)
	_atk_k = _kf(t, A_COUCH)
	rot(P_CHEST, Vector3(_kf(t, R_CHEST_X) * DEG, _kf(t, R_CHEST_Y) * DEG, 0))
	pos(P_CHEST, Vector3(0, 0, _kf(t, A_CHEST_Z)))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, A_ARM_Z)))
	rot(P_ARM_R, Vector3(_kf(t, R_ARM_X) * 0.5 * DEG, 0, 0))
	if prev < STRIKE_T and t >= STRIKE_T:
		_on_action_event(&"release")
		lance_struck.emit(get_lance_tip())
	if t >= ATTACK_LEN:
		_atk_k = 0.0
	return t < ATTACK_LEN


## A lance salute for any cast: the lance raised upright, the shield out.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-35.0 * DEG * _cast_k, 0, 0))
	return 0.75


func _extra_process(dt: float) -> void:
	super(dt)
	if _action != &"attack":
		_atk_k = 0.0
	if _action != &"cast":
		_cast_k = 0.0
	if _charge_t < CHARGE_LEN:
		var prev := _charge_t
		_charge_t += dt
		_charge_k = _kf(_charge_t, C_K) if not _dead else 0.0
		if prev < CHARGE_HIT and _charge_t >= CHARGE_HIT and not _dead:
			charge_struck.emit(get_lance_tip())
		if _charge_t >= CHARGE_LEN:
			_charge_k = 0.0
	else:
		_charge_k = 0.0
		_flare = maxf(0.0, _flare - dt / 0.5)
	_write_glow()


## Riding: the kit's seat pose, then the lance arm, the shield arm, the charge lean, the lance aim and the pennon.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var ck := _charge_k
	var gm: float = gallop * moving
	var bounce: float = lerpf(1.5 * sin(2.0 * TAU * gait), 4.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	# arms (replace the kit's reins): lance fist at the hip, shield arm low; the charge raises the shield
	_off_rot[P_ARM_R] = sar + Vector3((4.0 + bounce * 0.5 - 4.0 * ck) * DEG, 0, -3.0 * DEG) * w
	_off_rot[P_ARM_L] = sal + Vector3((-6.0 + bounce - 34.0 * ck) * DEG, 0, (5.0 + 10.0 * ck) * DEG) * w
	if ck > 0.0:
		rot(P_CHEST, Vector3(10.0 * DEG * ck * w, -5.0 * DEG * ck * w, 0))
		rot(P_HEAD, Vector3(-10.0 * DEG * ck * w, 4.0 * DEG * ck * w, 0))
		pos(P_ARM_R, Vector3(0, 0, _kf(_charge_t, C_ARM_Z) * w))
	# the lance: aimed in the model frame (seat pitch + lean compensated), bobbing a little with the gait
	var p: float = lerpf(REST_PITCH, GALLOP_PITCH, gm) + lerpf(1.2 * sin(2.0 * TAU * gait), 3.0 * sin(TAU * (gait - 0.3)),
		gallop) * moving
	var yaw: float = REST_YAW
	var couch: float = maxf(ck, _atk_k)
	if couch > 0.0:
		p = lerpf(p, CHARGE_PITCH if ck >= _atk_k else ATTACK_PITCH, couch)
		yaw = lerpf(yaw, COUCH_YAW, couch)
	if _cast_k > 0.0:
		p = lerpf(p, CAST_PITCH, _cast_k)
	if not _dead:
		_pitch = p
		_aim_lance(p, yaw)
	# the pennon streams back with the speed (and at the charge)
	if _pennon:
		var a: float = lerpf(12.0, 48.0, gm) + 30.0 * couch
		if _tier == 0 and not _dead:
			a += (4.0 + 5.0 * gm) * sin((_t + _phase_off) * (5.0 + 6.0 * gm))
		a = snappedf(a, 0.5)
		if a != _pennon_w:
			_pennon_w = a
			_pennon.rotation = Vector3(a * DEG, 0, 0)


## Turns the lance (child of ArmR) so its shaft points along pitch / yaw (deg) in the model frame.
func _aim_lance(pitch_deg: float, yaw_deg: float) -> void:
	if _lance == null:
		return
	var pr := pitch_deg * DEG
	var yr := yaw_deg * DEG
	var d := Vector3(sin(yr) * cos(pr), sin(pr), cos(yr) * cos(pr))
	var up := Vector3.UP - d * d.y
	if up.length_squared() < 1e-4:
		up = Vector3.BACK
	up = up.normalized()
	var want := Basis(up.cross(d), up, d)
	var rb := Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT])
	var bc := Basis.from_euler(_rest_rot[P_CHEST] + _off_rot[P_CHEST])
	var ba := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R])
	var q := ((rb * bc * ba).inverse() * want).orthonormalized().get_rotation_quaternion()
	if not q.is_equal_approx(_lance_q_w):
		_lance_q_w = q
		_lance.quaternion = q


## The lance head's own glow: the kit's glow level, flared by the charge.
func _write_glow() -> void:
	if _lance == null:
		return
	var g: float = snappedf(glow_level() * (1.0 + 1.6 * _flare + 0.6 * _charge_k), 0.05)
	if g != _glow_w:
		_glow_w = g
		_lance.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	super()
	_atk_k = 0.0
	_charge_t = 99.0
	_charge_k = 0.0
	_cast_k = 0.0
	_flare = 0.0
	_pitch = REST_PITCH
	_lance_q_w = Quaternion(0, 0, 0, 0)
	_pennon_w = 99.0
	_glow_w = -1.0
	_write_glow()
