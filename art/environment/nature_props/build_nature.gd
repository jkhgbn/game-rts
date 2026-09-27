extends SceneTree
## Task A2.8: generates the nature props with ONE shared painted material (nature_mat.tres) + one contact-shadow
## material (nature_contact_mat.tres):
##   trees   tree_pine, tree_fir, tree_broadleaf, tree_birch, tree_gold (3 shape variants each, in one mesh)
##           + tree_*_far stand-ins for the border forest (no variants, ~70-110 triangles)
##   rocks   rock_boulder, rock_slab, rock_shards, rock_spire (3 variants each)
##   ruins   ruin_pillar (3 variants: broken top, snapped with a fallen drum, leaning with its capital)
## Same file names as before (art/environment/meshes/<name>.res + art/environment/<name>.tscn), same footprints
## (trees: collider r 0.45 s; rocks: box 1.6 x 1.2 x 1.3 s at y 0.5; pillar: 3 m tall, r 0.7), so EnvProps
## (scripts/world/env_props.gd) and map_dressing.tscn pick them up unchanged.
## Variants: every part has a variant mask (UV2.x); nature_painted.gdshader picks the variant from a hash of the
## instance's world position and collapses the other variants' parts, so one MultiMesh shows 3 shapes.
## Re-run after changing a shape or colour (then run build_env.gd if the border forest layout changed):
##   $GODOT --headless --path . -s res://art/environment/nature_props/build_nature.gd --quit-after 600

const DIR := "res://art/environment/"
const NDIR := "res://art/environment/nature_props/"
const MESH_DIR := "res://art/environment/meshes/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4
const V01 := 3
const V12 := 6
const V02 := 5

# Palette (sRGB). Foliage is deeper / bluer than the lawn so crowns read against it; the shader adds the warm
# sunlit tops, cool shadows and per-instance hue shifts.
const TRUNK := Color(0.33, 0.24, 0.17)
const TRUNK_D := Color(0.23, 0.17, 0.12)
const PINE_D := Color(0.08, 0.22, 0.15)
const PINE := Color(0.13, 0.31, 0.18)
const PINE_L := Color(0.26, 0.46, 0.22)
const FIR_D := Color(0.10, 0.27, 0.21)
const FIR := Color(0.15, 0.36, 0.28)
const FIR_L := Color(0.28, 0.50, 0.37)
const OAK_D := Color(0.13, 0.29, 0.12)
const OAK := Color(0.22, 0.41, 0.15)
const OAK_L := Color(0.36, 0.53, 0.18)
const BIRCH_BARK := Color(0.86, 0.84, 0.78)
const BIRCH_LEAF_D := Color(0.33, 0.47, 0.15)
const BIRCH_LEAF := Color(0.47, 0.60, 0.20)
const BIRCH_LEAF_L := Color(0.64, 0.74, 0.28)
const GOLD_D := Color(0.50, 0.30, 0.12)
const GOLD := Color(0.70, 0.50, 0.19)
const GOLD_L := Color(0.86, 0.70, 0.33)
const STONE := Color(0.43, 0.42, 0.42)
const STONE_W := Color(0.46, 0.44, 0.41)
const STONE_B := Color(0.40, 0.41, 0.44)
const STONE_D := Color(0.30, 0.29, 0.30)
const RUIN := Color(0.53, 0.51, 0.52)
const RUIN_L := Color(0.60, 0.58, 0.57)
const RUIN_D := Color(0.35, 0.34, 0.35)
const IVY := Color(0.15, 0.32, 0.13)
const IVY_L := Color(0.27, 0.46, 0.17)

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var _conv: float = 1.0

# Current mesh (surface 0) and its contact disc (surface 1).
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _w := PackedFloat32Array()     # stone: moss amount (trees get their wind weight at commit)
var _uv2 := PackedVector2Array()   # (variant mask, kind)
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
var _report: Array = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	_make_materials()
	_build_pine()
	_build_fir()
	_build_broadleaf()
	_build_birch()
	_build_gold()
	_build_far_trees()
	_build_boulder()
	_build_slab()
	_build_shards()
	_build_spire()
	_build_pillar()
	for line: String in _report:
		print(line)
	print("NATURE BUILD OK")
	quit()


# --- materials ---------------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


## Saves, then returns the resource loaded back from its file, so whatever uses it next REFERENCES the file
## (ext_resource) instead of embedding a private copy: every prop mesh shares the one nature_mat.tres, every
## scene points at meshes/<name>.res.
func _save_ref(res: Resource, path: String) -> Resource:
	_save(res, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


func _make_materials() -> void:
	var noise: Texture2D = load("res://art/shaders/paint_noise.tres") as Texture2D
	var m := ShaderMaterial.new()
	m.shader = load(NDIR + "nature_painted.gdshader") as Shader
	m.set_shader_parameter("noise_tex", noise)
	mat = _save_ref(m, NDIR + "nature_mat.tres") as ShaderMaterial
	var cm := ShaderMaterial.new()
	cm.shader = load(NDIR + "nature_contact.gdshader") as Shader
	cm.set_shader_parameter("noise_tex", noise)
	cm.render_priority = -1
	contact_mat = _save_ref(cm, NDIR + "nature_contact_mat.tres") as ShaderMaterial


# --- mesh building -----------------------------------------------------------------------------

func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


## A transform whose local +Y runs from `a` to `b` (length |b - a|, so a unit-height primitive centred at 0.5
## spans a -> b when its height is 1; use _limb for cylinders).
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


## Adds mesh arrays, transformed. Options (all optional):
##   kind (Kind), mask (variant bits, 0 = always), jitter (m), seed, jit_axes (Vector3),
##   normals: "flat" (faceted, rocks) | "smooth" (the arrays' own normals) | "crown" (smooth, bent toward a
##   crown centre so a cluster of blobs shades as one soft volume): crown (Vector3), crown_k (0-1), crown_s (Vector3
##   squash of the crown ellipsoid),
##   col2 + grad ("y" part height, "r" distance from the part axis): colour gradient across the part,
##   ao_c (Vector3) + ao_r (m): darker toward the crown's core, moss (stone moss amount 0-1),
##   no_caps (drop +-Y cap faces of cylinders), tint (random value variation, default 0.08).
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.BARK)
	var mask: int = o.get("mask", 0)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var jit_axes: Vector3 = o.get("jit_axes", Vector3.ONE)
	var mode: String = o.get("normals", "flat")
	var crown: Vector3 = o.get("crown", Vector3.ZERO)
	var crown_k: float = o.get("crown_k", 0.6)
	var crown_s: Vector3 = o.get("crown_s", Vector3.ONE)
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var ao_c: Vector3 = o.get("ao_c", Vector3.ZERO)
	var ao_r: float = o.get("ao_r", 0.0)
	var moss: float = o.get("moss", 0.0)
	var no_caps: bool = o.get("no_caps", false)
	var tint: float = o.get("tint", 0.08)
	var nb: Basis = xf.basis.inverse().transposed()
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
		var p: Vector3 = xf * v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter * jit_axes
		tv[i] = p
		tn[i] = (nb * n[i]).normalized()
	for t: int in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		if no_caps and absf(n[a].y) > 0.99 and absf(n[b].y) > 0.99 and absf(n[c].y) > 0.99:
			continue
		var fn: Vector3 = (tv[b] - tv[a]).cross(tv[c] - tv[a])
		if fn.length_squared() < 1e-10:
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
			var nn: Vector3 = fn
			if mode == "smooth":
				nn = tn[vi]
			elif mode == "crown":
				var cd: Vector3 = ((tv[vi] - crown) / crown_s).normalized()
				nn = tn[vi].lerp(cd, crown_k).normalized()
			var gt: float = 0.0
			if grad == "y":
				gt = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
			else:
				gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
			var cc: Color = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			if ao_r > 0.0:
				var d: Vector3 = (tv[vi] - ao_c) * Vector3(1.0, 1.3, 1.0)
				k *= lerpf(0.60, 1.04, smoothstep(0.30, 1.0, d.length() / ao_r))
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k))
			_w.append(moss)
			_uv2.append(Vector2(mask, kind))


