extends NatureWarModel
## Greenheart Oathkeeper, Nature T2 heavy swordsman (new-units-12.md 6; tiers wave, medium). Height 2.0, radius 0.55.
## Ysolde's sworn shield, "honour and backbone": a broad-shouldered 2 m warden in layered BARK PLATE (brown, off the
## grass hue) over dark bark limbs, a team tabard, a long dark team cape, leaf-plate pauldrons (the right one
## crowned by 3 thorns), a bark great-helm with a dark eye slit and a tall swept TEAM LEAF CREST (the heroic read).
## Weapons: a BROAD LEAF-SHAPED GREATSHIELD on the left arm (point down, a dark bark rim, a team leaf emblem and a
## thorn boss) and a pale HEARTWOOD SWORD in the right hand (low guard, point forward-down).
## Glow point: the GREEN HEART-KNOT on the chest (own glow, a slow heartbeat; flares on Grove Oath).
## Attack `sword_slash` (kit: cut from the right shoulder, the shield comes up to guard).
## play_cast(&"grove_oath") 1.1 s: the shield is raised high, the sword lifted in salute, the heart flares and a ring
## of leaves sweeps out around the feet. Fidget: a sword salute to the face. Death: Nature "return to the grove".

const CAST_LEN := 1.1
const SH_L := Vector3(-0.40, 1.54, 0.0)
const SH_R := Vector3(0.40, 1.54, 0.0)
const FIST_R := Vector3(0.47, 0.98, 0.10)
const FIST_L := Vector3(-0.44, 1.06, 0.22)
const BLADE_DIR := Vector3(0.0, -0.6, 0.8)
const HEART := Vector3(0.0, 1.43, 0.255)

