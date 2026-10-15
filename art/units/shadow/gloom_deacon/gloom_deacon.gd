extends ShadowModel
## Gloom Deacon, Shadow T2 support caster (caster-units.md 5.4 / 10.4, task CU.V4). Height 1.8 x1.06 scene scale (mitre tip 2.3 m).
## "A tall veiled cleric with a floating reliquary": tall and thin, layered vestments (a team-dark underskirt to the
## floor, a team overskirt split at the front with silver orphreys, a two-layer shoulder mantle), a HIGH STIFF COLLAR
## flaring behind the head, a pale serene face in a dark cowl crowned by a MITRE (two team plates with a cleft, a silver
## band and orphrey, echoing Malrik's hollow church and the Hollow Oathsworn's crest); the left hand on the heart, a
## silver chain and bone pendant. The silhouette hooks: a long iron TAPER-STAFF in the right hand crowned with a bone
## candle and a violet flame (glow point 1; the Blood Tithe tether starts there), and a small COFFIN-SHAPED RELIQUARY of
## bone and silver floating behind her left shoulder with a violet eye-window (glow point 2), bobbing with a lag.
## Face (FaceKit + ShadowFaces): pale, gentle, no ears (under the cowl), a black-violet braid over the left shoulder and
## a fringe, a thin veil line across the brow, low-glow violet eyes, dark-plum lips, a serene closed mouth.
## Attack `deacon_bolt` (0.5 s, release 0.12): the taper jabs at the target, the flame flares (a thin violet bolt).
## play_cast(&"blood_tithe"): a HELD pose (taper levelled at the ally, left hand on the heart, head bowed) that lasts
##   while the channel does: call play_cast(&"blood_tithe") again each tick (it extends the hold, no restart) or
##   set_channeling(true / false). Ends 1.2 s after the last call, eases out in 0.25 s. She may walk meanwhile.
## play_cast(&"umbral_passage") (2.5 s): the taper raised high overhead, the reliquary rises, opens its lid and blazes,
##   the robe hem lifts in a violet updraft; closes at the end.
## Death: ShadowModel's sink + dissolve; the reliquary drops to the ground and its lid snaps shut, the flame dies.
## VFX hooks (art/vfx/caster_shadow_vfx.gd reads them): get_tether_origin() (the flame), get_reliquary_point(),
## play_vigil() (the reliquary flares: an ally's soul arrived). signal cast_released(spell_id, from).
## Draws at rest: 7 merged pivots + Face + Staff (4 surfaces, own_glow) + Reliquary + Lid + blob + flame motes.

signal cast_released(spell_id: StringName, from: Vector3)

const HC := Vector3(0, 1.745, 0.06)
const HR := 0.118
const HAND_R := Vector3(0.29, 1.16, 0.20)
const HAND_L := Vector3(-0.07, 1.36, 0.215)
const FLAME := Vector3(0.0, 1.06, 0.0)          # flame base in the staff node (grip at the origin)
const RELIQ := Vector3(-0.38, 1.86, -0.26)
const LID_HINGE := Vector3(-0.085, 0.0, 0.058)   # in the reliquary node
const ATTACK_LEN := 0.5
const RELEASE := 0.12
const TITHE_IN := 0.25
const TITHE_HOLD := 1.2
const PASSAGE_LEN := 2.5
const FLAME_GLOW := 1.6
const RELIQ_GLOW := 1.25
const VIOLET := Color(0.72, 0.34, 1.0)
const PLUM := Color(0.36, 0.14, 0.30)

static var _style: Dictionary = {}

