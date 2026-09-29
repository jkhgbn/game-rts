extends CharacterModel
## The Mage Archer (tier3-extras.md 6 / 12, task 13b.V5): the Shadow kingdom's unique NPC, "Veyra Nightquill" (A) /
## "Vesper Nightquill" (B). A tall hooded sorceress-archer: a peaked team-colour hood with a silver-trimmed brim and a
## short mantle, a long dark coat split at the front (team-colour lining, silver hem), a HALF CAPE on the left shoulder
## (banner cloth, swallow-tailed, the kingdom glyph on the shoulder blade), a silver pauldron and an archer's bracer on
## the right arm. THE READ: a dark recurve bow TALLER than her (2.1 m, obsidian limbs, silver tips) held upright at her
## right side with a glowing violet string (the kingdom glow (0.70, 0.30, 1.00)), and a FLOATING RUNE QUIVER at her back:
## five shafts with glowing violet heads fanned through a silver rune halo, bobbing on their own. Glow points at 40 m:
## the string and the quiver heads (2). Variant B (set_variant(1)) = hood down: a rolled cowl, silver-lilac hair and a
## long braid over the right shoulder (the hood lies on her back).
## Hooks (all safe before _ready): the kit ones (CharacterModel) + set_variant(v), play_call() (+ signal call_finished,
## is_calling()), weapon_override() -> &"mage_bow", get_beam_origin(), get_quiver_origin(), authored_mesh_count().
## Attack style `arcane_bow` (0.55 s, release = attack_windup 0.15): the bow comes up, the left hand draws a violet
## arrow of light onto the string, loose, the string snaps, a small recoil. Casts (play_cast): her own sable_shaft (a
## heavy charged draw, big recoil), grave_mark (the free hand points the mark, the quiver flares), eclipse_volley (aimed
## high, the quiver fan opens and rises); the Wizard-tree actives arc_bolt (snap shot), slipstep (the kit's blink + a
## quiver flash), starfall (shot straight up, the string stays lit), gravity_well (a downward swirl of the free hand,
## crouch), comet_rain (three quick high shots), astral_form (arms open, the bow held upright high, every glow up);
## unknown ids play a quick shot. Seated (kit rider): the bow arm rolls out, the bow clears the mount. play_call() (2.0 s): she rises out of the ground (the Lair's circle) head bowed, a ring
## of violet motes, then lifts the bow upright over her head with the quiver fanned open.
## Champion classes: `weapon_override &"mage_bow"` (tier3-extras.md 6.4): set_weapon_class(any class) keeps the bow (no
## kit piece is merged, `_weapon_pieces` is empty) and restores attack_style `arcane_bow` / windup 0.15, so the gameplay
## class swap (always &"wizard" for her) changes nothing visible; the Wizard-tree skill ids play her bow poses.
## Death `sink` (Shadow): she sinks back into the ground, the glows die. Idle / walk / hit / level-up / revive: the kit.
## Budget: 14 authored meshes (blob included), 15 draw instances (7 merged pivots + Bow, Quiver, Variant, blob, 4 particle
## systems), 0 lights, 0 own materials: 7 shared kit palette materials (shadow_cloth_dark, shadow_cloth, shadow_cape,
## shadow_silver, shadow_skin, shadow_obsidian, shadow_glow_hero) + the blob.

## Emitted when play_call() has finished (she stands on the ground).
signal call_finished

const GLOW := Color(0.70, 0.30, 1.00)
const SHOULDER_R := Vector3(0.31, 1.50, 0.0)
const SHOULDER_L := Vector3(-0.31, 1.50, 0.0)
const GRIP_R := Vector3(0.46, 1.08, 0.20)          # right fist = the bow grip (model space, rest pose)
const HAND_L := Vector3(-0.40, 1.00, 0.08)
const QUIVER_AT := Vector3(0.0, 1.40, -0.49)       # centre of the rune halo, floating behind the back
const HOOD_C := Vector3(0.0, 1.745, -0.015)
const HOOD_TIP := Vector3(0.0, 2.03, -0.27)         # the hood's peak, drooping back
const HEAD_C := Vector3(0.0, 1.73, 0.02)
const HEAD_R := 0.175
## Bow in grip space: limbs along +-Y, the back toward +Z, the string toward -Z (brace 0.215 m), string contact at +-0.87.
const LIMB: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.14, -0.012), Vector2(0.32, -0.05), Vector2(0.50, -0.10),
	Vector2(0.66, -0.15), Vector2(0.78, -0.185), Vector2(0.87, -0.20), Vector2(0.94, -0.188), Vector2(0.995, -0.15),
	Vector2(1.03, -0.10), Vector2(1.045, -0.055)]
const STRING_Y := 0.87
const STRING_Z := -0.215
const NOCK := 0.52                                  # drawn string: nock point behind the grip (bow space, -Z)
const ARROW_TIP := Vector3(0.025, 0.0, 0.36)        # the drawn arrow's head (bow space)
const SHOT_LEN := 0.55
const ATTACK_STYLE := &"arcane_bow"
const ATTACK_WINDUP := 0.15
const STRING_BASE := 1.2                            # glow_boost of the string at rest (energy 3 x 1.2)
const QUIVER_BASE := 0.9
const WEAPON_OVERRIDE := &"mage_bow"
const CALL_ID := &"mage_archer_call"
const CALL_LEN := 2.0
const CALL_DEPTH := 2.1                             # she starts this far under the ground
const CHEST_O := Vector3(0.0, 1.08, 0.0)           # the Chest pivot (model space)
const AIM_NOCK := Vector3(0.0, 1.60, 0.16)          # the draw anchor under her chin (model space, level shot)
const AIM_CHEST_YAW := -40.0                        # deg: the bow shoulder turns toward the target
const OWN_CAST_IDS: Array[StringName] = [&"sable_shaft", &"grave_mark", &"eclipse_volley"]
const TREE_CAST_IDS: Array[StringName] = [&"arc_bolt", &"slipstep", &"starfall", &"gravity_well", &"comet_rain",
	&"astral_form"]
const COMET_RELS: Array[float] = [0.38, 0.68, 0.98]

## 0 = Veyra (hood up), 1 = Vesper (hood down, braid). Change it with set_variant().
@export_range(0, 1) var variant: int = 0

static var _ma_meshes: Dictionary = {}

var _authored: int = 0
var _bow: MeshInstance3D
var _quiver: MeshInstance3D
var _variant_node: MeshInstance3D
var _spark: GPUParticles3D           # one-shot sparks at the arrow head on every loose
var _call_motes: GPUParticles3D      # one-shot ring of rising motes (play_call)
var _q_rest: Quaternion = Quaternion.IDENTITY
var _up_basis: Basis = Basis.IDENTITY
var _rest_dir_r: Vector3 = Vector3.DOWN
var _rest_dir_l: Vector3 = Vector3.DOWN
var _arm_len_r: float = 0.5
var _arm_len_l: float = 0.5
var _quiver_base: Vector3 = Vector3.ZERO

# per-frame targets written by the poses (reset in _extra_process)
var _bow_k: float = 0.0              # 0 rest grip -> 1 bow upright on the aim line (back to the target)
var _bow_e: float = 0.0              # the aim's elevation (rad)
var _bow_up: float = 0.0             # 1 = the bow stands upright in model space whatever the arm does
var _bow_draw: float = 0.0           # > 0.5: drawn string + nocked arrow of light
var _hold: float = 0.0               # extra string glow held by a pose
var _quiver_hold: float = 0.0        # extra quiver glow held by a pose
var _fan: float = 0.0                # quiver fan open (> 0.5) and lift (0-1)
# state
var _flare: float = 0.0
var _qflare: float = 0.0
var _qkick: float = 0.0
var _fired: bool = false
var _shots: int = 0
var _calling: bool = false
var _call_pending: bool = false
var _bow_q_w: Quaternion = Quaternion(9, 9, 9, 9)
var _drawn_w: int = -1
var _bow_glow_w: float = -1.0
var _quiver_glow_w: float = -1.0
var _fan_w: int = -1
var _quiver_xf_w: Transform3D = Transform3D(Basis.IDENTITY, Vector3(999, 0, 0))
## Painted face (FaceKit via ChampionFaces, faces pass 2026-09-28).
var _face: FaceRig


static func _robe() -> Material:
	return palette(&"shadow_cloth_dark")


static func _team() -> Material:
	return palette(&"shadow_cloth")


static func _cape_mat() -> Material:
	return palette(&"shadow_cape")


