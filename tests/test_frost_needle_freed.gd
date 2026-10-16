extends SceneTree
## Frost Needle freed target (2026-10-15): a Hoarlight Magebow whose attack_target is freed mid-fight must not cast the
## freed object (`as Unit` on a freed node = "SCRIPT ERROR: Trying to cast a freed object" at new_units_12.gd
## _try_frost_needle). The real case: the target is freed inside a physics frame after the magebow's Unit dropped dead
## targets and before its NewUnits12 node ticks. A Freer child (first child of the magebow) frees the target right
## there; 36 magebows free on 36 consecutive frames so one lands on the 0.5 s ability tick. A Logger counts SCRIPT ERRORs.
## Run:  godot --headless --path . -s tests/test_frost_needle_freed.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "frost_needle_freed"
const PLAYER := 0
const ENEMY := 1
const TIMEOUT_FRAMES := 2400
const BOWS := 36
const RUN_FRAMES := 240   # 4 s after the last target is freed


class ScriptErrors:
	extends Logger
	var mutex := Mutex.new()
	var lines: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		if error_type != 2:   # ERROR_TYPE_SCRIPT ("SCRIPT ERROR")
			return
		mutex.lock()
		lines.append("%s:%d %s %s" % [file, line, function, rationale if rationale != "" else code])
		mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass


## Runs in the magebow's physics pass between the Unit and its ability node: frees the target on `at_frame`.
class Freer:
	extends Node
	var victim: Node
	var at_frame := 0
	var _frame := 0

	func _physics_process(_delta: float) -> void:
		_frame += 1
		if _frame == at_frame and is_instance_valid(victim):
			victim.free()


var main: Node
var frame := 0
var _wait := 0
var _errs := ScriptErrors.new()
var _bows: Array[Unit] = []
var _dummies: Array[Unit] = []
var _free_frames: Array[int] = []
var _end_frame := 0


func _initialize() -> void:
	OS.add_logger(_errs)
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
	if frame == _end_frame:
		return _verdict()
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _setup() -> void:
	var base: Vector3 = (main.hero as Node3D).global_position + Vector3(0, 0, 6)
	for i in BOWS:
		var p := base + Vector3(float(i % 6) * 3.0, 0, floorf(float(i) / 6.0) * 2.0)
		var d := _dummy(p + Vector3(0, 0, 30))   # out of needle range: the cooldown stays 0 until the free
		var mb := UnitType.find(&"hoarlight_magebow").create_unit()
		mb.team = PLAYER as Unit.Team
		main.add_child(mb)
		mb.global_position = p
		mb.command_attack(d)
		var f := Freer.new()
		f.victim = d
		f.at_frame = 10 + i   # frames 10-45 cover a whole 0.5 s tick
		mb.add_child(f)
		mb.move_child(f, 0)   # before the NewUnits12 node in the physics order
		_bows.append(mb)
		_dummies.append(d)
		_free_frames.append(10 + i)
	_end_frame = _free_frames[_free_frames.size() - 1] + RUN_FRAMES


## A punching bag: no damage, not auto-targeted by anything else.
func _dummy(pos: Vector3) -> Unit:
	var u := Unit.new()
	u.team = ENEMY as Unit.Team
	u.max_hp = 5000.0
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.hide_from_auto_target(9999.0)
	return u


func _verdict() -> bool:
	OS.remove_logger(_errs)
	var problems: Array[String] = []
	for l in _errs.lines:
		problems.append(l)
	for mb in _bows:
		if not is_instance_valid(mb) or not mb.is_alive():
			problems.append("a magebow died / was freed")
			continue
		if mb.attack_target != null and not is_instance_valid(mb.attack_target):
			problems.append("a magebow still points at a freed target")
	var ab: Variant = NewUnits12.ability_of(_bows[0]) if is_instance_valid(_bows[0]) else null
	if ab == null:
		problems.append("no NewUnits12 ability on the magebow")
	if problems.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %d problem(s): %s" % [TASK_ID, problems.size(), "; ".join(problems.slice(0, 5))])
	return true
