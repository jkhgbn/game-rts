extends CharacterModel
## The Coin-Cutter champion (champions.md 4.1 / 4.3 / 4.6; task 9.V3): Sable Quint (variant A) / Silas Quint (B).
## A lean raider in a charcoal hood whose LONG TAIL streams down the back, a jagged mantle open at the throat (coin
## clasp), two short brass crescent knives (right hand forward grip, left hand reverse grip, the blade trailing
## past the elbow), a bulging burgundy LOOT SACK on the left hip and a belt of glowing gold COINS. Team colour only on
## the diagonal sash (knot + two waving tails) and the small back pennant (gold coin mark), both `coin_cutter_pennon`,
## so set_team_color recolours them and nothing else. Face (faces pass 2026-09-28): FaceKit, tan skin, gold glinting
## irises, a golden fringe out of the hood, the scarf pulled down under the lips (was a void + gold eye bar). Golden braid on
## both siblings; Silas (variant B) adds a forked beard: the one toggled node `VariantB` (set_variant).
## Glow points: coin belt (1.5, coin_cutter_gold_glow) + the gold irises (Face node), the flipped coin during casts.
## Attack `slash2`: fast double cut (right forehand, strike 0.08 s, then left backhand), 0.42 s. Casts (play_cast):
## cutpurse (coil + deep lunge-stab, gold glint at the tip), smoke_pouch (pulls a pouch from the belt, hurls it at
## its feet, knife arm up over the face), marked_for_coin (flips a coin high, catches it and points it at the mark).
## Unknown ids play cutpurse. Idle fidgets at close range only: flips a coin, weighs the sack. Death: `fall` + the
## sack spills its coins. Secondary motion: hood tail and sack on damped springs (walk, lunges, hits).
## Budget: 18 authored meshes (blob included), 14 draw instances (7 merged pivots + HoodTail, LootSack, VariantB,
## Pouch, FlipCoin, blob, sparks), 0 lights, 5 materials (this folder) + the kit's shared blob material.
## Champion classes (task 11.V4, skills-rework.md 5): the two knives are their own static parts tagged
## `mark_archetype_weapon` (dropped from the arm merges once a class is drawn); the hood, hood tail, loot sack, coin belt,
## sash and pennant always stay. Grips: the class weapon sits in the fists HAND_R / HAND_L (the quiver: the kit's back
## point, between the hood tail and the pennant pole). Archetype casts with a class weapon (per weapon_class()):
## Cutpurse = a lunging spear thrust / sword stab behind the shield / greatsword chop / staff jab (the glint at the
## weapon tip); Smoke Pouch = the left hand still throws, the weapon arm guards the face (spear upright, sword raised,
## greatsword kept on the shoulder, staff across); Marked for Coin = the coin flip, then the weapon points at the
## mark (the Sword and Shield flips beside the shield and points the sword). Class skills: the kit's poses.
## get_beam_origin(): the staff crystal (Wizard), the left fist (Spear javelin, Sword and Shield shield), else chest
## height in front.

const CC_DIR := "res://art/units/champions/coin_cutter/"
## B8 material merge (in-game grade 2026-09-30): every painted / glow part folds into ONE palette material
## (ChampionPalette, art/units/champions/champion_palette.gd): palette + pennon + face + sparks + blob = 5 materials.
const PAL_KEY := "coin_cutter"
const COIN_GOLD := Color(1.0, 0.85, 0.3)

# Model-space key points (feet origin, face +Z, weapon hand ArmR at +X).
const SHOULDER_R := Vector3(0.30, 1.25, 0.0)
const HAND_R := Vector3(0.32, 0.93, 0.09)
const SHOULDER_L := Vector3(-0.30, 1.25, 0.0)
const HAND_L := Vector3(-0.38, 0.99, 0.12)
const KNIFE_OFF := 0.085                      # guard distance from the fist centre along the blade
const BLADE_LEN := 0.37
const KNIFE_R_AXIS := Vector3(0.0, 0.70, 0.70)
const KNIFE_L_AXIS := Vector3(-0.02, -0.25, -1.0)
const TORSO_C := Vector3(0.0, 1.08, 0.0)
const FACE_C := Vector3(0.0, 1.50, 0.09)
const LEAN_DEG := 4.0
const TAIL_AT := Vector3(0.0, 1.69, -0.12)    # hood-tail pivot (child of Head)
const SACK_AT := Vector3(-0.22, 0.84, -0.10)  # loot-sack pivot (child of Hips)
const SACK_C := Vector3(-0.37, 0.62, -0.14)
const IDLE_IDS: Array[StringName] = [&"idle_flip", &"idle_weigh"]

# Keyframe tables [times], [values] (degrees / metres). Smooth between keys.
const SL_R_T: Array[float] = [0.0, 0.05, 0.10, 0.18, 0.42]
const SL_R_X: Array[float] = [0.0, 18.0, -72.0, -52.0, 0.0]
const SL_R_Z: Array[float] = [0.0, 45.0, -42.0, -30.0, 0.0]
const SL_L_T: Array[float] = [0.0, 0.08, 0.12, 0.20, 0.42]
const SL_L_X: Array[float] = [0.0, -50.0, -62.0, -38.0, 0.0]
const SL_L_Z: Array[float] = [0.0, 12.0, 52.0, -55.0, 0.0]
const SL_C_T: Array[float] = [0.0, 0.05, 0.10, 0.13, 0.20, 0.42]
const SL_C_Y: Array[float] = [0.0, 22.0, -28.0, -25.0, 24.0, 0.0]
const SL_B_T: Array[float] = [0.0, 0.05, 0.10, 0.22, 0.42]
const SL_B_Z: Array[float] = [0.0, -0.03, 0.20, 0.22, 0.0]
const SL_B_Y: Array[float] = [0.0, 0.0, -0.05, -0.04, 0.0]
const SL_LR: Array[float] = [0.0, 0.0, -22.0, -18.0, 0.0]
const SL_LL: Array[float] = [0.0, 0.0, 14.0, 12.0, 0.0]

const CP_T: Array[float] = [0.0, 0.12, 0.21, 0.34, 0.62]
const CP_BZ: Array[float] = [0.0, -0.06, 0.50, 0.46, 0.0]
const CP_BY: Array[float] = [0.0, -0.08, -0.13, -0.11, 0.0]
const CP_CX: Array[float] = [0.0, 14.0, 26.0, 22.0, 0.0]
const CP_CY: Array[float] = [0.0, 18.0, -12.0, -10.0, 0.0]
const CP_RX: Array[float] = [0.0, 30.0, -86.0, -80.0, 0.0]
const CP_RZ: Array[float] = [0.0, 22.0, -6.0, -6.0, 0.0]
const CP_LX: Array[float] = [0.0, -20.0, 45.0, 40.0, 0.0]
const CP_LZ: Array[float] = [0.0, 0.0, -35.0, -30.0, 0.0]
const CP_GR: Array[float] = [0.0, -10.0, -48.0, -45.0, 0.0]
const CP_GL: Array[float] = [0.0, 12.0, 38.0, 35.0, 0.0]
const CP_HX: Array[float] = [0.0, -8.0, -22.0, -18.0, 0.0]

const SP_T: Array[float] = [0.0, 0.14, 0.30, 0.37, 0.72]
const SP_LX: Array[float] = [0.0, 20.0, -160.0, -35.0, 0.0]
const SP_LZ: Array[float] = [0.0, 30.0, 10.0, 0.0, 0.0]
const SP_CX: Array[float] = [0.0, 12.0, -12.0, 24.0, 0.0]
const SP_CY: Array[float] = [0.0, -10.0, 15.0, -12.0, 0.0]
const SP_BY: Array[float] = [0.0, -0.03, 0.03, -0.13, 0.0]
const SP_RX: Array[float] = [0.0, 0.0, -30.0, -115.0, 0.0]
const SP_RZ: Array[float] = [0.0, 0.0, 0.0, -35.0, 0.0]
const SP_HX: Array[float] = [0.0, 14.0, -10.0, 12.0, 0.0]
const SP_GL: Array[float] = [0.0, 0.0, -10.0, 20.0, 0.0]
const SP_GR: Array[float] = [0.0, 0.0, 5.0, -15.0, 0.0]

const MK_T: Array[float] = [0.0, 0.15, 0.45, 0.72, 0.84, 1.05]
const MK_LX: Array[float] = [0.0, -75.0, -60.0, -80.0, -95.0, 0.0]
const MK_LZ: Array[float] = [0.0, 20.0, 15.0, 12.0, 5.0, 0.0]
const MK_HX: Array[float] = [0.0, -5.0, -25.0, -5.0, -8.0, 0.0]
const MK_CY: Array[float] = [0.0, 8.0, 5.0, 0.0, -18.0, 0.0]
const MK_CX: Array[float] = [0.0, 0.0, -6.0, 0.0, 4.0, 0.0]
const MK_RX: Array[float] = [0.0, -10.0, -15.0, -10.0, -20.0, 0.0]

const IF_T: Array[float] = [0.0, 0.25, 0.60, 0.95, 1.40]
const IF_LX: Array[float] = [0.0, -70.0, -62.0, -70.0, 0.0]
const IF_LZ: Array[float] = [0.0, 15.0, 15.0, 15.0, 0.0]
const IF_HX: Array[float] = [0.0, 0.0, -20.0, -4.0, 0.0]

