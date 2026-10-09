extends SceneTree
## Episode 8 story flow (campaign-outline.md 4.1 / 4.5, mission-e8-03.md 8.2): ep7_ending -> ep8_opening -> the road
## picker (e8m1) -> e8m1_<k> -> c_e8_muster -> e8m2 -> e8m3 -> ep8_ending_a -> ep8_throne_<wizard> -> the choice card ->
## ep8_ending_b or ep8_dark_<k> -> ep8_bookend or ep8_bookend_dark -> the credits -> the menu. Checks the tables, the
## flag branches, the screens (road pick, choice) on a test save, the seat table and the line tables.
## Run: godot --headless --path . -s tests/test_e8_flow.gd --quit-after 600

const TASK_ID := "e8_flow"
const SAVE := "user://test_e8_flow.json"

var fails: Array[String] = []
var _frames := 0


func _check(cond: bool, what: String) -> void:
	if not cond:
		fails.append(what)


func _initialize() -> void:
	CampaignState.default_path = SAVE
	CampaignState.open(SAVE).reset()
	# the chain tables
	_check(CampaignState.film_target(&"ep7_ending") == &"e8m1", "ep7_ending should unlock e8m1 (the road picker)")
	_check(CampaignState.film_target(&"c_e8_muster") == &"e8m2", "c_e8_muster -> e8m2")
	_check(CampaignState.film_target(&"ep8_ending_a") == &"", "the ending chain unlocks nothing")
	for k: String in ["fire", "shadow", "ice", "nature"]:
		var id := StringName("e8m1_" + k)
		_check(CampaignState.mission_available(id), "%s has a scene" % id)
		_check(StringName(CampaignState.reward_of(id).get("next", &"")) == &"c_e8_muster", "%s next = c_e8_muster" % id)
	for id: StringName in [&"e8m1", &"e8m2", &"e8m3"]:
		_check(CampaignState.mission_available(id), "%s has a scene" % id)
	for f: StringName in [&"ep8_opening", &"c_e8_muster", &"ep8_ending_a", &"ep8_throne_vessa", &"ep8_throne_malrik",
			&"ep8_throne_torvald", &"ep8_throne_ysolde", &"ep8_ending_b", &"ep8_dark_fire", &"ep8_dark_shadow", &"ep8_dark_ice",
			&"ep8_dark_nature", &"ep8_bookend", &"ep8_bookend_dark"]:
		_check(CampaignState.is_film(f), "%s is a story film" % f)
		_check(StoryFilms.available(f), "%s has a stage scene" % f)
	for s: StringName in CampaignState.STORY_SCREENS:
		_check(ResourceLoader.exists(String(CampaignState.STORY_SCREENS[s])), "%s screen exists" % s)
	_check(StoryFilms.opening_of(&"e8m1") == &"ep8_opening", "the campaign menu plays ep8_opening before the picker")
	# branches: no flags = the key films
	_check(StoryFilms.branch_of(&"ep8_throne_vessa") == &"ep8_throne_vessa", "no road = Vessa's throne shot")
	_check(StoryFilms.branch_of(&"ep8_ending_b") == &"ep8_ending_b", "no choice = canon")
	var cs := CampaignState.open(SAVE)
	cs.set_flags({"e8_road": 2, "ep8_choice": CampaignState.CHOICE_BREAK}, true)
	_check(StoryFilms.branch_of(&"ep8_throne_vessa") == &"ep8_throne_torvald", "road 2 = Torvald's throne shot")
	_check(StoryFilms.branch_of(&"ep8_ending_b") == &"ep8_ending_b", "break = canon b")
	_check(StoryFilms.branch_of(&"ep8_bookend") == &"ep8_bookend", "break = canon bookend")
	cs.set_flags({"ep8_choice": CampaignState.CHOICE_TAKE}, true)
	_check(StoryFilms.branch_of(&"ep8_ending_b") == &"ep8_dark_ice", "take + ice = ep8_dark_ice")
	_check(StoryFilms.branch_of(&"ep8_bookend") == &"ep8_bookend_dark", "take = the dark bookend")
	# the seat table (mission-e8-02.md 2.1) and the line tables
	var t := MissionE8Muster.seat_table(&"ice")
	_check(t[Unit.Team.PLAYER] == &"ice" and t[Teams.ALLY] == &"nature" and t[Unit.Team.ENEMY] == &"fire" \
			and t[Teams.ENEMY_2] == &"shadow", "seat table for Ice: %s" % str(t))
	for m: StringName in E8Lines.IDS:
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/voice/lines/%s.json" % m))
		var n := ((j as Dictionary)["lines"] as Array).size() if j is Dictionary else -1
		_check((E8Lines.IDS[m] as Array).size() == n and (E8Lines.LINES[m] as Array).size() == n, "%s lines %d" % [m, n])
	# the screens
	var road := (load("res://missions/e8_road_choice.tscn") as PackedScene).instantiate()
	road.set(&"save_path", SAVE)
	road.set(&"launch", false)
	root.add_child(road)
	var choice := (load("res://missions/ep8_choice.tscn") as PackedScene).instantiate()
	choice.set(&"save_path", SAVE)
	choice.set(&"launch", false)
	root.add_child(choice)
	var credits := (load("res://missions/ep8_credits.tscn") as PackedScene).instantiate()
	credits.set(&"save_path", SAVE)
	root.add_child(credits)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	var road := root.get_child(root.get_child_count() - 3)
	road.call(&"pick_road", &"shadow")
	var cs := CampaignState.open(SAVE)
	_check(int(cs.flag_value("e8_road", -1)) == 1 and cs.flag("e8_road_shadow") and not cs.flag("e8_road_fire"),
			"pick_road(shadow) writes e8_road 1")
	_check(cs.unlocked.has(&"e8m1_shadow"), "the picked road is unlocked")
	var choice := root.get_child(root.get_child_count() - 2)
	choice.call(&"choose", CampaignState.CHOICE_BREAK)
	cs = CampaignState.open(SAVE)
	_check(int(cs.flag_value("ep8_choice", 0)) == CampaignState.CHOICE_BREAK and cs.flag("ep8_throne_broken"), "choose(break) is saved")
	_check(StoryFilms.branch_of(&"ep8_ending_b") == &"ep8_ending_b", "after break: canon")
	_check(E8StoryScreen.dark_score({"e3m4_refused": false, "e3m3_refused": false, "e8_stone_uses": 2}) == 3, "dark score")
	cs.reset()
	CampaignState.default_path = ""
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in fails:
			print("  x ", f)
		print("FAIL %s: %s" % [TASK_ID, fails[0]])
	return true
