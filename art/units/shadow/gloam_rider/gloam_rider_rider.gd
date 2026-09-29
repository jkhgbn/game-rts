class_name GloamRiderRider
extends ShadowModel
## Gloam Rider rider (cavalry-mounts.md 4 / 10 row 13.V7): the Shadow draining lancer on the 13.V3 Dusk Steed. Seated
## with the kit's CharacterModel.set_seated (13.V1b); the scene that pairs it with the steed is gloam_rider.tscn
## (GloamRiderModel, the unit's model_scene). Extends ShadowModel for the Shadow dissolve death (it melts into violet
## while it rides the steed's fall).
## Look: a lean, tall-looking lancer in an ashen quilted gambeson (gloam_rider_coat: the value contrast against the
## black and violet steed) under a dark leather cuirass with tarnished-silver rims and a silver diamond on the sternum;
## a deep team-violet reaper COWL (a forward point over the brow, a drooping back point), a ragged cowl hem, smoke
## tongues trailing off the hood; inside it a dark void with two slanted glowing eyes over a silver half-mask. The lance side is armoured
## (ASYMMETRIC read: a big layered silver pauldron with three swept spikes, silver rerebrace and vambrace, iron
## gauntlet); the rein side is light (small leather cap, one spike). A tattered two-layer cloak (team violet over dark
## rags) drapes over the croup and streams back at the gallop.
## The LANCE (3.7 m, blackened shaft with a violet rim, silver rings, an iron vamplate with a silver spiked rim): a long
## tarnished-silver leaf head with a glowing violet fuller, two big harpoon barbs at its base and two pairs of small
## barbs up its edges; a swallow-tailed team-violet PENNON with a silver diamond trails from under the head (4 cached
## wave shapes swapped as it flutters; hangs off the shaft at rest, streams back at the gallop).
## Glow points (40 m): the hood eyes (merged) and the lance fuller (own glow: flares on the charge / strike).
## Lance carriage: at rest carried high and tilted out (CARRY deg), lowered forward at the gallop (GALLOP deg), couched
## dead level under the arm for the strike and the charge. The lance keeps its angle in the unit's frame while the
## rider leans (a two-bone right arm with its own forearm node holds it).
## Attack `lance_charge` (0.55 s, the melee hit at STRIKE 0.12 s): couch, a short draw back with the right shoulder
## back, the thrust (lean in, right shoulder forward, arm driving along the shaft), hold, recover; the steed's
## mount_toss lunges with it (the root forwards both). play_charge() (0.85 s, strike CHG_HIT 0.10 s = the steed's
## charge_hit): couched from the first frame, a bigger lean and thrust, the fuller flares.
## Hooks (on top of the kit's): play_charge(), is_charging(), get_lance_tip() -> Vector3 (world), lance_pitch() -> float
## (deg in the unit frame, negative = tip up), couch_amount() -> float, authored_mesh_count() -> int; signals
## charge_struck(at: Vector3) (the charge strike, lance tip, world) and lance_struck(at: Vector3) (the attack strike).
## Budget (section 10 cavalry): 11 authored meshes, 11 draw instances (7 merged pivots + ForearmR, Lance, Pennon,
## Cloak), no blob (the steed's shows), 0 lights, 0 particles.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

const OWN := "res://art/units/shadow/gloam_rider/materials/"
const DUSK := "res://art/units/mounts/dusk_steed/materials/"

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP := Vector3(0, 0.86, 0)
const CHEST_O := Vector3(0, 0.94, 0)
const SH_L := Vector3(-0.27, 1.37, 0.0)
const SH_R := Vector3(0.27, 1.37, 0.0)
const GRIP_L := Vector3(-0.27, 0.81, 0.0)
const ELBOW_R := Vector3(0.27, 1.09, 0.0)
const HAND_R := Vector3(0.27, 0.81, 0.0)
const UPPER_R := 0.28
const FORE_R := 0.28
const CLOAK_O := Vector3(0, 1.36, -0.15)
## Lance frame: grip at the origin, +Z toward the tip.
const LANCE_TIP := 2.95
const LANCE_BUTT := -0.86
const PENNON_Z := 2.26
const PENNON_LEN := 0.92
const PENNON_STEPS := 4
## Lance pitch / yaw (deg, unit frame; pitch negative = tip up, yaw positive = tip toward +X).
const CARRY := -50.0
const CARRY_YAW := 12.0
const GALLOP := -16.0
const GALLOP_YAW := -3.0
const COUCH := 9.0
const COUCH_YAW := -6.0
const DROP := 38.0
## Right-hand targets (chest frame, from the chest pivot): at rest by the right hip, forward at the gallop, couched
## under the arm; elbow pole directions.
const REST_HAND_C := Vector3(0.24, 0.08, 0.17)
const GALLOP_HAND_C := Vector3(0.22, 0.16, 0.24)
const COUCH_HAND_C := Vector3(0.20, 0.21, 0.28)
const REST_POLE := Vector3(0.7, -0.3, -1.0)
const COUCH_POLE := Vector3(0.45, -0.35, -1.0)
## Timelines (s).
const ATK_LEN := 0.55
const STRIKE := 0.12
const CHG_LEN := 0.85
const CHG_HIT := 0.10

