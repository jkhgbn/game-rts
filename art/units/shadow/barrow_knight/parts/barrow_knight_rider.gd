class_name BarrowKnightRider
extends ShadowModel
## Barrow Knight rider (stables.md 2, Shadow C: the tier-2 line breaker, rank-3 "Barrow Dreadlord"). Seated with the
## kit's CharacterModel.set_seated on the Barrow Steed (parts/barrow_steed.tscn: the barded Dusk Steed with a bone skull
## mask and a long team shroud); the scene pairing them is barrow_knight.tscn (BarrowKnightModel, x0.94). Extends
## ShadowModel for the Shadow dissolve death (it melts into violet while it rides the steed's fall) and the glowing eyes.
## Look (the grave-knight, kept apart from the Gloam Rider's hooded lancer): blackened iron plate edged in tarnished
## silver, a team surcoat with a bone crescent moon, heavy iron pauldrons with a bone spike, a tattered team cape over the
## croup; an iron BARBUTE with a Y-slit open face and a narrow iron BARROW CROWN of five silver points on top (FaceKit:
## a gaunt pale face, glowing violet eyes, a grim mouth, ink-black strands from under the helm); a tall team KITE SHIELD
## with a silver rim and a bone crescent on the left arm; in the right fist a FLAIL: an iron haft, a chain and a spiked
## iron ball ("FlailHead", swinging on its chain, lagging behind the arm).
## Glow: the crown's violet gem and the eyes (ShadowModel's eye glow); the steed's burning skull-mask eyes are the other.
## Attack `flail_smash` (0.70 s, melee strike STRIKE_T 0.12 s): the flail whirls up over the helm, the ball trailing, then
## crashes down in front (lean + twist), a recovery. play_charge() (0.85 s, hit 0.10 s): the flail held high, the ball
## streaming, a lean in behind the shield; charge_struck(at) at the hit frame (the ball, world).
## Rank 3 (set_rank(3), Barrow Dreadlord): the node "RankCrest" shows (a taller crown of bone spikes round a violet
## gem).
## Hooks (on top of the kit's, the names GloamRiderModel forwards): play_charge(), is_charging(), get_lance_tip() /
## get_weapon_tip() (the flail ball, world), lance_pitch() (0), couch_amount() (the charge weight), set_rank(rank),
## authored_mesh_count(); signals charge_struck(at), lance_struck(at) (the attack's strike frame, the ball).
## Budget (rider, JS cap ~3000 vertices with the face): 7 draw instances at rest (Hips with the legs astride, Chest,
## Head, Face, ArmL with the shield, ArmR with the haft, FlailHead); RankCrest hidden; no blob (the steed's shows);
## 0 particles, 0 lights.

signal charge_struck(at: Vector3)
signal lance_struck(at: Vector3)

const SH_L := Vector3(-0.29, 1.37, 0.0)
const SH_R := Vector3(0.29, 1.37, 0.0)
const ELBOW_L := Vector3(-0.33, 1.09, -0.02)
const FIST_L := Vector3(-0.32, 1.04, 0.22)
const ELBOW_R := Vector3(0.33, 1.09, -0.03)
const FIST_R := Vector3(0.34, 1.05, 0.22)
const SHIELD_C := Vector3(-0.46, 1.00, 0.12)
const HEAD_C := Vector3(0, 1.64, 0.06)
const HEAD_R := 0.13
## The flail: its haft from the fist along HAFT_DIR, the chain hangs from its end.
const HAFT_DIR := Vector3(0.10, 0.62, 0.78)
const HAFT_LEN := 0.52
const CHAIN_LEN := 0.30
const BALL_R := 0.10
const ATTACK_LEN := 0.70
const STRIKE_T := 0.12
const CHARGE_LEN := 0.85
const CHARGE_HIT := 0.10

