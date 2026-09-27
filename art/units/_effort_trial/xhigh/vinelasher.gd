extends NatureWarModel
## Vinelasher (effort trial, level xhigh), Nature T2 soldier (rush-balance.md 5.1 / 5.4). Height 1.8, radius 0.5,
## melee reach 3.0. A lean bark warrior: tan bark face and chest plate, dark bark legs, a team sash, loincloth, head
## ribbons, a pale leaf pauldron with team leaves on the LEFT shoulder (asymmetry), and a living russet thorn vine-whip
## 3 m long.
## Silhouette hook: the vine coils twice around the right forearm in horizontal loops (a ring from the pitch-55
## camera) and its tail rises over the right shoulder like a poised snake, the glowing bud tip hooked forward
## (the only glow point, nature_glow; high enough for the camera to see it).
## Attack `vine_lash` (own timeline, 0.7 s): the arm goes up overhead with the vine trailing behind, snaps down at
## 0.14 (release) while the vine cracks out 3 m to the front, a pink blossom opens on the handle's pommel, the vine
## drops, is dragged back and coils again. Cast (Snare Lash, 0.9 s): a low sidearm sweep, the vine's end loops into a
## snare ring 2.5 m ahead, a yank back, then the same recoil.
## The whip is ONE keep_separate node (3 surfaces: vine, thorns, glowing tip) whose mesh is swapped between 12
## pre-built cached shapes (0 = the coil); during a lash it is counter-rotated by the arm's pitch so the shapes are
## authored in the chest frame. Nothing is created after _ready (no nodes, meshes or materials per action).

const ATTACK_LEN := 0.7
const RELEASE := 0.14
const CAST_LEN := 0.9
const CAST_BLOOM := 0.24
const FIST := Vector3(0.44, 0.86, 0.07)       # right fist (model space, rest): the whip node's origin
const ELBOW_R := Vector3(0.40, 1.13, -0.01)
const HANDLE_DIR := Vector3(0.0, -0.5, 0.866)  # handle from the fist, forward-down
const BLOOM_LEN := 0.5
const VINE_R0 := 0.07     # chunky: the coil ring must read at 40 m (1 px ~ 4 cm)
const VINE_R1 := 0.036

# vine_lash tracks: [t, value, ease] (NatureWarModel._kf). Arm x: - raises forward (-165 = overhead).
static var L_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -165.0, 1, 0.14, -62.0, 2, 0.26, -58.0, 0, 0.45, -28.0, 0, 0.70, 0.0, 0])
static var L_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.08, -35.0, 1, 0.14, 20.0, 2, 0.40, 10.0, 0, 0.70, 0.0, 0])
static var L_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -10.0, 1, 0.14, 14.0, 2, 0.32, 8.0, 0, 0.70, 0.0, 0])
static var L_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 20.0, 1, 0.14, -18.0, 2, 0.34, -10.0, 0, 0.70, 0.0, 0])
static var L_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.05, 1, 0.14, 0.22, 2, 0.36, 0.18, 0, 0.70, 0.0, 0])
static var L_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 0.02, 1, 0.14, -0.06, 2, 0.36, -0.04, 0, 0.70, 0.0, 0])
static var L_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -10.0, 1, 0.14, 8.0, 0, 0.70, 0.0, 0])
static var L_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.08, 6.0, 1, 0.14, -26.0, 1, 0.40, -20.0, 0, 0.70, 0.0, 0])
static var L_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -4.0, 1, 0.14, 18.0, 1, 0.40, 14.0, 0, 0.70, 0.0, 0])
# snare_lash (cast) tracks
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, 35.0, 1, 0.24, -80.0, 2, 0.45, -74.0, 0, 0.62, 22.0, 1, 0.90, 0.0, 0])
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -30.0, 1, 0.24, 25.0, 2, 0.45, 15.0, 0, 0.62, -45.0, 1, 0.90, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, 8.0, 1, 0.24, 14.0, 2, 0.45, 10.0, 0, 0.62, -16.0, 1, 0.90, 0.0, 0])
static var C_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, 30.0, 1, 0.24, -24.0, 2, 0.45, -18.0, 0, 0.62, 16.0, 1, 0.90, 0.0, 0])
static var C_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.04, 1, 0.24, 0.16, 2, 0.45, 0.12, 0, 0.62, -0.14, 1, 0.90, 0.0, 0])
static var C_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.10, 1, 0.24, -0.12, 0, 0.45, -0.08, 0, 0.62, -0.03, 0, 0.90, 0.0, 0])
static var C_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -10.0, 1, 0.24, -28.0, 1, 0.45, -24.0, 0, 0.62, -8.0, 1, 0.90, 0.0, 0])
static var C_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, 12.0, 1, 0.24, 20.0, 1, 0.45, 18.0, 0, 0.62, 26.0, 1, 0.90, 0.0, 0])
# Whip shape per moment: [t_start, frame, ...] (frame 0 = the coil, 1-11 = the lash shapes of _lash_ctrl()).
static var ATK_FRAMES := PackedFloat32Array([0.0, 1, 0.035, 2, 0.09, 3, 0.125, 4, 0.24, 5, 0.34, 6, 0.47, 7, 0.6, 0])
static var CAST_FRAMES := PackedFloat32Array([0.0, 8, 0.12, 9, 0.24, 10, 0.45, 11, 0.62, 6, 0.75, 7, 0.86, 0])

