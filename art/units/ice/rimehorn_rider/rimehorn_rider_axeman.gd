class_name RimehornRiderAxeman
extends IceModel
## Rimehorn Rider rider (cavalry-mounts.md 4 / 10, task 13.V8): the Ice "armored breaker" on the 13.V4 Rimehorn. Seated
## with the kit's CharacterModel.set_seated (13.V1b); the scene that pairs it with the rhino is rimehorn_rider.tscn
## (RimehornRiderModel, the unit's model_scene).
## Look: a burly axeman in a team surcoat under dark blue steel plates, a HUGE WARM-BROWN FUR MANTLE over the shoulders
## (the widest mass of the rider, warm against the cool rhino), silver-blue pauldrons with frost crystals, a steel helm
## with a fur brim, a nose guard and a swept-back ICE FIN crest (echoes the Rimehorn's horn), a pale braided beard.
## Left arm: a ROUND SHIELD OF CLEAR ICE (0.84 m, the team snowflake inside, silver rim, crystal boss, frost crystals
## grown on the rim) braced out on the left flank, tilted to the sky so the big pale disc reads from the game camera.
## Right hand: a long bearded GREAT AXE (own node "Axe" at the fist: the wrist turns it, so the chop is a real one), an
## ice-crystal crescent blade with a glowing frost edge, a steel back spike, a crystal top point.
## Glow point: the axe's frost edge (ice_glow_unit, the only one: the Rimehorn already shows its horn tip and eyes).
## Riding: the axe carried upright at the right shoulder, the shield braced out-left; the kit's lean / bob / head.
## Attack (`great_swing`, 0.9 s, strike at SW_HIT 0.15 s = event `release` + signal axe_struck): the arm goes up and
## the axe head drops behind the back (wind-up, twist right, shield in), then the arm comes over the top and down in
## front while the head whips over into a chop down the right front of the rhino (lean into it, the shield swings out).
## Charge (play_charge_pose(), 0.85 s, impact 0.10 s like MountModel.play_charge): hunker behind the shield (shield
## forward, chest low), the axe raised high out to the right, a jolt at the impact.
## Fidget (IceModel, standing still): hefts the axe twice and looks round. Cast: the axe raised high.
## Death: freezes over and SHATTERS (IceModel, 10 crystal shards) while riding the Rimehorn's roll.
## Hooks (on top of the kit's / IceModel's): play_charge_pose(), get_axe_head() -> Vector3 (world),
## axe_angle() -> float (deg, the haft in the chest frame: 0 up, + toward the front), authored_mesh_count() -> int;
## signal axe_struck(at: Vector3) (world, the blade at the strike frame).
## Budget (cavalry unit, section 10): 9 authored meshes (7 merged pivot sculpts + the axe + the level-4 helm trim), 9 draw
## instances (7 merged pivots + Axe + the trim, hidden below level 4) + 1 particle system (10 shards), no blob (the
## rhino's shows), 0 lights.

signal axe_struck(at: Vector3)

const OWN := "res://art/units/ice/rimehorn_rider/materials/"

# Rest landmarks (model space, standing, feet origin, face +Z, right hand +X). Arms authored hanging straight down.
const HIP_Y := 0.90
const SH_L := Vector3(-0.37, 1.43, 0.0)
const SH_R := Vector3(0.37, 1.43, 0.0)
const HAND_L := Vector3(-0.39, 0.91, 0.02)
const HAND_R := Vector3(0.39, 0.91, 0.02)
## Shield centre (model, on the left forearm; its face looks along -X at rest) and radius.
const SHIELD_C := Vector3(-0.55, 1.03, 0.02)
const SHIELD_R := 0.42
## The axe (node-local, origin = the fist): haft along +Y (length above the fist), head centre, blade toward +Z.
const AXE_LEN := 1.06
const AXE_HEAD := 0.86
const BLADE_SCALE := 1.22
## Crescent blade outline (u = forward along the cutting direction, v = along the haft), metres before BLADE_SCALE.
const BLADE: Array[Vector2] = [Vector2(0.03, 0.11), Vector2(0.03, -0.12), Vector2(0.13, -0.13), Vector2(0.24, -0.21),
	Vector2(0.34, -0.33), Vector2(0.41, -0.26), Vector2(0.45, -0.13), Vector2(0.46, 0.0), Vector2(0.44, 0.11),
	Vector2(0.38, 0.21), Vector2(0.25, 0.14), Vector2(0.13, 0.10)]
