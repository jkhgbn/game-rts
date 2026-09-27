extends SceneTree
## Task 8.B3 (balance-2 bot knobs, docs/design/balance-2.md 2a / 2b / 2d) + the section 4 re-test harness.
## Part 0 (instant): data/ai/nature_*.tres and ice_*.tres carry the balance-2 values and the code presets
##   (AIProfile.nature() / ice()) say the same.
## Runs: any-kingdom bot vs bot, both sides normal bots, pairs "player:enemy", cap --minutes (default 24).
##   Logged per run: winner / time; army pop at 5 / 10 / 15 / end (max); crystals gathered at 5 / 10 / 15 / end;
##   workers at 5 / 10; X1 / X2 completion; attacks / retreats; wizard levels; first tier-2 item; wizard casts.
##   Checked (8.B3 done-when): an Ice bot places X1 by 6:00 unless its attack group is out then; a Nature bot
##   keeps <= 9 workers once X1 stands (before X2) and <= 12 after X2; a Nature relaunch after a retreat comes
##   >= 45 s after reaching the rally or at >= 85 % average HP (the all-in endgame exempt).
## Run:  godot --headless --path . -s tests/test_8_b3.gd --fixed-fps 60 --quit-after 90000 -- --pairs=ice:nature
##   Several pairs: quit-after ~ 88000 x pairs. Options: --pairs=a:b,c:d  --minutes=24  --only-data
##   --set=unit:rime_seer:support_amount=75,building:ice_keep:max_hp=3600,ai:nature_normal:regrow_wait=35
##   (8.B4: try a balance knob in memory only, after part 0; the data files are not touched)

const TASK_ID := "8.B3"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const MARKS: Array[float] = [300.0, 600.0, 900.0]

var main: Node
var bots := {}                      # team -> Commander
var _pairs: Array[String] = ["ice:nature"]
var _minutes := 24.0
var _pair := ""
var _kingdoms := {}                 # team -> kingdom
var _wait := 0
var _gap := 0
var _frame := 0
var _t := 0.0
var _errors: Array[String] = []
var _notes: Array[String] = []
var _results: Array[String] = []
var _m := {}                        # team -> metrics dictionary
var _started := false
var _tier_cache := {}
var _held: Array[Resource] = []     # --set resources, kept alive so the override stays in the load cache


func _initialize() -> void:
	var only_data := false
	var overrides := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pairs="):
			_pairs.clear()
			for p in a.trim_prefix("--pairs=").split(",", false):
				_pairs.append(p)
		elif a.begins_with("--minutes="):
			_minutes = a.trim_prefix("--minutes=").to_float()
		elif a == "--only-data":
			only_data = true
		elif a.begins_with("--set="):
			overrides = a.trim_prefix("--set=")
	_part0()   # checks the shipped data, before any --set
	if overrides != "":
		_apply_overrides(overrides)
	if only_data:
		_pairs.clear()
	_next_run()


## 8.B4: try a balance-2 section 5 knob without touching another owner's data file. `spec` is
## "unit:<id>:<field>=<value>,building:<id>:<field>=<value>,..." applied to the cached UnitType /
## BuildingType resources (every unit / building made in this process reads them).
func _apply_overrides(spec: String) -> void:
	for item in spec.split(",", false):
		var parts := item.split("=")
		var path := parts[0].split(":")
		if parts.size() != 2 or path.size() != 3:
			_errors.append("bad --set item %s" % item)
			continue
		var res: Resource = null
		match path[0]:
			"unit":
				res = UnitType.find(path[1])
			"building":
				res = BuildingType.find(path[1])
			"ai":   # data/ai/<id>.tres; AIProfile.for_id duplicates the cached (held) resource
				res = load("res://data/ai/%s.tres" % path[1])
		_held.append(res)
		if res == null or not path[2] in res:
			_errors.append("--set: no %s" % item)
			continue
		var old: Variant = res.get(path[2])
		res.set(path[2], type_convert(parts[1].to_float(), typeof(old)))
		print("override %s:%s %s -> %s" % [path[1], path[2], str(old), str(res.get(path[2]))])


# ---------------------------------------------------------------- part 0: the knobs

