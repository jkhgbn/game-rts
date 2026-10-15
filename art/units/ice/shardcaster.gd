extends IceModel
## Shardcaster (kingdom-ice.md 8.2; polish A.6): a narrow hooded caster in a dark team-shadow coat holding a LONG
## CRYSTAL ROD level across the body (1.4 m, faceted ice, the brightest line of the army), a quiver of 3 ice shards
## over the left shoulder, 3 shards orbiting the rod tip. Ranged: caster_fire, release 0.12 s.
## Glow points: rod tip (ice_glow_unit; charges up over the wind-up, flares + a burst of motes at the release) and
## the painted FaceKit irises (were the eye slit). Read at 40 m: dark narrow body + bright horizontal line + pointed hood.
## Idle fidget: lifts the rod, the shards whirl. Death: freezes over, shatters. Level 4: gold trim ring on the hood.

const ROD_DIR := Vector3(-0.92, 0.08, 0.38)   # model space: held sideways across the body, tip front-left
const GRIP := Vector3(0.34, 0.88, 0.14)
const GRIP_L := Vector3(-0.26, 0.93, 0.39)     # the left hand rests on the rod

var _tip: GeometryInstance3D
var _spin: Node3D
var _burst: GPUParticles3D
var _flare: float = 0.0
var _spin_speed: float = 1.6
var _tip_written: float = -1.0


## FaceKit face (faces pass 2026-09-28): a young caster, silver-white fringe under the hood, glowing ice-cyan irises.
## The Frostrune Rifleman (extends this script) overrides both.
func _face_key() -> String:
	return "shardcaster"


func _face_spec() -> Dictionary:
	var hair := Color(0.90, 0.93, 0.98)
	var tip := Color(0.70, 0.86, 1.0)
	return {"center": Vector3(0, 1.40, 0.03), "radius": 0.16, "head_mesh": sphere(0.16), "preset": &"bright",
		"detail": &"low", "skin": ICE_SKIN, "hair": hair, "hair_tip": tip, "eyes": Color(0.45, 0.85, 1.0), "ears": &"none",
		"palette": {"iris_glow": 0.8, "brow": Color(0.55, 0.62, 0.74), "lash": Color(0.12, 0.14, 0.22)},
		"eye": {"c": Vector2(0.056, 0.008)},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, Vector3(0, 1.40, 0.03), 0.16, hair, tip, -1.0)}


