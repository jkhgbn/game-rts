extends SceneTree
## Campaign prologue: Campaign -> Start (mission 1) plays the 3-minute prologue in-engine first (the baked
## data/cinematics/prologue_3min.tres on scenes/cinematics/prologue_3min.tscn): the player starts on shot 1 (S01,
## forge_citadel, 2.39 bars, music bed), the skip lock eats presses before 30 s, two skip presses after it end the
## movie, mission 1 loads and the campaign save says "seen"; a second Start goes straight to mission 1.
## Uses its own save (CampaignState.default_path), never user://campaign.json.
## Run:  godot --headless --path . -s tests/test_campaign_prologue.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "campaign_prologue"
const TIMEOUT_FRAMES := 5000
const TEST_SAVE := "user://test_campaign_prologue.json"
const MENU := "res://scenes/ui/main_menu.tscn"
const MISSION := "res://missions/mission_01.tscn"

var frame := 0
var step := 0
var step_frame := 0
var menu: Node
var stage: Node
var player: Node
var errors: Array[String] = []
var shot_seen: Array = []


func _initialize() -> void:
	CampaignState.default_path = TEST_SAVE
	_remove_save()
	menu = (load(MENU) as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu


func _process(_delta: float) -> bool:
	frame += 1
	step_frame += 1
	if frame > TIMEOUT_FRAMES:
		return _end("timed out at step %d" % step)
	match step:
		0:
			if step_frame < 3:
				return false
			var pb: Variant = menu.get(&"prologue_button")
			if not pb is Button:
				errors.append("no Watch prologue button in the campaign panel")
			elif (pb as Button).disabled:
				errors.append("Watch prologue is disabled (stage / script missing)")
			if not MenuFlow.prologue_available():
				return _end("prologue not available: scenes/cinematics/prologue_3min.tscn or its .tres missing")
			# the stage plays on the shared player (CinematicPlayer.instance): listen before it starts
			player = CinematicPlayer.instance(self)
			player.connect(&"shot_started", _on_shot)
			menu.call(&"set_mission", &"m01")
			stage = menu.call(&"start_mission") as Node
			if stage == null or stage.scene_file_path != "res://scenes/cinematics/prologue_3min.tscn":
				return _end("Start did not load the prologue stage (got %s)" % (stage.scene_file_path if stage else "null"))
			_next()
		1:
			# the stage prewarms its 5 sets under black, then the player starts on shot 1
			player = _player()
			if player == null or not bool(player.call(&"is_playing")):
				if step_frame > 200:
					return _end("the prologue never started playing")
				return false
			var st: Dictionary = player.call(&"debug_state")
			if String(st["id"]) != "prologue_3min":
				errors.append("playing %s, not prologue_3min" % st["id"])
			if int(st["shot_index"]) != 0 or String(st["shot_id"]) != "S01":
				errors.append("first shot is %s (%d), want S01 (0)" % [st["shot_id"], st["shot_index"]])
			if String(st["active_set"]) != "forge_citadel":
				errors.append("active set %s, want forge_citadel" % st["active_set"])
			var ov: Node = player.call(&"overlay")
			if ov == null or not bool(ov.call(&"is_open")):
				errors.append("letterbox overlay not open")
			var sc: Resource = player.call(&"current_script")
			if absf(float(sc.call(&"total_duration")) - 180.0) > 5.0:
				errors.append("prologue length %.1f s, want ~180" % float(sc.call(&"total_duration")))
			if float(sc.get(&"skip_locked_until")) < 1.0:
				errors.append("no skip lock")
			if current_scene != stage:
				errors.append("the stage is not the current scene")
			if CampaignState.open().is_seen(&"prologue_3min"):
				errors.append("marked seen before it was watched")
			_next()
		2:
			# a few frames of play: the clock runs, the flock / vfx do not error; then a skip press inside the lock
			if step_frame == 30:
				_press_skip()
			if step_frame < 40:
				return false
			if not bool(player.call(&"is_playing")):
				return _end("a skip press inside the 30 s lock ended the prologue")
			if float(player.call(&"elapsed")) < 0.3:
				errors.append("the cinematic clock does not run (t=%.2f)" % float(player.call(&"elapsed")))
			# past the lock: first viewing = two presses (the prompt, then the skip)
			player.call(&"seek", 31.0)
			_next()
		3:
			if step_frame == 2:
				_press_skip()
			if step_frame == 3:
				var st2: Dictionary = player.call(&"debug_state")
				if not bool(st2["skip_prompt"]):
					errors.append("first press after the lock showed no skip prompt")
			if step_frame == 5:
				_press_skip()
			if step_frame < 6:
				return false
			_next()
		4:
			# the skip ends the movie; the deferred hand-off loads mission 1
			var cs := current_scene
			if cs == null or cs.scene_file_path != MISSION:
				if step_frame > 600:
					return _end("mission 1 did not load after the skip (current: %s)" % (cs.scene_file_path if cs else "null"))
				return false
			if bool(player.call(&"is_playing")):
				errors.append("the player still plays in mission 1")
			if not CampaignState.open().is_seen(&"prologue_3min"):
				errors.append("the campaign save does not say prologue seen")
			_next()
		5:
			if step_frame < 30:
				return false
			# second start: straight to mission 1, no prologue
			var lvl: Node = MenuFlow.start_campaign_mission(self, &"m01", MISSION, 1)
			if lvl == null or lvl.scene_file_path != MISSION:
				errors.append("second start did not go straight to mission 1 (got %s)" % (lvl.scene_file_path if lvl else "null"))
			_next()
		6:
			if step_frame < 10:
				return false
			if bool(player.call(&"is_playing")):
				errors.append("the prologue played again on the second start")
			if not shot_seen.has(&"S01"):
				errors.append("shot_started(S01) never seen")
			return _end("")
	return false


func _on_shot(_i: int, id: StringName) -> void:
	shot_seen.append(id)


func _next() -> void:
	step += 1
	step_frame = 0


func _press_skip() -> void:
	var ev := InputEventAction.new()
	ev.action = &"cinematic_skip"
	ev.pressed = true
	root.push_input(ev)
	var up := InputEventAction.new()
	up.action = &"cinematic_skip"
	up.pressed = false
	root.push_input(up)


func _player() -> Node:
	for n in get_nodes_in_group(&"cinematic_player"):
		return n
	return null


func _campaign_state() -> Script:
	return load("res://scripts/campaign/campaign_state.gd") as Script


func _remove_save() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func _end(reason: String) -> bool:
	paused = false
	_remove_save()
	CampaignState.default_path = ""
	if reason == "" and errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		if reason != "":
			errors.append(reason)
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true
