extends NatureWarModel
## Wildwood Archer, Nature bowman (docs/design/bowmen.md: the plain longbow archer, "many of them"). body_height 1.6 (UnitType).
## A light upright woodland archer (the Burr Slinger crouches behind a horizontal pod, the Vinelasher is a bark
## warrior with a whip): an ochre buckskin jerkin (keeps the body off the grass hue), a team-dark leaf capelet, a
## bark leaf kilt, bark-dark legs with pale thorn-bone greave bands, a bare face with tied-back hair under a
## leaf CIRCLET whose two long team leaves sweep back like feathers (the head read), a bark quiver on the back with
## leaf-fletched arrows over the right shoulder.
## The silhouette hook: a tall living-wood LONGBOW (1.9 m, upright in the left fist, taller than the archer) sprouting
## leaves at both tips; a glowing seed BUD on the top tip is the only glow point (high up, reads over the crowd).
## Attack `bow_draw` (0.55 s, release 0.15): a quick clean draw to the chin, loose, the bud flares, green motes.
## play_cast (any id, 1.0 s): a slow full draw aimed high (an arcing shot), bigger flare.
## Hooks (plus every kit / Nature hook): get_bow_tip_position() -> Vector3 (world; where the arrow leaves).
## Draws: merged pivots + Bow (3 surfaces: wood, leaves, bud glow) + BowString + StringDrawn + Arrow (hidden at rest)
## + VetTrim (hidden) + blob. 0 lights. Kept cheap: it is the mass unit.

const ATTACK_LEN := 0.55
const RELEASE := 0.15
const CAST_LEN := 1.0
const CAST_RELEASE := 0.65
const BOW_TILT := 8.0
const GRIP_L := Vector3(-0.34, 0.95, 0.10)
const HAND_R := Vector3(0.32, 0.90, 0.05)
const SH_L := Vector3(-0.25, 1.28, 0.0)
const SH_R := Vector3(0.25, 1.28, 0.0)
# bow space (origin = grip, +Y up the bow, -Z toward the archer)
const TIP_U := Vector3(0.0, 0.98, -0.19)
const TIP_D := Vector3(0.0, -0.90, -0.19)
const NOCK := Vector3(0.0, 0.0, -0.48)
const ARROW_HEAD := Vector3(0.0, 0.0, 0.34)

# bow_draw tracks [t, value, ease] (NatureWarModel._kf). Arm x: negative raises forward.
static var A_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.10, -84.0, 1, 0.32, -80.0, 0, 0.55, 0.0, 0])
static var A_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.10, 26.0, 1, 0.32, 24.0, 0, 0.55, 0.0, 0])
static var A_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -78.0, 1, 0.15, -84.0, 0, 0.21, -66.0, 1, 0.55, 0.0, 0])
static var A_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.30, 1, 0.15, -0.44, 2, 0.21, -0.54, 1, 0.55, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.15, 0.0, 0, 0.20, -0.05, 1, 0.55, 0.0, 0])
# Arcing shot: slow full draw aimed high, loose at 0.65.
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.30, -116.0, 1, 0.80, -110.0, 0, 1.0, 0.0, 0])
static var C_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.30, 28.0, 1, 0.80, 24.0, 0, 1.0, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.30, -98.0, 1, 0.60, -110.0, 0, 0.72, -86.0, 1, 1.0, 0.0, 0])
static var C_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.30, -0.26, 1, 0.60, -0.48, 2, 0.72, -0.58, 1, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -12.0, 0, 0.60, -14.0, 0, 0.72, -4.0, 1, 1.0, 0.0, 0])

