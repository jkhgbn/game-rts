extends SceneTree
## Regression test for the playtest report "clicking the map doesn't work".
## Everything goes through real input (Viewport.push_input, like the OS events), with the HUD
## visible, at 1600 x 900 and at 3440 x 1440 (the user's ultrawide):
## - nothing covers the minimap (it is the hovered control);
## - minimap left click moves the camera there, dragging keeps moving it;
## - X (attack-move) then a minimap left click = attack-move to that spot, camera unchanged;
##   right click on the minimap while targeting = cancel;
## - minimap right click moves the selected units there;
## - left click on a unit in the 3D view selects it; right click on the ground moves it.
## Run:  godot --headless --path . -s tests/test_fix_minimap_click.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "fix_minimap_click"
const SIZES := [Vector2i(1600, 900), Vector2i(3440, 1440)]
const STEP := 130   # frames per window size

var main: Node
var sel: Node
var minimap: Control
var frame := 0
var _wait := 0
var _error := ""
var _soldiers: Array = []
var _map_target := Vector3.ZERO
var _map_start := 0.0
var _unit: Node3D
var _ground_target := Vector3.ZERO
var _ground_start := 0.0


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
		sel = main.selection
		minimap = main.hud.minimap
		# Headless: the mouse sits at (0, 0), a screen corner, so edge-pan would drift the camera.
		main.camera_rig.edge_pan_enabled = false
		for u in root.get_tree().get_nodes_in_group("units"):
			if u.team == 0 and not u.is_in_group("heroes") and not u.has_method("command_gather"):
				_soldiers.append(u)
		if _soldiers.size() < 3:
			_error = "need 3 soldiers, found %d" % _soldiers.size()
	var index := (frame - 1) / STEP
	if _error == "" and index < SIZES.size():
		_step(index, (frame - 1) % STEP)
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if index >= SIZES.size():
		print("PASS %s" % TASK_ID)
		return true
	return false


func _step(index: int, t: int) -> void:
	var size: Vector2i = SIZES[index]
	var tag := "%dx%d" % [size.x, size.y]
	match t:
		0:
			root.size = size
		2:
			if root.get_visible_rect().size != Vector2(size):
				_error = "%s: viewport is %s" % [tag, root.get_visible_rect().size]
				return
			_minimap_checks(tag)
		60:
			if _map_start - _avg_distance(_map_target) < 2.0:
				_error = "%s: minimap right click did not move the units (%.1f -> %.1f)" % [
						tag, _map_start, _avg_distance(_map_target)]
				return
			# The minimap move is checked: stop that blob, or the soldier ordered below is still inside 8 walking
			# soldiers and their avoidance can hold him back (the flaky "6.4 -> 5.6" of the step-12 CI).
			for u in _soldiers:
				u.command_stop()
			# 3D view: the camera looks at a soldier, left click on him selects him.
			_unit = _soldiers[2]
			sel.select_units([])
			main.camera_rig.focus_on(_unit.global_position)
		62:
			var cam: Camera3D = main.camera_rig.camera
			var p: Vector2 = cam.unproject_position(_unit.global_position + Vector3.UP * 0.8)
			_click(p, MOUSE_BUTTON_LEFT)
			if sel.selected.size() != 1 or sel.selected[0] != _unit:
				_error = "%s: left click on a unit at %s selected %s" % [tag, p, sel.selected]
				return
			# Right click on the ground moves it.
			_ground_target = _unit.global_position + Vector3(5.0, 0.0, -4.0)
			_ground_start = _flat(_unit.global_position, _ground_target)
			_click(cam.unproject_position(_ground_target), MOUSE_BUTTON_RIGHT)
		120:
			var now := _flat(_unit.global_position, _ground_target)
			if _ground_start - now < 2.0:
				var agent: NavigationAgent3D = _unit.get(&"_agent")
				_error = "%s: right click on the ground did not move the unit (%.1f -> %.1f; attack_target %s, nav target %s)" % [
						tag, _ground_start, now, _unit.attack_target, agent.target_position if agent else Vector3.INF]


