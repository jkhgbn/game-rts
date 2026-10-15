class_name WarMammothModel
extends MountModel
## War Mammoth (cavalry-mounts.md 5 / 10, task 13.V16): Ice's tier-3 siege titan. A shaggy blue-grey woolly
## mammoth, 5.8 m from the rump to the tusk tips, 3.4 m at the shoulder hump, a tall domed skull with a frosted crown
## of hair, a two-segment trunk that swings with the gait, and TWO LONG CURVED TUSKS = the read at 40 m: ivory
## sweeping down, out and up into a lyre in front of the face, their outer third capped in faceted ice bound with steel
## bands, ending in glowing ice points (ice_glow_unit). A long dark under-fur skirt and a blue-grey outer skirt hang
## to the knees, a shaggy mane covers the shoulder hump (pale, rimed tips on top), fur boots over the pillar legs,
## small icicles hang from the skirt hem. Team saddle-blanket (ice_cloth, dark hem, snowflake emblems) with leather
## girths carries the HOWDAH (13.V17, child scene `howdah.tscn` on the Seat marker: timber-and-ice box, team banner,
## hooded frost archer). Frost mist rolls off the feet (one looping particle system, world space, stopped > 45 m).
## Must never be confused with the Rimehorn (a low rhino with one horn) or the neutral Grizzlemaw (a brown bear).
##
## Hooks (all safe before _ready; callers use has_method):
##   kit / MountModel: set_team_color(c) (blanket + howdah banner / cloth / archer), set_moving(speed) (a heavy 4-beat
##   walk, never a gallop), play_attack() (tusk gore, strike 0.12 s), play_hit() (the whole beast + the howdah),
##   play_death() + signal death_finished (1.0 s: stumbles, rolls onto its side, frosts over; the archer slumps),
##   set_status(id, on), revive(), play_cast / play_level_up / set_veterancy (kit, no titan use).
##   play_trample(): the trample stomp (cavalry-mounts.md 5.2, every 1.0 s while moving): a front foot slams down,
##   the tusks sweep aside (alternating sides), the trunk swings; a trumpet (trunk up) when > 3 s since the last one.
##   Strike frame TRAMPLE_HIT (0.2 s) emits signal trample_stomped(at: Vector3) (world point of the stomping foot).
##   play_howdah_shot(target = null): the howdah archer's shot (forwarded to the howdah; target = Node3D or world
##   Vector3, the archer turns to it); release frame HOWDAH_RELEASE (0.12 s). get_howdah() -> Node3D,
##   get_howdah_muzzle() -> Vector3 (world point of the nocked arrow tip, where a bolt VFX starts).
## Budget (titan, section 10): authored meshes (sculpts + blob) mammoth 10 + howdah 5 = 15 (<= 36); draw instances
## mammoth 10 (Body, Head, Trunk, Trunk2, 4 legs, Tail, blob) + 1 particle system + howdah 6 (Frame, Chest, Head, ArmL,
## ArmR, 2 bow-string halves... see the test) <= 20; 0 lights; <= 2 particle systems.

signal trample_stomped(at: Vector3)

const OWN := "res://art/units/titans/war_mammoth/materials/"
const ICE := "res://art/units/ice/materials/"
const BLOB_TINT := Color(0.03, 0.05, 0.11, 0.55)
const FROST := Vector3(0.40, 0.72, 1.0)
## play_trample timeline (s): length and the stomp (strike) frame.
const TRAMPLE_LEN := 0.8
const TRAMPLE_HIT := 0.2
## Release frame of the howdah archer's shot (s after play_howdah_shot), for a bolt that leaves with the arrow.
const HOWDAH_RELEASE := 0.12
## Tusk gore (play_attack) length and strike frame.
const GORE_LEN := 0.9
const GORE_HIT := 0.12

## Body barrel (fur) of revolution along z, centred on BC; lateral / vertical squash SX / SY. Profile [z offset, r].
const BC := Vector3(0, 1.95, -0.15)
const SX := 0.94
const SY := 1.06
const BARREL_Z: Array[float] = [-1.50, -1.46, -1.30, -1.00, -0.50, 0.10, 0.60, 1.00, 1.25, 1.36]
const BARREL_R: Array[float] = [0.00, 0.42, 0.70, 0.90, 1.00, 1.02, 0.98, 0.86, 0.62, 0.00]
## Shoulder hump, rump, chest (neck base) ellipsoids: centre, radii.
const HUMP_C := Vector3(0, 2.78, 0.55)
const HUMP_R := Vector3(0.80, 0.62, 0.90)
const RUMP_C := Vector3(0, 2.30, -1.05)
const RUMP_R := Vector3(0.84, 0.62, 0.66)
const CHEST_C := Vector3(0, 2.22, 1.08)
const CHEST_R := Vector3(0.86, 0.90, 0.62)
## Skull (cranium, dome) and muzzle.
const SKULL_C := Vector3(0, 2.93, 1.85)
const SKULL_R := Vector3(0.62, 0.72, 0.57)
const DOME_C := Vector3(0, 3.40, 1.70)
const DOME_R := Vector3(0.44, 0.38, 0.42)
const MUZZLE_C := Vector3(0, 2.42, 2.18)
const MUZZLE_R := Vector3(0.46, 0.55, 0.40)
## The right tusk (x > 0; the left mirrors x): core points and radii. Index >= ICE_FROM is capped in ice.
const TUSK_P: Array[Vector3] = [Vector3(0.32, 2.24, 2.26), Vector3(0.55, 1.82, 2.56), Vector3(0.76, 1.46, 3.00),
	Vector3(0.88, 1.34, 3.48), Vector3(0.86, 1.48, 3.95), Vector3(0.68, 1.82, 4.26), Vector3(0.44, 2.14, 4.36)]
const TUSK_R: Array[float] = [0.23, 0.22, 0.21, 0.20, 0.18, 0.13, 0.0]
const ICE_FROM := 3
## Trunk: first segment (pivot Trunk at its root), second (pivot Trunk2 at its root); model space.
const TRUNK1_P: Array[Vector3] = [Vector3(0, 2.40, 2.34), Vector3(0, 2.30, 2.48), Vector3(0, 1.90, 2.66),
	Vector3(0, 1.42, 2.74)]
