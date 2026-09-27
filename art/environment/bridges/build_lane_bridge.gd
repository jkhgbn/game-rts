extends SceneTree
## Task 12.V3: builds the Crown Bridge (the lane bridge over the Crown Isle moat, docs/design/map-fill.md 2.2 and
## section 10): art/environment/bridges/lane_bridge.tscn + lane_bridge.res + lane_bridge_ember_mat.tres.
##   $GODOT --path . -s res://art/environment/bridges/build_lane_bridge.gd --quit-after 300
## (Windowed is the safe way to save meshes; the test re-checks the saved mesh.)
##
## Look: a wide, low, pale-stone bridge of the old crown ruins. Two stone arches per face (a middle pier with
## pointed cutwaters) dive into the trench, the flush paving is cracked and mossy (moss in every joint, more
## towards the parapets and the banks, worn clean along the middle), low two-course parapets with a notch and a
## fallen coping stone in the water, a pier pilaster over each cutwater, flared wing walls ending on four
## posts, each crowned by an iron brazier (gold band) holding cold, smouldering embers (emission only).
##
## Local space (see lane_bridge_art.gd): metres, y up, origin = crossing centre on the moat centre line,
## local +Z = away from the isle (isle centre at (0, 0, -MOAT_R)), X = along the moat (tangential).
## Deck: 8 m (X) x 6.5 m (Z), paving tops y 0.010-0.026. Water r 11.0-14.5 (y -0.35), trench bed y -1.0.
## The moat curvature is baked: arch / pier / abutment lines follow circles around the isle centre.
##
## Vertex conventions = nature_painted.gdshader (shared nature_mat.tres, like the ruin pillars):
##   COLOR.rgb sRGB block, COLOR.a height gradient (y -0.6 -> 0, y 0.2 -> 1), UV.x moss amount (stone),
##   UV.y height for the contact band (y + 0.55: a wet, darker band towards the water line; posts: y),
##   UV2 = (0 = always drawn, kind 3 stone / 5 ivy).

const DIR := "res://art/environment/bridges/"
const MESH_PATH := DIR + "lane_bridge.res"
const SCENE_PATH := DIR + "lane_bridge.tscn"
const ART_SCRIPT := DIR + "lane_bridge_art.gd"
const EMBER_MAT_PATH := DIR + "lane_bridge_ember_mat.tres"
const STONE_MAT_PATH := "res://art/environment/nature_props/nature_mat.tres"
const GOLD_MAT_PATH := "res://art/environment/crown/crown_gold_mat.tres"
const GLOW_SHADER := "res://art/environment/env_glow.gdshader"

const STONE := 0
const GOLD := 1
const EMBER := 2
const SURF_NAMES: Array[String] = ["stone", "gold", "ember"]
const KIND_STONE := 3
const KIND_IVY := 5

# Geometry.
const MOAT_R := 12.75
const WATER_IN := 11.0
const WATER_OUT := 14.5
const BED_Y := -1.0
const DECK_HW := 3.96          # paving half width (the parapets' inner faces)
const EDGE_X := 3.44           # the kerb strips along the parapets start here
const DECK_HL := 3.25          # half length along the lane
const DECK_Y := 0.018
const FACE_X := 4.25           # spandrel faces (arch faces)
const PARA_X := 4.13           # parapet centre line
const PARA_TH := 0.34
# Two segmental arches per face, span 1.5 m each: intrados crown at y -0.12, springing at y -0.45 (0.1 m under the
# water, so each arch shows a full-width dark opening above the water and dives into it at both ends).
const ARCH_R := 1.017          # intrados radius
const ARCH_CY := -1.137        # circle centre height (crown = ARCH_CY + ARCH_R)
const ARCH_HALF := 0.75        # half span
const SPRING_Y := -0.45
const ARCH_C: Array[float] = [11.75, 13.75]
const PIER_R0 := 12.5
const PIER_R1 := 13.0
const CUT_R0 := 12.36          # cutwater base (a little wider than the pier)
const CUT_R1 := 13.14
const PARA_TOP := 0.58
const POST_X := 4.62
const POST_Z := 3.1
const GRAD_Y0 := -0.6
const GRAD_SPAN := 0.8

# Palette (sRGB, stone saturation <= 0.2 like the crown ruins).
const PALE := Color(0.61, 0.585, 0.57)
const DECK := Color(0.475, 0.455, 0.435)
const WARM := Color(0.505, 0.47, 0.435)
const COOL := Color(0.455, 0.45, 0.465)
const STONE_M := Color(0.50, 0.48, 0.49)
const STONE_D := Color(0.36, 0.34, 0.36)
const JOINT := Color(0.24, 0.27, 0.17)
const IRON := Color(0.21, 0.19, 0.21)
const COAL := Color(0.14, 0.12, 0.13)
const ASH := Color(0.43, 0.41, 0.40)
const GOLD_C := Color(0.9, 0.64, 0.24)
const GOLD_D := Color(0.64, 0.4, 0.13)
const IVY := Color(0.15, 0.32, 0.13)
const IVY_L := Color(0.27, 0.46, 0.17)


class SurfData:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()


var _s: Array[SurfData] = []
var _conv := 1.0
var _uv_off := 0.55     # UV.y = y + _uv_off (contact band)
var _kind := KIND_STONE
var _tint := 0.09


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for i: int in 3:
		_s.append(SurfData.new())
	_detect_winding()
	_build_deck()
	for sgn: float in [-1.0, 1.0]:
		_build_face(sgn)
		_build_cutwater(sgn)
		_build_parapet(sgn)
		for zs: float in [-1.0, 1.0]:
			_build_post(sgn, zs)
	_build_vault()
	_build_revetments()
	_build_greenery()
	_build_rubble()
	var mesh: ArrayMesh = _commit()
	_pack_scene(mesh)
	print("LANE BRIDGE BUILD OK")
	quit()


# ------------------------------------------------------------------------------------------ basics

func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


static func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


static func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


## A point at tangential offset x, radius r from the isle centre, height y (the moat curvature).
static func _p(x: float, r: float, y: float) -> Vector3:
	return Vector3(x, y, sqrt(maxf(r * r - x * x, 0.0)) - MOAT_R)


