extends FireModel
## Scorchbow, Fire bowman (docs/design/bowmen.md: burning arrows, heavy base shot). body_height 1.65 (UnitType), stocky.
## A broad veteran war-bowman (the Ember Archer is a lean hooded scout): a bronze KETTLE HELM with a wide brim and a
## crest ridge and a swept-back team plume over a bearded face, a fur collar, a dark team gambeson with a bronze half-breastplate, a big bronze
## pauldron on the bow shoulder (asymmetry), a dark leather apron-skirt, bronze greaves, a leather HIP QUIVER on the
## right with red-fletched pitch arrows. The silhouette hook: a heavy dark-wood GREATBOW (1.95 m, upright in the left
## fist; the Ember Archer carries a light bow level) with bronze horn caps on the tips.
## The only glow point at rest: a bronze BRAZIER cup on a bracket behind the right shoulder (the arrows are lit in it).
## Attack `bow_draw` (0.65 s, release 0.15): the bow arm snaps up level, the body turns side-on, the right hand draws a
## BURNING arrow to the chin (its head flames = the arrow-tip glow), looses at 0.15 with an ember burst and a heavy
## recoil step back. play_cast (any id, 1.0 s): a slow full draw aimed high (an arcing fire shot), bigger flare.
## Hooks (plus every kit / Fire hook): get_bow_tip_position() -> Vector3 (world; where the arrow leaves).
## Draws: merged pivots + Bow (2 surfaces) + BowString + StringDrawn + Arrow + ArrowFlame (hidden at rest) + PotFire (brazier)
## + VetTrim (hidden) + blob. 0 lights.

const ATTACK_LEN := 0.65
const RELEASE := 0.15
const CAST_LEN := 1.0
const CAST_RELEASE := 0.65
const BOW_TILT := 8.0                            # deg, rest: the top of the bow leans forward a little
const GRIP_L := Vector3(-0.38, 0.96, 0.12)       # model space: the left fist = the Bow node origin
const HAND_R := Vector3(0.37, 0.90, 0.06)
const SH_L := Vector3(-0.29, 1.32, 0.0)
const SH_R := Vector3(0.29, 1.32, 0.0)
const POT := Vector3(0.25, 1.46, -0.22)          # back brazier cup centre (chest pivot)
# bow space (origin = grip, +Y up the bow, -Z toward the archer = string side)
const TIP_U := Vector3(0.0, 1.00, -0.17)
const TIP_D := Vector3(0.0, -0.93, -0.17)
const NOCK := Vector3(0.0, 0.0, -0.52)
const ARROW_HEAD := Vector3(0.0, 0.0, 0.34)
const EMBER_C := Color(1.0, 0.45, 0.10)

# bow_draw tracks [t, value, ease] (FireModel._kf). Arm x: negative raises forward.
static var S_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.10, -84.0, 1, 0.38, -80.0, 0, 0.65, 0.0, 0])
static var S_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.10, 30.0, 1, 0.38, 26.0, 0, 0.65, 0.0, 0])
static var S_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -78.0, 1, 0.15, -86.0, 0, 0.22, -62.0, 1, 0.65, 0.0, 0])
static var S_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.30, 1, 0.15, -0.46, 2, 0.22, -0.56, 1, 0.65, 0.0, 0])
static var S_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.15, 0.0, 0, 0.21, -0.12, 1, 0.40, -0.08, 0, 0.65, 0.0, 0])
static var S_ROOT_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -5.0, 1, 0.15, -5.0, 0, 0.21, -10.0, 1, 0.65, 0.0, 0])
# Arcing fire shot: slow full draw aimed high, loose at 0.65.
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.30, -118.0, 1, 0.80, -112.0, 0, 1.0, 0.0, 0])
static var C_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.30, 30.0, 1, 0.80, 26.0, 0, 1.0, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.30, -100.0, 1, 0.60, -112.0, 0, 0.72, -88.0, 1, 1.0, 0.0, 0])
static var C_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.30, -0.26, 1, 0.60, -0.48, 2, 0.72, -0.58, 1, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -14.0, 0, 0.60, -16.0, 0, 0.72, -4.0, 1, 1.0, 0.0, 0])

