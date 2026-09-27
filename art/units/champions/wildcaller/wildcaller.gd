extends CharacterModel
## The Wildcaller (titans-2.md 5 / 11, task 13c.V5): the Nature kingdom's unique NPC, "Maelis Oakenhollow" (A) /
## "Corwen Oakenhollow" (B). An old druid of the deep wood. THE READ at 40 m: a dark, stooped, cloaked figure (the only
## dark mass in a bright green-and-pink army) under a team-green deep hood with TALL PALE ANTLERS rising from it (a
## narrow lyre, ~0.65 m across, 2.5 m high: not Ysolde's wide blossoming rack), a moss collar over a FEATHER CAPELET on
## wide shoulders and a FEATHERED CLOAK flaring to the ground, both barred brown and pale (no other unit wears that
## barring, the read from the game camera); beside her a LIVING STAFF far taller than her
## (2.8 m): a gnarled shaft wound by a vine, team ribbons, and a CROWN of five curling branches that cradle a glowing
## heart-bud, ringed by pink blossoms with glowing cores (the glow point at 40 m). Close up: an old face deep in the hood
## with two faint green eyes, grey locks, a team stole down the robe, a rope belt with a curved call horn, a bone-and-
## feather fetish, pouches and a herb bundle; a ruff of stiff feathers behind the neck.
## Variant B (set_variant(1)) = Corwen: hood down (a rolled cowl, the hood lying on his back), a grey mane, bushy brows
## and a long BRAIDED BEARD down the chest (team ribbon, wooden bead); his antlers grow from a circlet of woven twigs.
## Hooks (all safe before _ready): the kit ones (CharacterModel) + set_variant(v), play_call() (+ signal call_finished,
## is_calling()), weapon_override() -> &"wild_staff", get_beam_origin() (the crown heart), get_crown_origin() (same),
## get_staff_foot(), authored_mesh_count().
## Attack style `thorn_bolt` (0.55 s, release = attack_windup 0.15): the staff cocks up, then the crown is thrust at the
## target (40 deg over the horizon) with the free palm pushing; sparks at the crown on the release. Casts (play_cast):
## her own thornsnare (the staff lifted high and DRIVEN foot-first into the ground in front, a crouch, the free arm sweeps
## out; strike 0.5), call_the_pack (the staff raised straight overhead in full bloom, the head thrown back, the free hand
## cupped at the mouth: a howl at 0.55), wild_stampede (a low wind-up to the right, then the staff swept forward and
## LEVELLED along the line, a long step; release 0.62, bloom); the Wizard-tree actives arc_bolt (a snap thrust), slipstep
## (the kit's blink + a crown flash), starfall (the crown straight up at the sky), gravity_well (the free hand spirals down
## to the ground, a crouch, the crown pressed forward and low), comet_rain (three pumps of the crown at the sky),
## astral_form (arms open, the staff held upright high out to the side, full bloom, every glow up); unknown ids play the
## snap thrust. play_call() (2.0 s): she rises out of the ground (the Elder Circle's root knot) with the staff held
## straight overhead, so its glowing crown breaks the ground first, inside a rising ring of green motes; then she plants
## the staff beside her (foot strikes at 1.55: flash, full bloom) and lifts her head.
## Walk: the kit's, stooped a little (4 deg), shorter strides. Seated (kit rider, she buys a Roan Courser at L7): the
## staff arm rolls out and the staff is held upright, its foot outside the mount's flank.
## Champion classes: `weapon_override &"wild_staff"` (titans-2.md 5.4): set_weapon_class(any class) keeps the staff (no kit
## piece is merged, `_weapon_pieces` is empty) and restores attack_style `thorn_bolt` / windup 0.15.
## Death `fall` (Nature): the kit fall, the staff goes down with the arm, the crown closes and dies, pink motes scatter.
## Idle / hit / level-up / revive: the kit (+ the crown breathes: a slow glow pulse at close range, a few rising motes).
## Budget: 13 authored meshes (blob included), 14 draw instances (7 merged pivots + Staff, Variant, blob, 4 particle
## systems: CrownMotes looping, ReleaseSparks, DeathMotes, CallMotes one-shot), 0 lights, 0 own materials: 8 shared Nature
## palette materials (nature_cloth, nature_bark_dark, nature_leaf_dark (the moss), nature_stone, nature_bark, nature_skin,
## nature_blossom, nature_glow_hero) + the kit blob. Team colour: the hood (A) / rolled cowl (B), the stole and the staff
## ribbons (nature_cloth only).

## Emitted when play_call() has finished (she stands on the ground).
signal call_finished

const NAT_DIR := "res://art/units/nature/materials/"
const GLOW := Color(0.75, 1.00, 0.40)
const PINK := Color(0.95, 0.60, 0.75)
const SHOULDER_R := Vector3(0.30, 1.48, 0.0)
const SHOULDER_L := Vector3(-0.30, 1.48, 0.0)
const GRIP_R := Vector3(0.45, 1.02, 0.20)          # right fist = the staff grip (model space, rest pose)
const HAND_L := Vector3(-0.40, 0.98, 0.10)
const HEAD_C := Vector3(0.0, 1.71, 0.045)
const HEAD_R := 0.16
const HOOD_C := Vector3(0.0, 1.735, 0.02)
const CHEST_O := Vector3(0.0, 1.08, 0.0)
## The staff in grip space: +Y along the shaft. Foot 1.0 below the fist, the crown's branches start at 1.26, the heart at
## 1.50, the crown tips at ~1.78 (model ~2.8 m).
const FOOT := 1.0
const CROWN_BASE_Y := 1.26
const HEART_Y := 1.50
const REST_AXIS := Vector3(0.07, 0.995, 0.07)       # top 4 deg outward, 4 deg forward (normalised at use)
const SEAT_AXIS := Vector3(-0.22, 1.0, 0.12)        # seated: foot out past the mount's flank
const ATTACK_STYLE := &"thorn_bolt"
const ATTACK_WINDUP := 0.15
const ATTACK_LEN := 0.55
const CROWN_BASE := 1.3                             # glow_boost of the crown at rest (energy 3 x 1.3)
const WEAPON_OVERRIDE := &"wild_staff"
const CALL_ID := &"wildcaller_call"
const CALL_LEN := 2.0
const CALL_DEPTH := 3.4                             # she starts this far under the ground (the raised crown at 0)
const CALL_PLANT := 1.55
const OWN_CAST_IDS: Array[StringName] = [&"thornsnare", &"call_the_pack", &"wild_stampede"]
const TREE_CAST_IDS: Array[StringName] = [&"arc_bolt", &"slipstep", &"starfall", &"gravity_well", &"comet_rain",
	&"astral_form"]
const COMET_RELS: Array[float] = [0.38, 0.68, 0.98]

## 0 = Maelis (hood up), 1 = Corwen (hood down, braided beard). Change it with set_variant().
@export_range(0, 1) var variant: int = 0

static var _wc_meshes: Dictionary = {}
static var _wc_mats: Dictionary = {}

var _authored: int = 0
var _staff: MeshInstance3D
var _variant_node: MeshInstance3D
var _spark: GPUParticles3D           # one-shot sparks at the crown heart on every release
var _call_motes: GPUParticles3D      # one-shot ring of rising motes (play_call)
var _q_rest: Quaternion = Quaternion.IDENTITY

# per-frame targets written by the poses (reset in _extra_process)
var _st_k: float = 0.0               # 0 = the staff rides the fist at rest, 1 = it points along _st_d (model space)
var _st_d: Vector3 = Vector3.UP
var _bloom: float = 0.0              # > 0.5: the crown opens into full bloom
var _hold: float = 0.0               # extra crown glow held by a pose
# state
var _flare: float = 0.0
var _fired: bool = false
var _shots: int = 0
var _calling: bool = false
var _call_pending: bool = false
var _staff_q_w: Quaternion = Quaternion(9, 9, 9, 9)
var _bloom_w: int = -1
var _glow_w: float = -1.0


static func _nat(name: String) -> Material:
	if not _wc_mats.has(name):
		_wc_mats[name] = load(NAT_DIR + name + ".tres")
	return _wc_mats[name]


static func _team() -> Material:
	return _nat("nature_cloth")


static func _robe() -> Material:
	return _nat("nature_bark_dark")


static func _moss() -> Material:
	return _nat("nature_leaf_dark")


static func _feather() -> Material:
	return _nat("nature_stone")


static func _wood() -> Material:
	return _nat("nature_bark")


static func _skin() -> Material:
	return _nat("nature_skin")


static func _petal() -> Material:
	return _nat("nature_blossom")


static func _glow() -> Material:
	return _nat("nature_glow_hero")


# ================================================================ hooks

## Variant piece: 0 = Maelis (hood up), 1 = Corwen (hood down, braided beard). Safe before _ready.
func set_variant(v: int) -> void:
	variant = clampi(v, 0, 1)
	if _variant_node:
		_variant_node.mesh = _variant_mesh(variant)


## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## Her weapon never changes (titans-2.md 5.4, ChampionType.weapon_override): the living staff.
func weapon_override() -> StringName:
	return WEAPON_OVERRIDE


