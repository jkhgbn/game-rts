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
	# Legs (dark fur trousers + boots).
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, capsule(0.10, 0.52), fur, Vector3(0.13 * sx, 0.38, 0))
		add_part(leg, box(Vector3(0.21, 0.11, 0.31)), leather, Vector3(0.13 * sx, 0.055, 0.04))
	# Chest: long team-dark coat skirt (dark mass), team torso, leather belt, pale fur collar, crystal shoulder guard
	# on the left, quiver with 3 ice shards over the left shoulder.
	add_part(chest, cyl(0.24, 0.37, 0.66, 8), dark, Vector3(0, 0.62, 0))
	add_part(chest, cyl(0.27, 0.24, 0.40, 8), cloth, Vector3(0, 1.08, 0))
	add_part(chest, cyl(0.25, 0.26, 0.07, 8), leather, Vector3(0, 0.90, 0))
	add_part(chest, cyl(0.16, 0.35, 0.15, 8), pale, Vector3(0, 1.26, 0))
	add_part(chest, sphere(0.14, 6, 3), frost, Vector3(-0.30, 1.25, 0.0), Vector3.ZERO, Vector3(1.0, 0.75, 1.1))
	add_part(chest, cyl(0.09, 0.08, 0.55, 6), leather, Vector3(-0.02, 1.05, -0.29), Vector3(0, 0, 22))
	add_crystal(chest, Vector3(-0.13, 1.30, -0.29), Vector3(-0.38, 1.0, 0.0), 0.06, 0.34, frost, 0.5)
	add_crystal(chest, Vector3(-0.07, 1.30, -0.34), Vector3(-0.25, 1.0, -0.2), 0.05, 0.28, frost, 0.5)
	add_crystal(chest, Vector3(-0.19, 1.26, -0.24), Vector3(-0.5, 1.0, 0.15), 0.045, 0.24, frost, 0.5)
	# Head: face, team hood cowl + tall pointed hood tip leaning back. The painted face (faces pass 2026-09-28) replaces
	# the glowing eye slit: its irises glow instead (the head keeps its glow point).
	add_part(head, sphere(0.16), skin, Vector3(0, 1.40, 0.03))
	add_part(head, sphere(0.215), cloth, Vector3(0, 1.44, -0.05))
	add_part(head, cyl(0.0, 0.17, 0.42, 6), cloth, Vector3(0, 1.69, -0.14), Vector3(-30, 0, 0))
	_face = FaceKit.attach(self, head, _face_key(), _face_spec())
	var trim := add_part(head, torus(0.18, 0.23), palette(&"unit_gold_trim"), Vector3(0, 1.56, -0.06),
		Vector3(-12, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# Arms: the left rests on the rod, the right holds it at the hip.
	add_limb(arm_l, Vector3(-0.33, 1.20, 0), GRIP_L, 0.085, dark, 0.095, skin)
	add_limb(arm_r, Vector3(0.33, 1.20, 0), GRIP, 0.085, dark, 0.095, skin)
	# Crystal rod: 1.4 m faceted ice, silver bands at the grip and the tip socket, glowing tip crystal.
	var d := ROD_DIR.normalized()
	var e := Basis(Quaternion(Vector3.UP, d)).get_euler() * (180.0 / PI)
	add_part(arm_r, cyl(0.05, 0.045, 1.36, 6), frost, GRIP + d * 0.33, e)
	add_part(arm_r, cyl(0.07, 0.07, 0.16, 6), metal, GRIP, e)
	add_part(arm_r, cyl(0.075, 0.06, 0.10, 6), metal, GRIP + d * 0.98, e)
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
