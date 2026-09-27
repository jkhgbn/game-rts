extends SceneTree
## Task 12.V14 (docs/design/map-fill.md 3.2 and 10): Landmarks B. Generates, with the SHARED painted nature material
## (nature_props/nature_mat.tres: stone / bark / ivy kinds) + its contact-shadow material:
##   aqueduct.tscn         Old Aqueduct: two broken arches over the north river on three piers (the middle one stands in
##                         the water); colliders: the two bank piers, cylinders r 0.9 (the arches are draw-only)
##   barge.tscn            Drowned Barge: a half-sunk river barge, stern under water, broken mast, torn sail over the
##                         side, cargo; draw-only (it lies in deep water)
##   standing_stones.tscn  Standing Stones: 6 leaning menhirs in a ring r 3 (one fallen and broken), faint carved runes
##                         (landmarks/stones_rune_mat.tres), a low altar slab; colliders: 6 cylinders r 0.5
## Meshes go to landmarks/meshes/<name>.res (surface 0 painted, then the contact discs, then the runes if any).
##
## Placement (for the systems glue): each scene's origin IS the landmark's spot of map-fill.md 3.2, y 0:
##   aqueduct  (-13.4, 0, -55)  = the midpoint of the piers (-17.5, -55) / (-9.3, -55); local +X runs west -> east
##   barge     (-6.2, 0, -24.5) (the river's centre line there; the model is already turned along the flow)
##   stones    (-54, 0, 20)     (the ring centre)
##   Player side: rotation 0. The mirror side: position -p, rotation.y = PI (point mirror, colliders included).
## Same layout as Landmarks A (build_landmarks_a.gd): root Node3D in group "landmarks" with metadata `landmark_id`
## (StringName), `decor_clear_radius` (float, m) and `foam_rocks` (PackedVector3Array of local (x, z, radius) circles
## for water.gdshader's `foam_rocks`: the middle pier + the fallen stones, the barge; the shader fills each circle
## white, so they stay inside what pokes out of the water) > "Model" (MeshInstance3D) + "Collision" (StaticBody3D,
## layer 1, mask 0) with CylinderShape3D children sized as 3.2, 1.8 m tall (under the 2 m agent height). Put the scene
## under the NavigationRegion3D before the bake (like the other obstacles), or free "Collision" if the map builds its own.
##
## Re-run after changing a shape (then look at the previews, landmarks_b_preview.gd):
##   $GODOT --headless --path . -s res://art/environment/landmarks/build_landmarks_b.gd --quit-after 600

const LDIR := "res://art/environment/landmarks/"
const MESH_DIR := "res://art/environment/landmarks/meshes/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }

# --- palette (sRGB) -------------------------------------------------------------------------------
# Aqueduct: warm weathered limestone, paler than the cliffs so the arches read against them.
const LIME := Color(0.62, 0.58, 0.51)
const LIME_L := Color(0.70, 0.66, 0.58)
const LIME_D := Color(0.47, 0.44, 0.39)
const LIME_C := Color(0.56, 0.56, 0.54)       # cooler blocks mixed in
const CHANNEL := Color(0.30, 0.27, 0.21)      # silted channel floor
# Standing stones: blue-grey granite (darker than the ruins, cool against the warm heath).
const GRAN := Color(0.42, 0.43, 0.46)
const GRAN_W := Color(0.47, 0.45, 0.42)
const GRAN_D := Color(0.31, 0.31, 0.34)
const RUNE := Color(0.36, 0.88, 0.76)          # moss-teal (no kingdom glow uses it)
# Barge: river-soaked timber.
const HULL := Color(0.38, 0.27, 0.17)
const HULL_D := Color(0.27, 0.19, 0.13)
const HULL_L := Color(0.47, 0.35, 0.22)
const DECK := Color(0.56, 0.46, 0.33)
const DECK_D := Color(0.44, 0.36, 0.26)
const WOOD_GREY := Color(0.52, 0.48, 0.42)     # sun-bleached rails and spars
const INSIDE := Color(0.10, 0.08, 0.07)
const IRON := Color(0.24, 0.23, 0.24)
const SAIL := Color(0.80, 0.73, 0.56)
const SAIL_STRIPE := Color(0.58, 0.33, 0.22)
const ROPE := Color(0.62, 0.52, 0.34)
const SACK := Color(0.66, 0.58, 0.42)
const SALT := Color(0.86, 0.85, 0.80)
const ROOF := Color(0.36, 0.33, 0.27)          # weathered shingles (no team red)
# Greens (ivy kind: never turns autumn).
const IVY := Color(0.16, 0.33, 0.13)
const IVY_L := Color(0.28, 0.47, 0.17)
const WEED := Color(0.20, 0.36, 0.18)

const WATER_Y := -0.35
## Collider height: under the navmesh agent height (2.0), like Landmarks A: a taller closed shape would leave >= 2 m of
## free space between the ground and its cap, and Recast would bake a walkable island inside it.
const COLLIDER_H := 1.8

var mat: Material
var contact_mat: Material
var rune_mat: ShaderMaterial
var _conv: float = 1.0
var _pre := Transform3D.IDENTITY     # applied after each part's own transform (the barge's sink / yaw)

# Current mesh: painted surface, contact discs, runes.
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _w := PackedFloat32Array()      # UV.x: stone moss amount / foliage wind weight
var _uv2 := PackedVector2Array()    # (variant mask 0, kind)
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
var _rv := PackedVector3Array()
var _rn := PackedVector3Array()
var _rc := PackedColorArray()
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	_make_materials()
	_build_aqueduct()
	_build_barge()
	_build_stones()
	for line: String in _report:
		print(line)
	print("LANDMARKS B BUILD OK")
	quit()


# --- materials / saving --------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _save_ref(res: Resource, path: String) -> Resource:
	_save(res, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


func _make_materials() -> void:
	mat = load(NDIR + "nature_mat.tres") as Material
	contact_mat = load(NDIR + "nature_contact_mat.tres") as Material
	var rm := ShaderMaterial.new()
	rm.shader = load(LDIR + "stones_rune.gdshader") as Shader
	rune_mat = _save_ref(rm, LDIR + "stones_rune_mat.tres") as ShaderMaterial


# --- small math ----------------------------------------------------------------------------------

func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


## A basis whose local +Y runs along a -> b.
func _along(a: Vector3, b: Vector3) -> Basis:
	var y: Vector3 = (b - a).normalized()
	var x: Vector3 = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _begin() -> void:
	_v = PackedVector3Array()
	_n = PackedVector3Array()
	_c = PackedColorArray()
	_w = PackedFloat32Array()
	_uv2 = PackedVector2Array()
	_cv = PackedVector3Array()
	_cn = PackedVector3Array()
	_cuv = PackedVector2Array()
	_cuv2 = PackedVector2Array()
	_rv = PackedVector3Array()
	_rn = PackedVector3Array()
	_rc = PackedColorArray()
	_pre = Transform3D.IDENTITY


# --- primitive arrays ----------------------------------------------------------------------------

func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


func _cyl(top: float, bottom: float, h: float, segs: int = 6, rings: int = 0) -> Array:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


func _sph(r: float, segs: int = 7, rings: int = 4) -> Array:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


func _box(size: Vector3, sub: int = 0) -> Array:
	var m := BoxMesh.new()
	m.size = size
	m.subdivide_width = sub
	m.subdivide_height = sub
	m.subdivide_depth = sub
	return m.get_mesh_arrays()


## A closed loft through rings of equal vertex count (convex-ish sections). Side normals point away from each
## ring's centroid, cap normals away from the whole shape's centre: _part uses them only to pick the winding.
## `apex_first` / `apex_last` (optional) pull the cap fan to a point (pointed or slanted ends).
func _loft(rings: Array, cap_first: bool = true, cap_last: bool = true, apex_first: Variant = null,
		apex_last: Variant = null) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var cents: Array[Vector3] = []
	var centre := Vector3.ZERO
	var count: int = 0
	for r: PackedVector3Array in rings:
		var c := Vector3.ZERO
		for p: Vector3 in r:
			c += p
		c /= float(r.size())
		cents.append(c)
		centre += c
		count += 1
	centre /= float(count)
	var m: int = (rings[0] as PackedVector3Array).size()
	for k: int in rings.size() - 1:
		var r0: PackedVector3Array = rings[k]
		var r1: PackedVector3Array = rings[k + 1]
		for i: int in m:
			var j: int = (i + 1) % m
			var base: int = v.size()
			v.append_array([r0[i], r0[j], r1[j], r1[i]])
			n.append_array([(r0[i] - cents[k]).normalized(), (r0[j] - cents[k]).normalized(),
				(r1[j] - cents[k + 1]).normalized(), (r1[i] - cents[k + 1]).normalized()])
			idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var caps: Array = []
	if cap_first:
		caps.append([0, apex_first])
	if cap_last:
		caps.append([rings.size() - 1, apex_last])
	for cp: Array in caps:
		var k2: int = cp[0]
		var ring: PackedVector3Array = rings[k2]
		var tip: Vector3 = cents[k2] if cp[1] == null else (cp[1] as Vector3)
		var cn: Vector3 = (cents[k2] - centre).normalized()
		if cn.length_squared() < 0.5:
			cn = Vector3.UP
		var base2: int = v.size()
		v.append(tip)
		n.append(cn)
		for i: int in m:
			v.append(ring[i])
			n.append(cn)
		for i: int in m:
			idx.append_array([base2, base2 + 1 + i, base2 + 1 + (i + 1) % m])
	return _mk(v, n, idx)


## A ring of points from a 2D polygon (x, z) at height y.
func _ring_xz(poly: PackedVector2Array, y: float, off := Vector2.ZERO, s := 1.0) -> PackedVector3Array:
	var out := PackedVector3Array()
	for p: Vector2 in poly:
		out.append(Vector3(off.x + p.x * s, y, off.y + p.y * s))
	return out


## A 2D polygon (x, y) extruded along z from z0 to z1 (voussoirs, wall pieces seen from the front).
func _prism_z(poly_xy: PackedVector2Array, z0: float, z1: float) -> Array:
	var a := PackedVector3Array()
	var b := PackedVector3Array()
	for p: Vector2 in poly_xy:
		a.append(Vector3(p.x, p.y, z0))
		b.append(Vector3(p.x, p.y, z1))
	return _loft([a, b])


# --- the part appender (flat painted shading, like build_nature.gd) ------------------------------

## Adds mesh arrays, transformed by xf then by _pre. Options: kind (Kind), jitter (m), seed, jit_axes (Vector3),
## normals "flat" | "smooth", col2 + grad ("y" | "r"), moss (UV.x: stone moss / foliage wind weight), no_caps,
## tint (per-face value variation), rune (true: goes to the rune surface, `phase` 0-1 in COLOR.a).
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.STONE)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var jit_axes: Vector3 = o.get("jit_axes", Vector3.ONE)
	var mode: String = o.get("normals", "flat")
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var moss: float = o.get("moss", 0.0)
	var no_caps: bool = o.get("no_caps", false)
	var tint: float = o.get("tint", 0.08)
	var rune: bool = o.get("rune", false)
	var phase: float = o.get("phase", 0.0)
	var full: Transform3D = _pre * xf
	var nb: Basis = full.basis.inverse().transposed()
	var miny: float = INF
	var maxy: float = -INF
	var maxr: float = 0.001
	for p: Vector3 in v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
		maxr = maxf(maxr, Vector2(p.x, p.z).length())
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	tv.resize(v.size())
	tn.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter * jit_axes
		tv[i] = full * p
		tn[i] = (nb * n[i]).normalized()
	for t: int in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		if no_caps and absf(n[a].y) > 0.99 and absf(n[b].y) > 0.99 and absf(n[c].y) > 0.99:
			continue
		var fn: Vector3 = (tv[b] - tv[a]).cross(tv[c] - tv[a])
		if fn.length_squared() < 1e-12:
			continue
		fn = fn.normalized()
		var s: float = 1.0 if fn.dot(tn[a] + tn[b] + tn[c]) >= 0.0 else -1.0
		if s != _conv:
			var tmp: int = b
			b = c
			c = tmp
		fn *= s
		var fk: float = 1.0 + (_h(((tv[a] + tv[b] + tv[c]) / 3.0).snappedf(0.01)) - 0.5) * tint
		for vi: int in [a, b, c]:
			var nn: Vector3 = fn if mode == "flat" else tn[vi]
			var gt: float = 0.0
			if grad == "y":
				gt = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
			else:
				gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
			var cc: Color = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			if rune:
				_rv.append(tv[vi])
				_rn.append(nn)
				_rc.append(Color(cc.r, cc.g, cc.b, phase))
			else:
				_v.append(tv[vi])
				_n.append(nn)
				_c.append(Color(cc.r * k, cc.g * k, cc.b * k))
				_w.append(moss)
				_uv2.append(Vector2(0.0, kind))


