class_name NatureKit
extends RefCounted
## Shared kit of the Nature buildings' epic pass (task A2.6): Grove Hall, Seed Hollow, Bramble Spire speak the
## Heartwood's language (art/buildings/nature_keep_build.gd + nature_keep/*.gdshader, reused read-only).
## - `MB`: multi-surface mesh builder, a runtime port of the Heartwood builder: UVs in METRES for the painted
##   patterns (masonry, bark with sap, planks, foliage), UV2 = (card id, sway phase) for the leaf cards and the
##   banner phase, vertex colour r = baked occlusion (the dark gaps between canopy clumps). Meshes are baked once
##   per key (`mesh()`) and shared by every instance; materials stay per instance (surface overrides).
## - `Blob` / `blob_mesh` / `clump_cards`: lumpy foliage clumps with baked gaps, fringed with leaf and blossom cards.
## - `make_materials()`: one set of the keep's materials per building (team colour, selection rim, damage per
##   instance), and helpers that drive them like nature_keep.gd does (team colour, rim, boost, health).
## - Ground patch material (nature_ground.gdshader), particle quads (soft dot, leaf, petal), camera distance.

const PAINTED: Shader = preload("res://art/buildings/nature_keep/nature_keep_painted.gdshader")
const LEAF: Shader = preload("res://art/buildings/nature_keep/nature_keep_leaf.gdshader")
const BANNER: Shader = preload("res://art/buildings/nature_keep/nature_keep_banner.gdshader")
const SEED: Shader = preload("res://art/buildings/nature_keep/nature_keep_seed.gdshader")
const RUNE: Shader = preload("res://art/shaders/rune_glow.gdshader")
const GROUND: Shader = preload("res://art/buildings/nature/nature_ground.gdshader")
const NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
const TEAM := Color(0.35, 0.70, 0.25)
const GLOW := Color(0.75, 1.00, 0.40)
const STRIPE := Color(0.15, 0.40, 0.15)
const RIM_IDLE := Color(0.72, 0.88, 0.55)
const RIM_IDLE_STRENGTH := 0.25
const MOSS := Color(0.22, 0.31, 0.11)
const COS15 := 0.9659258
## Painted (pattern shader) materials: take `damage`, `rim_color`, `rim_strength`.
const PAINTED_KEYS: Array[String] = ["Stone", "Dark", "Bark", "Wood", "Moss", "Leaves", "Thorn"]
## Cut-out card materials (leaf shader): same three uniforms.
const CARD_KEYS: Array[String] = ["LeafCard", "Blossom", "Petal"]
## Glowing materials that take `boost` (selection 1.4, training pulse, collapse overload).
const GLOW_KEYS: Array[String] = ["Heart", "Gate", "Blossom", "Petal", "Cap"]
## Multiplier on additive motes (pollen): keeps them under the bloom threshold, so they read as specks, not balls.
const MOTE_DIM := Color(0.55, 0.55, 0.55, 1.0)

## Baked meshes (art/buildings/nature/nature_bake.gd writes them; the game only loads them). A mesh without a baked
## file is built at runtime (GDScript, ~10-90 ms per building type, once).
const BAKED_DIR := "res://art/buildings/nature/baked/"
const NVC := preload("res://art/buildings/nature/nature_vc.gd")

static var _cache: Dictionary = {}
static var _builders: Dictionary = {}
static var _quads: Dictionary = {}
## The bake script sets it: ignore the baked files and build every mesh from code.
static var force_build: bool = false


# ============================================================ mesh builder

## One surface's triangles.
class Surf:
	var v: PackedVector3Array = PackedVector3Array()
	var n: PackedVector3Array = PackedVector3Array()
	var uv: PackedVector2Array = PackedVector2Array()
	var uv2: PackedVector2Array = PackedVector2Array()
	var c: PackedColorArray = PackedColorArray()


