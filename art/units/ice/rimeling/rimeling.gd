extends IceModel
## Rimeling, Ice T1 rush unit (new-units-12.md 6, rush-balance.md 5.4; tiers wave, medium). Height 1.05, radius 0.4.
## A squat frost goblin: a big head with a long nose, bat ears and two pale tusks in a team hood whose floppy tip
## falls to the left, a pale fur mantle, a pot belly in team cloth over a dark fur kilt, two ICICLE SHIVS held low
## (the right one longer), 3 icicle trophies at the left hip and a frozen crystal hump on the back (asymmetry).
## One glow point: the painted eyes (FaceKit irises). Frost-breath puffs every ~2.6 s.
## Attack `dual_slash` (kit): the two shivs slash one after the other. play_cast(&"frostbite") 0.6 s: both shivs
## raised overhead, crossed, stabbed down, a breath puff. Fidget: scrapes the shivs together. Death: freezes, shatters.

const CAST_LEN := 0.6
const FIST_L := Vector3(-0.31, 0.47, 0.10)
const FIST_R := Vector3(0.31, 0.47, 0.10)
const SH_L := Vector3(-0.25, 0.72, 0.0)
const SH_R := Vector3(0.25, 0.72, 0.0)

var _puffed: bool = false


func _build_parts() -> void:
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	# G-C leftovers (2026-10-15, docs/art/gc_leftovers.md): smooth bowed legs and arms, jagged fur kilt / mantle / cuffs,
	# a hooked nose, bat-wing ears, curved tusks, a floppy drooping hood tip, faceted icicles (IceUnitShapes, cached per process).
	# ---- Legs: short bowed fur legs, pale fur cuffs, big leather feet.
	IceUnitShapes.put(self, leg_l, "rml_gc_leg_l", func(acc: Dictionary) -> void: _gc_leg(acc, -1.0))
	IceUnitShapes.put(self, leg_r, "rml_gc_leg_r", func(acc: Dictionary) -> void: _gc_leg(acc, 1.0))
	# ---- Chest: pot belly (team), dark fur kilt, leather belt + pouch, pale fur mantle, icicle trophies at the left
	# hip, frozen crystal hump on the back; value breaks: a dark front panel, a leather baldric, an iron buckle, a dark
	# fur patch on the right flank.
	IceUnitShapes.put(self, chest, "rml_gc_chest", _gc_chest)
	# ---- Head: big goblin head, long nose, bat ears, tusks, team hood with a floppy tip (left), fur rim.
	IceUnitShapes.put(self, head, "rml_gc_head", _gc_head)
	# Face (faces pass 2026-09-28, goblin: eyes + mouth, no hair): mean narrow eyes with glowing ice-blue irises (the
	# head's glow point, was the eye slit) and a toothy grin between the tusks (FaceKit).
	var gsk := ICE_SKIN
	_face = UnitFaces.attach_lean(self, head, "rimeling", {"center": Vector3(0, 0.90, 0.05), "radius": 0.19,
		"head_mesh": sphere(0.19, 10, 5), "head_scale": Vector3(1.15, 0.95, 1.0), "preset": &"plain", "detail": &"low",
		"skin": gsk, "hair": Color(0.20, 0.24, 0.32), "eyes": Color(0.55, 0.90, 1.0), "ears": &"none",
		"palette": {"iris_glow": 0.9, "sclera": Color(0.90, 0.95, 1.0), "lip": gsk.darkened(0.25), "lip_line": Color(0.10, 0.12, 0.20),
			"mouth_in": Color(0.10, 0.10, 0.20)},
		"eye": {"c": Vector2(0.068, 0.032), "hw": 0.036, "top": 0.020, "ir": 0.017},
		"mouth": {"c": Vector2(0.0, -0.080), "hw": 0.060},
		"x": {&"neutral": {"blush": 0.0, "cut_in": 0.35, "mouth": {"kind": "closed", "curve": 2.2, "w": 1.0}}, &"smile": {"blush": 0.0},
			&"worried": {"blush": 0.0}, &"shout": {"blush": 0.0}, &"fierce": {"blush": 0.0}}}, false)
	var trim := add_part(head, torus(0.17, 0.21, 12), palette(&"unit_gold_trim"), Vector3(0, 1.07, -0.06),
		Vector3(-8, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: dark fur sleeves bent at the elbow, pale fur shoulder tufts, leather mitts with grip wraps, the two icicle
	# shivs (held low, forward; the right one longer).
	IceUnitShapes.put(self, arm_l, "rml_gc_arm_l", func(acc: Dictionary) -> void: _gc_arm(acc, -1.0))
	IceUnitShapes.put(self, arm_r, "rml_gc_arm_r", func(acc: Dictionary) -> void: _gc_arm(acc, 1.0))
	# ---- Fx: breath, hit chips, shatter, cool blob.
	add_breath(Vector3(0, 0.86, 0.33), 0.16)
	add_hit_chips(Vector3(0, 0.65, 0.1), 5)
	add_shatter(Vector3(0, 0.55, 0), 10, 0.25, 0.08)
	ensure_shadow_blob(0.36, BLOB_TINT)


# ================================================================ G-C shape builders (model space, IceUnitShapes)

func _gc_leg(acc: Dictionary, sx: float) -> void:
	IceUnitShapes.limb(IceUnitShapes.st(acc, ice(&"ice_fur")), Vector3(0.11 * sx, 0.42, 0), Vector3(0.14 * sx, 0.24, 0.04),
		Vector3(0.12 * sx, 0.08, 0.0), 0.08, 0.068, 0.058, 8)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.064, 0.09, 0.06, 4, 0.025),
		Transform3D(Basis.IDENTITY, Vector3(0.125 * sx, 0.125, 0.01)))
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_leather")), boot(0.08, 0.10),
		IceUnitShapes.xf(Vector3(0.125 * sx, 0.0, 0.06), Vector3(0, 8.0 * sx, 0), Vector3(1.0, 1.0, 1.6)))