## One flat triangle; its front face points along `hint`.
## `n_in` / `k_in` (from _quad): one normal and one value jitter for both triangles of a quad, so they weld.
func _tri(s: int, a: Vector3, b: Vector3, c: Vector3, col: Color, hint: Vector3, moss: float = 0.0,
		n_in: Vector3 = Vector3.ZERO, k_in: float = -1.0) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.length_squared() < 1e-12:
		return
	var sg: float = 1.0 if fn.dot(hint) >= 0.0 else -1.0
	var nn: Vector3 = fn.normalized() * sg if n_in == Vector3.ZERO else n_in
	if sg != _conv:
		var t: Vector3 = b
		b = c
		c = t
	var k: float = k_in if k_in >= 0.0 else 1.0 + (_h(((a + b + c) / 3.0).snappedf(0.01)) - 0.5) * _tint
	var sd: SurfData = _s[s]
	for p: Vector3 in [a, b, c]:
		sd.v.append(p)
		sd.n.append(nn)
		sd.c.append(Color(col.r * k, col.g * k, col.b * k, 1.0))
		sd.uv.append(Vector2(moss, p.y + _uv_off))
		sd.uv2.append(Vector2(0.0, _kind))


func _quad(s: int, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, hint: Vector3, moss: float = 0.0) -> void:
	var qn: Vector3 = (c - a).cross(d - b)
	if qn.length_squared() < 1e-12:
		qn = (b - a).cross(c - a)
	if qn.length_squared() < 1e-12:
		return
	qn = qn.normalized()
	if qn.dot(hint) < 0.0:
		qn = -qn
	var k: float = 1.0 + (_h(((a + b + c + d) * 0.25).snappedf(0.01)) - 0.5) * _tint
	_tri(s, a, b, c, col, hint, moss, qn, k)
	_tri(s, a, c, d, col, hint, moss, qn, k)


## A closed convex-ish block from 4 bottom + 4 top corners (same order around), faces oriented outward.
func _block(s: int, bot: Array, top: Array, col: Color, moss: float = 0.0, skip_bottom: bool = true,
		side_col: Color = Color(0, 0, 0, 0)) -> void:
	var centre := Vector3.ZERO
	for p: Vector3 in bot + top:
		centre += p
	centre /= 8.0
	var sc: Color = side_col if side_col.a > 0.0 else col
	for i: int in 4:
		var j: int = (i + 1) % 4
		var a: Vector3 = bot[i]
		var b: Vector3 = bot[j]
		var c: Vector3 = top[j]
		var d: Vector3 = top[i]
		_quad(s, a, b, c, d, sc, (a + b + c + d) * 0.25 - centre, moss)
	var tc: Vector3 = (top[0] + top[1] + top[2] + top[3]) * 0.25
	_quad(s, top[0], top[1], top[2], top[3], col, tc - centre, moss)
	if not skip_bottom:
		var bc: Vector3 = (bot[0] + bot[1] + bot[2] + bot[3]) * 0.25
		_quad(s, bot[0], bot[1], bot[2], bot[3], sc.darkened(0.25), bc - centre, moss)


## A triangular prism (3 bottom + 3 top corners).
func _prism3(s: int, bot: Array, top: Array, col: Color, moss: float = 0.0, side_col: Color = Color(0, 0, 0, 0)) -> void:
	var centre := Vector3.ZERO
	for p: Vector3 in bot + top:
		centre += p
	centre /= 6.0
	var sc: Color = side_col if side_col.a > 0.0 else col
	for i: int in 3:
		var j: int = (i + 1) % 3
		var a: Vector3 = bot[i]
		var b: Vector3 = bot[j]
		_quad(s, a, b, top[j], top[i], sc, (a + b + top[j] + top[i]) * 0.25 - centre, moss)
	_tri(s, top[0], top[1], top[2], col, (top[0] + top[1] + top[2]) / 3.0 - centre, moss)


## A box (centre, size, basis), corners jittered (metres, per axis).
func _box(s: int, centre: Vector3, size: Vector3, basis: Basis, col: Color, moss: float = 0.0, jitter: float = 0.0,
		seed: float = 0.0, jit_axes: Vector3 = Vector3.ONE, skip_bottom: bool = true, top_inset: float = 0.0) -> void:
	var hs: Vector3 = size * 0.5
	var bot: Array = []
	var top: Array = []
	var loc: Array = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for l: Vector2 in loc:
		for yy: int in 2:
			var ins: float = top_inset if yy == 1 else 0.0
			var lp := Vector3(l.x * maxf(hs.x - ins, 0.01), -hs.y if yy == 0 else hs.y, l.y * maxf(hs.z - ins, 0.01))
			var p: Vector3 = centre + basis * lp
			if jitter > 0.0:
				p += _h3(lp.snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter * jit_axes
			if yy == 0:
				bot.append(p)
			else:
				top.append(p)
	_block(s, bot, top, col, moss, skip_bottom)


## Any indexed primitive arrays, transformed, jittered, flat-shaded in one colour.
func _prim(s: int, arr: Array, xf: Transform3D, col: Color, moss: float = 0.0, jitter: float = 0.0, seed: float = 0.0) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nb: Basis = xf.basis.inverse().transposed()
	var tv := PackedVector3Array()
	tv.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = xf * v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter
		tv[i] = p
	for t: int in range(0, idx.size(), 3):
		var hint: Vector3 = nb * (n[idx[t]] + n[idx[t + 1]] + n[idx[t + 2]])
		_tri(s, tv[idx[t]], tv[idx[t + 1]], tv[idx[t + 2]], col, hint, moss)


func _sph(r: float, segs: int = 6, rings: int = 3) -> Array:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


## Surface of revolution from (radius, y) points around `xf` (walk with the solid on the RIGHT: up the outside,
## over the top, down the inside, so the faces point outward). `cols[i]` = band i.
func _lathe(s: int, prof: Array, cols: Array, sides: int, xf: Transform3D, moss: float = 0.0) -> void:
	for i: int in prof.size() - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var d: Vector2 = p1 - p0
		var nrm := Vector2(d.y, -d.x)
		var col: Color = cols[mini(i, cols.size() - 1)]
		for j: int in sides:
			var a0: float = j * TAU / sides
			var a1: float = (j + 1) * TAU / sides
			var am: float = (a0 + a1) * 0.5
			var q0: Vector3 = xf * Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x)
			var q1: Vector3 = xf * Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x)
			var q2: Vector3 = xf * Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x)
			var q3: Vector3 = xf * Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)
			var hint: Vector3 = xf.basis * Vector3(cos(am) * nrm.x, nrm.y, sin(am) * nrm.x)
			_quad(s, q0, q1, q2, q3, col, hint, moss)


## Flat polygon disc (fan) facing up.
func _disc(s: int, c: Vector3, r: float, sides: int, col: Color, xf: Transform3D = Transform3D.IDENTITY) -> void:
	for j: int in sides:
		var a0: float = j * TAU / sides
		var a1: float = (j + 1) * TAU / sides
		_tri(s, xf * c, xf * (c + Vector3(cos(a0) * r, 0, sin(a0) * r)), xf * (c + Vector3(cos(a1) * r, 0, sin(a1) * r)),
				col, xf.basis * Vector3.UP)


