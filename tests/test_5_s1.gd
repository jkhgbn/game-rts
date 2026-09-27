extends SceneTree
## Task 5.S1: fog of war core (docs/design/fog-of-war.md). Skirmish map, Shadow bot off.
## Run:  godot --headless --path . -s tests/test_5_s1.gd --fixed-fps 60 --quit-after 3000
## Add  shot=<file.png>  after  --  (and run without --headless) to save a screenshot at the start.
## Checks: start states; an enemy Shade out of sight is hidden; it shows when a Flame Guard walks near;
## a seen enemy building leaves a ghost once its area goes dark; F11 turns the fog off and on.

const TASK_ID := "5.S1"
const TIMEOUT_FRAMES := 2400
const SCENE := "res://scenes/skirmish.tscn"
const SHADE_POS := Vector3(-6.0, 0.0, 16.0)
const GUARD_POS := Vector3(-26.0, 0.0, 26.0)
const HOVEL_POS := Vector3(-24.0, 0.0, -6.0)

var main: Node
var fog: Node
var frame := 0
var _wait := 0
var _phase := 0
var _phase_frame := 0
var _errors: Array[String] = []
var _shade: Node3D
var _guard: Node3D
var _hovel: Node3D
var _shot := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shot="):
			_shot = arg.substr(5)
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 3000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	var done := _step()
	if done or frame > TIMEOUT_FRAMES:
		if not done:
			_errors.append("timed out in phase %d" % _phase)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _next(phase: int) -> void:
	_phase = phase
	_phase_frame = frame


func _step() -> bool:
	var t := frame - _phase_frame
	match _phase:
		0:   # wait for a couple of 5 Hz passes, check the start
			if t < 30:
				return false
			fog = main.get("fog")
			if fog == null or not fog.is_in_group("fog"):
				_errors.append("main.fog missing")
				return true
			_expect(fog.state_at(0, main.PLAYER_START) == 2, "start not VISIBLE")
			_expect(fog.state_at(0, main.SHADOW_START) == 0, "Shadow start not UNEXPLORED for the player")
			_expect(fog.state_at(1, main.SHADOW_START) == 2, "Shadow start not VISIBLE for the enemy")
			_expect(fog.state_at(0, main.PLAYER_START + Vector3(19.0, 0.0, 0.0)) != 0, "20 m start circle not explored")
			_expect(main.hero.visible, "own wizard hidden")
			_expect(not main.shadow_keep.visible, "enemy keep visible through the fog")
			_expect(not main.crown.visible, "crown visible while unexplored")
			var img: Image = fog.grid_image(0)
			_expect(img != null and img.get_width() == 60 and img.get_height() == 60, "grid_image not 60 x 60")
			_shade = main.make_unit("shade")
			_add(_shade, 1, SHADE_POS)
			_guard = main.make_unit("flame_guard")
			_add(_guard, 0, GUARD_POS)
			_take_shot()
			_next(1)
		1:
			if t < 20:
				return false
			_expect(not _shade.visible, "Shade 36 m away is visible")
			_expect(_shade.is_in_group("units"), "hidden Shade left the units group")
			_guard.command_move(SHADE_POS + Vector3(-4.0, 0.0, 2.0))
			_next(2)
		2:   # the guard walks in
			if _guard.global_position.distance_to(_shade.global_position) > 8.0:
				if t > 900:
					_errors.append("guard never reached the Shade")
					return true
				return false
			_next(3)
		3:
			if t < 20:
				return false
			_expect(_shade.visible, "Shade not visible with a Flame Guard %.1f m away" %
					_guard.global_position.distance_to(_shade.global_position))
			_shade.take_damage(99999.0, null)
			_hovel = main.build_grid.spawn_complete(load("res://data/buildings/shadow_hovel.tres"), HOVEL_POS, 1)
			_guard.command_stop()
			_guard.global_position = HOVEL_POS + Vector3(0.0, 0.0, 7.0)
			_next(4)
		4:
			if t < 20:
				return false
			_expect(_hovel.visible, "hovel not visible with the guard next to it")
			_expect(get_nodes_in_group("fog_ghosts").is_empty(), "ghost while the hovel is in sight")
			_guard.global_position = main.PLAYER_START + Vector3(4.0, 0.0, -4.0)
			_guard.command_stop()
			_next(5)
		5:
			if t < 20:
				return false
			_expect(not _hovel.visible, "hovel still visible after the guard left")
			_expect(fog.state_at(0, HOVEL_POS) == 1, "hovel cell not EXPLORED after the guard left")
			_expect(get_nodes_in_group("fog_ghosts").size() == 1, "expected 1 ghost, got %d" %
					get_nodes_in_group("fog_ghosts").size())
			_press_f11()
			_next(6)
		6:
			if t < 3:
				return false
			_expect(not fog.enabled, "F11 did not turn the fog off")
			_expect(_hovel.visible and main.shadow_keep.visible, "fog off: enemy buildings still hidden")
			_expect(get_nodes_in_group("fog_ghosts").is_empty(), "fog off: ghosts still there")
			_expect(fog.is_visible(0, main.SHADOW_START), "fog off: is_visible false")
			_press_f11()
			_next(7)
		7:
			if t < 20:
				return false
			_expect(fog.enabled, "second F11 did not turn the fog back on")
			_expect(not main.shadow_keep.visible, "fog back on: enemy keep visible")
			return true
	return false


func _add(u: Node3D, team: int, pos: Vector3) -> void:
	u.set(&"team", team)
	main.add_child(u)
	u.global_position = pos
	u.call(&"command_stop")


func _press_f11() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_F11
	ev.keycode = KEY_F11
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _take_shot() -> void:
	if _shot == "" or DisplayServer.get_name() == "headless":
		return
	main.camera_rig.focus_on(main.PLAYER_START + Vector3(12.0, 0.0, -12.0))
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(_shot)
	print("screenshot: ", _shot)


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)
