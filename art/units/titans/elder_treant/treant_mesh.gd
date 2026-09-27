extends RefCounted
## Elder Treant geometry (task 13.V18, cavalry-mounts.md 10): every mesh of the model, built in code once per game
## (static cache) in MODEL space (feet origin, face +Z, rest pose = the walking form). Used by elder_treant.gd
## (preloaded, no class_name). The rig tables (pivots, rest positions, the rooted pose) live here so the rig and the
## geometry agree exactly.
## The rooted form is authored too: the canopy of each forearm (twigs, leaf masses, blossoms, glowing seed pods) is
## built in the ROOTED pose (pose_xf) and mapped back into the forearm's rest space, and the ground roots ("Spread",
## a node that never moves) are built where they lie. Every vertex that only exists in the rooted form carries a
## growth record in CUSTOM0 (xyz = anchor, w = 1 + start): the shaders (treant.gdshaderinc) keep it on its anchor
## until root_morph reaches `start`, then grow it out over 0.3 of the morph (roots first, then twigs, leaves, pods).
## Surfaces per mesh: bark (treant_bark), leaf (treant_leaf: leaves, moss beard, blossoms, garland), glow
## (treant_glow: eyes, seed pods). Vertex colour meanings: see the three shaders.

const DIR := "res://art/units/titans/elder_treant/"
const DEG := PI / 180.0

enum { P_ROOT, P_HIPS, P_LEG_L, P_SHIN_L, P_LEG_R, P_SHIN_R, P_CHEST, P_HEAD, P_ARM_L, P_FORE_L, P_ARM_R,
	P_FORE_R, P_SPREAD }
const NP: int = 13
const PIVOT_PATHS: Array[String] = ["Root", "Root/Hips", "Root/Hips/LegL", "Root/Hips/LegL/ShinL", "Root/Hips/LegR",
	"Root/Hips/LegR/ShinR", "Root/Chest", "Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmL/ForeL",
	"Root/Chest/ArmR", "Root/Chest/ArmR/ForeR", "Spread"]
const PARENT: Array[int] = [-1, P_ROOT, P_HIPS, P_LEG_L, P_HIPS, P_LEG_R, P_ROOT, P_CHEST, P_CHEST, P_ARM_L, P_CHEST,
	P_ARM_R, -1]
## Rest positions of the pivots in their parent (the scene uses the same numbers; the test checks it).
const REST_LOCAL: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0, 1.25, 0), Vector3(-0.42, -0.05, 0),
	Vector3(-0.10, -0.56, 0.08), Vector3(0.42, -0.05, 0), Vector3(0.10, -0.56, 0.08), Vector3(0, 1.5, 0),
	Vector3(0, 1.42, 0.2), Vector3(-0.88, 1.22, 0.12), Vector3(-0.30, -0.78, 0.18), Vector3(0.88, 1.22, 0.12),
	Vector3(0.30, -0.78, 0.18), Vector3(0, 0, 0)]
## The rooted form (root_k = 1): Euler offsets in DEGREES (Basis.from_euler, YXZ) and position offsets per pivot.
## The body sinks 0.78 m, the legs splay and bend into the ground, the chest and face tilt up, the arms lift into
## a V and the forearms rise to carry the canopy.
const ROOTED_ROT: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(-18, 0, -24), Vector3(40, 0, -8),
	Vector3(-18, 0, 24), Vector3(40, 0, 8), Vector3(-7, 0, 0), Vector3(-12, 0, 0), Vector3(4, 0, -124),
	Vector3(0, 0, -30), Vector3(4, 0, 124), Vector3(0, 0, 30), Vector3(0, 0, 0)]
const ROOTED_POS: Array[Vector3] = [Vector3(0, -0.78, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0),
	Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0),
	Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0)]
## Pivots whose mesh casts a shadow (the big parts; the ground roots never).
const SHADOW_PIVOTS: Array[int] = [P_HIPS, P_LEG_L, P_SHIN_L, P_LEG_R, P_SHIN_R, P_CHEST, P_HEAD, P_ARM_L, P_FORE_L,
	P_ARM_R, P_FORE_R]

# ---- key points (model rest space, right side; x mirrors)
const ELBOW := Vector3(1.18, 2.00, 0.30)
const WRIST := Vector3(1.24, 1.16, 0.50)
const HAND := Vector3(1.24, 1.02, 0.56)
const FINGERS: Array[Vector3] = [Vector3(1.06, 0.60, 0.80), Vector3(1.27, 0.54, 0.86), Vector3(1.46, 0.64, 0.70),
	Vector3(0.98, 0.90, 0.80)]
const EYE := Vector3(0.17, 3.215, 0.735)
const CROWN_TOP := Vector3(0.0, 3.56, 0.17)

# ---- palette (leaf surface COLOR.rgb; bark colours are the material's)
const LEAF_A := Color(0.35, 0.56, 0.17, 0.0)
const LEAF_B := Color(0.27, 0.46, 0.14, 0.0)
const LEAF_C := Color(0.43, 0.62, 0.20, 0.0)
const LEAF_DARK := Color(0.22, 0.38, 0.12, 0.0)
const MOSS_A := Color(0.40, 0.49, 0.26, 0.0)
const MOSS_B := Color(0.31, 0.40, 0.20, 0.0)
const MOSS_TIP := Color(0.56, 0.60, 0.38, 0.0)
const PINK := Color(0.98, 0.50, 0.70, 0.5)
const PINK_PALE := Color(1.0, 0.78, 0.87, 0.5)
const HEART := Color(1.0, 0.86, 0.45, 0.5)
const EYE_GLOW := Color(0.50, 1.0, 0.42, 0.0)
const POD_GLOW := Color(0.80, 1.0, 0.34, 0.0)

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}


