extends SceneTree
## Automated play-through used to check the prototype works.
## Run:  godot --headless --path . -s tests/smoke_test.gd --fixed-fps 60
## Add  shots=<folder>  after  --  (and run without --headless) to save screenshots.

var main: Node
var frame := 0
var shots_dir := ""
var fireball_cast := false
var _wait := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			shots_dir = arg.substr(6)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL: navigation never finished baking")
			return true
		return false
	frame += 1
	if frame == 40:
		print("Navigation baked after %d frames" % _wait)
		print("Units spawned: player=%d enemy=%d" % [_count(0), _count(1)])
		_shot("01_start")
		_move_army(main.MID_CAMP + Vector3(-5, 0, 5))
		main.camera_rig.focus_on(main.MID_CAMP + Vector3(-6, 0, 6))
	if frame == 300:
		print("Army near mid camp? hero at %s" % main.hero.global_position)
		_shot("02_battle")
	if not fireball_cast and frame > 300 and frame % 30 == 0 and _count(1) > 6:
		var target := _nearest_enemy_to(main.hero.global_position)
		if target:
			var result: String = main.hero.command_fireball(target.global_position)
			print("Fireball cast: %s" % ("ok" if result == "" else result))
			fireball_cast = true
	if frame == 330:
		_shot("03_fireball")
	if frame == 1200:
		print("After mid fight: player=%d enemy=%d hero_hp=%d" % [_count(0), _count(1), main.hero.hp if is_instance_valid(main.hero) else 0])
		_move_army(main.ARTIFACT_POS + Vector3(-12, 0, 12))
	if frame == 2400 and is_instance_valid(main.hero):
		main.camera_rig.focus_on(main.hero.global_position)
		_shot("04_ruins")
		# The army fights the guardians while the wizard supports it with Fireballs from behind (she is the mission:
		# if she dies it is lost), then she walks to the crown.
		for u in _player_units():
			if u != main.hero:
				u.command_attack(_nearest_enemy_to(u.global_position)) if _nearest_enemy_to(u.global_position) else null
	if frame > 2400 and frame < 3600 and frame % 30 == 0 and is_instance_valid(main.hero) and main.hero.is_alive():
		_support_from_behind()
	if frame == 3600 and is_instance_valid(main.hero):
		print("Guardians left: %d, player=%d" % [_count(1), _count(0)])
		main.hero.command_move(main.ARTIFACT_POS)
	if main.game_over and frame % 60 == 0:
		_shot("05_end")
		print("GAME OVER at frame %d: victory=%s player=%d enemy=%d" % [frame, is_instance_valid(main.hero) and main.hero.is_alive(), _count(0), _count(1)])
		return true
	if frame > 6000:
		print("TIMEOUT: player=%d enemy=%d" % [_count(0), _count(1)])
		return true
	return false


# Ruins fight: Fireball the nearest guardian in range (16 m) when she can; step 10 m back toward the mid camp when
# she is under 40 % HP with an enemy close.
func _support_from_behind() -> void:
	var h = main.hero   # untyped: Wizard fields (hp, command_fireball)
	var e := _nearest_enemy_to(h.global_position)
	if e == null:
		return
	var d: float = e.global_position.distance_to(h.global_position)
	if h.hp < h.max_hp * 0.4 and d < 8.0:
		var back: Vector3 = (main.MID_CAMP - h.global_position)
		back.y = 0.0
		h.command_move(h.global_position + back.normalized() * 10.0)
	elif d <= 16.0:
		h.command_fireball(e.global_position)


func _player_units() -> Array:
	return root.get_tree().get_nodes_in_group("units").filter(func(u): return u.team == 0)


func _count(team: int) -> int:
	return root.get_tree().get_nodes_in_group("units").filter(func(u): return u.team == team).size()


func _nearest_enemy_to(pos: Vector3) -> Unit:
	var best: Unit = null
	var best_d := INF
	for u in root.get_tree().get_nodes_in_group("units"):
		if u.team == 1 and u.global_position.distance_to(pos) < best_d:
			best_d = u.global_position.distance_to(pos)
			best = u
	return best


func _move_army(center: Vector3) -> void:
	main.selection.select_units(_player_units())
	main.selection.formation_move(center)


func _shot(shot_name: String) -> void:
	if shots_dir == "":
		return
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [shots_dir, shot_name])
