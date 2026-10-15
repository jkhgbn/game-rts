extends NatureWarModel
## Thornling, Nature cheap melee swarm (kingdom-nature.md 7.2; 8.V3, polish A2.2). Height 1.4, radius 0.4.
## A lanky, hunched thorn imp: a bark keg body leaning far forward, the back armoured in overlapping team leaf-scales
## pierced by 5 raking spine thorns (the silhouette: a spiky hunch), a pointed wedge head thrust forward with a swept
## thorn crest, a V of glowing eyes, long dangling two-jointed arms with team leaf bracers, each ending in THREE long
## hooked thorn claws, digitigrade legs. Glow points: the eyes and the sap-knot between the shoulder blades
## (nature_glow 1.5; the knot is what the high camera sees).
## Motion: restless scuttle (lean, claws swinging low), `claw_frenzy` attack (own timeline, 0.6 s: coils, right claw
## rakes at 0.11 = the strike, left at 0.21, a hop-lunge), claw-clack fidget, hit splinters, Nature death.
## Parts: 26 meshes incl. the blob and the hidden L4 trim; ~9 draw instances after the merge.

const ATTACK_LEN := 0.6
# claw_frenzy tracks: [t, value, ease] (see NatureWarModel._kf). Arm x: + swings the claws back, - rakes forward-up.
static var F_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.07, 55.0, 1, 0.11, -100.0, 2, 0.20, -70.0, 1, 0.60, 0.0, 0])
static var F_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.07, -25.0, 1, 0.13, 50.0, 1, 0.21, -100.0, 2, 0.32, -70.0, 1, 0.60, 0.0, 0])
static var F_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 26.0, 1, 0.11, -30.0, 2, 0.21, 24.0, 2, 0.34, 6.0, 0, 0.60, 0.0, 0])
static var F_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -12.0, 1, 0.12, 16.0, 2, 0.30, 10.0, 0, 0.60, 0.0, 0])
static var F_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.08, 1, 0.13, 0.34, 2, 0.30, 0.26, 0, 0.60, 0.0, 0])
static var F_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.06, 1, 0.12, 0.09, 1, 0.22, -0.04, 2, 0.40, 0.0, 0])
static var F_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -14.0, 1, 0.13, 10.0, 0, 0.60, 0.0, 0])
static var F_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.07, 18.0, 1, 0.13, -30.0, 1, 0.35, -18.0, 0, 0.60, 0.0, 0])
static var F_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.13, 24.0, 1, 0.35, 14.0, 0, 0.60, 0.0, 0])


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
	var glow := nature(&"nature_glow")
	# ---- Legs: digitigrade (thigh forward to the knee, shin back to the ankle), clawed feet.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _leg_mesh(), dark, Vector3(0.15 * sx, 0, 0))
		add_part(leg, _foot_mesh(), dark, Vector3(0.16 * sx, 0, 0))
	# ---- Hips: a skirt of hanging team-dark leaves.
	add_part(hips, leaf_ring_mesh(6, 0.13, Vector3(0.17, 0.035, 0.30), -68.0, 12.0), cdark, Vector3(0, 0.60, 0.0))
	# ---- Chest: bark keg leaning forward, team leaf-scales on the back and shoulders, spine + shoulder thorns,
	# the glowing sap-knot between the shoulder blades.
	add_part(chest, sphere(0.25, 12, 6), bark, Vector3(0, 0.86, 0.03), Vector3(28, 0, 0), Vector3(1.0, 1.3, 0.92))
	# G-C: a dark vine belt round the keg's waist: breaks the bark mass at zoom 10.
	add_part(chest, torus(0.17, 0.215, 12), dark, Vector3(0, 0.70, 0.07), Vector3(28, 0, 0), Vector3(1.0, 1.0, 0.92))
	add_part(chest, _scales_mesh(), cloth, Vector3.ZERO)
	add_part(chest, _spine_mesh(), thorn, Vector3.ZERO)
	add_part(chest, sphere(0.085, 8, 4), glow, Vector3(0, 1.06, -0.13), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	add_leaf(chest, Vector3(0, 0.95, 0.27), Vector3(0.30, 0.06, 0.42), cdark, Vector3(62, 0, 0))
	# ---- Head: pointed wedge thrust forward, snout, V of glowing eyes, swept thorn crest, team leaf cap, L4 trim.
	add_part(head, sphere(0.19, 10, 5), bark, Vector3(0, 1.17, 0.27), Vector3(-8, 0, 0), Vector3(1.05, 0.88, 1.28))
	add_part(head, cyl(0.025, 0.075, 0.13, 6), bark, Vector3(0, 1.14, 0.50), Vector3(100, 0, 0), Vector3(1.0, 1.0, 0.8))
	# Face (FaceKit): glowing sap eyes (the glow point, was the V eye slits), a wicked grin under the snout, leaf-bark
	# ears; the thorn crest is its hair.
	var hc := Vector3(0, 1.17, 0.27)
	var gl := Color(0.75, 1.0, 0.40)
	_face = FaceKit.attach(self, head, "thornling", NatureFaces.style({
		"center": hc, "radius": 0.21, "head_mesh": sphere(0.19, 10, 5), "head_scale": Vector3(1.05, 0.88, 1.28),
		"head_at": hc, "preset": &"stern", "skin": NatureFaces.BARK.lightened(0.08), "hair": Color(0.20, 0.13, 0.06),
		"eyes": gl, "detail": &"low", "ears": &"none",
		"x": NatureFaces.lean_x(1.1, {&"neutral": {"mouth": {"kind": "smirk"}, "cut_in": 0.35}}),
		"palette": {"sclera": FaceKit.glow(Color(0.86, 1.0, 0.55), 0.55), "iris_in": FaceKit.glow(Color(0.95, 1.0, 0.7), 1.0),
			"iris_out": FaceKit.glow(Color(0.45, 0.80, 0.15), 0.8), "pupil": Color(0.06, 0.08, 0.02),
			"lash": Color(0.10, 0.07, 0.03), "brow": Color(0.14, 0.09, 0.04), "mouth_in": Color(0.12, 0.10, 0.03),
			"teeth": Color(0.90, 0.84, 0.62), "lip": NatureFaces.BARK.darkened(0.2), "lip_line": Color(0.10, 0.07, 0.03)},
		"eye": {"c": Vector2(0.070, 0.030), "tilt": 0.014}, "mouth": {"c": Vector2(0.0, -0.105), "hw": 0.052},
		"hair_fn": func(acc: Dictionary) -> void:
			for sx: float in [-1.0, 1.0]:
				NatureFaces.ear_leaf(acc, hc + Vector3(0, 0.02, -0.02), 0.19, sx, NatureFaces.BARK.lightened(0.12), 0.75, 0.45, 0.35),
	}, Vector3(-8, 0, 0), 0.003))
	add_part(head, _crest_mesh(), thorn, Vector3.ZERO)
	add_leaf(head, Vector3(0, 1.30, 0.16), Vector3(0.30, 0.06, 0.42), cloth, Vector3(-14, 180, 0))
	var trim := add_part(head, torus(0.13, 0.17, 10), palette(&"unit_gold_trim"), Vector3(0, 1.27, 0.22), Vector3(-12, 0, 0),
		Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Arms: long two-jointed bark arms, team leaf bracer, dark knuckle, three hooked claws.
	for arm: Node3D in [arm_l, arm_r]:
		var sx: float = -1.0 if arm == arm_l else 1.0
		add_part(arm, _arm_mesh(sx), dark, Vector3.ZERO)
		# G-C: a bracer of 3 team leaves wrapped round the forearm, tips down to the wrist (was a plain cylinder).
		add_part(arm, _bracer_mesh(sx), cloth, Vector3.ZERO)
		add_part(arm, sphere(0.085, 6, 3), dark, Vector3(0.40 * sx, 0.56, 0.28))
		add_part(arm, _claws_mesh(sx), thorn, Vector3(0.40 * sx, 0.56, 0.28))
	# ---- Fx
	add_hit_burst(Vector3(0, 0.95, 0.05), Color(0.46, 0.66, 0.20), 7)
	add_death_bloom(Vector3(0, 0.75, 0.1), 0.3, 8, 10, Color(0.55, 0.42, 0.24))
	ensure_shadow_blob(0.40)


# ================================================================ meshes (cached per type, model space unless said)

## Thigh (hip -> knee forward) and shin (knee -> ankle back) as one tapered bark limb; local to x = 0.
static func _leg_mesh() -> Mesh:
	return tapered_path_mesh("thornling_leg", PackedVector3Array([Vector3(0, 0.52, 0.0), Vector3(0.01, 0.30, 0.11),
		Vector3(0.01, 0.10, -0.05)]), PackedFloat32Array([0.085, 0.065, 0.05]))


## Long foot pointing forward with two toe claws (one mesh); local to x = 0.
static func _foot_mesh() -> Mesh:
	const KEY := "thornling_foot"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.append_from(sphere(0.07, 8, 4), 0, Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.0)), Vector3(0, 0.07, -0.05)))
	for s: float in [-1.0, 1.0]:
		var dir := Vector3(0.03 * s, -0.10, 1.0).normalized()
		st.append_from(cyl(0.0, 0.055, 0.26, 6), 0, Transform3D(Basis(Quaternion(Vector3.UP, dir)),
			Vector3(0.04 * s, 0.05, -0.03) + dir * 0.13))
	return _cached(KEY, _indexed(st))


