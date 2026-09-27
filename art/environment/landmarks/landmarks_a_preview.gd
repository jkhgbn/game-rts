extends SceneTree
## Task 12.V13 screenshots: the Fallen Colossus and the Giant's Stump. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/landmarks/landmarks_a_preview.gd
##       --resolution 1600x900 --quit-after 9000 -- mode=stage tag=v1
## Saves docs/art/screens/landmark_<tag>_<shot>.png (tag empty: landmark_<shot>.png) and prints the render stats.
## mode=stage: both landmarks (+ their mirrored copies, turned by PI as on the map) on the painted ground with the warm
##   lighting rig, units around them for scale, game camera (pitch 55, fov 50) at default / max zoom + close-ups +
##   the black silhouette test.
## mode=map: the real skirmish map (bot off, fog off, HUD hidden) with the four landmarks placed at their map-fill.md 3.2
##   spots, from the game camera. `only=<shot>,<shot>` limits the shots.

const COLOSSUS := "res://art/environment/landmarks/colossus.tscn"
const STUMP := "res://art/environment/landmarks/giant_stump.tscn"
const UNITS: Array[String] = ["res://art/units/fire/flame_guard.tscn", "res://art/units/fire/ember_archer.tscn",
	"res://art/units/shadow/shadow_knight.tscn", "res://art/units/nature/thornling.tscn"]
const SPOTS: Array = [[COLOSSUS, Vector3(-57, 0, -16)], [STUMP, Vector3(-30, 0, 20)]]

var _tag := ""
var _mode := "stage"
var _only := ""
var _rig: Node3D
var _stage: Node3D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("mode="):
			_mode = arg.substr(5)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	if zoom > 60.0:
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
	var img: Image = root.get_texture().get_image()
	var name: String = ("landmark_%s_%s.png" % [_tag, shot]) if _tag != "" else ("landmark_%s.png" % shot)
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/" + name))
	print("shot %-22s draws=%d prims=%d gpu_ms=%.2f" % [shot, draws, prims, gpu])


func _place(parent: Node, path: String, pos: Vector3, yaw: float) -> Node3D:
	var n: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	n.position = pos
	n.rotation.y = yaw
	parent.add_child(n)
	return n


func _unit(path: String, pos: Vector3, yaw: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var u: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	u.position = pos
	u.rotation.y = yaw
	_stage.add_child(u)


# ---------------------------------------------------------------- stage

func _run_stage() -> void:
	_stage = Node3D.new()
	_stage.name = "Stage"
	root.add_child(_stage)
	current_scene = _stage
	var light: Node3D = (load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new()
	_stage.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
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
	_stage.add_child(ground)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_stage.add_child(_rig)
	# Player-side copies (yaw 0) in front, the mirrored ones (yaw PI) behind them.
	var col_a := Vector3(-9, 0, 0)
	var stump_a := Vector3(9, 0, 0)
	_place(_stage, COLOSSUS, col_a, 0.0)
	_place(_stage, STUMP, stump_a, 0.0)
	_place(_stage, COLOSSUS, col_a + Vector3(0, 0, -22), PI)
	_place(_stage, STUMP, stump_a + Vector3(0, 0, -22), PI)
	# Scale: a few soldiers just outside the colliders (+ agent radius 0.5).
	_unit(UNITS[0], col_a + Vector3(-0.2, 0, 3.9), 0.3)
	_unit(UNITS[1], col_a + Vector3(3.2, 0, 2.2), -0.6)
	_unit(UNITS[2], col_a + Vector3(-3.9, 0, -1.2), 1.2)
	_unit(UNITS[3], col_a + Vector3(1.9, 0, -3.4), 2.6)
	_unit(UNITS[0], stump_a + Vector3(-2.3, 0, 2.3), 0.4)
	_unit(UNITS[1], stump_a + Vector3(3.0, 0, -0.9), -1.2)
	_unit(UNITS[3], stump_a + Vector3(0.9, 0, -2.8), 2.9)
	for i in 5:
		await process_frame
	var shots: Array = [
		["stage_z30", 30.0, Vector3(0, 0, 0)],
		["stage_z55", 55.0, Vector3(0, 0, -9)],
		["colossus_z30", 30.0, col_a],
		["colossus_z12", 12.0, col_a + Vector3(0, 0, 0.5)],
		["colossus_head_z8", 8.0, col_a + Vector3(1.0, 0, -0.2)],
		["colossus_hand_z7", 7.0, col_a + Vector3(-1.6, 0, 1.3)],
		["colossus_mirror_z14", 14.0, col_a + Vector3(0, 0, -22)],
		["stump_z30", 30.0, stump_a],
		["stump_z12", 12.0, stump_a + Vector3(0, 0, 0.5)],
		["stump_z7", 7.0, stump_a + Vector3(-0.6, 0, 0.8)],
		["stump_mirror_z14", 14.0, stump_a + Vector3(0, 0, -22)],
	]
	for s: Array in shots:
		if _wanted(s[0]):
			await _shoot(s[0], s[1], s[2])
	if _wanted("silhouette"):
		await _silhouette(col_a, stump_a)
	print("SHOTS DONE")
	quit()


## art-keep.md 0.1: the black silhouette on white from ~40 m (game camera at max zoom distance).
func _silhouette(a: Vector3, b: Vector3) -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	for n: Node in _stage.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		var mi := gi as MeshInstance3D
		if mi and mi.mesh is PlaneMesh:
			gi.material_override = white
		elif mi and mi.mesh:
			# Per surface: the multiplied contact shadow disc disappears (white on white), the rest is black.
			for s: int in mi.mesh.get_surface_count():
				var m: Material = mi.mesh.surface_get_material(s)
				var contact: bool = m != null and m.resource_path.ends_with("_contact_mat.tres")
				mi.set_surface_override_material(s, white if contact else black)
		else:
			gi.material_override = black
	for n2: Node in _stage.find_children("*", "WorldEnvironment", true, false):
		var env: Environment = (n2 as WorldEnvironment).environment.duplicate() as Environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color.WHITE
		env.glow_enabled = false
		env.fog_enabled = false
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.adjustment_enabled = false
		(n2 as WorldEnvironment).environment = env
	for n3: Node in _stage.find_children("*", "CanvasLayer", true, false):
		(n3 as CanvasLayer).visible = false
	await _shoot("silhouette", 40.0, (a + b) * 0.5 + Vector3(0, 0, -6))


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
	# Place the landmarks unless the map already has them (12.C8 plugs them in).
	var have := main.get_tree().get_nodes_in_group(&"landmarks")
	for s: Array in SPOTS:
		var path: String = s[0]
		var p: Vector3 = s[1]
		var found := false
		for l: Node in have:
			if l is Node3D and (l as Node3D).global_position.distance_to(p) < 1.0:
				found = true
		if not found:
			_place(main, path, p, 0.0)
			_place(main, path, -p, PI)
	var shots: Array = [
		["map_colossus_z30", 30.0, Vector3(-57, 0, -14)],
		["map_colossus_z45", 45.0, Vector3(-52, 0, -12)],
		["map_stump_z30", 30.0, Vector3(-30, 0, 22)],
		["map_stump_z45", 45.0, Vector3(-28, 0, 16)],
		["map_mirror_stump_z30", 30.0, Vector3(30, 0, -18)],
		["map_mirror_colossus_z30", 30.0, Vector3(57, 0, 18)],
	]
	for s2: Array in shots:
		if _wanted(s2[0]):
			await _shoot(s2[0], s2[1], s2[2])
	print("SHOTS DONE")
	quit()
