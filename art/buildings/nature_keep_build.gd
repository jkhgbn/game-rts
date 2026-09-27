extends SceneTree
## Generates art/buildings/nature_keep.tscn: Ysolde's Heartwood, a living-tree citadel (task A2.5 epic pass of
## kingdom-nature.md 7.1 + art-keep.md sections 0 / 6-9). Run it WINDOWED (headless drops mesh data when saving):
##   Godot --path . -s art/buildings/nature_keep_build.gd --fixed-fps 60 --quit-after 120
## The read: an ancient tree grown out of a ruined round stone keep. Its roots are the walls' buttresses and
## pour over the parapet into the ground, a braided trunk carries a wooden gallery and a glowing heart knot, a
## lumpy canopy fringed with leaves and blossoms holds three seed-lanterns, and a great Crown Bloom opens on top.
## Every static section is ONE ArrayMesh with one surface per material (UVs in metres for the painted patterns of
## nature_keep/nature_keep_painted.gdshader). Node names are the contract with nature_keep.gd.
## Local space: metres, y up, gate on -Z, footprint 6 x 6 (Building owns the collider).

const OUT := "res://art/buildings/nature_keep.tscn"
const KeepScript := preload("res://art/buildings/nature_keep.gd")
const DIR := "res://art/buildings/nature_keep/"
const TEAM := Color(0.35, 0.70, 0.25)
const GLOW := Color(0.75, 1.00, 0.40)
const COS15 := 0.9659258
const TRUNK_BASE := 2.6
const TRUNK_TOP := 10.4

## Canopy clumps: (angle deg from -Z toward +X, distance from the axis, centre y, radius); squash per clump.
## Clumps 5 and 8 are "CanopyLost" (they fall off below 50 % HP). Clump 9 is the low bough's.
const CLUMPS: Array[Vector4] = [
	Vector4(0.0, 0.45, 14.3, 2.6), Vector4(275.0, 1.85, 12.5, 1.8), Vector4(95.0, 1.8, 12.8, 1.85),
	Vector4(165.0, 1.85, 12.3, 1.8), Vector4(345.0, 1.9, 12.2, 1.8), Vector4(35.0, 2.1, 11.8, 1.5),
	Vector4(220.0, 1.95, 11.9, 1.5), Vector4(60.0, 1.5, 14.0, 1.45), Vector4(300.0, 1.45, 14.1, 1.4),
	Vector4(172.0, 2.65, 9.1, 1.05),
]
## Seed-lanterns hang under clumps 2 (+X), 1 (-X) and 3 (+Z); vine lengths.
const LANTERN_CLUMPS: Array[int] = [2, 1, 3]
const LANTERN_DROP: Array[float] = [2.7, 2.8, 2.5]
const CLUMP_SQUASH: Array[float] = [0.78, 0.72, 0.72, 0.72, 0.72, 0.74, 0.74, 0.8, 0.8, 0.72]
const LOST_CLUMPS: Array[int] = [5, 8]
## Roots: (angle deg from -Z toward +X, size). They avoid the gate (0) and the three wall banners (90 / 180 / 270).
const ROOTS: Array[Vector2] = [Vector2(36, 1.0), Vector2(64, 0.72), Vector2(120, 0.9), Vector2(148, 1.0),
	Vector2(210, 0.95), Vector2(238, 0.72), Vector2(298, 0.9), Vector2(324, 1.0)]
const BANNER_SIDES: Array[float] = [90.0, 180.0, 270.0]
## Gate standards (banner poles) on the lower plinth step, and the way their banners face (turned out 40 deg so
## the game camera, which sees the gate side in profile, still sees the cloth).
const STANDARDS: Array[Vector3] = [Vector3(-1.62, 0.5, -3.16), Vector3(1.62, 0.5, -3.16)]

var noise: Texture2D
var mats: Dictionary = {}
var keep: Node3D
var model: Node3D
var rng := RandomNumberGenerator.new()
var team_leaf_ramps: Array[Gradient] = []
var team_glow_ramps: Array[Gradient] = []
var bloom_pos := Vector3(0, 15.0, -0.3) # set from the crown clump's top in _build_canopy


# ============================================================ mesh builder

## One surface's triangles (untyped Arrays so appends through the Dictionary stick).
class Surf:
	var v: Array = []
	var n: Array = []
	var uv: Array = []
	var uv2: Array = []
	var c: Array = []


## Multi-surface mesh builder. `tri` is flat shaded and faces away from an `inside` point; `tri_s` takes smooth
## normals and faces along them. `xf` transforms everything added (positions and normals).
class MB:
	var order: Array[String] = []
	var surfs: Dictionary = {}
	var xf: Transform3D = Transform3D.IDENTITY
	var flip: bool = false
	## Vertex colour for everything added (r = baked ambient occlusion, 1 = open).
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
		s.v.append_array([a, c, b])
		s.n.append_array([nn, nn, nn])
		s.uv.append_array([ua, uc, ub])
		s.uv2.append_array([u2, u2, u2])
		s.c.append_array([col, col, col])

	## Smooth-shaded triangle: faces the side its vertex normals point to.
	func tri_s(k: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
			ua: Vector2, ub: Vector2, uc: Vector2, u2: Vector2 = Vector2.ZERO) -> void:
		tri_sc(k, a, b, c, na, nb, nc, ua, ub, uc, u2, col, col, col)

	## tri_s with a colour per vertex.
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
		s.v.append_array([a, c, b])
		s.n.append_array([na, nc, nb])
		s.uv.append_array([ua, uc, ub])
		s.uv2.append_array([u2, u2, u2])
		s.c.append_array([ca, cc, cb])

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

	## Side walls between polygon rings (Array of Vector2 x/z around +y) at heights ys; u runs along the ring
	## in metres, v = y. Caps are fans with planar UVs.
	func loft(k: String, rings: Array, ys: Array, cap_top: bool = true, cap_bottom: bool = false) -> void:
		var cnt: int = (rings[0] as Array).size()
		for L: int in rings.size() - 1:
			var r0: Array = rings[L]
			var r1: Array = rings[L + 1]
			var y0: float = ys[L]
			var y1: float = ys[L + 1]
			var inside := Vector3(0.0, (y0 + y1) * 0.5, 0.0)
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

	## A hollow band around a solid: outer face plus top and bottom rings (no inner face).
	func band(k: String, outer: Array, inner: Array, y0: float, y1: float) -> void:
		loft(k, [outer, outer], [y0, y1], false, false)
		var cnt: int = outer.size()
		for i: int in cnt:
			var j: int = (i + 1) % cnt
			var o0: Vector2 = outer[i]
			var o1: Vector2 = outer[j]
			var i0: Vector2 = inner[i]
			var i1: Vector2 = inner[j]
			for y: float in [y0, y1]:
				var dy: float = -1.0 if y == y1 else 1.0
				quad(k, Vector3(o0.x, y, o0.y), Vector3(o1.x, y, o1.y), Vector3(i1.x, y, i1.y), Vector3(i0.x, y, i0.y),
					o0, o1, i1, i0, Vector3((o0.x + i0.x) * 0.5, y + dy, (o0.y + i0.y) * 0.5))

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

	func commit(materials: Dictionary) -> Array:
		var mesh := ArrayMesh.new()
		var used: Array[Material] = []
		for k: String in order:
			var s: Surf = surfs[k]
			if s.v.is_empty():
				continue
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(s.v)
			arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(s.n)
			arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(s.uv)
			arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(s.uv2)
			arrays[Mesh.ARRAY_COLOR] = PackedColorArray(s.c)
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			used.append(materials[k])
		return [mesh, used]


# ============================================================ ring / shape helpers

## Regular polygon, circumradius r, points ordered around +y starting at angle `rot` from +x.
static func ring_n(n: int, r: float, rot: float = 0.0, off: Vector2 = Vector2.ZERO) -> Array:
	var pts: Array = []
	for i: int in n:
		var a: float = rot + TAU * float(i) / float(n)
		pts.append(off + Vector2(r * cos(a), -r * sin(a)))
	return pts


## 12-gon with a flat face toward -Z, given the apothem (centre to a flat face).
static func ring12(ap: float) -> Array:
	var r: float = ap / COS15
	var pts: Array = []
	for k: int in 12:
		var a: float = deg_to_rad(15.0 + 30.0 * float(k))
		pts.append(Vector2(sin(a) * r, -cos(a) * r))
	return pts


## Square of half-size h with 45-degree chamfered corners (leg ch).
static func chamfer(h: float, ch: float) -> Array:
	var e: float = h - ch
	return [Vector2(h, e), Vector2(h, -e), Vector2(e, -h), Vector2(-e, -h),
		Vector2(-h, -e), Vector2(-h, e), Vector2(-e, h), Vector2(e, h)]


## Horizontal direction at `deg` degrees from -Z toward +X.
static func dir_deg(deg: float) -> Vector3:
	var a: float = deg_to_rad(deg)
	return Vector3(sin(a), 0.0, -cos(a))


## The rampart's wall face (apothem) at height y: battered from 2.6 at y 1.25 to 2.42 at y 3.3.
static func wall_ap(y: float) -> float:
	return lerpf(2.6, 2.42, clampf((y - 1.25) / 2.05, 0.0, 1.0))


static func clump_center(i: int) -> Vector3:
	var c: Vector4 = CLUMPS[i]
	return dir_deg(c.x) * c.y + Vector3(0, c.z, 0)


## Hang point of seed-lantern i: under the outer rim of its clump (just inside the leaves).
static func lantern_pivot(i: int) -> Vector3:
	var ci: int = LANTERN_CLUMPS[i]
	var out: Vector3 = dir_deg(CLUMPS[ci].x)
	return clump_center(ci) + out * 0.95 - Vector3(0, CLUMPS[ci].w * 0.45, 0)