# Attack (flail_smash) / charge tracks [t, v, ease, ...] (the _kf format below).
static var F_ARM := PackedFloat32Array([0.0, 0.0, 0, 0.07, -150.0, 1, 0.12, -24.0, 2, 0.30, 8.0, 0, 0.70, 0.0, 0])
static var F_LEAN := PackedFloat32Array([0.0, 0.0, 0, 0.07, -10.0, 1, 0.12, 18.0, 2, 0.34, 8.0, 0, 0.70, 0.0, 0])
static var F_TWIST := PackedFloat32Array([0.0, 0.0, 0, 0.07, 22.0, 1, 0.12, -20.0, 2, 0.36, -8.0, 0, 0.70, 0.0, 0])
static var F_SHIELD := PackedFloat32Array([0.0, 0.0, 0, 0.07, -20.0, 1, 0.16, -6.0, 0, 0.70, 0.0, 0])
static var C_K := PackedFloat32Array([0.0, 0.0, 0, 0.08, 1.0, 1, 0.50, 1.0, 0, 0.85, 0.0, 0])

var _parts_n: int = 0
var _flail: MeshInstance3D
var _rank_node: Node3D
var _rank: int = 0

var _atk_t: float = 99.0
var _charge_t: float = 99.0
var _charge_k: float = 0.0
var _cast_k: float = 0.0
var _fl_dir: Vector3 = Vector3.DOWN          # the chain's direction (world), smoothed
var _fl_prev: Vector3 = Vector3.INF          # the haft tip last frame (world)
var _fl_q_w: Quaternion = Quaternion(0, 0, 0, 0)


# ================================================================ public hooks

func play_charge() -> void:
	if _dead:
		return
	_charge_t = 0.0
	set_process(true)


func is_charging() -> bool:
	return _charge_t < CHARGE_LEN


## World position of the flail ball (impact VFX). GloamRiderModel forwards it as get_lance_tip.
func get_lance_tip() -> Vector3:
	if _flail and _flail.is_inside_tree():
		return _flail.global_transform * Vector3(0, -CHAIN_LEN - BALL_R, 0)
	return global_position + Vector3(0.3, 2.2, 0.6)


func get_weapon_tip() -> Variant:
	return get_lance_tip()


func lance_pitch() -> float:
	return 0.0


func couch_amount() -> float:
	return _charge_k


## Stables16 rank-3 look (Barrow Dreadlord): the bone-spiked crown (node "RankCrest"). Idempotent.
func set_rank(rank: int) -> void:
	_rank = rank
	if _rank_node:
		_rank_node.visible = rank >= 3 and not _dead


func authored_mesh_count() -> int:
	return _parts_n


# ================================================================ build

func _build_parts() -> void:
	_parts_n = 0
	var head: Node3D = $Root/Chest/Head
	var arm_r: Node3D = $Root/Chest/ArmR
	_sculpt($Root/Hips, "bk_hips_v1", _hips_sculpt)
	_sculpt($Root/Chest, "bk_chest_v1", _chest_sculpt)
	_sculpt(head, "bk_head_v3", _head_sculpt)
	# Face (FaceKit): the gaunt pale grave-knight in the barbute's Y-slit: glowing violet eyes under hard brows, a grim
	# mouth, black-violet strands from under the helm (the helm covers the ears, like the Shadow Knight's).
	_face = FaceKit.attach(self, head, "barrow_knight_rider", {
		"center": HEAD_C, "radius": HEAD_R, "head_mesh": sphere(HEAD_R, 10, 6), "head_scale": Vector3(0.94, 1.06, 0.94),
		"preset": &"stern", "skin": ShadowFaces.PALE, "hair": ShadowFaces.INK, "eyes": ShadowFaces.GLOW, "detail": &"low",
		"x": NatureFaces.lean_x(1.15, {&"neutral": {"cut_in": 0.3, "mouth": {"kind": "frown", "curve": 0.5, "open": 0.0}}}),
		"palette": ShadowFaces.pal(ShadowFaces.PALE), "eye": {"c": Vector2(0.046, 0.020), "tilt": 0.012},
		"hair_fn": func(acc: Dictionary) -> void:
			ShadowFaces.strands(acc, [HEAD_C + Vector3(0.105, -0.02, -0.03), HEAD_C + Vector3(-0.105, -0.02, -0.03)], 0.16,
				0.026, ShadowFaces.INK, ShadowFaces.INK_TIP, Vector3(0.02, 0, -0.02)),
	})
	_sculpt($Root/Chest/ArmL, "bk_arm_l_v1", _arm_l_sculpt)
	_sculpt(arm_r, "bk_arm_r_v1", _arm_r_sculpt)
	var tip := FIST_R + HAFT_DIR.normalized() * HAFT_LEN
	_flail = _sculpt(arm_r, "bk_flail_v1", _flail_sculpt, tip, true, "FlailHead")
	_flail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_rank_node = _sculpt(head, "bk_rank_v1", _rank_sculpt, Vector3.ZERO, true, "RankCrest")
	_rank_node.visible = false


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


