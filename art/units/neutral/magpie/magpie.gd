extends CharacterModel
## The Magpie, a neutral thief of the Thieves' Guild (market-trade.md 5 / 9, task 10.V6). A lean bandit who moves in
## a permanent crouch on bird-bent legs: a black hood with a swept-back crest of iridescent feathers, a white
## BEAKED HALF-MASK (black beak, blue-green eye shine), a black / white PATCHWORK capelet whose white panels sit on the
## shoulders like a magpie's scapulars, a white belly patch, white-wrapped shins, and a long wedge-shaped TAIL CLOAK
## (black with white patches and an iridescent blue-green trim) streaming behind. Twin straight steel knives held in
## reverse grip, blades flaring out from the wrists like wing feathers. Neutral: no team colour at all.
## Loot: `set_carrying(true)` shows a big pale burlap SACK on the back (knotted neck over the right shoulder, rope
## strap, gold coins at the mouth), the one shape that tells a Magpie with loot apart at 40 m.
## Motion: a "lurk" idle (deep crouch, bird-like head snaps and tilts, the tail flicking), a sneaky crouched scurry,
## `scissor` attack (both knives cut inward crossing in front, strike 0.12 s, with a beak peck), `play_snatch()`
## (1.5 s channel: lunge, rummage with the left hand while the head snaps around, yank the sack over the shoulder),
## `play_smoke_flee()` (also on `set_status(&"shroud", true)`: a smoke puff, arms cross over the face, then a low
## sprint with the arms swept back like wings while the shroud lasts), `fall` death in a puff of smoke.
## Glow: ONE point, the eye shine (the FaceKit irises on the Face node, faces pass 2026-09-28), flares while snatching.
## Budget: 9 authored meshes (blob included) + 1 one-shot emitter; 10 draw instances (6 merged pivots + Tail, Sack,
## blob, Puff); 0 lights; 6 own materials + the kit's blob and gold trim.

const DIR := "res://art/units/neutral/magpie/"
const EYE := Color(0.3, 1.0, 0.85)
const SMOKE_A := Color(0.78, 0.82, 0.90, 0.85)
const SMOKE_B := Color(0.40, 0.46, 0.60, 0.0)

# Model-space key points (feet origin, face +Z, weapon hand ArmR at +X). Rest pose = the crouched lurk.
const LEAN_DEG := 14.0
const TORSO_PIVOT := Vector3(0.0, 0.70, 0.0)
const SHOULDER_R := Vector3(0.27, 1.12, 0.08)
const SHOULDER_L := Vector3(-0.27, 1.12, 0.08)
const ELBOW_R := Vector3(0.33, 0.92, -0.02)
const ELBOW_L := Vector3(-0.33, 0.92, -0.02)
const HAND_R := Vector3(0.31, 0.90, 0.21)
const HAND_L := Vector3(-0.31, 0.90, 0.21)
const KNIFE_R_AXIS := Vector3(0.60, -0.15, -0.78)   # reverse grip: blade out and back from the wrist
const KNIFE_L_AXIS := Vector3(-0.60, -0.15, -0.78)
const BLADE_LEN := 0.30
const HOOD_C := Vector3(0.0, 1.37, 0.05)
const FACE_C := Vector3(0.0, 1.35, 0.13)
const BEAK_ROOT := Vector3(0.0, 1.33, 0.29)
const BEAK_TIP := Vector3(0.0, 1.22, 0.545)
const EYE_AT := Vector3(0.0, 1.425, 0.352)
const TAIL_AT := Vector3(0.0, 1.10, -0.16)
const TAIL_PTS: Array[Vector3] = [Vector3(0.0, 1.10, -0.16), Vector3(0.0, 0.92, -0.28), Vector3(0.0, 0.72, -0.38),
	Vector3(0.0, 0.52, -0.45), Vector3(0.0, 0.34, -0.49)]
const SACK_AT := Vector3(0.03, 1.08, -0.24)
const SACK_C := Vector3(0.17, 1.33, -0.30)
const SNATCH_LEN := 1.5
const FLEE_LEN := 0.5
const PEEK_LEN := 1.7
const SNAP_PERIOD := 0.85

# Keyframe tables [times], [values] (degrees / metres). Smooth between keys.
const SN_T: Array[float] = [0.0, 0.18, 0.34, 0.60, 0.85, 1.08, 1.22, 1.36, 1.50]
const SN_BZ: Array[float] = [0.0, 0.24, 0.27, 0.27, 0.27, 0.25, 0.04, -0.03, 0.0]
const SN_BY: Array[float] = [0.0, -0.12, -0.14, -0.14, -0.14, -0.12, 0.03, 0.0, 0.0]
const SN_CX: Array[float] = [0.0, 24.0, 28.0, 26.0, 28.0, 24.0, -12.0, -4.0, 0.0]
const SN_CY: Array[float] = [0.0, 10.0, 14.0, 12.0, 14.0, 10.0, -20.0, -6.0, 0.0]
const SN_LX: Array[float] = [0.0, -80.0, -92.0, -84.0, -92.0, -86.0, -170.0, -70.0, 0.0]
const SN_LZ: Array[float] = [0.0, 12.0, 14.0, 14.0, 14.0, 12.0, 20.0, 5.0, 0.0]
const SN_RX: Array[float] = [0.0, -30.0, -38.0, -38.0, -38.0, -34.0, -10.0, -4.0, 0.0]
const SN_RZ: Array[float] = [0.0, 20.0, 24.0, 24.0, 24.0, 20.0, 8.0, 2.0, 0.0]
const SN_HX: Array[float] = [0.0, 14.0, 8.0, 6.0, 8.0, 10.0, -18.0, -6.0, 0.0]
const SN_GL: Array[float] = [0.0, -26.0, -28.0, -28.0, -28.0, -24.0, 4.0, 0.0, 0.0]
const SN_GR: Array[float] = [0.0, 20.0, 22.0, 22.0, 22.0, 20.0, -4.0, 0.0, 0.0]
const SN_HT: Array[float] = [0.0, 0.30, 0.36, 0.55, 0.61, 0.80, 0.86, 1.02, 1.10, 1.50]
const SN_HY: Array[float] = [0.0, 0.0, 40.0, 40.0, -38.0, -38.0, 30.0, 30.0, 0.0, 0.0]
const SN_HZ: Array[float] = [0.0, 0.0, 14.0, 14.0, -12.0, -12.0, 10.0, 10.0, 0.0, 0.0]

