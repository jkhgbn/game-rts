extends NatureWarModel
## Vinelasher, Nature T2 soldier (rush-balance.md 5.1 / 5.4; effort trial, medium). Height 1.8, reach 3.0 m.
## A lean bark warrior: brown bark body (keeps it off the grass hue), a team leaf sash + left leaf pauldron, a swept
## leaf hood with two pale thorn horns. The silhouette hook: a thorn whip wound 3 times around the right arm that
## drops into a big hanging loop (the circle read), its tail ending in the only glow point (the tip).
## Attack `whip_lash` (0.7 s): the loop is swapped for a 3 m lash that cracks forward from the arm, a pink blossom
## on the handle. play_cast (Snare Lash): the lash whirls up overhead and slams down in front.
## Draws: merged pivots + 4 keep_separate parts (loop, loop tip, lash, lash tip) + blob + hidden vet trim.

const ATTACK_LEN := 0.7
const CAST_LEN := 1.0
const LASH_OFF_AT := 0.58   # attack time when the loop comes back
const HAND := Vector3(0.33, 0.86, 0.12)
const HANDLE_END := Vector3(0.33, 0.64, 0.14)
const LASH_LEN := 3.0

# whip_lash tracks [t, value, ease] (NatureWarModel._kf). Arm x: + swings back, - raises forward.
static var W_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, 70.0, 1, 0.22, -96.0, 2, 0.40, -88.0, 0, 0.70, 0.0, 0])
static var W_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.12, 5.0, 1, 0.22, 20.0, 2, 0.45, 14.0, 0, 0.70, 0.0, 0])
static var W_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, -28.0, 1, 0.22, 22.0, 2, 0.45, 10.0, 0, 0.70, 0.0, 0])
static var W_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, -8.0, 1, 0.22, 12.0, 2, 0.45, 6.0, 0, 0.70, 0.0, 0])
static var W_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.08, 1, 0.22, 0.18, 2, 0.45, 0.12, 0, 0.70, 0.0, 0])
static var W_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -40.0, 1, 0.22, 30.0, 2, 0.70, 0.0, 0])
# Snare Lash: whirl overhead, slam forward-down.
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.30, -175.0, 1, 0.45, -150.0, 0, 0.56, -82.0, 2, 0.80, -80.0, 0, 1.0, 0.0, 0])
static var C_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0, 0.30, -20.0, 1, 0.45, 20.0, 0, 0.56, 0.0, 2, 1.0, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.30, -12.0, 1, 0.56, 18.0, 2, 0.80, 12.0, 0, 1.0, 0.0, 0])

