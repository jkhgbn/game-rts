extends SceneTree
## WS2.C3 (docs/design/wave-strike.md 14.2 P4): the Wave Strike level creates the UnitGrid (WS only), and a dead lane
## unit's corpse leaves the tree within 2 s (CORPSE_TIME) while a living one stays.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws2_c3.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "ws2_c3"
const SCENE := "res://scenes/wave_strike.tscn"

var level: Node
var _frames := 0
var _dead_ref: WeakRef
var _alive: Unit
var _kill_frame := -1
var _fails: Array[String] = []


func _initialize() -> void:
	level = (load(SCENE) as PackedScene).instantiate()
	var rules := WaveStrikeRules.load_default()
	rules.horn_first = 100000.0
	rules.time_limit = 0.0
	level.set(&"rules", rules)
	level.set(&"autopilot_player", true)
	level.set(&"wizards_enabled", false)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 2500:
		return _end("timed out")
	if level.get(&"director") == null:
		return false
	if _kill_frame < 0:
		var grid := UnitGrid.current()
		if grid == null or grid.get_parent() != level:
			_fails.append("no UnitGrid under the WS level")
		var gate: Vector3 = level.call(&"gate_position", 0)
		var a: Unit = level.call(&"spawn_lane_unit", 0, &"flame_guard", gate + Vector3(4, 0, 0), 0.0)
		_alive = level.call(&"spawn_lane_unit", 0, &"flame_guard", gate + Vector3(4, 0, 3), 0.0)
		if a == null or _alive == null:
			return _end("spawn_lane_unit returned null")
		a.take_damage(1.0e6, null)
		if a.is_alive():
			return _end("the lane unit did not die")
		_dead_ref = weakref(a)
		_kill_frame = _frames
		return false
	var since := _frames - _kill_frame
	var dead := _dead_ref.get_ref() as Node
	if dead == null or not dead.is_inside_tree():
		if not is_instance_valid(_alive) or not _alive.is_alive():
			_fails.append("the living lane unit was removed too")
		print("ws2_c3: corpse gone %.2f s after death" % (since / 60.0))
		return _end("")
	if since > 2.0 * 60 + 6:
		return _end("corpse still in the tree %.2f s after death" % (since / 60.0))
	return false


func _end(reason: String) -> bool:
	if reason != "":
		_fails.append(reason)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)
	return true
