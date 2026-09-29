extends CharacterModel
## The Oathwall champion (champions.md 4.6, task 9.V2): Garran / Gerda Stoneward, the Guardian. 2.0 m, radius 0.6.
## A square iron-clad wall of a man behind a DOOR-SIZED riveted oak shield (1.2 x 1.6 m, three planks, iron rim, two
## riveted straps, an iron boss with a glowing steel-blue OATH RUNE: a ring, four rays and a keyhole bar) in ArmL,
## a short war hammer (flat striking face + back spike) in ArmR, a square great helm under a FLAT overhanging lid with
## an open face window (faces pass 2026-09-28: was a glowing visor slit; FaceKit face, steel-blue glowing irises), a
## padded roll collar.
## Palette (4.6): iron, oak (shield boards, trousers, haft, Garran's beard), padded cloth (gambeson, Gerda's braids).
## Glow (1.5): rune + the irises (Face node, the old visor glow), steel-blue.
## Team colour ONLY on the waist sash (band, knot, two tails) and the back cape: both use `oathwall_cape`, the one
## material `set_team_color` swaps (kit cache per colour; matching `kingdom_color` restores the authored one).
## Variant B (Gerda) = ONE toggled node, `Root/Chest/Head/Variant`: its mesh swaps Garran's forked beard (A) for
## Gerda's two flaxen braids (B). `set_variant(v)` works before or after _ready.
## Read at 40 m (black test): a square block, a tall door on its left side reaching the ground, a flat lid on top.
## Hooks (kit): walk / idle / hit / death (`fall`, the shield topples aside) / level-up; attack `slam` (hammer
## overhead, slams the ground in front; strike 0.12 s); `play_cast(ability_id)`: `oath_of_iron` (hammer raised to
## the sky, shield shoved forward, stomp, rune flare), `shield_bash` (shove + step stomp), `bulwark_stand` (shield
## PLANTED in the ground, knees braced, hammer cocked; held 6 s until the next animation: an attack, another cast,
## a death or walking ends it). Unknown ids play oath_of_iron. Idle fidget (< 30 m): lifts the shield and thumps it
## down, rolls the neck. Budget: 25 authored meshes (blob incl.), 10 draw instances + 2 one-shot emitters (11
## nodes, one door hidden), 5 materials, 0 lights, ~2 470 vertices. Preview / pose tools: tools/oathwall_preview.gd,
## tools/oathwall_pose_check.gd, tools/oathwall_classes_preview.gd (task 11.V3).
##
## Champion classes (task 11.V3, skills-rework.md 5; kit convention: docs/handoff/for-tech-artist.md "11.V1"):
## - The hammer (haft + head, ArmR) is the archetype weapon (`mark_archetype_weapon`): gone with any class.
## - The DOOR shield is one keep_separate node per place, both tagged: `DoorShield` in ArmL for `""`, `spear`,
##   `sword_shield`; `DoorBack` slung on the Chest (rune outward, a leather strap across the cuirass, a left
##   gauntlet on the freed hand) for `two_hand`, `wizard`. The kit shows / hides them per class; the poses only MOVE
##   them (never toggle `visible`): Shield Bash / Bulwark Stand swing `DoorBack` off the back into the left hand and
##   back; the Hobbling Javelin plants `DoorShield` on the ground while the left hand throws; Shield Throw flings
##   `DoorShield` flat (it shrinks away into the ChampionVfx shield at 0.28-0.40 and comes back 0.80-0.88).
## - Sword and Shield holds only the kit's sword (`_weapon_pieces`): he keeps his own door, never the round shield.
## - Grips: hand_r = FIST_R (the gauntlet), hand_l = FIST_L (the javelin fist behind the door); back = kit default.
## - Oath of Iron raises the class weapon (per grip family); Bulwark cocks it; the door-in-hand classes keep the door
##   braced in front in the kit's spear_thrust / sword_slash and in Lunge / Skewer / Riposte (own versions).
## - The slam dust (release) only plays with the hammer (`weapon_class() == &""`).

const OWN_DIR := "res://art/units/champions/oathwall/materials/"
## Shield (ArmL): centre in model space, tilt (top 6 deg back toward the body) and yaw (face turned 38 deg outward,
## so the body shows beside the door; the casts swing it square to the front).
const SHIELD_C := Vector3(-0.56, 0.94, 0.36)
const SHIELD_ROT := Vector3(-6.0, -38.0, 0.0)
const SHIELD_SIZE := Vector2(1.2, 1.6)
## Hammer (ArmR): fist, haft direction (40 deg forward of straight down), head distance along the haft.
const FIST_R := Vector3(0.64, 1.00, 0.20)
const HAFT_DIR := Vector3(0.0, -0.766, 0.643)
const HEAD_AT := 0.84
## Attack `slam` timeline (s): overhead at SLAM_UP, ground at SLAM_HIT (the strike frame), held to SLAM_HOLD.
const SLAM_UP := 0.07
const SLAM_HIT := 0.12
const SLAM_HOLD := 0.22
const SLAM_LEN := 0.62
## Bulwark Stand: raised, planted, held, recovered.
const BW_UP := 0.30
const BW_PLANT := 0.42
const BW_HOLD := 6.0
const BW_END := 6.5
## Fx anchors (model space, rest pose): slam impact, stomp feet, planted shield bottom, shield face.
const FX_SLAM := Vector3(0.40, 0.05, 1.22)
const FX_FOOT_R := Vector3(0.24, 0.04, 0.30)
const FX_FOOT_L := Vector3(-0.24, 0.04, 0.50)
const FX_PLANT := Vector3(-0.07, 0.04, 0.72)
const FX_SHIELD := Vector3(-0.62, 1.10, 0.52)
const FX_BOSS := Vector3(-0.30, 0.95, 0.95)
const RUNE_COLOR := Color(0.6, 0.85, 1.0)
## Class weapons (11.V3): the free left fist (behind the door; the javelin grip, the gauntlet of the back classes).
const FIST_L := Vector3(-0.48, 1.00, 0.24)
## The door slung on the back (Two-Hand, Wizard): centre, rotation (face outward, top leaning on the shoulders).
const DOOR_BACK_C := Vector3(0.0, 1.16, -0.60)
const DOOR_BACK_ROT := Vector3(-6.0, 180.0, 0.0)
## Hobbling Javelin (Spear): the door stood on the ground in front-left while the left hand throws (model space).
const DOOR_PLANT_C := Vector3(-0.44, 0.80, 0.74)
const DOOR_PLANT_ROT := Vector3(-8.0, -20.0, 0.0)
## Shield Throw: the door leaves the hand at 0.28, is gone at 0.40, comes back at 0.80 and is caught at 0.88.
const THROW_OUT := 0.28
const THROW_GONE := 0.40
const THROW_BACK := 0.80
const THROW_CATCH := 0.88
## Classes that sling the door on the back.
const BACK_CLASSES: Array[StringName] = [&"two_hand", &"wizard"]
enum { DM_NONE, DM_BACK_TO_HAND, DM_PLANT, DM_FLY }
## Shield Throw keys (s; deg / m): wind across the body, fling flat at 0.28, follow through, catch at 0.88.
const _SHT_T: Array[float] = [0.0, 0.18, 0.28, 0.40, 0.84, 0.92, 1.10]
const _SHT_LX: Array[float] = [0.0, -40.0, -80.0, -60.0, -30.0, -60.0, 0.0]
const _SHT_LZ: Array[float] = [0.0, 40.0, -50.0, -40.0, 0.0, -10.0, 0.0]
const _SHT_CY: Array[float] = [0.0, 30.0, -30.0, -26.0, 0.0, -6.0, 0.0]
const _SHT_BY: Array[float] = [0.0, -0.05, -0.02, 0.0, 0.0, -0.04, 0.0]
const _SHT_BZ: Array[float] = [0.0, -0.04, 0.12, 0.10, 0.0, 0.02, 0.0]
const _SHT_GL: Array[float] = [0.0, 4.0, -24.0, -20.0, 0.0, -6.0, 0.0]

## Idle fidget every ~N s (+-40 % per unit) while standing within 30 m; 0 = never.
@export var fidget_every: float = 11.0

static var _own: Dictionary = {}          # material name -> Material, mesh key -> Mesh (shared per process)

var _authored: int = 0
var _variant: int = 0
var _variant_node: MeshInstance3D
var _door_arm: MeshInstance3D               # the door in ArmL ("", spear, sword_shield); its glow surface = the rune
var _door_back: MeshInstance3D              # the door on the back (two_hand, wizard)
var _door_arm_rest: Transform3D             # their authored local transforms
var _door_back_rest: Transform3D
var _door_mode: int = DM_NONE               # this frame's door motion, set by a pose, consumed by _drive_doors
var _door_w: float = 0.0
var _door_target: Transform3D = Transform3D.IDENTITY
var _door_fly: float = 0.0
var _skill_prev: float = 0.0
var _reach_rot: Vector3 = Vector3.ZERO          # this frame's reach-over-the-shoulder rotation of ArmL
var _visor_node: GeometryInstance3D         # the Face node (steel-blue irises: the old visor glow)
## Painted face (FaceKit via ChampionFaces, faces pass 2026-09-28).
var _face: FaceRig
var _dust: GPUParticles3D
var _sparks: GPUParticles3D
var _rune_flare: float = 0.0
var _visor_flare: float = 0.0
var _rune_written: float = -1.0
var _visor_written: float = -1.0
var _cast_prev: float = 0.0
var _fidget_wait: float = 0.0
var _fidget_prev: float = 0.0
var _death_dust: bool = false


