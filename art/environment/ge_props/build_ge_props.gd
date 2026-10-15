extends SceneTree
## G-E fixes C (docs/art/ge_fixes_c.md): bakes the props of review items 9 and 10 with the SHARED painted nature material
## (nature_props/nature_mat.tres: bark / leaves / stone / ivy kinds) + its contact-shadow material, the same recipe as
## the landmarks (build_landmarks_b.gd; its helpers are copied here, that script builds everything when instantiated):
##   meshes/oldroot.res       the Oldroot of mission 3 (Sighing Wood): an ancient tree of seven twisted trunk strands
##                            round a dark heart, a gap at the front (+Z) where the Signet glows (0, 2.1, 1.15), flared
##                            buttress roots (<= 5.4 m), five great limbs, a high broken canopy open to the south (the
##                            RTS camera keeps the hollow, the thorn ring and the clearing in view), hanging moss, ivy,
##                            bracket fungi. Draw-only: the mission keeps its own trunk collider (r 1.6).
##   meshes/warden_gate.res   the Warden Gate (missions 3 / 4): a ruined arch of mossy dressed stone on two piers inside
##                            the gate's collider feet (x +-1.5, 1 m wide, z +-1 m), a carved keystone, ivy, rubble.
##                            Draw-only (the gate keeps its feet colliders and its open-crack quad).
##   meshes/lane_fence.res    a broken split-rail fence span (~3.2 m, 1.1 m tall) for the Wave Strike lane edges.
##   meshes/lane_banner.res   a tall banner pole with a crossbar and a tattered ochre / ash-red pennant (the cloth sways
##                            with the shader's wind: UV.x weight).
##   oldroot.tscn / warden_gate_art.tscn   Node3D > "Model" (+ the Oldroot's "HollowGlow"); no collider, no script.
## Every mesh: surface 0 painted (nature_mat), surface 1 the contact discs (nature_contact_mat). One variant (mask 0).
##
## Re-run after changing a shape:
##   tools\godot_run.ps1 --headless --path . -s res://art/environment/ge_props/build_ge_props.gd --quit-after 600

const DIR := "res://art/environment/ge_props/"
const MESH_DIR := "res://art/environment/ge_props/meshes/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }

# --- palette (sRGB) ---------------------------------------------------------------------------------
# Oldroot: grey-brown ancient bark (cooler and greyer than the map's oaks so it reads as OLD), near-black heart.
const BARK := Color(0.29, 0.24, 0.19)
const BARK_D := Color(0.19, 0.155, 0.12)
const BARK_L := Color(0.40, 0.35, 0.28)
const HEART := Color(0.05, 0.045, 0.035)
const FUNGUS := Color(0.70, 0.58, 0.38)
const MOSS := Color(0.20, 0.33, 0.12)
const MOSS_L := Color(0.31, 0.45, 0.16)
const HANG := Color(0.36, 0.42, 0.22)          # hanging old-man's-beard moss
# Canopy: deep old-growth green (a step darker than the map's oaks), lighter sunlit puffs on top.
const LEAF_D := Color(0.10, 0.22, 0.09)
const LEAF := Color(0.17, 0.33, 0.12)
const LEAF_L := Color(0.29, 0.46, 0.16)
# Warden Gate: weathered grey-green dressed stone (cooler than the ruins of the Crown Isle).
const GSTONE := Color(0.47, 0.47, 0.44)
const GSTONE_L := Color(0.55, 0.55, 0.51)
const GSTONE_D := Color(0.35, 0.36, 0.34)
const GCARVE := Color(0.27, 0.28, 0.26)
const IVY := Color(0.16, 0.33, 0.13)
const IVY_L := Color(0.28, 0.47, 0.17)
# Lane props: sun-greyed timber, ochre and ash-red cloth (neutral: no kingdom colour).
const RAIL := Color(0.46, 0.40, 0.33)
const RAIL_D := Color(0.33, 0.28, 0.23)
const POLE := Color(0.30, 0.23, 0.17)
const CLOTH := Color(0.62, 0.46, 0.22)
const CLOTH_R := Color(0.48, 0.20, 0.14)
const IRON := Color(0.22, 0.21, 0.22)