## A limb (tapered cylinder) from a to b.
func _limb(a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Color, o: Dictionary = {}) -> void:
	var len: float = a.distance_to(b)
	var oo: Dictionary = o.duplicate()
	oo["no_caps"] = true
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	_part(_cyl(r1, r0, len, segs), Transform3D(_along(a, b), (a + b) * 0.5), col, oo)


## Flared roots: n wedges leaning out from the trunk foot, half in the ground.
func _roots(count: int, r: float, len: float, col: Color, seed: float, mask: int = 0) -> void:
	for i: int in count:
		var a: float = i * TAU / count + _h(Vector3(seed, i, 2)) * 0.9
		var d := Vector3(cos(a), 0, sin(a))
		_limb(d * r * 0.3 + Vector3(0, 0.42, 0), d * (r + len) + Vector3(0, -0.07, 0), 0.17 * r / 0.25, 0.05, 4,
			col, {"mask": mask, "seed": seed + i, "jitter": 0.015})


## A tree tier: star-skirted cone (points alternate r_out / r_in, the tips droop), a concave mid ring and a raised
## underside. Smooth normals: the tier shades as one soft cone, the tips catch light, the valleys stay dark.
func _tier(r_out: float, r_in: float, h: float, points: int, droop: float) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var m: int = points * 2
	v.append(Vector3(0, h, 0))
	n.append(Vector3.UP)
	for i: int in m:   # mid ring (1..m)
		var a: float = (i + 0.5) * PI / points
		var rm: float = (r_out if i % 2 == 0 else r_in) * 0.5
		v.append(Vector3(cos(a) * rm, h * 0.5, sin(a) * rm))
		n.append(Vector3(cos(a) * 0.55, 1.0, sin(a) * 0.55).normalized())
	for i: int in m:   # outer star (m+1..2m)
		var a2: float = i * PI / points
		var tip: bool = i % 2 == 0
		var r: float = r_out if tip else r_in
		v.append(Vector3(cos(a2) * r, -droop if tip else -droop * 0.35, sin(a2) * r))
		n.append(Vector3(cos(a2), 0.42 if tip else 0.62, sin(a2)).normalized())
	for i: int in m:
		idx.append_array([0, 1 + i, 1 + (i + 1) % m])
	for i: int in m:
		var mi: int = 1 + i
		var mj: int = 1 + (i + 1) % m
		var oi: int = 1 + m + i
		var oj: int = 1 + m + (i + 1) % m
		idx.append_array([mi, oi, oj, mi, oj, mj])
	var base: int = v.size()
	v.append(Vector3(0, h * 0.2, 0))
	n.append(Vector3.DOWN)
	for i: int in m:
		v.append(v[1 + m + i])
		n.append((Vector3.DOWN * 1.2 + Vector3(v[1 + m + i].x, 0, v[1 + m + i].z).normalized() * 0.4).normalized())
	for i: int in m:
		idx.append_array([base, base + 1 + i, base + 1 + (i + 1) % m])
	return _mk(v, n, idx)


## Simple tier for the far trees: star cone + underside, no mid ring.
func _tier_far(r_out: float, r_in: float, h: float, points: int, droop: float) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var m: int = points * 2
	v.append(Vector3(0, h, 0))
	n.append(Vector3.UP)
	for i: int in m:
		var a: float = i * PI / points
		var tip: bool = i % 2 == 0
		var r: float = r_out if tip else r_in
		v.append(Vector3(cos(a) * r, -droop if tip else 0.0, sin(a) * r))
		n.append(Vector3(cos(a), 0.5 if tip else 0.7, sin(a)).normalized())
	for i: int in m:
		idx.append_array([0, 1 + i, 1 + (i + 1) % m])
	var base: int = v.size()
	v.append(Vector3(0, h * 0.2, 0))
	n.append(Vector3.DOWN)
	for i: int in m:
		v.append(v[1 + i])
		n.append(Vector3.DOWN)
	for i: int in m:
		idx.append_array([base, base + 1 + i, base + 1 + (i + 1) % m])
	return _mk(v, n, idx)


## A chiselled rock: a low-poly ellipsoid cut by `cuts` random planes (+ a flat top plane) so it gets a few big flat
## facets like a hand-sculpted stone. Local origin = the ellipsoid centre.
func _chunk(radii: Vector3, cuts: int, seed: float, top: float = 0.78, segs: int = 7, rings: int = 4) -> Array:
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


## Soft contact shadow under the prop (surface 1): an irregular disc just above the ground.
func _disc(c: Vector3, rx: float, rz: float, segs: int, seed: float, mask: int = 0) -> void:
	var ring: Array[Vector3] = []
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.3
		ring.append(Vector3(c.x + cos(a) * rx * j, 0.035, c.z + sin(a) * rz * j))
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
			_cuv2.append(Vector2(mask, 0.0))


## Bakes the height gradient (COLOR.a), wind weight / moss (UV.x), local height (UV.y) and variant / kind (UV2),
## saves the mesh (surface 0: nature_mat, surface 1: contact disc if any). `tree_h` > 0: wind weight from the root
## (0) to the top (1), the same curve for every part so the crown never tears from the trunk.
func _commit(name: String, tree_h: float = 0.0) -> ArrayMesh:
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - miny, 0.01)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = clampf((_v[i].y - miny) / span, 0.0, 1.0)
		_c[i] = cc
		var w: float = _w[i]
		if tree_h > 0.0 and int(_uv2[i].y) != Kind.STONE:
			w = pow(clampf((_v[i].y - 0.35) / (tree_h - 0.35), 0.0, 1.0), 1.6)
		uv[i] = Vector2(w, _v[i].y)
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
	if not _cv.is_empty():
		var ca: Array = []
		ca.resize(Mesh.ARRAY_MAX)
		ca[Mesh.ARRAY_VERTEX] = _cv
		ca[Mesh.ARRAY_NORMAL] = _cn
		ca[Mesh.ARRAY_TEX_UV] = _cuv
		ca[Mesh.ARRAY_TEX_UV2] = _cuv2
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(ca))
		mesh.surface_set_material(1, contact_mat)
	mesh = _save_ref(mesh, MESH_DIR + name + ".res") as ArrayMesh
	# Triangles per variant (what one instance rasterises).
	var per := [0, 0, 0]
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	_report.append("mesh %-20s %4d tris, %4d verts (variants %d / %d / %d), contact %d, y %.2f..%.2f" % [name,
		_v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2], _cv.size() / 3,
		miny, maxy])
	# One mesh per variant too (<name>_v0/_v1/_v2.res, mask 0 = always drawn): for placement code that picks the
	# variant itself (no collapsed triangles at all). Same look: the shader keys everything else on the position.
	var has_variants := false
	for t2: int in range(0, _uv2.size(), 3):
		if _uv2[t2].x > 0.5:
			has_variants = true
			break
	if has_variants:
		for k2: int in 3:
			_save(_variant_mesh(arrays, _contact_arrays(), k2), MESH_DIR + "%s_v%d.res" % [name, k2])
	return mesh


## Non-indexed triangle arrays -> indexed ones, merging vertices whose every attribute matches. The smooth parts
## (crowns, tiers, trunks) share most vertices, so the GPU shades each once instead of once per triangle: the
## props are drawn map-wide in 6 passes (depth, colour, 4 shadow splits), vertex work is their main cost.
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


func _contact_arrays() -> Array:
	if _cv.is_empty():
		return []
	var ca: Array = []
	ca.resize(Mesh.ARRAY_MAX)
	ca[Mesh.ARRAY_VERTEX] = _cv
	ca[Mesh.ARRAY_NORMAL] = _cn
	ca[Mesh.ARRAY_TEX_UV] = _cuv
	ca[Mesh.ARRAY_TEX_UV2] = _cuv2
	return ca