## One surface under construction. cu = CUSTOM0 (4 floats per vertex).
class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var c := PackedColorArray()
	var cu := PackedFloat32Array()
	var i := PackedInt32Array()

	# All writes happen in here: writing a packed array through `surf.array[i]` from outside copies it every time.
	func add(p: Vector3, nn: Vector3, t: Vector2, col: Color) -> void:
		v.append(p)
		n.append(nn)
		uv.append(t)
		c.append(col)
		cu.append(0.0)
		cu.append(0.0)
		cu.append(0.0)
		cu.append(0.0)

	func quad(a: int, b: int, cc: int, d: int) -> void:
		var fnn := (v[d] - v[a]).cross(v[b] - v[a])
		if fnn.length_squared() < 1e-14:
			fnn = (v[cc] - v[b]).cross(v[d] - v[b])
		if fnn.dot(n[a] + n[b] + n[cc] + n[d]) >= 0.0:
			i.append_array(PackedInt32Array([a, b, d, b, cc, d]))
		else:
			i.append_array(PackedInt32Array([a, d, b, b, d, cc]))

	func tri(a: int, b: int, cc: int, nrm: Vector3) -> void:
		if (v[cc] - v[a]).cross(v[b] - v[a]).dot(nrm) >= 0.0:
			i.append_array(PackedInt32Array([a, b, cc]))
		else:
			i.append_array(PackedInt32Array([a, cc, b]))

	## Every vertex from `from` grows out of `anchor` from root_morph = t0 (shrink: vanishes instead).
	func tag(from: int, anchor: Vector3, t0: float, shrink: bool = false) -> void:
		var w := (1.0 + clampf(t0, 0.0, 0.7)) * (-1.0 if shrink else 1.0)
		for k: int in range(from, v.size()):
			cu[k * 4] = anchor.x
			cu[k * 4 + 1] = anchor.y
			cu[k * 4 + 2] = anchor.z
			cu[k * 4 + 3] = w

	## Every vertex from `from` grows out of `base`, later the farther it lies toward `tip` (a root that extends).
	func tag_along(from: int, base: Vector3, tip: Vector3, t_start: float, t_span: float) -> void:
		var dvec := tip - base
		var l2 := maxf(dvec.length_squared(), 0.0001)
		for k: int in range(from, v.size()):
			var f := clampf((v[k] - base).dot(dvec) / l2, 0.0, 1.0)
			cu[k * 4] = base.x
			cu[k * 4 + 1] = base.y
			cu[k * 4 + 2] = base.z
			cu[k * 4 + 3] = 1.0 + clampf(t_start + f * t_span, 0.0, 0.7)

	## Moves every vertex from `from_v` and every index from `from_i` into a new Surf (re-indexed) and returns it.
	func split_tail(from_v: int, from_i: int) -> Surf:
		var t := Surf.new()
		for k: int in range(from_v, v.size()):
			t.v.append(v[k])
			t.n.append(n[k])
			t.uv.append(uv[k])
			t.c.append(c[k])
			for q: int in 4:
				t.cu.append(cu[k * 4 + q])
		for k: int in range(from_i, i.size()):
			t.i.append(i[k] - from_v)
		v.resize(from_v)
		n.resize(from_v)
		uv.resize(from_v)
		c.resize(from_v)
		cu.resize(from_v * 4)
		i.resize(from_i)
		return t

	## Transforms vertices, normals and growth anchors from `from` (rooted-space authoring -> rest space).
	func xform_range(from: int, xf: Transform3D) -> void:
		for k: int in range(from, v.size()):
			v[k] = xf * v[k]
			n[k] = (xf.basis * n[k]).normalized()
			if cu[k * 4 + 3] != 0.0:
				var an := xf * Vector3(cu[k * 4], cu[k * 4 + 1], cu[k * 4 + 2])
				cu[k * 4] = an.x
				cu[k * 4 + 1] = an.y
				cu[k * 4 + 2] = an.z


static func material(nm: String) -> Material:
	if not _mats.has(nm):
		_mats[nm] = load(DIR + "treant_" + nm + ".tres")
	return _mats[nm]


# ================================================================ rig tables

## Model-space rest position of pivot i.
static func origin(i: int) -> Vector3:
	var p := Vector3.ZERO
	var k := i
	while k >= 0:
		p += REST_LOCAL[k]
		k = PARENT[k]
	return p


## Model-space transform of pivot i with the rooted offsets scaled by k (1 = the rooted form, 0 = rest).
static func pose_xf(i: int, k: float = 1.0) -> Transform3D:
	var t := Transform3D(Basis.from_euler(ROOTED_ROT[i] * (DEG * k)), REST_LOCAL[i] + ROOTED_POS[i] * k)
	if PARENT[i] >= 0:
		return pose_xf(PARENT[i], k) * t
	return t


## Maps a rest-space vertex of pivot i to where it renders in the rooted form.
static func rest_to_rooted(i: int) -> Transform3D:
	return pose_xf(i) * Transform3D(Basis.IDENTITY, -origin(i))


static func mx(p: Vector3, sx: float) -> Vector3:
	return Vector3(p.x * sx, p.y, p.z)


## Rest-space point (in the head) at the centre of the rooted crown canopy (volley origin marker).
static func crown_canopy_centre() -> Vector3:
	var to_r := rest_to_rooted(P_HEAD)
	return to_r.affine_inverse() * (to_r * CROWN_TOP + Vector3(0, 0.78, 0.05))


## Rest-space point (in the forearm) at the centre of that side's canopy (volley origin marker).
static func canopy_centre(sx: float) -> Vector3:
	var fi := P_FORE_L if sx < 0.0 else P_FORE_R
	var to_r := rest_to_rooted(fi)
	return to_r.affine_inverse() * (to_r * mx(WRIST, sx) + Vector3(0.14 * sx, 0.55, 0.0))


# ================================================================ meshes

## The rooted-only part of pivot i (the head's crown canopy, each forearm's canopy), null for the other pivots.
## It is its own mesh node, hidden while walking: an overlay material without the growth vertex code (the Ice chill
## tint, art/vfx/ice_vfx.gd) would otherwise draw the collapsed canopy at full size.
static func growth_mesh(i: int) -> ArrayMesh:
	mesh(i)
	return _meshes.get("g%d" % i)


## Splits the surfaces at the marks (rooted-only tails), bakes the tails as the growth mesh of pivot i.
static func _bake_growth(i: int, surfs: Array, marks: Array, names: Array) -> void:
	var groups := []
	for k: int in surfs.size():
		var s: Surf = surfs[k]
		var mk: Array = marks[k]
		groups.append([s.split_tail(int(mk[0]), int(mk[1])), names[k]])
	_meshes["g%d" % i] = _bake(groups)


static func mesh(i: int) -> ArrayMesh:
	var key := "p%d" % i
	if _meshes.has(key):
		return _meshes[key]
	var m: ArrayMesh = null
	match i:
		P_HIPS:
			m = _hips()
		P_LEG_L:
			m = _thigh(-1.0)
		P_LEG_R:
			m = _thigh(1.0)
		P_SHIN_L:
			m = _shin(-1.0)
		P_SHIN_R:
			m = _shin(1.0)
		P_CHEST:
			m = _chest()
		P_HEAD:
			m = _head()
		P_ARM_L:
			m = _upper_arm(-1.0)
		P_ARM_R:
			m = _upper_arm(1.0)
		P_FORE_L:
			m = _forearm(-1.0)
		P_FORE_R:
			m = _forearm(1.0)
		P_SPREAD:
			m = _spread()
	_meshes[key] = m
	return m