const TRUNK1_R: Array[float] = [0.30, 0.29, 0.25, 0.21]
const TRUNK2_P: Array[Vector3] = [Vector3(0, 1.46, 2.74), Vector3(0, 1.00, 2.75), Vector3(0, 0.64, 2.80),
	Vector3(0, 0.44, 2.92), Vector3(0, 0.39, 3.04)]
const TRUNK2_R: Array[float] = [0.21, 0.18, 0.15, 0.13, 0.11]

# Keyframe tracks [t, value, ease, ...] (MountModel._mkf).
# Tusk gore (play_attack): the head rears (tusks up), then drives down and forward (strike 0.12), rakes up, recovers.
static var GO_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -14.0, 1, 0.14, 24.0, 2, 0.30, -16.0, 1, 0.55, -4.0, 0, 0.9, 0.0, 0])
static var GO_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, -7.0, 1, 0.14, 9.0, 2, 0.30, -6.0, 1, 0.9, 0.0, 0])
static var GO_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.10, 1, 0.14, 0.34, 2, 0.35, 0.18, 0, 0.9, 0.0, 0])
static var GO_BODY_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -4.0, 1, 0.14, 5.0, 2, 0.35, 1.0, 0, 0.9, 0.0, 0])
static var GO_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, -12.0, 1, 0.14, 10.0, 2, 0.40, 0.0, 0, 0.9, 0.0, 0])
static var GO_TRUNK := PackedFloat32Array([0.0, 0.0, 0, 0.08, 18.0, 1, 0.16, -32.0, 2, 0.40, -8.0, 0, 0.9, 0.0, 0])
# Trample: lift (1 = raised) then slam (negative = planted hard), tusk sweep (+1 wind toward the side, -1 across),
# head pitch, body dip.
static var TR_LIFT := PackedFloat32Array([0.0, 0.0, 0, 0.13, 1.0, 1, 0.20, -0.3, 2, 0.34, 0.0, 0, 0.8, 0.0, 0])
static var TR_SWEEP := PackedFloat32Array([0.0, 0.0, 0, 0.14, 1.0, 1, 0.30, -1.0, 2, 0.50, -0.6, 0, 0.8, 0.0, 0])
static var TR_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.14, -8.0, 1, 0.22, 9.0, 2, 0.45, 4.0, 0, 0.8, 0.0, 0])
static var TR_DIP := PackedFloat32Array([0.0, 0.0, 0, 0.14, 0.04, 1, 0.21, -0.10, 2, 0.40, -0.02, 0, 0.8, 0.0, 0])

static var _fx_cache: Dictionary = {}

var _howdah: Node3D
var _mist: GPUParticles3D
var _trunk: Array[Node3D] = [null, null]
var _trunk_mi: Array[MeshInstance3D] = [null, null]
var _trunk_off: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _trunk_last: Array[Vector3] = [Vector3(INF, 0, 0), Vector3(INF, 0, 0)]
var _tr_t: float = 99.0
var _tr_side: float = 1.0
var _tr_big: bool = false
var _tr_last: float = -99.0
var _frost_v: float = 0.0


# ================================================================ authoring

func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	# Trunk pivots (not kit pivots): kept out of the Head merge, merged here into their own node each.
	_trunk[0] = get_node_or_null(^"Root/Mount/Head/Trunk") as Node3D
	_trunk[1] = get_node_or_null(^"Root/Mount/Head/Trunk/Trunk2") as Node3D
	for j: int in 2:
		if _trunk[j]:
			_trunk[j].set_meta(&"keep_separate", true)
	if _trunk[0]:
		add_sculpt(_trunk[0], _trunk1_sculpt)
	if _trunk[1]:
		add_sculpt(_trunk[1], _trunk2_sculpt)
	for j: int in 2:
		if _trunk[j]:
			_trunk_mi[j] = _merge_own(_trunk[j])
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	ensure_shadow_blob(1.2, BLOB_TINT)
	_shadow.scale = Vector3(3.6, 1.0, 6.2)
	_shadow.position = Vector3(0, 0.02, 0.45)
	# Frost mist rolling off the feet (world space: it trails behind the walk). Looping: the kit stops it beyond 45 m.
	_mist = _make_mist()
	$Fx.add_child(_mist)
	_mist.position = Vector3(0, 0.30, -0.05)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("mammoth") else ICE) + name + ".tres")


## Merges the static parts under an own (non-kit) pivot into one "Merged" node, cached per type like the kit.
func _merge_own(p: Node3D) -> MeshInstance3D:
	var key := _type_key + "|" + _pivot_name(p)
	var parts: Array[MeshInstance3D] = []
	var xforms: Array[Transform3D] = []
	_collect_static(p, Transform3D.IDENTITY, parts, xforms, true)
	var entry: Dictionary
	if _merged.has(key):
		entry = _merged[key]
	else:
		entry = _build_merged(parts, xforms)
		_merged[key] = entry
	for mi: MeshInstance3D in parts:
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	if entry.is_empty():
		return null
	var out := MeshInstance3D.new()
	out.name = "Merged"
	out.mesh = entry["mesh"]
	out.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var params: Dictionary = entry["params"]
	for nm: StringName in params:
		out.set_instance_shader_parameter(nm, params[nm])
	p.add_child(out)
	return out


# ================================================================ geometry helpers (model space)

static func _barrel_r(zl: float) -> float:
	if zl <= BARREL_Z[0] or zl >= BARREL_Z[BARREL_Z.size() - 1]:
		return 0.0
	for i: int in range(1, BARREL_Z.size()):
		if zl < BARREL_Z[i]:
			return lerpf(BARREL_R[i - 1], BARREL_R[i], (zl - BARREL_Z[i - 1]) / (BARREL_Z[i] - BARREL_Z[i - 1]))
	return 0.0


## [point, outward normal] on the barrel at model z and angle a (deg from the top toward +x).
static func _barrel_pt(z: float, a_deg: float) -> Array:
	var r := _barrel_r(z - BC.z)
	var a := deg_to_rad(a_deg)
	var p := BC + Vector3(r * SX * sin(a), r * SY * cos(a), z - BC.z)
	var n := Vector3(sin(a) / maxf(r * SX, 0.05), cos(a) / maxf(r * SY, 0.05), 0.0).normalized()
	return [p, n]


