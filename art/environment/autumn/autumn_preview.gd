extends SceneTree
## Task 20.V0 previews: the real Crown Hollow skirmish (scenes/skirmish.tscn) turned GOLDEN AUTUMN at runtime by
## autumn_swap.gd (shared materials, ground colours, lighting preset), bot off, fog off, HUD hidden, with squads of
## all 4 kingdoms (Fire, Shadow, Ice, Nature) idle on open ground, at the forest edge and fighting in the centre.
## Game camera at zoom 40 and 55. Saves docs/art/screens/20_v0_<tag>_<shot>.png. Windowed only:
##   tools/godot_run.ps1 --path . -s res://art/environment/autumn/autumn_preview.gd --resolution 1600x900
##       --fixed-fps 60 --quit-after 9000 '--' tag=autumn
## `autumn=0` renders the same staging in the default warm look (tag it "warm") for a side-by-side.

const SHOTS: Array = [
	# [name, zoom, focus]
	["field_z40", 40.0, Vector3(-26.0, 0.0, 18.0)],
	["field_z55", 55.0, Vector3(-24.0, 0.0, 14.0)],
	["fight_z40", 40.0, Vector3(0.0, 0.0, 3.0)],
	["fight_z55", 55.0, Vector3(0.0, 0.0, 3.0)],
	["base_z40", 40.0, Vector3(-36.0, 0.0, 36.0)],
	["edge_n_z55", 55.0, Vector3(10.0, 0.0, -50.0)],
]

var main: Node
var _tag := "autumn"
var _autumn := true
var _swap: GDScript


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg == "autumn=0":
			_autumn = false
	_swap = load("res://art/environment/autumn/autumn_swap.gd")
	if _autumn:
		print("swapped shared materials: ", _swap.call(&"swap_shared_materials"))
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
	for i in 20:
		await process_frame
	if _autumn:
		print("autumn ground materials: ", _swap.call(&"apply_ground", main))
		print("autumn lighting: ", _swap.call(&"apply_lighting", main))
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for s: Array in SHOTS:
		rig.set(&"_target_zoom", s[1])
		rig.set(&"_zoom", s[1])
		rig.rotation.y = 0.0
		rig.call(&"focus_on", s[2])
		for i in 50:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/20_v0_%s_%s.png" % [_tag, s[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved ", path)
	print("SHOTS DONE")
	_swap.call(&"release")
	quit()


## Four kingdoms: Fire + Nature on team 0, Shadow + Ice on team 1 (the 2v2 pairing of the playtest). Idle squads on
## the open field and by the forest edge, two small fights in the centre.
func _stage() -> void:
	var fire: Array = ["flame_guard", "flame_guard", "ember_archer", "ember_archer", "blaze_rider"]
	var shadow: Array = ["shade", "shade", "nightbolt", "shadow_knight", "grave_hound"]
	var ice: Array = ["rimeshield", "rimeshield", "shardcaster", "shardcaster", "rime_seer"]
	var nature: Array = ["thornling", "thornling", "burr_slinger", "burr_slinger", "bramblehorn"]
	# Field (zoom 40 / 55 around (-26, 18)): one squad of each kingdom side by side.
	_squad(fire, 0, Vector3(-36.0, 0.0, 14.0))
	_squad(nature, 0, Vector3(-28.0, 0.0, 14.0))
	_squad(shadow, 1, Vector3(-36.0, 0.0, 22.0))
	_squad(ice, 1, Vector3(-28.0, 0.0, 22.0))
	# Centre fights: Fire vs Shadow, Nature vs Ice.
	var a: Array = _squad(fire, 0, Vector3(-8.0, 0.0, 10.0))
	var b: Array = _squad(shadow, 1, Vector3(3.0, 0.0, -4.0), -1.0)
	var c: Array = _squad(nature, 0, Vector3(-12.0, 0.0, 0.0))
	var d: Array = _squad(ice, 1, Vector3(8.0, 0.0, 6.0), -1.0)
	for u: Node in a + c:
		u.call(&"command_attack_move", Vector3(4.0, 0.0, 0.0))
	for u: Node in b + d:
		u.call(&"command_attack_move", Vector3(-5.0, 0.0, 6.0))
	# By the north edge.
	_squad(nature, 0, Vector3(4.0, 0.0, -48.0))
	_squad(ice, 1, Vector3(14.0, 0.0, -48.0))


func _squad(ids: Array, team: int, at: Vector3, dir: float = 1.0) -> Array:
	var out: Array = []
	for i in ids.size():
		var u: Node3D = main.call(&"make_unit", ids[i])
		if u == null:
			print("no unit ", ids[i])
			continue
		u.set(&"team", team)
		main.add_child(u)
		u.global_position = at + Vector3((i % 4) * 1.6, 0.0, (i / 4) * 1.8 * dir)
		out.append(u)
	return out
