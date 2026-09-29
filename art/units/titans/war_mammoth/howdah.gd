class_name MammothHowdahModel
extends CharacterModel
## War Mammoth howdah + frost archer (cavalry-mounts.md 10, task 13.V17). A child scene of war_mammoth.tscn (instanced
## on the mammoth's Seat marker, meta keep_separate so the mammoth's merge leaves it alone); also works standalone.
## Origin = the seat point on the mammoth's blanket (+Z forward). Look: a timber box on four stilts that stand on two
## arched cradle ribs hugging the mammoth's back; corner posts and rails of timber, walls of deep-blue ice slabs, ice
## crystal finials, a team-cloth valance around the floor, a quiver of ice arrows on the right wall, and the TEAM
## BANNER on a tall pole at the rear-left corner. Inside, a kneeling hooded frost archer (team hood and tunic, a pale
## fur mantle, a face in shadow with a glowing eye slit, a crystal pauldron, a back quiver) holds a tall recurve bow
## with ice-capped limbs and an ice arrow with a glowing head, torso turned side-on (left shoulder forward).
## Pivots (kit): Root (the archer's floor point: turns to aim), Root/Chest (+ pitch to aim up at flyers), Chest/Head,
## Chest/ArmL (the bow arm), Chest/ArmR (the draw arm). No legs (hidden by the walls). The frame is one static mesh
## ("Frame", not a pivot). Two bow-string halves (StringU / StringL, ArmL children) follow the draw hand.
## Hooks: play_howdah_shot(target = null) (target Node3D / world Vector3 / null; the archer turns (+-150 deg) and pitches
## (-30..+20 deg) to it, draws, releases at RELEASE 0.12 s (the arrow leaves the hand), reaches back to the quiver and
## nocks a new arrow; 1.05 s), play_attack() (= play_howdah_shot()), get_muzzle() -> Vector3 (world point of the arrow
## tip), set_team_color(c) (banner, valance, hood, tunic), play_hit(), play_death() (slumps over the rail, glows off;
## death_finished), revive(), set_status(), the kit's other hooks. Signal shot_released(at: Vector3) at the release.
## Budget: 5 authored meshes (Frame, Chest, Head, ArmL, ArmR) + 2 string nodes = 7 draw instances, 0 lights, 0 particles.

signal shot_released(at: Vector3)

const ICE := "res://art/units/ice/materials/"
const RELEASE := 0.12
const SHOT_LEN := 1.05
## The archer's torso is turned side-on by this yaw (deg): left shoulder forward toward the target.
const TORSO_YAW := 30.0
## The archer's vertical axis (x, z) in model space; the floor top.
const AXIS := Vector3(0.0, 0.0, -0.10)
const FLOOR_Y := 0.29
## Bow (in the plane x = BOW_X): grip, string rest (nock), limb tips.
const BOW_X := -0.14
const GRIP := Vector3(-0.14, 1.18, 0.52)
const NOCK := Vector3(-0.12, 1.18, 0.37)
const TIP_U := Vector3(-0.14, 1.80, 0.40)
const TIP_D := Vector3(-0.14, 0.56, 0.40)
## The draw hand at rest (on the nock) and the arrow (nock end -> glowing tip).
const HAND_R := Vector3(-0.10, 1.18, 0.35)
const ARROW_NOCK := Vector3(-0.12, 1.18, 0.33)
const ARROW_TIP := Vector3(-0.12, 1.18, 1.15)
## ArmR offset at full draw (chest space): back along the arrow, a little up / out.
const DRAW_VEC := Vector3(0.10, 0.05, -0.34)
const AIM_TURN := 7.0
const AIM_PITCH_TURN := 4.0
const AIM_HOLD := 1.8
const YAW_MAX := 2.6

# Shot tracks [t, value, ease, ...] (MountModel._mkf): draw (1 = full), reach to the back quiver (1 = hand at it),
# chest yaw (deg, turning side-on at the draw), bow arm recoil (deg), head tilt along the arrow (deg).
static var S_DRAW := PackedFloat32Array([0.0, 0.0, 0, 0.10, 1.0, 1, 0.13, 1.08, 1, 0.24, 1.12, 0, 0.40, 0.55, 0, 0.60, 0.0, 0, 1.05, 0.0, 0])
static var S_REACH := PackedFloat32Array([0.0, 0.0, 0, 0.30, 0.0, 0, 0.50, 1.0, 0, 0.62, 1.0, 0, 0.92, 0.0, 0, 1.05, 0.0, 0])
static var S_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.10, 12.0, 1, 0.30, 10.0, 0, 0.60, 0.0, 0, 1.05, 0.0, 0])
static var S_BOW_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -4.0, 1, 0.15, 4.0, 2, 0.30, -2.0, 0, 0.60, 0.0, 0, 1.05, 0.0, 0])
static var S_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, 6.0, 1, 0.40, 4.0, 0, 0.80, 0.0, 0, 1.05, 0.0, 0])
# Idle scan (look around), every ~SCAN_EVERY s within 30 m.
const SCAN_EVERY := 7.0

