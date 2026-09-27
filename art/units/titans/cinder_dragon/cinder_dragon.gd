class_name CinderDragonModel
extends FlyerModel
## The Cinder Dragon, Fire's tier-3 titan (cavalry-mounts.md 5 / 10 row 13.V13; task 13.V13). Rig and hooks:
## flyer_model.gd. All geometry is built in code once per game (static cache) in MODEL space.
## Look: black scales with a deep red belly, glowing lava seams (along each flank, between the belly plates, cracks
## on the back, the lip line), a long S-necked head with a horned crown (two great swept-back horns + rear, cheek,
## brow and nose horns, a beard of chin spikes), glowing slit eyes, a row of dorsal spines from the skull to the tail,
## HUGE wings (span 7.0 m = the 40 m read) whose membranes take the kingdom colour with scorched, smouldering
## trailing edges and glowing veins along the fingers, a hooked thumb claw and elbow spike on each wing, 4 legs tucked
## (claws), and a tail ending in a burning flame spade (hot core) that sheds embers.
## Budget: 16 pivot meshes + ground blob = 17 authored meshes, 19 draw instances with the 2 particle systems
## (spade embers, looping, stopped beyond 45 m; crash embers, one shot), 0 lights, 5 materials (this folder) + the kit
## blob. Shadows: the big parts only (body, the 4 wing parts, neck, head, tail 1-2).

const MAT_PATH := "res://art/units/titans/cinder_dragon/cinder_"

# ---- anatomy, model space (feet origin, body centre at BAKE_HEIGHT), right side (x > 0); the left mirrors x
const SHOULDER := Vector3(0.42, 4.38, 0.50)
const ELBOW := Vector3(1.30, 4.56, -0.06)
const WRIST := Vector3(2.12, 4.72, 0.42)
const HIP_ATTACH := Vector3(0.34, 4.10, -1.15)
const FINGER_T := Vector3(1.30, 4.30, -1.95)
const FINGER_1 := Vector3(3.52, 5.02, -0.44)
const FINGER_2 := Vector3(3.16, 4.78, -1.44)
const FINGER_3 := Vector3(2.38, 4.52, -2.04)
const MOUTH := Vector3(0.0, 4.87, 3.25)
## The head and jaw are built at 1:1 then scaled up about the Head pivot (chunky style: a big readable head).
const HEAD_PIVOT := Vector3(0.0, 5.02, 2.18)
const HEAD_SCALE := 1.25
const SPADE_AT := Vector3(0.0, 3.755, -4.02)

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}

var _spade_fx: GPUParticles3D
var _crash_fx: GPUParticles3D


## One surface under construction (model-space vertices).
class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var c := PackedColorArray()
	var i := PackedInt32Array()


static func _mat(nm: String) -> Material:
	if not _mats.has(nm):
		_mats[nm] = load(MAT_PATH + nm + ".tres")
	return _mats[nm]


# ================================================================ parts

func _build_parts() -> void:
	for side: int in 2:
		var sx := -1.0 if side == 0 else 1.0
		wing_axis[side] = (_mx(HIP_ATTACH, sx) - _mx(SHOULDER, sx)).normalized()
		hand_axis[side] = (_mx(FINGER_T, sx) - _mx(WRIST, sx)).normalized()
	add_pivot_mesh(P_BODY, _body_mesh(), true, "BodyMesh")
	add_pivot_mesh(P_NECK1, _neck1_mesh(), true, "Neck1Mesh")
	add_pivot_mesh(P_NECK2, _neck2_mesh(), true, "Neck2Mesh")
	add_pivot_mesh(P_HEAD, _head_mesh(), true, "HeadMesh")
	add_pivot_mesh(P_JAW, _jaw_mesh(), false, "JawMesh")
	add_pivot_mesh(P_WING_L, _wing_arm_mesh(-1.0), true, "WingLMesh")
	add_pivot_mesh(P_WING_L2, _wing_hand_mesh(-1.0), true, "WingL2Mesh")
	add_pivot_mesh(P_WING_R, _wing_arm_mesh(1.0), true, "WingRMesh")
	add_pivot_mesh(P_WING_R2, _wing_hand_mesh(1.0), true, "WingR2Mesh")
	add_pivot_mesh(P_TAIL1, _tail_mesh(1), true, "Tail1Mesh")
	add_pivot_mesh(P_TAIL2, _tail_mesh(2), true, "Tail2Mesh")
	add_pivot_mesh(P_TAIL3, _tail_mesh(3), false, "Tail3Mesh")
	add_pivot_mesh(P_LEG_FL, _front_leg_mesh(-1.0), false, "LegFLMesh")
	add_pivot_mesh(P_LEG_FR, _front_leg_mesh(1.0), false, "LegFRMesh")
	add_pivot_mesh(P_LEG_BL, _hind_leg_mesh(-1.0), false, "LegBLMesh")
	add_pivot_mesh(P_LEG_BR, _hind_leg_mesh(1.0), false, "LegBRMesh")
	var mouth := Node3D.new()
	mouth.name = "Mouth"
	add_pivot_node(P_HEAD, mouth, MOUTH)
	_mouth = mouth
	# Embers shed by the flame spade (world space: they trail behind in flight). Loop fx stop beyond 45 m.
	_spade_fx = CharacterModel.make_motes(Color(1.0, 0.52, 0.16), 10, 1.0, 0.32, 1.0, 0.17)
	_spade_fx.name = "SpadeEmbers"
	_spade_fx.visibility_aabb = AABB(Vector3(-3.0, -2.0, -3.0), Vector3(6.0, 5.0, 6.0))
	add_pivot_node(P_TAIL3, _spade_fx, SPADE_AT + Vector3(0.0, 0.05, -0.42))
	# The fire goes out at the crash: a one-shot burst of embers from the body.
	_crash_fx = CharacterModel.make_motes(Color(1.0, 0.45, 0.12), 26, 1.1, 1.3, 3.2, 0.24, false, true)
	_crash_fx.name = "CrashEmbers"
	_crash_fx.visibility_aabb = AABB(Vector3(-4.0, -3.0, -4.0), Vector3(8.0, 8.0, 8.0))
	add_pivot_node(P_BODY, _crash_fx, Vector3(0.0, BAKE_HEIGHT, 0.0))
	ensure_shadow_blob(Vector2(3.3, 3.9), Color(0.05, 0.03, 0.02, 0.42))


