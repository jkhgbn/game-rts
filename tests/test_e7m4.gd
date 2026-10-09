extends SceneTree
## Mission e7m4 "The Year of Two Skies" (docs/design/mission-e7-04.md, scripted through MissionHarness; the real-fight
## run is tests/test_e7m4_sim.gd). Parts:
##   start   Torvald L6 (cap 8), the Citadel, Aldra, Malrik ALLY L7 + Hush, Vessa / Ysolde L7, 3 crimson galleys,
##           Kesh with Aurivane, Morrow with Malrik ("check 9": no save = no extras, 3 silver galleys).
##   turn    the rock taken -> P2 (Aurivane withdraws), 40 s -> the turn: every unit of Malrik's seat reads ENEMY_2,
##           no attack during the 10 s grace, Ossavar on side 0, silver galleys; a pay-off spends the gold and removes
##           the dragon ("checks 2-4").
##   rock    Malrik's side holding the rock 30 s after the turn = defeat ("check 6").
##   still   from 22:00, 3 channels of 15 s with 30 s between = victory, every enemy frozen ("check 7"); flags only,
##           next ep7_ending.
## Run: godot --headless --path . -s tests/test_e7m4.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e7m4"
const MISSION := "res://missions/mission_e7_04.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "turn", "rock", "still"]
var _part := ""
var h: MissionHarness
var main: MissionE7_04
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
	h.timeout_frames = 20000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e7m4_none.json"}}) as MissionE7_04
	match _part:
		"start":
			h.steps.add("start state", _start, 60)
		"turn":
			h.steps.add("P2, the turn, the grace, a pay-off", _turn, 9000)
		"rock":
			h.steps.add("the rock lost 30 s = defeat", _rock, 9000)
		"still":
			h.steps.add("Still the Sea = victory", _still, 16000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _start() -> bool:
	var m := main
	_ok(m.hero.level == 6 and m.hero.level_cap == 8 and m.hero.spell_points == 5, "Torvald L6, cap 8, 5 points")
	_ok(m.keep != null and m.keep.tier == 3, "the Citadel")
	_ok(m.malrik != null and int(m.malrik.team) == Teams.ALLY and m.malrik.level == 7, "Malrik ALLY L7")
	_ok(m.hush != null and int(m.hush.team) == Teams.ALLY, "Hush beside him")
	_ok(m.vessa.level == 7 and m.ysolde.level == 7, "Vessa / Ysolde L7")
	_ok(m.crimson.size() == 3, "3 crimson galleys")
	_ok(int(m.dragon("gilt_dragon").team) == Unit.Team.ENEMY and int(m.dragon("prism_dragon").team) == Teams.ALLY, "Kesh / Morrow")
	_ok(not m.people and not m.pits and m.silver_goal() == 3, "no save: no extras, 3 silver galleys")
	_ok(m.gold() == 0, "0 gold")
	return true


func _seat3_all_enemy() -> bool:
	for n in main.seat_nodes(&"malrik"):
		if int(n.get(&"team")) != Teams.ENEMY_2:
			return false
	return main.seat_nodes(&"malrik").size() > 5


func _turn() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m.rock.set_owner_side(0)
		m._on_rock_captured(m.rock, 0)
		_ok(m.phase == 2 and m.objective_state("obj_truce") == "active", "P2: the truce")
		_v["t"] = m.mission_time()
		return false
	if not _v.has("b"):
		if m.turn_time < 0.0:
			return false
		_v["b"] = true
		_ok(m.mission_time() - float(_v["t"]) >= 39.0, "the truce lasts 40 s")
		_ok(_seat3_all_enemy(), "every unit of Malrik's seat is ENEMY_2")
		_ok(int(m.dragon("ossavar_story").team) == 0, "Ossavar on side 0")
		_ok(m.silver.size() == 3, "3 silver galleys")
		_ok(m.said.has("L22") and m.said.has("L25a"), "No. / L25a")
		var foes := 0
		for n in m.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not u is Wizard and not u.is_worker():
				foes += 1
		_v["hp0"] = _side0_hp()
		_v["t"] = m.mission_time()
		return false
	if not _v.has("c"):
		if m.mission_time() - float(_v["t"]) < 8.0:
			return false
		_v["c"] = true
		_ok(_side0_hp() >= float(_v["hp0"]) - 1.0, "no attack during the grace (%.0f -> %.0f)" % [float(_v["hp0"]), _side0_hp()])
		if m.gold() < 400:
			_ok(m.pay_home("gilt_dragon") == MissionE7Base.MSG_NO_GOLD, "a pay-off refused without gold")
		m.add_gold(1000)
		var g0 := m.gold()
		_ok(m.pay_home("gilt_dragon") == "" and m.gold() == g0 - 400, "Kesh paid home (%d -> %d)" % [g0, m.gold()])
		_ok(m.paid.has("gilt_dragon") and not m.dragons.has("gilt_dragon"), "Kesh leaves for good")
		return false
	return true


func _side0_hp() -> float:
	var s := 0.0
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == 0:
			s += u.hp
	return s


func _rock() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m.fire_once(&"E7")
		m.fire_once(&"E8")
		m.fire_once(&"E9")
		m._turn_end()
		MissionHarness.skip_time(m, 12.0)
		return false
	if not _v.has("b"):
		if m.mission_time() < m.turn_time + 11.0:
			return false
		_v["b"] = true
		m.rock.set_owner_side(1)
		m.rock.locked = true
		_v["t"] = m.mission_time()
		return false
	if h.ended < 0:
		if m.mission_time() - float(_v["t"]) > 40.0:
			_ok(false, "no defeat after 40 s")
			return true
		return false
	_ok(h.ended == 0 and m.mission_time() - float(_v["t"]) >= 29.0, "Malrik's rock 30 s = defeat (%.0f s)" % (m.mission_time() - float(_v["t"])))
	return true


func _still() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m.fire_once(&"E7")
		m.fire_once(&"E8")
		m.fire_once(&"E9")
		m._turn_end()
		for row: Array in MissionE7_04.ASSAULTS:
			m.fire_once(StringName(row[1]))
		m.rock.set_owner_side(0)
		m.rock.locked = true
		MissionHarness.skip_time(m, m.still_at() + 1.0 - m.mission_time())
		return false
	if not _v.has("b"):
		if m.objective_state("obj_still") != "active":
			return false
		_v["b"] = true
		_ok(m.mission_time() >= MissionE7_04.STILL_AT, "not before 22:00")
		return false
	if h.ended < 0:
		MissionHarness.put(m.hero, MissionE7Base.ROCK)
		for n in m.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and int(u.team) == Teams.ENEMY_2 and u != m.malrik and MissionBase._flat(u.global_position, MissionE7Base.ROCK) < 20.0:
				u.take_damage(1.0e6, null)
		if m.stage == 1 and not _v.has("gap"):
			_v["gap"] = m.mission_time()
		return false
	_ok(h.ended == 1 and m.stage == 3, "three stages = victory")
	_ok(m.said.has("L39") and m.said.has("L40"), "Enough.")
	var cs := CampaignState.open("user://test_e7m4.json")
	cs.reset()
	var items_before := JSON.stringify(cs.items)
	cs.on_mission_victory(&"e7m4", m)
	_ok(cs.flag("e7_turned") and cs.flag("episode7_complete") and JSON.stringify(cs.items) == items_before, "flags only")
	_ok(StringName(m.mission_rewards().get("next", &"")) == &"ep7_ending", "next: ep7_ending")
	cs.reset()
	return true
