extends SceneTree
## Task 12b.V5 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/marsh/marsh_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 9000 -- mode=stage
## mode=stage (default): the painted ground (biome zones, no river), one full 3 x 3 m marsh patch in the west glade,
##   lineups of every mesh (3 variants each, found with the shader's own variant hash) on a strip of mud, the lighting
##   rig and the game camera (pitch 55). Saves docs/art/screens/12b_v5_contact.png (2 x 2 close-ups: puddles, rushes,
##   cattails, reeds), 12b_v5_lineup_z40.png, 12b_v5_stage_z40.png, 12b_v5_stage_z12.png.
## mode=map: the real skirmish map (bot off, fog off, HUD hidden, MapDressingArt as in the game), the 4 marsh patches
##   of terrain.md 4.2 scattered from marsh_set.gd ENTRIES: 12b_v5_patch_z40.png (Reed Ford, both marshes; also saved
##   as terrain_marsh.png), 12b_v5_mirror_z40.png (Willow Ford), 12b_v5_patch_z25.png, 12b_v5_close_z12.png.
## The dark mud under the decor is a PREVIEW STAND-IN for the 12b.V1 ground layer (terrain.md 7.1 marsh: mud
## (0.24, 0.18, 0.11), puddle tint, pock marks), built here from the same 0.5 m cell mask; the game draws it in
## ground.gdshader. The mask follows terrain.md 4.1 / 4.2 (ellipse + point-symmetric 1.0 m noisy edge; water, fords,
## roads and the 3 m riverbank band come first): MarshMask below, shared with tests/test_12b_v5.gd.
## nodecor=1: same shots without the marsh decor (cost baseline, nothing saved).

const SET_PATH := "res://art/environment/biomes/marsh/marsh_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const SHOT_DIR := "res://docs/art/screens/"
const PATCH_SIZE := 5        ## instances per cluster (the marsh is small: riverbank-sized clumps)
const PATCH_SPREAD := 0.8    ## gaussian sigma of a cluster, metres
## terrain.md 4.2 marsh patches, player half; the mirror (-x, -z) of each is a patch too.
const PATCHES: Array[Vector4] = [Vector4(-14.5, -33.0, 3.0, 3.0), Vector4(-2.5, -35.0, 3.0, 3.0)]
const CELL := 0.5
const RIVERBANK := 3.0       ## terrain.md 2: riverbank = land within 3.0 m of deep water (priority over mud)

var _mode := "stage"
var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _entries: Array = []
var _gp: GDScript
var _river: Dictionary = {}
var _roads: Array[Vector4] = []   # (x0, z0, x1, z1)
var _road_half := 1.5
var _noise := FastNoiseLite.new()
var _mud := {}                    # Vector2i cell -> true
var _edge := {}                   # Vector2i cell -> true
var _patches: Array[Vector4] = []
var _count := 0
var _no_decor := false
var _stage: Node3D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			_mode = arg.substr(5)
		elif arg == "nodecor=1":
			_no_decor = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_entries = (load(SET_PATH) as GDScript).get_script_constant_map()["ENTRIES"]
	_gp = load(GP_PATH) as GDScript
	_rng.seed = 12205
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.45
	_noise.seed = 5
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


# ---------------------------------------------------------------- the mask (terrain.md 4.1 stand-in)

## Point-symmetric edge noise in [-0.5, 0.5] m (terrain.md 4.1: 0.5 x (n(p) + n(-p))).
func _edge_noise(p: Vector2) -> float:
	return 0.5 * (_noise.get_noise_2d(p.x, p.y) + _noise.get_noise_2d(-p.x, -p.y)) * 0.5


func _in_patch(p: Vector2) -> bool:
	for pt: Vector4 in _patches:
		var q := Vector2((p.x - pt.x) / pt.z, (p.y - pt.y) / pt.w)
		var d: float = (q.length() - 1.0) * minf(pt.z, pt.w)
		if d + _edge_noise(p) < 0.0:
			return true
	return false


