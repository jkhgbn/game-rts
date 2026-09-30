extends SceneTree
## Fire / Shadow clarity lineup (read-only tool, 2026-09-30): a real skirmish (lighting, ground, HUD hidden), every
## non-worker Fire and Shadow unit type standing in two labelled rows plus both wizards, shot with the real RTS camera
## at zoom 30 (the default) and 18. Units are far from each other's aggro, on hold, so nothing fights.
## Run (windowed): tools\godot_run.ps1 --path . -s res://docs/art/ingame_grade/fs_lineup.gd --quit-after 100000 -- --tag=x
## Shots: docs/art/ingame_grade/shots/lineup_<tag>_*.png

const SKIRMISH := "res://scenes/skirmish.tscn"
const OUT := "res://docs/art/ingame_grade/shots"

var main: Node = null
var tag := "x"


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var wd := create_timer(240.0, true, false, true)
	wd.timeout.connect(func() -> void:
		print("LINEUP ERROR watchdog")
		quit(3))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	for i in 4:
		await process_frame
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var waited := 0
	while not bool(main.get(&"match_started")):
		await process_frame
		waited += 1
		if waited > 20000:
			quit(2)
			return
	for team in [0, 1]:
		var wz: Node = main.call(&"wizard_of", team)
		if wz:
			for c in wz.get_children():
				if c.has_method(&"default_pick") and not bool(c.call(&"is_locked")):
					c.call(&"choose", c.call(&"default_pick"))
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
	for c in main.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
	var center := Vector3(-26, 0, 36)
	var fire := _types(&"fire")
	var shadow := _types(&"shadow")
	var axis := Vector3(1, 0, 0)
	var rows := [[fire, 0, -3.0], [shadow, 1, 3.0]]
	for row: Array in rows:
		var list: Array = row[0]
		var n := list.size()
		for i in n:
			var u: Node = main.call(&"make_unit", list[i])
			if u == null:
				continue
			u.set(&"team", 0)   # same team: no fighting; the model keeps its kingdom colour
			main.add_child(u)
			(u as Node3D).global_position = center + axis * (float(i) - float(n - 1) * 0.5) * 2.3 + Vector3(0, 0, float(row[2]))
			u.call(&"command_stop")
			if u.has_method(&"command_hold"):
				u.call(&"command_hold")
			(u as Node3D).rotation.y = 0.0
			print("LINEUP ", row[1], " ", i, " ", list[i])
	for team in [0, 1]:
		var w: Node3D = main.call(&"wizard_of", team)
		if w:
			w.global_position = center + Vector3(-2.5 if team == 0 else 2.5, 0, -8.0)
			w.call(&"command_stop")
	for i in 90:
		await process_frame
	# The rig's focus sits south of the view centre: aim a few metres north of the rows so they fill the frame.
	await _shot("z30", center + Vector3(0, 0, -5), 30.0)
	await _shot("z18_left", center + Vector3(-7, 0, -3), 18.0)
	await _shot("z18_right", center + Vector3(7, 0, -3), 18.0)
	await _shot("z22_wizards", center + Vector3(0, 0, -11), 22.0)
	print("LINEUP done")
	quit(0)


func _types(kingdom: StringName) -> Array[String]:
	var out: Array[String] = []
	var names: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/units/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres"):
			names.append(fn.get_basename())
	names.sort()
	for id in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or StringName(t.get(&"faction")) != kingdom:
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0 or bool(t.get(&"is_worker")):
			continue
		out.append(id)
	return out


func _shot(id: String, at: Vector3, zoom: float) -> void:
	var cam: Node3D = main.get(&"camera_rig")
	cam.rotation = Vector3.ZERO
	cam.call(&"focus_on", at + Vector3(0, 0, zoom * 0.14))
	cam.set(&"_zoom", zoom)
	cam.set(&"_target_zoom", zoom)
	cam.call(&"_apply_zoom")
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := ProjectSettings.globalize_path("%s/lineup_%s_%s.png" % [OUT, tag, id])
	img.save_png(p)
	print("LINEUP shot ", p)