# ------------------------------------------------------------------------------------------ deck

func _build_deck() -> void:
	# Mossy bed under the paving: every joint shows dark moss.
	var by: float = -0.028
	_quad(STONE, Vector3(-DECK_HW - 0.02, by, -DECK_HL - 0.05), Vector3(DECK_HW + 0.02, by, -DECK_HL - 0.05),
			Vector3(DECK_HW + 0.02, by, DECK_HL + 0.05), Vector3(-DECK_HW - 0.02, by, DECK_HL + 0.05), JOINT, Vector3.UP, 1.0)
	# Kerb strips along both parapets: long slabs laid lengthwise (the frame of the deck).
	for sgn: float in [-1.0, 1.0]:
		var zk: float = -DECK_HL
		var ki: int = 0
		while zk < DECK_HL - 0.05:
			var kl: float = 0.85 + _h(Vector3(sgn, ki, 71)) * 0.6
			var zk1: float = minf(zk + kl, DECK_HL)
			if DECK_HL - zk1 < 0.45:
				zk1 = DECK_HL
			var xa: float = sgn * EDGE_X
			var xb: float = sgn * DECK_HW
			_slab(minf(xa, xb), maxf(xa, xb), zk, zk1, 100 + ki, int(sgn + 1.0), true)
			zk = zk1
			ki += 1
	# The field: rows across the lane, staggered joints.
	var z: float = -DECK_HL
	var row: int = 0
	while z < DECK_HL - 0.05:
		var rl: float = 0.58 + _h(Vector3(row, 1, 3)) * 0.5
		var z1: float = minf(z + rl, DECK_HL)
		if DECK_HL - z1 < 0.45:
			z1 = DECK_HL
		var x: float = -EDGE_X
		var ci: int = 0
		while x < EDGE_X - 0.05:
			var w: float = 0.6 + _h(Vector3(row, ci, 7)) * 0.75
			if ci == 0:
				w *= 0.4 + _h(Vector3(row, 2, 2)) * 0.75
			var x1: float = minf(x + w, EDGE_X)
			if EDGE_X - x1 < 0.4:
				x1 = EDGE_X
			_slab(x, x1, z, z1, row, ci, false)
			x = x1
			ci += 1
		z = z1
		row += 1
	# Loose slabs past both ends, on the banks (the paving frays into the plaza / the lane).
	for end: float in [-1.0, 1.0]:
		for i: int in 5:
			var hh: float = _h(Vector3(i, end, 31))
			var px: float = -3.2 + i * 1.55 + (hh - 0.5) * 0.6
			var pz: float = end * (DECK_HL + 0.28 + _h(Vector3(i, end, 32)) * 0.3)
			var sz := Vector3(0.45 + hh * 0.35, 0.05, 0.35 + _h(Vector3(i, end, 33)) * 0.25)
			_box(STONE, Vector3(px, -0.013, pz), sz, Basis(Vector3.UP, (hh - 0.5) * 0.8), DECK.darkened(0.06 + hh * 0.08),
					0.7, 0.012, 300.0 + i + end * 10.0, Vector3(1, 0.1, 1))


## One paving slab (x0..x1, z0..z1). Variants: whole, cracked in two (one half sunk a little), missing (rubble
## fill). Tops stay within y 0.006-0.026.
func _slab(x0: float, x1: float, z0: float, z1: float, row: int, ci: int, kerb: bool = false) -> void:
	var g: float = 0.024
	var hh: float = _h(Vector3(row, ci, 11))
	var seed: float = row * 17.0 + ci
	var cx: float = (x0 + x1) * 0.5
	var cz: float = (z0 + z1) * 0.5
	# Moss is all or nothing per slab (partial amounts look like pale dust): the kerbs and the bank ends are
	# overgrown, the worn middle of the lane is mostly bare.
	var end_k: float = smoothstep(1.9, 3.1, absf(cz))
	var moss_p: float = 0.55 if kerb else 0.07 + end_k * 0.3 + smoothstep(2.2, 3.3, absf(cx)) * 0.15
	var moss: float = 1.0 if _h(Vector3(row, ci, 17)) < moss_p else 0.0
	var tones: Array[Color] = [DECK, WARM, COOL, DECK, DECK]
	var col: Color = tones[int(_h(Vector3(row, ci, 13)) * 4.99)]
	col = col.darkened(_h(Vector3(row, ci, 14)) * 0.07)
	if _h(Vector3(row, ci, 18)) > 0.9:
		col = col.darkened(0.14)
	if kerb:
		col = col.lerp(STONE_M, 0.5)
	# The ends fray: the first / last row's slabs stop short by a random amount.
	if z1 >= DECK_HL - 0.001:
		z1 -= _h(Vector3(row, ci, 15)) * 0.26
	if z0 <= -DECK_HL + 0.001:
		z0 += _h(Vector3(row, ci, 16)) * 0.26
	var c00 := Vector2(x0 + g, z0 + g)
	var c10 := Vector2(x1 - g, z0 + g)
	var c11 := Vector2(x1 - g, z1 - g)
	var c01 := Vector2(x0 + g, z1 - g)
	var pts: Array = [c00, c10, c11, c01]
	for i: int in 4:
		var jj: Vector3 = _h3(Vector3(pts[i].x, 5.0, pts[i].y).snappedf(0.01)) * 0.022
		pts[i] = (pts[i] as Vector2) + Vector2(jj.x, jj.z)
	var top: float = DECK_Y + (hh - 0.5) * 0.008
	var kind: float = _h(Vector3(row, ci, 23))
	var inner: bool = not kerb and absf(cz) < 2.6
	if kind < 0.045 and inner:
		# Missing slab: a bed of broken bits, lower.
		for k: int in 4:
			var q := Vector2(lerpf(x0, x1, 0.25 + (k % 2) * 0.5), lerpf(z0, z1, 0.25 + floorf(k / 2.0) * 0.5))
			var hk: float = _h(Vector3(row, ci, 40 + k))
			_box(STONE, Vector3(q.x, -0.012, q.y), Vector3((x1 - x0) * 0.42, 0.034, (z1 - z0) * 0.42),
					Basis(Vector3.UP, (hk - 0.5) * 0.9), STONE_D.lerp(DECK, hk * 0.6), 0.9, 0.02, seed * 3.0 + k,
					Vector3(1, 0.15, 1))
		return
	if kind < 0.22 and not kerb:
		# Cracked across X: two pieces, the second sunk and tilted a little.
		var ta: float = 0.3 + _h(Vector3(row, ci, 24)) * 0.4
		var tb: float = 0.3 + _h(Vector3(row, ci, 25)) * 0.4
		var m0: Vector2 = (pts[0] as Vector2).lerp(pts[1], ta)
		var m1: Vector2 = (pts[3] as Vector2).lerp(pts[2], tb)
		var cg := Vector2(0.014, 0.0)
		_slab_poly([pts[0], m0 - cg, m1 - cg, pts[3]], [top, top, top, top], col, moss, seed)
		var t2: float = top - 0.009
		_slab_poly([m0 + cg, pts[1], pts[2], m1 + cg], [t2, t2 - 0.004, t2 + 0.002, t2], col.darkened(0.04),
				1.0, seed + 0.5)
		return
	var tops: Array = []
	for i: int in 4:
		tops.append(top + (_h(Vector3(row, ci, 50 + i)) - 0.5) * 0.005)
	_slab_poly(pts, tops, col, moss, seed)