func _stone(arr: Array, xf: Transform3D, col: Color, seed: float, moss: float = 0.6, jitter: float = 0.02,
		tint: float = 0.07) -> void:
	_part(arr, xf, col, {"kind": Kind.STONE, "moss": moss, "jitter": jitter, "seed": seed, "tint": tint})


func _wood(arr: Array, xf: Transform3D, col: Color, seed: float = 0.0, jitter: float = 0.0, tint: float = 0.08) -> void:
	_part(arr, xf, col, {"kind": Kind.BARK, "jitter": jitter, "seed": seed, "tint": tint})


## A limb (tapered cylinder) from a to b.
func _limb(a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Color, o: Dictionary = {}) -> void:
	var len: float = a.distance_to(b)
	var oo: Dictionary = o.duplicate()
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	if not oo.has("kind"):
		oo["kind"] = Kind.BARK
	_part(_cyl(r1, r0, len, segs), Transform3D(_along(a, b), (a + b) * 0.5), col, oo)


## A chiselled rock chunk (build_nature.gd's recipe): a low-poly ellipsoid cut by random planes.
func _chunk(radii: Vector3, cuts: int, seed: float, top: float = 0.78, segs: int = 6, rings: int = 4) -> Array:
	var arr: Array = _sph(1.0, segs, rings)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var planes: Array = []
	for k: int in cuts:
		var a: float = _h(Vector3(seed, k, 1.0)) * TAU
		var tilt: float = lerpf(-0.35, 0.55, _h(Vector3(seed, k, 2.0)))
		var pn := Vector3(cos(a) * cos(tilt), sin(tilt), sin(a) * cos(tilt)).normalized()
		planes.append([pn, 0.66 + 0.22 * _h(Vector3(seed, k, 3.0))])
	var ta: float = _h(Vector3(seed, 9.0, 4.0)) * TAU
	planes.append([Vector3(cos(ta) * 0.18, 1.0, sin(ta) * 0.18).normalized(), top])
	var out := PackedVector3Array()
	out.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = v[i] + _h3(v[i].snappedf(0.001) + Vector3(seed, seed, seed)) * 0.07
		for pl: Array in planes:
			var pn2: Vector3 = pl[0]
			var over: float = p.dot(pn2) - float(pl[1])
			if over > 0.0:
				p -= pn2 * over
		out[i] = p * radii
	var n2 := PackedVector3Array()
	n2.resize(n.size())
	for i: int in n.size():
		n2[i] = (n[i] / radii).normalized()
	return _mk(out, n2, arr[Mesh.ARRAY_INDEX])


## Soft contact shadow disc (surface 1) just above the ground, in scene space (not moved by _pre).
func _disc(c: Vector3, rx: float, rz: float, segs: int, seed: float, rot: float = 0.0) -> void:
	var ring: Array[Vector3] = []
	var b := Basis(Vector3.UP, rot)
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.3
		ring.append(Vector3(c.x, 0.035, c.z) + b * Vector3(cos(a) * rx * j, 0.0, sin(a) * rz * j))
	var centre := Vector3(c.x, 0.035, c.z)
	for i: int in segs:
		var p1: Vector3 = ring[i]
		var p2: Vector3 = ring[(i + 1) % segs]
		var fn: Vector3 = (p1 - centre).cross(p2 - centre)
		var up: bool = fn.y >= 0.0
		var tri: Array = [centre, p1, p2] if (1.0 if up else -1.0) == _conv else [centre, p2, p1]
		var uvs: Array = [0.0, 1.0, 1.0]
		for k: int in 3:
			_cv.append(tri[k])
			_cn.append(Vector3.UP)
			_cuv.append(Vector2(uvs[k], 0.0))
			_cuv2.append(Vector2(0.0, 0.0))


# --- commit --------------------------------------------------------------------------------------

## Bakes the height gradient (COLOR.a: 0 at y_lo -> 1 at the mesh top), moss / wind (UV.x), local height (UV.y),
## kind (UV2.y) and saves landmarks/meshes/<name>.res: surface 0 nature_mat, then contact discs, then runes.
func _commit(name: String, y_lo: float = 0.0) -> ArrayMesh:
	var maxy: float = -INF
	var miny: float = INF
	for p: Vector3 in _v:
		maxy = maxf(maxy, p.y)
		miny = minf(miny, p.y)
	var span: float = maxf(maxy - y_lo, 0.01)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = clampf((_v[i].y - y_lo) / span, 0.0, 1.0)
		_c[i] = cc
		uv[i] = Vector2(_w[i], _v[i].y)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = _uv2
	var mesh := ArrayMesh.new()
	var welded: Array = _weld(arrays)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, welded)
	mesh.surface_set_material(0, mat)
	var info := "mesh %-16s %5d tris, %5d verts" % [name, _v.size() / 3,
		(welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()]
	if not _cv.is_empty():
		var ca: Array = []
		ca.resize(Mesh.ARRAY_MAX)
		ca[Mesh.ARRAY_VERTEX] = _cv
		ca[Mesh.ARRAY_NORMAL] = _cn
		ca[Mesh.ARRAY_TEX_UV] = _cuv
		ca[Mesh.ARRAY_TEX_UV2] = _cuv2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(ca))
		mesh.surface_set_material(mesh.get_surface_count() - 1, contact_mat)
		info += ", contact %d" % (_cv.size() / 3)
	if not _rv.is_empty():
		var ra: Array = []
		ra.resize(Mesh.ARRAY_MAX)
		var ruv := PackedVector2Array()
		for p: Vector3 in _rv:
			ruv.append(Vector2(0.0, p.y))
		ra[Mesh.ARRAY_VERTEX] = _rv
		ra[Mesh.ARRAY_NORMAL] = _rn
		ra[Mesh.ARRAY_COLOR] = _rc
		ra[Mesh.ARRAY_TEX_UV] = ruv
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(ra))
		mesh.surface_set_material(mesh.get_surface_count() - 1, rune_mat)
		info += ", runes %d" % (_rv.size() / 3)
	mesh = _save_ref(mesh, MESH_DIR + name + ".res") as ArrayMesh
	_report.append(info + ", y %.2f..%.2f" % [miny, maxy])
	return mesh


## Non-indexed triangles -> indexed (merge vertices whose every attribute matches).
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


# --- scenes --------------------------------------------------------------------------------------

func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


## landmarks/<file>.tscn, the same layout as Landmarks A (build_landmarks_a.gd): Node3D root in group "landmarks"
## (metadata landmark_id, decor_clear_radius, foam_rocks) > "Model" (MeshInstance3D) + "Collision" (StaticBody3D,
## layer 1, mask 0) > one CylinderShape3D per [name, Vector3 base centre, radius, height].
func _scene(file: String, root_name: String, id: StringName, mesh: Mesh, colliders: Array, foam: PackedVector3Array,
		clear_r: float) -> void:
	var root := Node3D.new()
	root.name = root_name
	root.add_to_group(&"landmarks", true)
	root.set_meta(&"landmark_id", id)
	root.set_meta(&"decor_clear_radius", clear_r)
	root.set_meta(&"foam_rocks", foam)
	var mi := MeshInstance3D.new()
	mi.name = "Model"
	mi.mesh = mesh
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	root.add_child(mi)
	if not colliders.is_empty():
		var body := StaticBody3D.new()
		body.name = "Collision"
		body.collision_layer = 1
		body.collision_mask = 0
		root.add_child(body)
		for c: Array in colliders:
			var cs := CollisionShape3D.new()
			cs.name = String(c[0])
			var shape := CylinderShape3D.new()
			shape.radius = float(c[2])
			shape.height = float(c[3])
			cs.shape = shape
			cs.position = (c[1] as Vector3) + Vector3(0.0, float(c[3]) * 0.5, 0.0)
			body.add_child(cs)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, LDIR + file)
	root.free()


# =================================================================================================
# OLD AQUEDUCT
# Local frame: origin = midpoint of the bank piers, +X west -> east (piers at x -4.1 / +4.1), the river flows along
# ~+Z (tilted 12.7 deg: its centre line is x = 0.23 z, water |x| < 2.56). Ground y 0, water -0.35, trench bed -1.0.
# Bay W (x -3.38..-0.62) keeps its whole arch (the keystone has slipped); bay E (0.62..3.38) has collapsed: only the
# springers stand, its stones lie in the river. The west bank pier still carries a springer of the next (lost) bay,
# the east bank pier is broken off at ~3.6 m. The channel on top runs from the west remnant to the gap.
# =================================================================================================