static var _frame_cache: Dictionary = {}   # type key -> Mesh
static var _arrow_cache: Dictionary = {}   # type key -> Mesh (ArmR + the nocked arrow)
static var _mats: Dictionary = {}

var _frame: MeshInstance3D
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig
var _arm_r_mi: MeshInstance3D
var _mesh_plain: Mesh
var _mesh_arrow: Mesh
var _arrow_on: bool = true
var _strings: Array[MeshInstance3D] = []
var _string_last: Vector3 = Vector3(INF, 0, 0)
var _o_l: Vector3 = Vector3.ZERO
var _o_r: Vector3 = Vector3.ZERO
var _aim_yaw: float = 0.0
var _aim_pitch: float = 0.0
var _yaw_goal: float = 0.0
var _pitch_goal: float = 0.0
var _aim_left: float = 0.0
var _shot_t: float = 99.0
var _flare: float = 0.0
var _tip_written: float = -1.0
var _scan_wait: float = 0.0


static func m(name: String) -> Material:
	if not _mats.has(name):
		_mats[name] = load(ICE + name + ".tres")
	return _mats[name]


## Rotates a model point around the archer's axis by the torso yaw (the side-on stance).
static func _tw(p: Vector3) -> Vector3:
	var a := deg_to_rad(TORSO_YAW)
	var x := p.x - AXIS.x
	var z := p.z - AXIS.z
	return Vector3(AXIS.x + x * cos(a) + z * sin(a), p.y, AXIS.z - x * sin(a) + z * cos(a))


## One authored part per pivot: a multi-material sculpt (MountModel's static builders), built for the first instance.
func _sculpt_part(pivot: Node3D, build: Callable) -> void:
	if pivot == null or _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return
	var s := MountModel.sculpt()
	build.call(s)
	var mesh := MountModel.sculpt_mesh(s)
	if mesh:
		add_part(pivot, mesh, null, Vector3.ZERO)


# ================================================================ parts

func _build_parts() -> void:
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	_o_l = model_origin(arm_l)
	_o_r = model_origin(arm_r)
	_sculpt_part(chest, _chest_sculpt)
	_sculpt_part(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "howdah_archer", face_spec())
	_sculpt_part(arm_l, _arm_l_sculpt)
	_sculpt_part(arm_r, _arm_r_sculpt)
	# The static howdah frame: one mesh, cached per type, not a pivot (never animated by the kit).
	_frame = MeshInstance3D.new()
	_frame.name = "Frame"
	_frame.mesh = _frame_mesh()
	_frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_frame)
	move_child(_frame, 0)
	# Bow string: two thin halves from the nock to the limb tips (unit tube along +Y, placed by _write_strings).
	var smesh := MountModel.tube_mesh("howdah_string_v1", PackedVector3Array([Vector3.ZERO, Vector3.UP]),
		PackedFloat32Array([0.010, 0.010]), 4, false)
	for k: int in 2:
		var st := add_part(arm_l, smesh, m("ice_hair"), NOCK, Vector3.ZERO, Vector3.ONE, true, "StringU" if k == 0 else "StringL")
		_strings.append(st)


func _frame_mesh() -> Mesh:
	if _frame_cache.has(_type_key):
		return _frame_cache[_type_key]
	var s := MountModel.sculpt()
	_frame_sculpt(s)
	var mesh := MountModel.sculpt_mesh(s)
	_frame_cache[_type_key] = mesh
	return mesh


