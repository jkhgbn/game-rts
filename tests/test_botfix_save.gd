extends SceneTree
## Bot review 2026-10-12 D2: SaveWorld.capture leaves Magpies (group "magpies") and trackers (group "trackers") out,
## because their ThiefBand / TrackerContract brains are not saved (they came back as idle orphans after a load and
## blocked the guilds). Skirmish: tag two living units, capture, the unit rows drop by exactly 2 and neither tagged
## unit is in them; other units are still saved.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_botfix_save.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "botfix_save"
const TIMEOUT_FRAMES := 5000

var level: Node
var frame := 0
var _done := false


func _initialize() -> void:
	level = load("res://scenes/skirmish.tscn").instantiate()
	level.set(&"time_limit_s", 0.0)
	root.add_child(level)
	current_scene = level


func _process(_delta: float) -> bool:
	if _done:
		return true
	frame += 1
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		_done = true
		return true
	if frame < 240:   # let the skirmish spawn its keeps, workers and wizards
		return false
	_check()
	_done = true
	return true


func _check() -> void:
	var living: Array[Unit] = []
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u != null and u.is_alive() and not (u is Wizard) and not u.is_in_group(&"champions"):
			living.append(u)
	if living.size() < 3:
		print("FAIL %s: only %d plain living units to tag" % [TASK_ID, living.size()])
		return
	var before: int = (SaveWorld.capture(level)["units"] as Array).size()
	var magpie: Unit = living[0]
	var tracker: Unit = living[1]
	magpie.add_to_group(&"magpies")
	tracker.add_to_group(&"trackers")
	var rows: Array = SaveWorld.capture(level)["units"]
	if rows.size() != before - 2:
		print("FAIL %s: unit rows %d before tagging, %d after (expected %d)" % [TASK_ID, before, rows.size(), before - 2])
		return
	var positions: Array[Vector3] = []
	for r: Dictionary in rows:
		var p: Variant = r.get("pos", r.get("position", null))
		if p is Vector3:
			positions.append(p)
	for tagged: Unit in [magpie, tracker]:
		for p in positions:
			if p.is_equal_approx(tagged.global_position) and positions.count(p) == 1:
				print("FAIL %s: a tagged unit's row is still saved at %s" % [TASK_ID, p])
				return
	if rows.is_empty():
		print("FAIL %s: no unit saved at all" % TASK_ID)
		return
	print("PASS %s: %d unit rows -> %d with one Magpie and one tracker left out" % [TASK_ID, before, rows.size()])
