extends CharacterModel
## The Greywater Tracker (market-trade.md 6.1 / 9, task 10.V7): a hired monster-hunter of the Greywater Lodge, sold to a
## team by contract. Look: a long slate grey-green OILSKIN duster, a peaked grey-green HOOD whose point hangs back
## (a short liripipe), a shaggy pale FUR MANTLE over the shoulders (open in front), a lower-face mask with a dark
## eye bar (faces pass 2026-09-28: the mask is pulled down round the neck, a FaceKit face shows), a HOUND SKULL worn on the left shoulder and a necklace of hound fangs on the chest (the trophies), a coil
## of snare rope on the left hip and a bolt case on the right; a HEAVY CROSSBOW (wide steel prod, stirrup, a fang
## charm) carried in the right fist, nose down at the side, raised to the shoulder to shoot.
## Why a crossbow and not the longbow of the first art list: the lead's brief (10.V7) asked for "crossbow or spear",
## and a tall bow would echo the Wayfinder (bow + tall lantern pole) and the Ember Archer at 40 m. The silhouette here
## is a wide pale mantle + hood peak + skull bump (top) and the crossbow's cross (side), no tall vertical at all.
## Team colour (set_team_color, kit recolour of `*_pennon`): a forearm band with two short tails (left arm) and a
## contract ribbon tied to the hood point. Contracts belong to a team, so the hiring team's kingdom colour goes here.
## Glow (the one point): the amber head of the loaded snare bolt, dim at rest, bright while aiming ("drawing"), gone
## between the shot and the reload.
## Attack style `crossbow` (windup 0.15 = release): the crossbow comes up to the shoulder (0.11 s), looses at 0.15
## (recoil, amber sparks, the string snaps forward, the bolt is gone), re-spans at ~0.57 (nose dips, the free hand pulls
## the string), stays aimed to 0.85 and lowers by ~1.15; a re-trigger while aimed keeps the aim (no pop).
## Casts (none in the spec; play_cast is safe): any id = a slower aimed snare shot (release 0.30 s).
## Idle / walk / hit / death (`fall`) / level-up / revive come from the kit (CharacterModel).
## Budget (soldier, art-units.md 8): 16 authored meshes (blob included), 10 draw instances (7 merged pivots + Crossbow,
## blob, 1 one-shot spark emitter), 0 lights, 4 own materials (materials/) + 7 kit palette entries, 2 498 vertices
## (<= 2 500: primitives are tessellated low on purpose; see tests/test_10_v7.gd before adding parts).

const TR_DIR := "res://art/units/neutral/tracker/materials/"
const GLOW := Color(1.0, 0.62, 0.22)
const SHOULDER_R := Vector3(0.34, 1.42, 0.0)
const SHOULDER_L := Vector3(-0.34, 1.42, 0.0)
const GRIP_R := Vector3(0.43, 0.92, 0.08)          # right fist = the crossbow's pistol grip (model space)
const HAND_L := Vector3(-0.43, 0.93, 0.07)
const XBOW_REST := Vector3(40.0, -6.0, -10.0)       # deg (YXZ euler): nose forward-down at the right side, a little in
const AIM_ARM := 80.0                               # deg the shooting arm rises for a level shot
const CHEST_YAW := 20.0                             # deg: off-side shoulder forward while aiming
const TIP := Vector3(0.0, 0.14, 0.74)               # bolt head in crossbow space (sparks)
const REST_TIP_GLOW := 0.55                         # x glow_level: the loaded bolt at rest
const AIM_TIP_GLOW := 2.1                           # extra while aimed (1.5 energy x 2.65 = the halo)

static var _tr_mats: Dictionary = {}
static var _tr_meshes: Dictionary = {}

## Painted face (FaceKit, faces pass 2026-09-28).
var _face: FaceRig
var _authored: int = 0
var _xbow: MeshInstance3D
var _spark: GPUParticles3D

# per-frame targets written by the poses (reset in _extra_process)
var _bow_k: float = 0.0             # 0 carried at the side -> 1 aimed at the shoulder
var _elev: float = 0.0              # deg above the horizon of the current aim
# state
var _aim_s: float = 0.0             # smoothed aim weight (persists across re-triggers: no pop)
var _loaded: bool = true
var _fired: bool = false
var _cast_prev: float = 0.0
var _flare: float = 0.0
var _q_w: Quaternion = Quaternion(2, 0, 0, 0)
var _glow_w: float = -1.0


static func _m(name: StringName) -> Material:
	if not _tr_mats.has(name):
		_tr_mats[name] = load(TR_DIR + String(name) + ".tres")
	return _tr_mats[name]


