extends SceneTree
## Task A2.8 screenshots (trees, rocks, ruin pillars). Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/nature_props/nature_preview.gd
##       --resolution 1600x900 --quit-after 9000 -- tag=after
## Saves docs/art/screens/a28_<tag>_<shot>.png and prints the render stats of every shot (draw calls,
## primitives, fps), so before / after can be compared for cost too.
## `mode=map` (default): the real skirmish map (bot off, fog of war off, HUD hidden) from the game camera
## (pitch 55, fov 50): whole-map overview + forest / rocks / pillars / map edge close-ups.
## `mode=lineup`: every prop mesh in rows on the painted ground (4 instances each, so the per-instance
## variants show), warm lighting rig, game camera angle. `only=<shot>,<shot>` limits the shots.

const MESH_DIR := "res://art/environment/meshes/"
const LINEUP_TREES: Array[String] = ["tree_pine", "tree_fir", "tree_broadleaf", "tree_birch", "tree_gold"]
const LINEUP_ROCKS: Array[String] = ["rock_boulder", "rock_slab", "rock_shards", "rock_spire", "ruin_pillar"]
const LINEUP_FAR: Array[String] = ["tree_pine_far", "tree_fir_far", "tree_broadleaf_far", "tree_birch_far",
	"tree_gold_far"]

var main: Node
var _tag := "shot"
var _mode := "map"
var _only := ""
var _rig: Node3D   # RTSCamera
var _split := false    ## split=1: EnvProps draws <name>_v0 (one variant, no collapsed triangles): cost check only
var _no_png := false   ## nopng=1: stats only
## before=<folder>: draw the pre-A2.8 meshes rebuilt in that folder (old build_env.gd tree / rock / pillar code) with
## the pre-A2.8 border layout (south bank = full trees, one crest-rock set), for a fair before / after cost check.
var _before := ""
## scope=all (default) | border (only the border forest goes back) | props (only EnvProps) | nocontact (nothing
## goes back, the contact-shadow surfaces are dropped). Cost experiments only.
var _before_scope := "all"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("mode="):
			_mode = arg.substr(5)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
		elif arg == "split=1":
			_split = true
		elif arg.begins_with("before="):
			_before = arg.substr(7)
		elif arg.begins_with("scope="):
			_before_scope = arg.substr(6)
		elif arg == "nopng=1":
			_no_png = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	if _mode == "lineup":
		_run_lineup()
	else:
		_run_map()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


func _shoot(shot: String, zoom: float, focus: Vector3, yaw: float = 0.0, frames: int = 40) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = yaw
	_rig.call(&"focus_on", focus)
	if zoom > 60.0:   # overview: the camera clamps to the map bounds, fine; far plane must reach
		(_rig.get(&"camera") as Camera3D).far = 800.0
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
	var objects: float = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	if not _no_png:
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/a28_%s_%s.png" % [_tag, shot]
		img.save_png(ProjectSettings.globalize_path(path))
	print("shot %-16s draws=%d prims=%d objects=%d gpu_ms=%.2f fps=%d" % [shot, draws, prims, objects, gpu,
			Engine.get_frames_per_second()])


# ---------------------------------------------------------------- the real map