const IW_T: Array[float] = [0.0, 0.35, 0.60, 0.85, 1.10, 1.50]
const IW_LX: Array[float] = [0.0, 25.0, 20.0, 25.0, 20.0, 0.0]
const IW_LZ: Array[float] = [0.0, -30.0, -32.0, -30.0, -30.0, 0.0]
const IW_HY: Array[float] = [0.0, -30.0, -35.0, -35.0, -25.0, 0.0]
const IW_HX: Array[float] = [0.0, 15.0, 12.0, 15.0, 10.0, 0.0]
const IW_CY: Array[float] = [0.0, -12.0, -12.0, -12.0, -8.0, 0.0]
const IW_LIFT: Array[float] = [0.0, 0.0, 0.08, 0.0, 0.07, 0.0]

# Archetype casts with a class weapon (11.V4). Values per class on the cast's own times (CP_T / SP_T / MK_T).
# Cutpurse: [weapon arm RX, RZ, weapon arm push Z (m), free arm LX, LZ]. Grips of ChampionWeaponKit.piece_hold; the
# lunge already pitches the chest 26 deg forward, so the spear stays near its rest angle (-4), the sword lifts to -54
# (both about level at the strike), the greatsword chops forward and stops at +124 (tip clear of the ground), the staff head goes forward at +35.
const CP_CLASS: Dictionary = {
	&"spear": [[0.0, 6.0, -4.0, -4.0, 0.0], [0.0, 4.0, -4.0, -4.0, 0.0], [0.0, -0.14, 0.42, 0.38, 0.0],
		[0.0, -20.0, -48.0, -44.0, 0.0], [0.0, 0.0, 10.0, 8.0, 0.0]],
	&"sword_shield": [[0.0, 25.0, -54.0, -50.0, 0.0], [0.0, 18.0, -4.0, -4.0, 0.0], [0.0, -0.10, 0.22, 0.20, 0.0],
		[0.0, -30.0, -50.0, -44.0, 0.0], [0.0, 0.0, 12.0, 10.0, 0.0]],
	&"two_hand": [[0.0, -35.0, 124.0, 116.0, 0.0], [0.0, -10.0, 16.0, 14.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, -28.0, 99.0, 93.0, 0.0], [0.0, 10.0, -14.0, -12.0, 0.0]],
	&"wizard": [[0.0, -20.0, 38.0, 34.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0], [0.0, -0.06, 0.26, 0.24, 0.0],
		[0.0, -30.0, -70.0, -65.0, 0.0], [0.0, 0.0, 10.0, 8.0, 0.0]],
}
# Smoke Pouch: [weapon arm RX, RZ] (the left hand throws the pouch as before).
const SP_CLASS: Dictionary = {
	&"spear": [[0.0, 0.0, -20.0, -70.0, 0.0], [0.0, 0.0, 0.0, -30.0, 0.0]],
	&"sword_shield": [[0.0, 0.0, -30.0, -115.0, 0.0], [0.0, 0.0, 0.0, -35.0, 0.0]],
	&"two_hand": [[0.0, 0.0, -10.0, -25.0, 0.0], [0.0, 0.0, 0.0, -10.0, 0.0]],
	&"wizard": [[0.0, 0.0, -15.0, -45.0, 0.0], [0.0, 0.0, 0.0, -25.0, 0.0]],
}
# Marked for Coin: [weapon arm RX, RZ]; the last key but one (0.84) points the weapon at the mark.
const MK_CLASS: Dictionary = {
	&"spear": [[0.0, -10.0, -15.0, -10.0, 18.0, 0.0], [0.0, 0.0, 0.0, 0.0, -6.0, 0.0]],
	&"sword_shield": [[0.0, -10.0, -15.0, -10.0, -58.0, 0.0], [0.0, 0.0, 0.0, 0.0, -10.0, 0.0]],
	&"two_hand": [[0.0, -10.0, -15.0, -10.0, -20.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]],
	&"wizard": [[0.0, -10.0, -15.0, -10.0, 28.0, 0.0], [0.0, 0.0, 0.0, 0.0, -4.0, 0.0]],
}
# Sword and Shield: the coin flips beside the shield (left arm out to the side), lowered when the sword points.
const MK_SS_LX: Array[float] = [0.0, -62.0, -52.0, -66.0, -35.0, 0.0]
const MK_SS_LZ: Array[float] = [0.0, 34.0, 30.0, 28.0, 20.0, 0.0]

## 0 = Sable Quint (name A), 1 = Silas Quint (name B, forked beard). Use set_variant().
@export var variant: int = 0

static var _own_mats: Dictionary = {}
static var _meshes: Dictionary = {}

var _variant_node: Node3D
var _tail: MeshInstance3D
var _sack: MeshInstance3D
var _pouch: MeshInstance3D
var _coin: MeshInstance3D
var _sparks: GPUParticles3D
var _belt_glow: GeometryInstance3D     # merged Hips (coins), glow driven here
var _eye_glow: GeometryInstance3D      # the Face node (gold irises), glow driven here
## Painted face (FaceKit via ChampionFaces, faces pass 2026-09-28).
var _face: FaceRig

# Secondary motion (springs, radians / metres).
var _tail_a: Vector2 = Vector2.ZERO    # x = stream back, y = side swing (rot z)
var _tail_v: Vector2 = Vector2.ZERO
var _sack_a: Vector3 = Vector3.ZERO    # x = swing back, y = lift (m), z = side swing
var _sack_v: Vector3 = Vector3.ZERO
var _prev_root_z: float = 0.0
var _prev_yaw: float = 0.0
var _sack_rest: Vector3 = Vector3.ZERO
var _tail_written: Vector2 = Vector2(99, 99)
var _sack_written: Vector3 = Vector3(99, 99, 99)
# Per-frame targets written by the poses (reset every frame).
var _belt_k: float = 1.0
var _eye_k: float = 1.0
var _sack_lift: float = 0.0
var _belt_written: float = -1.0
var _eye_written: float = -1.0
var _coin_written: float = -1.0
var _fx_fired: bool = false
var _fx2_fired: bool = false
var _idle_left: float = 6.0
var _idle_i: int = 0


static func _mat(name: StringName) -> Material:
	if not _own_mats.has(name):
		_own_mats[name] = load(CC_DIR + "coin_cutter_" + String(name) + ".tres")
	return _own_mats[name]


# ================================================================ hooks (+ variant)

## Variant B (Silas) shows the forked beard; A (Sable) hides it. Safe before _ready.
func set_variant(v: int) -> void:
	variant = clampi(v, 0, 1)
	if _variant_node:
		_variant_node.visible = variant == 1
	ChampionFaces.switch(_face, "coin_cutter", _face_spec, variant)


## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## Face styles (FaceKit spec per variant; faces pass 2026-09-28). Sable (A): a sly young raider, tan skin, gold glinting
## irises (the old eye-bar glow), a golden swept fringe out of the hood (her braid is the head mesh), a smirk at
## rest. Silas (B): the older brother, heavier brows, a short fringe; his forked beard is VariantB.
static func _face_spec(v: int) -> Dictionary:
	var skin := Color(0.80, 0.60, 0.46)
	var gold := Color(0.86, 0.64, 0.26)
	var tip := Color(1.0, 0.84, 0.46)
	var fs := sphere(0.19, 12, 6)
	var spec := {"center": FACE_C, "radius": 0.19, "head_mesh": fs, "preset": &"bright" if v == 0 else &"stern",
		"skin": skin, "hair": gold, "hair_tip": tip, "eyes": Color(1.0, 0.74, 0.22), "ears": &"none",
		"palette": {"iris_glow": 0.45, "brow": Color(0.52, 0.34, 0.14), "lash": Color(0.14, 0.09, 0.07),
			"lip": Color(0.72, 0.40, 0.36)},
		"x": {&"neutral": {"mouth": {"kind": "smirk"}}},
		"hair_fn": func(acc: Dictionary) -> void:
			# the face sphere (was the charcoal void) is part of the face mesh: no skin material on the hood
			FaceKit.put_mesh(acc, fs, Transform3D(Basis.IDENTITY, FACE_C), skin)
			# hair framing the face in the hood: Sable a long swept fringe, Silas a short one the other way
			ChampionFaces.frame_locks(acc, FACE_C, 0.19, gold, tip, 1.0 if v == 0 else -0.7, false)}
	return spec


func play_hit() -> void:
	var before := _hit_t
	super()
	if _hit_t < before:
		_tail_v += Vector2(-3.5, 2.0)
		_sack_v += Vector3(2.5, 0.25, -1.5)


## Where casts and shots leave the Coin-Cutter (world): the staff crystal (Wizard class bolt, Arc Bolt), the left fist
## (Spear: the javelin; Sword and Shield: the thrown shield), else chest height half a metre in front.
func get_beam_origin() -> Vector3:
	if _ready_done and is_inside_tree():
		match weapon_class():
			&"wizard":
				var tip: Variant = get_weapon_tip()
				if tip is Vector3:
					return tip
			&"spear", &"sword_shield":
				var arm: Node3D = get_node_or_null(^"Root/Chest/ArmL")
				if arm:
					return arm.global_transform * (HAND_L - _arm_rest(P_ARM_L))
		return to_global(Vector3(0.0, body_height * 0.85, 0.45))
	return Vector3(0.0, body_height * 0.85, 0.45)


# ================================================================ class weapon grips (11.V4)

## The class weapons sit in the Coin-Cutter's own fists (the knife grips); the back slot stays the kit's (measured
## behind the mantle, between the hood tail on the left and the pennant pole on the right).
func _weapon_slot(slot: StringName) -> Transform3D:
	match slot:
		&"hand_r":
			return Transform3D(Basis.IDENTITY, HAND_R)
		&"hand_l":
			return Transform3D(Basis.IDENTITY, HAND_L)
	return super._weapon_slot(slot)