func _after_ready() -> void:
	_spade_fx.emitting = _tier == 0


func _on_revive() -> void:
	if _spade_fx:
		_spade_fx.emitting = _tier == 0


func _on_action_event(ev: StringName) -> void:
	if ev == &"crash" and _spade_fx:
		_spade_fx.emitting = false


# ================================================================ builders (static, cached per game)

static func _mx(p: Vector3, sx: float) -> Vector3:
	return Vector3(p.x * sx, p.y, p.z)


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


## Rows [v, a, b, c, d] -> Vector4 at v (smooth between rows).
static func _table(tab: Array, v: float) -> Vector4:
	var r0: Array = tab[0]
	if v <= float(r0[0]):
		return Vector4(r0[1], r0[2], r0[3], r0[4])
	for k: int in range(1, tab.size()):
		var r1: Array = tab[k]
		if v <= float(r1[0]):
			var a := (v - float(r0[0])) / maxf(float(r1[0]) - float(r0[0]), 0.0001)
			a = a * a * (3.0 - 2.0 * a)
			return Vector4(lerpf(r0[1], r1[1], a), lerpf(r0[2], r1[2], a), lerpf(r0[3], r1[3], a), lerpf(r0[4], r1[4], a))
		r0 = r1
	return Vector4(r0[1], r0[2], r0[3], r0[4])


static func _quad(s: Surf, a: int, b: int, c: int, d: int) -> void:
	var fnn := (s.v[d] - s.v[a]).cross(s.v[b] - s.v[a])
	if fnn.length_squared() < 1e-14:
		fnn = (s.v[c] - s.v[b]).cross(s.v[d] - s.v[b])
	if fnn.dot(s.n[a] + s.n[b] + s.n[c] + s.n[d]) >= 0.0:
		s.i.append_array(PackedInt32Array([a, b, d, b, c, d]))
	else:
		s.i.append_array(PackedInt32Array([a, d, b, b, d, c]))


## A flat triangle facing `nrm`.
static func _tri(s: Surf, a: Vector3, b: Vector3, c: Vector3, nrm: Vector3, col: Color) -> void:
	var k := s.v.size()
	for p: Vector3 in [a, b, c]:
		s.v.append(p)
		s.n.append(nrm)
		s.uv.append(Vector2(p.x, p.z))
		s.c.append(col)
	if (c - a).cross(b - a).dot(nrm) >= 0.0:
		s.i.append_array(PackedInt32Array([k, k + 1, k + 2]))
	else:
		s.i.append_array(PackedInt32Array([k, k + 2, k + 1]))


## Grid p = fn(u, v), u over cols, v over rows. Normals by finite differences, turned away from ctr(u, v).
static func _grid(s: Surf, fn: Callable, ctr: Callable, col: Callable, uvf: Callable, cols: int, rows: int) -> void:
	var base := s.v.size()
	const E := 0.002
	for j: int in rows + 1:
		var v := float(j) / float(rows)
		for i: int in cols + 1:
			var u := float(i) / float(cols)
			var p: Vector3 = fn.call(u, v)
			var du: Vector3 = (fn.call(minf(u + E, 1.0), v) as Vector3) - (fn.call(maxf(u - E, 0.0), v) as Vector3)
			var dv: Vector3 = (fn.call(u, minf(v + E, 1.0)) as Vector3) - (fn.call(u, maxf(v - E, 0.0)) as Vector3)
			var nn := dv.cross(du)
			var o: Vector3 = p - (ctr.call(u, v) as Vector3)
			if nn.length_squared() < 1e-12:
				nn = o
			if nn.length_squared() < 1e-12:
				nn = dv if v > 0.5 else -dv
			nn = nn.normalized()
			if nn.dot(o) < 0.0:
				nn = -nn
			s.v.append(p)
			s.n.append(nn)
			s.uv.append(uvf.call(u, v))
			s.c.append(col.call(u, v))
	for j: int in rows:
		for i: int in cols:
			var q0 := base + j * (cols + 1) + i
			_quad(s, q0, q0 + 1, q0 + cols + 2, q0 + cols + 1)


