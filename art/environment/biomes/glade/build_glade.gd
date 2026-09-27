extends SceneTree
## Task 12.V11 (map-fill.md 3.1 biome 7 "Wildflower Glade" + section 10): generates the glade scatter meshes with the
## SHARED painted nature material (art/environment/nature_props/nature_mat.tres + nature_contact_mat.tres, loaded,
## never re-saved). One mesh per decor kind (3 kinds: the 24-kind map budget is tight), 3 shape variants in each
## through the variant mask (UV2.x): the shader picks the variant from a hash of the instance position, so one
## MultiMesh shows 3 shapes.
##   glade_tall_grass.res       tall wild grass clump ~1.1 m wide, <= 0.75 m tall (V0 upright + straw foxtails,
##                              V1 wide arching fountain with cool tips, V2 wind-bent + bronze-pink plumes)
##   glade_flowers.res          wildflower cluster ~1 m, 4 colours over the 3 variants (V0 red poppies + yellow
##                              buttercups, V1 blue cornflowers + pink campion, V2 pink campion + blue + yellow)
##   glade_butterfly_bush.res   arching sage-green shrub ~1.4 m with long flower spikes (V0 lilac, V1 magenta,
##                              V2 white) and two resting butterflies + a soft contact disc (surface 1)
## Readability (the glade is the midfield where armies fight): the tall grass is olive / straw, a little LESS
## saturated than the lawn and far less than the Nature kingdom's green, and stays under a worker's shoulders;
## flowers are small bright specks in drifts (never a solid colour field); bushes are rare (gap 4 m).
## Vertex data follows nature_painted.gdshader: COLOR.rgb colour, COLOR.a height gradient, UV.x wind weight
## (clamp(y * k, 0, 0.45) with one k per mesh, so touching parts never tear), UV.y local height + a lift on flower
## heads (the shader's dark contact band stays on stems and blade roots), UV2 = (variant mask, kind). Kinds are only
## bark (0) and ivy (5: foliage without autumn). Every mesh is indexed (welded). No lights, no textures, no runtime
## materials.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/glade/build_glade.gd --quit-after 600

const DIR := "res://art/environment/biomes/glade/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45
const GOLDEN := 2.39996

# Palette (sRGB). Tall grass: olive / straw, close in value to the lawn (ground.gdshader grass_dark / grass_light) so
# it reads as a calm texture, and less saturated than the lawn so units stay the most saturated thing on the ground.
const GR_D := Color(0.17, 0.28, 0.12)
const GR := Color(0.33, 0.43, 0.19)
const GR_L := Color(0.54, 0.60, 0.31)
const GR_STRAW := Color(0.70, 0.66, 0.39)
const GR_COOL := Color(0.42, 0.55, 0.38)
const FOXTAIL := Color(0.74, 0.65, 0.42)
const PLUME := Color(0.66, 0.50, 0.52)
# Wildflowers.
const STEM := Color(0.22, 0.38, 0.14)
const LEAF_D := Color(0.13, 0.28, 0.11)
const LEAF := Color(0.29, 0.45, 0.18)
const BUD := Color(0.36, 0.52, 0.20)
const POPPY_D := Color(0.58, 0.06, 0.08)
const POPPY := Color(0.92, 0.18, 0.15)
const POPPY_EYE := Color(0.10, 0.08, 0.10)
const CORN_D := Color(0.20, 0.20, 0.62)
const CORN := Color(0.33, 0.52, 0.97)
const CAMP_D := Color(0.70, 0.22, 0.50)
const CAMP := Color(0.97, 0.52, 0.76)
const CAMP_EYE := Color(0.99, 0.88, 0.93)
const BUTTER_D := Color(0.90, 0.60, 0.06)
const BUTTER := Color(1.00, 0.87, 0.24)
# Butterfly bush: deep green leaves with a slight cool sage cast (distinct from the meadow's warm fruit bush), dark
# enough that the flower spikes carry the read.
const BB_D := Color(0.08, 0.19, 0.11)
const BB := Color(0.19, 0.35, 0.19)
const BB_L := Color(0.40, 0.55, 0.32)
const BARK_C := Color(0.36, 0.28, 0.20)
## Flower spikes per bush variant: [base (shadowed, tight buds), tip (open, sunlit)].
const SPIKES := [[Color(0.38, 0.22, 0.60), Color(0.76, 0.60, 0.97)], [Color(0.55, 0.12, 0.38), Color(0.97, 0.48, 0.74)],
	[Color(0.62, 0.60, 0.70), Color(0.99, 0.97, 0.98)]]
## Resting butterflies per bush variant: [wing colour, wing-tip colour].
const WINGS := [[Color(0.98, 0.52, 0.10), Color(0.18, 0.09, 0.05)], [Color(0.99, 0.94, 0.56), Color(0.62, 0.55, 0.28)],
	[Color(0.45, 0.64, 0.99), Color(0.14, 0.18, 0.45)]]

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var _conv: float = 1.0
var _wind_k: float = 0.0   # wind weight per metre of height for the current mesh