# Keyframe tracks [t, value, ease, ...] (ease: 0 smooth, 1 ease-out, 2 ease-in). Attack (lance_charge):
static var AT_W := PackedFloat32Array([0.0, 0.0, 0, 0.06, 1.0, 1, 0.34, 1.0, 0, 0.55, 0.0, 0])
static var AT_PUSH := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.12, 1, 0.12, 0.24, 2, 0.26, 0.16, 0, 0.55, 0.0, 0])
static var AT_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -4.0, 1, 0.13, 14.0, 2, 0.30, 6.0, 0, 0.55, 0.0, 0])
static var AT_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, 12.0, 1, 0.13, -14.0, 2, 0.30, -6.0, 0, 0.55, 0.0, 0])
# Charge (play_charge):
static var CR_W := PackedFloat32Array([0.0, 0.0, 0, 0.05, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])
static var CR_PUSH := PackedFloat32Array([0.0, 0.0, 0, 0.05, -0.10, 1, 0.10, 0.28, 2, 0.36, 0.20, 0, 0.85, 0.0, 0])
static var CR_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.06, 14.0, 1, 0.14, 22.0, 0, 0.45, 8.0, 0, 0.85, 0.0, 0])
static var CR_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.05, 10.0, 1, 0.11, -16.0, 2, 0.40, -6.0, 0, 0.85, 0.0, 0])

static var _pen_cache: Array[Mesh] = []

var _parts_n: int = 0
var _fore: MeshInstance3D
var _lance: MeshInstance3D
var _pennon: MeshInstance3D
var _cloak: MeshInstance3D

var _atk_t: float = 99.0
var _chg_t: float = 99.0
var _flare: float = 0.0
var _gal: float = 0.0          # gallop amount of the last seated frame (gallop blend x moving)
var _couch: float = 0.0
var _pitch_now: float = CARRY
var _lance_mb: Basis = Basis.IDENTITY   # the lance's basis in the model frame (last solve)
var _pen_ph: float = 0.0
var _pen_th: float = 0.0
var _dt: float = 0.0
# written-value caches (write on change only)
var _lance_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _fore_q_w: Quaternion = Quaternion(0, 0, 0, 0)
var _pen_rot_w: float = 999.0
var _pen_k_w: int = -1
var _glow_w: float = -1.0
var _cloak_w: float = 99.0
# IK scratch
var _ik_u: Basis = Basis.IDENTITY
var _ik_f: Basis = Basis.IDENTITY


# ================================================================ public hooks

## The charge strike (Unit.charged): couched lance, lean, thrust at CHG_HIT (with the steed's play_charge).
func play_charge() -> void:
	if _dead:
		return
	_chg_t = 0.0
	_flare = 1.0
	set_process(true)


func is_charging() -> bool:
	return _chg_t < CHG_LEN


## World position of the lance tip (charge / strike impact VFX).
func get_lance_tip() -> Vector3:
	if _lance and _lance.is_inside_tree():
		return _lance.global_transform * Vector3(0, 0, LANCE_TIP)
	return global_position + Vector3(0.2, 2.0, LANCE_TIP)


## Lance pitch (deg) in the unit's frame: negative = tip up (carried), ~+9 = couched.
func lance_pitch() -> float:
	return _pitch_now


## 0 = carried, 1 = couched for a strike / charge.
func couch_amount() -> float:
	return _couch


## Authored meshes of the rider (the cavalry budget of section 10).
func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var arm_r: Node3D = $Root/Chest/ArmR
	_sculpt($Root/Hips, "grr_hips_v1", _hips_sculpt)
	for leg: Node3D in [$Root/Hips/LegL, $Root/Hips/LegR]:
		var sx: float = -1.0 if leg.name == "LegL" else 1.0
		_sculpt(leg, "grr_leg_%s_v1" % sx, func(s: Dictionary) -> void: _leg_sculpt(s, sx))
	_sculpt($Root/Chest, "grr_chest_v1", _chest_sculpt)
	_sculpt($Root/Chest/Head, "grr_head_v2", _head_sculpt)
	# Face (FaceKit, face rework 2026-09-28; was a dark void with two glow slits): gaunt lilac-pale face, slanted glowing
	# violet eyes under hard brows, a grim mouth; black-violet strands out of the hood.
	var hc := Vector3(0, 1.64, 0.06)
	_face = FaceKit.attach(self, $Root/Chest/Head, "gloam_rider_rider", {
		"center": hc, "radius": 0.14, "head_mesh": sphere(0.14, 10, 6), "head_scale": Vector3(0.95, 1.08, 0.95), "head_at": hc,
		"preset": &"hollow", "skin": ShadowFaces.SKIN, "hair": ShadowFaces.INK, "eyes": ShadowFaces.GLOW, "detail": &"low",
		"x": NatureFaces.lean_x(1.15, {&"neutral": {"cut_in": 0.35, "mouth": {"kind": "frown", "curve": 0.5, "open": 0.0}}}),
		"palette": ShadowFaces.pal(ShadowFaces.SKIN), "eye": {"c": Vector2(0.050, 0.024), "tilt": 0.016},
		"hair_fn": func(acc: Dictionary) -> void:
			ShadowFaces.strands(acc, [hc + Vector3(0.10, 0.07, 0.05), hc + Vector3(-0.10, 0.07, 0.05)], 0.17, 0.028,
				ShadowFaces.INK, ShadowFaces.INK_TIP, Vector3(0.02, 0, 0.0)),
	})
	_sculpt($Root/Chest/ArmL, "grr_arm_l_v1", _arm_l_sculpt)
	_sculpt(arm_r, "grr_arm_r_v1", _arm_r_sculpt)
	# Own (keep_separate) parts: forearm (elbow), the lance (hand) with its pennon, the cloak (upper back).
	_fore = _sculpt(arm_r, "grr_fore_v1", _fore_sculpt, ELBOW_R, true, "ForearmR")
	_lance = _sculpt(_fore, "grr_lance_v1", _lance_sculpt, HAND_R, true, "Lance")
	_lance.set_meta(&"own_glow", true)
	_lance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if _pen_cache.is_empty():
		for k: int in PENNON_STEPS:
			var kk := k
			_pen_cache.append(_cached_sculpt("grr_pennon_%d_v1" % k, func(s: Dictionary) -> void: _pennon_sculpt(s, kk)))
	_parts_n += 1
	_pennon = add_part(_lance, _pen_cache[0], null, HAND_R + Vector3(0, 0, PENNON_Z), Vector3.ZERO, Vector3.ONE, true,
		"Pennon")
	_cloak = _sculpt($Root/Chest, "grr_cloak_v1", _cloak_sculpt, CLOAK_O, true, "Cloak")


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
	if name.begins_with("gloam_rider"):
		return MountModel.material_at(OWN + name + ".tres")
	if name.begins_with("dusk"):
		return MountModel.material_at(DUSK + name + ".tres")
	return palette(StringName(name))


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


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