## Multi-surface mesh builder (the Heartwood's MB). `tri` is flat shaded and faces away from an `inside` point;
## `tri_s` takes smooth normals and faces along them. `xf` transforms everything added. `col` = vertex colour
## (r = baked occlusion, 1 = open).
class MB:
	var order: Array[String] = []
	var surfs: Dictionary = {}
	var xf: Transform3D = Transform3D.IDENTITY
	var flip: bool = false
	var col: Color = Color.WHITE

	func _s(k: String) -> Surf:
		if not surfs.has(k):
			surfs[k] = Surf.new()
			order.append(k)
		return surfs[k]

	func tri(k: String, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2,
			inside: Vector3, u2: Vector2 = Vector2.ZERO) -> void:
		a = xf * a
		b = xf * b
		c = xf * c
		inside = xf * inside
		var nn: Vector3 = (b - a).cross(c - a)
		if nn.length_squared() < 1e-12:
			return
		nn = nn.normalized()
		if (nn.dot((a + b + c) / 3.0 - inside) < 0.0) != flip:
			var t: Vector3 = b
			b = c
			c = t
			var tu: Vector2 = ub
			ub = uc
			uc = tu
			nn = -nn
		var s: Surf = _s(k)
		# Godot's front faces are clockwise: emit a, c, b.
		s.v.append(a)
		s.v.append(c)
		s.v.append(b)
		for i: int in 3:
			s.n.append(nn)
			s.uv2.append(u2)
			s.c.append(col)
		s.uv.append(ua)
		s.uv.append(uc)
		s.uv.append(ub)

	func tri_s(k: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
			ua: Vector2, ub: Vector2, uc: Vector2, u2: Vector2 = Vector2.ZERO) -> void:
		tri_sc(k, a, b, c, na, nb, nc, ua, ub, uc, u2, col, col, col)

	func tri_sc(k: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
			ua: Vector2, ub: Vector2, uc: Vector2, u2: Vector2, ca: Color, cb: Color, cc: Color) -> void:
		a = xf * a
		b = xf * b
		c = xf * c
		na = (xf.basis * na).normalized()
		nb = (xf.basis * nb).normalized()
		nc = (xf.basis * nc).normalized()
		var g: Vector3 = (b - a).cross(c - a)
		if g.length_squared() < 1e-14:
			return
		if g.dot(na + nb + nc) < 0.0:
			var t: Vector3 = b
			b = c
			c = t
			var tn: Vector3 = nb
			nb = nc
			nc = tn
			var tu: Vector2 = ub
			ub = uc
			uc = tu
			var tc: Color = cb
			cb = cc
			cc = tc
		var s: Surf = _s(k)
		s.v.append(a)
		s.v.append(c)
		s.v.append(b)
		s.n.append(na)
		s.n.append(nc)
		s.n.append(nb)
		s.uv.append(ua)
		s.uv.append(uc)
		s.uv.append(ub)
		for i: int in 3:
			s.uv2.append(u2)
		s.c.append(ca)
		s.c.append(cc)
		s.c.append(cb)

	func quad(k: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2,
			uc: Vector2, ud: Vector2, inside: Vector3, u2: Vector2 = Vector2.ZERO) -> void:
		tri(k, a, b, c, ua, ub, uc, inside, u2)
		tri(k, a, c, d, ua, uc, ud, inside, u2)

	## Planar UVs in metres from the face's dominant axis.
	static func puv(p: Vector3, nn: Vector3) -> Vector2:
		var an: Vector3 = nn.abs()
		if an.y >= an.x and an.y >= an.z:
			return Vector2(p.x, p.z)
		if an.x >= an.z:
			return Vector2(p.z, p.y)
		return Vector2(p.x, p.y)

	func tri_auto(k: String, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
		var nn: Vector3 = (b - a).cross(c - a)
		tri(k, a, b, c, puv(a, nn), puv(b, nn), puv(c, nn), inside)

	func quad_auto(k: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
		tri_auto(k, a, b, c, inside)
		tri_auto(k, a, c, d, inside)

	## Side walls between polygon rings (Array of Vector2 x/z around +y) at heights ys; u runs along the ring in
	## metres, v = y. Caps are fans with planar UVs. `center` = the rings' axis (for facing).
	func loft(k: String, rings: Array, ys: Array, cap_top: bool = true, cap_bottom: bool = false,
			center: Vector2 = Vector2.ZERO) -> void:
		var cnt: int = (rings[0] as Array).size()
		for L: int in rings.size() - 1:
			var r0: Array = rings[L]
			var r1: Array = rings[L + 1]
			var y0: float = ys[L]
			var y1: float = ys[L + 1]
			var inside := Vector3(center.x, (y0 + y1) * 0.5, center.y)
			var u: float = 0.0
			for i: int in cnt:
				var j: int = (i + 1) % cnt
				var p0: Vector2 = r0[i]
				var p1: Vector2 = r0[j]
				var q1: Vector2 = r1[j]
				var q0: Vector2 = r1[i]
				var a := Vector3(p0.x, y0, p0.y)
				var b := Vector3(p1.x, y0, p1.y)
				var c := Vector3(q1.x, y1, q1.y)
				var d := Vector3(q0.x, y1, q0.y)
				var seg: float = a.distance_to(b)
				var top: float = q0.distance_to(q1)
				var um: float = u + seg * 0.5
				quad(k, a, b, c, d, Vector2(u, y0), Vector2(u + seg, y0), Vector2(um + top * 0.5, y1),
					Vector2(um - top * 0.5, y1), inside)
				u += seg
		if cap_top:
			cap(k, rings[rings.size() - 1], ys[ys.size() - 1], -1.0)
		if cap_bottom:
			cap(k, rings[0], ys[0], 1.0)

	func cap(k: String, ring: Array, y: float, inside_dy: float) -> void:
		var cnt: int = ring.size()
		var c := Vector2.ZERO
		for p: Vector2 in ring:
			c += p
		c /= float(cnt)
		var cc := Vector3(c.x, y, c.y)
		for i: int in cnt:
			var p0: Vector2 = ring[i]
			var p1: Vector2 = ring[(i + 1) % cnt]
			tri(k, cc, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), c, p0, p1, cc + Vector3(0, inside_dy, 0))

	## Flat ring between two polygons at height y, facing up.
	func annulus(k: String, outer: Array, inner: Array, y: float) -> void:
		var cnt: int = outer.size()
		for i: int in cnt:
			var j: int = (i + 1) % cnt
			var o0: Vector2 = outer[i]
			var o1: Vector2 = outer[j]
			var i0: Vector2 = inner[i]
			var i1: Vector2 = inner[j]
			quad(k, Vector3(o0.x, y, o0.y), Vector3(o1.x, y, o1.y), Vector3(i1.x, y, i1.y), Vector3(i0.x, y, i0.y),
				o0, o1, i1, i0, Vector3((o0.x + i0.x) * 0.5, y - 1.0, (o0.y + i0.y) * 0.5))

	## Box (centre, size) turned by `basis`.
	func box(k: String, center: Vector3, size: Vector3, basis: Basis = Basis.IDENTITY) -> void:
		var h: Vector3 = size * 0.5
		var p: Array[Vector3] = []
		for i: int in 8:
			var l := Vector3(h.x if (i & 1) != 0 else -h.x, h.y if (i & 2) != 0 else -h.y, h.z if (i & 4) != 0 else -h.z)
			p.append(center + basis * l)
		hexa(k, p)

	## Any convex 8-corner block, corners indexed by bits (x = 1, y = 2, z = 4) like box().
	func hexa(k: String, p: Array[Vector3]) -> void:
		var ctr := Vector3.ZERO
		for q: Vector3 in p:
			ctr += q
		ctr /= 8.0
		for f: Array in [[0, 2, 6, 4], [1, 3, 7, 5], [0, 1, 5, 4], [2, 3, 7, 6], [0, 1, 3, 2], [4, 5, 7, 6]]:
			quad_auto(k, p[f[0]], p[f[1]], p[f[2]], p[f[3]], ctr)

	## Flat convex polygon (fan from its centroid), facing away from `inside`.
	func poly(k: String, pts: Array[Vector3], inside: Vector3) -> void:
		var c := Vector3.ZERO
		for p: Vector3 in pts:
			c += p
		c /= float(pts.size())
		for i: int in pts.size():
			tri_auto(k, c, pts[i], pts[(i + 1) % pts.size()], inside)

	## A 4-sided pointed cone (thorn, spike, stone tooth) from `base` along `dir`, base half-width r.
	func spike(k: String, base: Vector3, dir: Vector3, length: float, r: float, twist: float = 0.0) -> void:
		var d: Vector3 = dir.normalized()
		var ref := Vector3.UP if absf(d.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var s1: Vector3 = d.cross(ref).normalized().rotated(d, twist)
		var s2: Vector3 = d.cross(s1).normalized()
		var tip: Vector3 = base + d * length
		var ring: Array[Vector3] = [base + s1 * r, base + s2 * r, base - s1 * r, base - s2 * r]
		for i: int in 4:
			tri_auto(k, ring[i], ring[(i + 1) % 4], tip, base + d * length * 0.25)

	## Smooth tapered tube along a path (parallel-transport frames). UV: u = tiles around (whole numbers tile the
	## bark seamlessly), v = metres along the path. `gnarl` bulges the rings (knotty bark); caps are flat fans.
	func tube(k: String, pts: Array[Vector3], radii: Array[float], sides: int, tiles_u: float = 1.0,
			gnarl: float = 0.0, seed: float = 0.0, cap_start: bool = false, cap_end: bool = true) -> void:
		var n: int = pts.size()
		var rings: Array = []
		var norms: Array = []
		var prev := Vector3.ZERO
		for i: int in n:
			var tan: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
			var nn: Vector3
			if i == 0:
				var ref := Vector3.UP if absf(tan.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
				nn = (ref - tan * ref.dot(tan)).normalized()
			else:
				nn = (prev - tan * prev.dot(tan)).normalized()
			prev = nn
			var bn: Vector3 = tan.cross(nn)
			var ring: Array = []
			var nr: Array = []
			for j: int in sides + 1:
				var a: float = TAU * float(j) / float(sides)
				var d: Vector3 = nn * cos(a) + bn * sin(a)
				var g: float = 1.0 + gnarl * (0.6 * sin(a * 3.0 + seed + float(i) * 0.7) + 0.4 * sin(a * 5.0 - seed * 1.3 + float(i) * 1.1))
				ring.append(pts[i] + d * radii[i] * g)
				nr.append(d)
			rings.append(ring)
			norms.append(nr)
		var vacc: float = 0.0
		for i: int in n - 1:
			var seg: float = pts[i].distance_to(pts[i + 1])
			var ra: Array = rings[i]
			var rb: Array = rings[i + 1]
			var na: Array = norms[i]
			var nb: Array = norms[i + 1]
			for j: int in sides:
				var u0: float = float(j) / float(sides) * tiles_u
				var u1: float = float(j + 1) / float(sides) * tiles_u
				tri_s(k, ra[j], ra[j + 1], rb[j + 1], na[j], na[j + 1], nb[j + 1],
					Vector2(u0, vacc), Vector2(u1, vacc), Vector2(u1, vacc + seg))
				tri_s(k, ra[j], rb[j + 1], rb[j], na[j], nb[j + 1], nb[j],
					Vector2(u0, vacc), Vector2(u1, vacc + seg), Vector2(u0, vacc + seg))
			vacc += seg
		for e: int in 2:
			if (e == 0 and not cap_start) or (e == 1 and not cap_end):
				continue
			var idx: int = 0 if e == 0 else n - 1
			if radii[idx] < 0.005:
				continue
			var ring: Array = rings[idx]
			var cn: Vector3 = (pts[0] - pts[1]).normalized() if e == 0 else (pts[n - 1] - pts[n - 2]).normalized()
			for j: int in sides:
				tri_s(k, pts[idx], ring[j], ring[j + 1], cn, cn, cn, Vector2(0.5, 0.5),
					Vector2(0.5 + 0.5 * cos(TAU * j / sides), 0.5), Vector2(0.5 + 0.5 * cos(TAU * (j + 1) / sides), 0.5))

	## Smooth surface of revolution around +y through `centre`: `prof` = Array of Vector2(radius, y) from bottom
	## to top. UV u = tiles around, v = metres along the profile (bark furrows run up the husk).
	func lathe(k: String, centre: Vector3, prof: Array[Vector2], sides: int, tiles_u: float = 1.0,
			gnarl: float = 0.0, seed: float = 0.0) -> void:
		var n: int = prof.size()
		var vs: Array[float] = [0.0]
		for i: int in range(1, n):
			vs.append(vs[i - 1] + prof[i - 1].distance_to(prof[i]))
		for i: int in n - 1:
			var p0: Vector2 = prof[i]
			var p1: Vector2 = prof[i + 1]
			var t0: Vector2 = (prof[mini(i + 1, n - 1)] - prof[maxi(i - 1, 0)]).normalized()
			var t1: Vector2 = (prof[mini(i + 2, n - 1)] - prof[i]).normalized()
			for j: int in sides:
				var a0: float = TAU * float(j) / float(sides)
				var a1: float = TAU * float(j + 1) / float(sides)
				var g00: float = 1.0 + gnarl * sin(a0 * 3.0 + seed + float(i) * 0.9)
				var g01: float = 1.0 + gnarl * sin(a1 * 3.0 + seed + float(i) * 0.9)
				var g10: float = 1.0 + gnarl * sin(a0 * 3.0 + seed + float(i + 1) * 0.9)
				var g11: float = 1.0 + gnarl * sin(a1 * 3.0 + seed + float(i + 1) * 0.9)
				var d0 := Vector3(cos(a0), 0.0, sin(a0))
				var d1 := Vector3(cos(a1), 0.0, sin(a1))
				var a: Vector3 = centre + d0 * p0.x * g00 + Vector3(0, p0.y, 0)
				var b: Vector3 = centre + d1 * p0.x * g01 + Vector3(0, p0.y, 0)
				var c: Vector3 = centre + d1 * p1.x * g11 + Vector3(0, p1.y, 0)
				var d: Vector3 = centre + d0 * p1.x * g10 + Vector3(0, p1.y, 0)
				var na: Vector3 = (d0 * t0.y - Vector3(0, t0.x, 0)).normalized()
				var nb: Vector3 = (d1 * t0.y - Vector3(0, t0.x, 0)).normalized()
				var nc: Vector3 = (d1 * t1.y - Vector3(0, t1.x, 0)).normalized()
				var nd: Vector3 = (d0 * t1.y - Vector3(0, t1.x, 0)).normalized()
				var u0: float = float(j) / float(sides) * tiles_u
				var u1: float = float(j + 1) / float(sides) * tiles_u
				tri_s(k, a, b, c, na, nb, nc, Vector2(u0, vs[i]), Vector2(u1, vs[i]), Vector2(u1, vs[i + 1]))
				tri_s(k, a, c, d, na, nc, nd, Vector2(u0, vs[i]), Vector2(u1, vs[i + 1]), Vector2(u0, vs[i + 1]))

	## Cut-out card strip along a path (leaf, petal): width `w` across `side`, one soft normal per point,
	## UV x 0..1 across, y 0..1 along; UV2 = (id, phase) for the leaf shader.
	func strip(k: String, pts: Array[Vector3], side: Vector3, w: float, nrms: Array[Vector3], id: float,
			phase: float) -> void:
		var n: int = pts.size()
		var hw: Vector3 = side.normalized() * w * 0.5
		var u2 := Vector2(id, phase)
		for i: int in n - 1:
			var v0: float = float(i) / float(n - 1)
			var v1: float = float(i + 1) / float(n - 1)
			var a: Vector3 = pts[i] - hw
			var b: Vector3 = pts[i] + hw
			var c: Vector3 = pts[i + 1] + hw
			var d: Vector3 = pts[i + 1] - hw
			tri_s(k, a, b, c, nrms[i], nrms[i], nrms[i + 1], Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), u2)
			tri_s(k, a, c, d, nrms[i], nrms[i + 1], nrms[i + 1], Vector2(0, v0), Vector2(1, v1), Vector2(0, v1), u2)

	## Low-poly UV sphere of material k at c (vertical squash sy).
	func sphere(k: String, c: Vector3, r: float, sy: float = 1.0, seg: int = 12, rings: int = 7) -> void:
		var prev: Array = []
		for i: int in rings + 1:
			var th: float = PI * float(i) / float(rings)
			var row: Array = []
			for j: int in seg + 1:
				var ph: float = TAU * float(j) / float(seg)
				row.append(Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)))
			if i > 0:
				var sc := Vector3(r, r * sy, r)
				for j: int in seg:
					var a: Vector3 = prev[j]
					var b: Vector3 = prev[j + 1]
					var cc: Vector3 = row[j + 1]
					var d: Vector3 = row[j]
					tri_s(k, c + a * sc, c + b * sc, c + cc * sc, a, b, cc, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
					tri_s(k, c + a * sc, c + cc * sc, c + d * sc, a, cc, d, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
			prev = row

	## A leaf-shaped banner (nature_keep_banner.gdshader): top edge centred at `top_center`, cloth facing `out`,
	## UV 0..1 per banner (y = 0 at the fixed top), UV2.x = its wave phase.
	func banner(top_center: Vector3, out: Vector3, w: float, h: float, phase: float, k: String = "Banner") -> void:
		var tng := Vector3(out.z, 0, -out.x).normalized()
		var nx: int = 3
		var ny: int = 10
		for i: int in nx:
			for j: int in ny:
				var u0: float = float(i) / nx
				var u1: float = float(i + 1) / nx
				var v0: float = float(j) / ny
				var v1: float = float(j + 1) / ny
				quad(k, _bp(top_center, tng, w, h, u0, v0), _bp(top_center, tng, w, h, u1, v0),
					_bp(top_center, tng, w, h, u1, v1), _bp(top_center, tng, w, h, u0, v1),
					Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1),
					top_center - out * 1.0 - Vector3(0, h * 0.5, 0), Vector2(phase, 0))

	func _bp(top_center: Vector3, tng: Vector3, w: float, h: float, u: float, v: float) -> Vector3:
		return top_center + tng * (u - 0.5) * w - Vector3(0, v * h, 0)

	## The mesh: one surface per material key (in first-use order), indexed. Returns [ArrayMesh, Array[String]].
	func commit() -> Array:
		var mesh := ArrayMesh.new()
		var used: Array[String] = []
		for k: String in order:
			var s: Surf = surfs[k]
			if s.v.is_empty():
				continue
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = s.v
			arrays[Mesh.ARRAY_NORMAL] = s.n
			arrays[Mesh.ARRAY_TEX_UV] = s.uv
			arrays[Mesh.ARRAY_TEX_UV2] = s.uv2
			arrays[Mesh.ARRAY_COLOR] = s.c
			var st := SurfaceTool.new()
			st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
			st.index()
			st.commit(mesh)
			mesh.surface_set_name(mesh.get_surface_count() - 1, k)   # the material key (kept in the baked file)
			used.append(k)
		return [mesh, used]


# ============================================================ foliage clumps

## Lumpy foliage clump: an icosphere pushed out by gaussian bumps, scaled per axis, flatter underneath.
class Blob:
	var c: Vector3
	var r: float = 1.0
	var scale: Vector3 = Vector3.ONE
	var sq_top: float = 0.75
	var sq_bot: float = 0.58
	var bump_dirs: Array[Vector3] = []
	var bump_amp: Array[float] = []
	var bump_sharp: Array[float] = []

	func radius_at(d: Vector3) -> float:
		var k: float = 0.9
		for i: int in bump_dirs.size():
			k += bump_amp[i] * exp(-(1.0 - d.dot(bump_dirs[i])) * bump_sharp[i])
		return r * k

	func point(d: Vector3) -> Vector3:
		var p: Vector3 = d * radius_at(d)
		p.y *= sq_top if p.y > 0.0 else sq_bot
		return c + p * scale

	## Normalised distance of p from this clump's surface (1 = on it).
	func k_of(p: Vector3) -> float:
		var d: Vector3 = (p - c) / scale
		d.y /= sq_top if d.y > 0.0 else sq_bot
		return d.length() / (r * 0.95)


## A clump with `bumps` random lumps (biased `outward`); rng-driven, so deterministic per seed.
static func make_blob(rng: RandomNumberGenerator, c: Vector3, r: float, scale: Vector3, squash: float,
		outward: Vector3 = Vector3.ZERO, bumps: int = 11, calm_top: bool = false) -> Blob:
	var b := Blob.new()
	b.c = c
	b.r = r
	b.scale = scale
	b.sq_top = squash
	b.sq_bot = squash * 0.78
	for k: int in bumps:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1.0), rng.randf_range(-1, 1)).normalized()
		if calm_top:
			d = Vector3(d.x, clampf(d.y, -0.2, 0.55), d.z).normalized()
		d = (d + outward * 0.35).normalized()
		b.bump_dirs.append(d)
		b.bump_amp.append(rng.randf_range(0.07, 0.15))
		b.bump_sharp.append(rng.randf_range(5.0, 10.0))
	return b