func _gc_chest(acc: Dictionary) -> void:
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_cloth")), sphere(0.24, 10, 5),
		IceUnitShapes.xf(Vector3(0, 0.61, 0.03), Vector3.ZERO, Vector3(1.05, 0.95, 1.0)))
	var fur := IceUnitShapes.st(acc, ice(&"ice_fur"))
	ChampionShapes.append(fur, fur_ring(0.21, 0.27, 0.15, 7, 0.045), Transform3D(Basis.IDENTITY, Vector3(0, 0.38, 0.0)))
	ChampionShapes.append(fur, sphere(0.10, 8, 4), IceUnitShapes.xf(Vector3(0.17, 0.60, 0.12), Vector3.ZERO, Vector3(0.6, 1.0, 0.8)))
	var leather := IceUnitShapes.st(acc, ice(&"ice_leather"))
	ChampionShapes.band(leather, 0.232, 0.055, 0.016, 10, Transform3D(Basis.IDENTITY, Vector3(0, 0.52, 0.02)))
	IceUnitShapes.egg(leather, IceUnitShapes.xf(Vector3(0.20, 0.46, 0.15), Vector3(0, -30, 0), Vector3(1.0, 1.0, 0.75)), 0.06, 0.13, 6)
	IceUnitShapes.strap(leather, PackedVector3Array([Vector3(0.16, 0.47, 0.18), Vector3(0.08, 0.545, 0.268), Vector3(0.0, 0.62, 0.289),
		Vector3(-0.08, 0.69, 0.262), Vector3(-0.16, 0.76, 0.165)]), 0.055, 0.02)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.12, 0.29, 0.14, 7, 0.04),
		Transform3D(Basis.IDENTITY, Vector3(0, 0.70, -0.01)))
	ChampionShapes.lame(IceUnitShapes.st(acc, ice(&"ice_cloth_dark")), 0.244, 0.244, 0.535, 0.70, -0.32, 0.32, 4, 0.016,
		Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.03)))
	ChampionShapes.plate(IceUnitShapes.st(acc, ice(&"ice_steel")), PackedVector2Array([Vector2(-0.035, 0.03), Vector2(0.035, 0.03),
		Vector2(0.035, -0.03), Vector2(-0.035, -0.03)]), 0.02, 0.008, Transform3D(Basis.IDENTITY, Vector3(0, 0.52, 0.27)))
	var frost := IceUnitShapes.st(acc, ice(&"ice_frost_crystal"))
	for i: int in 3:
		IceUnitShapes.crystal(frost, Vector3(-0.19 - 0.035 * i, 0.50, 0.10 - 0.05 * i), Vector3(0.1 * (i - 1), -1.0, 0.1), 0.028,
			0.13 + 0.03 * i)
	IceUnitShapes.crystal(frost, Vector3(0.07, 0.70, -0.20), Vector3(0.25, 1.0, -0.9), 0.055, 0.22)
	IceUnitShapes.crystal(frost, Vector3(-0.06, 0.66, -0.22), Vector3(-0.3, 0.7, -1.0), 0.045, 0.17)
	IceUnitShapes.crystal(frost, Vector3(0.0, 0.58, -0.24), Vector3(0.05, 0.4, -1.0), 0.04, 0.13)


