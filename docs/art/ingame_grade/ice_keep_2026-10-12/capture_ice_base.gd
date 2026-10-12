extends SceneTree
## Ice base in-game capture (read-only tool, Ice readability check 2026-10-12, rows 22 / 23 / 26 of under_90.md).
## Windowed skirmish (Ice vs Nature), real RTS camera + game lighting, HUD on, fog off, tier 3, full Ice base built,
## Torvald parked next to the keep. Same framing as ../ingame_capture.gd (b_base_ice / b_base_ice_far) so the shots
## compare 1:1 with ../shots/. Args after '--': --tag=after
## Run: tools\godot_run.ps1 --path . -s res://docs/art/ingame_grade/ice_keep_2026-10-12/capture_ice_base.gd --quit-after 60000 -- --tag=after

const SKIRMISH := "res://scenes/skirmish.tscn"
const OUT := "res://docs/art/ingame_grade/ice_keep_2026-10-12"

var main: Node = null
var tag := "after"


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var wd := create_timer(300.0, true, false, true)
	wd.timeout.connect(func() -> void:
		print("CAP ERROR watchdog")
		quit(3))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.trim_prefix("--tag=")
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
			print("CAP ERROR never started")
			quit(2)
			return
	for i in 30:
		await process_frame
	for team in [0, 1]:
		var wz: Node = main.call(&"wizard_of", team)
		if wz == null:
			continue
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
	_build_base(0, "ice")
	for i in 150:
		await process_frame
	var c: Vector3 = main.call(&"base_center", 0)
	var wiz: Node3D = main.call(&"wizard_of", 0)
	if wiz:
		wiz.global_position = c + Vector3(4.5, 0, 3.5)
		if wiz.has_method(&"command_stop"):
			wiz.call(&"command_stop")
	for i in 30:
		await process_frame
	await _shot("base_ice", c + Vector3(3, 0, -3), 30.0)
	await _shot("base_ice_far", c + Vector3(6, 0, -6), 48.0)
	await _shot("keep_close", c + Vector3(1.5, 0, 0.5), 18.0)
	if wiz:
		await _shot("torvald_z22", wiz.global_position, 22.0)
	print("CAP done")
	quit(0)


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
	var p := ProjectSettings.globalize_path("%s/%s_%s.png" % [OUT, tag, id])
	img.save_png(p)
	print("CAP shot ", p, " ", img.get_size())


func _build_base(team: int, kingdom: String) -> void:
	var grid: Object = main.get(&"build_grid")
	var near: Vector3 = main.call(&"base_center", team)
	var ids: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/buildings/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres") and fn.begins_with(kingdom + "_") and not fn.contains("keep"):
			ids.append(fn.get_basename())
	ids.sort()
	var dir := Vector3(1, 0, -1)
	var i := 0
	for id in ids:
		var bt: Resource = load("res://data/buildings/%s.tres" % id)
		var target: Vector3 = near + dir * (8.0 + 3.0 * (i % 3)) + Vector3(dir.z, 0, -dir.x) * (-10.0 + 7.0 * float(i))
		var spot: Vector3 = grid.call(&"find_spot", bt, target, team, 14)
		if spot != Vector3.INF:
			grid.call(&"spawn_complete", bt, spot, team)
		i += 1
