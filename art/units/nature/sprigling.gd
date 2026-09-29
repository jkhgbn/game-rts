extends GroveKinModel
## Sprigling, Nature worker (kingdom-nature.md 7.2, task 8.V3; polish A2.1). Height 1.2, radius 0.35: the smallest
## unit. A round sprout-creature: a pale seed-bulb head with two leaf "ears" and a BIG two-leaf sprout growing out of a
## dark seed-coat ring, with a glowing bud between the leaves (the kingdom glow point, nature_glow 1.5). Team leaf
## tunic with a hanging leaf hem, dark root legs with round root-bulb feet, a flint hoe over the right shoulder and a
## big tan seed sack on the back. Read at 40 m: small pale dot + bright sprout sticking up + tan sack behind.
## Motion: the sprout is a damped spring (it flops on every step, hop, hit and swing), a waddle walk, a little hop
## as idle fidget, a forward chop on attacks / mining. Carry: 3 crystals poke out of the sack. Mine: crystal sparks
## at the blade. Hit: leaves fly off. Death: falls, the sprout droops, leaves puff.

var _sprout: Node3D
var _sparks: GPUParticles3D
var _sx: Vector2 = Vector2.ZERO    # sprout pitch spring (angle, velocity)
var _sz: Vector2 = Vector2.ZERO    # sprout roll spring
var _sprout_written: Vector2 = Vector2(99.0, 99.0)


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := nature(&"nature_cloth")
	var cloth_dark := nature(&"nature_cloth_dark")
	var skin := nature(&"nature_skin")
	var bark := nature(&"nature_bark")
	var dark := nature(&"nature_bark_dark")
	var leaf := nature(&"nature_leaf")
	var sack := nature(&"nature_sec_sprigling")
	# Legs: stubby dark root legs with round root-bulb feet (long along +Z, the face side).
	for side: float in [-1.0, 1.0]:
		var leg: Node3D = leg_l if side < 0.0 else leg_r
		add_part(leg, lean_capsule(0.09, 0.30), dark, Vector3(0.12 * side, 0.21, 0))
		add_part(leg, sphere(0.12), dark, Vector3(0.12 * side, 0.066, 0.05), Vector3.ZERO, Vector3(0.95, 0.55, 1.3))
	# Hips: a bark tool belt under the round belly.
	add_part(hips, torus(0.24, 0.30), bark, Vector3(0, 0.44, 0))
	# Chest: round team tunic, a hanging team-dark leaf hem, a dark-leaf collar; the tan seed sack on the back.
	add_part(chest, sphere(0.30), cloth, Vector3(0, 0.57, 0), Vector3.ZERO, Vector3(1.0, 0.92, 0.95))
	add_leaf_crown(chest, Vector3(0, 0.47, 0), 7, 0.25, Vector3(0.21, 0.05, 0.22), -58.0, cloth_dark, 12.0)
	add_leaf_crown(chest, Vector3(0, 0.80, 0.0), 6, 0.13, Vector3(0.20, 0.05, 0.24), -28.0, cloth_dark, 30.0)
	add_part(chest, sphere(0.23), sack, Vector3(0, 0.67, -0.29), Vector3.ZERO, Vector3(1.12, 1.08, 0.9))
	add_part(chest, cyl(0.075, 0.13, 0.13, 8), sack, Vector3(0, 0.91, -0.32))
	add_part(chest, torus(0.08, 0.12, 10), dark, Vector3(0, 0.89, -0.32))
	# Shoulder leaves (team): widen the shoulders, the tunic reads as a leaf coat.
	var sh_l: Array[Transform3D] = [leaf_xform(Vector3.ZERO, Vector3(-1, 0, 0.15), Vector3(0.19, 0.05, 0.24), -32.0)]
	var sh_r: Array[Transform3D] = [leaf_xform(Vector3.ZERO, Vector3(1, 0, 0.15), Vector3(0.19, 0.05, 0.24), -32.0)]
	add_part(arm_l, cluster_mesh("a21_sprig_sh_l", leaf_mesh(), sh_l), cloth, Vector3(-0.24, 0.79, 0.0))
	add_part(arm_r, cluster_mesh("a21_sprig_sh_r", leaf_mesh(), sh_r), cloth, Vector3(0.24, 0.79, 0.0))
	# Head: pale seed-bulb face (FaceKit: big bright eyes, a smile, a pale new-growth fringe), two leaf ears, the dark
	# seed-coat ring the sprout grows from.
	var hc := Vector3(0, 1.0, 0.02)
	add_part(head, sphere(0.25), skin, hc, Vector3.ZERO, Vector3(1.0, 0.94, 0.96))
	_face = FaceKit.attach(self, head, "sprigling", {
		"center": hc, "radius": 0.24, "head_mesh": sphere(0.25), "head_scale": Vector3(1.0, 0.94, 0.96), "head_at": hc,
		"preset": &"bright", "skin": NatureFaces.SKIN, "hair": NatureFaces.NEW_GROWTH, "eyes": NatureFaces.EYE_LEAF,
		"detail": &"low", "x": NatureFaces.lean_x(), "palette": NatureFaces.pal(NatureFaces.NEW_GROWTH),
		"eye": {"c": Vector2(0.080, 0.004), "hw": 0.056, "top": 0.044, "bot": 0.025, "ir": 0.029},
		"brow": {"inner": Vector2(0.044, 0.066), "mid": Vector2(0.086, 0.080), "outer": Vector2(0.130, 0.066)},
		"mouth": {"c": Vector2(0.0, -0.080), "hw": 0.046},
		"hair_fn": func(acc: Dictionary) -> void:
			NatureFaces.fringe(acc, hc, 0.235, 3, NatureFaces.NEW_GROWTH, NatureFaces.NEW_GROWTH_TIP, 0.45, 0.85),
	})
	var ears: Array[Transform3D] = [
		leaf_xform(Vector3(-0.21, 0.0, 0.0), Vector3(-1, 0, -0.2), Vector3(0.13, 0.04, 0.21), 24.0),
		leaf_xform(Vector3(0.21, 0.0, 0.0), Vector3(1, 0, -0.2), Vector3(0.13, 0.04, 0.21), 24.0),
	]
	# Pale new-growth ears (nature_sec_sapling): with the pale face and the sack they keep the top of the unit light on
	# the meadow (Art Lab R3).
	add_part(head, cluster_mesh("a21_sprig_ears", leaf_mesh(), ears), nature(&"nature_sec_sapling"), Vector3(0, 1.07, -0.02))
	add_part(head, cyl(0.06, 0.12, 0.07, 8), dark, Vector3(0, 1.215, -0.01))
	# Sprout: stem + a big leaf + a small one + the glowing bud, baked into one bouncing node (keep_separate).
	_sprout = Node3D.new()
	_sprout.name = "Sprout"
	_sprout.position = Vector3(0, 1.22, -0.01) - model_origin(head)
	_sprout.set_meta(&"keep_separate", true)
	head.add_child(_sprout)
	var lm := leaf_mesh()
	var tip := Vector3(0, 0.27, -0.035)
	var sprout_mesh := bake("a21_sprig_sprout", [
		[cyl(0.03, 0.045, 0.28, 6), Transform3D(Basis(Vector3.RIGHT, -8.0 * DEG), Vector3(0, 0.135, -0.018)),
			nature(&"nature_leaf_dark")],
		[lm, leaf_xform(tip, Vector3(0.3, 0, -1), Vector3(0.30, 0.06, 0.54), 52.0), nature(&"nature_sec_sapling")],
		[lm, leaf_xform(tip + Vector3(0, -0.02, 0.01), Vector3(-0.6, 0, 0.8), Vector3(0.21, 0.05, 0.36), 34.0), leaf],
		[sphere(0.065, 8, 4), Transform3D(Basis(), tip + Vector3(0, 0.03, 0.0)), nature(&"nature_glow")],
	])
	add_part(_sprout, sprout_mesh, null, Vector3(0, 1.22, -0.01), Vector3.ZERO, Vector3.ONE, true, "SproutMesh")
	# Arms: short bark-tan arms with round fists.
	add_limb(arm_l, Vector3(-0.27, 0.72, 0), Vector3(-0.34, 0.47, 0.06), 0.08, skin, 0.105)
	add_limb(arm_r, Vector3(0.27, 0.72, 0), Vector3(0.31, 0.47, 0.08), 0.08, skin, 0.105)
	# Hoe: shaft from the fist up and back over the shoulder (30 deg), a wide flint blade facing forward at the top,
	# a dark binding knot and a little leaf charm tied under it.
	var fist := Vector3(0.31, 0.47, 0.08)
	var d := Vector3(0, cos(30.0 * DEG), -sin(30.0 * DEG))
	add_part(arm_r, cyl(0.042, 0.042, 1.0, 6), bark, fist + d * 0.35, Vector3(-30, 0, 0))
	var top: Vector3 = fist + d * 0.83
	var head_axis := Vector3(0, cos(60.0 * DEG), sin(60.0 * DEG))
	var blade: Array[Transform3D] = [leaf_xform(Vector3.ZERO, Vector3.BACK, Vector3(0.34, 0.08, 0.34), 30.0)]
	add_part(arm_r, cluster_mesh("a21_sprig_blade", leaf_mesh(), blade), nature(&"nature_stone"), top - head_axis * 0.02)
	add_part(arm_r, sphere(0.065, 8, 4), dark, top)
	var charm: Array[Transform3D] = [leaf_xform(Vector3.ZERO, Vector3(1, 0, 0.2), Vector3(0.12, 0.04, 0.20), -50.0)]
	add_part(arm_r, cluster_mesh("a21_sprig_charm", leaf_mesh(), charm), leaf, top - d * 0.12 + Vector3(0.04, 0, 0))
	# Carry: 3 resource crystals poking out of the sack, shown by set_carrying.
	var cr := MultiMeshInstance3D.new()
	cr.name = "Crystals"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cyl(0.0, 0.10, 0.32, 6)
	mm.instance_count = 3
	mm.set_instance_transform(0, Transform3D(Basis(), Vector3(0, 0.14, 0)))
	mm.set_instance_transform(1, Transform3D(Basis(Vector3.BACK, 0.45), Vector3(-0.11, 0.09, 0.03)))
	mm.set_instance_transform(2, Transform3D(Basis(Vector3.BACK, -0.45), Vector3(0.11, 0.08, -0.03)))
	cr.multimesh = mm
	cr.material_override = palette(&"crystal_glow")
	cr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cr.position = Vector3(0, 0.93, -0.32) - model_origin(chest)
	cr.set_meta(&"carry", true)
	cr.visible = false
	chest.add_child(cr)
	# FX: mine sparks at the blade, leaves knocked off on hits, a puff of leaves on death.
	_sparks = make_motes(Color(0.55, 0.85, 1.0), 5, 0.35, 0.05, 2.0, 0.08, false, true)
	_sparks.name = "MineSparks"
	_sparks.position = top + head_axis * 0.26 - model_origin(arm_r)
	arm_r.add_child(_sparks)
	add_hit_leaves(Vector3(0, 0.75, 0.1), Color(0.42, 0.68, 0.22), 5, 0.12)
	var puff := make_petals(Color(0.50, 0.72, 0.20), 8, 1.0, 0.25, 1.5, 0.14, true)
	puff.name = "DeathLeaves"
	puff.set_meta(&"death_fx", true)
	puff.position = Vector3(0, 0.7, 0)
	$Fx.add_child(puff)
	ensure_shadow_blob(0.35, KIN_BLOB)