const FL_T: Array[float] = [0.0, 0.10, 0.20, 0.34, 0.50]
const FL_BY: Array[float] = [0.0, -0.16, -0.12, 0.06, 0.0]
const FL_CX: Array[float] = [0.0, 26.0, 18.0, 30.0, 0.0]
const FL_AX: Array[float] = [0.0, -115.0, -100.0, 40.0, 0.0]
const FL_AZ: Array[float] = [0.0, 45.0, 40.0, -30.0, 0.0]
const FL_HX: Array[float] = [0.0, 20.0, 15.0, -8.0, 0.0]

const PK_T: Array[float] = [0.0, 0.30, 0.55, 0.85, 1.15, 1.40, 1.70]
const PK_BY: Array[float] = [0.0, -0.07, -0.07, -0.07, -0.07, -0.05, 0.0]
const PK_CX: Array[float] = [0.0, 14.0, 16.0, 16.0, 16.0, 10.0, 0.0]
const PK_HX: Array[float] = [0.0, -12.0, -14.0, -10.0, -14.0, -8.0, 0.0]
const PK_HY: Array[float] = [0.0, 0.0, 30.0, 30.0, -25.0, -25.0, 0.0]
const PK_AX: Array[float] = [0.0, -18.0, -20.0, -20.0, -20.0, -12.0, 0.0]

static var _own_mats: Dictionary = {}
static var _meshes: Dictionary = {}

var _tail: MeshInstance3D
var _sack: MeshInstance3D
var _puff: GPUParticles3D
var _eye_glow: GeometryInstance3D     # the Face node (the glowing irises), driven here
## Painted face (FaceKit, faces pass 2026-09-28).
var _face: FaceRig

# Secondary motion (springs).
var _tail_a: Vector2 = Vector2.ZERO    # x = lift back (rot x), y = side swing (rot z)
var _tail_v: Vector2 = Vector2.ZERO
var _sack_a: Vector3 = Vector3.ZERO    # x = swing back, y = bounce (m), z = side swing
var _sack_v: Vector3 = Vector3.ZERO
var _prev_root_z: float = 0.0
var _prev_yaw: float = 0.0
var _sack_rest: Vector3 = Vector3.ZERO
var _tail_written: Vector2 = Vector2(99, 99)
var _sack_written: Vector3 = Vector3(99, 99, 99)
# Per-frame targets written by the poses (reset every frame).
var _eye_k: float = 1.0
var _eye_written: float = -1.0
var _sack_off: Vector3 = Vector3.ZERO
var _sack_scale: float = 1.0
var _sack_off_written: Vector3 = Vector3.ZERO
var _sack_scale_written: float = 1.0
var _sack_forced: bool = false         # the snatch shows the sack before gameplay says "carrying"
var _fleeing: bool = false
var _idle_left: float = 8.0
var _fidget_next: float = 0.0
## G-D signature emitter (High / Ultra only; null otherwise).
var _sig: GPUParticles3D


static func _mat(name: StringName) -> Material:
	if not _own_mats.has(name):
		_own_mats[name] = load(DIR + "magpie_" + String(name) + ".tres")
	return _own_mats[name]


## G-D signature gate (CreatureSignature, High / Ultra only): near tier, animating, alive.
func signature_should_emit() -> bool:
	return _tier == 0 and not _offscreen and not _frozen and not _dead


# ================================================================ hooks

## Neutral: no team colour on a Magpie (market-trade.md 5.1). Always a no-op.
func set_team_color(_c: Color) -> void:
	pass


## 1.5 s channel (market-trade.md 5.3 "Snatch 1.5 s"): lunge, rummage in the victim's cargo, yank a sack over the
## shoulder. Gameplay still decides the loot (set_carrying); cancel_snatch() when the channel is broken.
func play_snatch() -> void:
	play_cast(&"snatch")


## Ends a snatch early (the channel was broken by damage, or the thief was ordered away). Safe to call any time.
func cancel_snatch() -> void:
	if _action == &"cast" and _cast_id == &"snatch":
		_action = &""
		_force_write = true
		_on_action_event(&"cast_end")


func is_snatching() -> bool:
	return _action == &"cast" and _cast_id == &"snatch" and not _dead


## Smoke puff + arms over the face, then the flee sprint while the shroud lasts. set_status(&"shroud", true) calls it.
func play_smoke_flee() -> void:
	play_cast(&"smoke_flee")


func is_fleeing() -> bool:
	return _fleeing


func set_status(id: StringName, on: bool) -> bool:
	if id == &"shroud":
		if on and not _fleeing and not _dead:
			play_smoke_flee()
		_fleeing = on and not _dead
		return true
	return super(id, on)


func set_moving(speed: float) -> void:
	super(speed)
	if speed >= 0.3 and is_snatching():
		cancel_snatch()


func set_carrying(on: bool) -> void:
	var was := _carrying
	super(on)
	_sack_forced = false
	if _sack:
		_sack.visible = on and not _dead
		if on and not was:
			_sack_v += Vector3(-2.0, 0.6, 1.2)   # the sack lands on the back with a bounce


func play_hit() -> void:
	var before := _hit_t
	super()
	if _hit_t < before:
		_tail_v += Vector2(3.0, 2.5)
		_sack_v += Vector3(2.0, 0.3, -1.5)


# ================================================================ parts

func _build_parts() -> void:
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var fx: Node3D = $Fx

	# ---- Legs: bird-bent (the crouch is the rest pose), black thighs, white-wrapped shins, pointed boots.
	add_part(leg_l, _leg_mesh(-1.0), null, Vector3.ZERO)
	add_part(leg_r, _leg_mesh(1.0), null, Vector3.ZERO)
	# ---- Chest: leaning torso, white belly, belt, patchwork skirt and capelet (white shoulder panels).
	add_part(chest, _torso_mesh(), null, Vector3.ZERO)
	# ---- The tail cloak streams from the upper back (own node: springs).
	_tail = add_part(chest, _tail_mesh(), null, TAIL_AT, Vector3.ZERO, Vector3.ONE, true, "Tail")
	# ---- Loot sack on the back, shown while carrying (own node: bounces, flies over the shoulder in the snatch).
	_sack = add_part(chest, _sack_mesh(), null, SACK_AT, Vector3.ZERO, Vector3.ONE, true, "Sack")
	_sack.set_meta(&"carry", true)
	_sack.visible = false
	# ---- Head: hood, crest, white beaked half-mask; the FaceKit face (eyes on the band: the eye shine, brows, lips).
	add_part(head, _head_mesh(), null, Vector3.ZERO)
	_face = FaceKit.attach(self, head, "magpie", _face_style())
	_face.set_meta(&"own_glow", true)   # the eye shine: driven in _drive_eyes
	# ---- Arms: sleeves, sheen bracers, white wing patch, gloves, reverse-grip knives.
	add_part(arm_r, _arm_mesh(1.0), null, Vector3.ZERO)
	add_part(arm_l, _arm_mesh(-1.0), null, Vector3.ZERO)
	# ---- Fx: one pre-built one-shot smoke puff (smoke flee, death).
	_puff = _make_puff()
	_puff.name = "Puff"
	_puff.position = Vector3(0.0, 0.55, 0.0)
	_puff.set_meta(&"death_fx", true)
	fx.add_child(_puff)
	ensure_shadow_blob(0.4)