static func _bake(groups: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	var flags := Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
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
		arr[Mesh.ARRAY_CUSTOM0] = s.cu
		arr[Mesh.ARRAY_INDEX] = s.i
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		am.surface_set_material(am.get_surface_count() - 1, material(String(g[1])))
	return am


# ---------------------------------------------------------------- hips: pelvis stump, root skirt, team garland

static func _hips() -> ArrayMesh:
	var bk := Surf.new()
	var lf := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 0.96, 0.0), Vector3(0, 1.18, 0.0), Vector3(0, 1.44, 0.01), Vector3(0, 1.68, 0.02)]
	var tab := [[0.0, 0.36, 0.30, 0.30], [0.22, 0.60, 0.50, 0.50], [0.7, 0.63, 0.53, 0.54], [1.0, 0.58, 0.49, 0.51]]
	_loft(bk, pts, _prof(tab), _cbk(0.15, 0.0, 0.5), 18, 8, 0.06, 1.0)
	_blob(bk, Vector3(0, 0.98, 0.0), Vector3(0.38, 0.1, 0.32), _bk(0.0, 0.3, 0.0), Basis.IDENTITY, 0.05, 10, 4)
	# a skirt of hanging roots (front and back: the thighs swing at the sides)
	for a_deg: float in [0.0, 26.0, -26.0, 180.0, 154.0, -154.0]:
		var a := a_deg * DEG
		var o := Vector3(sin(a), 0.0, cos(a))
		var base := Vector3(o.x * 0.48, 1.18, o.z * 0.42)
		var ln := 0.40 if absf(a_deg) < 30.0 else 0.34
		_branch(bk, [base, base + o * 0.11 + Vector3(0, -ln * 0.5, 0), base + o * 0.15 + Vector3(0, -ln, 0)], 0.12,
			0.03, _bk(0.25, 0.15, 0.0), 7, 6, 0.05)
	# the vine sash (lower in front) with hanging team leaves
	var ring: Array[Vector3] = []
	for j: int in 25:
		var a := TAU * float(j) / 24.0
		ring.append(Vector3(sin(a) * 0.70, 1.55 - 0.09 * cos(a), cos(a) * 0.60))
	_loft(bk, ring, _round(0.055, 0.055), _cbk(0.3, 0.1, 0.0), 6, 40)
	var k := 0
	for a_deg: float in [-78.0, -52.0, -26.0, 0.0, 26.0, 52.0, 78.0, 150.0, 180.0, -150.0]:
		var a := a_deg * DEG
		var o := Vector3(sin(a), 0.0, cos(a))
		var tg := Vector3(cos(a), 0.0, -sin(a))
		var at := Vector3(o.x * 0.73, 1.55 - 0.09 * cos(a), o.z * 0.63)
		var b := Basis(tg, Vector3.UP, o) * Basis(Vector3.RIGHT, 0.28)
		var br := 0.92 if k % 2 == 0 else 1.06
		_blob(lf, at + Vector3(0, -0.17, 0) + o * 0.05, Vector3(0.13, 0.22, 0.045), Color(br, br, br, 1.0), b, 0.04, 8, 5)
		k += 1
	return _bake([[bk, "bark"], [lf, "leaf"]])


# ---------------------------------------------------------------- legs

static func _thigh(sx: float) -> ArrayMesh:
	var bk := Surf.new()
	var hip := Vector3(0.42 * sx, 1.30, 0.0)
	var knee := Vector3(0.52 * sx, 0.66, 0.08)
	_blob(bk, hip + Vector3(0.02 * sx, 0.02, 0.0), Vector3(0.34, 0.22, 0.31), _bk(0.3, 0.0, 0.2), Basis.IDENTITY, 0.06,
		10, 6, 2.0 + sx)
	_loft(bk, [hip, hip.lerp(knee, 0.5) + Vector3(0.04 * sx, 0, 0.02), knee], _round(0.33, 0.25), _cbk(0.12, 0.0, 0.4),
		12, 7, 0.07, 2.0 + sx)
	_blob(bk, knee + Vector3(0.02 * sx, 0.0, 0.07), Vector3(0.25, 0.23, 0.24), _bk(0.35, 0.0, 0.2), Basis.IDENTITY,
		0.08, 10, 6, 3.0 + sx)
	return _bake([[bk, "bark"]])


## Shin + the root foot: a mossy club of a foot and four root toes that grip the ground.
static func _shin(sx: float) -> ArrayMesh:
	var bk := Surf.new()
	var knee := Vector3(0.52 * sx, 0.72, 0.08)
	var ankle := Vector3(0.55 * sx, 0.17, 0.05)
	var col := func(_ca: float, v: float) -> Color:
		return Color(lerpf(0.1, 0.7, v), 0.0, 0.3, 1.0)
	_loft(bk, [knee, Vector3(0.54 * sx, 0.40, 0.06), ankle], _round(0.24, 0.30), col, 12, 6, 0.07, 4.0 + sx)
	var foot := Vector3(0.55 * sx, 0.13, 0.10)
	_blob(bk, foot, Vector3(0.34, 0.15, 0.40), _bk(0.85, 0.0, 0.1), Basis.IDENTITY, 0.08, 10, 5, 5.0 + sx)
	for a_deg: float in [-42.0, 0.0, 42.0, 180.0]:
		var a := (a_deg + 12.0 * sx) * DEG
		var o := Vector3(sin(a), 0.0, cos(a))
		var ln := 0.42 if a_deg == 180.0 else 0.62
		var p0 := foot + o * 0.18 + Vector3(0, 0.02, 0)
		_branch(bk, [p0, foot + o * (0.18 + ln * 0.45) + Vector3(0, 0.04, 0), foot + o * (0.18 + ln * 0.85)
			+ Vector3(0, -0.06, 0), foot + o * (0.18 + ln) + Vector3(0, -0.12, 0)], 0.13, 0.03, _bk(0.55, 0.1, 0.0),
			7, 7, 0.06)
	return _bake([[bk, "bark"]])


# ---------------------------------------------------------------- chest: the great trunk

static func _chest() -> ArrayMesh:
	var bk := Surf.new()
	var lf := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 1.36, 0.0), Vector3(0, 1.86, 0.03), Vector3(0, 2.36, 0.09),
		Vector3(0, 2.80, 0.15), Vector3(0, 3.04, 0.18)]
	var tab := [[0.0, 0.56, 0.46, 0.46], [0.3, 0.62, 0.50, 0.50], [0.62, 0.76, 0.56, 0.60], [0.85, 0.82, 0.58, 0.62],
		[1.0, 0.64, 0.50, 0.54]]
	_loft(bk, pts, _prof(tab), _cbk(0.25, 0.0, 0.9), 24, 16, 0.07, 0.5)
	for sx: float in [-1.0, 1.0]:
		_blob(bk, Vector3(0.80 * sx, 2.74, 0.10), Vector3(0.42, 0.36, 0.40), _bk(0.95, 0.0, 0.3), Basis.IDENTITY, 0.1,
			12, 7, 7.0 + sx)
	# the hunch of the upper back
	_blob(bk, Vector3(0, 2.62, -0.34), Vector3(0.58, 0.46, 0.36), _bk(0.7, 0.0, 0.5), Basis.IDENTITY, 0.08, 12, 7, 9.0)
	# a living branch growing from the left of the back (asymmetric silhouette), a twig, leaf tufts
	_branch(bk, [Vector3(-0.30, 2.66, -0.50), Vector3(-0.44, 3.02, -0.72), Vector3(-0.56, 3.42, -0.86)], 0.15, 0.045,
		_bk(0.3, 0.0, 0.2), 8, 8, 0.05)
	_branch(bk, [Vector3(-0.44, 3.00, -0.72), Vector3(-0.64, 3.16, -0.76), Vector3(-0.80, 3.30, -0.74)], 0.07, 0.025,
		_bk(0.2, 0.0, 0.0), 6, 5)
	_leaf_mass(lf, Vector3(-0.58, 3.56, -0.88), Vector3(0.32, 0.24, 0.30), LEAF_B, 3.0)
	_leaf_mass(lf, Vector3(-0.84, 3.36, -0.74), Vector3(0.20, 0.15, 0.19), LEAF_A, 4.0)
	_blossom(lf, Vector3(-0.56, 3.80, -0.84), Vector3(0.1, 1.0, -0.2), 0.16, PINK, 0.4)
	# a broken stub on the right, its snapped end dark
	var s0 := Vector3(0.36, 2.52, -0.52)
	var s1 := Vector3(0.54, 2.84, -0.76)
	_branch(bk, [s0, s0.lerp(s1, 0.5) + Vector3(0.02, 0, 0), s1], 0.14, 0.11, _bk(0.2, 0.1, 0.1), 8, 4)
	var d := (s1 - s0).normalized()
	var bx := d.cross(Vector3.FORWARD).normalized()
	_blob(bk, s1, Vector3(0.11, 0.035, 0.11), _bk(0.0, 0.8, 0.0, 0.0), Basis(bx, d, bx.cross(d)), 0.0, 8, 3)
	# a knot hollow on the right of the chest: a bark ring around a dark hole
	var kc := Vector3(0.25, 2.10, 0.575)
	var ring: Array[Vector3] = []
	for j: int in 17:
		var a := TAU * float(j) / 16.0
		ring.append(kc + Vector3(cos(a) * 0.14, sin(a) * 0.17, 0.0))
	_loft(bk, ring, _round(0.055, 0.055), _cbk(0.1, 0.15, 0.0), 6, 24)
	_blob(bk, kc + Vector3(0, 0, -0.03), Vector3(0.12, 0.15, 0.05), _bk(0.0, 1.0, 0.0, 0.0), Basis.IDENTITY, 0.0, 8, 4)
	return _bake([[bk, "bark"], [lf, "leaf"]])


