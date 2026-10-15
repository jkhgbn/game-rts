extends CharacterModel
## The Wayfinder (champions.md 4.6, task 9.V1): a free-agent scout in a long moss-green split coat, a wide-brimmed
## traveller's hat with the sides curled up, tall leather boots and a short recurve bow in the right hand. On the back:
## a pack with a canvas bedroll and a map tube, and the signature LANTERN POLE (top 2.6 m, narrow) whose crook bends
## outward and carries a hanging lantern (the one glow point: (1.0, 0.8, 0.4), energy 1.5 x boost 2 = the 3.0 halo), clear
## of the hat in the black test; a crossbar holds the team pennant right above the hat.
## Team colour (set_team_color, kit recolour of `*_pennon`): the waist sash + its two tails and the back pennant only.
## Variant B (Tobin, the brother) = ONE toggled node "Variant" under Head: A (Tamsin) = back hair + a long auburn braid
## over the left shoulder; B = back hair + bushy beard + a pale feather in the hat band (the mesh is swapped).
## Attack style `bow` (0.5 s, release = attack_windup 0.15): bow arm up, bow turned upright, the other hand draws, the
## string snaps. Casts (play_cast): flare_arrow (bow raised high, 62 deg up, long draw), snare_line (quick 32 deg shot,
## the free hand lashes forward), trailblaze (straight up, the lantern blazes, the free arm rallies); unknown ids play
## flare_arrow. The lantern always hangs plumb (it counters the Root / Chest pitch and roll) and swings with the walk.
## Idle / walk / hit / death (`fall`) / level-up / revive come from the kit (CharacterModel).
## Champion classes (task 11.V2, skills-rework.md 5): the Bow is tagged as the archetype weapon (hidden by the kit once a
## class is taken); hat, split coat and the LANTERN POLE stay. Own grips (the kit pieces in her fists): spear turned
## 10 deg outward, quiver tilted to the right shoulder (clear of the pole), sword forward 20 deg down, greatsword resting
## against the right shoulder, staff 11 deg outward (its crystal clear of the hat brim). With a class the three
## archetype casts change: Signal Flare = the free (left) hand reaches up to the lantern, pulls a burning flare (sparks
## off the lantern) and hurls it overhand; Snare Line = a rope coil flung underarm by the left hand; Trailblaze = the
## class weapon raised to the sky while the lantern blazes. The flare / coil is ONE keep_separate node `HandProp` on
## ArmL (hidden unless a pose shows it, mesh swapped). get_beam_origin(): bow arrow / staff crystal / left hand.
## Budget: 22 authored meshes (blob included), 15 draw instances (7 merged pivots + Lantern, Bow, Variant, HandProp,
## blob, 3 particle systems), 0 lights, 5 own materials (materials/) + the kit's fire_skin (face, canvas, feather) and
## blob; ~5.9k vertices (a hero-grade count; at most 6 champions per match). Kit weapon pieces are shared (not counted).

const WF_DIR := "res://art/units/champions/wayfinder/materials/"
## B8 material merge (in-game grade 2026-09-30): every painted / glow part folds into ONE palette material
## (ChampionPalette, art/units/champions/champion_palette.gd); the motes share one draw material.
const PAL_KEY := "wayfinder"
const GLOW := Color(1.0, 0.8, 0.4)
const SHOULDER_R := Vector3(0.34, 1.42, 0.0)
const SHOULDER_L := Vector3(-0.34, 1.42, 0.0)
const GRIP_R := Vector3(0.43, 0.93, 0.07)          # right fist = the bow grip (model space)
const HAND_L := Vector3(-0.43, 0.93, 0.07)
const HANG := Vector3(-0.35, 2.49, -0.49)          # lantern hook (tip of the crook, bent outward)
const POLE_B := Vector3(-0.12, 0.90, -0.47)
const POLE_T := Vector3(-0.15, 2.50, -0.50)
const BOW_REST := Vector3(35.0, 0.0, -4.0)         # deg: the bow held diagonally at the side, top forward
const NOCK := 0.46                                  # drawn string: nock point behind the grip (bow space, -Z)
const SHOT_LEN := 0.5
const LANTERN_BASE := 2.0                           # glow_boost on the lantern core (1.5 x 2 = 3.0 halo)
const CAST_IDS: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze"]
# ---- champion class weapons (11.V2): grips in model space (rest pose)
const QUIVER_AT := Vector3(0.15, 1.20, -0.60)       # behind the pack, right of the lantern pole
const QUIVER_ROT := Vector3(-14.0, 0.0, -16.0)      # top back and toward the right shoulder
## Greatsword: up from the fist, a little back past the right pauldron and well out to the side. A blade leaning back
## points straight at the 55-deg game camera when she walks away (a nub at 40 m); this lean keeps ~55 % of its length
## visible from behind and ~80 % from the front.
const GREATSWORD_DIR := Vector3(0.40, 0.86, -0.26)
const HAND_PROP_ROT := Vector3(180.0, 0.0, 0.0)     # the prop's +Y (flare head) hangs down at rest, up when cocked
## Trailblaze with a class weapon: ArmR pitch and roll (deg) that stand the weapon upright, and the lift of the arm (m).
const CLASS_UP: Dictionary = {
	&"spear": [-60.0, Vector3(0.0, 0.16, 0.08), 6.0],
	&"sword_shield": [-120.0, Vector3(0.0, 0.04, 0.04), 6.0],
	&"two_hand": [15.0, Vector3(0.0, 0.20, 0.12), 25.0],
	&"wizard": [-7.0, Vector3(0.0, 0.30, 0.08), 6.0],
}
# Signal Flare with a class weapon (1.0 s): reach up to the lantern (0.24), grab (0.28), cock, hurl (release 0.50).
const FLR_T: Array[float] = [0.0, 0.24, 0.34, 0.44, 0.52, 0.64, 1.00]
const FLR_LX: Array[float] = [0.0, -202.0, -210.0, -222.0, -128.0, -98.0, 0.0]
const FLR_LZ: Array[float] = [0.0, -6.0, -6.0, -4.0, -2.0, 0.0, 0.0]
const FLR_LPY: Array[float] = [0.0, 0.18, 0.14, 0.08, 0.04, 0.0, 0.0]
const FLR_LPZ: Array[float] = [0.0, -0.18, -0.14, -0.08, 0.04, 0.04, 0.0]
const FLR_CX: Array[float] = [0.0, -8.0, -6.0, -10.0, 8.0, 6.0, 0.0]
const FLR_CY: Array[float] = [0.0, -10.0, -8.0, -20.0, 18.0, 12.0, 0.0]
const FLR_HX: Array[float] = [0.0, -20.0, -12.0, -10.0, -16.0, -8.0, 0.0]
const FLR_GL: Array[float] = [0.0, 0.0, -2.0, 4.0, -20.0, -16.0, 0.0]
const FLR_GR: Array[float] = [0.0, 0.0, 2.0, -4.0, 14.0, 10.0, 0.0]
const FLR_BY: Array[float] = [0.0, 0.03, 0.02, -0.02, -0.04, -0.03, 0.0]
const FLR_BZ: Array[float] = [0.0, 0.0, -0.02, -0.04, 0.08, 0.06, 0.0]
const FLR_RX: Array[float] = [0.0, 4.0, 4.0, 6.0, -8.0, -6.0, 0.0]
const FLR_GRAB := 0.28
const FLR_REL := 0.50
# Snare Line with a class weapon (0.72 s): back-swing, then an underarm fling of the rope coil (release 0.26).
const SNR_T: Array[float] = [0.0, 0.14, 0.24, 0.30, 0.42, 0.72]
const SNR_LX: Array[float] = [0.0, 35.0, -40.0, -95.0, -85.0, 0.0]
const SNR_LZ: Array[float] = [0.0, -10.0, -6.0, 0.0, 0.0, 0.0]
const SNR_CX: Array[float] = [0.0, -4.0, 4.0, 10.0, 8.0, 0.0]
const SNR_CY: Array[float] = [0.0, -18.0, 0.0, 16.0, 14.0, 0.0]
const SNR_BY: Array[float] = [0.0, -0.04, -0.05, -0.03, -0.02, 0.0]
const SNR_BZ: Array[float] = [0.0, -0.03, 0.02, 0.07, 0.06, 0.0]
const SNR_GL: Array[float] = [0.0, 4.0, -10.0, -22.0, -18.0, 0.0]
const SNR_GR: Array[float] = [0.0, -4.0, 6.0, 14.0, 12.0, 0.0]
const SNR_RX: Array[float] = [0.0, 4.0, 0.0, -6.0, -4.0, 0.0]
const SNR_REL := 0.26
enum { PROP_NONE, PROP_FLARE, PROP_SNARE }

## 0 = Tamsin (braid), 1 = Tobin (beard + feather). Change it with set_variant().
@export_range(0, 1) var variant: int = 0

static var _wf_mats: Dictionary = {}
static var _wf_meshes: Dictionary = {}

## Painted face (FaceKit via ChampionFaces, faces pass 2026-09-28).
var _face: FaceRig
var _authored: int = 0              # MeshInstance3D parts authored this build (budget check; blob added in _after_ready)
var _bow: MeshInstance3D
var _lantern: MeshInstance3D
var _variant_node: MeshInstance3D
var _spark: GPUParticles3D          # pre-built one-shot: sparks off the arrow tip when a cast looses
var _motes: GPUParticles3D

