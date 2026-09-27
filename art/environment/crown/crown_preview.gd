extends SceneTree
## Task A2.3 screenshots: the real skirmish (scenes/skirmish.tscn), bot off, fog off, HUD hidden, game camera
## (pitch 55, fov 50). Walks the Ember Crown through its looks and shoots the crystal nodes at several fills.
## Saves docs/art/screens/a23_<tag>_<shot>.png. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/crown/crown_preview.gd
##       --resolution 1600x900 --quit-after 9000 -- tag=after swap=1
## swap=1   shows the crown model (art/environment/crown/ember_crown_mesh.res) on the crown gem, like the lead
##          lines in the A2.3 report do (preview only: it pokes the gem node directly).
## light=E  sets the crown's OmniLight energy (test value), range=R its range.
## only=crown|crystal  one half of the shots.

const CROWN_MESH := "res://art/environment/crown/ember_crown_mesh.res"

var main: Node
var rig: Node3D
var _tag := "shot"
var _swap := false
var _light := -1.0
var _range := -1.0
var _only := ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg == "swap=1":
			_swap = true
		elif arg.begins_with("light="):
			_light = float(arg.substr(6))
		elif arg.begins_with("range="):
			_range = float(arg.substr(6))
		elif arg.begins_with("only="):
			_only = arg.substr(5)
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String, zoom: float, focus: Vector3, settle: int = 40) -> void:
	rig.set(&"_target_zoom", zoom)
	rig.set(&"_zoom", zoom)
	rig.rotation.y = 0.0
	rig.call(&"focus_on", focus)
	await _frames(settle)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "res://docs/art/screens/a23_%s_%s.png" % [_tag, name]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s fps=%d draws=%d" % [path, Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	rig = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var crown: Node3D = main.get(&"crown")
	if crown:
		_tweak_crown(crown)
	if _only != "crystal" and crown:
		await _crown_shots(crown)
	if _only != "crown":
		await _crystal_shots()
	print("SHOTS DONE")
	quit()


func _tweak_crown(crown: Node3D) -> void:
	if _swap and ResourceLoader.exists(CROWN_MESH):
		var gem: MeshInstance3D = crown.get(&"_gem")
		if gem:
			gem.mesh = load(CROWN_MESH) as Mesh
			gem.material_override = null
	for c: Node in crown.get_children():
		if c is OmniLight3D:
			if _light >= 0.0:
				(c as OmniLight3D).light_energy = _light
			if _range > 0.0:
				(c as OmniLight3D).omni_range = _range


func _crown_shots(crown: Node3D) -> void:
	var f := Vector3(0.0, 0.0, 0.6)
	await _shot("sealed_z12", 12.0, f, 60)
	await _shot("sealed_z22", 22.0, f)
	await _shot("sealed_z40", 40.0, f)
	# Stirring: the seal breaks 12 s from now.
	var now := float(main.call(&"match_time"))
	crown.set(&"seal_time", now + 12.0)
	await _frames(90)
	await _shot("stirring_z22", 22.0, f, 10)
	while bool(crown.call(&"is_sealed")):
		await process_frame
	await _frames(14)
	await _shot("break_z22", 22.0, f, 2)
	await _frames(150)
	await _shot("awake_z12", 12.0, f)
	await _shot("awake_z22", 22.0, f)
	await _shot("awake_z40", 40.0, f)
	await _shot("awake_z55", 55.0, Vector3(-6.0, 0.0, 8.0))
	# A wizard takes it: the altar goes dormant, the crown floats over her head.
	var hero: Node3D = main.get(&"hero")
	if hero:
		for w: Node in main.get(&"wardens").duplicate():
			if is_instance_valid(w) and w.has_method(&"take_damage"):
				w.call(&"take_damage", 1.0e6, null)
		hero.global_position = Vector3(-2.6, 0.0, 2.6)
		hero.call(&"command_move", Vector3(-1.0, 0.0, 1.0))
		var t := 0
		while bool(crown.call(&"is_available")) and t < 900:
			await process_frame
			t += 1
		hero.call(&"command_move", Vector3(-2.2, 0.0, 3.2))
		await _frames(150)
		await _shot("worn_z16", 16.0, Vector3(-0.8, 0.0, 1.4))
		await _shot("worn_z30", 30.0, Vector3(-0.8, 0.0, 1.4))


func _crystal_shots() -> void:
	# Extra nodes around Fire's natural expansion (-16, 6), then depleted to several fills.
	var fills: Array[float] = [0.62, 0.3, 0.1]
	var spots: Array[Vector3] = [Vector3(-11.5, 0, 9.0), Vector3(-20.5, 0, 9.0), Vector3(-16.0, 0, 11.5)]
	var script: GDScript = load("res://scripts/economy/crystal_node.gd") as GDScript
	var nav: Node = main.get(&"nav_region")
	for i: int in fills.size():
		var cn: Node3D = script.new()
		cn.set(&"crystals_left", 900)
		cn.position = spots[i]
		(nav if nav else main).add_child(cn)
		cn.call(&"take", int(900.0 * (1.0 - fills[i])))
	await _shot("crystal_fills_z16", 16.0, Vector3(-16.0, 0.0, 9.0), 60)
	await _shot("crystal_fills_z30", 30.0, Vector3(-16.0, 0.0, 9.0))
	await _shot("crystal_base_z30", 30.0, Vector3(-40.0, 0.0, 41.0), 60)
	await _shot("crystal_base_z45", 45.0, Vector3(-38.0, 0.0, 38.0))
