extends SceneTree
## Mission e4m3 "The Frozen Ashes" (docs/design/mission-e4-03.md, scripted through MissionHarness; the real-fight
## timing run is tests/test_e4m3_sim.gd). Parts:
##   start   Ysolde L5 + 4 points cap 8, 400 crystals, essence 150 + 600 (no save), Heartwood tier 2, Maelis called at
##           0:00, Torvald L6, Aldra, 5 frozen groves with 11 totems (TOTEM_HP), sturdier guards, the Glass Spire.
##   grow    Hollowfen: totem down -> thawed; plant 4 s; grows in 60 s alone, ~30 s with 4 soldiers; then it roots:
##           held 30 s (nobody in it = no progress) before it counts as grown.
##   rime    an enemy in a growing grove pauses it and re-rimes it after 10 s; a destroyed Grove Heart can be
##           replanted 30 s later.
##   win     five grown -> obj_hold 1:30 -> victory; flags (heartwood_seed_owned, Ysolde's essence).
## Run: godot --headless --path . -s tests/test_e4m3.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e4m3"
const MISSION := "res://missions/mission_e4_03.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "grow", "rime", "win"]
var _part := ""
var h: MissionHarness
var main: MissionE4_03
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
	h.timeout_frames = 40000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e4m3_none.json"}}) as MissionE4_03
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"grow":
			h.steps.add("Hollowfen grows alone in 60 s", _grow_alone, 9000)
			h.steps.add("Stagwatch grows in ~30 s with 4 soldiers", _grow_helped, 9000)
		"rime":
			h.steps.add("pause and re-rime", _rime, 6000)
			h.steps.add("replant 30 s after a heart falls", _replant, 9000)
		"win":
			h.steps.add("five groves + the hold = victory", _win, 30000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _thaw(id: StringName) -> void:
	for t: Variant in main.groves[id]["totems"]:
		if is_instance_valid(t):
			(t as Building).take_damage(1.0e7, null)
	MissionHarness.kill(main.groves[id]["guards"])


func _clear(at: Vector3, r: float) -> void:
	for n in main.get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == 1 and not main.is_dormant(u) and MissionBase._flat(u.global_position, at) <= r:
			u.take_damage(1.0e7, null)


func _start() -> bool:
	_ok(main.hero.level == 5 and main.hero.level_cap == 8 and main.hero.spell_points == 4, "Ysolde L5 + 4 points cap 8")
	_ok(Economy.for_team(0).crystals == 400 and EssenceBank.for_team(0).essence == 750, "400 / 750 (%d / %d)" % [
			Economy.for_team(0).crystals, EssenceBank.for_team(0).essence])
	_ok(main.keep.tier == 2, "Heartwood tier 2")
	_ok(main.maelis != null and main.maelis.is_alive(), "Maelis called at 0:00")
	_ok(main.torvald != null and main.torvald.level == 6, "Torvald L6")
	_ok(main.aldra != null and main.aldra.is_alive(), "Aldra")
	var totems := 0
	for id: StringName in main.groves:
		totems += (main.groves[id]["totems"] as Array).size()
		_ok(main.grove_state(id) == &"frozen", "%s frozen" % id)
	_ok(main.groves.size() == 5 and totems == 11, "5 groves, 11 totems (%d)" % totems)
	_ok(is_equal_approx((main.groves[&"stagwatch"]["totems"][0] as Building).max_hp, MissionE4_03.TOTEM_HP), "totem HP")
	var gd: Unit = main.groves[&"stagwatch"]["guards"][0]
	_ok(gd.max_hp > gd.unit_type.max_hp * (MissionE4_03.GUARD_HP_MULT - 0.05), "sturdier guards (%.0f / %.0f)" % [
			gd.max_hp, gd.unit_type.max_hp])
	_ok(main.glass_spire != null, "the Glass Spire")
	return true


func _grow_alone() -> bool:
	var id := &"hollowfen"
	var at: Vector3 = MissionE4_03.GROVES[id][1]
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		_thaw(id)
		return false
	if main.grove_state(id) == &"thawed" and not _v.has("planting"):
		_v["planting"] = true
		MissionHarness.put(main.hero, at)
		main.hero.command_stop()
		return false
	if main.grove_state(id) == &"growing" and not _v.has("g0"):
		_v["g0"] = main.mission_time()
		MissionHarness.put(main.hero, at + Vector3(14.0, 0.0, 0.0))
		for n in main.get_tree().get_nodes_in_group("units"):   # nobody in the ring: the 1x rate
			var u := n as Unit
			if u and int(u.team) == 0 and u != main.hero and MissionBase._flat(u.global_position, at) < 10.0:
				MissionHarness.put(u, at + Vector3(0.0, 0.0, 16.0))
		return false
	if main.grove_state(id) == &"rooting" and not _v.has("r0"):
		_v["r0"] = main.mission_time()
		var took := main.mission_time() - float(_v["g0"])
		_ok(absf(took - 60.0) <= 3.0, "60 s alone (%.1f)" % took)
		return false
	if not _v.has("r0"):
		return false
	if not _v.has("held") and main.mission_time() - float(_v["r0"]) > 5.0:
		_v["held"] = main.mission_time()
		_ok(main.grove_state(id) == &"rooting" and float(main.groves[id]["root"]) < 0.01, "no rooting while nobody holds it")
		MissionHarness.put(main.hero, at)
		main.hero.command_stop()
		return false
	if main.grove_state(id) != &"grown":
		return false
	var rooted := main.mission_time() - float(_v["held"])
	_ok(absf(rooted - MissionE4_03.ROOT_TIME) <= 3.0, "rooted after ~30 s held (%.1f)" % rooted)
	_ok(main.has_fired(&"E4") and main.objective_state("sec_unbroken") == "active", "E4, sec_unbroken")
	return true


func _grow_helped() -> bool:
	var id := &"stagwatch"
	var at: Vector3 = MissionE4_03.GROVES[id][1]
	if not _v.has("s"):
		_v["s"] = true
		_thaw(id)
		_clear(at, 14.0)
		MissionHarness.put(main.hero, at)
		main.hero.command_stop()
		return false
	_clear(at, 14.0)
	if main.grove_state(id) == &"growing" and not _v.has("s0"):
		_v["s0"] = main.mission_time()
		var th := _units(0, "thornling")
		for i in 4:
			MissionHarness.immortal(th[i])
			MissionHarness.put(th[i], at + Vector3(i * 0.9 - 1.5, 0.0, 1.0))
			(th[i] as Unit).command_stop()
		return false
	if main.grove_state(id) == &"rooting" and not _v.has("s1"):
		_v["s1"] = main.mission_time()
		var took := main.mission_time() - float(_v["s0"])
		_ok(absf(took - 30.0) <= 3.0, "~30 s with 4 soldiers (%.1f)" % took)
		return false
	if main.grove_state(id) != &"grown":
		return false
	_ok(_v.has("s1") and absf(main.mission_time() - float(_v["s1"]) - MissionE4_03.ROOT_TIME) <= 3.0,
			"the soldiers root it in ~30 s (%.1f)" % (main.mission_time() - float(_v.get("s1", 0.0))))
	return true


func _rime() -> bool:
	var id := &"hollowfen"
	var at: Vector3 = MissionE4_03.GROVES[id][1]
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		_thaw(id)
		MissionHarness.put(main.hero, at)
		main.hero.command_stop()
		return false
	if main.grove_state(id) == &"growing" and not _v.has("g"):
		_v["g"] = main.mission_time()
		MissionHarness.put(main.hero, at + Vector3(24.0, 0.0, 0.0))
		for n in main.get_tree().get_nodes_in_group("units"):   # nobody of ours comes to fight the Rimeshield
			var u := n as Unit
			if u and int(u.team) == 0 and u != main.hero and not u.is_worker():
				u.aggro_range = 0.0
				if MissionBase._flat(u.global_position, at) < 22.0:
					MissionHarness.put(u, at + Vector3(24.0, 0.0, 6.0))
		return false
	if not _v.has("g"):
		return false
	if not _v.has("shield") and main.mission_time() - float(_v["g"]) > 5.0:
		var rs := main.make_unit("rimeshield")
		main._spawn(rs, Unit.Team.ENEMY, at + Vector3(2.0, 0.0, 0.0))
		main.mark_scripted(rs)   # the Ice Commander leaves it alone
		rs.aggro_range = 0.0
		rs.attack_damage = 0.0
		MissionHarness.immortal(rs)
		_v["shield"] = main.mission_time()
		_v["meter"] = float(main.groves[id]["meter"])
		return false
	if not _v.has("shield"):
		return false
	if main.mission_time() - float(_v["shield"]) < 5.0:
		return false
	if not _v.has("paused_ok"):
		_v["paused_ok"] = true
		_ok(absf(float(main.groves[id]["meter"]) - float(_v["meter"])) < 0.02, "paused while the Rimeshield stands in it")
		return false
	if main.grove_state(id) != &"thawed":
		return false
	var took := main.mission_time() - float(_v["shield"])
	_ok(took >= 9.0 and took <= 12.0, "re-rimed after ~10 s (%.1f)" % took)
	_ok(main.has_fired(&"E7"), "E7")
	return true


func _replant() -> bool:
	var id := &"stagwatch"
	var at: Vector3 = MissionE4_03.GROVES[id][1]
	if not _v.has("r"):
		_v["r"] = true
		_thaw(id)
		_clear(at, 14.0)
		MissionHarness.put(main.hero, at)
		main.hero.command_stop()
		return false
	_clear(at, 14.0)
	if main.grove_state(id) == &"growing" and not _v.has("fast"):
		_v["fast"] = true
		main.groves[id]["meter"] = 0.99
		return false
	if main.grove_state(id) == &"grown" and not _v.has("killed"):
		_v["killed"] = main.mission_time()
		(main.groves[id]["heart"] as Building).take_damage(1.0e7, null)
		return false
	if not _v.has("killed"):
		return false
	if main.grove_state(id) == &"growing":
		var took := main.mission_time() - float(_v["killed"])
		_ok(took >= 30.0 and took <= 36.0, "replanted ~30 s after the heart fell (%.1f)" % took)
		_ok(main.objective_state("sec_unbroken") == "failed", "sec_unbroken failed")
		return true
	return false


func _win() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		for id: StringName in main.groves:
			_thaw(id)
		return false
	for id: StringName in main.groves:
		_clear(MissionE4_03.GROVES[id][1], 14.0)
		var g: Dictionary = main.groves[id]
		if g["state"] == &"thawed":
			g["state"] = &"growing"
			g["meter"] = 0.99
		elif g["state"] == &"rooting":
			main._grow(id)
		var hv: Variant = g["heart"]
		if hv != null and is_instance_valid(hv):
			(hv as Building).hp = (hv as Building).max_hp
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	_ok(main.objective_state("obj_groves") == "done" and main.objective_state("obj_hold") == "done", "groves + hold done")
	var flags := main.mission_flags()
	_ok(flags.has(CampaignState.YSOLDE_ESSENCE_FLAG), "Ysolde's essence (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e4m3.json")
	cs.reset()
	cs.on_mission_victory(&"e4m3", main)
	_ok(cs.flag("heartwood_seed_owned") and cs.unlocked.has(&"e4m4"), "the Heartwood Seed flag, e4m4 unlocked")
	cs.reset()
	return true
