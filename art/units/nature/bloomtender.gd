extends GroveKinModel
## Bloomtender (kingdom-nature.md 7.2, task 8.V4; polish A2.1): a robed caretaker under a HUGE hanging bell-flower
## hat (team-green bell with pale glancing edges, a 5-petal blossom-pink flared rim, dark sepals, a curled stem with a
## glowing bud), a folded dark bell robe with a scalloped petal hem, a lime leaf skirt, a pale gardener's apron, and a
## tall crook pole with a hanging seed-pod censer (bark ribs around a glowing core). Read at 40 m: widest hat of the
## army (a pink-rimmed green bell) + a light swinging at the top of a hook. Glow points: the censer core
## (nature_glow 1.5, flares x3.5) and the hat bud.
## Motion: the censer is a real pendulum (it lags when the Bloomtender starts, stops, turns, swings its pole) and the
## hat wobbles on a spring. Ranged: `censer_fling` (own timeline, 0.55 s): the pole cocks back during the windup and
## flings forward, release at `attack_windup` (0.12 s) with a pollen puff. Support: play_cast(&"support") = the pole
## tips toward the ally, the censer swings out, flares, puffs pollen (0.7 s); the heal beam starts at
## get_beam_origin(). The censer puffs a little pollen every ~3 s when idle nearby. Idle fidget: wafts the censer and
## sniffs the pollen. Hit: petals fly. Death: falls forward, the hat tumbles off, petals burst.

const HOOK := Vector3(0.47, 2.02, 0.42)    # model-space point the censer hangs from
const CORE := Vector3(0, -0.38, 0)          # censer core, relative to the hook
const HAT := Vector3(0, 1.50, 0.0)          # model-space origin of the hat (its rim level)
const FLING_LEN := 0.55
const PEND_L := 0.38                        # pendulum length (m)

var _censer: Node3D
var _core: GeometryInstance3D
var _hat: Node3D
var _puff: GPUParticles3D
var _idle_pollen: GPUParticles3D
var _flare: float = 0.0
var _core_written: float = -1.0
var _pollen_t: float = 0.0
# Censer pendulum (angle, velocity) about x (forward / back) and z (sideways), fed by the hook's world motion.
var _px: Vector2 = Vector2.ZERO
var _pz: Vector2 = Vector2.ZERO
var _hook_prev: Vector3 = Vector3.ZERO
var _hook_vel: Vector3 = Vector3.ZERO
var _hook_init: bool = false
# Hat spring.
var _hx: Vector2 = Vector2.ZERO
var _hz: Vector2 = Vector2.ZERO
var _hat_written: Vector3 = Vector3(99.0, 99.0, 99.0)
var _fidget_puffed: bool = false
var _hat_rest: Vector3 = Vector3.ZERO
var _hat_mesh: MeshInstance3D


## Low-poly limb (vertex budget): 6-segment cylinder from a to b, optional sphere at b.
func _rod(pivot: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, end_r: float = 0.0,
		end_mat: Material = null) -> void:
	var d := b - a
	add_part(pivot, cyl(r, r, d.length(), 6), mat, a + d * 0.5, Basis(Quaternion(Vector3.UP, d.normalized())).get_euler() / DEG)
	if end_r > 0.0:
		add_part(pivot, sphere(end_r, 8, 4), end_mat if end_mat else mat, b)


