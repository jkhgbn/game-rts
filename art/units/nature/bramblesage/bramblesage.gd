extends NatureWarModel
## Bramblesage, Nature caster (caster-units.md 5.3 / 10.3, task CU.V3). Height 1.8 with the crown, radius 0.45.
## "An antlered old druid with moth wings": a stooped elder in a long bark-brown robe with a scalloped leaf hem and two
## hanging skirts of straw and pale-moss leaves, a team shawl, stole and bell sleeves, a MANTLE OF TWO PALE MOTH WINGS
## over the shoulders (cream forewings with a dark eye-spot and a bark leading edge, pale-moss hindwings, the team
## colour on the wing roots: the top-facing team read), a CROWN OF BLEACHED TWIG ANTLERS hung with 4 glowing pollen
## pods (glow point 1) and a HOOKED BRIAR CROOK with a glowing bud at the hook (glow point 2, where the Snagroot vine
## leaves). Face: an elder with pointed leaf ears, long white hair and beard with moss-green tips, hazel eyes, a kind
## closed smile. Read at 40 m: a brown bell with two pale wing lobes at the shoulders, pale antlers + lights on top, a
## tall hook. Never green on green: brown / straw / cream masses, the team colour on the top-facing cloth.
## Hooks: the kit's (set_moving, play_attack, play_hit, play_death / death_finished, revive, play_level_up,
## set_veterancy, set_team_color, dances) + play_cast(id):
##   snagroot     0.6 s: the crook is thrust forward (the vine leaves the hook at VINE_T: UnitVfx `snagroot`, from
##                get_hook_position()), then YANKED back with both hands (the pull).
##   pollen_haze  0.8 s: the wings spread wide and beat once, the pods flare (UnitVfx `pollen_haze` at the point).
##   seedcloak    0.4 s: the wings wrap around him (the passive's burst; UnitVfx `seedcloak`).
##   anything else: the kit's generic two-arm raise.
## Attack `seed_spit` (0.5 s, release at attack_windup 0.12 s): the crook jabs forward and spits a seed from the hook
## (the bolt starts at get_beam_origin()). Walk: a stooped shuffle, the crook as a walking staff, the wings flutter.
## Idle: pollen drifts from the pods; fidget: strokes his beard, the pods brighten. Hit: moth dust and leaves.
## Death: sinks into a mound of leaves, the pods go dark. Level 4: a gold band on the crown.
## Draws at rest: 7 merged pivots + face + 2 wings + pods + blob = 12 (the death mound hidden).

const GRIP := Vector3(0.35, 0.98, 0.18)             # right fist (model space): holds the crook
const GRIP_L := Vector3(-0.30, 0.96, 0.16)
const HOOK_TIP := Vector3(0.385, 1.935, 0.445)      # the crook's hook end (the bud): vine / seed origin
const HC := Vector3(0, 1.47, 0.13)                  # face centre
const HR := 0.135
const WING_ROOT := Vector3(0.13, 1.37, -0.09)       # right wing root (model space, left = x mirrored)
const WING_YAW := 22.0                              # rest: the wings folded half back (0 = spread flat to the sides)
const WING_PITCH := 36.0                            # rest: the wing bottoms lean back off the robe
const ATTACK_LEN := 0.5
const SNAG_LEN := 0.6
const VINE_T := 0.22
const HAZE_LEN := 0.8
const BEAT_T := 0.45
const CLOAK_LEN := 0.4