## A spike / horn: a cone whose base (radius r) is at `base`, pointing along `dir`, length h.
static func _spike(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, r: float, h: float) -> void:
	MountModel.sculpt_add(s, cyl(0.0, r, h, 4), Transform3D(_to_dir(dir), base + dir.normalized() * h * 0.5), mat)


## The kite shield (the Pyrehoof Lancer's cut): a slightly convex plate in the model YZ plane (face toward -X), height h,
## half width w, thickness th; part 0 = the face (+ its back), 1 = the rim tube along the outline.
static func _kite_mesh(part: int, h: float, w: float, th: float, bulge: float) -> Mesh:
	var key := "bk_kite_%d_%s_%s_v1" % [part, h, w]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var rows := 7
	var cols := 4
	var grid: Array = []
	for i: int in rows + 1:
		var t := float(i) / float(rows)
		var hw: float = w * ((0.93 + 0.28 * t) if t < 0.25 else (1.0 - pow((t - 0.25) / 0.75, 1.35)))
		var row: Array[Vector3] = []
		for j: int in cols + 1:
			var u := lerpf(-1.0, 1.0, float(j) / float(cols))
			row.append(Vector3(-bulge * (1.0 - u * u) * (1.0 - 0.6 * t), h * 0.42 - h * t + (0.03 * (1.0 - u * u) if i == 0 else 0.0),
				u * hw))
		grid.append(row)
	if part == 1:
		var outline := PackedVector3Array()
		for j: int in cols + 1:
			outline.append((grid[0] as Array)[j] + Vector3(-0.01, 0, 0))
		for i: int in range(1, rows + 1):
			outline.append((grid[i] as Array)[cols] + Vector3(-0.01, 0, 0))
		for i: int in range(rows - 1, 0, -1):
			outline.append((grid[i] as Array)[0] + Vector3(-0.01, 0, 0))
		outline.append(outline[0])
		var radii := PackedFloat32Array()
		for k: int in outline.size():
			radii.append(0.022)
		return _cached(key, MountModel.tube_mesh(key + "_t", outline, radii, 4, false))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var o := Vector3(th, 0, 0)
	var bx := Vector3(1, 0, 0)
	for i: int in rows:
		var t0 := float(i) / float(rows)
		var t1 := float(i + 1) / float(rows)
		for j: int in cols:
			var u0 := lerpf(-1.0, 1.0, float(j) / float(cols))
			var u1 := lerpf(-1.0, 1.0, float(j + 1) / float(cols))
			var a: Vector3 = (grid[i] as Array)[j]
			var b: Vector3 = (grid[i] as Array)[j + 1]
			var c: Vector3 = (grid[i + 1] as Array)[j + 1]
			var d: Vector3 = (grid[i + 1] as Array)[j]
			var na := _kite_n(u0, t0, bulge, w)
			var nb := _kite_n(u1, t0, bulge, w)
			var nc := _kite_n(u1, t1, bulge, w)
			var nd := _kite_n(u0, t1, bulge, w)
			_tri3(st, a, b, c, na, nb, nc)
			_tri3(st, a, c, d, na, nc, nd)
			_tri3(st, a + o, c + o, b + o, bx, bx, bx)
			_tri3(st, a + o, d + o, c + o, bx, bx, bx)
	st.index()
	return _cached(key, st.commit())