func _slab_poly(pts: Array, tops: Array, col: Color, moss: float, _seed: float) -> void:
	var bot: Array = []
	var top: Array = []
	for i: int in 4:
		var p: Vector2 = pts[i]
		bot.append(Vector3(p.x, -0.03, p.y))
		top.append(Vector3(p.x, clampf(float(tops[i]), 0.006, 0.026), p.y))
	_block(STONE, bot, top, col, moss, true, col.darkened(0.18))


# ------------------------------------------------------------------------------------------ arch faces

## Angle of the springing on the intrados circle (the arch runs from PHI0 to PI - PHI0).
static func _phi0() -> float:
	return asin((SPRING_Y - ARCH_CY) / ARCH_R)


## (radius from the isle centre, y) of the arch point at angle phi, `extra` metres outside the intrados.
static func _arch(rc: float, phi: float, extra: float = 0.0) -> Vector2:
	return Vector2(rc + (ARCH_R + extra) * cos(phi), ARCH_CY + (ARCH_R + extra) * sin(phi))


## The spandrel face at x = sgn * FACE_X (abutments, piers, the stone above both arches) and the voussoir rings.
func _build_face(sgn: float) -> void:
	var fx: float = sgn * FACE_X
	var hint := Vector3(sgn, 0, 0)
	var top_y: float = -0.02
	var col: Color = STONE_D.lightened(0.1)   # darker than the voussoirs: the arches read
	# Abutment faces (mostly under the banks; the part over the trench lip shows) and the pier face.
	for span: Vector2 in [Vector2(10.3, WATER_IN), Vector2(WATER_OUT, 15.2), Vector2(PIER_R0, PIER_R1)]:
		var steps: int = 3 if span.y - span.x > 0.6 else 1
		for k: int in steps:
			var r0: float = lerpf(span.x, span.y, float(k) / steps)
			var r1: float = lerpf(span.x, span.y, float(k + 1) / steps)
			_quad(STONE, _p(fx, r0, BED_Y), _p(fx, r1, BED_Y), _p(fx, r1, top_y), _p(fx, r0, top_y), col, hint)
	# Spandrels over each arch: vertical strips from the intrados up to the deck edge.
	var na: int = 10
	var p0: float = _phi0()
	for rc: float in ARCH_C:
		for k: int in na:
			var f0: float = lerpf(PI - p0, p0, float(k) / na)
			var f1: float = lerpf(PI - p0, p0, float(k + 1) / na)
			var a: Vector2 = _arch(rc, f0)
			var b: Vector2 = _arch(rc, f1)
			_quad(STONE, _p(fx, a.x, a.y), _p(fx, b.x, b.y), _p(fx, b.x, top_y), _p(fx, a.x, top_y), col.darkened(0.03), hint)
		_voussoirs(sgn, rc)


## 9 wedge stones around one arch on one face; the keystone is paler and projects more.
func _voussoirs(sgn: float, rc: float) -> void:
	var n: int = 9
	var gap: float = 0.01
	var p0: float = _phi0()
	for i: int in n:
		var fa: float = lerpf(PI - p0, p0, float(i) / n) - gap
		var fb: float = lerpf(PI - p0, p0, float(i + 1) / n) + gap
		if i == 0:
			fa = PI - p0 + 0.08   # the first / last stones reach under the water
		if i == n - 1:
			fb = p0 - 0.08
		var key: bool = i == 4
		var depth: float = 0.135 if key else 0.12 + _h(Vector3(i, rc, 3)) * 0.02
		var x_in: float = sgn * (FACE_X - 0.06)
		# The ring stands proud of the face (an archivolt), past the parapet line: seen from the RTS camera its top
		# surfaces draw a pale arc over the dark opening.
		var x_out: float = sgn * (FACE_X + (0.2 if key else 0.16))
		var pa_i: Vector2 = _arch(rc, fa)
		var pb_i: Vector2 = _arch(rc, fb)
		var pa_o: Vector2 = _arch(rc, fa, depth)
		var pb_o: Vector2 = _arch(rc, fb, depth)
		var bot: Array = [_p(x_in, pa_i.x, pa_i.y), _p(x_in, pb_i.x, pb_i.y), _p(x_out, pb_i.x, pb_i.y), _p(x_out, pa_i.x, pa_i.y)]
		var top: Array = [_p(x_in, pa_o.x, pa_o.y), _p(x_in, pb_o.x, pb_o.y), _p(x_out, pb_o.x, pb_o.y), _p(x_out, pa_o.x, pa_o.y)]
		var col: Color = PALE.lightened(0.06) if key else (PALE if i % 2 == 0 else STONE_M.lightened(0.05))
		_block(STONE, bot, top, col, 0.0, false)


## The barrel vaults under the deck (very dark, seen through the arches) and the pier / abutment walls below them.
func _build_vault() -> void:
	var xs: Array[float] = [-FACE_X + 0.04, -2.1, 0.0, 2.1, FACE_X - 0.04]
	var na: int = 8
	var dark: Color = STONE_D.darkened(0.55)
	var p0: float = _phi0()
	for rc: float in ARCH_C:
		for xi: int in xs.size() - 1:
			var x0: float = xs[xi]
			var x1: float = xs[xi + 1]
			for k: int in na:
				var f0: float = lerpf(PI - p0, p0, float(k) / na)
				var f1: float = lerpf(PI - p0, p0, float(k + 1) / na)
				var q0: Vector2 = _arch(rc, f0)
				var q1: Vector2 = _arch(rc, f1)
				var a: Vector3 = _p(x0, q0.x, q0.y)
				var b: Vector3 = _p(x0, q1.x, q1.y)
				var c: Vector3 = _p(x1, q1.x, q1.y)
				var d: Vector3 = _p(x1, q0.x, q0.y)
				var axis: Vector3 = _p((x0 + x1) * 0.5, rc, ARCH_CY)
				_quad(STONE, a, b, c, d, dark, axis - (a + b + c + d) * 0.25)
			# Pier / abutment walls under the springing on both sides of this arch.
			for rw: float in [rc - ARCH_HALF, rc + ARCH_HALF]:
				var a2: Vector3 = _p(x0, rw, BED_Y)
				var b2: Vector3 = _p(x1, rw, BED_Y)
				var c2: Vector3 = _p(x1, rw, SPRING_Y)
				var d2: Vector3 = _p(x0, rw, SPRING_Y)
				var toward: Vector3 = _p((x0 + x1) * 0.5, rc, -0.7) - (a2 + c2) * 0.5
				_quad(STONE, a2, b2, c2, d2, dark, toward)