var _staff: MeshInstance3D
var _reliq: Node3D
var _reliq_body: MeshInstance3D
var _lid: Node3D
var _lid_mesh: MeshInstance3D
var _motes: GPUParticles3D
var _spark: GPUParticles3D
var _updraft: GPUParticles3D
var _flare: float = 0.0            # extra flame glow (attack / casts)
var _rglow: float = 0.0            # extra reliquary glow (passage / vigil)
var _vigil_t: float = 0.0
var _open: float = 0.0             # 0 closed .. 1 lid open
var _staff_rot: Vector3 = Vector3.ZERO
var _staff_written: Vector3 = Vector3(99, 99, 99)
var _reliq_pos: Vector3 = Vector3.ZERO
var _reliq_rot: Vector3 = Vector3.ZERO
var _reliq_written: Vector3 = Vector3(99, 99, 99)
var _lid_written: float = -1.0
var _flame_v: float = -1.0
var _reliq_v: float = -1.0
var _tithe_end: float = 0.0        # cast length of the current Blood Tithe hold (grows while channelling)
var _channel: bool = false
var _fired: bool = false
var _updraft_fired: bool = false
var _chest_origin: Vector3 = Vector3.ZERO


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
	var silver := palette(&"shadow_silver")
	var bone := palette(&"shadow_bone")
	var skin := palette(&"shadow_skin")
	_chest_origin = model_origin(chest)
	# ---- Legs: only the pointed shoe tips peek out under the hem.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, sphere(0.065, 6, 3), leather, Vector3(0.10 * sx, 0.045, 0.13), Vector3(-8, 0, 0), Vector3(0.85, 0.65, 1.9))
	# ---- Hips: a near-black underskirt to the floor, the team overskirt to mid-calf, split at the front with silver
	# orphreys and a silver hem, a silver cincture with a hanging cord, a bone rune plate on the underskirt.
	var obsidian := palette(&"shadow_obsidian")
	add_part(hips, _lathe("gd_under", PackedVector2Array([Vector2(0.20, 1.02), Vector2(0.225, 0.80), Vector2(0.28, 0.40),
		Vector2(0.325, 0.08), Vector2(0.33, 0.02)]), 12), obsidian, Vector3.ZERO)
	add_part(hips, _lathe("gd_under_hem", PackedVector2Array([Vector2(0.333, 0.075), Vector2(0.337, 0.03)]), 12), cdark,
		Vector3.ZERO)
	var a0 := deg_to_rad(90.0 + 26.0)
	var a1 := deg_to_rad(90.0 - 26.0 + 360.0)
	add_part(hips, _lathe("gd_over", PackedVector2Array([Vector2(0.215, 1.03), Vector2(0.245, 0.80), Vector2(0.30, 0.55),
		Vector2(0.345, 0.37), Vector2(0.355, 0.32)]), 12, a0, a1, true), cloth, Vector3.ZERO)
	add_part(hips, _lathe("gd_hem", PackedVector2Array([Vector2(0.352, 0.39), Vector2(0.36, 0.315)]), 12, a0, a1, true), silver,
		Vector3.ZERO)
	for s: float in [-1.0, 1.0]:
		add_part(hips, _panel("gd_orph_%s" % s, 0.32, 1.0, 0.357, 0.222, 0.47 * s - 0.055, 0.47 * s + 0.055, 1, 0.012),
			silver, Vector3.ZERO)
	add_part(hips, _lathe("gd_belt", PackedVector2Array([Vector2(0.236, 1.005), Vector2(0.24, 0.95)]), 12), silver,
		Vector3.ZERO)
	add_part(hips, _path("gd_cord", PackedVector3Array([Vector3(-0.09, 0.96, 0.225), Vector3(-0.115, 0.78, 0.265),
		Vector3(-0.125, 0.58, 0.31)]), PackedFloat32Array([0.016, 0.015, 0.014]), 4), silver, Vector3.ZERO)
	add_part(hips, sphere(0.032, 6, 3), bone, Vector3(-0.125, 0.555, 0.315))
	add_part(hips, box(Vector3(0.11, 0.11, 0.02)), bone, Vector3(0, 0.215, 0.31), Vector3(-8, 0, 45))
	# ---- Chest: slim team torso, a two-layer mantle (dark under, team over), the high stiff collar (team inside, a
	# silver rim), a silver chain with a bone pendant.
	var tc := Vector3(0, 1.24, 0.0)
	add_part(chest, _lathe("gd_torso", PackedVector2Array([Vector2(0.20, -0.28), Vector2(0.22, -0.12), Vector2(0.235, 0.06),
		Vector2(0.21, 0.18), Vector2(0.11, 0.25)]), 10), cloth, tc, Vector3(-3, 0, 0), Vector3(1.0, 1.0, 0.78))
	add_part(chest, cyl(0.13, 0.33, 0.24, 12, false), cdark, Vector3(0, 1.40, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	add_part(chest, cyl(0.13, 0.27, 0.15, 12, false), cloth, Vector3(0, 1.475, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 0.82))
	var c0 := deg_to_rad(90.0 + 62.0)
	var c1 := deg_to_rad(90.0 - 62.0 + 360.0)
	add_part(chest, _lathe("gd_collar", PackedVector2Array([Vector2(0.13, 1.49), Vector2(0.16, 1.60), Vector2(0.215, 1.78),
		Vector2(0.245, 1.90)]), 10, c0, c1, true), cloth, Vector3(0, 0, -0.02), Vector3.ZERO, Vector3(1.0, 1.0, 0.9))
	add_part(chest, _lathe("gd_collar_rim", PackedVector2Array([Vector2(0.238, 1.87), Vector2(0.25, 1.915)]), 10, c0, c1, true),
		silver, Vector3(0, 0, -0.02), Vector3.ZERO, Vector3(1.0, 1.0, 0.9))
	add_part(chest, _path("gd_chain", PackedVector3Array([Vector3(-0.15, 1.47, 0.13), Vector3(-0.05, 1.36, 0.19),
		Vector3(0.05, 1.36, 0.19), Vector3(0.15, 1.47, 0.13)]), PackedFloat32Array([0.012, 0.012, 0.012, 0.012]), 4), silver,
		Vector3.ZERO)
	add_part(chest, box(Vector3(0.05, 0.07, 0.02)), bone, Vector3(0.03, 1.31, 0.205), Vector3(-5, 0, 45))
	# ---- Head: pale face in a dark cowl open at the front, the mitre (front plate team, back plate team-dark, cleft
	# between), its silver band and orphrey with a small silver sigil.
	add_part(head, sphere(HR, 10, 6), skin, HC, Vector3.ZERO, Vector3(0.92, 1.06, 0.95))
	add_part(head, _lathe("gd_cowl", PackedVector2Array([Vector2(0.13, -0.13), Vector2(0.152, -0.04), Vector2(0.152, 0.05),
		Vector2(0.13, 0.115)]), 10, deg_to_rad(90.0 + 58.0), deg_to_rad(90.0 - 58.0 + 360.0), true), cdark,
		HC + Vector3(0, 0, -0.012))
	for pz: float in [1.0, -1.0]:
		add_part(head, _lathe("gd_mitre", PackedVector2Array([Vector2(0.146, 1.83), Vector2(0.15, 1.92), Vector2(0.13, 2.0),
			Vector2(0.097, 2.07), Vector2(0.05, 2.13), Vector2(0.001, 2.18)]), 12), cloth if pz > 0.0 else cdark,
			Vector3(0, 0, HC.z - 0.012 + 0.03 * pz), Vector3.ZERO, Vector3(1.0, 1.0, 0.30))
	add_part(head, _lathe("gd_mitre_band", PackedVector2Array([Vector2(0.155, 1.875), Vector2(0.155, 1.83)]), 12), silver,
		Vector3(0, 0, HC.z - 0.012), Vector3.ZERO, Vector3(1.0, 1.0, 0.62))
	add_part(head, box(Vector3(0.028, 0.24, 0.012)), silver, Vector3(0, 1.99, HC.z + 0.064), Vector3(-9, 0, 0))
	add_part(head, box(Vector3(0.06, 0.06, 0.014)), silver, Vector3(0, 1.955, HC.z + 0.07), Vector3(-9, 0, 45))
	if _style.is_empty():
		_style = _face_style()
	_face = FaceKit.attach(self, head, "gloom_deacon", _style)
	var trim := add_part(head, torus(0.15, 0.18, 10), palette(&"unit_gold_trim"), Vector3(0, 1.86, HC.z - 0.01), Vector3.ZERO,
		Vector3(1.0, 1.0, 0.65), true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Left arm: bell sleeve (team) to the hand laid on the heart, the dark lining and the hanging bell drape.
	add_part(arm_l, _path("gd_sleeve_l", PackedVector3Array([Vector3(-0.19, 1.52, 0.0), Vector3(-0.27, 1.31, 0.05),
		Vector3(-0.15, 1.33, 0.19)]), PackedFloat32Array([0.068, 0.07, 0.075]), 7), cloth, Vector3.ZERO)
	add_part(arm_l, cyl(0.06, 0.13, 0.30, 8, false), cdark, Vector3(-0.19, 1.19, 0.16), Vector3(8, 0, -6), Vector3(1.0, 1.0, 0.7))
	add_part(arm_l, cyl(0.075, 0.11, 0.08, 8, false), cloth, Vector3(-0.16, 1.32, 0.19), Vector3(0, 0, 70))
	add_part(arm_l, sphere(0.048, 6, 4), skin, HAND_L, Vector3(0, 0, 20), Vector3(1.25, 0.85, 0.6))
	# ---- Right arm: bell sleeve, the pale hand on the staff (the staff is its own node: it stays upright / aims).
	add_part(arm_r, _path("gd_sleeve_r", PackedVector3Array([Vector3(0.19, 1.52, 0.0), Vector3(0.28, 1.31, 0.04),
		Vector3(0.29, 1.21, 0.15)]), PackedFloat32Array([0.068, 0.07, 0.075]), 7), cloth, Vector3.ZERO)
	add_part(arm_r, cyl(0.07, 0.125, 0.22, 8, false), cdark, Vector3(0.29, 1.17, 0.12), Vector3(38, 0, 0), Vector3(1.0, 1.0, 0.8))
	add_part(arm_r, sphere(0.05, 6, 4), skin, HAND_R)
	_staff = add_part(arm_r, _staff_mesh(), null, HAND_R, Vector3.ZERO, Vector3.ONE, true, "Staff")
	_staff.set_meta(&"own_glow", true)
	_staff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_motes = make_motes(VIOLET, 5, 1.2, 0.05, 0.4, 0.07)
	_motes.name = "FlameMotes"
	_motes.position = FLAME + Vector3(0, 0.08, 0)
	_staff.add_child(_motes)
	_spark = make_motes(VIOLET, 10, 0.5, 0.06, 1.4, 0.10, false, true)
	_spark.name = "BoltSpark"
	_spark.position = FLAME + Vector3(0, 0.06, 0)
	_staff.add_child(_spark)
	# ---- The reliquary: a floating node under the chest (keep_separate: bobs, lags, opens, falls on death).
	_reliq = Node3D.new()
	_reliq.name = "Reliquary"
	_reliq.set_meta(&"keep_separate", true)
	_reliq.position = RELIQ - _chest_origin
	_reliq.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(18.0), deg_to_rad(6.0))
	_reliq.scale = Vector3.ONE * 1.22
	chest.add_child(_reliq)
	_reliq_body = MeshInstance3D.new()
	_reliq_body.name = "ReliqBody"
	_reliq_body.mesh = _reliq_mesh()
	_reliq_body.set_meta(&"own_glow", true)
	_reliq_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_reliq.add_child(_reliq_body)
	_lid = Node3D.new()
	_lid.name = "LidHinge"
	_lid.position = LID_HINGE
	_reliq.add_child(_lid)
	_lid_mesh = MeshInstance3D.new()
	_lid_mesh.name = "Lid"
	_lid_mesh.mesh = _lid_mesh_of()
	_lid_mesh.position = -LID_HINGE
	_lid_mesh.set_meta(&"own_glow", true)
	_lid_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lid.add_child(_lid_mesh)
	# ---- Fx: the passage updraft at the hem, death motes (restarted by the kit when the glows die), the violet pool.
	_updraft = make_motes(VIOLET, 22, 1.2, 0.42, 1.6, 0.11, true, true)
	_updraft.name = "Updraft"
	_updraft.position = Vector3(0, 0.08, 0)
	$Fx.add_child(_updraft)
	var dm := make_motes(VIOLET, 12, 1.1, 0.25, 1.3, 0.12, true, true)
	dm.name = "DeathMotes"
	dm.set_meta(&"death_fx", true)
	dm.position = Vector3(0, 0.8, 0)
	$Fx.add_child(dm)
	ensure_shadow_blob(0.42, Color(0.1, 0.03, 0.16, 0.55))


## The face style: ShadowFaces glowing-eye palette at a low glow, gentle, no ears, plum lips; the veil line across the
## brow and a fringe as extra paint, the black-violet braid over the left shoulder as 3D hair.
func _face_style() -> Dictionary:
	var pal := ShadowFaces.pal(ShadowFaces.PALE, Color(0.75, 0.35, 1.0), 0.55, Color(0.16, 0.10, 0.20))
	pal["lip"] = PLUM
	pal["lip_line"] = Color(0.20, 0.06, 0.16)
	var st := FaceKit.style_from({"center": HC, "radius": HR, "head_mesh": sphere(HR, 10, 6),
		"head_scale": Vector3(0.92, 1.06, 0.95), "preset": &"gentle", "detail": &"low", "skin": ShadowFaces.PALE,
		"hair": ShadowFaces.INK, "hair_tip": ShadowFaces.INK_TIP, "eyes": Color(0.75, 0.35, 1.0), "ears": &"none",
		"palette": pal,
		"eye": {"c": Vector2(0.036, 0.012), "hw": 0.021, "top": 0.016, "bot": 0.010, "ir": 0.011},
		"brow": {"inner": Vector2(0.016, 0.036), "mid": Vector2(0.038, 0.043), "outer": Vector2(0.058, 0.036),
			"w": Vector3(0.0036, 0.0034, 0.0015)},
		"mouth": {"c": Vector2(0.0, -0.044), "hw": 0.019, "lip": 0.0024},
		"x": NatureFaces.lean_x(1.1, {&"neutral": {"mouth": {"kind": "closed", "curve": 0.45, "w": 0.9}, "open": 0.8,
			"low": 0.45}}),
		"hair_fn": func(acc: Dictionary) -> void: _hair(acc)})
	var cv: Dictionary = st["canvas"]
	# the veil line: a thin dark-silver band across the brow, just under the cowl edge
	st["base"] = func(acc: Dictionary, _id: StringName) -> void:
		FaceKit.strip(acc, cv, FaceKit.bez(Vector2(-0.075, 0.056), Vector2(0.0, 0.066), Vector2(0.075, 0.056), 10),
			Vector3(0.0035, 0.0045, 0.0035), Color(0.30, 0.26, 0.40), 0.0016)
		FaceKit.fill(acc, cv, FaceKit.ellipse(Vector2(0.0, 0.070), Vector2(0.007, 0.009), 45.0, 6), Color(0.62, 0.56, 0.78),
			0.0022)
	return st


## A swept black-violet fringe out of the cowl and the braid falling over the left shoulder, tied with a silver ring.
static func _hair(acc: Dictionary) -> void:
	UnitFaces.hood_fringe(acc, HC, HR, ShadowFaces.INK, ShadowFaces.INK_TIP, -1.0, 0.95)
	var end := FaceKit.braid(acc, [HC + Vector3(-0.10, -0.03, -0.01), HC + Vector3(-0.14, -0.15, 0.04),
		HC + Vector3(-0.15, -0.30, 0.12), HC + Vector3(-0.13, -0.44, 0.17)], 5, 0.046, 0.034, ShadowFaces.INK,
		ShadowFaces.INK_TIP)
	FaceKit.put_mesh(acc, CharacterModel.sphere(1.0, 6, 3), Transform3D(Basis.from_scale(Vector3(0.022, 0.016, 0.022)),
		end + Vector3(0, 0.03, 0)), Color(0.72, 0.70, 0.82))


# ================================================================ meshes (cached, model space)

## Surface of revolution around the model Y axis through `prof` (x = radius, y = height) from angle a0 to a1 (radians,
## 0 = +X, PI/2 = +Z: the front), `seg` sides. `both` = double-sided (open collars, cowls seen from inside).
static func _lathe(key: String, prof: PackedVector2Array, seg: int, a0: float = 0.0, a1: float = TAU,
		both: bool = false) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in prof.size():
		for j: int in seg + 1:
			var a: float = lerpf(a0, a1, float(j) / float(seg))
			st.add_vertex(Vector3(cos(a) * prof[i].x, prof[i].y, sin(a) * prof[i].x))
	for i: int in prof.size() - 1:
		for j: int in seg:
			var p0 := i * (seg + 1) + j
			var q0 := (i + 1) * (seg + 1) + j
			for k: int in [p0, q0, p0 + 1, p0 + 1, q0, q0 + 1]:
				st.add_index(k)
	st.generate_normals()
	var m := _outward_lathe(st.commit())
	if both:
		m = _double(m)
	return _cached(key, m)


## Faces of a lathe pointing away from the Y axis.
static func _outward_lathe(m: ArrayMesh) -> ArrayMesh:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var out := 0.0
	for i: int in range(0, idx.size(), 3):
		var a := v[idx[i]]
		var n := (v[idx[i + 2]] - a).cross(v[idx[i + 1]] - a)   # visible side (Godot front = clockwise)
		var ctr := (a + v[idx[i + 1]] + v[idx[i + 2]]) / 3.0
		out += n.dot(Vector3(ctr.x, 0, ctr.z))
	if out >= 0.0:
		return m
	for i: int in range(0, idx.size(), 3):
		var t := idx[i + 1]
		idx[i + 1] = idx[i + 2]
		idx[i + 2] = t
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for i: int in nrm.size():
		nrm[i] = -nrm[i]
	arr[Mesh.ARRAY_INDEX] = idx
	arr[Mesh.ARRAY_NORMAL] = nrm
	var fixed := ArrayMesh.new()
	fixed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return fixed


## The mesh plus a flipped copy (inside faces with inverted normals).
static func _double(m: ArrayMesh) -> ArrayMesh:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var n := v.size()
	var v2 := v.duplicate()
	var n2 := nrm.duplicate()
	for i: int in n:
		v2.append(v[i])
		n2.append(-nrm[i])
	var i2 := idx.duplicate()
	for i: int in range(0, idx.size(), 3):
		i2.append(idx[i] + n)
		i2.append(idx[i + 2] + n)
		i2.append(idx[i + 1] + n)
	var clean := []
	clean.resize(Mesh.ARRAY_MAX)
	clean[Mesh.ARRAY_VERTEX] = v2
	clean[Mesh.ARRAY_NORMAL] = n2
	clean[Mesh.ARRAY_INDEX] = i2
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, clean)
	return out


## A thin curved strip on a cone around the model Y axis (radius r0 at y0 -> r1 at y1), angles a0..a1 from +Z toward
## +X, `thick` outward (orphreys, stoles).
static func _panel(key: String, y0: float, y1: float, r0: float, r1: float, a0: float, a1: float, cols: int,
		thick: float) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 3
	for i: int in rows:
		for j: int in cols:
			var q := []
			for dv: int in 2:
				for du: int in 2:
					var u := float(j + du) / float(cols)
					var t := float(i + dv) / float(rows)
					var a := lerpf(a0, a1, u)
					var r := lerpf(r0, r1, t) + thick
					q.append(Vector3(sin(a) * r, lerpf(y0, y1, t), cos(a) * r))
			for p: Vector3 in [q[0], q[2], q[1], q[1], q[2], q[3]]:
				st.add_vertex(p)
	st.index()
	st.generate_normals()
	return _cached(key, _outward_lathe(st.commit()))


## Tapered tube through `pts` (radii per point), one cached mesh (caps only at the ends).
static func _path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	# G-C (docs/art/gc_shadow_units.md): one continuous smooth tube (shared rings, 2 more sides) instead of a stack of
	# separate cylinders: rounder limbs for fewer vertices.
	var last := radii.size() - 1
	return _cached(key, ShadowGeo.tube(pts, radii, {"seg": seg + 2, "cap_start": radii[0] > 0.0,
		"cap_end": radii[last] > 0.0}))


static func _append_path(st: SurfaceTool, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int,
		xf: Transform3D) -> void:
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var extra: float = 0.015 if radii[i + 1] > 0.0 else 0.0
		var len_total := d.length() + extra
		var c := cyl(radii[i + 1], radii[i], len_total, seg, i == 0 or i == pts.size() - 2)
		st.append_from(c, 0, xf * Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))


