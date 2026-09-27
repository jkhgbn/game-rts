extends NatureWarModel
## Thistle Darter, Nature T1 skirmisher (new-units-12.md 6; tiers wave, medium). Height 1.2, radius 0.4, range 8.
## A small quick sprite-like hunter: long thin bark legs with pointed leaf shoes, a lean bark jerkin with a team sash
## and a dark leaf skirt, a big puffy THISTLE-DOWN CLOAK (cream-white fluff balls over the shoulders and back, seed
## filaments sticking out: the main mass is off the grass hue), a tan face with long ears and big dark eyes under a
## team THISTLE-BULB hood crowned by a ring of pink thistle spikes around a glowing seed (glow point 1).
## The silhouette hook: a long reed BLOWPIPE (1 m) held low in both hands, pointing forward-down, a glowing seed dart
## in its mouth (glow point 2). Rest = the aim pose rotated 45 deg down about the shoulder axis, so both arms raise
## it level to the mouth together.
## Attack `blow_dart` (0.55 s, release 0.14): the pipe snaps up to the lips, a puff (chest / head punch forward,
## pollen puff at the muzzle), the dart is gone until the pipe comes down. play_cast(&"skitter") 0.5 s: a quick hop
## forward with a trail of seed fluff. Fidget: blows a seed-fluff puff into the air and watches it.

const ATTACK_LEN := 0.55
const CAST_LEN := 0.5
const REST_DEG := 38.0
const S_L := Vector3(-0.18, 0.88, 0.0)
const S_R := Vector3(0.18, 0.88, 0.0)
# aim space (the pipe level at the mouth), model coordinates before the rest rotation
const MOUTH := Vector3(0.0, 0.99, 0.14)
const PIPE_END := Vector3(0.0, 0.99, 0.98)
const HAND_R := Vector3(0.04, 0.955, 0.27)
const HAND_L := Vector3(-0.03, 0.955, 0.46)

