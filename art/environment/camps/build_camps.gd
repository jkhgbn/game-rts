extends SceneTree
## Task 12.V24 (docs/design/map-fill.md 5.2 and 10): bakes the four monster camp sites. Run once (headless is fine),
## then import:
##   $GODOT --headless --path . -s res://art/environment/camps/build_camps.gd --quit-after 600
##   $GODOT --headless --path . --import
## Writes art/environment/camps/meshes/<kind>_{base,active,cleared,ground}.res, the shared camp_glow_mat.tres /
## camp_mud_mat.tres and the scenes <kind>_site.tscn (root script camp_site.gd, see there for the node layout, the
## frames and set_cleared). Look at the previews after a change (camps_preview.gd, windowed).
##
## Mesh format: the painted surface uses the SHARED nature_props/nature_mat.tres (nature_painted.gdshader: COLOR.rgb
## sRGB colour block, COLOR.a height gradient per part, UV.x moss (stone) / wind weight (foliage), UV.y height above
## the ground, UV2.y kind), soft contact discs use nature_contact_mat.tres, glowing pieces camp_glow_mat.tres (COLOR.a
## phase, UV.x energy weight), the wallow pit camp_mud_mat.tres (UV.x wetness). Flat shaded, welded + indexed.

const CDIR := "res://art/environment/camps/"
const MESH_DIR := "res://art/environment/camps/meshes/"
const NDIR := "res://art/environment/nature_props/"
const SITE_GROUND_MAT := "res://art/environment/neutral/site_ground_mat.tres"
const NOISE := "res://art/shaders/paint_noise.tres"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }

const TARGETS: Array[String] = ["base", "active", "cleared"]
const SURFACES: Array[String] = ["painted", "mud", "contact", "glow"]

# --- palette (sRGB) -------------------------------------------------------------------------------------------
# Wallow.
const MUD_WET := Color(0.29, 0.21, 0.14)
const MUD := Color(0.40, 0.30, 0.20)
const MUD_L := Color(0.50, 0.40, 0.28)
const MUD_DRY := Color(0.58, 0.49, 0.36)
const BONE := Color(0.88, 0.83, 0.70)
const BONE_D := Color(0.64, 0.58, 0.46)
const SOCKET := Color(0.12, 0.09, 0.07)
const BARK := Color(0.33, 0.24, 0.16)
const BARK_D := Color(0.22, 0.16, 0.11)
const WOOD_IN := Color(0.82, 0.67, 0.44)
const WOOD_GREY := Color(0.62, 0.58, 0.50)
const DRY_GRASS := Color(0.66, 0.58, 0.32)
const HEATH := Color(0.42, 0.47, 0.22)
const STONE := Color(0.50, 0.48, 0.44)
const STONE_D := Color(0.36, 0.35, 0.33)
# Nest.
const REED := Color(0.42, 0.52, 0.20)
const REED_D := Color(0.27, 0.36, 0.13)
const REED_DRY := Color(0.70, 0.62, 0.36)
const CATTAIL := Color(0.38, 0.22, 0.12)
const NEST := Color(0.54, 0.47, 0.28)
const NEST_D := Color(0.34, 0.29, 0.18)
const NEST_MUD := Color(0.24, 0.20, 0.14)
const EGG_GLOW := Color(1.0, 0.52, 0.12)
const EGG_SHELL := Color(0.86, 0.80, 0.60)
const YOLK := Color(0.80, 0.52, 0.16)
const LILY := Color(0.28, 0.50, 0.20)
# Hollow (the Gloomcap palette: cap (0.31, 0.37, 0.46), spots (0.76, 0.78, 0.76), stalk (0.62, 0.58, 0.5),
# glow (0.42, 0.95, 0.82)).
const CAP := Color(0.33, 0.40, 0.52)
const CAP_D := Color(0.22, 0.26, 0.36)
const SPOT := Color(0.80, 0.82, 0.80)
const STALK := Color(0.70, 0.66, 0.57)
const STALK_D := Color(0.48, 0.44, 0.38)
const GILL_DEAD := Color(0.42, 0.40, 0.38)
const SPORE_GLOW := Color(0.42, 0.95, 0.82)
const SPORE_MOSS := Color(0.20, 0.27, 0.26)
const ROT_BARK := Color(0.26, 0.20, 0.15)
const SHELF := Color(0.72, 0.52, 0.30)
const FOREST_MOSS := Color(0.24, 0.36, 0.16)
# Stag glade (the Hollow Stag's leaf glow (0.48, 1.0, 0.26)).
const ANTLER := Color(0.80, 0.74, 0.60)
const ANTLER_T := Color(0.93, 0.89, 0.78)
const ALTAR := Color(0.52, 0.52, 0.49)
const ALTAR_D := Color(0.38, 0.38, 0.37)
const LEAF_GLOW := Color(0.52, 1.0, 0.30)
const MOSS := Color(0.30, 0.46, 0.15)
const FERN := Color(0.30, 0.50, 0.18)
const FLOWER := Color(0.96, 0.94, 0.84)
const FLOWER_Y := Color(0.98, 0.84, 0.30)


class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()


var mats := {}
var _bufs := {}
var _tgt := "base"
var _conv := 1.0
var _rng := RandomNumberGenerator.new()
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	_make_materials()
	_build_wallow()
	_build_nest()
	_build_hollow()
	_build_stag()
	for line: String in _report:
		print(line)
	print("CAMPS BUILD OK")
	quit()


# --- materials / saving ----------------------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _save_ref(res: Resource, path: String) -> Resource:
	_save(res, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


func _make_materials() -> void:
	mats["painted"] = load(NDIR + "nature_mat.tres") as Material
	mats["contact"] = load(NDIR + "nature_contact_mat.tres") as Material
	var gm := ShaderMaterial.new()
	gm.shader = load(CDIR + "camp_glow.gdshader") as Shader
	mats["glow"] = _save_ref(gm, CDIR + "camp_glow_mat.tres")
	var mm := ShaderMaterial.new()
	mm.shader = load(CDIR + "camp_mud.gdshader") as Shader
	mm.set_shader_parameter(&"noise_tex", load(NOISE))
	mats["mud"] = _save_ref(mm, CDIR + "camp_mud_mat.tres")


# --- small math --------------------------------------------------------------------------------------------------

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


func _S(surface: String) -> Surf:
	var key := _tgt + "/" + surface
	if not _bufs.has(key):
		_bufs[key] = Surf.new()
	return _bufs[key]


# --- primitive arrays --------------------------------------------------------------------------------------------

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


func _box(size: Vector3) -> Array:
	var m := BoxMesh.new()
	m.size = size
	return m.get_mesh_arrays()


## A closed loft through rings of equal vertex count (normals point away from each ring's centroid).
func _loft(rings: Array, cap_first: bool = true, cap_last: bool = true, apex_last: Variant = null) -> Array:
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
	var caps: Array = []
	if cap_first:
		caps.append([0, null])
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


## A ring of `m` points of radius (rx, rz) around `c` at height y, wobbled by `wob` (seeded).
func _ring(c: Vector3, rx: float, rz: float, y: float, m: int, wob: float, seed: float, rot: float = 0.0) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i: int in m:
		var a: float = rot + TAU * float(i) / float(m)
		var j: float = 1.0 + (_h(Vector3(seed, float(i), 3.3)) - 0.5) * 2.0 * wob
		out.append(Vector3(c.x + cos(a) * rx * j, y, c.z + sin(a) * rz * j))
	return out


## A tube through `pts` with per-point radii (a radius of 0 closes to a point), `sides` around.
func _tube(pts: PackedVector3Array, radii: PackedFloat32Array, sides: int, cap0: bool = true, cap1: bool = true) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var cnt: int = pts.size()
	var ts: Array[Vector3] = []
	for i: int in cnt:
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, cnt - 1)]
		ts.append((b - a).normalized())
	var x: Vector3 = ts[0].cross(Vector3.UP if absf(ts[0].y) < 0.9 else Vector3.RIGHT).normalized()
	var rings: Array = []
	var norms: Array = []
	for i: int in cnt:
		var t: Vector3 = ts[i]
		x = (x - t * x.dot(t)).normalized()
		var y: Vector3 = t.cross(x)
		var ring := PackedVector3Array()
		var nr := PackedVector3Array()
		for k: int in sides:
			var a2: float = TAU * float(k) / float(sides)
			var d: Vector3 = x * cos(a2) + y * sin(a2)
			ring.append(pts[i] + d * radii[i])
			nr.append(d)
		rings.append(ring)
		norms.append(nr)
	for i: int in cnt - 1:
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		var n0: PackedVector3Array = norms[i]
		var n1: PackedVector3Array = norms[i + 1]
		for k: int in sides:
			var j: int = (k + 1) % sides
			var base: int = v.size()
			v.append_array([r0[k], r0[j], r1[j], r1[k]])
			n.append_array([n0[k], n0[j], n1[j], n1[k]])
			idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	for e: Array in [[0, cap0, -ts[0]], [cnt - 1, cap1, ts[cnt - 1]]]:
		if not e[1] or radii[e[0]] <= 0.0005:
			continue
		var ring2: PackedVector3Array = rings[e[0]]
		var base2: int = v.size()
		v.append(pts[e[0]])
		n.append(e[2])
		for k: int in sides:
			v.append(ring2[k])
			n.append(e[2])
		for k: int in sides:
			idx.append_array([base2, base2 + 1 + k, base2 + 1 + (k + 1) % sides])
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


# --- the part appender ------------------------------------------------------------------------------------------

