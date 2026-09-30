class_name StagrunnerRider
extends NatureModel
## Stagrunner rider (cavalry-mounts.md 4 / 10, task 13.V9): the Nature light cavalry on the 13.V5 Grove Stag. Seated
## with the kit's CharacterModel.set_seated (13.V1b); stagrunner.tscn (StagrunnerModel, the unit's model_scene) pairs
## it with the stag.
## Look: a lean, forward-crouched light rider in a DARK bark-lamellar jerkin (three pale bark bands), mossy sleeves
## and leggings, bark greaves; a bark half-helm with a GOLD LEAF CREST swept back and a glowing seed on the brow; the
## team cowl over the lower face, a team sash; a gold-leaf pauldron on the left shoulder. The LEAF CLOAK: a long,
## narrow mantle of golden and amber leaves in two hinged segments ("Cloak" + "CloakTail") ending in three pointed
## leaf tips; it drapes over the stag's rump at rest and streams straight back like a banner at the gallop.
## The BARK SHORTSPEAR (2.1 m, "Spear", right hand): a bark shaft with dark bands and a leather grip, a thorn butt, a
## pale heartwood leaf blade with a glowing sap vein and a glowing seed at the socket, a tuft of gold leaves and a
## TEAM PENNON under the blade.
## Glow points: the brow seed (merged, kit-driven) and the spear's vein + seed (own glow: flares at strikes/charges).
## Carry: upright and tilted forward at rest / the walk (CARRY_EL), lowered to a level couch beside the stag's neck at
## the gallop (COUCH_EL, under the antlers); left hand on the reins.
## `lance_charge` (play_attack, 0.55 s, strike 0.12 s, attack_windup 0): the spear levels onto the target (yaw clamped
## YAW_MIN..YAW_MAX, the grip slides back on the shaft for side targets), cocks back (0.06), thrusts (0.12, the right
## shoulder drives forward, the rider leans in), recovers. play_charge() (0.85 s, strike 0.10 s = the stag's
## CHARGE_HIT): a low crouch, the spear couched level and driven forward, blade flare, cloak flare.
## Hooks (on top of the kit's): play_charge(), is_charging(), set_aim_target(target: Variant) (Node3D tracked each
## frame, Vector3 world point, null = forward), get_spear_tip() -> Vector3, get_spear_dir() -> Vector3 (world),
## spear_elevation() -> float (deg, world), authored_mesh_count() -> int; signal spear_struck(tip, dir, charge)
## (world, one frame after the strike frame so the pose is applied).
## Budget (cavalry rider, section 10): 11 authored meshes, 11 draw instances (7 merged pivots + ForearmR, Spear,
## Cloak, CloakTail), no blob (the stag's shows), 0 lights, 0 particles.

signal spear_struck(tip: Vector3, dir: Vector3, charge: bool)

const OWN := "res://art/units/nature/stagrunner/materials/"

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP := Vector3(0, 0.84, 0)
const CHEST_O := Vector3(0, 0.92, 0)
const SH_L := Vector3(-0.28, 1.36, 0.0)
const SH_R := Vector3(0.28, 1.36, 0.0)
const GRIP_L := Vector3(-0.28, 0.80, 0.0)
const ELBOW_R := Vector3(0.28, 1.08, 0.0)
const HAND_R := Vector3(0.28, 0.80, 0.0)
const UPPER_R := 0.28
const FORE_R := 0.28
const CLOAK_O := Vector3(0, 1.38, -0.19)
const CLOAK_LEN := 0.56
const TAIL_O := Vector3(0, 0.82, -0.21)          # CLOAK_O + (0, -CLOAK_LEN, -0.02)
# Spear frame: the grip at the origin, the shaft along +Y toward the blade.
const BUTT := -0.64
const SOCKET := 1.02
const TIP := 1.58
const SPEAR_LEN := 2.22
# Grips (chest frame) and spear angles (deg, model frame: elevation above the horizontal, yaw + = right).
const CARRY_GRIP := Vector3(0.30, -0.06, 0.14)
const CARRY_EL := 78.0
const CARRY_YAW := 10.0
const COUCH_GRIP := Vector3(0.30, -0.08, 0.10)
const COUCH_EL := 4.0
const COUCH_YAW := 8.0
## Couched, the hand slides back on the shaft so the blade reaches past the stag's nose (m).
const COUCH_SLIDE := 0.36
const FOOT_GRIP := Vector3(0.30, -0.10, 0.18)
const FOOT_EL := 76.0
const CAST_GRIP := Vector3(0.24, 0.34, 0.14)
const CAST_EL := 84.0
const YAW_MIN := -28.0
const YAW_MAX := 70.0
const THRUST := 0.36
const ATK_LEN := 0.55
const STRIKE := 0.12
const CH_LEN := 0.85
const CH_STRIKE := 0.10
const GRIP_H := 1.8          # model-space height of the grip when seated (the thrust elevation)
const POLE_CARRY := Vector3(1.0, -0.25, -0.5)
const POLE_THRUST := Vector3(0.9, -0.5, -0.45)

