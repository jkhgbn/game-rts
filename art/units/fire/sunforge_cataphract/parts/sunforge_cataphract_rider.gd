class_name SunforgeCataphractRider
extends FireModel
## Sunforge Cataphract rider (stables.md 2, Fire V: the tier-3 anchor of the army). Seated with the kit's
## CharacterModel.set_seated on the gilded Sunforge Boar (parts/sunforge_boar.tscn); the scene pairing them is
## sunforge_cataphract.tscn (SunforgeCataphractModel, scaled x1.12: the biggest Fire rider).
## Look: an old sun-knight in plate of deep sun-gold (materials/sunforge_gold) over a bronze under-plate, gold pauldrons
## over team cloth cap sleeves, a team tabard with a gold sun and a long back skirt, a team cape; on his back the SUN
## WHEEL (the 40 m hook: a bright gold ring with eight rays round a team disc and a gold boss, tilted back over the cape);
## an open gold helm crowned with five short sun rays and a team horsehair plume, a pale braided beard (FaceKit: stern,
## amber eyes, pale brows, round ears); in the right fist the SUNFORGE MAUL resting on the shoulder (a long
## bound haft, a gold forge-hammer drum with glowing sun faces, a spike). No shield: the left hand keeps the reins.
## Glow: the maul's sun faces (merged in ArmR, own glow driven here: they flare on the strike); the boar's mane is the
## other.
## Attack `sun_smash` (0.80 s, melee strike STRIKE_T 0.12 s): the maul heaves back over the shoulder, then comes over
## and down in front of the boar with the whole body (lean + twist), a slow recovery. play_charge() (0.85 s, hit
## CHARGE_HIT 0.10 s): the maul brandished high, the rider stands in the stirrups and leans in; charge_struck(at) at the
## hit frame (maul head, world). Death: FireModel's burn while riding the boar's fall.
## Hooks (on top of the kit's, the names the BlazeRiderModel root forwards): play_charge(), get_lance_tip() /
## get_weapon_tip() (the maul head, world), lance_pitch() (0: no lance), couch_amount() (the charge weight),
## is_charging(), set_rank(rank) (no rank-3 research for this unit: accepted, no look), authored_mesh_count(); signals
## charge_struck(at), lance_struck(at) (the attack's strike frame, maul head).
## Budget (rider, JS cap ~3000 vertices with the face): 6 draw instances at rest (Hips with the legs astride, Chest with
## the sun wheel, Head, Face, ArmL, ArmR with the maul); VetTrim hidden; no blob (the boar's shows); 1 one-shot particle
## system (the death embers); 0 lights.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

const SH_L := Vector3(-0.33, 1.37, 0.0)
const SH_R := Vector3(0.33, 1.37, 0.0)
const ELBOW_R := Vector3(0.38, 1.10, -0.04)
const FIST_R := Vector3(0.39, 1.07, 0.21)
const ELBOW_L := Vector3(-0.36, 1.09, -0.02)
const FIST_L := Vector3(-0.34, 1.05, 0.23)
const HEAD_C := Vector3(0, 1.60, 0.06)
const HEAD_R := 0.135
## The maul: from the fist along MAUL_DIR (rest: up, back and out over the right shoulder), the drum head at MAUL_LEN.
const MAUL_DIR := Vector3(0.28, 0.74, -0.61)
const MAUL_LEN := 1.24
const MAUL_BUTT := -0.26
## The sun wheel on the back (Chest pivot): centre, tilt back (deg), ring radius.
const WHEEL_C := Vector3(0, 1.74, -0.31)
const WHEEL_TILT := 26.0
const WHEEL_R := 0.33
const ATTACK_LEN := 0.80
const STRIKE_T := 0.12
const CHARGE_LEN := 0.85
const CHARGE_HIT := 0.10
const PALE := Color(0.86, 0.84, 0.78)
## The deep sun-gold of the plate (own material: the kit's unit_gold_trim is kept for the bright trim and rays).
const GOLD_MAT := "res://art/units/fire/sunforge_cataphract/materials/sunforge_gold.tres"