# ================================================================ public API (on top of the kit hooks)

## 0 = Garran (forked beard), 1 = Gerda (two braids). Safe before _ready.
func set_variant(v: int) -> void:
	_variant = clampi(v, 0, 1)
	if _variant_node:
		_variant_node.mesh = _braids_mesh() if _variant == 1 else _beard_mesh()
	ChampionFaces.switch(_face, "oathwall", _face_spec, _variant)


## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


const FACE_C := Vector3(0.0, 1.73, 0.06)
const FACE_R := 0.16


## Face styles (FaceKit, faces pass 2026-09-28) in the helm window: a broad weathered face (the face sphere is part of
## the face mesh), steel-blue irises with a faint glow (the old visor), heavy brows. Garran (A): stern, oak-brown brows
## and a thick moustache over his forked beard (the Variant mesh). Gerda (B): a calmer face, flaxen brows and a short
## flaxen fringe under the brow band (her two braids are the Variant mesh).
static func _face_spec(v: int) -> Dictionary:
	var skin := Color(0.95, 0.76, 0.62)   # light: the face sits in the helm's shade
	var hair := Color(0.36, 0.24, 0.12) if v == 0 else Color(0.80, 0.70, 0.46)
	var tip := hair.lightened(0.25)
	var fs := sphere(FACE_R, 12, 6)
	var spec := {"center": FACE_C, "radius": FACE_R, "head_mesh": fs, "preset": &"stern" if v == 0 else &"gentle",
		"skin": skin, "hair": hair, "hair_tip": tip, "eyes": Color(0.55, 0.78, 1.0), "ears": &"none",
		"palette": {"iris_glow": 0.35, "lip": Color(0.72, 0.44, 0.40)},
		"hair_fn": func(acc: Dictionary) -> void:
			FaceKit.put_mesh(acc, fs, Transform3D(Basis.IDENTITY, FACE_C), skin)
			if v == 1:
				ChampionFaces.frame_locks(acc, FACE_C, FACE_R, hair, tip, 0.8, false)}
	if v == 0:
		spec["beard"] = &"moustache"
	return spec


