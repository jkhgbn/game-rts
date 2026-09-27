extends SceneTree
## Task 12b.V2 (terrain.md 7.2 "snow" set, art-keep.md 0): generates the snowfield scatter meshes with the SHARED
## painted nature material (art/environment/nature_props/nature_mat.tres, loaded, never re-saved). One mesh per decor
## kind, 3 shape variants in each through the variant mask (UV2.x): the shader picks the variant from a hash of the
## instance position, so one MultiMesh shows 3 shapes.
##   snow_capped_rocks.res  cold blue-grey granite under thick snow pillows (V0 big capped boulder + a small stone in a
##                          wind drift, V1 tilted granite shard with an icicle fringe under its raised end, V2 a huddle
##                          of three capped stones sunk in one drift) + a soft BLUE contact disc (surface 1,
##                          snow_contact_mat.tres = nature_contact.gdshader with a cold contact colour)
##   snow_frost_scrub.res   V0 frosted blue-green grass tuft poking out of a snow mound, V1 frost-bleached straw tuft
##                          bent over under the snow with three snow-capped seed heads, V2 small icicle shrub: dark bare
##                          twigs with frosted tips, snow on the forks, icicles under the low branches (+ contact disc)
## Snow, ice and rock use the stone kind (3, moss 0): no wind, lit tops (the shader's stone_top_light brightens every
## sky-facing snow face), cool ambient in the shade = blue snow shadows for free. Grass blades are foliage (5, light
## wind), twigs bark (0, no wind: a frozen shrub is stiff and the snow on it must not tear off). Snow parts carry a
## fixed COLOR.a and a UV.y lift so the shader's height gradient / contact band never greys them.
## Vertex data follows nature_painted.gdshader: COLOR.rgb colour, COLOR.a height gradient, UV.x wind weight
## (clamp(y * k, 0, 0.45)) or the stone moss amount (0 here), UV.y local height (+ lift), UV2 = (variant mask, kind).
## Every mesh is indexed (welded). No lights, no textures, no runtime materials. The sparkle lives in the ground shader
## (12b.V1), not here.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/snow/build_snow.gd --quit-after 600

const DIR := "res://art/environment/biomes/snow/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45
const GOLDEN := 2.39996

# Palette (sRGB). Snow is tuned so a flat sky-facing snow face (x1.35 stone top light) lands on the ground shader's
# snow base (0.90, 0.93, 0.98, terrain.md 7.1): white without blowing past the bloom threshold.
const SNOW := Color(0.77, 0.81, 0.88)
const SNOW_SH := Color(0.62, 0.69, 0.83)      # snow in its own shade / the underside of a pillow (blue)
const FROST := Color(0.66, 0.74, 0.84)        # frost rim (terrain.md 7.1 (0.80, 0.88, 0.96) before the top light)
const ICE := Color(0.55, 0.74, 0.90)
const ICE_L := Color(0.86, 0.95, 1.00)
const SLATE := Color(0.33, 0.35, 0.40)
const SLATE_D := Color(0.25, 0.26, 0.31)
const SLATE_B := Color(0.37, 0.40, 0.47)
const FG_ROOT := Color(0.12, 0.20, 0.19)
const FG_MID := Color(0.28, 0.42, 0.40)
const FG_TIP := Color(0.80, 0.87, 0.93)
const ST_ROOT := Color(0.30, 0.25, 0.16)
const ST := Color(0.62, 0.52, 0.32)
const ST_FROST := Color(0.86, 0.86, 0.84)
const TWIG_D := Color(0.17, 0.13, 0.12)
const TWIG := Color(0.28, 0.22, 0.20)
const TWIG_FROST := Color(0.64, 0.70, 0.78)

var mat: ShaderMaterial
var contact_mat: ShaderMaterial
var _conv: float = 1.0
var _wind_k: float = 0.0   # wind weight per metre of height for the current mesh

# Current mesh (surface 0) and its contact disc (surface 1).
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()      # alpha < 0 = automatic height gradient at commit
var _uv := PackedVector2Array()   # (wind weight or moss, local height + lift)
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
	contact_mat = load(DIR + "snow_contact_mat.tres") as ShaderMaterial
	if mat == null or contact_mat == null:
		push_error("nature / snow contact materials missing")
		quit(1)
		return
	_build_capped_rocks()
	_build_frost_scrub()
	for line: String in _report:
		print(line)
	print("SNOW BUILD OK")
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