static func _kite_n(u: float, t: float, bulge: float, w: float) -> Vector3:
	return Vector3(-1.0, 0.0, 1.6 * bulge * u * (1.0 - 0.6 * t) / maxf(w, 0.05)).normalized()


## One smooth triangle with its front face (Godot: clockwise) toward the given normals.
static func _tri3(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	if fn.dot(na + nb + nc) > 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


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

## Hips + legs astride (no leg pivots: merged into Hips = 1 draw): a mail skirt, an iron belt with a silver clasp, the
## surcoat's back skirt over the cantle (team, dark hem), iron tassets, dark leather thighs, iron greaves with silver
## knee cops, iron sabatons in the stirrups (the Dusk Steed is tall: long legs).
func _hips_sculpt(s: Dictionary) -> void:
	var iron := m("shadow_iron")
	var sil := m("shadow_silver")
	var lea := m("shadow_leather")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	_put(s, cyl(0.20, 0.245, 0.24, 8), m("shadow_obsidian"), Vector3(0, 0.83, 0))
	_put(s, cyl(0.215, 0.215, 0.07, 8, false), iron, Vector3(0, 0.945, 0))
	_put(s, box(Vector3(0.075, 0.075, 0.03)), sil, Vector3(0, 0.945, 0.215), Vector3(0, 0, 45))
	_put(s, box(Vector3(0.32, 0.44, 0.03)), cloth, Vector3(0, 0.74, -0.24), Vector3(12, 0, 0))
	_put(s, box(Vector3(0.325, 0.05, 0.035)), cdark, Vector3(0, 0.52, -0.285), Vector3(12, 0, 0))
	for sx: float in [-1.0, 1.0]:
		_put(s, box(Vector3(0.04, 0.20, 0.20)), iron, Vector3(0.225 * sx, 0.84, 0.03), Vector3(0, 0, -12.0 * sx))
		var hip := Vector3(0.105 * sx, 0.85, 0.02)
		var knee := Vector3(0.30 * sx, 0.54, 0.20)
		var ankle := Vector3(0.34 * sx, 0.20, 0.08)
		_seg(s, lea, hip, knee, 0.088, 0.07, 6)
		_put(s, sphere(0.075, 6, 3), sil, knee + Vector3(0.0, 0.0, 0.03), Vector3.ZERO, Vector3(1.0, 1.1, 1.0))
		_spike(s, sil, knee + Vector3(0, 0.0, 0.08), Vector3(0, 0.25, 1.0), 0.03, 0.10)
		_seg(s, iron, knee, ankle + Vector3(0, -0.03, 0), 0.068, 0.06, 6)
		MountModel.sculpt_add(s, cyl(0.055, 0.068, 0.24, 6), Transform3D(_to_dir(Vector3(0.04 * sx, 0.03, 1.0)),
			ankle + Vector3(0.005 * sx, -0.045, 0.09)), iron)


func _chest_sculpt(s: Dictionary) -> void:
	var iron := m("shadow_iron")
	var sil := m("shadow_silver")
	var bone := m("shadow_bone")
	var lea := m("shadow_leather")
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var thin := Basis.from_scale(Vector3(0.94, 1.0, 0.8))
	# the blackened iron breastplate (lathe), a silver rim at the waist and at the neck
	var prof := PackedVector2Array([Vector2(0.18, 0.92), Vector2(0.21, 1.02), Vector2(0.245, 1.16), Vector2(0.255, 1.27),
		Vector2(0.235, 1.35), Vector2(0.13, 1.43), Vector2(0.0, 1.45)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("bk_torso_v1", prof, 8), Transform3D(thin, Vector3.ZERO), iron)
	_put(s, cyl(0.22, 0.22, 0.035, 8, false), sil, Vector3(0, 1.0, 0), Vector3.ZERO, Vector3(0.94, 1.0, 0.8))
	# the team surcoat panel on the breast with the bone crescent moon, a dark hem
	_put(s, box(Vector3(0.30, 0.36, 0.03)), cloth, Vector3(0, 1.14, 0.205), Vector3(-5, 0, 0))
	_put(s, box(Vector3(0.305, 0.04, 0.035)), cdark, Vector3(0, 0.965, 0.212), Vector3(-5, 0, 0))
	_put(s, cyl(0.07, 0.07, 0.02, 8), bone, Vector3(0, 1.18, 0.225), Vector3(85, 0, 0))
	_put(s, cyl(0.058, 0.058, 0.024, 8), cloth, Vector3(0.025, 1.20, 0.228), Vector3(85, 0, 0))
	# the iron gorget with a silver rim
	_put(s, cyl(0.12, 0.16, 0.10, 8, false), iron, Vector3(0, 1.41, 0))
	# heavy iron pauldrons with silver rims and a bone spike each
	for sx: float in [-1.0, 1.0]:
		var pf := MountModel.frame(Vector3(0.31 * sx, 1.40, -0.01), Vector3(0.55 * sx, 1.0, 0.0), Vector3.BACK)
		MountModel.sculpt_add(s, MountModel.lathe_mesh("bk_pauldron_v1", PackedVector2Array([Vector2(0.17, -0.08),
			Vector2(0.175, -0.01), Vector2(0.14, 0.055), Vector2(0.07, 0.09), Vector2(0.0, 0.098)]), 8), pf, iron)
		MountModel.sculpt_add(s, cyl(0.178, 0.178, 0.03, 8, false), Transform3D(pf.basis, pf * Vector3(0, -0.06, 0)), sil)
		_spike(s, bone, pf * Vector3(0, 0.07, -0.02), Vector3(0.45 * sx, 1.0, -0.25), 0.03, 0.15)
	# the tattered team cape falling over the croup, a dark lining, a leather yoke
	MountModel.sculpt_fringe(s, cloth, MountModel.fringe_mesh("bk_cape_v1", 0.2, 0.11, 0.30, 0.22, 0.52, 110.0, 250.0, 6,
		0.18, 0.024, 0.7), Vector3(0, 1.38, -0.13), Basis(Vector3.RIGHT, deg_to_rad(28.0)))
	MountModel.sculpt_fringe(s, cdark, MountModel.fringe_mesh("bk_cape_in_v1", 0.19, 0.10, 0.285, 0.21, 0.58, 116.0, 244.0,
		5, 0.2, 0.02, 0.8), Vector3(0, 1.37, -0.125), Basis(Vector3.RIGHT, deg_to_rad(28.0)))
	_put(s, box(Vector3(0.46, 0.06, 0.07)), lea, Vector3(0, 1.39, -0.19))


func _head_sculpt(s: Dictionary) -> void:
	var skin := m("shadow_skin")
	var iron := m("shadow_iron")
	var sil := m("shadow_silver")
	_put(s, cyl(0.06, 0.07, 0.12, 6), skin, Vector3(0, 1.50, 0.02))
	# the face sphere (the FaceKit canvas)
	_put(s, sphere(HEAD_R, 10, 6), skin, HEAD_C, Vector3.ZERO, Vector3(0.94, 1.06, 0.94))
	# the barbute: an iron dome, the cheek plates down to the jaw (a Y-slit open face), a nape guard, silver edges
	var hp := PackedVector2Array([Vector2(0.174, 1.705), Vector2(0.178, 1.76), Vector2(0.157, 1.83), Vector2(0.10, 1.875),
		Vector2(0.0, 1.89)])
	MountModel.sculpt_add(s, MountModel.lathe_mesh("bk_barbute_v1", hp, 10),
		Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.08)), Vector3(0, 0, -0.01)), iron)
	var tb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))   # shell z -> up, angle 0 -> +Z
	for sx: float in [-1.0, 1.0]:
		var a0: float = 34.0 * sx
		var a1: float = 180.0 * sx
		MountModel.sculpt_add(s, MountModel.shell_mesh("bk_cheek_%s_v2" % sx, 0.18, 0.195, minf(a0, a1), maxf(a0, a1), 1.49,
			1.72, 0.02, 5, 1, 0.97, 0.0), Transform3D(tb, Vector3(0, 0, -0.01)), iron)
		# the silver edge of the face opening
		_seg(s, sil, Vector3(0.10 * sx, 1.49, 0.152), Vector3(0.098 * sx, 1.71, 0.15), 0.013, 0.013, 4)
	# the BARROW CROWN: a narrow iron circlet round the dome with five silver points
	_put(s, cyl(0.176, 0.176, 0.04, 10, false), iron, Vector3(0, 1.78, -0.01), Vector3.ZERO, Vector3(1.0, 1.0, 1.08))
	for k: int in 5:
		var a := deg_to_rad(-72.0 + 36.0 * float(k))
		var d := Vector3(sin(a), 0, cos(a) * 1.08)
		_spike(s, sil, Vector3(0, 1.795, -0.01) + d * 0.176, Vector3(d.x * 0.15, 1.0, d.z * 0.15), 0.026, 0.12)
	# the crown's violet gem over the brow (the rider's glow point with the eyes: high, it reads over a crowd)
	_put(s, sphere(0.055, 6, 3), m("shadow_glow_hero"), Vector3(0, 1.80, 0.20), Vector3.ZERO, Vector3(1.0, 1.3, 0.75))


