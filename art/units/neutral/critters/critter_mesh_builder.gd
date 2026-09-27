class_name CritterMeshBuilder
extends RefCounted
## Mesh builder of the game critters (task 12.V15): lofts, tubes and ellipsoids appended into ONE indexed surface
## with the per-vertex data of critter_painted.gdshader (colour block, bone chain, bone weight, rest height).
## Usage (deer.gd / rabbit.gd): set_bones([[id, pivot], [parent_id, pivot], ...]) (deepest first), set_paint(func),
## optional set_weight(func), then loft / tube / ellipsoid calls, then commit(material).
## Front faces: every triangle is wound so it faces its vertex normals (Godot's front = clockwise), so the builder
## never has to care about the loop direction.

const NO_BONE := Vector4(0.0, 0.0, 0.0, -1.0)

var v := PackedVector3Array()
var n := PackedVector3Array()
var col := PackedColorArray()
var uv := PackedVector2Array()
var c0 := PackedFloat32Array()
var c1 := PackedFloat32Array()
var c2 := PackedFloat32Array()
var idx := PackedInt32Array()

var _chain: Array[Vector4] = [NO_BONE, NO_BONE, NO_BONE]
var _paint: Callable
var _weight: Callable


## chain: [[bone_id, pivot: Vector3], ...], the vertex's own bone first, then its parent, grandparent (max 3).
func set_bones(chain: Array) -> void:
	_chain = [NO_BONE, NO_BONE, NO_BONE]
	for k: int in mini(chain.size(), 3):
		var p: Vector3 = chain[k][1]
		_chain[k] = Vector4(p.x, p.y, p.z, float(chain[k][0]))


## paint: func(p: Vector3, nrm: Vector3) -> Color (sRGB colour block of the vertex, model space).
func set_paint(paint: Callable) -> void:
	_paint = paint


## weight: func(p: Vector3) -> float (0-1, scales the own bone's angles), or Callable() = 1.
func set_weight(weight: Callable) -> void:
	_weight = weight


func triangle_count() -> int:
	return idx.size() / 3


func vert(p: Vector3, nr: Vector3) -> int:
	var i: int = v.size()
	var nn := nr.normalized()
	v.append(p)
	n.append(nn)
	col.append(_paint.call(p, nn) if _paint.is_valid() else Color.WHITE)
	var w: float = 1.0
	if _weight.is_valid():
		w = clampf(float(_weight.call(p)), 0.0, 1.0)
	uv.append(Vector2(w, p.y))
	var b: Vector4 = _chain[0]
	c0.append_array(PackedFloat32Array([b.x, b.y, b.z, b.w]))
	b = _chain[1]
	c1.append_array(PackedFloat32Array([b.x, b.y, b.z, b.w]))
	b = _chain[2]
	c2.append_array(PackedFloat32Array([b.x, b.y, b.z, b.w]))
	return i


func tri(a: int, b: int, c: int) -> void:
	var front := -(v[b] - v[a]).cross(v[c] - v[a])
	if front.dot(n[a] + n[b] + n[c]) < 0.0:
		var t := b
		b = c
		c = t
	idx.append(a)
	idx.append(b)
	idx.append(c)


## Quads between two rings of `seg` vertices each (wrapping).
func strip(r0: int, r1: int, seg: int) -> void:
	for k: int in seg:
		var k1: int = (k + 1) % seg
		tri(r0 + k, r0 + k1, r1 + k)
		tri(r0 + k1, r1 + k1, r1 + k)


func fan(center: int, ring: int, seg: int) -> void:
	for k: int in seg:
		tri(center, ring + k, ring + (k + 1) % seg)


## Frame of a path at a point: side (rx axis) and up (ry axis), from the tangent and a reference "side" hint.
static func frame(t: Vector3, ref: Vector3) -> Array[Vector3]:
	var up := t.cross(ref)
	if up.length_squared() < 1e-6:
		up = t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.FORWARD)
	up = up.normalized()
	var side := up.cross(t).normalized()
	return [side, up]