const AQ_HD := 0.8          # half depth of the wall (z)
const PIER_X := 4.1
const PIER_HW := 0.72
const MID_HW := 0.62
const Y_SPRING := 3.2
const R_IN := 1.38
const R_OUT := 1.88
const Y_CORNICE := 5.32
const Y_TOP := 5.56
const COURSE := 0.42
const ARCHES: Array[float] = [-6.2, -2.0, 2.0]   # arch centres (the first one is the lost bay beyond pier W)


## Keeps a wall block whose centre is (x, y)? The ruin's outline.
func _aq_keep(x: float, y: float, seed: float) -> bool:
	var jag: float = (_h(Vector3(x * 3.1, y * 2.3, seed)) - 0.5) * 0.5
	if x < -PIER_X - PIER_HW:   # beyond pier W: the springer's spandrel, stepping down to the west
		return x > -5.55 + (y - Y_CORNICE) * -0.25 + jag * 0.4 and y > Y_SPRING + 0.6
	if x > MID_HW and x < PIER_X - PIER_HW:   # the collapsed bay E
		var west_edge: float = 1.55 - (y - Y_SPRING) * 0.42 + jag
		var east_edge: float = 2.75 + (y - Y_SPRING) * 0.9 + jag
		return x < west_edge or (x > east_edge and y < Y_SPRING + 1.15)
	if x >= PIER_X - PIER_HW:   # pier E broken off
		return y < Y_SPRING + 0.75 + jag * 0.9
	return true


func _build_aqueduct() -> void:
	_begin()
	var seed := 100.0
	# --- bank piers: sunken skirt + plinth + masonry shaft + impost band ---
	for sx: float in [-1.0, 1.0]:
		var px: float = PIER_X * sx
		_stone(_box(Vector3(2.2, 0.36, 2.3)), _xf(Vector3(px, 0.0, 0.0), Vector3(0.0, 0.04 * sx, 0.0)), LIME_D.darkened(0.08),
			seed, 0.9, 0.05)
		_stone(_loft([_ring_xz(_rect(0.98, 1.02), 0.12), _ring_xz(_rect(0.86, 0.92), 0.55)]),
			_xf(Vector3(px, 0.0, 0.0)), LIME_D, seed + 1.0, 0.8, 0.03)
		_masonry(px - PIER_HW, px + PIER_HW, 0.55, Y_SPRING - 0.22, seed + 2.0 + sx, true)
		seed += 10.0
	# --- the middle pier, standing in the river: cutwater footing + sloped cap + shaft ---
	var cut := PackedVector2Array([Vector2(0.86, -0.95), Vector2(0.0, -1.55), Vector2(-0.86, -0.95),
		Vector2(-0.86, 0.95), Vector2(0.0, 1.55), Vector2(0.86, 0.95)])
	var cut_top := PackedVector2Array([Vector2(0.7, -0.84), Vector2(0.0, -0.9), Vector2(-0.7, -0.84),
		Vector2(-0.7, 0.84), Vector2(0.0, 0.9), Vector2(0.7, 0.84)])
	_stone(_loft([_ring_xz(cut, -1.15), _ring_xz(cut, 0.3), _ring_xz(cut_top, 0.82)]), _xf(Vector3.ZERO),
		LIME_D.darkened(0.05), 130.0, 0.7, 0.03)
	_masonry(-MID_HW, MID_HW, 0.82, Y_SPRING - 0.22, 131.0, true)
	# --- impost bands where the arches spring ---
	for ix: float in [-PIER_X, 0.0, PIER_X]:
		var hw: float = (PIER_HW if ix != 0.0 else MID_HW) + 0.12
		_stone(_box(Vector3(hw * 2.0, 0.22, AQ_HD * 2.0 + 0.22)), _xf(Vector3(ix, Y_SPRING - 0.11, 0.0)), LIME_L,
			140.0 + ix, 0.8, 0.02)
	# --- arch rings (proud of the wall so they read as rings) ---
	# Bay W: the whole ring, 11 voussoirs, the keystone slipped 0.14 m.
	_arch_ring(ARCHES[1], 0.0, PI, 11, 150.0, 5)
	# Bay E: the springers only (3 from the middle pier, 2 from pier E) + one loose voussoir about to fall.
	var step: float = PI / 11.0
	_arch_ring(ARCHES[2], PI - step * 3.0, PI, 3, 170.0, -1)
	_arch_ring(ARCHES[2], 0.0, step * 2.0, 2, 175.0, -1)
	_voussoir(ARCHES[2], PI - step * 4.0, PI - step * 3.0, 178.0, Vector3(0.1, -0.1, 0.05), 0.0, true)
	# The lost bay beyond pier W: its springer (4 voussoirs, it carries the remnant of its spandrel).
	_arch_ring(ARCHES[0], 0.0, step * 4.0, 4, 180.0, -1)
	# --- spandrel walls between Y_SPRING and the cornice, cut around the arches, broken per _aq_keep ---
	_spandrels(-7.0, PIER_X + PIER_HW, 190.0)
	# --- cornice (string course) and the channel on top: from the west remnant to the gap ---
	var x_w := -5.25
	var x_e := 1.0
	var x := x_w
	var i := 0
	while x < x_e - 0.05:
		var len: float = minf(0.9 + _h(Vector3(i, 3.0, 7.0)) * 0.5, x_e - x)
		var sag: float = -0.04 if i % 3 == 1 else 0.0
		_stone(_box(Vector3(len, 0.24, AQ_HD * 2.0 + 0.28)), _xf(Vector3(x + len * 0.5, Y_CORNICE + 0.12 + sag, 0.0),
			Vector3(0.0, 0.0, (_h(Vector3(i, 1.0, 2.0)) - 0.5) * 0.03)), LIME_L.lerp(LIME_C, _h(Vector3(i, 2, 2)) * 0.5),
			200.0 + i, 0.6, 0.02)
		x += len
		i += 1
	_channel(x_w + 0.1, x_e - 0.15, 220.0)
	# The broken ends: a few blocks hanging over the gap and over the west remnant.
	_stone(_box(Vector3(0.55, 0.4, 0.42)), _xf(Vector3(1.05, Y_TOP + 0.18, 0.52), Vector3(0.0, 0.1, -0.35)), LIME, 240.0)
	_stone(_box(Vector3(0.5, 0.36, 0.4)), _xf(Vector3(-5.3, Y_TOP + 0.1, -0.5), Vector3(0.05, -0.15, 0.3)), LIME_D, 241.0)
	# --- the fallen bay in the river: voussoirs and wall chunks half out of the water (draw-only) ---
	var fall: Array = [[Vector3(1.05, -0.62, 0.55), Vector3(0.62, 0.5, 0.95), Vector3(0.3, 0.4, 0.5)],
		[Vector3(1.85, -0.55, -0.35), Vector3(0.75, 0.62, 1.1), Vector3(-0.45, 1.2, 0.2)],
		[Vector3(2.35, -0.72, 0.75), Vector3(0.55, 0.45, 0.8), Vector3(0.6, 2.2, -0.3)],
		[Vector3(1.35, -0.78, -1.1), Vector3(0.5, 0.42, 0.7), Vector3(0.2, 0.7, 0.55)],
		[Vector3(0.95, -0.7, 1.45), Vector3(0.45, 0.4, 0.6), Vector3(-0.3, 1.8, 0.4)],
		[Vector3(2.1, -0.8, -1.35), Vector3(0.9, 0.5, 0.55), Vector3(0.1, 0.4, -0.2)]]
	var k := 0
	for f: Array in fall:
		_stone(_box(f[1]), _xf(f[0], f[2]), LIME.lerp(LIME_D, 0.3 + 0.2 * (k % 2)), 250.0 + k, 0.7, 0.05)
		k += 1
	# A big slab of the lost wall, tilted against the middle pier's cutwater.
	_stone(_box(Vector3(1.3, 0.34, 1.2)), _xf(Vector3(1.25, -0.28, -0.1), Vector3(0.12, 0.3, 0.38)), LIME_C, 262.0, 0.9, 0.04)
	# --- rubble on the banks (flat, walk-through height < 0.3 m) and at the pier feet ---
	for r: Array in [[Vector3(5.25, 0.06, 0.55), 0.3], [Vector3(5.1, 0.05, -0.75), 0.24], [Vector3(-5.35, 0.05, 0.6), 0.26],
			[Vector3(5.6, 0.04, -0.1), 0.2], [Vector3(-5.2, 0.05, -0.9), 0.22], [Vector3(3.2, 0.06, 1.25), 0.24],
			[Vector3(-3.2, 0.05, -1.25), 0.22]]:
		var rp: Vector3 = r[0]
		var rs: float = r[1]
		_stone(_chunk(Vector3(rs * 1.3, rs * 0.7, rs), 4, rp.x * 7.0 + rp.z), _xf(rp), LIME_D.lerp(LIME, 0.4),
			rp.x * 3.0 + rp.z, 0.6, 0.0)
	# --- ivy curtains from the cornice (both faces: the mirrored copy shows its north face to the camera) ---
	for iv: Array in [[-2.95, 1.0, 7], [-0.3, 1.0, 8], [-4.5, 1.0, 5], [-3.55, -1.0, 8], [-1.3, -1.0, 4],
			[0.35, -1.0, 6], [-5.05, -1.0, 4], [3.95, 1.0, 4], [4.35, -1.0, 5]]:
		var top_y: float = Y_CORNICE if float(iv[0]) < 1.2 else Y_SPRING + 0.55
		_ivy_curtain(float(iv[0]), top_y, float(iv[1]), int(iv[2]), 300.0 + float(iv[0]) * 5.0 + float(iv[1]))
	# Moss / grass tufts along the top, at the broken tops and at the pier feet.
	for t: Array in [[Vector3(-4.6, Y_TOP + 0.6, 0.58), 0.22], [Vector3(-3.4, Y_TOP + 0.6, -0.6), 0.18],
			[Vector3(-1.5, Y_TOP + 0.6, 0.62), 0.2], [Vector3(0.6, Y_TOP + 0.6, -0.58), 0.24],
			[Vector3(-2.3, Y_TOP + 0.16, 0.0), 0.26], [Vector3(-0.6, Y_TOP + 0.16, 0.05), 0.22],
			[Vector3(4.0, Y_SPRING + 0.85, 0.2), 0.3], [Vector3(4.35, Y_SPRING + 0.75, -0.35), 0.24],
			[Vector3(-5.1, Y_SPRING + 1.5, 0.1), 0.22],
			[Vector3(-4.1, 0.55, 0.98), 0.24], [Vector3(4.1, 0.55, -0.98), 0.24], [Vector3(-3.45, 0.5, -0.95), 0.2],
			[Vector3(0.0, 0.85, 1.0), 0.2], [Vector3(0.0, 0.85, -1.0), 0.18]]:
		var tp: Vector3 = t[0]
		var tr: float = t[1]
		_part(_sph(tr, 5, 3), _xf(tp, Vector3(0.0, tp.x, 0.0), Vector3(1.3, 0.55, 1.0)), IVY_L if int(tp.x * 3.0) % 2 == 0 else IVY,
			{"kind": Kind.IVY, "normals": "smooth", "jitter": tr * 0.25, "seed": tp.x * 11.0 + tp.z})
	# --- contact shadows under the bank piers ---
	_disc(Vector3(-PIER_X, 0, 0), 1.75, 1.8, 14, 11.0)
	_disc(Vector3(PIER_X, 0, 0), 1.7, 1.75, 14, 12.0)
	var mesh: ArrayMesh = _commit("aqueduct", 0.0)
	# Colliders (3.2): the two bank piers, cylinders r 0.9. Arches, middle pier and rubble: draw-only.
	_scene("aqueduct.tscn", "Aqueduct", &"lm_aqueduct", mesh,
		[["PierWest", Vector3(-PIER_X, 0, 0), 0.9, COLLIDER_H], ["PierEast", Vector3(PIER_X, 0, 0), 0.9, COLLIDER_H]],
		PackedVector3Array([Vector3(0.0, 0.0, 1.1), Vector3(1.7, 0.0, 0.8), Vector3(1.6, -1.2, 0.55)]), 5.8)