var _bow: Node3D
var _bstring: GeometryInstance3D
var _string_drawn: GeometryInstance3D
var _barrow: GeometryInstance3D
var _arrow_fire: GeometryInstance3D
var _pot_fire: GeometryInstance3D
var _burst: GPUParticles3D
var _drawn_on: bool = false
var _cast_loosed: bool = false
var _flare: float = 0.0
var _charge: float = 0.0
var _pot_written: float = -1.0
var _arrow_written: float = -1.0
var _bow_x_written: float = 999.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := palette(&"fire_cloth")
	var cdark := palette(&"fire_cloth_dark")
	var skin := palette(&"fire_skin")
	var leather := palette(&"fire_leather")
	var bronze := palette(&"fire_bronze")
	var wood := palette(&"fire_wood")
	var fur := palette(&"fire_fur")
	var hair := palette(&"fire_hair")
	var flame := palette(&"fire_flame")
	# ---- Legs: thick leather trousers, bronze greaves, dark boots.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		var x: float = 0.12 * sx
		add_part(leg, _path("sb_thigh", PackedVector3Array([Vector3(0, 0.86, 0), Vector3(0, 0.60, 0.02),
			Vector3(0, 0.36, 0.0)]), PackedFloat32Array([0.11, 0.095, 0.08]), 7), leather, Vector3(x, 0, 0))
		add_part(leg, _path("sb_boot", PackedVector3Array([Vector3(0, 0.30, -0.01), Vector3(0, 0.06, -0.01),
			Vector3(0, 0.05, 0.11), Vector3(0, 0.04, 0.18)]), PackedFloat32Array([0.085, 0.08, 0.065, 0.035]), 7),
			palette(&"fire_hair"), Vector3(x, 0, 0))
		add_part(leg, cyl(0.10, 0.09, 0.26, 7), bronze, Vector3(x, 0.24, 0.025), Vector3(-4, 0, 0),
			Vector3(1.0, 1.0, 0.9))
	# ---- Hips: dark leather apron-skirt, bronze belt with a buckle, hip quiver.
	add_part(hips, cyl(0.24, 0.33, 0.34, 9, false), leather, Vector3(0, 0.72, 0))
	add_part(hips, cyl(0.25, 0.25, 0.07, 9), bronze, Vector3(0, 0.88, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.9))
	add_part(hips, sphere(0.055, 6, 3), bronze, Vector3(0, 0.88, 0.23), Vector3.ZERO, Vector3(1.2, 1.0, 0.6))
	# ---- Back brazier: a bronze fire cup on a bracket rising behind the right shoulder (where the draw hand lights
	# each arrow); its flame is the only glow point, high up so it reads over the crowd.
	add_part(chest, _path("sb_bracket", PackedVector3Array([Vector3(0.10, 1.05, -0.22), Vector3(0.18, 1.28, -0.24),
		POT + Vector3(0, -0.07, 0)]), PackedFloat32Array([0.025, 0.022, 0.02]), 5), bronze, Vector3.ZERO)
	add_part(chest, cyl(0.10, 0.06, 0.12, 8, false), bronze, POT)
	add_part(chest, torus(0.085, 0.115, 8), bronze, POT + Vector3(0, 0.06, 0))
	add_part(chest, cyl(0.085, 0.065, 0.03, 8), hair, POT + Vector3(0, 0.03, 0))
	_pot_fire = add_part(chest, _flame_mesh(), flame, POT + Vector3(0, 0.05, 0), Vector3.ZERO, Vector3.ONE, true,
		"PotFire")
	_pot_fire.set_meta(&"own_glow", true)
	# Hip quiver behind the right hip: a leather tube leaning back, 3 thick arrows with red fletching (team cloth).
	var qa := Vector3(0.22, 0.80, -0.56).normalized()   # quiver axis, the mouth up and back
	var qc := Vector3(0.30, 0.78, -0.16)
	add_part(hips, cyl(0.075, 0.06, 0.46, 7), leather, qc, _euler_up(qa))
	add_part(hips, cyl(0.085, 0.085, 0.05, 7), bronze, qc + qa * 0.21, _euler_up(qa))
	add_part(hips, _quiver_arrows_mesh(qc + qa * 0.23, qa), wood, Vector3.ZERO)
	add_part(hips, _fletch_mesh(qc + qa * 0.23, qa), cloth, Vector3.ZERO)
	# ---- Chest: crimson team gambeson (lathe), bronze half-breastplate, team tabard, fur collar, left pauldron.
	add_part(chest, _path("sb_torso", PackedVector3Array([Vector3(0, 0.86, 0), Vector3(0, 1.00, 0.0),
		Vector3(0, 1.17, 0.01), Vector3(0, 1.30, 0.0), Vector3(0, 1.38, 0.0)]),
		PackedFloat32Array([0.22, 0.235, 0.27, 0.27, 0.17]), 8), cdark, Vector3.ZERO, Vector3.ZERO,
		Vector3(1.0, 1.0, 0.82))
	add_part(chest, sphere(0.25, 10, 5), bronze, Vector3(0, 1.14, 0.05), Vector3(-6, 0, 0), Vector3(1.0, 0.95, 0.78))
	add_part(chest, torus(0.20, 0.235, 10), leather, Vector3(0, 1.03, 0.03), Vector3(-6, 0, 0), Vector3(1.0, 1.4, 0.85))
	add_part(chest, cyl(0.07, 0.10, 0.32, 6), cdark, Vector3(0, 0.84, 0.215), Vector3(-8, 0, 0), Vector3(1.0, 1.0, 0.35))
	add_part(chest, torus(0.12, 0.23, 10), fur, Vector3(0, 1.36, 0.0), Vector3.ZERO, Vector3(1.0, 1.6, 0.9))
	# Big bronze pauldron on the bow shoulder: two stacked lames + a dark rim.
	add_part(chest, sphere(0.16, 8, 4), bronze, SH_L + Vector3(-0.04, 0.03, 0.0), Vector3(0, 0, 18),
		Vector3(1.15, 0.75, 1.1))
	add_part(chest, sphere(0.14, 8, 4), bronze, SH_L + Vector3(-0.09, -0.07, 0.0), Vector3(0, 0, 30),
		Vector3(1.05, 0.55, 1.05))
	# ---- Head: bearded face under a bronze kettle helm (dome + wide brim + a crest ridge), dark eye band.
	add_part(head, sphere(0.125, 8, 5), skin, Vector3(0, 1.53, 0.06))
	add_part(head, _path("sb_beard", PackedVector3Array([Vector3(0, 1.52, 0.10), Vector3(0, 1.44, 0.14),
		Vector3(0, 1.36, 0.13)]), PackedFloat32Array([0.10, 0.085, 0.0]), 7), hair, Vector3.ZERO, Vector3.ZERO,
		Vector3(1.0, 1.0, 0.8))
	add_part(head, box(Vector3(0.17, 0.035, 0.04)), palette(&"unit_eye_dark"), Vector3(0, 1.55, 0.175))
	add_part(head, sphere(0.155, 9, 5), bronze, Vector3(0, 1.60, 0.0), Vector3.ZERO, Vector3(1.0, 0.85, 1.05))
	add_part(head, cyl(0.34, 0.31, 0.04, 12), bronze, Vector3(0, 1.585, 0.01), Vector3(-6, 0, 0))
	# Crest ridge + a swept-back team horsehair plume (the head hook; the Ember Archer's hood point droops instead).
	add_part(head, _path("sb_ridge", PackedVector3Array([Vector3(0, 1.70, 0.12), Vector3(0, 1.75, 0.0),
		Vector3(0, 1.73, -0.12)]), PackedFloat32Array([0.02, 0.035, 0.03]), 5), bronze, Vector3.ZERO)
	add_part(head, _path("sb_plume", PackedVector3Array([Vector3(0, 1.74, -0.02), Vector3(0, 1.83, -0.10),
		Vector3(0, 1.86, -0.26), Vector3(0, 1.76, -0.42), Vector3(0, 1.56, -0.50)]),
		PackedFloat32Array([0.055, 0.08, 0.075, 0.055, 0.0]), 6), cloth, Vector3.ZERO, Vector3.ZERO, Vector3(0.65, 1.0, 1.0))
	var trim := add_part(head, torus(0.16, 0.20, 12), palette(&"unit_gold_trim"), Vector3(0, 1.66, 0.0),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: thick team sleeves, leather gloves, a leather bracer on the bow arm.
	_limb(arm_l, SH_L, GRIP_L, 0.08, cloth, 0.08, leather)
	var dl := (GRIP_L - SH_L).normalized()
	add_part(arm_l, cyl(0.09, 0.085, 0.18, 7), leather, SH_L.lerp(GRIP_L, 0.72), _euler_up(dl))
	_limb(arm_r, SH_R, HAND_R, 0.08, cloth, 0.08, leather)
	add_part(arm_r, sphere(0.10, 8, 4), cdark, SH_R + Vector3(0.03, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	# ---- The greatbow (keep_separate container under the bow arm, counter-rotated to stay upright on the draw).
	_bow = Node3D.new()
	_bow.name = "Bow"
	_bow.set_meta(&"keep_separate", true)
	_bow.position = GRIP_L - model_origin(arm_l)
	_bow.rotation_degrees = Vector3(BOW_TILT, 0, 0)
	arm_l.add_child(_bow)
	var body := MeshInstance3D.new()
	body.name = "BowBody"
	body.mesh = _bow_mesh(wood, bronze)
	body.set_meta(&"keep_separate", true)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_bow.add_child(body)
	_bstring = _bow_part(_string_mesh(), leather, "BowString")
	_string_drawn = _bow_part(_drawn_mesh(), leather, "StringDrawn")
	_barrow = _bow_part(_arrow_mesh(), wood, "Arrow")
	_arrow_fire = _bow_part(_flame_mesh(), flame, "ArrowFlame")
	_arrow_fire.position = ARROW_HEAD + Vector3(0, 0.0, 0.03)
	_arrow_fire.scale = Vector3(0.65, 0.8, 0.65)
	_arrow_fire.set_meta(&"own_glow", true)
	_string_drawn.visible = false
	_barrow.visible = false
	_arrow_fire.visible = false
	# ---- Fx: release embers off the bow front, FireModel's burn death (embers + ash), warm blob.
	_burst = make_motes(EMBER_C, 10, 0.4, 0.08, 3.0, 0.09, false, true)
	_burst.name = "ReleaseBurst"
	_burst.position = Vector3(0, 0.02, 0.36)
	_bow.add_child(_burst)
	var fx: Node3D = $Fx
	var be := make_motes(EMBER_C, 16, 0.9, 0.28, 1.4, 0.12, false, true)
	be.name = "BurnEmbers"
	be.position = Vector3(0, 0.8, 0)
	be.set_meta(&"burn_fx", true)
	fx.add_child(be)
	ensure_shadow_blob(0.44)


func _bow_part(mesh: Mesh, mat: Material, part_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"keep_separate", true)
	_bow.add_child(mi)
	return mi


## Capsule-ish limb from model point a to b (6-sided tube) + an end sphere (fist).
func _limb(pivot: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, end_r: float, end_mat: Material) -> void:
	var d := b - a
	add_part(pivot, cyl(r * 0.9, r, d.length(), 7), mat, a + d * 0.5, _euler_up(d.normalized()))
	add_part(pivot, sphere(end_r, 7, 4), end_mat, b)


static func _euler_up(dir: Vector3) -> Vector3:
	return Basis(Quaternion(Vector3.UP, dir.normalized())).get_euler() / DEG


# ================================================================ hooks

## World position where the arrow leaves the bow.
func get_bow_tip_position() -> Vector3:
	if _bow == null:
		return global_position + Vector3(0, 1.3, 0.4)
	return _bow.global_transform * Vector3(0, 0, 0.36)


# ================================================================ meshes (cached)

static func _path_into(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var extra: float = 0.02 if radii[i + 1] > 0.0 else 0.0
		var len_total := d.length() + extra
		st.append_from(cyl(radii[i + 1], radii[i], len_total, seg, false), 0,
			Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))


## Tapered tube through `pts`, cached by key.
static func _path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_path_into(st, pts, radii, seg)
	st.index()
	return _cached(key, st.commit())


## A fat central tongue and three lower tongues leaning out (origin at the coal bed, +Y up).
static func _flame_mesh() -> Mesh:
	const KEY := "sb_flame"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.append_from(cyl(0.0, 0.085, 0.30, 6), 0, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6.0)), Vector3(0, 0.15, 0)))
	var hs: Array[float] = [0.20, 0.15, 0.17]
	for k: int in 3:
		var a: float = TAU * k / 3.0 + 0.4
		var b := Basis(Vector3(-sin(a), 0, cos(a)), deg_to_rad(-18.0 - 6.0 * k))
		st.append_from(cyl(0.0, 0.045, hs[k], 5), 0, Transform3D(b, Vector3(cos(a) * 0.05, hs[k] * 0.5, sin(a) * 0.05)))
	st.index()
	return _cached(KEY, st.commit())


