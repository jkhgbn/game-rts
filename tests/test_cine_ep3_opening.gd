extends SceneTree
## Episode 3 opening wiring: ep3_opening (data/cinematics/ep3_opening.tres on scenes/cinematics/ep3_opening.tscn, both
## written by tools/cine/cine_stage_export.gd) is e3m1's opening film (StoryFilms.opening_of); the Campaign menu with e3m1
## selected shows "Watch opening"; Campaign Start on e3m1 plays the film first (shot B01), two skip presses after the
## lock end it, e3m1 loads and the save says "seen"; a second Start goes straight to e3m1.
## Uses its own save (CampaignState.default_path), never user://campaign.json.
## Run:  godot --headless --path . -s tests/test_cine_ep3_opening.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "cine_ep3_opening"
const TIMEOUT_FRAMES := 5000
const TEST_SAVE := "user://test_cine_ep3_opening.json"
const MENU := "res://scenes/ui/main_menu.tscn"
const FILM := &"ep3_opening"
const STAGE := "res://scenes/cinematics/ep3_opening.tscn"

var frame := 0
var step := 0
var step_frame := 0
var menu: Node
var stage: Node
var player: Node
var mission_path := ""
var errors: Array[String] = []


func _initialize() -> void:
	CampaignState.default_path = TEST_SAVE
	_remove_save()
	var cs := CampaignState.open()
	cs.unlocked.append(&"e3m1")
	cs.save()
	mission_path = CampaignState.mission_scene(&"e3m1")
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
			if StoryFilms.opening_of(&"e3m1") != FILM:
				errors.append("e3m1's opening film is %s, want ep3_opening" % StoryFilms.opening_of(&"e3m1"))
			if not StoryFilms.available(FILM):
				return _end("ep3_opening stage missing (%s)" % STAGE)
			var sc := CinematicScript.find(FILM)
			if sc == null or sc.stage_scene != STAGE:
				errors.append("ep3_opening.tres missing or names no stage")
			elif absf(sc.total_duration() - 91.0) > 4.0:
				errors.append("ep3_opening length %.1f s, want ~91" % sc.total_duration())
			if menu.has_method(&"refresh_missions"):
				menu.call(&"refresh_missions")
			menu.call(&"set_mission", &"e3m1")
			if menu.call(&"get_mission") != &"e3m1":
				errors.append("the Campaign menu cannot select e3m1")
			else:
				var pb: Variant = menu.get(&"prologue_button")
				if not pb is Button or (pb as Button).text != "Watch opening" or (pb as Button).disabled:
					errors.append("the watch button does not offer the Ep3 opening on e3m1")
			player = CinematicPlayer.instance(self)
			stage = MenuFlow.start_campaign_mission(self, &"e3m1", mission_path, 1)
			if stage == null or stage.scene_file_path != STAGE:
				return _end("Start on e3m1 did not load the ep3_opening stage (got %s)" % (stage.scene_file_path if stage else "null"))
			_next()
		1:
			player = _player()
			if player == null or not bool(player.call(&"is_playing")):
				if step_frame > 300:
					return _end("ep3_opening never started playing")
				return false
			var st: Dictionary = player.call(&"debug_state")
			if String(st["id"]) != String(FILM) or String(st["shot_id"]) != "B01":
				errors.append("playing %s / %s, want ep3_opening / B01" % [st["id"], st["shot_id"]])
			if CampaignState.open().is_seen(FILM):
				errors.append("marked seen before it was watched")
			_next()
		2:
			if step_frame < 20:
				return false
			player.call(&"seek", 60.0)
			_next()
		3:
			if step_frame == 2 or step_frame == 5:
				_press_skip()
			if step_frame < 6:
				return false
			_next()
		4:
			var cs := current_scene
			if cs == null or cs.scene_file_path != mission_path:
				if step_frame > 900:
					return _end("e3m1 did not load after the film (current: %s)" % (cs.scene_file_path if cs else "null"))
				return false
			if not CampaignState.open().is_seen(FILM):
				errors.append("the save does not say ep3_opening seen")
			_next()
		5:
			if step_frame < 30:
				return false
			var lvl: Node = MenuFlow.start_campaign_mission(self, &"e3m1", mission_path, 1)
			if lvl == null or lvl.scene_file_path != mission_path:
				errors.append("second start did not go straight to e3m1 (got %s)" % (lvl.scene_file_path if lvl else "null"))
			_next()
		6:
			if step_frame < 10:
				return false
			return _end("")
	return false


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


func _remove_save() -> void:
	for p: String in [TEST_SAVE, TEST_SAVE + ".bak", TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


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