# ================================================================ hooks

## Authored MeshInstance3D count of this build (every part, the blob included), for the budget test.
func authored_mesh_count() -> int:
	return _authored


## True while a snare bolt sits in the groove (false between the release and the re-span).
func is_loaded() -> bool:
	return _loaded


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
	# ---- Legs: oilskin trousers, tall boots with fur wraps
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		_part(leg, _leg_mesh(), null, Vector3(0.135 * sx, 0.0, 0.0))
	# ---- Hips: the duster skirt (split front and back vent), belt, snare-rope coil (left), bolt case (right)
	_part(hips, _skirt_mesh(), null, Vector3.ZERO)
	_part(hips, _belt_mesh(), null, Vector3.ZERO)
	# ---- Chest: coat torso + bandolier + fang necklace; the fur mantle; the hound skull on the left shoulder
	_part(chest, _torso_mesh(), null, Vector3.ZERO)
	_part(chest, _mantle_mesh(), _m(&"tracker_fur"), Vector3.ZERO)
	_part(chest, _skull_mesh(), null, Vector3.ZERO)
	# ---- Head: face + the lowered mask; the peaked hood (+ the contract ribbon on its point); the FaceKit face
	_part(head, _face_mesh(), null, Vector3.ZERO)
	_part(head, _hood_mesh(), null, Vector3.ZERO)
	_face = UnitFaces.attach_lean(self, head, "tracker", _face_spec(), false)
	# ---- Arms: oilskin sleeves, leather bracers / gloves; team band on the left forearm; the crossbow in the right fist
	for side: float in [-1.0, 1.0]:
		var arm: Node3D = arm_r if side > 0.0 else arm_l
		var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
		var hand := GRIP_R if side > 0.0 else HAND_L
		var wrist := sh.lerp(hand, 0.86) + Vector3(0, 0.02, 0)
		var d := wrist - sh
		_part(arm, cyl(0.084, 0.096, d.length() + 0.06, 7, false), _m(&"tracker_oilskin"), sh + d * 0.5, _euler_down(d))
		_part(arm, _arm_leather_mesh(side), palette(&"fire_leather"), Vector3.ZERO)
	_part(arm_l, _armband_mesh(), _m(&"tracker_pennon"), Vector3.ZERO)
	_xbow = _part(arm_r, _xbow_mesh(true), null, GRIP_R, XBOW_REST, true, "Crossbow")
	_xbow.set_meta(&"own_glow", true)
	_xbow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_spark = make_motes(GLOW, 10, 0.45, 0.04, 2.2, 0.07, false, true)
	_spark.name = "ReleaseSparks"
	_spark.position = TIP
	_xbow.add_child(_spark)
	ensure_shadow_blob(0.5)


func _after_ready() -> void:
	if _shadow:
		_authored += 1
	_q_w = Quaternion(2, 0, 0, 0)
	_glow_w = -1.0
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


## A (cols+1) x (rows+1) grid of points (row-major). Smooth normals from the grid, each turned toward hints[k];
## triangles wound so their front faces the same way (Godot fronts are clockwise). double: also the back side,
## inset along -normal, reversed.
static func _grid(acc: Array, pts: PackedVector3Array, hints: PackedVector3Array, cols: int, rows: int,
		wrap_u: bool, double: bool = false, inset: float = 0.0) -> void:
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
			acc[2].append(Vector2.ZERO)
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


## Surface of revolution: profile (r, y) points, `seg` segments; xf places it.
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


## Cylinder from a to b (radius ra at a, rb at b). Open ends unless caps.
static func _seg(acc: Array, a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 6, caps: bool = false) -> void:
	var d := b - a
	var l := d.length()
	var bs := Basis(Quaternion(Vector3.UP, d / l)).scaled_local(Vector3(1.0, l, 1.0))
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
	_tr_meshes[key] = am
	return am


static func _xf(at: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG).scaled_local(scl), at)


## A hound fang (bone cone, point down) hanging from `top`, tilted by `tilt` deg around Z.
static func _fang(acc: Array, top: Vector3, length: float, r: float, tilt: float = 0.0) -> void:
	_put(acc, cyl(r, 0.0, length, 6, false), _xf(top - Vector3(0, length * 0.5, 0), Vector3(0, 0, tilt)))


# ---------------------------------------------------------------- legs

