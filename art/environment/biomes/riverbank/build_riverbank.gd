extends SceneTree
## Task 12.V7 (map-fill.md 3.1 biome 2 + section 10): generates the Riverbank biome meshes with the SHARED painted
## nature material (art/environment/nature_props/nature_mat.tres + nature_contact_mat.tres, loaded, never re-saved):
##   decor (MultiMesh scatter, read by riverbank_set.gd, 3 shape variants per mesh through the variant mask):
##     biomes/riverbank/rb_reeds.res         reed clumps with feathery plumes (stems reach y -0.5: rooted at the lip too)
##     biomes/riverbank/rb_cattails.res      cattails (brown heads) + arching leaves
##     biomes/riverbank/rb_lily_pads.res     lily pads, white / pink flowers, a bud (origin = the water surface)
##     biomes/riverbank/rb_river_stones.res  rounded river-worn stones and pebbles
##     biomes/riverbank/rb_driftwood.res     bleached driftwood (log, root stump, crossed sticks)
##   tree (EnvProps, collider r 0.45 s, height 2 like every tree):
##     meshes/tree_willow.res (+ tree_willow_v0/_v1/_v2.res, one variant each) and meshes/tree_willow_far.res
## Vertex data follows nature_painted.gdshader (COLOR.rgb colour, COLOR.a height gradient, UV.x wind weight or
## stone moss, UV.y local height (contact band), UV2 = (variant mask, kind)). Every mesh is indexed (welded).
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/riverbank/build_riverbank.gd --quit-after 600

const DIR := "res://art/environment/biomes/riverbank/"
const NDIR := "res://art/environment/nature_props/"
const MESH_DIR := "res://art/environment/meshes/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4

# Palette (sRGB). Reeds / willow a little yellower than the oaks so the bank reads as its own band; flowers and
# cattail heads are the small accents.
const REED_D := Color(0.20, 0.31, 0.12)
const REED := Color(0.36, 0.47, 0.18)
const REED_L := Color(0.60, 0.61, 0.29)
const PLUME := Color(0.42, 0.33, 0.25)
const PLUME_L := Color(0.66, 0.56, 0.40)
const CAT_STEM := Color(0.27, 0.39, 0.15)
const CAT_LEAF_D := Color(0.17, 0.31, 0.12)
const CAT_LEAF_L := Color(0.45, 0.55, 0.21)
const CAT_HEAD := Color(0.27, 0.19, 0.12)
const CAT_HEAD_L := Color(0.42, 0.31, 0.20)
const PAD_D := Color(0.13, 0.32, 0.13)
const PAD := Color(0.24, 0.46, 0.17)
const PAD_OLD := Color(0.42, 0.44, 0.16)
const PAD_RED := Color(0.40, 0.25, 0.16)
const PETAL_W := Color(0.93, 0.91, 0.87)
const PETAL_TIP := Color(0.96, 0.80, 0.84)
const PETAL_PINK := Color(0.92, 0.52, 0.66)
const POLLEN := Color(1.0, 0.78, 0.22)
const RS := Color(0.50, 0.48, 0.45)
const RS_BLUE := Color(0.42, 0.45, 0.48)
const RS_SAND := Color(0.60, 0.54, 0.44)
const RS_DARK := Color(0.31, 0.30, 0.29)
const DRIFT := Color(0.64, 0.60, 0.54)
const DRIFT_D := Color(0.45, 0.41, 0.36)
const DRIFT_CUT := Color(0.74, 0.67, 0.55)
const WBARK := Color(0.36, 0.30, 0.22)
const WBARK_D := Color(0.24, 0.20, 0.15)
const WIL_D := Color(0.13, 0.27, 0.13)
const WIL := Color(0.30, 0.47, 0.19)
const WIL_L := Color(0.58, 0.68, 0.30)
const WIL_TOP := Color(0.47, 0.62, 0.25)    # cascade strands: light where they run over the dome ...
const WIL_TIP := Color(0.27, 0.43, 0.17)    # ... darker where they hang (tops light, bottoms dark)
const REED_DRY := Color(0.68, 0.57, 0.35)

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var _conv: float = 1.0

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _w := PackedFloat32Array()     # stone: moss; else explicit wind weight (>= 0) or -1 = automatic (tree curve)
var _uv2 := PackedVector2Array()   # (variant mask, kind)
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
var _report: Array = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	mat = load(NDIR + "nature_mat.tres") as ShaderMaterial
	contact_mat = load(NDIR + "nature_contact_mat.tres") as ShaderMaterial
	if mat == null or contact_mat == null:
		push_error("nature materials missing")
		quit(1)
		return
	_build_reeds()
	_build_cattails()
	_build_lily_pads()
	_build_river_stones()
	_build_driftwood()
	_build_willow()
	_build_willow_far()
	for line: String in _report:
		print(line)
	print("RIVERBANK BUILD OK")
	quit()


# --- helpers (same conventions as nature_props/build_nature.gd) ---------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


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


## Adds mesh arrays, transformed. Options (all optional):
##   kind, mask (variant bits, 0 = always), jitter (m), seed, jit_axes,
##   normals "flat" | "smooth" | "crown" (+ crown, crown_k, crown_s), col2 + grad ("y" | "r"), ao_c + ao_r,
##   moss (stone), no_caps, tint, wind (Vector2(weight at the part's bottom, at its top)), clip_y (drop triangles
##   whose 3 corners are all below this y: the buried half of a half-sunk stone).
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
	var has_wind: bool = o.has("wind")
	var wind: Vector2 = o.get("wind", Vector2.ZERO)
	var clip_y: float = o.get("clip_y", -INF)
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
		if tv[a].y < clip_y and tv[b].y < clip_y and tv[c].y < clip_y:
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
			var gy: float = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
			var gt: float = gy
			if grad == "r":
				gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
			var cc: Color = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			if ao_r > 0.0:
				var d: Vector3 = (tv[vi] - ao_c) * Vector3(1.0, 1.3, 1.0)
				k *= lerpf(0.60, 1.04, smoothstep(0.30, 1.0, d.length() / ao_r))
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k))
			if kind == Kind.STONE:
				_w.append(moss)
			elif has_wind:
				_w.append(lerpf(wind.x, wind.y, gy))
			else:
				_w.append(-1.0)
			_uv2.append(Vector2(mask, kind))