# ============================================================ entry

func _initialize() -> void:
	rng.seed = 7117
	noise = load("res://art/shaders/paint_noise.tres")
	_make_materials()
	keep = Node3D.new()
	keep.name = "NatureKeep"
	keep.set_script(KeepScript)
	model = _add(Node3D.new(), keep, "Model")

	_build_plinth()
	_build_rampart()
	_build_trunk()
	_build_canopy()
	_build_bloom()
	_build_lanterns()
	_build_banners()
	_build_state_meshes()
	_build_ground()
	_build_lights_and_fx()

	keep.set(&"painted_materials", [mats["Stone"], mats["Dark"], mats["Bark"], mats["Wood"], mats["Moss"],
		mats["Leaves"]] as Array[ShaderMaterial])
	keep.set(&"card_materials", [mats["LeafCard"], mats["Blossom"], mats["Petal"]] as Array[ShaderMaterial])
	keep.set(&"glow_materials", [mats["Heart"], mats["Gate"], mats["Lantern"]] as Array[ShaderMaterial])
	keep.set(&"bark_material", mats["Bark"])
	keep.set(&"leaves_material", mats["Leaves"])
	keep.set(&"leafcard_material", mats["LeafCard"])
	keep.set(&"blossom_material", mats["Blossom"])
	keep.set(&"petal_material", mats["Petal"])
	keep.set(&"heart_material", mats["Heart"])
	keep.set(&"gate_material", mats["Gate"])
	keep.set(&"lantern_material", mats["Lantern"])
	keep.set(&"banner_material", mats["Banner"])
	keep.set(&"ground_material", mats["Ground"])
	keep.set(&"outline_material", mats["Outline"])
	keep.set(&"bloom_position", bloom_pos)

	_own(keep, keep)
	var ps := PackedScene.new()
	var err: int = ps.pack(keep)
	if err == OK:
		err = ResourceSaver.save(ps, OUT)
	print("nature_keep_build: saved ", OUT, " err=", err, " verts=", _count_verts(keep))
	keep.free()
	quit()