## The glowing edge (indices into BLADE, beard tip -> top horn).
const EDGE_FROM := 4
const EDGE_TO := 9

## Riding rest pose of the arms (deg, pivot euler offsets): the shield braced out-left and tilted up, the axe arm low.
const REST_L := Vector3(-30.0, 22.0, -40.0)
const REST_R := Vector3(-30.0, 0.0, 12.0)
## The axe's angle in the chest frame at rest (deg about X: 0 = haft up, + = head toward the front).
const AXE_REST := -8.0
## Attack timeline (s): wind-up end, strike, end.
const SW_WIND := 0.10
const SW_HIT := 0.15
const SW_LEN := 0.9
## Charge (matches MountModel.play_charge: impact 0.10 s, length 0.85 s).
const CH_HIT := 0.10
const CH_LEN := 0.85

var _parts_n: int = 0
var _axe: MeshInstance3D
var _charge_t: float = 99.0
# this frame's axe angle / outward roll added by the poses (deg), consumed by _update_axe
var _psi_add: float = 0.0
var _roll_add: float = 0.0
var _yaw_add: float = 0.0
var _psi_now: float = AXE_REST
var _axe_q_w: Quaternion = Quaternion(0, 0, 0, 0)


# ================================================================ public hooks

## The rider's half of the cavalry charge (call with the mount's play_charge): hunker behind the shield, axe raised.
func play_charge_pose() -> void:
	if _dead:
		return
	_charge_t = 0.0
	set_process(true)


## World position of the axe blade's centre (the strike point for VFX).
func get_axe_head() -> Vector3:
	if _axe and _axe.is_inside_tree():
		return _axe.global_transform * Vector3(0, AXE_HEAD, 0.3)
	return global_position + Vector3.UP * 2.2


## The haft's angle in the chest frame (deg about X: 0 = up, 90 = forward, -90 = back).
func axe_angle() -> float:
	return _psi_now


