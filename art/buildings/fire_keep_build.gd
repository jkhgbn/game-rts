extends SceneTree
## Generates art/buildings/fire_keep.tscn: Vessa's Fire Keep, "the Ember Bastion" (task A.7 polish of
## art-keep.md section 3). Run it WINDOWED (headless drops mesh data when saving):
##   Godot --path . -s art/buildings/fire_keep_build.gd --quit-after 60
## Every static section is ONE ArrayMesh with one surface per material (flat shaded, UVs in metres for
## the painted patterns of fire_keep_painted.gdshader), so the keep gets much more detail for about the
## same draw calls. The node names below are the contract with fire_keep.gd.
## Local space: metres, y up, gate on -Z, footprint 6 x 6 (Building owns the collider).

const OUT := "res://art/buildings/fire_keep.tscn"
const KeepScript := preload("res://art/buildings/fire_keep.gd")
const PAINTED := "res://art/buildings/fire_keep_painted.gdshader"
const TEAM := Color(0.85, 0.30, 0.12)
const GLOW := Color(1.0, 0.55, 0.15)
const C8 := 0.9238795  # cos(22.5 deg): flat / corner ratio of an octagon

## Corner towers: (x, z) centres; the chimney tower is the asymmetric one, RoofLost the roof that
## breaks below 50 % HP (the near-left tower in the 1v1 camera).
const TOWERS: Array[Vector2] = [Vector2(2.6, -2.6), Vector2(-2.6, -2.6), Vector2(2.6, 2.6), Vector2(-2.6, 2.6)]
const CHIMNEY := 3
const LOST_ROOF := 2
const HEART_Y := 16.2
const RING_Y := 14.0
## Art Lab budget pass (art-keep.md 9: <= 8 materials): the builder still names surfaces by their palette
## key, but commit() merges them into TWO materials: "P" (fire_keep_painted.gdshader, slot = UV2.y) and "G"
## (fire_keep_glow.gdshader, kind = UV2.y). Keys not listed here keep their own material (Runes, Banner).
const GROUPS := {
	"S": ["P", 0], "O": ["P", 1], "D": ["P", 2], "M": ["P", 3], "T": ["P", 4],
	"Coal": ["G", 0], "Gate": ["G", 1], "Window": ["G", 2], "Heart": ["G", 3], "Crystal": ["G", 4],
	"Lava": ["G", 5], "Black": ["G", 6],
}
## Painted slots (S, O, D, M, T): base colour, pattern, spec, crack, block size, joint width, block tint.
const SLOT_DATA := [
	[Color(0.33, 0.28, 0.25), 1, 0.0, 0.55, Vector2(1.0, 0.5), 0.07, 0.18],
	[Color(0.10, 0.08, 0.09), 3, 0.4, 1.0, Vector2(1.0, 1.0), 0.07, 0.18],
	[Color(0.17, 0.14, 0.13), 1, 0.0, 0.0, Vector2(0.8, 0.42), 0.06, 0.26],
	[Color(0.66, 0.43, 0.17), 4, 0.45, 0.0, Vector2(1.1, 10.0), 0.05, 0.2],
	[TEAM, 2, 0.12, 0.0, Vector2(0.5, 0.34), 0.05, 0.24],
]
## Glow energy scale of the small openings (UV2.x of the window kind): below the bloom threshold, no halo.
const SLIT_DIM := 0.25

var noise: Texture2D
var mats: Dictionary = {}
var keep: Node3D
var body: Node3D


# ============================================================ mesh builder

## One surface's triangles (untyped Arrays so appends through the Dictionary stick).
class Surf:
	var v: Array = []
	var n: Array = []
	var uv: Array = []
	var uv2: Array = []