## Cells taken by something of higher priority than mud (water, ford, road, riverbank).
func _higher(p: Vector2) -> bool:
	if not _river.is_empty():
		var wd: float = _gp.call(&"water_distance", _river, p)
		if wd < RIVERBANK or _gp.call(&"in_ford", _river, p):
			return true
	for r: Vector4 in _roads:
		var c: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2(r.x, r.y), Vector2(r.z, r.w))
		if p.distance_to(c) < _road_half:
			return true
	return false


func _build_mask() -> void:
	_mud.clear()
	_edge.clear()
	for pt: Vector4 in _patches:
		var lo := Vector2i(floori((pt.x - pt.z - 1.5 + 60.0) / CELL), floori((pt.y - pt.w - 1.5 + 60.0) / CELL))
		var hi := Vector2i(ceili((pt.x + pt.z + 1.5 + 60.0) / CELL), ceili((pt.y + pt.w + 1.5 + 60.0) / CELL))
		for i: int in range(lo.x, hi.x):
			for j: int in range(lo.y, hi.y):
				var p := Vector2(-60.0 + (i + 0.5) * CELL, -60.0 + (j + 0.5) * CELL)
				if _in_patch(p) and not _higher(p):
					_mud[Vector2i(i, j)] = true
	# marsh_edge: the one-cell ring of land cells round the mud (not water / ford / road; riverbank is fine).
	for c: Vector2i in _mud:
		for dx: int in [-1, 0, 1]:
			for dz: int in [-1, 0, 1]:
				var n := c + Vector2i(dx, dz)
				if _mud.has(n) or _edge.has(n):
					continue
				var p := Vector2(-60.0 + (n.x + 0.5) * CELL, -60.0 + (n.y + 0.5) * CELL)
				if _is_land_not_road(p):
					_edge[n] = true
	print("marsh mask: %d mud cells (%.1f m2), %d edge cells (%.1f m2)" % [_mud.size(), _mud.size() * CELL * CELL,
		_edge.size(), _edge.size() * CELL * CELL])


func _is_land_not_road(p: Vector2) -> bool:
	if not _river.is_empty():
		if float(_gp.call(&"water_distance", _river, p)) < 0.3 or _gp.call(&"in_ford", _river, p):
			return false
	for r: Vector4 in _roads:
		var c: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2(r.x, r.y), Vector2(r.z, r.w))
		if p.distance_to(c) < _road_half:
			return false
	return true


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x + 60.0) / CELL), floori((p.y + 60.0) / CELL))


func _zone_ok(p: Vector2, place: StringName) -> bool:
	return _mud.has(_cell(p)) if place == &"marsh" else _edge.has(_cell(p))


# ---------------------------------------------------------------- the mud stand-in (12b.V1 draws it in the game)

## The mask sampled like the GPU samples a linear-filtered 0.5 m texture (texel centres at the cell centres).
func _mask_bilinear(p: Vector2) -> float:
	var g: Vector2 = (p + Vector2(60.0, 60.0)) / CELL - Vector2(0.5, 0.5)
	var i0 := Vector2i(floori(g.x), floori(g.y))
	var f: Vector2 = g - Vector2(i0)
	var v00: float = 1.0 if _mud.has(i0) else 0.0
	var v10: float = 1.0 if _mud.has(i0 + Vector2i(1, 0)) else 0.0
	var v01: float = 1.0 if _mud.has(i0 + Vector2i(0, 1)) else 0.0
	var v11: float = 1.0 if _mud.has(i0 + Vector2i(1, 1)) else 0.0
	return lerpf(lerpf(v00, v10, f.x), lerpf(v01, v11, f.x), f.y)


