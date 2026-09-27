extends RefCounted
## Frost Wyrm geometry (titans-2.md 7 / 11 row 13c.V8, task 13c.V8). Built in code once per game (static cache), in
## MODEL space, variant A proportions (B is the same geometry x1.15 by the rig, plus its crystal horns). REST POSE = a
## STRAIGHT serpent along -Z at BAKE_Y: bone 0 = the neck joint behind the skull (HEAD_Z), bone N_BONES-1 = the tail
## tip, DS apart; the rig (frost_wyrm.gd) bends it with a Skeleton3D. Loaded by frost_wyrm.gd with preload (no class_name).
## Parts:
##   body_mesh()      SKINNED: the long banded body (neck -> tail), the ragged ice-feather DORSAL FIN along its whole
##                    length, a small ventral blade under the tail and the ice-feather TAIL FLUKE (a four-lobed fan with
##                    a glowing crystal at the tip). Bones / weights from the rest z of each vertex (2 bones, linear).
##   head_mesh(v)     rigid (Head pivot): a long wedge skull, glowing eyes and lip line, fangs, the glowing palate and the
##                    FRILLED FIN CREST (a wide collar of ice-feather rays on each side + a crest fan on top = the read);
##                    v 1 adds the white-violet crystal horns of Old Hoarfang.
##   jaw_mesh()       rigid (Jaw pivot): lower jaw, glowing tongue, teeth, a small chin fin.
##   leg_mesh(sx)     rigid (LegFL / LegFR): the only legs, short clawed forelegs with an ice spur at the elbow.
##   fin_mesh(sx)     rigid (FinL / FinR): the pectoral ice-feather fans (1.1 m, NOT wings).
## Materials (materials/, A names; the rig swaps to the B set by surface override): wyrm_scale_a, wyrm_fin_a,
## wyrm_ice_a, wyrm_eye_a, wyrm_claw. Every mesh carries CUSTOM0 = rest position and CUSTOM1 = rest normal (the
## skinning-safe paint of wyrm_scale.gdshader).

const MAT_DIR := "res://art/units/neutral/beasts/frost_wyrm/materials/wyrm_"
const DEG := PI / 180.0

# ---- anatomy (model space, rest pose)
const BAKE_Y := 4.0
## z of bone 0 (the neck joint just behind the skull).
const HEAD_Z := 3.6
## Spine length, head joint -> tail tip (m).
const LEN := 12.5
const N_BONES := 25
const DS := LEN / 24.0
const CHEST_I := 5
const CHEST_S := DS * 5.0
const CHEST_Z := HEAD_Z - CHEST_S
const JAW_HINGE := Vector3(0.0, 3.87, 3.63)
const MOUTH := Vector3(0.0, 3.93, 4.95)
const SHOULDER := Vector3(0.34, 3.70, 1.15)
const FIN_ROOT := Vector3(0.40, 3.87, 0.76)
## Radius profile along the spine: rows [s, side, top, bottom, dorsal ridge].
const RAD := [[0.0, 0.33, 0.31, 0.30, 0.02], [0.8, 0.345, 0.32, 0.33, 0.03], [1.8, 0.40, 0.36, 0.40, 0.04],
	[2.6, 0.46, 0.41, 0.48, 0.05], [3.8, 0.47, 0.42, 0.46, 0.05], [5.6, 0.43, 0.39, 0.41, 0.04],
	[7.6, 0.34, 0.31, 0.32, 0.03], [9.6, 0.22, 0.21, 0.21, 0.02], [11.4, 0.11, 0.10, 0.10, 0.01],
	[12.5, 0.035, 0.035, 0.035, 0.0]]
## Dorsal fin height along the spine: rows [s, h, 0, 0, 0].
const CREST := [[0.05, 0.10, 0, 0, 0], [0.5, 0.46, 0, 0, 0], [1.4, 0.44, 0, 0, 0], [3.0, 0.40, 0, 0, 0],
	[6.0, 0.34, 0, 0, 0], [9.0, 0.25, 0, 0, 0], [10.7, 0.14, 0, 0, 0], [11.2, 0.0, 0, 0, 0]]
