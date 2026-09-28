extends SceneTree
## Asset trial: Dialogue Manager (addons/dialogue_manager). Compiles tests/asset_trials/ep5_intro_trial.dialogue
## (an Ep 5 style Vessa / Malrik intro with 3 choices, a conditional choice, state and a mutation) at runtime,
## walks every branch headless and prints the lines as they would reach the game's own dialogue path
## (Events.dialogue(speaker, text) -> DialogueBox.say). The project does not register the DialogueManager
## autoload (the plugin adds it only when enabled from the editor), so the manager node is created here.
## Headless:  tools\godot_run.ps1 --headless --path . -s tests/asset_trials/trial_dialogue.gd --quit-after 3000

const SRC := "res://tests/asset_trials/ep5_intro_trial.dialogue"


## Game state the dialogue reads and writes (in the game this would be the mission script).
class MissionState extends Node:
	var trust := 0
	var embers := 4
	var forge_lit := false

	func light_forge() -> void:
		forge_lit = true


var dm: Node


func _initialize() -> void:
	_run()


func _run() -> void:
	print("autoload DialogueManager in project.godot: %s" % ProjectSettings.has_setting("autoload/DialogueManager"))
	dm = (load("res://addons/dialogue_manager/dialogue_manager.gd") as GDScript).new()
	dm.name = "DialogueManager"
	root.add_child(dm)
	var text := FileAccess.get_file_as_string(SRC)
	var t0 := Time.get_ticks_usec()
	var res: Resource = dm.create_resource_from_text(text)
	print("compile: %.2f ms, cues=%s" % [(Time.get_ticks_usec() - t0) / 1000.0, str(res.get(&"cues"))])
	var ok := true
	for choice in 3:
		var st := MissionState.new()
		root.add_child(st)
		print("--- branch %d (trust=%d embers=%d)" % [choice, st.trust, st.embers])
		var n := await _walk(res, st, choice)
		print("--- end branch %d: %d lines, trust=%d forge_lit=%s" % [choice, n, st.trust, st.forge_lit])
		if n < 4:
			ok = false
		st.queue_free()
	# The conditional choice disappears when the state says so.
	var st2 := MissionState.new()
	st2.embers = 0
	root.add_child(st2)
	var first: RefCounted = await dm.get_next_dialogue_line(res, "start", [st2])
	first = await dm.get_next_dialogue_line(res, first.next_id, [st2])
	var shown := 0
	for r: RefCounted in first.responses:
		print("  choice \"%s\" condition=\"%s\" allowed=%s" % [r.text, r.condition_as_text, r.is_allowed])
		if r.is_allowed:
			shown += 1
	print("embers=0: %d of %d choices allowed (expected 2)" % [shown, first.responses.size()])
	if shown != 2:
		ok = false
	print("PASS dialogue trial" if ok else "FAIL dialogue trial")
	quit()


## Plays the dialogue from "start", picking response `choice` at the first menu. Returns the number of lines.
func _walk(res: Resource, st: Node, choice: int) -> int:
	var count := 0
	var line: RefCounted = await dm.get_next_dialogue_line(res, "start", [st])
	var guard := 0
	while line != null and guard < 50:
		guard += 1
		if not String(line.text).is_empty():
			count += 1
			# What the game would do: Events.dialogue.emit(StringName(line.character.to_lower()), line.text)
			print("  say(%s, \"%s\")" % [String(line.character).to_lower(), line.text])
		if line.responses.size() > 0:
			var allowed: Array = []
			for r: RefCounted in line.responses:
				if r.is_allowed:
					allowed.append(r)
			var pick: RefCounted = allowed[mini(choice, allowed.size() - 1)]
			print("  [choice] %s" % pick.text)
			line = await dm.get_next_dialogue_line(res, pick.next_id, [st])
		else:
			line = await dm.get_next_dialogue_line(res, line.next_id, [st])
	return count