## A tapered tube along `path` (Vector3 points) with one radius per point (0 = pointed tip). `sides` around.
## `flat` < 1 squashes the cross-section along `face` (a direction; the broad side of the ribbon turns toward it):
## reed blades, cattail leaves, willow strands. Smooth normals (ellipse normals). cap_start / cap_end close the ends.
func _tube(path: Array, radii: Array, sides: int, flat: float = 1.0, face: Vector3 = Vector3.ZERO,
		cap_start: bool = false, cap_end: bool = false) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var cnt: int = path.size()
	var tangents: Array[Vector3] = []
	for i: int in cnt:
		var t: Vector3
		if i == 0:
			t = (path[1] as Vector3) - (path[0] as Vector3)
		elif i == cnt - 1:
			t = (path[i] as Vector3) - (path[i - 1] as Vector3)
		else:
			t = (path[i + 1] as Vector3) - (path[i - 1] as Vector3)
		tangents.append(t.normalized())
	for i: int in cnt:
		var t: Vector3 = tangents[i]
		var ref: Vector3 = face
		if ref == Vector3.ZERO or absf(ref.normalized().dot(t)) > 0.97:
			ref = Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.BACK
		var thin: Vector3 = (ref - t * ref.dot(t)).normalized()
		var broad: Vector3 = t.cross(thin).normalized()
		var r: float = radii[i]
		for k: int in sides:
			var a: float = TAU * k / sides
			v.append((path[i] as Vector3) + broad * cos(a) * r + thin * sin(a) * r * flat)
			n.append((broad * cos(a) * flat + thin * sin(a)).normalized())
	for i: int in cnt - 1:
		for k: int in sides:
			var a0: int = i * sides + k
			var b0: int = i * sides + (k + 1) % sides
			var c0: int = (i + 1) * sides + k
			var d0: int = (i + 1) * sides + (k + 1) % sides
			idx.append_array([a0, b0, c0, b0, d0, c0])
	for cap: int in 2:
		if (cap == 0 and not cap_start) or (cap == 1 and not cap_end):
			continue
		var ring: int = 0 if cap == 0 else cnt - 1
		var nrm: Vector3 = -tangents[0] if cap == 0 else tangents[cnt - 1]
		var cb: int = v.size()
		v.append(path[ring])
		n.append(nrm)
		for k: int in sides:
			v.append(v[ring * sides + k])
			n.append(nrm)
		for k: int in sides:
			idx.append_array([cb, cb + 1 + k, cb + 1 + (k + 1) % sides])
	return _mk(v, n, idx)


## Leaf blobs: [centre, radius, squash (Vector3), colour t 0 (dark) - 1 (light)] around a crown centre.
func _blobs(list: Array, crown: Vector3, crown_r: float, dark: Color, mid: Color, light: Color, mask: int,
		seed: float, kind: int = Kind.LEAVES, segs: int = 7, rings: int = 4) -> void:
	var i: int = 0
	for b: Array in list:
		var ct: float = b[3]
		var c0: Color = dark.lerp(mid, minf(ct * 2.0, 1.0)) if ct < 0.5 else mid.lerp(light, (ct - 0.5) * 2.0)
		_part(_sph(b[1], segs, rings), _xf(b[0], Vector3(0.0, i * 1.1, 0.0), b[2]), c0.darkened(0.12),
			{"kind": kind, "mask": mask, "normals": "crown", "crown": crown, "crown_k": 0.62,
			"crown_s": Vector3(1.0, 0.7, 1.0), "col2": c0.lightened(0.10), "grad": "y", "jitter": b[1] * 0.16,
			"seed": seed + i, "ao_c": crown, "ao_r": crown_r, "tint": 0.10})
		i += 1


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


## Bakes COLOR.a (height gradient), UV.x (wind weight / moss), UV.y (local height) and saves the mesh.
## o: wind_h (> 0: automatic wind weight pow((y - wind_base) / (wind_h - wind_base), wind_pow) * wind_gain for
## parts without an explicit "wind"), grad_min (COLOR.a floor: flat things like lily pads are not "the bottom of
## the prop"), uv_y_add (lifts UV.y: no dark contact band), split (also save <path>_v0/_v1/_v2.res).
func _commit(path: String, o: Dictionary = {}) -> ArrayMesh:
	var wind_h: float = o.get("wind_h", 0.0)
	var wind_base: float = o.get("wind_base", 0.35)
	var wind_pow: float = o.get("wind_pow", 1.6)
	var wind_gain: float = o.get("wind_gain", 1.0)
	var grad_min: float = o.get("grad_min", 0.0)
	var uv_y_add: float = o.get("uv_y_add", 0.0)
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
		cc.a = lerpf(grad_min, 1.0, clampf((_v[i].y - miny) / span, 0.0, 1.0))
		_c[i] = cc
		var w: float = _w[i]
		if int(_uv2[i].y) != Kind.STONE and w < 0.0:
			w = 0.0
			if wind_h > 0.0:
				w = pow(clampf((_v[i].y - wind_base) / (wind_h - wind_base), 0.0, 1.0), wind_pow) * wind_gain
		uv[i] = Vector2(w, _v[i].y + uv_y_add)
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
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(_contact_arrays()))
		mesh.surface_set_material(1, contact_mat)
	_save(mesh, path)
	var per := [0, 0, 0]
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		for k: int in 3:
			if m <= 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-22s %4d tris, %4d verts (variants %d / %d / %d), contact %d, size %.2f x %.2f x %.2f, y %.2f..%.2f"
		% [path.get_file().get_basename(), _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(),
		per[0], per[1], per[2], _cv.size() / 3, aabb.size.x, aabb.size.y, aabb.size.z, miny, maxy])
	if o.get("split", false):
		for k2: int in 3:
			_save(_variant_mesh(arrays, _contact_arrays(), k2), path.trim_suffix(".res") + "_v%d.res" % k2)
	return mesh


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
			if m <= 0 or ((m >> k) & 1) == 1:
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
						if a == Mesh.ARRAY_TEX_UV2 and uvv.x > 0.5:
							uvv.x = 0.0
						p2.append(uvv)
					dst = p2
			out[a] = dst
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(out))
		mesh.surface_set_material(mesh.get_surface_count() - 1, sf[1])
	return mesh


# --- reeds ------------------------------------------------------------------------------------------

## One reed blade: a 3-sided ribbon from `base` rising `h`, bowing `bend` metres toward `out` (tip droops a bit).
func _reed(base: Vector3, out: Vector3, h: float, width: float, bend: float, mask: int, seed: float,
		col: Color = REED_D, col2: Color = REED_L) -> Vector3:
	var o: Vector3 = Vector3(out.x, 0.0, out.z).normalized()
	var p0: Vector3 = base + Vector3(0, -0.5, 0)
	var p1: Vector3 = base + Vector3(0, h * 0.55, 0) + o * bend * 0.3
	var p2: Vector3 = base + Vector3(0, h, 0) + o * bend
	_part(_tube([p0, p1, p2], [width, width * 0.8, 0.0], 3, 0.35, o), Transform3D.IDENTITY, col,
		{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": col2, "grad": "y", "seed": seed,
		"jitter": 0.004, "tint": 0.12})
	return p2