func _build_mud(parent: Node3D) -> void:
	if _mud.is_empty():
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c: Vector2i in _mud:
		var p := Vector2(-60.0 + c.x * CELL, -60.0 + c.y * CELL)
		lo = lo.min(p)
		hi = hi.max(p + Vector2(CELL, CELL))
	lo -= Vector2(1.0, 1.0)
	hi += Vector2(1.0, 1.0)
	var step := 0.25
	var nx: int = ceili((hi.x - lo.x) / step)
	var nz: int = ceili((hi.y - lo.y) / step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in nx + 1:
		for j: int in nz + 1:
			var x: float = lo.x + i * step
			var z: float = lo.y + j * step
			var w: float = _mask_bilinear(Vector2(x, z))
			var a: float = smoothstep(0.15, 0.7, w + _noise.get_noise_2d(x * 3.0, z * 3.0) * 0.12)
			var tone: float = 0.5 + 0.5 * _noise.get_noise_2d(x * 2.1 + 40.0, z * 2.1)
			var col := Color(0.24, 0.18, 0.11).lerp(Color(0.30, 0.235, 0.145), smoothstep(0.35, 0.65, tone))
			st.set_color(Color(col.r, col.g, col.b, a))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x, 0.012, z))
	for i2: int in nx:
		for j2: int in nz:
			var a0: int = i2 * (nz + 1) + j2          # (x, z)
			var a1: int = (i2 + 1) * (nz + 1) + j2    # (x + 1, z)
			var a2: int = (i2 + 1) * (nz + 1) + j2 + 1
			var a3: int = i2 * (nz + 1) + j2 + 1
			# Up-facing (clockwise seen from above, Godot's front face).
			for k: int in [a0, a1, a2, a0, a2, a3]:
				st.add_index(k)
	var mi := MeshInstance3D.new()
	mi.name = "MudStandIn"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.render_priority = -2
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


# ---------------------------------------------------------------- scatter (the set file's rules)

func _scatter(parent: Node3D) -> void:
	if _no_decor:
		return
	var total := 0
	var per_mesh := {}   # path -> Array[Transform3D]
	var gap_pts := {}    # path -> Array[Vector2]
	for e: Dictionary in _entries:
		var path: String = e["mesh"]
		var place: StringName = e["place"]
		var gap: float = float(e.get("gap", 0.0))
		var cluster: float = float(e["cluster"])
		if not per_mesh.has(path):
			per_mesh[path] = []
			gap_pts[path] = []
		var list: Array = per_mesh[path]
		var pts: Array = gap_pts[path]
		for pt: Vector4 in _patches:
			var rect := Rect2(pt.x - pt.z - 1.5, pt.y - pt.w - 1.5, (pt.z + 1.5) * 2.0, (pt.w + 1.5) * 2.0)
			var n_full: float = float(e["per_100m2"]) * rect.get_area() / 100.0
			for i: int in _round_rand(n_full * (1.0 - cluster)):
				var p := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y,
					rect.end.y))
				_try(list, pts, p, place, gap, e)
			for k: int in _round_rand(n_full * cluster / float(PATCH_SIZE)):
				var pc := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y,
					rect.end.y))
				if not _zone_ok(pc, place):
					continue
				for j: int in PATCH_SIZE:
					for attempt: int in 3:
						var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, PATCH_SPREAD), _rng.randfn(0.0, PATCH_SPREAD))
						if _zone_ok(p2, place):
							_try(list, pts, p2, place, gap, e)
							break
	for path2: String in per_mesh:
		var xfs: Array = per_mesh[path2]
		var e2: Dictionary = {}
		for e3: Dictionary in _entries:
			if e3["mesh"] == path2:
				e2 = e3
				break
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = load(path2) as Mesh
		mm.instance_count = xfs.size()
		for i: int in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = path2.get_file().get_basename().to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(e2["range"])
		mmi.visibility_range_end_margin = 10.0
		parent.add_child(mmi)
		print("scatter %-14s %4d instances" % [mmi.name, xfs.size()])
		total += xfs.size()
	_count += total
	print("scatter total %d instances (%d patches, budget %d)" % [total, _patches.size(),
		int((load(SET_PATH) as GDScript).get_script_constant_map()["INSTANCE_BUDGET"])])


func _round_rand(x: float) -> int:
	var n: int = int(floor(x))
	return n + (1 if _rng.randf() < x - float(n) else 0)


