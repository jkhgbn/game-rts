extends IceModel
## Rime Colossus (kingdom-ice.md 8.2; polish A.6): a hunched giant of dark stone and PACKED ICE: a faceted deep-ice
## torso under a dark stone hump, 5 jagged glacier crystals growing from the back, one massive faceted ice club-arm
## that reaches the ground, a glowing chest core (ice_glow_hero 3.0). Read at 40 m: the biggest, asymmetric mass
## (club side), bright crystals over a dark back, one strong light in the chest.
## Walk: heavy stomp (a dip and a frost puff at each footfall), shoulders roll. Attack `colossus_slam` (own timeline,
## 1.0 s): club overhead at 0.10, slams down in front at 0.16 (frost burst + a ground shockwave ring), long
## follow-through. Hits: the frost cracks flare. Idle fidget: thumps its chest, snorts frost. Death: crumbles,
## freezes over and shatters at 0.6 s.

const SLAM_LEN := 1.0
const SLAM_HIT := 0.16
const SLAM_POS := Vector3(0.75, 0.06, 1.45)
const RING_LEN := 0.5

static var _ring_mat: StandardMaterial3D

var _core: GeometryInstance3D
var _cracks: GeometryInstance3D
var _slam_fx: GPUParticles3D
var _step_fx: GPUParticles3D
var _ring: MeshInstance3D
var _crack_start: float = -99.0
var _core_flare: float = 0.0
var _core_written: float = -1.0
var _crack_written: float = -1.0
var _ring_t: float = 99.0
var _last_step_p: float = 0.0
var _last_fidget_dt: float = 0.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var stone := ice(&"ice_stone")
	var sdark := ice(&"ice_stone_dark")
	var deep := ice(&"ice_frost_deep")
	var frost := ice(&"ice_frost_crystal")
	var metal := ice(&"ice_metal")
	var glow := ice(&"ice_glow")
	# Legs: short dark stone pillars, ice knee chunks, big DARK stone feet (Art Lab P3: pale feet made the bottom as
	# light as the top; dark feet ground the giant and leave the light to the back crystals).
	# (G-C 2026-10-15: tapered stone legs, rounded stone feet with ice toe crystals, a soft-edged pelvis, a bigger team
	# loincloth front and back, a jagged team hide mantle over the shoulders: the team colour now reads from above.)
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_taper(leg, Vector3(0.33 * sx, 0.18, 0.02), Vector3(0.32 * sx, 0.86, 0), 0.22, 0.25, sdark, 9)
		add_part(leg, sphere(0.19, 6, 3), deep, Vector3(0.34 * sx, 0.64, 0.13), Vector3(0, 30, 0))
		add_part(leg, boot(0.25, 0.26), sdark, Vector3(0.34 * sx, 0.0, 0.08), Vector3.ZERO, Vector3(0.95, 1.0, 1.25))
		add_spikes(leg, Vector3(0.34 * sx, 0.06, 0.34), 3, 0.10, 0.05, 0.16, 75.0, frost, -60.0)
	# Hips: pelvis block + team loincloth (front and back).
	add_part(hips, soft_box(Vector3(0.95, 0.42, 0.62), 0.55), sdark, Vector3(0, 0.98, 0))
	add_part(hips, soft_box(Vector3(0.58, 0.64, 0.06)), ice(&"ice_cloth"), Vector3(0, 0.78, 0.34), Vector3(-6, 0, 0))
	add_part(hips, soft_box(Vector3(0.62, 0.56, 0.06)), ice(&"ice_cloth"), Vector3(0, 0.80, -0.33), Vector3(6, 0, 0))
	# Chest: faceted deep-ice barrel torso, dark stone hump and belly plates, team hide mantle, core socket.
	add_part(chest, sphere(0.62, 7, 4), deep, Vector3(0, 1.62, 0.08), Vector3(0, 12, 0), Vector3(1.25, 1.05, 0.95))
	add_part(chest, sphere(0.50, 7, 4), sdark, Vector3(0, 2.08, -0.14), Vector3.ZERO, Vector3(1.35, 0.85, 1.05))
	add_part(chest, sphere(0.30, 6, 3), sdark, Vector3(-0.42, 1.30, 0.34), Vector3(0, 20, 0), Vector3(1.0, 0.8, 0.7))
	add_part(chest, sphere(0.28, 6, 3), sdark, Vector3(0.44, 1.34, 0.32), Vector3(0, -15, 0), Vector3(1.0, 0.8, 0.7))
	# Team hide thrown over the hump (a shell just outside it, the crystals grow through it) with a jagged hide hem
	# round the shoulders: the big top-facing team-colour mass of the giant (Art Lab R6 3 % before).
	# (the hide covers the back of the hump only; its rim is cut into tufts, so from the RTS camera it reads as a
	# shaggy team pelt, not a smooth dome; the stone brow of the hump stays bare over the head)
	add_part(chest, fur_cap(0.53, -18.0, 7, 22.0, 230.0), ice(&"ice_cloth_dark"), Vector3(0, 2.08, -0.16),
		Vector3(0, 180, 0), Vector3(1.38, 0.88, 1.08))
	add_part(chest, fur_ring(0.64, 0.86, 0.22, 10, 0.07, 1.0, 0.9), ice(&"ice_cloth_dark"), Vector3(0, 1.82, -0.05))
	add_part(chest, torus(0.15, 0.25), metal, Vector3(0, 1.70, 0.64), Vector3(90, 0, 0))
	# Glacier crystals: 5 jagged hexagonal crystals growing out of the back hump, leaning back and out.
	add_crystal(chest, Vector3(0.02, 2.18, -0.30), Vector3(0.0, 1.0, -0.45), 0.21, 1.15, frost, 0.45)
	add_crystal(chest, Vector3(-0.36, 2.08, -0.30), Vector3(-0.45, 1.0, -0.55), 0.17, 0.90, frost, 0.45)
	add_crystal(chest, Vector3(0.40, 2.06, -0.30), Vector3(0.5, 1.0, -0.6), 0.16, 0.85, frost, 0.45)
	add_crystal(chest, Vector3(-0.04, 1.86, -0.56), Vector3(0.05, 0.55, -1.0), 0.15, 0.70, frost, 0.5)
	add_crystal(chest, Vector3(-0.62, 2.02, -0.02), Vector3(-1.0, 0.9, -0.2), 0.10, 0.45, frost, 0.5)
	# Chest core (own glow: pulses like a slow heartbeat, flares on hits and slams)
	_core = add_part(chest, sphere(0.17), ice(&"ice_glow_hero"), Vector3(0, 1.70, 0.66), Vector3.ZERO, Vector3.ONE, true,
		"Core")
	_core.set_meta(&"own_glow", true)
	# Frost cracks: 5 thin glowing seams (one MultiMesh), dim at rest, flare when hit
	_cracks = MultiMeshInstance3D.new()
	_cracks.name = "Cracks"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box(Vector3(0.05, 0.42, 0.04))
	mm.instance_count = 5
	var seams: Array[Transform3D] = [
		Transform3D(Basis.from_euler(Vector3(0.25, 0.0, 0.45)), Vector3(-0.38, 1.55, 0.58)),
		Transform3D(Basis.from_euler(Vector3(0.20, 0.0, -0.55)), Vector3(0.40, 1.48, 0.55)),
		Transform3D(Basis.from_euler(Vector3(1.35, 0.0, 0.9)), Vector3(-0.22, 2.46, 0.02)),
		Transform3D(Basis.from_euler(Vector3(1.30, 0.0, -0.6)), Vector3(0.30, 2.44, -0.02)),
		Transform3D(Basis.from_euler(Vector3(-0.3, 0.0, 0.2)), Vector3(0.66, 1.80, 0.25)),
	]
	for i: int in seams.size():
		var s := seams[i]
		s.origin -= model_origin(chest)
		mm.set_instance_transform(i, s)
	(_cracks as MultiMeshInstance3D).multimesh = mm
	_cracks.material_override = glow
	_cracks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cracks.set_meta(&"own_glow", true)
	chest.add_child(_cracks)
	# Head: low and forward, heavy brow, glowing eye bar, two short ice horns.
	add_part(head, sphere(0.26, 7, 4), stone, Vector3(0, 2.02, 0.52), Vector3.ZERO, Vector3(1.1, 0.9, 1.0))
	add_part(head, soft_box(Vector3(0.48, 0.12, 0.22), 0.55), sdark, Vector3(0, 2.12, 0.64), Vector3(-8, 0, 0))
	add_part(head, box(Vector3(0.32, 0.06, 0.05)), ice(&"ice_glow_unit"), Vector3(0, 2.03, 0.76))
	add_crystal(head, Vector3(-0.18, 2.16, 0.48), Vector3(-0.6, 1.0, -0.3), 0.06, 0.26, frost, 0.6)
	add_crystal(head, Vector3(0.18, 2.16, 0.48), Vector3(0.6, 1.0, -0.3), 0.06, 0.26, frost, 0.6)
	# Left arm: short stone arm + fist, crystal shoulder spike.
	add_taper(arm_l, Vector3(-0.68, 1.95, 0.05), Vector3(-0.80, 1.30, 0.17), 0.19, 0.15, sdark, 9)
	add_part(arm_l, sphere(0.22, 7, 4), stone, Vector3(-0.80, 1.22, 0.18), Vector3.ZERO, Vector3(1.0, 0.9, 1.1))
	add_spikes(arm_l, Vector3(-0.80, 1.26, 0.18), 3, 0.17, 0.045, 0.14, 80.0, frost, 30.0)
	add_crystal(arm_l, Vector3(-0.74, 2.10, 0.0), Vector3(-0.45, 1.0, 0.0), 0.12, 0.48, frost, 0.55)
	# Right arm = the club: dark shoulder boulder, stone upper arm, a massive faceted ice club down to the ground
	# with two stone bands and 3 crystal spikes at the head.
	add_part(arm_r, sphere(0.36, 7, 4), sdark, Vector3(0.80, 2.10, 0.02))
	add_crystal(arm_r, Vector3(0.90, 2.28, -0.02), Vector3(0.5, 1.0, -0.2), 0.12, 0.50, frost, 0.5)
	add_crystal(arm_r, Vector3(0.70, 2.30, -0.14), Vector3(0.1, 1.0, -0.6), 0.09, 0.36, frost, 0.5)
	add_limb(arm_r, Vector3(0.80, 1.95, 0.05), Vector3(0.88, 1.18, 0.12), 0.24, deep)
	add_part(arm_r, torus(0.20, 0.30, 8), sdark, Vector3(0.84, 1.55, 0.09), Vector3(0, 0, 6))
	add_part(arm_r, cyl(0.28, 0.46, 1.05, 6), frost, Vector3(0.90, 0.62, 0.14), Vector3(0, 30, 0))
	add_part(arm_r, torus(0.25, 0.35, 8), sdark, Vector3(0.89, 1.06, 0.13))
	add_part(arm_r, torus(0.36, 0.47, 8), sdark, Vector3(0.90, 0.42, 0.14))
	add_spikes(arm_r, Vector3(0.90, 0.26, 0.14), 3, 0.38, 0.11, 0.46, 70.0, frost, 20.0)
	# Fx: slam frost burst + shockwave ring (ground, in front), footfall frost puffs, breath, shatter (hits: the cracks).
	_slam_fx = make_motes(ICE_GLOW, 16, 0.6, 0.45, 1.6, 0.11, true, true)
	_slam_fx.name = "SlamBurst"
	_slam_fx.position = SLAM_POS + Vector3(0, 0.1, 0)
	$Fx.add_child(_slam_fx)
	_ring = MeshInstance3D.new()
	_ring.name = "SlamRing"
	_ring.mesh = _ring_mesh()
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = SLAM_POS
	_ring.visible = false
	$Fx.add_child(_ring)
	_step_fx = _puffs(0.5, 5, 0.8, 0.95, 0.18, Vector3.UP, 80.0, 0.5, 1.0, Vector3(0, 0.2, 0), 0.5)
	_step_fx.name = "StepPuff"
	$Fx.add_child(_step_fx)
	add_breath(Vector3(0, 1.95, 0.80), 0.42)
	add_shatter(Vector3(0, 1.4, 0.05), 22, 0.7, 0.16)
	ensure_shadow_blob(0.8, BLOB_TINT)