## The Signet's spot in the Oldroot's frame (mission_03.gd SIGNET_POS + SIGNET_LOOK_OFFSET): the gap must show it.
const SIGNET_AT := Vector3(0.0, 2.1, 1.15)

var mat: Material
var contact_mat: Material
var _conv: float = 1.0

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _w := PackedFloat32Array()      # UV.x: stone moss amount / wind weight
var _uv2 := PackedVector2Array()    # (variant mask 0, kind)
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	mat = load(NDIR + "nature_mat.tres") as Material
	contact_mat = load(NDIR + "nature_contact_mat.tres") as Material
	var oldroot := _build_oldroot()
	_scene_oldroot(oldroot)
	var gate := _build_gate()
	_scene_simple("warden_gate_art.tscn", "WardenGateArt", gate)
	_build_fence()
	_build_banner()
	for line: String in _report:
		print(line)
	print("GE PROPS BUILD OK")
	quit()


# --- saving ----------------------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _save_ref(res: Resource, path: String) -> Resource:
	_save(res, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


# --- small math ------------------------------------------------------------------------------------

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


# --- primitive arrays ------------------------------------------------------------------------------

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


## A closed loft through rings of equal vertex count (star-convex sections).
func _loft(rings: Array, cap_first: bool = true, cap_last: bool = true) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var cents: Array[Vector3] = []
	var centre := Vector3.ZERO
	for r: PackedVector3Array in rings:
		var c := Vector3.ZERO
		for p: Vector3 in r:
			c += p
		c /= float(r.size())
		cents.append(c)
		centre += c
	centre /= float(rings.size())
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
	var caps: Array[int] = []
	if cap_first:
		caps.append(0)
	if cap_last:
		caps.append(rings.size() - 1)
	for k2: int in caps:
		var ring: PackedVector3Array = rings[k2]
		var cn: Vector3 = (cents[k2] - centre).normalized()
		if cn.length_squared() < 0.5:
			cn = Vector3.UP
		var base2: int = v.size()
		v.append(cents[k2])
		n.append(cn)
		for i: int in m:
			v.append(ring[i])
			n.append(cn)
		for i: int in m:
			idx.append_array([base2, base2 + 1 + i, base2 + 1 + (i + 1) % m])
	return _mk(v, n, idx)


## A chiselled rock chunk: a low-poly ellipsoid cut by random planes (build_nature.gd's recipe).
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


# --- the part appender (flat painted shading, like build_nature.gd) --------------------------------

## Adds mesh arrays transformed by xf. Options: kind (Kind), jitter (m), seed, normals "flat" | "smooth", col2 + grad
## ("y" | "r"), moss (UV.x: stone moss / wind weight), tint (per-face value variation).
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
	var mode: String = o.get("normals", "flat")
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var moss: float = o.get("moss", 0.0)
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
		var p: Vector3 = v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter
		tv[i] = xf * p
		tn[i] = (nb * n[i]).normalized()
	for t: int in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
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
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k))
			_w.append(moss)
			_uv2.append(Vector2(0.0, kind))


func _stone(arr: Array, xf: Transform3D, col: Color, seed: float, moss: float = 0.6, jitter: float = 0.02,
		tint: float = 0.07) -> void:
	_part(arr, xf, col, {"kind": Kind.STONE, "moss": moss, "jitter": jitter, "seed": seed, "tint": tint})


## A limb (tapered cylinder) from a to b, smooth normals, bark by default.
func _limb(a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Color, o: Dictionary = {}) -> void:
	var len: float = a.distance_to(b)
	var oo: Dictionary = o.duplicate()
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	if not oo.has("kind"):
		oo["kind"] = Kind.BARK
	_part(_cyl(r1, r0, len, segs), Transform3D(_along(a, b), (a + b) * 0.5), col, oo)


