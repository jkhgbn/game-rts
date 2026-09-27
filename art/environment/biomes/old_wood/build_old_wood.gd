extends SceneTree
## Task 12.V10 (map-fill.md 3.1 biome 5 "Old Wood" + section 10): generates the Old Wood decor meshes. One mesh per
## decor kind, 3 shape variants in each through the variant mask (UV2.x, the rule of nature_painted.gdshader: the
## shader picks the variant from a hash of the instance position, so one MultiMesh shows 3 shapes). Every mesh has
## ONE surface and ONE material, so a scatter may draw it with the mesh's own material or a material_override.
##   ow_ferns.res         dark ferns (V0 lady-fern rosette, V1 upright shuttlecock fern + fiddleheads, V2 low bracken
##                        with two rust-brown dead fronds)                                     nature_mat.tres
##   ow_glowcaps.res      blue-cap glow mushrooms (V0 cluster on a mossy stub, V1 fairy-ring arc, V2 tall pair + young
##                        ones)                                                     old_wood_glow_mat.tres (emission)
##   ow_moss_boulders.res moss-capped boulders (V0 big boulder + leaning stone + ferns, V1 a pair, V2 a low slab + stone)
##                                                                                             nature_mat.tres
##   ow_fallen_trunk.res  fallen trunks (V0 with its upturned root plate, V1 broken in two with a hollow end, V2 leaning
##                        on its own snapped stump)                                            nature_mat.tres
##   ow_roots.res         surface roots (V0 three arching roots, V1 a knot of crossing roots round a weathered stump
##                        stub, V2 a serpentine root looping over a stone)                     nature_mat.tres
##   ow_cobwebs.res       cobweb cards on dead twigs (V0 dead snag + orb web, V1 bramble hoop + orb web, V2 ground
##                        sheet web on stubby stalks)                                       old_wood_web_mat.tres
## Vertex data: COLOR.rgb colour, COLOR.a height gradient (0 bottom -> 1 top), UV.x wind weight (ferns) / stone moss /
## glow weight (glowcaps) / card coordinate (webs), UV.y local height (card coordinate on webs), UV2 = (variant mask,
## kind). Every mesh is indexed (welded). No lights, no textures, no runtime materials.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/old_wood/build_old_wood.gd --quit-after 600

const DIR := "res://art/environment/biomes/old_wood/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
enum Web { TWIG = 0, ORB = 1, SHEET = 2 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45

# Palette (sRGB). The Old Wood is the darkest, coolest green of the map (the meadow is the sunny yellow one); its
# accents are the blue glow caps, pale moss tops, pale cobwebs and a few rust-brown dead bracken fronds.
const FERN_D := Color(0.07, 0.20, 0.10)
const FERN := Color(0.15, 0.37, 0.17)
const FERN_L := Color(0.31, 0.54, 0.22)
const FERN_TIP := Color(0.46, 0.64, 0.26)
const BRACKEN_D := Color(0.26, 0.16, 0.08)
const BRACKEN := Color(0.44, 0.28, 0.12)
const BRACKEN_L := Color(0.58, 0.41, 0.19)
const STEM_L := Color(0.84, 0.86, 0.88)
const STEM_D := Color(0.46, 0.52, 0.60)
const CAP_D := Color(0.06, 0.11, 0.40)
const CAP := Color(0.10, 0.24, 0.72)
const CAP_RIM := Color(0.36, 0.66, 1.00)
const GILL := Color(0.64, 0.90, 1.00)
const SPOT := Color(0.80, 0.96, 1.00)
const MOSS_D := Color(0.13, 0.25, 0.09)
const MOSS := Color(0.23, 0.38, 0.12)
const MOSS_L := Color(0.36, 0.50, 0.16)
const STONE_OW := Color(0.33, 0.35, 0.37)
const STONE_OW_D := Color(0.25, 0.27, 0.29)
const STONE_OW_W := Color(0.38, 0.37, 0.34)
const BARK_OW := Color(0.28, 0.21, 0.15)
const BARK_OW_D := Color(0.17, 0.13, 0.10)
const BARK_GREY := Color(0.36, 0.33, 0.29)
const END_GRAIN := Color(0.64, 0.49, 0.31)
const END_RING := Color(0.44, 0.32, 0.20)
const ROT := Color(0.10, 0.07, 0.05)
const EARTH := Color(0.25, 0.19, 0.13)
const FUNGUS := Color(0.88, 0.74, 0.48)
const FUNGUS_O := Color(0.86, 0.47, 0.16)
const ROOT := Color(0.31, 0.24, 0.17)
const ROOT_D := Color(0.20, 0.15, 0.11)
const TWIG := Color(0.22, 0.20, 0.19)
const TWIG_L := Color(0.48, 0.44, 0.40)
const WEB_TINT := Color(1.0, 1.0, 1.0)

var nature_mat: Material
var glow_mat: Material
var web_mat: Material
var _conv: float = 1.0

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _ux := PackedFloat32Array()    # UV.x
var _uy := PackedFloat32Array()    # UV.y
var _uv2 := PackedVector2Array()   # (variant mask, kind)
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_detect_winding()
	nature_mat = load(NDIR + "nature_mat.tres") as Material
	glow_mat = load(DIR + "old_wood_glow_mat.tres") as Material
	web_mat = load(DIR + "old_wood_web_mat.tres") as Material
	if nature_mat == null or glow_mat == null or web_mat == null:
		push_error("old wood: a material is missing")
		quit(1)
		return
	_build_ferns()
	_build_glowcaps()
	_build_boulders()
	_build_fallen_trunk()
	_build_roots()
	_build_cobwebs()
	for line: String in _report:
		print(line)
	print("OLD WOOD BUILD OK")
	quit()


# --- helpers (conventions of nature_props/build_nature.gd and biomes/riverbank/build_riverbank.gd) ---------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


## Smooth 3D value noise 0..1 (trilinear over the _h lattice): soft moss patches.
func _vnoise(p: Vector3) -> float:
	var i := Vector3(floorf(p.x), floorf(p.y), floorf(p.z))
	var f: Vector3 = p - i
	f = f * f * (Vector3(3, 3, 3) - f * 2.0)
	var out := 0.0
	for dz: int in 2:
		for dy: int in 2:
			for dx: int in 2:
				var w: float = (f.x if dx == 1 else 1.0 - f.x) * (f.y if dy == 1 else 1.0 - f.y) * \
					(f.z if dz == 1 else 1.0 - f.z)
				out += _h(i + Vector3(dx, dy, dz)) * w
	return out


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
	_ux = PackedFloat32Array()
	_uy = PackedFloat32Array()
	_uv2 = PackedVector2Array()


func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array,
		cols: PackedColorArray = PackedColorArray(), uvs: PackedVector2Array = PackedVector2Array()) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	if not cols.is_empty():
		arr[Mesh.ARRAY_COLOR] = cols
	if not uvs.is_empty():
		arr[Mesh.ARRAY_TEX_UV] = uvs
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


## A chiselled rock (build_nature.gd): a low-poly ellipsoid cut by `cuts` random planes + a flat-ish top plane.
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


