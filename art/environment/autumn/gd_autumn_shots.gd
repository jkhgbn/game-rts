extends SceneTree
## G-D autumn maps shots (docs/art/gd_autumn_maps.md): Quartermeet loaded through MapCatalog.instantiate_level, the
## autumn look installed by AutumnSwap.ensure_for_level on the level's `ready` (the main.gd hook's moment; nothing when
## the hook already did it), fog / HUD off, game camera at zoom 30. Windowed only:
##   tools/godot_run.ps1 --path . -s res://art/environment/autumn/gd_autumn_shots.gd --resolution 1600x900
##       --fixed-fps 60 --quit-after 9000 '--' --gfx=high tag=after
## `autumn=0` = the map as it rendered before (no swap; meaningful only while the hook is not in main.gd), tag "before".
## Saves docs/art/lab/gd_autumn/quartermeet_<tag>_<shot>.png.

const OUT := "res://docs/art/lab/gd_autumn/"
const SHOTS: Array = [
	# [name, zoom, focus]
	["ford_z30", 30.0, Vector3(-12.0, 0.0, -30.0)],
]

var level: Node
var _tag := "after"
var _autumn := true


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg == "autumn=0":
			_autumn = false
	level = MapCatalog.load_default().instantiate_level(&"quartermeet")
	if _autumn:
		var sw: GDScript = load("res://art/environment/autumn/autumn_swap.gd")
		level.ready.connect(func() -> void: print("autumn guard: ", sw.call(&"ensure_for_level", level)), CONNECT_ONE_SHOT)
	root.add_child(level)
	current_scene = level
	_run()


func _run() -> void:
	var wait := 0
	while level.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	for i in 30:
		await process_frame
	var fog: Node = level.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in level.get_children():
		if n is CanvasLayer and n.name != &"Vignette":
			(n as CanvasLayer).visible = false
	var hud: Node = level.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	var rig: Node3D = level.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for s: Array in SHOTS:
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = 0.0
		rig.call(&"focus_on", s[2])
		for i in 90:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := OUT + "quartermeet_%s_%s.png" % [_tag, s[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved ", path)
	print("SHOTS DONE")
	quit()