## Overlapping team leaf-scales down the hunched back + two big leaves per shoulder (one mesh, model space).
static func _scales_mesh() -> Mesh:
	var xs: Array[Transform3D] = []
	# Back scales: bases along the spine, tips down the back.
	var ys: Array[float] = [1.12, 1.00, 0.88, 0.76]
	var zs: Array[float] = [-0.04, -0.14, -0.20, -0.22]
	var ws: Array[float] = [0.40, 0.42, 0.38, 0.32]
	for i: int in 4:
		xs.append(leaf_xform(Vector3(0, ys[i], zs[i]), Vector3(0, 0, -1), Vector3(ws[i], 0.07, 0.36), -52.0 - 6.0 * i))
	# Shoulder leaves: pointing out and a little forward / back, drooping.
	for s: float in [-1.0, 1.0]:
		xs.append(leaf_xform(Vector3(0.16 * s, 1.10, 0.10), Vector3(s, 0, 0.30), Vector3(0.26, 0.06, 0.40), -26.0))
		xs.append(leaf_xform(Vector3(0.15 * s, 1.06, -0.04), Vector3(s, 0, -0.55), Vector3(0.22, 0.06, 0.34), -14.0))
	return cluster_mesh("thornling_scales_a22", leaf_mesh(), xs)