var _parts_n: int = 0
var _spear: MeshInstance3D
var _fore: MeshInstance3D
var _cloak: MeshInstance3D
var _tail: MeshInstance3D

# aim / action state
var _aim_mode: int = 0          # 0 none (forward), 1 world point, 2 node
var _aim_point: Vector3 = Vector3.ZERO
var _aim_node: Node3D = null
var _phi: float = 0.0           # target azimuth (deg, model frame, + = right)
var _elev: float = -8.0         # target elevation from the grip (deg)
var _phi_valid: bool = false
var _atk_t: float = 99.0
var _chg_t: float = 99.0
var _flare: float = 0.0
var _cast_k: float = 0.0
# written-value caches
var _fore_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _cloak_w: float = 999.0
var _tail_w: float = 999.0
var _glow_w: float = -1.0
# IK scratch
var _ik_u: Basis = Basis.IDENTITY
var _ik_f: Basis = Basis.IDENTITY


# ================================================================ public hooks

## The charge hit (Unit.charged; the root also plays the stag's charge): 0.85 s, strike at CH_STRIKE.
func play_charge() -> void:
	if _dead:
		return
	_chg_t = 0.0
	_flare = 1.0
	set_process(true)


func is_charging() -> bool:
	return not _dead and _chg_t < CH_LEN


## Where to thrust: a Node3D (tracked every frame at its centre + 0.9 m), a Vector3 world point, or null (forward).
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
		_elev = -8.0
		_phi_valid = false


func get_spear_tip() -> Vector3:
	if _spear and _spear.is_inside_tree():
		return _spear.global_transform * Vector3(0, TIP, 0)
	return global_position + Vector3.UP * 2.8


func get_spear_dir() -> Vector3:
	if _spear and _spear.is_inside_tree():
		return _spear.global_transform.basis.y.normalized()
	return Vector3.UP


func spear_elevation() -> float:
	return rad_to_deg(asin(clampf(get_spear_dir().y, -1.0, 1.0)))


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var chest: Node3D = $Root/Chest
	var arm_r: Node3D = $Root/Chest/ArmR
	_sculpt($Root/Hips, "sgr_hips_v1", _hips_sculpt)
	for leg: Node3D in [$Root/Hips/LegL, $Root/Hips/LegR]:
		var sx: float = -1.0 if leg.name == "LegL" else 1.0
		_sculpt(leg, "sgr_leg_%s_v1" % sx, func(s: Dictionary) -> void: _leg_sculpt(s, sx))
	_sculpt(chest, "sgr_chest_v1", _chest_sculpt)
	_sculpt($Root/Chest/Head, "sgr_head_v2", _head_sculpt)
	# Face (FaceKit, face rework 2026-09-28): fierce hazel eyes under the helm brow band, a hard grin of a lancer.
	var hc := Vector3(0, 1.62, 0.05)
	_face = FaceKit.attach(self, $Root/Chest/Head, "stagrunner_rider", {
		"center": hc, "radius": 0.145, "head_mesh": sphere(0.145, 10, 6), "head_scale": Vector3(0.95, 1.08, 0.95),
		"head_at": hc, "preset": &"stern", "skin": NatureFaces.SKIN.darkened(0.05), "hair": NatureFaces.CHESTNUT,
		"eyes": NatureFaces.EYE_HAZEL, "detail": &"low",
		"x": NatureFaces.lean_x(1.1, {&"neutral": {"mouth": {"kind": "smirk"}}}), "palette": NatureFaces.pal(NatureFaces.CHESTNUT),
		"eye": {"c": Vector2(0.050, 0.018)},
	})
	_sculpt($Root/Chest/ArmL, "sgr_arm_l_v1", _arm_l_sculpt)
	_sculpt(arm_r, "sgr_arm_r_v1", _arm_r_sculpt)
	# Own (keep_separate) parts: forearm (elbow), the spear (posed every frame), the two cloak segments.
	_fore = _sculpt(arm_r, "sgr_fore_v1", _fore_sculpt, ELBOW_R, true, "ForearmR")
	_spear = _sculpt(chest, "sgr_spear_v1", _spear_sculpt, CHEST_O + CARRY_GRIP, true, "Spear")
	_spear.set_meta(&"own_glow", true)
	_cloak = _sculpt(chest, "sgr_cloak_v1", _cloak_sculpt, CLOAK_O, true, "Cloak")
	_tail = _sculpt(_cloak, "sgr_tail_v1", _tail_sculpt, TAIL_O, true, "CloakTail")


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
	if name.begins_with("stagrunner"):
		return MountModel.material_at(OWN + name + ".tres")
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


