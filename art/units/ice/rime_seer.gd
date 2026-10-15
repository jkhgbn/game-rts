extends IceModel
## Rime Seer (kingdom-ice.md 8.2; polish A.6): the only WHITE unit of the army. A robed seer (pale bell robe, team
## stole and hem, dark collar that frames the head) with a crystal circlet, carrying a tall silver-blue hooked staff
## with a hanging ICE LANTERN (clear faceted glass around a glowing core, ice_glow_unit). The lantern swings (walk
## pendulum, slow idle sway) and is where the bolt and the support beam start. Read at 40 m: white bell + tall
## hook with a light at the top.
## Ranged: caster_fire, release 0.12 s (lantern flash). Support: play_cast(&"support") = staff thrust + lantern flare
## (0.6 s); the beam starts at get_beam_origin(). Idle fidget: peers into the lantern. Death: freezes over,
## shatters. Level 4: gold circlet trim.

const HOOK := Vector3(0.38, 2.16, 0.45)   # model-space point the lantern hangs from

var _lantern: Node3D
var _core: GeometryInstance3D
var _flare: float = 0.0
var _core_written: float = -1.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := ice(&"ice_cloth")
	var dark := ice(&"ice_cloth_dark")
	var robe := ice(&"ice_sec_seer")
	var skin := ice(&"ice_skin")
	var metal := ice(&"ice_metal")
	var frost := ice(&"ice_frost_crystal")
	var glow := ice(&"ice_glow_unit")
	# Hips: pale bell robe, team hem band, team stole down the front (no leg pivots: the robe hides the legs).
	# (G-C 2026-10-15: lathed robe / capelet / sleeves / beard, were cylinders and cones)
	add_part(hips, lathe(PackedVector2Array([Vector2(0.47, 0.0), Vector2(0.475, 0.06), Vector2(0.43, 0.22),
		Vector2(0.35, 0.46), Vector2(0.27, 0.70), Vector2(0.225, 0.92)]), 12, 1.0, 0.92), robe, Vector3.ZERO)
	add_part(hips, lathe(PackedVector2Array([Vector2(0.485, -0.005), Vector2(0.49, 0.05), Vector2(0.47, 0.13),
		Vector2(0.445, 0.15)]), 12, 1.0, 0.92), cloth, Vector3.ZERO)
	add_part(hips, soft_box(Vector3(0.20, 0.78, 0.035)), cloth, Vector3(0, 0.48, 0.33), Vector3(-16, 0, 0))
	add_part(hips, cyl(0.065, 0.065, 0.04, 6), frost, Vector3(0, 0.10, 0.45), Vector3(74, 0, 0))
	# Chest: pale torso, team capelet over the shoulders, dark collar, a crystal clasp.
	add_part(chest, lathe(PackedVector2Array([Vector2(0.23, 0.88), Vector2(0.24, 1.02), Vector2(0.24, 1.18),
		Vector2(0.20, 1.29)]), 10, 1.0, 0.9), robe, Vector3.ZERO)
	add_part(chest, lathe(PackedVector2Array([Vector2(0.34, 1.05), Vector2(0.345, 1.09), Vector2(0.30, 1.19),
		Vector2(0.21, 1.27), Vector2(0.12, 1.30)]), 12, 1.0, 0.9), cloth, Vector3.ZERO)
	add_part(chest, cyl(0.16, 0.25, 0.10, 10), dark, Vector3(0, 1.31, 0))
	add_part(chest, cyl(0.055, 0.055, 0.04, 6), frost, Vector3(0, 1.24, 0.24), Vector3(70, 0, 0))
	# Head: face, white beard, pale hood + peak, crystal circlet (3 points) and glowing brow gem.
	add_part(head, sphere(0.15), skin, Vector3(0, 1.40, 0.03))
	add_part(head, lathe(PackedVector2Array([Vector2(0.0, -0.36), Vector2(0.035, -0.31), Vector2(0.08, -0.20),
		Vector2(0.11, -0.10), Vector2(0.13, -0.02), Vector2(0.12, 0.02)]), 8, 1.0, 0.75), ice(&"ice_hair"),
		Vector3(0, 1.35, 0.12), Vector3(-12, 0, 0))
	add_part(head, sphere(0.20), robe, Vector3(0, 1.44, -0.04))
	add_part(head, cyl(0.0, 0.14, 0.28, 6), robe, Vector3(0, 1.65, -0.10), Vector3(-24, 0, 0))
	add_part(head, torus(0.17, 0.215), metal, Vector3(0, 1.52, -0.01), Vector3(-10, 0, 0))
	add_crystal(head, Vector3(0, 1.59, 0.16), Vector3(0, 1.0, 0.3), 0.055, 0.24, frost, 0.55)
	add_crystal(head, Vector3(-0.13, 1.57, 0.12), Vector3(-0.35, 1.0, 0.25), 0.045, 0.17, frost, 0.55)
	add_crystal(head, Vector3(0.13, 1.57, 0.12), Vector3(0.35, 1.0, 0.25), 0.045, 0.17, frost, 0.55)
	add_part(head, sphere(0.06, 6, 3), glow, Vector3(0, 1.535, 0.205))
	# Face (faces pass 2026-09-28): an old seer, lined face, grey-white brows, pale blue eyes, the mouth just above the
	# white beard (lowered 6 cm to show it; the beard is his hair read under the hood). FaceKit, replaces the eye bar.
	var white := Color(0.94, 0.95, 0.97)
	_face = FaceKit.attach(self, head, "rime_seer", {"center": Vector3(0, 1.40, 0.03), "radius": 0.15,
		"head_mesh": sphere(0.15), "preset": &"elder", "detail": &"low", "skin": ICE_SKIN, "hair": white,
		"hair_tip": Color(0.78, 0.88, 1.0), "eyes": Color(0.50, 0.72, 0.92), "ears": &"none",
		"palette": {"brow": Color(0.52, 0.56, 0.66), "lash": Color(0.16, 0.16, 0.22)},
		"eye": {"c": Vector2(0.054, 0.020)}, "brow": {"w": Vector3(0.0075, 0.0070, 0.0030)},
		"mouth": {"c": Vector2(0.0, -0.026), "hw": 0.032}})
	var trim := add_part(head, torus(0.20, 0.25), palette(&"unit_gold_trim"), Vector3(0, 1.50, -0.02),
		Vector3(-10, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# Arms: bell sleeves; the right hand holds the staff forward.
	# (G-C: flared lathed bell sleeves with a team cuff band)
	var sleeve := lathe(PackedVector2Array([Vector2(0.155, -0.02), Vector2(0.16, 0.0), Vector2(0.13, 0.10),
		Vector2(0.09, 0.30), Vector2(0.075, 0.44)]), 10)
	add_part(arm_l, sleeve, robe, Vector3(-0.32, 0.78, 0.02))
	add_part(arm_l, sphere(0.085, 8, 4), skin, Vector3(-0.33, 0.76, 0.05))
	add_part(arm_r, sleeve, robe, Vector3(0.36, 0.97, 0.13), Vector3(-22, 0, 8), Vector3(0.9, 0.62, 0.9))
	add_part(arm_r, sphere(0.085, 8, 4), skin, Vector3(0.37, 0.95, 0.15))
	# Staff: silver-blue shaft with silver bands, ice crystal foot, a crystal collar under the hook ring that curls
	# forward over the head (ring narrowed in G-C: the head stays under 0.35 m above the HP bar line).
	add_part(arm_r, cyl(0.045, 0.05, 1.96, 8), metal, Vector3(0.38, 1.16, 0.16))
	for by: float in [0.62, 1.30, 1.88]:
		add_part(arm_r, cyl(0.065, 0.065, 0.05, 8), ice(&"ice_steel"), Vector3(0.38, by, 0.16))
	add_part(arm_r, cyl(0.0, 0.07, 0.20, 6), frost, Vector3(0.38, 0.10, 0.16), Vector3(180, 0, 0))
	add_spikes(arm_r, Vector3(0.38, 1.98, 0.16), 4, 0.04, 0.035, 0.14, 25.0, frost, 45.0)
	add_part(arm_r, sphere(0.06, 6, 3), frost, Vector3(0.38, 2.10, 0.17))
	add_part(arm_r, torus(0.08, 0.125, 12), metal, Vector3(0.38, 2.16, 0.325), Vector3(0, 0, 90))
	# Lantern: hangs from the hook, swings on its own pivot (keep_separate: chain, cap, glass, core, drip).
	_lantern = Node3D.new()
	_lantern.name = "Lantern"
	_lantern.set_meta(&"keep_separate", true)
	_lantern.position = HOOK - model_origin(arm_r)
	arm_r.add_child(_lantern)
	add_part(_lantern, cyl(0.04, 0.14, 0.10, 6), metal, HOOK + Vector3(0, -0.10, 0))
	add_part(_lantern, cyl(0.12, 0.10, 0.24, 6), ice(&"ice_frost_glass"), HOOK + Vector3(0, -0.27, 0))
	add_part(_lantern, cyl(0.0, 0.09, 0.14, 6), frost, HOOK + Vector3(0, -0.46, 0), Vector3(180, 0, 0))
	_core = add_part(_lantern, sphere(0.085), glow, HOOK + Vector3(0, -0.26, 0), Vector3.ZERO, Vector3(1.0, 1.3, 1.0),
		true, "Core")
	_core.set_meta(&"own_glow", true)
	add_breath(Vector3(0, 1.34, 0.22), 0.20)
	add_shatter(Vector3(0, 0.8, 0), 12, 0.35, 0.10)
	ensure_shadow_blob(0.45, BLOB_TINT)


## Where the support beam and the bolt start (world space).
func get_beam_origin() -> Vector3:
	if _core:
		return _core.global_position
	return global_position + Vector3(0, 1.8, 0)


## Support: `support` = staff thrust toward the target + lantern flare (the 0.25 s beam fits in 0.10-0.35 s).
func _pose_cast(spell: StringName, t: float) -> float:
	if spell != &"support":
		return super._pose_cast(spell, t)
	var k := _k3(t, 0.0, 0.10, 0.35, 0.6, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-38.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(-70.0 * DEG * k, 0, -20.0 * DEG * k))
	rot(P_CHEST, Vector3(6.0 * DEG * k, 0, 0))
	rot(P_HEAD, Vector3(-8.0 * DEG * k, 0, 0))
	_flare = maxf(_flare, k)
	return 0.6


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_flare = 1.0


func _ice_process(dt: float) -> void:
	if _action == &"attack" and _action_t < attack_windup:
		_flare = maxf(_flare, 0.5 * _action_t / maxf(attack_windup, 0.01))
	# The bell robe sways with the walk (no legs: the hips carry the rhythm).
	if _walk_w > 0.0 and not _dead:
		var s := sin(TAU * _walk_p)
		rot(P_HIPS, Vector3(0, 5.0 * DEG * s * _walk_w, 3.5 * DEG * s * _walk_w))
	# Lantern pendulum: +-12 deg at the walk rate, a slow sway at idle; kicks forward on release.
	if _lantern and _tier < 2 and not _dead:
		var sw: float = 12.0 * DEG * sin(TAU * _walk_p) * _walk_w + 4.0 * DEG * sin(_t * 1.3 + _phase_off) * (1.0 - _walk_w)
		_lantern.rotation = Vector3(sw * 0.5 - 20.0 * DEG * _flare, 0.0, sw)
	if _core:
		var b: float = glow_level() * (1.0 + 2.5 * _flare)
		if b != _core_written:
			_core_written = b
			_core.set_instance_shader_parameter(&"glow_boost", b)
	_flare = maxf(0.0, _flare - dt / 0.35)


func _ice_revive() -> void:
	_flare = 0.0
	_core_written = -1.0
	if _lantern:
		_lantern.rotation = Vector3.ZERO


## Fidget: raises the staff so the lantern swings up, peers into its light.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.4, 1.0, 1.5, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-22.0 * DEG * k, 0, 0))
	rot(P_HEAD, Vector3(-12.0 * DEG * k, 14.0 * DEG * k, 0))
	_flare = maxf(_flare, 0.4 * k)
	return 1.5