# ================================================================ parts

## The Wizard staff crystal keeps its kit weapon-glow drive (the palette material declares glow_boost everywhere).
func _on_weapon_class(class_id: StringName) -> void:
	ChampionPalette.claim_crystal_glow(self, class_id)


## Every part goes through the champion palette fold (B8): painted / glow materials become palette entries.
func add_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	var f := ChampionPalette.fold(PAL_KEY, mesh, mat)
	return super.add_part(pivot, f[0], f[1], model_pos, rot_deg, scl, keep_separate, part_name)


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var fx: Node3D = $Fx

	# ---- Hips: coat skirt (long split tails at the back), the coin belt (burgundy strap, brass buckle, 8 gold coins).
	add_part(hips, _coat_mesh(), _mat(&"charcoal"), Vector3.ZERO)
	add_part(hips, _belt_mesh(), null, Vector3.ZERO)
	# ---- The loot sack hangs from the belt on the left hip (own node: it bounces and swings).
	_sack = add_part(hips, _sack_mesh(), null, SACK_AT, Vector3.ZERO, Vector3.ONE, true, "LootSack")

	# ---- Legs: burgundy trousers, tall charcoal boots with folded cuffs and a brass buckle.
	add_part(leg_l, _leg_mesh(-1.0), null, Vector3.ZERO)
	add_part(leg_r, _leg_mesh(1.0), null, Vector3.ZERO)

	# ---- Chest: leaning torso, jagged mantle open at the throat (coin clasp), team sash, back pennant.
	add_part(chest, _torso_mesh(), null, Vector3.ZERO)
	add_part(chest, _sash_mesh(), _mat(&"pennon"), Vector3.ZERO)
	add_part(chest, _pennant_mesh(), null, Vector3.ZERO)

	# ---- Head: hood, shadowed face, burgundy lining, eye bar, braid. Hood tail and Silas's beard are separate.
	add_part(head, _head_mesh(), null, Vector3.ZERO)
	_tail = add_part(head, _tail_mesh(), null, TAIL_AT, Vector3.ZERO, Vector3.ONE, true, "HoodTail")
	_variant_node = add_part(head, _beard_mesh(), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true,
			"VariantB")
	# The face (faces pass 2026-09-28): FaceKit, one node; Sable / Silas each their own style (switch on set_variant).
	_face = ChampionFaces.attach(self, head, "coin_cutter", _face_spec, variant)
	_face.set_meta(&"own_glow", true)   # the gold irises flare with the casts (was the eye bar): _drive_glows

	# ---- Arms: sleeves, burgundy bracers, gloves; the two crescent knives are the archetype weapon (11.V4).
	add_part(arm_r, _arm_mesh(1.0), null, Vector3.ZERO)
	add_part(arm_l, _arm_mesh(-1.0), null, Vector3.ZERO)
	mark_archetype_weapon(add_part(arm_r, _knife_mesh(1.0), null, Vector3.ZERO))
	mark_archetype_weapon(add_part(arm_l, _knife_mesh(-1.0), null, Vector3.ZERO))
	_pouch = add_part(arm_l, _pouch_mesh(), null, HAND_L + Vector3(0.0, -0.02, 0.07), Vector3.ZERO, Vector3.ONE,
			true, "Pouch")
	_pouch.visible = false

	# ---- Fx: the flipped coin (glows on its own), one pre-built one-shot gold spark emitter (casts, death spill).
	_coin = add_part(fx, _disc(0.07, 0.022, 10), _mat(&"gold_glow"), HAND_L, Vector3(90, 0, 0), Vector3.ONE,
			true, "FlipCoin")
	_coin.set_meta(&"own_glow", true)
	_coin.visible = false
	_sparks = make_motes(COIN_GOLD, 14, 0.8, 0.10, 2.2, 0.09, false, true)
	_sparks.name = "CoinSparks"
	fx.add_child(_sparks)
	ensure_shadow_blob(0.45)


func _after_ready() -> void:
	_variant_node.visible = variant == 1
	_sack_rest = _sack.position
	_belt_glow = _merged_nodes.get(P_HIPS)
	_eye_glow = _face
	for g: GeometryInstance3D in [_belt_glow, _eye_glow]:
		if g:
			_glow_nodes.erase(g)
	_idle_left = 5.0 + 6.0 * fmod(_phase_off, 1.0)


# ================================================================ meshes (built once per game, model space)

## [cylinder, transform] from a to b (radius ra at a, rb at b).
static func _seg(a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 8) -> Array:
	var d := b - a
	var l := d.length()
	var bs: Basis
	if d.normalized().y < -0.999:
		bs = Basis(Vector3.RIGHT, PI)
	else:
		bs = Basis(Quaternion(Vector3.UP, d / l))
	return [cyl(rb, ra, 1.0, seg), Transform3D(bs.scaled_local(Vector3(1.0, l, 1.0)), (a + b) * 0.5)]


static func _at(m: Mesh, p: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Array:
	return [m, Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), p)]


## One multi-surface ArrayMesh from [[parts, material], ...]; parts = [[Mesh, Transform3D], ...]. Cached by key.
static func _bake(key: String, groups: Array) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	for g: Array in groups:
		if (g[0] as Array).is_empty():
			continue
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays(g[0]))
		am.surface_set_material(am.get_surface_count() - 1, g[1])
	_meshes[key] = am
	return am


static func _arrays(parts: Array) -> Array:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for p: Array in parts:
		var m: Mesh = p[0]
		var xf: Transform3D = p[1]
		var nb := xf.basis.inverse().transposed()
		var arr := m.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var b0 := verts.size()
		for j: int in v.size():
			verts.append(xf * v[j])
			norms.append((nb * nr[j]).normalized())
			uvs.append(uv[j] if j < uv.size() else Vector2.ZERO)
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
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	return arrays


