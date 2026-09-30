extends RefCounted
## Briar Roc geometry (Nature T3 flyer, tiers wave). Reuses the Roc's rig anatomy and mesh helpers (roc_mesh.gd: loft,
## blob, blade, panel, horn) with its own shapes and materials. MODEL space: face +Z, body centre at y 4.0
## (FlyerModel.BAKE_HEIGHT); briar_roc.gd scales the whole bird to a 5 m wingspan. Right side authored, left mirrored.
## Vertex COLOR (briar_feather.gdshader = roc_feather + team tint): r feather / bark-plate rows, g pale blend, b dark
## tip blend, a shaft line.
## Shape language (40 m read): a raptor of BARK and THORN: bark body with a ridge of pale thorns down the spine, a mantle
## of team leaves over the shoulders, wings of dry-leaf coverts with a thorned bark leading edge ending in long pointed
## LEAF primaries (outer ones team-coloured), a fan of leaf tail feathers, a bark head with a pale thorn beak and a
## branching ANTLER CREST whose two tips carry glowing seed buds (the glow point), and a big seed-pod belly with
## glowing seed slits.

const RM := preload("res://art/units/neutral/beasts/roc/roc_mesh.gd")
const MAT_DIR := "res://art/units/nature/briar_roc/materials/"
const BARK := "briar_bark"
const DRY := "briar_dryleaf"
const LEAF := "briar_leaf"
const THORN := "briar_thorn"
const GLOW := "res://art/units/nature/materials/nature_glow.tres"
const DEG := PI / 180.0
const POD_C := Vector3(0.0, 3.76, 0.02)

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}


static func mat(nm: String) -> Material:
	if not _mats.has(nm):
		_mats[nm] = load(nm if nm.begins_with("res://") else MAT_DIR + nm + ".tres")
	return _mats[nm]


static func bake(key: String, groups: Array) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	for g: Array in groups:
		var s: RM.Surf = g[0]
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
		am.surface_set_material(am.get_surface_count() - 1, mat(String(g[1])))
	_meshes[key] = am
	return am


## A pointed leaf blade width profile (widest at 40 %, sharp tip).
static func leaf_w(wmax: float) -> Callable:
	return func(v: float) -> float:
		return wmax * (0.35 + 0.65 * sin(PI * clampf(v * 1.1, 0.0, 1.0))) * (1.0 - smoothstep(0.7, 1.0, v)) + 0.004


static func leaf_top() -> Callable:
	return func(_u: float, v: float) -> Color:
		return Color(0.0, 0.0, 0.45 * smoothstep(0.82, 1.0, v), 1.0)


static func leaf_bot() -> Callable:
	return func(_u: float, v: float) -> Color:
		return Color(0.0, 0.3, 0.4 * smoothstep(0.82, 1.0, v), 0.6)


static func thorn_col() -> Callable:
	return func(v: float) -> Color:
		return Color(0.0, 0.3 * (1.0 - v), 0.8 * smoothstep(0.55, 1.0, v), 0.0)


# ================================================================ meshes