## Rises out of the ground (the Elder Circle's root knot) in CALL_LEN s, then call_finished. Attacks / casts asked during
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


## Where her thorn bolts and cast effects leave (world space): the glowing heart in the staff's crown.
func get_beam_origin() -> Vector3:
	if not is_inside_tree() or not _ready_done or _staff == null:
		return position + Vector3.UP * 2.5
	return _staff.global_transform * Vector3(0.0, HEART_Y, 0.0)


## The crown heart (world space), e.g. where the call / revive column and Call the Pack's mist gather.
func get_crown_origin() -> Vector3:
	return get_beam_origin()


## The staff's foot (world space), e.g. where Thornsnare's strike touches the ground in front of her.
func get_staff_foot() -> Vector3:
	if not is_inside_tree() or not _ready_done or _staff == null:
		return position
	return _staff.global_transform * Vector3(0.0, -FOOT, 0.0)


# ================================================================ champion class weapons (weapon_override)

## weapon_override &"wild_staff": no class piece is ever merged, she keeps her staff.
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


## The kit set the class's attack style (staff_bolt for the Wizard class): the thorn bolt comes back.
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
	# ---- Legs: dark leggings, wrapped leather boots (mostly under the robe)
	_part(leg_l, _leg_mesh(-1.0), null, Vector3.ZERO)
	_part(leg_r, _leg_mesh(1.0), null, Vector3.ZERO)
	# ---- Hips: the long robe (mossy ragged hem), the rope belt with the call horn, pouches, fetish, herbs
	_part(hips, _skirt_mesh(), null, Vector3.ZERO)
	_part(hips, _belt_mesh(), null, Vector3.ZERO)
	# ---- Chest: robe top + team stole; the moss mantle + feather ruff; the long feathered cloak
	_part(chest, _torso_mesh(), null, Vector3.ZERO)
	_part(chest, _mantle_mesh(), null, Vector3.ZERO)
	_part(chest, _cloak_mesh(), null, Vector3.ZERO)
	# ---- Head: old face, faint glowing eyes, brows; the variant piece (hood + antlers / mane + beard + antler circlet)
	_part(head, _face_mesh(), null, Vector3.ZERO)
	_variant_node = _part(head, _variant_mesh(variant), null, Vector3.ZERO, Vector3.ZERO, true, "Variant")
	# ---- Arms: bell sleeves with moss cuffs, old hands; the living staff in the right fist
	_part(arm_l, _arm_mesh(-1.0), null, Vector3.ZERO)
	_part(arm_r, _arm_mesh(1.0), null, Vector3.ZERO)
	_staff = _part(arm_r, _staff_mesh(0), null, GRIP_R, Vector3.ZERO, true, "Staff")
	_staff.set_meta(&"own_glow", true)
	var motes := make_motes(GLOW, 6, 1.8, 0.16, 0.14, 0.05)
	motes.name = "CrownMotes"
	motes.position = Vector3(0.0, HEART_Y, 0.0)
	_staff.add_child(motes)
	_spark = make_motes(GLOW, 14, 0.5, 0.08, 1.9, 0.07, false, true)
	_spark.name = "ReleaseSparks"
	_spark.position = Vector3(0.0, HEART_Y, 0.0)
	_staff.add_child(_spark)
	var death := make_motes(PINK, 16, 1.1, 0.26, 1.0, 0.07, false, true)
	death.name = "DeathMotes"
	death.set_meta(&"death_fx", true)
	death.position = Vector3(0.0, HEART_Y, 0.0)
	_staff.add_child(death)
	# ---- the call ring (play_call): green motes rising from a ring round her feet (the root knot)
	_call_motes = make_motes(GLOW, 26, 1.4, 0.8, 2.4, 0.08, true, true)
	_call_motes.name = "CallMotes"
	_call_motes.position = Vector3(0.0, 0.05, 0.0)
	var fx := get_node_or_null(^"Fx")
	if fx:
		fx.add_child(_call_motes)
	else:
		add_child(_call_motes)
	ensure_shadow_blob(0.55, Color(0.04, 0.05, 0.02, 0.5))


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	if _variant_node:
		_variant_node.mesh = _variant_mesh(variant)
	_q_rest = Quaternion(Vector3.UP, REST_AXIS.normalized())
	_staff_q_w = Quaternion(9, 9, 9, 9)
	if _staff:
		_staff.quaternion = _q_rest
	_extra_process(0.0)
	if _call_pending:
		play_call()


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


## A smooth tube: `samples` Catmull-Rom points through the control points, radius r0 -> r1, a rounded tip.
static func _branch(acc: Array, ctrl: Array[Vector3], samples: int, r0: float, r1: float, seg: int = 6) -> void:
	var pts: Array[Vector3] = []
	for i: int in samples:
		pts.append(_crom(ctrl, float(i) / float(samples - 1)))
	_tube(acc, pts, r0, r1, seg)
	_put(acc, sphere(r1, seg, 3), _xf(pts[pts.size() - 1]))


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
	_wc_meshes[key] = am
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


## A flat lens (feather / leaf / petal): centre c, long axis `along` (length), lying across `across` (width), thin
## along their normal. Right-handed basis so the faces keep their winding.
static func _lens(acc: Array, c: Vector3, along: Vector3, across: Vector3, length: float, width: float,
		thick: float) -> void:
	var z := along.normalized()
	var x := (across - z * across.dot(z)).normalized()
	var y := z.cross(x)
	_put(acc, sphere(0.5, 6, 3), Transform3D(Basis(x * width, y * thick, z * length), c))


## One blossom: 5 petals radiating around `n` (the way it faces), cupped by (1 - open), a glowing core.
static func _blossom(petals: Array, glow: Array, c: Vector3, n: Vector3, s: float, open: float) -> void:
	var y := n.normalized()
	var b := Basis(Quaternion(Vector3.UP, y))
	var tilt := lerpf(42.0, 10.0, open) * DEG
	for i: int in 5:
		var ang := TAU * float(i) / 5.0 + 0.3
		var radial := b * Vector3(sin(ang), 0.0, cos(ang))
		var dir := (radial * cos(tilt) + y * sin(tilt)).normalized()
		var side := y.cross(radial).normalized()
		_lens(petals, c + dir * 0.034 * s, dir, side, 0.075 * s, 0.052 * s, 0.014 * s)
	_put(glow, sphere(0.024 * s, 6, 3), _xf(c + y * 0.008 * s))


# ---------------------------------------------------------------- legs

## One leg (model space): dark legging, a wrapped leather boot with a rounded toe, two wrap bands.
static func _leg_mesh(side: float) -> ArrayMesh:
	var key := "leg%d" % int(side)
	if _wc_meshes.has(key):
		return _wc_meshes[key]
	var robe := _bucket()
	var wood := _bucket()
	var x := 0.11 * side
	var xb := 0.115 * side
	_seg(robe, Vector3(x, 0.74, 0.0), Vector3(xb, 0.24, 0.01), 0.085, 0.068, 8)
	_put(robe, sphere(0.085, 8, 4), _xf(Vector3(x, 0.74, 0.0)))
	_seg(wood, Vector3(xb, 0.05, 0.0), Vector3(xb, 0.30, 0.01), 0.074, 0.080, 8)
	_put(wood, box(Vector3(0.13, 0.08, 0.20)), _xf(Vector3(xb, 0.04, 0.035)))
	_put(wood, sphere(0.072, 8, 4), _xf(Vector3(xb, 0.045, 0.14), Vector3.ZERO, Vector3(0.9, 0.62, 1.4)))
	for y: float in [0.13, 0.22]:
		_seg(robe, Vector3(xb, y - 0.018, 0.005), Vector3(xb, y + 0.018, 0.005), 0.084, 0.084, 8, 1.0, 1.0, true)
	return _commit(key, [[robe, _robe()], [wood, _wood()]])


# ---------------------------------------------------------------- hips

## Robe point: angle a from +Z (front) toward +X, v 0 (waist) -> 1 (hem). Deep folds, a longer back, a ragged hem.
static func _robe_point(a: float, v: float, grow: float = 0.0) -> Vector3:
	var back := maxf(0.0, -cos(a))
	var r := 0.20 + 0.155 * pow(v, 1.1) + 0.02 * back * v + 0.016 * sin(9.0 * a + 0.4) * v + grow
	var hem := 0.09 - 0.05 * back - 0.035 * absf(sin(6.5 * a + 1.1))
	return Vector3(sin(a) * r, lerpf(1.03, hem, v), cos(a) * r * 0.92)


static func _robe_band(acc: Array, v0: float, v1: float, rows: int, grow: float) -> void:
	const COLS := 30
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in rows + 1:
		var v := lerpf(v0, v1, float(j) / float(rows))
		for i: int in COLS + 1:
			var a := TAU * float(i) / float(COLS)
			var p := _robe_point(a, v, grow)
			pts.append(p)
			hints.append(Vector3(p.x, 0.0, p.z))
	_grid(acc, pts, hints, COLS, rows, true)