## Two-sided strip between a left and a right edge polyline (same point count): capes, pennons. `thick` separates
## the two faces along the local normal. Cached by key.
static func _strip_mesh(key: String, left: PackedVector3Array, right: PackedVector3Array, thick: float) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := left.size()
	for i: int in n - 1:
		var a := left[i]
		var b := right[i]
		var c := right[i + 1]
		var d := left[i + 1]
		var nf := (b - a).cross(d - a)
		if nf.length_squared() < 1e-10:
			nf = (c - b).cross(d - b)
		nf = nf.normalized()
		var o := nf * thick * 0.5
		# Godot's front faces are clockwise: (a, c, b) faces +nf
		for tri: Array in [[a, c, b], [a, d, c]]:
			st.set_normal(nf)
			st.add_vertex(tri[0] + o)
			st.set_normal(nf)
			st.add_vertex(tri[1] + o)
			st.set_normal(nf)
			st.add_vertex(tri[2] + o)
			st.set_normal(-nf)
			st.add_vertex(tri[0] - o)
			st.set_normal(-nf)
			st.add_vertex(tri[2] - o)
			st.set_normal(-nf)
			st.add_vertex(tri[1] - o)
	st.index()
	return _cached(key, st.commit())


# ---------------------------------------------------------------- body

func _hips_sculpt(s: Dictionary) -> void:
	var dark := m("nature_bark_dark")
	var bark := m("nature_bark")
	var cloth := m("nature_cloth")
	var gold := m("stagrunner_leaf_gold")
	var amber := m("stagrunner_leaf_amber")
	var blade := m("stagrunner_blade")
	# flared dark tasset skirt (split for riding), belt, a heartwood buckle
	_put(s, cyl(0.20, 0.25, 0.24, 10), dark, Vector3(0, 0.81, 0))
	_put(s, cyl(0.215, 0.215, 0.07, 10, false), dark, Vector3(0, 0.935, 0))
	_put(s, box(Vector3(0.08, 0.06, 0.03)), blade, Vector3(0, 0.935, 0.215))
	# bark lamellar tassets around the skirt (none at the front centre: the team tab hangs there)
	for a: float in [-150.0, -100.0, -55.0, 55.0, 100.0, 150.0, 180.0]:
		var r := deg_to_rad(a)
		var out := Vector3(sin(r), 0, cos(r))
		_put(s, box(Vector3(0.13, 0.19, 0.03)), bark, out * 0.245 + Vector3(0, 0.79, 0), Vector3(-12.0, a, 0.0))
	# team tab at the front, an amber leaf behind, two gold leaves on the thighs
	_leaf(s, cloth, Vector3(0, 0.91, 0.215), Vector3(0, -1.0, 0.25), Vector3(0, 0.25, 1.0), Vector3(0.19, 0.04, 0.34))
	_leaf(s, amber, Vector3(0, 0.90, -0.22), Vector3(0, -1.0, -0.32), Vector3(0, 0.25, -1.0), Vector3(0.22, 0.04, 0.34))
	for sx: float in [-1.0, 1.0]:
		_leaf(s, gold, Vector3(0.19 * sx, 0.89, 0.08), Vector3(0.45 * sx, -1.0, 0.1), Vector3(sx, 0.2, 0.2),
			Vector3(0.14, 0.035, 0.26))
	# a bark knife sheath on the left hip
	_put(s, box(Vector3(0.05, 0.24, 0.07)), dark, Vector3(-0.24, 0.78, 0.06), Vector3(0, 0, -12))
	_put(s, sphere(0.035, 6, 3), blade, Vector3(-0.215, 0.915, 0.06))


## A leg rooted at the hip (sx -1 left, +1 right): mossy leggings, a gold leaf knee guard, a bark greave on the shin
## authored bent back by seat_leg_forward_deg (it hangs straight in the saddle), a dark bark boot.
func _leg_sculpt(s: Dictionary, sx: float) -> void:
	var moss := m("nature_moss")
	var bark := m("nature_bark")
	var boot := m("nature_bark_dark")
	var gold := m("stagrunner_leaf_gold")
	var fwd := deg_to_rad(seat_leg_forward_deg)
	var hip := Vector3(0.11 * sx, 0.84, 0)
	var knee := Vector3(0.12 * sx, 0.47, 0.03)
	var shin := Vector3(0, -cos(fwd), -sin(fwd))
	var ankle := knee + shin * 0.30
	_seg(s, moss, hip, knee, 0.088, 0.07, 8)
	_put(s, sphere(0.072, 7, 3), moss, knee)
	_seg(s, moss, knee, ankle, 0.064, 0.058, 7)
	# bark greave (front half-shell) and wraps
	var front := Vector3(0, shin.z, -shin.y)
	_seg(s, bark, knee + shin * 0.04 + front * 0.03, ankle - shin * 0.02 + front * 0.025, 0.06, 0.052, 7)
	for f: float in [0.3, 0.65]:
		MountModel.sculpt_add(s, cyl(0.07, 0.07, 0.03, 7, false), Transform3D(_to_dir(shin), knee + shin * 0.30 * f), boot)
	_leaf(s, gold, knee + Vector3(0, 0.07, 0.05), Vector3(0, -0.5, 1.0), Vector3(0, 1.0, 0.3), Vector3(0.13, 0.035, 0.20))
	# boot: cuff + foot pointing forward, toe up by fwd (level once seated)
	var foot_dir := Vector3(0, sin(fwd), cos(fwd))
	var foot_c := ankle + foot_dir * 0.06 + Vector3(0, -0.035, 0)
	MountModel.sculpt_add(s, capsule(0.062, 0.25), Transform3D(_to_dir(foot_dir), foot_c), boot)
	_put(s, cyl(0.078, 0.07, 0.08, 7), boot, ankle + shin * -0.02, Vector3(rad_to_deg(-fwd), 0, 0))