## Smooth 3D value noise 0..1 (snow patches a few facets wide instead of per-facet confetti).
func _vnoise(p: Vector3) -> float:
	var i: Vector3 = p.floor()
	var f: Vector3 = p - i
	f = f * f * (Vector3(3.0, 3.0, 3.0) - f * 2.0)
	var x00: float = lerpf(_h(i), _h(i + Vector3(1, 0, 0)), f.x)
	var x10: float = lerpf(_h(i + Vector3(0, 1, 0)), _h(i + Vector3(1, 1, 0)), f.x)
	var x01: float = lerpf(_h(i + Vector3(0, 0, 1)), _h(i + Vector3(1, 0, 1)), f.x)
	var x11: float = lerpf(_h(i + Vector3(0, 1, 1)), _h(i + Vector3(1, 1, 1)), f.x)
	return lerpf(lerpf(x00, x10, f.y), lerpf(x01, x11, f.y), f.z)


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


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
##   kind (Kind, default IVY), mask (variant bits, 0 = always), jitter (m), seed, jit_axes,
##   normals: "flat" | "smooth" | "crown" (smooth, bent away from `crown`, squashed by crown_s, weight crown_k),
##   col2 + grad ("y" part height | "wy" mesh height | "r" distance from the part axis), tint (random value variation,
##   default 0.08), lift (metres added to UV.y: keeps the contact band off snow), a (fixed COLOR.a, default: height in
##   the mesh), wind (weight per metre, default the mesh's), moss (stone: UV.x = this amount instead of a wind weight),
##   clip_y (drop triangles entirely below this height: the buried part of a stone), no_caps (drop +-Y cap faces),
##   snow (stone: seed of the snow pattern; faces turned to the sky get SNOW, the band just below a FROST rim),
##   snow_at (the up-facing threshold, default 0.5).
##   Per-vertex colours in the arrays (ARRAY_COLOR) win over col / col2.
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
	var tint: float = o.get("tint", 0.08)
	var lift: float = o.get("lift", 0.0)
	var alpha: float = o.get("a", -1.0)
	var wk: float = o.get("wind", _wind_k)
	var moss: float = o.get("moss", -1.0)
	var clip_y: float = o.get("clip_y", -INF)
	var snow_on: bool = o.has("snow")
	var snow_seed: float = o.get("snow", 0.0)
	var snow_at: float = o.get("snow_at", 0.5)
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
	var wminy: float = INF
	var wmaxy: float = -INF
	for p: Vector3 in tv:
		wminy = minf(wminy, p.y)
		wmaxy = maxf(wmaxy, p.y)
	for t: int in range(0, idx.size(), 3):
		var a: int = idx[t]
		var b: int = idx[t + 1]
		var c: int = idx[t + 2]
		if no_caps and absf(n[a].y) > 0.99 and absf(n[b].y) > 0.99 and absf(n[c].y) > 0.99:
			continue
		if tv[a].y < clip_y and tv[b].y < clip_y and tv[c].y < clip_y:
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
		var centre: Vector3 = (tv[a] + tv[b] + tv[c]) / 3.0
		var fk: float = 1.0 + (_h(centre.snappedf(0.01)) - 0.5) * tint
		# Snow: the faces that see the sky (value noise breaks the line a few facets wide), a frost rim below them.
		var face := Color(0, 0, 0, 0)
		var face_a: float = alpha
		if snow_on:
			var sn: float = _vnoise(centre * 3.2 + Vector3(snow_seed, snow_seed * 0.37, snow_seed * 0.71))
			var up: float = fn.y + (sn - 0.5) * 0.5
			if up > snow_at:
				face = Color(SNOW.r, SNOW.g, SNOW.b, 1.0)
				face_a = 0.95
				fk = 1.0 + (fk - 1.0) * 0.3
			elif up > snow_at - 0.22:
				face = Color(FROST.r, FROST.g, FROST.b, 0.5)
		for vi: int in [a, b, c]:
			var nn: Vector3 = fn
			if mode == "smooth":
				nn = tn[vi]
			elif mode == "crown":
				var cd: Vector3 = ((tv[vi] - crown) / crown_s).normalized()
				nn = tn[vi].lerp(cd, crown_k).normalized()
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
			if face.a > 0.0:
				cc = cc.lerp(Color(face.r, face.g, face.b), face.a)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k, face_a))
			var ux: float = moss if moss >= 0.0 else clampf(tv[vi].y * wk, 0.0, WMAX)
			_uv.append(Vector2(ux, tv[vi].y + lift + (0.35 if face.a >= 1.0 else 0.0)))
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
	_report.append("mesh %-20s %4d tris, %4d verts (variants %d / %d / %d), contact %d, aabb %s .. %s" % [
		name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		_cv.size() / 3, aabb.position.snappedf(0.01), aabb.end.snappedf(0.01)])
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