## Multi-surface flat-shaded mesh builder. Every face is oriented away from an `inside` point.
class MB:
	var order: Array[String] = []
	var surfs: Dictionary = {}
	var xf: Transform3D = Transform3D.IDENTITY
	var flip: bool = false  # true = faces point TOWARD `inside` (the inner wall of a hollow)
	## Drop faces that look straight down: the RTS camera (pitch 55 deg) never sees them. Off for parts that
	## tip over (the Spire topples in the collapse).
	var skip_down: bool = true

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
		if skip_down and nn.y < -0.95:
			return
		var s: Surf = _s(k)
		# Godot's front faces are clockwise: emit a, c, b.
		s.v.append_array([a, c, b])
		s.n.append_array([nn, nn, nn])
		s.uv.append_array([ua, uc, ub])
		s.uv2.append_array([u2, u2, u2])

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

	## Side walls between polygon rings (Array of Vector2 x/z around +y) at heights ys; u runs along the
	## ring, v = y (or the slant distance with slant_v). Caps are fans with planar UVs.
	func loft(k: String, rings: Array, ys: Array, cap_top: bool = true, cap_bottom: bool = false,
			slant_v: bool = false) -> void:
		var cnt: int = (rings[0] as Array).size()
		var vacc: float = 0.0
		for L: int in rings.size() - 1:
			var r0: Array = rings[L]
			var r1: Array = rings[L + 1]
			var y0: float = ys[L]
			var y1: float = ys[L + 1]
			var inside := Vector3(0.0, (y0 + y1) * 0.5, 0.0)
			var u: float = 0.0
			var slant_sum: float = 0.0
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
				var sl: float = a.distance_to(d)
				slant_sum += sl
				var v0: float = vacc if slant_v else y0
				var v1: float = vacc + sl if slant_v else y1
				var top_scale: float = (q0.distance_to(q1) / maxf(seg, 0.001)) if slant_v else 1.0
				var um: float = u + seg * 0.5
				quad(k, a, b, c, d, Vector2(u, v0), Vector2(u + seg, v0),
					Vector2(um + seg * 0.5 * top_scale, v1), Vector2(um - seg * 0.5 * top_scale, v1), inside)
				u += seg
			vacc += slant_sum / float(cnt)
		if cap_top:
			_cap(k, rings[rings.size() - 1], ys[ys.size() - 1], -1.0)
		if cap_bottom:
			_cap(k, rings[0], ys[0], 1.0)

	func _cap(k: String, ring: Array, y: float, inside_dy: float) -> void:
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

	## Flat ring between two polygons at height y, facing up (or down).
	func annulus(k: String, outer: Array, inner: Array, y: float, up: bool = true) -> void:
		var cnt: int = outer.size()
		for i: int in cnt:
			var j: int = (i + 1) % cnt
			var o0: Vector2 = outer[i]
			var o1: Vector2 = outer[j]
			var i0: Vector2 = inner[i]
			var i1: Vector2 = inner[j]
			quad(k, Vector3(o0.x, y, o0.y), Vector3(o1.x, y, o1.y), Vector3(i1.x, y, i1.y), Vector3(i0.x, y, i0.y),
				o0, o1, i1, i0, Vector3((o0.x + i0.x) * 0.5, y + (-1.0 if up else 1.0), (o0.y + i0.y) * 0.5))

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
	## `skip` = face indices left out (0 -x, 1 +x, 2 -y, 3 +y, 4 -z, 5 +z, in the box's own frame).
	func box(k: String, center: Vector3, size: Vector3, basis: Basis = Basis.IDENTITY, skip: Array = []) -> void:
		var h: Vector3 = size * 0.5
		var p: Array[Vector3] = []
		for i: int in 8:
			var l := Vector3(h.x if (i & 1) != 0 else -h.x, h.y if (i & 2) != 0 else -h.y, h.z if (i & 4) != 0 else -h.z)
			p.append(center + basis * l)
		hexa(k, p, skip)

	## Any convex 8-corner block, corners indexed by bits (x = 1, y = 2, z = 4) like box().
	func hexa(k: String, p: Array[Vector3], skip: Array = []) -> void:
		var ctr := Vector3.ZERO
		for q: Vector3 in p:
			ctr += q
		ctr /= 8.0
		var faces: Array = [[0, 2, 6, 4], [1, 3, 7, 5], [0, 1, 5, 4], [2, 3, 7, 6], [0, 1, 3, 2], [4, 5, 7, 6]]
		for fi: int in faces.size():
			if fi in skip:
				continue
			var f: Array = faces[fi]
			quad_auto(k, p[f[0]], p[f[1]], p[f[2]], p[f[3]], ctr)

	## Merlon "tooth": a block with a pyramid point, facing `dir` (horizontal). The block's top face is
	## covered by the pyramid and its bottom sits on the parapet: neither is built. h = 0: pyramid only.
	func tooth(k: String, base: Vector3, w: float, d: float, h: float, tip: float, yaw: float) -> void:
		var bs := Basis(Vector3.UP, yaw)
		if h > 0.0:
			box(k, base + Vector3(0, h * 0.5, 0), Vector3(w, h, d), bs, [2, 3])
		var top: Vector3 = base + Vector3(0, h, 0)
		var apex: Vector3 = top + Vector3(0, tip, 0)
		var c: Array[Vector3] = []
		for s: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			c.append(top + bs * Vector3(s.x * w * 0.5, 0, s.y * d * 0.5))
		for i: int in 4:
			tri_auto(k, c[i], c[(i + 1) % 4], apex, top + Vector3(0, tip * 0.3, 0))

	## Tapered tube along a path (horn, claw, spike). `side` = a vector not parallel to the path, used
	## to build the ring frames; a radius of 0 closes it to a point.
	func tube(k: String, pts: Array[Vector3], radii: Array[float], sides: int, side: Vector3,
			twist: float = 0.0, cap_base: bool = false) -> void:
		var rings: Array = []
		var n: int = pts.size()
		for i: int in n:
			var t: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
			var s: Vector3 = t.cross(side).normalized()
			var q: Vector3 = s.cross(t).normalized()
			var ring: Array[Vector3] = []
			for j: int in sides:
				var a: float = TAU * float(j) / float(sides) + twist
				ring.append(pts[i] + (s * cos(a) + q * sin(a)) * radii[i])
			rings.append(ring)
		var vacc: float = 0.0
		for i: int in n - 1:
			var r0: Array[Vector3] = rings[i]
			var r1: Array[Vector3] = rings[i + 1]
			var inside: Vector3 = (pts[i] + pts[i + 1]) * 0.5
			var sl: float = pts[i].distance_to(pts[i + 1])
			for j: int in sides:
				var jj: int = (j + 1) % sides
				var u0: float = float(j) * 0.3
				quad(k, r0[j], r0[jj], r1[jj], r1[j], Vector2(u0, vacc), Vector2(u0 + 0.3, vacc),
					Vector2(u0 + 0.3, vacc + sl), Vector2(u0, vacc + sl), inside)
			vacc += sl
		if cap_base:
			var r0: Array[Vector3] = rings[0]
			for j: int in sides:
				tri_auto(k, pts[0], r0[j], r0[(j + 1) % sides], pts[1])

	## Flat convex polygon (fan from its centroid), facing away from `inside`.
	func poly(k: String, pts: Array[Vector3], inside: Vector3) -> void:
		var c := Vector3.ZERO
		for p: Vector3 in pts:
			c += p
		c /= float(pts.size())
		for i: int in pts.size():
			tri_auto(k, c, pts[i], pts[(i + 1) % pts.size()], inside)

	## One surface per MATERIAL group (GROUPS): palette keys sharing a material are merged, UV2.y = their slot.
	func commit(materials: Dictionary) -> Array:
		var mesh := ArrayMesh.new()
		var used: Array[Material] = []
		var g_order: Array[String] = []
		var merged: Dictionary = {}
		for k: String in order:
			var g: Array = GROUPS.get(k, [k, 0])
			var gk: String = g[0]
			if not merged.has(gk):
				merged[gk] = Surf.new()
				g_order.append(gk)
			var src: Surf = surfs[k]
			var dst: Surf = merged[gk]
			dst.v.append_array(src.v)
			dst.n.append_array(src.n)
			dst.uv.append_array(src.uv)
			for u2: Vector2 in src.uv2:
				dst.uv2.append(Vector2(u2.x, float(g[1])))
		for k: String in g_order:
			var s: Surf = merged[k]
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(s.v)
			arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(s.n)
			arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(s.uv)
			arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(s.uv2)
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			used.append(materials[k])
		return [mesh, used]


# ============================================================ ring helpers

## Regular polygon, circumradius r, points ordered around +y starting at angle `rot` from +x.
static func ring_n(n: int, r: float, rot: float = 0.0, off: Vector2 = Vector2.ZERO) -> Array:
	var pts: Array = []
	for i: int in n:
		var a: float = rot + TAU * float(i) / float(n)
		pts.append(off + Vector2(r * cos(a), -r * sin(a)))
	return pts


## Octagon with flat faces toward +-x / +-z, given the flat half-width.
static func oct(half: float, off: Vector2 = Vector2.ZERO) -> Array:
	return ring_n(8, half / C8, PI / 8.0, off)


## Hexagon with flat faces toward +-z, given the flat half-width.
static func hexr(half: float, off: Vector2 = Vector2.ZERO) -> Array:
	return ring_n(6, half / 0.8660254, PI / 6.0, off)


## Square of half-size h with 45-degree chamfered corners (leg ch).
static func chamfer(h: float, ch: float) -> Array:
	var e: float = h - ch
	return [Vector2(h, e), Vector2(h, -e), Vector2(e, -h), Vector2(-e, -h),
		Vector2(-h, -e), Vector2(-h, e), Vector2(-e, h), Vector2(e, h)]


# ============================================================ entry