## One leg in its own space (x 0 = the leg axis): oilskin trouser, tall dark boot, pale fur wrap at the boot top.
static func _leg_mesh() -> ArrayMesh:
	if _tr_meshes.has("leg"):
		return _tr_meshes["leg"]
	var oil := _bucket()
	var lea := _bucket()
	var fur := _bucket()
	_put(oil, cyl(0.10, 0.092, 0.40, 6, false), _xf(Vector3(0, 0.50, 0.005), Vector3(-1.5, 0, 0)))
	_put(lea, cyl(0.112, 0.102, 0.30, 7, false), _xf(Vector3(0, 0.215, 0.01)))
	_put(lea, box(Vector3(0.20, 0.12, 0.27)), _xf(Vector3(0, 0.06, 0.065)))
	_put(lea, sphere(0.10, 5, 3), _xf(Vector3(0, 0.07, 0.19), Vector3.ZERO, Vector3(1.0, 0.62, 1.0)))
	_put(fur, cyl(0.15, 0.125, 0.11, 7, false), _xf(Vector3(0, 0.39, 0.01), Vector3(0, 22, 0)))
	return _commit("leg", [[oil, _m(&"tracker_oilskin")], [lea, palette(&"fire_leather")], [fur, _m(&"tracker_fur")]])


# ---------------------------------------------------------------- hips

## Duster point: angle a from +Z (front) toward +X, v 0 (waist) -> 1 (hem). Straight-cut, the back a bit longer.
static func _skirt_point(a: float, v: float) -> Vector3:
	var back := maxf(0.0, -cos(a))
	var r := 0.262 + 0.15 * pow(v, 1.2) + 0.05 * back * v * v + 0.010 * sin(7.0 * a + 0.4) * v
	var hem := 0.36 - 0.06 * back * back
	return Vector3(sin(a) * r, lerpf(1.05, hem, v), cos(a) * r)


## Panel angle: the front stays open (12 deg at the waist -> 30 deg at the hem), a back vent from mid-thigh.
static func _skirt_angle(u: float, v: float, right: bool) -> float:
	var open := lerpf(12.0, 30.0, pow(v, 0.8)) * DEG
	var split := maxf(0.0, (v - 0.45) / 0.55) * 11.0 * DEG
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
			var p := _skirt_point(a, v)
			p += Vector3(p.x, 0.0, p.z).normalized() * grow
			pts.append(p)
			hints.append(Vector3(p.x, 0.0, p.z))
	_grid(acc, pts, hints, cols, rows, false, double, 0.014)


static func _skirt_mesh() -> ArrayMesh:
	if _tr_meshes.has("skirt"):
		return _tr_meshes["skirt"]
	var oil := _bucket()
	var lea := _bucket()
	for right: bool in [true, false]:
		_skirt_panel(oil, right, 0.0, 1.0, 0.0, 1.0, 5, 4, 0.0, true)
		_skirt_panel(lea, right, 0.0, 1.0, 0.91, 1.0, 5, 1, 0.007, false)          # hem band
	return _commit("skirt", [[oil, _m(&"tracker_oilskin")], [lea, palette(&"fire_leather")]])


## Belt + buckle; the snare-rope coil on the left hip (3 hemp loops on a strap); the bolt case on the right thigh.
static func _belt_mesh() -> ArrayMesh:
	if _tr_meshes.has("belt"):
		return _tr_meshes["belt"]
	var lea := _bucket()
	var metal := _bucket()
	var rope := _bucket()
	var bone := _bucket()
	_lathe(lea, PackedVector2Array([Vector2(0.282, 0.955), Vector2(0.286, 0.99), Vector2(0.282, 1.025)]), 10)
	_put(metal, box(Vector3(0.11, 0.09, 0.035)), _xf(Vector3(0.0, 0.99, 0.29)))
	# rope coil: a fat bundle of hemp loops on the outer hip (facing out and a little forward), two leather lashings
	var cc := Vector3(-0.35, 0.80, 0.06)
	var cb := Basis.from_euler(Vector3(0, -35, 90) * DEG)
	for k: int in 2:
		var off := cb * Vector3(0.012 * sin(float(k) * 2.1), -0.02 + 0.014 * float(k), 0.012 * cos(float(k) * 2.1))
		_put(rope, torus(0.06, 0.135, 8), Transform3D(cb * Basis(Vector3.RIGHT, (float(k) - 0.5) * 9.0 * DEG), cc + off * 1.6))
	for a: float in [0.0, PI]:
		var p := cc + cb * Vector3(sin(a) * 0.098, 0.0, cos(a) * 0.098)
		_put(lea, box(Vector3(0.07, 0.10, 0.07)), Transform3D(cb, p))
	_seg(lea, Vector3(-0.27, 0.99, 0.06), cc + cb * Vector3(0.0, 0.0, 0.098) + Vector3(0, 0.02, 0), 0.022, 0.022, 4)
	# bolt case on the right thigh, 4 pale fletchings and a strap
	var qb := Vector3(0.33, 0.62, -0.06)
	var qt := Vector3(0.36, 0.98, -0.11)
	_seg(lea, qb, qt, 0.06, 0.068, 6)
	_put(lea, sphere(0.06, 4, 2), _xf(qb))
	_seg(metal, qt - (qt - qb).normalized() * 0.02, qt + (qt - qb).normalized() * 0.02, 0.074, 0.074, 6, true)
	var dq := (qt - qb).normalized()
	for k: int in 1:
		var off := Vector3(0.03 * cos(k * 1.6), 0.0, 0.03 * sin(k * 1.6))
		_put(bone, box(Vector3(0.04, 0.10, 0.012)),
			Transform3D(Basis(Quaternion(Vector3.UP, dq)) * Basis(Vector3.UP, k * 0.8), qt + dq * 0.07 + off))
	return _commit("belt", [[lea, palette(&"fire_leather")], [metal, palette(&"warden_metal")],
		[rope, palette(&"fire_sec_worker")], [bone, palette(&"shadow_bone")]])


