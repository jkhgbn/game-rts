extends SceneTree
## Task 12.V8 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/meadow/meadow_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000 -- mode=stage
## mode=stage (default): a meadow patch (r 20 m + 4 m blend) scattered from meadow_set.gd ENTRIES with the rules the
##   set file documents (per_100m2, cluster, scale), a dirt road through it and a hovel for scale, the warm lighting
##   rig, the game camera (pitch 55). Saves docs/art/screens/meadow_game_z45.png (+ biome_meadow.png),
##   meadow_game_z30.png, meadow_close_z12.png, meadow_lineup_small.png / meadow_lineup_big.png (every mesh, its 3
##   variants side by side) and meadow_lineup_z40.png (the 40 m read); prints render stats and a wind check.
## mode=map: the real skirmish map (bot off, fog off, HUD hidden), the meadow scattered around both hubs (22 m + the
##   4 m blend, off the base paving, lane, roads, buildings, trees): meadow_map_z45.png, meadow_map_z25.png.

const SET_PATH := "res://art/environment/biomes/meadow/meadow_set.gd"
const HUBS: Array[Vector2] = [Vector2(-36.0, 36.0), Vector2(36.0, -36.0)]
const MEADOW_R := 22.0
const BLEND := 4.0
const PATCH_SIZE := 8.0      ## instances per patch (the `cluster` part)
const PATCH_SPREAD := 1.2    ## gaussian sigma of a patch, metres

var _mode := "stage"
var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _entries: Array = []
# Map mode: what blocks decor.
var _lane_a := Vector2(1000, 1000)
var _lane_b := Vector2(1001, 1001)
var _spots: Array[Vector4] = []
var _roads: Array[Vector4] = []
var _avoid: Array[Vector3] = []
var _centres: Array[Vector2] = []
var _core_r := MEADOW_R
var _count := 0
var _no_decor := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			_mode = arg.substr(5)
		elif arg == "nodecor=1":   # cost baseline: same shots without the meadow
			_no_decor = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_entries = (load(SET_PATH) as GDScript).get_script_constant_map()["ENTRIES"]
	_rng.seed = 12008
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


# ---------------------------------------------------------------- scatter (the set file's rules)

## Meadow weight at (x, z): 1 inside the core radius, fading to 0 over the blend ring; 0 where decor is blocked.
func _weight(x: float, z: float, margin: float) -> float:
	var q := Vector2(x, z)
	var d: float = INF
	for c: Vector2 in _centres:
		d = minf(d, q.distance_to(c))
	var w: float = clampf(1.0 - (d - _core_r) / BLEND, 0.0, 1.0)
	if w <= 0.0 or _blocked(q, margin):
		return 0.0
	return w


func _blocked(q: Vector2, margin: float) -> bool:
	if absf(q.x) > 59.6 or absf(q.y) > 59.6:
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


func _scatter(parent: Node3D) -> void:
	if _no_decor:
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c: Vector2 in _centres:
		lo = lo.min(c - Vector2.ONE * (_core_r + BLEND))
		hi = hi.max(c + Vector2.ONE * (_core_r + BLEND))
	var rect := Rect2(lo, hi - lo)
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
		# Even part: uniform tries, kept with probability = weight.
		for i: int in int(round(n_full * (1.0 - cluster))):
			var p := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
			if _rng.randf() < _weight(p.x, p.y, margin) and _gap_ok(xfs, p, gap):
				xfs.append(_xf(p, sc))
		# Patches: centres kept with probability = weight, then gaussian points around them.
		var patches: int = int(round(n_full * cluster / PATCH_SIZE))
		for k: int in patches:
			var pc := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
			if _rng.randf() >= _weight(pc.x, pc.y, margin):
				continue
			for j: int in int(PATCH_SIZE):
				var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, PATCH_SPREAD), _rng.randfn(0.0, PATCH_SPREAD)) * (2.0 if big else 1.0)
				if _rng.randf() < _weight(p2.x, p2.y, margin) and _gap_ok(xfs, p2, gap):
					xfs.append(_xf(p2, sc))
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


func _xf(p: Vector2, sc: Vector2) -> Transform3D:
	var s: float = _rng.randf_range(sc.x, sc.y)
	return Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(p.x, 0.0, p.y))


# ---------------------------------------------------------------- shots

