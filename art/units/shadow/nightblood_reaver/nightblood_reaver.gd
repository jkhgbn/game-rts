extends ShadowModel
## Nightblood Reaver, Shadow T3 vampire duelist (t3-helpers.md 7.2 / 7.3; tiers wave, medium effort). Height 2.1.
## A tall pale noble-warrior in black plate with oxblood trim: a gaunt lilac-pale face, slicked dark hair with a
## widow's peak, pointed ears; a high fan collar of plates rising behind the head (the vampire read), a big spiked
## right pauldron (asymmetry), a team tabard, and a torn two-panel cape flared like folded bat wings. The weapon
## hook: a long curved sabre held forward-down whose cutting edge glows violet (the main glow point, blood drops
## hang from it); the eyes glow faintly. The left hand is a clawed gauntlet (the drinking hand).
## Attack `reaver_slash` (0.6 s, strike 0.12): a diagonal overhead cut with a lunge. play_cast (drink / Blood Frenzy,
## 1.0 s): the claw reaches out, the sabre rises before the face, blood motes stream to it and the glows flare.
## Hook set_status(&"frenzy", on): eyes and blade flare (x2.4) while it lasts. Death: ShadowModel's dissolve.
## Draws: merged pivots + blob + hidden vet trim; one-shot emitters (drink, death). 0 lights.

const ATTACK_LEN := 0.6
const STRIKE := 0.12
const CAST_LEN := 1.0
const HAND_R := Vector3(0.38, 1.14, 0.16)
const HAND_L := Vector3(-0.37, 1.12, 0.16)
const BLOOD := Color(0.85, 0.18, 0.45)
const FRENZY_GAIN := 2.4

# reaver_slash tracks [t, value, ease] (FireModel format, local copy). Arm x: - raises forward / overhead.
static var R_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, -155.0, 1, 0.12, -40.0, 2, 0.22, -18.0, 1, 0.34, -24.0, 0, 0.60, 0.0, 0])
static var R_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.08, 30.0, 1, 0.12, -20.0, 2, 0.30, -14.0, 0, 0.60, 0.0, 0])
static var R_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.08, -50.0, 1, 0.12, 20.0, 2, 0.34, 12.0, 0, 0.60, 0.0, 0])
static var R_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 28.0, 1, 0.12, -30.0, 2, 0.34, -16.0, 0, 0.60, 0.0, 0])
static var R_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -12.0, 1, 0.12, 18.0, 2, 0.34, 10.0, 0, 0.60, 0.0, 0])
static var R_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.08, 1, 0.12, 0.38, 2, 0.34, 0.30, 0, 0.60, 0.0, 0])
static var R_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 0.05, 1, 0.12, -0.10, 2, 0.34, -0.06, 0, 0.60, 0.0, 0])
static var R_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -34.0, 1, 0.34, -26.0, 0, 0.60, 0.0, 0])
static var R_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, 22.0, 1, 0.34, 16.0, 0, 0.60, 0.0, 0])
# Drink: claw hand thrust out and clenching, the sabre raised upright before the face, head tilted back.
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.20, -85.0, 1, 0.75, -80.0, 0, 1.0, 0.0, 0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.25, -95.0, 1, 0.75, -100.0, 0, 1.0, 0.0, 0])
static var C_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.25, -35.0, 1, 0.75, -35.0, 0, 1.0, 0.0, 0])
static var C_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -22.0, 1, 0.75, -18.0, 0, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -10.0, 1, 0.75, -8.0, 0, 1.0, 0.0, 0])
static var C_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.35, 1.0, 1, 0.75, 1.0, 0, 1.0, 0.0, 0])