## The triangles of variant k only (their mask set to 0).
func _variant_mesh(arrays: Array, contact: Array, k: int) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var surfaces: Array = [[arrays, mat]]
	if not contact.is_empty():
		surfaces.append([contact, contact_mat])
	for sf: Array in surfaces:
		var src: Array = sf[0]
		var sv: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
		var s2: PackedVector2Array = src[Mesh.ARRAY_TEX_UV2]
		var out: Array = []
		out.resize(Mesh.ARRAY_MAX)
		var keep := PackedInt32Array()
		for t: int in range(0, sv.size(), 3):
			var m: int = int(s2[t].x)
			if m == 0 or ((m >> k) & 1) == 1:
				keep.append_array([t, t + 1, t + 2])
		for a: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
			if src[a] == null:
				continue
			var dst: Variant = null
			match a:
				Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL:
					var pv := PackedVector3Array()
					for i: int in keep:
						pv.append((src[a] as PackedVector3Array)[i])
					dst = pv
				Mesh.ARRAY_COLOR:
					var pc := PackedColorArray()
					for i: int in keep:
						pc.append((src[a] as PackedColorArray)[i])
					dst = pc
				_:
					var p2 := PackedVector2Array()
					for i: int in keep:
						var uvv: Vector2 = (src[a] as PackedVector2Array)[i]
						if a == Mesh.ARRAY_TEX_UV2:
							uvv.x = 0.0
						p2.append(uvv)
					dst = p2
			out[a] = dst
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(out))
		mesh.surface_set_material(mesh.get_surface_count() - 1, sf[1])
	return mesh


func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


## art/environment/<name>.tscn: a Node3D with one MeshInstance3D "Mesh" (same layout as before).
func _single(name: String, mesh: Mesh) -> void:
	var root := Node3D.new()
	root.name = name.to_pascal_case()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	root.add_child(mi)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, DIR + name + ".tscn")
	root.free()


# --- trees (s = 1: collider radius 0.45, height 2 at y 1) ---------------------------------------

## Stacked tiers: [radius, y, height, points, colour t 0-1, sideways offset (Vector2)], dark -> light.
func _tiers(list: Array, dark: Color, mid: Color, light: Color, mask: int, seed: float, droop: float = 0.42,
		kind: int = Kind.NEEDLES) -> void:
	var i: int = 0
	for t: Array in list:
		var r: float = t[0]
		var ct: float = t[4]
		var off: Vector2 = t[5] if t.size() > 5 else Vector2.ZERO
		var base_col: Color = dark.lerp(mid, ct)
		var tip_col: Color = mid.lerp(light, ct)
		_part(_tier(r, r * 0.68, t[2] * 1.2, t[3], droop * r / 1.6), _xf(Vector3(off.x, t[1], off.y),
			Vector3(0, seed + i * 0.83, 0)), base_col, {"kind": kind, "mask": mask, "normals": "smooth",
			"col2": tip_col, "grad": "r", "jitter": 0.05, "seed": seed + i, "tint": 0.10})
		i += 1


func _build_pine() -> void:
	_begin()
	_limb(Vector3(0, -0.15, 0), Vector3(0, 2.3, 0), 0.25, 0.12, 6, TRUNK, {"seed": 1.0, "jitter": 0.02})
	_roots(5, 0.24, 0.3, TRUNK_D, 1.0)
	# V0: classic, 5 tiers.
	_tiers([[1.75, 1.25, 1.25, 7, 0.0], [1.45, 1.95, 1.2, 7, 0.25], [1.15, 2.65, 1.15, 7, 0.5], [0.85, 3.3, 1.05, 6, 0.75],
		[0.55, 3.9, 1.0, 6, 1.0]], PINE_D, PINE, PINE_L, V0, 2.0)
	_part(_cyl(0.0, 0.2, 0.65, 5), _xf(Vector3(0, 5.05, 0)), PINE_L, {"kind": Kind.NEEDLES, "mask": V0,
		"normals": "smooth", "no_caps": true})
	# V1: tall and slim, 6 tiers.
	_tiers([[1.4, 1.35, 1.15, 7, 0.0], [1.2, 1.97, 1.1, 7, 0.2], [1.0, 2.6, 1.05, 6, 0.4], [0.82, 3.2, 1.0, 6, 0.6],
		[0.62, 3.8, 0.95, 6, 0.8], [0.42, 4.4, 0.9, 5, 1.0]], PINE_D, PINE, PINE_L, V1, 3.5)
	_part(_cyl(0.0, 0.16, 0.7, 5), _xf(Vector3(0, 5.55, 0)), PINE_L, {"kind": Kind.NEEDLES, "mask": V1,
		"normals": "smooth", "no_caps": true})
	# V2: old and bushy, 4 wide tiers pushed off-centre, a broken top and a dead snag.
	_tiers([[1.95, 1.1, 1.3, 8, 0.0, Vector2(0.08, -0.05)], [1.6, 1.85, 1.25, 7, 0.35, Vector2(-0.12, 0.08)],
		[1.2, 2.6, 1.15, 7, 0.7, Vector2(0.1, 0.1)], [0.8, 3.3, 0.9, 6, 1.0, Vector2(-0.05, -0.08)]],
		PINE_D, PINE.lerp(PINE_D, 0.15), PINE_L, V2, 5.0, 0.36)
	_limb(Vector3(0.0, 3.9, 0.0), Vector3(0.12, 4.55, -0.05), 0.09, 0.03, 4, Color(0.42, 0.38, 0.34),
		{"mask": V2, "seed": 5.5})
	_limb(Vector3(0.1, 2.0, 0.0), Vector3(1.0, 2.35, 0.55), 0.06, 0.015, 4, Color(0.42, 0.38, 0.34),
		{"mask": V2, "seed": 5.7})
	_disc(Vector3(0.1, 0, 0.15), 1.55, 1.5, 12, 1.0)
	_single("tree_pine", _commit("tree_pine", 5.3))


func _build_fir() -> void:
	_begin()
	_limb(Vector3(0, -0.15, 0), Vector3(0, 2.0, 0), 0.23, 0.1, 6, TRUNK_D, {"seed": 4.0, "jitter": 0.02})
	_roots(5, 0.22, 0.28, TRUNK_D, 4.0)
	# V0: tall narrow spire, 6 tiers.
	var l0: Array = []
	for i: int in 6:
		var r: float = 1.32 - i * 0.2
		l0.append([r, 1.1 + i * 0.66, 1.05, 6, i / 5.0])
	_tiers(l0, FIR_D, FIR, FIR_L, V0, 20.0, 0.24)
	_part(_cyl(0.0, 0.16, 0.8, 5), _xf(Vector3(0, 5.4, 0)), FIR_L, {"kind": Kind.NEEDLES, "mask": V0,
		"normals": "smooth", "no_caps": true})
	# V1: twin leaders: 5 tiers, then two small tops side by side.
	var l1: Array = []
	for i: int in 5:
		l1.append([1.4 - i * 0.2, 1.05 + i * 0.64, 1.05, 6, i / 5.0])
	_tiers(l1, FIR_D, FIR, FIR_L, V1, 24.0, 0.24)
	for k: int in 2:
		var sx: float = -0.28 if k == 0 else 0.3
		var hh: float = 1.25 if k == 0 else 0.95
		_part(_tier(0.45, 0.28, hh, 5, 0.08), _xf(Vector3(sx, 4.25, 0.05 * k), Vector3(0, k * 0.7, sx * 0.25)),
			FIR, {"kind": Kind.NEEDLES, "mask": V1, "normals": "smooth", "col2": FIR_L, "grad": "y", "seed": 26.0 + k})
	# V2: windswept: tiers drift to one side, flattened across the wind.
	var l2: Array = []
	for i: int in 6:
		l2.append([1.3 - i * 0.19, 1.1 + i * 0.64, 1.0, 6, i / 5.0, Vector2(0.07 * i, 0.03 * i)])
	_tiers(l2, FIR_D, FIR, FIR_L, V2, 28.0, 0.28)
	_part(_cyl(0.0, 0.15, 0.7, 5), _xf(Vector3(0.42, 5.1, 0.18), Vector3(0, 0, -0.18)), FIR_L,
		{"kind": Kind.NEEDLES, "mask": V2, "normals": "smooth", "no_caps": true})
	_disc(Vector3(0.1, 0, 0.1), 1.3, 1.25, 12, 4.0)
	_single("tree_fir", _commit("tree_fir", 5.6))