var _dart: MeshInstance3D
var _puff: GPUParticles3D
var _trail: GPUParticles3D
var _dart_gone: bool = false
var _flare: float = 0.0
var _dart_written: float = -1.0
var _fired: bool = false
var _fpuff: bool = false


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
	var skin := nature(&"nature_skin")
	var thorn := nature(&"nature_thorn")
	var blossom := nature(&"nature_blossom")
	var glow := nature(&"nature_glow")
	var down := palette(&"shadow_bone")
	# ---- Legs: long thin bark legs, pointed leaf shoes.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, tapered_path_mesh("td_leg_%s" % sx, PackedVector3Array([Vector3(0.08 * sx, 0.58, 0.0),
			Vector3(0.10 * sx, 0.32, 0.06), Vector3(0.09 * sx, 0.07, -0.02)]), PackedFloat32Array([0.055, 0.042, 0.035])),
			dark, Vector3.ZERO)
		add_part(leg, sphere(0.06, 8, 4), bark, Vector3(0.09 * sx, 0.035, 0.05), Vector3(-6, 0, 0), Vector3(1.0, 0.55, 2.0))
		add_part(leg, cyl(0.0, 0.03, 0.09, 5), bark, Vector3(0.09 * sx, 0.05, 0.19), Vector3(70, 0, 0))
	# ---- Hips: dark team leaf skirt.
	add_part(hips, leaf_ring_mesh(7, 0.10, Vector3(0.12, 0.03, 0.22), -68.0, 12.0), cdark, Vector3(0, 0.62, 0))
	# ---- Chest: lean bark jerkin, team sash, thorn belt, the thistle-down cloak + seed filaments.
	add_part(chest, sphere(0.14, 8, 5), bark, Vector3(0, 0.75, 0.0), Vector3(-4, 0, 0), Vector3(1.0, 1.35, 0.85))
	add_part(chest, box(Vector3(0.08, 0.40, 0.04)), cloth, Vector3(0.0, 0.76, 0.115), Vector3(-6, 0, -34))
	add_part(chest, cyl(0.13, 0.135, 0.05, 9), thorn, Vector3(0, 0.63, 0.0))
	add_part(chest, _down_mesh(), down, Vector3.ZERO)
	add_part(chest, _filament_mesh(), down, Vector3.ZERO)
	# ---- Head: tan face, long swept ears, big dark eyes, team thistle-bulb hood with bracts, pink spike crown,
	# glowing seed in the middle.
	add_part(head, sphere(0.105, 9, 5), skin, Vector3(0, 1.00, 0.05), Vector3.ZERO, Vector3(0.95, 1.05, 1.0))
	add_part(head, cyl(0.0, 0.02, 0.05, 5), skin, Vector3(0, 0.99, 0.16), Vector3(80, 0, 0))
	for s: float in [-1.0, 1.0]:
		add_part(head, box(Vector3(0.05, 0.035, 0.03)), palette(&"unit_eye_dark"), Vector3(0.042 * s, 1.02, 0.135),
			Vector3(0, 0, 12.0 * s))
		add_part(head, cyl(0.0, 0.04, 0.22, 6), skin, Vector3(0.14 * s, 1.05, -0.04), Vector3(-25, 0, -70.0 * s),
			Vector3(1.0, 1.0, 0.5))
	add_part(head, sphere(0.14, 8, 5), cloth, Vector3(0, 1.08, -0.035), Vector3(-10, 0, 0), Vector3(1.0, 0.95, 1.12))
	add_part(head, leaf_ring_mesh(5, 0.08, Vector3(0.09, 0.025, 0.15), 35.0, 0.0), cdark, Vector3(0, 1.13, -0.04))
	add_part(head, thorn_ring_mesh(7, 0.05, 0.026, 0.18, 16.0, 0.0), blossom, Vector3(0, 1.17, -0.04))
	add_part(head, sphere(0.08, 8, 4), glow, Vector3(0, 1.30, -0.04))
	var trim := add_part(head, torus(0.12, 0.15, 10), palette(&"unit_gold_trim"), Vector3(0, 1.14, -0.04),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Arms + blowpipe (authored in aim space, rotated REST_DEG down about the shoulder axis).
	add_part(arm_r, _arm_mesh("td_arm_r", S_R, HAND_R), skin, S_R, Vector3(REST_DEG, 0, 0))
	add_part(arm_l, _arm_mesh("td_arm_l", S_L, HAND_L), skin, S_L, Vector3(REST_DEG, 0, 0))
	add_part(arm_r, _pipe_mesh(), thorn, S_R, Vector3(REST_DEG, 0, 0))
	add_part(arm_r, _bands_mesh(), dark, S_R, Vector3(REST_DEG, 0, 0))
	add_part(arm_r, sphere(0.1, 8, 4), cloth, S_R + Vector3(0.02, 0.0, 0.0), Vector3.ZERO, Vector3(0.9, 0.7, 0.9))
	# the seed dart sits in the pipe mouth (keep_separate: hidden after the shot)
	var tip := _rest_point(PIPE_END + Vector3(0, 0, 0.02))
	_dart = add_part(arm_r, sphere(0.07, 8, 4), glow, tip, Vector3.ZERO, Vector3.ONE, true, "SeedDart")
	_dart.set_meta(&"own_glow", true)
	# ---- Fx
	_puff = make_dust(Color(0.95, 0.92, 0.80), 6, 0.7, 0.05, 0.22, 0.8, 40.0)
	_puff.name = "MuzzlePuff"
	_puff.position = tip - model_origin(arm_r)
	arm_r.add_child(_puff)
	_trail = make_dust(Color(0.95, 0.92, 0.80), 10, 1.0, 0.18, 0.20, 0.5, 80.0)
	_trail.name = "SeedTrail"
	_trail.position = Vector3(0, 0.25, 0)
	$Fx.add_child(_trail)
	add_hit_burst(Vector3(0, 0.8, 0.05), Color(0.92, 0.88, 0.74), 7)
	add_death_bloom(Vector3(0, 0.65, 0.05), 0.25, 8, 10, Color(0.92, 0.88, 0.74))
	ensure_shadow_blob(0.34)


## A point of the aim pose moved into the rest pose (rotated REST_DEG about the shoulder axis).
static func _rest_point(p: Vector3) -> Vector3:
	var o := Vector3(p.x, S_R.y, S_R.z)
	return o + Basis(Vector3.RIGHT, REST_DEG * DEG) * (p - o)


# ================================================================ meshes (cached; aim space relative to the shoulder)

static func _arm_mesh(key: String, sh: Vector3, hand: Vector3) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	var elbow := sh.lerp(hand, 0.5) + Vector3(0, -0.07, 0)
	st.append_from(tapered_path_mesh(key + "_p", PackedVector3Array([Vector3.ZERO, elbow - sh, hand - sh]),
		PackedFloat32Array([0.045, 0.038, 0.034])), 0, Transform3D.IDENTITY)
	st.append_from(sphere(0.045, 7, 4), 0, Transform3D(Basis.IDENTITY, hand - sh))
	return _cached(key, _indexed(st))


## The reed pipe: a long tapering tube, a flared muzzle, a bulb mouthpiece.
static func _pipe_mesh() -> Mesh:
	const KEY := "td_pipe"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var a := MOUTH - S_R
	var b := PIPE_END - S_R
	st.append_from(tapered_path_mesh("td_pipe_tube", PackedVector3Array([a, a.lerp(b, 0.5), b]),
		PackedFloat32Array([0.028, 0.024, 0.022]), 6, false), 0, Transform3D.IDENTITY)
	st.append_from(cyl(0.045, 0.025, 0.07, 7, false), 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), b + Vector3(0, 0, 0.0)))
	st.append_from(sphere(0.035, 7, 4), 0, Transform3D(Basis.IDENTITY, a))
	return _cached(KEY, _indexed(st))