## A feathery reed plume hanging off a stem tip (a drooping spindle).
func _plume(tip: Vector3, out: Vector3, len: float, mask: int, seed: float) -> void:
	var o: Vector3 = Vector3(out.x, 0.0, out.z).normalized()
	var a: Vector3 = tip + Vector3(0, -0.05, 0)
	var b: Vector3 = tip + o * len * 0.3 + Vector3(0, len * 0.1, 0)
	var c: Vector3 = tip + o * len * 0.7 + Vector3(0, -len * 0.08, 0)
	var d: Vector3 = tip + o * len + Vector3(0, -len * 0.4, 0)
	_part(_tube([a, b, c, d], [0.035, 0.075, 0.06, 0.0], 3, 1.0), Transform3D.IDENTITY, PLUME,
		{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": PLUME_L, "grad": "y", "seed": seed,
		"tint": 0.1})


## A reed clump: `count` blades around the centre; `plumes` of them carry a plume.
func _reed_clump(count: int, plumes: int, hmin: float, hmax: float, spread: float, lean: float, mask: int,
		seed: float, offset: Vector3 = Vector3.ZERO) -> void:
	for i: int in count:
		var a: float = i * 2.39996 + seed
		var r: float = spread * sqrt((i + 0.5) / count)
		var base: Vector3 = offset + Vector3(cos(a) * r, 0.0, sin(a) * r)
		var out := Vector3(cos(a), 0.0, sin(a))
		var h: float = lerpf(hmin, hmax, _h(Vector3(i, seed, 1.0)))
		var w: float = 0.042 + 0.018 * _h(Vector3(i, seed, 2.0))
		var bend: float = lean * (0.5 + 0.8 * _h(Vector3(i, seed, 3.0))) + r * 0.4
		var dry: bool = i % 4 == 3
		var tip: Vector3 = _reed(base, out, h, w, bend, mask, seed + i, REED_D.lerp(REED, 0.3) if dry else REED_D,
			REED_DRY if dry else REED_L)
		if i < plumes:
			_plume(tip, out, 0.26 + 0.08 * _h(Vector3(i, seed, 4.0)), mask, seed + i * 3.0)


func _build_reeds() -> void:
	_begin()
	# V0: a tall clump (1.2 - 1.65 m), 4 plumes.
	_reed_clump(10, 4, 1.15, 1.65, 0.24, 0.20, V0, 1.0)
	_disc(Vector3.ZERO, 0.55, 0.5, 9, 1.0, V0)
	# V1: a low, dense clump (0.75 - 1.15 m), 2 plumes.
	_reed_clump(10, 2, 0.75, 1.15, 0.2, 0.14, V1, 7.0)
	_disc(Vector3.ZERO, 0.48, 0.45, 9, 2.0, V1)
	# V2: a wide fan, blades thrown outward (wind-bent), 3 plumes, a small second tuft.
	_reed_clump(8, 3, 1.0, 1.5, 0.3, 0.42, V2, 13.0)
	_reed_clump(4, 0, 0.55, 0.8, 0.12, 0.2, V2, 19.0, Vector3(0.45, 0, 0.3))
	_disc(Vector3(0.1, 0, 0.1), 0.65, 0.55, 9, 3.0, V2)
	_commit(DIR + "rb_reeds.res", {"wind_h": 1.5, "wind_base": -0.05, "wind_pow": 1.3, "wind_gain": 1.25})


# --- cattails ----------------------------------------------------------------------------------------