var _loop: MeshInstance3D
var _loop_tip: MeshInstance3D
var _lash: MeshInstance3D
var _lash_tip: MeshInstance3D
var _lash_on: bool = false
var _loop_hidden: bool = false   # the loop is hidden once the body lies down (it would stick out of the moss)


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
	var dark := nature(&"nature_bark_dark")
	var thorn := nature(&"nature_thorn")
	var blossom := nature(&"nature_blossom")
	var glow := nature(&"nature_glow")
	# ---- Legs: long lean bark legs, dark feet.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _leg_mesh(sx), dark, Vector3.ZERO)
		add_part(leg, sphere(0.075, 8, 4), dark, Vector3(0.13 * sx, 0.06, 0.06), Vector3.ZERO, Vector3(1.0, 0.7, 1.6))
	# ---- Hips: bark belt + team-dark leaf skirt.
	add_part(hips, cyl(0.19, 0.2, 0.12, 10), dark, Vector3(0, 0.96, 0))
	add_part(hips, leaf_ring_mesh(7, 0.15, Vector3(0.16, 0.035, 0.34), -70.0, 10.0), cdark, Vector3(0, 0.98, 0))
	# ---- Chest: lean bark torso, team sash across it, left leaf pauldron with thorns (the asymmetry).
	add_part(chest, sphere(0.22, 10, 6), bark, Vector3(0, 1.24, 0), Vector3(-6, 0, 0), Vector3(1.05, 1.35, 0.78))
	add_part(chest, box(Vector3(0.12, 0.72, 0.06)), cloth, Vector3(0.02, 1.22, 0.16), Vector3(-8, 0, 38))
	add_part(chest, box(Vector3(0.12, 0.72, 0.06)), cloth, Vector3(0.02, 1.22, -0.16), Vector3(8, 0, 38))
	add_part(chest, cyl(0.07, 0.09, 0.14, 8), dark, Vector3(0, 1.50, 0.01))
	add_leaf(chest, Vector3(-0.30, 1.50, 0.0), Vector3(0.34, 0.07, 0.40), cloth, Vector3(0, -90, -30))
	add_thorns(chest, Vector3(-0.32, 1.52, 0.0), 3, 0.07, 0.035, 0.22, 35.0, thorn)
	# ---- Head: bark head, dark eye slit, pale thorn horns swept back, team leaf hood.
	add_part(head, sphere(0.14, 10, 6), bark, Vector3(0, 1.64, 0.03), Vector3.ZERO, Vector3(0.9, 1.15, 1.0))
	add_part(head, box(Vector3(0.18, 0.035, 0.05)), palette(&"unit_eye_dark"), Vector3(0, 1.67, 0.16))
	add_part(head, _horns_mesh(), thorn, Vector3.ZERO)
	add_leaf(head, Vector3(0, 1.76, -0.02), Vector3(0.30, 0.06, 0.46), cloth, Vector3(-18, 180, 0))
	var trim := add_part(head, torus(0.11, 0.15, 10), palette(&"unit_gold_trim"), Vector3(0, 1.72, 0.02),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: bark limb, thorn bracer.
	add_part(arm_l, _arm_mesh(-1.0), dark, Vector3.ZERO)
	add_part(arm_l, cyl(0.07, 0.085, 0.2, 8), thorn, Vector3(-0.33, 1.00, 0.07), Vector3(-20, 0, 0))
	add_part(arm_l, sphere(0.07, 8, 4), dark, Vector3(-0.33, 0.86, 0.12))
	# ---- Right arm: the whip arm. Bark limb, the whip wound 3 times round it, fist, handle with a pink blossom.
	add_part(arm_r, _arm_mesh(1.0), dark, Vector3.ZERO)
	add_part(arm_r, _coil_mesh(), thorn, Vector3.ZERO)
	add_part(arm_r, sphere(0.075, 8, 4), dark, HAND)
	add_part(arm_r, cyl(0.04, 0.035, 0.30, 6), dark, (HAND + HANDLE_END) * 0.5 + Vector3(0, 0.03, 0))
	add_part(arm_r, leaf_ring_mesh(5, 0.03, Vector3(0.09, 0.03, 0.12), 20.0), blossom, HAND + Vector3(0, 0.07, 0))
	# The hanging loop + tail and its glowing tip (shown at rest), the 3 m lash + tip (shown while lashing).
	_loop = add_part(arm_r, _loop_mesh(), thorn, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "WhipLoop")
	_loop_tip = add_part(arm_r, sphere(0.075, 8, 4), glow, _loop_tip_pos(), Vector3.ZERO, Vector3.ONE, true, "WhipLoopTip")
	_lash = add_part(arm_r, _lash_mesh(), thorn, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "WhipLash")
	_lash_tip = add_part(arm_r, sphere(0.09, 8, 4), glow, _lash_tip_pos(), Vector3.ZERO, Vector3.ONE, true, "WhipLashTip")
	_lash.visible = false
	_lash_tip.visible = false
	# ---- Fx
	add_hit_burst(Vector3(0, 1.2, 0.05), Color(0.46, 0.66, 0.20), 7)
	add_death_bloom(Vector3(0, 0.95, 0.1), 0.3, 8, 10, Color(0.55, 0.42, 0.24))
	ensure_shadow_blob(0.42)


# ================================================================ meshes (cached, model space)

static func _leg_mesh(side: float) -> Mesh:
	return tapered_path_mesh("vl_med_leg_%s" % side, PackedVector3Array([Vector3(0.12 * side, 0.94, 0.0),
		Vector3(0.13 * side, 0.50, 0.05), Vector3(0.13 * side, 0.08, -0.01)]), PackedFloat32Array([0.09, 0.07, 0.055]))


static func _arm_mesh(side: float) -> Mesh:
	return tapered_path_mesh("vl_med_arm_%s" % side, PackedVector3Array([Vector3(0.26 * side, 1.43, 0.0),
		Vector3(0.33 * side, 1.14, 0.0), HAND * Vector3(side, 1, 1)]), PackedFloat32Array([0.07, 0.06, 0.055]))


## Two pale thorn horns swept back from the brow (the top reads light).
static func _horns_mesh() -> Mesh:
	const KEY := "vl_med_horns"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		var m := tapered_path_mesh("vl_med_horn_%s" % s, PackedVector3Array([Vector3(0.07 * s, 1.72, 0.08),
			Vector3(0.13 * s, 1.84, -0.04), Vector3(0.16 * s, 1.88, -0.22)]), PackedFloat32Array([0.04, 0.03, 0.0]))
		st.append_from(m, 0, Transform3D.IDENTITY)
	return _cached(KEY, _indexed(st))


## The whip wound 3 times round the right arm: a helix around shoulder -> elbow -> wrist.
static func _coil_mesh() -> Mesh:
	const KEY := "vl_med_coil"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var axis := PackedVector3Array([Vector3(0.28, 1.36, 0.0), Vector3(0.33, 1.14, 0.0), Vector3(0.33, 0.93, 0.10)])
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var n := 20
	for i: int in n + 1:
		var u: float = float(i) / n
		var seg_u: float = u * 2.0
		var a: Vector3 = axis[0].lerp(axis[1], seg_u) if seg_u <= 1.0 else axis[1].lerp(axis[2], seg_u - 1.0)
		var ang: float = u * TAU * 3.0
		var r: float = 0.10 - 0.02 * u
		pts.append(a + Vector3(cos(ang) * r, 0.0, sin(ang) * r))
		radii.append(0.042)
	return tapered_path_mesh(KEY, pts, radii, 5, false)


## Loop centre / plane: a big vertical ring hanging beside the right leg, tilted back so the top camera sees it.
static func _loop_point(ang: float) -> Vector3:
	var c := Vector3(0.50, 0.42, 0.20)
	var r: float = 0.27
	var p := Vector3(sin(ang) * r, cos(ang) * r, 0.0)
	return c + Basis(Vector3.RIGHT, deg_to_rad(-35.0)) * p


## From the handle end into the loop (one full turn), then the tail climbs behind the arm to the tip on the shoulder.
static func _loop_mesh() -> Mesh:
	const KEY := "vl_med_loop"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var pts := PackedVector3Array([HANDLE_END])
	var radii := PackedFloat32Array([0.045])
	var n := 12
	for i: int in n + 1:
		var ang: float = -0.35 + float(i) / n * TAU * 1.08
		pts.append(_loop_point(ang))
		radii.append(0.045)
	pts.append(Vector3(0.47, 0.95, -0.10))
	radii.append(0.04)
	pts.append(Vector3(0.42, 1.22, -0.13))
	radii.append(0.035)
	pts.append(_loop_tip_pos())
	radii.append(0.03)
	return tapered_path_mesh(KEY, pts, radii, 5, false)


static func _loop_tip_pos() -> Vector3:
	return Vector3(0.37, 1.47, -0.10)


## The 3 m lash in the arm's rest frame (points down from the handle; the swing aims it forward). A light wave.
static func _lash_mesh() -> Mesh:
	const KEY := "vl_med_lash"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var n := 10
	for i: int in n + 1:
		var u: float = float(i) / n
		pts.append(HANDLE_END + Vector3(0.02 * u, -LASH_LEN * u, 0.12 * sin(u * PI * 1.5) * u))
		radii.append(lerpf(0.05, 0.028, u))
	return tapered_path_mesh(KEY, pts, radii, 6, false)


static func _lash_tip_pos() -> Vector3:
	return HANDLE_END + Vector3(0.02, -LASH_LEN, 0.12 * sin(PI * 1.5))


# ================================================================ motion

func _set_lash(on: bool) -> void:
	if on == _lash_on or _lash == null:
		return
	_lash_on = on
	_lash.visible = on
	_lash_tip.visible = on
	_loop.visible = not on
	_loop_tip.visible = not on


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"whip_lash":
		return super._pose_attack(prev, t)
	_set_lash(t < LASH_OFF_AT)
	rot(P_ARM_R, Vector3(_kf(t, W_ARM_R) * DEG, 0, _kf(t, W_ARM_RZ) * DEG))
	rot(P_CHEST, Vector3(_kf(t, W_CHEST_X) * DEG, _kf(t, W_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _kf(t, W_ROOT_Z)))
	if _tier == 0:
		rot(P_ARM_L, Vector3(_kf(t, W_ARM_L) * DEG, 0, 0))
	if prev < 0.22 and t >= 0.22:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	_set_lash(t < 0.85)
	rot(P_ARM_R, Vector3(_kf(t, C_ARM_R) * DEG, 0, _kf(t, C_ARM_RZ) * DEG))
	rot(P_CHEST, Vector3(_kf(t, C_CHEST_X) * DEG, 0, 0))
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"attack_end" or ev == &"cast_end" or ev == &"death_glow_off":
		_set_lash(false)


func _war_process(_dt: float) -> void:
	if _lash_on and (_dead or _action == &""):
		_set_lash(false)
	if _dead and not _loop_hidden and _death_t > 0.6:
		_loop_hidden = true
		_loop.visible = false
		_loop_tip.visible = false


func _war_revive() -> void:
	_set_lash(false)
	_loop_hidden = false
	_loop.visible = true
	_loop_tip.visible = true


## Prowl: upright lean stride, the whip arm steady, the free arm swinging.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	if _tier > 0:
		return
	var s: float = sin(TAU * _walk_p)
	rot(P_ROOT, Vector3(5.0 * DEG * w, 0, 0))
	rot(P_CHEST, Vector3(0, -6.0 * DEG * s * w, 0))
	rot(P_ARM_L, Vector3(-22.0 * DEG * s * w, 0, 0))
	rot(P_ARM_R, Vector3(8.0 * DEG * s * w, 0, 0))


## Fidget: lifts the whip arm and rolls the wrist, the loop swaying.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.3, 0.9, 1.3, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-35.0 * DEG * up, 0, 10.0 * DEG * sin(t * 9.0) * up))
	rot(P_HEAD, Vector3(0, 15.0 * DEG * up, 0))
	return 1.3
