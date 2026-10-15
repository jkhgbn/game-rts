extends ShadowModel
## Barrow Ghoul, Shadow T1 melee grave-eater (new-units-12.md 6; tiers wave, medium effort). Height 1.4 (hunched).
## Bone-white hide (the read on every ground), grey-lilac shins / hands / ribs, violet veins down the arms and the
## flanks, a spiked spine ridge over a big hump, a team-coloured torn shroud over the hump and the left shoulder
## (tatters hanging down the back) and a team loin rag. The silhouette hook: the hunch + very long arms whose big
## dark claws hang almost to the ground, the skull head thrust forward, the lower jaw hanging open.
## Glow point: the eyes (two violet sparks close together, one point at 40 m).
## Attack `ghoul_rake` (0.55 s, strike 0.14): lunge, a left then a right claw rake, the jaw snaps.
## play_cast(&"grave_feast") (1.6 s): the feeding lean: drops low over the kill, the head tears and the jaw chomps,
## the eyes flare, violet motes rise (the life it takes back). Death: ShadowModel's violet dissolve.
## Draws: merged pivots + Jaw + blob + hidden vet trim; 0 lights.

const ATTACK_LEN := 0.55
const STRIKE := 0.14
const FEAST_LEN := 1.6
const JAW_HINGE := Vector3(0.0, 1.135, 0.3)
const HAND := Vector3(0.3, 0.36, 0.3)
const VIOLET := Color(0.72, 0.34, 1.0)

