extends SceneTree
## Mission e4m1 "Hold Lark Hill" (docs/design/mission-e4-01.md, scripted through MissionHarness; the real-fight timing
## run is tests/test_e4m1_sim.gd). Parts:
##   start     4 seats on 2 sides (Nature + Fire vs Shadow + Ice), the river, Ysolde L3 cap 6, 300 / 400, Maelis, Wren,
##             Hush, the golden tree (3 000 HP), 2 horns, 3 standards owned by side 0, the ford zone, 5 bells.
##   bell      a bell rung at 0:10 brings its 6 villagers into the refuge (counted saved).
##   burn      Reedfield burns at 8:00 when unrung: 6 lost; a farm cannot be rung before its picket dies.
##   ford      the ford zone completes for side 1 in 60 s (never for side 0) -> sec_ford failed, L15b.
##   folk      the 11th villager lost = defeat.
##   night     nightfall with 20+ saved = victory; flags (Ysolde's essence, folk saved; Vessa's items untouched).
##   death     Ysolde's death = defeat.
## Run: godot --headless --path . -s tests/test_e4m1.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e4m1"
const MISSION := "res://missions/mission_e4_01.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "bell", "burn", "ford", "folk", "night", "death"]
var _part := ""
var h: MissionHarness
var main: MissionE4_01
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e4m1.json"}}) as MissionE4_01
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"bell":
			h.steps.add("a bell brings 6 villagers to the refuge", _bell, 3000)
		"burn":
			h.steps.add("Reedfield burns at 8:00", _burn, 600)
		"ford":
			h.steps.add("the ford falls to side 1 in 60 s", _ford, 6000)
		"folk":
			h.steps.add("11 lost = defeat", _folk_lost, 900)
		"night":
			h.steps.add("nightfall with 20 saved = victory", _night, 6000)
		"death":
			h.steps.add("Ysolde dies -> defeat", _death, 600)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	_ok(Teams.multi and Teams.seats().size() == 4, "4 seats")
	_ok(Teams.side_of(Unit.Team.ALLY) == 0 and Teams.side_of(Unit.Team.ENEMY_2) == 1, "sides")
	_ok(main.kingdom_of(0) == &"nature" and main.kingdom_of(Unit.Team.ALLY) == &"fire" and main.kingdom_of(1) == &"shadow" \
			and main.kingdom_of(Unit.Team.ENEMY_2) == &"ice", "kingdoms")
	_ok(main.hero.level == 3 and main.hero.level_cap == 6, "Ysolde L3 cap 6 (L%d cap %d)" % [main.hero.level, main.hero.level_cap])
	_ok(main.hero.spell_rank(&"thornburst") == 2 and main.hero.spell_rank(&"wild_bloom") == 1, "Ysolde's spells")
	_ok(Economy.for_team(0).crystals == 300 and EssenceBank.for_team(0).essence == 400, "300 / 400 (%d / %d)" % [
			Economy.for_team(0).crystals, EssenceBank.for_team(0).essence])
	_ok(_units(0, "sprigling").size() == 6 and _units(0, "thornling").size() == 11, "6 Spriglings, 11 Thornlings (%d)" % \
			_units(0, "thornling").size())
	_ok(main.maelis != null and main.maelis.is_alive() and main.wren != null, "Maelis, Wren")
	_ok(main.hush != null and main.malrik != null and main.torvald != null and main.vessa != null, "Hush, Malrik, Torvald, Vessa")
	_ok(main.tree != null and absf(main.tree.max_hp - 3000.0) < 1.0, "the golden tree 3 000 HP")
	_ok(main.horns.size() == 2 and main.standards.size() == 3 and main.standards_owned(0) == 3, "2 horns, 3 standards (side 0)")
	_ok(main.ford_zone != null and main.ford_zone.sides_allowed == [1], "ford zone for side 1")
	_ok(main.bells.size() == 5 and main.folk.is_empty(), "5 bells, nobody out yet")
	for id: String in ["obj_folk", "obj_tree", "obj_nightfall", "obj_ysolde", "sec_ford", "sec_horns"]:
		_ok(main.objective_state(id) == "active", "%s active" % id)
	_ok(absf(main.nightfall_at() - 1320.0) < 0.1, "nightfall at 22:00")
	return true


