extends SceneTree
## Task 12.V9 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/heath/heath_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000 -- mode=stage
## mode=stage (default): the painted ground with the Crown Hollow biome zones (no river), a heath patch on the west
##   flank scattered from heath_set.gd ENTRIES with the rules the set file documents (per_100m2 x heath weight,
##   cluster, scale, gap, yaw), the Fallen Colossus / Standing Stones landmarks when present, a dirt road, the warm
##   lighting rig and the game camera (pitch 55). Saves docs/art/screens/12_v9_patch_z40.png (+ biome_heath.png),
##   12_v9_patch_z25.png, 12_v9_close_z12.png, the contact sheet 12_v9_contact.png (2 x 2: every mesh with its 3
##   variants, close) and 12_v9_lineup_z40.png (the same lineup read from 40 m); prints render stats and a wind check.
## mode=map: the real skirmish map (bot off, fog off, HUD hidden), the heath scattered on both flanks (off the lane,
##   roads, slots, water, buildings, trees): 12_v9_map_west_z45.png, 12_v9_map_south_z45.png, 12_v9_map_z25.png.
## nodecor=1: same shots without the heath decor (cost baseline, nothing saved).

const SET_PATH := "res://art/environment/biomes/heath/heath_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const PATCH_SIZE := 8.0      ## instances per patch (the `cluster` part)
const PATCH_SPREAD := 1.2    ## gaussian sigma of a patch, metres
const SHOT_DIR := "res://docs/art/screens/"

var _mode := "stage"
var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _entries: Array = []
var _gp: GDScript
var _river: Dictionary = {}
var _edge := 59.6            ## decor stops at the map edge (the cliffs); the stage fills further for the look
# Map mode: what blocks decor.
var _lane_a := Vector2(1000, 1000)
var _lane_b := Vector2(1001, 1001)
var _spots: Array[Vector4] = []
var _roads: Array[Vector4] = []
var _avoid: Array[Vector3] = []
var _count := 0
var _no_decor := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			_mode = arg.substr(5)
		elif arg == "nodecor=1":
			_no_decor = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_entries = (load(SET_PATH) as GDScript).get_script_constant_map()["ENTRIES"]
	_gp = load(GP_PATH) as GDScript
	_rng.seed = 12009
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


# ---------------------------------------------------------------- scatter (the set file's rules)

func _zone_in(e: float, bl: float) -> float:
	return 1.0 - smoothstep(-bl, bl, e)


## Heath weight at q (ground.gdshader biome_weights without the paint jitter: ruins > riverbank > meadow > Old Wood >
## heath, blend over GroundParams.BLEND).
func heath_weight(q: Vector2) -> float:
	var consts: Dictionary = _gp.get_script_constant_map()
	var bl: float = float(consts["BLEND"]) * 0.5
	var ruin := 0.0
	for r: Vector4 in consts["RUINS"]:
		ruin = maxf(ruin, _zone_in(q.distance_to(Vector2(r.x, r.y)) - r.z, bl))
	var bank := 0.0
	if not _river.is_empty():
		var wd: float = _gp.call(&"water_distance", _river, q)
		if wd < 1e3:
			bank = _zone_in(wd - float(consts["BANK_REACH"]), bl)
	var hubs: Vector4 = consts["HUBS"]
	var meadow: float = _zone_in(minf(q.distance_to(Vector2(hubs.x, hubs.y)), q.distance_to(Vector2(hubs.z, hubs.w)))
		- float(consts["HUB_RADIUS"]), bl)
	var woods: Vector4 = consts["WOODS"]
	var wood: float = _zone_in(minf(q.distance_to(Vector2(woods.x, woods.y)), q.distance_to(Vector2(woods.z, woods.w)))
		- float(consts["WOOD_RADIUS"]), bl)
	var heath: float = 1.0 - _zone_in(maxf(absf(q.x), absf(q.y)) - float(consts["HEATH_EDGE"]), bl)
	var left: float = 1.0 - ruin
	bank *= left
	left -= bank
	meadow *= left
	left -= meadow
	wood *= left
	left -= wood
	return heath * left


