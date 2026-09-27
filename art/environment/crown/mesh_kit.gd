extends RefCounted
## Flat-shaded, multi-surface mesh kit for the crown and crystal builders (task A2.3):
## art/environment/crown/build_crown.gd and art/environment/crystal/build_crystal.gd preload it.
## Vertex conventions match env_painted.gdshader (art/environment/build_env.gd):
##   COLOR.rgb  sRGB colour block of the part (per face, with a small painted value jitter)
##   COLOR.a    0 at the mesh bottom -> 1 at its top (baked by commit(), unless the surface keeps its alpha)
##   UV.x       0 (no wind sway), UV.y local height in metres (dark contact band near y = 0)
## A surface can also carry CUSTOM0 (vec4 = `custom` when the face was added) and keep its own COLOR.a
## (the crystal shader reads them as "crystal base + depletion threshold" and "height along the crystal").

class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var cu := PackedFloat32Array()
	var keep_alpha := false
	var has_custom := false


const NO_TOP := Color(0, 0, 0, 0)

var surfs: Dictionary = {}          # name -> Surf
var order: Array[String] = []
var custom := Vector4.ZERO          # CUSTOM0 of the faces added from now on (surfaces with has_custom)
var face_var := 0.12                # per-face value jitter (0 = flat colour)
var _conv := 1.0                    # front-face winding sign of Godot's own primitives


func _init() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


## Declares (or returns) a surface. Surfaces are committed in declaration order.
func surf(name: String, keep_alpha: bool = false, has_custom: bool = false) -> Surf:
	if not surfs.has(name):
		var s := Surf.new()
		s.keep_alpha = keep_alpha
		s.has_custom = has_custom
		surfs[name] = s
		order.append(name)
	return surfs[name]


static func h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


