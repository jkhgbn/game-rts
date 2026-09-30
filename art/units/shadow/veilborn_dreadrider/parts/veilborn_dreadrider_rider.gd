class_name VeilbornDreadriderRider
extends ShadowModel
## Veilborn Dreadrider rider (stables.md 2, Shadow V: the tier-3 elite, the army's anchor). Seated with the kit's
## CharacterModel.set_seated on the Veil Steed (parts/veil_steed.tscn: the barded Dusk Steed with obsidian horns, a long
## trailing team veil and smoke at the hooves); the scene pairing them is veilborn_dreadrider.tscn
## (VeilbornDreadriderModel, x1.03). Extends ShadowModel for the Shadow dissolve death and the glowing eyes.
## Look (the dread knight, kept apart from the Gloam Rider's hooded lancer and the Barrow Knight's crowned flail): tall and
## narrow in obsidian plate edged in tarnished silver, a team surcoat split to the saddle, tarnished-silver pauldrons with an
## obsidian horn each (the light tops of the dark figure), and
## THE VEIL: a vast tattered team cloak (dark lining) streaming back over the steed; a close obsidian helm with a T-slit
## open face and two long HORNS sweeping back from the temples (FaceKit: a gaunt pale face, glowing violet eyes, black
## lips, ink strands); in the right fist a SCYTHE-GLAIVE carried slanting forward: a long black shaft, a silver collar, a
## great curved blade whose inner edge glows violet.
## Glow: the scythe's edge (merged in ArmR; flares on the reap), the violet ember in the helm's brow and the eyes.
## Attack `reap` (0.78 s, melee strike STRIKE_T 0.12 s): the scythe drawn back and up over the right shoulder, then a
## great horizontal reap across the front (the chest turns through ~70 deg), a heavy recovery. play_charge() (0.85 s,
## hit 0.10 s): the scythe levelled like a lance under the arm, a lean in; charge_struck(at) at the hit frame.
## Hooks (on top of the kit's, the names GloamRiderModel forwards): play_charge(), is_charging(), get_lance_tip() /
## get_weapon_tip() (the scythe's point, world), lance_pitch() (0), couch_amount() (the charge weight), set_rank(rank)
## (no rank research for the V unit: accepted, no look), authored_mesh_count(); signals charge_struck(at),
## lance_struck(at).
## Budget (rider, JS cap ~3000 vertices with the face): 6 draw instances at rest (Hips with the legs astride, Chest with
## the veil, Head, Face, ArmL, ArmR with the scythe); no blob (the steed's shows); 0 particles, 0 lights.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

const SH_L := Vector3(-0.29, 1.38, 0.0)
const SH_R := Vector3(0.29, 1.38, 0.0)
const ELBOW_L := Vector3(-0.32, 1.10, -0.02)
const FIST_L := Vector3(-0.31, 1.05, 0.22)
const ELBOW_R := Vector3(0.33, 1.10, -0.03)
const FIST_R := Vector3(0.34, 1.06, 0.20)
const HEAD_C := Vector3(0, 1.65, 0.06)
const HEAD_R := 0.13
## The scythe: from the fist along SCY_DIR (rest: slanting forward and up), the butt behind, the blade at the top.
const SCY_DIR := Vector3(0.06, 0.52, 0.85)
const SCY_BUTT := -0.62
const SCY_TOP := 1.18
const ATTACK_LEN := 0.78
const STRIKE_T := 0.12
const CHARGE_LEN := 0.85
const CHARGE_HIT := 0.10

# Attack (reap) / charge tracks [t, v, ease, ...] (the _kf format below): arm x / z offsets, chest twist / lean.
static var R_ARM_X := PackedFloat32Array([0.0, 0.0, 0, 0.07, -58.0, 1, 0.12, -20.0, 2, 0.34, -12.0, 0, 0.78, 0.0, 0])
static var R_ARM_Z := PackedFloat32Array([0.0, 0.0, 0, 0.07, 30.0, 1, 0.12, -40.0, 2, 0.34, -30.0, 0, 0.78, 0.0, 0])
static var R_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, 34.0, 1, 0.12, -36.0, 2, 0.36, -22.0, 0, 0.78, 0.0, 0])
static var R_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -6.0, 1, 0.12, 14.0, 2, 0.36, 8.0, 0, 0.78, 0.0, 0])
static var C_K := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])

