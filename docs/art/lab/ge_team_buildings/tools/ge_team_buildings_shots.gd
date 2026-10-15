extends "res://docs/art/lab/ge_review/tools/ge_shots.gd"
## G-E team buildings (systems-coder): Fire vs Fire base pair, player row (front) vs enemy row (back, alt palette).
## WINDOWED only:
##   tools\godot_run.ps1 --path . -s docs/art/lab/ge_team_buildings/tools/ge_team_buildings_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high
## Writes docs/art/lab/ge_team_buildings/after_fire_fire_buildings_z30.png.

const DIR := "res://docs/art/lab/ge_team_buildings"


func _main() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	for i in 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1600, 900))
		for f in 4:
			await process_frame
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"fire")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		quit(1)
		return
	await _wait(1.0)
	_close_picker()
	_hud(false)
	_fog(false)
	var c := Vector3(-30.0, 0.0, 30.0)
	for u in get_nodes_in_group(&"units"):
		if u is Node3D and (u as Node3D).global_position.distance_to(c) < 30.0:
			(u as Node3D).visible = false
	for team: int in [0, 1]:
		var z := 7.0 if team == 0 else -7.0
		_place_building("fire_barracks", team, c + Vector3(-9.0, 0.0, z))
		_place_building("fire_hearth", team, c + Vector3(0.0, 0.0, z))
		_place_building("fire_tower", team, c + Vector3(7.0, 0.0, z))
		var u := _unit("flame_guard", team, c + Vector3(-1.0, 0.0, z * 0.45), 0.0 if team == 1 else PI)
		if u:
			u.command_stop()
	for b in get_nodes_in_group(&"buildings"):
		if b is Building and (b as Building).global_position.distance_to(c) < 20.0:
			print("building %s team %d colour %s" % [(b as Building).building_type.id, int((b as Building).team), (b as Building).team_color])
	_cam(c, 30.0)
	await _wait(2.0)
	Input.warp_mouse(Vector2(800, 450))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(ProjectSettings.globalize_path("%s/after_fire_fire_buildings_z30.png" % DIR))
	print("GE SHOTS DONE")
	quit(0)