## Ring of n leaves (one cached mesh): bases on the ring, tips outward, tilted by tilt_deg (negative = drooping).
static func _ring_parts(parts: Array, centre: Vector3, n: int, ring_r: float, size: Vector3, tilt_deg: float,
		mat: Material, phase_deg: float = 0.0) -> void:
	for i: int in n:
		var a := TAU * float(i) / float(n) + phase_deg * DEG
		var out := Vector3(sin(a), 0, cos(a))
		parts.append([leaf_mesh(), leaf_xform(centre + out * ring_r, out, size, tilt_deg), mat])


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := nature(&"nature_cloth")
	var dark := nature(&"nature_cloth_dark")
	var skin := nature(&"nature_skin")
	var bark := nature(&"nature_bark")
	var bdark := nature(&"nature_bark_dark")
	var leaf := nature(&"nature_leaf")
	var ldark := nature(&"nature_leaf_dark")
	var bloom := nature(&"nature_petal_bloom")
	# Hips: a folded bark-brown gardener's robe (the dark base: it parts the unit from the grass), a scalloped hem of
	# overlapping team petals, a short team-dark leaf peplum at the waist.
	var robe := PackedVector2Array([Vector2(0.24, 1.02), Vector2(0.27, 0.88), Vector2(0.31, 0.70), Vector2(0.37, 0.50),
		Vector2(0.44, 0.30), Vector2(0.50, 0.14), Vector2(0.53, 0.02)])
	add_part(hips, lathe("a21_bt_robe", robe, 18, 9, 0.07, 1, 0.03), bark, Vector3.ZERO)
	add_leaf_crown(hips, Vector3(0, 0.25, 0), 9, 0.44, Vector3(0.30, 0.05, 0.26), -64.0, cloth, 20.0)
	add_leaf_crown(hips, Vector3(0, 0.88, 0), 7, 0.26, Vector3(0.22, 0.05, 0.28), -58.0, dark, 10.0)
	# Chest: team torso, lime leaf ruff around the neck, a blossom brooch.
	add_part(chest, cyl(0.20, 0.27, 0.40, 10), cloth, Vector3(0, 1.08, 0))
	add_leaf_crown(chest, Vector3(0, 1.26, 0), 6, 0.16, Vector3(0.20, 0.05, 0.26), 18.0, leaf, 12.0)
	add_part(chest, sphere(0.075, 8, 4), bloom, Vector3(0, 1.17, 0.26), Vector3.ZERO, Vector3(1.2, 1.2, 0.6))
	# Head: face + dark eye bar (under the hat rim), a team-dark hood behind it that frames the face.
	add_part(head, sphere(0.20), skin, Vector3(0, 1.40, 0.06))
	add_part(head, sphere(0.215), dark, Vector3(0, 1.43, -0.035))
	add_part(head, box(Vector3(0.22, 0.07, 0.06)), palette(&"unit_eye_dark"), Vector3(0, 1.42, 0.245))
	# Hat: one baked, wobbling node (keep_separate).
	_hat = Node3D.new()
	_hat.name = "Hat"
	_hat.position = HAT - model_origin(head)
	_hat_rest = _hat.position
	_hat.set_meta(&"keep_separate", true)
	head.add_child(_hat)
	var bell := PackedVector2Array([Vector2(0.05, 0.47), Vector2(0.12, 0.455), Vector2(0.19, 0.41), Vector2(0.245, 0.335),
		Vector2(0.275, 0.245), Vector2(0.295, 0.16), Vector2(0.31, 0.10)])
	var hat_parts: Array = [
		# 6-lobed bell: its ridges run down into the 6 petals (turned 30 deg like them)
		[lathe("a21_bt_bell6", bell, 24, 6, 0.09, 1), Transform3D(Basis(Vector3.UP, PI / 6.0), Vector3.ZERO),
			nature(&"nature_bell_cloth")],
		[cyl(0.30, 0.30, 0.012, 12), Transform3D(Basis(), Vector3(0, 0.12, 0)), dark],
		[cyl(0.03, 0.045, 0.24, 6), Transform3D(Basis(Vector3.RIGHT, -18.0 * DEG), Vector3(0, 0.57, -0.035)), ldark],
		[leaf_mesh(), leaf_xform(Vector3(0.0, 0.62, -0.06), Vector3(0.7, 0, -0.7), Vector3(0.13, 0.04, 0.24), 28.0), leaf],
		[sphere(0.07, 8, 4), Transform3D(Basis(), Vector3(0, 0.69, -0.075)), nature(&"nature_glow")],
	]
	_ring_parts(hat_parts, Vector3(0, 0.445, 0), 5, 0.07, Vector3(0.13, 0.05, 0.24), -12.0, ldark, 36.0)
	# The rim: 6 big overlapping blossom petals flaring out from the bell mouth like a brim (the pink frill seen from
	# the RTS camera).
	# (phase 30: the face looks out between two petals)
	_ring_parts(hat_parts, Vector3(0, 0.11, 0), 6, 0.25, Vector3(0.36, 0.06, 0.31), -9.0, bloom, 30.0)
	_hat_mesh = add_part(_hat, bake("a21_bt_hat", hat_parts), null, HAT, Vector3.ZERO, Vector3.ONE, true, "HatMesh")
	# Veterancy 4: a gold band around the bell (hidden until set_veterancy(4)).
	var trim := add_part(_hat, torus(0.26, 0.31, 12), palette(&"unit_gold_trim"), HAT + Vector3(0, 0.25, 0),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	trim.set_meta(&"vet_trim", true)
	trim.visible = false
	# Arms: team bell sleeves; the right hand holds the pole.
	add_part(arm_l, cyl(0.07, 0.14, 0.44, 8), cloth, Vector3(-0.32, 1.00, 0.02))
	add_part(arm_l, sphere(0.09, 8, 4), skin, Vector3(-0.33, 0.76, 0.05))
	_rod(arm_r, Vector3(0.31, 1.20, 0), Vector3(0.46, 0.98, 0.15), 0.09, cloth, 0.09, skin)
	# Pole: shaft, crook curling forward over the hat, two leaves at the top.
	add_part(arm_r, cyl(0.042, 0.042, 2.0, 6), bark, Vector3(0.47, 1.02, 0.15))
	add_part(arm_r, torus(0.11, 0.165, 10), bark, Vector3(0.47, 2.02, 0.285), Vector3(0, 0, 90))
	add_leaf(arm_r, Vector3(0.47, 2.10, 0.08), Vector3(0.13, 0.04, 0.28), leaf, Vector3(-55, 0, 0))
	add_leaf(arm_r, Vector3(0.51, 1.92, 0.08), Vector3(0.13, 0.04, 0.24), ldark, Vector3(-120, 30, 0))
	# Censer: a seed pod hanging from the hook on its own pendulum (keep_separate, one baked mesh): chain, a dark
	# leaf cap with sepals, 3 bark ribs around the glowing core, a pointed tip.
	_censer = Node3D.new()
	_censer.name = "Censer"
	_censer.set_meta(&"keep_separate", true)
	_censer.position = HOOK - model_origin(arm_r)
	arm_r.add_child(_censer)
	var c := CORE
	var pod: Array = [
		[cyl(0.018, 0.018, 0.20, 4), Transform3D(Basis(), Vector3(0, -0.10, 0)), bdark],
		[cyl(0.035, 0.12, 0.08, 8), Transform3D(Basis(), Vector3(0, -0.235, 0)), ldark],
		[cyl(0.0, 0.10, 0.13, 8), Transform3D(Basis(Vector3.RIGHT, PI), c + Vector3(0, -0.15, 0)), bdark],
	]
	_ring_parts(pod, Vector3(0, -0.26, 0), 5, 0.08, Vector3(0.09, 0.03, 0.13), -50.0, ldark, 0.0)
	for k: int in 3:
		var bs := Basis(Vector3.UP, PI * float(k) / 3.0) * Basis(Vector3.RIGHT, PI * 0.5)
		pod.append([torus(0.13, 0.16, 7), Transform3D(bs, c), bark])
	pod.append([sphere(0.13, 8, 5), Transform3D(Basis().scaled(Vector3(1.0, 1.15, 1.0)), c), nature(&"nature_glow")])
	_core = add_part(_censer, bake("a21_bt_censer", pod), null, HOOK, Vector3.ZERO, Vector3.ONE, true, "Pod")
	_core.set_meta(&"own_glow", true)
	# Pollen from the censer: a puff on each heal / shot, a small drift every ~3 s nearby (pre-built one-shots).
	_puff = make_motes(NATURE_GLOW, 10, 0.9, 0.14, 0.7, 0.10, false, true)
	_puff.name = "Pollen"
	_puff.position = CORE
	_censer.add_child(_puff)
	_idle_pollen = make_motes(Color(0.92, 0.95, 0.50), 4, 1.5, 0.08, 0.35, 0.08, false, true)
	_idle_pollen.name = "PollenDrift"
	_idle_pollen.position = CORE
	_censer.add_child(_idle_pollen)
	# Petals knocked off on hits; a burst of blossom petals on death.
	add_hit_leaves(Vector3(0, 1.55, 0.1), Color(0.95, 0.62, 0.76), 5, 0.12)
	var petals := make_petals(Color(0.95, 0.60, 0.75), 12, 1.2, 0.40, 1.0, 0.14, true)
	petals.name = "DeathPetals"
	petals.set_meta(&"death_fx", true)
	petals.position = Vector3(0, 1.5, 0)
	$Fx.add_child(petals)
	ensure_shadow_blob(0.45, KIN_BLOB)


func _kin_ready() -> void:
	# The hat is the biggest mass seen from the RTS camera: it takes the white hit flash with the chest / head / arm.
	if _hat_mesh:
		_flash_hit_targets.append(_hat_mesh)


## Where the heal beam and the bolt start (world space): the censer core.
func get_beam_origin() -> Vector3:
	if _censer and _censer.is_inside_tree():
		return _censer.global_transform * CORE
	return global_position + Vector3(0, 1.7, 0)


## Censer fling (own style); anything else goes to the kit. The pole rests UP from the fist: a negative arm angle
## cocks the censer back, a positive one brings it over to the front.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"censer_fling":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	var b := w + 0.10
	rot(P_ARM_R, Vector3(_k3(t, 0.0, w, b, FLING_LEN, -18.0, 26.0) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_k3(t, 0.0, w, b, FLING_LEN, 12.0, -34.0) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_k3(t, 0.0, w, b, FLING_LEN, -5.0, 8.0) * DEG, _k3(t, 0.0, w, b, FLING_LEN, 12.0, -10.0) * DEG, 0))
	rot(P_HIPS, Vector3(0, _k3(t, 0.0, w, b, FLING_LEN, 6.0, -6.0) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _k3(t, 0.0, w, b, FLING_LEN, -0.04, 0.06)))
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < FLING_LEN


## Support heal: `support` = the pole cocks back then tips toward the ally, the free hand opens toward it, the
## Bloomtender rises on tiptoe and the censer swings out and flares (the 0.25 s beam fits in 0.0-0.35 s).
func _pose_cast(spell: StringName, t: float) -> float:
	if spell != &"support":
		return super._pose_cast(spell, t)
	var k := _k3(t, 0.0, 0.14, 0.40, 0.7, 1.0, 1.0)
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.12, 0.30, 0.7, -16.0, 30.0) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(-65.0 * DEG * k, 0, -15.0 * DEG * k))
	rot(P_CHEST, Vector3(8.0 * DEG * k, -8.0 * DEG * k, 0))
	rot(P_HEAD, Vector3(-6.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, 0.04 * k, 0))
	_flare = maxf(_flare, k)
	return 0.7