## Adds mesh arrays transformed by `xf` to the current target. Options: surf ("painted" | "glow"), kind (Kind),
## jitter (m), seed, normals ("flat" | "smooth"), col2 + grad ("y" | "r"), moss (stone UV.x), wind (m: foliage
## wind weight = height / wind), tint (per-face value variation), lift (added to UV.y, softens the contact band),
## glo (gradient at the part's bottom, -1 = auto), w (glow energy weight), phase (glow COLOR.a).
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var surf: String = o.get("surf", "painted")
	var kind: int = o.get("kind", Kind.STONE)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var mode: String = o.get("normals", "flat")
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var moss: float = o.get("moss", 0.0)
	var wind: float = o.get("wind", 0.0)
	var tint: float = o.get("tint", 0.08)
	var lift: float = o.get("lift", 0.0)
	var glo: float = o.get("glo", -1.0)
	var gw: float = o.get("w", 1.0)
	var phase: float = o.get("phase", _h(xf.origin.snappedf(0.01)))
	var nb: Basis = xf.basis.inverse().transposed()
	var sminy: float = INF
	var smaxy: float = -INF
	var maxr: float = 0.001
	for p: Vector3 in v:
		sminy = minf(sminy, p.y)
		smaxy = maxf(smaxy, p.y)
		maxr = maxf(maxr, Vector2(p.x, p.z).length())
	var tv := PackedVector3Array()
	var tn := PackedVector3Array()
	tv.resize(v.size())
	tn.resize(v.size())
	var miny: float = INF
	var maxy: float = -INF
	for i: int in v.size():
		var p: Vector3 = v[i]
		if jitter > 0.0:
			p += _h3(v[i].snappedf(0.001) + Vector3(seed, seed * 0.7, seed * 1.3)) * jitter
		tv[i] = xf * p
		tn[i] = (nb * n[i]).normalized()
		miny = minf(miny, tv[i].y)
		maxy = maxf(maxy, tv[i].y)
	var span: float = maxf(maxy - miny, 0.01)
	if glo < 0.0:
		glo = clampf(0.55 - span * 0.35, 0.05, 0.5)
	var s_out: Surf = _S(surf)
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
				gt = clampf((v[vi].y - sminy) / maxf(smaxy - sminy, 0.001), 0.0, 1.0)
			else:
				gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
			var cc: Color = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			s_out.v.append(tv[vi])
			s_out.n.append(nn)
			if surf == "glow":
				s_out.c.append(Color(cc.r, cc.g, cc.b, phase))
				s_out.uv.append(Vector2(gw, tv[vi].y))
				s_out.uv2.append(Vector2.ZERO)
			else:
				var ga: float = lerpf(glo, 1.0, clampf((tv[vi].y - miny) / span, 0.0, 1.0))
				s_out.c.append(Color(cc.r * k, cc.g * k, cc.b * k, ga))
				var ux: float = moss
				if kind != Kind.STONE:
					ux = clampf(tv[vi].y / wind, 0.0, 1.0) if wind > 0.0 else 0.0
				s_out.uv.append(Vector2(ux, tv[vi].y + lift))
				s_out.uv2.append(Vector2(0.0, kind))


func _stone(arr: Array, xf: Transform3D, col: Color, seed: float, moss: float = 0.5, o: Dictionary = {}) -> void:
	var oo: Dictionary = o.duplicate()
	oo["kind"] = Kind.STONE
	oo["moss"] = moss
	oo["seed"] = seed
	if not oo.has("jitter"):
		oo["jitter"] = 0.02
	_part(arr, xf, col, oo)


## A limb (tapered cylinder, smooth) from a to b.
func _limb(a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Color, o: Dictionary = {}) -> void:
	var oo: Dictionary = o.duplicate()
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	if not oo.has("kind"):
		oo["kind"] = Kind.BARK
	_part(_cyl(r1, r0, a.distance_to(b), segs), Transform3D(_along(a, b), (a + b) * 0.5), col, oo)


## A curved tube through `pts` with radii, smooth shaded.
func _curve(pts: PackedVector3Array, radii: PackedFloat32Array, sides: int, col: Color, o: Dictionary = {}) -> void:
	var oo: Dictionary = o.duplicate()
	if not oo.has("normals"):
		oo["normals"] = "smooth"
	if not oo.has("kind"):
		oo["kind"] = Kind.BARK
	_part(_tube(pts, radii, sides), Transform3D.IDENTITY, col, oo)


## Soft contact shadow disc (nature_contact_mat) just above the ground (or the ford film).
func _disc(c: Vector3, rx: float, rz: float, segs: int, seed: float, rot: float = 0.0, y: float = 0.035) -> void:
	var s: Surf = _S("contact")
	var ring: Array[Vector3] = []
	var b := Basis(Vector3.UP, rot)
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.3
		ring.append(Vector3(c.x, y, c.z) + b * Vector3(cos(a) * rx * j, 0.0, sin(a) * rz * j))
	var centre := Vector3(c.x, y, c.z)
	for i: int in segs:
		var p1: Vector3 = ring[i]
		var p2: Vector3 = ring[(i + 1) % segs]
		var fn: Vector3 = (p1 - centre).cross(p2 - centre)
		var up: bool = fn.y >= 0.0
		var tri: Array = [centre, p1, p2] if (1.0 if up else -1.0) == _conv else [centre, p2, p1]
		var uvs: Array = [0.0, 1.0, 1.0]
		for k: int in 3:
			s.v.append(tri[k])
			s.n.append(Vector3.UP)
			s.uv.append(Vector2(uvs[k], 0.0))
			s.uv2.append(Vector2.ZERO)


## One grass / reed / fern blade: a 3-sided tapering tube from `foot` along a bent curve.
func _blade(foot: Vector3, dir: Vector3, h: float, r: float, bend: float, col: Color, col2: Color, kind: int,
		wind: float, segs: int = 3) -> void:
	var d: Vector3 = dir.normalized()
	var side: Vector3 = d.cross(Vector3.UP)
	if side.length_squared() < 1e-4:
		side = Vector3.RIGHT
	var out: Vector3 = Vector3.UP.cross(side).normalized()   # horizontal bend direction
	if out.dot(Vector3(d.x, 0.0, d.z)) < 0.0:
		out = -out
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i: int in segs + 1:
		var u: float = float(i) / float(segs)
		pts.append(foot + d * h * u + out * bend * u * u)
		radii.append(r * (1.0 - u) + 0.0)
	_part(_tube(pts, radii, 3, false, false), Transform3D.IDENTITY, col, {"kind": kind, "col2": col2, "wind": wind,
		"normals": "smooth", "tint": 0.12, "glo": 0.35})


# --- commit ------------------------------------------------------------------------------------------------------

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


## Saves meshes/<name>_<target>.res for every target with geometry. Returns {target: [mesh, params]}.
func _commit(name: String) -> Dictionary:
	var out := {}
	for tgt: String in TARGETS:
		var mesh := ArrayMesh.new()
		var params := PackedStringArray()
		var info := ""
		var tris := 0
		for surf: String in SURFACES:
			var key := tgt + "/" + surf
			if not _bufs.has(key):
				continue
			var s: Surf = _bufs[key]
			if s.v.is_empty():
				continue
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = s.v
			arrays[Mesh.ARRAY_NORMAL] = s.n
			if not s.c.is_empty():
				arrays[Mesh.ARRAY_COLOR] = s.c
			if not s.uv.is_empty():
				arrays[Mesh.ARRAY_TEX_UV] = s.uv
			if not s.uv2.is_empty():
				arrays[Mesh.ARRAY_TEX_UV2] = s.uv2
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _weld(arrays))
			mesh.surface_set_material(mesh.get_surface_count() - 1, mats[surf])
			info += " %s %d" % [surf, s.v.size() / 3]
			tris += s.v.size() / 3
			if surf == "glow":
				params.append("lit")
			elif surf == "mud":
				params.append("wet")
		if mesh.get_surface_count() == 0:
			continue
		var aabb: AABB = mesh.get_aabb()
		mesh = _save_ref(mesh, MESH_DIR + "%s_%s.res" % [name, tgt]) as ArrayMesh
		out[tgt] = [mesh, params]
		_report.append("mesh %-12s %-7s %5d tris:%s | size %.1f x %.1f x %.1f" % [name, tgt, tris, info,
			aabb.size.x, aabb.size.y, aabb.size.z])
	_bufs.clear()
	_tgt = "base"
	return out


## The painted trodden ground patch, baked to meshes/<name>_ground.res. A FILLED disc (radius `radius`, wobbled, a
## tongue `door_len` m longer toward `door`) in the MAP.P2 SiteGround mesh contract so it uses the shared
## site_ground_mat.tres: UV.x 0 at the centre -> 1 at the rim (the shader's ragged dirt edge sits at ~0.8), UV.y =
## metres from the "contact line" (dark baked shadow where it is ~0): `band_r` > 0 draws that dark band on the circle
## of radius band_r (the fairy ring), `pit_r` > 0 hugs the rim of a pit of that radius (the wallow); else none.
## COLOR = dirt tint (x2 in the shader) + strength.
func _ground(name: String, radius: float, door: Vector3, door_len: float, seed_i: int, strength: float, tint: Color,
		band_r: float = 0.0, pit_r: float = 0.0) -> Mesh:
	var fr: Array[float] = [0.0, 0.18, 0.36, 0.52, 0.64, 0.74, 0.8, 0.86, 0.93, 1.0]
	var segs := 36
	var w0: float = _h(Vector3(seed_i, 1, 1)) * TAU
	var w1: float = _h(Vector3(seed_i, 2, 1)) * TAU
	var dd := Vector2(door.x, door.z)
	if dd.length() > 0.01:
		dd = dd.normalized()
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var norms := PackedVector3Array()
	var col := Color(tint.r, tint.g, tint.b, strength)
	for k: int in fr.size():
		for i: int in segs:
			var a: float = TAU * float(i) / float(segs)
			var dir := Vector2(cos(a), sin(a))
			var r: float = radius * (1.0 + 0.12 * sin(a * 3.0 + w0) + 0.07 * sin(a * 5.0 + w1))
			if door_len > 0.0 and dd != Vector2.ZERO:
				r += door_len * pow(maxf(dir.dot(dd), 0.0), 10.0)
			var p: Vector2 = dir * r * fr[k]
			verts.append(Vector3(p.x, 0.0, p.y))
			var d: float = p.length()
			var uy: float = 6.0
			if band_r > 0.0:
				uy = absf(d - band_r) * 1.4
			elif pit_r > 0.0:
				uy = maxf(d - pit_r, 0.0)
			uvs.append(Vector2(fr[k], uy))
			cols.append(col)
			norms.append(Vector3.UP)
	var idx := PackedInt32Array()
	for k: int in fr.size() - 1:
		for i: int in segs:
			var j: int = (i + 1) % segs
			var a: int = k * segs + i
			var b: int = k * segs + j
			var c: int = (k + 1) * segs + i
			var d2: int = (k + 1) * segs + j
			for tri: Array in [[a, c, b], [b, c, d2]]:
				var fn: Vector3 = (verts[tri[1]] - verts[tri[0]]).cross(verts[tri[2]] - verts[tri[0]])
				if fn.length_squared() < 1e-12:
					continue
				if (1.0 if fn.y >= 0.0 else -1.0) == _conv:
					idx.append_array([tri[0], tri[1], tri[2]])
				else:
					idx.append_array([tri[0], tri[2], tri[1]])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _save_ref(m, MESH_DIR + "%s_ground.res" % name) as Mesh