## The great helm with its face window (model space, Head pivot): the back block, two cheek plates and the brow band
## (flat-shaded frustum pieces keeping the old 0.54 x 0.52 -> 0.58 x 0.56 outline, 0.33 high at y 1.765).
static func _helm_mesh() -> Mesh:
	if _own.has("helm"):
		return _own["helm"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# back block: z -0.26 / -0.28 -> +0.09 / +0.10
	_frustum_into(st, _xf(Vector3(0, 1.765, -0.087)), Vector2(0.54, 0.35), Vector2(0.58, 0.38), 0.33, Vector2.ZERO)
	for sx: float in [-1.0, 1.0]:
		# cheek plates (x 0.15 -> 0.27 / 0.29, z 0.09 -> 0.26 / 0.28), full height
		_frustum_into(st, _xf(Vector3(0.212 * sx, 1.765, 0.177)), Vector2(0.124, 0.17), Vector2(0.144, 0.19), 0.33, Vector2.ZERO)
	# brow band over the window (y 1.84 -> 1.93)
	_frustum_into(st, _xf(Vector3(0, 1.885, 0.182)), Vector2(0.30, 0.18), Vector2(0.30, 0.19), 0.09, Vector2.ZERO)
	st.index()
	var m := st.commit()
	_own["helm"] = m
	return m

func get_variant() -> int:
	return _variant


## Kingdom colour of the owner: recolours ONLY the sash and the cape (kit rule 2.2, cached per colour). The authored
## colour (kingdom_color) restores the original material, so a champion can change hands (the kit does both now).
func set_team_color(c: Color) -> void:
	super.set_team_color(c)


## Every MeshInstance3D authored for this model (blob included), before the merge. Budget <= 26.
func authored_mesh_count() -> int:
	return _authored


## Starts the idle fidget now (preview helper; the loop does it by itself every ~fidget_every s within 30 m).
func play_fidget() -> void:
	if not _dead and _action == &"" and _speed < 0.3:
		_action = &"fidget"
		_action_t = 0.0
		_fidget_prev = 0.0


func play_hit() -> void:
	if not _dead and _t - _last_hit_time >= 0.15 and _tier == 0:
		_burst(_sparks, FX_SHIELD if door_in_hand() else Vector3(0.0, 1.35, 0.38))
	super.play_hit()


## True while the door is carried in the left hand (archetype, Spear, Sword and Shield); false = on the back.
func door_in_hand() -> bool:
	return not BACK_CLASSES.has(weapon_class())


## The door node the current class shows (`DoorShield` in ArmL or `DoorBack` on the Chest).
func door_node() -> MeshInstance3D:
	return _door_arm if door_in_hand() else _door_back


## Where bolts and thrown skills start (world space, always a Vector3): the Wizard's staff crystal; with the door in
## hand, the door's face (Shield Throw leaves from it); with the door on the back, a point in front of the chest.
func get_beam_origin() -> Vector3:
	if not is_inside_tree():
		return position + Vector3.UP * body_height * 0.75
	if weapon_class() == &"wizard":
		var tip: Variant = get_weapon_tip()
		if tip is Vector3:
			return tip
	if door_in_hand() and _door_arm and _door_arm.is_inside_tree():
		return _door_arm.global_transform * Vector3(0, 0, 0.12)
	return global_transform * Vector3(0.0, 1.35, 0.45)


func add_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	return super.add_part(pivot, mesh, mat, model_pos, rot_deg, scl, keep_separate, part_name)


# ================================================================ parts

func _build_parts() -> void:
	_authored = 0
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var iron := own(&"oathwall_iron")
	var oak := own(&"oathwall_oak")
	var pad := own(&"oathwall_padding")
	var team := own(&"oathwall_cape")
	# Legs (4): short dark leather trousers (the dark base) + chunky flat-shaded iron sabatons.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		# a plain 8-sided leg (was a 162-vertex capsule; its ends hide in the skirt / sabaton: faces pass trim)
		add_part(leg, cyl(0.15, 0.15, 0.56, 8), oak, Vector3(0.22 * sx, 0.42, 0.0))
		add_part(leg, frustum(Vector2(0.32, 0.46), Vector2(0.26, 0.34), 0.24), iron, Vector3(0.22 * sx, 0.12, 0.06))
	# Hips (2): quilted gambeson skirt + the team sash (band, knot, two tails on the hammer hip).
	add_part(hips, cyl(0.37, 0.47, 0.40, 8), pad, Vector3(0, 0.80, 0), Vector3(0, 22.5, 0))
	add_part(hips, _sash_mesh(), team, Vector3.ZERO)
	# Chest (5): square iron cuirass (flat-shaded, wider at the shoulders), round pauldrons, the team cape, collar.
	add_part(chest, frustum(Vector2(0.64, 0.50), Vector2(0.80, 0.58), 0.66), iron, Vector3(0, 1.25, 0))
	for sx: float in [-1.0, 1.0]:
		add_part(chest, sphere(0.27), iron, Vector3(0.54 * sx, 1.50, 0.0), Vector3.ZERO, Vector3(1.05, 0.72, 1.12))
	add_part(chest, cape(0.84, 1.15), team, Vector3(0, 1.03, -0.41), Vector3(8, 0, 0))
	# Padded roll collar: a light band between the helm and the cuirass (the head reads apart from the body).
	add_part(chest, cyl(0.34, 0.38, 0.11, 8), pad, Vector3(0, 1.605, 0.0), Vector3(0, 22.5, 0))
	# Head (3 + face): square great helm (flat-shaded, a little wider at the top) with an OPEN FACE WINDOW (faces pass
	# 2026-09-28: was a closed box + a glowing visor slit; same outline), the flat bevelled lid overhanging it, the
	# variant; the face in the window is the FaceKit Face node (its steel-blue irises carry the old visor glow).
	add_part(head, _helm_mesh(), iron, Vector3.ZERO)
	add_part(head, frustum(Vector2(0.72, 0.70), Vector2(0.66, 0.64), 0.07), iron, Vector3(0, 1.965, 0))
	_variant_node = add_part(head, _beard_mesh(), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Variant")
	_face = ChampionFaces.attach(self, head, "oathwall", _face_spec, _variant)
	_face.set_meta(&"own_glow", true)   # driven with the old visor flare (_write_glows)
	# ArmL (3): sleeve; the door (ONE keep_separate node, 3 surfaces: iron rim / straps / rivets / boss, three oak
	# planks, the oath rune); a left gauntlet for the classes that sling the door on the back.
	_limb(arm_l, Vector3(-0.58, 1.50, 0.0), Vector3(-0.48, 1.04, 0.22), 0.12, pad)
	_door_arm = add_part(arm_l, _door_mesh(), null, SHIELD_C, SHIELD_ROT, Vector3.ONE, true, "DoorShield")
	mark_weapon_classes(_door_arm, [&"", &"spear", &"sword_shield"])
	mark_weapon_classes(add_part(arm_l, _gauntlet_l_mesh(), iron, Vector3.ZERO), BACK_CLASSES)
	# Chest (+2): the same door slung on the back, and its leather strap across the cuirass (two_hand, wizard).
	_door_back = add_part(chest, _door_mesh(), null, DOOR_BACK_C, DOOR_BACK_ROT, Vector3.ONE, true, "DoorBack")
	mark_weapon_classes(_door_back, BACK_CLASSES)
	mark_weapon_classes(add_part(chest, box(Vector3(0.11, 0.90, 0.04)), oak, Vector3(0.0, 1.27, 0.30),
		Vector3(-4.0, 0.0, -40.0)), BACK_CLASSES)
	# ArmR (4): sleeve, iron gauntlet + cuff, then the archetype weapon: oak haft, forged hammer head (square core,
	# flared striking face, back spike, haft cap).
	_limb(arm_r, Vector3(0.60, 1.48, 0.0), FIST_R + Vector3(0, 0.04, -0.02), 0.13, pad)
	add_part(arm_r, _gauntlet_mesh(), iron, Vector3.ZERO)
	mark_archetype_weapon(add_part(arm_r, cyl(0.055, 0.055, 0.98, 8), oak, FIST_R + HAFT_DIR * 0.33,
		_euler_deg(_basis_y(HAFT_DIR))))
	mark_archetype_weapon(add_part(arm_r, _hammer_head_mesh(), iron, FIST_R + HAFT_DIR * HEAD_AT,
		_euler_deg(_basis_y(HAFT_DIR))))
	# Fx: dust puffs (stomps, slam, plant, fidget thump, the fall) and steel-blue sparks (clangs, rune flares).
	_dust = _make_dust()
	_dust.name = "Dust"
	$Fx.add_child(_dust)
	_sparks = make_motes(RUNE_COLOR, 12, 0.45, 0.15, 2.4, 0.09, false, true)
	_sparks.name = "Sparks"
	$Fx.add_child(_sparks)
	ensure_shadow_blob(0.66)
	_authored += 1   # the blob


func _after_ready() -> void:
	_visor_node = _face
	_door_arm_rest = _door_arm.transform
	_door_back_rest = _door_back.transform
	# The rune (both doors) and the visor are driven here (flares, the planted-shield glow); the kit keeps the rest.
	for n: GeometryInstance3D in [_door_arm, _door_back, _visor_node]:
		if n:
			_glow_nodes.erase(n)
	if _variant_node:
		_flash_hit_targets.append(_variant_node)
	_fidget_wait = _next_fidget() * 0.6
	set_variant(_variant)
	_write_glows(true)


## Class weapon hooks (11.V3): Sword and Shield keeps the door (no round shield); fixed grips.
func _weapon_pieces(class_id: StringName) -> Array[StringName]:
	var p := super._weapon_pieces(class_id)
	if class_id == &"sword_shield":
		p.erase(&"round_shield")
	return p


## The arming sword juts forward-right past the body (15 deg down, 30 deg outward) so it reads at 40 m beside the
## door (the kit's generic hold hides it in front of the cuirass); the sword_slash strike stays level-forward.
func _weapon_grip(piece: StringName) -> Transform3D:
	if piece == &"sword":
		return Transform3D(Basis(Vector3.UP, 30.0 * DEG) * Basis(Vector3.RIGHT, 105.0 * DEG), FIST_R)
	return super._weapon_grip(piece)


func _weapon_slot(slot: StringName) -> Transform3D:
	match slot:
		&"hand_r":
			return Transform3D(Basis.IDENTITY, FIST_R)
		&"hand_l":
			return Transform3D(Basis.IDENTITY, FIST_L)
	return super._weapon_slot(slot)


func _on_weapon_class(_class_id: StringName) -> void:
	_door_mode = DM_NONE
	if _door_arm:
		_door_arm.transform = _door_arm_rest
		_door_back.transform = _door_back_rest
	_write_glows(true)


func _on_revive() -> void:
	if _face:
		_face.reset()
	_rune_flare = 0.0
	_visor_flare = 0.0
	_death_dust = false
	_fidget_wait = _next_fidget()
	_write_glows(true)


# ================================================================ animation

func _on_action_event(ev: StringName) -> void:
	match ev:
		&"cast_start":
			_cast_prev = 0.0
			_skill_prev = 0.0
		&"release":
			# The slam dust belongs to the hammer; the class styles have their own ChampionVfx.
			if _tier < 2 and weapon_class() == &"":
				_burst(_dust, FX_SLAM)
				_burst(_sparks, FX_SLAM + Vector3(0, 0.15, 0))
		&"level_up":
			_rune_flare = 1.0
			_visor_flare = 1.0


## Attack `slam`: the hammer swings up over the head (0.07 s), comes down and hits the ground in front at 0.12 s
## (the strike frame: melee damage is instant), stays planted a beat, then the long heavy recovery.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"slam":
		var going := super._pose_attack(prev, t)
		if door_in_hand():
			_door_guard_attack(t)
		return going
	rot(P_ARM_R, Vector3(_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, -155.0, -26.0) * DEG, 0,
		_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, 10.0, -4.0) * DEG))
	# The door rides up and forward as he bows so its edge never digs into the ground.
	rot(P_ARM_L, Vector3(_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, 6.0, -16.0) * DEG, 0, 0))
	pos(P_ARM_L, Vector3(0, _k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, 0.0, 0.14), 0))
	rot(P_CHEST, Vector3(_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, -12.0, 20.0) * DEG,
		_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, 12.0, -10.0) * DEG, 0))
	rot(P_HEAD, Vector3(_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, -10.0, -8.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, 0.05, -0.14),
		_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, -0.04, 0.20)))
	rot(P_LEG_L, Vector3(_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, -6.0, -20.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k4(t, 0.0, SLAM_UP, SLAM_HIT, SLAM_HOLD, SLAM_LEN, 4.0, 16.0) * DEG, 0, 0))
	if prev < SLAM_HIT and t >= SLAM_HIT:
		_on_action_event(&"release")
	return t < SLAM_LEN


func _pose_cast(spell: StringName, t: float) -> float:
	var prev := _cast_prev
	_cast_prev = t
	var back := not door_in_hand()
	match spell:
		&"shield_bash":
			return _pose_bash_back(prev, t) if back else _pose_bash(prev, t)
		&"bulwark_stand":
			return _pose_bulwark_back(prev, t) if back else _pose_bulwark(prev, t)
	return _pose_oath(prev, t)


## Oath of Iron (taunt): the weapon goes up to the sky (hammer, or the class weapon: `_arm_r_raise`), the shield is
## shoved forward (door on the back: the left fist thumps the chest instead), a heavy stomp of the right foot at
## 0.34 s (dust, sparks from the boss, the rune and visor flare), then the weapon comes down.
func _pose_oath(prev: float, t: float) -> float:
	_arm_r_raise(_k4(t, 0.0, 0.28, 0.30, 0.75, 1.1, 1.0, 1.0))
	if door_in_hand():
		rot(P_ARM_L, Vector3(_k4(t, 0.05, 0.30, 0.36, 0.80, 1.1, -4.0, -10.0) * DEG,
			_k4(t, 0.05, 0.30, 0.36, 0.80, 1.1, 16.0, 22.0) * DEG, 0))
		pos(P_ARM_L, Vector3(_k4(t, 0.05, 0.30, 0.36, 0.80, 1.1, 0.06, 0.10), 0,
			_k4(t, 0.05, 0.30, 0.36, 0.80, 1.1, 0.10, 0.22)))
	else:
		rot(P_ARM_L, Vector3(_k4(t, 0.05, 0.28, 0.34, 0.80, 1.1, -45.0, -80.0) * DEG, 0,
			_k4(t, 0.05, 0.28, 0.34, 0.80, 1.1, 20.0, 42.0) * DEG))
	rot(P_CHEST, Vector3(_k4(t, 0.0, 0.28, 0.36, 0.80, 1.1, -8.0, 6.0) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_k4(t, 0.0, 0.25, 0.36, 0.75, 1.1, -14.0, -4.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k4(t, 0.06, 0.26, 0.34, 0.34, 0.50, -40.0, 0.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k4(t, 0.30, 0.36, 0.40, 0.55, 0.75, -0.10, -0.06), 0))
	if prev < 0.34 and t >= 0.34:
		_rune_flare = 1.0
		_visor_flare = 1.0
		if _tier < 2:
			_burst(_dust, FX_FOOT_R)
			_burst(_sparks, FX_BOSS)
	return 1.1


## Shield Bash: pulls the shield back with a twist (0.10 s), then SHOVES it forward with a lunge and a stomping
## step of the left foot (0.16 s); sparks off the shield face, dust under the foot.
func _pose_bash(prev: float, t: float) -> float:
	rot(P_CHEST, Vector3(0, _k4(t, 0.0, 0.10, 0.18, 0.30, 0.7, -16.0, 20.0) * DEG, 0))
	pos(P_ARM_L, Vector3(0, _k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, 0.04, 0.06),
		_k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, -0.08, 0.36)))
	rot(P_ARM_L, Vector3(_k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, 6.0, -16.0) * DEG,
		_k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, 0.0, 16.0) * DEG, 0))
	rot(P_ARM_R, Vector3(_k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, 10.0, -20.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k4(t, 0.12, 0.16, 0.20, 0.32, 0.7, -0.08, -0.05),
		_k4(t, 0.04, 0.10, 0.18, 0.30, 0.7, -0.05, 0.30)))
	rot(P_LEG_L, Vector3(_k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, -30.0, -14.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, 6.0, 16.0) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_k4(t, 0.0, 0.10, 0.16, 0.30, 0.7, 4.0, -6.0) * DEG, 0, 0))
	if prev < 0.14 and t >= 0.14:
		_rune_flare = 1.0
		if _tier < 2:
			_burst(_sparks, FX_SHIELD + Vector3(0.05, 0.0, 0.40))
	if prev < 0.16 and t >= 0.16 and _tier < 2:
		_burst(_dust, FX_FOOT_L)
	return 0.7