func _chest_sculpt(s: Dictionary) -> void:
	var dark := m("nature_bark_dark")
	var bark := m("nature_bark")
	var cloth := m("nature_cloth")
	var cloth_d := m("nature_cloth_dark")
	var gold := m("stagrunner_leaf_gold")
	var amber := m("stagrunner_leaf_amber")
	# torso (lathe, flattened front-back): a lean rider's dark jerkin
	var prof := PackedVector2Array([Vector2(0.17, 0.90), Vector2(0.195, 1.0), Vector2(0.23, 1.15), Vector2(0.238, 1.25),
		Vector2(0.21, 1.35), Vector2(0.12, 1.43), Vector2(0.0, 1.45)])
	var torso := MountModel.lathe_mesh("sgr_torso_v1", prof, 12)
	MountModel.sculpt_add(s, torso, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.8)), Vector3.ZERO), dark)
	# three pale bark lamellar bands
	for b: Array in [[1.03, 0.212], [1.13, 0.236], [1.23, 0.245]]:
		MountModel.sculpt_add(s, cyl(float(b[1]) + 0.012, float(b[1]) + 0.016, 0.07, 12, false),
			Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.82)), Vector3(0, float(b[0]), 0)), bark)
	# team sash (right shoulder to left hip), front and back
	for zs: float in [1.0, -1.0]:
		_put(s, box(Vector3(0.09, 0.56, 0.035)), cloth, Vector3(0.0, 1.15, 0.186 * zs), Vector3(0, 0, -32.0 * zs))
	# team cowl round the neck, dark rim
	_put(s, cyl(0.13, 0.215, 0.13, 12, false), cloth, Vector3(0, 1.42, -0.005))
	_put(s, cyl(0.218, 0.222, 0.03, 12, false), cloth_d, Vector3(0, 1.355, -0.005))
	# left pauldron: a bark plate under a fan of gold / amber leaves (the asymmetric read)
	_put(s, sphere(0.12, 8, 4), bark, Vector3(-0.27, 1.41, 0.0), Vector3(0, 0, 20), Vector3(1.0, 0.55, 1.0))
	for i: int in 4:
		var u: float = float(i) / 3.0 * 2.0 - 1.0
		_leaf(s, gold if i % 2 == 0 else amber, Vector3(-0.25, 1.45, u * 0.09),
			Vector3(-1.0, -0.55, u * 0.55), Vector3(-0.4, 1.0, 0), Vector3(0.15, 0.035, 0.30))
	# right shoulder: a small bark cap
	_put(s, sphere(0.10, 8, 4), bark, Vector3(0.27, 1.41, 0.0), Vector3(0, 0, -20), Vector3(1.0, 0.5, 1.0))
	# the cloak clasp bar across the upper back
	_put(s, box(Vector3(0.36, 0.06, 0.05)), dark, Vector3(0, 1.40, -0.17))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("nature_skin")
	var cloth := m("nature_cloth")
	var dark := m("nature_bark_dark")
	var bark := m("nature_bark")
	var gold := m("stagrunner_leaf_gold")
	var amber := m("stagrunner_leaf_amber")
	var glow := m("nature_glow")
	_put(s, cyl(0.065, 0.075, 0.14, 8), skin, Vector3(0, 1.50, 0.02))
	# face (FaceKit rig, _build_parts), the team cowl pulled down to the neck so the mouth shows
	_put(s, sphere(0.145, 10, 6), skin, Vector3(0, 1.62, 0.05), Vector3.ZERO, Vector3(0.95, 1.08, 0.95))
	_put(s, sphere(0.155, 10, 5), cloth, Vector3(0, 1.49, 0.035), Vector3.ZERO, Vector3(0.95, 0.45, 0.98))
	# bark half-helm: dome above the brow, a dark brow band, cheek guards, a nasal, a ridge
	var dome := MountModel.lathe_mesh("sgr_helm_v1", PackedVector2Array([Vector2(0.182, 0.0), Vector2(0.178, 0.05),
		Vector2(0.15, 0.12), Vector2(0.09, 0.172), Vector2(0.0, 0.19)]), 12)
	MountModel.sculpt_add(s, dome, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.12)), Vector3(0, 1.685, 0.0)), bark)
	MountModel.sculpt_add(s, cyl(0.19, 0.19, 0.05, 12, false),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.12)), Vector3(0, 1.70, 0.0)), dark)
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.035, 0.13, 0.12)), bark, Vector3(0.155 * sx, 1.62, 0.06), Vector3(8, 0, 10.0 * sx))
	_put(s, box(Vector3(0.035, 0.09, 0.03)), dark, Vector3(0, 1.655, 0.205))
	_put(s, box(Vector3(0.045, 0.05, 0.34)), dark, Vector3(0, 1.865, -0.01), Vector3(-8, 0, 0))
	# the gold leaf crest swept back (the read), two amber side plumes, a small leaf forward
	_leaf(s, gold, Vector3(0, 1.86, 0.08), Vector3(0, 0.62, -1.0), Vector3(0, 1.0, 0.3), Vector3(0.13, 0.035, 0.50))
	_leaf(s, gold, Vector3(0, 1.88, 0.14), Vector3(0, 1.0, 0.35), Vector3(0, 0.3, -1.0), Vector3(0.09, 0.03, 0.20))
	for sx: float in [-1.0, 1.0]:
		_leaf(s, amber, Vector3(0.05 * sx, 1.85, 0.02), Vector3(0.32 * sx, 0.5, -1.0), Vector3(sx * 0.3, 1.0, 0.2),
			Vector3(0.11, 0.03, 0.40))
	# glowing seed on the brow in a dark leaf setting
	_leaf(s, dark, Vector3(0, 1.70, 0.20), Vector3(0, 1.0, 0.2), Vector3(0, 0, 1), Vector3(0.09, 0.02, 0.12))
	_put(s, sphere(0.038, 7, 4), glow, Vector3(0, 1.745, 0.205))