## [point, outward normal] on an ellipsoid at azimuth theta (deg from +z toward +x) and elevation phi (deg).
static func _ell_pt(c: Vector3, r: Vector3, theta_deg: float, phi_deg: float) -> Array:
	var th := deg_to_rad(theta_deg)
	var ph := deg_to_rad(phi_deg)
	var u := Vector3(cos(ph) * sin(th), sin(ph), cos(ph) * cos(th))
	return [c + u * r, (u / r).normalized()]


static func _ell(s: Dictionary, mat: Material, c: Vector3, r: Vector3, seg: int = 12, rings: int = 6) -> void:
	sculpt_put(s, sphere(1.0, seg, rings), mat, c, Vector3.ZERO, r)


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var fur := m("mammoth_fur")
	var dark := m("mammoth_fur_dark")
	var pale := m("ice_fur_pale")
	var ice := m("ice_frost_crystal")
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	var steel := m("ice_steel")
	# ---- mass: barrel, shoulder hump, rump, chest; a dark belly
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	sculpt_add(s, lathe_mesh("mammoth_barrel_v1", prof, 14), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(SX, 1, SY)), BC), fur)
	_ell(s, fur, HUMP_C, HUMP_R, 14, 7)
	_ell(s, fur, RUMP_C, RUMP_R, 12, 6)
	_ell(s, fur, CHEST_C, CHEST_R, 12, 6)
	_ell(s, dark, Vector3(0, 1.32, -0.12), Vector3(0.84, 0.36, 1.30), 12, 5)
	# ---- the long shaggy coat: a dark under-skirt to the knees, a blue-grey outer skirt over it, a mane over the
	# shoulder hump (open behind, where the howdah sits) with rimed pale tips on top, a fringe over the rump
	sculpt_fringe(s, dark, fringe_mesh("mammoth_underskirt_v1", 0.90, 1.42, 1.00, 1.56, 0.42, 0.0, 360.0, 30, 0.30,
		0.04, 0.6), Vector3(0, 1.58, -0.15))
	sculpt_fringe(s, fur, fringe_mesh("mammoth_skirt_v1", 0.97, 1.50, 1.08, 1.64, 0.38, 0.0, 360.0, 28, 0.24, 0.04,
		0.55), Vector3(0, 1.92, -0.15))
	sculpt_fringe(s, fur, fringe_mesh("mammoth_mane_v1", 0.56, 0.62, 0.95, 1.00, 0.55, -128.0, 128.0, 20, 0.26, 0.04,
		0.5), HUMP_C + Vector3(0, 0.38, 0.02))
	# G-C: the rimed hump crest as shaggy locks lying back and down over the hump (was a flat 13-tooth ring that read
	# as a cog from the RTS camera), pale frost tips on the crest, darker locks below them
	for i: int in 11:
		var th: float = -150.0 + 30.0 * float(i)
		var e := _ell_pt(HUMP_C, HUMP_R, th, 58.0)
		var nn: Vector3 = e[1]
		var dn := (nn * 0.45 + Vector3(0, -0.55, -0.55)).normalized()
		sculpt_lock(s, pale if i % 2 == 0 else fur, (e[0] as Vector3) - nn * 0.04, dn, nn, 0.34, 0.62 - 0.08 * float(i % 3), 0.10)
	for i: int in 4:
		var th2: float = -45.0 + 30.0 * float(i)
		var e2 := _ell_pt(HUMP_C, HUMP_R, th2, 82.0)
		sculpt_lock(s, pale, (e2[0] as Vector3) - Vector3(0, 0.04, 0), Vector3(0.2 * sin(deg_to_rad(th2)), -0.35, -1.0).normalized(),
			Vector3.UP, 0.30, 0.48, 0.09)
	sculpt_fringe(s, fur, fringe_mesh("mammoth_rumpfur_v1", 0.52, 0.42, 0.90, 0.74, 0.50, 112.0, 248.0, 12, 0.24,
		0.04, 0.5), RUMP_C + Vector3(0, 0.44, -0.04))
	# throat beard: long locks from the chest front, hanging between the front legs
	for i: int in 7:
		var x: float = -0.45 + 0.15 * float(i)
		var root := Vector3(x, 2.30 - absf(x) * 0.4, CHEST_C.z + CHEST_R.z * 0.86 - absf(x) * 0.35)
		sculpt_lock(s, dark if i % 2 == 0 else fur, root, Vector3(x * 0.3, -1.0, 0.18).normalized(),
			Vector3(x, -0.1, 1.0).normalized(), 0.30, 0.95 - absf(x) * 0.5, 0.10)
	# flank locks over the skirt top (shaggy break-up of the outline)
	for sx: float in [-1.0, 1.0]:
		for i: int in 6:
			var z: float = 0.95 - 0.42 * float(i)
			var e := _barrel_pt(z, 64.0 * sx)
			var nn: Vector3 = e[1]
			sculpt_lock(s, fur if i % 2 == 0 else dark, (e[0] as Vector3) - nn * 0.05, (nn * 0.35 + Vector3.DOWN).normalized(),
				nn, 0.34, 0.62, 0.10)
	# icicles hanging from the outer skirt hem (small, pointing down)
	for i: int in 10:
		var a: float = TAU * (float(i) + 0.5) / 10.0
		var at := Vector3(1.06 * sin(a), 1.44, -0.15 + 1.60 * cos(a))
		sculpt_crystal(s, ice, at + Vector3(0, 0.06, 0), Vector3(0.12 * sin(a), -1.0, 0.12 * cos(a)), 0.05, 0.26, 0.55, 15.0)
	# frost crystals growing out of the rimed hump crest (leaning forward, clear of the howdah)
	var ht := HUMP_C + Vector3(0, HUMP_R.y, 0)
	for c: Array in [[Vector3(0.0, -0.02, 0.20), Vector3(0.0, 1.0, 0.7), 0.10, 0.50],
			[Vector3(0.20, -0.07, 0.10), Vector3(0.5, 1.0, 0.5), 0.08, 0.36],
			[Vector3(-0.20, -0.07, 0.12), Vector3(-0.5, 1.0, 0.55), 0.08, 0.38]]:
		sculpt_crystal(s, ice, ht + (c[0] as Vector3), c[1], c[2], c[3], 0.45, 10.0)
	# ---- team saddle-blanket under the howdah: draped over the back, dark hems, snowflake emblems on the flanks
	var at0 := Transform3D(Basis.IDENTITY, BC)
	var l0: float = -1.07 - BC.z
	var l1: float = -0.20 - BC.z
	var r0: float = _barrel_r(l0)
	var r1: float = _barrel_r(l1)
	var rx: float = r0 * SX + 0.07
	var ry: float = r0 * SY + 0.07
	var taper: float = (r1 * SY + 0.07) / ry
	sculpt_add(s, shell_mesh("mammoth_blanket_v1", rx, ry, -84.0, 84.0, l0, l1, 0.04, 16, 3, taper, 0.0), at0, cloth)
	for sx: float in [-1.0, 1.0]:
		var a0: float = 74.0 * sx
		var a1: float = 88.0 * sx
		sculpt_add(s, shell_mesh("mammoth_hem_%s" % sx, rx + 0.012, ry + 0.012, minf(a0, a1), maxf(a0, a1), l0 - 0.01,
			l1 + 0.01, 0.05, 2, 3, taper), at0, cdark)
		# emblem: a big dark diamond with a pale-team 6-point snowflake
		var e := _barrel_pt(-0.66, 58.0 * sx)
		var nn: Vector3 = e[1]
		var ep: Vector3 = (e[0] as Vector3) + nn * 0.10
		var eb := frame(ep, Vector3.UP, nn).basis
		sculpt_add(s, box(Vector3(0.44, 0.44, 0.03)), Transform3D(eb * Basis(Vector3.BACK, PI * 0.25), ep), cdark)
		for k: int in 3:
			sculpt_add(s, box(Vector3(0.06, 0.40, 0.03)), Transform3D(eb * Basis(Vector3.BACK, PI / 3.0 * float(k)),
				ep + nn * 0.016), cloth)
	for end: int in 2:
		var la: float = l0 - 0.02 if end == 0 else l1 - 0.05
		var sc: float = 1.0 if end == 0 else taper
		sculpt_add(s, shell_mesh("mammoth_hemend_%d" % end, rx * sc + 0.014, ry * sc + 0.014, -84.0, 84.0, la, la + 0.07,
			0.05, 16, 1), at0, cdark)
	# girths (leather bands around the belly) with steel buckles, and a breast strap around the chest front
	for gz: float in [-0.40, -0.92]:
		var rr: float = _barrel_r(gz - BC.z)
		sculpt_add(s, shell_mesh("mammoth_girth_%s" % gz, rr * SX + 0.09, rr * SY + 0.09, -180.0, 180.0, gz - BC.z - 0.07,
			gz - BC.z + 0.07, 0.03, 18, 1), at0, leather)
		for sx: float in [-1.0, 1.0]:
			var e := _barrel_pt(gz, 100.0 * sx)
			sculpt_put(s, box(Vector3(0.05, 0.20, 0.20)), steel, (e[0] as Vector3) + (e[1] as Vector3) * 0.11)
	var strap := PackedVector3Array([Vector3(-0.90, 2.62, 0.05), Vector3(-0.86, 2.28, 0.80), Vector3(-0.55, 2.02, 1.50),
		Vector3(0.0, 1.94, 1.70), Vector3(0.55, 2.02, 1.50), Vector3(0.86, 2.28, 0.80), Vector3(0.90, 2.62, 0.05)])
	sculpt_add(s, tube_mesh("mammoth_breaststrap_v1", strap, PackedFloat32Array([0.06, 0.07, 0.07, 0.07, 0.07, 0.07, 0.06]),
		6, true), Transform3D.IDENTITY, leather)
	sculpt_put(s, sphere(0.12, 8, 4), steel, Vector3(0.0, 1.94, 1.74), Vector3.ZERO, Vector3(1.0, 1.0, 0.5))


