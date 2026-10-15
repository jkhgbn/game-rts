extends "res://docs/art/lab/ge_review/tools/ge_shots.gd"
## G-E team read shots (gameplay-coder): two armies of `pk` / `ek` clashing in the open, fog and HUD off, zoom 30 and 40.
## WINDOWED only:
##   tools\godot_run.ps1 --path . -s docs/art/lab/ge_team/tools/ge_team_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --pk=fire --ek=fire --tag=_ge_team_after
## JPGs land in docs/art/lab/ge_review/<tag>/ (ge_shots' OUT); the key PNGs are composed into docs/art/lab/ge_team/.
## "Before" = Unit.ALT_PALETTE_ENABLED and Unit.TEAM_RING_ENABLED set false for the run.


func _main() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	tag = String(args.get("tag", "_ge_team"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [OUT, tag]))
	for i in 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1600, 900))
		for f in 4:
			await process_frame
	var pk := String(args.get("pk", "fire"))
	var ek := String(args.get("ek", "fire"))
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", StringName(pk))
	main.set(&"enemy_kingdom", StringName(ek))
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
	var all: Array[Unit] = []
	for team: int in [0, 1]:
		var types := _kingdom_types(pk if team == 0 else ek)
		var i := 0
		for id: String in types.slice(1, 11):
			var col := i % 5
			var row := i / 5
			var z := 5.0 + float(row) * 2.6
			var u := _unit(id, team, c + Vector3((float(col) - 2.0) * 2.4, 0.0, z if team == 0 else -z), 0.0 if team == 1 else PI)
			if u:
				u.max_hp = 20000.0
				u.hp = 20000.0
				all.append(u)
			i += 1
	for u in all:
		if u.has_method(&"command_attack_move"):
			u.call(&"command_attack_move", c)
		else:
			u.command_move(c)
	_cam(c, 30.0)
	await _wait(3.5)
	await _shot("battle_%s_%s_z30" % [pk, ek])
	_cam(c, 40.0)
	await _wait(1.0)
	await _shot("battle_%s_%s_z40" % [pk, ek])
	print("GE SHOTS DONE ", tag)
	quit(0)