## Leaf blobs: [centre, radius, squash (Vector3), colour t 0 (dark) - 1 (light)] around a crown centre.
func _blobs(list: Array, crown: Vector3, crown_r: float, dark: Color, mid: Color, light: Color, mask: int,
		seed: float, kind: int = Kind.LEAVES, segs: int = 7, rings: int = 4) -> void:
	var i: int = 0
	for b: Array in list:
		var ct: float = b[3]
		var c0: Color = dark.lerp(mid, minf(ct * 2.0, 1.0)) if ct < 0.5 else mid.lerp(light, (ct - 0.5) * 2.0)
		_part(_sph(b[1], segs, rings), _xf(b[0], Vector3(0.0, i * 1.1, 0.0), b[2]), c0.darkened(0.12),
			{"kind": kind, "mask": mask, "normals": "crown", "crown": crown, "crown_k": 0.62,
			"crown_s": Vector3(1.0, 0.8, 1.0), "col2": c0.lightened(0.10), "grad": "y", "jitter": b[1] * 0.16,
			"seed": seed + i, "ao_c": crown, "ao_r": crown_r, "tint": 0.10})
		i += 1


func _build_broadleaf() -> void:
	_begin()
	_roots(5, 0.3, 0.32, TRUNK_D, 3.0)
	# V0: round oak. Trunk + 3 limbs + 7 blobs.
	_limb(Vector3(0, -0.15, 0), Vector3(0.05, 2.4, 0), 0.34, 0.2, 7, TRUNK, {"mask": V0, "seed": 3.0, "jitter": 0.03})
	_limb(Vector3(0.05, 1.9, 0), Vector3(0.95, 2.75, 0.3), 0.14, 0.06, 5, TRUNK_D, {"mask": V0})
	_limb(Vector3(0.0, 2.0, 0), Vector3(-0.85, 2.8, -0.35), 0.14, 0.06, 5, TRUNK_D, {"mask": V0})
	_limb(Vector3(0.05, 2.2, 0), Vector3(0.1, 3.0, -0.85), 0.12, 0.05, 5, TRUNK_D, {"mask": V0})
	var c0 := Vector3(0.0, 3.2, 0.0)
	_blobs([[Vector3(0, 2.8, 0), 1.25, Vector3(1.1, 0.72, 1.1), 0.0], [Vector3(0.95, 3.0, 0.35), 0.95, Vector3.ONE, 0.35],
		[Vector3(-0.9, 3.05, -0.35), 1.0, Vector3.ONE, 0.3], [Vector3(0.2, 3.1, -0.95), 0.9, Vector3.ONE, 0.45],
		[Vector3(-0.3, 3.15, 0.9), 0.92, Vector3.ONE, 0.5], [Vector3(0.15, 3.8, 0.05), 1.05, Vector3(1.0, 0.85, 1.0), 0.8],
		[Vector3(-0.35, 4.35, -0.2), 0.62, Vector3.ONE, 1.0]], c0, 2.0, OAK_D, OAK, OAK_L, V0, 10.0)
	_disc(Vector3(0, 0, 0.1), 1.9, 1.8, 14, 3.0, V0)
	# V1: tall oval crown on a longer trunk, three storeys of blobs.
	_limb(Vector3(0, -0.15, 0), Vector3(-0.05, 2.9, 0.05), 0.32, 0.18, 7, TRUNK, {"mask": V1, "seed": 3.3, "jitter": 0.03})
	_limb(Vector3(-0.05, 2.3, 0.05), Vector3(0.6, 3.3, 0.2), 0.12, 0.05, 5, TRUNK_D, {"mask": V1})
	_limb(Vector3(-0.05, 2.5, 0.05), Vector3(-0.55, 3.5, -0.3), 0.12, 0.05, 5, TRUNK_D, {"mask": V1})
	var c1 := Vector3(0.0, 3.7, 0.0)
	_blobs([[Vector3(0, 3.0, 0), 1.1, Vector3(1.1, 0.75, 1.05), 0.0], [Vector3(0.6, 3.5, 0.3), 0.85, Vector3.ONE, 0.35],
		[Vector3(-0.6, 3.6, -0.25), 0.88, Vector3.ONE, 0.35], [Vector3(0.05, 3.7, -0.65), 0.8, Vector3.ONE, 0.5],
		[Vector3(0.0, 4.4, 0.15), 0.95, Vector3(1.0, 0.9, 1.0), 0.8], [Vector3(0.1, 5.05, -0.05), 0.6, Vector3.ONE, 1.0]],
		c1, 1.9, OAK_D, OAK, OAK_L, V1, 20.0)
	_disc(Vector3(0, 0, 0.1), 1.5, 1.45, 14, 3.5, V1)
	# V2: wide spreading tree: a forked trunk, two low lobes over the limbs, flat top.
	_limb(Vector3(0, -0.15, 0), Vector3(0.0, 1.5, 0), 0.38, 0.28, 7, TRUNK, {"mask": V2, "seed": 3.6, "jitter": 0.03})
	_limb(Vector3(0.0, 1.35, 0), Vector3(1.05, 2.7, 0.15), 0.22, 0.1, 6, TRUNK, {"mask": V2, "seed": 3.7})
	_limb(Vector3(0.0, 1.35, 0), Vector3(-0.95, 2.65, -0.2), 0.22, 0.1, 6, TRUNK, {"mask": V2, "seed": 3.8})
	var c2 := Vector3(0.0, 2.95, 0.0)
	_blobs([[Vector3(1.1, 2.9, 0.1), 1.05, Vector3(1.15, 0.7, 1.1), 0.1], [Vector3(-1.05, 2.85, -0.15), 1.05,
		Vector3(1.15, 0.7, 1.1), 0.1], [Vector3(0.0, 3.1, 0.0), 1.0, Vector3(1.2, 0.7, 1.15), 0.3],
		[Vector3(0.55, 3.45, -0.55), 0.85, Vector3(1.0, 0.8, 1.0), 0.6], [Vector3(-0.55, 3.5, 0.55), 0.85,
		Vector3(1.0, 0.8, 1.0), 0.7], [Vector3(0.1, 3.75, 0.05), 0.75, Vector3(1.0, 0.75, 1.0), 1.0]], c2, 2.3,
		OAK_D, OAK, OAK_L, V2, 30.0)
	_disc(Vector3(0, 0, 0.1), 2.3, 1.9, 14, 3.9, V2)
	_single("tree_broadleaf", _commit("tree_broadleaf", 5.0))


func _build_birch() -> void:
	_begin()
	var bark := {"kind": Kind.BIRCH, "seed": 30.0, "jitter": 0.012}
	# V0: one slender trunk.
	_limb(Vector3(0, -0.15, 0), Vector3(0.1, 3.4, 0.0), 0.2, 0.1, 6, BIRCH_BARK, bark.merged({"mask": V0}))
	_limb(Vector3(0.06, 2.3, 0), Vector3(0.55, 3.0, 0.15), 0.06, 0.03, 4, BIRCH_BARK.darkened(0.1),
		bark.merged({"mask": V0}))
	_blobs([[Vector3(0.1, 3.2, 0.1), 0.95, Vector3(1.0, 1.1, 1.0), 0.0], [Vector3(0.7, 3.55, -0.2), 0.7, Vector3.ONE, 0.4],
		[Vector3(-0.55, 3.65, 0.3), 0.72, Vector3.ONE, 0.35], [Vector3(0.05, 4.25, -0.1), 0.78, Vector3.ONE, 0.75],
		[Vector3(0.3, 4.8, 0.2), 0.46, Vector3.ONE, 1.0]], Vector3(0.1, 3.8, 0.0), 1.5, BIRCH_LEAF_D, BIRCH_LEAF,
		BIRCH_LEAF_L, V0, 35.0)
	_disc(Vector3(0.1, 0, 0.1), 1.3, 1.25, 12, 30.0, V0)
	# V1: twin trunks from one foot, two small crowns.
	_limb(Vector3(0, -0.15, 0), Vector3(-0.45, 3.1, 0.05), 0.19, 0.08, 6, BIRCH_BARK, bark.merged({"mask": V1}))
	_limb(Vector3(0.05, -0.15, 0), Vector3(0.5, 3.5, -0.1), 0.17, 0.07, 6, BIRCH_BARK.darkened(0.05),
		bark.merged({"mask": V1}))
	_blobs([[Vector3(-0.55, 3.2, 0.1), 0.78, Vector3(1.0, 1.1, 1.0), 0.1], [Vector3(-0.7, 3.85, -0.05), 0.55, Vector3.ONE, 0.8],
		[Vector3(0.6, 3.55, -0.1), 0.82, Vector3(1.0, 1.1, 1.0), 0.2], [Vector3(0.55, 4.25, 0.05), 0.6, Vector3.ONE, 0.9],
		[Vector3(0.0, 3.55, 0.1), 0.55, Vector3.ONE, 0.45]], Vector3(0.0, 3.7, 0.0), 1.5, BIRCH_LEAF_D, BIRCH_LEAF,
		BIRCH_LEAF_L, V1, 40.0)
	_disc(Vector3(0.0, 0, 0.1), 1.45, 1.2, 12, 31.0, V1)
	# V2: a leaning birch, crown thrown to one side.
	_limb(Vector3(0, -0.15, 0), Vector3(0.95, 3.1, 0.25), 0.2, 0.09, 6, BIRCH_BARK, bark.merged({"mask": V2}))
	_limb(Vector3(0.6, 2.2, 0.15), Vector3(0.2, 2.9, 0.0), 0.06, 0.03, 4, BIRCH_BARK.darkened(0.1),
		bark.merged({"mask": V2}))
	_blobs([[Vector3(1.0, 3.15, 0.25), 0.9, Vector3(1.1, 1.0, 1.0), 0.0], [Vector3(0.35, 3.1, 0.05), 0.62, Vector3.ONE, 0.3],
		[Vector3(1.45, 3.55, -0.1), 0.62, Vector3.ONE, 0.5], [Vector3(0.95, 3.95, 0.3), 0.68, Vector3.ONE, 0.85]],
		Vector3(0.95, 3.5, 0.2), 1.3, BIRCH_LEAF_D, BIRCH_LEAF, BIRCH_LEAF_L, V2, 45.0)
	_disc(Vector3(0.6, 0, 0.2), 1.45, 1.15, 12, 32.0, V2)
	_single("tree_birch", _commit("tree_birch", 4.8))