func _frame_sculpt(s: Dictionary) -> void:
	var wood := m("ice_wood")
	var dark := m("ice_stone_dark")
	var slab := m("ice_frost_deep")
	var ice := m("ice_frost_crystal")
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var leather := m("ice_leather")
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var banner := m("ice_cape")
	var pale := m("ice_fur_pale")
	# ---- cradle: two arched ribs hugging the mammoth's back (its barrel centre is 1.11 m below the seat), stilts up
	# to the floor, steel shoes
	for rib: Array in [[0.45, 1.03, 1.15], [-0.50, 0.88, 0.98]]:
		var z: float = rib[0]
		MountModel.sculpt_add(s, MountModel.shell_mesh("howdah_rib_%s" % z, rib[1], rib[2], -64.0, 64.0, -0.07, 0.07, 0.10, 10, 1),
			Transform3D(Basis.IDENTITY, Vector3(0, -1.11, z)), wood)
		for sx: float in [-1.0, 1.0]:
			var a := asin(0.55 / float(rib[1]))
			var y0: float = -1.11 + float(rib[2]) * cos(a)
			var h: float = 0.19 - y0 + 0.02
			MountModel.sculpt_put(s, box(Vector3(0.13, h, 0.13)), wood, Vector3(0.55 * sx, y0 + h * 0.5 - 0.02, z))
			MountModel.sculpt_put(s, box(Vector3(0.17, 0.06, 0.17)), steel, Vector3(0.55 * sx, 0.16, z))
			MountModel.sculpt_put(s, box(Vector3(0.16, 0.05, 0.16)), steel, Vector3(0.55 * sx, y0 + 0.02, z))
		# cross brace between the stilts
		MountModel.sculpt_put(s, box(Vector3(1.10, 0.08, 0.08)), wood, Vector3(0, 0.12, z))
	# ---- floor (planks with dark seams)
	MountModel.sculpt_put(s, box(Vector3(1.56, 0.10, 1.46)), wood, Vector3(0, 0.24, -0.02))
	for x: float in [-0.47, -0.16, 0.16, 0.47]:
		MountModel.sculpt_put(s, box(Vector3(0.025, 0.012, 1.40)), dark, Vector3(x, 0.295, -0.02))
	# ---- team valance hanging from the floor edges, a dark hem and steel studs
	for side: Array in [[Vector3(0, 0.12, 0.745), Vector3(1.58, 0.26, 0.025)], [Vector3(0, 0.12, -0.785), Vector3(1.58, 0.26, 0.025)],
			[Vector3(0.795, 0.12, -0.02), Vector3(0.025, 0.26, 1.50)], [Vector3(-0.795, 0.12, -0.02), Vector3(0.025, 0.26, 1.50)]]:
		var c: Vector3 = side[0]
		var sz: Vector3 = side[1]
		MountModel.sculpt_put(s, box(sz), cloth, c)
		MountModel.sculpt_put(s, box(Vector3(sz.x + 0.01, 0.06, sz.z + 0.01)), cdark, c - Vector3(0, 0.12, 0))
	# ---- parapet: corner posts, side mid posts, rails, walls of deep ice slabs (front lower for the shot)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var pc := Vector3(0.74 * sx, 0.68, 0.69 * sz - 0.02)
			MountModel.sculpt_put(s, box(Vector3(0.14, 0.80, 0.14)), wood, pc)
			MountModel.sculpt_put(s, box(Vector3(0.18, 0.06, 0.18)), steel, pc + Vector3(0, 0.41, 0))
			MountModel.sculpt_put(s, box(Vector3(0.17, 0.05, 0.17)), steel, pc + Vector3(0, -0.28, 0))
			# ice finial: the front ones lean forward-out, the back ones up-out
			var d := Vector3(0.45 * sx, 1.0, 0.55 * sz).normalized()
			MountModel.sculpt_crystal(s, ice, pc + Vector3(0, 0.42, 0), d, 0.09, 0.46 if sz > 0.0 else 0.36, 0.5, 15.0 * sx)
		MountModel.sculpt_put(s, box(Vector3(0.12, 0.66, 0.12)), wood, Vector3(0.74 * sx, 0.62, -0.02))
		MountModel.sculpt_put(s, box(Vector3(0.10, 0.09, 1.46)), wood, Vector3(0.74 * sx, 0.97, -0.02))
		MountModel.sculpt_put(s, box(Vector3(0.10, 0.07, 1.46)), wood, Vector3(0.74 * sx, 0.33, -0.02))
		MountModel.sculpt_put(s, box(Vector3(0.06, 0.58, 1.30)), slab, Vector3(0.74 * sx, 0.64, -0.02))
	MountModel.sculpt_put(s, box(Vector3(1.46, 0.09, 0.10)), wood, Vector3(0, 0.97, -0.71))
	MountModel.sculpt_put(s, box(Vector3(1.46, 0.07, 0.10)), wood, Vector3(0, 0.33, -0.71))
	MountModel.sculpt_put(s, box(Vector3(1.30, 0.58, 0.06)), slab, Vector3(0, 0.64, -0.71))
	MountModel.sculpt_put(s, box(Vector3(0.12, 0.66, 0.12)), wood, Vector3(0, 0.62, -0.71))
	MountModel.sculpt_put(s, box(Vector3(1.46, 0.09, 0.10)), wood, Vector3(0, 0.74, 0.67))
	MountModel.sculpt_put(s, box(Vector3(1.46, 0.07, 0.10)), wood, Vector3(0, 0.33, 0.67))
	MountModel.sculpt_put(s, box(Vector3(1.30, 0.36, 0.06)), slab, Vector3(0, 0.53, 0.67))
	# a steel boss with an ice crystal on the front wall (the prow)
	MountModel.sculpt_put(s, sphere(0.10, 8, 4), metal, Vector3(0, 0.55, 0.72), Vector3.ZERO, Vector3(1.0, 1.0, 0.5))
	MountModel.sculpt_crystal(s, ice, Vector3(0, 0.55, 0.74), Vector3(0, 0.25, 1.0), 0.06, 0.22, 0.5)
	# ---- quiver of ice arrows on the right wall (outside)
	var qc := Vector3(0.83, 0.64, 0.22)
	MountModel.sculpt_put(s, cyl(0.10, 0.09, 0.56, 8), leather, qc, Vector3(0, 0, -10))
	MountModel.sculpt_put(s, torus(0.085, 0.12, 12), steel, qc + Vector3(0.05, 0.25, 0), Vector3(0, 0, -10))
	for k: int in 4:
		var off := Vector3(0.04 * float(k % 2) - 0.02, 0.0, 0.05 * float(k) - 0.075)
		MountModel.sculpt_crystal(s, ice, qc + off + Vector3(0.05, 0.26, 0), Vector3(0.18, 1.0, 0.0), 0.028, 0.20, 0.55)
		MountModel.sculpt_put(s, box(Vector3(0.012, 0.08, 0.05)), pale, qc + off + Vector3(0.02, 0.22, 0), Vector3(0, 0, -10))
	# ---- the team banner: a tall pole at the rear-left corner, crossbar, a hanging swallow-tail banner (banner shader)
	var pole := Vector3(-0.84, 0.0, -0.84)
	MountModel.sculpt_put(s, cyl(0.04, 0.05, 2.06, 8), wood, pole + Vector3(0, 0.93, 0))
	MountModel.sculpt_put(s, box(Vector3(0.12, 0.05, 0.12)), steel, pole + Vector3(0, 0.40, 0))
	MountModel.sculpt_put(s, box(Vector3(0.12, 0.05, 0.12)), steel, pole + Vector3(0, 0.95, 0))
	MountModel.sculpt_put(s, cyl(0.026, 0.026, 0.74, 6), wood, pole + Vector3(0.33, 1.86, 0), Vector3(0, 0, 90))
	MountModel.sculpt_crystal(s, ice, pole + Vector3(0, 1.94, 0), Vector3.UP, 0.07, 0.30, 0.55)
	for ex: float in [0.0, 0.70]:
		MountModel.sculpt_put(s, sphere(0.045, 6, 3), steel, pole + Vector3(ex, 1.86, 0))
	MountModel.sculpt_put(s, cape(0.64, 0.98), banner, pole + Vector3(0.36, 1.37, 0))