## A cattail: a straight stem, a brown sausage head at 70-85 % of its height, a thin spike above.
func _cattail(base: Vector3, h: float, lean: Vector3, mask: int, seed: float) -> void:
	var top: Vector3 = base + Vector3(0, h, 0) + lean
	var hb: float = 0.62 + 0.08 * _h(Vector3(seed, 1, 1))
	var head_a: Vector3 = base.lerp(top, hb)
	var head_b: Vector3 = base.lerp(top, hb + 0.26)
	_part(_tube([base + Vector3(0, -0.5, 0), head_a, top], [0.022, 0.017, 0.0], 3), Transform3D.IDENTITY, CAT_STEM,
		{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": CAT_STEM.lightened(0.15), "seed": seed})
	_part(_tube([head_a - (head_b - head_a) * 0.08, head_a.lerp(head_b, 0.25), head_a.lerp(head_b, 0.8), head_b],
		[0.034, 0.058, 0.056, 0.0], 4), Transform3D.IDENTITY, CAT_HEAD,
		{"kind": Kind.BARK, "mask": mask, "normals": "smooth", "col2": CAT_HEAD_L, "grad": "y", "seed": seed,
		"tint": 0.1})


## A long flat cattail leaf arching out and over.
func _cat_leaf(base: Vector3, a: float, h: float, mask: int, seed: float) -> void:
	var o := Vector3(cos(a), 0, sin(a))
	var p0: Vector3 = base + Vector3(0, -0.4, 0)
	var p1: Vector3 = base + Vector3(0, h * 0.85, 0) + o * 0.2
	var p2: Vector3 = base + Vector3(0, h * 0.8, 0) + o * 0.62
	_part(_tube([p0, p1, p2], [0.05, 0.042, 0.0], 3, 0.22, o), Transform3D.IDENTITY, CAT_LEAF_D,
		{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": CAT_LEAF_L, "grad": "y", "seed": seed,
		"tint": 0.12})


func _build_cattails() -> void:
	_begin()
	# V0: 4 cattails of mixed heights + 5 leaves.
	var s0: Array = [[Vector3(0.0, 0, 0.0), 1.35], [Vector3(0.14, 0, 0.1), 1.15], [Vector3(-0.12, 0, 0.12), 1.05],
		[Vector3(0.05, 0, -0.15), 1.25]]
	for i: int in s0.size():
		_cattail(s0[i][0], s0[i][1], Vector3(0.05 * cos(i * 2.1), 0, 0.05 * sin(i * 2.1)), V0, 20.0 + i)
	for i: int in 5:
		_cat_leaf(Vector3(cos(i * 1.3) * 0.06, 0, sin(i * 1.3) * 0.06), i * 1.26 + 0.3, 0.9 + 0.2 * _h(Vector3(i, 5, 5)),
			V0, 30.0 + i)
	_disc(Vector3.ZERO, 0.5, 0.45, 9, 20.0, V0)
	# V1: a small group: 3 cattails, 4 leaves, one head bent over.
	var s1: Array = [[Vector3(0.0, 0, 0.0), 1.2], [Vector3(0.12, 0, -0.1), 1.0], [Vector3(-0.1, 0, -0.06), 0.95]]
	for i: int in s1.size():
		var lean := Vector3(0.18, 0, 0.1) if i == 2 else Vector3(0.04 * cos(i * 2.7), 0, 0.04 * sin(i * 2.7))
		_cattail(s1[i][0], s1[i][1], lean, V1, 40.0 + i)
	for i: int in 4:
		_cat_leaf(Vector3(cos(i * 1.7) * 0.05, 0, sin(i * 1.7) * 0.05), i * 1.57 + 1.0, 0.85 + 0.2 * _h(Vector3(i, 6, 6)),
			V1, 45.0 + i)
	_disc(Vector3.ZERO, 0.45, 0.42, 9, 21.0, V1)
	# V2: a wide stand: 5 cattails in a loose line + 4 leaves.
	for i: int in 5:
		var x: float = -0.3 + i * 0.15
		_cattail(Vector3(x, 0, 0.06 * sin(i * 2.3)), 1.0 + 0.35 * _h(Vector3(i, 7, 7)),
			Vector3(0.03 * sin(i * 1.9), 0, 0.03 * cos(i * 1.9)), V2, 50.0 + i)
	for i: int in 4:
		_cat_leaf(Vector3(-0.2 + i * 0.14, 0, 0.0), i * 1.9 + 0.5, 0.8 + 0.25 * _h(Vector3(i, 8, 8)), V2, 60.0 + i)
	_disc(Vector3.ZERO, 0.62, 0.42, 9, 22.0, V2)
	_commit(DIR + "rb_cattails.res", {"wind_h": 1.4, "wind_base": -0.05, "wind_pow": 1.4, "wind_gain": 1.1})


# --- lily pads (origin = the water surface; place at y = RiverSystem.WATER_Y) ------------------------

## A pad: a slightly cupped disc of radius r with its V notch at angle `rot`.
func _pad(c: Vector3, r: float, rot: float, col: Color, mask: int, seed: float) -> void:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var segs: int = 9
	var notch: float = 0.55
	v.append(Vector3(0, 0.026, 0))
	n.append(Vector3.UP)
	for i: int in segs + 1:
		var a: float = notch * 0.5 + (TAU - notch) * i / segs
		var rr: float = r * (0.95 + 0.08 * _h(Vector3(seed, i, 1.0)))
		var y: float = 0.03 + 0.012 * _h(Vector3(seed, i, 2.0))
		v.append(Vector3(cos(a) * rr, y, sin(a) * rr))
		n.append(Vector3(cos(a) * 0.12, 1.0, sin(a) * 0.12).normalized())
	for i: int in segs:
		idx.append_array([0, 1 + i, 2 + i])
	_part(_mk(v, n, idx), _xf(c, Vector3(0, rot, 0)), col.darkened(0.08), {"kind": Kind.IVY, "mask": mask,
		"normals": "smooth", "col2": col.lightened(0.12), "grad": "r", "seed": seed, "tint": 0.1,
		"wind": Vector2(0.22, 0.22)})


## A water-lily flower: 8 outer + 5 inner petals (kites lifted at the tips) and a yellow centre. r = petal length.
func _flower(c: Vector3, r: float, petal: Color, tip: Color, mask: int, seed: float) -> void:
	for layer: int in 2:
		var count: int = 8 if layer == 0 else 5
		var rl: float = r if layer == 0 else r * 0.68
		var lift: float = r * (0.45 if layer == 0 else 0.95)
		var half: float = 0.3 if layer == 0 else 0.42
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var idx := PackedInt32Array()
		for j: int in count:
			var a: float = (j + 0.5 * layer) * TAU / count + seed
			var d := Vector3(cos(a), 0, sin(a))
			var dl := Vector3(cos(a - half), 0, sin(a - half))
			var dr := Vector3(cos(a + half), 0, sin(a + half))
			var up: float = 0.05 + 0.02 * layer
			var b: int = v.size()
			v.append_array([Vector3(0, up, 0), dl * rl * 0.5 + Vector3(0, up + lift * 0.45, 0),
				d * rl + Vector3(0, up + lift, 0), dr * rl * 0.5 + Vector3(0, up + lift * 0.45, 0)])
			var nn: Vector3 = (Vector3.UP * 1.0 - d * (0.55 + 0.4 * layer)).normalized()
			n.append_array([Vector3.UP, nn, nn, nn])
			idx.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
		_part(_mk(v, n, idx), _xf(c), petal, {"kind": Kind.IVY, "mask": mask, "normals": "smooth",
			"col2": tip, "grad": "r", "seed": seed + layer, "tint": 0.05, "wind": Vector2(0.22, 0.3)})
	_part(_sph(r * 0.2, 5, 2), _xf(c + Vector3(0, 0.08, 0), Vector3.ZERO, Vector3(1.0, 0.6, 1.0)), POLLEN,
		{"kind": Kind.IVY, "mask": mask, "normals": "smooth", "seed": seed, "wind": Vector2(0.3, 0.3)})


## A closed bud on a short stalk poking out of the water.
func _bud(c: Vector3, h: float, col: Color, mask: int, seed: float) -> void:
	_part(_tube([c + Vector3(0, -0.05, 0), c + Vector3(0.01, h * 0.55, 0), c + Vector3(0.02, h, 0.01)],
		[0.045, 0.065, 0.0], 4), Transform3D.IDENTITY, PAD_D, {"kind": Kind.IVY, "mask": mask, "normals": "smooth",
		"col2": col, "grad": "y", "seed": seed, "wind": Vector2(0.2, 0.45)})


func _build_lily_pads() -> void:
	_begin()
	# V0: 4 pads and a white flower.
	var p0: Array = [[Vector3(0, 0, 0), 0.4, PAD], [Vector3(0.62, 0.002, 0.2), 0.3, PAD.lerp(PAD_OLD, 0.4)],
		[Vector3(-0.35, 0.004, 0.55), 0.26, PAD], [Vector3(-0.5, 0.001, -0.3), 0.34, PAD_D.lerp(PAD, 0.6)]]
	for i: int in p0.size():
		_pad(p0[i][0], p0[i][1], i * 1.9 + 0.4, p0[i][2], V0, 70.0 + i)
	_flower(Vector3(0.12, 0.0, 0.08), 0.2, PETAL_W, PETAL_TIP, V0, 0.3)
	# V1: a wide raft of 6 pads, a pink flower and a bud.
	var p1: Array = [[Vector3(0, 0, 0), 0.42, PAD], [Vector3(0.7, 0.003, -0.1), 0.36, PAD.lerp(PAD_OLD, 0.5)],
		[Vector3(0.3, 0.001, 0.62), 0.3, PAD_D.lerp(PAD, 0.5)], [Vector3(-0.62, 0.002, 0.28), 0.34, PAD],
		[Vector3(-0.3, 0.004, -0.6), 0.28, PAD_RED.lerp(PAD_OLD, 0.4)], [Vector3(1.2, 0.002, 0.45), 0.24, PAD]]
	for i: int in p1.size():
		_pad(p1[i][0], p1[i][1], i * 2.3 + 1.1, p1[i][2], V1, 80.0 + i)
	_flower(Vector3(0.66, 0.0, -0.08), 0.2, PETAL_W.lerp(PETAL_PINK, 0.55), PETAL_PINK, V1, 1.2)
	_bud(Vector3(-0.28, 0.0, 0.05), 0.2, PETAL_PINK.darkened(0.1), V1, 88.0)
	# V2: 3 small pads and a lone bud (sparse water).
	var p2: Array = [[Vector3(0, 0, 0), 0.3, PAD.lerp(PAD_OLD, 0.25)], [Vector3(0.48, 0.002, -0.22), 0.24, PAD],
		[Vector3(-0.1, 0.003, 0.5), 0.22, PAD_RED.lerp(PAD, 0.5)]]
	for i: int in p2.size():
		_pad(p2[i][0], p2[i][1], i * 2.7 + 2.0, p2[i][2], V2, 90.0 + i)
	_bud(Vector3(0.25, 0.0, 0.22), 0.18, PETAL_W.darkened(0.05), V2, 95.0)
	_flower(Vector3(0.48, 0.0, -0.22), 0.16, PETAL_W, PETAL_TIP, V2, 2.1)
	_commit(DIR + "rb_lily_pads.res", {"grad_min": 0.75, "uv_y_add": 0.5})


# --- river stones -------------------------------------------------------------------------------------

## A river-worn stone: a smooth squashed sphere, half sunk (the buried triangles are dropped).
func _stone(c: Vector3, radii: Vector3, yaw: float, col: Color, mask: int, seed: float, moss: float = 0.2,
		segs: int = 7, rings: int = 4) -> void:
	_part(_sph(1.0, segs, rings), _xf(c, Vector3(0.08 * sin(seed), yaw, 0.06 * cos(seed)), radii), col,
		{"kind": Kind.STONE, "mask": mask, "normals": "smooth", "moss": moss, "jitter": radii.y * 0.12,
		"jit_axes": Vector3(1.0, 0.6, 1.0), "seed": seed, "tint": 0.06, "col2": col.lightened(0.08),
		"clip_y": -0.02})


func _build_river_stones() -> void:
	_begin()
	# V0: a lip of 6 pebbles around a medium stone.
	_stone(Vector3(0, 0.02, 0), Vector3(0.32, 0.2, 0.26), 0.3, RS, V0, 1.0, 0.25)
	var cols: Array[Color] = [RS_BLUE, RS_SAND, RS_DARK, RS, RS_SAND, RS_BLUE]
	for i: int in 6:
		var a: float = i * 1.05 + 0.4
		var d: float = 0.42 + 0.16 * _h(Vector3(i, 3, 1))
		var rr: float = 0.08 + 0.07 * _h(Vector3(i, 3, 2))
		_stone(Vector3(cos(a) * d, rr * 0.2, sin(a) * d * 0.8), Vector3(rr * 1.2, rr * 0.7, rr), a, cols[i], V0,
			10.0 + i, 0.0, 5, 2)
	_disc(Vector3.ZERO, 0.75, 0.62, 10, 1.0, V0)
	# V1: two big flat worn stones side by side + 3 pebbles.
	_stone(Vector3(-0.22, 0.0, 0.0), Vector3(0.46, 0.17, 0.36), 0.5, RS_BLUE, V1, 2.0, 0.3, 8, 4)
	_stone(Vector3(0.38, 0.0, 0.18), Vector3(0.34, 0.14, 0.3), 1.7, RS, V1, 3.0, 0.2, 7, 4)
	for i: int in 3:
		var a2: float = i * 2.1 + 1.0
		var rr2: float = 0.07 + 0.05 * _h(Vector3(i, 4, 2))
		_stone(Vector3(cos(a2) * 0.62, rr2 * 0.2, sin(a2) * 0.5), Vector3(rr2 * 1.2, rr2 * 0.7, rr2), a2,
			[RS_SAND, RS_DARK, RS][i], V1, 20.0 + i, 0.0, 5, 2)
	_disc(Vector3(0.05, 0, 0.05), 0.85, 0.6, 10, 2.0, V1)
	# V2: one rounded mid boulder (0.5 m tall) with 4 pebbles at its foot.
	_stone(Vector3(0, 0.12, 0), Vector3(0.48, 0.4, 0.4), 0.9, RS, V2, 4.0, 0.45, 8, 4)
	for i: int in 4:
		var a3: float = i * 1.6 + 0.2
		var rr3: float = 0.07 + 0.06 * _h(Vector3(i, 5, 2))
		_stone(Vector3(cos(a3) * 0.58, rr3 * 0.2, sin(a3) * 0.5), Vector3(rr3 * 1.2, rr3 * 0.7, rr3), a3,
			[RS_BLUE, RS_SAND, RS_DARK, RS_SAND][i], V2, 30.0 + i, 0.0, 5, 2)
	_disc(Vector3.ZERO, 0.8, 0.7, 10, 4.0, V2)
	_commit(DIR + "rb_river_stones.res")


# --- driftwood ----------------------------------------------------------------------------------------

func _wood(path: Array, radii: Array, sides: int, mask: int, seed: float, col: Color = DRIFT,
		caps: bool = true) -> void:
	_part(_tube(path, radii, sides, 1.0, Vector3.ZERO, caps and float(radii[0]) > 0.0,
		caps and float(radii[radii.size() - 1]) > 0.0), Transform3D.IDENTITY, col,
		{"kind": Kind.BARK, "mask": mask, "normals": "smooth", "col2": col.lightened(0.08), "grad": "y",
		"jitter": 0.012, "seed": seed, "tint": 0.1})


func _build_driftwood() -> void:
	_begin()
	# V0: a long bleached branch (2.3 m) lying on its side, a root flare at one end, two snapped twigs.
	_wood([Vector3(-1.15, 0.2, 0.05), Vector3(-0.4, 0.15, -0.05), Vector3(0.4, 0.12, 0.08), Vector3(1.15, 0.09, 0.0)],
		[0.2, 0.16, 0.13, 0.09], 6, V0, 1.0)
	for i: int in 3:
		var a: float = i * 2.0 + 0.5
		_wood([Vector3(-1.1, 0.2, 0.05), Vector3(-1.35, 0.2 + 0.18 * sin(a), 0.05 + 0.3 * cos(a))], [0.08, 0.0], 4, V0,
			5.0 + i, DRIFT_D, false)
	_wood([Vector3(0.1, 0.2, 0.05), Vector3(0.35, 0.42, 0.28)], [0.045, 0.0], 4, V0, 9.0, DRIFT_D, false)
	_wood([Vector3(0.6, 0.15, 0.0), Vector3(0.85, 0.12, -0.35)], [0.04, 0.0], 4, V0, 10.0, DRIFT_D, false)
	_disc(Vector3.ZERO, 1.35, 0.5, 12, 1.0, V0)
	# V1: a stranded root stump: a short thick trunk piece with 5 root fingers spreading out.
	_wood([Vector3(0.1, 0.24, 0.0), Vector3(0.55, 0.2, 0.05), Vector3(0.95, 0.16, 0.0)], [0.26, 0.22, 0.18], 7, V1, 20.0)
	for i: int in 5:
		var a2: float = -1.4 + i * 0.7
		var d := Vector3(-cos(a2), 0, sin(a2))
		_wood([Vector3(0.1, 0.24, 0.0), Vector3(0.1, 0.24, 0.0) + d * 0.45 + Vector3(0, 0.05 + 0.1 * (i % 2), 0),
			Vector3(0.1, 0.24, 0.0) + d * 0.8 + Vector3(0, -0.02 + 0.2 * (i % 2), 0)], [0.09, 0.06, 0.0], 4, V1,
			21.0 + i, DRIFT_D.lerp(DRIFT, 0.4), false)
	_disc(Vector3(0.2, 0, 0), 1.0, 0.75, 12, 2.0, V1)
	# V2: two crossed sticks and a flat broken plank-like slab.
	_wood([Vector3(-0.8, 0.07, -0.3), Vector3(0.0, 0.1, -0.05), Vector3(0.8, 0.07, 0.25)], [0.08, 0.075, 0.05], 5, V2,
		30.0)
	_wood([Vector3(-0.5, 0.17, 0.45), Vector3(0.1, 0.19, -0.02), Vector3(0.6, 0.08, -0.5)], [0.07, 0.065, 0.045], 5,
		V2, 31.0, DRIFT_D.lerp(DRIFT, 0.5))
	_part(_tube([Vector3(-0.15, 0.06, 0.5), Vector3(0.45, 0.07, 0.55)], [0.13, 0.11], 4, 0.3, Vector3.UP, true,
		true), Transform3D.IDENTITY, DRIFT_CUT, {"kind": Kind.BARK, "mask": V2, "normals": "flat", "seed": 32.0,
		"jitter": 0.01, "tint": 0.1})
	_disc(Vector3(0, 0, 0.1), 1.0, 0.75, 12, 3.0, V2)
	_commit(DIR + "rb_driftwood.res", {"grad_min": 0.35})


# --- willow tree (s = 1: collider radius 0.45, height 2 at y 1, like every tree) ----------------------

## The crown body: a flattened dark core (the fill seen between the strands) and a light top lobe. r = crown radius
## (m). Foliage kind IVY: the willow never takes the random autumn tint (it stays the river's green landmark).
func _willow_crown(c: Vector3, r: float, mask: int, seed: float, dark: Color = WIL_D, mid: Color = WIL,
		light: Color = WIL_L, stretch: Vector3 = Vector3.ONE) -> void:
	_blobs([[c + Vector3(0, -0.22, 0), r * 0.8, Vector3(1.2, 0.5, 1.2) * stretch, 0.1],
		[c + Vector3(-0.05, r * 0.3, 0.05), r * 0.36, Vector3(1.2, 0.6, 1.2), 0.95]],
		c, r * 1.05, dark, mid, light, mask, seed, Kind.IVY, 7, 4)


## The weeping cascade: `count` leafy ribbons (double-sided flat strips, 16 triangles each) that start at the crown
## top, run over the dome, bend at its rim and fall `lmin`..`lmax` metres to rounded tips: the mop / curtain
## silhouette that makes a willow read at 40 m. `side` > 0 lengthens the strands toward local +X (a willow over the
## water trails its curtain deeper there). Wind weight 0.5 at the top -> 1.5 at the tips.
func _cascade(c: Vector3, r: float, count: int, lmin: float, lmax: float, width: float, mask: int, seed: float,
		side: float = 0.0, stretch: Vector3 = Vector3.ONE, top_col: Color = WIL_TOP, tip_col: Color = WIL_TIP) -> void:
	var dome_h: float = r * 0.8 * 0.5
	for i: int in count:
		var a: float = (i + 0.45 * (_h(Vector3(seed, i, 1.0)) - 0.5)) * TAU / count
		var on := Vector3(cos(a), 0, sin(a))
		var o: Vector3 = on * stretch
		var len: float = lerpf(lmin, lmax, _h(Vector3(seed, i, 2.0))) * (1.0 + side * on.x)
		var rr: float = r * (0.95 + 0.1 * _h(Vector3(seed, i, 3.0)))
		var hw: float = width * (0.85 + 0.3 * _h(Vector3(seed, i, 4.0)))
		var twist: float = (_h(Vector3(seed, i, 8.0)) - 0.5) * 0.4
		var sd: Vector3 = (Vector3(-on.z, 0, on.x) + on * twist).normalized()
		var rim: Vector3 = c + o * rr + Vector3(0, dome_h * 0.2, 0)
		var path: Array = [c + o * 0.25 + Vector3(0, dome_h * 1.05 + 0.1, 0),
			c + o * rr * 0.55 + Vector3(0, dome_h * 0.9 + 0.08, 0), rim,
			rim + on * 0.12 + Vector3(0, -len * 0.5, 0), rim + on * 0.2 + Vector3(0, -len, 0)]
		var widths: Array = [hw * 0.5, hw * 0.85, hw, hw * 0.8, hw * 0.3]
		var lift := Vector3(0, 0.025 * (i % 3), 0)   # overlapping strands never share a plane (no z-fighting)
		for j: int in 3:
			path[j] = (path[j] as Vector3) + lift
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var idx := PackedInt32Array()
		# Front face over the whole strand; back face only where it hangs free (the dome hides the rest).
		for face: int in 2:
			var fo: float = 1.0 if face == 0 else -1.0
			var j0: int = 0 if face == 0 else 2
			var b: int = v.size()
			for j: int in range(j0, 5):
				var p: Vector3 = path[j]
				var up: float = 1.4 if j == 0 else (1.0 if j == 1 else (0.55 if j == 2 else 0.3))
				var nb: Vector3 = on * fo + Vector3(0, up if face == 0 else 0.3, 0)
				v.append(p - sd * widths[j])
				v.append(p + sd * widths[j])
				n.append((nb - sd * 0.4).normalized())
				n.append((nb + sd * 0.4).normalized())
			for j: int in 4 - j0:
				var l0: int = b + j * 2
				idx.append_array([l0, l0 + 1, l0 + 2, l0 + 1, l0 + 3, l0 + 2])
		# Per-strand value / hue step: the curtain reads as separate painted strokes, not one sheet.
		var k: float = 0.8 + 0.32 * _h(Vector3(seed, i, 9.0))
		var warm: float = _h(Vector3(seed, i, 10.0)) * 0.3
		var tc: Color = tip_col.lerp(WIL_L, warm * 0.5)
		var hc: Color = top_col.lerp(WIL_L, warm)
		_part(_mk(v, n, idx), Transform3D.IDENTITY, Color(tc.r * k, tc.g * k, tc.b * k), {"kind": Kind.IVY,
			"mask": mask, "normals": "smooth", "col2": Color(hc.r * k, hc.g * k, hc.b * k), "grad": "y",
			"seed": seed + i, "jitter": 0.02, "tint": 0.12, "wind": Vector2(1.5, 0.5)})


## The weeping curtain: `count` leafy ribbons (double-sided flat strips, 12 triangles each) hanging from the crown
## rim: each starts inside a rim lobe, arches out past it, then falls `lmin`..`lmax` metres, narrowing to a rounded
## tip. `side` > 0 lengthens the strands toward local +X (a willow over the water trails its curtain deeper there).
## Wind weight 0.5 at the anchor -> 1.5 at the tip, so the curtain swings more than the crown.
func _curtain(c: Vector3, anchor_r: float, anchor_y: float, count: int, lmin: float, lmax: float, width: float,
		mask: int, seed: float, side: float = 0.0, a0: float = 0.0, top_col: Color = WIL, tip_col: Color = WIL_L,
		stretch: Vector3 = Vector3.ONE) -> void:
	for i: int in count:
		var a: float = a0 + (i + 0.4 * (_h(Vector3(seed, i, 1.0)) - 0.5)) * TAU / count
		var o := Vector3(cos(a) * stretch.x, 0, sin(a) * stretch.z)
		var on: Vector3 = o.normalized()
		var sd := Vector3(-on.z, 0, on.x)
		var len: float = lerpf(lmin, lmax, _h(Vector3(seed, i, 2.0))) * (1.0 + side * on.x)
		var ar: float = anchor_r * (0.94 + 0.1 * _h(Vector3(seed, i, 3.0)))
		var hw: float = width * (0.85 + 0.3 * _h(Vector3(seed, i, 4.0)))
		var twist: float = (_h(Vector3(seed, i, 8.0)) - 0.5) * 0.5
		var sdt: Vector3 = (sd + on * twist).normalized()
		var path: Array = [c + o * ar * 0.72 + Vector3(0, anchor_y - c.y + 0.25, 0),
			c + o * (ar + 0.22) + Vector3(0, anchor_y - c.y - 0.12, 0)]
		path.append((path[1] as Vector3) + on * 0.16 + Vector3(0, -len * 0.58, 0))
		path.append((path[1] as Vector3) + on * 0.2 + Vector3(0, -len, 0))
		var widths: Array = [hw * 0.8, hw, hw * 0.78, hw * 0.28]
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var idx := PackedInt32Array()
		for face: int in 2:
			var fo: float = 1.0 if face == 0 else -1.0
			var b: int = v.size()
			for j: int in 4:
				var p: Vector3 = path[j]
				var w: float = widths[j]
				v.append(p - sdt * w)
				v.append(p + sdt * w)
				n.append((on * fo + Vector3(0, 0.3, 0) - sdt * 0.45).normalized())
				n.append((on * fo + Vector3(0, 0.3, 0) + sdt * 0.45).normalized())
			for j: int in 3:
				var l0: int = b + j * 2
				idx.append_array([l0, l0 + 1, l0 + 2, l0 + 1, l0 + 3, l0 + 2])
		_part(_mk(v, n, idx), Transform3D.IDENTITY, tip_col, {"kind": Kind.IVY, "mask": mask, "normals": "smooth",
			"col2": top_col, "grad": "y", "seed": seed + i, "jitter": 0.025, "tint": 0.14, "wind": Vector2(1.5, 0.5)})


func _build_willow() -> void:
	_begin()
	_roots(6, 0.32, 0.38, WBARK_D, 70.0)
	var bark := {"seed": 70.0, "jitter": 0.035}
	var in_top: Color = WIL_D.lerp(WIL, 0.3)
	var in_tip: Color = WIL.lerp(WIL_L, 0.45)
	# V0: classic weeping willow: a stout trunk leaning a little toward +X, three limbs, a round umbrella crown,
	# a full curtain down to ~1.2 m.
	_limb(Vector3(0, -0.15, 0), Vector3(0.18, 1.7, 0.03), 0.4, 0.3, 7, WBARK, bark.merged({"mask": V0}))
	_limb(Vector3(0.18, 1.6, 0.03), Vector3(0.9, 3.1, 0.4), 0.2, 0.09, 5, WBARK, bark.merged({"mask": V0}))
	_limb(Vector3(0.18, 1.6, 0.03), Vector3(-0.4, 3.2, -0.5), 0.19, 0.08, 5, WBARK, bark.merged({"mask": V0}))
	_limb(Vector3(0.18, 1.7, 0.03), Vector3(0.3, 3.5, -0.05), 0.2, 0.08, 5, WBARK_D, bark.merged({"mask": V0}))
	var c0 := Vector3(0.25, 3.7, 0.0)
	_willow_crown(c0, 2.1, V0, 71.0)
	_cascade(c0, 2.1, 22, 1.7, 2.6, 0.3, V0, 72.0)
	_curtain(c0, 1.3, 3.3, 7, 1.3, 1.7, 0.24, V0, 73.0, 0.0, 0.3, in_top, in_tip)
	_disc(Vector3(0.25, 0, 0.0), 2.3, 2.2, 14, 70.0, V0)
	# V1: leaning over the water (local +X): trunk slanting out, a flatter crown thrown to +X, the strands on that
	# side trailing almost to the ground (the "dipping" curtain).
	_limb(Vector3(0, -0.15, 0), Vector3(0.45, 1.3, 0.0), 0.42, 0.33, 7, WBARK, bark.merged({"mask": V1}))
	_limb(Vector3(0.45, 1.25, 0.0), Vector3(1.05, 2.5, 0.08), 0.33, 0.22, 7, WBARK, bark.merged({"mask": V1}))
	_limb(Vector3(1.0, 2.4, 0.08), Vector3(1.8, 3.2, 0.45), 0.17, 0.08, 5, WBARK, bark.merged({"mask": V1}))
	_limb(Vector3(1.0, 2.4, 0.08), Vector3(0.6, 3.3, -0.5), 0.16, 0.07, 5, WBARK_D, bark.merged({"mask": V1}))
	var c1 := Vector3(1.1, 3.45, 0.0)
	_willow_crown(c1, 2.2, V1, 74.0, WIL_D, WIL, WIL_L, Vector3(1.12, 1.0, 0.95))
	_cascade(c1, 2.2, 22, 1.6, 2.2, 0.3, V1, 75.0, 0.3, Vector3(1.12, 1.0, 0.95))
	_curtain(c1, 1.35, 3.0, 7, 1.2, 1.5, 0.24, V1, 76.0, 0.15, 0.6, in_top, in_tip)
	_disc(Vector3(0.9, 0, 0.0), 2.5, 2.1, 14, 71.0, V1)
	# V2: an old pollard: short fat trunk with a burl, 3 upright limbs, a taller two-storey crown, darker leaves and
	# a longer, straighter curtain.
	_limb(Vector3(0, -0.15, 0), Vector3(0.05, 1.45, 0.0), 0.46, 0.4, 7, WBARK_D, bark.merged({"mask": V2}))
	_part(_sph(0.42, 7, 4), _xf(Vector3(0.05, 1.5, 0.0), Vector3.ZERO, Vector3(1.1, 0.6, 1.05)), WBARK_D,
		{"kind": Kind.BARK, "mask": V2, "normals": "smooth", "jitter": 0.05, "seed": 77.0})
	for k: int in 3:
		var a: float = k * TAU / 3.0 + 0.4
		_limb(Vector3(0.05, 1.55, 0.0), Vector3(cos(a) * 0.6, 3.5, sin(a) * 0.6), 0.17, 0.08, 5, WBARK,
			bark.merged({"mask": V2, "seed": 78.0 + k}))
	var c2 := Vector3(0.0, 4.0, 0.0)
	var d2: Color = WIL_D.darkened(0.08)
	_willow_crown(c2, 1.95, V2, 79.0, d2, WIL.darkened(0.1), WIL_L.darkened(0.1))
	_cascade(c2, 1.95, 20, 2.3, 2.9, 0.3, V2, 80.0, 0.0, Vector3.ONE, WIL_TOP.darkened(0.1), WIL_TIP.darkened(0.08))
	_curtain(c2, 1.15, 3.6, 7, 1.4, 1.8, 0.24, V2, 81.0, 0.0, 0.5, in_top.darkened(0.1), in_tip.darkened(0.1))
	_disc(Vector3(0, 0, 0.0), 2.1, 2.0, 14, 72.0, V2)
	_commit(MESH_DIR + "tree_willow.res", {"wind_h": 5.0, "split": true})


## The border / far stand-in: same silhouette (umbrella dome + fringed curtain skirt), ~150 triangles, no variants,
## "lite" shading (UV2.x = -1), no contact disc.
func _build_willow_far() -> void:
	_begin()
	_limb(Vector3(0, -0.1, 0), Vector3(0.2, 2.2, 0), 0.34, 0.2, 4, WBARK)
	var c := Vector3(0.25, 3.7, 0.0)
	_part(_sph(1.55, 6, 3), _xf(c + Vector3(0, 0.05, 0), Vector3.ZERO, Vector3(1.4, 0.6, 1.4)), WIL_D.lerp(WIL, 0.4),
		{"kind": Kind.IVY, "normals": "crown", "crown": c, "crown_k": 0.6, "col2": WIL.lightened(0.05),
		"jitter": 0.12, "seed": 90.0, "ao_c": c, "ao_r": 2.2})
	_part(_sph(0.95, 6, 3), _xf(c + Vector3(-0.1, 0.7, 0.05), Vector3.ZERO, Vector3(1.15, 0.62, 1.15)), WIL,
		{"kind": Kind.IVY, "normals": "crown", "crown": c, "crown_k": 0.6, "col2": WIL_L.lerp(WIL, 0.4),
		"jitter": 0.1, "seed": 91.0})
	# Curtain skirt: a double-sided ring from under the dome rim down to a fringed hem (long / short tongues).
	var segs: int = 14
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for face: int in 2:
		var fo: float = 1.0 if face == 0 else -1.0
		var b: int = v.size()
		for i: int in segs:
			var a: float = i * TAU / segs
			var o := Vector3(cos(a), 0, sin(a))
			v.append(c + o * 1.95 + Vector3(0, -0.2, 0))
			n.append((o * fo + Vector3(0, 0.3, 0)).normalized())
			var hem: float = 1.3 if i % 2 == 0 else 1.95
			v.append(Vector3(c.x, 0, c.z) + o * 2.25 + Vector3(0, hem, 0))
			n.append((o * fo + Vector3(0, 0.15, 0)).normalized())
		for i: int in segs:
			var j: int = (i + 1) % segs
			idx.append_array([b + i * 2, b + j * 2, b + i * 2 + 1, b + j * 2, b + j * 2 + 1, b + i * 2 + 1])
	_part(_mk(v, n, idx), Transform3D.IDENTITY, WIL_TIP, {"kind": Kind.IVY, "normals": "smooth",
		"col2": WIL_TOP, "grad": "y", "seed": 92.0, "jitter": 0.05, "wind": Vector2(1.2, 0.5)})
	for i: int in _uv2.size():
		_uv2[i] = Vector2(-1.0, _uv2[i].y)
	_commit(MESH_DIR + "tree_willow_far.res", {"wind_h": 5.0})