var _drink: GPUParticles3D
var _frenzy: bool = false
var _flare: float = 0.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var plate := palette(&"shadow_obsidian")
	var iron := palette(&"shadow_iron")
	var blood := palette(&"fire_hair")
	var silver := palette(&"shadow_silver")
	var cloth := palette(&"shadow_cloth")
	var cdark := palette(&"shadow_cloth_dark")
	var leather := palette(&"shadow_leather")
	var skin := palette(&"shadow_skin")
	var glow := palette(&"shadow_glow_mid")
	# ---- Legs: black greaves, oxblood knee plates, long pointed sabatons.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _nr_path("nr_leg_%s" % sx, PackedVector3Array([Vector3(0.14 * sx, 1.08, 0.0),
			Vector3(0.15 * sx, 0.62, 0.04), Vector3(0.15 * sx, 0.14, 0.0)]), PackedFloat32Array([0.1, 0.075, 0.065]), 6),
			plate, Vector3.ZERO)
		add_part(leg, sphere(0.085, 7, 4), blood, Vector3(0.15 * sx, 0.62, 0.08), Vector3.ZERO, Vector3(1.0, 1.1, 0.8))
		add_part(leg, cyl(0.0, 0.03, 0.12, 4), silver, Vector3(0.15 * sx, 0.70, 0.14), Vector3(-60, 0, 0))
		add_part(leg, cyl(0.0, 0.075, 0.28, 6), iron, Vector3(0.15 * sx, 0.06, 0.12), Vector3(90, 0, 0), Vector3(1.0, 1.0, 0.6))
	# ---- Hips: black fauld, oxblood tassets flaring out, team tabard front and back, a belt with a silver clasp.
	add_part(hips, cyl(0.24, 0.31, 0.3, 9), plate, Vector3(0, 0.98, 0))
	for k: int in 4:
		var a: float = deg_to_rad(-65.0 + 43.0 * k)
		var d := Vector3(sin(a), 0, cos(a))
		add_part(hips, box(Vector3(0.17, 0.3, 0.03)), blood, Vector3(0, 0.8, 0) + d * 0.3,
			Vector3(-18, rad_to_deg(a), 0))
	add_part(hips, box(Vector3(0.2, 0.7, 0.03)), cloth, Vector3(0, 0.66, 0.31), Vector3(-7, 0, 0))
	add_part(hips, cyl(0.0, 0.1, 0.14, 4), cloth, Vector3(0, 0.25, 0.35), Vector3(180, 45, 0), Vector3(1.0, 1.0, 0.25))
	add_part(hips, box(Vector3(0.2, 0.6, 0.03)), cdark, Vector3(0, 0.7, -0.3), Vector3(7, 0, 0))
	add_part(hips, cyl(0.25, 0.25, 0.07, 10), leather, Vector3(0, 1.1, 0.0))
	add_part(hips, sphere(0.05, 6, 3), silver, Vector3(0, 1.1, 0.25), Vector3.ZERO, Vector3(1.2, 1.0, 0.6))
	# ---- Chest: black breastplate with a silver ridge, oxblood ribbing, the fan collar, the torn bat-wing cape.
	add_part(chest, sphere(0.28, 8, 5), plate, Vector3(0, 1.44, 0.0), Vector3(-4, 0, 0), Vector3(1.05, 1.2, 0.82))
	add_part(chest, box(Vector3(0.035, 0.36, 0.05)), silver, Vector3(0, 1.46, 0.225), Vector3(-10, 0, 0))
	add_part(chest, torus(0.2, 0.26, 8), blood, Vector3(0, 1.22, 0.0), Vector3.ZERO, Vector3(1.0, 1.8, 0.85))
	add_part(chest, cyl(0.08, 0.1, 0.16, 6, false), iron, Vector3(0, 1.73, 0.0))
	for k: int in 5:
		var a: float = deg_to_rad(-120.0 + 60.0 * k)
		var d := Vector3(sin(a), 0, -cos(a))
		var lean: float = 16.0 + 6.0 * absf(float(k) - 2.0)
		add_part(chest, box(Vector3(0.11, 0.42 - 0.05 * absf(float(k) - 2.0), 0.03)), silver,
			Vector3(0, 1.86, -0.02) + d * 0.15, Vector3(-lean, rad_to_deg(a), 0))
		if k == 2:
			add_part(chest, box(Vector3(0.09, 0.34, 0.02)), blood, Vector3(0, 1.84, -0.02) + d * 0.13, Vector3(-lean, rad_to_deg(a), 0))
	for s: float in [-1.0, 1.0]:
		add_part(chest, cape(0.4, 1.2), palette(&"shadow_cape"), Vector3(0.18 * s, 1.12, -0.3), Vector3(10, 180 - 22 * s, 0))
		for k: int in 2:
			add_part(chest, cyl(0.0, 0.075, 0.3, 4), cdark, Vector3((0.08 + 0.2 * k) * s, 0.42 + 0.04 * k, -0.42 + 0.03 * k),
				Vector3(180 - 10, 0, 8 * s), Vector3(1.0, 1.0, 0.3))
	add_part(chest, _nr_path("nr_wingrib", PackedVector3Array([Vector3(-0.2, 1.68, -0.26), Vector3(-0.44, 1.36, -0.42),
		Vector3(-0.47, 0.72, -0.47)]), PackedFloat32Array([0.03, 0.025, 0.012]), 3), plate, Vector3.ZERO)
	add_part(chest, _nr_path("nr_wingrib_r", PackedVector3Array([Vector3(0.2, 1.68, -0.26), Vector3(0.44, 1.36, -0.42),
		Vector3(0.47, 0.72, -0.47)]), PackedFloat32Array([0.03, 0.025, 0.012]), 3), plate, Vector3.ZERO)
	# ---- Head: gaunt pale face, slick dark hair with a widow's peak, pointed ears, faint violet eyes.
	add_part(head, sphere(0.12, 8, 5), skin, Vector3(0, 1.86, 0.03), Vector3.ZERO, Vector3(0.84, 1.15, 0.95))
	add_part(head, sphere(0.125, 8, 4), leather, Vector3(0, 1.91, -0.02), Vector3(-15, 0, 0), Vector3(0.95, 0.9, 1.1))
	add_part(head, cyl(0.0, 0.05, 0.1, 4), leather, Vector3(0, 1.935, 0.1), Vector3(160, 0, 0), Vector3(1.0, 1.0, 0.5))
	for s: float in [-1.0, 1.0]:
		add_part(head, cyl(0.0, 0.028, 0.12, 4), skin, Vector3(0.12 * s, 1.89, 0.0), Vector3(-20, 0, -62 * s))
		add_part(head, box(Vector3(0.05, 0.026, 0.024)), palette(&"shadow_glow_hero"), Vector3(0.042 * s, 1.875, 0.132), Vector3(0, 0, -12 * s))
	add_part(head, box(Vector3(0.05, 0.012, 0.02)), palette(&"unit_eye_dark"), Vector3(0, 1.8, 0.135))
	var trim := add_part(head, torus(0.12, 0.16, 8), palette(&"unit_gold_trim"), Vector3(0, 1.99, -0.01),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: small pauldron with an oxblood rim, iron arm, clawed silver gauntlet.
	add_part(arm_l, sphere(0.14, 7, 4), plate, Vector3(-0.35, 1.68, 0.0), Vector3(0, 0, 20), Vector3(1.15, 0.8, 1.1))
	add_part(arm_l, torus(0.13, 0.16, 6), blood, Vector3(-0.37, 1.63, 0.0), Vector3(0, 0, 25), Vector3(1.0, 1.0, 1.0))
	add_part(arm_l, _nr_path("nr_arm_l", PackedVector3Array([Vector3(-0.34, 1.64, 0.0), Vector3(-0.38, 1.38, 0.03),
		HAND_L + Vector3(0, 0.08, -0.03)]), PackedFloat32Array([0.075, 0.068, 0.07]), 6), iron, Vector3.ZERO)
	add_part(arm_l, cyl(0.075, 0.09, 0.14, 6), plate, HAND_L + Vector3(0, 0.1, -0.03), Vector3(18, 0, 0))
	add_part(arm_l, sphere(0.065, 7, 4), silver, HAND_L)
	add_part(arm_l, _claws_mesh(), silver, Vector3.ZERO)
	# ---- Right arm: big spiked pauldron (3 silver spikes), iron arm, the long curved sabre held forward-down.
	add_part(arm_r, sphere(0.18, 8, 4), plate, Vector3(0.36, 1.70, 0.0), Vector3(0, 0, -18), Vector3(1.2, 0.8, 1.15))
	add_part(arm_r, torus(0.17, 0.2, 8), blood, Vector3(0.38, 1.64, 0.0), Vector3(0, 0, -22))
	for k: int in 3:
		add_part(arm_r, cyl(0.0, 0.04, 0.24 - 0.04 * k, 4), silver, Vector3(0.38 + 0.05 * k, 1.84 - 0.04 * k, -0.08 + 0.08 * k),
			Vector3(0, 0, -30 - 12 * k))
	add_part(arm_r, _nr_path("nr_arm_r", PackedVector3Array([Vector3(0.34, 1.64, 0.0), Vector3(0.39, 1.38, 0.03),
		HAND_R + Vector3(0, 0.08, -0.03)]), PackedFloat32Array([0.075, 0.068, 0.07]), 6), iron, Vector3.ZERO)
	add_part(arm_r, cyl(0.075, 0.09, 0.14, 6), plate, HAND_R + Vector3(0, 0.1, -0.03), Vector3(18, 0, 0))
	add_part(arm_r, sphere(0.065, 7, 4), iron, HAND_R)
	add_part(arm_r, cyl(0.025, 0.025, 0.22, 5, false), leather, HAND_R + Vector3(0, 0.02, -0.02), Vector3(-45, 0, 0))
	add_part(arm_r, _nr_path("nr_guard", PackedVector3Array([HAND_R + Vector3(-0.11, -0.03, 0.02), HAND_R + Vector3(0, -0.06, 0.07),
		HAND_R + Vector3(0.12, -0.01, 0.06)]), PackedFloat32Array([0.018, 0.028, 0.012]), 5), blood, Vector3.ZERO)
	add_part(arm_r, _blade_mesh(), plate, Vector3.ZERO)
	add_part(arm_r, _edge_mesh(), glow, Vector3.ZERO)
	# ---- Fx: the drink stream (restarted on cast), death motes (restarted by the kit when the glows die).
	_drink = make_motes(BLOOD, 14, 0.6, 0.12, 1.4, 0.12, false, true)
	_drink.name = "DrinkMotes"
	_drink.position = HAND_L + Vector3(0, 0.1, 0.2) - model_origin(arm_l)
	arm_l.add_child(_drink)
	var dm := make_motes(BLOOD, 12, 1.1, 0.28, 1.3, 0.13, true, true)
	dm.name = "DeathMotes"
	dm.set_meta(&"death_fx", true)
	dm.position = Vector3(0, 0.8, 0)
	$Fx.add_child(dm)
	ensure_shadow_blob(0.48, Color(0.1, 0.03, 0.12, 0.55))


# ================================================================ meshes (cached, model space)

## Tapered tube through `pts` (radii per point), one cached mesh.
static func _nr_path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_nr_append(st, pts, radii, seg)
	st.index()
	return _cached(key, st.commit())


static func _nr_append(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var len_total := d.length() + (0.02 if radii[i + 1] > 0.0 else 0.0)
		var c := cyl(radii[i + 1], radii[i], len_total, seg, i == 0 or i == pts.size() - 2)
		st.append_from(c, 0, Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))


## The sabre's spine curve: from the guard forward-down, curving up at the tip (a sabre's sweep).
static func _blade_point(u: float) -> Vector3:
	var p0 := HAND_R + Vector3(0.0, -0.07, 0.08)
	var p1 := HAND_R + Vector3(0.02, -0.64, 0.30)
	var p2 := HAND_R + Vector3(0.05, -0.94, 0.64)
	var a := p0.lerp(p1, u)
	var b := p1.lerp(p2, u)
	return a.lerp(b, u)


static func _blade_down(u: float) -> Vector3:
	var t := (_blade_point(minf(u + 0.02, 1.0)) - _blade_point(maxf(u - 0.02, 0.0))).normalized()
	return (Vector3.DOWN - t * Vector3.DOWN.dot(t)).normalized()


## Flat curved blade (diamond section: back, two flats, edge), width tapering to the point.
static func _blade_mesh() -> Mesh:
	const KEY := "nr_blade"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 7
	var rings: Array[PackedVector3Array] = []
	for i: int in n + 1:
		var u: float = float(i) / n
		var c := _blade_point(u)
		var dn := _blade_down(u)
		var w: float = lerpf(0.1, 0.0, pow(u, 2.2))
		var side := Vector3(0.018 * (1.0 - u * 0.7), 0, 0)
		rings.append(PackedVector3Array([c - dn * w * 0.35, c + side + dn * w * 0.2, c + dn * w * 0.65, c - side + dn * w * 0.2]))
	for i: int in n:
		for j: int in 4:
			var a := rings[i][j]
			var b := rings[i][(j + 1) % 4]
			var c2 := rings[i + 1][(j + 1) % 4]
			var d := rings[i + 1][j]
			var nrm := (b - a).cross(d - a).normalized()
			st.set_normal(nrm)
			st.add_vertex(a); st.add_vertex(b); st.add_vertex(c2)
			st.add_vertex(a); st.add_vertex(c2); st.add_vertex(d)
	st.generate_normals()
	st.index()
	return _cached(KEY, st.commit())


## The glowing cutting edge along the blade's underside + two hanging blood drops.
static func _edge_mesh() -> Mesh:
	const KEY := "nr_edge"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var n := 6
	for i: int in n + 1:
		var u: float = 0.08 + 0.9 * float(i) / n
		var w: float = lerpf(0.1, 0.0, pow(u, 2.2))
		pts.append(_blade_point(u) + _blade_down(u) * (w * 0.62))
		radii.append(lerpf(0.016, 0.008, u))
	_nr_append(st, pts, radii, 4)
	for u: float in [0.45]:
		var w: float = lerpf(0.1, 0.0, pow(u, 2.2))
		var top := _blade_point(u) + _blade_down(u) * (w * 0.62)
		_nr_append(st, PackedVector3Array([top, top + Vector3(0, -0.05, 0), top + Vector3(0, -0.09, 0)]),
			PackedFloat32Array([0.01, 0.022, 0.0]), 4)
	st.index()
	return _cached(KEY, st.commit())


## Three long silver claws from the left gauntlet, curling forward.
static func _claws_mesh() -> Mesh:
	const KEY := "nr_claws"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for k: int in 3:
		var dx: float = (float(k) - 1.0) * 0.04
		var base := HAND_L + Vector3(dx, -0.02, 0.04)
		_nr_append(st, PackedVector3Array([base, base + Vector3(dx * 0.5, -0.07, 0.08), base + Vector3(dx, -0.15, 0.10)]),
			PackedFloat32Array([0.018, 0.013, 0.0]), 4)
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ hooks / motion

## Blood Frenzy: eyes and blade flare while on (gameplay: `set_status(&"frenzy", true / false)`).
func set_status(id: StringName, on: bool) -> bool:
	if id == &"frenzy":
		_frenzy = on
		_apply_glow(true)
		return true
	return super(id, on)


func glow_level() -> float:
	return super() * (FRENZY_GAIN if _frenzy else 1.0) * (1.0 + 1.6 * _flare)


func _pose_attack(prev: float, t: float) -> bool:
	rot(P_ARM_R, Vector3(_nr_kf(t, R_ARM_R) * DEG, 0, _nr_kf(t, R_ARM_RZ) * DEG))
	rot(P_ARM_L, Vector3(_nr_kf(t, R_ARM_L) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_nr_kf(t, R_CHEST_X) * DEG, _nr_kf(t, R_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _nr_kf(t, R_ROOT_Y), _nr_kf(t, R_ROOT_Z)))
	if _tier == 0:
		rot(P_LEG_L, Vector3(_nr_kf(t, R_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_nr_kf(t, R_LEG_R) * DEG, 0, 0))
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ARM_L, Vector3(_nr_kf(t, C_ARM_L) * DEG, 0, 0))
	rot(P_ARM_R, Vector3(_nr_kf(t, C_ARM_R) * DEG, 0, _nr_kf(t, C_ARM_RZ) * DEG))
	rot(P_CHEST, Vector3(_nr_kf(t, C_CHEST_X) * DEG, 0, 0))
	if _tier == 0:
		rot(P_HEAD, Vector3(_nr_kf(t, C_HEAD_X) * DEG, 0, 0))
	var f: float = snappedf(_nr_kf(t, C_FLARE), 0.05)
	if f != _flare:
		_flare = f
		_apply_glow(true)
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	super(ev)
	match ev:
		&"cast_start":
			if _drink and _tier < 2:
				_drink.restart()
		&"cast_end", &"death_glow_off":
			if _flare != 0.0:
				_flare = 0.0
				_apply_glow(true)


func _on_revive() -> void:
	super()
	_frenzy = false
	_flare = 0.0
	_apply_glow(true)


## Duelist's glide: upright, the sabre held low and steady, the claw hand swinging, a slight shoulder roll.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	if _tier > 0:
		return
	var s: float = sin(TAU * _walk_p)
	rot(P_ROOT, Vector3(4.0 * DEG * w, 0, 0))
	rot(P_CHEST, Vector3(0, -7.0 * DEG * s * w, 2.0 * DEG * s * w))
	rot(P_ARM_R, Vector3(-4.0 * DEG * s * w, 0, 0))
	rot(P_ARM_L, Vector3(-16.0 * DEG * s * w, 0, 0))


## Keyframe track [t, v, ease, ...] (same format as FireModel._kf; ShadowModel has none).
static func _nr_kf(t: float, k: PackedFloat32Array) -> float:
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
