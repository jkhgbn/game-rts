extends GroveKinModel
## Sapling, Nature summon (kingdom-nature.md 7.2, task 8.V3; Call the Thicket; polish A2.1). Height 1.2, radius 0.4.
## A walking young tree: a furrowed bark trunk with glowing green sap veins (nature_bark_sap: the kingdom glow of a
## magic summon; moss creeps up the root feet), a team vine sash, a round leafy CANOPY head (blossom top lobes, team
## body, dark underside, a fringe of team-dark leaves, dark eye bar) that sways on its own spring, two branch arms (the
## right one ends in a knobbly burl club), splayed root feet. The top lobes flower: two blossom-pink (nature_blossom)
## and one cream (nature_sec_sapling, also the 3 top leaves): the light, warm top that lifts it off the meadow green
## (Art Lab R3; the dark walnut trunk is the other half of that value split). The canopy body carries the team
## colour (an autumn canopy in a mirror match). Read at 40 m: "a round head on a stick".
## Attack: melee_swing (burl club). Sprout: grows 0.2 -> 1.0 in 0.5 s with a stretch, a squash and the canopy
## bursting open, a ring of green motes; automatic when it enters the tree (play_sprout() re-plays it).
## Idle fidget: shakes its canopy (leaves fly). Hit: leaves fly off. Death = wither: leaves turn brown, the sap
## goes dark, the canopy and arms droop, it sinks, brown leaves fall.

const SPROUT_LEN := 0.5
const CANOPY_BASE := Vector3(0, 0.96, 0)   # model-space pivot of the canopy (the neck)

var _sprout_t: float = 99.0
var _sprout_fx: GPUParticles3D
var _canopy: Node3D
var _cx: Vector2 = Vector2.ZERO   # canopy pitch spring
var _cz: Vector2 = Vector2.ZERO   # canopy roll spring
var _canopy_written: Vector2 = Vector2(99.0, 99.0)
var _fidget_puffed: bool = false
var _withered: bool = false
var _wither_nodes: Array[MeshInstance3D] = []
var _wither_surfs: PackedInt32Array = PackedInt32Array()
var _wither_mats: Array[Material] = []
var _wither_prev: Array[Material] = []


