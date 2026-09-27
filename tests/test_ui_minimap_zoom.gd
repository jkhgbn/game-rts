extends SceneTree
## Minimap zoom (JS request 2026-09-27), mission 1 map at 1600 x 900, through real input (Viewport.push_input):
## - zoom starts at 1x (the whole map, world (0, 0) at the minimap centre);
## - the wheel over the minimap zooms it 1x -> 3x in steps of 0.5 around the mouse (the world point under the mouse
##   stays there), clamped to 3x, the view clamped to the map; wheel down goes back to 1x (centred again);
##   the 3D camera does not zoom while the wheel is over the minimap, and still zooms with the wheel elsewhere;
## - zoomed in: left click moves the camera to the clicked world point, X + click attack-moves there, right click
##   moves the selected units there;
## - zoomed in, the view follows the camera when it moves out of the middle of the view.
## Run: godot --headless --path . -s tests/test_ui_minimap_zoom.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "ui_minimap_zoom"

var main: Node
var sel: Node
var minimap: Minimap
var frame := 0
var _wait := 0
var _error := ""
var _soldiers: Array = []
var _rect := Rect2()
var _move_target := Vector3.ZERO
var _move_start := 0.0


func _initialize() -> void:
	root.size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_step(frame)
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if frame >= 80:
		print("PASS %s" % TASK_ID)
		return true
	return false


func _step(t: int) -> void:
	match t:
		1:
			sel = main.selection
			minimap = main.hud.minimap
			main.camera_rig.edge_pan_enabled = false   # headless mouse at (0, 0) would pan
			for u in get_nodes_in_group("units"):
				if u.team == 0 and not u.is_in_group("heroes") and not u.has_method("command_gather"):
					_soldiers.append(u)
			if _soldiers.size() < 3:
				_error = "need 3 soldiers, found %d" % _soldiers.size()
		3:
			_rect = minimap.get_global_rect()
			_check_wheel()
		5:
			_check_clicks()
		60:
			var now := _avg_distance(_move_target)
			if _move_start - now < 2.0:
				_error = "zoomed minimap right click did not move the units (%.1f -> %.1f)" % [_move_start, now]
				return
			for u in _soldiers:
				u.command_stop()
			# Follow: zoomed 3x, the camera jumps to a far corner; the view slides so the camera is inside it.
			minimap.set_zoom(3.0)
			minimap.center_view_on(Vector3.ZERO)
			main.camera_rig.focus_on(Vector3(-50.0, 0.0, 50.0))
		63:
			var cam: Vector3 = main.camera_rig.global_position
			var span: float = minimap.map_size * 0.5 / minimap.zoom
			var off := Vector2(cam.x, cam.z) - minimap.view_center
			if absf(off.x) > span or absf(off.y) > span:
				_error = "zoomed view did not follow the camera (centre %s, camera %s)" % [minimap.view_center, cam]
				return
			var room: float = minimap.map_size * 0.5 - span
			if absf(minimap.view_center.x) > room + 0.01 or absf(minimap.view_center.y) > room + 0.01:
				_error = "followed view left the map: %s" % minimap.view_center
				return
			var p: Vector2 = minimap.world_to_map(cam)
			if not Rect2(Vector2.ZERO, Vector2(Minimap.SIZE, Minimap.SIZE)).has_point(p):
				_error = "the camera is at %s on the zoomed minimap" % p
				return
			var draws: int = minimap.redraw_count
			minimap.queue_redraw()
			set_meta(&"draws", draws)
		66:
			if minimap.redraw_count <= int(get_meta(&"draws")):
				_error = "the zoomed minimap did not redraw"
				return
			minimap.set_zoom(1.0)
			if minimap.view_center != Vector2.ZERO:
				_error = "back at 1x the view is not centred: %s" % minimap.view_center


