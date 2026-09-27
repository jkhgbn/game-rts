extends IceModel
## Frostbow, Ice T2 marksman (rush-balance.md 5.1 / 5.4; Art Lab v3 phase 4.2, medium effort). Height 1.7, range 12.
## A tall slim hooded archer: dark fur legs in tall boots with pale fur cuffs, a leather jerkin with a team tabard
## strip, a team capelet + short dark back cape, a deep ROUNDED team hood framed by a pale fur ring and a pale fur
## face scarf (the Shardcaster's hood is pointed, the Rifleman wears a wide pale mantle), a silver archer's bracer on
## the bow arm, a leather quiver across the back with 3 crystal arrow heads over the right shoulder.
## The silhouette hook: a LONG ICE LONGBOW (1.95 m, taller than the body) held upright in the left hand, faceted ice
## limbs with a recurve and ice-shard tips, a leather grip. Its STRING is the only glow point (own glow): bright and
## slowly pulsing while Hamstring Shot is ready, dim while it cools down.
## Attack `bow_draw` (0.6 s, release 0.15): the bow arm snaps up level (the bow stays upright), the body turns side-on,
## the right hand draws a crystal arrow to the chin (V string), looses at 0.15 (motes burst off the bow, the string
## flares), the hand flies back. play_cast (any id, e.g. &"hamstring_shot", 1.0 s): a slow full draw, the string
## charges up, looses at 0.65 with a bigger flare.
## Hooks (plus every kit / Ice hook): set_hamstring_ready(on) / set_status(&"hamstring_ready", on) -> true,
## get_bow_tip_position() -> Vector3 (world; where the arrow leaves).
## Draws: merged pivots + Bow (2 surfaces) + String + StringDrawn + Arrow (hidden at rest) + VetTrim + blob.

const ATTACK_LEN := 0.6
const RELEASE := 0.15
const CAST_LEN := 1.0
const CAST_RELEASE := 0.65
const BOW_TILT := 8.0                            # deg, rest: the top of the bow leans forward a little
const GRIP_L := Vector3(-0.35, 0.97, 0.10)       # model space: the left fist = the Bow node origin
const HAND_R := Vector3(0.34, 0.93, 0.05)
const SH_L := Vector3(-0.27, 1.31, 0.0)
const SH_R := Vector3(0.27, 1.31, 0.0)
# bow space (origin = grip, +Y up the bow, -Z toward the archer = string side)
const TIP_U := Vector3(0.0, 1.00, -0.15)
const TIP_D := Vector3(0.0, -0.95, -0.15)
const NOCK := Vector3(0.0, 0.0, -0.50)
const ARROW_HEAD := Vector3(0.0, 0.0, 0.34)
const GLOW_READY := 1.6
const GLOW_COOL := 0.45

# bow_draw tracks [t, value, ease] (0 smooth, 1 ease-out, 2 ease-in). Arm x: negative raises forward.
static var A_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.10, -84.0, 1, 0.36, -80.0, 0, 0.60, 0.0, 0])
static var A_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.10, 26.0, 1, 0.36, 24.0, 0, 0.60, 0.0, 0])
static var A_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -78.0, 1, 0.15, -84.0, 0, 0.22, -66.0, 1, 0.60, 0.0, 0])
static var A_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.30, 1, 0.15, -0.44, 2, 0.22, -0.54, 1, 0.60, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.15, 0.0, 0, 0.20, -0.06, 1, 0.60, 0.0, 0])
# Hamstring Shot: slow full draw, hold, loose at 0.65.
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.25, -86.0, 1, 0.80, -82.0, 0, 1.0, 0.0, 0])
static var C_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.25, 30.0, 1, 0.80, 26.0, 0, 1.0, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.25, -78.0, 1, 0.60, -88.0, 0, 0.72, -64.0, 1, 1.0, 0.0, 0])
static var C_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.25, -0.26, 1, 0.60, -0.48, 2, 0.72, -0.58, 1, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -6.0, 0, 0.60, -8.0, 0, 0.72, 4.0, 1, 1.0, 0.0, 0])

