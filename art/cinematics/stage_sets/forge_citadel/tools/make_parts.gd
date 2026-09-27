extends SceneTree
## forge_citadel big parts (tech-art tool, not game code): the Master's citadel pieces built from boxes / prisms into
## vertex-coloured meshes on a handful of SHARED materials (matte, metal, glow, banner, waterfall, pool), saved as
## mesh-only scenes `parts/<name>.tscn` so World Forge rows bake them into the set (one draw per material, total).
## Every part: origin at its base centre, faces +Z at yaw 0. Deterministic (hash noise, no RNG state).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_citadel/tools/make_parts.gd --quit-after 600

const DIR := "res://art/cinematics/stage_sets/forge_citadel/parts"
const MATS := DIR + "/materials"

const STONE := Color(0.63, 0.59, 0.53)
const STONE_D := Color(0.44, 0.41, 0.39)
const SLATE := Color(0.24, 0.21, 0.36)
const GOLD := Color(0.86, 0.66, 0.26)
const WARM := Color(1.0, 0.68, 0.32)
const VIOLET := Color(0.34, 0.13, 0.50)
const ROCK := Color(0.40, 0.37, 0.35)
const WOOD := Color(0.30, 0.20, 0.13)

var mats := {}
var sts := {}  ## material key -> SurfaceTool (current part)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_materials()
	_part("great_tower", func() -> void: _tower(Transform3D.IDENTITY, 3.6, 19.0, 14, true))
	_part("small_tower", func() -> void: _tower(Transform3D.IDENTITY, 2.4, 11.0, 10, true))
	_part("throne_tower", _throne)
	_part("gatehouse", _gatehouse)
	_part("drum_mount", func() -> void: _drum(72.0, 30.0, 64, 10, 2.4))
	_part("drum_t2", func() -> void: _drum(42.0, 8.0, 48, 11))
	_part("drum_t3", func() -> void: _drum(24.0, 10.0, 36, 12))
	_part("drum_pinnacle", func() -> void: _drum(15.0, 30.0, 24, 13, 1.6))
	_part("drum_ruin", func() -> void: _drum(11.0, 30.0, 20, 14, 1.4))
	_part("stair_t1", func() -> void: _stair(11.0, 8.0, 8.0))
	_part("stair_t2", func() -> void: _stair(13.0, 10.0, 6.0))
	_part("falls_8", func() -> void: _falls(5.0, 8.2, true))
	_part("falls_10", func() -> void: _falls(4.2, 10.2, true))
	_part("falls_30", func() -> void: _falls(9.0, 31.0, false))
	_part("rainbow", _rainbow)
	_part("great_bridge", _great_bridge)
	_part("statue", _statue)
	_part("offerings", _offerings)
	_part("dome", func() -> void: _dome(false))
	_part("dome_ruin", func() -> void: _dome(true))
	_part("orrery", func() -> void: _orrery(false))
	_part("orrery_ruin", func() -> void: _orrery(true))
	_part("panel", func() -> void: _panel(Color(0, 0, 0, 0), false))
	_part("panel_win", func() -> void: _panel(WARM, false))
	_part("panel_red", func() -> void: _panel(Color(1.0, 0.25, 0.1), false))
	_part("panel_violet", func() -> void: _panel(Color(0.7, 0.3, 1.0), false))
	_part("panel_blue", func() -> void: _panel(Color(0.35, 0.65, 1.0), false))
	_part("panel_green", func() -> void: _panel(Color(0.35, 0.95, 0.3), false))
	_part("panel_broken", func() -> void: _panel(Color(0, 0, 0, 0), true))
	_part("throne", _throne_seat)
	_part("column", _column)
	_part("shaft_red", func() -> void: _shaft(Color(1.0, 0.3, 0.12)))
	_part("shaft_violet", func() -> void: _shaft(Color(0.65, 0.3, 1.0)))
	_part("shaft_blue", func() -> void: _shaft(Color(0.3, 0.6, 1.0)))
	_part("shaft_green", func() -> void: _shaft(Color(0.35, 1.0, 0.35)))
	_part("belfry", _belfry)
	_part("vines", _vines)
	_part("garden", _garden)
	_part("cloud_puff", _cloud)
	_part("ring_road", func() -> void: _ring(51.0, 6.0))
	_part("court_floor", func() -> void: _disc(9.5, Color(0.48, 0.44, 0.40)))
	_part("feast_table", _feast)
	_part("master_figure", _master)
	_part("swordsman", _swordsman)
	_part("candle", _candle)
	_part("moss", _moss)
	_part("fire_cluster", _fires)
	for b: Array in [["banner_master", VIOLET, GOLD], ["banner_fire", Color(0.72, 0.18, 0.08), GOLD], ["banner_ice", Color(0.55, 0.75, 0.92), Color(0.95, 0.97, 1.0)],
			["banner_nature", Color(0.20, 0.45, 0.16), GOLD], ["banner_shadow", Color(0.16, 0.10, 0.22), Color(0.62, 0.45, 0.85)]]:
		_part(b[0], func() -> void: _banner_hang(b[1], b[2]))
	_part("flag_pole", func() -> void: _flag_pole(VIOLET, GOLD))
	_part("lantern_post", _lantern_post)
	_part("lantern_string", _lantern_string)
	_part("stall_a", func() -> void: _stall(Color(0.75, 0.22, 0.14), Color(0.92, 0.84, 0.66), 1))
	_part("stall_b", func() -> void: _stall(Color(0.18, 0.36, 0.62), Color(0.92, 0.84, 0.66), 2))
	_part("stall_c", func() -> void: _stall(Color(0.34, 0.52, 0.20), Color(0.86, 0.66, 0.26), 3))
	_part("crowd_a", func() -> void: _crowd(11, 4.0, 5))
	_part("crowd_b", func() -> void: _crowd(16, 6.0, 9))
	_part("sky_bridge", func() -> void: _bridge(13.0))
	_part("ridge_backdrop", _ridge)
	_part("brazier_tall", _brazier_tall)
	# a zero-draw subject pin (tagged `place` for mark subjects)
	var pin := Node3D.new()
	pin.name = "subject_pin"
	var ps := PackedScene.new()
	ps.pack(pin)
	ResourceSaver.save(ps, DIR + "/subject_pin.tscn")
	pin.free()
	quit()


# ------------------------------------------------------------------ plumbing

func _materials() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATS))
	mats["matte"] = load(MATS + "/citadel_matte.tres")
	mats["metal"] = load(MATS + "/citadel_metal.tres")
	mats["glow"] = load(MATS + "/citadel_glow.tres")
	var defs := {
		"banner": func() -> Material:
			var m := ShaderMaterial.new()
			m.shader = load(MATS + "/citadel_banner.gdshader")
			return m,
		"falls": func() -> Material:
			var m := ShaderMaterial.new()
			m.shader = load(MATS + "/citadel_waterfall.gdshader")
			return m,
		"shaft": func() -> Material:
			var m := ShaderMaterial.new()
			m.shader = load(MATS + "/citadel_shaft.gdshader")
			return m,
		"pool": func() -> Material:
			var m := StandardMaterial3D.new()
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.06
			m.metallic = 0.35
			return m,
	}
	for k: String in defs:
		var p := "%s/citadel_%s.tres" % [MATS, k]
		ResourceSaver.save((defs[k] as Callable).call(), p)
		mats[k] = load(p)


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
	for key: String in ["matte", "metal", "glow", "banner", "pool", "falls", "shaft"]:
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


# ------------------------------------------------------------------ parts

func _tower(xf: Transform3D, r: float, h: float, n: int, roof: bool) -> void:
	prism("matte", xf, Vector3.ZERO, r + 0.5, r, 1.4, n, STONE_D)
	prism("matte", xf, Vector3(0, 1.4, 0), r, r * 0.93, h - 1.4, n, STONE, false)
	for band in [0.33, 0.66]:
		prism("matte", xf, Vector3(0, h * band, 0), r * (1.0 - 0.07 * band) + 0.12, r * (1.0 - 0.07 * band) + 0.12, 0.35, n, STONE_D, false)
	prism("matte", xf, Vector3(0, h, 0), r * 0.93, r * 1.14, 0.9, n, STONE_D)
	merlons("matte", xf, h + 0.9, r * 1.08, n, 0.9, STONE)
	# windows (glow slits) on 4 sides at 3 heights
	for k in 4:
		var bs := Basis(Vector3.UP, TAU * k / 4.0 + PI / n)
		for y in [h * 0.3, h * 0.55, h * 0.8]:
			box("glow", xf * Transform3D(bs, Vector3.ZERO), Vector3(0, y, r * (1.0 - 0.07 * y / h) - 0.02), Vector3(0.22, 0.6, 0.12), WARM)
	if roof:
		prism("matte", xf, Vector3(0, h + 0.9, 0), r * 0.95, r * 0.95, 1.2, n, STONE_D, false)
		prism("matte", xf, Vector3(0, h + 2.1, 0), r * 1.2, 0.0, r * 2.3, n, SLATE)
		prism("metal", xf, Vector3(0, h + 2.1 + r * 2.3 - 0.3, 0), 0.18, 0.0, 2.2, 6, GOLD)