## Elliptic loft through `c` (stations), half-sizes rx (along the side axis) / ry (up axis), `seg` sides, angle 0 = up.
## A radius <= 0 at the first / last station = a pointed tip (one vertex). cap0 / cap1 close flat ends with a fan.
func loft(c: Array[Vector3], rx: Array[float], ry: Array[float], seg: int, cap0: bool = false, cap1: bool = false,
		ref: Vector3 = Vector3.RIGHT) -> void:
	var count: int = c.size()
	var rings: Array[int] = []
	for i: int in count:
		var t := (c[mini(i + 1, count - 1)] - c[maxi(i - 1, 0)]).normalized()
		var fr := frame(t, ref)
		if rx[i] <= 0.0 or ry[i] <= 0.0:
			rings.append(-1 - vert(c[i], t if i == count - 1 else -t))
			continue
		var start: int = v.size()
		for k: int in seg:
			var a: float = TAU * float(k) / float(seg)
			var p := c[i] + fr[0] * sin(a) * rx[i] + fr[1] * cos(a) * ry[i]
			var nr := fr[0] * sin(a) / rx[i] + fr[1] * cos(a) / ry[i]
			vert(p, nr)
		rings.append(start)
	for i: int in count - 1:
		var a: int = rings[i]
		var b: int = rings[i + 1]
		if a < 0 and b >= 0:
			fan(-1 - a, b, seg)
		elif b < 0 and a >= 0:
			fan(-1 - b, a, seg)
		elif a >= 0 and b >= 0:
			strip(a, b, seg)
	if cap0 and rings[0] >= 0:
		var t0 := (c[0] - c[1]).normalized()
		fan(vert(c[0] + t0 * minf(rx[0], ry[0]) * 0.35, t0), rings[0], seg)
	if cap1 and rings[count - 1] >= 0:
		var t1 := (c[count - 1] - c[count - 2]).normalized()
		fan(vert(c[count - 1] + t1 * minf(rx[count - 1], ry[count - 1]) * 0.35, t1), rings[count - 1], seg)


## Round tube (loft with rx = ry = radius).
func tube(pts: Array[Vector3], radii: Array[float], seg: int, cap0: bool = false, cap1: bool = false,
		ref: Vector3 = Vector3.RIGHT) -> void:
	loft(pts, radii, radii, seg, cap0, cap1, ref)


## UV ellipsoid with single-vertex poles: 2 x seg x (rings - 1) triangles. Its poles lie on the basis' y axis.
func ellipsoid(center: Vector3, r: Vector3, seg: int, rings: int, basis: Basis = Basis.IDENTITY) -> void:
	var top: int = vert(center + basis * Vector3(0, r.y, 0), basis * Vector3.UP)
	var prev: int = -1
	for j: int in range(1, rings):
		var ph: float = PI * float(j) / float(rings)
		var start: int = v.size()
		for k: int in seg:
			var a: float = TAU * float(k) / float(seg)
			var unit := Vector3(sin(ph) * sin(a), cos(ph), sin(ph) * cos(a))
			var p := center + basis * (unit * r)
			var nr := basis * Vector3(unit.x / r.x, unit.y / r.y, unit.z / r.z)
			vert(p, nr)
		if prev < 0:
			fan(top, start, seg)
		else:
			strip(prev, start, seg)
		prev = start
	var bottom: int = vert(center + basis * Vector3(0, -r.y, 0), basis * Vector3.DOWN)
	fan(bottom, prev, seg)


## The finished single surface (one material), custom channels as RGBA floats.
func commit(mat: Material) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_COLOR] = col
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_CUSTOM0] = c0
	arrays[Mesh.ARRAY_CUSTOM1] = c1
	arrays[Mesh.ARRAY_CUSTOM2] = c2
	arrays[Mesh.ARRAY_INDEX] = idx
	var flags: int = (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) \
		| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
		| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	am.surface_set_material(0, mat)
	return am


## Colour helpers for the paint callbacks.
static func mixc(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, clampf(t, 0.0, 1.0))


static func band(x: float, a: float, b: float) -> float:
	return smoothstep(a, b, x)
