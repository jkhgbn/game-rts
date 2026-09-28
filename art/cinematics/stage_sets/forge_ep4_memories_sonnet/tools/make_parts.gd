extends SceneTree
## forge_ep4_memories_sonnet parts (tech-art tool, not game code): the Episode 4 flashback dressing (docs/design/
## episode3-4-opening.md 4.2) built from faceted blobs / prisms into vertex-coloured meshes on the SHARED forge_citadel
## materials (matte, glow, halo, mist, shaft), saved as mesh-only scenes parts/<name>.tscn so World Forge rows bake them
## (one draw per material). Every part: origin at its local centre / base, faces +Z at yaw 0. Deterministic (hash noise).
## Corner parts are built around (0,0) and placed at the corner's x offset by the .set.
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_ep4_memories_sonnet/tools/make_parts.gd --quit-after 900

const CIT := "res://art/cinematics/stage_sets/forge_citadel/parts/materials"
const DIR := "res://art/cinematics/stage_sets/forge_ep4_memories_sonnet/parts"

const I := Transform3D.IDENTITY
var mats := {}
var sts := {}  ## material key -> SurfaceTool (current part)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for k: String in ["matte", "metal", "glow", "halo", "mist", "shaft", "haze", "banner", "falls", "pool", "shade"]:
		mats[k] = load("%s/citadel_%s.tres" % [CIT, k])
	_part("winter", func() -> void:
		_corner_winter()
		_snowfall())
	_part("spring", func() -> void:
		_corner_spring()
		_pollen()
		_butterflies()
		_sun_shafts())
	_part("frost_meadow", func() -> void:
		_corner_hem()
		_snowfall()
		_frost_glitter())
	_part("burned_wood", func() -> void:
		_corner_ash()
		_frost_glitter()
		_ash_drifts())
	_part("master_robe", _master_robe)
	_part("hem_flames", _hem_flames)
	_part("frost_ring", _frost_ring)
	_part("green_shoot", _green_shoot)
	_part("snow_fir", func() -> void: _snow_fir(1))
	_part("snow_fir_b", func() -> void: _snow_fir(2))
	_part("frost_fir", func() -> void: _snow_fir(3))
	_part("blossom_tree", _blossom_tree)
	_part("meadow_tufts", _meadow_tufts)
	_part("flower_patch", _flower_patch)
	_part("stump_a", func() -> void: _stump(0.75, 0.55, 1))
	_part("stump_b", func() -> void: _stump(0.55, 0.9, 2))
	_part("stump_c", func() -> void: _stump(1.0, 0.35, 3))
	_part("dead_trunk_a", func() -> void: _dead_trunk(5.5, 0.28, 1))
	_part("dead_trunk_b", func() -> void: _dead_trunk(8.0, 0.36, 2))
	_part("dead_trunk_c", func() -> void: _dead_trunk(3.4, 0.22, 3))
	_part("far_village_glow", _far_glow)
	_make_light_part()
	quit()


func _st(key: String) -> SurfaceTool:
	if not sts.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts[key] = st
	return sts[key]


func _part(name: String, build: Callable) -> void:
	sts.clear()
	build.call()
	var mesh := ArrayMesh.new()
	var tris := 0
	for key: String in ["matte", "metal", "glow", "banner", "pool", "falls", "shaft", "shade", "haze", "mist", "halo"]:
		if not sts.has(key):
			continue
		var arr := (sts[key] as SurfaceTool).commit_to_arrays()
		tris += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mats[key])
	var mp := "%s/%s.res" % [DIR, name]
	ResourceSaver.save(mesh, mp, ResourceSaver.FLAG_COMPRESS)
	mesh.take_over_path(mp)
	var n := Node3D.new()
	n.name = name
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	n.add_child(mi)
	mi.owner = n
	var ps := PackedScene.new()
	ps.pack(n)
	ResourceSaver.save(ps, "%s/%s.tscn" % [DIR, name])
	n.free()
	var ab := mesh.get_aabb()
	print("PART %s surfaces=%d tris=%d aabb=%s" % [name, mesh.get_surface_count(), tris, ab])


static func h01(a: float, b: float, s: int) -> float:
	var h := int(floor(a * 131.0)) * 73856093 ^ int(floor(b * 137.0)) * 19349663 ^ s * 83492791
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, uva := Vector2.ZERO, uvb := Vector2.ZERO, uvc := Vector2.ZERO) -> void:
	var n := (b - a).cross(c - a).normalized()
	# Godot front faces are clockwise seen from the front: emit a, c, b for a counter-clockwise (right-hand) input
	for pv: Array in [[a, uva], [c, uvc], [b, uvb]]:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(pv[1])
		st.add_vertex(pv[0])


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	_tri(st, a, b, c, col)
	_tri(st, a, c, d, col)


## Box: centre c, half extents h, in xf.
func box(key: String, xf: Transform3D, c: Vector3, h: Vector3, col: Color) -> void:
	var st := _st(key)
	var p := func(x: float, y: float, z: float) -> Vector3: return xf * (c + Vector3(x * h.x, y * h.y, z * h.z))
	var sh := func(k: float) -> Color: return Color(col.r * k, col.g * k, col.b * k, col.a)
	_quad(st, p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), sh.call(0.92))     # +z
	_quad(st, p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1), sh.call(0.8))  # -z
	_quad(st, p.call(1, -1, 1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(1, 1, 1), sh.call(0.86))     # +x
	_quad(st, p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), sh.call(0.84)) # -x
	_quad(st, p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, 1, -1), p.call(-1, 1, -1), sh.call(1.0))      # top
	_quad(st, p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, -1, 1), p.call(-1, -1, 1), sh.call(0.6))  # bottom


## Tapered prism (cylinder / cone) around the local Y axis from y0 to y0+h.
func prism(key: String, xf: Transform3D, c: Vector3, r0: float, r1: float, h: float, sides: int, col: Color, caps := true, jitter := 0.0, seed := 0) -> void:
	var st := _st(key)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		var k := 0.86 + 0.14 * cos((a0 + a1) * 0.5 - 0.6)
		var tone := Color(col.r * k, col.g * k, col.b * k)
		if jitter > 0.0:
			tone = tone.lerp(tone.darkened(0.2), h01(float(i), c.y, seed))
		var b0 := xf * (c + d0 * r0)
		var b1 := xf * (c + d1 * r0)
		var t0 := xf * (c + d0 * r1 + Vector3(0, h, 0))
		var t1 := xf * (c + d1 * r1 + Vector3(0, h, 0))
		_quad(st, b0, b1, t1, t0, tone)
		if caps and r1 > 0.001:
			_tri(st, xf * (c + Vector3(0, h, 0)), t0, t1, col)
		if caps and r0 > 0.001 and c.y > 0.05:
			_tri(st, xf * c, b1, b0, col.darkened(0.3))