# ---------------------------------------------------------------- chest

## Coat torso (keg), a leather bandolier across the chest, the mantle clasp cord, and the hound-fang necklace.
static func _torso_mesh() -> ArrayMesh:
	if _tr_meshes.has("torso"):
		return _tr_meshes["torso"]
	var oil := _bucket()
	var lea := _bucket()
	var bone := _bucket()
	var metal := _bucket()
	# the coat torso stops at the shoulders (faces pass 2026-09-28: it used to rise to 1.63 m, over the chin)
	_put(oil, cyl(0.285, 0.25, 0.52, 10), _xf(Vector3(0, 1.27, 0)))
	# bandolier: right shoulder -> left hip, 3 pieces following the chest
	var pieces: Array = [[Vector3(0.16, 1.40, 0.245), -28.0], [Vector3(0.0, 1.24, 0.29), 0.0], [Vector3(-0.16, 1.09, 0.255), 28.0]]
	for p: Array in pieces:
		_put(lea, box(Vector3(0.075, 0.25, 0.035)), _xf(p[0], Vector3(0, float(p[1]), 42.0)))
	_put(metal, box(Vector3(0.07, 0.07, 0.03)), _xf(Vector3(0.0, 1.24, 0.31), Vector3(0, 0, 42)))
	# clasp cord between the mantle's front edges (under the chin since the faces pass)
	_seg(lea, Vector3(-0.115, 1.455, 0.205), Vector3(0.115, 1.455, 0.205), 0.018, 0.018, 5)
	# fang necklace: a cord arc over the chest, 5 fangs (the biggest in the middle)
	var prev := Vector3.ZERO
	for i: int in 7:
		var u := float(i) / 6.0 * 2.0 - 1.0
		var p := Vector3(0.20 * u, 1.39 - 0.09 * (1.0 - u * u), 0.0)
		p.z = sqrt(maxf(0.0, 0.282 * 0.282 - p.x * p.x)) + 0.02
		if i > 0 and i % 2 == 0:
			_seg(lea, prev, p, 0.012, 0.012, 4)
		if i > 0 and i < 6:
			var big := 1.0 - absf(u) * 0.45
			_fang(bone, p + Vector3(0, 0.005, 0.012), 0.13 * big, 0.028 * big, -u * 14.0)
		if i % 2 == 0:
			prev = p
	return _commit("torso", [[oil, _m(&"tracker_oilskin")], [lea, palette(&"fire_leather")], [bone, palette(&"shadow_bone")],
		[metal, palette(&"warden_metal")]])