func _arm_l_sculpt(s: Dictionary) -> void:
	var moss := m("nature_bark")
	var bark := m("nature_bark")
	var band := m("nature_bark_dark")
	var skin := m("nature_skin")
	var elbow := SH_L + Vector3(0, -0.28, 0)
	_put(s, sphere(0.085, 8, 4), moss, SH_L + Vector3(0, -0.02, 0))
	_seg(s, moss, SH_L, elbow, 0.07, 0.062, 8)
	_put(s, sphere(0.062, 7, 3), moss, elbow)
	_seg(s, band, elbow, GRIP_L + Vector3(0, 0.05, 0), 0.064, 0.056, 8)
	_put(s, cyl(0.068, 0.068, 0.03, 8, false), band, elbow + Vector3(0, -0.06, 0))
	_put(s, cyl(0.06, 0.06, 0.03, 8, false), band, GRIP_L + Vector3(0, 0.09, 0))
	_put(s, sphere(0.066, 8, 4), skin, GRIP_L, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


func _arm_r_sculpt(s: Dictionary) -> void:
	var moss := m("nature_bark")
	_put(s, sphere(0.085, 8, 4), moss, SH_R + Vector3(0, -0.02, 0))
	_seg(s, moss, SH_R, ELBOW_R, 0.07, 0.062, 8)
	_put(s, sphere(0.062, 7, 3), moss, ELBOW_R)


## The right forearm (keep_separate "ForearmR", node-local at the elbow): bark bracer with a thorn spur, the fist.
func _fore_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var band := m("nature_bark_dark")
	var thorn := m("nature_thorn")
	var skin := m("nature_skin")
	var hand := HAND_R - ELBOW_R
	_seg(s, bark, Vector3.ZERO, hand + Vector3(0, 0.05, 0), 0.062, 0.056, 8)
	_put(s, cyl(0.066, 0.066, 0.03, 8, false), band, Vector3(0, -0.07, 0))
	_put(s, cyl(0.06, 0.06, 0.03, 8, false), band, hand + Vector3(0, 0.09, 0))
	_seg(s, thorn, Vector3(0.05, -0.12, 0), Vector3(0.12, -0.08, -0.02), 0.022, 0.0, 5)
	_put(s, sphere(0.066, 8, 4), skin, hand, Vector3.ZERO, Vector3(1.05, 1.05, 1.1))


## The bark shortspear (keep_separate "Spear", spear frame: the grip at the origin, the blade along +Y; +Z is "below"
## the shaft when it is levelled forward).
func _spear_sculpt(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var thorn := m("nature_thorn")
	var blade := m("stagrunner_blade")
	var glow := m("nature_glow")
	var gold := m("stagrunner_leaf_gold")
	var amber := m("stagrunner_leaf_amber")
	var cloth := m("nature_cloth")
	# shaft, thorn butt, dark bands, the grip wrap
	_seg(s, thorn, Vector3(0, BUTT + 0.12, 0), Vector3(0, SOCKET, 0), 0.046, 0.042, 7)
	_seg(s, bark, Vector3(0, BUTT + 0.13, 0), Vector3(0, BUTT, 0), 0.05, 0.0, 6)
	_put(s, cyl(0.05, 0.05, 0.04, 7, false), dark, Vector3(0, BUTT + 0.14, 0))
	for y: float in [-0.36, 0.42, 0.78]:
		_put(s, cyl(0.052, 0.052, 0.04, 7, false), dark, Vector3(0, y, 0))
	_put(s, cyl(0.054, 0.054, 0.22, 7), dark, Vector3(0, 0.0, 0))
	# socket cone, the glowing seed, the heartwood leaf blade with its sap vein
	_seg(s, dark, Vector3(0, SOCKET - 0.06, 0), Vector3(0, SOCKET + 0.08, 0), 0.052, 0.034, 7)
	_put(s, sphere(0.052, 7, 4), glow, Vector3(0, SOCKET - 0.01, 0))
	_leaf(s, blade, Vector3(0, SOCKET + 0.02, 0), Vector3.UP, Vector3(0, 0, 1), Vector3(0.22, 0.07, TIP - SOCKET - 0.02))
	_put(s, sphere(0.03, 6, 4), glow, Vector3(0, SOCKET + 0.22, 0), Vector3.ZERO, Vector3(0.9, 5.0, 1.6))
	# a tuft of gold / amber leaves under the blade
	for i: int in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		var o := Vector3(cos(a), 0, sin(a))
		_leaf(s, gold if i % 2 == 0 else amber, Vector3(0, SOCKET - 0.07, 0) + o * 0.03, o * 0.4 + Vector3.DOWN, o,
			Vector3(0.08, 0.02, 0.26))
	# the team pennon: hoisted along the shaft under the tuft, its tip trailing down the shaft and away (+Z)
	var left := PackedVector3Array([Vector3(0, 0.90, 0.03), Vector3(0.02, 0.80, 0.19), Vector3(-0.01, 0.66, 0.33),
		Vector3(0, 0.50, 0.44)])
	var right := PackedVector3Array([Vector3(0, 0.64, 0.03), Vector3(0.02, 0.60, 0.16), Vector3(-0.01, 0.54, 0.30),
		Vector3(0, 0.50, 0.44)])
	MountModel.sculpt_add(s, _strip_mesh("sgr_pennon_v1", left, right, 0.018), Transform3D.IDENTITY, cloth)


## Upper cloak segment (keep_separate "Cloak", node-local at CLOAK_O, hanging along -Y, its outer face toward -Z):
## a TEAM backing with shingled gold / amber leaves (in-game grade pass 2026-09-30: the backing was amber and the
## unit showed ~13 % team colour; the cloak lies over the stag's rump, the most top-facing cloth of the unit).
func _cloak_sculpt(s: Dictionary) -> void:
	var gold := m("stagrunner_leaf_gold")
	var amber := m("stagrunner_leaf_amber")
	var team := m("nature_cloth")
	var dark := m("nature_bark_dark")
	var l := CLOAK_LEN + 0.03
	var left := PackedVector3Array([Vector3(-0.24, 0.02, 0.0), Vector3(-0.29, -l * 0.5, -0.03), Vector3(-0.27, -l, -0.02)])
	var right := PackedVector3Array([Vector3(0.24, 0.02, 0.0), Vector3(0.29, -l * 0.5, -0.03), Vector3(0.27, -l, -0.02)])
	MountModel.sculpt_add(s, _strip_mesh("sgr_cloak_back_v2", left, right, 0.025), Transform3D.IDENTITY, team)
	for sx: float in [-1.0, 1.0]:
		_put(s, sphere(0.05, 7, 3), dark, Vector3(0.15 * sx, 0.0, 0.0))
	var back := Vector3(0, 0.12, -1.0).normalized()
	for r: int in 4:
		var n: int = 3 if r % 2 == 0 else 2
		var y: float = -0.02 - 0.145 * float(r)
		for i: int in n:
			var u: float = 0.0 if n == 1 else (float(i) / float(n - 1)) * 2.0 - 1.0
			var x: float = u * (0.16 if n == 3 else 0.085)
			var base := Vector3(x, y, -0.03 - 0.012 * float(r % 2))
			var mat: Material = gold if (i + r) % 2 == 0 else amber
			_leaf(s, mat, base, Vector3(u * 0.14, -1.0, -0.10), back, Vector3(0.20, 0.035, 0.26))


## Lower cloak segment (keep_separate "CloakTail", child of Cloak, node-local at TAIL_O): a narrowing backing, a row of
## leaves and three long pointed leaf tips (swallowtail).
func _tail_sculpt(s: Dictionary) -> void:
	var gold := m("stagrunner_leaf_gold")
	var amber := m("stagrunner_leaf_amber")
	var team := m("nature_cloth")
	var left := PackedVector3Array([Vector3(-0.27, 0.03, 0.0), Vector3(-0.24, -0.20, -0.02), Vector3(-0.17, -0.36, -0.01)])
	var right := PackedVector3Array([Vector3(0.27, 0.03, 0.0), Vector3(0.24, -0.20, -0.02), Vector3(0.17, -0.36, -0.01)])
	MountModel.sculpt_add(s, _strip_mesh("sgr_tail_back_v2", left, right, 0.025), Transform3D.IDENTITY, team)
	var back := Vector3(0, 0.12, -1.0).normalized()
	for i: int in 3:
		var u: float = float(i) - 1.0
		_leaf(s, gold if i != 1 else amber, Vector3(u * 0.15, -0.01, -0.03), Vector3(u * 0.12, -1.0, -0.08), back,
			Vector3(0.16, 0.035, 0.24))
	for i: int in 2:
		var u: float = float(i) * 2.0 - 1.0
		_leaf(s, amber, Vector3(u * 0.065, -0.15, -0.04), Vector3(u * 0.08, -1.0, -0.08), back, Vector3(0.15, 0.035, 0.24))
	# the swallowtail: three long pointed leaves (the middle one longest)
	for i: int in 3:
		var u: float = float(i) - 1.0
		var ln: float = 0.36 if i == 1 else 0.30
		_leaf(s, gold, Vector3(u * 0.10, -0.28, -0.03), Vector3(u * 0.35, -1.0, -0.05), back, Vector3(0.14, 0.03, ln))


# ================================================================ motion

## `lance_charge`: timing only here (the strike event at STRIKE, a small lunge); the spear, arm and body are posed in
## _pose_seated (in the saddle) or _extra_process (on foot).
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"lance_charge":
		return super._pose_attack(prev, t)
	_atk_t = t
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
	pos(P_ROOT, Vector3(0, 0, _k3(t, 0.0, 0.06, STRIKE, ATK_LEN, -0.05, 0.16)))
	return t < ATK_LEN


## Any cast: the spear raised high (a salute), 0.7 s.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.18, 0.45, 0.7, 1.0, 1.0)
	return 0.7


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"release":
			_flare = maxf(_flare, 0.55)
			call_deferred(&"_emit_strike", false)
		&"attack_end":
			_atk_t = 99.0


func _emit_strike(charge: bool) -> void:
	if _dead or _spear == null or not _spear.is_inside_tree():
		return
	spear_struck.emit(get_spear_tip(), get_spear_dir(), charge)


## Timers, the aim, the flare glow; on foot the spear is posed here (in the saddle: _pose_seated).
func _extra_process(dt: float) -> void:
	_face_tick()
	if _chg_t < CH_LEN:
		var prev := _chg_t
		_chg_t += dt
		if prev < CH_STRIKE and _chg_t >= CH_STRIKE and not _dead:
			call_deferred(&"_emit_strike", true)
	if _action != &"attack":
		_atk_t = 99.0
	_flare = move_toward(_flare, 0.0, dt / 0.8)
	_update_phi()
	if _spear:
		var gl: float = snappedf(glow_level() * (1.0 + 1.6 * _flare), 0.05)
		if gl != _glow_w:
			_glow_w = gl
			_spear.set_instance_shader_parameter(&"glow_boost", gl)
	if not _rd_on:
		_solve(1.0, 0.0, 0.0, 0.0, false, _off_rot[P_ARM_L])
		_pose_cloak(0.0, 0.0, 0.0, 0.0)


func _update_phi() -> void:
	var p: Vector3
	if _aim_mode == 2:
		if not is_instance_valid(_aim_node) or not _aim_node.is_inside_tree():
			_aim_mode = 1 if _phi_valid else 0
			_aim_node = null
			return
		p = _aim_node.global_position + Vector3.UP * 0.9
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
	_elev = clampf(rad_to_deg(atan2(l.y - GRIP_H, hd)), -28.0, 8.0)
	_phi_valid = true


## Riding: the kit's seat pose (lean, bob, head, reins), then the spear, the arms, the crouch and the cloak.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	super._pose_seated(w, gait, gallop, moving)
	_solve(w, gait, gallop * moving, moving, true, sal)
	_pose_cloak(w, gait, gallop * moving, moving)


## The spear (carry / couch / thrust / charge / cast), the chest crouch and twist, the two-bone spear arm, the reins
## arm and the head. `g` = gallop x moving; `seated` false = on foot (w 1).
func _solve(w: float, gait: float, g: float, moving: float, seated: bool, sal: Vector3) -> void:
	var ck: float = _cast_k
	_cast_k = 0.0
	var at: float = _atk_t if _action == &"attack" and not _dead else 99.0
	var aw: float = _k3(at, 0.0, 0.05, 0.30, ATK_LEN, 1.0, 1.0) if at < 90.0 else 0.0
	var th: float = _k3(at, 0.0, 0.06, STRIKE, ATK_LEN, -0.3, 1.0) if at < 90.0 else 0.0
	var ct: float = _chg_t if not _dead else 99.0
	var cw: float = _k3(ct, 0.0, 0.05, 0.45, CH_LEN, 1.0, 1.0) if ct < CH_LEN else 0.0
	var cth: float = _k3(ct, 0.0, 0.05, CH_STRIKE, CH_LEN, -0.25, 1.2) if ct < CH_LEN else 0.0
	# ---- the wanted spear direction (model frame) and grip (chest frame)
	var el: float
	var yaw: float
	var grip: Vector3
	if seated:
		el = lerpf(CARRY_EL, COUCH_EL, g)
		yaw = lerpf(CARRY_YAW, COUCH_YAW, g)
		grip = CARRY_GRIP.lerp(COUCH_GRIP, g)
	else:
		el = FOOT_EL
		yaw = 4.0
		grip = FOOT_GRIP
	var ay: float = clampf(_phi, YAW_MIN, YAW_MAX) if _phi_valid else 0.0
	var ae: float = _elev if _phi_valid else -8.0
	var hw: float = maxf(aw, cw)
	el = lerpf(el, ae, aw)
	yaw = lerpf(yaw, ay, aw)
	el = lerpf(el, -4.0, cw)
	yaw = lerpf(yaw, clampf(ay, -12.0, 28.0), cw)
	grip = grip.lerp(COUCH_GRIP, hw)
	if ck > 0.0:
		el = lerpf(el, CAST_EL, ck)
		yaw = lerpf(yaw, 0.0, ck)
		grip = grip.lerp(CAST_GRIP, ck)
	var er := deg_to_rad(el)
	var yr := deg_to_rad(yaw)
	var a_m := Vector3(sin(yr) * cos(er), sin(er), cos(yr) * cos(er))
	# ---- chest: a light rider's forward crouch, the lean into the thrust, the twist toward the target and the right
	# shoulder driving forward at the strike
	var bc := Basis.from_euler(_rest_rot[P_CHEST] + _off_rot[P_CHEST])
	var lean: float = (5.0 + 5.0 * g) * (1.0 if seated else 0.0) + 8.0 * aw + 6.0 * maxf(th, 0.0) + 16.0 * cw \
		+ 6.0 * maxf(cth, 0.0)
	var twist: float = clampf(ay * 0.35, -12.0, 25.0) * hw - 20.0 * maxf(th, 0.0) - 14.0 * maxf(cth, 0.0)
	if lean != 0.0 or twist != 0.0:
		bc = bc * Basis(Vector3.RIGHT, lean * DEG * w) * Basis(Vector3.UP, twist * DEG * w)
		_off_rot[P_CHEST] = bc.get_euler() - _rest_rot[P_CHEST]
	var rb := Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT])
	var inv := (rb * bc).inverse()
	var ac := (inv * a_m).normalized()
	# ---- the hand: the grip + the thrust along the shaft; the grip slides back on the shaft for side targets
	var push: float = THRUST * th + 0.44 * cth
	var hand_t := grip + ac * push
	var bob := Vector3(0, lerpf(0.012 * sin(2.0 * TAU * gait), 0.03 * sin(TAU * (gait - 0.4)), g) * moving, 0)
	hand_t += bob * (1.0 - hw)
	var shr: Vector3 = _rest_pos[P_ARM_R]
	var pole := POLE_CARRY.lerp(POLE_THRUST, hw)
	_ik(shr, hand_t, UPPER_R, FORE_R, pole)
	_off_rot[P_ARM_R] = _ik_u.get_euler() * w
	var hand := shr + (hand_t - shr).limit_length(UPPER_R + FORE_R - 0.004)
	if _fore:
		var fq := (_ik_u.inverse() * _ik_f).get_rotation_quaternion()
		if w < 1.0:
			fq = Quaternion.IDENTITY.slerp(fq, w)
		if not fq.is_equal_approx(_fore_q_w):
			_fore_q_w = fq
			_fore.quaternion = fq
	var slide: float = maxf(clampf((absf(yaw) - 15.0) / 50.0, 0.0, 1.0) * 0.42, COUCH_SLIDE * maxf(g, hw) * (1.0 - ck))
	if _spear:
		_spear.transform = Transform3D(_basis_y(ac, Vector3.RIGHT), hand + ac * slide)
	# ---- the reins hand (seated; the kit's reins fade while an action poses the arms)
	if seated:
		var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 6.0 * sin(TAU * (gait - 0.4)), g) * moving
		var reins := Vector3((-36.0 - 14.0 * cw + bounce) * DEG, 0, 10.0 * DEG)
		_off_rot[P_ARM_L] = sal + reins * w
	# ---- head: toward the target while thrusting
	if hw > 0.0:
		_off_rot[P_HEAD] += Vector3(-4.0 * DEG * hw, clampf(ay - twist, -60.0, 60.0) * 0.6 * DEG * hw * w, 0)


