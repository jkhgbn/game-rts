extends RefCounted
## G-F Quartermeet identity (docs/art/gf_quartermeet.md): the Quartermeet-only meshes, built in code once per run
## (static cache) in the shared nature_mat.tres vertex format (nature_painted.gdshader header: COLOR.rgb sRGB colour,
## COLOR.a height gradient, UV.x wind weight (stone: moss amount), UV.y local height, UV2 = (variant mask, kind)).
## No new material, shader, light or particle. Reach it with load():
##     var qm: GDScript = load("res://art/environment/quartermeet/quartermeet_meshes.gd")
##     qm.stook()          # harvest stook ~1.3 m tall, ~0.6 m wide: straw sheaves leaning together, tied (7 / 6 / 5)
##     qm.bale()           # round hay bale ~1.25 m lying on its side, 3 variants (one, one squat, a pair)
##     qm.wall()           # drystone wall segment 2.4 m x ~0.6 m, granite stones + coping, 3 variants (whole, slumped,
##                         # half-fallen with stones at its foot)
##     qm.standing_stone() # the crown-isle landmark: a ~4.8 m granite menhir with a straw harvest garland (one shape)
## Origins sit on the ground (the standing stone: the water surface, 0.35 m below the ground). Straw uses the bark kind
## (its colour is kept through the autumn swap, the bark streaks read as straw); stones use the stone kind (moss caps).

const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const KIND_BARK := 0
const KIND_STONE := 3
const V0 := 1
const V1 := 2
const V2 := 4

## Palette (sRGB).
const STRAW_D := Color(0.52, 0.45, 0.27)
const STRAW := Color(0.74, 0.66, 0.42)
const STRAW_L := Color(0.86, 0.80, 0.56)
const TIE := Color(0.36, 0.30, 0.20)
const BALE_END := Color(0.60, 0.53, 0.34)
const STONE_D := Color(0.36, 0.355, 0.34)
const STONE := Color(0.50, 0.49, 0.46)
const STONE_L := Color(0.62, 0.61, 0.57)
const MENHIR := Color(0.47, 0.46, 0.44)
const MENHIR_L := Color(0.60, 0.59, 0.55)

static var _cache: Dictionary = {}


static func stook() -> ArrayMesh:
	if not _cache.has(&"stook"):
		_cache[&"stook"] = _build_stook()
	return _cache[&"stook"]


static func bale() -> ArrayMesh:
	if not _cache.has(&"bale"):
		_cache[&"bale"] = _build_bale()
	return _cache[&"bale"]


static func wall() -> ArrayMesh:
	if not _cache.has(&"wall"):
		_cache[&"wall"] = _build_wall()
	return _cache[&"wall"]


static func standing_stone() -> ArrayMesh:
	if not _cache.has(&"menhir"):
		_cache[&"menhir"] = _build_menhir()
	return _cache[&"menhir"]


## Drops the cached meshes (tests / tools before quitting; the next call rebuilds them).
static func clear_cache() -> void:
	_cache.clear()


## Triangles per variant of a mesh built here (tests / the note): [v0, v1, v2].
static func variant_tris(mesh: ArrayMesh) -> Array[int]:
	var out: Array[int] = [0, 0, 0]
	if mesh == null or mesh.get_surface_count() == 0:
		return out
	var a: Array = mesh.surface_get_arrays(0)
	var uv2: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	for t: int in uv2.size() / 3:
		var m := int(uv2[t * 3].x)
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				out[k] += 1
	return out


# ---------------------------------------------------------------- builder