## A grass blade: a flattened 3-sided spike (visible from every side) in 2 segments, bent by `lean`: the middle ring
## carries a quarter of the lean, so the blade stands up from the root and droops at the top. `face` = angle of the
## flat side. Colours: root c0, middle c0 -> c1 at 55 %, tip c1 (the frost sits on the upper half).
func _bent_blade(base: Vector3, h: float, w: float, lean: Vector3, face: float, c0: Color, c1: Color) -> Array:
	var side := Vector3(cos(face), 0.0, sin(face))
	var out := Vector3(-side.z, 0.0, side.x)
	var tip: Vector3 = base + Vector3(0.0, maxf(h - lean.length() * 0.3, h * 0.35), 0.0) + lean
	var mid: Vector3 = base + Vector3(0.0, h * 0.5, 0.0) + lean * 0.25
	var sec: Array[Vector3] = [side * w, -side * w, out * w * 0.4]
	var cen: Vector3 = (sec[0] + sec[1] + sec[2]) / 3.0
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var rings: Array = [[base, 1.0, c0], [mid, 0.66, c0.lerp(c1, 0.55)]]
	for rg: Array in rings:
		for s: Vector3 in sec:
			v.append((rg[0] as Vector3) + s * float(rg[1]))
			n.append(((s - cen).normalized() + Vector3(0.0, 0.3, 0.0)).normalized())
			cols.append(rg[2] as Color)
	var t: int = v.size()
	v.append(tip)
	n.append(Vector3.UP)
	cols.append(c1)
	for i: int in 3:
		var j: int = (i + 1) % 3
		idx.append_array([i, j, 3 + i, j, 3 + j, 3 + i, 3 + i, 3 + j, t])
	return _mk(v, n, idx, cols)


## A 3-sided double pyramid from `a` to `b` (icicles, seed heads, frost spikes), radius `r` at `bulge` (0-1).
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
		cols.append(col_a.lerp(col_b, 0.35))
	v.append(b)
	n.append(d)
	cols.append(col_b)
	var idx := PackedInt32Array()
	for i: int in 3:
		var j: int = (i + 1) % 3
		idx.append_array([0, 1 + i, 1 + j, 4, 1 + j, 1 + i])
	return _mk(v, n, idx, cols)


## A chiselled rock (build_nature.gd's recipe): a unit sphere cut by `cuts` random planes and a tilted top plane at
## `top`, jittered, scaled by `radii`.
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