func merlons(key: String, xf: Transform3D, y: float, r: float, n: int, size: float, col: Color) -> void:
	for i in n:
		var a := TAU * (i + 0.5) / n
		var b := Basis(Vector3.UP, a)
		box(key, xf * Transform3D(b, Vector3.ZERO), Vector3(0, y + size * 0.5, r), Vector3(size * 0.5, size * 0.5, size * 0.35), col)


## Camera-facing card collapsed on its centre (expanded by citadel_halo / citadel_mist): radius s (m), UV2.y = mode
## (halo: 0 soft, 1 star glint; mist: drift speed). All vertices of a halo / mist surface carry UV2.
func halo(xf: Transform3D, c: Vector3, s: float, col: Color, mode := 0.0, key := "halo") -> void:
	var st := _st(key)
	var p := xf * c
	var corners := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i: int in [0, 2, 1, 0, 3, 2]:
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.set_uv(corners[i])
		st.set_uv2(Vector2(s, mode))
		st.add_vertex(p)


func mist(xf: Transform3D, c: Vector3, s: float, col: Color, drift := 0.3) -> void:
	halo(xf, c, s, col, drift, "mist")


## A flat glow card (real geometry, halo mode 2): a pool of light of radius r on a floor at c (y up).
func glow_pool(xf: Transform3D, c: Vector3, r: float, col: Color) -> void:
	var st := _st("halo")
	var corners := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i: int in [0, 2, 1, 0, 3, 2]:
		var uv: Vector2 = corners[i]
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.set_uv(uv)
		st.set_uv2(Vector2(r, 2.0))
		st.add_vertex(xf * (c + Vector3((uv.x * 2.0 - 1.0) * r, 0, (uv.y * 2.0 - 1.0) * r)))


## A horizontal annulus of haze at height y (r0..r1), UV.x = rim fade, colour alpha = density.
func haze_ring(y: float, r0: float, r1: float, col: Color, stretch := 0.0, segs := 48) -> void:
	var st := _st("haze")
	var rings := 4
	for j in rings:
		var ra := lerpf(r0, r1, float(j) / rings)
		var rb := lerpf(r0, r1, float(j + 1) / rings)
		var fa := _rim(float(j) / rings, r0 < 1.0)
		var fb := _rim(float(j + 1) / rings, r0 < 1.0)
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var p00 := Vector3(sin(a0) * ra, y, cos(a0) * ra)
			var p10 := Vector3(sin(a1) * ra, y, cos(a1) * ra)
			var p01 := Vector3(sin(a0) * rb, y, cos(a0) * rb)
			var p11 := Vector3(sin(a1) * rb, y, cos(a1) * rb)
			_tri(st, p00, p11, p10, col, Vector2(fa, stretch), Vector2(fb, stretch), Vector2(fa, stretch))
			_tri(st, p00, p01, p11, col, Vector2(fa, stretch), Vector2(fb, stretch), Vector2(fb, stretch))


static func _rim(t: float, solid_inside: bool) -> float:
	if solid_inside:
		return clampf((1.0 - t) * 3.0, 0.0, 1.0)
	return clampf(minf(t * 3.0, (1.0 - t) * 3.0), 0.0, 1.0)


# ------------------------------------------------------------------ parts

static func vn(x: float, z: float, s: int) -> float:
	var xi := floorf(x)
	var zi := floorf(z)
	var fx := x - xi
	var fz := z - zi
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	var a := h01(xi, zi, s)
	var b := h01(xi + 1.0, zi, s)
	var c := h01(xi, zi + 1.0, s)
	var d := h01(xi + 1.0, zi + 1.0, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fz)


## Half-ellipsoid dome (faceted). rad = (rx, ry, rz). Colour per face from the normal: top tone up, side tone down.
func blob(key: String, c: Vector3, rad: Vector3, top: Color, side: Color, seed := 0, rings := 3, segs := 7, jit := 0.15) -> void:
	var st := _st(key)
	var pts: Array = []
	for j in rings + 1:
		var phi := (PI * 0.5) * float(j) / rings
		var row: Array = []
		for i in segs:
			var a := TAU * i / segs
			var k := 1.0 + (h01(float(i), float(j), seed) - 0.5) * 2.0 * jit
			if j == rings:
				k = 1.0
			row.append(c + Vector3(sin(a) * rad.x * cos(phi) * k, sin(phi) * rad.y * k, cos(a) * rad.z * cos(phi) * k))
		pts.append(row)
	for j in rings:
		for i in segs:
			var i2 := (i + 1) % segs
			var p00: Vector3 = pts[j][i]
			var p10: Vector3 = pts[j][i2]
			var p11: Vector3 = pts[j + 1][i2]
			var p01: Vector3 = pts[j + 1][i]
			var n := ((p10 - p00).cross(p11 - p00)).normalized()
			var col := side.lerp(top, clampf(n.y * 1.3, 0.0, 1.0))
			var v := 0.9 + 0.2 * h01(float(i), float(j), seed + 7)
			col = Color(col.r * v, col.g * v, col.b * v, col.a)
			_tri(st, p00, p10, p11, col)
			_tri(st, p00, p11, p01, col)


