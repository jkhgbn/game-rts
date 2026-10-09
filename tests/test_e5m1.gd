extends SceneTree
## Mission e5m1 "The First Spark" (docs/design/mission-e5-01.md, scripted through MissionHarness; the real-fight timing
## run is tests/test_e5m1_sim.gd). Parts:
##   start   Vessa L1 (Fireball, cap 3), Old Vey 2 m east (not commandable), 3 Flame Guards, 4 Cinder Hands, 250
##           crystals, Valewatch 2 000 HP, 5 cold beacons, 3 farms, 2 tents, guards G1-G6, tier 1 only.
##   beacon  a beacon does not catch while its guard stands within 8 m; with G1 dead Vessa lights Hearthstone in ~3 s
##           (E3: obj 1 / 5, W1 armed at 4:00 at the earliest); The Lesson refunds 10 mana near Vey.
##   final   the 5 beacons lit = obj_hold + the Final with Gannet; Gannet below 40 % flees and ends the hold early;
##           victory (cinematics off) with the flags; the reward table writes flags only.
## Run: godot --headless --path . -s tests/test_e5m1.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e5m1"
const MISSION := "res://missions/mission_e5_01.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "beacon", "final"]
var _part := ""
var h: MissionHarness
var main: MissionE5_01
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m1_none.json"}}) as MissionE5_01
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"beacon":
			h.steps.add("a guarded beacon, then lit", _beacon, 3000)
		"final":
			h.steps.add("five beacons, the Final, Gannet flees, victory", _final, 6000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	var hero := main.hero
	_ok(hero.level == 1 and hero.level_cap == 3 and hero.spell_rank(&"fireball") >= 1, "Vessa L1, Fireball, cap 3")
	_ok(main.vey != null and not main.vey.is_commandable() and absf(MissionBase._flat(main.vey.global_position,
			hero.global_position) - 2.0) < 1.0, "Old Vey 2 m east, not commandable")
	_ok(_units(0, "flame_guard").size() == 3 and _units(0, "cinder_hand").size() == 4, "3 Flame Guards, 4 Cinder Hands")
	_ok(Economy.for_team(0).crystals == 250, "250 crystals (%d)" % Economy.for_team(0).crystals)
	_ok(main.keep != null and is_equal_approx(main.keep.max_hp, 2000.0), "Valewatch 2 000 HP")
	_ok(main.beacons.size() == 5 and main.lit.is_empty(), "5 cold beacons")
	_ok(main.farms.size() == 3 and main.tents.size() == 2, "3 farms, 2 tents")
	_ok(_units(1, "reiver").size() >= 14 and _units(2, "bristleback").size() == 2, "guards (%d reivers)" % _units(1, "reiver").size())
	_ok(main.tier_system != null and main.tier_system.max_tier == 1, "tier 1 only")
	_ok(main.objective_state("obj_beacons") == "active" and main.objective_state("obj_hold") == "", "objectives")
	for id: StringName in MissionE5_01.BEACONS:
		var p: Vector3 = MissionE5_01.BEACONS[id][1]
		_ok(MissionBase._flat((main.beacons[id] as Node3D).global_position, p) < 1.5, "beacon %s at its spot" % id)
	return true


func _beacon() -> bool:
	var hero := main.hero
	var br := main.beacons[&"hearthstone"] as MissionBrazier
	if not _v.has("t"):
		_v["t"] = main.mission_time()
		MissionHarness.immortal(hero)
		MissionHarness.put(hero, br.global_position + Vector3(1.5, 0.0, 0.0))
		hero.command_stop()
		return false
	if not _v.has("blocked"):
		if main.mission_time() - float(_v["t"]) < 5.0:
			if br.lit:
				_ok(false, "lit while G1 stands")
				return true
			return false
		_v["blocked"] = true
		for g: Variant in main.guard_groups[&"G1"]:
			if is_instance_valid(g):
				(g as Unit).take_damage(1.0e6, null)
		MissionHarness.put(hero, br.global_position + Vector3(1.5, 0.0, 0.0))
		hero.command_stop()
		_v["t2"] = main.mission_time()
		return false
	if not br.lit:
		if main.mission_time() - float(_v["t2"]) > 8.0:
			_ok(false, "Hearthstone never lit")
			return true
		return false
	if not _v.has("lit"):
		_v["lit"] = main.mission_time() - float(_v["t2"])
		_ok(float(_v["lit"]) < 4.5, "lit in ~3 s (%.1f)" % float(_v["lit"]))
		_ok(main.lit.size() == 1 and main.has_fired(&"E3") and main.said.has("L5"), "E3: 1 / 5, L5")
		_ok(main.objective_text(&"obj_beacons").contains("1 / 5"), "counter 1 / 5")
		# The Lesson: a Fireball near Vey costs 30.
		MissionHarness.put(main.vey, hero.global_position + Vector3(2.0, 0.0, 0.0))
		hero.mana = hero.get_stat(&"max_mana")
		_v["mana"] = hero.mana
		_v["cast"] = hero.command_cast(&"fireball", hero.global_position + Vector3(6, 0, 0))
		_v["cast_at"] = main.mission_time()
		return false
	if main.mission_time() - float(_v["cast_at"]) < 2.0 and float(_v["mana"]) - hero.mana < 1.0:
		return false
	if not _v.has("lesson"):
		_v["lesson"] = true
		var spent := float(_v["mana"]) - hero.mana
		_ok(String(_v["cast"]) != "" or absf(spent - 30.0) < 3.0, "Fireball costs 30 near Vey (%.1f, %s)" % [spent, _v["cast"]])
	return true


func _final() -> bool:
	var hero := main.hero
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(hero)
		for id: StringName in MissionE5_01.BEACON_ORDER:
			(main.beacons[id] as MissionBrazier).light()
		return false
	if not _v.has("hold"):
		if main.objective_state("obj_hold") != "active":
			return false
		_v["hold"] = true
		_ok(main.objective_state("obj_beacons") == "done", "obj_beacons done")
		_ok(main.said.has("L16") and main.said.has("L17") and main.has_fired(&"E7") and main.has_fired(&"E10"), "E7 / E10 / E13 lines")
		_ok(_units(0, "blaze_rider").size() == 2 and _units(0, "ember_archer").size() >= 2, "gift riders and archers")
		_ok(absf(main.hold_ends_at - 600.0) < 1.0, "an early 5th beacon holds until dusk, 10:00 (%.0f)" % main.hold_ends_at)
		MissionHarness.skip_time(main, 555.0 - main.mission_time())
		return false
	if not _v.has("final"):
		if main.gannet == null:
			return false
		_v["final"] = true
		_ok(main.mission_time() >= 549.0, "Gannet with the second group, 50 s before dusk (%.0f)" % main.mission_time())
		main.gannet.take_damage(main.gannet.max_hp * 0.65, hero)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	_ok(main.gannet_fled and main.said.has("L18") and main.said.has("L23"), "Gannet fled, L18, the watch lines")
	_ok(main.objective_state("obj_hold") == "done", "obj_hold done")
	var flags := main.mission_flags()
	_ok(flags.has("e5m1_time"), "e5m1_time (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e5m1.json")
	cs.reset()
	var items_before := JSON.stringify(cs.items)
	cs.on_mission_victory(&"e5m1", main)
	_ok(cs.flag("ep5_started") and cs.unlocked.has(&"e5m2") and JSON.stringify(cs.items) == items_before,
			"flags only, e5m2 unlocked")
	cs.reset()
	return true