## Pointed cutwater in front of the middle pier (splits the moat's flow), with a mossy sloping cap stone.
func _build_cutwater(sgn: float) -> void:
	var fx: float = sgn * FACE_X
	var tip_x: float = sgn * 5.45
	var yf: float = -0.04
	var yt: float = -0.2
	var a_b: Vector3 = _p(fx, CUT_R0, BED_Y)
	var b_b: Vector3 = _p(fx, CUT_R1, BED_Y)
	var t_b: Vector3 = _p(tip_x, 12.75, BED_Y)
	var a_t: Vector3 = _p(fx, CUT_R0, yf)
	var b_t: Vector3 = _p(fx, CUT_R1, yf)
	var t_t: Vector3 = _p(tip_x, 12.75, yt)
	_prism3(STONE, [a_b, b_b, t_b], [a_t, b_t, t_t], STONE_M, 0.0)
	# Cap stone: overhangs 4 cm, 6 cm thick, mossy.
	var cc: Vector3 = (a_t + b_t + t_t) / 3.0
	var bot: Array = []
	var top: Array = []
	for p: Vector3 in [a_t, b_t, t_t]:
		var o: Vector3 = p + Vector3(p.x - cc.x, 0, p.z - cc.z).normalized() * 0.045
		if absf(p.x - fx) < 0.01:
			o.x = fx - sgn * 0.02    # tucked into the face
		bot.append(o + Vector3(0, -0.005, 0))
		top.append(o + Vector3(0, 0.06, 0))
	_prism3(STONE, bot, top, PALE.darkened(0.04), 0.95, STONE_M)


# ------------------------------------------------------------------------------------------ parapets

func _build_parapet(sgn: float) -> void:
	var xc: float = sgn * PARA_X
	# Straight run, notched on the +X side (broken coping, upper course knocked down).
	var notch := Vector2(3.3, 4.25) if sgn > 0.0 else Vector2(-1.0, -1.0)
	_wall(Vector2(xc, -2.5), Vector2(xc, 2.5), 10.0 + sgn, notch)
	# Wing walls flaring out to the posts.
	for zs: float in [-1.0, 1.0]:
		_wall(Vector2(xc, zs * 2.46), Vector2(sgn * (POST_X - 0.16), zs * (POST_Z - 0.2)), 20.0 + sgn * 3.0 + zs,
				Vector2(-1.0, -1.0))
	# Pier pilaster over the cutwater: a taller, thicker block with a cap.
	var za: float = _p(sgn * FACE_X, CUT_R0, 0.0).z
	var zb: float = _p(sgn * FACE_X, CUT_R1, 0.0).z
	var zc: float = (za + zb) * 0.5
	var zw: float = absf(zb - za)
	_box(STONE, Vector3(sgn * 4.26, 0.27, zc), Vector3(0.6, 0.78, zw), Basis.IDENTITY, STONE_M, 0.5, 0.012, 60.0 + sgn)
	_box(STONE, Vector3(sgn * 4.26, 0.7, zc), Vector3(0.68, 0.1, zw + 0.1), Basis.IDENTITY, PALE, 1.0, 0.01, 61.0 + sgn,
			Vector3.ONE, false, 0.035)


## A low parapet from a to b (xz): two courses of blocks (y -0.02 .. 0.43) and a chamfered coping (to 0.52).
## `notch` (t range in metres along the wall, x < 0 = none): the coping is gone and the upper course broken.
func _wall(a: Vector2, b: Vector2, seed: float, notch: Vector2) -> void:
	var d: Vector2 = b - a
	var length: float = d.length()
	var dir: Vector2 = d / length
	var nrm := Vector2(-dir.y, dir.x)
	var hw: float = PARA_TH * 0.5
	var courses: Array = [[-0.02, 0.235], [0.235, 0.47]]
	for ci: int in 2:
		var t: float = 0.0
		var bi: int = 0
		while t < length - 0.01:
			var hh: float = _h(Vector3(seed, ci, bi))
			var bl: float = (0.3 + hh * 0.45) if (bi == 0 and ci == 1) else (0.6 + hh * 0.42)
			var t1: float = minf(t + bl, length)
			if length - t1 < 0.25:
				t1 = length
			var y0: float = courses[ci][0]
			var y1: float = courses[ci][1]
			var in_notch: bool = notch.x >= 0.0 and (t + t1) * 0.5 > notch.x and (t + t1) * 0.5 < notch.y
			var col: Color = STONE_M.lerp(PALE, _h(Vector3(seed, ci, bi + 40)) * 0.8)
			if ci == 1 and in_notch:
				# Broken: jagged low top, a darker fresh break.
				_wall_block(a, dir, nrm, t + 0.007, t1 - 0.007, hw, y0, 0.33 + hh * 0.05, col.darkened(0.08), 0.2, seed + bi,
						0.05)
			else:
				_wall_block(a, dir, nrm, t + 0.007, t1 - 0.007, hw, y0, y1, col, 0.35, seed + bi + ci * 20.0, 0.008)
			t = t1
			bi += 1
	# Coping.
	var tc: float = 0.0
	var ki: int = 0
	while tc < length - 0.01:
		var hk: float = _h(Vector3(seed, 7, ki))
		var kl: float = 0.85 + hk * 0.4
		var tk1: float = minf(tc + kl, length)
		if length - tk1 < 0.3:
			tk1 = length
		var mid: float = (tc + tk1) * 0.5
		if not (notch.x >= 0.0 and mid > notch.x - 0.2 and mid < notch.y + 0.2):
			var col2: Color = PALE.lerp(DECK, hk * 0.5)
			_wall_block(a, dir, nrm, tc + 0.01, tk1 - 0.01, hw + 0.035, 0.47, PARA_TOP + (hk - 0.5) * 0.012, col2,
					1.0 if hk > 0.6 else 0.0,
					seed + 100.0 + ki, 0.006, 0.035)
		tc = tk1
		ki += 1


