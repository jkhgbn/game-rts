class_name WaterMeshes
extends RefCounted
## Mesh builders for the Hollowmere river look (task 12.V1). They define the UV convention water.gdshader expects,
## so RiverSystem (12.C1) can call them (through `load()`, see the step-12 rules) or copy them:
##   UV.x  metres along the flow (downstream = the order of the path points), UV.y 0 on the left bank -> 1 on the
##   right bank (left = seen looking downstream... any consistent side is fine, the shader is symmetric),
##   COLOR.r  bank-foam weight (1 = foam at this bank vertex, 0 = none: river mouths opening into the moat),
##   COLOR.g  piece width / REF_WIDTH (1.0 on the 5 m river, 0.7 on the 3.5 m moat).
## Paths are world (x, z) polylines of the channel centre line, the same data as the ground cut (map-fill.md 2.1):
## straight segments, joints mitred (the bends are small, so the mitre stays within 1 cm of the ground's round cut).
## All meshes are one indexed surface with the shared materials below; none casts a shadow worth having (turn
## `cast_shadow` off on the instances, they sit at or under ground level).

const WATER_Y := -0.35
const TOP_Y := 0.0
const WALL_BOTTOM_Y := -0.6       # water is opaque: nothing below this is ever seen (the bed is optional)
const BED_Y := -1.0
const FILM_Y := 0.02
const WATER_MAT := "res://art/environment/water/water_mat.tres"
const FORD_MAT := "res://art/environment/water/water_ford_mat.tres"
const BED_MAT := "res://art/environment/water/riverbed_mat.tres"
const REF_WIDTH := 5.0            # water_mat channel_width: COLOR.g = piece width / REF_WIDTH


## Points along a circle (world x/z) from angle a0 to a1 in degrees (atan2(z, x): 0 east, 90 south), about
## `step_m` metres apart. a1 < a0 walks clockwise. A full ring (360 deg) repeats its first point at the end.
static func arc_path(center: Vector2, radius: float, a0_deg: float, a1_deg: float, step_m: float = 0.6) -> PackedVector2Array:
	var out := PackedVector2Array()
	var span: float = deg_to_rad(a1_deg - a0_deg)
	var n: int = maxi(2, int(ceil(absf(span) * radius / step_m)))
	for i in n + 1:
		var a: float = deg_to_rad(a0_deg) + span * float(i) / float(n)
		out.append(center + Vector2(cos(a), sin(a)) * radius)
	return out


## Water surface of a channel: a strip `half_width` either side of `path` at height `y`.
## `s0` = UV.x at the first point (continue the flow between pieces). `bank_foam(p: Vector2) -> float` gives
## COLOR.r per bank vertex (default: 1 everywhere). `flip_across` swaps the banks (UV.y = 1 - v): use it so two
## pieces that start side by side (the two halves of the moat leaving the river mouth) match across their seam.
## `end_dirs` (optional, 2 entries): the across direction at the first and the last point (any sign), e.g. the
## radial direction where a moat half starts, so two pieces meeting at an angle share their seam exactly.
static func channel_surface(path: PackedVector2Array, half_width: float, y: float = WATER_Y, s0: float = 0.0,
		max_step: float = 1.0, bank_foam: Callable = Callable(), flip_across: bool = false,
		end_dirs: PackedVector2Array = PackedVector2Array()) -> ArrayMesh:
	var smp: Array = _samples(path, max_step, end_dirs)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	for d: Dictionary in smp:
		var c: Vector2 = d["c"]
		var m: Vector2 = d["m"]
		var l: Vector2 = c - m * half_width
		var r: Vector2 = c + m * half_width
		rows.append([Vector3(l.x, y, l.y), Vector3(r.x, y, r.y), float(d["s"]) + s0,
				_foam(bank_foam, l), _foam(bank_foam, r)])
	for j in rows.size() - 1:
		var a: Array = rows[j]
		var b: Array = rows[j + 1]
		var v := [a[0], a[1], b[1], b[0]]
		var v0: float = 1.0 if flip_across else 0.0
		var uv := [Vector2(a[2], v0), Vector2(a[2], 1.0 - v0), Vector2(b[2], 1.0 - v0), Vector2(b[2], v0)]
		var fc := [a[3], a[4], b[4], b[3]]
		_quad(st, v, uv, fc, Vector3.UP, half_width * 2.0 / REF_WIDTH)
	st.index()
	var mesh := st.commit()
	mesh.surface_set_material(0, load(WATER_MAT))
	_ensure_quality()
	return mesh