func _throne() -> void:
	var I := Transform3D.IDENTITY
	# stepped base
	box("matte", I, Vector3(0, 1.0, 0), Vector3(7.5, 1.0, 7.5), STONE_D)
	box("matte", I, Vector3(0, 6.0, 0), Vector3(6.2, 4.0, 6.2), STONE)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			prism("matte", I, Vector3(6.0 * sx, 0, 6.0 * sz), 1.9, 1.7, 13.0, 10, STONE)
			prism("matte", I, Vector3(6.0 * sx, 13.0, 6.0 * sz), 2.0, 0.0, 5.0, 10, SLATE)
			prism("metal", I, Vector3(6.0 * sx, 17.6, 6.0 * sz), 0.12, 0.0, 1.4, 6, GOLD)
	box("glow", I, Vector3(0, 2.6, 6.22), Vector3(1.4, 2.2, 0.06), WARM)  # the great door
	box("metal", I, Vector3(0, 5.1, 6.3), Vector3(1.8, 0.25, 0.12), GOLD)
	# shaft
	prism("matte", I, Vector3(0, 10.0, 0), 5.0, 4.4, 30.0, 8, STONE, false)
	for y in [16.0, 24.0, 32.0]:
		prism("matte", I, Vector3(0, y, 0), 5.0 - 0.02 * (y - 10.0) + 0.15, 5.0 - 0.02 * (y - 10.0) + 0.15, 0.5, 8, STONE_D, false)
	for k in 8:
		var bs := Basis(Vector3.UP, TAU * k / 8.0 + PI / 8.0)
		for y in [13.0, 20.0, 27.5, 35.0]:
			box("glow", Transform3D(bs, Vector3.ZERO), Vector3(0, y, 4.95 - 0.02 * (y - 10.0) - 0.9), Vector3(0.35, 1.3, 0.12), WARM if k % 2 == 0 else Color(0.8, 0.55, 1.0))
	# balcony and crown
	prism("matte", I, Vector3(0, 40.0, 0), 4.4, 6.6, 1.6, 16, STONE_D)
	merlons("matte", I, 41.6, 6.3, 20, 0.9, STONE)
	prism("matte", I, Vector3(0, 41.6, 0), 3.8, 3.5, 10.0, 8, STONE, false)
	for k in 8:
		var a := TAU * k / 8.0
		var p := Vector3(sin(a) * 5.6, 41.6, cos(a) * 5.6)
		prism("matte", I, p, 0.55, 0.45, 3.0, 6, STONE)
		prism("matte", I, p + Vector3(0, 3.0, 0), 0.7, 0.0, 3.2, 6, SLATE)
		box("glow", I, p + Vector3(0, 2.4, 0), Vector3(0.18, 0.18, 0.18), Color(0.85, 0.6, 1.0))
	prism("metal", I, Vector3(0, 51.6, 0), 3.9, 3.9, 0.5, 8, GOLD, false)
	prism("matte", I, Vector3(0, 52.1, 0), 4.3, 0.0, 14.0, 8, SLATE)
	# the Master's crystal
	prism("glow", I, Vector3(0, 65.0, 0), 0.0, 1.3, 2.6, 6, Color(0.82, 0.65, 1.0))
	prism("glow", I, Vector3(0, 67.6, 0), 1.3, 0.0, 3.4, 6, Color(0.95, 0.85, 1.0))


func _gatehouse() -> void:
	var I := Transform3D.IDENTITY
	for sx in [-1.0, 1.0]:
		_tower(Transform3D(Basis(), Vector3(6.6 * sx, 0, 0)), 3.3, 14.0, 12, true)
	box("matte", I, Vector3(0, 11.5, 0), Vector3(4.2, 2.5, 2.2), STONE)
	box("matte", I, Vector3(0, 9.2, 0), Vector3(4.2, 0.3, 2.35), STONE_D)
	for i in 5:
		box("matte", I, Vector3(-3.4 + i * 1.7, 14.4, 0), Vector3(0.45, 0.45, 2.2), STONE)
	# half-raised portcullis
	for i in 7:
		box("metal", I, Vector3(-3.0 + i * 1.0, 7.4, 0.2), Vector3(0.07, 1.8, 0.07), Color(0.2, 0.2, 0.22))
	box("metal", I, Vector3(0, 6.0, 0.2), Vector3(3.3, 0.08, 0.08), Color(0.2, 0.2, 0.22))
	box("metal", I, Vector3(0, 12.0, 2.3), Vector3(1.2, 1.2, 0.06), GOLD)  # the Master's seal
	for sx in [-1.0, 1.0]:
		box("metal", I, Vector3(3.2 * sx, 5.4, 2.7), Vector3(0.12, 0.12, 0.5), Color(0.15, 0.13, 0.12))
		box("glow", I, Vector3(3.2 * sx, 5.0, 3.1), Vector3(0.28, 0.4, 0.28), WARM)


## A rocky cliff drum (tier) of radius r, height h; flagstone top.
func _drum(r: float, h: float, sides: int, seed: int, rough := 0.55) -> void:
	var st := _st("matte")
	var rows := maxi(3, int(h / 1.6))
	var rad := func(i: int, j: int) -> float:
		var ii := i % sides
		if j == rows:
			return r
		return r + rough * (h01(float(ii), float(j), seed) - 0.5) + (0.9 + rough * 3.0) * (1.0 - float(j) / rows) * (1.0 - float(j) / rows) + 0.4
	for i in sides:
		for j in rows:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var y0 := h * j / rows
			var y1 := h * (j + 1) / rows
			var p00 := Vector3(sin(a0) * rad.call(i, j), y0, cos(a0) * rad.call(i, j))
			var p10 := Vector3(sin(a1) * rad.call(i + 1, j), y0, cos(a1) * rad.call(i + 1, j))
			var p01 := Vector3(sin(a0) * rad.call(i, j + 1), y1, cos(a0) * rad.call(i, j + 1))
			var p11 := Vector3(sin(a1) * rad.call(i + 1, j + 1), y1, cos(a1) * rad.call(i + 1, j + 1))
			var strata := 0.85 + 0.2 * h01(float(j), 3.0, seed) + 0.08 * h01(float(i), float(j), seed + 5)
			var col := ROCK * strata
			if j == rows - 1:
				col = STONE_D  # masonry lip
			_quad(st, p00, p10, p11, p01, Color(col.r, col.g, col.b))
	# flagstone top: concentric rings
	var rings := 5
	for k in rings:
		var ra := r * float(k) / rings
		var rb := r * float(k + 1) / rings
		for i in sides:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var tone := Color(0.54, 0.50, 0.45) * (0.9 + 0.12 * h01(float(i), float(k), seed + 9))
			var q0 := Vector3(sin(a0) * ra, h, cos(a0) * ra)
			var q1 := Vector3(sin(a1) * ra, h, cos(a1) * ra)
			var q2 := Vector3(sin(a1) * rb, h, cos(a1) * rb)
			var q3 := Vector3(sin(a0) * rb, h, cos(a0) * rb)
			_quad(st, q3, q2, q1, q0, Color(tone.r, tone.g, tone.b))


## A grand stair: base at z=0 (y=0), climbing toward -z to the top at z=-len (y=rise), width w.
func _stair(len: float, rise: float, w: float) -> void:
	var n := int(ceil(rise / 0.34))
	var dz := len / n
	var dy := rise / n
	var I := Transform3D.IDENTITY
	for i in n:
		var top := dy * (i + 1)
		var tone := Color(0.58, 0.54, 0.49) * (0.92 + 0.1 * h01(float(i), 1.0, 3))
		box("matte", I, Vector3(0, top * 0.5, -dz * (i + 0.5)), Vector3(w * 0.5, top * 0.5, dz * 0.5 + 0.01), Color(tone.r, tone.g, tone.b))
	# side walls (sloped, made of stepped blocks) + lanterns on posts
	for sx in [-1.0, 1.0]:
		for i in n:
			var top := dy * (i + 1) + 0.9
			box("matte", I, Vector3(sx * (w * 0.5 + 0.35), top * 0.5, -dz * (i + 0.5)), Vector3(0.35, top * 0.5, dz * 0.5 + 0.01), STONE_D)
		for k in 3:
			var z := -len * (0.1 + 0.4 * k)
			var y := rise * (0.1 + 0.4 * k) + 0.9
			box("matte", I, Vector3(sx * (w * 0.5 + 0.35), y + 0.5, z), Vector3(0.28, 0.5, 0.28), STONE)
			box("glow", I, Vector3(sx * (w * 0.5 + 0.35), y + 1.25, z), Vector3(0.2, 0.25, 0.2), WARM)
	box("matte", I, Vector3(0, rise - 0.05, -len - 1.0), Vector3(w * 0.5 + 0.7, 0.05, 1.0), STONE_D)  # landing lip