## An ArrayMesh with one surface per material: parts = [[mesh, Transform3D, material], ...] (built once, cached).
static func _multi(key: String, parts: Array) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var groups: Dictionary = {}
	var order: Array = []
	for p: Array in parts:
		var mat: Material = p[2]
		if not groups.has(mat):
			groups[mat] = SurfaceTool.new()
			(groups[mat] as SurfaceTool).begin(Mesh.PRIMITIVE_TRIANGLES)
			order.append(mat)
		var m: Mesh = p[0]
		for s: int in m.get_surface_count():
			(groups[mat] as SurfaceTool).append_from(m, s, p[1])
	var out := ArrayMesh.new()
	for mat: Material in order:
		var st: SurfaceTool = groups[mat]
		st.index()
		st.commit(out)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	return _cached(key, out)


## A flat-shaded prism: the convex outline `poly` (x, y) extruded from z0 to z1 (front cap at z1).
static func _extrude(poly: PackedVector2Array, z0: float, z1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := poly.size()
	var ctr := Vector2.ZERO
	for p: Vector2 in poly:
		ctr += p
	ctr /= float(n)
	for k: int in n:
		var a := poly[k]
		var b := poly[(k + 1) % n]
		# front cap (+Z) and back cap (-Z), fanned from the centre
		for tri: Array in [[Vector3(ctr.x, ctr.y, z1), Vector3(b.x, b.y, z1), Vector3(a.x, a.y, z1), Vector3.BACK],
				[Vector3(ctr.x, ctr.y, z0), Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3.FORWARD]]:
			st.set_normal(tri[3])
			st.add_vertex(tri[0])
			st.set_normal(tri[3])
			st.add_vertex(tri[1])
			st.set_normal(tri[3])
			st.add_vertex(tri[2])
		# side
		var e := b - a
		var sn := Vector3(e.y, -e.x, 0).normalized()
		if sn.dot(Vector3(a.x - ctr.x, a.y - ctr.y, 0)) < 0.0:
			sn = -sn
		var q := [Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(b.x, b.y, z1), Vector3(a.x, a.y, z1)]
		for i: int in [0, 1, 2, 0, 2, 3]:
			st.set_normal(sn)
			st.add_vertex(q[i])
	var m := st.commit()
	return _fix_faces(m)


## Flips the triangles whose visible side disagrees with their stored normal (hand-built prisms).
static func _fix_faces(m: ArrayMesh) -> ArrayMesh:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for i: int in range(0, v.size(), 3):
		var vis := (v[i + 2] - v[i]).cross(v[i + 1] - v[i])
		if vis.dot(nr[i]) < 0.0:
			var t := v[i + 1]
			v[i + 1] = v[i + 2]
			v[i + 2] = t
	arr[Mesh.ARRAY_VERTEX] = v
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return out


const COFFIN := [Vector2(-0.055, 0.17), Vector2(0.055, 0.17), Vector2(0.085, 0.075), Vector2(0.05, -0.17),
	Vector2(-0.05, -0.17), Vector2(-0.085, 0.075)]


static func _coffin(scale: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in COFFIN:
		out.append(p * scale)
	return out


## The reliquary body (node space, origin = its centre, front = +Z): bone coffin, silver head and foot caps, the violet
## glow inside the front (seen when the lid opens).
static func _reliq_mesh() -> Mesh:
	const KEY := "gd_reliq"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var bone := palette(&"shadow_bone")
	var silver := palette(&"shadow_silver")
	var glow := palette(&"shadow_glow_mid")
	return _multi(KEY, [
		[_extrude(_coffin(1.0), -0.055, 0.052), Transform3D.IDENTITY, bone],
		[box(Vector3(0.125, 0.03, 0.12)), Transform3D(Basis.IDENTITY, Vector3(0, 0.165, 0)), silver],
		[box(Vector3(0.11, 0.03, 0.12)), Transform3D(Basis.IDENTITY, Vector3(0, -0.165, 0)), silver],
		[box(Vector3(0.18, 0.025, 0.118)), Transform3D(Basis.IDENTITY, Vector3(0, 0.075, 0)), silver],
		[_extrude(_coffin(0.78), 0.050, 0.054), Transform3D.IDENTITY, glow],
	])


## The lid (node space of the reliquary, hinged at LID_HINGE): a bone plate with a silver rim and the violet eye-window.
static func _lid_mesh_of() -> Mesh:
	const KEY := "gd_lid"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var bone := palette(&"shadow_bone")
	var silver := palette(&"shadow_silver")
	var glow := palette(&"shadow_glow_mid")
	return _multi(KEY, [
		[_extrude(_coffin(1.03), 0.054, 0.074), Transform3D.IDENTITY, bone],
		[torus(0.03, 0.045, 8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5).scaled(Vector3(1.0, 1.0, 1.0)) *
			Basis.from_scale(Vector3(0.9, 1.0, 1.3)), Vector3(0, 0.03, 0.076)), silver],
		[sphere(0.03, 8, 4), Transform3D(Basis.from_scale(Vector3(0.75, 1.25, 0.4)), Vector3(0, 0.03, 0.078)), glow],
	])


## The taper-staff in the staff node's space (grip at the origin, up = +Y): an iron shaft, silver knops and a crescent
## cradle, a silver cup, the bone taper with wax drips, the violet flame (the glow point).
static func _staff_mesh() -> Mesh:
	const KEY := "gd_staff"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var iron := palette(&"shadow_iron")
	var silver := palette(&"shadow_silver")
	var bone := palette(&"shadow_bone")
	var glow := palette(&"shadow_glow_mid")
	var shaft := SurfaceTool.new()
	_append_path(shaft, PackedVector3Array([Vector3(0, -1.12, -0.01), Vector3(0, 0.0, 0.0), Vector3(0, 0.84, 0.0)]),
		PackedFloat32Array([0.018, 0.024, 0.022]), 6, Transform3D.IDENTITY)
	shaft.index()
	return _multi(KEY, [
		[shaft.commit(), Transform3D.IDENTITY, iron],
		[cyl(0.035, 0.035, 0.06, 6), Transform3D(Basis.IDENTITY, Vector3(0, 0.10, 0)), silver],
		[cyl(0.02, 0.04, 0.10, 6), Transform3D(Basis.IDENTITY, Vector3(0, 0.80, 0)), silver],
		[cyl(0.07, 0.03, 0.06, 8), Transform3D(Basis.IDENTITY, Vector3(0, 0.88, 0)), silver],
		[cyl(0.03, 0.034, 0.14, 6), Transform3D(Basis.IDENTITY, Vector3(0, 0.98, 0)), bone],
		[sphere(0.018, 5, 3), Transform3D(Basis.from_scale(Vector3(1.0, 1.6, 1.0)), Vector3(0.028, 0.95, 0.01)), bone],
		[sphere(0.014, 5, 3), Transform3D(Basis.from_scale(Vector3(1.0, 1.8, 1.0)), Vector3(-0.02, 0.97, 0.022)), bone],
		[cyl(0.0, 0.055, 0.20, 7), Transform3D(Basis.IDENTITY, FLAME + Vector3(0, 0.10, 0)), glow],
		[sphere(0.05, 7, 4), Transform3D(Basis.from_scale(Vector3(1.0, 1.1, 1.0)), FLAME + Vector3(0, 0.03, 0)), glow],
	])


# ================================================================ VFX hooks (world space)

## Where the Blood Tithe tether and the attack bolt start: the taper flame (world).
func get_tether_origin() -> Vector3:
	if _staff and _staff.is_inside_tree():
		return _staff.global_transform * (FLAME + Vector3(0, 0.07, 0))
	return global_position + Vector3.UP * 2.2


## The reliquary's eye-window (world): the Vigil wisp flies here; the Passage rift opens around the Deacon.
func get_reliquary_point() -> Vector3:
	if _reliq and _reliq.is_inside_tree():
		return _reliq.global_transform * Vector3(0, 0.03, 0.08)
	return global_position + Vector3.UP * 1.9


## Vigil: an ally's soul reached the reliquary (the VFX wisp landed): a short flare of its window.
func play_vigil() -> void:
	if not _dead:
		_vigil_t = 0.5


## Blood Tithe channel state from gameplay: true holds the tithe pose until false (play_cast(&"blood_tithe") also works:
## each call extends the hold by TITHE_HOLD).
func set_channeling(on: bool) -> void:
	_channel = on
	if on and not _dead and not (_action == &"cast" and _cast_id == &"blood_tithe"):
		play_cast(&"blood_tithe")


func play_cast(spell_id: StringName) -> void:
	if spell_id == &"blood_tithe" and not _dead and _action == &"cast" and _cast_id == &"blood_tithe":
		# still channelling: extend the hold, never restart the raise
		_tithe_end = maxf(_tithe_end, _action_t + TITHE_HOLD + TITHE_IN)
		return
	super(spell_id)
	if spell_id == &"blood_tithe":
		_tithe_end = TITHE_IN + TITHE_HOLD + TITHE_IN


# ================================================================ motion

func _after_ready() -> void:
	super()
	_write_flame(FLAME_GLOW, true)
	_write_reliq(RELIQ_GLOW, true)


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"deacon_bolt":
		return super(prev, t)
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.06, RELEASE + 0.03, ATTACK_LEN, 8.0, -32.0) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.06, RELEASE + 0.04, ATTACK_LEN, -5.0, 9.0) * DEG,
		_k3(t, 0.0, 0.06, RELEASE + 0.04, ATTACK_LEN, 8.0, -10.0) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _k3(t, 0.0, 0.06, RELEASE + 0.04, ATTACK_LEN, -0.03, 0.07)))
	if _tier == 0:
		rot(P_HEAD, Vector3(_k3(t, 0.0, 0.06, RELEASE + 0.04, ATTACK_LEN, -4.0, 6.0) * DEG, 0, 0))
	_flare = _k3(t, 0.0, RELEASE, RELEASE + 0.05, ATTACK_LEN, 0.6, 1.4)
	if prev < RELEASE and t >= RELEASE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	if spell == &"blood_tithe":
		if _channel:
			_tithe_end = maxf(_tithe_end, t + TITHE_IN + 0.05)
		var w: float = smoothstep(0.0, TITHE_IN, t) * (1.0 - smoothstep(_tithe_end - TITHE_IN, _tithe_end, t))
		var beat: float = sin(t * 5.0)
		rot(P_ARM_R, Vector3((-58.0 + 3.0 * beat) * DEG * w, 0, 6.0 * DEG * w))
		rot(P_CHEST, Vector3(5.0 * DEG * w, 0, 0))
		rot(P_ARM_L, Vector3(-6.0 * DEG * w, 0, 0))
		if _tier == 0:
			rot(P_HEAD, Vector3(9.0 * DEG * w, 0, 0))
		_flare = 0.8 * w + 0.25 * w * (0.5 + 0.5 * beat)
		if not _fired and t >= TITHE_IN * 0.8:
			_fired = true
			if _spark and _tier < 2:
				_spark.restart()
			cast_released.emit(&"blood_tithe", get_tether_origin())
		return _tithe_end
	# umbral_passage (and any other id): the long raise
	var up: float = smoothstep(0.0, 0.45, t) * (1.0 - smoothstep(2.2, PASSAGE_LEN, t))
	var sway: float = sin(t * 3.2) * up
	rot(P_ARM_R, Vector3((-118.0 + 4.0 * sway) * DEG * up, 0, -8.0 * DEG * up))
	rot(P_ARM_L, Vector3(-60.0 * DEG * up, 0, -38.0 * DEG * up))
	pos(P_ARM_L, Vector3(-0.04 * up, 0, 0.04 * up))
	rot(P_CHEST, Vector3(-9.0 * DEG * up, 0, 0))
	pos(P_ROOT, Vector3(0, 0.07 * up + 0.015 * sway, 0))
	if _tier == 0:
		rot(P_HEAD, Vector3(-14.0 * DEG * up, 0, 0))
	_flare = 1.6 * up
	_open = smoothstep(0.35, 0.7, t) * (1.0 - smoothstep(2.15, 2.45, t))
	_rglow = 2.4 * _open
	if not _updraft_fired and t >= 0.3:
		_updraft_fired = true
		if _updraft and _tier < 2:
			_updraft.restart()
	if not _fired and t >= PASSAGE_LEN - 0.05:
		_fired = true
		cast_released.emit(&"umbral_passage", global_position)
	return PASSAGE_LEN