# Attack (sun_smash) / charge tracks [t, v, ease, ...] (FireModel._kf format; arm x: + brings the maul head forward).
static var S_ARM := PackedFloat32Array([0.0, 0.0, 0, 0.07, -38.0, 1, 0.12, 96.0, 2, 0.32, 74.0, 0, 0.80, 0.0, 0])
static var S_ARM_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, 8.0, 1, 0.12, -10.0, 2, 0.40, -6.0, 0, 0.80, 0.0, 0])
static var S_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.13, 20.0, 2, 0.36, 12.0, 0, 0.80, 0.0, 0])
static var S_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, 20.0, 1, 0.13, -16.0, 2, 0.40, -8.0, 0, 0.80, 0.0, 0])
static var S_REIN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -24.0, 1, 0.14, -8.0, 0, 0.80, 0.0, 0])
static var C_K := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])

var _parts_n: int = 0
var _arm_r: Node3D
var _embers: GPUParticles3D

var _smash_k: float = 0.0
var _charge_t: float = 99.0
var _charge_k: float = 0.0
var _cast_k: float = 0.0
var _flare: float = 0.0
var _glow_w: float = -1.0
var _glow_mi: GeometryInstance3D


# ================================================================ public hooks

## The charge (the unit's charge hit): the maul brandished high, a lean into the blow. 0.85 s; charge_struck(at) at
## CHARGE_HIT.
func play_charge() -> void:
	if _dead:
		return
	_charge_t = 0.0
	_flare = 1.0
	set_process(true)


## World position of the maul head (VFX: impact, charge streak). BlazeRiderModel forwards it as get_lance_tip.
func get_lance_tip() -> Vector3:
	if _arm_r and _arm_r.is_inside_tree():
		return _arm_r.global_transform * (FIST_R + MAUL_DIR.normalized() * MAUL_LEN - model_origin(_arm_r))
	return global_position + Vector3(0.5, 2.4, -0.6)


func get_weapon_tip() -> Variant:
	return get_lance_tip()


func lance_pitch() -> float:
	return 0.0


func couch_amount() -> float:
	return _charge_k


func is_charging() -> bool:
	return _charge_t < CHARGE_LEN


## The Sunforge Cataphract has no rank-3 research (stables.md 3): accepted, no look.
func set_rank(_rank: int) -> void:
	pass


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var head: Node3D = $Root/Chest/Head
	_arm_r = $Root/Chest/ArmR
	_sculpt($Root/Hips, "sf_hips_v3", _hips_sculpt)
	_sculpt($Root/Chest, "sf_chest_v3", _chest_sculpt)
	_sculpt(head, "sf_head_v4", _head_sculpt)
	# Face: an old sun-knight: amber eyes under pale brows, round ears; the mouth sits on the top of the sculpted pale
	# beard (mouth canvas).
	_face = UnitFaces.attach_lean(self, head, "sunforge_cataphract_rider", {"center": HEAD_C, "radius": HEAD_R,
		"head_mesh": sphere(HEAD_R, 10, 6), "head_scale": Vector3(0.96, 1.04, 0.95), "preset": &"stern", "detail": &"low",
		"skin": FIRE_SKIN.darkened(0.05), "hair": PALE, "hair_tip": Color(1.0, 0.97, 0.9), "eyes": Color(0.86, 0.58, 0.14),
		"ears": &"round", "eye": {"c": Vector2(0.047, 0.010), "hw": 0.026, "top": 0.017, "ir": 0.013},
		"palette": {"brow": PALE.darkened(0.1)},
		"mouth_canvas": FaceKit.canvas(Vector3(0, 1.505, 0.12), 0.10, sphere(0.11, 7, 3), Vector3(1.2, 0.95, 0.8),
			Vector3.INF, Basis(Vector3.RIGHT, deg_to_rad(18.0)), 0.002),
		"mouth": {"c": Vector2(0.0, 0.060), "hw": 0.030}}, false)
	_sculpt($Root/Chest/ArmL, "sf_arm_l_v2", func(s: Dictionary) -> void: _arm_sculpt(s, -1.0))
	_sculpt(_arm_r, "sf_arm_r_v2", _arm_r_sculpt)
	var vet := add_part(head, cyl(0.2, 0.2, 0.04, 12, false), palette(&"fire_glow"), Vector3(0, 1.70, -0.01),
		Vector3(-4, 0, 0), Vector3(1.0, 1.0, 1.1), true, "VetTrim")
	vet.set_meta(&"vet_trim", true)
	_parts_n += 1
	_embers = CharacterModel.make_motes(Color(1.0, 0.55, 0.12), 10, 0.9, 0.36, 1.5, 0.16, false, true)
	_embers.name = "BurnEmbers"
	_embers.set_meta(&"burn_fx", true)
	_embers.set_meta(&"keep_separate", true)
	_embers.position = Vector3(0, 0.25, 0)
	$Root/Chest.add_child(_embers)


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
	if name == "sunforge_gold":
		return MountModel.material_at(GOLD_MAT)
	return palette(StringName(name))