## Waterfall: a sheet from y=h down to 0, falling out toward +z, a foam skirt and a pool at its foot.
func _falls(w: float, h: float, pool: bool) -> void:
	var st := _st("falls")
	var cols := 6
	var rows := 12
	var pt := func(i: int, j: int) -> Vector3:
		var u := float(i) / cols
		var v := float(j) / rows
		return Vector3((u - 0.5) * w * (1.0 + 0.25 * v), h * (1.0 - v), 1.6 * sqrt(v) + 0.2)
	for i in cols:
		for j in rows:
			var a: Vector3 = pt.call(i, j)
			var b: Vector3 = pt.call(i + 1, j)
			var c: Vector3 = pt.call(i + 1, j + 1)
			var d: Vector3 = pt.call(i, j + 1)
			var ua := Vector2(float(i) / cols, float(j) / rows)
			var ub := Vector2(float(i + 1) / cols, float(j) / rows)
			var uc := Vector2(float(i + 1) / cols, float(j + 1) / rows)
			var ud := Vector2(float(i) / cols, float(j + 1) / rows)
			_tri(st, d, c, b, Color.WHITE, ud, uc, ub)
			_tri(st, d, b, a, Color.WHITE, ud, ub, ua)
	# foam skirt: a low ring of sheets at the foot
	for k in 8:
		var a0 := PI * k / 8.0 - PI * 0.5
		var a1 := PI * (k + 1) / 8.0 - PI * 0.5
		var r := w * 0.55
		var c0 := Vector3(sin(a0) * r, 0.05, 1.8 + cos(a0) * r * 0.6)
		var c1 := Vector3(sin(a1) * r, 0.05, 1.8 + cos(a1) * r * 0.6)
		_tri(st, c0, c1, c1 + Vector3(0, 1.4, 0), Color(1, 1, 1, 0.8), Vector2(0.2, 1), Vector2(0.8, 1), Vector2(0.8, 0.7))
		_tri(st, c0, c1 + Vector3(0, 1.4, 0), c0 + Vector3(0, 1.4, 0), Color(1, 1, 1, 0.8), Vector2(0.2, 1), Vector2(0.8, 0.7), Vector2(0.2, 0.7))
	if pool:
		var ps := _st("pool")
		var pr := w * 0.95
		var pc := Vector3(0, 0.06, 2.4)
		for i in 20:
			var a0 := TAU * i / 20.0
			var a1 := TAU * (i + 1) / 20.0
			_tri(ps, pc, pc + Vector3(sin(a0) * pr, 0, cos(a0) * pr * 0.75), pc + Vector3(sin(a1) * pr, 0, cos(a1) * pr * 0.75), Color(0.12, 0.26, 0.34))
		for i in 14:
			var a := TAU * i / 14.0
			box("matte", Transform3D(Basis(Vector3.UP, a), pc + Vector3(sin(a) * (pr + 0.3), 0, cos(a) * (pr + 0.3) * 0.75)), Vector3(0, 0.25, 0), Vector3(0.7, 0.25, 0.4), STONE_D)


## A hanging banner: gold rod at y=0, cloth down to y=-5.6 facing +z, swallow-tail. UV.x = 0 at the rod (fixed) -> 1.
func _banner_hang(col: Color, trim: Color) -> void:
	box("metal", Transform3D.IDENTITY, Vector3(0, 0, 0.05), Vector3(1.15, 0.07, 0.07), GOLD)
	var st := _st("banner")
	var rows := 10
	var hh := 5.6
	for j in rows:
		var v0 := float(j) / rows
		var v1 := float(j + 1) / rows
		var w0 := 0.9
		var w1 := 0.9
		var y0 := -hh * v0
		var y1 := -hh * v1
		var c := col if (j != 1 and j != rows - 2) else trim
		if j == rows - 1:
			# swallow tail: two points
			_tri(st, Vector3(-w0, y0, 0.1), Vector3(0, y0, 0.1), Vector3(-w1, y1 - 0.4, 0.1), col, Vector2(v0, 0), Vector2(v0, 0), Vector2(1, 0))
			_tri(st, Vector3(0, y0, 0.1), Vector3(w0, y0, 0.1), Vector3(w1, y1 - 0.4, 0.1), col, Vector2(v0, 0), Vector2(v0, 0), Vector2(1, 0))
			continue
		_tri(st, Vector3(-w1, y1, 0.1), Vector3(w1, y1, 0.1), Vector3(w0, y0, 0.1), c, Vector2(v1, 0), Vector2(v1, 0), Vector2(v0, 0))
		_tri(st, Vector3(-w1, y1, 0.1), Vector3(w0, y0, 0.1), Vector3(-w0, y0, 0.1), c, Vector2(v1, 0), Vector2(v0, 0), Vector2(v0, 0))
	# emblem: a gold diamond in the middle
	_tri(st, Vector3(0, -2.2, 0.12), Vector3(0.45, -2.8, 0.12), Vector3(0, -3.4, 0.12), trim, Vector2(0.45, 0), Vector2(0.5, 0), Vector2(0.6, 0))
	_tri(st, Vector3(0, -2.2, 0.12), Vector3(0, -3.4, 0.12), Vector3(-0.45, -2.8, 0.12), trim, Vector2(0.45, 0), Vector2(0.6, 0), Vector2(0.5, 0))


## A tall flag pole (10 m) with a long pennant flying toward +x.
func _flag_pole(col: Color, trim: Color) -> void:
	prism("matte", Transform3D.IDENTITY, Vector3.ZERO, 0.45, 0.4, 0.6, 8, STONE_D)
	prism("metal", Transform3D.IDENTITY, Vector3(0, 0.6, 0), 0.12, 0.08, 10.0, 6, Color(0.25, 0.22, 0.2))
	prism("metal", Transform3D.IDENTITY, Vector3(0, 10.6, 0), 0.2, 0.0, 0.5, 6, GOLD)
	var st := _st("banner")
	var cols := 10
	var L := 5.5
	for i in cols:
		var u0 := float(i) / cols
		var u1 := float(i + 1) / cols
		var h0 := 1.6 * (1.0 - 0.6 * u0)
		var h1 := 1.6 * (1.0 - 0.6 * u1)
		var c := trim if i == 0 else col
		var top := 10.4
		_tri(st, Vector3(L * u0, top - h0, 0), Vector3(L * u1, top - h1, 0), Vector3(L * u1, top, 0), c, Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 0))
		_tri(st, Vector3(L * u0, top - h0, 0), Vector3(L * u1, top, 0), Vector3(L * u0, top, 0), c, Vector2(u0, 0), Vector2(u1, 0), Vector2(u0, 0))


func _lantern_post() -> void:
	var I := Transform3D.IDENTITY
	box("matte", I, Vector3(0, 0.2, 0), Vector3(0.3, 0.2, 0.3), STONE_D)
	box("metal", I, Vector3(0, 1.7, 0), Vector3(0.07, 1.5, 0.07), Color(0.14, 0.12, 0.11))
	box("metal", I, Vector3(0.3, 3.15, 0), Vector3(0.35, 0.05, 0.05), Color(0.14, 0.12, 0.11))
	box("glow", I, Vector3(0.6, 2.8, 0), Vector3(0.17, 0.24, 0.17), WARM)
	box("metal", I, Vector3(0.6, 3.1, 0), Vector3(0.22, 0.06, 0.22), Color(0.14, 0.12, 0.11))


