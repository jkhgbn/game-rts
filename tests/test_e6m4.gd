extends SceneTree
## Mission e6m4 "The First Crack" (docs/design/mission-e6-04.md, scripted through MissionHarness; the real-fight run is
## tests/test_e6m4_sim.gd). Parts:
##   start   Ysolde L4 (cap 7), Torvald the ALLY seat at L5 with his army, the seal 4 000 HP, 4 Warden Gates, the
##           Heartwood, the Stronghold closed until 3:30, the hold at 0.
##   hold    from 1:00 the hold grows; an ENEMY within 6 m of the stone pauses it; a Thornling dying 20 m from the stone
##           costs the seal 15, one at 30 m costs 0, a Warden costs 0.
##   final   100 %: victory (cinematics off), flags only, the reward's next is ep6_ending.
## Run: godot --headless --path . -s tests/test_e6m4.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e6m4"
const MISSION := "res://missions/mission_e6_04.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "hold", "final"]
var _part := ""
var h: MissionHarness
var main: MissionE6_04
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
	h.timeout_frames = 12000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e6m4_none.json"}}) as MissionE6_04
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"hold":
			h.steps.add("the hold, the pause, the Hollow counts", _hold, 6000)
		"final":
			h.steps.add("100 %, victory, flags", _final, 4000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	var hero := main.hero
	_ok(hero.level == 4 and hero.level_cap == 7 and hero.spell_rank(&"wild_bloom") >= 1, "Ysolde L4, Wild Bloom, cap 7")
	_ok(main.torvald != null and main.torvald.level == 5 and int(main.torvald.team) == MissionE6_04.ALLY_SEAT, "Torvald, ALLY, L5")
	_ok(_units(MissionE6_04.ALLY_SEAT, "rimeshield").size() == 6, "Torvald's 6 Rimeshields")
	_ok(_units(0, "thornling").size() == 8 and _units(0, "sprigling").size() == 6, "8 Thornlings, 6 Spriglings")
	_ok(Economy.for_team(0).crystals == 400, "400 crystals (%d)" % Economy.for_team(0).crystals)
	_ok(main.seal != null and is_equal_approx(main.seal.max_hp, 4000.0), "the seal 4 000")
	_ok(main.wgates.size() == 4, "4 Warden Gates")
	_ok(main.tier_system != null and main.tier_system.max_tier == 1, "the Stronghold closed before 3:30")
	_ok(main.hold == 0.0 and main.objective_state("obj_hold") == "active", "hold 0 %")
	_ok(Teams.is_ally(0, MissionE6_04.ALLY_SEAT) and Teams.is_hostile(0, 1), "ally / hostile teams")
	return true


func _hold() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		main.seal.setup(4000.0, 0.0)
		MissionHarness.skip_time(main, 70.0 - main.mission_time())
		return false
	if not _v.has("grew"):
		if main.mission_time() < 75.0:
			return false
		_v["grew"] = main.hold
		_ok(main.hold > 0.0, "the hold grows from 1:00 (%.3f)" % main.hold)
		var w := main.spawn_rows([["hollow_warden", 1]], Vector3(3.0, 0.0, 0.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		w.aggro_range = 0.0
		w.command_stop()
		_v["w"] = w
		_v["t2"] = main.mission_time()
		return false
	if not _v.has("paused"):
		if main.mission_time() - float(_v["t2"]) < 3.0:
			return false
		_v["paused"] = true
		_ok(main.hold_paused, "paused with a Warden at 3 m")
		_v["h"] = main.hold
		return false
	if not _v.has("counts"):
		_ok(absf(main.hold - float(_v["h"])) < 0.0005, "no progress while paused")
		_v["counts"] = true
		var hp := main.seal.hp
		(_v["w"] as Unit).take_damage(1.0e6, null)
		_ok(is_equal_approx(main.seal.hp, hp), "a Warden's death costs 0")
		var t20 := main.spawn_rows([["thornling", 1]], Vector3(20.0, 0.0, 0.0), 0.0, Unit.Team.PLAYER, false)[0] as Unit
		t20.take_damage(1.0e6, null)
		_ok(absf(hp - main.seal.hp - 15.0) < 0.5, "a Thornling at 20 m costs 15 (%.1f)" % (hp - main.seal.hp))
		var hp2 := main.seal.hp
		var t30 := main.spawn_rows([["thornling", 1]], Vector3(30.0, 0.0, 0.0), 0.0, Unit.Team.PLAYER, false)[0] as Unit
		t30.take_damage(1.0e6, null)
		_ok(is_equal_approx(main.seal.hp, hp2), "a Thornling at 30 m costs 0")
		_ok(main.said.has("L7"), "E2: L7")
		MissionHarness.skip_time(main, 215.0 - main.mission_time())
		return false
	if main.mission_time() < 216.0:
		return false
	_ok(main.tier_system.max_tier == 2 and main.has_fired(&"E3"), "the Stronghold opens at 3:30")
	return true


func _final() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		main.seal.setup(1.0e6, 0.0)
		MissionHarness.skip_time(main, 61.0 - main.mission_time())
		return false
	if not _v.has("set"):
		if main.mission_time() < 62.0:
			return false
		_v["set"] = true
		main.hold = 0.995
		return false
	if h.ended < 0:
		for n in main.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and int(u.team) == Unit.Team.ENEMY:
				u.take_damage(1.0e6, null)
		return false
	_ok(h.ended == 1, "victory")
	_ok(main.said.has("L22") and main.objective_state("obj_hold") == "done", "L22, obj_hold done")
	var cs := CampaignState.open("user://test_e6m4.json")
	cs.reset()
	var items_before := JSON.stringify(cs.items)
	cs.on_mission_victory(&"e6m4", main)
	_ok(cs.flag("ep6_complete") and JSON.stringify(cs.items) == items_before, "flags only, ep6_complete")
	_ok(StringName(main.mission_rewards().get("next", &"")) == &"ep6_ending", "next: ep6_ending")
	cs.reset()
	return true