## Tube along a Catmull-Rom spine. prof(v) -> Vector4(side radius, top radius, bottom radius, dorsal ridge).
## u = 0 is the top (UV.x = u), UV.y = metres along. col(cos_around, v) -> Color.
static func _loft(s: Surf, pts: Array[Vector3], prof: Callable, col: Callable, ring: int, samples: int,
		up_ref: Vector3 = Vector3.UP) -> void:
	var total := 0.0
	for k: int in pts.size() - 1:
		total += pts[k].distance_to(pts[k + 1])
	var frame := func(v: float) -> Array:
		var tn := (_cr(pts, minf(v + 0.01, 1.0)) - _cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var x := up_ref.cross(tn)
		if x.length_squared() < 1e-6:
			x = Vector3.RIGHT
		x = x.normalized()
		return [x, tn.cross(x).normalized()]
	var fn := func(u: float, v: float) -> Vector3:
		var fr: Array = frame.call(v)
		var pr: Vector4 = prof.call(v)
		var a := TAU * u
		var ca := cos(a)
		var ry := pr.y if ca >= 0.0 else pr.z
		var up := ry * ca + pr.w * pow(maxf(ca, 0.0), 10.0)
		return _cr(pts, v) + (fr[0] as Vector3) * (pr.x * sin(a)) + (fr[1] as Vector3) * up
	var ctr := func(_u: float, v: float) -> Vector3:
		return _cr(pts, v)
	var colf := func(u: float, v: float) -> Color:
		return col.call(cos(TAU * u), v)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u, v * total)
	_grid(s, fn, ctr, colf, uvf, ring, samples)


## Tapered round horn / claw / spike along pts (r0 at the base, r1 at the tip). Colour: horn material gradient
## (g 0 = dark base -> 1 = pale tip), from `pale_from` along the horn.
static func _horn(s: Surf, pts: Array[Vector3], r0: float, r1: float, pale_from: float = 0.35, ring: int = 7,
		samples: int = 7, flat: float = 1.0) -> void:
	var up := Vector3.UP
	var d := (pts[pts.size() - 1] - pts[0]).normalized()
	if absf(d.y) > 0.8:
		up = Vector3.FORWARD
	var prof := func(v: float) -> Vector4:
		var r := lerpf(r0, r1, pow(v, 0.85)) + 0.003
		return Vector4(r * flat, r, r, 0.0)
	var col := func(_ca: float, v: float) -> Color:
		return Color(0.0, smoothstep(pale_from, 1.0, v), 0.0, 0.0)
	_loft(s, pts, prof, col, ring, samples, up)


## Lumpy ellipsoid at c (radii r, rotated by b), colour col(u, v).
static func _blob(s: Surf, c: Vector3, r: Vector3, col: Color, b: Basis = Basis.IDENTITY, lump: float = 0.03,
		cols: int = 10, rows: int = 6) -> void:
	var fn := func(u: float, v: float) -> Vector3:
		var a := TAU * u
		var th := PI * v
		var k := 1.0 + lump * sin(5.0 * a + 1.3) * sin(3.0 * th + 0.4)
		return c + b * Vector3(sin(th) * sin(a) * r.x * k, cos(th) * r.y * k, sin(th) * cos(a) * r.z * k)
	var ctr := func(_u: float, _v: float) -> Vector3:
		return c
	var colf := func(_u: float, _v: float) -> Color:
		return col
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u, v)
	_grid(s, fn, ctr, colf, uvf, cols, rows)


## Dorsal spine: a flattened curved fin rising from `base` (tilted back), height h, base length len.
static func _spine(s: Surf, base: Vector3, h: float, blen: float, tilt_deg: float = 38.0) -> void:
	var t := tilt_deg * DEG
	var dir := Vector3(0.0, cos(t), -sin(t))
	var pts: Array[Vector3] = [base - dir * 0.05, base + dir * h * 0.5 + Vector3(0, 0, -0.03 * h), base + dir * h
		+ Vector3(0, -0.06 * h, -0.12 * h)]
	var prof := func(v: float) -> Vector4:
		var w := 1.0 - v
		return Vector4(0.05 * w + 0.004, blen * 0.5 * pow(w, 0.8) + 0.004, blen * 0.5 * pow(w, 0.8) + 0.004, 0.0)
	var col := func(_ca: float, v: float) -> Color:
		return Color(0.0, smoothstep(0.45, 1.0, v) * 0.85, 0.0, 0.0)
	_loft(s, pts, prof, col, 6, 5, Vector3.FORWARD)


