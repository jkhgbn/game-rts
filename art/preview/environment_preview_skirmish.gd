extends SceneTree
## Task A.10 screenshots: loads the real skirmish map (scenes/skirmish.tscn), bot off, fog off, HUD hidden,
## and saves the game camera (pitch 55, fov 50) at zoom 20 / 40 / 55 over several spots to
## docs/art/screens/polish_env_<tag>_<shot>.png. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/preview/environment_preview_skirmish.gd
##       --resolution 1600x900 --quit-after 6000 -- tag=after dressing=1
## `dressing=1` adds art/environment/map_dressing.tscn the way main.gd should (see its script header),
## `fog=1` keeps the fog of war on, `only=<shot>,<shot>` takes only those shots.

const SHOTS: Array = [
	# [name, zoom, focus]
	["z20_crown", 20.0, Vector3(0.0, 0.0, 1.5)],
	["z20_base", 20.0, Vector3(-40.0, 0.0, 37.0)],
	["z20_home_nodes", 20.0, Vector3(-38.0, 0.0, 30.0)],
	["z20_node", 20.0, Vector3(-17.0, 0.0, 8.0)],
	["z40_base", 40.0, Vector3(-38.0, 0.0, 34.0)],
	["z40_mid", 40.0, Vector3(-10.0, 0.0, 6.0)],
	["z55_centre", 55.0, Vector3(0.0, 0.0, 4.0)],
	["z55_edge_sw", 55.0, Vector3(-48.0, 0.0, 50.0)],
	["z55_edge_n", 55.0, Vector3(12.0, 0.0, -56.0)],
]

var main: Node
var _tag := "shot"
var _dressing := false
var _fog := false
var _only := ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg == "dressing=1":
			_dressing = true
		elif arg == "fog=1":
			_fog = true
		elif arg.begins_with("only="):
			_only = arg.substr(5)
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
	if _dressing and ResourceLoader.exists("res://art/environment/map_dressing.tscn"):
		main.add_child((load("res://art/environment/map_dressing.tscn") as PackedScene).instantiate())
	var fog: Node = main.get(&"fog")
	if fog and not _fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	var rig: Node3D = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for s: Array in SHOTS:
		if _only != "" and not (s[0] as String) in _only.split(","):
			continue
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = 0.0
		rig.call(&"focus_on", s[2])
		for i in 45:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/polish_env_%s_%s.png" % [_tag, s[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s fps=%d draws=%d prims=%d" % [path, Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	print("SHOTS DONE")
	quit()