## Irregular ground disc (up-facing) with value-noise colour between a and b, fading to `edge` at the rim.
func patch(key: String, c: Vector3, r: float, a: Color, b: Color, edge: Color, seed := 0, bump := 0.03, rings := 7, segs := 30, stretch := Vector2(1, 1)) -> void:
	var st := _st(key)
	var pts: Array = []
	for j in rings + 1:
		var row: Array = []
		for i in segs:
			var an := TAU * i / segs
			var rr := r * (0.86 + 0.28 * vn(cos(an) * 1.6 + 5.0, sin(an) * 1.6 + 5.0, seed))
			var t := float(j) / rings
			var p := Vector3(sin(an) * rr * t * stretch.x, 0, cos(an) * rr * t * stretch.y)
			var nz := vn(p.x * 0.9 + 20.0, p.z * 0.9 + 20.0, seed + 3)
			var col := a.lerp(b, nz)
			var w := clampf((t - 0.72) / 0.28, 0.0, 1.0)
			col = col.lerp(edge, w * w)
			p.y = bump * (0.6 + nz) * (1.0 - t * 0.6)
			row.append([c + p, col])
		pts.append(row)
	for j in rings:
		for i in segs:
			var i2 := (i + 1) % segs
			var p00: Array = pts[j][i]
			var p10: Array = pts[j][i2]
			var p01: Array = pts[j + 1][i]
			var p11: Array = pts[j + 1][i2]
			var col: Color = (p00[1] as Color).lerp(p11[1] as Color, 0.5)
			_tri(st, p00[0], p11[0], p10[0], col)
			_tri(st, p00[0], p01[0], p11[0], col)


## Leaning cone spike (flame / crystal / blade): base centre c, tip offset, base radius w, `sides` around.
func spike(key: String, c: Vector3, tip: Vector3, w: float, col: Color, sides := 3, twist := 0.0, tipcol := Color(-1, 0, 0, 0)) -> void:
	var st := _st(key)
	var tc := col if tipcol.r < 0.0 else tipcol
	for i in sides:
		var a0 := twist + TAU * i / sides
		var a1 := twist + TAU * (i + 1) / sides
		var b0 := c + Vector3(sin(a0) * w, 0, cos(a0) * w)
		var b1 := c + Vector3(sin(a1) * w, 0, cos(a1) * w)
		var t := c + tip
		var k := 0.85 + 0.15 * cos((a0 + a1) * 0.5)
		_tri(st, b0, b1, t, Color(col.r * k, col.g * k, col.b * k, col.a))


func dquad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	_quad(_st(key), a, b, c, d, col)
	_quad(_st(key), d, c, b, a, col)


func _hut(x: float, z: float, yaw: float, glow_on: bool, snow: bool) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), Vector3(x, 0, z))
	box("matte", xf, Vector3(0, 0.9, 0), Vector3(1.7, 0.9, 1.3), Color(0.30, 0.22, 0.17))
	var roof := Color(0.86, 0.9, 0.97) if snow else Color(0.42, 0.30, 0.16)
	prism("matte", xf * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO), Vector3(0, 1.75, 0), 2.6, 0.12, 1.3, 4, roof)
	box("matte", xf, Vector3(1.0, 2.1, -0.3), Vector3(0.2, 0.45, 0.2), Color(0.25, 0.2, 0.18))
	if glow_on:
		box("glow", xf, Vector3(0.0, 1.0, 1.31), Vector3(0.42, 0.34, 0.02), Color(2.6, 1.5, 0.55))
		box("glow", xf, Vector3(-1.0, 1.05, 1.31), Vector3(0.25, 0.3, 0.02), Color(2.4, 1.35, 0.5))
		halo(xf, Vector3(0, 1.0, 1.6), 1.8, Color(1.0, 0.6, 0.25, 0.5))
		glow_pool(xf, Vector3(0.3, 0.06, 3.0), 2.6, Color(1.0, 0.62, 0.28, 0.55))
	else:
		box("matte", xf, Vector3(0.0, 1.0, 1.31), Vector3(0.42, 0.34, 0.02), Color(0.12, 0.1, 0.09))


func _fence(x0: float, x1: float, z: float, snow: bool) -> void:
	var n := int((x1 - x0) / 1.4)
	for i in n + 1:
		var x := x0 + (x1 - x0) * float(i) / n
		var h := 0.85 + 0.15 * h01(float(i), 1.0, 5)
		var lean := (h01(float(i), 2.0, 5) - 0.5) * 0.08
		box("matte", Transform3D(Basis(Vector3.BACK, lean), Vector3(x, 0, z)), Vector3(0, h * 0.5, 0), Vector3(0.07, h * 0.5, 0.07), Color(0.32, 0.24, 0.18))
		if snow:
			box("matte", I, Vector3(x, h + 0.03, z), Vector3(0.1, 0.04, 0.1), Color(0.9, 0.93, 0.98))
		if i < n:
			var xm := x + (x1 - x0) / n * 0.5
			box("matte", I, Vector3(xm, 0.65, z), Vector3((x1 - x0) / n * 0.5, 0.04, 0.03), Color(0.3, 0.22, 0.16))
			box("matte", I, Vector3(xm, 0.38, z), Vector3((x1 - x0) / n * 0.5, 0.04, 0.03), Color(0.28, 0.21, 0.15))
			if snow:
				box("matte", I, Vector3(xm, 0.7, z), Vector3((x1 - x0) / n * 0.48, 0.03, 0.045), Color(0.9, 0.93, 0.98))


func _villager(x: float, z: float, s: float, col: Color) -> void:
	prism("matte", I, Vector3(x, 0, z), 0.3 * s, 0.17 * s, 1.15 * s, 7, col)
	blob("matte", Vector3(x, 1.15 * s, z), Vector3(0.17, 0.2, 0.17) * s, col, col, int(x * 10), 2, 6, 0.0)


func _trowel_and_hollow(snow: bool) -> void:
	var soil := Color(0.16, 0.12, 0.1)
	patch("matte", Vector3(0, 0.02, 0), 0.75, soil, soil.lightened(0.15), Color(0.24, 0.2, 0.17) if snow else Color(0.2, 0.16, 0.12), 41, 0.02, 4, 16)
	# heaped soil crescent behind the hollow
	for k in 5:
		var a := PI + (k - 2) * 0.5
		blob("matte", Vector3(sin(a) * 0.85, 0, cos(a) * 0.85 - 0.2), Vector3(0.28, 0.16, 0.24), Color(0.3, 0.24, 0.19), Color(0.2, 0.15, 0.12), k, 2, 6, 0.2)
	# trowel lying by the hole
	var xf := Transform3D(Basis(Vector3.UP, 0.7), Vector3(0.85, 0.05, 0.55))
	box("matte", xf, Vector3(0, 0.03, -0.18), Vector3(0.035, 0.03, 0.14), Color(0.34, 0.22, 0.12))
	box("metal", xf, Vector3(0, 0.02, 0.15), Vector3(0.06, 0.012, 0.16), Color(0.62, 0.64, 0.68))
	if snow:
		box("matte", xf, Vector3(0, 0.05, 0.15), Vector3(0.05, 0.012, 0.13), Color(0.92, 0.95, 1.0))