static func _mesh(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array,
		idx: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	if not idx.is_empty():
		arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


## Two triangles for the quad a-b-c-d (a b on one row, d c on the next), wound so their front faces the vertex
## normals (Godot: clockwise front, front normal = (c - a) x (b - a)).
static func _quad(idx: PackedInt32Array, v: PackedVector3Array, n: PackedVector3Array, a: int, b: int, c: int, d: int) -> void:
	var fn := (v[d] - v[a]).cross(v[b] - v[a])
	if fn.length_squared() < 1e-14:
		fn = (v[c] - v[b]).cross(v[d] - v[b])
	if fn.dot(n[a] + n[b] + n[c] + n[d]) >= 0.0:
		idx.append_array(PackedInt32Array([a, b, d, b, c, d]))
	else:
		idx.append_array(PackedInt32Array([a, d, b, b, d, c]))


## Low-poly coin: a disc of radius r, thickness h (axis +Y), seg sides; sides false = caps only (glowing coins).
static func _disc(r: float, h: float, seg: int, sides: bool = true) -> ArrayMesh:
	var key := "disc%s_%s_%d_%s" % [r, h, seg, sides]
	if _meshes.has(key):
		return _meshes[key]
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var hy := h * 0.5
	for sd: float in [1.0, -1.0]:
		var c0 := v.size()
		v.append(Vector3(0, hy * sd, 0))
		n.append(Vector3(0, sd, 0))
		for i: int in seg:
			var a := TAU * float(i) / float(seg)
			v.append(Vector3(sin(a) * r, hy * sd, cos(a) * r))
			n.append(Vector3(0, sd, 0))
		for i: int in seg:
			var a := c0 + 1 + i
			var b := c0 + 1 + (i + 1) % seg
			if (v[b] - v[c0]).cross(v[a] - v[c0]).dot(n[c0]) >= 0.0:
				idx.append_array(PackedInt32Array([c0, a, b]))
			else:
				idx.append_array(PackedInt32Array([c0, b, a]))
	if sides:
		var s0 := v.size()
		for i: int in seg:
			var a := TAU * float(i) / float(seg)
			var o := Vector3(sin(a), 0, cos(a))
			v.append(o * r + Vector3(0, hy, 0))
			n.append(o)
			v.append(o * r - Vector3(0, hy, 0))
			n.append(o)
		for i: int in seg:
			var j := (i + 1) % seg
			_quad(idx, v, n, s0 + 2 * i, s0 + 2 * j, s0 + 2 * j + 1, s0 + 2 * i + 1)
	var uvs := PackedVector2Array()
	uvs.resize(v.size())
	var m := _mesh(v, n, uvs, idx)
	_meshes[key] = m
	return m


## Grid surface p = fn(u, v) (u, v in 0..1). Normals from finite differences, oriented away from out_from(u, v)
## (a point inside the shape). uvfn(u, v) -> Vector2 (default (u, v)). double_sided: a back copy with flipped normals.
static func _grid(fn: Callable, out_from: Callable, cols: int, rows: int, double_sided: bool = false,
		uvfn: Callable = Callable()) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	const E := 0.003
	for j: int in rows + 1:
		var v := float(j) / float(rows)
		for i: int in cols + 1:
			var u := float(i) / float(cols)
			var p: Vector3 = fn.call(u, v)
			var du: Vector3 = fn.call(minf(u + E, 1.0), v) - fn.call(maxf(u - E, 0.0), v)
			var dv: Vector3 = fn.call(u, minf(v + E, 1.0)) - fn.call(u, maxf(v - E, 0.0))
			var nn := dv.cross(du)
			var o: Vector3 = p - (out_from.call(u, v) as Vector3)
			if nn.length_squared() < 1e-14:
				nn = o
			nn = nn.normalized()
			if nn.dot(o) < 0.0:
				nn = -nn
			verts.append(p)
			norms.append(nn)
			uvs.append(uvfn.call(u, v) if uvfn.is_valid() else Vector2(u, v))
	var sides := 2 if double_sided else 1
	var nv := verts.size()
	if double_sided:
		for k: int in nv:
			verts.append(verts[k])
			norms.append(-norms[k])
			uvs.append(uvs[k])
	for s: int in sides:
		for j: int in rows:
			for i: int in cols:
				var q0 := s * nv + j * (cols + 1) + i
				_quad(idx, verts, norms, q0, q0 + 1, q0 + cols + 2, q0 + cols + 1)
	return _mesh(verts, norms, uvs, idx)


## Catmull-Rom point on pts at v (0..1).
static func _cr(pts: Array[Vector3], v: float) -> Vector3:
	var n := pts.size()
	var f := clampf(v, 0.0, 1.0) * float(n - 1)
	var i := mini(int(f), n - 2)
	var t := f - float(i)
	var p0 := pts[maxi(i - 1, 0)]
	var p1 := pts[i]
	var p2 := pts[i + 1]
	var p3 := pts[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


## A tapered tube along a Catmull-Rom curve. rfn(v) -> radius.
static func _tube(pts: Array[Vector3], rfn: Callable, ring: int, samples: int) -> ArrayMesh:
	var frame := func(v: float) -> Array:
		var t := (_cr(pts, minf(v + 0.01, 1.0)) - _cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var ref := Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.FORWARD
		var nn := t.cross(ref).normalized()
		return [nn, t.cross(nn).normalized()]
	var fn := func(u: float, v: float) -> Vector3:
		var fr: Array = frame.call(v)
		var a := TAU * u
		return _cr(pts, v) + (float(rfn.call(v))) * ((fr[0] as Vector3) * cos(a) + (fr[1] as Vector3) * sin(a))
	var centre := func(_u: float, v: float) -> Vector3:
		return _cr(pts, v)
	return _grid(fn, centre, ring, samples)


static func _lean() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, LEAN_DEG * DEG), TORSO_C) * Transform3D(Basis(), -TORSO_C)


static func _torso_r(y: float) -> float:
	return lerpf(0.20, 0.245, clampf((y - 0.84) / 0.48, 0.0, 1.0))


## Coat skirt: waist 0.90 to a hem that is short in front (0.62) and long behind (0.40), split at the centre back
## into two tails; soft folds. Model space (the Hips pivot moves it).
static func _coat_point(u: float, v: float) -> Vector3:
	var a := TAU * u
	var back := maxf(0.0, -cos(a))
	var hem := lerpf(0.58, 0.40, pow(back, 1.4)) + 0.13 * exp(-pow((a - PI) / 0.17, 2.0))
	var r := 0.205 + 0.10 * v + 0.05 * back * v + 0.012 * sin(8.0 * a) * v
	return Vector3(sin(a) * r, lerpf(0.905, hem, v), cos(a) * r)


static func _coat_mesh() -> ArrayMesh:
	if _meshes.has("cc_coat"):
		return _meshes["cc_coat"]
	var m := _grid(func(u: float, v: float) -> Vector3: return _coat_point(u, v),
			func(u: float, v: float) -> Vector3: return Vector3(0, _coat_point(u, v).y, 0), 28, 5)
	_meshes["cc_coat"] = m
	return m


## Charcoal belt strung with 8 glowing gold coins, brass buckle.
static func _belt_mesh() -> ArrayMesh:
	if _meshes.has("cc_belt"):
		return _meshes["cc_belt"]
	var coins: Array = []
	for k: int in 8:
		var a := (45.0 + 38.5 * float(k)) * DEG
		var out := Vector3(sin(a), 0.0, cos(a))
		var tang := Vector3(cos(a), 0.0, -sin(a))
		var bs := Basis(tang, (10.0 if k % 2 == 0 else -10.0) * DEG) * Basis(Quaternion(Vector3.UP, out))
		coins.append([_disc(0.058, 0.022, 8, false), Transform3D(bs, out * 0.258 + Vector3(0, 0.86 + (0.012 if k % 2 == 0 else -0.01), 0))])
	return _bake("cc_belt", [
		[[_at(torus(0.205, 0.25, 14), Vector3(0, 0.86, 0), Vector3.ZERO, Vector3(1, 1.6, 1))], _mat(&"charcoal")],
		[[_at(box(Vector3(0.13, 0.11, 0.05)), Vector3(0, 0.86, 0.235))], _mat(&"brass")],
		[coins, _mat(&"gold_glow")]])


## Bulging, lumpy brass-leather sack (the coins inside) with a pinched neck and a frilled mouth, tilted so the neck
## leans to the belt; burgundy cord, two gold coins sticking out, a charcoal strap. Relative to SACK_AT (own node).
static func _sack_point(u: float, v: float) -> Vector3:
	var a := TAU * u
	var r: float
	var y: float
	if v < 0.12:
		var s := v / 0.12
		r = lerpf(0.095, 0.055, s) + 0.012 * sin(7.0 * a) * (1.0 - s)
		y = lerpf(0.215, 0.15, s)
	else:
		var s := (v - 0.12) / 0.88
		var ph := lerpf(0.29, PI, s)
		var sp := sin(ph)
		r = 0.19 * sp * (1.0 + 0.07 * sin(5.0 * a + 0.4) * sp * sp + 0.04 * sin(3.0 * a + 1.3))
		y = -0.01 + 0.17 * cos(ph) - 0.02 * sp * sp
	return Vector3(sin(a) * r, y, cos(a) * r)


static func _sack_mesh() -> ArrayMesh:
	if _meshes.has("cc_sack"):
		return _meshes["cc_sack"]
	var xf := Transform3D(Basis(Vector3.BACK, -20.0 * DEG), SACK_C - SACK_AT)   # neck leans in toward the belt
	var body := _grid(func(u: float, v: float) -> Vector3: return _sack_point(u, v),
			func(_u: float, v: float) -> Vector3: return Vector3(0, _sack_point(0.0, v).y, 0), 12, 8)   # was 16 x 10 (faces pass trim)
	var neck := xf * Vector3(0, 0.15, 0)
	var mouth := xf * Vector3(0, 0.21, 0)
	var m := _bake("cc_sack", [
		[[[body, xf]], _mat(&"brass")],
		[[[torus(0.045, 0.074, 10), xf * Transform3D(Basis().scaled(Vector3(1, 1.5, 1)), Vector3(0, 0.15, 0))]],
			_mat(&"burgundy")],
		[[[_disc(0.056, 0.018, 8, false), Transform3D(xf.basis * Basis(Vector3.RIGHT, 70.0 * DEG) * Basis(Vector3.BACK, 20.0 * DEG), mouth + Vector3(0.01, 0.03, 0.03))],
			[_disc(0.05, 0.018, 8, false), Transform3D(xf.basis * Basis(Vector3.RIGHT, -25.0 * DEG) * Basis(Vector3.BACK, -55.0 * DEG), mouth + Vector3(-0.03, 0.02, -0.02))]],
			_mat(&"gold_glow")],
		[[_seg(Vector3(0, 0.02, 0), neck, 0.03, 0.028, 6)], _mat(&"charcoal")]])
	return m


## Leg (G-C): a shaped burgundy-trousered leg in charcoal (thigh -> knee -> calf; was a straight can), a tall boot
## swelling at the calf over a rounded toe-forward foot (was a box), the folded burgundy cuff and the brass buckle.
static func _leg_mesh(side: float) -> ArrayMesh:
	if _meshes.has("cc_leg%d" % int(side)):
		return _meshes["cc_leg%d" % int(side)]
	var x := 0.13 * side
	var bx := 0.145 * side
	var leg := ChampionShapes.begin()
	ChampionShapes.tube(leg, PackedVector3Array([Vector3(x, 0.72, 0.0), Vector3(x * 1.04, 0.56, 0.008),
		Vector3(lerpf(x, bx, 0.6), 0.43, 0.02), Vector3(bx, 0.32, 0.0)]), PackedFloat32Array([0.096, 0.098, 0.08, 0.086]), 7,
		false)
	ChampionShapes.lathe(leg, PackedVector2Array([Vector2(0.096, 0.04), Vector2(0.112, 0.15), Vector2(0.116, 0.24),
		Vector2(0.106, 0.30)]), 8, _xf3(Vector3(bx, 0.0, 0.0)), 1.0, 1.05, false)
	ChampionShapes.lathe(leg, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.10, 0.0), Vector2(0.11, 0.035),
		Vector2(0.098, 0.085), Vector2(0.06, 0.12), Vector2(0.0, 0.13)]), 8, _xf3(Vector3(bx, 0.0, 0.065)), 1.0, 1.6)
	var cuff := ChampionShapes.begin()
	ChampionShapes.lathe(cuff, PackedVector2Array([Vector2(0.105, 0.255), Vector2(0.13, 0.265), Vector2(0.128, 0.32),
		Vector2(0.105, 0.33)]), 8, _xf3(Vector3(bx, 0.0, 0.0)), 1.0, 1.05, false)
	var brass := ChampionShapes.begin()
	ChampionShapes.plate(brass, PackedVector2Array([Vector2(-0.042, -0.026), Vector2(0.042, -0.026), Vector2(0.042, 0.026),
		Vector2(-0.042, 0.026)]), 0.022, 0.008, _xf3(Vector3(bx, 0.17, 0.118)))
	return _bake("cc_leg%d" % int(side), [[[[ChampionShapes.commit(leg), Transform3D.IDENTITY]], _mat(&"charcoal")],
		[[[ChampionShapes.commit(cuff), Transform3D.IDENTITY]], _mat(&"burgundy")],
		[[[ChampionShapes.commit(brass), Transform3D.IDENTITY]], _mat(&"brass")]])


