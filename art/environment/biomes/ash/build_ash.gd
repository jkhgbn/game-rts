extends SceneTree
## Task 12b.V4 (docs/design/terrain.md 7.2 "ash" + 10): generates the Cinder Scar decor and its static-scar particles.
##   ash_charred_wood.res   charred stumps and burnt logs, ash_char_mat.tres (ash_char.gdshader: coal-black char
##                          checks, pale ash on the tops, a few smouldering seams). 3 variants through the variant mask:
##                          V0 broken stump ~0.7 m wide with a jagged splintered crown, a glowing heart in its top and an
##                          ash heap at its foot; V1 a fallen log broken in two (~2.3 m), the broken ends glowing over a
##                          pale ash heap; V2 a leaning burnt snag ~1.6 m with a broken branch and a short log at its foot
##   ash_burnt_grass.res    blackened grass tufts, the SHARED nature_mat.tres (stiff: little wind). V0 charred stubble
##                          with curled ash-grey tips round a pinch of ash, V1 a half-burnt tuft (black stems, scorched
##                          straw tops: the edge of the burn), V2 a "ghost" tuft of pale ash that kept the grass's shape
##   ash_scar_fx.tscn       one per static Cinder Scar (r 4.5): EmberMotes (GPUParticles3D, 16 additive quads, no light)
##                          + SmokeColumn (8 soft puffs, a thin wisp ~6 m tall leaning downwind)
##   ash_smoke_tex.res      the smoke puff mask (64 x 64, mipmapped) used by SmokeColumn
## Vertex data: COLOR.rgb colour, COLOR.a height gradient, UV.x heat (charred wood) or wind weight (grass), UV.y local
## height, UV2 = (variant mask, kind). Every mesh is indexed (welded), one surface, one shared material. No lights.
## Re-run after a change:
##   $GODOT --headless --path . -s res://art/environment/biomes/ash/build_ash.gd --quit-after 600

const DIR := "res://art/environment/biomes/ash/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CHAR_MAT := "res://art/environment/biomes/ash/ash_char_mat.tres"

## ash_char.gdshader kinds (UV2.y).
enum { K_WOOD = 0, K_COAL = 1, K_EMBER = 2 }
## nature_painted.gdshader kinds (UV2.y).
enum { N_BARK = 0, N_STONE = 3, N_IVY = 5 }
const V0 := 1
const V1 := 2
const V2 := 4
const WMAX := 0.45
const GOLDEN := 2.39996

# Palette (sRGB). Coal-black wood a touch warm (brown-black, not blue), grey splinter tips, pale ash; the ember glow is
# in the shader (Fire glow #FF8C26 family).
const CHAR_D := Color(0.035, 0.031, 0.028)
const CHAR := Color(0.07, 0.062, 0.056)
const CHAR_L := Color(0.13, 0.115, 0.10)
const SPLINTER := Color(0.30, 0.285, 0.27)
const ROOT := Color(0.09, 0.075, 0.06)
const COAL := Color(0.05, 0.045, 0.045)
const ASH := Color(0.34, 0.325, 0.31)
const ASH_L := Color(0.44, 0.425, 0.40)
const EMBER := Color(0.20, 0.08, 0.03)
const BG_ROOT := Color(0.045, 0.04, 0.035)
const BG_BLACK := Color(0.085, 0.075, 0.065)
const BG_BROWN := Color(0.25, 0.16, 0.08)
const BG_SINGE := Color(0.50, 0.27, 0.10)
const BG_ASH := Color(0.38, 0.365, 0.345)
const BG_ASH_L := Color(0.55, 0.535, 0.51)
const BG_STRAW := Color(0.70, 0.58, 0.32)
const BG_STRAW_D := Color(0.42, 0.32, 0.16)