func _corner_winter() -> void:
	var edge := Color(0.42, 0.5, 0.4)
	patch("matte", Vector3(0, 0.0, -1.0), 10.5, Color(0.9, 0.93, 1.0), Color(0.72, 0.8, 0.93), edge, 11, 0.05, 8, 34, Vector2(1.2, 1.0))
	# wind-blown drifts
	for k in 9:
		var x := (h01(float(k), 1.0, 12) - 0.5) * 14.0
		var z := -2.0 - h01(float(k), 2.0, 12) * 7.0
		blob("matte", Vector3(x, 0, z), Vector3(1.3, 0.28, 0.7) * (0.6 + h01(float(k), 3.0, 12)), Color(0.95, 0.97, 1.0), Color(0.66, 0.74, 0.9), k, 2, 8, 0.1)
	_trowel_and_hollow(true)
	# glowing seed in the hollow
	halo(I, Vector3(0, 0.08, 0), 0.5, Color(0.5, 1.0, 0.5, 0.55))
	# footprint trail from the village to the hollow (leading line)
	for k in 9:
		var t := float(k)
		var x := 2.6 - t * 0.28 + (0.16 if k % 2 == 0 else -0.16)
		var z := 8.5 - t * 0.9
		box("matte", Transform3D(Basis(Vector3.UP, 0.3), Vector3(x, 0, z)), Vector3(0, 0.03, 0), Vector3(0.09, 0.03, 0.2), Color(0.55, 0.62, 0.78))
	_fence(-7.0, 7.0, -3.6, true)
	_hut(-6.5, -9.5, 0.25, true, true)
	_hut(5.0, -11.0, -0.3, true, true)
	_hut(-0.5, -14.0, 0.0, true, true)
	# villagers watching from the fence, backs to the cold
	for k in 4:
		_villager(-3.0 + k * 1.15, -5.3 - h01(float(k), 1.0, 9) * 0.8, 0.95 + 0.1 * h01(float(k), 2.0, 9), Color(0.14, 0.12, 0.18))


func _corner_spring() -> void:
	var edge := Color(0.42, 0.5, 0.32)
	patch("matte", Vector3(0, 0.0, -1.0), 10.5, Color(0.3, 0.58, 0.2), Color(0.46, 0.72, 0.26), edge, 21, 0.05, 8, 34, Vector2(1.2, 1.0))
	for k in 9:
		var x := (h01(float(k), 1.0, 22) - 0.5) * 14.0
		var z := -2.0 - h01(float(k), 2.0, 22) * 7.0
		blob("matte", Vector3(x, 0, z), Vector3(1.2, 0.35, 0.8) * (0.6 + h01(float(k), 3.0, 22)), Color(0.5, 0.78, 0.28), Color(0.25, 0.5, 0.18), k, 2, 8, 0.1)
	_trowel_and_hollow(false)
	_fence(-7.0, 7.0, -3.6, false)
	_hut(-6.5, -9.5, 0.25, false, false)
	_hut(5.0, -11.0, -0.3, false, false)
	_hut(-0.5, -14.0, 0.0, false, false)
	for k in 4:
		_villager(-3.0 + k * 1.15, -5.3 - h01(float(k), 1.0, 9) * 0.8, 0.95 + 0.1 * h01(float(k), 2.0, 9), Color(0.55, 0.32, 0.22).lerp(Color(0.2, 0.35, 0.5), h01(float(k), 4.0, 9)))
	# gold light pooling across the meadow from the low sun
	glow_pool(I, Vector3(-2.0, 0.07, 2.0), 5.5, Color(1.0, 0.85, 0.4, 0.28))
	glow_pool(I, Vector3(3.0, 0.07, -3.0), 4.0, Color(1.0, 0.8, 0.35, 0.22))


func _corner_hem() -> void:
	var edge := Color(0.42, 0.5, 0.42)
	patch("matte", Vector3(0, 0.0, -1.0), 10.5, Color(0.7, 0.82, 0.88), Color(0.5, 0.66, 0.78), edge, 31, 0.05, 8, 34, Vector2(1.2, 1.0))
	# scorched ring where the hem has burned the meadow
	patch("matte", Vector3(-0.8, 0.02, -0.6), 2.4, Color(0.2, 0.11, 0.07), Color(0.09, 0.06, 0.06), Color(0.42, 0.55, 0.6), 32, 0.02, 5, 22)
	glow_pool(I, Vector3(-0.8, 0.07, -0.4), 3.4, Color(1.0, 0.5, 0.15, 0.55))
	for k in 8:
		var x := (h01(float(k), 1.0, 33) - 0.5) * 14.0
		var z := -3.0 - h01(float(k), 2.0, 33) * 6.0
		blob("matte", Vector3(x, 0, z), Vector3(1.0, 0.3, 0.7) * (0.6 + h01(float(k), 3.0, 33)), Color(0.85, 0.94, 0.98), Color(0.5, 0.64, 0.8), k, 2, 8, 0.1)
	# trampled ash-black footprints leading to the master
	for k in 7:
		box("matte", Transform3D(Basis(Vector3.UP, 0.2), Vector3(-3.5 + k * 0.45 + (0.12 if k % 2 == 0 else -0.12), 0, 5.0 - k * 0.7)), Vector3(0, 0.03, 0), Vector3(0.08, 0.03, 0.19), Color(0.22, 0.24, 0.3))
	# broken fence, half fallen
	_fence(-7.0, -1.0, -4.5, true)
	box("matte", Transform3D(Basis(Vector3.BACK, 1.3), Vector3(2.0, 0, -4.4)), Vector3(0, 0.45, 0), Vector3(0.07, 0.45, 0.07), Color(0.22, 0.16, 0.13))
	_hut(6.0, -10.5, -0.4, true, true)