## Spines along a loft's top: at spline params vs, heights hs.
static func _spine_row(s: Surf, pts: Array[Vector3], prof: Callable, vs: Array, hs: Array, blen: float) -> void:
	for k: int in vs.size():
		var v: float = vs[k]
		var tn := (_cr(pts, minf(v + 0.01, 1.0)) - _cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var x := Vector3.UP.cross(tn).normalized()
		var up := tn.cross(x).normalized()
		var pr: Vector4 = prof.call(v)
		var base := _cr(pts, v) + up * (pr.y + pr.w - 0.05)
		_spine(s, base, float(hs[k]), blen)


## Uniform scale of a surface about c (normals unchanged).
static func _scale_surf(s: Surf, c: Vector3, k: float) -> void:
	for j: int in s.v.size():
		s.v[j] = c + (s.v[j] - c) * k


static func _bake(key: String, groups: Array) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	for g: Array in groups:
		var s: Surf = g[0]
		if s.v.is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = s.v
		arr[Mesh.ARRAY_NORMAL] = s.n
		arr[Mesh.ARRAY_TEX_UV] = s.uv
		arr[Mesh.ARRAY_COLOR] = s.c
		arr[Mesh.ARRAY_INDEX] = s.i
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		am.surface_set_material(am.get_surface_count() - 1, _mat(String(g[1])))
	_meshes[key] = am
	return am


# ---- colour helpers (dragon_scale.gdshader COLOR: r lava, g belly / pale, b lofted, a explicit glow)

static func _belly(ca: float) -> float:
	return smoothstep(-0.18, -0.58, ca)


## Round tapered profile for _loft (flat > 1 widens it sideways).
static func _round(r0: float, r1: float, flat: float = 1.0) -> Callable:
	return func(v: float) -> Vector4:
		var r := lerpf(r0, r1, v)
		return Vector4(r * flat, r, r, 0.0)


static func _scaled(lava: float) -> Callable:
	return func(ca: float, _v: float) -> Color:
		return Color(lava, _belly(ca), 1.0, 0.0)


# ================================================================ meshes

## Body: a deep-keeled chest, narrow waist, hips; shoulder bulges at the wing roots, thighs; 7 dorsal spines.
static func _body_mesh() -> ArrayMesh:
	if _meshes.has("body"):
		return _meshes["body"]
	var sc := Surf.new()
	var hn := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.42, 1.36), Vector3(0, 4.25, 0.92), Vector3(0, 4.10, 0.35),
		Vector3(0, 4.02, -0.35), Vector3(0, 3.99, -1.0), Vector3(0, 3.96, -1.45), Vector3(0, 3.95, -1.68)]
	var tab := [[0.0, 0.40, 0.36, 0.40, 0.0], [0.15, 0.58, 0.47, 0.58, 0.06], [0.33, 0.66, 0.45, 0.76, 0.08],
		[0.55, 0.52, 0.39, 0.53, 0.07], [0.78, 0.53, 0.41, 0.45, 0.06], [1.0, 0.35, 0.32, 0.32, 0.03]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	_loft(sc, pts, prof, _scaled(1.0), 24, 26)
	for sx: float in [-1.0, 1.0]:
		_blob(sc, Vector3(0.40 * sx, 4.30, 0.46), Vector3(0.25, 0.25, 0.38), Color(0.7, 0.0, 0.0, 0.0),
			Basis(Vector3.FORWARD, 0.25 * sx), 0.04)
		_blob(sc, Vector3(0.33 * sx, 3.80, -0.95), Vector3(0.22, 0.27, 0.33), Color(0.7, 0.25, 0.0, 0.0),
			Basis.IDENTITY, 0.04)
	_spine_row(hn, pts, prof, [0.06, 0.2, 0.34, 0.48, 0.62, 0.76, 0.9], [0.30, 0.38, 0.42, 0.38, 0.33, 0.28, 0.22], 0.30)
	return _bake("body", [[sc, "scale"], [hn, "horn"]])


static func _neck1_mesh() -> ArrayMesh:
	if _meshes.has("neck1"):
		return _meshes["neck1"]
	var sc := Surf.new()
	var hn := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.16, 0.72), Vector3(0, 4.32, 1.14), Vector3(0, 4.52, 1.45),
		Vector3(0, 4.72, 1.74)]
	var tab := [[0.0, 0.47, 0.41, 0.47, 0.05], [0.5, 0.39, 0.34, 0.40, 0.04], [1.0, 0.32, 0.29, 0.33, 0.03]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	_loft(sc, pts, prof, _scaled(0.95), 18, 10)
	_spine_row(hn, pts, prof, [0.3, 0.62, 0.92], [0.24, 0.24, 0.22], 0.24)
	return _bake("neck1", [[sc, "scale"], [hn, "horn"]])


static func _neck2_mesh() -> ArrayMesh:
	if _meshes.has("neck2"):
		return _meshes["neck2"]
	var sc := Surf.new()
	var hn := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.55, 1.52), Vector3(0, 4.80, 1.84), Vector3(0, 4.98, 2.10),
		Vector3(0, 5.06, 2.30)]
	var tab := [[0.0, 0.33, 0.30, 0.34, 0.03], [0.6, 0.28, 0.26, 0.29, 0.03], [1.0, 0.25, 0.23, 0.24, 0.02]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	_loft(sc, pts, prof, _scaled(0.9), 18, 10)
	_spine_row(hn, pts, prof, [0.25, 0.6], [0.21, 0.19], 0.2)
	return _bake("neck2", [[sc, "scale"], [hn, "horn"]])


## Head (upper skull + upper jaw): brow ridges, glowing slit eyes and nostrils, a glowing lip line, upper teeth and
## fangs, the glowing palate (seen when the jaw opens) and the horned crown.
static func _head_mesh() -> ArrayMesh:
	if _meshes.has("head"):
		return _meshes["head"]
	var sc := Surf.new()
	var hn := Surf.new()
	var lv := Surf.new()
	var fl := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 5.07, 2.00), Vector3(0, 5.08, 2.25), Vector3(0, 5.05, 2.55),
		Vector3(0, 5.00, 2.85), Vector3(0, 4.97, 3.10)]
	var tab := [[0.0, 0.17, 0.13, 0.12, 0.0], [0.12, 0.25, 0.19, 0.15, 0.02], [0.28, 0.27, 0.20, 0.15, 0.02],
		[0.48, 0.23, 0.165, 0.125, 0.015], [0.72, 0.165, 0.12, 0.10, 0.01], [0.92, 0.125, 0.095, 0.085, 0.0],
		[1.0, 0.03, 0.025, 0.025, 0.0]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	var col := func(ca: float, v: float) -> Color:
		var lip := exp(-pow((ca + 0.93) / 0.09, 2.0)) * smoothstep(0.15, 0.3, v) * (1.0 - smoothstep(0.9, 1.0, v))
		return Color(0.55, smoothstep(-0.55, -0.85, ca) * 0.8, 1.0, 0.85 * lip)
	_loft(sc, pts, prof, col, 22, 16)
	for sx: float in [-1.0, 1.0]:
		# heavy brow ridge (angry slant) and a cheek plate
		_blob(sc, Vector3(0.165 * sx, 5.19, 2.50), Vector3(0.10, 0.065, 0.19), Color(0.3, 0.0, 0.0, 0.0),
			Basis(Vector3.FORWARD, -0.35 * sx) * Basis(Vector3.RIGHT, 0.12))
		_blob(sc, Vector3(0.235 * sx, 5.02, 2.33), Vector3(0.07, 0.10, 0.17), Color(0.3, 0.2, 0.0, 0.0))
		# slit eyes (glow) and nostrils (lava)
		_blob(fl, Vector3(0.212 * sx, 5.105, 2.585), Vector3(0.045, 0.034, 0.10), Color.WHITE,
			Basis(Vector3.UP, 0.35 * sx) * Basis(Vector3.FORWARD, -0.25 * sx), 0.0, 8, 4)
		_blob(lv, Vector3(0.068 * sx, 5.035, 3.03), Vector3(0.036, 0.03, 0.04), Color.WHITE, Basis.IDENTITY, 0.0, 6, 3)
		# the horned crown: two great swept-back horns, rear horns, cheek horns, brow horns
		_horn(hn, [Vector3(0.13 * sx, 5.15, 2.32), Vector3(0.26 * sx, 5.30, 2.03), Vector3(0.37 * sx, 5.47, 1.73),
			Vector3(0.43 * sx, 5.67, 1.43), Vector3(0.41 * sx, 5.88, 1.20)], 0.115, 0.012, 0.3, 8, 9)
		_horn(hn, [Vector3(0.06 * sx, 5.17, 2.14), Vector3(0.11 * sx, 5.36, 1.93), Vector3(0.14 * sx, 5.52, 1.74)],
			0.07, 0.01)
		_horn(hn, [Vector3(0.24 * sx, 5.02, 2.24), Vector3(0.42 * sx, 5.00, 2.04), Vector3(0.57 * sx, 5.06, 1.85),
			Vector3(0.64 * sx, 5.15, 1.70)], 0.075, 0.01)
		_horn(hn, [Vector3(0.18 * sx, 5.21, 2.46), Vector3(0.22 * sx, 5.35, 2.37), Vector3(0.25 * sx, 5.46, 2.26)],
			0.05, 0.008)
		# upper teeth along the lip, a big fang at the front
		for k: int in 5:
			var v: float = 0.34 + 0.13 * float(k)
			var c := _cr(pts, v)
			var pr: Vector4 = prof.call(v)
			var base := c + Vector3(0.62 * pr.x * sx, -0.78 * pr.z, 0.0)
			var ln := 0.07 if k < 4 else 0.13
			_horn(hn, [base + Vector3(0, 0.02, 0), base + Vector3(0, -ln, 0.015)], 0.028 if k < 4 else 0.04, 0.004,
				0.0, 5, 2)
	_horn(hn, [Vector3(0, 5.06, 2.87), Vector3(0, 5.17, 2.85), Vector3(0, 5.27, 2.78)], 0.055, 0.008)
	_blob(lv, Vector3(0.0, 4.945, 2.62), Vector3(0.13, 0.022, 0.30), Color.WHITE, Basis.IDENTITY, 0.0, 8, 4)
	for s: Surf in [sc, hn, lv, fl]:
		_scale_surf(s, HEAD_PIVOT, HEAD_SCALE)
	return _bake("head", [[sc, "scale"], [hn, "horn"], [lv, "lava"], [fl, "flame"]])


## Lower jaw: glowing tongue / throat, lower teeth, a beard of chin spikes.
static func _jaw_mesh() -> ArrayMesh:
	if _meshes.has("jaw"):
		return _meshes["jaw"]
	var sc := Surf.new()
	var hn := Surf.new()
	var lv := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.905, 2.12), Vector3(0, 4.875, 2.42), Vector3(0, 4.86, 2.72),
		Vector3(0, 4.865, 3.02)]
	var tab := [[0.0, 0.17, 0.035, 0.10, 0.0], [0.4, 0.19, 0.04, 0.105, 0.0], [0.8, 0.13, 0.035, 0.075, 0.0],
		[1.0, 0.04, 0.015, 0.03, 0.0]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	var col := func(ca: float, _v: float) -> Color:
		return Color(0.5, smoothstep(-0.2, -0.7, ca), 1.0, 0.0)
	_loft(sc, pts, prof, col, 16, 10)
	_blob(lv, Vector3(0.0, 4.893, 2.55), Vector3(0.12, 0.02, 0.30), Color.WHITE, Basis.IDENTITY, 0.0, 8, 4)
	for sx: float in [-1.0, 1.0]:
		for k: int in 4:
			var v: float = 0.3 + 0.16 * float(k)
			var c := _cr(pts, v)
			var pr: Vector4 = prof.call(v)
			var base := c + Vector3(0.66 * pr.x * sx, 0.6 * pr.y, 0.0)
			var ln := 0.06 if k < 3 else 0.10
			_horn(hn, [base + Vector3(0, -0.02, 0), base + Vector3(0, ln, 0.01)], 0.025 if k < 3 else 0.035, 0.004,
				0.0, 5, 2)
		_horn(hn, [Vector3(0.11 * sx, 4.80, 2.60), Vector3(0.15 * sx, 4.70, 2.50), Vector3(0.17 * sx, 4.60, 2.40)],
			0.045, 0.008)
	_horn(hn, [Vector3(0, 4.79, 2.78), Vector3(0, 4.68, 2.70), Vector3(0, 4.57, 2.60)], 0.055, 0.008)
	for s: Surf in [sc, hn, lv]:
		_scale_surf(s, HEAD_PIVOT, HEAD_SCALE)
	return _bake("jaw", [[sc, "scale"], [hn, "horn"], [lv, "lava"]])


## Arm segment of a wing (the WingX pivot, hinged on the flank): humerus + forearm (elbow spike), the last finger
## (wrist -> T, the hand hinge), and the inner membrane (shoulder -> wrist leading edge, hip -> T scalloped).
static func _wing_arm_mesh(sx: float) -> ArrayMesh:
	var key := "wing_arm%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var sc := Surf.new()
	var hn := Surf.new()
	var mb := Surf.new()
	var s := _mx(SHOULDER, sx)
	var e := _mx(ELBOW, sx)
	var w := _mx(WRIST, sx)
	var h := _mx(HIP_ATTACH, sx)
	var t := _mx(FINGER_T, sx)
	var bone := func(ca: float, _v: float) -> Color:
		return Color(0.6, _belly(ca) * 0.6, 1.0, 0.4 * exp(-pow((ca - 1.0) / 0.16, 2.0)))
	_loft(sc, [s + Vector3(-0.06 * sx, 0.0, 0.03), e.lerp(s, 0.5) + Vector3(0, 0.05, 0.02), e], _round(0.16, 0.11),
		bone, 8, 7)
	_loft(sc, [e, e.lerp(w, 0.5) + Vector3(0, 0.03, 0.03), w], _round(0.11, 0.085), bone, 8, 7)
	_loft(sc, [w, w.lerp(t, 0.5) + Vector3(0.05 * sx, 0.02, 0.0), t], _round(0.075, 0.035), bone, 6, 8)
	_blob(sc, e, Vector3(0.12, 0.11, 0.12), Color(0.6, 0.0, 0.0, 0.0))
	_blob(sc, s, Vector3(0.18, 0.16, 0.2), Color(0.6, 0.0, 0.0, 0.0))
	_horn(hn, [e + Vector3(0.02 * sx, 0.04, -0.06), e + Vector3(0.08 * sx, 0.10, -0.26), e + Vector3(0.10 * sx, 0.10, -0.40)],
		0.065, 0.01)
	_horn(hn, [t + Vector3(0, 0, 0.03), t + (t - w).normalized() * 0.14 + Vector3(0, -0.03, 0)], 0.03, 0.006, 0.2, 5, 3)
	# inner membrane: u from the body (0) to the hand hinge line (1), v from the leading edge (0) to the trailing (1)
	var lead := func(u: float) -> Vector3:
		return s.lerp(w, u) + Vector3(0.0, 0.04 * sin(PI * u), 0.10 * sin(PI * u))
	var trail := func(u: float) -> Vector3:
		var b := h.lerp(t, u)
		return b + ((lead.call(u) as Vector3) - b) * 0.24 * sin(PI * u)
	var fn := func(u: float, v: float) -> Vector3:
		var p: Vector3 = (lead.call(u) as Vector3).lerp(trail.call(u) as Vector3, v)
		return p + Vector3(0.0, -0.10 * sin(PI * u) * sin(PI * v), 0.0)
	var ctr := func(u: float, v: float) -> Vector3:
		return (fn.call(u, v) as Vector3) - Vector3.UP
	var col := func(u: float, v: float) -> Color:
		var mid := clampf(minf(minf(u, 1.0 - u) * 5.0, v * 4.0), 0.0, 1.0)
		return Color(mid, v, smoothstep(0.7, 1.0, v) * smoothstep(0.02, 0.12, u) * smoothstep(0.02, 0.1, 1.0 - u), 0.0)
	var span := s.distance_to(w)
	var chord := s.distance_to(h)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * span, v * chord)
	_grid(mb, fn, ctr, col, uvf, 12, 8)
	return _bake(key, [[sc, "scale"], [hn, "horn"], [mb, "membrane"]])


