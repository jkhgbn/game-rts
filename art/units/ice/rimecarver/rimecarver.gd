extends IceModel
## Rimecarver, Ice caster (caster-units.md 5.2 / 10.2, task CU.V2). Height 1.7, radius 0.45. "A mason with a menhir":
## a young rune-mason in a fur-lined team coat (hood down, bunched on the shoulders) and a stone-grey apron, carrying
## a TALL SLAB OF RUNE-ICE strapped to his back (taller than his head: deep steel-blue crystal, iron bands, one cyan
## carver's rune near the top, front and back = glow point 1) and a two-handed MASON'S MAUL held upright at his right
## side (a banded stone-steel head with three small runes on its top face = glow point 2). Read at 40 m: a pointed
## blue menhir behind a team-blue figure + a hammer post at the right hand. No near-white mass (Ice clarity pass):
## the slab is deep steel-blue, only its facet edges catch the light; the coat is the team colour.
## Hooks: the kit's (set_moving, play_attack, play_hit, play_death / death_finished, revive, play_level_up,
## set_veterancy, set_team_color, dances) + play_cast(id):
##   rime_bulwark  0.7 s: the maul is raised overhead and SLAMMED into the ground in front (impact at IMPACT_T: the
##                 maul runes flare, a frost burst at the maul head). Gameplay raises the wall; UnitVfx
##                 `rime_bulwark` draws it (and the frost crack from his feet to it: pass the caster as target).
##   scrying_rune  0.5 s: plucks a rune-pebble from the apron pocket (it shows in the left hand) and throws it
##                 underarm; the pebble leaves the hand at THROW_T (UnitVfx `scrying_rune` lands the stone).
##   anything else: the kit's generic two-arm raise.
## Attack `maul_flick` (0.5 s, release at attack_windup 0.12 s): the maul head taps forward and flicks an ice chip
## (the bolt starts at get_beam_origin(), the maul runes flash). Stillness (passive): standing still 3 s (or
## set_status(&"stillness", true)) makes the back rune pulse slowly. Idle fidget: lifts the maul and blows the frost
## off its runes. Hit: ice chips. Death: freezes over, shatters (IceModel). Level 4: gold headband.
## Draws at rest: 7 merged pivots + face + maul + maul runes + slab rune + blob (pebble hidden) = 12.

const GRIP_R := Vector3(0.34, 0.98, 0.16)            # right fist (model space): the maul's pivot (the "wrist")
const MAUL_DIR := Vector3(0.02, 1.0, 0.10)           # the shaft at rest (up, a little forward)
const MAUL_HEAD := 0.98                              # fist -> head centre along the shaft (m)
const GRIP_L := Vector3(-0.33, 0.95, 0.08)           # left fist (the pebble hand)
const SLAB_Z := -0.37                                # the slab's centre line at y 1.4
const SLAB_TILT := 4.0                               # deg, the slab leans back
const RUNE_Y := 1.79                                 # the carver's rune on the slab (above the head)
const BULWARK_LEN := 0.7
const IMPACT_T := 0.40
const SCRY_LEN := 0.5
const THROW_T := 0.31
const FLICK_LEN := 0.5
const STILL_TIME := 3.0

# Keyframe tracks [t, value, ease, ...] (ease 0 smooth, 1 ease-out, 2 ease-in; NatureWarModel._kf format).
# Arm x: - swings the arm forward / up. Wrist: + tips the maul head forward (the head is UP from the fist).
static var B_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.26, -165.0, 1, IMPACT_T, -38.0, 2, 0.55, -36.0, 0, BULWARK_LEN, 0.0, 0])
static var B_WRIST := PackedFloat32Array([0.0, 0.0, 0, 0.26, -18.0, 1, IMPACT_T, 168.0, 2, 0.55, 162.0, 0, BULWARK_LEN, 0.0, 0])
static var B_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.26, -150.0, 1, IMPACT_T, -52.0, 2, 0.55, -50.0, 0, BULWARK_LEN, 0.0, 0])
static var B_ARM_LZ := PackedFloat32Array([0.0, 0.0, 0, 0.26, 18.0, 1, IMPACT_T, 34.0, 2, 0.55, 32.0, 0, BULWARK_LEN, 0.0, 0])
static var B_CHEST := PackedFloat32Array([0.0, 0.0, 0, 0.26, -12.0, 1, IMPACT_T, 26.0, 2, 0.55, 22.0, 0, BULWARK_LEN, 0.0, 0])
static var B_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.26, -14.0, 1, IMPACT_T, 10.0, 2, 0.55, 8.0, 0, BULWARK_LEN, 0.0, 0])
static var B_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.26, 0.03, 1, IMPACT_T, -0.15, 2, 0.55, -0.13, 0, BULWARK_LEN, 0.0, 0])
static var B_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.26, -10.0, 1, IMPACT_T, -30.0, 2, 0.55, -28.0, 0, BULWARK_LEN, 0.0, 0])
static var B_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.26, 6.0, 1, IMPACT_T, 20.0, 2, 0.55, 18.0, 0, BULWARK_LEN, 0.0, 0])
static var S_ARM_L := PackedFloat32Array([0.0, 0.0, 0, 0.14, 48.0, 1, THROW_T, -112.0, 2, 0.38, -104.0, 0, SCRY_LEN, 0.0, 0])
static var S_ARM_LZ := PackedFloat32Array([0.0, 0.0, 0, 0.12, 6.0, 0, THROW_T, -10.0, 0, SCRY_LEN, 0.0, 0])
static var S_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.14, 24.0, 1, THROW_T, -22.0, 2, SCRY_LEN, 0.0, 0])
static var S_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, 10.0, 0, THROW_T, -4.0, 0, SCRY_LEN, 0.0, 0])
static var S_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, 12.0, 0, THROW_T, -6.0, 0, SCRY_LEN, 0.0, 0])
static var S_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.05, 1, THROW_T, 0.0, 0, SCRY_LEN, 0.0, 0])
static var F_ARM_R := PackedFloat32Array([0.0, 0.0, 0, 0.07, -22.0, 1, 0.13, -52.0, 2, 0.30, -44.0, 0, FLICK_LEN, 0.0, 0])
static var F_WRIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, -28.0, 1, 0.13, 74.0, 2, 0.30, 62.0, 0, FLICK_LEN, 0.0, 0])
static var F_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.07, 14.0, 1, 0.13, -16.0, 2, FLICK_LEN, 0.0, 0])
static var F_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, -0.04, 1, 0.13, 0.07, 2, FLICK_LEN, 0.0, 0])

