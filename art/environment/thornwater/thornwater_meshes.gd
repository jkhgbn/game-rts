extends RefCounted
## G-F review 2 item 9 (docs/art/gf_thornwater.md): the two Thornwater-only meshes, built in code once per run (static
## cache, ~2 ms) in the shared nature_mat.tres vertex format (nature_painted.gdshader header: COLOR.rgb sRGB colour,
## COLOR.a height gradient, UV.x wind weight, UV.y local height, UV2 = (variant mask, kind)). No new material, shader,
## light or particle. Reach it with load():
##     var tm: GDScript = load("res://art/environment/thornwater/thornwater_meshes.gd")
##     tm.thicket()     # bramble thicket ~2.4 x 1.2 m, 3 variants by the variant mask (blackberry / dog-rose / dead
##                      # canes with red hips): arching thorny canes over a mound of dark leaf clumps
##     tm.thorn_spire() # the crown-isle landmark: three thorn canes braided into a ~6 m twisted spire with root canes
##                      # splaying into the moat, thorns, leaf clumps and pale roses near the top (one shape)
## Both meshes have their origin where they meet the ground (the spire: the water surface, 0.35 m below the ground).

const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const KIND_BARK := 0
const KIND_IVY := 5
const V0 := 1
const V1 := 2
const V2 := 4

## Palette (sRGB).
const CANE_D := Color(0.20, 0.10, 0.085)
const CANE_L := Color(0.40, 0.21, 0.15)
const CANE_DEAD := Color(0.42, 0.36, 0.28)
const THORN := Color(0.66, 0.58, 0.44)
const LEAF_D := Color(0.075, 0.18, 0.095)
const LEAF := Color(0.14, 0.29, 0.13)
const LEAF_L := Color(0.24, 0.40, 0.18)
const BERRY := Color(0.15, 0.05, 0.13)
const ROSE := Color(0.93, 0.66, 0.74)
const ROSE_W := Color(0.95, 0.92, 0.85)
const HIP := Color(0.72, 0.16, 0.10)
const ROOT := Color(0.16, 0.12, 0.09)

static var _cache: Dictionary = {}


## The bramble thicket (cached).
static func thicket() -> ArrayMesh:
	if not _cache.has(&"thicket"):
		_cache[&"thicket"] = _build_thicket()
	return _cache[&"thicket"]