class Builder:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var conv := 1.0
	var wind_k := 0.1

	func _init() -> void:
		var arr: Array = BoxMesh.new().get_mesh_arrays()
		var bv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var bi: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var fn: Vector3 = (bv[bi[1]] - bv[bi[0]]).cross(bv[bi[2]] - bv[bi[0]])
		conv = 1.0 if fn.dot(bn[bi[0]]) >= 0.0 else -1.0

	## One triangle, ordered so its front face looks along `out` (Godot's winding read from BoxMesh).
	func tri(a: Vector3, b: Vector3, cc: Vector3, na: Vector3, nb: Vector3, nc: Vector3, out: Vector3,
			col: Color, kind: int, mask: int) -> void:
		var fn: Vector3 = (b - a).cross(cc - a)
		if fn.dot(out) * conv < 0.0:
			var t := b
			b = cc
			cc = t
			var tn := nb
			nb = nc
			nc = tn
		for p: Array in [[a, na], [b, nb], [cc, nc]]:
			var pos: Vector3 = p[0]
			v.append(pos)
			n.append((p[1] as Vector3).normalized())
			c.append(Color(col.r, col.g, col.b, -1.0))
			uv.append(Vector2(clampf(maxf(pos.y, 0.0) * wind_k, 0.0, 1.0), pos.y))
			uv2.append(Vector2(mask, kind))

	## A tube along `path` (radius per point, `sides` round), smooth radial normals, colour from col0 to col1.
	func tube(path: Array[Vector3], radii: Array[float], sides: int, col0: Color, col1: Color, kind: int,
			mask: int) -> void:
		var rings: Array = []
		for i: int in path.size():
			var t: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
			var side := t.cross(Vector3.UP)
			if side.length() < 0.01:
				side = t.cross(Vector3.RIGHT)
			side = side.normalized()
			var up := side.cross(t).normalized()
			var ring: Array[Vector3] = []
			for s: int in sides:
				var a := s * TAU / sides
				ring.append(side * cos(a) + up * sin(a))
			rings.append(ring)
		for i: int in path.size() - 1:
			var ra: Array = rings[i]
			var rb: Array = rings[i + 1]
			var col := col0.lerp(col1, float(i) / maxf(path.size() - 2, 1.0))
			for s: int in sides:
				var s2 := (s + 1) % sides
				var a0: Vector3 = path[i] + (ra[s] as Vector3) * radii[i]
				var a1: Vector3 = path[i] + (ra[s2] as Vector3) * radii[i]
				var b0: Vector3 = path[i + 1] + (rb[s] as Vector3) * radii[i + 1]
				var b1: Vector3 = path[i + 1] + (rb[s2] as Vector3) * radii[i + 1]
				var out: Vector3 = (ra[s] as Vector3) + (ra[s2] as Vector3)
				if radii[i + 1] <= 0.001:
					tri(a0, a1, b0, ra[s], ra[s2], rb[s], out, col, kind, mask)
				else:
					tri(a0, a1, b1, ra[s], ra[s2], rb[s2], out, col, kind, mask)
					tri(a0, b1, b0, ra[s], rb[s2], rb[s], out, col, kind, mask)

	## A low-poly lumpy ellipsoid (stones), flat-ish normals bent from its centre, darker underside.
	func blob(ctr: Vector3, radii: Vector3, segs: int, rings: int, col: Color, col_top: Color, kind: int, mask: int,
			seed: float, yaw: float = 0.0) -> void:
		var pts: Array = []
		var rot := Basis(Vector3.UP, yaw)
		for r: int in rings + 1:
			var th := PI * float(r) / float(rings)
			var row: Array[Vector3] = []
			for s: int in segs:
				var ph := TAU * float(s) / float(segs) + seed * 1.7
				var j: float = 1.0 + (_hh(Vector3(seed, r, s)) - 0.5) * 0.3
				row.append(Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)) * j)
			pts.append(row)
		for r: int in rings:
			var ra: Array = pts[r]
			var rb: Array = pts[r + 1]
			var col_r := col_top.lerp(col, float(r) / float(rings))
			for s: int in segs:
				var s2 := (s + 1) % segs
				var a0: Vector3 = ra[s]
				var a1: Vector3 = ra[s2]
				var b0: Vector3 = rb[s]
				var b1: Vector3 = rb[s2]
				var out := rot * ((a0 + a1 + b0 + b1) * 0.25)
				var p00 := ctr + rot * (a0 * radii)
				var p01 := ctr + rot * (a1 * radii)
				var p10 := ctr + rot * (b0 * radii)
				var p11 := ctr + rot * (b1 * radii)
				if r > 0:
					tri(p00, p01, p11, rot * a0, rot * a1, rot * b1, out, col_r, kind, mask)
				if r < rings - 1:
					tri(p00, p11, p10, rot * a0, rot * b1, rot * b0, out, col_r, kind, mask)

	## A flat disc (n-gon fan) at `ctr` facing `nrm`, radius `r`, rim colour `col`, centre `col_c`.
	func disc(ctr: Vector3, nrm: Vector3, r: float, sides: int, col: Color, kind: int, mask: int) -> void:
		nrm = nrm.normalized()
		var side := nrm.cross(Vector3.UP)
		if side.length() < 0.01:
			side = nrm.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(nrm).normalized()
		for s: int in sides:
			var a0 := s * TAU / sides
			var a1 := (s + 1) * TAU / sides
			var p0 := ctr + (side * cos(a0) + up * sin(a0)) * r
			var p1 := ctr + (side * cos(a1) + up * sin(a1)) * r
			tri(ctr, p0, p1, nrm, nrm, nrm, nrm, col, kind, mask)

	func to_mesh() -> ArrayMesh:
		var miny := INF
		var maxy := -INF
		for p: Vector3 in v:
			miny = minf(miny, p.y)
			maxy = maxf(maxy, p.y)
		var span := maxf(maxy - miny, 0.01)
		for i: int in v.size():
			var cc: Color = c[i]
			cc.a = clampf((v[i].y - miny) / span, 0.0, 1.0)
			c[i] = cc
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_COLOR] = c
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_TEX_UV2] = uv2
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		if ResourceLoader.exists(NATURE_MAT):
			mesh.surface_set_material(0, load(NATURE_MAT) as Material)
		return mesh

	static func _hh(p: Vector3) -> float:
		return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