var _parts_n: int = 0
var _arm_r: Node3D
var _glow_mi: GeometryInstance3D
var _atk_t: float = 99.0
var _charge_t: float = 99.0
var _charge_k: float = 0.0
var _cast_k: float = 0.0
var _flare: float = 0.0
var _glow_w: float = -1.0


# ================================================================ public hooks

func play_charge() -> void:
	if _dead:
		return
	_charge_t = 0.0
	_flare = 1.0
	set_process(true)


func is_charging() -> bool:
	return _charge_t < CHARGE_LEN


## World position of the scythe's point (impact VFX). GloamRiderModel forwards it as get_lance_tip.
func get_lance_tip() -> Vector3:
	if _arm_r and _arm_r.is_inside_tree():
		return _arm_r.global_transform * (_blade_tip() - model_origin(_arm_r))
	return global_position + Vector3(0.3, 2.4, 1.0)


func get_weapon_tip() -> Variant:
	return get_lance_tip()


func lance_pitch() -> float:
	return 0.0


func couch_amount() -> float:
	return _charge_k


func set_rank(_rank: int) -> void:
	pass


func authored_mesh_count() -> int:
	return _parts_n


## Model-space rest position of the blade's point.
static func _blade_tip() -> Vector3:
	var d := SCY_DIR.normalized()
	var top := FIST_R + d * SCY_TOP
	var down := (Vector3.DOWN - d * Vector3.DOWN.dot(d)).normalized()
	return top + down * 0.30 - d * 0.42


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var head: Node3D = $Root/Chest/Head
	_arm_r = $Root/Chest/ArmR
	_sculpt($Root/Hips, "vb_hips_v1", _hips_sculpt)
	_sculpt($Root/Chest, "vb_chest_v2", _chest_sculpt)
	_sculpt(head, "vb_head_v2", _head_sculpt)
	# Face (FaceKit): the gaunt pale dread knight in the helm's T-slit: glowing violet eyes slanted under hard brows, dark
	# lips, black-violet strands under the helm (the helm covers the ears).
	_face = FaceKit.attach(self, head, "veilborn_dreadrider_rider", {
		"center": HEAD_C, "radius": HEAD_R, "head_mesh": sphere(HEAD_R, 10, 6), "head_scale": Vector3(0.92, 1.08, 0.94),
		"preset": &"hollow", "skin": ShadowFaces.PALE, "hair": ShadowFaces.INK, "eyes": ShadowFaces.GLOW, "detail": &"low",
		"x": NatureFaces.lean_x(1.15, {&"neutral": {"cut_in": 0.45, "mouth": {"kind": "smirk"}}}),
		"palette": ShadowFaces.pal(ShadowFaces.PALE), "eye": {"c": Vector2(0.046, 0.022), "tilt": 0.016},
		"hair_fn": func(acc: Dictionary) -> void:
			ShadowFaces.strands(acc, [HEAD_C + Vector3(0.10, 0.0, -0.02), HEAD_C + Vector3(-0.10, 0.0, -0.02)], 0.2, 0.026,
				ShadowFaces.INK, ShadowFaces.INK_TIP, Vector3(0.02, 0, -0.03)),
	})
	_sculpt($Root/Chest/ArmL, "vb_arm_l_v2", func(s: Dictionary) -> void: _arm_sculpt(s, -1.0))
	_sculpt(_arm_r, "vb_arm_r_v2", _arm_r_sculpt)


func _sculpt(pivot: Node3D, key: String, build: Callable, at: Vector3 = Vector3.ZERO, keep: bool = false,
		nm: String = "") -> MeshInstance3D:
	_parts_n += 1
	if not keep and _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var mesh := _cached_sculpt(key, build)
	if mesh == null:
		return null
	return add_part(pivot, mesh, null, at, Vector3.ZERO, Vector3.ONE, keep, nm)