# Keyframe tracks [t, value, ease, ...] (NatureWarModel._kf). Arm x: - swings the arm forward / up.
static var A_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.07, 14.0, 1, 0.13, -42.0, 2, 0.30, -36.0, 0, ATTACK_LEN, 0.0, 0])
static var A_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 10.0, 1, 0.13, -12.0, 2, ATTACK_LEN, 0.0, 0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.03, 1, 0.13, 0.06, 2, ATTACK_LEN, 0.0, 0])
static var S_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.08, 18.0, 1, VINE_T, -72.0, 2, 0.30, -70.0, 0, 0.46, 34.0, 2, SNAG_LEN, 0.0, 0])
static var S_ARM_L := PackedFloat32Array([0.0, 0.0, 0, VINE_T, -20.0, 0, 0.30, -58.0, 1, 0.46, -30.0, 2, SNAG_LEN, 0.0, 0])
static var S_ARM_LZ := PackedFloat32Array([0.0, 0.0, 0, VINE_T, 10.0, 0, 0.30, 40.0, 1, 0.46, 34.0, 0, SNAG_LEN, 0.0, 0])
static var S_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -6.0, 1, VINE_T, 14.0, 2, 0.30, 12.0, 0, 0.46, -14.0, 2, SNAG_LEN, 0.0, 0])
static var S_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.04, 1, VINE_T, 0.12, 2, 0.30, 0.10, 0, 0.46, -0.10, 2, SNAG_LEN, 0.0, 0])
static var S_LEG_L := PackedFloat32Array([0.0, 0.0, 0, VINE_T, -22.0, 2, 0.30, -20.0, 0, 0.46, 8.0, 2, SNAG_LEN, 0.0, 0])
static var S_LEG_R := PackedFloat32Array([0.0, 0.0, 0, VINE_T, 14.0, 2, 0.30, 12.0, 0, 0.46, -16.0, 2, SNAG_LEN, 0.0, 0])
# Pollen Haze: wings (yaw from rest: - spreads; roll: + raises the outer edge), arms up and out, head up.
static var H_WING_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.28, -40.0, 1, 0.62, -40.0, 0, HAZE_LEN, 0.0, 0])
static var H_WING_ROLL := PackedFloat32Array([0.0, 0.0, 0, 0.28, 34.0, 1, 0.38, 46.0, 1, BEAT_T, -14.0, 2, 0.56, 20.0, 1, HAZE_LEN, 0.0, 0])
static var H_ARMS := PackedFloat32Array([0.0, 0.0, 0, 0.28, -60.0, 1, 0.62, -58.0, 0, HAZE_LEN, 0.0, 0])
static var H_ARMS_Z := PackedFloat32Array([0.0, 0.0, 0, 0.28, 34.0, 1, 0.62, 32.0, 0, HAZE_LEN, 0.0, 0])
static var H_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.28, -14.0, 1, BEAT_T, 6.0, 2, 0.62, -6.0, 0, HAZE_LEN, 0.0, 0])
static var H_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.28, 0.05, 1, BEAT_T, -0.04, 2, 0.62, 0.02, 0, HAZE_LEN, 0.0, 0])
# Seedcloak: the wings sweep forward around the body and back.
static var C_WING_YAW := PackedFloat32Array([0.0, 0.0, 0, 0.14, -104.0, 1, 0.26, -100.0, 0, CLOAK_LEN, 0.0, 0])
static var C_WING_ROLL := PackedFloat32Array([0.0, 0.0, 0, 0.14, -12.0, 1, 0.26, -10.0, 0, CLOAK_LEN, 0.0, 0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.14, 16.0, 1, 0.26, 14.0, 0, CLOAK_LEN, 0.0, 0])

var _wing_l: Node3D
var _wing_r: Node3D
var _pods: GeometryInstance3D
var _bud: GeometryInstance3D
var _mound: Node3D
var _drift: GPUParticles3D
var _haze_puff: GPUParticles3D
var _cloak_puff: GPUParticles3D
var _seed_puff: GPUParticles3D
var _wing_yaw: float = 0.0     # animated offsets (deg), posed each frame, 0 at rest
var _wing_roll: float = 0.0
var _wing_written: Vector2 = Vector2(999.0, 999.0)
var _flare: float = 0.0
var _bud_flare: float = 0.0
var _pods_written: float = -1.0
var _bud_written: float = -1.0
var _mound_written: float = -1.0
var _puffed: bool = false
var _hit_flap: Vector2 = Vector2.ZERO   # wing spring (value, velocity): hits and starts / stops flap the wings


# ================================================================ meshes (static, cached per type)

## One double-sided layer: a centroid fan over `pts` (wing plane XY, x mirrored by sx) at +-z, each side facing out.
static func _layer(st: SurfaceTool, pts: PackedVector2Array, sx: float, z: float) -> void:
	var c := Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	c /= float(pts.size())
	for side: float in [1.0, -1.0]:
		var zz := z * side
		var a := Vector3(c.x * sx, c.y, zz)
		for i: int in pts.size():
			var b := Vector3(pts[i].x * sx, pts[i].y, zz)
			var d := Vector3(pts[(i + 1) % pts.size()].x * sx, pts[(i + 1) % pts.size()].y, zz)
			if (d - a).cross(b - a).z * side < 0.0:   # front face = (c - a) x (b - a) must point out of this side
				var tmp := b
				b = d
				d = tmp
			st.set_normal(Vector3(0, 0, side))
			st.add_vertex(a)
			st.set_normal(Vector3(0, 0, side))
			st.add_vertex(b)
			st.set_normal(Vector3(0, 0, side))
			st.add_vertex(d)


static func _ellipse(c: Vector2, r: Vector2, n: int = 10) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in n:
		var a := TAU * float(i) / float(n)
		out.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return out