## A tapered tube along `path` with one radius per point (0 = pointed tip), `sides` around; cap_start / cap_end
## close the ends (flat). Smooth normals.
func _tube(path: Array, radii: Array, sides: int, cap_start: bool = false, cap_end: bool = false) -> Array:
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
		var ref: Vector3 = Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
		var a0: Vector3 = (ref - t * ref.dot(t)).normalized()
		var b0: Vector3 = t.cross(a0).normalized()
		var r: float = radii[i]
		for k: int in sides:
			var a: float = TAU * k / sides
			var dirv: Vector3 = a0 * cos(a) + b0 * sin(a)
			v.append((path[i] as Vector3) + dirv * r)
			n.append(dirv)
	for i: int in cnt - 1:
		for k: int in sides:
			var p0: int = i * sides + k
			var p1: int = i * sides + (k + 1) % sides
			var q0: int = (i + 1) * sides + k
			var q1: int = (i + 1) * sides + (k + 1) % sides
			idx.append_array([p0, p1, q0, p1, q1, q0])
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


## A surface of revolution around local +Y: `prof` = [Vector2(radius, y)...] from the top down, with one colour and
## one UV.x value (glow weight) per profile point. Smooth normals from the profile.
func _lathe(prof: Array, sides: int, cols: Array, ux: Array) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var cnt: int = prof.size()
	for i: int in cnt:
		var p: Vector2 = prof[i]
		var pa: Vector2 = prof[maxi(i - 1, 0)]
		var pb: Vector2 = prof[mini(i + 1, cnt - 1)]
		var tan2: Vector2 = (pb - pa).normalized()   # along the profile (top -> down)
		var out2 := Vector2(tan2.y, -tan2.x)          # outward in (r, y)
		if out2.x < 0.0 and p.x > 0.001:
			out2 = -out2
		if p.x < 0.001:
			out2 = Vector2(0.0, 1.0) if i == 0 else Vector2(0.0, -1.0)
		for k: int in sides:
			var a: float = TAU * k / sides
			var dirv := Vector3(cos(a), 0.0, sin(a))
			v.append(dirv * p.x + Vector3(0.0, p.y, 0.0))
			n.append((dirv * out2.x + Vector3(0.0, out2.y, 0.0)).normalized())
			c.append(cols[i])
			uv.append(Vector2(float(ux[i]), 0.0))
	for i: int in cnt - 1:
		for k: int in sides:
			var p0: int = i * sides + k
			var p1: int = i * sides + (k + 1) % sides
			var q0: int = (i + 1) * sides + k
			var q1: int = (i + 1) * sides + (k + 1) % sides
			idx.append_array([p0, q0, p1, p1, q0, q1])
	return _mk(v, n, idx, c, uv)


## A small 4-sided double pyramid from `a` to `b` (spots, broken-wood splinters), radius r at `bulge` along a -> b.
func _spindle(a: Vector3, b: Vector3, r: float, bulge: float, sides: int = 4) -> Array:
	var d: Vector3 = (b - a).normalized()
	var x: Vector3 = d.cross(Vector3.FORWARD if absf(d.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(d).normalized()
	var m: Vector3 = a + (b - a) * bulge
	var v := PackedVector3Array([a])
	var n := PackedVector3Array([-d])
	for i: int in sides:
		var ang: float = i * TAU / sides
		var rad: Vector3 = x * cos(ang) + z * sin(ang)
		v.append(m + rad * r)
		n.append(rad)
	v.append(b)
	n.append(d)
	var idx := PackedInt32Array()
	for i: int in sides:
		var j: int = (i + 1) % sides
		idx.append_array([0, 1 + i, 1 + j, sides + 1, 1 + j, 1 + i])
	return _mk(v, n, idx)


## Adds mesh arrays, transformed. Options (all optional):
##   kind (Kind, or Web for the cobweb mesh), mask (variant bits, 0 = every variant), jitter (m), seed, jit_axes,
##   normals "flat" | "smooth" | "up" (mostly straight up: flat leaves), col2 + grad ("y" part height | "r"),
##   tint (random value variation), moss (stone: UV.x moss amount), ux (Vector2: UV.x at the part's bottom -> top;
##   wind weight or glow weight), use_ux (UV.x from the arrays' ARRAY_TEX_UV.x, e.g. per-vertex wind or glow),
##   moss_top (0-1: vertices facing the sky turn to moss, patchy), clip_y (drop triangles whose corners are all
##   below this y), no_caps (drop +-Y cap faces of primitives). Per-vertex colours in the arrays win over col / col2.
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var vc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var au: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.BARK)
	var mask: int = o.get("mask", 0)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var jit_axes: Vector3 = o.get("jit_axes", Vector3.ONE)
	var mode: String = o.get("normals", "flat")
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var tint: float = o.get("tint", 0.08)
	var moss: float = o.get("moss", 0.0)
	var ux: Vector2 = o.get("ux", Vector2.ZERO)
	var use_ux: bool = o.get("use_ux", false) and not au.is_empty()
	var moss_top: float = o.get("moss_top", 0.0)
	var moss_lo: float = o.get("moss_lo", 0.30)
	var moss_cover: float = 1.0 - float(o.get("moss_cover", 0.5))   # 1 - share of the sky-facing area that is mossy
	var lift: float = o.get("lift", 0.0)
	var clip_y: float = o.get("clip_y", -INF)
	var no_caps: bool = o.get("no_caps", false)
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
			elif mode == "up":
				nn = (tn[vi] * 0.35 + Vector3.UP).normalized()
			var gy: float = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
			var gt: float = gy
			if grad == "r":
				gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
			var cc: Color = vc[vi] if not vc.is_empty() else col.lerp(col2, gt)
			if moss_top > 0.0:
				var patch: float = (_vnoise(tv[vi] * 5.0 + Vector3(seed, 3.1, 0.0)) - 0.5) * 0.5
				var m: float = smoothstep(moss_lo, moss_lo + 0.32, tn[vi].y + patch) * moss_top
				# Moss grows in soft-edged patches, never as an even green coat.
				m *= smoothstep(moss_cover - 0.1, moss_cover + 0.1, _vnoise(tv[vi] * 1.7 + Vector3(0.0, seed, 7.7)))
				var mc: Color = MOSS_D.lerp(MOSS, smoothstep(0.4, 0.9, tn[vi].y)).lerp(MOSS_L,
					_vnoise(tv[vi] * 6.0) * 0.4)
				cc = cc.lerp(mc, m)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k))
			if kind == Kind.STONE and o.has("moss"):
				_ux.append(moss)
			elif use_ux:
				_ux.append(au[vi].x)
			else:
				_ux.append(lerpf(ux.x, ux.y, gy))
			_uy.append(tv[vi].y + lift)
			_uv2.append(Vector2(mask, kind))


## Bakes COLOR.a (height gradient), welds, saves DIR/<name>.res with ONE surface and `material`, reports numbers.
## o: grad_min (COLOR.a floor), wind_clamp (clamp UV.x into 0..WMAX: meshes drawn with nature_mat).
func _commit(name: String, material: Material, o: Dictionary = {}) -> ArrayMesh:
	var grad_min: float = o.get("grad_min", 0.0)
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
		var x: float = _ux[i]
		if o.get("wind_clamp", false):
			x = clampf(x, 0.0, WMAX) if int(_uv2[i].y) != Kind.STONE else clampf(x, 0.0, 1.0)
		uv[i] = Vector2(x, _uy[i])
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
	mesh.surface_set_material(0, material)
	_save(mesh, DIR + name + ".res")
	var per := [0, 0, 0]
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		for k: int in 3:
			if m <= 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-18s %4d tris, %4d verts (variants %d / %d / %d), size %.2f x %.2f x %.2f, y %.2f..%.2f" % [
		name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		aabb.size.x, aabb.size.y, aabb.size.z, miny, maxy])
	return mesh