static func _cached_sculpt(key: String, build: Callable) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var s := MountModel.sculpt()
	build.call(s)
	return _cached(key, MountModel.sculpt_mesh(s))


static func m(name: String) -> Material:
	return palette(StringName(name))


static func _to_dir(d: Vector3) -> Basis:
	var n := d.normalized()
	if n.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	if n.dot(Vector3.UP) > 0.9999:
		return Basis.IDENTITY
	return Basis(Quaternion(Vector3.UP, n))


static func _seg(s: Dictionary, mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	MountModel.sculpt_add(s, cyl(rb, ra, l, seg), Transform3D(_to_dir(d), a + d * 0.5), mat)


static func _put(s: Dictionary, mesh: Mesh, mat: Material, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> void:
	MountModel.sculpt_put(s, mesh, mat, at, rot_deg, scl)


static func _spike(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, r: float, h: float) -> void:
	MountModel.sculpt_add(s, cyl(0.0, r, h, 4), Transform3D(_to_dir(dir), base + dir.normalized() * h * 0.5), mat)


## Keyframe track [t, v, ease, ...] from t = 0 (ease of the segment arriving at a key: 0 smooth, 1 out, 2 in).
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


# ---------------------------------------------------------------- body

## Hips + legs astride (merged into Hips): an obsidian fauld, the surcoat's split skirts over the cantle (team), obsidian
## tassets, dark leather thighs, obsidian greaves with silver knee spikes, pointed sabatons in the stirrups.
func _hips_sculpt(s: Dictionary) -> void:
	var obs := m("shadow_obsidian")
	var sil := m("shadow_silver")
	var lea := m("shadow_leather")
	var cloth := m("shadow_cloth")
	_put(s, cyl(0.19, 0.235, 0.24, 8), obs, Vector3(0, 0.83, 0))
	_put(s, cyl(0.205, 0.205, 0.06, 8, false), sil, Vector3(0, 0.95, 0))
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.16, 0.50, 0.03)), cloth, Vector3(0.09 * sx, 0.72, -0.24), Vector3(12, 0, 6.0 * sx))
		_put(s, box(Vector3(0.04, 0.20, 0.19)), obs, Vector3(0.22 * sx, 0.84, 0.03), Vector3(0, 0, -12.0 * sx))
		var hip := Vector3(0.105 * sx, 0.85, 0.02)
		var knee := Vector3(0.30 * sx, 0.54, 0.20)
		var ankle := Vector3(0.34 * sx, 0.20, 0.08)
		_seg(s, lea, hip, knee, 0.085, 0.068, 6)
		_spike(s, sil, knee + Vector3(0, 0.0, 0.06), Vector3(0, 0.3, 1.0), 0.035, 0.12)
		_seg(s, obs, knee, ankle + Vector3(0, -0.03, 0), 0.066, 0.058, 6)
		MountModel.sculpt_add(s, cyl(0.0, 0.066, 0.30, 6), Transform3D(_to_dir(Vector3(0.04 * sx, 0.02, 1.0)),
			ankle + Vector3(0.005 * sx, -0.045, 0.12)), obs)