## Body: bark hull (bark-plate rows), a ridge of pale thorns down the spine, a mantle of team leaves over the shoulders,
## the seed pod belly (pale bone husk split by glowing seed slits).
static func body_mesh() -> ArrayMesh:
	if _meshes.has("body"):
		return _meshes["body"]
	var bk := RM.Surf.new()
	var lf := RM.Surf.new()
	var th := RM.Surf.new()
	var gl := RM.Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.12, 0.80), Vector3(0, 4.06, 0.50), Vector3(0, 3.99, 0.12),
		Vector3(0, 3.97, -0.30), Vector3(0, 4.00, -0.66), Vector3(0, 4.04, -1.00)]
	var tab := [[0.0, 0.26, 0.26, 0.26, 0.0], [0.18, 0.40, 0.34, 0.40, 0.0], [0.38, 0.44, 0.34, 0.42, 0.0],
		[0.62, 0.38, 0.30, 0.36, 0.0], [0.85, 0.24, 0.19, 0.18, 0.0], [1.0, 0.10, 0.08, 0.07, 0.0]]
	var prof := func(v: float) -> Vector4:
		return RM.table(tab, v)
	var col := func(ca: float, _v: float) -> Color:
		return Color(0.9, 0.0, 0.35 * smoothstep(-0.2, -0.8, ca), 0.0)
	RM.loft(bk, pts, prof, col, 14, 10, Vector3.RIGHT, 2.2)
	# spine thorns (pale, raked back), largest over the shoulders
	var tc := thorn_col()
	for k: int in 6:
		var z: float = 0.52 - 0.28 * float(k)
		var h: float = 0.30 - 0.035 * float(k)
		var base := Vector3(0.0, 4.30 - 0.02 * float(k), z)
		RM.horn(th, [base, base + Vector3(0, h * 0.6, -h * 0.25), base + Vector3(0, h, -h * 0.6)], 0.06, 0.006, tc, 5, 3,
			Vector3.RIGHT)
	# the leaf mantle: two rows of team leaves lying back over each shoulder
	var lt := leaf_top()
	var lb := leaf_bot()
	for sx: float in [-1.0, 1.0]:
		for k: int in 4:
			var a := float(k) / 3.0
			var b := Vector3((0.16 + 0.10 * a) * sx, 4.30 - 0.05 * a, 0.46 - 0.16 * a)
			var d := Vector3((0.35 + 0.35 * a) * sx, -0.18, -1.0).normalized()
			var ln: float = 0.56 - 0.06 * a
			var p: Array[Vector3] = [b, b + d * ln * 0.5 + Vector3(0, 0.04, 0), b + d * ln]
			RM.blade(lf, p, leaf_w(0.20), Vector3(0.3 * sx, 1.0, 0.0).normalized(), 0.03, lt, lb, 6)
	# seed pod belly: a husk with six seams; glowing seed slits between them
	var husk := func(d: Vector3) -> Color:
		var seam := absf(sin(atan2(d.x, d.y + 1.2) * 3.0))
		return Color(0.0, 0.25 + 0.3 * seam, 0.35 * (1.0 - seam), 0.0)
	RM.blob(th, POD_C, Vector3(0.30, 0.22, 0.44), husk, Basis(Vector3.RIGHT, 0.12), 0.04, 12, 7)
	for k: int in 4:
		var sx: float = -1.0 if k < 2 else 1.0
		var zz: float = 0.16 if k % 2 == 0 else -0.14
		RM.blob(gl, POD_C + Vector3(0.24 * sx, -0.06, zz), Vector3(0.035, 0.05, 0.12), RM.flat_col(Color.WHITE),
			Basis(Vector3.FORWARD, 0.5 * sx), 0.0, 6, 4)
	return bake("body", [[bk, BARK], [lf, LEAF], [th, THORN], [gl, GLOW]])


## Lower neck: bark with a ruff of thorn hackles pointing back.
static func neck1_mesh() -> ArrayMesh:
	if _meshes.has("neck1"):
		return _meshes["neck1"]
	var bk := RM.Surf.new()
	var th := RM.Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.06, 0.56), Vector3(0, 4.20, 0.76), Vector3(0, 4.34, 0.94)]
	RM.loft(bk, pts, RM.round_prof(0.30, 0.23), RM.flat_col2(Color(0.8, 0.0, 0.1, 0.0)), 12, 6, Vector3.RIGHT, 1.6)
	var tc := thorn_col()
	for k: int in 5:
		var a := lerpf(-95.0, 95.0, float(k) / 4.0) * DEG
		var c := RM.cr(pts, 0.6)
		var outw := Vector3(sin(a), cos(a) * 0.9, -0.15).normalized()
		var base := c + outw * 0.22
		var tip := base + (Vector3(0.0, 0.1, -1.0) * 0.8 + outw * 0.5).normalized() * 0.30
		RM.horn(th, [base, base.lerp(tip, 0.5) + outw * 0.02, tip], 0.05, 0.006, tc, 5, 3, Vector3.UP)
	return bake("neck1", [[bk, BARK], [th, THORN]])


static func neck2_mesh() -> ArrayMesh:
	if _meshes.has("neck2"):
		return _meshes["neck2"]
	var bk := RM.Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.28, 0.86), Vector3(0, 4.42, 1.00), Vector3(0, 4.52, 1.12)]
	var col := func(ca: float, _v: float) -> Color:
		return Color(0.6, 0.3 * smoothstep(0.1, -0.5, ca), 0.0, 0.0)
	RM.loft(bk, pts, RM.round_prof(0.24, 0.20), col, 12, 5, Vector3.RIGHT, 1.3)
	return bake("neck2", [[bk, BARK]])