## Festival lanterns strung between two poles 10 m apart (along x), sagging.
func _lantern_string() -> void:
	var I := Transform3D.IDENTITY
	for sx in [-5.0, 5.0]:
		box("matte", I, Vector3(sx, 2.3, 0), Vector3(0.1, 2.3, 0.1), WOOD)
	var n := 9
	for i in n:
		var t := float(i + 1) / (n + 1)
		var x := -5.0 + 10.0 * t
		var y := 4.4 - 1.1 * sin(PI * t)
		var col: Color = [WARM, Color(1.0, 0.45, 0.25), Color(0.95, 0.85, 0.45)][i % 3]
		box("glow", I, Vector3(x, y - 0.25, 0), Vector3(0.16, 0.2, 0.16), col)
	for i in 10:
		var t0 := float(i) / 10.0
		var t1 := float(i + 1) / 10.0
		var a := Vector3(-5.0 + 10.0 * t0, 4.5 - 1.1 * sin(PI * t0), 0)
		var b := Vector3(-5.0 + 10.0 * t1, 4.5 - 1.1 * sin(PI * t1), 0)
		box("metal", Transform3D(Basis(Vector3.BACK, atan2(b.y - a.y, b.x - a.x)), (a + b) * 0.5), Vector3.ZERO, Vector3(a.distance_to(b) * 0.5, 0.02, 0.02), Color(0.1, 0.1, 0.1))


func _stall(awn: Color, awn2: Color, seed: int) -> void:
	var I := Transform3D.IDENTITY
	box("matte", I, Vector3(0, 0.45, 0), Vector3(1.5, 0.45, 0.7), WOOD)
	for sx in [-1.4, 1.4]:
		for sz in [-0.8, 0.8]:
			box("matte", I, Vector3(sx, 1.2, sz), Vector3(0.06, 1.2, 0.06), WOOD)
	for i in 6:
		var c := awn if i % 2 == 0 else awn2
		box("matte", Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(-1.4 + 0.47 * (i + 0.5), 2.45, 0)), Vector3.ZERO, Vector3(0.235, 0.04, 1.15), c)
	for i in 5:
		var gc: Color = [Color(0.85, 0.35, 0.15), Color(0.9, 0.75, 0.3), Color(0.35, 0.55, 0.25), Color(0.6, 0.3, 0.5), Color(0.8, 0.8, 0.7)][(i + seed) % 5]
		box("matte", I, Vector3(-1.1 + 0.55 * i, 1.0, 0.2 * (h01(float(i), 1.0, seed) - 0.5)), Vector3(0.2, 0.12, 0.2), gc)
	box("matte", Transform3D(Basis(Vector3.UP, 0.4), Vector3(2.1, 0, 0.6)), Vector3(0, 0.35, 0), Vector3(0.35, 0.35, 0.35), Color(0.40, 0.28, 0.17))
	box("glow", I, Vector3(1.35, 2.0, 0.85), Vector3(0.12, 0.16, 0.12), WARM)


## A crowd: n simple cloaked figures inside radius r (heads, shoulders, a few hoods).
func _crowd(n: int, r: float, seed: int) -> void:
	var cloaks := [Color(0.45, 0.22, 0.16), Color(0.25, 0.30, 0.42), Color(0.32, 0.36, 0.22), Color(0.50, 0.44, 0.36), Color(0.30, 0.20, 0.36), Color(0.62, 0.52, 0.30)]
	var skins := [Color(0.85, 0.66, 0.52), Color(0.62, 0.45, 0.32), Color(0.45, 0.30, 0.22)]
	for i in n:
		var a := TAU * h01(float(i), 0.3, seed)
		var d := r * sqrt(h01(float(i), 0.7, seed))
		var p := Vector3(sin(a) * d, 0, cos(a) * d)
		var s := 0.9 + 0.2 * h01(float(i), 1.1, seed)
		var xf := Transform3D(Basis(Vector3.UP, TAU * h01(float(i), 2.0, seed)).scaled(Vector3.ONE * s), p)
		var cl: Color = cloaks[int(h01(float(i), 3.0, seed) * 5.99)]
		prism("matte", xf, Vector3.ZERO, 0.34, 0.22, 1.35, 7, cl)
		prism("matte", xf, Vector3(0, 1.35, 0), 0.22, 0.26, 0.12, 7, cl.darkened(0.15))
		prism("matte", xf, Vector3(0, 1.47, 0), 0.13, 0.12, 0.24, 6, skins[int(h01(float(i), 4.0, seed) * 2.99)])
		if h01(float(i), 5.0, seed) > 0.6:
			prism("matte", xf, Vector3(0, 1.5, 0), 0.17, 0.0, 0.32, 6, cl.darkened(0.1))


## A sky bridge from x=0 to x=len at deck height 0 (placed at the deck level), arch below, parapets, lanterns.
func _bridge(len: float) -> void:
	var I := Transform3D.IDENTITY
	box("matte", I, Vector3(len * 0.5, -0.4, 0), Vector3(len * 0.5, 0.4, 1.8), STONE)
	for sz in [-1.0, 1.0]:
		box("matte", I, Vector3(len * 0.5, 0.45, sz * 1.95), Vector3(len * 0.5, 0.45, 0.2), STONE_D)
	var n := 12
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var y0 := -0.8 - 3.2 * (1.0 - sin(PI * t0))
		var y1 := -0.8 - 3.2 * (1.0 - sin(PI * t1))
		var xm := len * (t0 + t1) * 0.5
		var ym := minf(y0, y1)
		box("matte", I, Vector3(xm, (ym - 0.8) * 0.5 - 0.4 + 0.4, 0), Vector3(len / n * 0.5 + 0.02, absf(ym - 0.8) * 0.5 * 0.35 + 0.3, 1.6), STONE_D)
	for k in 3:
		for sz in [-1.0, 1.0]:
			var x := len * (0.2 + 0.3 * k)
			box("glow", I, Vector3(x, 1.1, sz * 1.95), Vector3(0.14, 0.18, 0.14), WARM)


## Distant ridge for the backdrop: 360 m wide, peaks to ~70 m, 30 m deep. Placed far north.
func _ridge() -> void:
	var st := _st("matte")
	var cols := 72
	var W := 360.0
	var rows := 4
	var hgt := func(i: int, j: int) -> float:
		var x := float(i) / cols
		var base := 28.0 + 22.0 * sin(x * 9.0 + 1.3) * 0.5 + 18.0 * h01(float(i / 3), 0.0, 17) + 10.0 * h01(float(i), 1.0, 17)
		base += 26.0 * exp(-pow((x - 0.62) * 7.0, 2.0))  # one great peak behind-right
		return base * (1.0 - float(j) / rows * 0.2) * (0.0 if j == rows else 1.0) if j < rows else 0.0
	for i in cols:
		for j in rows:
			var x0 := -W * 0.5 + W * i / cols
			var x1 := -W * 0.5 + W * (i + 1) / cols
			var z0 := 15.0 - 30.0 * j / rows
			var z1 := 15.0 - 30.0 * (j + 1) / rows
			# front face from ground at z=+15 rising; each row a step back and up
			var a := Vector3(x0, hgt.call(i, j) * float(j) / rows, z0)
			var b := Vector3(x1, hgt.call(i + 1, j) * float(j) / rows, z0)
			var c := Vector3(x1, hgt.call(i + 1, j + 1) * float(j + 1) / rows if j + 1 < rows else hgt.call(i + 1, j), z1)
			var d := Vector3(x0, hgt.call(i, j + 1) * float(j + 1) / rows if j + 1 < rows else hgt.call(i, j), z1)
			var ym := (c.y + d.y) * 0.5
			var col := Color(0.34, 0.35, 0.42).lerp(Color(0.86, 0.88, 0.95), smoothstep(46.0, 58.0, ym))
			col = col * (0.9 + 0.15 * h01(float(i), float(j), 21))
			_quad(st, a, b, c, d, Color(col.r, col.g, col.b))


func _brazier_tall() -> void:
	var I := Transform3D.IDENTITY
	prism("matte", I, Vector3.ZERO, 0.6, 0.5, 0.4, 8, STONE_D)
	prism("metal", I, Vector3(0, 0.4, 0), 0.14, 0.14, 2.0, 6, Color(0.16, 0.14, 0.13))
	prism("metal", I, Vector3(0, 2.4, 0), 0.25, 0.75, 0.5, 8, Color(0.2, 0.17, 0.15))
	prism("glow", I, Vector3(0, 2.8, 0), 0.62, 0.3, 0.35, 8, Color(1.0, 0.55, 0.18))
	prism("glow", I, Vector3(0, 3.1, 0), 0.35, 0.0, 0.7, 6, Color(1.0, 0.8, 0.4))


# ------------------------------------------------------------------ prologue_3min set pieces (S01-S07, S12, S13, S30)