static func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


# ---------------------------------------------------------------- stook

## Sheaves leaning on each other: each a 5-sided bundle splayed at the butt, pinched at the tie, a loose ear tuft above.
static func _build_stook() -> ArrayMesh:
	var b := Builder.new()
	b.wind_k = 0.08
	var counts: Array[int] = [7, 6, 5]
	for var_i: int in 3:
		var mask: int = [V0, V1, V2][var_i]
		var seed := float(var_i) * 7.7 + 1.0
		var nsh := counts[var_i]
		var top := 1.3 - var_i * 0.08
		var spread := 0.27 - var_i * 0.02
		for k: int in nsh:
			var a := k * TAU / float(nsh) + seed + (_h(Vector3(k, seed, 1.0)) - 0.5) * 0.4
			var dir := Vector3(cos(a), 0.0, sin(a))
			var butt := dir * spread * (0.9 + _h(Vector3(seed, k, 2.0)) * 0.25)
			var tie := dir * 0.06 + Vector3(0.0, top * 0.6, 0.0)
			var ear := dir * 0.2 + Vector3(0.0, top + _h(Vector3(k, 3.0, seed)) * 0.1, 0.0)
			var path: Array[Vector3] = [butt, butt.lerp(tie, 0.5) + dir * 0.03, tie, tie.lerp(ear, 0.55) + dir * 0.06, ear]
			var radii: Array[float] = [0.09, 0.075, 0.05, 0.08, 0.015]
			var col_l := STRAW_L if k % 2 == 0 else STRAW
			b.tube(path, radii, 5, STRAW_D, col_l, KIND_BARK, mask)
			# The twine round each sheaf's waist.
			var band: Array[Vector3] = [tie + Vector3(0.0, -0.035, 0.0), tie + Vector3(0.0, 0.035, 0.0)]
			var br: Array[float] = [0.058, 0.058]
			b.tube(band, br, 5, TIE, TIE, KIND_BARK, mask)
	return b.to_mesh()