func _build_gold() -> void:
	_begin()
	_roots(5, 0.32, 0.34, TRUNK_D, 40.0)
	# V0: wide dome.
	_limb(Vector3(0, -0.15, 0), Vector3(0, 2.1, 0), 0.38, 0.24, 7, TRUNK_D, {"mask": V0, "seed": 40.0, "jitter": 0.03})
	_limb(Vector3(0, 1.7, 0), Vector3(1.1, 2.55, 0.1), 0.16, 0.07, 5, TRUNK_D, {"mask": V0})
	_limb(Vector3(0, 1.7, 0), Vector3(-1.0, 2.5, -0.1), 0.16, 0.07, 5, TRUNK_D, {"mask": V0})
	_blobs([[Vector3(0, 2.65, 0), 1.4, Vector3(1.25, 0.55, 1.2), 0.0], [Vector3(1.1, 2.95, 0.2), 0.95,
		Vector3(1.0, 0.75, 1.0), 0.4], [Vector3(-1.05, 3.0, -0.25), 1.0, Vector3(1.0, 0.75, 1.0), 0.4],
		[Vector3(0.1, 3.2, 0.9), 0.95, Vector3(1.0, 0.75, 1.0), 0.55], [Vector3(-0.1, 3.3, -0.9), 0.9,
		Vector3(1.0, 0.75, 1.0), 0.6], [Vector3(0.1, 3.65, 0.0), 1.0, Vector3(1.0, 0.7, 1.0), 1.0]],
		Vector3(0, 3.0, 0), 2.2, GOLD_D, GOLD, GOLD_L, V0, 45.0, Kind.GOLD)
	_disc(Vector3(0, 0, 0.1), 2.1, 2.0, 14, 40.0, V0)
	# V1: two layered tiers of foliage (a flat lower skirt and a smaller top).
	_limb(Vector3(0, -0.15, 0), Vector3(0.05, 3.2, 0), 0.36, 0.18, 7, TRUNK_D, {"mask": V1, "seed": 41.0, "jitter": 0.03})
	_blobs([[Vector3(0.6, 2.45, 0.1), 0.95, Vector3(1.2, 0.5, 1.1), 0.3], [Vector3(-0.6, 2.4, -0.1), 0.95,
		Vector3(1.2, 0.5, 1.1), 0.35], [Vector3(0.0, 2.5, 0.7), 0.85, Vector3(1.2, 0.5, 1.1), 0.45],
		[Vector3(0.05, 3.6, 0.0), 1.0, Vector3(1.15, 0.62, 1.1), 0.7], [Vector3(0.1, 4.1, 0.1), 0.6, Vector3.ONE, 1.0]],
		Vector3(0, 3.1, 0), 1.9, GOLD_D, GOLD, GOLD_L, V1, 50.0, Kind.GOLD)
	_disc(Vector3(0, 0, 0.1), 1.7, 1.6, 14, 41.0, V1)
	# V2: a smaller, rounder tree with a crooked trunk.
	_limb(Vector3(0, -0.15, 0), Vector3(0.25, 1.4, 0.05), 0.33, 0.24, 7, TRUNK_D, {"mask": V2, "seed": 42.0})
	_limb(Vector3(0.25, 1.35, 0.05), Vector3(0.05, 2.4, -0.05), 0.24, 0.16, 6, TRUNK_D, {"mask": V2, "seed": 42.5})
	_blobs([[Vector3(0.05, 2.7, 0), 1.15, Vector3(1.1, 0.8, 1.05), 0.0], [Vector3(0.7, 3.1, 0.3), 0.8, Vector3.ONE, 0.4],
		[Vector3(-0.65, 3.15, -0.25), 0.82, Vector3.ONE, 0.45], [Vector3(0.0, 3.6, 0.0), 0.85, Vector3.ONE, 1.0]],
		Vector3(0, 3.0, 0), 1.7, GOLD_D, GOLD, GOLD_L, V2, 55.0, Kind.GOLD)
	_disc(Vector3(0, 0, 0.1), 1.6, 1.5, 12, 42.0, V2)
	_single("tree_gold", _commit("tree_gold", 4.4))


## Marks the current mesh as a "lite" border stand-in (UV2.x = -1: the shader skips its leaf-clump pass).
func _lite() -> void:
	for i: int in _uv2.size():
		_uv2[i] = Vector2(-1.0, _uv2[i].y)