# ---------------------------------------------------------------- head: bark face, moss beard, blossom crown

static func _head() -> ArrayMesh:
	var bk := Surf.new()
	var lf := Surf.new()
	var gl := Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 2.84, 0.20), Vector3(0, 3.10, 0.25), Vector3(0, 3.38, 0.23),
		Vector3(0, 3.60, 0.17)]
	var tab := [[0.0, 0.60, 0.52, 0.54], [0.45, 0.55, 0.50, 0.50], [0.8, 0.48, 0.44, 0.46], [1.0, 0.34, 0.30, 0.32]]
	_loft(bk, pts, _prof(tab), _cbk(0.2, 0.0, 0.5), 22, 12, 0.05, 2.2)
	_blob(bk, Vector3(0, 3.60, 0.17), Vector3(0.40, 0.16, 0.36), _bk(1.0, 0.0, 0.0), Basis.IDENTITY, 0.08, 12, 6, 1.1)
	for sx: float in [-1.0, 1.0]:
		# heavy mossy brows, drooping at the outer ends (an old, stern face)
		_blob(bk, Vector3(0.20 * sx, 3.35, 0.70), Vector3(0.21, 0.07, 0.11), _bk(1.0, 0.0, 0.0),
			Basis(Vector3.BACK, -0.26 * sx), 0.06, 10, 5, 3.0 + sx)
		# dark sockets and the glowing eyes
		_blob(bk, mx(EYE, sx) + Vector3(0, 0.0, -0.045), Vector3(0.13, 0.085, 0.05), _bk(0.0, 1.0, 0.0, 0.0),
			Basis(Vector3.UP, 0.3 * sx), 0.0, 10, 5)
		_blob(gl, mx(EYE, sx), Vector3(0.095, 0.06, 0.04), Color(EYE_GLOW.r, EYE_GLOW.g, EYE_GLOW.b, 0.0),
			Basis(Vector3.UP, 0.3 * sx) * Basis(Vector3.BACK, -0.12 * sx), 0.0, 10, 5)
		# cheek burls
		_blob(bk, Vector3(0.34 * sx, 3.02, 0.62), Vector3(0.15, 0.13, 0.12), _bk(0.4, 0.0, 0.0), Basis.IDENTITY, 0.08, 9, 5,
			6.0 + sx)
	_blob(bk, Vector3(0, 3.33, 0.73), Vector3(0.08, 0.09, 0.07), _bk(0.5, 0.0, 0.0), Basis.IDENTITY, 0.05, 8, 5)
	# a big knotty nose, a dark mouth slit
	_branch(bk, [Vector3(0, 3.28, 0.70), Vector3(0, 3.14, 0.83), Vector3(0, 3.03, 0.85)], 0.10, 0.08,
		_bk(0.0, 0.05, 0.0), 8, 5)
	_blob(bk, Vector3(0, 3.00, 0.84), Vector3(0.10, 0.08, 0.09), _bk(0.0, 0.1, 0.0), Basis.IDENTITY, 0.08, 9, 5, 2.0)
	_blob(bk, Vector3(0, 2.90, 0.72), Vector3(0.20, 0.045, 0.05), _bk(0.0, 1.0, 0.0, 0.0), Basis.IDENTITY, 0.0, 10, 4)
	# the moss beard: hanging strands over the chest (longest in the middle) and a drooping moustache
	for j: int in 9:
		var x0 := -0.36 + 0.09 * float(j)
		var cen := 1.0 - absf(x0) / 0.40
		var end_y := lerpf(2.38, 2.02, cen)
		var sp: Array[Vector3] = [Vector3(x0, 2.97 - 0.03 * (1.0 - cen), 0.70 + 0.02 * cen), Vector3(x0 * 1.05, 2.74, 0.85),
			Vector3(x0, 2.50, 0.86), Vector3(x0 * 0.92, end_y, 0.78 - 0.05 * (1.0 - cen))]
		var base_c: Color = MOSS_A if j % 2 == 0 else MOSS_B
		var w0 := 0.085 + 0.015 * cen
		var prof := func(v: float) -> Vector4:
			return Vector4(w0 * (1.0 - 0.6 * v) + 0.01, 0.035, 0.035, 0.0)
		var colf := func(_ca: float, v: float) -> Color:
			return base_c.lerp(MOSS_TIP, smoothstep(0.55, 1.0, v))
		_loft(lf, sp, prof, colf, 8, 9, 0.12, float(j))
	for sx: float in [-1.0, 1.0]:
		var sp: Array[Vector3] = [Vector3(0.05 * sx, 3.0, 0.86), Vector3(0.20 * sx, 2.95, 0.84),
			Vector3(0.31 * sx, 2.80, 0.79), Vector3(0.35 * sx, 2.62, 0.75)]
		var prof := func(v: float) -> Vector4:
			return Vector4(0.05 * (1.0 - 0.5 * v) + 0.01, 0.04, 0.04, 0.0)
		var colf := func(_ca: float, v: float) -> Color:
			return MOSS_B.lerp(MOSS_TIP, smoothstep(0.5, 1.0, v))
		_loft(lf, sp, prof, colf, 7, 8, 0.1, 3.0 + sx)
	# the blossom crown: short thick branches radiating from the crown, each carrying a leaf mass and blossoms
	var brs := [[-35.0, 52.0, 0.62, 0.30], [35.0, 52.0, 0.62, 0.30], [95.0, 36.0, 0.74, 0.32], [-95.0, 36.0, 0.74, 0.32],
		[150.0, 48.0, 0.58, 0.28], [-150.0, 48.0, 0.58, 0.28], [180.0, 66.0, 0.52, 0.27]]
	var leaf_cols: Array[Color] = [LEAF_A, LEAF_C, LEAF_B, LEAF_A, LEAF_C, LEAF_B, LEAF_A]
	var k := 0
	for b: Array in brs:
		var a := float(b[0]) * DEG
		var e := float(b[1]) * DEG
		var ln := float(b[2])
		var rr := float(b[3])
		var o := Vector3(sin(a), 0.0, cos(a))
		var base := CROWN_TOP + Vector3(o.x * 0.26, -0.04, o.z * 0.22)
		var dir := Vector3(o.x * cos(e), sin(e), o.z * cos(e))
		var p1 := base + dir * ln * 0.5 + Vector3(0, 0.06, 0)
		var p2 := base + dir * ln + Vector3(0, 0.12, 0)
		_branch(bk, [base, p1, p2], 0.12, 0.035, _bk(0.35, 0.0, 0.1), 7, 7, 0.06)
		var c := p2 + dir * 0.06 + Vector3(0, 0.04, 0)
		_leaf_mass(lf, c, Vector3(rr, rr * 0.74, rr * 0.92), leaf_cols[k], 10.0 + float(k))
		var up := (dir + Vector3.UP * 1.4).normalized()
		_blossom(lf, c + up * rr * 0.72 + o * 0.06, up, 0.27, PINK if k % 2 == 0 else PINK_PALE, float(k))
		if k < 6:
			_blossom(lf, c + (o * 0.8 + Vector3.UP * 0.5).normalized() * rr * 0.85, (o + Vector3.UP).normalized(), 0.23,
				PINK_PALE if k % 2 == 0 else PINK, float(k) + 0.5)
		k += 1
	_leaf_mass(lf, Vector3(0, 3.80, 0.10), Vector3(0.44, 0.28, 0.40), LEAF_A, 21.0)
	_blossom(lf, Vector3(0.10, 4.08, 0.16), Vector3(0.1, 1.0, 0.2), 0.28, PINK, 0.3)
	_blossom(lf, Vector3(-0.16, 4.04, -0.06), Vector3(-0.2, 1.0, -0.1), 0.25, PINK_PALE, 1.3)
	var marks := [[bk.v.size(), bk.i.size()], [lf.v.size(), lf.i.size()], [gl.v.size(), gl.i.size()]]
	_crown_canopy(bk, lf, gl)
	_bake_growth(P_HEAD, [bk, lf, gl], marks, ["bark", "leaf", "glow"])
	return _bake([[bk, "bark"], [lf, "leaf"], [gl, "glow"]])