func _run_map() -> void:
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
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
	var env: Node = main.get(&"env_props")
	var tree_pos: Array[Vector3] = []
	var rock_pos: Array[Vector3] = []
	var rock_scale: Array[float] = []
	if env:
		for c: Node in env.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null:
				continue
			for i in mmi.multimesh.instance_count:
				var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
				if String(mmi.name).begins_with("Tree"):
					tree_pos.append(xf.origin)
				elif String(mmi.name).begins_with("Rock"):
					rock_pos.append(xf.origin)
					rock_scale.append(xf.basis.get_scale().x)
			if _split:
				var vpath: String = mmi.multimesh.mesh.resource_path.trim_suffix(".res") + "_v0.res"
				if ResourceLoader.exists(vpath):
					mmi.multimesh.mesh = load(vpath) as Mesh
			print("props %s: %d instances, %d tris per mesh" % [mmi.name, mmi.multimesh.instance_count,
					_tris(mmi.multimesh.mesh)])
	if _before != "":
		for n4: Node in main.find_children("*", "MultiMeshInstance3D", true, false):
			var mm4: MultiMesh = (n4 as MultiMeshInstance3D).multimesh
			if mm4 == null or mm4.mesh == null:
				continue
			var in_border: bool = n4.get_parent().name == "BorderForest"
			if (_before_scope == "border" and not in_border) or (_before_scope == "props" and in_border) \
					or (_before_scope == "nocontact"):
				if _before_scope == "nocontact" and mm4.mesh.get_surface_count() > 1:
					var m2 := mm4.mesh.duplicate() as ArrayMesh
					m2.surface_remove(1)
					mm4.mesh = m2
				continue
			var base: String = mm4.mesh.resource_path.get_file().get_basename()
			if base.begins_with("rock_spire_v"):
				base = "rock_spire"
			if in_border and String(n4.name).begins_with("South_"):
				base = base.trim_suffix("_far")
			var p4: String = _before.path_join(base + ".res")
			if FileAccess.file_exists(p4):
				mm4.mesh = load(p4) as Mesh
	var border := 0
	var border_tris := 0
	for n2: Node in main.find_children("*", "MultiMeshInstance3D", true, false):
		var mm2 := n2 as MultiMeshInstance3D
		if mm2.get_parent() and mm2.get_parent().name == "BorderForest":
			border += mm2.multimesh.instance_count
			border_tris += mm2.multimesh.instance_count * _tris(mm2.multimesh.mesh)
	print("border forest: %d instances, %d tris total" % [border, border_tris])
	# Densest tree cluster in the player (south-west) half, and the biggest rock.
	var best := Vector3(-30, 0, 20)
	var best_n := -1
	for p: Vector3 in tree_pos:
		if p.x + p.z > 0.0:
			continue
		var n3 := 0
		for q: Vector3 in tree_pos:
			if p.distance_to(q) < 7.0:
				n3 += 1
		if n3 > best_n:
			best_n = n3
			best = p
	var rock := Vector3(-20, 0, 10)
	var rs := 0.0
	for i in rock_pos.size():
		if rock_scale[i] > rs and absf(rock_pos[i].x) < 50.0 and absf(rock_pos[i].z) < 50.0:
			rs = rock_scale[i]
			rock = rock_pos[i]
	print("forest focus %s (%d trees), rock focus %s (scale %.2f)" % [best, best_n, rock, rs])
	var shots: Array = [
		["overview", 150.0, Vector3(0, 0, 8)],
		["forest_z18", 18.0, best + Vector3(0, 0, 2)],
		["forest_z35", 35.0, best + Vector3(0, 0, 3)],
		["rocks_z16", 16.0, rock + Vector3(0, 0, 1.5)],
		["pillars_z24", 24.0, Vector3(0, 0, 3)],
		["base_z45", 45.0, Vector3(-38.0, 0.0, 38.0)],
		["edge_n_z55", 55.0, Vector3(10.0, 0.0, -52.0)],
		["edge_w_z40", 40.0, Vector3(-52.0, 0.0, 0.0)],
		["edge_s_z40", 40.0, Vector3(5.0, 0.0, 56.0)],
	]
	var world_env: Environment = null
	for we: Node in main.find_children("*", "WorldEnvironment", true, false):
		world_env = (we as WorldEnvironment).environment
	for s: Array in shots:
		if not _wanted(s[0]):
			continue
		var fog_was := world_env.fog_enabled if world_env else false
		if world_env and s[0] == "overview":
			world_env.fog_enabled = false
		await _shoot(s[0], s[1], s[2])
		if world_env:
			world_env.fog_enabled = fog_was
	print("SHOTS DONE")
	quit()


