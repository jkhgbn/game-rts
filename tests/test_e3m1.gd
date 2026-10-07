extends SceneTree
## Mission e3m1 "Take the Ford" (docs/design/mission-e3-01.md, scripted through MissionHarness; the real-fight timing
## run is tests/test_e3m1_sim.gd). Parts:
##   start   4 seats on 2 sides (Shadow + Ice vs Nature + Fire), the river with 3 fords (ford slow on), Malrik L3 cap 6
##           with the Keystone Shard, Hush, 300 / 400 / the start army, the guards G1-G6, 2 Horn Spires, 3 standards.
##   ford    the ford zone: side 0 only, fixed 60 s, contested = frozen, W3 at 70 %, obj_ford done -> obj_foot.
##   foot    a standard taken by side 0 -> W4 (E9); Ysolde's Standard topples (E10); all 3 -> obj_hold + the Final.
##   hold    the hold pauses while a standard is lost and never resets; 2:00 -> victory; rewards (flags only, Malrik's
##           essence flag; Vessa's track untouched).
##   misc    Heartbeat mana; horns -> sec_horns; Vessa's death after E5 -> sec_vessa; Malrik's death = defeat.
## Run: godot --headless --path . -s tests/test_e3m1.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e3m1"
const MISSION := "res://missions/mission_e3_01.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "ford", "foot", "hold", "misc", "death"]
var _part := ""
var h: MissionHarness
var main: MissionE3_01
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e3m1.json"}}) as MissionE3_01
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"ford":
			h.steps.add("contested ford frozen", _ford_contested, 300)
			h.steps.add("ford 60 s, W3 at 70 %", _ford_capture, 6000)
		"foot":
			h.steps.add("first standard -> W4", _first_standard, 2400)
			h.steps.add("all three -> hold", _all_standards, 6000)
		"hold":
			h.steps.add("hold pauses", _hold_pause, 4000)
			h.steps.add("hold done -> victory", _hold_victory, 12000)
		"misc":
			h.steps.add("heartbeat", _heartbeat, 120)
			h.steps.add("horns", _horns, 300)
			h.steps.add("Vessa driven", _vessa, 600)
		"death":
			h.steps.add("Malrik dies -> defeat", _death, 600)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _clear(at: Vector3, r: float) -> void:
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.is_hostile(int(u.team), 0) and not u is Wizard \
				and MissionBase._flat(u.global_position, at) <= r:
			u.take_damage(1.0e7, null)


## Puts `n` side-0 soldiers at `at` (the start Shades), Malrik stays home.
func _station(at: Vector3, n: int) -> void:
	var i := 0
	for u in _units(0, "shade") + _units(0, "nightbolt") + _units(0, "grave_hound"):
		if i >= n:
			break
		MissionHarness.immortal(u)
		MissionHarness.put(u, at + Vector3(i * 0.8 - 1.0, 0.0, 0.0))
		u.set(&"aggro_range", 0.0)
		i += 1