func _own(n: Node, root: Node) -> void:
	for ch: Node in n.get_children():
		ch.owner = root
		_own(ch, root)


## camps/<kind>_site.tscn: root (camp_site.gd, group "camp_sites") > Ground, Base, Active, Cleared.
func _scene(kind: StringName, root_name: String, meshes: Dictionary, ground: Mesh, clear_r: float,
		shadow: Dictionary) -> void:
	var root := Node3D.new()
	root.name = root_name
	root.set_script(load(CDIR + "camp_site.gd"))
	root.set(&"kind", kind)
	root.add_to_group(&"camp_sites", true)
	root.set_meta(&"decor_clear_radius", clear_r)
	if ground:
		var g := MeshInstance3D.new()
		g.name = "Ground"
		g.mesh = ground
		g.material_override = load(SITE_GROUND_MAT) as Material
		g.position = Vector3(0.0, 0.028, 0.0)
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		g.visibility_range_end = 150.0
		root.add_child(g)
	var names := {"base": "Base", "active": "Active", "cleared": "Cleared"}
	for tgt: String in TARGETS:
		if not meshes.has(tgt):
			continue
		var mi := MeshInstance3D.new()
		mi.name = names[tgt]
		mi.mesh = meshes[tgt][0]
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(shadow.get(tgt, false)) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 150.0 if tgt == "base" else 120.0
		var params: PackedStringArray = meshes[tgt][1]
		if not params.is_empty():
			mi.set_meta(&"camp_params", params)
		if tgt == "cleared":
			mi.visible = false
		root.add_child(mi)
	_own(root, root)
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	if err != OK:
		push_error("pack failed %s" % kind)
	_save(ps, CDIR + "%s_site.tscn" % kind)
	root.free()


# =================================================================================================================
# Bristleback Wallow (T1). Local -Z faces the map centre; the two boars stand at (0, 0, -1.5) and (0, 0, 2.0).
# A wide oval mud pit in the middle (camp_mud_mat: glossy puddle that dries into cracked plates when cleared) with a
# ring of churned clods (open toward the centre, where the hoof trail comes in), the ribcage and horned skull of an
# old kill on the east side, two tusk-gnawed logs and wood chips on the west, and the dominant vertical: a dead,
# bark-stripped rubbing snag at the back, polished pale on top and mud-caked to knee height.
# =================================================================================================================

func _pit_r(a: float) -> float:
	return 1.0 + 0.10 * sin(a * 3.0 + 0.7) + 0.06 * sin(a * 5.0 + 2.1)