## The ford film: the part of the channel inside the ford circle, at FILM_Y over the ground, same UV convention
## (UV.x continues the channel's `s0`). Use water_ford_mat.tres (the builder sets it).
static func ford_film(path: PackedVector2Array, half_width: float, ford_center: Vector2, ford_radius: float,
		y: float = FILM_Y, s0: float = 0.0) -> ArrayMesh:
	var smp: Array = _samples(path, 0.25)
	var sc: float = _project_s(smp, ford_center)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := 8
	var rows := 10
	var grid: Array = []
	for i in cols + 1:
		var a: float = lerpf(-half_width, half_width, float(i) / cols)
		var reach: float = sqrt(maxf(ford_radius * ford_radius - a * a, 0.0))
		var col: Array = []
		for k in rows + 1:
			var along: float = lerpf(-reach, reach, float(k) / rows)
			var f: Array = _frame(smp, sc + along)
			var p: Vector2 = (f[0] as Vector2) + (f[1] as Vector2) * a
			if k == 0 or k == rows:   # snap the ends onto the circle (curved channels)
				var dv: Vector2 = p - ford_center
				if dv.length() > 0.001:
					p = ford_center + dv.normalized() * minf(dv.length(), ford_radius)
			col.append([Vector3(p.x, y, p.y), Vector2(s0 + sc + along, (a / half_width + 1.0) * 0.5)])
		grid.append(col)
	for i in cols:
		for k in rows:
			var q := [grid[i][k], grid[i + 1][k], grid[i + 1][k + 1], grid[i][k + 1]]
			_quad(st, [q[0][0], q[1][0], q[2][0], q[3][0]], [q[0][1], q[1][1], q[2][1], q[3][1]],
					[1.0, 1.0, 1.0, 1.0], Vector3.UP, half_width * 2.0 / REF_WIDTH)
	st.index()
	var mesh := st.commit()
	mesh.surface_set_material(0, load(FORD_MAT))
	return mesh


## Trench walls on both banks of a channel, from TOP_Y (exactly on the bank line) down to `bottom_y`, leaning
## and jittered a little inward below the lip (chunky rock). `skip(p: Vector2) -> bool` drops wall pieces whose
## bank point is inside another water piece (river mouths into the moat). `with_bed` adds a flat bed at BED_Y.
static func channel_walls(path: PackedVector2Array, half_width: float, skip: Callable = Callable(),
		bottom_y: float = WALL_BOTTOM_Y, max_step: float = 0.8, seed_value: int = 0, with_bed: bool = false) -> ArrayMesh:
	var smp: Array = _samples(path, max_step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# (inset toward the centre in metres, height): the first row is the bank lip, exactly on the ground cut; the
	# jittered middle rows make the chunky rock; the last one is under the water (never seen).
	var profile: Array = [[0.0, TOP_Y], [0.07, -0.12], [0.13, -0.30], [0.22, bottom_y]]
	for side: float in [-1.0, 1.0]:
		var rings: Array = []
		for j in smp.size():
			var d: Dictionary = smp[j]
			var c: Vector2 = d["c"]
			var m: Vector2 = d["m"]
			var u: Vector2 = d["n"]
			var ring: Array = []
			for k in profile.size():
				var inset: float = profile[k][0]
				if k > 0 and k < profile.size() - 1:
					inset += (_h(float(j) + float(seed_value) * 7.1, float(k) + side * 3.3) - 0.3) * 0.09
				var p: Vector2 = c + m * side * half_width - u * side * inset
				ring.append(Vector3(p.x, profile[k][1], p.y))
			rings.append([ring, c + m * side * half_width])
		for j in rings.size() - 1:
			var mid: Vector2 = ((rings[j][1] as Vector2) + (rings[j + 1][1] as Vector2)) * 0.5
			if skip.is_valid() and bool(skip.call(mid)):
				continue
			var ra: Array = rings[j][0]
			var rb: Array = rings[j + 1][0]
			var nrm: Vector2 = -(smp[j]["n"] as Vector2) * side
			for k in profile.size() - 1:
				_quad_flat(st, [ra[k], rb[k], rb[k + 1], ra[k + 1]], Vector3(nrm.x, 0.0, nrm.y))
	if with_bed:
		for j in smp.size() - 1:
			var a: Dictionary = smp[j]
			var b: Dictionary = smp[j + 1]
			var hw: float = half_width - 0.2
			var pa: Vector2 = (a["c"] as Vector2) - (a["m"] as Vector2) * hw
			var pb: Vector2 = (a["c"] as Vector2) + (a["m"] as Vector2) * hw
			var pc: Vector2 = (b["c"] as Vector2) + (b["m"] as Vector2) * hw
			var pd: Vector2 = (b["c"] as Vector2) - (b["m"] as Vector2) * hw
			_quad_flat(st, [Vector3(pa.x, BED_Y, pa.y), Vector3(pb.x, BED_Y, pb.y), Vector3(pc.x, BED_Y, pc.y),
					Vector3(pd.x, BED_Y, pd.y)], Vector3.UP)
	st.generate_normals()
	st.index()
	var mesh := st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, load(BED_MAT))
	return mesh