static func _skirt_mesh() -> ArrayMesh:
	if _wc_meshes.has("skirt"):
		return _wc_meshes["skirt"]
	var robe := _bucket()
	var moss := _bucket()
	_robe_band(robe, 0.0, 1.0, 9, 0.0)
	_robe_band(moss, 0.86, 1.0, 2, 0.01)                # the mossy, dragged hem
	return _commit("skirt", [[robe, _robe()], [moss, _moss()]])


## Rope belt with a knot, the curved CALL HORN on the left hip (ivory, dark bands, a cord), a pouch on the right hip, a
## herb bundle at the right back, a bone-and-feather fetish at the front right.
static func _belt_mesh() -> ArrayMesh:
	if _wc_meshes.has("belt"):
		return _wc_meshes["belt"]
	var wood := _bucket()
	var dark := _bucket()
	var skin := _bucket()
	var fea := _bucket()
	var moss := _bucket()
	var zs := Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.92)), Vector3.ZERO)
	_lathe(wood, PackedVector2Array([Vector2(0.212, 0.975), Vector2(0.226, 0.99), Vector2(0.226, 1.01),
		Vector2(0.212, 1.025)]), 18, zs)
	_put(wood, sphere(0.04, 8, 4), _xf(Vector3(-0.07, 0.99, 0.205), Vector3.ZERO, Vector3(1.3, 1.0, 0.8)))
	for k: int in 2:
		var sx := -0.06 - 0.03 * float(k)
		_seg(wood, Vector3(sx, 0.98, 0.21), Vector3(sx - 0.02, 0.78 + 0.05 * float(k), 0.235), 0.013, 0.011, 5)
		_put(wood, sphere(0.02, 6, 3), _xf(Vector3(sx - 0.02, 0.78 + 0.05 * float(k), 0.235)))
	# the call horn: hung on a cord from the belt at the left hip, mouth forward-down
	var horn: Array[Vector3] = [Vector3(-0.19, 0.95, 0.13), Vector3(-0.245, 0.86, 0.10), Vector3(-0.265, 0.76, 0.02),
		Vector3(-0.25, 0.68, -0.07), Vector3(-0.22, 0.64, -0.13)]
	var hp: Array[Vector3] = []
	for i: int in 9:
		hp.append(_crom(horn, float(i) / 8.0))
	_tube(skin, hp, 0.016, 0.058, 8)
	_put(dark, cyl(0.062, 0.062, 0.02, 10), Transform3D(Basis(Quaternion(Vector3.UP, (hp[8] - hp[7]).normalized())), hp[8]))
	for t: float in [0.3, 0.62]:
		var p := _crom(horn, t)
		var d := (_crom(horn, t + 0.03) - _crom(horn, t - 0.03)).normalized()
		_put(dark, cyl(0.03 + 0.03 * t, 0.03 + 0.03 * t, 0.022, 8), Transform3D(Basis(Quaternion(Vector3.UP, d)), p))
	_seg(dark, Vector3(-0.19, 0.99, 0.15), Vector3(-0.19, 0.95, 0.13), 0.008, 0.008, 4)
	_seg(dark, Vector3(-0.23, 0.99, 0.06), Vector3(-0.255, 0.72, -0.01), 0.008, 0.008, 4)
	# pouch on the right hip
	_put(wood, sphere(0.075, 8, 4), _xf(Vector3(0.21, 0.90, 0.07), Vector3(0, 62, 0), Vector3(1.0, 1.1, 0.65)))
	_put(dark, box(Vector3(0.12, 0.04, 0.08)), _xf(Vector3(0.212, 0.965, 0.07), Vector3(0, 62, 0)))
	# herb bundle at the right back (moss sprigs tied with a band)
	for k: int in 4:
		var a := 0.3 * float(k) - 0.45
		_seg(moss, Vector3(0.17, 0.97, -0.13), Vector3(0.20 + 0.04 * sin(a), 0.74, -0.18 + 0.04 * cos(a)), 0.02, 0.035, 5)
	_put(dark, cyl(0.035, 0.035, 0.03, 8), _xf(Vector3(0.175, 0.93, -0.14)))
	# fetish at the front right: a cord, a small bone, two feathers
	_seg(dark, Vector3(0.10, 0.98, 0.205), Vector3(0.11, 0.84, 0.23), 0.007, 0.007, 4)
	_put(skin, sphere(0.034, 6, 3), _xf(Vector3(0.11, 0.83, 0.235), Vector3(0, 0, 20), Vector3(1.0, 1.5, 0.8)))
	_lens(fea, Vector3(0.09, 0.75, 0.24), Vector3(-0.15, -1.0, 0.05), Vector3.RIGHT, 0.13, 0.04, 0.012)
	_lens(fea, Vector3(0.13, 0.76, 0.235), Vector3(0.2, -1.0, 0.05), Vector3.RIGHT, 0.12, 0.035, 0.012)
	return _commit("belt", [[wood, _wood()], [dark, _robe()], [skin, _skin()], [fea, _feather()], [moss, _moss()]])


# ---------------------------------------------------------------- chest

## Robe top (lathe, flattened front-back), the team STOLE down the front to the knees with fringed ends, a wooden toggle.
static func _torso_mesh() -> ArrayMesh:
	if _wc_meshes.has("torso"):
		return _wc_meshes["torso"]
	var robe := _bucket()
	var team := _bucket()
	var wood := _bucket()
	var zs := Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.86)), Vector3.ZERO)
	_lathe(robe, PackedVector2Array([Vector2(0.20, 1.00), Vector2(0.20, 1.10), Vector2(0.215, 1.22), Vector2(0.235, 1.32),
		Vector2(0.24, 1.40), Vector2(0.222, 1.47), Vector2(0.18, 1.52), Vector2(0.12, 1.555), Vector2(0.065, 1.575)]), 14, zs)
	# the stole: two strips from the neck down over the belt to below the knees
	for sx: float in [-1.0, 1.0]:
		var path: Array[Vector3] = [Vector3(0.075 * sx, 1.56, 0.10), Vector3(0.09 * sx, 1.46, 0.19),
			Vector3(0.095 * sx, 1.30, 0.215), Vector3(0.095 * sx, 1.12, 0.195), Vector3(0.095 * sx, 1.00, 0.222),
			Vector3(0.10 * sx, 0.82, 0.245), Vector3(0.105 * sx, 0.60, 0.268)]
		const ROWS := 12
		var pts := PackedVector3Array()
		var hints := PackedVector3Array()
		for j: int in ROWS + 1:
			var p := _crom(path, float(j) / float(ROWS))
			for i: int in 2:
				pts.append(p + Vector3((float(i) - 0.5) * 0.085, 0.0, 0.0))
				hints.append(Vector3(0.0, 0.1, 1.0))
		_grid(team, pts, hints, 1, ROWS, false)
		# fringe: three short tassels at the end, and a leaf-shaped weight
		var end := path[path.size() - 1]
		for k: int in 3:
			_seg(team, end + Vector3((float(k) - 1.0) * 0.028, 0.0, 0.0), end + Vector3((float(k) - 1.0) * 0.032,
				-0.07, 0.005), 0.009, 0.006, 4)
		_put(wood, sphere(0.024, 6, 3), _xf(end + Vector3(0.0, 0.01, 0.012), Vector3.ZERO, Vector3(1.4, 0.8, 0.6)))
	_put(wood, box(Vector3(0.10, 0.024, 0.03)), _xf(Vector3(0.0, 1.50, 0.175), Vector3(0, 0, 8)))
	return _commit("torso", [[robe, _robe()], [team, _team()], [wood, _wood()]])


## Mantle point: the moss capelet over the shoulders. a from +Z toward +X, v 0 (neck) -> 1 (ragged hem). Wide at the
## shoulders, lumpy.
static func _mantle_point(a: float, v: float, grow: float = 0.0) -> Vector3:
	var side := absf(sin(a))
	var back := maxf(0.0, -cos(a))
	var reach := 0.29 + 0.08 * side
	var r := 0.11 + reach * pow(sin(v * PI * 0.5), 0.6) + 0.02 * sin(7.0 * a + 1.3) * v + grow
	var tatter := pow(absf(sin(4.5 * a + 0.5)), 3.0) * 0.05
	var y := 1.588 - 0.33 * pow(v, 1.5) - tatter * pow(v, 5.0) - 0.08 * back * v * v
	return Vector3(sin(a) * r, y, cos(a) * r * 0.88)