## 3 thick arrow shafts poking out of the hip quiver (model space).
static func _quiver_arrows_mesh(top: Vector3, qa: Vector3) -> Mesh:
	const KEY := "sb_qarrows"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var offs: Array[Vector3] = [Vector3(0.03, 0, 0.02), Vector3(-0.03, 0, 0.0), Vector3(0.0, 0, -0.03)]
	var lens: Array[float] = [0.20, 0.26, 0.23]
	for i: int in 3:
		var a: Vector3 = top + offs[i]
		_path_into(st, PackedVector3Array([a - qa * 0.05, a + qa * lens[i]]), PackedFloat32Array([0.017, 0.017]), 4)
	st.index()
	return _cached(KEY, st.commit())


## Red fletching vanes on the 3 quiver arrows (team cloth).
static func _fletch_mesh(top: Vector3, qa: Vector3) -> Mesh:
	const KEY := "sb_qfletch"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var offs: Array[Vector3] = [Vector3(0.03, 0, 0.02), Vector3(-0.03, 0, 0.0), Vector3(0.0, 0, -0.03)]
	var lens: Array[float] = [0.20, 0.26, 0.23]
	var b := Basis(Quaternion(Vector3.UP, qa))
	for i: int in 3:
		var c: Vector3 = top + offs[i] + qa * (lens[i] - 0.06)
		st.append_from(box(Vector3(0.09, 0.13, 0.012)), 0, Transform3D(b * Basis(Vector3.UP, 0.4 * i), c))
	st.index()
	return _cached(KEY, st.commit())


