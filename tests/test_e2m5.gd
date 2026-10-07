extends SceneTree
## Mission e2m5 "The Light Below" (docs/design/mission-e2-05.md, acceptance checks 2-8 scripted through MissionHarness;
## the real-fight timing run is tests/test_e2m5_sim.gd). Parts:
##   start   4 seats (Fire Citadel, Nature / Shadow / Ice Strongholds), the Rift (bridges + dais open), the Door
##           untargetable, 4 grey seals, the Warden host (6), the statue asleep, Old Vey, Ysolde, Malrik / Torvald L6.
##   seals   Vessa kindles a seal in 4 s; an enemy within 6 m pauses it; 30 damage resets it; Malrik cracks it back in
##           4 s; the Wake meter rate = 0.10 + 0.10 x amber - 0.05 x white-gold (min 0.05).
##   wake    no wake before 9:00 even at 100 %; at the wake: +500 Door HP per white-gold seal, the host turns ENEMY, B1.
##   boss    B1 Door Slam hurts the Door; B2 with Malrik within 20 m: x 0.5 damage + heal, his death breaks it; B3 the
##           Sunlance needs Vessa at the Door with Vey within 8 m: 300 + Exposed.
##   door    the Hold heals 1 000 once at the first 50 % dip (sec_door failed); Door HP 0 = defeat.
##   roost   refusals (8:00, Stables, crystals); the Roost trains a Cinder Dragon -> sec_dragon done.
##   end     the Doorwarden falls -> victory, rewards e2m5 (fire_titans_unlocked, next ep2_ending).
## Run: godot --headless --path . -s tests/test_e2m5.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e2m5"
const MISSION := "res://missions/mission_e2_05.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "seals", "wake", "boss", "door", "roost", "end"]
var _part := ""
var h: MissionHarness
var main: MissionE2_05
var _errors: Array[String] = []
var _v := {}
var _t0 := 0
var _gap := 0
var _finished := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_parts = [a.trim_prefix("--only=")]
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
	h.timeout_frames = 40000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m5_none.json"}}) as MissionE2_05
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"seals":
			h.steps.add("kindle in 4 s", _kindle, 600)
			h.steps.add("pause + reset", _pause_reset, 900)
			h.steps.add("Malrik cracks it", _crack, 900)
		"wake":
			h.steps.add("no wake before 9:00", _no_early_wake, 120)
			h.steps.add("the wake", _wake, 300)
		"boss":
			h.steps.add("B1 Door Slam", _slam, 900)
			h.steps.add("B2 tether", _tether, 600)
			h.steps.add("B3 Sunlance", _lance, 600)
		"door":
			h.steps.add("the Hold", _hold, 300)
			h.steps.add("Door 0 = defeat", _breach, 600)
		"roost":
			h.steps.add("Roost refusals", _roost_refusals, 30)
			h.steps.add("Roost + Dragon", _roost, 14000)
		"end":
			h.steps.add("the fall -> victory", _fall, 3000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _clear(at: Vector3, r: float) -> void:
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) != 0 and int(u.team) != Unit.Team.ALLY and u != main.boss and u != main.shadow_hero \
				and MissionBase._flat(u.global_position, at) <= r:
			u.take_damage(1.0e7, null)


func _start() -> bool:
	_ok(Teams.multi and Teams.seats().size() == 4, "4 seats")
	_ok(main.keep != null and main.keep.tier == 3, "Fire Citadel (%d)" % (main.keep.tier if main.keep else -1))
	_ok(main.keep_of(Unit.Team.ALLY) != null and main.keep_of(Unit.Team.ENEMY) != null and main.keep_of(Unit.Team.ENEMY_2) != null,
			"3 bot keeps")
	_ok(main.is_rift(Vector3(-30, 0, 0)) and not main.is_rift(Vector3(-45, 0, 0)) and not main.is_rift(Vector3(0, 0, 0)), "rift / bridge / dais")
	_ok(main.door != null and main.door.has_meta(Unit.TRUCE_META), "the Door untargetable before the wake")
	_ok(main.seal_count(&"grey") == 4, "4 grey seals")
	_ok(main.host.size() == 6 and main.is_dormant(main.boss), "host 6, statue asleep")
	_ok(main.vey != null and main.ysolde != null and main.torvald != null, "Vey, Ysolde, Torvald")
	_ok(main.shadow_hero.level == 6 and main.torvald.level == 6, "Malrik / Torvald L6")
	_ok(h.saw("obj_seals", "active") and h.saw("obj_keep", "active"), "objectives")
	return true


func _kindle() -> bool:
	var s: Vector3 = MissionE2_05.SEALS[&"S"]
	if not _v.has("k"):
		_v["k"] = true
		_clear(s, 14.0)
		MissionHarness.put(main.hero, s + Vector3(1.5, 0, 0))
		_t0 = h.frame
		return false
	if main.seals[&"S"] != &"gold":
		return false
	var secs := float(h.frame - _t0) / 60.0
	_ok(secs >= 3.8 and secs <= 5.0, "kindled in ~4 s (%.1f)" % secs)
	_ok(absf(main.wake_rate() - 0.05) < 0.001, "rate with 1 gold = 0.05 (%.3f)" % main.wake_rate())
	return true