## Rooted form only: the crown swells into the middle of the canopy (authored in the ROOTED pose of the head and
## mapped back), bridging the two arm canopies into one broad dome; blossoms on top, two pods underneath.
static func _crown_canopy(bk: Surf, lf: Surf, gl: Surf) -> void:
	var to_r := rest_to_rooted(P_HEAD)
	var k_bk := bk.v.size()
	var k_lf := lf.v.size()
	var k_gl := gl.v.size()
	var c := to_r * CROWN_TOP
	var masses := [[c + Vector3(0, 0.78, 0.05), Vector3(1.0, 0.56, 0.86), LEAF_A, 0.48],
		[c + Vector3(-1.0, 0.98, 0.12), Vector3(0.72, 0.50, 0.64), LEAF_C, 0.54],
		[c + Vector3(1.0, 0.98, 0.12), Vector3(0.72, 0.50, 0.64), LEAF_B, 0.54],
		[c + Vector3(0, 0.55, -0.62), Vector3(0.78, 0.46, 0.56), LEAF_B, 0.52]]
	var j := 0
	for ms: Array in masses:
		var mc: Vector3 = ms[0]
		var k0 := bk.v.size()
		_branch(bk, [c, c.lerp(mc, 0.5) + Vector3(0, 0.08, 0), mc], 0.10, 0.035, _bk(0.3, 0.0, 0.3), 7, 6, 0.05)
		bk.tag_along(k0, c, mc, 0.38, 0.14)
		var k1 := lf.v.size()
		_leaf_mass(lf, mc, ms[1], ms[2], 50.0 + float(j))
		lf.tag(k1, c, float(ms[3]))
		j += 1
	var bl := [[0, Vector3(0.2, 1.0, 0.25), PINK], [0, Vector3(-0.35, 0.9, -0.1), PINK_PALE], [0, Vector3(0.4, 0.8, -0.3), PINK],
		[1, Vector3(-0.3, 0.9, 0.3), PINK], [1, Vector3(0.1, 1.0, -0.2), PINK_PALE], [2, Vector3(0.3, 0.9, 0.3), PINK_PALE],
		[2, Vector3(-0.1, 1.0, -0.2), PINK], [3, Vector3(0.0, 0.9, -0.4), PINK_PALE]]
	j = 0
	for b: Array in bl:
		var ms: Array = masses[int(b[0])]
		var mc: Vector3 = ms[0]
		var r: Vector3 = ms[1]
		var dn := (b[1] as Vector3).normalized()
		var p := mc + Vector3(dn.x * r.x, dn.y * r.y, dn.z * r.z) * 0.98
		var k0 := lf.v.size()
		_blossom(lf, p, dn, 0.22, b[2], float(j) * 0.9)
		lf.tag(k0, p, 0.64 + 0.03 * float(j % 3))
		j += 1
	for sx: float in [-1.0, 1.0]:
		var ms: Array = masses[1 if sx < 0.0 else 2]
		var mc: Vector3 = ms[0]
		var top := mc + Vector3(0.2 * sx, -0.36, 0.2)
		var k_b := bk.v.size()
		var k_l := lf.v.size()
		var k_g := gl.v.size()
		_branch(bk, [top, top + Vector3(0.02, -0.07, 0.01), top + Vector3(0, -0.14, 0)], 0.035, 0.025, _bk(0.1, 0.0, 0.0), 5, 3)
		var pc := top + Vector3(0, -0.28, 0)
		_blob(gl, pc, Vector3(0.12, 0.17, 0.12), Color(POD_GLOW.r, POD_GLOW.g, POD_GLOW.b, 0.2 + 0.4 * sx), Basis.IDENTITY,
			0.0, 9, 6)
		_blob(lf, pc + Vector3(0, 0.13, 0), Vector3(0.10, 0.05, 0.10), LEAF_DARK, Basis.IDENTITY, 0.1, 7, 3)
		bk.tag(k_b, top, 0.58)
		lf.tag(k_l, top, 0.62)
		gl.tag(k_g, top, 0.62)
	var to_rest := to_r.affine_inverse()
	bk.xform_range(k_bk, to_rest)
	lf.xform_range(k_lf, to_rest)
	gl.xform_range(k_gl, to_rest)


# ---------------------------------------------------------------- arms

static func _upper_arm(sx: float) -> ArrayMesh:
	var bk := Surf.new()
	var lf := Surf.new()
	var s := Vector3(0.86 * sx, 2.80, 0.12)
	var e := mx(ELBOW, sx) + Vector3(0, -0.04, 0)
	_loft(bk, [s, s.lerp(e, 0.5) + Vector3(0.06 * sx, 0, 0), e], _round(0.27, 0.20), _cbk(0.3, 0.0, 0.4), 12, 8, 0.08,
		6.0 + sx)
	_blob(bk, e + Vector3(0.02 * sx, 0.02, -0.02), Vector3(0.22, 0.21, 0.22), _bk(0.4, 0.0, 0.2), Basis.IDENTITY, 0.08,
		10, 6, 7.0 + sx)
	var t0 := Vector3(1.00 * sx, 2.55, -0.05)
	var t1 := Vector3(1.12 * sx, 2.84, -0.18)
	_branch(bk, [t0, t0.lerp(t1, 0.5) + Vector3(0.02 * sx, 0, 0), t1], 0.06, 0.02, _bk(0.2, 0.0, 0.0), 6, 5)
	_leaf_mass(lf, t1 + Vector3(0.02 * sx, 0.06, -0.02), Vector3(0.18, 0.13, 0.17), LEAF_A, 5.0 + sx)
	return _bake([[bk, "bark"], [lf, "leaf"]])