## Spacing of the feather rays along the dorsal fin (m).
const RAY := 0.34
const TAIL_ROOT_S := 11.45

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}
static var _skin: Skin


## One surface under construction (model-space vertices). `mask` is written as UV2 of every new vertex.
class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var c := PackedColorArray()
	var i := PackedInt32Array()
	var mask := Vector2.ZERO


static func mat(nm: String) -> Material:
	if not _mats.has(nm):
		_mats[nm] = load(MAT_DIR + nm + ".tres")
	return _mats[nm]


## Rest position of bone i (model space).
static func bone_rest(i: int) -> Vector3:
	return Vector3(0.0, BAKE_Y, HEAD_Z - float(i) * DS)


## Radii at spine length s: Vector4(side, top, bottom, ridge).
static func radius_at(s: float) -> Vector4:
	return _table(RAD, clampf(s, 0.0, LEN))


## Shared bind poses of the body skin (bone i bound at its rest transform).
static func skin() -> Skin:
	if _skin == null:
		_skin = Skin.new()
		for i: int in N_BONES:
			_skin.add_bind(i, Transform3D(Basis(), bone_rest(i)).affine_inverse())
	return _skin


# ================================================================ helpers (ported from the Cinder / Frost Dragon builders)

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


## Rows [x, a, b, c, d] -> Vector4 at x (smooth between rows).
static func _table(tab: Array, x: float) -> Vector4:
	var r0: Array = tab[0]
	if x <= float(r0[0]):
		return Vector4(r0[1], r0[2], r0[3], r0[4])
	for k: int in range(1, tab.size()):
		var r1: Array = tab[k]
		if x <= float(r1[0]):
			var a := (x - float(r0[0])) / maxf(float(r1[0]) - float(r0[0]), 0.0001)
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
			s.uv2.append(s.mask)
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


## Tapered round horn / claw / tooth along pts (claw material: g 0 dark base -> 1 pale tip from `pale_from`).
static func _horn(s: Surf, pts: Array[Vector3], r0: float, r1: float, pale_from: float = 0.35, ring: int = 7,
		samples: int = 7) -> void:
	var up := Vector3.UP
	var d := (pts[pts.size() - 1] - pts[0]).normalized()
	if absf(d.y) > 0.8:
		up = Vector3.FORWARD
	var prof := func(v: float) -> Vector4:
		var r := lerpf(r0, r1, pow(v, 0.85)) + 0.003
		return Vector4(r, r, r, 0.0)
	var col := func(_ca: float, v: float) -> Color:
		return Color(0.0, smoothstep(pale_from, 1.0, v), 0.0, 0.0)
	_loft(s, pts, prof, col, ring, samples, up)


## Lumpy ellipsoid at c (radii r, rotated by b), colour col.
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


## A faceted ice crystal from `base` along `dir` (frost_ice.gdshader COLOR: r glow, g 0 base -> 1 tip).
static func _shard(s: Surf, base: Vector3, dir: Vector3, h: float, r: float, glow: float, sides: int = 5,
		flat: float = 1.0) -> void:
	var d := dir.normalized()
	var pts: Array[Vector3] = [base - d * 0.04, base + d * (h * 0.5), base + d * h]
	var prof := func(v: float) -> Vector4:
		var k := 1.0 - 0.14 * v if v < 0.5 else lerpf(0.93, 0.0, (v - 0.5) / 0.5)
		var rr := r * k + 0.003
		return Vector4(rr * flat, rr, rr, 0.0)
	var col := func(_ca: float, v: float) -> Color:
		return Color(glow, v, 0.0, 0.0)
	_loft(s, pts, prof, col, sides, 4, Vector3.FORWARD if absf(d.y) > 0.8 else Vector3.UP)


