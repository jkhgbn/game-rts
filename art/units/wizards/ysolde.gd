extends WizardModel
## Ysolde, the Nature Wizard (kingdom-nature.md 7.2; built 8.V3, polished A.14). A young forest-queen read from the
## RTS camera by a colour split the grass can't swallow: a dark flowing BARK gown (painted furrows with glowing sap,
## a mossy hem, a train and trailing roots behind her) under a team-green leaf bodice, leaf over-skirt, a star-shaped
## leaf mantle and a curved leaf cape. Auburn swept locks around a painted face (FaceKit, 5 expressions), and a pair of wide
## living ANTLERS (1.5 m tip to tip, wider than the mantle) with pink blossoms and glowing hearts on every tine.
## Her living staff is gnarled wood wound by a vine, sap flowing up into a cradle of three curled prongs that holds
## the glowing seed (3.0) inside a closed tulip of 6 petals; the tulip opens into a flower on casts.
## Casts (6.5): thornburst (staff raised high then driven into the ground, a ring of thorn chips bursts from its
## foot), wild_bloom (arms spread, staff overhead, full bloom, the crown blazes, petals burst from the seed),
## call_the_thicket (staff planted, she bends to touch the ground and sweeps her hand up; green life rises in front).
## Extras: gown sway and cape billow on the walk, staff levelled at the target on the auto-attack, level-up
## pirouette with a petal burst, a gasp and reaching hand before the fall (the staff drops, leaves burst), and
## (close camera only) idle fidgets: she lets the seed bloom over her palm, listens to the forest, twirls the staff.
## Glow points: seed 3.0, crown blossom hearts + irises (vertex-colour glow on the FaceKit Face node). 5 petals drift from the crown.
## Materials: hero-only art/units/wizards/ysolde_*.tres (ysolde_grove.gdshader: bark, sap, moss, petals; the
## *_cloth ones are recoloured by set_team_color) + the Nature palette (leaves, glows).
## Draw instances: 5 merged pivots + Face, Cape, StaffMesh, Seed, Petals + 3 particles + blob = 14, 1 light.
## Hooks: those of CharacterModel / WizardModel, unchanged.

const YS_DIR := "res://art/units/wizards/"
const GLOW := Color(0.75, 1.0, 0.40)
const PINK := Color(0.96, 0.60, 0.76)
const GRIP := Vector3(0.52, 1.04, 0.26)       # model space: the right fist, pivot of the staff
const SEED_UP := 1.46                          # seed centre above the grip (staff space)
const FOOT_DOWN := 1.0                         # staff foot below the grip
const SHOULDER_L := Vector3(-0.42, 1.50, 0.0)
const SHOULDER_R := Vector3(0.42, 1.50, 0.0)
const HAND_L := Vector3(-0.50, 1.04, 0.10)
const CAPE_AT := Vector3(0.0, 1.56, -0.02)
const CAPE_TILT := 4.0
const PETALS := 6
const IDLE_IDS: Array[StringName] = [&"idle_bloom", &"idle_listen", &"idle_twirl"]

static var _own_mats: Dictionary = {}
static var _meshes: Dictionary = {}
static var _pms: Dictionary = {}
static var _draws: Dictionary = {}

var _staff: Node3D                 # keep_separate: pivots at the fist, tilted / spun by poses
var _bloom: Node3D                 # seed + petals (the bobbing node)
var _petals: MultiMeshInstance3D
var _head_glow: MeshInstance3D     # the Face node (irises + crown blossom hearts glow)
var _face: FaceRig                 # painted face + auburn locks + blossom tie (FaceKit)
var _expr: StringName = &"neutral"  # requested by set_expression (kept for a call before _ready)
var _cape: MeshInstance3D
var _drift: GPUParticles3D
var _fx: GPUParticles3D            # one pre-built one-shot emitter for every burst (mode swapped per use)

# Per-frame targets, written by the poses, reset at the end of _wizard_process.
var _open: float = 0.0             # tulip openness (0 bud, 1 flower)
var _staff_pitch: float = 0.0      # rad, + = top forward
var _staff_roll: float = 0.0       # rad, - = top outward (+X)
var _staff_spin: float = 0.0       # rad about the shaft
var _staff_keep: float = 1.0       # 1 = the staff stays upright whatever the arm does
var _crown: float = 1.0            # crown hearts + eye bar boost
var _cape_kick: float = 0.0        # extra cape lift (deg)
# Written state (only touch nodes when something changed).
var _open_cur: float = 0.0
var _open_written: float = -1.0
var _staff_written: Vector3 = Vector3(99, 99, 99)
var _crown_written: float = -1.0
var _cape_written: float = 999.0
var _fx_fired: bool = false
var _idle_left: float = 6.0
var _idle_i: int = 0


static func _mat(name: StringName) -> Material:
	if not _own_mats.has(name):
		_own_mats[name] = load(YS_DIR + String(name) + ".tres")
	return _own_mats[name]