var _bow: Node3D
var _string: GeometryInstance3D
var _string_drawn: GeometryInstance3D
var _arrow: GeometryInstance3D
var _burst: GPUParticles3D
var _drawn_on: bool = false
var _cast_loosed: bool = false
var _ready_on: bool = true
var _flare: float = 0.0
var _charge: float = 0.0
var _str_glow_written: float = -1.0
var _bow_x_written: float = 999.0


func _build_parts() -> void:
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := ice(&"ice_cloth")
	var cdark := ice(&"ice_cloth_dark")
	var skin := ice(&"ice_skin")
	var leather := ice(&"ice_leather")
	var fur := ice(&"ice_fur")
	var pale := ice(&"ice_fur_pale")
	var metal := ice(&"ice_metal")
	var frost := ice(&"ice_frost_crystal")
	var glow := ice(&"ice_glow_unit")
	# ---- Legs: long dark fur legs, tall leather boots with pale fur cuffs.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		var x: float = 0.11 * sx
		add_part(leg, _path("fb_thigh", PackedVector3Array([Vector3(0, 0.88, 0), Vector3(0, 0.62, 0.02),
			Vector3(0, 0.38, 0.0)]), PackedFloat32Array([0.095, 0.08, 0.07]), 11), fur, Vector3(x, 0, 0))
		add_part(leg, _path("fb_boot", PackedVector3Array([Vector3(0, 0.40, -0.01), Vector3(0, 0.22, 0.0),
			Vector3(0, 0.06, -0.01), Vector3(0, 0.05, 0.10), Vector3(0, 0.035, 0.17)]),
			PackedFloat32Array([0.095, 0.085, 0.075, 0.06, 0.03]), 11), leather, Vector3(x, 0, 0))
		add_part(leg, cyl(0.115, 0.105, 0.08, 9), pale, Vector3(x, 0.39, 0.0), Vector3(-6, 0, 0))
	# ---- Chest: leather jerkin (lathe), short team-dark skirt, team tabard strip, silver belt, team capelet, short
	# rounded dark back cape, leather quiver across the back with 3 crystal arrow heads over the right shoulder.
	add_part(chest, _path("fb_torso", PackedVector3Array([Vector3(0, 0.86, 0), Vector3(0, 1.00, 0.0),
		Vector3(0, 1.16, 0.01), Vector3(0, 1.28, 0.0), Vector3(0, 1.36, 0.0)]),
		PackedFloat32Array([0.19, 0.20, 0.235, 0.24, 0.16]), 12), leather, Vector3.ZERO, Vector3.ZERO,
		Vector3(1.0, 1.0, 0.85))
	add_part(chest, cyl(0.20, 0.27, 0.30, 12, false), cdark, Vector3(0, 0.80, -0.01), Vector3(5, 0, 0))
	add_part(chest, box(Vector3(0.15, 0.64, 0.04)), cloth, Vector3(0, 0.95, 0.19), Vector3(-4, 0, 0))
	add_part(chest, cyl(0.205, 0.205, 0.06, 9), metal, Vector3(0, 0.91, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.88))
	add_part(chest, cyl(0.14, 0.33, 0.20, 12), cloth, Vector3(0, 1.26, 0), Vector3(-5, 0, 4))
	add_part(chest, _path("fb_cape", PackedVector3Array([Vector3(0, 0.36, 0), Vector3(0, 0.0, -0.03),
		Vector3(0, -0.34, -0.08)]), PackedFloat32Array([0.21, 0.24, 0.27]), 12), cdark, Vector3(0, 0.94, -0.22),
		Vector3(8, 0, 0), Vector3(1.0, 1.0, 0.16))
	var qdir := Vector3(0.42, 0.906, 0.0)
	add_part(chest, cyl(0.075, 0.065, 0.56, 6), leather, Vector3(0.07, 1.10, -0.30), Vector3(0, 0, -25))
	add_part(chest, cyl(0.085, 0.085, 0.06, 6), metal, Vector3(0.07, 1.10, -0.30) + qdir * 0.25, Vector3(0, 0, -25))
	var qtop := Vector3(0.07, 1.10, -0.30) + qdir * 0.28
	add_crystal(chest, qtop + Vector3(-0.03, 0, 0.02), Vector3(0.30, 1.0, 0.05), 0.035, 0.20, frost, 0.6)
	add_crystal(chest, qtop + Vector3(0.03, -0.01, -0.02), Vector3(0.55, 1.0, -0.10), 0.03, 0.17, frost, 0.6)
	add_crystal(chest, qtop + Vector3(0.0, -0.02, 0.04), Vector3(0.45, 1.0, 0.25), 0.03, 0.15, frost, 0.6)
	# ---- Head: face, pale fur scarf, deep rounded team hood with a forward brim, pale fur ring framing the face,
	# dark eye band.
	add_part(head, sphere(0.12, 8, 5), skin, Vector3(0, 1.52, 0.055))
	add_part(head, cyl(0.12, 0.145, 0.12, 8), cdark, Vector3(0, 1.45, 0.04), Vector3(8, 0, 0))
	add_part(head, sphere(0.18, 12, 6), cloth, Vector3(0, 1.56, -0.04), Vector3(-10, 0, 0), Vector3(1.0, 1.12, 1.1))
	add_part(head, cyl(0.0, 0.09, 0.20, 6), cloth, Vector3(0, 1.62, -0.24), Vector3(-115, 0, 0))
	add_part(head, torus(0.10, 0.145, 10), pale, Vector3(0, 1.54, 0.12), Vector3(80, 0, 0), Vector3(1.0, 1.0, 1.15))
	for ex: float in [-0.045, 0.045]:
		add_part(head, box(Vector3(0.045, 0.025, 0.04)), palette(&"unit_eye_dark"), Vector3(ex, 1.535, 0.165))
	var trim := add_part(head, torus(0.15, 0.19, 12), palette(&"unit_gold_trim"), Vector3(0, 1.66, -0.04),
		Vector3(-10, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: dark sleeves, leather gloves, silver bracer on the bow arm.
	var elb_l := Vector3(-0.33, 1.12, -0.02)
	add_part(arm_l, _path("fb_arm_l", PackedVector3Array([SH_L, elb_l, GRIP_L]),
		PackedFloat32Array([0.078, 0.066, 0.058]), 11), cdark, Vector3.ZERO)
	add_part(arm_l, sphere(0.072, 7, 4), leather, GRIP_L)
	var dl := (GRIP_L - elb_l).normalized()
	var el := Basis(Quaternion(Vector3.UP, dl)).get_euler() * (180.0 / PI)
	add_part(arm_l, cyl(0.082, 0.072, 0.17, 7), metal, elb_l.lerp(GRIP_L, 0.55), el)
	var elb_r := Vector3(0.34, 1.11, -0.04)
	add_part(arm_r, _path("fb_arm_r", PackedVector3Array([SH_R, elb_r, HAND_R]),
		PackedFloat32Array([0.078, 0.066, 0.058]), 11), cdark, Vector3.ZERO)
	add_part(arm_r, sphere(0.072, 7, 4), leather, HAND_R)
	var dr := (HAND_R - elb_r).normalized()
	add_part(arm_r, cyl(0.075, 0.068, 0.10, 7), leather, elb_r.lerp(HAND_R, 0.75),
		Basis(Quaternion(Vector3.UP, dr)).get_euler() * (180.0 / PI))
	add_part(arm_r, sphere(0.10, 8, 4), cloth, SH_R + Vector3(0.02, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	add_part(arm_l, sphere(0.10, 8, 4), cloth, SH_L + Vector3(-0.02, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	# ---- The longbow (keep_separate container under the bow arm, counter-rotated to stay upright on the draw).
	_bow = Node3D.new()
	_bow.name = "Bow"
	_bow.set_meta(&"keep_separate", true)
	_bow.position = GRIP_L - model_origin(arm_l)
	_bow.rotation_degrees = Vector3(BOW_TILT, 0, 0)
	arm_l.add_child(_bow)
	var body := MeshInstance3D.new()
	body.name = "BowBody"
	body.mesh = _bow_mesh(frost, leather)
	body.set_meta(&"keep_separate", true)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_bow.add_child(body)
	_string = _bow_part(_string_mesh(), glow, "String")
	_string_drawn = _bow_part(_drawn_mesh(), glow, "StringDrawn")
	_arrow = _bow_part(_arrow_mesh(), frost, "Arrow")
	_string.set_meta(&"own_glow", true)
	_string_drawn.set_meta(&"own_glow", true)
	_string_drawn.visible = false
	_arrow.visible = false
	# ---- Fx: release motes off the bow front, breath, hit chips, shatter death, cool blob.
	_burst = make_motes(ICE_GLOW, 8, 0.35, 0.08, 3.0, 0.08, false, true)
	_burst.name = "ReleaseBurst"
	_burst.position = Vector3(0, 0.02, 0.30)
	_bow.add_child(_burst)
	add_breath(Vector3(0, 1.47, 0.22), 0.18)
	add_hit_chips(Vector3(0, 1.15, 0.1), 6)
	add_shatter(Vector3(0, 0.9, 0), 12, 0.3, 0.10)
	ensure_shadow_blob(0.42, BLOB_TINT)


func _bow_part(mesh: Mesh, mat: Material, part_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"keep_separate", true)
	_bow.add_child(mi)
	return mi


# ================================================================ hooks

func set_hamstring_ready(on: bool) -> void:
	_ready_on = on


func set_status(id: StringName, on: bool) -> bool:
	if id == &"hamstring_ready":
		set_hamstring_ready(on)
		return true
	return super.set_status(id, on)


## World position where the arrow leaves the bow.
func get_bow_tip_position() -> Vector3:
	if _bow == null:
		return global_position + Vector3(0, 1.3, 0.4)
	return _bow.global_transform * Vector3(0, 0, 0.35)


# ================================================================ meshes (cached, bow space)

static func _path_into(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := b - a
		var extra: float = 0.02 if radii[i + 1] > 0.0 else 0.0
		var basis := Basis(Quaternion(Vector3.UP, d.normalized()))
		var len_total := d.length() + extra
		st.append_from(cyl(radii[i + 1], radii[i], len_total, seg, false), 0,
			Transform3D(basis, a + d.normalized() * len_total * 0.5))


## Tapered tube / lathe through `pts` (model-space offsets), cached by key.
static func _path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int, caps: bool = false) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_path_into(st, pts, radii, seg)
	if caps:
		st.append_from(cyl(radii[0], radii[0], 0.005, seg), 0, Transform3D(Basis.IDENTITY, pts[0]))
		var n := pts.size() - 1
		var d := (pts[n] - pts[n - 1]).normalized()
		st.append_from(cyl(radii[n], radii[n], 0.005, seg), 0, Transform3D(Basis(Quaternion(Vector3.UP, d)), pts[n]))
	st.index()
	return _cached(key, st.commit())


## Two surfaces: the faceted ice limbs (recurve, shard tips) and the leather grip with silver rings.
static func _bow_mesh(frost: Material, leather: Material) -> Mesh:
	const KEY := "fb_bow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [1.0, -1.0]:
		var L: float = 1.0 if s > 0.0 else 0.95
		var pts := PackedVector3Array([Vector3(0, 0.0, 0.02), Vector3(0, 0.26 * L * s, 0.0),
			Vector3(0, 0.52 * L * s, -0.07), Vector3(0, 0.76 * L * s, -0.15), Vector3(0, 0.92 * L * s, -0.19),
			Vector3(0, 1.0 * L * s, -0.15)])
		_path_into(st, pts, PackedFloat32Array([0.055, 0.05, 0.043, 0.034, 0.026, 0.022]), 6)
		# ice shard at the tip, pointing on along the recurve
		var tip := Vector3(0, 1.0 * L * s, -0.15)
		var dir := (tip - Vector3(0, 0.92 * L * s, -0.19)).normalized()
		st.append_from(cyl(0.0, 0.035, 0.16, 6), 0,
			Transform3D(Basis(Quaternion(Vector3.UP, dir)), tip + dir * 0.07))
		# a small crystal fin on the back of each limb (chunky read at 40 m)
		var fin := Vector3(0, 0.40 * L * s, 0.0)
		st.append_from(cyl(0.0, 0.04, 0.14, 6), 0,
			Transform3D(Basis(Quaternion(Vector3.UP, Vector3(0, 0.35 * s, 1.0).normalized())), fin + Vector3(0, 0.02 * s, 0.06)))
	st.index()
	var m: ArrayMesh = st.commit()
	m.surface_set_material(0, frost)
	var st2 := SurfaceTool.new()
	st2.append_from(cyl(0.066, 0.066, 0.24, 6), 0, Transform3D.IDENTITY)
	st2.append_from(cyl(0.072, 0.072, 0.035, 6), 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.13, 0)))
	st2.append_from(cyl(0.072, 0.072, 0.035, 6), 0, Transform3D(Basis.IDENTITY, Vector3(0, -0.13, 0)))
	st2.index()
	st2.commit(m)
	m.surface_set_material(1, leather)
	return _cached(KEY, m)


static func _string_mesh() -> Mesh:
	const KEY := "fb_string"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, TIP_D]), PackedFloat32Array([0.017, 0.017]), 5)
	st.index()
	return _cached(KEY, st.commit())


static func _drawn_mesh() -> Mesh:
	const KEY := "fb_string_drawn"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, NOCK, TIP_D]), PackedFloat32Array([0.017, 0.02, 0.017]), 5)
	st.index()
	return _cached(KEY, st.commit())