func _build_wallow() -> void:
	_rng.seed = 24001
	_tgt = "base"
	var c := Vector3(0.1, 0.0, 0.15)
	var rx := 2.15
	var rz := 1.95
	# Mud pit: polar rings, inner rings shifted toward the puddle.
	var fr: Array[float] = [0.0, 0.22, 0.45, 0.66, 0.82, 0.93, 1.0, 1.1]
	var hy: Array[float] = [0.028, 0.03, 0.034, 0.042, 0.06, 0.085, 0.095, 0.004]
	var wt: Array[float] = [1.0, 0.9, 0.74, 0.52, 0.4, 0.3, 0.22, 0.05]
	var puddle_off := Vector3(0.35, 0.0, -0.25)
	var segs := 30
	var mud: Surf = _S("mud")
	var grid: Array = []
	for k: int in fr.size():
		var row: Array = []
		for i: int in segs:
			var a: float = TAU * float(i) / float(segs)
			var r: float = _pit_r(a) * fr[k]
			var cc: Vector3 = c + puddle_off * (1.0 - fr[k])
			var jit: float = (_h(Vector3(k, i, 1.7)) - 0.5) * 0.08 * fr[k]
			row.append(Vector3(cc.x + cos(a) * rx * (r + jit), hy[k], cc.z + sin(a) * rz * (r + jit)))
		grid.append(row)
	for k: int in fr.size() - 1:
		for i: int in segs:
			var j: int = (i + 1) % segs
			var quad: Array = [[k, i], [k, j], [k + 1, j], [k + 1, i]]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var pa: Vector3 = grid[quad[tri[0]][0]][quad[tri[0]][1]]
				var pb: Vector3 = grid[quad[tri[1]][0]][quad[tri[1]][1]]
				var pc: Vector3 = grid[quad[tri[2]][0]][quad[tri[2]][1]]
				var ka: int = quad[tri[0]][0]
				var kb: int = quad[tri[1]][0]
				var kc: int = quad[tri[2]][0]
				var fn: Vector3 = (pb - pa).cross(pc - pa)
				if fn.length_squared() < 1e-12:
					continue
				fn = fn.normalized()
				var verts: Array = [[pa, ka], [pb, kb], [pc, kc]]
				if (1.0 if fn.y >= 0.0 else -1.0) != _conv:
					verts = [[pa, ka], [pc, kc], [pb, kb]]
				if fn.y < 0.0:
					fn = -fn
				for vv: Array in verts:
					var p: Vector3 = vv[0]
					var kk: int = vv[1]
					mud.v.append(p)
					mud.n.append(fn)
					var mc: Color = MUD_WET.lerp(MUD, clampf(fr[kk] * 1.1 - 0.1, 0.0, 1.0))
					mud.c.append(mc)
					mud.uv.append(Vector2(wt[kk], p.y))
	# Churned clods around the rim, open toward -Z (the trail) and a gap at +Z (the back boar wades in).
	var n_clods := 26
	for i: int in n_clods:
		var a: float = TAU * float(i) / float(n_clods) + _rng.randf_range(-0.08, 0.08)
		var dz: float = sin(a)
		if dz < -0.8 or (dz > 0.93):
			continue
		var r: float = _pit_r(a) * _rng.randf_range(0.98, 1.1)
		var p := Vector3(c.x + cos(a) * rx * r, 0.0, c.z + sin(a) * rz * r)
		var rad: float = _rng.randf_range(0.17, 0.33)
		var col: Color = MUD_WET.lerp(MUD, _rng.randf())
		_stone(_chunk(Vector3(rad * 1.25, rad * 0.55, rad), 4, 30.0 + i), _xf(p + Vector3(0, rad * 0.08, 0),
			Vector3(0, _rng.randf() * TAU, 0)), col, 30.0 + i, 0.3 if _rng.randf() < 0.3 else 0.0,
			{"col2": MUD, "lift": 0.12})
		if _rng.randf() < 0.45:   # a second, smaller clod thrown further out
			var p2: Vector3 = p + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.35, 0.7)
			var r2: float = rad * 0.55
			_stone(_chunk(Vector3(r2 * 1.2, r2 * 0.5, r2), 4, 60.0 + i), _xf(p2, Vector3(0, _rng.randf() * TAU, 0)),
				MUD, 60.0 + i, 0.0, {"lift": 0.15})
	# Mud splats on the grass beyond the rim.
	for i: int in 9:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(2.6, 3.6)
		var p := Vector3(c.x + cos(a) * r, 0.0, c.z + sin(a) * r * 0.95)
		if p.z > 2.3:
			p.z = 2.3 - (p.z - 2.3)
		var s: float = _rng.randf_range(0.18, 0.34)
		_stone(_chunk(Vector3(s, 0.05, s * 0.7), 3, 90.0 + i, 0.6), _xf(p + Vector3(0, 0.01, 0),
			Vector3(0, _rng.randf() * TAU, 0)), MUD, 90.0 + i, 0.0, {"lift": 0.3})
	# --- The old kill (east): ribcage + skull + scattered long bones.
	var rib_c := Vector3(3.55, 0.0, -0.1)
	var rib_b := Basis(Vector3.UP, 0.55) * Basis(Vector3.RIGHT, 0.12)   # lying a little on its side
	var spine_a: Vector3 = rib_c + rib_b * Vector3(-0.85, 0.14, 0.0)
	var spine_b: Vector3 = rib_c + rib_b * Vector3(0.85, 0.1, 0.0)
	_curve(PackedVector3Array([spine_a, (spine_a + spine_b) * 0.5 + Vector3(0, 0.05, 0), spine_b]),
		PackedFloat32Array([0.07, 0.08, 0.05]), 5, BONE_D, {"kind": Kind.STONE, "col2": BONE, "lift": 0.2})
	for k: int in 7:   # vertebra knobs
		var u: float = float(k) / 6.0
		var q: Vector3 = spine_a.lerp(spine_b, u) + Vector3(0, 0.08, 0)
		_stone(_box(Vector3(0.12, 0.1, 0.14)), Transform3D(rib_b, q), BONE, 120.0 + k, 0.0, {"lift": 0.3})
	for k: int in 6:
		var x: float = -0.6 + 1.2 * float(k) / 5.0
		var hh: float = 0.72 - absf(x) * 0.35
		for side: float in [-1.0, 1.0]:
			if k == 5 and side > 0.0:
				continue   # one rib broken off
			var pts := PackedVector3Array()
			var sink: float = 0.0 if side < 0.0 else -0.12
			for q: Vector3 in [Vector3(x, 0.14, 0.0), Vector3(x + 0.05, hh, side * 0.32), Vector3(x + 0.1, hh * 0.78,
					side * 0.62), Vector3(x + 0.13, 0.05 + sink, side * 0.72)]:
				pts.append(rib_c + rib_b * q)
			_curve(pts, PackedFloat32Array([0.055, 0.05, 0.042, 0.03]), 5, BONE, {"kind": Kind.STONE, "col2": BONE,
				"lift": 0.25})
	_disc(rib_c, 1.1, 0.8, 10, 3.0, 0.55)
	# Skull: a long boar-like skull with upcurved tusks and dark sockets, jaw fallen beside it.
	var sk := Vector3(2.3, 0.0, 1.75)
	var skb := Basis(Vector3.UP, -0.9)
	_stone(_chunk(Vector3(0.34, 0.24, 0.26), 5, 140.0, 0.8), Transform3D(skb, sk + Vector3(0, 0.18, 0)), BONE, 140.0,
		0.0, {"col2": BONE, "lift": 0.2})
	_stone(_chunk(Vector3(0.3, 0.14, 0.15), 4, 141.0, 0.8), Transform3D(skb, sk + skb * Vector3(0.42, 0.12, 0.0)),
		BONE, 141.0, 0.0, {"lift": 0.25})
	for side: float in [-1.0, 1.0]:
		_stone(_sph(0.075, 6, 3), Transform3D(skb, sk + skb * Vector3(0.12, 0.3, side * 0.17)), SOCKET, 142.0, 0.0,
			{"lift": 0.3, "tint": 0.0})
		var tp := PackedVector3Array()
		for q: Vector3 in [Vector3(0.5, 0.1, side * 0.12), Vector3(0.62, 0.2, side * 0.24), Vector3(0.62, 0.42,
				side * 0.32), Vector3(0.5, 0.56, side * 0.3)]:
			tp.append(sk + skb * q)
		_curve(tp, PackedFloat32Array([0.06, 0.05, 0.035, 0.0]), 5, BONE, {"kind": Kind.STONE, "col2": Color(1, 0.98,
			0.9), "lift": 0.3})
	_stone(_chunk(Vector3(0.32, 0.07, 0.12), 4, 143.0, 0.7), _xf(sk + Vector3(-0.35, 0.05, 0.45), Vector3(0, 0.4, 0.1)),
		BONE_D, 143.0, 0.0, {"lift": 0.25})
	_disc(sk, 0.55, 0.45, 8, 4.0)
	for bd: Array in [[Vector3(0.9, 0, 2.55), 0.3], [Vector3(3.1, 0, -1.9), -0.9], [Vector3(1.4, 0, -3.1), 1.9],
			[Vector3(-1.1, 0, -3.0), 0.8]]:
		var bp: Vector3 = bd[0]
		var yaw: float = bd[1]
		var bb := Basis(Vector3.UP, yaw)
		_limb(bp + bb * Vector3(-0.32, 0.05, 0), bp + bb * Vector3(0.32, 0.05, 0), 0.04, 0.04, 5, BONE,
			{"kind": Kind.STONE, "lift": 0.3})
		for e: float in [-0.34, 0.34]:
			_stone(_sph(0.075, 5, 3), _xf(bp + bb * Vector3(e, 0.06, 0), Vector3.ZERO, Vector3(1.0, 0.8, 1.3)), BONE,
				150.0 + e, 0.0, {"lift": 0.3})
	# --- Gnawed logs (west).
	var la := Vector3(-3.75, 0.24, -0.55)
	var lb := Vector3(-2.55, 0.26, 1.45)
	_limb(la, lb, 0.26, 0.24, 7, BARK, {"col2": BARK_D, "jitter": 0.02, "seed": 5.0})
	_part(_cyl(0.26, 0.26, 0.02, 7), Transform3D(_along(lb, la), la + (la - lb).normalized() * 0.005), WOOD_IN,
		{"kind": Kind.BARK, "tint": 0.0})
	# The chewed end: a pale cone of torn wood with a waist bitten out of it.
	var dirl: Vector3 = (lb - la).normalized()
	var cp := PackedVector3Array([lb, lb + dirl * 0.18 + Vector3(0, -0.02, 0), lb + dirl * 0.34, lb + dirl * 0.5])
	_curve(cp, PackedFloat32Array([0.24, 0.13, 0.16, 0.0]), 7, WOOD_IN, {"col2": WOOD_IN, "normals": "flat",
		"jitter": 0.02, "seed": 7.0})
	for k: int in 4:   # tusk gouges along the top
		var u: float = 0.2 + 0.18 * k
		var p: Vector3 = la.lerp(lb, u) + Vector3(0, 0.24, 0)
		_part(_box(Vector3(0.05, 0.03, 0.36)), Transform3D(_along(la, lb).rotated(dirl, 0.2 * (k - 1.5)) *
			Basis(Vector3.RIGHT, PI * 0.5), p), WOOD_IN, {"kind": Kind.BARK, "tint": 0.05})
	_disc((la + lb) * 0.5, 1.5, 0.5, 10, 5.0, -atan2(lb.z - la.z, lb.x - la.x))
	# Second log, snapped: splintered end.
	var lc := Vector3(-4.3, 0.2, 1.2)
	var ld := Vector3(-3.3, 0.2, 2.2)
	_limb(lc, ld, 0.21, 0.2, 7, BARK_D, {"col2": BARK, "jitter": 0.02, "seed": 9.0})
	var dir2: Vector3 = (ld - lc).normalized()
	for k: int in 5:
		var a: float = TAU * float(k) / 5.0
		var off: Vector3 = _along(lc, ld) * Vector3(cos(a) * 0.12, 0.0, sin(a) * 0.12)
		_curve(PackedVector3Array([ld + off, ld + off * 0.8 + dir2 * _rng.randf_range(0.15, 0.32)]),
			PackedFloat32Array([0.06, 0.0]), 4, WOOD_IN, {"normals": "flat"})
	_disc((lc + ld) * 0.5, 1.0, 0.45, 9, 6.0, -atan2(ld.z - lc.z, ld.x - lc.x))
	for i: int in 10:   # wood chips
		var p := Vector3(_rng.randf_range(-3.4, -1.9), 0.02, _rng.randf_range(-0.2, 2.2))
		_part(_box(Vector3(0.12, 0.03, 0.06)), _xf(p, Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf() * TAU, 0)),
			WOOD_IN, {"kind": Kind.BARK, "lift": 0.3, "tint": 0.15})
	# --- The rubbing snag (the silhouette's vertical): dead trunk, leaning, bark stripped and polished pale above,
	# caked in mud below, two broken branch stubs, root flares.
	var sf := Vector3(-2.75, 0.0, -2.0)
	var st := sf + Vector3(0.3, 1.95, -0.22)
	var sm: Vector3 = sf.lerp(st, 0.5) + Vector3(-0.08, 0.0, 0.05)
	_curve(PackedVector3Array([sf + Vector3(0, -0.1, 0), sf.lerp(sm, 0.4), sm, st]),
		PackedFloat32Array([0.3, 0.25, 0.2, 0.12]), 7, MUD, {"col2": WOOD_GREY, "jitter": 0.015, "seed": 11.0})
	_part(_cyl(0.0, 0.12, 0.22, 7), Transform3D(_along(sm, st), st + (st - sm).normalized() * 0.1), WOOD_GREY,
		{"kind": Kind.BARK, "normals": "flat", "jitter": 0.03, "seed": 12.0})
	for br: Array in [[0.62, Vector3(0.45, 0.3, -0.2)], [0.8, Vector3(-0.35, 0.2, 0.25)]]:
		var bp: Vector3 = sf.lerp(st, float(br[0]))
		_limb(bp, bp + (br[1] as Vector3), 0.07, 0.035, 5, WOOD_GREY)
	for k: int in 4:
		var a: float = TAU * float(k) / 4.0 + 0.5
		var d := Vector3(cos(a), 0, sin(a))
		_curve(PackedVector3Array([sf + Vector3(0, 0.25, 0) + d * 0.1, sf + d * 0.45 + Vector3(0, 0.06, 0),
			sf + d * 0.7 + Vector3(0, -0.04, 0)]), PackedFloat32Array([0.12, 0.08, 0.03]), 5, MUD,
			{"col2": BARK_D, "grad": "y"})
	_disc(sf, 0.75, 0.7, 9, 12.0)
	# Dry heath tufts and a few stones at the edge of the clearing.
	for i: int in 11:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(3.4, 4.4)
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		if p.distance_to(rib_c) < 1.3 or p.distance_to(sf) < 0.8 or p.distance_to((la + lb) * 0.5) < 1.2 or p.z > 2.5:
			continue
		for b: int in 7:
			var d := Vector3(_rng.randf_range(-0.45, 0.45), 1.0, _rng.randf_range(-0.45, 0.45))
			_blade(p + Vector3(_rng.randf_range(-0.12, 0.12), 0, _rng.randf_range(-0.12, 0.12)), d,
				_rng.randf_range(0.32, 0.55), 0.035, 0.08, HEATH, DRY_GRASS, Kind.IVY, 0.6)
	for i: int in 4:
		var a: float = -0.3 - i * 1.05
		var p := Vector3(cos(a) * 4.1, 0, sin(a) * 4.0)
		var s: float = _rng.randf_range(0.2, 0.32)
		_stone(_chunk(Vector3(s, s * 0.7, s * 0.85), 5, 200.0 + i), _xf(p, Vector3(0, a, 0)), STONE, 200.0 + i, 0.5,
			{"col2": STONE})
		_disc(p, s * 1.6, s * 1.4, 7, 200.0 + i)
	var meshes := _commit("bristleback")
	var ground := _ground("bristleback", 4.2, Vector3(0, 0, -1), 2.2, 11, 1.0, Color(0.40, 0.35, 0.29), 0.0, 2.05)
	_scene(&"bristleback", "BristlebackWallow", meshes, ground, 4.6, {"base": true})