# ================================================================ parts

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := _mat(&"ysolde_cloth")
	var dark := _mat(&"ysolde_cloth_dark")
	var skin := _mat(&"ysolde_skin")
	var leaf := NatureModel.nature(&"nature_leaf")
	var leaf_dark := NatureModel.nature(&"nature_leaf_dark")

	# ---- Hips: the flowing bark gown (+ train and trailing roots), leaf over-skirt around the sides and back.
	add_part(hips, _gown_mesh(), _mat(&"ysolde_bark"), Vector3.ZERO)
	var over: Array = []
	var over_dark: Array = []
	for i: int in 9:
		var a := (48.0 + 33.0 * float(i)) * DEG            # 48..312 deg: the front stays open on the bark
		var out := Vector3(sin(a), 0, cos(a))
		var long := i % 2 == 0
		var l := 0.62 if long else 0.50
		var xf := NatureModel.leaf_xform(out * 0.24 + Vector3(0, 1.02, 0), out, Vector3(0.27 if long else 0.24, 0.05, l),
				-66.0 if long else -58.0)
		(over if long else over_dark).append([NatureModel.leaf_mesh(), xf])
	# Long leaves in the DARK team green, short ones light (Art Lab R3: the mid-body read sat at the grass value;
	# a dark skirt under the light bodice / mantle splits her from the meadow, both still team-coloured).
	add_part(hips, _bake("ys14_over", over), dark, Vector3.ZERO)
	add_part(hips, _bake("ys14_over_dark", over_dark), cloth, Vector3.ZERO)

	# ---- Chest: leaf bodice, bark belt with a blossom brooch, star-shaped leaf mantle, curved leaf cape.
	add_part(chest, cyl(0.25, 0.215, 0.54, 12), cloth, Vector3(0, 1.28, 0))
	add_part(chest, torus(0.20, 0.265, 14), NatureModel.nature(&"nature_bark"), Vector3(0, 1.03, 0))
	add_part(chest, _bake("ys14_brooch", _flower(Transform3D(Basis(Vector3.RIGHT, 80.0 * DEG).scaled(Vector3.ONE * 0.9),
			Vector3(0, 1.05, 0.255)))), _mat(&"ysolde_blossom"), Vector3.ZERO)
	add_part(chest, NatureModel.leaf_ring_mesh(9, 0.13, Vector3(0.25, 0.05, 0.44), -26.0), cloth, Vector3(0, 1.56, 0))
	add_part(chest, NatureModel.leaf_ring_mesh(9, 0.12, Vector3(0.20, 0.05, 0.30), -10.0, 20.0), dark, Vector3(0, 1.60, 0))
	_cape = add_part(chest, _cape_mesh(), null, CAPE_AT, Vector3(CAPE_TILT, 0, 0), Vector3.ONE, true, "Cape")

	# ---- Head: neck, pale face, antler crown. Hair (auburn swept locks, blossom tie) + the painted face: the FaceKit
	# Face node below (face rework 2026-09-28).
	add_part(head, cyl(0.065, 0.075, 0.16, 8), skin, Vector3(0, 1.63, 0.0))
	add_part(head, sphere(0.205), skin, Vector3(0, 1.77, 0.05), Vector3.ZERO, Vector3(0.95, 1.05, 0.95))
	# a wreath of small dark leaves lying on the hair (breaks the round top read from the high camera)
	add_part(head, NatureModel.leaf_ring_mesh(9, 0.15, Vector3(0.12, 0.03, 0.22), 4.0, 10.0), leaf,
			Vector3(0, 1.95, -0.05))
	add_part(head, torus(0.185, 0.225, 14), _mat(&"ysolde_antler"), Vector3(0, 1.915, -0.01), Vector3(-8, 0, 0))
	var crown := _crown_layout()
	add_part(head, _bake("ys14_antlers", crown["antlers"]), _mat(&"ysolde_antler"), Vector3.ZERO)
	add_part(head, _bake("ys14_crown_leaf", crown["leaves"]), leaf, Vector3.ZERO)
	add_part(head, _bake("ys14_crown_leaf_dark", crown["leaves_dark"]), leaf_dark, Vector3.ZERO)
	var fl: Array = []
	for xf: Transform3D in crown["tips"]:
		fl.append_array(_flower(xf))
	add_part(head, _bake("ys14_crown_blossoms", fl), _mat(&"ysolde_blossom"), Vector3.ZERO)
	# The 8 blossom hearts glow through their vertex alpha on the Face node (the old HeadGlow node: eye bar + hearts).
	_face = FaceKit.attach(self, head, "ysolde", _face_style())
	_face.set_expression(_expr)
	_face.set_meta(&"own_glow", true)   # irises + blossom hearts glow with _crown, written below
	_head_glow = _face

	# ---- Arms: team-dark leaf sleeves, leaf cuffs, hands; the right fist holds the staff.
	_arm(arm_l, SHOULDER_L, HAND_L, "l")
	_arm(arm_r, SHOULDER_R, GRIP, "r")

	# ---- Staff (keep_separate so poses can tilt / spin it at the fist): one mesh + the seed in its tulip.
	_staff = Node3D.new()
	_staff.name = "Staff"
	_staff.set_meta(&"keep_separate", true)
	_staff.position = GRIP - model_origin(arm_r)
	arm_r.add_child(_staff)
	var sm := MeshInstance3D.new()
	sm.name = "StaffMesh"
	sm.mesh = _staff_mesh()
	sm.set_meta(&"keep_separate", true)
	_staff.add_child(sm)
	_bloom = Node3D.new()
	_bloom.name = "Bloom"
	_bloom.position = Vector3(0, SEED_UP, 0)
	_staff.add_child(_bloom)
	var seed := MeshInstance3D.new()
	seed.name = "Seed"
	seed.mesh = sphere(0.13)
	seed.scale = Vector3(1.0, 1.25, 1.0)
	seed.material_override = NatureModel.nature(&"nature_glow_hero")
	seed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seed.set_meta(&"own_glow", true)
	seed.set_meta(&"keep_separate", true)
	_bloom.add_child(seed)
	_petals = MultiMeshInstance3D.new()
	_petals.name = "Petals"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = NatureModel.leaf_mesh()
	mm.instance_count = PETALS
	_petals.multimesh = mm
	_petals.material_override = _mat(&"ysolde_blossom")
	_petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_petals.set_meta(&"keep_separate", true)
	_petals.position = Vector3(0, -0.07, 0)
	_bloom.add_child(_petals)
	_write_petals(0.0)
	_orb = seed
	_bob = _bloom
	_bob_rest = _bloom.position
	_light = OmniLight3D.new()
	_light.name = "SeedLight"
	_light.light_color = GLOW
	_light.light_energy = light_energy
	_light.light_specular = 0.2
	_light.omni_range = 4.5
	_light.shadow_enabled = false
	_light.position = _bloom.position
	_staff.add_child(_light)
	# Looping total 8 (Art Lab B6p, art-units 8 wizard): 3 seed motes + 5 crown petals (were 6 + 8).
	var motes := make_motes(GLOW, 3, 1.6, 0.14, 0.30, 0.05)
	motes.name = "SeedMotes"
	motes.position = _bloom.position
	_staff.add_child(motes)

	# ---- FX: petals drifting from the crown (looping, < 45 m), one pre-built one-shot burst for everything else.
	_drift = NatureModel.make_petals(PINK, 5, 3.2, 0.55, 0.35, 0.13)
	_drift.name = "CrownPetals"
	_drift.position = Vector3(0, 2.30, -0.05) - model_origin(head)
	head.add_child(_drift)
	_fx = GPUParticles3D.new()
	_fx.name = "CastFx"
	_fx.amount = 18
	_fx.one_shot = true
	_fx.emitting = false
	_fx.explosiveness = 0.9
	_fx.randomness = 0.3
	_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6))
	# Rest mode = thornburst, the default cast (_fire sets the mode before every restart, so this is only the idle state).
	_fx.process_material = _pm(&"thorns")
	_fx.draw_pass_1 = _draw(false)
	# Pre-build every burst kind's shared resources now (Art Lab B10: no material created on the first cast).
	for k: StringName in [&"bloom", &"thicket", &"death"]:
		_pm(k)
	_draw(true)
	$Fx.add_child(_fx)
	ensure_shadow_blob(0.62)