## Burgundy mantle: a round capelet over the shoulders, open at the throat, its hem cut into jagged dags.
static func _mantle_point(u: float, v: float) -> Vector3:
	var a0 := 0.30 + 0.40 * v                     # the front opening widens toward the hem
	var a := lerpf(a0, TAU - a0, u)
	var back := maxf(0.0, -cos(a))
	var r := 0.15 + 0.25 * sin(v * PI * 0.5) + 0.02 * back * v
	var dag := 0.055 * pow(absf(cos(3.5 * a)), 3.0) * v * v * v
	return Vector3(sin(a) * r, 1.47 - 0.30 * v * v - dag - 0.03 * back * v, cos(a) * r + 0.01)


## Charcoal torso keg (leaning), the burgundy mantle, the brass coin clasp at the throat.
static func _torso_mesh() -> ArrayMesh:
	if _meshes.has("cc_torso"):
		return _meshes["cc_torso"]
	var mantle := _grid(func(u: float, v: float) -> Vector3: return _mantle_point(u, v),
			func(u: float, v: float) -> Vector3: return Vector3(0, _mantle_point(u, v).y + 0.05, 0), 18, 4, true)
	var lean := _lean()
	var m := _bake("cc_torso", [
		[[[cyl(0.245, 0.20, 0.48, 10), lean * Transform3D(Basis(), TORSO_C)]], _mat(&"charcoal")],
		[[[mantle, Transform3D()]], _mat(&"burgundy")],
		[[_at(_disc(0.06, 0.025, 8), Vector3(0, 1.42, 0.165), Vector3(72, 0, 0))], _mat(&"brass")]])
	return m


## Team sash: a band from the right shoulder across the chest and back to the left waist, a knot and two tails that
## hang down the left thigh (banner shader: the band has UV.y 0 = still, the tails UV.y 0 -> 1 = wave, dark stripes;
## UV.x 0 keeps the pennant glyph and swallow-tail off them).
static func _sash_point(a: float) -> Vector3:
	const K := 0.74
	const YC := 1.14
	var y := YC
	var r := 0.0
	for _i: int in 4:
		r = _torso_r(y) + 0.02
		y = YC + K * sin(a) * r
	return Vector3(sin(a) * r, y, cos(a) * r)


static func _sash_mesh() -> ArrayMesh:
	if _meshes.has("cc_sash"):
		return _meshes["cc_sash"]
	var lean := _lean()
	var pn := Vector3(-0.74, 1.0, 0.0).normalized()
	var band := func(u: float, v: float) -> Vector3:
		var a := TAU * u
		var p := _sash_point(a)
		var out := Vector3(sin(a), 0.0, cos(a))
		var w := (pn - out * pn.dot(out)).normalized()
		return p + w * (v - 0.5) * 0.13 + out * 0.004 * sin(PI * v)
	var band_c := func(u: float, _v: float) -> Vector3:
		return Vector3(0, _sash_point(TAU * u).y, 0)
	var still := func(_u: float, _v: float) -> Vector2:
		return Vector2.ZERO
	var band_m := _grid(band, band_c, 28, 2, false, still)
	var parts: Array = [[band_m, lean]]
	# knot on the left waist
	var ka := -60.0 * DEG
	var knot := Vector3(sin(ka) * 0.235, 0.975, cos(ka) * 0.235)
	parts.append([sphere(0.065, 8, 4), lean * Transform3D(Basis(Vector3.UP, ka).scaled(Vector3(1.0, 0.85, 0.75)), knot)])
	# two tails following the coat's flare
	for t: Array in [[-62.0, -6.0, 0.44, 0.10], [-52.0, 5.0, 0.36, 0.09]]:
		var a0: float = float(t[0]) * DEG
		var da: float = float(t[1]) * DEG
		var ln: float = t[2]
		var wd: float = t[3]
		var tail := func(u: float, v: float) -> Vector3:
			var a := a0 + da * v
			var y := 0.96 - ln * v
			var r := 0.255 + 0.10 * clampf((0.905 - y) / 0.32, 0.0, 1.0) + 0.035 * v
			var c := Vector3(sin(a) * r, y, cos(a) * r)
			var across := Vector3(cos(a), 0.0, -sin(a))
			return c + across * (u - 0.5) * lerpf(wd, wd * 0.85, v) + Vector3(sin(a), 0, cos(a)) * 0.012 * sin(PI * u)
		var tail_c := func(_u: float, v: float) -> Vector3:
			return Vector3(0, 0.96 - ln * v, 0)
		var down := func(_u: float, v: float) -> Vector2:
			return Vector2(0.0, v)
		parts.append([_grid(tail, tail_c, 2, 6, false, down), Transform3D()])
	var m := _bake("cc_sash", [[parts, _mat(&"pennon")]])
	return m


## Back pennant on a short pole from the belt (right side of the back): crossbar, a brass coin finial, the team
## cloth with its gold coin mark (diamond glyph) and swallow-tail.
static func _pennant_mesh() -> ArrayMesh:
	if _meshes.has("cc_pennant"):
		return _meshes["cc_pennant"]
	var p0 := Vector3(0.24, 0.90, -0.245)
	var p1 := Vector3(0.27, 2.00, -0.38)
	var cloth := func(u: float, v: float) -> Vector3:
		return Vector3(lerpf(0.12, 0.41, u), 1.93 - 0.44 * v, -0.39 - 0.012 * sin(PI * u))
	var cloth_c := func(u: float, v: float) -> Vector3:
		return Vector3(lerpf(0.12, 0.41, u), 1.93 - 0.44 * v, 0.0)
	return _bake("cc_pennant", [
		[[_seg(p0, p1, 0.028, 0.024, 6), _seg(Vector3(0.11, 1.945, -0.385), Vector3(0.42, 1.945, -0.385), 0.02, 0.02, 6)],
			_mat(&"charcoal")],
		[[_at(_disc(0.07, 0.024, 8), p1 + Vector3(0, 0.07, 0), Vector3(90, 0, 0)),
			_at(sphere(0.032, 6, 3), Vector3(0.11, 1.945, -0.385)), _at(sphere(0.032, 6, 3), Vector3(0.42, 1.945, -0.385))],
			_mat(&"brass")],
		[[[_grid(cloth, cloth_c, 4, 7), Transform3D()]], _mat(&"pennon")]])


## Burgundy face scarf pulled down under the chin (faces pass 2026-09-28: it used to hide the lower face; a patch of a
## sphere slightly larger than the face, its top edge peaked at the front), wrapping round into the hood.
static func _mask_point(u: float, v: float) -> Vector3:
	const R := 0.198
	var a := lerpf(-1.9, 1.9, u)
	var y_top := 1.385 + 0.03 * pow(maxf(0.0, cos(a)), 8.0)   # pulled down under the lips (faces pass)
	var th_top := acos(clampf((y_top - FACE_C.y) / R, -1.0, 1.0))
	var th := lerpf(th_top, 2.55, v)
	return FACE_C + R * Vector3(sin(th) * sin(a), cos(th), sin(th) * cos(a))


## Hood shell, the burgundy face scarf with a bandana point and the golden braid down the left of the chest (burgundy
## wrap, tuft). The face itself (skin, eyes, lips, fringe) is the FaceKit Face node (faces pass 2026-09-28).
static func _head_mesh() -> ArrayMesh:
	if _meshes.has("cc_head"):
		return _meshes["cc_head"]
	var braid_pts: Array[Vector3] = [Vector3(-0.11, 1.41, 0.20), Vector3(-0.15, 1.30, 0.25), Vector3(-0.165, 1.18, 0.262),
		Vector3(-0.16, 1.07, 0.252), Vector3(-0.155, 0.99, 0.237)]
	var braid := _tube(braid_pts, func(v: float) -> float: return 0.047 * (0.72 + 0.28 * absf(sin(v * PI * 6.0))), 5, 12)
	var end := braid_pts[4]
	var mask := _grid(func(u: float, v: float) -> Vector3: return _mask_point(u, v),
			func(_u: float, _v: float) -> Vector3: return FACE_C, 12, 3)
	var m := _bake("cc_head", [
		[[_at(sphere(0.25, 12, 7), Vector3(0, 1.53, -0.02), Vector3.ZERO, Vector3(1.0, 1.08, 1.12)),
			_at(torus(0.14, 0.18, 14), Vector3(0, 1.472, 0.205), Vector3(104, 0, 0), Vector3(1.0, 1.0, 1.15))], _mat(&"charcoal")],
		[[[mask, Transform3D()], _at(prism(Vector3(0.22, 0.13, 0.03)), Vector3(0, 1.315, 0.225), Vector3(-18, 0, 180)),
			_seg(end + Vector3(0, 0.02, 0), end + Vector3(0, -0.035, 0), 0.043, 0.043, 8)], _mat(&"burgundy")],
		[[[braid, Transform3D()], _seg(end + Vector3(0, -0.03, 0), end + Vector3(0.005, -0.12, 0.0), 0.045, 0.0, 8)],
			_mat(&"brass")]])
	return m