## A snow mound / wind drift: a heightfield disc (radii rx, rz, height h) whose profile h (1 - t^2)^2 feathers into
## the ground with a flat tangent (no step where it meets the painted snow). `lean` (0-1) piles it up on local +X
## (the side the wind drove the snow against); the outline wobbles by +-15 %. Smooth normals from the profile.
func _mound(rx: float, rz: float, h: float, lean: float, seed: float, segs: int = 12, rings: int = 3) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	v.append(Vector3(rx * lean * 0.22, h * (1.0 + lean * 0.2), 0.0))
	n.append(Vector3.UP)
	var jit: Array[float] = []
	for si: int in segs:
		jit.append(1.0 + (_h(Vector3(seed, si, 3.0)) - 0.5) * 0.3)
	for ri: int in range(1, rings + 1):
		var t: float = float(ri) / rings
		for si: int in segs:
			var a: float = si * TAU / segs
			var ha: float = h * (1.0 - lean * 0.5 + lean * 0.5 * cos(a) + lean * 0.2)
			var prof: float = pow(1.0 - t * t, 2.0)
			var r: float = t * jit[si]
			var p := Vector3(cos(a) * rx * r + rx * lean * 0.22 * (1.0 - t), ha * prof - (0.012 if ri == rings else 0.0),
				sin(a) * rz * r)
			v.append(p)
			var slope: float = 4.0 * ha * t * (1.0 - t * t) / maxf((rx + rz) * 0.5 * jit[si], 0.01)
			n.append(Vector3(cos(a) * slope * rz / maxf(rx, 0.01), 1.0, sin(a) * slope * rx / maxf(rz, 0.01)).normalized())
	for si: int in segs:
		var sj: int = (si + 1) % segs
		idx.append_array([0, 1 + sj, 1 + si])
	for ri: int in range(1, rings):
		var o0: int = 1 + (ri - 1) * segs
		var o1: int = 1 + ri * segs
		for si: int in segs:
			var sj: int = (si + 1) % segs
			idx.append_array([o0 + si, o0 + sj, o1 + si, o0 + sj, o1 + sj, o1 + si])
	return _mk(v, n, idx)


## Snow parts: stone kind, no moss, fixed bright gradient, lifted off the contact band.
func _snow_o(mask: int, seed: float, extra: Dictionary = {}) -> Dictionary:
	var o := {"kind": Kind.STONE, "mask": mask, "moss": 0.0, "seed": seed, "a": 0.95, "lift": 0.4, "tint": 0.04,
		"normals": "smooth"}
	o.merge(extra, true)
	return o


func _drift(c: Vector3, yaw: float, rx: float, rz: float, h: float, lean: float, mask: int, seed: float,
		segs: int = 12) -> void:
	_part(_mound(rx, rz, h, lean, seed, segs), _xf(c, Vector3(0.0, yaw, 0.0)), SNOW_SH,
		_snow_o(mask, seed, {"col2": SNOW, "grad": "y", "jitter": 0.012, "jit_axes": Vector3(1.0, 0.3, 1.0)}))


## A pillow of snow sitting on something: a squashed sphere (radii r, t, r * rz_k) centred slightly below `top`, its
## hidden bottom dropped; blue at its underside -> white on top, soft rounded shading, a little lumpy.
func _pillow(top: Vector3, r: float, t: float, rz_k: float, rot: Vector3, mask: int, seed: float, segs: int = 9,
		rings: int = 4) -> void:
	var c: Vector3 = top - Vector3(0.0, t * 0.35, 0.0)
	_part(_sph(1.0, segs, rings), _xf(c, rot, Vector3(r, t, r * rz_k)), SNOW_SH,
		_snow_o(mask, seed, {"col2": SNOW, "grad": "y", "normals": "crown", "crown": c - Vector3(0.0, t * 0.6, 0.0),
		"crown_k": 0.55, "crown_s": Vector3(1.0, 0.45, 1.0), "jitter": minf(r, t) * 0.18,
		"jit_axes": Vector3(1.0, 0.6, 1.0), "clip_y": c.y - t * 0.55}))