func _after_ready() -> void:
	_sack_rest = _sack.position
	_eye_glow = _face
	if _eye_glow:
		_glow_nodes.erase(_eye_glow)
	_idle_left = 6.0 + 6.0 * fmod(_phase_off * 3.1, 1.0)
	_drive_eyes()
	# G-D signature (High+): a stolen coin glinting at the belt now and then.
	var hips: Node3D = $Root/Hips
	_sig = CreatureSignature.attach(self, hips, Vector3(0.16, 0.92, 0.12) - model_origin(hips), &"glints", 0.8)


# ================================================================ mesh helpers (built once per game, model space)

## Cylinder / cone without the kit's middle ring (a third fewer vertices); caps false = open tube. Cached.
static func _c0(top_r: float, bottom_r: float, h: float, seg: int = 8, caps: bool = true) -> Mesh:
	var key := "c0_%s_%s_%s_%d_%s" % [top_r, bottom_r, h, seg, caps]
	if _meshes.has(key):
		return _meshes[key]
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bottom_r
	m.height = h
	m.radial_segments = seg
	m.rings = 0
	m.cap_top = caps and top_r > 0.0
	m.cap_bottom = caps and bottom_r > 0.0
	_meshes[key] = m
	return m


## [cylinder, transform] from a to b (radius ra at a, rb at b). caps false: open (ends hidden in a joint).
static func _seg(a: Vector3, b: Vector3, ra: float, rb: float, seg: int = 8, caps: bool = true) -> Array:
	var d := b - a
	var l := d.length()
	var bs: Basis
	if d.normalized().y < -0.999:
		bs = Basis(Vector3.RIGHT, PI)
	else:
		bs = Basis(Quaternion(Vector3.UP, d / l))
	return [_c0(rb, ra, 1.0, seg, caps), Transform3D(bs.scaled_local(Vector3(1.0, l, 1.0)), (a + b) * 0.5)]


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


## Two triangles for the quad a-b-c-d, wound so their front faces the vertex normals.
static func _quad(idx: PackedInt32Array, v: PackedVector3Array, n: PackedVector3Array, a: int, b: int, c: int, d: int) -> void:
	var fn := (v[d] - v[a]).cross(v[b] - v[a])
	if fn.length_squared() < 1e-14:
		fn = (v[c] - v[b]).cross(v[d] - v[b])
	if fn.dot(n[a] + n[b] + n[c] + n[d]) >= 0.0:
		idx.append_array(PackedInt32Array([a, b, d, b, c, d]))
	else:
		idx.append_array(PackedInt32Array([a, d, b, b, d, c]))


## Grid surface p = fn(u, v) split into several meshes by pick(col, row) -> int (0..n-1), one per material. Normals
## from finite differences, oriented away from out_from(u, v). double_sided: a back copy with flipped normals.
## Each output mesh keeps only the vertices its quads use. Returns an Array of n ArrayMesh (null when empty).
static func _grid_split(fn: Callable, out_from: Callable, cols: int, rows: int, pick: Callable, n: int,
		double_sided: bool = false) -> Array:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
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
	var out: Array = []
	for k: int in n:
		var kv := PackedVector3Array()
		var kn := PackedVector3Array()
		var idx := PackedInt32Array()
		for s: int in (2 if double_sided else 1):
			var sg := 1.0 if s == 0 else -1.0
			var base_map := {}
			for j: int in rows:
				for i: int in cols:
					if int(pick.call(i, j)) != k:
						continue
					var q: Array[int] = [j * (cols + 1) + i, j * (cols + 1) + i + 1, (j + 1) * (cols + 1) + i + 1,
						(j + 1) * (cols + 1) + i]
					var qi: Array[int] = []
					for g: int in q:
						if not base_map.has(g):
							base_map[g] = kv.size()
							kv.append(verts[g])
							kn.append(norms[g] * sg)
						qi.append(base_map[g])
					_quad(idx, kv, kn, qi[0], qi[1], qi[2], qi[3])
		if idx.is_empty():
			out.append(null)
		else:
			var uvs := PackedVector2Array()
			uvs.resize(kv.size())
			out.append(_mesh(kv, kn, uvs, idx))
	return out


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


## A tapered tube along a Catmull-Rom curve (rope strap). rfn(v) -> radius.
static func _tube(pts: Array[Vector3], r: float, ring: int, samples: int) -> ArrayMesh:
	var frame := func(v: float) -> Array:
		var t := (_cr(pts, minf(v + 0.01, 1.0)) - _cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var ref := Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.FORWARD
		var nn := t.cross(ref).normalized()
		return [nn, t.cross(nn).normalized()]
	var fn := func(u: float, v: float) -> Vector3:
		var fr: Array = frame.call(v)
		var a := TAU * u
		return _cr(pts, v) + r * ((fr[0] as Vector3) * cos(a) + (fr[1] as Vector3) * sin(a))
	var centre := func(_u: float, v: float) -> Vector3:
		return _cr(pts, v)
	return _grid_split(fn, centre, ring, samples, _one, 1)[0]


## Low-poly coin: a disc of radius r, thickness h (axis +Y).
static func _disc(r: float, h: float, seg: int) -> Mesh:
	return _c0(r, r, h, seg)


static func _lean() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, LEAN_DEG * DEG), TORSO_PIVOT) * Transform3D(Basis(), -TORSO_PIVOT)


# ================================================================ meshes