var _bow: Node3D
var _bow_body: GeometryInstance3D
var _bstring: GeometryInstance3D
var _string_drawn: GeometryInstance3D
var _barrow: GeometryInstance3D
var _burst: GPUParticles3D
var _drawn_on: bool = false
var _cast_loosed: bool = false
var _flare: float = 0.0
var _charge: float = 0.0
var _bud_written: float = -1.0
var _bow_x_written: float = 999.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := nature(&"nature_cloth")
	var cdark := nature(&"nature_cloth_dark")
	var bark := nature(&"nature_bark")
	var bdark := nature(&"nature_bark_dark")
	var skin := nature(&"nature_skin")
	var hair := nature(&"nature_hair")
	var thorn := nature(&"nature_thorn")
	var leaf := nature(&"nature_leaf")
	var glow := nature(&"nature_glow")
	var suede := nature(&"nature_sec_slinger_c")   # ochre buckskin jerkin: the value read off the grass (R3 / R12)
	# ---- Legs: lean bark-dark legs, pale thorn greave bands, dark feet.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, tapered_path_mesh("wa_leg_%s" % sx, PackedVector3Array([Vector3(0.11 * sx, 0.86, 0.0),
			Vector3(0.12 * sx, 0.48, 0.04), Vector3(0.12 * sx, 0.08, -0.01)]), PackedFloat32Array([0.085, 0.065, 0.055])),
			bdark, Vector3.ZERO)
		add_part(leg, cyl(0.07, 0.065, 0.05, 7), thorn, Vector3(0.12 * sx, 0.30, 0.02))
		add_part(leg, sphere(0.07, 7, 4), bdark, Vector3(0.12 * sx, 0.055, 0.06), Vector3.ZERO, Vector3(1.0, 0.7, 1.6))
	# ---- Hips: bark belt + team-dark leaf kilt, a small pouch.
	add_part(hips, cyl(0.19, 0.19, 0.08, 9), bark, Vector3(0, 0.87, 0))
	add_part(hips, leaf_ring_mesh(7, 0.15, Vector3(0.16, 0.035, 0.30), -72.0, 12.0), bark, Vector3(0, 0.88, 0))
	add_part(hips, sphere(0.07, 6, 3), bark, Vector3(-0.20, 0.80, 0.08), Vector3.ZERO, Vector3(0.9, 1.1, 0.7))
	# ---- Chest: bark-leather jerkin (lathe), team leaf capelet, a leather baldric, the bark quiver on the back.
	add_part(chest, tapered_path_mesh("wa_torso", PackedVector3Array([Vector3(0, 0.84, 0), Vector3(0, 1.00, 0.0),
		Vector3(0, 1.16, 0.01), Vector3(0, 1.30, 0.0)]), PackedFloat32Array([0.18, 0.19, 0.22, 0.2]), 8, false),
		suede, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	add_part(chest, leaf_ring_mesh(7, 0.13, Vector3(0.22, 0.05, 0.28), -40.0, 0.0), cdark, Vector3(0, 1.30, 0.0))
	add_part(chest, cyl(0.075, 0.10, 0.10, 8), skin, Vector3(0, 1.36, 0.01))
	add_part(chest, box(Vector3(0.05, 0.62, 0.03)), bdark, Vector3(0.0, 1.08, 0.18), Vector3(-6, 0, -34))
	var qa := Vector3(0.36, 0.93, 0.0)
	var qc := Vector3(0.04, 1.10, -0.23)
	add_part(chest, cyl(0.07, 0.055, 0.52, 7), bark, qc, _euler_up(qa))
	add_part(chest, cyl(0.078, 0.078, 0.04, 7), bdark, qc + qa * 0.24, _euler_up(qa))
	var qtop := qc + qa * 0.26
	add_part(chest, _quiver_shafts_mesh(qtop, qa), bdark, Vector3.ZERO)
	add_part(chest, _fletch_mesh(qtop, qa), leaf, Vector3.ZERO)
	# ---- Head: bare face, tied-back hair, a leaf circlet with two long team leaves sweeping back like feathers.
	add_part(head, sphere(0.13, 9, 5), skin, Vector3(0, 1.50, 0.03), Vector3.ZERO, Vector3(0.92, 1.08, 1.0))
	add_part(head, sphere(0.135, 9, 5), hair, Vector3(0, 1.54, -0.02), Vector3(-15, 0, 0), Vector3(1.0, 1.0, 1.05))
	add_part(head, tapered_path_mesh("wa_tail", PackedVector3Array([Vector3(0, 1.52, -0.13), Vector3(0, 1.42, -0.20),
		Vector3(0, 1.30, -0.19)]), PackedFloat32Array([0.05, 0.045, 0.0]), 6), hair, Vector3.ZERO)
	for ex: float in [-0.042, 0.042]:
		add_part(head, box(Vector3(0.04, 0.025, 0.04)), palette(&"unit_eye_dark"), Vector3(ex, 1.515, 0.14))
	add_part(head, torus(0.12, 0.15, 10), bdark, Vector3(0, 1.58, 0.0), Vector3(-10, 0, 0))
	for sx: float in [-1.0, 1.0]:
		add_leaf(head, Vector3(0.10 * sx, 1.66, -0.14), Vector3(0.11, 0.04, 0.42), cloth, Vector3(-38, 180 - 14 * sx, 0))
	add_leaf(head, Vector3(0, 1.62, 0.12), Vector3(0.10, 0.03, 0.16), cloth, Vector3(-20, 0, 0))
	var trim := add_part(head, torus(0.14, 0.18, 10), palette(&"unit_gold_trim"), Vector3(0, 1.62, 0.0),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: bark-leather sleeves, skin hands, a thorn bracer on the bow arm.
	add_limb(arm_l, SH_L, GRIP_L, 0.06, bark, 0.068, skin)
	var dl := (GRIP_L - SH_L).normalized()
	add_part(arm_l, cyl(0.075, 0.07, 0.15, 7), thorn, SH_L.lerp(GRIP_L, 0.72), _euler_up(dl))
	add_limb(arm_r, SH_R, HAND_R, 0.06, bark, 0.068, skin)
	# ---- The longbow (keep_separate container under the bow arm, counter-rotated to stay upright on the draw).
	_bow = Node3D.new()
	_bow.name = "Bow"
	_bow.set_meta(&"keep_separate", true)
	_bow.position = GRIP_L - model_origin(arm_l)
	_bow.rotation_degrees = Vector3(BOW_TILT, 0, 0)
	arm_l.add_child(_bow)
	var body := MeshInstance3D.new()
	body.name = "BowBody"
	body.mesh = _bow_mesh(bark, leaf, glow)
	body.set_meta(&"keep_separate", true)
	body.set_meta(&"own_glow", true)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_bow.add_child(body)
	_bow_body = body
	_bstring = _bow_part(_string_mesh(), thorn, "BowString")
	_string_drawn = _bow_part(_drawn_mesh(), thorn, "StringDrawn")
	_barrow = _bow_part(_arrow_mesh(), bdark, "Arrow")
	_string_drawn.visible = false
	_barrow.visible = false
	# ---- Fx: green motes off the bow front on release, Nature hit leaves / death bloom.
	_burst = make_motes(NATURE_GLOW, 6, 0.35, 0.06, 2.4, 0.08, false, true)
	_burst.name = "ReleaseBurst"
	_burst.position = Vector3(0, 0.02, 0.36)
	_bow.add_child(_burst)
	add_hit_burst(Vector3(0, 1.15, 0.05), Color(0.46, 0.66, 0.20), 6)
	add_death_bloom(Vector3(0, 0.9, 0.1), 0.3, 8, 8, Color(0.55, 0.42, 0.24))
	ensure_shadow_blob(0.4)


func _bow_part(mesh: Mesh, mat: Material, part_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"keep_separate", true)
	_bow.add_child(mi)
	return mi


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


static func _quiver_shafts_mesh(top: Vector3, qa: Vector3) -> Mesh:
	const KEY := "wa_qshafts"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var offs: Array[Vector3] = [Vector3(0.03, 0, 0.02), Vector3(-0.03, 0, 0.0), Vector3(0.0, 0, -0.03)]
	var lens: Array[float] = [0.20, 0.26, 0.23]
	for i: int in 3:
		var a: Vector3 = top + offs[i]
		_path_into(st, PackedVector3Array([a - qa * 0.05, a + qa * lens[i]]), PackedFloat32Array([0.014, 0.014]), 4)
	return _cached(KEY, _indexed(st))


## Leaf fletching on the 3 quiver arrows (two little leaves each).
static func _fletch_mesh(top: Vector3, qa: Vector3) -> Mesh:
	const KEY := "wa_qfletch"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var offs: Array[Vector3] = [Vector3(0.03, 0, 0.02), Vector3(-0.03, 0, 0.0), Vector3(0.0, 0, -0.03)]
	var lens: Array[float] = [0.20, 0.26, 0.23]
	var xs: Array[Transform3D] = []
	for i: int in 3:
		var base: Vector3 = top + offs[i] + qa * (lens[i] - 0.10)
		for s: float in [1.0]:
			var side := Vector3(s * 0.7, 0, (0.7 if i == 1 else -0.7)).normalized()
			var dir := (qa + side * 0.35).normalized()
			var b := Basis(Quaternion(Vector3.BACK, dir))
			xs.append(Transform3D(b.scaled_local(Vector3(0.06, 0.02, 0.14)), base + dir * 0.07))
	return cluster_mesh(KEY, leaf_mesh(), xs)


## Three surfaces: living-wood limbs (0), sprouting leaves at both tips + the grip wrap (1), the glowing seed bud on
## the top tip (2).
static func _bow_mesh(wood: Material, leaf: Material, glow: Material) -> Mesh:
	const KEY := "wa_bow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [1.0, -1.0]:
		var L: float = 0.98 if s > 0.0 else 0.90
		var pts := PackedVector3Array([Vector3(0, 0.0, 0.02), Vector3(0, 0.30 * L * s, 0.0),
			Vector3(0, 0.60 * L * s, -0.06), Vector3(0, 0.84 * L * s, -0.14), Vector3(0, 1.0 * L * s, -0.19)])
		_path_into(st, pts, PackedFloat32Array([0.05, 0.045, 0.036, 0.028, 0.02]), 6)
		# a twig knot halfway up each limb
		st.append_from(cyl(0.0, 0.025, 0.12, 4), 0, Transform3D(Basis(Quaternion(Vector3.UP,
			Vector3(0.5, 0.6 * s, 0.6).normalized())), Vector3(0.03, 0.50 * L * s, 0.0)))
	var m: ArrayMesh = _indexed(st)
	m.surface_set_material(0, wood)
	var xs: Array[Transform3D] = []
	for s: float in [1.0, -1.0]:
		var L: float = 0.98 if s > 0.0 else 0.90
		var tip := Vector3(0, 1.0 * L * s, -0.19)
		for k: int in 2:
			var a: float = PI * k + 0.9
			var dir := Vector3(cos(a) * 0.8, 0.9 * s, sin(a) * 0.8 + 0.2).normalized()
			var b := Basis(Quaternion(Vector3.BACK, dir))
			xs.append(Transform3D(b.scaled_local(Vector3(0.09, 0.025, 0.20)), tip - Vector3(0, 0.08 * s, 0) + dir * 0.09))
	var lm := cluster_mesh("wa_bow_leaves", leaf_mesh(), xs)
	var st2 := SurfaceTool.new()
	st2.append_from(lm, 0, Transform3D.IDENTITY)
	st2.append_from(cyl(0.062, 0.062, 0.22, 6), 0, Transform3D.IDENTITY)
	st2.index()
	st2.commit(m)
	m.surface_set_material(1, leaf)
	var st3 := SurfaceTool.new()
	var top := Vector3(0, 0.98, -0.19)
	st3.append_from(sphere(0.062, 6, 4), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1.35, 1)), top + Vector3(0, 0.07, 0)))
	st3.index()
	st3.commit(m)
	m.surface_set_material(2, glow)
	return _cached(KEY, m)