static func _silver() -> Material:
	return palette(&"shadow_silver")


static func _skin() -> Material:
	return palette(&"shadow_skin")


static func _dark() -> Material:
	return palette(&"shadow_obsidian")


static func _glow() -> Material:
	return palette(&"shadow_glow_hero")


# ================================================================ hooks

## Variant piece: 0 = Veyra (hood up), 1 = Vesper (hood down, braid). Safe before _ready.
func set_variant(v: int) -> void:
	variant = clampi(v, 0, 1)
	if _variant_node:
		_variant_node.mesh = _variant_mesh(variant)
	ChampionFaces.switch(_face, "mage_archer", _face_spec, variant)


## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## Face styles (FaceKit, faces pass 2026-09-28). Pale lilac skin (shadow_skin), violet irises with the kingdom glow, a
## cool calm look, silver-lilac brows, dusky mauve lips. Her hair is the Variant mesh: Veyra (A, hood up) the silver-
## lilac cheek locks, Vesper (B, hood down) the hair cap + the braid, with a straighter, sterner brow. No ears (hood / hair
## cap cover them).
static func _face_spec(v: int) -> Dictionary:
	var hair := Color(0.80, 0.74, 0.92)
	var spec := {"center": HEAD_C, "radius": HEAD_R, "head_mesh": sphere(HEAD_R), "head_scale": Vector3(0.92, 1.05, 0.95),
		"preset": &"gentle" if v == 0 else &"stern", "skin": Color(0.62, 0.60, 0.70), "hair": hair,
		"hair_tip": Color(0.93, 0.88, 1.0), "eyes": GLOW, "ears": &"none",
		"palette": {"iris_glow": 0.4, "brow": Color(0.66, 0.60, 0.80), "lash": Color(0.10, 0.06, 0.14),
			"lip": Color(0.55, 0.36, 0.52), "lip_line": Color(0.26, 0.12, 0.26), "blush": Color(0.72, 0.52, 0.70)}}
	return spec


## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Her weapon never changes (tier3-extras.md 6.4, ChampionType.weapon_override): the mage bow.
func weapon_override() -> StringName:
	return WEAPON_OVERRIDE


## Rises out of the ground (the Dread Paddock's circle) in CALL_LEN s, then call_finished. Attacks / casts asked during
## the rise are ignored (she is not up yet). Safe before _ready (plays once ready). No-op while dead.
func play_call() -> void:
	if not _ready_done:
		_call_pending = true
		return
	_call_pending = false
	if _dead:
		return
	_calling = false
	super.play_cast(CALL_ID)
	_calling = true
	if _call_motes and _tier < 2:
		_call_motes.restart()
	_animate(0.0)


## True while play_call() plays.
func is_calling() -> bool:
	return _calling


func play_cast(spell_id: StringName) -> void:
	if _calling:
		return
	super.play_cast(spell_id)


func play_attack() -> void:
	if _calling:
		return
	super.play_attack()


func play_death() -> void:
	_calling = false
	super.play_death()


## Where her arrows and shot skills leave (world space): the arrow head on the bow.
func get_beam_origin() -> Vector3:
	if not is_inside_tree() or not _ready_done:
		return position + Vector3.UP * body_height * 0.75
	if _bow:
		return _bow.global_transform * Vector3(0.025, 0.0, 0.30)
	return global_position + Vector3.UP * body_height * 0.75


## The rune quiver's centre (world space), e.g. where Eclipse Volley's shafts rise from.
func get_quiver_origin() -> Vector3:
	if not is_inside_tree() or not _ready_done or _quiver == null:
		return position + Vector3.UP * 1.6
	return _quiver.global_transform * Vector3(0.0, 0.2, 0.0)


# ================================================================ champion class weapons (weapon_override)

## weapon_override &"mage_bow": no class piece is ever merged, she keeps her bow.
func _weapon_pieces(_class_id: StringName) -> Array[StringName]:
	var none: Array[StringName] = []
	return none


func _weapon_slot(slot: StringName) -> Transform3D:
	match slot:
		&"hand_r":
			return Transform3D(Basis.IDENTITY, GRIP_R)
		&"hand_l":
			return Transform3D(Basis.IDENTITY, HAND_L)
	return super._weapon_slot(slot)


## The kit set the class's attack style (staff_bolt for the Wizard class): the bow's comes back.
func _on_weapon_class(_class_id: StringName) -> void:
	attack_style = ATTACK_STYLE
	attack_windup = ATTACK_WINDUP


# ================================================================ parts

func _part(pivot: Node3D, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		keep: bool = false, part_name: String = "") -> MeshInstance3D:
	_authored += 1
	return add_part(pivot, mesh, mat, at, rot_deg, Vector3.ONE, keep, part_name)


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	_authored = 0
	# ---- Legs: dark leggings, tall pointed boots with silver cuffs and knee cops
	_part(leg_l, _leg_mesh(-1.0), null, Vector3.ZERO)
	_part(leg_r, _leg_mesh(1.0), null, Vector3.ZERO)
	# ---- Hips: the long coat skirt (open front, team lining, silver hem), belt, pouch, team sash
	_part(hips, _skirt_mesh(), null, Vector3.ZERO)
	_part(hips, _belt_mesh(), null, Vector3.ZERO)
	# ---- Chest: bodice + corset + silver neckline + brooch; the half cape; the floating rune quiver
	_part(chest, _torso_mesh(), null, Vector3.ZERO)
	_part(chest, _cape_mesh(), null, Vector3.ZERO)
	_quiver = _part(chest, _quiver_mesh(0), null, QUIVER_AT, Vector3(-5.0, 0.0, 0.0), true, "Quiver")
	_quiver.set_meta(&"own_glow", true)
	var motes := make_motes(GLOW, 6, 1.6, 0.20, 0.16, 0.05)
	motes.name = "QuiverMotes"
	motes.position = Vector3(0.0, 0.25, 0.0)
	_quiver.add_child(motes)
	var death := make_motes(GLOW, 14, 1.0, 0.25, 1.2, 0.07, false, true)
	death.name = "DeathMotes"
	death.set_meta(&"death_fx", true)
	_quiver.add_child(death)
	# ---- Head: face, eyes, circlet; the variant piece (hood up / hood down + braid)
	_part(head, _face_mesh(), null, Vector3.ZERO)
	_variant_node = _part(head, _variant_mesh(variant), null, Vector3.ZERO, Vector3.ZERO, true, "Variant")
	_face = ChampionFaces.attach(self, head, "mage_archer", _face_spec, variant)
	# ---- Arms: sleeves, gloves; right pauldron + bracer; left bell sleeve. The bow in the right fist.
	_part(arm_l, _arm_mesh(-1.0), null, Vector3.ZERO)
	_part(arm_r, _arm_mesh(1.0), null, Vector3.ZERO)
	_bow = _part(arm_r, _bow_mesh(false), null, GRIP_R, Vector3.ZERO, true, "Bow")
	_bow.set_meta(&"own_glow", true)
	_spark = make_motes(GLOW, 12, 0.5, 0.05, 1.8, 0.07, false, true)
	_spark.name = "ReleaseSparks"
	_spark.position = ARROW_TIP
	_bow.add_child(_spark)
	# ---- the call ring (play_call): violet motes rising from a ring round her feet
	_call_motes = make_motes(GLOW, 24, 1.3, 0.75, 2.2, 0.08, true, true)
	_call_motes.name = "CallMotes"
	_call_motes.position = Vector3(0.0, 0.05, 0.0)
	var fx := get_node_or_null(^"Fx")
	if fx:
		fx.add_child(_call_motes)
	else:
		add_child(_call_motes)
	ensure_shadow_blob(0.5, Color(0.05, 0.03, 0.08, 0.45))


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	if _variant_node:
		_variant_node.mesh = _variant_mesh(variant)
	_q_rest = (Basis(Vector3.BACK, -8.0 * DEG) * Basis(Vector3.RIGHT, 10.0 * DEG) * Basis(Vector3.UP, -90.0 * DEG)).get_rotation_quaternion()
	_up_basis = Basis(Vector3.UP, -90.0 * DEG)
	_rest_dir_r = (GRIP_R - SHOULDER_R).normalized()
	_rest_dir_l = (HAND_L - SHOULDER_L).normalized()
	_arm_len_r = (GRIP_R - SHOULDER_R).length()
	_arm_len_l = (HAND_L - SHOULDER_L).length()
	if _quiver:
		_quiver_base = _quiver.position
	_bow_q_w = Quaternion(9, 9, 9, 9)
	_extra_process(0.0)
	if _call_pending:
		play_call()