func _weight(x: float, z: float, margin: float) -> float:
	var q := Vector2(x, z)
	var w: float = heath_weight(q)
	if w <= 0.01 or _blocked(q, margin):
		return 0.0
	return w


func _blocked(q: Vector2, margin: float) -> bool:
	if absf(q.x) > _edge or absf(q.y) > _edge:
		return true
	if not _river.is_empty():
		if float(_gp.call(&"water_distance", _river, q)) < 0.6 + margin:
			return true
	var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, _lane_a, _lane_b)
	if q.distance_to(c) < 5.2 + margin:
		return true
	for s: Vector4 in _spots:
		if q.distance_to(Vector2(s.x, s.y)) < s.z + 0.8 + margin:
			return true
	for r: Vector4 in _roads:
		var c2: Vector2 = Geometry2D.get_closest_point_to_segment(q, Vector2(r.x, r.y), Vector2(r.z, r.w))
		if q.distance_to(c2) < 2.3 + margin:
			return true
	for a: Vector3 in _avoid:
		if q.distance_to(Vector2(a.x, a.y)) < a.z + margin:
			return true
	return false


func _scatter(parent: Node3D, rect: Rect2) -> void:
	if _no_decor:
		return
	var lo: Vector2 = rect.position
	var hi: Vector2 = rect.end
	var total := 0
	for e: Dictionary in _entries:
		var mesh := load(String(e["mesh"])) as Mesh
		var sc: Vector2 = e["scale"]
		var gap: float = float(e.get("gap", 0.0))
		var big: bool = gap > 0.0
		var margin: float = gap * 0.5 if big else 0.25
		var n_full: float = float(e["per_100m2"]) * rect.get_area() / 100.0
		var cluster: float = e["cluster"]
		var xfs: Array[Transform3D] = []
		for i: int in int(round(n_full * (1.0 - cluster))):
			var p := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
			if _rng.randf() < _weight(p.x, p.y, margin) and _gap_ok(xfs, p, gap):
				xfs.append(_xf(p, sc, e))
		var patches: int = int(round(n_full * cluster / PATCH_SIZE))
		for k: int in patches:
			var pc := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
			if _rng.randf() >= _weight(pc.x, pc.y, margin):
				continue
			for j: int in int(PATCH_SIZE):
				var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, PATCH_SPREAD), _rng.randfn(0.0, PATCH_SPREAD)) \
					* (2.0 if big else 1.0)
				if _rng.randf() < _weight(p2.x, p2.y, margin) and _gap_ok(xfs, p2, gap):
					xfs.append(_xf(p2, sc, e))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for i: int in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(e["mesh"]).get_file().get_basename().to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(e["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(e["range"])
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mmi)
		print("scatter %-22s %4d instances (%.1f / 100 m2 at full weight)" % [mmi.name, xfs.size(),
			float(e["per_100m2"])])
		total += xfs.size()
	_count += total
	print("scatter total %d instances" % total)


func _gap_ok(xfs: Array[Transform3D], p: Vector2, gap: float) -> bool:
	if gap <= 0.0:
		return true
	for xf: Transform3D in xfs:
		if Vector2(xf.origin.x, xf.origin.z).distance_to(p) < gap:
			return false
	return true


func _xf(p: Vector2, sc: Vector2, e: Dictionary) -> Transform3D:
	var s: float = _rng.randf_range(sc.x, sc.y)
	var yaw: float = _rng.randf() * TAU
	if e.has("yaw"):
		var j: float = float(e.get("yaw_jitter", 0.0))
		yaw = float(e["yaw"]) + _rng.randf_range(-j, j)
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), Vector3(p.x, 0.0, p.y))