## Two surfaces: the dark-wood recurve limbs with bronze horn caps (surface 0 wood, 1 bronze).
static func _bow_mesh(wood: Material, bronze: Material) -> Mesh:
	const KEY := "sb_bow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [1.0, -1.0]:
		var L: float = 1.0 if s > 0.0 else 0.93
		var pts := PackedVector3Array([Vector3(0, 0.0, 0.03), Vector3(0, 0.26 * L * s, 0.01),
			Vector3(0, 0.52 * L * s, -0.07), Vector3(0, 0.76 * L * s, -0.16), Vector3(0, 0.92 * L * s, -0.21),
			Vector3(0, 1.0 * L * s, -0.17)])
		_path_into(st, pts, PackedFloat32Array([0.065, 0.058, 0.048, 0.038, 0.03, 0.026]), 6)
	st.index()
	var m: ArrayMesh = st.commit()
	m.surface_set_material(0, wood)
	var st2 := SurfaceTool.new()
	st2.append_from(cyl(0.075, 0.075, 0.26, 6), 0, Transform3D.IDENTITY)
	for s: float in [1.0, -1.0]:
		var L: float = 1.0 if s > 0.0 else 0.93
		var tip := Vector3(0, 1.0 * L * s, -0.17)
		# bronze horn cap curling forward past the tip
		_path_into(st2, PackedVector3Array([tip, tip + Vector3(0, 0.07 * s, 0.05), tip + Vector3(0, 0.09 * s, 0.13)]),
			PackedFloat32Array([0.04, 0.032, 0.0]), 5)
		st2.append_from(cyl(0.05, 0.05, 0.05, 6), 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.36 * L * s, -0.03)))
	st2.index()
	st2.commit(m)
	m.surface_set_material(1, bronze)
	return _cached(KEY, m)