# ================================================================ head (skull, tusks)

func _head_sculpt(s: Dictionary) -> void:
	var fur := m("mammoth_fur")
	var dark := m("mammoth_fur_dark")
	var pale := m("ice_fur_pale")
	var skin := m("ice_fur")
	var ivory := m("mammoth_ivory")
	var ice := m("ice_frost_crystal")
	var deep := m("ice_frost_deep")
	var steel := m("ice_steel")
	var glow := m("ice_glow_unit")
	# ---- skull: tall cranium + high dome, a heavy muzzle with the tusk sockets, mouth
	_ell(s, fur, SKULL_C, SKULL_R, 12, 6)
	_ell(s, fur, DOME_C, DOME_R, 10, 5)
	_ell(s, fur, MUZZLE_C, MUZZLE_R, 12, 6)
	_ell(s, fur, Vector3(0, 2.58, 1.50), Vector3(0.70, 0.78, 0.46), 10, 5)   # neck joint (hidden seam)
	for sx: float in [-1.0, 1.0]:
		_ell(s, dark, Vector3(0.30 * sx, 2.28, 2.28), Vector3(0.21, 0.26, 0.24), 8, 4)
	_ell(s, skin, Vector3(0, 1.98, 2.16), Vector3(0.24, 0.14, 0.22), 8, 4)
	# ---- eyes (small, deep-set, a cold glint), brows, ears
	for sx: float in [-1.0, 1.0]:
		var eye := Vector3(0.50 * sx, 2.82, 2.10)
		sculpt_put(s, sphere(0.09, 6, 3), skin, eye - Vector3(0.02 * sx, 0, 0), Vector3(0, 30.0 * sx, 0), Vector3(0.8, 0.8, 1.2))
		var eb := Basis(Vector3.UP, 0.55 * sx) * Basis(Vector3.BACK, -0.30 * sx)
		sculpt_add(s, box(Vector3(0.06, 0.045, 0.15)), Transform3D(eb, eye + Vector3(0.015 * sx, 0.0, 0.01)), glow)
		sculpt_put(s, sphere(0.14, 6, 3), fur, eye + Vector3(-0.03 * sx, 0.10, -0.02), Vector3(-15, 25.0 * sx, 0),
			Vector3(1.0, 0.5, 1.5))
		var ear := Vector3(0.60 * sx, 3.00, 1.60)
		sculpt_put(s, sphere(0.24, 8, 4), dark, ear, Vector3(0, -20.0 * sx, 10.0 * sx), Vector3(0.42, 1.0, 0.9))
		sculpt_lock(s, fur, ear + Vector3(0.05 * sx, 0.12, -0.02), Vector3(0.3 * sx, -1.0, -0.2).normalized(),
			Vector3(sx, 0, 0), 0.30, 0.40, 0.08)
	# ---- hair: a rimed pale crown on the dome, a ruff over the back of the skull (hides the neck seam), cheek locks,
	# a beard under the jaw
	# G-C: a shaggy frosted topknot (locks falling from the crown of the dome all round, longest at the back) instead
	# of the flat 12-tooth ring that read as a cog from above
	for i: int in 10:
		var a: float = TAU * float(i) / 10.0 + 0.3
		var out := Vector3(sin(a), 0.0, cos(a))
		var base := DOME_C + Vector3(0, DOME_R.y - 0.03, 0) + out * 0.13
		var back: float = 0.5 - 0.5 * cos(a)   # 0 at the front, 1 at the back
		sculpt_lock(s, pale if i % 2 == 0 else fur, base, (out * 0.75 + Vector3(0, -0.6, 0)).normalized(), (out + Vector3.UP * 0.3).normalized(),
			0.30, 0.40 + 0.22 * back, 0.09)
	sculpt_fringe(s, fur, fringe_mesh("mammoth_ruff_v1", 0.52, 0.42, 0.80, 0.62, 0.50, 100.0, 260.0, 11, 0.24, 0.04,
		0.5), Vector3(0, 3.02, 1.62))
	for sx: float in [-1.0, 1.0]:
		for k: int in 3:
			var root := Vector3(0.52 * sx, 2.78 - 0.16 * float(k), 1.78 + 0.12 * float(k))
			sculpt_lock(s, fur if k != 1 else dark, root, Vector3(0.25 * sx, -1.0, 0.05).normalized(), Vector3(sx, 0, 0.3).normalized(),
				0.26, 0.50 - 0.08 * float(k), 0.08)
	for i: int in 5:
		var x: float = -0.24 + 0.12 * float(i)
		sculpt_lock(s, dark if i % 2 == 0 else fur, Vector3(x, 2.02, 1.98 - absf(x) * 0.3), Vector3(x * 0.5, -1.0, -0.1).normalized(),
			Vector3(x, -0.2, 1.0).normalized(), 0.22, 0.55 - absf(x), 0.08)
	# ---- THE TUSKS: ivory from the sockets, curving down, out and up; the outer third capped in faceted ice (plates
	# + spikes), a steel band at the cap, a crystal point with a glowing tip
	for sx: float in [-1.0, 1.0]:
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		for i: int in ICE_FROM + 2:
			pts.append(_mx(TUSK_P[i], sx))
			rad.append(TUSK_R[i])
		sculpt_add(s, tube_mesh("mammoth_tusk_%s" % sx, pts, rad, 10, true), Transform3D.IDENTITY, ivory)
		var ipts := PackedVector3Array()
		var irad := PackedFloat32Array()
		for i: int in range(ICE_FROM, TUSK_P.size() - 1):
			ipts.append(_mx(TUSK_P[i], sx))
			irad.append(TUSK_R[i] + 0.035)
		sculpt_add(s, tube_mesh("mammoth_tuskice_%s" % sx, ipts, irad, 7, true, 0.9), Transform3D.IDENTITY, deep)
		# overlapping crystal sheath plates
		for i: int in [ICE_FROM, ICE_FROM + 1]:
			var p0 := _mx(TUSK_P[i], sx)
			var p1 := _mx(TUSK_P[i + 1], sx)
			var t := (p1 - p0).normalized()
			var seg: float = (p1 - p0).length()
			var r: float = TUSK_R[i]
			var b := Basis(Quaternion(Vector3.UP, t))
			sculpt_add(s, cyl(r * 1.05, r * 1.42, seg * 0.72, 6), Transform3D(b * Basis(Vector3.UP, 0.4 * float(i)),
				p0 + t * seg * 0.36), ice)
		# spikes along the outer-top of the cap (the ice read from above)
		for k: int in 4:
			var u: float = float(ICE_FROM) + 0.35 + 0.55 * float(k)
			var i0: int = int(floor(u))
			var p := _mx(TUSK_P[i0], sx).lerp(_mx(TUSK_P[i0 + 1], sx), u - float(i0))
			var t := (_mx(TUSK_P[i0 + 1], sx) - _mx(TUSK_P[i0], sx)).normalized()
			var out := (Vector3(sx, 0.9, 0.0) - t * Vector3(sx, 0.9, 0.0).dot(t)).normalized()
			var r: float = lerpf(TUSK_R[i0], TUSK_R[i0 + 1], u - float(i0))
			sculpt_crystal(s, ice, p + out * r * 0.8, (out + t * 0.5).normalized(), 0.055, 0.24 - 0.03 * float(k), 0.55, 20.0 * float(k))
		# steel bands where the ice cap starts
		for bu: float in [ICE_FROM - 0.2, ICE_FROM - 0.45]:
			var i0: int = int(floor(bu))
			var p := _mx(TUSK_P[i0], sx).lerp(_mx(TUSK_P[i0 + 1], sx), bu - float(i0))
			var t := (_mx(TUSK_P[i0 + 1], sx) - _mx(TUSK_P[i0], sx)).normalized()
			var r: float = lerpf(TUSK_R[i0], TUSK_R[i0 + 1], bu - float(i0))
			sculpt_add(s, torus(r * 0.92, r + 0.06, 14), Transform3D(Basis(Quaternion(Vector3.UP, t)), p), steel)
		# the crystal point and its glowing tip
		var p5 := _mx(TUSK_P[TUSK_P.size() - 2], sx)
		var p6 := _mx(TUSK_P[TUSK_P.size() - 1], sx)
		var td := (p6 - p5).normalized()
		sculpt_crystal(s, ice, p5 - td * 0.04, td, 0.16, (p6 - p5).length() + 0.12, 0.5, 30.0)
		sculpt_add(s, cyl(0.0, 0.07, 0.26, 6), Transform3D(Basis(Quaternion(Vector3.UP, td)), p6 + td * 0.02), glow)