## The hood's long tail (liripipe) streaming back over the left shoulder blade and down toward the sack, a brass ring
## and a burgundy tassel at the tip. Relative to TAIL_AT (its own node).
static func _tail_mesh() -> ArrayMesh:
	if _meshes.has("cc_tail"):
		return _meshes["cc_tail"]
	var pts: Array[Vector3] = [Vector3(0.0, 1.70, -0.10), Vector3(-0.02, 1.68, -0.27), Vector3(-0.10, 1.57, -0.39),
		Vector3(-0.22, 1.40, -0.42), Vector3(-0.31, 1.21, -0.36), Vector3(-0.36, 1.03, -0.27)]
	for i: int in pts.size():
		pts[i] -= TAIL_AT
	var tube := _tube(pts, func(v: float) -> float: return lerpf(0.13, 0.026, pow(v, 0.8)), 6, 10)   # was 7 x 12 (faces pass trim)
	var tip := pts[5]
	var dir := (pts[5] - pts[4]).normalized()
	var m := _bake("cc_tail", [
		[[[tube, Transform3D()]], _mat(&"charcoal")],
		[[_seg(tip - dir * 0.02, tip + dir * 0.04, 0.038, 0.038, 8)], _mat(&"brass")],
		[[_seg(tip + dir * 0.04, tip + dir * 0.17, 0.055, 0.0, 8)], _mat(&"burgundy")]])
	return m


## Silas's forked golden beard (variant B): a mass under the scarf, two braided forks, brass-bead tips.
static func _beard_mesh() -> ArrayMesh:
	if _meshes.has("cc_beard"):
		return _meshes["cc_beard"]
	var parts: Array = [_at(sphere(0.10, 8, 4), Vector3(0, 1.335, 0.215), Vector3.ZERO, Vector3(1.2, 0.8, 0.8))]
	for s: float in [-1.0, 1.0]:
		var fork: Array[Vector3] = [Vector3(0.035 * s, 1.31, 0.25), Vector3(0.05 * s, 1.21, 0.285), Vector3(0.06 * s, 1.10, 0.295)]
		parts.append([_tube(fork, func(v: float) -> float: return lerpf(0.055, 0.02, v) * (0.8 + 0.2 * absf(sin(v * PI * 3.0))), 5, 5),
				Transform3D()])
	var m := _bake("cc_beard", [[parts, _mat(&"brass")]])
	return m

## Knife frame at the fist: +Y along the blade, +X the flat (turned up so the crescent reads from the camera).
static func _knife_xf(hand: Vector3, axis: Vector3) -> Transform3D:
	var y := axis.normalized()
	var x := (Vector3.UP - y * Vector3.UP.dot(y)).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x, y, z), hand + y * KNIFE_OFF)


## Crescent blade in its own frame (+Y along, curving toward +Z, edge on the inner side), diamond section: a thick
## spine, a ridge, a sharp edge. Three strips (top face, bottom face, spine), 64 vertices.
static func _blade_row(s: float) -> Array[Vector3]:
	const W := 0.14
	const T := 0.034
	const BEND := 0.10
	var c := Vector3(0.0, BLADE_LEN * s, BEND * s * s)
	var n := Vector3(0.0, -2.0 * BEND * s, BLADE_LEN).normalized()
	var w := maxf(W * (1.0 - pow(s, 2.2)) * (0.72 + 0.45 * sin(PI * s)), 0.006)
	var th := maxf(T * pow(1.0 - s, 0.5) * 0.5, 0.002)
	var sp := c - n * 0.3 * w
	var rg := c + n * 0.12 * w
	return [sp + Vector3(th, 0, 0), rg + Vector3(th * 0.8, 0, 0), c + n * 0.7 * w, rg - Vector3(th * 0.8, 0, 0),
		sp - Vector3(th, 0, 0), c]


static func _blade_mesh() -> ArrayMesh:
	if _meshes.has("cc_blade"):
		return _meshes["cc_blade"]
	const ST := 7
	var centre := func(_u: float, v: float) -> Vector3:
		return _blade_row(v)[5]
	var face := func(u: float, v: float, a: int, b: int, c: int) -> Vector3:
		var r := _blade_row(v)
		return r[a].lerp(r[b], u * 2.0) if u <= 0.5 else r[b].lerp(r[c], u * 2.0 - 1.0)
	var top := _grid(func(u: float, v: float) -> Vector3: return face.call(u, v, 0, 1, 2), centre, 2, ST)
	var bot := _grid(func(u: float, v: float) -> Vector3: return face.call(u, v, 4, 3, 2), centre, 2, ST)
	var spine := _grid(func(u: float, v: float) -> Vector3: return _blade_row(v)[0].lerp(_blade_row(v)[4], u), centre, 1, ST)
	var m := _mesh_of([[top, Transform3D()], [bot, Transform3D()], [spine, Transform3D()]])
	_meshes["cc_blade"] = m
	return m


static func _mesh_of(parts: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays(parts))
	return am