# Current mesh (surface 0) and its contact disc (surface 1).
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()      # alpha < 0 = automatic height gradient at commit
var _uv := PackedVector2Array()   # (wind weight, local height + lift)
var _uv2 := PackedVector2Array()  # (variant mask, kind)
var _cv := PackedVector3Array()
var _cn := PackedVector3Array()
var _cuv := PackedVector2Array()
var _cuv2 := PackedVector2Array()
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_detect_winding()
	mat = load(NDIR + "nature_mat.tres") as ShaderMaterial
	contact_mat = load(NDIR + "nature_contact_mat.tres") as ShaderMaterial
	if mat == null or contact_mat == null:
		push_error("nature materials missing")
		quit(1)
		return
	_build_tall_grass()
	_build_flowers()
	_build_butterfly_bush()
	for line: String in _report:
		print(line)
	print("GLADE BUILD OK")
	quit()


# --- helpers -----------------------------------------------------------------------------------

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


## A transform whose local +Y points along `dir` (spikes, tilted heads), placed at `pos`.
func _along(pos: Vector3, dir: Vector3, spin: float = 0.0) -> Transform3D:
	var y: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Transform3D(Basis(x, y, z) * Basis(Vector3.UP, spin), pos)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _begin(wind_k: float) -> void:
	_wind_k = wind_k
	_v = PackedVector3Array()
	_n = PackedVector3Array()
	_c = PackedColorArray()
	_uv = PackedVector2Array()
	_uv2 = PackedVector2Array()
	_cv = PackedVector3Array()
	_cn = PackedVector3Array()
	_cuv = PackedVector2Array()
	_cuv2 = PackedVector2Array()


func _mk(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array,
		cols: PackedColorArray = PackedColorArray()) -> Array:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = idx
	if not cols.is_empty():
		arr[Mesh.ARRAY_COLOR] = cols
	return arr


func _sph(r: float, segs: int = 7, rings: int = 4) -> Array:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m.get_mesh_arrays()


## Adds mesh arrays, transformed (same option set as the meadow builder). Options (all optional):
##   kind (Kind, default IVY = foliage without autumn), mask (variant bits, 0 = always), jitter (m), seed, jit_axes,
##   normals: "flat" | "smooth" | "crown" (smooth, bent away from `crown`, squashed by crown_s, weight crown_k) |
##   "up" (flat leaves / petals: mostly straight up), col2 + grad ("y" part height | "wy" world height | "r" distance
##   from the part axis), ao_c + ao_r (darker toward a crown's core), tint (random value variation, default 0.08),
##   lift (metres added to UV.y: keeps the contact band off heads), a (fixed COLOR.a, default: height in the mesh),
##   wind (weight per metre, default the mesh's). Per-vertex colours in the arrays (ARRAY_COLOR) win over col / col2.
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var vc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.IVY)
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
	var tint: float = o.get("tint", 0.08)
	var lift: float = o.get("lift", 0.0)
	var alpha: float = o.get("a", -1.0)
	var wk: float = o.get("wind", _wind_k)
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
	var wminy: float = INF
	var wmaxy: float = -INF
	for p: Vector3 in tv:
		wminy = minf(wminy, p.y)
		wmaxy = maxf(wmaxy, p.y)
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
			var nn: Vector3 = fn
			if mode == "smooth":
				nn = tn[vi]
			elif mode == "crown":
				var cd: Vector3 = ((tv[vi] - crown) / crown_s).normalized()
				nn = tn[vi].lerp(cd, crown_k).normalized()
			elif mode == "up":
				nn = (tn[vi] * 0.25 + Vector3.UP).normalized()
			var cc: Color
			if not vc.is_empty():
				cc = vc[vi]
			else:
				var gt: float = 0.0
				if grad == "y":
					gt = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
				elif grad == "wy":
					gt = clampf((tv[vi].y - wminy) / maxf(wmaxy - wminy, 0.001), 0.0, 1.0)
				else:
					gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
				cc = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			if ao_r > 0.0:
				var d: Vector3 = (tv[vi] - ao_c) * Vector3(1.0, 1.3, 1.0)
				k *= lerpf(0.62, 1.04, smoothstep(0.30, 1.0, d.length() / ao_r))
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k, alpha))
			_uv.append(Vector2(clampf(tv[vi].y * wk, 0.0, WMAX), tv[vi].y + lift))
			_uv2.append(Vector2(mask, kind))


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
		for k: int in 3:
			_cv.append(tri[k])
			_cn.append(Vector3.UP)
			_cuv.append(Vector2(0.0 if tri[k] == centre else 1.0, 0.0))
			_cuv2.append(Vector2(mask, 0.0))