## Dark bark bands along the pipe (value detail).
static func _bands_mesh() -> Mesh:
	const KEY := "td_pipe_bands"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for u: float in [0.14, 0.42, 0.72]:
		var p := MOUTH.lerp(PIPE_END, u) - S_R
		st.append_from(cyl(0.034, 0.034, 0.035, 6), 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), p))
	return _cached(KEY, _indexed(st))


## The thistle-down cloak: fluff balls over the shoulders and the back, down to the knees.
static func _down_mesh() -> Mesh:
	var xs: Array[Transform3D] = []
	for d: Vector4 in [Vector4(-0.16, 0.87, -0.02, 0.10), Vector4(0.16, 0.87, -0.02, 0.10), Vector4(0.0, 0.88, -0.09, 0.12),
			Vector4(0.0, 0.76, -0.14, 0.15), Vector4(-0.12, 0.66, -0.13, 0.12), Vector4(0.12, 0.66, -0.13, 0.12),
			Vector4(0.0, 0.55, -0.14, 0.12), Vector4(-0.11, 0.45, -0.11, 0.09), Vector4(0.11, 0.45, -0.11, 0.09),
			Vector4(-0.19, 0.76, -0.06, 0.08), Vector4(0.19, 0.76, -0.06, 0.08)]:
		xs.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * d.w), Vector3(d.x, d.y, d.z)))
	return cluster_mesh("td_down", sphere(1.0, 6, 3), xs)


