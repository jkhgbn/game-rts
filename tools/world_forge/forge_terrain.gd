extends RefCounted
## World Forge terrain (prologue P1): a height field built from spec ops (`hill` / `ridge` / `valley` / `pad`),
## smoothed, baked to one vertex-coloured mesh + a trimesh collision shape; plus the distant mountains ring (`sky`)
## and flat water planes (`water`). Deterministic (same ops + seed = same heights). Grammar: README "Terrain".
## `on` is false until a terrain op is seen: then height_at() is 0 everywhere and flat sets are unchanged.
## No class_name on purpose (preloaded tool script).

const FMesh := preload("res://tools/world_forge/forge_mesh.gd")
const MAX_CELLS := 300

var on := false
var step := 2.0
var smooth := 2
var noise := 0.25
var extend := 0.0
var rock := Color(0.42, 0.40, 0.38)
var snow := INF
var tseed := 1
var ops: Array = []    ## [{kind: hill|ridge|valley, ...}]
var pads: Array = []   ## [{at: Vector3, r, edge, y (NAN = terrain there)}]
## baked grid
var x0 := 0.0
var z0 := 0.0
var nx := 0
var nz := 0
var h := PackedFloat32Array()
var baked := false


# ---------------------------------------------------------------- field

func bake(size: Vector2) -> void:
	baked = true
	if not on:
		return
	var w := size.x + 2.0 * extend
	var d := size.y + 2.0 * extend
	while w / step > MAX_CELLS or d / step > MAX_CELLS:
		step *= 1.25
	nx = int(ceil(w / step)) + 1
	nz = int(ceil(d / step)) + 1
	x0 = -(nx - 1) * step * 0.5
	z0 = -(nz - 1) * step * 0.5
	h.resize(nx * nz)
	for j in nz:
		for i in nx:
			var x := x0 + i * step
			var z := z0 + j * step
			var v := 0.0
			for op: Dictionary in ops:
				v += _op(op, x, z)
			if noise > 0.0:
				v += noise * ((FMesh.value_noise(x, z, 9.0, tseed + 31) - 0.5) * 1.4 + (FMesh.value_noise(x, z, 3.5, tseed + 32) - 0.5) * 0.6)
			h[j * nx + i] = v
	for _p in smooth:
		var out := PackedFloat32Array()
		out.resize(h.size())
		for j in nz:
			for i in nx:
				var s := 0.0
				var n := 0.0
				for dj in [-1, 0, 1]:
					for di in [-1, 0, 1]:
						var ii := clampi(i + di, 0, nx - 1)
						var jj := clampi(j + dj, 0, nz - 1)
						var wgt := 2.0 if (di == 0 and dj == 0) else 1.0
						s += h[jj * nx + ii] * wgt
						n += wgt
				out[j * nx + i] = s / n
		h = out
	for p: Dictionary in pads:
		var c: Vector3 = p["at"]
		var y: float = p["y"] if not is_nan(float(p["y"])) else height_at(c.x, c.z)
		p["y_final"] = y
		var r: float = p["r"]
		var e: float = maxf(0.01, p["edge"])
		for j in nz:
			for i in nx:
				var x := x0 + i * step
				var z := z0 + j * step
				var dd := Vector2(x - c.x, z - c.z).length()
				if dd >= r + e:
					continue
				var t := 1.0 if dd <= r else 1.0 - smoothstep(r, r + e, dd)
				h[j * nx + i] = lerpf(h[j * nx + i], y, t)


static func _cos_fall(t: float) -> float:
	return 0.5 * (1.0 + cos(PI * clampf(t, 0.0, 1.0)))


func _op(op: Dictionary, x: float, z: float) -> float:
	match String(op["kind"]):
		"hill":
			var c: Vector3 = op["at"]
			var r: float = op["r"]
			var dd := Vector2(x - c.x, z - c.z).length()
			if dd >= r:
				return 0.0
			var fl: float = op["flat"] * r
			return float(op["h"]) * _cos_fall((dd - fl) / maxf(0.01, r - fl))
		"ridge":
			var hw: float = float(op["width"]) * 0.5
			var dd := _dist_poly(x, z, op["poly"])
			if dd >= hw:
				return 0.0
			var jag: float = op["jag"]
			var hh: float = float(op["h"]) * (1.0 + jag * ((FMesh.value_noise(x, z, hw * 1.6, tseed + 41) - 0.5) * 1.3 + (FMesh.value_noise(x, z, hw * 0.5, tseed + 42) - 0.5) * 0.7))
			var t := dd / hw
			return hh * _cos_fall(t) * (1.0 - 0.15 * t)
		"valley":
			var hw: float = float(op["width"]) * 0.5
			var dd := _dist_poly(x, z, op["poly"])
			if dd >= hw:
				return 0.0
			var fl: float = op["flat"] * hw
			return -float(op["depth"]) * _cos_fall((dd - fl) / maxf(0.01, hw - fl))
	return 0.0