## Non-indexed triangle arrays -> indexed ones, merging vertices whose every attribute matches.
func _weld(src: Array) -> Array:
	var sv: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	var sn: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
	var sc: PackedColorArray = src[Mesh.ARRAY_COLOR]
	var su: PackedVector2Array = src[Mesh.ARRAY_TEX_UV]
	var s2: PackedVector2Array = src[Mesh.ARRAY_TEX_UV2]
	var seen := {}
	var remap := PackedInt32Array()
	remap.resize(sv.size())
	var keep := PackedInt32Array()
	for i: int in sv.size():
		var key := "%.4f,%.4f,%.4f|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f,%.3f|%.4f,%.4f|%d,%d" % [sv[i].x, sv[i].y, sv[i].z,
			sn[i].x, sn[i].y, sn[i].z, sc[i].r, sc[i].g, sc[i].b, sc[i].a, su[i].x, su[i].y, int(s2[i].x), int(s2[i].y)]
		if seen.has(key):
			remap[i] = seen[key]
		else:
			seen[key] = keep.size()
			remap[i] = keep.size()
			keep.append(i)
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var oc := PackedColorArray()
	var ou := PackedVector2Array()
	var o2 := PackedVector2Array()
	for i: int in keep:
		ov.append(sv[i])
		on.append(sn[i])
		oc.append(sc[i])
		ou.append(su[i])
		o2.append(s2[i])
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = ov
	out[Mesh.ARRAY_NORMAL] = on
	out[Mesh.ARRAY_COLOR] = oc
	out[Mesh.ARRAY_TEX_UV] = ou
	out[Mesh.ARRAY_TEX_UV2] = o2
	out[Mesh.ARRAY_INDEX] = remap
	return out


# --- ferns (nature_mat, foliage kind IVY: never the random autumn tint) ------------------------------------------

## One fern frond: a comb of leaflets (pinnae) along an arching rachis, big near the middle, small at the base and
## the tip, each a kite leaning forward and drooping a little, + a tip leaflet. `ang` = direction on the ground,
## rise / droop shape the arch (tip height = rise - droop), `width` = the longest leaflet. The leaflets touch, so the
## frond reads as one feathery blade from the game camera. UV.x = wind weight (0 at the base -> 0.4 at the tip).
func _frond(base: Vector3, ang: float, length: float, rise: float, droop: float, width: float, secs: int,
		mask: int, seed: float, c0: Color, c1: Color, c2: Color, lobe: float = 0.45) -> void:
	var d := Vector3(cos(ang), 0.0, sin(ang))
	var s := Vector3(-d.z, 0.0, d.x)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var pts: Array[Vector3] = []
	for k: int in secs + 1:
		var t: float = float(k) / secs
		var h: float = rise * (2.0 * t - t * t) - droop * t * t * t
		var wig: float = sin(t * 5.0 + seed) * 0.03 * t
		pts.append(base + d * length * t + s * wig + Vector3(0.0, h, 0.0))
	var step: float = length / secs
	for k: int in range(1, secs + 1):
		var t: float = float(k) / secs
		var p: Vector3 = pts[k]
		var tg: Vector3 = (pts[mini(k + 1, secs)] - pts[k - 1]).normalized()
		var sd: Vector3 = tg.cross(Vector3.UP).normalized() * -1.0
		var up: Vector3 = sd.cross(tg).normalized() * -1.0
		if up.y < 0.0:
			up = -up
		var cc: Color = c0.lerp(c1, t * 2.0) if t < 0.5 else c1.lerp(c2, (t - 0.5) * 2.0)
		var wind: float = 0.40 * t
		var sides: Array = [1.0, -1.0] if k < secs else [0.0]
		for sg: float in sides:
			var ll: float = width * pow(sin(PI * clampf(t * 0.94, 0.0, 1.0)), 0.8) * (1.0 - 0.25 * t) * \
				(1.0 - lobe * 0.25 * float(k % 2))
			var dir: Vector3 = (sd * sg * 0.78 + tg * 0.62).normalized() if sg != 0.0 else tg
			if sg == 0.0:
				ll = width * 0.55
			var tip: Vector3 = p + dir * ll - up * ll * 0.28
			var half: float = step * 0.8 if sg != 0.0 else ll * 0.3
			var side_v: Vector3 = (sd * sg).normalized() if sg != 0.0 else sd
			var c1v: Vector3 = p + dir * ll * 0.45 + tg * half * 0.5 + up * 0.01
			var c2v: Vector3 = p + dir * ll * 0.45 - tg * half * 0.6 + up * 0.01
			if sg == 0.0:
				c1v = p + tg * ll * 0.4 + side_v * half
				c2v = p + tg * ll * 0.4 - side_v * half
			var b: int = v.size()
			v.append_array([p - tg * step * 0.25, c1v, tip, c2v])
			var nn: Vector3 = (up + side_v * sg * 0.25).normalized()
			n.append_array([nn, nn, nn, nn])
			cols.append_array([cc.darkened(0.22), cc, cc.lightened(0.12), cc.darkened(0.06)])
			uvs.append_array([Vector2(wind, 0.0), Vector2(wind, 0.0), Vector2(minf(wind + 0.05, WMAX), 0.0),
				Vector2(wind, 0.0)])
			idx.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
	_part(_mk(v, n, idx, cols, uvs), Transform3D.IDENTITY, c1, {"kind": Kind.IVY, "mask": mask, "normals": "smooth",
		"use_ux": true, "tint": 0.10, "lift": 0.3})


## A fiddlehead: a young frond still curled in a spiral on a short stalk.
func _fiddlehead(base: Vector3, h: float, ang: float, mask: int, seed: float) -> void:
	var d := Vector3(cos(ang), 0.0, sin(ang))
	var pts: Array = [base, base + Vector3(0, h * 0.55, 0) + d * 0.02]
	var top: Vector3 = base + Vector3(0, h, 0) + d * 0.04
	var r0: float = 0.055
	for i: int in 5:
		var a: float = PI * 0.5 - i * 1.3
		var rr: float = r0 * (1.0 - i * 0.16)
		pts.append(top + d * (cos(a) * rr) + Vector3(0, sin(a) * rr - r0, 0))
	var radii: Array = [0.02, 0.018, 0.02, 0.02, 0.018, 0.015, 0.0]
	var arr: Array = _tube(pts, radii, 3, true, false)
	_part(arr, Transform3D.IDENTITY, FERN_L, {"kind": Kind.IVY, "mask": mask, "normals": "smooth", "col2": FERN_TIP,
		"ux": Vector2(0.0, 0.25), "seed": seed})


