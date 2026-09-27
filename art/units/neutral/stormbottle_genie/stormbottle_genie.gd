extends CharacterModel
## Stormbottle Genie, neutral T3 lightning artillery hired at the tavern (t3-helpers.md 7.2 / 7.3; tiers wave, medium
## effort). Height 2.6. A storm-spirit of white-gold cloud: a broad lumpy torso and huge arms, a storm crest swept back
## from the head, gold collar and sash, its tail pouring in a spiral out of a floating brass bottle below (gold bands,
## a team cord with tassels on the neck). The glows: a rune ring on each gold forearm bracer (Vey's blade runes, 2
## points). It hovers (`fly_height`, bob and a rocking bottle); crackling sparks at the bottle's lip.
## Attack `genie_bolt` (0.6 s, release 0.15): rears back and thrusts the right fist, a jagged white-gold bolt leaps
## from it (the 19.V25 beam VFX is gameplay's; this is the model's own short arc). play_cast (Tempest Bolt, 1.1 s):
## both fists raised overhead, the runes flare, slammed forward with a big bolt and a spark burst.
## Death ("Unbottled"): the cloud is sucked down into the bottle, which drops to the ground (1.0 s).
## Draws: merged pivots + bolt (keep_separate) + lip sparks + blob + hidden vet trim; one-shot bursts. 0 lights.

## Hover height of the bottle's foot (the Art Lab reads the model as hovering).
var fly_height: float = 0.22

const ATTACK_LEN := 0.6
const RELEASE := 0.15
const BOLT_OFF := 0.32
const CAST_LEN := 1.1
const CAST_RELEASE := 0.55
const CAST_BOLT_OFF := 0.8
const FIST_R := Vector3(0.76, 1.13, 0.26)
const FIST_L := Vector3(-0.76, 1.13, 0.26)
const ELBOW := Vector3(0.72, 1.62, 0.05)
const SHOULDER := Vector3(0.5, 2.02, 0.0)
const LIP := Vector3(0, 1.0, 0)
const SPARK := Color(1.0, 0.88, 0.45)

# genie_bolt: cock the fist back, thrust it forward (arm x - = forward), recoil.
static var A_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.10, 35.0, 1, 0.15, -72.0, 2, 0.30, -66.0, 0, 0.60, 0.0, 0])
static var A_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.10, -30.0, 1, 0.15, 25.0, 2, 0.35, 15.0, 0, 0.60, 0.0, 0])
static var A_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.10, 24.0, 1, 0.15, -22.0, 2, 0.35, -12.0, 0, 0.60, 0.0, 0])
static var A_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -12.0, 1, 0.15, 14.0, 2, 0.35, 8.0, 0, 0.60, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.10, -0.10, 1, 0.15, 0.22, 2, 0.30, 0.02, 0, 0.60, 0.0, 0])
# Tempest Bolt: both arms overhead (gather), slam forward, recover.
static var C_ARMS := PackedFloat32Array([0.0, 0.0, 0, 0.40, -165.0, 1, 0.50, -170.0, 0, 0.56, -70.0, 2, 0.80, -62.0, 0, 1.1, 0.0, 0])
static var C_ARMS_Z := PackedFloat32Array([0.0, 0.0, 0, 0.40, 18.0, 1, 0.56, -8.0, 2, 1.1, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.40, -16.0, 1, 0.56, 20.0, 2, 0.80, 14.0, 0, 1.1, 0.0, 0])
static var C_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.40, 0.25, 1, 0.56, -0.05, 2, 0.80, 0.0, 0, 1.1, 0.0, 0])
static var C_FLARE := PackedFloat32Array([0.0, 0.0, 0, 0.40, 1.0, 1, 0.60, 1.0, 0, 1.0, 0.0, 0])