## Euler (deg) that turns a primitive's +Y axis along d.
static func _euler_down(d: Vector3) -> Vector3:
	return Basis(Quaternion(Vector3.UP, d.normalized())).get_euler() / DEG


# ================================================================ mesh building (static, cached once per game)

static func _bucket() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedInt32Array()]


## Appends primitive `m` (surface 0) transformed by xf.
static func _put(acc: Array, m: Mesh, xf: Transform3D) -> void:
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
		acc[2].append(uv[j] if j < uv.size() else Vector2.ZERO)
	if ix.is_empty():
		for j: int in v.size():
			acc[3].append(b0 + j)
	else:
		for j: int in ix.size():
			acc[3].append(b0 + ix[j])


## Grid normals: central differences (wrap_u = closed along u), each turned toward hints[k].
static func _grid_normals(pts: PackedVector3Array, hints: PackedVector3Array, cols: int, rows: int,
		wrap_u: bool) -> PackedVector3Array:
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
	return norms


## A (cols+1) x (rows+1) grid of points (row-major) into acc, fronts facing the hints (Godot fronts are clockwise).
## inner != []: also the back side, inset along -normal, reversed, into that bucket (a lining of another colour).
static func _grid(acc: Array, pts: PackedVector3Array, hints: PackedVector3Array, cols: int, rows: int,
		wrap_u: bool, inner: Array = [], inset: float = 0.0, uvs: PackedVector2Array = PackedVector2Array()) -> void:
	var w := cols + 1
	var norms := _grid_normals(pts, hints, cols, rows, wrap_u)
	for side: int in (1 if inner.is_empty() else 2):
		var dst: Array = acc if side == 0 else inner
		var s: float = 1.0 if side == 0 else -1.0
		var b0: int = (dst[0] as PackedVector3Array).size()
		for k: int in pts.size():
			dst[0].append(pts[k] - norms[k] * inset if side == 1 else pts[k])
			dst[1].append(norms[k] * s)
			dst[2].append(uvs[k] if k < uvs.size() else Vector2.ZERO)
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
					dst[3].append(b0 + a)
					dst[3].append(b0 + b)
					dst[3].append(b0 + c)


## Surface of revolution: profile (r, y) points, `seg` segments; xf places it. Normals from the profile.
static func _lathe(acc: Array, prof: PackedVector2Array, seg: int, xf: Transform3D = Transform3D.IDENTITY) -> void:
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	var n := prof.size()
	for j: int in n:
		var t := prof[mini(j + 1, n - 1)] - prof[maxi(j - 1, 0)]
		var n2 := Vector2(t.y, -t.x)
		for i: int in seg + 1:
			var a := TAU * float(i) / float(seg)
			pts.append(xf * Vector3(sin(a) * prof[j].x, prof[j].y, cos(a) * prof[j].x))
			hints.append(xf.basis * Vector3(sin(a) * n2.x, n2.y, cos(a) * n2.x))
	_grid(acc, pts, hints, seg, n - 1, true)


## [cylinder from a to b] (radius ra at a, rb at b), flattened across the axis by sx / sz.
static func _seg(acc: Array, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6, sx: float = 1.0,
		sz: float = 1.0, caps: bool = false) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.0001:
		return
	var bs := Basis(Quaternion(Vector3.UP, d / l)).scaled_local(Vector3(sx, l, sz))
	_put(acc, cyl(rb, ra, 1.0, seg, caps), Transform3D(bs, (a + b) * 0.5))


## A tube through the points (joints rounded by small spheres), radius r0 -> r1 along it.
static func _tube(acc: Array, pts: Array[Vector3], r0: float, r1: float, seg: int = 6) -> void:
	var n := pts.size()
	for k: int in n - 1:
		var ra := lerpf(r0, r1, float(k) / float(n - 1))
		var rb := lerpf(r0, r1, float(k + 1) / float(n - 1))
		_seg(acc, pts[k], pts[k + 1], ra, rb, seg)
		if k > 0:
			_put(acc, sphere(ra, seg, 3), _xf(pts[k]))


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
	_ma_meshes[key] = am
	return am


static func _xf(at: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), at)


## Catmull-Rom through pts at t (0..1 over the whole polyline, uniform per span).
static func _crom(pts: Array[Vector3], t: float) -> Vector3:
	var n := pts.size()
	var f := clampf(t, 0.0, 1.0) * float(n - 1)
	var i := mini(int(f), n - 2)
	var u := f - float(i)
	var p0 := pts[maxi(i - 1, 0)]
	var p1 := pts[i]
	var p2 := pts[i + 1]
	var p3 := pts[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)


# ---------------------------------------------------------------- legs

## One leg (model space): dark legging, a tall boot with a pointed toe, silver cuff and knee cop.
static func _leg_mesh(side: float) -> ArrayMesh:
	var key := "leg%d" % int(side)
	if _ma_meshes.has(key):
		return _ma_meshes[key]
	var robe := _bucket()
	var dark := _bucket()
	var sil := _bucket()
	var x := 0.12 * side
	var xb := 0.125 * side
	_seg(robe, Vector3(x, 0.76, 0.0), Vector3(xb, 0.44, 0.012), 0.086, 0.072, 8)
	_put(robe, sphere(0.086, 8, 4), _xf(Vector3(x, 0.76, 0.0)))
	_seg(dark, Vector3(xb, 0.07, 0.0), Vector3(xb, 0.50, 0.012), 0.072, 0.083, 8)
	_put(dark, box(Vector3(0.13, 0.08, 0.20)), _xf(Vector3(xb, 0.04, 0.035)))
	_put(dark, sphere(0.075, 8, 4), _xf(Vector3(xb, 0.045, 0.15), Vector3.ZERO, Vector3(0.85, 0.6, 1.55)))
	_put(dark, box(Vector3(0.10, 0.05, 0.08)), _xf(Vector3(xb, 0.025, -0.065)))
	_put(sil, cyl(0.093, 0.09, 0.045, 10), _xf(Vector3(xb, 0.50, 0.012)))
	_put(sil, sphere(0.068, 8, 4), _xf(Vector3(xb, 0.555, 0.07), Vector3(-10, 0, 0), Vector3(1.0, 1.35, 0.55)))
	_put(sil, box(Vector3(0.11, 0.014, 0.23)), _xf(Vector3(xb, 0.006, 0.05)))
	return _commit(key, [[robe, _robe()], [dark, _dark()], [sil, _silver()]])


# ---------------------------------------------------------------- hips

## Coat skirt point: angle a from +Z (front) toward +X, v 0 (waist) -> 1 (hem). The back hangs longer and flares.
static func _skirt_point(a: float, v: float, grow: float = 0.0) -> Vector3:
	var back := maxf(0.0, -cos(a))
	var side := absf(sin(a))
	var r := 0.205 + 0.13 * pow(v, 1.2) + 0.07 * back * back * v * v + 0.012 * sin(7.0 * a + 0.6) * v + grow
	var hem := 0.46 - 0.26 * back * back - 0.04 * side
	return Vector3(sin(a) * r, lerpf(1.03, hem, v), cos(a) * r * 0.9)


## Panel angle: the front stays open (12 deg at the waist -> 40 deg at the hem), the back splits from mid-thigh.
static func _skirt_angle(u: float, v: float, right: bool) -> float:
	var open := lerpf(12.0, 40.0, pow(v, 0.9)) * DEG
	var split := maxf(0.0, (v - 0.40) / 0.60) * 12.0 * DEG
	if right:
		return lerpf(open, PI - split, u)
	return lerpf(PI + split, TAU - open, u)


static func _skirt_panel(acc: Array, inner: Array, right: bool, u0: float, u1: float, v0: float, v1: float, cols: int,
		rows: int, grow: float) -> void:
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in rows + 1:
		var v := lerpf(v0, v1, float(j) / float(rows))
		for i: int in cols + 1:
			var a := _skirt_angle(lerpf(u0, u1, float(i) / float(cols)), v, right)
			var p := _skirt_point(a, v, grow)
			pts.append(p)
			hints.append(Vector3(p.x, 0.0, p.z))
	_grid(acc, pts, hints, cols, rows, false, inner, 0.012)