func _pause_reset() -> bool:
	var w: Vector3 = MissionE2_05.SEALS[&"W"]
	if not _v.has("p"):
		_v["p"] = true
		_clear(w, 14.0)
		MissionHarness.put(main.hero, w + Vector3(0, 0, 1.5))
		var shade := main._spawn(main.make_unit("shade"), Unit.Team.ENEMY, w + Vector3(0, 0, -5))
		MissionHarness.immortal(shade)
		shade.aggro_range = 0.0
		shade.attack_damage = 0.0
		_v["s"] = shade
		_t0 = h.frame
		return false
	if h.frame - _t0 == 300:
		var row: Array = main.seal_progress.get(&"W", [0, 0.0, null])
		_ok(float(row[1]) < 0.05, "paused with a Shade at 5 m (%.2f)" % float(row[1]))
		(_v["s"] as Unit).death_guard = Callable()
		(_v["s"] as Unit).take_damage(1.0e7, null)
		return false
	if h.frame - _t0 == 420:
		var row: Array = main.seal_progress.get(&"W", [0, 0.0, null])
		_ok(float(row[1]) > 0.2, "runs again (%.2f)" % float(row[1]))
		main.hero.take_damage(31.0, null)
		row = main.seal_progress.get(&"W", [0, 0.0, null])
		_ok(float(row[1]) < 0.05, "30 damage resets it")
		return false
	return main.seals[&"W"] == &"gold"


func _crack() -> bool:
	var s: Vector3 = MissionE2_05.SEALS[&"S"]
	if not _v.has("c"):
		_v["c"] = true
		MissionHarness.put(main.hero, Vector3(-40, 0, 40))
		MissionHarness.put(main.vey, Vector3(-38, 0, 40))
		main.vey.set(&"stance", &"home")
		_clear(s, 14.0)
		MissionHarness.immortal(main.shadow_hero)
		MissionHarness.put(main.shadow_hero, s + Vector3(0, 0, -1.5))
		main.shadow_hero.aggro_range = 0.0
		_t0 = h.frame
		return false
	if main.seals[&"S"] == &"amber":
		var secs := float(h.frame - _t0) / 60.0
		_ok(secs <= 5.5, "cracked in ~4 s (%.1f)" % secs)
		_ok(absf(main.wake_rate() - 0.15) < 0.001, "rate 1 amber 1 gold = 0.15 (%.3f)" % main.wake_rate())
		_ok(main.said.has(6), "E3: L6")
		return true
	if h.frame % 30 == 0:
		_clear(s, 10.0)
		MissionHarness.put(main.shadow_hero, s + Vector3(0, 0, -1.5))
	if h.frame % 240 == 0:
		print("  crack: S %s progress %s malrik %s blockers %d" % [main.seals[&"S"], str(main.seal_progress.get(&"S", [])),
				main.shadow_hero.global_position, main._side_units_near(s, MissionE2_05.SEAL_BLOCK, 0)])
	return false


func _no_early_wake() -> bool:
	main.wake = 100.0
	if h.frame < 60:
		return false
	_ok(not main.woke, "no wake before 9:00 at 100 %")
	return true


func _wake() -> bool:
	if not _v.has("w"):
		_v["w"] = true
		main.seals[&"S"] = &"gold"
		main.seals[&"W"] = &"gold"
		MissionHarness.skip_time(main, MissionE2_05.WAKE_FLOOR + 1.0)
		return false
	if not main.woke:
		return false
	_ok(absf(main.door.max_hp - 7000.0) < 1.0, "Door 6 000 + 2 x 500 (%.0f)" % main.door.max_hp)
	_ok(not main.door.has_meta(Unit.TRUCE_META) or main.door.get_meta(Unit.TRUCE_META) != Unit.TRUCE_ALL, "the Door targetable")
	var neutral := main.host.filter(func(u: Variant) -> bool: return is_instance_valid(u) and int((u as Unit).team) == Unit.Team.NEUTRAL)
	_ok(neutral.is_empty() and not main.host.is_empty(), "the host is ENEMY")
	_ok(main.boss_phase == 1 and not main.is_dormant(main.boss) and int(main.boss.team) == Unit.Team.ENEMY, "B1")
	_ok(h.saw("obj_door", "active") and h.saw("obj_doorwarden", "active") and h.saw("sec_seals", "failed"), "objectives at E14")
	return true


func _boss_ready() -> void:
	main.wake_up()
	MissionHarness.immortal(main.hero)
	main.boss.global_position = MissionE2_05.DOOR_RIM_N
	main.boss.command_stop()


func _slam() -> bool:
	if not _v.has("b"):
		_v["b"] = true
		_boss_ready()
		_v["hp"] = main.door.hp
		return false
	if main.door.hp <= float(_v["hp"]) - 100.0:
		_ok(true, "slam")
		return true
	return false