## Hand segment of a wing (WingX2 pivot at the wrist, hinged on the last finger): three finger bones with tip claws,
## the hooked thumb claw, three membrane panels (fans from the wrist, scalloped trailing edges). The panel next to
## the last finger shares its edge exactly with the arm panel (wrist -> T).
static func _wing_hand_mesh(sx: float) -> ArrayMesh:
	var key := "wing_hand%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var sc := Surf.new()
	var hn := Surf.new()
	var mb := Surf.new()
	var w := _mx(WRIST, sx)
	var tips: Array[Vector3] = [_mx(FINGER_1, sx), _mx(FINGER_2, sx), _mx(FINGER_3, sx), _mx(FINGER_T, sx)]
	var radii: Array[float] = [0.085, 0.072, 0.066]
	var bone := func(ca: float, _v: float) -> Color:
		return Color(0.6, _belly(ca) * 0.6, 1.0, 0.4 * exp(-pow((ca - 1.0) / 0.16, 2.0)))
	for k: int in 3:
		var tip := tips[k]
		var mid := w.lerp(tip, 0.5) + Vector3(0.0, 0.05, 0.0) + (tips[k + 1] - tip).normalized() * 0.06
		_loft(sc, [w, mid, tip], _round(radii[k], 0.03), bone, 6, 9)
		var out := (tip - mid).normalized()
		_horn(hn, [tip - out * 0.04, tip + out * 0.16 + Vector3(0, 0.02, 0), tip + out * 0.26 + Vector3(0, -0.04, -0.06)],
			0.04, 0.006, 0.15, 5, 4)
	_blob(sc, w, Vector3(0.11, 0.10, 0.12), Color(0.6, 0.0, 0.0, 0.0))
	# the hooked thumb claw on the leading edge
	_horn(hn, [w + Vector3(0.02 * sx, 0.03, 0.04), w + Vector3(0.06 * sx, 0.10, 0.24), w + Vector3(0.08 * sx, 0.10, 0.42),
		w + Vector3(0.06 * sx, 0.02, 0.52)], 0.075, 0.008, 0.25, 7, 7)
	# membrane panels between consecutive fingers: u across (finger a -> finger b), v from the wrist to the edge
	var sags: Array[float] = [0.20, 0.23, 0.20]
	for k: int in 3:
		var a := tips[k]
		var b := tips[k + 1]
		var sag: float = sags[k]
		var edge := func(u: float) -> Vector3:
			var q := a.lerp(b, u)
			return q + (w - q) * sag * sin(PI * u)
		var la := a.distance_to(w)
		var fn := func(u: float, v: float) -> Vector3:
			var p: Vector3 = w + ((edge.call(u) as Vector3) - w) * v
			return p + Vector3(0.0, -0.05 * la * sin(PI * u) * sin(PI * v), 0.0)
		var ctr := func(u: float, v: float) -> Vector3:
			return (fn.call(u, v) as Vector3) - Vector3.UP
		var col := func(u: float, v: float) -> Color:
			var mid := clampf(minf(u, 1.0 - u) * 5.0, 0.0, 1.0) * smoothstep(0.0, 0.25, v)
			return Color(mid, v, smoothstep(0.7, 1.0, v) * smoothstep(0.02, 0.1, minf(u, 1.0 - u)), 0.0)
		var ab := a.distance_to(b)
		var uvf := func(u: float, v: float) -> Vector2:
			return Vector2(u * ab, v * la)
		_grid(mb, fn, ctr, col, uvf, 10, 9)
	return _bake(key, [[sc, "scale"], [hn, "horn"], [mb, "membrane"]])