func _tris(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	var t := 0
	for s in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		t += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t


# ---------------------------------------------------------------- lineup

## nature_painted.gdshader's hash1 (sine-free, so the CPU gets the same value as the GPU).
static func _hash1(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d: float = p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)


static func variant_at(pos: Vector3) -> int:
	return mini(int(floor(_hash1(Vector2(pos.z, pos.x) + Vector2(3.1, 7.7)) * 3.0)), 2)


## A position near `pos` where the shader shows `variant`.
func _find_variant(pos: Vector3, variant: int) -> Vector3:
	for i in 400:
		var p: Vector3 = pos + Vector3(fmod(i * 0.173, 1.2) - 0.6, 0.0, fmod(i * 0.311, 1.2) - 0.6)
		if variant_at(p) == variant:
			return p
	return pos

func _run_lineup() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	var light: Node3D = (load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new()
	stage.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	var gm: Material = load("res://art/environment/ground_material.tres")
	if gm is ShaderMaterial:
		gm = (gm as ShaderMaterial).duplicate()
		(gm as ShaderMaterial).set_shader_parameter(&"lane_a", Vector2(500, 500))
		(gm as ShaderMaterial).set_shader_parameter(&"lane_b", Vector2(501, 501))
		for i in 4:
			(gm as ShaderMaterial).set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	ground.material_override = gm
	stage.add_child(ground)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	stage.add_child(_rig)
	# Rows (z): one group per mesh (x = (k - 2) * 13), its 3 variants side by side (positions searched so the
	# shader's hash picks variant 0, 1, 2 there). Far meshes: 2 instances each.
	var rows: Array = [[LINEUP_TREES, -4.0, 4.2, 3], [LINEUP_ROCKS, 6.0, 3.2, 3], [LINEUP_FAR, 16.0, 4.0, 2]]
	for r: Array in rows:
		var names: Array = r[0]
		for k in names.size():
			var mesh := load(MESH_DIR + String(names[k]) + ".res") as Mesh
			if mesh == null:
				continue
			var count: int = r[3]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mesh
			mm.instance_count = count
			for i in count:
				var pos := Vector3((k - 2) * 13.0 + (i - (count - 1) * 0.5) * float(r[2]), 0.0, float(r[1]))
				if count == 3:
					pos = _find_variant(pos, i)
				if String(names[k]) == "ruin_pillar":
					mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, 0.4 + i * 1.3).scaled(
						Vector3(1, (2.4 + i * 0.9) / 3.0, 1)), pos))
				else:
					mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, 0.3 + i * 1.9), pos))
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			stage.add_child(mmi)
			print("lineup %-20s %d tris" % [names[k], _tris(mesh)])
	for i in 5:
		await process_frame
	var shots: Array = [
		["lineup_z60", 55.0, Vector3(0, 0, 9)],
		["lineup_pine_fir", 15.0, Vector3(-19.5, 0, -5.5)],
		["lineup_broadleaf", 12.0, Vector3(0, 0, -5.5)],
		["lineup_birch_gold", 15.0, Vector3(19.5, 0, -5.5)],
		["lineup_boulder_slab", 11.0, Vector3(-19.5, 0, 5.5)],
		["lineup_shards_spire", 11.0, Vector3(6.5, 0, 5.5)],
		["lineup_pillar", 11.0, Vector3(26, 0, 5)],
		["lineup_far", 26.0, Vector3(0, 0, 18)],
	]
	for s: Array in shots:
		if _wanted(s[0]):
			await _shoot(s[0], s[1], s[2])
	# Wind check: the same broadleaf / pine frame 0.75 s apart must differ (trees sway), the rock row must not.
	_rig.call(&"focus_on", Vector3(-6.5, 0, -5.5))
	_rig.set(&"_target_zoom", 14.0)
	_rig.set(&"_zoom", 14.0)
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
	print("SHOTS DONE")
	quit()
