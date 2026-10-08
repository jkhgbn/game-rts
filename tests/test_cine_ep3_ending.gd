extends SceneTree
## Episode 3 ending + Episode 4 wiring: e3m4's reward "next" is the film ep3_ending; the chain ep3_ending -> ep4_opening ->
## e4m1 (its mission scene starts, 2026-10-08); both films have their stage (scenes/cinematics/<id>.tscn, tools/cine/cine_stage_export.gd)
## and baked script; ep3_ending passes cine's checks with every line translated (data/i18n/fr/dialogue.po); playing the
## chain shows ep3_ending, a skip goes on to ep4_opening, a skip there starts e4m1 (mission_e4_01.tscn), both marked seen.
## Uses its own save (CampaignState.default_path).
## Run:  godot --headless --path . -s tests/test_cine_ep3_ending.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "cine_ep3_ending"
const TEST_SAVE := "user://test_cine_ep3_ending.json"
const E4M1 := "res://missions/mission_e4_01.tscn"

var frame := 0
var step := 0
var step_frame := 0
var player: Node
var errors: Array[String] = []


func _initialize() -> void:
	CampaignState.default_path = TEST_SAVE
	_remove_save()


func _process(_delta: float) -> bool:
	frame += 1
	step_frame += 1
	if frame > 5000:
		return _end("timed out at step %d" % step)
	match step:
		0:
			if step_frame < 2:
				return false
			var r: Dictionary = CampaignState.MISSION_REWARDS.get(&"e3m4", {})
			_ok(r.get("next") == &"ep3_ending", "e3m4 reward next is %s, want ep3_ending" % r.get("next"))
			_ok(CampaignState.film_next(&"ep3_ending") == &"ep4_opening", "ep3_ending -> ep4_opening")
			_ok(CampaignState.film_target(&"ep3_ending") == &"e4m1", "the chain ends on e4m1")
			for id: StringName in [&"ep3_ending", &"ep4_opening"]:
				_ok(StoryFilms.available(id), "%s stage missing" % id)
				var sc := CinematicScript.find(id)
				_ok(sc != null and sc.stage_scene == StoryFilms.stage_of(id), "%s script missing or names no stage" % id)
			_check_ending_source()
			player = CinematicPlayer.instance(self)
			var stage := StoryFilms.play_chain(self, &"ep3_ending", 1)
			if stage == null:
				return _end("play_chain(ep3_ending) started nothing")
			_next()
		1:
			if not _playing(&"ep3_ending"):
				return step_frame > 300 and _end("ep3_ending never played")
			player.call(&"seek", 50.0)
			_next()
		2:
			if step_frame == 3 or step_frame == 6:
				_press_skip()
			if step_frame < 8:
				return false
			_next()
		3:
			if not _playing(&"ep4_opening"):
				return step_frame > 600 and _end("ep4_opening did not follow ep3_ending")
			_ok(CampaignState.open().is_seen(&"ep3_ending"), "ep3_ending not marked seen")
			player.call(&"seek", 80.0)
			_next()
		4:
			if step_frame == 3 or step_frame == 6:
				_press_skip()
			if step_frame < 8:
				return false
			_next()
		5:
			var cs := current_scene
			if cs == null or cs.scene_file_path != E4M1:
				return step_frame > 600 and _end("the chain did not start e4m1 (%s)" % (cs.scene_file_path if cs else "null"))
			_ok(CampaignState.open().is_seen(&"ep4_opening"), "ep4_opening not marked seen")
			return _end("")
	return false


## cine checks on ep3_ending (0 FAIL) and the French of every line.
func _check_ending_source() -> void:
	var doc := CineDoc.load_file(CineDoc.source_of("ep3_ending"))
	var stage := CineStage.new()
	root.add_child(stage)
	stage.build(doc)
	var bake := CineBake.run(doc, stage)
	var ev := CineEval.create(bake.shots, stage.actor_start)
	var rep := ToolReport.start("cine", "check", "ep3_ending")
	CineChecks.add_groups(rep)
	CineChecks.problems(doc, stage, bake, rep)
	CineChecks.timing(doc, bake, ev, rep)
	CineChecks.framing(bake, ev, rep)
	CineChecks.continuity(bake, ev, rep)
	CineChecks.subtitles(doc, bake, rep)
	_ok(rep.count("FAIL") == 0, "ep3_ending cine check FAIL %s" % [rep.problem_lines()])
	stage.queue_free()
	for s: Dictionary in doc.shots:
		for ln: Dictionary in s.get("lines", []):
			var text := String(ln["text"])
			_ok(CineSceneCheck._french(text) != "", "no French for \"%s\"" % text)


func _playing(id: StringName) -> bool:
	for n in get_nodes_in_group(&"cinematic_player"):
		player = n
	return player != null and bool(player.call(&"is_playing")) and player.call(&"current_id") == id


func _ok(cond: bool, what: String) -> void:
	if not cond:
		errors.append(what)


func _next() -> void:
	step += 1
	step_frame = 0


func _press_skip() -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = &"cinematic_skip"
		ev.pressed = pressed
		root.push_input(ev)


func _remove_save() -> void:
	for p: String in [TEST_SAVE, TEST_SAVE + ".bak", TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _end(reason: String) -> bool:
	paused = false
	_remove_save()
	CampaignState.default_path = ""
	if reason != "":
		errors.append(reason)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true