func _on_action_event(ev: StringName) -> void:
	super(ev)
	match ev:
		&"release":
			if _spark and _tier < 2:
				_spark.restart()
			cast_released.emit(&"attack", get_tether_origin())
		&"cast_start":
			_fired = false
			_updraft_fired = false
		&"attack_end", &"cast_end":
			_flare = 0.0
			_channel = false
		&"death_glow_off":
			_flare = 0.0
			_rglow = 0.0
			if _motes:
				_motes.emitting = false


## A slow processional glide: the robe hides the legs, a small sway, the staff hand steady, the heart hand still.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_ARM_R, Vector3(-8.0 * DEG * s * w, 0, 0))
	rot(P_ARM_L, Vector3(18.0 * DEG * s * w, 0, 0))   # cancels the kit's arm swing: the hand stays on the heart
	if _tier > 0:
		return
	rot(P_ROOT, Vector3(2.0 * DEG * w, 0, 1.5 * DEG * s * w))
	rot(P_HIPS, Vector3(0, 4.0 * DEG * s * w, 0))
	rot(P_CHEST, Vector3(0, -3.0 * DEG * s * w, 0))


func _extra_process(dt: float) -> void:
	super(dt)
	if _staff == null:
		return
	if _dead:
		_death_extras()
		return
	if _action == &"":
		_flare = move_toward(_flare, 0.0, dt * 3.0)
		_rglow = move_toward(_rglow, 0.0, dt * 3.0)
		_open = move_toward(_open, 0.0, dt * 2.5)
	if _vigil_t > 0.0:
		_vigil_t -= dt
	var vig: float = 2.0 * clampf(_vigil_t / 0.5, 0.0, 1.0)
	var flick: float = 0.0
	if _tier == 0:
		flick = 0.12 * sin(_t * 9.0) + 0.07 * sin(_t * 5.3 + 1.7)
	_write_flame(FLAME_GLOW * (1.0 + flick + 1.5 * _flare), false)
	_write_reliq(RELIQ_GLOW * (1.0 + 0.15 * sin(_t * 1.9) + _rglow + vig), false)
	if _tier >= 2:
		return
	# The staff: kept upright against the arm / chest / root pitch (it swings with them only a little), aimed forward
	# during the tithe (levelled at the ally) and the bolt.
	var tilt: Vector3 = _off_rot[P_ARM_R] + _off_rot[P_CHEST] + _off_rot[P_ROOT]
	var aim: float = 0.0
	if _action == &"cast" and _cast_id == &"blood_tithe":
		aim = 42.0 * DEG * smoothstep(0.0, TITHE_IN, _action_t) * (1.0 - smoothstep(_tithe_end - TITHE_IN, _tithe_end, _action_t))
	elif _action == &"attack":
		aim = _k3(_action_t, 0.0, 0.06, RELEASE + 0.03, ATTACK_LEN, -6.0, 26.0) * DEG
	var target := Vector3(-tilt.x * 0.9 + aim, 0.0, -tilt.z * 0.9)
	_staff_rot = _staff_rot.lerp(target, clampf(dt * 14.0, 0.0, 1.0))
	if _staff_rot.distance_squared_to(_staff_written) > 0.00002:
		_staff_written = _staff_rot
		_staff.rotation = _staff_rot
	# The reliquary floats: a slow bob and sway, lagging behind the body's pitch and roll; it rises during the passage.
	var body: Vector3 = _off_rot[P_CHEST] + _off_rot[P_ROOT]
	var passage: float = _open
	var bob := Vector3(0.012 * sin(_t * 1.3 + 0.4), 0.035 * sin(_t * 1.7) + 0.16 * passage, 0.0)
	_reliq_pos = _reliq_pos.lerp(bob - Vector3(0, 0, body.x * 0.25), clampf(dt * 5.0, 0.0, 1.0))
	_reliq_rot = _reliq_rot.lerp(Vector3(-body.x * 0.6 + 0.08 * sin(_t * 1.1), 0.12 * sin(_t * 0.7) + 1.4 * passage * sin(_t * 1.5),
		-body.z * 0.6 + 0.06 * sin(_t * 1.3 + 1.0)), clampf(dt * 4.0, 0.0, 1.0))
	var key := _reliq_pos + _reliq_rot * 0.37
	if key.distance_squared_to(_reliq_written) > 0.000004:
		_reliq_written = key
		_reliq.position = RELIQ - _chest_origin + _reliq_pos
		_reliq.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(18.0), deg_to_rad(6.0)) + _reliq_rot
	_write_lid(_open)


