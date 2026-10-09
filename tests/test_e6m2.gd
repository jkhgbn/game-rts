extends SceneTree
## Mission e6m2 "The Rider at the Gate" (docs/design/mission-e6-02.md, scripted through MissionHarness; the real-fight
## timing runs are tests/test_e6m2_sim.gd (open) and tests/test_e6m2_shut_sim.gd). Parts:
##   start   Torvald L3 (Rime Bolt, Flash Freeze, cap 6), Aldra at the mere (not commandable), 6 Haulers, the army,
##           350 crystals, the Frostgate closed (3 600 HP), 2 Warden Gates, the town (Hall + 8 houses), the Heartfrost
##           3 000 HP, no path through the Long Ice while the gate is closed.
##   open    5:30 the rider; Open = branch open (L10), the gate opens and the path exists, townsfolk walk through and are
##           saved; dawn: victory with e6m2_gate_opened / e6m2_town_saved; the reward chain plays c_e6_gate.
##   shut    the window runs out = branch shut (L13), the town burns; dawn: victory, e6m2_gate_opened false, and
##           StoryFilms.branch_of picks c_e6_gate_shut from the saved flag.
## Run: godot --headless --path . -s tests/test_e6m2.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e6m2"
const MISSION := "res://missions/mission_e6_02.tscn"
const GAP_FRAMES := 3
const SAVE := "user://test_e6m2.json"

