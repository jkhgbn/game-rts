extends SceneTree
## Task 12.V12 (map-fill.md 3.1 biome 3 "Crown Isle ruins" + section 10): generates the ruins decor meshes. Stone,
## iron and grass use the SHARED painted nature material (art/environment/nature_props/nature_mat.tres, loaded, never
## re-saved); the ember moss uses this folder's ruins_ember_mat.tres (ruins_ember.gdshader, emission only). One mesh
## per decor kind, 3 shape variants in each through the variant mask (UV2.x): the shader picks the variant from a
## hash of the instance position, so one MultiMesh shows 3 shapes. ONE surface per mesh (no contact disc), so a
## MultiMesh may also use the item's material as material_override.
##   ruins_flagstones.res  flat broken flagstones ~1.3 m, <= 0.3 m (V0 slab split by a crack + a small slab, V1 one
##                         slab heaved up on a wedge of rubble + its broken corner, V2 loose small tiles, one missing)
##   ruins_drums.res       low column drums <= 0.4 m (V0 standing stub with a broken top, V1 two slices, the upper one
##                         slid off, V2 a drum lying on its side, half sunk)
##   ruins_ember_moss.res  ember moss <= 0.35 m (V0 cushions round a smouldering heart, V1 creeping along paving
##                         joints with glowing beads, V2 a moss-grown stone chunk)
##   ruins_monuments.res   <= 0.85 m (V0 cracked statue plinth with the statue's broken feet, V1 plinth split in two
##                         with its fallen finial, V2 a cold brazier: iron bowl of grey ash and charcoal on a sooty post)
## Vertex data follows nature_painted.gdshader: COLOR.rgb colour, COLOR.a height gradient, UV.x stone moss amount /
## grass wind weight (clamp(y * k, 0, 0.45)) / ember heat (ember shader), UV.y local height, UV2 = (variant mask, kind).
## Every mesh is indexed (welded). No lights, no textures, no colliders, no runtime materials.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/ruins/build_ruins.gd --quit-after 600

const DIR := "res://art/environment/biomes/ruins/"
const NDIR := "res://art/environment/nature_props/"

enum Kind { BARK = 0, NEEDLES = 1, LEAVES = 2, STONE = 3, BIRCH = 4, IVY = 5, GOLD = 6 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45
const GOLDEN := 2.39996

# Palette (sRGB). The crown altar's pale lilac-grey ruin stone (build_crown.gd STONE_P / STONE / STONE_D, saturation
# <= 0.2), soot and ash from the old fires, scorched grass; the ember is the only strong colour.
const STONE_P := Color(0.55, 0.52, 0.55)   # a step darker than the altar: the painted paving under it is pale
const STONE := Color(0.46, 0.43, 0.47)
const STONE_D := Color(0.29, 0.27, 0.31)
const SOOT := Color(0.19, 0.16, 0.17)
const ASH := Color(0.23, 0.22, 0.22)
const ASH_L := Color(0.33, 0.32, 0.31)
const CHAR := Color(0.09, 0.08, 0.08)
const IRON := Color(0.17, 0.16, 0.18)
const IRON_L := Color(0.30, 0.28, 0.31)
const BRONZE := Color(0.62, 0.40, 0.16)
const GRASS_D := Color(0.20, 0.21, 0.08)
const GRASS := Color(0.40, 0.37, 0.15)
const GRASS_T := Color(0.66, 0.52, 0.24)   # sun- and ember-scorched tips
const MOSS_D := Color(0.15, 0.17, 0.07)
const MOSS := Color(0.36, 0.40, 0.15)
const MOSS_R := Color(0.46, 0.20, 0.07)    # rust fronds
const EMBER := Color(0.95, 0.46, 0.12)     # albedo under the emission
const COAL := Color(0.16, 0.07, 0.03)

var mat: ShaderMaterial
var ember_mat: ShaderMaterial
var _conv: float = 1.0
var _wind_k: float = 0.0

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()      # alpha < 0 = automatic height gradient at commit
var _uv := PackedVector2Array()   # (moss / wind / heat, local height + lift)
var _uv2 := PackedVector2Array()  # (variant mask, kind)
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_detect_winding()
	mat = load(NDIR + "nature_mat.tres") as ShaderMaterial
	if mat == null:
		push_error("nature_mat.tres missing")
		quit(1)
		return
	_make_ember_mat()
	_build_flagstones()
	_build_drums()
	_build_ember_moss()
	_build_monuments()
	for line: String in _report:
		print(line)
	print("RUINS BUILD OK")
	quit()


# --- helpers -----------------------------------------------------------------------------------

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])


func _make_ember_mat() -> void:
	var m := ShaderMaterial.new()
	m.shader = load(DIR + "ruins_ember.gdshader") as Shader
	m.set_shader_parameter("noise_tex", load("res://art/shaders/paint_noise.tres") as Texture2D)
	_save(m, DIR + "ruins_ember_mat.tres")
	m.take_over_path(DIR + "ruins_ember_mat.tres")   # the moss mesh then references the file
	ember_mat = m


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