## Border-forest stand-ins (seen from 25 m and more): same silhouettes and colours, few triangles, no variants
## and no contact disc (the plateau floor is painted dark already). A little darker than the map's trees so the
## playfield stays the focus.
func _build_far_trees() -> void:
	_begin()
	_limb(Vector3(0, -0.1, 0), Vector3(0, 1.6, 0), 0.24, 0.14, 4, TRUNK)
	for i: int in 3:
		var r: float = 1.8 - i * 0.45
		var col: Color = PINE_D.lerp(PINE, i / 2.0)
		_part(_tier_far(r, r * 0.7, 1.75 - i * 0.1, 6, 0.34), _xf(Vector3(0, 1.3 + i * 1.15, 0), Vector3(0, i * 0.6, 0)),
			col, {"kind": Kind.NEEDLES, "normals": "smooth", "col2": PINE_L.lerp(PINE, 0.4 - i * 0.2), "grad": "r",
			"jitter": 0.06, "seed": 2.0 + i})
	_lite()
	_commit("tree_pine_far", 5.0)
	_begin()
	_limb(Vector3(0, -0.1, 0), Vector3(0, 1.4, 0), 0.22, 0.12, 4, TRUNK_D)
	for i: int in 4:
		var r2: float = 1.3 - i * 0.26
		_part(_tier_far(r2, r2 * 0.68, 1.4, 6, 0.26), _xf(Vector3(0, 1.1 + i * 0.95, 0), Vector3(0, i * 0.7, 0)),
			FIR_D.lerp(FIR, i / 3.0), {"kind": Kind.NEEDLES, "normals": "smooth", "col2": FIR_L.lerp(FIR, 0.5 - i * 0.15),
			"grad": "r", "jitter": 0.05, "seed": 20.0 + i})
	_lite()
	_commit("tree_fir_far", 5.2)
	var sets: Array = [
		["tree_broadleaf_far", TRUNK, 2.1, Kind.LEAVES, OAK_D, OAK, OAK_L, [[Vector3(0, 2.8, 0), 1.35, 0.0],
			[Vector3(0.7, 3.2, 0.3), 1.0, 0.45], [Vector3(-0.5, 3.7, -0.2), 0.95, 0.9]]],
		["tree_birch_far", BIRCH_BARK.darkened(0.15), 2.0, Kind.LEAVES, BIRCH_LEAF_D, BIRCH_LEAF, BIRCH_LEAF_L,
			[[Vector3(0.1, 2.9, 0.1), 1.0, 0.0], [Vector3(-0.3, 3.7, 0.2), 0.8, 0.8], [Vector3(0.5, 3.4, -0.2), 0.7, 0.5]]],
		["tree_gold_far", TRUNK_D, 1.9, Kind.GOLD, GOLD_D, GOLD, GOLD_L, [[Vector3(0, 2.7, 0), 1.45, 0.0],
			[Vector3(0.6, 3.2, 0.2), 1.05, 0.5], [Vector3(-0.4, 3.5, -0.2), 1.0, 0.9]]],
	]
	for s: Array in sets:
		_begin()
		var th: float = s[2]
		_limb(Vector3(0, -0.1, 0), Vector3(0, th, 0), 0.26, 0.15, 4, s[1] as Color,
			{"kind": Kind.BIRCH if (s[0] as String).begins_with("tree_birch") else Kind.BARK})
		var k: int = 0
		var crown := Vector3(0, 3.2, 0)
		for b: Array in s[7]:
			var ct: float = b[2]
			var c0: Color = (s[4] as Color).lerp(s[5] as Color, minf(ct * 2.0, 1.0)) if ct < 0.5 \
				else (s[5] as Color).lerp(s[6] as Color, (ct - 0.5) * 2.0)
			_part(_sph(b[1] as float, 6, 3), _xf(b[0] as Vector3, Vector3(0, k, 0), Vector3(1.0, 0.85, 1.0)),
				c0.darkened(0.22), {"kind": s[3], "normals": "crown", "crown": crown, "crown_k": 0.6,
				"col2": c0.lightened(0.02), "jitter": 0.13, "seed": 60.0 + k, "ao_c": crown, "ao_r": 1.8})
			k += 1
		_lite()
		_commit(s[0] as String, 4.5)


# --- rocks (s = 1: collider box 1.6 x 1.2 x 1.3 at y 0.5; mesh fits y -0.25..1.25) ---------------

func _rock(radii: Vector3, pos: Vector3, rot: Vector3, col: Color, mask: int, seed: float, moss: float = 0.8,
		cuts: int = 5, top: float = 0.78) -> void:
	_part(_chunk(radii, cuts, seed, top), _xf(pos, rot), col, {"kind": Kind.STONE, "mask": mask, "moss": moss,
		"seed": seed, "tint": 0.12, "col2": col.lightened(0.06), "grad": "y"})


func _pebbles(count: int, r: float, dist: float, col: Color, mask: int, seed: float) -> void:
	for i: int in count:
		var a: float = i * 2.4 + seed
		var rr: float = r * (0.7 + 0.6 * _h(Vector3(seed, i, 3.0)))
		_part(_chunk(Vector3(rr, rr * 0.65, rr * 0.85), 2, seed + i * 3.1, 0.7, 5, 3),
			_xf(Vector3(cos(a), 0, sin(a)) * dist * (0.85 + 0.3 * _h(Vector3(i, seed, 1.0))) + Vector3(0, rr * 0.2, 0),
			Vector3(0.2, a, 0.1)), col, {"kind": Kind.STONE, "mask": mask, "moss": 0.3, "seed": seed + i, "tint": 0.1})


func _build_boulder() -> void:
	_begin()
	# V0: a big boulder with a smaller one leaning on it.
	_rock(Vector3(0.82, 0.72, 0.7), Vector3(0.1, 0.42, 0.0), Vector3(0.1, 0.3, 0.05), STONE, V0, 30.0)
	_rock(Vector3(0.55, 0.48, 0.52), Vector3(-0.62, 0.24, 0.3), Vector3(0.3, 1.1, -0.25), STONE.darkened(0.06), V0, 31.0)
	_pebbles(3, 0.16, 0.95, STONE.darkened(0.1), V0, 32.0)
	_disc(Vector3(0, 0, 0.05), 1.25, 1.1, 12, 30.0, V0)
	# V1: three stones huddled together, one taller.
	_rock(Vector3(0.55, 0.78, 0.52), Vector3(-0.3, 0.42, -0.15), Vector3(0.08, 0.6, -0.1), STONE_B, V1, 33.0, 0.7, 5, 0.82)
	_rock(Vector3(0.6, 0.5, 0.55), Vector3(0.42, 0.28, 0.15), Vector3(0.0, 1.9, 0.12), STONE, V1, 34.0)
	_rock(Vector3(0.42, 0.34, 0.4), Vector3(-0.15, 0.12, 0.55), Vector3(0.2, 2.8, 0.0), STONE.darkened(0.05), V1, 35.0)
	_pebbles(2, 0.15, 0.95, STONE_B.darkened(0.08), V1, 36.0)
	_disc(Vector3(0, 0, 0.1), 1.2, 1.1, 12, 33.0, V1)
	# V2: a split boulder: two halves leaning apart with a gap between them.
	for k: int in 2:
		var sgn: float = -1.0 if k == 0 else 1.0
		var arr: Array = _chunk(Vector3(0.8, 0.72, 0.66), 4, 37.0, 0.8)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i: int in v.size():   # cut along x = 0: this half keeps its side
			if v[i].x * sgn < 0.0:
				var p: Vector3 = v[i]
				p.x = 0.0
				v[i] = p
		arr[Mesh.ARRAY_VERTEX] = v
		_part(arr, _xf(Vector3(sgn * 0.12, 0.38, 0.0), Vector3(0.0, 0.3, sgn * 0.12)), STONE_W if k == 0 else STONE_W.darkened(0.05),
			{"kind": Kind.STONE, "mask": V2, "moss": 0.85, "seed": 37.0 + k, "tint": 0.12, "col2": STONE_W.lightened(0.05)})
	_pebbles(3, 0.14, 0.9, STONE_W.darkened(0.12), V2, 38.0)
	_disc(Vector3(0, 0, 0.05), 1.25, 1.05, 12, 37.0, V2)
	_single("rock_boulder", _commit("rock_boulder"))


func _plate(size: Vector3, pos: Vector3, rot: Vector3, col: Color, mask: int, seed: float, moss: float = 0.6) -> void:
	_part(_box(size, 1), _xf(pos, rot), col, {"kind": Kind.STONE, "mask": mask, "moss": moss, "jitter": 0.06,
		"seed": seed, "tint": 0.1, "col2": col.lightened(0.05), "jit_axes": Vector3(1.0, 0.5, 1.0)})


func _build_slab() -> void:
	_begin()
	# V0: stratified plates stacked and shifted.
	_plate(Vector3(1.7, 0.42, 1.32), Vector3(0, 0.1, 0), Vector3(0.05, 0.2, 0.06), STONE_W.darkened(0.08), V0, 40.0)
	_plate(Vector3(1.38, 0.36, 1.02), Vector3(-0.1, 0.48, 0.06), Vector3(-0.08, 0.55, 0.05), STONE_W, V0, 41.0)
	_plate(Vector3(1.02, 0.32, 0.8), Vector3(0.1, 0.8, -0.05), Vector3(0.1, 0.95, -0.06), STONE_W.lightened(0.04), V0, 42.0)
	_plate(Vector3(0.56, 0.28, 0.46), Vector3(0.22, 1.07, 0.05), Vector3(0.14, 1.4, -0.1), STONE_W.lightened(0.08), V0, 43.0)
	_pebbles(2, 0.15, 1.0, STONE_W.darkened(0.12), V0, 44.0)
	_disc(Vector3(0, 0, 0.05), 1.3, 1.15, 12, 40.0, V0)
	# V1: a big tilted table stone propped on a low block.
	_plate(Vector3(0.7, 0.4, 0.8), Vector3(0.45, 0.15, 0.0), Vector3(0, 0.3, 0), STONE_D.lightened(0.12), V1, 45.0, 0.5)
	_plate(Vector3(1.85, 0.34, 1.25), Vector3(-0.05, 0.52, 0.0), Vector3(0.06, 0.25, 0.3), STONE_W, V1, 46.0)
	_rock(Vector3(0.38, 0.3, 0.36), Vector3(-0.72, 0.1, 0.45), Vector3(0.1, 0.5, 0), STONE_W.darkened(0.08), V1, 47.0)
	_disc(Vector3(0, 0, 0.05), 1.35, 1.1, 12, 45.0, V1)
	# V2: a low wide shelf in two steps with a fallen piece.
	_plate(Vector3(1.9, 0.5, 1.4), Vector3(0, 0.12, 0), Vector3(0.0, -0.3, 0.04), STONE_B.lightened(0.04), V2, 48.0)
	_plate(Vector3(1.1, 0.4, 0.95), Vector3(-0.25, 0.55, -0.1), Vector3(0.05, -0.1, -0.05), STONE_B.lightened(0.1), V2, 49.0)
	_plate(Vector3(0.55, 0.3, 0.4), Vector3(0.95, 0.08, 0.55), Vector3(0.3, 0.8, 0.25), STONE_B, V2, 50.0, 0.4)
	_disc(Vector3(0, 0, 0.05), 1.4, 1.2, 12, 48.0, V2)
	_single("rock_slab", _commit("rock_slab"))