# per-frame targets written by the poses (reset in _extra_process)
var _bow_k: float = 0.0             # 0 rest grip -> 1 bow upright, perpendicular to the arm
var _bow_draw: float = 0.0          # > 0.5: drawn string + nocked arrow
var _hold: float = 0.0              # extra lantern boost held by a pose (trailblaze)
# state
var _flare: float = 0.0             # decaying lantern flare (releases, level-up)
var _kick: float = 0.0              # decaying lantern swing kick (deg)
var _fired: bool = false
var _bow_rot_w: Vector3 = Vector3(999, 0, 0)
var _drawn_w: int = -1
var _lantern_w: float = -1.0
var _bow_glow_w: float = -1.0
var _swing_w: Vector3 = Vector3(999, 0, 0)
# class weapons (11.V2)
var _hand_prop: MeshInstance3D      # flare / rope coil in the left fist (keep_separate, shown by the class poses)
var _prop_req: int = PROP_NONE      # this frame's request from a pose (reset in _extra_process)
var _prop_w: int = -1
var _prop_glow_w: float = -1.0
var _grabbed: bool = false          # Signal Flare: the flare was pulled from the lantern this cast


static func _m(name: StringName) -> Material:
	if not _wf_mats.has(name):
		_wf_mats[name] = load(WF_DIR + String(name) + ".tres")
	return _wf_mats[name]


static func _skin() -> Material:
	return palette(&"fire_skin")


# ================================================================ hooks

## Variant piece: 0 = Tamsin (braid), 1 = Tobin (beard + hat feather). Safe before _ready.
func set_variant(v: int) -> void:
	variant = clampi(v, 0, 1)
	if _variant_node:
		_variant_node.mesh = ChampionPalette.fold_mesh(PAL_KEY, _variant_mesh(variant))
	ChampionFaces.switch(_face, "wayfinder", _face_spec, variant)


## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## Face styles (FaceKit, faces pass 2026-09-28; the old dark eye bar under the brim is gone and the coat collar no
## longer hides the mouth). Weathered scout skin (fire_skin), green eyes, auburn brows (the leather colour). Tamsin
## (A): a bright open face, a swept auburn fringe under the brim, freckle-warm blush (her back hair and braid are the
## Variant mesh). Tobin (B): heavier brows, the mouth on the top of his bushy beard under the moustache (Variant).
static func _face_spec(v: int) -> Dictionary:
	var c := Vector3(0, 1.60, 0.03)
	var auburn := Color(0.46, 0.24, 0.11)
	var spec := {"center": c, "radius": 0.21, "head_mesh": sphere(0.21), "head_scale": Vector3(0.95, 1.05, 0.95),
		"preset": &"bright" if v == 0 else &"stern", "skin": Color(0.92, 0.72, 0.55), "hair": auburn,
		"hair_tip": Color(0.66, 0.36, 0.16), "eyes": Color(0.30, 0.50, 0.24), "ears": &"none",
		"palette": {"lip": Color(0.80, 0.44, 0.38)}}
	if v == 0:
		spec["hair_fn"] = func(acc: Dictionary) -> void:
			ChampionFaces.frame_locks(acc, c, 0.21, auburn, Color(0.66, 0.36, 0.16), 1.0, false, 0.95)
	else:
		spec["mouth_canvas"] = FaceKit.canvas(Vector3(0, 1.462, 0.125), 0.14, sphere(0.14), Vector3(1.2, 1.1, 0.85),
			Vector3.INF, Basis.from_euler(Vector3(-12.0 * DEG, 0, 0)), 0.002)
		spec["mouth"] = {"c": Vector2(0.0, -0.004), "hw": 0.040, "lip": 0.0038}
		spec["palette"]["lip_line"] = Color(0.14, 0.05, 0.03)
		spec["palette"]["lip"] = Color(0.86, 0.50, 0.44)
	return spec


## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Where her shots and thrown skills leave her (world space): the Wizard staff's crystal; with another class weapon
## the left hand (flare, javelin, shield throw); before a class the arrow head on the bow.
func get_beam_origin() -> Vector3:
	if not is_inside_tree() or not _ready_done:
		return position + Vector3.UP * body_height * 0.75
	var cls := weapon_class()
	if cls == &"wizard":
		var tip: Variant = get_weapon_tip()
		if tip is Vector3:
			return tip
	if cls != &"" and _piv[P_ARM_L]:
		return _piv[P_ARM_L].global_transform * (HAND_L - SHOULDER_L)
	if _bow:
		return _bow.global_transform * Vector3(0.03, 0.0, 0.18)
	return global_position + Vector3.UP * body_height * 0.75


# ================================================================ champion class weapons (11.V2)

## Her fists: the bow grip and the left glove centres (rest pose, model space).
func _weapon_slot(slot: StringName) -> Transform3D:
	match slot:
		&"hand_r":
			return Transform3D(Basis.IDENTITY, GRIP_R)
		&"hand_l":
			return Transform3D(Basis.IDENTITY, HAND_L)
	return super._weapon_slot(slot)


func _weapon_grip(piece: StringName) -> Transform3D:
	match piece:
		&"quiver":
			return Transform3D(Basis.from_euler(QUIVER_ROT * DEG), QUIVER_AT)
		&"spear":
			# the generic mid-shaft hold (tip forward, 30 deg up), turned 10 deg outward: clear of the hat brim
			return Transform3D(Basis(Vector3.UP, 10.0 * DEG) * Basis(Vector3.RIGHT, 60.0 * DEG), GRIP_R + Vector3(0.02, 0, 0))
		&"sword":
			# point forward and 20 deg down, 14 deg outward (clear of the boots and the coat skirt)
			return Transform3D(Basis(Vector3.UP, 14.0 * DEG) * Basis(Vector3.RIGHT, 110.0 * DEG), GRIP_R)
		&"greatsword":
			var d := GREATSWORD_DIR.normalized()
			var x := (Vector3.RIGHT - d * d.dot(Vector3.RIGHT)).normalized()
			return Transform3D(Basis(x, d, x.cross(d)), GRIP_R)
		&"staff":
			# upright, 7 deg forward and 11 deg outward: the crystal stands beside the hat, away from the lantern
			return Transform3D(Basis.from_euler(Vector3(7.0, 0.0, -11.0) * DEG), GRIP_R)
	return super._weapon_grip(piece)


## The release sparks follow the fire: on the bow (arrow tip) before a class, under the lantern with a class weapon
## (Signal Flare pulled from it, Trailblaze).
func _on_weapon_class(class_id: StringName) -> void:
	ChampionPalette.claim_crystal_glow(self, class_id)   # the staff crystal glow (palette material, B8 merge)
	_prop_req = PROP_NONE
	_prop_w = -1
	_grabbed = false
	if _spark == null:
		return
	var holder: Node3D = _bow if class_id == &"" else _lantern
	if holder and _spark.get_parent() != holder:
		_spark.reparent(holder, false)
	_spark.position = Vector3(0, 0.0, 0.18) if class_id == &"" else Vector3(0, -0.24, 0)


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		keep: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	var f := ChampionPalette.fold(PAL_KEY, mesh, mat)
	return add_part(pivot, f[0], f[1], at, rot_deg, Vector3.ONE, keep, part_name)


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	_authored = 0
	# ---- Legs: shaped dark trousers (G-C), tall leather boots with turned-down cuffs
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		_part(leg, _leg_mesh(sx), null, Vector3.ZERO)
		_part(leg, _boot_mesh(), null, Vector3(0.14 * sx, 0.0, 0.0))
	# ---- Hips: the long split coat skirt (leather hem + front trims), belt, team sash + tails, hip quiver
	_part(hips, _skirt_mesh(), null, Vector3.ZERO)
	_part(hips, _belt_mesh(), null, Vector3.ZERO)
	_part(hips, _sash_mesh(), _m(&"wayfinder_pennon"), Vector3.ZERO)
	# ---- Chest: coat torso, collar, leather vest + baldric; pack, bedroll, map tube; the lantern pole; pennant
	_part(chest, _torso_mesh(), null, Vector3.ZERO)
	_part(chest, _pack_mesh(), null, Vector3.ZERO)
	_part(chest, _pole_mesh(), null, Vector3.ZERO)
	var pen_top := Vector3(0.012, 2.275, -0.495)
	_part(chest, cape(0.27, 0.50), _m(&"wayfinder_pennon"), pen_top - Vector3(0, 0.25, 0))
	# G-C: the team half-cloak over the left shoulder (heraldic glyph of the banner shader)
	_part(chest, _mantle_mesh(), null, Vector3.ZERO)
	_lantern = _part(chest, _lantern_mesh(), null, HANG, Vector3.ZERO, true, "Lantern")
	_lantern.set_meta(&"own_glow", true)
	_motes = make_motes(GLOW, 5, 1.5, 0.05, 0.28, 0.05)
	_motes.name = "LanternMotes"
	ChampionPalette.share_motes(PAL_KEY, _motes)
	_motes.position = Vector3(0, -0.20, 0)
	_lantern.add_child(_motes)
	var embers := make_motes(GLOW, 12, 0.9, 0.12, 1.1, 0.06, false, true)
	embers.name = "DeathEmbers"
	ChampionPalette.share_motes(PAL_KEY, embers)
	embers.set_meta(&"death_fx", true)
	embers.position = Vector3(0, -0.22, 0)
	_lantern.add_child(embers)
	# ---- Head: face, then the hat (brim, pinched crown, band); the variant piece; the FaceKit face (eyes, brows, lips)
	_part(head, _face_mesh(), _skin(), Vector3.ZERO)
	_part(head, _hat_mesh(), null, Vector3.ZERO)
	_variant_node = _part(head, _variant_mesh(variant), null, Vector3.ZERO, Vector3.ZERO, true, "Variant")
	_face = ChampionFaces.attach(self, head, "wayfinder", _face_spec, variant)
	# ---- Arms: coat sleeves, leather pauldrons / cuffs / gloves; the bow in the right fist
	for side: float in [-1.0, 1.0]:
		var arm: Node3D = arm_r if side > 0.0 else arm_l
		_part(arm, _sleeve_mesh(side), null, Vector3.ZERO)   # G-C: shaped sleeve (bicep, bent elbow, forearm)
		_part(arm, _arm_leather_mesh(side), _m(&"wayfinder_leather"), Vector3.ZERO)
	_bow = _part(arm_r, _bow_mesh(false), null, GRIP_R, BOW_REST, true, "Bow")
	_bow.set_meta(&"own_glow", true)
	mark_archetype_weapon(_bow)      # 11.V2: the kit hides it once a class weapon is taken
	# the class poses' hand prop (Signal Flare / Snare Line with a class weapon): hidden until a pose asks for it
	_hand_prop = _part(arm_l, _flare_mesh(), null, HAND_L, HAND_PROP_ROT, true, "HandProp")
	_hand_prop.set_meta(&"own_glow", true)
	_hand_prop.visible = false
	_spark = make_motes(GLOW, 10, 0.55, 0.05, 1.8, 0.07, false, true)
	_spark.name = "ReleaseSparks"
	ChampionPalette.share_motes(PAL_KEY, _spark)
	_spark.position = Vector3(0, 0.0, 0.18)
	_bow.add_child(_spark)
	ensure_shadow_blob(0.5)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	if _variant_node:
		_variant_node.mesh = ChampionPalette.fold_mesh(PAL_KEY, _variant_mesh(variant))
	_lantern_w = -1.0
	_extra_process(0.0)