## Walls where the ground of a ford circle ends and the deep channel begins (the circle's arcs inside the
## channel), facing out of the circle.
static func ford_end_walls(path: PackedVector2Array, half_width: float, ford_center: Vector2, ford_radius: float,
		bottom_y: float = WALL_BOTTOM_Y) -> ArrayMesh:
	var smp: Array = _samples(path, 0.25)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 96
	for i in n:
		var a0: float = TAU * float(i) / n
		var a1: float = TAU * float(i + 1) / n
		var p0: Vector2 = ford_center + Vector2(cos(a0), sin(a0)) * ford_radius
		var p1: Vector2 = ford_center + Vector2(cos(a1), sin(a1)) * ford_radius
		if _dist_to_samples(smp, p0) > half_width + 0.05 and _dist_to_samples(smp, p1) > half_width + 0.05:
			continue
		var out: Vector2 = ((p0 + p1) * 0.5 - ford_center).normalized()
		var ins: Vector2 = -out * 0.12
		_quad_flat(st, [Vector3(p0.x, TOP_Y, p0.y), Vector3(p1.x, TOP_Y, p1.y),
				Vector3(p1.x + ins.x, bottom_y, p1.y + ins.y), Vector3(p0.x + ins.x, bottom_y, p0.y + ins.y)],
				Vector3(out.x, 0.0, out.y))
	st.generate_normals()
	st.index()
	var mesh := st.commit()
	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, load(BED_MAT))
	return mesh