# ================================================================ archer

func _chest_sculpt(s: Dictionary) -> void:
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var pale := m("ice_fur_pale")
	var leather := m("ice_leather")
	var ice := m("ice_frost_crystal")
	var metal := m("ice_metal")
	var yaw := Vector3(0, TORSO_YAW, 0)
	var c := AXIS
	# kneeling coat skirt, tunic (team), belt with a silver buckle, bandolier
	MountModel.sculpt_put(s, cyl(0.25, 0.36, 0.46, 10), cdark, Vector3(c.x, 0.52, c.z), yaw)
	MountModel.sculpt_put(s, cyl(0.25, 0.21, 0.46, 10), cloth, Vector3(c.x, 0.95, c.z), yaw, Vector3(1.0, 1.0, 0.86))
	MountModel.sculpt_put(s, cyl(0.225, 0.225, 0.07, 10), leather, Vector3(c.x, 0.77, c.z), yaw, Vector3(1.0, 1.0, 0.86))
	MountModel.sculpt_put(s, box(Vector3(0.09, 0.08, 0.03)), metal, _tw(Vector3(0.0, 0.77, c.z + 0.20)), yaw)
	MountModel.sculpt_put(s, box(Vector3(0.07, 0.56, 0.03)), leather, _tw(Vector3(0.02, 0.98, c.z + 0.19)), yaw + Vector3(0, 0, 38))
	# pale fur mantle over the shoulders
	MountModel.sculpt_fringe(s, pale, MountModel.fringe_mesh("howdah_mantle_v1", 0.16, 0.14, 0.33, 0.28, 0.14, 0.0, 360.0, 11,
		0.08, 0.03, 0.5), Vector3(c.x, 1.24, c.z), Basis.from_euler(yaw * DEG))
	# crystal pauldron on the (forward) left shoulder
	var sh := _tw(Vector3(-0.23, 1.16, c.z))
	MountModel.sculpt_put(s, sphere(0.12, 8, 4), ice, sh, yaw, Vector3(1.0, 0.72, 1.12))
	MountModel.sculpt_crystal(s, ice, sh + Vector3(-0.04, 0.05, 0), Vector3(-0.6, 1.0, 0.1), 0.04, 0.18, 0.55)
	MountModel.sculpt_crystal(s, ice, sh + Vector3(-0.02, 0.05, 0.06), Vector3(-0.3, 1.0, 0.5), 0.035, 0.14, 0.55)
	# back quiver with three ice arrows
	var q := _tw(Vector3(0.10, 1.05, c.z - 0.24))
	MountModel.sculpt_put(s, cyl(0.075, 0.065, 0.52, 8), leather, q, Vector3(0, 0, -24))
	for k: int in 3:
		var off := Vector3(0.03 * float(k) - 0.03, 0.0, 0.03 * float(k % 2))
		MountModel.sculpt_crystal(s, ice, q + off + Vector3(0.10, 0.23, 0), Vector3(0.42, 1.0, 0.0), 0.025, 0.18, 0.55)