## Euler (deg) that turns a primitive's +Y axis along d.
static func _euler_down(d: Vector3) -> Vector3:
	return Basis(Quaternion(Vector3.UP, d.normalized())).get_euler() / DEG


# ================================================================ mesh building (static, cached once per game)

static func _bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## Appends primitive `m` (surface 0) transformed by xf. uv_const.x >= 0 replaces every UV (flat banner colour).
static func _put(acc: Array, m: Mesh, xf: Transform3D, uv_const: Vector2 = Vector2(-1, -1)) -> void:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb := xf.basis.inverse().transposed()
	var b0: int = (acc[0] as PackedVector3Array).size()
	for j: int in v.size():
		acc[0].append(xf * v[j])
		acc[1].append((nb * nr[j]).normalized())
		if uv_const.x >= 0.0:
			acc[2].append(uv_const)
		else:
			acc[2].append(uv[j] if j < uv.size() else Vector2.ZERO)
	if ix.is_empty():
		for j: int in v.size():
			acc[3].append(b0 + j)
	else:
		for j: int in ix.size():
			acc[3].append(b0 + ix[j])


## A (cols+1) x (rows+1) grid of points (row-major) into acc. Smooth normals from the grid (central differences;
## wrap_u = closed loop along u), each turned toward hints[k]; triangles wound so their front faces the same way
## (Godot fronts are clockwise). double: also the back side, inset along -normal, reversed.
static func _grid(acc: Array, pts: PackedVector3Array, hints: PackedVector3Array, cols: int, rows: int,
		wrap_u: bool, double: bool = false, inset: float = 0.0, uvs: PackedVector2Array = PackedVector2Array()) -> void:
	var w := cols + 1
	var norms := PackedVector3Array()
	norms.resize(pts.size())
	for j: int in rows + 1:
		for i: int in cols + 1:
			var il := i - 1
			var ir := i + 1
			if wrap_u:
				if il < 0:
					il = cols - 1
				if ir > cols:
					ir = 1
			else:
				il = maxi(il, 0)
				ir = mini(ir, cols)
			var du := pts[j * w + ir] - pts[j * w + il]
			var dv := pts[mini(j + 1, rows) * w + i] - pts[maxi(j - 1, 0) * w + i]
			var n := du.cross(dv)
			var h := hints[j * w + i]
			if n.length_squared() < 1e-12:
				n = h
			n = n.normalized()
			if n.dot(h) < 0.0:
				n = -n
			norms[j * w + i] = n
	for side: int in (2 if double else 1):
		var s: float = 1.0 if side == 0 else -1.0
		var b0: int = (acc[0] as PackedVector3Array).size()
		for k: int in pts.size():
			acc[0].append(pts[k] - norms[k] * inset if side == 1 else pts[k])
			acc[1].append(norms[k] * s)
			acc[2].append(uvs[k] if k < uvs.size() else Vector2.ZERO)
		for j: int in rows:
			for i: int in cols:
				var q0 := j * w + i
				var quads: Array = [[q0, q0 + 1, q0 + w], [q0 + 1, q0 + w + 1, q0 + w]]
				for tri: Array in quads:
					var a: int = tri[0]
					var b: int = tri[1]
					var c: int = tri[2]
					var front := -(pts[b] - pts[a]).cross(pts[c] - pts[a])
					if front.dot((norms[a] + norms[b] + norms[c]) * s) < 0.0:
						var t := b
						b = c
						c = t
					acc[3].append(b0 + a)
					acc[3].append(b0 + b)
					acc[3].append(b0 + c)


## Surface of revolution: profile (r, y) points, `seg` segments; xf places it. Normals from the profile.
static func _lathe(acc: Array, prof: PackedVector2Array, seg: int, xf: Transform3D = Transform3D.IDENTITY,
		double: bool = false, inset: float = 0.0) -> void:
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	var n := prof.size()
	for j: int in n:
		var t := prof[mini(j + 1, n - 1)] - prof[maxi(j - 1, 0)]
		var n2 := Vector2(t.y, -t.x)   # outward for a profile climbing up / curling in over the top
		for i: int in seg + 1:
			var a := TAU * float(i) / float(seg)
			pts.append(xf * Vector3(sin(a) * prof[j].x, prof[j].y, cos(a) * prof[j].x))
			hints.append(xf.basis * Vector3(sin(a) * n2.x, n2.y, cos(a) * n2.x))
	_grid(acc, pts, hints, seg, n - 1, true, double, inset)


## [cylinder from a to b] (radius ra at a, rb at b), flattened across the axis by sx / sz. Open ends unless caps
## (every caller hides its ends in a joint, knob, cap or the next segment).
static func _seg(acc: Array, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6, sx: float = 1.0,
		sz: float = 1.0, caps: bool = false) -> void:
	var d := b - a
	var l := d.length()
	var bs := Basis(Quaternion(Vector3.UP, d / l)).scaled_local(Vector3(sx, l, sz))
	_put(acc, cyl(rb, ra, 1.0, seg, caps), Transform3D(bs, (a + b) * 0.5))


## One ArrayMesh from [acc, material] pairs (empty accs skipped), cached by key.
static func _commit(key: String, surfaces: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for s: Array in surfaces:
		var acc: Array = s[0]
		if (acc[0] as PackedVector3Array).is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc[0]
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_TEX_UV] = acc[2]
		arrays[Mesh.ARRAY_INDEX] = acc[3]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, s[1])
	_wf_meshes[key] = am
	return am


static func _xf(at: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), at)


# ---------------------------------------------------------------- legs

## Tall riding boot (G-C): a rounded toe-forward foot (lathe, no more brick), a shaft swelling at the calf, the dark
## turned-down cuff and a dark sole rim.
static func _boot_mesh() -> ArrayMesh:
	if _wf_meshes.has("boot"):
		return _wf_meshes["boot"]
	var lea := _bucket()
	var dark := _bucket()
	var s := ChampionShapes.begin()
	ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.0, 0.012), Vector2(0.10, 0.012), Vector2(0.112, 0.04),
		Vector2(0.105, 0.09), Vector2(0.07, 0.135), Vector2(0.0, 0.15)]), 9, _xf(Vector3(0, 0.0, 0.07)), 1.0, 1.6)
	ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.098, 0.05), Vector2(0.11, 0.17), Vector2(0.118, 0.27),
		Vector2(0.112, 0.36)]), 9, _xf(Vector3(0, 0.0, 0.01)), 1.0, 1.06, false)
	_put_st(lea, s)
	s = ChampionShapes.begin()
	ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.112, 0.35), Vector2(0.138, 0.36), Vector2(0.142, 0.415),
		Vector2(0.118, 0.43)]), 9, _xf(Vector3(0, 0.0, 0.01)), 1.0, 1.06, false)
	ChampionShapes.band(s, 0.10, 0.024, 0.012, 9, _xf(Vector3(0, 0.012, 0.07)), 1.0, 1.6)
	_put_st(dark, s)
	return _commit("boot", [[lea, _m(&"wayfinder_leather")], [dark, _m(&"wayfinder_hat")]])


