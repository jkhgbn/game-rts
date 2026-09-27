extends SceneTree
## Task 12.V10 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/old_wood/old_wood_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000 -- mode=stage
## mode=stage (default): an Old Wood patch at the real wood centre (-50, -50) (so the 12.V2 ground draws its Old Wood
##   tint), scattered from old_wood_set.gd items() with the rules the set documents (density, cluster, gap, scale),
##   a few pines / firs for context, the lighting rig and the game camera (pitch 55). Saves docs/art/screens/
##   12_v10_patch_z40.png (+ biome_old_wood.png), 12_v10_patch_z25.png, 12_v10_close_z12.png, the contact sheet
##   12_v10_contact.png (every mesh, its 3 variants side by side), 12_v10_contact_close_*.png and 12_v10_contact_z40.png.
## Add `nodecor=1` for a cost baseline (same shots without the set, nothing saved).
## mode=map: the real skirmish map (bot off, fog off, HUD hidden) with both Old Woods scattered (clear of roads, the
##   lane, spots, buildings, trees, crystal nodes and the riverbank): 12_v10_map_z40.png, 12_v10_map_z25.png,
##   12_v10_map_mirror_z40.png.

const SET_PATH := "res://art/environment/biomes/old_wood/old_wood_set.gd"
const WOODS: Array[Vector2] = [Vector2(-50.0, -50.0), Vector2(50.0, 50.0)]
const WOOD_R := 28.0
const BLEND := 4.0
const PATCH_SIZE := 8.0
const PATCH_SPREAD := 1.2
const SHOT_PREFIX := "res://docs/art/screens/12_v10_"

var _mode := "stage"
var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _items: Array = []
var _lane_a := Vector2(1000, 1000)
var _lane_b := Vector2(1001, 1001)
var _spots: Array[Vector4] = []
var _roads: Array[Vector4] = []
var _avoid: Array[Vector3] = []
var _centres: Array[Vector2] = []
var _river: Dictionary = {}
var _gp: GDScript
var _no_decor := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("mode="):
			_mode = arg.substr(5)
		elif arg == "nodecor=1":   # cost baseline: same shots without the Old Wood set, nothing saved
			_no_decor = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_items = (load(SET_PATH) as GDScript).call(&"items")
	_gp = load("res://art/environment/ground_params.gd") as GDScript
	_rng.seed = 12010
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


# ---------------------------------------------------------------- scatter (the set file's rules)

func _weight(x: float, z: float, margin: float) -> float:
	var q := Vector2(x, z)
	var d: float = INF
	for c: Vector2 in _centres:
		d = minf(d, q.distance_to(c))
	var w: float = clampf(1.0 - (d - WOOD_R) / BLEND, 0.0, 1.0)
	if w <= 0.0 or _blocked(q, margin):
		return 0.0
	return w


func _blocked(q: Vector2, margin: float) -> bool:
	if absf(q.x) > 59.6 or absf(q.y) > 59.6:
		return true
	if not _river.is_empty() and float(_gp.call(&"water_distance", _river, q)) < 6.0:
		return true   # riverbank biome wins over the Old Wood (ground_params order)
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
		lo = lo.min(c - Vector2.ONE * (WOOD_R + BLEND))
		hi = hi.max(c + Vector2.ONE * (WOOD_R + BLEND))
	lo = lo.max(Vector2(-60, -60))
	hi = hi.min(Vector2(60, 60))
	var rect := Rect2(lo, hi - lo)
	var total := 0
	for it: Dictionary in _items:
		var mesh: Mesh = it["mesh"]
		var sc: Vector2 = it["scale"]
		var gap: float = it["gap"]
		var big: bool = gap > 0.0
		var margin: float = gap * 0.5 if big else 0.25
		var n_full: float = float(it["density"]) * rect.get_area() / 100.0
		var cluster: float = it["cluster"]
		var xfs: Array[Transform3D] = []
		for i: int in int(round(n_full * (1.0 - cluster))):
			var p := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
			if _rng.randf() < _weight(p.x, p.y, margin) and _gap_ok(xfs, p, gap):
				xfs.append(_xf(p, sc))
		var patches: int = int(round(n_full * cluster / PATCH_SIZE))
		for k: int in patches:
			var pc := Vector2(_rng.randf_range(lo.x, hi.x), _rng.randf_range(lo.y, hi.y))
			if _rng.randf() >= _weight(pc.x, pc.y, margin):
				continue
			for j: int in int(PATCH_SIZE):
				var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, PATCH_SPREAD), _rng.randfn(0.0, PATCH_SPREAD)) \
					* (2.0 if big else 1.0)
				if _rng.randf() < _weight(p2.x, p2.y, margin) and _gap_ok(xfs, p2, gap):
					xfs.append(_xf(p2, sc))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for i: int in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(it["id"]).to_pascal_case()
		mmi.multimesh = mm
		mmi.material_override = it["material"]   # the 12.V6 contract allows it: same as the mesh's own material
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(it["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(it["vis_end"])
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mmi)
		print("scatter %-14s %4d instances (%.1f / 100 m2 at full weight)" % [mmi.name, xfs.size(), float(it["density"])])
		total += xfs.size()
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
	print("shot %-18s draws=%d prims=%d gpu_ms=%.2f" % [shot, draws, prims, gpu])
	if _no_decor:
		return
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(SHOT_PREFIX + shot + ".png"))
	if also != "":
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/%s.png" % also))


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


# ---------------------------------------------------------------- stage

const STAGE_C := Vector3(-47.0, 0.0, -47.0)
const LINEUP_Z := -18.0   # the contact sheet rows sit south of the patch, on plain ground