var _jaw_node: Node3D
var _feast_fx: GPUParticles3D
var _jaw_v: float = -1.0
var _eyes_hot: bool = false
var _feast_fired: bool = false


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var bone := palette(&"shadow_bone")
	var grey := palette(&"shadow_skin")
	var claw := palette(&"shadow_obsidian")
	var vein := palette(&"shadow_sec_bolt")
	var cloth := palette(&"shadow_cloth")
	var cdark := palette(&"shadow_cloth_dark")
	# ---- Legs: crouched, knees forward, grey shins, long clawed feet.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _tube("bg_thigh_%s" % sx, PackedVector3Array([Vector3(0.12 * sx, 0.72, 0.0),
			Vector3(0.15 * sx, 0.44, 0.13)]), PackedFloat32Array([0.08, 0.06]), 6), bone, Vector3.ZERO)
		add_part(leg, _tube("bg_shin_%s" % sx, PackedVector3Array([Vector3(0.15 * sx, 0.44, 0.13),
			Vector3(0.14 * sx, 0.12, -0.02)]), PackedFloat32Array([0.055, 0.042]), 5), grey, Vector3.ZERO)
		add_part(leg, sphere(0.06, 6, 3), grey, Vector3(0.14 * sx, 0.05, 0.06), Vector3.ZERO, Vector3(1.0, 0.55, 2.0))
		for k: int in 3:
			var tx: float = 0.14 * sx + (float(k) - 1.0) * 0.035
			add_part(leg, cyl(0.0, 0.016, 0.08, 4), claw, Vector3(tx, 0.03, 0.17), Vector3(84, 0, 0))
	# ---- Hips: bony pelvis, team-dark loin rag with team tatters.
	add_part(hips, sphere(0.15, 6, 3), bone, Vector3(0, 0.75, -0.01), Vector3.ZERO, Vector3(1.15, 0.8, 0.9))
	add_part(hips, cyl(0.16, 0.21, 0.2, 8), cdark, Vector3(0, 0.66, 0.0))
	# G-C leftovers (2026-10-15): torn rags with ragged hems (bevelled plates) instead of flat boxes.
	add_part(hips, _gc("bg_gc_loin", func(st: SurfaceTool) -> void:
		_rag(st, 0.12, 0.26, Transform3D(Basis.from_euler(Vector3(-10, 0, 6) * DEG), Vector3(0.03, 0.52, 0.17)))
		_rag(st, 0.10, 0.20, Transform3D(Basis.from_euler(Vector3(-12, 180, 8) * DEG), Vector3(-0.07, 0.54, -0.17)))),
		cloth, Vector3.ZERO)
	# ---- Chest: forward-leaning torso, ribs, violet flank veins, the hump with a spiked spine ridge, the shroud.
	add_part(chest, _tube("bg_torso", PackedVector3Array([Vector3(0, 0.78, -0.02), Vector3(0, 0.98, 0.04),
		Vector3(0, 1.13, 0.18)]), PackedFloat32Array([0.15, 0.21, 0.17]), 8, false), bone, Vector3.ZERO)
	add_part(chest, sphere(0.2, 8, 4), bone, Vector3(0, 1.1, -0.02), Vector3(-20, 0, 0), Vector3(1.15, 0.95, 1.0))
	# ribs: thin bony arcs round the front of the chest (G-C leftovers: were full tori)
	add_part(chest, _gc("bg_gc_ribs", func(st: SurfaceTool) -> void:
		# (centre z, radius) follow the torso tube at each rib's height, so the ribs ride on the hide
		var ring: Array[Vector3] = [Vector3(0.016, 0.19, 0.185), Vector3(0.037, 0.212, 0.205), Vector3(0.096, 0.198, 0.192)]
		for k: int in 3:
			var c := Vector3(0, 0.9 + 0.07 * k, ring[k].x)
			var pts := ChampionShapes.arc(c, ring[k].y, ring[k].z, -1.75, 1.75, 6)
			for i: int in pts.size():
				var u: float = absf(float(i) / float(pts.size() - 1) - 0.5) * 2.0
				pts[i] += Vector3(0, -0.035 * u * u, 0)   # the rib ends sweep down round the flank
			ChampionShapes.tube(st, pts, PackedFloat32Array([0.009, 0.016, 0.019, 0.019, 0.016, 0.009]), 4, false)), grey,
		Vector3.ZERO)
	for s: float in [-1.0, 1.0]:
		add_part(chest, _tube("bg_vein_%s" % s, PackedVector3Array([Vector3(0.17 * s, 1.08, 0.06), Vector3(0.2 * s, 0.97, 0.03),
			Vector3(0.16 * s, 0.84, 0.02)]), PackedFloat32Array([0.018, 0.016, 0.01]), 4, false), vein, Vector3.ZERO)
	for k: int in 5:
		var u: float = float(k) / 4.0
		var p := Vector3(0, 0.98 + 0.3 * u - 0.1 * u * u, -0.17 + 0.22 * u)
		add_part(chest, cyl(0.0, 0.04, 0.13 - 0.015 * k, 5), grey, p + Vector3(0, 0.1, -0.05), Vector3(-40 + 15 * u, 0, 0))
	# shroud: a torn cap over the hump, tatters down the back, one flap over the left shoulder (the asymmetry).
	add_part(chest, sphere(0.19, 10, 3), cloth, Vector3(0.02, 1.12, -0.04), Vector3(-25, 0, 8), Vector3(1.2, 0.55, 1.1))
	add_part(chest, _gc("bg_gc_tatters_d", func(st: SurfaceTool) -> void:
		for k: int in [0, 2]:
			_rag(st, 0.1, 0.3 - 0.05 * k, Transform3D(Basis.from_euler(Vector3(-18, 180, 8 - 8 * k) * DEG),
				Vector3(-0.1 + 0.1 * k, 0.92 - 0.02 * k, -0.2)))
		_rag(st, 0.16, 0.26, Transform3D(Basis.from_euler(Vector3(-10, 10, -15) * DEG), Vector3(-0.25, 1.0, 0.1)))), cdark,
		Vector3.ZERO)
	add_part(chest, _gc("bg_gc_tatters_c", func(st: SurfaceTool) -> void:
		_rag(st, 0.1, 0.25, Transform3D(Basis.from_euler(Vector3(-18, 180, 0) * DEG), Vector3(0.0, 0.90, -0.2)))), cloth,
		Vector3.ZERO)
	# the shroud's cowl round the neck and shoulders (reads from the game camera above).
	add_part(chest, cyl(0.13, 0.27, 0.2, 8, false), cloth, Vector3(0, 1.13, 0.1), Vector3(38, 0, 0), Vector3(1.0, 1.0, 0.85))
	add_part(chest, torus(0.12, 0.16, 7), cdark, Vector3(0, 1.2, 0.16), Vector3(38, 0, 0))
	# ---- Head: skull thrust forward, heavy brow, deep sockets with violet eye sparks, swept-back ears, teeth.
	var hc := Vector3(0, 1.18, 0.31)
	add_part(head, sphere(0.12, 8, 4), bone, hc, Vector3(-10, 0, 0), Vector3(0.95, 0.85, 1.2))
	# Face (FaceKit, face rework 2026-09-28; were 2 dark sockets + 2 violet sparks): violet eyes glowing in black
	# sockets, brows that knit into a hungry glare on the rake; the hanging jaw
	# is its mouth (the kit's mouth hides under it). A bald skull (the ears are its own); two violet sparks sit in the
	# sockets (the glow point: the painted eyes under the brow do not reach the bloom from the RTS camera).
	var cv := FaceKit.canvas(hc, 0.13, sphere(0.12, 8, 4), Vector3(0.95, 0.85, 1.2), hc, Basis.from_euler(Vector3(-10, 0, 0) * DEG), 0.003)
	_face = FaceKit.attach(self, head, "barrow_ghoul", NatureFaces.style({
		"center": hc, "radius": 0.13, "head_mesh": sphere(0.12, 8, 4), "head_scale": Vector3(0.95, 0.85, 1.2), "head_at": hc,
		"preset": &"hollow", "skin": ShadowFaces.BONE, "hair": ShadowFaces.ASH, "eyes": ShadowFaces.GLOW, "detail": &"low",
		"x": NatureFaces.lean_x(1.15, {&"neutral": {"cut_in": 0.3, "open": 0.9}}),
		"palette": ShadowFaces.pal(ShadowFaces.BONE),
		"eye": {"c": Vector2(0.042, 0.020), "hw": 0.025, "top": 0.020, "bot": 0.015, "ir": 0.014, "pupil": 0.35},
		"brow": {"inner": Vector2(0.016, 0.046), "mid": Vector2(0.042, 0.052), "outer": Vector2(0.066, 0.044),
			"w": Vector3(0.007, 0.006, 0.003)},
		"mouth": NatureFaces.beast_mouth(Vector2(0, -0.10)),
		"hair_fn": func(acc: Dictionary) -> void:
			ShadowFaces.sparks(acc, cv, Vector2(0.042, 0.020), 0.03, 0.02),
	}, Vector3(-10, 0, 0), 0.003))
	# heavy brow ridge: an arched bony bar over the sockets (G-C leftovers: was a box)
	add_part(head, _gc("bg_gc_brow", func(st: SurfaceTool) -> void:
		ChampionShapes.tube(st, PackedVector3Array([Vector3(-0.105, 1.235, 0.36), Vector3(-0.05, 1.258, 0.405),
			Vector3(0.0, 1.252, 0.415), Vector3(0.05, 1.258, 0.405), Vector3(0.105, 1.235, 0.36)]),
			PackedFloat32Array([0.014, 0.024, 0.02, 0.024, 0.014]), 5, true, 0.8)), grey, Vector3.ZERO)
	add_part(head, cyl(0.035, 0.05, 0.1, 6), grey, Vector3(0, 1.14, 0.45), Vector3(95, 0, 0))
	for s: float in [-1.0, 1.0]:
		add_part(head, cyl(0.0, 0.045, 0.2, 5), bone, Vector3(0.1 * s, 1.23, 0.23), Vector3(-65, 0, -30 * s),
			Vector3(1.0, 1.0, 0.5))
	add_part(head, prism(Vector3(0.14, 0.05, 0.02)), bone, Vector3(0, 1.1, 0.46), Vector3(180, 0, 0))
	var trim := add_part(head, torus(0.11, 0.15, 7), palette(&"unit_gold_trim"), Vector3(0, 1.3, 0.3),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# lower jaw: its own node (hinge) so it can hang open and chomp.
	_jaw_node = Node3D.new()
	_jaw_node.name = "Jaw"
	_jaw_node.set_meta(&"keep_separate", true)
	_jaw_node.position = JAW_HINGE - model_origin(head)
	head.add_child(_jaw_node)
	add_part(_jaw_node, _jaw_mesh(), bone, JAW_HINGE, Vector3.ZERO, Vector3.ONE, true, "JawBone")
	# ---- Arms: very long, bone upper arm, grey forearm with a violet vein, big grey hands, four dark claws.
	for arm: Node3D in [arm_l, arm_r]:
		var sx: float = -1.0 if arm == arm_l else 1.0
		var h := HAND * Vector3(sx, 1, 1)
		add_part(arm, _tube("bg_upper_%s" % sx, PackedVector3Array([Vector3(0.23 * sx, 1.08, 0.12),
			Vector3(0.33 * sx, 0.8, 0.18)]), PackedFloat32Array([0.065, 0.05]), 6), bone, Vector3.ZERO)
		add_part(arm, _tube("bg_fore_%s" % sx, PackedVector3Array([Vector3(0.33 * sx, 0.8, 0.18),
			h + Vector3(0, 0.05, -0.02)]), PackedFloat32Array([0.05, 0.04]), 5), grey, Vector3.ZERO)
		add_part(arm, _tube("bg_armvein_%s" % sx, PackedVector3Array([Vector3(0.36 * sx, 0.98, 0.14),
			Vector3(0.37 * sx, 0.78, 0.2), Vector3(0.33 * sx, 0.5, 0.26)]), PackedFloat32Array([0.016, 0.014, 0.008]), 4,
			false), vein, Vector3.ZERO)
		add_part(arm, sphere(0.07, 6, 3), grey, h, Vector3.ZERO, Vector3(1.0, 0.8, 1.3))
		add_part(arm, _claws_mesh(sx), claw, Vector3.ZERO)
	# ---- Fx: feast motes (restarted by the cast), Shadow death motes, violet pool blob.
	_feast_fx = make_motes(VIOLET, 12, 0.9, 0.25, 1.2, 0.12, false, true)
	_feast_fx.name = "FeastMotes"
	_feast_fx.position = Vector3(0, 0.3, 0.55)
	$Fx.add_child(_feast_fx)
	var dm := make_motes(VIOLET, 12, 1.1, 0.25, 1.3, 0.12, true, true)
	dm.name = "DeathMotes"
	dm.set_meta(&"death_fx", true)
	dm.position = Vector3(0, 0.6, 0)
	$Fx.add_child(dm)
	ensure_shadow_blob(0.4, Color(0.1, 0.03, 0.16, 0.55))


# ================================================================ meshes (cached, model space)

static func _tube(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 5,
		caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	# G-C (docs/art/gc_shadow_units.md): one continuous smooth tube (shared rings, 2 more sides) instead of a stack of
	# 5-6 sided cylinders: rounder limbs for fewer vertices.
	var last := radii.size() - 1
	return _cached(key, ShadowGeo.tube(pts, radii, {"seg": seg + 2, "cap_start": caps and radii[0] > 0.0,
		"cap_end": caps and radii[last] > 0.0}))


## Four long hooked claws curling forward and down from the hand.
static func _claws_mesh(side: float) -> Mesh:
	var key := "bg_claws_%s" % side
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	var h := HAND * Vector3(side, 1, 1)
	for k: int in 4:
		var dx: float = (float(k) - 1.5) * 0.035
		var b := h + Vector3(dx, -0.02, 0.06)
		var m := _tube("bg_claw_%s_%d" % [side, k], PackedVector3Array([b, b + Vector3(dx * 0.4, -0.08, 0.08),
			b + Vector3(dx * 0.6, -0.17, 0.07)]), PackedFloat32Array([0.017, 0.012, 0.0]), 3)
		st.append_from(m, 0, Transform3D.IDENTITY)
	st.index()
	return _cached(key, st.commit())


## Lower jaw in the jaw node's frame (origin = the hinge): a narrow bony U-shaped jaw forward (bevelled plate, sloping
## down) with four pointed teeth along its front (G-C leftovers 2026-10-15: were a box and a prism).
static func _jaw_mesh() -> Mesh:
	return _gc("bg_jaw_v2", func(st: SurfaceTool) -> void:
		ChampionShapes.plate(st, PackedVector2Array([Vector2(-0.06, 0.08), Vector2(0.06, 0.08), Vector2(0.055, -0.03),
			Vector2(0.03, -0.08), Vector2(-0.03, -0.08), Vector2(-0.055, -0.03)]), 0.035, 0.01,
			Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-78.0)), Vector3(0, -0.03, 0.09)), true)
		for x: float in [-0.042, -0.015, 0.015, 0.042]:
			var b := Vector3(x, -0.03, 0.15 - absf(x) * 0.6)
			ChampionShapes.tube(st, PackedVector3Array([b, b + Vector3(-x * 0.1, 0.045 - absf(x) * 0.3, 0.004)]),
				PackedFloat32Array([0.009, 0.0]), 3, true))