## Distance from `p` to the polyline `path` (the analytic river distance of the ground cut).
static func distance_to_path(path: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in path.size() - 1:
		best = minf(best, _seg_dist(p, path[i], path[i + 1]))
	return best


# ------------------------------------------------------------------------------------------------ internals

## G2b: the shared water materials follow the graphics tier (water_quality.gd, load-guarded).
static func _ensure_quality() -> void:
	const WQ := "res://art/environment/water/water_quality.gd"
	if ResourceLoader.exists(WQ):
		(load(WQ) as Script).call(&"ensure")


static func _foam(cb: Callable, p: Vector2) -> float:
	return clampf(float(cb.call(p)), 0.0, 1.0) if cb.is_valid() else 1.0


static func _h(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Samples along a polyline, at most `max_step` apart, every original point kept. Each sample:
## {c: centre, n: unit left normal, m: mitre vector (n scaled so offsets stay parallel), s: arc length}.
static func _samples(path: PackedVector2Array, max_step: float, end_dirs: PackedVector2Array = PackedVector2Array()) -> Array:
	var out: Array = []
	var count: int = path.size()
	if count < 2:
		return out
	var closed: bool = path[0].distance_to(path[count - 1]) < 0.01
	var seg_n: Array[Vector2] = []
	for i in count - 1:
		var d: Vector2 = (path[i + 1] - path[i]).normalized()
		seg_n.append(Vector2(-d.y, d.x))
	var s := 0.0
	for i in count - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var L: float = a.distance_to(b)
		var n: int = maxi(1, int(ceil(L / max_step)))
		for k in n:
			var t: float = float(k) / n
			var nn: Vector2 = seg_n[i]
			var mm: Vector2 = nn
			if k == 0 and (i > 0 or closed):
				var prev: Vector2 = seg_n[i - 1] if i > 0 else seg_n[count - 2]
				var avg: Vector2 = (prev + nn).normalized()
				mm = avg / maxf(avg.dot(nn), 0.5)
				nn = avg
			out.append({"c": a.lerp(b, t), "n": nn, "m": mm, "s": s + L * t})
		s += L
	var last_n: Vector2 = seg_n[count - 2]
	var last_m: Vector2 = last_n
	if closed:
		last_n = out[0]["n"]
		last_m = out[0]["m"]
	out.append({"c": path[count - 1], "n": last_n, "m": last_m, "s": s})
	if end_dirs.size() == 2 and not closed:
		for e in 2:
			var d: Dictionary = out[0] if e == 0 else out[out.size() - 1]
			var nn: Vector2 = d["n"]
			var ov: Vector2 = end_dirs[e].normalized()
			if ov.length_squared() < 0.5:
				continue
			ov *= signf(ov.dot(nn)) if absf(ov.dot(nn)) > 1e-6 else 1.0
			d["n"] = ov
			d["m"] = ov   # exactly half_width out along it: both pieces land on the same points
	return out


## Arc length of the sample nearest to `p` (projected on the polyline).
static func _project_s(smp: Array, p: Vector2) -> float:
	var best := INF
	var best_s := 0.0
	for i in smp.size() - 1:
		var a: Vector2 = smp[i]["c"]
		var b: Vector2 = smp[i + 1]["c"]
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		var d: float = p.distance_to(a + ab * t)
		if d < best:
			best = d
			best_s = lerpf(float(smp[i]["s"]), float(smp[i + 1]["s"]), t)
	return best_s


## [centre, unit left normal] at arc length `s` (clamped to the path).
static func _frame(smp: Array, s: float) -> Array:
	for i in smp.size() - 1:
		var s1: float = smp[i + 1]["s"]
		if s <= s1 or i == smp.size() - 2:
			var s0: float = smp[i]["s"]
			var t: float = clampf((s - s0) / maxf(s1 - s0, 1e-6), 0.0, 1.0)
			var c: Vector2 = (smp[i]["c"] as Vector2).lerp(smp[i + 1]["c"], t)
			var n: Vector2 = (smp[i]["n"] as Vector2).lerp(smp[i + 1]["n"], t).normalized()
			return [c, n]
	return [smp[0]["c"], smp[0]["n"]]


static func _dist_to_samples(smp: Array, p: Vector2) -> float:
	var best := INF
	for i in smp.size() - 1:
		best = minf(best, _seg_dist(p, smp[i]["c"], smp[i + 1]["c"]))
	return best


## A quad with UVs, COLOR.r (bank foam) and COLOR.g (width scale), split into two triangles wound to face `want`
## (Godot: clockwise = front).
static func _quad(st: SurfaceTool, v: Array, uv: Array, fc: Array, want: Vector3, width_scale: float) -> void:
	for tri: Array in [[0, 1, 2], [0, 2, 3]]:
		var ids: Array = tri
		var a: Vector3 = v[ids[0]]
		var b: Vector3 = v[ids[1]]
		var c: Vector3 = v[ids[2]]
		if (b - a).cross(c - a).dot(want) > 0.0:
			ids = [ids[0], ids[2], ids[1]]
		for k: int in ids:
			st.set_normal(want)
			st.set_uv(uv[k])
			st.set_color(Color(fc[k], width_scale, 1.0, 1.0))
			st.add_vertex(v[k])


## A quad without UVs (walls, bed): normals come from generate_normals() (faceted chunky rock).
static func _quad_flat(st: SurfaceTool, v: Array, want: Vector3) -> void:
	for tri: Array in [[0, 1, 2], [0, 2, 3]]:
		var ids: Array = tri
		var a: Vector3 = v[ids[0]]
		var b: Vector3 = v[ids[1]]
		var c: Vector3 = v[ids[2]]
		if (b - a).cross(c - a).dot(want) > 0.0:
			ids = [ids[0], ids[2], ids[1]]
		for k: int in ids:
			st.add_vertex(v[k])