func _build_parts() -> void:
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var bark := nature(&"nature_bark_sap")
	var leaf := nature(&"nature_sec_sapling")
	var light := nature(&"nature_leaf")
	var cloth := nature(&"nature_cloth")
	var bloom := nature(&"nature_blossom")   # blossom top lobes (Art Lab R3: lifts the crown off the meadow)
	# Chest: furrowed trunk with a root flare, diagonal team vine sash with a leaf knot.
	add_part(chest, cyl(0.11, 0.17, 0.64, 8), bark, Vector3(0, 0.63, 0))
	add_part(chest, cyl(0.16, 0.22, 0.12, 8), bark, Vector3(0, 0.36, 0))
	add_part(chest, torus(0.13, 0.20), cloth, Vector3(0, 0.62, 0), Vector3(0, 0, 18))
	var knot: Array[Transform3D] = [
		leaf_xform(Vector3.ZERO, Vector3(0.4, 0, 1), Vector3(0.15, 0.04, 0.22), -55.0),
		leaf_xform(Vector3(0.02, 0.0, 0.0), Vector3(1, 0, 0.3), Vector3(0.13, 0.04, 0.19), -40.0),
	]
	add_part(chest, cluster_mesh("a21_sap_knot", leaf_mesh(), knot), cloth, Vector3(0.12, 0.66, 0.13))
	# Canopy: one baked, swaying node (keep_separate): dark underside, team-green body lobes, blossom top lobes,
	# a fringe of team leaves, 3 upright top leaves and the dark eye bar on the front lobe.
	_canopy = Node3D.new()
	_canopy.name = "Canopy"
	_canopy.position = CANOPY_BASE - model_origin(head)
	_canopy.set_meta(&"keep_separate", true)
	head.add_child(_canopy)
	var b := CANOPY_BASE
	var sp := sphere(0.5)
	var lm := leaf_mesh()
	var parts: Array = [
		[sp, _lobe(Vector3(0, 1.00, -0.01) - b, Vector3(0.58, 0.36, 0.58)), nature(&"nature_leaf_dark")],
		[sp, _lobe(Vector3(0, 1.11, 0) - b, Vector3(0.60, 0.52, 0.58)), cloth],
		[sp, _lobe(Vector3(0.19, 1.07, 0.06) - b, Vector3(0.36, 0.34, 0.36)), cloth],
		[sp, _lobe(Vector3(-0.20, 1.09, 0.04) - b, Vector3(0.38, 0.36, 0.38)), cloth],
		[sp, _lobe(Vector3(0.03, 1.09, -0.20) - b, Vector3(0.38, 0.36, 0.38)), cloth],
		[sp, _lobe(Vector3(0.0, 1.05, 0.16) - b, Vector3(0.34, 0.30, 0.34)), cloth],
		[sp, _lobe(Vector3(0.07, 1.26, 0.03) - b, Vector3(0.36, 0.32, 0.36)), bloom],
		[sp, _lobe(Vector3(-0.11, 1.23, -0.08) - b, Vector3(0.32, 0.28, 0.32)), bloom],
		[sp, _lobe(Vector3(0.17, 1.17, 0.12) - b, Vector3(0.24, 0.22, 0.24)), leaf],
	]
	for i: int in 8:
		var a := TAU * float(i) / 8.0 + 0.2
		var out := Vector3(sin(a), 0, cos(a))
		parts.append([lm, leaf_xform(Vector3(0, 1.00, 0) - b + out * 0.25, out, Vector3(0.19, 0.05, 0.24), -20.0), nature(&"nature_cloth_dark")])
	for i: int in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		var out := Vector3(sin(a), 0, cos(a))
		parts.append([lm, leaf_xform(Vector3(0.02, 1.37, -0.01) - b + out * 0.04, out, Vector3(0.13, 0.05, 0.22), 58.0),
			leaf])
	add_part(_canopy, bake("a21_sap_canopy", parts), null, CANOPY_BASE, Vector3.ZERO, Vector3.ONE, true, "CanopyMesh")
	# Face (FaceKit, on the front lobe; sways with the canopy): a pale heartwood mask with round sap-green eyes and a
	# small mouth, the leaves are its hair.
	var fc := Vector3(0, 1.05, 0.16)
	var fm := sphere(0.5)
	var fs := Vector3(0.34, 0.30, 0.34)
	var cv := FaceKit.canvas(fc, 0.16, fm, fs, fc, Basis.IDENTITY, 0.006)
	_face = FaceKit.attach(self, _canopy, "sapling", NatureFaces.style({
		"center": fc, "radius": 0.16, "head_mesh": fm, "head_scale": fs, "head_at": fc, "preset": &"gentle",
		"skin": NatureFaces.HEARTWOOD, "hair": NatureFaces.BARK, "eyes": NatureFaces.EYE_LEAF, "detail": &"low",
		"x": NatureFaces.lean_x(), "palette": NatureFaces.pal(NatureFaces.BARK),
		"eye": {"c": Vector2(0.052, 0.012), "hw": 0.030, "top": 0.026, "bot": 0.016, "ir": 0.017},
		"brow": {"inner": Vector2(0.024, 0.050), "mid": Vector2(0.052, 0.060), "outer": Vector2(0.080, 0.050)},
		"mouth": {"c": Vector2(0.0, -0.050), "hw": 0.026},
		"base": func(acc: Dictionary, _id: StringName) -> void:
			FaceKit.fill(acc, cv, FaceKit.ellipse(Vector2(0, -0.006), Vector2(0.105, 0.088), 0.0, 18),
				FaceKit.radial(Vector2(0, -0.006), Vector2(0.105, 0.088), NatureFaces.HEARTWOOD, NatureFaces.HEARTWOOD.darkened(0.25), 0.7),
				0.0012, 0.008),
	}, Vector3.ZERO, 0.006))
	# Arms: branches; the left one forks into a twig, both carry leaf tufts; the right one ends in a burl club.
	add_limb(arm_l, Vector3(-0.13, 0.72, 0), Vector3(-0.40, 0.50, 0.08), 0.055, bark)
	add_limb(arm_l, Vector3(-0.33, 0.56, 0.06), Vector3(-0.45, 0.64, 0.12), 0.035, bark)
	add_part(arm_l, _tuft(), leaf, Vector3(-0.42, 0.47, 0.09))
	add_part(arm_l, _tuft(), light, Vector3(-0.46, 0.66, 0.13), Vector3(0, 60, 0), Vector3(0.8, 0.8, 0.8))
	add_limb(arm_r, Vector3(0.13, 0.72, 0), Vector3(0.43, 0.47, 0.12), 0.065, bark)
	add_part(arm_r, sphere(0.13), bark, Vector3(0.45, 0.41, 0.13), Vector3(0, 0, 12), Vector3(1.0, 1.25, 1.0))
	add_part(arm_r, _tuft(), light, Vector3(0.47, 0.52, 0.13), Vector3(0, 30, 0))
	# Legs: stubby trunk foot + 3 splayed roots each (mossy at the ground).
	add_part(leg_l, _roots(-1.0), bark, Vector3(-0.12, 0.0, 0))
	add_part(leg_r, _roots(1.0), bark, Vector3(0.12, 0.0, 0))
	# FX: sprout ring, leaves on hits, withering leaves.
	_sprout_fx = make_motes(NATURE_GLOW, 12, 0.7, 0.45, 1.4, 0.10, true, true)
	_sprout_fx.name = "SproutMotes"
	_sprout_fx.position = Vector3(0, 0.1, 0)
	$Fx.add_child(_sprout_fx)
	add_hit_leaves(Vector3(0, 1.05, 0.05), Color(0.45, 0.72, 0.26), 6, 0.14)
	var fall := make_petals(Color(0.55, 0.40, 0.18), 10, 1.1, 0.35, 1.2, 0.15, true)
	fall.name = "WitherLeaves"
	fall.set_meta(&"death_fx", true)
	fall.position = Vector3(0, 1.0, 0)
	$Fx.add_child(fall)
	ensure_shadow_blob(0.40, KIN_BLOB)