# ---------------------------------------------------------------- shots

func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40, also: String = "") -> Image:
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
	img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12_v9_%s.png" % shot))
	if also != "":
		img.save_png(ProjectSettings.globalize_path(SHOT_DIR + "%s.png" % also))
	return img


func _wind_check(focus: Vector3, zoom: float) -> void:
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
	print("wind check: %d of %d sampled pixels changed in 0.75 s" % [changed, (a.get_width() / 4) * (a.get_height() / 4)])


# ---------------------------------------------------------------- stage

func _run_stage() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
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
	var road := Vector4(-78.0, 9.0, -30.0, -6.0)
	var segs := PackedVector4Array()
	segs.resize(16)
	segs[0] = road
	gm.set_shader_parameter(&"road_segs", segs)
	gm.set_shader_parameter(&"road_count", 1)
	_gp.call(&"apply", gm, _gp.call(&"skirmish_biomes"))
	ground.material_override = gm
	stage.add_child(ground)
	_roads.append(road)
	var lm: Array = [["res://art/environment/landmarks/colossus.tscn", Vector3(-57.0, 0.0, -16.0), 4.2],
		["res://art/environment/landmarks/standing_stones.tscn", Vector3(-54.0, 0.0, 20.0), 4.2]]
	for l: Array in lm:
		if ResourceLoader.exists(l[0]):
			var n: Node3D = (load(l[0]) as PackedScene).instantiate() as Node3D
			stage.add_child(n)
			n.position = l[1]
			_avoid.append(Vector3((l[1] as Vector3).x, (l[1] as Vector3).z, float(l[2])))
	# The map-edge cliffs and plateau (the scene without its scatter script) frame the heath like in the game.
	if ResourceLoader.exists("res://art/environment/map_dressing.tscn"):
		var md: Node = (load("res://art/environment/map_dressing.tscn") as PackedScene).instantiate()
		md.set_script(null)
		stage.add_child(md)
	_edge = 59.6
	var patch := Node3D.new()
	patch.name = "Heath"
	stage.add_child(patch)
	_scatter(patch, Rect2(Vector2(-60.0, -60.0), Vector2(46.0, 88.0)))
	_scatter(patch, Rect2(Vector2(-14.0, -60.0), Vector2(40.0, 16.0)))
	_build_lineup(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)   # closer than the game allows, for the lineup close-ups only
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("patch_z40", 40.0, Vector3(-4, 0, -40), 40, "biome_heath")
	await _shoot("west_z40", 40.0, Vector3(-44, 0, 2))
	await _shoot("patch_z25", 25.0, Vector3(-2, 0, -44))
	await _shoot("close_z12", 12.0, Vector3(-4, 0, -49))
	# Contact sheet: one close shot per mesh (3 variants each), stitched 2 x 2.
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
	for x: int in w:   # thin separators
		sheet.set_pixel(x, h / 2, Color(0.1, 0.1, 0.1))
	for y: int in h:
		sheet.set_pixel(w / 2, y, Color(0.1, 0.1, 0.1))
	sheet.save_png(ProjectSettings.globalize_path(SHOT_DIR + "12_v9_contact.png"))
	print("saved 12_v9_contact.png")
	await _shoot("lineup_z40", 40.0, Vector3(1.0, 0, LINEUP_Z - 3.0))
	await _wind_check(Vector3(-9.0, 0, LINEUP_Z), 6.0)
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


const LINEUP_Z := 52.0   ## on the south heath band (no river in the stage)


## [mesh, centre x, spacing, close-up zoom, focus z offset] per lineup group.
func _groups() -> Array:
	return [["heath_tall_grass", -9.0, 1.3, 4.0, -0.4], ["heath_heather", -3.2, 1.55, 4.5, -0.45],
		["heath_gorse", 4.0, 2.4, 6.0, -0.4], ["heath_lichen_stones", 11.2, 2.4, 6.0, -0.5]]