## Ice-feather fan: fin panels between consecutive rays (roots[k] -> tips[k]); the edge between two tips sags toward
## the roots by `sag` (the ragged feather tips); an ice ray (thin glowing shard) along every ray. ref = the side the
## panel normals face (the shader is double-sided).
static func _fan(fin: Surf, ice: Surf, roots: Array[Vector3], tips: Array[Vector3], sag: float, ref: Vector3,
		cols: int, rows: int, ray_r: float, ray_glow: float) -> void:
	for k: int in roots.size() - 1:
		var ra := roots[k]
		var rb := roots[k + 1]
		var ta := tips[k]
		var tb := tips[k + 1]
		var edge := func(u: float) -> Vector3:
			var q := ta.lerp(tb, u)
			return q + (ra.lerp(rb, u) - q) * sag * sin(PI * u)
		var fn := func(u: float, v: float) -> Vector3:
			return ra.lerp(rb, u).lerp(edge.call(u) as Vector3, v)
		var ctr := func(u: float, v: float) -> Vector3:
			return (fn.call(u, v) as Vector3) - ref
		var col := func(u: float, v: float) -> Color:
			return Color(pow(maxf(1.0 - u, u), 7.0), v, smoothstep(0.7, 1.0, v), 0.0)
		var w := ta.distance_to(tb)
		var ln := (ra.distance_to(ta) + rb.distance_to(tb)) * 0.5
		var uvf := func(u: float, v: float) -> Vector2:
			return Vector2(u * w, v * ln)
		_grid(fin, fn, ctr, col, uvf, cols, rows)
	for k: int in roots.size():
		var d := tips[k] - roots[k]
		_shard(ice, roots[k] + d * 0.06, d, d.length() * 0.98, ray_r, ray_glow, 4)


static func _belly(ca: float) -> float:
	return smoothstep(-0.18, -0.58, ca)


static func _round(r0: float, r1: float) -> Callable:
	return func(v: float) -> Vector4:
		var r := lerpf(r0, r1, v)
		return Vector4(r, r, r, 0.0)


static func _scaled(rime: float) -> Callable:
	return func(ca: float, _v: float) -> Color:
		return Color(rime, _belly(ca), 1.0, 0.0)


## groups: [[Surf, material name], ...]. skinned: bones / weights from the rest z (2 bones, linear along the spine).
static func _bake(key: String, groups: Array, skinned: bool = false) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	var flags := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) \
		| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
	for g: Array in groups:
		var s: Surf = g[0]
		if s.v.is_empty():
			continue
		var nv := s.v.size()
		var c0 := PackedFloat32Array()
		var c1 := PackedFloat32Array()
		c0.resize(nv * 4)
		c1.resize(nv * 4)
		for k: int in nv:
			var p := s.v[k]
			var q := s.n[k]
			c0[k * 4] = p.x
			c0[k * 4 + 1] = p.y
			c0[k * 4 + 2] = p.z
			c0[k * 4 + 3] = 1.0
			c1[k * 4] = q.x
			c1[k * 4 + 1] = q.y
			c1[k * 4 + 2] = q.z
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = s.v
		arr[Mesh.ARRAY_NORMAL] = s.n
		arr[Mesh.ARRAY_TEX_UV] = s.uv
		arr[Mesh.ARRAY_TEX_UV2] = s.uv2
		arr[Mesh.ARRAY_COLOR] = s.c
		arr[Mesh.ARRAY_INDEX] = s.i
		arr[Mesh.ARRAY_CUSTOM0] = c0
		arr[Mesh.ARRAY_CUSTOM1] = c1
		if skinned:
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			bones.resize(nv * 4)
			weights.resize(nv * 4)
			for k: int in nv:
				var f := clampf((HEAD_Z - s.v[k].z) / DS, 0.0, float(N_BONES - 1))
				var i0 := mini(int(f), N_BONES - 2)
				var w := clampf(f - float(i0), 0.0, 1.0)
				bones[k * 4] = i0
				bones[k * 4 + 1] = i0 + 1
				weights[k * 4] = 1.0 - w
				weights[k * 4 + 1] = w
			arr[Mesh.ARRAY_BONES] = bones
			arr[Mesh.ARRAY_WEIGHTS] = weights
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		am.surface_set_material(am.get_surface_count() - 1, mat(String(g[1])))
	_meshes[key] = am
	return am