func _count_verts(n: Node) -> int:
	var total: int = 0
	var mi := n as MeshInstance3D
	if mi and mi.mesh:
		var line: String = "  %s:" % mi.name
		for s: int in mi.mesh.get_surface_count():
			var cnt: int = (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			total += cnt
			var m: Material = mi.get_surface_override_material(s)
			line += " %s=%d" % [m.resource_name if m else "?", cnt / 3]
		if OS.get_cmdline_user_args().has("--stats"):
			print(line, " tris")
	for c: Node in n.get_children():
		total += _count_verts(c)
	return total


func _add(n: Node, parent: Node, nm: String) -> Node:
	n.name = nm
	parent.add_child(n)
	return n


func _own(n: Node, owner_node: Node) -> void:
	for c: Node in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


## MeshInstance3D from a builder, one surface override per material, painted height gradient params.
func _mesh_node(mb: MB, nm: String, parent: Node3D, ao_bottom: float, ao_height: float,
		shadow: bool = true, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var res: Array = mb.commit(mats)
	var mi := MeshInstance3D.new()
	mi.mesh = res[0]
	mi.position = pos
	_add(mi, parent, nm)
	var used: Array[Material] = res[1]
	for i: int in used.size():
		mi.set_surface_override_material(i, used[i])
	mi.set_instance_shader_parameter(&"ao_bottom", ao_bottom)
	mi.set_instance_shader_parameter(&"ao_height", ao_height)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ============================================================ materials

func _painted(nm: String, color: Color, pattern: int, params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.resource_name = nm
	m.resource_local_to_scene = true
	m.shader = load(DIR + "nature_keep_painted.gdshader")
	m.set_shader_parameter(&"base_color", color)
	m.set_shader_parameter(&"noise_tex", noise)
	m.set_shader_parameter(&"pattern", pattern)
	m.set_shader_parameter(&"rim_color", KeepScript.RIM_IDLE)
	m.set_shader_parameter(&"rim_strength", KeepScript.RIM_IDLE_STRENGTH)
	m.set_shader_parameter(&"sap_color", GLOW)
	for k: String in params:
		m.set_shader_parameter(StringName(k), params[k])
	return m


func _shader_mat(nm: String, path: String, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.resource_name = nm
	m.resource_local_to_scene = true
	m.shader = load(path)
	for k: String in params:
		m.set_shader_parameter(StringName(k), params[k])
	return m


func _make_materials() -> void:
	var moss_col := Color(0.22, 0.31, 0.11)
	mats["Stone"] = _painted("Stone", Color(0.5, 0.47, 0.37), 1, {"block_size": Vector2(0.95, 0.46),
		"joint_width": 0.07, "block_tint": 0.2, "moss": 0.45, "moss_color": moss_col})
	mats["Dark"] = _painted("DarkStone", Color(0.26, 0.24, 0.17), 1, {"block_size": Vector2(0.8, 0.42),
		"joint_width": 0.06, "block_tint": 0.24, "moss": 0.35, "moss_color": moss_col})
	mats["Bark"] = _painted("Bark", Color(0.40, 0.28, 0.16), 2, {"sap": 1.0, "sap_energy": 1.35,
		"sap_speed": 0.25, "bark_scale": Vector2(1.0, 0.16), "moss": 0.35, "moss_color": moss_col,
		"spec_strength": 0.04})
	mats["Wood"] = _painted("Wood", Color(0.56, 0.41, 0.24), 4, {"block_size": Vector2(1.6, 0.26),
		"joint_width": 0.04, "block_tint": 0.2})
	mats["Moss"] = _painted("Moss", Color(0.2, 0.3, 0.1), 0, {"moss": 0.3, "moss_color": moss_col})
	mats["Leaves"] = _painted("Leaves", TEAM, 3, {"noise_scale_a": 0.8, "leaf_scale": 1.35,
		"foliage_value": 0.62, "top_tint": Color(1.32, 1.22, 0.7)})
	var leaf := DIR + "nature_keep_leaf.gdshader"
	mats["LeafCard"] = _shader_mat("LeafCard", leaf, {"shape": 0, "base_color": TEAM, "sway": 0.1,
		"glow_color": GLOW, "leaf_value": 0.68})
	mats["Blossom"] = _shader_mat("Blossom", leaf, {"shape": 1, "base_color": Color(0.95, 0.60, 0.75),
		"edge_color": Color(1.0, 0.9, 0.95), "glow_color": GLOW, "glow_energy": 2.4, "sway": 0.05})
	mats["Petal"] = _shader_mat("Petal", leaf, {"shape": 2, "base_color": Color(0.95, 0.52, 0.72),
		"edge_color": Color(1.0, 0.86, 0.9), "glow_color": GLOW, "glow_energy": 2.6, "sway": 0.06,
		"ao_low": 12.0, "ao_span": 4.0})
	mats["Heart"] = _shader_mat("Heart", DIR + "nature_keep_seed.gdshader", {"glow_color": GLOW,
		"core_color": Color(0.95, 1.0, 0.72), "noise_tex": noise, "energy": 2.5, "beat_period": 2.5, "boost": 1.0})
	var glow := "res://art/shaders/rune_glow.gdshader"
	mats["Gate"] = _shader_mat("Gate", glow, {"glow_color": GLOW, "energy": 1.6, "pulse_speed": 1.2,
		"rune_bands": 0, "boost": 1.0, "phase": 0.0})
	mats["Lantern"] = _shader_mat("Lantern", "res://art/buildings/nature_keep_glow.gdshader",
		{"glow_color": GLOW, "boost_mult": 1.0})
	mats["Outline"] = _shader_mat("Outline", "res://art/buildings/nature_keep_glow.gdshader",
		{"glow_color": GLOW, "boost_mult": 1.0})
	mats["Banner"] = _shader_mat("Banner", DIR + "nature_keep_banner.gdshader", {"cloth_color": TEAM,
		"stripe_color": Color(0.15, 0.40, 0.15), "trim_color": Color(0.58, 0.44, 0.25), "glyph_color": GLOW,
		"glyph_energy": 0.9, "amplitude": 0.09, "speed": 1.7})
	mats["Ground"] = _shader_mat("Ground", "res://art/buildings/nature_keep_ground.gdshader",
		{"noise_tex": noise, "size": 13.0, "glow_color": GLOW, "ring_energy": 0.7})
	(mats["Ground"] as ShaderMaterial).render_priority = -1
	var black := StandardMaterial3D.new()
	black.resource_name = "GateVoid"
	black.resource_local_to_scene = true
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(0.03, 0.05, 0.02)
	mats["Black"] = black


# ============================================================ plinth, menhirs

func _build_plinth() -> void:
	var mb := MB.new()
	# Two battered, chamfered steps of dark mossy flagstones (top at y 0.9).
	mb.loft("Dark", [chamfer(3.3, 1.0), chamfer(3.22, 0.97)], [0.0, 0.5])
	mb.loft("Dark", [chamfer(3.05, 0.9), chamfer(3.0, 0.88)], [0.5, 0.9])
	# Stairs down from the gate and their cheek stones.
	mb.box("Dark", Vector3(0, 0.3, -3.25), Vector3(1.9, 0.6, 0.5))
	mb.box("Dark", Vector3(0, 0.15, -3.65), Vector3(2.0, 0.3, 0.42))
	for sx: float in [-1.0, 1.0]:
		mb.box("Stone", Vector3(sx * 1.1, 0.42, -3.35), Vector3(0.3, 0.84, 0.95),
			Basis(Vector3.RIGHT, deg_to_rad(-6.0)))
	# Standing stones on the four chamfered corners: tapered, leaning out, glowing leaf runes on the outer face.
	var heights: Array[float] = [2.8, 2.35, 3.0, 2.55]
	for i: int in 4:
		var deg: float = 45.0 + 90.0 * float(i)
		var out: Vector3 = dir_deg(deg)
		var across := Vector3(-out.z, 0, out.x)
		var base: Vector3 = out * 3.22 + Vector3(0, 0.82, 0)
		var h: float = heights[i]
		var lean: float = deg_to_rad(6.0 + 2.0 * float(i % 2))
		var top_c: Vector3 = base + Vector3(0, h, 0) + out * h * tan(lean)
		var p: Array[Vector3] = []
		for bit: int in 8:
			var sx: float = 1.0 if (bit & 1) != 0 else -1.0
			var sz: float = 1.0 if (bit & 4) != 0 else -1.0
			var top: bool = (bit & 2) != 0
			var w: float = 0.26 if top else 0.4
			var d: float = 0.19 if top else 0.3
			var c: Vector3 = top_c if top else base
			p.append(c + across * sx * w + out * sz * d)
		mb.hexa("Stone", p)
		# Rough pyramid top.
		var apex: Vector3 = top_c + Vector3(0, 0.36, 0) + across * 0.05
		var tp: Array[Vector3] = [p[2], p[3], p[7], p[6]]
		for k: int in 4:
			mb.tri_auto("Stone", tp[k], tp[(k + 1) % 4], apex, top_c - Vector3(0, 0.2, 0))
		# Runes on the outer face: a stem with two pairs of leaf strokes and a seed dot.
		var fb: Vector3 = base + out * 0.3
		var ft: Vector3 = top_c + out * 0.19
		var fup: Vector3 = (ft - fb).normalized()
		var fn: Vector3 = across.cross(fup).normalized()
		if fn.dot(out) < 0.0:
			fn = -fn
		var face_at := func(s: float, t: float) -> Vector3:
			return fb.lerp(ft, s) + across * t * lerpf(1.0, 0.65, s) + fn * 0.035
		var bs := Basis(across, fup, fn)
		mb.box("Gate", face_at.call(0.45, 0.0), Vector3(0.07, h * 0.5, 0.05), bs)
		for s: float in [0.34, 0.52]:
			for sd: float in [-1.0, 1.0]:
				var rot := Basis(Vector3.BACK, sd * deg_to_rad(-40.0))
				mb.box("Gate", face_at.call(s + 0.04, sd * 0.1), Vector3(0.06, 0.26, 0.05), bs * rot)
		mb.box("Gate", face_at.call(0.76, 0.0), Vector3(0.13, 0.13, 0.05), bs * Basis(Vector3.BACK, PI * 0.25))
	_mesh_node(mb, "Plinth", model, 0.0, 3.5)


# ============================================================ rampart (the ruined stone keep), gate, standards

func _build_rampart() -> void:
	var mb := MB.new()
	# Base course, battered wall, a string course, corbel, parapet and walkway; earth mound inside.
	mb.loft("Dark", [ring12(2.72), ring12(2.66)], [0.9, 1.25], false)
	mb.loft("Stone", [ring12(2.6), ring12(2.42)], [1.25, 3.3], false)
	mb.band("Dark", ring12(2.58), ring12(2.49), 2.28, 2.44)
	mb.loft("Dark", [ring12(2.42), ring12(2.64)], [3.3, 3.55], false)
	mb.loft("Stone", [ring12(2.64), ring12(2.64)], [3.55, 3.82], false)
	mb.annulus("Dark", ring12(2.64), ring12(2.2), 3.82)
	mb.loft("Moss", [ring12(2.2), ring12(1.45)], [3.82, 4.12], true)
	# Parapet blocks every 15 deg, some missing, broken or tilted; none where a root climbs over or at the gate.
	for k: int in 24:
		var deg: float = 15.0 * float(k)
		if absf(wrapf(deg, -180.0, 180.0)) < 28.0 or _near_root(deg, 13.0):
			continue
		if rng.randf() < 0.22:
			continue # a missing block
		var out: Vector3 = dir_deg(deg)
		var h: float = rng.randf_range(0.26, 0.5)
		var tilt: float = rng.randf_range(-0.14, 0.14)
		mb.box("Stone", out * 2.47 + Vector3(0, 3.82 + h * 0.5 - 0.03, 0), Vector3(0.5, h, 0.34),
			Basis(Vector3.UP, -deg_to_rad(deg)) * Basis(Vector3.FORWARD, tilt))
	# Gatehouse: a squared portal pushed out of the -Z face, a cornice, a pointed crest stone.
	mb.box("Stone", Vector3(0, 2.36, -2.72), Vector3(2.55, 2.92, 0.64))
	mb.box("Dark", Vector3(0, 3.93, -2.76), Vector3(2.85, 0.24, 0.8))
	mb.box("Dark", Vector3(0, 1.07, -2.78), Vector3(2.75, 0.34, 0.76))
	for sx: float in [-1.0, 1.0]:
		mb.box("Dark", Vector3(sx * 1.2, 2.4, -3.06), Vector3(0.24, 2.7, 0.12))
	var crest: Array[Vector3] = [Vector3(-0.55, 4.05, -2.95), Vector3(0.55, 4.05, -2.95), Vector3(0.55, 4.05, -2.55),
		Vector3(-0.55, 4.05, -2.55)]
	var crest_top := Vector3(0, 4.75, -2.78)
	for i: int in 4:
		mb.tri_auto("Stone", crest[i], crest[(i + 1) % 4], crest_top, Vector3(0, 4.2, -2.75))
	# Arch: jamb stones, nine voussoirs with a big keystone (a glowing seed rune on it).
	var zc: float = -3.04
	var spring: float = 2.3
	var ar: float = 0.72
	for sx: float in [-1.0, 1.0]:
		for j: int in 3:
			var y0: float = 1.24 + float(j) * 0.36
			mb.box("Dark", Vector3(sx * (ar + 0.16), y0 + 0.17, zc - 0.05), Vector3(0.34 + 0.06 * float(j % 2), 0.33, 0.14))
	for i: int in 9:
		var a0: float = PI * float(i) / 9.0 + 0.02
		var a1: float = PI * float(i + 1) / 9.0 - 0.02
		var r0: float = ar
		var r1: float = ar + 0.32 + (0.14 if i == 4 else 0.0)
		var p: Array[Vector3] = []
		for bit: int in 8:
			var a: float = a1 if (bit & 1) != 0 else a0
			var r: float = r1 if (bit & 2) != 0 else r0
			var z: float = zc - 0.14 if (bit & 4) != 0 else zc + 0.02
			p.append(Vector3(cos(a) * r, spring + sin(a) * r, z))
		mb.hexa("Dark", p)
	var ks := Vector3(0, spring + ar + 0.22, zc - 0.16)
	var gem: Array[Vector3] = [ks + Vector3(0, 0.13, 0), ks + Vector3(0.1, 0, 0), ks + Vector3(0, -0.13, 0), ks + Vector3(-0.1, 0, 0)]
	for i: int in 4:
		mb.tri_auto("Gate", gem[i], gem[(i + 1) % 4], ks + Vector3(0, 0, -0.07), ks + Vector3(0, 0, 0.1))
	# The dark doorway and a curtain of glowing hanging vines inside it (the training flash point).
	var door: Array[Vector3] = [Vector3(-ar, 1.24, zc - 0.005), Vector3(ar, 1.24, zc - 0.005)]
	for i: int in 11:
		var a: float = PI * float(i) / 10.0
		door.append(Vector3(cos(a) * ar, spring + sin(a) * ar, zc - 0.005))
	mb.poly("Black", door, Vector3(0, 2.0, 0))
	for i: int in 6:
		var x: float = -0.5 + 0.2 * float(i)
		var top: float = spring + sqrt(maxf(ar * ar - x * x, 0.0)) - 0.04
		var bottom: float = lerpf(1.55, 2.2, absf(sin(float(i) * 1.7)))
		mb.box("Gate", Vector3(x, (top + bottom) * 0.5, zc - 0.03), Vector3(0.05, top - bottom, 0.04))
		mb.box("Gate", Vector3(x + 0.03, bottom + 0.05, zc - 0.04), Vector3(0.11, 0.11, 0.05), Basis(Vector3.BACK, PI * 0.25))
	# Wooden banner rods (with brackets) under the parapet of the three banner faces.
	for deg: float in BANNER_SIDES:
		var out: Vector3 = dir_deg(deg)
		var tng := Vector3(-out.z, 0, out.x)
		var yaw: float = -deg_to_rad(deg)
		mb.box("Wood", out * 2.76 + Vector3(0, 3.44, 0), Vector3(1.5, 0.11, 0.11), Basis(Vector3.UP, yaw))
		for o: float in [-0.55, 0.55]:
			mb.box("Dark", out * 2.6 + tng * o + Vector3(0, 3.44, 0), Vector3(0.12, 0.14, 0.4), Basis(Vector3.UP, yaw))
	# Gate standards: gnarled wooden poles with a crossbar, two curled fronds and a glowing bud on top.
	for i: int in STANDARDS.size():
		var b: Vector3 = STANDARDS[i]
		var sgn: float = signf(b.x)
		var pts: Array[Vector3] = [b, b + Vector3(0.04 * sgn, 1.3, 0.02), b + Vector3(-0.03 * sgn, 2.6, -0.02),
			b + Vector3(0.03 * sgn, 3.9, 0.02), b + Vector3(0.0, 4.9, 0.0), b + Vector3(0.0, 5.25, 0.0)]
		mb.tube("Wood", pts, [0.14, 0.125, 0.115, 0.1, 0.08, 0.05] as Array[float], 7, 1.0, 0.1, float(i) * 3.0, false, true)
		var face: Vector3 = _standard_facing(i)
		var bar_dir := Vector3(-face.z, 0, face.x)
		mb.box("Wood", b + Vector3(0, 4.62, 0) + face * 0.1, Vector3(1.25, 0.1, 0.1), Basis(bar_dir, Vector3.UP, face))
		for sd: float in [-1.0, 1.0]:
			var c0: Vector3 = b + Vector3(0, 5.0, 0)
			var o: Vector3 = bar_dir * sd
			var fr: Array[Vector3] = [c0, c0 + o * 0.28 + Vector3(0, 0.28, 0), c0 + o * 0.42 + Vector3(0, 0.62, 0),
				c0 + o * 0.28 + Vector3(0, 0.84, 0), c0 + o * 0.14 + Vector3(0, 0.72, 0)]
			mb.tube("Wood", fr, [0.07, 0.06, 0.05, 0.04, 0.03] as Array[float], 5, 1.0)
		var bud: Vector3 = b + Vector3(0, 5.42, 0)
		var eq: Array = ring_n(5, 0.16)
		for k: int in 5:
			var q0: Vector2 = eq[k]
			var q1: Vector2 = eq[(k + 1) % 5]
			var e0: Vector3 = bud + Vector3(q0.x, 0, q0.y)
			var e1: Vector3 = bud + Vector3(q1.x, 0, q1.y)
			mb.tri_auto("Gate", e0, e1, bud + Vector3(0, 0.34, 0), bud)
			mb.tri_auto("Gate", e1, e0, bud + Vector3(0, -0.16, 0), bud)
	_mesh_node(mb, "Rampart", model, 0.9, 3.4)


## Which way gate standard i's banner faces (out of the gate, turned 40 deg outward).
static func _standard_facing(i: int) -> Vector3:
	var sgn: float = signf(STANDARDS[i].x)
	return Vector3(sin(deg_to_rad(40.0)) * sgn, 0, -cos(deg_to_rad(40.0)))


static func _near_root(deg: float, tol: float) -> bool:
	for r: Vector2 in ROOTS:
		if absf(wrapf(deg - r.x, -180.0, 180.0)) < tol:
			return true
	return false


# ============================================================ trunk, roots, limbs, gallery

## Root path: out of the trunk, over the parapet, down the battered wall, over both plinth steps, into the ground.
func _root(mb: MB, deg: float, size: float, seed: float) -> void:
	var prof: Array = [[1.0, 4.35, 0.66], [1.75, 4.62, 0.6], [2.3, 4.5, 0.53], [2.86, 4.05, 0.49],
		[2.97, 3.2, 0.46], [2.98, 2.1, 0.43], [3.07, 1.15, 0.39], [3.36, 0.74, 0.34], [3.6, 0.22, 0.27],
		[3.85, -0.25, 0.18]]
	var pts: Array[Vector3] = []
	var rad: Array[float] = []
	for i: int in prof.size():
		var s: Array = prof[i]
		var wob: float = sin(float(i) * 1.3 + seed) * 4.0 + sin(float(i) * 2.9 + seed * 2.0) * 2.0
		var d: Vector3 = dir_deg(deg + wob)
		var r: float = s[0]
		var rr: float = s[2] * lerpf(1.0, size, clampf(float(i) / 3.0, 0.0, 1.0))
		# Thinner roots hug the wall more closely.
		if i >= 3:
			r -= (s[2] - rr) * 0.85
		pts.append(d * r + Vector3(0, s[1], 0))
		rad.append(rr)
	mb.tube("Bark", pts, rad, 7, 2.0, 0.07, seed, false, false)


## Strand k of the braided trunk (full path, y TRUNK_BASE .. TRUNK_TOP) and its radii.
func _strand(k: int) -> Array:
	var phase: float = deg_to_rad(120.0 * float(k) + 25.0)
	var pts: Array[Vector3] = []
	var rad: Array[float] = []
	var n: int = 14
	for i: int in n + 1:
		var t: float = float(i) / float(n)
		var y: float = lerpf(TRUNK_BASE, TRUNK_TOP, t)
		var a: float = phase + deg_to_rad(130.0) * t
		var flare: float = 0.45 * (1.0 - smoothstep(0.0, 0.25, t))
		var off: float = lerpf(0.95, 0.4, pow(t, 0.8)) + flare * 0.5 + 0.08 * sin(t * 7.0 + float(k))
		pts.append(Vector3(sin(a) * off, y, -cos(a) * off))
		rad.append(lerpf(1.02, 0.56, t) + flare)
	return [pts, rad]


## A limb from `start` to a clump centre (ending inside it), bending up then out.
func _limb(mb: MB, k: String, start: Vector3, target: Vector3, r0: float, r1: float, seed: float) -> void:
	var mid1: Vector3 = start.lerp(target, 0.35) + Vector3(0, 0.55, 0)
	var mid2: Vector3 = start.lerp(target, 0.7) + Vector3(0, 0.3, 0)
	var pts: Array[Vector3] = [start, mid1, mid2, target]
	mb.tube(k, pts, [r0, lerpf(r0, r1, 0.4), lerpf(r0, r1, 0.75), r1] as Array[float], 8, 1.0, 0.06, seed, false, true)


func _build_trunk() -> void:
	var split: float = KeepScript.SPLIT_Y
	var low := MB.new()
	var high := MB.new()
	# Roots (they stay with the stump when the crown falls).
	for i: int in ROOTS.size():
		_root(low, ROOTS[i].x, ROOTS[i].y, float(i) * 2.3)
	# Surface roots at ground level between the big ones, crawling off the plinth into the moss.
	for i: int in 6:
		var deg: float = 15.0 + 60.0 * float(i) + rng.randf_range(-8.0, 8.0)
		if absf(wrapf(deg, -180.0, 180.0)) < 30.0:
			deg += 40.0
		var d: Vector3 = dir_deg(deg)
		var side: Vector3 = Vector3(-d.z, 0, d.x) * rng.randf_range(-0.4, 0.4)
		var pts: Array[Vector3] = [d * 3.0 + Vector3(0, 0.62, 0), d * 3.35 + Vector3(0, 0.45, 0) + side * 0.3,
			d * 3.9 + Vector3(0, 0.08, 0) + side, d * 4.5 + Vector3(0, -0.08, 0) + side * 1.4]
		low.tube("Bark", pts, [0.2, 0.17, 0.12, 0.05] as Array[float], 6, 1.0, 0.05, float(i))
	# Braided trunk: three strands twisting 130 deg around a core, split into the stump part and the crown part.
	var limb_targets: Array[int] = [3, 1, 5]
	for k: int in 3:
		var sr: Array = _strand(k)
		var pts: Array[Vector3] = sr[0]
		var rad: Array[float] = sr[1]
		var lp: Array[Vector3] = []
		var lr: Array[float] = []
		var hp: Array[Vector3] = []
		var hr: Array[float] = []
		for i: int in pts.size():
			if pts[i].y <= split + 0.3:
				lp.append(pts[i])
				lr.append(rad[i])
			if pts[i].y >= split - 0.3:
				hp.append(pts[i])
				hr.append(rad[i])
		low.tube("Bark", lp, lr, 10, 3.0, 0.08, float(k) * 1.7, false, true)
		# The strand leaves the trunk top as a limb into its clump.
		var last: Vector3 = hp[hp.size() - 1]
		var ci: int = limb_targets[k]
		var target: Vector3 = clump_center(ci) - Vector3(0, CLUMPS[ci].w * 0.2, 0)
		hp.append(last.lerp(target, 0.4) + Vector3(0, 0.7, 0))
		hr.append(0.46)
		hp.append(last.lerp(target, 0.78) + Vector3(0, 0.35, 0))
		hr.append(0.36)
		hp.append(target)
		hr.append(0.24)
		high.tube("Bark", hp, hr, 10, 3.0, 0.08, float(k) * 1.7, false, true)
	# Core (fills the braid).
	low.tube("Bark", [Vector3(0, TRUNK_BASE, 0), Vector3(0.05, 4.4, 0.0), Vector3(0.0, split + 0.3, 0.05)] as Array[Vector3],
		[1.2, 1.0, 0.9] as Array[float], 12, 3.0, 0.05, 0.4, false, true)
	high.tube("Bark", [Vector3(0.0, split - 0.3, 0.05), Vector3(-0.05, 8.6, 0.0), Vector3(0.0, 11.0, 0.05)] as Array[Vector3],
		[0.9, 0.78, 0.6] as Array[float], 12, 3.0, 0.05, 0.9, false, true)
	# Heart knot on the gate side above the portal: a bark burl ring around a glowing seed.
	var kc := Vector3(0, 5.25, -1.28)
	var ring: Array[Vector3] = []
	var rr: Array[float] = []
	for i: int in 13:
		var a: float = TAU * float(i) / 12.0
		ring.append(kc + Vector3(cos(a) * 0.62, sin(a) * 0.72, -0.05 + 0.06 * sin(a * 2.0)))
		rr.append(0.2 + 0.05 * sin(a * 3.0))
	low.tube("Bark", ring, rr, 8, 1.0, 0.0, 0.0, false, false)
	var knot := _sphere_into(low, "Heart", kc + Vector3(0, 0, -0.08), 0.5, 1.0)
	# Other limbs from the top of the core: the crown clump, the other ring clumps, the upper fill clumps.
	var top := Vector3(0, 10.6, 0)
	_limb(high, "Bark", top, clump_center(0) - Vector3(0, 0.6, 0), 0.55, 0.3, 1.0)
	for ci: int in [2, 4, 6, 7, 8]:
		var start: Vector3 = top + Vector3(0, -0.6 + 0.3 * float(ci % 3), 0) + dir_deg(CLUMPS[ci].x) * 0.2
		_limb(high, "Bark", start, clump_center(ci) - Vector3(0, CLUMPS[ci].w * 0.2, 0), 0.42, 0.22, float(ci))
	# The low bough: the asymmetric second mass, reaching out over the -X / +Z side.
	var bd: Vector3 = dir_deg(CLUMPS[9].x)
	var bough: Array[Vector3] = [bd * 0.35 + Vector3(0, 6.7, 0), bd * 1.15 + Vector3(0, 7.25, 0), bd * 1.9 + Vector3(0, 7.7, 0),
		clump_center(9) - Vector3(0, 0.25, 0)]
	high.tube("Bark", bough, [0.5, 0.42, 0.33, 0.22] as Array[float], 9, 2.0, 0.08, 5.0, false, true)
	# Bare twigs poking out of the crown (silhouette detail).
	for i: int in 6:
		var d: Vector3 = dir_deg(30.0 + 60.0 * float(i) + rng.randf_range(-12.0, 12.0))
		var s: Vector3 = d * 1.4 + Vector3(0, 12.8 + rng.randf_range(0.0, 1.2), 0)
		var e: Vector3 = d * rng.randf_range(3.3, 4.0) + Vector3(0, 14.2 + rng.randf_range(0.0, 1.4), 0)
		high.tube("Bark", [s, s.lerp(e, 0.5) + Vector3(0, 0.25, 0), e] as Array[Vector3],
			[0.13, 0.08, 0.02] as Array[float], 5, 1.0)
	# The gallery: a wooden walk around the trunk at y 6.9 on four struts, a low branch rail on six stubby posts.
	var gy: float = 6.9
	var deck: Array = []
	for i: int in 12:
		var a: float = TAU * float(i) / 12.0 + 0.1
		var dr: float = 1.72 + 0.08 * sin(float(i) * 2.3)
		deck.append(Vector2(cos(a) * dr, -sin(a) * dr))
	var deck_in: Array = ring_n(12, 0.95, 0.1)
	high.loft("Wood", [deck, deck], [gy - 0.14, gy], false)
	high.annulus("Wood", deck, deck_in, gy)
	high.flip = true
	high.annulus("Wood", deck, deck_in, gy - 0.14)
	high.flip = false
	var posts: Array[Vector3] = []
	for i: int in 6:
		var q: Vector2 = deck[i * 2]
		var p := Vector3(q.x * 0.95, gy, q.y * 0.95)
		posts.append(p)
		high.tube("Wood", [p, p + Vector3(0, 0.46, 0)] as Array[Vector3], [0.07, 0.055] as Array[float], 5, 1.0)
	var rail: Array[Vector3] = []
	var rail_r: Array[float] = []
	for i: int in 13:
		var a0: Vector3 = posts[(i / 2) % 6]
		var a1: Vector3 = posts[((i / 2) + 1) % 6]
		var q: Vector3 = a0 if i % 2 == 0 else a0.lerp(a1, 0.5) - Vector3(0, 0.06, 0)
		rail.append(q + Vector3(0, 0.44, 0))
		rail_r.append(0.055)
	high.tube("Wood", rail, rail_r, 5, 1.0, 0.1, 0.0, false, false)
	for i: int in 4:
		var d: Vector3 = dir_deg(45.0 + 90.0 * float(i))
		high.tube("Wood", [d * 0.8 + Vector3(0, gy - 1.3, 0), d * 1.25 + Vector3(0, gy - 0.6, 0), d * 1.6 + Vector3(0, gy - 0.12, 0)] as Array[Vector3],
			[0.12, 0.1, 0.08] as Array[float], 6, 1.0)
	_mesh_node(low, "TrunkLow", model, 0.0, 10.0)
	_mesh_node(high, "TrunkHigh", model, 0.0, 12.0)
	# The heart knot's surface belongs to TrunkLow; keep its centre for the script.
	keep.set(&"knot_position", knot)


## A low-poly sphere (UV sphere, 10 x 6) of material k at c; returns c.
func _sphere_into(mb: MB, k: String, c: Vector3, r: float, sy: float, seg: int = 12, rings: int = 7) -> Vector3:
	var prev: Array = []
	for i: int in rings + 1:
		var th: float = PI * float(i) / float(rings)
		var row: Array = []
		for j: int in seg + 1:
			var ph: float = TAU * float(j) / float(seg)
			var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
			row.append(d)
		if i > 0:
			for j: int in seg:
				var a: Vector3 = prev[j]
				var b: Vector3 = prev[j + 1]
				var cc: Vector3 = row[j + 1]
				var d: Vector3 = row[j]
				var sc := Vector3(r, r * sy, r)
				mb.tri_s(k, c + a * sc, c + b * sc, c + cc * sc, a, b, cc, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
				mb.tri_s(k, c + a * sc, c + cc * sc, c + d * sc, a, cc, d, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		prev = row
	return c


# ============================================================ canopy

## Lumpy foliage clump: an icosphere (subdivided `sub` times) pushed out by gaussian bumps, flatter underneath.
class Blob:
	var c: Vector3
	var r: float
	var sq_top: float
	var sq_bot: float
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
		return c + p


func _make_blob(i: int) -> Blob:
	var b := Blob.new()
	b.c = clump_center(i)
	b.r = CLUMPS[i].w
	b.sq_top = CLUMP_SQUASH[i]
	b.sq_bot = CLUMP_SQUASH[i] * 0.78
	var outward: Vector3 = (b.c - Vector3(0, b.c.y, 0)).normalized() if i != 0 else Vector3.UP
	for k: int in 13:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1.0), rng.randf_range(-1, 1)).normalized()
		if i == 0:
			# The crown clump keeps a calm top (the Crown Bloom sits there): lumps around its shoulders.
			d = Vector3(d.x, clampf(d.y, -0.2, 0.55), d.z).normalized()
		else:
			d = (d + outward * 0.35).normalized()
		b.bump_dirs.append(d)
		b.bump_amp.append(rng.randf_range(0.06, 0.14))
		b.bump_sharp.append(rng.randf_range(5.0, 10.0))
	return b


func _blob_mesh(mb: MB, b: Blob, sub: int, id: float, others: Array = []) -> void:
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
	# Smooth normals from the faces, softened toward the radial direction (a painterly volume).
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
		var ao: float = _canopy_ao(pos[i], b, others)
		aoc.append(Color(ao, ao, ao, 1.0))
	var u2 := Vector2(id, 0)
	for f: Array in faces:
		mb.tri_sc("Leaves", pos[f[0]], pos[f[1]], pos[f[2]], nrm[f[0]], nrm[f[1]], nrm[f[2]],
			Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, u2, aoc[f[0]], aoc[f[1]], aoc[f[2]])


## Baked occlusion of a canopy point by the other clumps (dark crevices where clumps meet), 0.3 .. 1.
func _canopy_ao(p: Vector3, self_b: Blob, others: Array) -> float:
	var ao: float = 1.0
	for o: Blob in others:
		if o == self_b:
			continue
		var d: Vector3 = p - o.c
		d.y /= o.sq_top if d.y > 0.0 else o.sq_bot
		var k: float = d.length() / (o.r * 0.95)
		ao *= 1.0 - 0.62 * (1.0 - smoothstep(0.92, 1.6, k))
	return clampf(ao, 0.3, 1.0)


## Leaf cards around a clump: hanging along its lower rim and sides, a few sticking up on top; blossoms on top.
func _clump_cards(mb: MB, b: Blob, n_leaves: int, n_blossoms: int, others: Array = []) -> void:
	for i: int in n_leaves:
		var up_bias: bool = i % 5 == 0
		var y: float = rng.randf_range(0.35, 0.8) if up_bias else rng.randf_range(-0.6, 0.25)
		var a: float = rng.randf() * TAU
		var d := Vector3(cos(a) * sqrt(1.0 - y * y), y, sin(a) * sqrt(1.0 - y * y))
		var p: Vector3 = b.point(d)
		var outward: Vector3 = (p - b.c).normalized()
		var horiz := Vector3(outward.x, 0, outward.z).normalized()
		var side: Vector3 = Vector3.UP.cross(horiz).normalized()
		var s: float = rng.randf_range(0.8, 1.15)
		var dir: Vector3
		if up_bias:
			dir = (outward + Vector3.UP * 0.5).normalized()
		else:
			dir = (horiz * 0.75 + Vector3.DOWN * rng.randf_range(0.4, 0.9)).normalized()
		side = side.rotated(dir, rng.randf_range(-0.5, 0.5))
		var h: float = 0.85 * s
		var bend: Vector3 = (dir + Vector3.DOWN * 0.45).normalized()
		var start: Vector3 = p - outward * 0.12
		var pts: Array[Vector3] = [start, start + dir * h * 0.5, start + dir * h * 0.5 + bend * h * 0.5]
		var nn: Vector3 = (outward + Vector3.UP * 0.35).normalized()
		var ao: float = _canopy_ao(p, b, others)
		mb.col = Color(ao, ao, ao, 1.0)
		mb.strip("LeafCard", pts, side, 0.5 * s, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())
	for i: int in n_blossoms:
		var y: float = rng.randf_range(0.3, 0.95)
		var a: float = rng.randf() * TAU
		var d := Vector3(cos(a) * sqrt(1.0 - y * y), y, sin(a) * sqrt(1.0 - y * y))
		var p: Vector3 = b.point(d)
		var outward: Vector3 = (p - b.c).normalized()
		var t1: Vector3 = outward.cross(Vector3.RIGHT if absf(outward.x) < 0.9 else Vector3.FORWARD).normalized()
		var s: float = rng.randf_range(0.5, 0.72)
		var start: Vector3 = p + outward * 0.06 - t1 * s * 0.5
		var nn: Vector3 = (outward + Vector3.UP * 0.5).normalized()
		var ao: float = _canopy_ao(p, b, others)
		mb.col = Color(ao, ao, ao, 1.0)
		mb.strip("Blossom", [start, start + t1 * s] as Array[Vector3], outward.cross(t1), s,
			[nn, nn] as Array[Vector3], rng.randf(), rng.randf())


func _build_canopy() -> void:
	var pivot: Vector3 = KeepScript.CANOPY_PIVOT
	var main := MB.new()
	var lost := MB.new()
	main.xf = Transform3D(Basis.IDENTITY, -pivot)
	lost.xf = Transform3D(Basis.IDENTITY, -pivot)
	var blobs: Array = []
	for i: int in CLUMPS.size():
		blobs.append(_make_blob(i))
	for i: int in CLUMPS.size():
		var b: Blob = blobs[i]
		if i == 0:
			bloom_pos = b.point(Vector3.UP) - Vector3(0, 0.3, 0)
		var mb: MB = lost if i in LOST_CLUMPS else main
		_blob_mesh(mb, b, 3 if i == 0 else 2, float(i) / 10.0, blobs)
		var n_leaves: int = int(8.0 + CLUMPS[i].w * 8.0)
		var n_bl: int = int(CLUMPS[i].w * 2.5) + (4 if i == 0 else 0)
		_clump_cards(mb, b, n_leaves, n_bl, blobs)
		mb.col = Color.WHITE
	# Hanging moss beards under the ring clumps.
	for i: int in 9:
		var ci: int = 1 + (i % 6)
		var c: Vector3 = clump_center(ci)
		var d: Vector3 = dir_deg(CLUMPS[ci].x + rng.randf_range(-50.0, 50.0))
		var p: Vector3 = c + d * CLUMPS[ci].w * rng.randf_range(0.3, 0.7) - Vector3(0, CLUMPS[ci].w * 0.35, 0)
		var l: float = rng.randf_range(1.2, 2.2)
		var sw: Vector3 = d * 0.15
		var mb: MB = lost if ci in LOST_CLUMPS else main
		mb.tube("Bark", [p, p + sw - Vector3(0, l * 0.5, 0), p - sw * 0.5 - Vector3(0, l, 0)] as Array[Vector3],
			[0.09, 0.06, 0.015] as Array[float], 5, 1.0, 0.15, float(i))
	_mesh_node(main, "Canopy", model, 8.0, 7.5, true, pivot)
	_mesh_node(lost, "CanopyLost", model, 8.0, 7.5, true, pivot)


# ============================================================ crown bloom

func _build_bloom() -> void:
	var mb := MB.new()
	# A collar of big leaves under the flower ties it to the canopy.
	for i: int in 7:
		var a: float = TAU * float(i) / 7.0
		var d := Vector3(cos(a), 0, sin(a))
		var pts: Array[Vector3] = [d * 0.3 + Vector3(0, 0.05, 0), d * 1.1 + Vector3(0, 0.15, 0), d * 1.9 + Vector3(0, -0.1, 0)]
		var nn := Vector3.UP
		mb.strip("LeafCard", pts, Vector3(-d.z, 0, d.x), 0.95, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())
	# Outer petals: a wide cup; inner petals: shorter and more upright, turned half a step.
	for ring: int in 2:
		var count: int = 8 if ring == 0 else 6
		var length: float = 2.3 if ring == 0 else 1.45
		var width: float = 1.25 if ring == 0 else 0.82
		var lift: float = 0.5 if ring == 0 else 1.0
		for i: int in count:
			var a: float = TAU * (float(i) + 0.5 * float(ring)) / float(count) + 0.2
			var d := Vector3(cos(a), 0, sin(a))
			var side := Vector3(-d.z, 0, d.x)
			var pts: Array[Vector3] = []
			var nrms: Array[Vector3] = []
			for s: int in 5:
				var t: float = float(s) / 4.0
				# Rises steeply, then curls outward at the tip.
				var out: float = length * (0.18 + t * 0.82) * (1.0 - 0.15 * t * t) * (1.0 if ring == 0 else 0.7)
				var up: float = length * (lift * t - 0.25 * t * t * (1.0 if ring == 0 else 0.3))
				pts.append(d * out + Vector3(0, up + 0.05 * float(ring), 0))
				nrms.append((Vector3.UP * 0.8 - d * 0.35 + d * t * 0.6).normalized())
			mb.strip("Petal", pts, side, width, nrms, float(i + ring * 7) / 14.0, rng.randf())
	# The seed at the heart of the bloom and six glowing stamens around it.
	_sphere_into(mb, "Heart", Vector3(0, 0.48, 0), 0.52, 1.1)
	for i: int in 7:
		var a: float = TAU * float(i) / 7.0 + 0.3
		var d := Vector3(cos(a), 0, sin(a))
		var tip: Vector3 = d * 0.6 + Vector3(0, 1.3, 0)
		mb.tube("Heart", [d * 0.25 + Vector3(0, 0.5, 0), d * 0.4 + Vector3(0, 1.0, 0), tip] as Array[Vector3],
			[0.045, 0.04, 0.03] as Array[float], 4, 1.0)
		_sphere_into(mb, "Heart", tip + Vector3(0, 0.06, 0), 0.11, 1.0, 6, 4)
	_mesh_node(mb, "Bloom", model, 0.0, 1.0, false, bloom_pos)


# ============================================================ seed-lanterns

func _build_lanterns() -> void:
	var lant: Node3D = _add(Node3D.new(), model, "Lanterns")
	for i: int in 3:
		var pv: Node3D = _add(Node3D.new(), lant, "Lantern%d" % i)
		pv.position = lantern_pivot(i)
		var mb := MB.new()
		var vlen: float = LANTERN_DROP[i]
		var sway := Vector3(0.12, 0, 0.08) * (1.0 if i % 2 == 0 else -1.0)
		mb.tube("Bark", [Vector3.ZERO, sway - Vector3(0, vlen * 0.5, 0), Vector3(0, -vlen, 0)] as Array[Vector3],
			[0.06, 0.05, 0.045] as Array[float], 5, 1.0)
		# Calyx: a bark cup with five pointed sepals hugging the top of the pod.
		var top := Vector3(0, -vlen, 0)
		mb.loft("Bark", [ring_n(7, 0.08), ring_n(7, 0.3)], [top.y + 0.05, top.y - 0.14], false)
		for k: int in 5:
			var a: float = TAU * float(k) / 5.0
			var d := Vector3(cos(a), 0, sin(a))
			var s := Vector3(-d.z, 0, d.x)
			var b0: Vector3 = top + d * 0.26 + Vector3(0, -0.12, 0)
			mb.tri_auto("Bark", b0 - s * 0.12, b0 + s * 0.12, b0 + d * 0.12 + Vector3(0, -0.36, 0), top + Vector3(0, -0.5, 0))
		# The glowing seed pod (teardrop).
		var prof: Array = [[0.02, -0.02], [0.24, -0.14], [0.39, -0.34], [0.43, -0.57], [0.36, -0.8], [0.19, -0.98], [0.02, -1.08]]
		var rings: Array = []
		var ys: Array = []
		for pp: Array in prof:
			rings.append(ring_n(10, pp[0]))
			ys.append(top.y + float(pp[1]))
		mb.loft("Pod", rings, ys, true, true)
		var mi: MeshInstance3D = _mesh_node_mat(mb, "Pod", pv, {"Bark": mats["Bark"], "Pod": mats["Lantern"]})
		mi.set_instance_shader_parameter(&"ao_bottom", 7.0)
		mi.set_instance_shader_parameter(&"ao_height", 5.0)
		mi.set_instance_shader_parameter(&"energy", 1.5)
		mi.set_instance_shader_parameter(&"pulse_speed", 2.0)
		mi.set_instance_shader_parameter(&"phase", float(i) * 2.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _mesh_node_mat(mb: MB, nm: String, parent: Node3D, m: Dictionary) -> MeshInstance3D:
	var res: Array = mb.commit(m)
	var mi := MeshInstance3D.new()
	mi.mesh = res[0]
	_add(mi, parent, nm)
	var used: Array[Material] = res[1]
	for i: int in used.size():
		mi.set_surface_override_material(i, used[i])
	return mi


# ============================================================ banners

func _banner(mb: MB, top_center: Vector3, out: Vector3, w: float, h: float, phase: float) -> void:
	var tng := Vector3(out.z, 0, -out.x)
	var nx: int = 3
	var ny: int = 10
	for i: int in nx:
		for j: int in ny:
			var u0: float = float(i) / nx
			var u1: float = float(i + 1) / nx
			var v0: float = float(j) / ny
			var v1: float = float(j + 1) / ny
			var p := func(u: float, v: float) -> Vector3:
				return top_center + tng * (u - 0.5) * w - Vector3(0, v * h, 0)
			mb.quad("Banner", p.call(u0, v0), p.call(u1, v0), p.call(u1, v1), p.call(u0, v1),
				Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1),
				top_center - out * 1.0 - Vector3(0, h * 0.5, 0), Vector2(phase, 0))


func _build_banners() -> void:
	var gate := MB.new()
	for i: int in STANDARDS.size():
		var face: Vector3 = _standard_facing(i)
		_banner(gate, STANDARDS[i] + Vector3(0, 4.56, 0) + face * 0.17, face, 1.05, 2.7, 1.9 * float(i))
	var side := MB.new()
	var ph: float = 3.4
	for deg: float in BANNER_SIDES:
		var out: Vector3 = dir_deg(deg)
		_banner(side, out * 2.85 + Vector3(0, 3.38, 0), out, 1.25, 2.35, ph)
		ph += 1.7
	_mesh_node(gate, "BannersGate", model, 0.0, 1.0, false)
	_mesh_node(side, "BannersSide", model, 0.0, 1.0, false)


# ============================================================ state meshes (hidden until needed)

func _build_state_meshes() -> void:
	var split: float = KeepScript.SPLIT_Y
	# Stump: the jagged broken top of the trunk and its pale heartwood, shown when the crown falls.
	var st := MB.new()
	st.loft("Wood", [ring_n(12, 1.45), ring_n(12, 1.35)], [split - 0.15, split + 0.05], true)
	for i: int in 11:
		var a: float = TAU * float(i) / 11.0 + rng.randf_range(-0.1, 0.1)
		var d := Vector3(cos(a), 0, sin(a))
		var r: float = rng.randf_range(1.0, 1.45)
		var h: float = rng.randf_range(0.5, 1.7)
		var b: Vector3 = d * r + Vector3(0, split - 0.1, 0)
		st.tube("Bark", [b, b + d * 0.12 + Vector3(0, h * 0.6, 0), b + d * 0.2 + Vector3(0, h, 0)] as Array[Vector3],
			[rng.randf_range(0.2, 0.3), 0.14, 0.0] as Array[float], 5, 1.0, 0.0, 0.0, false, false)
	var stump: MeshInstance3D = _mesh_node(st, "Stump", model, 0.0, 8.0)
	stump.visible = false
	# Rubble2 (< 50 % HP): a torn-off limb with its leaf clump lying at the +X / +Z corner, and bark chips.
	var r2 := MB.new()
	var limb: Array[Vector3] = [Vector3(2.4, 0.35, 3.3), Vector3(3.3, 0.45, 3.9), Vector3(4.2, 0.4, 4.3), Vector3(4.9, 0.55, 4.5)]
	r2.tube("Bark", limb, [0.32, 0.28, 0.22, 0.15] as Array[float], 8, 2.0, 0.08, 3.0, true, true)
	var lb := Blob.new()
	lb.c = Vector3(5.0, 0.55, 4.6)
	lb.r = 1.0
	lb.sq_top = 0.6
	lb.sq_bot = 0.35
	for k: int in 5:
		lb.bump_dirs.append(Vector3(rng.randf_range(-1, 1), rng.randf_range(0, 1), rng.randf_range(-1, 1)).normalized())
		lb.bump_amp.append(0.18)
		lb.bump_sharp.append(6.0)
	_blob_mesh(r2, lb, 2, 0.95)
	for i: int in 7:
		var p := Vector3(rng.randf_range(2.8, 4.8), 0.08, rng.randf_range(2.9, 4.8))
		r2.box("Bark", p, Vector3(0.5, 0.16, 0.2), Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(0.1, 0.3)))
	var rb2: MeshInstance3D = _mesh_node(r2, "Rubble2", model, 0.0, 2.0)
	rb2.visible = false
	# Debris (the wreck): the fallen crown's withered remains lying behind the stump (+Z).
	var db := MB.new()
	for i: int in 4:
		var c := Vector3(rng.randf_range(-2.4, 2.4), 0.4, rng.randf_range(4.0, 6.2))
		var bl := Blob.new()
		bl.c = c
		bl.r = rng.randf_range(0.9, 1.3)
		bl.sq_top = 0.55
		bl.sq_bot = 0.3
		for k: int in 5:
			bl.bump_dirs.append(Vector3(rng.randf_range(-1, 1), rng.randf_range(0, 1), rng.randf_range(-1, 1)).normalized())
			bl.bump_amp.append(0.2)
			bl.bump_sharp.append(6.0)
		_blob_mesh(db, bl, 2, 0.9)
	for i: int in 3:
		var s := Vector3(rng.randf_range(-1.2, 1.2), 0.45, 2.9 + float(i) * 0.4)
		var e: Vector3 = s + Vector3(rng.randf_range(-2.5, 2.5), 0.0, rng.randf_range(2.0, 3.5))
		db.tube("Bark", [s, s.lerp(e, 0.5) + Vector3(0, 0.1, 0), e] as Array[Vector3], [0.45, 0.35, 0.2] as Array[float], 8, 2.0, 0.08, float(i), true, true)
	var deb: MeshInstance3D = _mesh_node(db, "Debris", model, 0.0, 2.0)
	deb.visible = false
	# Construction outline: a glowing chamfered ring on the ground around the plinth (not under Model).
	var ol := MB.new()
	var outer: Array = chamfer(3.62, 1.1)
	var inner: Array = chamfer(3.42, 1.04)
	ol.annulus("Outline", outer, inner, 0.0)
	var o: MeshInstance3D = _mesh_node_mat(ol, "Outline", keep, {"Outline": mats["Outline"]})
	o.position = Vector3(0, 0.06, 0)
	o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	o.set_instance_shader_parameter(&"energy", 2.0)
	o.set_instance_shader_parameter(&"pulse_speed", TAU)
	o.visible = false


# ============================================================ ground

func _build_ground() -> void:
	var decal := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(13, 13)
	decal.mesh = pm
	decal.material_override = mats["Ground"]
	decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decal.position = Vector3(0, 0.03, 0)
	_add(decal, keep, "ContactDecal")
	# Mossy boulders, fern tufts and glowing mushroom clusters around the plinth (one mesh, at the root).
	var mb := MB.new()
	var placed: int = 0
	var tries: int = 0
	while placed < 10 and tries < 300:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(3.7, 4.7)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if _blocked(p):
			continue
		placed += 1
		var s: float = rng.randf_range(0.3, 0.55)
		var hgt: float = rng.randf_range(0.25, 0.6)
		mb.xf = Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(0.05, 0.3)), p)
		mb.loft("Dark", [ring_n(6, s, rng.randf()), ring_n(6, s * 0.72, rng.randf())], [-0.15, hgt], true)
	mb.xf = Transform3D.IDENTITY
	placed = 0
	tries = 0
	while placed < 8 and tries < 300:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(3.5, 4.4)
		var p := Vector3(cos(a) * r, 0.02, sin(a) * r)
		if _blocked(p):
			continue
		placed += 1
		for f: int in 6:
			var fa: float = TAU * float(f) / 6.0 + rng.randf() * 0.5
			var d := Vector3(cos(fa), 0, sin(fa))
			var dir: Vector3 = (d * 0.6 + Vector3.UP * rng.randf_range(0.6, 1.0)).normalized()
			var side: Vector3 = d.cross(Vector3.UP).normalized()
			var h: float = rng.randf_range(0.6, 0.95)
			var bend: Vector3 = (dir + d * 0.8 + Vector3.DOWN * 0.3).normalized()
			var pts: Array[Vector3] = [p, p + dir * h * 0.55, p + dir * h * 0.55 + bend * h * 0.45]
			var nn: Vector3 = (Vector3.UP + d * 0.3).normalized()
			mb.strip("LeafCard", pts, side, 0.34, [nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())
	placed = 0
	tries = 0
	while placed < 4 and tries < 300:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(3.45, 4.1)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if _blocked(p):
			continue
		placed += 1
		for m: int in 3:
			var q: Vector3 = p + Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
			var h: float = rng.randf_range(0.25, 0.55)
			var cr: float = rng.randf_range(0.14, 0.24)
			mb.xf = Transform3D(Basis(Vector3.RIGHT, rng.randf_range(-0.2, 0.2)), q)
			mb.tube("Dark", [Vector3.ZERO, Vector3(0.03, h, 0)] as Array[Vector3], [0.06, 0.045] as Array[float], 5, 1.0)
			mb.loft("Gate", [ring_n(6, cr), ring_n(6, cr * 0.7), ring_n(6, 0.02)], [h - 0.04, h + 0.07, h + 0.14], false, true)
			mb.xf = Transform3D.IDENTITY
	_mesh_node(mb, "Rubble", keep, -0.3, 1.5, false)


## Keep the gate stairs and the standards clear of ground dressing.
static func _blocked(p: Vector3) -> bool:
	return p.z < -2.6 and absf(p.x) < 2.6


# ============================================================ lights and particles

func _build_lights_and_fx() -> void:
	var cl := OmniLight3D.new()
	cl.light_color = GLOW
	cl.light_energy = 1.6
	cl.light_specular = 0.2
	cl.omni_range = 11.0
	cl.position = Vector3(0, 8.4, 0)
	_add(cl, keep, "CrownLight")
	var gl := OmniLight3D.new()
	gl.light_color = GLOW
	gl.light_energy = 1.1
	gl.light_specular = 0.2
	gl.omni_range = 5.5
	gl.position = Vector3(0, 2.0, -3.9)
	_add(gl, keep, "GateLight")

	var soft: Texture2D = _radial()
	var leaf_tex: Texture2D = _shape_tex(0)
	var petal_tex: Texture2D = _shape_tex(1)
	var add_soft: QuadMesh = _quad(BaseMaterial3D.BLEND_MODE_ADD, soft, true)
	var mix_soft: QuadMesh = _quad(BaseMaterial3D.BLEND_MODE_MIX, soft, false)
	var mix_leaf: QuadMesh = _quad(BaseMaterial3D.BLEND_MODE_MIX, leaf_tex, false)
	var mix_petal: QuadMesh = _quad(BaseMaterial3D.BLEND_MODE_MIX, petal_tex, false)
	var glow_ramp := _ramp([0.0, 0.15, 0.7, 1.0], [Color(GLOW, 0.0), Color(GLOW, 1.0), Color(GLOW, 0.8), Color(GLOW, 0.0)], team_glow_ramps)

	# Idle (only near the camera, nature_keep.gd): pollen motes rising around the walls.
	var po := _pm(Vector3.UP, 25.0, 0.4, 0.9, Vector3.ZERO, 0.1, 0.05, glow_ramp)
	po.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	po.emission_ring_axis = Vector3.UP
	po.emission_ring_radius = 3.9
	po.emission_ring_inner_radius = 1.8
	po.emission_ring_height = 1.2
	po.orbit_velocity_min = 0.03
	po.orbit_velocity_max = 0.07
	po.turbulence_enabled = true
	po.turbulence_noise_strength = 0.3
	po.turbulence_noise_scale = 1.5
	_particles("Pollen", Vector3(0, 1.4, 0), 30, 6.0, po, add_soft, false)
	# Falling leaves from the canopy rim, tumbling.
	var leaf_ramp := _ramp([0.0, 0.08, 0.8, 1.0], [Color(TEAM, 0.0), Color(TEAM, 1.0), Color(TEAM.darkened(0.2), 1.0),
		Color(TEAM.darkened(0.3), 0.0)], team_leaf_ramps)
	var lv := _pm(Vector3.DOWN, 20.0, 0.6, 1.1, Vector3(0.3, -0.25, 0.1), 0.34, 0.3, leaf_ramp)
	lv.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	lv.emission_ring_axis = Vector3.UP
	lv.emission_ring_radius = 3.8
	lv.emission_ring_inner_radius = 1.8
	lv.emission_ring_height = 0.8
	lv.angle_min = 0.0
	lv.angle_max = 360.0
	lv.angular_velocity_min = -120.0
	lv.angular_velocity_max = 120.0
	lv.turbulence_enabled = true
	lv.turbulence_noise_strength = 0.6
	lv.turbulence_noise_scale = 2.0
	_particles("Leaves", Vector3(0, 11.2, 0), 14, 7.0, lv, mix_leaf, false)
	# Petals drifting off the Crown Bloom.
	var petal_ramp := _ramp([0.0, 0.1, 0.8, 1.0], [Color(0.98, 0.72, 0.84, 0.0), Color(0.98, 0.72, 0.84, 1.0),
		Color(0.95, 0.66, 0.8, 1.0), Color(0.95, 0.66, 0.8, 0.0)], [])
	var pe := _pm(Vector3(0.3, 1.0, 0.1), 60.0, 0.4, 0.9, Vector3(0.35, -0.35, 0.15), 0.22, 0.2, petal_ramp)
	pe.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pe.emission_sphere_radius = 0.9
	pe.angle_min = 0.0
	pe.angle_max = 360.0
	pe.angular_velocity_min = -160.0
	pe.angular_velocity_max = 160.0
	pe.turbulence_enabled = true
	pe.turbulence_noise_strength = 0.5
	pe.turbulence_noise_scale = 1.6
	_particles("Petals", bloom_pos + Vector3(0, 0.6, 0), 12, 6.0, pe, mix_petal, false)

	# State particles (art-keep.md 7.3, Nature colours): damage smoke, withering leaves.
	var smoke_ramp := _ramp([0.0, 0.12, 1.0], [Color(0.2, 0.18, 0.13, 0.0), Color(0.2, 0.18, 0.13, 0.6), Color(0.32, 0.3, 0.24, 0.0)], [])
	for s: Array in [["Smoke1", Vector3(1.6, 10.8, -1.6)], ["Smoke2", Vector3(-1.3, 13.4, -1.1)]]:
		var pm := _pm(Vector3.UP, 12.0, 1.0, 1.6, Vector3(0.25, 0.0, 0.0), 0.7, 2.6, smoke_ramp)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.5
		_particles(s[0], s[1], 24, 3.5, pm, mix_soft, false)
	var wither_ramp := _ramp([0.0, 0.08, 0.7, 1.0], [Color(0.66, 0.46, 0.14, 0.0), Color(0.66, 0.46, 0.14, 1.0),
		Color(0.48, 0.3, 0.1, 1.0), Color(0.3, 0.2, 0.08, 0.0)], [])
	for s: Array in [["Wither1", Vector3(-1.9, 11.6, -0.6)], ["Wither2", Vector3(1.6, 11.9, 1.4)]]:
		var pm := _pm(Vector3.DOWN, 35.0, 0.8, 1.6, Vector3(0.3, -1.6, 0.0), 0.34, 0.3, wither_ramp)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 1.5
		pm.angle_min = 0.0
		pm.angle_max = 360.0
		pm.angular_velocity_min = -200.0
		pm.angular_velocity_max = 200.0
		_particles(s[0], s[1], 20, 2.8, pm, mix_leaf, false)
	# Training burst out of the gate (8.3), construction ring + completion flash (8.2).
	var burst_ramp := _ramp([0.0, 1.0], [Color(GLOW, 1.0), Color(GLOW, 0.0)], team_glow_ramps)
	var tb := _pm(Vector3(0, 0.3, -1), 60.0, 2.0, 4.0, Vector3(0, -1.5, 0), 0.28, 0.08, burst_ramp)
	_particles("TrainBurst", Vector3(0, 1.9, -3.3), 24, 0.8, tb, add_soft, true)
	var br := _pm(Vector3.UP, 10.0, 0.8, 1.6, Vector3.ZERO, 0.22, 0.06, burst_ramp)
	br.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	br.emission_ring_axis = Vector3.UP
	br.emission_ring_radius = 3.75
	br.emission_ring_inner_radius = 3.5
	br.emission_ring_height = 0.05
	_particles("BuildRing", Vector3(0, 0.1, 0), 40, 1.2, br, add_soft, false)
	var bf := _pm(Vector3.UP, 180.0, 3.0, 6.0, Vector3(0, -3.0, 0), 0.4, 0.1, burst_ramp)
	_particles("BuildFlash", bloom_pos + Vector3(0, 0.5, 0), 40, 1.0, bf, add_soft, true)
	# Collapse: bloom burst (petals + sparks), lantern bursts, dust, bark splinters.
	var bb := _pm(Vector3.UP, 180.0, 2.5, 5.5, Vector3(0, -2.5, 0), 0.3, 0.22, petal_ramp)
	bb.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	bb.emission_sphere_radius = 1.0
	bb.angle_min = 0.0
	bb.angle_max = 360.0
	bb.angular_velocity_min = -300.0
	bb.angular_velocity_max = 300.0
	_particles("BloomBurst", bloom_pos + Vector3(0, 0.6, 0), 40, 1.6, bb, mix_petal, true)
	var img := Image.create(3, 1, false, Image.FORMAT_RGBF)
	for i: int in 3:
		var lp: Vector3 = lantern_pivot(i) - Vector3(0, LANTERN_DROP[i] + 0.55, 0)
		img.set_pixel(i, 0, Color(lp.x, lp.y, lp.z))
	var lb := _pm(Vector3.UP, 180.0, 2.0, 4.5, Vector3(0, -3.0, 0), 0.26, 0.06, burst_ramp)
	lb.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	lb.emission_point_texture = ImageTexture.create_from_image(img)
	lb.emission_point_count = 3
	_particles("LanternBurst", Vector3.ZERO, 36, 0.9, lb, add_soft, true)
	var du := _pm(Vector3.UP, 80.0, 1.0, 3.0, Vector3(0, -0.5, 0), 1.0, 3.0,
		_ramp([0.0, 1.0], [Color(0.42, 0.37, 0.26, 0.6), Color(0.36, 0.32, 0.22, 0.0)], []))
	du.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	du.emission_box_extents = Vector3(2.6, 0.5, 2.6)
	_particles("CollapseDust", Vector3(0, 4.0, 0), 60, 2.5, du, mix_soft, true)
	var sh := GPUParticles3D.new()
	sh.amount = 14
	sh.lifetime = 1.7
	sh.one_shot = true
	sh.explosiveness = 1.0
	sh.emitting = false
	sh.fixed_fps = 30
	sh.interpolate = true
	sh.local_coords = true
	sh.position = Vector3(0, 2.0, 4.5)
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.3, 1.0, 0.3)
	sh.draw_pass_1 = chunk
	sh.material_override = mats["Bark"]
	sh.visibility_aabb = AABB(Vector3(-9, -8, -9), Vector3(18, 16, 18))
	var shp := ParticleProcessMaterial.new()
	shp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	shp.emission_sphere_radius = 1.6
	shp.direction = Vector3.UP
	shp.spread = 70.0
	shp.initial_velocity_min = 3.0
	shp.initial_velocity_max = 6.0
	shp.gravity = Vector3(0, -12.0, 0)
	shp.particle_flag_rotate_y = true
	shp.angle_min = 0.0
	shp.angle_max = 360.0
	shp.angular_velocity_min = -360.0
	shp.angular_velocity_max = 360.0
	shp.scale_min = 0.8
	shp.scale_max = 1.5
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(0.75, 1))
	sc.add_point(Vector2(1, 0))
	var sct := CurveTexture.new()
	sct.curve = sc
	shp.scale_curve = sct
	sh.process_material = shp
	_add(sh, keep, "Shatter")
	sh.set_instance_shader_parameter(&"ao_bottom", 0.0)
	sh.set_instance_shader_parameter(&"ao_height", 6.0)