## A cold granite stone with snow on its sky-facing facets, a frost rim below, and (pillow > 0) a snow pillow on
## its top sized from the top facets' spread.
func _capped_stone(radii: Vector3, pos: Vector3, rot: Vector3, col: Color, mask: int, seed: float, pillow: float = 1.0,
		cuts: int = 5, top: float = 0.66, segs: int = 9, rings: int = 5) -> void:
	var arr: Array = _chunk(radii, cuts, seed, top, segs, rings)
	var xf: Transform3D = _xf(pos, rot)
	_part(arr, xf, col, {"kind": Kind.STONE, "mask": mask, "moss": 0.0, "seed": seed, "tint": 0.12,
		"col2": col.lightened(0.06), "grad": "y", "snow": seed * 1.3, "snow_at": 0.64, "clip_y": -0.03})
	if pillow <= 0.0:
		return
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var maxy: float = -INF
	var tv: Array[Vector3] = []
	for p: Vector3 in v:
		var q: Vector3 = xf * p
		tv.append(q)
		maxy = maxf(maxy, q.y)
	var band: float = maxy - radii.y * 0.16
	var c := Vector3.ZERO
	var cnt := 0
	for q: Vector3 in tv:
		if q.y > band:
			c += q
			cnt += 1
	c /= maxf(cnt, 1)
	var spread: float = 0.0
	for q: Vector3 in tv:
		if q.y > band:
			spread = maxf(spread, Vector2(q.x - c.x, q.z - c.z).length())
	var r: float = maxf(spread, radii.x * 0.4) * 0.9 * pillow
	var t: float = clampf(r * 0.34, 0.06, 0.18)
	_pillow(Vector3(c.x, maxy, c.z), r, t, 0.9, Vector3(0.0, seed, 0.0), mask, seed + 0.5)


func _icicle(top: Vector3, length: float, r: float, mask: int, seed: float) -> void:
	var tip: Vector3 = top + Vector3((_h(Vector3(seed, 1, 0)) - 0.5) * 0.03, -length, (_h(Vector3(seed, 2, 0)) - 0.5) * 0.03)
	_part(_spindle(top + Vector3(0.0, 0.03, 0.0), tip, r, 0.12, ICE, ICE_L), Transform3D.IDENTITY, ICE,
		{"kind": Kind.STONE, "mask": mask, "moss": 0.0, "normals": "smooth", "a": 1.0, "lift": 0.5, "tint": 0.04})


func _twig(a: Vector3, b: Vector3, r0: float, r1: float, c0: Color, c1: Color, mask: int) -> void:
	var d: Vector3 = b - a
	var basis := Basis(Quaternion(Vector3.UP, d.normalized()))
	_part(_cyl(r1, r0, d.length(), 4), Transform3D(basis, (a + b) * 0.5), c0,
		{"kind": Kind.BARK, "mask": mask, "normals": "smooth", "tint": 0.06, "col2": c1, "grad": "y", "wind": 0.0,
		"no_caps": true})


# --- snow-capped rocks -------------------------------------------------------------------------