## Tail segments; the last one ends in the flame spade (a horizontal flame blade with a hot core + a small vertical fin).
static func _tail_mesh(seg: int) -> ArrayMesh:
	var key := "tail%d" % seg
	if _meshes.has(key):
		return _meshes[key]
	var sc := Surf.new()
	var hn := Surf.new()
	var lv := Surf.new()
	var fl := Surf.new()
	var pts: Array[Vector3]
	var tab: Array
	var sv: Array
	var sh: Array
	match seg:
		1:
			pts = [Vector3(0, 3.98, -1.22), Vector3(0, 3.945, -1.80), Vector3(0, 3.89, -2.46)]
			tab = [[0.0, 0.37, 0.33, 0.33, 0.03], [1.0, 0.235, 0.215, 0.215, 0.02]]
			sv = [0.2, 0.55, 0.88]
			sh = [0.22, 0.2, 0.18]
		2:
			pts = [Vector3(0, 3.885, -2.26), Vector3(0, 3.84, -2.86), Vector3(0, 3.80, -3.42)]
			tab = [[0.0, 0.225, 0.205, 0.205, 0.02], [1.0, 0.135, 0.125, 0.125, 0.01]]
			sv = [0.25, 0.6, 0.92]
			sh = [0.17, 0.15, 0.13]
		_:
			pts = [Vector3(0, 3.80, -3.24), Vector3(0, 3.78, -3.68), Vector3(0, 3.76, -4.06)]
			tab = [[0.0, 0.14, 0.13, 0.13, 0.01], [0.85, 0.075, 0.07, 0.07, 0.0], [1.0, 0.04, 0.04, 0.04, 0.0]]
			sv = [0.3, 0.65]
			sh = [0.11, 0.09]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	_loft(sc, pts, prof, _scaled(0.9), 16, 10)
	_spine_row(hn, pts, prof, sv, sh, 0.16)
	if seg == 3:
		_spade(lv, SPADE_AT, 1.0, 0.075, false)
		_spade(fl, SPADE_AT + Vector3(0, 0.03, -0.06), 0.56, 0.06, false)
		_spade(lv, SPADE_AT + Vector3(0, 0.0, -0.02), 0.5, 0.05, true)
	return _bake(key, [[sc, "scale"], [hn, "horn"], [lv, "lava"], [fl, "flame"]])