func _quad2(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	var st := _st(key)
	_quad(st, a, b, c, d, col)
	_quad(st, d, c, b, a, col.darkened(0.15))


func _rainbow() -> void:
	var st := _st("shaft")
	var cols := [Color(1, 0.2, 0.2), Color(1, 0.6, 0.15), Color(1, 1, 0.3), Color(0.3, 1, 0.35), Color(0.3, 0.55, 1), Color(0.6, 0.3, 1)]
	var R := 16.0
	var bw := 0.55
	var seg := 28
	for b in cols.size():
		var r0 := R - b * bw
		var r1 := r0 - bw
		for i in seg:
			var a0 := PI * i / seg
			var a1 := PI * (i + 1) / seg
			var p00 := Vector3(cos(a0) * r0, sin(a0) * r0, 0)
			var p10 := Vector3(cos(a1) * r0, sin(a1) * r0, 0)
			var p01 := Vector3(cos(a0) * r1, sin(a0) * r1, 0)
			var p11 := Vector3(cos(a1) * r1, sin(a1) * r1, 0)
			var u0 := float(b) / cols.size()
			var u1 := float(b + 1) / cols.size()
			var v := 0.25 + 0.5 * absf(0.5 - float(i) / seg)
			var c: Color = cols[b]
			c.a = 0.6
			_tri(st, p00, p10, p11, c, Vector2(u0, v), Vector2(u0, v), Vector2(u1, v))
			_tri(st, p00, p11, p01, c, Vector2(u0, v), Vector2(u1, v), Vector2(u1, v))


## The Great Bridge: deck top at y=0 from z=0 to z=80 (placed at the city level), piers down 34 m to the clouds,
## a widened plaza at z=40 for the statue.
func _great_bridge() -> void:
	var I := Transform3D.IDENTITY
	var L := 80.0
	box("matte", I, Vector3(0, -0.8, L * 0.5), Vector3(4.6, 0.8, L * 0.5), STONE)
	box("matte", I, Vector3(0, -0.02, L * 0.5), Vector3(3.6, 0.04, L * 0.5), Color(0.5, 0.46, 0.41))
	box("matte", I, Vector3(0, -0.8, 40), Vector3(10.0, 0.8, 8.0), STONE)
	for sx in [-1.0, 1.0]:
		for seg in [[0.0, 32.0], [48.0, 80.0]]:
			var z0: float = seg[0]
			var z1: float = seg[1]
			box("matte", I, Vector3(sx * 4.4, 0.55, (z0 + z1) * 0.5), Vector3(0.3, 0.55, (z1 - z0) * 0.5), STONE_D)
		box("matte", I, Vector3(sx * 9.8, 0.55, 40), Vector3(0.3, 0.55, 8.0), STONE_D)
		for zz in [32.2, 47.8]:
			box("matte", I, Vector3(sx * 7.1, 0.55, zz), Vector3(2.8, 0.55, 0.3), STONE_D)
		for k in 10:
			var z := 4.0 + 8.0 * k
			if absf(z - 40.0) < 9.0:
				continue
			box("matte", I, Vector3(sx * 4.4, 1.5, z), Vector3(0.35, 0.4, 0.35), STONE)
			box("glow", I, Vector3(sx * 4.4, 2.1, z), Vector3(0.2, 0.22, 0.2), WARM)
	# piers and arches
	var piers := [8.0, 24.0, 40.0, 56.0, 72.0]
	for z: float in piers:
		var big := absf(z - 40.0) < 1.0
		var hw := 6.0 if big else 3.2
		var hd := 5.0 if big else 2.4
		box("matte", I, Vector3(0, -18.0, z), Vector3(hw, 16.4, hd), STONE_D)
		box("matte", I, Vector3(0, -2.2, z), Vector3(hw + 0.4, 0.6, hd + 0.4), STONE)
		prism("matte", I, Vector3(0, -36.0, z), hw + 2.0, hw, 3.0, 8, ROCK)
	for i in piers.size() - 1:
		var za: float = piers[i] + (5.0 if absf(piers[i] - 40.0) < 1.0 else 2.4)
		var zb: float = piers[i + 1] - (5.0 if absf(piers[i + 1] - 40.0) < 1.0 else 2.4)
		var n := 10
		for k in n:
			var t0 := float(k) / n
			var t1 := float(k + 1) / n
			var yb := -1.6 - 7.0 * (1.0 - sin(PI * (t0 + t1) * 0.5))
			box("matte", I, Vector3(0, (yb - 1.6) * 0.5, lerpf(za, zb, (t0 + t1) * 0.5)), Vector3(3.8, absf(yb + 1.6) * 0.5 + 0.4, (zb - za) / n * 0.5 + 0.02), STONE_D)


## The colossal hooded Master (moss-green stone), 30 m with its pedestal, facing +z.
func _statue() -> void:
	var I := Transform3D.IDENTITY
	var MOSS := Color(0.34, 0.44, 0.30)
	var BRONZE := Color(0.40, 0.46, 0.38)
	box("matte", I, Vector3(0, 1.5, 0), Vector3(4.2, 1.5, 4.2), STONE_D)
	box("matte", I, Vector3(0, 3.2, 0), Vector3(3.8, 0.2, 3.8), STONE)
	prism("matte", I, Vector3(0, 3.4, 0), 3.6, 2.1, 14.0, 12, BRONZE, false, 1.0, 3)
	for k in 5:
		prism("matte", I, Vector3(0, 3.4 + k * 2.8, 0), 3.62 - k * 0.3, 3.5 - k * 0.3, 0.5, 12, MOSS, false)
	prism("matte", I, Vector3(0, 17.4, 0), 2.1, 2.8, 2.2, 12, BRONZE)
	prism("matte", I, Vector3(0, 19.6, 0), 2.8, 1.5, 1.0, 12, MOSS)
	prism("matte", I, Vector3(0, 20.4, -0.2), 1.7, 1.35, 3.4, 10, BRONZE)
	prism("matte", Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 23.8, -0.2)), Vector3.ZERO, 1.35, 0.0, 2.2, 10, MOSS)
	box("matte", I, Vector3(0, 22.0, 1.05), Vector3(0.75, 1.1, 0.35), Color(0.08, 0.08, 0.09))
	prism("matte", Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 21.2, 1.2)), Vector3.ZERO, 0.7, 0.0, 3.2, 8, Color(0.7, 0.7, 0.62))
	box("matte", Transform3D(Basis(Vector3.BACK, -0.5), Vector3(2.7, 18.0, 0.8)), Vector3.ZERO, Vector3(0.6, 2.0, 0.6), BRONZE)
	prism("matte", I, Vector3(3.6, 3.4, 1.2), 0.3, 0.25, 26.0, 8, Color(0.3, 0.26, 0.2))
	prism("glow", I, Vector3(3.6, 29.4, 1.2), 0.0, 0.8, 1.0, 6, Color(0.6, 1.0, 0.7))
	prism("glow", I, Vector3(3.6, 30.4, 1.2), 0.8, 0.0, 1.2, 6, Color(0.7, 1.0, 0.8))
	box("matte", Transform3D(Basis(Vector3.RIGHT, -1.1), Vector3(-2.2, 16.8, 1.6)), Vector3.ZERO, Vector3(0.6, 2.2, 0.6), BRONZE)
	box("matte", I, Vector3(-2.2, 16.1, 3.6), Vector3(0.9, 0.25, 0.8), MOSS)
	for k in 14:
		var a := TAU * h01(float(k), 1.0, 8)
		var y := 4.0 + 14.0 * h01(float(k), 2.0, 8)
		var r := 3.6 - (y - 3.4) * 0.107
		box("matte", Transform3D(Basis(Vector3.UP, a), Vector3.ZERO), Vector3(0, y, r + 0.05), Vector3(0.5, 1.2, 0.12), Color(0.26, 0.40, 0.18))


func _offerings() -> void:
	var I := Transform3D.IDENTITY
	var fl := [Color(0.95, 0.85, 0.3), Color(0.95, 0.4, 0.3), Color(0.9, 0.9, 0.95), Color(0.75, 0.45, 0.9), Color(0.45, 0.7, 1.0)]
	for k in 70:
		var a := PI * (0.1 + 0.8 * h01(float(k), 0.5, 4))
		var d := 4.6 + 2.2 * h01(float(k), 1.5, 4)
		var p := Vector3(cos(a) * d, 0.12, sin(a) * d)
		box("matte", I, p, Vector3(0.14, 0.12, 0.14), fl[k % fl.size()])
	for k in 9:
		var a := PI * (0.15 + 0.7 * k / 8.0)
		box("glow", I, Vector3(cos(a) * 4.5, 0.25, sin(a) * 4.5), Vector3(0.06, 0.25, 0.06), Color(1.0, 0.8, 0.45))