func _try(list: Array, pts: Array, p: Vector2, place: StringName, gap: float, e: Dictionary) -> void:
	if not _zone_ok(p, place):
		return
	var sc: Vector2 = e["scale"]
	var s: float = _rng.randf_range(sc.x, sc.y)
	if gap > 0.0:
		# The film may spill onto grass or the riverbank band, never over water / ford / road cells (the river's own
		# film, the ruts).
		var reach: float = float((load(SET_PATH) as GDScript).get_script_constant_map()["PUDDLE_REACH"]) * s
		for a: int in 8:
			var q: Vector2 = p + Vector2(cos(a * TAU / 8.0), sin(a * TAU / 8.0)) * reach
			if not _is_land_not_road(q):
				return
		# water.gdshader draws rapids foam on the shared film within 0.5 m OUTSIDE a ford circle: keep clear.
		if not _river.is_empty():
			for f: Vector4 in PackedVector4Array(_river.get(&"fords", PackedVector4Array())):
				if f.z > 0.0 and p.distance_to(Vector2(f.x, f.y)) < f.z + 0.5 + reach:
					return
		for o: Vector2 in pts:
			if o.distance_to(p) < gap:
				return
		pts.append(p)
	var yaw: float = _rng.randf() * TAU
	list.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), Vector3(p.x, float(e.get("y", 0.0)), p.y)))


# ---------------------------------------------------------------- shots

func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40) -> Image:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	for i in frames:
		await process_frame
		if i >= frames - 20:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / 20.0
	await RenderingServer.frame_post_draw
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	print("shot %-14s draws=%d prims=%d gpu_ms=%.2f" % [shot, draws, prims, gpu])
	var img: Image = root.get_texture().get_image()
	if _no_decor or shot == "":
		return img
	img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v5_%s.png" % shot))
	return img


# ---------------------------------------------------------------- stage

const LINEUP_Z := 52.0
const STAGE_PATCH := Vector4(-24.0, 38.0, 3.0, 3.0)

## [mesh path, centre x, spacing, close-up zoom, focus z offset] per lineup group.
func _groups() -> Array:
	var c: Dictionary = (load(SET_PATH) as GDScript).get_script_constant_map()
	return [[c["PUDDLES"], -12.0, 3.0, 7.0, -0.2], [c["RUSHES"], -4.0, 1.6, 4.2, -0.35],
		[c["CATTAILS"], 2.5, 1.5, 4.6, -0.45], [c["REEDS"], 9.0, 1.7, 5.0, -0.45]]


func _run_stage() -> void:
	_stage = Node3D.new()
	_stage.name = "Stage"
	root.add_child(_stage)
	current_scene = _stage
	_stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	_gp.call(&"apply", gm, _gp.call(&"skirmish_biomes"))
	ground.material_override = gm
	_stage.add_child(ground)
	if ResourceLoader.exists("res://art/environment/map_dressing.tscn"):
		var md: Node = (load("res://art/environment/map_dressing.tscn") as PackedScene).instantiate()
		md.set_script(null)
		_stage.add_child(md)
	# One full patch in the glade, and a long mud strip under the lineups.
	_patches = [STAGE_PATCH]
	_build_mask()
	var decor := Node3D.new()
	decor.name = "Marsh"
	_stage.add_child(decor)
	_build_mud(decor)
	_scatter(decor)
	_patches = [Vector4(-1.5, LINEUP_Z, 13.5, 1.6)]
	_build_mask()
	_build_mud(_stage)
	_build_lineup()
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)
	_stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("stage_z40", 40.0, Vector3(STAGE_PATCH.x, 0, STAGE_PATCH.y))
	await _shoot("stage_z12", 12.0, Vector3(STAGE_PATCH.x, 0, STAGE_PATCH.y + 0.5))
	var quads: Array[Image] = []
	for g: Array in _groups():
		quads.append(await _shoot("", float(g[3]), Vector3(float(g[1]), 0.0, LINEUP_Z + float(g[4]))))
	var w: int = quads[0].get_width()
	var h: int = quads[0].get_height()
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i: int in quads.size():
		var q: Image = quads[i]
		q.convert(Image.FORMAT_RGBA8)
		q.resize(w / 2, h / 2, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(q, Rect2i(0, 0, w / 2, h / 2), Vector2i((i % 2) * (w / 2), (i / 2) * (h / 2)))
	for x: int in w:
		sheet.set_pixel(x, h / 2, Color(0.1, 0.1, 0.1))
	for y: int in h:
		sheet.set_pixel(w / 2, y, Color(0.1, 0.1, 0.1))
	sheet.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12b_v5_contact.png"))
	print("saved 12b_v5_contact.png")
	await _shoot("lineup_z40", 40.0, Vector3(-1.5, 0, LINEUP_Z - 3.0))
	await _ripple_check(Vector3(-12.0, 0, LINEUP_Z), 6.0)
	print("SHOTS DONE")
	quit()


## nature_painted.gdshader's hash1 (sine-free, so the CPU gets the variant the GPU draws).
static func _hash1(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d: float = p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)


static func variant_at(pos: Vector3) -> int:
	return mini(int(floor(_hash1(Vector2(pos.z, pos.x) + Vector2(3.1, 7.7)) * 3.0)), 2)


func _find_variant(pos: Vector3, variant: int) -> Vector3:
	for i in 400:
		var p: Vector3 = pos + Vector3(fmod(i * 0.173, 0.6) - 0.3, 0.0, fmod(i * 0.311, 0.6) - 0.3)
		if variant_at(p) == variant:
			return p
	return pos


func _build_lineup() -> void:
	for g: Array in _groups():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = load(String(g[0])) as Mesh
		mm.instance_count = 3
		for i in 3:
			var x: float = float(g[1]) + (i - 1) * float(g[2])
			var pos: Vector3 = _find_variant(Vector3(x, 0.0, LINEUP_Z), i)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, 0.4 + i * 1.7), pos))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stage.add_child(mmi)


