extends SceneTree
## G-F building bars follow-up: the hover pick (SelectionManager, 20 Hz, one ray on layer 2) also passes the building
## under the cursor to set_hp_bar_hover, so its faded bar shows at full opacity; moving off fades it again; a unit
## standing in front of a building wins (never both hovered).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gf_hover_building.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "gf_hover_building"
const TIMEOUT_FRAMES := 3000

var main: Node
var _wait := 0
var _frame := 0
var _step := 0
var _t_ms := 0
var _step_frame := 0
var _sel: Node
var _tower: Building
var _keep: Building
var _unit: Unit
var _errors: Array[String] = []


func _initialize() -> void:
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
	_frame += 1
	if _frame == 1:
		_setup()
		return false
	if _run():
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if _frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d" % [TASK_ID, _step])
		return true
	return false


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _setup() -> void:
	_sel = main.get(&"selection")
	var grid: BuildGrid = main.get(&"build_grid")
	for n in get_nodes_in_group(&"buildings"):
		if n is Keep and int((n as Building).team) == Unit.Team.PLAYER:
			_keep = n
	_tower = grid.spawn_complete(BuildingType.find(&"fire_tower"), _keep.global_position + Vector3(14, 0, 0),
			Unit.Team.PLAYER)
	_tower.take_damage(_tower.max_hp * 0.2, null)   # a damaged, unselected bar: visible, fades to 35 %
	_sel.call(&"select_units", [])
	_t_ms = Time.get_ticks_msec()


func _cam() -> Camera3D:
	return _sel.get(&"camera") as Camera3D


func _point_mouse(world: Vector3) -> void:
	_sel.set(&"_mouse_pos", _cam().unproject_position(world))
	_step_frame = _frame


func _faded() -> bool:
	return _tower.hp_bar_opacity() <= Unit.HP_BAR_FADE_MIN + 0.01


func _run() -> bool:
	var now := Time.get_ticks_msec()
	match _step:
		0:
			# Wait for the hit flash to fade (real time, UnitFx.now()).
			if now - _t_ms < int((UnitFx.FADE_HOLD + UnitFx.FADE_TIME) * 1000.0) + 200:
				return false
			_expect(_faded(), "tower bar did not fade before the hover (%.2f)" % _tower.hp_bar_opacity())
			_cam().get_parent().set_process(false)   # no edge pan from the (headless) system cursor
			_sel.call(&"centre_camera_on", [_tower])
			_step_frame = _frame
			_step = 10
		10:
			if _frame - _step_frame < 30:   # the camera settles on the tower
				return false
			_point_mouse(_tower.global_position + Vector3.UP * 1.5)
			_step = 1
		1:
			if _frame - _step_frame < 10:   # a few 20 Hz hover ticks
				return false
			_expect(_sel.get(&"hovered_unit") == _tower, "hover target is not the tower (%s)" % str(_sel.get(&"hovered_unit")))
			_expect(is_equal_approx(_tower.hp_bar_opacity(), 1.0), "hovered: opacity %.2f" % _tower.hp_bar_opacity())
			# Move off onto empty ground away from the base.
			_point_mouse(_tower.global_position + Vector3(8, 0, 6))
			_step = 2
		2:
			if _frame - _step_frame < 10:
				return false
			_expect(_sel.get(&"hovered_unit") != _tower, "tower still hovered after moving off")
			_expect(_faded(), "moved off: bar did not fade back (%.2f)" % _tower.hp_bar_opacity())
			# A unit standing between the camera and the tower wins.
			for n in get_nodes_in_group(&"units"):
				var u := n as Unit
				if u != null and u.is_alive() and int(u.team) == Unit.Team.PLAYER and u != main.hero \
						and u.is_commandable():
					_unit = u
					break
			if _unit == null:
				_expect(false, "no player unit to stand in front of the tower")
				return true
			var to_cam := _cam().global_position - _tower.global_position
			to_cam.y = 0.0
			_unit.set_down(_tower.global_position + to_cam.normalized() * (_tower.target_radius() + 0.8))
			_unit.command_stop()
			_step_frame = _frame
			_step = 3
		3:
			if _frame - _step_frame < 5:
				return false
			_point_mouse(_unit.global_position + Vector3.UP * _unit.body_height * 0.5)
			_step = 4
		4:
			if _frame - _step_frame < 10:
				return false
			var hv: Variant = _sel.get(&"hovered_unit")
			_expect(hv == _unit, "unit in front of the tower is not the hover target (%s)" % str(hv))
			_expect(bool(_unit.get(&"_bar_hover")), "unit bar not in hover mode")
			_expect(not bool(_tower.get(&"_bar_hover")), "tower and unit hovered at once")
			_expect(_faded(), "tower bar not faded while the unit wins (%.2f)" % _tower.hp_bar_opacity())
			return true
	return false