## Foliage clump surface (icosphere subdivided `sub` times, painterly softened normals, baked occlusion from
## `others` into the vertex colour: the dark gaps where clumps meet).
static func blob_mesh(mb: MB, b: Blob, sub: int, id: float, others: Array = [], k: String = "Leaves") -> void:
	var t: float = (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = []
	for v: Vector3 in [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
		verts.append(v.normalized())
	var faces: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4],
		[11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5],
		[2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for s: int in sub:
		var cache: Dictionary = {}
		var nf: Array = []
		for f: Array in faces:
			var m: Array[int] = []
			for e: int in 3:
				var a: int = f[e]
				var bb: int = f[(e + 1) % 3]
				var key: int = mini(a, bb) * 100000 + maxi(a, bb)
				if not cache.has(key):
					verts.append((verts[a] + verts[bb]).normalized())
					cache[key] = verts.size() - 1
				m.append(cache[key])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		faces = nf
	var pos: Array[Vector3] = []
	for d: Vector3 in verts:
		pos.append(b.point(d))
	var nrm: Array[Vector3] = []
	nrm.resize(verts.size())
	for i: int in nrm.size():
		nrm[i] = Vector3.ZERO
	for f: Array in faces:
		var fn: Vector3 = (pos[f[1]] - pos[f[0]]).cross(pos[f[2]] - pos[f[0]])
		if fn.dot(pos[f[0]] - b.c) < 0.0:
			fn = -fn
		for e: int in 3:
			nrm[f[e]] += fn
	for i: int in nrm.size():
		var radial: Vector3 = (pos[i] - b.c).normalized()
		nrm[i] = (nrm[i].normalized() * 0.55 + radial * 0.45).normalized()
	var aoc: Array[Color] = []
	for i: int in pos.size():
		var ao: float = canopy_ao(pos[i], b, others)
		aoc.append(Color(ao, ao, ao, 1.0))
	var u2 := Vector2(id, 0)
	for f: Array in faces:
		mb.tri_sc(k, pos[f[0]], pos[f[1]], pos[f[2]], nrm[f[0]], nrm[f[1]], nrm[f[2]],
			Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, u2, aoc[f[0]], aoc[f[1]], aoc[f[2]])


## Baked occlusion of point p by the other clumps (dark crevices where clumps meet), 0.3 .. 1.
static func canopy_ao(p: Vector3, self_b: Blob, others: Array) -> float:
	var ao: float = 1.0
	for o: Blob in others:
		if o == self_b:
			continue
		ao *= 1.0 - 0.62 * (1.0 - smoothstep(0.92, 1.6, o.k_of(p)))
	return clampf(ao, 0.3, 1.0)


## Leaf cards around a clump (hanging along its lower rim and sides, some sticking up on top) and blossoms on top.
## `min_y` / `max_y` limit where on the clump (-1 bottom .. 1 top) the hanging leaves grow.
static func clump_cards(mb: MB, b: Blob, rng: RandomNumberGenerator, n_leaves: int, n_blossoms: int,
		others: Array = [], leaf_size: float = 0.85, min_y: float = -0.6, max_y: float = 0.25) -> void:
	for i: int in n_leaves:
		var up_bias: bool = i % 5 == 0
		var y: float = rng.randf_range(0.35, 0.8) if up_bias else rng.randf_range(min_y, max_y)
		var a: float = rng.randf() * TAU
		var d := Vector3(cos(a) * sqrt(1.0 - y * y), y, sin(a) * sqrt(1.0 - y * y))
		var p: Vector3 = b.point(d)
		var outward: Vector3 = (p - b.c).normalized()
		var horiz := Vector3(outward.x, 0, outward.z)
		horiz = horiz.normalized() if horiz.length() > 0.01 else Vector3.RIGHT
		var side: Vector3 = Vector3.UP.cross(horiz).normalized()
		var s: float = rng.randf_range(0.8, 1.15)
		var dir: Vector3
		if up_bias:
			dir = (outward + Vector3.UP * 0.5).normalized()
		else:
			dir = (horiz * 0.75 + Vector3.DOWN * rng.randf_range(0.4, 0.9)).normalized()
		side = side.rotated(dir, rng.randf_range(-0.5, 0.5))
		var h: float = leaf_size * s
		var bend: Vector3 = (dir + Vector3.DOWN * 0.45).normalized()
		var start: Vector3 = p - outward * 0.12
		var pts: Array[Vector3] = [start, start + dir * h * 0.5, start + dir * h * 0.5 + bend * h * 0.5]
		var nn: Vector3 = (outward + Vector3.UP * 0.35).normalized()
		var ao: float = canopy_ao(p, b, others)
		mb.col = Color(ao, ao, ao, 1.0)
		mb.strip("LeafCard", pts, side, 0.59 * h, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())
	for i: int in n_blossoms:
		var y: float = rng.randf_range(0.35, 0.95)
		var a: float = rng.randf() * TAU
		var d := Vector3(cos(a) * sqrt(1.0 - y * y), y, sin(a) * sqrt(1.0 - y * y))
		var p: Vector3 = b.point(d)
		var outward: Vector3 = (p - b.c).normalized()
		var t1: Vector3 = outward.cross(Vector3.RIGHT if absf(outward.x) < 0.9 else Vector3.FORWARD).normalized()
		var s: float = rng.randf_range(0.5, 0.7)
		var start: Vector3 = p + outward * 0.06 - t1 * s * 0.5
		var nn: Vector3 = (outward + Vector3.UP * 0.5).normalized()
		var ao: float = canopy_ao(p, b, others)
		mb.col = Color(ao, ao, ao, 1.0)
		mb.strip("Blossom", [start, start + t1 * s] as Array[Vector3], outward.cross(t1), s,
			[nn, nn] as Array[Vector3], rng.randf(), rng.randf())
	mb.col = Color.WHITE


## A flower: `count` outer petal cards in a cup (+ an inner ring), a glowing seed heart and stamens, at `c`
## (local +y = the flower's axis via `basis`). The Heartwood's Crown Bloom in small.
static func flower(mb: MB, c: Vector3, basis: Basis, size: float, count: int, rng: RandomNumberGenerator,
		stamens: int = 5, collar: bool = true) -> void:
	var saved: Transform3D = mb.xf
	mb.xf = saved * Transform3D(basis.scaled_local(Vector3.ONE * size), c)
	if collar:
		for i: int in count - 1:
			var a: float = TAU * float(i) / float(count - 1) + 0.3
			var d := Vector3(cos(a), 0, sin(a))
			mb.strip("LeafCard", [d * 0.3 + Vector3(0, 0.02, 0), d * 1.0 + Vector3(0, 0.08, 0), d * 1.6 + Vector3(0, -0.14, 0)] as Array[Vector3],
				Vector3(-d.z, 0, d.x), 0.8, [Vector3.UP, Vector3.UP, Vector3.UP] as Array[Vector3], rng.randf(), rng.randf())
	for ring: int in 2:
		var n: int = count if ring == 0 else maxi(count - 2, 4)
		var length: float = 1.9 if ring == 0 else 1.2
		var width: float = 1.05 if ring == 0 else 0.7
		var lift: float = 0.55 if ring == 0 else 1.0
		for i: int in n:
			var a: float = TAU * (float(i) + 0.5 * float(ring)) / float(n) + 0.2
			var d := Vector3(cos(a), 0, sin(a))
			var pts: Array[Vector3] = []
			var nrms: Array[Vector3] = []
			for s: int in 5:
				var t: float = float(s) / 4.0
				var out: float = length * (0.18 + t * 0.82) * (1.0 - 0.15 * t * t) * (1.0 if ring == 0 else 0.7)
				var up: float = length * (lift * t - 0.25 * t * t * (1.0 if ring == 0 else 0.3))
				pts.append(d * out + Vector3(0, up + 0.05 * float(ring), 0))
				nrms.append((Vector3.UP * 0.8 - d * 0.35 + d * t * 0.6).normalized())
			mb.strip("Petal", pts, Vector3(-d.z, 0, d.x), width, nrms, float(i + ring * 7) / 14.0, rng.randf())
	mb.sphere("Heart", Vector3(0, 0.42, 0), 0.44, 1.1, 10, 6)
	for i: int in stamens:
		var a: float = TAU * float(i) / float(stamens) + 0.3
		var d := Vector3(cos(a), 0, sin(a))
		var tip: Vector3 = d * 0.52 + Vector3(0, 1.1, 0)
		mb.tube("Heart", [d * 0.22 + Vector3(0, 0.45, 0), d * 0.34 + Vector3(0, 0.85, 0), tip] as Array[Vector3],
			[0.04, 0.035, 0.03] as Array[float], 4, 1.0)
		mb.sphere("Heart", tip + Vector3(0, 0.05, 0), 0.1, 1.0, 6, 4)
	mb.xf = saved


## A seed-lantern (the Heartwood's): a vine from the pivot (origin) down `drop` metres, a bark calyx with five
## sepals, a glowing teardrop pod (material "Heart").
static func lantern(mb: MB, drop: float, sway: Vector3, scale: float = 1.0) -> void:
	mb.tube("Bark", [Vector3.ZERO, sway - Vector3(0, drop * 0.5, 0), Vector3(0, -drop, 0)] as Array[Vector3],
		[0.05, 0.045, 0.04] as Array[float], 5, 1.0)
	var top := Vector3(0, -drop, 0)
	mb.loft("Bark", [ring_n(7, 0.07 * scale, 0.0, Vector2(top.x, top.z)), ring_n(7, 0.26 * scale, 0.0, Vector2(top.x, top.z))],
		[top.y + 0.05, top.y - 0.12 * scale], false, false, Vector2(top.x, top.z))
	for k: int in 5:
		var a: float = TAU * float(k) / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		var s := Vector3(-d.z, 0, d.x)
		var b0: Vector3 = top + (d * 0.22 + Vector3(0, -0.1, 0)) * scale
		mb.tri_auto("Bark", b0 - s * 0.1 * scale, b0 + s * 0.1 * scale, b0 + (d * 0.1 + Vector3(0, -0.3, 0)) * scale,
			top + Vector3(0, -0.45, 0) * scale)
	var prof: Array[Vector2] = []
	for pp: Vector2 in [Vector2(0.02, -0.02), Vector2(0.21, -0.12), Vector2(0.34, -0.3), Vector2(0.37, -0.5),
			Vector2(0.31, -0.7), Vector2(0.16, -0.86), Vector2(0.02, -0.95)]:
		prof.append(Vector2(pp.x * scale, top.y + pp.y * scale))
	prof.reverse()   # the lathe runs bottom -> top (outward normals)
	mb.lathe("Heart", Vector3.ZERO, prof, 10, 1.0)


## A banner standard (the Heartwood's gate poles): gnarled wooden pole from `b` up `h`, a crossbar facing `face`,
## two curled fronds and a glowing bud on top. Returns the crossbar centre (hang the banner under it).
static func standard(mb: MB, b: Vector3, h: float, face: Vector3, seed: float, bar: float = 1.1) -> Vector3:
	var sgn: float = 1.0 if seed >= 0.0 else -1.0
	var pts: Array[Vector3] = [b, b + Vector3(0.04 * sgn, h * 0.3, 0.02), b + Vector3(-0.03 * sgn, h * 0.6, -0.02),
		b + Vector3(0.03 * sgn, h * 0.85, 0.02), b + Vector3(0.0, h, 0.0)]
	mb.tube("Wood", pts, [0.12, 0.11, 0.1, 0.085, 0.06] as Array[float], 7, 1.0, 0.1, seed, false, true)
	var bar_dir := Vector3(-face.z, 0, face.x).normalized()
	var bar_c: Vector3 = b + Vector3(0, h - 0.5, 0) + face * 0.1
	mb.box("Wood", bar_c, Vector3(bar, 0.09, 0.09), Basis(bar_dir, Vector3.UP, face.normalized()))
	for sd: float in [-1.0, 1.0]:
		var c0: Vector3 = b + Vector3(0, h - 0.12, 0)
		var o: Vector3 = bar_dir * sd
		mb.tube("Wood", [c0, c0 + o * 0.24 + Vector3(0, 0.24, 0), c0 + o * 0.36 + Vector3(0, 0.54, 0),
			c0 + o * 0.24 + Vector3(0, 0.72, 0), c0 + o * 0.12 + Vector3(0, 0.62, 0)] as Array[Vector3],
			[0.06, 0.05, 0.045, 0.035, 0.025] as Array[float], 5, 1.0)
	var bud: Vector3 = b + Vector3(0, h + 0.05, 0)
	var eq: Array = ring_n(5, 0.14)
	for k: int in 5:
		var q0: Vector2 = eq[k]
		var q1: Vector2 = eq[(k + 1) % 5]
		var e0: Vector3 = bud + Vector3(q0.x, 0, q0.y)
		var e1: Vector3 = bud + Vector3(q1.x, 0, q1.y)
		mb.tri_auto("Gate", e0, e1, bud + Vector3(0, 0.3, 0), bud)
		mb.tri_auto("Gate", e1, e0, bud + Vector3(0, -0.14, 0), bud)
	return bar_c


## A tapered standing stone leaning `lean_deg` outward along `out`, with a glowing leaf rune on its outer face.
static func menhir(mb: MB, base: Vector3, out: Vector3, h: float, w: float, lean_deg: float, rune: bool = true) -> void:
	var across := Vector3(-out.z, 0, out.x)
	var top_c: Vector3 = base + Vector3(0, h, 0) + out * h * tan(deg_to_rad(lean_deg))
	var p: Array[Vector3] = []
	for bit: int in 8:
		var sx: float = 1.0 if (bit & 1) != 0 else -1.0
		var sz: float = 1.0 if (bit & 4) != 0 else -1.0
		var top: bool = (bit & 2) != 0
		var ww: float = w * (0.65 if top else 1.0)
		var dd: float = w * (0.48 if top else 0.75)
		p.append((top_c if top else base) + across * sx * ww + out * sz * dd)
	mb.hexa("Stone", p)
	var apex: Vector3 = top_c + Vector3(0, w * 0.9, 0) + across * 0.04
	var tp: Array[Vector3] = [p[2], p[3], p[7], p[6]]
	for k: int in 4:
		mb.tri_auto("Stone", tp[k], tp[(k + 1) % 4], apex, top_c - Vector3(0, 0.2, 0))
	if not rune:
		return
	var fb: Vector3 = base + out * w * 0.75
	var ft: Vector3 = top_c + out * w * 0.48
	var fup: Vector3 = (ft - fb).normalized()
	var fn: Vector3 = across.cross(fup).normalized()
	if fn.dot(out) < 0.0:
		fn = -fn
	var bs := Basis(across, fup, fn)
	var at := func(s: float, t: float) -> Vector3:
		return fb.lerp(ft, s) + across * t * lerpf(1.0, 0.65, s) + fn * 0.035
	mb.box("Gate", at.call(0.45, 0.0), Vector3(0.07, h * 0.5, 0.05), bs)
	for s: float in [0.34, 0.52]:
		for sd: float in [-1.0, 1.0]:
			mb.box("Gate", at.call(s + 0.04, sd * 0.1), Vector3(0.06, 0.24, 0.05), bs * Basis(Vector3.BACK, sd * deg_to_rad(-40.0)))
	mb.box("Gate", at.call(0.76, 0.0), Vector3(0.13, 0.13, 0.05), bs * Basis(Vector3.BACK, PI * 0.25))


## A root: from `a` (on the trunk / wall) arcing over `over` and down into the ground at `b` (y < 0), radius r0 -> r1.
static func root(mb: MB, a: Vector3, over: Vector3, b: Vector3, r0: float, r1: float, seed: float) -> void:
	var pts: Array[Vector3] = []
	var rad: Array[float] = []
	for i: int in 7:
		var t: float = float(i) / 6.0
		var p: Vector3 = a.lerp(over, t).lerp(over.lerp(b, t), t)   # quadratic bezier
		pts.append(p + Vector3(sin(t * 7.0 + seed) * 0.05, 0, cos(t * 5.0 + seed) * 0.05))
		rad.append(lerpf(r0, r1, t))
	mb.tube("Bark", pts, rad, 7, 2.0, 0.07, seed, false, false)


# ============================================================ shapes

## Regular polygon, circumradius r, points around +y starting at angle `rot` from +x, offset `off`.
static func ring_n(n: int, r: float, rot: float = 0.0, off: Vector2 = Vector2.ZERO) -> Array:
	var pts: Array = []
	for i: int in n:
		var a: float = rot + TAU * float(i) / float(n)
		pts.append(off + Vector2(r * cos(a), -r * sin(a)))
	return pts


## Square of half-size h with 45-degree chamfered corners (leg ch), centred on `off`.
static func chamfer(h: float, ch: float, off: Vector2 = Vector2.ZERO) -> Array:
	var e: float = h - ch
	var pts: Array = []
	for p: Vector2 in [Vector2(h, e), Vector2(h, -e), Vector2(e, -h), Vector2(-e, -h),
			Vector2(-h, -e), Vector2(-h, e), Vector2(-e, h), Vector2(e, h)]:
		pts.append(p + off)
	return pts


## Rectangle (half sizes hx, hz) with chamfered corners, centred on `off`.
static func rect_ch(hx: float, hz: float, ch: float, off: Vector2 = Vector2.ZERO) -> Array:
	var pts: Array = []
	for p: Vector2 in [Vector2(hx, hz - ch), Vector2(hx, -hz + ch), Vector2(hx - ch, -hz), Vector2(-hx + ch, -hz),
			Vector2(-hx, -hz + ch), Vector2(-hx, hz - ch), Vector2(-hx + ch, hz), Vector2(hx - ch, hz)]:
		pts.append(p + off)
	return pts


## Horizontal direction at `deg` degrees from -Z toward +X.
static func dir_deg(deg: float) -> Vector3:
	var a: float = deg_to_rad(deg)
	return Vector3(sin(a), 0.0, -cos(a))


# ============================================================ mesh cache and nodes

## The mesh for `key` ([ArrayMesh, material keys], shared by every instance): the baked file if there is one, else
## `build` (Callable taking an MB) fills a new one the first time.
static func mesh(key: String, build: Callable) -> Array:
	_builders[key] = build
	if _cache.has(key):
		return _cache[key]
	var res: Array = []
	var path: String = baked_path(key)
	if not force_build and ResourceLoader.exists(path):
		var m := load(path) as ArrayMesh
		if m:
			var keys: Array[String] = []
			for i: int in m.get_surface_count():
				keys.append(m.surface_get_name(i))
			res = [m, keys]
	if res.is_empty():
		res = build_fresh(build)
	_cache[key] = res
	return res


## Builds a mesh from code (never cached, never baked): the bake script and the staleness test use it.
static func build_fresh(build: Callable) -> Array:
	var mb := MB.new()
	build.call(mb)
	return mb.commit()


static func baked_path(key: String) -> String:
	return BAKED_DIR + key.replace("/", "__") + ".res"


## Every mesh key used so far (the bake script saves them all).
static func cached_keys() -> Array:
	return _cache.keys()


static func cached_mesh(key: String) -> ArrayMesh:
	return (_cache[key] as Array)[0] if _cache.has(key) else null


## The code that builds `key` (from the latest instance that asked for it).
static func builder_of(key: String) -> Callable:
	return _builders.get(key, Callable())


static func clear_cache() -> void:
	_cache.clear()


## A MeshInstance3D showing the mesh `key` with this building's materials (surface overrides).
static func node(nm: String, key: String, build: Callable, mats: Dictionary, parent: Node3D,
		shadow: bool = true) -> MeshInstance3D:
	var res: Array = mesh(key, build)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = res[0]
	var keys: Array[String] = res[1]
	var all_glow: bool = true
	for i: int in keys.size():
		mi.set_surface_override_material(i, mats[keys[i]])
		if not (keys[i] in ["Heart", "Gate", "Cap", "Black"]):
			all_glow = false
	if not shadow or all_glow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# ============================================================ materials

static func _painted(nm: String, color: Color, pattern: int, params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.resource_name = nm
	m.shader = PAINTED
	m.set_shader_parameter(&"base_color", color)
	m.set_shader_parameter(&"noise_tex", NOISE)
	m.set_shader_parameter(&"pattern", pattern)
	m.set_shader_parameter(&"rim_color", RIM_IDLE)
	m.set_shader_parameter(&"rim_strength", RIM_IDLE_STRENGTH)
	m.set_shader_parameter(&"sap_color", GLOW)
	for k: String in params:
		m.set_shader_parameter(StringName(k), params[k])
	return m


static func _shader(nm: String, shader: Shader, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.resource_name = nm
	m.shader = shader
	for k: String in params:
		m.set_shader_parameter(StringName(k), params[k])
	return m


## A fresh set of the Heartwood's materials for one building (keys: PAINTED_KEYS, CARD_KEYS, Heart, Gate,
## Banner, Black). Same settings as nature_keep_build.gd so the kingdom reads as one family.
static func make_materials() -> Dictionary:
	var m: Dictionary = {}
	m["Stone"] = _painted("Stone", Color(0.5, 0.47, 0.37), 1, {"block_size": Vector2(0.8, 0.4),
		"joint_width": 0.065, "block_tint": 0.2, "moss": 0.45, "moss_color": MOSS})
	m["Dark"] = _painted("DarkStone", Color(0.26, 0.24, 0.17), 1, {"block_size": Vector2(0.7, 0.36),
		"joint_width": 0.055, "block_tint": 0.24, "moss": 0.35, "moss_color": MOSS})
	m["Bark"] = _painted("Bark", Color(0.40, 0.28, 0.16), 2, {"sap": 1.0, "sap_energy": 1.35,
		"sap_speed": 0.25, "bark_scale": Vector2(1.0, 0.2), "moss": 0.35, "moss_color": MOSS, "spec_strength": 0.04})
	m["Wood"] = _painted("Wood", Color(0.56, 0.41, 0.24), 4, {"block_size": Vector2(1.2, 0.22),
		"joint_width": 0.035, "block_tint": 0.2})
	m["Moss"] = _painted("Moss", Color(0.2, 0.3, 0.1), 0, {"moss": 0.3, "moss_color": MOSS})
	m["Leaves"] = _painted("Leaves", TEAM, 3, {"noise_scale_a": 0.8, "leaf_scale": 1.6,
		"foliage_value": 0.62, "top_tint": Color(1.32, 1.22, 0.7)})
	m["Thorn"] = _painted("Thorn", Color(0.2, 0.14, 0.09), 0, {"spec_strength": 0.15})
	m["LeafCard"] = _shader("LeafCard", LEAF, {"shape": 0, "base_color": TEAM, "sway": 0.08,
		"glow_color": GLOW, "leaf_value": 0.68, "ao_low": 1.0, "ao_span": 6.0})
	m["Blossom"] = _shader("Blossom", LEAF, {"shape": 1, "base_color": Color(0.95, 0.60, 0.75),
		"edge_color": Color(1.0, 0.9, 0.95), "glow_color": GLOW, "glow_energy": 2.4, "sway": 0.04,
		"ao_low": 1.0, "ao_span": 6.0})
	m["Petal"] = _shader("Petal", LEAF, {"shape": 2, "base_color": Color(0.95, 0.52, 0.72),
		"edge_color": Color(1.0, 0.86, 0.9), "glow_color": GLOW, "glow_energy": 2.6, "sway": 0.05,
		"ao_low": 2.0, "ao_span": 6.0})
	m["Heart"] = _shader("Heart", SEED, {"glow_color": GLOW, "core_color": Color(0.95, 1.0, 0.72),
		"noise_tex": NOISE, "energy": 2.5, "beat_period": 2.5, "boost": 1.0})
	m["Gate"] = _shader("Gate", RUNE, {"glow_color": GLOW, "energy": 1.6, "pulse_speed": 1.2,
		"rune_bands": 0, "boost": 1.0, "phase": 0.0})
	m["Cap"] = _shader("Cap", RUNE, {"glow_color": GLOW, "energy": 0.55, "pulse_speed": 0.9,
		"rune_bands": 0, "boost": 1.0, "phase": 1.7})
	m["Banner"] = _shader("Banner", BANNER, {"cloth_color": TEAM, "stripe_color": STRIPE,
		"trim_color": Color(0.58, 0.44, 0.25), "glyph_color": GLOW, "glyph_energy": 0.9, "amplitude": 0.08,
		"speed": 1.7})
	var black := StandardMaterial3D.new()
	black.resource_name = "Void"
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(0.03, 0.05, 0.02)
	m["Black"] = black
	var gd: int = gfx_detail()
	for k: String in PAINTED_KEYS + CARD_KEYS + ["Heart"]:
		(m[k] as ShaderMaterial).set_shader_parameter(&"gfx_detail", gd)
	return m


## G-B Nature: the painted layer's tier (nature_paint.gdshaderinc `gfx_detail`): Low 0, Medium 1, High / Ultra 2.
static func gfx_detail() -> int:
	return clampi(GameSettings.effective_graphics_quality(), 0, 2)


## G-B Nature: High / Ultra (fireflies, tier-up flourishes and other extra particles; Low keeps today's cost).
static func gfx_rich() -> bool:
	return GameSettings.effective_graphics_quality() >= 2


## The painted and card materials of a set (damage, rim, soot).
static func surface_materials(m: Dictionary) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for k: String in PAINTED_KEYS + CARD_KEYS:
		out.append(m[k])
	return out


static func glow_of(team: Color) -> Color:
	return GLOW if team.is_equal_approx(TEAM) else team.lightened(0.35)


## Team colour on a set (nature_keep.gd set_team_color): leaves, cards, banners, sap and every glow.
static func apply_team(m: Dictionary, c: Color) -> void:
	var glow: Color = glow_of(c)
	var is_default: bool = c.is_equal_approx(TEAM)
	(m["Leaves"] as ShaderMaterial).set_shader_parameter(&"base_color", c)
	var card: ShaderMaterial = m["LeafCard"]
	card.set_shader_parameter(&"base_color", c)
	card.set_shader_parameter(&"glow_color", glow)
	for k: String in ["Blossom", "Petal", "Heart", "Gate", "Cap"]:
		(m[k] as ShaderMaterial).set_shader_parameter(&"glow_color", glow)
	var ban: ShaderMaterial = m["Banner"]
	ban.set_shader_parameter(&"cloth_color", c)
	ban.set_shader_parameter(&"stripe_color", STRIPE if is_default else c.darkened(0.55))
	ban.set_shader_parameter(&"glyph_color", glow)
	(m["Bark"] as ShaderMaterial).set_shader_parameter(&"sap_color", glow)
	NVC.sync(m)   # the merged painted material (B8), when the building has one


## Selection / construction rim (nature_keep.gd _apply_rim_and_glow): idle = the Heartwood's green rim.
static func apply_rim(m: Dictionary, team: Color, sel_k: float, building: bool) -> void:
	var k: float = maxf(sel_k, 0.65) if building else sel_k
	var rim_col: Color = RIM_IDLE.lerp(team.lightened(0.2), k)
	var rim_str: float = lerpf(RIM_IDLE_STRENGTH, 0.9, k)
	for key: String in PAINTED_KEYS:
		(m[key] as ShaderMaterial).set_shader_parameter(&"rim_color", rim_col)
		(m[key] as ShaderMaterial).set_shader_parameter(&"rim_strength", rim_str)
	for key: String in CARD_KEYS:
		(m[key] as ShaderMaterial).set_shader_parameter(&"rim_color", rim_col)
		(m[key] as ShaderMaterial).set_shader_parameter(&"rim_strength", rim_str * 0.8)
	var ban: ShaderMaterial = m["Banner"]
	ban.set_shader_parameter(&"rim_color", team.lightened(0.3))
	ban.set_shader_parameter(&"rim_strength", 0.6 * sel_k)
	NVC.sync(m)   # the merged painted material (B8), when the building has one


## Glow boost (selection 1.4, pulses, collapse) on every glowing material of a set.
static func apply_boost(m: Dictionary, boost: float) -> void:
	for k: String in GLOW_KEYS:
		(m[k] as ShaderMaterial).set_shader_parameter(&"boost", boost)
	NVC.sync_cards(m)   # blossoms / petals glow in the merged card material (B8), when there is one


## Damage looks (nature_keep.gd _apply_health): soot, browning leaves, dropped cards and blossoms, a racing heart,
## sap bleeding wider. `hurt` = below 50 % HP, `dying` = below 25 %.
static func apply_health(m: Dictionary, r: float, hurt: bool, dying: bool) -> void:
	var dmg: float = (1.0 - r) * 0.5
	if dying:
		dmg = 1.0
	elif hurt:
		dmg = 0.6
	for k: String in PAINTED_KEYS:
		(m[k] as ShaderMaterial).set_shader_parameter(&"damage", dmg)
	for k: String in CARD_KEYS:
		(m[k] as ShaderMaterial).set_shader_parameter(&"damage", dmg * 0.8)
	(m["Banner"] as ShaderMaterial).set_shader_parameter(&"damage", dmg)
	var wither: float = 0.38 if dying else (0.2 if hurt else 0.0)
	(m["Leaves"] as ShaderMaterial).set_shader_parameter(&"wither", wither)
	var card: ShaderMaterial = m["LeafCard"]
	card.set_shader_parameter(&"wither", wither * 0.9)
	card.set_shader_parameter(&"drop", 0.5 if dying else (0.25 if hurt else 0.0))
	(m["Blossom"] as ShaderMaterial).set_shader_parameter(&"drop", 0.85 if dying else (0.5 if hurt else 0.0))
	(m["Heart"] as ShaderMaterial).set_shader_parameter(&"beat_period", 0.9 if dying else (1.6 if hurt else 2.5))
	(m["Petal"] as ShaderMaterial).set_shader_parameter(&"glow_energy", 1.4 if dying else (2.1 if hurt else 2.6))
	NVC.sync(m)   # the merged painted material (B8), when the building has one


## Collapse, 0..1 after the fall: the canopy browns fully, the sap drains, the glow dims to embers.
static func apply_wreck(m: Dictionary, k: float) -> void:
	(m["Leaves"] as ShaderMaterial).set_shader_parameter(&"wither", lerpf(0.7, 1.0, k))
	(m["LeafCard"] as ShaderMaterial).set_shader_parameter(&"wither", lerpf(0.7, 1.0, k))
	(m["Bark"] as ShaderMaterial).set_shader_parameter(&"sap", lerpf(1.0, 0.15, k))
	NVC.sync(m)   # the merged painted material (B8), when the building has one


## The moss ground patch (nature_ground.gdshader) for a plinth of half-size `plinth_half`.
static func ground_material(size: float, plinth_half: float, chamfer_sum: float, roundness: float,
		ring_radius: float, ring_caps: float, seed: float) -> ShaderMaterial:
	var m := _shader("Ground", GROUND, {"noise_tex": NOISE, "size": size, "plinth_half": plinth_half,
		"chamfer_sum": chamfer_sum, "roundness": roundness, "reach_min": plinth_half + 0.2,
		"root_start": plinth_half - 0.1, "root_len": clampf(size * 0.18, 0.7, 1.6),
		"root_count": clampf(plinth_half * 3.0, 5.0, 10.0), "root_width": clampf(plinth_half * 0.06, 0.08, 0.18),
		"ring_radius": ring_radius, "ring_caps": ring_caps, "cap_size": clampf(plinth_half * 0.35, 0.7, 1.0),
		"petal_scale": 2.6, "seed": seed, "glow_color": GLOW, "ring_energy": 0.8})
	m.render_priority = -1
	return m


# ============================================================ particles

## Soft radial dot (ADD or MIX), billboard, vertex colour: pollen, sparks, smoke.
static func soft_quad(add: bool) -> Mesh:
	if not add:
		return atlas_quad(0)   # B8: the MIX dot shares one atlas material with the leaf and petal cut-outs
	var key: String = "soft_%s" % add
	if _quads.has(key):
		return _quads[key]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	var q := _card_quad(t, add)
	_quads[key] = q
	return q


## A tumbling leaf (0) or petal (1) cut-out, MIX, billboard, tinted by the particle colour.
static func shape_quad(kind: int) -> Mesh:
	return atlas_quad(1 + kind)   # B8: leaf / petal cut-outs share one atlas material with the MIX soft dot


## B8: ONE MIX billboard material for the soft dot (frame 0), the tumbling leaf (1) and the petal (2): a 3-cell atlas
## texture; each frame is its own quad whose UVs cover one cell (the images are the ones soft_quad / shape_quad drew).
static func atlas_quad(frame: int) -> Mesh:
	var key: String = "atlas_%d" % frame
	if _quads.has(key):
		return _quads[key]
	if not _quads.has("atlas_mat"):
		var n: int = 64
		var img := Image.create(n * 3, n, false, Image.FORMAT_RGBA8)
		var soft := _soft_image(n)
		img.blit_rect(soft, Rect2i(0, 0, n, n), Vector2i(0, 0))
		for k: int in 2:
			img.blit_rect(_shape_image(k, n), Rect2i(0, 0, n, n), Vector2i(n * (k + 1), 0))
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		_quads["atlas_mat"] = m
	var q := QuadMesh.new()
	var a: Array = q.surface_get_arrays(0)
	var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var inset: float = 0.5 / 64.0
	for i: int in uv.size():
		uv[i] = Vector2((float(frame) + lerpf(inset, 1.0 - inset, uv[i].x)) / 3.0, uv[i].y)
	a[Mesh.ARRAY_TEX_UV] = uv
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	am.surface_set_material(0, _quads["atlas_mat"])
	_quads[key] = am
	return am


## The soft radial dot (soft_quad's gradient: alpha 1 -> 0.5 at 35 % -> 0) as an image.
static func _soft_image(n: int) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y: int in n:
		for x: int in n:
			var d: float = Vector2((float(x) + 0.5) / float(n) - 0.5, (float(y) + 0.5) / float(n) - 0.5).length() * 2.0
			var a: float = lerpf(1.0, 0.5, d / 0.35) if d < 0.35 else lerpf(0.5, 0.0, clampf((d - 0.35) / 0.65, 0.0, 1.0))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return img


## The leaf (0) / petal (1) cut-out (shape_quad's drawing) as an image.
static func _shape_image(kind: int, n: int) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y: int in n:
		for x: int in n:
			var u: float = (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v: float = (float(y) + 0.5) / float(n)
			var inside: float
			var shade: float = 1.0
			if kind == 0:
				var hw: float = pow(sin(PI * v), 0.8) * 0.55
				inside = clampf((hw - absf(u)) * 18.0, 0.0, 1.0)
				shade = lerpf(0.72, 1.0, clampf(absf(u) * 8.0, 0.0, 1.0)) * lerpf(0.85, 1.1, v)
			else:
				var d: float = Vector2(u / 0.62, (v - 0.5) / 0.46).length()
				inside = clampf((1.0 - d) * 10.0, 0.0, 1.0)
				shade = lerpf(1.1, 0.85, d)
			img.set_pixel(x, y, Color(shade, shade, shade, inside))
	return img


static func _card_quad(tex: Texture2D, add: bool) -> QuadMesh:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	var q := QuadMesh.new()
	q.material = m
	return q


## A colour ramp from (offset, colour) stops; `track` collects the gradient for team recolouring.
static func ramp(offsets: Array[float], colors: Array[Color], track: Array = []) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	track.append(g)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


## A ParticleProcessMaterial (art-keep.md 0.6): direction / spread, speed range, gravity, size start -> end, ramp.
static func process(dir: Vector3, spread: float, vmin: float, vmax: float, gravity: Vector3, size_start: float,
		size_end: float, color_ramp: Texture2D) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir.normalized()
	pm.spread = spread
	pm.initial_velocity_min = vmin
	pm.initial_velocity_max = vmax
	pm.gravity = gravity
	var base: float = maxf(size_start, size_end)
	pm.scale_min = base
	pm.scale_max = base
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, size_start / base))
	curve.add_point(Vector2(1.0, size_end / base))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	pm.color_ramp = color_ramp
	return pm


## Tumbling cards (leaves, petals): random start angle and spin.
static func tumble(pm: ParticleProcessMaterial, spin: float) -> void:
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	pm.angular_velocity_min = -spin
	pm.angular_velocity_max = spin


## Turns a state plume into the Heartwood's withering leaves pouring down (below 25 % HP), in a sphere of `radius`.
static func make_withering(p: GPUParticles3D, radius: float, amount: int) -> void:
	var r: GradientTexture1D = ramp([0.0, 0.08, 0.7, 1.0], [Color(0.66, 0.46, 0.14, 0.0), Color(0.66, 0.46, 0.14, 1.0),
		Color(0.48, 0.3, 0.1, 1.0), Color(0.3, 0.2, 0.08, 0.0)])
	var pm := process(Vector3.DOWN, 35.0, 0.5, 1.2, Vector3(0.3, -1.4, 0.0), 0.24 * clampf(radius, 0.6, 1.0),
		0.2 * clampf(radius, 0.6, 1.0), r)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius
	tumble(pm, 200.0)
	p.process_material = pm
	p.draw_pass_1 = shape_quad(0)
	p.amount = amount
	p.lifetime = 2.6


## Ground dressing round a plinth (the Heartwood's): mossy boulders, fern tufts, glowing mushroom clusters on a ring
## r_min .. r_max, skipping points where `blocked` (Callable(Vector3) -> bool) says so.
static func dressing(mb: MB, rng: RandomNumberGenerator, boulders: int, ferns: int, mushrooms: int, r_min: float,
		r_max: float, blocked: Callable, scale: float = 1.0) -> void:
	var spots: Array[Vector3] = []
	var want: int = boulders + ferns + mushrooms
	var tries: int = 0
	while spots.size() < want and tries < 600:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(r_min, r_max)
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		if blocked.call(p):
			continue
		var ok: bool = true
		for s: Vector3 in spots:
			if s.distance_to(p) < 0.75 * scale:
				ok = false
				break
		if ok:
			spots.append(p)
	for i: int in spots.size():
		var p: Vector3 = spots[i]
		if i < boulders:
			var s: float = rng.randf_range(0.28, 0.5) * scale
			mb.xf = Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(0.05, 0.3)), p)
			mb.loft("Dark", [ring_n(6, s, rng.randf()), ring_n(6, s * 0.7, rng.randf())],
				[-0.15, rng.randf_range(0.22, 0.5) * scale], true)
			mb.xf = Transform3D.IDENTITY
		elif i < boulders + ferns:
			for f: int in 6:
				var fa: float = TAU * float(f) / 6.0 + rng.randf() * 0.5
				var d := Vector3(cos(fa), 0, sin(fa))
				var dir: Vector3 = (d * 0.6 + Vector3.UP * rng.randf_range(0.6, 1.0)).normalized()
				var h: float = rng.randf_range(0.5, 0.8) * scale
				var bend: Vector3 = (dir + d * 0.8 + Vector3.DOWN * 0.3).normalized()
				var nn: Vector3 = (Vector3.UP + d * 0.3).normalized()
				mb.strip("LeafCard", [p, p + dir * h * 0.55, p + dir * h * 0.55 + bend * h * 0.45] as Array[Vector3],
					d.cross(Vector3.UP).normalized(), 0.3 * scale, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())
		else:
			for m: int in 3:
				var q: Vector3 = p + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3)) * scale
				var h: float = rng.randf_range(0.22, 0.45) * scale
				var cr: float = rng.randf_range(0.12, 0.2) * scale
				mb.xf = Transform3D(Basis(Vector3.RIGHT, rng.randf_range(-0.2, 0.2)), q)
				mb.tube("Dark", [Vector3.ZERO, Vector3(0.03, h, 0)] as Array[Vector3], [0.05 * scale, 0.04 * scale] as Array[float], 5, 1.0)
				mb.loft("Cap", [ring_n(7, cr), ring_n(7, cr * 0.7), ring_n(7, 0.02)], [h - 0.04, h + 0.06, h + 0.12], false, true)
				mb.xf = Transform3D.IDENTITY


