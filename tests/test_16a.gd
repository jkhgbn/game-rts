extends SceneTree
## Task 16a: score system + score screen.
## 1. Score math on a stub ScoreKeeper (weights, penalty clamp, baselines, leader / margin, table_text).
## 2. History sampling every 30 s of match time (fake clock) + finish().
## 3. GameSettings "Time limit" -> Skirmish.time_limit_s, and the main menu's Off / 30 min / 45 min row.
## 4. Four skirmishes: time limit (ends on score, "Won on score"), victory (enemy razed), defeat (own base razed),
##    concede (the bot surrenders): each shows the Score tab (table + graph) and keeps the Summary tab.
## Run:  godot --headless --path . -s tests/test_16a.gd --fixed-fps 60 --quit-after 40000

const TASK_ID := "16a"
const SCENE := "res://scenes/skirmish.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const KEEPER := preload("res://scripts/world/score_keeper.gd")
const PHASES: Array[StringName] = [&"time", &"victory", &"defeat", &"concede"]
const PHASE_TIMEOUT := 4000

var _errors: Array[String] = []
var _stage := 0            # 0 = unit checks, 1 = history, 2+ = skirmish phases
var _stub: Node
var _fake_t := 0.0
var _frames := 0
var main: Node
var _phase := -1
var _phase_frames := 0
var _acted := false
var _ended_frames := 0
var _bake_frames := 0
var _gap_frames := 0
var _errors_before := 0
var _menu: Node


func _initialize() -> void:
	_check_math()
	_check_settings()
	# History stub: in the tree, fake match clock.
	_stub = KEEPER.new()
	_stub.set(&"match_time_source", func() -> float: return _fake_t)
	root.add_child(_stub)
	_menu = load(MENU_SCENE).instantiate()
	root.add_child(_menu)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 38000:
		return _end("timed out")
	if _stage == 0:
		_check_menu()
		_stage = 1
		return false
	if _stage == 1:
		return _history_step()
	return _phase_step()


# ---------------------------------------------------------------- 1. math

func _check_math() -> void:
	var sk: Node = KEEPER.new()   # not in the tree: pure math
	sk.call(&"add_stat", 0, &"value_killed", 1000.0)
	sk.call(&"add_stat", 0, &"value_lost", 400.0)      # -0.25 each -> military 900
	sk.call(&"add_stat", 1, &"value_lost", 1000.0)     # military clamps at 0
	sk.call(&"set_stat", 0, &"crystals", 1000.0)       # 0.4 -> 400
	sk.call(&"set_stat", 0, &"gold", 100.0)            # 0.6 -> 60
	sk.call(&"set_stat", 0, &"trade_gold", 100.0)      # +0.2 -> 20
	sk.call(&"set_stat", 0, &"peak_workers", 10.0)     # 40 -> 400
	sk.call(&"set_stat", 0, &"peak_workers", 6.0)      # peak kept
	sk.call(&"add_stat", 0, &"point_seconds", 100.0)   # 0.3 -> 30
	sk.call(&"add_stat", 0, &"camps", 2.0)             # 150 -> 300
	sk.call(&"set_stat", 0, &"wizard_level", 3.0)      # (3 - 1) x 200 -> 400
	sk.call(&"set_stat", 1, &"wizard_level", 1.0)      # baseline -> 0
	sk.call(&"set_stat", 1, &"champion_levels", 5.0)   # 120 -> 600
	var b0: Dictionary = sk.call(&"breakdown", 0)
	var b1: Dictionary = sk.call(&"breakdown", 1)
	_expect(int(b0["military"]) == 900, "military 900, got %s" % b0["military"])
	_expect(int(b0["economy"]) == 880, "economy 880, got %s" % b0["economy"])
	_expect(int(b0["map"]) == 330, "map 330, got %s" % b0["map"])
	_expect(int(b0["growth"]) == 400, "growth 400, got %s" % b0["growth"])
	_expect(int(b0["total"]) == 2510 and int(sk.call(&"score", 0)) == 2510, "total 2510, got %s" % b0["total"])
	_expect(int(b1["military"]) == 0 and int(b1["growth"]) == 600 and int(b1["total"]) == 600,
			"team 1 military 0 / growth 600, got %s" % str(b1))
	_expect(int(sk.call(&"leader")) == 0 and int(sk.call(&"margin")) == 1910, "leader 0 by 1910")
	var table: String = sk.call(&"table_text")
	_expect(table.contains("Military") and table.contains("TOTAL") and table.contains("2 510")
			and table.contains("leader: team 0 by 1 910"), "table_text:\n%s" % table)
	# Kill credit: unknown killer -> the other side; neutral killer -> nobody.
	sk.call(&"record_kill", 1, -1, 300)
	sk.call(&"record_kill", 1, 2, 200)
	_expect(is_equal_approx(float(sk.call(&"stat", 0, &"value_killed")), 1300.0), "unknown killer credits the other side")
	_expect(is_equal_approx(float(sk.call(&"stat", 1, &"value_lost")), 1500.0), "losses always counted")
	var tie: Node = KEEPER.new()
	_expect(int(tie.call(&"leader")) == -1 and int(tie.call(&"margin")) == 0, "tie: leader -1")
	sk.free()
	tie.free()


