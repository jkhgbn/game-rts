extends ShadowModel
## Hollow Oathsworn, Shadow T2 heavy swordsman: Malrik's sworn blade, "honour and backbone" (new-units-12.md 6;
## tiers wave, medium effort). Height 2.0 (mitre tip 2.27). A tall knight in black plate with a hero's V taper:
## huge silver-rimmed pauldrons (the left one with a raised haute-piece), a narrow waist, a long team tabard, a torn
## team cape, a torn crimson sash tied at the left hip. The helm is a closed great helm crowned by a split
## "hollow-bishop" mitre crest (two silver leaves with a gap between them) and two team lappets; the violet eyes in the
## visor slit are glow point 1. He stands in a vigil: both gauntlets on the grip of a long single-edged sword planted
## point-down before him; a violet rune along the blade near the guard is glow point 2.
## Attack `oath_cleave` (0.85 s, strike 0.14): the sword swings up over the head and down in one two-handed chop,
## ShadowModel's knight body throw + stomp and a slam burst at the strike.
## play_cast(&"unbroken_vow") (1.4 s): the sword is raised in salute before the visor, the rune flares white-violet,
## a violet-red sigil ring opens at his feet, then the sword is driven down; the rune stays hot for the Vow's 6 s.
## Death: ShadowModel's violet dissolve. Draws: merged pivots + Rune + Sigil (hidden at rest) + blob + trim; 0 lights.

const ATTACK_LEN := 0.85
const STRIKE := 0.14
const CAST_LEN := 1.4
const VOW_TIME := 6.0
const GRIP := Vector3(0.03, 0.0, 0.33)      # x / z of the sword line
const HAND_R := Vector3(0.03, 1.13, 0.33)
const HAND_L := Vector3(0.03, 1.27, 0.33)
const SIGIL_COL := Color(0.95, 0.25, 0.5)
const RUNE_GLOW := 1.4