static func _string_mesh() -> Mesh:
	const KEY := "wa_string"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, TIP_D]), PackedFloat32Array([0.014, 0.014]), 4)
	return _cached(KEY, _indexed(st))


static func _drawn_mesh() -> Mesh:
	const KEY := "wa_string_drawn"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([TIP_U, NOCK, TIP_D]), PackedFloat32Array([0.014, 0.016, 0.014]), 4)
	return _cached(KEY, _indexed(st))


static func _arrow_mesh() -> Mesh:
	const KEY := "wa_arrow"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	_path_into(st, PackedVector3Array([NOCK, ARROW_HEAD]), PackedFloat32Array([0.016, 0.016]), 4)
	st.append_from(cyl(0.0, 0.035, 0.12, 4), 0,
		Transform3D(Basis(Quaternion(Vector3.UP, Vector3.BACK)), ARROW_HEAD + Vector3(0, 0, 0.05)))
	return _cached(KEY, _indexed(st))


# ================================================================ motion

func _wa_drawn(on: bool) -> void:
	if on == _drawn_on or _bstring == null:
		return
	_drawn_on = on
	_bstring.visible = not on
	_string_drawn.visible = on
	_barrow.visible = on


func _set_bow_x(arm_deg: float) -> void:
	var x: float = BOW_TILT - arm_deg
	if absf(x - _bow_x_written) < 0.01 or _bow == null:
		return
	_bow_x_written = x
	_bow.rotation.x = x * DEG


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"bow_draw":
		return super._pose_attack(prev, t)
	var al := _kf(t, A_ARM_L)
	var yaw := _kf(t, A_YAW)
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(0, yaw * DEG, 0))
	rot(P_HEAD, Vector3(0, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_kf(t, A_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, A_ARM_RZ)))
	pos(P_ROOT, Vector3(0, 0, _kf(t, A_ROOT_Z)))
	var st: float = yaw / 26.0
	if _tier == 0:
		rot(P_LEG_L, Vector3(-16.0 * DEG * st, 0, -6.0 * DEG * st))
		rot(P_LEG_R, Vector3(12.0 * DEG * st, 0, 6.0 * DEG * st))
	rot(P_ROOT, Vector3(-5.0 * DEG * st, 0, 0))
	_set_bow_x(al)
	_wa_drawn(t > 0.04 and t < RELEASE)
	_charge = clampf(t / RELEASE, 0.0, 1.0) if t < RELEASE else 0.0
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	var al := _kf(t, C_ARM_L)
	var yaw := _kf(t, C_YAW)
	var up: float = clampf(t / 0.3, 0.0, 1.0) * (1.0 - smoothstep(0.75, 1.0, t))
	rot(P_ARM_L, Vector3(al * DEG, -yaw * DEG, 0))
	rot(P_CHEST, Vector3(_kf(t, C_CHEST_X) * DEG, yaw * DEG, 0))
	rot(P_HEAD, Vector3(-12.0 * DEG * up, -yaw * 0.9 * DEG, 0))
	rot(P_ARM_R, Vector3(_kf(t, C_ARM_R) * DEG, -yaw * 0.6 * DEG, 0))
	pos(P_ARM_R, Vector3(0, 0, _kf(t, C_ARM_RZ)))
	_set_bow_x(al + 30.0 * up)
	_wa_drawn(t > 0.12 and t < CAST_RELEASE)
	_charge = clampf((t - 0.2) / (CAST_RELEASE - 0.2), 0.0, 1.0) * 1.6 if t < CAST_RELEASE else 0.0
	if t >= CAST_RELEASE and not _cast_loosed:
		_cast_loosed = true
		_loose(1.6)
	return CAST_LEN