func _check_settings() -> void:
	var before: int = GameSettings.time_limit_min
	var level := Node.new()
	_expect(not GameSettings.apply_time_limit(level), "apply_time_limit set a node without time_limit_s")
	level.free()
	var sk_level: Node = load(SCENE).instantiate()
	GameSettings.time_limit_min = 45
	_expect(GameSettings.apply_time_limit(sk_level) and is_equal_approx(float(sk_level.get(&"time_limit_s")), 2700.0),
			"45 min -> time_limit_s 2700")
	GameSettings.time_limit_min = 0
	GameSettings.apply_time_limit(sk_level)
	_expect(is_equal_approx(float(sk_level.get(&"time_limit_s")), 0.0), "Off -> time_limit_s 0")
	sk_level.free()
	GameSettings.time_limit_min = before
	_expect(GameSettings.TIME_LIMIT_CHOICES == [0, 30, 45], "choices Off / 30 / 45")


func _check_menu() -> void:
	var buttons: Array = _menu.get(&"time_limit_buttons")
	var texts: Array[String] = []
	for b in buttons:
		texts.append((b as Button).text)
	_expect(texts == ["Off", "30 min", "45 min"], "menu time-limit row, got %s" % str(texts))
	var pressed := 0
	for i in buttons.size():
		if (buttons[i] as Button).button_pressed:
			pressed += 1
			_expect(GameSettings.TIME_LIMIT_CHOICES[i] == GameSettings.time_limit_min, "the saved limit is pressed")
	_expect(pressed == 1, "exactly one time-limit button pressed (%d)" % pressed)
	_menu.queue_free()
	_menu = null


# ---------------------------------------------------------------- 2. history

func _history_step() -> bool:
	var h: Array = _stub.call(&"history", 0)
	if _fake_t == 0.0:
		_expect(h.size() == 1 and is_equal_approx(float(h[0]["t"]), 0.0), "history starts with a 0:00 point")
		_stub.call(&"add_stat", 0, &"camps", 1.0)
		_fake_t = 29.0
		return false
	if _fake_t == 29.0:
		_expect(h.size() == 1, "no history point before 30 s (%d)" % h.size())
		_fake_t = 31.0
		return false
	if _fake_t == 31.0:
		_expect(h.size() == 2 and int(h[1]["total"]) == 150 and int(h[1]["map"]) == 150,
				"a history point at 30 s with the new total, got %s" % str(h))
		_stub.call(&"add_stat", 1, &"beasts", 1.0)
		_fake_t = 61.0
		return false
	if _fake_t == 61.0:
		var h1: Array = _stub.call(&"history", 1)
		_expect(h.size() == 3 and h1.size() == 3 and int(h1[2]["total"]) == 400, "a history point at 60 s for both teams")
		_stub.call(&"finish")
		_stub.call(&"add_stat", 0, &"camps", 5.0)
		_expect(int(_stub.call(&"score", 0)) == 150, "finish() freezes the score")
		_expect(ScoreKeeper.instance(self) == _stub, "ScoreKeeper.instance finds the group 'score' node")
		_stub.queue_free()
		_stub = null
		_stage = 2
		_next_phase()
	return false


# ---------------------------------------------------------------- 3-4. skirmish phases

func _next_phase() -> void:
	if main != null:
		main.queue_free()
		main = null
	_phase += 1
	_phase_frames = 0
	_bake_frames = 0
	_gap_frames = 0
	_acted = false
	_ended_frames = 0
	_errors_before = _errors.size()


func _start_phase() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	# After add_child: the main menu installed MenuFlow's hook, which applies the saved "Time limit" on entry.
	main.set(&"time_limit_s", 4.0 if PHASES[_phase] == &"time" else 0.0)


