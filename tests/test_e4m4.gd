extends SceneTree
## Mission e4m4 "Winter's End" (docs/design/mission-e4-04.md, scripted through MissionHarness; the real-fight timing run
## is tests/test_e4m4_sim.gd). Parts:
##   start   4 seats (Nature + Fire vs Ice + the Shadow tithe), Ysolde L6 + 5 points cap 8, 450 / 150 + 700, Maelis
##           called, Vessa, Torvald L7 behind the Heart Gate (truce), Aldra, the Wall (pieces, 3 gates, 4 spires), the
##           Winterheart frost-bound, 2 dormant Wallwardens, the Sleeping Elder's 2 totems.
##   wall    a Thornling does 35 % of its damage to a piece, an Elder Treant 100 %; a piece regrows while the
##           Winterheart stands and not after the thaw.
##   elder   both totems down + Ysolde 4 s at the shell = a free Elder Treant, sec_elder.
##   heart   the Winterheart takes no damage until both Wallwardens die (a gate under 50 % wakes its warden).
##   win     the Winterheart down = the thaw (gates open), obj_spire; Ysolde at the spire = victory; flags.
## Run: godot --headless --path . -s tests/test_e4m4.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e4m4"
const MISSION := "res://missions/mission_e4_04.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "wall", "elder", "heart", "win"]
var _part := ""
var h: MissionHarness
var main: MissionE4_04
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e4m4_none.json"}}) as MissionE4_04
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"wall":
			h.steps.add("wall factors and regrowth", _wall, 3000)
		"elder":
			h.steps.add("wake the Sleeping Elder", _elder, 2000)
		"heart":
			h.steps.add("frost-bound until both wardens fall", _heart, 2000)
		"win":
			h.steps.add("the thaw, the spire, victory", _win, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _piece() -> WinterWall:
	for v: Variant in main.wall:
		if not is_instance_valid(v):
			continue
		var w := v as WinterWall
		if w and w.is_alive() and not w.is_gate and absf(w.global_position.x + 10.0) < 6.0:
			return w
	return null


func _start() -> bool:
	_ok(Teams.multi and Teams.side_of(Unit.Team.ALLY) == 0 and Teams.side_of(Unit.Team.ENEMY) == 1, "seats / sides")
	_ok(main.hero.level == 6 and main.hero.level_cap == 8 and main.hero.spell_points == 5, "Ysolde L6 + 5 points cap 8")
	_ok(Economy.for_team(0).crystals == 450 and EssenceBank.for_team(0).essence == 850, "450 / 850 (%d / %d)" % [
			Economy.for_team(0).crystals, EssenceBank.for_team(0).essence])
	_ok(main.maelis != null and main.vessa != null and main.aldra != null, "Maelis, Vessa, Aldra")
	_ok(main.torvald != null and main.torvald.level == 7 and main.torvald.has_meta(Unit.TRUCE_META), "Torvald L7 on the parapet")
	var valid := main.wall.filter(func(v: Variant) -> bool: return is_instance_valid(v) and (v as Building).is_alive())
	print("    wall: %d pieces, %d alive; x %s" % [main.wall.size(), valid.size(), str(valid.map(func(v: Variant) -> int: return int((v as Node3D).global_position.x)))])
	_ok(main.gates.size() == 3 and main.wall.size() > 30 and main.wall_spires.size() == 4, "the Wall (%d pieces)" % main.wall.size())
	_ok(main.winterheart != null and main.winterheart.has_meta(Unit.TRUCE_META), "the Winterheart frost-bound")
	_ok(main.wallwardens.size() == 2 and main.is_dormant(main.wallwardens[&"west"]), "2 dormant Wallwardens")
	_ok(main.elder_totems.size() == 2, "the Elder's 2 totems")
	_ok(main.objective_state("obj_wall") == "active", "obj_wall")
	return true


func _wall() -> bool:
	var p := _piece()
	if p == null:
		h.check(false, "no wall piece")
		return true
	if not _v.has("t"):
		_v["t"] = true
		var th: Unit = _units(0, "thornling")[0]
		var before := p.hp
		p.take_damage(100.0, th)
		_ok(absf(before - p.hp - 35.0) < 0.5, "a Thornling does 35 %% (%.1f)" % (before - p.hp))
		main._grant_treant(Vector3(-10.0, 0.0, 0.0))
		var tr: Unit = main.treants[0]
		before = p.hp
		p.take_damage(100.0, tr)
		_ok(absf(before - p.hp - 100.0) < 0.5, "an Elder Treant does 100 %% (%.1f)" % (before - p.hp))
		_v["hp"] = p.hp
		_v["at"] = main.mission_time()
		return false
	if main.mission_time() - float(_v["at"]) < 14.0:
		return false
	if not _v.has("regrew"):
		_v["regrew"] = true
		_ok(p.hp > float(_v["hp"]) + 10.0, "the piece regrows while the Winterheart stands (%.0f -> %.0f)" % [float(_v["hp"]), p.hp])
		for id: StringName in main.wallwardens:
			main._wake_warden(id)   # a dormant warden cannot die (MissionBase.set_dormant)
			(main.wallwardens[id] as Unit).take_damage(1.0e7, null)
		return false
	if not _v.has("thaw"):
		if main.wardens_down < 2:
			return false
		_v["thaw"] = true
		main.winterheart.take_damage(1.0e7, null)
		p.take_damage(200.0, null)
		_v["hp2"] = p.hp
		_v["at2"] = main.mission_time()
		return false
	if main.mission_time() - float(_v["at2"]) < 14.0:
		return false
	_ok(main.thawed and absf(p.hp - float(_v["hp2"])) < 1.0, "no regrowth after the thaw (%.0f -> %.0f)" % [float(_v["hp2"]), p.hp])
	return true


func _elder() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		for t: Variant in main.elder_totems:
			(t as Building).take_damage(1.0e7, null)
		for n in main.get_tree().get_nodes_in_group("units"):
			var u := n as Unit
			if u and int(u.team) == 1 and MissionBase._flat(u.global_position, MissionE4_04.ELDER) < 16.0:
				u.take_damage(1.0e7, null)
		MissionHarness.put(main.hero, MissionE4_04.ELDER)
		main.hero.command_stop()
		return false
	if not main.elder_woken:
		return false
	_ok(main.treants.size() == 1 and main.objective_state("sec_elder") == "done" and main.said.has("L6"), "a free Treant, sec_elder, L6")
	return true


func _heart() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		var before := main.winterheart.hp
		_ok(main.winterheart.has_meta(Unit.TRUCE_META), "frost-bound (truce)")
		var g: WinterWall = main.gates[&"west"]
		g.take_spell_damage(g.max_hp * 0.55, null)
		_ok(not main.is_dormant(main.wallwardens[&"west"]), "the West Gate under 50 % wakes its warden")
		_ok(main.winterheart.hp == before, "no damage yet")
		for id: StringName in main.wallwardens:
			main._wake_warden(id)   # a dormant warden cannot die (MissionBase.set_dormant)
			(main.wallwardens[id] as Unit).take_damage(1.0e7, null)
		return false
	if main.wardens_down < 2:
		return false
	_ok(not main.winterheart.has_meta(Unit.TRUCE_META) and main.said.has("L21"), "open once both wardens fell (L21)")
	return true


func _win() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		for id: StringName in main.wallwardens:
			main._wake_warden(id)   # a dormant warden cannot die (MissionBase.set_dormant)
			(main.wallwardens[id] as Unit).take_damage(1.0e7, null)
		return false
	if not _v.has("heart"):
		if main.wardens_down < 2:
			return false
		_v["heart"] = true
		main.winterheart.take_damage(1.0e7, null)
		return false
	if not _v.has("spire"):
		if not main.thawed:
			return false
		_v["spire"] = true
		_ok(main.objective_state("obj_wall") == "done" and main.objective_state("obj_spire") == "active", "obj_wall -> obj_spire")
		var open := true
		for id: StringName in main.gates:
			if (main.gates[id] as Building).is_alive():
				open = false
		_ok(open, "the gates are open")
		MissionHarness.put(main.hero, MissionE4_04.GLASS_SPIRE + Vector3(0.0, 0.0, 6.0))
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	var flags := main.mission_flags()
	_ok(flags.has(CampaignState.YSOLDE_ESSENCE_FLAG), "Ysolde's essence (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e4m4.json")
	cs.reset()
	cs.on_mission_victory(&"e4m4", main)
	_ok(cs.flag("ep4_complete") and cs.flag("torvald_stayed_aldra"), "ep4_complete, torvald_stayed_aldra")
	cs.reset()
	return true
