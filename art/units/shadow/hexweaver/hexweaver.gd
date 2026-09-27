extends ShadowModel
## Hexweaver, Shadow T2 debuff caster (rush-balance.md 5.1 / 5.4, task 16.V4 art; new-units brief, medium effort).
## Height 1.6 (staff crook 1.95). A hunched witch: team-violet robe over a rounded dark hump, a deep hood whose point
## droops behind her (a small bone charm on its tip), a pale hook-nosed face, long bell sleeves hanging past the
## wrists, a clawed left hand. The silhouette hook: a crooked dark staff in the right hand whose crook dangles a
## bone cage lantern in front of her; the violet soul inside the cage is the only glow point (thin smoke wisps rise
## from it). The cage hangs by gravity (counter-rotates the arm / chest) with a lagging pendulum.
## Attack `hex_bolt` (0.55 s, release 0.12): the claw hand stabs forward, the staff jabs, the cage swings and flares.
## play_cast (Wither Hex, 1.0 s): the staff is raised high, the claw hand grasps, the soul flares, a violet burst.
## Draws: merged pivots + cage (bone) + soul (glow) + wisp + cast burst + blob + hidden vet trim. 0 lights.

const ATTACK_LEN := 0.55
const RELEASE := 0.12
const CAST_LEN := 1.0
const CAST_BURST_AT := 0.55
const HAND_R := Vector3(0.30, 0.95, 0.33)
const HAND_L := Vector3(-0.31, 0.84, 0.29)
const CROOK_TIP := Vector3(0.30, 1.84, 0.63)
const CAGE_DROP := 0.30        # cage centre below the crook tip
const CAGE_R := 0.14
const CAGE_H := 0.17           # half height
const VIOLET := Color(0.72, 0.34, 1.0)