## A limb through points (radii per point), with a joint sphere at each inner point so the bends do not tear.
func _chain(pts: Array, radii: Array, segs: int, col: Color, o: Dictionary = {}) -> void:
	for i: int in pts.size() - 1:
		var c0: Color = col
		_limb(pts[i], pts[i + 1], radii[i], radii[i + 1], segs, c0, o)
		if i > 0:
			var oo: Dictionary = o.duplicate()
			oo["normals"] = "smooth"
			if not oo.has("kind"):
				oo["kind"] = Kind.BARK
			_part(_sph(float(radii[i]) * 1.02, segs, 4), Transform3D(Basis(), pts[i]), col, oo)


## A puffy leaf cloud of `n` jittered spheres round `c` (radius `r`), darker at the bottom (baked crown occlusion).
## Kind IVY (foliage shading, never one of the shader's random autumn crowns: the Oldroot stands at the origin, whose
## position hash turned a LEAVES crown gold).
func _puff(c: Vector3, r: float, n: int, seed: float) -> void:
	for i: int in n:
		var h := _h3(Vector3(seed, i, 3.3))
		var p := c + Vector3(h.x * r * 0.9, h.y * r * 0.35, h.z * r * 0.9)
		var rr := r * lerpf(0.45, 0.75, _h(Vector3(seed, i, 5.1)))
		var light: float = clampf(0.5 + (p.y - c.y) / (r * 1.2), 0.0, 1.0)
		var top: Color = LEAF.lerp(LEAF_L, light)
		_part(_sph(rr, 10, 6), _xf(p, Vector3(0.0, h.x * 3.0, 0.0), Vector3(1.0, 0.78, 1.0)), LEAF_D,
			{"kind": Kind.IVY, "col2": top, "jitter": rr * 0.07, "seed": seed + i, "moss": 0.7, "tint": 0.1,
			"normals": "smooth"})


## Soft contact shadow disc (surface 1) just above the ground.
func _disc(c: Vector3, rx: float, rz: float, segs: int, seed: float) -> void:
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
			_cuv2.append(Vector2(0.0, 0.0))


# --- commit ----------------------------------------------------------------------------------------

## Bakes the height gradient (COLOR.a), moss / wind (UV.x), local height (UV.y), kind (UV2.y) and saves
## ge_props/meshes/<name>.res: surface 0 nature_mat, then the contact discs.
func _commit(name: String) -> ArrayMesh:
	var maxy: float = -INF
	var miny: float = INF
	for p: Vector3 in _v:
		maxy = maxf(maxy, p.y)
		miny = minf(miny, p.y)
	var span: float = maxf(maxy, 0.01)
	var uv := PackedVector2Array()
	uv.resize(_v.size())
	for i: int in _v.size():
		var cc: Color = _c[i]
		cc.a = clampf(_v[i].y / span, 0.0, 1.0)
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
	var info := "mesh %-14s %5d tris, %5d verts" % [name, _v.size() / 3,
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


# --- scenes ----------------------------------------------------------------------------------------

func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


func _model(mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Model"
	mi.mesh = mesh
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return mi


func _scene_simple(file: String, root_name: String, mesh: Mesh) -> void:
	var root := Node3D.new()
	root.name = root_name
	root.add_child(_model(mesh))
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, DIR + file)
	root.free()


## oldroot.tscn: "Model" + "HollowGlow" (a soft green-gold glow on the dark heart behind the gap, opaque emission,
## energy 0.9 x a mid colour: a sap-green core, never a white disc; no light, so it costs nothing at any tier).
func _scene_oldroot(mesh: Mesh) -> void:
	var root := Node3D.new()
	root.name = "OldrootArt"
	root.add_child(_model(mesh))
	var glow := MeshInstance3D.new()
	glow.name = "HollowGlow"
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 12
	sm.rings = 6
	glow.mesh = sm
	glow.position = Vector3(0.0, 2.05, 0.64)
	glow.scale = Vector3(0.3, 1.2, 0.24)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.16, 0.15, 0.06)
	gm.emission_enabled = true
	gm.emission = Color(0.55, 0.64, 0.24)
	gm.emission_energy_multiplier = 0.9
	gm.roughness = 1.0
	glow.material_override = _save_ref(gm, DIR + "oldroot_glow_mat.tres") as Material
	root.add_child(glow)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	_save(ps, DIR + "oldroot.tscn")
	root.free()


