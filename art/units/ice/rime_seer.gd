extends IceModel
## Rime Seer (kingdom-ice.md 8.2; polish A.6): the only WHITE unit of the army. A robed seer (pale bell robe, team
## stole and hem, dark collar that frames the head) with a crystal circlet, carrying a tall silver-blue hooked staff
## with a hanging ICE LANTERN (clear faceted glass around a glowing core, ice_glow_unit). The lantern swings (walk
## pendulum, slow idle sway) and is where the bolt and the support beam start. Read at 40 m: white bell + tall
## hook with a light at the top.
## Ranged: caster_fire, release 0.12 s (lantern flash). Support: play_cast(&"support") = staff thrust + lantern flare
## (0.6 s); the beam starts at get_beam_origin(). Idle fidget: peers into the lantern. Death: freezes over,
## shatters. Level 4: gold circlet trim.

const HOOK := Vector3(0.38, 2.16, 0.46)   # model-space point the lantern hangs from

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
	add_part(hips, cyl(0.22, 0.47, 0.92, 10), robe, Vector3(0, 0.46, 0))
	add_part(hips, cyl(0.47, 0.49, 0.12, 10), cloth, Vector3(0, 0.06, 0))
	add_part(hips, box(Vector3(0.20, 0.74, 0.04)), cloth, Vector3(0, 0.50, 0.35), Vector3(-15, 0, 0))
	# Chest: pale torso, team shoulder cape, dark collar.
	add_part(chest, cyl(0.22, 0.24, 0.42, 8), robe, Vector3(0, 1.10, 0))
	add_part(chest, cyl(0.25, 0.33, 0.22, 8), cloth, Vector3(0, 1.17, 0))
	add_part(chest, cyl(0.16, 0.25, 0.10, 8), dark, Vector3(0, 1.31, 0))
	# Head: face, white beard, pale hood + peak, crystal circlet (3 points) and glowing brow gem.
	add_part(head, sphere(0.15), skin, Vector3(0, 1.40, 0.03))
	add_part(head, cyl(0.13, 0.0, 0.34, 6), ice(&"ice_hair"), Vector3(0, 1.24, 0.12), Vector3(-12, 0, 0))
	add_part(head, sphere(0.20), robe, Vector3(0, 1.44, -0.04))
	add_part(head, cyl(0.0, 0.14, 0.28, 6), robe, Vector3(0, 1.65, -0.10), Vector3(-24, 0, 0))
	add_part(head, torus(0.17, 0.215), metal, Vector3(0, 1.52, -0.01), Vector3(-10, 0, 0))
	add_crystal(head, Vector3(0, 1.59, 0.16), Vector3(0, 1.0, 0.3), 0.055, 0.24, frost, 0.55)
	add_crystal(head, Vector3(-0.13, 1.57, 0.12), Vector3(-0.35, 1.0, 0.25), 0.045, 0.17, frost, 0.55)
	add_crystal(head, Vector3(0.13, 1.57, 0.12), Vector3(0.35, 1.0, 0.25), 0.045, 0.17, frost, 0.55)
	add_part(head, sphere(0.06, 6, 3), glow, Vector3(0, 1.535, 0.205))
	add_part(head, box(Vector3(0.16, 0.04, 0.04)), palette(&"unit_eye_dark"), Vector3(0, 1.43, 0.165))
	var trim := add_part(head, torus(0.20, 0.25), palette(&"unit_gold_trim"), Vector3(0, 1.50, -0.02),
		Vector3(-10, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# Arms: bell sleeves; the right hand holds the staff forward.
	add_part(arm_l, cyl(0.07, 0.15, 0.44, 8), robe, Vector3(-0.32, 1.00, 0.02))
	add_part(arm_l, sphere(0.085), skin, Vector3(-0.33, 0.76, 0.05))
	add_limb(arm_r, Vector3(0.31, 1.20, 0), Vector3(0.37, 0.95, 0.15), 0.09, robe, 0.085, skin)
	# Staff: silver-blue shaft, ice crystal foot, hook ring curling forward over the head.
	add_part(arm_r, cyl(0.05, 0.05, 1.96, 6), metal, Vector3(0.38, 1.16, 0.16))
	add_part(arm_r, cyl(0.0, 0.07, 0.20, 6), frost, Vector3(0.38, 0.10, 0.16), Vector3(180, 0, 0))
	add_part(arm_r, sphere(0.075, 6, 3), frost, Vector3(0.38, 2.12, 0.16))
	add_part(arm_r, torus(0.13, 0.20, 12), metal, Vector3(0.38, 2.16, 0.31), Vector3(0, 0, 90))
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