## Bird-bent leg: black thigh forward to the knee, white-wrapped shin back to the ankle (two black straps), a black
## boot with a pointed toe.
static func _leg_mesh(side: float) -> ArrayMesh:
	var key := "mp_leg%d" % int(side)
	if _meshes.has(key):
		return _meshes[key]
	var hip := Vector3(0.14 * side, 0.64, 0.0)
	var knee := Vector3(0.165 * side, 0.37, 0.15)
	var ankle := Vector3(0.15 * side, 0.12, -0.03)
	var sd := ankle - knee
	return _bake(key, [
		[[_seg(hip, knee, 0.095, 0.078, 8, false), _at(sphere(0.08, 8, 4), knee),
			_seg(knee + sd * 0.30 - sd.normalized() * 0.025, knee + sd * 0.30 + sd.normalized() * 0.025, 0.079, 0.079, 8, false),
			_seg(knee + sd * 0.66 - sd.normalized() * 0.025, knee + sd * 0.66 + sd.normalized() * 0.025, 0.072, 0.072, 8, false),
			_at(_c0(0.078, 0.084, 0.10, 8, false), ankle + Vector3(0, -0.02, 0)),
			_at(box(Vector3(0.14, 0.09, 0.24)), Vector3(0.15 * side, 0.045, 0.03)),
			_seg(Vector3(0.15 * side, 0.05, 0.14), Vector3(0.15 * side, 0.035, 0.25), 0.065, 0.015, 6)], _mat(&"black")],
		[[_seg(knee, ankle, 0.070, 0.058, 8, false)], _mat(&"white")]])


## Short jerkin skirt below the belt, cut into feather points; patchwork panels.
static func _skirt_point(u: float, v: float) -> Vector3:
	var a := TAU * u
	var r := 0.185 + 0.085 * v + 0.012 * sin(10.0 * a) * v
	var dag := 0.05 * pow(absf(cos(5.0 * a)), 3.0) * v * v * v
	return Vector3(sin(a) * r, lerpf(0.77, 0.53, v) - dag, cos(a) * r)


## Capelet over the shoulders: a round mantle with 8 feather points on the hem.
static func _mantle_point(u: float, v: float) -> Vector3:
	var a := TAU * u
	var r := 0.13 + 0.24 * sin(v * PI * 0.5)
	var back := maxf(0.0, -cos(a))
	var dag := 0.07 * pow(absf(cos(4.0 * a)), 3.0) * v * v * v
	return Vector3(sin(a) * r * 1.06, 1.25 - 0.27 * v * v - dag - 0.04 * back * v, cos(a) * r)


const SKIRT_PANELS: Array[int] = [0, 1, 0, 0, 1, 0, 1, 0]
const SKIRT_COLS := 16
const MANTLE_COLS := 20
const TAIL_COLS := 6
const TAIL_ROWS := 8


static func _skirt_pick(i: int, _j: int) -> int:
	return SKIRT_PANELS[(i * 8) / SKIRT_COLS]


## Capelet panels: white on the shoulders (a magpie's scapulars) and one off-centre patch on the back.
static func _mantle_pick(i: int, j: int) -> int:
	var a := TAU * (float(i) + 0.5) / float(MANTLE_COLS)
	if absf(sin(a)) > 0.62:
		return 1
	if a > 3.45 and a < 4.0 and j >= 2:
		return 1
	return 0


## Tail panels: 2 = iridescent trim (both edges, the hem), 1 = white patches, 0 = black.
static func _tail_pick(i: int, j: int) -> int:
	if i == 0 or i == TAIL_COLS - 1 or j == TAIL_ROWS - 1:
		return 2
	if (j >= 1 and j <= 2 and i >= 1 and i <= 2) or (j >= 4 and j <= 5 and i == 3):
		return 1
	return 0


static func _one(_i: int, _j: int) -> int:
	return 0


## Torso keg (leaning), the white belly patch, the belt with a steel buckle, the patchwork skirt and capelet.
static func _torso_mesh() -> ArrayMesh:
	if _meshes.has("mp_torso"):
		return _meshes["mp_torso"]
	var lean := _lean()
	var skirt := _grid_split(func(u: float, v: float) -> Vector3: return _skirt_point(u, v),
			func(u: float, v: float) -> Vector3: return Vector3(0, _skirt_point(u, v).y, 0), SKIRT_COLS, 3,
			_skirt_pick, 2, false)
	var mantle := _grid_split(func(u: float, v: float) -> Vector3: return _mantle_point(u, v),
			func(u: float, v: float) -> Vector3: return Vector3(0, _mantle_point(u, v).y + 0.05, 0), MANTLE_COLS, 4,
			_mantle_pick, 2, true)
	var black: Array = [[_c0(0.225, 0.18, 0.50, 10), lean * Transform3D(Basis(), Vector3(0, 0.95, 0))],
		_at(_c0(0.212, 0.205, 0.08, 10, false), Vector3(0, 0.735, 0))]
	var white: Array = [[sphere(0.19, 10, 5), lean * Transform3D(Basis().scaled(Vector3(1.12, 1.1, 1.0)), Vector3(0, 0.87, 0.085))]]
	for k: int in 2:
		if skirt[k]:
			(black if k == 0 else white).append([skirt[k], Transform3D()])
		if mantle[k]:
			(black if k == 0 else white).append([mantle[k], lean])
	return _bake("mp_torso", [[black, _mat(&"black")], [white, _mat(&"white")],
		[[_at(box(Vector3(0.12, 0.09, 0.05)), Vector3(0, 0.735, 0.215))], _mat(&"steel")]])


## Wedge tail cloak: centre feathers longest (graduated), slightly domed, black with white patches, iridescent trim
## on both edges and on the hem. Relative to TAIL_AT (own node).
static func _tail_point(u: float, v: float) -> Vector3:
	var c := _cr(TAIL_PTS, v)
	var e := absf(u - 0.5) * 2.0
	var w := lerpf(0.40, 0.48, v)
	var x := (u - 0.5) * w
	var lift := 0.16 * e * e * v                     # outer feathers shorter (graduated fan)
	var dome := -0.035 * sin(PI * u) * (1.0 - 0.5 * v)
	return c + Vector3(x, lift, dome) - TAIL_AT


static func _tail_mesh() -> ArrayMesh:
	if _meshes.has("mp_tail"):
		return _meshes["mp_tail"]
	var parts := _grid_split(func(u: float, v: float) -> Vector3: return _tail_point(u, v),
			func(_u: float, v: float) -> Vector3: return _cr(TAIL_PTS, v) + Vector3(0, 0, 0.3) - TAIL_AT,
			TAIL_COLS, TAIL_ROWS, _tail_pick, 3, true)
	var m := _bake("mp_tail", [[[[parts[0], Transform3D()]], _mat(&"black")],
		[[[parts[1], Transform3D()]], _mat(&"white")], [[[parts[2], Transform3D()]], _mat(&"sheen")]])
	return m