## Bulwark Stand: raises the shield (0.30 s), drives it into the ground (0.42 s: dust, sparks, rune flare), then
## holds a braced crouch behind it with the hammer cocked for 6 s; recovers over 0.5 s. Any next animation (attack,
## cast, death) replaces it; walking ends the hold early (_extra_process).
func _pose_bulwark(prev: float, t: float) -> float:
	pos(P_ARM_L, Vector3(_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 0.06, 0.12),
		_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 0.18, -0.01),
		_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 0.06, 0.14)))
	rot(P_ARM_L, Vector3(_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, -6.0, -12.0) * DEG,
		_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 14.0, 28.0) * DEG, 0))
	pos(P_ROOT, Vector3(0, _k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 0.04, -0.16), 0))
	rot(P_CHEST, Vector3(_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, -6.0, 12.0) * DEG,
		_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, -4.0, 8.0) * DEG, 0))
	rot(P_HEAD, Vector3(_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, -4.0, -10.0) * DEG, 0, 0))
	rot(P_LEG_L, Vector3(_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, -6.0, -24.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 4.0, 26.0) * DEG, 0, 0))
	_arm_r_cock(t)
	if prev < BW_PLANT and t >= BW_PLANT:
		_rune_flare = 1.0
		_visor_flare = 1.0
		if _tier < 2:
			_burst(_dust, FX_PLANT)
			_burst(_sparks, FX_PLANT + Vector3(0, 0.10, 0.05))
	return BW_END


## Right arm, weapon "raised to the sky" (Oath of Iron), k 0-1, per grip family (champion_weapon_kit piece_hold):
## hammer / sword hang forward-down (arm overhead); the spear points forward-up (arm forward, shaft vertical); the
## greatsword and the staff are held UP from the fist (lifted straight up, the blade / crystal over the helm).
func _arm_r_raise(k: float) -> void:
	match weapon_class():
		&"spear":
			rot(P_ARM_R, Vector3(-70.0 * DEG * k, 0, 10.0 * DEG * k))
			pos(P_ARM_R, Vector3(0, 0.14 * k, 0.02 * k))
		&"two_hand":
			rot(P_ARM_R, Vector3(20.0 * DEG * k, 0, -4.0 * DEG * k))
			pos(P_ARM_R, Vector3(-0.04 * k, 0.32 * k, 0.06 * k))
		&"wizard":
			rot(P_ARM_R, Vector3(-12.0 * DEG * k, 0, 10.0 * DEG * k))
			pos(P_ARM_R, Vector3(0, 0.24 * k, 0.06 * k))
			weapon_flare(0.8 * k)
		_:
			rot(P_ARM_R, Vector3(-150.0 * DEG * k, 0, 14.0 * DEG * k))


## Right arm during Bulwark Stand (raised 0 -> BW_UP, cocked BW_PLANT -> BW_HOLD): the hammer / sword cocked high over
## the planted door; the spear levelled forward beside it; the greatsword on the shoulder; the staff planted upright.
func _arm_r_cock(t: float) -> void:
	var c := _k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 0.29, 1.0)
	match weapon_class():
		&"spear":
			rot(P_ARM_R, Vector3(-15.0 * DEG * c, 0, 6.0 * DEG * c))
			pos(P_ARM_R, Vector3(0, 0.12 * c, -0.06 * c))
		&"two_hand":
			rot(P_ARM_R, Vector3(-10.0 * DEG * c, 0, 8.0 * DEG * c))
			pos(P_ARM_R, Vector3(0, 0.06 * c, 0))
		&"wizard":
			rot(P_ARM_R, Vector3(-16.0 * DEG * c, 0, 6.0 * DEG * c))
			pos(P_ARM_R, Vector3(0, 0.04 * c, 0.10 * c))
		_:
			rot(P_ARM_R, Vector3(_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, -30.0, -105.0) * DEG, 0,
				_k4(t, 0.0, BW_UP, BW_PLANT, BW_HOLD, BW_END, 6.0, 12.0) * DEG))


## Shield Bash with the door on the back (Two-Hand, Wizard): the left hand reaches over the shoulder and swings the
## door off the back into the fist (0 -> 0.12), the bash plays 0.06 s later (shove at 0.22), then the door is swung
## back on (0.55 -> 0.85).
func _pose_bash_back(prev: float, t: float) -> float:
	_door_mode = DM_BACK_TO_HAND
	_door_w = smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.55, 0.85, t))
	_reach_back(_k4(t, 0.0, 0.05, 0.05, 0.05, 0.14, 1.0, 1.0) + _k4(t, 0.55, 0.67, 0.67, 0.67, 0.85, 1.0, 1.0))
	_pose_bash(prev - 0.06, t - 0.06)
	return 0.9


## Bulwark Stand with the door on the back: swung off into the hand (0 -> 0.22), then the planted hold as usual;
## swung back on during the recovery (BW_HOLD -> BW_END; walking jumps there too).
func _pose_bulwark_back(prev: float, t: float) -> float:
	_door_mode = DM_BACK_TO_HAND
	_door_w = smoothstep(0.0, 0.22, t) * (1.0 - smoothstep(BW_HOLD, BW_END, t))
	_reach_back(_k4(t, 0.0, 0.08, 0.08, 0.08, 0.24, 1.0, 1.0)
		+ _k4(t, BW_HOLD, BW_HOLD + 0.2, BW_HOLD + 0.2, BW_HOLD + 0.2, BW_END, 1.0, 1.0))
	return _pose_bulwark(prev, t)


## The left arm goes up over the shoulder to the door's top edge (k 0-1).
func _reach_back(k: float) -> void:
	_reach_rot = Vector3(-165.0 * DEG * k, 0, 14.0 * DEG * k)
	rot(P_ARM_L, _reach_rot)
	rot(P_CHEST, Vector3(0, 10.0 * DEG * k, 0))


# ---------------------------------------------------------------- class skills with the door in hand (11.V3)

func _pose_class_skill(id: StringName, t: float) -> float:
	var prev := _skill_prev
	_skill_prev = t
	if door_in_hand():
		match id:
			&"lunge":
				return _pose_lunge_door(t)
			&"hobbling_javelin":
				return _pose_javelin_door(prev, t)
			&"skewer":
				return _pose_skewer_door(t)
			&"riposte":
				return _pose_riposte_door(t)
			&"shield_throw":
				return _pose_door_throw(prev, t)
	return super._pose_class_skill(id, t)


## Lunge (Spear): the kit's dash-thrust, the door driven forward ahead of him instead of flung back.
func _pose_lunge_door(t: float) -> float:
	var c := _k3(t, 0.0, 0.10, 0.30, 0.60, 1.0, 1.0)
	pos(P_ROOT, Vector3(0, -0.14 * c, _k3(t, 0.0, 0.10, 0.20, 0.60, -0.06, 0.50)))
	rot(P_CHEST, Vector3(20.0 * DEG * c, _k3(t, 0.0, 0.10, 0.20, 0.60, 14.0, -18.0) * DEG, 0))
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, 18.0, -20.0) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, 0, _k3(t, 0.0, 0.10, 0.20, 0.60, -0.12, 0.45)))
	rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, -4.0, -18.0) * DEG, _k3(t, 0.0, 0.10, 0.20, 0.60, 8.0, 20.0) * DEG, 0))
	pos(P_ARM_L, Vector3(0.04 * c, 0.06 * c, _k3(t, 0.0, 0.10, 0.20, 0.60, 0.04, 0.24)))
	rot(P_HEAD, Vector3(-18.0 * DEG * c, 0, 0))
	rot(P_LEG_L, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, -10.0, -48.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, 8.0, 36.0) * DEG, 0, 0))
	return 0.60