func _on_action_event(ev: StringName) -> void:
	if ev == &"release" or (ev == &"cast_start" and _cast_id == &"support"):
		_flare = 1.0
		_px.y -= 7.0   # the censer is flung forward
		if _puff and _tier < 2:
			_puff.restart()


func _on_kin_hit() -> void:
	_hx.y -= 6.0
	_hz.y += 5.0 * (1.0 if int(_t * 10.0) % 2 == 0 else -1.0)
	_px.y += 4.0


func _kin_process(dt: float) -> void:
	if _action == &"attack" and _action_t < attack_windup:
		_flare = maxf(_flare, 0.5 * _action_t / maxf(attack_windup, 0.01))
	var fast := is_idle_fast()
	if not fast and _walk_w > 0.0 and not _dead:
		# The bell robe sways with the walk (no legs: the hips carry the rhythm), the torso counters it.
		var s := sin(TAU * _walk_p)
		rot(P_HIPS, Vector3(0, 5.0 * DEG * s * _walk_w, 3.5 * DEG * s * _walk_w))
		rot(P_CHEST, Vector3(0, -3.0 * DEG * s * _walk_w, 0))
	if _tier < 2:
		_censer_process(dt, fast)
		_hat_process(dt)
		if not _dead:
			_pollen_t += dt
			if _pollen_t >= 3.0:
				_pollen_t = fmod(_phase_off, 0.8)
				if _tier == 0 and _idle_pollen:
					_idle_pollen.restart()
	if _core:
		var b: float = glow_level() * (1.0 + 2.5 * _flare)
		if b != _core_written:
			_core_written = b
			_core.set_instance_shader_parameter(&"glow_boost", b)
	_flare = maxf(0.0, _flare - dt / 0.4)