func _gc_head(acc: Dictionary) -> void:
	var skin := IceUnitShapes.st(acc, ice(&"ice_skin"))
	ChampionShapes.append(skin, sphere(0.19, 10, 5), IceUnitShapes.xf(Vector3(0, 0.90, 0.05), Vector3.ZERO, Vector3(1.15, 0.95, 1.0)))
	# a long hooked nose
	ChampionShapes.tube(skin, PackedVector3Array([Vector3(0, 0.885, 0.20), Vector3(0, 0.878, 0.30), Vector3(0, 0.848, 0.375)]),
		PackedFloat32Array([0.05, 0.032, 0.006]), 6, false)
	var pale := IceUnitShapes.st(acc, ice(&"ice_fur_pale"))
	for s: float in [-1.0, 1.0]:
		# bat-wing ear: a bevelled leaf with a notched trailing edge, swept back and up
		var ear := PackedVector2Array([Vector2(0.0, 0.05), Vector2(0.15, 0.065), Vector2(0.29, 0.0), Vector2(0.16, -0.012),
			Vector2(0.13, -0.05), Vector2(0.0, -0.045)])
		if s < 0.0:
			for k: int in ear.size():
				ear[k] = Vector2(-ear[k].x, ear[k].y)
		ChampionShapes.plate(skin, ear, 0.022, 0.008, IceUnitShapes.xf(Vector3(0.16 * s, 0.95, -0.02), Vector3(-10, -25.0 * s, 18.0 * s)))
		# curved tusk from the lower jaw
		ChampionShapes.tube(pale, PackedVector3Array([Vector3(0.055 * s, 0.79, 0.19), Vector3(0.062 * s, 0.82, 0.215),
			Vector3(0.075 * s, 0.865, 0.225)]), PackedFloat32Array([0.022, 0.016, 0.0]), 5, false)
	var cloth := IceUnitShapes.st(acc, ice(&"ice_cloth"))
	ChampionShapes.append(cloth, sphere(0.235, 10, 5), IceUnitShapes.xf(Vector3(0, 0.96, -0.08), Vector3.ZERO, Vector3(1.05, 1.0, 1.05)))
	# the floppy hood tip, drooping to the left, a pale pompom at its end
	var tip_c := Vector3(-0.07, 1.12, -0.24)
	var dir := Basis.from_euler(Vector3(-55, 0, 24) * DEG) * Vector3.UP
	var end := tip_c + dir * 0.13 + Vector3(-0.10, -0.10, -0.03)
	ChampionShapes.tube(cloth, PackedVector3Array([tip_c - dir * 0.17, tip_c - dir * 0.04, tip_c + dir * 0.08 + Vector3(-0.03, -0.02, 0),
		end]), PackedFloat32Array([0.125, 0.095, 0.06, 0.03]), 7, true)
	ChampionShapes.append(pale, sphere(0.055, 7, 4), Transform3D(Basis.IDENTITY, end + Vector3(-0.02, -0.03, 0)))
	# pale fur ruff round the face, flaring forward
	ChampionShapes.append(pale, fur_ring(0.14, 0.20, 0.06, 6, 0.02),
		Transform3D(Basis(Vector3.RIGHT, (78.0 + 180.0) * DEG), Vector3(0, 0.93, 0.15)))


