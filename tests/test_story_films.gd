extends SceneTree
## Story films between missions (scripts/campaign/story_films.gd, CampaignState.STORY_FILMS): e2m5's reward "next" is
## the `ep2_ending` film; the chain ep2_ending -> ep3_opening -> e3m1; a victory unlocks the mission at the end of the
## chain; the ep2_ending stage scene and script exist and the script names its stage; the chain plays that stage.
## Run: godot --headless --path . -s tests/test_story_films.gd --fixed-fps 60 --quit-after 2000

const TASK_ID := "story_films"
const SAVE := "user://test_story_films.json"

var _errors: Array[String] = []
var _frame := 0
var _stage: Node = null


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _initialize() -> void:
	_ok(CampaignState.is_film(&"ep2_ending") and not CampaignState.is_film(&"e3m1"), "ep2_ending is a film")
	_ok(CampaignState.film_next(&"ep2_ending") == &"ep3_opening", "ep2_ending -> ep3_opening")
	_ok(CampaignState.film_target(&"ep2_ending") == &"e3m1", "the chain ends on e3m1")
	_ok(CampaignState.film_target(&"e3m2") == &"e3m2", "a mission id is its own target")
	_ok(StoryFilms.available(&"ep2_ending"), "the ep2_ending stage exists")
	var script := load("res://data/cinematics/ep2_ending.tres")
	_ok(script != null, "the ep2_ending script loads")
	if script:
		_ok(String(script.get(&"stage_scene")) == "res://scenes/cinematics/ep2_ending.tscn", "the script names its stage")
	var cs := CampaignState.open(SAVE)
	cs.reset()
	cs.on_mission_victory(&"e2m5", null)
	_ok(cs.unlocked.has(&"e3m1") and not cs.unlocked.has(&"ep2_ending"), "the e2m5 victory unlocks e3m1 (%s)" % str(cs.unlocked))
	cs.reset()
	for id: StringName in [&"e3m1", &"e3m2", &"e3m3", &"e3m4"]:
		_ok(CampaignState.mission_available(id), "%s has a scene" % id)
	_stage = StoryFilms.play_chain(self, &"ep2_ending", 1)
	_ok(_stage != null and _stage.has_signal(&"cinematic_done"), "the chain plays the ep2_ending stage")


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 30:
		return false
	print("PASS %s" % TASK_ID if _errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true