## Bakes the height gradient (COLOR.a, unless a part fixed it), welds, saves DIR/<name>.res (surface 0: nature_mat,
## surface 1: contact disc if any) and reports the triangles per variant.
func _commit(name: String) -> ArrayMesh:
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - miny, 0.01)
	for i: int in _v.size():
		var cc: Color = _c[i]
		if cc.a < 0.0:
			cc.a = clampf((_v[i].y - miny) / span, 0.0, 1.0)
		_c[i] = cc
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_TEX_UV] = _uv
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
	_save(mesh, DIR + name + ".res")
	var per := [0, 0, 0]
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-22s %4d tris, %4d verts (variants %d / %d / %d), contact %d, size %.2f x %.2f x %.2f" % [
		name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		_cv.size() / 3, aabb.size.x, aabb.size.y, aabb.size.z])
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


# --- shape builders (return arrays for _part) ----------------------------------------------------

## A grass blade / stem: a flattened 3-sided spike (visible from every side) in `segs` segments (1 = straight,
## 3 triangles; each extra segment adds 6). The centre line bends along `lean` (lean * t^2) and the tip drops by
## `droop` (* t^3), so long blades arch over. `face` = angle of the flat side, colours `c0` root -> `c1` tip.
func _blade(base: Vector3, h: float, w: float, lean: Vector3, face: float, c0: Color, c1: Color,
		segs: int = 2, droop: float = 0.0) -> Array:
	var side := Vector3(cos(face), 0.0, sin(face))
	var out := Vector3(-side.z, 0.0, side.x)
	var sec: Array[Vector3] = [side * w, -side * w, out * w * 0.4]
	var cen: Vector3 = (sec[0] + sec[1] + sec[2]) / 3.0
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for k: int in segs:
		var t: float = float(k) / segs
		var c: Vector3 = base + Vector3(0.0, h * t - droop * t * t * t, 0.0) + lean * t * t
		var wf: float = 1.0 - 0.62 * t
		for s: Vector3 in sec:
			v.append(c + s * wf)
			n.append(((s - cen).normalized() + Vector3(0.0, 0.25, 0.0)).normalized())
			cols.append(c0.lerp(c1, t))
	var tip: int = v.size()
	v.append(base + Vector3(0.0, h - droop, 0.0) + lean)
	n.append(Vector3.UP)
	cols.append(c1)
	for k: int in segs - 1:
		for i: int in 3:
			var j: int = (i + 1) % 3
			var a0: int = k * 3 + i
			var a1: int = k * 3 + j
			idx.append_array([a0, a1, a0 + 3, a1, a1 + 3, a0 + 3])
	var last: int = (segs - 1) * 3
	for i: int in 3:
		idx.append_array([last + i, last + (i + 1) % 3, tip])
	return _mk(v, n, idx, cols)