## Hobbling Javelin (Spear): the kit's overhand throw with the LEFT hand (javelin from the back quiver, release
## 0.40), so first the door is stood on the ground in front-left (0.02 -> 0.12, dust), and picked up again 0.56 -> 0.76.
func _pose_javelin_door(prev: float, t: float) -> float:
	var length := super._pose_class_skill(&"hobbling_javelin", t)
	_door_mode = DM_PLANT
	_door_w = _k4(t, 0.02, 0.12, 0.12, 0.56, 0.76, 1.0, 1.0)
	_door_target = Transform3D(Basis.from_euler(DOOR_PLANT_ROT * DEG), DOOR_PLANT_C)
	if prev < 0.12 and t >= 0.12 and _tier < 2:
		_burst(_dust, Vector3(DOOR_PLANT_C.x, 0.04, DOOR_PLANT_C.z))
	return length


## Skewer (Spear): one long one-hand thrust with a big step behind the braced door (0.30), held a beat.
func _pose_skewer_door(t: float) -> float:
	pos(P_ROOT, Vector3(0, _k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, -0.04, -0.10), _k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, -0.06, 0.40)))
	rot(P_ARM_R, Vector3(_k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, 14.0, -6.0) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, _k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, 0.0, 0.04), _k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, -0.18, 0.60)))
	rot(P_CHEST, Vector3(_k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, -4.0, 14.0) * DEG, _k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, 25.0, -20.0) * DEG, 0))
	var k := _k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, 0.5, 1.0)
	rot(P_ARM_L, Vector3(-8.0 * DEG * k, 18.0 * DEG * k, 0))
	pos(P_ARM_L, Vector3(0.04 * k, 0.06 * k, 0.20 * k))
	rot(P_LEG_L, Vector3(_k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, -8.0, -40.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k4(t, 0.0, 0.18, 0.30, 0.52, 0.90, 6.0, 30.0) * DEG, 0, 0))
	return 0.90


## Riposte (Sword and Shield): the door squared to the front and lifted a hand, the sword cocked high over its top
## edge, knees braced; held 4 s (an attack or a cast ends it).
func _pose_riposte_door(t: float) -> float:
	var k := _k4(t, 0.0, 0.25, 0.25, 3.7, 4.0, 1.0, 1.0)
	var bob := 0.012 * sin(t * 6.0) * k
	rot(P_ARM_L, Vector3(-10.0 * DEG * k, 26.0 * DEG * k, 0))
	pos(P_ARM_L, Vector3(0.14 * k, 0.08 * k, 0.16 * k))
	rot(P_ARM_R, Vector3(-118.0 * DEG * k, 0, 22.0 * DEG * k))
	rot(P_CHEST, Vector3(4.0 * DEG * k, 10.0 * DEG * k, 0))
	pos(P_ROOT, Vector3(0, -0.07 * k + bob, 0))
	rot(P_LEG_L, Vector3(-16.0 * DEG * k, 0, 0))
	rot(P_LEG_R, Vector3(14.0 * DEG * k, 0, 0))
	return 4.0


## Shield Throw (Sword and Shield): the Oathwall throws his DOOR. Winds it across the body (0.18), flings it flat
## (0.28): the door tips flat, spins and shrinks away into ChampionVfx's flying shield (gone at 0.40); it comes back
## 0.80 and is caught at 0.88 with a recoil and a clang (sparks). Sword lowered.
func _pose_door_throw(prev: float, t: float) -> float:
	rot(P_ARM_L, Vector3(_kf(t, _SHT_T, _SHT_LX) * DEG, 0, _kf(t, _SHT_T, _SHT_LZ) * DEG))
	rot(P_CHEST, Vector3(0, _kf(t, _SHT_T, _SHT_CY) * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(t, _SHT_T, _SHT_BY), _kf(t, _SHT_T, _SHT_BZ)))
	rot(P_LEG_L, Vector3(_kf(t, _SHT_T, _SHT_GL) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(-0.6 * _kf(t, _SHT_T, _SHT_GL) * DEG, 0, 0))
	rot(P_ARM_R, Vector3(-20.0 * DEG * _k3(t, 0.0, 0.2, 0.9, 1.1, 1.0, 1.0), 0, 0))
	var a := 0.0
	if t >= THROW_OUT and t < THROW_CATCH:
		a = 1.0
		if t < THROW_GONE:
			a = _ease_out((t - THROW_OUT) / (THROW_GONE - THROW_OUT))
		elif t >= THROW_BACK:
			a = 1.0 - _ease_in((t - THROW_BACK) / (THROW_CATCH - THROW_BACK))
	if a > 0.0:
		_door_mode = DM_FLY
		_door_fly = a
	if prev < THROW_OUT and t >= THROW_OUT:
		_rune_flare = 1.0
	if prev < THROW_CATCH and t >= THROW_CATCH:
		_rune_flare = 1.0
		if _tier < 2:
			_burst(_sparks, FX_SHIELD)
	return 1.10


## Door kept braced in front during the kit's spear_thrust / sword_slash (cancels the kit's free-arm swing, which
## would fling a 1.6 m door around).
func _door_guard_attack(t: float) -> void:
	match attack_style:
		&"sword_slash":
			rot(P_ARM_L, Vector3(-_k3(t, 0.0, 0.07, 0.12, 0.5, -34.0, -46.0) * DEG, 0, -_k3(t, 0.0, 0.07, 0.12, 0.5, -6.0, 8.0) * DEG))
			rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -6.0, -12.0) * DEG, _k3(t, 0.0, 0.07, 0.12, 0.5, 8.0, 18.0) * DEG, 0))
			pos(P_ARM_L, Vector3(0, _k3(t, 0.0, 0.07, 0.12, 0.5, 0.03, 0.06), _k3(t, 0.0, 0.07, 0.12, 0.5, 0.06, 0.14)))
		&"spear_thrust":
			rot(P_ARM_L, Vector3(-_k3(t, 0.0, 0.07, 0.12, 0.5, -22.0, 18.0) * DEG, 0, 0))
			rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -6.0, -10.0) * DEG, _k3(t, 0.0, 0.07, 0.12, 0.5, 6.0, 14.0) * DEG, 0))
			pos(P_ARM_L, Vector3(0, 0.03 * _k3(t, 0.0, 0.07, 0.12, 0.5, 1.0, 1.0), _k3(t, 0.0, 0.07, 0.12, 0.5, 0.04, 0.16)))


# ---------------------------------------------------------------- door driver (11.V3)

## Local transform of pivot i this frame (rest + the pose offsets written so far).
func _pose_xf(i: int) -> Transform3D:
	var b := Basis.from_euler(_rest_rot[i] + _off_rot[i])
	if i == P_ROOT:
		b = b.scaled_local(_root_scale)
	return Transform3D(b, _rest_pos[i] + _off_pos[i])


## Model-space transform of ArmL this frame.
func _arm_l_model() -> Transform3D:
	return _pose_xf(P_ROOT) * _pose_xf(P_CHEST) * _pose_xf(P_ARM_L)


## Places the two door nodes for this frame from the pose's request (end of _extra_process: every offset is final).
## DM_BACK_TO_HAND: DoorBack (Chest space) goes from the back, over the left shoulder, to the left fist (w 0-1).
## DM_PLANT: DoorShield leaves the moving arm for a fixed model-space spot (w 0-1). DM_FLY: DoorShield flung flat
## from the hand, spinning and shrinking (_door_fly 0 = in hand, 1 = gone).
func _drive_doors() -> void:
	if _door_arm == null:
		return
	var arm_xf := _door_arm_rest
	var back_xf := _door_back_rest
	match _door_mode:
		DM_BACK_TO_HAND:
			# The hand the door swings to, without the reach over the shoulder (the reach only meets the door).
			var arm := Transform3D(Basis.from_euler(_rest_rot[P_ARM_L] + _off_rot[P_ARM_L] - _reach_rot),
				_rest_pos[P_ARM_L] + _off_pos[P_ARM_L])
			back_xf = _door_path(_door_back_rest, arm * _door_arm_rest, _door_w)
		DM_PLANT:
			var local := _arm_l_model().affine_inverse() * _door_target
			arm_xf = _door_arm_rest.interpolate_with(local, _door_w)
		DM_FLY:
			var am := _arm_l_model()
			arm_xf = am.affine_inverse() * _fly_xf(am * _door_arm_rest, _door_fly)
	_door_mode = DM_NONE
	_reach_rot = Vector3.ZERO
	if not _door_arm.transform.is_equal_approx(arm_xf):
		_door_arm.transform = arm_xf
	if not _door_back.transform.is_equal_approx(back_xf):
		_door_back.transform = back_xf