## The leaf cloak: drapes over the rump in the saddle, streams back like a banner at the gallop (the tail flutters),
## flares at the charge; hangs down on foot.
func _pose_cloak(w: float, gait: float, g: float, moving: float) -> void:
	if _cloak == null:
		return
	var cw: float = _k3(_chg_t, 0.0, 0.05, 0.45, CH_LEN, 1.0, 1.0) if _chg_t < CH_LEN and not _dead else 0.0
	var walk: float = moving * (1.0 - g)
	var c: float = lerpf(4.0, 26.0, w) + g * (44.0 + 5.0 * sin(TAU * gait * 2.0 + 0.6)) \
		+ walk * (5.0 + 3.0 * sin(TAU * gait * 2.0)) + 10.0 * cw
	var t: float = lerpf(3.0, 42.0, w) - 22.0 * g + g * 7.0 * sin(TAU * gait * 2.0 + 1.8) \
		+ walk * 4.0 * sin(TAU * gait * 2.0 + 1.0) + 8.0 * cw
	if _dead:
		c = lerpf(4.0, 26.0, w)
		t = lerpf(3.0, 42.0, w)
	c = snappedf(c, 0.25)
	t = snappedf(t, 0.25)
	if c != _cloak_w:
		_cloak_w = c
		_cloak.rotation = Vector3(c * DEG, 0, 0)
	if _tail and t != _tail_w:
		_tail_w = t
		_tail.rotation = Vector3(t * DEG, 0, 0)


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
	_face_reset()
	_atk_t = 99.0
	_chg_t = 99.0
	_flare = 0.0
	_cast_k = 0.0
	_fore_q_w = Quaternion(0, 0, 0, 0)
	_cloak_w = 999.0
	_tail_w = 999.0
	_glow_w = -1.0
	if _fore:
		_fore.quaternion = Quaternion.IDENTITY