## One wall block between t0 and t1 along the wall, half thickness hw, y0..y1. `jag` = random top height
## (broken tops), `inset` = chamfer of the top face.
func _wall_block(a: Vector2, dir: Vector2, nrm: Vector2, t0: float, t1: float, hw: float, y0: float, y1: float,
		col: Color, moss: float, seed: float, jag: float, inset: float = 0.0) -> void:
	var bot: Array = []
	var top: Array = []
	var corners: Array = [[t0, -hw], [t1, -hw], [t1, hw], [t0, hw]]
	for i: int in 4:
		var tt: float = corners[i][0]
		var ss: float = corners[i][1]
		var p: Vector2 = a + dir * tt + nrm * ss
		var j: Vector3 = _h3(Vector3(p.x, seed, p.y).snappedf(0.001)) * 0.01
		bot.append(Vector3(p.x + j.x, y0, p.y + j.z))
		var tin: float = inset
		var pt: Vector2 = a + dir * (tt + (tin if i == 0 or i == 3 else -tin)) + nrm * (ss + (tin if ss < 0.0 else -tin))
		var yj: float = y1 + (_h(Vector3(seed, i, 9)) - 0.5) * jag
		top.append(Vector3(pt.x + j.x, yj, pt.y + j.z))
	_block(STONE, bot, top, col, moss, true, col.darkened(0.1))


# ------------------------------------------------------------------------------------------ posts, braziers

func _build_post(sgn: float, zs: float) -> void:
	var c := Vector3(sgn * POST_X, 0.0, zs * POST_Z)
	var seed: float = 200.0 + sgn * 7.0 + zs * 3.0
	var old_off: float = _uv_off
	_uv_off = 0.0   # on the bank: the usual dark contact band at the ground
	_box(STONE, c + Vector3(0, -0.06, 0), Vector3(0.8, 0.3, 0.8), Basis(Vector3.UP, 0.03 * sgn), STONE_D.lightened(0.05),
			0.7, 0.02, seed)
	_box(STONE, c + Vector3(0, 0.55, 0), Vector3(0.6, 0.92, 0.6), Basis.IDENTITY, STONE_M.lerp(PALE, 0.4), 0.2, 0.012,
			seed + 1.0)
	var chipped: bool = sgn < 0.0 and zs > 0.0
	_box(STONE, c + Vector3(0, 1.065, 0), Vector3(0.76, 0.12, 0.76), Basis(Vector3.UP, 0.05 * zs), PALE, 1.0, 0.012,
			seed + 2.0, Vector3.ONE, false, 0.035)
	if chipped:
		# A corner of the cap broke off and lies at the foot.
		_box(STONE, c + Vector3(sgn * 0.62, 0.04, zs * 0.35), Vector3(0.26, 0.12, 0.22),
				Basis.from_euler(Vector3(0.3, 0.8, 0.2)), PALE.darkened(0.08), 0.7, 0.03, seed + 3.0)
	_uv_off = old_off
	# Brazier (one sits a little askew).
	var tilt: Basis = Basis.from_euler(Vector3(0.07 * zs, 0.4 * sgn, -0.06 * sgn)) if (sgn > 0.0 and zs > 0.0) \
			else Basis(Vector3.UP, 0.4 * sgn + zs * 0.2)
	_brazier(Transform3D(tilt, c + Vector3(0, 1.12, 0)), seed + 10.0)


## An iron bowl on a short stem with a gold band, filled with ash-grey coals and a few smouldering embers.
func _brazier(xf: Transform3D, seed: float) -> void:
	_uv_off = 1.0
	_lathe(STONE, [Vector2(0.23, 0.0), Vector2(0.22, 0.05), Vector2(0.13, 0.085), Vector2(0.09, 0.1), Vector2(0.085, 0.17),
			Vector2(0.14, 0.185), Vector2(0.29, 0.27), Vector2(0.365, 0.38), Vector2(0.375, 0.44), Vector2(0.33, 0.45),
			Vector2(0.305, 0.4)], [IRON.lightened(0.08), IRON, IRON, IRON, IRON.darkened(0.1), IRON, IRON, IRON.lightened(0.05),
			IRON.lightened(0.12), IRON.darkened(0.2)], 8, xf)
	_lathe(GOLD, [Vector2(0.28, 0.272), Vector2(0.305, 0.272), Vector2(0.352, 0.352), Vector2(0.33, 0.352)],
			[GOLD_D, GOLD_C, GOLD_C], 8, xf)
	# Smouldering bed under the coals (shows in the gaps), then the coal lumps and a few live embers on top.
	_disc(EMBER, Vector3(0, 0.398, 0), 0.29, 8, Color.WHITE, xf)
	for k: int in 12:
		var a: float = k * 2.39996 + seed
		var rr: float = 0.03 + sqrt(float(k) / 12.0) * 0.23
		var hk: float = _h(Vector3(k, seed, 5))
		var s: float = 0.085 + hk * 0.05
		var p := Vector3(cos(a) * rr, 0.42 + (1.0 - rr / 0.26) * 0.03, sin(a) * rr)
		var col: Color = COAL.lerp(ASH, _h(Vector3(k, seed, 6)) * 0.7)
		# Every fourth lump still smoulders.
		_prim(EMBER if k % 4 == 1 else STONE, _sph(s, 5, 3), xf * Transform3D(Basis.from_euler(Vector3(hk, a, hk * 0.5)).scaled(
				Vector3(1.2, 0.55, 1.0)), p), col, 0.0, 0.012, seed + k)
	for k: int in 3:
		var a2: float = k * 2.1 + seed * 0.37
		var p2 := Vector3(cos(a2) * 0.12, 0.445, sin(a2) * 0.12)
		_prim(EMBER, _sph(0.045 + k * 0.008, 5, 3), xf * Transform3D(Basis.from_euler(Vector3(0.3, a2, 0.2)).scaled(
				Vector3(1.2, 0.6, 1.0)), p2), Color.WHITE, 0.0, 0.01, seed + 20.0 + k)
	_uv_off = 0.55


# ------------------------------------------------------------------------------------------ greenery, rubble