## The fur mantle: a thick shaggy collar-cape over both shoulders and the back, open in front, jagged hem (tufts),
## the back hanging lower. Double-sided (the inside shows at the front edges).
static func _mantle_mesh() -> ArrayMesh:
	if _tr_meshes.has("mantle"):
		return _tr_meshes["mantle"]
	var fur := _bucket()
	const COLS := 14
	const ROWS := 3
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in ROWS + 1:
		var v := float(j) / float(ROWS)
		var open := lerpf(26.0, 44.0, v) * DEG
		for i: int in COLS + 1:
			var a := lerpf(open, TAU - open, float(i) / float(COLS))
			var s := sin(a)
			var c := cos(a)
			var back := maxf(0.0, -c)
			var r := lerpf(0.20, 0.45, pow(v, 0.75)) + 0.05 * s * s * v + 0.03 * back * v + 0.018 * sin(7.0 * a) * v * v
			var jag := 0.0
			if j == ROWS:
				jag = 0.07 * (0.5 + 0.5 * sin(11.0 * a + 0.6))
			elif j == ROWS - 1:
				jag = 0.02 * (0.5 + 0.5 * sin(11.0 * a + 0.6))
			var y := lerpf(1.645, 1.26 - 0.15 * back * back, pow(v, 0.85)) - jag
			pts.append(Vector3(s * r, y, c * r * 0.95 - 0.02))
			hints.append(Vector3(s, 0.7 * (1.0 - v) + 0.15, c))
	_grid(fur, pts, hints, COLS, ROWS, false, true, 0.035)
	return _commit("mantle", [[fur, _m(&"tracker_fur")]])


## A hound skull worn on the left shoulder (snout forward): cranium, snout, brow, pricked ear stubs, dark sockets
## and nose, two fangs.
static func _skull_mesh() -> ArrayMesh:
	if _tr_meshes.has("skull"):
		return _tr_meshes["skull"]
	var bone := _bucket()
	var dark := _bucket()
	var lea := _bucket()
	var c := Vector3(-0.37, 1.53, 0.02)
	_put(bone, sphere(0.12, 7, 4), _xf(c, Vector3(-8, 0, 0), Vector3(0.85, 0.72, 1.1)))
	_put(bone, box(Vector3(0.10, 0.075, 0.17)), _xf(c + Vector3(0, -0.035, 0.165), Vector3(8, 0, 0)))
	for sx: float in [-1.0, 1.0]:
		_put(bone, cyl(0.0, 0.035, 0.11, 6), _xf(c + Vector3(0.055 * sx, 0.085, -0.03), Vector3(-35, 0, -20.0 * sx)))
		_fang(bone, c + Vector3(0.032 * sx, -0.065, 0.225), 0.085, 0.02, -8.0 * sx)
	_put(dark, box(Vector3(0.13, 0.045, 0.04)), _xf(c + Vector3(0, 0.012, 0.118), Vector3(-10, 0, 0)))
	_put(dark, sphere(0.032, 4, 2), _xf(c + Vector3(0, -0.02, 0.255)))
	_seg(lea, c + Vector3(0.10, -0.06, -0.05), Vector3(-0.12, 1.33, 0.29), 0.016, 0.016, 4)          # tie cord
	return _commit("skull", [[bone, palette(&"shadow_bone")], [dark, palette(&"unit_eye_dark")], [lea, palette(&"fire_leather")]])


# ---------------------------------------------------------------- head

## Face (skin) and the leather mask pulled down round the neck (faces pass 2026-09-28: it used to cover the mouth and
## nose, with a dark eye bar in the gap; the eyes, brows and lips are the FaceKit Face node now).
static func _face_mesh() -> ArrayMesh:
	if _tr_meshes.has("face"):
		return _tr_meshes["face"]
	var skin := _bucket()
	var lea := _bucket()
	_put(skin, cyl(0.075, 0.088, 0.16, 6, false), _xf(Vector3(0, 1.47, 0.0)))
	_put(skin, sphere(0.195, 8, 4), _xf(Vector3(0, 1.61, 0.03), Vector3.ZERO, Vector3(0.95, 1.05, 0.95)))
	_put(lea, cyl(0.17, 0.16, 0.10, 8, false), _xf(Vector3(0, 1.455, 0.02), Vector3(-6, 0, 0)))
	return _commit("face", [[skin, palette(&"fire_skin")], [lea, palette(&"fire_leather")]])


## Face (FaceKit, lean: a soldier-budget unit): a weathered hunter, narrowed grey-green eyes, dark brows, a thin hard
## mouth, a dark swept fringe out of the hood (UnitFaces.hood_fringe).
static func _face_spec() -> Dictionary:
	var c := Vector3(0, 1.61, 0.03)
	var hair := Color(0.20, 0.15, 0.11)
	return {"center": c, "radius": 0.195, "head_mesh": sphere(0.195, 8, 4), "head_scale": Vector3(0.95, 1.05, 0.95),
		"preset": &"stern", "detail": &"low", "skin": Color(0.92, 0.72, 0.55), "hair": hair, "eyes": Color(0.40, 0.48, 0.36),
		"ears": &"none", "palette": {"lip": Color(0.72, 0.44, 0.38)},
		"x": {&"neutral": {"mouth": {"curve": 0.35}}},
		"hair_fn": func(acc: Dictionary) -> void:
			UnitFaces.hood_fringe(acc, c, 0.195, hair, Color(0.34, 0.26, 0.18), -1.0, 0.95)}


