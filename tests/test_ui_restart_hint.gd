extends SceneTree
## Playtest fix 2026-09-27: the end screen has Restart (F9) / Main menu buttons and Restart reloads the level;
## the skirmish "Next: ..." hint follows the player's state (no Hall -> build the Hall; Hall done -> train).
## Run:  godot --headless --path . -s tests/test_ui_restart_hint.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "ui_restart_hint"
const TIMEOUT_FRAMES := 5000

var main: Node
var frame := 0
var step := 0
var _wait := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	match step:
		0:
			var r := _check_hint()
			if r != "":
				return _finish(r)
			step = 1
		1:
			if main.get("hero") == null:
				return false
			var hud: Node = main.get("hud")
			if hud == null:
				return _finish("no HUD")
			if hud.get("next_step_hint") != null:
				return _finish("the next-step hint should not show in a mission")
			hud.call(&"show_banner", "DEFEAT", Color(0.9, 0.3, 0.3))
			var b := hud.get("end_restart_button") as Button
			var m := hud.get("end_menu_button") as Button
			if b == null or not b.is_visible_in_tree():
				return _finish("no visible Restart button on the defeat screen")
			if not b.text.contains("F9"):
				return _finish("Restart button does not show F9 (%s)" % b.text)
			if m == null or not m.is_visible_in_tree() or not m.text.to_lower().contains("menu"):
				return _finish("no visible Main menu button on the defeat screen")
			b.pressed.emit()
			step = 2
		2:
			_wait += 1
			if _wait < 5:
				return false
			var lv: Node = current_scene
			if lv == null or lv == main or not is_instance_valid(lv):
				return _wait > 600 and _finish("Restart did not reload the level")
			if paused:
				return _finish("still paused after restart")
			# The hint in a real skirmish (fire vs shadow).
			main = MenuFlow.start_skirmish(self, 0, &"shadow", &"fire")
			_wait = 0
			step = 3
		3:
			_wait += 1
			if main.get("hero") == null or _wait < 30:
				return _wait > 3000 and _finish("skirmish never spawned the hero")
			var hud: Node = main.get("hud")
			var hint: Node = hud.get("next_step_hint") if hud else null
			if hint == null:
				return _finish("no next-step hint in the skirmish")
			var text := (hint.get("label") as Label).text
			print("skirmish hint: ", text, "  at ", (hint as Control).position)
			if not text.begins_with("Next: ") or not (hint as Control).is_visible_in_tree():
				return _finish("skirmish hint not shown (%s)" % text)
			return _finish("")
	return false


## The hint on its own (fire kingdom, player team): "build the Ember Hall" until a Hall is completed, then "train".
func _check_hint() -> String:
	var script := load("res://scripts/ui/next_step_hint.gd") as Script
	if script == null:
		return "next_step_hint.gd missing"
	NextStepHint.dismissed = false
	var hint: Node = script.new()
	hint.set(&"kingdom", &"fire")
	hint.set(&"team", 0)
	root.add_child(hint)
	hint.call(&"refresh")
	var label := hint.get("label") as Label
	var before := label.text
	print("hint before: ", before)
	if not before.contains("Ember Hall") or not before.contains("B then X") or not before.contains("150"):
		return "first hint should say how to build the Ember Hall (%s)" % before
	var bt: Resource = load("res://data/buildings/fire_barracks.tres")
	var hall: Node3D = BuildGrid.create_building(bt)
	hall.set(&"team", 0)
	hall.position = Vector3(500, 0, 500)
	root.add_child(hall)
	if not bool(hall.call(&"is_constructed")):
		return "the test Hall is not completed"
	hint.call(&"refresh")
	var after := label.text
	print("hint after: ", after)
	if after == before or not after.contains("train soldiers"):
		return "hint did not move on after the Hall was completed (%s)" % after
	for t in [before, after]:
		if t.contains("T2") or t.to_lower().contains("tier"):
			return "the hint must never talk about tiers"
	# Click hides it.
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	hint.call(&"_gui_input", ev)
	if (hint as Control).visible:
		return "clicking the hint did not hide it"
	NextStepHint.dismissed = false
	hall.queue_free()
	hint.queue_free()
	return ""


func _finish(reason: String) -> bool:
	paused = false
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