static var _vl_frames: Array[Mesh] = []

var _whip: MeshInstance3D
var _blossom: MeshInstance3D
var _whip_f: int = 0
var _whip_turned: bool = false
var _bloom_t: float = 99.0
var _bloom_s: float = -1.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := nature(&"nature_cloth")
	var cdark := nature(&"nature_cloth_dark")
	var bark := nature(&"nature_bark")
	var bdark := nature(&"nature_bark_dark")
	var skin := nature(&"nature_skin")
	var thorn := nature(&"nature_thorn")
	# ---- Legs: lean dark bark legs, the left foot forward (a fighting stance), bark greaves, root boots.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		var fz: float = 0.07 if sx < 0.0 else -0.05
		add_part(leg, tapered_path_mesh("vl_leg_%s" % sx, PackedVector3Array([Vector3(0.12 * sx, 0.92, 0.0),
			Vector3(0.14 * sx, 0.50, 0.05 + fz), Vector3(0.14 * sx, 0.10, fz)]),
			PackedFloat32Array([0.10, 0.072, 0.058])),
			bdark, Vector3.ZERO)
		add_part(leg, sphere(0.078, 8, 4), bark, Vector3(0.14 * sx, 0.51, 0.08 + fz))
		add_part(leg, cyl(0.078, 0.066, 0.24, 6), bark, Vector3(0.14 * sx, 0.30, 0.05 + fz), Vector3(-7, 0, 0),
			Vector3(1.0, 1.0, 0.8))
		add_part(leg, box(Vector3(0.14, 0.10, 0.27)), bdark, Vector3(0.14 * sx, 0.05, 0.05 + fz))
	# ---- Hips: bark pelvis, dark belt, team loincloth leaves front and back.
	add_part(hips, cyl(0.17, 0.19, 0.20, 8), bark, Vector3(0, 0.92, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.8))
	add_part(hips, cyl(0.20, 0.20, 0.06, 8, false), bdark, Vector3(0, 0.99, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	add_part(hips, _loin_mesh(), cloth, Vector3.ZERO)
	# ---- Chest: lean V torso of red bark (nature_hair russet: off the khaki heath / ochre autumn floors and the meadow
	# green, Art Lab R4 / S1), a pale bark-tan chest plate (tops light), a team sash across it, a pale right shoulder
	# knob with thorns, a pale leaf plate + two team leaves on the left shoulder.
	add_part(chest, cyl(0.22, 0.15, 0.48, 8), nature(&"nature_hair"), Vector3(0, 1.18, 0), Vector3(6, 0, 0),
		Vector3(1.0, 1.0, 0.72))
	add_part(chest, sphere(0.2, 8, 4), skin, Vector3(0, 1.29, 0.05), Vector3(6, 0, 0), Vector3(1.1, 0.85, 0.66))
	add_part(chest, cyl(0.215, 0.215, 0.07, 10, false), cloth, Vector3(0, 1.17, 0), Vector3(0, 0, 32),
		Vector3(1.0, 1.0, 0.78))
	add_part(chest, cyl(0.06, 0.07, 0.12, 6), bark, Vector3(0, 1.47, 0.02))
	add_part(chest, sphere(0.1, 8, 4), skin, Vector3(0.25, 1.40, 0.0), Vector3.ZERO, Vector3(1.1, 0.9, 1.0))
	add_thorns(chest, Vector3(0.28, 1.44, 0.0), 3, 0.05, 0.03, 0.13, 50.0, thorn, 30.0)
	add_part(chest, sphere(0.09, 8, 4), bark, Vector3(-0.25, 1.40, 0.0))
	# Pale plate on top: not grass-green (R3 top third), light on the dark Old Wood / heath (R4k / R4).
	add_part(chest, _pauldron_mesh(), skin, Vector3.ZERO)
	add_part(chest, _pauldron_leaves_mesh(), cloth, Vector3.ZERO)
	# ---- Head: long tan bark face, bark brow over two slanted dark eye slits, pale swept-back thorn crest (a value
	# step that survives dim light, R12), team ribbons trailing back, L4 trim.
	add_part(head, sphere(0.13, 8, 5), skin, Vector3(0, 1.66, 0.04), Vector3.ZERO, Vector3(0.85, 1.15, 1.0))
	add_part(head, sphere(0.07, 6, 3), skin, Vector3(0, 1.55, 0.12), Vector3.ZERO, Vector3(0.9, 0.8, 1.0))
	add_part(head, box(Vector3(0.18, 0.04, 0.07)), bark, Vector3(0, 1.725, 0.125), Vector3(-12, 0, 0))
	add_part(head, _eyes_mesh(), bdark, Vector3.ZERO)
	add_part(head, _crest_mesh(), skin, Vector3.ZERO)
	add_part(head, _ribbons_mesh(), cloth, Vector3.ZERO)
	var trim := add_part(head, torus(0.10, 0.13, 10), palette(&"unit_gold_trim"), Vector3(0, 1.74, 0.03),
		Vector3(-10, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: bark arm, team bracer, dark fist.
	add_part(arm_l, tapered_path_mesh("vl_arm_l", PackedVector3Array([Vector3(-0.28, 1.40, 0.0),
		Vector3(-0.35, 1.12, -0.02), Vector3(-0.36, 0.86, 0.10)]), PackedFloat32Array([0.07, 0.058, 0.05])), bark,
		Vector3.ZERO)
	add_part(arm_l, cyl(0.066, 0.076, 0.16, 7), cdark, Vector3(-0.355, 0.97, 0.05), Vector3(-25, 0, 0))
	add_part(arm_l, sphere(0.065, 8, 4), bdark, Vector3(-0.36, 0.84, 0.11))
	# ---- Right arm: bark arm hanging out from the body (room for the coil), dark fist, the whip handle forward-down.
	add_part(arm_r, tapered_path_mesh("vl_arm_r", PackedVector3Array([Vector3(0.28, 1.40, 0.0), ELBOW_R,
		FIST + Vector3(0, 0.02, 0)]), PackedFloat32Array([0.075, 0.06, 0.052])), bark, Vector3.ZERO)
	add_part(arm_r, sphere(0.07, 8, 4), bdark, FIST)
	add_part(arm_r, cyl(0.034, 0.04, 0.28, 6), bdark, FIST + HANDLE_DIR * 0.13, Vector3(-60, 0, 0))
	# Keep_separate: the whip (mesh swapped per lash moment) and the pommel blossom (hidden until a lash lands).
	if _vl_frames.is_empty():
		_vl_frames.append(_coil_mesh())
		for c: PackedVector3Array in _lash_ctrl():
			_vl_frames.append(_whip_mesh("vl_lash_%d" % _vl_frames.size(), _spline(c, 3)))
	_whip = add_part(arm_r, _vl_frames[0], null, FIST, Vector3.ZERO, Vector3.ONE, true, "Whip")
	_blossom = add_part(arm_r, leaf_ring_mesh(6, 0.025, Vector3(0.09, 0.025, 0.13), 38.0), nature(&"nature_blossom"),
		FIST + HANDLE_DIR * 0.27, Vector3(-60, 0, 0), Vector3.ONE, true, "Blossom")
	_blossom.visible = false
	# ---- Fx
	add_hit_burst(Vector3(0, 1.2, 0.05), Color(0.46, 0.36, 0.20), 7)
	add_death_bloom(Vector3(0, 0.95, 0.1), 0.3, 8, 10, Color(0.55, 0.42, 0.24))
	ensure_shadow_blob(0.45)


# ================================================================ meshes (cached per type, model space unless said)

## Team loincloth: one leaf hanging in front, one behind (one mesh).
static func _loin_mesh() -> Mesh:
	var xs: Array[Transform3D] = [
		leaf_xform(Vector3(0, 0.97, 0.15), Vector3(0, 0, 1), Vector3(0.24, 0.04, 0.40), -72.0),
		leaf_xform(Vector3(0, 0.97, -0.14), Vector3(0, 0, -1), Vector3(0.22, 0.04, 0.36), -70.0),
	]
	return cluster_mesh("vl_loin", leaf_mesh(), xs)


## Left pauldron: a big pale bark-tan leaf plate over the left shoulder (the value accent that reads on dark grounds).
static func _pauldron_mesh() -> Mesh:
	var xs: Array[Transform3D] = [
		leaf_xform(Vector3(-0.20, 1.47, 0.02), Vector3(-1, 0, 0.15), Vector3(0.32, 0.05, 0.42), -28.0),
	]
	return cluster_mesh("vl_pauldron_top", leaf_mesh(), xs)


## Two team leaves under the pauldron plate, hanging front and back of the left shoulder.
static func _pauldron_leaves_mesh() -> Mesh:
	var xs: Array[Transform3D] = [
		leaf_xform(Vector3(-0.21, 1.42, 0.12), Vector3(-0.8, 0, 0.6), Vector3(0.24, 0.05, 0.34), -40.0),
		leaf_xform(Vector3(-0.21, 1.42, -0.10), Vector3(-0.8, 0, -0.6), Vector3(0.24, 0.05, 0.34), -40.0),
	]
	return cluster_mesh("vl_pauldron_leaves", leaf_mesh(), xs)


## Two team ribbons trailing back from the crown (one mesh).
static func _ribbons_mesh() -> Mesh:
	var xs: Array[Transform3D] = [
		leaf_xform(Vector3(-0.05, 1.76, -0.04), Vector3(-0.3, 0, -1), Vector3(0.13, 0.03, 0.34), 8.0),
		leaf_xform(Vector3(0.05, 1.76, -0.04), Vector3(0.3, 0, -1), Vector3(0.13, 0.03, 0.34), 14.0),
	]
	return cluster_mesh("vl_ribbons", leaf_mesh(), xs)


## Two slanted eye slits (a fierce "V" under the brow), sunk into the face (one mesh, model space).
static func _eyes_mesh() -> Mesh:
	const KEY := "vl_eyes"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		var b := Basis.from_euler(Vector3(-0.2, 0.35 * s, -0.38 * s))
		st.append_from(box(Vector3(0.075, 0.03, 0.05)), 0, Transform3D(b, Vector3(0.045 * s, 1.69, 0.145)))
	return _cached(KEY, _indexed(st))


## Swept-back crest: three thorn spikes over the crown (one mesh, model space).
static func _crest_mesh() -> Mesh:
	const KEY := "vl_crest"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var cone := cyl(0.0, 1.0, 1.0, 5)
	var defs: Array = [   # base, dir, length, radius
		[Vector3(0, 1.78, 0.06), Vector3(0, 0.75, -0.66), 0.30, 0.055],
		[Vector3(-0.07, 1.75, 0.03), Vector3(-0.35, 0.7, -0.62), 0.20, 0.042],
		[Vector3(0.07, 1.75, 0.03), Vector3(0.35, 0.7, -0.62), 0.20, 0.042],
	]
	for d: Array in defs:
		var dir := (d[1] as Vector3).normalized()
		var h: float = d[2]
		var r: float = d[3]
		var b := Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(r, h, r))
		st.append_from(cone, 0, Transform3D(b, (d[0] as Vector3) + dir * h * 0.45))
	return _cached(KEY, _indexed(st))


## The rest shape (whip-node space = model axes, origin at the fist): two horizontal loops climbing the forearm, then
## the tail rising outside the upper arm to over the shoulder, hooked forward like a poised snake.
static func _coil_mesh() -> Mesh:
	var u := (ELBOW_R - FIST).normalized()
	var e1 := Vector3.RIGHT
	e1 = (e1 - u * e1.dot(u)).normalized()
	var e2 := u.cross(e1)
	var pts := PackedVector3Array([Vector3.ZERO])
	const LOOPS := 2.0
	const N := 20
	const R := 0.17
	for i: int in N + 1:
		var s := float(i) / float(N)
		var a := TAU * LOOPS * s   # starts and ends on the outer side (+X): the tail rises clear of the arm
		var c := u * (0.04 + 0.21 * s)
		pts.append(c + (e1 * cos(a) + e2 * sin(a)) * R * (1.0 if i > 0 else 0.6))
	var tail := _spline(PackedVector3Array([pts[pts.size() - 1], Vector3(0.16, 0.42, -0.10), Vector3(0.10, 0.72, -0.15),
		Vector3(0.01, 0.95, -0.11), Vector3(-0.05, 1.05, 0.0), Vector3(-0.07, 1.06, 0.12), Vector3(-0.06, 0.99, 0.2)]), 3)
	for i: int in range(1, tail.size()):
		pts.append(tail[i])
	return _whip_mesh("vl_coil", pts)


## Control points of the 11 lash shapes (chest frame, origin at the fist; +Z forward, +Y up).
static func _lash_ctrl() -> Array[PackedVector3Array]:
	var out: Array[PackedVector3Array] = []
	# 1 uncoil: hanging from the rising fist, the tail on the ground behind
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(0.02, -0.35, -0.05), Vector3(0.05, -0.7, -0.15),
		Vector3(0.06, -0.95, -0.4), Vector3(0.05, -1.05, -0.8), Vector3(0.03, -1.1, -1.3), Vector3(0.0, -1.12, -1.9)]))
	# 2 wind: fist overhead, the vine trailing behind in a big arc
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.2, -0.35), Vector3(0.02, 0.15, -0.85),
		Vector3(0.04, -0.2, -1.3), Vector3(0.05, -0.75, -1.6), Vector3(0.05, -1.35, -1.6), Vector3(0.04, -1.8, -1.35)]))
	# 3 throw: the vine rolls up and over to the front
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.4, 0.05), Vector3(-0.02, 0.75, 0.25),
		Vector3(-0.04, 0.9, 0.65), Vector3(-0.06, 0.8, 1.1), Vector3(-0.08, 0.55, 1.55), Vector3(-0.1, 0.25, 1.95),
		Vector3(-0.12, -0.1, 2.3)]))
	# 4 crack: fully out, 3 m to the front, a little down
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(-0.03, -0.02, 0.5), Vector3(-0.07, -0.08, 1.0),
		Vector3(-0.1, -0.17, 1.5), Vector3(-0.14, -0.28, 2.0), Vector3(-0.18, -0.42, 2.5), Vector3(-0.22, -0.58, 2.95)]))
	# 5 drop: the vine falls to the ground in front
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(-0.03, -0.2, 0.5), Vector3(-0.07, -0.45, 1.0),
		Vector3(-0.1, -0.7, 1.5), Vector3(-0.13, -0.92, 2.0), Vector3(-0.16, -1.04, 2.5), Vector3(-0.18, -1.08, 2.9)]))
	# 6 pull: dragged back along the ground in an S
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(0.0, -0.45, 0.25), Vector3(0.06, -0.85, 0.55),
		Vector3(0.18, -1.0, 0.95), Vector3(0.1, -1.02, 1.4), Vector3(-0.12, -1.03, 1.8), Vector3(-0.3, -1.04, 2.1)]))
	# 7 gather: a loose loop beside the arm, the tail rising to coil again
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(0.12, -0.22, 0.18), Vector3(0.32, -0.3, 0.05),
		Vector3(0.36, -0.2, -0.2), Vector3(0.2, -0.05, -0.32), Vector3(0.02, 0.1, -0.2), Vector3(0.06, 0.35, 0.0),
		Vector3(0.08, 0.6, -0.06), Vector3(0.02, 0.82, 0.05)]))
	# 8 cast trail: the arm back low, the vine trailing behind-right on the ground
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(0.05, -0.4, -0.1), Vector3(0.2, -0.72, -0.3),
		Vector3(0.45, -0.86, -0.6), Vector3(0.7, -0.9, -1.0), Vector3(0.85, -0.92, -1.5), Vector3(0.9, -0.93, -2.0)]))
	# 9 cast sweep: a low wide arc from the right to the front
	out.append(PackedVector3Array([Vector3.ZERO, Vector3(0.25, -0.2, 0.25), Vector3(0.6, -0.42, 0.6),
		Vector3(0.9, -0.6, 1.1), Vector3(1.0, -0.7, 1.7), Vector3(0.85, -0.78, 2.3), Vector3(0.5, -0.82, 2.8)]))
	# 10 snare: out to the front, the end wound into a ring (the snare) around the target
	out.append(_with_loop(PackedVector3Array([Vector3.ZERO, Vector3(-0.02, -0.1, 0.6), Vector3(-0.05, -0.22, 1.2),
		Vector3(-0.08, -0.34, 1.8)]), Vector3(-0.1, -0.46, 2.55), 0.32))
	# 11 yank: taut, the snare pulled tight
	out.append(_with_loop(PackedVector3Array([Vector3.ZERO, Vector3(-0.02, -0.07, 0.6), Vector3(-0.04, -0.15, 1.2),
		Vector3(-0.06, -0.23, 1.8)]), Vector3(-0.07, -0.3, 2.4), 0.17))
	return out


