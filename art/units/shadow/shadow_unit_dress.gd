class_name ShadowUnitDress
extends RefCounted
## G-C Shadow units pass (docs/art/gc_shadow_units.md): reshapes the generated Hall units + Gloom Thrall
## (_build_shadow.gd scenes) at _build_parts time, before the kit merge. The blocky primitives (box feet, capsule legs,
## plain cylinders and cones) are dropped and replaced by shaped ShadowGeo meshes: tapered legs with pointed curled
## boots, tattered layered robes in team cloth, swept hoods, domed spiked pauldrons, curved bone horns, bevelled
## sickle blades, a greatsword with a swept guard, a hound with ribs, claws, fangs and a vertebra tail.
## Contract: every pivot, named node (Cape, Bolt, LanternOrb, Lantern, Heart, Fuller, Jaw, Tail, Crystals, GoldTrim,
## Fx emitters), attachment point, glow node and face canvas stays; the new static parts merge into the existing pivot
## meshes (no new draw instance); materials are the kit's Shadow palette (team colour, hit flash, kit_detail unchanged).
## Static parts are built once per unit type (the kit caches the merge; later instances skip all of it). The few
## keep_separate parts that are reshaped (thrall lantern cage, hound jaw and tail) swap their mesh on every instance
## from a static cache (shared, B9-clean).

static var _sep_cache: Dictionary = {}   # key -> Mesh (keep_separate swaps, shared by every instance)
## Off = the pre-G-C look (shot / lab before-after in one process; set it before the first Shadow unit spawns).
static var enabled: bool = true


static func apply(m: ShadowModel) -> void:
	if not enabled:
		return
	var build := not m.is_type_merged()
	# By scene, not unit_kind (Hollow Oathsworn and stage-set puppets reuse the knight / shade kinds with other parts).
	match m.scene_file_path.get_file():
		"gloom_thrall.tscn":
			if build:
				_thrall(m)
			_swap(m, "Root/Chest/ArmR/Lantern/MeshInstance3D", "thrall_cage", _thrall_cage)
		"shade.tscn":
			if build:
				_shade(m)
			_swap(m, "Root/Chest/Cape", "shade_cape", func(_xf: Transform3D) -> Mesh:
				return ShadowGeo.cloth(0.40, 0.54, 0.85, 4, 6, 0.06, 0.13, 21))
		"nightbolt.tscn":
			if build:
				_nightbolt(m)
		"grave_hound.tscn":
			if build:
				_hound(m)
			_swap(m, "Root/Mount/Head/Jaw/MeshInstance3D", "hound_jaw", _hound_jaw)
			_swap(m, "Root/Mount/Tail/MeshInstance3D", "hound_tail", _hound_tail)
		"shadow_knight.tscn":
			if build:
				_knight(m)
			_swap(m, "Root/Chest/Cape", "knight_cape", func(_xf: Transform3D) -> Mesh:
				return ShadowGeo.cloth(0.86, 1.10, 1.85, 6, 8, 0.10, 0.14, 17))


## High+ soul wisps (ShadowModel decides the tier): violet motes trailing off the knight's greatsword, rising from the
## thrall's lantern. Shared process / draw resources (CharacterModel.make_motes); a child of the model, so the fog of
## war hides them with the unit. Null for the other scenes.
static func add_wisps(m: ShadowModel) -> GPUParticles3D:
	if not enabled:
		return null
	var parent: Node3D
	var at := Vector3.ZERO
	var p: GPUParticles3D
	match m.scene_file_path.get_file():
		"shadow_knight.tscn":
			parent = m.get_node_or_null("Root/Chest/ArmR") as Node3D
			at = Vector3(0.42, 1.40, 0.40) + Vector3(0.08, 0.81, -0.58).normalized() * 1.25
			p = CharacterModel.make_motes(Color(0.70, 0.36, 1.0), 10, 1.3, 0.16, 0.3, 0.085)
		"gloom_thrall.tscn":
			parent = m.get_node_or_null("Root/Chest/ArmR/Lantern") as Node3D
			at = Vector3(0.60, 2.02 - 0.25, 0.36)
			p = CharacterModel.make_motes(Color(0.72, 0.40, 1.0), 6, 1.6, 0.09, 0.28, 0.065)
	if parent == null or p == null:
		if p:
			p.free()
		return null
	p.name = "SoulWisps"
	p.position = at - m.model_origin(parent)
	parent.add_child(p)
	return p


# ================================================================ helpers

static func _drop(m: Node, paths: Array) -> void:
	for p: String in paths:
		var n := m.get_node_or_null(p)
		if n is MeshInstance3D and n.get_child_count() == 0:
			n.get_parent().remove_child(n)
			n.free()