## Authored meshes of the rider (the cavalry budget of section 10).
func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	_sculpt($Root/Hips, "rrr_hips_v1", _hips_sculpt)
	for leg: Node3D in [$Root/Hips/LegL, $Root/Hips/LegR]:
		var sx: float = -1.0 if leg.name == "LegL" else 1.0
		_sculpt(leg, "rrr_leg_%s_v1" % sx, func(s: Dictionary) -> void: _leg_sculpt(s, sx))
	_sculpt($Root/Chest, "rrr_chest_v1", _chest_sculpt)
	_sculpt($Root/Chest/Head, "rrr_head_v3", _head_sculpt)
	# Face (faces pass 2026-09-28): a weathered axeman, pale brows, ice-grey eyes; the mouth sits on the pale beard
	# under the moustache (mouth canvas). Replaces the two dark eye beads: one FaceRig surface.
	_face = FaceKit.attach(self, $Root/Chest/Head, "rimehorn_rider_axeman", {"center": Vector3(0, 1.72, 0.05), "radius": 0.145,
		"head_mesh": sphere(0.145, 10, 6), "head_scale": Vector3(0.95, 1.05, 0.95), "preset": &"stern", "detail": &"low",
		"skin": ICE_SKIN, "hair": Color(0.90, 0.92, 0.95), "eyes": Color(0.50, 0.62, 0.74), "ears": &"none",
		"palette": {"brow": Color(0.56, 0.58, 0.64), "lash": Color(0.10, 0.10, 0.14)},
		"eye": {"c": Vector2(0.052, -0.006), "hw": 0.027, "top": 0.017, "ir": 0.013},
		"brow": {"inner": Vector2(0.024, 0.026), "mid": Vector2(0.050, 0.030), "outer": Vector2(0.076, 0.024)},
		"mouth_canvas": FaceKit.canvas(Vector3(0, 1.59, 0.12), 0.11, sphere(0.125, 9, 5), Vector3(1.0, 0.9, 0.8), Vector3.INF,
			Basis.IDENTITY, 0.002),
		"mouth": {"c": Vector2(0.0, 0.040), "hw": 0.030}})
	_sculpt($Root/Chest/ArmL, "rrr_arm_l_v1", _arm_l_sculpt)
	_sculpt($Root/Chest/ArmR, "rrr_arm_r_v1", _arm_r_sculpt)
	# the axe: own node at the fist (turned by the wrist every animated frame)
	_parts_n += 1
	_axe = add_part($Root/Chest/ArmR, _cached_sculpt("rrr_axe_v1", _axe_sculpt), null, HAND_R, Vector3.ZERO, Vector3.ONE,
		true, "Axe")
	# Level 4: a gold ring on the helm brim.
	_parts_n += 1
	var trim := add_part($Root/Chest/Head, torus(0.19, 0.235, 14), palette(&"unit_gold_trim"), Vector3(0, 1.845, 0.03),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# The shatter death: one burst of 10 crystal shards from the chest (the cavalry budget: 1 particle system <= 10).
	_shatter = _shards(10, 0.9, 0.35, 1.6, 3.6, 180.0, Vector3.UP, 0.12)
	_shatter.name = "Shatter"
	var chest: Node3D = $Root/Chest
	_shatter.position = Vector3(0, 1.25, 0.05) - model_origin(chest)
	chest.add_child(_shatter)


func _ice_ready() -> void:
	_axe_q_w = Quaternion(0, 0, 0, 0)
	_update_axe()


## One authored part from a multi-material sculpt (MountModel's builders), skipped once the pivot's merge is cached.
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
	if name.begins_with("rimehorn_rider"):
		return MountModel.material_at(OWN + name + ".tres")
	return ice(StringName(name))


## Rotation taking +Y onto `d` (robust for d straight down).
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


## Flat slab from a 2D outline (u -> local +Z, v -> local +Y), `thick` along local X, both faces + the rim walls.
static func _slab_mesh(key: String, poly: PackedVector2Array, thick: float) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := thick * 0.5
	var tri := Geometry2D.triangulate_polygon(poly)
	for i: int in range(0, tri.size(), 3):
		for sx: float in [-1.0, 1.0]:
			var nn := Vector3(sx, 0, 0)
			var a := Vector3(h * sx, poly[tri[i]].y, poly[tri[i]].x)
			var b := Vector3(h * sx, poly[tri[i + 1]].y, poly[tri[i + 1]].x)
			var c := Vector3(h * sx, poly[tri[i + 2]].y, poly[tri[i + 2]].x)
			_emit(st, a, b, c, nn)
	var area := 0.0
	for i: int in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		area += p.x * q.y - q.x * p.y
	var ccw: float = 1.0 if area > 0.0 else -1.0
	for i: int in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var e := (q - p).normalized()
		var o := Vector2(e.y, -e.x) * ccw
		var nn := Vector3(0, o.y, o.x)
		var a := Vector3(-h, p.y, p.x)
		var b := Vector3(h, p.y, p.x)
		var c := Vector3(h, q.y, q.x)
		var d := Vector3(-h, q.y, q.x)
		_emit(st, a, b, c, nn)
		_emit(st, a, c, d, nn)
	st.index()
	return _cached(key, st.commit())


## One flat-shaded triangle, front face (Godot: clockwise) toward `n`.
static func _emit(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot(n) > 0.0:
		var t := b
		b = c
		c = t
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)


# ---------------------------------------------------------------- body

func _hips_sculpt(s: Dictionary) -> void:
	var dark := m("ice_cloth_dark")
	var cloth := m("ice_cloth")
	var leather := m("ice_leather")
	var metal := m("ice_metal")
	var fur := m("rimehorn_rider_fur")
	_put(s, cyl(0.225, 0.26, 0.22, 10), dark, Vector3(0, 0.84, 0))
	# heavy belt, a round silver-blue buckle with an ice gem
	_put(s, cyl(0.255, 0.255, 0.09, 12, false), leather, Vector3(0, 0.955, 0))
	_put(s, cyl(0.075, 0.075, 0.04, 8), metal, Vector3(0, 0.955, 0.255), Vector3(90, 0, 0))
	_put(s, cyl(0.035, 0.035, 0.03, 6), m("ice_frost_crystal"), Vector3(0, 0.955, 0.28), Vector3(90, 0, 0))
	# fur skirt round the sides and back (the front stays clear of the Rimehorn's hump), a team flap behind
	MountModel.sculpt_fringe(s, fur, MountModel.fringe_mesh("rrr_skirt_v1", 0.25, 0.22, 0.32, 0.29, 0.14, 62.0, 298.0, 8,
		0.10, 0.03, 0.6), Vector3(0, 0.93, 0))
	_put(s, soft_box(Vector3(0.30, 0.30, 0.035)), cloth, Vector3(0, 0.79, -0.27), Vector3(-14, 0, 0))
	_put(s, soft_box(Vector3(0.30, 0.04, 0.04)), dark, Vector3(0, 0.645, -0.305), Vector3(-14, 0, 0))


## A leg rooted at the hip (sx -1 left, +1 right): team-dark trousers, a steel knee cop, the shin authored bent back by
## seat_leg_forward_deg so it hangs straight down in the saddle, a steel greave, a leather boot with a fur cuff.
func _leg_sculpt(s: Dictionary, sx: float) -> void:
	var dark := m("ice_cloth_dark")
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var leather := m("ice_leather")
	var fur := m("rimehorn_rider_fur")
	var fwd := deg_to_rad(seat_leg_forward_deg)
	var hip := Vector3(0.13 * sx, HIP_Y, 0)
	var knee := Vector3(0.145 * sx, 0.50, 0.03)
	var shin := Vector3(0, -cos(fwd), -sin(fwd))
	var ankle := knee + shin * 0.34
	_seg(s, dark, hip, knee, 0.105, 0.085, 8)
	_put(s, sphere(0.085, 8, 4), metal, knee + Vector3(0, 0.0, 0.03), Vector3.ZERO, Vector3(1.0, 0.9, 1.0))
	_seg(s, steel, knee, ankle, 0.08, 0.07, 8)
	# fur boot cuff, the boot pointing forward (toe up by fwd: level once seated)
	MountModel.sculpt_add(s, cyl(0.10, 0.092, 0.11, 8), Transform3D(_to_dir(shin), knee + shin * 0.26), fur)
	var foot_dir := Vector3(0, sin(fwd), cos(fwd))
	var foot_c := ankle + foot_dir * 0.07 + Vector3(0, -0.04, 0)
	MountModel.sculpt_add(s, capsule(0.07, 0.28), Transform3D(_to_dir(foot_dir), foot_c), leather)
	_put(s, cyl(0.08, 0.075, 0.08, 8), leather, ankle, Vector3(rad_to_deg(-fwd), 0, 0))


func _chest_sculpt(s: Dictionary) -> void:
	var cloth := m("ice_cloth")
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var frost := m("ice_frost_crystal")
	var fur := m("rimehorn_rider_fur")
	# torso: the team surcoat (lathe, flattened front-back)
	var prof := PackedVector2Array([Vector2(0.20, 0.92), Vector2(0.24, 1.02), Vector2(0.295, 1.18), Vector2(0.31, 1.30),
		Vector2(0.29, 1.40), Vector2(0.20, 1.50), Vector2(0.10, 1.56), Vector2(0.0, 1.57)])
	var torso := MountModel.lathe_mesh("rrr_torso_v1", prof, 12)
	MountModel.sculpt_add(s, torso, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.82)), Vector3.ZERO), cloth)
	# dark steel plates front and back, a silver-blue medallion with an ice gem
	_put(s, soft_box(Vector3(0.46, 0.34, 0.10)), steel, Vector3(0, 1.27, 0.20), Vector3(-9, 0, 0))
	_put(s, soft_box(Vector3(0.40, 0.13, 0.09)), steel, Vector3(0, 1.06, 0.18), Vector3(-4, 0, 0))
	_put(s, soft_box(Vector3(0.48, 0.40, 0.08)), steel, Vector3(0, 1.25, -0.20), Vector3(8, 0, 0))
	_put(s, cyl(0.08, 0.08, 0.04, 10), metal, Vector3(0, 1.30, 0.265), Vector3(81, 0, 0))
	_put(s, cyl(0.045, 0.045, 0.04, 6), frost, Vector3(0, 1.303, 0.29), Vector3(81, 0, 0))
	# silver-blue pauldrons, frost crystals growing out of them
	for sx: float in [-1.0, 1.0]:
		_put(s, sphere(0.17, 10, 5), metal, Vector3(0.41 * sx, 1.41, 0.0), Vector3.ZERO, Vector3(1.15, 0.72, 1.12))
		MountModel.sculpt_crystal(s, frost, Vector3(0.47 * sx, 1.45, 0.03), Vector3(0.75 * sx, 1.0, 0.15), 0.06, 0.34)
		MountModel.sculpt_crystal(s, frost, Vector3(0.42 * sx, 1.47, -0.10), Vector3(0.35 * sx, 1.0, -0.55), 0.045, 0.24)
	# the fur mantle: a thick collar roll and a shaggy cape over the shoulders (the rider's widest mass)
	_put(s, torus(0.12, 0.27, 12), fur, Vector3(0, 1.53, -0.02), Vector3.ZERO, Vector3(1.0, 1.7, 0.92))
	MountModel.sculpt_fringe(s, fur, MountModel.fringe_mesh("rrr_mantle_v1", 0.23, 0.19, 0.45, 0.36, 0.20, 0.0, 360.0, 14,
		0.11, 0.035, 0.6), Vector3(0, 1.55, -0.02))
	# the mantle hangs longer down the back
	MountModel.sculpt_fringe(s, fur, MountModel.fringe_mesh("rrr_mantle_back_v1", 0.38, 0.30, 0.42, 0.34, 0.30, 118.0,
		242.0, 6, 0.12, 0.035, 0.6), Vector3(0, 1.40, -0.03))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("ice_skin")
	var hair := m("ice_hair")
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var frost := m("ice_frost_crystal")
	var fur := m("rimehorn_rider_fur")
	_put(s, cyl(0.085, 0.10, 0.14, 8), skin, Vector3(0, 1.585, 0.02))
	_put(s, sphere(0.145, 10, 6), skin, Vector3(0, 1.72, 0.05), Vector3.ZERO, Vector3(0.95, 1.05, 0.95))
	for sx: float in [-1.0, 1.0]:
		_put(s, soft_box(Vector3(0.05, 0.17, 0.15)), steel, Vector3(0.145 * sx, 1.71, 0.07), Vector3(0, 12.0 * sx, 0))
	# the pale beard: a full chin, a long braid with a silver ring, a moustache
	_put(s, sphere(0.125, 9, 5), hair, Vector3(0, 1.59, 0.12), Vector3.ZERO, Vector3(1.0, 0.9, 0.8))
	_seg(s, hair, Vector3(0, 1.55, 0.16), Vector3(0, 1.34, 0.22), 0.09, 0.02, 7)
	_put(s, torus(0.035, 0.07, 8), metal, Vector3(0, 1.46, 0.195), Vector3(15, 0, 0))
	for sx: float in [-1.0, 1.0]:
		_seg(s, hair, Vector3(0.0, 1.672, 0.19), Vector3(0.10 * sx, 1.615, 0.165), 0.03, 0.012, 5)
	# steel helm with a fur brim and a nose guard
	_put(s, sphere(0.17, 12, 6), steel, Vector3(0, 1.83, 0.03), Vector3.ZERO, Vector3(1.05, 0.88, 1.08))
	_put(s, torus(0.155, 0.195, 14), metal, Vector3(0, 1.805, 0.03))
	_put(s, torus(0.15, 0.225, 14), fur, Vector3(0, 1.79, 0.02), Vector3.ZERO, Vector3(1.0, 1.5, 1.0))
	_put(s, soft_box(Vector3(0.04, 0.15, 0.035)), metal, Vector3(0, 1.745, 0.195), Vector3(-6, 0, 0))
	# the swept-back ice fin crest (echoes the Rimehorn's horn), a steel ridge under it
	_put(s, soft_box(Vector3(0.05, 0.05, 0.30)), metal, Vector3(0, 1.975, 0.0), Vector3(-10, 0, 0))
	MountModel.sculpt_add(s, MountModel.tube_mesh("rrr_crest_v1", PackedVector3Array([Vector3(0, 1.96, 0.13),
		Vector3(0, 2.07, 0.02), Vector3(0, 2.16, -0.13), Vector3(0, 2.22, -0.32)]),
		PackedFloat32Array([0.075, 0.07, 0.045, 0.0]), 6, true, 0.38), Transform3D.IDENTITY, frost)
	for sx: float in [-1.0, 1.0]:
		MountModel.sculpt_crystal(s, frost, Vector3(0.15 * sx, 1.87, -0.02), Vector3(0.8 * sx, 0.55, -0.6), 0.035, 0.19)