func _on_action_event(ev: StringName) -> void:
	if ev == &"mine_hit" and _sparks:
		_sparks.restart()
		_sx.y += 5.0


func _on_kin_hit() -> void:
	_sx.y -= 9.0
	_sz.y += 6.0 * (1.0 if int(_t * 10.0) % 2 == 0 else -1.0)


func _kin_process(dt: float) -> void:
	var waddle: float = 0.0
	if not is_idle_fast():
		if _walk_w > 0.0 and not _dead:
			# Waddle: roll onto the planted foot, a little forward lean, the head counters the roll.
			var s: float = sin(TAU * _walk_p)
			waddle = 6.0 * DEG * s * _walk_w
			rot(P_ROOT, Vector3(4.0 * DEG * _walk_w, 0, waddle))
			rot(P_CHEST, Vector3(0, 0, -2.5 * DEG * s * _walk_w))
			rot(P_HEAD, Vector3(0, 0, -2.0 * DEG * s * _walk_w))
		if _action == &"attack" and attack_style == &"worker_pick":
			# Lean back on the wind-up, throw the weight forward on the chop.
			var t := _action_t
			rot(P_CHEST, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.40, -8.0, 16.0) * DEG, 0, 0))
	# Sprout spring: flops with the body's up / down and forward jolts, droops when the Sprigling dies.
	if _sprout == null or _tier >= 2:
		return
	var acc := root_accel()
	var tx: float = 1.15 if _dead else 0.0
	_sx = spring(_sx, tx, -acc.y * 0.55 + acc.z * 0.8, 11.0, 4.5, dt)
	_sz = spring(_sz, -waddle * 1.2, acc.x * 0.8, 10.0, 4.0, dt)
	_sx.x = clampf(_sx.x, -0.9, 1.3)
	_sz.x = clampf(_sz.x, -0.7, 0.7)
	if absf(_sx.x - _sprout_written.x) > 0.003 or absf(_sz.x - _sprout_written.y) > 0.003:
		_sprout_written = Vector2(_sx.x, _sz.x)
		_sprout.rotation = Vector3(_sx.x, 0, _sz.x)