func _initialize() -> void:
	noise = load("res://art/shaders/paint_noise.tres")
	_make_materials()
	keep = Node3D.new()
	keep.name = "FireKeep"
	keep.set_script(KeepScript)
	body = _add(Node3D.new(), keep, "Body")

	_build_plinth()
	_build_lava()
	_build_walls()
	_build_towers()
	_build_roofs()
	_build_donjon()
	_build_windows()
	_build_braziers()
	_build_spire()
	_build_floating()
	_build_banners()
	_build_ground()
	_build_lights_and_fx()

	# The merged materials fill the old slots (fire_keep.gd: painted = P, glow = G + Runes).
	keep.set(&"painted_materials", [mats["P"]] as Array[ShaderMaterial])
	keep.set(&"glow_materials", [mats["G"], mats["Runes"]] as Array[ShaderMaterial])
	keep.set(&"gate_material", mats["G"])
	keep.set(&"cap_material", mats["P"])
	keep.set(&"banner_material", mats["Banner"])
	keep.set(&"crystal_material", mats["G"])
	keep.set(&"heart_material", mats["G"])
	keep.set(&"ground_material", mats["Ground"])
	keep.set(&"lava_material", mats["G"])
	keep.set(&"rune_material", mats["Runes"])

	_own(keep, keep)
	var ps := PackedScene.new()
	var err: int = ps.pack(keep)
	if err == OK:
		err = ResourceSaver.save(ps, OUT)
	print("fire_keep_build: saved ", OUT, " err=", err)
	keep.free()
	quit()


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
		shadow: bool = true, ao: bool = true) -> MeshInstance3D:
	var res: Array = mb.commit(mats)
	var mi := MeshInstance3D.new()
	mi.mesh = res[0]
	_add(mi, parent, nm)
	var used: Array[Material] = res[1]
	for i: int in used.size():
		mi.set_surface_override_material(i, used[i])
	if ao:
		mi.set_instance_shader_parameter(&"ao_bottom", ao_bottom)
		mi.set_instance_shader_parameter(&"ao_height", ao_height)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ============================================================ materials

func _painted(nm: String, color: Color, pattern: int, spec: float, crack: float, block: Vector2,
		joint: float = 0.07, tint: float = 0.18) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.resource_name = nm
	m.resource_local_to_scene = true
	m.shader = load(PAINTED)
	m.set_shader_parameter(&"base_color", color)
	m.set_shader_parameter(&"noise_tex", noise)
	m.set_shader_parameter(&"noise_scale_a", 0.5)
	m.set_shader_parameter(&"noise_scale_b", 0.12)
	m.set_shader_parameter(&"spec_strength", spec)
	m.set_shader_parameter(&"rim_color", Color(0.55, 0.65, 0.85))
	m.set_shader_parameter(&"rim_strength", 0.25)
	m.set_shader_parameter(&"crack_strength", crack)
	m.set_shader_parameter(&"crack_color", Color(1.0, 0.5, 0.12))
	m.set_shader_parameter(&"crack_speed", 1.2)
	m.set_shader_parameter(&"crack_scale", 0.8)
	m.set_shader_parameter(&"damage", 0.0)
	m.set_shader_parameter(&"pattern", pattern)
	m.set_shader_parameter(&"block_size", block)
	m.set_shader_parameter(&"joint_width", joint)
	m.set_shader_parameter(&"block_tint", tint)
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
	# ONE painted material for the whole palette (slots S, O, D, M, T; see SLOT_DATA and GROUPS).
	var p := _painted("FirePainted", Color(0.33, 0.28, 0.25), 1, 0.0, 0.55, Vector2(1.0, 0.5))
	var cols := PackedColorArray()
	var specs := PackedFloat32Array()
	var cracks := PackedFloat32Array()
	var pats := PackedInt32Array()
	var blocks := PackedVector2Array()
	var joints := PackedFloat32Array()
	var tints := PackedFloat32Array()
	for d: Array in SLOT_DATA:
		cols.append(d[0])
		pats.append(d[1])
		specs.append(d[2])
		cracks.append(d[3])
		blocks.append(d[4])
		joints.append(d[5])
		tints.append(d[6])
	p.set_shader_parameter(&"base_colors", cols)
	p.set_shader_parameter(&"spec_strengths", specs)
	p.set_shader_parameter(&"crack_strengths", cracks)
	p.set_shader_parameter(&"patterns", pats)
	p.set_shader_parameter(&"block_sizes", blocks)
	p.set_shader_parameter(&"joint_widths", joints)
	p.set_shader_parameter(&"block_tints", tints)
	mats["P"] = p
	# ONE glow material for coals, gate, windows, heart, crystals, lava, the doorway and the build outline.
	mats["G"] = _shader_mat("FireGlow", "res://art/buildings/fire_keep_glow.gdshader", {"noise_tex": noise,
		"glow_color": GLOW, "team_glow": Color(1.0, 0.6, 0.18), "boost": 1.0})
	mats["Runes"] = _shader_mat("Runes", "res://art/buildings/fire_keep_runes.gdshader",
		{"glow_color": GLOW, "energy": 2.6, "cells": 26.0, "boost": 1.0})
	mats["Banner"] = _shader_mat("Banner", "res://art/buildings/fire_keep_banner.gdshader",
		{"cloth_color": TEAM, "stripe_color": Color(0.55, 0.08, 0.05), "trim_color": Color(0.80, 0.55, 0.22),
		"glyph_color": Color(1.0, 0.75, 0.30), "glyph_energy": 0.9, "amplitude": 0.11, "speed": 2.4})
	mats["Ground"] = _shader_mat("Ground", "res://art/buildings/fire_keep_ground.gdshader",
		{"noise_tex": noise, "darkness": 0.0})
	(mats["Ground"] as ShaderMaterial).render_priority = -1


# ============================================================ sections

func _build_plinth() -> void:
	var mb := MB.new()
	# Two battered, chamfered steps (top at y 1.1), and an outer lip that holds the lava channel.
	mb.loft("D", [chamfer(3.6, 1.0), chamfer(3.45, 0.95)], [0.0, 0.6])
	mb.loft("D", [chamfer(3.3, 0.85), chamfer(3.2, 0.8)], [0.6, 1.1])
	mb.band("D", chamfer(3.2, 0.8), chamfer(3.12, 0.76), 1.1, 1.28)
	# Stairs down from the gate.
	mb.box("D", Vector3(0, 0.3, -3.8), Vector3(2.5, 0.6, 0.8))
	mb.box("D", Vector3(0, 0.85, -3.45), Vector3(2.3, 0.5, 0.7))
	# Stair cheeks (bronze-capped later by the walls' trim).
	for sx: float in [-1.0, 1.0]:
		mb.box("D", Vector3(sx * 1.38, 0.62, -3.75), Vector3(0.36, 1.24, 1.1))
	_mesh_node(mb, "Plinth", body, 0.0, 1.4)