func _part0() -> void:
	var want := {
		"nature_easy": {"worker_target_expanded": 6, "worker_target_x2": 6, "regrow_wait": 45.0},
		"nature_normal": {"worker_target_home": 7, "worker_target_expanded": 9, "worker_target_x2": 12, "regrow_wait": 45.0},
		"nature_hard": {"worker_target_home": 7, "worker_target_expanded": 9, "worker_target_x2": 12, "regrow_wait": 45.0},
		"ice_easy": {"expand_time": 330.0, "expand_home_below": 0, "retreat_hp": 0.4},
		"ice_normal": {"expand_time": 330.0, "expand_home_below": 0, "retreat_hp": 0.4, "attack_ratio": 1.4},   # 8.B4
		"ice_hard": {"expand_time": 330.0, "expand_home_below": 0, "retreat_hp": 0.4},
	}
	for name: String in want:
		var d := AIProfile.DIFFICULTY_NAMES.find(name.get_slice("_", 1))
		var kingdom := name.get_slice("_", 0)
		var file := load("res://data/ai/%s.tres" % name) as AIProfile
		var code := AIProfile.nature(d) if kingdom == "nature" else AIProfile.ice(d)
		for field: String in want[name]:
			var w: Variant = want[name][field]
			for pair in [["file", file], ["code", code]]:
				var p: AIProfile = pair[1]
				if p == null:
					_errors.append("%s: no %s profile" % [name, pair[0]])
					continue
				var v: Variant = p.get(field)
				if not is_equal_approx(float(v), float(w)):
					_errors.append("%s (%s): %s = %s, want %s" % [name, pair[0], field, str(v), str(w)])
	print("part 0: balance-2 bot knobs checked (%d errors)" % _errors.size())


# ---------------------------------------------------------------- runs

func _next_run() -> void:
	if _pairs.is_empty():
		_finish()
		return
	_pair = _pairs.pop_front()
	var ks := _pair.split(":")
	_kingdoms = {PLAYER: StringName(ks[0]), ENEMY: StringName(ks[1] if ks.size() > 1 else "shadow")}
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", _kingdoms[PLAYER])
	main.set(&"enemy_kingdom", _kingdoms[ENEMY])
	bots = {PLAYER: _bot_for(PLAYER), ENEMY: _bot_for(ENEMY)}
	_wait = 0
	_frame = 0
	_started = false
	_m = {}
	for team in [PLAYER, ENEMY]:
		_m[team] = {"army": [], "gathered": [], "workers": [], "army_max": 0, "x1": -1.0, "x2": -1.0, "x1_placed": -1.0,
				"top_item": -1.0, "casts": 0, "workers_x1_max": 0, "workers_x2_max": 0, "regrow": [], "_regrow_seen": 0}
	root.add_child(main)
	current_scene = main


func _bot_for(team: int) -> Node:
	for child in main.get_children():
		if child.get_script() == COMMANDER and int(child.team) == team:
			child.difficulty = 1
			child.profile = null
			child.profile_id = &""
			return child
	var b: Node = COMMANDER.new()
	b.team = team
	b.difficulty = 1
	main.add_child(b)
	return b


func _process(_delta: float) -> bool:
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_next_run()
		return false
	if main == null:
		return true
	if not main.match_started:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_frame += 1
	_t = main.match_time()
	if not _started:
		if not bots[PLAYER].get(&"_ready_done") or not bots[ENEMY].get(&"_ready_done"):
			return false
		_started = true
		for team in [PLAYER, ENEMY]:
			var c: Object = main.wizard_of(team).get(&"spell_caster")
			c.connect(&"spell_cast", func(_id: StringName) -> void: _m[team]["casts"] += 1)
		print("RUN %s start: player %s (%s) vs enemy %s (%s)" % [_pair, bots[PLAYER].ai.id, bots[PLAYER].faction,
				bots[ENEMY].ai.id, bots[ENEMY].faction])
	if _frame % 60 == 0:
		for team in [PLAYER, ENEMY]:
			_sample(team)
	if not main.game_over and _t < _minutes * 60.0:
		return false
	_end_run()
	return false


func _sample(team: int) -> void:
	var m: Dictionary = _m[team]
	var b: Node = bots[team]
	var army := _army_pop(team)
	var workers := _workers(team)
	m["army_max"] = maxi(int(m["army_max"]), army)
	var i: int = (m["army"] as Array).size()
	if i < MARKS.size() and _t >= MARKS[i]:
		m["army"].append(army)
		m["gathered"].append(Economy.for_team(team).gathered_total)
		m["workers"].append(workers)
	var slots: Dictionary = b.get(&"_slot_building")
	if float(m["x1_placed"]) < 0.0 and slots.has(&"X1"):
		m["x1_placed"] = _t
	var x1: bool = b.call(&"_x1_done")
	var x2: bool = b.call(&"_slot_done", &"X2")
	if x1 and float(m["x1"]) < 0.0:
		m["x1"] = _t
	if x2 and float(m["x2"]) < 0.0:
		m["x2"] = _t
	if x1 and not x2:
		m["workers_x1_max"] = maxi(int(m["workers_x1_max"]), workers)
	elif x2:
		m["workers_x2_max"] = maxi(int(m["workers_x2_max"]), workers)
	if _kingdoms[team] == &"ice" and absf(_t - 360.0) < 0.6:
		m["group_out_6"] = bool(b.call(&"_group_out"))
	var items: Variant = b.get(&"items")
	if float(m["top_item"]) < 0.0 and items != null:
		for id: String in (items as Object).get(&"bought"):
			if _tier(id) == 2:
				m["top_item"] = _t
				break
	var regrow: Array = b.launch_after_regrow
	while int(m["_regrow_seen"]) < regrow.size():
		m["regrow"].append([float(regrow[int(m["_regrow_seen"])]), float(b.launch_hp_ratios.back()), bool(b.all_in)])
		m["_regrow_seen"] = int(m["_regrow_seen"]) + 1