## Ribbed dome with an oculus: rim at y=0 (radius 8.6), crown at +6.8. Double-sided panels (seen from inside).
func _dome(ruin: bool) -> void:
	var R := 8.6
	var H := 6.8
	var ribs := 16
	var steps := 7
	var tmax := acos(2.4 / R) / (PI * 0.5)
	var pt := func(i: int, j: int) -> Vector3:
		var t := tmax * float(j) / steps
		var a := TAU * float(i) / ribs
		var r := R * cos(t * PI * 0.5)
		return Vector3(sin(a) * r, H * sin(t * PI * 0.5), cos(a) * r)
	var DOME := Color(0.30, 0.52, 0.48) if not ruin else Color(0.30, 0.38, 0.30)
	for i in ribs:
		for j in steps:
			if ruin and (h01(float(i), float(j), 31) > 0.55 or (i >= 3 and i <= 7 and j >= 2)):
				continue
			var tone := DOME * (0.9 + 0.12 * h01(float(i), float(j), 2))
			_quad2("matte", pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1), Color(tone.r, tone.g, tone.b))
	for i in ribs:
		var jmax := steps
		if ruin and i % 3 == 1:
			jmax = 3
		for j in jmax:
			var a: Vector3 = pt.call(i, j)
			var b: Vector3 = pt.call(i, j + 1)
			var mid := (a + b) * 0.5
			var up := (b - a).normalized()
			var out := Vector3(mid.x, 0, mid.z).normalized()
			var side := up.cross(out).normalized()
			var bs := Basis(side, up, side.cross(up))
			box("metal" if not ruin else "matte", Transform3D(bs, mid + out * 0.1), Vector3.ZERO, Vector3(0.16, a.distance_to(b) * 0.5 + 0.05, 0.2), GOLD if not ruin else Color(0.36, 0.33, 0.25))
	prism("metal" if not ruin else "matte", Transform3D.IDENTITY, Vector3(0, -0.3, 0), R + 0.4, R + 0.4, 0.5, 32, GOLD if not ruin else STONE_D, false)
	if not ruin:
		prism("metal", Transform3D.IDENTITY, Vector3(0, H * sin(tmax * PI * 0.5) - 0.1, 0), 2.6, 2.6, 0.35, 16, GOLD, false)


## The brass orrery (about 7 m across): a sun, three tilted rings, four apprentice flames on arms.
func _orrery(ruin: bool) -> void:
	var I := Transform3D.IDENTITY
	var BRASS := GOLD if not ruin else Color(0.35, 0.36, 0.26)
	var mk := "metal" if not ruin else "matte"
	prism("matte", I, Vector3.ZERO, 1.4, 1.1, 1.0, 12, STONE_D)
	prism(mk, I, Vector3(0, 1.0, 0), 0.22, 0.18, 2.6, 8, BRASS)
	var sun := Vector3(0, 3.8, 0)
	var sk := "glow" if not ruin else "matte"
	prism(sk, I, sun + Vector3(0, -0.7, 0), 0.0, 0.75, 0.7, 10, WARM if not ruin else Color(0.3, 0.28, 0.2))
	prism(sk, I, sun, 0.75, 0.0, 0.7, 10, Color(1.0, 0.85, 0.5) if not ruin else Color(0.3, 0.28, 0.2))
	var tilts := [0.25, -0.45, 0.7]
	var radii := [1.8, 2.6, 3.4]
	for k in 3:
		var tl: float = tilts[k]
		var bs := Basis(Vector3.RIGHT, tl if not ruin else tl + 0.6) * Basis(Vector3.BACK, 0.2 * k)
		var n := 28
		for i in n:
			var a := TAU * (i + 0.5) / n
			var r: float = radii[k]
			if ruin and k == 2 and i > 18:
				continue
			box(mk, Transform3D(bs * Basis(Vector3.UP, a), sun), Vector3(0, 0, r), Vector3(r * PI / n + 0.02, 0.05, 0.07), BRASS)
	var fc := [Color(1.0, 0.3, 0.1), Color(0.7, 0.3, 1.0), Color(0.3, 0.6, 1.0), Color(0.35, 1.0, 0.35)]
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		var r := 3.0
		var tip := sun + Vector3(sin(a) * r, 0.4 * (k % 2) - 0.2, cos(a) * r)
		var mid := (sun + tip) * 0.5
		box(mk, Transform3D(Basis(Vector3.UP, a), mid), Vector3.ZERO, Vector3(0.04, 0.04, r * 0.5), BRASS)
		var fk: Color = fc[k]
		if ruin:
			prism("matte", I, tip + Vector3(0, -0.12, 0), 0.12, 0.12, 0.12, 6, Color(0.15, 0.15, 0.14))
		else:
			prism("glow", I, tip, 0.0, 0.2, 0.25, 6, fk)
			prism("glow", I, tip + Vector3(0, 0.25, 0), 0.2, 0.0, 0.45, 6, fk.lightened(0.3))


## Wall panel for interiors: 3.4 m long along local z, 0.8 m thick, 9 m tall; a glowing (stained) window when col.a > 0.
func _panel(col: Color, broken: bool) -> void:
	var I := Transform3D.IDENTITY
	if broken:
		for k in 4:
			var h := 2.0 + 5.5 * h01(float(k), 3.0, 41)
			var tone := STONE_D.lerp(Color(0.3, 0.38, 0.24), 0.35 * h01(float(k), 4.0, 41))
			box("matte", I, Vector3(0, h * 0.5, -1.275 + 0.85 * k), Vector3(0.4, h * 0.5, 0.43), tone)
		box("matte", I, Vector3(0, 0.25, 0), Vector3(0.55, 0.25, 1.72), Color(0.28, 0.36, 0.22))
		return
	box("matte", I, Vector3(0, 4.5, 0), Vector3(0.4, 4.5, 1.72), STONE)
	box("matte", I, Vector3(0, 0.3, 0), Vector3(0.52, 0.3, 1.72), STONE_D)
	box("matte", I, Vector3(0, 8.8, 0), Vector3(0.55, 0.2, 1.74), STONE_D)
	box("matte", I, Vector3(0, 4.5, 1.55), Vector3(0.62, 4.5, 0.3), STONE_D)
	if col.a > 0.0:
		box("glow", I, Vector3(0, 4.9, -0.1), Vector3(0.44, 2.4, 0.62), col)
		box("glow", I, Vector3(0, 7.5, -0.1), Vector3(0.44, 0.2, 0.4), col)
		box("metal", I, Vector3(0, 4.9, -0.1), Vector3(0.46, 0.05, 0.64), Color(0.1, 0.1, 0.1))


func _throne_seat() -> void:
	var I := Transform3D.IDENTITY
	for k in 3:
		box("matte", I, Vector3(0, 0.2 + k * 0.4, -0.3 * k), Vector3(3.6 - k * 0.8, 0.2, 2.8 - k * 0.6), STONE_D if k % 2 == 0 else STONE)
	box("matte", I, Vector3(0, 1.4, 0), Vector3(3.2, 0.03, 2.4), VIOLET)
	var y0 := 1.2
	box("matte", I, Vector3(0, y0 + 0.5, -0.6), Vector3(0.9, 0.5, 0.7), STONE)
	box("matte", I, Vector3(0, y0 + 1.04, -0.55), Vector3(0.75, 0.06, 0.6), VIOLET)
	box("matte", I, Vector3(0, y0 + 3.0, -1.3), Vector3(1.0, 3.0, 0.2), STONE)
	box("metal", I, Vector3(0, y0 + 3.0, -1.12), Vector3(0.8, 2.6, 0.03), GOLD)
	box("matte", I, Vector3(0, y0 + 3.0, -1.1), Vector3(0.62, 2.35, 0.03), VIOLET)
	for sx in [-1.0, 1.0]:
		box("matte", I, Vector3(sx * 0.95, y0 + 1.3, -0.5), Vector3(0.15, 0.3, 0.7), STONE)
		prism("metal", I, Vector3(sx * 1.0, y0 + 6.0, -1.3), 0.14, 0.0, 1.0, 6, GOLD)
	prism("glow", I, Vector3(0, y0 + 6.1, -1.3), 0.0, 0.35, 0.35, 6, Color(0.9, 0.75, 1.0))
	prism("glow", I, Vector3(0, y0 + 6.45, -1.3), 0.35, 0.0, 0.6, 6, Color(0.95, 0.9, 1.0))


func _column() -> void:
	var I := Transform3D.IDENTITY
	box("matte", I, Vector3(0, 0.3, 0), Vector3(0.8, 0.3, 0.8), STONE_D)
	prism("matte", I, Vector3(0, 0.6, 0), 0.55, 0.48, 7.8, 12, STONE, false)
	box("matte", I, Vector3(0, 8.6, 0), Vector3(0.8, 0.2, 0.8), STONE_D)
	prism("metal", I, Vector3(0, 8.1, 0), 0.5, 0.62, 0.3, 12, GOLD, false)