# =================================================================================================================
# Ford Nest (T2, Mirefangs) in Reed Ford / Willow Ford. Origin = the ford centre on the film (y 0), local +Z
# downstream, X across the 5 m channel (ford_stones.tscn: stepping stones at z ~ -1.85, the middle r 1.6 left free).
# Three woven reed-and-mud nest mounds (the big one in the middle), a cup in each with amber eggs (glow, Active),
# reed beds at both channel edges (Active: upright and swaying; Cleared: flattened outward, broken, yellowed), lily
# pads. Cleared: smashed shells in the cups, torn strands on the film.
# =================================================================================================================

## A nest mound: the outer woven wall up to the rim (`inner` false), or the cup inside it (`inner` true: normals
## turned inward so the cup walls and floor face up / in).
func _mound(c: Vector3, r: float, h: float, seed: float, inner: bool = false) -> Array:
	var rings: Array = []
	var prof: Array = [[1.22, -0.02], [1.08, 0.06], [0.98, 0.3], [0.82, 0.72], [0.64, 1.0]]
	if inner:
		prof = [[0.64, 1.0], [0.5, 0.94], [0.34, 0.72]]
	for k: int in prof.size():
		var pr: Array = prof[k]
		var kk: int = k + (4 if inner else 0)
		rings.append(_ring(c + Vector3(0, float(pr[1]) * h, 0), r * float(pr[0]), r * float(pr[0]) * 0.92,
			c.y + float(pr[1]) * h, 11, 0.07, seed + kk * 0.37))
	var arr: Array = _loft(rings, false, inner)
	if inner:
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		for i: int in n.size():
			n[i] = -n[i]
		arr[Mesh.ARRAY_NORMAL] = n
	return arr


func _build_nest() -> void:
	_rng.seed = 24002
	_tgt = "base"
	var mounds: Array = [[Vector3(0.15, 0.0, 0.4), 0.95, 0.5, 4], [Vector3(-1.1, 0.0, -0.45), 0.58, 0.34, 2],
		[Vector3(1.08, 0.0, -0.52), 0.55, 0.33, 3]]
	var mi: int = 0
	for md: Array in mounds:
		var c: Vector3 = md[0]
		var r: float = md[1]
		var h: float = md[2]
		_part(_mound(c, r, h, 20.0 + mi), Transform3D.IDENTITY, NEST_MUD, {"kind": Kind.BARK, "col2": NEST,
			"jitter": 0.025, "seed": 20.0 + mi, "glo": 0.3, "lift": 0.1})
		_part(_mound(c, r, h, 20.0 + mi, true), Transform3D.IDENTITY, NEST_D, {"kind": Kind.BARK, "col2": NEST_D.darkened(0.3),
			"jitter": 0.025, "seed": 20.0 + mi, "glo": 0.5, "lift": 0.4})
		# Woven strands laid over the wall up to the rim.
		var ns: int = 12 if r > 0.6 else 8
		for k: int in ns:
			var a: float = TAU * float(k) / float(ns) + _rng.randf_range(-0.2, 0.2)
			var twist: float = _rng.randf_range(0.35, 0.7) * (1.0 if k % 2 == 0 else -1.0)
			var pts := PackedVector3Array()
			for u: float in [0.0, 0.35, 0.7, 1.0]:
				var aa: float = a + twist * u
				var rr: float = r * lerpf(1.18, 0.62, u)
				var yy: float = h * lerpf(0.02, 1.02, pow(u, 0.8)) + 0.03
				pts.append(c + Vector3(cos(aa) * rr, yy, sin(aa) * rr * 0.92))
			pts.append(c + Vector3(cos(a + twist) * r * 0.5, h * 1.0, sin(a + twist) * r * 0.46))
			_curve(pts, PackedFloat32Array([0.03, 0.035, 0.035, 0.03, 0.02]), 4,
				REED_DRY if k % 3 != 0 else NEST_D, {"normals": "flat", "tint": 0.15})
		_disc(c, r * 1.5, r * 1.4, 10, 20.0 + mi, 0.0, 0.045)
		# Eggs (Active, glow) / smashed shells (Cleared).
		var ne: int = md[3]
		for e: int in ne:
			var a: float = TAU * float(e) / float(ne) + 0.4 * mi
			var er: float = (0.0 if ne == 1 else r * 0.2)
			var ep: Vector3 = c + Vector3(cos(a) * er, h * 0.74 + 0.07, sin(a) * er)
			var tilt := Vector3(_rng.randf_range(-0.5, 0.5), a, _rng.randf_range(-0.5, 0.5))
			_tgt = "active"
			_part(_sph(0.095, 7, 4), _xf(ep, tilt, Vector3(1.0, 1.35, 1.0)), EGG_GLOW, {"surf": "glow", "w": 0.42,
				"normals": "smooth", "phase": _rng.randf()})
			_tgt = "cleared"
			# Shell: the lower half of the egg, a jagged rim, plus shards; a yolk smear.
			var sh: Array = _sph(0.085, 7, 4)
			var sv: PackedVector3Array = sh[Mesh.ARRAY_VERTEX]
			for vi: int in sv.size():
				var cut: float = 0.01 + 0.03 * _h(Vector3(vi, e, mi))
				if sv[vi].y > cut:
					var q: Vector3 = sv[vi]
					q.y = cut
					sv[vi] = q
			sh[Mesh.ARRAY_VERTEX] = sv
			_part(sh, _xf(ep + Vector3(0, -0.03, 0), tilt * Vector3(1.4, 1, 1.4), Vector3(1.0, 1.35, 1.0)), EGG_SHELL,
				{"kind": Kind.STONE, "lift": 0.3})
			for s: int in 2:
				var sa: float = _rng.randf() * TAU
				var sp: Vector3 = c + Vector3(cos(sa), 0, sin(sa)) * r * _rng.randf_range(0.9, 1.5) + Vector3(0, 0.035, 0)
				_part(_box(Vector3(0.1, 0.02, 0.07)), _xf(sp, Vector3(0, _rng.randf() * TAU, 0.2)), EGG_SHELL,
					{"kind": Kind.STONE, "lift": 0.35})
			_tgt = "base"
		_tgt = "cleared"
		_stone(_chunk(Vector3(r * 0.45, 0.02, r * 0.4), 3, 40.0 + mi, 0.5), _xf(c + Vector3(0, h * 0.74, 0)), YOLK,
			40.0 + mi, 0.0, {"lift": 0.35})
		_tgt = "base"
		mi += 1
	# Reed beds at the channel edges (and on the bank lips), upright (Active) / flattened (Cleared).
	var clumps: Array = [Vector3(-2.25, 0, 0.15), Vector3(-2.4, 0, 1.55), Vector3(-1.95, 0, 2.85), Vector3(2.3, 0, -0.55),
		Vector3(2.35, 0, 1.05), Vector3(2.0, 0, 2.6), Vector3(-2.35, 0, -2.95), Vector3(2.45, 0, -3.0),
		Vector3(-0.9, 0, 3.15)]
	var ci: int = 0
	for cc: Vector3 in clumps:
		var nb: int = 16 if ci < 6 else 11
		_disc(cc, 0.55, 0.5, 8, 50.0 + ci, 0.0, 0.045)
		for b: int in nb:
			var off := Vector3(_rng.randf_range(-0.38, 0.38), 0.0, _rng.randf_range(-0.38, 0.38))
			var foot: Vector3 = cc + off
			var h: float = _rng.randf_range(0.95, 1.55)
			var lean := Vector3(off.x * 0.6 + _rng.randf_range(-0.15, 0.15), 1.0, off.z * 0.6 + _rng.randf_range(-0.15, 0.15))
			var col: Color = REED.lerp(REED_D, _rng.randf() * 0.6)
			var cattail: bool = b % 5 == 0
			var r: float = _rng.randf_range(0.03, 0.045)
			_tgt = "active"
			_blade(foot, lean, h, r, _rng.randf_range(0.05, 0.25), col, REED_DRY if _rng.randf() < 0.3 else col.lightened(0.15),
				Kind.IVY, 1.6)
			if cattail:
				var top: Vector3 = foot + lean.normalized() * h * 0.82
				_part(_cyl(0.055, 0.055, 0.24, 6), Transform3D(_along(foot, top), top), CATTAIL, {"kind": Kind.BARK,
					"wind": 1.6, "normals": "smooth", "glo": 0.6})
			# Flattened: lying away from the nest (trampled in the fight), some snapped with a short stub left.
			_tgt = "cleared"
			var away: Vector3 = Vector3(foot.x, 0.0, foot.z).normalized()
			away = (away + Vector3(_rng.randf_range(-0.5, 0.5), 0.0, _rng.randf_range(-0.2, 0.6))).normalized()
			var el: float = _rng.randf_range(0.08, 0.3)
			var ldir: Vector3 = away * cos(el) + Vector3.UP * sin(el)
			var dry: Color = col.lerp(REED_DRY, 0.45)
			if _rng.randf() < 0.35:
				var stub: float = _rng.randf_range(0.18, 0.4)
				_blade(foot, lean, stub, r, 0.0, dry, dry, Kind.IVY, 0.0, 1)
				_blade(foot + lean.normalized() * stub + away * 0.05, ldir, h * 0.6, r * 0.8, -0.05, dry, REED_DRY,
					Kind.IVY, 0.0)
			else:
				_blade(foot, ldir, h * 0.9, r, -0.06, dry, REED_DRY, Kind.IVY, 0.0)
			if cattail:
				var tp: Vector3 = foot + ldir * h * 0.75
				_part(_cyl(0.055, 0.055, 0.24, 6), Transform3D(_along(foot, tp), tp), CATTAIL, {"kind": Kind.BARK,
					"normals": "smooth", "glo": 0.6})
			_tgt = "base"
		ci += 1
	# Lily pads on the film by the reeds (flat notched discs).
	for lp: Vector3 in [Vector3(-1.75, 0.03, 0.9), Vector3(-1.55, 0.03, 2.2), Vector3(1.75, 0.03, 0.2),
			Vector3(1.6, 0.03, 1.9), Vector3(-1.3, 0.03, 3.0), Vector3(0.9, 0.03, 2.7)]:
		var pr: float = _rng.randf_range(0.2, 0.3)
		var ring := PackedVector3Array()
		var notch: float = _rng.randf() * TAU
		for k: int in 10:
			var a: float = notch + TAU * (0.06 + 0.9 * float(k) / 9.0)
			ring.append(lp + Vector3(cos(a) * pr, 0.0, sin(a) * pr))
		ring.append(lp)
		var top := PackedVector3Array()
		for q: Vector3 in ring:
			top.append(q + Vector3(0, 0.02, 0))
		_part(_loft([ring, top], true, true), Transform3D.IDENTITY, LILY, {"kind": Kind.IVY, "lift": 0.4, "glo": 0.8})
	# Torn nest strands floating on the film (Cleared).
	_tgt = "cleared"
	for i: int in 9:
		var a: float = _rng.randf() * TAU
		var p := Vector3(cos(a), 0.0, sin(a)) * _rng.randf_range(0.9, 1.9) + Vector3(0, 0.04, 0.3)
		var d := Vector3(_rng.randf_range(-1, 1), 0.0, _rng.randf_range(-0.2, 1)).normalized()
		_curve(PackedVector3Array([p, p + d * 0.25 + Vector3(0, 0.01, 0), p + d * 0.5]), PackedFloat32Array([0.025,
			0.025, 0.015]), 4, REED_DRY, {"normals": "flat", "lift": 0.4})
	_tgt = "base"
	var meshes := _commit("mirefang")
	_scene(&"mirefang", "FordNest", meshes, null, 3.6, {"base": true})


