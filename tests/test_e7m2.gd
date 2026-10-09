extends SceneTree
## Mission e7m2 "First Blood, and No Further" (docs/design/mission-e7-02.md, scripted through MissionHarness; the
## real-fight run is tests/test_e7m2_sim.gd). Parts:
##   start      Torvald L5 (cap 8), the Stronghold, the Bazaar, Seraphine, Vessa L6, 2 barricades, the Citadel closed.
##   clues      both barricades down -> obj_rock / obj_truth; a clue refuses with an enemy within 8 m, completes in 4 s
##              once clear, leaving 3 m resets it ("check 2").
##   duel       truth known + the afternoon bell: Dacian on the sand, the duel stops below 75 % (won), the ambush; Hush
##              flees at 25 %, every knife dead = victory (cinematics off), flags only, next c_e7_mask.
##   dacian     Dacian dies in the ambush = defeat.
## Run: godot --headless --path . -s tests/test_e7m2.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e7m2"
const MISSION := "res://missions/mission_e7_02.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "clues", "duel", "dacian"]
var _part := ""
var h: MissionHarness
var main: MissionE7_02
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e7m2_none.json"}}) as MissionE7_02
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"clues":
			h.steps.add("barricades, clue channels", _clues, 3000)
		"duel":
			h.steps.add("the duel, the ambush, victory", _duel, 12000)
		"dacian":
			h.steps.add("Dacian dies = defeat", _dacian, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	var m := main
	_ok(m.hero.level == 5 and m.hero.level_cap == 8 and m.hero.spell_points == 4, "Torvald L5, cap 8, 4 points")
	_ok(m.keep != null and m.keep.tier == 2, "the Stronghold")
	_ok(Market.of_team(0) != null, "the Bazaar")
	_ok(m.seraphine != null and m.seraphine.is_alive(), "Seraphine")
	_ok(m.vessa != null and m.vessa.level == 6, "Vessa L6")
	_ok(m.barricades_left() == 2, "two barricades")
	_ok(m.tier_system.max_tier == 2, "the Citadel closed before 5:45")
	_ok(_units(0, "rimeshield").size() == 6 and _units(0, "frost_mortar").size() == 1, "6 Rimeshields, 1 Mortar")
	_ok(Economy.for_team(0).crystals == 400, "400 crystals")
	_ok(m.no_save_fallback and EssenceBank.for_team(0).essence >= 650, "no save: 150 + 500 essence (%d)" % EssenceBank.for_team(0).essence)
	return true


func _clues() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		for b: Variant in m.barricades:
			(b as Building).take_damage(1.0e6, null)
		return false
	if not _v.has("b"):
		if m.objective_state("obj_truth") != "active":
			return false
		_v["b"] = true
		_ok(m.objective_state("obj_barricade") == "done" and m.objective_state("obj_rock") == "active", "barricades down")
		# the ledger clue: with its guard alive, refused
		MissionHarness.put(m.hero, MissionE7_02.CLUES[&"ledger"])
		_v["t"] = m.mission_time()
		return false
	if not _v.has("c"):
		if m.mission_time() - float(_v["t"]) < 6.0:
			return false
		_v["c"] = true
		_ok(not m.clues_found.has(&"ledger"), "refused with an enemy within 8 m")
		for n in m.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and int(u.team) == Unit.Team.ENEMY and MissionBase._flat(u.global_position, MissionE7_02.CLUES[&"ledger"]) < 14.0:
				u.take_damage(1.0e6, null)
		MissionHarness.put(m.hero, MissionE7_02.CLUES[&"ledger"])
		_v["t"] = m.mission_time()
		return false
	if not _v.has("d"):
		if m.mission_time() - float(_v["t"]) < 2.0:
			return false
		_v["d"] = true
		MissionHarness.put(m.hero, MissionE7_02.CLUES[&"ledger"] + Vector3(6.0, 0.0, 0.0))
		_v["t"] = m.mission_time()
		return false
	if not _v.has("e"):
		if m.mission_time() - float(_v["t"]) < 1.0:
			return false
		_v["e"] = true
		_ok(float(m.clue_progress.get(&"ledger", 0.0)) == 0.0, "leaving 3 m resets")
		MissionHarness.put(m.hero, MissionE7_02.CLUES[&"ledger"])
		_v["t"] = m.mission_time()
		return false
	if m.mission_time() - float(_v["t"]) < 5.0:
		return false
	_ok(m.clues_found.has(&"ledger") and m.said.has("L11"), "the ledger in 4 s")
	return true


func _clear_isle() -> void:
	for n in main.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.ENEMY and not u is Wizard and MissionBase._flat(u.global_position, Vector3.ZERO) < 30.0:
			u.take_damage(1.0e6, null)


func _duel() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		for b: Variant in m.barricades:
			(b as Building).take_damage(1.0e6, null)
		for c: StringName in [&"knives", &"ledger", &"herald"]:
			m._clue_found(c)
		_ok(m.objective_state("obj_duel") == "active", "obj_duel after 3 clues")
		_clear_isle()
		MissionHarness.skip_time(m, m.duel_floor() + 1.0 - m.mission_time())
		return false
	if not _v.has("b"):
		if not m.dacian_arrived:
			return false
		_v["b"] = true
		_ok(m.mission_time() >= m.duel_floor(), "Dacian not before the afternoon bell")
		m.hero.death_guard = Callable()
		MissionHarness.put(m.hero, MissionE7_02.DUEL_T)
		MissionHarness.put(m.dacian, MissionE7_02.DUEL_D)
		return false
	if not _v.has("c"):
		if m.duel_state != "on":
			return false
		_v["c"] = true
		m.dacian.take_damage(m.dacian.max_hp * 0.3, m.hero)
		return false
	if not _v.has("d"):
		if not m.has_fired(&"ambush"):
			return false
		_v["d"] = true
		_ok(m.duel_state == "won" and m.objective_state("sec_duel") == "done", "first blood to Torvald")
		_ok(m.dacian.hp >= m.dacian.max_hp * 0.69, "no further damage after the stop")
		MissionHarness.immortal(m.dacian)
		MissionHarness.immortal(m.hero)
		m.hush.take_damage(m.hush.max_hp * 0.8, m.hero)
		return false
	if not _v.has("e"):
		if not m.hush_gone:
			return false
		_v["e"] = true
		_ok(m.hush.is_alive(), "Hush never dies")
		MissionHarness.skip_time(m, 31.0)
		return false
	if not _v.has("f"):
		_v["f"] = (int(_v.get("f_n", 0)) > 0)
		_v["f_n"] = int(_v.get("f_n", 0)) + 1
		if int(_v["f_n"]) < 120:
			_v.erase("f")
			return false
		_v["f"] = true
		return false
	if h.ended < 0:
		for v: Variant in m.knives:
			if is_instance_valid(v) and (v as Unit).is_alive():
				(v as Unit).take_damage(1.0e6, null)
		return false
	_ok(h.ended == 1, "victory")
	_ok(m.said.has("L27"), "L27")
	var cs := CampaignState.open("user://test_e7m2.json")
	cs.reset()
	cs.on_mission_victory(&"e7m2", m)
	_ok(cs.flag("helper_aldra_unlocked") and cs.flag("e7_truth_known") and cs.flag("e7m2_duel_won"), "flags")
	_ok(StringName(m.mission_rewards().get("next", &"")) == &"c_e7_mask", "next: c_e7_mask")
	cs.reset()
	return true


func _dacian() -> bool:
	var m := main
	if not _v.has("a"):
		_v["a"] = true
		MissionHarness.immortal(m.hero)
		m.fire_once(&"E12")
		m.fire_once(&"E13")
		m.dacian = m.make_unit("dacian_story")
		m._spawn(m.dacian, Unit.Team.PLAYER, Vector3(3.0, 0.0, -3.0))
		m._ambush()
		return false
	if h.ended < 0:
		if m.dacian and is_instance_valid(m.dacian) and m.dacian.is_alive():
			m.dacian.take_damage(1.0e6, null)
		return false
	_ok(h.ended == 0 and m.said.has("L29"), "Dacian's death = defeat")
	return true