## A cached mesh built by build(st) (ChampionShapes into one SurfaceTool, model space).
static func _gc(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := ChampionShapes.begin()
	build.call(st)
	return _cached(key, ChampionShapes.commit(st))


## A torn rag (w x h, centred, face +Z of xf): a straight top edge and a ragged hem (bevelled plate, both faces drawn).
static func _rag(st: SurfaceTool, w: float, h: float, xf: Transform3D) -> void:
	var o := PackedVector2Array()
	for p: Vector2 in [Vector2(-0.5, 0.5), Vector2(0.5, 0.5), Vector2(0.52, -0.22), Vector2(0.34, -0.5), Vector2(0.16, -0.3),
			Vector2(-0.04, -0.46), Vector2(-0.24, -0.28), Vector2(-0.46, -0.42)]:
		o.append(Vector2(p.x * w, p.y * h))
	ChampionShapes.plate(st, o, 0.02, 0.006, xf)


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"ghoul_rake":
		return super._pose_attack(prev, t)
	rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.07, 0.14, 0.4, 45.0, -110.0) * DEG, 0, _k3(t, 0.0, 0.07, 0.14, 0.4, -10.0, 20.0) * DEG))
	rot(P_ARM_R, Vector3(_k3(t, 0.08, 0.16, 0.24, 0.55, 45.0, -110.0) * DEG, 0, _k3(t, 0.08, 0.16, 0.24, 0.55, 10.0, -20.0) * DEG))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.07, 0.14, 0.5, -10.0, 16.0) * DEG, _k3(t, 0.0, 0.1, 0.24, 0.55, 18.0, -18.0) * DEG, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.07, 0.14, 0.5, -0.06, 0.03), _k3(t, 0.0, 0.07, 0.14, 0.5, -0.05, 0.28)))
	if _tier == 0:
		rot(P_HEAD, Vector3(_k3(t, 0.0, 0.07, 0.14, 0.5, -15.0, 10.0) * DEG, 0, 0))
		rot(P_LEG_L, Vector3(_k3(t, 0.0, 0.07, 0.14, 0.5, -10.0, -30.0) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_k3(t, 0.0, 0.07, 0.14, 0.5, 6.0, 20.0) * DEG, 0, 0))
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Grave Feast: the feeding lean over the kill.
func _pose_cast(_spell: StringName, t: float) -> float:
	var low: float = _k3(t, 0.0, 0.25, 1.35, FEAST_LEN, 1.0, 1.0)
	pos(P_ROOT, Vector3(0, -0.24 * low, 0.1 * low))
	rot(P_ROOT, Vector3(16.0 * DEG * low, 0, 0))
	rot(P_CHEST, Vector3(18.0 * DEG * low, 0, 0))
	rot(P_LEG_L, Vector3(-40.0 * DEG * low, 0, 0))
	rot(P_LEG_R, Vector3(-30.0 * DEG * low, 0, 0))
	var tear: float = sin(t * 14.0) * smoothstep(0.25, 0.4, t) * (1.0 - smoothstep(1.2, 1.35, t))
	rot(P_HEAD, Vector3((20.0 * low + 16.0 * tear) * DEG, 10.0 * DEG * tear, 0))
	rot(P_ARM_L, Vector3((-50.0 * low + 14.0 * tear) * DEG, 0, 14.0 * DEG * low))
	rot(P_ARM_R, Vector3((-50.0 * low - 14.0 * tear) * DEG, 0, -14.0 * DEG * low))
	if not _feast_fired and t >= 0.4:
		_feast_fired = true
		if _feast_fx and _tier < 2:
			_feast_fx.restart()
	return FEAST_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	if ev == &"cast_start":
		_feast_fired = false