## Head: bark skull with a pale face, dark brow ridges (the eyes: briar_roc.gd's FaceKit rig), a pale hooked thorn beak, the ANTLER CREST (two
## branching bark antlers with pale tines, a glowing seed bud on each main tip) and three leaves behind.
static func head_mesh() -> ArrayMesh:
	if _meshes.has("head"):
		return _meshes["head"]
	var bk := RM.Surf.new()
	var th := RM.Surf.new()
	var lf := RM.Surf.new()
	var gl := RM.Surf.new()
	var skull := func(d: Vector3) -> Color:
		return Color(0.5, 0.45 * smoothstep(0.1, -0.4, d.y), 0.0, 0.0)
	RM.blob(bk, Vector3(0.0, 4.60, 1.15), Vector3(0.20, 0.19, 0.26), skull, Basis(Vector3.RIGHT, -0.12), 0.03, 12, 7)
	for sx: float in [-1.0, 1.0]:
		RM.blob(bk, Vector3(0.115 * sx, 4.69, 1.27), Vector3(0.075, 0.045, 0.15), RM.flat_col(Color(0.0, 0.0, 0.7, 0.0)),
			Basis(Vector3.UP, 0.25 * sx) * Basis(Vector3.FORWARD, 0.35 * sx), 0.02, 7, 4)
		# (the dark eye blobs are gone: FaceKit paints the eyes, briar_roc.gd, face rework 2026-09-28)
	# hooked thorn beak
	var bpts: Array[Vector3] = [Vector3(0, 4.605, 1.34), Vector3(0, 4.60, 1.49), Vector3(0, 4.555, 1.60),
		Vector3(0, 4.47, 1.67), RM.BEAK_TIP]
	var btab := [[0.0, 0.10, 0.09, 0.065, 0.0], [0.35, 0.075, 0.07, 0.045, 0.0], [0.65, 0.05, 0.05, 0.03, 0.0],
		[0.88, 0.028, 0.03, 0.02, 0.0], [1.0, 0.006, 0.006, 0.006, 0.0]]
	var bprof := func(v: float) -> Vector4:
		return RM.table(btab, v)
	var bcol := func(_ca: float, v: float) -> Color:
		return Color(0.0, 0.5 * smoothstep(0.4, 1.0, v), 0.35 * (1.0 - smoothstep(0.0, 0.25, v)), 0.0)
	RM.loft(th, bpts, bprof, bcol, 8, 8)
	# antler crest: main beam up and back, two pale tines, a seed bud (glow) on the tip
	var tc := thorn_col()
	var beam_col := func(v: float) -> Color:
		return Color(0.4, 0.0, 0.3 * (1.0 - v), 0.0)
	for sx: float in [-1.0, 1.0]:
		var b0 := Vector3(0.08 * sx, 4.74, 1.14)
		var b1 := Vector3(0.17 * sx, 4.92, 1.02)
		var b2 := Vector3(0.24 * sx, 5.05, 0.84)
		var b3 := Vector3(0.27 * sx, 5.10, 0.64)
		RM.horn(bk, [b0, b1, b2, b3], 0.05, 0.02, beam_col, 6, 6, Vector3.FORWARD)
		RM.horn(th, [b1, b1 + Vector3(0.02 * sx, 0.10, 0.04), b1 + Vector3(0.05 * sx, 0.20, 0.03)], 0.025, 0.004, tc, 5, 3)
		RM.horn(th, [b2, b2 + Vector3(0.07 * sx, 0.08, 0.02), b2 + Vector3(0.16 * sx, 0.13, -0.01)], 0.022, 0.004, tc, 5, 3)
		RM.blob(gl, b3 + Vector3(0.01 * sx, 0.03, -0.02), Vector3(0.085, 0.085, 0.095), RM.flat_col(Color.WHITE),
			Basis.IDENTITY, 0.0, 7, 5)
	# the crown bud between the antlers (the brightest seed)
	RM.blob(gl, Vector3(0.0, 4.86, 1.02), Vector3(0.10, 0.10, 0.11), RM.flat_col(Color.WHITE), Basis.IDENTITY, 0.0, 8, 5)
	RM.horn(bk, [Vector3(0.0, 4.72, 1.10), Vector3(0.0, 4.80, 1.05), Vector3(0.0, 4.84, 1.03)], 0.05, 0.035, beam_col, 6, 3,
		Vector3.FORWARD)
	# three leaves behind the crown
	var lt := leaf_top()
	var lb := leaf_bot()
	for k: int in [-1, 0, 1]:
		var kk := float(k)
		var b := Vector3(0.06 * kk, 4.72, 1.02)
		var p: Array[Vector3] = [b, b + Vector3(0.08 * kk, 0.10, -0.18), b + Vector3(0.14 * kk, 0.14, -0.40)]
		RM.blade(lf, p, leaf_w(0.14), Vector3(0.4 * kk, 1.0, 0.0).normalized(), 0.025, lt, lb, 5)
	return bake("head", [[bk, BARK], [th, THORN], [lf, LEAF], [gl, GLOW]])