## Back (a) -> over the left shoulder (door upright, face turned out to the left) -> in hand (c), Chest space.
static func _door_path(a: Transform3D, c: Transform3D, w: float) -> Transform3D:
	if w <= 0.0:
		return a
	if w >= 1.0:
		return c
	var mid_o := (a.origin + c.origin) * 0.5 + Vector3(-0.30, 0.55, 0.0)
	var mid_b := Basis(Vector3.UP, -PI * 0.5)
	if w < 0.5:
		var u := w * 2.0
		return Transform3D(a.basis.slerp(mid_b, u), a.origin.lerp(mid_o, u))
	var v := (w - 0.5) * 2.0
	return Transform3D(mid_b.slerp(c.basis, v), mid_o.lerp(c.origin, v))


## The thrown door (model space) from the hand transform: tips flat, spins, flies forward and up, shrinks away.
static func _fly_xf(hand: Transform3D, a: float) -> Transform3D:
	var flat := Basis(Vector3.RIGHT, -PI * 0.5 * clampf(a * 2.5, 0.0, 1.0))
	var b := Basis(Vector3.UP, a * TAU * 1.25) * hand.basis * flat
	var s := maxf(pow(1.0 - a, 1.5), 0.01)
	return Transform3D(b.scaled_local(Vector3(s, s, s)), hand.origin + Vector3(0.25, 0.35, 2.8) * a)


## Idle fidget: lifts the door a hand high and thumps it down (dust), then rolls the neck and the shoulders. With the
## door on the back: a shrug of the strap instead of the thump.
func _pose_fidget(t: float) -> float:
	if door_in_hand():
		pos(P_ARM_L, Vector3(0, _k4(t, 0.0, 0.35, 0.45, 0.45, 0.8, 0.16, -0.02), 0))
	else:
		pos(P_ROOT, Vector3(0, _k4(t, 0.0, 0.30, 0.45, 0.45, 0.8, 0.03, -0.01), 0))
	rot(P_CHEST, Vector3(_k4(t, 0.0, 0.35, 0.45, 0.6, 1.0, -4.0, 3.0) * DEG,
		_k4(t, 0.0, 0.35, 0.45, 0.9, 1.4, -7.0, -3.0) * DEG, 0))
	var roll: float = 0.0
	if t > 0.55 and t < 1.75:
		roll = sin((t - 0.55) * TAU / 1.2) * sin((t - 0.55) * PI / 1.2)
	rot(P_HEAD, Vector3(-4.0 * DEG * absf(roll), 0, 10.0 * DEG * roll))
	rot(P_CHEST, Vector3(0, 0, -2.5 * DEG * roll))
	if _fidget_prev < 0.45 and t >= 0.45 and door_in_hand():
		_burst(_dust, Vector3(-0.30, 0.04, 0.62))
	_fidget_prev = t
	return 1.8


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	_rune_flare = maxf(0.0, _rune_flare - dt / 0.6)
	_visor_flare = maxf(0.0, _visor_flare - dt / 0.45)
	_fidget_process(dt)
	if _dead:
		# The shield topples outward as he falls, the hammer arm flops; dust when the body hits the ground.
		var f: float = _ease_out(clampf((_death_t - 0.10) / 0.40, 0.0, 1.0))
		rot(P_ARM_L, Vector3(-10.0 * DEG * f, 0, -38.0 * DEG * f))
		rot(P_ARM_R, Vector3(0, 0, 20.0 * DEG * f))
		if not _death_dust and _death_t >= 0.52:
			_death_dust = true
			if _tier < 2:
				_burst(_dust, Vector3(0, 0.04, 1.0))
	else:
		# March: the door stays braced in front (cancels most of the kit's arm swing) and rides a little higher.
		# Door on the back: the free left arm keeps the kit's swing.
		var in_hand := door_in_hand()
		if _walk_w > 0.0:
			var s := sin(TAU * _walk_p)
			if in_hand:
				rot(P_ARM_L, Vector3(15.0 * DEG * s * _walk_w, 0, 0))
				pos(P_ARM_L, Vector3(0, 0.05 * _walk_w, 0.03 * _walk_w))
			rot(P_CHEST, Vector3(3.0 * DEG * _walk_w, 4.0 * DEG * s * _walk_w, 0))
		# Hit: the shield snaps up to cover.
		if _hit_t < HIT_LEN and in_hand:
			var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 \
				else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
			rot(P_ARM_L, Vector3(-14.0 * DEG * k, 0, 0))
			pos(P_ARM_L, Vector3(0, 0.06 * k, 0))
		# Bulwark: walking away ends the hold early (jumps to the recovery).
		if _action == &"cast" and _cast_id == &"bulwark_stand" and _speed >= 0.3 \
				and _action_t > BW_PLANT and _action_t < BW_HOLD:
			_action_t = BW_HOLD
	_drive_doors()
	_write_glows(false)


func _fidget_process(dt: float) -> void:
	if _action == &"fidget":
		if _dead or _speed >= 0.3:
			_action = &""
			return
		var length := _pose_fidget(_action_t)
		if _action_t >= length:
			_action = &""
		return
	if fidget_every <= 0.0 or _dead or _action != &"" or _speed >= 0.3 or _tier != 0:
		return
	_fidget_wait -= dt
	if _fidget_wait <= 0.0:
		_fidget_wait = _next_fidget()
		play_fidget()


func _next_fidget() -> float:
	var h: float = float(hash(get_instance_id() + int(_t * 7.0)) % 1000) / 1000.0
	return fidget_every * (0.6 + 0.8 * h)


## Rune (both door nodes) and visor (Head) glow: kit level (veterancy x haste, 0 dead) x flares; the planted shield
## glows.
func _write_glows(force: bool) -> void:
	var g := glow_level()
	var hold: float = 0.0
	if _action == &"cast" and _cast_id == &"bulwark_stand" and not _dead:
		hold = smoothstep(BW_UP, BW_PLANT + 0.05, _action_t) * (1.0 - smoothstep(BW_HOLD, BW_END, _action_t))
	var rb: float = g * (1.0 + 2.2 * _rune_flare + 0.9 * hold)
	var vb: float = g * (1.0 + 1.6 * _visor_flare + 0.4 * hold)
	if _door_arm and (force or absf(rb - _rune_written) > 0.01 or (rb == 0.0 and _rune_written != 0.0)):
		_rune_written = rb
		_door_arm.set_instance_shader_parameter(&"glow_boost", rb)
		_door_back.set_instance_shader_parameter(&"glow_boost", rb)
	if _visor_node and (force or absf(vb - _visor_written) > 0.01 or (vb == 0.0 and _visor_written != 0.0)):
		_visor_written = vb
		_visor_node.set_instance_shader_parameter(&"glow_boost", vb)


func _burst(p: GPUParticles3D, at: Vector3) -> void:
	if p == null:
		return
	p.position = at
	p.restart()


## Smooth keyframe table (smoothstep between keys).
static func _kf(t: float, ts: Array[float], vs: Array[float]) -> float:
	if t <= ts[0]:
		return vs[0]
	for i: int in range(1, ts.size()):
		if t < ts[i]:
			var f := (t - ts[i - 1]) / maxf(ts[i] - ts[i - 1], 0.0001)
			return lerpf(vs[i - 1], vs[i], f * f * (3.0 - 2.0 * f))
	return vs[vs.size() - 1]


## Keyframes 0 -> v1 (t0..t1) -> v2 (t1..t2), HOLD v2 (t2..t3) -> 0 (t3..t4), eased.
static func _k4(t: float, t0: float, t1: float, t2: float, t3: float, t4: float, v1: float, v2: float) -> float:
	if t <= t0 or t >= t4:
		return 0.0
	if t < t1:
		return v1 * _ease_out((t - t0) / maxf(t1 - t0, 0.0001))
	if t < t2:
		return lerpf(v1, v2, _ease_out((t - t1) / maxf(t2 - t1, 0.0001)))
	if t < t3:
		return v2
	return v2 * (1.0 - smoothstep(0.0, 1.0, (t - t3) / maxf(t4 - t3, 0.0001)))


# ================================================================ part helpers

## Own palette material (art/units/champions/oathwall/materials/), loaded once.
static func own(name: StringName) -> Material:
	var key := "mat_" + String(name)
	if not _own.has(key):
		_own[key] = load(OWN_DIR + String(name) + ".tres")
	return _own[key]