var _heart: MeshInstance3D
var _ring: MeshInstance3D
var _oath_fx: GPUParticles3D
var _heart_written: float = -1.0
var _flare: float = 0.0
var _ring_on: bool = false
var _oath_fired: bool = false
var _ring_y: float = 0.0


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := nature(&"nature_cloth")
	var cdark := nature(&"nature_cloth_dark")
	var bark := nature(&"nature_bark")
	var dark := nature(&"nature_bark_dark")
	var thorn := nature(&"nature_thorn")
	var heartwood := nature(&"nature_sec_sprigling")
	var glow := nature(&"nature_glow")
	# Face rework 2026-09-28: segment counts trimmed (spheres 6x3 / 10x6, cylinders 8, tori 8, one leaf less per ring) to
	# pay for the open-faced helm's face; the unit was already over the soldier vertex budget before it.
	# G-C (2026-10-15): trimmed again (6-sided limbs / cape, 6-ring tori, one tasset and one mantle leaf less, wider) to
	# get back under the soldier budget (Art Lab B4 FAIL 2703 > 2500).
	# ---- Legs: dark bark thighs, bark greaves + knee plates, heavy dark boots.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, tapered_path_mesh("gho_leg_%s" % sx, PackedVector3Array([Vector3(0.15 * sx, 1.02, 0.0),
			Vector3(0.17 * sx, 0.62, 0.03), Vector3(0.16 * sx, 0.14, 0.0)]), PackedFloat32Array([0.12, 0.10, 0.085]), 6),
			dark, Vector3.ZERO)
		add_part(leg, cyl(0.11, 0.125, 0.38, 6), dark, Vector3(0.165 * sx, 0.31, 0.02))
		add_part(leg, sphere(0.10, 6, 3), bark, Vector3(0.17 * sx, 0.61, 0.08), Vector3(-20, 0, 0), Vector3(1.0, 0.8, 0.9))
		add_part(leg, sphere(0.11, 6, 3), dark, Vector3(0.165 * sx, 0.07, 0.07), Vector3.ZERO, Vector3(1.05, 0.62, 1.6))
	# ---- Hips: bark leaf tassets, team tabard front + back, dark belt.
	add_part(hips, leaf_ring_mesh(6, 0.22, Vector3(0.27, 0.05, 0.36), -70.0, 22.5), bark, Vector3(0, 1.02, 0))
	add_part(hips, box(Vector3(0.28, 0.56, 0.04)), cloth, Vector3(0, 0.80, 0.25), Vector3(-6, 0, 0))
	add_part(hips, box(Vector3(0.28, 0.50, 0.04)), cdark, Vector3(0, 0.82, -0.25), Vector3(6, 0, 0))
	add_part(hips, cyl(0.27, 0.27, 0.09, 8), dark, Vector3(0, 1.06, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.85))
	add_part(hips, box(Vector3(0.12, 0.10, 0.05)), thorn, Vector3(0, 1.06, 0.24))
	# ---- Chest: broad bark cuirass, ridge, gorget, heart frame, leaf-plate pauldrons, long dark team cape.
	add_part(chest, sphere(0.30, 10, 5), bark, Vector3(0, 1.36, 0.0), Vector3(-4, 0, 0), Vector3(1.25, 1.15, 0.85))
	add_part(chest, cyl(0.03, 0.05, 0.42, 5), thorn, Vector3(0, 1.30, 0.245), Vector3(-8, 0, 0))
	add_part(chest, cyl(0.15, 0.20, 0.12, 8), dark, Vector3(0, 1.62, 0.0))
	add_part(chest, torus(0.085, 0.13, 6), thorn, HEART + Vector3(0, 0, -0.01), Vector3(80, 0, 0))
	add_part(chest, thorn_ring_mesh(6, 0.12, 0.025, 0.09, 90.0, 0.0), thorn, HEART + Vector3(0, 0, -0.02))
	for s: float in [-1.0, 1.0]:
		for i: int in 3:
			add_leaf(chest, Vector3(0.36 * s, 1.66 - 0.07 * i, -0.02 + 0.02 * i), Vector3(0.30 - 0.03 * i, 0.07, 0.40 - 0.05 * i),
				[heartwood, dark, bark][i], Vector3(-10.0 + 8.0 * i, 90.0 * s, -32.0 * s - 10.0 * i * s))
	add_thorns(chest, Vector3(0.44, 1.70, -0.02), 3, 0.08, 0.035, 0.24, 28.0, thorn)
	# team leaf mantle over the shoulders (top-facing team colour; lifts the read off brown / purple heath)
	add_part(chest, leaf_ring_mesh(7, 0.17, Vector3(0.29, 0.05, 0.34), -32.0, 20.0), cloth, Vector3(0, 1.64, -0.02),
		Vector3.ZERO, Vector3(1.15, 1.0, 0.9))
	add_part(chest, NatureWarModel.tapered_path_mesh("gho_cape", PackedVector3Array([Vector3(0, 0.40, 0),
		Vector3(0, 0.0, -0.05), Vector3(0, -0.52, -0.12)]), PackedFloat32Array([0.30, 0.36, 0.42]), 6, false), cdark,
		Vector3(0, 1.12, -0.26), Vector3(6, 0, 0), Vector3(1.0, 1.0, 0.14))
	add_part(chest, sphere(0.06, 6, 3), thorn, Vector3(-0.26, 1.60, 0.14))
	# heart-knot: two interlaced glowing rings (own glow, the heartbeat)
	_heart = add_part(chest, _heart_mesh(), glow, HEART, Vector3.ZERO, Vector3.ONE, true, "HeartKnot")
	_heart.set_meta(&"own_glow", true)
	# ---- Head: bark great-helm, dark face plate + eye slit, thorn band, tall swept team leaf crest + 2 bark wings.
	var hc := Vector3(0, 1.82, 0.02)
	add_part(head, sphere(0.165, 10, 6), heartwood, hc, Vector3.ZERO, Vector3(0.95, 1.15, 1.02))
	# Face (FaceKit, was the dark face plate + eye slit): an open-faced helm: a dark rim, the face inside it (steady
	# green eyes, stern brows, a set mouth) and a short chestnut beard over the chin guard.
	var hm := sphere(0.165, 10, 6)
	var hs := Vector3(0.95, 1.15, 1.02)
	var cv := FaceKit.canvas(hc, 0.17, hm, hs, hc, Basis.IDENTITY, 0.004)
	var fo := Vector2(0, -0.012)
	var spec := {
		"center": hc, "radius": 0.17, "head_mesh": hm, "head_scale": hs, "head_at": hc, "preset": &"stern",
		"skin": NatureFaces.SKIN, "hair": NatureFaces.CHESTNUT, "eyes": NatureFaces.EYE_LEAF, "detail": &"low",
		"x": NatureFaces.lean_x(1.1), "palette": NatureFaces.pal(NatureFaces.CHESTNUT),
		"eye": {"c": Vector2(0.036, 0.014), "hw": 0.021, "top": 0.016, "bot": 0.010, "ir": 0.011},
		"brow": {"inner": Vector2(0.014, 0.036), "mid": Vector2(0.036, 0.044), "outer": Vector2(0.058, 0.036),
			"w": Vector3(0.0070, 0.0065, 0.0030)},
		"mouth": {"c": Vector2(0.0, -0.052), "hw": 0.022, "lip": 0.0024},
		"base": func(acc: Dictionary, _id: StringName) -> void:
			FaceKit.fill(acc, cv, FaceKit.ellipse(fo, Vector2(0.084, 0.106), 0.0, 16), Color(0.14, 0.10, 0.05), 0.0010, 0.014)
			FaceKit.fill(acc, cv, FaceKit.ellipse(fo, Vector2(0.071, 0.093), 0.0, 16), NatureFaces.SKIN, 0.0014, 0.014),
		"hair_fn": func(acc: Dictionary) -> void:
			for k: int in 3:
				var x := (float(k) - 1.0) * 0.030
				NatureFaces.blade(acc, hc + Vector3(x, -0.085, 0.165), hc + Vector3(x * 1.3, -0.165, 0.175), 0.022, 0.008,
					Vector3(0, 0, 1), NatureFaces.CHESTNUT, NatureFaces.CHESTNUT_TIP, 0.01),
	}
	_face = FaceKit.attach(self, head, "greenheart_oathkeeper", NatureFaces.style(spec, Vector3.ZERO, 0.004))
	add_part(head, torus(0.14, 0.18, 6), thorn, Vector3(0, 1.88, 0.02), Vector3(-6, 0, 0))
	add_leaf(head, Vector3(0, 2.10, -0.10), Vector3(0.20, 0.035, 0.62), cloth, Vector3(-58, 180, 90))
	add_leaf(head, Vector3(0, 2.02, -0.14), Vector3(0.12, 0.04, 0.44), cdark, Vector3(-40, 180, 90))
	for s: float in [-1.0, 1.0]:
		add_leaf(head, Vector3(0.17 * s, 1.90, -0.08), Vector3(0.10, 0.03, 0.30), bark, Vector3(-30, 180.0 - 30.0 * s, 0))
	var trim := add_part(head, torus(0.17, 0.21, 12), palette(&"unit_gold_trim"), Vector3(0, 1.96, 0.02),
		Vector3(-6, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Right arm: bark sleeve, bracer, gauntlet, the heartwood sword (low guard, forward-down).
	var elb_r := Vector3(0.47, 1.24, -0.02)
	add_part(arm_r, tapered_path_mesh("gho_arm_r", PackedVector3Array([SH_R, elb_r, FIST_R]),
		PackedFloat32Array([0.095, 0.085, 0.075]), 6), dark, Vector3.ZERO)
	add_part(arm_r, cyl(0.095, 0.085, 0.20, 6), bark, elb_r.lerp(FIST_R, 0.5),
		Basis(Quaternion(Vector3.UP, (FIST_R - elb_r).normalized())).get_euler() * (180.0 / PI))
	add_part(arm_r, sphere(0.085, 6, 3), dark, FIST_R)
	var bd := BLADE_DIR.normalized()
	var be := Basis(Quaternion(Vector3.UP, bd)).get_euler() * (180.0 / PI)
	add_part(arm_r, cyl(0.03, 0.03, 0.26, 6), dark, FIST_R - bd * 0.03, be)
	add_part(arm_r, sphere(0.05, 6, 3), thorn, FIST_R - bd * 0.17)
	add_part(arm_r, box(Vector3(0.30, 0.05, 0.07)), dark, FIST_R + bd * 0.11, be)
	add_leaf(arm_r, FIST_R + bd * 0.11 + Vector3(0.17, 0.0, 0.0), Vector3(0.07, 0.03, 0.14), thorn, Vector3(0, 90, 0))
	add_leaf(arm_r, FIST_R + bd * 0.11 + Vector3(-0.17, 0.0, 0.0), Vector3(0.07, 0.03, 0.14), thorn, Vector3(0, -90, 0))
	add_part(arm_r, cyl(0.035, 0.06, 0.84, 4), heartwood, FIST_R + bd * 0.56, be, Vector3(1.7, 1.0, 0.5))
	add_part(arm_r, cyl(0.0, 0.035, 0.16, 4), heartwood, FIST_R + bd * 1.05, be, Vector3(1.7, 1.0, 0.5))
	add_part(arm_r, cyl(0.012, 0.018, 0.70, 4), cdark, FIST_R + bd * 0.50 + Vector3(0, 0, 0.0), be, Vector3(1.0, 1.0, 1.6))
	# ---- Left arm: bark sleeve + gauntlet, the leaf greatshield (point down, facing forward, angled out a little).
	var elb_l := Vector3(-0.49, 1.26, 0.04)
	add_part(arm_l, tapered_path_mesh("gho_arm_l", PackedVector3Array([SH_L, elb_l, FIST_L]),
		PackedFloat32Array([0.095, 0.085, 0.075]), 6), dark, Vector3.ZERO)
	add_part(arm_l, sphere(0.085, 6, 3), dark, FIST_L)
	var sc := Vector3(-0.50, 1.02, 0.34)
	add_leaf(arm_l, sc + Vector3(0, 0, -0.03), Vector3(0.86, 0.10, 1.40), dark, Vector3(90, -14, 0))
	add_leaf(arm_l, sc, Vector3(0.78, 0.13, 1.30), bark, Vector3(90, -14, 0))
	add_leaf(arm_l, sc + Vector3(0.012, 0.02, 0.055), Vector3(0.40, 0.06, 0.70), cloth, Vector3(90, -14, 0))
	add_part(arm_l, sphere(0.075, 8, 4), thorn, sc + Vector3(0.02, 0.10, 0.10), Vector3.ZERO, Vector3(1.0, 1.0, 0.7))
	add_part(arm_l, cyl(0.012, 0.02, 1.05, 4), thorn, sc + Vector3(0.015, -0.02, 0.075), Vector3(0, -14, 0))
	# ---- Grove Oath: a ring of leaves around the feet (hidden, grown during the cast).
	_ring = add_part(hips, leaf_ring_mesh(14, 0.75, Vector3(0.22, 0.03, 0.42), 12.0, 0.0), nature(&"nature_leaf"),
		Vector3(0, 0.06, 0), Vector3.ZERO, Vector3.ONE, true, "OathRing")
	_ring.visible = false
	_oath_fx = make_petals(Color(0.62, 0.86, 0.30), 14, 1.0, 0.6, 1.2, 0.16, true)
	_oath_fx.name = "OathLeaves"
	_oath_fx.position = Vector3(0, 0.6, 0)
	$Fx.add_child(_oath_fx)
	# ---- Fx
	add_hit_burst(Vector3(0, 1.4, 0.1), Color(0.50, 0.36, 0.20), 8)
	add_death_bloom(Vector3(0, 1.1, 0.1), 0.4, 10, 12, Color(0.55, 0.42, 0.24))
	ensure_shadow_blob(0.55)


static func _heart_mesh() -> Mesh:
	const KEY := "gho_heart_gc"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.append_from(torus(0.03, 0.065, 5), 0, Transform3D(Basis.from_euler(Vector3(80, 0, 35) * DEG), Vector3(-0.025, 0.0, 0.0)))
	st.append_from(torus(0.03, 0.065, 5), 0, Transform3D(Basis.from_euler(Vector3(80, 0, -35) * DEG), Vector3(0.025, 0.0, 0.0)))
	st.append_from(sphere(0.045, 8, 4), 0, Transform3D(Basis.IDENTITY, Vector3(0, -0.01, 0.02)))
	return _cached(KEY, _indexed(st))


# ================================================================ motion

## Grove Oath: shield raised high, sword lifted in salute, the heart flares, a ring of leaves sweeps out.
func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.25, 0.8, CAST_LEN, 1.0, 1.0)
	rot(P_ARM_L, Vector3(-95.0 * DEG * k, 0, -10.0 * DEG * k))
	rot(P_ARM_R, Vector3(-150.0 * DEG * _k3(t, 0.05, 0.35, 0.8, CAST_LEN, 1.0, 1.0), 0, 12.0 * DEG * k))
	rot(P_CHEST, Vector3(-10.0 * DEG * k, 0, 0))
	rot(P_HEAD, Vector3(-12.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.2, 0.3, 0.5, 0.06, -0.06), 0))
	rot(P_LEG_L, Vector3(-12.0 * DEG * k, 0, -6.0 * DEG * k))
	rot(P_LEG_R, Vector3(10.0 * DEG * k, 0, 6.0 * DEG * k))
	if t >= 0.25 and not _oath_fired:
		_oath_fired = true
		_flare = 1.6
		if _oath_fx and _tier < 2:
			_oath_fx.restart()
	var ru: float = clampf((t - 0.25) / 0.75, 0.0, 1.0)
	_set_ring(t >= 0.25 and t < CAST_LEN and _tier < 2)
	if _ring_on:
		var s: float = 0.45 + 0.85 * _ease_out(ru)
		_ring.scale = Vector3(s, 1.0 + 1.5 * sin(PI * ru), s)
		_ring.position.y = _ring_y + 0.25 * sin(PI * ru)
		_ring.rotation.y = ru * 1.2
	return CAST_LEN