# ---------------------------------------------------------------- bale

static func _bale_at(b: Builder, ctr: Vector3, axis: Vector3, r: float, half_len: float, squash: float,
		mask: int) -> void:
	axis = axis.normalized()
	var sides := 12
	var side := axis.cross(Vector3.UP).normalized()
	var up := Vector3.UP
	var ring_a: Array[Vector3] = []
	var ring_b: Array[Vector3] = []
	var nrm: Array[Vector3] = []
	for s: int in sides:
		var ang := s * TAU / sides
		var d := side * cos(ang) + up * sin(ang) * squash
		var bulge := 1.0 + (_h(Vector3(s, ctr.x, 1.0)) - 0.5) * 0.06
		nrm.append(side * cos(ang) + up * sin(ang))
		ring_a.append(ctr + d * r * bulge - axis * half_len)
		ring_b.append(ctr + d * r * bulge + axis * half_len)
	for s: int in sides:
		var s2 := (s + 1) % sides
		var col := STRAW if (nrm[s] as Vector3).y > 0.0 else STRAW_D
		var out := nrm[s] + nrm[s2]
		b.tri(ring_a[s], ring_a[s2], ring_b[s2], nrm[s], nrm[s2], nrm[s2], out, col, KIND_BARK, mask)
		b.tri(ring_a[s], ring_b[s2], ring_b[s], nrm[s], nrm[s2], nrm[s], out, col, KIND_BARK, mask)
	# Ends: a lighter rim ring and a darker rolled core (the spiral reads as two tones).
	for e: float in [-1.0, 1.0]:
		var c := ctr + axis * half_len * e
		var on := axis * e
		for s: int in sides:
			var s2 := (s + 1) % sides
			var p0: Vector3 = (ring_a[s] if e < 0.0 else ring_b[s])
			var p1: Vector3 = (ring_a[s2] if e < 0.0 else ring_b[s2])
			var m0 := c + (p0 - c) * 0.55 + on * 0.02
			var m1 := c + (p1 - c) * 0.55 + on * 0.02
			b.tri(p0, p1, m1, on, on, on, on, STRAW_L, KIND_BARK, mask)
			b.tri(p0, m1, m0, on, on, on, on, STRAW_L, KIND_BARK, mask)
			b.tri(c + on * 0.04, m0, m1, on, on, on, on, BALE_END, KIND_BARK, mask)


static func _build_bale() -> ArrayMesh:
	var b := Builder.new()
	b.wind_k = 0.0
	_bale_at(b, Vector3(0.0, 0.6, 0.0), Vector3.RIGHT, 0.62, 0.55, 1.0, V0)
	_bale_at(b, Vector3(0.0, 0.54, 0.0), Vector3(1.0, 0.0, 0.2), 0.64, 0.55, 0.86, V1)
	_bale_at(b, Vector3(-0.66, 0.58, 0.0), Vector3(0.1, 0.0, 1.0), 0.6, 0.55, 0.97, V2)
	_bale_at(b, Vector3(0.68, 0.58, 0.2), Vector3(-0.1, 0.0, 1.0), 0.6, 0.55, 0.97, V2)
	return b.to_mesh()


# ---------------------------------------------------------------- drystone wall