static func _string_mesh() -> Mesh:
	const KEY := "sb_string"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, TIP_D]), PackedFloat32Array([0.016, 0.016]), 4)
	st.index()
	return _cached(KEY, st.commit())


static func _drawn_mesh() -> Mesh:
	const KEY := "sb_string_drawn"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, NOCK, TIP_D]), PackedFloat32Array([0.016, 0.018, 0.016]), 4)
	st.index()
	return _cached(KEY, st.commit())


## Heavy arrow: a thick shaft from the nock past the grip, a dark pitch-wrapped head.
static func _arrow_mesh() -> Mesh:
	const KEY := "sb_arrow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([NOCK, ARROW_HEAD]), PackedFloat32Array([0.02, 0.02]), 5)
	st.append_from(sphere(0.045, 6, 3), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1, 1.6)), ARROW_HEAD))
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ motion

func _sb_drawn(on: bool) -> void:
	if on == _drawn_on or _bstring == null:
		return
	_drawn_on = on
	_bstring.visible = not on
	_string_drawn.visible = on
	_barrow.visible = on
	_arrow_fire.visible = on


func _set_bow_x(arm_deg: float) -> void:
	# keeps the bow upright whatever the bow arm does (the arm's X rotation is undone on the Bow node)
	var x: float = BOW_TILT - arm_deg
	if absf(x - _bow_x_written) < 0.01 or _bow == null:
		return
	_bow_x_written = x
	_bow.rotation.x = x * DEG


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"bow_draw":
		return super(prev, t)
	var al := _kf(t, S_ARM_L)
	var yaw := _kf(t, S_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(0, yaw * DEG, 0))
	rot(P_HEAD, Vector3(0, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_kf(t, S_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, S_ARM_RZ)))
	pos(P_ROOT, Vector3(0, 0, _kf(t, S_ROOT_Z)))
	var st: float = yaw / 30.0   # stance: the front foot steps out, the back leg braces
	rot(P_LEG_L, Vector3(-18.0 * DEG * st, 0, -6.0 * DEG * st))
	rot(P_LEG_R, Vector3(14.0 * DEG * st, 0, 6.0 * DEG * st))
	rot(P_ROOT, Vector3(_kf(t, S_ROOT_X) * DEG, 0, 0))
	_set_bow_x(al)
	_sb_drawn(t > 0.04 and t < RELEASE)
	_charge = clampf(t / RELEASE, 0.0, 1.0) if t < RELEASE else 0.0
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	var al := _kf(t, C_ARM_L)
	var yaw := _kf(t, C_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(_kf(t, C_CHEST_X) * DEG, yaw * DEG, 0))
	rot(P_HEAD, Vector3(-12.0 * DEG * clampf(t / 0.3, 0.0, 1.0) * (1.0 - smoothstep(0.75, 1.0, t)), -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_kf(t, C_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, C_ARM_RZ)))
	_set_bow_x(al + 30.0 * clampf(t / 0.3, 0.0, 1.0) * (1.0 - smoothstep(0.75, 1.0, t)))
	_sb_drawn(t > 0.12 and t < CAST_RELEASE)
	_charge = clampf((t - 0.2) / (CAST_RELEASE - 0.2), 0.0, 1.0) * 1.6 if t < CAST_RELEASE else 0.0
	if t >= CAST_RELEASE and not _cast_loosed:
		_cast_loosed = true
		_loose(1.6)
	return CAST_LEN