# ---------------------------------------------------------------- hips

## Coat skirt point: angle a from +Z (front) toward +X, v 0 (waist) -> 1 (hem). The back tails hang lower and flare.
static func _skirt_point(a: float, v: float, grow: float = 0.0) -> Vector3:
	var back := maxf(0.0, -cos(a))
	var r := 0.268 + 0.165 * pow(v, 1.15) + 0.085 * back * back * v * v + 0.012 * sin(9.0 * a + 1.3) * v + grow
	var hem := 0.31 - 0.08 * back * back
	return Vector3(sin(a) * r, lerpf(1.05, hem, v), cos(a) * r)


## Panel angle: the front stays open (10 deg at the waist -> 36 deg at the hem), the back splits from mid-thigh.
static func _skirt_angle(u: float, v: float, right: bool) -> float:
	var open := lerpf(10.0, 36.0, pow(v, 0.8)) * DEG
	var split := maxf(0.0, (v - 0.35) / 0.65) * 15.0 * DEG
	if right:
		return lerpf(open, PI - split, u)
	return lerpf(PI + split, TAU - open, u)


static func _skirt_panel(acc: Array, right: bool, u0: float, u1: float, v0: float, v1: float, cols: int, rows: int,
		grow: float, double: bool) -> void:
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in rows + 1:
		var v := lerpf(v0, v1, float(j) / float(rows))
		for i: int in cols + 1:
			var a := _skirt_angle(lerpf(u0, u1, float(i) / float(cols)), v, right)
			var p := _skirt_point(a, v, grow)
			pts.append(p)
			hints.append(Vector3(p.x, 0.0, p.z))
	_grid(acc, pts, hints, cols, rows, false, double, 0.014)


static func _skirt_mesh() -> ArrayMesh:
	if _wf_meshes.has("skirt"):
		return _wf_meshes["skirt"]
	var coat := _bucket()
	var trim := _bucket()
	for right: bool in [true, false]:
		_skirt_panel(coat, right, 0.0, 1.0, 0.0, 1.0, 12, 8, 0.0, true)
		_skirt_panel(trim, right, 0.0, 1.0, 0.90, 1.0, 12, 1, 0.007, false)           # hem band
		if right:
			_skirt_panel(trim, true, 0.0, 0.07, 0.0, 1.0, 1, 8, 0.006, false)        # front edge trims
		else:
			_skirt_panel(trim, false, 0.93, 1.0, 0.0, 1.0, 1, 8, 0.006, false)
	return _commit("skirt", [[coat, _m(&"wayfinder_coat")], [trim, _m(&"wayfinder_hat")]])


## Belt + buckle, and the hip quiver (left, behind) with pale fletchings.
static func _belt_mesh() -> ArrayMesh:
	if _wf_meshes.has("belt"):
		return _wf_meshes["belt"]
	var lea := _bucket()
	var dark := _bucket()
	var pale := _bucket()
	var prof := PackedVector2Array([Vector2(0.287, 0.962), Vector2(0.29, 0.995), Vector2(0.287, 1.028)])
	_lathe(lea, prof, 16)
	_put(dark, box(Vector3(0.10, 0.08, 0.035)), _xf(Vector3(0.0, 0.995, 0.29)))
	var qb := Vector3(-0.31, 0.60, -0.17)
	var qt := Vector3(-0.37, 1.02, -0.245)
	_seg(lea, qb, qt, 0.07, 0.078, 8)
	_seg(dark, qt - (qt - qb).normalized() * 0.02, qt + (qt - qb).normalized() * 0.03, 0.088, 0.088, 8, 1.0, 1.0, true)
	_put(lea, sphere(0.07, 8, 4), _xf(qb))
	var dq := (qt - qb).normalized()
	for k: int in 4:
		var off := Vector3(0.035 * cos(k * 1.7), 0.0, 0.035 * sin(k * 1.7))
		_put(pale, box(Vector3(0.045, 0.13, 0.014)),
			Transform3D(Basis(Quaternion(Vector3.UP, dq)) * Basis(Vector3.UP, k * 0.8), qt + dq * 0.09 + off))
	_seg(lea, Vector3(-0.27, 1.0, -0.10), qt + Vector3(0.02, -0.05, 0.02), 0.022, 0.022, 4)   # quiver strap
	return _commit("belt", [[lea, _m(&"wayfinder_leather")], [dark, _m(&"wayfinder_hat")], [pale, _skin()]])


## Team sash: a band round the waist + knot on the right front (flat UV: plain team colour, no wave), two tails
## hanging from the knot (real UVs: they wave, swallow-tail ends, a small gold diamond from the banner glyph).
static func _sash_mesh() -> ArrayMesh:
	if _wf_meshes.has("sash"):
		return _wf_meshes["sash"]
	var acc := _bucket()
	var flat := Vector2(0.0, 0.04)
	_put(acc, cyl(0.279, 0.281, 0.085, 16, false), _xf(Vector3(0, 1.07, 0)), flat)
	_put(acc, sphere(0.065, 8, 4), _xf(Vector3(0.13, 1.055, 0.275), Vector3(0, 25, 0), Vector3(1.3, 1.0, 0.8)), flat)
	var tails: Array = [[Vector3(0.12, 1.035, 0.305), 0.13, 0.44, 5.0], [Vector3(0.17, 1.04, 0.29), 0.11, 0.34, 17.0]]
	for t: Array in tails:
		var b := Basis.from_euler(Vector3(-15.0, 10.0, float(t[3])) * DEG)
		var h: float = t[2]
		_put(acc, cape(float(t[1]), h), Transform3D(b, (t[0] as Vector3) + b * Vector3(0, -h * 0.5, 0)))
	return _commit("sash", [[acc, _m(&"wayfinder_pennon")]])


# ---------------------------------------------------------------- chest

static func _torso_mesh() -> ArrayMesh:
	if _wf_meshes.has("torso"):
		return _wf_meshes["torso"]
	var coat := _bucket()
	var lea := _bucket()
	var vest := _bucket()
	# G-C: a shaped coat body (waist -> chest swell -> shoulders) instead of a 12-sided can
	var s := ChampionShapes.begin()
	ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.25, 1.0), Vector2(0.262, 1.10), Vector2(0.29, 1.27),
		Vector2(0.294, 1.38), Vector2(0.27, 1.47), Vector2(0.24, 1.50)]), 14, Transform3D.IDENTITY, 1.0, 0.92)
	_put_st(coat, s)
	# turned-up collar, lowered under the chin (faces pass 2026-09-28: it used to hide the mouth)
	var collar := PackedVector2Array([Vector2(0.255, 1.40), Vector2(0.24, 1.44), Vector2(0.225, 1.475), Vector2(0.232, 1.495)])
	_lathe(coat, collar, 12, Transform3D(Basis(), Vector3(0, 0, -0.012)), true, 0.02)
	# the leather vest: a bevelled panel with rounded corners
	s = ChampionShapes.begin()
	ChampionShapes.plate(s, _round_rect(0.125, 0.20, 0.04), 0.06, 0.018, _xf(Vector3(0, 1.245, 0.236), Vector3(4, 0, 0)))
	_put_st(vest, s)
	var pieces: Array = [[Vector3(0.155, 1.43, 0.245), 28.0], [Vector3(0.0, 1.265, 0.292), 0.0], [Vector3(-0.155, 1.10, 0.255), -28.0]]
	s = ChampionShapes.begin()
	for p: Array in pieces:
		ChampionShapes.plate(s, _round_rect(0.037, 0.125, 0.01), 0.035, 0.008, _xf(p[0], Vector3(0, float(p[1]), -42.0)))
	ChampionShapes.stud(s, Vector3(0.0, 1.265, 0.305), Vector3.BACK, 0.045, 0.03)
	_put_st(lea, s)
	return _commit("torso", [[coat, _m(&"wayfinder_coat")], [lea, _m(&"wayfinder_leather")], [vest, _m(&"wayfinder_hat")]])


## Back pack: a soft leather body (bevelled, rounded), dark flap and straps, pale canvas bedroll across the top, map
## tube on the right.
static func _pack_mesh() -> ArrayMesh:
	if _wf_meshes.has("pack"):
		return _wf_meshes["pack"]
	var lea := _bucket()
	var dark := _bucket()
	var pale := _bucket()
	var s := ChampionShapes.begin()
	ChampionShapes.plate(s, _round_rect(0.18, 0.19, 0.05), 0.16, 0.035, _xf(Vector3(0, 1.17, -0.355), Vector3(0, 180, 0)), true)
	_put_st(lea, s)
	s = ChampionShapes.begin()
	ChampionShapes.plate(s, _round_rect(0.1875, 0.07, 0.025), 0.175, 0.02, _xf(Vector3(0, 1.30, -0.352), Vector3(-6, 180, 0)), true)
	_put_st(dark, s)
	_put(pale, cyl(0.09, 0.09, 0.52, 10), _xf(Vector3(0.02, 1.435, -0.395), Vector3(0, 0, 90)))
	for sx: float in [-0.14, 0.16]:
		_put(dark, torus(0.086, 0.106, 10), _xf(Vector3(sx, 1.435, -0.395), Vector3(0, 0, 90)))
	var tube_c := Vector3(0.225, 1.29, -0.475)
	var tb := Basis.from_euler(Vector3(0, 0, -12) * DEG)
	_put(lea, cyl(0.055, 0.055, 0.48, 8), Transform3D(tb, tube_c))
	_put(dark, cyl(0.064, 0.064, 0.07, 8), Transform3D(tb, tube_c + tb * Vector3(0, 0.255, 0)))
	_put(dark, cyl(0.062, 0.062, 0.04, 8), Transform3D(tb, tube_c + tb * Vector3(0, -0.22, 0)))
	return _commit("pack", [[lea, _m(&"wayfinder_leather")], [dark, _m(&"wayfinder_hat")], [pale, _skin()]])