func _chest_sculpt(s: Dictionary) -> void:
	var obs := m("shadow_obsidian")
	var sil := m("shadow_silver")
	var lea := m("shadow_leather")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var thin := Basis.from_scale(Vector3(0.9, 1.0, 0.78))
	# the obsidian breastplate (tall, narrow), silver rims at the waist and the neck
	var prof := PackedVector2Array([Vector2(0.17, 0.92), Vector2(0.20, 1.02), Vector2(0.24, 1.17), Vector2(0.25, 1.28),
		Vector2(0.23, 1.36), Vector2(0.12, 1.44), Vector2(0.0, 1.46)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("vb_torso_v1", prof, 8), Transform3D(thin, Vector3.ZERO), obs)
	_put(s, cyl(0.20, 0.20, 0.03, 8, false), sil, Vector3(0, 1.0, 0), Vector3.ZERO, Vector3(0.9, 1.0, 0.78))
	# the team surcoat panel down the breast, a silver rune-eye on it, a dark hem
	_put(s, box(Vector3(0.24, 0.40, 0.03)), cloth, Vector3(0, 1.13, 0.20), Vector3(-5, 0, 0))
	_put(s, box(Vector3(0.245, 0.04, 0.035)), cdark, Vector3(0, 0.935, 0.205), Vector3(-5, 0, 0))
	_put(s, cyl(0.06, 0.06, 0.02, 8), sil, Vector3(0, 1.20, 0.22), Vector3(85, 0, 0), Vector3(1.0, 1.0, 0.55))
	_put(s, cyl(0.022, 0.022, 0.024, 6), obs, Vector3(0, 1.20, 0.228), Vector3(85, 0, 0))
	# the obsidian gorget, a silver rim
	_put(s, cyl(0.115, 0.155, 0.10, 8, false), obs, Vector3(0, 1.42, 0))
	# spiked obsidian pauldrons, silver rims, three swept spikes on each
	for sx: float in [-1.0, 1.0]:
		var pf := MountModel.frame(Vector3(0.30 * sx, 1.41, -0.01), Vector3(0.55 * sx, 1.0, 0.0), Vector3.BACK)
		MountModel.sculpt_add(s, MountModel.lathe_mesh("vb_pauldron_v1", PackedVector2Array([Vector2(0.16, -0.08),
			Vector2(0.165, -0.01), Vector2(0.13, 0.05), Vector2(0.06, 0.085), Vector2(0.0, 0.092)]), 8), pf, sil)
		MountModel.sculpt_add(s, cyl(0.168, 0.168, 0.028, 8, false), Transform3D(pf.basis, pf * Vector3(0, -0.06, 0)), obs)
		_spike(s, obs, pf * Vector3(0.0, 0.06, -0.02), Vector3(0.45 * sx, 1.0, -0.4), 0.04, 0.24)
	# THE VEIL: a vast tattered team cloak from the shoulders, a dark lining, streaming back over the croup
	MountModel.sculpt_fringe(s, cloth, MountModel.fringe_mesh("vb_veil_v1", 0.22, 0.12, 0.40, 0.30, 0.78, 102.0, 258.0, 7,
		0.24, 0.024, 0.8), Vector3(0, 1.40, -0.12), Basis(Vector3.RIGHT, deg_to_rad(34.0)))
	MountModel.sculpt_fringe(s, cdark, MountModel.fringe_mesh("vb_veil_in_v1", 0.21, 0.11, 0.38, 0.285, 0.86, 108.0, 252.0,
		6, 0.26, 0.02, 0.9), Vector3(0, 1.39, -0.115), Basis(Vector3.RIGHT, deg_to_rad(34.0)))
	_put(s, box(Vector3(0.44, 0.06, 0.07)), lea, Vector3(0, 1.40, -0.18))
	_put(s, sphere(0.045, 6, 3), sil, Vector3(0.20, 1.40, -0.14))
	_put(s, sphere(0.045, 6, 3), sil, Vector3(-0.20, 1.40, -0.14))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("shadow_skin")
	var obs := m("shadow_obsidian")
	var sil := m("shadow_silver")
	var bone := m("shadow_bone")
	_put(s, cyl(0.058, 0.066, 0.12, 6), skin, Vector3(0, 1.51, 0.02))
	_put(s, sphere(HEAD_R, 10, 6), skin, HEAD_C, Vector3.ZERO, Vector3(0.92, 1.08, 0.94))
	# the close obsidian helm: a dome from the brow, cheek plates wrapping to the nape (a T-slit open face), a nasal
	var hp := PackedVector2Array([Vector2(0.168, 1.715), Vector2(0.172, 1.77), Vector2(0.152, 1.84), Vector2(0.095, 1.885),
		Vector2(0.0, 1.90)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("vb_helm_v1", hp, 10),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.1)), Vector3(0, 0, -0.01)), obs)
	var tb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))   # shell z -> up, angle 0 -> +Z
	for sx: float in [-1.0, 1.0]:
		var a0: float = 30.0 * sx
		var a1: float = 180.0 * sx
		MountModel.sculpt_add(s, MountModel.shell_mesh("vb_cheek_%s_v1" % sx, 0.172, 0.19, minf(a0, a1), maxf(a0, a1), 1.50,
			1.73, 0.02, 5, 1, 0.98, 0.0), Transform3D(tb, Vector3(0, 0, -0.01)), obs)
		_seg(s, sil, Vector3(0.088 * sx, 1.50, 0.158), Vector3(0.088 * sx, 1.72, 0.155), 0.012, 0.012, 4)
		# the HORNS: from the temples, sweeping back and out, bone tips
		var hb := Vector3(0.15 * sx, 1.78, -0.02)
		MountModel.sculpt_add(s, MountModel.tube_mesh("vb_horn_%s_v1" % sx, PackedVector3Array([hb, hb + Vector3(0.10 * sx, 0.08, -0.06),
			hb + Vector3(0.16 * sx, 0.12, -0.20), hb + Vector3(0.15 * sx, 0.10, -0.36)]), PackedFloat32Array([0.045, 0.036, 0.022,
			0.0]), 5), Transform3D.IDENTITY, obs)
		_spike(s, bone, hb + Vector3(0.155 * sx, 0.115, -0.27), Vector3(-0.1 * sx, -0.1, -1.0), 0.02, 0.10)
	_seg(s, sil, Vector3(0, 1.73, 0.165), Vector3(0, 1.655, 0.19), 0.016, 0.012, 4)
	# a violet ember set in the helm's brow over the slit (a steady high glow point with the eyes)
	_put(s, sphere(0.05, 6, 3), m("shadow_glow_hero"), Vector3(0, 1.775, 0.185), Vector3.ZERO, Vector3(1.0, 1.35, 0.7))