static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


# ---------------------------------------------------------------- body

## Hips + both legs astride (no leg pivots: merged into Hips = 1 draw): team-dark riding skirt, gold belt plate, the long
## team tabard's back skirt over the cantle, dark trousers, gold knee cops and greaves, dark sabatons.
func _hips_sculpt(s: Dictionary) -> void:
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var gold := m("sunforge_gold")
	var bright := m("unit_gold_trim")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	# G-C leftovers: a faulds skirt of three rolled bronze lames (was an 8-sided can), a gold belt band, the bevelled
	# tabard skirt with a pointed gold hem, smooth legs with domed gold knee cops, ridged greaves and rounded sabatons
	for k: int in 3:
		var y0: float = 0.71 + 0.075 * float(k)
		RiderShapes.lame(s, bronze, 0.27 - 0.012 * float(k), 0.255 - 0.012 * float(k), y0, y0 + 0.085, 0.0, TAU, 14, 0.016)
	RiderShapes.band(s, bright, 0.232, 0.07, 0.016, 14, Transform3D(Basis.IDENTITY, Vector3(0, 0.935, 0)))
	# the long tabard skirt hanging over the cantle, a gold hem (the front one would sit inside the boar's hump)
	RiderShapes.box_plate(s, cloth, Vector3(0.37, 0.52, 0.026), Vector3(0, 0.715, -0.26), Vector3(18, 0, 0), Vector3.ONE,
		0.9, 0.14)
	RiderShapes.box_plate(s, bright, Vector3(0.33, 0.075, 0.03), Vector3(0, 0.478, -0.338), Vector3(18, 0, 0), Vector3.ONE,
		0.55, 0.55)
	for sx: float in [-1.0, 1.0]:
		var hip := Vector3(0.13 * sx, 0.83, 0.02)
		var knee := Vector3(0.41 * sx, 0.62, 0.24)
		var ankle := Vector3(0.50 * sx, 0.40, 0.12)
		RiderShapes.tube(s, cdark, PackedVector3Array([hip, hip.lerp(knee, 0.45), knee]),
			PackedFloat32Array([0.108, 0.113, 0.086]), 9)
		RiderShapes.lathe(s, gold, PackedVector2Array([Vector2(0.094, 0.0), Vector2(0.09, 0.035), Vector2(0.064, 0.068),
			Vector2(0.0, 0.084)]), 10, MountModel.frame(knee + Vector3(0.01 * sx, 0.01, -0.005), Vector3(0.1 * sx, 0.1, 1.0),
			Vector3.UP), 1.0, 1.2)
		var an := ankle + Vector3(0, -0.04, 0)
		RiderShapes.tube(s, gold, PackedVector3Array([knee, knee.lerp(an, 0.3), an]),
			PackedFloat32Array([0.082, 0.088, 0.07]), 9)
		var fr := Vector3(0.0, 0.25, 1.0).normalized()
		RiderShapes.tube(s, bright, PackedVector3Array([knee.lerp(an, 0.12) + fr * 0.076, knee.lerp(an, 0.5) + fr * 0.082,
			an + fr * 0.06]), PackedFloat32Array([0.02, 0.018, 0.01]), 5)
		var fd := Vector3(0.05 * sx, 0.03, 1.0).normalized()
		var fc := ankle + Vector3(0.01 * sx, -0.05, 0.10)
		RiderShapes.boot(s, leather, fc - fd * 0.12, fc + fd * 0.16, 0.074)
		RiderShapes.lame(s, gold, 0.08, 0.072, 0.0, 0.07, 0.0, TAU, 10, 0.014, MountModel.frame(an + Vector3(0, 0.0, 0),
			knee - an, Vector3.BACK))