## Stone-faced banks (abutment wing walls) either side of each face, on both banks: two courses of blocks
## down into the water (a slight batter, in front of the trench wall's lip) and a pale kerb over the cut edge.
## They frame the bridge from above and hide the raw ground cut next to it.
func _build_revetments() -> void:
	for sgn: float in [-1.0, 1.0]:
		for bank: int in 2:
			var inner: bool = bank == 0
			var r_edge: float = WATER_IN if inner else WATER_OUT
			var to_water: float = 1.0 if inner else -1.0
			var length: float = 1.75 if inner else 2.1
			var seed: float = 600.0 + sgn * 11.0 + bank * 5.0
			var x_start: float = FACE_X - 0.12
			var x_end: float = FACE_X + length
			# Courses: (y top, y bottom).
			var courses: Array = [[0.0, -0.21], [-0.21, -0.62]]
			for ci: int in 2:
				var x: float = x_start
				var bi: int = 0
				while x < x_end - 0.05:
					var hh: float = _h(Vector3(seed, ci, bi))
					var bl: float = (0.28 + hh * 0.3) if (bi == 0 and ci == 0) else (0.5 + hh * 0.34)
					var x1: float = minf(x + bl, x_end)
					var yt: float = courses[ci][0]
					var yb: float = courses[ci][1]
					if ci == 0 and x1 >= x_end - 0.01:
						yt = -0.09   # the last block of the upper course is broken low
					var push: float = hh * 0.025
					var bot: Array = []
					var top: Array = []
					for yy: int in 2:
						var y: float = yb if yy == 0 else yt
						var rf: float = r_edge + to_water * (0.02 + push + maxf(-y, 0.0) * 0.3)
						var rb: float = r_edge - to_water * 0.3
						var pts: Array = [_p(sgn * (x + 0.006), rf, y), _p(sgn * (x1 - 0.006), rf, y),
								_p(sgn * (x1 - 0.006), rb, y), _p(sgn * (x + 0.006), rb, y)]
						if yy == 0:
							bot = pts
						else:
							top = pts
					var col: Color = STONE_M.lerp(STONE_D, _h(Vector3(seed, ci, bi + 30)) * 0.6)
					_block(STONE, bot, top, col, 0.0, true, col.darkened(0.06))
					x = x1
					bi += 1
			# Kerb over the cut edge (overhangs the water 4 cm), a gap where it broke near the far end.
			var xk: float = x_start
			var ki: int = 0
			while xk < x_end - 0.3:
				var hk: float = _h(Vector3(seed, 9, ki))
				var kl: float = 0.6 + hk * 0.35
				var xk1: float = minf(xk + kl, x_end - 0.12)
				if not (ki == 2 and not inner):
					var rf2: float = r_edge + to_water * 0.045
					var rb2: float = r_edge - to_water * 0.36
					var yb2: float = -0.05
					var yt2: float = 0.03 + (hk - 0.5) * 0.012
					var b2: Array = [_p(sgn * (xk + 0.01), rf2, yb2), _p(sgn * (xk1 - 0.01), rf2, yb2),
							_p(sgn * (xk1 - 0.01), rb2, yb2), _p(sgn * (xk + 0.01), rb2, yb2)]
					var t2: Array = [_p(sgn * (xk + 0.02), rf2 - to_water * 0.012, yt2), _p(sgn * (xk1 - 0.02), rf2 - to_water * 0.012, yt2),
							_p(sgn * (xk1 - 0.02), rb2, yt2), _p(sgn * (xk + 0.02), rb2, yt2)]
					_block(STONE, b2, t2, PALE.lerp(DECK, hk * 0.6), 1.0 if hk > 0.4 else 0.0, true, STONE_M)
				xk = xk1
				ki += 1


func _build_greenery() -> void:
	_kind = KIND_IVY
	var old_tint: float = _tint
	_tint = 0.12
	for sgn: float in [-1.0, 1.0]:
		# Ivy curtains hanging from the cornice over the arches, down to the water.
		var rs: Array = [11.05, 14.3] if sgn > 0.0 else [11.35, 13.95, 14.95]
		for ri: int in rs.size():
			var r: float = rs[ri]
			var rows: int = 4 if ri % 2 == 0 else 3
			for j: int in rows:
				var y: float = -0.05 - j * 0.11
				var off: float = (_h(Vector3(ri, j, sgn)) - 0.5) * 0.22
				var p: Vector3 = _p(sgn * (FACE_X + 0.1), r + off, y)
				var rr: float = 0.15 - j * 0.02
				_prim(STONE, _sph(rr, 5, 3), Transform3D(Basis.from_scale(Vector3(0.5, 1.15, 1.0)), p),
						IVY_L if (j + ri) % 2 == 0 else IVY, 0.0, 0.03, 400.0 + ri * 9.0 + j + sgn)
		# Ivy spilling over the coping near the isle end and over one wing.
		for k: int in 3:
			var z: float = -2.1 + k * 0.28 if sgn < 0.0 else 1.55 + k * 0.3
			var y2: float = 0.5 - k * 0.12
			_prim(STONE, _sph(0.17 - k * 0.02, 5, 3), Transform3D(Basis.from_scale(Vector3(0.7, 0.8, 1.2)),
					Vector3(sgn * (PARA_X + 0.14), y2, z)), IVY if k % 2 == 0 else IVY_L, 0.0, 0.03, 450.0 + k + sgn)
		# Moss cushions at the parapet foot on the deck (flat, under 6 cm).
		for k: int in 5:
			var hz: float = _h(Vector3(k, sgn, 61))
			var z3: float = -2.9 + k * 1.35 + hz * 0.5
			_prim(STONE, _sph(0.2 + hz * 0.08, 6, 2), Transform3D(Basis.from_scale(Vector3(1.0, 0.09, 1.6)),
					Vector3(sgn * 3.93, 0.01, z3)), IVY.lerp(IVY_L, hz), 0.0, 0.015, 470.0 + k + sgn * 3.0)
	# Ivy climbing two of the posts.
	for pc: Vector3 in [Vector3(-POST_X, 0, -POST_Z), Vector3(POST_X, 0, POST_Z)]:
		var face: Vector3 = Vector3(signf(pc.x), 0, 0)
		for j: int in 4:
			var p4: Vector3 = pc + face * 0.31 + Vector3(0, 0.12 + j * 0.2, (_h(Vector3(j, pc.x, 3)) - 0.5) * 0.2)
			_prim(STONE, _sph(0.14 - j * 0.015, 5, 3), Transform3D(Basis.from_scale(Vector3(0.45, 1.2, 1.0)), p4),
					IVY_L if j % 2 == 0 else IVY, 0.0, 0.03, 480.0 + j + pc.x)
	_tint = old_tint
	_kind = KIND_STONE