## The mantle: a dark capelet covered by 4 rows of barred feathers (pale / brown, the pale row at the hem), a collar of
## moss clumps round the neck and on the shoulders, and a ruff of stiff barred feathers behind the neck.
static func _mantle_mesh() -> ArrayMesh:
	if _wc_meshes.has("mantle"):
		return _wc_meshes["mantle"]
	var moss := _bucket()
	var lining := _bucket()
	var fea := _bucket()
	var wood := _bucket()
	const COLS := 30
	const ROWS := 8
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in ROWS + 1:
		var v := float(j) / float(ROWS)
		for i: int in COLS + 1:
			var a := TAU * float(i) / float(COLS)
			var p := _mantle_point(a, v)
			pts.append(p)
			hints.append(p - _mantle_point(a, v, -0.02) + Vector3(0, 0.001, 0))
	_grid(lining, pts, hints, COLS, ROWS, true, lining, 0.014)
	# the feather capelet: 4 overlapping rows round the shoulders, barred pale / brown, the pale row at the hem
	for k: int in 4:
		var v := 0.34 + 0.19 * float(k)
		var n := 18 + 4 * k
		var ln := 0.17 + 0.03 * float(k)
		for i: int in n:
			var a := TAU * (float(i) + (0.5 if k % 2 == 1 else 0.0)) / float(n)
			var vc := minf(v + 0.05, 1.0)
			var c := _mantle_point(a, vc, 0.02 + 0.008 * float(k))
			var dn := (_mantle_point(a, minf(vc + 0.05, 1.0)) - _mantle_point(a, vc - 0.05)).normalized()
			var dst: Array = fea if k % 2 == 1 else wood
			if k == 3:
				dst = fea
			_lens(dst, c + dn * ln * 0.25, dn, Vector3(cos(a), 0.0, -sin(a)), ln, 0.10, 0.022)
	# the moss collar round the neck, clumps on the shoulders
	for i: int in 12:
		var a := TAU * float(i) / 12.0 + 0.2
		var p := _mantle_point(a, 0.22, 0.02)
		_put(moss, sphere(0.055 + 0.012 * sin(float(i) * 2.3), 8, 4), _xf(p, Vector3.ZERO, Vector3(1.2, 0.85, 1.2)))
	for c: Array in [[1.35, 0.42, 0.06], [-1.35, 0.42, 0.06], [2.3, 0.5, 0.05], [-2.3, 0.5, 0.05]]:
		var p := _mantle_point(float(c[0]), float(c[1]), 0.04)
		_put(moss, sphere(float(c[2]), 8, 4), _xf(p, Vector3.ZERO, Vector3(1.1, 0.9, 1.1)))
	# the feather ruff: stiff barred feathers fanned up and out behind the neck
	for k: int in 7:
		var a := PI + (float(k) - 3.0) * 0.30
		var base := _mantle_point(a, 0.16, 0.0)
		var out := Vector3(sin(a), 0.0, cos(a))
		var up := (Vector3.UP * 1.0 + out * 0.9).normalized()
		var ln := 0.24 - 0.025 * absf(float(k) - 3.0)
		_lens(fea if k % 2 == 0 else wood, base + up * ln * 0.5, up, out.cross(Vector3.UP), ln, 0.075, 0.018)
	return _commit("mantle", [[moss, _moss()], [lining, _robe()], [fea, _feather()], [wood, _wood()]])


## Cloak point: the long back cloak under the mantle. a from +Z toward +X (the back half: 95 .. 265 deg), v 0 (under
## the mantle) -> 1 (the ground). Flares wide at the hem.
static func _cloak_point(a: float, v: float, grow: float = 0.0) -> Vector3:
	var back := maxf(0.0, -cos(a))
	var r := 0.33 + 0.26 * pow(v, 1.15) + 0.05 * back * v + 0.012 * sin(8.0 * a) * v + grow
	var y := lerpf(1.34, 0.05 - 0.02 * back, v)
	return Vector3(sin(a) * r, y, cos(a) * r * 0.9)


## The feathered cloak: a dark base (both sides) covered by 7 overlapping rows of feathers, barred pale / brown, the
## last row a long pale fringe (the ragged silhouette edge at the ground).
static func _cloak_mesh() -> ArrayMesh:
	if _wc_meshes.has("cloak"):
		return _wc_meshes["cloak"]
	var base := _bucket()
	var pale := _bucket()
	var brown := _bucket()
	const A0 := 95.0 * DEG
	const A1 := 265.0 * DEG
	const COLS := 18
	const ROWS := 8
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in ROWS + 1:
		var v := float(j) / float(ROWS)
		for i: int in COLS + 1:
			var a := lerpf(A0, A1, float(i) / float(COLS))
			var p := _cloak_point(a, v)
			pts.append(p)
			hints.append(Vector3(p.x, 0.0, p.z))
	_grid(base, pts, hints, COLS, ROWS, false, base, 0.01)
	const FROWS := 7
	for k: int in FROWS:
		var v := 0.10 + 0.13 * float(k)
		var n := 12 + k
		var ln := 0.24 + 0.012 * float(k) + (0.08 if k == FROWS - 1 else 0.0)
		for i: int in n:
			var u := (float(i) + (0.5 if k % 2 == 1 else 0.0) + 0.25) / float(n)
			if u > 1.0:
				continue
			var a := lerpf(A0 + 0.08, A1 - 0.08, u)
			var vc := minf(v + ln * 0.35 / 1.3, 0.99)
			var p := _cloak_point(a, vc, 0.022 + 0.004 * float(k))
			var dn := (_cloak_point(a, vc + 0.05) - _cloak_point(a, vc - 0.05)).normalized()
			var across := Vector3(cos(a), 0.0, -sin(a))
			var c := p
			var bottom := c.y - ln * 0.5 * absf(dn.y)
			if bottom < 0.015:
				c.y += 0.015 - bottom
			var dst: Array = pale if (k % 2 == 0 or k == FROWS - 1) else brown
			_lens(dst, c, dn, across, ln, 0.12, 0.024)
	return _commit("cloak", [[base, _robe()], [pale, _feather()], [brown, _wood()]])


# ---------------------------------------------------------------- head

## Neck, an old face (long hooked nose, sunken cheeks, a pointed chin), faint glowing eyes deep-set, bushy grey brows.
static func _face_mesh() -> ArrayMesh:
	if _wc_meshes.has("face"):
		return _wc_meshes["face"]
	var skin := _bucket()
	var glow := _bucket()
	var fea := _bucket()
	_seg(skin, Vector3(0.0, 1.50, 0.0), Vector3(0.0, 1.64, 0.03), 0.06, 0.056, 8)
	_put(skin, sphere(HEAD_R), _xf(HEAD_C, Vector3.ZERO, Vector3(0.88, 1.06, 0.95)))
	_put(skin, sphere(0.068, 8, 4), _xf(Vector3(0.0, 1.615, 0.10), Vector3.ZERO, Vector3(0.9, 0.95, 1.0)))
	# the nose: a long hooked wedge
	_seg(skin, Vector3(0.0, 1.735, 0.175), Vector3(0.0, 1.66, 0.235), 0.026, 0.016, 6)
	_put(skin, sphere(0.02, 6, 3), _xf(Vector3(0.0, 1.662, 0.232)))
	for sx: float in [-1.0, 1.0]:
		_put(glow, sphere(0.019, 6, 3), _xf(Vector3(0.052 * sx, 1.738, 0.162), Vector3(0, 0, -10.0 * sx), Vector3(1.3, 0.7, 0.6)))
		_put(fea, sphere(0.034, 6, 3), _xf(Vector3(0.056 * sx, 1.772, 0.168), Vector3(0, 0, 16.0 * sx), Vector3(1.4, 0.55, 0.7)))
		_put(skin, sphere(0.03, 6, 3), _xf(Vector3(0.078 * sx, 1.675, 0.14), Vector3.ZERO, Vector3(0.8, 1.1, 0.8)))
	return _commit("face", [[skin, _skin()], [glow, _glow()], [fea, _feather()]])


## Hood point: u across the hood (0 = the opening's right edge, 1 = its left edge, going round the back), v 0 = the
## crown -> 1 = the hem under the mantle. A deep, rounded cowl: the face opening widest at the eyes, closed under the
## chin, the brim overhanging the face.
static func _hood_point(u: float, v: float, grow: float = 0.0) -> Vector3:
	var th := lerpf(0.0, 2.45, v)
	var op := 0.95 * smoothstep(0.35, 0.90, th) * (1.0 - smoothstep(1.85, 2.30, th)) + 0.05
	var ph := lerpf(op, TAU - op, u)
	var flare := smoothstep(1.5, 2.45, th)
	var r := 0.215 + 0.14 * flare + grow
	var xs := 1.0 + 0.30 * flare
	var p := HOOD_C + Vector3(sin(th) * sin(ph) * r * xs, cos(th) * r * 1.08, sin(th) * cos(ph) * r)
	var edge := 1.0 - smoothstep(0.0, 0.12, minf(u, 1.0 - u))
	p.z += 0.06 * edge * (1.0 - flare)
	return p