# ================================================================ body (skinned)

## The whole serpent from the neck joint to the tail tip: the banded scaled tube, the dorsal fin, the ventral tail
## blade and the tail fluke.
static func body_mesh() -> ArrayMesh:
	if _meshes.has("body"):
		return _meshes["body"]
	var sc := Surf.new()
	var fin := Surf.new()
	var ice := Surf.new()
	_tube(sc, -0.14, LEN, 108, 18)
	_dorsal(fin, 0.05, 11.2)
	_ventral(fin, 8.2, 11.3)
	_fluke(fin, ice)
	return _bake("body", [[sc, "scale_a"], [fin, "fin_a"], [ice, "ice_a"]], true)


## The straight scaled tube (UV.x around from the top, UV.y = s metres); UV2 = (flank spots, back bands).
static func _tube(s: Surf, s0: float, s1: float, rows: int, ring: int) -> void:
	var base := s.v.size()
	var fn := func(u: float, v: float) -> Vector3:
		var sv := lerpf(s0, s1, v)
		var pr := radius_at(sv)
		var a := TAU * u
		var ca := cos(a)
		var ry := pr.y if ca >= 0.0 else pr.z
		var up := ry * ca + pr.w * pow(maxf(ca, 0.0), 10.0)
		return Vector3(pr.x * sin(a), BAKE_Y + up, HEAD_Z - sv)
	var ctr := func(_u: float, v: float) -> Vector3:
		return Vector3(0.0, BAKE_Y, HEAD_Z - lerpf(s0, s1, v))
	var col := func(u: float, _v: float) -> Color:
		return Color(1.0, _belly(cos(TAU * u)), 1.0, 0.0)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u, lerpf(s0, s1, v))
	_grid(s, fn, ctr, col, uvf, ring, rows)
	for k: int in range(base, s.v.size()):
		var sv := s.uv[k].y
		var spot := smoothstep(2.1, 2.5, sv) * (1.0 - smoothstep(9.4, 9.9, sv))
		var band := smoothstep(0.1, 0.5, sv) * (1.0 - smoothstep(11.0, 11.8, sv))
		s.uv2[k] = Vector2(spot, band)


## The ragged ice-feather dorsal fin: rays every RAY m leaning back, spiky tips between sagging panels.
static func _dorsal(s: Surf, s0: float, s1: float) -> void:
	var cols := int((s1 - s0) / (RAY / 10.0))
	var hgt := func(sv: float) -> float:
		var p := sv / RAY
		var ef := 0.6 + 0.4 * pow(absf(cos(PI * p)), 5.0)
		return _table(CREST, sv).x * ef
	var fn := func(u: float, v: float) -> Vector3:
		var sv := lerpf(s0, s1, u)
		var pr := radius_at(sv)
		var h: float = hgt.call(sv)
		var base := Vector3(0.0, BAKE_Y + pr.y + pr.w - 0.05, HEAD_Z - sv)
		return base + Vector3(0.0, v * h, -v * h * 0.55)
	var ctr := func(u: float, v: float) -> Vector3:
		return (fn.call(u, v) as Vector3) - Vector3.RIGHT
	var col := func(u: float, v: float) -> Color:
		var sv := lerpf(s0, s1, u)
		return Color(pow(absf(cos(PI * sv / RAY)), 10.0), v, smoothstep(0.65, 1.0, v), 0.0)
	var uvf := func(u: float, v: float) -> Vector2:
		var sv := lerpf(s0, s1, u)
		return Vector2(sv, v * float(hgt.call(sv)))
	_grid(s, fn, ctr, col, uvf, cols, 3)