func _shard(base: Vector3, h: float, r: float, rot: Vector3, col: Color, mask: int, seed: float) -> void:
	_part(_cyl(0.02, r, h, 5), _xf(base + (Basis.from_euler(rot) * Vector3(0, h * 0.5, 0)), rot), col,
		{"kind": Kind.STONE, "mask": mask, "moss": 0.25, "jitter": r * 0.18, "seed": seed, "tint": 0.12,
		"col2": col.lightened(0.12), "no_caps": true})


func _build_shards() -> void:
	_begin()
	# V0: a crown of five spikes out of a low mound.
	_rock(Vector3(0.78, 0.36, 0.68), Vector3(0, 0.02, 0), Vector3.ZERO, STONE_B.darkened(0.18), V0, 36.0, 0.8, 4, 0.7)
	var sh: Array = [[Vector3(-0.05, 0.1, 0), 1.45, 0.34, Vector3(0.08, 0.3, -0.1)],
		[Vector3(0.42, 0.05, 0.28), 1.0, 0.27, Vector3(0.3, 1.0, -0.4)], [Vector3(-0.45, 0.05, -0.28), 0.85, 0.25,
		Vector3(-0.35, 2.0, 0.3)], [Vector3(0.3, 0.05, -0.42), 0.7, 0.2, Vector3(0.35, 0.5, 0.45)],
		[Vector3(-0.35, 0.05, 0.4), 0.55, 0.18, Vector3(-0.3, 1.4, -0.45)]]
	var i: int = 0
	for s: Array in sh:
		_shard(s[0], s[1], s[2], s[3], STONE_B.lightened(0.03 * i), V0, 37.0 + i)
		i += 1
	_disc(Vector3(0, 0, 0.05), 1.1, 1.0, 12, 36.0, V0)
	# V1: two tall blades and a broken stub.
	_rock(Vector3(0.6, 0.3, 0.55), Vector3(0, 0.0, 0), Vector3(0, 0.8, 0), STONE_B.darkened(0.2), V1, 38.0, 0.8, 4, 0.7)
	_shard(Vector3(-0.15, 0.05, 0.0), 1.6, 0.36, Vector3(0.05, 0.4, -0.12), STONE_B, V1, 39.0)
	_shard(Vector3(0.3, 0.05, 0.12), 1.2, 0.3, Vector3(-0.1, 1.2, 0.22), STONE_B.lightened(0.05), V1, 40.0)
	_part(_cyl(0.18, 0.26, 0.4, 5), _xf(Vector3(-0.2, 0.18, 0.45), Vector3(0.2, 0.3, 0.1)), STONE_B.darkened(0.05),
		{"kind": Kind.STONE, "mask": V1, "moss": 0.7, "jitter": 0.04, "seed": 41.0})
	_disc(Vector3(0, 0, 0.05), 1.0, 0.95, 12, 38.0, V1)
	# V2: a fan of leaning shards, like a burst.
	_rock(Vector3(0.7, 0.28, 0.6), Vector3(0, 0.0, 0), Vector3(0, 1.6, 0), STONE_B.darkened(0.18), V2, 42.0, 0.8, 4, 0.7)
	for k: int in 4:
		var a: float = k * 1.2 - 1.8
		_shard(Vector3(cos(a) * 0.2, 0.05, sin(a) * 0.15), 1.25 - k * 0.12, 0.26 - k * 0.02,
			Vector3(sin(a) * 0.45, a, -cos(a) * 0.35), STONE_B.lightened(0.02 * k), V2, 43.0 + k)
	_disc(Vector3(0, 0, 0.05), 1.1, 1.0, 12, 42.0, V2)
	_single("rock_shards", _commit("rock_shards"))


func _build_spire() -> void:
	_begin()
	# V0: a tall weathered needle with a leaning chunk (2.5 m).
	_part(_cyl(0.18, 0.62, 2.3, 7, 2), _xf(Vector3(0, 1.1, 0), Vector3(0.06, 0.2, -0.05)), STONE,
		{"kind": Kind.STONE, "mask": V0, "moss": 0.6, "jitter": 0.12, "seed": 50.0, "tint": 0.12, "col2": STONE.lightened(0.08)})
	_part(_cyl(0.04, 0.3, 0.9, 6), _xf(Vector3(0.05, 2.6, 0.04), Vector3(0.1, 0.9, 0.12)), STONE.lightened(0.06),
		{"kind": Kind.STONE, "mask": V0, "moss": 0.2, "jitter": 0.05, "seed": 51.0})
	_rock(Vector3(0.48, 0.34, 0.38), Vector3(0.55, 0.16, 0.2), Vector3(0.3, 0.5, 0.2), STONE.darkened(0.08), V0, 52.0)
	_disc(Vector3(0.1, 0, 0.05), 1.05, 0.95, 12, 50.0, V0)
	# V1: twin needles leaning apart.
	_part(_cyl(0.12, 0.5, 2.0, 6, 1), _xf(Vector3(-0.3, 0.95, 0), Vector3(0.0, 0.4, 0.14)), STONE_B,
		{"kind": Kind.STONE, "mask": V1, "moss": 0.6, "jitter": 0.1, "seed": 53.0, "tint": 0.12, "col2": STONE_B.lightened(0.08)})
	_part(_cyl(0.1, 0.42, 1.5, 6, 1), _xf(Vector3(0.35, 0.7, 0.1), Vector3(0.05, 1.3, -0.2)), STONE_B.lightened(0.04),
		{"kind": Kind.STONE, "mask": V1, "moss": 0.6, "jitter": 0.09, "seed": 54.0, "tint": 0.12})
	_rock(Vector3(0.35, 0.25, 0.3), Vector3(0.1, 0.1, -0.45), Vector3(0.2, 0.3, 0.0), STONE_B.darkened(0.1), V1, 55.0)
	_disc(Vector3(0, 0, 0.05), 1.05, 0.95, 12, 53.0, V1)
	# V2: a stubby broken spire, its top lying at the foot.
	_part(_cyl(0.34, 0.66, 1.45, 7, 1), _xf(Vector3(0, 0.65, 0), Vector3(0.04, 0.6, -0.03)), STONE_W,
		{"kind": Kind.STONE, "mask": V2, "moss": 0.8, "jitter": 0.12, "seed": 56.0, "tint": 0.12, "col2": STONE_W.lightened(0.06)})
	_part(_cyl(0.05, 0.32, 1.0, 6), _xf(Vector3(0.75, 0.22, 0.35), Vector3(0.0, 0.8, 1.35)), STONE_W.lightened(0.04),
		{"kind": Kind.STONE, "mask": V2, "moss": 0.5, "jitter": 0.05, "seed": 57.0})
	_rock(Vector3(0.3, 0.22, 0.28), Vector3(-0.6, 0.08, 0.2), Vector3(0.2, 1.3, 0.0), STONE_W.darkened(0.1), V2, 58.0)
	_disc(Vector3(0.15, 0, 0.1), 1.15, 1.0, 12, 56.0, V2)
	_single("rock_spire", _commit("rock_spire"))