## Courses of flat granite stones along X (length 2.4 m), a row of on-edge coping stones on top. Variant 1 slumps in
## the middle; variant 2 has a fallen section with its stones lying at the foot.
static func _build_wall() -> ArrayMesh:
	var b := Builder.new()
	b.wind_k = 0.55            # stone: UV.x = moss amount, more on the top courses
	var length := 2.4
	for var_i: int in 3:
		var mask: int = [V0, V1, V2][var_i]
		var seed := float(var_i) * 5.3 + 3.0
		var courses := 3
		for cr: int in courses:
			var y := 0.1 + cr * 0.15
			var x := -length * 0.5 + (0.12 if cr % 2 == 1 else 0.0)
			var k := 0
			while x < length * 0.5 - 0.1:
				var w := 0.34 + _h(Vector3(seed, cr, k)) * 0.22
				var cx := x + w * 0.5
				var slump := 0.0
				if var_i == 1:
					slump = 0.12 * maxf(0.0, 1.0 - absf(cx) / 0.9)
				var fallen := var_i == 2 and cr >= 1 and cx > -0.1 and cx < 0.9
				if not fallen:
					var col := STONE.lerp(STONE_L if k % 3 == 0 else STONE_D, _h(Vector3(k, cr, seed)) * 0.7)
					b.blob(Vector3(cx, y - slump, (_h(Vector3(k, seed, cr)) - 0.5) * 0.05),
						Vector3(w * 0.52, 0.095, 0.24 - cr * 0.025), 5, 3, col.darkened(0.12), col, KIND_STONE, mask,
						seed + k + cr * 10.0)
				x += w
				k += 1
		# Coping: stones on edge along the top.
		var xc := -length * 0.5 + 0.08
		var j := 0
		while xc < length * 0.5 - 0.08:
			var slump2 := 0.12 * maxf(0.0, 1.0 - absf(xc) / 0.9) if var_i == 1 else 0.0
			var gone := var_i == 2 and xc > -0.15 and xc < 0.95
			if not gone:
				var col2 := STONE_D.lerp(STONE, _h(Vector3(j, seed, 7.0)))
				b.blob(Vector3(xc + 0.08, 0.6 - slump2, 0.0), Vector3(0.07, 0.13, 0.17), 4, 3, col2.darkened(0.1),
					col2, KIND_STONE, mask, seed + 40.0 + j, (_h(Vector3(j, 2.0, seed)) - 0.5) * 0.5)
			xc += 0.16 + _h(Vector3(seed, j, 9.0)) * 0.05
			j += 1
		if var_i == 2:
			# The fallen stones at the foot of the gap.
			for f: int in 5:
				var fx := 0.0 + f * 0.2 + (_h(Vector3(f, seed, 11.0)) - 0.5) * 0.2
				var fz := (0.35 + _h(Vector3(seed, f, 12.0)) * 0.25) * (1.0 if f % 2 == 0 else -1.0)
				var col3 := STONE.lerp(STONE_D, _h(Vector3(f, 13.0, seed)))
				b.blob(Vector3(fx, 0.08, fz), Vector3(0.17, 0.09, 0.13), 5, 3, col3.darkened(0.12), col3, KIND_STONE,
					mask, seed + 70.0 + f, f * 0.9)
	return b.to_mesh()


# ---------------------------------------------------------------- standing stone