func _chest_sculpt(s: Dictionary) -> void:
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var gold := m("sunforge_gold")
	var bright := m("unit_gold_trim")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	# bronze under-plate torso, the gold cuirass over it (broad, flattened front-back)
	var prof := PackedVector2Array([Vector2(0.21, 0.90), Vector2(0.24, 1.0), Vector2(0.275, 1.14), Vector2(0.29, 1.26),
		Vector2(0.265, 1.36), Vector2(0.15, 1.45), Vector2(0.0, 1.47)])
	RiderShapes.lathe(s, bronze, prof, 12, Transform3D.IDENTITY, 1.0, 0.84)
	# G-C leftovers: the gold cuirass turned on 16 sides with a rolled waist lip and a centre ridge
	var cu := PackedVector2Array([Vector2(0.262, 1.015), Vector2(0.268, 1.03), Vector2(0.298, 1.15), Vector2(0.31, 1.26),
		Vector2(0.292, 1.35), Vector2(0.22, 1.425)])
	RiderShapes.lathe(s, gold, cu, 16, Transform3D.IDENTITY, 1.0, 0.88, false)
	RiderShapes.tube(s, bright, PackedVector3Array([Vector3(0, 1.15, 0.262), Vector3(0, 1.26, 0.272),
		Vector3(0, 1.35, 0.256)]), PackedFloat32Array([0.014, 0.014, 0.008]), 4)
	# the team tabard over the belly with the embroidered sun (a gold disc, a dark heart), bevelled with a pointed hem
	RiderShapes.box_plate(s, cloth, Vector3(0.32, 0.22, 0.026), Vector3(0, 1.055, 0.262), Vector3(-6, 0, 0), Vector3.ONE,
		0.85, 0.2)
	RiderShapes.lathe(s, bright, PackedVector2Array([Vector2(0.072, -0.01), Vector2(0.07, 0.006), Vector2(0.05, 0.014),
		Vector2(0.0, 0.016)]), 12, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(84.0)), Vector3(0, 1.08, 0.282)))
	RiderShapes.box_plate(s, cdark, Vector3(0.045, 0.045, 0.024), Vector3(0, 1.08, 0.293), Vector3(-6, 0, 45))
	# gold gorget: two rolled lames
	RiderShapes.lame(s, gold, 0.172, 0.146, 1.40, 1.45, 0.0, TAU, 12, 0.014)
	RiderShapes.lame(s, gold, 0.148, 0.122, 1.445, 1.50, 0.0, TAU, 12, 0.012)
	# layered pauldrons: a gold dome with a bright rim over a team cloth cap sleeve
	for sx: float in [-1.0, 1.0]:
		var pf := MountModel.frame(Vector3(0.35 * sx, 1.41, -0.01), Vector3(0.55 * sx, 1.0, 0.0), Vector3.BACK)
		RiderShapes.lathe(s, gold, PackedVector2Array([Vector2(0.19, -0.07), Vector2(0.195, -0.01), Vector2(0.155, 0.05),
			Vector2(0.08, 0.085), Vector2(0.0, 0.092)]), 14, pf)
		RiderShapes.band(s, bright, 0.19, 0.03, 0.012, 14, Transform3D(pf.basis, pf * Vector3(0, -0.055, 0)))
		RiderShapes.lathe(s, cloth, PackedVector2Array([Vector2(0.195, -0.045), Vector2(0.2, -0.035), Vector2(0.19, 0.0),
			Vector2(0.17, 0.04)]), 12, Transform3D(pf.basis, pf * Vector3(0.02 * sx, -0.115, 0)), 1.0, 1.0, false)
	# the long team cape, a dark leather yoke (a rounded strap)
	_put(s, cape(0.74, 0.70), m("fire_cape"), Vector3(0, 1.07, -0.36), Vector3(28, 0, 0))
	RiderShapes.tube(s, leather, PackedVector3Array([Vector3(-0.29, 1.39, -0.2), Vector3(-0.13, 1.415, -0.265),
		Vector3(0.13, 1.415, -0.265), Vector3(0.29, 1.39, -0.2)]), PackedFloat32Array([0.032, 0.036, 0.036, 0.032]), 6, true,
		0.65)
	# the SUN WHEEL on the back: a strut, the gold ring, eight rays, the team disc and a gold boss, tilted back
	# the wheel's plane faces backward and up: its normal = -Z tilted up by WHEEL_TILT (cylinder axis +Y -> the normal)
	var nrm := Vector3(0, sin(deg_to_rad(WHEEL_TILT)), -cos(deg_to_rad(WHEEL_TILT)))
	var wb := MountModel.frame(Vector3.ZERO, nrm, Vector3.UP).basis
	_seg(s, bronze, Vector3(0, 1.30, -0.22), WHEEL_C + nrm * -0.02, 0.035, 0.03, 5)
	MountModel.sculpt_add(s, cyl(WHEEL_R, WHEEL_R, 0.05, 12, false), Transform3D(wb, WHEEL_C), bright)
	MountModel.sculpt_add(s, cyl(WHEEL_R - 0.02, WHEEL_R - 0.02, 0.025, 10), Transform3D(wb, WHEEL_C), cloth)
	_put(s, sphere(0.07, 7, 3), gold, WHEEL_C + nrm * 0.03, Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
	for k: int in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var d := wb * Vector3(cos(a), 0, sin(a))
		MountModel.sculpt_add(s, prism(Vector3(0.075, 0.13, 0.03)), Transform3D(MountModel.frame(Vector3.ZERO, d, nrm).basis,
			WHEEL_C + d * (WHEEL_R + 0.06)), bright)


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("fire_skin")
	var beard := m("shadow_bone")
	var gold := m("sunforge_gold")
	var bright := m("unit_gold_trim")
	var bronze := m("fire_bronze")
	_put(s, cyl(0.075, 0.085, 0.12, 10), skin, Vector3(0, 1.50, 0.02))
	# the face sphere (FaceKit canvas) and the pale beard (the mouth canvas) falling in a braided point
	_put(s, sphere(HEAD_R, 10, 6), skin, HEAD_C, Vector3.ZERO, Vector3(0.96, 1.04, 0.95))
	_put(s, sphere(0.11, 7, 3), beard, Vector3(0, 1.505, 0.12), Vector3(18, 0, 0), Vector3(1.2, 0.95, 0.8))
	MountModel.sculpt_add(s, MountModel.tube_mesh("sf_beard_v1", PackedVector3Array([Vector3(0, 1.45, 0.17),
		Vector3(0, 1.36, 0.21), Vector3(0, 1.27, 0.22)]), PackedFloat32Array([0.055, 0.04, 0.0]), 5), Transform3D.IDENTITY,
		beard)
	# the open gold helm: a dome from the brow, a bronze brow band, a crown of five short sun rays, a neck guard
	var hp := PackedVector2Array([Vector2(0.172, 1.672), Vector2(0.182, 1.735), Vector2(0.165, 1.80), Vector2(0.115, 1.85),
		Vector2(0.0, 1.87)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("sf_helm_v1", hp, 10),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.1)), Vector3(0, 0, -0.01)), gold)
	_put(s, cyl(0.186, 0.186, 0.04, 10, false), bronze, Vector3(0, 1.68, -0.01), Vector3.ZERO, Vector3(1.0, 1.0, 1.1))
	for k: int in 5:
		var a := deg_to_rad(-64.0 + 32.0 * float(k))
		var d := Vector3(sin(a), 0, cos(a) * 1.1)
		_put(s, prism(Vector3(0.08, 0.14, 0.025)), bright, Vector3(0, 1.735, -0.01) + d * 0.18 + Vector3(0, 0.03, 0),
			Vector3(-10.0 * cos(a), rad_to_deg(a), 0))
	# a team horsehair plume from the crown, falling back over the nape
	var cloth := m("fire_cloth")
	for k: int in 5:
		var u := lerpf(-1.0, 1.0, float(k) / 4.0)
		MountModel.sculpt_lock(s, cloth, Vector3(u * 0.05, 1.875, -0.02 - 0.03 * absf(u)), Vector3(u * 0.35, 0.25, -1.0).normalized(),
			Vector3.UP, 0.10, 0.36 - 0.06 * absf(u), 0.06)
	var tb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))   # shell z -> up, angle 0 -> +Z
	MountModel.sculpt_add(s, MountModel.shell_mesh("sf_nape_v1", 0.21, 0.225, 125.0, 235.0, 1.52, 1.69, 0.02, 5, 1, 0.86,
		0.0), Transform3D(tb, Vector3(0, 0, -0.01)), gold)