static func jaw_mesh() -> ArrayMesh:
	if _meshes.has("jaw"):
		return _meshes["jaw"]
	var th := RM.Surf.new()
	var pts: Array[Vector3] = [Vector3(0, 4.525, 1.36), Vector3(0, 4.505, 1.47), Vector3(0, 4.475, 1.57)]
	var tab := [[0.0, 0.08, 0.025, 0.05, 0.0], [0.7, 0.05, 0.02, 0.035, 0.0], [1.0, 0.012, 0.01, 0.01, 0.0]]
	var prof := func(v: float) -> Vector4:
		return RM.table(tab, v)
	RM.loft(th, pts, prof, RM.flat_col2(Color(0.0, 0.3, 0.2, 0.0)), 8, 5)
	return bake("jaw", [[th, THORN]])


## Arm part of a wing: a bark leading edge with forward thorns and the inner wing of dry-leaf coverts (rows, a
## scalloped trailing edge, a dark trailing band); underside pale straw.
static func wing_arm_mesh(sx: float) -> ArrayMesh:
	var key := "wing_arm%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var bk := RM.Surf.new()
	var dr := RM.Surf.new()
	var th := RM.Surf.new()
	var s := RM.mx(RM.SHOULDER, sx)
	var e := RM.mx(RM.ELBOW, sx)
	var w := RM.mx(RM.WRIST, sx)
	var rt := RM.mx(RM.ROOT_TRAIL, sx)
	var wt := RM.mx(RM.WRIST_TRAIL, sx)
	var lead: Array[Vector3] = [s + Vector3(-0.06 * sx, -0.02, 0.02), e + Vector3(0, 0.03, 0.02), w]
	RM.loft(bk, lead, RM.round_prof(0.10, 0.07), RM.flat_col2(Color(0.8, 0.0, 0.2, 0.0)), 7, 8, Vector3.FORWARD, 0.5)
	var tc := thorn_col()
	for k: int in 4:
		var u := 0.2 + 0.22 * float(k)
		var b := RM.cr(lead, u)
		var fwd := Vector3(0.35 * sx, 0.35, 1.0).normalized()
		var ln := 0.22 - 0.02 * float(k)
		RM.horn(th, [b, b + fwd * ln * 0.55 + Vector3(0, 0.02, 0), b + fwd * ln + Vector3(0.05 * sx, 0.06, -0.02)],
			0.045, 0.005, tc, 5, 3, Vector3.UP)
	var arm: Array[Vector3] = [s, e, w]
	var mid := func(u: float, v: float) -> Vector3:
		var l := RM.cr(arm, u)
		var t := rt.lerp(wt, u) + Vector3(0.0, 0.0, -0.09 * RM.scallop(u, 7.0))
		return l.lerp(t, v) + Vector3(0.0, 0.05 * sin(PI * v) * (0.5 + 0.5 * sin(PI * u)), 0.0)
	var thk := func(v: float) -> float:
		return 0.10 * pow(1.0 - v, 2.0) + 0.012
	var ct := func(_u: float, v: float) -> Color:
		return Color(1.0, 0.15 * RM.bump(v, 0.5, 0.08), 0.6 * smoothstep(0.8, 1.0, v), 0.0)
	var cb := func(_u: float, v: float) -> Color:
		return Color(0.7, 0.75, 0.5 * smoothstep(0.82, 1.0, v), 0.0)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * 1.45, v * 0.9)
	RM.panel(dr, mid, thk, ct, cb, uvf, 16, 5)
	return bake(key, [[bk, BARK], [dr, DRY], [th, THORN]])