func _arm_l_sculpt(s: Dictionary) -> void:
	var dark := m("ice_cloth_dark")
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var leather := m("ice_leather")
	var cloth := m("ice_cloth")
	var frost := m("ice_frost_crystal")
	var fur := m("rimehorn_rider_fur")
	var elbow := Vector3(-0.385, 1.16, 0.0)
	_put(s, sphere(0.105, 8, 4), dark, SH_L + Vector3(0, -0.02, 0))
	_seg(s, dark, SH_L, elbow, 0.092, 0.08, 8)
	_put(s, torus(0.06, 0.12, 8), fur, elbow + Vector3(0, -0.01, 0), Vector3.ZERO, Vector3(1.0, 1.6, 1.0))
	_seg(s, steel, elbow, HAND_L + Vector3(0, 0.05, 0), 0.082, 0.07, 8)
	_put(s, sphere(0.078, 8, 4), leather, HAND_L, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))
	# strap from the forearm to the shield
	_put(s, soft_box(Vector3(0.14, 0.06, 0.06)), leather, Vector3(-0.47, 1.06, 0.01))
	# the round shield of clear ice (face -X), silver rim, the team snowflake inside the ice, a crystal boss
	var sc := SHIELD_C
	_put(s, cyl(SHIELD_R, SHIELD_R, 0.07, 14), m("ice_frost_clear"), sc, Vector3(0, 0, 90))
	_put(s, torus(SHIELD_R - 0.03, SHIELD_R + 0.05, 14), metal, sc, Vector3(0, 0, 90))
	for k: int in 3:
		_put(s, soft_box(Vector3(0.022, 0.085, 0.62)), cloth, sc + Vector3(-0.005, 0, 0), Vector3(60.0 * k, 0, 0))
	_put(s, cyl(0.0, 0.11, 0.17, 6), frost, sc + Vector3(-0.115, 0, 0), Vector3(0, 0, 90))
	_put(s, cyl(0.12, 0.12, 0.03, 10), metal, sc + Vector3(-0.035, 0, 0), Vector3(0, 0, 90))
	# three frost crystals grown on the rim (top-front), pointing outward
	for a: float in [-35.0, 0.0, 35.0]:
		var ar := deg_to_rad(a + 40.0)
		var out := Vector3(0, cos(ar), sin(ar))
		MountModel.sculpt_crystal(s, frost, sc + out * (SHIELD_R + 0.02), out + Vector3(-0.15, 0, 0), 0.045, 0.2)