## Antlers (model space): a tall pale lyre. Per side a main beam curving up and out then in, a brow tine forward, a tine
## out and one back; moss at the base and a hanging strand. base = the beam root, sc = scale.
static func _antlers(bone: Array, moss: Array, base_y: float, base_x: float, sc: float) -> void:
	for s: float in [-1.0, 1.0]:
		var o := Vector3(base_x * s, base_y, 0.0)
		var beam: Array[Vector3] = [o, o + Vector3(0.06 * s, 0.105, -0.03) * sc, o + Vector3(0.115 * s, 0.225, -0.05) * sc,
			o + Vector3(0.145 * s, 0.345, -0.045) * sc, o + Vector3(0.135 * s, 0.455, -0.02) * sc,
			o + Vector3(0.105 * s, 0.545, 0.01) * sc]
		_branch(bone, beam, 12, 0.05 * sc, 0.016 * sc, 7)
		var tines: Array = [[0.18, Vector3(0.03 * s, 0.07, 0.11), Vector3(0.045 * s, 0.13, 0.15)],
			[0.45, Vector3(0.07 * s, 0.08, -0.01), Vector3(0.09 * s, 0.18, -0.02)],
			[0.70, Vector3(0.02 * s, 0.08, -0.08), Vector3(0.035 * s, 0.15, -0.105)]]
		for tn: Array in tines:
			var p0 := _crom(beam, float(tn[0]))
			var ctrl: Array[Vector3] = [p0, p0 + (tn[1] as Vector3) * sc, p0 + (tn[2] as Vector3) * sc]
			_branch(bone, ctrl, 5, 0.03 * sc, 0.01 * sc, 6)
		_put(moss, sphere(0.06 * sc, 8, 4), _xf(o + Vector3(0.01 * s, 0.02, 0.0), Vector3.ZERO, Vector3(1.3, 0.8, 1.3)))
		var fork := _crom(beam, 0.18)
		_put(moss, sphere(0.035 * sc, 6, 3), _xf(fork, Vector3.ZERO, Vector3(1.2, 0.9, 1.2)))
		var hang := _crom(beam, 0.45)
		_seg(moss, hang, hang + Vector3(0.03 * s, -0.12, 0.0) * sc, 0.02 * sc, 0.008 * sc, 5)


## The variant piece (model space, Head pivot). 0 = the deep team hood (dark lining, a moss rim), antlers rising from it,
## grey locks at the cheeks; 1 = hood down: a grey mane, a braided beard down the chest (team ribbon, bead), a circlet of
## woven twigs with the antlers, the rolled cowl round the neck and the hood lying on the back.
static func _variant_mesh(v: int) -> ArrayMesh:
	var key := "variant%d" % v
	if _wc_meshes.has(key):
		return _wc_meshes[key]
	var team := _bucket()
	var lining := _bucket()
	var bone := _bucket()
	var moss := _bucket()
	var hair := _bucket()
	var wood := _bucket()
	if v == 0:
		const COLS := 22
		const ROWS := 14
		var pts := PackedVector3Array()
		var hints := PackedVector3Array()
		for j: int in ROWS + 1:
			var vv := float(j) / float(ROWS)
			for i: int in COLS + 1:
				var uu := float(i) / float(COLS)
				var p := _hood_point(uu, vv)
				pts.append(p)
				hints.append(p - _hood_point(uu, vv, -0.02))
		_grid(team, pts, hints, COLS, ROWS, false, lining, 0.016)
		# a moss rim along the brim
		for side: float in [0.0, 1.0]:
			var edge: Array[Vector3] = []
			for j: int in range(3, ROWS - 1):
				edge.append(_hood_point(side, float(j) / float(ROWS), 0.006))
			_tube(moss, edge, 0.02, 0.016, 5)
		_antlers(bone, moss, 1.925, 0.10, 1.0)
		for sx: float in [-1.0, 1.0]:
			var lock: Array[Vector3] = [Vector3(0.11 * sx, 1.76, 0.10), Vector3(0.135 * sx, 1.64, 0.13),
				Vector3(0.13 * sx, 1.53, 0.155)]
			_tube(hair, lock, 0.03, 0.016, 6)
	else:
		# the mane: a cap with a high receding hairline, long grey hair down the back of the neck
		const HC := 18
		const HR := 10
		var pts := PackedVector3Array()
		var hints := PackedVector3Array()
		var hc := Vector3(0.0, 1.72, 0.03)
		for j: int in HR + 1:
			var th := lerpf(0.0, 2.25, float(j) / float(HR))
			var op := 1.25 * smoothstep(0.3, 1.2, th) + 0.25
			for i: int in HC + 1:
				var ph := lerpf(op, TAU - op, float(i) / float(HC))
				var d := Vector3(sin(th) * sin(ph), cos(th) * 1.05, sin(th) * cos(ph) * 1.02)
				pts.append(hc + d * (0.172 + 0.03 * smoothstep(1.2, 2.2, th)))
				hints.append(d)
		_grid(hair, pts, hints, HC, HR, false)
		# bushy grey side tufts over the ears
		for sx: float in [-1.0, 1.0]:
			_put(hair, sphere(0.07, 8, 4), _xf(Vector3(0.15 * sx, 1.69, -0.01), Vector3.ZERO, Vector3(0.8, 1.2, 1.1)))
		# moustache and the braided beard down the front of the mantle
		for sx: float in [-1.0, 1.0]:
			_put(hair, sphere(0.04, 7, 3), _xf(Vector3(0.04 * sx, 1.635, 0.195), Vector3(0, 0, 25.0 * sx), Vector3(1.5, 0.7, 0.9)))
		_put(hair, sphere(0.09, 8, 4), _xf(Vector3(0.0, 1.595, 0.15), Vector3.ZERO, Vector3(1.05, 0.9, 0.85)))
		var path: Array[Vector3] = [Vector3(0.0, 1.57, 0.19), Vector3(0.0, 1.50, 0.30), Vector3(0.0, 1.42, 0.40),
			Vector3(0.0, 1.32, 0.43), Vector3(0.0, 1.22, 0.42), Vector3(0.0, 1.12, 0.36)]
		const LOBES := 11
		for i: int in LOBES:
			var t := float(i) / float(LOBES - 1)
			var p := _crom(path, t)
			var d := (_crom(path, minf(t + 0.02, 1.0)) - _crom(path, maxf(t - 0.02, 0.0))).normalized()
			var r := lerpf(0.068, 0.036, t)
			var side := Vector3(0.015 if i % 2 == 0 else -0.015, 0, 0)
			_put(hair, sphere(r, 7, 3), Transform3D(Basis(Quaternion(Vector3.UP, d)).scaled_local(Vector3(1.0, 1.5, 0.85)), p + side))
		var end := path[path.size() - 1]
		_put(team, cyl(0.03, 0.03, 0.045, 8), _xf(end + Vector3(0, -0.035, -0.01)))
		_put(wood, sphere(0.032, 7, 3), _xf(end + Vector3(0, -0.075, -0.012)))
		_put(hair, cyl(0.02, 0.05, 0.09, 8), _xf(end + Vector3(0, -0.14, -0.012), Vector3(180, 0, 0)))
		# the circlet of woven twigs and the antlers rising from the temples
		_put(wood, torus(0.158, 0.182, 20), _xf(Vector3(0.0, 1.80, 0.03), Vector3(-10, 0, 0), Vector3(0.95, 1.0, 1.0)))
		_put(moss, sphere(0.03, 6, 3), _xf(Vector3(0.0, 1.822, 0.20), Vector3.ZERO, Vector3(1.4, 0.8, 0.7)))
		_antlers(bone, moss, 1.835, 0.105, 0.95)
		# the rolled cowl round the neck (team, dark edge), the hood lying on the upper back
		var zs := Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.95)), Vector3(0, 0, -0.01))
		_lathe(team, PackedVector2Array([Vector2(0.14, 1.555), Vector2(0.21, 1.565), Vector2(0.235, 1.605),
			Vector2(0.21, 1.645), Vector2(0.15, 1.64)]), 18, zs)
		_put(team, sphere(0.2, 12, 6), _xf(Vector3(0.0, 1.50, -0.34), Vector3(-18, 0, 0), Vector3(1.15, 0.85, 0.42)))
		_put(lining, sphere(0.15, 10, 5), _xf(Vector3(0.0, 1.52, -0.295), Vector3(-18, 0, 0), Vector3(1.1, 0.7, 0.3)))
	return _commit(key, [[team, _team()], [lining, _robe()], [bone, _skin()], [moss, _moss()], [hair, _feather()],
		[wood, _wood()]])


# ---------------------------------------------------------------- arms and staff

## One arm (model space): a dark sleeve widening into a bell cuff with a moss trim, an old hand; the left wrist wears a
## string of wooden beads.
static func _arm_mesh(side: float) -> ArrayMesh:
	var key := "arm%d" % int(side)
	if _wc_meshes.has(key):
		return _wc_meshes[key]
	var robe := _bucket()
	var skin := _bucket()
	var moss := _bucket()
	var wood := _bucket()
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var hand := GRIP_R if side > 0.0 else HAND_L
	_seg(robe, sh, sh.lerp(hand, 0.55), 0.07, 0.068, 8)
	_put(robe, sphere(0.07, 8, 4), _xf(sh))
	_seg(robe, sh.lerp(hand, 0.55), sh.lerp(hand, 0.84), 0.068, 0.112, 10)
	_seg(moss, sh.lerp(hand, 0.82), sh.lerp(hand, 0.86), 0.116, 0.12, 10, 1.0, 1.0, true)
	_seg(skin, sh.lerp(hand, 0.80), hand, 0.042, 0.046, 8)
	if side > 0.0:
		# a fist closed round the staff: knuckles and a thumb over the grip
		_put(skin, sphere(0.056, 8, 4), _xf(hand + Vector3(0.018, 0.0, -0.008), Vector3.ZERO, Vector3(1.05, 1.1, 1.0)))
		_put(skin, sphere(0.022, 6, 3), _xf(hand + Vector3(-0.025, 0.035, 0.03)))
	else:
		_put(skin, sphere(0.052, 8, 4), _xf(hand, Vector3.ZERO, Vector3(0.9, 1.25, 0.8)))
		for k: int in 3:
			_put(skin, capsule(0.013, 0.07), _xf(hand + Vector3(0.012 * float(k - 1), -0.06, 0.018), Vector3(8, 0, 0)))
		for k: int in 7:
			var a := TAU * float(k) / 7.0
			var w := sh.lerp(hand, 0.84)
			_put(wood, sphere(0.016, 6, 3), _xf(w + Vector3(sin(a) * 0.048, 0.0, cos(a) * 0.048)))
	return _commit(key, [[robe, _robe()], [skin, _skin()], [moss, _moss()], [wood, _wood()]])


