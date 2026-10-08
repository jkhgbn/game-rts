extends SceneTree
## Regression tests for docs/reviews/review-2026-10-08.md (campaign / cinematic runtime):
## 1. the menu difficulty reaches the mission (`mission_difficulty`) on start and on Retry (reload);
## 2. "Next mission" (MenuFlow.start_mission while a level is current): the new level's pop bonuses go to ITS Economy;
## 3. a refused story film (CinematicPlayer.play error, or a null autoplay script) still emits `cinematic_done`;
## 4. the victory "Continue" label numbers the mission inside its episode (e2m1 = Mission 1);
## 5. replaying a mission never turns an earned objective flag back to false.
## Uses its own save (CampaignState.default_path), never user://campaign.json.
## Run:  godot --headless --path . -s tests/test_review_campaign.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "review_campaign"
const TIMEOUT_FRAMES := 5000
const TEST_SAVE := "user://test_review_campaign.json"
const MISSION := "res://missions/mission_01.tscn"
const FILM_SCRIPT := "res://data/cinematics/ep2_ending.tres"
const SETTLE := 8

var errors: Array[String] = []
var frame := 0
var step := 0
var step_frame := 0
var level: Node = null
var fresh_caps := {}
var film_done: Array = []
var stages: Array[Node] = []
var busy_player: Node = null


func _ok(cond: bool, what: String) -> void:
	if not cond:
		errors.append(what)
		print("  x ", what)


func _initialize() -> void:
	CampaignState.default_path = TEST_SAVE
	_check_continue_label()
	_check_replay_flags()
	_start_refused_films()


func _process(_delta: float) -> bool:
	frame += 1
	step_frame += 1
	if frame > TIMEOUT_FRAMES:
		return _end("timed out at step %d" % step)
	match step:
		0:   # 3. refused films: cinematic_done arrives (deferred)
			if step_frame < 5:
				return false
			_ok(film_done.has(&"refused"), "a refused play emits cinematic_done (got %s)" % str(film_done))
			_ok(film_done.has(&"null_script"), "a null autoplay script emits cinematic_done (got %s)" % str(film_done))
			if busy_player != null:
				busy_player.set(&"_playing", false)
				busy_player.process_mode = Node.PROCESS_MODE_ALWAYS
			for s in stages:
				if is_instance_valid(s):
					s.queue_free()
			# 1. a fresh mission start with Hard
			level = MenuFlow.start_mission(self, MISSION, 2)
			_ok(level != null and level.is_inside_tree(), "start_mission returns the level in the tree")
			_ok(level != null and int(level.get(&"mission_difficulty")) == 2,
					"start_mission sets mission_difficulty = 2 (got %s)" % str(level.get(&"mission_difficulty") if level else null))
			_next()
		1:
			if step_frame < SETTLE:
				return false
			fresh_caps = _caps_of(level)
			_ok(int(fresh_caps.get(0, 0)) > 0, "a fresh mission start gives the player a pop cap (got %s)" % str(fresh_caps))
			# 2. "Next mission": start a mission while one is current (the victory Continue button's call)
			var old := level
			level = MenuFlow.start_mission(self, MISSION, int(old.get(&"mission_difficulty")))
			_ok(current_scene == level, "the new level is the current scene")
			_ok(int(level.get(&"mission_difficulty")) == 2, "Continue keeps the difficulty (got %s)" % str(level.get(&"mission_difficulty")))
			_next()
		2:
			if step_frame < SETTLE:
				return false
			var caps := _caps_of(level)
			_ok(caps == fresh_caps, "Next mission: pop caps %s == fresh start %s" % [str(caps), str(fresh_caps)])
			# 1. Retry (pause menu / end screen) reloads the scene: the difficulty must survive
			MenuFlow.restart(self)
			_next()
		3:
			if step_frame < SETTLE:
				return false
			var cur := current_scene
			_ok(cur != null and cur != level and cur.scene_file_path == MISSION, "Retry reloaded the mission")
			_ok(cur != null and int(cur.get(&"mission_difficulty")) == 2,
					"Retry keeps mission_difficulty = 2 (got %s)" % str(cur.get(&"mission_difficulty") if cur else null))
			return _end("")
	return false


func _next() -> void:
	step += 1
	step_frame = 0


## Player-team (0) and enemy-team pop caps of the Economies inside `lvl`.
func _caps_of(lvl: Node) -> Dictionary:
	var caps := {}
	for n in get_nodes_in_group("economies"):
		if lvl != null and lvl.is_ancestor_of(n):
			caps[int(n.get(&"team"))] = int(n.get(&"pop_cap"))
	return caps


func _check_continue_label() -> void:
	_ok(MissionBase.continue_label(&"m02", false) == "Continue: Mission 2", "m02 label")
	_ok(MissionBase.continue_label(&"e2m1", false) == "Continue: Mission 1",
			"e2m1 label = Mission 1 (got %s)" % MissionBase.continue_label(&"e2m1", false))
	_ok(MissionBase.continue_label(&"e3m4", false) == "Continue: Mission 4", "e3m4 label")
	_ok(MissionBase.continue_label(&"ep3_opening", true) == "Continue", "a film says Continue")


func _check_replay_flags() -> void:
	var cs := CampaignState.open(TEST_SAVE)
	cs.reset()
	var won := Node.new()
	won.set_meta(&"objective_states", {"sec_peddler": "done", "sec_outpost": "failed"})
	cs.on_mission_victory(&"m01", won)
	_ok(bool(cs.flags.get("m1_peddler_freed", false)), "first win: m1_peddler_freed true")
	_ok(not bool(cs.flags.get("m1_outpost_burned", true)), "first win: m1_outpost_burned false")
	var replay := Node.new()
	replay.set_meta(&"objective_states", {"sec_peddler": "failed", "sec_outpost": "done"})
	cs.on_mission_victory(&"m01", replay)
	_ok(bool(cs.flags.get("m1_peddler_freed", false)), "a replay keeps m1_peddler_freed true")
	_ok(bool(cs.flags.get("m1_outpost_burned", false)), "a replay can still earn m1_outpost_burned")
	won.free()
	replay.free()
	cs.reset()


func _start_refused_films() -> void:
	# the shared player is busy: play() answers "Already playing"
	busy_player = CinematicPlayer.instance(self)
	busy_player.process_mode = Node.PROCESS_MODE_DISABLED   # a faked "playing" flag must not tick
	busy_player.set(&"_playing", true)
	var a := CinematicStage.new()
	a.name = "RefusedStage"
	a.render_scale = false
	a.prewarm_frames = 0
	a.quit_when_done = false
	a.autoplay_script = load(FILM_SCRIPT) as CinematicScript
	a.cinematic_done.connect(func(_id: StringName, _s: bool) -> void: film_done.append(&"refused"))
	root.add_child(a)
	stages.append(a)
	var b := CinematicStage.new()
	b.name = "NullScriptStage"
	b.render_scale = false
	b.quit_when_done = false
	b.cinematic_done.connect(func(_id: StringName, _s: bool) -> void: film_done.append(&"null_script"))
	root.add_child(b)
	stages.append(b)


func _end(reason: String) -> bool:
	if reason != "":
		errors.append(reason)
	var f := FileAccess.open(TEST_SAVE, FileAccess.READ)
	if f != null:
		f.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("PASS %s" % TASK_ID if errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(errors)])
	return true