## Bulging burlap sack (lumpy, tied neck leaning to the right shoulder), a black rope tie and strap over the right
## shoulder to the chest, two gold coins at the mouth. Relative to SACK_AT (own node).
static func _sack_point(u: float, v: float) -> Vector3:
	var a := TAU * u
	var r: float
	var y: float
	if v < 0.12:
		var s := v / 0.12
		r = lerpf(0.12, 0.07, s) + 0.016 * sin(7.0 * a) * (1.0 - s)
		y = lerpf(0.28, 0.20, s)
	else:
		var s := (v - 0.12) / 0.88
		var ph := lerpf(0.29, PI, s)
		var sp := sin(ph)
		r = 0.31 * sp * (1.0 + 0.08 * sin(5.0 * a + 0.4) * sp * sp + 0.05 * sin(3.0 * a + 1.3))
		y = -0.01 + 0.25 * cos(ph) - 0.03 * sp * sp
	return Vector3(sin(a) * r, y, cos(a) * r * 0.85)


static func _sack_mesh() -> ArrayMesh:
	if _meshes.has("mp_sack"):
		return _meshes["mp_sack"]
	var xf := Transform3D(Basis(Vector3.BACK, -28.0 * DEG) * Basis(Vector3.RIGHT, -12.0 * DEG), SACK_C - SACK_AT)
	var body: ArrayMesh = _grid_split(func(u: float, v: float) -> Vector3: return _sack_point(u, v),
			func(_u: float, v: float) -> Vector3: return Vector3(0, _sack_point(0.0, v).y, 0), 12, 8,
			_one, 1)[0]
	var neck := xf * Vector3(0, 0.20, 0)
	var mouth := xf * Vector3(0, 0.27, 0)
	var strap_pts: Array[Vector3] = [neck, neck + Vector3(0.10, 0.02, 0.12), Vector3(0.24, 1.29, 0.0) - SACK_AT,
		Vector3(0.22, 1.16, 0.16) - SACK_AT, Vector3(0.10, 1.00, 0.24) - SACK_AT]
	return _bake("mp_sack", [
		[[[body, xf]], _mat(&"burlap")],
		[[[torus(0.06, 0.095, 8), xf * Transform3D(Basis().scaled(Vector3(1, 1.6, 1)), Vector3(0, 0.20, 0))],
			[_tube(strap_pts, 0.028, 4, 8), Transform3D()]], _mat(&"black")],
		[[[_disc(0.07, 0.024, 8), Transform3D(xf.basis * Basis(Vector3.RIGHT, 65.0 * DEG) * Basis(Vector3.BACK, 20.0 * DEG), mouth + Vector3(0.015, 0.03, 0.03))],
			[_disc(0.065, 0.024, 8), Transform3D(xf.basis * Basis(Vector3.RIGHT, -30.0 * DEG) * Basis(Vector3.BACK, -50.0 * DEG), mouth + Vector3(-0.035, 0.02, -0.02))]],
			palette(&"unit_gold_trim")]])


## White half-mask: a patch of a sphere over the whole face opening, wrapping into the hood.
static func _mask_point(u: float, v: float) -> Vector3:
	const R := 0.215
	var a := lerpf(-1.25, 1.25, u)
	var th := lerpf(0.50, 2.05, v) - 0.18 * (1.0 - cos(a)) * v   # the lower edge climbs toward the cheeks
	return FACE_C + R * Vector3(sin(th) * sin(a), cos(th), sin(th) * cos(a))


## The black bandit band across the eyes, over the white mask.
static func _band_point(u: float, v: float) -> Vector3:
	const R := 0.222
	var a := lerpf(-1.12, 1.12, u)
	var th := lerpf(1.02, 1.42, v) + 0.06 * (1.0 - cos(a)) * (1.0 - 2.0 * v)
	return FACE_C + R * Vector3(sin(th) * sin(a), cos(th), sin(th) * cos(a))


## Hood, shadowed face, the white mask with its black bandit band and the eye shine, the beak (white root, black
## tip), three iridescent crest feathers.
static func _head_mesh() -> ArrayMesh:
	if _meshes.has("mp_head"):
		return _meshes["mp_head"]
	var mask: ArrayMesh = _grid_split(func(u: float, v: float) -> Vector3: return _mask_point(u, v),
			func(_u: float, _v: float) -> Vector3: return FACE_C, 10, 4, _one, 1)[0]
	var band: ArrayMesh = _grid_split(func(u: float, v: float) -> Vector3: return _band_point(u, v),
			func(_u: float, _v: float) -> Vector3: return FACE_C, 8, 1, _one, 1)[0]
	var feather := _c0(0.0, 0.07, 1.0, 4)
	var crest: Array = []
	for f: Array in [[-0.055, 0.30, -14.0, -52.0], [0.0, 0.40, 0.0, -60.0], [0.055, 0.30, 14.0, -52.0]]:
		var x: float = f[0]
		var ln: float = f[1]
		var b := Basis.from_euler(Vector3(float(f[3]), 0.0, float(f[2])) * DEG)
		var base := Vector3(x, 1.575, -0.02)
		crest.append([feather, Transform3D(b.scaled_local(Vector3(0.45, ln, 1.0)), base + b.y * ln * 0.5)])
	var mid := BEAK_ROOT.lerp(BEAK_TIP, 0.45)
	var m := _bake("mp_head", [
		# (hood 10 x 5, was 12 x 6; the hidden face sphere 6 x 3, was 8 x 4: faces pass 2026-09-28 trims for the face)
		[[_at(sphere(0.24, 10, 5), HOOD_C, Vector3.ZERO, Vector3(1.0, 1.06, 1.12)), _at(sphere(0.185, 6, 3), FACE_C),
			[band, Transform3D()], _seg(mid, BEAK_TIP, 0.05, 0.0, 8, false)], _mat(&"black")],
		[[[mask, Transform3D()], _seg(BEAK_ROOT, mid, 0.09, 0.05, 8, false)], _mat(&"white")],
		[crest, _mat(&"sheen")]])
	return m