## Death: the reliquary drops to the ground beside her and its lid snaps shut; the staff tips with the body.
func _death_extras() -> void:
	var t: float = _death_t
	_write_flame(FLAME_GLOW * (1.0 - smoothstep(0.05, 0.4, t)) * (1.0 + 1.5 * smoothstep(0.0, 0.1, t)), false)
	_write_reliq(RELIQ_GLOW * (1.0 - smoothstep(0.2, 0.5, t)), false)
	_write_lid(_open * (1.0 - smoothstep(0.0, 0.15, t)))
	var chest := _reliq.get_parent() as Node3D
	if chest == null or not chest.is_inside_tree():
		return
	var start: Vector3 = chest.global_transform * (RELIQ - _chest_origin)
	var ground: Vector3 = global_transform * Vector3(-0.42, 0.14, -0.18)
	var f: float = _ease_in(clampf(t / 0.45, 0.0, 1.0))
	var bounce: float = 0.05 * sin(PI * clampf((t - 0.45) / 0.2, 0.0, 1.0))
	var at: Vector3 = start.lerp(ground, f) + Vector3.UP * bounce
	_reliq.position = chest.global_transform.affine_inverse() * at
	_reliq.rotation = Vector3(deg_to_rad(-8.0 - 70.0 * f), deg_to_rad(18.0), deg_to_rad(6.0 + 20.0 * f))