# --- ruin pillar (3.0 m tall; EnvProps scales y by height / 3.0. Collider: cylinder r 0.7) ---------

## A fluted column drum (radius alternates r_out / r_in around 2 * flutes vertices), capped both ends.
func _fluted(r_out: float, r_in: float, h: float, flutes: int) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var m: int = flutes * 2
	for ring: int in 2:
		for i: int in m:
			var a: float = i * PI / flutes
			var r: float = r_out if i % 2 == 0 else r_in
			v.append(Vector3(cos(a) * r, h * ring, sin(a) * r))
			n.append(Vector3(cos(a), 0, sin(a)))
	for i: int in m:
		var j: int = (i + 1) % m
		idx.append_array([i, j, m + i, j, m + j, m + i])
	for cap: int in 2:
		var cbase: int = v.size()
		var up: Vector3 = Vector3.UP if cap == 1 else Vector3.DOWN
		v.append(Vector3(0, h * cap, 0))
		n.append(up)
		for i: int in m:
			v.append(v[cap * m + i])
			n.append(up)
		for i: int in m:
			idx.append_array([cbase, cbase + 1 + i, cbase + 1 + (i + 1) % m])
	return _mk(v, n, idx)


## A broken column top: ring of radius r at y 0, a jagged rim (heights 0.3..1 x h) and a sunken centre.
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
		var notch: float = 0.45 if i % 4 == 1 else 1.0
		var hh: float = h * (0.55 + 0.45 * _h(Vector3(i, seed, 1.0))) * notch
		v.append(Vector3(cos(a) * r * 0.97, hh, sin(a) * r * 0.97))
		n.append(Vector3(cos(a), 0.2, sin(a)))
	for i: int in segs:
		var j: int = (i + 1) % segs
		idx.append_array([i, j, segs + i, j, segs + j, segs + i])
	var cbase: int = v.size()
	v.append(Vector3(0.1, h * 0.35, -0.05))
	n.append(Vector3.UP)
	for i: int in segs:
		v.append(v[segs + i])
		n.append(Vector3.UP)
	for i: int in segs:
		idx.append_array([cbase, cbase + 1 + i, cbase + 1 + (i + 1) % segs])
	return _mk(v, n, idx)


func _stone(arr: Array, xf: Transform3D, col: Color, mask: int, seed: float, moss: float = 0.7, jitter: float = 0.03) -> void:
	_part(arr, xf, col, {"kind": Kind.STONE, "mask": mask, "moss": moss, "jitter": jitter, "seed": seed, "tint": 0.08})


## Ivy climbing a shaft of radius r on one side, from y0 up `rows` clumps.
func _ivy(r: float, y0: float, rows: int, a0: float, mask: int, seed: float, centre: Vector3 = Vector3.ZERO) -> void:
	for i: int in 3:
		var a: float = a0 + i * 0.5
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, -a)
		for j: int in rows - i:
			var jy: float = y0 + j * 0.36 + i * 0.12
			var jr: float = 0.17 - j * 0.015
			_part(_sph(jr, 4, 2), Transform3D(b * Basis.from_scale(Vector3(0.45, 1.2, 1.0)), centre + d * (r - 0.02)
				+ Vector3(0, jy, 0) + Vector3(-d.z, 0, d.x) * (_h(Vector3(i, j, seed)) - 0.5) * 0.16),
				IVY_L if (i + j) % 2 == 0 else IVY, {"kind": Kind.IVY, "mask": mask, "normals": "smooth",
				"jitter": 0.03, "seed": seed + i * 5.0 + j})


func _build_pillar() -> void:
	_begin()
	# Shared plinth: two chunky steps and a base ring.
	_stone(_box(Vector3(1.7, 0.32, 1.7)), _xf(Vector3(0, 0.12, 0)), RUIN_D, 0, 40.0, 0.9, 0.05)
	_stone(_box(Vector3(1.32, 0.24, 1.32)), _xf(Vector3(0, 0.39, 0), Vector3(0, 0.05, 0)), RUIN.darkened(0.08), 0, 41.0,
		0.8, 0.04)
	_stone(_cyl(0.66, 0.74, 0.2, 10), _xf(Vector3(0, 0.6, 0)), RUIN, 0, 42.0, 0.6, 0.02)
	# V0: two drums, the upper one knocked off its seat, broken top, ivy.
	_stone(_fluted(0.56, 0.49, 1.2, 8), _xf(Vector3(0, 0.7, 0)), RUIN, V0, 43.0, 0.3, 0.02)
	_stone(_cyl(0.6, 0.6, 0.14, 10), _xf(Vector3(0, 1.95, 0)), RUIN_D.lightened(0.05), V0, 44.0, 0.5, 0.015)
	_stone(_fluted(0.53, 0.47, 0.62, 8), _xf(Vector3(0.05, 2.02, 0.03), Vector3(0.03, 0.14, 0.02)), RUIN_L, V0, 45.0, 0.3, 0.02)
	_stone(_broken_top(0.52, 0.34, 9, 3.0), _xf(Vector3(0.06, 2.6, 0.04), Vector3(0.05, 0.3, 0.03)), RUIN.darkened(0.1),
		V0, 46.0, 0.9, 0.04)
	_ivy(0.54, 0.75, 5, -0.55, V0, 47.0)
	_stone(_cyl(0.42, 0.45, 0.6, 8), _xf(Vector3(1.0, 0.24, 0.55), Vector3(0.3, 0.4, 1.5708)), RUIN_D, V0, 48.0, 0.7, 0.06)
	# V1: snapped low: one drum and a jagged break, the upper drum lying at the foot.
	_stone(_fluted(0.56, 0.49, 0.95, 8), _xf(Vector3(0, 0.7, 0)), RUIN, V1, 50.0, 0.3, 0.02)
	_stone(_broken_top(0.54, 0.5, 10, 7.0), _xf(Vector3(0.0, 1.62, 0.0), Vector3(0.04, 1.1, -0.03)), RUIN.darkened(0.08),
		V1, 51.0, 0.9, 0.04)
	var lie := Basis(Vector3.UP, 0.7) * Basis(Vector3.BACK, PI * 0.5)
	_stone(_fluted(0.5, 0.44, 1.0, 8), Transform3D(lie, Vector3(0.9, 0.46, 0.75) + lie * Vector3(0, -0.5, 0)), RUIN_L,
		V1, 52.0, 0.6, 0.02)
	_ivy(0.54, 0.72, 3, 2.2, V1, 53.0)
	# V2: leaning shaft that kept its capital.
	var tilt := Basis.from_euler(Vector3(0.1, 0.0, -0.08))
	_stone(_fluted(0.55, 0.48, 1.85, 8), Transform3D(tilt, Vector3(0, 0.68, 0)), RUIN, V2, 55.0, 0.3, 0.02)
	_stone(_cyl(0.66, 0.54, 0.22, 10), Transform3D(tilt, Vector3(0, 0.68, 0) + tilt * Vector3(0, 1.96, 0)),
		RUIN_D.lightened(0.06), V2, 56.0, 0.6, 0.02)
	_stone(_box(Vector3(1.12, 0.28, 1.12)), Transform3D(tilt * Basis(Vector3.UP, 0.15), Vector3(0, 0.68, 0)
		+ tilt * Vector3(0, 2.22, 0)), RUIN_L, V2, 57.0, 0.9, 0.05)
	_ivy(0.53, 0.8, 4, 3.6, V2, 58.0, Vector3(0.0, 0.0, 0.0))
	# Rubble at the foot (shared).
	for k: int in 4:
		var a2: float = k * 1.7 + 0.4
		_stone(_box(Vector3(0.3, 0.22, 0.26) * (1.0 + _h(Vector3(k, 5, 5)) * 0.6)),
			_xf(Vector3(cos(a2), 0, sin(a2)) * 1.08 + Vector3(0, 0.06, 0), Vector3(0.2, a2, 0.15)), RUIN_D.lightened(0.05),
			0, 60.0 + k, 0.6, 0.04)
	_disc(Vector3(0.1, 0, 0.1), 1.45, 1.4, 14, 40.0)
	_single("ruin_pillar", _commit("ruin_pillar"))