static func _mx(p: Vector3, sx: float) -> Vector3:
	return Vector3(p.x * sx, p.y, p.z)


# ================================================================ trunk (two pivots)

func _trunk1_sculpt(s: Dictionary) -> void:
	var fur := m("mammoth_fur")
	var dark := m("mammoth_fur_dark")
	var pts := PackedVector3Array(TRUNK1_P)
	sculpt_add(s, tube_mesh("mammoth_trunk1_v1", pts, PackedFloat32Array(TRUNK1_R), 10, true), Transform3D.IDENTITY, fur)
	# shaggy hair on the upper trunk
	for i: int in 4:
		var t: float = 0.25 + 0.22 * float(i)
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var root := TRUNK1_P[1].lerp(TRUNK1_P[3], t) + Vector3(0.16 * sx, 0.0, 0.10)
		sculpt_lock(s, dark if i % 2 == 0 else fur, root, Vector3(0.3 * sx, -1.0, 0.2).normalized(), Vector3(sx, 0, 0.6).normalized(),
			0.20, 0.34, 0.07)


func _trunk2_sculpt(s: Dictionary) -> void:
	var dark := m("mammoth_fur_dark")
	var skin := m("ice_fur")
	var pts := PackedVector3Array(TRUNK2_P)
	sculpt_add(s, tube_mesh("mammoth_trunk2_v1", pts, PackedFloat32Array(TRUNK2_R), 10, true), Transform3D.IDENTITY, dark)
	# wrinkle rings
	for i: int in 5:
		var u: float = 0.3 + 0.55 * float(i)
		var i0: int = mini(int(floor(u)), TRUNK2_P.size() - 2)
		var p := TRUNK2_P[i0].lerp(TRUNK2_P[i0 + 1], u - float(i0))
		var t := (TRUNK2_P[i0 + 1] - TRUNK2_P[i0]).normalized()
		var r: float = lerpf(TRUNK2_R[i0], TRUNK2_R[i0 + 1], u - float(i0))
		sculpt_add(s, torus(r * 0.9, r + 0.025, 12), Transform3D(Basis(Quaternion(Vector3.UP, t)), p), skin)
	# the tip "fingers"
	var tip := TRUNK2_P[TRUNK2_P.size() - 1]
	sculpt_put(s, sphere(0.075, 6, 3), skin, tip + Vector3(0, 0.03, 0.04))
	sculpt_put(s, sphere(0.06, 6, 3), skin, tip + Vector3(0, -0.05, 0.02))