## Pendulum: the censer hangs straight down whatever the arm, chest and body do, and lags behind the hook's
## world-space acceleration (starts, stops, turns, pole swings), then swings back and settles.
func _censer_process(dt: float, fast: bool) -> void:
	if _censer == null or dt <= 0.0 or not _censer.is_inside_tree():
		return
	var hook: Vector3 = _censer.global_position
	var acc := Vector3.ZERO
	if _hook_init:
		var v: Vector3 = (hook - _hook_prev) / dt
		acc = global_basis.orthonormalized().inverse() * ((v - _hook_vel) / dt)
		acc = acc.clamp(Vector3(-30, -30, -30), Vector3(30, 30, 30))
		_hook_vel = v
	else:
		_hook_init = true
		_hook_vel = Vector3.ZERO
	_hook_prev = hook
	var g: float = maxf(9.8 + acc.y, 2.0) / PEND_L
	var idle_drive: float = 0.25 * sin(_t * 1.3 + _phase_off) * (1.0 - _walk_w)
	_px = spring(_px, 0.0, acc.z / PEND_L - (g - 26.0) * _px.x + idle_drive, 5.1, 1.7, dt)
	_pz = spring(_pz, 0.0, -acc.x / PEND_L - (g - 26.0) * _pz.x + idle_drive * 0.6, 5.1, 1.7, dt)
	_px.x = clampf(_px.x, -1.1, 1.1)
	_pz.x = clampf(_pz.x, -0.9, 0.9)
	# Undo the pose rotation between the model and the censer so it keeps hanging down.
	var comp_x: float = 0.0
	var comp_z: float = 0.0
	if not fast:
		comp_x = -(_off_rot[P_ROOT].x + _off_rot[P_CHEST].x + _off_rot[P_ARM_R].x)
		comp_z = -(_off_rot[P_ROOT].z + _off_rot[P_CHEST].z + _off_rot[P_ARM_R].z)
	_censer.rotation = Vector3(_px.x + comp_x, 0.0, _pz.x + comp_z)