func _rect(hx: float, hz: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(hx, -hz), Vector2(-hx, -hz), Vector2(-hx, hz), Vector2(hx, hz)])


## Ashlar courses filling x0..x1 between y0 and y1 (the whole wall depth). `bond`: running bond (joints offset).
func _masonry(x0: float, x1: float, y0: float, y1: float, seed: float, bond: bool) -> void:
	var y: float = y0
	var row: int = 0
	while y < y1 - 0.05:
		var ch: float = minf(COURSE * (0.9 + 0.2 * _h(Vector3(row, seed, 1.0))), y1 - y)
		if y1 - (y + ch) < 0.15:
			ch = y1 - y
		_course(x0, x1, y, y + ch, seed + row * 3.0, row, bond)
		y += ch
		row += 1


## One course of blocks from x0 to x1 (skips blocks the ruin lost, see _aq_keep).
func _course(x0: float, x1: float, ya: float, yb: float, seed: float, row: int, bond: bool) -> void:
	var span: float = x1 - x0
	if span < 0.08:
		return
	var n: int = maxi(1, int(round(span / 0.75)))
	var cuts: Array[float] = [x0]
	var odd: bool = bond and row % 2 == 1 and span > 0.6
	var count: int = n if odd else n - 1
	for k: int in count:
		var f: float = (float(k + 1) - (0.5 if odd else 0.0)) / n + (_h(Vector3(k, row, seed)) - 0.5) * 0.18 / n
		cuts.append(x0 + span * clampf(f, 0.04, 0.96))
	cuts.append(x1)
	for k: int in cuts.size() - 1:
		var a: float = cuts[k]
		var b: float = cuts[k + 1]
		if b - a < 0.06:
			continue
		var cx: float = (a + b) * 0.5
		var cy: float = (ya + yb) * 0.5
		if not _aq_keep(cx, cy, seed):
			continue
		var hk: float = _h(Vector3(cx * 5.0, cy * 3.0, seed))
		var col: Color = LIME.lerp(LIME_L, hk) if hk > 0.35 else LIME.lerp(LIME_C, hk * 2.0)
		if hk < 0.12:
			col = LIME_D
		var proud: float = (_h(Vector3(cx, cy, seed + 4.0)) - 0.5) * 0.05
		_stone(_box(Vector3(b - a, yb - ya, AQ_HD * 2.0 + proud * 2.0)), _xf(Vector3(cx, cy, 0.0)), col,
			seed + k, 0.75, 0.018, 0.05)


## The spandrel walls: courses from the springing to the cornice, each cut around every arch's extrados.
func _spandrels(x0: float, x1: float, seed: float) -> void:
	var y: float = Y_SPRING
	var row: int = 0
	while y < Y_CORNICE - 0.05:
		var yb: float = minf(y + COURSE, Y_CORNICE)
		if Y_CORNICE - yb < 0.15:
			yb = Y_CORNICE
		# Free intervals = [x0, x1] minus each arch's opening at this course.
		var ivs: Array = [[x0, x1]]
		for ac: float in ARCHES:
			var dy_hi: float = yb - Y_SPRING
			var dy_lo: float = y - Y_SPRING
			var hw: float = 0.0
			if dy_hi < R_OUT:
				hw = sqrt(R_OUT * R_OUT - dy_hi * dy_hi)
			if dy_lo < R_IN:
				hw = maxf(hw, sqrt(R_IN * R_IN - dy_lo * dy_lo) + 0.05)
			if hw <= 0.0:
				continue
			var out: Array = []
			for iv: Array in ivs:
				var a: float = iv[0]
				var b: float = iv[1]
				if b <= ac - hw or a >= ac + hw:
					out.append(iv)
					continue
				if a < ac - hw:
					out.append([a, ac - hw])
				if b > ac + hw:
					out.append([ac + hw, b])
			ivs = out
		for iv2: Array in ivs:
			_course(iv2[0], iv2[1], y, yb, seed + row * 7.0, row, true)
		y = yb
		row += 1


## Voussoirs of the ring of the arch centred at x = xc (springing y Y_SPRING) from angle a0 to a1 (0 = east),
## `count` pieces. `slip` = index of a keystone that slipped (-1 = none).
func _arch_ring(xc: float, a0: float, a1: float, count: int, seed: float, slip: int) -> void:
	for i: int in count:
		var t0: float = a0 + (a1 - a0) * float(i) / count
		var t1: float = a0 + (a1 - a0) * float(i + 1) / count
		var off := Vector3.ZERO
		var extra: float = 0.0
		if i == slip:
			off = Vector3(0.0, -0.14, 0.03)
			extra = 0.1
		_voussoir(xc, t0, t1, seed + i, off, extra)


func _voussoir(xc: float, t0: float, t1: float, seed: float, off: Vector3, extra: float, loose: bool = false) -> void:
	var r_out: float = R_OUT + extra + (_h(Vector3(seed, 1, 1)) - 0.5) * 0.08
	var poly := PackedVector2Array([Vector2(cos(t0) * R_IN, sin(t0) * R_IN), Vector2(cos(t0) * r_out, sin(t0) * r_out),
		Vector2(cos(t1) * r_out, sin(t1) * r_out), Vector2(cos(t1) * R_IN, sin(t1) * R_IN)])
	var hd: float = AQ_HD + 0.05 + (_h(Vector3(seed, 2, 2)) - 0.5) * 0.03
	var hk: float = _h(Vector3(seed, 3, 3))
	var col: Color = LIME_L.lerp(LIME, hk * 0.6)
	var rot := Vector3.ZERO
	if loose:   # the loose one: tilted, hanging out of line
		rot = Vector3(0.0, 0.0, 0.32)
	var mid := Vector3(xc + cos((t0 + t1) * 0.5) * (R_IN + r_out) * 0.5, Y_SPRING + sin((t0 + t1) * 0.5) * (R_IN + r_out) * 0.5, 0.0)
	var xf := Transform3D(Basis.IDENTITY, Vector3(xc, Y_SPRING, 0.0) + off)
	if rot != Vector3.ZERO:
		xf = Transform3D(Basis.from_euler(rot), mid + off) * Transform3D(Basis.IDENTITY, Vector3(xc, Y_SPRING, 0.0) - mid)
	_stone(_prism_z(poly, -hd, hd), xf, col, seed, 0.8, 0.015, 0.05)


## The water channel on top of the cornice: two side walls in blocks, a silted floor, a few capstones.
func _channel(x0: float, x1: float, seed: float) -> void:
	_stone(_box(Vector3(x1 - x0, 0.14, 0.82)), _xf(Vector3((x0 + x1) * 0.5, Y_TOP + 0.07, 0.0)), CHANNEL, seed, 1.0, 0.01)
	for sz: float in [-1.0, 1.0]:
		var x: float = x0
		var i: int = 0
		while x < x1 - 0.05:
			var len: float = minf(0.7 + _h(Vector3(i, sz, seed)) * 0.45, x1 - x)
			var hh: float = 0.5 - (0.18 if _h(Vector3(i, sz, seed + 1.0)) < 0.25 else 0.0)
			var hk: float = _h(Vector3(i, sz, seed + 2.0))
			_stone(_box(Vector3(len - 0.01, hh, 0.38)), _xf(Vector3(x + len * 0.5, Y_TOP + hh * 0.5, sz * 0.6),
				Vector3(0.0, 0.0, 0.0)), LIME.lerp(LIME_L, hk), seed + i + sz * 30.0, 0.65, 0.02, 0.05)
			x += len
			i += 1
	# Capstones: two still in place, one slid askew.
	for cp: Array in [[-3.9, 0.0, 0.0], [-1.6, 0.0, 0.0], [-0.3, 0.2, 0.35]]:
		_stone(_box(Vector3(0.7, 0.13, 1.74)), _xf(Vector3(float(cp[0]), Y_TOP + 0.56, float(cp[1])),
			Vector3(0.04, float(cp[2]), 0.06)), LIME_L, seed + float(cp[0]), 0.7, 0.02)


## A hanging ivy curtain on the face z = side * AQ_HD at x, from top_y down `clumps` leaf clumps (flat on the wall).
func _ivy_curtain(x: float, top_y: float, side: float, clumps: int, seed: float) -> void:
	for strand: int in 2:
		var sx: float = x + (strand - 0.5) * 0.26 + (_h(Vector3(seed, strand, 1.0)) - 0.5) * 0.1
		var n: int = clumps - strand * 2 - int(_h(Vector3(seed, strand, 2.0)) * 2.0)
		var drift: float = (_h(Vector3(seed, strand, 3.0)) - 0.5) * 0.08
		for j: int in maxi(n, 1):
			var jy: float = top_y - 0.08 - j * 0.27 - strand * 0.1
			var r: float = 0.2 - j * 0.013
			var p := Vector3(sx + drift * j + (_h(Vector3(seed, strand, j)) - 0.5) * 0.12, jy, side * (AQ_HD + 0.06))
			_part(_sph(r, 5, 3), _xf(p, Vector3(0.0, 0.0, (_h(Vector3(j, strand, seed)) - 0.5) * 0.6),
				Vector3(1.2, 1.15, 0.32)), IVY_L if (j + strand) % 3 == 0 else IVY,
				{"kind": Kind.IVY, "normals": "smooth", "jitter": 0.035, "seed": seed + strand * 5.0 + j})