func _build_ferns() -> void:
	_begin()
	# V0: lady-fern rosette, 7 arching fronds, ~1.7 m across, 0.6 m tall.
	for i: int in 7:
		var a: float = i * TAU / 7.0 + (_h(Vector3(i, 1, 0)) - 0.5) * 0.45
		var ln: float = 0.72 + 0.16 * _h(Vector3(i, 2, 0))
		_frond(Vector3(cos(a) * 0.04, 0.03, sin(a) * 0.04), a, ln, 0.58, 0.44, 0.28, 5, V0, 10.0 + i, FERN_D, FERN,
			FERN_L if i % 3 != 0 else FERN_TIP)
	# V1: shuttlecock fern, 6 tall vase-shaped fronds (0.95 m) + two fiddleheads in the centre.
	for i: int in 6:
		var a2: float = i * TAU / 6.0 + 0.3 + (_h(Vector3(i, 3, 0)) - 0.5) * 0.35
		var ln2: float = 0.5 + 0.1 * _h(Vector3(i, 4, 0))
		_frond(Vector3(cos(a2) * 0.05, 0.04, sin(a2) * 0.05), a2, ln2, 1.0, 0.3, 0.25, 5, V1, 20.0 + i, FERN_D,
			FERN.lightened(0.05), FERN_TIP)
	_fiddlehead(Vector3(0.03, 0.03, -0.02), 0.34, 0.4, V1, 30.0)
	_fiddlehead(Vector3(-0.04, 0.03, 0.03), 0.26, 2.6, V1, 31.0)
	# V2: low, wide bracken: 6 spreading fronds (~2 m across), one of them rust-brown and dying.
	for i: int in 6:
		var a3: float = i * TAU / 6.0 + 0.8 + (_h(Vector3(i, 5, 0)) - 0.5) * 0.5
		var ln3: float = 0.82 + 0.18 * _h(Vector3(i, 6, 0))
		var dead: bool = i == 2
		_frond(Vector3(cos(a3) * 0.05, 0.03, sin(a3) * 0.05), a3, ln3, 0.42 if not dead else 0.3, 0.3, 0.29, 5, V2,
			40.0 + i, BRACKEN_D if dead else FERN_D, BRACKEN if dead else FERN.darkened(0.05),
			BRACKEN_L if dead else FERN_L, 0.5)
	_commit("ow_ferns", nature_mat, {"wind_clamp": true})


# --- glow mushrooms (old_wood_glow_mat: UV.x = glow weight) ------------------------------------------------------

## One mushroom: a slender stem (bulb at the foot) under a domed cap whose rim and gills glow; `spots` pale glowing
## spots on the cap. `lean` tilts it (the cap stays level-ish).
func _shroom(base: Vector3, h: float, cap_r: float, lean: Vector3, mask: int, seed: float, spots: int = 0,
		sides: int = 8) -> void:
	# Chunky, readable at the game camera (art-keep.md 0.1: caps 1.3-1.6 x wider than a natural mushroom's).
	cap_r *= 1.45
	h *= 1.12
	var sr: float = cap_r * 0.22
	var top: Vector3 = base + Vector3(0, h, 0) + lean
	var mid: Vector3 = base + Vector3(0, h * 0.5, 0) + lean * 0.35
	_part(_tube([base + Vector3(0, -0.02, 0), mid, top], [sr * 1.3, sr * 0.9, sr * 0.8], 4 if sides < 7 else 5, false,
		false), Transform3D.IDENTITY, STEM_D,
		{"mask": mask, "normals": "smooth", "col2": STEM_L, "ux": Vector2(0.0, 0.22), "seed": seed, "clip_y": -0.01})
	var ch: float = cap_r * 0.62
	var prof: Array
	var cols: Array
	var glow: Array
	if sides >= 6:
		prof = [Vector2(0.0, ch), Vector2(cap_r * 0.55, ch * 0.9), Vector2(cap_r, ch * 0.3), Vector2(cap_r * 0.9, 0.0),
			Vector2(sr * 0.9, -ch * 0.05)]
		cols = [CAP_D, CAP_D.lerp(CAP, 0.6), CAP_RIM, GILL, GILL.darkened(0.2)]
		glow = [0.16, 0.24, 0.9, 1.0, 0.75]
	else:
		prof = [Vector2(0.0, ch), Vector2(cap_r * 0.7, ch * 0.75), Vector2(cap_r, ch * 0.2), Vector2(sr * 0.9, 0.0)]
		cols = [CAP_D.lerp(CAP, 0.3), CAP, CAP_RIM, GILL]
		glow = [0.2, 0.34, 0.95, 1.0]
	var tilt := Vector3(lean.z * 0.8, (_h(Vector3(seed, 2, 2)) - 0.5) * 2.0, -lean.x * 0.8)
	_part(_lathe(prof, sides, cols, glow), _xf(top, tilt), CAP, {"mask": mask, "normals": "smooth", "use_ux": true,
		"tint": 0.06})
	for i: int in spots:
		var a: float = i * 2.4 + seed
		var rr: float = cap_r * (0.25 + 0.4 * _h(Vector3(seed, i, 5)))
		var p: Vector3 = Vector3(cos(a) * rr, 0.0, sin(a) * rr)
		p.y = ch * (1.0 - pow(rr / cap_r, 2.0) * 0.55) - 0.004
		var q: Vector3 = _xf(top, tilt) * p
		var sz: float = cap_r * (0.09 + 0.05 * _h(Vector3(seed, i, 6)))
		var arr: Array = _spindle(q - Vector3(0, sz * 0.2, 0), q + Vector3(0, sz * 0.45, 0), sz, 0.3, 4)
		_part(arr, Transform3D.IDENTITY, SPOT, {"mask": mask, "normals": "smooth", "ux": Vector2(1.0, 1.0)})


## A mossy lump / rotting wood knob the mushrooms grow from (no glow).
func _moss_lump(c: Vector3, r: Vector3, mask: int, seed: float) -> void:
	_part(_sph(1.0, 6, 3), _xf(c, Vector3(0, seed, 0), r), MOSS_D, {"mask": mask, "normals": "smooth", "col2": MOSS,
		"jitter": r.x * 0.15, "seed": seed, "clip_y": -0.01})