var _parts: Array[String] = ["start", "open", "shut"]
var _part := ""
var h: MissionHarness
var main: MissionE6_02
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
		CampaignState.default_path = ""
		print("PASS %s" % TASK_ID if _errors.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return
	_part = _parts.pop_front()
	_v = {}
	h = MissionHarness.new()
	h.task_id = "%s/%s" % [TASK_ID, _part]
	h.timeout_frames = 20000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e6m2_none.json"}}) as MissionE6_02
	match _part:
		"start":
			h.steps.add("start state", _start, 60)
		"open":
			h.steps.add("open the gate, folk saved, dawn", _open, 18000)
		"shut":
			h.steps.add("the fire dies, the town burns, dawn", _shut, 18000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _path_through() -> bool:
	var map := main.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map, Vector3(0.0, 0.0, -30.0), Vector3(0.0, 0.0, 20.0), true)
	if OS.get_cmdline_user_args().has("--verbose"):
		print("    path ", path.size(), " ", path[0] if not path.is_empty() else Vector3.INF, " -> ", path[path.size() - 1] if not path.is_empty() else Vector3.INF, " mid ", path[path.size() / 2] if not path.is_empty() else Vector3.INF)
	return not path.is_empty() and MissionBase._flat(path[path.size() - 1], Vector3(0.0, 0.0, 20.0)) < 2.0


func _start() -> bool:
	var hero := main.hero
	_ok(hero.level == 3 and hero.level_cap == 6 and hero.spell_rank(&"flash_freeze") >= 1, "Torvald L3, Flash Freeze, cap 6")
	_ok(main.aldra != null and not main.aldra.is_commandable(), "Aldra at the mere, not commandable")
	_ok(_units(0, "rime_hauler").size() == 6, "6 Haulers")
	_ok(_units(0, "rimeshield").size() == 6 and _units(0, "frostbow").size() == 2, "6 Rimeshields, 2 Frostbows")
	_ok(Economy.for_team(0).crystals == 350, "350 crystals (%d)" % Economy.for_team(0).crystals)
	_ok(main.gate != null and main.gate.is_closed and is_equal_approx(main.gate.max_hp, 3600.0), "the Frostgate, closed")
	_ok(main.wgates.size() == 2 and main.houses.size() == 9, "2 Warden Gates, the Hall + 8 houses")
	_ok(main.heartfrost != null and is_equal_approx(main.heartfrost.max_hp, 3000.0), "Heartfrost 3 000 HP")
	_ok(not _path_through(), "no path through the Long Ice while the gate is closed")
	_ok(main.tier_system != null and main.tier_system.max_tier == 1, "tier 1")
	return true


func _skip_to_choice() -> bool:
	if not _v.has("skipped"):
		_v["skipped"] = true
		MissionHarness.immortal(main.hero)
		main.heartfrost.setup(1.0e6, 0.0)
		MissionHarness.skip_time(main, 331.0 - main.mission_time())
		return false
	return main.choice_at >= 0.0


func _open() -> bool:
	if not _v.has("chose"):
		if not _skip_to_choice():
			return false
		_v["chose"] = true
		_ok(main.said.has("L9") and main.objective_state("obj_choice") == "active", "the rider, the window")
		main.choose_open()
		_ok(main.branch == &"open" and main.gate_opened and not main.gate.is_closed and main.said.has("L10"), "branch open")
		_v["t"] = main.mission_time()
		return false
	if not _v.has("path"):
		if main.mission_time() - float(_v["t"]) < 2.0:
			return false
		_v["path"] = true
		_ok(_path_through(), "a path through the open gate")
		return false
	if not _v.has("folk"):
		if main.saved < 8:
			if main.mission_time() - float(_v["t"]) > 120.0:
				_ok(false, "8 townsfolk not saved in 2:00 (%d, sent %d)" % [main.saved, main.folk_sent])
				return true
			for n in main.get_tree().get_nodes_in_group(&"units"):
				var u := n as Unit
				if u and int(u.team) == Unit.Team.ENEMY:
					u.take_damage(1.0e6, null)
			return false
		_v["folk"] = true
		_ok(main.said.has("L18"), "E7: the first 8 saved, L18")
		for p in main.folk.duplicate():
			MissionHarness.put(p as Unit, Vector3(0.0, 0.0, -20.0))
		main.saved = 24
		MissionHarness.skip_time(main, 1201.0 - main.mission_time())
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory at dawn")
	var flags := main.mission_flags()
	_ok(flags.get("e6m2_gate_opened") == true and flags.get("e6m2_town_saved") == true and int(flags.get("e6m2_saved_count", 0)) >= 12,
			"open flags (%s)" % str(flags))
	_ok(main.said.has("L21"), "the open dawn lines")
	var cs := CampaignState.open(SAVE)
	cs.reset()
	cs.on_mission_victory(&"e6m2", main)
	CampaignState.default_path = SAVE
	_ok(cs.unlocked.has(&"e6m3") and StoryFilms.branch_of(&"c_e6_gate") == &"c_e6_gate", "e6m3 unlocked, c_e6_gate (open)")
	cs.reset()
	CampaignState.default_path = ""
	return true


func _shut() -> bool:
	if not _v.has("chose"):
		if not _skip_to_choice():
			return false
		_v["chose"] = true
		MissionHarness.skip_time(main, 100.0)
		return false
	if not _v.has("shut"):
		if main.branch != &"shut":
			return false
		_v["shut"] = true
		_ok(not main.gate_opened and main.said.has("L13") and main.objective_state("obj_town") == "failed", "the fire died: shut")
		_v["hp"] = (main.town_hall as Building).hp
		_v["t"] = main.mission_time()
		return false
	if not _v.has("burn"):
		if main.mission_time() - float(_v["t"]) < 3.0:
			return false
		_v["burn"] = true
		_ok((main.town_hall as Building).hp < float(_v["hp"]) - 20.0, "the town burns")
		MissionHarness.skip_time(main, 1201.0 - main.mission_time())
		return false
	if h.ended < 0:
		for n in main.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and int(u.team) == Unit.Team.ENEMY:
				u.take_damage(1.0e6, null)
		return false
	_ok(h.ended == 1, "victory at dawn (shut)")
	var flags := main.mission_flags()
	_ok(flags.get("e6m2_gate_opened") == false and flags.get("e6m2_town_saved") == false, "shut flags (%s)" % str(flags))
	_ok(main.said.has("L25"), "the shut dawn lines")
	var cs := CampaignState.open(SAVE)
	cs.reset()
	cs.on_mission_victory(&"e6m2", main)
	CampaignState.default_path = SAVE
	_ok(StoryFilms.branch_of(&"c_e6_gate") == &"c_e6_gate_shut", "c_e6_gate_shut picked by the flag")
	cs.reset()
	CampaignState.default_path = ""
	return true