func _build_lava() -> void:
	var mb := MB.new()
	# The channel: a loop on the plinth top between the wall base (2.97) and the lip (3.12).
	var inner: Array = chamfer(2.98, 0.62)
	var outer: Array = chamfer(3.13, 0.77)
	var along: float = 0.0
	var y: float = 1.13
	for i: int in 8:
		var j: int = (i + 1) % 8
		var i0: Vector2 = inner[i]
		var i1: Vector2 = inner[j]
		var o0: Vector2 = outer[i]
		var o1: Vector2 = outer[j]
		var seg: float = ((i0 + o0) * 0.5).distance_to((i1 + o1) * 0.5)
		mb.quad("Lava", Vector3(i0.x, y, i0.y), Vector3(o0.x, y, o0.y), Vector3(o1.x, y, o1.y), Vector3(i1.x, y, i1.y),
			Vector2(0, along), Vector2(0.15, along), Vector2(0.15, along + seg), Vector2(0, along + seg),
			Vector3(0, y - 1.0, 0))
		along += seg
	# Lava falls: over the lip, down both plinth steps, into a pool (sides +x, -x and the back +z).
	for dir: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]:
		var across := Vector3(-dir.z, 0, dir.x)
		var prof: Array[Vector2] = [Vector2(2.82, 1.7), Vector2(3.22, 1.7), Vector2(3.25, 1.3),
			Vector2(3.225, 1.1), Vector2(3.33, 0.6), Vector2(3.47, 0.61), Vector2(3.48, 0.6), Vector2(3.63, 0.0),
			Vector2(3.9, 0.025)]
		var path: Array[Vector3] = []
		for p: Vector2 in prof:
			path.append(dir * p.x + Vector3(0, p.y, 0))
		_strip(mb, path, 0.62, across, dir)
		# Pool: a lobed disc on the ground, UV.y = distance from the fall (the lava spreads out).
		var pc: Vector3 = dir * 4.15 + Vector3(0, 0.03, 0)
		var pts: Array[Vector3] = []
		for i: int in 10:
			var a: float = TAU * float(i) / 10.0
			var r: float = 0.55 + 0.12 * sin(a * 3.0 + dir.x * 2.0 + dir.z)
			pts.append(pc + (dir * cos(a) * 0.85 + across * sin(a)) * r)
		for i: int in 10:
			var p0: Vector3 = pts[i]
			var p1: Vector3 = pts[(i + 1) % 10]
			mb.tri("Lava", pc, p0, p1, Vector2(0, 0), Vector2(float(i) * 0.35, p0.distance_to(pc)),
				Vector2(float(i + 1) * 0.35, p1.distance_to(pc)), pc - Vector3(0, 1, 0))
	_mesh_node(mb, "Lava", body, 0.0, 1.0, false, false)


## Lava strip along a path, `w` wide across `across`; faces away from the plinth (inside = -out, down).
func _strip(mb: MB, path: Array[Vector3], w: float, across: Vector3, out: Vector3) -> void:
	var vlen: float = 0.0
	var hw: float = w * 0.5
	for i: int in path.size() - 1:
		var a: Vector3 = path[i]
		var b: Vector3 = path[i + 1]
		var seg: float = a.distance_to(b)
		var mid: Vector3 = (a + b) * 0.5
		var nrm: Vector3 = (b - a).cross(across).normalized()
		if nrm.dot(out + Vector3.UP) < 0.0:
			nrm = -nrm
		var lift: Vector3 = nrm * 0.02
		mb.quad("Lava", a - across * hw + lift, a + across * hw + lift, b + across * hw + lift, b - across * hw + lift,
			Vector2(0, vlen), Vector2(w, vlen), Vector2(w, vlen + seg), Vector2(0, vlen + seg), mid - nrm)
		vlen += seg


## Wall half-width (flat) at height y: battered from 2.88 at y 1.55 to 2.58 at y 6.1.
static func wall_half(y: float) -> float:
	return lerpf(2.88, 2.58, clampf((y - 1.55) / 4.55, 0.0, 1.0))


