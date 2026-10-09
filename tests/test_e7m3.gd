extends SceneTree
## Mission e7m3 "The Outwall" (docs/design/mission-e7-03.md, scripted through MissionHarness; the real-fight runs are
## tests/test_e7m3_sim.gd (people path) and tests/test_e7m3_passive_sim.gd). Parts:
##   start    Torvald L5 (cap 8), the Glass Hall at the Citadel, Aldra called, 5 rows of 8, 2 chained mammoths.
##   bells    a bell refuses with an enemy within 8 m, rings in 3 s once clear; its 8 dockers walk and shelter; an
##            uncontested raid for 20 s burns a row ("check 2"); the tithe pays 10 gold / 15 s per held pit ("check 4").
##   lost     lost >= 30 = defeat.
##   dawn     22:00 = victory whatever the secondaries (cinematics off), flags only, next c_e7_pits.
## Run: godot --headless --path . -s tests/test_e7m3.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e7m3"
const MISSION := "res://missions/mission_e7_03.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "bells", "lost", "dawn"]
var _part := ""
var h: MissionHarness
var main: MissionE7_03
var _errors: Array[String] = []
var _v := {}
var _gap := 0
var _finished := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_parts.assign(a.trim_prefix("--only=").split(","))
	_open_next()


func _process(_delta: float) -> bool:
	if _finished:
		return true
	if _gap > 0:
		_gap -= 1
		if _gap == 0:
			_open_next()
		return _finished
	if h == null or main == null:
		return _finished
	if h.tick():
		for e in h.errors:
			_errors.append("%s: %s" % [_part, e])
		main.queue_free()
		main = null
		h = null
		_gap = GAP_FRAMES
	return _finished


