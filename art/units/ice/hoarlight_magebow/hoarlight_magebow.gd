extends IceModel
## Hoarlight Magebow, Ice T2 mage-archer (new-units-12.md 6; tiers wave, medium). Height 1.7, range 9.5.
## A slim mage in a long team coat (dark coat tails, silver belt and rune gorget), a short dark cape with a pale fur
## collar, a leather rune-tome at the right hip, a team hood with a forward peak and a silver circlet crowned by
## 3 ice crystals (the crest; the Frostbow has a round hood, the Shardcaster a tall pointed one).
## The silhouette hook: a BOW OF LIGHT, a canted glass-rune stave (1.5 m, faceted ice limbs whose tips curl FORWARD,
## silver rune rings, forked ends) held in the left hand. It has NO string at rest: on the draw a glowing string of
## light and a light arrow appear between the forks. Glow points: the rune crystal at the upper fork (own glow,
## pulses; charges on the draw, flares at the release) + the string / arrow while drawn.
## Attack `light_draw` (0.6 s, release 0.15): bow arm up level (the stave stays upright), body side-on, the right
## hand draws the light string to the chin, looses. play_cast(&"frost_needle") 1.0 s: slow full draw, bigger flare.
## Hooks: kit + Ice hooks, get_bow_tip_position() -> Vector3 (world; where the needle leaves).

const ATTACK_LEN := 0.6
const RELEASE := 0.15
const CAST_LEN := 1.0
const CAST_RELEASE := 0.65
const BOW_TILT := 6.0
const BOW_CANT := -14.0                          # deg: the stave leans outward (to the left) at rest
const GRIP_L := Vector3(-0.34, 0.96, 0.10)
const HAND_R := Vector3(0.32, 0.93, 0.05)
const SH_L := Vector3(-0.25, 1.30, 0.0)
const SH_R := Vector3(0.25, 1.30, 0.0)
# bow space (origin = grip, +Y up the stave, +Z away from the archer)
const TIP_U := Vector3(0.0, 0.86, 0.15)
const TIP_D := Vector3(0.0, -0.74, 0.13)
const NOCK := Vector3(0.0, 0.0, -0.48)
const ARROW_HEAD := Vector3(0.0, 0.0, 0.42)
const RUNE_BASE := 1.25

static var A_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.10, -84.0, 1, 0.36, -80.0, 0, 0.60, 0.0, 0])
static var A_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.10, 28.0, 1, 0.36, 24.0, 0, 0.60, 0.0, 0])
static var A_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -78.0, 1, 0.15, -86.0, 0, 0.22, -60.0, 1, 0.60, 0.0, 0])
static var A_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.30, 1, 0.15, -0.44, 2, 0.22, -0.56, 1, 0.60, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.15, 0.0, 0, 0.20, -0.07, 1, 0.60, 0.0, 0])
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.25, -88.0, 1, 0.80, -82.0, 0, 1.0, 0.0, 0])
static var C_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.25, 32.0, 1, 0.80, 26.0, 0, 1.0, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.25, -78.0, 1, 0.60, -90.0, 0, 0.72, -62.0, 1, 1.0, 0.0, 0])
static var C_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.25, -0.26, 1, 0.60, -0.50, 2, 0.72, -0.60, 1, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -8.0, 0, 0.60, -10.0, 0, 0.72, 4.0, 1, 1.0, 0.0, 0])