func _on_revive() -> void:
	super()
	_flare = 0.0
	_rglow = 0.0
	_open = 0.0
	_vigil_t = 0.0
	_channel = false
	_staff_rot = Vector3.ZERO
	_staff_written = Vector3(99, 99, 99)
	_reliq_pos = Vector3.ZERO
	_reliq_rot = Vector3.ZERO
	_reliq_written = Vector3(99, 99, 99)
	if _staff:
		_staff.rotation = Vector3.ZERO
	if _reliq:
		_reliq.position = RELIQ - _chest_origin
		_reliq.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(18.0), deg_to_rad(6.0))
	_write_lid(0.0)
	if _motes:
		_motes.emitting = true
	_write_flame(FLAME_GLOW, true)
	_write_reliq(RELIQ_GLOW, true)


# ================================================================ glow / lid writes (own_glow; quantised)

func _write_flame(v: float, force: bool) -> void:
	v = snappedf(v * glow_level() * glow_gain if not _dead else v * glow_gain, 0.05)
	if (v == _flame_v and not force) or _staff == null:
		return
	_flame_v = v
	_staff.set_instance_shader_parameter(&"glow_boost", v)


func _write_reliq(v: float, force: bool) -> void:
	v = snappedf(v * glow_level() * glow_gain if not _dead else v * glow_gain, 0.05)
	if (v == _reliq_v and not force) or _reliq_body == null:
		return
	_reliq_v = v
	_reliq_body.set_instance_shader_parameter(&"glow_boost", v)
	_lid_mesh.set_instance_shader_parameter(&"glow_boost", v)


func _write_lid(k: float) -> void:
	k = snappedf(k, 0.01)
	if k == _lid_written or _lid == null:
		return
	_lid_written = k
	_lid.rotation = Vector3(0, -deg_to_rad(115.0) * k, 0)