## A static part at model-space `pos` (meshes built in model space use pos ZERO).
static func _add(m: CharacterModel, piv: String, mesh: Mesh, mat: StringName, pos: Vector3 = Vector3.ZERO,
		rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> void:
	var p := m.get_node_or_null(piv) as Node3D
	if p == null or mesh == null:
		return
	m.add_part(p, mesh, CharacterModel.palette(mat), pos, rot, scl)


## Swaps the mesh of a keep_separate part (its node, transform and material stay). `build` gets the node's model
## transform and returns the mesh in the node's local frame; cached per key.
static func _swap(m: Node3D, path: String, key: String, build: Callable) -> void:
	var mi := m.get_node_or_null(path) as MeshInstance3D
	if mi == null:
		return
	if not _sep_cache.has(key):
		_sep_cache[key] = build.call(_model_xf(m, mi))
	var mesh: Mesh = _sep_cache[key]
	if mesh != null:
		mi.mesh = mesh


static func _model_xf(m: Node, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var c: Node = n
	while c and c != m:
		xf = (c as Node3D).transform * xf
		c = c.get_parent()
	return xf


## Model-space points -> a node's local frame.
static func _local(xf: Transform3D, pts: PackedVector3Array) -> PackedVector3Array:
	var inv := xf.affine_inverse()
	var out := PackedVector3Array()
	for p: Vector3 in pts:
		out.append(inv * p)
	return out


static func _pts(a: Array) -> PackedVector3Array:
	return PackedVector3Array(a)


static func _rad(a: Array) -> PackedFloat32Array:
	return PackedFloat32Array(a)


## A tapered biped leg (thigh, knee, calf, ankle) around x = 0, from the hip `top` down to the ankle.
static func _leg_mesh(r: float, top: float, ankle: float) -> ArrayMesh:
	var l := top - ankle
	var knee := ankle + l * 0.46
	return ShadowGeo.lathe([
		Vector3(r * 0.55, top + 0.03, 0.0), Vector3(r * 1.02, top - 0.02, 0.0), Vector3(r * 1.10, top - l * 0.24, 0.006),
		Vector3(r * 0.92, knee + l * 0.08, 0.016), Vector3(r * 0.80, knee, 0.022), Vector3(r * 0.94, knee - l * 0.15, -0.004),
		Vector3(r * 0.74, ankle + l * 0.16, 0.0), Vector3(r * 0.60, ankle, 0.0)], 8, {"cap_bot": true})


## A pointed boot along +Z (heel at z -0.07 x s), the toe curling up by `curl`, with a spiky folded cuff at the ankle.
static func _boot_mesh(s: float, curl: float, cuff_r: float, cuff_y: float) -> ArrayMesh:
	var boot := ShadowGeo.tube(_pts([Vector3(0, 0.072 * s, -0.075 * s), Vector3(0, 0.07 * s, 0.02 * s),
		Vector3(0, 0.056 * s, 0.12 * s), Vector3(0, 0.06 * s + curl * 0.3, 0.20 * s), Vector3(0, 0.07 * s + curl, 0.27 * s)]),
		_rad([0.072 * s, 0.078 * s, 0.062 * s, 0.036 * s, 0.0]), {"seg": 7, "ell": Vector2(0.72, 1.0), "cap_start": true})
	var cuff := ShadowGeo.lathe([Vector3(cuff_r * 1.12, cuff_y + 0.07 * s, 0.0), Vector3(cuff_r * 1.0, cuff_y + 0.01, 0.0),
		Vector3(cuff_r * 0.92, cuff_y - 0.05 * s, 0.0)], 8, {"jag": -0.045 * s, "jag_ring": 0, "jag_seed": 4})
	return ShadowGeo.combine([[boot], [cuff]])


static func _biped_legs(m: CharacterModel, hip: float, lx: float, r: float, fs: float, mat: StringName,
		boot_mat: StringName, curl: float) -> void:
	_drop(m, ["Root/Hips/LegL/MeshInstance3D", "Root/Hips/LegL/MeshInstance3D2", "Root/Hips/LegR/MeshInstance3D",
		"Root/Hips/LegR/MeshInstance3D2"])
	var leg := _leg_mesh(r, hip, 0.13 * fs)
	var boot := _boot_mesh(fs, curl, r * 0.78, 0.15 * fs)
	for s: float in [-1.0, 1.0]:
		var pv := "Root/Hips/LegR" if s > 0.0 else "Root/Hips/LegL"
		_add(m, pv, leg, mat, Vector3(lx * s, 0, 0))
		_add(m, pv, boot, boot_mat, Vector3(lx * s, 0, 0.02 * fs))


## A curved spike / horn from a to c bending through b (radius r at the base, a point at the tip).
static func _horn(a: Vector3, b: Vector3, c: Vector3, r: float, n: int = 5, seg: int = 6) -> ArrayMesh:
	return ShadowGeo.tube(ShadowGeo.bez(a, b, c, n), ShadowGeo.taper(r, 0.0, n + 1, 0.8), {"seg": seg})


## A domed plate (pauldron, knee cop) around +Y: radius r, height h, closed underneath.
static func _dome(r: float, h: float, sz: float = 1.0) -> ArrayMesh:
	return ShadowGeo.lathe([Vector3(0.0, h, 0), Vector3(r * 0.45, h * 0.93, 0), Vector3(r * 0.78, h * 0.68, 0),
		Vector3(r * 0.96, h * 0.30, 0), Vector3(r, 0.0, 0), Vector3(r * 0.97, -h * 0.18, 0)], 10,
		{"sz": sz, "cap_bot": true})


## A sleeve / bracer tube along an arm (shoulder s -> hand h), from t0 to t1 of its length.
static func _bracer(s: Vector3, h: Vector3, t0: float, t1: float, r0: float, r1: float) -> ArrayMesh:
	return ShadowGeo.tube(_pts([s.lerp(h, t0), s.lerp(h, (t0 + t1) * 0.5), s.lerp(h, t1)]), _rad([r0, (r0 + r1) * 0.5, r1]),
		{"seg": 8, "cap_start": true, "cap_end": true})


## Replaces a box gauntlet (`drop`) with a flared cuff + rounded fist along the arm (shoulder s -> hand h).
static func _fist(m: CharacterModel, pv: String, drop: String, s: Vector3, h: Vector3, r: float, mat: StringName,
		knuckles: StringName = &"") -> void:
	_drop(m, [pv + "/" + drop])
	var d := (h - s).normalized()
	_add(m, pv, ShadowGeo.tube(_pts([h - d * r * 1.35, h - d * r * 0.55, h + d * r * 0.1, h + d * r * 0.55, h + d * r * 0.82]),
		_rad([r * 1.12, r * 1.0, r * 0.95, r * 0.7, 0.0]), {"seg": 8, "cap_start": true}), mat)
	if knuckles != &"":
		var side := d.cross(Vector3.UP).normalized()
		for k: int in 3:
			var p := h + d * r * 0.3 + side * (float(k) - 1.0) * r * 0.5 + Vector3.UP * r * 0.55
			_add(m, pv, _horn(p, p + Vector3.UP * r * 0.2, p + Vector3.UP * r * 0.32 + d * r * 0.25, r * 0.16, 2, 4), knuckles)


# ================================================================ 5.1 Gloom Thrall (worker, 1.4 m)

static func _thrall(m: ShadowModel) -> void:
	_biped_legs(m, 0.43, 0.14, 0.085, 0.9, &"shadow_leather", &"shadow_leather", 0.02)
	_drop(m, ["Root/Chest/MeshInstance3D", "Root/Chest/MeshInstance3D2", "Root/Chest/MeshInstance3D3",
		"Root/Chest/Head/MeshInstance3D3", "Root/Chest/ArmR/MeshInstance3D3"])
	# Hunched drudge robe (pale grey-violet), leaning forward over the knees, a tattered hem; a longer team-dark
	# under-robe shows between the tatters.
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.14, 1.00, 0.11), Vector3(0.21, 0.93, 0.10), Vector3(0.27, 0.79, 0.08),
		Vector3(0.32, 0.63, 0.05), Vector3(0.36, 0.47, 0.02), Vector3(0.385, 0.36, 0.0)], 14,
		{"sz": 0.92, "jag": 0.075, "jag_seed": 1, "cap_top": true}), &"shadow_sec_worker")
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.30, 0.62, 0.03), Vector3(0.37, 0.43, 0.0), Vector3(0.41, 0.27, -0.01)],
		12, {"sz": 0.92, "jag": 0.07, "jag_seed": 3}), &"shadow_cloth_dark")
	# Team mantle draped over the hump, ragged edge.
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.10, 1.10, 0.05), Vector3(0.17, 1.04, 0.04), Vector3(0.28, 0.95, 0.01),
		Vector3(0.355, 0.85, -0.03), Vector3(0.38, 0.76, -0.06)], 14, {"sz": 0.95, "jag": 0.07, "jag_seed": 5,
		"cap_top": true}), &"shadow_cloth")
	# Rope belt + a leather satchel on the right hip.
	_add(m, "Root/Chest", CharacterModel.torus(0.305, 0.345, 14), &"shadow_leather", Vector3(0, 0.64, 0.05),
		Vector3(6, 0, 0), Vector3(1.0, 1.0, 0.92))
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.0, 0.09, 0), Vector3(0.06, 0.08, 0), Vector3(0.085, 0.02, 0),
		Vector3(0.08, -0.05, 0), Vector3(0.0, -0.08, 0)], 8, {"sz": 0.55}), &"shadow_leather", Vector3(0.31, 0.55, 0.12),
		Vector3(0, -30, 8))
	# Deep cowl: a dark rim frames the face, the hood tail droops down the back.
	_add(m, "Root/Chest/Head", CharacterModel.torus(0.115, 0.165, 14), &"shadow_cloth_dark", Vector3(0, 1.06, 0.33),
		Vector3(90, 0, 0), Vector3(1.0, 1.0, 1.15))
	_add(m, "Root/Chest/Head", ShadowGeo.tube(_pts([Vector3(0, 1.24, 0.04), Vector3(0, 1.25, -0.16), Vector3(0, 1.17, -0.33),
		Vector3(0, 1.03, -0.42), Vector3(0, 0.90, -0.43)]), _rad([0.13, 0.11, 0.075, 0.04, 0.0]), {"seg": 8}),
		&"shadow_cloth")
	# Bell sleeves.
	_add(m, "Root/Chest/ArmL", _bracer(Vector3(-0.30, 0.92, 0.06), Vector3(-0.28, 0.62, 0.24), 0.45, 0.86, 0.088, 0.125),
		&"shadow_sec_worker")
	_add(m, "Root/Chest/ArmR", _bracer(Vector3(0.30, 0.92, 0.06), Vector3(0.36, 0.74, 0.22), 0.40, 0.84, 0.088, 0.125),
		&"shadow_sec_worker")
	_fist(m, "Root/Chest/ArmR", "MeshInstance3D2", Vector3(0.30, 0.92, 0.06), Vector3(0.36, 0.74, 0.22), 0.10, &"shadow_skin")
	# Crooked iron lantern pole with a crook over the lantern, a bone charm and two team rags.
	var hand := Vector3(0.36, 0.74, 0.22)
	var tip := Vector3(0.60, 2.02, 0.36)
	var d := (tip - hand).normalized()
	_add(m, "Root/Chest/ArmR", ShadowGeo.tube(_pts([hand - d * 0.30, hand + d * 0.40 + Vector3(0.02, 0, -0.015),
		tip - d * 0.40 + Vector3(-0.02, 0, 0.01), tip + Vector3(0, 0.04, 0), tip + Vector3(-0.01, 0.13, 0.05),
		tip + Vector3(-0.01, 0.12, 0.13), tip + Vector3(-0.01, 0.05, 0.16)]),
		_rad([0.036, 0.034, 0.032, 0.03, 0.026, 0.02, 0.0]), {"seg": 6, "cap_start": true}), &"shadow_iron")
	var charm := tip - d * 0.36
	_add(m, "Root/Chest/ArmR", CharacterModel.sphere(0.05, 8, 4), &"shadow_bone", charm + Vector3(0.05, -0.09, 0.0),
		Vector3.ZERO, Vector3(1.0, 1.15, 0.9))
	for k: int in 2:
		var a := charm + Vector3(-0.03 + 0.05 * k, 0.0, 0.03 - 0.06 * k)
		_add(m, "Root/Chest/ArmR", ShadowGeo.tube(_pts([a, a + Vector3(0.02, -0.12, -0.03), a + Vector3(0.0, -0.24, -0.07)]),
			_rad([0.035, 0.03, 0.0]), {"seg": 4, "ell": Vector2(0.25, 1.0)}), &"shadow_cloth")


