extends SceneTree
## Episode 2 between-scenes (stage films, data/cinematics/src/c_e2_{ashes,lodge,stair}.cine on forge_intro_ysolde /
## forge_ep2_feast / forge_watch_keep): the rewards of e2m1 / e2m2 / e2m3 name the film, each film leads to the next mission (CampaignState.STORY_FILMS) and the
## victory still unlocks that mission; each film has its stage (scenes/cinematics/<id>.tscn) and baked script, passes
## cine's checks with every line translated (data/i18n/fr/dialogue.po) and voiced (data/voice/manifest.json); the
## campaign menu plays it before its mission (StoryFilms.opening_of); c_e2_ashes plays alone, a skip lands on the main
## menu and marks it seen. Uses its own save (CampaignState.default_path).
## Run:  godot --headless --path . -s tests/test_cine_ep2_between.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "cine_ep2_between"
const TEST_SAVE := "user://test_cine_ep2_between.json"
const MENU := "res://scenes/ui/main_menu.tscn"
const FILMS := {&"c_e2_ashes": [&"e2m1", &"e2m2"], &"c_e2_lodge": [&"e2m2", &"e2m3"], &"c_e2_stair": [&"e2m3", &"e2m4"]}

var frame := 0
var step := 0
var step_frame := 0
var player: Node
var errors: Array[String] = []
var voiced := {}


func _initialize() -> void:
	CampaignState.default_path = TEST_SAVE
	_remove_save()


func _process(_delta: float) -> bool:
	frame += 1
	step_frame += 1
	if frame > 3500:
		return _end("timed out at step %d" % step)
	match step:
		0:
			if step_frame < 2:
				return false
			_load_manifest()
			for id: StringName in FILMS:
				var after: StringName = FILMS[id][0]
				var before: StringName = FILMS[id][1]
				var r: Dictionary = CampaignState.MISSION_REWARDS.get(after, {})
				_ok(r.get("next") == id, "%s reward next is %s, want %s" % [after, r.get("next"), id])
				_ok(CampaignState.film_next(id) == before, "%s -> %s" % [id, before])
				_ok(CampaignState.film_target(id) == before, "%s's chain ends on %s" % [id, before])
				_ok(StoryFilms.opening_of(before) == id, "%s is not played before %s" % [id, before])
				_ok(StoryFilms.available(id), "%s stage missing" % id)
				var sc := CinematicScript.find(id)
				_ok(sc != null and sc.stage_scene == StoryFilms.stage_of(id), "%s script missing or names no stage" % id)
				_check_source(String(id))
			player = CinematicPlayer.instance(self)
			if StoryFilms.play_only(self, &"c_e2_ashes") == null:
				return _end("play_only(c_e2_ashes) started nothing")
			_next()
		1:
			if not _playing(&"c_e2_ashes"):
				return step_frame > 300 and _end("c_e2_ashes never played")
			player.call(&"seek", 30.0)
			_next()
		2:
			if step_frame == 3 or step_frame == 6:
				_press_skip()
			if step_frame < 8:
				return false
			_next()
		3:
			var cs := current_scene
			if cs == null or cs.scene_file_path != MENU:
				return step_frame > 600 and _end("c_e2_ashes did not end on the main menu (%s)" % (cs.scene_file_path if cs else "null"))
			_ok(CampaignState.open().is_seen(&"c_e2_ashes"), "c_e2_ashes not marked seen")
			return _end("")
	return false


## cine checks (0 FAIL), the French and the voice of every line.
func _check_source(id: String) -> void:
	var doc := CineDoc.load_file(CineDoc.source_of(id))
	var stage := CineStage.new()
	root.add_child(stage)
	stage.build(doc)
	var bake := CineBake.run(doc, stage)
	var ev := CineEval.create(bake.shots, stage.actor_start)
	var rep := ToolReport.start("cine", "check", id)
	CineChecks.add_groups(rep)
	CineChecks.problems(doc, stage, bake, rep)
	CineChecks.timing(doc, bake, ev, rep)
	CineChecks.framing(bake, ev, rep)
	CineChecks.continuity(bake, ev, rep)
	CineChecks.subtitles(doc, bake, rep)
	_ok(rep.count("FAIL") == 0, "%s cine check FAIL %s" % [id, rep.problem_lines()])
	stage.queue_free()
	for s: Dictionary in doc.shots:
		for ln: Dictionary in s.get("lines", []):
			var text := String(ln["text"])
			_ok(CineSceneCheck._french(text) != "", "%s: no French for \"%s\"" % [id, text])
			_ok(voiced.has(text), "%s: \"%s\" not voiced" % [id, text])


func _load_manifest() -> void:
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/voice/manifest.json"))
	if m is Dictionary:
		var entries: Variant = (m as Dictionary).get("lines", m)
		if entries is Dictionary:
			for k: Variant in entries:
				var e: Variant = entries[k]
				if e is Dictionary and (e as Dictionary).has("text"):
					voiced[String((e as Dictionary)["text"])] = true


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
