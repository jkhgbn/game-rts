extends SceneTree
## Test for 1.U3 (minimap): placement, 10 Hz redraw, left click moves the camera,
## right click moves the selected units, world <-> map mapping.
## Run:  godot --headless --path . -s tests/test_1_u3.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "1.u3"
const TIMEOUT_FRAMES := 600

var main: Node
var frame := 0
var _wait := 0
var _minimap: Control
var _draws_at_start := 0
var _soldiers: Array = []
var _move_target := Vector3(-25.0, 0.0, 10.0)   # map point clear of the (squashed) headless HUD panels
var _start_dist := 0.0
var _error := ""


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
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _check_done():
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out (%s)" % [TASK_ID, _status()])
		return true
	return false


func _setup() -> void:
	_minimap = main.hud.minimap
	if _minimap == null:
		_error = "GameHUD has no minimap"
		return
	_draws_at_start = _minimap.redraw_count
	# Mapping: map centre = world origin, corners = +-60 m.
	var c: Vector2 = _minimap.world_to_map(Vector3.ZERO)
	if not c.is_equal_approx(Vector2(100, 100)):
		_error = "world origin maps to %s, expected (100, 100)" % c
		return
	var w: Vector3 = _minimap.map_to_world(Vector2(200, 0))
	if not w.is_equal_approx(Vector3(60, 0, -60)):
		_error = "map (200, 0) maps to %s, expected (60, 0, -60)" % w
		return


func _check_done() -> bool:
	if frame == 5:
		# SC2.U1 (ui-sc2-console.md 1): 200 x 200 at (14, 692) on a 1600 x 900 screen, anchored bottom-left. Headless
		# windows are 64 x 64, so check it relative to the bottom edge: 900 - 692 = 208 px above it.
		var rect: Rect2 = _minimap.get_global_rect()
		var expected := Vector2(14, root.get_visible_rect().size.y - 208)
		if rect.position.distance_to(expected) > 1.5 or rect.size.distance_to(Vector2(200, 200)) > 1.5:
			_error = "minimap draw area at %s, expected %s 200 x 200" % [rect, expected]
			return false
		# Left click on the map: the camera centres on that world point.
		var target := Vector3(30.0, 0.0, -30.0)
		_click(rect.position + _minimap.world_to_map(target), MOUSE_BUTTON_LEFT)
		var cam_pos: Vector3 = main.camera_rig.position
		if Vector2(cam_pos.x, cam_pos.z).distance_to(Vector2(target.x, target.z)) > 1.0:
			_error = "left click moved camera to %s, expected %s" % [cam_pos, target]
			return false
	if frame == 10:
		# Right click on the map: selected soldiers move there.
		for u in root.get_tree().get_nodes_in_group("units"):
			if u.team == 0 and not u.is_in_group("heroes"):
				_soldiers.append(u)
		main.selection.select_units(_soldiers)
		_start_dist = _avg_distance()
		var rect: Rect2 = _minimap.get_global_rect()
		_click(rect.position + _minimap.world_to_map(_move_target), MOUSE_BUTTON_RIGHT)
	if frame == 70:
		# 69 frames at 60 fps = 1.15 s -> about 12 redraws (+ a few forced by clicks); every frame would be 69.
		var draws: int = _minimap.redraw_count - _draws_at_start
		if draws < 6 or draws > 20:
			_error = "minimap redrew %d times in ~1.2 s, expected ~10 Hz" % draws
			return false
	if frame >= 180:
		return _start_dist - _avg_distance() > 4.0
	return false


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
		total += Vector2(u.global_position.x, u.global_position.z).distance_to(Vector2(_move_target.x, _move_target.z))
	return total / max(1, _soldiers.size())


func _status() -> String:
	return "draws=%d start_dist=%.1f now=%.1f" % [_minimap.redraw_count - _draws_at_start, _start_dist, _avg_distance()]