## The rank-3 crown (node "RankCrest" on Head, node-local = model space): seven tall bone spikes round a silver ring and a
## violet gem on the brow.
func _rank_sculpt(s: Dictionary) -> void:
	var bone := m("shadow_bone")
	var sil := m("shadow_silver")
	_put(s, cyl(0.165, 0.165, 0.05, 10, false), sil, Vector3(0, 1.83, -0.01), Vector3.ZERO, Vector3(1.0, 1.0, 1.08))
	for k: int in 7:
		var a := deg_to_rad(-90.0 + 30.0 * float(k))
		var d := Vector3(sin(a), 0, cos(a) * 1.08)
		_spike(s, bone, Vector3(0, 1.85, -0.01) + d * 0.165, Vector3(d.x * 0.2, 1.0, d.z * 0.2), 0.03, 0.22 - 0.04 * absf(cos(a)))
	_put(s, sphere(0.035, 6, 3), m("shadow_glow_mid"), Vector3(0, 1.84, 0.18))


func _arm_l_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, -1.0)
	var cloth := m("shadow_cloth")
	var cdark := m("shadow_cloth_dark")
	var sil := m("shadow_silver")
	var bone := m("shadow_bone")
	var lea := m("shadow_leather")
	# the tall team kite shield on the forearm (face out, -X): silver rim, a bone crescent moon over a dark bar
	var at := Transform3D(Basis.IDENTITY, SHIELD_C)
	MountModel.sculpt_add(s, _kite_mesh(0, 0.94, 0.26, 0.035, 0.06), at, cloth)
	MountModel.sculpt_add(s, _kite_mesh(1, 0.94, 0.26, 0.035, 0.06), at, sil)
	var sb := Basis(Vector3.BACK, PI * 0.5)   # cylinder axis along X
	var moon := SHIELD_C + Vector3(-0.07, 0.08, 0.0)
	MountModel.sculpt_add(s, cyl(0.10, 0.10, 0.02, 10), Transform3D(sb, moon), bone)
	MountModel.sculpt_add(s, cyl(0.085, 0.085, 0.024, 10), Transform3D(sb, moon + Vector3(-0.004, 0.045, 0.03)), cloth)
	MountModel.sculpt_add(s, box(Vector3(0.02, 0.36, 0.05)), Transform3D(Basis.IDENTITY, SHIELD_C + Vector3(-0.058, -0.22, 0)), cdark)
	_put(s, box(Vector3(0.03, 0.05, 0.22)), lea, SHIELD_C + Vector3(0.06, 0.02, 0.0))