static func h3(p: Vector3) -> Vector3:
	return Vector3(h(p), h(p + Vector3(5.2, 1.3, 7.1)), h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


# ------------------------------------------------------------------------------------------ faces

## One triangle with per-vertex colours; its front face (and flat normal) points along `hint`.
func tri_c(s: String, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, hint: Vector3) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	var sg: float = 1.0 if fn.dot(hint) >= 0.0 else -1.0
	var nn: Vector3 = fn.normalized() * sg
	if sg != _conv:
		var tv: Vector3 = b
		b = c
		c = tv
		var tc: Color = cb
		cb = cc
		cc = tc
	var k: float = 1.0
	if face_var > 0.0:
		k += (h(((a + b + c) / 3.0).snappedf(0.01)) - 0.5) * face_var
	var sf: Surf = surf(s)
	for pair: Array in [[a, ca], [b, cb], [c, cc]]:
		var col: Color = pair[1]
		sf.v.append(pair[0])
		sf.n.append(nn)
		sf.c.append(Color(col.r * k, col.g * k, col.b * k, col.a))
		if sf.has_custom:
			sf.cu.append_array(PackedFloat32Array([custom.x, custom.y, custom.z, custom.w]))


## One triangle in one colour; sky-facing faces get `top` mixed in (moss...; alpha = strength).
func tri(s: String, a: Vector3, b: Vector3, c: Vector3, col: Color, hint: Vector3, top: Color = NO_TOP) -> void:
	var fc: Color = col
	if top.a > 0.0:
		var fn: Vector3 = (b - a).cross(c - a)
		if fn.dot(hint) < 0.0:
			fn = -fn
		fn = fn.normalized()
		var centre: Vector3 = (a + b + c) / 3.0
		if fn.y > 0.7 and h(centre.snappedf(0.01) + Vector3(3, 3, 3)) > 0.35:
			fc = col.lerp(Color(top.r, top.g, top.b), top.a * smoothstep(0.7, 0.95, fn.y))
	tri_c(s, a, b, c, fc, fc, fc, hint)


func quad(s: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, hint: Vector3,
		top: Color = NO_TOP) -> void:
	tri(s, a, b, c, col, hint, top)
	tri(s, a, c, d, col, hint, top)


## A Godot primitive (or any indexed arrays), transformed, jittered (metres, hashed on the source vertex so
## shared corners stay welded), flat-shaded in one colour.
func prim(s: String, m: PrimitiveMesh, xf: Transform3D, col: Color, jitter: float = 0.0, top: Color = NO_TOP,
		seed: float = 0.0) -> void:
	arrays(s, m.get_mesh_arrays(), xf, col, jitter, top, seed)


func arrays(s: String, arr: Array, xf: Transform3D, col: Color, jitter: float = 0.0, top: Color = NO_TOP,
		seed: float = 0.0) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nb: Basis = xf.basis.inverse().transposed()
	var tv := PackedVector3Array()
	tv.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = xf * v[i]
		if jitter > 0.0:
			p += h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter
		tv[i] = p
	for t: int in range(0, idx.size(), 3):
		var hint: Vector3 = nb * (n[idx[t]] + n[idx[t + 1]] + n[idx[t + 2]])
		tri(s, tv[idx[t]], tv[idx[t + 1]], tv[idx[t + 2]], col, hint, top)


## A closed convex-ish block from 4 bottom + 4 top corners (same order around), faces oriented outward.
func block(s: String, bot: Array, top_pts: Array, col: Color, top: Color = NO_TOP, side_col: Color = Color(0, 0, 0, 0)) -> void:
	var centre := Vector3.ZERO
	for p: Vector3 in bot + top_pts:
		centre += p
	centre /= 8.0
	var sc: Color = side_col if side_col.a > 0.0 else col
	for i: int in 4:
		var j: int = (i + 1) % 4
		var a: Vector3 = bot[i]
		var b: Vector3 = bot[j]
		var c: Vector3 = top_pts[j]
		var d: Vector3 = top_pts[i]
		quad(s, a, b, c, d, sc, (a + b + c + d) / 4.0 - centre, top)
	quad(s, top_pts[0], top_pts[1], top_pts[2], top_pts[3], col, Vector3.UP * 0.001 + (top_pts[0] + top_pts[2]) * 0.5 - centre, top)
	quad(s, bot[0], bot[1], bot[2], bot[3], sc.darkened(0.2), (bot[0] + bot[2]) * 0.5 - centre)


# ------------------------------------------------------------------------------------------ sweeps

## A loop of `sides` points around `centre` in the plane (x_axis, z_axis), radii rx / rz, jittered.
static func ring(centre: Vector3, x_axis: Vector3, z_axis: Vector3, rx: float, rz: float, sides: int,
		phase: float = 0.0, jitter: float = 0.0, seed: float = 0.0) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i: int in sides:
		var a: float = phase + i * TAU / sides
		var p: Vector3 = centre + x_axis * cos(a) * rx + z_axis * sin(a) * rz
		if jitter > 0.0 and (rx > 0.0 or rz > 0.0):
			p += h3(Vector3(i, seed, seed * 1.7)) * jitter
		out.append(p)
	return out


## Two unit vectors perpendicular to `t`, the first as close as possible to `ref`.
static func frame(t: Vector3, ref: Vector3) -> Array:
	t = t.normalized()
	var x: Vector3 = ref - t * ref.dot(t)
	if x.length_squared() < 1e-6:
		x = Vector3.RIGHT - t * t.x
	x = x.normalized()
	return [x, t.cross(x)]


## Side walls between consecutive rings (same point count), with optional caps. `seg_surf[i]` /
## `seg_col[i]` pick the surface and colour of the band between ring i and i + 1 (the last entry repeats).
## `centres` are the ring centres (they orient the faces outward). A ring of radius 0 = a pointed tip.
func sweep(rings: Array, centres: Array, seg_surf: Array, seg_col: Array, cap_start: bool = true,
		cap_end: bool = true, top: Color = NO_TOP, cap_surf: String = "") -> void:
	for i: int in rings.size() - 1:
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		var s: String = seg_surf[mini(i, seg_surf.size() - 1)]
		var col: Color = seg_col[mini(i, seg_col.size() - 1)]
		var c0: Vector3 = centres[i]
		var c1: Vector3 = centres[i + 1]
		var m: int = r0.size()
		for j: int in m:
			var k: int = (j + 1) % m
			var a: Vector3 = r0[j]
			var b: Vector3 = r0[k]
			var c: Vector3 = r1[k]
			var d: Vector3 = r1[j]
			var mid: Vector3 = (a + b + c + d) * 0.25
			var axis_pt: Vector3 = (c0 + c1) * 0.5
			var hint: Vector3 = mid - axis_pt
			tri(s, a, b, c, col, hint, top)
			tri(s, a, c, d, col, hint, top)
	if cap_start:
		_cap(rings[0], centres[0], (centres[0] - centres[1]).normalized(),
				cap_surf if cap_surf != "" else seg_surf[0], seg_col[0], top)
	if cap_end:
		var last: int = rings.size() - 1
		_cap(rings[last], centres[last], (centres[last] - centres[last - 1]).normalized(),
				cap_surf if cap_surf != "" else seg_surf[mini(last - 1, seg_surf.size() - 1)],
				seg_col[mini(last - 1, seg_col.size() - 1)], top)


func _cap(r: PackedVector3Array, centre: Vector3, out_dir: Vector3, s: String, col: Color, top: Color) -> void:
	var c := Vector3.ZERO
	for p: Vector3 in r:
		c += p
	c /= float(r.size())
	for j: int in r.size():
		tri(s, c, r[j], r[(j + 1) % r.size()], col, out_dir, top)


## Points along a quadratic-ish spline through `pts` (Catmull-Rom), `steps` samples per span.
static func spline(pts: Array, steps: int) -> Array:
	var out: Array = []
	for i: int in pts.size() - 1:
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, pts.size() - 1)]
		for k: int in steps:
			var t: float = float(k) / steps
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	out.append(pts[pts.size() - 1])
	return out