func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40, also: String = "") -> void:
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
	if _no_decor:
		return
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/meadow_%s.png" % shot))
	if also != "":
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/%s.png" % also))


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
	plane.size = Vector2(160, 160)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	var road := Vector4(-40.0, 9.0, 40.0, -3.0)
	var segs := PackedVector4Array()
	segs.resize(16)
	segs[0] = road
	gm.set_shader_parameter(&"road_segs", segs)
	gm.set_shader_parameter(&"road_count", 1)
	ground.material_override = gm
	stage.add_child(ground)
	_roads.append(road)
	var hovel_pos := Vector3(-9.0, 0.0, -8.0)
	if ResourceLoader.exists("res://art/buildings/hovel.tscn"):
		var hv: Node3D = (load("res://art/buildings/hovel.tscn") as PackedScene).instantiate() as Node3D
		stage.add_child(hv)
		hv.position = hovel_pos
		_avoid.append(Vector3(hovel_pos.x, hovel_pos.z, 3.6))
	_centres = [Vector2.ZERO]
	_core_r = 20.0
	var patch := Node3D.new()
	patch.name = "Meadow"
	stage.add_child(patch)
	_scatter(patch)
	_build_lineup(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)   # closer than the game allows, for the lineup close-ups only
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("game_z45", 45.0, Vector3(0, 0, 3), 40, "biome_meadow")
	await _shoot("game_z30", 30.0, Vector3(4, 0, 6))
	await _shoot("close_z12", 12.0, Vector3(6, 0, 8))
	await _shoot("lineup_small", 12.0, Vector3(0, 0, -43.5))
	await _shoot("lineup_grass", 7.0, Vector3(-3.9, 0, -44.0))
	await _shoot("lineup_flowers", 7.0, Vector3(3.9, 0, -44.0))
	await _shoot("lineup_big", 11.0, Vector3(0, 0, -38.0))
	await _shoot("lineup_z40", 40.0, Vector3(0, 0, -40.0))
	await _wind_check(Vector3(-3.9, 0, -44.0), 7.0)
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


## Every mesh with its 3 variants side by side: small pieces at z -44.5, hay and bushes at z -39.
func _build_lineup(stage: Node3D) -> void:
	var small: Array[String] = ["meadow_tufts", "meadow_clover", "meadow_daisies", "meadow_dandelions"]
	var bigs: Array[String] = ["meadow_fruit_bush", "meadow_hay"]
	var rows: Array = [[small, -44.5, 1.1, 3.9], [bigs, -39.0, 2.6, 8.8]]
	for r: Array in rows:
		var names: Array[String] = r[0]
		for k in names.size():
			var mesh := load("res://art/environment/biomes/meadow/%s.res" % names[k]) as Mesh
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mesh
			mm.instance_count = 3
			for i in 3:
				var x: float = (k - (names.size() - 1) * 0.5) * float(r[3]) + (i - 1) * float(r[2])
				var pos: Vector3 = _find_variant(Vector3(x, 0.0, float(r[1])), i)
				mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, 0.4 + i * 1.7), pos))
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			if names[k] != "meadow_hay":
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
	_centres = HUBS
	_core_r = MEADOW_R
	var patch := Node3D.new()
	patch.name = "MeadowPreview"
	main.add_child(patch)
	_scatter(patch)
	await _shoot("map_z45", 45.0, Vector3(-33.0, 0.0, 33.0))
	await _shoot("map_z25", 25.0, Vector3(-27.0, 0.0, 30.0))
	await _shoot("map_mirror_z45", 45.0, Vector3(33.0, 0.0, -33.0))
	print("SHOTS DONE")
	quit()


## The same obstacles MapDressingArt reads: lane / spots / roads from the painted ground, trees and props from
## EnvProps, crystal nodes, buildings.
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
	for n: Node in root.get_tree().get_nodes_in_group(&"crystal_nodes"):
		if n is Node3D:
			var p: Vector3 = (n as Node3D).global_position
			_avoid.append(Vector3(p.x, p.z, 2.3))
	for b: Node in root.get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D:
			var pb: Vector3 = (b as Node3D).global_position
			var r: float = float(b.call(&"target_radius")) + 1.0 if b.has_method(&"target_radius") else 4.0
			_avoid.append(Vector3(pb.x, pb.z, r))