static func _lobe(at: Vector3, scl: Vector3) -> Transform3D:
	return Transform3D(Basis().scaled(scl), at)


## A tuft of 3 leaves fanning up and out (one cached mesh).
static func _tuft() -> Mesh:
	var xs: Array[Transform3D] = []
	for i: int in 3:
		var a := TAU * float(i) / 3.0
		xs.append(leaf_xform(Vector3.ZERO, Vector3(sin(a), 0, cos(a)), Vector3(0.12, 0.04, 0.19), 35.0))
	return cluster_mesh("a21_sap_tuft", leaf_mesh(), xs)


## Stubby foot (reversed cone up to the hip) + 3 roots splayed outward on the ground; side = +1 right, -1 left.
static func _roots(side: float) -> Mesh:
	var key := "a21_sapling_roots_f1_%s" % side
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var xs: Array[Transform3D] = [Transform3D(Basis().scaled(Vector3(1.1, 0.36, 1.1)), Vector3(0, 0.18, 0))]
	var yaws: Array[float] = [20.0 * side, 100.0 * side, 160.0 * side]
	for y: float in yaws:
		var out := Vector3(sin(y * DEG), 0, cos(y * DEG))
		# Base cone axis (+Y, thick at the bottom) laid outward and down: the thin tip digs into the ground.
		var bs := Basis(Quaternion(Vector3.UP, (out - Vector3(0, 0.35, 0)).normalized()))
		xs.append(Transform3D(bs.scaled_local(Vector3(1.05, 0.32, 1.05)), Vector3(0, 0.08, 0) + bs * Vector3(0, 0.16, 0)))
	return cluster_mesh(key, cyl(0.035, 0.085, 1.0, 6, false), xs)   # open ends: in the ground / the hip (face budget)