## The lantern: a pagoda roof with a finial, four bars round the orb and a bottom cup (one mesh, the cap node's own
## frame: the cap sits 0.08 m under the pole tip, unrotated; the orb's centre is 0.17 m under it).
static func _thrall_cage(_xf: Transform3D) -> Mesh:
	var items: Array = []
	items.append([ShadowGeo.lathe([Vector3(0.0, 0.13, 0), Vector3(0.02, 0.10, 0), Vector3(0.06, 0.05, 0),
		Vector3(0.145, 0.0, 0), Vector3(0.158, -0.025, 0), Vector3(0.11, -0.01, 0)], 8, {"jag": -0.03, "jag_ring": 4,
		"jag_seed": 6}), Transform3D.IDENTITY])
	for k: int in 4:
		var a: float = TAU * (float(k) + 0.5) / 4.0
		var p0 := Vector3(sin(a) * 0.14, -0.02, cos(a) * 0.14)
		var p1 := Vector3(sin(a) * 0.15, -0.17, cos(a) * 0.15)
		var p2 := Vector3(sin(a) * 0.10, -0.33, cos(a) * 0.10)
		items.append([ShadowGeo.tube(_pts([p0, p1, p2]), _rad([0.014, 0.014, 0.012]), {"seg": 4}), Transform3D.IDENTITY])
	items.append([ShadowGeo.lathe([Vector3(0.11, -0.31, 0), Vector3(0.08, -0.36, 0), Vector3(0.0, -0.42, 0)], 8,
		{"cap_top": true}), Transform3D.IDENTITY])
	return ShadowGeo.combine(items)


# ================================================================ 5.2 Shade (melee, 1.6 m)