## Spade outline (right half, x lateral, d backward), mirrored: a flame blade with side tongues and a long tip.
const SPADE_HALF: Array[Vector2] = [Vector2(0.0, -0.02), Vector2(0.10, 0.04), Vector2(0.26, 0.14), Vector2(0.40, 0.28),
	Vector2(0.46, 0.40), Vector2(0.42, 0.50), Vector2(0.58, 0.68), Vector2(0.30, 0.58), Vector2(0.26, 0.72),
	Vector2(0.36, 0.90), Vector2(0.13, 0.80), Vector2(0.0, 1.06)]


## A domed flame blade (thickness th) at `at`, scaled by k; vertical = the fin standing up / down (in the YZ plane).
static func _spade(s: Surf, at: Vector3, k: float, th: float, vertical: bool) -> void:
	var ring: Array[Vector2] = []
	for p: Vector2 in SPADE_HALF:
		ring.append(p)
	for idx: int in range(SPADE_HALF.size() - 2, 0, -1):
		ring.append(Vector2(-SPADE_HALF[idx].x, SPADE_HALF[idx].y))
	var centre := Vector2(0.0, 0.42)
	var to3 := func(p: Vector2, lift: float) -> Vector3:
		if vertical:
			return at + Vector3(lift, p.x * k, -p.y * k)
		return at + Vector3(p.x * k, lift, -p.y * k)
	var up := Vector3.RIGHT if vertical else Vector3.UP
	var col := Color.WHITE
	var n := ring.size()
	for i: int in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var ca: Vector3 = to3.call(centre, th)
		var cb: Vector3 = to3.call(centre, -th)
		_tri(s, ca, to3.call(a, 0.0), to3.call(b, 0.0), up, col)
		_tri(s, cb, to3.call(b, 0.0), to3.call(a, 0.0), -up, col)