var _maul: Node3D
var _maul_runes: GeometryInstance3D
var _slab_rune: GeometryInstance3D
var _pebble: Node3D
var _impact: GPUParticles3D
var _impact_mist: GPUParticles3D
var _wrist: float = 0.0
var _wrist_written: float = 99.0
var _flare: float = 0.0
var _runes_written: float = -1.0
var _slab_written: float = -1.0
var _still_t: float = 0.0
var _still_w: float = 0.0
var _still_forced: bool = false
var _pebble_on: bool = false
var _fidget_puffed: bool = false


static func _kf(t: float, k: PackedFloat32Array) -> float:
	var n: int = k.size()
	if t >= k[n - 3]:
		return k[n - 2]
	if t <= 0.0:
		return k[1]
	var i: int = 3
	while t >= k[i]:
		i += 3
	var t0: float = k[i - 3]
	var u: float = (t - t0) / (k[i] - t0)
	var e: float = k[i + 2]
	if e == 1.0:
		u = u * (2.0 - u)
	elif e == 2.0:
		u = u * u
	else:
		u = u * u * (3.0 - 2.0 * u)
	return k[i - 2] + (k[i + 1] - k[i - 2]) * u


# ================================================================ meshes (static, cached per type)

## The rune-ice menhir: an 8-sided chiselled block tapering to a leaning point (smooth-indexed; ice_crystal shades the
## facets flat from screen derivatives). Rings: (y, half width, half thickness, x offset), apex apart. ~60 vertices.
static func _slab_mesh() -> Mesh:
	const KEY := "rc_slab_v4"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var rings: Array[Vector4] = [Vector4(0.60, 0.19, 0.070, 0.0), Vector4(0.78, 0.235, 0.082, 0.0),
		Vector4(1.25, 0.255, 0.088, -0.01), Vector4(1.63, 0.235, 0.082, 0.0), Vector4(1.84, 0.17, 0.070, 0.025),
		Vector4(1.96, 0.095, 0.050, 0.045)]
	var apex := Vector3(0.07, 2.065, 0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 8
	var idx: Array[PackedInt32Array] = []
	var vi := 0
	for r: int in rings.size():
		var g := rings[r]
		var ring := PackedInt32Array()
		for j: int in n:
			# chamfered rectangle: corners cut, a deterministic chisel jitter per vertex
			var pts := [Vector2(1.0, 0.35), Vector2(0.72, 1.0), Vector2(-0.72, 1.0), Vector2(-1.0, 0.35),
				Vector2(-1.0, -0.35), Vector2(-0.72, -1.0), Vector2(0.72, -1.0), Vector2(1.0, -0.35)]
			var p: Vector2 = pts[j]
			var jit := 1.0 + 0.07 * sin(float(r * 13 + j * 7) * 1.7)
			st.add_vertex(Vector3(p.x * g.y * jit + g.w, g.x + 0.012 * sin(float(j * 5 + r) * 2.3), p.y * g.z * jit))
			ring.append(vi)
			vi += 1
		idx.append(ring)
	st.add_vertex(apex)
	var apex_i := vi
	vi += 1
	st.add_vertex(Vector3(0, rings[0].x - 0.02, 0))
	var bot_i := vi
	for r: int in rings.size() - 1:
		for j: int in n:
			var a := idx[r][j]
			var b := idx[r][(j + 1) % n]
			var c := idx[r + 1][j]
			var d := idx[r + 1][(j + 1) % n]
			st.add_index(a); st.add_index(d); st.add_index(b)
			st.add_index(a); st.add_index(c); st.add_index(d)
	var top := idx[rings.size() - 1]
	for j: int in n:
		st.add_index(top[j]); st.add_index(apex_i); st.add_index(top[(j + 1) % n])
		st.add_index(idx[0][j]); st.add_index(idx[0][(j + 1) % n]); st.add_index(bot_i)
	st.generate_normals()
	return _cached(KEY, st.commit())


## z of the slab's centre line at model height y (it leans back SLAB_TILT deg about y 1.4).
static func _slab_z(y: float) -> float:
	return SLAB_Z - (y - 1.4) * sin(SLAB_TILT * DEG)


## The carver's rune (an original glyph: a stem, two branches rising from its middle, a foot bar, a dot over the
## stem), flat boxes baked into one mesh lying in the XY plane (faces +Z), about 0.28 m tall.
static func _rune_mesh() -> Mesh:
	const KEY := "rc_rune_v1"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var bars: Array = [
		[Vector3(0.036, 0.22, 0.02), Vector3(0, 0.0, 0), 0.0],
		[Vector3(0.032, 0.13, 0.02), Vector3(-0.05, 0.05, 0), 40.0],
		[Vector3(0.032, 0.13, 0.02), Vector3(0.05, 0.05, 0), -40.0],
		[Vector3(0.12, 0.032, 0.02), Vector3(0, -0.11, 0), 0.0],
		[Vector3(0.05, 0.05, 0.02), Vector3(0, 0.155, 0), 45.0],
	]
	for b: Array in bars:
		st.append_from(box(b[0]), 0, Transform3D(Basis(Vector3.BACK, deg_to_rad(float(b[2]))), b[1]))
	st.index()
	return _cached(KEY, st.commit())


## Cheap ash-blond crop for the face mesh (~330 v): a hair cap, 5 swept crown blades (the pale cap the RTS camera
## sees), a short two-blade fringe, low round ears, a light two-blade moustache.
static func _crop_hair(acc: Dictionary, c: Vector3, r: float, col: Color, tip: Color) -> void:
	FaceKit.cap(acc, c, r, col, 0.42, 0.95)
	NatureFaces.crown(acc, c, r, 5, col, tip, 0.85, 0.28, 160.0)
	NatureFaces.fringe(acc, c, r, 2, col, tip, 0.45, 0.55, 0.22)
	for sx: float in [-1.0, 1.0]:
		NatureFaces.ear_round(acc, c, r, sx, ICE_SKIN)
		var root := c + Vector3(0.010 * sx, -0.034, 0.136)
		var end := c + Vector3(0.058 * sx, -0.066, 0.112)
		NatureFaces.blade(acc, root, end, 0.011, 0.006, Vector3(0, 0.3, 1).normalized(), col.darkened(0.08), tip, 0.004)


# ================================================================ build

func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := ice(&"ice_cloth")
	var cdark := ice(&"ice_cloth_dark")
	var leather := ice(&"ice_leather")
	var steel := ice(&"ice_steel")
	var metal := ice(&"ice_metal")
	var sdark := ice(&"ice_stone_dark")
	var wood := ice(&"ice_wood")
	var skin := ice(&"ice_skin")
	var glow := ice(&"ice_glow_unit")
	# ---- Legs: steel-blue trousers, dark fur boots with a turned-down cuff.
	# (G-C leftovers 2026-10-15: shaped trousers with a knee, lathed fur boots with a jagged cuff.)
	IceUnitShapes.put(self, leg_l, "rc_gc_leg_l", func(acc: Dictionary) -> void: _gc_leg(acc, -1.0))
	IceUnitShapes.put(self, leg_r, "rc_gc_leg_r", func(acc: Dictionary) -> void: _gc_leg(acc, 1.0))
	# ---- Hips: the team coat's skirt (folded, knee length) over a dark fur hem, the stone-grey mason's apron with a
	# pocket of rune pebbles, a leather belt with an iron buckle and a pouch.
	var coat := PackedVector2Array([Vector2(0.205, 0.98), Vector2(0.235, 0.86), Vector2(0.27, 0.72), Vector2(0.305, 0.58),
		Vector2(0.335, 0.46), Vector2(0.35, 0.40)])
	add_part(hips, GroveKinModel.lathe("rc_coat_v1", coat, 12, 5, 0.07, 2, 0.02), cdark, Vector3.ZERO)
	IceUnitShapes.put(self, hips, "rc_gc_hips", _gc_hips)
	# ---- Chest: team coat torso, dark placket, a dark fur collar (the hood's lining), the hood bunched on the back,
	# leather harness straps over the shoulders to the slab. The SLAB: deep rune-ice, two iron bands, the rune.
	add_part(chest, sphere(0.19, 8, 4), cloth, Vector3(0, 1.40, -0.17), Vector3(-15, 0, 0), Vector3(1.15, 0.75, 0.8))
	IceUnitShapes.put(self, chest, "rc_gc_chest", _gc_chest)
	# The slab leans back SLAB_TILT deg about its middle (y 1.4): its centre line is z = _slab_z(y).
	add_part(chest, _slab_mesh(), ice(&"ice_frost_deep"), Vector3(0, 0, SLAB_Z + 1.4 * sin(SLAB_TILT * DEG)),
		Vector3(-SLAB_TILT, 0, 0))
	# The carver's rune on both faces of the slab near its top (keep_separate: it pulses with Stillness).
	var zr := _slab_z(RUNE_Y)
	var rune_parts: Array = [
		[_rune_mesh(), Transform3D(Basis(Vector3.RIGHT, -SLAB_TILT * DEG), Vector3(0.02, RUNE_Y, zr + 0.079)), glow],
		[_rune_mesh(), Transform3D(Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, SLAB_TILT * DEG), Vector3(0.02, RUNE_Y - 0.12,
			_slab_z(RUNE_Y - 0.12) - 0.083)), glow],
	]
	_slab_rune = add_part(chest, GroveKinModel.bake("rc_slab_rune_v1", rune_parts), null, Vector3.ZERO, Vector3.ZERO,
		Vector3.ONE, true, "SlabRune")
	_slab_rune.set_meta(&"own_glow", true)
	# ---- Head: neck, skin head, FaceKit face (bright young mason: ash-blond crop, round ears, a light moustache,
	# ice-blue eyes, wind-red cheeks, a small determined smile). Hair is ash-blond, not white (clarity pass).
	var hc := Vector3(0, 1.53, 0.03)
	add_part(head, cyl(0.065, 0.075, 0.10, 8), skin, Vector3(0, 1.41, 0.01))
	add_part(head, sphere(0.14, 10, 6), skin, hc)
	# Budget face (soldier allowance 800 v): lean decals, a cheap crop (a cap + swept blades), low round ears and a
	# two-blade moustache instead of the kit's lock presets (~1400 v).
	var hair := Color(0.84, 0.70, 0.40)
	var tip := Color(0.95, 0.88, 0.62)
	_face = UnitFaces.attach_lean(self, head, "rimecarver", {"center": hc, "radius": 0.14,
		"head_mesh": sphere(0.14, 10, 6), "preset": &"bright", "detail": &"low", "skin": ICE_SKIN, "hair": hair,
		"hair_tip": tip, "eyes": Color(0.55, 0.78, 0.95), "ears": &"none",
		"palette": {"brow": Color(0.52, 0.40, 0.22), "lash": Color(0.14, 0.13, 0.16),
			"blush": ICE_SKIN.lerp(Color(0.92, 0.30, 0.28), 0.8)},
		"eye": {"c": Vector2(0.050, 0.022)}, "mouth": {"c": Vector2(0.0, -0.058), "hw": 0.028},
		"x": {&"neutral": {"mouth": {"kind": "closed", "curve": 1.35, "w": 0.9}, "blush": 1.3}},
		"hair_fn": func(acc: Dictionary) -> void:
			_crop_hair(acc, hc, 0.14, hair, tip)})
	var trim := add_part(head, torus(0.135, 0.165, 12), palette(&"unit_gold_trim"), Vector3(0, 1.60, 0.02),
		Vector3(-8, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Arms: team sleeves, dark fur cuffs, leather gloves. Right fist holds the maul; the left hangs by the pouch.
	IceUnitShapes.put(self, arm_r, "rc_gc_arm_r", func(acc: Dictionary) -> void: _gc_arm(acc, 1.0))
	IceUnitShapes.put(self, arm_l, "rc_gc_arm_l", func(acc: Dictionary) -> void: _gc_arm(acc, -1.0))
	# ---- The maul (keep_separate "wrist" pivot at the right fist): ash shaft, leather grip, iron pommel, a banded
	# stone-steel head across the swing (long axis along Z), three runes on its top face.
	_maul = Node3D.new()
	_maul.name = "Maul"
	_maul.set_meta(&"keep_separate", true)
	_maul.position = GRIP_R - model_origin(arm_r)
	arm_r.add_child(_maul)
	var d := MAUL_DIR.normalized()
	var along := Basis(Quaternion(Vector3.UP, d))
	var e := along.get_euler() / DEG
	var hp := GRIP_R + d * MAUL_HEAD
	# G-C leftovers: a tapered ash shaft with a swelling at the grip, an octagonal chamfered stone head (flat faces up /
	# down, the runes on the top face) with steel collars at both ends and a steel socket where the shaft goes in.
	var head_xf := Transform3D(along * Basis(Vector3.RIGHT, PI * 0.5), hp - GRIP_R)
	var maul_parts: Array = [
		[IceUnitShapes.mesh("rc_gc_maul_shaft", func(s: SurfaceTool) -> void:
			ChampionShapes.tube(s, PackedVector3Array([d * -0.30, d * 0.08, d * 0.55, d * 0.90]),
				PackedFloat32Array([0.034, 0.032, 0.027, 0.030]), 6, true)), Transform3D.IDENTITY, wood],
		[IceUnitShapes.mesh("rc_gc_maul_grip", func(s: SurfaceTool) -> void:
			for k: int in 3:
				ChampionShapes.band(s, 0.031, 0.05, 0.008, 6, IceUnitShapes.on(d, d * (-0.06 + 0.07 * k)))), Transform3D.IDENTITY,
			leather],
		[IceUnitShapes.mesh("rc_gc_maul_pommel", func(s: SurfaceTool) -> void:
			ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.0, -0.06), Vector2(0.042, -0.035), Vector2(0.045, 0.0),
				Vector2(0.03, 0.03)]), 6, IceUnitShapes.on(d, d * -0.31), 1.0, 1.0, false)), Transform3D.IDENTITY, metal],
		[IceUnitShapes.mesh("rc_gc_maul_head", func(s: SurfaceTool) -> void:
			ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.074, -0.17), Vector2(0.097, -0.15), Vector2(0.097, 0.15),
				Vector2(0.074, 0.17)]), 8, Transform3D.IDENTITY, 0.9, 1.0, true, PI / 8.0, PI / 8.0 + TAU, true)), head_xf, sdark],
		[IceUnitShapes.mesh("rc_gc_maul_collars", func(s: SurfaceTool) -> void:
			for z: float in [-0.12, 0.12]:
				ChampionShapes.band(s, 0.095, 0.045, 0.014, 8, Transform3D(Basis.IDENTITY, Vector3(0, z, 0)), 0.9, 1.0)
			ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.05, 0.0), Vector2(0.044, 0.05), Vector2(0.036, 0.075)]), 6,
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.07)), 1.0, 1.0, false)), head_xf, steel],
	]
	add_part(_maul, GroveKinModel.bake("rc_maul_v2", maul_parts), null, GRIP_R, Vector3.ZERO, Vector3.ONE, true, "MaulMesh")
	var mr: Array = []
	for k: int in 3:
		mr.append([box(Vector3(0.06, 0.024, 0.06)), Transform3D(along * Basis(Vector3.UP, PI * 0.25),
			hp - GRIP_R + along * Vector3(0, 0.092, -0.10 + 0.10 * k)), glow])
	_maul_runes = add_part(_maul, GroveKinModel.bake("rc_maul_runes_v1", mr), null, GRIP_R, Vector3.ZERO, Vector3.ONE,
		true, "MaulRunes")
	_maul_runes.set_meta(&"own_glow", true)
	# ---- The rune pebble (left hand, shown only during Scrying Rune): a grey river stone with a cyan rune dot.
	_pebble = Node3D.new()
	_pebble.name = "Pebble"
	_pebble.set_meta(&"keep_separate", true)
	_pebble.position = GRIP_L + Vector3(0, -0.02, 0.05) - model_origin(arm_l)
	arm_l.add_child(_pebble)
	var pb: Array = [
		[sphere(0.055, 8, 4), Transform3D(Basis.from_scale(Vector3(1.0, 0.75, 1.0)), Vector3.ZERO), sdark],
		[sphere(0.022, 6, 3), Transform3D(Basis(), Vector3(0, 0.035, 0.02)), glow],
	]
	add_part(_pebble, GroveKinModel.bake("rc_pebble_v1", pb), null, GRIP_L + Vector3(0, -0.02, 0.05), Vector3.ZERO,
		Vector3.ONE, true, "PebbleMesh")
	_pebble.visible = false
	# ---- Fx: frost breath, hit chips, the shatter death, the maul's impact burst (pre-built one-shots).
	add_breath(Vector3(0, 1.47, 0.19), 0.18)
	add_hit_chips(Vector3(0, 1.15, 0.12), 6)
	add_shatter(Vector3(0, 0.95, -0.05), 14, 0.4, 0.11)
	_impact = _shards(10, 0.8, 0.15, 2.0, 3.6, 55.0, Vector3.UP, 0.075)
	_impact.name = "MaulImpact"
	$Fx.add_child(_impact)
	_impact_mist = _puffs(0.5, 6, 0.8, 0.95, 0.18, Vector3.UP, 70.0, 0.4, 0.9, Vector3(0, 0.2, 0), 0.45)
	_impact_mist.name = "MaulMist"
	$Fx.add_child(_impact_mist)
	ensure_shadow_blob(0.45, BLOB_TINT)