func _kin_ready() -> void:
	# Surfaces that brown when it withers (swapped once; revive restores what was there, team colour included).
	var leafy: Array[Material] = [nature(&"nature_sec_sapling"), nature(&"nature_leaf_dark"), nature(&"nature_leaf"),
		nature(&"nature_bark_sap"), nature(&"nature_cloth"), nature(&"nature_cloth_dark"), nature(&"nature_blossom")]
	var brown: Array[Material] = [nature(&"nature_wither"), nature(&"nature_bark_dark"), nature(&"nature_wither"),
		nature(&"nature_bark_dark"), nature(&"nature_wither"), nature(&"nature_bark_dark"), nature(&"nature_wither")]
	var nodes: Array[MeshInstance3D] = []
	for i: int in _merged_nodes:
		nodes.append(_merged_nodes[i])
	var canopy_mesh: MeshInstance3D = null
	if _canopy and _canopy.get_child_count() > 0:
		canopy_mesh = _canopy.get_child(0) as MeshInstance3D
		if canopy_mesh:
			nodes.append(canopy_mesh)
			_flash_hit_targets.append(canopy_mesh)   # the canopy (its head) takes the white hit flash too
	for mi: MeshInstance3D in nodes:
		if mi == null or mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			var k := leafy.find(m)
			if k < 0 or (k >= 4 and mi != canopy_mesh):   # the chest sash stays cloth; the canopy leaves wither
				continue
			_wither_nodes.append(mi)
			_wither_surfs.append(s)
			_wither_mats.append(brown[k])
			_wither_prev.append(null)
	play_sprout()


## Grow from 0.2 to full size in 0.5 s (called automatically when the Sapling enters the tree).
func play_sprout() -> void:
	if _dead:
		return
	_sprout_t = 0.0
	_set_sprout_scale(0.0)
	if _sprout_fx:
		_sprout_fx.restart()


func _process(delta: float) -> void:
	super._process(delta)
	if _sprout_t < SPROUT_LEN:
		_sprout_t += delta
		if _dead or _sprout_t >= SPROUT_LEN:
			_sprout_t = 99.0
			_set_sprout_scale(1.0)
		else:
			_set_sprout_scale(_sprout_t / SPROUT_LEN)
	if _dead and not _withered:
		_wither(true)


## Sprout pose at u (0-1): the trunk shoots up stretched, squashes as it lands at full size, the canopy bursts open
## a little later with an overshoot. u = 1 is the rest pose.
func _set_sprout_scale(u: float) -> void:
	var root := _piv[P_ROOT]
	if root == null:
		return
	if u >= 1.0:
		root.scale = Vector3.ONE
		if _canopy:
			_canopy.scale = Vector3.ONE
		return
	var f: float = 1.06 * smoothstep(0.0, 0.8, u) if u < 0.8 else lerpf(1.06, 1.0, (u - 0.8) / 0.2)
	var s: float = 0.2 + 0.8 * f
	var st: float = 0.20 * sin(PI * clampf(u / 0.7, 0.0, 1.0)) - 0.08 * sin(PI * clampf((u - 0.7) / 0.3, 0.0, 1.0))
	root.scale = Vector3(s * (1.0 - st * 0.45), s * (1.0 + st), s * (1.0 - st * 0.45))
	if _canopy:
		var c: float = clampf((u - 0.2) / 0.8, 0.0, 1.0)
		var back: float = 1.0 + 2.2 * pow(c - 1.0, 3.0) + 1.2 * pow(c - 1.0, 2.0)   # ease-out-back
		var cs: float = 0.3 + 0.7 * back
		_canopy.scale = Vector3(cs, cs, cs)