## The living staff in grip space (origin = the fist, +Y up the shaft): a gnarled shaft with knots and a root-knot foot,
## a dark grip wrap, a moss vine wound round it with small leaves, two team ribbons, and the CROWN: five branches curling
## round a glowing heart-bud in a bark cradle, a pink blossom with a glowing core on each branch and each tip, small
## leaves at the fork, a feather charm and a bone bead on cords. bloom 1 = the crown opened wide, the blossoms big.
static func _staff_mesh(bloom: int) -> ArrayMesh:
	var key := "staff%d" % bloom
	if _wc_meshes.has(key):
		return _wc_meshes[key]
	var wood := _bucket()
	var dark := _bucket()
	var moss := _bucket()
	var petals := _bucket()
	var glow := _bucket()
	var team := _bucket()
	var fea := _bucket()
	var skin := _bucket()
	var op := float(bloom)
	# shaft
	var shaft: Array[Vector3] = [Vector3(0.0, -FOOT + 0.02, 0.0), Vector3(0.012, -0.62, -0.008), Vector3(-0.011, -0.22, 0.01),
		Vector3(0.014, 0.22, -0.006), Vector3(-0.012, 0.66, 0.01), Vector3(0.01, 1.02, -0.01), Vector3(0.0, 1.20, 0.0),
		Vector3(0.0, CROWN_BASE_Y + 0.02, 0.0)]
	_branch(wood, shaft, 18, 0.036, 0.05, 7)
	for kn: Array in [[0.18, 0.042], [0.47, 0.046], [0.74, 0.05]]:
		_put(wood, sphere(float(kn[1]), 7, 3), _xf(_crom(shaft, float(kn[0])) + Vector3(0.012, 0.0, -0.01),
			Vector3(0, 40.0 * float(kn[0]), 0), Vector3(1.2, 1.5, 0.9)))
	# the root-knot foot
	for k: int in 3:
		var a := TAU * float(k) / 3.0 + 0.4
		var d := Vector3(sin(a), 0.0, cos(a))
		_seg(dark, Vector3(0.0, -FOOT + 0.10, 0.0), Vector3(0.0, -FOOT, 0.0) + d * 0.06, 0.024, 0.01, 5)
	_put(dark, sphere(0.04, 7, 3), _xf(Vector3(0.0, -FOOT + 0.09, 0.0), Vector3.ZERO, Vector3(1.0, 1.3, 1.0)))
	# grip wrap
	_seg(dark, Vector3(0.0, -0.10, 0.0), Vector3(0.0, 0.11, 0.0), 0.047, 0.047, 8, 1.0, 1.0, true)
	# the vine wound round the shaft, with small leaves
	var vine: Array[Vector3] = []
	for i: int in 34:
		var t := float(i) / 33.0
		var y := lerpf(-0.45, CROWN_BASE_Y - 0.04, t)
		var a := t * TAU * 2.6
		vine.append(Vector3(sin(a) * 0.054, y, cos(a) * 0.054))
	_tube(moss, vine, 0.011, 0.013, 5)
	for i: int in 7:
		var t := 0.1 + 0.13 * float(i)
		var y := lerpf(-0.45, CROWN_BASE_Y - 0.04, t)
		var a := t * TAU * 2.6
		var out := Vector3(sin(a), 0.0, cos(a))
		_lens(moss, Vector3(sin(a) * 0.08, y + 0.01, cos(a) * 0.08), (out + Vector3(0, 0.4, 0)).normalized(),
			Vector3.UP.cross(out), 0.07, 0.035, 0.01)
	# team ribbons: a knot under the crown, two streamers
	_put(team, sphere(0.05, 8, 4), _xf(Vector3(0.0, 1.16, 0.0), Vector3.ZERO, Vector3(1.1, 0.7, 1.1)))
	_seg(team, Vector3(0.03, 1.15, 0.02), Vector3(0.10, 0.80, 0.07), 0.028, 0.024, 4, 1.0, 0.25)
	_seg(team, Vector3(-0.02, 1.15, 0.03), Vector3(0.02, 0.74, 0.11), 0.026, 0.022, 4, 1.0, 0.25)
	# the crown: five branches
	var heart_r := lerpf(0.092, 0.115, op)
	var phase := 0.25
	for i: int in 5:
		var phi := TAU * float(i) / 5.0 + phase
		var d := Vector3(sin(phi), 0.0, cos(phi))
		var up := Vector3.UP
		var ctrl: Array[Vector3] = [up * (CROWN_BASE_Y - 0.03),
			d * lerpf(0.10, 0.12, op) + up * (CROWN_BASE_Y + 0.10),
			d * lerpf(0.21, 0.27, op) + up * (CROWN_BASE_Y + lerpf(0.22, 0.20, op)),
			d * lerpf(0.20, 0.33, op) + up * (CROWN_BASE_Y + lerpf(0.34, 0.32, op)),
			d * lerpf(0.12, 0.34, op) + up * (CROWN_BASE_Y + lerpf(0.44, 0.44, op)),
			d * lerpf(0.05, 0.30, op) + up * (CROWN_BASE_Y + lerpf(0.49, 0.53, op))]
		_branch(wood, ctrl, 9, 0.032, 0.013, 6)
		# a big blossom on the outer bulge (facing out and up), one on the tip (facing up / out), a bud low on the
		# branch between two of them (every other branch)
		var bc := _crom(ctrl, 0.5) + d * 0.04
		_blossom(petals, glow, bc, (d + Vector3(0, 0.45, 0)).normalized(), lerpf(1.75, 2.3, op), op)
		var tip := ctrl[ctrl.size() - 1]
		_blossom(petals, glow, tip + Vector3(0, 0.02, 0), (Vector3.UP + d * lerpf(0.25, 0.8, op)).normalized(),
			lerpf(1.35, 1.8, op), op)
		if i % 2 == 0:
			var lo := _crom(ctrl, 0.22)
			var dl := Vector3(sin(phi + 0.63), 0.0, cos(phi + 0.63))
			_blossom(petals, glow, lo + dl * 0.05, (dl + Vector3(0, 0.2, 0)).normalized(), lerpf(1.1, 1.5, op), op)
		# leaves at the fork, hanging out and down
		_lens(moss, up * (CROWN_BASE_Y - 0.02) + d * 0.06 + Vector3(0, -0.02, 0), (d + Vector3(0, -0.5, 0)).normalized(),
			Vector3.UP.cross(d), 0.10, 0.05, 0.012)
	# the heart-bud in its bark cradle
	_lathe(wood, PackedVector2Array([Vector2(0.02, HEART_Y - 0.13), Vector2(0.06, HEART_Y - 0.10),
		Vector2(0.075, HEART_Y - 0.06), Vector2(0.06, HEART_Y - 0.035)]), 10)
	_put(glow, sphere(heart_r, 10, 5), _xf(Vector3(0.0, HEART_Y, 0.0), Vector3.ZERO, Vector3(1.0, 1.15, 1.0)))
	# charms on cords from one branch: a feather and a bone bead
	var ph0 := phase + TAU * 2.0 / 5.0
	var cd := Vector3(sin(ph0), 0.0, cos(ph0))
	var c0 := cd * lerpf(0.13, 0.16, op) + Vector3.UP * (CROWN_BASE_Y + 0.11)
	_seg(dark, c0, c0 + Vector3(0.0, -0.20, 0.0) + cd * 0.02, 0.006, 0.006, 4)
	_lens(fea, c0 + Vector3(0.0, -0.27, 0.0) + cd * 0.025, Vector3(0.0, -1.0, 0.1), cd.cross(Vector3.UP), 0.13, 0.04, 0.012)
	var c1 := c0 + cd.cross(Vector3.UP) * 0.05
	_seg(dark, c1, c1 + Vector3(0.0, -0.13, 0.0), 0.006, 0.006, 4)
	_put(skin, sphere(0.026, 6, 3), _xf(c1 + Vector3(0.0, -0.15, 0.0), Vector3.ZERO, Vector3(0.9, 1.3, 0.9)))
	return _commit(key, [[wood, _wood()], [dark, _robe()], [moss, _moss()], [petals, _petal()], [glow, _glow()],
		[team, _team()], [fea, _feather()], [skin, _skin()]])


# ================================================================ animation

## Points the staff along d (model space) with weight k this frame (the strongest request wins).
func _staff_to(k: float, d: Vector3) -> void:
	if k > _st_k:
		_st_k = k
		_st_d = d