static func _skirt_mesh() -> ArrayMesh:
	if _ma_meshes.has("skirt"):
		return _ma_meshes["skirt"]
	var robe := _bucket()
	var lining := _bucket()
	var sil := _bucket()
	for right: bool in [true, false]:
		_skirt_panel(robe, lining, right, 0.0, 1.0, 0.0, 1.0, 12, 8, 0.0)
		_skirt_panel(sil, [], right, 0.0, 1.0, 0.91, 1.0, 12, 1, 0.006)              # hem band
		if right:
			_skirt_panel(sil, [], true, 0.0, 0.06, 0.0, 1.0, 1, 8, 0.005)          # front edge trims
		else:
			_skirt_panel(sil, [], false, 0.94, 1.0, 0.0, 1.0, 1, 8, 0.005)
	return _commit("skirt", [[robe, _robe()], [lining, _team()], [sil, _silver()]])


## Belt with a silver buckle, a pouch on the right hip, the team sash knot and two tails on the left hip.
static func _belt_mesh() -> ArrayMesh:
	if _ma_meshes.has("belt"):
		return _ma_meshes["belt"]
	var dark := _bucket()
	var sil := _bucket()
	var team := _bucket()
	var zs := Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.9)), Vector3.ZERO)
	_lathe(dark, PackedVector2Array([Vector2(0.212, 0.972), Vector2(0.218, 1.005), Vector2(0.212, 1.038)]), 16, zs)
	_put(sil, box(Vector3(0.095, 0.08, 0.03)), _xf(Vector3(0.0, 1.005, 0.198)))
	_put(dark, box(Vector3(0.05, 0.035, 0.03)), _xf(Vector3(0.0, 1.005, 0.206)))
	_put(dark, box(Vector3(0.11, 0.13, 0.065)), _xf(Vector3(0.20, 0.92, 0.07), Vector3(0, 62, 0)))
	_put(sil, box(Vector3(0.115, 0.045, 0.07)), _xf(Vector3(0.20, 0.975, 0.07), Vector3(0, 62, 0)))
	_put(team, sphere(0.055, 8, 4), _xf(Vector3(-0.15, 1.0, 0.15), Vector3(0, -30, 0), Vector3(1.3, 1.0, 0.8)))
	_put(team, box(Vector3(0.075, 0.38, 0.018)), _xf(Vector3(-0.16, 0.80, 0.15), Vector3(-6, -30, 5)))
	_put(team, box(Vector3(0.062, 0.29, 0.018)), _xf(Vector3(-0.19, 0.84, 0.12), Vector3(-4, -42, 13)))
	return _commit("belt", [[dark, _dark()], [sil, _silver()], [team, _team()]])


# ---------------------------------------------------------------- chest

## Bodice (lathe, flattened front-back), dark corset band with silver rims, the silver V neckline, the cape brooch.
static func _torso_mesh() -> ArrayMesh:
	if _ma_meshes.has("torso"):
		return _ma_meshes["torso"]
	var robe := _bucket()
	var dark := _bucket()
	var sil := _bucket()
	var zs := Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.84)), Vector3.ZERO)
	_lathe(robe, PackedVector2Array([Vector2(0.195, 1.00), Vector2(0.188, 1.10), Vector2(0.20, 1.20), Vector2(0.222, 1.30),
		Vector2(0.226, 1.37), Vector2(0.212, 1.44), Vector2(0.175, 1.50), Vector2(0.12, 1.545), Vector2(0.07, 1.565)]), 14, zs)
	var zc := Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.86)), Vector3.ZERO)
	_lathe(dark, PackedVector2Array([Vector2(0.200, 1.04), Vector2(0.206, 1.10), Vector2(0.199, 1.17)]), 14, zc)
	_lathe(sil, PackedVector2Array([Vector2(0.203, 1.028), Vector2(0.209, 1.037), Vector2(0.203, 1.046)]), 14, zc)
	_lathe(sil, PackedVector2Array([Vector2(0.202, 1.162), Vector2(0.208, 1.171), Vector2(0.202, 1.18)]), 14, zc)
	for sx: float in [-1.0, 1.0]:
		_seg(sil, Vector3(0.12 * sx, 1.49, 0.13), Vector3(0.0, 1.335, 0.196), 0.016, 0.016, 5)
	_put(sil, sphere(0.024, 6, 3), _xf(Vector3(0.0, 1.335, 0.196)))
	# the brooch that pins the half cape (front of the left shoulder) and its short chain to the cape corner
	_put(sil, cyl(0.052, 0.052, 0.026, 10), _xf(Vector3(-0.21, 1.53, 0.09), Vector3(70, 0, 20)))
	_put(dark, sphere(0.026, 6, 3), _xf(Vector3(-0.205, 1.535, 0.105)))
	_seg(sil, Vector3(-0.21, 1.53, 0.09), Vector3(-0.29, 1.60, 0.01), 0.011, 0.011, 4)
	return _commit("torso", [[robe, _robe()], [dark, _dark()], [sil, _silver()]])


## The half cape (banner cloth: UV.y 0 at the shoulder, waves lower down): pinned over the LEFT shoulder, hanging
## behind the left arm and down the back to the back of the knees, ending right of the spine. Curved grid (Catmull-Rom
## top and hem edges), bulging away from the body.
static func _cape_mesh() -> ArrayMesh:
	if _ma_meshes.has("cape"):
		return _ma_meshes["cape"]
	var acc := _bucket()
	var top: Array[Vector3] = [Vector3(-0.30, 1.61, 0.00), Vector3(-0.36, 1.60, -0.08), Vector3(-0.32, 1.56, -0.18),
		Vector3(-0.18, 1.52, -0.24), Vector3(-0.02, 1.49, -0.255), Vector3(0.13, 1.47, -0.235)]
	var hem: Array[Vector3] = [Vector3(-0.52, 1.05, -0.24), Vector3(-0.53, 0.82, -0.27), Vector3(-0.43, 0.63, -0.34),
		Vector3(-0.25, 0.54, -0.38), Vector3(-0.04, 0.52, -0.385), Vector3(0.12, 0.58, -0.34)]
	const COLS := 15
	const ROWS := 8
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	var uvs := PackedVector2Array()
	for j: int in ROWS + 1:
		var v := float(j) / float(ROWS)
		for i: int in COLS + 1:
			var u := float(i) / float(COLS)
			var a := _crom(top, u)
			var b := _crom(hem, u)
			var p := a.lerp(b, v)
			var out := Vector3(p.x, 0.0, p.z + 0.02).normalized()
			p += out * 0.05 * sin(PI * v) * (0.6 + 0.4 * v)
			pts.append(p)
			hints.append(out)
			uvs.append(Vector2(u, v))
	_grid(acc, pts, hints, COLS, ROWS, false, [], 0.0, uvs)
	return _commit("cape", [[acc, _cape_mat()]])


## The floating rune quiver in its own space (origin = the halo centre, +Y up; faces -Z = away from her back): five
## dark shafts converging on a silver base ring below, fanned up through a silver rune halo with glowing ticks, each
## with a glowing violet head (the second glow point) and silver fletching. fan 1 = opened wide and lifted (volleys).
static func _quiver_mesh(fan: int) -> ArrayMesh:
	var key := "quiver%d" % fan
	if _ma_meshes.has(key):
		return _ma_meshes[key]
	var dark := _bucket()
	var sil := _bucket()
	var glow := _bucket()
	var step := 13.0 if fan == 0 else 30.0
	var halo := 1.0 if fan == 0 else 1.3
	var base := Vector3(0.0, -0.42, 0.0)
	for i: int in 5:
		var ang := float(i - 2) * step * DEG
		var dir := Vector3(-sin(ang), cos(ang), 0.0)
		var len_i := 0.80 - 0.05 * absf(float(i - 2))
		var a := base + dir * 0.06
		var b := base + dir * len_i
		_seg(dark, a, b, 0.016, 0.016, 6)
		var hb := Basis(Quaternion(Vector3.UP, dir))
		# head: a long diamond (two cones), glowing
		_put(glow, cyl(0.0, 0.05, 0.13, 6), Transform3D(hb, b + dir * 0.065))
		_put(glow, cyl(0.05, 0.0, 0.045, 6), Transform3D(hb, b - dir * 0.0225))
		# fletching: 3 silver fins near the base
		for f: int in 3:
			var fb := hb * Basis(Vector3.UP, TAU * float(f) / 3.0)
			_put(sil, box(Vector3(0.006, 0.10, 0.045)), Transform3D(fb, a + dir * 0.09 + fb * Vector3(0, 0, 0.022)))
	# the rune halo (in the XY plane) with 6 glowing ticks, and the base ring
	_put(sil, torus(0.170 * halo, 0.195 * halo, 22), _xf(Vector3.ZERO, Vector3(90, 0, 0)))
	for k: int in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		var p := Vector3(sin(a), cos(a), 0.0) * 0.1825 * halo
		_put(glow, box(Vector3(0.035, 0.035, 0.03)), _xf(p, Vector3(0, 0, -rad_to_deg(a) + 45.0)))
	_put(sil, torus(0.04, 0.065, 12), _xf(base + Vector3(0, 0.03, 0), Vector3(90, 0, 0)))
	_put(sil, sphere(0.04, 8, 4), _xf(base))
	return _commit(key, [[dark, _dark()], [sil, _silver()], [glow, _glow()]])