## The film's ripples / caustics move (a breeze on the pool), the plants sway: pixels changing over 0.75 s.
func _ripple_check(focus: Vector3, zoom: float) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var a: Image = root.get_texture().get_image()
	for i in 45:
		await process_frame
	await RenderingServer.frame_post_draw
	var b: Image = root.get_texture().get_image()
	var changed := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.06:
				changed += 1
	print("motion check: %d of %d sampled pixels changed in 0.75 s" % [changed,
		(a.get_width() / 4) * (a.get_height() / 4)])


# ---------------------------------------------------------------- the real map

func _run_map() -> void:
	var main: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	for i in 10:
		await process_frame
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer and n.name != "Vignette":
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_rig = main.get(&"camera_rig")
	_rig.set(&"edge_pan_enabled", false)
	_river = _gp.call(&"skirmish_river")
	_read_roads(main)
	_patches.clear()
	for pt: Vector4 in PATCHES:
		_patches.append(pt)
		_patches.append(Vector4(-pt.x, -pt.y, pt.z, pt.w))
	_build_mask()
	var decor := Node3D.new()
	decor.name = "MarshPreview"
	main.add_child(decor)
	_build_mud(decor)
	_scatter(decor)
	await _shoot("patch_z40", 40.0, Vector3(-8.5, 0.0, -34.0))
	var img: Image = root.get_texture().get_image()
	if not _no_decor:
		img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "terrain_marsh.png"))
	await _shoot("mirror_z40", 40.0, Vector3(8.5, 0.0, 34.0))
	await _shoot("patch_z25", 25.0, Vector3(-9.0, 0.0, -33.5))
	await _shoot("close_z12", 12.0, Vector3(-15.0, 0.0, -32.5))
	print("SHOTS DONE")
	quit()


## Roads from the painted ground (road_segs: ring road 3 m) and the lane (5.2 m, outside r 11): terrain.md 4.1.
func _read_roads(level: Node) -> void:
	for mi: Node in level.find_children("*", "MeshInstance3D", true, false):
		var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == "res://art/environment/ground.gdshader" \
				and (mi as MeshInstance3D).mesh is PlaneMesh:
			var count: Variant = sm.get_shader_parameter(&"road_count")
			var segs: Variant = sm.get_shader_parameter(&"road_segs")
			if count is int and segs != null:
				var list: Array = Array(segs)
				for i: int in mini(int(count), list.size()):
					_roads.append(list[i])
			var la: Variant = sm.get_shader_parameter(&"lane_a")
			var lb: Variant = sm.get_shader_parameter(&"lane_b")
			if la is Vector2 and lb is Vector2:
				_roads.append(Vector4((la as Vector2).x, (la as Vector2).y, (lb as Vector2).x, (lb as Vector2).y))
			break
	print("roads read: %d segments" % _roads.size())