func _loose(amount: float) -> void:
	_flare = amount
	_charge = 0.0
	_sb_drawn(false)
	if _burst and _tier < 2:
		_burst.restart()


func _on_action_event(ev: StringName) -> void:
	super(ev)
	if ev == &"release":
		_loose(1.0)
	elif ev == &"cast_start":
		_cast_loosed = false
	elif ev == &"attack_end" or ev == &"cast_end" or ev == &"death_glow_off":
		_sb_drawn(false)
		_charge = 0.0
		_set_bow_x(0.0)


## Heavy march: the kit swings the bow arm -18 deg, keep the long bow calm (net -5) so it does not paddle the ground.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	rot(P_ARM_L, Vector3(13.0 * DEG * sin(TAU * _walk_p) * w, 0, 0))


func _extra_process(dt: float) -> void:
	super(dt)
	if _pot_fire == null:
		return
	if _dead:
		# The pot gutters out with the burn.
		var k: float = 1.0 - smoothstep(0.1, 0.5, _death_t)
		_pot_fire.scale = Vector3(k, k, k) + Vector3(0.001, 0.001, 0.001)
		_write_fire(k, 0.0)
		if _drawn_on:
			_sb_drawn(false)
		return
	if _action == &"":
		if _drawn_on:
			_sb_drawn(false)
		_set_bow_x(0.0)
		_charge = 0.0
	_flare = maxf(0.0, _flare - dt / 0.35)
	if _tier == 0:
		var fl: float = 0.10 * sin(_t * 13.0 + _phase_off * 5.0) + 0.06 * sin(_t * 7.3 + 1.1)
		_pot_fire.scale = Vector3(1.0 - fl * 0.5, 1.0 + fl, 1.0 - fl * 0.5)
	_write_fire(1.0 + 0.6 * _flare, 1.3 + 1.2 * _charge)


func _on_revive() -> void:
	super()
	_flare = 0.0
	_charge = 0.0
	_pot_written = -1.0
	_arrow_written = -1.0
	_drawn_on = true
	_sb_drawn(false)
	_set_bow_x(0.0)
	if _pot_fire:
		_pot_fire.scale = Vector3.ONE


## Own glows (the kit does not boost them): x veterancy / haste, 0 when dead.
func _write_fire(pot: float, arrow: float) -> void:
	var g := glow_level()
	var p: float = snappedf(pot * g, 0.05)
	if p != _pot_written:
		_pot_written = p
		_pot_fire.set_instance_shader_parameter(&"glow_boost", p)
	var a: float = snappedf(arrow * g, 0.05)
	if a != _arrow_written and _arrow_fire:
		_arrow_written = a
		_arrow_fire.set_instance_shader_parameter(&"glow_boost", a)