## A small ice-feather blade under the tail (continues into the fluke's lower lobe).
static func _ventral(s: Surf, s0: float, s1: float) -> void:
	var cols := int((s1 - s0) / (RAY / 10.0))
	var hgt := func(sv: float) -> float:
		var k := sin(PI * clampf((sv - s0) / (s1 - s0), 0.0, 1.0))
		return 0.2 * pow(k, 0.8) * (0.62 + 0.38 * pow(absf(cos(PI * sv / RAY)), 5.0))
	var fn := func(u: float, v: float) -> Vector3:
		var sv := lerpf(s0, s1, u)
		var pr := radius_at(sv)
		var h: float = hgt.call(sv)
		return Vector3(0.0, BAKE_Y - pr.z + 0.04 - v * h, HEAD_Z - sv - v * h * 0.5)
	var ctr := func(u: float, v: float) -> Vector3:
		return (fn.call(u, v) as Vector3) - Vector3.RIGHT
	var col := func(u: float, v: float) -> Color:
		var sv := lerpf(s0, s1, u)
		return Color(pow(absf(cos(PI * sv / RAY)), 10.0), v, smoothstep(0.65, 1.0, v), 0.0)
	var uvf := func(u: float, v: float) -> Vector2:
		var sv := lerpf(s0, s1, u)
		return Vector2(sv, v * float(hgt.call(sv)))
	_grid(s, fn, ctr, col, uvf, cols, 2)


## The tail fluke: a horizontal fan (the top-down read of the tail end) + upper and lower lobes, ice rays, and a long
## glowing crystal at the tip (the tail glow point).
static func _fluke(fin: Surf, ice: Surf) -> void:
	var zr := HEAD_Z - TAIL_ROOT_S
	var c := Vector3(0.0, BAKE_Y, zr)
	var dirs: Array[Vector3] = [Vector3(-1.0, 0.0, -0.32), Vector3(-0.78, 0.0, -0.64), Vector3(-0.42, 0.0, -0.92),
		Vector3(0.0, 0.0, -1.0), Vector3(0.42, 0.0, -0.92), Vector3(0.78, 0.0, -0.64), Vector3(1.0, 0.0, -0.32)]
	var lens: Array[float] = [0.62, 0.9, 1.12, 1.3, 1.12, 0.9, 0.62]
	var roots: Array[Vector3] = []
	var tips: Array[Vector3] = []
	for k: int in dirs.size():
		var d := dirs[k].normalized()
		var r := c + Vector3(d.x * 0.06, 0.0, -0.1 * absf(d.x))
		roots.append(r)
		tips.append(r + d * lens[k] + Vector3(0.0, 0.03 * sin(PI * float(k) / 6.0), 0.0))
	_fan(fin, ice, roots, tips, 0.3, Vector3.UP, 6, 5, 0.03, 0.55)
	# upper and lower lobes (vertical) around the centre ray
	var up_d := Vector3(0.0, 0.8, -0.62).normalized()
	var dn_d := Vector3(0.0, -0.7, -0.72).normalized()
	var vr: Array[Vector3] = [c + Vector3(0.0, 0.08, 0.1), c, c + Vector3(0.0, -0.07, 0.1)]
	var vt: Array[Vector3] = [vr[0] + up_d * 0.78, c + Vector3(0.0, 0.0, -1.3), vr[2] + dn_d * 0.55]
	_fan(fin, ice, vr, vt, 0.3, Vector3.RIGHT, 6, 5, 0.028, 0.55)
	# the crystal at the tip: the tail's glow point
	_shard(ice, c + Vector3(0.0, 0.0, -1.05), Vector3(0.0, 0.0, -1.0), 0.72, 0.1, 1.0, 6)
	for sx: float in [-1.0, 1.0]:
		_shard(ice, c + Vector3(0.05 * sx, 0.0, -0.95), Vector3(0.45 * sx, 0.18, -1.0), 0.42, 0.06, 1.0, 5)


# ================================================================ head, jaw (rigid)