## Every mesh with its 3 variants side by side along x at LINEUP_Z (variants found with the shader's own hash).
func _build_lineup(stage: Node3D) -> void:
	for g: Array in _groups():
		var mesh := load("res://art/environment/biomes/heath/%s.res" % g[0]) as Mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 3
		for i in 3:
			var x: float = float(g[1]) + (i - 1) * float(g[2])
			var pos: Vector3 = _find_variant(Vector3(x, 0.0, LINEUP_Z), i)
			var yaw: float = -0.6435 if g[0] == "heath_tall_grass" else 0.4 + i * 1.7
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), pos))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stage.add_child(mmi)


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
	_read_map(main)
	_river = _gp.call(&"skirmish_river")
	_edge = 59.6
	var patch := Node3D.new()
	patch.name = "HeathPreview"
	main.add_child(patch)
	_scatter(patch, Rect2(Vector2(-60.0, -60.0), Vector2(120.0, 120.0)))
	print("heath instances on the map: %d (budget %d)" % [_count,
		int((load(SET_PATH) as GDScript).get_script_constant_map()["INSTANCE_BUDGET"])])
	await _shoot("map_west_z45", 45.0, Vector3(-48.0, 0.0, 2.0))
	await _shoot("map_south_z45", 45.0, Vector3(0.0, 0.0, 48.0))
	await _shoot("map_z25", 25.0, Vector3(-50.0, 0.0, 8.0))
	print("SHOTS DONE")
	quit()


## The same obstacles MapDressingArt reads: lane / spots / roads from the painted ground, trees and props from
## EnvProps, crystal nodes, buildings, landmarks (their decor-free radius), capture points and camps.
func _read_map(level: Node) -> void:
	for mi: Node in level.find_children("*", "MeshInstance3D", true, false):
		var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == "res://art/environment/ground.gdshader" \
				and (mi as MeshInstance3D).mesh is PlaneMesh:
			var la: Variant = sm.get_shader_parameter(&"lane_a")
			var lb: Variant = sm.get_shader_parameter(&"lane_b")
			if la is Vector2 and lb is Vector2:
				_lane_a = la
				_lane_b = lb
			for i: int in 4:
				var s: Variant = sm.get_shader_parameter(StringName("spot_%d" % i))
				if s is Vector4 and (s as Vector4).z > 0.0:
					_spots.append(s)
			var count: Variant = sm.get_shader_parameter(&"road_count")
			var segs: Variant = sm.get_shader_parameter(&"road_segs")
			if count is int and segs != null:
				var list: Array = Array(segs)
				for i: int in mini(int(count), list.size()):
					_roads.append(list[i])
			break
	var env: Node = level.get(&"env_props") if &"env_props" in level else null
	if env:
		for c: Node in env.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null or mmi.multimesh == null:
				continue
			for i: int in mmi.multimesh.instance_count:
				var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
				_avoid.append(Vector3(xf.origin.x, xf.origin.z, 1.1 * xf.basis.get_scale().x))
	for grp: StringName in [&"crystal_nodes", &"capture_points", &"taverns", &"trade_posts"]:
		for n: Node in root.get_tree().get_nodes_in_group(grp):
			if n is Node3D:
				var p: Vector3 = (n as Node3D).global_position
				_avoid.append(Vector3(p.x, p.z, 3.0))
	for b: Node in root.get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D:
			var pb: Vector3 = (b as Node3D).global_position
			var r: float = float(b.call(&"target_radius")) + 1.0 if b.has_method(&"target_radius") else 4.0
			_avoid.append(Vector3(pb.x, pb.z, r))
	for n2: Node in level.find_children("*", "Node3D", true, false):
		if n2.has_meta(&"decor_clear_radius"):
			var p2: Vector3 = (n2 as Node3D).global_position
			_avoid.append(Vector3(p2.x, p2.z, float(n2.get_meta(&"decor_clear_radius"))))