func _arm_r_sculpt(s: Dictionary) -> void:
	var dark := m("ice_cloth_dark")
	var steel := m("ice_steel")
	var leather := m("ice_leather")
	var fur := m("rimehorn_rider_fur")
	var elbow := Vector3(0.385, 1.16, 0.0)
	_put(s, sphere(0.105, 8, 4), dark, SH_R + Vector3(0, -0.02, 0))
	_seg(s, dark, SH_R, elbow, 0.092, 0.08, 8)
	_put(s, torus(0.06, 0.12, 8), fur, elbow + Vector3(0, -0.01, 0), Vector3.ZERO, Vector3(1.0, 1.6, 1.0))
	_seg(s, steel, elbow, HAND_R + Vector3(0, 0.05, 0), 0.082, 0.07, 8)
	_put(s, sphere(0.078, 8, 4), leather, HAND_R, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


## The great axe (keep_separate "Axe", node-local: the fist at the origin, haft along +Y, the blade toward +Z): haft,
## grip wraps, pommel, collar, steel socket, the ice crescent blade with a glowing frost edge, a back spike, a crystal
## top point.
func _axe_sculpt(s: Dictionary) -> void:
	var steel := m("ice_steel")
	var metal := m("ice_metal")
	var leather := m("ice_leather")
	var frost := m("ice_frost_crystal")
	var d := Vector3.UP
	_seg(s, m("ice_wood"), d * -0.17, d * AXE_LEN, 0.036, 0.034, 7)
	_put(s, sphere(0.055, 7, 3), metal, d * -0.19)
	for o: float in [-0.09, 0.09]:
		_put(s, cyl(0.045, 0.045, 0.05, 7, false), leather, d * o)
	_put(s, cyl(0.052, 0.052, 0.06, 7), metal, d * 0.66)
	var h := d * AXE_HEAD
	_put(s, soft_box(Vector3(0.10, 0.25, 0.13)), steel, h + Vector3(0, 0, 0.02))
	var poly := PackedVector2Array()
	for p: Vector2 in BLADE:
		poly.append(p * BLADE_SCALE)
	MountModel.sculpt_add(s, _slab_mesh("rrr_blade_v1", poly, 0.06), Transform3D(Basis.IDENTITY, h), frost)
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	for i: int in range(EDGE_FROM, EDGE_TO + 1):
		var p: Vector2 = BLADE[i] * BLADE_SCALE
		pts.append(h + Vector3(0, p.y, p.x + 0.012))
		rad.append(0.034 if i != EDGE_FROM and i != EDGE_TO else 0.02)
	MountModel.sculpt_add(s, MountModel.tube_mesh("rrr_edge_v1", pts, rad, 5), Transform3D.IDENTITY, m("ice_glow_unit"))
	MountModel.sculpt_add(s, cyl(0.0, 0.055, 0.22, 6), Transform3D(_to_dir(Vector3(0, 0, -1)), h + Vector3(0, 0, -0.15)),
		steel)
	MountModel.sculpt_crystal(s, frost, d * (AXE_LEN - 0.02), d, 0.04, 0.2)


# ================================================================ motion

## `great_swing` (mounted chop): wind-up to SW_WIND (arm up, the head drops behind the back, twist right, shield in),
## strike at SW_HIT (the arm comes over and down in front, the head whips over the top into the chop, lean into it,
## the shield swings out), recovery to SW_LEN. Offsets relative to the riding rest pose (added in _pose_seated), so
## the recovery blends back without a jump.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"great_swing":
		return super._pose_attack(prev, t)
	var sc := swing_scale * DEG
	rot(P_ARM_R, Vector3(_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -136.0, -30.0) * sc, 0,
		_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 6.0, 18.0) * DEG))
	_psi_add += _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -142.0, 118.0)
	_yaw_add += _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 10.0, 45.0)
	rot(P_ARM_L, Vector3(_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 14.0, -18.0) * DEG, 0,
		_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 10.0, -16.0) * DEG))
	rot(P_CHEST, Vector3(_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -12.0, 18.0) * DEG,
		_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 24.0, -16.0) * DEG, _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 4.0, -12.0) * DEG))
	rot(P_HEAD, Vector3(_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -6.0, 12.0) * DEG,
		_k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -12.0, 10.0) * DEG, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, 0.05, -0.08), _k3(t, 0.0, SW_WIND, SW_HIT, SW_LEN, -0.04, 0.14)))
	if prev < SW_HIT and t >= SW_HIT:
		_on_action_event(&"release")
	return t < SW_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		axe_struck.emit(get_axe_head())


