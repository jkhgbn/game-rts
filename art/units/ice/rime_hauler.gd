extends IceModel
## Rime Hauler, Ice worker (kingdom-ice.md 8.2; polish A.6). Height 1.4, radius 0.4. A stocky ice-cutter: team
## coat with a dark fur hem, a pale fur hood ruff around the face, a sledge-pick with an ICE pick-spike over the right
## shoulder and a wooden back-frame carrying a big block of faceted ice with a small lantern (ice_glow_unit, the
## single glow point). Read at 40 m: round dark-hemmed body + bright ice cube on the back + tool over the shoulder.
## Frost breath every 3 s. Carry: 3 resource crystals on top of the ice block. Mine: blue sparks at the pick tip.
## Idle fidget: hefts the pick. Death: freezes over, shatters. Draw instances after the merge: 8 + 4 particle systems.

var _sparks: GPUParticles3D


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := ice(&"ice_cloth")
	var fur := ice(&"ice_fur")
	var pale := ice(&"ice_fur_pale")
	var leather := ice(&"ice_leather")
	var wood := ice(&"ice_wood")
	var metal := ice(&"ice_metal")
	var steel := ice(&"ice_steel")
	var frost := ice(&"ice_frost_crystal")
	# Chest: team coat (bell) with a dark fur hem, leather belt, pale fur ruff at the neck.
	add_part(chest, cyl(0.26, 0.39, 0.56, 8), cloth, Vector3(0, 0.74, 0))
	add_part(chest, cyl(0.39, 0.42, 0.13, 8), fur, Vector3(0, 0.50, 0))
	add_part(chest, cyl(0.29, 0.31, 0.08, 8), leather, Vector3(0, 0.78, 0))
	add_part(chest, cyl(0.20, 0.33, 0.14, 8), pale, Vector3(0, 1.00, 0))
	# Back-frame: two dark posts, a tray, and a big clear ice block on it (the "worker" read), lantern hook.
	add_part(chest, box(Vector3(0.08, 0.74, 0.08)), wood, Vector3(-0.25, 0.96, -0.34))
	add_part(chest, box(Vector3(0.08, 0.74, 0.08)), wood, Vector3(0.25, 0.96, -0.34))
	add_part(chest, box(Vector3(0.54, 0.09, 0.36)), wood, Vector3(0, 0.84, -0.42))
	add_part(chest, box(Vector3(0.48, 0.44, 0.36)), frost, Vector3(0, 1.11, -0.46), Vector3(4, 10, -3))
	add_part(chest, box(Vector3(0.58, 0.08, 0.10)), wood, Vector3(0, 1.28, -0.30))
	add_part(chest, cyl(0.05, 0.10, 0.07, 6), metal, Vector3(0.33, 1.16, -0.26))
	add_part(chest, sphere(0.09), ice(&"ice_glow_unit"), Vector3(0.33, 1.06, -0.26))
	# Head: face, team hood with a short pointed back, pale fur ring around the face. The painted face (faces pass
	# 2026-09-28): a ruddy hauler with a straw-blond fringe and moustache, grey-blue eyes (FaceKit, replaces the eye bar).
	add_part(head, sphere(0.21), ice(&"ice_skin"), Vector3(0, 1.12, 0.04))
	add_part(head, sphere(0.27), cloth, Vector3(0, 1.17, -0.07), Vector3.ZERO, Vector3(1.0, 1.05, 1.0))
	add_part(head, cyl(0.0, 0.16, 0.30, 6), cloth, Vector3(0, 1.30, -0.26), Vector3(-62, 0, 0))
	add_part(head, torus(0.15, 0.25), pale, Vector3(0, 1.13, 0.13), Vector3(90, 0, 0))
	var hair := Color(0.86, 0.74, 0.46)
	_face = UnitFaces.attach_lean(self, head, "rime_hauler", {"center": Vector3(0, 1.12, 0.04), "radius": 0.21,
		"head_mesh": sphere(0.21), "preset": &"plain", "detail": &"low", "skin": ICE_SKIN, "hair": hair,
		"hair_tip": Color(0.98, 0.92, 0.72), "eyes": Color(0.36, 0.52, 0.66), "ears": &"none", "beard": &"moustache",
		"palette": {"brow": hair.darkened(0.35)}, "brow": {"w": Vector3(0.0085, 0.0080, 0.0034)},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, Vector3(0, 1.12, 0.04), 0.21, hair,
			Color(0.98, 0.92, 0.72), 1.0)})
	# Legs: dark fur trousers + big boots.
	add_part(leg_l, capsule(0.12, 0.34), fur, Vector3(-0.15, 0.28, 0))
	add_part(leg_r, capsule(0.12, 0.34), fur, Vector3(0.15, 0.28, 0))
	add_part(leg_l, box(Vector3(0.25, 0.14, 0.33)), leather, Vector3(-0.15, 0.07, 0.05))
	add_part(leg_r, box(Vector3(0.25, 0.14, 0.33)), leather, Vector3(0.15, 0.07, 0.05))
	# Arms: team sleeves + leather mittens.
	add_limb(arm_l, Vector3(-0.38, 0.95, 0), Vector3(-0.42, 0.62, 0.04), 0.10, cloth, 0.115, leather)
	add_limb(arm_r, Vector3(0.38, 0.95, 0), Vector3(0.40, 0.62, 0.04), 0.10, cloth, 0.115, leather)
	# Sledge-pick: shaft up and back over the shoulder (30 deg), iron hammer head + a long ICE pick spike.
	var fist := Vector3(0.40, 0.62, 0.04)
	var d := Vector3(0, cos(30.0 * DEG), -sin(30.0 * DEG))
	add_part(arm_r, cyl(0.045, 0.045, 1.12, 6), wood, fist + d * 0.40, Vector3(-30, 0, 0))
	var top: Vector3 = fist + d * 0.94
	var head_axis := Vector3(0, cos(60.0 * DEG), sin(60.0 * DEG))
	add_part(arm_r, box(Vector3(0.17, 0.30, 0.17)), steel, top - head_axis * 0.07, Vector3(60, 0, 0))
	add_crystal(arm_r, top + head_axis * 0.07, head_axis, 0.075, 0.40, frost, 0.6)
	# Carry: 3 resource crystals on the ice block (kit crystal colour), shown by set_carrying.
	var cr := MultiMeshInstance3D.new()
	cr.name = "Crystals"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cyl(0.0, 0.10, 0.30, 6)
	mm.instance_count = 3
	mm.set_instance_transform(0, Transform3D(Basis(), Vector3(0, 0.15, 0)))
	mm.set_instance_transform(1, Transform3D(Basis(Vector3.BACK, 0.4), Vector3(-0.12, 0.10, 0.04)))
	mm.set_instance_transform(2, Transform3D(Basis(Vector3.BACK, -0.4), Vector3(0.12, 0.09, -0.04)))
	cr.multimesh = mm
	cr.material_override = palette(&"crystal_glow")
	cr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cr.position = Vector3(0, 1.33, -0.46) - model_origin(chest)
	cr.set_meta(&"carry", true)
	cr.visible = false
	chest.add_child(cr)
	# FX: mine sparks at the pick tip, frost breath, shatter.
	_sparks = make_motes(Color(0.55, 0.85, 1.0), 5, 0.35, 0.05, 2.0, 0.08, false, true)
	_sparks.name = "MineSparks"
	_sparks.position = top + head_axis * 0.45 - model_origin(arm_r)
	arm_r.add_child(_sparks)
	add_breath(Vector3(0, 1.10, 0.28), 0.20)
	add_shatter(Vector3(0, 0.6, 0), 10, 0.3, 0.09)
	ensure_shadow_blob(0.4, BLOB_TINT)


func _on_action_event(ev: StringName) -> void:
	if ev == &"mine_hit" and _sparks:
		_sparks.restart()


func _ice_process(_dt: float) -> void:
	# Heavier trudge: a little forward lean on the walk (the load); the kit adds +10 deg when carrying.
	if _walk_w > 0.0 and not _dead:
		rot(P_CHEST, Vector3(5.0 * DEG * _walk_w, 0, 0))


## Fidget: hefts the pick off the shoulder and drops it back (a bounce), glancing up at the sky.
func _pose_fidget(t: float) -> float:
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.25, 0.45, 0.9, 28.0, -6.0) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_k3(t, 0.2, 0.5, 0.9, 1.3, -14.0, -14.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.35, 0.45, 0.5, 0.7, -0.03, -0.03), 0))
	return 1.3