static func _shade(m: ShadowModel) -> void:
	_biped_legs(m, 0.60, 0.17, 0.10, 1.0, &"shadow_leather", &"shadow_leather", 0.05)
	_drop(m, ["Root/Hips/MeshInstance3D", "Root/Chest/MeshInstance3D", "Root/Chest/MeshInstance3D4",
		"Root/Chest/MeshInstance3D5", "Root/Chest/Head/MeshInstance3D2", "Root/Chest/ArmL/MeshInstance3D3",
		"Root/Chest/ArmL/MeshInstance3D4", "Root/Chest/ArmR/MeshInstance3D3", "Root/Chest/ArmR/MeshInstance3D4",
		"Root/Chest/ArmR/MeshInstance3D5"])
	# Tattered war-skirt (team dark) under a lean V torso (team cloth).
	_add(m, "Root/Hips", ShadowGeo.lathe([Vector3(0.19, 0.84, 0.0), Vector3(0.245, 0.72, 0.0), Vector3(0.295, 0.58, -0.01),
		Vector3(0.33, 0.45, -0.02)], 12, {"sz": 0.85, "jag": 0.12, "jag_seed": 2, "cap_top": true}), &"shadow_cloth_dark")
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.14, 1.31, 0.0), Vector3(0.28, 1.26, 0.0), Vector3(0.31, 1.15, 0.0),
		Vector3(0.27, 1.02, 0.01), Vector3(0.205, 0.87, 0.0), Vector3(0.19, 0.72, 0.0)], 12,
		{"sz": 0.78, "cap_top": true, "cap_bot": true}), &"shadow_cloth")
	# Domed obsidian pauldrons, two curved silver spikes each, raked out and back.
	var dome := _dome(0.14, 0.11, 0.9)
	for s: float in [-1.0, 1.0]:
		_add(m, "Root/Chest", dome, &"shadow_obsidian", Vector3(0.355 * s, 1.235, -0.01), Vector3(0, 0, -24.0 * s))
		var b1 := Vector3(0.40 * s, 1.31, -0.03)
		_add(m, "Root/Chest", _horn(b1, b1 + Vector3(0.14 * s, 0.06, 0.0), b1 + Vector3(0.24 * s, 0.24, -0.10), 0.045),
			&"shadow_silver")
		var b2 := Vector3(0.31 * s, 1.33, 0.04)
		_add(m, "Root/Chest", _horn(b2, b2 + Vector3(0.06 * s, 0.07, 0.0), b2 + Vector3(0.12 * s, 0.18, -0.06), 0.03, 4, 5),
			&"shadow_silver")
	# Swept hood (team cloth: the biggest mass seen from the game camera; it was dark), the point streams back.
	_add(m, "Root/Chest/Head", ShadowGeo.lathe([Vector3(0.0, 1.76, -0.50), Vector3(0.06, 1.725, -0.37),
		Vector3(0.13, 1.67, -0.22), Vector3(0.195, 1.60, -0.115), Vector3(0.235, 1.51, -0.07), Vector3(0.245, 1.41, -0.06),
		Vector3(0.235, 1.31, -0.05)], 12, {"sz": 1.04}), &"shadow_cloth")
	# The hood opening: a dark rolled rim round the face (the gaunt face and glowing eyes read inside it).
	_add(m, "Root/Chest/Head", CharacterModel.torus(0.125, 0.175, 14), &"shadow_cloth_dark", Vector3(0, 1.425, 0.175),
		Vector3(90, 0, 0), Vector3(1.0, 1.0, 1.2))
	# Leather bracers.
	for s: float in [-1.0, 1.0]:
		var pv := "Root/Chest/ArmR" if s > 0.0 else "Root/Chest/ArmL"
		_add(m, pv, _bracer(Vector3(0.36 * s, 1.20, 0.0), Vector3(0.47 * s, 0.80, 0.10), 0.52, 0.80, 0.098, 0.108),
			&"shadow_leather")
	_fist(m, "Root/Chest/ArmR", "MeshInstance3D2", Vector3(0.36, 1.20, 0.0), Vector3(0.47, 0.80, 0.10), 0.11, &"shadow_silver")
	# Reverse-grip sickle blades (bevelled, single-edged), the right one with a soul-fire back edge.
	for s: float in [-1.0, 1.0]:
		var pv := "Root/Chest/ArmR" if s > 0.0 else "Root/Chest/ArmL"
		var h := Vector3(0.47 * s, 0.80, 0.10)
		var d1 := Vector3(0.22 * s, -0.72, -0.66).normalized()
		var d2 := Vector3(0.10 * s, -0.97, -0.20).normalized()
		var a := h + d1 * 0.07
		var b := a + d1 * 0.42
		var c := b + d2 * 0.40
		var out := Vector3(s, 0, 0)
		var edge := (b - a).cross(out).normalized()
		var spine := _pts([a, a + d1 * 0.21, b, b.lerp(c, 0.5) + edge * 0.035, c + edge * 0.075])
		_add(m, pv, ShadowGeo.blade(spine, _rad([0.065, 0.08, 0.08, 0.062, 0.0]), edge, out, 0.022, 0.32), &"shadow_silver")
		# A small crescent guard over the knuckles.
		_add(m, pv, _horn(a - edge * 0.05 - d1 * 0.02, a + edge * 0.04 - d1 * 0.06, a + edge * 0.11 - d1 * 0.01, 0.022, 4, 5),
			&"shadow_silver")
		if s > 0.0:
			var back := _pts([a - edge * 0.035 + d1 * 0.03, a + d1 * 0.21 - edge * 0.035, b - edge * 0.033,
				b.lerp(c, 0.5) + edge * 0.035 - edge * 0.026])
			_add(m, pv, ShadowGeo.tube(back, _rad([0.012, 0.016, 0.015, 0.0]), {"seg": 4}), &"shadow_glow")


# ================================================================ 5.3 Nightbolt (ranged, 1.6 m)