## A moth wing (sx +1 = right, -1 = left): in the wing plane, x outward, y down from the root at 0. Cream forewing
## with a bark leading edge and a dark eye-spot, pale-moss hindwing with a spot, the team colour on both roots.
static func _wing_mesh(sx: float) -> Mesh:
	var key := "bs_wing_v4_%s" % sx
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var layers: Array = [
		[nature(&"nature_sec_bramblesage"), 0.003, [PackedVector2Array([Vector2(0, 0), Vector2(0.18, 0.10),
			Vector2(0.42, 0.13), Vector2(0.60, -0.04), Vector2(0.56, -0.28), Vector2(0.40, -0.44), Vector2(0.12, -0.46),
			Vector2(0, -0.30)])]],
		[nature(&"nature_moss"), 0.002, [PackedVector2Array([Vector2(0, -0.28), Vector2(0.12, -0.40), Vector2(0.37, -0.46),
			Vector2(0.47, -0.61), Vector2(0.39, -0.83), Vector2(0.22, -0.95), Vector2(0.08, -0.75), Vector2(0, -0.55)])]],
		[nature(&"nature_cloth"), 0.006, [PackedVector2Array([Vector2(0.01, -0.01), Vector2(0.18, 0.08),
			Vector2(0.29, -0.06), Vector2(0.24, -0.33), Vector2(0.06, -0.37), Vector2(0.0, -0.2)])]],
		[nature(&"nature_cloth_dark"), 0.006, [PackedVector2Array([Vector2(0.01, -0.36), Vector2(0.14, -0.43),
			Vector2(0.21, -0.60), Vector2(0.08, -0.64), Vector2(0.01, -0.52)])]],
		[nature(&"nature_bark"), 0.006, [PackedVector2Array([Vector2(0, 0.0), Vector2(0.18, 0.10), Vector2(0.42, 0.13),
			Vector2(0.60, -0.04), Vector2(0.565, -0.07), Vector2(0.41, 0.09), Vector2(0.18, 0.065), Vector2(0.0, -0.035)])]],
		[nature(&"nature_bark_dark"), 0.009, [_ellipse(Vector2(0.43, -0.14), Vector2(0.08, 0.068), 8),
			_ellipse(Vector2(0.31, -0.71), Vector2(0.05, 0.045), 8)]],
		[nature(&"nature_sec_slinger_b"), 0.012, [_ellipse(Vector2(0.435, -0.135), Vector2(0.043, 0.037), 8)]],
	]
	var am := ArrayMesh.new()
	for l: Array in layers:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for pts: PackedVector2Array in l[2]:
			_layer(st, pts, sx, float(l[1]))
		st.index()
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, l[0])
	return _cached(key, am)


## The bleached twig antlers (both sides) as tapered paths, with the tines the pods hang from.
static func _antler_mesh() -> Mesh:
	const KEY := "bs_antlers_v3"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for sx: float in [-1.0, 1.0]:
		var paths: Array = [
			[PackedVector3Array([Vector3(0.06, 1.56, 0.10), Vector3(0.14, 1.71, 0.075), Vector3(0.235, 1.96, -0.04)]),
				PackedFloat32Array([0.028, 0.019, 0.0])],
			[PackedVector3Array([Vector3(0.14, 1.71, 0.075), Vector3(0.26, 1.77, 0.10), Vector3(0.335, 1.80, 0.14)]),
				PackedFloat32Array([0.016, 0.011, 0.0])],
		]
		var k := 0
		for p: Array in paths:
			var pts: PackedVector3Array = p[0]
			var mp := PackedVector3Array()
			for v: Vector3 in pts:
				mp.append(Vector3(v.x * sx, v.y, v.z))
			st.append_from(tapered_path_mesh("bs_antler2_%s_%d" % [sx, k], mp, p[1], 4), 0, Transform3D.IDENTITY)
			k += 1
	return _cached(KEY, _indexed(st))


## The crook: the hook as a tapered path curling forward over the top, and a briar vine spiralling up the shaft.
static func _hook_mesh() -> Mesh:
	return tapered_path_mesh("bs_hook_v1", PackedVector3Array([Vector3(0.378, 1.90, 0.245), Vector3(0.38, 2.05, 0.27),
		Vector3(0.382, 2.105, 0.37), Vector3(0.384, 2.05, 0.455), HOOK_TIP]),
		PackedFloat32Array([0.034, 0.032, 0.028, 0.022, 0.014]), 6)