## Cinematic / UI hook: FaceKit.EXPRESSIONS (&"neutral" default, &"smile", &"fierce", &"worried", &"shout").
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## Face (FaceKit, faces pass 2026-09-28; replaces the glowing eye box): round bird-bright eyes painted on the black
## bandit band (dark eyes, glowing blue-green irises: the one glow point), black brow strokes on the white mask above
## them, small painted lips on the mask's chin under the beak. The canvas is the mask sphere, lifted over the band.
static func _face_style() -> Dictionary:
	if _meshes.has("_face_style"):
		return _meshes["_face_style"]
	var white := Color(0.80, 0.80, 0.78)
	var spec := {"center": FACE_C, "radius": 0.215, "head_mesh": sphere(0.215, 10, 5), "preset": &"hollow", "detail": &"low",
		"skin": white, "hair": Color(0.08, 0.08, 0.10), "eyes": EYE, "ears": &"none",
		"eye": {"c": Vector2(0.072, 0.072), "hw": 0.036, "top": 0.026, "bot": 0.020, "ir": 0.019, "pupil": 0.42},
		"brow": {"inner": Vector2(0.034, 0.112), "mid": Vector2(0.072, 0.128), "outer": Vector2(0.110, 0.116),
			"w": Vector3(0.0065, 0.0070, 0.0030)},
		"mouth": {"c": Vector2(0.0, -0.090), "hw": 0.030, "lip": 0.0030},
		"palette": {"sclera": FaceKit.glow(Color(0.80, 0.95, 0.92), 0.25), "iris_glow": 0.75, "pupil": Color(0.02, 0.05, 0.05),
			"lash": Color(0.02, 0.02, 0.03), "brow": Color(0.06, 0.06, 0.08), "lip": Color(0.62, 0.46, 0.46),
			"lip_line": Color(0.12, 0.10, 0.10), "highlight": Color(0.85, 1.0, 0.95)}}
	var st := UnitFaces.lean(FaceKit.style_from(spec), false)
	st["canvas"] = FaceKit.canvas(FACE_C, 0.215, sphere(0.215, 10, 5), Vector3.ONE, Vector3.INF, Basis.IDENTITY, 0.02)
	_meshes["_face_style"] = st
	return st


## Knife frame at the fist: +Y along the blade, +X the thin direction (the flat faces up to the RTS camera).
static func _knife_xf(hand: Vector3, axis: Vector3) -> Transform3D:
	var y := axis.normalized()
	var x := (Vector3.UP - y * Vector3.UP.dot(y)).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x, y, z), hand)


## Sleeve (shoulder, bent elbow), the iridescent bracer, a white wing patch on the upper arm, the glove and the
## reverse-grip knife (straight leaf blade flaring out and back from the wrist, cross guard, pommel).
static func _arm_mesh(side: float) -> ArrayMesh:
	var key := "mp_arm%d" % int(side)
	if _meshes.has(key):
		return _meshes[key]
	var sh := SHOULDER_R if side > 0.0 else SHOULDER_L
	var el := ELBOW_R if side > 0.0 else ELBOW_L
	var hand := HAND_R if side > 0.0 else HAND_L
	var kx := _knife_xf(hand, KNIFE_R_AXIS if side > 0.0 else KNIFE_L_AXIS)
	var ky := kx.basis.y
	var d := hand - el
	var up := el - sh
	var out := Vector3(side, 0.0, 0.0)
	var black: Array = [_at(sphere(0.09, 6, 3), sh), _seg(sh, el, 0.078, 0.07, 8, false), _at(sphere(0.07, 6, 3), el),
		_seg(el, hand, 0.068, 0.062, 8, false), _at(sphere(0.082, 8, 4), hand),
		_seg(kx.origin - ky * 0.09, kx.origin + ky * 0.03, 0.026, 0.026, 5, false)]
	var sheen: Array = [_seg(el + d * 0.35, el + d * 0.78, 0.084, 0.078, 8)]
	var white: Array = [[sphere(0.075, 8, 4), Transform3D(Basis(Quaternion(Vector3.UP, up.normalized())).scaled_local(Vector3(0.75, 1.5, 1.1)),
		sh + up * 0.5 + out * 0.045 + Vector3(0, 0, -0.02))]]
	var blade := cyl(0.0, 0.062, BLADE_LEN, 4)
	var steel: Array = [[blade, Transform3D(kx.basis.scaled_local(Vector3(0.35, 1.0, 1.0)), kx.origin + ky * (0.055 + BLADE_LEN * 0.5))],
		[box(Vector3(0.035, 0.035, 0.17)), Transform3D(kx.basis, kx.origin + ky * 0.045)],
		_at(sphere(0.032, 6, 3), kx.origin - ky * 0.10)]
	return _bake(key, [[black, _mat(&"black")], [sheen, _mat(&"sheen")], [white, _mat(&"white")], [steel, _mat(&"steel")]])


## Grey-blue smoke puff (10 soft MIX quads), shared process / draw resources.
static func _make_puff() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 12
	p.lifetime = 1.0
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.92
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-2.5, -1.0, -2.5), Vector3(5, 4, 5))
	var pm: ParticleProcessMaterial = _meshes.get("mp_puff_pm")
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.35
		pm.direction = Vector3.UP
		pm.spread = 75.0
		pm.initial_velocity_min = 0.7
		pm.initial_velocity_max = 1.6
		pm.gravity = Vector3(0, 0.4, 0)
		pm.damping_min = 1.5
		pm.damping_max = 2.5
		pm.scale_min = 0.8
		pm.scale_max = 1.25
		var cv := Curve.new()
		cv.add_point(Vector2(0, 0.45))
		cv.add_point(Vector2(0.35, 1.0))
		cv.add_point(Vector2(1, 1.5))
		var ct := CurveTexture.new()
		ct.curve = cv
		pm.scale_curve = ct
		var g := Gradient.new()
		g.set_color(0, SMOKE_A)
		g.set_color(1, SMOKE_B)
		g.add_point(0.4, Color(0.58, 0.64, 0.76, 0.6))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		_meshes["mp_puff_pm"] = pm
	p.process_material = pm
	var q: QuadMesh = _meshes.get("mp_puff_quad")
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(0.8, 0.8)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true
		sm.vertex_color_use_as_albedo = true
		sm.albedo_texture = mote_texture()
		sm.no_depth_test = false
		q.material = sm
		_meshes["mp_puff_quad"] = q
	p.draw_pass_1 = q
	return p


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


## Bird-like head snaps: a new look (yaw, tilt) every SNAP_PERIOD, reached in 0.08 s and held. Pure function of time.
func _snap(tt: float) -> Vector2:
	var s := tt / SNAP_PERIOD
	var i := floorf(s)
	var f := (s - i) * SNAP_PERIOD
	var k := smoothstep(0.0, 0.08, f)
	return _snap_target(i - 1.0).lerp(_snap_target(i), k)