func _gc_arm(acc: Dictionary, s: float) -> void:
	var sh: Vector3 = SH_R if s > 0.0 else SH_L
	var fist: Vector3 = FIST_R if s > 0.0 else FIST_L
	var elbow := (sh + fist) * 0.5 + Vector3(0.035 * s, 0.0, -0.05)
	IceUnitShapes.limb(IceUnitShapes.st(acc, ice(&"ice_fur")), sh, elbow, fist, 0.062, 0.055, 0.05, 6)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_cap(0.09, -25.0, 5, 18.0),
		IceUnitShapes.xf(sh + Vector3(0.02 * s, -0.01, 0), Vector3(0, 0, -20.0 * s), Vector3(1.0, 0.85, 1.0)))
	var leather := IceUnitShapes.st(acc, ice(&"ice_leather"))
	IceUnitShapes.egg(leather, IceUnitShapes.on(Vector3(0, -0.4, 1.0), fist + Vector3(0, -0.01, 0.0)), 0.07, 0.14, 6)
	var blade_dir := Vector3(0.05 * -s, -0.35 if s < 0.0 else -0.30, 1.0)
	ChampionShapes.band(leather, 0.046, 0.06, 0.01, 6, IceUnitShapes.on(blade_dir, fist + Vector3(0, -0.02, 0.06)))
	IceUnitShapes.crystal(IceUnitShapes.st(acc, ice(&"ice_frost_crystal")), fist + Vector3(0, -0.03, 0.08), blade_dir,
		0.042 if s < 0.0 else 0.048, 0.34 if s < 0.0 else 0.44)


# ================================================================ motion

## Frostbite: both shivs raised overhead and crossed, then stabbed down in front with a breath puff.
func _pose_cast(_spell: StringName, t: float) -> float:
	var a := _k3(t, 0.0, 0.22, 0.32, CAST_LEN, -150.0, -40.0)
	rot(P_ARM_L, Vector3(a * DEG, 0, _k3(t, 0.0, 0.22, 0.32, CAST_LEN, -18.0, -10.0) * DEG))
	rot(P_ARM_R, Vector3(a * DEG, 0, _k3(t, 0.0, 0.22, 0.32, CAST_LEN, 18.0, 10.0) * DEG))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.22, 0.32, CAST_LEN, -12.0, 20.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.2, 0.32, CAST_LEN, 0.08, -0.05), _k3(t, 0.2, 0.32, 0.35, CAST_LEN, 0.15, 0.15)))
	if t >= 0.3 and not _puffed:
		_puffed = true
		puff_breath()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_puffed = false


func _ice_process(_dt: float) -> void:
	# Goblin scurry: a forward hunch and a wider arm pump on the walk.
	if _walk_w > 0.0 and not _dead:
		rot(P_CHEST, Vector3(10.0 * DEG * _walk_w, 0, 0))
		rot(P_ARM_L, Vector3(-10.0 * DEG * sin(TAU * _walk_p) * _walk_w, 0, 0))
		rot(P_ARM_R, Vector3(14.0 * DEG * sin(TAU * _walk_p) * _walk_w, 0, 0))


## Fidget: scrapes the two shivs together in front of the belly, grinning up.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.25, 0.9, 1.2, 1.0, 1.0)
	var s: float = sin(t * 18.0) * k
	rot(P_ARM_L, Vector3((-45.0 + 8.0 * s) * DEG * k, 0, -22.0 * DEG * k))
	rot(P_ARM_R, Vector3((-45.0 - 8.0 * s) * DEG * k, 0, 22.0 * DEG * k))
	rot(P_HEAD, Vector3(-10.0 * DEG * k, 0, 0))
	return 1.2