## Lope: hunched and low, big arm swings (the claws brush the grass), the head bobbing forward.
func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_ARM_L, Vector3(-16.0 * DEG * s * w, 0, 0))
	rot(P_ARM_R, Vector3(26.0 * DEG * s * w, 0, 0))
	rot(P_CHEST, Vector3(8.0 * DEG * w, 0, 4.0 * DEG * s * w))
	pos(P_ROOT, Vector3(0, -0.03 * w, 0))
	if _tier == 0:
		rot(P_HEAD, Vector3(-8.0 * DEG * absf(s) * w, 0, 0))


func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	if _jaw_node == null:
		return
	# Jaw: hangs a little open, snaps on the rake, chomps while feeding, drops on death.
	var j: float = 12.0
	if _dead:
		j = 30.0
	elif _action == &"attack":
		j += _k3(_action_t, 0.0, 0.08, 0.14, 0.3, 26.0, -12.0)
	elif _action == &"cast":
		j += (14.0 + 14.0 * sin(_action_t * 14.0)) * smoothstep(0.2, 0.4, _action_t) * (1.0 - smoothstep(1.3, 1.5, _action_t))
	elif _tier == 0:
		j += 4.0 * sin(_t * 2.3)
	j = snappedf(j, 1.0)
	if j != _jaw_v and _tier < 2:
		_jaw_v = j
		_jaw_node.rotation.x = j * DEG
	# Eyes flare while feeding and raking.
	if not _dead and (_action == &"cast" or _action == &"attack"):
		var k: float
		if _action == &"cast":
			k = _k3(_action_t, 0.0, 0.3, 1.3, FEAST_LEN, 2.0, 2.0)
		else:
			k = _k3(_action_t, 0.0, 0.08, 0.16, ATTACK_LEN, 0.8, 1.0)
		for gi: GeometryInstance3D in _glow_nodes:
			gi.set_instance_shader_parameter(&"glow_boost", glow_level() * (1.0 + k))
		_eyes_hot = true
	elif _eyes_hot:
		_eyes_hot = false
		_apply_glow(true)


func _on_revive() -> void:
	super._on_revive()
	_jaw_v = -1.0
	_eyes_hot = false