func _build_parts() -> void:
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := ice(&"ice_cloth")
	var dark := ice(&"ice_cloth_dark")
	var skin := ice(&"ice_skin")
	var leather := ice(&"ice_leather")
	var fur := ice(&"ice_fur")
	var pale := ice(&"ice_fur_pale")
	var metal := ice(&"ice_metal")
	var frost := ice(&"ice_frost_crystal")
	var glow := ice(&"ice_glow_unit")
	# Legs (tapered dark fur trousers + rounded boots; G-C 2026-10-15, were capsules + boxes).
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_taper(leg, Vector3(0.13 * sx, 0.11, 0), Vector3(0.13 * sx, 0.62, 0), 0.075, 0.105, fur)
		add_part(leg, boot(0.105, 0.13), leather, Vector3(0.13 * sx, 0.0, 0.04), Vector3.ZERO, Vector3(1.0, 1.0, 1.4))
	# Chest (G-C: lathed, was cones; same authored part count: the Frostrune Rifleman builds on it and counts them):
	# a long team-dark greatcoat flaring to a jagged fur-rimmed hem, a fitted team torso, leather belt, pale fur collar,
	# a crystal shoulder guard on the left, a quiver with 3 ice shards over the left shoulder (one grouped part).
	add_part(chest, lathe(PackedVector2Array([Vector2(0.39, 0.28), Vector2(0.37, 0.40), Vector2(0.31, 0.64),
		Vector2(0.255, 0.86), Vector2(0.25, 0.93)]), 10, 1.0, 0.9), dark, Vector3.ZERO)
	add_part(chest, fur_ring(0.375, 0.40, 0.10, 8, 0.04, 1.0, 0.9), fur, Vector3(0, 0.26, 0))
	add_part(chest, lathe(PackedVector2Array([Vector2(0.245, 0.88), Vector2(0.27, 1.00), Vector2(0.285, 1.12),
		Vector2(0.25, 1.24), Vector2(0.16, 1.30), Vector2(0.0, 1.31)]), 10, 1.0, 0.85), cloth, Vector3.ZERO)
	add_part(chest, cyl(0.26, 0.27, 0.07, 10), leather, Vector3(0, 0.90, 0))
	add_part(chest, fur_ring(0.16, 0.32, 0.15, 7, 0.04, 1.0, 0.9), pale, Vector3(0, 1.19, 0))
	add_part(chest, sphere(0.14, 6, 3), frost, Vector3(-0.30, 1.25, 0.0), Vector3.ZERO, Vector3(1.0, 0.75, 1.1))
	add_part(chest, cyl(0.09, 0.08, 0.55, 8), leather, Vector3(-0.02, 1.05, -0.29), Vector3(0, 0, 22))
	var shard := cyl(0.0, 1.0, 1.0, 6)
	var prism6 := cyl(1.0, 0.85, 1.0, 6)
	var quiver: Array = []
	for q: Array in [[Vector3(-0.13, 1.30, -0.29), Vector3(-0.38, 1.0, 0.0), 0.06, 0.34],
			[Vector3(-0.07, 1.30, -0.34), Vector3(-0.25, 1.0, -0.2), 0.05, 0.28],
			[Vector3(-0.19, 1.26, -0.24), Vector3(-0.5, 1.0, 0.15), 0.045, 0.24]]:
		var qd: Vector3 = (q[1] as Vector3).normalized()
		var qe := Basis(Quaternion(Vector3.UP, qd)).get_euler() * (180.0 / PI)
		var qr: float = q[2]
		var qh: float = q[3]
		quiver.append([prism6, q[0] + qd * qh * 0.25, qe, Vector3(qr, qh * 0.5, qr)])
		quiver.append([shard, q[0] + qd * qh * 0.75, qe, Vector3(qr, qh * 0.5, qr)])
	add_group(chest, "shardcaster_quiver", frost, quiver)
	# Head: face, team hood cowl + tall pointed hood tip leaning back. The painted face (faces pass 2026-09-28) replaces
	# the glowing eye slit: its irises glow instead (the head keeps its glow point).
	add_part(head, sphere(0.16), skin, Vector3(0, 1.40, 0.03))
	add_part(head, sphere(0.215), cloth, Vector3(0, 1.44, -0.05))
	# (G-C: a lathed cowl whose tip droops back, was a straight cone that read as a pointed cap)
	add_part(head, lathe(PackedVector2Array([Vector2(0.175, 0.0), Vector2(0.16, 0.10), Vector2(0.11, 0.21),
		Vector2(0.055, 0.29), Vector2(0.0, 0.32)]), 8), cloth, Vector3(0, 1.49, -0.04), Vector3(-42, 0, 0))
	add_part(head, cyl(0.0, 0.055, 0.20, 6), cloth, Vector3(0, 1.66, -0.32), Vector3(-118, 0, 0))
	_face = FaceKit.attach(self, head, _face_key(), _face_spec())
	var trim := add_part(head, torus(0.18, 0.23), palette(&"unit_gold_trim"), Vector3(0, 1.56, -0.06),
		Vector3(-12, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# Arms: the left rests on the rod, the right holds it at the hip.
	# (G-C: tapered sleeves with pale fur cuffs and leather gloves, were capsules)
	for arm: Node3D in [arm_l, arm_r]:
		var sh := Vector3(-0.33 if arm == arm_l else 0.33, 1.20, 0)
		var hand: Vector3 = GRIP_L if arm == arm_l else GRIP
		var cuff := sh.lerp(hand, 0.78)
		add_taper(arm, sh, cuff, 0.09, 0.075, dark)
		add_part(arm, fur_ring(0.07, 0.09, 0.05, 5, 0.02), pale, cuff, Basis(Quaternion(Vector3.UP,
			(hand - sh).normalized())).get_euler() * (180.0 / PI))
		add_part(arm, sphere(0.085, 8, 4), leather, hand)
	# Crystal rod: 1.4 m faceted ice, silver bands at the grip, mid-shaft and the tip socket, glowing tip crystal.
	var d := ROD_DIR.normalized()
	var e := Basis(Quaternion(Vector3.UP, d)).get_euler() * (180.0 / PI)
	add_part(arm_r, cyl(0.05, 0.045, 1.36, 6), frost, GRIP + d * 0.33, e)
	add_part(arm_r, cyl(0.07, 0.07, 0.16, 8), metal, GRIP, e)
	add_part(arm_r, cyl(0.062, 0.062, 0.05, 8), metal, GRIP + d * 0.55, e)
	add_part(arm_r, cyl(0.085, 0.06, 0.12, 8), metal, GRIP + d * 0.98, e)
	for k: int in 3:
		var a := TAU * float(k) / 3.0
		var side := Basis(Quaternion(Vector3.UP, d)) * Vector3(cos(a), 0, sin(a))
		add_crystal(arm_r, GRIP + d * 1.0 + side * 0.06, d + side * 0.55, 0.025, 0.16, frost, 0.6)
	var back_e := Basis(Quaternion(Vector3.UP, -d)).get_euler() * (180.0 / PI)
	add_part(arm_r, cyl(0.0, 0.06, 0.18, 6), frost, GRIP - d * 0.44, back_e)
	var tip_pos := GRIP + d * 1.14
	_tip = add_part(arm_r, cyl(0.0, 0.09, 0.32, 6), glow, tip_pos, e, Vector3.ONE, true, "Tip")
	_tip.set_meta(&"own_glow", true)
	# 3 shards orbiting the rod axis at the tip (one MultiMesh, spun by one Node3D)
	var orbit := Node3D.new()
	orbit.name = "Orbit"
	orbit.set_meta(&"keep_separate", true)
	orbit.position = tip_pos - model_origin(arm_r)
	orbit.basis = Basis(Quaternion(Vector3.BACK, d))
	arm_r.add_child(orbit)
	_spin = Node3D.new()
	_spin.name = "Spin"
	orbit.add_child(_spin)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Shards"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cyl(0.0, 0.05, 0.20, 6)
	mm.instance_count = 3
	for i: int in 3:
		var a := TAU * float(i) / 3.0
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(cos(a), sin(a), 0.0) * 0.19))
	mmi.multimesh = mm
	mmi.material_override = glow
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spin.add_child(mmi)
	# FX: release burst at the tip, breath, shatter.
	_burst = make_motes(ICE_GLOW, 8, 0.35, 0.08, 3.0, 0.09, false, true)
	_burst.name = "ReleaseBurst"
	_burst.position = tip_pos + d * 0.15 - model_origin(arm_r)
	arm_r.add_child(_burst)
	add_breath(Vector3(0, 1.38, 0.24), 0.20)
	add_shatter(Vector3(0, 0.85, 0), 12, 0.3, 0.10)
	ensure_shadow_blob(0.45, BLOB_TINT)


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_flare = 1.0
		_spin_speed = 12.0
		if _burst and _tier < 2:
			_burst.restart()