## Hand part of a wing: bark hand edge, a fan of TEAM-leaf coverts and seven long pointed LEAF primaries (the outer
## five in the team leaf, the inner two dry), curling up at the tips. In-game grade pass (2026-09-30): the hand coverts
## were dry leaf and the bird showed 8 % team colour; the outer wing is its most top-facing surface.
static func wing_hand_mesh(sx: float) -> ArrayMesh:
	var key := "wing_hand%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var bk := RM.Surf.new()
	var dr := RM.Surf.new()
	var lf := RM.Surf.new()
	var w := RM.mx(RM.WRIST, sx)
	var h := RM.mx(RM.HAND, sx)
	var wt := RM.mx(RM.WRIST_TRAIL, sx)
	var dir := func(ang_deg: float) -> Vector3:
		var a := ang_deg * DEG
		return Vector3(cos(a) * sx, 0.0, -sin(a))
	var edge: Array[Vector3] = [w, w.lerp(h, 0.5) + Vector3(0, 0.02, 0.01), h + Vector3(0.10 * sx, 0.0, -0.04)]
	RM.loft(bk, edge, RM.round_prof(0.07, 0.04), RM.flat_col2(Color(0.8, 0.0, 0.2, 0.0)), 7, 5, Vector3.FORWARD, 0.4)
	var corr: Vector3 = wt - (w + (dir.call(88.0) as Vector3) * 0.96)
	var cmid := func(u: float, v: float) -> Vector3:
		var b := w.lerp(h, u)
		var ln := lerpf(0.96, 0.40, u) - 0.05 * (1.0 - RM.scallop(u, 6.0))
		var tip: Vector3 = b + (dir.call(lerpf(88.0, -6.0, u)) as Vector3) * ln + corr * pow(1.0 - u, 2.0)
		return b.lerp(tip, v) + Vector3(0.0, 0.04 * sin(PI * v), 0.0)
	var cth := func(v: float) -> float:
		return 0.07 * pow(1.0 - v, 2.0) + 0.012
	var ct := func(_u: float, v: float) -> Color:
		return Color(1.0, 0.0, 0.15 * v, 0.0)
	var cb := func(_u: float, v: float) -> Color:
		return Color(0.7, 0.7, 0.15 * v, 0.0)
	var cuv := func(u: float, v: float) -> Vector2:
		return Vector2(u * 0.7, v * 0.7)
	RM.panel(lf, cmid, cth, ct, cb, cuv, 10, 4)
	var lt := leaf_top()
	var lb := leaf_bot()
	for k: int in 7:
		var b := h.lerp(w, float(k) / 7.0) + Vector3(0.0, -0.01 + 0.012 * float(k), -0.02)
		var d: Vector3 = dir.call(RM.PRIM_ANG[k])
		var back: Vector3 = dir.call(RM.PRIM_ANG[k] + 90.0)
		var ln: float = RM.PRIM_LEN[k] * 1.04
		var curl := (0.16 if k < 5 else 0.05) * ln
		var pts: Array[Vector3] = [b - d * 0.05, b + d * ln * 0.5 + Vector3(0, 0.02, 0),
			b + d * ln * 0.85 + back * 0.03 * ln + Vector3(0, curl * 0.45, 0), b + d * ln + back * 0.07 * ln + Vector3(0, curl, 0)]
		RM.blade(lf if k < 5 else dr, pts, leaf_w(0.30), Vector3.UP, 0.035, lt, lb, 7)
	return bake(key, [[bk, BARK], [dr, DRY], [lf, LEAF]])