# =================================================================================================================
# Gloomcap Hollow (T2) in the Old Wood nook. Local -Z faces the map centre (the nook's mouth between the Den and the
# Lodge); the Elder and the three sprouts stand on the ring r 1.5-2.0. A fairy ring r ~3.1 of blue-grey toadstools
# with teal glowing rims and a band of glowing spore moss on the ground (open at -Z), the Mother Cap (2.2 m, the
# vertical; Active: upright and glowing, Cleared: snapped, the cap lying on its side, grey), a rotten log with shelf
# fungus outside the ring, mossy stones and small mushroom clusters.
# =================================================================================================================

func _toadstool(foot: Vector3, h: float, cr: float, lean: Vector3, seed: float, glow_w: float, dead: bool = false,
		spot_glow: float = 0.0) -> void:
	var up: Vector3 = (Vector3.UP + lean).normalized()
	var top: Vector3 = foot + up * h
	var mid: Vector3 = foot.lerp(top, 0.5) + lean * h * 0.15
	var sr: float = maxf(cr * 0.22, 0.04)
	var ss: int = 7 if cr > 0.6 else 5
	var cs: int = 12 if cr > 0.6 else (9 if cr > 0.2 else 7)
	_curve(PackedVector3Array([foot + Vector3(0, -0.03, 0), foot + up * 0.08, mid, top]),
		PackedFloat32Array([sr * 1.5, sr * 1.35, sr, sr * 0.9]), ss, STALK_D, {"col2": STALK, "kind": Kind.STONE,
		"lift": 0.15})
	# Cap: underside -> rim -> dome.
	var b := _along(foot, top) if lean.length() > 0.01 else Basis.IDENTITY
	var prof: Array = [[0.3, -0.06], [1.0, 0.0], [0.9, 0.2], [0.6, 0.42], [0.22, 0.54]]
	var rings: Array = []
	for pr: Array in prof:
		var ring := PackedVector3Array()
		for k: int in cs:
			var a: float = TAU * float(k) / float(cs)
			var j: float = 1.0 + (_h(Vector3(seed, k, 5.0)) - 0.5) * 0.12
			ring.append(top + b * Vector3(cos(a) * cr * float(pr[0]) * j, cr * float(pr[1]), sin(a) * cr * float(pr[0]) * j))
		rings.append(ring)
	var capcol: Color = CAP_D.lerp(GILL_DEAD, 0.5) if dead else CAP
	_part(_loft(rings, true, true, top + b * Vector3(0, cr * 0.58, 0)), Transform3D.IDENTITY, capcol,
		{"kind": Kind.STONE, "col2": CAP_D if not dead else GILL_DEAD, "grad": "r", "normals": "smooth", "glo": 0.5,
		"lift": 0.4})
	# Pale spots on the dome.
	# Spots on the dome (sitting ON the surface: height from the profile at that radius). Glowing on the camp's
	# big caps (`spot_glow` > 0), pale elsewhere.
	var nsp: int = 3 + int(_h(Vector3(seed, 1, 1)) * 3.0) if cr > 0.2 else 2
	for k: int in nsp:
		var a: float = TAU * float(k) / float(nsp) + seed
		var f: float = 0.3 + 0.32 * _h(Vector3(seed, k, 2.0))
		var yy: float = lerpf(0.54, 0.42, clampf((f - 0.22) / 0.38, 0.0, 1.0)) if f > 0.22 else 0.54
		if f > 0.6:
			yy = lerpf(0.42, 0.2, (f - 0.6) / 0.3)
		var p: Vector3 = top + b * Vector3(cos(a) * cr * f, cr * yy + 0.005, sin(a) * cr * f)
		var s: float = cr * 0.13
		if spot_glow > 0.0 and not dead:
			_part(_sph(s, 6, 3), _xf(p, Vector3.ZERO, Vector3(1.0, 0.4, 1.0)), SPORE_GLOW, {"surf": "glow",
				"w": spot_glow, "normals": "smooth"})
		else:
			_part(_sph(s, 5, 2), _xf(p, Vector3.ZERO, Vector3(1.0, 0.35, 1.0)), SPOT if not dead else GILL_DEAD,
				{"kind": Kind.STONE, "lift": 0.5, "tint": 0.05})
	# Glowing gills: a band from under the cap edge to its lip (the camera sees it as a luminous edge).
	if glow_w > 0.0 and not dead:
		var r0 := PackedVector3Array()
		var r1 := PackedVector3Array()
		var r2 := PackedVector3Array()
		for k: int in cs:
			var a: float = TAU * float(k) / float(cs)
			var j: float = 1.0 + (_h(Vector3(seed, k, 5.0)) - 0.5) * 0.12
			r0.append(top + b * Vector3(cos(a) * cr * 1.02 * j, -0.005, sin(a) * cr * 1.02 * j))
			r1.append(top + b * Vector3(cos(a) * cr * 0.45, -cr * 0.07, sin(a) * cr * 0.45))
			r2.append(top + b * Vector3(cos(a) * cr * 1.05 * j, cr * 0.05 + 0.01, sin(a) * cr * 1.05 * j))
		_part(_loft([r0, r1], false, false), Transform3D.IDENTITY, SPORE_GLOW, {"surf": "glow", "w": glow_w,
			"normals": "smooth"})
		_part(_loft([r0, r2], false, false), Transform3D.IDENTITY, SPORE_GLOW, {"surf": "glow", "w": glow_w,
			"normals": "smooth"})
	if cr > 0.15:
		_disc(foot, cr * 1.2 + 0.1, cr * 1.1 + 0.1, 7, seed)


