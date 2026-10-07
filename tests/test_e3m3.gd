extends SceneTree
## Mission e3m3 "The Stone's Price" (docs/design/mission-e3-03.md, scripted through MissionHarness). Parts:
##   start   the Bishop's Seat at tier 3, Malrik L5 cap 7 with the Keystone Shard, 400 crystals, the start army, the
##           Great Crypt, 4 closed barrows, the Lodge watch.
##   barrows B1 / B2 open at 1:30 and spawn 2 Wardens per 30 s up to 8; a candle with a Warden at 7 m stays blocked and
##           relights in 4 s once it is gone; sealing crumbles a Warden near the door and stops its spawns.
##   stone   the offer enables J; each use +20 %; 5 uses = the stone speaks (Malrik held 5 s, then 60 %); an own Shade's
##           death adds 0.5 %; sec_refuse fails at the first use.
##   sexton  the 4th candle raises the Sexton; the Toll at 50 %; its fall with 4 candles = victory; the save flags.
## Run: godot --headless --path . -s tests/test_e3m3.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|...]

const TASK_ID := "e3m3"
const MISSION := "res://missions/mission_e3_03.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "barrows", "stone", "sexton"]
var _part := ""
var h: MissionHarness
var main: MissionE3_03
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e3m3_none.json"}}) as MissionE3_03
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"barrows":
			h.steps.add("B1 / B2 open at 1:30", _open, 600)
			h.steps.add("spawns to 8", _cap, 2400)
			h.steps.add("kill gate", _gate, 400)
			h.steps.add("blocked candle", _blocked, 400)
			h.steps.add("relight + seal", _relight, 600)
		"stone":
			h.steps.add("the offer", _offer, 900)
			h.steps.add("uses and the seizure", _uses, 900)
			h.steps.add("death feeds", _death_feeds, 600)
		"sexton":
			h.steps.add("4 candles -> the Sexton", _four, 300)
			h.steps.add("the Toll at 50 %", _toll, 300)
			h.steps.add("the fall -> victory", _fall, 3000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _hollow_alive() -> Array:
	return main.get_tree().get_nodes_in_group("hollow").filter(func(n: Node) -> bool:
		return (n as Unit).is_alive() and not (n as Node).has_meta(&"lodge"))


func _start() -> bool:
	_ok(main.keep != null and main.keep.tier == 3, "the Seat at tier 3")
	_ok(main.hero is ShadowWizard and main.hero.level == 5 and main.hero.level_cap == 7, "Malrik L5 cap 7")
	_ok(Economy.for_team(0).crystals == 400, "400 crystals (%d)" % Economy.for_team(0).crystals)
	_ok(EssenceBank.for_team(0).essence == 850, "150 + 700 essence, no save (%d)" % EssenceBank.for_team(0).essence)
	_ok(_units(0, "shade").size() == 6 and _units(0, "gloom_deacon").size() == 1 and _units(0, "gloom_thrall").size() == 6, "army")
	_ok(main.crypt != null and main.crypt.is_alive() and main.crypt.max_hp == 3000.0, "the Great Crypt 3 000")
	_ok(main.doors_open.is_empty() and main.candles_lit() == 0, "barrows closed, candles cold")
	_ok(main.get_tree().get_nodes_in_group("hollow").size() == 4, "the Lodge watch")
	_ok(not main.heart_enabled and main.use_heart() == MissionE3_03.REFUSE_NOT_YET, "no power before the offer")
	return true


func _open() -> bool:
	if main.mission_time() < 89.0:
		MissionHarness.skip_time(main, 89.0 - main.mission_time())
		return false
	if not main.doors_open.get(&"B1", false):
		return false
	_ok(main.doors_open.get(&"B2", false) and not main.doors_open.get(&"B3", false), "B1 + B2 open, B3 closed")
	return true


func _cap() -> bool:
	MissionHarness.immortal(main.crypt)
	var n := (main.door_units[&"B1"] as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive()).size()
	if n < 8:
		if not _v.has("last") or main.mission_time() - float(_v["last"]) > 1.0:
			_v["last"] = main.mission_time()
			MissionHarness.skip_time(main, 29.0)
		return false
	for u: Variant in main.door_units[&"B1"]:
		(u as Unit).set(&"aggro_range", 0.0)
		(u as Unit).command_stop()
	MissionHarness.skip_time(main, 60.0)
	_v["n8"] = true
	return true


## A clear candle of a barrow that has not given up its dead stays cold.
func _gate() -> bool:
	var candle: Vector3 = MissionE3_03.BARROWS[&"B2"][2]
	for u in _hollow_alive():
		MissionHarness.kill([u])
	main.door_kills[&"B2"] = 0
	MissionHarness.immortal(main.hero)
	MissionHarness.put(main.hero, candle)
	if not _v.has("g"):
		_v["g"] = main.mission_time()
		return false
	if main.mission_time() - float(_v["g"]) < 6.0:
		return false
	_ok(not main.candles[&"B2"], "B2's candle stays cold until its barrow is emptied")
	return true


func _blocked() -> bool:
	var candle: Vector3 = MissionE3_03.BARROWS[&"B1"][2]
	if not _v.has("b"):
		_v["b"] = true
		for u in _hollow_alive():
			MissionHarness.kill([u])
		var w := main.spawn_wave_at([["ruin_warden", 1]], candle + Vector3(7.0, 0.0, 0.0), Unit.Team.ENEMY)
		_v["w"] = w
		for u: Variant in w:
			main._hollow(u as Unit)
			(u as Unit).set(&"aggro_range", 0.0)
		MissionHarness.immortal(main.hero)
		MissionHarness.put(main.hero, candle)
		_v["t"] = main.mission_time()
		return false
	MissionHarness.put(main.hero, candle)
	(_v["w"][0] as Unit).global_position = candle + Vector3(7.0, 0.0, 0.0)
	if main.mission_time() - float(_v["t"]) < 5.0:
		return false
	_ok(not main.candles[&"B1"], "a Warden at 7 m blocks the candle")
	main.door_kills[&"B1"] = main.kills_needed(&"B1")   # the barrow emptied (the kill gate is checked in _gate below)
	MissionHarness.kill(_v["w"])
	_v["t2"] = main.mission_time()
	return true


func _relight() -> bool:
	var candle: Vector3 = MissionE3_03.BARROWS[&"B1"][2]
	MissionHarness.put(main.hero, candle)
	for u in _hollow_alive():
		if MissionBase._flat((u as Unit).global_position, candle) <= 9.0:
			MissionHarness.kill([u])
	if not _v.has("near"):
		var near := main.spawn_wave_at([["ruin_warden", 1]], (MissionE3_03.BARROWS[&"B1"][1] as Vector3) + Vector3(-6.0, 0.0, 0.0), Unit.Team.ENEMY)
		main._hollow(near[0] as Unit)
		(near[0] as Unit).set(&"aggro_range", 0.0)
		_v["near"] = near[0]
	(_v["near"] as Unit).global_position = (MissionE3_03.BARROWS[&"B1"][1] as Vector3) + Vector3(-6.0, 0.0, 0.0)
	if not main.candles[&"B1"]:
		return false
	var took := main.mission_time() - float(_v["t2"])
	_ok(took <= 6.0, "relit in ~4 s once clear (%.1f)" % took)
	_ok(not main.doors_open[&"B1"] and h.saw("obj_candles", "active"), "B1 sealed")
	_ok(not is_instance_valid(_v["near"]) or not (_v["near"] as Unit).is_inside_tree() or not (_v["near"] as Unit).is_alive(),
			"a Warden 6 m from the door crumbled")
	return true


func _offer() -> bool:
	if not main.heart_enabled:
		if not _v.has("w"):
			var w := main.spawn_wave_at([["ruin_warden", 1]], main.hero.global_position + Vector3(8.0, 0.0, 0.0), Unit.Team.ENEMY)
			main._hollow(w[0] as Unit)
			(w[0] as Unit).set(&"aggro_range", 0.0)
			_v["w"] = w
		return false
	_ok(main.objective_state("sec_refuse") == "active", "sec_refuse shown at the offer")
	return true


func _uses() -> bool:
	MissionHarness.immortal(main.hero)
	if main.seizures > 0:
		_ok(main.shard_uses == 5 and main.held_left > 0.0, "5 uses -> the stone speaks (uses %d)" % main.shard_uses)
		_ok(main.objective_state("sec_refuse") == "failed", "sec_refuse failed")
		_v["held_at"] = main.mission_time()
		return true
	var r := main.use_heart()
	if r == "":
		_ok(absf(main.stone_hold - 20.0 * main.shard_uses) < 0.01 or main.seizures > 0, "+20 %% per use (%.1f)" % main.stone_hold)
		if main.shard_uses == 1:
			_ok(main.use_heart() == MissionE3_03.REFUSE_RECHARGING, "Recharging")
	main.heart_left = 0.0
	return false


func _death_feeds() -> bool:
	if main.held_left > 0.0:
		_ok(main.use_heart() == MissionE3_03.REFUSE_HELD, "held: The stone holds you")
		return false
	if not _v.has("after"):
		_v["after"] = main.stone_hold
		_ok(absf(main.stone_hold - 60.0) < 0.01, "the meter at 60 %% after the seizure (%.1f)" % main.stone_hold)
		var s: Unit = _units(0, "shade")[0]
		s.take_damage(1.0e7, null)
		return false
	_ok(absf(main.stone_hold - float(_v["after"]) - 0.5) < 0.01, "an own Shade's death: +0.5 %% (%.1f)" % main.stone_hold)
	return true


func _four() -> bool:
	for id: StringName in MissionE3_03.BARROWS:
		main._open_door(id)
		main.relight(id)
	_ok(main.candles_lit() == 4 and main.sexton != null and main.sexton.is_alive(), "the Sexton rises at the 4th candle")
	_ok(main.objective_state("obj_candles") == "done" and main.objective_state("obj_sexton") == "active", "objectives")
	MissionHarness.immortal(main.crypt)
	return true


func _toll() -> bool:
	MissionHarness.immortal(main.hero)
	main.sexton.take_damage(main.sexton.hp - main.sexton.max_hp * 0.49 + 1.0, null)
	if main.sexton_phase < 2:
		return false
	_ok(main.has_fired(&"E14") and main.sexton.has_status(&"dazed"), "the Toll + the stagger")
	return true


func _fall() -> bool:
	if main.sexton and is_instance_valid(main.sexton) and main.sexton.is_alive():
		main.sexton.take_damage(1.0e7, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	var f := main.mission_flags()
	_ok(f.has("e3m3_shard_uses") and f.has("e3m3_seizures") and f.has(CampaignState.MALRIK_ESSENCE_FLAG), "flags %s" % str(f))
	_ok(int(main.mission_flag_adds().get("shadow_stone_uses", -1)) == 0, "the track counter (0 uses)")
	_ok(main.objective_state("sec_refuse") == "done" or main.objective_state("sec_refuse") == "", "sec_refuse")
	return true
