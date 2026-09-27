extends SceneTree
## M7.U1: campaign UI. Briefing pauses and Begin unpauses; fake objective / dialogue events update the
## objectives panel (counter, countdown, done / failed) and the dialogue box (colour, queue, Enter skip, 5 s).
## Run:  godot --headless --path . -s tests/test_m7_u1.gd --fixed-fps 60 --quit-after 3000
## Windowed (no --headless): also saves screenshots to user://m7_u1_briefing.png and user://m7_u1_dialogue.png.

const TASK_ID := "M7.U1"
const TIMEOUT_FRAMES := 2400


class FakeMission extends Node:
	var progress := 0
	var hold_left := -1.0
	var states := {&"obj_braziers": "active", &"obj_crown": "hidden", &"obj_hold": "hidden",
			&"obj_vessa": "active", &"sec_peddler": "active", &"sec_outpost": "active"}

	func briefing() -> Dictionary:
		return {
			title = "The Crown in the Ashes",
			paragraphs = [
				"The God Wizard vanished between one breath and the next. He left four apprentices, four kingdoms and not one word of instruction. His regalia fell across the world like sparks from a kicked fire.",
				"One spark still glows: the Ember Crown, sealed in Emberfall, the Master's burnt-out observatory on the border between the Fire and Shadow kingdoms. Three old braziers hold the seal shut.",
				"Vessa, the youngest and least patient apprentice, rides out the night she hears of it. Malrik of Shadow got there first and is camped at the far end of the ruins. He cannot light a brazier. She can.",
			],
			objectives = ["Light the braziers of Emberfall (0 / 3)", "Claim the Ember Crown",
					"Survive Malrik's counterattack (2:00)"],
		}

	func objectives() -> Array:
		return [
			{id = &"obj_braziers", text = "Light the braziers of Emberfall", primary = true,
					state = states[&"obj_braziers"], progress = progress, goal = 3},
			{id = &"obj_crown", text = "Claim the Ember Crown", primary = true, state = states[&"obj_crown"]},
			{id = &"obj_hold", text = "Survive Malrik's counterattack (2:00)", primary = true,
					state = states[&"obj_hold"], time_left = hold_left},
			{id = &"obj_vessa", text = "Vessa must survive", primary = true, state = states[&"obj_vessa"]},
			{id = &"sec_peddler", text = "Free the Ruin Peddler", type = "secondary", state = states[&"sec_peddler"]},
			{id = &"sec_outpost", text = "Burn Malrik's Gloom Hall", type = "secondary", state = states[&"sec_outpost"]},
		]


var main: Node
var frame := 0
var _wait := 0
var mhud: Node
var fake: FakeMission
var events: Node
var step := 0
var step_frame := 0
var begun_count := 0
var windowed := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	windowed = DisplayServer.get_name() != "headless"


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			return _fail("navigation never finished baking")
		return false
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _fail("timed out at step %d" % step)
	return _run()


func _fail(reason: String) -> bool:
	paused = false
	print("FAIL %s: %s" % [TASK_ID, reason])
	return true


func _next_step() -> void:
	step += 1
	step_frame = frame