## Mining: the hoe swing of the kit plus the body throwing its weight into each chop.
func _pose_mine(t: float) -> void:
	super._pose_mine(t)
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.35, 0.5, 1.0, -6.0, 14.0) * DEG, 0, 0))


## Fidget: a happy little hop (crouch, jump, land), the free arm thrown up; the sprout flops on the landing.
func _pose_fidget(t: float) -> float:
	var y: float = _k3(t, 0.0, 0.16, 0.16, 0.30, -0.05, -0.05) + _k3(t, 0.16, 0.32, 0.32, 0.50, 0.16, 0.16) \
		+ _k3(t, 0.46, 0.54, 0.54, 0.80, -0.05, -0.05)
	pos(P_ROOT, Vector3(0, y, 0))
	rot(P_ARM_L, Vector3(_k3(t, 0.10, 0.30, 0.45, 0.85, -115.0, -115.0) * DEG, 0,
		_k3(t, 0.10, 0.30, 0.45, 0.85, -20.0, -20.0) * DEG))
	rot(P_ARM_R, Vector3(_k3(t, 0.10, 0.30, 0.45, 0.85, 12.0, 12.0) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_k3(t, 0.10, 0.30, 0.55, 0.95, -14.0, -14.0) * DEG, 0, 0))
	rot(P_LEG_L, Vector3(_k3(t, 0.16, 0.30, 0.40, 0.55, -18.0, -18.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k3(t, 0.16, 0.30, 0.40, 0.55, 12.0, 12.0) * DEG, 0, 0))
	return 1.0


func _kin_revive() -> void:
	_sx = Vector2.ZERO
	_sz = Vector2.ZERO
	_sprout_written = Vector2(99.0, 99.0)
	if _sprout:
		_sprout.rotation = Vector3.ZERO