## Hood point (model space): the peak of the cowl leans back into a short liripipe.
const HOOD_TIP := Vector3(0.0, 1.935, -0.255)
const LIRI_END := Vector3(0.0, 1.80, -0.47)


## The peaked hood: open in front around the face (the brow closes over the forehead), double-sided, the top pulled
## back into a point that continues as a short liripipe; a team ribbon tied at its end (flat band + waving tail).
static func _hood_mesh() -> ArrayMesh:
	if _tr_meshes.has("hood"):
		return _tr_meshes["hood"]
	var oil := _bucket()
	var team := _bucket()
	var prof: Array[Vector2] = [Vector2(0.255, 1.43), Vector2(0.262, 1.60), Vector2(0.254, 1.675), Vector2(0.242, 1.72),
		Vector2(0.205, 1.80), Vector2(0.13, 1.875), Vector2(0.0, 1.935)]
	const COLS := 10
	var pts := PackedVector3Array()
	var hints := PackedVector3Array()
	for j: int in prof.size():
		var y := prof[j].y
		var r := prof[j].x
		var open := lerpf(44.0, 0.0, clampf((y - 1.61) / 0.10, 0.0, 1.0)) * DEG
		var t := clampf((y - 1.60) / 0.335, 0.0, 1.0)
		var back := -0.255 * pow(t, 2.3)
		for i: int in COLS + 1:
			var a := lerpf(open, TAU - open, float(i) / float(COLS))
			var brim := 0.035 * maxf(0.0, cos(a)) * clampf((y - 1.62) / 0.12, 0.0, 1.0) * (1.0 - t * t)
			pts.append(Vector3(sin(a) * r, y, cos(a) * r * 1.06 + back - 0.01 + brim))
			hints.append(Vector3(sin(a), 0.4 * t, cos(a)))
	_grid(oil, pts, hints, COLS, prof.size() - 1, false, true, 0.02)
	# liripipe: tapering tube from the peak, drooping back
	var mid := HOOD_TIP.lerp(LIRI_END, 0.5) + Vector3(0, 0.02, 0)
	_seg(oil, HOOD_TIP + Vector3(0, -0.03, 0.03), mid, 0.06, 0.042, 6)
	_seg(oil, mid, LIRI_END, 0.042, 0.018, 6)
	_put(oil, sphere(0.043, 4, 2), _xf(mid))
	# the contract ribbon: a band round the liripipe (flat UV = plain team colour) + one waving tail
	_put(team, cyl(0.052, 0.05, 0.10, 8, false), Transform3D(Basis(Quaternion(Vector3.UP, (LIRI_END - mid).normalized())),
		mid.lerp(LIRI_END, 0.35)), Vector2(0.0, 0.04))
	var tb := Basis.from_euler(Vector3(-35.0, 180.0, 0.0) * DEG)
	_put(team, cape(0.14, 0.44), Transform3D(tb, mid.lerp(LIRI_END, 0.35) + tb * Vector3(0, -0.22, 0)))
	return _commit("hood", [[oil, _m(&"tracker_oilskin")], [team, _m(&"tracker_pennon")]])


# ---------------------------------------------------------------- arms and crossbow

## Bracer + glove of one arm (model space).
static func _arm_leather_mesh(side: float) -> ArrayMesh:
	var key := "arm%d" % int(side)
	if _tr_meshes.has(key):
		return _tr_meshes[key]
	var acc := _bucket()
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var hand := GRIP_R if side > 0.0 else HAND_L
	var d := (hand - sh).normalized()
	_put(acc, cyl(0.108, 0.096, 0.16, 8, false), Transform3D(Basis(Quaternion(Vector3.DOWN, d)), sh.lerp(hand, 0.78)))
	_put(acc, sphere(0.10, 7, 4), _xf(hand))
	return _commit(key, [[acc, null]])


## Team band on the left forearm (flat UV: plain team colour) with two short waving tails on its outer side.
static func _armband_mesh() -> ArrayMesh:
	if _tr_meshes.has("armband"):
		return _tr_meshes["armband"]
	var acc := _bucket()
	var d := (HAND_L - SHOULDER_L).normalized()
	var c := SHOULDER_L.lerp(HAND_L, 0.58)
	_put(acc, cyl(0.106, 0.1, 0.16, 10, false), Transform3D(Basis(Quaternion(Vector3.DOWN, d)), c), Vector2(0.0, 0.04))
	var tails: Array = [[Vector3(-0.1, 0.05, 0.03), 0.13, 0.38, -8.0], [Vector3(-0.1, 0.04, -0.05), 0.11, 0.30, 6.0]]
	for t: Array in tails:
		var b := Basis.from_euler(Vector3(0.0, -80.0, float(t[3])) * DEG)
		var h: float = t[2]
		_put(acc, cape(float(t[1]), h), Transform3D(b, c + (t[0] as Vector3) + b * Vector3(0, -h * 0.5, 0)))
	return _commit("armband", [[acc, null]])