func _build_walls() -> void:
	var mb := MB.new()
	# Base course, battered wall, bronze mid band, corbel, bronze parapet with the walkway on top.
	mb.loft("D", [chamfer(2.98, 0.62), chamfer(2.93, 0.6)], [1.1, 1.55], false)
	mb.loft("S", [chamfer(2.88, 0.58), chamfer(2.58, 0.5)], [1.55, 6.1], false)
	mb.band("M", chamfer(2.8, 0.56), chamfer(2.66, 0.54), 3.95, 4.3)
	mb.loft("D", [chamfer(2.58, 0.5), chamfer(2.9, 0.62)], [6.1, 6.5], false)
	mb.loft("M", [chamfer(2.9, 0.62), chamfer(2.9, 0.62)], [6.5, 6.8], false)
	mb._cap("S", chamfer(2.9, 0.62), 6.8, -1.0)
	# Crenellation teeth, three per side (the +-x middle ones make room for the braziers).
	for side: int in 4:
		var yaw: float = PI * 0.5 * float(side)
		var out := Vector3(sin(yaw), 0, cos(yaw))
		var tng := Vector3(out.z, 0, -out.x)
		for o: float in [-1.0, 0.0, 1.0]:
			if o == 0.0 and absf(out.x) > 0.5:
				continue
			mb.tooth("D", out * 2.62 + tng * o + Vector3(0, 6.8, 0), 0.56, 0.5, 0.5, 0.38, yaw)
	# Gatehouse: a squared block pushed out of the -z wall, arched gate, emblem, cornice.
	mb.box("S", Vector3(0, 3.5, -2.75), Vector3(3.1, 4.8, 0.9))
	mb.box("M", Vector3(0, 6.02, -2.72), Vector3(3.4, 0.26, 1.05))
	for sx: float in [-1.0, 1.0]:
		mb.box("D", Vector3(sx * 1.45, 3.5, -3.24), Vector3(0.3, 4.8, 0.14))  # corner pilasters
		mb.tooth("D", Vector3(sx * 0.62, 6.15, -3.0), 0.5, 0.42, 0.42, 0.34, 0.0)
	# Bronze arch: jambs + seven voussoirs (a big keystone).
	var zc: float = -3.2
	for sx: float in [-1.0, 1.0]:
		mb.box("M", Vector3(sx * 1.12, 2.32, zc - 0.07), Vector3(0.34, 2.45, 0.16))
	for i: int in 7:
		var a0: float = PI * float(i) / 7.0 + 0.025
		var a1: float = PI * float(i + 1) / 7.0 - 0.025
		var r0: float = 0.95
		var r1: float = 1.32 + (0.16 if i == 3 else 0.0)
		var p: Array[Vector3] = []
		for bit: int in 8:
			var a: float = a1 if (bit & 1) != 0 else a0
			var r: float = r1 if (bit & 2) != 0 else r0
			var z: float = zc - 0.18 if (bit & 4) != 0 else zc + 0.02
			p.append(Vector3(cos(a) * r, 3.55 + sin(a) * r, z))
		mb.hexa("M", p)
	# The dark doorway (rectangle + half disc), the glowing portcullis in front of it.
	var door: Array[Vector3] = [Vector3(-0.95, 1.1, zc - 0.01), Vector3(0.95, 1.1, zc - 0.01)]
	for i: int in 9:
		var a: float = PI * float(i) / 8.0
		door.append(Vector3(cos(a) * 0.95, 3.55 + sin(a) * 0.95, zc - 0.01))
	mb.poly("Black", door, Vector3(0, 2.5, 0))
	for i: int in 5:
		var x: float = -0.64 + 0.32 * float(i)
		var top: float = 3.55 + sqrt(maxf(0.95 * 0.95 - x * x, 0.0)) - 0.06
		mb.box("Gate", Vector3(x, (1.1 + top) * 0.5, zc - 0.07), Vector3(0.11, top - 1.1, 0.08))
	for y: float in [2.0, 2.95]:
		mb.box("Gate", Vector3(0, y, zc - 0.1), Vector3(1.85, 0.1, 0.06))
	# Emblem over the arch: bronze octagon disc with a glowing gem.
	var ey: float = 5.42
	var disc: Array = ring_n(8, 0.42, PI / 8.0)
	var ring_front: Array[Vector3] = []
	for q: Vector2 in disc:
		ring_front.append(Vector3(q.x, ey + q.y, zc - 0.16))
	mb.poly("M", ring_front, Vector3(0, ey, 0))
	for i: int in 8:
		var q0: Vector2 = disc[i]
		var q1: Vector2 = disc[(i + 1) % 8]
		mb.quad_auto("M", Vector3(q0.x, ey + q0.y, zc - 0.16), Vector3(q1.x, ey + q1.y, zc - 0.16),
			Vector3(q1.x, ey + q1.y, zc), Vector3(q0.x, ey + q0.y, zc), Vector3(0, ey, zc + 0.5))
	var gem_c := Vector3(0, ey, zc - 0.2)
	var gem: Array[Vector3] = [gem_c + Vector3(0, 0.3, 0), gem_c + Vector3(0.22, 0, 0), gem_c + Vector3(0, -0.3, 0),
		gem_c + Vector3(-0.22, 0, 0)]
	var gem_tip: Vector3 = gem_c + Vector3(0, 0, -0.16)
	for i: int in 4:
		mb.tri_auto("Gate", gem[i], gem[(i + 1) % 4], gem_tip, gem_c + Vector3(0, 0, 0.1))
	# Lava vents at the foot of the three other faces: bronze grille bars, a spout lip, a stone hood.
	for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]:
		var tng := Vector3(out.z, 0, -out.x)
		for o: float in [-0.26, 0.0, 0.26]:
			mb.box("M", out * (wall_half(2.2) + 0.08) + tng * o + Vector3(0, 2.22, 0), tng.abs() * 0.09 + out.abs() * 0.08 + Vector3(0, 1.2, 0))
		mb.box("M", out * 2.99 + Vector3(0, 1.62, 0), tng.abs() * 1.0 + out.abs() * 0.5 + Vector3(0, 0.14, 0))
		mb.box("D", out * (wall_half(2.95) + 0.1) + Vector3(0, 2.98, 0), tng.abs() * 1.35 + out.abs() * 0.3 + Vector3(0, 0.22, 0))
	# Banner rods (bronze) with brackets for the three side banners.
	for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]:
		var tng := Vector3(out.z, 0, -out.x)
		mb.box("M", out * 3.05 + Vector3(0, 6.32, 0), (tng.abs() * 1.5 + out.abs() * 0.12 + Vector3(0, 0.12, 0)))
		for o: float in [-0.6, 0.6]:
			mb.box("M", out * 2.86 + tng * o + Vector3(0, 6.32, 0), tng.abs() * 0.1 + out.abs() * 0.4 + Vector3(0, 0.1, 0))
	_mesh_node(mb, "Walls", body, 1.1, 6.0)


func _build_towers() -> void:
	var mb := MB.new()
	for ti: int in TOWERS.size():
		var c: Vector2 = TOWERS[ti]
		mb.xf = Transform3D(Basis.IDENTITY, Vector3(c.x, 0, c.y))
		mb.loft("D", [oct(1.26), oct(1.12)], [0.0, 1.3], false)
		mb.loft("S", [oct(1.06), oct(0.9)], [1.3, 8.4], false)
		mb.band("M", oct(1.06), oct(0.98), 4.3, 4.62)
		mb.band("M", oct(0.99), oct(0.9), 7.15, 7.45)
		mb.loft("D", [oct(0.9), oct(1.22)], [8.4, 8.95], false)
		mb.loft("S", [oct(1.22), oct(1.22)], [8.95, 9.5], true)
		if ti == CHIMNEY or ti == LOST_ROOF:
			mb.band("M", oct(1.28), oct(1.2), 9.28, 9.5)  # the other two sit under their roof's eave
		if ti == CHIMNEY:
			# The forge chimney: the asymmetric second vertical, taller than every roof.
			for k: int in 8:
				var a: float = TAU * float(k) / 8.0 + PI / 8.0
				var tp := Vector3(cos(a) * 1.02, 9.5, -sin(a) * 1.02)
				mb.tooth("D", tp, 0.42, 0.36, 0.34, 0.3, a + PI * 0.5)
			mb.loft("S", [oct(0.72), oct(0.6)], [9.5, 14.2], false)
			mb.band("M", oct(0.76), oct(0.66), 10.9, 11.2)
			mb.band("M", oct(0.7), oct(0.6), 13.0, 13.3)
			mb.loft("D", [oct(0.6), oct(0.84), oct(0.84)], [14.2, 14.5, 14.85], false)
			mb.annulus("D", oct(0.84), oct(0.56), 14.85)
			mb.flip = true
			mb.loft("D", [oct(0.56), oct(0.56)], [14.3, 14.85], false)
			mb.flip = false
	mb.xf = Transform3D.IDENTITY
	_mesh_node(mb, "Towers", body, 0.0, 10.0)


## One flared, tiled roof with an obsidian eave, finial and two curved horns, at tower centre c.
func _roof(mb: MB, c: Vector2) -> void:
	mb.xf = Transform3D(Basis.IDENTITY, Vector3(c.x, 0, c.y))
	mb.loft("T", [oct(1.55), oct(1.12), oct(0.68), oct(0.3), oct(0.001)], [9.4, 9.8, 10.9, 12.0, 12.95], false, false, true)
	mb.loft("O", [oct(1.62), oct(1.62)], [9.28, 9.44], false)
	mb.annulus("O", oct(1.62), oct(1.4), 9.44)
	mb.tube("O", [Vector3(0, 12.6, 0), Vector3(0, 13.2, 0), Vector3(0, 13.7, 0)] as Array[Vector3],
		[0.16, 0.1, 0.0] as Array[float], 4, Vector3.RIGHT)
	mb.xf = Transform3D.IDENTITY
	var outward := Vector3(c.x, 0, c.y).normalized()
	for s: float in [-1.0, 1.0]:
		var d: Vector3 = outward.rotated(Vector3.UP, s * 0.62)
		var side: Vector3 = d.cross(Vector3.UP)
		var b := Vector3(c.x, 0, c.y) + d * 1.05 + Vector3(0, 9.85, 0)
		var pts: Array[Vector3] = [b, b + d * 0.42 + Vector3(0, 0.35, 0), b + d * 0.72 + Vector3(0, 1.0, 0),
			b + d * 0.7 + Vector3(0, 1.65, 0), b + d * 0.5 + Vector3(0, 2.05, 0)]
		mb.tube("O", pts, [0.26, 0.22, 0.15, 0.08, 0.0] as Array[float], 5, side)