func _run() -> bool:
	var since := frame - step_frame
	match step:
		0:
			events = root.get_node("Events")
			fake = FakeMission.new()
			fake.name = "FakeMission"
			main.add_child(fake)
			mhud = load("res://scripts/ui/mission/mission_hud.gd").call("attach", main, fake, main.hud)
			mhud.begun.connect(func() -> void: begun_count += 1)
			_next_step()
		1:
			if since < 5:
				return false
			if not paused:
				return _fail("briefing did not pause the game")
			var b: Node = mhud.briefing
			if b == null or b.title_label.text.to_lower() != "the crown in the ashes":
				return _fail("briefing title missing")
			if b.paragraph_labels.size() != 3 or b.objective_labels.size() != 3:
				return _fail("briefing has %d paragraphs / %d objectives" % [b.paragraph_labels.size(), b.objective_labels.size()])
			if windowed and since < 30:
				return false
			_shot("briefing")
			b.begin_button.pressed.emit()
			_next_step()
		2:
			if since < 2:
				return false
			if paused:
				return _fail("Begin did not unpause")
			if begun_count != 1 or mhud.is_briefing_open():
				return _fail("begun not emitted / briefing still open")
			var p: Node = mhud.objectives_panel
			if p.row_text(&"obj_braziers") != "Light the braziers of Emberfall (0 / 3)":
				return _fail("counter row reads '%s'" % p.row_text(&"obj_braziers"))
			if p.row_text(&"obj_crown") != "":
				return _fail("hidden objective is shown")
			if not p.is_primary(&"obj_vessa") or p.is_primary(&"sec_peddler"):
				return _fail("primary / secondary split wrong")
			# Fake events: a brazier lit, the peddler freed, the crown active, the hold timer running.
			fake.progress = 1
			events.emit_signal(&"objective_changed", &"sec_peddler", &"done")
			events.emit_signal(&"objective_changed", &"obj_crown", &"active")
			fake.states[&"obj_hold"] = "active"
			fake.hold_left = 83.2
			events.emit_signal(&"objective_changed", &"obj_hold", &"active")
			events.emit_signal(&"dialogue", &"vessa", "One lit. Malrik, you still dress like a funeral that got lost on the way.")
			events.emit_signal(&"dialogue", &"malrik", "Light all the candles you like. The dark just gets a better view.")
			events.emit_signal(&"dialogue", &"narrator", "The Westwatch fire rises.")
			_next_step()
		3:
			var p: Node = mhud.objectives_panel
			var d: Node = mhud.dialogue_box
			if p.row_text(&"obj_braziers") != "Light the braziers of Emberfall (1 / 3)":
				return _fail("counter did not update: '%s'" % p.row_text(&"obj_braziers"))
			if p.row_state(&"sec_peddler") != &"done":
				return _fail("sec_peddler not done")
			if p.row_text(&"obj_crown") == "":
				return _fail("obj_crown did not appear")
			if p.row_text(&"obj_hold") != "Survive Malrik's counterattack (1:24)":
				return _fail("countdown reads '%s'" % p.row_text(&"obj_hold"))
			if not d.is_showing() or d.current_speaker() != &"vessa" or d.queued_count() != 2:
				return _fail("dialogue box: showing %s speaker %s queue %d" % [d.is_showing(), d.current_speaker(), d.queued_count()])
			if not d.name_color().is_equal_approx(Color(1.0, 0.45, 0.1)):
				return _fail("Vessa's name colour is %s" % d.name_color())
			if windowed and since < 40:
				return false
			_shot("dialogue")
			# Enter skips to Malrik.
			var key := InputEventKey.new()
			key.physical_keycode = KEY_ENTER
			key.keycode = KEY_ENTER
			key.pressed = true
			root.push_input(key)
			_next_step()
		4:
			var d: Node = mhud.dialogue_box
			if since < 2:
				return false
			if d.current_speaker() != &"malrik" or d.queued_count() != 1:
				return _fail("Enter did not skip (speaker %s)" % d.current_speaker())
			if not d.name_color().is_equal_approx(Color(0.7, 0.3, 1.0)):
				return _fail("Malrik's name colour is %s" % d.name_color())
			fake.hold_left = 5.0
			events.emit_signal(&"objective_changed", &"obj_vessa", &"failed")
			_next_step()
		5:
			var d: Node = mhud.dialogue_box
			# 5 s per line: Malrik still up at 4.5 s, narrator after 5.1 s.
			if since == 270 and d.current_speaker() != &"malrik":
				return _fail("line ended before 5 s")
			if since == 306 and d.current_speaker() != &"narrator":
				return _fail("line did not advance after 5 s (speaker %s)" % d.current_speaker())
			if since < 620:
				return false
			if d.is_showing() or d.queued_count() != 0:
				return _fail("queue did not empty")
			var p: Node = mhud.objectives_panel
			if p.row_state(&"obj_vessa") != &"failed":
				return _fail("obj_vessa not failed")
			if p.row_text(&"obj_hold") != "Survive Malrik's counterattack (0:05)":
				return _fail("countdown reads '%s'" % p.row_text(&"obj_hold"))
			print("objectives: %s | %s | %s" % [p.row_text(&"obj_braziers"), p.row_text(&"obj_hold"), p.row_state(&"obj_vessa")])
			print("PASS %s" % TASK_ID)
			return true
	return false


func _shot(tag: String) -> void:
	if not windowed:
		return
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://m7_u1_%s.png" % tag)
	img.save_png(path)
	print("screenshot: " + path)