## Forearm, the branch hand (four twig fingers with hooked tips) and, grown only in the rooted form, the canopy.
static func _forearm(sx: float) -> ArrayMesh:
	var bk := Surf.new()
	var lf := Surf.new()
	var gl := Surf.new()
	var e := mx(ELBOW, sx)
	var w := mx(WRIST, sx)
	_loft(bk, [e, Vector3(1.22 * sx, 1.56, 0.40), w], _round(0.19, 0.26), _cbk(0.25, 0.0, 0.4), 12, 8, 0.09, 8.0 + sx)
	_blob(bk, w + Vector3(0, -0.04, 0.02), Vector3(0.27, 0.23, 0.28), _bk(0.35, 0.0, 0.2), Basis.IDENTITY, 0.1, 10, 6,
		9.0 + sx)
	var h := mx(HAND, sx)
	for f: int in 4:
		var t := mx(FINGERS[f], sx)
		var mid := h.lerp(t, 0.5) + Vector3(0, 0.02, 0.07)
		var hook := t + (t - h).normalized() * 0.1 + Vector3(0, -0.02, 0.06)
		_branch(bk, [h, mid, t, hook], 0.09 if f == 3 else 0.10, 0.022, _bk(0.1, 0.1, 0.0), 7, 8, 0.06)
		_blob(bk, h.lerp(t, 0.42), Vector3(0.085, 0.085, 0.085), _bk(0.2, 0.0, 0.0), Basis.IDENTITY, 0.05, 7, 4)
	var u0 := Vector3(1.30 * sx, 1.66, 0.28)
	var u1 := Vector3(1.46 * sx, 1.84, 0.12)
	_branch(bk, [u0, u0.lerp(u1, 0.5), u1], 0.06, 0.02, _bk(0.2, 0.0, 0.0), 6, 4)
	_leaf_mass(lf, u1 + Vector3(0.02 * sx, 0.04, -0.02), Vector3(0.20, 0.14, 0.18), LEAF_C, 7.0 + sx)
	var marks := [[bk.v.size(), bk.i.size()], [lf.v.size(), lf.i.size()], [gl.v.size(), gl.i.size()]]
	_canopy(bk, lf, gl, sx)
	_bake_growth(P_FORE_L if sx < 0.0 else P_FORE_R, [bk, lf, gl], marks, ["bark", "leaf", "glow"])
	return _bake([[bk, "bark"], [lf, "leaf"], [gl, "glow"]])


## The rooted canopy of one arm, authored in the ROOTED pose and mapped back into the forearm's rest space: twigs
## sprout from the wrist and the forearm (morph 0.36-0.6), leaf masses swell from them (0.44-0.72), blossoms open
## on top (0.64-0.94), glowing seed pods swell underneath (0.6-0.98).
static func _canopy(bk: Surf, lf: Surf, gl: Surf, sx: float) -> void:
	var fi := P_FORE_L if sx < 0.0 else P_FORE_R
	var to_r := rest_to_rooted(fi)
	var to_rest := to_r.affine_inverse()
	var k_bk := bk.v.size()
	var k_lf := lf.v.size()
	var k_gl := gl.v.size()
	var w := to_r * mx(WRIST, sx)
	var e := to_r * mx(ELBOW, sx)
	var m := e.lerp(w, 0.5)
	var tm := Vector3.ZERO
	for f: int in 3:
		tm += to_r * mx(FINGERS[f], sx)
	tm /= 3.0
	# twigs
	var twigs := [[w, Vector3(0.40 * sx, 0.62, 0.05), 0.09, 0.36], [w, Vector3(-0.12 * sx, 0.66, -0.30), 0.08, 0.40],
		[w, Vector3(0.18 * sx, 0.50, 0.42), 0.08, 0.40], [m, Vector3(0.10 * sx, 0.55, -0.22), 0.07, 0.38],
		[tm, Vector3(0.22 * sx, 0.40, 0.10), 0.06, 0.42]]
	for tw: Array in twigs:
		var b0: Vector3 = tw[0]
		var b1: Vector3 = b0 + (tw[1] as Vector3)
		var k0 := bk.v.size()
		_branch(bk, [b0, b0.lerp(b1, 0.5) + Vector3(0.05 * sx, 0.04, 0.0), b1], float(tw[2]), 0.025, _bk(0.3, 0.0, 0.3),
			7, 6, 0.05)
		bk.tag_along(k0, b0, b1, float(tw[3]), 0.2)
	# leaf masses: [centre, radii, anchor, start, colour]
	var masses := [[w + Vector3(0.12 * sx, 0.64, 0.0), Vector3(0.86, 0.58, 0.76), w, 0.46, LEAF_A],
		[tm + Vector3(0.10 * sx, 0.40, 0.0), Vector3(0.74, 0.52, 0.68), tm, 0.50, LEAF_C],
		[m + Vector3(0.0, 0.58, -0.18), Vector3(0.62, 0.42, 0.54), m, 0.44, LEAF_B],
		[w + Vector3(0.64 * sx, 0.20, 0.08), Vector3(0.58, 0.42, 0.54), w, 0.52, LEAF_A],
		[w + Vector3(0.06 * sx, 0.30, 0.56), Vector3(0.44, 0.32, 0.40), w, 0.55, LEAF_C],
		[w + Vector3(-0.24 * sx, 0.36, -0.52), Vector3(0.44, 0.32, 0.40), w, 0.55, LEAF_B]]
	var j := 0
	for ms: Array in masses:
		var c: Vector3 = ms[0]
		var r: Vector3 = ms[1]
		var k0 := lf.v.size()
		_leaf_mass(lf, c, r, ms[4], 30.0 + float(j) + sx)
		lf.tag(k0, ms[2], float(ms[3]))
		j += 1
	# blossoms on the tops
	var bl := [[0, Vector3(0.2, 0.95, 0.1), PINK], [0, Vector3(-0.35, 0.85, -0.2), PINK_PALE], [1, Vector3(0.1, 0.95, 0.2), PINK_PALE],
		[1, Vector3(0.45, 0.8, -0.15), PINK], [3, Vector3(0.5, 0.8, 0.2), PINK_PALE], [4, Vector3(0.0, 0.8, 0.55), PINK],
		[2, Vector3(-0.1, 0.9, -0.3), PINK]]
	j = 0
	for b: Array in bl:
		var ms: Array = masses[int(b[0])]
		var c: Vector3 = ms[0]
		var r: Vector3 = ms[1]
		var dv: Vector3 = b[1]
		var dn := Vector3(dv.x * sx, dv.y, dv.z).normalized()
		var p := c + Vector3(dn.x * r.x, dn.y * r.y, dn.z * r.z) * 0.98
		var k0 := lf.v.size()
		_blossom(lf, p, dn, 0.22, b[2], float(j) * 0.7)
		lf.tag(k0, p, 0.64 + 0.04 * float(j % 3))
		j += 1
	# seed pods hanging under the masses: [mass, offset x/z]
	var pods := [[0, Vector2(0.28, 0.18)], [0, Vector2(-0.22, -0.2)], [1, Vector2(0.1, 0.1)], [3, Vector2(0.15, -0.05)],
		[4, Vector2(-0.05, 0.12)], [5, Vector2(0.05, -0.1)]]
	j = 0
	for pd: Array in pods:
		var ms: Array = masses[int(pd[0])]
		var c: Vector3 = ms[0]
		var r: Vector3 = ms[1]
		var o: Vector2 = pd[1]
		var top := c + Vector3(o.x * sx, -r.y * 0.72, o.y)
		var hang := 0.12 + 0.06 * float(j % 2)
		var k_b := bk.v.size()
		var k_l := lf.v.size()
		var k_g := gl.v.size()
		_branch(bk, [top, top + Vector3(0.02, -hang * 0.5, 0.01), top + Vector3(0, -hang, 0)], 0.035, 0.025,
			_bk(0.1, 0.0, 0.0), 5, 3)
		var pc := top + Vector3(0, -hang - 0.14, 0)
		_blob(gl, pc, Vector3(0.12, 0.17, 0.12), Color(POD_GLOW.r, POD_GLOW.g, POD_GLOW.b, fmod(0.37 * float(j), 1.0)),
			Basis.IDENTITY, 0.0, 9, 6)
		_blob(lf, pc + Vector3(0, 0.13, 0), Vector3(0.10, 0.05, 0.10), LEAF_DARK, Basis.IDENTITY, 0.1, 7, 3)
		var st := 0.60 + 0.03 * float(j % 3)
		bk.tag(k_b, top, st - 0.04)
		lf.tag(k_l, top, st)
		gl.tag(k_g, top, st)
		j += 1
	bk.xform_range(k_bk, to_rest)
	lf.xform_range(k_lf, to_rest)
	gl.xform_range(k_gl, to_rest)