func _build_roofs() -> void:
	var intact := MB.new()
	var lost := MB.new()
	for ti: int in TOWERS.size():
		if ti == CHIMNEY:
			continue
		_roof(lost if ti == LOST_ROOF else intact, TOWERS[ti])
	_mesh_node(intact, "Roofs", body, 9.3, 3.8)
	_mesh_node(lost, "RoofLost", body, 9.3, 3.8)


## Donjon flat half-width at y (octagon, battered from 1.95 at 6.2 to 1.7 at 11.3).
static func donjon_half(y: float) -> float:
	return lerpf(1.95, 1.7, clampf((y - 6.2) / 5.1, 0.0, 1.0))


func _build_donjon() -> void:
	var mb := MB.new()
	mb.loft("S", [oct(1.95), oct(1.7)], [6.2, 11.3], false)
	mb.band("M", oct(1.92), oct(1.8), 8.55, 8.85)
	mb.loft("D", [oct(1.7), oct(2.08)], [11.3, 11.8], false)
	mb.loft("M", [oct(2.08), oct(2.08)], [11.8, 12.1], true)
	for k: int in 8:
		var a: float = TAU * float(k) / 8.0
		var out := Vector3(cos(a), 0, -sin(a))
		mb.tooth("D", out * 1.84 + Vector3(0, 12.1, 0), 0.62, 0.46, 0.46, 0.4, a + PI * 0.5)
	_mesh_node(mb, "Donjon", body, 6.2, 6.0)


## A flat quad / arch on a battered face: `out` = face direction, half_fn gives the face distance at y.
func _face_shape(mb: MB, k: String, center: Vector3, out: Vector3, dist0: float, y0: float, dist1: float,
		y1: float, w: float, ya: float, yb: float, arch: bool, energy_scale: float = 1.0) -> void:
	var tng := Vector3(out.z, 0, -out.x)
	var fp := func(t: float, y: float) -> Vector3:
		var d: float = lerpf(dist0, dist1, clampf((y - y0) / (y1 - y0), 0.0, 1.0)) + 0.03
		return center + out * d + tng * t + Vector3(0, y, 0)
	# Outline in face coordinates (t across, y up); UV = 0..1 inside the opening.
	var ts: Array[Vector2] = [Vector2(-w * 0.5, ya), Vector2(w * 0.5, ya)]
	if arch:
		for i: int in 5:
			var a: float = PI * float(i) / 4.0
			ts.append(Vector2(cos(a) * w * 0.5, yb + sin(a) * w * 0.5))
	else:
		ts.append(Vector2(w * 0.5, yb))
		ts.append(Vector2(-w * 0.5, yb))
	var top: float = yb + (w * 0.5 if arch else 0.0)
	var c2 := Vector2(0.0, (ya + top) * 0.5)
	var uvf := func(q: Vector2) -> Vector2:
		return Vector2((q.x + w * 0.5) / w, (q.y - ya) / (top - ya))
	var inside: Vector3 = center + Vector3(0, (ya + yb) * 0.5, 0)
	for i: int in ts.size():
		var q0: Vector2 = ts[i]
		var q1: Vector2 = ts[(i + 1) % ts.size()]
		mb.tri(k, fp.call(c2.x, c2.y), fp.call(q0.x, q0.y), fp.call(q1.x, q1.y), uvf.call(c2), uvf.call(q0),
			uvf.call(q1), inside, Vector2(energy_scale, 0.0))


func _build_windows() -> void:
	var mb := MB.new()
	# Donjon: four tall arched forge windows, the heart's glow seen through the walls.
	for k: int in 4:
		var a: float = PI * 0.5 * float(k)
		var out := Vector3(cos(a), 0, -sin(a))
		_face_shape(mb, "Window", Vector3.ZERO, out, 1.95, 6.2, 1.7, 11.3, 0.76, 9.2, 10.4, true)
		_face_shape(mb, "Window", Vector3.ZERO, out, 1.95, 6.2, 1.7, 11.3, 0.3, 7.15, 8.1, true, SLIT_DIM)
	# Wall arrow slits (two per side on +-x and +z, dimmed: no halo) and the lava vents the falls pour out of.
	for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]:
		var tng := Vector3(out.z, 0, -out.x)
		for o: float in [-1.15, 1.15]:
			_face_shape(mb, "Window", tng * o, out, 2.88, 1.55, 2.58, 6.1, 0.26, 4.65, 5.55, true, SLIT_DIM)
		_face_shape(mb, "Window", Vector3.ZERO, out, 2.88, 1.55, 2.58, 6.1, 0.96, 1.7, 2.3, true)
	# Tower slits on the two outer faces of every tower (dimmed).
	for c: Vector2 in TOWERS:
		var cc := Vector3(c.x, 0, c.y)
		for out: Vector3 in [Vector3(signf(c.x), 0, 0), Vector3(0, 0, signf(c.y))]:
			_face_shape(mb, "Window", cc, out, 1.06, 1.3, 0.9, 8.4, 0.24, 5.4, 6.4, true, SLIT_DIM)
	# The chimney mouth.
	var ch: Vector2 = TOWERS[CHIMNEY]
	var mouth: Array[Vector3] = []
	for q: Vector2 in oct(0.56):
		mouth.append(Vector3(ch.x + q.x, 14.62, ch.y + q.y))
	var mc := Vector3(ch.x, 14.62, ch.y)
	for i: int in mouth.size():
		mb.tri("Window", mc, mouth[i], mouth[(i + 1) % mouth.size()], Vector2(0.5, 0.05), Vector2(0.5, 0.05),
			Vector2(0.5, 0.05), mc - Vector3(0, 1, 0), Vector2(1.0, 0.0))
	_mesh_node(mb, "Windows", body, 0.0, 1.0, false, false)


## Brazier positions (bowl base): gatehouse roof corners and the +-x parapets.
const BRAZIERS: Array[Vector3] = [Vector3(-1.25, 6.15, -2.95), Vector3(1.25, 6.15, -2.95),
	Vector3(2.6, 6.8, 0.0), Vector3(-2.6, 6.8, 0.0)]