func _after_ready() -> void:
	_idle_left = 5.0 + 6.0 * fmod(_phase_off, 1.0)


## Sleeve capsule, a cuff of 5 leaves at the wrist, hand.
func _arm(pivot: Node3D, shoulder: Vector3, hand: Vector3, side: String) -> void:
	var d := hand - shoulder
	var e := Basis(Quaternion(Vector3.DOWN, d.normalized())).get_euler() / DEG
	add_part(pivot, capsule(0.085, d.length() + 0.10), _mat(&"ysolde_cloth_dark"), shoulder + d * 0.5, e)
	add_part(pivot, sphere(0.105), _mat(&"ysolde_cloth_dark"), shoulder + Vector3(0, 0.02, 0))
	var wrist := shoulder + d * 0.80
	var cuff: Array = []
	for k: int in 5:
		var a := TAU * float(k) / 5.0 + 0.3
		var out := Vector3(sin(a), 0, cos(a))
		cuff.append([NatureModel.leaf_mesh(), NatureModel.leaf_xform(wrist + out * 0.05, out, Vector3(0.12, 0.03, 0.22), -52.0)])
	add_part(pivot, _bake("ys14_cuff_" + side, cuff), _mat(&"ysolde_cloth"), Vector3.ZERO)
	add_part(pivot, sphere(0.085), _mat(&"ysolde_skin"), hand)


# ================================================================ shared meshes (built once per game)

## One mesh (vertex + normal + index) from [mesh, Transform3D] pairs, cached by key.
static func _bake(key: String, parts: Array) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays(parts))
	_meshes[key] = am
	return am


static func _arrays(parts: Array) -> Array:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for p: Array in parts:
		var m: Mesh = p[0]
		var xf: Transform3D = p[1]
		var nb := xf.basis.inverse().transposed()
		var arr := m.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var b0 := verts.size()
		for j: int in v.size():
			verts.append(xf * v[j])
			norms.append((nb * nr[j]).normalized())
		if ix.is_empty():
			for j: int in v.size():
				idx.append(b0 + j)
		else:
			for j: int in ix.size():
				idx.append(b0 + ix[j])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	return arrays


## [cylinder, transform] from a to b (radius ra at a, rb at b); sx / sz flatten it across the axis.
static func _seg(a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6, sx: float = 1.0, sz: float = 1.0) -> Array:
	if b.y < a.y:   # keep the axis pointing up (Quaternion(UP, -UP) is degenerate)
		var t := a
		a = b
		b = t
		var tr := ra
		ra = rb
		rb = tr
	var d := b - a
	var l := d.length()
	var bs := Basis(Quaternion(Vector3.UP, d / l)).scaled_local(Vector3(sx, l, sz))
	return [cyl(rb, ra, 1.0, seg), Transform3D(bs, (a + b) * 0.5)]


## A 5-petal blossom in the frame xf (petals open around its +Y).
static func _flower(xf: Transform3D) -> Array:
	var out: Array = []
	for k: int in 5:
		var a := TAU * float(k) / 5.0
		var o := Vector3(sin(a), 0, cos(a))
		out.append([NatureModel.leaf_mesh(), xf * NatureModel.leaf_xform(o * 0.02, o, Vector3(0.105, 0.035, 0.135), 26.0)])
	return out


## The flowing gown: a lathe from the waist to a hem cut into 12 bark tongues, a train sweeping out behind,
## slow folds that twist as they fall. Model space (the Hips pivot moves it).
static func _gown_point(a: float, v: float) -> Vector3:
	var back := maxf(0.0, -cos(a))
	var r := 0.245 + 0.35 * pow(v, 1.3) + 0.27 * back * back * v * v
	r += 0.02 * sin(7.0 * a + v * 2.5) * v
	var hem := 0.025 + 0.08 * pow(absf(sin(6.0 * a)), 0.7) * (1.0 - 0.75 * back)
	return Vector3(sin(a) * r, lerpf(1.06, hem, v), cos(a) * r)