# ---------------------------------------------------------------- head

## Neck, face (a pointed chin), nose, the silver circlet (its back hides in the hood / hair). The eyes, brows and lips
## are the FaceKit Face node (faces pass 2026-09-28; the old dark eye lumps are gone).
static func _face_mesh() -> ArrayMesh:
	if _ma_meshes.has("face"):
		return _ma_meshes["face"]
	var skin := _bucket()
	var sil := _bucket()
	_seg(skin, Vector3(0.0, 1.52, -0.005), Vector3(0.0, 1.66, 0.005), 0.062, 0.058, 8)
	_put(skin, sphere(HEAD_R), _xf(HEAD_C, Vector3.ZERO, Vector3(0.92, 1.05, 0.95)))
	_put(skin, sphere(0.075, 8, 4), _xf(Vector3(0.0, 1.625, 0.095), Vector3.ZERO, Vector3(0.95, 0.9, 1.0)))
	_put(skin, sphere(0.028, 6, 3), _xf(Vector3(0.0, 1.712, 0.188), Vector3.ZERO, Vector3(0.8, 1.2, 1.0)))
	_put(sil, torus(0.162, 0.178, 20), _xf(Vector3(0.0, 1.80, 0.025), Vector3(-14, 0, 0), Vector3(0.95, 1.0, 1.0)))
	_put(sil, cyl(0.0, 0.026, 0.06, 4), _xf(Vector3(0.0, 1.79, 0.198), Vector3(180, 0, 0)))
	return _commit("face", [[skin, _skin()], [sil, _silver()]])


## Hood point: u across the hood (0 = the opening's right edge, 1 = its left edge, going round the back), v 0 = the
## peak -> 1 = the mantle hem on the shoulders. Face opening widest at the eyes, closed under the chin; the brim
## overhangs the face; the crown is drawn up and back into a drooping peak.
static func _hood_point(u: float, v: float, grow: float = 0.0) -> Vector3:
	var th := lerpf(0.0, 2.5, v)
	var op := 0.92 * smoothstep(0.30, 0.85, th) * (1.0 - smoothstep(1.80, 2.30, th)) + 0.06
	var ph := lerpf(op, TAU - op, u)
	var flare := smoothstep(1.5, 2.5, th)
	var r := 0.212 + 0.13 * flare + grow
	var xs := 1.0 + 0.30 * flare
	var p := HOOD_C + Vector3(sin(th) * sin(ph) * r * xs, cos(th) * r * 1.06, sin(th) * cos(ph) * r)
	var edge := 1.0 - smoothstep(0.0, 0.10, minf(u, 1.0 - u))
	p.z += 0.045 * edge * (1.0 - flare)
	var w := pow(1.0 - clampf(th, 0.0, 1.0), 2.0)
	return p.lerp(HOOD_TIP + Vector3(0, grow, -grow), w)


## The variant piece (model space, Head pivot). 0 = the hood up (team cloth outside, dark lining, silver brim and hem
## trims) + two silver locks at the cheeks; 1 = hood down: silver-lilac hair, a long braid over the right shoulder
## (team ribbon), the rolled cowl round the neck and the hood lying on the upper back (its peak down the spine).
static func _variant_mesh(v: int) -> ArrayMesh:
	var key := "variant%d" % v
	if _ma_meshes.has(key):
		return _ma_meshes[key]
	var team := _bucket()
	var robe := _bucket()
	var sil := _bucket()
	if v == 0:
		const COLS := 18   # was 22 x 14 (faces pass 2026-09-28: pays part of the face)
		const ROWS := 12
		var pts := PackedVector3Array()
		var hints := PackedVector3Array()
		for j: int in ROWS + 1:
			var vv := float(j) / float(ROWS)
			for i: int in COLS + 1:
				var uu := float(i) / float(COLS)
				var p := _hood_point(uu, vv)
				pts.append(p)
				hints.append(p - _hood_point(uu, vv, -0.02))
		_grid(team, pts, hints, COLS, ROWS, false, robe, 0.016)
		# silver trims: the brim (both edges of the opening) and the mantle hem
		for side: float in [0.0, 1.0]:
			var edge: Array[Vector3] = []
			for j: int in range(2, ROWS + 1):
				edge.append(_hood_point(side, float(j) / float(ROWS), 0.004))
			_tube(sil, edge, 0.015, 0.013, 5)
		var hem: Array[Vector3] = []
		for i: int in COLS + 1:
			hem.append(_hood_point(float(i) / float(COLS), 1.0, 0.004))
		_tube(sil, hem, 0.013, 0.013, 5)
		# two locks of hair at the cheeks
		for sx: float in [-1.0, 1.0]:
			var lock: Array[Vector3] = [Vector3(0.12 * sx, 1.77, 0.10), Vector3(0.145 * sx, 1.66, 0.125),
				Vector3(0.14 * sx, 1.57, 0.15)]
			_tube(sil, lock, 0.032, 0.018, 6)
	else:
		# hair: a cap over the crown and back (open at the face below the hairline), parted fringe
		const HC := 18
		const HR := 9
		var pts := PackedVector3Array()
		var hints := PackedVector3Array()
		var hc := Vector3(0.0, 1.735, 0.0)
		for j: int in HR + 1:
			var th := lerpf(0.0, 1.95, float(j) / float(HR))
			var op := 0.95 * smoothstep(0.62, 1.05, th) + 0.001
			for i: int in HC + 1:
				var ph := lerpf(op, TAU - op, float(i) / float(HC))
				var d := Vector3(sin(th) * sin(ph), cos(th) * 1.04, sin(th) * cos(ph) * 1.02)
				pts.append(hc + d * 0.19)
				hints.append(d)
		_grid(sil, pts, hints, HC, HR, false)
		# the braid: from behind the right ear over the shoulder, down the front to the waist; team ribbon, tuft
		var path: Array[Vector3] = [Vector3(0.11, 1.66, -0.12), Vector3(0.20, 1.55, -0.06), Vector3(0.245, 1.44, 0.10),
			Vector3(0.225, 1.30, 0.225), Vector3(0.205, 1.16, 0.245), Vector3(0.19, 1.04, 0.245)]
		const LOBES := 12
		for i: int in LOBES:
			var t := float(i) / float(LOBES - 1)
			var p := _crom(path, t)
			var d := (_crom(path, minf(t + 0.02, 1.0)) - _crom(path, maxf(t - 0.02, 0.0))).normalized()
			var r := lerpf(0.058, 0.040, t)
			var side := Vector3(0.016 if i % 2 == 0 else -0.016, 0, 0)
			_put(sil, sphere(r, 7, 3), Transform3D(Basis(Quaternion(Vector3.UP, d)).scaled_local(Vector3(1.0, 1.5, 0.9)), p + side))
		var end := path[path.size() - 1]
		_put(team, cyl(0.036, 0.036, 0.045, 8), _xf(end + Vector3(0, -0.04, 0)))
		_put(sil, cyl(0.03, 0.06, 0.11, 8), _xf(end + Vector3(0, -0.11, 0.005)))
		# the rolled cowl round the neck (team) with a silver edge, the hood lying on the upper back + its peak
		_lathe(team, PackedVector2Array([Vector2(0.15, 1.50), Vector2(0.215, 1.515), Vector2(0.245, 1.565),
			Vector2(0.215, 1.625), Vector2(0.15, 1.62)]), 16, Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.95)), Vector3(0, 0, -0.03)))
		_lathe(sil, PackedVector2Array([Vector2(0.20, 1.50), Vector2(0.222, 1.505), Vector2(0.20, 1.515)]), 16,
			Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.95)), Vector3(0, 0, -0.03)))
		_put(team, sphere(0.2, 12, 6), _xf(Vector3(0.0, 1.47, -0.25), Vector3(-12, 0, 0), Vector3(1.15, 0.85, 0.45)))
		_seg(team, Vector3(0.0, 1.40, -0.30), Vector3(0.0, 1.13, -0.33), 0.085, 0.0, 8)
		_put(robe, sphere(0.15, 10, 5), _xf(Vector3(0.0, 1.49, -0.205), Vector3(-12, 0, 0), Vector3(1.1, 0.7, 0.3)))
	return _commit(key, [[team, _team()], [robe, _robe()], [sil, _silver()]])