## A spike / smoke tongue: cone whose base (radius r) is at `base`, pointing along `dir`, length h, flattened to `flat`
## across `side`.
static func _spike(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, r: float, h: float,
		side: Vector3 = Vector3.RIGHT, flat: float = 1.0) -> void:
	var f := MountModel.frame(base, dir, side)
	MountModel.sculpt_add(s, cyl(0.0, 1.0, 1.0, 6), Transform3D(Basis(f.basis.x * r * flat, f.basis.y * h, f.basis.z * r),
		base + f.basis.y * h * 0.5), mat)


# ---------------------------------------------------------------- body

func _hips_sculpt(s: Dictionary) -> void:
	var coat := m("gloam_rider_coat")
	var lea := m("shadow_leather")
	var sil := m("shadow_silver")
	var iron := m("shadow_iron")
	var cloth := m("shadow_cloth")
	# quilted gambeson skirt (split for riding), belt, a silver diamond buckle
	_put(s, cyl(0.19, 0.235, 0.26, 10), coat, Vector3(0, 0.82, 0))
	_put(s, cyl(0.205, 0.205, 0.07, 10, false), lea, Vector3(0, 0.945, 0))
	_put(s, box(Vector3(0.075, 0.075, 0.03)), sil, Vector3(0, 0.945, 0.205), Vector3(0, 0, 45))
	# ragged team tabard panels front and back
	MountModel.sculpt_fringe(s, cloth, MountModel.fringe_mesh("grr_tabard_f_v1", 0.215, 0.2, 0.235, 0.225, 0.26, -34.0,
		34.0, 3, 0.12, 0.02, 0.6), Vector3(0, 0.93, 0))
	MountModel.sculpt_fringe(s, cloth, MountModel.fringe_mesh("grr_tabard_b_v1", 0.215, 0.2, 0.235, 0.225, 0.26, 146.0,
		214.0, 3, 0.12, 0.02, 0.6), Vector3(0, 0.93, 0))
	# iron tassets with silver rivets over the thighs
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.03, 0.18, 0.15)), iron, Vector3(0.215 * sx, 0.84, 0.03), Vector3(0, 0, -12.0 * sx))
		_put(s, sphere(0.018, 5, 3), sil, Vector3(0.232 * sx, 0.9, 0.03))


## A leg rooted at the hip (sx -1 left, +1 right): leather trousers, a silver knee cop with a spike, the shin authored
## bent back by seat_leg_forward_deg so it hangs straight down in the saddle, a silver greave, a dark boot.
func _leg_sculpt(s: Dictionary, sx: float) -> void:
	var lea := m("shadow_leather")
	var sil := m("shadow_silver")
	var boot := m("shadow_obsidian")
	var fwd := deg_to_rad(seat_leg_forward_deg)
	var hip := Vector3(0.105 * sx, 0.86, 0)
	var knee := Vector3(0.115 * sx, 0.48, 0.03)
	var shin := Vector3(0, -cos(fwd), -sin(fwd))
	var ankle := knee + shin * 0.30
	_seg(s, lea, hip, knee, 0.085, 0.066, 8)
	_put(s, sphere(0.072, 7, 3), sil, knee + Vector3(0, 0, 0.02), Vector3.ZERO, Vector3(1.0, 1.0, 1.1))
	_spike(s, sil, knee + Vector3(0, 0.0, 0.08), Vector3(0, 0.25, 1.0), 0.03, 0.1)
	_seg(s, lea, knee, ankle, 0.062, 0.056, 7)
	var front := Vector3(0, shin.z, -shin.y)   # perpendicular to the shin, toward the toes
	MountModel.sculpt_add(s, box(Vector3(0.1, 0.24, 0.03)), Transform3D(_to_dir(shin) * Basis(Vector3.UP, 0.0),
		knee + shin * 0.14 + front * 0.055), sil)
	# boot: cuff + foot pointing forward, toe up by fwd (level once seated)
	var foot_dir := Vector3(0, sin(fwd), cos(fwd))
	var foot_c := ankle + foot_dir * 0.06 + Vector3(0, -0.035, 0)
	MountModel.sculpt_add(s, capsule(0.06, 0.26), Transform3D(_to_dir(foot_dir), foot_c), boot)
	_put(s, cyl(0.078, 0.068, 0.1, 7), boot, ankle + shin * -0.02, Vector3(rad_to_deg(-fwd), 0, 0))