## A tall granite menhir rising from the moat: a faceted slab tapering and leaning a little, a rounded crown, a straw
## harvest garland round it with tied sheaves, boulders at its foot (origin = water surface).
static func _build_menhir() -> ArrayMesh:
	var b := Builder.new()
	b.wind_k = 0.07
	var h := 4.8
	var rings := 8
	var sides := 7
	var pts: Array = []
	for r: int in rings + 1:
		var t := float(r) / float(rings)
		var y := -0.6 + t * (h + 0.6)
		var wx := lerpf(0.78, 0.5, t) * (1.0 - 0.55 * pow(t, 6.0))
		var wz := lerpf(0.46, 0.32, t) * (1.0 - 0.55 * pow(t, 6.0))
		var lean := Vector3(0.22, 0.0, 0.05) * t * t
		var row: Array[Vector3] = []
		for s: int in sides:
			var a := s * TAU / sides + t * 0.25
			var j := 1.0 + (_h(Vector3(r, s, 3.0)) - 0.5) * 0.18
			row.append(Vector3(cos(a) * wx * j, y, sin(a) * wz * j) + lean)
		pts.append(row)
	var axis_c: Array[Vector3] = []
	for r: int in rings + 1:
		var sum := Vector3.ZERO
		for p: Vector3 in pts[r]:
			sum += p
		axis_c.append(sum / float(sides))
	for r: int in rings:
		var ra: Array = pts[r]
		var rb: Array = pts[r + 1]
		var t := float(r) / float(rings)
		var col := MENHIR.lerp(MENHIR_L, t * 0.6)
		for s: int in sides:
			var s2 := (s + 1) % sides
			var a0: Vector3 = ra[s]
			var a1: Vector3 = ra[s2]
			var b0: Vector3 = rb[s]
			var b1: Vector3 = rb[s2]
			var out := (a0 + a1 + b0 + b1) * 0.25 - axis_c[r].lerp(axis_c[r + 1], 0.5)
			out.y = 0.0
			b.tri(a0, a1, b1, out, out, out, out, col, KIND_STONE, 0)
			b.tri(a0, b1, b0, out, out, out, out, col, KIND_STONE, 0)
	# The crown cap (a fan to the top point).
	var top_c: Vector3 = axis_c[rings] + Vector3(0.0, 0.18, 0.0)
	var last: Array = pts[rings]
	for s: int in sides:
		var s2 := (s + 1) % sides
		var a0: Vector3 = last[s]
		var a1: Vector3 = last[s2]
		var out := (a0 + a1) * 0.5 - axis_c[rings] + Vector3(0.0, 0.6, 0.0)
		b.tri(a0, a1, top_c, out, out, Vector3.UP, out, MENHIR_L, KIND_STONE, 0)
	# The harvest garland: a twisted straw rope round the stone at ~2.6 m, sagging on one side, sheaves tied on.
	var gy := 2.6
	var gpath: Array[Vector3] = []
	var gr: Array[float] = []
	var seg := 14
	var t_g := (gy + 0.6) / (h + 0.6)
	var cx: Vector3 = axis_c[0].lerp(axis_c[rings], t_g)
	var gwx := lerpf(0.78, 0.5, t_g) * 1.12
	var gwz := lerpf(0.46, 0.32, t_g) * 1.12
	for i: int in seg + 1:
		var a := i * TAU / seg
		var sag := 0.22 * maxf(0.0, cos(a - 0.6))
		gpath.append(Vector3(cx.x + cos(a) * gwx, gy - sag, cx.z + sin(a) * gwz))
		gr.append(0.07)
	b.tube(gpath, gr, 5, STRAW, STRAW_L, KIND_BARK, 0)
	for k: int in 3:
		var a := 0.6 + (k - 1) * 0.7
		var p := Vector3(cx.x + cos(a) * gwx, gy - 0.22 * maxf(0.0, cos(a - 0.6)), cx.z + sin(a) * gwz)
		var out := Vector3(cos(a), 0.0, sin(a))
		var path: Array[Vector3] = [p + Vector3(0.0, 0.05, 0.0), p + out * 0.08 - Vector3(0.0, 0.3, 0.0),
			p + out * 0.12 - Vector3(0.0, 0.6, 0.0)]
		var radii: Array[float] = [0.05, 0.08, 0.12]
		b.tube(path, radii, 5, STRAW_D, STRAW_L, KIND_BARK, 0)
	# Boulders at its foot, breaking the water line.
	for k: int in 4:
		var a := k * TAU / 4.0 + 0.4
		var col := STONE.lerp(STONE_D, _h(Vector3(k, 5.0, 1.0)))
		b.blob(Vector3(cos(a) * 0.85, 0.05, sin(a) * 0.6), Vector3(0.38, 0.3, 0.32), 6, 3, col.darkened(0.15), col,
			KIND_STONE, 0, 30.0 + k, a)
	return b.to_mesh()