func _build_glowcaps() -> void:
	_begin()
	# V0: a cluster on a mossy rotten stub (~0.8 m across, tallest 0.46 m).
	_part(_tube([Vector3(0.02, -0.03, 0.0), Vector3(0.0, 0.12, 0.01), Vector3(0.01, 0.2, 0.0)], [0.17, 0.15, 0.14], 7,
		false, true), Transform3D.IDENTITY, BARK_OW, {"mask": V0, "normals": "smooth", "col2": BARK_OW_D,
		"moss_top": 0.9, "jitter": 0.02, "seed": 1.0, "clip_y": -0.01})
	_moss_lump(Vector3(0.18, 0.0, 0.12), Vector3(0.2, 0.09, 0.16), V0, 2.0)
	_shroom(Vector3(0.12, 0.08, -0.05), 0.34, 0.2, Vector3(0.05, 0, -0.03), V0, 3.0, 3)
	_shroom(Vector3(-0.12, 0.06, 0.08), 0.26, 0.17, Vector3(-0.06, 0, 0.04), V0, 4.0, 2)
	_shroom(Vector3(0.28, 0.02, 0.2), 0.16, 0.1, Vector3(0.04, 0, 0.02), V0, 5.0, 0, 5)
	_shroom(Vector3(-0.3, 0.0, -0.12), 0.13, 0.09, Vector3(-0.03, 0, -0.02), V0, 6.0, 0, 5)
	_shroom(Vector3(0.06, 0.0, 0.3), 0.12, 0.08, Vector3(0.0, 0, 0.04), V0, 7.0, 0, 5)
	_shroom(Vector3(-0.2, 0.0, 0.28), 0.09, 0.07, Vector3(-0.02, 0, 0.03), V0, 8.0, 0, 5)
	# V1: a fairy-ring arc of 7 small caps (1.1 m across) around a moss patch.
	for i: int in 7:
		var a: float = -0.4 + i * 0.6
		var rr: float = 0.5 + 0.06 * _h(Vector3(i, 7, 1))
		var hh: float = 0.1 + 0.1 * _h(Vector3(i, 7, 2))
		_shroom(Vector3(cos(a) * rr, 0.0, sin(a) * rr), hh, 0.08 + 0.05 * _h(Vector3(i, 7, 3)),
			Vector3(cos(a), 0, sin(a)) * 0.03, V1, 20.0 + i, 0, 5)
	_moss_lump(Vector3(0.1, 0.0, 0.2), Vector3(0.3, 0.05, 0.24), V1, 21.0)
	# V2: a tall pair (0.72 / 0.56 m) with wide caps, three young ones and a moss lump.
	_shroom(Vector3(0.0, 0.0, 0.0), 0.62, 0.27, Vector3(0.1, 0, 0.04), V2, 30.0, 4)
	_shroom(Vector3(-0.2, 0.0, 0.12), 0.46, 0.22, Vector3(-0.1, 0, 0.06), V2, 31.0, 3)
	_shroom(Vector3(0.24, 0.0, 0.2), 0.14, 0.09, Vector3(0.03, 0, 0.03), V2, 32.0, 0, 5)
	_shroom(Vector3(-0.1, 0.0, -0.24), 0.11, 0.08, Vector3(-0.02, 0, -0.03), V2, 33.0, 0, 5)
	_shroom(Vector3(0.3, 0.0, -0.1), 0.08, 0.06, Vector3(0.02, 0, 0.0), V2, 34.0, 0, 5)
	_moss_lump(Vector3(-0.05, 0.0, 0.05), Vector3(0.26, 0.07, 0.22), V2, 35.0)
	_commit("ow_glowcaps", glow_mat, {"grad_min": 0.2})


# --- moss boulders (nature_mat, stone kind with full moss: the shader grows moss caps on the tops) --------------

func _rock(radii: Vector3, pos: Vector3, rot: Vector3, col: Color, mask: int, seed: float, moss: float = 0.75,
		cuts: int = 5, top: float = 0.78, segs: int = 8, rings: int = 5) -> void:
	_part(_chunk(radii, cuts, seed, top, segs, rings), _xf(pos, rot), col, {"kind": Kind.STONE, "mask": mask,
		"moss": moss, "seed": seed, "tint": 0.12, "col2": col.lightened(0.07), "grad": "y", "clip_y": -0.03,
		"moss_top": 0.9 * moss, "moss_lo": 0.2, "moss_cover": 0.6})


func _pebble(pos: Vector3, r: float, col: Color, mask: int, seed: float) -> void:
	_part(_chunk(Vector3(r, r * 0.65, r * 0.85), 2, seed, 0.7, 5, 3), _xf(pos, Vector3(0.2, seed, 0.1)), col,
		{"kind": Kind.STONE, "mask": mask, "moss": 0.6, "seed": seed, "tint": 0.1, "clip_y": -0.03})


func _build_boulders() -> void:
	_begin()
	# V0: a big rounded boulder (0.8 m), a smaller one leaning on it, ferns and pebbles at the foot.
	_rock(Vector3(0.82, 0.62, 0.7), Vector3(0.05, 0.22, 0.0), Vector3(0.08, 0.4, 0.05), STONE_OW, V0, 40.0)
	_rock(Vector3(0.46, 0.4, 0.42), Vector3(-0.7, 0.12, 0.35), Vector3(0.25, 1.2, -0.2), STONE_OW_D, V0, 41.0)
	_pebble(Vector3(0.75, 0.03, 0.55), 0.13, STONE_OW_D, V0, 42.0)
	_pebble(Vector3(-0.3, 0.03, -0.75), 0.1, STONE_OW, V0, 43.0)
	for i: int in 3:
		var a: float = 0.7 + i * 0.55
		_frond(Vector3(cos(a) * 0.62, 0.03, sin(a) * 0.62), a, 0.45, 0.34, 0.26, 0.17, 6, V0, 44.0 + i, FERN_D, FERN,
			FERN_L)
	# V1: a pair: a tall rounded stone (0.85 m) beside a wide low one.
	_rock(Vector3(0.52, 0.82, 0.5), Vector3(-0.35, 0.05, -0.1), Vector3(0.06, 0.5, -0.08), STONE_OW_W, V1, 50.0, 1.0,
		5, 0.84)
	_rock(Vector3(0.7, 0.45, 0.6), Vector3(0.45, 0.1, 0.18), Vector3(0.0, 2.0, 0.1), STONE_OW, V1, 51.0)
	_pebble(Vector3(0.1, 0.03, 0.72), 0.12, STONE_OW_D, V1, 52.0)
	# V2: a low flat mossy slab (1.9 m) with a small boulder resting on its end.
	_rock(Vector3(1.0, 0.42, 0.66), Vector3(0.0, 0.02, 0.0), Vector3(0.04, 0.3, 0.03), STONE_OW_D, V2, 60.0, 1.0, 4,
		0.55)
	_rock(Vector3(0.36, 0.32, 0.33), Vector3(0.52, 0.34, 0.08), Vector3(0.3, 0.9, 0.1), STONE_OW_W, V2, 61.0)
	_pebble(Vector3(-0.95, 0.03, 0.45), 0.12, STONE_OW, V2, 62.0)
	_pebble(Vector3(-0.8, 0.03, -0.5), 0.09, STONE_OW_D, V2, 63.0)
	for i: int in 2:
		var a2: float = 2.3 + i * 0.7
		_frond(Vector3(cos(a2) * 0.9, 0.03, sin(a2) * 0.6), a2, 0.45, 0.3, 0.22, 0.17, 6, V2, 64.0 + i, FERN_D, FERN,
			FERN_L)
	_commit("ow_moss_boulders", nature_mat, {"wind_clamp": true})


# --- fallen trunks (nature_mat, bark kind; moss grows on the upward faces through the vertex colour) -------------

func _log(path: Array, radii: Array, sides: int, mask: int, seed: float, cap_start: bool, cap_end: bool,
		col: Color = BARK_OW, moss: float = 0.85) -> void:
	_part(_tube(path, radii, sides, false, false), Transform3D.IDENTITY, col, {"mask": mask, "normals": "smooth",
		"col2": col.lerp(BARK_GREY, 0.35), "moss_top": moss, "moss_lo": 0.45, "moss_cover": 0.42, "jitter": 0.018, "seed": seed, "tint": 0.1,
		"clip_y": -0.02})
	if cap_start:
		_end_grain(path[0], (path[0] as Vector3) - (path[1] as Vector3), radii[0], sides, mask, false)
	if cap_end:
		var k: int = path.size() - 1
		_end_grain(path[k], (path[k] as Vector3) - (path[k - 1] as Vector3), radii[k], sides, mask, false)