static func _nightbolt(m: ShadowModel) -> void:
	_biped_legs(m, 0.55, 0.15, 0.10, 1.0, &"shadow_leather", &"shadow_leather", 0.03)
	_drop(m, ["Root/Chest/MeshInstance3D2", "Root/Chest/MeshInstance3D3", "Root/Chest/MeshInstance3D4",
		"Root/Chest/Head/MeshInstance3D2", "Root/Chest/Head/MeshInstance3D3", "Root/Chest/ArmR/MeshInstance3D3",
		"Root/Chest/ArmR/MeshInstance3D4", "Root/Chest/ArmR/MeshInstance3D5", "Root/Chest/ArmR/MeshInstance3D6",
		"Root/Chest/ArmR/MeshInstance3D7"])
	# Long tattered coat (team dark), the tails longer at the back; a ragged team shoulder mantle.
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.245, 0.84, 0.0), Vector3(0.285, 0.72, -0.01), Vector3(0.335, 0.53, -0.03),
		Vector3(0.375, 0.35, -0.05), Vector3(0.395, 0.25, -0.065)], 14, {"sx": 0.95, "sz": 0.9, "jag": 0.10,
		"jag_seed": 7}), &"shadow_cloth_dark")
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.14, 1.31, 0.0), Vector3(0.24, 1.26, 0.0), Vector3(0.355, 1.14, -0.01),
		Vector3(0.395, 1.03, -0.02)], 14, {"sz": 0.9, "jag": 0.07, "jag_seed": 9, "cap_top": true}), &"shadow_cloth")
	# Round leather quiver (the glowing fletchings stay on top).
	_add(m, "Root/Chest", ShadowGeo.tube(_pts([Vector3(-0.114, 0.80, -0.30), Vector3(-0.17, 1.02, -0.30),
		Vector3(-0.226, 1.245, -0.30)]), _rad([0.065, 0.078, 0.085]), {"seg": 8, "cap_start": true, "cap_end": true}),
		&"shadow_leather")
	_add(m, "Root/Chest", CharacterModel.torus(0.075, 0.1, 10), &"shadow_silver", Vector3(-0.21, 1.18, -0.30),
		Vector3(0, 0, 14))
	# Wide drooping brim (team) with a tattered edge, a bent pointed crown (light violet); the glowing band stays.
	var brim := ShadowGeo.lathe([Vector3(0.20, 0.03, 0), Vector3(0.33, 0.016, 0), Vector3(0.45, -0.008, 0),
		Vector3(0.525, -0.048, 0), Vector3(0.55, -0.078, 0), Vector3(0.50, -0.06, 0), Vector3(0.36, -0.024, 0),
		Vector3(0.20, -0.008, 0)], 16, {"jag": 0.028, "jag_ring": 4, "jag_seed": 11})
	_add(m, "Root/Chest/Head", brim, &"shadow_cloth", Vector3(0, 1.585, -0.01), Vector3(-7, 0, 0))
	_add(m, "Root/Chest/Head", ShadowGeo.tube(_pts([Vector3(0, 0.0, 0), Vector3(0, 0.12, -0.01), Vector3(0, 0.24, -0.045),
		Vector3(0, 0.33, -0.11), Vector3(0, 0.37, -0.22)]), _rad([0.215, 0.175, 0.115, 0.055, 0.0]),
		{"seg": 10, "cap_start": true}), &"shadow_sec_bolt", Vector3(0, 1.595, -0.02), Vector3(-10, 0, 0))
	_fist(m, "Root/Chest/ArmR", "MeshInstance3D2", Vector3(0.34, 1.14, 0.0), Vector3(0.24, 0.98, 0.26), 0.11, &"shadow_silver")
	# Crossbow: a tapered iron stock, a bone prod mount, recurved silver limbs with barbed tips and a string.
	var c := Vector3(0.15, 1.04, 0.36)
	_add(m, "Root/Chest/ArmR", ShadowGeo.tube(_pts([c + Vector3(0, -0.05, -0.41), c + Vector3(0, -0.02, -0.24),
		c + Vector3(0, 0.0, 0.05), c + Vector3(0, 0.01, 0.32), c + Vector3(0, 0.01, 0.38)]),
		_rad([0.072, 0.058, 0.055, 0.05, 0.04]), {"seg": 6, "ell": Vector2(1.0, 0.8), "cap_start": true, "cap_end": true}),
		&"shadow_iron")
	_add(m, "Root/Chest/ArmR", CharacterModel.sphere(0.07, 8, 4), &"shadow_bone", c + Vector3(0, 0.03, 0.33),
		Vector3.ZERO, Vector3(1.1, 0.9, 1.0))
	var tips: Array[Vector3] = []
	for s: float in [-1.0, 1.0]:
		var root := c + Vector3(0.05 * s, 0.03, 0.34)
		var end := c + Vector3(0.49 * s, 0.03, 0.20)
		var limb := ShadowGeo.bez(root, root + Vector3(0.27 * s, 0.0, 0.12), end, 5)
		limb.append(end + Vector3(0.04 * s, 0.0, -0.07))
		_add(m, "Root/Chest/ArmR", ShadowGeo.tube(limb, _rad([0.05, 0.046, 0.04, 0.034, 0.028, 0.022, 0.016]),
			{"seg": 6, "ell": Vector2(0.7, 1.0), "cap_start": true, "cap_end": true}), &"shadow_silver")
		var t := end + Vector3(0.04 * s, 0.0, -0.07)
		tips.append(t)
		_add(m, "Root/Chest/ArmR", _horn(t, t + Vector3(0.03 * s, 0.0, -0.05), t + Vector3(0.02 * s, 0.03, -0.17), 0.03, 3, 5),
			&"shadow_silver")
	_add(m, "Root/Chest/ArmR", ShadowGeo.tube(_pts([tips[0], c + Vector3(0, 0.06, 0.02), tips[1]]), _rad([0.008, 0.008, 0.008]),
		{"seg": 3}), &"shadow_bone")


# ================================================================ 5.4 Grave Hound (quadruped, 1.0 m)

