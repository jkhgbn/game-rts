extends SceneTree
## Task MAP.P3 (the horizon): screenshots + GPU timing of the real Crown Hollow skirmish (scenes/skirmish.tscn) at the
## four map edges and corners, game camera (pitch 55, fov 50) at zoom 40 / 55, plus two shots with the camera
## turned to look out of the map. Bot off, fog of war off, HUD hidden. With `horizon=1` it instances
## art/environment/horizon/horizon.tscn into the skirmish (what the lead's glue will do).
## Saves docs/art/screens/map_polish3_<tag>_<shot>.png. With `gpu=1` it measures the GPU time on the gpu shots
## twice per shot, horizon hidden then shown (same frame state, 120 frames each, vsync off), and prints the delta.
## Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/horizon/horizon_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 12000 -- tag=after horizon=1 gpu=1
## `only=<shot>,<shot>` renders only those shots; `shots=0` skips the screenshots (timing only).

const HORIZON_SCENE := "res://art/environment/horizon/horizon.tscn"
const SHOTS: Array = [
	# [name, zoom, focus, camera yaw (0 = looking north), measure gpu]
	["n_z40", 40.0, Vector3(0.0, 0.0, -58.0), 0.0, false],
	["n_z55", 55.0, Vector3(0.0, 0.0, -58.0), 0.0, true],
	["s_z40", 40.0, Vector3(0.0, 0.0, 58.0), 0.0, false],
	["s_z55", 55.0, Vector3(0.0, 0.0, 58.0), 0.0, false],
	["e_z40", 40.0, Vector3(58.0, 0.0, 0.0), 0.0, false],
	["e_z55", 55.0, Vector3(58.0, 0.0, 0.0), 0.0, true],
	["w_z40", 40.0, Vector3(-58.0, 0.0, 0.0), 0.0, false],
	["w_z55", 55.0, Vector3(-58.0, 0.0, 0.0), 0.0, false],
	["ne_z40", 40.0, Vector3(58.0, 0.0, -58.0), 0.0, false],
	["ne_z55", 55.0, Vector3(58.0, 0.0, -58.0), 0.0, true],
	["nw_z40", 40.0, Vector3(-58.0, 0.0, -58.0), 0.0, false],
	["nw_z55", 55.0, Vector3(-58.0, 0.0, -58.0), 0.0, true],
	["se_z40", 40.0, Vector3(58.0, 0.0, 58.0), 0.0, false],
	["se_z55", 55.0, Vector3(58.0, 0.0, 58.0), 0.0, false],
	["sw_z40", 40.0, Vector3(-58.0, 0.0, 58.0), 0.0, false],
	["sw_z55", 55.0, Vector3(-58.0, 0.0, 58.0), 0.0, false],
	# Camera turned (middle mouse) to look out of the map: the far land is in full view.
	["s_out_z55", 55.0, Vector3(0.0, 0.0, 58.0), PI, true],
	["e_out_z55", 55.0, Vector3(58.0, 0.0, 10.0), -PI * 0.5, false],
	["centre_z55", 55.0, Vector3(0.0, 0.0, 0.0), 0.0, true],
	# Landmark checks: the aqueduct (W), the tower (NE), the shrine (NW), the pond (E) where they sit best in view.
	["w_aq_z55", 55.0, Vector3(-58.0, 0.0, -34.0), 0.0, false],
	["w_aq_z40", 40.0, Vector3(-58.0, 0.0, -40.0), 0.0, false],
	["ne_tower_z40", 40.0, Vector3(58.0, 0.0, -58.0), -0.5, false],
	["nw_shrine_z40", 40.0, Vector3(-58.0, 0.0, -58.0), 0.5, false],
	["e_pond_z55", 55.0, Vector3(58.0, 0.0, -50.0), 0.0, false],
	# 12.V5's river mouths: the horizon must keep the north stream and the south gorge open.
	["s_gorge_z40", 40.0, Vector3(15.0, 0.0, 58.0), 0.0, false],
	["s_gorge_out_z40", 40.0, Vector3(15.0, 0.0, 58.0), PI, false],
	["n_notch_z40", 40.0, Vector3(-15.0, 0.0, -58.0), 0.0, false],
	["n_notch_out_z55", 55.0, Vector3(-15.0, 0.0, -40.0), 0.0, false],
]
const GPU_FRAMES := 120

var main: Node
var horizon: Node3D
var _tag := "shot"
var _only := ""
var _gpu := false
var _shots := true
var _use_horizon := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
		elif arg == "gpu=1":
			_gpu = true
		elif arg == "shots=0":
			_shots = false
		elif arg == "horizon=1":
			_use_horizon = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	if _use_horizon and ResourceLoader.exists(HORIZON_SCENE):
		horizon = (load(HORIZON_SCENE) as PackedScene).instantiate() as Node3D
		main.add_child(horizon)
	root.add_child(main)
	current_scene = main
	_run()


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer and n.name != &"Vignette":
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var deltas: Array[float] = []
	for s: Array in SHOTS:
		if _only != "" and not _only.split(",").has(s[0]):
			continue
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = s[3]
		rig.call(&"focus_on", s[2])
		for i in 40:
			await process_frame
		if _shots:
			await RenderingServer.frame_post_draw
			var img: Image = root.get_texture().get_image()
			var path := "res://docs/art/screens/map_polish3_%s_%s.png" % [_tag, s[0]]
			img.save_png(ProjectSettings.globalize_path(path))
			print("saved %s draws=%d prims=%d" % [path,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		if _gpu and bool(s[4]):
			# A/B/A/B on the same view: horizon off, on, off, on (drops the first frames after each toggle).
			var off_sum := 0.0
			var on_sum := 0.0
			for rep in 4:
				var on: bool = rep % 2 == 1
				if horizon:
					horizon.visible = on
				for i in 10:
					await RenderingServer.frame_post_draw
				var sum := 0.0
				for i in GPU_FRAMES:
					await RenderingServer.frame_post_draw
					sum += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
				if on:
					on_sum += sum / GPU_FRAMES
				else:
					off_sum += sum / GPU_FRAMES
			if horizon:
				horizon.visible = true
			var d: float = (on_sum - off_sum) * 0.5
			deltas.append(d)
			print("GPU %s off %.3f ms on %.3f ms delta %+.3f ms" % [s[0], off_sum * 0.5, on_sum * 0.5, d])
	if not deltas.is_empty():
		var mean := 0.0
		for d: float in deltas:
			mean += d
		print("GPU MEAN DELTA %+.3f ms over %d shots" % [mean / deltas.size(), deltas.size()])
	print("SHOTS DONE")
	quit()