## Upper arm (bronze rerebrace over the team-dark sleeve), a gold elbow cop, gold vambrace, leather gauntlet.
func _arm_sculpt(s: Dictionary, sx: float) -> void:
	var cdark := m("fire_cloth_dark")
	var gold := m("sunforge_gold")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var sh: Vector3 = SH_L if sx < 0.0 else SH_R
	var el: Vector3 = ELBOW_L if sx < 0.0 else ELBOW_R
	var fi: Vector3 = FIST_L if sx < 0.0 else FIST_R
	# G-C leftovers: sleeve tube, a rerebrace of two rolled lames, a cupped gold elbow cop, a flared vambrace
	var s0 := sh + Vector3(0, 0.02, 0)
	var d := (fi - el).normalized()
	var u := (el - s0).normalized()
	RiderShapes.tube(s, cdark, PackedVector3Array([s0, s0.lerp(el, 0.45), el]), PackedFloat32Array([0.09, 0.095, 0.075]), 9)
	for k: int in 2:
		var c := s0.lerp(el, 0.3 + 0.28 * float(k))
		RiderShapes.lame(s, bronze, 0.1 - 0.006 * float(k), 0.096 - 0.006 * float(k), 0.0, 0.1, 0.0, TAU, 10, 0.012,
			MountModel.frame(c, -u, Vector3.BACK))
	RiderShapes.lathe(s, gold, PackedVector2Array([Vector2(0.082, 0.0), Vector2(0.078, 0.032), Vector2(0.05, 0.064),
		Vector2(0.0, 0.074)]), 9, MountModel.frame(el - d * 0.01, u - d, Vector3(sx, 0, 0)))
	var w0 := fi - d * 0.04
	RiderShapes.tube(s, gold, PackedVector3Array([el, el.lerp(w0, 0.3), w0, w0 + d * 0.006]),
		PackedFloat32Array([0.076, 0.081, 0.087, 0.062]), 9)
	_put(s, sphere(0.082, 9, 4), leather, fi, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


## The right arm and the SUNFORGE MAUL in its fist (merged: the arm swings it): a bronze pommel, the leather-bound haft
## with gold bands, the gold drum head across the haft with glowing sun faces at both ends, a spike on top.
func _arm_r_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, 1.0)
	var wood := m("fire_wood")
	var gold := m("sunforge_gold")
	var bright := m("unit_gold_trim")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var glow := m("fire_glow_hero")
	var d := MAUL_DIR.normalized()
	var butt := FIST_R + d * MAUL_BUTT
	var head := FIST_R + d * MAUL_LEN
	# G-C leftovers: a smooth haft, raised grip wraps, a barrel drum with rolled rims and a waist band
	RiderShapes.tube(s, wood, PackedVector3Array([butt, butt.lerp(head, 0.5), head - d * 0.12]),
		PackedFloat32Array([0.042, 0.04, 0.038]), 8)
	_put(s, sphere(0.058, 8, 4), bronze, butt)
	for k: int in 4:
		RiderShapes.band(s, leather, 0.042, 0.06, 0.01, 8, MountModel.frame(FIST_R + d * (-0.11 + 0.08 * float(k)), d,
			Vector3.UP))
	var bp := FIST_R + d * 0.62
	RiderShapes.band(s, bright, 0.04, 0.06, 0.012, 8, MountModel.frame(bp, d, Vector3.UP))
	# the drum: its axis across the haft, in the swing plane (the faces strike forward / back)
	var ax := d.cross(Vector3.RIGHT).normalized()
	var df := MountModel.frame(head, ax, d)
	RiderShapes.lathe(s, gold, PackedVector2Array([Vector2(0.13, -0.17), Vector2(0.142, -0.15), Vector2(0.135, -0.12),
		Vector2(0.125, -0.04), Vector2(0.125, 0.04), Vector2(0.135, 0.12), Vector2(0.142, 0.15), Vector2(0.13, 0.17)]), 14, df)
	RiderShapes.band(s, bright, 0.126, 0.05, 0.012, 14, df)
	for sa: float in [-1.0, 1.0]:
		_seg(s, glow, head + ax * 0.165 * sa, head + ax * 0.185 * sa, 0.10, 0.085, 10)
	_seg(s, bright, head + d * 0.10, head + d * 0.30, 0.05, 0.0, 5)