func _build_rubble() -> void:
	# The coping stone knocked off the +X notch, half sunk in the moat beside the bridge.
	_box(STONE, Vector3(4.9, -0.4, 0.42), Vector3(0.9, 0.16, 0.44), Basis.from_euler(Vector3(0.42, 0.55, 0.2)),
			PALE.darkened(0.05), 0.9, 0.02, 500.0)
	_box(STONE, Vector3(4.62, -0.33, 1.02), Vector3(0.36, 0.2, 0.3), Basis.from_euler(Vector3(0.4, 1.2, 0.3)),
			STONE_M, 0.6, 0.03, 501.0)
	# A cornice chunk by the isle-end bank on the -X side.
	_box(STONE, Vector3(-4.72, -0.31, -2.05), Vector3(0.42, 0.18, 0.3), Basis.from_euler(Vector3(0.2, 0.3, -0.35)),
			STONE_M.darkened(0.04), 0.8, 0.03, 502.0)
	# Rubble on the banks at the post feet (ground contact).
	_uv_off = 0.0
	var spots: Array = [Vector3(5.25, 0.05, -3.35), Vector3(-5.2, 0.04, 3.45), Vector3(4.2, 0.03, 3.75),
			Vector3(-4.1, 0.04, -3.7), Vector3(5.3, 0.03, 2.75)]
	for i: int in spots.size():
		var hh: float = _h(Vector3(i, 7, 7))
		_box(STONE, spots[i], Vector3(0.26, 0.14, 0.2) * (1.0 + hh * 0.6), Basis.from_euler(Vector3(0.2, hh * 6.0, 0.15)),
				STONE_M.lerp(STONE_D, hh), 0.7, 0.03, 510.0 + i)
	_uv_off = 0.55


# ------------------------------------------------------------------------------------------ output

## Non-indexed triangle arrays -> indexed ones, merging vertices whose every attribute matches.
func _weld(src: Array) -> Array:
	var sv: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	var sn: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
	var sc: PackedColorArray = src[Mesh.ARRAY_COLOR] if src[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var su: PackedVector2Array = src[Mesh.ARRAY_TEX_UV] if src[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var s2: PackedVector2Array = src[Mesh.ARRAY_TEX_UV2] if src[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	var seen := {}
	var remap := PackedInt32Array()
	remap.resize(sv.size())
	var keep := PackedInt32Array()
	for i: int in sv.size():
		var key := "%.4f,%.4f,%.4f|%.3f,%.3f,%.3f" % [sv[i].x, sv[i].y, sv[i].z, sn[i].x, sn[i].y, sn[i].z]
		if not sc.is_empty():
			key += "|%.3f,%.3f,%.3f,%.3f" % [sc[i].r, sc[i].g, sc[i].b, sc[i].a]
		if not su.is_empty():
			key += "|%.4f,%.4f" % [su[i].x, su[i].y]
		if not s2.is_empty():
			key += "|%d,%d" % [int(s2[i].x), int(s2[i].y)]
		if seen.has(key):
			remap[i] = seen[key]
		else:
			seen[key] = keep.size()
			remap[i] = keep.size()
			keep.append(i)
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var oc := PackedColorArray()
	var ou := PackedVector2Array()
	var o2 := PackedVector2Array()
	for i: int in keep:
		ov.append(sv[i])
		on.append(sn[i])
		if not sc.is_empty():
			oc.append(sc[i])
		if not su.is_empty():
			ou.append(su[i])
		if not s2.is_empty():
			o2.append(s2[i])
	out[Mesh.ARRAY_VERTEX] = ov
	out[Mesh.ARRAY_NORMAL] = on
	if not sc.is_empty():
		out[Mesh.ARRAY_COLOR] = oc
	if not su.is_empty():
		out[Mesh.ARRAY_TEX_UV] = ou
	if not s2.is_empty():
		out[Mesh.ARRAY_TEX_UV2] = o2
	out[Mesh.ARRAY_INDEX] = remap
	return out


func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _materials() -> Array[Material]:
	var ember := ShaderMaterial.new()
	ember.shader = load(GLOW_SHADER) as Shader
	# Cold embers: a deep, low smoulder that breathes slowly (each brazier at its own phase: the shader keys the
	# pulse on world position). No light: emission only.
	ember.set_shader_parameter("glow_color", Color(0.88, 0.17, 0.04))
	ember.set_shader_parameter("core_color", Color(1.0, 0.45, 0.14))
	ember.set_shader_parameter("energy", 2.2)
	ember.set_shader_parameter("pulse_speed", 0.8)
	ember.set_shader_parameter("pulse_amount", 0.32)
	ember.set_shader_parameter("sparkle", 0.0)
	_save(ember, EMBER_MAT_PATH)
	var ember_ref: Material = ResourceLoader.load(EMBER_MAT_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as Material
	var out: Array[Material] = [load(STONE_MAT_PATH) as Material, load(GOLD_MAT_PATH) as Material, ember_ref]
	return out


func _commit() -> ArrayMesh:
	var mats: Array[Material] = _materials()
	var mesh := ArrayMesh.new()
	var report: Array[String] = []
	var total: int = 0
	var aabb := AABB()
	var first := true
	for s: int in 3:
		var sd: SurfData = _s[s]
		if sd.v.is_empty():
			continue
		for i: int in sd.v.size():
			var cc: Color = sd.c[i]
			cc.a = clampf((sd.v[i].y - GRAD_Y0) / GRAD_SPAN, 0.0, 1.0)
			sd.c[i] = cc
			if first:
				aabb = AABB(sd.v[i], Vector3.ZERO)
				first = false
			else:
				aabb = aabb.expand(sd.v[i])
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = sd.v
		arr[Mesh.ARRAY_NORMAL] = sd.n
		arr[Mesh.ARRAY_COLOR] = sd.c
		if s == STONE:
			arr[Mesh.ARRAY_TEX_UV] = sd.uv
			arr[Mesh.ARRAY_TEX_UV2] = sd.uv2
		var welded: Array = _weld(arr)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, welded)
		var si: int = mesh.get_surface_count() - 1
		mesh.surface_set_name(si, SURF_NAMES[s])
		mesh.surface_set_material(si, mats[s])
		var tris: int = int(sd.v.size() / 3.0)
		total += tris
		report.append("  surface %-6s %5d tris, %5d verts" % [SURF_NAMES[s], tris,
				(welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()])
	_save(mesh, MESH_PATH)
	print("lane_bridge.res: %d surfaces, %d tris, aabb %s" % [mesh.get_surface_count(), total, aabb])
	for line: String in report:
		print(line)
	return ResourceLoader.load(MESH_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as ArrayMesh


func _pack_scene(mesh: ArrayMesh) -> void:
	var root := Node3D.new()
	root.name = "LaneBridge"
	root.set_script(load(ART_SCRIPT))
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	root.add_child(mi)
	mi.owner = root
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	if err != OK:
		push_error("pack failed %d" % err)
	_save(ps, SCENE_PATH)
	root.free()