static func _dist_poly(x: float, z: float, poly: PackedVector3Array) -> float:
	var p := Vector2(x, z)
	var best := INF
	for i in range(poly.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(p, Vector2(poly[i].x, poly[i].z), Vector2(poly[i + 1].x, poly[i + 1].z))
		best = minf(best, q.distance_to(p))
	if poly.size() == 1:
		best = p.distance_to(Vector2(poly[0].x, poly[0].z))
	return best


## Terrain height at (x, z) (bilinear on the baked grid; 0 when there is no terrain).
func height_at(x: float, z: float) -> float:
	if not on or h.is_empty():
		return 0.0
	var fx := clampf((x - x0) / step, 0.0, nx - 1.001)
	var fz := clampf((z - z0) / step, 0.0, nz - 1.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a := h[j * nx + i]
	var b := h[j * nx + i + 1]
	var c := h[(j + 1) * nx + i]
	var e := h[(j + 1) * nx + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, e, tx), tz)


func normal_at(x: float, z: float) -> Vector3:
	if not on:
		return Vector3.UP
	var e := step * 0.5
	var dx := height_at(x + e, z) - height_at(x - e, z)
	var dz := height_at(x, z + e) - height_at(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


func slope_deg(x: float, z: float) -> float:
	return rad_to_deg(acos(clampf(normal_at(x, z).y, -1.0, 1.0)))


func ground_callable() -> Callable:
	return Callable(self, "height_at") if on else Callable()


func min_max() -> Vector2:
	if h.is_empty():
		return Vector2.ZERO
	var lo := INF
	var hi := -INF
	for v in h:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return Vector2(lo, hi)


func layout_line() -> String:
	var mm := min_max()
	var s := 0.0
	for k in range(0, h.size(), 7):
		s += h[k] * float(k % 13 + 1)
	return "terrain %dx%d step %.3f min %.3f max %.3f sum %.3f" % [nx, nz, step, mm.x, mm.y, s]


# ---------------------------------------------------------------- meshes

func mesh(base: Color) -> ArrayMesh:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var idx := PackedInt32Array()
	v.resize(nx * nz)
	n.resize(nx * nz)
	c.resize(nx * nz)
	var snow_col := Color(0.86, 0.89, 0.94)
	for j in nz:
		for i in nx:
			var x := x0 + i * step
			var z := z0 + j * step
			var y := h[j * nx + i]
			var k := j * nx + i
			v[k] = Vector3(x, y, z)
			var nn := normal_at(x, z)
			n[k] = nn
			var nval := FMesh.value_noise(x, z, 7.0, tseed) * 0.6 + FMesh.value_noise(x, z, 2.5, tseed + 1) * 0.4
			var col := base.darkened(0.18).lerp(base.lightened(0.12), nval)
			var slope := 1.0 - nn.y
			col = col.lerp(rock.lerp(rock.darkened(0.2), nval), smoothstep(0.22, 0.45, slope))
			if y < 0.0:
				col = col.darkened(minf(0.3, -y * 0.08))
			if not is_inf(snow):
				col = col.lerp(snow_col, smoothstep(snow, snow + 3.0, y) * (1.0 - smoothstep(0.35, 0.6, slope)))
			c[k] = col
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			var b := a + 1
			var d := a + nx
			var e := d + 1
			idx.append_array([a, b, e, a, e, d])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := FMesh.vc_material(false, 0.97)
	mat.vertex_color_is_srgb = true
	m.surface_set_material(0, mat)
	return m


## Distant mountains: `layers` jagged silhouette rings around (0,0), unshaded, fog off (the haze is baked in).
static func mountains(sky: Dictionary) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var layers: int = sky["mountains"]
	var seg := 180
	var base_col: Color = sky["color"]
	var haze: Color = sky["haze"]
	var sd: int = sky["seed"]
	for L in layers:
		# layer 0 = the far, tall, hazy range; the next ones come closer, lower and darker
		var f := float(L) / maxf(1.0, float(layers - 1)) if layers > 1 else 0.0
		var rad: float = float(sky["dist"]) * (1.0 - 0.14 * f)
		var tall: float = float(sky["height"]) * (1.0 - 0.35 * f)
		var col := base_col.lerp(haze, 0.42 - 0.3 * f)
		var foot := haze.lerp(base_col, 0.15 + 0.2 * f)
		var tops: Array[float] = []
		for s in seg + 1:
			var a := TAU * float(s % seg) / seg
			var px := cos(a) * 60.0
			var pz := sin(a) * 60.0
			var nv := FMesh.value_noise(px, pz, 22.0, sd + L * 7) * 0.55 + FMesh.value_noise(px, pz, 8.0, sd + L * 7 + 1) * 0.3 \
				+ FMesh.value_noise(px, pz, 2.6, sd + L * 7 + 2) * 0.15
			tops.append(tall * (0.25 + 0.95 * pow(nv, 1.6)))
		for s in seg:
			var a0 := TAU * float(s) / seg
			var a1 := TAU * float(s + 1) / seg
			var p0 := Vector3(cos(a0) * rad, 0, sin(a0) * rad)
			var p1 := Vector3(cos(a1) * rad, 0, sin(a1) * rad)
			var y0: float = tops[s]
			var y1: float = tops[s + 1]
			var q := [p0 + Vector3(0, -25, 0), p1 + Vector3(0, -25, 0), p1 + Vector3(0, y1, 0), p0 + Vector3(0, y0, 0)]
			var cols := [foot, foot, _peak(col, y1, tall), _peak(col, y0, tall)]
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(cols[i])
				st.set_normal(-(q[i] as Vector3).normalized())
				st.add_vertex(q[i])
	var m := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true
	m.surface_set_material(0, mat)
	return m


static func _peak(col: Color, y: float, tall: float) -> Color:
	return col.lerp(Color(0.85, 0.87, 0.92).lerp(col, 0.35), smoothstep(0.72, 0.95, y / maxf(1.0, tall)))


## A flat water plane over `area` (null = the whole rect `full` = Rect2 on x/z) at `level`.
static func water(wd: Dictionary, full: Rect2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y: float = wd["level"]
	var area: Variant = wd["area"]
	var pts: Array[Vector3] = []
	if area == null or String(area["kind"]) == "rect":
		var mn := Vector2(full.position.x, full.position.y) if area == null else Vector2(area["min"].x, area["min"].z)
		var mx := full.end if area == null else Vector2(area["max"].x, area["max"].z)
		pts = [Vector3(mn.x, y, mn.y), Vector3(mx.x, y, mn.y), Vector3(mx.x, y, mx.y), Vector3(mn.x, y, mx.y)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(pts[i])
	else:
		var c: Vector3 = area["center"]
		var r: float = area["r1"]
		for s in 48:
			var a0 := TAU * s / 48.0
			var a1 := TAU * (s + 1) / 48.0
			for p: Vector3 in [Vector3(c.x, y, c.z), Vector3(c.x + cos(a1) * r, y, c.z + sin(a1) * r), Vector3(c.x + cos(a0) * r, y, c.z + sin(a0) * r)]:
				st.set_normal(Vector3.UP)
				st.add_vertex(p)
	var m := st.commit()
	var mat := StandardMaterial3D.new()
	var col: Color = wd["color"]
	col.a = wd["alpha"]
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.35
	mat.metallic = 0.0
	mat.metallic_specular = 0.25
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.surface_set_material(0, mat)
	return m


## Hill shading for plan.png: colour of the terrain at (x, z) from the base ground colour.
func shade(base: Color, x: float, z: float) -> Color:
	var nn := normal_at(x, z)
	var light := clampf(nn.dot(Vector3(-0.5, 0.75, -0.45).normalized()), 0.0, 1.0)
	var y := height_at(x, z)
	var col := base.darkened(0.35).lerp(base.lightened(0.25), light)
	# contour every 2 m
	if absf(fposmod(y, 2.0)) < 0.18:
		col = col.darkened(0.25)
	return col