var _conv: float = 1.0
var _wind_k: float = 0.0
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _uv := PackedVector2Array()
var _uv2 := PackedVector2Array()
var _report: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_detect_winding()
	var nature := load(NATURE_MAT) as ShaderMaterial
	var char_mat := load(CHAR_MAT) as ShaderMaterial
	if nature == null or char_mat == null:
		push_error("ash: materials missing")
		quit(1)
		return
	_build_charred_wood(char_mat)
	_build_burnt_grass(nature)
	_build_scar_fx()
	for line: String in _report:
		print(line)
	print("ASH BUILD OK")
	quit()


# --- helpers (build_heath.gd's toolkit, + a heat channel) ---------------------------------------

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


func _cyl(top: float, bottom: float, h: float, segs: int = 8, rings: int = 0) -> Array:
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
##   kind (UV2.y), mask (variant bits, 0 = always), jitter (m), seed, jit_axes, normals: "flat" | "smooth" |
##   "crown" (smooth, bent away from `crown`, weight crown_k), col2 + grad ("y" part height | "wy" mesh height),
##   tint (random value variation per face, default 0.08), lift (metres added to UV.y), a (fixed COLOR.a),
##   heat + heat_c + heat_r (UV.x = heat, fading to 0 at heat_r metres from heat_c; heat_r 0 = everywhere),
##   wind (weight per metre for nature meshes, default the mesh's), clip_y (drop triangles entirely below it).
##   Per-vertex colours in the arrays (ARRAY_COLOR) win over col / col2.
func _part(arr: Array, xf: Transform3D, col: Color, o: Dictionary = {}) -> void:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var vc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	if idx.is_empty():
		for i: int in v.size():
			idx.append(i)
	var kind: int = o.get("kind", K_WOOD)
	var mask: int = o.get("mask", 0)
	var jitter: float = o.get("jitter", 0.0)
	var seed: float = o.get("seed", 0.0)
	var jit_axes: Vector3 = o.get("jit_axes", Vector3.ONE)
	var mode: String = o.get("normals", "flat")
	var crown: Vector3 = o.get("crown", Vector3.ZERO)
	var crown_k: float = o.get("crown_k", 0.6)
	var col2: Color = o.get("col2", col)
	var grad: String = o.get("grad", "y")
	var tint: float = o.get("tint", 0.08)
	var lift: float = o.get("lift", 0.0)
	var alpha: float = o.get("a", -1.0)
	var wk: float = o.get("wind", _wind_k)
	var has_heat: bool = o.has("heat")
	var heat: float = o.get("heat", 0.0)
	var heat_c: Vector3 = o.get("heat_c", Vector3.ZERO)
	var heat_r: float = o.get("heat_r", 0.0)
	var clip_y: float = o.get("clip_y", -INF)
	var nb: Basis = xf.basis.inverse().transposed()
	var miny: float = INF
	var maxy: float = -INF
	for p: Vector3 in v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
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
		for vi: int in [a, b, c]:
			var nn: Vector3 = fn
			if mode == "smooth":
				nn = tn[vi]
			elif mode == "crown":
				nn = tn[vi].lerp((tv[vi] - crown).normalized(), crown_k).normalized()
			var cc: Color
			if not vc.is_empty():
				cc = vc[vi]
			else:
				var gt: float = 0.0
				if grad == "y":
					gt = clampf((v[vi].y - miny) / maxf(maxy - miny, 0.001), 0.0, 1.0)
				else:
					gt = clampf((tv[vi].y - wminy) / maxf(wmaxy - wminy, 0.001), 0.0, 1.0)
				cc = col.lerp(col2, gt)
			var k: float = fk if mode == "flat" else 1.0 + (_h(tv[vi].snappedf(0.02)) - 0.5) * tint
			_v.append(tv[vi])
			_n.append(nn)
			_c.append(Color(cc.r * k, cc.g * k, cc.b * k, alpha))
			var ux: float
			if has_heat:
				ux = heat
				if heat_r > 0.0:
					ux *= 1.0 - smoothstep(heat_r * 0.25, heat_r, tv[vi].distance_to(heat_c))
			else:
				ux = clampf(tv[vi].y * wk, 0.0, WMAX)
			_uv.append(Vector2(ux, tv[vi].y + lift))
			_uv2.append(Vector2(mask, kind))


