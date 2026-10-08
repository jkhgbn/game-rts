extends SceneTree
## Mission e4m2 "The Green Road" (docs/design/mission-e4-02.md, scripted through MissionHarness; the real-fight timing
## run is tests/test_e4m2_sim.gd). Parts:
##   start   Ysolde L4 + 3 points cap 7, 400 crystals, essence 150 + 500 (no save), the Heartwood at tier 2, 40 people in
##           4 convoys of 10 (30 needed), Cinderwatch, Ashby + 6 guards, Maelis at the Lantern, 2 totems, A1-A3, Hush.
##   walk    a convoy with no enemy on the road arrives (37-45 s); the ring is refused while it walks.
##   cower   a Shade within 10 m stops a walker; it walks on 2 s after the Shade dies.
##   brook   the crossing slow is gone once both totems die (sec_brook).
##   lost    11 of 40 lost = defeat.
##   win     every convoy through = victory; flags (Ysolde's essence, folk arrived).
## Run: godot --headless --path . -s tests/test_e4m2.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e4m2"
const MISSION := "res://missions/mission_e4_02.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "walk", "cower", "brook", "lost", "win"]
var _part := ""
var h: MissionHarness
var main: MissionE4_02
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
	h.timeout_frames = 30000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e4m2_none.json"}}) as MissionE4_02
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"walk":
			h.steps.add("an open road: 37-45 s", _walk, 5000)
		"cower":
			h.steps.add("cower and walk on", _cower, 5000)
		"brook":
			h.steps.add("the brook thaws", _brook, 600)
		"lost":
			h.steps.add("11 lost = defeat", _lost, 900)
		"win":
			h.steps.add("all through = victory", _win, 20000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


## Every awake enemy soldier off the map's road (dormant ambushes stay asleep).
func _clear_road() -> void:
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == 1 and not main.is_dormant(u):
			u.take_damage(1.0e7, null)


func _start() -> bool:
	_ok(main.hero.level == 4 and main.hero.level_cap == 7 and main.hero.spell_points == 3, "Ysolde L4 + 3 points cap 7")
	_ok(Economy.for_team(0).crystals == 400 and EssenceBank.for_team(0).essence == 650, "400 / 650 (%d / %d)" % [
			Economy.for_team(0).crystals, EssenceBank.for_team(0).essence])
	_ok(main.keep.tier == 2, "the Heartwood at tier 2")
	_ok(main.folk_total == 40 and main.folk_needed == 30 and main.convoys.size() == 4, "40 people, 30 needed, 4 convoys")
	_ok(_units(0, "meadow_folk").size() == 40, "40 at the green")
	_ok(main.ashby != null and _units(0, "flame_guard").size() == 6, "Ashby + 6 guards")
	_ok(main.maelis != null and main.wren != null and main.hush != null, "Maelis, Wren, Hush")
	_ok(main.totems.size() == 2 and main.groups.size() == 3, "2 totems, A1-A3")
	_ok(main.is_dormant((main.groups[&"A1"] as Array)[0]) and not main.is_dormant((main.groups[&"A2"] as Array)[0]),
			"A1 dormant, A2 awake")
	_ok(main.objective_state("obj_convoys") == "active", "obj_convoys")
	return true


func _walk() -> bool:
	if not _v.has("t"):
		MissionHarness.immortal(main.hero)
		for gid: StringName in main.groups:
			MissionHarness.kill(main.groups[gid])
		_clear_road()
		_v["t"] = main.mission_time()
		_ok(main.ring() == "", "the first ring sends convoy 1")
		_ok(main.ring() != "", "the ring is refused while it walks")
		return false
	_clear_road()
	if main.arrived < 10:
		return false
	var took := main.mission_time() - float(_v["t"])
	print("    convoy 1 through in %.1f s" % took)
	_ok(took >= 35.0 and took <= 50.0, "37-45 s on an open road (%.1f)" % took)
	return true


func _cower() -> bool:
	if not _v.has("t"):
		for gid: StringName in main.groups:
			MissionHarness.kill(main.groups[gid])
		_clear_road()
		main.ring()
		_v["t"] = true
		return false
	var walkers: Array = (main.convoys[0] as Dictionary)["walkers"]
	var lead: Unit = null
	for w: Variant in walkers:
		if is_instance_valid(w) and (w as Unit).is_alive():
			lead = w
			break
	if lead == null:
		return false
	if not _v.has("shade"):
		if MissionBase._flat(lead.global_position, MissionE4_02.LANTERN) < 12.0:
			return false
		var shade := main.make_unit("shade")
		main._spawn(shade, Unit.Team.ENEMY, lead.global_position + Vector3(0.0, 0.0, 8.0))
		shade.aggro_range = 0.0
		shade.attack_damage = 0.0
		MissionHarness.immortal(shade)
		_v["shade"] = shade
		_v["since"] = 0
		return false
	if not _v.has("stopped"):
		if float(main._cower.get(lead, 0.0)) < 0.0:   # cowering (stopped by the mission)
			var s: Unit = _v["shade"]
			_v["stopped"] = main.mission_time()
			s.death_guard = Callable()
			s.take_damage(1.0e7, null)
		return false
	if not _v.has("moved"):
		_clear_road()   # nothing else may hold the walker (a stray hunter made this flaky: 30 s)
		if not main._cower.has(lead) and lead.has_move_order():
			_v["moved"] = main.mission_time() - float(_v["stopped"])
		return false
	_ok(float(_v["moved"]) >= 1.5 and float(_v["moved"]) <= 4.0, "walks on ~2 s after the Shade died (%.1f)" % float(_v["moved"]))
	return true


func _brook() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.put(main.hero, MissionE4_02.BROOK_ICE)
		MissionHarness.immortal(main.hero)
		return false
	if not _v.has("slow"):
		if not main.hero.has_meta(&"on_ice"):
			return false
		_v["slow"] = true
		for t: Variant in main.totems:
			t.take_damage(1.0e7, null)
		return false
	if main.hero.has_meta(&"on_ice"):
		return false
	_ok(main.brook_thawed and main.objective_state("sec_brook") == "done", "brook thawed, sec_brook done")
	return true


func _lost() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		return false
	var folk := _units(0, "meadow_folk")
	if main.lost < 11 and not folk.is_empty():
		(folk[0] as Unit).take_damage(1.0e7, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and main.objective_state("obj_convoys") == "failed" and main.said.has("L31"), "11 lost = defeat")
	return true


func _win() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		for gid: StringName in main.groups:
			MissionHarness.kill(main.groups[gid])
		for f in _units(0, "meadow_folk"):
			MissionHarness.immortal(f)
		return false
	_clear_road()
	if main.next_convoy < 4 and main.on_road() == 0:
		main.auto_times[main.next_convoy] = 0.0
	if h.ended < 0:
		return false
	_ok(h.ended == 1 and main.arrived == 40, "victory, 40 through (%d)" % main.arrived)
	var flags := main.mission_flags()
	_ok(int(flags.get("e4m2_folk_arrived", -1)) == 40 and flags.has(CampaignState.YSOLDE_ESSENCE_FLAG), "flags (%s)" % str(flags))
	return true