func _bell() -> bool:
	if not _v.has("rung"):
		if main.mission_time() < 10.0:
			return false
		_v["rung"] = main.mission_time()
		MissionHarness.immortal(main.hero)
		MissionHarness.put(main.hero, MissionE4_01.BELLS[&"larkford"][1] + Vector3(1.0, 0.0, 0.0))
		return false
	if main.folk.is_empty():
		return false
	if main.folk_saved < 6:
		return false
	_ok(main.folk.size() == 6 and bool(main.bells[&"larkford"]["roused"]), "Larkford roused, 6 villagers")
	_ok(main.has_fired(&"E2") and main.said.has("L6"), "E2 / L6")
	print("    6 saved after %.1f s" % (main.mission_time() - float(_v["rung"])))
	return true


func _burn() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		MissionHarness.put(main.hero, MissionE4_01.BELLS[&"reedfield"][1])
		return false
	if not _v.has("locked"):
		if main.mission_time() < 3.0:
			return false
		_v["locked"] = true
		_ok(not bool(main.bells[&"reedfield"]["roused"]), "Reedfield locked while its picket lives")
		MissionHarness.put(main.hero, MissionE4_01.YSOLDE_START)
		MissionHarness.skip_time(main, 480.0 - main.mission_time())
		return false
	if not bool(main.bells[&"reedfield"]["burned"]):
		return false
	_ok(main.folk_lost == 6 and main.said.has("L14"), "Reedfield burned: 6 lost, L14 (%d)" % main.folk_lost)
	return true


func _ford() -> bool:
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		MissionHarness.kill(_units(0, "thornling").filter(func(u: Unit) -> bool:
				return MissionBase._flat(u.global_position, MissionE4_01.FORD_ZONE) < 14.0))
		MissionHarness.kill(_units(0, "burr_slinger") + _units(Unit.Team.ALLY, "flame_guard"))
		var shades := _units(1, "shade")
		for i in mini(3, shades.size()):
			MissionHarness.immortal(shades[i])
			MissionHarness.put(shades[i], MissionE4_01.FORD_ZONE + Vector3(i * 0.8, 0.0, 0.0))
			shades[i].set(&"aggro_range", 0.0)
			shades[i].set_meta(MissionBase.SCRIPTED_GROUP, true)
			shades[i].add_to_group(MissionBase.SCRIPTED_GROUP)
		return false
	if not main.ford_zone.locked:
		return false
	var took := main.mission_time() - float(_v["t"])
	_ok(main.ford_zone.owner_side == 1, "side 1 owns the ford")
	_ok(absf(took - 61.0) <= 5.0, "the ford in ~60 s (%.1f)" % took)
	_ok(main.objective_state("sec_ford") == "failed" and main.said.has("L15b"), "sec_ford failed, L15b")
	return true


func _folk_lost() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		h.protect_hero = true
		for id: StringName in [&"larkford", &"millbrook"]:
			main.rouse(id)
		return false
	var alive: Array = main.folk.filter(func(f: Variant) -> bool: return is_instance_valid(f) and (f as Unit).is_alive())
	if main.folk_lost < 11 and not alive.is_empty():
		(alive[0] as Unit).take_damage(1.0e7, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and main.objective_state("obj_folk") == "failed" and main.said.has("L37"), "11 lost = defeat")
	return true


func _night() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		MissionHarness.immortal(main.tree)
		for id: StringName in main.bells:
			main.rouse(id)
		for f: Variant in main.folk:
			MissionHarness.immortal(f)
			MissionHarness.put(f as Unit, MissionE4_01.GOLDEN_TREE + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
		return false
	if not _v.has("skip"):
		if main.folk_saved < 25:
			return false
		_v["skip"] = true
		MissionHarness.skip_time(main, main.nightfall_at() - main.mission_time() + 0.5)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	_ok(main.objective_state("obj_nightfall") == "done" and main.objective_state("obj_folk") == "done", "objectives done")
	var flags := main.mission_flags()
	_ok(int(flags.get("e4m1_folk_saved", -1)) == 30 and int(flags.get(CampaignState.YSOLDE_ESSENCE_FLAG, -1)) >= 0
			and flags.has("e4m1_time"), "computed flags (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e4m1.json")
	cs.reset()
	cs.items = {"artifacts_owned": ["ember_crown"], "essence": 77}
	cs.on_mission_victory(&"e4m1", main)
	_ok(cs.items.get("essence", 0) == 77 and cs.is_completed(&"e4m1") and cs.unlocked.has(&"e4m2"),
			"flags-only victory: Vessa's items untouched, e4m2 unlocked")
	_ok(cs.flag("maelis_story_met") and int(cs.flag_value("e4m1_folk_saved", 0)) == 30, "saved flags")
	cs.reset()
	return true


func _death() -> bool:
	if not _v.has("d"):
		_v["d"] = true
		h.protect_hero = false
		main.hero.take_damage(1.0e7, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and main.objective_state("obj_ysolde") == "failed", "Ysolde's death = defeat")
	return true