# =================================================================================================
# DROWNED BARGE
# Built along +Z (bow +Z, keel at y 0), then _pre sinks it: pitch 12 deg (bow up), roll 5 deg, lowered 0.72 m (the
# stern and its cabin half under water), turned 28 deg (the river runs at 18.4 deg there; the wreck lies canted 10 deg
# across the flow, 3.4 m wide in a 5 m channel).
# =================================================================================================

const BG_STATIONS: Array = [
	# [z, bottom half-beam, gunwale half-beam, bottom y, gunwale y]
	[-3.2, 0.72, 0.96, 0.34, 1.16],
	[-2.6, 0.95, 1.12, 0.08, 1.03],
	[-1.4, 1.0, 1.17, 0.0, 0.99],
	[0.0, 1.0, 1.17, 0.0, 0.98],
	[1.4, 0.98, 1.15, 0.02, 1.02],
	[2.4, 0.8, 1.03, 0.2, 1.12],
	[3.2, 0.46, 0.72, 0.55, 1.3],
]
const DECK_Y := 0.72


func _barge_pre() -> Transform3D:
	var b := Basis(Vector3.UP, deg_to_rad(28.4)) * Basis(Vector3.RIGHT, deg_to_rad(-15.0)) * Basis(Vector3.BACK, deg_to_rad(-10.0))
	return Transform3D(b, Vector3(0.0, -0.95, 0.0))


## The hull outline at station s, side-to-side: 5 points per side (gunwale .. chine) + the keel line.
func _station(s: Array, inset: float) -> PackedVector3Array:
	var z: float = s[0]
	var b: float = float(s[1]) - inset
	var g: float = float(s[2]) - inset
	var yb: float = float(s[3]) + inset
	var yg: float = float(s[4])
	var pts := PackedVector3Array()
	for k: int in 5:   # port side: gunwale (k 0) down to chine (k 4)
		var t: float = k / 4.0
		pts.append(Vector3(-lerpf(g, b, t), lerpf(yg, yb + 0.05, t * t * 0.3 + t * 0.7), z))
	pts.append(Vector3(0.0, yb - 0.02, z))
	for k: int in 5:
		var t2: float = 1.0 - k / 4.0
		pts.append(Vector3(lerpf(g, b, t2), lerpf(yg, yb + 0.05, t2 * t2 * 0.3 + t2 * 0.7), z))
	return pts


func _build_barge() -> void:
	_begin()
	_pre = _barge_pre()
	var outer: Array = []
	var inner: Array = []
	for s: Array in BG_STATIONS:
		outer.append(_station(s, 0.0))
		inner.append(_station(s, 0.09))
	# --- outer planking: one strake per row between stations, colours alternate (planks read at 30 m) ---
	for k: int in outer.size() - 1:
		var a: PackedVector3Array = outer[k]
		var b: PackedVector3Array = outer[k + 1]
		for i: int in a.size() - 1:
			var strake: int = mini(i, a.size() - 2 - i)
			var col: Color = HULL if strake % 2 == 0 else HULL_D
			if strake == 0:
				col = HULL_L   # the wale under the gunwale
			var quad := PackedVector3Array([a[i], a[i + 1], b[i + 1], b[i]])
			var mid: Vector3 = (a[i] + b[i + 1]) * 0.5
			var out_n := Vector3(mid.x, minf(mid.y - 0.5, 0.0) * 2.0, 0.0).normalized()
			if out_n.length_squared() < 0.5:
				out_n = Vector3.DOWN
			_quad(quad, out_n, col, k * 20 + i)
	# Transoms: stern and bow (flat boards closing the ends).
	_fan(outer[0], Vector3.FORWARD, HULL_D)
	_fan(outer[outer.size() - 1], Vector3.BACK, HULL_D)
	# --- inner bulwarks above the deck and the gunwale cap ---
	for k: int in inner.size() - 1:
		var a2: PackedVector3Array = inner[k]
		var b2: PackedVector3Array = inner[k + 1]
		for side: int in 2:
			var i0: int = 0 if side == 0 else a2.size() - 2
			var quad2 := PackedVector3Array([a2[i0], a2[i0 + 1], b2[i0 + 1], b2[i0]])
			var inn := Vector3(1.0 if side == 0 else -1.0, 0.0, 0.0)
			_quad(quad2, inn, INSIDE.lerp(HULL_D, 0.5), 400 + k * 2 + side)
			# cap: outer gunwale point -> inner gunwale point
			var oa: PackedVector3Array = outer[k]
			var ob: PackedVector3Array = outer[k + 1]
			var j0: int = 0 if side == 0 else oa.size() - 1
			var cap := PackedVector3Array([oa[j0] + Vector3(0, 0.06, 0), a2[i0] + Vector3(0, 0.06, 0),
				b2[i0] + Vector3(0, 0.06, 0), ob[j0] + Vector3(0, 0.06, 0)])
			_quad(cap, Vector3.UP, WOOD_GREY, 500 + k * 2 + side)
			# cap's outer lip (so the rail has thickness)
			_quad(PackedVector3Array([oa[j0], oa[j0] + Vector3(0, 0.06, 0), ob[j0] + Vector3(0, 0.06, 0), ob[j0]]),
				Vector3(-1.0 if side == 0 else 1.0, 0.0, 0.0), WOOD_GREY.darkened(0.15), 520 + k * 2 + side)
	# --- the deck: planks fore and aft, a broken hole amidships (starboard of the mast) over the dark hold ---
	var hole_z0 := -1.25
	var hole_z1 := 0.15
	var plank_w := 0.26
	var np: int = 8
	for p: int in np:
		var px: float = -1.02 + (p + 0.5) * (2.04 / np)
		var in_hole: bool = px > 0.05 and px < 0.9
		var segs: Array = []
		if in_hole:
			var j1: float = hole_z0 + (_h(Vector3(p, 1, 1)) - 0.5) * 0.5
			var j2: float = hole_z1 + (_h(Vector3(p, 2, 2)) - 0.5) * 0.5
			segs = [[-3.0, j1], [j2, 3.05]]
		else:
			segs = [[-3.0, 3.05]]
		for sg: Array in segs:
			var za: float = sg[0]
			var zb: float = sg[1]
			var hw: float = _half_beam_at((za + zb) * 0.5) - 0.1
			if absf(px) + plank_w * 0.5 > hw + 0.2:
				continue
			var col: Color = DECK if p % 2 == 0 else DECK_D
			col = col.lerp(DECK.lightened(0.08), _h(Vector3(p, za, 3.0)) * 0.5)
			var zlo: float = maxf(za, _deck_end(px, -1.0))
			var zhi: float = minf(zb, _deck_end(px, 1.0))
			if zhi - zlo < 0.1:
				continue
			_wood(_box(Vector3(plank_w - 0.025, 0.07, zhi - zlo)), _xf(Vector3(px, DECK_Y, (zlo + zhi) * 0.5),
				Vector3((_h(Vector3(p, za, 4.0)) - 0.5) * 0.02, 0.0, (_h(Vector3(p, za, 5.0)) - 0.5) * 0.04)), col, p + za, 0.0, 0.06)
	# Splintered plank ends sticking up at the hole.
	for sp: Array in [[0.3, hole_z0 + 0.1, 0.5], [0.62, hole_z1 - 0.05, -0.6], [0.8, hole_z0 + 0.25, 0.35]]:
		_wood(_box(Vector3(0.22, 0.06, 0.55)), _xf(Vector3(float(sp[0]), DECK_Y + 0.08, float(sp[1])),
			Vector3(float(sp[2]), 0.1, 0.05)), DECK_D, float(sp[1]))
	# The dark hold under the hole (flooded: its floor sits under the water line once sunk).
	_wood(_box(Vector3(1.0, 0.05, 1.7)), _xf(Vector3(0.48, 0.2, -0.55)), INSIDE, 0.0)
	# --- stern cabin (half under water once sunk), its door toward the bow ---
	_wood(_box(Vector3(1.55, 0.86, 1.25)), _xf(Vector3(0.0, DECK_Y + 0.43, -2.35)), HULL_L.lerp(WOOD_GREY, 0.3), 30.0, 0.02)
	_wood(_box(Vector3(0.5, 0.62, 0.05)), _xf(Vector3(-0.2, DECK_Y + 0.33, -1.71)), INSIDE, 31.0)
	for rs: float in [-1.0, 1.0]:   # pitched roof: two boards
		_wood(_box(Vector3(1.02, 0.09, 1.6)), _xf(Vector3(rs * 0.46, DECK_Y + 1.02, -2.35), Vector3(0.0, 0.0, -rs * 0.34)),
			ROOF, 33.0 + rs, 0.0, 0.1)
	_wood(_box(Vector3(0.14, 0.12, 1.7)), _xf(Vector3(0.0, DECK_Y + 1.2, -2.35)), WOOD_GREY, 35.0)   # ridge beam
	# A bent tin stovepipe through the roof (the cabin's silhouette mark when only the roof is above water).
	_limb(Vector3(0.45, DECK_Y + 0.95, -2.7), Vector3(0.5, DECK_Y + 1.62, -2.72), 0.09, 0.09, 6, IRON)
	_limb(Vector3(0.5, DECK_Y + 1.6, -2.72), Vector3(0.72, DECK_Y + 1.78, -2.95), 0.09, 0.1, 6, IRON)
	# Tiller: the rudder post behind the stern, the bar reaching up and forward out of the water.
	_limb(Vector3(0.0, -0.1, -3.32), Vector3(0.0, 1.35, -3.3), 0.08, 0.07, 5, HULL_D)
	_wood(_box(Vector3(0.1, 1.1, 0.6)), _xf(Vector3(0.0, 0.3, -3.55)), HULL_D, 32.0)
	_limb(Vector3(0.0, 1.3, -3.3), Vector3(0.35, 1.95, -2.35), 0.05, 0.04, 5, WOOD_GREY)
	# --- the broken mast: a stub with a jagged top, the upper mast fallen over the starboard side ---
	var mast_foot := Vector3(-0.2, DECK_Y, 0.55)
	var mast_top := Vector3(-0.32, DECK_Y + 2.45, 0.42)
	_limb(mast_foot, mast_top, 0.17, 0.15, 7, WOOD_GREY.lerp(HULL_L, 0.4), {"seed": 40.0, "jitter": 0.01})
	_part(_broken_top(0.15, 0.2, 7, 41.0), Transform3D(_along(mast_foot, mast_top), mast_top), WOOD_GREY,
		{"kind": Kind.BARK, "tint": 0.1})
	_wood(_cyl(0.24, 0.26, 0.14, 7), _xf(mast_foot + Vector3(0, 0.07, 0)), HULL_D, 42.0)   # mast partner
	var f0 := Vector3(0.15, DECK_Y + 1.55, 0.7)
	var f1 := Vector3(2.05, -0.1, 2.3)
	_limb(f0, f1, 0.12, 0.1, 6, WOOD_GREY.lerp(HULL_L, 0.3))
	_part(_broken_top(0.12, 0.22, 6, 43.0), Transform3D(_along(f1, f0), f0), WOOD_GREY, {"kind": Kind.BARK, "tint": 0.1})
	# The yard across the fallen mast, and the torn sail hanging from it over the side into the water.
	var yard_c: Vector3 = f0.lerp(f1, 0.45)
	var ya: Vector3 = yard_c + Vector3(-0.35, 0.18, 1.3)
	var yb: Vector3 = yard_c + Vector3(0.45, -0.25, -1.25)
	_limb(ya, yb, 0.075, 0.06, 5, WOOD_GREY)
	_sail(ya, yb, 50.0)
	# Rigging: a slack stay from the stub top to the bow post.
	_limb(mast_top + Vector3(0, -0.2, 0), Vector3(0.0, 1.62, 3.1), 0.025, 0.025, 4, ROPE)
	# --- the bow: a heron stem post, a rope coil, lashed cargo (salt barrels, crates, sacks) ---
	_limb(Vector3(0.0, 1.0, 3.18), Vector3(0.0, 1.7, 3.32), 0.1, 0.085, 6, HULL_L)
	_limb(Vector3(0.0, 1.68, 3.31), Vector3(0.0, 2.08, 3.2), 0.07, 0.055, 6, WOOD_GREY)
	_part(_sph(0.12, 6, 4), _xf(Vector3(0.0, 2.12, 3.26), Vector3.ZERO, Vector3(0.8, 0.85, 1.3)), WOOD_GREY,
		{"kind": Kind.BARK, "normals": "smooth"})
	_limb(Vector3(0.0, 2.1, 3.33), Vector3(0.0, 2.02, 3.78), 0.045, 0.004, 5, SAIL_STRIPE.lerp(WOOD_GREY, 0.3))
	_part(_cyl(0.3, 0.3, 0.12, 9), _xf(Vector3(-0.45, DECK_Y + 0.08, 2.55)), ROPE, {"kind": Kind.BARK, "tint": 0.06})
	_part(_cyl(0.14, 0.14, 0.13, 7), _xf(Vector3(-0.45, DECK_Y + 0.09, 2.55)), HULL_D, {"kind": Kind.BARK})
	for br: Array in [[Vector3(0.45, DECK_Y, 1.9), 0.0], [Vector3(-0.2, DECK_Y, 1.6), 0.3], [Vector3(0.52, DECK_Y, 1.32), 0.9]]:
		_barrel(br[0], Basis(Vector3.UP, float(br[1])), 60.0 + float(br[1]))
	_barrel(Vector3(-0.55, DECK_Y + 0.27, 1.05), Basis(Vector3.UP, 0.4) * Basis(Vector3.BACK, PI * 0.5), 64.0)
	_crate(Vector3(0.05, DECK_Y, 2.45), 0.62, 0.2, 70.0)
	_crate(Vector3(0.15, DECK_Y + 0.6, 2.4), 0.46, -0.3, 71.0)
	_crate(Vector3(-0.6, DECK_Y, 0.0), 0.5, 0.5, 72.0)
	for sk: Array in [[Vector3(-0.55, DECK_Y + 0.1, 1.85), 0.3], [Vector3(0.62, DECK_Y + 0.1, 2.5), -0.4]]:
		_part(_sph(0.25, 6, 4), _xf(sk[0] + Vector3(0, 0.08, 0), Vector3(0.1, float(sk[1]), 0.2), Vector3(1.0, 0.62, 1.35)), SACK,
			{"kind": Kind.BARK, "normals": "smooth", "jitter": 0.03, "seed": float(sk[1])})
	# A spill of salt from a split sack at the hole's edge.
	_part(_sph(0.3, 6, 3), _xf(Vector3(0.15, DECK_Y + 0.03, 0.3), Vector3.ZERO, Vector3(1.2, 0.18, 0.9)), SALT,
		{"kind": Kind.STONE, "normals": "smooth", "tint": 0.04})
	# Weed and slime along the hull (at the water line once sunk) + a hanging net of weed on the bow.
	for wd: Array in [[Vector3(-1.14, 0.8, 1.6), 0.26], [Vector3(1.12, 0.75, 0.9), 0.22], [Vector3(-1.1, 0.85, -0.3), 0.2],
			[Vector3(1.06, 0.85, 2.3), 0.2], [Vector3(-0.75, 1.1, 3.0), 0.18]]:
		_part(_sph(float(wd[1]), 5, 3), _xf(wd[0], Vector3.ZERO, Vector3(0.45, 1.3, 1.4)), WEED,
			{"kind": Kind.IVY, "normals": "smooth", "jitter": 0.04, "seed": (wd[0] as Vector3).z})
	# --- flotsam around the wreck (floating at the water line, no collider): a barrel, a crate, planks. Placed in
	# hull-aligned coordinates (only the yaw), outside the hull's beam. ---
	var yaw := deg_to_rad(28.4)
	_pre = Transform3D(Basis(Vector3.UP, yaw), Vector3.ZERO)
	_barrel(Vector3(-1.72, WATER_Y - 0.2, -1.7), Basis(Vector3.UP, 1.1) * Basis(Vector3.BACK, PI * 0.5 + 0.15), 80.0)
	_crate(Vector3(1.75, WATER_Y - 0.26, -2.5), 0.5, 0.7, 81.0, Vector3(0.25, 0.0, 0.18))
	_wood(_box(Vector3(0.24, 0.06, 1.4)), _xf(Vector3(-1.62, WATER_Y + 0.02, 2.1), Vector3(0.0, 0.35, 0.04)), DECK_D, 82.0)
	_wood(_box(Vector3(0.22, 0.06, 1.0)), _xf(Vector3(1.68, WATER_Y + 0.02, 0.4), Vector3(0.0, -0.3, -0.05)), DECK, 83.0)
	var mesh: ArrayMesh = _commit("barge", WATER_Y)
	# Foam collars (local x, z, radius): water.gdshader fills each circle white, so they stay inside what pokes out of
	# the water: the bow half of the hull (3 circles along its axis), the cabin, the rudder post.
	var ax := Vector2(sin(yaw), cos(yaw))
	var foam := PackedVector3Array()
	for fc: Vector2 in [Vector2(0.2, 0.95), Vector2(1.4, 0.95), Vector2(2.45, 0.62), Vector2(-2.35, 0.62), Vector2(-3.35, 0.2)]:
		foam.append(Vector3(ax.x * fc.x, ax.y * fc.x, fc.y))
	_scene("barge.tscn", "Barge", &"lm_barge", mesh, [], foam, 3.6)