## A fake light shaft falling from a window (source at the origin) down and forward (+z), plus a floor pool.
func _shaft(col: Color) -> void:
	var st := _st("shaft")
	var a0 := Vector3(0, 0, 0)
	var a1 := Vector3(0, -7.4, 8.0)
	for plane in 2:
		var s0 := Vector3(0.75, 0, 0) if plane == 0 else Vector3(0, 0.75, 0)
		var s1 := Vector3(1.3, 0, 0) if plane == 0 else Vector3(0, 1.1, -0.9)
		_tri(st, a0 - s0, a0 + s0, a1 + s1, col, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
		_tri(st, a0 - s0, a1 + s1, a1 - s1, col, Vector2(0, 0), Vector2(1, 1), Vector2(0, 1))
	var fc := Color(col.r, col.g, col.b, 0.7)
	var c := a1 + Vector3(0, 0.03, 0)
	_tri(st, c + Vector3(-1.4, 0, -1.6), c + Vector3(1.4, 0, -1.6), c + Vector3(1.4, 0, 1.6), fc, Vector2(0, 0.3), Vector2(1, 0.3), Vector2(1, 0.3))
	_tri(st, c + Vector3(-1.4, 0, -1.6), c + Vector3(1.4, 0, 1.6), c + Vector3(-1.4, 0, 1.6), fc, Vector2(0, 0.3), Vector2(1, 0.3), Vector2(0, 0.3))


func _belfry() -> void:
	var I := Transform3D.IDENTITY
	box("matte", I, Vector3(0, 3.0, 0), Vector3(2.6, 3.0, 2.6), STONE)
	box("matte", I, Vector3(0, 6.1, 0), Vector3(2.8, 0.2, 2.8), STONE_D)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			box("matte", I, Vector3(sx * 2.2, 8.6, sz * 2.2), Vector3(0.45, 2.4, 0.45), STONE)
	box("matte", I, Vector3(0, 11.3, 0), Vector3(2.8, 0.35, 2.8), STONE_D)
	prism("matte", Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3.ZERO), Vector3(0, 11.6, 0), 4.1, 0.0, 4.2, 4, SLATE)
	prism("metal", I, Vector3(0, 15.6, 0), 0.12, 0.0, 1.4, 6, GOLD)
	box("matte", I, Vector3(0, 10.6, 0), Vector3(2.0, 0.15, 0.15), WOOD)
	prism("metal", I, Vector3(0, 8.6, 0), 1.35, 0.55, 1.9, 14, GOLD)
	prism("metal", I, Vector3(0, 10.5, 0), 0.55, 0.2, 0.2, 10, GOLD)
	box("glow", I, Vector3(0, 3.6, 2.62), Vector3(0.4, 0.7, 0.04), WARM)


## Hanging-garden vines: a curtain 8 m wide hanging from y=0 down, facing +z.
func _vines() -> void:
	var I := Transform3D.IDENTITY
	var greens := [Color(0.20, 0.40, 0.16), Color(0.28, 0.48, 0.18), Color(0.16, 0.32, 0.14)]
	box("matte", I, Vector3(0, 0.3, -0.2), Vector3(4.2, 0.35, 0.6), Color(0.22, 0.38, 0.16))
	for k in 22:
		var x := -4.0 + 8.0 * (k + 0.5) / 22.0
		var L := 2.0 + 6.5 * h01(float(k), 1.0, 51)
		var g: Color = greens[k % 3]
		box("matte", I, Vector3(x, -L * 0.5, 0.25 + 0.2 * h01(float(k), 2.0, 51)), Vector3(0.2, L * 0.5, 0.12), g)
		if h01(float(k), 3.0, 51) > 0.5:
			box("matte", I, Vector3(x, -L * (0.3 + 0.5 * h01(float(k), 4.0, 51)), 0.42), Vector3(0.12, 0.12, 0.05), Color(0.95, 0.75, 0.85))


func _garden() -> void:
	var I := Transform3D.IDENTITY
	box("matte", I, Vector3(0, 0.4, 0), Vector3(3.2, 0.4, 1.6), STONE_D)
	box("matte", I, Vector3(0, 0.95, 0), Vector3(2.9, 0.2, 1.35), Color(0.24, 0.42, 0.18))
	for k in 3:
		var x := -2.0 + 2.0 * k
		prism("matte", I, Vector3(x, 1.1, 0), 0.14, 0.1, 1.6, 6, WOOD)
		prism("matte", I, Vector3(x, 2.4, 0), 0.4, 1.1, 0.8, 8, Color(0.26, 0.46, 0.2))
		prism("matte", I, Vector3(x, 3.2, 0), 1.1, 0.2, 1.2, 8, Color(0.30, 0.52, 0.22))
		for f in 4:
			box("matte", I, Vector3(x + 0.6 * (f - 1.5), 1.2, 1.2), Vector3(0.12, 0.1, 0.12), Color(0.95, 0.6, 0.7) if f % 2 == 0 else Color(0.95, 0.9, 0.5))


func _cloud() -> void:
	var I := Transform3D.IDENTITY
	for k in 9:
		var p := Vector3((h01(float(k), 1.0, 61) - 0.5) * 22.0, 1.0 + 3.0 * h01(float(k), 2.0, 61), (h01(float(k), 3.0, 61) - 0.5) * 14.0)
		var r := 4.0 + 4.0 * h01(float(k), 4.0, 61)
		var top := Color(0.98, 0.95, 0.96)
		var under := Color(0.80, 0.74, 0.86)
		prism("matte", I, p, r * 0.75, r, r * 0.3, 12, under, false)
		prism("matte", I, p + Vector3(0, r * 0.3, 0), r, r * 0.55, r * 0.45, 12, top, false)
		prism("matte", I, p + Vector3(0, r * 0.75, 0), r * 0.55, 0.0, r * 0.35, 12, top)
		prism("matte", I, p + Vector3(0, -0.01, 0), 0.0, r * 0.75, 0.01, 12, under, false)


func _ring(r: float, w: float) -> void:
	var st := _st("matte")
	var n := 96
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var ri := r - w * 0.5
		var ro := r + w * 0.5
		var tone := Color(0.52, 0.48, 0.43) * (0.9 + 0.15 * h01(float(i), 0.0, 71))
		_quad(st, Vector3(sin(a0) * ro, 0.06, cos(a0) * ro), Vector3(sin(a1) * ro, 0.06, cos(a1) * ro),
			Vector3(sin(a1) * ri, 0.06, cos(a1) * ri), Vector3(sin(a0) * ri, 0.06, cos(a0) * ri), Color(tone.r, tone.g, tone.b))


func _disc(r: float, col: Color) -> void:
	var st := _st("matte")
	var n := 40
	for k in 4:
		var ra := r * k / 4.0
		var rb := r * (k + 1) / 4.0
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var tone := col * (0.88 + 0.16 * h01(float(i), float(k), 72))
			_quad(st, Vector3(sin(a0) * rb, 0.04, cos(a0) * rb), Vector3(sin(a1) * rb, 0.04, cos(a1) * rb),
				Vector3(sin(a1) * ra, 0.04, cos(a1) * ra), Vector3(sin(a0) * ra, 0.04, cos(a0) * ra), Color(tone.r, tone.g, tone.b))


func _figure(xf: Transform3D, cloak: Color, h: float, crown: bool) -> void:
	prism("matte", xf, Vector3.ZERO, 0.34, 0.22, h * 0.72, 7, cloak)
	prism("matte", xf, Vector3(0, h * 0.72, 0), 0.22, 0.26, 0.12, 7, cloak.darkened(0.15))
	prism("matte", xf, Vector3(0, h * 0.72 + 0.12, 0), 0.13, 0.12, 0.24, 6, Color(0.8, 0.62, 0.5))
	if crown:
		prism("metal", xf, Vector3(0, h * 0.72 + 0.36, 0), 0.15, 0.17, 0.12, 6, GOLD)