func _build_capped_rocks() -> void:
	_begin(0.0)
	# V0: a big rounded granite boulder, dark shoulders under a thick pillow, a small capped stone at its foot, a low
	# wind drift feathering out on its lee side (~1.9 m incl. the drift, 0.85 m tall).
	_capped_stone(Vector3(0.62, 0.82, 0.52), Vector3(0.0, 0.18, 0.0), Vector3(0.05, 0.4, 0.03), SLATE, V0, 201.0, 0.95,
		5, 0.62)
	_capped_stone(Vector3(0.28, 0.34, 0.26), Vector3(0.64, 0.08, 0.3), Vector3(0.2, 1.3, -0.1), SLATE_B, V0, 202.0, 0.9,
		4, 0.72, 7, 4)
	_capped_stone(Vector3(0.22, 0.16, 0.19), Vector3(-0.6, 0.03, 0.42), Vector3(0.15, 0.7, 0.1), SLATE_D, V0, 203.0, 0.0,
		4, 0.72, 7, 4)
	_drift(Vector3(-0.46, 0.0, -0.3), 2.6, 0.85, 0.55, 0.14, 0.8, V0, 204.0)
	_disc(Vector3(0.05, 0.0, 0.05), 1.05, 0.9, 12, 201.0, V0)
	# V1: a tilted outcrop: a long granite shard breaking out of the snow at ~31 deg, snow on its back and a pillow on
	# top, an icicle fringe under the raised end, a second shard behind it, a low drift against it.
	var r1 := Vector3(0.74, 0.36, 0.46)
	var rot1 := Vector3(0.05, 0.25, 0.55)
	var pos1 := Vector3(0.0, 0.2, 0.0)
	_capped_stone(r1, pos1, rot1, SLATE, V1, 211.0, 0.75, 5, 0.6, 10, 5)
	_capped_stone(Vector3(0.44, 0.3, 0.34), Vector3(-0.52, 0.12, -0.4), Vector3(-0.1, 0.6, 0.62), SLATE_D, V1, 213.0,
		0.7, 5, 0.62, 9, 5)
	# Icicles along the raised end's underside (the chunk's own vertices: outermost +X per slice, below its middle).
	var lv: PackedVector3Array = _chunk(r1, 5, 211.0, 0.6, 10, 5)[Mesh.ARRAY_VERTEX]
	var xf1: Transform3D = _xf(pos1, rot1)
	var ice_n := 0
	for i: int in 7:
		var zs: float = lerpf(-0.62, 0.62, (i + 0.5) / 7.0) * r1.z
		var best := Vector3(-INF, 0.0, 0.0)
		for q: Vector3 in lv:
			if absf(q.z - zs) < r1.z * 0.16 and q.y < r1.y * 0.05 and q.y > -r1.y * 0.6 and q.x > best.x:
				best = q
		if best.x == -INF:
			continue
		var top: Vector3 = xf1 * (best * 0.94)
		var ln: float = lerpf(0.18, 0.34, _h(Vector3(i, 215.0, 2.0))) * (0.65 if i == 0 or i == 6 else 1.0)
		ln = minf(ln, top.y - 0.05)
		if ln < 0.08:
			continue
		_icicle(top, ln, lerpf(0.036, 0.05, _h(Vector3(i, 215.0, 3.0))), V1, 215.0 + i)
		ice_n += 1
	_drift(Vector3(-0.8, 0.0, 0.12), 3.1, 0.7, 0.62, 0.13, 0.7, V1, 216.0)
	_capped_stone(Vector3(0.2, 0.15, 0.18), Vector3(0.7, 0.03, -0.4), Vector3(0.1, 2.2, 0.1), SLATE_B, V1, 217.0, 0.0,
		4, 0.72, 7, 4)
	_disc(Vector3(-0.05, 0.0, 0.0), 1.05, 0.85, 12, 211.0, V1)
	# V2: a huddle of three capped stones sunk in one low drift.
	_capped_stone(Vector3(0.42, 0.5, 0.38), Vector3(-0.14, 0.1, 0.0), Vector3(0.1, 0.4, 0.0), SLATE_B, V2, 221.0, 0.95,
		4, 0.74)
	_capped_stone(Vector3(0.32, 0.36, 0.3), Vector3(0.42, 0.06, 0.24), Vector3(-0.1, 2.0, 0.08), SLATE, V2, 222.0, 0.95,
		4, 0.76, 8, 4)
	_capped_stone(Vector3(0.25, 0.26, 0.23), Vector3(0.22, 0.03, -0.4), Vector3(0.0, 3.1, 0.12), SLATE_D, V2, 223.0, 0.9,
		4, 0.78, 7, 4)
	_drift(Vector3(0.1, 0.0, 0.0), 0.3, 1.0, 0.8, 0.12, 0.3, V2, 224.0, 14)
	_disc(Vector3(0.08, 0.0, 0.0), 1.0, 0.85, 12, 221.0, V2)
	_report.append("slab icicles: %d" % ice_n)
	_commit("snow_capped_rocks")


# --- frosted grass / icicle shrub --------------------------------------------------------------