func _set_ring(on: bool) -> void:
	if on == _ring_on or _ring == null:
		return
	_ring_on = on
	_ring.visible = on


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_oath_fired = false
	elif ev == &"cast_end" or ev == &"death_glow_off":
		_set_ring(false)


func _war_ready() -> void:
	if _ring:
		_ring_y = _ring.position.y


func _war_process(dt: float) -> void:
	if _ring_on and (_dead or _action != &"cast"):
		_set_ring(false)
	_flare = maxf(0.0, _flare - dt / 0.6)
	if _heart:
		var beat: float = 0.0
		if _tier == 0:
			var ph: float = fmod(_t + _phase_off, 1.4) / 1.4
			beat = 0.35 * (maxf(0.0, 1.0 - absf(ph - 0.1) * 12.0) + 0.6 * maxf(0.0, 1.0 - absf(ph - 0.25) * 12.0))
		var b: float = glow_level() * (1.35 + beat + 2.2 * _flare)
		if absf(b - _heart_written) > 0.04:
			_heart_written = b
			_heart.set_instance_shader_parameter(&"glow_boost", b)
	# heavy stride: shoulders roll, the shield arm stays steady
	if _walk_w > 0.0 and not _dead and _tier == 0:
		var s: float = sin(TAU * _walk_p)
		rot(P_CHEST, Vector3(0, -5.0 * DEG * s * _walk_w, 0))
		rot(P_ARM_L, Vector3(14.0 * DEG * s * _walk_w, 0, 0))


func _war_revive() -> void:
	_flare = 0.0
	_heart_written = -1.0
	_set_ring(false)


## Fidget: raises the heartwood sword to the face in salute, then lowers it.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.4, 1.0, 1.5, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-105.0 * DEG * k, 0, -18.0 * DEG * k))
	rot(P_HEAD, Vector3(10.0 * DEG * k, 0, 0))
	_flare = maxf(_flare, 0.4 * k)
	return 1.5