func _feast() -> void:
	var I := Transform3D.IDENTITY
	box("matte", I, Vector3(0, 0.85, 0), Vector3(7.0, 0.07, 0.8), WOOD)
	box("matte", I, Vector3(0, 0.8, 0), Vector3(7.02, 0.02, 0.84), Color(0.85, 0.8, 0.68))
	for sx in [-6.4, 0.0, 6.4]:
		box("matte", I, Vector3(sx, 0.4, 0), Vector3(0.12, 0.4, 0.6), WOOD)
	for sz in [-1.4, 1.4]:
		box("matte", I, Vector3(0, 0.45, sz), Vector3(6.8, 0.06, 0.25), WOOD)
	for k in 12:
		box("metal", I, Vector3(-6.2 + 1.13 * k, 1.02, 0.3 * (k % 2 * 2 - 1)), Vector3(0.06, 0.1, 0.06), GOLD)
		box("matte", I, Vector3(-5.9 + 1.13 * k, 0.97, -0.25 * (k % 2 * 2 - 1)), Vector3(0.18, 0.06, 0.12), Color(0.65, 0.45, 0.25))
	for k in 4:
		box("glow", I, Vector3(-5.0 + 3.3 * k, 1.25, 0), Vector3(0.05, 0.2, 0.05), Color(1.0, 0.8, 0.45))
	var kings := [Color(0.75, 0.18, 0.1), Color(0.4, 0.2, 0.55), Color(0.45, 0.65, 0.9), Color(0.25, 0.5, 0.2)]
	for k in 4:
		var x := -4.5 + 3.0 * k
		var z := 1.4 if k % 2 == 0 else -1.4
		_figure(Transform3D(Basis(Vector3.UP, 0.0 if z < 0 else PI), Vector3(x, 0.0, z)), kings[k], 1.75, true)
	var folk := [Color(0.5, 0.44, 0.36), Color(0.3, 0.3, 0.42), Color(0.45, 0.25, 0.2)]
	for k in 6:
		var x := -6.0 + 2.4 * k
		var z := -1.4 if k % 2 == 0 else 1.4
		_figure(Transform3D(Basis(Vector3.UP, 0.0 if z < 0 else PI), Vector3(x, 0.0, z)), folk[k % 3], 1.6, false)


## The Master stand-in (B6 will replace it): 3.2 m, hooded, a beard of white-gold light, his hem burning in 4 colours.
func _master() -> void:
	var I := Transform3D.IDENTITY
	var ROBE := Color(0.26, 0.2, 0.36)
	prism("matte", I, Vector3(0, 0.12, 0), 0.85, 0.42, 2.3, 12, ROBE)
	var hem := [Color(1.0, 0.3, 0.1), Color(0.7, 0.3, 1.0), Color(0.3, 0.6, 1.0), Color(0.35, 1.0, 0.35)]
	var n := 16
	var st := _st("glow")
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var c: Color = hem[i * 4 / n]
		var r0 := 0.9
		var r1 := 0.86
		_quad(st, Vector3(sin(a0) * r0, 0.0, cos(a0) * r0), Vector3(sin(a1) * r0, 0.0, cos(a1) * r0), Vector3(sin(a1) * r1, 0.16, cos(a1) * r1), Vector3(sin(a0) * r1, 0.16, cos(a0) * r1), c)
	prism("matte", I, Vector3(0, 2.42, 0), 0.42, 0.56, 0.25, 12, ROBE.darkened(0.1))
	prism("matte", I, Vector3(0, 2.67, 0), 0.56, 0.3, 0.2, 12, ROBE)
	prism("matte", I, Vector3(0, 2.8, -0.05), 0.32, 0.28, 0.42, 10, ROBE.darkened(0.15))
	prism("matte", Transform3D(Basis(Vector3.RIGHT, -0.35), Vector3(0, 3.2, -0.08)), Vector3.ZERO, 0.28, 0.0, 0.34, 10, ROBE.darkened(0.15))
	box("matte", I, Vector3(0, 2.98, 0.2), Vector3(0.16, 0.16, 0.08), Color(0.03, 0.03, 0.04))
	prism("glow", Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 2.86, 0.26)), Vector3.ZERO, 0.17, 0.0, 0.75, 8, Color(1.0, 0.9, 0.6))
	for sx in [-1.0, 1.0]:
		box("matte", Transform3D(Basis(Vector3.RIGHT, -0.9), Vector3(sx * 0.5, 2.25, 0.3)), Vector3.ZERO, Vector3(0.16, 0.42, 0.16), ROBE)
	box("matte", I, Vector3(0.5, 1.95, 0.62), Vector3(0.12, 0.04, 0.14), Color(0.8, 0.66, 0.55))
	prism("matte", I, Vector3(-0.62, 0.0, 0.25), 0.05, 0.04, 3.5, 6, Color(0.28, 0.22, 0.16))
	prism("glow", I, Vector3(-0.62, 3.5, 0.25), 0.0, 0.14, 0.14, 6, Color(0.95, 0.85, 1.0))
	prism("glow", I, Vector3(-0.62, 3.64, 0.25), 0.14, 0.0, 0.2, 6, Color(0.95, 0.85, 1.0))


func _swordsman() -> void:
	var I := Transform3D.IDENTITY
	var DARK := Color(0.12, 0.12, 0.14)
	prism("matte", I, Vector3.ZERO, 0.4, 0.26, 1.35, 8, DARK)
	prism("matte", I, Vector3(0, 1.35, 0), 0.26, 0.34, 0.14, 8, DARK)
	prism("matte", I, Vector3(0, 1.49, 0), 0.13, 0.12, 0.26, 6, Color(0.2, 0.17, 0.15))
	prism("metal", Transform3D(Basis(Vector3.BACK, 0.35), Vector3(0.38, 0.85, -0.1)), Vector3.ZERO, 0.03, 0.02, 1.1, 4, Color(0.6, 0.62, 0.66))
	box("metal", I, Vector3(0.2, 1.0, -0.1), Vector3(0.12, 0.02, 0.02), Color(0.4, 0.35, 0.25))


func _candle() -> void:
	var I := Transform3D.IDENTITY
	prism("metal", I, Vector3.ZERO, 0.14, 0.1, 0.04, 8, Color(0.3, 0.26, 0.2))
	prism("matte", I, Vector3(0, 0.04, 0), 0.035, 0.03, 0.2, 8, Color(0.9, 0.86, 0.75))
	prism("glow", I, Vector3(0, 0.25, 0), 0.0, 0.025, 0.03, 6, Color(1.0, 0.75, 0.35))
	prism("glow", I, Vector3(0, 0.28, 0), 0.025, 0.0, 0.07, 6, Color(1.0, 0.85, 0.5))


func _moss() -> void:
	var st := _st("matte")
	for k in 26:
		var p := Vector3((h01(float(k), 1.0, 81) - 0.5) * 12.0, 0.03 + 0.002 * k, (h01(float(k), 2.0, 81) - 0.5) * 12.0)
		var r := 0.6 + 1.2 * h01(float(k), 3.0, 81)
		var c := Color(0.24, 0.36, 0.16) * (0.85 + 0.3 * h01(float(k), 4.0, 81))
		for i in 7:
			var a0 := TAU * i / 7.0
			var a1 := TAU * (i + 1) / 7.0
			_tri(st, p, p + Vector3(sin(a0), 0, cos(a0)) * r, p + Vector3(sin(a1), 0, cos(a1)) * r, Color(c.r, c.g, c.b))
		for j in 4:
			box("matte", Transform3D.IDENTITY, p + Vector3((h01(float(k), 5.0 + j, 81) - 0.5) * r, 0.1, (h01(float(k), 6.0 + j, 81) - 0.5) * r), Vector3(0.18, 0.1, 0.18), Color(0.2, 0.34, 0.14))
	for k in 10:
		var p := Vector3((h01(float(k), 7.0, 81) - 0.5) * 10.0, 0.0, (h01(float(k), 8.0, 81) - 0.5) * 10.0)
		box("matte", Transform3D(Basis(Vector3.UP, h01(float(k), 9.0, 81) * 3.0), p), Vector3(0, 0.25, 0), Vector3(0.5 + 0.4 * h01(float(k), 10.0, 81), 0.25, 0.4), STONE_D)


## Distant army camps: 40 fires in a 60 m field + a few tents (seen from far away: glowing dots).
func _fires() -> void:
	var I := Transform3D.IDENTITY
	for k in 40:
		var p := Vector3((h01(float(k), 1.0, 91) - 0.5) * 60.0, 0.6, (h01(float(k), 2.0, 91) - 0.5) * 30.0)
		box("glow", I, p, Vector3(0.6, 0.6, 0.6), Color(1.0, 0.5 + 0.2 * h01(float(k), 3.0, 91), 0.15))
	for k in 16:
		var p := Vector3((h01(float(k), 4.0, 91) - 0.5) * 60.0, 0.0, (h01(float(k), 5.0, 91) - 0.5) * 30.0)
		prism("matte", I, p, 1.6, 0.0, 2.2, 4, Color(0.3, 0.26, 0.22))