## G-C: 3 team leaves wrapped round the forearm (shoulder-elbow-wrist path of _arm_mesh), bases at the elbow side, tips
## overlapping down toward the wrist; side +1 / -1 (model space).
static func _bracer_mesh(side: float) -> Mesh:
	var elbow := Vector3(0.40 * side, 0.80, 0.10)
	var wrist := Vector3(0.40 * side, 0.57, 0.27)
	var axis := (wrist - elbow).normalized()
	var xs: Array[Transform3D] = []
	for i: int in 3:
		var a := TAU * float(i) / 3.0 + 0.4 * side
		var out := (Basis(axis, a) * Vector3(1, 0, 0).cross(axis)).normalized()
		var base := elbow + axis * 0.07 + out * 0.055
		# leaf along the forearm, its flat face turned to `out`
		var b := Basis(out.cross(axis).normalized(), out, axis)
		xs.append(Transform3D(b.scaled_local(Vector3(0.17, 0.05, 0.27)), base + axis * 0.135))
	return cluster_mesh("thornling_bracer_gc_%s" % side, leaf_mesh(), xs)


## 5 raking spine thorns through the scales + one thorn on each shoulder (one mesh, model space).
static func _spine_mesh() -> Mesh:
	const KEY := "thornling_spine_gc"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var cone := thorn_cone()   # G-C: UV-tagged (dark root, pale bone point)
	var ys: Array[float] = [1.14, 1.03, 0.92, 0.81, 0.70]
	var zs: Array[float] = [-0.02, -0.12, -0.19, -0.23, -0.25]
	var hs: Array[float] = [0.42, 0.56, 0.50, 0.40, 0.28]
	var rs: Array[float] = [0.075, 0.09, 0.085, 0.075, 0.06]
	for i: int in 5:
		var dir := Vector3(0.10 * (1.0 if i % 2 == 0 else -1.0), 0.62 - 0.07 * i, -0.78).normalized()
		var b := Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(rs[i], hs[i], rs[i]))
		st.append_from(cone, 0, Transform3D(b, Vector3(0, ys[i], zs[i]) + dir * hs[i] * 0.45))
	for s: float in [-1.0, 1.0]:
		var dir := Vector3(0.75 * s, 0.62, -0.25).normalized()
		var b := Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(0.07, 0.36, 0.07))
		st.append_from(cone, 0, Transform3D(b, Vector3(0.22 * s, 1.08, 0.0) + dir * 0.16))
	return _cached(KEY, _indexed(st))


