extends SceneTree
## Episode 8 stage films (docs/design/script-episodes-4-8.md, shot lists in script-episodes-4-8/e8m*.md): the opening
## ep8_opening, the between-scene c_e8_muster, and the closing set "Four Hands": ep8_ending_a, ep8_throne_<k> (x4),
## ep8_ending_b (canon, Vessa road), ep8_dark_<k> (x4), ep8_bookend (canon track) + ep8_bookend_dark. Each passes cine's checks (0 FAIL), has its baked script and stage, every line
## translated and voiced (tests/helpers/cine_film_check.gd). Missions e8m1-e8m3 are not built (and the closing chain needs StoryFlow branching): the films are not in
## CampaignState.STORY_FILMS yet; one is played alone (StoryFilms.play_only), seeked, skipped -> main menu, marked seen.
## Run:  godot --headless --path . -s tests/test_cine_ep8_films.gd --fixed-fps 60 --quit-after 6000
## Dev:  add  -- --report  to print each film's length and every WARN row (checks only, no play).

const TASK_ID := "cine_ep8_films"
const FILMS: Array[String] = ["ep8_opening", "c_e8_muster", "ep8_ending_a", "ep8_throne_vessa", "ep8_throne_malrik",
	"ep8_throne_torvald", "ep8_throne_ysolde", "ep8_ending_b", "ep8_dark_fire", "ep8_dark_ice", "ep8_dark_nature",
	"ep8_dark_shadow", "ep8_bookend", "ep8_bookend_dark"]
const PLAY := &"ep8_bookend"
const TEST_SAVE := "user://test_cine_ep8_films.json"
const MENU := "res://scenes/ui/main_menu.tscn"

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
	if frame > 5500:
		return _end("timed out at step %d" % step)
	match step:
		0:
			if step_frame < 2:
				return false
			var voiced := CineFilmCheck.voiced_lines()
			var info: Array[String] = []
			for id: String in FILMS:
				errors.append_array(CineFilmCheck.check(root, id, voiced, info))
			if "--report" in OS.get_cmdline_user_args():
				for l: String in info:
					print("  ", l)
				return _end("")
			if StoryFilms.play_only(self, PLAY) == null:
				return _end("play_only(%s) started nothing" % PLAY)
			_next()
		1:
			if not _playing(PLAY):
				return step_frame > 300 and _end("%s never played" % PLAY)
			player.call(&"seek", 12.0)
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
				return step_frame > 600 and _end("%s did not end on the main menu" % PLAY)
			_ok(CampaignState.open().is_seen(PLAY), "%s not marked seen" % PLAY)
			return _end("")
	return false


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
