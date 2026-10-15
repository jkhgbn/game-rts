extends IceModel
## Rimeshield, Ice melee line (kingdom-ice.md 8.2; polish A.6). Height 1.7, radius 0.5. A square armored guard in
## CRYSTAL ARMOUR over dark blue steel: faceted ice pauldrons (2 crystals each, the widest shoulders of the army), an
## ice gem set in the breastplate, a box helm with an ice crest, an open front (painted FaceKit face) and a glowing brow band (ice_glow_unit, the single glow
## point; the pale Ice glow needs 3.4 to read as light on a pale unit). Behind a ROUND
## SHIELD OF CLEAR ICE (0.9 m, translucent: the team snowflake shows through it, silver rim, crystal boss) and an axe
## with an ice blade. Read at 40 m: wide square block + big pale disc in front.
## Motion: the shield stays braced on the march, shoves forward with the chop, rises on hits (ice chips fly);
## idle fidget: raps the axe on the shield rim.
## Death: freezes over, shatters. Level 4: gold trim ring on the helm.
## G-C 2026-10-15 (docs/art/gc_ice_units.md): the box helm is now a lathed close helm (dome, rolled brim, wrap-around
## cheek / nape guard, steel brow ridge), the torso a lathed team gambeson under a steel breastplate shell, layered
## steel pauldron domes, jagged fur collar / tassets / boot cuffs, a fur-lined team cape down the back, tapered limbs,
## rounded sabatons; the crest is 5 cm lower (head top x1.24 body_height).


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := ice(&"ice_cloth")
	var dark := ice(&"ice_cloth_dark")
	var metal := ice(&"ice_metal")
	var steel := ice(&"ice_steel")
	var fur := ice(&"ice_fur")
	var frost := ice(&"ice_frost_crystal")
	var pale := ice(&"ice_fur_pale")
	# Chest (G-C 2026-10-15: lathed, was a keg + a box): a team gambeson torso (broad chest, narrow waist), a steel
	# breastplate shell over its front with a hexagonal ice gem, layered steel pauldron domes with their crystal pairs,
	# a shaggy pale fur collar and a fur-lined team cape down the back (the team colour seen from the RTS camera).
	add_part(chest, lathe(PackedVector2Array([Vector2(0.29, 0.80), Vector2(0.33, 0.90), Vector2(0.37, 1.05),
		Vector2(0.385, 1.18), Vector2(0.33, 1.28), Vector2(0.20, 1.36), Vector2(0.0, 1.38)]), 10, 1.0, 0.82), cloth, Vector3.ZERO)
	add_part(chest, lathe(PackedVector2Array([Vector2(0.36, 1.03), Vector2(0.395, 1.08),
		Vector2(0.41, 1.17), Vector2(0.365, 1.27), Vector2(0.25, 1.33)]), 6, 1.0, 0.86, 120.0), steel, Vector3.ZERO)
	add_part(chest, cyl(0.12, 0.12, 0.09, 6), frost, Vector3(0, 1.16, 0.355), Vector3(78, 0, 0))
	var dome := lathe(PackedVector2Array([Vector2(0.20, -0.06), Vector2(0.215, 0.0), Vector2(0.19, 0.08),
		Vector2(0.12, 0.135), Vector2(0.0, 0.155)]), 8)
	for sx: float in [-1.0, 1.0]:
		add_part(chest, dome, steel, Vector3(0.45 * sx, 1.28, 0), Vector3(0, 0, -16.0 * sx), Vector3(1.05, 0.9, 1.05))
		add_part(chest, cyl(0.20, 0.23, 0.07, 8, false), metal, Vector3(0.47 * sx, 1.17, 0), Vector3(0, 0, -18.0 * sx))
		add_crystal(chest, Vector3(0.48 * sx, 1.36, 0.03), Vector3(0.5 * sx, 1.0, 0.15), 0.09, 0.42, frost)
		add_crystal(chest, Vector3(0.42 * sx, 1.37, -0.12), Vector3(0.32 * sx, 1.0, -0.45), 0.062, 0.29, frost)
	add_part(chest, fur_ring(0.20, 0.31, 0.12, 7, 0.04, 1.0, 0.9), pale, Vector3(0, 1.27, -0.01))
	add_part(chest, cloak(0.25, 0.42, 0.80, 150.0, 4, 5), ice(&"ice_cape"), Vector3(0, 1.33, -0.02), Vector3(-6, 0, 0))
	# Hips: jagged dark fur tassets (the dark base under the armour), steel belt + crystal buckle, a team tabard flap.
	add_part(hips, fur_ring(0.32, 0.40, 0.28, 8, 0.05, 1.0, 0.9), fur, Vector3(0, 0.52, 0))
	add_part(hips, cyl(0.32, 0.33, 0.07, 8), metal, Vector3(0, 0.80, 0))
	add_part(hips, cyl(0.06, 0.06, 0.05, 6), frost, Vector3(0, 0.80, 0.30), Vector3(90, 0, 0))
	add_part(hips, soft_box(Vector3(0.30, 0.42, 0.03)), cloth, Vector3(0, 0.58, 0.34), Vector3(-10, 0, 0))
	# Head: box helm, glowing brow band (the old visor, raised), ice crest (3 crystals in a row) on a team ridge. The
	# face (faces pass 2026-09-28) looks out of the helm front: a stern veteran, platinum moustache, pale blue eyes. The
	# face sphere is part of the FaceKit mesh (vertex colour = ice_skin): no extra surface on the head.
	# Helm (G-C: a lathed close helm, was a box): a dome with a small rolled brim, a wrap-around guard over the cheeks,
	# ears and nape (open at the front so the face shows), a steel brow ridge; the glowing brow band rides on it.
	add_part(head, lathe(PackedVector2Array([Vector2(0.235, 1.585), Vector2(0.255, 1.60), Vector2(0.245, 1.625),
		Vector2(0.235, 1.69), Vector2(0.195, 1.77), Vector2(0.115, 1.83), Vector2(0.0, 1.85)]), 12), steel, Vector3(0, 0, -0.02))
	add_part(head, lathe(PackedVector2Array([Vector2(0.195, 1.35), Vector2(0.22, 1.40), Vector2(0.235, 1.50),
		Vector2(0.24, 1.60)]), 8, 1.0, 1.0, 250.0), steel, Vector3(0, 0, -0.02), Vector3(0, 180, 0))
	add_part(head, soft_box(Vector3(0.32, 0.06, 0.07)), steel, Vector3(0, 1.60, 0.20), Vector3(-10, 0, 0))
	add_part(head, box(Vector3(0.28, 0.045, 0.04)), ice(&"ice_glow_unit"), Vector3(0, 1.645, 0.215))
	var fc := Vector3(0, 1.49, 0.17)
	_face = UnitFaces.attach_lean(self, head, "rimeshield", {"center": fc, "radius": 0.15, "head_mesh": sphere(0.15, 10, 6),
		"preset": &"stern", "detail": &"low", "skin": ICE_SKIN, "hair": Color(0.88, 0.88, 0.84), "hair_tip": Color(1, 1, 0.97),
		"eyes": Color(0.40, 0.64, 0.86), "ears": &"none", "beard": &"moustache",
		"palette": {"brow": Color(0.46, 0.46, 0.50), "lash": Color(0.12, 0.12, 0.16)},
		"eye": {"hw": 0.032, "top": 0.021, "ir": 0.015}, "mouth": {"c": Vector2(0.0, -0.066), "hw": 0.036},
		"hair_fn": func(acc: Dictionary) -> void: FaceKit.put_mesh(acc, sphere(0.15, 10, 6), Transform3D(Basis.IDENTITY, fc), ICE_SKIN)},
		false)
	# Team ridge + ice crest (3 crystals in a row; lowered 5 cm for the R8 head-height read).
	add_part(head, soft_box(Vector3(0.10, 0.09, 0.46)), cloth, Vector3(0, 1.80, -0.01), Vector3(-4, 0, 0))
	add_crystal(head, Vector3(0, 1.80, 0.12), Vector3(0, 1.0, 0.25), 0.075, 0.33, frost)
	add_crystal(head, Vector3(0, 1.82, -0.04), Vector3(0, 1.0, -0.1), 0.07, 0.27, frost)
	add_crystal(head, Vector3(0, 1.80, -0.18), Vector3(0, 1.0, -0.5), 0.06, 0.21, frost)
	var trim := add_part(head, torus(0.25, 0.30), palette(&"unit_gold_trim"), Vector3(0, 1.75, 0), Vector3.ZERO,
		Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# Legs (G-C: tapered thigh-to-ankle, steel greave, soft-edged sabaton, pale fur boot cuff).
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_taper(leg, Vector3(0.18 * sx, 0.12, 0), Vector3(0.18 * sx, 0.60, 0), 0.085, 0.13, dark)
		add_part(leg, cyl(0.10, 0.085, 0.22, 8, false), steel, Vector3(0.18 * sx, 0.27, 0.02))
		add_part(leg, boot(0.12, 0.15), steel, Vector3(0.18 * sx, 0.0, 0.05), Vector3.ZERO, Vector3(1.0, 1.0, 1.45))
		add_part(leg, fur_ring(0.105, 0.135, 0.07, 5, 0.025), pale, Vector3(0.18 * sx, 0.14, 0.01))
	# Arms: tapered team-dark sleeves, steel bracers and soft-edged gauntlets.
	add_taper(arm_l, Vector3(-0.48, 1.27, 0), Vector3(-0.50, 0.90, 0.09), 0.105, 0.08, dark)
	add_taper(arm_r, Vector3(0.48, 1.27, 0), Vector3(0.48, 0.90, 0.02), 0.105, 0.08, dark)
	add_part(arm_l, cyl(0.10, 0.09, 0.16, 8, false), steel, Vector3(-0.495, 0.99, 0.07), Vector3(14, 0, 0))
	add_part(arm_r, cyl(0.10, 0.09, 0.16, 8, false), steel, Vector3(0.48, 0.99, 0.015), Vector3(3, 0, 0))
	add_part(arm_l, soft_box(Vector3(0.15, 0.15, 0.17)), steel, Vector3(-0.50, 0.86, 0.10))
	add_part(arm_r, soft_box(Vector3(0.15, 0.15, 0.17)), steel, Vector3(0.48, 0.86, 0.02))
	# Round shield of clear ice, front-left, face +Z: 0.9 m disc (12 facets), silver rim, crystal boss, and the team
	# snowflake (3 crossed bars) inside the ice.
	var sc := Vector3(-0.40, 0.98, 0.36)
	add_part(arm_l, cyl(0.45, 0.45, 0.09, 12), ice(&"ice_frost_clear"), sc, Vector3(90, 0, 0))
	add_part(arm_l, torus(0.42, 0.50, 12), metal, sc, Vector3(90, 0, 0))
	for k: int in 3:
		add_part(arm_l, box(Vector3(0.68, 0.10, 0.03)), cloth, sc + Vector3(0, 0, -0.01), Vector3(0, 0, 60.0 * k))
	add_part(arm_l, cyl(0.0, 0.12, 0.20, 6), frost, sc + Vector3(0, 0, 0.12), Vector3(90, 0, 0))
	# Axe, forward-down 45 deg: grip, silver socket, a wide ICE blade on the upper side.
	var fist := Vector3(0.48, 0.86, 0.02)
	var d := Vector3(0, -0.707, 0.707)
	var perp := Vector3(0, 0.707, 0.707)
	add_part(arm_r, cyl(0.045, 0.045, 0.64, 6), ice(&"ice_wood"), fist + d * 0.20, Vector3(135, 0, 0))
	add_part(arm_r, box(Vector3(0.09, 0.12, 0.12)), steel, fist + d * 0.44, Vector3(135, 0, 0))
	# Prism apex into the haft, wide base = the cutting edge (width along the haft, thin across the swing plane).
	var blade := Basis(d, -perp, Vector3.RIGHT).get_euler() * (180.0 / PI)
	add_part(arm_r, prism(Vector3(0.38, 0.30, 0.07)), frost, fist + d * 0.44 + perp * 0.17, blade)
	# FX: ice chips from the shield on hits, breath through the visor, shatter.
	add_hit_chips(sc + Vector3(0, 0.05, 0.10), 6)
	add_breath(Vector3(0, 1.46, 0.27), 0.22)
	add_shatter(Vector3(0, 0.9, 0.05), 14, 0.35, 0.11)
	ensure_shadow_blob(0.5, BLOB_TINT)


func _ice_process(_dt: float) -> void:
	if _dead:
		return
	# March: the shield stays braced (cancels most of the kit's -18 deg arm swing), a slight forward lean.
	if _walk_w > 0.0:
		var s := sin(TAU * _walk_p)
		rot(P_ARM_L, Vector3(14.0 * DEG * s * _walk_w, 0, 0))
		rot(P_CHEST, Vector3(4.0 * DEG * _walk_w, 0, 0))
	# Attack: the shield pulls in on the wind-up, then SHOVES forward with the chop (shield bash + axe).
	if _action == &"attack":
		rot(P_ARM_L, Vector3(_k3(_action_t, 0.0, 0.06, 0.12, 0.40, 12.0, -38.0) * DEG, 0,
			_k3(_action_t, 0.0, 0.06, 0.12, 0.40, 0.0, -10.0) * DEG))
	# Hit: the shield snaps up to cover.
	if _hit_t < HIT_LEN:
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, 0))


## Fidget: raps the axe twice on the rim of the raised shield.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.25, 1.0, 1.3, 1.0, 1.0)
	rot(P_ARM_L, Vector3(-18.0 * DEG * up, 0, 0))
	var tap := 0.0
	if t > 0.25 and t < 1.0:
		tap = absf(sin((t - 0.25) * TAU / 0.36))
	rot(P_ARM_R, Vector3((-55.0 * up + 22.0 * tap * up) * DEG, 0, -28.0 * DEG * up))
	rot(P_CHEST, Vector3(0, 12.0 * DEG * up, 0))
	return 1.3