## The lantern pole: dark shaft up the back to a crook (apex 2.60 m) whose tip carries the lantern hook; leather
## wraps, iron ferrule, a crossbar holding the pennant.
static func _pole_mesh() -> ArrayMesh:
	if _wf_meshes.has("pole"):
		return _wf_meshes["pole"]
	var dark := _bucket()
	var lea := _bucket()
	_seg(dark, POLE_B, POLE_T, 0.052, 0.046, 8)
	var crook: Array[Vector3] = [POLE_T, Vector3(-0.175, 2.548, -0.50), Vector3(-0.25, 2.566, -0.497),
		Vector3(-0.325, 2.545, -0.493), Vector3(-0.35, 2.50, -0.49)]
	var radii: Array[float] = [0.04, 0.038, 0.035, 0.032, 0.03]
	for k: int in crook.size() - 1:
		_seg(dark, crook[k], crook[k + 1], radii[k], radii[k + 1], 7)
		_put(dark, sphere(radii[k + 1] + 0.004, 7, 4), _xf(crook[k + 1]))
	_put(dark, sphere(0.052, 8, 4), _xf(POLE_B))
	for y: float in [1.04, 1.37, 1.95]:
		var t := (y - POLE_B.y) / (POLE_T.y - POLE_B.y)
		_seg(lea, POLE_B.lerp(POLE_T, t) - Vector3(0, 0.035, 0), POLE_B.lerp(POLE_T, t) + Vector3(0, 0.035, 0), 0.058, 0.058, 8, 1.0, 1.0, true)
	var bar_a := POLE_B.lerp(POLE_T, (2.285 - POLE_B.y) / (POLE_T.y - POLE_B.y))
	var bar_b := Vector3(0.16, 2.285, bar_a.z)
	_seg(dark, bar_b, bar_a, 0.022, 0.022, 6)
	_put(lea, sphere(0.042, 8, 4), _xf(bar_b + Vector3(0.02, 0, 0)))
	return _commit("pole", [[dark, _m(&"wayfinder_hat")], [lea, _m(&"wayfinder_leather")]])


## Lantern in its own space (origin = the hook, hanging down): ring, cone roof, plate, glowing glass, 4 posts, base.
static func _lantern_mesh() -> ArrayMesh:
	if _wf_meshes.has("lantern"):
		return _wf_meshes["lantern"]
	var dark := _bucket()
	var lea := _bucket()
	var glow := _bucket()
	_put(dark, torus(0.022, 0.042, 10), _xf(Vector3(0, -0.025, 0), Vector3(90, 0, 0)))
	_put(dark, cyl(0.025, 0.125, 0.09, 8), _xf(Vector3(0, -0.105, 0)))
	_put(lea, cyl(0.112, 0.112, 0.025, 8), _xf(Vector3(0, -0.16, 0)))
	_put(glow, sphere(0.09, 10, 5), _xf(Vector3(0, -0.245, 0), Vector3.ZERO, Vector3(1.0, 1.25, 1.0)))
	for k: int in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		_put(dark, box(Vector3(0.018, 0.19, 0.018)), _xf(Vector3(sin(a) * 0.097, -0.245, cos(a) * 0.097)))
	_put(dark, cyl(0.112, 0.092, 0.045, 8), _xf(Vector3(0, -0.345, 0)))
	_put(lea, sphere(0.032, 6, 3), _xf(Vector3(0, -0.382, 0)))
	return _commit("lantern", [[dark, _m(&"wayfinder_hat")], [lea, _m(&"wayfinder_leather")], [glow, _m(&"wayfinder_glow")]])


# ---------------------------------------------------------------- head

static func _face_mesh() -> ArrayMesh:
	if _wf_meshes.has("face"):
		return _wf_meshes["face"]
	var acc := _bucket()
	_put(acc, cyl(0.075, 0.088, 0.16, 8), _xf(Vector3(0, 1.47, 0.0)))
	_put(acc, sphere(0.21), _xf(Vector3(0, 1.60, 0.03), Vector3.ZERO, Vector3(0.95, 1.05, 0.95)))
	_put(acc, sphere(0.048, 8, 4), _xf(Vector3(0, 1.575, 0.237)))
	_put(acc, sphere(0.05, 6, 3), _xf(Vector3(0.196, 1.595, 0.02), Vector3.ZERO, Vector3(0.6, 1.0, 1.0)))
	_put(acc, sphere(0.05, 6, 3), _xf(Vector3(-0.196, 1.595, 0.02), Vector3.ZERO, Vector3(0.6, 1.0, 1.0)))
	return _commit("face", [[acc, null]])


## Hat frame: tilted 8 deg back (the face shows a little more from the front).
static func _hat_xf() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, -8.0 * DEG), Vector3(0, 1.775, 0.02))


## Brim point: radius r at angle a, the sides curled up, front and back dipping; `y` = thickness offset.
static func _brim_point(a: float, r: float, y: float) -> Vector3:
	var f := clampf((r - 0.19) / 0.28, 0.0, 1.0)
	var s := sin(a)
	var c := cos(a)
	var lift := 0.08 * s * s * f * f - 0.035 * c * c * f - 0.02 * maxf(c, 0.0) * f
	return Vector3(s * r, y + lift, c * r * 1.04)


## Wide brim (7-point closed-ish profile), pinched crown, leather band.
static func _hat_mesh() -> ArrayMesh:
	if _wf_meshes.has("hat"):
		return _wf_meshes["hat"]
	var dark := _bucket()
	var lea := _bucket()
	var hx := _hat_xf()
	const SEG := 28   # was 32 (faces pass trim)
	var prof: Array[Vector2] = [Vector2(0.19, -0.012), Vector2(0.33, -0.012), Vector2(0.455, -0.011), Vector2(0.472, 0.0),
		Vector2(0.455, 0.012), Vector2(0.33, 0.014), Vector2(0.19, 0.014)]
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in prof.size():
		for i: int in SEG + 1:
			var a := TAU * float(i) / float(SEG)
			var p := _brim_point(a, prof[j].x, prof[j].y)
			pts.append(hx * p)
			hints.append(hx.basis * (p - _brim_point(a, 0.33, 0.001)))
	_grid(dark, pts, hints, SEG, prof.size() - 1, true)
	# crown: a lathe pinched front / back at the top with a dent down the middle
	var cprof: Array[Vector2] = [Vector2(0.207, 0.0), Vector2(0.21, 0.085), Vector2(0.198, 0.165), Vector2(0.175, 0.228),
		Vector2(0.13, 0.262), Vector2(0.065, 0.27), Vector2(0.0, 0.258)]
	pts = PackedVector3Array()
	hints = PackedVector3Array()
	const CSEG := 16   # was 20 (faces pass trim)
	for j: int in cprof.size():
		var t := cprof[mini(j + 1, cprof.size() - 1)] - cprof[maxi(j - 1, 0)]
		var n2 := Vector2(t.y, -t.x)
		for i: int in CSEG + 1:
			var a := TAU * float(i) / float(CSEG)
			var y := cprof[j].y
			y -= 0.045 * cos(a) * cos(a) * smoothstep(0.12, 0.27, y)
			y -= 0.03 * (1.0 - clampf(cprof[j].x / 0.13, 0.0, 1.0))
			var p := Vector3(sin(a) * cprof[j].x, y, cos(a) * cprof[j].x * 1.06)
			pts.append(hx * p)
			hints.append(hx.basis * Vector3(sin(a) * n2.x, n2.y, cos(a) * n2.x))
	_grid(dark, pts, hints, CSEG, cprof.size() - 1, true)
	_lathe(lea, PackedVector2Array([Vector2(0.214, 0.012), Vector2(0.214, 0.042), Vector2(0.212, 0.07)]), CSEG,
		hx * Transform3D(Basis().scaled(Vector3(1.0, 1.0, 1.06)), Vector3.ZERO))
	return _commit("hat", [[dark, _m(&"wayfinder_hat")], [lea, _m(&"wayfinder_leather")]])