## A 3-sided double pyramid from `a` to `b` (seed heads, buds, plumes), radius `r` at `bulge` (0-1 along a -> b).
func _spindle(a: Vector3, b: Vector3, r: float, bulge: float, col_a: Color, col_b: Color) -> Array:
	var d: Vector3 = (b - a).normalized()
	var x: Vector3 = d.cross(Vector3.FORWARD if absf(d.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(d).normalized()
	var m: Vector3 = a + (b - a) * bulge
	var v := PackedVector3Array([a])
	var n := PackedVector3Array([-d])
	var cols := PackedColorArray([col_a])
	for i: int in 3:
		var ang: float = i * TAU / 3.0
		var rad: Vector3 = x * cos(ang) + z * sin(ang)
		v.append(m + rad * r)
		n.append(rad)
		cols.append(col_a.lerp(col_b, 0.6))
	v.append(b)
	n.append(d)
	cols.append(col_b)
	var idx := PackedInt32Array()
	for i: int in 3:
		var j: int = (i + 1) % 3
		idx.append_array([0, 1 + i, 1 + j, 4, 1 + j, 1 + i])
	return _mk(v, n, idx, cols)


## A flat fan (petal rings, wings): triangles from `centre` over the `rim` points (open fan unless `closed`).
## Normals are domed: up, bent outward by `dome` (0 = flat up).
func _fan(centre: Vector3, c_col: Color, rim: Array[Vector3], rim_cols: Array[Color], closed: bool,
		dome: float = 0.0) -> Array:
	var v := PackedVector3Array([centre])
	var n := PackedVector3Array([Vector3.UP])
	var cols := PackedColorArray([c_col])
	var idx := PackedInt32Array()
	for i: int in rim.size():
		v.append(rim[i])
		var o := Vector3(rim[i].x - centre.x, 0.0, rim[i].z - centre.z)
		n.append((Vector3.UP + o.normalized() * dome).normalized() if o.length() > 0.0001 else Vector3.UP)
		cols.append(rim_cols[i % rim_cols.size()])
	var last: int = rim.size() if closed else rim.size() - 1
	for i: int in last:
		idx.append_array([0, 1 + i, 1 + (i + 1) % rim.size()])
	return _mk(v, n, idx, cols)


## A lathe (surface of revolution around +Y) from (radius, height) profile points, bottom to top. A ring of radius
## ~0 closes that end (its triangles are degenerate and dropped). Outward normal hints.
func _lathe(profile: Array[Vector2], segs: int, phase: float = 0.0) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for p: Vector2 in profile:
		for i: int in segs:
			var a: float = i * TAU / segs + phase
			v.append(Vector3(cos(a) * p.x, p.y, sin(a) * p.x))
			n.append(Vector3(cos(a), 0.35, sin(a)).normalized())
	for ring: int in profile.size() - 1:
		for i: int in segs:
			var j: int = (i + 1) % segs
			var a0: int = ring * segs + i
			var a1: int = ring * segs + j
			var b0: int = (ring + 1) * segs + i
			var b1: int = (ring + 1) * segs + j
			idx.append_array([a0, a1, b0, a1, b1, b0])
	return _mk(v, n, idx)


# --- tall grass --------------------------------------------------------------------------------

func _build_tall_grass() -> void:
	_begin(0.66)
	# Shared core (every variant): 10 long blades arching out of the middle (3 segments: the arch shows up close).
	_clump(10, 0, 0.0, 0.10, 0.46, 0.60, 0.10, 0.24, 0.06, 0, GR_L, 0.044, 3, 1.0, Vector3.ZERO)
	# V0: an upright, dense clump (14 more blades, straw tips) with 5 foxtail seed heads standing above it.
	_clump(14, 10, 0.08, 0.24, 0.30, 0.46, 0.12, 0.28, 0.04, V0, GR_STRAW, 0.042, 2, 2.0, Vector3.ZERO)
	for k: int in 5:
		var a: float = 0.5 + k * GOLDEN
		var t: float = _h(Vector3(k, 2.0, 5.0))
		var base := Vector3(cos(a) * 0.05, -0.02, sin(a) * 0.05)
		var lean := Vector3(cos(a), 0.0, sin(a)) * (0.07 + 0.08 * t)
		var h: float = 0.50 + t * 0.06
		_part(_blade(base, h, 0.011, lean, a, GR_D, GR_L, 2), Transform3D.IDENTITY, GR, {"mask": V0,
			"normals": "smooth"})
		var tip: Vector3 = base + Vector3(0.0, h, 0.0) + lean
		var dir: Vector3 = (lean * 0.6 + Vector3(0.0, 0.14, 0.0)).normalized()
		_part(_spindle(tip - dir * 0.015, tip + dir * 0.13, 0.024, 0.45, FOXTAIL.darkened(0.3), FOXTAIL.lightened(0.12)),
			Transform3D.IDENTITY, FOXTAIL, {"mask": V0, "normals": "smooth", "lift": 0.3})
	# V1: a wide fountain: 14 long blades falling out and over in every direction, cool blue-green tips.
	_clump(14, 10, 0.06, 0.20, 0.40, 0.52, 0.34, 0.52, 0.20, V1, GR_COOL, 0.042, 2, 3.0, Vector3.ZERO)
	# V2: wind-bent (lodged) toward local +X, 13 blades, and 4 soft bronze-pink hair-grass plumes.
	_clump(13, 10, 0.06, 0.22, 0.30, 0.44, 0.16, 0.30, 0.10, V2, GR_STRAW.lerp(GR_L, 0.5), 0.042, 2, 4.0,
		Vector3(0.22, 0.0, 0.05))
	for k: int in 4:
		var a: float = -0.9 + k * 0.62
		var t: float = _h(Vector3(k, 4.0, 5.0))
		var base := Vector3(cos(a) * 0.06, -0.02, sin(a) * 0.06)
		var lean := Vector3(0.16 + 0.06 * t, 0.0, sin(a) * 0.12)
		var h: float = 0.44 + t * 0.08
		_part(_blade(base, h, 0.011, lean, a, GR_D, GR_STRAW, 2), Transform3D.IDENTITY, GR, {"mask": V2,
			"normals": "smooth"})
		var tip: Vector3 = base + Vector3(0.0, h, 0.0) + lean
		var dir: Vector3 = (lean.normalized() * 0.7 + Vector3(0.0, 0.5, 0.0)).normalized()
		for s: int in 2:   # two crossed spindles: a soft, open plume
			var off := Vector3(0.0, 0.0, 0.012 * (1 - 2 * s))
			_part(_spindle(tip - dir * 0.01 + off, tip + dir * (0.15 - 0.03 * s) + off, 0.045 - 0.01 * s, 0.35,
				PLUME.darkened(0.25), PLUME.lightened(0.18)), Transform3D.IDENTITY, PLUME, {"mask": V2,
				"normals": "smooth", "lift": 0.3})
	_commit("glade_tall_grass")


## `count` blades around the origin (golden-angle spiral from index `start`): inner blades tall and upright, outer
## ones shorter, leaning out and drooping. `bend` pushes every blade one way (wind-bent clumps).
func _clump(count: int, start: int, r0: float, r1: float, h0: float, h1: float, lean0: float, lean1: float,
		droop: float, mask: int, tip_col: Color, width: float, segs: int, seed: float, bend: Vector3) -> void:
	for i: int in count:
		var a: float = (start + i) * GOLDEN + seed * 0.37
		var t: float = _h(Vector3(i, seed, 1.0))
		var f: float = sqrt((i + 0.5) / count)   # 0 = centre, 1 = rim
		var r: float = lerpf(r0, r1, f)
		var p := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var hh: float = lerpf(h1, h0, clampf(f * 0.8 + (t - 0.5) * 0.4, 0.0, 1.0))
		var la: float = a + (t - 0.5) * 0.9
		var lean := Vector3(cos(la), 0.0, sin(la)) * lerpf(lean0, lean1, clampf(f + (t - 0.5) * 0.3, 0.0, 1.0))
		lean += bend * (0.7 + t * 0.6)
		var c0: Color = GR_D.lerp(GR, 0.25 + t * 0.35)
		var c1: Color = GR.lerp(tip_col, 0.45 + t * 0.55)
		_part(_blade(p, hh, width * (0.85 + t * 0.35), lean, a + PI * 0.5 + (t - 0.5) * 0.8, c0, c1, segs,
			droop * (0.6 + f * 0.8)), Transform3D.IDENTITY, c0, {"mask": mask, "normals": "crown",
			"crown": Vector3(0.0, -0.3, 0.0), "crown_k": 0.55, "tint": 0.06, "lift": 0.22})


# --- wildflowers -------------------------------------------------------------------------------

func _build_flowers() -> void:
	_begin(0.9)
	# Shared: a low base of 7 narrow leaves (every variant).
	for i: int in 7:
		var a: float = i * GOLDEN + 0.4
		var t: float = _h(Vector3(i, 7.0, 7.0))
		var p := Vector3(cos(a) * 0.12 * t, -0.01, sin(a) * 0.12 * t)
		var lean := Vector3(cos(a), 0.0, sin(a)) * (0.10 + 0.06 * t)
		_part(_blade(p, 0.15 + 0.08 * t, 0.024, lean, a + 1.4, LEAF_D, LEAF, 1), Transform3D.IDENTITY, LEAF,
			{"normals": "crown", "crown": Vector3(0.0, -0.2, 0.0), "crown_k": 0.5, "tint": 0.08, "lift": 0.15})
	# V0: red poppies + yellow buttercups. V1: blue cornflowers + pink campion. V2: pink campion + a few blue and
	# yellow (a mixed drift). Every variant also has 2 green buds.
	_drift(&"poppy", 9, 0, 0.0, 0.42, V0, 41.0, 0.30, 0.48)
	_drift(&"butter", 3, 9, 0.22, 0.44, V0, 42.0, 0.20, 0.28)
	_drift(&"bud", 2, 12, 0.10, 0.30, V0, 43.0, 0.34, 0.40)
	_drift(&"corn", 10, 0, 0.0, 0.42, V1, 51.0, 0.28, 0.44)
	_drift(&"campion", 3, 10, 0.22, 0.44, V1, 52.0, 0.30, 0.40)
	_drift(&"bud", 2, 13, 0.10, 0.30, V1, 53.0, 0.32, 0.38)
	_drift(&"campion", 8, 0, 0.0, 0.40, V2, 61.0, 0.30, 0.46)
	_drift(&"corn", 2, 8, 0.25, 0.44, V2, 62.0, 0.26, 0.34)
	_drift(&"butter", 2, 10, 0.25, 0.44, V2, 63.0, 0.20, 0.26)
	_drift(&"bud", 2, 12, 0.10, 0.30, V2, 64.0, 0.30, 0.36)
	_commit("glade_flowers")


## `count` flowers of one kind on a golden-angle spiral from index `start`: taller in the middle, leaning out at the
## rim, heads tilted outward a little (so a drift reads as a dome of colour from the high camera).
func _drift(kind: StringName, count: int, start: int, rmin: float, rmax: float, mask: int, seed: float,
		hmin: float, hmax: float) -> void:
	for i: int in count:
		var a: float = (start + i) * GOLDEN + seed * 0.13
		var t: float = _h(Vector3(i, seed, 3.0))
		var f: float = sqrt((i + 0.5) / count)
		var rr: float = lerpf(rmin, rmax, f)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var base: Vector3 = dir * rr * 0.7
		var lean: Vector3 = dir * (0.03 + rr * 0.2) + Vector3(cos(a * 3.1), 0.0, sin(a * 2.3)) * 0.02
		var h: float = lerpf(hmax, hmin, clampf(rr / 0.44, 0.0, 1.0)) * (0.9 + t * 0.2)
		var segs: int = 2 if kind == &"poppy" else 1   # poppies nod on long, curved stems
		_part(_blade(base, h, 0.011, lean, a + 1.2, STEM.darkened(0.25), STEM.lightened(0.05), segs),
			Transform3D.IDENTITY, STEM, {"mask": mask, "normals": "smooth"})
		var top: Vector3 = base + Vector3(0.0, h, 0.0) + lean
		var tilt := Basis(Vector3(-dir.z, 0.0, dir.x), -0.15 - 0.35 * clampf(rr / 0.44, 0.0, 1.0))
		var xf := Transform3D(tilt * Basis(Vector3.UP, t * 3.0), top)
		match kind:
			&"poppy":
				_cup(xf, 0.088 + t * 0.02, 5, POPPY_D, POPPY, 0.42, mask)
				_eye(xf, 0.022, 0.03, POPPY_EYE, POPPY_EYE.lightened(0.15), mask)
			&"butter":
				_cup(xf, 0.056 + t * 0.01, 5, BUTTER_D, BUTTER, 0.35, mask)
			&"corn":
				_cornflower(xf, 0.074 + t * 0.014, mask)
			&"campion":
				_campion(xf, 0.074 + t * 0.012, mask)
			&"bud":
				_part(_spindle(top - Vector3(0.0, 0.01, 0.0), top + tilt.y * 0.07, 0.022, 0.45, STEM, BUD),
					Transform3D.IDENTITY, STEM, {"mask": mask, "normals": "smooth", "lift": 0.3, "a": 1.0})


## A cup flower (poppy, buttercup; local +Y up): `petals` rounded petals whose rims curl up by `curl` x size, dark
## at the heart, bright at the rim.
func _cup(xf: Transform3D, size: float, petals: int, c_in: Color, c_out: Color, curl: float, mask: int) -> void:
	var rim: Array[Vector3] = []
	var cols: Array[Color] = []
	var n: int = petals * 2
	for i: int in n:
		var a: float = i * TAU / n
		var lobe: bool = i % 2 == 0
		var r: float = size if lobe else size * 0.76
		rim.append(Vector3(cos(a) * r, size * (curl if lobe else curl * 0.6), sin(a) * r))
		cols.append(c_out if lobe else c_out.lerp(c_in, 0.25))
	_part(_fan(Vector3.ZERO, c_in, rim, cols, true, -0.35), xf, c_out, {"mask": mask, "normals": "smooth",
		"lift": 0.4, "a": 1.0, "tint": 0.05})


## A small domed centre (poppy seed capsule).
func _eye(xf: Transform3D, r: float, h: float, c_edge: Color, c_top: Color, mask: int) -> void:
	var rim: Array[Vector3] = []
	for i: int in 5:
		var a: float = i * TAU / 5.0
		rim.append(Vector3(cos(a) * r, h * 0.3, sin(a) * r))
	_part(_fan(Vector3(0.0, h, 0.0), c_top, rim, [c_edge] as Array[Color], true, 0.8), xf, c_top, {"mask": mask,
		"normals": "smooth", "lift": 0.45, "a": 1.0, "tint": 0.03})


## A cornflower head: a ragged 14-point star, dark violet-blue heart -> bright blue frayed tips, a little domed.
func _cornflower(xf: Transform3D, size: float, mask: int) -> void:
	var rim: Array[Vector3] = []
	var cols: Array[Color] = []
	for i: int in 14:
		var a: float = i * TAU / 14.0
		var tip: bool = i % 2 == 0
		var r: float = size if tip else size * 0.60
		rim.append(Vector3(cos(a) * r, -size * 0.10 if tip else size * 0.05, sin(a) * r))
		cols.append(CORN if tip else CORN.lerp(CORN_D, 0.35))
	_part(_fan(Vector3(0.0, size * 0.28, 0.0), CORN_D, rim, cols, true, 0.5), xf, CORN, {"mask": mask,
		"normals": "smooth", "lift": 0.4, "a": 1.0, "tint": 0.05})


## A campion head: 5 notched pink petals, a pale heart.
func _campion(xf: Transform3D, size: float, mask: int) -> void:
	var rim: Array[Vector3] = []
	var cols: Array[Color] = []
	for k: int in 5:
		var c: float = k * TAU / 5.0
		for q: Vector2 in [Vector2(-0.30, 1.0), Vector2(0.0, 0.80), Vector2(0.30, 1.0), Vector2(0.63, 0.34)]:
			var a: float = c + q.x
			rim.append(Vector3(cos(a) * size * q.y, size * 0.12 * q.y, sin(a) * size * q.y))
			cols.append(CAMP if q.y > 0.5 else CAMP_D.lerp(CAMP, 0.4))
	_part(_fan(Vector3(0.0, size * 0.05, 0.0), CAMP_EYE, rim, cols, true, -0.2), xf, CAMP, {"mask": mask,
		"normals": "smooth", "lift": 0.4, "a": 1.0, "tint": 0.05})


# --- butterfly bush ----------------------------------------------------------------------------

func _build_butterfly_bush() -> void:
	_begin(0.22)
	var crown := Vector3(0.0, 0.62, 0.0)
	var bo := {"normals": "crown", "crown": crown, "crown_k": 0.55, "crown_s": Vector3(1.0, 0.62, 1.0),
		"grad": "y", "ao_c": crown, "ao_r": 1.0, "jitter": 0.03, "tint": 0.12}
	# Woody base (every variant): 4 short stems fanning out of the root.
	for i: int in 4:
		var a: float = i * TAU / 4.0 + 0.4
		var d := Vector3(cos(a), 0.0, sin(a))
		_part(_blade(d * 0.05 + Vector3(0.0, -0.02, 0.0), 0.46, 0.032, d * 0.24, a + 1.3, BARK_C.darkened(0.3), BARK_C,
			2), Transform3D.IDENTITY, BARK_C, {"kind": Kind.BARK, "normals": "smooth", "tint": 0.05})
	# Core leaf mass (every variant).
	_blob(Vector3(0.0, 0.58, 0.0), 0.42, 0, 80.0, bo, 8, 4)
	# Per variant: 5 arching branches [angle, reach, height, drop]: a leaf mass half-way out, a smaller one at the end
	# (lower by `drop`), and a flower panicle nodding out of the end one; V0 a classic fountain, V1 an upright vase,
	# V2 a low wide mound.
	var arcs: Array = [
		[[0.3, 0.64, 0.80, 0.16], [1.55, 0.60, 0.74, 0.18], [2.8, 0.66, 0.84, 0.14], [4.05, 0.58, 0.72, 0.18],
			[5.25, 0.62, 0.78, 0.16]],
		[[0.9, 0.42, 0.98, 0.04], [2.15, 0.46, 0.90, 0.06], [3.4, 0.40, 1.02, 0.04], [4.65, 0.46, 0.92, 0.06],
			[5.9, 0.42, 0.96, 0.05]],
		[[0.0, 0.70, 0.66, 0.16], [1.25, 0.74, 0.62, 0.18], [2.5, 0.68, 0.68, 0.16], [3.75, 0.74, 0.64, 0.18],
			[5.0, 0.70, 0.66, 0.16]],
	]
	# Panicle pose per variant: [outward, upward, droop].
	var pose: Array = [[0.55, 0.85, 0.20], [0.30, 1.0, 0.06], [0.42, 0.95, 0.16]]
	for vi: int in 3:
		var mask: int = 1 << vi
		var list: Array = arcs[vi]
		var cols: Array = SPIKES[vi]
		var ps: Array = pose[vi]
		var tips: Array[Vector3] = []
		for bi: int in list.size():
			var arc: Array = list[bi]
			var a: float = arc[0]
			var d := Vector3(cos(a), 0.0, sin(a))
			var reach: float = arc[1]
			var h: float = arc[2]
			var pa: Vector3 = d * reach * 0.5 + Vector3(0.0, h, 0.0)
			var pb: Vector3 = d * reach + Vector3(0.0, h - float(arc[3]), 0.0)
			_blob(pa, 0.30, mask, 81.0 + vi * 7 + bi, bo, 7, 4)
			_blob(pb, 0.21, mask, 101.0 + vi * 7 + bi, bo, 6, 3)
			var t: float = _h(Vector3(bi, vi, 9.0))
			var sd: Vector3 = (d * float(ps[0]) + Vector3(0.0, float(ps[1]), 0.0)).normalized()
			var base: Vector3 = pb + (d * 0.35 + Vector3(0.0, 1.0, 0.0)).normalized() * 0.17
			var length: float = 0.54 + t * 0.10
			_part(_panicle(base, sd, length, 0.105, float(ps[2]), cols[0] as Color, cols[1] as Color, 5, 5, t * 3.0),
				Transform3D.IDENTITY, cols[1] as Color, {"mask": mask, "normals": "smooth", "lift": 0.4, "a": 1.0,
				"tint": 0.06, "jitter": 0.02, "seed": 110.0 + bi + vi * 10})
			tips.append(base + sd * length * 0.55 + Vector3(0.0, -float(ps[2]) * 0.3, 0.0))
			# Every other branch: a second, shorter panicle out of the mid mass, more upright.
			if bi % 2 == 0:
				var sd2: Vector3 = (d * float(ps[0]) * 0.6 + Vector3(0.0, float(ps[1]) + 0.35, 0.0)).normalized()
				var b2: Vector3 = pa + (d * 0.4 + Vector3(0.0, 0.9, 0.0)).normalized() * 0.25
				_part(_panicle(b2, sd2, 0.42 + t * 0.08, 0.09, float(ps[2]) * 0.5, cols[0] as Color, cols[1] as Color, 5,
					5, t * 5.0), Transform3D.IDENTITY, cols[1] as Color, {"mask": mask, "normals": "smooth", "lift": 0.4,
					"a": 1.0, "tint": 0.06, "jitter": 0.02, "seed": 130.0 + bi + vi * 10})
		# Two butterflies resting on panicles (wings open in a shallow V, flutter with the leaves).
		var wc: Array = WINGS[vi]
		for b: int in 2:
			var bp: Vector3 = tips[(b * 2 + 1 + vi) % tips.size()] + Vector3(0.0, 0.07, 0.0)
			_butterfly(bp, vi * 1.7 + b * 2.2, 0.95 + 0.15 * b, wc[0] as Color, wc[1] as Color, mask)
	_disc(Vector3.ZERO, 1.0, 1.0, 12, 95.0)
	_commit("glade_butterfly_bush")


func _blob(c: Vector3, r: float, mask: int, seed: float, bo: Dictionary, segs: int, rings: int) -> void:
	var o: Dictionary = bo.duplicate()
	o["mask"] = mask
	o["seed"] = seed
	o["col2"] = BB_L
	var dark: Color = BB_D.lerp(BB, clampf(0.25 + c.y * 0.9, 0.0, 1.0))
	_part(_sph(r, segs, rings), _xf(c, Vector3(0.0, seed, 0.0), Vector3(1.0, 0.82, 1.0)), dark, o)


## A nodding flower panicle (butterfly bush): `rings` rings of `segs` sides along a curve from `base` along `dir`
## (length `len`, the tip dropping by `droop`), swelling near the base and tapering to a point. Every other ring is
## fatter and twisted (floret whorls), and a shade darker, so it reads as a spike of tiny flowers, not a smooth cone.
func _panicle(base: Vector3, dir: Vector3, len: float, r: float, droop: float, c_dark: Color, c_light: Color,
		segs: int, rings: int, phase: float) -> Array:
	var d: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT
	var x: Vector3 = d.cross(ref).normalized()
	var z: Vector3 = x.cross(d).normalized()
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for k: int in rings:
		var t: float = float(k) / rings
		var c: Vector3 = base + d * len * t + Vector3(0.0, -droop * t * t, 0.0)
		var rad: float = r * lerpf(0.6, 1.0, minf(t * 4.0, 1.0)) * (1.0 - t * 0.55) * (1.24 if k % 2 == 1 else 0.84)
		var col: Color = c_dark.lerp(c_light, 0.45 + t * 0.55) * (0.8 if k % 2 == 0 else 1.0)
		for i: int in segs:
			var a: float = i * TAU / segs + phase + k * 0.55
			var o: Vector3 = x * cos(a) + z * sin(a)
			v.append(c + o * rad)
			n.append((o + d * 0.2).normalized())
			cols.append(Color(col.r, col.g, col.b))
	var tip: int = v.size()
	v.append(base + d * len * 0.94 + Vector3(0.0, -droop * 0.9, 0.0))   # a blunt, rounded tip
	n.append(d)
	cols.append(c_light)
	for k: int in rings - 1:
		for i: int in segs:
			var j: int = (i + 1) % segs
			var a0: int = k * segs + i
			var a1: int = k * segs + j
			idx.append_array([a0, a1, a0 + segs, a1, a1 + segs, a0 + segs])
	var last: int = (rings - 1) * segs
	for i: int in segs:
		idx.append_array([last + i, last + (i + 1) % segs, tip])
	return _mk(v, n, idx, cols)


## A resting butterfly: two wings (fore + hind lobe as one 3-triangle fan each) in a shallow V over a thin body.
func _butterfly(p: Vector3, yaw: float, s: float, c_wing: Color, c_tip: Color, mask: int) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), p)
	for side: float in [1.0, -1.0]:
		var rim: Array[Vector3] = []
		for q: Vector3 in [Vector3(0.030, 0.0, 0.006), Vector3(0.050, 0.0, 0.050), Vector3(0.004, 0.0, 0.068),
				Vector3(-0.040, 0.0, 0.040), Vector3(-0.026, 0.0, 0.006)]:
			rim.append(Vector3(q.x, q.z * 0.55, q.z * side))
		_part(_fan(Vector3.ZERO, c_wing, rim, [c_wing, c_tip, c_tip, c_wing, c_wing] as Array[Color], false), xf,
			c_wing, {"mask": mask, "normals": "up", "lift": 0.5, "a": 1.0, "tint": 0.03})
	_part(_spindle(Vector3(-0.035, 0.0, 0.0), Vector3(0.03, 0.004, 0.0), 0.007, 0.4, c_tip, c_tip), xf, c_tip,
		{"mask": mask, "normals": "smooth", "lift": 0.5, "a": 1.0})