## Capsule from model point a to b (radius r), merged with the pivot.
func _limb(pivot: Node3D, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d := b - a
	# an 8-sided sleeve (was a 162-vertex capsule; the ends hide in the pauldron / gauntlet: faces pass trim)
	add_part(pivot, cyl(r, r, d.length() + r * 0.6, 8), mat, a + d * 0.5, _euler_deg(_basis_y(d)))


## The door shield in its own frame (face +Z, centre at the origin): one mesh, three surfaces (iron: rim, straps,
## rivets, boss; oak: the three planks; glow: the oath rune). Shared by DoorShield and DoorBack (11.V3).
static func _door_mesh() -> Mesh:
	var key := "door"
	if _own.has(key):
		return _own[key]
	var metal := SurfaceTool.new()
	metal.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rune := SurfaceTool.new()
	rune.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append(metal, box(Vector3(SHIELD_SIZE.x, SHIELD_SIZE.y, 0.06)), _xf(Vector3(0, 0, -0.02)))
	_append(metal, _ironwork_mesh(), Transform3D.IDENTITY)
	_append(metal, sphere(0.22), _xf(Vector3(0, 0, 0.07), Vector3.ZERO, Vector3(1.0, 1.0, 0.55)))
	_append(wood, _planks_mesh(), Transform3D.IDENTITY)
	_append(rune, _rune_mesh(), Transform3D.IDENTITY)
	var m := ArrayMesh.new()
	var k := 0
	for p: Array in [[metal, own(&"oathwall_iron")], [wood, own(&"oathwall_oak")], [rune, own(&"oathwall_glow")]]:
		var st: SurfaceTool = p[0]
		st.index()
		st.commit(m)
		m.surface_set_material(k, p[1])
		k += 1
	_own[key] = m
	return m


## Left gauntlet (model space) for the classes that sling the door on the back: iron fist + flared cuff.
static func _gauntlet_l_mesh() -> Mesh:
	var up := (Vector3(-0.58, 1.50, 0.0) - FIST_L).normalized()
	var pieces: Array = []
	pieces.append([sphere(0.14), _xf(FIST_L)])
	pieces.append([cyl(0.14, 0.17, 0.20, 8), Transform3D(_basis_y(up), FIST_L + up * 0.17)])
	return _compound("gauntlet_l", pieces)


static func _basis_y(dir: Vector3) -> Basis:
	return Basis(Quaternion(Vector3.UP, dir.normalized()))


static func _euler_deg(b: Basis) -> Vector3:
	return b.get_euler() * (180.0 / PI)


static func _xf(p: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl), p)