func _check_wheel() -> void:
	if not is_equal_approx(minimap.zoom, 1.0) or minimap.world_to_map(Vector3.ZERO).distance_to(Vector2(110, 110)) > 0.01:
		_error = "minimap does not start at 1x centred (zoom %.2f)" % minimap.zoom
		return
	var cam_zoom: float = main.camera_rig.get(&"_target_zoom")
	var local := Vector2(170, 40)
	var before: Vector3 = minimap.map_to_world(local)
	_wheel(_rect.position + local, MOUSE_BUTTON_WHEEL_UP)
	if not is_equal_approx(minimap.zoom, 1.5):
		_error = "wheel up over the minimap: zoom %.2f (want 1.5)" % minimap.zoom
		return
	var after: Vector3 = minimap.map_to_world(local)
	if Vector2(before.x, before.z).distance_to(Vector2(after.x, after.z)) > 0.05:
		_error = "zoom is not around the mouse: %s -> %s" % [before, after]
		return
	if not is_equal_approx(float(main.camera_rig.get(&"_target_zoom")), cam_zoom):
		_error = "the wheel over the minimap also zoomed the 3D camera"
		return
	for i in 6:
		_wheel(_rect.position + local, MOUSE_BUTTON_WHEEL_UP)
	if not is_equal_approx(minimap.zoom, Minimap.ZOOM_MAX):
		_error = "zoom not clamped to 3x: %.2f" % minimap.zoom
		return
	var room: float = minimap.map_size * 0.5 - minimap.map_size * 0.5 / minimap.zoom
	if absf(minimap.view_center.x) > room + 0.01 or absf(minimap.view_center.y) > room + 0.01:
		_error = "zoomed view outside the map: %s (room %.1f)" % [minimap.view_center, room]
		return
	# A corner of the zoomed minimap is still on the map.
	var corner: Vector3 = minimap.map_to_world(Vector2(Minimap.SIZE, 0))
	if absf(corner.x) > minimap.map_size * 0.5 + 0.01 or absf(corner.z) > minimap.map_size * 0.5 + 0.01:
		_error = "zoomed minimap shows off the map: %s" % corner
		return
	for i in 6:
		_wheel(_rect.position + local, MOUSE_BUTTON_WHEEL_DOWN)
	if not is_equal_approx(minimap.zoom, 1.0) or minimap.view_center != Vector2.ZERO:
		_error = "wheel down: zoom %.2f, centre %s (want 1x, centred)" % [minimap.zoom, minimap.view_center]
		return
	# The wheel elsewhere still zooms the 3D camera (and not the minimap).
	_wheel(Vector2(800, 300), MOUSE_BUTTON_WHEEL_UP)
	if is_equal_approx(float(main.camera_rig.get(&"_target_zoom")), cam_zoom) and cam_zoom > main.camera_rig.min_zoom:
		_error = "the wheel in the 3D view no longer zooms the camera"
		return
	if not is_equal_approx(minimap.zoom, 1.0):
		_error = "the wheel in the 3D view zoomed the minimap"


func _check_clicks() -> void:
	minimap.set_zoom(2.0)
	var target: Vector3 = _soldiers[0].global_position + Vector3(8.0, 0.0, -8.0)
	minimap.center_view_on(target)
	# Left click: the camera goes to the clicked world point.
	var local := Vector2(150, 70)
	var world: Vector3 = minimap.map_to_world(local)
	_click(_rect.position + local, MOUSE_BUTTON_LEFT)
	var cam: Vector3 = main.camera_rig.position
	if Vector2(cam.x, cam.z).distance_to(Vector2(world.x, world.z)) > 0.5:
		_error = "zoomed left click put the camera at %s, want %s" % [cam, world]
		return
	# X + click = attack-move there; the camera does not move.
	minimap.center_view_on(target)
	sel.select_units(_soldiers)
	_key(KEY_X)
	if sel.get_pending_order() != &"attack_move":
		_error = "X did not start attack-move targeting"
		return
	var am_point := target + Vector3(-3.0, 0.0, 2.0)
	_click(_rect.position + minimap.world_to_map(am_point), MOUSE_BUTTON_LEFT)
	if sel.get_pending_order() != &"" or not _soldiers[0].is_attack_moving():
		_error = "X + zoomed minimap click did not attack-move"
		return
	var goal: Vector3 = _soldiers[0].get("_attack_move_target")
	if _flat(goal, am_point) > 4.5:
		_error = "X + zoomed minimap click: goal %s is not near %s" % [goal, am_point]
		return
	if main.camera_rig.position != cam:
		_error = "X + zoomed minimap click moved the camera"
		return
	# Right click: the selected units walk there.
	for u in _soldiers:
		u.command_stop()
	_move_target = target
	_move_start = _avg_distance(target)
	_click(_rect.position + minimap.world_to_map(target), MOUSE_BUTTON_RIGHT)


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


func _wheel(pos: Vector2, button: MouseButton) -> void:
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