## A cut / broken end: rings of end grain (or a dark rotten hollow when `hollow`).
func _end_grain(c: Vector3, dirv: Vector3, r: float, sides: int, mask: int, hollow: bool, old: bool = false) -> void:
	var d: Vector3 = dirv.normalized()
	var x: Vector3 = d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var y: Vector3 = d.cross(x).normalized()
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	# Old cuts (stumps weathered for years) are grey-brown, not fresh tan: no bright "eye" from the game camera.
	var grain: Color = END_GRAIN.lerp(BARK_GREY, 0.6).darkened(0.1) if old else END_GRAIN
	var ring: Color = END_RING.lerp(BARK_GREY, 0.5).darkened(0.15) if old else END_RING
	var rings: Array = [[0.0, ROT if hollow else ring, -0.12 if hollow else 0.0],
		[0.45, ROT if hollow else grain, -0.08 if hollow else 0.0],
		[0.72, ring if hollow else grain.darkened(0.08), 0.0], [1.0, BARK_OW_D, 0.0]]
	v.append(c + d * float(rings[0][2]))
	n.append(d)
	cols.append(rings[0][1])
	for ri: int in range(1, rings.size()):
		for k: int in sides:
			var a: float = TAU * k / sides
			v.append(c + (x * cos(a) + y * sin(a)) * r * float(rings[ri][0]) + d * float(rings[ri][2]))
			n.append(d)
			cols.append(rings[ri][1])
	for k: int in sides:
		idx.append_array([0, 1 + k, 1 + (k + 1) % sides])
	for ri: int in range(1, rings.size() - 1):
		var b0: int = 1 + (ri - 1) * sides
		var b1: int = b0 + sides
		for k: int in sides:
			var k1: int = (k + 1) % sides
			idx.append_array([b0 + k, b1 + k, b0 + k1, b0 + k1, b1 + k, b1 + k1])
	_part(_mk(v, n, idx, cols), Transform3D.IDENTITY, END_GRAIN, {"mask": mask, "normals": "flat", "tint": 0.06})


## A jagged snapped end: splinters pointing along `dirv` around the rim.
func _splinters(c: Vector3, dirv: Vector3, r: float, count: int, mask: int, seed: float) -> void:
	var d: Vector3 = dirv.normalized()
	var x: Vector3 = d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var y: Vector3 = d.cross(x).normalized()
	for i: int in count:
		var a: float = TAU * i / count + _h(Vector3(seed, i, 1)) * 0.5
		var rr: float = r * (0.55 + 0.35 * _h(Vector3(seed, i, 2)))
		var p: Vector3 = c + (x * cos(a) + y * sin(a)) * rr - d * 0.04
		var ln: float = 0.1 + 0.28 * _h(Vector3(seed, i, 3))
		_part(_spindle(p, p + d * ln + (x * cos(a) + y * sin(a)) * 0.03, r * 0.22, 0.15, 4), Transform3D.IDENTITY,
			END_GRAIN.lerp(BARK_OW, 0.35), {"mask": mask, "normals": "flat", "tint": 0.12})


func _bracket(c: Vector3, outv: Vector3, r: float, col: Color, mask: int, seed: float) -> void:
	var yaw: float = atan2(outv.x, outv.z)
	_part(_sph(1.0, 6, 3), _xf(c + outv.normalized() * r * 0.45, Vector3(0.0, yaw, 0.0), Vector3(r, r * 0.22, r * 0.75)),
		col.darkened(0.2), {"mask": mask, "normals": "smooth", "col2": col, "seed": seed})


func _build_fallen_trunk() -> void:
	_begin()
	# V0: a long fallen trunk (4.3 m) with its upturned root plate, branch stubs, bracket fungi and ferns.
	var p0: Array = [Vector3(-1.85, 0.34, 0.0), Vector3(-0.9, 0.31, 0.05), Vector3(0.2, 0.28, -0.04),
		Vector3(1.25, 0.24, 0.03), Vector3(2.2, 0.2, 0.0)]
	_log(p0, [0.36, 0.33, 0.3, 0.27, 0.23], 9, V0, 1.0, false, true)
	# Root plate: a vertical disc of earth and roots torn out of the ground (to 1.25 m).
	_part(_cyl(0.72, 0.72, 0.24, 11), _xf(Vector3(-2.02, 0.5, 0.0), Vector3(0.0, 0.0, PI * 0.5), Vector3(1.0, 1.0, 1.1)),
		EARTH, {"mask": V0, "normals": "smooth", "col2": EARTH.darkened(0.25), "jitter": 0.07, "seed": 2.0,
		"clip_y": -0.02, "tint": 0.14})
	for i: int in 7:
		var a: float = i * TAU / 7.0 + 0.3
		var dirv := Vector3(0.0, sin(a), cos(a))
		var st: Vector3 = Vector3(-2.1, 0.5, 0.0) + dirv * 0.55
		var tip: Vector3 = st + dirv * (0.28 + 0.2 * _h(Vector3(i, 1, 9))) + Vector3(-0.3, 0.0, 0.0)
		if tip.y < 0.02:
			tip.y = 0.02
		_part(_tube([st, st.lerp(tip, 0.5) + Vector3(-0.08, 0.05, 0.0), tip], [0.07, 0.045, 0.0], 4),
			Transform3D.IDENTITY, ROOT_D, {"mask": V0, "normals": "smooth", "col2": ROOT, "seed": 3.0 + i,
			"clip_y": -0.02})
	# Branch stubs.
	_part(_tube([Vector3(-0.4, 0.5, 0.05), Vector3(-0.28, 0.82, 0.12), Vector3(-0.2, 1.0, 0.16)], [0.09, 0.06, 0.0], 5),
		Transform3D.IDENTITY, BARK_OW, {"mask": V0, "normals": "smooth", "col2": BARK_GREY, "seed": 12.0})
	_part(_tube([Vector3(0.95, 0.35, -0.2), Vector3(1.05, 0.52, -0.55), Vector3(1.1, 0.6, -0.72)], [0.07, 0.05, 0.0], 5),
		Transform3D.IDENTITY, BARK_OW, {"mask": V0, "normals": "smooth", "col2": BARK_GREY, "seed": 13.0})
	_bracket(Vector3(0.1, 0.3, 0.28), Vector3(0, 0, 1), 0.14, FUNGUS, V0, 14.0)
	_bracket(Vector3(0.32, 0.22, 0.29), Vector3(0.2, 0, 1), 0.1, FUNGUS, V0, 15.0)
	_bracket(Vector3(-0.95, 0.42, -0.3), Vector3(0, 0, -1), 0.12, FUNGUS_O, V0, 16.0)
	for i: int in 3:
		var a2: float = 1.2 + i * 0.6
		_frond(Vector3(0.7, 0.03, 0.4), a2, 0.55, 0.42, 0.3, 0.18, 6, V0, 17.0 + i, FERN_D, FERN, FERN_L)
	# V1: broken in two: a snapped piece with splinters and a second piece with a hollow, rotten end; ferns between.
	var p1a: Array = [Vector3(-2.05, 0.32, -0.05), Vector3(-1.2, 0.3, 0.0), Vector3(-0.35, 0.29, 0.03)]
	_log(p1a, [0.34, 0.33, 0.31], 9, V1, 20.0, true, false)
	_splinters(Vector3(-0.35, 0.29, 0.03), Vector3(1, 0, 0), 0.31, 7, V1, 21.0)
	_end_grain(Vector3(-0.3, 0.29, 0.03), Vector3(1, 0, 0), 0.26, 9, V1, false)
	var p1b: Array = [Vector3(0.25, 0.27, 0.25), Vector3(1.05, 0.26, 0.4), Vector3(1.95, 0.25, 0.55)]
	_log(p1b, [0.3, 0.29, 0.28], 9, V1, 22.0, false, false, BARK_OW.lerp(BARK_GREY, 0.2))
	_splinters(Vector3(0.25, 0.27, 0.25), Vector3(-1, 0, -0.15), 0.27, 6, V1, 23.0)
	_end_grain(Vector3(1.95, 0.25, 0.55), Vector3(1, 0, 0.17), 0.28, 9, V1, true)
	_end_grain(Vector3(0.22, 0.27, 0.245), Vector3(-1, 0, -0.17), 0.24, 9, V1, false)
	_bracket(Vector3(1.2, 0.3, 0.12), Vector3(-0.1, 0, -1), 0.13, FUNGUS_O, V1, 24.0)
	for i: int in 4:
		var a3: float = -0.8 + i * 1.3
		_frond(Vector3(-0.05, 0.03, 0.1), a3, 0.55, 0.55, 0.3, 0.19, 6, V1, 25.0 + i, FERN_D, FERN, FERN_TIP)
	# V2: a snapped standing stump (1.1 m) with its fallen top leaning on it.
	_part(_tube([Vector3(1.55, -0.04, 0.0), Vector3(1.55, 0.2, 0.0), Vector3(1.57, 0.95, 0.02)], [0.46, 0.38, 0.33], 9,
		false, false), Transform3D.IDENTITY, BARK_OW, {"mask": V2, "normals": "smooth", "col2": BARK_OW.lerp(BARK_GREY, 0.4),
		"moss_top": 0.6, "jitter": 0.02, "seed": 30.0, "clip_y": -0.02})
	_splinters(Vector3(1.57, 0.95, 0.02), Vector3(0, 1, 0), 0.33, 8, V2, 31.0)
	_end_grain(Vector3(1.57, 0.97, 0.02), Vector3(0, 1, 0), 0.27, 9, V2, true)
	for i: int in 5:
		var a4: float = i * TAU / 5.0 + 0.4
		var dv := Vector3(cos(a4), 0.0, sin(a4))
		_part(_tube([Vector3(1.55, 0.3, 0.0) + dv * 0.3, Vector3(1.55, 0.08, 0.0) + dv * 0.62,
			Vector3(1.55, -0.04, 0.0) + dv * 0.85], [0.12, 0.07, 0.0], 5), Transform3D.IDENTITY, BARK_OW_D,
			{"mask": V2, "normals": "smooth", "col2": ROOT, "moss_top": 0.5, "seed": 32.0 + i, "clip_y": -0.02})
	var p2: Array = [Vector3(-2.2, 0.26, -0.1), Vector3(-1.1, 0.46, -0.05), Vector3(0.1, 0.7, 0.0),
		Vector3(1.2, 0.95, 0.0)]
	_log(p2, [0.3, 0.29, 0.27, 0.25], 9, V2, 33.0, true, false, BARK_OW.lerp(BARK_GREY, 0.15), 0.9)
	_splinters(Vector3(1.2, 0.95, 0.0), Vector3(1, 0.2, 0), 0.24, 6, V2, 34.0)
	_bracket(Vector3(-0.6, 0.5, 0.26), Vector3(0, 0, 1), 0.12, FUNGUS, V2, 35.0)
	_commit("ow_fallen_trunk", nature_mat, {"wind_clamp": true})