## Obsidian arm: a leather sleeve, a silver elbow cop, an obsidian vambrace, a clawed gauntlet.
func _arm_sculpt(s: Dictionary, sx: float) -> void:
	var obs := m("shadow_obsidian")
	var sil := m("shadow_silver")
	var lea := m("shadow_leather")
	var sh: Vector3 = SH_L if sx < 0.0 else SH_R
	var el: Vector3 = ELBOW_L if sx < 0.0 else ELBOW_R
	var fi: Vector3 = FIST_L if sx < 0.0 else FIST_R
	_seg(s, lea, sh + Vector3(0, 0.02, 0), el, 0.072, 0.062, 6)
	_put(s, sphere(0.064, 6, 3), sil, el + Vector3(0, 0, -0.015))
	_seg(s, obs, el, fi - (fi - el).normalized() * 0.04, 0.068, 0.06, 6)
	_put(s, sphere(0.07, 6, 3), obs, fi, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


## The right arm and the SCYTHE-GLAIVE in its fist (merged: the arm swings it): a black shaft with a silver butt spike and
## collar, the great curved blade (tarnished silver) whose inner edge glows violet.
func _arm_r_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, 1.0)
	var lea := m("shadow_leather")
	var sil := m("shadow_silver")
	var obs := m("shadow_obsidian")
	var glow := m("shadow_glow_hero")
	var d := SCY_DIR.normalized()
	var butt := FIST_R + d * SCY_BUTT
	var top := FIST_R + d * SCY_TOP
	_seg(s, obs, butt, top, 0.03, 0.028, 5)
	_seg(s, lea, FIST_R - d * 0.12, FIST_R + d * 0.14, 0.036, 0.036, 5)
	_spike(s, sil, butt, -d, 0.03, 0.12)
	_seg(s, sil, top - d * 0.06, top + d * 0.02, 0.045, 0.04, 6)
	# the blade: from the collar it runs back along the shaft's "down" side in a long curve to its point
	var down := (Vector3.DOWN - d * Vector3.DOWN.dot(d)).normalized()
	var pts := PackedVector3Array([top + d * 0.02, top + down * 0.10 + d * 0.02, top + down * 0.22 - d * 0.12,
		top + down * 0.30 - d * 0.42])
	MountModel.sculpt_add(s, MountModel.tube_mesh("vb_blade_v1", pts, PackedFloat32Array([0.07, 0.075, 0.05, 0.0]), 5, true,
		0.22), Transform3D.IDENTITY, sil)
	var edge := PackedVector3Array([top + down * 0.14 + d * 0.0, top + down * 0.25 - d * 0.14, top + down * 0.31 - d * 0.38])
	MountModel.sculpt_add(s, MountModel.tube_mesh("vb_edge_v1", edge, PackedFloat32Array([0.022, 0.02, 0.0]), 4, true, 0.4),
		Transform3D(Basis.IDENTITY, down * 0.03), glow)