## Flat-shaded tapered box: `bottom` (x, z) size at -h/2, `top` at +h/2. Chunky plates, boots.
static func frustum(bottom: Vector2, top: Vector2, h: float) -> Mesh:
	var key := "fr%s_%s_%s" % [bottom, top, h]
	if _own.has(key):
		return _own[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_frustum_into(st, Transform3D.IDENTITY, bottom, top, h, Vector2.ZERO)
	st.index()
	var m := st.commit()
	_own[key] = m
	return m


static func _frustum_into(st: SurfaceTool, xf: Transform3D, bottom: Vector2, top: Vector2, h: float, uv: Vector2) -> void:
	var y0 := -h * 0.5
	var y1 := h * 0.5
	var b: Array[Vector3] = [Vector3(-bottom.x, y0, -bottom.y) * Vector3(0.5, 1, 0.5),
		Vector3(bottom.x, y0, -bottom.y) * Vector3(0.5, 1, 0.5), Vector3(bottom.x, y0, bottom.y) * Vector3(0.5, 1, 0.5),
		Vector3(-bottom.x, y0, bottom.y) * Vector3(0.5, 1, 0.5)]
	var t: Array[Vector3] = [Vector3(-top.x, y1, -top.y) * Vector3(0.5, 1, 0.5),
		Vector3(top.x, y1, -top.y) * Vector3(0.5, 1, 0.5), Vector3(top.x, y1, top.y) * Vector3(0.5, 1, 0.5),
		Vector3(-top.x, y1, top.y) * Vector3(0.5, 1, 0.5)]
	var faces: Array = [[b[0], b[1], b[2], b[3]], [t[3], t[2], t[1], t[0]], [b[3], b[2], t[2], t[3]],
		[b[1], b[0], t[0], t[1]], [b[2], b[1], t[1], t[2]], [b[0], b[3], t[3], t[0]]]
	for f: Array in faces:
		_quad(st, xf * (f[0] as Vector3), xf * (f[1] as Vector3), xf * (f[2] as Vector3), xf * (f[3] as Vector3), uv, uv)


## Adds a flat quad a, b, c, d given COUNTER-CLOCKWISE seen from outside (so n = (b - a) x (d - a) points out).
## Godot's front faces are clockwise, so the triangles are emitted a, c, b / a, d, c. a, b get uv_bottom; c, d uv_top.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv_top: Vector2, uv_bottom: Vector2) -> void:
	var n := (b - a).cross(d - a).normalized()
	if n == Vector3.ZERO:
		n = (c - b).cross(a - b).normalized()
	# Given CCW from outside, n points outward; Godot front faces are clockwise, so emit a, c, b / a, d, c.
	for v: Array in [[a, uv_bottom], [c, uv_top], [b, uv_bottom], [a, uv_bottom], [d, uv_top], [c, uv_top]]:
		st.set_normal(n)
		st.set_uv(v[1] as Vector2)
		st.add_vertex(v[0] as Vector3)


## Appends a primitive mesh (surface 0) transformed by xf, as plain triangles.
static func _append(st: SurfaceTool, mesh: Mesh, xf: Transform3D) -> void:
	var arr := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var nb := xf.basis.inverse().transposed()
	var count: int = ix.size() if not ix.is_empty() else v.size()
	for k: int in count:
		var j: int = ix[k] if not ix.is_empty() else k
		st.set_normal((nb * nr[j]).normalized() if j < nr.size() else Vector3.UP)
		st.set_uv(uv[j] if j < uv.size() else Vector2.ZERO)
		st.add_vertex(xf * v[j])


## One mesh (one material) from [mesh, Transform3D] pairs.
static func _compound(key: String, pieces: Array) -> Mesh:
	if _own.has(key):
		return _own[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Array in pieces:
		_append(st, p[0] as Mesh, p[1] as Transform3D)
	st.index()
	var m := st.commit()
	_own[key] = m
	return m


# ================================================================ custom meshes (built once per process)

## Three oak planks of slightly different lengths, 3 cm seams (the iron rim shows through), shield frame.
static func _planks_mesh() -> Mesh:
	var pieces: Array = []
	var hs: Array[float] = [1.48, 1.52, 1.45]
	var dy: Array[float] = [0.0, 0.01, -0.01]
	for i: int in 3:
		pieces.append([box(Vector3(0.35, hs[i], 0.07)), _xf(Vector3(-0.375 + 0.375 * i, dy[i], 0.035))])
	return _compound("planks", pieces)


## Iron fittings: two straps across the planks, 10 rivets on them and 6 on the rim.
static func _ironwork_mesh() -> Mesh:
	var pieces: Array = []
	for sy: float in [-0.52, 0.52]:
		pieces.append([box(Vector3(1.16, 0.13, 0.035)), _xf(Vector3(0, sy, 0.085))])
		for x: float in [-0.48, -0.24, 0.0, 0.24, 0.48]:
			pieces.append([sphere(0.045, 5, 2), _xf(Vector3(x, sy, 0.105))])
	for p: Vector2 in [Vector2(-0.57, -0.77), Vector2(0.57, -0.77), Vector2(-0.57, 0.77), Vector2(0.57, 0.77),
			Vector2(-0.575, 0.0), Vector2(0.575, 0.0)]:
		pieces.append([sphere(0.045, 5, 2), _xf(Vector3(p.x, p.y, 0.015))])
	return _compound("ironwork", pieces)


## The oath rune (glow): a ring around the boss, four diagonal rays, a keyhole bar on the boss face.
static func _rune_mesh() -> Mesh:
	var pieces: Array = []
	pieces.append([torus(0.24, 0.30, 16), _xf(Vector3(0, 0, 0.08), Vector3(90, 0, 0))])
	for k: int in 4:
		var a := deg_to_rad(45.0 + 90.0 * k)
		var r := 0.41
		pieces.append([box(Vector3(0.07, 0.17, 0.03)), _xf(Vector3(sin(a) * r, cos(a) * r, 0.085), Vector3(0, 0, -rad_to_deg(a)))])
	pieces.append([box(Vector3(0.05, 0.22, 0.03)), _xf(Vector3(0, -0.01, 0.185))])
	return _compound("rune", pieces)


## Hammer-hand gauntlet (model space): a big iron fist and a flared cuff up the forearm.
static func _gauntlet_mesh() -> Mesh:
	var up := (Vector3(0.60, 1.48, 0.0) - FIST_R).normalized()
	var pieces: Array = []
	pieces.append([sphere(0.145), _xf(FIST_R)])
	pieces.append([cyl(0.145, 0.175, 0.20, 8), Transform3D(_basis_y(up), FIST_R + up * 0.17)])
	return _compound("gauntlet", pieces)


## War hammer head in the haft frame (Y = haft direction; +Z = the striking side, it hits the ground in `slam`): a
## square core, a flared square striking face, a stubby pyramid spike on the back, a cap over the haft end.
static func _hammer_head_mesh() -> Mesh:
	var pieces: Array = []
	pieces.append([box(Vector3(0.24, 0.26, 0.30)), _xf(Vector3(0, 0, 0.03))])
	pieces.append([frustum(Vector2(0.24, 0.24), Vector2(0.32, 0.32), 0.10), _xf(Vector3(0, 0, 0.22), Vector3(90, 0, 0))])
	pieces.append([box(Vector3(0.34, 0.34, 0.05)), _xf(Vector3(0, 0, 0.285))])
	# Spike: a 4-sided cone twisted 45 deg about its own axis (faces square with the core), tip toward -Z.
	var spike := Basis(Vector3.RIGHT, deg_to_rad(-90.0)) * Basis(Vector3.UP, deg_to_rad(45.0))
	pieces.append([cyl(0.0, 0.13, 0.26, 4), Transform3D(spike, Vector3(0, 0, -0.24))])
	pieces.append([box(Vector3(0.11, 0.06, 0.11)), _xf(Vector3(0, 0.16, 0.03))])
	return _compound("hammer_head", pieces)


## Team sash: an 8-sided band around the waist (UV.y 0.1: no wave, no stripe), a knot on the hammer hip and two
## hanging tails (UV.y 0 -> 1 down the tail: the banner shader waves them and paints the stripes; UV.x kept in
## 0-0.3 so the glyph and the swallow-tail cut stay on the cape only). Model space.
static func _sash_mesh() -> Mesh:
	var key := "sash"
	if _own.has(key):
		return _own[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ap := 0.495
	var rv := ap / cos(PI / 8.0)
	var y0 := 0.89
	var y1 := 1.02
	for i: int in 8:
		var a0 := PI / 8.0 + TAU * float(i) / 8.0
		var a1 := PI / 8.0 + TAU * float(i + 1) / 8.0
		var p0 := Vector3(sin(a0) * rv, 0, cos(a0) * rv)
		var p1 := Vector3(sin(a1) * rv, 0, cos(a1) * rv)
		# CCW seen from outside (angles grow from +Z toward +X, so p0 is on the viewer's left).
		_quad(st, p0 + Vector3(0, y0, 0), p1 + Vector3(0, y0, 0), p1 + Vector3(0, y1, 0), p0 + Vector3(0, y1, 0),
			Vector2(0.15, 0.1), Vector2(0.15, 0.1))
	# Knot on the right hip (60 deg from the front toward +X), facing outward.
	var ka := deg_to_rad(60.0)
	var kxf := Transform3D(Basis(Vector3.UP, ka), Vector3(sin(ka) * 0.53, 0.955, cos(ka) * 0.53))
	_frustum_into(st, kxf, Vector2(0.16, 0.10), Vector2(0.13, 0.08), 0.15, Vector2(0.15, 0.1))
	_tail(st, Vector3(0.455, 0.92, 0.29), Vector3(0.49, 0.47, 0.33), 0.15, deg_to_rad(58.0))
	_tail(st, Vector3(0.485, 0.93, 0.21), Vector3(0.555, 0.58, 0.17), 0.13, deg_to_rad(72.0))
	st.index()
	var m := st.commit()
	_own[key] = m
	return m


## A hanging cloth strip from `top` to `bottom`, `w` wide, facing outward at angle `face` (from +Z toward +X).
static func _tail(st: SurfaceTool, top: Vector3, bottom: Vector3, w: float, face: float) -> void:
	var across := Vector3(cos(face), 0, -sin(face)) * (w * 0.5)
	var segs := 6
	for s: int in segs:
		var u0 := float(s) / float(segs)
		var u1 := float(s + 1) / float(segs)
		var c0 := top.lerp(bottom, u0)
		var c1 := top.lerp(bottom, u1)
		# Slight flare toward the bottom.
		var f0 := 1.0 + 0.15 * u0
		var f1 := 1.0 + 0.15 * u1
		_quad_uv(st, c1 - across * f1, c1 + across * f1, c0 + across * f0, c0 - across * f0,
			Vector2(0.0, u1), Vector2(0.3, u1), Vector2(0.3, u0), Vector2(0.0, u0))


static func _quad_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2,
		uc: Vector2, ud: Vector2) -> void:
	var n := (b - a).cross(d - a).normalized()
	for v: Array in [[a, ua], [c, uc], [b, ub], [a, ua], [d, ud], [c, uc]]:
		st.set_normal(n)
		st.set_uv(v[1] as Vector2)
		st.add_vertex(v[0] as Vector3)


## Garran (variant A): a chestnut FORKED beard: a broad block under the helm rim and two lobes jutting forward over
## the cuirass, an iron bead at each tip. Two surfaces (oak-brown hair, iron). Model space.
static func _beard_mesh() -> Mesh:
	var key := "beard"
	if _own.has(key):
		return _own[key]
	var hair := SurfaceTool.new()
	hair.begin(Mesh.PRIMITIVE_TRIANGLES)
	var metal := SurfaceTool.new()
	metal.begin(Mesh.PRIMITIVE_TRIANGLES)
	_frustum_into(hair, _xf(Vector3(0, 1.555, 0.305)), Vector2(0.40, 0.13), Vector2(0.46, 0.12), 0.11, Vector2.ZERO)
	for sx: float in [-1.0, 1.0]:
		var xf := _xf(Vector3(0.09 * sx, 1.37, 0.375), Vector3(-14, 0, 10.0 * sx))
		_frustum_into(hair, xf, Vector2(0.10, 0.08), Vector2(0.19, 0.13), 0.30, Vector2.ZERO)
		_append(metal, cyl(0.055, 0.055, 0.07, 8), xf * _xf(Vector3(0, -0.17, 0)))
	var m := _two_surfaces(hair, own(&"oathwall_oak"), metal, own(&"oathwall_iron"))
	_own[key] = m
	return m


## Gerda (variant B): two thick flaxen braids from under the helm down over the cuirass, iron bands and tufts.
static func _braids_mesh() -> Mesh:
	var key := "braids"
	if _own.has(key):
		return _own[key]
	var hair := SurfaceTool.new()
	hair.begin(Mesh.PRIMITIVE_TRIANGLES)
	var metal := SurfaceTool.new()
	metal.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx: float in [-1.0, 1.0]:
		var a := Vector3(0.19 * sx, 1.60, 0.27)
		var b := Vector3(0.22 * sx, 1.40, 0.385)
		var c := Vector3(0.23 * sx, 1.13, 0.40)
		# Braided look: overlapping flattened lobes, bigger at the top.
		for k: int in 6:
			var u := float(k) / 5.0
			var p := a.lerp(b, u * 2.0) if u < 0.5 else b.lerp(c, (u - 0.5) * 2.0)
			var r := lerpf(0.085, 0.07, u)
			_append(hair, sphere(1.0, 6, 3), _xf(p, Vector3(0, 0, 25.0 * sx * (1.0 if k % 2 == 0 else -1.0)),
				Vector3(r * 1.1, r * 0.95, r * 0.8)))
		_append(metal, cyl(0.06, 0.06, 0.06, 8), _xf(c + Vector3(0, -0.04, 0.0)))
		_append(hair, cyl(0.02, 0.07, 0.14, 6), _xf(c + Vector3(0, -0.13, 0.0), Vector3(180, 0, 0)))
	var m := _two_surfaces(hair, own(&"oathwall_padding"), metal, own(&"oathwall_iron"))
	_own[key] = m
	return m


static func _two_surfaces(a: SurfaceTool, ma: Material, b: SurfaceTool, mb: Material) -> ArrayMesh:
	var m := ArrayMesh.new()
	a.index()
	a.commit(m)
	m.surface_set_material(0, ma)
	b.index()
	b.commit(m)
	m.surface_set_material(1, mb)
	return m


## Dust puffs (MIX, warm grey-brown), one-shot, restarted wherever a foot, the hammer or the shield hits the ground.
static func _make_dust() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 0.9
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.95
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 3, 4))
	var pm: ParticleProcessMaterial = _own.get("dust_pm")
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_axis = Vector3.UP
		pm.emission_ring_radius = 0.25
		pm.emission_ring_inner_radius = 0.08
		pm.emission_ring_height = 0.04
		pm.direction = Vector3.UP
		pm.spread = 70.0
		pm.initial_velocity_min = 0.8
		pm.initial_velocity_max = 1.7
		pm.gravity = Vector3(0, -1.2, 0)
		pm.damping_min = 1.5
		pm.damping_max = 2.5
		pm.scale_min = 0.8
		pm.scale_max = 1.3
		var sc := CurveTexture.new()
		var cv := Curve.new()
		cv.add_point(Vector2(0, 0.4))
		cv.add_point(Vector2(1, 1.0))
		sc.curve = cv
		pm.scale_curve = sc
		var ramp := GradientTexture1D.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.50, 0.44, 0.36, 0.0))
		g.set_color(1, Color(0.46, 0.41, 0.34, 0.0))
		g.add_point(0.15, Color(0.52, 0.46, 0.38, 0.55))
		ramp.gradient = g
		pm.color_ramp = ramp
		_own["dust_pm"] = pm
	p.process_material = pm
	var q: QuadMesh = _own.get("dust_quad")
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(0.45, 0.45)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true
		sm.vertex_color_use_as_albedo = true
		sm.albedo_texture = mote_texture()
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		q.material = sm
		_own["dust_quad"] = q
	p.draw_pass_1 = q
	return p