## Seed filaments sticking out of the cloak (thin cones, the fluffy edge at 25 m).
static func _filament_mesh() -> Mesh:
	var xs: Array[Transform3D] = []
	var dirs := [Vector3(-0.7, 0.5, -0.5), Vector3(0.7, 0.5, -0.5), Vector3(0.0, 0.6, -0.8), Vector3(-0.9, -0.1, -0.4),
		Vector3(0.9, -0.1, -0.4), Vector3(0.0, 0.1, -1.0)]
	var bases := [Vector3(-0.2, 0.93, -0.06), Vector3(0.2, 0.93, -0.06), Vector3(0.0, 0.92, -0.18),
		Vector3(-0.22, 0.70, -0.12), Vector3(0.22, 0.70, -0.12), Vector3(0.0, 0.70, -0.27)]
	for i: int in dirs.size():
		var d: Vector3 = (dirs[i] as Vector3).normalized()
		xs.append(Transform3D(Basis(Quaternion(Vector3.UP, d)), (bases[i] as Vector3) + d * 0.07))
	return cluster_mesh("td_filaments", cyl(0.0, 0.022, 0.15, 5), xs)


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"blow_dart":
		return super._pose_attack(prev, t)
	var r := attack_windup
	var up := _k3(t, 0.0, r * 0.8, 0.36, ATTACK_LEN, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-REST_DEG * DEG * up, 0, 0))
	rot(P_ARM_L, Vector3(-REST_DEG * DEG * up, 0, 0))
	var puff := _k3(t, r, r + 0.04, r + 0.08, 0.36, 1.0, 0.4)
	rot(P_CHEST, Vector3((6.0 * puff - 4.0 * up) * DEG, 0, 0))
	rot(P_HEAD, Vector3(8.0 * puff * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, -0.04 * up, 0.04 * puff))
	rot(P_LEG_L, Vector3(-14.0 * DEG * up, 0, 0))
	rot(P_LEG_R, Vector3(10.0 * DEG * up, 0, 0))
	if prev < r and t >= r:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Skitter: a quick hop forward, legs tucked, a trail of seed fluff.
func _pose_cast(_spell: StringName, t: float) -> float:
	var u: float = clampf(t / 0.4, 0.0, 1.0)
	var h: float = sin(PI * u)
	pos(P_ROOT, Vector3(0, 0.38 * h, 0.35 * _k3(t, 0.0, 0.2, 0.3, CAST_LEN, 1.0, 1.0)))
	rot(P_ROOT, Vector3(-10.0 * DEG * h, 0, 0))
	rot(P_LEG_L, Vector3(-50.0 * DEG * h, 0, 0))
	rot(P_LEG_R, Vector3(-30.0 * DEG * h, 0, 0))
	rot(P_ARM_L, Vector3(-30.0 * DEG * h, 0, -25.0 * DEG * h))
	rot(P_ARM_R, Vector3(-20.0 * DEG * h, 0, 20.0 * DEG * h))
	if not _fired and t >= 0.05:
		_fired = true
		if _trail and _tier < 2:
			_trail.restart()
	return CAST_LEN


func _set_dart(gone: bool) -> void:
	if gone == _dart_gone or _dart == null:
		return
	_dart_gone = gone
	_dart.visible = not gone


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_flare = 1.0
		_set_dart(true)
		if _puff and _tier < 2:
			_puff.restart()
	elif ev == &"cast_start":
		_fired = false
	elif ev == &"attack_end" or ev == &"death_glow_off":
		_set_dart(false)


func _war_process(dt: float) -> void:
	if _dart_gone and not _dead and _action != &"attack":
		_set_dart(false)
	_flare = maxf(0.0, _flare - dt / 0.3)
	if _dart:
		var b: float = glow_level() * (1.3 + 1.5 * _flare)
		if absf(b - _dart_written) > 0.04:
			_dart_written = b
			_dart.set_instance_shader_parameter(&"glow_boost", b)
	# light quick skip: a small forward lean on the walk
	if _walk_w > 0.0 and not _dead and _tier == 0:
		rot(P_ROOT, Vector3(6.0 * DEG * _walk_w, 0, 0))


func _war_revive() -> void:
	_flare = 0.0
	_dart_written = -1.0
	_set_dart(false)


## Fidget: lifts the pipe halfway, blows a seed-fluff puff up into the air and watches it drift.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.3, 0.9, 1.4, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-25.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(-25.0 * DEG * k, 0, 0))
	rot(P_HEAD, Vector3(-18.0 * DEG * _k3(t, 0.4, 0.7, 1.1, 1.4, 1.0, 1.0), 0, 0))
	if t < 0.1:
		_fpuff = false
	elif t >= 0.35 and not _fpuff:
		_fpuff = true
		if _puff and _tier == 0:
			_puff.restart()
	return 1.4