func _chest_sculpt(s: Dictionary) -> void:
	var coat := m("gloam_rider_coat")
	var lea := m("shadow_leather")
	var sil := m("shadow_silver")
	var iron := m("shadow_iron")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var thin := Basis.from_scale(Vector3(0.9, 1.0, 0.78))
	# torso (lathe, thin: Shadow units read taller): the quilted gambeson
	var prof := PackedVector2Array([Vector2(0.16, 0.92), Vector2(0.18, 1.0), Vector2(0.215, 1.16), Vector2(0.225, 1.26),
		Vector2(0.205, 1.34), Vector2(0.12, 1.42), Vector2(0.0, 1.45)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("grr_torso_v1", prof, 12), Transform3D(thin, Vector3.ZERO), coat)
	# dark leather cuirass with tarnished-silver rims and a silver diamond on the sternum
	var cp := PackedVector2Array([Vector2(0.19, 1.02), Vector2(0.226, 1.13), Vector2(0.236, 1.23), Vector2(0.222, 1.31)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("grr_cuirass_v1", cp, 12, false),
		Transform3D(Basis.from_scale(Vector3(0.92, 1.0, 0.82)), Vector3.ZERO), lea)
	MountModel.sculpt_add(s, torus(0.18, 0.205, 14), Transform3D(Basis.from_scale(Vector3(0.93, 1.0, 0.83)),
		Vector3(0, 1.02, 0)), sil)
	MountModel.sculpt_add(s, torus(0.2, 0.228, 14), Transform3D(Basis.from_scale(Vector3(0.93, 1.0, 0.83)),
		Vector3(0, 1.31, 0)), sil)
	_put(s, box(Vector3(0.13, 0.13, 0.03)), sil, Vector3(0, 1.17, 0.196), Vector3(-6, 0, 45))
	_put(s, box(Vector3(0.06, 0.06, 0.03)), cdark, Vector3(0, 1.17, 0.21), Vector3(-6, 0, 45))
	# silver gorget
	_put(s, cyl(0.12, 0.165, 0.1, 10), sil, Vector3(0, 1.4, 0))
	# the lance-side pauldron: three layered silver / iron lames and three swept spikes (the asymmetric element)
	_put(s, sphere(0.17, 10, 5), sil, SH_R + Vector3(0.03, 0.05, 0), Vector3(0, 0, -20), Vector3(1.0, 0.62, 1.1))
	_put(s, sphere(0.16, 10, 4), iron, SH_R + Vector3(0.06, -0.04, 0), Vector3(0, 0, -32), Vector3(1.02, 0.5, 1.12))
	_put(s, sphere(0.15, 10, 4), sil, SH_R + Vector3(0.085, -0.12, 0), Vector3(0, 0, -42), Vector3(0.95, 0.42, 1.05))
	for i: int in 3:
		var base := SH_R + Vector3(0.04 + 0.02 * float(i), 0.12 - 0.02 * float(i), 0.07 - 0.08 * float(i))
		_spike(s, sil, base, Vector3(0.35 + 0.1 * float(i), 1.0, -0.35 - 0.2 * float(i)), 0.045, 0.28 - 0.04 * float(i))
	# the rein-side shoulder: a small leather cap and one short spike
	_put(s, sphere(0.12, 8, 4), lea, SH_L + Vector3(-0.02, 0.04, 0), Vector3(0, 0, 15), Vector3(1.0, 0.6, 1.1))
	_spike(s, sil, SH_L + Vector3(-0.04, 0.09, 0.0), Vector3(-0.45, 1.0, -0.3), 0.03, 0.16)
	# team cowl over the shoulders with a ragged dark hem
	_put(s, cyl(0.14, 0.27, 0.16, 12, false), cloth, Vector3(0, 1.43, -0.01))
	MountModel.sculpt_fringe(s, cdark, MountModel.fringe_mesh("grr_cowl_hem_v1", 0.268, 0.25, 0.292, 0.272, 0.07, -180.0,
		180.0, 12, 0.09, 0.02, 0.6), Vector3(0, 1.355, -0.01))


## The tattered cloak (keep_separate "Cloak" at CLOAK_O, node-local): team violet over longer dark rags, hanging from
## the shoulders; tilted back over the croup when seated, lifted by the gallop.
func _cloak_sculpt(s: Dictionary) -> void:
	MountModel.sculpt_fringe(s, m("shadow_cloth"), MountModel.fringe_mesh("grr_cloak_out_v1", 0.2, 0.1, 0.3, 0.2, 0.5,
		105.0, 255.0, 6, 0.2, 0.025, 0.7), Vector3(0, 0, 0.02))
	MountModel.sculpt_fringe(s, m("shadow_cloth_dark"), MountModel.fringe_mesh("grr_cloak_in_v1", 0.19, 0.09, 0.285, 0.19,
		0.6, 110.0, 250.0, 5, 0.26, 0.02, 0.8), Vector3(0, -0.01, 0.03))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("shadow_skin")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var sil := m("shadow_silver")
	var smoke := m("dusk_smoke")
	var wisp := m("dusk_wisp")
	_put(s, cyl(0.06, 0.07, 0.12, 8), skin, Vector3(0, 1.5, 0.02))
	# the face (FaceKit rig, _build_parts): a gaunt pale face in the hood, glowing eyes; the silver half-mask is now a
	# chin guard under the mouth
	_put(s, sphere(0.14, 10, 6), skin, Vector3(0, 1.64, 0.06), Vector3.ZERO, Vector3(0.95, 1.08, 0.95))
	_put(s, sphere(0.13, 10, 5), sil, Vector3(0, 1.535, 0.07), Vector3.ZERO, Vector3(0.95, 0.42, 0.95))
	# the deep hood (team): shell, a brow overhang shading the eyes, a dark rim round the face, the hooked peak
	_put(s, sphere(0.205, 12, 6), cloth, Vector3(0, 1.69, -0.07), Vector3.ZERO, Vector3(1.06, 1.12, 1.12))
	_put(s, sphere(0.16, 10, 4), cloth, Vector3(0, 1.8, 0.07), Vector3(-12, 0, 0), Vector3(1.08, 0.48, 1.0))
	# the grim cowl's forward point over the brow (the reaper read), the drooping back point
	MountModel.sculpt_add(s, MountModel.tube_mesh("grr_hood_brow_v1", PackedVector3Array([Vector3(0, 1.83, 0.0),
		Vector3(0, 1.83, 0.14), Vector3(0, 1.79, 0.26)]), PackedFloat32Array([0.1, 0.06, 0.0]), 7, true, 0.8),
		Transform3D.IDENTITY, cloth)
	_put(s, torus(0.13, 0.172, 14), cdark, Vector3(0, 1.655, 0.12), Vector3(76, 0, 0), Vector3(1.0, 1.0, 1.15))
	MountModel.sculpt_add(s, MountModel.tube_mesh("grr_hood_peak_v3", PackedVector3Array([Vector3(0, 1.8, -0.12),
		Vector3(0, 1.83, -0.27), Vector3(0, 1.75, -0.4), Vector3(0, 1.6, -0.47)]),
		PackedFloat32Array([0.16, 0.1, 0.05, 0.0]), 8), Transform3D.IDENTITY, cloth)
	# smoke trailing off the hood's back edge (the steed's smoke, tying rider and mount)
	for sx: float in [-1.0, 1.0]:
		_spike(s, smoke, Vector3(0.12 * sx, 1.62, -0.2), Vector3(0.3 * sx, -0.55, -1.0), 0.07, 0.3, Vector3.RIGHT, 0.45)
	_spike(s, smoke, Vector3(0, 1.6, -0.24), Vector3(0, -0.7, -0.9), 0.08, 0.34, Vector3.RIGHT, 0.45)
	_spike(s, wisp, Vector3(0.05, 1.63, -0.26), Vector3(0.15, -0.4, -1.0), 0.04, 0.26, Vector3.RIGHT, 0.45)


func _arm_l_sculpt(s: Dictionary) -> void:
	var coat := m("gloam_rider_coat")
	var lea := m("shadow_leather")
	var sil := m("shadow_silver")
	var elbow := SH_L + Vector3(0, -0.28, 0)
	_put(s, sphere(0.08, 8, 4), coat, SH_L + Vector3(0, -0.02, 0))
	_seg(s, coat, SH_L, elbow, 0.068, 0.06, 8)
	_put(s, sphere(0.06, 7, 3), lea, elbow)
	_seg(s, lea, elbow, GRIP_L + Vector3(0, 0.05, 0), 0.058, 0.052, 8)
	_put(s, cyl(0.068, 0.06, 0.14, 8), sil, elbow + Vector3(0, -0.13, 0))
	_put(s, sphere(0.064, 8, 4), lea, GRIP_L, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


func _arm_r_sculpt(s: Dictionary) -> void:
	var sil := m("shadow_silver")
	var iron := m("shadow_iron")
	_seg(s, sil, SH_R + Vector3(0, -0.02, 0), ELBOW_R, 0.072, 0.064, 8)
	_put(s, sphere(0.07, 8, 4), iron, ELBOW_R)
	_spike(s, sil, ELBOW_R + Vector3(0.0, 0.0, -0.05), Vector3(0, -0.2, -1.0), 0.03, 0.1)


## The right forearm (keep_separate "ForearmR", node-local at the elbow): silver vambrace, an iron gauntlet.
func _fore_sculpt(s: Dictionary) -> void:
	var sil := m("shadow_silver")
	var iron := m("shadow_iron")
	var hand := HAND_R - ELBOW_R
	_seg(s, sil, Vector3.ZERO, hand + Vector3(0, 0.06, 0), 0.064, 0.056, 8)
	_put(s, cyl(0.082, 0.064, 0.07, 8), iron, hand + Vector3(0, 0.1, 0))
	_put(s, sphere(0.07, 8, 4), iron, hand, Vector3.ZERO, Vector3(1.0, 1.05, 1.15))


## The lance (keep_separate "Lance", child of ForearmR, node-local: the grip at the origin, +Z toward the tip).
func _lance_sculpt(s: Dictionary) -> void:
	var shaft := m("gloam_rider_shaft")
	var sil := m("shadow_silver")
	var iron := m("shadow_iron")
	var lea := m("shadow_leather")
	var glow := m("shadow_glow_mid")
	var z90 := Basis(Vector3.RIGHT, PI * 0.5)       # +Y -> +Z
	MountModel.sculpt_add(s, MountModel.tube_mesh("grr_lance_shaft_v1", PackedVector3Array([Vector3(0, 0, -0.74),
		Vector3(0, 0, 0.1), Vector3(0, 0, 1.2), Vector3(0, 0, 2.32)]), PackedFloat32Array([0.046, 0.056, 0.05, 0.04]), 7),
		Transform3D.IDENTITY, shaft)
	_put(s, sphere(0.06, 8, 4), sil, Vector3(0, 0, -0.76))
	MountModel.sculpt_add(s, cyl(0.0, 0.04, 0.14, 6), Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0, -0.85)), sil)
	MountModel.sculpt_add(s, MountModel.tube_mesh("grr_lance_grip_v1", PackedVector3Array([Vector3(0, 0, -0.18),
		Vector3(0, 0, 0.12)]), PackedFloat32Array([0.062, 0.062]), 8), Transform3D.IDENTITY, lea)
	# vamplate: an iron cone opening toward the hand, a silver rim with five back-swept spikes
	MountModel.sculpt_add(s, cyl(0.06, 0.2, 0.28, 12), Transform3D(z90, Vector3(0, 0, 0.3)), iron)
	MountModel.sculpt_add(s, torus(0.18, 0.215, 14), Transform3D(z90, Vector3(0, 0, 0.165)), sil)
	for i: int in 5:
		var a := TAU * float(i) / 5.0 + 0.3
		var o := Vector3(cos(a), sin(a), 0)
		_spike(s, sil, o * 0.19 + Vector3(0, 0, 0.17), o * 0.5 + Vector3(0, 0, -1.0), 0.03, 0.12)
	for z: float in [0.95, 1.65]:
		MountModel.sculpt_add(s, torus(0.045, 0.072, 10), Transform3D(z90, Vector3(0, 0, z)), sil)
	# socket, the long leaf head (wide in Y, thin in X), a glowing fuller on both faces
	MountModel.sculpt_add(s, cyl(0.05, 0.066, 0.14, 8), Transform3D(z90, Vector3(0, 0, 2.37)), sil)
	MountModel.sculpt_add(s, MountModel.tube_mesh("grr_lance_head_v1", PackedVector3Array([Vector3(0, 0, 2.42),
		Vector3(0, 0, 2.56), Vector3(0, 0, 2.76), Vector3(0, 0, LANCE_TIP)]), PackedFloat32Array([0.075, 0.1, 0.06, 0.0]),
		6, true, 0.28), Transform3D.IDENTITY, sil)
	MountModel.sculpt_add(s, MountModel.tube_mesh("grr_lance_fuller_v1", PackedVector3Array([Vector3(0, 0, 2.46),
		Vector3(0, 0, 2.58), Vector3(0, 0, 2.74), Vector3(0, 0, 2.88)]), PackedFloat32Array([0.03, 0.05, 0.03, 0.0]), 6,
		true, 0.75), Transform3D.IDENTITY, glow)
	# barbs: two big harpoon hooks at the head's base, two pairs of small hooks up its edges
	for sy: float in [-1.0, 1.0]:
		MountModel.sculpt_add(s, MountModel.tube_mesh("grr_barb_big_%s_v1" % sy, PackedVector3Array([
			Vector3(0, 0.06 * sy, 2.5), Vector3(0, 0.15 * sy, 2.4), Vector3(0, 0.2 * sy, 2.25)]),
			PackedFloat32Array([0.038, 0.024, 0.0]), 5, true, 0.45), Transform3D.IDENTITY, sil)
		for i: int in 2:
			var z0: float = 2.62 + 0.1 * float(i)
			var e: float = 0.085 - 0.02 * float(i)
			MountModel.sculpt_add(s, MountModel.tube_mesh("grr_barb_%d_%s_v1" % [i, sy], PackedVector3Array([
				Vector3(0, e * sy, z0), Vector3(0, (e + 0.05) * sy, z0 - 0.07), Vector3(0, (e + 0.06) * sy, z0 - 0.13)]),
				PackedFloat32Array([0.022, 0.013, 0.0]), 5, true, 0.45), Transform3D.IDENTITY, sil)


## Pennon wave shape k (0..PENNON_STEPS-1), node-local (hinge on the shaft at the origin): a swallow-tailed ribbon
## trailing along -Z (toward the grip), its width along -Y, waving along X (a travelling wave, phase k); a dark tie at
## the hinge and a silver diamond on both faces.
func _pennon_sculpt(s: Dictionary, k: int) -> void:
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var sil := m("shadow_silver")
	var ph: float = TAU * float(k) / float(PENNON_STEPS)
	var n: int = 7
	var rows: Array = []
	for i: int in n + 1:
		var u := float(i) / float(n)
		var w: float = lerpf(0.30, 0.22, u)
		var y0: float = -0.03
		var row := PackedVector3Array()
		for r: int in 3:
			var y: float = y0 - w * float(r) * 0.5
			var z: float = -PENNON_LEN * u
			if r == 1:
				z = maxf(z, -(PENNON_LEN - 0.25))   # the swallow-tail notch
			var x: float = _pen_wave(u, float(r) * 0.5, ph)
			row.append(Vector3(x, y, z))
		rows.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in n:
		var a: PackedVector3Array = rows[i]
		var b: PackedVector3Array = rows[i + 1]
		for r: int in 2:
			_quad2(st, a[r], b[r], b[r + 1], a[r + 1])
	st.index()
	MountModel.sculpt_add(s, st.commit(), Transform3D.IDENTITY, cloth)
	# the tie on the shaft and a dark hem strip at the hoist
	_put(s, box(Vector3(0.05, 0.07, 0.07)), cdark, Vector3(0, -0.03, 0.0))
	# the silver diamond (both faces, on the wave)
	var u0: float = 0.34
	var dx: float = _pen_wave(u0, 0.5, ph)
	_put(s, box(Vector3(0.024, 0.11, 0.11)), sil, Vector3(dx, -0.03 - lerpf(0.30, 0.22, u0) * 0.5, -PENNON_LEN * u0),
		Vector3(45, 0, 0))


## Pennon wave offset (X) at length share u, width share v (0 = the shaft edge), phase ph.
static func _pen_wave(u: float, v: float, ph: float) -> float:
	return 0.075 * u * (1.0 + 0.4 * v) * sin(TAU * u * 1.1 - ph)


## A double-sided quad a-b-c-d (thin: both faces offset 6 mm along the normal).
static func _quad2(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var nrm := (b - a).cross(d - a)
	if nrm.length_squared() < 1e-10:
		nrm = (c - b).cross(a - b)
	nrm = nrm.normalized()
	if nrm.x < 0.0:
		nrm = -nrm
	for side: float in [1.0, -1.0]:
		var o := nrm * 0.006 * side
		var nn := nrm * side
		_tri(st, a + o, b + o, c + o, nn)
		_tri(st, a + o, c + o, d + o, nn)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, nn: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-12:
		return
	if fn.dot(nn) > 0.0:   # Godot front faces are clockwise: the geometric normal must point away from nn
		var t := b
		b = c
		c = t
	for v: Vector3 in [a, b, c]:
		st.set_normal(nn)
		st.add_vertex(v)


# ================================================================ motion

## `lance_charge` (ATK_LEN, the melee hit at STRIKE): the couch, draw back, thrust and recovery are posed in _solve
## (after the kit seats the hips); this only runs the clock and the release.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"lance_charge":
		return super._pose_attack(prev, t)
	_atk_t = t
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
		lance_struck.emit(get_lance_tip())
	return t < ATK_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	if ev == &"attack_end":
		_atk_t = 99.0
	elif ev == &"release":
		_flare = maxf(_flare, 0.6)


## Timers (charge clock, strike event, glow flare, pennon phase), the ShadowModel dissolve when dead, and the pose on
## foot (never used by the unit: it is always seated).
func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	_dt = dt
	if _chg_t < CHG_LEN:
		var prev := _chg_t
		_chg_t += dt
		if prev < CHG_HIT and _chg_t >= CHG_HIT and not _dead:
			charge_struck.emit(get_lance_tip())
	_flare = move_toward(_flare, 0.0, dt / 0.6)
	_pen_ph = fmod(_pen_ph + dt * lerpf(0.9, 4.6, _gal), float(PENNON_STEPS))
	if not _rd_on and not _dead:
		_solve(1.0, 0.0, 0.0, 0.0)
	# lance fuller glow: the kit's level (veterancy, haste; 0 dead) x the strike / charge flare
	if _lance:
		var g: float = snappedf(glow_level() * (1.0 + 1.6 * _flare + 0.5 * _couch), 0.05)
		if g != _glow_w:
			_glow_w = g
			_lance.set_instance_shader_parameter(&"glow_boost", g)


## Riding: the kit's seat pose (lean, bob, reins), then the lance arm, the couch / thrust overlays, the pennon and
## the cloak. The left hand stays on the reins even while the right arm strikes.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 6.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	_off_rot[P_ARM_L] = sal + Vector3((-34.0 + bounce) * DEG, 0, 10.0 * DEG) * w
	_solve(w, gait, gallop, moving)
	if _cloak:
		var c: float = (34.0 + 6.0 * moving + gallop * moving * (14.0 + 5.0 * sin(TAU * gait * 2.0 + 0.6))) * w
		if _dead:
			c = 20.0 * w
		c = snappedf(c, 0.25)
		if c != _cloak_w:
			_cloak_w = c
			_cloak.rotation = Vector3(c * DEG, 0, 0)


## Solves the chest lean / twist overlays, the lance direction, the two-bone lance arm, the lance and the pennon.
func _solve(w: float, gait: float, gallop: float, moving: float) -> void:
	var g: float = gallop * moving
	_gal = g
	# ---- overlays: attack (lance_charge) and charge
	var aw: float = 0.0
	var push: float = 0.0
	var lean: float = 0.0
	var twist: float = 0.0
	if not _dead and _action == &"attack" and attack_style == &"lance_charge" and _atk_t < ATK_LEN:
		aw = _kf(_atk_t, AT_W)
		push = _kf(_atk_t, AT_PUSH)
		lean = _kf(_atk_t, AT_LEAN)
		twist = _kf(_atk_t, AT_TWIST)
	if not _dead and _chg_t < CHG_LEN:
		aw = maxf(aw, _kf(_chg_t, CR_W))
		push += _kf(_chg_t, CR_PUSH)
		lean += _kf(_chg_t, CR_LEAN)
		twist += _kf(_chg_t, CR_TWIST)
	_couch = aw
	# ---- chest: the kit's lean / sway, then our lean and twist
	var bc := Basis.from_euler(_rest_rot[P_CHEST] + _off_rot[P_CHEST])
	if lean != 0.0 or twist != 0.0:
		bc = bc * Basis(Vector3.RIGHT, lean * DEG * w) * Basis(Vector3.UP, twist * DEG * w)
		_off_rot[P_CHEST] = bc.get_euler() - _rest_rot[P_CHEST]
	var rb := Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT])
	# ---- the lance direction in the unit frame
	var gq: float = smoothstep(0.2, 0.9, g)
	var idle: float = 1.0 - moving
	var pitch: float = lerpf(CARRY, GALLOP, gq) + 2.2 * sin(TAU * (gait - 0.2)) * g + 1.2 * sin((_t + _phase_off) * 1.3) * idle
	var yaw: float = lerpf(CARRY_YAW, GALLOP_YAW, gq)
	pitch = lerpf(pitch, COUCH, aw)
	yaw = lerpf(yaw, COUCH_YAW, aw)
	var lm := Basis(Vector3.UP, yaw * DEG) * Basis(Vector3.RIGHT, pitch * DEG)
	if _dead:
		# the lance tips down with the slump and rolls with the fall
		var sl: float = smoothstep(0.0, 0.5, _death_t)
		lm = rb * (Basis(Vector3.UP, yaw * DEG) * Basis(Vector3.RIGHT, lerpf(pitch, DROP, sl) * DEG))
	_pitch_now = pitch
	_lance_mb = lm
	var inv := (rb * bc).inverse()
	var lc := (inv * lm).orthonormalized()
	var ldir := lc.z
	# ---- the right hand (chest frame): rest / gallop / couched, plus the thrust along the shaft
	var bob := Vector3(0, lerpf(0.012 * sin(2.0 * TAU * gait), 0.028 * sin(TAU * (gait - 0.4)), gallop) * moving, 0)
	var hand := REST_HAND_C.lerp(GALLOP_HAND_C, gq).lerp(COUCH_HAND_C, aw) + bob + ldir * push
	var pole := REST_POLE.lerp(COUCH_POLE, aw)
	var sar: Vector3 = _off_rot[P_ARM_R]
	_ik(_rest_pos[P_ARM_R], hand, UPPER_R, FORE_R, pole)
	_off_rot[P_ARM_R] = sar + _ik_u.get_euler() * w
	var ab := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R])
	var fb := _ik_f
	if _fore:
		var fq := (ab.inverse() * _ik_f).get_rotation_quaternion()
		if not fq.is_equal_approx(_fore_q_w):
			_fore_q_w = fq
			_fore.quaternion = fq
		fb = ab * Basis(fq)
	# ---- the lance in the forearm's frame
	if _lance:
		var lq := (fb.inverse() * lc).get_rotation_quaternion()
		if not lq.is_equal_approx(_lance_q_w):
			_lance_q_w = lq
			_lance.quaternion = lq
	_pose_pennon(g)