## A war-cry salute for any cast: the axe raised high overhead.
func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-125.0 * DEG * k, 0, 16.0 * DEG * k))
	_psi_add += 8.0 * k
	rot(P_HEAD, Vector3(-12.0 * DEG * k, 0, 0))
	return 0.75


## Fidget (standing still): hefts the axe twice, a glance round.
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.25, 1.25, 1.6, 1.0, 1.0)
	var heft: float = absf(sin(clampf((t - 0.2) / 1.0, 0.0, 1.0) * TAU))
	rot(P_ARM_R, Vector3((-16.0 * env - 14.0 * heft * env) * DEG, 0, 0))
	_psi_add += 12.0 * heft * env
	rot(P_CHEST, Vector3(-4.0 * DEG * env, 6.0 * DEG * env, 0))
	rot(P_HEAD, Vector3(-4.0 * DEG * env, 26.0 * DEG * sin(t * TAU / 1.6) * env, 0))
	return 1.6


func _ice_process(dt: float) -> void:
	if _charge_t < CH_LEN:
		_charge_t += dt
	if _dead:
		_charge_t = 99.0
	if not _rd_on:
		_update_axe()


## Riding: the kit's seat pose (lean, bob, head, legs), then the own arms (the kit's reins replaced): the rest pose
## always on, the action offsets written before kept on top; the charge hunker; then the axe's wrist.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 7.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var rl := REST_L + Vector3(bounce * 0.6, 0, 0)
	var rr := REST_R + Vector3(-bounce, 0, 0)
	var psi: float = AXE_REST + (bounce * 0.8 - 10.0 * gallop * moving)
	# at the gallop the shield comes in closer
	rl += Vector3(-6.0, 6.0, 4.0) * gallop * moving
	if _charge_t < CH_LEN and not _dead:
		var t := _charge_t
		var env := _k3(t, 0.0, 0.07, 0.40, CH_LEN, 1.0, 1.0)
		var jolt := _k3(t, CH_HIT - 0.02, CH_HIT + 0.03, CH_HIT + 0.05, 0.32, 1.0, 1.0)
		rl += Vector3(-34.0 * env - 14.0 * jolt, 34.0 * env, 18.0 * env)
		rr += Vector3(-62.0 * env, 0, 30.0 * env)
		psi += -46.0 * env
		_roll_add += 14.0 * env
		rot(P_CHEST, Vector3((16.0 * env - 9.0 * jolt) * DEG * w, 0, 0))
		rot(P_HEAD, Vector3(-10.0 * env * DEG * w, 0, 0))
	_off_rot[P_ARM_L] = sal + rl * DEG * w
	_off_rot[P_ARM_R] = sar + rr * DEG * w
	_psi_add += (psi - AXE_REST) * w
	_update_axe()