func _build_braziers() -> void:
	var mb := MB.new()
	for p: Vector3 in BRAZIERS:
		# Small parts: hexagons (art-keep 9: cylinders 6-8), pyramid prongs.
		mb.xf = Transform3D(Basis.IDENTITY, p)
		mb.loft("M", [hexr(0.3), hexr(0.2)], [0.0, 0.14], false)
		mb.loft("M", [hexr(0.13), hexr(0.13)], [0.14, 0.42], false)
		mb.loft("M", [hexr(0.18), hexr(0.5), hexr(0.52)], [0.42, 0.72, 0.8], false)
		mb.loft("Coal", [hexr(0.46), hexr(0.24)], [0.74, 0.92], true)
		for k: int in 4:
			var a: float = PI * 0.5 * float(k) + PI * 0.25
			var d := Vector3(cos(a), 0, sin(a))
			mb.tooth("M", d * 0.46 + Vector3(0, 0.78, 0), 0.12, 0.12, 0.0, 0.28, a)
	mb.xf = Transform3D.IDENTITY
	_mesh_node(mb, "Braziers", body, 5.8, 2.0)


func _build_spire() -> void:
	var mb := MB.new()
	mb.skip_down = false  # it topples in the collapse: its undersides show
	# Local to the Spire node at y 12 (it topples around its base when the keep dies).
	mb.loft("O", [ring_n(6, 1.55), ring_n(6, 1.25), ring_n(6, 0.98)], [0.0, 1.2, 1.8], true)
	mb.loft("O", [ring_n(6, 0.55, 0.5), ring_n(6, 0.3, 0.5), ring_n(6, 0.001, 0.5)], [1.8, 2.6, 3.2], false)
	# Four great claws on the diagonals and four small ones between them, cradling the heart.
	for k: int in 8:
		var big: bool = k % 2 == 0
		var a: float = PI * 0.25 * float(k) + PI * 0.25
		var d := Vector3(cos(a), 0, -sin(a))
		var side: Vector3 = d.cross(Vector3.UP)
		var pts: Array[Vector3]
		var radii: Array[float]
		if big:
			pts = [d * 1.02 + Vector3(0, 1.2, 0), d * 1.75 + Vector3(0, 2.8, 0), d * 1.78 + Vector3(0, 4.5, 0),
				d * 1.22 + Vector3(0, 5.9, 0), d * 0.62 + Vector3(0, 6.6, 0)]
			radii = [0.46, 0.38, 0.27, 0.12, 0.0]
		else:
			pts = [d * 1.0 + Vector3(0, 1.3, 0), d * 1.45 + Vector3(0, 2.3, 0), d * 1.35 + Vector3(0, 3.4, 0),
				d * 0.95 + Vector3(0, 4.1, 0)]
			radii = [0.3, 0.22, 0.1, 0.0]
		mb.tube("O", pts, radii, 4, side, PI * 0.25)
	var res: Array = mb.commit(mats)
	var mi := MeshInstance3D.new()
	mi.mesh = res[0]
	mi.set_surface_override_material(0, (res[1] as Array)[0])
	mi.position = Vector3(0, 12.0, 0)
	_add(mi, body, "Spire")
	mi.set_instance_shader_parameter(&"ao_bottom", 12.0)
	mi.set_instance_shader_parameter(&"ao_height", 6.5)


func _build_floating() -> void:
	# The Ember Heart.
	var heart := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.74
	sm.height = 1.48
	sm.radial_segments = 12
	sm.rings = 6
	heart.mesh = sm
	heart.material_override = mats["G"]
	heart.set_instance_shader_parameter(&"kind_override", 3)  # SphereMesh has no UV2: glow kind "heart"
	heart.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	heart.position = Vector3(0, HEART_Y, 0)
	_add(heart, body, "EmberHeart")
	# The rune band around it, tilted; fire_keep.gd spins it about its own y.
	var mb := MB.new()
	var segs: int = 32
	for i: int in segs:
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0) * 1.42, 0, sin(a0) * 1.42)
		var p1 := Vector3(cos(a1) * 1.42, 0, sin(a1) * 1.42)
		var u0: float = float(i) / float(segs)
		var u1: float = float(i + 1) / float(segs)
		mb.quad("Runes", p0 + Vector3(0, -0.17, 0), p1 + Vector3(0, -0.17, 0), p1 + Vector3(0, 0.17, 0),
			p0 + Vector3(0, 0.17, 0), Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0), Vector3.ZERO)
	var tilt := Node3D.new()
	tilt.position = Vector3(0, HEART_Y, 0)
	tilt.rotation = Vector3(deg_to_rad(16.0), 0, deg_to_rad(-9.0))
	_add(tilt, body, "RuneTilt")
	_mesh_node(mb, "RuneRing", tilt, 0.0, 1.0, false, false)
	# The crystal ring (Ring rotates; each crystal spins on itself).
	var ring := Node3D.new()
	ring.position = Vector3(0, RING_Y, 0)
	_add(ring, body, "Ring")
	var cm := MB.new()
	var top := Vector3(0, 0.82, 0)
	var bot := Vector3(0, -0.5, 0)
	var eq: Array = ring_n(6, 0.32)
	for i: int in 6:
		var q0: Vector2 = eq[i]
		var q1: Vector2 = eq[(i + 1) % 6]
		var e0 := Vector3(q0.x, 0.08 * (1.0 if i % 2 == 0 else -1.0), q0.y)
		var e1 := Vector3(q1.x, 0.08 * (1.0 if (i + 1) % 2 == 0 else -1.0), q1.y)
		cm.tri_auto("Crystal", e0, e1, top, Vector3.ZERO)
		cm.tri_auto("Crystal", e1, e0, bot, Vector3.ZERO)
	# A small satellite shard stuck to its side.
	cm.xf = Transform3D(Basis(Vector3(0, 0, 1), 0.5).scaled(Vector3.ONE * 0.45), Vector3(0.24, -0.12, 0.05))
	for i: int in 6:
		var q0: Vector2 = eq[i]
		var q1: Vector2 = eq[(i + 1) % 6]
		cm.tri_auto("Crystal", Vector3(q0.x, 0, q0.y), Vector3(q1.x, 0, q1.y), top, Vector3.ZERO)
		cm.tri_auto("Crystal", Vector3(q1.x, 0, q1.y), Vector3(q0.x, 0, q0.y), bot, Vector3.ZERO)
	var cres: Array = cm.commit(mats)
	for i: int in 3:
		var c := MeshInstance3D.new()
		c.mesh = cres[0]
		c.material_override = mats["G"]
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a: float = TAU * float(i) / 3.0
		c.position = Vector3(cos(a) * 3.25, 0, sin(a) * 3.25)
		c.rotation.y = a
		_add(c, ring, "Crystal%d" % (i + 1))