## The right arm and the flail's haft in its fist (merged: the arm swings it): an iron-bound haft with a silver cap.
func _arm_r_sculpt(s: Dictionary) -> void:
	_arm_sculpt(s, 1.0)
	var iron := m("shadow_iron")
	var sil := m("shadow_silver")
	var lea := m("shadow_leather")
	var d := HAFT_DIR.normalized()
	_seg(s, lea, FIST_R - d * 0.14, FIST_R + d * 0.10, 0.034, 0.034, 5)
	_seg(s, iron, FIST_R + d * 0.10, FIST_R + d * (HAFT_LEN - 0.03), 0.034, 0.03, 5)
	_put(s, sphere(0.045, 6, 3), sil, FIST_R - d * 0.16)
	_seg(s, sil, FIST_R + d * (HAFT_LEN - 0.05), FIST_R + d * HAFT_LEN, 0.042, 0.03, 5)


## Iron arm: a rerebrace, a silver elbow cop, a vambrace, an iron gauntlet.
func _arm_sculpt(s: Dictionary, sx: float) -> void:
	var iron := m("shadow_iron")
	var sil := m("shadow_silver")
	var lea := m("shadow_leather")
	var sh: Vector3 = SH_L if sx < 0.0 else SH_R
	var el: Vector3 = ELBOW_L if sx < 0.0 else ELBOW_R
	var fi: Vector3 = FIST_L if sx < 0.0 else FIST_R
	_seg(s, lea, sh + Vector3(0, 0.02, 0), el, 0.075, 0.064, 6)
	_put(s, sphere(0.068, 6, 3), sil, el + Vector3(0, 0, -0.015))
	_seg(s, iron, el, fi - (fi - el).normalized() * 0.04, 0.068, 0.062, 6)
	_put(s, sphere(0.072, 6, 3), iron, fi, Vector3.ZERO, Vector3(1.0, 1.05, 1.1))