var _bolt: MeshInstance3D
var _burst: GPUParticles3D
var _cast_burst: GPUParticles3D
var _lip_sparks: GPUParticles3D
var _flare: float = 0.0
var _cast_fired: bool = false


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloud := palette(&"shadow_bone")
	var gold := palette(&"unit_gold_trim")
	var brass := palette(&"fire_bronze")
	var dark := palette(&"fire_leather")
	var cord := palette(&"fire_cloth")
	var rune := palette(&"warden_glow")
	var storm := palette(&"shadow_skin")
	var deep := palette(&"shadow_sec_worker")
	# ---- Hips: the brass bottle (foot, round belly, shoulder, neck, lip), gold bands, team cord, the spiral tail.
	add_part(hips, cyl(0.15, 0.19, 0.07, 10), brass, Vector3(0, fly_height + 0.035, 0))
	add_part(hips, sphere(0.3, 12, 6), brass, Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(1.0, 0.85, 1.0))
	add_part(hips, torus(0.27, 0.32, 14), gold, Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0))
	add_part(hips, torus(0.2, 0.235, 12), dark, Vector3(0, 0.36, 0), Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
	add_part(hips, cyl(0.1, 0.24, 0.16, 12), brass, Vector3(0, 0.71, 0))
	add_part(hips, cyl(0.08, 0.1, 0.22, 10), brass, Vector3(0, 0.88, 0))
	add_part(hips, torus(0.075, 0.125, 10), gold, Vector3(0, 0.99, 0))
	add_part(hips, torus(0.085, 0.12, 8), cord, Vector3(0, 0.84, 0), Vector3(8, 0, 0))
	for s: float in [-1.0, 1.0]:
		add_part(hips, _gn_path("gn_tassel_%s" % s, PackedVector3Array([Vector3(0.09 * s, 0.84, 0.05),
			Vector3(0.15 * s, 0.74, 0.1), Vector3(0.17 * s, 0.62, 0.11)]), PackedFloat32Array([0.018, 0.016, 0.014]), 4),
			cord, Vector3.ZERO)
		add_part(hips, cyl(0.0, 0.04, 0.1, 6), cord, Vector3(0.17 * s, 0.58, 0.11), Vector3(180, 0, 0))
	add_part(hips, _tail_mesh(), deep, Vector3.ZERO)
	add_part(hips, _tail_wisp_mesh(), gold, Vector3.ZERO)
	_lip_sparks = make_motes(SPARK, 4, 0.45, 0.1, 0.8, 0.08)
	_lip_sparks.name = "LipSparks"
	_lip_sparks.set_meta(&"keep_separate", true)
	_lip_sparks.position = LIP - model_origin(hips)
	hips.add_child(_lip_sparks)
	# ---- Chest: the lumpy storm torso (waist, chest, shoulder and back puffs), gold sash and collar, storm spikes.
	add_part(chest, sphere(0.26, 10, 5), storm, Vector3(0, 1.4, 0.02), Vector3.ZERO, Vector3(1.0, 0.9, 0.9))
	add_part(chest, sphere(0.42, 12, 6), cloud, Vector3(0, 1.78, 0.0), Vector3(-8, 0, 0), Vector3(1.15, 0.92, 0.82))
	for p: Vector3 in [Vector3(-0.2, 1.62, 0.22), Vector3(0.2, 1.62, 0.22), Vector3(0, 1.95, -0.22)]:
		add_part(chest, sphere(0.2, 8, 5), storm if p.z > 0.0 else cloud, p, Vector3.ZERO, Vector3(1.0, 0.85, 0.9))
	add_part(chest, torus(0.26, 0.33, 12), gold, Vector3(0, 1.46, 0.02), Vector3(-6, 0, 0), Vector3(1.0, 1.4, 0.9))
	add_part(chest, torus(0.13, 0.2, 12), gold, Vector3(0, 2.1, 0.02), Vector3(-10, 0, 0), Vector3(1.0, 1.2, 1.0))
	add_part(chest, box(Vector3(0.09, 0.09, 0.05)), brass, Vector3(0, 1.47, 0.3), Vector3(0, 0, 45))
	# Storm-dark puffs under the pecs and round the flanks (value breaks inside the cloud), a gold medallion.
	for s: float in [-1.0, 1.0]:
		add_part(chest, sphere(0.17, 8, 4), deep, Vector3(0.37 * s, 1.56, 0.04), Vector3.ZERO, Vector3(1.0, 0.9, 1.0))
		add_part(chest, sphere(0.15, 8, 4), storm, Vector3(0.3 * s, 1.5, -0.2))
		add_part(head, sphere(0.08, 7, 4), storm, Vector3(0.15 * s, 2.24, 0.12))
	add_part(chest, sphere(0.12, 8, 4), deep, Vector3(0, 1.68, 0.28), Vector3.ZERO, Vector3(1.0, 1.3, 0.6))
	add_part(chest, cyl(0.1, 0.1, 0.035, 12), gold, Vector3(0, 1.86, 0.36), Vector3(75, 0, 0))
	add_part(chest, sphere(0.045, 6, 3), dark, Vector3(0, 1.865, 0.385))
	for s: float in [-1.0, 1.0]:
		add_part(chest, _gn_path("gn_chain_%s" % s, PackedVector3Array([Vector3(0.14 * s, 2.06, 0.18), Vector3(0.1 * s, 1.97, 0.32),
			Vector3(0.03 * s, 1.9, 0.36)]), PackedFloat32Array([0.018, 0.018, 0.018]), 4), gold, Vector3.ZERO)
	for s: float in [-1.0, 1.0]:
		for k: int in 2:
			add_part(chest, cyl(0.0, 0.1 - 0.02 * k, 0.42 - 0.08 * k, 6), storm,
				Vector3(0.28 * s + 0.12 * s * k, 2.08 - 0.08 * k, -0.28), Vector3(-58 + 8 * k, 0, -28 * s - 12 * s * k))
	# ---- Head: a broad cloud head, gold eye slits and brow, a pointed cloud beard, the storm crest swept back.
	add_part(head, sphere(0.2, 10, 5), cloud, Vector3(0, 2.3, 0.08), Vector3.ZERO, Vector3(0.95, 1.0, 0.95))
	add_part(head, box(Vector3(0.26, 0.06, 0.1)), cloud, Vector3(0, 2.365, 0.22), Vector3(-10, 0, 0))
	for s: float in [-1.0, 1.0]:
		add_part(head, box(Vector3(0.075, 0.03, 0.03)), gold, Vector3(0.065 * s, 2.32, 0.268), Vector3(0, 0, -14 * s))
	add_part(head, cyl(0.0, 0.1, 0.3, 6), storm, Vector3(0, 2.1, 0.2), Vector3(160, 0, 0))
	for k: int in 3:
		var sx: float = (float(k) - 1.0) * 0.1
		add_part(head, cyl(0.0, 0.08 - 0.01 * absf(sx) * 10.0 * 0.1, 0.46 - 0.1 * absf(float(k) - 1.0), 6), cloud,
			Vector3(sx, 2.5, -0.1), Vector3(-62, 0, -sx * 120.0))
	add_part(head, torus(0.05, 0.075, 8), gold, Vector3(0, 2.49, 0.02), Vector3(-60, 0, 0))
	var trim := add_part(head, torus(0.16, 0.2, 12), gold, Vector3(0, 2.44, 0.06), Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Arms: huge cloud arms, gold bracers with a glowing rune ring, big fists.
	for arm: Node3D in [arm_l, arm_r]:
		var sx: float = -1.0 if arm == arm_l else 1.0
		var m := Vector3(sx, 1, 1)
		add_part(arm, sphere(0.25, 10, 5), cloud, SHOULDER * m + Vector3(0.04 * sx, 0.02, 0), Vector3.ZERO, Vector3(1.0, 0.9, 1.0))
		add_part(arm, _gn_path("gn_arm_%s" % sx, PackedVector3Array([SHOULDER * m, ELBOW * m, FIST_R * m + Vector3(0, 0.1, -0.04)]),
			PackedFloat32Array([0.17, 0.16, 0.13]), 9), storm, Vector3.ZERO)
		var fa := (ELBOW * m).lerp(FIST_R * m, 0.55)
		add_part(arm, cyl(0.155, 0.17, 0.26, 10), gold, fa, Vector3(-23, 0, -3 * sx))
		add_part(arm, torus(0.155, 0.19, 12), rune, fa + Vector3(0, 0.02, -0.01), Vector3(-23, 0, -3 * sx), Vector3(1.0, 1.3, 1.0))
		add_part(arm, sphere(0.17, 10, 5), cloud, FIST_R * m, Vector3.ZERO, Vector3(0.95, 1.0, 1.1))
		var fd := (FIST_R - ELBOW).normalized() * m
		for e: float in [-0.14, 0.14]:
			add_part(arm, cyl(0.172, 0.172, 0.035, 12), dark, fa + fd * e, Vector3(-23, 0, -3 * sx))
		var ua := (SHOULDER * m).lerp(ELBOW * m, 0.55)
		add_part(arm, torus(0.15, 0.2, 12), gold, ua, Vector3(0, 0, 60 * sx), Vector3(1.0, 1.3, 1.0))
		add_part(arm, sphere(0.13, 8, 4), storm, ua + Vector3(-0.08 * sx, -0.06, -0.08))
		add_part(arm, sphere(0.07, 6, 4), cloud, FIST_R * m + Vector3(-0.1 * sx, 0.06, 0.1))
	# The bolt from the right fist (shown at the release), in the arm's rest frame along the forearm.
	_bolt = add_part(arm_r, _bolt_mesh(), rune, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Bolt")
	_bolt.visible = false
	# ---- Fx: bolt spark burst at the fist, cast burst ring, death motes (the cloud sucked into the bottle).
	_burst = make_motes(SPARK, 12, 0.4, 0.12, 2.4, 0.14, false, true)
	_burst.name = "BoltBurst"
	_burst.position = FIST_R + Vector3(0, -0.1, 0.1) - model_origin(arm_r)
	arm_r.add_child(_burst)
	_cast_burst = make_motes(SPARK, 18, 0.6, 0.5, 2.0, 0.16, true, true)
	_cast_burst.name = "TempestBurst"
	_cast_burst.position = Vector3(0, 1.2, 1.0)
	$Fx.add_child(_cast_burst)
	var dm := make_motes(SPARK, 14, 0.9, 0.2, 1.8, 0.13, false, true)
	dm.name = "DeathMotes"
	dm.set_meta(&"death_fx", true)
	dm.position = Vector3(0, 1.0, 0)
	$Fx.add_child(dm)
	ensure_shadow_blob(0.55, Color(0.06, 0.05, 0.03, 0.4))


# ================================================================ meshes (cached, model space)

## Tapered tube through `pts` (radii per point), one cached mesh.
static func _gn_path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_gn_append(st, pts, radii, seg)
	st.index()
	return _cached(key, st.commit())


static func _gn_append(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var len_total := d.length() + (0.03 if radii[i + 1] > 0.0 else 0.0)
		var c := cyl(radii[i + 1], radii[i], len_total, seg, i == 0 or i == pts.size() - 2)
		st.append_from(c, 0, Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))


static func _tail_point(u: float) -> Vector3:
	var a: float = u * TAU * 1.25
	var r: float = lerpf(0.02, 0.1, u)
	return Vector3(cos(a) * r, lerpf(0.97, 1.45, u), sin(a) * r)


## The tail: a widening spiral of cloud pouring up out of the bottle's lip into the waist, with puffs along it.
static func _tail_mesh() -> Mesh:
	const KEY := "gn_tail"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var n := 8
	for i: int in n + 1:
		var u: float = float(i) / n
		pts.append(_tail_point(u))
		radii.append(lerpf(0.06, 0.22, u * u))
	_gn_append(st, pts, radii, 9)
	for u: float in [0.3, 0.6]:
		var p := _tail_point(u)
		st.append_from(sphere(lerpf(0.09, 0.17, u), 8, 4), 0, Transform3D(Basis(), p + Vector3(p.x, 0, p.z).normalized() * 0.06))
	st.index()
	return _cached(KEY, st.commit())


## A thin gold wisp coiling round the tail the other way.
static func _tail_wisp_mesh() -> Mesh:
	const KEY := "gn_wisp"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var n := 10
	for i: int in n + 1:
		var u: float = float(i) / n
		var a: float = -u * TAU * 1.4 + 1.0
		var r: float = lerpf(0.08, 0.26, u)
		pts.append(Vector3(cos(a) * r, lerpf(0.98, 1.38, u), sin(a) * r))
		radii.append(lerpf(0.014, 0.022, u))
	return _gn_path(KEY, pts, radii, 4)


## A jagged bolt leaving the right fist along the forearm (arm rest frame), ~2.4 m, zigzagging, forked at the end.
static func _bolt_mesh() -> Mesh:
	const KEY := "gn_bolt"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var d := (FIST_R - ELBOW).normalized()
	var side := d.cross(Vector3.RIGHT).normalized()
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var zig: Array[float] = [0.0, 0.12, -0.14, 0.16, -0.1, 0.14, -0.12, 0.05]
	for i: int in zig.size():
		var u: float = float(i) / (zig.size() - 1)
		pts.append(FIST_R + d * (0.14 + 2.3 * u) + side * zig[i] + Vector3(zig[i] * 0.5, 0, 0))
		radii.append(lerpf(0.05, 0.025, u))
	_gn_append(st, pts, radii, 4)
	var fork_a := pts[4]
	_gn_append(st, PackedVector3Array([fork_a, fork_a + d * 0.4 + side * -0.25, fork_a + d * 0.75 + side * -0.2]),
		PackedFloat32Array([0.03, 0.022, 0.012]), 4)
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ motion

func glow_level() -> float:
	return super() * (1.0 + 2.0 * _flare)


func _set_flare(v: float) -> void:
	v = snappedf(v, 0.05)
	if v != _flare:
		_flare = v
		_apply_glow(true)


func _pose_attack(prev: float, t: float) -> bool:
	rot(P_ARM_R, Vector3(_gn_kf(t, A_ARM_R) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_gn_kf(t, A_CHEST_X) * DEG, _gn_kf(t, A_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _gn_kf(t, A_ROOT_Z)))
	if _tier == 0:
		rot(P_ARM_L, Vector3(_gn_kf(t, A_ARM_L) * DEG, 0, 0))
	if _bolt:
		_bolt.visible = t >= RELEASE and t < BOLT_OFF
	_set_flare(0.6 * smoothstep(0.0, RELEASE, t) * (1.0 - smoothstep(BOLT_OFF, 0.5, t)))
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(_spell: StringName, t: float) -> float:
	var a: float = _gn_kf(t, C_ARMS) * DEG
	var z: float = _gn_kf(t, C_ARMS_Z) * DEG
	rot(P_ARM_R, Vector3(a, 0, z))
	rot(P_ARM_L, Vector3(a, 0, -z))
	rot(P_CHEST, Vector3(_gn_kf(t, C_CHEST_X) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _gn_kf(t, C_ROOT_Y), 0))
	_set_flare(_gn_kf(t, C_FLARE))
	if _bolt:
		_bolt.visible = t >= CAST_RELEASE and t < CAST_BOLT_OFF
	if not _cast_fired and t >= CAST_RELEASE:
		_cast_fired = true
		if _tier < 2:
			if _cast_burst:
				_cast_burst.restart()
			if _burst:
				_burst.restart()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"release":
			if _burst and _tier < 2:
				_burst.restart()
		&"cast_start":
			_cast_fired = false
		&"attack_end", &"cast_end", &"death_glow_off":
			if _bolt:
				_bolt.visible = false
			_set_flare(0.0)
			if ev == &"death_glow_off" and _lip_sparks:
				_lip_sparks.emitting = false


func _on_revive() -> void:
	_flare = 0.0
	if _bolt:
		_bolt.visible = false
	if _lip_sparks:
		_lip_sparks.emitting = true
	_apply_glow(true)


## Hover: a slow deep bob, the bottle rocking, the head looking about.
func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.07 * s, 0))
	_write_rot(P_CHEST, _rest_rot[P_CHEST] + Vector3(2.0 * DEG * s, 0, 0))
	if _tier == 0:
		_write_rot(P_HIPS, _rest_rot[P_HIPS] + Vector3(0, 0, 4.0 * DEG * sin(0.7 * ph)))
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + Vector3(0, 8.0 * DEG * sin(0.5 * ph + 1.0), 0))


func _pose_idle(w: float) -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	pos(P_ROOT, Vector3(0, 0.07 * s * w, 0))
	rot(P_CHEST, Vector3(2.0 * DEG * s * w, 0, 0))
	rot(P_HIPS, Vector3(0, 0, 4.0 * DEG * sin(0.7 * ph) * w))
	rot(P_HEAD, Vector3(0, 8.0 * DEG * sin(0.5 * ph + 1.0) * w, 0))


## Glide: leans into the move, the bottle trails (tilts back), arms sway slowly.
func _pose_walk(w: float, _rate: float) -> void:
	var s: float = sin(TAU * _walk_p)
	rot(P_ROOT, Vector3(8.0 * DEG * w, 0, 0))
	rot(P_HIPS, Vector3(-14.0 * DEG * w, 0, 3.0 * DEG * s * w))
	rot(P_CHEST, Vector3(0, 5.0 * DEG * s * w, 0))
	rot(P_ARM_L, Vector3(-10.0 * DEG * s * w, 0, 0))
	rot(P_ARM_R, Vector3(10.0 * DEG * s * w, 0, 0))
	pos(P_ROOT, Vector3(0, 0.04 * sin(2.0 * TAU * _walk_p) * w, 0))


## Unbottled: the cloud swirls and is sucked down into the bottle, the bottle drops to the ground.
func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var k: float = _ease_in(clampf(t / 0.75, 0.0, 1.0))
	rot(P_CHEST, Vector3(0, 540.0 * DEG * k, 0))
	pos(P_CHEST, Vector3(0, -0.9 * k, 0))
	rot(P_ARM_L, Vector3(0, 0, 70.0 * DEG * k))
	rot(P_ARM_R, Vector3(0, 0, -70.0 * DEG * k))
	_root_scale *= Vector3(lerpf(1.0, 0.45, k), lerpf(1.0, 0.3, k), lerpf(1.0, 0.45, k))
	var drop: float = _ease_in(clampf((t - 0.6) / 0.25, 0.0, 1.0))
	pos(P_ROOT, Vector3(0, -fly_height * 0.3 * drop, 0))
	rot(P_ROOT, Vector3(0, 0, 70.0 * DEG * drop))
	if t >= 0.3:
		_glows_dead()
	if _shadow:
		_shadow.transparency = clampf((t - 0.7) / 0.3, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


## Keyframe track [t, v, ease, ...] (same format as FireModel._kf).
static func _gn_kf(t: float, k: PackedFloat32Array) -> float:
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