# ---------------------------------------------------------------- arms and bow

## One arm (model space): sleeve, glove; right = silver-rimmed pauldron + archer's bracer with silver bands;
## left = a flared bell cuff with a silver edge.
static func _arm_mesh(side: float) -> ArrayMesh:
	var key := "arm%d" % int(side)
	if _ma_meshes.has(key):
		return _ma_meshes[key]
	var robe := _bucket()
	var dark := _bucket()
	var sil := _bucket()
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var hand := GRIP_R if side > 0.0 else HAND_L
	var wrist := sh.lerp(hand, 0.86)
	_seg(robe, sh, wrist, 0.072, 0.06, 8)
	_put(robe, sphere(0.08, 8, 4), _xf(sh + Vector3(0.0, 0.01, 0.0)))
	_put(dark, sphere(0.058, 8, 4), _xf(hand, Vector3.ZERO, Vector3(0.95, 1.15, 0.95)))
	if side > 0.0:
		_put(dark, sphere(0.13, 10, 5), _xf(sh + Vector3(0.025, 0.07, 0.0), Vector3(0, 0, -20), Vector3(1.1, 0.72, 1.12)))
		_put(dark, sphere(0.12, 10, 5), _xf(sh + Vector3(0.06, 0.0, 0.0), Vector3(0, 0, -30), Vector3(1.05, 0.5, 1.06)))
		_put(sil, torus(0.118, 0.14, 16), _xf(sh + Vector3(0.03, 0.05, 0.0), Vector3(0, 0, -20), Vector3(1.0, 1.0, 1.02)))
		_put(sil, sphere(0.03, 6, 3), _xf(sh + Vector3(0.05, 0.155, 0.0)))
		_seg(dark, sh.lerp(hand, 0.52), sh.lerp(hand, 0.84), 0.07, 0.066, 8, 1.0, 1.0, true)
		for t: float in [0.58, 0.79]:
			_seg(sil, sh.lerp(hand, t - 0.02), sh.lerp(hand, t + 0.02), 0.075, 0.072, 8, 1.0, 1.0, true)
	else:
		_seg(robe, sh.lerp(hand, 0.55), sh.lerp(hand, 0.86), 0.066, 0.108, 10)
		_seg(sil, sh.lerp(hand, 0.85), sh.lerp(hand, 0.88), 0.108, 0.112, 10, 1.0, 1.0, false)
		_seg(dark, sh.lerp(hand, 0.80), hand, 0.05, 0.052, 8)
	return _commit(key, [[robe, _robe()], [dark, _dark()], [sil, _silver()]])


## The mage bow in grip space (origin = the fist, limbs along Y, back toward +Z, string toward -Z): obsidian recurve
## limbs (2.1 m tip to tip) with silver recurve tips and back fins, a wrapped grip with silver bands, the glowing violet
## string. drawn: the limbs flex, the string makes a V to the nock NOCK behind the grip and an arrow of violet light
## lies on the bow.
static func _bow_mesh(drawn: bool) -> ArrayMesh:
	var key := "bow%d" % int(drawn)
	if _ma_meshes.has(key):
		return _ma_meshes[key]
	var wood := _bucket()
	var sil := _bucket()
	var glow := _bucket()
	var flex := 1.3 if drawn else 1.0
	var ys := 0.97 if drawn else 1.0
	var n := LIMB.size()
	for sy: float in [1.0, -1.0]:
		for k: int in n - 1:
			var a := Vector3(0, LIMB[k].x * sy * ys, LIMB[k].y * (flex if k > 0 else 1.0))
			var b := Vector3(0, LIMB[k + 1].x * sy * ys, LIMB[k + 1].y * flex)
			var ra := lerpf(0.044, 0.022, float(k) / float(n - 1))
			var rb := lerpf(0.044, 0.022, float(k + 1) / float(n - 1))
			_seg(sil if k >= n - 3 else wood, a, b, ra, rb, 6, 1.25, 1.0)
			if k > 0:
				_put(sil if k >= n - 2 else wood, sphere(ra, 6, 3), _xf(a, Vector3.ZERO, Vector3(1.25, 1.0, 1.0)))
		var tip := Vector3(0, LIMB[n - 1].x * sy * ys, LIMB[n - 1].y * flex)
		_put(sil, sphere(0.03, 6, 3), _xf(tip))
		# a silver fin on the back of each limb (the "blade" of the bow)
		var f0 := Vector3(0, 0.30 * sy * ys, -0.04 * flex + 0.035)
		var f1 := Vector3(0, 0.62 * sy * ys, -0.13 * flex + 0.035)
		_seg(sil, f0, f1, 0.012, 0.004, 4, 1.0, 2.2)
	_put(wood, cyl(0.05, 0.05, 0.22, 8), _xf(Vector3.ZERO))
	for y: float in [-0.115, 0.115]:
		_put(sil, cyl(0.056, 0.056, 0.03, 8), _xf(Vector3(0, y, 0)))
	_put(sil, box(Vector3(0.03, 0.03, 0.05)), _xf(Vector3(0.035, 0.03, 0.0)))
	var su := Vector3(0, STRING_Y * ys, STRING_Z * flex)
	var sd := Vector3(0, -STRING_Y * ys, STRING_Z * flex)
	if drawn:
		var nock := Vector3(0, 0, -NOCK)
		_seg(glow, sd, nock, 0.02, 0.02, 5)
		_seg(glow, nock, su, 0.02, 0.02, 5)
		_put(glow, sphere(0.02, 6, 3), _xf(nock))
		# the arrow of light: shaft, a long diamond head, three small vanes
		_seg(glow, Vector3(0.025, 0, -NOCK + 0.02), Vector3(0.025, 0, ARROW_TIP.z - 0.10), 0.013, 0.013, 5)
		_put(glow, cyl(0.0, 0.04, 0.12, 6), _xf(Vector3(0.025, 0, ARROW_TIP.z - 0.04), Vector3(90, 0, 0)))
		_put(glow, cyl(0.04, 0.0, 0.04, 6), _xf(Vector3(0.025, 0, ARROW_TIP.z - 0.12), Vector3(90, 0, 0)))
		for f: int in 3:
			_put(glow, box(Vector3(0.006, 0.045, 0.09)), _xf(Vector3(0.025, 0, -NOCK + 0.09), Vector3(0, 0, 120.0 * f)) *
				Transform3D(Basis(), Vector3(0, 0.024, 0)))
	else:
		_seg(glow, sd, su, 0.02, 0.02, 5)
	return _commit(key, [[wood, _dark()], [sil, _silver()], [glow, _glow()]])


# ================================================================ animation

## Aim the bow: k = weight of the raise (0-1), elev = degrees above the horizon, draw = string pulled (0-1),
## kl = weight of the drawing (left) arm. Solved each frame (a few basis ops, no allocation): the chest turns the bow
## shoulder toward the target, the arrow line runs from the anchor under her chin (AIM_NOCK) along the aim; the bow
## arm points at the grip on that line, the bow stands upright on it (back to the target), and the left hand goes to
## the string (at rest brace -> the nock as it draws).
func _aim(k: float, elev: float, draw: float, kl: float) -> void:
	var e := elev * DEG
	var chest_e := Vector3(-elev / 5.0 * DEG, AIM_CHEST_YAW * DEG, 0.0)
	var chest_b := Basis.from_euler(chest_e)
	var chest_inv := chest_b.inverse()
	var co := CHEST_O
	var dir := Vector3(0.0, sin(e), cos(e))
	var sh_r := co + chest_b * (SHOULDER_R - co)
	var arm_d := (AIM_NOCK + dir * NOCK - sh_r).normalized()
	rot(P_ARM_R, Basis(Quaternion(_rest_dir_r, chest_inv * arm_d)).get_euler() * k)
	var grip := sh_r + arm_d * _arm_len_r
	var hand_t := grip - dir * lerpf(-STRING_Z, NOCK, clampf(draw, 0.0, 1.0))
	var sh_l := co + chest_b * (SHOULDER_L - co)
	var to_h := hand_t - sh_l
	var l_d := chest_inv * to_h.normalized()
	rot(P_ARM_L, Basis(Quaternion(_rest_dir_l, l_d)).get_euler() * kl)
	pos(P_ARM_L, l_d * clampf(to_h.length() - _arm_len_l, -0.12, 0.10) * kl)
	rot(P_CHEST, chest_e * k)
	rot(P_HEAD, Vector3(-elev * 0.15 * DEG * k, -AIM_CHEST_YAW * 0.85 * DEG * k, 0))
	rot(P_LEG_R, Vector3(-9.0 * DEG * k, 0, 0))
	rot(P_LEG_L, Vector3(7.0 * DEG * k, 0, 0))
	if k > _bow_k:
		_bow_k = k
		_bow_e = e
	_bow_draw = maxf(_bow_draw, draw)