## The variant piece (model space, Head pivot): 0 = back hair + braid over the left shoulder with a tie and tuft;
## 1 = back hair, sideburns, bushy beard, moustache + a pale feather in the hat band. Auburn = the leather colour.
static func _variant_mesh(v: int) -> ArrayMesh:
	var key := "variant%d" % v
	if _wf_meshes.has(key):
		return _wf_meshes[key]
	var hair := _bucket()
	var dark := _bucket()
	var pale := _bucket()
	if v == 0:
		_put(hair, sphere(0.215), _xf(Vector3(0, 1.635, -0.05), Vector3.ZERO, Vector3(1.0, 0.92, 0.95)))
		_put(hair, sphere(0.075, 8, 4), _xf(Vector3(0.175, 1.55, -0.01), Vector3.ZERO, Vector3(0.8, 1.2, 1.0)))
		var path: Array[Vector3] = [Vector3(-0.16, 1.555, -0.03), Vector3(-0.245, 1.465, 0.10), Vector3(-0.228, 1.32, 0.225),
			Vector3(-0.198, 1.17, 0.262), Vector3(-0.183, 1.05, 0.27)]
		const LOBES := 9
		var total := 0.0
		for k: int in path.size() - 1:
			total += path[k].distance_to(path[k + 1])
		for i: int in LOBES:
			var s := total * float(i) / float(LOBES - 1)
			var k := 0
			while k < path.size() - 2 and s > path[k].distance_to(path[k + 1]):
				s -= path[k].distance_to(path[k + 1])
				k += 1
			var seg_len := path[k].distance_to(path[k + 1])
			var p := path[k].lerp(path[k + 1], clampf(s / seg_len, 0.0, 1.0))
			var d := (path[k + 1] - path[k]).normalized()
			var r := lerpf(0.062, 0.042, float(i) / float(LOBES - 1))
			var side := Vector3(0.014 if i % 2 == 0 else -0.014, 0, 0)
			_put(hair, sphere(r, 7, 3), Transform3D(Basis(Quaternion(Vector3.UP, d)).scaled_local(Vector3(1.0, 1.45, 0.9)), p + side))
		var end := path[path.size() - 1]
		_put(dark, cyl(0.033, 0.033, 0.04, 8), _xf(end + Vector3(0, -0.035, 0)))
		_put(hair, cyl(0.03, 0.058, 0.10, 8), _xf(end + Vector3(0, -0.10, 0.005)))
	else:
		_put(hair, sphere(0.212), _xf(Vector3(0, 1.645, -0.05), Vector3.ZERO, Vector3(1.0, 0.86, 0.95)))
		for sx: float in [-1.0, 1.0]:
			_put(hair, sphere(0.07, 8, 4), _xf(Vector3(0.178 * sx, 1.55, 0.04), Vector3.ZERO, Vector3(0.75, 1.3, 1.0)))
		_put(hair, sphere(0.14), _xf(Vector3(0, 1.462, 0.125), Vector3(-12, 0, 0), Vector3(1.2, 1.1, 0.85)))
		_put(hair, sphere(0.05, 8, 4), _xf(Vector3(0, 1.535, 0.228), Vector3.ZERO, Vector3(2.3, 0.75, 0.9)))
		var hx := _hat_xf()
		var dir := (Basis(Vector3.UP, 25.0 * DEG) * Vector3(0, 0.62, -0.78)).normalized()
		var base := Vector3(0.20, 0.05, -0.04)
		_put(pale, sphere(0.5, 8, 3), hx * Transform3D(Basis(Quaternion(Vector3.BACK, dir)).scaled_local(Vector3(0.075, 0.02, 0.42)),
			base + dir * 0.19))
	return _commit(key, [[hair, _m(&"wayfinder_leather")], [dark, _m(&"wayfinder_hat")], [pale, _skin()]])


# ---------------------------------------------------------------- arms and bow

## Pauldron, cuff and glove of one arm (model space).
static func _arm_leather_mesh(side: float) -> ArrayMesh:
	var key := "arm%d" % int(side)
	if _wf_meshes.has(key):
		return _wf_meshes[key]
	var acc := _bucket()
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var hand := GRIP_R if side > 0.0 else HAND_L
	_put(acc, sphere(0.14), _xf(sh + Vector3(0.02 * side, 0.045, 0.0), Vector3(0, 0, -14.0 * side), Vector3(1.12, 0.78, 1.15)))
	var d := (hand - sh).normalized()
	var wrist := sh.lerp(hand, 0.80)
	_put(acc, cyl(0.106, 0.096, 0.10, 8), Transform3D(Basis(Quaternion(Vector3.DOWN, d)), wrist))
	_put(acc, sphere(0.10), _xf(hand))
	return _commit(key, [[acc, null]])


## Bow in grip space (origin = the fist, limbs along Y, the back toward +Z, the string toward -Z). drawn: the limbs
## flex, the string makes a V to the nock NOCK behind the grip and a flare arrow (glowing head) lies on the bow.
static func _bow_mesh(drawn: bool) -> ArrayMesh:
	var key := "bow%d" % int(drawn)
	if _wf_meshes.has(key):
		return _wf_meshes[key]
	var wood := _bucket()
	var dark := _bucket()
	var pale := _bucket()
	var glow := _bucket()
	var flex := 1.35 if drawn else 1.0
	var limb: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.12, -0.02), Vector2(0.26, -0.065), Vector2(0.38, -0.12),
		Vector2(0.48, -0.17), Vector2(0.545, -0.185), Vector2(0.585, -0.155)]
	for sy: float in [1.0, -1.0]:
		for k: int in limb.size() - 1:
			var a := Vector3(0, limb[k].x * sy, limb[k].y * (flex if k > 0 else 1.0))
			var b := Vector3(0, limb[k + 1].x * sy, limb[k + 1].y * flex)
			if sy < 0.0:
				var t := a
				a = b
				b = t
			var ra := lerpf(0.036, 0.017, float(k) / 6.0)
			var rb := lerpf(0.036, 0.017, float(k + 1) / 6.0)
			_seg(wood, a, b, rb if sy < 0.0 else ra, ra if sy < 0.0 else rb, 6, 1.7, 1.0)
	_put(dark, cyl(0.044, 0.044, 0.17, 8), _xf(Vector3.ZERO))
	var tip_u := Vector3(0, 0.585, -0.155 * flex)
	var tip_d := Vector3(0, -0.585, -0.155 * flex)
	_put(dark, sphere(0.028, 6, 3), _xf(tip_u))
	_put(dark, sphere(0.028, 6, 3), _xf(tip_d))
	if drawn:
		var nock := Vector3(0, 0, -NOCK)
		_seg(pale, tip_d, nock, 0.009, 0.009, 4)
		_seg(pale, nock, tip_u, 0.009, 0.009, 4)
		_seg(dark, Vector3(0.03, 0, -NOCK + 0.01), Vector3(0.03, 0, 0.13), 0.013, 0.013, 5)
		_put(glow, cyl(0.0, 0.036, 0.10, 6), _xf(Vector3(0.03, 0, 0.18), Vector3(90, 0, 0)))
		for k: int in 3:
			_put(pale, box(Vector3(0.006, 0.04, 0.10)), _xf(Vector3(0.03, 0, -NOCK + 0.09), Vector3(0, 0, 120.0 * k)) *
				Transform3D(Basis(), Vector3(0, 0.022, 0)))
	else:
		_seg(pale, tip_d, tip_u, 0.009, 0.009, 4)
	return _commit(key, [[wood, _m(&"wayfinder_leather")], [dark, _m(&"wayfinder_hat")], [pale, _skin()],
		[glow, _m(&"wayfinder_glow")]])


## Signal flare in fist space (origin = the fist, the burning head toward +Y): a dark stick with a leather wrap, an
## iron collar and a big glowing head with a flame tip (chunky: it must read in the throw at 40 m).
static func _flare_mesh() -> ArrayMesh:
	if _wf_meshes.has("flare"):
		return _wf_meshes["flare"]
	var dark := _bucket()
	var lea := _bucket()
	var glow := _bucket()
	_seg(dark, Vector3(0, -0.10, 0), Vector3(0, 0.20, 0), 0.028, 0.032, 6, 1.0, 1.0, true)
	_seg(lea, Vector3(0, -0.05, 0), Vector3(0, 0.06, 0), 0.038, 0.038, 6, 1.0, 1.0, true)
	_put(dark, cyl(0.05, 0.042, 0.04, 8), _xf(Vector3(0, 0.21, 0)))
	_put(glow, sphere(0.07, 8, 4), _xf(Vector3(0, 0.28, 0), Vector3.ZERO, Vector3(1.0, 1.3, 1.0)))
	_put(glow, cyl(0.0, 0.05, 0.14, 6), _xf(Vector3(0, 0.39, 0)))
	return _commit("flare", [[dark, _m(&"wayfinder_hat")], [lea, _m(&"wayfinder_leather")], [glow, _m(&"wayfinder_glow")]])


## Snare line coil in fist space: three loops of leather rope hanging from the fist, a dark weighted end.
static func _snare_mesh() -> ArrayMesh:
	if _wf_meshes.has("snare"):
		return _wf_meshes["snare"]
	var lea := _bucket()
	var dark := _bucket()
	for k: int in 3:
		var r := 0.12 - 0.012 * float(k)
		_put(lea, torus(r - 0.022, r, 12), _xf(Vector3(0.012 * float(k) - 0.012, 0.13 - 0.01 * float(k), 0.0),
			Vector3(0, 8.0 * float(k - 1), 90.0)))
	_put(dark, sphere(0.045, 8, 4), _xf(Vector3(0, -0.02, 0)))
	_seg(lea, Vector3(0.0, 0.25, 0.0), Vector3(0.05, 0.40, 0.02), 0.014, 0.012, 5)
	_put(dark, sphere(0.04, 7, 3), _xf(Vector3(0.05, 0.42, 0.02)))
	return _commit("snare", [[lea, _m(&"wayfinder_leather")], [dark, _m(&"wayfinder_hat")]])