# --- surface roots (nature_mat, bark kind, moss on the tops) ------------------------------------------------------

## A root running along the ground from `a` to `b`, arching `hump` metres up in the middle (dives in at both ends).
func _root(a: Vector3, b: Vector3, hump: float, r0: float, r1: float, mask: int, seed: float, bends: int = 5,
		col: Color = ROOT) -> void:
	var pts: Array = []
	var radii: Array = []
	var side: Vector3 = (b - a).cross(Vector3.UP).normalized()
	for i: int in bends + 1:
		var t: float = float(i) / bends
		var h: float = -0.06 + (hump + 0.06) * pow(sin(PI * t), 0.8)
		var wob: float = sin(t * 7.0 + seed) * 0.08 * (1.0 - absf(t - 0.5) * 2.0 + 0.3)
		pts.append(a.lerp(b, t) + side * wob + Vector3(0, h, 0))
		radii.append(lerpf(r0, r1, t))
	_part(_tube(pts, radii, 6), Transform3D.IDENTITY, col, {"mask": mask, "normals": "smooth", "col2": ROOT_D,
		"moss_top": 0.7, "moss_lo": 0.5, "moss_cover": 0.3, "jitter": 0.012, "seed": seed, "clip_y": -0.01, "tint": 0.1})


func _build_roots() -> void:
	_begin()
	# V0: three arching surface roots fanning out (1.9 m), as if from a big tree just off the patch.
	_root(Vector3(-1.0, 0.0, -0.1), Vector3(1.05, 0.0, 0.0), 0.3, 0.2, 0.09, V0, 1.0)
	_root(Vector3(-0.95, 0.0, 0.0), Vector3(0.6, 0.0, 0.8), 0.22, 0.17, 0.07, V0, 2.0, 4)
	_root(Vector3(-0.95, 0.0, -0.1), Vector3(0.4, 0.0, -0.85), 0.18, 0.15, 0.06, V0, 3.0, 4, ROOT.darkened(0.1))
	# V1: a knot of thick roots crossing over each other around a low, weathered stump stub (grey cut, no bright eye).
	_root(Vector3(-0.95, 0.0, -0.35), Vector3(0.85, 0.0, 0.4), 0.36, 0.2, 0.11, V1, 10.0, 5)
	_root(Vector3(-0.6, 0.0, 0.7), Vector3(0.75, 0.0, -0.55), 0.27, 0.18, 0.09, V1, 11.0, 5, ROOT.darkened(0.08))
	_root(Vector3(0.15, 0.0, -0.9), Vector3(-0.25, 0.0, 0.8), 0.2, 0.15, 0.07, V1, 12.0, 4)
	_part(_tube([Vector3(-0.05, -0.04, 0.02), Vector3(-0.05, 0.12, 0.02), Vector3(-0.04, 0.3, 0.03)], [0.3, 0.25, 0.22],
		8, false, false), Transform3D.IDENTITY, BARK_OW, {"mask": V1, "normals": "smooth", "col2": BARK_GREY,
		"moss_top": 0.5, "jitter": 0.025, "seed": 13.0, "clip_y": -0.01})
	_end_grain(Vector3(-0.04, 0.3, 0.03), Vector3(0.2, 1, 0.1), 0.22, 8, V1, false, true)
	# V2: a serpentine root looping over a stone, and a thinner side root.
	_root(Vector3(-1.05, 0.0, 0.2), Vector3(-0.1, 0.0, 0.0), 0.22, 0.17, 0.14, V2, 20.0, 4)
	_root(Vector3(-0.2, 0.0, 0.0), Vector3(0.75, 0.0, -0.15), 0.5, 0.14, 0.11, V2, 21.0, 5)
	_root(Vector3(0.65, 0.0, -0.15), Vector3(1.15, 0.0, 0.3), 0.12, 0.11, 0.05, V2, 22.0, 3)
	_root(Vector3(-0.5, 0.0, 0.1), Vector3(-0.1, 0.0, 0.8), 0.13, 0.1, 0.04, V2, 23.0, 3, ROOT.darkened(0.12))
	_rock(Vector3(0.24, 0.2, 0.22), Vector3(0.27, 0.06, -0.08), Vector3(0.1, 0.6, 0.0), STONE_OW, V2, 24.0, 1.0, 3, 0.8,
		6, 4)
	_commit("ow_roots", nature_mat, {"wind_clamp": true})