func _kin_process(dt: float) -> void:
	var roll: float = 0.0
	if not is_idle_fast():
		if _walk_w > 0.0 and not _dead:
			# Heavy trunk stomp: roll onto the planted root, lean in, the canopy lags behind (spring below).
			var s: float = sin(TAU * _walk_p)
			roll = 5.0 * DEG * s * _walk_w
			rot(P_ROOT, Vector3(3.0 * DEG * _walk_w, 0, roll))
			rot(P_CHEST, Vector3(0, 0, -2.0 * DEG * s * _walk_w))
		if _dead:
			# Withering: the branches sag.
			var k: float = clampf(_death_t / 0.5, 0.0, 1.0)
			rot(P_ARM_L, Vector3(30.0 * DEG * k, 0, -25.0 * DEG * k))
			rot(P_ARM_R, Vector3(30.0 * DEG * k, 0, 25.0 * DEG * k))
	# Canopy spring: lags behind every jolt (steps, the club swing, hits), droops forward when it withers.
	if _canopy == null or _tier >= 2:
		return
	var acc := root_accel()
	var tx: float = 0.45 if _dead else 0.0
	_cx = spring(_cx, tx, -acc.y * 0.25 + acc.z * 0.6, 9.0, 4.0, dt)
	_cz = spring(_cz, -roll * 1.4, acc.x * 0.5, 8.5, 3.5, dt)
	_cx.x = clampf(_cx.x, -0.6, 0.7)
	_cz.x = clampf(_cz.x, -0.5, 0.5)
	if absf(_cx.x - _canopy_written.x) > 0.003 or absf(_cz.x - _canopy_written.y) > 0.003:
		_canopy_written = Vector2(_cx.x, _cz.x)
		_canopy.rotation = Vector3(_cx.x, 0, _cz.x)


func _on_kin_hit() -> void:
	_cx.y -= 5.0
	_cz.y += 4.0 * (1.0 if int(_t * 10.0) % 2 == 0 else -1.0)


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":   # the club lands: the canopy whips forward
		_cx.y += 6.0


## Fidget: shakes its canopy like a wet dog (fast decaying wiggle), a few leaves fly off.
func _pose_fidget(t: float) -> float:
	if t < 0.05:
		_fidget_puffed = false
	if not _fidget_puffed and t >= 0.15:
		_fidget_puffed = true
		if _hit_leaves:
			_hit_leaves.restart()
	var env: float = _k3(t, 0.0, 0.12, 0.35, 1.1, 1.0, 1.0)
	var w: float = sin(t * TAU * 5.5) * env
	rot(P_HEAD, Vector3(0, 10.0 * DEG * w, 9.0 * DEG * w))
	rot(P_CHEST, Vector3(0, -4.0 * DEG * w, -3.0 * DEG * w))
	rot(P_ARM_L, Vector3(0, 0, -18.0 * DEG * env))
	rot(P_ARM_R, Vector3(0, 0, 18.0 * DEG * env))
	_cz.y += 1.5 * w
	return 1.1


func _wither(on: bool) -> void:
	_withered = on
	for j: int in _wither_nodes.size():
		var mi := _wither_nodes[j]
		if on:
			_wither_prev[j] = mi.get_surface_override_material(_wither_surfs[j])
			mi.set_surface_override_material(_wither_surfs[j], _wither_mats[j])
		else:
			mi.set_surface_override_material(_wither_surfs[j], _wither_prev[j])
			_wither_prev[j] = null


func _kin_revive() -> void:
	_sprout_t = 99.0
	_set_sprout_scale(1.0)
	_cx = Vector2.ZERO
	_cz = Vector2.ZERO
	_canopy_written = Vector2(99.0, 99.0)
	if _canopy:
		_canopy.rotation = Vector3.ZERO
	if _withered:
		_wither(false)