# ================================================================ animation

## Smooth keyframes (smoothstep between keys): times ts (s), values vs.
static func _wf_kf(t: float, ts: Array[float], vs: Array[float]) -> float:
	var n := ts.size()
	if t <= ts[0]:
		return vs[0]
	for i: int in range(1, n):
		if t < ts[i]:
			var f := (t - ts[i - 1]) / maxf(ts[i] - ts[i - 1], 0.0001)
			return lerpf(vs[i - 1], vs[i], f * f * (3.0 - 2.0 * f))
	return vs[n - 1]

## Aim the bow: k = weight of the raise (0-1), elev = degrees above the horizon, draw = string pulled (0-1),
## kl = weight of the drawing (left) arm (casts can hand it to another gesture).
func _aim(k: float, elev: float, draw: float, kl: float) -> void:
	rot(P_ARM_R, Vector3(-(88.0 + elev) * DEG * k, 12.0 * DEG * k, 6.0 * DEG * k))
	pos(P_ARM_R, Vector3(0.0, 0.0, 0.08 * k))
	rot(P_CHEST, Vector3(-elev / 5.0 * DEG * k, -24.0 * DEG * k, 0))
	rot(P_HEAD, Vector3(-elev * 0.15 * DEG * k, 8.0 * DEG * k, 0))
	rot(P_ARM_L, Vector3(-(84.0 + elev * 0.95) * DEG * kl, 52.0 * DEG * kl, 0))
	pos(P_ARM_L, Vector3(0.08 * kl, 0.02 * kl, (0.12 - 0.07 * draw) * kl))
	rot(P_LEG_R, Vector3(-9.0 * DEG * k, 0, 0))
	rot(P_LEG_L, Vector3(7.0 * DEG * k, 0, 0))
	_bow_k = maxf(_bow_k, k)
	_bow_draw = maxf(_bow_draw, draw)


## Attack `bow`: raise and draw (0 - windup), loose at the windup (the string snaps, a small recoil), hold, lower.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"bow":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.15
	var k := _k3(t, 0.0, w * 0.8, w + 0.12, SHOT_LEN, 1.0, 1.0)
	var d := _k3(t, 0.0, w, w, w + 0.03, 1.0, 1.0)
	_aim(k, 6.0, d, k)
	pos(P_ROOT, Vector3(0, 0, _k3(t, w, w + 0.04, w + 0.08, SHOT_LEN, -0.05, -0.02)))
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < SHOT_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	if weapon_class() != &"":
		return _pose_cast_class(spell, t)
	match spell:
		&"snare_line":
			# A quick shot 32 deg up; the free hand lashes forward after the loose (the line whips out).
			var rel := 0.26
			var k := _k3(t, 0.0, 0.16, rel + 0.10, 0.72, 1.0, 1.0)
			var d := _k3(t, 0.02, rel, rel, rel + 0.03, 1.0, 1.0)
			var f := _k3(t, rel, rel + 0.07, rel + 0.16, 0.72, 1.0, 1.0)
			_aim(k, 32.0, d, k * (1.0 - f))
			rot(P_ARM_L, Vector3(-70.0 * DEG * f, 12.0 * DEG * f, 0))
			rot(P_CHEST, Vector3(8.0 * DEG * f, 14.0 * DEG * f, 0))
			pos(P_ROOT, Vector3(0, -0.03 * k, 0.06 * f))
			_release_at(t, rel, 1.4)
			return 0.72
		&"trailblaze":
			# Straight up; then the lantern blazes and the free arm sweeps up and out (a rally), a small hop.
			var rel := 0.34
			var k := _k3(t, 0.0, 0.26, rel + 0.10, 0.80, 1.0, 1.0)
			var d := _k3(t, 0.06, rel, rel, rel + 0.03, 1.0, 1.0)
			var r := _k3(t, rel, rel + 0.16, 0.85, 1.10, 1.0, 1.0)
			_aim(k, 84.0, d, k * (1.0 - r))
			rot(P_ARM_L, Vector3(-30.0 * DEG * r, 0, -100.0 * DEG * r))
			rot(P_HEAD, Vector3(-10.0 * DEG * r, 0, 0))
			pos(P_ROOT, Vector3(0, 0.07 * _k3(t, rel, rel + 0.10, rel + 0.16, rel + 0.34, 1.0, 1.0) - 0.04 * k, 0))
			_hold = maxf(_hold, 2.2 * _k3(t, rel - 0.04, rel + 0.10, 0.85, 1.10, 1.0, 1.0))
			_release_at(t, rel, 1.0)
			return 1.10
		_:
			# flare_arrow (and unknown ids): bow raised high, 62 deg up, a long draw, knees bent, then the loose.
			var rel := 0.42
			var k := _k3(t, 0.0, 0.28, rel + 0.14, 0.95, 1.0, 1.0)
			var d := _k3(t, 0.10, rel, rel, rel + 0.03, 1.0, 1.0)
			_aim(k, 62.0, d, k)
			pos(P_ROOT, Vector3(0, -0.045 * k, 0))
			rot(P_LEG_L, Vector3(6.0 * DEG * k, 0, 0))
			_hold = maxf(_hold, 0.8 * d)
			_release_at(t, rel, 2.4)
			return 0.95


## The three archetype casts with a class weapon in the right hand (the bow is gone; the left hand does the work).
func _pose_cast_class(spell: StringName, t: float) -> float:
	match spell:
		&"snare_line":
			# Back-swing, then the rope coil flung underarm from the left hand (0.26); the weapon arm counters.
			rot(P_ARM_L, Vector3(_wf_kf(t, SNR_T, SNR_LX) * DEG, 0, _wf_kf(t, SNR_T, SNR_LZ) * DEG))
			rot(P_ARM_R, Vector3(_wf_kf(t, SNR_T, SNR_RX) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_wf_kf(t, SNR_T, SNR_CX) * DEG, _wf_kf(t, SNR_T, SNR_CY) * DEG, 0))
			pos(P_ROOT, Vector3(0, _wf_kf(t, SNR_T, SNR_BY), _wf_kf(t, SNR_T, SNR_BZ)))
			rot(P_LEG_L, Vector3(_wf_kf(t, SNR_T, SNR_GL) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_wf_kf(t, SNR_T, SNR_GR) * DEG, 0, 0))
			if t < SNR_REL:
				_prop_req = PROP_SNARE
			elif not _fired:
				_fired = true
				_flare = maxf(_flare, 0.8)
				_kick = 7.0
			return 0.72
		&"trailblaze":
			# The class weapon raised to the sky (stood upright, the arm lifted), the lantern blazes, the free arm
			# sweeps up and out (a rally), a small hop.
			var rel := 0.34
			var k := _k3(t, 0.0, 0.26, 0.85, 1.10, 1.0, 1.0)
			var r := _k3(t, rel, rel + 0.16, 0.85, 1.10, 1.0, 1.0)
			var up: Array = CLASS_UP.get(weapon_class(), [-90.0, Vector3.ZERO, 6.0])
			rot(P_ARM_R, Vector3(float(up[0]) * DEG * k, 0, float(up[2]) * DEG * k))
			pos(P_ARM_R, (up[1] as Vector3) * k)
			rot(P_ARM_L, Vector3(-30.0 * DEG * r, 0, -100.0 * DEG * r))
			rot(P_CHEST, Vector3(-6.0 * DEG * k, -8.0 * DEG * k, 0))
			rot(P_HEAD, Vector3(-14.0 * DEG * maxf(k * 0.5, r), 0, 0))
			pos(P_ROOT, Vector3(0, 0.07 * _k3(t, rel, rel + 0.10, rel + 0.16, rel + 0.34, 1.0, 1.0) - 0.03 * k, 0))
			rot(P_LEG_L, Vector3(-6.0 * DEG * k, 0, 0))
			_hold = maxf(_hold, 2.2 * _k3(t, rel - 0.04, rel + 0.10, 0.85, 1.10, 1.0, 1.0))
			weapon_flare(k)
			_release_at(t, rel, 1.0)
			return 1.10
		_:
			# Signal Flare (and unknown ids): the left hand reaches up to the lantern, pulls a burning flare out
			# (0.28: sparks off the lantern), cocks it behind the head and hurls it overhand, high (0.50).
			rot(P_ARM_L, Vector3(_wf_kf(t, FLR_T, FLR_LX) * DEG, 0, _wf_kf(t, FLR_T, FLR_LZ) * DEG))
			pos(P_ARM_L, Vector3(0, _wf_kf(t, FLR_T, FLR_LPY), _wf_kf(t, FLR_T, FLR_LPZ)))
			rot(P_ARM_R, Vector3(_wf_kf(t, FLR_T, FLR_RX) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_wf_kf(t, FLR_T, FLR_CX) * DEG, _wf_kf(t, FLR_T, FLR_CY) * DEG, 0))
			rot(P_HEAD, Vector3(_wf_kf(t, FLR_T, FLR_HX) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, _wf_kf(t, FLR_T, FLR_BY), _wf_kf(t, FLR_T, FLR_BZ)))
			rot(P_LEG_L, Vector3(_wf_kf(t, FLR_T, FLR_GL) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_wf_kf(t, FLR_T, FLR_GR) * DEG, 0, 0))
			if t >= FLR_GRAB and t < FLR_REL:
				_prop_req = PROP_FLARE
			if not _grabbed and t >= FLR_GRAB:
				_grabbed = true
				_flare = maxf(_flare, 2.4)
				_kick = maxf(_kick, 6.0)
				if _spark and _tier < 2:
					_spark.restart()
			if not _fired and t >= FLR_REL:
				_fired = true
				_flare = maxf(_flare, 0.8)
				_kick = 10.0
			_hold = maxf(_hold, 0.8 * _k3(t, 0.10, FLR_GRAB, FLR_GRAB, FLR_REL, 1.0, 1.0))
			return 1.0