## The pennon hangs off the shaft (gravity + a breeze from the front, the wind of the gallop) and flutters: the node
## turns about the shaft toward that side, the cached wave shapes cycle.
func _pose_pennon(g: float) -> void:
	if _pennon == null:
		return
	var z := _lance_mb.z.normalized()
	var want := Vector3.DOWN + Vector3(0, 0, -1.0) * (0.35 + 1.8 * g)
	var p := want - z * want.dot(z)
	if p.length_squared() < 1e-4:
		p = -_lance_mb.y
	var pl := _lance_mb.inverse() * p
	var th: float = atan2(pl.x, -pl.y)
	var k: float = 1.0 - exp(-maxf(_dt, 0.0) * 7.0)
	_pen_th = lerp_angle(_pen_th, th, k) if _pen_rot_w < 900.0 else th
	var flutter: float = (5.0 + 9.0 * g) * DEG * sin(_pen_ph * TAU / float(PENNON_STEPS) * 2.0)
	var r: float = snappedf(_pen_th + flutter, 0.004)
	if r != _pen_rot_w:
		_pen_rot_w = r
		_pennon.rotation = Vector3(0, 0, r)
	var kk: int = int(_pen_ph) % PENNON_STEPS
	if kk != _pen_k_w and kk < _pen_cache.size():
		_pen_k_w = kk
		_pennon.mesh = _pen_cache[kk]


## Keyframe track [t, v, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth, 1 out, 2 in).
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
	super._on_revive()
	_atk_t = 99.0
	_chg_t = 99.0
	_flare = 0.0
	_couch = 0.0
	_gal = 0.0
	_lance_q_w = Quaternion(0, 0, 0, 0)
	_fore_q_w = Quaternion(0, 0, 0, 0)
	_pen_rot_w = 999.0
	_pen_k_w = -1
	_glow_w = -1.0
	_cloak_w = 99.0
	if _fore:
		_fore.quaternion = Quaternion.IDENTITY
	if _cloak:
		_cloak.rotation = Vector3.ZERO