## Tail: a fan of seven long pointed leaves (team leaves at the edges and centre, dry ones between).
static func tail_mesh() -> ArrayMesh:
	if _meshes.has("tail"):
		return _meshes["tail"]
	var lf := RM.Surf.new()
	var dr := RM.Surf.new()
	var bk := RM.Surf.new()
	RM.blob(bk, RM.TAIL_BASE + Vector3(0, 0.02, -0.02), Vector3(0.16, 0.08, 0.20), RM.flat_col(Color(0.6, 0.0, 0.2, 0.0)),
		Basis.IDENTITY, 0.04, 8, 5)
	var lt := leaf_top()
	var lb := leaf_bot()
	for k: int in 7:
		var a := lerpf(-30.0, 30.0, float(k) / 6.0) * DEG
		var d := Vector3(sin(a), 0.0, -cos(a))
		var ln: float = RM.TAIL_LEN * (1.1 - 0.12 * absf(float(k) - 3.0) / 3.0)
		var b := RM.TAIL_BASE + d * 0.05 + Vector3(0, 0.006 * absf(float(k) - 3.0), 0)
		var pts: Array[Vector3] = [b, b + d * ln * 0.5 + Vector3(0, -0.02, 0), b + d * ln + Vector3(0, -0.07, 0)]
		var team := k % 2 == 0
		RM.blade(lf if team else dr, pts, leaf_w(0.26), Vector3.UP, 0.03, lt, lb, 6)
	return bake("tail", [[lf, LEAF], [dr, DRY], [bk, BARK]])


## Leg: bark thigh and tarsus, three thorn toes + hind toe with long pale thorn talons.
static func leg_mesh(sx: float) -> ArrayMesh:
	var key := "leg%d" % int(sx)
	if _meshes.has(key):
		return _meshes[key]
	var bk := RM.Surf.new()
	var th := RM.Surf.new()
	RM.blob(bk, Vector3(0.20 * sx, 3.67, -0.08), Vector3(0.14, 0.20, 0.16), RM.flat_col(Color(0.8, 0.1, 0.2, 0.0)),
		Basis(Vector3.RIGHT, 0.5), 0.06, 8, 5)
	var k := Vector3(0.20 * sx, 3.53, -0.19)
	var a0 := Vector3(0.20 * sx, 3.45, -0.36)
	var an := Vector3(0.20 * sx, 3.39, -0.50)
	RM.loft(bk, [k, k.lerp(a0, 0.5), a0, an], RM.round_prof(0.08, 0.05), RM.flat_col2(Color(0.5, 0.0, 0.4, 0.0)), 6, 4)
	var tc := thorn_col()
	for t: int in 3:
		var sp := (float(t) - 1.0) * 0.4
		var e2 := an + Vector3(sin(sp) * 0.10 * sx, -0.12, -0.12)
		RM.horn(th, [an, an.lerp(e2, 0.5) + Vector3(0, 0.01, 0), e2, e2 + Vector3(0, -0.07, 0.08)], 0.04, 0.004, tc, 5, 4)
	var h2 := an + Vector3(0.0, -0.08, 0.12)
	RM.horn(th, [an, h2, h2 + Vector3(0, -0.07, -0.08)], 0.038, 0.004, tc, 5, 4)
	var lf := RM.Surf.new()
	if sx > 0.0:
		# the right talon trails a rooting vine (one-sided: the asymmetric read), thorns along it, a leaf at the end
		var v0 := an + Vector3(0.02, -0.10, 0.02)
		var vine: Array[Vector3] = [v0, v0 + Vector3(0.10, -0.28, -0.10), v0 + Vector3(0.05, -0.55, -0.30),
			v0 + Vector3(0.16, -0.78, -0.42)]
		RM.loft(bk, vine, RM.round_prof(0.035, 0.018), RM.flat_col2(Color(0.4, 0.0, 0.6, 0.0)), 6, 8, Vector3.RIGHT, 0.2)
		for q: int in 3:
			var p := RM.cr(vine, 0.25 + 0.25 * float(q))
			var o := Vector3(0.6 if q % 2 == 0 else -0.6, 0.2, 0.5).normalized()
			RM.horn(th, [p, p + o * 0.06, p + o * 0.11 + Vector3(0, 0.02, 0)], 0.018, 0.003, tc, 4, 2)
		var e := vine[3]
		var lp: Array[Vector3] = [e, e + Vector3(0.06, -0.10, -0.10), e + Vector3(0.10, -0.16, -0.26)]
		RM.blade(lf, lp, leaf_w(0.18), Vector3(1.0, 0.3, 0.0).normalized(), 0.025, leaf_top(), leaf_bot(), 5)
	return bake(key, [[bk, BARK], [th, THORN], [lf, LEAF]])