# ===================================================================================================
# THE OLDROOT
# Frame: trunk centre at the origin, ground y 0, front (+Z) = the gap where the Signet hangs (0, 2.1, 1.15).
# Seven strands spiral up from a ring (r ~1.15) and close into a bole at y ~6; the front strand is missing below
# y 3.7, so the dark heart (r 0.62) and its glow show between the two front strands (at +-56 deg).
# ===================================================================================================

func _build_oldroot() -> ArrayMesh:
	_begin()
	# The heart: a dark core inside the strands (seen through the gap), from the ground into the bole.
	_part(_cyl(0.66, 0.74, 5.6, 10), _xf(Vector3(0.0, 2.8, 0.0)), HEART, {"kind": Kind.BARK, "normals": "smooth",
		"col2": BARK_D.darkened(0.55), "tint": 0.04})
	# Seven strands (one missing at the front), each a twisting chain from the ground to the bole.
	var angles: Array[float] = []
	for i: int in 7:
		angles.append(deg_to_rad(90.0 + 62.0 + i * (360.0 - 124.0) / 6.0))   # +-62 deg off +Z, spread round the back
	for i: int in angles.size():
		var a0: float = angles[i]
		var pts: Array = []
		var radii: Array = []
		var steps := 7
		for s: int in steps + 1:
			var t := float(s) / float(steps)
			var y := lerpf(-0.2, 6.4, t)
			var twist := a0 + t * 0.75                                       # a slow spiral (clockwise from above)
			var rr := lerpf(1.18, 0.55, pow(t, 0.8)) + sin(t * 7.0 + i) * 0.06
			var p := Vector3(cos(twist) * rr, y, sin(twist) * rr)
			# The two front strands stay apart below ~3.7 m so the Signet shows between them (eased back above).
			if i == 0 or i == angles.size() - 1:
				var side := -1.0 if i == 0 else 1.0
				var held := side * maxf(side * p.x, 0.95)
				p.x = lerpf(held, p.x, smoothstep(3.2, 4.6, y))
			pts.append(p)
			radii.append(lerpf(0.64, 0.40, t) + 0.04 * sin(t * 9.0 + i * 1.7))
		_chain(pts, radii, 9, BARK, {"col2": BARK_L, "tint": 0.1})
	# The bole the strands close into, and its lobed crown where the limbs leave.
	var rings: Array = []
	for k: int in 5:
		var y := 5.2 + k * 0.7
		var r := lerpf(1.05, 0.85, float(k) / 4.0)
		var ring := PackedVector3Array()
		for j: int in 12:
			var a := j * TAU / 12.0
			var lobe := 1.0 + 0.16 * sin(a * 4.0 + k * 0.6)
			ring.append(Vector3(cos(a) * r * lobe, y, sin(a) * r * lobe))
		rings.append(ring)
	_part(_loft(rings), Transform3D(), BARK, {"kind": Kind.BARK, "normals": "smooth", "col2": BARK_L, "tint": 0.08})
	# Buttress roots: thick flanges that arch out of the strand feet, snake a little and sink (none straight at the front:
	# the gap stays open). Lighter at the top (sunlit bark), a moss saddle on most.
	for i: int in 10:
		var a := deg_to_rad(90.0 + 32.0 + i * 296.0 / 9.0) + (_h(Vector3(i, 1, 1)) - 0.5) * 0.25
		var d := Vector3(cos(a), 0.0, sin(a))
		var side := d.cross(Vector3.UP)
		var reach := lerpf(2.5, 3.8, _h(Vector3(i, 2, 1)))
		var wig := (_h(Vector3(i, 3, 1)) - 0.5) * 1.0
		var pts: Array = []
		var radii: Array = []
		for s: int in 7:
			var t := float(s) / 6.0
			var r := lerpf(0.8, reach, t)
			var y := lerpf(1.7, -0.5, pow(t, 0.8)) + sin(t * PI) * 0.12
			pts.append(d * r + side * sin(t * 3.0) * wig * t + Vector3(0, y, 0))
			radii.append(lerpf(0.66, 0.1, pow(t, 0.85)))   # tapers to a thin tip as it dives
		_chain(pts, radii, 8, BARK_D, {"col2": BARK_L, "tint": 0.1})
		if i % 3 != 2:   # a moss saddle on the root's back
			var mp: Vector3 = pts[2]
			_part(_sph(0.36, 8, 4), _xf(mp + Vector3(0, 0.3, 0), Vector3(0, a, 0), Vector3(1.7, 0.42, 1.1)),
				MOSS, {"kind": Kind.IVY, "col2": MOSS_L, "jitter": 0.05, "seed": float(i)})
	# Great limbs from the bole: up and out, mostly to the back and the sides (the south stays open to the camera).
	var limb_dirs: Array[float] = [200.0, 245.0, 290.0, 335.0, 25.0, 150.0]   # degrees in x/z (90 = +Z = front)
	var tips: Array[Vector3] = []
	for i: int in limb_dirs.size():
		var a := deg_to_rad(limb_dirs[i])
		var d := Vector3(cos(a), 0.0, sin(a))
		var reach := lerpf(5.0, 7.0, _h(Vector3(i, 5, 2)))
		var p0 := d * 0.6 + Vector3(0, 7.2, 0)
		var p1 := d * (reach * 0.45) + Vector3(0, 8.9 + _h(Vector3(i, 6, 2)) * 0.6, 0)
		var p2 := d * reach + Vector3(0, 10.0 + _h(Vector3(i, 7, 2)) * 1.4, 0)
		_chain([p0, p1, p2], [0.5, 0.33, 0.16], 8, BARK, {"col2": BARK_L, "tint": 0.1})
		tips.append(p2)
		# Two side branches per limb.
		for b: int in 2:
			var sd := d.rotated(Vector3.UP, (0.7 if b == 0 else -0.6)) * lerpf(1.6, 2.4, _h(Vector3(i, b, 8)))
			var q0: Vector3 = p1.lerp(p2, 0.3)
			var q1 := q0 + sd + Vector3(0, 0.9, 0)
			_limb(q0, q1, 0.16, 0.07, 6, BARK, {"col2": BARK_L})
			tips.append(q1)
		# Hanging moss from the limb.
		for m: int in 3:
			var hp: Vector3 = p0.lerp(p2, 0.35 + m * 0.22)
			var hl := lerpf(0.9, 2.0, _h(Vector3(i, m, 9)))
			_limb(hp, hp + Vector3(0.05, -hl, 0.04), 0.07, 0.015, 4, HANG, {"kind": Kind.IVY, "moss": 0.5})
	# The canopy: big leaf clouds over the limb tips, high (y >= 9.5); none on the camera's line to the gap.
	var crowns: Array[Vector3] = []
	for t: Vector3 in tips:
		var c := t + Vector3(0, 0.9, 0)
		var to_gap := Vector2(c.x, c.z - (SIGNET_AT.z + 0.7 * (c.y - SIGNET_AT.y)))
		if to_gap.length() < 3.4:
			continue
		crowns.append(c)
	for i: int in crowns.size():
		var big := (i % 3) == 0
		_puff(crowns[i], 2.8 if big else 2.1, 9 if big else 6, float(i) * 3.7)
	# Ivy climbing the two front strands, bracket fungi on the back.
	for side: float in [-1.0, 1.0]:
		var base := Vector3(side * 0.95, 0.2, 0.62)
		for k: int in 6:
			var p := base + Vector3(side * 0.06 * sin(k * 1.3), k * 0.55, 0.06 * cos(k))
			_part(_sph(0.2, 6, 3), _xf(p, Vector3(0, k, 0), Vector3(1.3, 0.8, 0.9)), IVY,
				{"kind": Kind.IVY, "col2": IVY_L, "jitter": 0.05, "seed": side * 10.0 + k})
	for k: int in 6:
		var a := deg_to_rad(180.0 + k * 40.0)
		var y := 1.4 + (k % 3) * 0.9
		var p := Vector3(cos(a) * 1.18, y, sin(a) * 1.18)
		_part(_cyl(0.32, 0.36, 0.08, 9), _xf(p, Vector3(0, -a, 0.12), Vector3(1.0, 1.0, 0.6)), FUNGUS,
			{"kind": Kind.STONE, "col2": FUNGUS.lightened(0.15), "tint": 0.05})
	_disc(Vector3.ZERO, 3.4, 3.4, 18, 1.0)
	_disc(Vector3(0.0, 0.0, -1.0), 5.2, 4.6, 18, 2.0)
	return _commit("oldroot")