## The thorn spire (cached).
static func thorn_spire() -> ArrayMesh:
	if not _cache.has(&"spire"):
		_cache[&"spire"] = _build_spire()
	return _cache[&"spire"]


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
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var n := idx.size() / 3 if not idx.is_empty() else uv2.size() / 3
	for t: int in n:
		var vi: int = idx[t * 3] if not idx.is_empty() else t * 3
		var m := int(uv2[vi].x)
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
	var wind_k := 0.15

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

	## A tube along `path` (radius per point, `sides` round), smooth radial normals, colour from col0 (root) to col1.
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

	## A 3-sided thorn: base centre `p`, pointing along `d`, length `l`, base radius `r` (flat normals).
	func thorn(p: Vector3, d: Vector3, l: float, r: float, mask: int) -> void:
		d = d.normalized()
		var side := d.cross(Vector3.UP)
		if side.length() < 0.01:
			side = d.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(d).normalized()
		var tip := p + d * l
		var base: Array[Vector3] = []
		for k: int in 3:
			var a := k * TAU / 3.0
			base.append(p + (side * cos(a) + up * sin(a)) * r)
		for k: int in 3:
			var a: Vector3 = base[k]
			var b: Vector3 = base[(k + 1) % 3]
			var out := ((a + b) * 0.5 - p).normalized() + d * 0.2
			tri(a, b, tip, out, out, out, out, THORN, KIND_BARK, mask)

	## A low-poly ellipsoid clump (leaves / berries), normals bent away from its centre (painted crown shading).
	func blob(ctr: Vector3, radii: Vector3, segs: int, rings: int, col: Color, col_top: Color, kind: int, mask: int,
			seed: float) -> void:
		var pts: Array = []
		for r: int in rings + 1:
			var th := PI * float(r) / float(rings)
			var row: Array[Vector3] = []
			for s: int in segs:
				var ph := TAU * float(s) / float(segs) + seed * 1.7
				var hv: float = fposmod(sin(Vector3(seed, r, s).dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)
				var j: float = 1.0 + (hv - 0.5) * 0.28
				var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
				row.append(d * j)
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
				var out := (a0 + a1 + b0 + b1) * 0.25
				var p00 := ctr + a0 * radii
				var p01 := ctr + a1 * radii
				var p10 := ctr + b0 * radii
				var p11 := ctr + b1 * radii
				if r > 0:
					tri(p00, p01, p11, a0, a1, b1, out, col_r, kind, mask)
				if r < rings - 1:
					tri(p00, p11, p10, a0, b1, b0, out, col_r, kind, mask)

	## A flat 5-petal flower (a star of triangles) facing `up`, radius `r`.
	func flower(p: Vector3, up: Vector3, r: float, col: Color, mask: int, seed: float) -> void:
		up = up.normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		var fwd := side.cross(up).normalized()
		for k: int in 5:
			var a := k * TAU / 5.0 + seed
			var a1 := a - 0.42
			var a2 := a + 0.42
			var tip := p + (side * cos(a) + fwd * sin(a)) * r + up * 0.02
			var l := p + (side * cos(a1) + fwd * sin(a1)) * r * 0.55
			var rr := p + (side * cos(a2) + fwd * sin(a2)) * r * 0.55
			tri(p + up * 0.03, l, tip, up, up, up, up, col, KIND_IVY, mask)
			tri(p + up * 0.03, tip, rr, up, up, up, up, col, KIND_IVY, mask)

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


static func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


## An arching cane from `root` out along `dir` (xz), up to `h`, landing `reach` metres out; returns its points.
static func _arch(root: Vector3, dir: Vector3, h: float, reach: float, steps: int) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	dir = Vector3(dir.x, 0.0, dir.z).normalized()
	for i: int in steps + 1:
		var t := float(i) / float(steps)
		var y := sin(t * PI * 0.92) * h + (0.0 if t < 0.9 else -0.1 * (t - 0.9) * 10.0)
		pts.append(root + dir * reach * t + Vector3(0.0, maxf(y, -0.05), 0.0))
	return pts


static func _build_thicket() -> ArrayMesh:
	var b := Builder.new()
	b.wind_k = 0.18
	for var_i: int in 3:
		var mask: int = [V0, V1, V2][var_i]
		var seed := float(var_i) * 11.3 + 2.0
		var dead := var_i == 2
		var dark := LEAF_D if not dead else LEAF_D.lerp(CANE_DEAD, 0.3)
		# A dome mound of leaf clumps: one big core, a ring of smaller clumps round it.
		b.blob(Vector3(0.0, 0.5, 0.0), Vector3(0.78, 0.52, 0.7) * (0.9 if dead else 1.0), 7, 4, dark,
			LEAF if not dead else LEAF.lerp(CANE_DEAD, 0.4), KIND_IVY, mask, seed)
		var n_ring: int = [6, 5, 4][var_i]
		for k: int in n_ring:
			var a := k * TAU / float(n_ring) + seed
			var rr := 0.62 + _h(Vector3(seed, k, 1.0)) * 0.2
			var ctr := Vector3(cos(a) * rr, 0.28 + _h(Vector3(k, seed, 2.0)) * 0.12, sin(a) * rr * 0.9)
			var rad := Vector3(0.42, 0.3, 0.4) * (0.8 + _h(Vector3(k, 3.0, seed)) * 0.4)
			var top := LEAF_L if k % 2 == 0 else LEAF
			if dead:
				top = LEAF.lerp(CANE_DEAD, 0.5)
			b.blob(ctr, rad, 6, 3, dark, top, KIND_IVY, mask, seed + k)
		# Canes arching over the mound (rooted inside it), thorny, tips dipping at its edge.
		var n_canes: int = [5, 5, 5][var_i]
		for k: int in n_canes:
			var a := k * TAU / float(n_canes) + seed * 0.7 + _h(Vector3(k, seed, 5.0)) * 0.5
			var dir := Vector3(cos(a), 0.0, sin(a))
			var root := dir * 0.15 + Vector3(0.0, 0.55, 0.0)
			var h := 0.45 + _h(Vector3(seed, k, 7.0)) * 0.3
			var reach := (0.95 if not dead else 0.8) + _h(Vector3(k, seed, 8.0)) * 0.25
			var pts := _arch(root, dir, h, reach, 5)
			for j: int in pts.size():
				var q: Vector3 = pts[j]
				q.y = maxf(q.y - float(j) / 5.0 * 0.45, 0.12)
				pts[j] = q
			var radii: Array[float] = [0.05, 0.045, 0.04, 0.032, 0.024, 0.014]
			var c0 := CANE_D if not dead else CANE_DEAD.darkened(0.25)
			var c1 := CANE_L if not dead else CANE_DEAD
			b.tube(pts, radii, 4, c0, c1, KIND_BARK, mask)
			for j: int in range(1, pts.size() - 1):
				var t: Vector3 = (pts[j + 1] - pts[j - 1]).normalized()
				var out := t.cross(Vector3.UP).normalized() * (1.0 if j % 2 == 0 else -1.0) + Vector3.UP * 0.5
				b.thorn(pts[j], out - t * 0.3, 0.06, 0.012, mask)
			var top_p: Vector3 = pts[2] + Vector3(0.0, 0.06, 0.0)
			if var_i == 0:
				for q: int in 3:
					var off := Vector3(cos(q * 2.1 + k), 0.0, sin(q * 2.1 + k)) * 0.07
					b.blob(top_p + off, Vector3(0.05, 0.05, 0.05), 4, 2, BERRY, BERRY.lightened(0.2), KIND_IVY, mask,
						k + q)
			elif var_i == 1:
				b.flower(top_p, Vector3(0.0, 1.0, 0.0) + dir * 0.3, 0.13, ROSE if k % 2 == 0 else ROSE_W, mask, k)
			elif k % 2 == 0:
				b.blob(top_p, Vector3(0.055, 0.07, 0.055), 4, 2, HIP, HIP.lightened(0.2), KIND_IVY, mask, k)
	return b.to_mesh()


static func _build_spire() -> ArrayMesh:
	var b := Builder.new()
	b.wind_k = 0.01
	var height := 6.6
	var steps := 16
	# Three thick canes braided round each other, the braid shrinking to a hooked tip.
	for cane: int in 3:
		var pts: Array[Vector3] = []
		var radii: Array[float] = []
		var top := height * (1.0 - 0.07 * cane)
		for i: int in steps + 1:
			var t := float(i) / float(steps)
			var a := cane * TAU / 3.0 + t * TAU * 1.25
			var br := lerpf(0.62, 0.06, pow(t, 0.85))
			var hook := Vector3(0.55, 0.0, 0.2) * pow(t, 3.0)
			pts.append(Vector3(cos(a) * br, t * top, sin(a) * br) + hook)
			radii.append(lerpf(0.34, 0.02, pow(t, 0.75)))
		b.tube(pts, radii, 7, CANE_D, CANE_L, KIND_BARK, 0)
		for i: int in range(1, steps):
			var t := float(i) / float(steps)
			var tan: Vector3 = (pts[i + 1] - pts[i - 1]).normalized()
			for k: int in 2:
				var a := float(i) * 2.1 + k * PI + cane
				var side := tan.cross(Vector3.UP).normalized()
				var up := side.cross(tan).normalized()
				var out := side * cos(a) + up * sin(a)
				b.thorn(pts[i] + out * radii[i] * 0.85, out + Vector3.UP * 0.2, lerpf(0.5, 0.14, t), lerpf(0.11, 0.03, t),
					0)
	# Side canes curling out of the braid, each with a leaf clump and (higher up) a rose.
	for k: int in 7:
		var t0 := 0.12 + k * 0.11
		var a := k * 2.4 + 0.5
		var dir := Vector3(cos(a), 0.0, sin(a))
		var root := Vector3(0.0, t0 * height, 0.0) + dir * lerpf(0.55, 0.12, t0)
		var cane_len := lerpf(1.7, 0.9, t0)
		var pts: Array[Vector3] = []
		for i: int in 6:
			var t := float(i) / 5.0
			var curl := dir.rotated(Vector3.UP, t * 1.4)
			pts.append(root + curl * t * cane_len + Vector3(0.0, sin(t * PI) * 0.55 - t * 0.25, 0.0))
		var radii: Array[float] = [0.12, 0.1, 0.08, 0.06, 0.04, 0.0]
		b.tube(pts, radii, 5, CANE_D, CANE_L, KIND_BARK, 0)
		for i: int in range(1, 5):
			var tan: Vector3 = (pts[i + 1] - pts[i - 1]).normalized()
			b.thorn(pts[i], tan.cross(Vector3.UP).normalized() * (1.0 if i % 2 == 0 else -1.0) + Vector3.UP * 0.3,
				0.2, 0.04, 0)
		b.blob(pts[3] + Vector3(0.0, 0.15, 0.0), Vector3(0.55, 0.38, 0.5) * lerpf(1.0, 0.7, t0), 7, 3, LEAF_D,
			LEAF_L if k % 2 == 0 else LEAF, KIND_IVY, 0, k)
		if k >= 2:
			b.flower(pts[4] + Vector3(0.0, 0.2, 0.0), Vector3.UP + dir * 0.5, 0.24, ROSE if k % 2 == 0 else ROSE_W, 0, k)
	# Root canes splaying into the water (the origin is the water surface).
	for k: int in 7:
		var a := k * TAU / 7.0 + 0.3
		var dir := Vector3(cos(a), 0.0, sin(a))
		var pts: Array[Vector3] = [Vector3(0.0, 0.7, 0.0) + dir * 0.35, dir * 0.95 + Vector3(0.0, 0.4, 0.0),
			dir * 1.45 + Vector3(0.0, 0.05, 0.0), dir * 1.8 + Vector3(0.0, -0.3, 0.0)]
		var radii: Array[float] = [0.22, 0.16, 0.1, 0.05]
		b.tube(pts, radii, 5, ROOT, CANE_D, KIND_BARK, 0)
		b.thorn(pts[1] + Vector3(0.0, radii[1] * 0.8, 0.0), Vector3.UP + dir * 0.4, 0.25, 0.05, 0)
	# Leaf mass and a crown of roses at the hooked tip.
	b.blob(Vector3(0.45, height * 0.82, 0.15), Vector3(0.55, 0.4, 0.5), 7, 3, LEAF_D, LEAF, KIND_IVY, 0, 9.0)
	b.blob(Vector3(0.05, height * 0.6, -0.3), Vector3(0.6, 0.42, 0.55), 7, 3, LEAF_D, LEAF_L, KIND_IVY, 0, 4.0)
	b.blob(Vector3(-0.3, height * 0.38, 0.3), Vector3(0.7, 0.45, 0.6), 7, 3, LEAF_D, LEAF, KIND_IVY, 0, 2.0)
	b.blob(Vector3(0.2, height * 0.16, 0.0), Vector3(0.85, 0.5, 0.8), 7, 3, LEAF_D, LEAF_L, KIND_IVY, 0, 6.0)
	for k: int in 5:
		var a := k * TAU / 5.0
		b.flower(Vector3(0.45 + cos(a) * 0.45, height * 0.86 + sin(a * 2.0) * 0.12, 0.15 + sin(a) * 0.4),
			Vector3(cos(a) * 0.5, 1.0, sin(a) * 0.5), 0.26, ROSE if k % 2 == 0 else ROSE_W, 0, a)
	return b.to_mesh()
