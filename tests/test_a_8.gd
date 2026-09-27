extends SceneTree
## Task A.8: the polished Dusk Keep and Rime Keep instantiate headless and every art hook runs
## without errors (construction, selection, training pulse, damage states, heal, destroy, early free).
## Run: Godot --headless --path . -s tests/test_a_8.gd --fixed-fps 60 --quit-after 900

const SCENES: Array[String] = ["res://art/buildings/dusk_keep.tscn", "res://art/buildings/ice_keep.tscn"]
const HOOKS: Array[StringName] = [&"set_team_color", &"set_construction_progress", &"set_health_ratio",
	&"play_training_pulse", &"play_destroyed", &"set_selected"]

var _keeps: Array = []
var _frame: int = 0
var _finished: int = 0
var _ok: bool = true


func _initialize() -> void:
	for path: String in SCENES:
		var k: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		for h: StringName in HOOKS:
			if not k.has_method(h):
				_fail("%s lacks %s" % [path, h])
		# Hooks before _ready must be cached.
		k.call(&"set_team_color", Color(0.9, 0.2, 0.2))
		k.call(&"set_construction_progress", 0.0)
		root.add_child(k)
		k.connect(&"destroyed_finished", func() -> void: _finished += 1)
		_keeps.append(k)



func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 5:
		# Extra instances freed mid-collapse must not error.
		for i: int in 2:
			var early: Node3D = (load(SCENES[i]) as PackedScene).instantiate() as Node3D
			root.add_child(early)
	if _frame == 8:
		var n: int = 0
		for c: Node in root.get_children():
			if c is Node3D and not (c in _keeps):
				c.call(&"play_destroyed")
				create_timer(0.7 + 0.4 * n).timeout.connect(c.queue_free)
				n += 1
	for k: Node3D in _keeps:
		match _frame:
			10: k.call(&"set_construction_progress", 0.5)
			40: k.call(&"set_construction_progress", 1.0)
			60: k.call(&"set_selected", true)
			80: k.call(&"set_selected", false)
			90: k.call(&"play_training_pulse")
			95: k.call(&"play_training_pulse")
			120: k.call(&"set_health_ratio", 0.4)
			150: k.call(&"set_health_ratio", 0.2)
			180: k.call(&"set_health_ratio", 1.0)
			200: k.call(&"set_health_ratio", 0.1)
			220: k.call(&"play_destroyed")
	if _frame == 500:
		if _finished != _keeps.size():
			_fail("destroyed_finished emitted %d / %d" % [_finished, _keeps.size()])
		print(("PASS" if _ok else "FAIL") + " A.8 keeps: art hooks")
		return true
	return false


func _fail(msg: String) -> void:
	_ok = false
	printerr("A.8 FAIL: ", msg)