func _phase_step() -> bool:
	if _phase >= PHASES.size():
		return _end("")
	if main == null:
		# The previous skirmish is freed first (its services leave their groups), then the next one starts.
		_gap_frames += 1
		if _gap_frames >= 3:
			_start_phase()
		return false
	var phase := PHASES[_phase]
	if not main.match_started:
		_bake_frames += 1
		if _bake_frames > 6000:
			_errors.append("%s: navigation never finished baking" % phase)
			_next_phase()
		return false
	_phase_frames += 1
	if _phase_frames > PHASE_TIMEOUT:
		_errors.append("%s: timed out (time %.1f, game_over %s)" % [phase, float(main.call(&"match_time")), main.game_over])
		_next_phase()
		return false
	var sk: Node = main.get(&"score_keeper") as Node
	if not _acted:
		_acted = true
		if sk == null:
			_errors.append("%s: no ScoreKeeper on the skirmish" % phase)
			_next_phase()
			return false
		match phase:
			&"time":
				sk.call(&"add_stat", 0, &"value_killed", 5000.0)   # the player leads
			&"victory":
				_raze(1)
			&"defeat":
				_raze(0)
			&"concede":
				main.call(&"surrender", 1, "")
		return false
	if not main.game_over:
		return false
	_ended_frames += 1
	if _ended_frames < 10:
		return false
	_check_end_screen(phase, sk)
	_next_phase()
	return false


func _raze(team: int) -> void:
	for b in main.get_tree().get_nodes_in_group("buildings"):
		if int(b.team) == team:
			b.take_damage(1.0e7, null)


func _check_end_screen(phase: StringName, sk: Node) -> void:
	var hud: Node = main.get(&"hud")
	var want_win := phase != &"defeat"
	_expect(int(main.winner_team) == (0 if want_win else 1), "%s: winner %d" % [phase, main.winner_team])
	_expect(hud.call(&"is_banner_shown"), "%s: end banner shown" % phase)
	_expect(hud.get(&"end_tabs").visible, "%s: Summary / Score tabs shown" % phase)
	_expect(hud.get(&"end_tab") == &"score" and hud.get(&"score_panel").visible, "%s: Score tab open" % phase)
	var shown: Dictionary = hud.get(&"score_panel").get(&"shown")
	_expect(shown.has("total") and (shown["total"] as Array).size() == 2
			and int(shown["total"][0]) == int(sk.call(&"score", 0)) and int(shown["total"][1]) == int(sk.call(&"score", 1)),
			"%s: score table totals %s" % [phase, str(shown.get("total"))])
	_expect((shown["rows"] as Dictionary).size() == 4, "%s: 4 category rows" % phase)
	_expect((sk.call(&"history", 0) as Array).size() >= 2, "%s: history has the start and end points" % phase)
	_expect(not bool(sk.get(&"running")), "%s: the ScoreKeeper stopped at the end" % phase)
	var sub: String = hud.get(&"end_subtitle").text
	var body: String = hud.get(&"end_body").text
	_expect(body.begins_with("Match time ") and body.ends_with("F9: play again"), "%s: summary body kept" % phase)
	match phase:
		&"time":
			_expect(main.get(&"ended_on_score") == true, "time: ended_on_score")
			_expect(sub.begins_with("Won on score"), "time: subtitle '%s'" % sub)
			_expect(int(sk.call(&"leader")) == 0, "time: the player leads")
			print(sk.call(&"table_text"))
		&"victory":
			_expect(sub == "" and main.get(&"ended_on_score") == false, "victory: no on-score subtitle ('%s')" % sub)
			_expect(float(sk.call(&"stat", 0, &"value_killed")) >= 600.0, "victory: razed keep value credited")
		&"defeat":
			_expect(float(sk.call(&"stat", 0, &"value_lost")) >= 600.0, "defeat: own keep value lost")
		_:
			_expect(sub == "", "concede: no subtitle")
	# The Summary tab still works.
	hud.call(&"select_end_tab", &"summary")
	_expect(hud.get(&"end_body").visible and not hud.get(&"score_panel").visible, "%s: Summary tab shows the stats" % phase)
	hud.call(&"select_end_tab", &"score")
	var graph: Control = hud.get(&"score_panel").get(&"graph")
	_expect(graph != null and graph.custom_minimum_size.x > 0.0, "%s: graph control" % phase)
	print("%s: %d problem(s), score %d - %d" % [phase, _errors.size() - _errors_before, int(sk.call(&"score", 0)),
			int(sk.call(&"score", 1))])


# ---------------------------------------------------------------- helpers

func _expect(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)


func _end(reason: String) -> bool:
	if reason != "":
		_errors.append(reason)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in _errors:
			print("  - " + e)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _errors.size()])
	return true