# ================================================================ legs + tail

## A pillar leg rooted at the pivot p: fur thigh, dark lower leg, two layered fur fringes (knee, boot), a wide dark
## sole pad with 4 ivory toenails.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var fur := m("mammoth_fur")
	var dark := m("mammoth_fur_dark")
	var skin := m("ice_fur")
	var ivory := m("mammoth_ivory")
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	var lean: float = 0.03 if front else -0.03
	sculpt_add(s, tube_mesh("mammoth_thigh_%s" % front, PackedVector3Array([Vector3(0, 1.82, 0), Vector3(0, 1.30, lean * 0.6),
		Vector3(0, 0.94, lean)]), PackedFloat32Array([0.42, 0.38, 0.34]), 10, false), Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), fur)
	sculpt_add(s, tube_mesh("mammoth_shin_%s" % front, PackedVector3Array([Vector3(0, 0.98, lean), Vector3(0, 0.55, 0.05),
		Vector3(0, 0.20, 0.06)]), PackedFloat32Array([0.33, 0.31, 0.36]), 10, false), Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), dark)
	sculpt_put(s, sphere(0.40, 12, 4), skin, Vector3(x, 0.17, z + 0.06), Vector3.ZERO, Vector3(1.0, 0.34, 1.06))
	for k: int in 4:
		var a: float = deg_to_rad(-48.0 + 32.0 * float(k))
		sculpt_put(s, sphere(0.085, 6, 3), ivory, Vector3(x + 0.36 * sin(a), 0.12, z + 0.06 + 0.36 * cos(a)),
			Vector3(0, rad_to_deg(a), 0), Vector3(1.1, 0.8, 0.9))
	sculpt_fringe(s, dark, fringe_mesh("mammoth_knee_v1", 0.38, 0.38, 0.48, 0.48, 0.28, 0.0, 360.0, 9, 0.13, 0.035, 0.6),
		Vector3(x, 1.24, z + lean))
	sculpt_fringe(s, fur, fringe_mesh("mammoth_boot_v1", 0.33, 0.33, 0.45, 0.45, 0.32, 0.0, 360.0, 10, 0.15, 0.035, 0.6),
		Vector3(x, 0.78, z + 0.05))


func _tail_sculpt(s: Dictionary) -> void:
	var fur := m("mammoth_fur")
	var dark := m("mammoth_fur_dark")
	var tp := PackedVector3Array([Vector3(0, 2.42, -1.62), Vector3(0, 2.18, -1.80), Vector3(0, 1.88, -1.88),
		Vector3(0, 1.64, -1.90)])
	sculpt_add(s, tube_mesh("mammoth_tail_v1", tp, PackedFloat32Array([0.11, 0.08, 0.065, 0.05]), 6), Transform3D.IDENTITY, fur)
	for i: int in 6:
		var a := TAU * float(i) / 6.0
		var out := Vector3(sin(a), 0.0, cos(a) * 0.6 - 0.4).normalized()
		sculpt_lock(s, dark if i % 2 == 0 else fur, tp[3] + Vector3(0, 0.06, 0) + out * 0.03,
			(out * 0.25 + Vector3.DOWN).normalized(), out, 0.14, 0.34, 0.05)


# ================================================================ frost mist