func _snap_target(i: float) -> Vector2:
	var h := fposmod(sin(i * 12.9898 + _phase_off * 78.233) * 43758.5453, 1.0)
	var h2 := fposmod(sin(i * 4.1414 + _phase_off * 19.19) * 23421.631, 1.0)
	if fposmod(i, 3.0) < 1.0:
		h = 0.5 + (h - 0.5) * 0.3   # every third look is roughly straight ahead
	return Vector2((h - 0.5) * 84.0 * DEG, (h2 - 0.5) * 26.0 * DEG)


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.015 * s, 0))
	_write_rot(P_CHEST, _rest_rot[P_CHEST] + Vector3(2.0 * DEG * s, 0, 0))
	if _tier == 0:
		var sn := _snap(_t + _phase_off * 3.0)
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + Vector3(0, sn.x, sn.y))


func _pose_idle(w: float) -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	pos(P_ROOT, Vector3(0, 0.015 * s * w, 0))
	rot(P_CHEST, Vector3(2.0 * DEG * s * w, 0, 0))
	var sn := _snap(_t + _phase_off * 3.0)
	rot(P_HEAD, Vector3(0, sn.x * w, sn.y * w))


## The sneaky scurry: kit legs / arms, lower and leaning in, head kept level, knives held back and out. Fleeing
## (shroud on): a low sprint, deep lean, arms swept back like wings.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s := sin(TAU * _walk_p)
	var c := cos(TAU * _walk_p)
	if _fleeing:
		rot(P_CHEST, Vector3(26.0 * DEG * w, 0, 0))
		rot(P_HEAD, Vector3(-20.0 * DEG * w, 0, 0))
		pos(P_ROOT, Vector3(0, -0.07 * w, 0))
		rot(P_ARM_L, Vector3((50.0 + 10.0 * s) * DEG * w, 0, -28.0 * DEG * w))
		rot(P_ARM_R, Vector3((50.0 - 10.0 * s) * DEG * w, 0, 28.0 * DEG * w))
	else:
		rot(P_CHEST, Vector3(10.0 * DEG * w, -5.0 * DEG * s * w, 0))
		rot(P_HEAD, Vector3(-9.0 * DEG * w, 6.0 * DEG * s * w, 0))
		pos(P_ROOT, Vector3(0, (-0.035 + 0.02 * c * c) * w, 0))
		rot(P_ARM_L, Vector3(14.0 * DEG * w, 0, -10.0 * DEG * w))
		rot(P_ARM_R, Vector3(4.0 * DEG * w, 0, 10.0 * DEG * w))