## The heavy crossbow in grip space (origin = the fist, +Z = the shot, +Y = the top of the stock). loaded: the prod
## flexed back, the string spanned to the nut and a snare bolt (amber glowing head) in the groove; else the string
## rests straight across the relaxed prod.
static func _xbow_mesh(loaded: bool) -> ArrayMesh:
	var key := "xbow%d" % int(loaded)
	if _tr_meshes.has(key):
		return _tr_meshes[key]
	var wood := _bucket()
	var metal := _bucket()
	var pale := _bucket()
	var lea := _bucket()
	var glow := _bucket()
	# stock, drop butt, top rail, grip wrap
	_put(wood, box(Vector3(0.075, 0.09, 0.66)), _xf(Vector3(0, 0.075, 0.20)))
	_put(wood, box(Vector3(0.08, 0.16, 0.22)), _xf(Vector3(0, 0.035, -0.22), Vector3(-10, 0, 0)))
	# prod block, the steel prod (recurved tips), nocks, stirrup
	var py := 0.08
	_put(metal, box(Vector3(0.14, 0.11, 0.10)), _xf(Vector3(0, py, 0.51)))
	var flex := 1.0 if loaded else 0.35
	var limb: Array[Vector2] = [Vector2(0.0, 0.515), Vector2(0.22, 0.52), Vector2(0.40, 0.48), Vector2(0.545, 0.43)]
	var tips: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		var prev := Vector3.ZERO
		for k: int in limb.size():
			var z0: float = 0.515 + (limb[k].y - 0.515) * (0.6 + 0.4 * flex)
			var p := Vector3(limb[k].x * sx, py, z0)
			if k > 0:
				var r0 := lerpf(0.036, 0.02, float(k - 1) / 3.0)
				var r1 := lerpf(0.036, 0.02, float(k) / 3.0)
				_seg(metal, prev, p, r0, r1, 4)
			prev = p
		_put(metal, sphere(0.032, 4, 2), _xf(prev))
		tips.append(prev)
	_put(metal, torus(0.055, 0.085, 6), _xf(Vector3(0, py - 0.005, 0.63), Vector3(90, 0, 0)))
	# fang charm under the stirrup
	_seg(lea, Vector3(0, py - 0.08, 0.63), Vector3(0, py - 0.16, 0.63), 0.012, 0.012, 4)
	_fang(pale, Vector3(0.0, py - 0.15, 0.632), 0.11, 0.026, 8.0)
	var nut := Vector3(0, 0.135, 0.05)
	if loaded:
		_seg(pale, tips[0], nut, 0.009, 0.009, 4)
		_seg(pale, nut, tips[1], 0.009, 0.009, 4)
		# snare bolt: shaft, pale vanes, the glowing barbed head
		_seg(wood, Vector3(0, 0.15, 0.06), Vector3(0, 0.15, 0.66), 0.016, 0.016, 5)
		_put(pale, box(Vector3(0.07, 0.012, 0.10)), _xf(Vector3(0, 0.15, 0.13)))
		_put(glow, cyl(0.0, 0.042, 0.13, 6), _xf(Vector3(0, 0.15, 0.725), Vector3(90, 0, 0)))
	else:
		_seg(pale, tips[0], tips[1], 0.009, 0.009, 4)
	return _commit(key, [[wood, palette(&"fire_wood")], [metal, palette(&"warden_metal")], [pale, palette(&"shadow_bone")],
		[lea, palette(&"fire_leather")], [glow, _m(&"tracker_glow")]])


# ================================================================ animation