## Bakes the height gradient (COLOR.a, unless a part fixed it), welds, saves DIR/<name>.res with `mat`.
func _commit(name: String, mat: Material) -> ArrayMesh:
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
	_save(mesh, DIR + name + ".res")
	var per := [0, 0, 0]
	for t: int in range(0, _uv2.size(), 3):
		var m: int = int(_uv2[t].x)
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
	var aabb: AABB = mesh.get_aabb()
	_report.append("mesh %-18s %4d tris, %4d verts (variants %d / %d / %d), aabb %s .. %s" % [
		name, _v.size() / 3, (welded[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), per[0], per[1], per[2],
		aabb.position.snappedf(0.01), aabb.end.snappedf(0.01)])
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
		oc.append(sc[i])
		ou.append(su[i])
		o2.append(s2[i])
	out[Mesh.ARRAY_VERTEX] = ov
	out[Mesh.ARRAY_NORMAL] = on
	out[Mesh.ARRAY_COLOR] = oc
	out[Mesh.ARRAY_TEX_UV] = ou
	out[Mesh.ARRAY_TEX_UV2] = o2
	out[Mesh.ARRAY_INDEX] = remap
	return out


# --- shape builders ------------------------------------------------------------------------------

## A 3-sided double pyramid from `a` to `b` (splinters, thorns), radius `r` at `bulge` (0-1).
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


## A chiselled lump (build_nature.gd's recipe): a unit sphere cut by `cuts` random planes, jittered, scaled by `radii`.
func _chunk(radii: Vector3, cuts: int, seed: float, top: float = 0.78, segs: int = 6, rings: int = 3) -> Array:
	var arr: Array = _sph(1.0, segs, rings)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var planes: Array = []
	for k: int in cuts:
		var a: float = _h(Vector3(seed, k, 1.0)) * TAU
		var tilt: float = lerpf(-0.35, 0.55, _h(Vector3(seed, k, 2.0)))
		var pn := Vector3(cos(a) * cos(tilt), sin(tilt), sin(a) * cos(tilt)).normalized()
		planes.append([pn, 0.66 + 0.22 * _h(Vector3(seed, k, 3.0))])
	planes.append([Vector3.UP, top])
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


## A tapered cylinder from `a` to `b` (logs, roots, branches): radius r0 at a, r1 at b.
func _limb(a: Vector3, b: Vector3, r0: float, r1: float, col: Color, o: Dictionary, segs: int = 8,
		rings: int = 2) -> void:
	var d: Vector3 = b - a
	var basis := Basis(Quaternion(Vector3.UP, d.normalized()))
	_part(_cyl(r1, r0, d.length(), segs, rings), Transform3D(basis, (a + b) * 0.5), col, o)


## A grass blade: a flattened 3-sided spike in 2 segments, bent by `lean` (the middle ring carries a quarter of it).
func _bent_blade(base: Vector3, h: float, w: float, lean: Vector3, face: float, c0: Color, c1: Color) -> Array:
	var side := Vector3(cos(face), 0.0, sin(face))
	var out := Vector3(-side.z, 0.0, side.x)
	var tip: Vector3 = base + Vector3(0.0, maxf(h - lean.length() * 0.3, h * 0.3), 0.0) + lean
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


# --- charred wood ----------------------------------------------------------------------------------

func _wood(mask: int, seed: float, heat: float = 0.0, heat_c: Vector3 = Vector3.ZERO, heat_r: float = 0.0,
		jitter: float = 0.03) -> Dictionary:
	return {"kind": K_WOOD, "mask": mask, "seed": seed, "jitter": jitter, "col2": CHAR_L, "grad": "wy", "tint": 0.14,
		"heat": heat, "heat_c": heat_c, "heat_r": heat_r, "clip_y": -0.03}


func _splinters(centre: Vector3, rim_r: float, y: float, count: int, h0: float, h1: float, mask: int, seed: float,
		up: Vector3 = Vector3.UP, tall_at: float = -1.0) -> void:
	var x: Vector3 = up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var z: Vector3 = x.cross(up).normalized()
	for i: int in count:
		var a: float = i * TAU / count + _h(Vector3(i, seed, 1.0)) * 0.6
		var rad: Vector3 = x * cos(a) + z * sin(a)
		var t: float = _h(Vector3(i, seed, 2.0))
		var h: float = lerpf(h0, h1, t)
		if tall_at >= 0.0 and absf(wrapf(a - tall_at, -PI, PI)) < 0.6:
			h = h1 * 1.35
		var base: Vector3 = centre + up * y + rad * rim_r * 0.82
		var tip: Vector3 = base + up * h + rad * (0.03 + t * 0.06)
		var w: float = 0.05 + 0.03 * _h(Vector3(i, seed, 3.0))
		_part(_spindle(base - up * 0.06, tip, w, 0.25, CHAR, SPLINTER.darkened(0.25 * t)), Transform3D.IDENTITY, CHAR,
			{"kind": K_WOOD, "mask": mask, "normals": "smooth", "tint": 0.1, "heat": 0.0})


func _coals(spots: Array, mask: int, seed: float) -> void:
	for i: int in spots.size():
		var s: Array = spots[i]
		var p: Vector3 = s[0]
		var r: float = s[1]
		var hot: float = s[2]
		_part(_chunk(Vector3(r * 1.2, r * 0.75, r), 3, seed + i, 0.72), _xf(p, Vector3(0.2, seed + i * 1.7, 0.1)),
			COAL if hot < 0.5 else EMBER, {"kind": K_EMBER if hot > 0.0 else K_COAL, "mask": mask, "heat": hot,
			"tint": 0.12, "clip_y": -0.02})


func _ash_heap(p: Vector3, rx: float, rz: float, h: float, mask: int, seed: float) -> void:
	_part(_sph(1.0, 8, 3), _xf(p, Vector3(0.0, seed, 0.0), Vector3(rx, h, rz)), ASH,
		{"kind": K_COAL, "mask": mask, "jitter": 0.035, "seed": seed, "col2": ASH_L, "grad": "y", "tint": 0.06,
		"normals": "crown", "crown": p - Vector3(0.0, h * 0.6, 0.0), "crown_k": 0.4, "heat": 0.0, "clip_y": -0.01})


func _build_charred_wood(mat: Material) -> void:
	_begin(0.0)
	# V0: a broken stump ~0.7 m across, 0.66 m to its charred top, splinters to ~1.1 m on one side.
	var foot_glow := Vector3(0.3, 0.08, 0.1)
	_part(_cyl(0.25, 0.33, 0.66, 11, 3), _xf(Vector3(0.0, 0.33, 0.0)), CHAR, _wood(V0, 1.0, 0.75, foot_glow, 0.3, 0.035))
	_part(_cyl(0.15, 0.13, 0.06, 9), _xf(Vector3(0.02, 0.645, -0.01)), EMBER,
		{"kind": K_EMBER, "mask": V0, "heat": 0.6, "tint": 0.1, "jitter": 0.012, "seed": 3.0})
	_splinters(Vector3.ZERO, 0.27, 0.62, 8, 0.1, 0.34, V0, 2.0, Vector3.UP, 0.8)
	for i: int in 5:
		var a: float = i * TAU / 5.0 + 0.35
		var reach: float = 0.58 + 0.14 * _h(Vector3(i, 4.0, 1.0))
		var d := Vector3(cos(a), 0.0, sin(a))
		_limb(d * 0.2 + Vector3(0.0, 0.13, 0.0), d * reach + Vector3(0.0, -0.04, 0.0), 0.12, 0.035, ROOT,
			_wood(V0, 10.0 + i, 0.0, Vector3.ZERO, 0.0, 0.02), 6, 1)
	_part(_box(Vector3(0.07, 0.3, 0.07)), _xf(Vector3(0.315, 0.2, 0.02), Vector3(0.0, 0.0, 0.08)), EMBER,
		{"kind": K_EMBER, "mask": V0, "heat": 1.0, "tint": 0.05})
	_ash_heap(Vector3(-0.42, 0.0, 0.34), 0.34, 0.26, 0.09, V0, 5.0)
	_coals([[Vector3(-0.36, 0.05, 0.3), 0.08, 0.9], [Vector3(0.5, 0.04, -0.3), 0.1, 0.0],
		[Vector3(-0.12, 0.03, -0.55), 0.07, 0.0]], V0, 20.0)
	# V1: a fallen log broken in two (~2.3 m), the broken ends smouldering over a pale ash heap.
	var gap := Vector3(0.02, 0.0, 0.03)
	var a0 := Vector3(-1.2, 0.17, 0.12)
	var a1 := Vector3(-0.14, 0.2, 0.0)
	_limb(a0, a1, 0.21, 0.19, CHAR, _wood(V1, 30.0, 0.95, a1, 0.42), 11, 4)
	var b0 := Vector3(0.14, 0.16, 0.02)
	var b1 := Vector3(1.0, 0.13, -0.42)
	_limb(b0, b1, 0.18, 0.15, CHAR, _wood(V1, 31.0, 0.9, b0, 0.38), 10, 3)
	_splinters(a1, 0.18, -0.02, 5, 0.08, 0.2, V1, 32.0, (a1 - a0).normalized())
	_splinters(b0, 0.16, -0.02, 4, 0.07, 0.16, V1, 33.0, (b0 - b1).normalized())
	_limb(Vector3(-0.72, 0.3, 0.06), Vector3(-0.56, 0.66, 0.3), 0.065, 0.035, CHAR, _wood(V1, 34.0, 0.0), 6, 1)
	_limb(Vector3(0.62, 0.22, -0.22), Vector3(0.74, 0.5, -0.02), 0.05, 0.028, CHAR, _wood(V1, 35.0, 0.0), 5, 1)
	_ash_heap(gap + Vector3(0.0, 0.0, 0.04), 0.46, 0.34, 0.11, V1, 36.0)
	_coals([[Vector3(-0.03, 0.08, 0.1), 0.08, 1.0], [Vector3(0.12, 0.06, -0.14), 0.07, 1.0],
		[Vector3(-0.2, 0.05, -0.2), 0.06, 0.7], [Vector3(-1.35, 0.04, -0.2), 0.09, 0.0]], V1, 40.0)
	# V2: a leaning burnt snag ~1.6 m (broken crown, one broken branch), a short log smouldering at its foot.
	var lean := Basis.from_euler(Vector3(0.05, 0.0, -0.1))
	var top := lean * Vector3(0.0, 1.5, 0.0)
	_part(_cyl(0.11, 0.21, 1.52, 10, 5), Transform3D(lean, lean * Vector3(0.0, 0.76, 0.0)), CHAR,
		_wood(V2, 50.0, 0.6, Vector3(0.12, 0.1, 0.18), 0.28, 0.03))
	_splinters(top, 0.12, -0.04, 5, 0.12, 0.3, V2, 51.0, lean * Vector3.UP, 2.4)
	var br0: Vector3 = lean * Vector3(0.02, 1.02, 0.0)
	_limb(br0, br0 + Vector3(-0.44, 0.34, 0.12), 0.065, 0.03, CHAR, _wood(V2, 52.0, 0.0), 6, 1)
	_limb(br0 + Vector3(-0.2, 0.16, 0.05), br0 + Vector3(-0.28, 0.42, -0.1), 0.03, 0.015, CHAR, _wood(V2, 53.0, 0.0), 4, 0)
	for i: int in 3:
		var a: float = i * TAU / 3.0 + 0.9
		var d := Vector3(cos(a), 0.0, sin(a))
		_limb(d * 0.14 + Vector3(0.0, 0.1, 0.0), d * 0.5 + Vector3(0.0, -0.04, 0.0), 0.08, 0.03, ROOT,
			_wood(V2, 54.0 + i, 0.0, Vector3.ZERO, 0.0, 0.02), 6, 1)
	var l0 := Vector3(0.36, 0.12, 0.34)
	var l1 := Vector3(0.98, 0.11, 0.56)
	_limb(l0, l1, 0.13, 0.12, CHAR, _wood(V2, 58.0, 0.9, l1, 0.3), 9, 2)
	_splinters(l1, 0.11, -0.02, 3, 0.06, 0.12, V2, 59.0, (l1 - l0).normalized())
	_ash_heap(Vector3(1.04, 0.0, 0.66), 0.26, 0.22, 0.07, V2, 60.0)
	_coals([[Vector3(1.1, 0.04, 0.7), 0.06, 1.0], [Vector3(-0.3, 0.04, 0.28), 0.08, 0.0],
		[Vector3(0.1, 0.03, -0.4), 0.07, 0.0]], V2, 61.0)
	_commit("ash_charred_wood", mat)


# --- blackened grass ------------------------------------------------------------------------------

func _build_burnt_grass(mat: Material) -> void:
	_begin(0.25)
	# V0: charred stubble (0.1-0.26 m), black with singed or ash-grey tips, a few blades curled over, a pinch of ash.
	for i: int in 18:
		var a: float = i * GOLDEN + 0.3
		var t: float = _h(Vector3(i, 1.0, 1.0))
		var r: float = 0.04 + 0.2 * sqrt((i + 0.5) / 18.0)
		var p := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var h: float = lerpf(0.26, 0.1, sqrt((i + 0.5) / 18.0)) * (0.8 + t * 0.4)
		var curled: bool = i % 4 == 1
		var la: float = a + (t - 0.5) * 1.2
		var lean := Vector3(cos(la), 0.0, sin(la)) * h * (0.75 if curled else 0.12 + t * 0.2)
		var tip: Color = BG_ASH_L if curled else (BG_SINGE if t > 0.55 else BG_BROWN)
		_part(_bent_blade(p, h, 0.03 + t * 0.012, lean, a + PI * 0.5, BG_ROOT, tip), Transform3D.IDENTITY, BG_BLACK,
			{"kind": N_IVY, "mask": V0, "normals": "smooth", "tint": 0.06})
	_part(_sph(1.0, 7, 3), _xf(Vector3(0.02, 0.0, 0.0), Vector3.ZERO, Vector3(0.12, 0.035, 0.1)), Color(0.2, 0.19, 0.18),
		{"kind": N_STONE, "mask": V0, "wind": 0.0, "col2": Color(0.26, 0.25, 0.235), "tint": 0.05, "clip_y": -0.01})
	# V1: half-burnt tuft (0.25-0.45 m): black stems burnt up to a line, scorched straw tops (the edge of the burn).
	for i: int in 12:
		var a: float = i * GOLDEN + 1.1
		var t: float = _h(Vector3(i, 2.0, 1.0))
		var r: float = 0.03 + 0.15 * sqrt((i + 0.5) / 12.0)
		var p := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var h: float = lerpf(0.46, 0.26, sqrt((i + 0.5) / 12.0)) * (0.85 + t * 0.3)
		var lean := Vector3(cos(a + 0.4), 0.0, sin(a + 0.4)) * h * (0.2 + t * 0.35)
		_part(_bent_blade(p, h, 0.034, lean, a + PI * 0.5, BG_BLACK, BG_STRAW if t > 0.4 else BG_STRAW_D),
			Transform3D.IDENTITY, BG_BLACK, {"kind": N_IVY, "mask": V1, "normals": "smooth", "tint": 0.07})
	for i: int in 6:
		var a: float = i * TAU / 6.0 + 0.5
		var p := Vector3(cos(a) * 0.2, -0.02, sin(a) * 0.2)
		_part(_bent_blade(p, 0.12, 0.03, Vector3(cos(a), 0.0, sin(a)) * 0.03, a, BG_ROOT, BG_BROWN),
			Transform3D.IDENTITY, BG_BLACK, {"kind": N_IVY, "mask": V1, "normals": "smooth", "tint": 0.06})
	# V2: a "ghost" tuft of pale ash that kept the grass's shape, round a few black stubs.
	for i: int in 11:
		var a: float = i * GOLDEN + 2.0
		var t: float = _h(Vector3(i, 3.0, 1.0))
		var r: float = 0.03 + 0.16 * sqrt((i + 0.5) / 11.0)
		var p := Vector3(cos(a) * r, -0.02, sin(a) * r)
		var h: float = lerpf(0.34, 0.2, sqrt((i + 0.5) / 11.0)) * (0.85 + t * 0.3)
		var lean := Vector3(cos(a), 0.0, sin(a)) * h * (0.25 + t * 0.3)
		_part(_bent_blade(p, h, 0.036, lean, a + PI * 0.5, BG_ASH.darkened(0.35), BG_ASH_L),
			Transform3D.IDENTITY, BG_ASH, {"kind": N_IVY, "mask": V2, "normals": "smooth", "tint": 0.05})
	for i: int in 5:
		var a: float = i * TAU / 5.0 + 0.2
		var p := Vector3(cos(a) * 0.24, -0.02, sin(a) * 0.24)
		_part(_bent_blade(p, 0.1, 0.03, Vector3.ZERO, a, BG_ROOT, BG_BLACK), Transform3D.IDENTITY, BG_BLACK,
			{"kind": N_IVY, "mask": V2, "normals": "smooth", "tint": 0.06})
	_commit("ash_burnt_grass", mat)


# --- static-scar particles --------------------------------------------------------------------------

func _build_scar_fx() -> void:
	var smoke_tex := _puff_texture()
	_save(smoke_tex, DIR + "ash_smoke_tex.res")
	smoke_tex = load(DIR + "ash_smoke_tex.res") as ImageTexture
	var fx := Node3D.new()
	fx.name = "AshScarFx"
	fx.set_meta(&"scar_radius", 4.5)
	# Ember motes: 16 additive dots drifting up out of the scar, flickering as they cool.
	var motes := GPUParticles3D.new()
	motes.name = "EmberMotes"
	motes.amount = 16
	motes.lifetime = 3.4
	motes.preprocess = 3.4
	motes.fixed_fps = 30
	motes.interpolate = true
	motes.local_coords = true
	motes.randomness = 0.5
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	motes.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	motes.visibility_aabb = AABB(Vector3(-5.5, -0.5, -5.5), Vector3(11.0, 5.5, 11.0))
	motes.visibility_range_end = 90.0
	var mm := ParticleProcessMaterial.new()
	mm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mm.emission_ring_axis = Vector3.UP
	mm.emission_ring_radius = 3.9
	mm.emission_ring_inner_radius = 0.0
	mm.emission_ring_height = 0.1
	mm.direction = Vector3.UP
	mm.spread = 18.0
	mm.initial_velocity_min = 0.25
	mm.initial_velocity_max = 0.7
	mm.gravity = Vector3(0.1, 0.32, 0.075)
	mm.damping_min = 0.05
	mm.damping_max = 0.15
	mm.turbulence_enabled = true
	mm.turbulence_noise_strength = 0.6
	mm.turbulence_noise_scale = 2.6
	mm.turbulence_noise_speed_random = 0.4
	mm.turbulence_influence_min = 0.05
	mm.turbulence_influence_max = 0.14
	mm.scale_min = 0.07
	mm.scale_max = 0.12
	mm.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.15, 1.0), Vector2(0.7, 0.8), Vector2(1.0, 0.2)])
	var hot := _hdr(Color(1.0, 0.78, 0.4), 3.0)
	var ember := _hdr(Color(1.0, 0.45, 0.12), 2.6)
	var dim := _hdr(Color(0.9, 0.3, 0.08), 1.3)
	mm.color_ramp = _ramp_at([0.0, 0.08, 0.25, 0.36, 0.5, 0.62, 0.8, 1.0],
		[Color(hot, 0.0), hot, dim, ember, dim, ember, Color(dim, 0.6), Color(dim, 0.0)])
	motes.process_material = mm
	motes.draw_pass_1 = _particle_quad(_dot_texture(), BaseMaterial3D.BLEND_MODE_ADD, false)
	fx.add_child(motes)
	motes.owner = fx
	# A thin smoke column: 8 soft puffs rising ~6 m from one smouldering spot, leaning downwind (0.8, 0.6).
	var smoke := GPUParticles3D.new()
	smoke.name = "SmokeColumn"
	smoke.position = Vector3(0.9, 0.25, -0.7)
	smoke.amount = 8
	smoke.lifetime = 7.0
	smoke.preprocess = 7.0
	smoke.fixed_fps = 30
	smoke.interpolate = true
	smoke.local_coords = true
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smoke.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	smoke.visibility_aabb = AABB(Vector3(-3.0, -0.5, -3.0), Vector3(9.0, 9.0, 8.0))
	smoke.visibility_range_end = 90.0
	var sm := ParticleProcessMaterial.new()
	sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sm.emission_sphere_radius = 0.3
	sm.direction = Vector3.UP
	sm.spread = 6.0
	sm.initial_velocity_min = 0.55
	sm.initial_velocity_max = 0.75
	sm.gravity = Vector3(0.12, 0.05, 0.09)
	sm.damping_min = 0.02
	sm.damping_max = 0.06
	sm.angle_min = -180.0
	sm.angle_max = 180.0
	sm.angular_velocity_min = -14.0
	sm.angular_velocity_max = 14.0
	sm.scale_min = 1.5
	sm.scale_max = 1.9
	sm.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.35, 0.65), Vector2(1.0, 1.0)])
	sm.color_initial_ramp = _ramp_at([0.0, 0.5, 1.0], _lin([Color(0.46, 0.44, 0.43), Color(0.56, 0.55, 0.54),
		Color(0.5, 0.49, 0.49)]))
	sm.color_ramp = _ramp_at([0.0, 0.12, 0.55, 1.0], [Color(0.75, 0.72, 0.7, 0.0), Color(0.85, 0.84, 0.83, 0.52),
		Color(1.0, 1.0, 1.0, 0.34), Color(1.0, 1.0, 1.0, 0.0)])
	smoke.process_material = sm
	smoke.draw_pass_1 = _particle_quad(smoke_tex, BaseMaterial3D.BLEND_MODE_MIX, true)
	fx.add_child(smoke)
	smoke.owner = fx
	var ps := PackedScene.new()
	var err: int = ps.pack(fx)
	if err != OK:
		push_error("ash_scar_fx pack failed %d" % err)
	_save(ps, DIR + "ash_scar_fx.tscn")
	fx.free()
	_report.append("scene ash_scar_fx.tscn: EmberMotes 16 (additive, unshaded), SmokeColumn 8 (mix), no lights")


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode, soft: bool) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.disable_fog = blend == BaseMaterial3D.BLEND_MODE_ADD  # G-E 5: an additive quad must not fog
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true   # Godot 4.7: without it the particle scale is ignored
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	if soft:
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.4
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = mat
	return q


func _dot_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 32
	t.height = 32
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


## A soft smoke puff mask (mapfill_vfx.gd's "smoke"): noise-eroded disc, lighter on top.
func _puff_texture() -> ImageTexture:
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
			var a := clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
			var shade := clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse - 0.5) * 0.25, 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _vn(x: float, y: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(_h2(ix, iy), _h2(ix + 1.0, iy), fx), lerpf(_h2(ix, iy + 1.0), _h2(ix + 1.0, iy + 1.0), fx), fy)


func _h2(x: float, y: float) -> float:
	return fposmod(sin(x * 127.1 + y * 311.7) * 43758.5453, 1.0)


func _hdr(c: Color, energy: float) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, 1.0)


func _lin(colors: Array) -> Array:
	var out: Array = []
	for c: Color in colors:
		out.append(c.srgb_to_linear())
	return out


func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for p: Vector2 in points:
		c.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


func _ramp_at(offsets: Array, colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	return t