var _bow: Node3D
var _rune: GeometryInstance3D
var _string: GeometryInstance3D
var _arrow: GeometryInstance3D
var _burst: GPUParticles3D
var _drawn_on: bool = false
var _cast_loosed: bool = false
var _flare: float = 0.0
var _charge: float = 0.0
var _rune_written: float = -1.0
var _str_written: float = -1.0
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
	var pale := ice(&"ice_fur_pale")
	var metal := ice(&"ice_metal")
	var steel := ice(&"ice_steel")
	var frost := ice(&"ice_frost_crystal")
	var glow := ice(&"ice_glow_unit")
	# ---- Legs: slim team-dark legs, tall leather boots, pale fur cuffs.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		var x: float = 0.10 * sx
		add_part(leg, _path("hmb_thigh", PackedVector3Array([Vector3(0, 0.88, 0), Vector3(0, 0.62, 0.02),
			Vector3(0, 0.38, 0.0)]), PackedFloat32Array([0.085, 0.072, 0.062]), 7), cdark, Vector3(x, 0, 0))
		add_part(leg, _path("hmb_boot", PackedVector3Array([Vector3(0, 0.40, -0.01), Vector3(0, 0.20, 0.0),
			Vector3(0, 0.06, -0.01), Vector3(0, 0.045, 0.11), Vector3(0, 0.035, 0.18)]),
			PackedFloat32Array([0.078, 0.07, 0.068, 0.055, 0.03]), 7), leather, Vector3(x, 0, 0))
		add_part(leg, fur_ring(0.09, 0.11, 0.07, 5, 0.022), pale, Vector3(x, 0.37, 0.0))   # G-C: jagged fur cuff
	# ---- Chest: team coat (lathe), long dark coat tails, silver belt, rune gorget, short dark cape + fur collar,
	# rune-tome at the right hip.
	add_part(chest, _path("hmb_torso", PackedVector3Array([Vector3(0, 0.84, 0), Vector3(0, 0.98, 0.0),
		Vector3(0, 1.16, 0.01), Vector3(0, 1.28, 0.0), Vector3(0, 1.36, 0.0)]),
		PackedFloat32Array([0.17, 0.18, 0.215, 0.215, 0.14]), 8), cloth, Vector3.ZERO, Vector3.ZERO,
		Vector3(1.0, 1.0, 0.85))
	add_part(chest, cyl(0.18, 0.30, 0.52, 8, false), cdark, Vector3(0, 0.62, -0.02), Vector3(4, 0, 0))
	add_part(chest, _path("hmb_tabard", PackedVector3Array([Vector3(0, 0.22, 0), Vector3(0, 0.0, 0.0),
		Vector3(0, -0.24, 0.03)]), PackedFloat32Array([0.07, 0.08, 0.10]), 6), cloth, Vector3(0, 0.64, 0.25),
		Vector3(-12, 0, 0), Vector3(1.0, 1.0, 0.3))
	add_part(chest, cyl(0.19, 0.19, 0.06, 8), metal, Vector3(0, 0.90, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.88))
	add_part(chest, box(Vector3(0.09, 0.08, 0.04)), metal, Vector3(0, 0.90, 0.17))
	add_part(chest, cyl(0.12, 0.20, 0.09, 8), metal, Vector3(0, 1.31, 0.0))
	add_part(chest, _path("hmb_cape", PackedVector3Array([Vector3(0, 0.26, 0), Vector3(0, 0.0, -0.03),
		Vector3(0, -0.26, -0.07)]), PackedFloat32Array([0.22, 0.25, 0.28]), 8), cdark, Vector3(0, 1.08, -0.21),
		Vector3(8, 0, 0), Vector3(1.0, 1.0, 0.16))
	add_part(chest, fur_ring(0.13, 0.25, 0.13, 7, 0.035, 1.0, 0.95), pale, Vector3(0, 1.30, -0.03), Vector3(-8, 0, 0))   # G-C: shaggy fur collar
	add_part(chest, box(Vector3(0.07, 0.20, 0.17)), leather, Vector3(0.23, 0.82, 0.03), Vector3(0, 0, 8))
	add_part(chest, box(Vector3(0.075, 0.05, 0.12)), steel, Vector3(0.25, 0.82, 0.03), Vector3(0, 0, 8))
	add_crystal(chest, Vector3(0.26, 0.93, 0.05), Vector3(0.2, -1.0, 0.1), 0.02, 0.10, frost, 0.6)
	# ---- Head: face, team hood with a forward peak, back drape, silver circlet crowned by 3 ice crystals.
	add_part(head, sphere(0.115, 8, 5), skin, Vector3(0, 1.52, 0.055))
	add_part(head, sphere(0.165, 9, 5), cloth, Vector3(0, 1.56, -0.03), Vector3(-8, 0, 0), Vector3(1.0, 1.08, 1.1))
	add_part(head, cyl(0.0, 0.085, 0.16, 6), cloth, Vector3(0, 1.66, 0.10), Vector3(72, 0, 0), Vector3(1.4, 1.0, 0.7))
	add_part(head, cyl(0.10, 0.16, 0.20, 9, false), cdark, Vector3(0, 1.44, -0.08), Vector3(-10, 0, 0))
	add_part(head, torus(0.15, 0.175, 8), metal, Vector3(0, 1.63, -0.01), Vector3(-12, 0, 0))
	add_crystal(head, Vector3(0, 1.66, 0.13), Vector3(0, 1.0, 0.25), 0.032, 0.22, frost, 0.6)
	add_crystal(head, Vector3(-0.10, 1.66, 0.09), Vector3(-0.5, 1.0, 0.1), 0.024, 0.14, frost, 0.6)
	add_crystal(head, Vector3(0.10, 1.66, 0.09), Vector3(0.5, 1.0, 0.1), 0.024, 0.14, frost, 0.6)
	# Face (faces pass 2026-09-28): a young mage, silver-lilac fringe under the peak, violet-blue eyes (FaceKit,
	# replaces the eye dots).
	var hair := Color(0.80, 0.80, 0.92)
	_face = UnitFaces.attach_lean(self, head, "hoarlight_magebow", {"center": Vector3(0, 1.52, 0.055), "radius": 0.115,
		"head_mesh": sphere(0.115, 8, 5), "preset": &"bright", "detail": &"low", "skin": ICE_SKIN, "hair": hair,
		"hair_tip": Color(0.72, 0.84, 1.0), "eyes": Color(0.52, 0.48, 0.92), "ears": &"none",
		"palette": {"brow": Color(0.50, 0.50, 0.64)}, "eye": {"c": Vector2(0.042, 0.014)},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, Vector3(0, 1.52, 0.055), 0.115, hair,
			Color(0.72, 0.84, 1.0), 1.0)}, false)
	var trim := add_part(head, torus(0.18, 0.21, 12), palette(&"unit_gold_trim"), Vector3(0, 1.55, -0.04),
		Vector3(-10, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: dark sleeves, team shoulder caps, silver bracer on the bow arm, leather glove on the draw hand.
	var elb_l := Vector3(-0.31, 1.11, -0.02)
	add_part(arm_l, _path("hmb_arm_l", PackedVector3Array([SH_L, elb_l, GRIP_L]),
		PackedFloat32Array([0.072, 0.062, 0.054]), 8), cdark, Vector3.ZERO)
	add_part(arm_l, sphere(0.068, 7, 4), leather, GRIP_L)
	var dl := (GRIP_L - elb_l).normalized()
	add_part(arm_l, cyl(0.078, 0.068, 0.15, 8), metal, elb_l.lerp(GRIP_L, 0.55),
		Basis(Quaternion(Vector3.UP, dl)).get_euler() * (180.0 / PI))
	var elb_r := Vector3(0.32, 1.10, -0.04)
	add_part(arm_r, _path("hmb_arm_r", PackedVector3Array([SH_R, elb_r, HAND_R]),
		PackedFloat32Array([0.072, 0.062, 0.054]), 8), cdark, Vector3.ZERO)
	add_part(arm_r, sphere(0.068, 7, 4), leather, HAND_R)
	add_part(arm_r, sphere(0.095, 8, 4), cloth, SH_R + Vector3(0.02, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	add_part(arm_l, sphere(0.095, 8, 4), cloth, SH_L + Vector3(-0.02, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	# ---- The bow of light (keep_separate container under the bow arm, counter-rotated to stay upright on the draw).
	_bow = Node3D.new()
	_bow.name = "Bow"
	_bow.set_meta(&"keep_separate", true)
	_bow.position = GRIP_L - model_origin(arm_l)
	_bow.rotation_degrees = Vector3(BOW_TILT, 0, BOW_CANT)
	arm_l.add_child(_bow)
	var body := MeshInstance3D.new()
	body.name = "Stave"
	body.mesh = _stave_mesh(frost, metal, leather)
	body.set_meta(&"keep_separate", true)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_bow.add_child(body)
	_rune = _bow_part(_rune_mesh(), glow, "Rune")
	_string = _bow_part(_string_mesh(), glow, "LightString")
	_arrow = _bow_part(_arrow_mesh(), glow, "LightArrow")
	for gi: GeometryInstance3D in [_rune, _string, _arrow]:
		gi.set_meta(&"own_glow", true)
	_string.visible = false
	_arrow.visible = false
	# ---- Fx: release motes off the stave front, breath, hit chips, shatter death, cool blob.
	_burst = make_motes(ICE_GLOW, 9, 0.35, 0.08, 3.2, 0.08, false, true)
	_burst.name = "ReleaseBurst"
	_burst.position = Vector3(0, 0.02, 0.36)
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


## World position where the needle leaves the stave.
func get_bow_tip_position() -> Vector3:
	if _bow == null:
		return global_position + Vector3(0, 1.3, 0.4)
	return _bow.global_transform * Vector3(0, 0, 0.4)


# ================================================================ meshes (cached)

static func _path_into(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var extra: float = 0.02 if radii[i + 1] > 0.0 else 0.0
		var len_total := d.length() + extra
		st.append_from(cyl(radii[i + 1], radii[i], len_total, seg, false), 0,
			Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))


static func _path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_path_into(st, pts, radii, seg)
	st.index()
	return _cached(key, st.commit())


## Three surfaces: faceted glass limbs curling forward with forked ends, silver rune rings, leather grip.
static func _stave_mesh(frost: Material, metal: Material, leather: Material) -> Mesh:
	const KEY := "hmb_stave"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var st_m := SurfaceTool.new()
	for s: float in [1.0, -1.0]:
		var tip: Vector3 = TIP_U if s > 0.0 else TIP_D
		var L: float = absf(tip.y)
		var pts := PackedVector3Array([Vector3(0, 0.0, 0.0), Vector3(0, 0.28 * L * s, -0.02),
			Vector3(0, 0.56 * L * s, 0.0), Vector3(0, 0.82 * L * s, 0.05), tip])
		_path_into(st, pts, PackedFloat32Array([0.05, 0.046, 0.04, 0.032, 0.026]), 6)
		# the fork: two short prongs splitting forward / back at the tip (where the light string anchors)
		for f: float in [1.0, -1.0]:
			var dir := Vector3(0, 0.8 * s, 0.6 * f).normalized()
			st.append_from(cyl(0.0, 0.026, 0.13, 6), 0, Transform3D(Basis(Quaternion(Vector3.UP, dir)), tip + dir * 0.06))
		# a crystal fin on the back of each limb (chunky read at 40 m)
		var fin := Vector3(0, 0.42 * L * s, -0.02)
		st.append_from(cyl(0.0, 0.045, 0.16, 6), 0,
			Transform3D(Basis(Quaternion(Vector3.UP, Vector3(0, 0.3 * s, -1.0).normalized())), fin + Vector3(0, 0.02 * s, -0.07)))
		# silver rune rings
		st_m.append_from(cyl(0.058, 0.058, 0.035, 6), 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.30 * L * s, -0.02)))
		st_m.append_from(cyl(0.05, 0.05, 0.03, 6), 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.62 * L * s, 0.01)))
	st.index()
	var m: ArrayMesh = st.commit()
	m.surface_set_material(0, frost)
	st_m.index()
	st_m.commit(m)
	m.surface_set_material(1, metal)
	var st2 := SurfaceTool.new()
	st2.append_from(cyl(0.064, 0.064, 0.22, 7), 0, Transform3D.IDENTITY)
	st2.index()
	st2.commit(m)
	m.surface_set_material(2, leather)
	return _cached(KEY, m)


## The rune crystal set in the upper fork (the rest glow point).
static func _rune_mesh() -> Mesh:
	const KEY := "hmb_rune"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var c := TIP_U + Vector3(0, -0.02, -0.01)
	st.append_from(cyl(0.0, 0.07, 0.13, 6), 0, Transform3D(Basis.IDENTITY, c + Vector3(0, 0.065, 0)))
	st.append_from(cyl(0.0, 0.07, 0.10, 6), 0, Transform3D(Basis(Vector3.RIGHT, PI), c + Vector3(0, -0.05, 0)))
	st.index()
	return _cached(KEY, st.commit())


static func _string_mesh() -> Mesh:
	const KEY := "hmb_string"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, NOCK, TIP_D]), PackedFloat32Array([0.018, 0.022, 0.018]), 5)
	st.index()
	return _cached(KEY, st.commit())