## A curled fiddlehead fern at `base` (stem, spiral head, two fronds): the small buildings' asymmetric detail.
static func fiddlehead(mb: MB, base: Vector3, h: float, rng: RandomNumberGenerator) -> void:
	var pts: Array[Vector3] = [base, base + Vector3(-0.08, h * 0.45, 0.0), base + Vector3(0.0, h * 0.85, -0.04)]
	mb.tube("Moss", pts, [0.1, 0.08, 0.07] as Array[float], 6, 1.0)
	var c: Vector3 = base + Vector3(0.12, h, -0.04)
	var spiral: Array[Vector3] = []
	var rad: Array[float] = []
	for i: int in 9:
		var a: float = PI + float(i) * 0.8
		var rr: float = h * 0.2 * (1.0 - float(i) * 0.1)
		spiral.append(c + Vector3(cos(a) * rr, sin(a) * rr, 0.0))
		rad.append(0.075 * (1.0 - float(i) * 0.08))
	mb.tube("Moss", spiral, rad, 6, 1.0, 0.0, 0.0, false, true)
	for k: int in 2:
		var d: Vector3 = dir_deg(rng.randf_range(0.0, 360.0))
		var dir: Vector3 = (d * 0.7 + Vector3.UP * 0.7).normalized()
		var bend: Vector3 = (dir + d + Vector3.DOWN * 0.5).normalized()
		var p0: Vector3 = base + Vector3(0, h * (0.25 + 0.2 * k), 0)
		var nn: Vector3 = (Vector3.UP + d * 0.3).normalized()
		mb.strip("LeafCard", [p0, p0 + dir * h * 0.4, p0 + dir * h * 0.4 + bend * h * 0.4] as Array[Vector3],
			d.cross(Vector3.UP).normalized(), h * 0.3, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())


## Soft ring (bright band near the edge, faint fill inside) for the Bramble Spire's aura pulse. White, tinted by
## the material colour.
static func ring_texture() -> Texture2D:
	if _quads.has("ring_tex"):
		return _quads["ring_tex"]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 0.87, 0.94, 0.985, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.02), Color(1, 1, 1, 0.12), Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	_quads["ring_tex"] = tex
	return tex


## Distance from the active camera to `p` (global), or 0 when there is none (headless: counts as near).
static func camera_distance(n: Node3D, p: Vector3) -> float:
	if not n.is_inside_tree():
		return 0.0
	var cam: Camera3D = n.get_viewport().get_camera_3d()
	return cam.global_position.distance_to(p) if cam else 0.0