## Line + one horizontal loop of radius r around `centre` (entering from the fist side), 1.1 turns.
static func _with_loop(line: PackedVector3Array, centre: Vector3, r: float) -> PackedVector3Array:
	var out := line.duplicate()
	for k: int in 10:
		var a := TAU * 1.1 * float(k) / 9.0
		out.append(centre + Vector3(r * sin(a), -0.02 * a, -r * cos(a)))
	return out


## Catmull-Rom through the control points, `per` samples per span.
static func _spline(c: PackedVector3Array, per: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var n := c.size()
	for i: int in n - 1:
		var p0 := c[maxi(i - 1, 0)]
		var p1 := c[i]
		var p2 := c[i + 1]
		var p3 := c[mini(i + 2, n - 1)]
		for j: int in per:
			var t := float(j) / float(per)
			out.append(0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	out.append(c[n - 1])
	return out


## The vine along `pts`: a tapered 5-sided tube (russet vine), thorns (tan) and the glowing bud at the end,
## ONE cached mesh with 3 surfaces (materials on the mesh: the node has no material_override).
static func _whip_mesh(key: String, pts: PackedVector3Array) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	const SIDES := 5
	var n := pts.size()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	var tans := PackedVector3Array()
	var nrms := PackedVector3Array()
	var t0 := (pts[1] - pts[0]).normalized()
	var nrm := (Vector3.UP if absf(t0.y) < 0.9 else Vector3.RIGHT).cross(t0).normalized()
	for i: int in n:
		var t: Vector3
		if i == 0:
			t = t0
		elif i == n - 1:
			t = (pts[n - 1] - pts[n - 2]).normalized()
		else:
			t = (pts[i + 1] - pts[i - 1]).normalized()
		nrm = (nrm - t * nrm.dot(t)).normalized()   # parallel transport: no twist along the vine
		var bin := t.cross(nrm)
		tans.append(t)
		nrms.append(nrm)
		var r := lerpf(VINE_R0, VINE_R1, float(i) / float(n - 1))
		for k: int in SIDES:
			var a := TAU * float(k) / float(SIDES)
			var d := nrm * cos(a) + bin * sin(a)
			verts.append(pts[i] + d * r)
			norms.append(d)
	for i: int in n - 1:
		for k: int in SIDES:
			var a0 := i * SIDES + k
			var b0 := i * SIDES + (k + 1) % SIDES
			var c0 := a0 + SIDES
			var d0 := b0 + SIDES
			idx.append_array(PackedInt32Array([a0, c0, b0, b0, c0, d0]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Thorns: every 2nd point, spiralling around the vine, raked toward the tip.
	var st := SurfaceTool.new()
	var cone := cyl(0.0, 1.0, 1.0, 4)
	var phi: float = 0.0
	for i: int in range(2, n - 2, 3):
		phi += 2.1
		var t: Vector3 = tans[i]
		var nr: Vector3 = nrms[i]
		var d := nr * cos(phi) + t.cross(nr) * sin(phi)
		var dir := (d + t * 0.55).normalized()
		var r := lerpf(VINE_R0, VINE_R1, float(i) / float(n - 1))
		var b := Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(0.026, 0.11, 0.026))
		st.append_from(cone, 0, Transform3D(b, pts[i] + d * r * 0.6 + dir * 0.05))
	st.index()
	st.commit(am)
	# Glowing bud at the end, stretched along the last direction.
	var st2 := SurfaceTool.new()
	var tl: Vector3 = tans[n - 1]
	var bb := Basis(Quaternion(Vector3.UP, tl)).scaled_local(Vector3(0.95, 1.5, 0.95))
	st2.append_from(sphere(0.065, 8, 4), 0, Transform3D(bb, pts[n - 1] + tl * 0.05))
	st2.index()
	st2.commit(am)
	am.surface_set_material(0, nature(&"nature_hair"))
	am.surface_set_material(1, nature(&"nature_thorn"))
	am.surface_set_material(2, nature(&"nature_glow"))
	return _cached(key, am)


## Frame index of a [t_start, frame, ...] timeline at time t.
static func _frame_at(t: float, tl: PackedFloat32Array) -> int:
	var f: int = int(tl[1])
	var i: int = 0
	while i < tl.size() and t >= tl[i]:
		f = int(tl[i + 1])
		i += 2
	return f


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"vine_lash":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, L_ARM_R) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_kf(t, L_ARM_L) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, L_CHEST_X) * DEG, _kf(t, L_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, L_ROOT_Y), _kf(t, L_ROOT_Z)))
	if _tier == 0:
		rot(P_HEAD, Vector3(_kf(t, L_HEAD_X) * DEG, 0, 0))
		rot(P_LEG_L, Vector3(_kf(t, L_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_kf(t, L_LEG_R) * DEG, 0, 0))
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Snare Lash (and any other spell id): low sidearm sweep, the snare ring, a yank back.
func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ARM_R, Vector3(_kf(t, C_ARM_R) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_kf(t, C_ARM_L) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, C_CHEST_X) * DEG, _kf(t, C_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, C_ROOT_Y), _kf(t, C_ROOT_Z)))
	if _tier == 0:
		rot(P_LEG_L, Vector3(_kf(t, C_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_kf(t, C_LEG_R) * DEG, 0, 0))
	return CAST_LEN


## Stalking walk: a slight forward lean, the whip arm held steadier than the free arm.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_CHEST, Vector3(6.0 * DEG * w, 0, 0))
	rot(P_ARM_R, Vector3(-4.0 * DEG * s * w, 0, 0))


## Fidget: lifts the coiled forearm and looks at the vine, then shakes it loose.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.35, 1.0, 1.5, 1.0, 1.0)
	var shake: float = 0.0
	if t > 0.9 and t < 1.3:
		shake = sin((t - 0.9) * TAU * 3.0)
	rot(P_ARM_R, Vector3(-38.0 * DEG * up, 0, 10.0 * DEG * shake * up))
	rot(P_HEAD, Vector3(12.0 * DEG * up, 24.0 * DEG * up, 0))
	rot(P_CHEST, Vector3(0, 10.0 * DEG * up, 0))
	return 1.5


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_bloom_t = 0.0


func _war_process(dt: float) -> void:
	if _whip == null:
		return
	var f: int = 0
	if not _dead:
		if _action == &"attack" and attack_style == &"vine_lash":
			f = _frame_at(_action_t, ATK_FRAMES)
		elif _action == &"cast":
			f = _frame_at(_action_t, CAST_FRAMES)
			if _action_t >= CAST_BLOOM and _action_t - dt < CAST_BLOOM:
				_bloom_t = 0.0
	if f != _whip_f:
		_whip_f = f
		_whip.mesh = _vl_frames[f]
	if f != 0:
		_whip.rotation = Vector3(-_off_rot[P_ARM_R].x, 0, 0)   # lash shapes are authored in the chest frame
		_whip_turned = true
	elif _whip_turned:
		_whip.rotation = Vector3.ZERO
		_whip_turned = false
	# Pommel blossom: opens fast on the crack, holds, closes.
	var s: float = 0.0
	if _bloom_t < BLOOM_LEN and not _dead:
		_bloom_t += dt
		s = _k3(_bloom_t, 0.0, 0.08, 0.3, BLOOM_LEN, 1.0, 1.0)
	s = snappedf(s, 0.02)
	if s != _bloom_s:
		_bloom_s = s
		_blossom.visible = s > 0.0
		if s > 0.0:
			_blossom.scale = Vector3.ONE * (0.25 + 0.75 * s)


func _war_revive() -> void:
	_whip_f = 0
	if _whip:
		_whip.mesh = _vl_frames[0]
		_whip.rotation = Vector3.ZERO
	_whip_turned = false
	_bloom_t = 99.0
	_bloom_s = 0.0
	if _blossom:
		_blossom.visible = false