var _cage: Node3D
var _soul: GeometryInstance3D
var _wisp: GPUParticles3D
var _burst: GPUParticles3D
var _cage_rot: Vector3 = Vector3.ZERO
var _cage_written: Vector3 = Vector3(99, 99, 99)
var _flaring: bool = false
var _burst_fired: bool = false


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := palette(&"shadow_cloth")
	var cdark := palette(&"shadow_cloth_dark")
	var leather := palette(&"shadow_leather")
	var skin := palette(&"shadow_skin")
	var bone := palette(&"shadow_bone")
	var glow := palette(&"shadow_glow_mid")
	# ---- Legs: thin dark legs under the robe, pointed shoes poking out of the hem.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _hw_path("hw_leg_%s" % sx, PackedVector3Array([Vector3(0.11 * sx, 0.78, 0.0),
			Vector3(0.12 * sx, 0.42, 0.03), Vector3(0.12 * sx, 0.08, 0.0)]), PackedFloat32Array([0.06, 0.05, 0.045]), 5, false), leather,
			Vector3.ZERO)
		add_part(leg, sphere(0.06, 8, 4), leather, Vector3(0.12 * sx, 0.05, 0.08), Vector3(-10, 0, 0), Vector3(0.9, 0.7, 2.0))
	# ---- Hips: long dark robe skirt to the ankles, a cord belt with bone charms.
	add_part(hips, cyl(0.21, 0.38, 0.66, 12), cdark, Vector3(0, 0.47, 0.0), Vector3(-5, 0, 0))
	add_part(hips, cyl(0.215, 0.225, 0.07, 10), leather, Vector3(0, 0.78, 0.02))
	add_part(hips, box(Vector3(0.04, 0.10, 0.03)), bone, Vector3(-0.12, 0.70, 0.19), Vector3(0, 0, 8))
	add_part(hips, box(Vector3(0.035, 0.08, 0.03)), bone, Vector3(-0.05, 0.69, 0.22), Vector3(0, 0, -6))
	# ---- Chest: the hunch. A forward-leaning team robe torso, a rounded dark hump behind, a shawl, a skull pendant.
	add_part(chest, _hw_path("hw_torso", PackedVector3Array([Vector3(0, 0.78, 0.01), Vector3(0, 1.02, 0.07),
		Vector3(0, 1.19, 0.15)]), PackedFloat32Array([0.21, 0.22, 0.16]), 10, false), cloth, Vector3.ZERO)
	add_part(chest, sphere(0.2, 10, 5), cdark, Vector3(0, 1.21, -0.08), Vector3(-25, 12, 6), Vector3(1.2, 1.0, 1.05))
	add_part(chest, cyl(0.10, 0.28, 0.15, 10), cdark, Vector3(0, 1.21, 0.10), Vector3(32, 10, -5))
	add_part(chest, sphere(0.05, 8, 4), bone, Vector3(0, 1.08, 0.29), Vector3(-15, 0, 0), Vector3(1.0, 1.1, 0.8))
	# Left shoulder fetish (the asymmetry opposite the cage): a small beast skull with a hooked bone horn rising back.
	add_part(chest, sphere(0.065, 8, 4), bone, Vector3(-0.21, 1.27, 0.03), Vector3(0, -20, 0), Vector3(1.0, 0.85, 1.25))
	add_part(chest, _hw_path("hw_fetish", PackedVector3Array([Vector3(-0.22, 1.30, 0.0), Vector3(-0.31, 1.42, -0.04),
		Vector3(-0.39, 1.56, -0.12), Vector3(-0.38, 1.63, -0.25)]), PackedFloat32Array([0.045, 0.034, 0.02, 0.0]), 5),
		bone, Vector3.ZERO)
	# ---- Head: pale hook-nosed face in a deep team hood whose point droops behind, a bone charm on the tip.
	# (the whole head sits low and forward of the shoulders: the hunch read from the game camera)
	var ho := Vector3(0, -0.03, 0.05)
	add_part(head, sphere(0.095, 8, 5), skin, Vector3(0, 1.29, 0.23) + ho, Vector3.ZERO, Vector3(0.9, 1.1, 0.95))
	add_part(head, cyl(0.0, 0.028, 0.13, 5), skin, Vector3(0, 1.275, 0.34) + ho, Vector3(105, 0, 0))
	for ex: float in [-0.038, 0.038]:
		add_part(head, sphere(0.022, 5, 2), palette(&"unit_eye_dark"), Vector3(ex, 1.315, 0.305) + ho)
	add_part(head, _hw_path("hw_hood", PackedVector3Array([Vector3(0, 1.17, 0.08), Vector3(0, 1.33, 0.07),
		Vector3(0, 1.46, 0.0), Vector3(0, 1.54, -0.12), Vector3(0, 1.53, -0.27), Vector3(0, 1.43, -0.37)]),
		PackedFloat32Array([0.15, 0.165, 0.13, 0.08, 0.045, 0.02]), 9, false), cloth, ho)
	add_part(head, torus(0.125, 0.16, 12), cdark, Vector3(0, 1.31, 0.165) + ho, Vector3(80, 0, 0), Vector3(1.0, 1.0, 1.15))
	add_part(head, sphere(0.04, 6, 3), bone, Vector3(0, 1.41, -0.38) + ho)
	var trim := add_part(head, torus(0.15, 0.19, 12), palette(&"unit_gold_trim"), Vector3(0, 1.20, 0.08),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: bell sleeve hanging past the wrist, pale clawed hand.
	add_part(arm_l, _hw_path("hw_sleeve_l", PackedVector3Array([Vector3(-0.22, 1.22, 0.08), Vector3(-0.30, 1.03, 0.14),
		Vector3(-0.31, 0.90, 0.24)]), PackedFloat32Array([0.07, 0.085, 0.13]), 10), cloth, Vector3.ZERO)
	add_part(arm_l, cyl(0.12, 0.015, 0.36, 6), cdark, Vector3(-0.33, 0.72, 0.19), Vector3(-14, 0, -9))
	add_part(arm_l, sphere(0.05, 8, 4), skin, HAND_L)
	add_part(arm_l, _claws_mesh(), skin, Vector3.ZERO)
	# ---- Right arm: bell sleeve, the fist on a crooked dark staff.
	add_part(arm_r, _hw_path("hw_sleeve_r", PackedVector3Array([Vector3(0.22, 1.22, 0.08), Vector3(0.30, 1.05, 0.16),
		Vector3(0.30, 0.99, 0.27)]), PackedFloat32Array([0.07, 0.085, 0.12]), 10), cloth, Vector3.ZERO)
	add_part(arm_r, cyl(0.11, 0.015, 0.32, 6), cdark, Vector3(0.32, 0.82, 0.23), Vector3(-14, 0, 9))
	add_part(arm_r, sphere(0.05, 8, 4), skin, HAND_R)
	add_part(arm_r, _staff_mesh(), leather, Vector3.ZERO)
	add_part(arm_r, cyl(0.042, 0.042, 0.08, 6), palette(&"shadow_silver"), Vector3(0.30, 1.20, 0.35), Vector3(4, 0, 0))
	add_part(arm_r, cyl(0.045, 0.045, 0.07, 6), palette(&"shadow_silver"), Vector3(0.30, 1.78, 0.37), Vector3(4, 0, 0))
	# ---- The bone cage lantern: a pendulum node at the crook tip (keep_separate), cage + soul inside.
	_cage = Node3D.new()
	_cage.name = "HexCage"
	_cage.set_meta(&"keep_separate", true)
	_cage.position = CROOK_TIP - model_origin(arm_r)
	arm_r.add_child(_cage)
	add_part(_cage, _cage_mesh(), bone, CROOK_TIP, Vector3.ZERO, Vector3.ONE, true, "CageBones")
	_soul = add_part(_cage, sphere(0.085, 8, 4), glow, CROOK_TIP + Vector3(0, -CAGE_DROP + 0.01, 0), Vector3.ZERO,
		Vector3(1.0, 1.2, 1.0), true, "CageSoul")
	# Thin smoke threads rising from the cage (looping, stops beyond 45 m) and the Wither Hex burst.
	_wisp = make_motes(VIOLET, 5, 1.3, 0.06, 0.45, 0.09)
	_wisp.name = "CageWisp"
	_wisp.position = Vector3(0, -CAGE_DROP + 0.05, 0)
	_cage.add_child(_wisp)
	_burst = make_motes(VIOLET, 12, 0.7, 0.10, 1.6, 0.13, false, true)
	_burst.name = "HexBurst"
	_burst.position = Vector3(0, -CAGE_DROP, 0)
	_cage.add_child(_burst)
	# ---- Fx: death motes (restarted by the kit when the glows die) + the Shadow violet pool blob.
	var dm := make_motes(VIOLET, 12, 1.1, 0.25, 1.3, 0.12, true, true)
	dm.name = "DeathMotes"
	dm.set_meta(&"death_fx", true)
	dm.position = Vector3(0, 0.7, 0)
	$Fx.add_child(dm)
	ensure_shadow_blob(0.42, Color(0.1, 0.03, 0.16, 0.55))


# ================================================================ meshes (cached, model space)

static func _indexed_hw(st: SurfaceTool) -> Mesh:
	st.index()
	return st.commit()


## Tapered tube through `pts` (radii per point, last 0 = a point), baked into ONE cached mesh.
static func _hw_path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	_append_path(st, pts, radii, seg, caps)
	return _cached(key, _indexed_hw(st))


static func _append_path(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int, caps: bool,
		xf: Transform3D = Transform3D.IDENTITY) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := b - a
		var extra: float = 0.02 if radii[i + 1] > 0.0 else 0.0
		var basis := Basis(Quaternion(Vector3.UP, d.normalized()))
		var len_total := d.length() + extra
		var c := cyl(radii[i + 1], radii[i], len_total, seg, caps)
		st.append_from(c, 0, xf * Transform3D(basis, a + d.normalized() * len_total * 0.5))


## Three long hooked claws from the left hand, reaching forward.
static func _claws_mesh() -> Mesh:
	const KEY := "hw_claws"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for k: int in 3:
		var dx: float = (float(k) - 1.0) * 0.035
		var base := HAND_L + Vector3(dx, -0.01, 0.03)
		_append_path(st, PackedVector3Array([base, base + Vector3(dx * 0.6, -0.05, 0.07),
			base + Vector3(dx, -0.11, 0.08)]), PackedFloat32Array([0.016, 0.012, 0.0]), 4, true)
	return _cached(KEY, _indexed_hw(st))


## Crooked staff: a gnarled shaft through the fist, bent at the top into a hook reaching forward over the cage.
static func _staff_mesh() -> Mesh:
	return _hw_path("hw_staff", PackedVector3Array([Vector3(0.30, 0.16, 0.30), Vector3(0.31, 0.70, 0.32),
		Vector3(0.29, 1.30, 0.35), Vector3(0.30, 1.80, 0.37), Vector3(0.30, 1.93, 0.45), Vector3(0.30, 1.95, 0.57),
		CROOK_TIP]), PackedFloat32Array([0.022, 0.03, 0.03, 0.032, 0.03, 0.026, 0.02]), 6, false)


## Bone cage in the cage node's local space (origin = the crook tip): a vertebra cord, a top cap, 6 curved rib bars,
## a bottom ring and a small skull under it.
static func _cage_mesh() -> Mesh:
	const KEY := "hw_cage"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var c := Vector3(0, -CAGE_DROP, 0)
	# cord
	_append_path(st, PackedVector3Array([Vector3.ZERO, Vector3(0, -CAGE_DROP + CAGE_H + 0.02, 0)]),
		PackedFloat32Array([0.014, 0.014]), 4, false)
	# top cap
	st.append_from(cyl(0.03, 0.07, 0.05, 8), 0, Transform3D(Basis.IDENTITY, c + Vector3(0, CAGE_H + 0.01, 0)))
	# ribs (meridians of an egg), 5 bars with 3 bends each
	for k: int in 5:
		var a: float = (float(k) + 0.5) / 5.0 * TAU
		var pts := PackedVector3Array()
		var radii := PackedFloat32Array()
		for j: int in 4:
			var phi: float = lerpf(0.12, 0.92, float(j) / 3.0) * PI
			var r: float = sin(phi) * CAGE_R
			pts.append(c + Vector3(cos(a) * r, cos(phi) * CAGE_H, sin(a) * r))
			radii.append(0.013)
		_append_path(st, pts, radii, 3, false)
	# bottom ring
	var ring := PackedVector3Array()
	var rr := PackedFloat32Array()
	var ry: float = cos(0.92 * PI) * CAGE_H
	var rrad: float = sin(0.92 * PI) * CAGE_R + 0.01
	for k: int in 6:
		var a2: float = float(k) / 5.0 * TAU
		ring.append(c + Vector3(cos(a2) * rrad, ry, sin(a2) * rrad))
		rr.append(0.014)
	_append_path(st, ring, rr, 4, false)
	# skull under the cage (cranium + jaw)
	st.append_from(sphere(0.05, 6, 3), 0, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.9, 1.05)),
		c + Vector3(0, -CAGE_H - 0.05, 0)))
	st.append_from(box(Vector3(0.06, 0.03, 0.05)), 0, Transform3D(Basis.IDENTITY, c + Vector3(0, -CAGE_H - 0.1, 0.015)))
	return _cached(KEY, _indexed_hw(st))


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"hex_bolt":
		return super._pose_attack(prev, t)
	rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.09, 0.14, ATTACK_LEN, -45.0, -88.0) * DEG, 0, _k3(t, 0.0, 0.09, 0.14,
		ATTACK_LEN, -6.0, 10.0) * DEG))
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.09, 0.14, ATTACK_LEN, -6.0, -24.0) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.09, 0.14, ATTACK_LEN, -8.0, 12.0) * DEG, _k3(t, 0.0, 0.09, 0.14, ATTACK_LEN,
		-10.0, 14.0) * DEG, 0))
	rot(P_HEAD, Vector3(_k3(t, 0.0, 0.09, 0.14, ATTACK_LEN, -6.0, -10.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0, _k3(t, 0.0, 0.09, 0.14, ATTACK_LEN, -0.03, 0.07)))
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Wither Hex: the staff rises high (the cage swings up in front of the hood), the claw grasps, then drags down.
func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.30, 0.62, CAST_LEN, -62.0, -70.0) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.30, 0.58, CAST_LEN, -35.0, -100.0) * DEG, 0,
		_k3(t, 0.0, 0.30, 0.58, CAST_LEN, -20.0, 8.0) * DEG))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.30, 0.58, CAST_LEN, -14.0, 16.0) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_k3(t, 0.0, 0.30, 0.58, CAST_LEN, -12.0, 4.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.30, 0.58, CAST_LEN, 0.04, -0.04), 0))
	if not _burst_fired and t >= CAST_BURST_AT:
		_burst_fired = true
		if _burst and _tier == 0:
			_burst.restart()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	match ev:
		&"cast_start", &"attack_start":
			_burst_fired = false
		&"release":
			if _burst and _tier == 0:
				_burst.restart()