func _start() -> bool:
	_ok(Teams.multi and Teams.seats().size() == 4, "4 seats")
	_ok(Teams.side_of(Unit.Team.ALLY) == 0 and Teams.side_of(Unit.Team.ENEMY_2) == 1, "sides")
	_ok(main.kingdom_of(0) == &"shadow" and main.kingdom_of(Unit.Team.ALLY) == &"ice" and main.kingdom_of(1) == &"nature" \
			and main.kingdom_of(Unit.Team.ENEMY_2) == &"fire", "kingdoms")
	_ok(main.hero is ShadowWizard and main.hero.level == 3 and main.hero.level_cap == 6, "Malrik L3 cap 6")
	_ok(main.hero.spell_rank(&"shadow_lance") == 2 and main.hero.spell_rank(&"soul_siphon") == 1, "Malrik spells")
	var inv: Variant = ItemDrops.inventory_of(main.hero)
	var arts: Array = inv.get(&"artifacts") if inv != null else []
	_ok(not arts.is_empty() and arts[0] != null and String((arts[0] as ItemType).id if arts[0] is ItemType else arts[0].get("type").id) == "keystone_shard",
			"the Keystone Shard in slot 1 (%s)" % str(arts))
	_ok(main.hush != null and main.hush.is_alive(), "Hush")
	_ok(main.torvald != null and main.ysolde != null and main.vessa != null, "Torvald, Ysolde, Vessa")
	_ok(Economy.for_team(0).crystals == 300 and EssenceBank.for_team(0).essence == 400, "300 / 400 (%d / %d)" % [
			Economy.for_team(0).crystals, EssenceBank.for_team(0).essence])
	_ok(_units(0, "gloom_thrall").size() == 5 and _units(0, "shade").size() == 4, "5 Thralls, 4 Shades")
	var river := RiverSystem.instance(main.get_tree())
	_ok(river != null and river.is_ford(MissionE3_01.FORD_STONE) and river.is_water(Vector3(-18.0, 0.0, 4.0))
			and not river.is_water(Vector3(-18.0, 0.0, 14.0)), "river + Stone Ford")
	_ok(main.horns.size() == 2 and main.standards.size() == 3 and main.ford_zone != null, "2 horns, 3 standards, ford zone")
	_ok(main.guard_groups.size() == 6 and (main.guard_groups[&"G1"] as Array).size() == 8, "guards (G1 %d)" % (main.guard_groups[&"G1"] as Array).size())
	_ok(main.standards_owned(1) == 3, "standards start Nature / Fire")
	_ok(main.objective_state("obj_ford") == "active" and main.objective_state("obj_malrik") == "active", "objectives")
	return true


func _ford_contested() -> bool:
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		_station(MissionE3_01.FORD_ZONE, 2)   # G1 stands in the zone: contested
		return false
	if main.mission_time() - float(_v["t"]) < 4.0:
		return false
	_ok(main.ford_zone.contested and main.ford_zone.progress == 0.0, "the ford frozen while G1 stands in it")
	return true


func _ford_capture() -> bool:
	if not _v.has("cleared"):
		_v["cleared"] = main.mission_time()
		MissionHarness.kill(main.guard_groups[&"G1"])
		return false
	_clear(MissionE3_01.FORD_ZONE, 9.0)
	if h.frame % 600 == 0:
		print("    ford progress %.2f counts %s contested %s" % [main.ford_zone.progress, str(main.ford_zone.counts), main.ford_zone.contested])
	if main.ford_zone.progress >= 0.71 and not _v.has("half"):
		_v["half"] = main.mission_time() - float(_v["cleared"])
		_ok(main.waves_fired.has(&"W3"), "W3 at 70 %")
	if not main.ford_zone.locked:
		return false
	var took := main.mission_time() - float(_v["cleared"])
	_ok(absf(took - 62.0) <= 5.0, "the ford in ~60 s (%.1f)" % took)
	_ok(h.saw("obj_ford", "done") and main.objective_state("obj_foot") == "active", "obj_ford done -> obj_foot")
	return true


func _take(id: StringName) -> void:
	main.ford_zone.set_owner_side(0)
	var z := main.standards[id] as MissionZone
	if not _v.has("st_" + String(id)):
		_v["st_" + String(id)] = true
		_station(z.global_position, 3)
	_clear(z.global_position, 10.0)
	if h.frame % 600 == 0:
		print("    %s owner %d progress %.2f (side %d) counts %s" % [id, z.owner_side, z.progress, z.capture_side, str(z.counts)])


func _first_standard() -> bool:
	if main.objective_state("obj_foot") != "active":
		main.ford_zone.set_owner_side(0)
		main._on_ford_captured(main.ford_zone, 0)
		return false
	_take(&"std_well")
	if (main.standards[&"std_well"] as MissionZone).owner_side != 0:
		return false
	_ok(main.waves_fired.has(&"W4"), "W4 at the first standard")
	_ok(main.has_fired(&"E9"), "E9")
	return true