func _release_at(t: float, rel: float, flare: float) -> void:
	if not _fired and t >= rel:
		_fired = true
		_flare = maxf(_flare, flare)
		_kick = 9.0
		if _spark and _tier < 2:
			_spark.restart()


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"cast_start":
			_fired = false
			_grabbed = false
		&"release":
			# the arrow's glint is the bow's; a class weapon's strike only swings the lantern
			if weapon_class() == &"":
				_flare = maxf(_flare, 0.6)
			_kick = maxf(_kick, 5.0)
		&"level_up":
			_flare = maxf(_flare, 2.5)
			_kick = maxf(_kick, 8.0)
		&"death_glow_off":
			_kick = maxf(_kick, 14.0)


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	# Bow: upright and perpendicular to the arm while aiming; drawn string + arrow while drawn.
	var k := clampf(_bow_k, 0.0, 1.0)
	var drawn: int = 1 if (_bow_draw > 0.5 and not _dead) else 0
	_bow_k = 0.0
	_bow_draw = 0.0
	if _bow:
		var r := Vector3(lerpf(BOW_REST.x, 90.0, k), lerpf(BOW_REST.y, 0.0, k), lerpf(BOW_REST.z, 0.0, k)) * DEG
		if r != _bow_rot_w:
			_bow_rot_w = r
			_bow.rotation = r
		if drawn != _drawn_w:
			_drawn_w = drawn
			_bow.mesh = ChampionPalette.fold_mesh(PAL_KEY, _bow_mesh(drawn == 1))
	# Lantern: base halo x veterancy / haste (0 once dead), flares on releases and level-ups.
	_flare = maxf(0.0, _flare - dt * 2.2)
	var g := glow_level() * (LANTERN_BASE + _flare + _hold)
	_hold = 0.0
	if _lantern and g != _lantern_w:
		_lantern_w = g
		_lantern.set_instance_shader_parameter(&"glow_boost", g)
	var bg := glow_level() * 1.6
	if _bow and bg != _bow_glow_w:
		_bow_glow_w = bg
		_bow.set_instance_shader_parameter(&"glow_boost", bg)
	# Hand prop (class poses): shown only on the frames a pose asks for it; the flare burns bright.
	var pr: int = PROP_NONE if _dead else _prop_req
	_prop_req = PROP_NONE
	if _hand_prop:
		if pr != _prop_w:
			_prop_w = pr
			_hand_prop.visible = pr != PROP_NONE
			if pr != PROP_NONE:
				_hand_prop.mesh = ChampionPalette.fold_mesh(PAL_KEY, _flare_mesh() if pr == PROP_FLARE else _snare_mesh())
		var pg := glow_level() * 2.6 if pr == PROP_FLARE else 0.0
		if pg != _prop_glow_w:
			_prop_glow_w = pg
			_hand_prop.set_instance_shader_parameter(&"glow_boost", pg)
	# Lantern swing: hangs plumb (counters Root + Chest pitch / roll), idles, swings with the stride, kicks on shots.
	_kick = maxf(0.0, _kick - dt * 22.0)
	if _lantern == null or (_tier >= 1 and _walk_w == 0.0 and _action == &"" and not _dead and _kick == 0.0):
		return
	var ph := _t + _phase_off
	var sx := 2.5 * sin(ph * 1.9) + 9.0 * _walk_w * sin(TAU * _walk_p * 2.0 - 1.2) + _kick * sin(ph * 11.0)
	var sz := 2.0 * sin(ph * 1.3 + 1.0) + 6.0 * _walk_w * sin(TAU * _walk_p + 0.9)
	var root := _piv[P_ROOT]
	var chest := _piv[P_CHEST]
	var pitch := root.rotation.x + chest.rotation.x
	var roll := root.rotation.z + chest.rotation.z
	var sw := Vector3(sx * DEG - pitch, 0.0, sz * DEG - roll)
	if sw.distance_squared_to(_swing_w) > 1e-7:
		_swing_w = sw
		_lantern.rotation = sw


func _on_revive() -> void:
	if _face:
		_face.reset()
	_flare = 0.0
	_kick = 0.0
	_hold = 0.0
	_fired = false
	_grabbed = false
	_prop_req = PROP_NONE
	_prop_w = -1
	_prop_glow_w = -1.0
	_bow_rot_w = Vector3(999, 0, 0)
	_drawn_w = -1
	_lantern_w = -1.0
	_bow_glow_w = -1.0
	_swing_w = Vector3(999, 0, 0)


# ---------------------------------------------------------------- G-C hero layer (docs/art/gc_champions.md)

## A ChampionShapes SurfaceTool committed and appended to a bucket.
static func _put_st(acc: Array, st: SurfaceTool) -> void:
	var m := ChampionShapes.commit(st)
	if m.get_surface_count() > 0:
		_put(acc, m, Transform3D.IDENTITY)


## Rectangle (half sizes hx, hy) with rounded corners of radius r (3 points per corner), counter-clockwise.
static func _round_rect(hx: float, hy: float, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var cs: Array[Vector2] = [Vector2(hx - r, -hy + r), Vector2(hx - r, hy - r), Vector2(-hx + r, hy - r), Vector2(-hx + r, -hy + r)]
	for k: int in 4:
		for j: int in 3:
			var a := -PI * 0.5 + PI * 0.5 * (float(k) + float(j) / 2.0)
			out.append(cs[k] + Vector2(cos(a), sin(a)) * r)
	return out


## Dark trousers (G-C): thigh -> knee -> calf -> ankle (was a 162-vertex capsule), the bottom inside the boot.
static func _leg_mesh(sx: float) -> ArrayMesh:
	var key := "leg%d" % int(sx)
	if _wf_meshes.has(key):
		return _wf_meshes[key]
	var acc := _bucket()
	var x := 0.135 * sx
	var s := ChampionShapes.begin()
	ChampionShapes.tube(s, PackedVector3Array([Vector3(x, 0.74, 0.0), Vector3(x * 1.02, 0.60, 0.008), Vector3(x, 0.47, 0.022),
		Vector3(x, 0.36, 0.0), Vector3(x, 0.28, 0.0)]), PackedFloat32Array([0.105, 0.108, 0.086, 0.09, 0.08]), 8, false)
	_put_st(acc, s)
	return _commit(key, [[acc, _m(&"wayfinder_hat")]])


## Coat sleeve (G-C): shoulder -> bicep -> elbow (bent back) -> forearm swell -> wrist (was a capsule).
static func _sleeve_mesh(side: float) -> ArrayMesh:
	var key := "sleeve%d" % int(side)
	if _wf_meshes.has(key):
		return _wf_meshes[key]
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var hand := GRIP_R if side > 0.0 else HAND_L
	var wrist := sh.lerp(hand, 0.86) + Vector3(0, 0.02, 0)
	var el := sh.lerp(wrist, 0.5) + Vector3(0.012 * side, 0.0, -0.025)
	var acc := _bucket()
	var s := ChampionShapes.begin()
	ChampionShapes.tube(s, PackedVector3Array([sh + Vector3(0, 0.03, 0), sh.lerp(el, 0.45), el, el.lerp(wrist, 0.45), wrist]),
		PackedFloat32Array([0.088, 0.094, 0.076, 0.082, 0.07]), 8, true)
	_put_st(acc, s)
	return _commit(key, [[acc, _m(&"wayfinder_coat")]])


## The traveller's half-cloak (G-C, team colour: wayfinder_pennon, banner shader with its glyph): pinned at the right
## collar, it sweeps over the left shoulder and down the left side of the back, clear of the pack and the pole.
static func _mantle_mesh() -> ArrayMesh:
	if _wf_meshes.has("mantle"):
		return _wf_meshes["mantle"]
	var acc := _bucket()
	var s := ChampionShapes.begin()
	var top := ChampionShapes.arc(Vector3(-0.03, 1.505, -0.03), 0.37, 0.34, -0.1, -2.5, 7)
	ChampionShapes.cloth(s, top, 0.56, 1.3, 0.12, 6, 4, 2.0, 0.025, 0.04)
	var m := ChampionShapes.commit(s)
	_put(acc, m, Transform3D.IDENTITY)
	return _commit("mantle", [[acc, _m(&"wayfinder_pennon")]])