func _radial() -> GradientTexture2D:
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
	return t


## A small white cut-out texture: 0 = leaf (pointed oval with a midrib), 1 = petal (rounded oval).
func _shape_tex(kind: int) -> ImageTexture:
	var n: int = 48
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
	return ImageTexture.create_from_image(img)


func _quad(blend: int, tex: Texture2D, hdr: bool) -> QuadMesh:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = blend
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if hdr:
		m.albedo_color = Color(1.5, 1.5, 1.5, 1.0) # motes just reach the bloom threshold
	var q := QuadMesh.new()
	q.material = m
	return q


func _ramp(offsets: Array, colors: Array, team_list: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	if team_list is Array[Gradient]:
		(team_list as Array[Gradient]).append(g)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _pm(dir: Vector3, spread: float, vmin: float, vmax: float, gravity: Vector3, size_start: float,
		size_end: float, ramp: Texture2D) -> ParticleProcessMaterial:
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
	pm.color_ramp = ramp
	return pm


func _particles(nm: String, pos: Vector3, amount: int, life: float, pm: ParticleProcessMaterial,
		quad: Mesh, one_shot: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.process_material = pm
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-9, -12, -9), Vector3(18, 26, 18))
	p.position = pos
	p.emitting = false
	_add(p, keep, nm)
	return p