## Keyframed value at t: linear in time, smoothstep-eased per span.
static func _kf(t: float, ts: Array, vs: Array) -> float:
	if t <= float(ts[0]):
		return float(vs[0])
	for i: int in ts.size() - 1:
		if t < float(ts[i + 1]):
			var u := (t - float(ts[i])) / maxf(float(ts[i + 1]) - float(ts[i]), 0.0001)
			return lerpf(float(vs[i]), float(vs[i + 1]), smoothstep(0.0, 1.0, u))
	return float(vs[vs.size() - 1])


## Old druid walk: the kit's, stooped a little.
func _pose_walk(w: float, rate: float) -> void:
	super._pose_walk(w, rate)
	rot(P_CHEST, Vector3(4.0 * DEG * w, 0, 0))


## A thrust of the crown at the target: raise (0 .. rel), the crown at `elev` deg over the horizon at the release, hold,
## lower. The free palm pushes after it.
func _pose_bolt(t: float, rel: float, length: float, elev: float, flare: float) -> void:
	var k := _k3(t, 0.0, rel * 0.9, rel + 0.15, length, 1.0, 1.0)
	var e := lerpf(elev + 34.0, elev, smoothstep(rel * 0.4, rel, t)) * DEG
	rot(P_ARM_R, Vector3(lerpf(-40.0, -58.0, smoothstep(rel * 0.4, rel, t)) * DEG * k, 0, 6.0 * DEG * k))
	pos(P_ARM_R, Vector3(0, 0, 0.05 * _k3(t, rel * 0.6, rel, rel + 0.1, length, 1.0, 0.8)))
	_staff_to(k, Vector3(0.0, sin(e), cos(e)))
	var p := _k3(t, rel * 0.5, rel + 0.02, rel + 0.15, length, 1.0, 1.0)
	rot(P_ARM_L, Vector3(-62.0 * DEG * p, 0, 14.0 * DEG * p))
	rot(P_CHEST, Vector3(5.0 * DEG * k, -10.0 * DEG * k, 0))
	rot(P_HEAD, Vector3(-4.0 * DEG * k, 8.0 * DEG * k, 0))
	pos(P_ROOT, Vector3(0, 0, _k3(t, rel, rel + 0.05, rel + 0.10, length, 0.07, 0.03)))
	rot(P_LEG_L, Vector3(-8.0 * DEG * k, 0, 0))
	_hold = maxf(_hold, 1.4 * clampf(t / rel, 0.0, 1.0) * k)
	_release_at(t, rel, flare)


## Attack `thorn_bolt`.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != ATTACK_STYLE:
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else ATTACK_WINDUP
	_pose_bolt(t, w, ATTACK_LEN, 40.0, 0.0)
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < ATTACK_LEN


func _pose_class_skill(id: StringName, t: float) -> float:
	match id:
		&"arc_bolt":
			_pose_bolt(t, 0.20, 0.6, 30.0, 2.4)
			return 0.6
		&"starfall":
			# The crown raised straight at the sky, the head back; a flare at 0.42 held while the star falls.
			var k := _k3(t, 0.0, 0.30, 0.90, 1.2, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-165.0 * DEG * k, 0, -4.0 * DEG * k))
			_staff_to(k, Vector3(0.0, 1.0, 0.04))
			rot(P_ARM_L, Vector3(-40.0 * DEG * k, 0, -35.0 * DEG * k))
			rot(P_HEAD, Vector3(-24.0 * DEG * k, 0, 0))
			rot(P_CHEST, Vector3(-8.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, -0.04 * _k3(t, 0.30, 0.42, 0.6, 1.0, 1.0, 1.0), 0))
			_hold = maxf(_hold, 2.4 * _k3(t, 0.2, 0.42, 0.9, 1.2, 1.0, 1.0))
			_bloom = maxf(_bloom, _k3(t, 0.35, 0.45, 0.85, 1.0, 1.0, 1.0))
			_release_at(t, 0.42, 3.0)
			return 1.2
		&"slipstep":
			# The kit's blink (fade to a sliver, gone, back with an overshoot) + a crown flash on both ends.
			var ln := super._pose_class_skill(id, t)
			_hold = maxf(_hold, 2.4 * (1.0 - clampf(absf(t - 0.15) / 0.2, 0.0, 1.0)))
			return ln
	return super._pose_class_skill(id, t)


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		CALL_ID:
			return _pose_call(t)
		&"thornsnare":
			return _pose_thornsnare(t)
		&"call_the_pack":
			return _pose_call_the_pack(t)
		&"wild_stampede":
			return _pose_stampede(t)
		&"gravity_well":
			# The free hand swirls down to the ground in a spiral, a crouch; the crown pressed forward and low.
			var k := _k3(t, 0.0, 0.25, 0.75, 1.0, 1.0, 1.0)
			var sw := clampf((t - 0.08) / 0.45, 0.0, 1.0)
			var c := _k3(t, 0.20, 0.48, 0.70, 1.0, 1.0, 1.0)
			rot(P_ARM_L, Vector3(lerpf(-125.0, 5.0, _ease_in(sw)) * DEG * k, 0, -32.0 * sin(sw * TAU * 1.25) * DEG * k))
			rot(P_ARM_R, Vector3(-48.0 * DEG * k, 0, 8.0 * DEG * k))
			_staff_to(k, Vector3(0.0, 0.42, 1.0).normalized())
			rot(P_CHEST, Vector3(20.0 * DEG * c, 10.0 * DEG * k, 0))
			rot(P_HEAD, Vector3(10.0 * DEG * c, 0, 0))
			pos(P_ROOT, Vector3(0, -0.13 * c, 0))
			rot(P_LEG_L, Vector3(-26.0 * DEG * c, 0, 0))
			rot(P_LEG_R, Vector3(16.0 * DEG * c, 0, 0))
			_hold = maxf(_hold, 2.0 * _k3(t, 0.44, 0.50, 0.56, 0.85, 1.0, 1.0))
			_release_at(t, 0.50, 1.6)
			return 1.0
		&"comet_rain":
			# Three pumps of the crown at the sky (0.38, 0.68, 0.98), each with a flare.
			var k := _k3(t, 0.0, 0.22, 1.12, 1.4, 1.0, 1.0)
			var pump := 0.0
			for r: float in COMET_RELS:
				pump = maxf(pump, _k3(t, r - 0.12, r, r, r + 0.14, 1.0, 1.0))
			rot(P_ARM_R, Vector3((-118.0 - 22.0 * pump) * DEG * k, 0, 0))
			_staff_to(k, Vector3(0.0, 0.87 + 0.1 * pump, 0.5 - 0.2 * pump).normalized())
			rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, -20.0 * DEG * k))
			rot(P_HEAD, Vector3(-14.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, -0.03 * pump, 0))
			_hold = maxf(_hold, 1.0 * k + 1.2 * pump)
			while _shots < COMET_RELS.size() and t >= COMET_RELS[_shots]:
				_shots += 1
				_burst(2.2)
			return 1.4
		&"astral_form":
			# Arms open: the staff held upright high out to the side, the free arm spread, chest up, head back, a lift;
			# full bloom, every glow up.
			var k := _k3(t, 0.0, 0.35, 0.85, 1.2, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-20.0 * DEG * k, 0, 62.0 * DEG * k))
			rot(P_ARM_L, Vector3(-20.0 * DEG * k, 0, -70.0 * DEG * k))
			_staff_to(k, Vector3.UP)
			rot(P_CHEST, Vector3(-10.0 * DEG * k, 0, 0))
			rot(P_HEAD, Vector3(-16.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, 0.07 * k, 0))
			_hold = maxf(_hold, 2.6 * k)
			_bloom = maxf(_bloom, k)
			_release_at(t, 0.35, 1.2)
			return 1.2
		_:
			_pose_bolt(t, 0.20, 0.6, 30.0, 2.4)
			return 0.6


## Thornsnare (1.0 s): the staff lifted high, then DRIVEN foot-first into the ground in front of her (strike 0.5, a
## crouch, the chest bent over it), the free arm sweeping out; a crown flare at the strike, held, then back.
func _pose_thornsnare(t: float) -> float:
	const TS: Array[float] = [0.0, 0.28, 0.42, 0.50, 0.74, 1.0]
	var arm := _kf(t, TS, [0.0, -95.0, -60.0, -30.0, -30.0, 0.0])
	var crouch := _kf(t, TS, [0.0, 0.03, -0.02, -0.13, -0.11, 0.0])
	var lean := _kf(t, TS, [0.0, -8.0, 4.0, 18.0, 15.0, 0.0])
	var sweep := _kf(t, TS, [0.0, -20.0, -30.0, -55.0, -50.0, 0.0])
	var k := _k3(t, 0.0, 0.2, 0.8, 1.0, 1.0, 1.0)
	rot(P_ARM_R, Vector3(arm * DEG, 0, 4.0 * DEG * k))
	_staff_to(k, Vector3(0.0, 1.0, 0.06))
	rot(P_ARM_L, Vector3(-38.0 * DEG * k, 0, sweep * DEG))
	rot(P_CHEST, Vector3(lean * DEG, -6.0 * DEG * k, 0))
	rot(P_HEAD, Vector3(lean * 0.3 * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, crouch, 0.04 * k))
	rot(P_LEG_L, Vector3(-18.0 * DEG * k, 0, 0))
	rot(P_LEG_R, Vector3(12.0 * DEG * k, 0, 0))
	_hold = maxf(_hold, 0.8 * k + 2.0 * _k3(t, 0.46, 0.50, 0.62, 0.95, 1.0, 1.0))
	_release_at(t, 0.50, 3.0)
	return 1.0