## Swept-back thorn crest (3 on the crown) + two ear thorns sideways-back (one mesh, model space).
static func _crest_mesh() -> Mesh:
	const KEY := "thornling_crest_gc"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var cone := thorn_cone()   # G-C: UV-tagged
	var defs: Array = [   # base, dir, length, radius
		[Vector3(0, 1.30, 0.34), Vector3(0, 0.55, -0.83), 0.40, 0.065],
		[Vector3(-0.07, 1.29, 0.27), Vector3(-0.25, 0.50, -0.83), 0.32, 0.055],
		[Vector3(0.07, 1.29, 0.27), Vector3(0.25, 0.50, -0.83), 0.32, 0.055],
		[Vector3(-0.17, 1.20, 0.22), Vector3(-0.85, 0.35, -0.40), 0.26, 0.05],
		[Vector3(0.17, 1.20, 0.22), Vector3(0.85, 0.35, -0.40), 0.26, 0.05],
	]
	for d: Array in defs:
		var dir := (d[1] as Vector3).normalized()
		var h: float = d[2]
		var r: float = d[3]
		var b := Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(r, h, r))
		st.append_from(cone, 0, Transform3D(b, (d[0] as Vector3) + dir * h * 0.45))
	return _cached(KEY, _indexed(st))


## Shoulder -> elbow (out and back a little) -> wrist (forward), one tapered limb in model space (no negative scale:
## the merge would flip the faces), side +1 right / -1 left.
static func _arm_mesh(side: float) -> Mesh:
	return tapered_path_mesh("thornling_arm_a22_%s" % side, PackedVector3Array([Vector3(0.30 * side, 1.04, 0.10),
		Vector3(0.40 * side, 0.80, 0.10), Vector3(0.40 * side, 0.57, 0.27)]), PackedFloat32Array([0.075, 0.06, 0.055]))