## Flat-shaded triangle whose front faces away from `inside`.
static func _tri(verts: PackedVector3Array, norms: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var fn := (c - a).cross(b - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot((a + b + c) / 3.0 - inside) < 0.0:
		var t := b
		b = c
		c = t
		fn = -fn
	fn = fn.normalized()
	verts.append_array(PackedVector3Array([a, b, c]))
	norms.append_array(PackedVector3Array([fn, fn, fn]))


## Arm (G-C): a shaped charcoal sleeve (shoulder -> bicep -> bent elbow -> forearm; was one straight can), the
## shoulder and glove balls, a flared burgundy bracer.
static func _arm_mesh(side: float) -> ArrayMesh:
	var key := "cc_arm%d" % int(side)
	if _meshes.has(key):
		return _meshes[key]
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var hand := HAND_R if side > 0.0 else HAND_L
	var d := hand - sh
	var bracer_c := sh + d * 0.74
	var el := sh.lerp(hand, 0.48) + Vector3(0.012 * side, 0.0, -0.02)
	var sleeve := ChampionShapes.begin()
	ChampionShapes.tube(sleeve, PackedVector3Array([sh, sh.lerp(el, 0.5), el, el.lerp(hand, 0.5), hand]),
		PackedFloat32Array([0.078, 0.083, 0.068, 0.074, 0.068]), 7, false)
	var charcoal: Array = [[ChampionShapes.commit(sleeve), Transform3D.IDENTITY],
		_at(sphere(0.09, 8, 4), sh + Vector3(0.0, 0.01, 0.0)), _at(sphere(0.096, 8, 5), hand)]
	var dn := d.normalized()
	var br := ChampionShapes.begin()
	ChampionShapes.tube(br, PackedVector3Array([bracer_c + dn * 0.08, bracer_c, bracer_c - dn * 0.075]),
		PackedFloat32Array([0.092, 0.094, 0.084]), 8, true)
	# (no brass here: brass in the arm merges is the sign of the archetype knives, test_11_v4)
	return _bake(key, [[charcoal, _mat(&"charcoal")], [[[ChampionShapes.commit(br), Transform3D.IDENTITY]], _mat(&"burgundy")]])


## The crescent knife in the fist (right: forward grip, blade up and forward; left: reverse grip, blade trailing back
## past the elbow): charcoal grip, brass blade, guard and pommel. The archetype weapon (hidden with a class).
static func _knife_mesh(side: float) -> ArrayMesh:
	var key := "cc_knife%d" % int(side)
	if _meshes.has(key):
		return _meshes[key]
	var hand := HAND_R if side > 0.0 else HAND_L
	var axis := KNIFE_R_AXIS if side > 0.0 else KNIFE_L_AXIS
	var kx := _knife_xf(hand, axis)
	var ky := kx.basis.y
	var brass: Array = [[_blade_mesh(), kx], [_disc(0.056, 0.024, 8), Transform3D(kx.basis, kx.origin)],
		_at(sphere(0.034, 6, 3), kx.origin - ky * 0.175)]
	return _bake(key, [[[_seg(kx.origin - ky * 0.16, kx.origin, 0.026, 0.026, 6)], _mat(&"charcoal")],
		[brass, _mat(&"brass")]])


static func _pouch_mesh() -> ArrayMesh:
	if _meshes.has("cc_pouch"):
		return _meshes["cc_pouch"]
	return _bake("cc_pouch", [
		[[_at(sphere(0.075, 8, 4), Vector3(0, -0.02, 0), Vector3.ZERO, Vector3(1.0, 0.9, 1.0)),
			_seg(Vector3(0, 0.04, 0), Vector3(0, 0.09, 0), 0.03, 0.05, 6)], _mat(&"burgundy")],
		[[_at(torus(0.026, 0.042, 6), Vector3(0, 0.045, 0))], _mat(&"brass")]])


# ================================================================ animation

static func _kf(t: float, ts: Array[float], vs: Array[float]) -> float:
	var n := ts.size()
	if t <= ts[0]:
		return vs[0]
	for i: int in range(1, n):
		if t < ts[i]:
			var f := (t - ts[i - 1]) / maxf(ts[i] - ts[i - 1], 0.0001)
			return lerpf(vs[i - 1], vs[i], f * f * (3.0 - 2.0 * f))
	return vs[n - 1]


## _kf for the untyped value rows of the class tables (CP_CLASS...).
static func _kv(t: float, ts: Array[float], vs: Array) -> float:
	var n := ts.size()
	if t <= ts[0]:
		return float(vs[0])
	for i: int in range(1, n):
		if t < ts[i]:
			var f := (t - ts[i - 1]) / maxf(ts[i] - ts[i - 1], 0.0001)
			return lerpf(float(vs[i - 1]), float(vs[i]), f * f * (3.0 - 2.0 * f))
	return float(vs[n - 1])


## `slash2`: right forehand cut (strike 0.08 s), then the left reverse-grip backhand; 0.42 s. Other styles: the kit.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"slash2":
		return super(prev, t)
	rot(P_ARM_R, Vector3(_kf(t, SL_R_T, SL_R_X) * DEG, 0.0, _kf(t, SL_R_T, SL_R_Z) * DEG))
	rot(P_ARM_L, Vector3(_kf(t, SL_L_T, SL_L_X) * DEG, 0.0, _kf(t, SL_L_T, SL_L_Z) * DEG))
	rot(P_CHEST, Vector3(8.0 * DEG * _k3(t, 0.0, 0.08, 0.20, 0.42, 1.0, 1.0), _kf(t, SL_C_T, SL_C_Y) * DEG, 0.0))
	pos(P_ROOT, Vector3(0.0, _kf(t, SL_B_T, SL_B_Y), _kf(t, SL_B_T, SL_B_Z)))
	rot(P_LEG_R, Vector3(_kf(t, SL_B_T, SL_LR) * DEG, 0.0, 0.0))
	rot(P_LEG_L, Vector3(_kf(t, SL_B_T, SL_LL) * DEG, 0.0, 0.0))
	_eye_k = maxf(_eye_k, 1.0 + 0.5 * _k3(t, 0.0, 0.08, 0.2, 0.42, 1.0, 1.0))
	if prev < 0.08 and t >= 0.08:
		_on_action_event(&"release")
	return t < 0.42


func _pose_cast(spell: StringName, t: float) -> float:
	var wc := weapon_class()
	match spell:
		&"smoke_pouch":
			rot(P_ARM_L, Vector3(_kf(t, SP_T, SP_LX) * DEG, 0.0, _kf(t, SP_T, SP_LZ) * DEG))
			if SP_CLASS.has(wc):
				var sp: Array = SP_CLASS[wc]
				rot(P_ARM_R, Vector3(_kv(t, SP_T, sp[0]) * DEG, 0.0, _kv(t, SP_T, sp[1]) * DEG))
				if wc == &"wizard":
					weapon_flare(_k3(t, 0.28, 0.35, 0.42, 0.72, 1.0, 1.0))
			else:
				rot(P_ARM_R, Vector3(_kf(t, SP_T, SP_RX) * DEG, 0.0, _kf(t, SP_T, SP_RZ) * DEG))
			rot(P_CHEST, Vector3(_kf(t, SP_T, SP_CX) * DEG, _kf(t, SP_T, SP_CY) * DEG, 0.0))
			rot(P_HEAD, Vector3(_kf(t, SP_T, SP_HX) * DEG, 0.0, 0.0))
			pos(P_ROOT, Vector3(0.0, _kf(t, SP_T, SP_BY), 0.0))
			rot(P_LEG_L, Vector3(_kf(t, SP_T, SP_GL) * DEG, 0.0, 0.0))
			rot(P_LEG_R, Vector3(_kf(t, SP_T, SP_GR) * DEG, 0.0, 0.0))
			_pouch.visible = t >= 0.10 and t < 0.35
			_belt_k = maxf(_belt_k, 1.0 + 0.8 * _k3(t, 0.0, 0.1, 0.14, 0.3, 1.0, 1.0))
			return 0.72
		&"marked_for_coin":
			if wc == &"sword_shield":
				rot(P_ARM_L, Vector3(_kf(t, MK_T, MK_SS_LX) * DEG, 0.0, _kf(t, MK_T, MK_SS_LZ) * DEG))
			else:
				rot(P_ARM_L, Vector3(_kf(t, MK_T, MK_LX) * DEG, 0.0, _kf(t, MK_T, MK_LZ) * DEG))
			if MK_CLASS.has(wc):
				var mk: Array = MK_CLASS[wc]
				rot(P_ARM_R, Vector3(_kv(t, MK_T, mk[0]) * DEG, 0.0, _kv(t, MK_T, mk[1]) * DEG))
			else:
				rot(P_ARM_R, Vector3(_kf(t, MK_T, MK_RX) * DEG, 0.0, 0.0))
			rot(P_CHEST, Vector3(_kf(t, MK_T, MK_CX) * DEG, _kf(t, MK_T, MK_CY) * DEG, 0.0))
			rot(P_HEAD, Vector3(_kf(t, MK_T, MK_HX) * DEG, 0.0, 0.0))
			var point := _k3(t, 0.70, 0.78, 0.90, 1.05, 1.0, 1.0)
			_eye_k = maxf(_eye_k, 1.0 + 1.3 * point)
			if wc == &"wizard":
				weapon_flare(point)
			_coin_pose(t, 0.05, 0.18, 0.72, 0.98, 0.85, 5.0, 1.0 + 2.0 * point)
			if not _fx_fired and t >= 0.72:
				_fx_fired = true
				_burst(to_global(_coin.position))
			return 1.05
		&"idle_flip":
			if _speed >= 0.3:
				return 0.0
			rot(P_ARM_L, Vector3(_kf(t, IF_T, IF_LX) * DEG, 0.0, _kf(t, IF_T, IF_LZ) * DEG))
			rot(P_HEAD, Vector3(_kf(t, IF_T, IF_HX) * DEG, 0.0, 0.0))
			_coin_pose(t, 0.12, 0.30, 0.95, 1.20, 0.6, 3.0, 1.0)
			return 1.4
		&"idle_weigh":
			if _speed >= 0.3:
				return 0.0
			rot(P_ARM_L, Vector3(_kf(t, IW_T, IW_LX) * DEG, 0.0, _kf(t, IW_T, IW_LZ) * DEG))
			rot(P_HEAD, Vector3(_kf(t, IW_T, IW_HX) * DEG, _kf(t, IW_T, IW_HY) * DEG, 0.0))
			rot(P_CHEST, Vector3(0.0, _kf(t, IW_T, IW_CY) * DEG, 0.0))
			_sack_lift = _kf(t, IW_T, IW_LIFT)
			_belt_k = maxf(_belt_k, 1.0 + 0.6 * _k3(t, 0.5, 0.6, 1.1, 1.4, 1.0, 1.0))
			return 1.5
		_:  # cutpurse (and unknown ids): coil, then a deep lunge-stab; a gold glint at the knife / weapon tip.
			if CP_CLASS.has(wc):
				var cp: Array = CP_CLASS[wc]
				rot(P_ARM_R, Vector3(_kv(t, CP_T, cp[0]) * DEG, 0.0, _kv(t, CP_T, cp[1]) * DEG))
				pos(P_ARM_R, Vector3(0.0, 0.0, _kv(t, CP_T, cp[2])))
				rot(P_ARM_L, Vector3(_kv(t, CP_T, cp[3]) * DEG, 0.0, _kv(t, CP_T, cp[4]) * DEG))
				if wc == &"wizard":
					weapon_flare(_k3(t, 0.10, 0.21, 0.26, 0.45, 1.0, 1.0))
			else:
				rot(P_ARM_R, Vector3(_kf(t, CP_T, CP_RX) * DEG, 0.0, _kf(t, CP_T, CP_RZ) * DEG))
				rot(P_ARM_L, Vector3(_kf(t, CP_T, CP_LX) * DEG, 0.0, _kf(t, CP_T, CP_LZ) * DEG))
			rot(P_CHEST, Vector3(_kf(t, CP_T, CP_CX) * DEG, _kf(t, CP_T, CP_CY) * DEG, 0.0))
			rot(P_HEAD, Vector3(_kf(t, CP_T, CP_HX) * DEG, 0.0, 0.0))
			pos(P_ROOT, Vector3(0.0, _kf(t, CP_T, CP_BY), _kf(t, CP_T, CP_BZ)))
			rot(P_LEG_R, Vector3(_kf(t, CP_T, CP_GR) * DEG, 0.0, 0.0))
			rot(P_LEG_L, Vector3(_kf(t, CP_T, CP_GL) * DEG, 0.0, 0.0))
			var hit := _k3(t, 0.16, 0.22, 0.30, 0.55, 1.0, 1.0)
			_belt_k = maxf(_belt_k, 1.0 + 1.5 * hit)
			_eye_k = maxf(_eye_k, 1.0 + 0.8 * hit)
			if not _fx_fired and t >= 0.21:
				_fx_fired = true
				var rest_tip := _knife_xf(HAND_R, KNIFE_R_AXIS) * Vector3(0, BLADE_LEN * 0.85, 0.06)
				var pieces := weapon_pieces()
				if wc != &"" and not pieces.is_empty():
					rest_tip = weapon_grip_xf(pieces[0]) * WEAPON_KIT.piece_tip(pieces[0])
				_burst(to_global(_model_xf(P_ARM_R) * (rest_tip - _arm_rest(P_ARM_R))))
			return 0.62


## The flipped coin: in the left hand from t_show, thrown at t_up, back in the hand at t_down (apex `apex` m,
## `turns` spins), hidden at t_hide. boost_catch = its glow after the catch.
func _coin_pose(t: float, t_show: float, t_up: float, t_down: float, t_hide: float, apex: float, turns: float,
		boost_catch: float) -> void:
	if t < t_show or t >= t_hide:
		_coin.visible = false
		return
	_coin.visible = true
	var hand := _model_xf(P_ARM_L) * (HAND_L + Vector3(0.0, 0.085, 0.07) - _arm_rest(P_ARM_L))
	var h := 0.0
	var spin := 0.0
	var boost := 1.2
	if t >= t_up and t < t_down:
		var f := (t - t_up) / (t_down - t_up)
		h = 4.0 * apex * f * (1.0 - f)
		spin = TAU * turns * f
		boost = 1.8
	elif t >= t_down:
		boost = boost_catch
	_coin.position = hand + Vector3(0.0, h, 0.0)
	_coin.rotation = Vector3(PI * 0.5 + spin, 0.0, 0.0)
	var g := glow_level() * boost
	if g != _coin_written:
		_coin_written = g
		_coin.set_instance_shader_parameter(&"glow_boost", g)


## Rest (model-space) origin of an arm pivot.
func _arm_rest(i: int) -> Vector3:
	return _rest_pos[P_ROOT] + _rest_pos[P_CHEST] + _rest_pos[i]


## Model-space transform of an arm pivot for THIS frame's pose (rest + offsets), without waiting for _apply().
func _model_xf(i: int) -> Transform3D:
	var root := Transform3D(Basis.from_euler(_rest_rot[P_ROOT] + _off_rot[P_ROOT]).scaled(_root_scale),
			_rest_pos[P_ROOT] + _off_pos[P_ROOT])
	var ch := Transform3D(Basis.from_euler(_rest_rot[P_CHEST] + _off_rot[P_CHEST]), _rest_pos[P_CHEST] + _off_pos[P_CHEST])
	return root * ch * Transform3D(Basis.from_euler(_rest_rot[i] + _off_rot[i]), _rest_pos[i] + _off_pos[i])


func _burst(at: Vector3) -> void:
	if _sparks == null or not _sparks.is_inside_tree():
		return
	_sparks.global_position = at
	_sparks.restart()


func _on_action_event(ev: StringName) -> void:
	if _coin == null:
		return
	match ev:
		&"cast_start":
			_fx_fired = false
			_fx2_fired = false
			_coin.visible = false
			_pouch.visible = false
		&"cast_end":
			_coin.visible = false
			_pouch.visible = false
		&"level_up":
			_fx2_fired = false
		&"death_glow_off":
			_coin.visible = false
			_pouch.visible = false
			_burst(_sack.global_transform * Vector3(-0.12, -0.2, -0.04))
			_sack_v += Vector3(-3.0, 0.4, 2.0)


func _is_full() -> bool:
	return _dead or _action != &"" or _hit_t < HIT_LEN or _level_t < LEVEL_LEN or _walk_w > 0.0 \
		or _speed >= 0.3 or _force_write or _flash_v != 0.0


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	var full := _is_full()
	if full and not _dead:
		_body_extras()
	elif _dead:
		var g := _k3(_death_t, 0.0, 0.2, 0.3, 0.6, 1.0, 1.0)
		rot(P_HEAD, Vector3(-18.0 * DEG * g, 0.0, 0.0))
		rot(P_ARM_L, Vector3(-40.0 * DEG * g, 0.0, -30.0 * DEG * g))
	if _action != &"cast" and _level_t >= LEVEL_LEN and _coin.visible:
		_coin.visible = false
	# Idle fidgets: close camera only (tier 0), every 8-14 s.
	if not _dead and _tier == 0 and _action == &"" and _speed < 0.3 and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN:
		_idle_left -= dt
		if _idle_left <= 0.0:
			_idle_left = 8.0 + 6.0 * fmod(_phase_off * 7.3 + float(_idle_i) * 0.37, 1.0)
			# with the round shield on the left arm the coin flip would hide the face: weigh the sack instead
			play_cast(&"idle_weigh" if weapon_class() == &"sword_shield" else IDLE_IDS[_idle_i % IDLE_IDS.size()])
			_idle_i += 1
	elif _action != &"" or _speed >= 0.3:
		_idle_left = maxf(_idle_left, 3.0)
	_secondary(dt, full)
	_drive_glows()
	_belt_k = 1.0
	_eye_k = 1.0
	_sack_lift = 0.0


## Offsets on top of the kit's walk / hit / level-up (only on frames the kit applies them).
func _body_extras() -> void:
	if _walk_w > 0.0:
		# A low prowl: leaning in, eyes level, the forward knife kept up.
		var sw := sin(TAU * _walk_p) * _walk_w
		rot(P_CHEST, Vector3(7.0 * DEG * _walk_w, -4.0 * DEG * sw, 0.0))
		rot(P_HEAD, Vector3(-6.0 * DEG * _walk_w, 3.0 * DEG * sw, 0.0))
		rot(P_ARM_R, Vector3(-14.0 * DEG * _walk_w, 0.0, 0.0))
		rot(P_ARM_L, Vector3(-6.0 * DEG * _walk_w, 0.0, 0.0))
	if _hit_t < HIT_LEN:
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		rot(P_HEAD, Vector3(-12.0 * DEG * k, 0.0, 8.0 * DEG * k))
		rot(P_ARM_L, Vector3(-25.0 * DEG * k, 0.0, -10.0 * DEG * k))
	if _level_t < LEVEL_LEN:
		# Level-up: flips a coin high off the thumb, the belt blazes, a burst of gold.
		var u := clampf(_level_t / LEVEL_LEN, 0.0, 1.0)
		rot(P_ARM_L, Vector3(-70.0 * DEG * sin(PI * u), 0.0, 15.0 * DEG * sin(PI * u)))
		_belt_k = maxf(_belt_k, 1.0 + 1.8 * sin(PI * u))
		_eye_k = maxf(_eye_k, 1.0 + 1.0 * sin(PI * u))
		if _action != &"cast":
			_coin_pose(_level_t, 0.0, 0.03, 0.38, 0.40, 0.55, 3.0, 2.0)
		if not _fx2_fired and _level_t >= 0.08:
			_fx2_fired = true
			_burst(to_global(_model_xf(P_ARM_L) * (HAND_L - _arm_rest(P_ARM_L)) + Vector3(0, 0.4, 0)))


## Hood tail and loot sack: damped springs driven by the walk, lunges (root speed), chest twists and hits.
func _secondary(dt: float, full: bool) -> void:
	if _tail == null or _sack == null:
		return
	var tt := Vector2.ZERO
	var st := Vector3(0.0, _sack_lift, 0.0)
	if full and dt > 0.0:
		var rz := _off_pos[P_ROOT].z
		var vz := (rz - _prev_root_z) / dt
		_prev_root_z = rz
		var yaw := _off_rot[P_CHEST].y
		var vyaw := (yaw - _prev_yaw) / dt
		_prev_yaw = yaw
		var p := TAU * _walk_p
		tt.x = _walk_w * (10.0 + 6.0 * sin(2.0 * p)) * DEG + clampf(vz * 0.5, -0.5, 0.9) \
			- 0.6 * (_off_rot[P_CHEST].x + _off_rot[P_HEAD].x)
		tt.y = _walk_w * 5.0 * DEG * sin(p) - clampf(vyaw * 0.06, -0.5, 0.5)
		st.x = clampf(vz * 0.45, -0.4, 0.7)
		st.y += -0.03 * absf(sin(p)) * _walk_w
		st.z = -_walk_w * 9.0 * DEG * sin(p) - clampf(vyaw * 0.04, -0.3, 0.3)
		if _dead:
			tt.x -= 0.9 * clampf((_death_t - 0.25) / 0.4, 0.0, 1.0)
	else:
		_prev_root_z = _off_pos[P_ROOT].z if full else 0.0
		_prev_yaw = _off_rot[P_CHEST].y if full else 0.0
	var h := minf(dt, 0.05)
	var steps := 1 if h <= 0.02 else 2
	var sdt := h / float(steps)
	for _s: int in steps:
		_tail_v += ((tt - _tail_a) * 90.0 - _tail_v * 9.0) * sdt
		_tail_a += _tail_v * sdt
		_sack_v += ((st - _sack_a) * Vector3(80.0, 140.0, 80.0) - _sack_v * Vector3(7.0, 10.0, 7.0)) * sdt
		_sack_a += _sack_v * sdt
	if _tail_a.distance_squared_to(_tail_written) > 0.000004:
		_tail_written = _tail_a
		_tail.rotation = Vector3(_tail_a.x, 0.0, _tail_a.y)
	if _sack_a.distance_squared_to(_sack_written) > 0.000004:
		_sack_written = _sack_a
		_sack.rotation = Vector3(_sack_a.x, 0.0, _sack_a.z)
		_sack.position = _sack_rest + Vector3(0.0, _sack_a.y, 0.0)


## Coin belt (merged Hips) and eye bar (merged Head) glows: veterancy / haste x the cast flares.
func _drive_glows() -> void:
	var g := glow_level()
	var b := g * _belt_k
	if _belt_glow and b != _belt_written:
		_belt_written = b
		_belt_glow.set_instance_shader_parameter(&"glow_boost", b)
	var e := g * _eye_k
	if _eye_glow and e != _eye_written:
		_eye_written = e
		_eye_glow.set_instance_shader_parameter(&"glow_boost", e)


func _on_revive() -> void:
	if _face:
		_face.reset()
	_tail_a = Vector2.ZERO
	_tail_v = Vector2.ZERO
	_sack_a = Vector3.ZERO
	_sack_v = Vector3.ZERO
	_tail_written = Vector2(99, 99)
	_sack_written = Vector3(99, 99, 99)
	_belt_written = -1.0
	_eye_written = -1.0
	_coin_written = -1.0
	_coin.visible = false
	_pouch.visible = false


## Translation-only transform (G-C helpers).
static func _xf3(p: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, p)