# ---- G-C leftovers (2026-10-15): shaped pieces (IceUnitShapes / ChampionShapes, cached per process, model space).

func _gc_leg(acc: Dictionary, sx: float) -> void:
	IceUnitShapes.limb(IceUnitShapes.st(acc, ice(&"ice_steel")), Vector3(0.12 * sx, 0.80, 0.0), Vector3(0.125 * sx, 0.50, 0.03),
		Vector3(0.13 * sx, 0.22, 0.01), 0.09, 0.075, 0.066, 7)
	var fur := IceUnitShapes.st(acc, ice(&"ice_fur"))
	ChampionShapes.append(fur, boot(0.10, 0.17), IceUnitShapes.xf(Vector3(0.13 * sx, 0.0, 0.035), Vector3.ZERO, Vector3(0.95, 1.0, 1.45)))
	ChampionShapes.append(fur, fur_ring(0.085, 0.118, 0.07, 4, 0.03), Transform3D(Basis.IDENTITY, Vector3(0.13 * sx, 0.18, 0.01)))


## Fur hem, the curved stone-grey apron (dark hem, a pocket with three rune pebbles), the belt, buckle and pouch.
func _gc_hips(acc: Dictionary) -> void:
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur")), fur_ring(0.33, 0.38, 0.09, 6, 0.04),
		Transform3D(Basis.IDENTITY, Vector3(0, 0.355, 0)))
	ChampionShapes.lame(IceUnitShapes.st(acc, ice(&"ice_sec_carver")), 0.39, 0.255, 0.38, 0.95, -0.52, 0.52, 5, 0.022)
	var sdark := IceUnitShapes.st(acc, ice(&"ice_stone_dark"))
	ChampionShapes.lame(sdark, 0.402, 0.392, 0.372, 0.425, -0.53, 0.53, 5, 0.024)
	ChampionShapes.lame(sdark, 0.352, 0.334, 0.57, 0.69, -0.30, 0.30, 3, 0.02)
	var metal := IceUnitShapes.st(acc, ice(&"ice_metal"))
	for k: int in 3:
		var a: float = -0.16 + 0.16 * k
		ChampionShapes.stud(metal, Vector3(sin(a) * 0.335, 0.695, cos(a) * 0.335), Vector3(sin(a), 0.6, cos(a)), 0.03)
	var leather := IceUnitShapes.st(acc, ice(&"ice_leather"))
	ChampionShapes.band(leather, 0.232, 0.065, 0.016, 12, Transform3D(Basis.IDENTITY, Vector3(0, 0.93, 0)))
	ChampionShapes.plate(metal, PackedVector2Array([Vector2(-0.045, 0.035), Vector2(0.045, 0.035), Vector2(0.045, -0.035),
		Vector2(-0.045, -0.035)]), 0.022, 0.009, Transform3D(Basis.IDENTITY, Vector3(0, 0.93, 0.252)))
	IceUnitShapes.egg(leather, IceUnitShapes.xf(Vector3(-0.25, 0.85, 0.08), Vector3(0, 20, 0), Vector3(1.0, 1.0, 0.75)), 0.065, 0.15, 6)