# ================================================================ motion

func _after_ready() -> void:
	super()
	if _embers and not _burn_fx.has(_embers):
		_burn_fx.append(_embers)
	_glow_mi = _merged_nodes.get(P_ARM_R)


## `sun_smash`: heave back, the maul over and down in front (strike STRIKE_T), a slow recovery. The arm angles are set
## in _pose_seated (after the kit's reins pose); this runs the clock, the body and the strike event.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"sun_smash":
		return super._pose_attack(prev, t)
	_smash_k = 1.0
	rot(P_CHEST, Vector3(_kf(t, S_LEAN) * DEG, _kf(t, S_TWIST) * DEG, 0))
	rot(P_HEAD, Vector3(-_kf(t, S_LEAN) * 0.5 * DEG, -_kf(t, S_TWIST) * 0.4 * DEG, 0))
	rot(P_ARM_R, Vector3(_kf(t, S_ARM) * DEG, 0, _kf(t, S_ARM_Z) * DEG))
	rot(P_ARM_L, Vector3(_kf(t, S_REIN) * DEG, 0, 0))
	if prev < STRIKE_T and t >= STRIKE_T:
		_on_action_event(&"release")
		_flare = maxf(_flare, 1.0)
		lance_struck.emit(get_lance_tip())
	if t >= ATTACK_LEN:
		_smash_k = 0.0
	return t < ATTACK_LEN