func _h3(p: Vector3) -> Vector3:
	return Vector3(_h(p), _h(p + Vector3(5.2, 1.3, 7.1)), _h(p + Vector3(2.7, 9.1, 3.3))) * 2.0 - Vector3.ONE


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _begin(wind_k: float = 0.0) -> void:
	_wind_k = wind_k
	_v = PackedVector3Array()
	_n = PackedVector3Array()
	_c = PackedColorArray()
	_uv = PackedVector2Array()
	_uv2 = PackedVector2Array()


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
##   kind (Kind, default STONE), mask (variant bits, 0 = always), jitter (m), seed, jit_axes,
##   normals: "flat" | "smooth" | "up" (mostly straight up: flat leaves / ash) | "crown" (smooth, bent away from
##   `crown`, squashed by crown_s, weight crown_k), col2 + grad ("y" part height | "wy" world height | "r" distance from
##   the part axis), tint (random value variation, default 0.08), lift (metres added to UV.y), a (fixed COLOR.a),
##   UV.x: moss (stone moss amount, fixed) | heat + heat2 (ember heat, from heat at the part's bottom to heat2 at its
##   top) | otherwise the grass wind weight (clamp(y * wind, 0, 0.45), wind default the mesh's).
##   Per-vertex colours in the arrays (ARRAY_COLOR) win over col / col2.
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var vc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", Kind.STONE)
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
	var has_moss: bool = o.has("moss")
	var moss: float = o.get("moss", 0.0)
	var has_heat: bool = o.has("heat")
	var heat: float = o.get("heat", 0.0)
	var heat2: float = o.get("heat2", heat)
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
			var gy: float = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
			var cc: Color
			if not vc.is_empty():
				cc = vc[vi]
			else:
				var gt: float = gy
				if grad == "wy":
					gt = clampf((tv[vi].y - wminy) / maxf(wmaxy - wminy, 0.001), 0.0, 1.0)
				elif grad == "r":
					gt = clampf(Vector2(v[vi].x, v[vi].z).length() / maxr, 0.0, 1.0)
				cc = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			var ux: float
			if has_moss:
				ux = moss
			elif has_heat:
				ux = lerpf(heat, heat2, gy)
			else:
				ux = clampf(tv[vi].y * wk, 0.0, WMAX)
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k, alpha))
			_uv.append(Vector2(ux, tv[vi].y + lift))
			_uv2.append(Vector2(mask, kind))


## Bakes the height gradient (COLOR.a, unless a part fixed it), welds, saves DIR/<name>.res (one surface, `material`)
## and reports the triangles per variant.
func _commit(name: String, material: Material) -> ArrayMesh:
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in _v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var span: float = maxf(maxy - maxf(miny, 0.0), 0.01)
	for i: int in _v.size():
		var cc: Color = _c[i]
		if cc.a < 0.0:
			cc.a = clampf(_v[i].y / span, 0.0, 1.0)
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
	mesh.surface_set_material(0, material)
	_save(mesh, DIR + name + ".res")
	var per := [0, 0, 0]
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-18s %4d tris, %4d verts (variants %d / %d / %d), size %.2f x %.2f x %.2f, y %.2f..%.2f" % [
		name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y, aabb.end.y])
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


# --- shape builders (return arrays for _part) ----------------------------------------------------

## A chunky cut stone: `outline` (x, z points, star-shaped around its centroid, any winding) extruded from y -sink
## to h, the top edge bevelled (the top face is the outline pulled `bevel` toward the centroid, the bevel drops
## 0.7 x bevel). Flat-shaded, it reads as a hand-cut block with a light top and a lit chamfer.
func _slab(outline: PackedVector2Array, h: float, bevel: float, sink: float = 0.06) -> Array:
	var cnt: int = outline.size()
	var cen := Vector2.ZERO
	for p: Vector2 in outline:
		cen += p
	cen /= float(cnt)
	var inset := PackedVector2Array()
	for p: Vector2 in outline:
		var d: Vector2 = p - cen
		var l: float = d.length()
		inset.append(cen + d * maxf(l - bevel, l * 0.45) / maxf(l, 0.001))
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	var yb: float = h - bevel * 0.7
	for ring: int in 3:
		for i: int in cnt:
			var p2: Vector2 = inset[i] if ring == 2 else outline[i]
			var y: float = -sink if ring == 0 else (yb if ring == 1 else h)
			v.append(Vector3(p2.x, y, p2.y))
			var o := Vector3(outline[i].x - cen.x, 0.0, outline[i].y - cen.y).normalized()
			n.append((o + Vector3(0.0, 0.0 if ring == 0 else (0.6 if ring == 1 else 2.0), 0.0)).normalized())
	for ring: int in 2:
		for i: int in cnt:
			var j: int = (i + 1) % cnt
			var a0: int = ring * cnt + i
			var a1: int = ring * cnt + j
			var b0: int = (ring + 1) * cnt + i
			var b1: int = (ring + 1) * cnt + j
			idx.append_array([a0, a1, b0, a1, b1, b0])
	var base: int = v.size()
	for i: int in cnt:
		v.append(Vector3(inset[i].x, h, inset[i].y))
		n.append(Vector3.UP)
	var tri: PackedInt32Array = Geometry2D.triangulate_polygon(inset)
	if tri.is_empty():
		for i: int in range(1, cnt - 1):
			tri.append_array([0, i, i + 1])
	for t: int in tri:
		idx.append(base + t)
	return _mk(v, n, idx)


## A rectangle outline w x d with its corners nudged (hand-cut), `cut` > 0 knocks off corner `cut_i`.
func _rect(w: float, d: float, seed: float, wobble: float = 0.025, cut: float = 0.0, cut_i: int = 0) -> PackedVector2Array:
	var pts: Array[Vector2] = [Vector2(-w, -d) * 0.5, Vector2(w, -d) * 0.5, Vector2(w, d) * 0.5, Vector2(-w, d) * 0.5]
	var out := PackedVector2Array()
	for i: int in 4:
		var p: Vector2 = pts[i] + Vector2(_h(Vector3(seed, i, 1.0)) - 0.5, _h(Vector3(seed, i, 2.0)) - 0.5) * wobble * 2.0
		if cut > 0.0 and i == cut_i:
			var prev: Vector2 = pts[(i + 3) % 4]
			var next: Vector2 = pts[(i + 1) % 4]
			out.append(p + (prev - p).normalized() * cut)
			out.append(p + (next - p).normalized() * cut * 0.8)
		else:
			out.append(p)
	return out