func _head_sculpt(s: Dictionary) -> void:
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var pale := m("ice_fur_pale")
	var shade := m("ice_fur")
	var c := AXIS
	# face in the hood's shadow (its two glowing eyes: the archer's CreatureFaceRig, faces pass 2026-09-28: was a glowing
	# eye slit), scarf, deep team hood with a long point hanging back, fur rim
	MountModel.sculpt_put(s, sphere(0.12, 10, 5), shade, Vector3(c.x, 1.31, c.z + 0.04))
	MountModel.sculpt_put(s, cyl(0.12, 0.14, 0.10, 8), cdark, Vector3(c.x, 1.22, c.z + 0.02))
	MountModel.sculpt_put(s, sphere(0.175, 10, 5), cloth, Vector3(c.x, 1.35, c.z - 0.02), Vector3.ZERO, Vector3(1.0, 1.06, 1.08))
	MountModel.sculpt_put(s, cyl(0.0, 0.14, 0.40, 8), cloth, Vector3(c.x, 1.49, c.z - 0.20), Vector3(-48, 0, 0))
	MountModel.sculpt_put(s, torus(0.10, 0.155, 14), pale, Vector3(c.x, 1.33, c.z + 0.10), Vector3(78, 0, 0))


func _arm_l_sculpt(s: Dictionary) -> void:
	var cdark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	var wood := m("ice_wood")
	var ice := m("ice_frost_crystal")
	var pale := m("ice_fur_pale")
	var sh := _o_l
	var hand := GRIP + Vector3(0, 0, -0.02)
	# straight bow arm: sleeve, bracer, gloved fist on the grip
	_limb(s, sh, hand, 0.062, cdark)
	var d := (hand - sh).normalized()
	MountModel.sculpt_add(s, cyl(0.07, 0.075, 0.18, 8), Transform3D(Basis(Quaternion(Vector3.UP, d)), sh.lerp(hand, 0.72)), leather)
	MountModel.sculpt_put(s, sphere(0.068, 8, 4), leather, hand)
	# recurve bow in the plane x = BOW_X: limbs bend back toward the archer, the tips flick forward; ice-capped tips
	var pts := PackedVector3Array()
	for p: Vector2 in [Vector2(0.56, 0.40), Vector2(0.64, 0.36), Vector2(0.80, 0.40), Vector2(0.98, 0.48), Vector2(1.18, 0.53),
			Vector2(1.38, 0.48), Vector2(1.56, 0.40), Vector2(1.72, 0.36), Vector2(1.80, 0.40)]:
		pts.append(Vector3(BOW_X, p.x, p.y))
	MountModel.sculpt_add(s, MountModel.tube_mesh("howdah_bow_v1", pts, PackedFloat32Array([0.018, 0.028, 0.038, 0.044, 0.05,
		0.044, 0.038, 0.028, 0.018]), 6, true, 0.7), Transform3D.IDENTITY, wood)
	MountModel.sculpt_put(s, cyl(0.058, 0.058, 0.16, 8), leather, GRIP)
	for k: int in 2:
		var tip: Vector3 = TIP_U if k == 0 else TIP_D
		var inner: Vector3 = Vector3(BOW_X, 1.72, 0.36) if k == 0 else Vector3(BOW_X, 0.64, 0.36)
		var td := (tip - inner).normalized()
		MountModel.sculpt_crystal(s, ice, inner, (td + Vector3(0, 0.6 * (1.0 if k == 0 else -1.0), 0)).normalized(), 0.045, 0.22, 0.5)
		MountModel.sculpt_put(s, box(Vector3(0.012, 0.10, 0.04)), pale, inner.lerp(tip, 0.5) + Vector3(0, 0, -0.03))