func _all_standards() -> bool:
	# The capture rule itself is checked on the first standard; the other two are handed over (the bots' waves
	# and respawning wizards would contest a test that only stands 3 Shades there).
	for id: StringName in [&"std_ysolde", &"std_clover", &"std_well"]:
		var z := main.standards[id] as MissionZone
		if z.owner_side != 0:
			z.set_owner_side(0)
			main._on_standard_captured(z, 0)
	_ok(main.standard_toppled and main.has_fired(&"E10"), "Ysolde's Standard toppled")
	_ok(main.objective_state("obj_hold") == "active" and main.waves_fired.has(&"FINAL"), "obj_hold + the Final")
	_ok(absf(main.hold_left - 120.0) < 2.0, "2:00 hold (%.1f)" % main.hold_left)
	return true


func _setup_hold() -> bool:
	if main.objective_state("obj_hold") == "active":
		return true
	main.ford_zone.set_owner_side(0)
	main._on_ford_captured(main.ford_zone, 0)
	for id: StringName in main.standards:
		(main.standards[id] as MissionZone).set_owner_side(0)
	main._foot_taken()
	MissionHarness.immortal(main.hero)
	return false


func _hold_pause() -> bool:
	if not _setup_hold():
		return false
	if not _v.has("lost"):
		_v["lost"] = main.hold_left
		(main.standards[&"std_clover"] as MissionZone).set_owner_side(-1)
		return false
	if not main.hold_paused:
		return false
	var before := main.hold_left
	MissionHarness.skip_time(main, 0.0)
	_ok(before >= float(_v["lost"]) - 1.0, "the countdown kept (%.1f)" % before)
	(main.standards[&"std_clover"] as MissionZone).set_owner_side(0)
	return true


func _hold_victory() -> bool:
	for id: StringName in main.standards:
		var z := main.standards[id] as MissionZone
		if z.owner_side != 0:
			z.set_owner_side(0)
		_clear(z.global_position, 12.0)
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	var flags := main.mission_flags()
	_ok(int(flags.get(CampaignState.MALRIK_ESSENCE_FLAG, -1)) >= 0 and bool(flags.get("e3m1_standard_toppled", false))
			and flags.has("e3m1_time"), "Malrik's essence flag + computed flags (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e3m1.json")
	cs.reset()
	cs.items = {"artifacts_owned": ["ember_crown"], "essence": 77}
	cs.on_mission_victory(&"e3m1", main)
	_ok(cs.items.get("essence", 0) == 77 and cs.is_completed(&"e3m1") and cs.unlocked.has(&"e3m2"),
			"flags-only victory: Vessa's items untouched, e3m2 unlocked")
	_ok(cs.flag_value(CampaignState.MALRIK_ESSENCE_FLAG, null) != null and cs.flag("ep3_started"), "saved flags")
	cs.reset()
	return true


func _heartbeat() -> bool:
	if not _v.has("m"):
		main.hero.mana = 0.0
		_v["m"] = true
		var foes := _units(Unit.Team.ENEMY, "thornling")
		var near := main.hero.global_position + Vector3(3.0, 0.0, 0.0)
		for i in 2:
			var u: Unit = foes[i]
			MissionHarness.put(u, near)
			u.take_damage(1.0e7, null)
		var far: Unit = foes[3]
		MissionHarness.put(far, main.hero.global_position + Vector3(12.0, 0.0, 0.0))
		far.take_damage(1.0e7, null)
		return false
	_ok(main.heartbeats == 1, "heartbeat: 1 gain (2 deaths in one 0.5 s gate, 1 at 12 m: %d)" % main.heartbeats)
	return true


func _horns() -> bool:
	if not _v.has("h"):
		_v["h"] = true
		for id: StringName in main.horns:
			(main.horns[id] as Building).take_damage(1.0e7, null)
		return false
	_ok(main.horns_down == 2 and main.objective_state("sec_horns") == "done", "sec_horns done")
	return true


func _vessa() -> bool:
	if not main.has_fired(&"E5"):
		main._fire_wave(&"W2")
		return false
	if not _v.has("v"):
		_v["v"] = true
		main.vessa.take_damage(1.0e7, null)
		return false
	_ok(main.vessa_driven and main.objective_state("sec_vessa") == "done", "sec_vessa done")
	return true


func _death() -> bool:
	if not _v.has("d"):
		_v["d"] = true
		h.protect_hero = false
		main.hero.take_damage(1.0e7, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and main.objective_state("obj_malrik") == "failed", "Malrik's death = defeat")
	return true