## Attack `arcane_bow`: raise and draw (0 - windup), loose at the windup (string snap, sparks), hold, lower.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != ATTACK_STYLE:
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else ATTACK_WINDUP
	var k := _k3(t, 0.0, w * 0.8, w + 0.14, SHOT_LEN, 1.0, 1.0)
	var d := _k3(t, 0.0, w, w, w + 0.03, 1.0, 1.0)
	_aim(k, 4.0, d, k)
	pos(P_ROOT, Vector3(0, 0, _k3(t, w, w + 0.04, w + 0.08, SHOT_LEN, -0.05, -0.02)))
	_hold = maxf(_hold, 1.2 * d)
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < SHOT_LEN


func _pose_class_skill(id: StringName, t: float) -> float:
	match id:
		&"arc_bolt":
			return _pose_snap_shot(t)
		&"starfall":
			# Shot straight up (82 deg), the string stays lit while the star falls; head back.
			var rel := 0.42
			var k := _k3(t, 0.0, 0.28, 0.85, 1.2, 1.0, 1.0)
			var d := _k3(t, 0.10, rel, rel, rel + 0.03, 1.0, 1.0)
			_aim(k, 82.0, d, k)
			rot(P_HEAD, Vector3(-16.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, -0.04 * k, 0))
			_hold = maxf(_hold, 2.2 * _k3(t, 0.10, rel, 0.9, 1.2, 1.0, 1.0))
			_release_at(t, rel, 3.0)
			return 1.2
		&"slipstep":
			# The kit's blink (fade to a sliver, gone, back with an overshoot) + a quiver flash on both ends.
			var ln := super._pose_class_skill(id, t)
			_quiver_hold = maxf(_quiver_hold, 2.0 * (1.0 - clampf(absf(t - 0.15) / 0.2, 0.0, 1.0)))
			return ln
	return super._pose_class_skill(id, t)


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		CALL_ID:
			return _pose_call(t)
		&"sable_shaft":
			# A heavy charged draw (the string blazes), knees bent, a wide stance; the loose throws her back.
			var rel := 0.55
			var k := _k3(t, 0.0, 0.30, rel + 0.16, 1.0, 1.0, 1.0)
			var d := _k3(t, 0.08, rel, rel, rel + 0.03, 1.0, 1.0)
			_aim(k, 2.0, d, k)
			pos(P_ROOT, Vector3(0, -0.06 * k, _k3(t, rel, rel + 0.05, rel + 0.12, 1.0, -0.14, -0.08)))
			rot(P_CHEST, Vector3(_k3(t, 0.10, rel, rel + 0.05, 1.0, -6.0, 5.0) * DEG, 0, 0))
			rot(P_LEG_L, Vector3(-8.0 * DEG * k, 0, -5.0 * DEG * k))
			rot(P_LEG_R, Vector3(6.0 * DEG * k, 0, 6.0 * DEG * k))
			_hold = maxf(_hold, 2.8 * d)
			_quiver_hold = maxf(_quiver_hold, 1.2 * d)
			_release_at(t, rel, 3.0)
			return 1.0
		&"grave_mark":
			# The free hand points the mark at the target (a jab at 0.34), the bow arm drops back, the quiver flares.
			var rel := 0.34
			var k := _k3(t, 0.0, 0.22, 0.55, 0.8, 1.0, 1.0)
			var p := _k3(t, rel - 0.06, rel, rel + 0.03, rel + 0.25, 1.0, 1.0)
			rot(P_ARM_L, Vector3(-96.0 * DEG * k, 10.0 * DEG * k, 0))
			pos(P_ARM_L, Vector3(0.04 * k, 0.02 * k, 0.04 * k + 0.06 * p))
			rot(P_CHEST, Vector3(0, 22.0 * DEG * k, 0))
			rot(P_HEAD, Vector3(4.0 * DEG * k, -12.0 * DEG * k, 0))
			rot(P_ARM_R, Vector3(14.0 * DEG * k, 0, 8.0 * DEG * k))
			rot(P_LEG_L, Vector3(-8.0 * DEG * k, 0, 0))
			_quiver_hold = maxf(_quiver_hold, 2.4 * p)
			_hold = maxf(_hold, 0.8 * p)
			_release_at(t, rel, 0.6)
			return 0.8
		&"eclipse_volley":
			# Aimed high (68 deg); the quiver fan opens and rises over her head, blazes at the loose, closes after.
			var rel := 0.52
			var k := _k3(t, 0.0, 0.30, rel + 0.20, 1.3, 1.0, 1.0)
			var d := _k3(t, 0.12, rel, rel, rel + 0.03, 1.0, 1.0)
			_aim(k, 68.0, d, k)
			pos(P_ROOT, Vector3(0, -0.05 * k, 0))
			_fan = maxf(_fan, _k3(t, 0.10, 0.40, 0.95, 1.25, 1.0, 1.0))
			_quiver_hold = maxf(_quiver_hold, 2.6 * _k3(t, 0.10, rel, rel + 0.08, 1.1, 1.0, 1.0))
			_hold = maxf(_hold, 1.8 * d)
			_release_at(t, rel, 3.0)
			return 1.3
		&"gravity_well":
			# The free hand swirls down to the ground in a spiral, a crouch; the bow held out; a flash at 0.50.
			var k := _k3(t, 0.0, 0.25, 0.75, 1.0, 1.0, 1.0)
			var sw := clampf((t - 0.08) / 0.45, 0.0, 1.0)
			var c := _k3(t, 0.20, 0.48, 0.70, 1.0, 1.0, 1.0)
			rot(P_ARM_L, Vector3(lerpf(-125.0, 5.0, _ease_in(sw)) * DEG * k, 0, -32.0 * sin(sw * TAU * 1.25) * DEG * k))
			rot(P_ARM_R, Vector3(-22.0 * DEG * k, 0, 12.0 * DEG * k))
			rot(P_CHEST, Vector3(20.0 * DEG * c, 10.0 * DEG * k, 0))
			rot(P_HEAD, Vector3(10.0 * DEG * c, 0, 0))
			pos(P_ROOT, Vector3(0, -0.13 * c, 0))
			rot(P_LEG_L, Vector3(-26.0 * DEG * c, 0, 0))
			rot(P_LEG_R, Vector3(16.0 * DEG * c, 0, 0))
			_quiver_hold = maxf(_quiver_hold, 2.0 * _k3(t, 0.44, 0.50, 0.56, 0.85, 1.0, 1.0))
			_release_at(t, 0.50, 1.2)
			return 1.0
		&"comet_rain":
			# Three quick high shots (0.38, 0.68, 0.98), the string re-drawn between them.
			var k := _k3(t, 0.0, 0.22, 1.12, 1.4, 1.0, 1.0)
			var d := 0.0
			for r: float in COMET_RELS:
				d = maxf(d, _k3(t, r - 0.22, r, r, r + 0.03, 1.0, 1.0))
			_aim(k, 64.0, d, k)
			pos(P_ROOT, Vector3(0, -0.03 * k, 0))
			_hold = maxf(_hold, 1.6 * d)
			_quiver_hold = maxf(_quiver_hold, 1.0 * k)
			while _shots < COMET_RELS.size() and t >= COMET_RELS[_shots]:
				_shots += 1
				_loose(2.0)
			return 1.4
		&"astral_form":
			# Arms open: the bow held upright high out to the side, the free arm spread, chest up, head back, a lift;
			# every glow up and the quiver fan open.
			var k := _k3(t, 0.0, 0.35, 0.85, 1.2, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-20.0 * DEG * k, 0, 62.0 * DEG * k))
			rot(P_ARM_L, Vector3(-20.0 * DEG * k, 0, -70.0 * DEG * k))
			rot(P_CHEST, Vector3(-10.0 * DEG * k, 0, 0))
			rot(P_HEAD, Vector3(-16.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, 0.07 * k, 0))
			_bow_up = maxf(_bow_up, k)
			_hold = maxf(_hold, 2.6 * k)
			_quiver_hold = maxf(_quiver_hold, 2.6 * k)
			_fan = maxf(_fan, k)
			_release_at(t, 0.35, 1.0)
			return 1.2
		_:
			return _pose_snap_shot(t)