## A flat board closing a hull end: fan over the station outline, facing `hint`.
func _fan(ring: PackedVector3Array, hint: Vector3, col: Color) -> void:
	var c := Vector3.ZERO
	for p: Vector3 in ring:
		c += p
	c /= float(ring.size())
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	for i: int in ring.size():
		v.append_array([c, ring[i], ring[(i + 1) % ring.size()]])
		n.append_array([hint, hint, hint])
	_part(_mk(v, n, PackedInt32Array()), Transform3D.IDENTITY, col, {"kind": Kind.BARK, "tint": 0.1})


func _half_beam_at(z: float) -> float:
	for k: int in BG_STATIONS.size() - 1:
		var a: Array = BG_STATIONS[k]
		var b: Array = BG_STATIONS[k + 1]
		if z >= float(a[0]) and z <= float(b[0]):
			var t: float = (z - float(a[0])) / (float(b[0]) - float(a[0]))
			return lerpf(float(a[2]), float(b[2]), t)
	return 0.7


## Where the deck plank at x ends toward the stern (dir -1) or the bow (+1): inside the transoms.
func _deck_end(x: float, dir: float) -> float:
	var z: float = 3.1 * dir
	while absf(z) > 0.2:
		if _half_beam_at(z) - 0.1 > absf(x) + 0.12:
			return z
		z -= 0.05 * dir
	return 0.0


## A flat quad (4 points, any winding) with an outward hint normal; planks get a small per-quad tint.
func _quad(q: PackedVector3Array, hint: Vector3, col: Color, seed: int) -> void:
	var v := PackedVector3Array([q[0], q[1], q[2], q[0], q[2], q[3]])
	var n := PackedVector3Array([hint, hint, hint, hint, hint, hint])
	var k: float = 0.94 + _h(Vector3(seed, 0.3, 0.7)) * 0.12
	_part(_mk(v, n, PackedInt32Array()), Transform3D.IDENTITY, Color(col.r * k, col.g * k, col.b * k),
		{"kind": Kind.BARK, "tint": 0.05})


## A broken spar end: ring of radius r at y 0, a jagged rim (heights up to h), a sunken centre.
func _broken_top(r: float, h: float, segs: int, seed: float) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for i: int in segs:
		var a: float = i * TAU / segs
		v.append(Vector3(cos(a) * r, 0, sin(a) * r))
		n.append(Vector3(cos(a), 0, sin(a)))
	for i: int in segs:
		var a: float = i * TAU / segs
		var hh: float = h * (0.2 + 0.8 * _h(Vector3(i, seed, 1.0))) * (0.3 if i % 3 == 1 else 1.0)
		v.append(Vector3(cos(a) * r * 0.85, hh, sin(a) * r * 0.85))
		n.append(Vector3(cos(a), 0.3, sin(a)))
	for i: int in segs:
		var j: int = (i + 1) % segs
		idx.append_array([i, j, segs + i, j, segs + j, segs + i])
	var cbase: int = v.size()
	v.append(Vector3(0.0, h * 0.25, 0.0))
	n.append(Vector3.UP)
	for i: int in segs:
		v.append(v[segs + i])
		n.append(Vector3.UP)
	for i: int in segs:
		idx.append_array([cbase, cbase + 1 + i, cbase + 1 + (i + 1) % segs])
	return _mk(v, n, idx)


## A salt barrel standing on `foot` (its axis = basis * Y), two iron hoops.
func _barrel(foot: Vector3, b: Basis, seed: float) -> void:
	var up: Vector3 = b * Vector3.UP
	var c: Vector3 = foot + up * 0.3
	_part(_cyl(0.22, 0.22, 0.6, 8), Transform3D(b, c), HULL_L.lerp(DECK, 0.3), {"kind": Kind.BARK, "tint": 0.06, "seed": seed})
	_part(_cyl(0.27, 0.27, 0.3, 8), Transform3D(b, c), HULL_L.lerp(DECK, 0.5), {"kind": Kind.BARK, "tint": 0.06, "no_caps": true})
	for hy: float in [-0.22, 0.22]:
		_part(_cyl(0.255, 0.255, 0.05, 8), Transform3D(b, c + up * hy), IRON, {"kind": Kind.STONE, "no_caps": true})
	_part(_cyl(0.2, 0.2, 0.02, 8), Transform3D(b, c + up * 0.3), SALT, {"kind": Kind.STONE, "tint": 0.04})