# ------------------------------------------------------------------------------------------ output

## Builds the ArrayMesh (one surface per declared surface, `mats[name]` on it) and saves it to `path`
## (empty = not saved). COLOR.a gets the mesh-wide height gradient unless the surface keeps its alpha.
func commit(path: String, mats: Dictionary) -> ArrayMesh:
	var miny: float = INF
	var maxy: float = -INF
	for name: String in order:
		var sf: Surf = surfs[name]
		for p: Vector3 in sf.v:
			miny = minf(miny, p.y)
			maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - miny, 0.01)
	var mesh := ArrayMesh.new()
	var tris: int = 0
	for name: String in order:
		var sf: Surf = surfs[name]
		if sf.v.is_empty():
			continue
		var uv := PackedVector2Array()
		uv.resize(sf.v.size())
		for i: int in sf.v.size():
			if not sf.keep_alpha:
				var cc: Color = sf.c[i]
				cc.a = (sf.v[i].y - miny) / span
				sf.c[i] = cc
			uv[i] = Vector2(0.0, sf.v[i].y)
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = sf.v
		arr[Mesh.ARRAY_NORMAL] = sf.n
		arr[Mesh.ARRAY_COLOR] = sf.c
		arr[Mesh.ARRAY_TEX_UV] = uv
		var flags: int = 0
		if sf.has_custom:
			arr[Mesh.ARRAY_CUSTOM0] = sf.cu
			flags = Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		var si: int = mesh.get_surface_count() - 1
		mesh.surface_set_name(si, name)
		if mats.has(name):
			mesh.surface_set_material(si, mats[name])
		tris += sf.v.size() / 3
	if path != "":
		var err: int = ResourceSaver.save(mesh, path, ResourceSaver.FLAG_CHANGE_PATH)
		if err != OK:
			push_error("save failed %s: %d" % [path, err])
		mesh.take_over_path(path)   # so scenes packed afterwards reference the file instead of embedding it
	print("mesh %s: %d surfaces, %d tris, y %.2f..%.2f" % [path.get_file(), mesh.get_surface_count(), tris, miny, maxy])
	return mesh