## Aim: k = weight (0 carried at the side, 1 at the shoulder), elev = deg above the horizon.
func _aim(k: float, elev: float) -> void:
	rot(P_ARM_R, Vector3(-(AIM_ARM + elev) * DEG * k, 0.0, 0.0))
	pos(P_ARM_R, Vector3(-0.05 * k, 0.0, -0.10 * k))
	rot(P_CHEST, Vector3(-elev / 5.0 * DEG * k, CHEST_YAW * DEG * k, 0))
	rot(P_HEAD, Vector3(-elev * 0.2 * DEG * k, -CHEST_YAW * 0.7 * DEG * k, 0))
	rot(P_ARM_L, Vector3(-(78.0 + elev * 0.9) * DEG * k, 38.0 * DEG * k, 0))
	pos(P_ARM_L, Vector3(0.10 * k, 0.0, 0.10 * k))
	rot(P_LEG_R, Vector3(8.0 * DEG * k, 0, 0))
	rot(P_LEG_L, Vector3(-8.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, -0.035 * k, 0))
	_bow_k = maxf(_bow_k, k)
	_elev = elev


## One aimed shot: raise (smoothed, so a re-trigger mid-way keeps the aim), loose at `rel`, re-span, hold to `hold`,
## lower. Returns false when finished.
func _shot(prev: float, t: float, rel: float, hold: float, elev: float) -> bool:
	var dt := maxf(t - prev, 0.0)
	var target := 1.0 if t < hold else 0.0
	_aim_s = move_toward(_aim_s, target, dt / (0.11 if target > _aim_s else 0.30))
	var k := smoothstep(0.0, 1.0, _aim_s)
	_aim(k, elev)
	if prev < rel and t >= rel:
		_on_action_event(&"release")
	# recoil: the nose kicks up, the body rocks back
	var r := _k3(t, rel, rel + 0.03, rel + 0.07, rel + 0.30, 1.0, 0.5)
	rot(P_ARM_R, Vector3(-10.0 * DEG * r, 0, 0))
	pos(P_ROOT, Vector3(0, 0, -0.05 * r))
	# re-span: the nose dips, the free hand hauls the string back to the nut
	var rl := _k3(t, rel + 0.20, rel + 0.34, rel + 0.46, rel + 0.64, 1.0, 1.0) * k
	rot(P_ARM_R, Vector3(20.0 * DEG * rl, 0, 0))
	rot(P_ARM_L, Vector3(30.0 * DEG * rl, -20.0 * DEG * rl, 0))
	pos(P_ARM_L, Vector3(0, 0, -0.08 * rl))
	if not _loaded and t >= rel + 0.42:
		_set_loaded(true)
	return t < hold or _aim_s > 0.0


## Attack `crossbow` (windup = release <= 0.15).
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"crossbow":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.15
	return _shot(prev, t, w, 0.85, 4.0)


## Any cast id: a slower aimed snare shot (release 0.30 s, 10 deg up).
func _pose_cast(_spell: StringName, t: float) -> float:
	var prev := _cast_prev
	_cast_prev = t
	return 99.0 if _shot(prev, t, 0.30, 1.0, 10.0) else 0.0


func _set_loaded(on: bool) -> void:
	if on == _loaded:
		return
	_loaded = on
	if _xbow:
		_xbow.mesh = _xbow_mesh(on)
		_glow_w = -1.0


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"attack_start":
			_set_loaded(true)
		&"cast_start":
			_cast_prev = 0.0
			_set_loaded(true)
		&"release":
			_set_loaded(false)
			_flare = 1.0
			if _spark and _tier < 2:
				_spark.restart()


## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	var k := clampf(_bow_k, 0.0, 1.0)
	_bow_k = 0.0
	if _dead:
		_aim_s = 0.0
		k = 0.0
	# Crossbow: carried nose-down at the side -> level along the shot (counters the arm raise and the chest turn).
	if _xbow:
		var q := Quaternion.from_euler(XBOW_REST * DEG)
		if k > 0.0:
			var aim := Basis(Vector3.RIGHT, (AIM_ARM + _elev) * DEG) * Basis(Vector3.UP, -CHEST_YAW * DEG) \
				* Basis(Vector3.RIGHT, -_elev * DEG)
			q = q.slerp(aim.get_rotation_quaternion(), k)
		if not q.is_equal_approx(_q_w):
			_q_w = q
			_xbow.quaternion = q
		# Bolt head: dim at rest, bright while aimed ("drawing"); a short flash as it looses (sparks).
		_flare = maxf(0.0, _flare - dt * 4.0)
		var g := glow_level() * (REST_TIP_GLOW + AIM_TIP_GLOW * k + 1.5 * _flare) if _loaded else 0.0
		if g != _glow_w:
			_glow_w = g
			_xbow.set_instance_shader_parameter(&"glow_boost", g)


func _on_revive() -> void:
	if _face:
		_face.reset()
	_aim_s = 0.0
	_flare = 0.0
	_cast_prev = 0.0
	_set_loaded(true)
	_q_w = Quaternion(2, 0, 0, 0)
	_glow_w = -1.0