func _arm_r_sculpt(s: Dictionary) -> void:
	var cdark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	var sh := _o_r
	var elbow := Vector3(0.24, 1.08, 0.12)
	_limb(s, sh, elbow, 0.064, cdark)
	_limb(s, elbow, HAND_R, 0.058, cdark)
	var d := (HAND_R - elbow).normalized()
	MountModel.sculpt_add(s, cyl(0.065, 0.07, 0.16, 8), Transform3D(Basis(Quaternion(Vector3.UP, d)), elbow.lerp(HAND_R, 0.55)), leather)
	MountModel.sculpt_put(s, sphere(0.062, 8, 4), leather, HAND_R)


## The nocked ice arrow (merged into a variant of ArmR's mesh: shown / hidden by a mesh swap, 0 draw instances).
func _arrow_sculpt(s: Dictionary) -> void:
	var wood := m("ice_wood")
	var pale := m("ice_fur_pale")
	var ice := m("ice_frost_crystal")
	var glow := m("ice_glow_unit")
	var d := (ARROW_TIP - ARROW_NOCK).normalized()
	var len: float = (ARROW_TIP - ARROW_NOCK).length()
	var b := Basis(Quaternion(Vector3.UP, d))
	MountModel.sculpt_add(s, cyl(0.014, 0.014, len - 0.12, 6), Transform3D(b, ARROW_NOCK + d * (len - 0.12) * 0.5), wood)
	for k: int in 3:
		var fb := b * Basis(Vector3.UP, TAU * float(k) / 3.0)
		MountModel.sculpt_add(s, box(Vector3(0.006, 0.12, 0.05)), Transform3D(fb, ARROW_NOCK + d * 0.08 + fb * Vector3(0, 0, 0.03)), pale)
	MountModel.sculpt_add(s, cyl(0.032, 0.02, 0.05, 6), Transform3D(b, ARROW_TIP - d * 0.14), ice)
	MountModel.sculpt_add(s, cyl(0.0, 0.045, 0.16, 6), Transform3D(b, ARROW_TIP - d * 0.06), glow)


func _limb(s: Dictionary, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d := b - a
	MountModel.sculpt_add(s, capsule(r, d.length() + r), Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d * 0.5), mat)


# ================================================================ lifecycle

func _after_ready() -> void:
	if _frame and not _flash_hit_targets.has(_frame):
		_flash_hit_targets.append(_frame)
	_arm_r_mi = _merged_nodes.get(P_ARM_R)
	if _face:
		_face.set_host(_merged_nodes.get(P_HEAD))
	if _arm_r_mi:
		_mesh_plain = _arm_r_mi.mesh
		_mesh_arrow = _arrow_variant()
		_show_arrow(true)
	for st: MeshInstance3D in _strings:
		if not _flash_hit_targets.has(st):
			_flash_hit_targets.append(st)
	_string_last = Vector3(INF, 0, 0)
	_write_strings(NOCK - _o_l)
	_scan_wait = SCAN_EVERY * (0.5 + float(hash(get_instance_id()) % 100) / 100.0)


func _arrow_variant() -> Mesh:
	if _arrow_cache.has(_type_key):
		return _arrow_cache[_type_key]
	var s := MountModel.sculpt()
	_arrow_sculpt(s)
	var am := MountModel.sculpt_mesh(s)
	var mesh: Mesh = _merge_items([[_mesh_plain, Transform3D.IDENTITY, []], [am, Transform3D(Basis.IDENTITY, -_o_r), []]])
	_arrow_cache[_type_key] = mesh
	return mesh


func _show_arrow(on: bool) -> void:
	_arrow_on = on
	if _arm_r_mi and _mesh_arrow:
		_arm_r_mi.mesh = _mesh_arrow if on else _mesh_plain
		_tip_written = -1.0


## Whether the archer holds an arrow right now (released at the shot, a new one nocked from the quiver).
func has_arrow() -> bool:
	return _arrow_on


# ================================================================ hooks

## The archer's shot. target: Node3D (aims at its body), world Vector3, or null (ahead). Release at RELEASE (0.12 s):
## signal shot_released(world arrow tip), the arrow leaves the hand; then the archer reaches back to his quiver and
## nocks a new arrow (SHOT_LEN 1.05 s). Calls while dead or before _ready are ignored.
func play_howdah_shot(target: Variant = null) -> void:
	if _dead or not _ready_done:
		return
	_aim_at(target)
	_shot_t = 0.0
	_action = &"shot"   # private action id: the kit only advances _action_t, the pose is written here
	_action_t = 0.0
	_show_arrow(true)
	set_process(true)


