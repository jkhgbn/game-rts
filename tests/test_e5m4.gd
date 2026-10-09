extends SceneTree
## Mission e5m4 "Leftovers" (docs/design/mission-e5-04.md, scripted through MissionHarness; the real-fight timing run is
## tests/test_e5m4_sim.gd). Parts:
##   start   Malrik L3 (cap 5) with 4 Shades + 2 Nightbolts + 2 Grave Hounds, Vessa L3 (bot) with her start army, both
##           keeps and Halls out of the fight (truce until 6:00), 5 banners (home banners owned), tier 1, 300 / 250.
##   steal   a Malrik squad neutralises Vessa's home banner twice as fast as a neutral capture (Spoils +100, L16).
##   neutral a Vessa squad takes a neutral banner x1.25 faster than 12 s.
##   bell    Malrik owning 3 banners counts the bell; dropping to 2 resets it; 30 s = victory (cinematics off), flags.
## Run: godot --headless --path . -s tests/test_e5m4.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e5m4"
const MISSION := "res://missions/mission_e5_04.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "steal", "neutral", "bell"]
var _part := ""
var h: MissionHarness
var main: MissionE5_04
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m4_none.json"}}) as MissionE5_04
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"steal":
			h.steps.add("Malrik steals at x2", _steal, 1500)
		"neutral":
			h.steps.add("Vessa takes a neutral banner faster", _neutral, 1500)
		"bell":
			h.steps.add("the bell", _bell, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


## Freezes both armies (the parts test the banner rules, not fights).
func _freeze() -> void:
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u != main.hero:
			main.set_dormant(u, true)
	for bot in main.commanders:
		bot.set(&"enabled", false)
	main._order_left = 1.0e9   # Vessa's banner plan off too


func _start() -> bool:
	_ok(main.hero.level == 3 and main.hero.level_cap == 5, "Malrik L3, cap 5")
	_ok(_units(0, "shade").size() == 4 and _units(0, "nightbolt").size() == 2 and _units(0, "grave_hound").size() == 2,
			"Malrik's start army")
	_ok(main.vessa != null and main.vessa.level == 3 and _units(1, "flame_guard").size() == 4, "Vessa L3 and her army")
	_ok(main.banners.size() == 5 and main.owned(0) == 1 and main.owned(1) == 1, "5 banners, the home ones owned")
	_ok(main.keep.has_meta(Unit.TRUCE_META), "the yards out of the fight until 6:00")
	_ok(main.tier_system != null and main.tier_system.max_tier == 1, "tier 1 only")
	_ok(Economy.for_team(0).crystals == 300 and EssenceBank.for_team(0).essence == 250, "300 / 250")
	return true


func _steal() -> bool:
	var z := main.banners[&"bn_fire"] as MissionZone
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		var hounds := _units(0, "grave_hound")
		_freeze()
		MissionHarness.immortal(main.hero)
		for u: Variant in hounds:
			main.set_dormant(u as Unit, false)
			MissionHarness.put(u as Unit, z.global_position + Vector3(1.0, 0.0, 0.0))
			(u as Unit).command_stop()
		_v["crystals"] = Economy.for_team(0).crystals
		return false
	if z.owner_side == 1:
		if main.mission_time() - float(_v["t"]) > 15.0:
			_ok(false, "never neutralised")
			return true
		return false
	var took := main.mission_time() - float(_v["t"])
	_ok(took < 9.0, "neutralised at x2 (%.1f s; neutral 12 s / 1.25 for 2 units)" % took)
	_ok(Economy.for_team(0).crystals >= int(_v["crystals"]) + 100 and main.said.has("L16"), "Spoils +100, L16")
	return true


func _neutral() -> bool:
	var z := main.banners[&"bn_west"] as MissionZone
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		var g: Unit = _units(1, "flame_guard")[0]
		_freeze()
		MissionHarness.immortal(main.hero)
		main.set_dormant(g, false)
		MissionHarness.put(g, z.global_position)
		g.command_stop()
		return false
	if z.owner_side != 1:
		if main.mission_time() - float(_v["t"]) > 15.0:
			_ok(false, "never captured")
			return true
		return false
	var took := main.mission_time() - float(_v["t"])
	_ok(took < 11.0 and took > 8.5, "taken in ~9.6 s (%.1f)" % took)
	return true


func _bell() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		_freeze()
		MissionHarness.immortal(main.hero)
		for id: StringName in [&"bn_west", &"bn_orrery"]:
			(main.banners[id] as MissionZone).set_owner_side(0)
		_v["t0"] = main.mission_time()
		return false
	if not _v.has("floor"):
		if main.mission_time() - float(_v["t0"]) < 2.0:
			return false
		_v["floor"] = true
		_ok(main.bell[0] == 0.0, "no count before the bell opens (%.0f)" % main.bell_from())
		MissionHarness.skip_time(main, main.bell_from() - main.mission_time() + 0.5)
		return false
	if not _v.has("reset"):
		if main.bell[0] < 20.0:
			return false
		_v["reset"] = main.mission_time()
		(main.banners[&"bn_orrery"] as MissionZone).set_owner_side(-1)
		return false
	if not _v.has("checked"):
		if main.mission_time() - float(_v["reset"]) < 0.6:
			return false
		_v["checked"] = true
		_ok(main.bell[0] == 0.0 and main.said.has("L12"), "below 3 resets the count (L12 at the start)")
		(main.banners[&"bn_orrery"] as MissionZone).set_owner_side(0)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1 and main.said.has("L21"), "30 s = victory, the bell lines")
	var flags := main.mission_flags()
	_ok(flags.has("e5m4_time") and flags.has("e5m4_spoils"), "flags (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e5m4.json")
	cs.reset()
	cs.on_mission_victory(&"e5m4", main)
	_ok(cs.flag("ep5_complete"), "ep5_complete")
	cs.reset()
	return true