## Skull + upper jaw, eyes, lip glow, teeth, palate, the frilled fin crest; variant 1 adds the crystal horns.
static func head_mesh(variant: int) -> ArrayMesh:
	var key := "head%d" % variant
	if _meshes.has(key):
		return _meshes[key]
	var sc := Surf.new()
	var cl := Surf.new()
	var fin := Surf.new()
	var ice := Surf.new()
	var gl := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.03, 3.36), Vector3(0, 4.085, 3.68), Vector3(0, 4.085, 4.02),
		Vector3(0, 4.035, 4.38), Vector3(0, 3.995, 4.68), Vector3(0, 3.975, 4.94)]
	var tab := [[0.0, 0.29, 0.25, 0.23, 0.0], [0.14, 0.365, 0.30, 0.25, 0.03], [0.34, 0.35, 0.275, 0.21, 0.03],
		[0.58, 0.265, 0.205, 0.15, 0.02], [0.82, 0.18, 0.145, 0.105, 0.01], [0.95, 0.12, 0.10, 0.08, 0.0],
		[1.0, 0.04, 0.04, 0.035, 0.0]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	var col := func(ca: float, v: float) -> Color:
		var lip := exp(-pow((ca + 0.93) / 0.09, 2.0)) * smoothstep(0.2, 0.34, v) * (1.0 - smoothstep(0.9, 1.0, v))
		return Color(0.6, smoothstep(-0.55, -0.85, ca) * 0.85, 1.0, 0.6 * lip)
	_loft(sc, pts, prof, col, 22, 18)
	for sx: float in [-1.0, 1.0]:
		# brow ridge (a cold scowl), cheek plate
		_blob(sc, Vector3(0.19 * sx, 4.29, 3.99), Vector3(0.12, 0.07, 0.23), Color(0.6, 0.0, 0.0, 0.0),
			Basis(Vector3.FORWARD, -0.3 * sx) * Basis(Vector3.RIGHT, 0.1))
		_blob(sc, Vector3(0.30 * sx, 4.02, 3.72), Vector3(0.09, 0.13, 0.21), Color(0.5, 0.25, 0.0, 0.0))
		# eyes (cold glow) and nostrils
		_blob(gl, Vector3(0.262 * sx, 4.178, 4.05), Vector3(0.056, 0.043, 0.118), Color.WHITE,
			Basis(Vector3.UP, 0.35 * sx) * Basis(Vector3.FORWARD, -0.25 * sx), 0.0, 8, 4)
		_blob(gl, Vector3(0.075 * sx, 4.05, 4.84), Vector3(0.034, 0.027, 0.042), Color.WHITE, Basis.IDENTITY, 0.0, 6, 3)
		# upper teeth along the lip, a long fang at the front
		for k: int in 5:
			var v: float = 0.36 + 0.12 * float(k)
			var cp := _cr(pts, v)
			var pr: Vector4 = prof.call(v)
			var base := cp + Vector3(0.62 * pr.x * sx, -0.8 * pr.z, 0.0)
			var ln := 0.075 if k < 4 else 0.15
			_horn(cl, [base + Vector3(0, 0.02, 0), base + Vector3(0, -ln, 0.02)], 0.03 if k < 4 else 0.045, 0.004,
				0.0, 5, 2)
		# THE READ: the frilled fin crest, a wide collar of ice-feather rays fanning out behind each cheek
		var fd: Array[Vector3] = [Vector3(0.25, 0.95, -0.45), Vector3(0.62, 0.72, -0.55), Vector3(0.9, 0.32, -0.55),
			Vector3(1.0, -0.08, -0.5), Vector3(0.82, -0.48, -0.45), Vector3(0.5, -0.82, -0.35)]
		var fl: Array[float] = [0.84, 1.0, 1.08, 0.98, 0.78, 0.56]
		var roots: Array[Vector3] = []
		var tips: Array[Vector3] = []
		for k: int in fd.size():
			var d := _mx(fd[k], sx).normalized()
			var r := Vector3(0.22 * sx, 4.06, 3.55) + d * 0.09
			roots.append(r)
			tips.append(r + d * fl[k])
		_fan(fin, ice, roots, tips, 0.3, Vector3.FORWARD, 6, 5, 0.032, 0.8)
	# the crest fan on top of the skull (continues into the dorsal fin)
	var cr: Array[Vector3] = [Vector3(0, 4.26, 3.82), Vector3(0, 4.28, 3.63), Vector3(0, 4.25, 3.45)]
	var cd: Array[Vector3] = [Vector3(0, 0.92, -0.4), Vector3(0, 0.8, -0.6), Vector3(0, 0.66, -0.75)]
	var cln: Array[float] = [0.62, 0.72, 0.62]
	var ctips: Array[Vector3] = []
	for k: int in 3:
		ctips.append(cr[k] + cd[k].normalized() * cln[k])
	_fan(fin, ice, cr, ctips, 0.3, Vector3.RIGHT, 6, 5, 0.032, 0.8)
	# the glowing palate (seen when the jaw opens)
	_blob(gl, Vector3(0.0, 3.935, 4.24), Vector3(0.15, 0.022, 0.36), Color.WHITE, Basis.IDENTITY, 0.0, 8, 4)
	if variant == 1:
		# Old Hoarfang: white-violet crystal horns growing from the brow (two tall, two back-swept, a nose crystal)
		for sx: float in [-1.0, 1.0]:
			_shard(ice, Vector3(0.17 * sx, 4.29, 3.93), Vector3(0.32 * sx, 0.8, -0.52), 0.95, 0.1, 0.55, 6)
			_shard(ice, Vector3(0.26 * sx, 4.22, 3.78), Vector3(0.76 * sx, 0.5, -0.45), 0.58, 0.07, 0.55, 5)
			_shard(ice, Vector3(0.13 * sx, 4.28, 4.14), Vector3(0.22 * sx, 0.92, 0.28), 0.3, 0.05, 0.55, 5)
		_shard(ice, Vector3(0.0, 4.11, 4.62), Vector3(0.0, 0.86, 0.32), 0.34, 0.065, 0.55, 5)
	return _bake(key, [[sc, "scale_a"], [cl, "claw"], [fin, "fin_a"], [ice, "ice_a"], [gl, "eye_a"]])


## Lower jaw: glowing tongue / throat, lower teeth, a small chin fin.
static func jaw_mesh() -> ArrayMesh:
	if _meshes.has("jaw"):
		return _meshes["jaw"]
	var sc := Surf.new()
	var cl := Surf.new()
	var fin := Surf.new()
	var ice := Surf.new()
	var gl := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 3.905, 3.50), Vector3(0, 3.865, 3.92), Vector3(0, 3.855, 4.32),
		Vector3(0, 3.87, 4.82)]
	var tab := [[0.0, 0.27, 0.05, 0.15, 0.0], [0.45, 0.235, 0.045, 0.125, 0.0], [0.82, 0.15, 0.035, 0.085, 0.0],
		[1.0, 0.05, 0.02, 0.03, 0.0]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	var col := func(ca: float, _v: float) -> Color:
		return Color(0.5, smoothstep(-0.2, -0.7, ca), 1.0, 0.0)
	_loft(sc, pts, prof, col, 16, 12)
	_blob(gl, Vector3(0.0, 3.893, 4.2), Vector3(0.13, 0.02, 0.33), Color.WHITE, Basis.IDENTITY, 0.0, 8, 4)
	for sx: float in [-1.0, 1.0]:
		for k: int in 4:
			var v: float = 0.34 + 0.15 * float(k)
			var cp := _cr(pts, v)
			var pr: Vector4 = prof.call(v)
			var base := cp + Vector3(0.66 * pr.x * sx, 0.6 * pr.y, 0.0)
			var ln := 0.065 if k < 3 else 0.11
			_horn(cl, [base + Vector3(0, -0.02, 0), base + Vector3(0, ln, 0.01)], 0.027 if k < 3 else 0.038, 0.004,
				0.0, 5, 2)
	var roots: Array[Vector3] = [Vector3(0, 3.78, 4.30), Vector3(0, 3.76, 4.08), Vector3(0, 3.78, 3.86)]
	var dd: Array[Vector3] = [Vector3(0, -0.8, -0.55), Vector3(0, -0.9, -0.42), Vector3(0, -0.78, -0.62)]
	var dl: Array[float] = [0.34, 0.44, 0.36]
	var tips: Array[Vector3] = []
	for k: int in 3:
		tips.append(roots[k] + dd[k].normalized() * dl[k])
	_fan(fin, ice, roots, tips, 0.3, Vector3.RIGHT, 5, 4, 0.025, 0.4)
	return _bake("jaw", [[sc, "scale_a"], [cl, "claw"], [fin, "fin_a"], [ice, "ice_a"], [gl, "eye_a"]])


# ================================================================ forelegs, pectoral fins (rigid)

## A short clawed foreleg (sx -1 left, 1 right), hanging down-forward at rest (planted when coiled).
static func leg_mesh(sx: float) -> ArrayMesh:
	var key := "leg%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var sc := Surf.new()
	var cl := Surf.new()
	var ice := Surf.new()
	var s := _mx(SHOULDER, sx)
	var e := Vector3(0.50 * sx, 3.36, 0.98)
	var w := Vector3(0.47 * sx, 3.10, 1.30)
	var col := _scaled(0.5)
	_loft(sc, [s, s.lerp(e, 0.5) + Vector3(0.03 * sx, 0.0, 0.02), e], _round(0.16, 0.11), col, 9, 6)
	_loft(sc, [e, e.lerp(w, 0.5) + Vector3(0.0, -0.02, 0.0), w], _round(0.11, 0.08), col, 9, 6)
	_blob(sc, e, Vector3(0.11, 0.11, 0.12), Color(0.5, 0.2, 0.0, 0.0))
	_blob(sc, w + Vector3(0.0, -0.02, 0.07), Vector3(0.11, 0.065, 0.14), Color(0.4, 0.3, 0.0, 0.0))
	for k: int in 3:
		var ox := (float(k) - 1.0) * 0.07 * sx
		var b := w + Vector3(ox, -0.03, 0.16)
		_horn(cl, [b, b + Vector3(ox * 0.3, -0.02, 0.12), b + Vector3(ox * 0.4, -0.12, 0.2)], 0.036, 0.005, 0.2, 5, 4)
	_shard(ice, e + Vector3(0.03 * sx, 0.03, -0.06), Vector3(0.3 * sx, 0.35, -1.0), 0.36, 0.05, 0.4, 5)
	return _bake(key, [[sc, "scale_a"], [cl, "claw"], [ice, "ice_a"]])


## A pectoral ice-feather fan (5 rays, ~1.15 m), spread out and back from behind the foreleg.
static func fin_mesh(sx: float) -> ArrayMesh:
	var key := "fin%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var fin := Surf.new()
	var ice := Surf.new()
	var dirs: Array[Vector3] = [Vector3(1.0, 0.08, -0.3), Vector3(0.88, 0.04, -0.58), Vector3(0.66, -0.01, -0.82),
		Vector3(0.42, -0.04, -0.95), Vector3(0.18, -0.05, -1.0)]
	var lens: Array[float] = [1.0, 1.15, 1.12, 0.98, 0.78]
	var roots: Array[Vector3] = []
	var tips: Array[Vector3] = []
	var r0 := _mx(FIN_ROOT, sx)
	for k: int in dirs.size():
		var d := _mx(dirs[k], sx).normalized()
		var r := r0 + Vector3(0.0, -0.02 * float(k), -0.07 * float(k))
		roots.append(r)
		tips.append(r + d * lens[k])
	_fan(fin, ice, roots, tips, 0.28, Vector3.UP, 6, 5, 0.03, 0.5)
	return _bake(key, [[fin, "fin_a"], [ice, "ice_a"]])