# ===================================================================================================
# THE WARDEN GATE
# Frame: the gate's own (WardenGate: feet colliders 1 x 4.5 x 2 at x +-1.5, the opening x -1..1, faces +Z).
# Two piers of dressed blocks (the west one broken lower), a round arch (radius 1.0 inside, voussoirs to 1.75)
# springing at y 3.5, a carved keystone, moss on every top (stone moss), ivy down the east pier, rubble at the feet.
# ===================================================================================================

func _build_gate() -> ArrayMesh:
	_begin()
	for side: float in [-1.0, 1.0]:
		var x := side * 1.5
		var y := 0.0
		var k := 0
		var top := 3.55 if side > 0.0 else 3.45
		# A plinth, then courses.
		_stone(_chunk(Vector3(0.68, 0.28, 1.08), 5, 11.0 + side, 0.9, 8, 4), _xf(Vector3(x, 0.18, 0.0)), GSTONE_D, 1.0,
			0.3, 0.02)
		y = 0.38
		while y < top:
			var h := minf(lerpf(0.52, 0.66, _h(Vector3(side, k, 1))), top - y)
			var w := 0.98 - k * 0.012
			var off := Vector3((_h(Vector3(side, k, 2)) - 0.5) * 0.06, 0.0, (_h(Vector3(side, k, 3)) - 0.5) * 0.08)
			var col := GSTONE.lerp(GSTONE_L if k % 2 == 0 else GSTONE_D, _h(Vector3(side, k, 4)) * 0.6)
			_stone(_box(Vector3(w, h - 0.04, 1.62), 1), _xf(Vector3(x, y + h * 0.5, 0.0) + off,
				Vector3(0.0, (_h(Vector3(side, k, 5)) - 0.5) * 0.06, 0.0)), col, side * 7.0 + k, 0.65, 0.035)
			y += h
			k += 1
		# Impost block the arch springs from.
		_stone(_box(Vector3(1.12, 0.26, 1.76), 1), _xf(Vector3(x, top + 0.13, 0.0)), GSTONE_L, side * 3.0, 0.8, 0.02)
	# The arch: 9 voussoirs round (0, 3.75), inner radius 1.0, outer 1.72; the keystone carved and proud.
	var cy := 3.75
	for i: int in 9:
		var a0 := PI - i * PI / 9.0
		var a1 := PI - (i + 1) * PI / 9.0
		var am := (a0 + a1) * 0.5
		var ring_in := 1.0
		var ring_out := 1.72 + (0.12 if i == 4 else 0.0)
		var poly := PackedVector2Array([Vector2(cos(a0) * ring_in, sin(a0) * ring_in) * 1.0,
			Vector2(cos(a1) * ring_in, sin(a1) * ring_in), Vector2(cos(a1) * ring_out, sin(a1) * ring_out),
			Vector2(cos(a0) * ring_out, sin(a0) * ring_out)])
		var a := PackedVector3Array()
		var b := PackedVector3Array()
		var shrink := 0.97
		var cxy := Vector2(cos(am), sin(am)) * (ring_in + ring_out) * 0.5
		for p: Vector2 in poly:
			var q := cxy + (p - cxy) * shrink
			a.append(Vector3(q.x, cy + q.y, -0.8))
			b.append(Vector3(q.x, cy + q.y, 0.8))
		var col := GSTONE.lerp(GSTONE_L, _h(Vector3(i, 1, 9)) * 0.7)
		if i == 4:
			col = GSTONE_L
		_stone(_loft([a, b]), Transform3D(Basis(Vector3.FORWARD, (_h(Vector3(i, 2, 9)) - 0.5) * 0.03), Vector3.ZERO),
			col, float(i) * 1.3, 0.7, 0.03)
	# Keystone face: a stern warden mask carved proud of the keystone (brow, eyes, beard of leaves), both faces.
	for fz: float in [1.0, -1.0]:
		var kz := fz * 0.86
		var kc := Vector3(0.0, cy + 1.42, kz)
		_part(_box(Vector3(0.44, 0.52, 0.1)), _xf(kc), GSTONE_D, {"kind": Kind.STONE, "moss": 0.2})
		_part(_box(Vector3(0.36, 0.07, 0.06)), _xf(kc + Vector3(0, 0.13, fz * 0.06)), GCARVE, {"kind": Kind.STONE})
		for ex: float in [-0.09, 0.09]:
			_part(_box(Vector3(0.07, 0.05, 0.05)), _xf(kc + Vector3(ex, 0.05, fz * 0.07)), HEART, {"kind": Kind.STONE})
		_part(_cyl(0.0, 0.13, 0.22, 5), _xf(kc + Vector3(0, -0.14, fz * 0.06), Vector3(PI, 0, 0)), IVY,
			{"kind": Kind.IVY, "col2": IVY_L})
	# The wall coping over the arch (broken short of the west pier) and two low wall stubs flanking the piers.
	_stone(_box(Vector3(2.9, 0.34, 1.5), 1), _xf(Vector3(0.35, 5.62, 0.0), Vector3(0, 0, 0.05)), GSTONE_D, 4.0, 0.9, 0.04)
	for side: float in [-1.0, 1.0]:
		for j: int in 2:
			var sx := side * (2.35 + j * 0.62)
			var hh := 0.55 - j * 0.2
			_stone(_box(Vector3(0.6, hh, 0.85), 1), _xf(Vector3(sx, hh * 0.5, (_h(Vector3(side, j, 4)) - 0.5) * 0.2),
				Vector3(0, (_h(Vector3(side, j, 6)) - 0.5) * 0.3, 0)), GSTONE_D, side * 5.0 + j, 0.75, 0.04)
	# Ivy down the east pier's front and back.
	for fz: float in [0.84, -0.84]:
		for k: int in 9:
			var p := Vector3(1.5 + sin(k * 1.7) * 0.32, 4.3 - k * 0.42, fz)
			_part(_sph(0.2, 6, 3), _xf(p, Vector3(0, k, 0), Vector3(1.1, 1.0, 0.5)), IVY,
				{"kind": Kind.IVY, "col2": IVY_L, "jitter": 0.05, "seed": fz * 10.0 + k})
	# Rubble at the feet (low: units walk through it), a fallen voussoir from the broken coping.
	for i: int in 9:
		var a := _h(Vector3(i, 4, 4)) * TAU
		var r := lerpf(2.1, 3.3, _h(Vector3(i, 5, 4)))
		var p := Vector3(cos(a) * r, 0.1, sin(a) * r * 0.8)
		var s := lerpf(0.16, 0.3, _h(Vector3(i, 6, 4)))
		_stone(_chunk(Vector3(s * 1.3, s, s), 5, 30.0 + i, 0.7), _xf(p), GSTONE_D, 30.0 + i, 0.5, 0.0)
	_stone(_box(Vector3(0.66, 0.34, 0.8), 1), _xf(Vector3(-2.2, 0.17, 1.4), Vector3(0.1, 0.6, 0.15)), GSTONE, 50.0, 0.6,
		0.04)
	_disc(Vector3(-1.5, 0, 0), 0.95, 1.25, 12, 3.0)
	_disc(Vector3(1.5, 0, 0), 0.95, 1.25, 12, 4.0)
	_disc(Vector3(0, 0, 0), 3.0, 1.6, 16, 5.0)
	return _commit("warden_gate")