## The flail head (keep_separate "FlailHead" at the haft's end, node-local, the chain hanging along -Y): a silver ring,
## the chain (three iron links), the spiked iron ball with silver spikes.
func _flail_sculpt(s: Dictionary) -> void:
	var iron := m("shadow_iron")
	var sil := m("shadow_silver")
	var obs := m("shadow_obsidian")
	for k: int in 3:
		var y := -0.05 - 0.09 * float(k)
		_put(s, cyl(0.035, 0.035, 0.06, 5, false), iron, Vector3(0, y, 0), Vector3(0, 90.0 * float(k % 2), 90))
	var bc := Vector3(0, -CHAIN_LEN - BALL_R * 0.6, 0)
	_put(s, sphere(BALL_R, 8, 4), obs, bc)
	for d: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(0, -1, 0),
			Vector3(0.6, 0.6, 0.5)]:
		_spike(s, sil, bc + d.normalized() * BALL_R * 0.8, d, 0.035, 0.09)


# ================================================================ motion

## `flail_smash`: the flail up over the helm, then crashing down in front (strike STRIKE_T), a recovery. The arm is
## posed in _pose_seated (after the kit's reins); this runs the clock, the body and the strike event.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"flail_smash":
		return super._pose_attack(prev, t)
	_atk_t = t
	rot(P_CHEST, Vector3(_kf(t, F_LEAN) * DEG, _kf(t, F_TWIST) * DEG, 0))
	rot(P_HEAD, Vector3(-_kf(t, F_LEAN) * 0.5 * DEG, 0, 0))
	rot(P_ARM_L, Vector3(_kf(t, F_SHIELD) * DEG, 0, 0))
	if prev < STRIKE_T and t >= STRIKE_T:
		_on_action_event(&"release")
		lance_struck.emit(get_lance_tip())
	if t >= ATTACK_LEN:
		_atk_t = 99.0
	return t < ATTACK_LEN