## Hat: wobbles on a stiff spring after every jolt; on death it tumbles off forward.
func _hat_process(dt: float) -> void:
	if _hat == null:
		return
	if _dead:
		var f: float = _ease_in(clampf((_death_t - 0.15) / 0.45, 0.0, 1.0))
		_hat.rotation = Vector3(0.9 * f, 0.0, 0.35 * f)
		_hat.position = _hat_rest + Vector3(0.05 * f, -0.12 * f, 0.22 * f)
		_hat_written = Vector3(99.0, 99.0, 99.0)
		return
	var acc := root_accel()
	_hx = spring(_hx, 0.0, -acc.y * 0.18 + acc.z * 0.45, 13.0, 5.0, dt)
	_hz = spring(_hz, 0.0, acc.x * 0.4, 12.0, 5.0, dt)
	_hx.x = clampf(_hx.x, -0.5, 0.5)
	_hz.x = clampf(_hz.x, -0.4, 0.4)
	if absf(_hx.x - _hat_written.x) > 0.003 or absf(_hz.x - _hat_written.z) > 0.003:
		_hat_written = Vector3(_hx.x, 0.0, _hz.x)
		_hat.rotation = _hat_written


## Fidget: lifts the pole a little, wafts the censer with the free hand and leans in to sniff the pollen.
func _pose_fidget(t: float) -> float:
	if t < 0.05:
		_fidget_puffed = false
	var k := _k3(t, 0.0, 0.35, 1.2, 1.7, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-14.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(-55.0 * DEG * k, 0, (-10.0 + 14.0 * sin(t * TAU * 1.6)) * DEG * k))
	rot(P_HEAD, Vector3(-8.0 * DEG * k, 20.0 * DEG * k, 0))
	rot(P_CHEST, Vector3(4.0 * DEG * k, 8.0 * DEG * k, 0))
	if not _fidget_puffed and t >= 0.4:
		_fidget_puffed = true
		_flare = maxf(_flare, 0.5)
		if _idle_pollen:
			_idle_pollen.restart()
	return 1.7


func _kin_revive() -> void:
	_flare = 0.0
	_core_written = -1.0
	_px = Vector2.ZERO
	_pz = Vector2.ZERO
	_hx = Vector2.ZERO
	_hz = Vector2.ZERO
	_hook_init = false
	_hat_written = Vector3(99.0, 99.0, 99.0)
	if _censer:
		_censer.rotation = Vector3.ZERO
	if _hat:
		_hat.rotation = Vector3.ZERO
		_hat.position = _hat_rest