func play_attack() -> void:
	play_howdah_shot(null)


## World position of the nocked arrow's tip (where a howdah bolt VFX starts).
func get_muzzle() -> Vector3:
	var arm: Node3D = _piv[P_ARM_R] if _piv.size() > P_ARM_R else null
	if arm == null or not arm.is_inside_tree():
		return global_position + Vector3.UP * 1.2 if is_inside_tree() else Vector3.UP * 1.2
	return arm.global_transform * (ARROW_TIP - _o_r)


func _aim_at(target: Variant) -> void:
	_aim_left = AIM_HOLD
	var world: Variant = null
	if target is Node3D and is_instance_valid(target):
		var n := target as Node3D
		var bh: Variant = n.get(&"body_height")
		world = n.global_position + Vector3.UP * (float(bh) * 0.6 if bh != null else 1.0)
	elif target is Vector3:
		world = target
	if world == null or not is_inside_tree():
		_yaw_goal = 0.0
		_pitch_goal = 0.0
		return
	var local := global_transform.affine_inverse() * (world as Vector3)
	var d := local - Vector3(AXIS.x, 1.18, AXIS.z)
	_yaw_goal = clampf(atan2(d.x, d.z), -YAW_MAX, YAW_MAX)
	_pitch_goal = clampf(-atan2(d.y, maxf(Vector2(d.x, d.z).length(), 0.1)), -0.55, 0.35)


# ================================================================ animation

func _extra_process(dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if _dead:
		return
	# aim: turn (Root yaw) and pitch (Chest) toward the goal; hold, then drift back to face forward
	if _aim_left > 0.0:
		_aim_left -= dt
		if _aim_left <= 0.0:
			_yaw_goal = 0.0
			_pitch_goal = 0.0
	_aim_yaw = move_toward(_aim_yaw, _yaw_goal, AIM_TURN * dt)
	_aim_pitch = move_toward(_aim_pitch, _pitch_goal, AIM_PITCH_TURN * dt)
	var aiming: bool = _aim_yaw != 0.0 or _aim_pitch != 0.0 or _yaw_goal != 0.0 or _pitch_goal != 0.0
	if aiming and (_action == &"" or _action == &"scan"):
		_action = &"aim"
		_action_t = 0.0
	elif not aiming and _action == &"aim":
		_action = &""
	rot(P_ROOT, Vector3(0, _aim_yaw, 0))
	rot(P_CHEST, Vector3(_aim_pitch, 0, 0))
	# the shot
	var nock_l := NOCK - _o_l
	if _shot_t < SHOT_LEN:
		var prev := _shot_t
		_shot_t += dt
		nock_l = _pose_shot(prev, _shot_t)
		if _shot_t >= SHOT_LEN and _action == &"shot":
			_action = &"aim" if aiming else &""
	elif _action == &"shot":
		_action = &""
	# idle scan (look around), close only
	_scan_tick(dt)
	_write_strings(nock_l)
	# arrow-head glow: charges over the draw
	if _arm_r_mi and _arrow_on:
		_flare = maxf(0.0, _flare - dt / 0.4)
		var b: float = glow_level() * (1.0 + 2.2 * _flare)
		if absf(b - _tip_written) > 0.02:
			_tip_written = b
			_arm_r_mi.set_instance_shader_parameter(&"glow_boost", b)


## Poses the shot at time t; returns the string nock (ArmL local) for this frame.
func _pose_shot(prev: float, t: float) -> Vector3:
	var draw := MountModel._mkf(t, S_DRAW)
	var reach := MountModel._mkf(t, S_REACH)
	rot(P_CHEST, Vector3(0, MountModel._mkf(t, S_CHEST_Y) * DEG, 0))
	rot(P_ARM_L, Vector3(MountModel._mkf(t, S_BOW_X) * DEG, 0, 0))
	rot(P_HEAD, Vector3(MountModel._mkf(t, S_HEAD_X) * DEG, -8.0 * DEG * draw, 0))
	var arm_rot := Vector3((-6.0 * draw - 115.0 * reach) * DEG, 8.0 * DEG * draw, 0)
	var arm_pos := DRAW_VEC * draw
	rot(P_ARM_R, arm_rot)
	pos(P_ARM_R, arm_pos)
	if t < RELEASE:
		_flare = maxf(_flare, t / RELEASE)
	if prev < RELEASE and t >= RELEASE:
		_flare = 1.0
		var at := get_muzzle()
		_show_arrow(false)
		shot_released.emit(at)
	if prev < 0.56 and t >= 0.56:
		_show_arrow(true)
	var rest := NOCK - _o_l
	if t < RELEASE:
		# the string follows the draw hand (ArmR rest + this frame's offsets, both in Chest space) into ArmL space
		var xr := Transform3D(Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R]), _rest_pos[P_ARM_R] + _off_pos[P_ARM_R])
		var xl := Transform3D(Basis.from_euler(_rest_rot[P_ARM_L] + _off_rot[P_ARM_L]), _rest_pos[P_ARM_L] + _off_pos[P_ARM_L])
		var hand_c := xr * (Vector3(BOW_X + 0.02, NOCK.y, NOCK.z) - _o_r)
		return xl.affine_inverse() * hand_c
	# released: the string snaps back and quivers a moment
	var q: float = 1.0 - clampf((t - RELEASE) / 0.25, 0.0, 1.0)
	return rest + Vector3(0, 0, 0.03 * sin((t - RELEASE) * 90.0) * q)