## Call the Pack (1.3 s): the staff raised straight overhead in full bloom, the head thrown back, the free hand cupped at
## the mouth: the howl at 0.55 (flash, sparks, the ring of motes at her feet), held to 0.95, then lowered.
func _pose_call_the_pack(t: float) -> float:
	var k := _k3(t, 0.0, 0.35, 0.95, 1.3, 1.0, 1.0)
	var howl := _k3(t, 0.40, 0.55, 0.95, 1.2, 1.0, 1.0)
	rot(P_ARM_R, Vector3(-160.0 * DEG * k, 0, -6.0 * DEG * k))
	_staff_to(k, Vector3(0.0, 1.0, 0.05))
	rot(P_ARM_L, Vector3(-118.0 * DEG * k, 0, 28.0 * DEG * k))
	pos(P_ARM_L, Vector3(0.05 * k, 0.0, 0.04 * k))
	rot(P_HEAD, Vector3(-(12.0 + 20.0 * howl) * DEG * k, 0, 0))
	rot(P_CHEST, Vector3(-(4.0 + 8.0 * howl) * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, 0.04 * howl, 0))
	_bloom = maxf(_bloom, _k3(t, 0.30, 0.45, 1.0, 1.15, 1.0, 1.0))
	_hold = maxf(_hold, 1.0 * k + 2.2 * howl)
	if not _fired and t >= 0.55:
		_fired = true
		_burst(3.0)
		if _call_motes and _tier < 2:
			_call_motes.restart()
	return 1.3


## Wild Stampede (1.3 s): a low wind-up (0 .. 0.4, the crown back over the right shoulder, a crouch and a twist), then the
## staff swept forward and LEVELLED along the line (release 0.62, a long step, the free arm flung back), full bloom.
func _pose_stampede(t: float) -> float:
	const TS: Array[float] = [0.0, 0.40, 0.62, 0.95, 1.3]
	var arm := _kf(t, TS, [0.0, 28.0, -78.0, -72.0, 0.0])
	var twist := _kf(t, TS, [0.0, 26.0, -18.0, -14.0, 0.0])
	var step := _kf(t, TS, [0.0, -0.04, 0.24, 0.22, 0.0])
	var dip := _kf(t, TS, [0.0, -0.12, -0.08, -0.07, 0.0])
	var k := _k3(t, 0.0, 0.3, 1.0, 1.3, 1.0, 1.0)
	var fwd := smoothstep(0.40, 0.62, t)
	var d := Vector3(0.35, 0.40, -0.85).normalized().lerp(Vector3(0.0, 0.10, 1.0).normalized(), fwd).normalized()
	rot(P_ARM_R, Vector3(arm * DEG, 0, 10.0 * DEG * k))
	_staff_to(k, d)
	rot(P_CHEST, Vector3(12.0 * DEG * k, twist * DEG, 0))
	rot(P_HEAD, Vector3(-4.0 * DEG * k, -twist * 0.6 * DEG, 0))
	rot(P_ARM_L, Vector3(_kf(t, TS, [0.0, -30.0, 45.0, 40.0, 0.0]) * DEG, 0, -18.0 * DEG * k))
	pos(P_ROOT, Vector3(0, dip, step))
	rot(P_LEG_L, Vector3(_kf(t, TS, [0.0, 6.0, -30.0, -28.0, 0.0]) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_kf(t, TS, [0.0, -4.0, 18.0, 16.0, 0.0]) * DEG, 0, 0))
	_bloom = maxf(_bloom, _k3(t, 0.40, 0.55, 1.0, 1.15, 1.0, 1.0))
	_hold = maxf(_hold, 1.0 * k + 1.6 * _k3(t, 0.50, 0.62, 0.95, 1.2, 1.0, 1.0))
	_release_at(t, 0.62, 3.0)
	return 1.3


## play_call(): she rises out of the ground (0.1 - 1.2 s) holding the staff straight overhead (the glowing crown breaks
## the ground first), head up toward it; she plants the staff beside her (the foot strikes at 1.55: flash, sparks, full
## bloom), lifts her head, and stands by 2.0. The blob fades in as she rises.
func _pose_call(t: float) -> float:
	var rise := _ease_out(clampf((t - 0.1) / 1.1, 0.0, 1.0))
	pos(P_ROOT, Vector3(0, -CALL_DEPTH * (1.0 - rise), 0))
	const TS: Array[float] = [0.0, 1.15, 1.40, CALL_PLANT, 1.75, CALL_LEN]
	var arm := _kf(t, TS, [-165.0, -165.0, -70.0, -24.0, -22.0, 0.0])
	var k := 1.0 - smoothstep(1.75, CALL_LEN, t)
	rot(P_ARM_R, Vector3(arm * DEG, 0, -4.0 * DEG * k))
	_staff_to(k, Vector3(0.0, 1.0, 0.05))
	var look := _kf(t, TS, [-22.0, -22.0, 6.0, 14.0, 4.0, 0.0])
	rot(P_HEAD, Vector3(look * DEG, 0, 0))
	rot(P_CHEST, Vector3(_kf(t, TS, [-6.0, -6.0, 6.0, 12.0, 4.0, 0.0]) * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_kf(t, TS, [-30.0, -30.0, -20.0, -10.0, -5.0, 0.0]) * DEG, 0,
		_kf(t, TS, [-38.0, -38.0, -25.0, -12.0, -5.0, 0.0]) * DEG))
	pos(P_ROOT, Vector3(0, _kf(t, TS, [0.0, 0.0, 0.0, -0.06, -0.02, 0.0]), 0))
	_bloom = maxf(_bloom, _k3(t, 1.45, CALL_PLANT, 1.85, 1.98, 1.0, 1.0))
	_hold = maxf(_hold, 1.6 * (1.0 - rise) + 2.6 * _k3(t, 1.4, CALL_PLANT, 1.75, CALL_LEN, 1.0, 1.0))
	if _shadow:
		_shadow.transparency = 1.0 - smoothstep(0.6, 1.2, t)
	_release_at(t, CALL_PLANT, 2.8)
	return CALL_LEN


## Riding (she buys a Roan Courser at level 7): the kit's rider pose, the staff arm rolled out and the staff held upright
## with its foot out past the mount's flank.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	super._pose_seated(w, gait, gallop, moving)
	if _action == &"":
		rot(P_ARM_R, Vector3(-10.0 * DEG * w, 0, 18.0 * DEG * w))
		_staff_to(w, SEAT_AXIS.normalized())


func _release_at(t: float, rel: float, flare: float) -> void:
	if not _fired and t >= rel:
		_fired = true
		_burst(flare)


## One release: the crown flares, sparks burst from the heart.
func _burst(flare: float) -> void:
	_flare = maxf(_flare, flare)
	if _spark and _tier < 2:
		_spark.restart()


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"attack_start":
			_fired = false
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
			_burst(2.2)
		&"level_up":
			_flare = maxf(_flare, 2.5)


func _extra_process(dt: float) -> void:
	# ---- Staff: rides the fist at rest; a pose points it along _st_d in model space (weight _st_k).
	var k := clampf(_st_k, 0.0, 1.0)
	var bl: int = 1 if (_bloom > 0.5 and not _dead) else 0
	_st_k = 0.0
	_bloom = 0.0
	if _staff == null:
		return
	var q := _q_rest
	if k > 0.0:
		var ab_inv := (Basis.from_euler(_off_rot[P_ROOT]) * Basis.from_euler(_off_rot[P_CHEST])
			* Basis.from_euler(_off_rot[P_ARM_R])).inverse()
		q = q.slerp((ab_inv * Basis(Quaternion(Vector3.UP, _st_d.normalized()))).get_rotation_quaternion(), k)
	if not q.is_equal_approx(_staff_q_w):
		_staff_q_w = q
		_staff.quaternion = q
	if bl != _bloom_w:
		_bloom_w = bl
		_staff.mesh = _staff_mesh(bl)
	# ---- Crown glow: x veterancy / haste (0 once dead), a slow breath at close range, flares on releases / level-ups.
	_flare = maxf(0.0, _flare - dt * 2.4)
	var breath := 0.0
	if _tier == 0 and not _dead:
		breath = 0.2 * sin((_t + _phase_off) * 1.9)
	var g := glow_level() * (CROWN_BASE + breath + _flare + _hold)
	_hold = 0.0
	if absf(g - _glow_w) > 0.004 or (g == 0.0 and _glow_w != 0.0):
		_glow_w = g
		_staff.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	_flare = 0.0
	_hold = 0.0
	_bloom = 0.0
	_st_k = 0.0
	_fired = false
	_shots = 0
	_calling = false
	_staff_q_w = Quaternion(9, 9, 9, 9)
	_bloom_w = -1
	_glow_w = -1.0