static func _gown_mesh() -> ArrayMesh:
	const KEY := "ys14_gown"
	if _meshes.has(KEY):
		return _meshes[KEY]
	const S := 36
	const R := 10
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for j: int in R + 1:
		var v := float(j) / float(R)
		for i: int in S + 1:
			var a := TAU * float(i) / float(S)
			verts.append(_gown_point(a, v))
			var du := _gown_point(a + 0.01, v) - _gown_point(a - 0.01, v)
			var dv := _gown_point(a, minf(v + 0.02, 1.0)) - _gown_point(a, maxf(v - 0.02, 0.0))
			norms.append(dv.cross(du).normalized())
	for j: int in R:
		for i: int in S:
			var q0 := j * (S + 1) + i
			var q1 := q0 + 1
			var q2 := q0 + S + 2
			var q3 := q0 + S + 1
			idx.append_array(PackedInt32Array([q0, q1, q3, q1, q2, q3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[KEY] = am
	return am


## Antlers, crown leaves and the blossom frames (model space), computed once.
static func _crown_layout() -> Dictionary:
	if _meshes.has("ys14_crown_layout"):
		return _meshes["ys14_crown_layout"]
	var antlers: Array = []
	var leaves: Array = []
	var leaves_dark: Array = []
	var tips: Array[Transform3D] = []
	for s: float in [-1.0, 1.0]:
		var b0 := Vector3(0.13 * s, 1.93, -0.03)
		var p1 := Vector3(0.32 * s, 2.06, -0.08)
		var p2 := Vector3(0.55 * s, 2.17, -0.14)
		var p3 := Vector3(0.76 * s, 2.36, -0.16)
		var t0a := b0.lerp(p1, 0.55)
		var t0 := Vector3(0.36 * s, 2.13, 0.15)
		var t1 := Vector3(0.38 * s, 2.40, -0.04)
		var t2 := Vector3(0.60 * s, 2.47, -0.29)
		antlers.append(_seg(b0, p1, 0.060, 0.050, 7))
		antlers.append(_seg(p1, p2, 0.050, 0.040, 7))
		antlers.append(_seg(p2, p3, 0.040, 0.020, 6))
		antlers.append(_seg(t0a, t0, 0.034, 0.014))
		antlers.append(_seg(p1, t1, 0.038, 0.016))
		antlers.append(_seg(p2, t2, 0.034, 0.015))
		antlers.append([sphere(0.052, 8, 4), Transform3D(Basis(), p1)])
		antlers.append([sphere(0.042, 8, 4), Transform3D(Basis(), p2)])
		# blossom frames: facing up and a little along the tine
		var ends: Array = [[p3, p3 - p2, 1.5], [t1, t1 - p1, 1.35], [t2, t2 - p2, 1.3], [t0, t0 - t0a, 1.05]]
		for e: Array in ends:
			var f := ((e[1] as Vector3).normalized() + Vector3.UP * 1.2).normalized()
			tips.append(Transform3D(Basis(Quaternion(Vector3.UP, f)).scaled(Vector3.ONE * float(e[2])), e[0]))
		# leaves sprouting along the beams (outward, alternating fresh / dark)
		var along: Array = [[b0.lerp(p1, 0.5), 0.35, false], [p1.lerp(p2, 0.5), -0.45, true], [p2.lerp(p3, 0.45), 0.5, false],
			[p1.lerp(t1, 0.5), -0.9, true]]
		for l: Array in along:
			var o := Vector3(s, 0, 0).rotated(Vector3.UP, float(l[1]) * s)
			var xf := NatureModel.leaf_xform(l[0], o, Vector3(0.11, 0.03, 0.21), -18.0)
			(leaves_dark if l[2] else leaves).append([NatureModel.leaf_mesh(), xf])
	# a small tiara of three fresh leaves at the front of the circlet
	for k: int in 3:
		var yaw := (float(k) - 1.0) * 0.45
		var o := Vector3(sin(yaw), 0, cos(yaw))
		leaves.append([NatureModel.leaf_mesh(), NatureModel.leaf_xform(Vector3(0, 1.93, 0.0) + o * 0.20, o,
				Vector3(0.09, 0.03, 0.20 if k == 1 else 0.16), 62.0 if k == 1 else 50.0)])
	var d := {"antlers": antlers, "leaves": leaves, "leaves_dark": leaves_dark, "tips": tips}
	_meshes["ys14_crown_layout"] = d
	return d


# ================================================================ face / expressions

## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout"; aliases
## angry / sad / cast / happy). Unknown ids = neutral. Safe before _ready and any number of times.
func set_expression(id: StringName) -> void:
	_expr = FaceKit.canonical(id)
	if _face:
		_face.set_expression(_expr)


func get_expression() -> StringName:
	return _expr


## Ysolde's face style: a young forest-queen: leaf-green irises with a soft glow (her old eye-bar read), dark lashes,
## auburn brows, freckles over the nose and cheeks, rosy blush, a warm closed smile at rest. Hair (hair plan 3): the
## baked block became auburn swept locks with copper tips: 2 front locks per side falling over the leaf mantle in front
## of the shoulders (the 25 m read: auburn on green), a fringe swept under the wreath, a back fall, and one front lock
## tied with a pink blossom. One vertex-coloured surface on the Face node.
static func _face_style() -> Dictionary:
	if _meshes.has("ys_face_style"):
		return _meshes["ys_face_style"]
	var hair := Color(0.50, 0.19, 0.08)
	var tip := Color(0.92, 0.55, 0.26)
	var pink := Color(0.96, 0.60, 0.76)
	var fc := Vector3(0, 1.77, 0.05)
	var st := {
		"canvas": FaceKit.canvas(fc, 0.20, sphere(0.205), Vector3(0.95, 1.05, 0.95)),
		"palette": {"skin": Color(0.93, 0.78, 0.64), "sclera": Color(0.98, 0.96, 0.90), "iris_in": Color(0.78, 1.0, 0.45),
			"iris_out": Color(0.14, 0.40, 0.10), "iris_glow": 0.4, "pupil": Color(0.06, 0.10, 0.04), "highlight": Color(1, 1, 0.94),
			"lash": Color(0.18, 0.08, 0.05), "brow": Color(0.48, 0.19, 0.09), "blush": Color(0.95, 0.46, 0.46),
			"lip_line": Color(0.46, 0.16, 0.12), "lip": Color(0.88, 0.50, 0.48), "mouth_in": Color(0.34, 0.08, 0.07),
			"teeth": Color(0.99, 0.97, 0.92), "tongue": Color(0.92, 0.46, 0.46)},
		"eye": {"c": Vector2(0.066, 0.014), "hw": 0.032, "top": 0.025, "bot": 0.014, "tilt": 0.004, "ir": 0.0168, "lash": 1.15, "flick": 0.010},
		"brow": {"inner": Vector2(0.030, 0.056), "mid": Vector2(0.066, 0.070), "outer": Vector2(0.100, 0.060), "w": Vector3(0.0052, 0.0050, 0.0020)},
		"cheek": {"c": Vector2(0.092, -0.030), "r": Vector2(0.028, 0.016)},
		"mouth": {"c": Vector2(0.0, -0.074), "hw": 0.037, "lip": 0.0028},
		"extra": func(acc: Dictionary, _id: StringName) -> void:
			var cv: Dictionary = _meshes["ys_face_style"]["canvas"]
			var fr := Color(0.72, 0.42, 0.26)
			for p: Vector2 in [Vector2(0.018, -0.012), Vector2(0.030, -0.020), Vector2(0.044, -0.014), Vector2(0.056, -0.024),
					Vector2(0.070, -0.018), Vector2(0.084, -0.026), Vector2(0.038, -0.030), Vector2(0.064, -0.034)]:
				for sx: float in [-1.0, 1.0]:
					FaceKit.fill(acc, cv, FaceKit.ellipse(Vector2(p.x * sx, p.y), Vector2(0.0022, 0.0022), 0.0, 6), fr, 0.0021, 0.004),
		"geo": func(acc: Dictionary) -> void:
			var sph := sphere(1.0, 10, 5)
			FaceKit.put_mesh(acc, sph, Transform3D(Basis.from_scale(Vector3(0.221, 0.185, 0.215)), Vector3(0, 1.85, -0.065)), hair.darkened(0.12))
			FaceKit.put_mesh(acc, sph, Transform3D(Basis.from_scale(Vector3(0.19, 0.24, 0.14)), Vector3(0, 1.70, -0.12)), hair.darkened(0.18))
			for sx: float in [-1.0, 1.0]:
				FaceKit.lock(acc, [Vector3(0.13 * sx, 1.90, 0.10), Vector3(0.23 * sx, 1.74, 0.15), Vector3(0.20 * sx, 1.54, 0.27),
					Vector3(0.24 * sx, 1.31, 0.32)], Vector3(0.4 * sx, 0.1, 0.9).normalized(), 0.12, 0.05, hair, tip, 5, 0.6, -20.0 * sx)
				FaceKit.lock(acc, [Vector3(0.17 * sx, 1.90, -0.02), Vector3(0.28 * sx, 1.70, 0.04), Vector3(0.30 * sx, 1.50, 0.15),
					Vector3(0.35 * sx, 1.30, 0.18)], Vector3(0.8 * sx, 0.1, 0.5).normalized(), 0.13, 0.055, hair, tip, 5, 0.6, 15.0 * sx)
			FaceKit.lock(acc, [Vector3(0.0, 1.84, -0.16), Vector3(0.03, 1.66, -0.30), Vector3(-0.02, 1.48, -0.33),
				Vector3(0.02, 1.30, -0.31)], Vector3(0, 0, -1), 0.24, 0.07, hair, tip, 5, 0.65, 10.0)
			FaceKit.lock(acc, [Vector3(0.13, 1.93, 0.11), Vector3(0.04, 1.925, 0.205), Vector3(-0.08, 1.885, 0.21),
				Vector3(-0.17, 1.80, 0.15)], Vector3(0, 0.3, 1).normalized(), 0.10, 0.04, hair, tip, 4, 0.85, 0.0)
			# the blossom tie on her left front lock
			var bc := Vector3(-0.215, 1.62, 0.22)
			for k: int in 5:
				var a := TAU * float(k) / 5.0
				FaceKit.put_mesh(acc, sphere(1.0, 6, 3), Transform3D(Basis.from_scale(Vector3(0.024, 0.024, 0.012)),
					bc + Vector3(cos(a) * 0.024, sin(a) * 0.024, 0.02)), pink)
			FaceKit.put_mesh(acc, sphere(1.0, 6, 3), Transform3D(Basis.from_scale(Vector3(0.014, 0.014, 0.01)), bc + Vector3(0, 0, 0.03)),
				FaceKit.glow(Color(1.0, 0.92, 0.45), 0.5))
			# the 8 blossom hearts of the antler crown (were the HeadGlow node, nature_glow)
			for xf: Transform3D in _crown_layout()["tips"]:
				FaceKit.put_mesh(acc, sphere(0.5, 8, 4), Transform3D(xf.basis.scaled_local(Vector3.ONE * 0.085), xf.origin + xf.basis.y * 0.025),
					FaceKit.glow(Color(0.75, 1.0, 0.40), 1.0)),
	}
	_meshes["ys_face_style"] = st
	return st


## The living staff in grip space (origin = the fist, +Y up): gnarled shaft with knots, a vine winding up it with
## leaves, root foot, and a cradle of three curled prongs (leaf-tipped) around the seed. 3 surfaces.
static func _staff_mesh() -> ArrayMesh:
	if _meshes.has("ys14_staff"):
		return _meshes["ys14_staff"]
	var wood: Array = []
	var vine: Array = []
	var green: Array = []
	var nodes: Array[Vector3] = [Vector3(0, -FOOT_DOWN, 0), Vector3(0.015, -0.45, 0.01), Vector3(-0.012, 0.15, -0.01),
		Vector3(0.012, 0.70, 0.008), Vector3(0, 1.20, 0)]
	var radii: Array[float] = [0.05, 0.047, 0.044, 0.04, 0.036]
	for k: int in 4:
		wood.append(_seg(nodes[k], nodes[k + 1], radii[k], radii[k + 1], 7))
		if k > 0:
			wood.append([sphere(radii[k] + 0.012, 8, 4), Transform3D(Basis().scaled(Vector3(1, 1.5, 1)), nodes[k])])
	for k: int in 3:   # root foot
		var a := TAU * float(k) / 3.0 + 0.4
		var o := Vector3(sin(a), 0, cos(a))
		wood.append(_seg(Vector3(0, -0.90, 0), o * 0.13 + Vector3(0, -FOOT_DOWN - 0.01, 0), 0.032, 0.008, 5))
	for k: int in 3:   # the cradle: three prongs curling in over the seed, a leaf at each
		var a := TAU * float(k) / 3.0 + PI / 6.0
		var o := Vector3(sin(a), 0, cos(a))
		var q0 := Vector3(0, 1.17, 0) + o * 0.03
		var q1 := Vector3(0, 1.31, 0) + o * 0.14
		var q2 := Vector3(0, 1.49, 0) + o * 0.17
		var q3 := Vector3(0, 1.63, 0) + o * 0.085
		wood.append(_seg(q0, q1, 0.032, 0.026, 5))
		wood.append(_seg(q1, q2, 0.026, 0.020, 5))
		wood.append(_seg(q2, q3, 0.020, 0.008, 5))
		green.append([NatureModel.leaf_mesh(), NatureModel.leaf_xform(q2 + o * 0.01, o.rotated(Vector3.UP, 0.5),
				Vector3(0.10, 0.03, 0.22), 18.0)])
	var prev := Vector3.ZERO
	for k: int in 17:   # the vine
		var ang := float(k) * 0.9
		var p := Vector3(cos(ang) * 0.058, -0.58 + float(k) * 0.1, sin(ang) * 0.058)
		if k > 0:
			vine.append(_seg(prev, p, 0.015, 0.015, 5))
		if k % 4 == 3:
			var o := Vector3(cos(ang), 0, sin(ang))
			green.append([NatureModel.leaf_mesh(), NatureModel.leaf_xform(p, o, Vector3(0.08, 0.02, 0.15), 35.0)])
		prev = p
	var am := ArrayMesh.new()
	for g: Array in [[wood, _mat(&"ysolde_wood")], [vine, NatureModel.nature(&"nature_leaf_dark")],
			[green, NatureModel.nature(&"nature_leaf")]]:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays(g[0]))
		am.surface_set_material(am.get_surface_count() - 1, g[1])
	_meshes["ys14_staff"] = am
	return am


## Curved leaf cape (double-sided): a cone section wrapping the back (+-64 deg) made of 5 big pointed leaves: the hem
## is cut into 5 lobes and each lobe bulges out between creases, so every leaf catches its own light. One surface,
## team cloth (the team recolour finds it). Shared vertex grid: outer face, then the inner face.
static func _cape_mesh() -> ArrayMesh:
	if _meshes.has("ys14_cape"):
		return _meshes["ys14_cape"]
	const COLS := 30
	const ROWS := 10
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for side: float in [1.0, -1.0]:
		for j: int in ROWS + 1:
			var v := float(j) / float(ROWS)
			for i: int in COLS + 1:
				var u := float(i) / float(COLS)
				verts.append(_cape_point(u, v))
				var du := _cape_point(u + 0.004, v) - _cape_point(u - 0.004, v)
				var dv := _cape_point(u, minf(v + 0.02, 1.0)) - _cape_point(u, maxf(v - 0.02, 0.0))
				norms.append(du.cross(dv).normalized() * side)
	var n_side := (ROWS + 1) * (COLS + 1)
	for j: int in ROWS:
		for i: int in COLS:
			var q := j * (COLS + 1) + i
			var p1 := q + 1
			var p2 := q + COLS + 2
			var p3 := q + COLS + 1
			idx.append_array(PackedInt32Array([q, p3, p1, p1, p3, p2]))
			idx.append_array(PackedInt32Array([q + n_side, p1 + n_side, p3 + n_side, p1 + n_side, p2 + n_side, p3 + n_side]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, _mat(&"ysolde_cloth"))
	_meshes["ys14_cape"] = am
	return am


## Cape point at u (0-1 across), v (0-1 down). Lobe tips at the centre of each fifth, creases between them.
static func _cape_point(u: float, v: float) -> Vector3:
	var a := lerpf(-64.0, 64.0, u) * DEG
	var w := fposmod(u * 5.0, 1.0)
	var bulge := 0.04 * sin(PI * w) * smoothstep(0.0, 0.35, v)
	var r := 0.28 + 0.28 * smoothstep(0.0, 0.3, v) + 0.08 * v + bulge
	var tip := 1.0 - 0.42 * pow(absf(w * 2.0 - 1.0), 1.2) * smoothstep(0.25, 1.0, v)
	return Vector3(sin(a) * r, -1.0 * v * tip, -cos(a) * r)

## Process materials of the shared burst emitter: bloom (petals from the seed), thorns (chips racing out from the
## staff foot), thicket (life rising in a ring in front), death (leaves and petals from the body). Shared.
static func _pm(kind: StringName) -> ParticleProcessMaterial:
	if _pms.has(kind):
		return _pms[kind]
	var pm := ParticleProcessMaterial.new()
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -220.0
	pm.angular_velocity_max = 220.0
	var tint := Gradient.new()
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.08, Color(1, 1, 1, 1))
	fade.add_point(0.7, Color(1, 1, 1, 1))
	match kind:
		&"thorns":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.18
			pm.emission_ring_inner_radius = 0.05
			pm.emission_ring_height = 0.05
			pm.direction = Vector3.UP
			pm.spread = 30.0
			pm.initial_velocity_min = 1.4
			pm.initial_velocity_max = 2.4
			pm.radial_velocity_min = 2.2
			pm.radial_velocity_max = 3.4
			pm.gravity = Vector3(0, -6.0, 0)
			pm.damping_min = 0.4
			pm.damping_max = 0.8
			pm.scale_min = 0.8
			pm.scale_max = 1.5
			tint.set_color(0, Color(0.46, 0.30, 0.15))
			tint.set_color(1, Color(0.55, 0.80, 0.25))
			tint.add_point(0.5, Color(0.22, 0.42, 0.12))
		&"thicket":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = 0.8
			pm.emission_ring_inner_radius = 0.55
			pm.emission_ring_height = 0.05
			pm.direction = Vector3.UP
			pm.spread = 8.0
			pm.initial_velocity_min = 1.2
			pm.initial_velocity_max = 2.1
			pm.radial_velocity_min = -0.4
			pm.radial_velocity_max = -0.2
			pm.gravity = Vector3.ZERO
			pm.damping_min = 0.6
			pm.damping_max = 1.0
			pm.scale_min = 0.8
			pm.scale_max = 1.3
			tint.set_color(0, Color(0.75, 1.0, 0.40))
			tint.set_color(1, Color(0.95, 1.0, 0.65))
		&"death":
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.45
			pm.direction = Vector3.UP
			pm.spread = 180.0
			pm.initial_velocity_min = 0.6
			pm.initial_velocity_max = 1.6
			pm.gravity = Vector3(0, -1.2, 0)
			pm.damping_min = 0.8
			pm.damping_max = 1.4
			pm.scale_min = 0.8
			pm.scale_max = 1.3
			tint.set_color(0, Color(0.50, 0.72, 0.20))
			tint.set_color(1, Color(0.96, 0.60, 0.76))
			tint.add_point(0.7, Color(0.22, 0.40, 0.12))
		_:   # bloom
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 0.18
			pm.direction = Vector3.UP
			pm.spread = 180.0
			pm.initial_velocity_min = 0.8
			pm.initial_velocity_max = 1.9
			pm.gravity = Vector3(0, -0.7, 0)
			pm.damping_min = 1.0
			pm.damping_max = 1.6
			pm.scale_min = 0.8
			pm.scale_max = 1.3
			tint.set_color(0, Color(0.96, 0.58, 0.74))
			tint.set_color(1, Color(1.0, 0.92, 0.95))
			tint.add_point(0.6, Color(0.98, 0.72, 0.84))
	var tt := GradientTexture1D.new()
	tt.gradient = tint
	pm.color_initial_ramp = tt
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	_pms[kind] = pm
	return pm


## Draw passes of the burst emitter: soft petal bits (alpha) or glowing motes (additive). Vertex colour tints.
static func _draw(glow: bool) -> QuadMesh:
	if _draws.has(glow):
		return _draws[glow]
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12) if glow else Vector2(0.15, 0.10)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sm.vertex_color_use_as_albedo = true
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow:
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		sm.albedo_color = Color(2.2, 2.2, 2.0, 1.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35 if glow else 0.70, Color(1, 1, 1, 0.85 if glow else 1.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	sm.albedo_texture = t
	q.material = sm
	_draws[glow] = q
	return q


## Restarts the burst emitter in mode `kind` at a world position.
func _fire(kind: StringName, at: Vector3) -> void:
	if _fx == null:
		return
	_fx.process_material = _pm(kind)
	_fx.draw_pass_1 = _draw(kind == &"thicket")
	match kind:
		&"thorns": _fx.lifetime = 0.9
		&"thicket": _fx.lifetime = 1.1
		&"death": _fx.lifetime = 1.4
		_: _fx.lifetime = 1.3
	_fx.global_position = at
	_fx.restart()


## Petal i: base on a small ring under the seed, cupped up around it (o = 0) or opened flat and longer (o = 1).
func _write_petals(o: float) -> void:
	var mm := _petals.multimesh
	var tilt: float = lerpf(64.0, -6.0, o)
	var size := Vector3(0.15 + 0.06 * o, 0.035, 0.24 + 0.12 * o)
	for i: int in PETALS:
		var a := TAU * float(i) / float(PETALS)
		var out := Vector3(sin(a), 0, cos(a))
		mm.set_instance_transform(i, NatureModel.leaf_xform(out * 0.05, out, size, tilt))


# ================================================================ animation

func _on_action_event(ev: StringName) -> void:
	match ev:
		&"cast_start":
			_fx_fired = false
		&"level_up":
			_fire(&"bloom", _bloom.global_position)
		&"death_glow_off":
			_fire(&"death", global_transform * Vector3(0, 0.8, 0.3))
			_drift.emitting = false


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"wild_bloom":
			# Arms spread wide, staff lifted overhead, chin up on tiptoe; the flower opens, the crown blazes.
			var k := _k3(t, 0.0, 0.30, 0.70, 1.05, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-22.0 * DEG * k, 0, 10.0 * DEG * k))
			pos(P_ARM_R, Vector3(0.02 * k, 0.44 * k, 0.04 * k))
			rot(P_ARM_L, Vector3(-35.0 * DEG * k, 0, -85.0 * DEG * k))
			rot(P_HEAD, Vector3(-16.0 * DEG * k, 0, 0))
			rot(P_CHEST, Vector3(-8.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, 0.06 * k, 0))
			if not _fx_fired and t >= 0.26:
				_fx_fired = true
				_fire(&"bloom", _bloom.global_position)
			_open = maxf(_open, k)
			_crown = maxf(_crown, 1.0 + 1.2 * k)
			_cape_kick += 14.0 * k
			_cast_boost = 1.0 + 2.5 * k
			_cast_light = 1.0 + 1.5 * k
			return 1.05
		&"call_the_thicket":
			# Staff lifted then planted; she bends to touch the ground and sweeps her hand up: life rises in front.
			var lift := _k3(t, 0.0, 0.22, 0.22, 0.36, 1.0, 1.0)
			var plant := _k3(t, 0.22, 0.36, 0.80, 1.10, 1.0, 1.0)
			var reach := _k3(t, 0.05, 0.30, 0.38, 0.58, 1.0, 1.0)
			var sweep := _k3(t, 0.38, 0.62, 0.82, 1.10, 1.0, 1.0)
			rot(P_ARM_R, Vector3((-25.0 * lift - 12.0 * plant) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.26 * lift - 0.06 * plant, 0.10 * plant))
			rot(P_ARM_L, Vector3((-35.0 * reach - 150.0 * sweep) * DEG, 0, (10.0 * reach - 20.0 * sweep) * DEG))
			rot(P_CHEST, Vector3((22.0 * reach - 10.0 * sweep) * DEG, -10.0 * DEG * reach, 0))
			rot(P_HEAD, Vector3((10.0 * reach - 18.0 * sweep) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, -0.14 * reach + 0.05 * sweep, 0))
			_staff_pitch += 6.0 * DEG * plant
			if not _fx_fired and t >= 0.40:
				_fx_fired = true
				_fire(&"thicket", global_transform * Vector3(-0.1, 0.05, 1.3))
			var k := maxf(lift, plant)
			_open = maxf(_open, 0.85 * k)
			_crown = maxf(_crown, 1.0 + 1.0 * sweep)
			_cast_boost = 1.0 + 2.5 * k
			_cast_light = 1.0 + 1.5 * k
			return 1.1
		&"idle_bloom":
			# She raises her palm toward the staff and looks up: the seed blooms for a moment.
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.45, 1.60, 2.20, 1.0, 1.0)
			var b := _k3(t, 0.40, 0.90, 1.50, 2.00, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-55.0 * DEG * k, 0, 25.0 * DEG * k))
			rot(P_HEAD, Vector3(-12.0 * DEG * k, 22.0 * DEG * k, 0))
			rot(P_CHEST, Vector3(0, 8.0 * DEG * k, 0))
			_open = maxf(_open, 0.9 * b)
			_cast_boost = 1.0 + 1.5 * b
			_cast_light = 1.0 + 0.8 * b
			return 2.2
		&"idle_listen":
			# Head tilted, looking away, as if the forest were talking; the crown blossoms brighten.
			if _speed >= 0.3:
				return 0.0
			var k := _k3(t, 0.0, 0.5, 1.4, 2.0, 1.0, 1.0)
			rot(P_HEAD, Vector3(-6.0 * DEG * k, -24.0 * DEG * k, 12.0 * DEG * k))
			rot(P_CHEST, Vector3(0, -8.0 * DEG * k, 0))
			rot(P_ARM_L, Vector3(-60.0 * DEG * k, 0, 15.0 * DEG * k))
			_crown = maxf(_crown, 1.0 + 1.2 * k)
			return 2.0
		&"idle_twirl":
			# Lifts the staff and twirls it once in her fingers.
			if _speed >= 0.3:
				return 0.0
			var lift := _k3(t, 0.0, 0.25, 1.0, 1.4, 1.0, 1.0)
			pos(P_ARM_R, Vector3(0, 0.10 * lift, 0.04 * lift))
			rot(P_HEAD, Vector3(0, 10.0 * DEG * lift, 0))
			_staff_spin = TAU * smoothstep(0.15, 1.05, t)
			_open = maxf(_open, 0.4 * lift)
			return 1.4
		_:  # thornburst (and unknown ids): staff raised high, then driven into the ground in front.
			var up := _k3(t, 0.0, 0.20, 0.22, 0.34, 1.0, 1.0)
			var slam := _k3(t, 0.20, 0.34, 0.55, 0.85, 1.0, 1.0)
			rot(P_ARM_R, Vector3((-45.0 * up - 25.0 * slam) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.30 * up + 0.06 * slam, 0.02 * up + 0.16 * slam))
			rot(P_ARM_L, Vector3((-60.0 * up + 20.0 * slam) * DEG, 0, (-35.0 * up - 30.0 * slam) * DEG))
			rot(P_CHEST, Vector3((-10.0 * up + 18.0 * slam) * DEG, (10.0 * up - 6.0 * slam) * DEG, 0))
			rot(P_HEAD, Vector3((-10.0 * up + 6.0 * slam) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0.05 * up - 0.14 * slam, 0.06 * slam))
			_staff_pitch += (-12.0 * up + 10.0 * slam) * DEG
			if not _fx_fired and t >= 0.33:
				_fx_fired = true
				var foot := _staff.global_transform * Vector3(0, -FOOT_DOWN, 0)
				foot.y = global_position.y + 0.05
				_fire(&"thorns", foot)
			var k := maxf(up, slam)
			_open = maxf(_open, 0.7 * k)
			_crown = maxf(_crown, 1.0 + 1.2 * slam)
			_cast_boost = 1.0 + 2.0 * k
			_cast_light = 1.0 + 1.5 * k
			return 0.85