# ---------------------------------------------------------------- the ground roots (rooted form only)

static func _spread() -> ArrayMesh:
	var bk := Surf.new()
	var lf := Surf.new()
	# where the sunk, splayed legs enter the ground: a root collar each
	for li: int in [P_SHIN_L, P_SHIN_R]:
		var hip := pose_xf(PARENT[li]).origin
		var knee := pose_xf(li).origin
		var g := knee
		if knee.y < 0.0 and hip.y > 0.0:
			g = hip.lerp(knee, hip.y / (hip.y - knee.y))
		var k0 := bk.v.size()
		_blob(bk, Vector3(g.x, -0.02, g.z), Vector3(0.46, 0.28, 0.46), _bk(0.5, 0.0, 0.4), Basis.IDENTITY, 0.1, 12, 6,
			g.x)
		bk.tag(k0, Vector3(g.x, -0.3, g.z), 0.06)
	var k1 := bk.v.size()
	_blob(bk, Vector3(0, -0.06, 0.02), Vector3(0.95, 0.32, 0.82), _bk(0.6, 0.0, 0.5), Basis.IDENTITY, 0.1, 16, 6, 4.0)
	bk.tag(k1, Vector3(0, -0.36, 0.02), 0.03)
	# eleven roots radiating out, arching over the ground and diving in; every other one forks
	for k: int in 11:
		var a := TAU * float(k) / 11.0 + 0.3 * sin(float(k) * 2.3)
		var o := Vector3(sin(a), 0.0, cos(a))
		var pp := Vector3(cos(a), 0.0, -sin(a))
		var ln := 1.45 + 0.8 * fmod(float(k) * 0.618, 1.0)
		var base := Vector3(o.x * 0.62, 0.14, o.z * 0.55)
		var p1 := base + o * ln * 0.3 + Vector3(0, 0.12, 0)
		var p2 := base + o * ln * 0.62 + pp * 0.14 * sin(float(k) * 1.7) + Vector3(0, 0.05, 0)
		var p3 := base + o * ln + pp * 0.1 * cos(float(k)) + Vector3(0, -0.14, 0)
		var k0 := bk.v.size()
		_branch(bk, [base, p1, p2, p3], 0.20 - 0.04 * fmod(float(k) * 0.37, 1.0), 0.04, _bk(0.22, 0.05, 0.8), 8, 10,
			0.07)
		bk.tag_along(k0, base, p3, 0.08 + 0.02 * float(k % 3), 0.45)
		if k % 2 == 0:
			var fb := p1.lerp(p2, 0.5)
			var fd := (o * cos(0.6) + pp * sin(0.6) * (1.0 if k % 4 == 0 else -1.0)).normalized()
			var f1 := fb + fd * 0.62 + Vector3(0, -0.12, 0)
			var k2 := bk.v.size()
			_branch(bk, [fb, fb.lerp(f1, 0.5) + Vector3(0, 0.06, 0), f1], 0.09, 0.02, _bk(0.2, 0.05, 0.5), 6, 6)
			bk.tag_along(k2, fb, f1, 0.36, 0.25)
	# moss mounds and a few blossoms: the grove wakes around it
	for k: int in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		var c := Vector3(sin(a) * 1.05, 0.0, cos(a) * 0.95)
		var k0 := lf.v.size()
		_blob(lf, c, Vector3(0.28, 0.09, 0.24), MOSS_B if k % 2 == 0 else LEAF_DARK, Basis.IDENTITY, 0.15, 9, 4, float(k))
		lf.tag(k0, c - Vector3(0, 0.1, 0), 0.45)
	for k: int in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		var c := Vector3(sin(a) * (1.45 + 0.15 * float(k % 2)), 0.0, cos(a) * (1.35 + 0.2 * float(k % 2)))
		var k0 := bk.v.size()
		_branch(bk, [c, c + Vector3(0.02, 0.12, 0.0), c + Vector3(0.0, 0.24, 0.02)], 0.025, 0.018, _bk(0.2, 0.0, 0.0), 5, 3)
		bk.tag(k0, c, 0.6)
		var k2 := lf.v.size()
		_blob(lf, c + Vector3(0, 0.03, 0), Vector3(0.14, 0.05, 0.12), LEAF_B, Basis.IDENTITY, 0.1, 7, 3)
		_blossom(lf, c + Vector3(0, 0.26, 0.02), Vector3(0.1, 1.0, 0.15), 0.13, PINK if k % 2 == 0 else PINK_PALE, float(k))
		lf.tag(k2, c, 0.64)
	return _bake([[bk, "bark"], [lf, "leaf"]])


# ================================================================ builder helpers

static func _bk(moss: float, dark: float, sap: float, furrow: float = 1.0) -> Color:
	return Color(moss, dark, sap, furrow)


static func _cbk(moss: float, dark: float, sap: float, furrow: float = 1.0) -> Callable:
	var col := Color(moss, dark, sap, furrow)
	return func(_ca: float, _v: float) -> Color:
		return col