func _loose(amount: float) -> void:
	_flare = amount
	_charge = 0.0
	_wa_drawn(false)
	if _burst and _tier < 2:
		_burst.restart()


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_loose(1.0)
	elif ev == &"cast_start":
		_cast_loosed = false
	elif ev == &"attack_end" or ev == &"cast_end" or ev == &"death_glow_off":
		_wa_drawn(false)
		_charge = 0.0
		_set_bow_x(0.0)


## Light ranger's lope: upright, the long bow kept calm (the kit swings the bow arm -18 deg: net -5).
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_ARM_L, Vector3(13.0 * DEG * s * w, 0, 0))
	if _tier == 0:
		rot(P_CHEST, Vector3(0, -5.0 * DEG * s * w, 0))


func _war_process(dt: float) -> void:
	if _dead or _action == &"" or _action == &"fidget":
		if _drawn_on:
			_wa_drawn(false)
		if _action != &"fidget":
			_set_bow_x(0.0)
		_charge = 0.0
	_flare = maxf(0.0, _flare - dt / 0.35)
	if _bow_body:
		var b: float = snappedf(glow_level() * (2.2 + 0.8 * _charge + 1.8 * _flare), 0.05)
		if b != _bud_written:
			_bud_written = b
			_bow_body.set_instance_shader_parameter(&"glow_boost", b)


func _war_revive() -> void:
	_flare = 0.0
	_charge = 0.0
	_bud_written = -1.0
	_drawn_on = true
	_wa_drawn(false)
	_set_bow_x(0.0)


## Fidget: lifts the bow, sights along it, tests the string (the bud glints).
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.35, 0.95, 1.4, 1.0, 1.0)
	var al := -36.0 * k
	rot(P_ARM_L, Vector3(al * DEG, 0, 0))
	_set_bow_x(al * 0.7)
	rot(P_HEAD, Vector3(6.0 * DEG * k, -16.0 * DEG * k, 0))
	rot(P_ARM_R, Vector3(-28.0 * DEG * k, 0, 0))
	if t > 0.6 and t < 0.7:
		_flare = maxf(_flare, 0.5)
	if t >= 1.35:
		_set_bow_x(0.0)
	return 1.4