## Flat ground ring (additive, radial ring texture): scaled out and faded by _ice_process on each slam.
static func _ring_mesh() -> Mesh:
	var key := "ice_slam_ring"
	var pm: PlaneMesh = _mesh_cache.get(key)
	if pm == null:
		pm = PlaneMesh.new()
		pm.size = Vector2.ONE
		var g := Gradient.new()
		g.set_color(0, Color(0.75, 0.92, 1.0, 0.0))
		g.set_color(1, Color(0.75, 0.92, 1.0, 0.0))
		g.add_point(0.62, Color(0.75, 0.92, 1.0, 0.0))
		g.add_point(0.80, Color(0.85, 0.96, 1.0, 1.0))
		g.add_point(0.90, Color(0.75, 0.92, 1.0, 0.35))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		_ring_mat = StandardMaterial3D.new()
		_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_ring_mat.disable_fog = true  # G-E 5: an additive quad must not fog
		_ring_mat.albedo_texture = gt
		_ring_mat.albedo_color = Color(1.4, 1.6, 1.8, 1.0)
		_ring_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		pm.material = _ring_mat
		_mesh_cache[key] = pm
	return pm


## Heavy slam (own style); anything else goes to the kit.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"colossus_slam":
		return super._pose_attack(prev, t)
	# Club: overhead (-150) at 0.10, down in front (-40) at the hit, eases back over the long follow-through.
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.10, SLAM_HIT, SLAM_LEN, -150.0, -40.0) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.10, SLAM_HIT, SLAM_LEN, 30.0, -25.0) * DEG, 0, 0))
	# Body: rears back, then bows hard into the slam with a twist toward the club side.
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.10, SLAM_HIT, SLAM_LEN, -12.0, 24.0) * DEG,
		_k3(t, 0.0, 0.10, SLAM_HIT, SLAM_LEN, 10.0, -14.0) * DEG, 0))
	rot(P_HEAD, Vector3(_k3(t, 0.0, 0.10, SLAM_HIT, SLAM_LEN, 10.0, -18.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.10, 0.30, SLAM_LEN, 0.05, -0.14), _k3(t, 0.0, 0.10, SLAM_HIT, SLAM_LEN, -0.05, 0.15)))
	# Knees give under the impact.
	rot(P_LEG_L, Vector3(_k3(t, 0.10, SLAM_HIT, 0.35, SLAM_LEN, 12.0, 12.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k3(t, 0.10, SLAM_HIT, 0.35, SLAM_LEN, -8.0, -8.0) * DEG, 0, 0))
	if prev < SLAM_HIT and t >= SLAM_HIT:
		_on_action_event(&"release")
	return t < SLAM_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_core_flare = 1.0
		if _tier < 2:
			if _slam_fx:
				_slam_fx.restart()
			_ring_t = 0.0
			if _ring:
				_ring.visible = true


## G-C: more snow round the giant (High / Ultra, close camera only).
func _snow_amount() -> int:
	return 10


func _on_ice_hit() -> void:
	_crack_start = _t


func _ice_process(dt: float) -> void:
	var g := glow_level()
	# Walk: heavy stomp (a sharp dip at each footfall), shoulders roll, club drags; frost puff under the foot.
	if _walk_w > 0.0 and not _dead:
		var s := sin(TAU * _walk_p)
		var foot := pow(1.0 - absf(s), 6.0)
		pos(P_ROOT, Vector3(0, -0.07 * foot * _walk_w, 0))
		rot(P_CHEST, Vector3(4.0 * DEG * _walk_w, 7.0 * DEG * s * _walk_w, 3.0 * DEG * s * _walk_w))
		rot(P_ARM_R, Vector3(-4.0 * DEG * s * _walk_w, 0, 3.0 * DEG * _walk_w))
		var half := fmod(_walk_p, 0.5)
		if half < _last_step_p and _tier == 0 and _step_fx:
			var sx: float = -1.0 if _walk_p < 0.5 else 1.0
			_step_fx.position = Vector3(0.34 * sx, 0.05, 0.15)
			_step_fx.restart()
		_last_step_p = half
	# Slam shockwave ring: grows 0.5 -> 3.4 m and fades in RING_LEN.
	if _ring_t < RING_LEN:
		_ring_t += dt
		var u: float = clampf(_ring_t / RING_LEN, 0.0, 1.0)
		var sc: float = lerpf(0.5, 3.4, 1.0 - (1.0 - u) * (1.0 - u))
		_ring.scale = Vector3(sc, 1.0, sc)
		_ring.transparency = u * u
		if u >= 1.0:
			_ring.visible = false
	# Cracks flare for 0.5 s on hits; the core beats slowly (4 s) and flares on hits / slams.
	var k: float = clampf(1.0 - (_t - _crack_start) / 0.5, 0.0, 1.0)
	_core_flare = maxf(0.0, _core_flare - dt / 0.4)
	if _cracks:
		var cb: float = g * (0.35 + 2.6 * k)
		if cb != _crack_written:
			_crack_written = cb
			_cracks.set_instance_shader_parameter(&"glow_boost", cb)
	if _core:
		var beat: float = 0.0
		if _tier == 0:
			beat = 0.25 * pow(maxf(0.0, sin((_t + _phase_off) * TAU / idle_period)), 8.0)
		var b: float = g * (1.0 + beat + 0.8 * k + 1.2 * _core_flare)
		if absf(b - _core_written) > 0.01 or (b == 0.0 and _core_written != 0.0):
			_core_written = b
			_core.set_instance_shader_parameter(&"glow_boost", b)


func _ice_revive() -> void:
	_crack_start = -99.0
	_core_flare = 0.0
	_core_written = -1.0
	_crack_written = -1.0
	_ring_t = 99.0
	if _ring:
		_ring.visible = false


## Fidget: rears up, thumps its chest with the free fist (the core flares) and snorts frost.
func _pose_fidget(t: float) -> float:
	var rear := _k3(t, 0.0, 0.45, 0.75, 1.6, 1.0, 1.0)
	rot(P_CHEST, Vector3(-9.0 * DEG * rear, 0, 0))
	rot(P_HEAD, Vector3(-10.0 * DEG * rear, 0, 0))
	rot(P_ARM_L, Vector3(_k3(t, 0.2, 0.5, 0.62, 1.2, -35.0, -58.0) * DEG, _k3(t, 0.2, 0.5, 0.62, 1.2, 25.0, 30.0) * DEG, 0))
	rot(P_ARM_R, Vector3(0, 0, 6.0 * DEG * rear))
	if t >= 0.62 and _last_fidget_dt < 0.62:
		_core_flare = 1.0
		puff_breath()
	_last_fidget_dt = t
	return 1.6