## Soft MIX puffs drifting off the ground around the feet (art-keep 0.6: unshaded billboards, soft gradient).
## Built once per game (process / draw resources shared by every mammoth), one node per mammoth.
static func _make_mist() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "FrostMist"
	p.amount = 16
	p.lifetime = 2.8
	p.preprocess = 1.4
	p.local_coords = false
	p.fixed_fps = 30
	p.interpolate = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-5.0, -1.0, -7.0), Vector3(10.0, 4.0, 14.0))
	var pm: ParticleProcessMaterial = _fx_cache.get("mist_pm")
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(1.15, 0.06, 1.70)
		pm.direction = Vector3.UP
		pm.spread = 88.0
		pm.initial_velocity_min = 0.08
		pm.initial_velocity_max = 0.22
		pm.gravity = Vector3(0, -0.02, 0)
		pm.damping_min = 0.05
		pm.damping_max = 0.15
		pm.scale_min = 0.8
		pm.scale_max = 1.25
		pm.angle_min = -180.0
		pm.angle_max = 180.0
		var sc := CurveTexture.new()
		var cv := Curve.new()
		cv.add_point(Vector2(0, 0.45))
		cv.add_point(Vector2(1, 1.0))
		sc.curve = cv
		pm.scale_curve = sc
		var ramp := GradientTexture1D.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.86, 0.94, 1.0, 0.0))
		g.set_color(1, Color(0.80, 0.90, 1.0, 0.0))
		g.add_point(0.25, Color(0.88, 0.95, 1.0, 0.28))
		g.add_point(0.65, Color(0.84, 0.93, 1.0, 0.18))
		ramp.gradient = g
		pm.color_ramp = ramp
		_fx_cache["mist_pm"] = pm
	p.process_material = pm
	var q: QuadMesh = _fx_cache.get("mist_quad")
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(1.8, 1.8)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		# the billboards cross the ground: fade them where they meet it (no hard cut lines)
		sm.proximity_fade_enabled = true
		sm.proximity_fade_distance = 0.7
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true
		sm.vertex_color_use_as_albedo = true
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		var gt := GradientTexture2D.new()
		var tg := Gradient.new()
		tg.set_color(0, Color(1, 1, 1, 1))
		tg.set_color(1, Color(1, 1, 1, 0))
		tg.add_point(0.4, Color(1, 1, 1, 0.6))
		gt.gradient = tg
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		sm.albedo_texture = gt
		q.material = sm
		_fx_cache["mist_quad"] = q
	p.draw_pass_1 = q
	return p


# ================================================================ lifecycle

func _mount_ready() -> void:
	_frost_v = 0.0
	_howdah = get_node_or_null(^"Root/Mount/Seat/Howdah") as Node3D
	for mi: MeshInstance3D in _trunk_mi:
		if mi and not _flash_hit_targets.has(mi):
			_flash_hit_targets.append(mi)
	# A titan: the head (tusks) and the legs cast sun shadows too (a mount's kit default is the body only).
	for i: int in [P_MOUNT_HEAD, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		var mi: MeshInstance3D = _merged_nodes.get(i)
		if mi:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if _mist:
		_mist.emitting = _tier < 2 and not _dead


# ================================================================ hooks

func set_team_color(c: Color) -> void:
	super(c)
	var h := _howdah_node()
	if h and h.has_method(&"set_team_color"):
		h.call(&"set_team_color", c)


func play_hit() -> void:
	super()
	var h := _howdah_node()
	if h and not _dead and h.has_method(&"play_hit"):
		h.call(&"play_hit")


func play_death() -> void:
	if _dead:
		return
	super()
	_tr_t = 99.0
	if _mist:
		_mist.emitting = false
	var h := _howdah_node()
	if h and h.has_method(&"play_death"):
		h.call(&"play_death")


func revive() -> void:
	super()
	var h := _howdah_node()
	if h and h.has_method(&"revive"):
		h.call(&"revive")


func set_status(id: StringName, on: bool) -> bool:
	var r: bool = super(id, on)
	var h := _howdah_node()
	if h and h.has_method(&"set_status"):
		h.call(&"set_status", id, on)
	return r


## The trample stomp (cavalry-mounts.md 5.2; TitanAbilities calls it on each trample tick while moving). Overlays the
## gait: a front foot slams down, the tusks sweep aside (the side alternates each call), the trunk swings; a trumpet
## (trunk thrown up) when the last trample was more than 3 s ago. trample_stomped(at) fires at TRAMPLE_HIT.
func play_trample() -> void:
	if _dead:
		return
	_tr_big = _t - _tr_last > 3.0
	_tr_last = _t
	_tr_t = 0.0
	_tr_side = -_tr_side
	if _action == &"":
		_action = &"trample"   # a private action id (the kit only advances _action_t): keeps the pose path alive
		_action_t = 0.0
	_flare = maxf(_flare, 0.45)
	set_process(true)


## The howdah archer's shot (cavalry-mounts.md 5.2 howdah): forwarded to the howdah child scene. target: a Node3D
## or a world Vector3 (the archer turns and aims at it), or null (shoots ahead). Release at HOWDAH_RELEASE.
func play_howdah_shot(target: Variant = null) -> void:
	var h := _howdah_node()
	if h and not _dead and h.has_method(&"play_howdah_shot"):
		h.call(&"play_howdah_shot", target)


func get_howdah() -> Node3D:
	return _howdah_node()


## World position of the nocked arrow's tip (bolt VFX origin); the howdah's position when it has none.
func get_howdah_muzzle() -> Vector3:
	var h := _howdah_node()
	if h and h.has_method(&"get_muzzle"):
		return h.call(&"get_muzzle")
	return global_position + Vector3.UP * body_height


func _howdah_node() -> Node3D:
	if _howdah == null:
		_howdah = get_node_or_null(^"Root/Mount/Seat/Howdah") as Node3D
	return _howdah


# ================================================================ motion (on top of MountModel)

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"tusk_gore":
		return super(prev, t)
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, GO_HEAD_X) * DEG, _mkf(t, GO_HEAD_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _mkf(t, GO_ROOT_Z)))
	rot(P_MOUNT, Vector3(_mkf(t, GO_BODY_X) * DEG, 0, 0))
	var f := _mkf(t, GO_LEG_F) * DEG * (1.0 - 0.6 * _walk_w)
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.8, 0, 0))
	xrot(X_TAIL, Vector3(12.0 * DEG * smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.4, 0.9, t)), 0, 0))
	_trunk_off[0] += Vector3(_mkf(t, GO_TRUNK) * DEG, 0, 0)
	_trunk_off[1] += Vector3(_mkf(t, GO_TRUNK) * 0.8 * DEG, 0, 0)
	if prev < GORE_HIT and t >= GORE_HIT:
		_flare = maxf(_flare, 0.8)
		_on_action_event(&"release")
	return t < GORE_LEN