static func _briar_mesh() -> Mesh:
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	var n := 7
	for i: int in n:
		var u := float(i) / float(n - 1)
		var a := u * TAU * 2.2
		var c := Vector3(0.335, 0.30, 0.135).lerp(Vector3(0.378, 1.88, 0.245), u)
		pts.append(c + Vector3(cos(a) * 0.045, 0.0, sin(a) * 0.045))
		rad.append(0.013 if i < n - 1 else 0.0)
	return tapered_path_mesh("bs_briar_v2", pts, rad, 3, false)


# ================================================================ build

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
	var bdark := nature(&"nature_bark_dark")
	var skin := nature(&"nature_skin")
	var straw := nature(&"nature_sec_slinger_b")
	var moss := nature(&"nature_moss")
	var pale := nature(&"nature_sec_sprigling")
	var thorn := nature(&"nature_thorn")
	var glow := nature(&"nature_glow")
	# ---- Feet: bark sandals peeking out under the robe (the walk shuffles them).
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, sphere(0.085, 6, 3), bdark, Vector3(0.10 * sx, 0.045, 0.10), Vector3.ZERO, Vector3(0.95, 0.6, 1.5))
	# ---- Hips: the long bark robe (a scalloped leaf hem), a straw leaf skirt over its lower half, a pale-moss one at
	# the hips, a braided vine belt.
	var robe := PackedVector2Array([Vector2(0.19, 1.02), Vector2(0.215, 0.92), Vector2(0.255, 0.74), Vector2(0.30, 0.52),
		Vector2(0.355, 0.30), Vector2(0.405, 0.12), Vector2(0.425, 0.03)])
	add_part(hips, GroveKinModel.lathe("bs_robe_v3", robe, 10, 5, 0.10, 3, 0.05), bark, Vector3.ZERO)
	add_leaf_crown(hips, Vector3(0, 0.40, 0), 6, 0.29, Vector3(0.25, 0.04, 0.34), -74.0, straw, 12.0)
	add_leaf_crown(hips, Vector3(0, 0.80, 0), 4, 0.215, Vector3(0.24, 0.04, 0.30), -70.0, moss, 45.0)
	add_part(hips, cyl(0.205, 0.215, 0.06, 10, false), bdark, Vector3(0, 0.96, 0))
	# ---- Chest: the stooped bark torso, a team shawl over the shoulders, a team stole down the front with leaf tips,
	# a team-dark hood fallen behind the head.
	add_part(chest, cyl(0.17, 0.225, 0.46, 10), bark, Vector3(0, 1.15, 0.03), Vector3(14, 0, 0))
	add_part(chest, cyl(0.15, 0.27, 0.17, 10), cloth, Vector3(0, 1.31, 0.06), Vector3(14, 0, 0))
	for sx: float in [-1.0, 1.0]:
		add_part(chest, box(Vector3(0.085, 0.56, 0.03)), straw, Vector3(0.085 * sx, 1.02, 0.225), Vector3(8, 0, 4.0 * sx))
		add_leaf(chest, Vector3(0.09 * sx, 0.72, 0.245), Vector3(0.10, 0.03, 0.16), cloth, Vector3(80, 0, 0))
	add_part(chest, sphere(0.155, 8, 4), cdark, Vector3(0, 1.42, -0.02), Vector3(-10, 0, 0), Vector3(1.1, 0.8, 0.9))
	# ---- Head: skin head, the elder's face (FaceKit, lean): hazel eyes, a kind closed smile, pointed leaf ears, long
	# white hair and a long beard with moss-green tips (cheap blades); the bleached antler crown, a hidden gold band.
	add_part(head, sphere(HR, 10, 6), skin, HC)
	var white := Color(0.93, 0.92, 0.86)
	var mtip := Color(0.60, 0.72, 0.34)
	_face = _attach_face(head, {"center": HC, "radius": HR, "head_mesh": sphere(HR, 10, 6),
		"preset": &"elder", "detail": &"low", "skin": NatureFaces.SKIN, "hair": white, "hair_tip": mtip,
		"eyes": NatureFaces.EYE_HAZEL.lerp(Color(0.40, 0.55, 0.22), 0.35), "ears": &"none",
		"palette": {"brow": Color(0.78, 0.76, 0.70), "lash": Color(0.20, 0.14, 0.08)},
		"eye": {"c": Vector2(0.048, 0.018)}, "mouth": {"c": Vector2(0.0, -0.056), "hw": 0.026},
		"x": NatureFaces.lean_x(1.05, {&"neutral": {"mouth": {"kind": "closed", "curve": 1.2, "w": 0.9}}}),
		"hair_fn": func(acc: Dictionary) -> void:
			_elder_hair(acc, white, mtip)})
	add_part(head, _antler_mesh(), pale, Vector3.ZERO)
	var trim := add_part(head, torus(0.13, 0.16, 12), palette(&"unit_gold_trim"), Vector3(0, 1.56, 0.11),
		Vector3(-12, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# The pollen pods (keep_separate, own glow: they flare on Pollen Haze, go dark on death): 4 hanging from the tines.
	var pod_at: Array[Vector3] = [Vector3(0.335, 1.74, 0.14), Vector3(0.245, 1.90, -0.045), Vector3(-0.335, 1.74, 0.14),
		Vector3(-0.245, 1.90, -0.045)]
	var pod_parts: Array = []
	for p: Vector3 in pod_at:
		pod_parts.append([cyl(0.006, 0.006, 0.07, 4, false), Transform3D(Basis(), p + Vector3(0, 0.055, 0)), bdark])
		pod_parts.append([sphere(0.054, 6, 3), Transform3D(Basis.from_scale(Vector3(1.0, 1.3, 1.0)), p), glow])
	_pods = add_part(head, GroveKinModel.bake("bs_pods_v3", pod_parts), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE,
		true, "Pods")
	_pods.set_meta(&"own_glow", true)
	# ---- Arms: team bell sleeves with team-dark cuffs, bark-tan hands. The right fist holds the crook.
	add_limb(arm_r, Vector3(0.27, 1.27, 0.04), GRIP, 0.068, straw, 0.07, skin)
	add_part(arm_r, cyl(0.075, 0.115, 0.13, 8, false), cdark, GRIP + Vector3(-0.005, 0.10, -0.03), Vector3(-18, 0, 0))
	add_limb(arm_l, Vector3(-0.27, 1.27, 0.04), GRIP_L, 0.068, straw, 0.07, skin)
	add_part(arm_l, cyl(0.075, 0.115, 0.13, 8, false), cdark, GRIP_L + Vector3(0.005, 0.10, -0.03), Vector3(-18, 0, 0))
	# ---- The crook: thorn-brown shaft (a walking staff: its foot on the ground), a briar vine spiralling up it, three
	# thorns under the hook, the hook curling forward, a glowing bud at its end (the vine's source).
	var sb := Vector3(0.335, 0.05, 0.13)
	var stp := Vector3(0.378, 1.92, 0.245)
	var sd := stp - sb
	add_part(arm_r, cyl(0.028, 0.034, sd.length(), 6), thorn, sb + sd * 0.5, Basis(Quaternion(Vector3.UP, sd.normalized())).get_euler() / DEG)
	add_part(arm_r, _briar_mesh(), nature(&"nature_leaf_dark"), Vector3.ZERO)
	add_part(arm_r, _hook_mesh(), thorn, Vector3.ZERO)
	add_thorns(arm_r, Vector3(0.378, 1.80, 0.24), 3, 0.03, 0.018, 0.10, 62.0, bdark, 20.0)
	add_leaf(arm_r, Vector3(0.40, 2.02, 0.23), Vector3(0.09, 0.03, 0.17), moss, Vector3(-40, 60, 0))
	add_part(arm_r, sphere(0.042, 6, 3), glow, HOOK_TIP + Vector3(0, -0.02, 0), Vector3.ZERO, Vector3(1.0, 1.3, 1.0))
	# ---- The moth wings (keep_separate pivots at the shoulder roots; posed per frame when they move).
	_wing_r = _make_wing(chest, 1.0)
	_wing_l = _make_wing(chest, -1.0)
	# ---- The death mound (at the feet, outside Root so it does not sink with the body): a leafy dome, hidden.
	_mound = Node3D.new()
	_mound.name = "Mound"
	_mound.set_meta(&"keep_separate", true)
	add_child(_mound)
	var mound_parts: Array = [[sphere(0.46, 8, 3), Transform3D(Basis.from_scale(Vector3(1.0, 0.36, 0.9)), Vector3(0, 0.02, 0)), bark]]
	for i: int in 3:
		var a := TAU * float(i) / 3.0 + 0.3
		var out := Vector3(sin(a), 0, cos(a))
		mound_parts.append([leaf_mesh(), leaf_xform(out * 0.18 + Vector3(0, 0.13, 0), out, Vector3(0.20, 0.04, 0.32), 18.0),
			straw if i % 2 == 0 else moss])
	add_part(_mound, GroveKinModel.bake("bs_mound_v3", mound_parts), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "MoundMesh")
	_mound.visible = false
	_mound.scale = Vector3(0.01, 0.01, 0.01)
	# ---- Fx: a slow pollen drift from the pods (looping, stops beyond 45 m), pollen puffs for the casts, moth dust +
	# leaves on hits, leaves on death (pre-built one-shots).
	_drift = make_motes(Color(0.55, 0.60, 0.30), 3, 2.4, 0.22, 0.22, 0.05)
	_drift.name = "PollenDrift"
	_drift.position = Vector3(0, 1.80, 0.06)
	$Fx.add_child(_drift)
	_haze_puff = make_dust(Color(0.90, 0.88, 0.45), 12, 1.3, 0.45, 0.42, 0.9, 80.0)
	_haze_puff.name = "HazePuff"
	_haze_puff.position = Vector3(0, 1.5, -0.1)
	$Fx.add_child(_haze_puff)
	_cloak_puff = make_dust(Color(0.88, 0.84, 0.50), 10, 1.0, 0.55, 0.5, 0.5, 90.0)
	_cloak_puff.name = "CloakPuff"
	_cloak_puff.position = Vector3(0, 1.0, 0)
	$Fx.add_child(_cloak_puff)
	_seed_puff = make_motes(Color(0.85, 0.95, 0.45), 6, 0.5, 0.05, 0.9, 0.07, false, true)
	_seed_puff.name = "SeedPuff"
	$Fx.add_child(_seed_puff)
	add_hit_burst(Vector3(0, 1.3, 0.0), Color(0.86, 0.80, 0.56), 7)
	add_death_bloom(Vector3(0, 0.6, 0), 0.45, 8, 12, Color(0.72, 0.62, 0.34))
	ensure_shadow_blob(0.46, GroveKinModel.KIN_BLOB)


func _war_ready() -> void:
	# The hook bud is merged into the crook arm: its glow is driven here (flares on the spit / the vine), not by the kit.
	_bud = _merged_nodes.get(P_ARM_R)
	if _bud:
		_glow_nodes.erase(_bud)


## FaceKit.attach with a lean style at a coarser decal density (the elder's hair and beard take the face budget).
static var _face_style: Dictionary = {}


func _attach_face(head: Node3D, spec: Dictionary) -> FaceRig:
	if _face_style.is_empty():
		_face_style = UnitFaces.lean(FaceKit.style_from(spec), false, 6.0)
	return FaceKit.attach(self, head, "bramblesage", _face_style)


## A wing pivot at the shoulder root (keep_separate: its own draw, posed in _war_process).
func _make_wing(chest: Node3D, sx: float) -> Node3D:
	var w := Node3D.new()
	w.name = "WingR" if sx > 0.0 else "WingL"
	w.set_meta(&"keep_separate", true)
	var root := Vector3(WING_ROOT.x * sx, WING_ROOT.y, WING_ROOT.z)
	w.position = root - model_origin(chest)
	chest.add_child(w)
	add_part(w, _wing_mesh(sx), null, root, Vector3.ZERO, Vector3.ONE, true, "WingMesh")
	w.basis = _wing_basis(sx, 0.0, 0.0)
	return w


static func _wing_basis(sx: float, yaw_off: float, roll_off: float) -> Basis:
	return Basis(Vector3.UP, (WING_YAW + yaw_off) * sx * DEG) * Basis(Vector3.BACK, roll_off * sx * DEG) \
		* Basis(Vector3.RIGHT, WING_PITCH * DEG)


## The elder's hair for the face mesh (~420 v): a hair cap, swept white crown blades with moss tips, long locks down
## the back and beside the face, a long three-blade beard and a moustache, pointed leaf ears.
static func _elder_hair(acc: Dictionary, col: Color, tip: Color) -> void:
	var c := HC
	var r := HR
	FaceKit.cap(acc, c, r, col, 0.36, 1.0)
	NatureFaces.crown(acc, c, r, 4, col, col.lerp(tip, 0.6), 0.95, 0.36, 170.0)
	for x: float in [-0.045, 0.045]:
		NatureFaces.blade(acc, c + Vector3(x, 0.07, -0.10), c + Vector3(x * 1.6, -0.30, -0.17), 0.07, 0.012,
			Vector3(0, 0.25, -1).normalized(), col, tip, 0.02)
	for sx: float in [-1.0, 1.0]:
		NatureFaces.ear_leaf(acc, c, r, sx, NatureFaces.SKIN, 0.70, 0.38, 0.30)
		NatureFaces.blade(acc, c + Vector3(0.105 * sx, 0.03, 0.02), c + Vector3(0.14 * sx, -0.24, 0.07), 0.030, 0.010,
			Vector3(sx, 0, 0.35).normalized(), col, tip, 0.012)
		NatureFaces.blade(acc, c + Vector3(0.010 * sx, -0.034, 0.128), c + Vector3(0.062 * sx, -0.070, 0.106), 0.012,
			0.006, Vector3(0, 0.3, 1).normalized(), col, col.lerp(tip, 0.3), 0.004)
	# The beard: one broad spade from the jaw line to the chest (a centre blade over two overlapping side blades that
	# start at the cheeks), moss-green at the tip.
	for sx: float in [-1.0, 1.0]:
		NatureFaces.blade(acc, c + Vector3(0.075 * sx, -0.035, 0.085), c + Vector3(0.022 * sx, -0.30, 0.125), 0.045, 0.014,
			Vector3(0.3 * sx, 0.1, 1).normalized(), col, tip, 0.018)
	NatureFaces.blade(acc, c + Vector3(0, -0.07, 0.115), c + Vector3(0, -0.34, 0.13), 0.062, 0.016,
		Vector3(0, 0.1, 1).normalized(), col, tip, 0.02)


# ================================================================ public helpers

## Where the seed bolt starts (world space): the bud at the crook's hook.
func get_beam_origin() -> Vector3:
	return get_hook_position()


## The crook's hook end (world space): where the Snagroot vine leaves.
func get_hook_position() -> Vector3:
	var arm := _piv[P_ARM_R] if _piv.size() > P_ARM_R else null
	if arm and arm.is_inside_tree():
		return arm.global_transform * (HOOK_TIP + Vector3(0, -0.02, 0) - Vector3(0.27, 1.27, 0.04))
	return global_position + Vector3(0.38, 1.92, 0.44)


## The crown of pods (world space): the Pollen Haze flare.
func get_crown_position() -> Vector3:
	if _pods and _pods.is_inside_tree():
		return $Root/Chest/Head.global_transform * (Vector3(0, 1.82, 0.06) - Vector3(0, 1.42, 0.10))
	return global_position + Vector3(0, 1.82, 0)


# ================================================================ poses

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"seed_spit":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, A_ARM_R) * DEG, 0, 0))
	rot(P_CHEST, Vector3(0, _kf(t, A_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _kf(t, A_ROOT_Z)))
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	if t < w:
		_bud_flare = maxf(_bud_flare, 0.6 * t / w)
	if prev < w and t >= w:
		_bud_flare = 1.0
		_on_action_event(&"release")
		if _seed_puff and _tier == 0:
			_seed_puff.global_position = get_hook_position()
			_seed_puff.restart()
	return t < ATTACK_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"snagroot":
			rot(P_ARM_R, Vector3(_kf(t, S_ARM_R) * DEG, 0, 0))
			rot(P_ARM_L, Vector3(_kf(t, S_ARM_L) * DEG, 0, _kf(t, S_ARM_LZ) * DEG))
			rot(P_CHEST, Vector3(_kf(t, S_CHEST_X) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0, _kf(t, S_ROOT_Z)))
			rot(P_LEG_L, Vector3(_kf(t, S_LEG_L) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_kf(t, S_LEG_R) * DEG, 0, 0))
			_wing_yaw = 18.0 * _k3(t, 0.0, VINE_T, 0.30, SNAG_LEN, 1.0, -0.6)
			if t < VINE_T:
				_bud_flare = maxf(_bud_flare, t / VINE_T)
			return SNAG_LEN
		&"pollen_haze":
			_wing_yaw = _kf(t, H_WING_YAW)
			_wing_roll = _kf(t, H_WING_ROLL)
			var a := _kf(t, H_ARMS) * DEG
			var z := _kf(t, H_ARMS_Z) * DEG
			rot(P_ARM_L, Vector3(a, 0, -z))
			rot(P_ARM_R, Vector3(a * 0.45, 0, z * 0.5))
			rot(P_CHEST, Vector3(_kf(t, H_CHEST_X) * DEG, 0, 0))
			rot(P_HEAD, Vector3(-12.0 * DEG * _k3(t, 0.0, 0.28, 0.62, HAZE_LEN, 1.0, 1.0), 0, 0))
			pos(P_ROOT, Vector3(0, _kf(t, H_ROOT_Y), 0))
			_flare = maxf(_flare, 0.5 * _k3(t, 0.0, 0.28, BEAT_T, HAZE_LEN, 1.0, 1.0))
			return HAZE_LEN
		&"seedcloak":
			_wing_yaw = _kf(t, C_WING_YAW)
			_wing_roll = _kf(t, C_WING_ROLL)
			rot(P_CHEST, Vector3(_kf(t, C_CHEST_X) * DEG, 0, 0))
			rot(P_HEAD, Vector3(10.0 * DEG * _k3(t, 0.0, 0.14, 0.26, CLOAK_LEN, 1.0, 1.0), 0, 0))
			pos(P_ROOT, Vector3(0, -0.06 * _k3(t, 0.0, 0.14, 0.26, CLOAK_LEN, 1.0, 1.0), 0))
			return CLOAK_LEN
	return super._pose_cast(spell, t)


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_puffed = false


func _on_kin_hit_flap() -> void:
	_hit_flap.y += 9.0


func play_hit() -> void:
	if not _dead and _t - _last_hit_time >= 0.15:
		_on_kin_hit_flap()
	super.play_hit()


func _war_process(dt: float) -> void:
	# Cast moments: the haze beat flares the pods and puffs pollen; the cloak puffs a ring of seed-dust; the vine
	# leaves the hook.
	if _action == &"cast" and not _puffed:
		match _cast_id:
			&"pollen_haze":
				if _action_t >= BEAT_T:
					_puffed = true
					_flare = 1.0
					if _haze_puff and _tier == 0:
						_haze_puff.restart()
			&"seedcloak":
				if _action_t >= 0.12:
					_puffed = true
					_flare = maxf(_flare, 0.7)
					if _cloak_puff and _tier == 0:
						_cloak_puff.restart()
			&"snagroot":
				if _action_t >= VINE_T:
					_puffed = true
					_bud_flare = 1.0
	# Wings: the posed offsets + a walk flutter + the hit / start-stop spring; the death droop.
	var flutter := 0.0
	if _walk_w > 0.0 and not _dead:
		flutter = 5.0 * sin(TAU * _walk_p * 2.0) * _walk_w
	_hit_flap = GroveKinModel.spring(_hit_flap, 0.0, 0.0, 11.0, 4.5, dt)
	var yaw := _wing_yaw + _hit_flap.x * 10.0
	var roll := _wing_roll + flutter + _hit_flap.x * 6.0
	if _dead:
		var f: float = clampf(_death_t / 0.5, 0.0, 1.0)
		yaw += 20.0 * f
		roll -= 25.0 * f
	if _tier < 2 and (absf(yaw - _wing_written.x) > 0.05 or absf(roll - _wing_written.y) > 0.05):
		_wing_written = Vector2(yaw, roll)
		if _wing_r:
			_wing_r.basis = _wing_basis(1.0, yaw, roll)
		if _wing_l:
			_wing_l.basis = _wing_basis(-1.0, yaw, roll)
	_wing_yaw = 0.0
	_wing_roll = 0.0
	# Glows (pods, bud): veterancy x the flares; dark once dead (glow_level() is 0 then).
	var g := glow_level()
	if _pods:
		var p: float = snappedf(g * (1.6 + 2.4 * _flare), 0.02)
		if p != _pods_written:
			_pods_written = p
			_pods.set_instance_shader_parameter(&"glow_boost", p)
	if _bud:
		var b: float = snappedf(g * (1.0 + 2.6 * _bud_flare), 0.02)
		if b != _bud_written:
			_bud_written = b
			_bud.set_instance_shader_parameter(&"glow_boost", b)
	_flare = maxf(0.0, _flare - dt / 0.5)
	_bud_flare = maxf(0.0, _bud_flare - dt / 0.3)
	# Death: the leaf mound grows at the feet while the body sinks into it.
	var m := 0.0
	if _dead:
		m = _ease_out(clampf((_death_t - 0.15) / 0.55, 0.0, 1.0))
	if m != _mound_written and _mound:
		_mound_written = m
		_mound.visible = m > 0.0
		_mound.scale = Vector3.ONE * maxf(m, 0.01)


func _war_revive() -> void:
	_flare = 0.0
	_bud_flare = 0.0
	_pods_written = -1.0
	_bud_written = -1.0
	_hit_flap = Vector2.ZERO
	_wing_written = Vector2(999.0, 999.0)
	_mound_written = -1.0
	if _mound:
		_mound.visible = false
		_mound.scale = Vector3(0.01, 0.01, 0.01)


## Fidget: strokes his beard with the free hand, looks up at his pods (they brighten, a little pollen falls).
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.45, 1.5, 2.0, 1.0, 1.0)
	var stroke := sin(t * TAU * 1.4) * 8.0 * k
	rot(P_ARM_L, Vector3((-78.0 * k + stroke) * DEG, 0, 22.0 * DEG * k))
	rot(P_HEAD, Vector3(-14.0 * DEG * k, -10.0 * DEG * k, 0))
	_flare = maxf(_flare, 0.35 * k)
	return 2.0