func _corner_ash() -> void:
	var edge := Color(0.3, 0.32, 0.31)
	patch("matte", Vector3(0, 0.0, -2.0), 13.0, Color(0.30, 0.31, 0.34), Color(0.16, 0.16, 0.19), edge, 41, 0.06, 8, 36, Vector2(1.25, 1.0))
	# frozen ash: pale rime crusts on the drifts
	for k in 12:
		var x := (h01(float(k), 1.0, 43) - 0.5) * 18.0
		var z := 4.0 - h01(float(k), 2.0, 43) * 13.0
		patch("matte", Vector3(x, 0.03, z), 0.8 + 1.4 * h01(float(k), 3.0, 43), Color(0.62, 0.68, 0.76), Color(0.44, 0.5, 0.6), Color(0.24, 0.25, 0.28), 44 + k, 0.03, 3, 12)
	# a fallen charred log across the mid ground
	var lx := Transform3D(Basis(Vector3.UP, 0.35) * Basis(Vector3.BACK, PI * 0.5), Vector3(-3.8, 0.34, -4.5))
	prism("matte", lx, Vector3.ZERO, 0.34, 0.26, 4.6, 8, Color(0.09, 0.08, 0.09), true, 0.2, 5)
	for k in 6:
		var x := (h01(float(k), 1.0, 46) - 0.5) * 12.0
		var z := 2.0 - h01(float(k), 2.0, 46) * 9.0
		blob("matte", Vector3(x, -0.05, z), Vector3(0.35, 0.22, 0.3) * (0.6 + h01(float(k), 3.0, 46)), Color(0.34, 0.35, 0.4), Color(0.14, 0.14, 0.17), k, 2, 6, 0.25)
	# the small warm hollow where the shoot lives (dark, very slightly green-lit)
	patch("matte", Vector3(0, 0.03, 0), 0.9, Color(0.07, 0.07, 0.08), Color(0.12, 0.13, 0.12), Color(0.2, 0.2, 0.22), 47, 0.02, 4, 16)
const HEM_COLS := [Color(2.8, 0.65, 0.18), Color(2.8, 2.0, 0.4), Color(0.45, 1.2, 2.9), Color(0.45, 2.6, 0.7)]


func _hem_col(a: float) -> Color:
	return HEM_COLS[int(floorf(fposmod(a, TAU) / (TAU / 4.0))) % 4]


func _master_robe() -> void:
	var plum := Color(0.17, 0.1, 0.24)
	prism("matte", I, Vector3.ZERO, 0.7, 0.32, 1.5, 12, plum, true, 0.1, 3)
	prism("matte", I, Vector3(0, 1.5, 0), 0.32, 0.24, 0.32, 10, plum.lightened(0.05), true)
	blob("matte", Vector3(0, 1.72, 0), Vector3(0.44, 0.17, 0.3), plum.lightened(0.12), plum, 5, 2, 10, 0.05)
	blob("matte", Vector3(0, 1.84, 0.0), Vector3(0.3, 0.36, 0.3), plum.lightened(0.08), plum.darkened(0.2), 6, 3, 10, 0.04)
	blob("matte", Vector3(0, 1.98, 0.2), Vector3(0.16, 0.2, 0.1), Color(0.01, 0.01, 0.02), Color(0.01, 0.01, 0.02), 7, 2, 8, 0.0)
	# hem trim in four arcs (the four wizard colours), glowing
	for q in 4:
		for s in 6:
			var a0 := TAU * (q * 6 + s) / 24.0
			var a1 := TAU * (q * 6 + s + 1) / 24.0
			var col: Color = HEM_COLS[q]
			var d0 := Vector3(sin(a0), 0, cos(a0))
			var d1 := Vector3(sin(a1), 0, cos(a1))
			_quad(_st("glow"), d0 * 0.7 + Vector3(0, 0.02, 0), d1 * 0.7 + Vector3(0, 0.02, 0), d1 * 0.67 + Vector3(0, 0.16, 0), d0 * 0.67 + Vector3(0, 0.16, 0), col)
	# reaching arm toward the child (+z), sleeve + pale hand
	var dir := Vector3(0.25, -0.45, 0.85).normalized()
	var ax := Transform3D(Basis(Quaternion(Vector3.UP, dir)), Vector3(0.36, 1.72, 0.08))
	prism("matte", ax, Vector3.ZERO, 0.11, 0.07, 0.78, 7, plum.lightened(0.05))
	blob("matte", Vector3(0.36, 1.72, 0.08) + dir * 0.82, Vector3(0.06, 0.06, 0.06), Color(0.85, 0.7, 0.6), Color(0.6, 0.45, 0.4), 8, 2, 6, 0.0)
	# staff in the left hand with an amber ember-orb
	prism("matte", I, Vector3(-0.52, 0, 0.32), 0.04, 0.035, 2.3, 6, Color(0.28, 0.2, 0.14))
	blob("glow", Vector3(-0.52, 2.32, 0.32), Vector3(0.09, 0.09, 0.09), Color(2.6, 1.6, 0.5), Color(2.6, 1.6, 0.5), 9, 2, 8, 0.0)
	halo(I, Vector3(-0.52, 2.4, 0.32), 0.9, Color(1.0, 0.6, 0.2, 0.7))


func _hem_flames() -> void:
	for i in 30:
		var a := TAU * (float(i) + h01(float(i), 1.0, 60) * 0.6) / 30.0
		var r := 0.68 + (h01(float(i), 2.0, 60) - 0.5) * 0.06
		var hgt := 0.22 + 0.42 * h01(float(i), 3.0, 60)
		var lean := Vector3(sin(a), 0, cos(a)) * (0.05 + 0.12 * h01(float(i), 4.0, 60)) + Vector3((h01(float(i), 5.0, 60) - 0.5) * 0.12, 0, (h01(float(i), 6.0, 60) - 0.5) * 0.12)
		var col := _hem_col(a)
		spike("glow", Vector3(sin(a) * r, 0.04, cos(a) * r), lean + Vector3(0, hgt, 0), 0.07 + 0.04 * h01(float(i), 7.0, 60), col, 3, a)
		if i % 3 == 0:
			spike("glow", Vector3(sin(a) * r, 0.05, cos(a) * r), lean * 0.7 + Vector3(0, hgt * 0.55, 0), 0.045, col.lightened(0.5), 3, a + 1.0)
	for q in 4:
		var a := TAU * (q + 0.5) / 4.0
		var c: Color = HEM_COLS[q]
		halo(I, Vector3(sin(a) * 0.65, 0.25, cos(a) * 0.65), 0.75, Color(c.r * 0.4, c.g * 0.4, c.b * 0.4, 0.55))
		glow_pool(I, Vector3(sin(a) * 1.0, 0.05, cos(a) * 1.0), 1.4, Color(c.r * 0.35, c.g * 0.35, c.b * 0.35, 0.4))
	for k in 16:
		var a := TAU * h01(float(k), 1.0, 61)
		var rr := 0.4 + 0.5 * h01(float(k), 2.0, 61)
		halo(I, Vector3(sin(a) * rr, 0.6 + 1.6 * h01(float(k), 3.0, 61), cos(a) * rr), 0.045, Color(2.0, 1.0, 0.3, 0.9), 0.0)