## A crate of edge `s` on `foot`, turned `yaw`, with darker slats.
func _crate(foot: Vector3, s: float, yaw: float, seed: float, tilt: Vector3 = Vector3.ZERO) -> void:
	var b := Basis.from_euler(tilt) * Basis(Vector3.UP, yaw)
	var c: Vector3 = foot + b * Vector3(0, s * 0.5, 0)
	_wood(_box(Vector3(s, s, s)), Transform3D(b, c), DECK.lerp(HULL_L, 0.3), seed, 0.0, 0.1)
	for k: int in 2:
		var off: Vector3 = b * Vector3(0.0, (k - 0.5) * s * 0.6, 0.0)
		_wood(_box(Vector3(s + 0.04, s * 0.12, s + 0.04)), Transform3D(b, c + off), HULL_D, seed + k)


## The torn sail: a cloth grid hanging from the yard a -> b, draped over the side down into the water, torn edge.
func _sail(a: Vector3, b: Vector3, seed: float) -> void:
	var cols: int = 5
	var rows: int = 4
	var grid: Array = []
	for r: int in rows + 1:
		var line: Array[Vector3] = []
		for c: int in cols + 1:
			var t: float = float(c) / cols
			var p: Vector3 = a.lerp(b, t)
			var drop: float = r * 0.42
			# Hangs down and outward (over the starboard side), folds alternate in and out.
			var fold: float = sin(t * PI * 3.0 + r * 0.8) * 0.12 * (r / float(rows))
			p += Vector3(0.2 * r + fold, -drop, fold * 0.8)
			if r == rows:   # torn bottom edge
				p.y += (_h(Vector3(c, seed, 1.0)) - 0.2) * 0.35
			line.append(p)
		grid.append(line)
	for r: int in rows:
		for c: int in cols:
			if r == rows - 1 and _h(Vector3(c, seed, 2.0)) < 0.3:
				continue   # holes along the torn edge
			var p00: Vector3 = grid[r][c]
			var p10: Vector3 = grid[r][c + 1]
			var p11: Vector3 = grid[r + 1][c + 1]
			var p01: Vector3 = grid[r + 1][c]
			var col: Color = SAIL_STRIPE if r == 1 else SAIL
			col = col.darkened(0.06 * (c % 2))
			var fn: Vector3 = (p10 - p00).cross(p01 - p00).normalized()
			for side: float in [1.0, -1.0]:   # two-sided cloth
				var v := PackedVector3Array([p00, p10, p11, p00, p11, p01])
				var n := PackedVector3Array()
				for q: int in 6:
					n.append(fn * side)
				_part(_mk(v, n, PackedInt32Array()), Transform3D.IDENTITY, col,
					{"kind": Kind.IVY, "moss": 0.0, "tint": 0.05})


# =================================================================================================
# STANDING STONES
# Ring r 3 around the origin. Angles (atan2(z, x), z = south): E 0 (the tall king stone), SE 60, SW 120, W 180 (the
# fallen one, broken in two, its runes to the sky), NW 240, NE 300. The south and north pairs are the shortest so the
# ring stays open to the RTS camera on both copies (the mirror swaps E / W and N / S). Colliders: 6 cylinders r 0.5.
# =================================================================================================

const STONES: Array = [
	# [angle deg, radius, height, half width, half thickness, lean deg, lean dir (deg from outward), colour]
	[2.0, 3.05, 3.5, 0.56, 0.34, 7.0, 15.0, 0],
	[58.0, 2.95, 2.4, 0.52, 0.32, 11.0, 180.0, 1],
	[123.0, 3.0, 2.6, 0.5, 0.31, 9.0, 30.0, 2],
	[181.0, 3.0, 3.0, 0.52, 0.32, 0.0, 0.0, 0],   # fallen (height = its length)
	[238.0, 3.05, 2.9, 0.55, 0.33, 12.0, -20.0, 2],
	[302.0, 2.95, 2.7, 0.5, 0.31, 8.0, 160.0, 1],
]
const GLYPH_CELL := Vector2(0.36, 0.46)
const GROOVE := Color(0.17, 0.18, 0.2)
const FALLEN := 3

## Glyph strokes in a cell (x -0.5..0.5, y 0..1): original shapes, no real alphabet.
const GLYPHS: Array = [
	[[Vector2(0, 0), Vector2(0, 1)], [Vector2(0, 1), Vector2(0.42, 0.66)], [Vector2(0, 0.62), Vector2(0.42, 0.3)]],
	[[Vector2(0, 0), Vector2(0, 1)], [Vector2(-0.34, 0.5), Vector2(0, 0.82)], [Vector2(0, 0.82), Vector2(0.34, 0.5)],
		[Vector2(0.34, 0.5), Vector2(0, 0.18)], [Vector2(0, 0.18), Vector2(-0.34, 0.5)]],
	[[Vector2(-0.36, 0), Vector2(0.36, 1)], [Vector2(0.36, 0), Vector2(-0.36, 1)], [Vector2(-0.4, 1), Vector2(0.4, 1)]],
	[[Vector2(0, 0), Vector2(0, 0.78)], [Vector2(0, 0.78), Vector2(0.34, 1)], [Vector2(-0.36, 0.34), Vector2(0.36, 0.34)]],
	[[Vector2(-0.3, 1), Vector2(0.3, 0.66)], [Vector2(0.3, 0.66), Vector2(-0.3, 0.33)], [Vector2(-0.3, 0.33), Vector2(0.3, 0)]],
	[[Vector2(0, 0), Vector2(0, 1)], [Vector2(-0.38, 0.62), Vector2(0, 1)], [Vector2(0.38, 0.62), Vector2(0, 1)],
		[Vector2(-0.3, 0.2), Vector2(0.3, 0.2)]],
	[[Vector2(-0.34, 0), Vector2(-0.34, 1)], [Vector2(0.34, 0), Vector2(0.34, 1)], [Vector2(-0.34, 0.5), Vector2(0.34, 0.5)],
		[Vector2(-0.34, 1), Vector2(0.34, 0.72)]],
	[[Vector2(0, 0.08), Vector2(-0.34, 0.5)], [Vector2(-0.34, 0.5), Vector2(0, 0.92)], [Vector2(0, 0.92), Vector2(0.34, 0.5)],
		[Vector2(0.34, 0.5), Vector2(0, 0.08)], [Vector2(0, 0.38), Vector2(0, 0.62)]],
]


func _build_stones() -> void:
	_begin()
	var colliders: Array = []
	for i: int in STONES.size():
		var s: Array = STONES[i]
		var ang: float = deg_to_rad(float(s[0]))
		var rad: float = s[1]
		var base := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var outward := Vector3(cos(ang), 0.0, sin(ang))
		var col: Color = [GRAN, GRAN_W, GRAN.lerp(GRAN_D, 0.35)][int(s[7])]
		var seed: float = 500.0 + i * 17.0
		if i == FALLEN:
			_fallen_stone(base, ang, float(s[2]), float(s[3]), float(s[4]), col, seed)
			colliders.append(["Stone%d" % i, base, 0.5, COLLIDER_H])
			continue
		# Broad faces turned toward the ring centre (face normal = -outward), a small yaw jitter.
		var yaw: float = -ang + PI * 0.5 + (_h(Vector3(seed, 1, 1)) - 0.5) * 0.35
		var lean_dir: Vector3 = outward.rotated(Vector3.UP, deg_to_rad(float(s[6])))
		var lean_axis: Vector3 = Vector3.UP.cross(lean_dir).normalized()
		var b := Basis(lean_axis, deg_to_rad(float(s[5]))) * Basis(Vector3.UP, yaw)
		var xf := Transform3D(b, base)
		_menhir(xf, float(s[2]), float(s[3]), float(s[4]), col, seed, 3 if float(s[2]) < 3.0 else 4, i)
		# Packing stones around the foot, a contact shadow.
		for k: int in 3:
			var a2: float = ang + (k - 1) * 0.9 + _h(Vector3(seed, k, 5)) * 0.5
			var pp: Vector3 = base + Vector3(cos(a2), 0, sin(a2)) * (0.58 + _h(Vector3(seed, k, 6)) * 0.2)
			var pr: float = 0.12 + _h(Vector3(seed, k, 7)) * 0.12
			_stone(_chunk(Vector3(pr * 1.3, pr * 0.75, pr), 5, seed + k, 0.7, 7, 4), _xf(pp + Vector3(0, pr * 0.15, 0),
				Vector3(0.0, a2, 0.0)), GRAN_D.lerp(col, 0.5), seed + k, 0.3, 0.0)
		_disc(base, 0.95, 0.8, 12, seed, yaw)
		colliders.append(["Stone%d" % i, base, 0.5, COLLIDER_H])
	# The altar slab in the middle (walk-through, 0.28 m), a faint rune ring on its top.
	var alt_b := Basis(Vector3.UP, 0.35)
	_stone(_box(Vector3(1.55, 0.3, 0.95)), Transform3D(alt_b, Vector3(0.1, 0.12, 0.05)), GRAN_W.lightened(0.04), 700.0, 0.5, 0.04)
	_stone(_box(Vector3(1.75, 0.12, 1.12)), Transform3D(alt_b * Basis(Vector3.RIGHT, 0.02), Vector3(0.1, 0.0, 0.05)), GRAN_D,
		701.0, 0.9, 0.04)
	var top := Transform3D(alt_b * Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0.1, 0.275, 0.05))   # face frame: z = up
	for k: int in 10:
		var a0: float = k * TAU / 10.0 + 0.08
		var a1: float = a0 + TAU / 10.0 * 0.62
		var r0 := 0.33
		_stroke(top, Vector2(cos(a0), sin(a0)) * r0, Vector2(cos(a1), sin(a1)) * r0, 0.07, 0.62)
		if k % 2 == 0:
			var am: float = (a0 + a1) * 0.5
			_stroke(top, Vector2(cos(am), sin(am)) * 0.2, Vector2(cos(am), sin(am)) * 0.1, 0.06, 0.62)
	_stroke(top, Vector2(-0.52, -0.3), Vector2(-0.52, 0.3), 0.06, 0.62)
	_stroke(top, Vector2(0.52, -0.3), Vector2(0.52, 0.3), 0.06, 0.62)
	_disc(Vector3(0.1, 0, 0.05), 1.25, 0.9, 14, 710.0, 0.35)
	# A few flat stones half in the grass along the ring (walk-through).
	for k2: int in 5:
		var a3: float = deg_to_rad(28.0 + k2 * 60.0 + (_h(Vector3(k2, 8, 8)) - 0.5) * 20.0)
		if k2 == 2:
			continue
		var fp := Vector3(cos(a3), 0.0, sin(a3)) * 3.05
		_stone(_chunk(Vector3(0.36, 0.1, 0.26), 5, 720.0 + k2, 0.7, 7, 4), _xf(fp + Vector3(0, 0.02, 0), Vector3(0, a3, 0)),
			GRAN_D.lerp(GRAN_W, 0.5), 720.0 + k2, 0.4, 0.0)
	var mesh: ArrayMesh = _commit("standing_stones", 0.0)
	_scene("standing_stones.tscn", "StandingStones", &"lm_stones", mesh, colliders, PackedVector3Array(), 4.3)