## Crystal arrow: thin shaft from the nock to past the grip, a faceted head.
static func _arrow_mesh() -> Mesh:
	const KEY := "fb_arrow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([NOCK, ARROW_HEAD]), PackedFloat32Array([0.016, 0.016]), 5)
	st.append_from(cyl(0.0, 0.04, 0.14, 6), 0,
		Transform3D(Basis(Quaternion(Vector3.UP, Vector3.BACK)), ARROW_HEAD + Vector3(0, 0, 0.06)))
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ motion

static func _fb_kf(t: float, k: PackedFloat32Array) -> float:
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


func _set_drawn(on: bool) -> void:
	if on == _drawn_on or _string == null:
		return
	_drawn_on = on
	_string.visible = not on
	_string_drawn.visible = on
	_arrow.visible = on


func _set_bow_x(arm_deg: float) -> void:
	# keeps the bow upright whatever the bow arm does (the arm's X rotation is undone on the Bow node)
	var x: float = BOW_TILT - arm_deg
	if absf(x - _bow_x_written) < 0.01 or _bow == null:
		return
	_bow_x_written = x
	_bow.rotation.x = x * DEG


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"bow_draw":
		return super._pose_attack(prev, t)
	var al := _fb_kf(t, A_ARM_L)
	var yaw := _fb_kf(t, A_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(0, yaw * DEG, 0))
	rot(P_HEAD, Vector3(0, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_fb_kf(t, A_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _fb_kf(t, A_ARM_RZ)))
	pos(P_ROOT, Vector3(0, 0, _fb_kf(t, A_ROOT_Z)))
	var st: float = yaw / 26.0   # stance: the front foot steps out, the back leg braces
	rot(P_LEG_L, Vector3(-16.0 * DEG * st, 0, -6.0 * DEG * st))
	rot(P_LEG_R, Vector3(12.0 * DEG * st, 0, 6.0 * DEG * st))
	rot(P_ROOT, Vector3(-5.0 * DEG * st, 0, 0))
	_set_bow_x(al)
	_set_drawn(t > 0.04 and t < RELEASE)
	_charge = clampf(t / RELEASE, 0.0, 1.0) if t < RELEASE else 0.0
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	var al := _fb_kf(t, C_ARM_L)
	var yaw := _fb_kf(t, C_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(_fb_kf(t, C_CHEST_X) * DEG, yaw * DEG, 0))
	rot(P_HEAD, Vector3(0, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_fb_kf(t, C_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _fb_kf(t, C_ARM_RZ)))
	_set_bow_x(al)
	_set_drawn(t > 0.12 and t < CAST_RELEASE)
	_charge = clampf((t - 0.2) / (CAST_RELEASE - 0.2), 0.0, 1.0) * 1.6 if t < CAST_RELEASE else 0.0
	if t >= CAST_RELEASE and not _cast_loosed:
		_cast_loosed = true
		_loose(1.6)
	return CAST_LEN


func _loose(amount: float) -> void:
	_flare = amount
	_charge = 0.0
	_set_drawn(false)
	if _burst and _tier < 2:
		_burst.restart()


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_loose(1.0)
	elif ev == &"cast_start":
		_cast_loosed = false
	elif ev == &"attack_end" or ev == &"cast_end" or ev == &"death_glow_off":
		_set_drawn(false)
		_charge = 0.0
		_set_bow_x(0.0)


func _ice_process(dt: float) -> void:
	if _dead or _action == &"" or _action == &"fidget":
		if _drawn_on:
			_set_drawn(false)
		if _action != &"fidget":
			_set_bow_x(0.0)
		_charge = 0.0
	if _walk_w > 0.0 and not _dead:
		# the kit swings the bow arm -18 deg: keep the long bow calm (net -5), it would paddle the ground
		rot(P_ARM_L, Vector3(13.0 * DEG * sin(TAU * _walk_p) * _walk_w, 0, 0))
	_flare = maxf(0.0, _flare - dt / 0.35)
	if _string:
		var base: float = GLOW_READY if _ready_on else GLOW_COOL
		if _ready_on and _tier == 0:
			base += 0.3 * (0.5 + 0.5 * sin(_t * 3.0 + _phase_off * 6.0))   # pulses up, never below the ready level
		var b: float = glow_level() * (base + 1.4 * _charge + 2.2 * _flare)
		if absf(b - _str_glow_written) > 0.04:
			_str_glow_written = b
			_string.set_instance_shader_parameter(&"glow_boost", b)
			_string_drawn.set_instance_shader_parameter(&"glow_boost", b)


func _ice_revive() -> void:
	_flare = 0.0
	_charge = 0.0
	_str_glow_written = -1.0
	_set_drawn(false)
	_set_bow_x(0.0)


## Fidget: lifts the bow before the face, looks along it and plucks the string (a glint).
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.35, 0.95, 1.4, 1.0, 1.0)
	var al := -38.0 * k
	rot(P_ARM_L, Vector3(al * DEG, 0, 0))
	_set_bow_x(al * 0.7)
	rot(P_HEAD, Vector3(6.0 * DEG * k, -18.0 * DEG * k, 0))
	rot(P_ARM_R, Vector3(-30.0 * DEG * k, 0, 0))
	if t > 0.6 and t < 0.7:
		_flare = maxf(_flare, 0.6)
	if t >= 1.35:
		_set_bow_x(0.0)
	return 1.4