func _wizard_process(dt: float) -> void:
	if _staff == null:
		return
	var full := _walk_w > 0.0 or _action != &"" or _dead or _hit_t < HIT_LEN or _level_t < LEVEL_LEN
	if _dead:
		_death_extras()
	elif full:
		_body_extras()
	# Idle fidgets: close camera only (tier 0), every 8-14 s.
	if not _dead and _tier == 0 and _action == &"" and _speed < 0.3 and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN:
		_idle_left -= dt
		if _idle_left <= 0.0:
			_idle_left = 8.0 + 6.0 * fmod(_phase_off * 7.3 + float(_idle_i) * 0.37, 1.0)
			play_cast(IDLE_IDS[_idle_i % IDLE_IDS.size()])
			_idle_i += 1
	elif _action != &"" or _speed >= 0.3:
		_idle_left = maxf(_idle_left, 3.0)
	# Tulip: opens fast, closes slowly; shut when dead.
	var target := 0.0 if _dead else clampf(_open, 0.0, 1.0)
	_open_cur = move_toward(_open_cur, target, dt * (6.0 if target > _open_cur else 2.5))
	if absf(_open_cur - _open_written) > 0.01:
		_open_written = _open_cur
		_write_petals(_open_cur)
	# Staff at the fist: cancels the arm / chest pitch (upright staff) plus the wanted tilt; a slow idle sway.
	var comp: float
	if full:
		comp = _off_rot[P_ARM_R].x + _off_rot[P_CHEST].x
	else:
		comp = (_piv[P_ARM_R].rotation.x - _rest_rot[P_ARM_R].x) + (_piv[P_CHEST].rotation.x - _rest_rot[P_CHEST].x)
	var sr := Vector3(_staff_pitch - comp * _staff_keep, _staff_spin,
			_staff_roll + 2.0 * DEG * sin(0.7 * (_t + _phase_off)))
	if sr.distance_squared_to(_staff_written) > 0.000004:
		_staff_written = sr
		_staff.rotation = sr
	# Crown hearts + eye bar.
	var cb := glow_level() * _crown
	if absf(cb - _crown_written) > 0.01:
		_crown_written = cb
		_head_glow.set_instance_shader_parameter(&"glow_boost", cb)
	if _face:
		_face.auto(self)
	# Cape: billows with the walk and casts, slow flutter; flops forward on death.
	var ck := CAPE_TILT + _cape_kick + 1.5 * sin(_t * 2.1 + _phase_off) + 1.0 * sin(_t * 3.7)
	if _dead:
		ck = CAPE_TILT - 15.0 * clampf(_death_t / 0.5, 0.0, 1.0)
	if absf(ck - _cape_written) > 0.05:
		_cape_written = ck
		_cape.rotation.x = ck * DEG
	_open = 0.0
	_staff_pitch = 0.0
	_staff_roll = 0.0
	_staff_spin = 0.0
	_staff_keep = 1.0
	_crown = 1.0
	_cape_kick = 0.0