func _ice_process(dt: float) -> void:
	# Windup: the tip brightens toward the release, the rod levels at the target and is thrust forward at the
	# release; after it the flare fades in 0.3 s. Both shoulders share one X axis: giving ArmL the same X rotation
	# as ArmR keeps the left hand on the rod.
	var charge: float = 0.0
	if _action == &"attack":
		var w := attack_windup
		charge = clampf(_action_t / maxf(w, 0.01), 0.0, 1.0) if _action_t < w else 0.0
		rot(P_ARM_L, Vector3(_k3(_action_t, 0.0, w, w, 0.5, -25.0, -25.0) * DEG, 0, 0))
		rot(P_CHEST, Vector3(_k3(_action_t, 0.0, w, w + 0.05, 0.5, -6.0, 5.0) * DEG,
			_k3(_action_t, 0.0, w, w + 0.05, 0.5, 14.0, -10.0) * DEG, 0))
		var thrust := _k3(_action_t, w * 0.5, w, w + 0.04, 0.45, -0.06, 0.14)
		pos(P_ARM_R, Vector3(0, 0, thrust))
		pos(P_ARM_L, Vector3(0, 0, thrust))
	if _walk_w > 0.0 and not _dead:
		# Walk: the kit swings ArmL -18 and ArmR +8; bring ArmL to +8 too.
		rot(P_ARM_L, Vector3(26.0 * DEG * sin(TAU * _walk_p) * _walk_w, 0, 0))
	_flare = maxf(0.0, _flare - dt / 0.3)
	_spin_speed = move_toward(_spin_speed, 1.6, dt * 20.0)
	if _spin and _tier < 2 and not _dead:
		_spin.rotation.z = fmod(_spin.rotation.z + dt * _spin_speed, TAU)
	if _tip:
		var b: float = glow_level() * (1.0 + 1.8 * charge + 2.5 * _flare)
		if b != _tip_written:
			_tip_written = b
			_tip.set_instance_shader_parameter(&"glow_boost", b)


func _ice_revive() -> void:
	_flare = 0.0
	_tip_written = -1.0


## Fidget: lifts the rod to eye level, the orbit shards whirl and the tip glints.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.3, 0.8, 1.2, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-30.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, 0))
	rot(P_HEAD, Vector3(8.0 * DEG * k, -10.0 * DEG * k, 0))
	_spin_speed = maxf(_spin_speed, 1.6 + 6.0 * k)
	_flare = maxf(_flare, 0.35 * k)
	return 1.2