## Arc Bolt (and unknown ids): a snap shot, raise 0.12, loose at 0.20, a sharp recoil.
func _pose_snap_shot(t: float) -> float:
	var rel := 0.20
	var k := _k3(t, 0.0, 0.12, rel + 0.12, 0.6, 1.0, 1.0)
	var d := _k3(t, 0.02, rel, rel, rel + 0.03, 1.0, 1.0)
	_aim(k, 8.0, d, k)
	pos(P_ROOT, Vector3(0, 0, _k3(t, rel, rel + 0.04, rel + 0.08, 0.6, -0.07, -0.03)))
	_hold = maxf(_hold, 2.0 * d)
	_release_at(t, rel, 2.2)
	return 0.6


## play_call(): she rises out of the ground (0.15-1.2 s) head bowed, the bow hand at her side, the string lit; she
## straightens (0.9-1.4) and lifts the bow upright over her head with the quiver fanned open (flash at 1.5), then lowers
## it (2.0). The blob fades in as she rises.
func _pose_call(t: float) -> float:
	var rise := _ease_out(clampf((t - 0.15) / 1.05, 0.0, 1.0))
	pos(P_ROOT, Vector3(0, -CALL_DEPTH * (1.0 - rise), 0))
	var bowed := 1.0 - smoothstep(0.9, 1.4, t)
	rot(P_HEAD, Vector3(28.0 * DEG * bowed, 0, 0))
	rot(P_CHEST, Vector3(12.0 * DEG * bowed, 0, 0))
	rot(P_ARM_L, Vector3(-50.0 * DEG * bowed, 38.0 * DEG * bowed, 0))
	var f := _k3(t, 1.2, 1.5, 1.72, 2.0, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-150.0 * DEG * f, 0, 8.0 * DEG * f))
	pos(P_ARM_R, Vector3(0, 0.06 * f, 0))
	rot(P_ARM_L, Vector3(0, 0, -35.0 * DEG * f))
	rot(P_HEAD, Vector3(-10.0 * DEG * f, 0, 0))
	_bow_up = maxf(_bow_up, f)
	_hold = maxf(_hold, 1.5 * (1.0 - rise) + 3.0 * f)
	_quiver_hold = maxf(_quiver_hold, 2.5 * f)
	_fan = maxf(_fan, _k3(t, 1.25, 1.45, 1.75, 1.95, 1.0, 1.0))
	if _shadow:
		_shadow.transparency = 1.0 - smoothstep(0.6, 1.2, t)
	_release_at(t, 1.5, 2.5)
	return CALL_LEN


## Riding (she buys a Roan Courser at level 7): the kit's rider pose, the bow arm rolled out so the long lower limb
## hangs clear of the mount's shoulder.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	super._pose_seated(w, gait, gallop, moving)
	if _action == &"":
		rot(P_ARM_R, Vector3(-8.0 * DEG * w, 0, 16.0 * DEG * w))


func _release_at(t: float, rel: float, flare: float) -> void:
	if not _fired and t >= rel:
		_fired = true
		_loose(flare)


## One loose: the string flares, the quiver jolts, sparks off the arrow head.
func _loose(flare: float) -> void:
	_flare = maxf(_flare, flare)
	_qflare = maxf(_qflare, flare * 0.5)
	_qkick = 1.0
	if _spark and _tier < 2:
		_spark.restart()


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"cast_start":
			_fired = false
			_shots = 0
		&"cast_end":
			if _cast_id == CALL_ID and _calling:
				_calling = false
				if _shadow:
					_shadow.transparency = 0.0
				call_finished.emit()
		&"release":
			_loose(1.4)
		&"level_up":
			_flare = maxf(_flare, 2.5)
			_qflare = maxf(_qflare, 2.0)
		&"death_glow_off":
			_qkick = 1.0


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	# ---- Bow: rest grip -> upright and perpendicular to the raised arm (aim) -> upright in model space (_bow_up).
	var k := clampf(_bow_k, 0.0, 1.0)
	var up := clampf(_bow_up, 0.0, 1.0)
	var drawn: int = 1 if (_bow_draw > 0.5 and not _dead) else 0
	_bow_k = 0.0
	_bow_up = 0.0
	_bow_draw = 0.0
	if _bow:
		var q := _q_rest
		if k > 0.0 or up > 0.0:
			# the arm's model-space frame this frame (the pivots rest unrotated), to hold the bow in model space
			var ab_inv := (Basis.from_euler(_off_rot[P_ROOT]) * Basis.from_euler(_off_rot[P_CHEST])
				* Basis.from_euler(_off_rot[P_ARM_R])).inverse()
			if k > 0.0:
				q = q.slerp((ab_inv * Basis(Vector3.RIGHT, -_bow_e)).get_rotation_quaternion(), k)
			if up > 0.0:
				q = q.slerp((ab_inv * _up_basis).get_rotation_quaternion(), up)
		if not q.is_equal_approx(_bow_q_w):
			_bow_q_w = q
			_bow.quaternion = q
		if drawn != _drawn_w:
			_drawn_w = drawn
			_bow.mesh = _bow_mesh(drawn == 1)
	# ---- Glows: string and quiver x veterancy / haste (0 once dead), flares on looses and level-ups.
	_flare = maxf(0.0, _flare - dt * 2.4)
	_qflare = maxf(0.0, _qflare - dt * 2.0)
	var gl := glow_level()
	var g := gl * (STRING_BASE + _flare + _hold)
	_hold = 0.0
	if _bow and g != _bow_glow_w:
		_bow_glow_w = g
		_bow.set_instance_shader_parameter(&"glow_boost", g)
	var qg := gl * (QUIVER_BASE + _qflare + _quiver_hold)
	_quiver_hold = 0.0
	if _quiver and qg != _quiver_glow_w:
		_quiver_glow_w = qg
		_quiver.set_instance_shader_parameter(&"glow_boost", qg)
	# ---- Quiver: floats on its own (bob, slow sway), jolts on a loose, opens and rises for the volleys.
	var lift := clampf(_fan, 0.0, 1.0)
	var fan: int = 1 if (lift > 0.5 and not _dead) else 0
	_fan = 0.0
	_qkick = maxf(0.0, _qkick - dt * 4.0)
	if _quiver == null:
		return
	if fan != _fan_w:
		_fan_w = fan
		_quiver.mesh = _quiver_mesh(fan)
	if _tier >= 1 and _action == &"" and _walk_w == 0.0 and not _dead and lift == 0.0 and _qkick == 0.0:
		return
	var ph := _t + _phase_off
	var bob := 0.03 * sin(ph * 2.1) + 0.02 * _walk_w * sin(TAU * _walk_p * 2.0)
	var p := _quiver_base + Vector3(0.0, bob + 0.24 * lift - 0.04 * _qkick, -0.05 * lift + 0.04 * _qkick)
	var r := Vector3((-5.0 - 10.0 * lift) * DEG, 0.0, (4.0 * sin(ph * 0.9) + 5.0 * _qkick * sin(ph * 17.0)) * DEG)
	var xf := Transform3D(Basis.from_euler(r), p)
	if not xf.is_equal_approx(_quiver_xf_w):
		_quiver_xf_w = xf
		_quiver.transform = xf


func _on_revive() -> void:
	if _face:
		_face.reset()
	_flare = 0.0
	_qflare = 0.0
	_qkick = 0.0
	_hold = 0.0
	_quiver_hold = 0.0
	_fan = 0.0
	_fired = false
	_shots = 0
	_calling = false
	_bow_q_w = Quaternion(9, 9, 9, 9)
	_drawn_w = -1
	_bow_glow_w = -1.0
	_quiver_glow_w = -1.0
	_fan_w = -1
	_quiver_xf_w = Transform3D(Basis.IDENTITY, Vector3(999, 0, 0))