static func _arrow_mesh() -> Mesh:
	const KEY := "hmb_arrow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([NOCK, ARROW_HEAD]), PackedFloat32Array([0.014, 0.02]), 5)
	st.append_from(cyl(0.0, 0.045, 0.16, 6), 0,
		Transform3D(Basis(Quaternion(Vector3.UP, Vector3.BACK)), ARROW_HEAD + Vector3(0, 0, 0.07)))
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ motion

static func _mb_kf(t: float, k: PackedFloat32Array) -> float:
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
	_string.visible = on
	_arrow.visible = on


func _set_bow_x(arm_deg: float) -> void:
	# keeps the stave upright whatever the bow arm does (the arm's X rotation is undone on the Bow node)
	var x: float = BOW_TILT - arm_deg
	if absf(x - _bow_x_written) < 0.01 or _bow == null:
		return
	_bow_x_written = x
	_bow.rotation.x = x * DEG


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"light_draw":
		return super._pose_attack(prev, t)
	var al := _mb_kf(t, A_ARM_L)
	var yaw := _mb_kf(t, A_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(0, yaw * DEG, 0))
	rot(P_HEAD, Vector3(0, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_mb_kf(t, A_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _mb_kf(t, A_ARM_RZ)))
	pos(P_ROOT, Vector3(0, 0, _mb_kf(t, A_ROOT_Z)))
	var st: float = yaw / 28.0
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
	var al := _mb_kf(t, C_ARM_L)
	var yaw := _mb_kf(t, C_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(_mb_kf(t, C_CHEST_X) * DEG, yaw * DEG, 0))
	rot(P_HEAD, Vector3(0, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_mb_kf(t, C_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _mb_kf(t, C_ARM_RZ)))
	_set_bow_x(al)
	_set_drawn(t > 0.12 and t < CAST_RELEASE)
	_charge = clampf((t - 0.2) / (CAST_RELEASE - 0.2), 0.0, 1.0) * 1.8 if t < CAST_RELEASE else 0.0
	if t >= CAST_RELEASE and not _cast_loosed:
		_cast_loosed = true
		_loose(1.8)
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
		rot(P_ARM_L, Vector3(12.0 * DEG * sin(TAU * _walk_p) * _walk_w, 0, 0))
	_flare = maxf(0.0, _flare - dt / 0.35)
	if _rune:
		var base: float = RUNE_BASE
		if _tier == 0:
			base += 0.25 * (0.5 + 0.5 * sin(_t * 2.4 + _phase_off * 6.0))
		var b: float = glow_level() * (base + 1.5 * _charge + 2.2 * _flare)
		if absf(b - _rune_written) > 0.04:
			_rune_written = b
			_rune.set_instance_shader_parameter(&"glow_boost", b)
		var s: float = glow_level() * (1.6 + 1.2 * _charge)
		if absf(s - _str_written) > 0.04:
			_str_written = s
			_string.set_instance_shader_parameter(&"glow_boost", s)
			_arrow.set_instance_shader_parameter(&"glow_boost", s)


func _ice_revive() -> void:
	_flare = 0.0
	_charge = 0.0
	_rune_written = -1.0
	_str_written = -1.0
	_set_drawn(false)
	_set_bow_x(0.0)


## Fidget: lifts the stave before the face and traces a rune in the air with the draw hand (the rune glints).
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.35, 0.95, 1.4, 1.0, 1.0)
	var al := -40.0 * k
	rot(P_ARM_L, Vector3(al * DEG, 0, 0))
	_set_bow_x(al * 0.7)
	rot(P_HEAD, Vector3(6.0 * DEG * k, -16.0 * DEG * k, 0))
	rot(P_ARM_R, Vector3((-55.0 + 12.0 * sin(t * 9.0)) * DEG * k, 0, 10.0 * DEG * cos(t * 9.0) * k))
	if t > 0.6 and t < 0.75:
		_flare = maxf(_flare, 0.7)
	if t >= 1.35:
		_set_bow_x(0.0)
	return 1.4