## Hunched shuffle: bent further over, the staff arm planted (little swing), the free sleeve swaying, a side hobble.
func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_CHEST, Vector3(7.0 * DEG * w, 0, 2.0 * DEG * s * w))
	rot(P_ARM_R, Vector3(-10.0 * DEG * s * w, 0, 0))
	if _tier == 0:
		rot(P_HEAD, Vector3(-6.0 * DEG * w, 0, 0))
		rot(P_ROOT, Vector3(0, 0, 2.5 * DEG * s * w))


func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	if _dead or _cage == null:
		return
	# The cage hangs by gravity: undo the arm / chest / root pitch and roll, then add a lagging pendulum.
	var tilt: Vector3 = _off_rot[P_ARM_R] + _off_rot[P_CHEST] + _off_rot[P_ROOT]
	var sway: float = 12.0 * DEG * sin(TAU * _walk_p - 0.8) * _walk_w + 4.0 * DEG * sin(_t * 1.6) * (1.0 - _walk_w)
	var target := Vector3(-tilt.x + sway * 0.5, 0.0, -tilt.z + sway)
	if _tier < 2:
		_cage_rot = _cage_rot.lerp(target, clampf(dt * 9.0, 0.0, 1.0))
		if _cage_rot.distance_squared_to(_cage_written) > 0.00002:
			_cage_written = _cage_rot
			_cage.rotation = _cage_rot
	# The soul flares during attacks and casts.
	if _action == &"attack" or _action == &"cast":
		var k: float
		if _action == &"attack":
			k = _k3(_action_t, 0.0, RELEASE, RELEASE + 0.05, ATTACK_LEN, 1.0, 1.4)
		else:
			k = _k3(_action_t, 0.0, 0.3, CAST_BURST_AT + 0.05, CAST_LEN, 0.8, 2.2)
		if _soul:
			_soul.set_instance_shader_parameter(&"glow_boost", glow_level() * (1.0 + k))
		_flaring = true
	elif _flaring:
		_flaring = false
		_apply_glow(true)


func _on_revive() -> void:
	super._on_revive()
	_cage_rot = Vector3.ZERO
	_cage_written = Vector3(99, 99, 99)
	_flaring = false
	if _cage:
		_cage.rotation = Vector3.ZERO
