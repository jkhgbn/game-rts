extends SceneTree
## Test for 1.U4 (hotkeys): control groups (Ctrl+N set, Shift+N add, N select, N N centre camera),
## X + left click = attack-move (right click cancels), C = stop, H = hold (moved from A / S so that
## W A S D stay free for the wizard).
## Keys are sent as AZERTY would send them (physical position differs from the printed letter),
## so this also proves physical keycodes are used.
## Run:  godot --headless --path . -s tests/test_1_u4.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "1.u4"
const TIMEOUT_FRAMES := 900

var main: Node
var sel: Node
var frame := 0
var _wait := 0
var _soldiers: Array = []
var _group: Array = []
var _target := Vector3.ZERO
var _start_dist := 0.0
var _stop_dist := 0.0
var _error := ""
var _done := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 1:
		_setup()
	else:
		_step()
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _setup() -> void:
	sel = main.selection
	# Headless windows are 64 x 64, so HUD panels would cover every click: hide the HUD.
	main.hud.visible = false
	for u in root.get_tree().get_nodes_in_group("units"):
		if u.team == 0 and not u.is_in_group("heroes"):
			_soldiers.append(u)
	_group = _soldiers.slice(0, 5)
	sel.select_units(_group)
	_key(KEY_1, KEY_AMPERSAND, true, false)    # Ctrl+1 (AZERTY prints "&" on that key)
	sel.select_units([main.hero])
	_key(KEY_1, KEY_AMPERSAND)                 # 1 -> select group 1
	if sel.selected.size() != 5 or not sel.selected.has(_group[0]):
		_error = "1 selected %d units, expected group of 5" % sel.selected.size()


func _step() -> void:
	match frame:
		5:
			# Second press within 0.4 s: camera centres on the group.
			main.camera_rig.focus_on(Vector3(20, 0, -20))
			_key(KEY_1, KEY_AMPERSAND)
			var center := Vector3.ZERO
			for u in _group:
				center += u.global_position
			center /= 5.0
			var cam: Vector3 = main.camera_rig.position
			if Vector2(cam.x, cam.z).distance_to(Vector2(center.x, center.z)) > 0.5:
				_error = "double tap put camera at %s, expected %s" % [cam, center]
		40:
			# Slow second press: no camera jump. Shift+1 adds the hero.
			main.camera_rig.focus_on(Vector3(20, 0, -20))
			_key(KEY_1, KEY_AMPERSAND)
			if main.camera_rig.position.distance_to(Vector3(20, 0, -20)) > 0.1:
				_error = "a slow second press moved the camera"
				return
			sel.select_units([main.hero])
			_key(KEY_1, KEY_AMPERSAND, false, true)
			_key(KEY_2, KEY_2)                # empty group 2: selection unchanged
			sel.select_units([])
			_key(KEY_1, KEY_AMPERSAND)
			if sel.selected.size() != 6:
				_error = "Shift+1 should make group 1 hold 6 units, got %d" % sel.selected.size()
		45:
			# X then right click = cancelled, nothing ordered.
			sel.select_units(_soldiers)
			main.camera_rig.focus_on(_soldiers[0].global_position)
		47:
			_key(KEY_X, KEY_X)                     # X prints X on AZERTY too
			if not sel.is_attack_move_pending():
				_error = "X did not start attack-move targeting"
				return
			_click(Vector2(800, 450), MOUSE_BUTTON_RIGHT)
			if sel.is_attack_move_pending():
				_error = "right click did not cancel attack-move"
				return
			# X then left click on the ground = attack-move there.
			_target = _soldiers[0].global_position + Vector3(7.0, 0.0, -7.0)
			_start_dist = _avg_distance()
			_key(KEY_X, KEY_X)
			var screen: Vector2 = main.camera_rig.camera.unproject_position(_target)
			_click(screen, MOUSE_BUTTON_LEFT)
			if sel.is_attack_move_pending():
				_error = "left click did not confirm attack-move"
		110:
			if _start_dist - _avg_distance() < 2.0:
				_error = "attack-move: units did not walk to the point (%.1f -> %.1f)" % [_start_dist, _avg_distance()]
				return
			_key(KEY_C, KEY_C)                     # stop (C is the same on AZERTY)
			_stop_dist = _avg_distance()
		150:
			if absf(_avg_distance() - _stop_dist) > 1.0:
				_error = "C did not stop the units (%.1f -> %.1f)" % [_stop_dist, _avg_distance()]
				return
			_key(KEY_H, KEY_H)                     # hold must not error (with or without command_hold)
			_key(KEY_ESCAPE, KEY_ESCAPE)
		160:
			_done = true


func _key(physical: Key, printed: Key, ctrl := false, shift := false) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = printed
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _click(pos: Vector2, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)


func _avg_distance() -> float:
	var total := 0.0
	for u in _soldiers:
		total += Vector2(u.global_position.x, u.global_position.z).distance_to(Vector2(_target.x, _target.z))
	return total / max(1, _soldiers.size())