func _build_hollow() -> void:
	_rng.seed = 24003
	_tgt = "base"
	var ring_r := 3.15
	# Spore-moss band on the ground (dark pads) with glowing moss tufts along the ring.
	var n_pads := 40
	for i: int in n_pads:
		var a: float = TAU * float(i) / float(n_pads) + _rng.randf_range(-0.05, 0.05)
		if sin(a) < -0.9:
			continue   # the gap facing the nook mouth
		var r: float = ring_r + _rng.randf_range(-0.28, 0.28)
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var s: float = _rng.randf_range(0.2, 0.34)
		_stone(_chunk(Vector3(s, 0.05, s * 0.8), 3, 300.0 + i, 0.6, 5, 3), _xf(p + Vector3(0, 0.012, 0),
			Vector3(0, _rng.randf() * TAU, 0)), SPORE_MOSS, 300.0 + i, 0.0, {"lift": 0.35, "glo": 0.6})
		var gp: Vector3 = p + Vector3(_rng.randf_range(-0.1, 0.1), 0.045, _rng.randf_range(-0.1, 0.1))
		var gs: float = _rng.randf_range(0.09, 0.15)
		_part(_sph(gs, 5, 2), _xf(gp, Vector3(0, _rng.randf() * TAU, 0), Vector3(1.4, 0.6, 1.0)), SPORE_GLOW,
			{"surf": "glow", "w": 0.5, "normals": "smooth"})
	# The ring of toadstools (a gap toward -Z; the Mother Cap stands in it at the back).
	var n_caps := 14
	for i: int in n_caps:
		var a: float = TAU * float(i) / float(n_caps) + 0.2
		if sin(a) < -0.85:
			continue
		var r: float = ring_r + _rng.randf_range(-0.2, 0.2)
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		if p.distance_to(Vector3(-2.35, 0, 2.65)) < 1.1:
			continue   # the Mother Cap
		var big: bool = i % 3 == 0
		var h: float = _rng.randf_range(0.55, 0.85) if big else _rng.randf_range(0.28, 0.48)
		var cr: float = h * _rng.randf_range(0.55, 0.7)
		var lean := Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.05, 0.2)
		_toadstool(p, h, cr, lean, 400.0 + i, 0.9 if big else 0.7, false, 0.45 if big else 0.0)
		if _rng.randf() < 0.6:   # a little one beside it
			var q: Vector3 = p + Vector3(_rng.randf_range(-0.35, 0.35), 0, _rng.randf_range(-0.35, 0.35))
			var h2: float = _rng.randf_range(0.14, 0.24)
			_toadstool(q, h2, h2 * 0.7, Vector3(_rng.randf_range(-0.2, 0.2), 0, _rng.randf_range(-0.2, 0.2)),
				450.0 + i, 0.0)
	# The Mother Cap (Active: upright, glowing / Cleared: snapped, cap on its side, dead grey).
	var mf := Vector3(-2.35, 0.0, 2.65)
	_tgt = "active"
	_toadstool(mf, 2.05, 1.05, Vector3(-0.05, 0, 0.07), 500.0, 1.0, false, 0.6)   # leans outward
	_tgt = "cleared"
	# Stump of the stalk with a jagged top, the rest lying outward with the cap on its side.
	var snap := mf + Vector3(0.03, 0.85, -0.04)
	_curve(PackedVector3Array([mf + Vector3(0, -0.03, 0), mf + Vector3(0, 0.1, 0), mf + Vector3(0.02, 0.5, -0.02), snap]),
		PackedFloat32Array([0.36, 0.33, 0.25, 0.23]), 7, STALK_D, {"col2": STALK, "kind": Kind.STONE, "lift": 0.15})
	for k: int in 5:
		var a: float = TAU * float(k) / 5.0
		_curve(PackedVector3Array([snap + Vector3(cos(a) * 0.18, -0.02, sin(a) * 0.18),
			snap + Vector3(cos(a) * 0.12, _rng.randf_range(0.1, 0.24), sin(a) * 0.12)]), PackedFloat32Array([0.07, 0.0]),
			4, STALK, {"kind": Kind.STONE, "normals": "flat"})
	var fall_dir := Vector3(-0.55, 0.0, 0.83).normalized()
	var s0: Vector3 = mf + fall_dir * 0.45 + Vector3(0, 0.22, 0)
	var s1: Vector3 = s0 + fall_dir * 1.1 + Vector3(0, 0.02, 0)
	_limb(s0, s1, 0.22, 0.2, 7, STALK, {"kind": Kind.STONE, "lift": 0.2})
	var capc: Vector3 = s1 + fall_dir * 0.35 + Vector3(0, 0.55, 0)
	var capb := Basis(fall_dir.cross(Vector3.UP).normalized(), -1.25)
	var prof: Array = [[0.3, -0.06], [1.0, 0.0], [0.97, 0.1], [0.8, 0.3], [0.5, 0.46], [0.18, 0.54]]
	var rings: Array = []
	for pr: Array in prof:
		var ring := PackedVector3Array()
		for k: int in 12:
			var a: float = TAU * float(k) / 12.0
			ring.append(capc + capb * Vector3(cos(a) * 1.0 * float(pr[0]), float(pr[1]) * 1.0, sin(a) * 1.0 * float(pr[0])))
		rings.append(ring)
	_part(_loft(rings, true, true, capc + capb * Vector3(0, 0.58, 0)), Transform3D.IDENTITY, CAP_D.lerp(GILL_DEAD, 0.5),
		{"kind": Kind.STONE, "col2": GILL_DEAD, "grad": "r", "normals": "smooth", "glo": 0.4, "lift": 0.2})
	_disc(capc, 1.2, 0.9, 10, 510.0, 0.4)
	_tgt = "base"
	_disc(mf, 1.25, 1.15, 10, 501.0)
	# The rotten log outside the ring (east), hollow end, shelf fungus, moss on top.
	var la := Vector3(4.05, 0.26, -1.25)
	var lb := Vector3(3.85, 0.28, 1.75)
	_limb(la, lb, 0.3, 0.27, 8, ROT_BARK, {"col2": BARK_D, "jitter": 0.03, "seed": 21.0})
	_part(_cyl(0.3, 0.3, 0.02, 8), Transform3D(_along(lb, la), la + (la - lb).normalized() * 0.005), Color(0.08, 0.06,
		0.05), {"kind": Kind.BARK, "tint": 0.0})
	for k: int in 5:
		var u: float = 0.15 + 0.17 * k
		var p: Vector3 = la.lerp(lb, u) + Vector3(-0.27, 0.05 + 0.08 * (k % 2), 0)
		_part(_cyl(0.2, 0.22, 0.05, 8), _xf(p, Vector3(0, 0, -0.15), Vector3(1.0, 1.0, 0.8)), SHELF,
			{"kind": Kind.STONE, "col2": SHELF.lightened(0.2), "lift": 0.4})
	for k: int in 3:
		var p: Vector3 = la.lerp(lb, 0.2 + 0.3 * k) + Vector3(0.0, 0.26, 0)
		_stone(_chunk(Vector3(0.3, 0.06, 0.24), 3, 600.0 + k, 0.6), _xf(p), FOREST_MOSS, 600.0 + k, 0.0, {"lift": 0.45})
	_disc((la + lb) * 0.5, 0.7, 1.9, 10, 21.0)
	# Mossy stones and small mushroom clusters outside the ring.
	for sd: Array in [[Vector3(-3.9, 0, -0.6), 0.42], [Vector3(-0.2, 0, 4.2), 0.35], [Vector3(2.6, 0, 3.7), 0.3]]:
		var p: Vector3 = sd[0]
		var s: float = sd[1]
		_stone(_chunk(Vector3(s * 1.2, s * 0.8, s), 5, 700.0 + p.x), _xf(p, Vector3(0, p.z, 0)), STONE_D, 700.0 + p.x, 0.9,
			{"col2": STONE})
		_disc(p, s * 1.7, s * 1.5, 8, 700.0 + p.x)
		for k: int in 3:
			var q: Vector3 = p + Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5)) * 1.4
			var hh: float = _rng.randf_range(0.12, 0.22)
			_toadstool(q, hh, hh * 0.75, Vector3.ZERO, 720.0 + k + p.x, 0.0)
	# Ferns at the edge of the clearing.
	for i: int in 7:
		var a: float = _rng.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * _rng.randf_range(3.9, 4.6)
		if p.distance_to((la + lb) * 0.5) < 1.8:
			continue
		for k: int in 6:
			var ka: float = TAU * float(k) / 6.0 + _rng.randf()
			_blade(p, Vector3(cos(ka) * 0.9, 0.7, sin(ka) * 0.9), _rng.randf_range(0.45, 0.65), 0.05, -0.15,
				FERN.darkened(0.25), FERN, Kind.IVY, 0.7)
	var meshes := _commit("gloomcap")
	var ground := _ground("gloomcap", 4.6, Vector3(0, 0, -1), 1.2, 12, 0.8, Color(0.33, 0.31, 0.28), ring_r)
	_scene(&"gloomcap", "GloomcapHollow", meshes, ground, 4.7, {"base": true, "active": true, "cleared": true})


# =================================================================================================================
# Stag Glade (T3). Local -Z faces the map centre; the Hollow Stag stands on the spot (r 0.9, 2.6 m tall): nothing
# above 0.3 m within 2.4 m. In front (-Z): the moss altar, a slab on two stones blanketed in moss with a glowing leaf
# groove and a shed antler laid on it; behind (+X +Z): the antler cairn, stacked stones bristling with shed antlers
# (the vertical, ~2 m) with glowing leaf buds on a few tines; an arc of low mossy stones, ferns, white glade flowers,
# a fallen branch. Cleared: the glow dies (lit 0).
# =================================================================================================================

## A shed antler: a curved main beam with `tines` branching tines, from `base` along `dir`.
func _antler(base: Vector3, dir: Vector3, length: float, r: float, tines: int, seed: float, leaves: int = 0) -> void:
	var d: Vector3 = dir.normalized()
	var side: Vector3 = d.cross(Vector3.UP)
	if side.length_squared() < 1e-3:
		side = Vector3.RIGHT
	side = side.normalized()
	var bend: Vector3 = side.cross(d).normalized()
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	for k: int in 5:
		var u: float = float(k) / 4.0
		pts.append(base + d * length * u + bend * sin(u * PI * 0.8) * length * 0.18 + side * u * u * length * 0.1)
		radii.append(lerpf(r, r * 0.25, u))
	radii[4] = 0.0
	_curve(pts, radii, 6, ANTLER, {"col2": ANTLER_T, "normals": "smooth", "tint": 0.06})
	# Burr at the base.
	_part(_cyl(r * 1.6, r * 1.6, r * 0.8, 7), Transform3D(_along(base, pts[1]), base), ANTLER.darkened(0.15),
		{"kind": Kind.BARK, "jitter": r * 0.2, "seed": seed})
	for t: int in tines:
		var u: float = 0.3 + 0.55 * float(t) / maxf(float(tines - 1), 1.0)
		var i0: int = int(u * 4.0)
		var at: Vector3 = pts[mini(i0, 3)].lerp(pts[mini(i0 + 1, 4)], u * 4.0 - float(i0))
		var sgn: float = 1.0 if t % 2 == 0 else -1.0
		var td: Vector3 = (d * 0.6 + bend * 0.7 + side * sgn * 0.5).normalized()
		var tl: float = length * lerpf(0.34, 0.22, u) * (0.85 + 0.3 * _h(Vector3(seed, t, 1)))
		var tip: Vector3 = at + td * tl
		_curve(PackedVector3Array([at, at.lerp(tip, 0.5) + d * tl * 0.12, tip]),
			PackedFloat32Array([r * lerpf(0.75, 0.45, u), r * 0.35, 0.0]), 5, ANTLER, {"col2": ANTLER_T})
		if t < leaves:
			for l: int in 2:
				var lp: Vector3 = tip - td * 0.05 + side * (0.07 if l == 0 else -0.06) + Vector3(0, 0.02 * l, 0)
				_part(_sph(0.075, 6, 3), _xf(lp, Vector3(0.3 * l, seed + l, 0.4), Vector3(1.0, 0.35, 1.7)), LEAF_GLOW,
					{"surf": "glow", "w": 0.75, "normals": "smooth"})