# ===================================================================================================
# LANE PROPS (Wave Strike, Ashwind Reach)
# ===================================================================================================

## A split-rail fence span along +X (x -1.6..1.6): three leaning posts, two rails, the right-hand upper rail fallen.
func _build_fence() -> ArrayMesh:
	_begin()
	var posts: Array[float] = [-1.6, 0.0, 1.6]
	for i: int in posts.size():
		var lean := (_h(Vector3(i, 1, 2)) - 0.5) * 0.16
		var h := lerpf(1.05, 1.2, _h(Vector3(i, 2, 2)))
		_limb(Vector3(posts[i], -0.1, 0.0), Vector3(posts[i] + lean, h, lean * 0.5), 0.09, 0.07, 6, RAIL_D,
			{"normals": "flat", "col2": RAIL})
	_limb(Vector3(-1.75, 0.45, 0.04), Vector3(1.75, 0.5, -0.02), 0.06, 0.055, 5, RAIL, {"normals": "flat"})
	_limb(Vector3(-1.75, 0.88, 0.03), Vector3(0.1, 0.9, 0.0), 0.055, 0.05, 5, RAIL, {"normals": "flat"})
	_limb(Vector3(0.15, 0.86, 0.02), Vector3(1.85, 0.06, 0.35), 0.055, 0.05, 5, RAIL_D, {"normals": "flat"})   # fallen
	_disc(Vector3.ZERO, 1.9, 0.35, 10, 6.0)
	return _commit("lane_fence")