# ================================================================ motion

func _after_ready() -> void:
	super._after_ready()
	_glow_mi = _merged_nodes.get(P_ARM_R)


## `reap`: the scythe drawn back over the right shoulder, the great horizontal reap across the front (strike STRIKE_T),
## a heavy recovery. The arm offsets are applied in _pose_seated (after the kit's reins); this runs the body and events.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"reap":
		return super._pose_attack(prev, t)
	_atk_t = t
	rot(P_CHEST, Vector3(_kf(t, R_LEAN) * DEG, _kf(t, R_TWIST) * DEG, 0))
	rot(P_HEAD, Vector3(-_kf(t, R_LEAN) * 0.5 * DEG, -_kf(t, R_TWIST) * 0.5 * DEG, 0))
	if prev < STRIKE_T and t >= STRIKE_T:
		_on_action_event(&"release")
		_flare = maxf(_flare, 1.0)
		lance_struck.emit(get_lance_tip())
	if t >= ATTACK_LEN:
		_atk_t = 99.0
	return t < ATTACK_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	if ev == &"attack_end":
		_atk_t = 99.0


## A dread salute for any cast: the scythe raised, blade high.
func _pose_cast(_spell: StringName, t: float) -> float:
	_cast_k = _k3(t, 0.0, 0.18, 0.5, 0.75, 1.0, 1.0)
	return 0.75


func _extra_process(dt: float) -> void:
	super._extra_process(dt)
	if _action != &"attack":
		_atk_t = 99.0
	if _action != &"cast":
		_cast_k = 0.0
	if _charge_t < CHARGE_LEN:
		var prev := _charge_t
		_charge_t += dt
		_charge_k = _kf(_charge_t, C_K) if not _dead else 0.0
		if prev < CHARGE_HIT and _charge_t >= CHARGE_HIT and not _dead:
			charge_struck.emit(get_lance_tip())
		if _charge_t >= CHARGE_LEN:
			_charge_k = 0.0
	else:
		_charge_k = 0.0
	_flare = maxf(0.0, _flare - dt / 0.6)
	_write_glow()


## Riding: the kit's seat pose; the scythe arm (rest: slanting forward; the reap; levelled at the charge; raised for a
## cast), the left hand on the reins.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(1.5 * sin(2.0 * TAU * gait), 4.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var ck := _charge_k
	var ax: float = 4.0 + bounce * 0.5 + 34.0 * ck - 70.0 * _cast_k
	var az: float = -3.0
	if _atk_t < ATTACK_LEN:
		ax += _kf(_atk_t, R_ARM_X)
		az += _kf(_atk_t, R_ARM_Z)
	_off_rot[P_ARM_R] = sar + Vector3(ax * DEG, 0, az * DEG) * w
	if ck > 0.0:
		rot(P_CHEST, Vector3(14.0 * DEG * ck * w, -6.0 * DEG * ck * w, 0))
		rot(P_HEAD, Vector3(-12.0 * DEG * ck * w, 4.0 * DEG * ck * w, 0))


## The scythe edge (merged in ArmR): the kit's glow level, flared by the reap / charge; ArmR drives its own glow_boost.
func _write_glow() -> void:
	if _glow_mi == null:
		return
	if not _glow_mi.has_meta(&"own_glow"):
		_glow_mi.set_meta(&"own_glow", true)
		_glow_nodes.erase(_glow_mi)
	var g: float = snappedf(glow_level() * (1.0 + 1.5 * _flare + 0.6 * _charge_k), 0.05)
	if g != _glow_w:
		_glow_w = g
		_glow_mi.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	super._on_revive()
	_atk_t = 99.0
	_charge_t = 99.0
	_charge_k = 0.0
	_cast_k = 0.0
	_flare = 0.0
	_glow_w = -1.0
	_write_glow()