# --- cobweb cards (old_wood_web_mat: twigs opaque, webs procedural; UV2.y = Web kind) -----------------------------

func _twig(path: Array, radii: Array, mask: int, seed: float) -> void:
	_part(_tube(path, radii, 4), Transform3D.IDENTITY, TWIG, {"kind": Web.TWIG, "mask": mask, "normals": "smooth",
		"col2": TWIG_L, "jitter": 0.006, "seed": seed, "clip_y": -0.01})


## A web card: a fan from the hub to the anchor points (rim), with a middle ring that sags a little. UV = card
## coordinates (hub 0, rim at length 1, angle = the anchor's angle in the web plane).
func _web(hub: Vector3, rim: Array, kind: int, mask: int, sag: float = 0.03) -> void:
	var cnt: int = rim.size()
	var nrm := Vector3.ZERO
	for i: int in cnt:
		nrm += ((rim[i] as Vector3) - hub).cross((rim[(i + 1) % cnt] as Vector3) - hub)
	nrm = nrm.normalized()
	var ax: Vector3 = (rim[0] as Vector3) - hub
	ax = (ax - nrm * ax.dot(nrm)).normalized()
	var ay: Vector3 = nrm.cross(ax)
	var rim_uv: Array[Vector2] = []
	var mids: Array[Vector3] = []
	for i: int in cnt:
		var q: Vector3 = (rim[i] as Vector3) - hub
		var ang: float = atan2(q.dot(ay), q.dot(ax))
		rim_uv.append(Vector2(cos(ang), sin(ang)))
		mids.append(hub + q * 0.5 + Vector3(0, -sag * q.length(), 0))
	var tris: Array = []
	for i: int in cnt:
		var j: int = (i + 1) % cnt
		tris.append([[hub, Vector2.ZERO], [mids[i], rim_uv[i] * 0.5], [mids[j], rim_uv[j] * 0.5]])
		tris.append([[mids[i], rim_uv[i] * 0.5], [rim[i], rim_uv[i]], [rim[j], rim_uv[j]]])
		tris.append([[mids[i], rim_uv[i] * 0.5], [rim[j], rim_uv[j]], [mids[j], rim_uv[j] * 0.5]])
	for tri: Array in tris:
		for corner: Array in tri:
			_v.append(corner[0])
			_n.append(nrm)
			_c.append(WEB_TINT)
			_ux.append((corner[1] as Vector2).x)
			_uy.append((corner[1] as Vector2).y)
			_uv2.append(Vector2(mask, kind))


func _build_cobwebs() -> void:
	_begin()
	# V0: a dead snag (1.3 m) with forked twigs and an orb web between them, a small web low down.
	var s0: Array = [Vector3(0, -0.02, 0), Vector3(0.03, 0.45, 0.01), Vector3(0.0, 0.9, 0.04), Vector3(0.05, 1.3, 0.02)]
	_twig(s0, [0.055, 0.04, 0.028, 0.0], V0, 1.0)
	var t1a := Vector3(0.03, 0.5, 0.01)
	var t1b := Vector3(0.48, 0.92, 0.1)
	_twig([t1a, Vector3(0.25, 0.74, 0.05), t1b], [0.025, 0.018, 0.0], V0, 2.0)
	var t2a := Vector3(0.01, 0.95, 0.04)
	var t2b := Vector3(0.42, 1.28, 0.08)
	_twig([t2a, t2b], [0.018, 0.0], V0, 3.0)
	var t3b := Vector3(-0.36, 0.5, -0.02)
	_twig([Vector3(0.02, 0.34, 0.01), Vector3(-0.2, 0.46, -0.01), t3b], [0.02, 0.014, 0.0], V0, 4.0)
	_web(Vector3(0.22, 0.95, 0.06), [Vector3(0.02, 0.62, 0.02), Vector3(0.36, 0.84, 0.08), t1b, t2b,
		Vector3(0.02, 1.22, 0.03)], Web.ORB, V0)
	_web(Vector3(-0.13, 0.22, -0.01), [Vector3(0.02, 0.05, 0.0), Vector3(0.03, 0.33, 0.01), Vector3(-0.2, 0.45, -0.01), t3b,
		Vector3(-0.34, 0.02, -0.03)], Web.SHEET, V0, 0.04)
	# V1: a bramble hoop (two dead arching stems) with an orb web filling the hoop and a sheet web at its foot.
	var arch: Array = [Vector3(-0.5, -0.02, 0.0), Vector3(-0.48, 0.4, 0.02), Vector3(-0.3, 0.76, 0.03),
		Vector3(0.05, 0.9, 0.02), Vector3(0.36, 0.7, 0.0), Vector3(0.48, 0.3, -0.02), Vector3(0.52, -0.02, 0.0)]
	_twig(arch, [0.035, 0.03, 0.026, 0.022, 0.02, 0.018, 0.015], V1, 10.0)
	_twig([Vector3(-0.15, -0.02, 0.2), Vector3(0.1, 0.42, 0.18), Vector3(0.35, 0.55, 0.12), Vector3(0.62, 0.34, 0.1)],
		[0.022, 0.018, 0.014, 0.0], V1, 11.0)
	_web(Vector3(0.0, 0.42, 0.02), [arch[1], arch[2], arch[3], arch[4], arch[5], Vector3(0.32, 0.03, 0.0),
		Vector3(-0.3, 0.03, 0.02)], Web.ORB, V1)
	_web(Vector3(0.28, 0.1, 0.25), [Vector3(0.1, 0.25, 0.18), Vector3(0.45, 0.28, 0.12), Vector3(0.7, 0.02, 0.35),
		Vector3(0.2, 0.02, 0.55), Vector3(-0.05, 0.02, 0.4)], Web.SHEET, V1, 0.05)
	# V2: a ground sheet web (1.1 m) slung between five stubby stalks, sagging toward a funnel.
	var stubs: Array[Vector3] = []
	for i: int in 5:
		var a: float = i * TAU / 5.0 + (_h(Vector3(i, 4, 4)) - 0.5) * 0.5
		var rr: float = 0.5 + 0.08 * _h(Vector3(i, 4, 5))
		var hh: float = 0.2 + 0.18 * _h(Vector3(i, 4, 6))
		var base := Vector3(cos(a) * rr, -0.02, sin(a) * rr)
		var tip: Vector3 = base + Vector3(cos(a) * 0.06, hh, sin(a) * 0.06)
		_twig([base, tip], [0.02, 0.008], V2, 20.0 + i)
		stubs.append(tip)
	var rim: Array = []
	for i: int in 5:
		rim.append(stubs[i])
		var m: Vector3 = (stubs[i] + stubs[(i + 1) % 5]) * 0.5 * 1.05
		m.y = 0.03
		rim.append(m)
	_web(Vector3(0.03, 0.12, -0.02), rim, Web.SHEET, V2, 0.06)
	_web(Vector3(0.3, 0.22, 0.28), [stubs[0], stubs[1], Vector3(0.35, 0.02, 0.35)], Web.ORB, V2)
	_commit("ow_cobwebs", web_mat, {"grad_min": 0.2})