## Coat torso (shoulder slope), the dark placket with toggles, the fur collar, harness straps over the shoulders to
## the slab, the slab's two iron bands.
func _gc_chest(acc: Dictionary) -> void:
	ChampionShapes.lathe(IceUnitShapes.st(acc, ice(&"ice_cloth")), PackedVector2Array([Vector2(0.245, 0.94), Vector2(0.25, 1.06),
		Vector2(0.236, 1.24), Vector2(0.20, 1.36), Vector2(0.12, 1.42)]), 12, Transform3D.IDENTITY, 1.0, 0.9, false)
	ChampionShapes.plate(IceUnitShapes.st(acc, ice(&"ice_cloth_dark")), PackedVector2Array([Vector2(-0.03, 0.22),
		Vector2(0.03, 0.22), Vector2(0.034, -0.22), Vector2(-0.034, -0.22)]), 0.024, 0.008,
		IceUnitShapes.xf(Vector3(0, 1.15, 0.222), Vector3(-5, 0, 0)))
	var metal := IceUnitShapes.st(acc, ice(&"ice_metal"))
	for y: float in [1.04, 1.16, 1.28]:
		ChampionShapes.stud(metal, Vector3(0, y, 0.236 - (y - 1.15) * 0.09), Vector3(0, 0, 1), 0.018)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur")), fur_ring(0.13, 0.25, 0.10, 6, 0.03),
		Transform3D(Basis.IDENTITY, Vector3(0, 1.335, 0)))
	var leather := IceUnitShapes.st(acc, ice(&"ice_leather"))
	for sx: float in [-1.0, 1.0]:
		IceUnitShapes.strap(leather, PackedVector3Array([Vector3(0.14 * sx, 0.98, 0.22), Vector3(0.15 * sx, 1.20, 0.226),
			Vector3(0.155 * sx, 1.36, 0.17), Vector3(0.16 * sx, 1.44, 0.02), Vector3(0.16 * sx, 1.40, -0.16),
			Vector3(0.15 * sx, 1.30, -0.27)]), 0.065, 0.022)
	var steel := IceUnitShapes.st(acc, ice(&"ice_steel"))
	for y: float in [1.00, 1.58]:
		ChampionShapes.band(steel, 0.262, 0.065, 0.018, 8, Transform3D(Basis(Vector3.RIGHT, -SLAB_TILT * DEG), Vector3(0, y, _slab_z(y))),
			1.0, 0.37)