## The wrist: turns the Axe node so its haft points at angle AXE_REST + _psi_add (chest frame, about X) rolled outward
## by _roll_add, whatever the arm does. Consumes this frame's additions.
func _update_axe() -> void:
	var psi: float = AXE_REST + _psi_add
	var roll: float = _roll_add
	var yaw: float = _yaw_add
	_psi_add = 0.0
	_roll_add = 0.0
	_yaw_add = 0.0
	if _dead:
		psi = AXE_REST
		roll = 0.0
		yaw = 0.0
	_psi_now = psi
	if _axe == null:
		return
	var want := Basis(Vector3.UP, yaw * DEG) * Basis(Vector3.BACK, -roll * DEG) * Basis(Vector3.RIGHT, psi * DEG)
	var arm := Basis.from_euler(_rest_rot[P_ARM_R] + _off_rot[P_ARM_R]) if _piv[P_ARM_R] else Basis.IDENTITY
	var q := (arm.inverse() * want).get_rotation_quaternion()
	if not q.is_equal_approx(_axe_q_w):
		_axe_q_w = q
		_axe.quaternion = q


func _ice_revive() -> void:
	_charge_t = 99.0
	_psi_add = 0.0
	_roll_add = 0.0
	_yaw_add = 0.0
	_axe_q_w = Quaternion(0, 0, 0, 0)
	_update_axe()