## Three long hooked claws from the knuckle (forward, then hooking down); local to the knuckle; side +1 / -1.
static func _claws_mesh(side: float) -> Mesh:
	var key := "thornling_claws_a22_%s" % side
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	var spread: Array[float] = [0.075, 0.0, -0.065]
	var scale: Array[float] = [0.85, 1.0, 0.8]
	for i: int in 3:
		var k: float = scale[i]
		var o := Vector3(spread[i] * side, 0.0, 0.0)
		var pts := PackedVector3Array([o, o + Vector3(0.015 * side, -0.06, 0.16) * k,
			o + Vector3(0.03 * side, -0.17, 0.29) * k, o + Vector3(0.025 * side, -0.33, 0.35) * k])
		var m := tapered_path_mesh("%s_%d" % [key, i], pts, PackedFloat32Array([0.045, 0.04, 0.026, 0.0]), 4)
		st.append_from(thorn_tagged("%s_%d_gc" % [key, i], m, pts[0], pts[3]), 0, Transform3D.IDENTITY)   # G-C: pale points
	return _cached(key, _indexed(st))


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"claw_frenzy":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, F_ARM_R) * DEG, 0, _kf(t, F_ARM_R) * -0.12 * DEG))
	rot(P_ARM_L, Vector3(_kf(t, F_ARM_L) * DEG, 0, _kf(t, F_ARM_L) * 0.12 * DEG))
	rot(P_CHEST, Vector3(_kf(t, F_CHEST_X) * DEG, _kf(t, F_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, F_ROOT_Y), _kf(t, F_ROOT_Z)))
	if _tier == 0:
		rot(P_HEAD, Vector3(_kf(t, F_HEAD_X) * DEG, 0, 0))
		rot(P_LEG_L, Vector3(_kf(t, F_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_kf(t, F_LEG_R) * DEG, 0, 0))
	if prev < 0.11 and t >= 0.11:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Scuttle: leaning into the run, hips twisting, claws swinging low and loose, head bobbing.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var ph: float = TAU * _walk_p
	var s: float = sin(ph)
	rot(P_ROOT, Vector3(9.0 * DEG * w, 0, 3.0 * DEG * s * w))
	if _tier > 0:
		return
	rot(P_HIPS, Vector3(0, 9.0 * DEG * s * w, 0))
	rot(P_CHEST, Vector3(0, -7.0 * DEG * s * w, 0))
	rot(P_ARM_L, Vector3(-10.0 * DEG * s * w, 0, 5.0 * DEG * absf(s) * w))
	rot(P_ARM_R, Vector3(-26.0 * DEG * s * w, 0, -5.0 * DEG * absf(s) * w))
	rot(P_HEAD, Vector3(-6.0 * DEG * absf(sin(ph + 0.4)) * w, 0, 0))


## Death: flung back by the blow, claws thrown up, then the kit's fall; the Nature layer adds the bloom and flash.
func _pose_death(dt: float) -> void:
	super(dt)
	var t: float = _death_t
	var fl: float = _k3(t, 0.0, 0.12, 0.3, 0.7, 1.0, 0.6)
	rot(P_ARM_L, Vector3(-80.0 * DEG * fl, 0, 25.0 * DEG * fl))
	rot(P_ARM_R, Vector3(-50.0 * DEG * fl, 0, -25.0 * DEG * fl))
	rot(P_HEAD, Vector3(-25.0 * DEG * _k3(t, 0.0, 0.1, 0.3, 0.6, 1.0, 0.5), 0, 0))
	pos(P_ROOT, Vector3(0, 0, -0.12 * _k3(t, 0.0, 0.12, 0.25, 0.5, 1.0, 1.0)))


## Fidget: raises both claw-hands and clacks them together twice, head cocked, then shakes them out.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.3, 1.0, 1.4, 1.0, 1.0)
	var clack: float = 0.0
	if t > 0.3 and t < 1.0:
		clack = absf(sin((t - 0.3) * TAU * 1.45))
	rot(P_ARM_R, Vector3(-62.0 * DEG * up, (-22.0 * clack) * DEG * up, 0))
	rot(P_ARM_L, Vector3(-62.0 * DEG * up, (22.0 * clack) * DEG * up, 0))
	rot(P_CHEST, Vector3(-8.0 * DEG * up, 0, 0))
	rot(P_HEAD, Vector3(-10.0 * DEG * up, 0, 16.0 * DEG * up))
	return 1.4
