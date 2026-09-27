extends SceneTree
## Task MAP.P1 screenshots + GPU timing of the real Crown Hollow skirmish map (scenes/skirmish.tscn): bot off,
## fog of war off, HUD hidden, a staged fight in the centre plus idle squads on open grass and on a road, game
## camera (pitch 55, fov 50) at zooms 20 / 40 / 55. Saves docs/art/screens/map_polish_<tag>_<shot>.png and prints
## "GPU <shot> <ms>" (average GPU render time over 120 frames, vsync off). Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/environment/map_polish_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 9000 -- tag=after
## `only=<shot>,<shot>` renders only those shots; `gpu=0` skips the timing.

const SHOTS: Array = [
	# [name, zoom, focus, measure gpu]
	["base_z20", 20.0, Vector3(-38.0, 0.0, 40.0), false],
	["base_z40", 40.0, Vector3(-36.0, 0.0, 36.0), true],
	["fight_z20", 20.0, Vector3(0.0, 0.0, 3.0), false],
	["fight_z40", 40.0, Vector3(0.0, 0.0, 3.0), true],
	["fight_z55", 55.0, Vector3(0.0, 0.0, 3.0), true],
	["field_z20", 20.0, Vector3(-27.0, 0.0, 21.0), false],
	["field_z40", 40.0, Vector3(-25.0, 0.0, 16.0), false],
	["field_e_z20", 20.0, Vector3(28.5, 0.0, -21.0), false],
	["road_z20", 20.0, Vector3(-44.0, 0.0, 16.0), false],
	["edge_n_z55", 55.0, Vector3(10.0, 0.0, -50.0), true],
	["edge_w_z40", 40.0, Vector3(-52.0, 0.0, -18.0), false],
	["edge_s_z40", 40.0, Vector3(-12.0, 0.0, 52.0), false],
	["enemy_z40", 40.0, Vector3(36.0, 0.0, -36.0), false],
]
const GPU_FRAMES := 120

var main: Node
var _tag := "shot"
var _only := ""
var _gpu := true


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
		elif arg == "gpu=0":
			_gpu = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
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
	_stage()
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	var vp_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var total := 0.0
	var measured := 0
	for s: Array in SHOTS:
		if _only != "" and not _only.split(",").has(s[0]):
			continue
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = 0.0
		rig.call(&"focus_on", s[2])
		for i in 50:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/map_polish_%s_%s.png" % [_tag, s[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s draws=%d prims=%d" % [path,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		if _gpu and bool(s[3]):
			var sum := 0.0
			for i in GPU_FRAMES:
				await RenderingServer.frame_post_draw
				sum += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
			var avg := sum / GPU_FRAMES
			total += avg
			measured += 1
			print("GPU %s %.3f ms" % [s[0], avg])
	if measured > 0:
		print("GPU MEAN %.3f ms over %d shots" % [total / measured, measured])
	print("SHOTS DONE")
	quit()


## A fight in the centre (moving), plus idle squads on open grass and on the west road, so readability of units
## against the ground can be judged at every zoom.
func _stage() -> void:
	var p_ids: Array = ["flame_guard", "flame_guard", "flame_guard", "flame_guard", "ember_archer",
			"ember_archer", "ember_archer", "blaze_rider"]
	var e_ids: Array = ["shade", "shade", "shade", "shade", "shadow_knight", "nightbolt", "nightbolt",
			"grave_hound"]
	var mine: Array = _squad(p_ids, 0, Vector3(-7.0, 0.0, 9.0))
	var theirs: Array = _squad(e_ids, 1, Vector3(3.0, 0.0, -3.0), -1.0)
	for u: Node in mine:
		u.call(&"command_attack_move", Vector3(4.0, 0.0, -2.0))
	for u: Node in theirs:
		u.call(&"command_attack_move", Vector3(-4.0, 0.0, 8.0))
	_squad(["flame_guard", "flame_guard", "ember_archer", "ember_archer", "blaze_rider"], 0, Vector3(-30.0, 0.0, 20.0))
	_squad(["shade", "shade", "nightbolt", "shadow_knight", "grave_hound"], 1, Vector3(26.0, 0.0, -22.0))
	_squad(["flame_guard", "ember_archer", "flame_guard", "ember_archer"], 0, Vector3(-45.5, 0.0, 14.0))


func _squad(ids: Array, team: int, at: Vector3, dir: float = 1.0) -> Array:
	var out: Array = []
	for i in ids.size():
		var u: Node3D = main.call(&"make_unit", ids[i])
		if u == null:
			continue
		u.set(&"team", team)
		main.add_child(u)
		u.global_position = at + Vector3((i % 4) * 1.6, 0.0, (i / 4) * 1.8 * dir)
		out.append(u)
	return out