static func _hound(m: ShadowModel) -> void:
	_drop(m, ["Root/Mount/LegFL/MeshInstance3D", "Root/Mount/LegFR/MeshInstance3D", "Root/Mount/LegBL/MeshInstance3D",
		"Root/Mount/LegBR/MeshInstance3D", "Root/Mount/Body/MeshInstance3D6", "Root/Mount/Body/MeshInstance3D7",
		"Root/Mount/Body/MeshInstance3D8", "Root/Mount/Head/MeshInstance3D2", "Root/Mount/Head/MeshInstance3D3"])
	# Gaunt digitigrade legs (shadow flesh) with bone claws.
	for l: Array in [["LegFL", -0.17, 0.30], ["LegFR", 0.17, 0.30], ["LegBL", -0.15, -0.42], ["LegBR", 0.15, -0.42]]:
		var t := Vector3(float(l[1]), 0.54, float(l[2]))
		var pv := "Root/Mount/" + String(l[0])
		var front: bool = t.z > 0.0
		var paw := Vector3(t.x * 1.1, 0.045, t.z + (0.08 if front else 0.12))
		var pts: PackedVector3Array
		var rad: PackedFloat32Array
		if front:
			pts = _pts([t + Vector3(0, 0.06, 0), t + Vector3(t.x * 0.04, -0.20, -0.05), Vector3(t.x * 1.08, 0.13, t.z + 0.04),
				paw + Vector3(0, 0.02, -0.01), paw + Vector3(0, 0.0, 0.05)])
			rad = _rad([0.075, 0.056, 0.038, 0.044, 0.04])
		else:
			pts = _pts([t + Vector3(0, 0.07, 0.02), t + Vector3(t.x * 0.04, -0.15, 0.10), Vector3(t.x * 1.08, 0.17, t.z - 0.06),
				paw + Vector3(0, 0.02, -0.01), paw + Vector3(0, 0.0, 0.05)])
			rad = _rad([0.095, 0.062, 0.038, 0.044, 0.04])
		_add(m, pv, ShadowGeo.tube(pts, rad, {"seg": 7, "cap_start": true, "cap_end": true}),
			&"shadow_leather")
		for k: int in 3:
			var dx: float = (float(k) - 1.0) * 0.032
			var cb := paw + Vector3(dx, 0.02, 0.06)
			_add(m, pv, _horn(cb, cb + Vector3(dx * 0.3, 0.0, 0.05), cb + Vector3(dx * 0.5, -0.035, 0.085),
				0.016, 3, 4), &"shadow_bone")
	# Open bone ribs over the flanks.
	for z: float in [0.10, 0.23, 0.36]:
		for s: float in [-1.0, 1.0]:
			_add(m, "Root/Mount/Body", ShadowGeo.tube(_pts([Vector3(0.03 * s, 0.86, z), Vector3(0.165 * s, 0.82, z),
				Vector3(0.232 * s, 0.665, z + 0.02), Vector3(0.20 * s, 0.49, z + 0.05), Vector3(0.10 * s, 0.39, z + 0.07)]),
				_rad([0.024, 0.024, 0.022, 0.018, 0.0]), {"seg": 5}), &"shadow_bone")
	# Curved bone spines along the back, biggest over the shoulders.
	for sp: Array in [[0.30, 0.42], [0.08, 0.36], [-0.14, 0.30], [-0.34, 0.22], [-0.52, 0.15]]:
		var z: float = sp[0]
		var h: float = sp[1]
		var base := Vector3(0, 0.80 + (z - 0.34) * 0.083, z)
		_add(m, "Root/Mount/Body", _horn(base, base + Vector3(0, h * 0.72, -h * 0.08), base + Vector3(0, h * 0.86, -h * 0.62),
			0.07 * h / 0.4 + 0.012, 4, 6), &"shadow_bone")
	# Swept-back horns and two upper fangs.
	for s: float in [-1.0, 1.0]:
		var hb := Vector3(0.09 * s, 0.84, 0.58)
		_add(m, "Root/Mount/Head", ShadowGeo.tube(_pts([hb, hb + Vector3(0.10 * s, 0.10, -0.04), hb + Vector3(0.15 * s, 0.15, -0.16),
			hb + Vector3(0.14 * s, 0.17, -0.29), hb + Vector3(0.10 * s, 0.22, -0.38)]), _rad([0.06, 0.05, 0.038, 0.022, 0.0]),
			{"seg": 6}), &"shadow_bone")
		var f := Vector3(0.042 * s, 0.70, 0.90)
		_add(m, "Root/Mount/Head", _horn(f, f + Vector3(0.0, -0.03, 0.01), f + Vector3(0.006 * s, -0.075, 0.02), 0.018, 3, 4),
			&"shadow_bone")


## Lower jaw: a tapered bone jaw with four teeth (the Jaw node's local frame).
static func _hound_jaw(xf: Transform3D) -> Mesh:
	var items: Array = []
	var jaw := _local(xf, _pts([Vector3(0, 0.655, 0.585), Vector3(0, 0.648, 0.72), Vector3(0, 0.638, 0.86),
		Vector3(0, 0.63, 0.94)]))
	items.append([ShadowGeo.tube(jaw, _rad([0.085, 0.078, 0.06, 0.04]), {"seg": 7, "ell": Vector2(0.5, 1.0),
		"cap_start": true, "cap_end": true})])
	for z: float in [0.80, 0.89]:
		for s: float in [-1.0, 1.0]:
			var p := _local(xf, _pts([Vector3(0.036 * s, 0.655, z), Vector3(0.036 * s, 0.685, z + 0.004),
				Vector3(0.034 * s, 0.712, z + 0.01)]))
			items.append([ShadowGeo.tube(p, _rad([0.014, 0.01, 0.0]), {"seg": 4})])
	return ShadowGeo.combine(items)


## Vertebra tail ending in a bone barb (the Tail part's local frame).
static func _hound_tail(xf: Transform3D) -> Mesh:
	var spine := ShadowGeo.bez(Vector3(0, 0.62, -0.62), Vector3(0, 0.70, -0.92), Vector3(0, 0.93, -1.03), 6)
	var end: Vector3 = spine[spine.size() - 1]
	var dir := (end - spine[spine.size() - 2]).normalized()
	spine.append(end + dir * 0.13)
	return ShadowGeo.tube(_local(xf, spine), _rad([0.052, 0.036, 0.044, 0.03, 0.036, 0.022, 0.03, 0.0]),
		{"seg": 6, "cap_start": true})


# ================================================================ 5.5 Shadow Knight (heavy, 2.4 m)