func _scan_tick(dt: float) -> void:
	if _action == &"scan":
		var k := _k3(_action_t, 0.0, 0.4, 1.4, 1.9, 1.0, 1.0)
		var side: float = 1.0 if int(_phase_off * 10.0) % 2 == 0 else -1.0
		rot(P_HEAD, Vector3(-4.0 * DEG * k, 38.0 * DEG * k * side, 0))
		rot(P_CHEST, Vector3(0, 14.0 * DEG * k * side, 0))
		if _action_t >= 1.9:
			_action = &""
		return
	if _action != &"" or _tier != 0:
		return
	_scan_wait -= dt
	if _scan_wait <= 0.0:
		_scan_wait = SCAN_EVERY * (0.7 + 0.6 * float(hash(get_instance_id() + int(_t)) % 100) / 100.0)
		_action = &"scan"
		_action_t = 0.0


## Places the two string halves from the nock (ArmL local) to the limb tips.
func _write_strings(nock_l: Vector3) -> void:
	if _strings.size() < 2 or (nock_l.is_equal_approx(_string_last) and not _force_write):
		return
	_string_last = nock_l
	for k: int in 2:
		var st := _strings[k]
		if st == null:
			continue
		var tip: Vector3 = (TIP_U if k == 0 else TIP_D) - _o_l
		var v := tip - nock_l
		var ln := maxf(v.length(), 0.001)
		var y := v / ln
		var x := (Vector3.RIGHT - y * y.dot(Vector3.RIGHT)).normalized()
		var z := x.cross(y)
		st.transform = Transform3D(Basis(x, y * ln, z), nock_l)


## Death: the archer slumps forward over the rail, the bow arm drops, glows die at 0.3 s; death_finished at 1.0 s
## (the mammoth frosts him over with the beast).
func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var k := smoothstep(0.0, 0.45, t)
	rot(P_ROOT, Vector3(0, _aim_yaw * (1.0 - k), 0))
	rot(P_CHEST, Vector3(40.0 * DEG * k, 0, 10.0 * DEG * k))
	rot(P_HEAD, Vector3(28.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(55.0 * DEG * k, 0, 0))
	rot(P_ARM_R, Vector3(65.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, -0.12 * k, 0))
	if t >= 0.3:
		_glows_dead()
		if _arm_r_mi:
			_arm_r_mi.set_instance_shader_parameter(&"glow_boost", 0.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _on_revive() -> void:
	if _face:
		_face.reset()
	_shot_t = 99.0
	_aim_yaw = 0.0
	_aim_pitch = 0.0
	_yaw_goal = 0.0
	_pitch_goal = 0.0
	_aim_left = 0.0
	_flare = 0.0
	_show_arrow(true)
	_string_last = Vector3(INF, 0, 0)
	_write_strings(NOCK - _o_l)


## The archer's eyes (faces pass 2026-09-28; titans: eyes only): two glowing ice-blue eyes in the hood's shadow with
## lids and brows for the expression (the aim narrows them), no painted mouth (it hides under the scarf). Drawn inside
## the merged head (CreatureFaceRig host mode: no extra draw instance).
static func face_spec() -> Dictionary:
	var shade := Color(0.16, 0.20, 0.28)
	return CreatureFaceRig.beast_spec(Vector3(AXIS.x, 1.31, AXIS.z + 0.04), 0.12, {"c": Vector2(0.040, 0.020), "hw": 0.024,
		"top": 0.013, "bot": 0.010, "ir": 0.011, "lash": 1.0, "flick": 0.0}, shade, Color(0.60, 0.90, 1.0), 0.9,
		Vector2(0.0, -0.06), {"head_mesh": CharacterModel.sphere(0.12, 10, 5), "lift": 0.006,
		"palette": {"sclera": FaceKit.glow(Color(0.40, 0.62, 0.80), 0.5), "brow": Color(0.36, 0.44, 0.56)}})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