## A regular polygon outline (octagon plinths).
func _ngon(r: float, sides: int, phase: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in sides:
		var a: float = phase + i * TAU / sides
		out.append(Vector2(cos(a), sin(a)) * r)
	return out


## A grass blade: a flattened 3-sided spike, 1 or 2 segments, colours c0 root -> c1 tip (per-vertex colours).
func _blade(base: Vector3, h: float, w: float, lean: Vector3, face: float, c0: Color, c1: Color,
		segs: int = 2) -> Array:
	var side := Vector3(cos(face), 0.0, sin(face))
	var out := Vector3(-side.z, 0.0, side.x)
	var tip: Vector3 = base + Vector3(0.0, h, 0.0) + lean
	var sec: Array[Vector3] = [side * w, -side * w, out * w * 0.4]
	var cen: Vector3 = (sec[0] + sec[1] + sec[2]) / 3.0
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var rings: Array = [[base, 1.0, c0]]
	if segs > 1:
		rings.append([base + Vector3(0.0, h * 0.55, 0.0) + lean * 0.3, 0.62, c0.lerp(c1, 0.55)])
	for rg: Array in rings:
		for s: Vector3 in sec:
			v.append((rg[0] as Vector3) + s * float(rg[1]))
			n.append(((s - cen).normalized() + Vector3(0.0, 0.25, 0.0)).normalized())
			cols.append(rg[2] as Color)
	var t: int = v.size()
	v.append(tip)
	n.append(Vector3.UP)
	cols.append(c1)
	for i: int in 3:
		var j: int = (i + 1) % 3
		if segs > 1:
			idx.append_array([i, j, 3 + i, j, 3 + j, 3 + i, 3 + i, 3 + j, t])
		else:
			idx.append_array([i, j, t])
	return _mk(v, n, idx, cols)


## A 3-sided double pyramid from `a` to `b` (moss fronds), radius `r` at `bulge` (0-1 along a -> b).
func _spindle(a: Vector3, b: Vector3, r: float, bulge: float) -> Array:
	var d: Vector3 = (b - a).normalized()
	var x: Vector3 = d.cross(Vector3.FORWARD if absf(d.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(d).normalized()
	var m: Vector3 = a + (b - a) * bulge
	var v := PackedVector3Array([a])
	var n := PackedVector3Array([-d])
	for i: int in 3:
		var ang: float = i * TAU / 3.0
		var rad: Vector3 = x * cos(ang) + z * sin(ang)
		v.append(m + rad * r)
		n.append(rad)
	v.append(b)
	n.append(d)
	var idx := PackedInt32Array()
	for i: int in 3:
		var j: int = (i + 1) % 3
		idx.append_array([0, 1 + i, 1 + j, 4, 1 + j, 1 + i])
	return _mk(v, n, idx)


## A chiselled rock chip: a low-poly ellipsoid cut by `cuts` random planes (+ a flat top), centred on its origin.
func _chunk(radii: Vector3, cuts: int, seed: float, top: float = 0.78, segs: int = 6, rings: int = 3) -> Array:
	var arr: Array = _sph(1.0, segs, rings)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var planes: Array = []
	for k: int in cuts:
		var a: float = _h(Vector3(seed, k, 1.0)) * TAU
		var tilt: float = lerpf(-0.35, 0.55, _h(Vector3(seed, k, 2.0)))
		planes.append([Vector3(cos(a) * cos(tilt), sin(tilt), sin(a) * cos(tilt)).normalized(),
			0.66 + 0.22 * _h(Vector3(seed, k, 3.0))])
	var ta: float = _h(Vector3(seed, 9.0, 4.0)) * TAU
	planes.append([Vector3(cos(ta) * 0.18, 1.0, sin(ta) * 0.18).normalized(), top])
	var out := PackedVector3Array()
	out.resize(v.size())
	for i: int in v.size():
		var p: Vector3 = v[i] + _h3(v[i].snappedf(0.001) + Vector3(seed, seed, seed)) * 0.07
		for pl: Array in planes:
			var pn: Vector3 = pl[0]
			var over: float = p.dot(pn) - float(pl[1])
			if over > 0.0:
				p -= pn * over
		out[i] = p * radii
	var n2 := PackedVector3Array()
	n2.resize(n.size())
	for i: int in n.size():
		n2[i] = (n[i] / radii).normalized()
	return _mk(out, n2, arr[Mesh.ARRAY_INDEX])


## A fluted column drum (radius alternates r_out / r_in around 2 * flutes vertices) from y 0 to h, capped both ends.
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


## A broken column top: a ring of radius r at y 0, a jagged rim (0.3..1 x h, a few deep notches) and a sunken,
## off-centre break face.
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
		var notch: float = 0.4 if i % 4 == 1 else 1.0
		var hh: float = h * (0.5 + 0.5 * _h(Vector3(i, seed, 1.0))) * notch
		v.append(Vector3(cos(a) * r * 0.96, hh, sin(a) * r * 0.96))
		n.append(Vector3(cos(a), 0.3, sin(a)).normalized())
	for i: int in segs:
		var j: int = (i + 1) % segs
		idx.append_array([i, j, segs + i, j, segs + j, segs + i])
	var cbase: int = v.size()
	v.append(Vector3(r * 0.2, h * 0.3, -r * 0.1))
	n.append(Vector3.UP)
	for i: int in segs:
		v.append(v[segs + i])
		n.append(Vector3.UP)
	for i: int in segs:
		idx.append_array([cbase, cbase + 1 + i, cbase + 1 + (i + 1) % segs])
	return _mk(v, n, idx)


## A surface of revolution around +Y from (radius, height) profile points with a normal hint per point
## (hint.x radial, hint.y up): outward on the outside of a bowl, inward on its inside.
func _lathe(profile: Array[Vector2], hints: Array[Vector2], segs: int, phase: float = 0.0) -> Array:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var idx := PackedInt32Array()
	for k: int in profile.size():
		var p: Vector2 = profile[k]
		var hn: Vector2 = hints[k]
		for i: int in segs:
			var a: float = i * TAU / segs + phase
			v.append(Vector3(cos(a) * p.x, p.y, sin(a) * p.x))
			n.append(Vector3(cos(a) * hn.x, hn.y, sin(a) * hn.x).normalized())
	for ring: int in profile.size() - 1:
		for i: int in segs:
			var j: int = (i + 1) % segs
			var a0: int = ring * segs + i
			var a1: int = ring * segs + j
			var b0: int = (ring + 1) * segs + i
			var b1: int = (ring + 1) * segs + j
			idx.append_array([a0, a1, b0, a1, b1, b0])
	return _mk(v, n, idx)


## A flat irregular blob just above the ground (spilled ash, the smouldering heart of a moss patch).
func _blob_disc(c: Vector3, rx: float, rz: float, segs: int, seed: float) -> Array:
	var v := PackedVector3Array([c])
	var n := PackedVector3Array([Vector3.UP])
	var idx := PackedInt32Array()
	for i: int in segs:
		var a: float = i * TAU / segs
		var j: float = 1.0 + (_h(Vector3(seed, i, 7.0)) - 0.5) * 0.45
		v.append(c + Vector3(cos(a) * rx * j, -0.012, sin(a) * rz * j))
		n.append(Vector3.UP)
	for i: int in segs:
		idx.append_array([0, 1 + i, 1 + (i + 1) % segs])
	return _mk(v, n, idx)


# --- small dressing ----------------------------------------------------------------------------

## A small tuft of scorched grass (grows in the joints): `count` blades around p.
func _tuft(p: Vector3, count: int, h: float, mask: int, seed: float) -> void:
	for i: int in count:
		var a: float = i * GOLDEN + seed
		var t: float = _h(Vector3(i, seed, 4.0))
		var r: float = 0.02 + 0.05 * sqrt((i + 0.5) / count)
		var base := p + Vector3(cos(a) * r, -0.02, sin(a) * r)
		var hh: float = h * 1.3 * (0.6 + 0.4 * t) * (1.0 - 0.3 * sqrt((i + 0.5) / count))
		var lean := Vector3(cos(a), 0.0, sin(a)) * (0.05 + 0.1 * t)
		var tip: Color = GRASS.lerp(GRASS_T, 0.4 + t * 0.6)
		_part(_blade(base, hh, 0.04, lean, a + PI * 0.5, GRASS_D, tip, 2 if hh > 0.2 else 1), Transform3D.IDENTITY,
			GRASS, {"kind": Kind.IVY, "mask": mask, "normals": "crown", "crown": p + Vector3(0.0, -0.2, 0.0),
			"crown_k": 0.5, "tint": 0.08})


## A loose chip of ruin stone lying on the ground at p.
func _chip(p: Vector3, size: float, col: Color, mask: int, seed: float) -> void:
	_part(_chunk(Vector3(size, size * 0.55, size * 0.8), 3, seed, 0.7, 5, 3), _xf(p + Vector3(0.0, size * 0.18, 0.0),
		Vector3(0.15, seed * 1.7, 0.1)), col, {"mask": mask, "moss": 0.3, "seed": seed, "tint": 0.1,
		"col2": col.lightened(0.08)})


## A cut stone (see _slab) placed with `xf`: dark sides, light top, some moss.
func _stone_slab(outline: PackedVector2Array, h: float, bevel: float, xf: Transform3D, top: Color, mask: int,
		seed: float, moss: float = 0.35, sink: float = 0.06) -> void:
	_part(_slab(outline, h, bevel, sink), xf, STONE_D.lerp(top, 0.25), {"mask": mask, "moss": moss, "seed": seed,
		"col2": top, "grad": "y", "tint": 0.1, "jitter": 0.008, "jit_axes": Vector3(1.0, 0.6, 1.0)})


# --- flagstones --------------------------------------------------------------------------------

func _build_flagstones() -> void:
	_begin(0.9)
	# V0: a big slab split by a crack (the east half lifted on its outer edge) + a small slab with a knocked-off corner.
	var a := PackedVector2Array([Vector2(-0.62, -0.40), Vector2(0.02, -0.44), Vector2(-0.05, -0.17), Vector2(0.07, 0.05),
		Vector2(-0.03, 0.24), Vector2(0.03, 0.42), Vector2(-0.60, 0.38)])
	var b := PackedVector2Array([Vector2(0.11, -0.44), Vector2(0.61, -0.37), Vector2(0.63, 0.40), Vector2(0.12, 0.42),
		Vector2(0.06, 0.24), Vector2(0.16, 0.05), Vector2(0.04, -0.17)])
	_stone_slab(a, 0.09, 0.05, _xf(Vector3(-0.1, 0.0, -0.12), Vector3(0.02, 0.0, 0.0)), STONE_P, V0, 1.0, 0.3)
	_stone_slab(b, 0.1, 0.05, _xf(Vector3(-0.08, 0.035, -0.12), Vector3(0.0, 0.0, 0.07)), STONE_P.darkened(0.04), V0, 2.0,
		0.4)
	_stone_slab(_rect(0.5, 0.44, 3.0, 0.02, 0.14, 2), 0.08, 0.045, _xf(Vector3(-0.32, 0.0, 0.58), Vector3(0.0, 0.12, -0.03)),
		STONE, V0, 3.0, 0.5)
	_tuft(Vector3(-0.07, 0.0, -0.58), 5, 0.22, V0, 4.0)
	_tuft(Vector3(0.1, 0.0, 0.33), 4, 0.18, V0, 5.0)
	_chip(Vector3(0.62, 0.0, 0.52), 0.1, STONE_D, V0, 6.0)
	# V1: one slab heaved up on a wedge of rubble (raised edge ~0.25 m), its broken corner lying beside it.
	var heave := PackedVector2Array([Vector2(-0.6, -0.42), Vector2(0.55, -0.44), Vector2(0.6, 0.12), Vector2(0.36, 0.2),
		Vector2(0.3, 0.43), Vector2(-0.58, 0.4)])
	_stone_slab(heave, 0.11, 0.055, _xf(Vector3(0.0, 0.06, -0.05), Vector3(0.24, 0.3, 0.04)), STONE_P, V1, 11.0, 0.35,
		0.12)
	# (the raised edge is local -Z, turned by the 0.3 yaw: the wedge sits under it)
	_part(_chunk(Vector3(0.26, 0.12, 0.15), 3, 12.0, 0.7, 5, 3), _xf(Vector3(-0.12, 0.04, -0.4), Vector3(0.1, 0.3, 0.0)),
		SOOT.lerp(STONE_D, 0.5), {"mask": V1, "moss": 0.1, "seed": 12.0, "tint": 0.1})
	var corner := PackedVector2Array([Vector2(-0.2, -0.14), Vector2(0.22, -0.12), Vector2(-0.12, 0.2)])
	_stone_slab(corner, 0.07, 0.035, _xf(Vector3(0.62, 0.0, 0.42), Vector3(0.0, 1.1, 0.06)), STONE, V1, 13.0, 0.3)
	_tuft(Vector3(-0.45, 0.0, 0.5), 5, 0.24, V1, 14.0)
	_chip(Vector3(-0.7, 0.0, -0.3), 0.09, STONE_D, V1, 15.0)
	_chip(Vector3(0.32, 0.0, -0.6), 0.07, STONE, V1, 16.0)
	# V2: loose small tiles in two rows, one missing (grass grows in the hole), one cracked in two.
	var k := 0
	for row: int in 2:
		for col: int in 3:
			var cx: float = (col - 1) * 0.47 + row * 0.1
			var cz: float = (row - 0.5) * 0.47
			if row == 1 and col == 1:
				_tuft(Vector3(cx, 0.0, cz), 6, 0.26, V2, 21.0)
				continue
			var tilt := Vector3((_h(Vector3(k, 2, 1)) - 0.5) * 0.09, (_h(Vector3(k, 2, 2)) - 0.5) * 0.3,
				(_h(Vector3(k, 2, 3)) - 0.5) * 0.09)
			var top: Color = STONE_P if (row + col) % 2 == 0 else STONE.lightened(0.05)
			var hh: float = 0.07 + _h(Vector3(k, 2, 4)) * 0.03
			if row == 0 and col == 2:   # cracked tile: two triangles with a gap
				_stone_slab(PackedVector2Array([Vector2(-0.2, -0.2), Vector2(0.19, -0.2), Vector2(-0.2, 0.17)]), hh, 0.03,
					_xf(Vector3(cx - 0.02, 0.0, cz - 0.02), tilt), top, V2, 30.0 + k, 0.4)
				_stone_slab(PackedVector2Array([Vector2(0.2, -0.15), Vector2(0.2, 0.2), Vector2(-0.16, 0.2)]), hh, 0.03,
					_xf(Vector3(cx + 0.02, 0.012, cz + 0.02), tilt + Vector3(0.04, 0.0, -0.05)), top.darkened(0.05), V2,
					31.0 + k, 0.4)
			else:
				_stone_slab(_rect(0.41, 0.41, 40.0 + k, 0.02), hh, 0.035, _xf(Vector3(cx, 0.0, cz), tilt), top, V2, 40.0 + k,
					0.3 + 0.2 * _h(Vector3(k, 3, 3)))
			k += 1
	_chip(Vector3(0.72, 0.0, 0.4), 0.08, STONE_D, V2, 50.0)
	_chip(Vector3(-0.6, 0.0, 0.5), 0.1, STONE, V2, 51.0)
	_tuft(Vector3(-0.72, 0.0, -0.3), 4, 0.2, V2, 52.0)
	_commit("ruins_flagstones", mat)


# --- column drums ------------------------------------------------------------------------------

func _build_drums() -> void:
	_begin(0.0)
	# V0: a standing stub, snapped low, the break face jagged; a chip of it on the ground.
	_part(_fluted(0.46, 0.41, 0.26, 9), _xf(Vector3(0.0, -0.06, 0.0), Vector3(0.0, 0.2, 0.0)), STONE_D.lerp(STONE, 0.5),
		{"mask": V0, "moss": 0.35, "seed": 1.0, "col2": STONE_P, "grad": "y", "jitter": 0.012})
	_part(_broken_top(0.44, 0.14, 12, 2.0), _xf(Vector3(0.0, 0.2, 0.0), Vector3(0.02, 0.7, 0.03)), STONE,
		{"mask": V0, "moss": 0.6, "seed": 2.0, "col2": STONE_P.darkened(0.08), "grad": "y", "jitter": 0.012})
	_chip(Vector3(0.62, 0.0, 0.25), 0.14, STONE, V0, 3.0)
	_chip(Vector3(-0.45, 0.0, 0.48), 0.08, STONE_D, V0, 4.0)
	# V1: two drum slices: a thick disc on the ground, a thinner one slid half off it onto the paving.
	_part(_fluted(0.48, 0.43, 0.2, 10), _xf(Vector3(-0.18, -0.04, 0.0), Vector3(0.03, 0.4, -0.02)), STONE_D.lerp(STONE, 0.5),
		{"mask": V1, "moss": 0.5, "seed": 11.0, "col2": STONE_P, "grad": "y", "jitter": 0.01})
	_part(_fluted(0.4, 0.36, 0.16, 9), _xf(Vector3(0.3, 0.09, 0.08), Vector3(0.06, 0.9, -0.22)), STONE.darkened(0.04),
		{"mask": V1, "moss": 0.35, "seed": 12.0, "col2": STONE_P, "grad": "y", "jitter": 0.01})
	_chip(Vector3(-0.2, 0.0, -0.62), 0.1, STONE_D, V1, 13.0)
	# V2: a drum lying on its side, half sunk (top ~0.37 m), one end snapped.
	var lie := Basis(Vector3.UP, 0.35) * Basis(Vector3.BACK, PI * 0.5)
	_part(_fluted(0.44, 0.39, 0.9, 9), Transform3D(lie, Vector3(0.0, -0.08, 0.0) + lie * Vector3(0.0, -0.45, 0.0)),
		STONE_D.lerp(STONE, 0.4), {"mask": V2, "moss": 0.55, "seed": 21.0, "col2": STONE_P, "grad": "wy",
		"jitter": 0.012})
	_part(_broken_top(0.42, 0.1, 12, 22.0), Transform3D(lie, Vector3(0.0, -0.08, 0.0) + lie * Vector3(0.0, 0.44, 0.0)),
		STONE, {"mask": V2, "moss": 0.2, "seed": 22.0, "jitter": 0.01})
	_chip(Vector3(0.1, 0.0, 0.55), 0.09, STONE, V2, 23.0)
	_tuft(Vector3(-0.3, 0.0, 0.42), 5, 0.22, V2, 24.0)
	_commit("ruins_drums", mat)


# --- ember moss --------------------------------------------------------------------------------

## A squashed moss cushion at c (radius r): dark at the foot, rust on top, a faint warm heat on its crown.
func _cushion(c: Vector3, r: float, mask: int, seed: float, heat_top: float = 0.0, segs: int = 6,
		rings: int = 3) -> void:
	var t: float = _h(Vector3(seed, 1.0, 1.0))
	_part(_sph(r, segs, rings), _xf(c + Vector3(0.0, r * 0.12, 0.0), Vector3(0.0, seed, 0.0), Vector3(1.0, 0.5, 1.0)), MOSS_D,
		{"kind": Kind.STONE, "mask": mask, "normals": "smooth", "col2": MOSS.lerp(MOSS_R, t * 0.2), "heat": 0.0,
		"heat2": heat_top, "jitter": r * 0.12, "seed": seed, "tint": 0.1})


## A glowing frond: a 3-sided spike from p, its tip fully hot.
func _frond(p: Vector3, h: float, lean: Vector3, mask: int, seed: float) -> void:
	_part(_spindle(p, p + Vector3(0.0, h, 0.0) + lean, 0.028, 0.35), Transform3D.IDENTITY, MOSS_R, {"kind": Kind.STONE,
		"mask": mask, "normals": "smooth", "col2": EMBER, "heat": 0.25, "heat2": 1.0, "seed": seed, "tint": 0.05})


## A smouldering bead (joint creepers, crack embers).
func _bead(p: Vector3, r: float, mask: int, heat: float = 1.0) -> void:
	_part(_sph(r, 4, 2), _xf(p, Vector3.ZERO, Vector3(1.0, 0.6, 1.0)), COAL, {"kind": Kind.STONE, "mask": mask,
		"normals": "smooth", "col2": EMBER, "heat": heat * 0.6, "heat2": heat, "tint": 0.04})


func _build_ember_moss() -> void:
	_begin(0.0)
	# V0: cushions ringed round a smouldering heart, hot fronds poking up.
	_part(_blob_disc(Vector3(0.02, 0.03, -0.02), 0.15, 0.13, 9, 1.0), Transform3D.IDENTITY, COAL, {"kind": Kind.STONE,
		"mask": V0, "normals": "up", "col2": EMBER, "grad": "r", "heat": 0.6, "a": 0.2})
	for i: int in 6:
		var a: float = i * TAU / 6.0 + 0.3
		var rr: float = 0.26 + 0.1 * _h(Vector3(i, 1, 1))
		_cushion(Vector3(cos(a) * rr, 0.0, sin(a) * rr), 0.14 + 0.08 * _h(Vector3(i, 1, 2)), V0, 2.0 + i)
	for i: int in 7:
		var a2: float = i * GOLDEN + 0.4
		var rr2: float = 0.12 + 0.3 * _h(Vector3(i, 2, 1))
		var p := Vector3(cos(a2) * rr2, 0.05, sin(a2) * rr2)
		_frond(p, 0.1 + 0.07 * _h(Vector3(i, 2, 2)), Vector3(cos(a2), 0.0, sin(a2)) * 0.04, V0, 10.0 + i)
	# V1: creeping along two paving joints (an L), glowing beads strung along them.
	for s: int in 2:
		var d := Vector3(1, 0, 0) if s == 0 else Vector3(0, 0, 1)
		var start := Vector3(-0.5, 0.0, -0.12) if s == 0 else Vector3(0.12, 0.0, -0.1)
		var length: float = 1.0 if s == 0 else 0.7
		var nseg: int = 5 if s == 0 else 3
		for j: int in nseg:
			var t: float = (j + 0.5) / nseg
			var p2: Vector3 = start + d * length * t + Vector3(d.z, 0.0, d.x) * (_h(Vector3(s, j, 5)) - 0.5) * 0.06
			_cushion(p2, 0.08 + 0.045 * _h(Vector3(s, j, 6)), V1, 20.0 + s * 10 + j, 0.02, 5, 3)
			if j % 2 == 1:
				_bead(p2 + Vector3(0.0, 0.05, 0.0) + Vector3(d.z, 0.0, d.x) * 0.05, 0.04, V1)
	_part(_blob_disc(Vector3(0.12, 0.02, -0.12), 0.12, 0.12, 7, 30.0), Transform3D.IDENTITY, COAL, {"kind": Kind.STONE,
		"mask": V1, "normals": "up", "col2": EMBER, "grad": "r", "heat": 0.7, "a": 0.2})
	_frond(Vector3(0.1, 0.03, -0.14), 0.12, Vector3(0.03, 0.0, 0.02), V1, 31.0)
	_frond(Vector3(0.16, 0.03, -0.08), 0.09, Vector3(-0.02, 0.0, 0.03), V1, 32.0)
	# V2: a fist-sized chunk of ruin stone grown over with ember moss, a hot crack in its top.
	_part(_chunk(Vector3(0.3, 0.22, 0.26), 4, 40.0, 0.75), _xf(Vector3(0.0, 0.1, 0.0), Vector3(0.1, 0.5, 0.05)), STONE_D,
		{"kind": Kind.STONE, "mask": V2, "col2": STONE, "grad": "y", "heat": 0.0, "seed": 40.0, "tint": 0.12})
	_cushion(Vector3(-0.08, 0.2, 0.04), 0.14, V2, 41.0, 0.03)
	_cushion(Vector3(0.28, 0.0, 0.18), 0.13, V2, 42.0)
	_cushion(Vector3(-0.3, 0.0, -0.12), 0.12, V2, 43.0)
	_cushion(Vector3(0.12, 0.0, -0.3), 0.1, V2, 44.0)
	_part(_box(Vector3(0.26, 0.03, 0.035)), _xf(Vector3(0.1, 0.285, -0.03), Vector3(0.0, 0.6, 0.12)), COAL,
		{"kind": Kind.STONE, "mask": V2, "col2": EMBER, "heat": 1.0, "tint": 0.03})
	for i: int in 4:
		var a3: float = i * GOLDEN + 1.0
		var p3 := Vector3(-0.08, 0.26, 0.04) + Vector3(cos(a3), 0.0, sin(a3)) * 0.08
		_frond(p3, 0.08 + 0.04 * _h(Vector3(i, 4, 4)), Vector3(cos(a3), 0.0, sin(a3)) * 0.03, V2, 45.0 + i)
	_frond(Vector3(0.3, 0.05, 0.18), 0.1, Vector3(0.02, 0.0, 0.0), V2, 50.0)
	_commit("ruins_ember_moss", ember_mat)


# --- statue plinths and the cold brazier ---------------------------------------------------------

## A statue foot (sandal) on the plinth top at p, turned `yaw`, with its calf snapped above the ankle.
func _foot(p: Vector3, yaw: float, mask: int, seed: float) -> void:
	var sole := PackedVector2Array([Vector2(-0.075, -0.19), Vector2(0.07, -0.2), Vector2(0.105, -0.02), Vector2(0.1, 0.12),
		Vector2(0.06, 0.2), Vector2(-0.06, 0.2), Vector2(-0.1, 0.1), Vector2(-0.09, -0.04)])
	var b := Basis(Vector3.UP, yaw)
	_part(_slab(sole, 0.1, 0.035, 0.0), Transform3D(b, p), STONE, {"mask": mask, "moss": 0.3, "seed": seed,
		"col2": STONE_P, "grad": "y", "tint": 0.08})
	var heel: Vector3 = p + b * Vector3(0.0, 0.0, -0.1)
	_part(_cyl(0.105, 0.12, 0.2, 8), Transform3D(b, heel + Vector3(0.0, 0.19, 0.0)), STONE, {"mask": mask, "moss": 0.1,
		"seed": seed + 1.0, "col2": STONE_P, "grad": "y", "normals": "smooth", "tint": 0.06})
	_part(_broken_top(0.1, 0.09, 8, seed), Transform3D(b * Basis(Vector3.UP, seed), heel + Vector3(0.0, 0.29, 0.0)),
		STONE_P.darkened(0.06), {"mask": mask, "moss": 0.5, "seed": seed + 2.0})


func _build_monuments() -> void:
	_begin(0.9)
	# V0: a two-step statue plinth, its top cracked through; the statue is gone but for its feet, snapped at the calves.
	_stone_slab(_rect(1.1, 1.06, 1.0, 0.02, 0.1, 1), 0.2, 0.06, _xf(Vector3.ZERO, Vector3(0.0, 0.05, 0.0)), STONE, V0, 1.0,
		0.55, 0.08)
	var top_a := PackedVector2Array([Vector2(-0.4, -0.4), Vector2(0.05, -0.41), Vector2(-0.02, -0.12), Vector2(0.08, 0.1),
		Vector2(0.0, 0.4), Vector2(-0.4, 0.39)])
	var top_b := PackedVector2Array([Vector2(0.11, -0.41), Vector2(0.41, -0.4), Vector2(0.4, 0.4), Vector2(0.07, 0.4),
		Vector2(0.14, 0.1), Vector2(0.04, -0.12)])
	_stone_slab(top_a, 0.19, 0.05, _xf(Vector3(0.0, 0.2, 0.0), Vector3(0.0, 0.05, 0.0)), STONE_P, V0, 2.0, 0.35, 0.02)
	_stone_slab(top_b, 0.19, 0.05, _xf(Vector3(0.02, 0.19, 0.0), Vector3(0.0, 0.05, -0.05)), STONE_P.darkened(0.04), V0,
		3.0, 0.4, 0.02)
	_foot(Vector3(-0.17, 0.39, 0.02), 0.08, V0, 4.0)
	_foot(Vector3(0.2, 0.38, -0.06), -0.22, V0, 7.0)
	_chip(Vector3(0.7, 0.0, 0.3), 0.12, STONE, V0, 10.0)
	_chip(Vector3(-0.35, 0.0, 0.7), 0.1, STONE_D, V0, 11.0)
	_tuft(Vector3(0.6, 0.0, -0.5), 5, 0.26, V0, 12.0)
	# V1: the plinth split in two, one half tipped away; its crowning finial (a banded stone orb) fallen in the grass.
	var half_a := PackedVector2Array([Vector2(-0.55, -0.52), Vector2(0.1, -0.53), Vector2(0.02, -0.2), Vector2(0.12, 0.08),
		Vector2(-0.02, 0.3), Vector2(0.04, 0.52), Vector2(-0.54, 0.5)])
	var half_b := PackedVector2Array([Vector2(0.18, -0.53), Vector2(0.55, -0.5), Vector2(0.54, 0.52), Vector2(0.12, 0.52),
		Vector2(0.06, 0.3), Vector2(0.2, 0.08), Vector2(0.1, -0.2)])
	_stone_slab(half_a, 0.36, 0.06, _xf(Vector3(-0.05, 0.0, 0.0), Vector3(0.0, -0.1, 0.0)), STONE_P, V1, 21.0, 0.5, 0.08)
	_stone_slab(half_b, 0.34, 0.06, _xf(Vector3(0.06, 0.02, 0.0), Vector3(0.04, -0.1, -0.12)), STONE.lightened(0.04), V1,
		22.0, 0.55, 0.12)
	_stone_slab(_rect(0.5, 0.56, 23.0, 0.02, 0.18, 1), 0.14, 0.04, _xf(Vector3(-0.26, 0.36, 0.0), Vector3(0.0, 0.2, 0.0)),
		STONE_P.lightened(0.04), V1, 23.0, 0.3, 0.02)
	_part(_sph(0.22, 8, 5), _xf(Vector3(0.82, 0.17, 0.42), Vector3(0.5, 0.3, 0.3), Vector3(1.0, 0.86, 1.0)), STONE_D,
		{"mask": V1, "moss": 0.5, "seed": 24.0, "col2": STONE_P, "grad": "wy", "normals": "smooth", "tint": 0.06})
	_part(_cyl(0.235, 0.235, 0.06, 10), _xf(Vector3(0.82, 0.17, 0.42), Vector3(0.5, 0.3, 0.3)), BRONZE.darkened(0.25),
		{"kind": Kind.BARK, "mask": V1, "moss": 0.0, "normals": "smooth", "tint": 0.06})
	_chip(Vector3(0.35, 0.0, -0.72), 0.12, STONE, V1, 25.0)
	_tuft(Vector3(0.18, 0.0, 0.62), 5, 0.25, V1, 26.0)
	# V2: a cold brazier: octagonal footing, a sooty fluted post, a wide iron bowl full of grey ash and charcoal, three
	# claws on the rim, a bronze band; spilled ash on the ground.
	_stone_slab(_ngon(0.46, 8, 0.2), 0.15, 0.05, Transform3D.IDENTITY, STONE, V2, 31.0, 0.5, 0.06)
	_part(_fluted(0.19, 0.165, 0.3, 8), _xf(Vector3(0.0, 0.14, 0.0)), STONE, {"mask": V2, "moss": 0.1, "seed": 32.0,
		"col2": SOOT, "grad": "y", "tint": 0.08})
	_part(_cyl(0.23, 0.2, 0.07, 8), _xf(Vector3(0.0, 0.47, 0.0)), IRON_L, {"kind": Kind.BARK, "mask": V2, "moss": 0.0,
		"tint": 0.05})
	var bowl: Array[Vector2] = [Vector2(0.14, 0.49), Vector2(0.3, 0.53), Vector2(0.4, 0.61), Vector2(0.45, 0.7),
		Vector2(0.47, 0.76), Vector2(0.42, 0.77), Vector2(0.38, 0.7), Vector2(0.26, 0.63)]
	var hints: Array[Vector2] = [Vector2(0.3, -1.0), Vector2(0.6, -0.8), Vector2(1.0, -0.4), Vector2(1.0, 0.0),
		Vector2(0.4, 1.0), Vector2(-0.3, 1.0), Vector2(-1.0, 0.3), Vector2(-0.6, 1.0)]
	_part(_lathe(bowl, hints, 10, 0.1), Transform3D.IDENTITY, IRON, {"kind": Kind.BARK, "mask": V2, "moss": 0.0,
		"col2": IRON_L, "grad": "y", "tint": 0.06})
	_part(_cyl(0.425, 0.405, 0.045, 10), _xf(Vector3(0.0, 0.63, 0.0)), BRONZE, {"kind": Kind.BARK, "mask": V2,
		"moss": 0.0, "normals": "smooth", "tint": 0.05})
	_part(_sph(0.37, 9, 3), _xf(Vector3(0.0, 0.66, 0.0), Vector3.ZERO, Vector3(1.0, 0.3, 1.0)), ASH, {"mask": V2,
		"moss": 0.0, "col2": ASH_L, "grad": "y", "normals": "smooth", "jitter": 0.015, "seed": 34.0, "tint": 0.1})
	for i: int in 5:
		var a: float = i * GOLDEN + 0.6
		var rr: float = 0.08 + 0.2 * _h(Vector3(i, 35, 1))
		_part(_chunk(Vector3(0.1, 0.06, 0.08) * (0.8 + 0.5 * _h(Vector3(i, 35, 2))), 3, 36.0 + i, 0.7, 5, 2),
			_xf(Vector3(cos(a) * rr, 0.745 - rr * 0.1, sin(a) * rr), Vector3(0.3, a, 0.2)), CHAR, {"mask": V2,
			"moss": 0.0, "seed": 36.0 + i, "tint": 0.15})
	for i: int in 3:
		var a2: float = i * TAU / 3.0 + 0.5
		var d := Vector3(cos(a2), 0.0, sin(a2))
		_part(_box(Vector3(0.06, 0.16, 0.1)), Transform3D(Basis(Vector3.UP, -a2) * Basis(Vector3.BACK, -0.35),
			d * 0.46 + Vector3(0.0, 0.76, 0.0)), IRON_L, {"kind": Kind.BARK, "mask": V2, "moss": 0.0, "tint": 0.05})
	_part(_blob_disc(Vector3(0.42, 0.015, 0.3), 0.36, 0.26, 9, 38.0), Transform3D.IDENTITY, ASH, {"mask": V2,
		"moss": 0.0, "normals": "up", "col2": ASH_L.darkened(0.1), "grad": "r", "a": 0.15})
	_chip(Vector3(-0.55, 0.0, 0.35), 0.08, CHAR.lightened(0.1), V2, 39.0)
	_commit("ruins_monuments", mat)