static func _knight(m: ShadowModel) -> void:
	_drop(m, ["Root/Hips/LegL/MeshInstance3D", "Root/Hips/LegL/MeshInstance3D2", "Root/Hips/LegR/MeshInstance3D",
		"Root/Hips/LegR/MeshInstance3D2", "Root/Hips/MeshInstance3D", "Root/Chest/MeshInstance3D2",
		"Root/Chest/MeshInstance3D3", "Root/Chest/MeshInstance3D4", "Root/Chest/MeshInstance3D5",
		"Root/Chest/MeshInstance3D6", "Root/Chest/MeshInstance3D7", "Root/Chest/MeshInstance3D8",
		"Root/Chest/Head/MeshInstance3D2", "Root/Chest/Head/MeshInstance3D3", "Root/Chest/Head/MeshInstance3D4",
		"Root/Chest/Head/MeshInstance3D5", "Root/Chest/ArmR/MeshInstance3D3", "Root/Chest/ArmR/MeshInstance3D4",
		"Root/Chest/ArmR/MeshInstance3D5"])
	# Armoured legs: obsidian greaves, silver knee cops with a spike, pointed silver sabatons with a spiky cuff.
	var greave := ShadowGeo.lathe([Vector3(0.09, 0.88, 0), Vector3(0.17, 0.82, 0), Vector3(0.18, 0.70, 0.01),
		Vector3(0.152, 0.57, 0.02), Vector3(0.132, 0.49, 0.02), Vector3(0.152, 0.41, 0.0), Vector3(0.142, 0.31, -0.01),
		Vector3(0.112, 0.21, 0.0), Vector3(0.10, 0.15, 0.0)], 8, {"cap_bot": true})
	var cop := ShadowGeo.combine([[_dome(0.10, 0.065)], [ShadowGeo.tube(_pts([Vector3(0, 0.05, 0), Vector3(0, 0.12, -0.01),
		Vector3(0, 0.19, -0.04)]), _rad([0.032, 0.02, 0.0]), {"seg": 5})]])
	var sab := ShadowGeo.combine([[ShadowGeo.tube(_pts([Vector3(0, 0.10, -0.13), Vector3(0, 0.10, 0.02), Vector3(0, 0.085, 0.17),
		Vector3(0, 0.08, 0.29), Vector3(0, 0.10, 0.39)]), _rad([0.105, 0.118, 0.10, 0.066, 0.0]),
		{"seg": 8, "ell": Vector2(0.72, 1.0), "cap_start": true})],
		[ShadowGeo.lathe([Vector3(0.15, 0.27, 0), Vector3(0.135, 0.20, 0), Vector3(0.125, 0.13, 0)], 8,
		{"jag": -0.06, "jag_ring": 0, "jag_seed": 8})]])
	for s: float in [-1.0, 1.0]:
		var pv := "Root/Hips/LegR" if s > 0.0 else "Root/Hips/LegL"
		_add(m, pv, greave, &"shadow_obsidian", Vector3(0.26 * s, 0, 0))
		_add(m, pv, cop, &"shadow_silver", Vector3(0.26 * s, 0.49, 0.12), Vector3(80, 0, 0))
		_add(m, pv, sab, &"shadow_silver", Vector3(0.26 * s, 0, 0.03))
	# Layered plate skirt (team), an iron belt with a bone skull buckle, a pointed tattered tabard (team dark).
	_add(m, "Root/Hips", ShadowGeo.lathe([Vector3(0.40, 1.14, 0), Vector3(0.45, 1.02, 0), Vector3(0.515, 0.85, 0),
		Vector3(0.55, 0.72, 0)], 10, {"sz": 0.9, "jag": 0.08, "jag_seed": 13, "cap_top": true}), &"shadow_cloth")
	_add(m, "Root/Hips", CharacterModel.torus(0.40, 0.47, 16), &"shadow_iron", Vector3(0, 1.12, 0), Vector3.ZERO,
		Vector3(1.0, 1.0, 0.9))
	_add(m, "Root/Hips", CharacterModel.sphere(0.075, 8, 4), &"shadow_bone", Vector3(0, 1.12, 0.41), Vector3.ZERO,
		Vector3(1.0, 1.1, 0.7))
	_add(m, "Root/Hips", ShadowGeo.tube(_pts([Vector3(0, 1.08, 0.39), Vector3(0, 0.86, 0.47), Vector3(0, 0.64, 0.48),
		Vector3(0, 0.47, 0.45), Vector3(0, 0.33, 0.42)]), _rad([0.17, 0.19, 0.175, 0.12, 0.0]),
		{"seg": 6, "ell": Vector2(0.14, 1.0)}), &"shadow_cloth_dark")
	# Barrel obsidian cuirass with a keel, a soul-fire rune (the old rune's glow point), a spiky obsidian collar.
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.34, 2.00, 0.03), Vector3(0.47, 1.90, 0.03), Vector3(0.485, 1.74, 0.04),
		Vector3(0.43, 1.52, 0.05), Vector3(0.375, 1.32, 0.05), Vector3(0.36, 1.16, 0.04)], 10,
		{"sz": 0.8, "keel": 0.16, "arc": Vector2(-104.0, 104.0), "flat": true}), &"shadow_obsidian")
	_add(m, "Root/Chest", ShadowGeo.tube(_pts([Vector3(-0.12, 1.74, 0.475), Vector3(-0.06, 1.60, 0.497), Vector3(0, 1.47, 0.505),
		Vector3(0.06, 1.60, 0.497), Vector3(0.12, 1.74, 0.475)]), _rad([0.0, 0.02, 0.022, 0.02, 0.0]), {"seg": 4}),
		&"shadow_glow_mid")
	_add(m, "Root/Chest", ShadowGeo.tube(_pts([Vector3(0, 1.47, 0.503), Vector3(0, 1.38, 0.49), Vector3(0, 1.27, 0.455)]),
		_rad([0.02, 0.016, 0.0]), {"seg": 4}), &"shadow_glow_mid")
	_add(m, "Root/Chest", ShadowGeo.lathe([Vector3(0.39, 2.10, 0), Vector3(0.36, 2.00, 0), Vector3(0.43, 1.86, 0)], 10,
		{"sz": 0.9, "jag": -0.07, "jag_ring": 0, "jag_seed": 10, "cap_bot": true}), &"shadow_obsidian")
	# Layered team pauldrons (three domed lames, silver rim) crowned by three curved silver spikes.
	var dome := _dome(0.29, 0.17, 1.1)
	for s: float in [-1.0, 1.0]:
		_add(m, "Root/Chest", dome, &"shadow_cloth", Vector3(0.62 * s, 1.95, 0.0), Vector3(0, 0, -22.0 * s))
		_add(m, "Root/Chest", dome, &"shadow_cloth", Vector3(0.74 * s, 1.81, 0.0), Vector3(0, 0, -40.0 * s),
			Vector3(0.84, 0.84, 0.84))
		_add(m, "Root/Chest", dome, &"shadow_cloth_dark", Vector3(0.77 * s, 1.69, 0.0), Vector3(0, 0, -56.0 * s),
			Vector3(0.62, 0.62, 0.62))
		_add(m, "Root/Chest", CharacterModel.torus(0.27, 0.31, 16), &"shadow_silver", Vector3(0.625 * s, 1.945, 0.0),
			Vector3(0, 0, -22.0 * s), Vector3(1.0, 1.0, 1.1))
		for k: int in 3:
			var z: float = (float(k) - 1.0) * 0.15
			var r: float = 0.065 if k == 1 else 0.048
			var hgt: float = 1.0 if k == 1 else 0.78
			var base := Vector3(0.64 * s, 2.09, z)
			_add(m, "Root/Chest", _horn(base, base + Vector3(0.08 * s, 0.19 * hgt, z * 0.15),
				base + Vector3(0.19 * s, 0.34 * hgt, z * 0.35 - 0.08), r), &"shadow_silver")
		# Spiked couter on each elbow, an obsidian vambrace on the forearm.
		var sh := Vector3(0.66 * s, 1.80, 0.0)
		var hd := Vector3(0.42 * s, 1.40, 0.40) if s > 0.0 else Vector3(0.20 * s, 1.26, 0.44)
		var pv := "Root/Chest/ArmR" if s > 0.0 else "Root/Chest/ArmL"
		_add(m, pv, _bracer(sh, hd, 0.58, 0.88, 0.158, 0.168), &"shadow_obsidian")
		_fist(m, pv, "MeshInstance3D2", sh, hd, 0.15, &"shadow_obsidian", &"shadow_silver")
		var el := sh.lerp(hd, 0.48)
		_add(m, pv, _horn(el, el + Vector3(0.07 * s, 0.0, -0.07), el + Vector3(0.12 * s, 0.04, -0.17), 0.05, 3, 5),
			&"shadow_silver")
	# Helm: a ridged spire cap instead of the flat bucket top, a silver brow band over the face opening, cheek plates.
	_add(m, "Root/Chest/Head", ShadowGeo.lathe([Vector3(0.0, 2.66, -0.03), Vector3(0.05, 2.60, -0.02), Vector3(0.11, 2.52, -0.01),
		Vector3(0.16, 2.46, 0.0), Vector3(0.17, 2.43, 0.0)], 8, {"cap_bot": true, "flat": true}), &"shadow_obsidian")
	var brow := PackedVector3Array()
	for k: int in 7:
		var a: float = deg_to_rad(-62.0 + 124.0 * float(k) / 6.0)
		brow.append(Vector3(sin(a) * 0.238, 2.25 + 0.018 * cos(a * 2.0), cos(a) * 0.238))
	_add(m, "Root/Chest/Head", ShadowGeo.tube(brow, _rad([0.0, 0.026, 0.03, 0.032, 0.03, 0.026, 0.0]), {"seg": 5}),
		&"shadow_silver")
	for s: float in [-1.0, 1.0]:
		_add(m, "Root/Chest/Head", ShadowGeo.blade(_pts([Vector3(0.180 * s, 2.22, 0.152), Vector3(0.208 * s, 2.10, 0.175),
			Vector3(0.24 * s, 1.97, 0.20)]), _rad([0.045, 0.045, 0.0]), Vector3(-0.64 * s, 0, 0.77), Vector3(0.77 * s, 0, 0.64),
			0.02, 0.5), &"shadow_obsidian")
	# Great helm crest fin and swept-back bone horns (kept under body_height + 0.4 so the HP bar stays clear).
	_add(m, "Root/Chest/Head", ShadowGeo.blade(_pts([Vector3(0, 2.42, 0.15), Vector3(0, 2.44, 0.0), Vector3(0, 2.42, -0.15),
		Vector3(0, 2.36, -0.27)]), _rad([0.06, 0.13, 0.10, 0.0]), Vector3.UP, Vector3.RIGHT, 0.03, 0.0), &"shadow_obsidian")
	for s: float in [-1.0, 1.0]:
		var hb := Vector3(0.20 * s, 2.32, 0.02)
		_add(m, "Root/Chest/Head", ShadowGeo.tube(_pts([hb, hb + Vector3(0.14 * s, 0.10, -0.03), hb + Vector3(0.27 * s, 0.24, -0.10),
			hb + Vector3(0.30 * s, 0.35, -0.24), hb + Vector3(0.25 * s, 0.41, -0.36), hb + Vector3(0.17 * s, 0.42, -0.43)]),
			_rad([0.10, 0.085, 0.068, 0.05, 0.03, 0.0]), {"seg": 7}), &"shadow_bone")
	# Greatsword: wrapped grip, obsidian pommel spike, a swept spiked guard and a leaf-shaped double-edged blade.
	var hr := Vector3(0.42, 1.40, 0.40)
	var d := Vector3(0.08, 0.81, -0.58).normalized()
	var face := Vector3(0, 0.58, 0.81)
	var e := d.cross(face).normalized()
	var grip := _pts([])
	var gr := _rad([])
	for k: int in 7:
		grip.append(hr + d * lerpf(-0.28, 0.24, float(k) / 6.0))
		gr.append(0.05 if k % 2 == 0 else 0.043)
	_add(m, "Root/Chest/ArmR", ShadowGeo.tube(grip, gr, {"seg": 6, "cap_start": true}), &"shadow_leather")
	_add(m, "Root/Chest/ArmR", _horn(hr - d * 0.27, hr - d * 0.33, hr - d * 0.41, 0.07, 3, 6), &"shadow_obsidian")
	var g := hr + d * 0.26
	_add(m, "Root/Chest/ArmR", ShadowGeo.tube(_pts([g - e * 0.40 + d * 0.10, g - e * 0.22 + d * 0.01, g, g + e * 0.22 + d * 0.01,
		g + e * 0.40 + d * 0.10]), _rad([0.0, 0.05, 0.065, 0.05, 0.0]), {"seg": 6, "ell": Vector2(1.0, 0.8)}),
		&"shadow_silver")
	var spine := _pts([])
	for t: float in [0.30, 0.50, 0.95, 1.45, 1.82, 2.09]:
		spine.append(hr + d * t)
	_add(m, "Root/Chest/ArmR", ShadowGeo.blade(spine, _rad([0.15, 0.13, 0.138, 0.12, 0.075, 0.0]), e, face, 0.034, 1.0),
		&"shadow_silver")
