extends SceneTree
## Template for a per-task test. Copy it to tests/test_<task-id>.gd (for example test_1_s1.gd).
## Run:  godot --headless --path . -s tests/test_<task-id>.gd --fixed-fps 60 --quit-after 3000
## Rules:
## - Always pass --quit-after so a script error cannot hang the run.
## - Don't use autoload names (Events...) here: test scripts compile before autoloads exist.
##   Use root.get_node("Events") instead.
## - Print one line "PASS <task-id>" or "FAIL <task-id>: <reason>" at the end.

const TASK_ID := "x.y"
const TIMEOUT_FRAMES := 2400

var main: Node
var frame := 0
var _wait := 0


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
	if _check_done():
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _setup() -> void:
	pass   # give orders, spawn things...


func _check_done() -> bool:
	return false   # return true when the task's "done when" is met