var _rune: GeometryInstance3D
var _sigil: GeometryInstance3D
var _sigil_fx: GPUParticles3D
var _vow_left: float = 0.0
var _rune_v: float = -1.0
var _sigil_v: float = -1.0
var _sigil_fired: bool = false


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var plate := palette(&"shadow_iron")
	var trim := palette(&"shadow_silver")
	var leather := palette(&"shadow_leather")
	var cloth := palette(&"shadow_cloth")
	var cdark := palette(&"shadow_cloth_dark")
	var sash := palette(&"fire_cloth_dark")
	var dark := palette(&"unit_eye_dark")
	# ---- Legs: plate cuisses, silver knee cops, greaves, long sabatons.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _tube("ho_thigh_%s" % sx, PackedVector3Array([Vector3(0.13 * sx, 1.0, 0.0),
			Vector3(0.14 * sx, 0.58, 0.03)]), PackedFloat32Array([0.095, 0.075]), 8), plate, Vector3.ZERO)
		add_part(leg, sphere(0.07, 7, 3), trim, Vector3(0.14 * sx, 0.57, 0.07), Vector3.ZERO, Vector3(1.0, 1.0, 0.8))
		add_part(leg, cyl(0.075, 0.09, 0.48, 8), plate, Vector3(0.14 * sx, 0.3, 0.01))
		add_part(leg, sphere(0.08, 7, 3), plate, Vector3(0.14 * sx, 0.055, 0.08), Vector3.ZERO, Vector3(1.0, 0.6, 1.9))
	# ---- Hips: fauld, tassets, long team tabard front and back, the crimson sash knotted at the left hip.
	add_part(hips, cyl(0.21, 0.27, 0.2, 10), plate, Vector3(0, 1.0, 0.0))
	add_part(hips, cyl(0.275, 0.275, 0.035, 10), trim, Vector3(0, 0.9, 0.0))
	for s: float in [-1.0, 1.0]:
		add_part(hips, box(Vector3(0.17, 0.22, 0.04)), plate, Vector3(0.19 * s, 0.84, 0.1), Vector3(-8, 20 * s, 8 * s))
	add_part(hips, box(Vector3(0.24, 0.78, 0.035)), cloth, Vector3(0, 0.62, 0.21), Vector3(-5, 0, 0))
	add_part(hips, box(Vector3(0.24, 0.05, 0.04)), trim, Vector3(0, 0.25, 0.245), Vector3(-5, 0, 0))
	add_part(hips, box(Vector3(0.32, 0.84, 0.035)), cdark, Vector3(0, 0.6, -0.2), Vector3(7, 0, 0))
	add_part(hips, torus(0.2, 0.26, 10), sash, Vector3(0, 1.08, 0.0), Vector3(0, 0, -8), Vector3(1.0, 2.2, 1.0))
	add_part(hips, sphere(0.06, 6, 3), sash, Vector3(-0.24, 1.04, 0.1))
	add_part(hips, box(Vector3(0.08, 0.5, 0.025)), sash, Vector3(-0.28, 0.8, 0.12), Vector3(-4, 20, -10))
	add_part(hips, box(Vector3(0.07, 0.36, 0.025)), sash, Vector3(-0.3, 0.86, 0.02), Vector3(6, 40, -18))
	# ---- Chest: cuirass with a silver ridge, narrow waist, gorget, huge pauldrons, torn team cape.
	add_part(chest, cyl(0.24, 0.19, 0.22, 10), plate, Vector3(0, 1.16, 0.0))
	add_part(chest, sphere(0.27, 10, 5), plate, Vector3(0, 1.4, 0.0), Vector3.ZERO, Vector3(1.18, 1.1, 0.82))
	add_part(chest, box(Vector3(0.035, 0.36, 0.05)), trim, Vector3(0, 1.4, 0.21), Vector3(-8, 0, 0))
	add_part(chest, cyl(0.12, 0.16, 0.1, 10), trim, Vector3(0, 1.66, 0.0))
	# the oath medallion (bronze) on the breast, over the silver ridge.
	add_part(chest, cyl(0.065, 0.065, 0.03, 10), palette(&"fire_bronze"), Vector3(0, 1.47, 0.225), Vector3(80, 0, 0))
	for s: float in [-1.0, 1.0]:
		add_part(chest, sphere(0.17, 9, 4), trim, Vector3(0.37 * s, 1.62, 0.0), Vector3(0, 0, -14 * s), Vector3(1.3, 0.85, 1.15))
		add_part(chest, torus(0.17, 0.2, 10), plate, Vector3(0.39 * s, 1.58, 0.0), Vector3(0, 0, -20 * s), Vector3(1.25, 1.2, 1.15))
		add_part(chest, cyl(0.15, 0.17, 0.07, 9), plate, Vector3(0.42 * s, 1.47, 0.0), Vector3(0, 0, -24 * s))
	add_part(chest, box(Vector3(0.05, 0.2, 0.26)), trim, Vector3(-0.3, 1.8, 0.0), Vector3(0, 0, 14))
	add_part(chest, cape(0.6, 1.25), palette(&"shadow_cape"), Vector3(0, 1.0, -0.24), Vector3(7, 0, 0))
	# ---- Head: great helm, visor slit with violet eyes, the split mitre crest, team lappets down the back.
	add_part(head, cyl(0.125, 0.135, 0.26, 10), plate, Vector3(0, 1.84, 0.01))
	add_part(head, sphere(0.125, 10, 3), plate, Vector3(0, 1.97, 0.01), Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
	add_part(head, box(Vector3(0.2, 0.035, 0.03)), dark, Vector3(0, 1.87, 0.135))
	add_part(head, box(Vector3(0.03, 0.14, 0.03)), trim, Vector3(0, 1.8, 0.14))
	for s: float in [-1.0, 1.0]:
		add_part(head, sphere(0.022, 5, 2), palette(&"shadow_glow_hero"), Vector3(0.045 * s, 1.87, 0.14))
		add_part(head, prism(Vector3(0.13, 0.36, 0.2)), trim, Vector3(0.06 * s, 2.11, 0.0), Vector3(0, 0, -12 * s))
		add_part(head, box(Vector3(0.05, 0.36, 0.02)), cloth, Vector3(0.05 * s, 1.84, -0.15), Vector3(10, 0, 4 * s))
	add_part(head, cyl(0.13, 0.13, 0.04, 10), trim, Vector3(0, 1.96, 0.01))
	var vt := add_part(head, torus(0.15, 0.19, 10), palette(&"unit_gold_trim"), Vector3(0, 1.99, 0.01),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if vt:
		vt.set_meta(&"vet_trim", true)
	# ---- Arms: plate arms reaching in to the grip, silver couters, gauntlets.
	add_part(arm_l, _tube("ho_arm_l", PackedVector3Array([Vector3(-0.37, 1.58, 0.0), Vector3(-0.3, 1.33, 0.13),
		HAND_L + Vector3(-0.05, 0.0, -0.03)]), PackedFloat32Array([0.095, 0.085, 0.07]), 8), plate, Vector3.ZERO)
	add_part(arm_l, sphere(0.065, 7, 3), trim, Vector3(-0.31, 1.33, 0.12))
	add_part(arm_l, cyl(0.08, 0.095, 0.12, 8), trim, HAND_L + Vector3(-0.1, 0.02, -0.05), Vector3(-70, 0, 60))
	add_part(arm_l, sphere(0.065, 7, 3), plate, HAND_L, Vector3.ZERO, Vector3(1.0, 0.9, 1.1))
	add_part(arm_r, _tube("ho_arm_r", PackedVector3Array([Vector3(0.37, 1.58, 0.0), Vector3(0.31, 1.3, 0.13),
		HAND_R + Vector3(0.05, 0.0, -0.03)]), PackedFloat32Array([0.095, 0.085, 0.07]), 8), plate, Vector3.ZERO)
	add_part(arm_r, sphere(0.065, 7, 3), trim, Vector3(0.32, 1.3, 0.12))
	add_part(arm_r, cyl(0.08, 0.095, 0.12, 8), trim, HAND_R + Vector3(0.1, 0.02, -0.05), Vector3(-70, 0, -60))
	add_part(arm_r, sphere(0.065, 7, 3), plate, HAND_R, Vector3.ZERO, Vector3(1.0, 0.9, 1.1))
	# ---- The sword (right arm): pommel, grip, guard, a long single-edged silver blade with a dark spine, the tip.
	add_part(arm_r, sphere(0.045, 6, 3), trim, Vector3(GRIP.x, 1.38, GRIP.z))
	add_part(arm_r, cyl(0.024, 0.024, 0.3, 6), leather, Vector3(GRIP.x, 1.2, GRIP.z))
	add_part(arm_r, box(Vector3(0.24, 0.04, 0.07)), trim, Vector3(GRIP.x, 1.04, GRIP.z))
	add_part(arm_r, box(Vector3(0.06, 0.07, 0.09)), plate, Vector3(GRIP.x, 1.04, GRIP.z))
	add_part(arm_r, box(Vector3(0.02, 0.84, 0.085)), trim, Vector3(GRIP.x, 0.6, GRIP.z + 0.01))
	add_part(arm_r, box(Vector3(0.026, 0.84, 0.022)), plate, Vector3(GRIP.x, 0.6, GRIP.z - 0.035))
	add_part(arm_r, prism(Vector3(0.105, 0.16, 0.02)), trim, Vector3(GRIP.x, 0.1, GRIP.z), Vector3(180, 90, 0))
	_rune = add_part(arm_r, box(Vector3(0.026, 0.42, 0.016)), palette(&"shadow_glow_hero"),
		Vector3(GRIP.x, 0.8, GRIP.z + 0.02), Vector3.ZERO, Vector3.ONE, true, "BladeRune")
	_rune.set_meta(&"own_glow", true)
	var slam := make_motes(Color(0.6, 0.3, 0.9), 10, 0.5, 0.15, 1.8, 0.12, false, true)
	slam.name = "Slam"
	slam.position = Vector3(GRIP.x, 0.3, GRIP.z + 0.5) - model_origin(arm_r)
	arm_r.add_child(slam)
	# ---- Fx: the Vow sigil (a flat glowing ring at the feet, hidden at rest) + its motes, the Shadow death motes.
	var fx: Node3D = $Fx
	_sigil = add_part(fx, torus(0.62, 0.7, 24), palette(&"shadow_glow_hero"), Vector3(0, 0.04, 0), Vector3.ZERO,
		Vector3(1.0, 0.15, 1.0), true, "Sigil")
	_sigil.set_meta(&"own_glow", true)
	_sigil.visible = false
	_sigil_fx = make_motes(SIGIL_COL, 18, 0.9, 0.66, 1.4, 0.13, true, true)
	_sigil_fx.name = "SigilMotes"
	_sigil_fx.position = Vector3(0, 0.05, 0)
	fx.add_child(_sigil_fx)
	var dm := make_motes(Color(0.72, 0.34, 1.0), 14, 1.1, 0.3, 1.3, 0.13, true, true)
	dm.name = "DeathMotes"
	dm.set_meta(&"death_fx", true)
	dm.position = Vector3(0, 0.9, 0)
	fx.add_child(dm)
	ensure_shadow_blob(0.55, Color(0.1, 0.03, 0.16, 0.55))


# ================================================================ meshes (cached, model space)

static func _tube(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	# G-C (docs/art/gc_shadow_units.md): one continuous smooth tube (shared rings, 2 more sides) instead of a stack of
	# 6-sided cylinders: rounder limbs for fewer vertices.
	var last := radii.size() - 1
	return _cached(key, ShadowGeo.tube(pts, radii, {"seg": seg + 2, "cap_start": caps and radii[0] > 0.0,
		"cap_end": caps and radii[last] > 0.0}))


# ================================================================ motion

func _after_ready() -> void:
	super._after_ready()
	_write_rune(1.0)


## Oath cleave: the planted sword swings up over the helm (blade up), then one chop down in front. The sword hangs
## DOWN from the fists, so negative arm angles bring the blade up and over (art-units rule).
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"oath_cleave":
		return super._pose_attack(prev, t)
	var a: float = _k3(t, 0.0, 0.09, STRIKE, ATTACK_LEN, -175.0, -55.0)
	rot(P_ARM_R, Vector3(a * DEG, 0, _k3(t, 0.0, 0.09, STRIKE, ATTACK_LEN, 10.0, -6.0) * DEG))
	rot(P_ARM_L, Vector3(a * DEG, 0, _k3(t, 0.0, 0.09, STRIKE, ATTACK_LEN, -10.0, 6.0) * DEG))
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Unbroken Vow: salute (sword up before the visor), the rune flares, the sigil opens, then the sword is driven down.
func _pose_cast(_spell: StringName, t: float) -> float:
	var up: float = _k3(t, 0.0, 0.3, 0.8, 1.05, 1.0, 1.0)
	var drive: float = _k3(t, 0.8, 0.95, 1.05, CAST_LEN, 1.0, 1.0)
	rot(P_ARM_R, Vector3((-150.0 * up + 25.0 * drive) * DEG, 0, 0))
	rot(P_ARM_L, Vector3((-150.0 * up + 25.0 * drive) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, -0.08 * up, 0.12 * up))
	pos(P_ARM_L, Vector3(0, -0.08 * up, 0.12 * up))
	rot(P_CHEST, Vector3((-6.0 * up + 14.0 * drive) * DEG, 0, 0))
	rot(P_HEAD, Vector3(-10.0 * DEG * up, 0, 0))
	pos(P_ROOT, Vector3(0, 0.04 * up - 0.1 * drive, 0))
	if _tier == 0:
		rot(P_LEG_L, Vector3(-18.0 * DEG * drive, 0, 0))
		rot(P_LEG_R, Vector3(14.0 * DEG * drive, 0, 0))
	# The sigil opens at 0.3 s and fades by the end.
	var s: float = smoothstep(0.25, 0.5, t) * (1.0 - smoothstep(1.05, CAST_LEN, t))
	_write_sigil(s, 0.6 + 0.6 * smoothstep(0.25, 0.9, t))
	if not _sigil_fired and t >= 0.3:
		_sigil_fired = true
		if _sigil_fx and _tier < 2:
			_sigil_fx.restart()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	match ev:
		&"cast_start":
			_sigil_fired = false
			_vow_left = VOW_TIME + CAST_LEN
		&"cast_end", &"death_glow_off":
			_write_sigil(0.0, 1.0)


## Heavy march: the sword carried tip-forward off the ground, the kit's arm swing cancelled so both hands stay on it.
func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_ARM_L, Vector3((18.0 * s - 24.0) * DEG * w, 0, 0))
	rot(P_ARM_R, Vector3((-8.0 * s - 24.0) * DEG * w, 0, 0))
	if _tier == 0:
		rot(P_HIPS, Vector3(0, 5.0 * DEG * s * w, 0))


func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	if _rune == null:
		return
	if _dead:
		_write_rune(3.0 * (1.0 - smoothstep(0.1, 0.4, _death_t)))
		return
	var hot: float = 0.0
	if _vow_left > 0.0:
		_vow_left -= dt
		hot = 1.2 * smoothstep(0.0, 1.0, _vow_left)
	if _action == &"cast":
		hot = 1.2 + 2.2 * _k3(_action_t, 0.0, 0.3, 0.8, 1.2, 1.0, 1.0)
	elif _action == &"attack":
		hot += 1.0 * _k3(_action_t, 0.0, 0.09, STRIKE + 0.04, 0.5, 0.6, 1.0)
	var pulse: float = 0.12 * sin(_t * 2.2) if _tier == 0 else 0.0
	_write_rune(1.0 + hot + pulse)


func _on_revive() -> void:
	super._on_revive()
	_vow_left = 0.0
	_write_sigil(0.0, 1.0)
	_rune_v = -1.0
	_write_rune(1.0)


func _write_rune(v: float) -> void:
	v = snappedf(v * RUNE_GLOW * glow_level(), 0.05)
	if v == _rune_v or _rune == null:
		return
	_rune_v = v
	_rune.set_instance_shader_parameter(&"glow_boost", v)


func _write_sigil(v: float, scale_k: float) -> void:
	if _sigil == null:
		return
	v = snappedf(v, 0.05)
	_sigil.visible = v > 0.0
	if v > 0.0:
		_sigil.scale = Vector3(scale_k, 0.15, scale_k)
	if v != _sigil_v:
		_sigil_v = v
		_sigil.set_instance_shader_parameter(&"glow_boost", v * 1.6)
