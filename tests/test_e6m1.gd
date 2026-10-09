extends SceneTree
## Mission e6m1 "A Hundred Winters" (docs/design/mission-e6-01.md, scripted through MissionHarness; the real-fight timing
## run is tests/test_e6m1_sim.gd). Parts:
##   start   Torvald L2 (Rime Bolt, cap 5), young Aldra (not commandable), 5 Haulers, 4 Rimeshields + 2 Shardcasters,
##           300 crystals, Rime Keep 3 000 HP, the Heartfrost 2 000 HP (PLAYER, only ENEMY damage), the longhouse,
##           28 snowbanks, tier 1, objectives.
##   floe    4 Wardens (weight 8) on F7 add weight cracks; the break sinks them (dead) and moves a Rimeshield off unhurt.
##   final   winter 3: W3c dead = E12, victory (cinematics off) with the flags; the reward table writes flags only and
##           its film chain c_e6_lake -> e6m2 unlocks e6m2.
## Run: godot --headless --path . -s tests/test_e6m1.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e6m1"
const MISSION := "res://missions/mission_e6_01.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "floe", "final"]
var _part := ""
var h: MissionHarness
var main: MissionE6_01
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e6m1_none.json"}}) as MissionE6_01
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"floe":
			h.steps.add("Wardens sink, the army is spared", _floe, 3000)
		"final":
			h.steps.add("winter 3 ends, victory, flags", _final, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	var hero := main.hero
	_ok(hero is Wizard and hero.level == 2 and hero.level_cap == 5 and hero.spell_rank(&"rime_bolt") >= 1,
			"Torvald L2, Rime Bolt, cap 5")
	_ok(main.player_kingdom == &"ice", "the Ice kingdom (Torvald)")
	_ok(main.aldra != null and not main.aldra.is_commandable(), "Aldra, not commandable")
	_ok(_units(0, "rime_hauler").size() == 5, "5 Haulers")
	_ok(_units(0, "rimeshield").size() == 4 and _units(0, "shardcaster").size() == 2, "4 Rimeshields + 2 Shardcasters")
	_ok(Economy.for_team(0).crystals == 300, "300 crystals (%d)" % Economy.for_team(0).crystals)
	_ok(main.keep != null and is_equal_approx(main.keep.max_hp, 3000.0), "Rime Keep 3 000 HP")
	_ok(main.heartfrost != null and is_equal_approx(main.heartfrost.max_hp, 2000.0) and main.heartfrost.team == 0,
			"Heartfrost 2 000 HP, PLAYER")
	main.heartfrost.take_damage(100.0, hero)
	_ok(is_equal_approx(main.heartfrost.hp, 2000.0), "a PLAYER hit does not hurt the Heartfrost")
	_ok(main.longhouse != null and main.longhouse.is_alive(), "the longhouse")
	_ok(main.get_tree().get_nodes_in_group(&"snowbanks").size() == 28, "28 snowbanks")
	_ok(main.tier_system != null and main.tier_system.max_tier == 1, "tier 1 only")
	_ok(main.objective_state("obj_winters") == "active" and main.objective_state("sec_sentinels") == "", "objectives")
	_ok(EssenceBank.for_team(0) != null and EssenceBank.for_team(0).essence >= 399, "essence 400")
	return true


func _floe() -> bool:
	var lake := main.lake
	var p := Vector3(cos(deg_to_rad(315.0)) * 14.0, 0.0, sin(deg_to_rad(315.0)) * 14.0)
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		MissionHarness.immortal(main.hero)
		_v["wardens"] = main.spawn_rows([["hollow_warden", 4]], p, 1.0, Unit.Team.ENEMY, false)
		for u: Variant in _v["wardens"]:
			(u as Unit).aggro_range = 0.0
		var shield := main.spawn_rows([["rimeshield", 1]], p + Vector3(-1.5, 0.0, 0.0), 0.0, Unit.Team.PLAYER, false)[0] as Unit
		shield.aggro_range = 0.0
		_v["shield"] = shield
		return false
	if not _v.has("weight"):
		if lake.cracks[7] < 1.0:
			if main.mission_time() - float(_v["t"]) > 9.0:
				_ok(false, "no weight crack on F7 in 9 s (%.1f)" % lake.cracks[7])
				return true
			return false
		_v["weight"] = true
		var shield := _v["shield"] as Unit
		for u: Variant in _v["wardens"]:
			MissionHarness.put(u as Unit, p + Vector3(randf() - 0.5, 0.0, randf() - 0.5))
		MissionHarness.put(shield, p + Vector3(-1.0, 0.0, 0.0))
		lake.crack(7, 4.0, main.hero)
		return false
	var dead := (_v["wardens"] as Array).all(func(u: Variant) -> bool: return not is_instance_valid(u) or not (u as Unit).is_alive())
	_ok(dead, "the 4 Wardens sank")
	var shield := _v["shield"] as Unit
	_ok(shield.is_alive() and is_equal_approx(shield.hp, shield.max_hp) and GlasswaterLake.floe_at(shield.global_position) != 7,
			"the Rimeshield moved off unhurt (%.0f / %.0f)" % [shield.hp, shield.max_hp])
	_ok(main.has_fired(&"E4") and main.said.has("L11"), "E4: L11")
	return true


func _final() -> bool:
	var hero := main.hero
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(hero)
		main.heartfrost.setup(1.0e6, 0.0)
		MissionHarness.skip_time(main, 1100.0 - main.mission_time())
		return false
	if not _v.has("w3c"):
		if not main.waves_fired.has("w3c"):
			return false
		_v["w3c"] = true
		_ok(main.season == 5 and main.is_winter() and main.said.has("L20"), "winter 3, W3c, L20")
		_ok(main.winter3_units.any(func(u: Variant) -> bool: return is_instance_valid(u) \
				and String((u as Unit).unit_type.id) == "stair_breaker"), "the Stair-Breaker leads W3c")
		var foes: Array = main.get_tree().get_nodes_in_group(&"units").filter(func(n: Node) -> bool:
			return (n as Unit).team == Unit.Team.ENEMY)
		MissionHarness.kill(foes)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	_ok(main.objective_state("obj_winters") == "done" and main.said.has("L27"), "obj_winters done, L27")
	var flags := main.mission_flags()
	_ok(flags.has("e6m1_time"), "e6m1_time (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e6m1.json")
	cs.reset()
	var items_before := JSON.stringify(cs.items)
	cs.on_mission_victory(&"e6m1", main)
	_ok(cs.flag("ep6_started") and cs.unlocked.has(&"e6m2") and JSON.stringify(cs.items) == items_before,
			"flags only, e6m2 unlocked")
	cs.reset()
	return true