static func _front_leg_mesh(sx: float) -> ArrayMesh:
	var key := "leg_f%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var sc := Surf.new()
	var hn := Surf.new()
	var sh := Vector3(0.36 * sx, 3.66, 0.58)
	var el := Vector3(0.43 * sx, 3.36, 0.30)
	var wr := Vector3(0.39 * sx, 3.30, 0.74)
	var col := _scaled(0.5)
	_loft(sc, [sh, sh.lerp(el, 0.5) + Vector3(0.02 * sx, 0, 0.02), el], _round(0.15, 0.10), col, 8, 6)
	_loft(sc, [el, el.lerp(wr, 0.5) + Vector3(0, -0.03, 0), wr], _round(0.10, 0.075), col, 8, 6)
	_blob(sc, el, Vector3(0.10, 0.10, 0.11), Color(0.5, 0.2, 0.0, 0.0))
	_blob(sc, wr + Vector3(0, -0.01, 0.06), Vector3(0.10, 0.065, 0.12), Color(0.4, 0.3, 0.0, 0.0))
	for k: int in 3:
		var ox := (float(k) - 1.0) * 0.065 * sx
		var b := wr + Vector3(ox, -0.02, 0.14)
		_horn(hn, [b, b + Vector3(ox * 0.3, -0.03, 0.10), b + Vector3(ox * 0.4, -0.10, 0.14)], 0.032, 0.005, 0.2, 5, 3)
	return _bake(key, [[sc, "scale"], [hn, "horn"]])


static func _hind_leg_mesh(sx: float) -> ArrayMesh:
	var key := "leg_b%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var sc := Surf.new()
	var hn := Surf.new()
	var hp := Vector3(0.36 * sx, 3.76, -0.92)
	var kn := Vector3(0.45 * sx, 3.42, -1.16)
	var an := Vector3(0.41 * sx, 3.50, -1.70)
	var ft := Vector3(0.40 * sx, 3.53, -1.94)
	var col := _scaled(0.5)
	_loft(sc, [hp, hp.lerp(kn, 0.5) + Vector3(0.03 * sx, 0, 0.03), kn], _round(0.22, 0.13), col, 8, 6)
	_loft(sc, [kn, kn.lerp(an, 0.5) + Vector3(0, -0.02, 0), an], _round(0.12, 0.08), col, 8, 6)
	_loft(sc, [an, an.lerp(ft, 0.5), ft], _round(0.08, 0.05, 1.3), col, 7, 4)
	_blob(sc, kn, Vector3(0.12, 0.12, 0.13), Color(0.5, 0.0, 0.0, 0.0))
	for k: int in 3:
		var ox := (float(k) - 1.0) * 0.06 * sx
		var b := ft + Vector3(ox, -0.01, -0.02)
		_horn(hn, [b, b + Vector3(ox * 0.3, -0.04, -0.10), b + Vector3(ox * 0.4, -0.11, -0.12)], 0.03, 0.005, 0.2, 5, 3)
	return _bake(key, [[sc, "scale"], [hn, "horn"]])