## Profile table rows [v, side, front, back] -> Callable(v) -> Vector4(side, front, back, 0).
static func _prof(tab: Array) -> Callable:
	return func(v: float) -> Vector4:
		var r0: Array = tab[0]
		if v <= float(r0[0]):
			return Vector4(r0[1], r0[2], r0[3], 0.0)
		for k: int in range(1, tab.size()):
			var r1: Array = tab[k]
			if v <= float(r1[0]):
				var a := (v - float(r0[0])) / maxf(float(r1[0]) - float(r0[0]), 0.0001)
				a = a * a * (3.0 - 2.0 * a)
				return Vector4(lerpf(r0[1], r1[1], a), lerpf(r0[2], r1[2], a), lerpf(r0[3], r1[3], a), 0.0)
			r0 = r1
		return Vector4(r0[1], r0[2], r0[3], 0.0)


static func _round(r0: float, r1: float) -> Callable:
	return func(v: float) -> Vector4:
		var r := lerpf(r0, r1, v)
		return Vector4(r, r, r, 0.0)


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


## Grid p = fn(u, v): normals by finite differences, turned away from ctr(u, v).
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
			s.add(p, nn, uvf.call(u, v), col.call(u, v))
	for j: int in rows:
		for i: int in cols:
			var q0 := base + j * (cols + 1) + i
			s.quad(q0, q0 + 1, q0 + cols + 2, q0 + cols + 1)


## Tube along a Catmull-Rom spine. prof(v) -> Vector4(side radius, front radius (u = 0 side), back radius, ridge).
## Vertical spines: u = 0 faces +Z; horizontal ones: u = 0 faces up. UV.x = u x an integer number of bark tiles (no
## seam), UV.y = metres along. lump: organic bumps (periodic around, so no seam either). col(cos_around, v) -> Color.
static func _loft(s: Surf, pts: Array[Vector3], prof: Callable, col: Callable, ring: int, samples: int,
		lump: float = 0.0, seed: float = 0.0) -> void:
	var total := 0.0
	for k: int in pts.size() - 1:
		total += pts[k].distance_to(pts[k + 1])
	var chord := (pts[pts.size() - 1] - pts[0])
	if chord.length_squared() < 1e-6:
		chord = pts[1] - pts[0]
	chord = chord.normalized()
	var ref := Vector3.BACK if absf(chord.y) > 0.6 else Vector3.UP
	var pr_mid: Vector4 = prof.call(0.5)
	var tiles := float(maxi(2, roundi(TAU * (pr_mid.x + pr_mid.y) * 0.5 / 0.32)))
	var frame := func(v: float) -> Array:
		var tn := (_cr(pts, minf(v + 0.01, 1.0)) - _cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var x := ref.cross(tn)
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
		var k := 1.0 + lump * (0.6 * sin(5.0 * a + v * total * 2.3 + seed) + 0.4 * sin(3.0 * a - v * total * 3.1 + seed * 1.7))
		return _cr(pts, v) + (fr[0] as Vector3) * (pr.x * sin(a) * k) + (fr[1] as Vector3) * (ry * ca * k
			+ pr.w * pow(maxf(ca, 0.0), 10.0))
	var ctr := func(_u: float, v: float) -> Vector3:
		return _cr(pts, v)
	var colf := func(u: float, v: float) -> Color:
		return col.call(cos(TAU * u), v)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * tiles, v * total)
	_grid(s, fn, ctr, colf, uvf, ring, samples)


## Tapered round branch / root / claw along pts (r0 at the base, r1 at the tip).
static func _branch(s: Surf, pts: Array[Vector3], r0: float, r1: float, col: Color, ring: int = 7, samples: int = 6,
		lump: float = 0.0) -> void:
	var prof := func(v: float) -> Vector4:
		var r := lerpf(r0, r1, pow(v, 0.9)) + 0.003
		return Vector4(r, r, r, 0.0)
	_loft(s, pts, prof, func(_ca: float, _v: float) -> Color: return col, ring, samples, lump, r0 * 37.0)


## Lumpy ellipsoid at c (radii r, rotated by b).
static func _blob(s: Surf, c: Vector3, r: Vector3, col: Color, b: Basis = Basis.IDENTITY, lump: float = 0.03,
		cols: int = 10, rows: int = 6, seed: float = 0.0) -> void:
	var tiles := float(maxi(2, roundi(TAU * maxf(r.x, r.z) / 0.32)))
	var fn := func(u: float, v: float) -> Vector3:
		var a := TAU * u
		var th := PI * v
		var k := 1.0 + lump * sin(5.0 * a + 1.3 + seed) * sin(3.0 * th + 0.4 + seed * 0.7)
		return c + b * Vector3(sin(th) * sin(a) * r.x * k, cos(th) * r.y * k, sin(th) * cos(a) * r.z * k)
	var ctr := func(_u: float, _v: float) -> Vector3:
		return c
	var colf := func(_u: float, _v: float) -> Color:
		return col
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * tiles, v * PI * r.y)
	_grid(s, fn, ctr, colf, uvf, cols, rows)


## A cloud-like leaf mass: a lumpy core and three puffs on its upper half.
static func _leaf_mass(s: Surf, c: Vector3, r: Vector3, col: Color, seed: float) -> void:
	_blob(s, c, r, col, Basis.IDENTITY, 0.13, 12, 7, seed)
	for j: int in 3:
		var ang := seed * 2.3 + TAU * float(j) / 3.0
		var off := Vector3(cos(ang) * r.x * 0.6, r.y * (0.30 + 0.18 * float(j % 2)), sin(ang) * r.z * 0.6)
		var pc := col.lightened(0.06) if j == 0 else (col.darkened(0.05) if j == 1 else col)
		pc.a = col.a
		_blob(s, c + off, r * (0.48 + 0.05 * float(j)), pc, Basis.IDENTITY, 0.1, 8, 5, seed + float(j))


## A five-petal blossom facing `dir`: a cupped star (tips raised) with a back face and a small golden heart.
static func _blossom(s: Surf, c: Vector3, dir: Vector3, size: float, col: Color, spin: float = 0.0) -> void:
	var d := dir.normalized()
	var a := d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var b := d.cross(a).normalized()
	var pc := Color(col.r, col.g, col.b, 0.5)
	for side: int in 2:
		var sd := 1.0 if side == 0 else -1.0
		var k0 := s.v.size()
		s.add(c + d * size * (0.10 if side == 0 else 0.02), d * sd, Vector2(0.5, 0.5), pc)
		for j: int in 10:
			var ang := spin + TAU * float(j) / 10.0
			var tip := j % 2 == 0
			var rr := size if tip else size * 0.42
			var radial := a * cos(ang) + b * sin(ang)
			var p := c + radial * rr + d * size * (0.18 if tip else 0.04)
			var nrm := (d * sd + radial * 0.25 * sd).normalized()
			s.add(p, nrm, Vector2(0.5 + 0.5 * cos(ang), 0.5 + 0.5 * sin(ang)), pc)
		for j: int in 10:
			s.tri(k0, k0 + 1 + j, k0 + 1 + (j + 1) % 10, d * sd)
	_blob(s, c + d * size * 0.14, Vector3(size * 0.22, size * 0.12, size * 0.22), HEART, Basis(a, d, b), 0.0, 6, 3)