## A salute for any cast: the maul raised to the sky.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-75.0 * DEG * _cast_k, 0, 10.0 * DEG * _cast_k))
	rot(P_CHEST, Vector3(-6.0 * DEG * _cast_k, 0, 0))
	return 0.75


func _extra_process(dt: float) -> void:
	super(dt)
	if _action != &"attack":
		_smash_k = 0.0
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
	_flare = maxf(0.0, _flare - dt / 0.6)
	_write_glow()


## Riding: the kit's seat pose; the maul arm rests (the reins' raise replaced), the left hand on the reins; the charge
## raises the maul high and leans in.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(1.5 * sin(2.0 * TAU * gait), 4.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var ck := _charge_k
	_off_rot[P_ARM_R] = sar + Vector3((-6.0 + bounce * 0.4 - 70.0 * ck) * DEG, 0, (-4.0 + 8.0 * ck) * DEG) * w
	if ck > 0.0:
		rot(P_CHEST, Vector3(14.0 * DEG * ck * w, -8.0 * DEG * ck * w, 0))
		rot(P_HEAD, Vector3(-12.0 * DEG * ck * w, 5.0 * DEG * ck * w, 0))
		pos(P_ROOT, Vector3(0, 0.06 * ck * w, 0))


## The maul's sun faces (merged in ArmR): the kit's glow level, flared by the strike / charge. The ArmR node drives its
## own glow_boost (meta own_glow).
func _write_glow() -> void:
	if _glow_mi == null:
		return
	if not _glow_mi.has_meta(&"own_glow"):
		_glow_mi.set_meta(&"own_glow", true)
		_glow_nodes.erase(_glow_mi)
	var g: float = snappedf(glow_level() * (1.0 + 1.4 * _flare + 0.6 * _charge_k), 0.05)
	if g != _glow_w:
		_glow_w = g
		_glow_mi.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	super()
	_smash_k = 0.0
	_charge_t = 99.0
	_charge_k = 0.0
	_cast_k = 0.0
	_flare = 0.0
	_glow_w = -1.0
	_write_glow()
