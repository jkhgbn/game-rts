extends NatureWarModel
## Vinelasher, Nature T2 soldier (effort trial, low). Height 1.8. A lean bark warrior; a thorn whip coiled around the
## right arm (circle read) that uncoils into a 3 m lash on attack. Glow: whip tip only.

var _lash: Node3D
var _coil: Node3D
var _lash_t: float = -1.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := nature(&"nature_cloth")
	var cdark := nature(&"nature_cloth_dark")
	var bark := nature(&"nature_bark")
	var dark := nature(&"nature_bark_dark")
	var thorn := nature(&"nature_sec_slinger_c")
	var glow := nature(&"nature_glow")
	for leg: Node3D in [$Root/Hips/LegL, $Root/Hips/LegR]:
		var sx: float = -1.0 if leg.name == "LegL" else 1.0
		add_part(leg, cyl(0.07, 0.09, 0.85, 7), dark, Vector3(0.13 * sx, 0.45, 0))
		add_part(leg, box(Vector3(0.14, 0.08, 0.26)), dark, Vector3(0.13 * sx, 0.04, 0.05))
	add_part(hips, leaf_ring_mesh(7, 0.16, Vector3(0.16, 0.035, 0.32), -70.0, 12.0), cdark, Vector3(0, 0.92, 0))
	add_part(chest, cyl(0.20, 0.15, 0.55, 8), bark, Vector3(0, 1.20, 0))
	add_part(chest, sphere(0.2, 8, 4), cloth, Vector3(0, 1.40, -0.06), Vector3.ZERO, Vector3(1.3, 0.6, 1.0))
	add_part(head, sphere(0.14, 10, 5), bark, Vector3(0, 1.64, 0.02), Vector3.ZERO, Vector3(0.9, 1.15, 1.0))
	add_part(head, box(Vector3(0.18, 0.03, 0.04)), dark, Vector3(0, 1.66, 0.14))
	add_leaf(head, Vector3(0, 1.80, -0.02), Vector3(0.26, 0.06, 0.40), cloth, Vector3(-20, 180, 0))
	var trim := add_part(head, torus(0.11, 0.15, 10), palette(&"unit_gold_trim"), Vector3(0, 1.74, 0), Vector3.ZERO,
		Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	for arm: Node3D in [arm_l, arm_r]:
		var sx: float = -1.0 if arm == arm_l else 1.0
		add_part(arm, cyl(0.05, 0.065, 0.62, 6), dark, Vector3(0.28 * sx, 1.15, 0.02))
		add_part(arm, cyl(0.07, 0.08, 0.16, 7), cloth, Vector3(0.28 * sx, 1.02, 0.02))
	# Coiled whip: three thorn rings stacked around the right forearm (big circle read), handle in the fist.
	_coil = add_part(arm_r, torus(0.10, 0.17, 12), thorn, Vector3(0.28, 1.00, 0.02), Vector3.ZERO,
		Vector3(1.6, 1.0, 1.6), true, "Coil")
	add_part(arm_r, torus(0.10, 0.16, 12), thorn, Vector3(0.28, 1.12, 0.02), Vector3(0, 0, 8), Vector3(1.5, 1.0, 1.5))
	add_part(arm_r, cyl(0.035, 0.035, 0.24, 6), dark, Vector3(0.28, 0.80, 0.08), Vector3(70, 0, 0))
	# Lash: hidden, a 3 m thorn line from the fist with the glowing tip; shown during the attack.
	_lash = add_part(arm_r, cyl(0.02, 0.05, 3.0, 5), thorn, Vector3(0.28, 0.80, 1.6), Vector3(90, 0, 0),
		Vector3.ONE, true, "Lash")
	if _lash:
		_lash.visible = false
	add_part(arm_r, sphere(0.08, 8, 4), glow, Vector3(0.28, 0.86, -0.05), Vector3.ZERO, Vector3.ONE, false)
	add_hit_burst(Vector3(0, 1.2, 0.05), Color(0.46, 0.66, 0.20), 7)
	add_death_bloom(Vector3(0, 1.0, 0.1), 0.3, 8, 10, Color(0.55, 0.42, 0.24))
	ensure_shadow_blob(0.42)


func play_attack() -> void:
	super.play_attack()
	_lash_t = 0.0


func play_cast(spell_id: StringName) -> void:
	super.play_cast(spell_id)
	_lash_t = 0.0


func _process(delta: float) -> void:
	super(delta)
	if _lash_t < 0.0 or _lash == null:
		return
	_lash_t += delta
	var on: bool = _lash_t > 0.12 and _lash_t < 0.45
	_lash.visible = on
	if _coil:
		_coil.visible = not on
	if _lash_t >= 0.45:
		_lash_t = -1.0