func _on_action_event(ev: StringName) -> void:
	super._on_action_event(ev)
	if ev == &"attack_end":
		_atk_t = 99.0


## A war salute for any cast: the flail raised, the ball swinging.
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
	if _dead and _rank_node and _rank_node.visible and _death_t > 0.5:
		_rank_node.visible = false
	_swing_flail(dt)


## Riding: the kit's seat pose; the flail arm (rest low with the haft forward-up; the smash; raised at the charge / cast),
## the shield arm guarding across (raised at the charge).
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var sal: Vector3 = _off_rot[P_ARM_L]
	var sar: Vector3 = _off_rot[P_ARM_R]
	super._pose_seated(w, gait, gallop, moving)
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * gait), 5.0 * sin(TAU * (gait - 0.4)), gallop) * moving
	var ck := _charge_k
	var ax: float = 6.0 + bounce * 0.5 - 120.0 * ck - 110.0 * _cast_k
	if _atk_t < ATTACK_LEN:
		ax += _kf(_atk_t, F_ARM)
	_off_rot[P_ARM_R] = sar + Vector3(ax * DEG, 0, -4.0 * DEG) * w
	_off_rot[P_ARM_L] = sal + Vector3((-12.0 + bounce - 28.0 * ck) * DEG, 0, (5.0 + 8.0 * ck) * DEG) * w
	if ck > 0.0:
		rot(P_CHEST, Vector3(12.0 * DEG * ck * w, -6.0 * DEG * ck * w, 0))
		rot(P_HEAD, Vector3(-10.0 * DEG * ck * w, 4.0 * DEG * ck * w, 0))


## The ball hangs on its chain and trails the haft: the chain direction eases toward "down, against the tip's motion"
## (world), and FlailHead is turned so its -Y follows it. No allocation; only while animated.
func _swing_flail(dt: float) -> void:
	if _flail == null or not _flail.is_inside_tree():
		return
	var p := _flail.global_position
	var want := Vector3.DOWN
	if _fl_prev != Vector3.INF and dt > 0.0001:
		var v := (p - _fl_prev) / dt
		want = (Vector3.DOWN * 3.0 - v * 0.55).normalized()
	_fl_prev = p
	var k: float = 1.0 - exp(-maxf(dt, 0.0) * 12.0)
	_fl_dir = _fl_dir.slerp(want, k).normalized() if _fl_dir.dot(want) > -0.99 else want
	var par := (_flail.get_parent() as Node3D).global_transform.basis
	var ld := (par.inverse() * _fl_dir).normalized()
	var q := Quaternion(Vector3.DOWN, ld) if ld.dot(Vector3.DOWN) > -0.999 else Quaternion(Vector3.RIGHT, PI)
	if not q.is_equal_approx(_fl_q_w):
		_fl_q_w = q
		_flail.quaternion = q


func _on_revive() -> void:
	super._on_revive()
	_atk_t = 99.0
	_charge_t = 99.0
	_charge_k = 0.0
	_cast_k = 0.0
	_fl_dir = Vector3.DOWN
	_fl_prev = Vector3.INF
	_fl_q_w = Quaternion(0, 0, 0, 0)
	set_rank(_rank)