## One ring of the menhir's 6-sided section: narrow edges at +-w (x, their z pushed by e0 / e1 for rugged edges),
## broad flat faces at z = +-t (the runes sit on them).
func _msection(w: float, t: float, xo: float, y: float, slope: float = 0.0, e0: float = 0.0, e1: float = 0.0) -> PackedVector3Array:
	var pts: Array[Vector2] = [Vector2(w, e0 * t), Vector2(w * 0.64, t), Vector2(-w * 0.6, t), Vector2(-w, e1 * t),
		Vector2(-w * 0.68, -t), Vector2(w * 0.6, -t)]
	var out := PackedVector3Array()
	for p: Vector2 in pts:
		out.append(Vector3(xo + p.x, y + slope * p.x, p.y))
	return out


## The menhir's rings: [y, w, t, xoff, e0, e1] from the buried foot to the slanted shoulder: a heavy belly low down,
## rugged edges, a blunt top. Deterministic per seed.
func _menhir_rings(h: float, w0: float, t0: float, seed: float) -> Array:
	var ys: Array[float] = [-0.35, 0.14, 0.3, 0.48, 0.64, 0.78, 0.89, 0.95]
	var wf: Array[float] = [1.0, 1.05, 1.07, 1.0, 0.93, 0.84, 0.72, 0.58]
	var tf: Array[float] = [1.0, 1.03, 1.04, 0.98, 0.92, 0.84, 0.74, 0.62]
	var out: Array = []
	for k: int in ys.size():
		var y: float = ys[k] if k == 0 else ys[k] * h
		var jw: float = 1.0 + (_h(Vector3(seed, k, 1.0)) - 0.5) * 0.2
		var xo: float = (_h(Vector3(seed, k, 2.0)) - 0.5) * 0.12 * w0 + (0.06 * w0 * sin(k * 1.3 + seed))
		var e0: float = (_h(Vector3(seed, k, 4.0)) - 0.5) * 0.9
		var e1: float = (_h(Vector3(seed, k, 5.0)) - 0.5) * 0.9
		out.append([y, w0 * wf[k] * jw, t0 * tf[k] * (1.0 + (_h(Vector3(seed, k, 3.0)) - 0.5) * 0.1), xo, e0, e1])
	return out


func _menhir_loft(rings: Array, slope: float) -> Array:
	var out: Array = []
	for k: int in rings.size():
		var r: Array = rings[k]
		out.append(_msection(r[1], r[2], r[3], r[0], slope if k == rings.size() - 1 else 0.0, r[4], r[5]))
	return out


## A standing stone (transform xf: base centre, broad faces along local +-Z) with `glyphs` runes on each broad face.
func _menhir(xf: Transform3D, h: float, w0: float, t0: float, col: Color, seed: float, glyphs: int, idx: int) -> void:
	var rings: Array = _menhir_rings(h, w0, t0, seed)
	var slope: float = (_h(Vector3(seed, 9, 9)) - 0.5) * 0.55
	var last: Array = rings[rings.size() - 1]
	var apex := Vector3(float(last[3]) + float(last[1]) * slope * 0.6, h + 0.02 + absf(slope) * 0.12, 0.0)
	_part(_loft(_menhir_loft(rings, slope), false, true, null, apex), xf, col, {"kind": Kind.STONE, "moss": 0.75,
		"tint": 0.1, "col2": col.lightened(0.06)})
	# Runes on both broad faces (the camera sees the inner face of the far stones, the outer face of the near ones).
	var phase: float = fposmod(idx * 0.37, 1.0)
	for side: float in [1.0, -1.0]:
		for g: int in glyphs:
			var gy: float = 0.6 + g * 0.58
			if gy + GLYPH_CELL.y > h * 0.8:
				break
			var fr: Transform3D = _face_frame(rings, gy, side)
			var glyph: Array = GLYPHS[int(_h(Vector3(seed, g, side)) * GLYPHS.size()) % GLYPHS.size()]
			for st: Array in glyph:
				_stroke(xf * fr, (st[0] as Vector2) * GLYPH_CELL, (st[1] as Vector2) * GLYPH_CELL, 0.075, phase + g * 0.08)


## The frame of a broad face at height y (between rings): origin on the surface at the face centre, x along the face,
## y up the face, z = outward normal. side +1 = the +Z face, -1 = the -Z face (x mirrored so glyphs read right).
func _face_frame(rings: Array, y: float, side: float) -> Transform3D:
	var k: int = 0
	while k < rings.size() - 2 and float(rings[k + 1][0]) < y:
		k += 1
	var r0: Array = rings[k]
	var r1: Array = rings[k + 1]
	var t: float = clampf((y - float(r0[0])) / (float(r1[0]) - float(r0[0])), 0.0, 1.0)
	var tz: float = lerpf(float(r0[2]), float(r1[2]), t)
	var xo: float = lerpf(float(r0[3]), float(r1[3]), t) + lerpf(float(r0[1]), float(r1[1]), t) * 0.01
	var dtdy: float = (float(r1[2]) - float(r0[2])) / (float(r1[0]) - float(r0[0]))
	var dxdy: float = (float(r1[3]) - float(r0[3])) / (float(r1[0]) - float(r0[0]))
	var ax := Vector3(side, 0.0, 0.0)
	var ay := Vector3(dxdy, 1.0, dtdy * side).normalized()
	var az: Vector3 = ax.cross(ay).normalized()
	ay = az.cross(ax).normalized()
	return Transform3D(Basis(ax, ay, az), Vector3(xo, y, tz * side))


## A glowing rune stroke a -> b in the face frame `fr` (points in metres), width w, sitting just on the surface.
func _stroke(fr: Transform3D, a: Vector2, b: Vector2, w: float, phase: float) -> void:
	var d: Vector2 = b - a
	var len: float = d.length() + w * 0.8
	var mid: Vector2 = (a + b) * 0.5
	var rot := Basis(Vector3.BACK, d.angle())
	# The carved groove (painted, dark, a little wider) and the faint glowing inlay in it.
	_part(_box(Vector3(len + 0.05, w + 0.05, 0.02)), fr * Transform3D(rot, Vector3(mid.x, mid.y, 0.0)), GROOVE,
		{"kind": Kind.STONE, "moss": 0.0, "tint": 0.04})
	var xf: Transform3D = fr * Transform3D(rot, Vector3(mid.x, mid.y, 0.007))
	_part(_box(Vector3(len, w, 0.03)), xf, RUNE, {"rune": true, "phase": fposmod(phase, 1.0)})


## The fallen stone: lying along the ring (tangent), sunk 30 %, snapped in two; its runes face the sky.
func _fallen_stone(base: Vector3, ang: float, length: float, w0: float, t0: float, col: Color, seed: float) -> void:
	var tangent := Vector3(-sin(ang), 0.0, cos(ang))
	# Main piece: a menhir of 70 % length laid down: local +Y -> tangent, local +Z (front face) -> up.
	var h1: float = length * 0.68
	var lie := Basis(tangent.cross(Vector3.UP).normalized() * -1.0, tangent, Vector3.UP)
	lie = Basis(lie.x.normalized(), lie.y.normalized(), lie.x.cross(lie.y).normalized())
	if lie.z.y < 0.0:
		lie = Basis(-lie.x, lie.y, -lie.z)
	# Sunk so its top stays under 0.45 m: units walk over it outside its r 0.5 collider (map-fill 3.2).
	var start: Vector3 = base - tangent * (h1 * 0.5) + Vector3(0, t0 * 0.22, 0)
	var xf := Transform3D(lie * Basis(Vector3.UP, 0.08), start)
	var rings: Array = _menhir_rings(h1, w0, t0, seed)
	# Broken end (the last ring) capped jagged, the foot (first ring) capped too: it was pulled out of the ground.
	var last: Array = rings[rings.size() - 1]
	var jag := Vector3(float(last[3]) + 0.1, float(last[0]) + 0.1, 0.05)
	_part(_loft(_menhir_loft(rings, 0.0), true, true, Vector3(0.0, -0.45, 0.0), jag), xf, col.darkened(0.05),
		{"kind": Kind.STONE, "moss": 0.95, "tint": 0.1})
	for g: int in 3:
		var gy: float = 0.35 + g * 0.58
		if gy + GLYPH_CELL.y > h1 * 0.92:
			break
		var fr: Transform3D = _face_frame(rings, gy, 1.0)
		var glyph: Array = GLYPHS[(g * 3 + 1) % GLYPHS.size()]
		for st: Array in glyph:
			_stroke(xf * fr, (st[0] as Vector2) * GLYPH_CELL, (st[1] as Vector2) * GLYPH_CELL, 0.075, 0.8 + g * 0.08)
	# The snapped top: a short blunt piece lying just past the break, kinked 25 deg, sunk into the turf.
	var top_rings: Array = _menhir_rings(length * 0.32, w0 * 0.8, t0 * 0.85, seed + 3.0)
	var kink := Basis(Vector3.UP, 0.45)
	var xf2 := Transform3D(kink * lie * Basis(Vector3.UP, 0.25), base + tangent * (h1 * 0.5 + 0.5)
		+ tangent.cross(Vector3.UP) * 0.15 + Vector3(0.0, t0 * 0.12, 0.0))
	var tlast: Array = top_rings[top_rings.size() - 1]
	_part(_loft(_menhir_loft(top_rings, 0.25), true, true, Vector3(0.0, -0.4, 0.0),
		Vector3(float(tlast[3]), length * 0.32 + 0.04, 0.0)), xf2, col, {"kind": Kind.STONE, "moss": 0.85, "tint": 0.1})
	# A shallow socket where it stood, packing stones scattered.
	_stone(_chunk(Vector3(0.22, 0.1, 0.18), 4, seed + 7.0), _xf(base + tangent * -0.2 + Vector3(0.45, 0.03, 0.2)), GRAN_D, seed + 7.0, 0.8, 0.0)
	_stone(_chunk(Vector3(0.16, 0.09, 0.14), 4, seed + 8.0), _xf(base + tangent * 0.9 + Vector3(-0.5, 0.03, 0.1)), GRAN_D, seed + 8.0, 0.8, 0.0)
	_disc(base, 1.6, 0.85, 14, seed, -ang)