func _banner(mb: MB, top_center: Vector3, out: Vector3, w: float, h: float, phase: float) -> void:
	var tng := Vector3(out.z, 0, -out.x)
	var nx: int = 2
	var ny: int = 8
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
	for i: int in 2:
		var c: Vector2 = TOWERS[i]
		_banner(gate, Vector3(c.x, 7.32, c.y - 1.1), Vector3.FORWARD, 1.0, 2.55, 1.7 * float(i))
	var side := MB.new()
	var ph: float = 3.4
	for out: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]:
		_banner(side, out * 3.1 + Vector3(0, 6.26, 0), out, 1.25, 3.2, ph)
		ph += 1.7
	_mesh_node(gate, "BannersGate", body, 0.0, 1.0, true, false)
	_mesh_node(side, "BannersSide", body, 0.0, 1.0, true, false)


func _build_ground() -> void:
	var decal := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(13, 13)
	decal.mesh = pm
	decal.material_override = mats["Ground"]
	decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decal.position = Vector3(0, 0.03, 0)
	_add(decal, keep, "ContactDecal")
	# Basalt chunks (dark stone) and obsidian shards jutting out of the scorched ground.
	var mb := MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var placed: int = 0
	var tries: int = 0
	while placed < 11 and tries < 200:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(3.75, 4.5)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if _blocked(p):
			continue
		placed += 1
		var s: float = rng.randf_range(0.3, 0.5)
		var hgt: float = rng.randf_range(0.3, 0.6)
		mb.xf = Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(0.1, 0.35)), p)
		mb.loft("D", [ring_n(5, s, rng.randf()), ring_n(5, s * 0.7, rng.randf())], [-0.15, hgt], true)
	placed = 0
	tries = 0
	while placed < 8 and tries < 200:
		tries += 1
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(3.8, 4.6)
		var p := Vector3(cos(a) * r, -0.1, sin(a) * r)
		if _blocked(p):
			continue
		placed += 1
		var out := Vector3(cos(a), 0, sin(a))
		var lean: Vector3 = (Vector3.UP + out * rng.randf_range(0.25, 0.6)).normalized()
		var hgt: float = rng.randf_range(0.55, 1.15)
		mb.xf = Transform3D.IDENTITY
		var r0: float = rng.randf_range(0.16, 0.24)
		mb.tube("O", [p, p + lean * hgt] as Array[Vector3], [r0, 0.0] as Array[float], 4, out.cross(Vector3.UP),
			rng.randf())
	mb.xf = Transform3D.IDENTITY
	_mesh_node(mb, "Rubble", keep, -0.3, 1.5)


## Keep the gate stairs and the three lava pools clear of rubble.
static func _blocked(p: Vector3) -> bool:
	if p.z < -3.0 and absf(p.x) < 2.0:
		return true
	for d: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]:
		if p.distance_to(d * 4.15) < 1.1:
			return true
	return false


# ============================================================ lights and particles

func _build_lights_and_fx() -> void:
	var hl := OmniLight3D.new()
	hl.light_color = Color(1.0, 0.55, 0.2)
	hl.light_energy = 3.0
	hl.light_specular = 0.2
	hl.omni_range = 15.0
	hl.position = Vector3(0, 13.4, 0)
	_add(hl, body, "HeartLight")
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.45, 0.1)
	gl.light_energy = 1.8
	gl.light_specular = 0.2
	gl.omni_range = 7.0
	gl.position = Vector3(0, 2.4, -4.4)
	_add(gl, body, "GateLight")

	var add_quad: QuadMesh = _quad(BaseMaterial3D.BLEND_MODE_ADD)
	var mix_quad: QuadMesh = _quad(BaseMaterial3D.BLEND_MODE_MIX)
	var fire_ramp := _ramp([0.0, 0.35, 0.75, 1.0], [Color(1, 0.92, 0.55, 1), Color(1, 0.5, 0.1, 0.9),
		Color(0.55, 0.08, 0.0, 0.5), Color(0.3, 0.02, 0.0, 0.0)])
	# Brazier flames: one system, emission points on the four coals.
	var img := Image.create(BRAZIERS.size(), 1, false, Image.FORMAT_RGBF)
	for i: int in BRAZIERS.size():
		var p: Vector3 = BRAZIERS[i] + Vector3(0, 0.95, 0)
		img.set_pixel(i, 0, Color(p.x, p.y, p.z))
	var bf := _pm(Vector3.UP, 12.0, 1.0, 1.7, Vector3.ZERO, 0.5, 0.1, fire_ramp)
	bf.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	bf.emission_point_texture = ImageTexture.create_from_image(img)
	bf.emission_point_count = BRAZIERS.size()
	_particles("BrazierFire", Vector3.ZERO, 36, 0.7, bf, add_quad)
	# Embers rising off the lava channel.
	var em := _pm(Vector3.UP, 30.0, 0.5, 1.3, Vector3.ZERO, 0.11, 0.05,
		_ramp([0.0, 1.0], [Color(1, 0.7, 0.25, 1), Color(1, 0.45, 0.1, 0)]))
	em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	em.emission_ring_axis = Vector3.UP
	em.emission_ring_radius = 3.25
	em.emission_ring_inner_radius = 3.0
	em.emission_ring_height = 0.1
	em.turbulence_enabled = true
	em.turbulence_noise_strength = 0.35
	em.turbulence_noise_scale = 1.2
	_particles("Embers", Vector3(0, 1.2, 0), 20, 3.0, em, add_quad)
	# Chimney smoke (dark, drifting).
	var cs := _pm(Vector3.UP, 10.0, 0.9, 1.2, Vector3(0.25, 0, 0), 0.6, 2.2,
		_ramp([0.0, 0.2, 1.0], [Color(0.3, 0.2, 0.16, 0.0), Color(0.24, 0.19, 0.17, 0.5), Color(0.2, 0.18, 0.17, 0.0)]))
	cs.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	cs.emission_sphere_radius = 0.35
	var ch: Vector2 = TOWERS[CHIMNEY]
	_particles("ChimneySmoke", Vector3(ch.x, 14.9, ch.y), 16, 4.0, cs, mix_quad)
	# Heart sparks.
	var hs := _pm(Vector3.UP, 70.0, 0.5, 1.3, Vector3(0, 0.3, 0), 0.14, 0.04, fire_ramp)
	hs.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	hs.emission_sphere_radius = 0.8
	_particles("HeartSparks", Vector3(0, HEART_Y, 0), 14, 1.2, hs, add_quad)


func _quad(blend: int) -> QuadMesh:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = blend
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = t
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var q := QuadMesh.new()
	q.material = m
	return q


func _ramp(offsets: Array, colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _pm(dir: Vector3, spread: float, vmin: float, vmax: float, gravity: Vector3, size_start: float,
		size_end: float, ramp: Texture2D) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir
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
		quad: Mesh) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.process_material = pm
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-8, -4, -8), Vector3(16, 24, 16))
	p.position = pos
	_add(p, body, nm)
	return p
