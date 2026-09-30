extends SceneTree
## In-game readability capture for the six Stables T3 / extra models (read-only tool; the method of
## docs/art/ingame_grade/ingame_capture.gd: the real skirmish, real RTS camera, HUD on, fog off). Two lineups that do
## not fight (both on the player's team, 10 m apart): the Ice line (the three new Ice riders between their Ice
## siblings) and the Nature line (the three new Nature units between theirs); each unit wears its kingdom colour. Shots at the default RTS zoom 30, at 18 and at
## 45, plus both lines walking (the moving read).
##   tools\godot_run.ps1 --path . -s res://art/units/ice/frostcrown_juggernaut/tools/t3_ingame.gd --quit-after 60000 --
##     --tag=t3 [--out=res://docs/art/ingame_grade/shots]

const SKIRMISH := "res://scenes/skirmish.tscn"
const ICE_LINE: Array[String] = ["rimeshield", "snowdrift_rider", "rimehorn_rider", "frostcrown_juggernaut",
	"rime_harrier", "frostbow", "rime_colossus"]
const NATURE_LINE: Array[String] = ["thornling", "bramble_harrier", "stagrunner", "thornback_charger", "spirit_wolf",
	"glade_outrider", "bramblehorn"]

var args := {}
var main: Node = null
var out := "res://docs/art/ingame_grade/shots"
var tag := "t3"


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var wd := create_timer(300.0, true, false, true)
	wd.timeout.connect(func() -> void:
		print("T3IG ERROR watchdog")
		quit(3))
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	tag = String(args.get("tag", tag))
	out = String(args.get("out", out))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	for i in 4:
		await process_frame
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"ice")
	main.set(&"enemy_kingdom", &"nature")
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var waited := 0
	while not bool(main.get(&"match_started")):
		await process_frame
		waited += 1
		if waited > 20000:
			print("T3IG ERROR never started")
			quit(2)
			return
	for i in 30:
		await process_frame
	for team in [0, 1]:
		var wz: Node = main.call(&"wizard_of", team)
		var pn: Node = wz.get_node_or_null(^"StrIntPath") if wz else null
		if pn and not bool(pn.call(&"is_locked")):
			pn.call(&"choose", pn.call(&"default_pick"))
	paused = false
	for i in 10:
		await process_frame
	var cam: Node = main.get(&"camera_rig")
	cam.set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(1598, 898))
	var fog: Variant = main.get(&"fog")
	if fog is Node:
		(fog as Node).set(&"enabled", false)
	var ts: Node = get_first_node_in_group(&"tier_systems")
	if ts:
		ts.call(&"set_tier", 0, 3)
		ts.call(&"set_tier", 1, 3)
	# both lines on the player's team (the team colour comes from the unit's kingdom, not the team): nothing fights
	var ice_at := Vector3(-16.0, 0.0, 30.0)
	var nat_at := Vector3(-16.0, 0.0, 40.0)
	var ice := _line(ICE_LINE, 0, ice_at)
	var nat := _line(NATURE_LINE, 0, nat_at)
	for i in 90:
		await process_frame
	await _shot("ice_z30", ice_at, 30.0)
	await _shot("ice_z18", ice_at, 18.0)
	await _shot("nature_z30", nat_at, 30.0)
	await _shot("nature_z18", nat_at, 18.0)
	await _shot("both_z45", (ice_at + nat_at) * 0.5, 45.0)
	# on the move: both lines walk 8 m toward +x
	for u in ice + nat:
		if is_instance_valid(u):
			(u as Node).call(&"command_move", (u as Node3D).global_position + Vector3(8, 0, 0))
	await _wait(0.9)
	await _shot("ice_walk_z30", ice_at + Vector3(4, 0, 0), 30.0)
	await _shot("nature_walk_z30", nat_at + Vector3(4, 0, 0), 30.0)
	print("T3IG done")
	quit(0)


func _line(ids: Array[String], team: int, at: Vector3) -> Array:
	var res: Array = []
	var n := ids.size()
	for i in n:
		var u: Node = main.call(&"make_unit", ids[i])
		if u == null:
			print("T3IG no unit ", ids[i])
			continue
		u.set(&"team", team)
		main.add_child(u)
		(u as Node3D).global_position = at + Vector3((float(i) - float(n - 1) * 0.5) * 3.4, 0, 0)
		u.call(&"command_stop")
		if u.has_method(&"command_hold"):
			u.call(&"command_hold")
		if u.has_method(&"face_toward"):
			u.call(&"face_toward", (u as Node3D).global_position + Vector3(0, 0, 1))
		res.append(u)
	return res


func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000.0):
		await process_frame


func _shot(id: String, at: Vector3, zoom: float) -> void:
	var cam: Node3D = main.get(&"camera_rig")
	cam.rotation = Vector3.ZERO
	cam.call(&"focus_on", at + Vector3(0, 0, zoom * 0.14))
	cam.set(&"_zoom", zoom)
	cam.set(&"_target_zoom", zoom)
	cam.call(&"_apply_zoom")
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := ProjectSettings.globalize_path("%s/%s_%s.png" % [out, tag, id])
	img.save_png(p)
	print("T3IG shot ", p)