func _tier(id: String) -> int:
	if not _tier_cache.has(id):
		var path := "res://data/items/%s.tres" % id
		var r: Resource = load(path) if ResourceLoader.exists(path) else null
		_tier_cache[id] = int(r.get(&"tier")) if r and r.get(&"tier") != null else -1
	return int(_tier_cache[id])


func _end_run() -> void:
	for team in [PLAYER, ENEMY]:
		var m: Dictionary = _m[team]
		m["army_end"] = _army_pop(team)
		m["gathered_end"] = Economy.for_team(team).gathered_total
	var winner := "no winner"
	if main.game_over and int(main.winner_team) >= 0:
		winner = "%s wins (%s side)" % [_kingdoms[int(main.winner_team)], "player" if int(main.winner_team) == PLAYER else "enemy"]
	var p: Dictionary = _m[PLAYER]
	var e: Dictionary = _m[ENEMY]
	var ratio10 := "-"
	if (p["gathered"] as Array).size() >= 2:
		var a := float(p["gathered"][1])
		var b := float(e["gathered"][1])
		ratio10 = "%.2f" % (maxf(a, b) / maxf(1.0, minf(a, b)))
	var line := "RUN %s: %s at %s | army 5/10/15 %s / %s, end %d / %d (max %d / %d) | gathered 5/10/15 %s / %s, end %d / %d (10:00 ratio %s) | workers 5/10 %s / %s | X1 %s / %s, X2 %s / %s | attacks %d / %d, retreats %d / %d | wizard lvl %d / %d | top item %s / %s | casts %d / %d" % [
			_pair, winner, _clock(_t), str(p["army"]), str(e["army"]), p["army_end"], e["army_end"], p["army_max"],
			e["army_max"], str(p["gathered"]), str(e["gathered"]), p["gathered_end"], e["gathered_end"], ratio10,
			str(p["workers"]), str(e["workers"]), _clock(p["x1"]), _clock(e["x1"]), _clock(p["x2"]), _clock(e["x2"]),
			bots[PLAYER].attacks_launched, bots[ENEMY].attacks_launched, bots[PLAYER].retreat_hp_ratios.size(),
			bots[ENEMY].retreat_hp_ratios.size(), _level(PLAYER), _level(ENEMY), _clock(p["top_item"]),
			_clock(e["top_item"]), p["casts"], e["casts"]]
	_results.append(line)
	print(line)
	for team in [PLAYER, ENEMY]:
		_check(team)
	main.queue_free()
	main = null
	_gap = 3


## The 8.B3 done-when checks for this run's side `team`.
func _check(team: int) -> void:
	var m: Dictionary = _m[team]
	var k: StringName = _kingdoms[team]
	var tag := "%s (%s side)" % [_pair, "player" if team == PLAYER else "enemy"]
	if k == &"ice" and _t >= 360.0:
		var placed := float(m["x1_placed"])
		if (placed < 0.0 or placed > 360.0) and not bool(m.get("group_out_6", false)):
			_errors.append("%s: Ice X1 placed at %s (want by 6:00)" % [tag, _clock(placed)])
		print("  %s: Ice X1 placed %s, done %s" % [tag, _clock(placed), _clock(m["x1"])])
	if k == &"nature":
		if int(m["workers_x1_max"]) > 9 or int(m["workers_x2_max"]) > 12:
			_errors.append("%s: Nature workers %d after X1, %d after X2 (want <= 9 / 12)" % [tag, m["workers_x1_max"],
					m["workers_x2_max"]])
		for r: Array in m["regrow"]:
			if float(r[0]) < 44.5 and float(r[1]) < 0.85 and not bool(r[2]):
				_errors.append("%s: Nature relaunched %.0f s after the rally at %.0f %% HP" % [tag, r[0], float(r[1]) * 100.0])
		print("  %s: Nature workers max %d after X1 / %d after X2, relaunches [waited s, HP, all-in] %s" % [tag,
				m["workers_x1_max"], m["workers_x2_max"], str(m["regrow"])])


func _army_pop(team: int) -> int:
	var pop := 0
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == team and not u is Wizard and u.unit_type \
				and not u.unit_type.is_worker and not AICasts.is_summon(u):
			pop += u.unit_type.pop
	return pop


func _workers(team: int) -> int:
	var n := 0
	for node in get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == team and u.unit_type and u.unit_type.is_worker:
			n += 1
	return n


func _level(team: int) -> int:
	var w: Node = main.wizard_of(team)
	return (w as Unit).level if w else 0


static func _clock(t: Variant) -> String:
	var s := float(t)
	if s < 0.0:
		return "-"
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func _finish() -> void:
	for n in _notes:
		print("note: " + n)
	if not _results.is_empty():
		print("---- runs ----")
		for r in _results:
			print(r)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	quit()