## Offsets on top of the kit's walk / attack / hit / level-up poses (only on frames the kit applies them).
func _body_extras() -> void:
	# Walk: a gliding queen: the gown sways, the chest counters, the staff swings like a walking stick.
	if _walk_w > 0.0:
		var sw := sin(TAU * _walk_p) * _walk_w
		rot(P_HIPS, Vector3(0, 5.0 * DEG * sw, 3.0 * DEG * sw))
		rot(P_CHEST, Vector3(3.0 * DEG * _walk_w, -4.0 * DEG * sw, 0))
		rot(P_HEAD, Vector3(-3.0 * DEG * _walk_w, 3.0 * DEG * sw, -2.0 * DEG * sw))
		_staff_pitch += 8.0 * DEG * sw
		_cape_kick += (10.0 + 4.0 * absf(sw)) * _walk_w
	# Auto-attack (wizard_bolt, release 0.12): the seed is levelled at the target, the off hand flicks.
	if _action == &"attack":
		var a := _k3(_action_t, 0.0, attack_windup, attack_windup + 0.05, 0.45, 1.0, 1.0)
		_staff_pitch += 12.0 * DEG * a
		pos(P_ARM_R, Vector3(0, 0.04 * a, 0.12 * a))
		rot(P_ARM_L, Vector3(-35.0 * DEG * a, 0, 20.0 * DEG * a))
		rot(P_CHEST, Vector3(4.0 * DEG * a, -10.0 * DEG * a, 0))
		_open = maxf(_open, 0.6 * a)
		_crown = maxf(_crown, 1.0 + 0.6 * a)
	# Hit: the head snaps back, the staff jolts.
	if _hit_t < HIT_LEN:
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		rot(P_HEAD, Vector3(-14.0 * DEG * k, 0, 6.0 * DEG * k))
		rot(P_ARM_L, Vector3(-20.0 * DEG * k, 0, -15.0 * DEG * k))
		_staff_pitch -= 10.0 * DEG * k
	# Level-up: a pirouette with the free arm flung out; full bloom, the crown blazes.
	if _level_t < LEVEL_LEN:
		var u := clampf(_level_t / LEVEL_LEN, 0.0, 1.0)
		var s := sin(PI * u)
		rot(P_ROOT, Vector3(0, TAU * smoothstep(0.0, 1.0, u), 0))
		rot(P_ARM_L, Vector3(0, 0, -75.0 * DEG * s))
		_open = maxf(_open, s)
		_crown = maxf(_crown, 1.0 + 1.2 * s)
		_cape_kick += 25.0 * s


## Death (fall): a gasp, head back and the off hand reaching to the sky, then the kit's fall; the staff slips out
## of her hand and topples outward.
func _death_extras() -> void:
	var t := _death_t
	var g := _k3(t, 0.0, 0.22, 0.30, 0.55, 1.0, 1.0)
	rot(P_HEAD, Vector3(-22.0 * DEG * g, 0, 0))
	rot(P_ARM_L, Vector3(-110.0 * DEG * g, 0, -20.0 * DEG * g))
	rot(P_CHEST, Vector3(-10.0 * DEG * g, 0, 0))
	var f := _ease_in(clampf((t - 0.25) / 0.45, 0.0, 1.0))
	_staff_keep = 1.0 - f
	_staff_roll = -70.0 * DEG * f


func _on_revive() -> void:
	super._on_revive()
	_open_cur = 0.0
	_open_written = -1.0
	_staff_written = Vector3(99, 99, 99)
	_crown_written = -1.0
	_cape_written = 999.0
	if _face:
		_face.reset()
	if _drift:
		_drift.emitting = _tier < 2