## Idle fidget (every ~fidget_every s): the trunk rises and curls into a trumpet, the head lifts, a front foot stamps,
## then a frost shake runs through the coat.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.45, 1.2, 1.7, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(-12.0 * DEG * up, 8.0 * DEG * sin(t * 2.4) * up, 0))
	_trunk_off[0] += Vector3(-70.0 * DEG * up, 12.0 * DEG * sin(t * 3.0) * up, 0)
	_trunk_off[1] += Vector3(-55.0 * DEG * up, 0, 10.0 * DEG * sin(t * 4.0) * up)
	var stamp := _k3(t, 1.55, 1.75, 1.85, 2.0, 1.0, -0.3)
	rot(P_LEG_FR, Vector3(-18.0 * DEG * maxf(stamp, 0.0), 0, 0))
	pos(P_LEG_FR, Vector3(0, 0.14 * maxf(stamp, 0.0), 0))
	var shake := _k3(t, 1.9, 2.0, 2.35, 2.5, 1.0, 1.0)
	rot(P_MOUNT, Vector3(0, 0, 2.2 * DEG * sin(t * TAU * 7.0) * shake))
	xrot(X_TAIL, Vector3(8.0 * DEG * shake, 24.0 * DEG * sin(t * TAU * 3.0) * shake, 0))
	if _fidget_prev < 1.0 and t >= 1.0:
		_flare = maxf(_flare, 0.6)
		_on_mount_event(&"fidget_snort")
	return 2.5


func _mount_process(dt: float) -> void:
	# trample overlay
	if _tr_t < TRAMPLE_LEN:
		var prev := _tr_t
		_tr_t += dt
		if not _fast and not _dead:
			_pose_trample(_tr_t)
		if prev < TRAMPLE_HIT and _tr_t >= TRAMPLE_HIT and not _dead:
			trample_stomped.emit(_stomp_point())
		if _tr_t >= TRAMPLE_LEN and _action == &"trample":
			_action = &""
	elif _action == &"trample":
		_action = &""
	_trunk_tick()
	if _dead:
		# The base death lolls the head 18 deg further toward the ground: with 1.8 m of tusks that digs them in; keep
		# the head in line with the body (the down-side tusk rests on the ground).
		rot(P_MOUNT_HEAD, Vector3(0, 0, _mkf(_death_t, D_HEAD_Z) * DEG * _fall_side * 0.85))
		_death_frost()
		if _mist and _mist.emitting:
			_mist.emitting = false


func _pose_trample(t: float) -> void:
	var s := _tr_side
	var lift := _mkf(t, TR_LIFT)
	var leg: int = P_LEG_FL if s < 0.0 else P_LEG_FR
	rot(leg, Vector3((-24.0 * maxf(lift, 0.0) + 8.0 * minf(lift, 0.0)) * DEG, 0, 0))
	pos(leg, Vector3(0, 0.20 * maxf(lift, 0.0), 0))
	var sw := _mkf(t, TR_SWEEP)
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, TR_HEAD_X) * DEG, 16.0 * DEG * sw * s, -7.0 * DEG * sw * s))
	rot(P_MOUNT, Vector3(0, 0, 2.5 * DEG * maxf(lift, 0.0) * -s))
	pos(P_ROOT, Vector3(0, _mkf(t, TR_DIP), 0))
	var tk := -sw * s
	var env := _k3(t, 0.0, 0.15, 0.4, 0.8, 1.0, 1.0)
	_trunk_off[0] += Vector3(-6.0 * DEG * env, 0, 10.0 * DEG * tk)
	_trunk_off[1] += Vector3(-14.0 * DEG * env, 0, 16.0 * DEG * tk)
	if _tr_big:
		var up := _k3(t, 0.0, 0.2, 0.45, 0.8, 1.0, 1.0)
		_trunk_off[0] += Vector3(-80.0 * DEG * up, 0, 0)
		_trunk_off[1] += Vector3(-60.0 * DEG * up, 0, 0)
		rot(P_MOUNT_HEAD, Vector3(-10.0 * DEG * up, 0, 0))


## World point where the stomping foot lands (the trample centre is about there).
func _stomp_point() -> Vector3:
	var leg: Node3D = _piv[P_LEG_FL] if _tr_side < 0.0 else _piv[P_LEG_FR]
	if leg == null or not is_inside_tree():
		return global_position
	var lp := leg.global_position
	return Vector3(lp.x, global_position.y, lp.z)


## Trunk: idle sway, a pendulum swing following the gait (lags the head), plus this frame's pose offsets. Written
## every processed frame (also on the idle fast path), only when changed.
func _trunk_tick() -> void:
	if _trunk[0] == null:
		return
	var r0 := _trunk_off[0]
	var r1 := _trunk_off[1]
	_trunk_off[0] = Vector3.ZERO
	_trunk_off[1] = Vector3.ZERO
	if not _dead and _tier < 2:
		var ph: float = (_t + _phase_off) * TAU / idle_period
		var idle := 1.0 - _walk_w
		r0 += Vector3(3.0 * sin(ph * 1.1), 5.0 * sin(ph * 0.7 + 1.0), 4.0 * sin(ph * 0.9 + 0.3)) * DEG * idle
		r1 += Vector3(-6.0 + 5.0 * sin(ph * 1.1 - 0.8), 0.0, 7.0 * sin(ph * 0.9 - 0.6)) * DEG * idle
		if _walk_w > 0.0:
			var p := _gait_p
			r0 += Vector3(7.0 * sin(2.0 * TAU * p - 0.8), 0.0, 6.0 * sin(TAU * p - 0.6)) * DEG * _walk_w
			r1 += Vector3(-4.0 + 10.0 * sin(2.0 * TAU * p - 1.6), 0.0, 9.0 * sin(TAU * p - 1.3)) * DEG * _walk_w
		if _hit_t < HIT_LEN:
			var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
			r0 += Vector3(12.0 * DEG * k, 0, 0)
			r1 += Vector3(18.0 * DEG * k, 0, 0)
	elif _dead:
		var k := smoothstep(0.1, 0.6, _death_t)
		r0 += Vector3(-10.0 * DEG * k, 0, 0)
		r1 += Vector3(-25.0 * DEG * k, 0, 0)
	for j: int in 2:
		var r: Vector3 = r0 if j == 0 else r1
		if r != _trunk_last[j] or _force_write:
			_trunk_last[j] = r
			_trunk[j].rotation = r


## Death: the body frosts over as it goes down (Ice idiom; the titan stays lying there).
func _death_frost() -> void:
	var v: float = snappedf(0.30 * smoothstep(0.15, 0.85, _death_t), 0.02)
	if v == _frost_v:
		return
	_frost_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", FROST)


func _mount_revive() -> void:
	_frost_v = 0.0
	_tr_t = 99.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE)
	for j: int in 2:
		_trunk_last[j] = Vector3(INF, 0, 0)
	if _mist:
		_mist.emitting = _tier < 2