func _build_frost_scrub() -> void:
	_begin(0.35)
	# V0: a frosted blue-green grass tuft poking out of a low snow mound (~0.55 m tall): dark roots, frost-white tips.
	for i: int in 13:
		var a: float = i * GOLDEN + 0.3
		var t: float = _h(Vector3(i, 301.0, 1.0))
		var f: float = sqrt((i + 0.5) / 13.0)
		var r: float = lerpf(0.02, 0.14, f)
		var base := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var hh: float = lerpf(0.56, 0.3, clampf(f * 0.8 + (t - 0.5) * 0.4, 0.0, 1.0))
		var lean := Vector3(cos(a), 0.0, sin(a)) * hh * lerpf(0.18, 0.42, _h(Vector3(i, 301.0, 2.0)))
		var c0: Color = FG_ROOT.lerp(FG_MID, 0.2 + t * 0.35)
		var c1: Color = FG_MID.lerp(FG_TIP, 0.6 + t * 0.4)
		_part(_bent_blade(base, hh, 0.05 * (0.85 + t * 0.3), lean, a + PI * 0.5 + (t - 0.5) * 0.5, c0, c1),
			Transform3D.IDENTITY, c0, {"mask": V0, "normals": "crown", "crown": Vector3(0.0, -0.25, 0.0), "crown_k": 0.5,
			"tint": 0.06})
	_drift(Vector3(0.0, 0.0, 0.0), 0.8, 0.24, 0.21, 0.06, 0.3, V0, 302.0, 9)
	# V1: a frost-bleached straw tuft bent over under the snow, three seed heads with snow on them, a low drift on its
	# windward side (~0.6 m tall).
	for i: int in 11:
		var a2: float = i * GOLDEN + 1.1
		var t2: float = _h(Vector3(i, 311.0, 1.0))
		var f2: float = sqrt((i + 0.5) / 11.0)
		var r2: float = lerpf(0.02, 0.13, f2)
		var base2 := Vector3(cos(a2) * r2, -0.02, sin(a2) * r2)
		var h2: float = lerpf(0.62, 0.34, clampf(f2 * 0.8 + (t2 - 0.5) * 0.4, 0.0, 1.0))
		var bend: float = lerpf(0.25, 0.75, _h(Vector3(i, 311.0, 2.0)))
		var lean2 := Vector3(cos(a2), 0.0, sin(a2)) * h2 * bend
		var c0b: Color = ST_ROOT.lerp(ST, 0.3 + t2 * 0.3)
		var c1b: Color = ST.lerp(ST_FROST, 0.45 + t2 * 0.5)
		_part(_bent_blade(base2, h2, 0.045 * (0.85 + t2 * 0.3), lean2, a2 + PI * 0.5, c0b, c1b), Transform3D.IDENTITY,
			c0b, {"mask": V1, "normals": "crown", "crown": Vector3(0.0, -0.25, 0.0), "crown_k": 0.5, "tint": 0.06})
	for k: int in 3:
		var a3: float = 0.7 + k * 2.2
		var base3 := Vector3(cos(a3) * 0.04, -0.02, sin(a3) * 0.04)
		var h3: float = 0.66 - k * 0.07
		var lean3 := Vector3(cos(a3), 0.0, sin(a3)) * (0.12 + k * 0.04)
		_part(_bent_blade(base3, h3, 0.014, lean3, a3, ST_ROOT, ST), Transform3D.IDENTITY, ST,
			{"mask": V1, "normals": "smooth"})
		var tip: Vector3 = base3 + Vector3(0.0, maxf(h3 - lean3.length() * 0.3, h3 * 0.35), 0.0) + lean3
		var mid: Vector3 = base3 + Vector3(0.0, h3 * 0.5, 0.0) + lean3 * 0.25
		var dir: Vector3 = (tip - mid).normalized()
		_part(_spindle(tip - dir * 0.02, tip + dir * 0.16, 0.035, 0.4, ST, ST.lightened(0.2)), Transform3D.IDENTITY,
			ST, {"mask": V1, "normals": "smooth", "lift": 0.3, "a": 1.0, "tint": 0.04})
		_pillow(tip + dir * 0.09 + Vector3(0.0, 0.03, 0.0), 0.04, 0.024, 1.0, Vector3.ZERO, V1, 312.0 + k, 5, 3)
	_drift(Vector3(-0.06, 0.0, 0.03), 3.3, 0.32, 0.24, 0.07, 0.7, V1, 313.0, 9)
	# V2: a small icicle shrub (~0.8 m tall, ~1.1 m wide): six dark crooked stems, each with a side branch; snow lies
	# along the branches in long strips and packs the forks, rime on the twig ends, icicles hang under the flat side
	# branches.
	var ice_n := 0
	for i: int in 6:
		var az: float = i * TAU / 6.0 + 0.35 + (_h(Vector3(i, 320.0, 1.0)) - 0.5) * 0.6
		var hs: float = lerpf(0.68, 0.9, _h(Vector3(i, 320.0, 2.0)))
		var sp: float = lerpf(0.14, 0.28, _h(Vector3(i, 320.0, 3.0)))
		var out := Vector3(cos(az), 0.0, sin(az))
		var side := Vector3(-out.z, 0.0, out.x) * (1.0 if i % 2 == 0 else -1.0)
		var root := out * 0.035 + Vector3(0.0, -0.03, 0.0)
		# A crooked stem: three segments, each kinked sideways a little.
		var p1: Vector3 = root + Vector3(0.0, hs * 0.36, 0.0) + out * sp * 0.3 + side * 0.04
		var p2: Vector3 = root + Vector3(0.0, hs * 0.7, 0.0) + out * sp * 0.65 - side * 0.05
		var tip2: Vector3 = root + Vector3(0.0, hs, 0.0) + out * sp + side * 0.03
		_twig(root, p1, 0.04, 0.032, TWIG_D, TWIG_D.lerp(TWIG, 0.6), V2)
		_twig(p1, p2, 0.032, 0.022, TWIG_D.lerp(TWIG, 0.6), TWIG, V2)
		_twig(p2, tip2, 0.022, 0.011, TWIG, TWIG.lerp(TWIG_FROST, 0.55), V2)
		# The side branch from p1: out and flatter, a twig flicking up at its end.
		var sa: float = az + (0.8 if i % 2 == 0 else -0.8)
		var sout := Vector3(cos(sa), 0.0, sin(sa))
		var s_mid: Vector3 = p1 + sout * 0.2 + Vector3(0.0, 0.07, 0.0)
		var s_tip: Vector3 = s_mid + sout * 0.1 + Vector3(0.0, 0.18, 0.0)
		_twig(p1, s_mid, 0.022, 0.016, TWIG_D.lerp(TWIG, 0.6), TWIG, V2)
		_twig(s_mid, s_tip, 0.016, 0.008, TWIG, TWIG.lerp(TWIG_FROST, 0.55), V2)
		# Snow: a long strip lying along the flat side branch, a clump packed into the fork, a small cap on p2.
		var sd: Vector3 = (s_mid - p1)
		var yaw: float = atan2(-sd.z, sd.x)
		_pillow(p1.lerp(s_mid, 0.55) + Vector3(0.0, 0.028, 0.0), 0.15, 0.04, 0.4, Vector3(0.0, yaw, 0.0), V2, 331.0 + i,
			6, 3)
		_pillow(p1 + Vector3(0.0, 0.03, 0.0), 0.08, 0.045, 0.8, Vector3(0.0, az, 0.0), V2, 321.0 + i, 6, 3)
		if i % 2 == 1:
			var pd: Vector3 = (p2 - p1)
			_pillow(p2 + Vector3(0.0, 0.02, 0.0), 0.07, 0.03, 0.6, Vector3(0.0, atan2(-pd.z, pd.x), 0.0), V2, 326.0 + i,
				6, 3)
		# Rime at the stem tip (a small frost spike catching the light).
		_part(_spindle(tip2 - Vector3(0.0, 0.02, 0.0), tip2 + out * 0.04 + Vector3(0.0, 0.08, 0.0), 0.02, 0.3, FROST,
			ICE_L), Transform3D.IDENTITY, FROST, {"kind": Kind.STONE, "mask": V2, "moss": 0.0, "normals": "smooth",
			"a": 1.0, "lift": 0.5, "tint": 0.04})
		# Icicles under the side branch.
		for k2: int in 2:
			var on: Vector3 = p1.lerp(s_mid, 0.4 + k2 * 0.45) - Vector3(0.0, 0.015, 0.0)
			var ln2: float = lerpf(0.13, 0.22, _h(Vector3(i, k2, 341.0)))
			ln2 = minf(ln2, on.y - 0.1)
			if ln2 > 0.06:
				_icicle(on, ln2, 0.028, V2, 341.0 + i * 2 + k2)
				ice_n += 1
	_drift(Vector3(0.02, 0.0, 0.0), 1.9, 0.3, 0.26, 0.07, 0.5, V2, 351.0, 9)
	_disc(Vector3.ZERO, 0.66, 0.6, 10, 351.0, V2)
	_report.append("icicle shrub: %d icicles" % ice_n)
	_commit("snow_frost_scrub")