func _frost_ring() -> void:
	patch("matte", Vector3(0, 0.02, 0), 1.5, Color(0.92, 0.97, 1.0), Color(0.7, 0.86, 0.96), Color(0.5, 0.66, 0.78), 71, 0.03, 4, 18)
	for i in 18:
		var a := TAU * (float(i) + h01(float(i), 1.0, 72)) / 18.0
		var r := 0.32 + 0.75 * h01(float(i), 2.0, 72)
		var hgt := 0.14 + 0.4 * h01(float(i), 3.0, 72)
		var lean := Vector3((h01(float(i), 4.0, 72) - 0.5) * 0.3, 0, (h01(float(i), 5.0, 72) - 0.5) * 0.3)
		spike("matte", Vector3(sin(a) * r, 0.0, cos(a) * r), lean + Vector3(0, hgt, 0), 0.05 + 0.03 * h01(float(i), 6.0, 72), Color(0.78, 0.92, 1.0), 4, a)
		if i % 3 == 0:
			spike("glow", Vector3(sin(a) * r, 0.0, cos(a) * r), lean + Vector3(0, hgt * 0.9, 0), 0.03, Color(0.5, 1.0, 1.9), 4, a)
	# a small frost-bitten sapling (own mesh: the kit sapling costs 19 draws)
	prism("matte", I, Vector3.ZERO, 0.04, 0.02, 0.85, 6, Color(0.36, 0.3, 0.3), true, 0.1, 74)
	for k in 9:
		var ay := 0.3 + 0.07 * k
		var aa := TAU * float(k) * 0.382
		spike("matte", Vector3(0, ay, 0), Vector3(sin(aa) * 0.3, 0.08 - 0.02 * (k % 3), cos(aa) * 0.3), 0.1, Color(0.72, 0.88, 0.95), 3, float(k))
	halo(I, Vector3(0, 0.3, 0), 1.6, Color(0.45, 0.7, 1.0, 0.35))
	for k in 6:
		var a := TAU * h01(float(k), 1.0, 73)
		halo(I, Vector3(sin(a) * 0.6, 0.15 + 0.4 * h01(float(k), 2.0, 73), cos(a) * 0.6), 0.09, Color(1.5, 2.0, 2.6, 0.9), 1.0)


func _green_shoot() -> void:
	prism("matte", I, Vector3.ZERO, 0.016, 0.009, 0.24, 6, Color(0.2, 0.55, 0.18))
	spike("glow", Vector3(0, 0.2, 0), Vector3(0.14, 0.07, 0.02), 0.035, Color(0.4, 1.7, 0.5), 4, 0.4)
	spike("glow", Vector3(0, 0.22, 0), Vector3(-0.12, 0.09, -0.03), 0.032, Color(0.45, 1.8, 0.55), 4, 1.2)
	spike("glow", Vector3(0, 0.24, 0), Vector3(0.01, 0.16, 0.0), 0.02, Color(0.6, 2.0, 0.7), 4)
	halo(I, Vector3(0, 0.2, 0), 0.7, Color(0.4, 1.0, 0.45, 0.32))
	glow_pool(I, Vector3(0, 0.03, 0), 0.9, Color(0.4, 1.0, 0.4, 0.5))
	for k in 6:
		var a := TAU * h01(float(k), 1.0, 81)
		halo(I, Vector3(sin(a) * 0.25, 0.1 + 0.4 * h01(float(k), 2.0, 81), cos(a) * 0.25), 0.05, Color(1.4, 2.6, 1.4, 0.9), 1.0)


func _snow_fir(v: int) -> void:
	var hh: float = [5.2, 3.8, 4.6][v - 1]
	var dark := Color(0.05, 0.19, 0.12) if v < 3 else Color(0.2, 0.32, 0.38)
	var snow := Color(0.9, 0.94, 1.0) if v < 3 else Color(0.78, 0.9, 1.0)
	prism("matte", I, Vector3.ZERO, 0.18, 0.1, hh * 0.3, 7, Color(0.25, 0.17, 0.12))
	var tiers := 5 if v != 2 else 4
	for t in tiers:
		var f := float(t) / tiers
		var y := hh * (0.2 + 0.62 * f)
		var r := lerpf(1.55, 0.5, f) * hh / 5.2
		var th := hh * 0.28
		prism("matte", I, Vector3(0, y, 0), r, 0.05, th, 8, dark, true, 0.3, t + v)
		prism("matte", I, Vector3(0, y + th * 0.22, 0), r * 0.76, 0.04, th * 0.78, 8, snow, true, 0.15, t + 9)
	prism("matte", I, Vector3(0, hh * 0.9, 0), 0.22, 0.0, hh * 0.16, 6, snow)


func _blossom_tree() -> void:
	prism("matte", I, Vector3.ZERO, 0.24, 0.15, 1.6, 7, Color(0.3, 0.22, 0.17), true, 0.2, 1)
	prism("matte", Transform3D(Basis(Vector3.BACK, 0.5), Vector3(0, 1.4, 0)), Vector3.ZERO, 0.11, 0.07, 1.1, 6, Color(0.3, 0.22, 0.17))
	prism("matte", Transform3D(Basis(Vector3.BACK, -0.6), Vector3(0, 1.3, 0)), Vector3.ZERO, 0.1, 0.06, 1.0, 6, Color(0.3, 0.22, 0.17))
	var cs := [Vector3(0, 2.7, 0), Vector3(-0.9, 2.4, 0.3), Vector3(0.9, 2.5, -0.2), Vector3(0.2, 3.1, 0.5), Vector3(-0.3, 2.3, -0.8)]
	for k in cs.size():
		var pink := k % 2 == 0
		var top := Color(1.0, 0.72, 0.8) if pink else Color(1.0, 0.94, 0.95)
		var side := Color(0.78, 0.4, 0.55) if pink else Color(0.8, 0.62, 0.7)
		blob("matte", (cs[k] as Vector3) - Vector3(0, 0.45, 0), Vector3(1.05, 0.95, 1.0), top, side, k + 4, 3, 9, 0.16)
	patch("matte", Vector3(0, 0.03, 0), 1.9, Color(1.0, 0.8, 0.86), Color(0.85, 0.6, 0.7), Color(0.38, 0.64, 0.24), 91, 0.02, 3, 14)