func _minimap_checks(tag: String) -> void:
	var rect: Rect2 = minimap.get_global_rect()
	var screen := root.get_visible_rect().size
	if rect.position.distance_to(Vector2(26, screen.y - 246)) > 1.5 or rect.size.distance_to(Vector2(220, 220)) > 1.5:
		_error = "%s: minimap at %s" % [tag, rect]
		return
	# Nothing above the minimap eats the mouse.
	var p := rect.position + Vector2(170, 40)
	_move(p)
	if root.gui_get_hovered_control() != minimap:
		_error = "%s: the control under the minimap point is %s" % [tag, root.gui_get_hovered_control()]
		return
	# Left click: camera goes there.
	main.camera_rig.focus_on(Vector3(-40, 0, 40))
	_button(p, MOUSE_BUTTON_LEFT, true)
	if not _camera_at(minimap.map_to_world(p - rect.position)):
		_error = "%s: minimap left click put the camera at %s" % [tag, main.camera_rig.position]
		return
	# Drag: the camera follows.
	var p2 := rect.position + Vector2(60, 150)
	_move(p2)
	_button(p2, MOUSE_BUTTON_LEFT, false)
	if not _camera_at(minimap.map_to_world(p2 - rect.position)):
		_error = "%s: minimap drag put the camera at %s" % [tag, main.camera_rig.position]
		return
	# After the release, moving over the minimap no longer moves the camera.
	var cam_before: Vector3 = main.camera_rig.position
	_move(rect.position + Vector2(200, 200))
	if main.camera_rig.position != cam_before:
		_error = "%s: the camera still follows the mouse after the release" % tag
		return
	# X then a minimap left click = attack-move there; the camera does not move.
	sel.select_units(_soldiers)
	_key(KEY_X)
	if sel.get_pending_order() != &"attack_move":
		_error = "%s: X did not start attack-move targeting" % tag
		return
	var am_point := Vector3(-20.0, 0.0, 20.0)
	_click(rect.position + minimap.world_to_map(am_point), MOUSE_BUTTON_LEFT)
	if sel.get_pending_order() != &"" or not _soldiers[0].is_attack_moving():
		_error = "%s: X + minimap click did not attack-move (pending '%s')" % [tag, sel.get_pending_order()]
		return
	if main.camera_rig.position != cam_before:
		_error = "%s: X + minimap click moved the camera" % tag
		return
	# Right click on the minimap while targeting cancels.
	_key(KEY_X)
	_click(rect.position + minimap.world_to_map(am_point), MOUSE_BUTTON_RIGHT)
	if sel.get_pending_order() != &"":
		_error = "%s: right click on the minimap did not cancel targeting" % tag
		return
	# Right click: the selected units walk there.
	_map_target = _soldiers[0].global_position + Vector3(8.0, 0.0, -8.0)
	_map_start = _avg_distance(_map_target)
	_click(rect.position + minimap.world_to_map(_map_target), MOUSE_BUTTON_RIGHT)


func _camera_at(world: Vector3) -> bool:
	var cam: Vector3 = main.camera_rig.position
	return Vector2(cam.x, cam.z).distance_to(Vector2(world.x, world.z)) < 0.5


func _avg_distance(target: Vector3) -> float:
	var total := 0.0
	for u in _soldiers:
		total += _flat(u.global_position, target)
	return total / maxf(1.0, _soldiers.size())


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _move(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	root.push_input(ev)


func _button(pos: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.position = pos
	ev.global_position = pos
	ev.pressed = pressed
	root.push_input(ev)


func _click(pos: Vector2, button: MouseButton) -> void:
	_move(pos)
	_button(pos, button, true)
	_button(pos, button, false)


func _key(physical: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = physical
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)