## `scissor`: both knives wind out, then cut inward crossing in front (strike 0.12 s) with a lunge and a beak peck.
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"scissor":
		return super(prev, t)
	var ax := _k3(t, 0.0, 0.06, 0.12, 0.40, -40.0, -75.0) * DEG
	var az := _k3(t, 0.0, 0.06, 0.12, 0.40, 45.0, -35.0) * DEG
	rot(P_ARM_R, Vector3(ax, 0, az))
	rot(P_ARM_L, Vector3(ax, 0, -az))
	rot(P_CHEST, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.40, -8.0, 16.0) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.40, -12.0, 22.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.06, 0.12, 0.40, 0.03, -0.05), _k3(t, 0.04, 0.12, 0.16, 0.40, 0.22, 0.22)))
	rot(P_LEG_L, Vector3(_k3(t, 0.0, 0.08, 0.14, 0.40, -10.0, -24.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k3(t, 0.0, 0.08, 0.14, 0.40, 6.0, 18.0) * DEG, 0, 0))
	_eye_k = maxf(_eye_k, 1.0 + 0.5 * _k3(t, 0.0, 0.08, 0.2, 0.4, 1.0, 1.0))
	if prev < 0.12 and t >= 0.12:
		_on_action_event(&"release")
	return t < 0.40


func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"smoke_flee":
			rot(P_ARM_L, Vector3(_kf(t, FL_T, FL_AX) * DEG, 0, _kf(t, FL_T, FL_AZ) * DEG))
			rot(P_ARM_R, Vector3(_kf(t, FL_T, FL_AX) * DEG, 0, -_kf(t, FL_T, FL_AZ) * DEG))
			rot(P_CHEST, Vector3(_kf(t, FL_T, FL_CX) * DEG, 0, 0))
			rot(P_HEAD, Vector3(_kf(t, FL_T, FL_HX) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, _kf(t, FL_T, FL_BY), 0))
			return FLEE_LEN
		&"idle_peek":
			if _speed >= 0.3:
				return 0.0
			rot(P_CHEST, Vector3(_kf(t, PK_T, PK_CX) * DEG, 0, 0))
			rot(P_HEAD, Vector3(_kf(t, PK_T, PK_HX) * DEG, _kf(t, PK_T, PK_HY) * DEG, 0))
			pos(P_ROOT, Vector3(0, _kf(t, PK_T, PK_BY), 0))
			pos(P_HEAD, Vector3(0, 0, 0.05 * _k3(t, 0.0, 0.3, 1.4, 1.7, 1.0, 1.0)))
			var a := _kf(t, PK_T, PK_AX) * DEG
			rot(P_ARM_L, Vector3(a, 0, 0))
			rot(P_ARM_R, Vector3(a, 0, 0))
			_eye_k = maxf(_eye_k, 1.0 + 0.4 * _k3(t, 0.3, 0.5, 1.2, 1.5, 1.0, 1.0))
			return PEEK_LEN
		_:  # snatch (and unknown ids)
			rot(P_ARM_L, Vector3((_kf(t, SN_T, SN_LX) + 9.0 * sin(t * 38.0) * _k3(t, 0.3, 0.4, 1.0, 1.08, 1.0, 1.0)) * DEG,
					0, _kf(t, SN_T, SN_LZ) * DEG))
			rot(P_ARM_R, Vector3(_kf(t, SN_T, SN_RX) * DEG, 0, _kf(t, SN_T, SN_RZ) * DEG))
			rot(P_CHEST, Vector3(_kf(t, SN_T, SN_CX) * DEG, _kf(t, SN_T, SN_CY) * DEG, 0))
			rot(P_HEAD, Vector3(_kf(t, SN_T, SN_HX) * DEG, _kf(t, SN_HT, SN_HY) * DEG, _kf(t, SN_HT, SN_HZ) * DEG))
			pos(P_ROOT, Vector3(0, _kf(t, SN_T, SN_BY), _kf(t, SN_T, SN_BZ)))
			rot(P_LEG_L, Vector3(_kf(t, SN_T, SN_GL) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_kf(t, SN_T, SN_GR) * DEG, 0, 0))
			_eye_k = maxf(_eye_k, 1.0 + 0.9 * _k3(t, 0.25, 0.35, 1.05, 1.2, 1.0, 1.0))
			# The yank: a sack flies from the left hand over the head onto the back.
			if t >= 1.10 and t < SNATCH_LEN and not _carrying:
				var f := clampf((t - 1.10) / 0.26, 0.0, 1.0)
				var e := f * f * (3.0 - 2.0 * f)
				_sack_forced = true
				_sack_off = Vector3(-0.32, 0.62, 0.42).lerp(Vector3.ZERO, e) + Vector3(0, 0.25 * sin(PI * e), 0)
				_sack_scale = lerpf(0.5, 1.0, e)
			return SNATCH_LEN


func _on_action_event(ev: StringName) -> void:
	if _sack == null:
		return
	match ev:
		&"cast_start":
			_sack_forced = false
			_sack.visible = _carrying
			if _cast_id == &"smoke_flee":
				_burst()
				_tail_v += Vector2(6.0, 0.0)
				_sack_v += Vector3(-2.5, 0.5, 0.0)
		&"cast_end":
			_sack_forced = false
			_sack.visible = _carrying and not _dead
		&"death_glow_off":
			_sack_forced = false
			_sack.visible = false   # the gameplay LootSack takes over where the thief falls


func _burst() -> void:
	if _puff and _puff.is_inside_tree():
		_puff.global_position = global_position + Vector3(0, 0.55, 0)
		_puff.restart()


func _is_full() -> bool:
	return _dead or _action != &"" or _hit_t < HIT_LEN or _level_t < LEVEL_LEN or _walk_w > 0.0 \
		or _speed >= 0.3 or _force_write or _flash_v != 0.0


func _extra_process(dt: float) -> void:
	if _face:
		_face.auto(self)
	var full := _is_full()
	if _dead:
		var g := _k3(_death_t, 0.0, 0.2, 0.3, 0.6, 1.0, 1.0)
		rot(P_HEAD, Vector3(-20.0 * DEG * g, 0.0, 12.0 * DEG * g))
		rot(P_ARM_L, Vector3(-50.0 * DEG * g, 0.0, -35.0 * DEG * g))
	# Idle fidget (close camera only): a low peek, every 7-13 s.
	if not _dead and _tier == 0 and _action == &"" and _speed < 0.3 and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN:
		_idle_left -= dt
		if _idle_left <= 0.0:
			_idle_left = 7.0 + 6.0 * fmod(_phase_off * 7.3 + _fidget_next * 0.37, 1.0)
			_fidget_next += 1.0
			play_cast(&"idle_peek")
	elif _action != &"" or _speed >= 0.3:
		_idle_left = maxf(_idle_left, 3.0)
	if _sack_forced and _sack and not _sack.visible:
		_sack.visible = true
	_secondary(dt, full)
	_drive_eyes()
	_eye_k = 1.0
	if not _sack_forced:
		_sack_off = Vector3.ZERO
		_sack_scale = 1.0


## Tail cloak and loot sack: damped springs driven by the walk, lunges (root speed), chest twists and hits.
func _secondary(dt: float, full: bool) -> void:
	if _tail == null or _sack == null:
		return
	var tt := Vector2.ZERO
	var st := Vector3.ZERO
	if full and dt > 0.0:
		var rz := _off_pos[P_ROOT].z
		var vz := (rz - _prev_root_z) / dt
		_prev_root_z = rz
		var yaw := _off_rot[P_CHEST].y
		var vyaw := (yaw - _prev_yaw) / dt
		_prev_yaw = yaw
		var p := TAU * _walk_p
		tt.x = _walk_w * ((30.0 if _fleeing else 12.0) + 6.0 * sin(2.0 * p)) * DEG + clampf(vz * 0.5, -0.5, 0.9) \
			- 0.5 * _off_rot[P_CHEST].x
		tt.y = _walk_w * 6.0 * DEG * sin(p) - clampf(vyaw * 0.06, -0.5, 0.5)
		st.x = clampf(vz * 0.45, -0.4, 0.7)
		st.y = -0.03 * absf(sin(p)) * _walk_w
		st.z = -_walk_w * 8.0 * DEG * sin(p) - clampf(vyaw * 0.04, -0.3, 0.3)
		if _dead:
			tt.x -= 1.1 * clampf((_death_t - 0.2) / 0.4, 0.0, 1.0)   # folds in under the falling body
	else:
		_prev_root_z = _off_pos[P_ROOT].z if full else 0.0
		_prev_yaw = _off_rot[P_CHEST].y if full else 0.0
		# The lurking tail flick (a magpie cocks its tail now and then).
		if _tier == 0:
			var ft := fposmod(_t + _phase_off * 5.0, 4.3)
			tt.x = 16.0 * DEG * _k3(ft, 0.0, 0.12, 0.25, 0.7, 1.0, 1.0)
	var h := minf(dt, 0.05)
	var steps := 1 if h <= 0.02 else 2
	var sdt := h / float(steps)
	for _s: int in steps:
		_tail_v += ((tt - _tail_a) * 110.0 - _tail_v * 10.0) * sdt
		_tail_a += _tail_v * sdt
		_sack_v += ((st - _sack_a) * Vector3(80.0, 140.0, 80.0) - _sack_v * Vector3(7.0, 10.0, 7.0)) * sdt
		_sack_a += _sack_v * sdt
	if _tail_a.distance_squared_to(_tail_written) > 0.000004:
		_tail_written = _tail_a
		_tail.rotation = Vector3(_tail_a.x, 0.0, _tail_a.y)
	if not _sack.visible:
		return
	if _sack_a.distance_squared_to(_sack_written) > 0.000004 or _sack_off != _sack_off_written \
			or _sack_scale != _sack_scale_written:
		_sack_written = _sack_a
		_sack_off_written = _sack_off
		_sack_scale_written = _sack_scale
		_sack.rotation = Vector3(_sack_a.x, 0.0, _sack_a.z)
		_sack.position = _sack_rest + Vector3(0.0, _sack_a.y, 0.0) + _sack_off
		_sack.scale = Vector3.ONE * _sack_scale


## The eye shine (merged Head): veterancy / haste x the snatch / attack / peek flares, 0 when dead.
func _drive_eyes() -> void:
	var e := glow_level() * _eye_k
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
	_eye_written = -1.0
	_sack_forced = false
	_sack_off = Vector3.ZERO
	_sack_scale = 1.0
	_sack_off_written = Vector3.ZERO
	_sack_scale_written = 1.0
	_fleeing = false
	if _sack:
		_sack.visible = _carrying
		_sack.position = _sack_rest
		_sack.rotation = Vector3.ZERO
		_sack.scale = Vector3.ONE
	_drive_eyes()