func _meadow_tufts() -> void:
	for c in 12:
		var a := TAU * h01(float(c), 1.0, 95)
		var r := 1.6 * sqrt(h01(float(c), 2.0, 95))
		var p := Vector3(sin(a) * r, 0, cos(a) * r)
		for b in 4:
			var ha := 0.25 + 0.3 * h01(float(c), float(b) + 3.0, 95)
			var lean := Vector3((h01(float(c), float(b), 96) - 0.5) * 0.3, 0, (h01(float(c), float(b), 97) - 0.5) * 0.3)
			var g := 0.5 + 0.3 * h01(float(c), float(b), 98)
			spike("matte", p + Vector3((b - 1.5) * 0.03, 0, 0), lean + Vector3(0, ha, 0), 0.035, Color(0.26 * g, 0.6 * g, 0.18 * g), 3, float(b))


func _flower_patch() -> void:
	var pal := [Color(1.0, 0.85, 0.2), Color(1.0, 1.0, 0.95), Color(0.95, 0.45, 0.6), Color(0.5, 0.62, 1.0)]
	for f in 11:
		var a := TAU * h01(float(f), 1.0, 99)
		var r := 1.1 * sqrt(h01(float(f), 2.0, 99))
		var p := Vector3(sin(a) * r, 0, cos(a) * r)
		var hh := 0.3 + 0.25 * h01(float(f), 3.0, 99)
		spike("matte", p, Vector3(0, hh, 0), 0.014, Color(0.2, 0.5, 0.15), 3)
		var pc: Color = pal[f % 4]
		blob("matte", p + Vector3(0, hh - 0.01, 0), Vector3(0.065, 0.05, 0.065), pc, pc.darkened(0.25), f, 2, 6, 0.1)
	for f in 5:
		var a := TAU * h01(float(f), 5.0, 99)
		spike("matte", Vector3(sin(a) * 0.5, 0, cos(a) * 0.5), Vector3(0.05, 0.4, 0.0), 0.05, Color(0.25, 0.6, 0.18), 3, float(f))
func _stump(r: float, h: float, seed: int) -> void:
	var st := _st("matte")
	var sides := 10
	var tops: Array = []
	for i in sides:
		tops.append(h * (0.6 + 0.75 * h01(float(i), 1.0, seed * 7)))
	var cen := Vector3(0, h * 0.8, 0)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var i2 := (i + 1) % sides
		var r0 := r * (1.0 + 0.1 * h01(float(i), 2.0, seed))
		var r1 := r * (1.0 + 0.1 * h01(float(i2), 2.0, seed))
		var b0 := Vector3(sin(a0) * r0 * 1.15, 0, cos(a0) * r0 * 1.15)
		var b1 := Vector3(sin(a1) * r1 * 1.15, 0, cos(a1) * r1 * 1.15)
		var t0 := Vector3(sin(a0) * r0 * 0.85, tops[i], cos(a0) * r0 * 0.85)
		var t1 := Vector3(sin(a1) * r1 * 0.85, tops[i2], cos(a1) * r1 * 0.85)
		var k := 0.7 + 0.5 * h01(float(i), 3.0, seed)
		var col := Color(0.1 * k, 0.09 * k, 0.1 * k)
		_quad(st, b0, b1, t1, t0, col)
		_tri(st, cen, t0, t1, Color(0.06, 0.055, 0.06))
		# frost dust on the broken rim
		if i % 2 == 0:
			_tri(st, t0 + Vector3(0, 0.005, 0), t0.lerp(t1, 0.5) + Vector3(0, 0.02, 0), cen.lerp(t0, 0.6) + Vector3(0, 0.03, 0), Color(0.62, 0.7, 0.8))
	for k in 3:
		var a := TAU * h01(float(k), 4.0, seed)
		blob("matte", Vector3(sin(a) * r * 1.2, -0.02, cos(a) * r * 1.2), Vector3(r * 0.5, h * 0.25, r * 0.3), Color(0.14, 0.13, 0.15), Color(0.07, 0.06, 0.07), k + seed, 2, 6, 0.2)
	# a drift of ash banked on the lee side
	blob("matte", Vector3(r * 1.1, -0.03, r * 0.4), Vector3(r * 1.1, h * 0.35, r * 0.6), Color(0.5, 0.55, 0.64), Color(0.24, 0.25, 0.3), seed + 3, 2, 8, 0.15)


func _dead_trunk(h: float, r: float, seed: int) -> void:
	var lean := (h01(1.0, 2.0, seed) - 0.5) * 0.22
	var xf := Transform3D(Basis(Vector3.BACK, lean), Vector3.ZERO)
	prism("matte", xf, Vector3.ZERO, r * 1.25, r * 0.4, h, 8, Color(0.09, 0.08, 0.1), true, 0.4, seed)
	for b in 4:
		var y := h * (0.35 + 0.15 * b)
		var side := 1.0 if b % 2 == 0 else -1.0
		var ang := side * (0.9 + 0.3 * h01(float(b), 1.0, seed))
		var bxf := Transform3D(Basis(Vector3.BACK, ang + lean) * Basis(Vector3.UP, h01(float(b), 2.0, seed) * 2.0), xf * Vector3(0, y, 0))
		prism("matte", bxf, Vector3.ZERO, r * 0.35, r * 0.06, h * (0.28 - b * 0.03), 5, Color(0.09, 0.08, 0.1))
	prism("matte", xf, Vector3(0, h * 0.95, 0), r * 0.4, 0.0, 0.5, 5, Color(0.08, 0.075, 0.09))
	# frost rime on the windward side
	for k in 4:
		var y := h * (0.15 + 0.2 * k)
		box("matte", xf, Vector3(r * 0.9 * (1.0 - y / h * 0.6), y, 0), Vector3(0.03, 0.12, r * 0.35), Color(0.62, 0.7, 0.8))