## A banner pole (4.2 m) with a crossbar and a tattered two-colour pennant hanging along +X; the cloth sways (UV.x).
func _build_banner() -> ArrayMesh:
	_begin()
	_limb(Vector3(0, -0.2, 0), Vector3(0.03, 4.2, 0.0), 0.075, 0.055, 7, POLE, {"col2": POLE.lightened(0.1)})
	_part(_cyl(0.0, 0.09, 0.22, 6), _xf(Vector3(0.03, 4.3, 0.0)), IRON, {"kind": Kind.STONE})
	_limb(Vector3(-0.1, 3.9, 0.0), Vector3(1.25, 3.9, 0.0), 0.045, 0.04, 5, POLE)
	# The pennant: a strip of quads hanging from the bar, ragged bottom edge, a dark red band at the bottom.
	var cols := 6
	var rows := 5
	var w := 1.15
	var hh := 2.1
	for cx: int in cols:
		for ry: int in rows:
			var x0 := 0.05 + w * cx / cols
			var x1 := 0.05 + w * (cx + 1) / cols
			var y0 := 3.85 - hh * ry / rows
			var y1 := 3.85 - hh * (ry + 1) / rows
			if ry == rows - 1:
				y1 += (_h(Vector3(cx, 7, 1)) - 0.2) * 0.45   # tattered hem
			var wv := 0.06
			var p0 := Vector3(x0, y0, sin(x0 * 5.0 + y0) * wv)
			var p1 := Vector3(x1, y0, sin(x1 * 5.0 + y0) * wv)
			var p2 := Vector3(x1, y1, sin(x1 * 5.0 + y1) * wv)
			var p3 := Vector3(x0, y1, sin(x0 * 5.0 + y1) * wv)
			var col := CLOTH if ry < rows - 2 else CLOTH_R
			var weight := 0.25 + 0.6 * float(ry + 1) / rows   # the hem moves most
			var arr := _mk(PackedVector3Array([p0, p1, p2, p0, p2, p3, p0, p2, p1, p0, p3, p2]),
				PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK,
					Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD,
					Vector3.FORWARD]), PackedInt32Array())
			_part(arr, Transform3D(), col, {"kind": Kind.BARK, "moss": weight, "tint": 0.1})
	_disc(Vector3.ZERO, 0.35, 0.35, 8, 7.0)
	return _commit("lane_banner")