## Sleeve with an elbow bend, the fur cuff, the leather glove (the right one wraps the maul's grip).
func _gc_arm(acc: Dictionary, sx: float) -> void:
	var sh := Vector3(0.29 * sx, 1.32, 0.0)
	var hand: Vector3 = GRIP_R if sx > 0.0 else GRIP_L
	var elbow := Vector3(0.33 * sx, 1.135, 0.01)
	IceUnitShapes.limb(IceUnitShapes.st(acc, ice(&"ice_cloth_dark")), sh, elbow, hand, 0.078, 0.07, 0.062, 6)
	var fd := (hand - elbow).normalized()
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur")), fur_ring(0.07, 0.095, 0.07, 4, 0.025),
		IceUnitShapes.on(-fd, hand - fd * 0.10))
	IceUnitShapes.egg(IceUnitShapes.st(acc, ice(&"ice_leather")), IceUnitShapes.on(fd, hand - fd * 0.01), 0.075, 0.16, 6)


func _ice_ready() -> void:
	# The slab is the biggest mass seen from the RTS camera: it takes the hit flash with the body.
	var chest_m: MeshInstance3D = _merged_nodes.get(P_CHEST)
	if chest_m and not _flash_hit_targets.has(chest_m):
		_flash_hit_targets.append(chest_m)