func _tether() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		_boss_ready()
		main.boss.hp = main.boss.max_hp * 0.69
		MissionHarness.immortal(main.shadow_hero)
		MissionHarness.put(main.shadow_hero, MissionE2_05.MALRIK_TETHER_SPOT)
		_t0 = h.frame
		return false
	if h.frame - _t0 < 30:
		return false
	if not _v.has("d"):
		_v["d"] = true
		_ok(main.boss_phase == 2 and main.tether_on, "B2 tether on")
		var hp := main.boss.hp
		main.boss.take_damage(1000.0, null)
		var lost := hp - main.boss.hp
		_ok(lost > 300.0 and lost < 700.0, "x 0.5 with armor (%.0f lost of 1000)" % lost)
		main.shadow_hero.death_guard = Callable()
		main.shadow_hero.take_damage(1.0e7, null)
		_t0 = h.frame
		return false
	if h.frame - _t0 < 30:
		return false
	_ok(not main.tether_on, "Malrik's death breaks it")
	return true


func _lance() -> bool:
	if not _v.has("l"):
		_v["l"] = true
		_boss_ready()
		main.boss.hp = main.boss.max_hp * 0.34
		MissionHarness.put(main.hero, MissionE2_05.SOUTH_RIM)
		MissionHarness.immortal(main.vey)
		MissionHarness.put(main.vey, MissionE2_05.SOUTH_RIM + Vector3(2, 0, 2))
		return false
	if main.vey.global_position.distance_to(main.hero.global_position) > 6.0:
		MissionHarness.put(main.vey, main.hero.global_position + Vector3(2, 0, 2))
	if main.lances >= 1:
		_ok(main.boss_phase == 3 and main.exposed_left > 0.0, "B3: a Sunlance, Exposed")
		_ok(main.said.has(30), "E19: L30")
		return true
	return false


func _hold() -> bool:
	if not _v.has("h"):
		_v["h"] = true
		main.wake_up()
		main.door.hp = main.door.max_hp * 0.51
		main.door.take_damage(main.door.max_hp * 0.02, null)
		return false
	_ok(main.door_held and main.said.has(24), "the Hold (L24)")
	_ok(main.door.hp > main.door.max_hp * 0.6, "+1 000 (%.0f)" % main.door.hp)
	_ok(h.saw("sec_door", "failed"), "sec_door failed at the first dip")
	return true


func _breach() -> bool:
	if not _v.has("x"):
		_v["x"] = true
		main.door.take_damage(1.0e7, null)
		return false
	if h.ended == 0:
		_ok(h.saw("obj_door", "failed"), "obj_door failed")
		return true
	return false


func _roost_refusals() -> bool:
	_ok(main.raise_roost() == "Available at 8:00", "8:00 gate")
	MissionHarness.skip_time(main, MissionE2_05.ROOST_AT + 1.0)
	_v["r"] = true
	return true


func _roost() -> bool:
	if h.frame % 60 == 0:
		_clear(Vector3(-50, 0, 45), 35.0)   # the raids (W1, Hush) stay off the Roost site
	if not _v.has("s"):
		if main.mission_time() < MissionE2_05.ROOST_AT:
			return false
		_v["s"] = true
		_ok(main.raise_roost() == "Needs Ember Stables", "Stables first")
		main.build_grid.spawn_complete(BuildingType.find("fire_stables"), Vector3(-60, 0, 34), 0)
		Economy.for_team(0).add(5000)
		var r := main.raise_roost()
		_ok(r == "", "the Roost placed (%s)" % r)
		return false
	if main.roost == null or not main.roost.is_constructed():
		if h.frame % 600 == 0:
			print("  roost %s progress %.2f" % [main.roost != null, main.roost.construction_progress() if main.roost else -1.0])
		return false
	if not _v.has("q"):
		_v["q"] = true
		var t: UnitType = (main.roost as TrainingBuilding).trainable_types()[0]
		_ok(t.id == &"cinder_dragon" and t.cost == 700 and t.pop == 6, "Roost Z = Cinder Dragon 700 / 6")
		var why := (main.roost as TrainingBuilding).queue_unit(t)
		_ok(why == "", "queued (%s)" % why)
		return false
	if h.frame % 600 == 0:
		print("  roost queue %d progress %.2f" % [(main.roost as TrainingBuilding).queue.size(), (main.roost as TrainingBuilding).train_progress()])
	if main.dragons >= 1:
		_ok(h.saw("sec_dragon", "done") and main.said.has(13), "sec_dragon done, L13")
		_ok(h.saw_spotlight("cinder_dragon"), "the Cinder Dragon spotlight")
		return true
	return false


func _fall() -> bool:
	if not _v.has("f"):
		_v["f"] = true
		main.wake_up()
		return false
	if not _v.has("k"):
		_v["k"] = true
		main.boss.take_damage(1.0e8, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	var r: Dictionary = CampaignState.reward_of(&"e2m5")
	_ok(r.get("next") == &"ep2_ending" and (r.get("set_flags", {}) as Dictionary).get("fire_titans_unlocked") == true,
			"rewards %s" % str(r))
	return true