func _ash_drifts() -> void:
	for k in 8:
		var x := (h01(float(k), 1.0, 110) - 0.5) * 10.0
		var z := (h01(float(k), 2.0, 110) - 0.5) * 10.0
		if x > -3.5 and x < 3.5 and z > -1.6 and z < 5.0:
			continue  # keep the shoot and the H09 camera lane clear
		blob("matte", Vector3(x, -0.04, z), Vector3(1.5, 0.3, 0.8) * (0.6 + 0.7 * h01(float(k), 3.0, 110)), Color(0.5, 0.55, 0.64), Color(0.22, 0.23, 0.28), k, 2, 9, 0.12)


func _pollen() -> void:
	for k in 46:
		halo(I, Vector3((h01(float(k), 1.0, 120) - 0.5) * 9.0, 0.3 + 2.8 * h01(float(k), 2.0, 120), (h01(float(k), 3.0, 120) - 0.5) * 9.0), 0.03 + 0.05 * h01(float(k), 4.0, 120), Color(1.0, 0.85, 0.4, 0.75), 0.0)


func _snowfall() -> void:
	for k in 90:
		halo(I, Vector3((h01(float(k), 1.0, 121) - 0.5) * 11.0, 0.1 + 5.0 * h01(float(k), 2.0, 121), (h01(float(k), 3.0, 121) - 0.5) * 11.0), 0.018 + 0.03 * h01(float(k), 4.0, 121), Color(0.9, 0.95, 1.0, 0.85), 0.0)


func _frost_glitter() -> void:
	for k in 34:
		halo(I, Vector3((h01(float(k), 1.0, 122) - 0.5) * 12.0, 0.04 + 0.5 * h01(float(k), 2.0, 122), (h01(float(k), 3.0, 122) - 0.5) * 12.0), 0.05 + 0.08 * h01(float(k), 4.0, 122), Color(1.5, 1.9, 2.6, 0.9), 1.0)


func _sun_shafts() -> void:
	var st := _st("shaft")
	var L := Vector3(0.2, -0.55, 0.8).normalized()
	var w1 := L.cross(Vector3.RIGHT).normalized()
	var w2 := L.cross(w1).normalized()
	for k in 5:
		var A := Vector3(-6.0 + 3.2 * k + h01(float(k), 1.0, 130) * 1.2, 9.0 + h01(float(k), 2.0, 130) * 2.0, -12.0 - h01(float(k), 3.0, 130) * 3.0)
		var B := A + L * (17.0 + 4.0 * h01(float(k), 4.0, 130))
		var wa := 0.5 + 0.5 * h01(float(k), 5.0, 130)
		var sc := Color(1.0, 0.88, 0.5, 0.4)
		for w: Vector3 in [w1, w2]:
			_tri(st, A - w * wa * 0.5, A + w * wa * 0.5, B + w * wa * 1.6, sc, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
			_tri(st, A - w * wa * 0.5, B + w * wa * 1.6, B - w * wa * 1.6, sc, Vector2(0, 0), Vector2(1, 1), Vector2(0, 1))


func _butterflies() -> void:
	var pal := [Color(1.0, 0.85, 0.2), Color(1.0, 1.0, 0.95), Color(0.5, 0.65, 1.0)]
	for k in 6:
		var p := Vector3((h01(float(k), 1.0, 140) - 0.5) * 4.0, 0.5 + 0.9 * h01(float(k), 2.0, 140), (h01(float(k), 3.0, 140) - 0.5) * 4.0)
		var c: Color = pal[k % 3]
		var s := 0.07
		dquad("matte", p, p + Vector3(-s, s * 0.7, 0.02), p + Vector3(-s * 1.1, s * 0.1, 0.05), p + Vector3(-s * 0.2, -s * 0.5, 0.01), c)
		dquad("matte", p, p + Vector3(s * 0.2, -s * 0.5, 0.01), p + Vector3(s * 1.1, s * 0.1, 0.05), p + Vector3(s, s * 0.7, 0.02), c)


func _far_glow() -> void:
	# the burning village far behind the hem scene: black roof silhouettes, fire-lit windows, a big orange bloom
	for k in 7:
		var x := -12.0 + k * 4.0 + (h01(float(k), 1.0, 150) - 0.5) * 2.0
		var xf := Transform3D(Basis(Vector3.UP, (h01(float(k), 2.0, 150) - 0.5) * 0.6), Vector3(x, 0, 0))
		box("matte", xf, Vector3(0, 1.0, 0), Vector3(1.6, 1.0, 1.2), Color(0.05, 0.04, 0.06))
		prism("matte", xf * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO), Vector3(0, 2.0, 0), 2.4, 0.1, 1.2 + h01(float(k), 3.0, 150), 4, Color(0.04, 0.035, 0.05))
		box("glow", xf, Vector3(0, 1.0, 1.21), Vector3(0.4, 0.3, 0.02), Color(3.0, 1.2, 0.3))
		spike("glow", Vector3(x, 2.0, 0), Vector3(0.2, 1.4 + 1.6 * h01(float(k), 4.0, 150), 0.0), 0.5, Color(3.0, 1.0, 0.2), 3, float(k))
		halo(I, Vector3(x, 2.4, 1.0), 6.0, Color(1.0, 0.4, 0.1, 0.5))
	for k in 6:
		mist(I, Vector3(-12.0 + k * 4.5, 4.5 + h01(float(k), 1.0, 151) * 2.0, 1.0), 5.0, Color(0.25, 0.15, 0.14, 0.5), 0.1)


func _make_light_part() -> void:
	var n := Node3D.new()
	n.name = "hem_light"
	var l := OmniLight3D.new()
	l.name = "Fire"
	l.light_color = Color(1.0, 0.55, 0.25)
	l.light_energy = 3.0
	l.omni_range = 11.0
	l.omni_attenuation = 1.2
	l.position = Vector3(0, 0.7, 0.9)
	l.set_script(load(DIR + "/hem_light_flicker.gd"))
	n.add_child(l)
	l.owner = n
	var ps := PackedScene.new()
	ps.pack(n)
	ResourceSaver.save(ps, DIR + "/hem_light.tscn")
	n.free()
	var m := Node3D.new()
	m.name = "mood_zones"
	m.set_script(load(DIR + "/mood_zones.gd"))
	var ps2 := PackedScene.new()
	ps2.pack(m)
	ResourceSaver.save(ps2, DIR + "/mood_zones.tscn")
	m.free()
	print("light parts saved")