# ================================================================ public helpers

## Where the attack bolt / chip starts (world space): the maul head's runes.
func get_beam_origin() -> Vector3:
	if _maul_runes and _maul_runes.is_inside_tree():
		return _maul.global_transform * (MAUL_DIR.normalized() * (MAUL_HEAD + 0.1))
	return global_position + Vector3.UP * 1.9


## The maul head (world space): where the slam lands, where a frost crack starts.
func get_maul_head_position() -> Vector3:
	if _maul and _maul.is_inside_tree():
		return _maul.global_transform * (MAUL_DIR.normalized() * MAUL_HEAD)
	return global_position + Vector3(0.3, 1.9, 0.3)


## The carver's rune on the slab (world space).
func get_rune_position() -> Vector3:
	if _slab_rune and _slab_rune.is_inside_tree():
		return $Root/Chest.global_transform * (Vector3(0.02, RUNE_Y, _slab_z(RUNE_Y) + 0.08) - Vector3(0, 0.95, 0))
	return global_position + Vector3(0, RUNE_Y, _slab_z(RUNE_Y))


## True while the Stillness pulse shows (3 s standing still, or forced by set_status).
func is_still() -> bool:
	return _still_w > 0.5


func set_status(id: StringName, on: bool) -> bool:
	if id == &"stillness":
		_still_forced = on
		return true
	return super.set_status(id, on)