func _build_stag() -> void:
	_rng.seed = 24004
	_tgt = "base"
	# --- Moss altar in front.
	var ac := Vector3(0.1, 0.0, -3.35)
	var ab := Basis(Vector3.UP, 0.12)
	for side: float in [-1.0, 1.0]:
		_stone(_chunk(Vector3(0.3, 0.34, 0.38), 5, 800.0 + side), Transform3D(ab, ac + ab * Vector3(side * 0.62, 0.2, 0.0)),
			ALTAR_D, 800.0 + side, 0.8, {"col2": ALTAR})
	var slab := Transform3D(ab * Basis(Vector3.FORWARD, 0.03), ac + Vector3(0, 0.5, 0))
	_stone(_box(Vector3(1.9, 0.24, 0.95)), slab, ALTAR, 810.0, 1.0, {"jitter": 0.04, "col2": ALTAR})
	_stone(_chunk(Vector3(1.0, 0.1, 0.52), 4, 811.0, 0.55), Transform3D(ab, ac + Vector3(0, 0.6, 0)), MOSS, 811.0, 0.0,
		{"col2": MOSS.lightened(0.15), "lift": 0.6})
	# Moss draping over the front and back edges.
	for k: int in 7:
		var x: float = -0.8 + 1.6 * float(k) / 6.0 + _rng.randf_range(-0.06, 0.06)
		for side: float in [-1.0, 1.0]:
			if _rng.randf() < 0.35:
				continue
			var top: Vector3 = ac + ab * Vector3(x, 0.63, side * 0.46)
			var hang: float = _rng.randf_range(0.18, 0.4)
			_curve(PackedVector3Array([top, top + ab * Vector3(0, -0.04, side * 0.07), top + ab * Vector3(0, -hang,
				side * 0.05)]), PackedFloat32Array([0.07, 0.06, 0.0]), 5, MOSS, {"kind": Kind.IVY, "col2": MOSS.darkened(0.2),
				"lift": 0.5})
	# The glowing leaf groove on the slab (midrib + veins), and a shed antler laid across it.
	var gy: float = 0.645
	var mid_a: Vector3 = ac + ab * Vector3(-0.55, gy, 0.05)
	var mid_b: Vector3 = ac + ab * Vector3(0.5, gy, -0.05)
	_curve(PackedVector3Array([mid_a, mid_a.lerp(mid_b, 0.5) + ab * Vector3(0, 0.005, 0.06), mid_b]),
		PackedFloat32Array([0.03, 0.035, 0.02]), 4, LEAF_GLOW, {"surf": "glow", "w": 1.0})
	for k: int in 4:
		var u: float = 0.2 + 0.2 * k
		var root: Vector3 = mid_a.lerp(mid_b, u)
		for side: float in [-1.0, 1.0]:
			var tip: Vector3 = root + ab * Vector3(0.18, 0.0, side * (0.3 - 0.05 * k))
			_curve(PackedVector3Array([root, tip]), PackedFloat32Array([0.022, 0.012]), 4, LEAF_GLOW,
				{"surf": "glow", "w": 0.85})
	var leaf_ring := PackedVector3Array()
	for k: int in 14:   # the leaf outline
		var a: float = TAU * float(k) / 14.0
		leaf_ring.append(ac + ab * Vector3(cos(a) * 0.62 - 0.02, gy, sin(a) * 0.36 * (1.0 - 0.35 * cos(a))))
	for k: int in 14:
		_curve(PackedVector3Array([leaf_ring[k], leaf_ring[(k + 1) % 14]]), PackedFloat32Array([0.02, 0.02]), 4,
			LEAF_GLOW, {"surf": "glow", "w": 0.8})
	_antler(ac + ab * Vector3(-0.75, 0.66, 0.3), ab * Vector3(1.0, 0.08, -0.35), 0.95, 0.05, 3, 820.0)
	_disc(ac, 1.45, 0.95, 10, 830.0, -0.12)
	# Offerings: glade flowers laid at the altar's foot.
	for k: int in 6:
		var p: Vector3 = ac + ab * Vector3(_rng.randf_range(-0.9, 0.9), 0.0, -0.62 - _rng.randf() * 0.25)
		_blade(p, Vector3(_rng.randf_range(-0.3, 0.3), 1, _rng.randf_range(-0.3, 0.3)), 0.2, 0.02, 0.0, FERN, FERN,
			Kind.IVY, 0.5, 1)
		_part(_sph(0.06, 6, 3), _xf(p + Vector3(0, 0.21, 0), Vector3.ZERO, Vector3(1, 0.5, 1)),
			FLOWER if k % 3 != 0 else FLOWER_Y, {"kind": Kind.STONE, "lift": 0.6, "tint": 0.0})
	# --- Antler cairn behind the stag (the vertical).
	var cc := Vector3(2.85, 0.0, 2.85)
	var tiers: Array = [[6, 0.62, 0.42, 0.24], [4, 0.36, 0.34, 0.68], [3, 0.15, 0.27, 1.02], [1, 0.0, 0.22, 1.32]]
	var ti: int = 0
	for tr: Array in tiers:
		var cnt: int = tr[0]
		for k: int in cnt:
			var a: float = TAU * float(k) / float(cnt) + ti * 0.7
			var p: Vector3 = cc + Vector3(cos(a) * float(tr[1]), float(tr[3]), sin(a) * float(tr[1]))
			var s: float = float(tr[2]) * _rng.randf_range(0.9, 1.1)
			_stone(_chunk(Vector3(s * 1.15, s * 0.75, s), 5, 900.0 + ti * 10 + k), _xf(p, Vector3(0, a, 0)), STONE,
				900.0 + ti * 10 + k, 0.7 if ti == 0 else 0.45, {"col2": STONE_D})
		ti += 1
	_disc(cc, 1.35, 1.25, 10, 950.0)
	# Shed antlers stuck into the cairn and leaning on it, fanning up and out (the site's vertical, ~2.3 m).
	var ants: Array = [[Vector3(0.05, 1.35, 0.0), Vector3(0.08, 1.0, -0.15), 1.25, 4, 2],
		[Vector3(-0.3, 1.0, 0.2), Vector3(-0.7, 0.9, 0.35), 1.2, 3, 2],
		[Vector3(0.35, 0.95, 0.25), Vector3(0.65, 0.85, 0.5), 1.15, 3, 1],
		[Vector3(0.25, 0.8, -0.4), Vector3(0.45, 0.8, -0.7), 1.0, 3, 1],
		[Vector3(-0.4, 0.6, -0.35), Vector3(-0.75, 0.55, -0.6), 0.95, 2, 0]]
	var ai: int = 0
	for an: Array in ants:
		_antler(cc + (an[0] as Vector3), an[1] as Vector3, float(an[2]), 0.085, int(an[3]), 960.0 + ai, int(an[4]))
		ai += 1
	# A couple of antlers lying at the cairn's foot.
	_antler(cc + Vector3(-1.05, 0.06, 0.25), Vector3(-0.2, 0.05, 1.0), 0.95, 0.065, 2, 980.0)
	_antler(cc + Vector3(0.85, 0.06, -0.75), Vector3(1.0, 0.1, -0.3), 0.85, 0.06, 2, 981.0)
	# A ring of low, broad mossy stones (the old sacred circle), skipping the altar and the cairn; walk-through
	# height (< 0.45 m).
	for k: int in 12:
		var a: float = TAU * float(k) / 12.0 + 0.15
		var p := Vector3(cos(a) * 4.35, 0.0, sin(a) * 4.35)
		if p.distance_to(ac) < 1.7 or p.distance_to(cc) < 1.5:
			continue
		var s: float = _rng.randf_range(0.34, 0.44)
		_stone(_chunk(Vector3(s * 1.25, 0.42, s), 5, 1000.0 + k, 0.82), _xf(p + Vector3(0, 0.05, 0),
			Vector3(_rng.randf_range(-0.12, 0.12), a, _rng.randf_range(-0.12, 0.12))), ALTAR, 1000.0 + k, 0.55,
			{"col2": ALTAR.lightened(0.2)})
		_disc(p, s * 1.7, s * 1.5, 7, 1000.0 + k)
	# Ferns and white flowers around the edge; a fallen branch.
	for i: int in 9:
		var a: float = _rng.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * _rng.randf_range(3.3, 4.5)
		if p.distance_to(ac) < 1.4 or p.distance_to(cc) < 1.3:
			continue
		for k: int in 6:
			var ka: float = TAU * float(k) / 6.0 + _rng.randf()
			_blade(p, Vector3(cos(ka) * 0.9, 0.75, sin(ka) * 0.9), _rng.randf_range(0.4, 0.6), 0.05, -0.12,
				FERN.darkened(0.2), FERN.lightened(0.1), Kind.IVY, 0.7)
		for k: int in 3:
			var q: Vector3 = p + Vector3(_rng.randf_range(-0.5, 0.5), 0, _rng.randf_range(-0.5, 0.5))
			_part(_sph(0.07, 6, 3), _xf(q + Vector3(0, 0.12, 0), Vector3.ZERO, Vector3(1, 0.5, 1)), FLOWER,
				{"kind": Kind.STONE, "lift": 0.6, "tint": 0.0})
	var fb0 := Vector3(-3.4, 0.08, 1.2)
	var fb1 := Vector3(-2.3, 0.1, 2.6)
	_limb(fb0, fb1, 0.09, 0.06, 6, BARK)
	_limb(fb0.lerp(fb1, 0.6), fb0.lerp(fb1, 0.6) + Vector3(-0.5, 0.1, 0.35), 0.05, 0.02, 5, BARK)
	_disc((fb0 + fb1) * 0.5, 0.9, 0.3, 8, 1050.0, -atan2(fb1.z - fb0.z, fb1.x - fb0.x))
	var meshes := _commit("hollow_stag")
	var ground := _ground("hollow_stag", 5.2, Vector3(0, 0, -1), 1.0, 13, 0.95, Color(0.38, 0.47, 0.30))
	_scene(&"hollow_stag", "StagGlade", meshes, ground, 4.7, {"base": true})