func _run_stage() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(130, 130)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	ground.position = Vector3(-10, 0, -10)
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	var road := Vector4(-62.0, -30.0, -30.0, -36.0)
	var segs := PackedVector4Array()
	segs.resize(16)
	segs[0] = road
	gm.set_shader_parameter(&"road_segs", segs)
	gm.set_shader_parameter(&"road_count", 1)
	var bio: Dictionary = _gp.call(&"skirmish_biomes")
	bio[&"biome_woods"] = Vector4(-50, -50, -8, -12)   # 2nd wood under the contact sheet: Old Wood ground there too
	_gp.call(&"apply", gm, bio)
	ground.material_override = gm
	stage.add_child(ground)
	_roads.append(road)
	# A few forest trees (the Old Wood's own tree clusters are real trees with colliders, placed by 12.C1).
	var trees: Array = [["tree_pine", [Vector3(-54, 0, -44), Vector3(-41, 0, -55), Vector3(-44, 0, -41.5)]],
		["tree_fir", [Vector3(-51, 0, -52), Vector3(-38, 0, -46), Vector3(-56.5, 0, -50)]],
		["tree_broadleaf", [Vector3(-47, 0, -38.5)]]]
	for tr: Array in trees:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = load("res://art/environment/meshes/%s.res" % tr[0]) as Mesh
		var pts: Array = tr[1]
		mm.instance_count = pts.size()
		for i: int in pts.size():
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, i * 1.9).scaled(Vector3.ONE * (1.05 + 0.1 * i)),
				pts[i]))
			_avoid.append(Vector3((pts[i] as Vector3).x, (pts[i] as Vector3).z, 1.1))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		stage.add_child(mmi)
	var hovel_pos := Vector3(-36.0, 0.0, -36.0)
	if ResourceLoader.exists("res://art/buildings/hovel.tscn"):
		var hv: Node3D = (load("res://art/buildings/hovel.tscn") as PackedScene).instantiate() as Node3D
		stage.add_child(hv)
		hv.position = hovel_pos
		_avoid.append(Vector3(hovel_pos.x, hovel_pos.z, 3.6))
	_centres = [Vector2(-50, -50)]
	var patch := Node3D.new()
	patch.name = "OldWood"
	stage.add_child(patch)
	_scatter(patch)
	_build_lineup(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("patch_z40", 40.0, STAGE_C, 40, "biome_old_wood")
	await _shoot("patch_z25", 25.0, STAGE_C + Vector3(-2, 0, 1))
	await _shoot("close_z12", 12.0, STAGE_C + Vector3(-3, 0, 2))
	await _shoot("contact", 17.0, Vector3(-8.0, 0, LINEUP_Z + 4.0))
	await _shoot("contact_close_ferns", 6.5, Vector3(-14.0, 0, LINEUP_Z + 0.4))
	await _shoot("contact_close_glowcaps", 5.0, Vector3(-7.6, 0, LINEUP_Z + 0.3))
	await _shoot("contact_close_cobwebs", 5.0, Vector3(-2.0, 0, LINEUP_Z + 0.4))
	await _shoot("contact_close_roots", 8.0, Vector3(-13.5, 0, LINEUP_Z + 4.2))
	await _shoot("contact_close_boulders", 8.0, Vector3(-5.5, 0, LINEUP_Z + 4.2))
	await _shoot("contact_close_trunks", 12.0, Vector3(-8.5, 0, LINEUP_Z + 8.0))
	await _shoot("contact_z40", 40.0, Vector3(-8.0, 0, LINEUP_Z + 4.0))
	print("SHOTS DONE")
	quit()


## The contact sheet: every mesh with its 3 variants side by side (x positions per mesh; row z offsets from
## LINEUP_Z). Trunks lie along x.
func _build_lineup(stage: Node3D) -> void:
	var layout: Array = [
		["ow_ferns", [-16.0, -14.0, -12.0], 0.0],
		["ow_glowcaps", [-9.0, -7.6, -6.2], 0.0],
		["ow_cobwebs", [-3.5, -2.0, -0.5], 0.0],
		["ow_roots", [-16.2, -13.5, -10.8], 4.0],
		["ow_moss_boulders", [-8.3, -5.5, -2.7], 4.0],
		["ow_fallen_trunk", [-14.0, -8.5, -3.0], 8.0],
	]
	for l: Array in layout:
		var name: String = l[0]
		var xs: Array = l[1]
		var mesh := load("res://art/environment/biomes/old_wood/%s.res" % name) as Mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 3
		for i in 3:
			var pos: Vector3 = _find_variant(Vector3(float(xs[i]), 0.0, LINEUP_Z + float(l[2])), i)
			var yaw: float = 0.4 + i * 1.7 if name != "ow_fallen_trunk" else 0.15
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), pos))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if name in ["ow_moss_boulders",
			"ow_fallen_trunk"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	var river_on: Variant = main.get(&"river_enabled")
	if river_on == null or bool(river_on):
		_river = _gp.call(&"skirmish_river")
	_centres = WOODS
	var patch := Node3D.new()
	patch.name = "OldWoodPreview"
	main.add_child(patch)
	_scatter(patch)
	await _shoot("map_z40", 40.0, Vector3(-46.0, 0.0, -46.0))
	await _shoot("map_z25", 25.0, Vector3(-48.0, 0.0, -44.0))
	await _shoot("map_mirror_z40", 40.0, Vector3(46.0, 0.0, 46.0))
	print("SHOTS DONE")
	quit()


## The same obstacles MapDressingArt reads: lane / spots / roads from the painted ground, trees and props from
## EnvProps, crystal nodes, buildings (as meadow_preview.gd).
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