func _open_next() -> void:
	if _parts.is_empty():
		_finished = true
		print("PASS %s" % TASK_ID if _errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return
	_part = _parts.pop_front()
	_v = {}
	h = MissionHarness.new()
	h.task_id = "%s/%s" % [TASK_ID, _part]
	h.timeout_frames = 15000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e7m3_none.json"}}) as MissionE7_03
	match _part:
		"start":
			h.steps.add("start state", _start, 60)
		"bells":
			h.steps.add("bells, shelter, burning, tithe", _bells, 8000)
		"lost":
			h.steps.add("lost 30 = defeat", _lost, 2000)
		"dawn":
			h.steps.add("dawn = victory, flags", _dawn, 4000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _start() -> bool:
	var m := main
	_ok(m.hero.level == 5 and m.hero.level_cap == 8, "Torvald L5, cap 8")
	_ok(m.keep != null and m.keep.tier == 3, "the Glass Hall at the Citadel")
	var roster := HelperRoster.for_team(0)
	_ok(roster != null and roster.state() != &"none", "Aldra called (%s)" % (roster.state() if roster else &"-"))
	_ok(m.row_people.size() == 5 and int(m.row_people[&"R1"]) == 8, "5 rows of 8")
	_ok(m.mammoths.size() == 2 and not m.mammoths_free, "2 chained mammoths")
	_ok(m.gold() == 0, "0 gold")
	return true


func _enemies_at(at: Vector3, r: float) -> void:
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.ENEMY and MissionBase._flat(u.global_position, at) < r:
			u.take_damage(1.0e6, null)


func _bells() -> bool:
	var m := main
	var r1: Vector3 = MissionE7_03.ROWS[&"R1"]
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		var foe := m.spawn_rows([["flame_guard", 1]], r1 + Vector3(4.0, 0.0, 0.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		foe.aggro_range = 0.0
		foe.attack_damage = 0.0
		_v["foe"] = foe
		MissionHarness.put(m.hero, r1)
		_v["t"] = m.mission_time()
		return false
	if not _v.has("b"):
		if m.mission_time() - float(_v["t"]) < 5.0:
			return false
		_v["b"] = true
		_ok(not m.bells_rung.has(&"R1"), "refused with an enemy within 8 m")
		_enemies_at(r1, 12.0)
		_v["t"] = m.mission_time()
		return false
	if not _v.has("c"):
		if m.mission_time() - float(_v["t"]) < 4.0:
			return false
		_v["c"] = true
		_ok(m.bells_rung.has(&"R1") and m.walkers.size() == 8, "rung in 3 s, 8 walk (%d)" % m.walkers.size())
		MissionHarness.put(m.hero, MissionE7_03.START)
		_v["t"] = m.mission_time()
		return false
	if not _v.has("d"):
		if m.sheltered < 8 and m.mission_time() - float(_v["t"]) < 40.0:
			return false
		_v["d"] = true
		_ok(m.sheltered == 8, "8 sheltered (%d)" % m.sheltered)
		# an uncontested raid on R2 (Brannet's row) for 20 s burns it
		var foe := m.spawn_rows([["flame_guard", 1]], (MissionE7_03.ROWS[&"R2"] as Vector3) + Vector3(2.0, 0.0, 0.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		foe.aggro_range = 0.0
		foe.attack_damage = 0.0
		m.clear_waves()
		_v["t"] = m.mission_time()
		return false
	if not _v.has("e"):
		if m.mission_time() - float(_v["t"]) < 22.0:
			return false
		_v["e"] = true
		_ok(m.rows_taken.has(&"R2") and m.lost >= 8, "an uncontested raid burns a row (lost %d)" % m.lost)
		_enemies_at(MissionE7_03.ROWS[&"R2"], 10.0)
		# the tithe: from 9:00, one held pit pays 10 gold / 15 s
		for pid: StringName in MissionE7_03.PITS:
			_enemies_at(MissionE7_03.PITS[pid], 30.0)
		for id in ["PG_R1", "PG_R2", "PG_R3", "LA1", "MK1", "LA2"]:
			m.fire_once(StringName(id))
		MissionHarness.skip_time(m, 541.0 - m.mission_time())
		return false
	if not _v.has("f"):
		if not m.has_fired(&"E6"):
			return false
		_v["f"] = true
		var p1: Vector3 = MissionE7_03.PITS[&"P1"]
		_enemies_at(p1, 30.0)
		var s := m.spawn_rows([["rimeshield", 1]], p1, 0.0, Unit.Team.PLAYER, false)[0] as Unit
		MissionHarness.immortal(s)
		_v["g0"] = m.gold()
		m._tithe_t = 0.0
		_v["t"] = m.mission_time()
		return false
	if m.mission_time() - float(_v["t"]) < 31.0:
		_enemies_at(MissionE7_03.PITS[&"P1"], 12.0)
		return false
	var got := m.gold() - int(_v["g0"])
	_ok(got >= 10 and got <= 30 and got % 10 == 0, "the tithe: 10 gold / 15 s (%d in 31 s)" % got)
	return true


func _lost() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m._add_lost(29)
		_ok(h.ended < 0, "29 lost is not a defeat")
		m._add_lost(1)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and m.said.has("L31"), "30 lost = defeat")
	return true


func _dawn() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		if m.keep:
			MissionHarness.immortal(m.keep)
		for id in ["LA1", "MK1", "LA2", "MK2", "LA3", "MK3", "NT1s", "NT1e", "NT2", "NT3s", "NT3e", "PG_R1", "PG_R2", "PG_R3", "E10", "E11"]:
			m.fire_once(StringName(id))
		MissionHarness.skip_time(m, MissionE7_03.DAWN_AT + 1.0 - m.mission_time())
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "dawn = victory")
	_ok(m.said.has("L28") and m.said.has("L29"), "L28, L29 (not the people)")
	var cs := CampaignState.open("user://test_e7m3.json")
	cs.reset()
	cs.on_mission_victory(&"e7m3", m)
	_ok(not cs.flag("e7m3_people") and int(cs.flag_value("e7m3_sheltered", -1)) == 0, "flags")
	_ok(StringName(m.mission_rewards().get("next", &"")) == &"c_e7_pits", "next: c_e7_pits")
	_ok(CampaignState.FILM_BRANCHES.has(&"c_e7_pits"), "the pits branch film")
	cs.reset()
	return true