# ================================================================ poses

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"maul_flick":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, F_ARM_R) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_kf(t, F_ARM_R) * 0.3 * DEG, 0, 0))
	rot(P_CHEST, Vector3(0, _kf(t, F_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _kf(t, F_ROOT_Z)))
	_wrist = _kf(t, F_WRIST) * DEG
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	if t < w:
		_flare = maxf(_flare, 0.6 * t / w)
	if prev < w and t >= w:
		_flare = 1.0
		_on_action_event(&"release")
	return t < FLICK_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"rime_bulwark":
			rot(P_ARM_R, Vector3(_kf(t, B_ARM_R) * DEG, 0, -8.0 * DEG * _k3(t, 0.0, 0.26, IMPACT_T, BULWARK_LEN, 1.0, 1.0)))
			rot(P_ARM_L, Vector3(_kf(t, B_ARM_L) * DEG, 0, _kf(t, B_ARM_LZ) * DEG))
			rot(P_CHEST, Vector3(_kf(t, B_CHEST) * DEG, 0, 0))
			rot(P_HEAD, Vector3(_kf(t, B_HEAD) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, _kf(t, B_ROOT_Y), 0))
			rot(P_LEG_L, Vector3(_kf(t, B_LEG_L) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_kf(t, B_LEG_R) * DEG, 0, 0))
			_wrist = _kf(t, B_WRIST) * DEG
			if t < IMPACT_T:
				_flare = maxf(_flare, 0.7 * t / IMPACT_T)
			return BULWARK_LEN
		&"scrying_rune":
			rot(P_ARM_L, Vector3(_kf(t, S_ARM_L) * DEG, 0, _kf(t, S_ARM_LZ) * DEG))
			rot(P_CHEST, Vector3(_kf(t, S_CHEST_X) * DEG, _kf(t, S_CHEST_Y) * DEG, 0))
			rot(P_HEAD, Vector3(_kf(t, S_HEAD_X) * DEG, _kf(t, S_CHEST_Y) * -0.4 * DEG, 0))
			pos(P_ROOT, Vector3(0, _kf(t, S_ROOT_Y), 0))
			rot(P_ARM_R, Vector3(-10.0 * DEG * _k3(t, 0.0, 0.12, THROW_T, SCRY_LEN, 1.0, 1.0), 0, 0))
			rot(P_LEG_L, Vector3(-22.0 * DEG * _k3(t, 0.08, THROW_T, 0.38, SCRY_LEN, 1.0, 1.0), 0, 0))
			rot(P_LEG_R, Vector3(12.0 * DEG * _k3(t, 0.08, THROW_T, 0.38, SCRY_LEN, 1.0, 1.0), 0, 0))
			_set_pebble(t >= 0.10 and t < THROW_T)
			if t >= THROW_T and t < THROW_T + 0.12:
				_flare = maxf(_flare, 0.5)
			return SCRY_LEN
	return super._pose_cast(spell, t)


func _on_action_event(ev: StringName) -> void:
	if ev == &"cast_start":
		_fidget_puffed = false
	elif ev == &"cast_end" or ev == &"attack_end":
		_set_pebble(false)


func _ice_process(dt: float) -> void:
	# The slam lands: runes flare, frost chips and mist burst at the maul head (within 30 m).
	if _action == &"cast" and _cast_id == &"rime_bulwark" and _action_t >= IMPACT_T and _action_t - dt < IMPACT_T:
		_flare = 1.0
		if _tier == 0 and _impact:
			var hp := get_maul_head_position()
			_impact.global_position = hp
			_impact.restart()
			_impact_mist.global_position = Vector3(hp.x, global_position.y + 0.1, hp.z)
			_impact_mist.restart()
	# The maul's wrist (posed this frame by the attack / cast / fidget, 0 otherwise).
	if _maul and absf(_wrist - _wrist_written) > 0.001:
		_wrist_written = _wrist
		_maul.rotation = Vector3(_wrist, 0.0, 0.0)
	_wrist = 0.0
	# Stillness: 3 s without moving (or forced) -> the back rune pulses slowly.
	if _dead:
		_still_t = 0.0
	elif _speed < 0.3 and _action != &"attack":
		_still_t += dt
	else:
		_still_t = 0.0
	var still_on := _still_forced or _still_t >= STILL_TIME
	_still_w = move_toward(_still_w, 1.0 if still_on and not _dead else 0.0, dt / 0.6)
	var g := glow_level()
	if _slab_rune:
		var pulse := 0.5 + 0.5 * sin((_t + _phase_off) * TAU / 2.4)
		var s: float = snappedf(g * (1.0 + (0.35 + 0.9 * pulse) * _still_w + 1.2 * _flare), 0.02)
		if s != _slab_written:
			_slab_written = s
			_slab_rune.set_instance_shader_parameter(&"glow_boost", s)
	if _maul_runes:
		var m: float = snappedf(g * (1.5 + 2.0 * _flare), 0.02)
		if m != _runes_written:
			_runes_written = m
			_maul_runes.set_instance_shader_parameter(&"glow_boost", m)
	_flare = maxf(0.0, _flare - dt / 0.35)


## The freeze-over before the shatter (IceModel): at 0.3 of the kit strength, so the frozen body reads steel-blue
## frost instead of a near-white blob (Ice clarity pass: no white masses, in-game check 2026-09-30).
func _write_freeze(v: float) -> void:
	super._write_freeze(v * 0.3)


func _set_pebble(on: bool) -> void:
	if _pebble and on != _pebble_on:
		_pebble_on = on
		_pebble.visible = on


func _ice_revive() -> void:
	_flare = 0.0
	_wrist = 0.0
	_wrist_written = 99.0
	_runes_written = -1.0
	_slab_written = -1.0
	_still_t = 0.0
	_still_w = 0.0
	_set_pebble(false)
	if _maul:
		_maul.rotation = Vector3.ZERO


## Fidget: lifts the maul to eye level, blows the frost off its runes (a breath puff, the runes brighten).
func _pose_fidget(t: float) -> float:
	if t < 0.05:
		_fidget_puffed = false
	var k := _k3(t, 0.0, 0.45, 1.3, 1.8, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-38.0 * DEG * k, 0, -10.0 * DEG * k))
	_wrist = -22.0 * DEG * k
	rot(P_HEAD, Vector3(6.0 * DEG * k, 24.0 * DEG * k, 0))
	rot(P_CHEST, Vector3(0, 10.0 * DEG * k, 0))
	if not _fidget_puffed and t >= 0.7:
		_fidget_puffed = true
		puff_breath()
	if t >= 0.7 and t < 1.3:
		_flare = maxf(_flare, 0.45)
	return 1.8
