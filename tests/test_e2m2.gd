extends SceneTree
## Mission e2m2 "Roots and Embers" (docs/design/mission-e2-02.md, acceptance checks 1-8 scripted through MissionHarness;
## the real-fight timing run is tests/test_e2m2_sim.gd). Parts:
##   start   4 seats (Teams: PLAYER + ALLY side 0, ENEMY + ENEMY_2 side 1), hostility by side (ally never an enemy,
##           ENEMY_2 an enemy), fog shared by side, ALLY scripted with no building and not out; Fire Stronghold + army,
##           Ysolde L4 + Maelis + Wren + 6 carriers + 6 wardens, Rimehold (hall + 3 spires), 8 capture points,
##           objectives, Torvald / Malrik L5.
##   plant   E2 at 0:20: Ysolde plants Grove A; a Shade at 7 m pauses it, the progress is kept; done -> E3, the grove
##           (ALLY building, 900 HP), 2 carriers spent (not lost); Sprouts after 60 s (2 Thornlings), Seedbed.
##   ping    send_ysolde(B) = an AllyChannel defend ping answered at once, the column heads for B; retreat -> nearest
##           planted grove; L7 once.
##   e14     the 3 groves -> E14: Heartwood (nature keep) at A2 + Grove Hall + 2 Seed Hollows + 5 Spriglings, the ALLY
##           Commander, obj_ally active; Rimehold destroyed -> E15 + obj_rimehold; the Vice (2:30) with both wizards;
##           a destroyed grove pauses it; victory, withdraw, rewards e2m2 (next e2m3, ep2_nature_allied).
##   keep    the Fire keep destroyed = defeat (L32).
##   ally    the ALLY seat out after E14 = defeat (L33).
## Run: godot --headless --path . -s tests/test_e2m2.gd --fixed-fps 60 --quit-after 60000 [-- --only=start|plant|...]

const TASK_ID := "e2m2"
const MISSION := "res://missions/mission_e2_02.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "plant", "ping", "e14", "keep", "ally"]
var _part := ""
var h: MissionHarness
var main: MissionE2_02
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m2_none.json"}}) as MissionE2_02
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
		"plant":
			h.steps.add("E2: Ysolde walks to Grove A", _plant_starts, 4000)
			h.steps.add("a Shade pauses it", _plant_pause, 1200)
			h.steps.add("Grove A planted", _plant_done, 4000)
			h.steps.add("Sprouts and Seedbed", _sprouts, 1200)
		"ping":
			h.steps.add("ping Grove B", _ping, 400)
			h.steps.add("retreat ping", _retreat, 400)
		"e14":
			h.steps.add("3 groves: E14", _e14, 600)
			h.steps.add("Rimehold falls, the Vice starts", _rimehold, 1200)
			h.steps.add("a grove falls: the Vice pauses", _vice_pause, 600)
			h.steps.add("the Vice ends: victory", _victory, 4000)
		"keep":
			h.steps.add("Fire keep destroyed = defeat", _keep_loss, 600)
		"ally":
			h.steps.add("ALLY seat out = defeat", _ally_loss, 900)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


# ---------------------------------------------------------------- start

func _start() -> bool:
	_ok(Teams.multi and Teams.seats() == [0, 1, 3, 4], "4 seats %s" % str(Teams.seats()))
	_ok(Teams.side_of(3) == 0 and Teams.side_of(4) == 1 and Teams.is_hostile(0, 4) and not Teams.is_hostile(0, 3),
			"sides: ALLY with PLAYER, ENEMY_2 against")
	var fg: Unit = _units(0, "flame_guard")[0]
	_ok(not fg.is_enemy_of(main.ysolde) and fg.is_enemy_of(main.torvald) and fg.is_ally_of(main.ysolde),
			"hostility by side (Ysolde ally, Torvald enemy)")
	_ok(Economy.for_team(3) != null and Economy.for_team(4) != null, "one Economy per seat")
	_ok(Building.for_team(3).is_empty() and not main.seat_out(3), "ALLY: no building, not out")
	_ok(main.keep.tier == 2 and main.keep_of(4) != null and main.keep_of(4).tier == 2, "Fire / Ice keeps: Stronghold")
	var army := _units(0, "flame_guard").size() + _units(0, "ember_archer").size() + _units(0, "blaze_rider").size() \
			+ _units(0, "pyre_adept").size() + _units(0, "kilnwarden").size()
	_ok(army == 15, "15 start soldiers (%d)" % army)
	_ok(main.workers_of(0).size() == 6, "6 Cinder Hands")
	_ok(main.ysolde.level == 4 and int(main.ysolde.team) == 3, "Ysolde L4 on ALLY")
	_ok(main.maelis != null and main.maelis.level == 4, "Maelis follows Ysolde's level")
	_ok(main.wren != null and not main.wren.is_commandable(), "Wren: not commandable")
	_ok(main.carriers.size() == 6 and not (main.carriers[0] as Unit).is_commandable(), "6 carriers, not commandable")
	_ok(main.column.size() == 6, "6 wardens in the column (%d)" % main.column.size())
	_ok(main.rimehold.size() == 4 and main.rimehold_hall.is_locked(), "Rimehold: hall (locked) + 3 spires")
	_ok(main.torvald.level == 5 and main.shadow_hero.level == 5, "Torvald / Malrik L5")
	_ok(main.points_held() == 0 and main.capture_points != null, "capture points built")
	_ok(h.saw("obj_groves", "active") and h.saw("obj_rimehold", "active") and h.saw("obj_keep", "active"),
			"objectives %s" % str(h.objective_log))
	_ok(main.fog.state_at(0, main.ysolde.global_position) == FogOfWar.VISIBLE, "Ysolde's ground is visible to Fire (side fog)")
	_ok(Skirmish.enemy_team_of(4) == 0 and Skirmish.enemy_team_of(3) == 1, "lane opponents")
	return true


# ---------------------------------------------------------------- planting

func _plant_starts() -> bool:
	var s: GroveSite = main.sites[&"A"]
	if s.progress > 0.05:
		_ok(main.has_fired(&"E2") and main.said.has(4), "E2 / L4")
		return true
	return false


func _plant_pause() -> bool:
	var s: GroveSite = main.sites[&"A"]
	if not _v.has("shade"):
		var shade := main._spawn(main.make_unit("shade"), Unit.Team.ENEMY, s.global_position + Vector3(7.0, 0.0, 0.0))
		MissionHarness.immortal(shade)
		shade.aggro_range = 0.0
		_v["shade"] = shade
		_v["p"] = s.progress
		_t0 = h.frame
		return false
	if h.frame - _t0 < 180:
		MissionHarness.put(_v["shade"], s.global_position + Vector3(7.0, 0.0, 0.0))
	if h.frame - _t0 == 180:
		_ok(s.paused and absf(s.progress - float(_v["p"])) < 0.03, "paused with a Shade at 7 m (%.2f -> %.2f)" % [_v["p"], s.progress])
		var sh: Unit = _v["shade"]
		sh.death_guard = Callable()
		MissionHarness.kill([sh])
		_v["p2"] = s.progress
		return false
	if h.frame - _t0 >= 300:
		_ok(s.progress > float(_v["p2"]), "resumes (not reset) once the Shade dies")
		return true
	return false


func _plant_done() -> bool:
	var s: GroveSite = main.sites[&"A"]
	if s.is_planted():
		_ok(int(s.grove.team) == 3 and absf(s.grove.max_hp - 900.0) < 1.0, "Grove A: ALLY, 900 HP")
		_ok(main.carriers.size() == 4 and main.carriers_lost == 0, "2 carriers spent, none lost")
		_ok(main.has_fired(&"E3") and main.said.has(6), "E3 / L6")
		_ok(main.groves_standing() == 1, "1 / 3")
		_v["t"] = main.mission_time()
		return true
	return false


func _sprouts() -> bool:
	var s: GroveSite = main.sites[&"A"]
	if not _v.has("skip"):
		_v["skip"] = true
		s.sprout_left = 0.1
		s.seed_left = 0.1
		_v["c"] = main.carriers.size()
		return false
	if s.sprouts.size() == 2:
		_ok(int((s.sprouts[0] as Unit).team) == 3, "2 Thornlings for ALLY")
		_ok(main.carriers.size() == int(_v["c"]) + 1 or main.carriers.size() == int(_v["c"]), "Seedbed: +1 carrier (max 2 waiting)")
		return true
	return false


# ---------------------------------------------------------------- pings

func _ping() -> bool:
	if not _v.has("sent"):
		_v["sent"] = true
		_ok(main.send_ysolde(&"B") == "", "the ping is accepted")
		_t0 = h.frame
		return false
	if main.column_target == &"B":
		_ok(h.frame - _t0 <= 120, "answered within 2 s")
		_ok(main.dialogue_log.any(func(l: String) -> bool: return l.contains("Right behind you.")), "the answer line")
		return true
	return false


func _retreat() -> bool:
	if not _v.has("r"):
		_v["r"] = true
		main._plant(&"A", [])
		AllyChannel.instance(main.get_tree()).ping(&"retreat", main.ysolde.global_position, 0)
		return false
	_ok(main.column_target == &"A", "retreat: the nearest planted grove (%s)" % main.column_target)
	return true


# ---------------------------------------------------------------- E14, Rimehold, the Vice

func _e14() -> bool:
	if not _v.has("p"):
		_v["p"] = true
		for id: StringName in [&"A", &"B", &"C"]:
			main._plant(id, [])
		return false
	if not main.ally_active:
		return false
	_ok(main.has_fired(&"E14") and h.saw("obj_groves", "done") and h.saw("obj_ally", "active"), "E14: groves done, obj_ally")
	_ok(main.heartwood != null and main.heartwood.building_type.id == &"nature_keep", "the Heartwood (nature keep)")
	var b := Building.for_team(3)
	var kinds := {}
	for x in b:
		kinds[String(x.building_type.id)] = int(kinds.get(String(x.building_type.id), 0)) + 1
	_ok(int(kinds.get("nature_barracks", 0)) == 1 and int(kinds.get("nature_hollow", 0)) == 2, "Grove Hall + 2 Seed Hollows %s" % str(kinds))
	_ok(_units(3, "sprigling").size() == 5, "5 Spriglings")
	_ok(main.ally_commander != null, "the ALLY Commander")
	_ok(main.said.has(18) and main.said.has(20), "L18-L20")
	return true


func _rimehold() -> bool:
	if not _v.has("k"):
		_v["k"] = true
		for b in main.rimehold:
			b.take_damage(1.0e7, null)
		return false
	if main.vice_left > 0.0:
		_ok(h.saw("obj_rimehold", "done") and main.said.has(21), "E15: L21")
		_ok(absf(main.vice_left - 150.0) < 1.0, "the Vice: 2:30 (%.0f)" % main.vice_left)
		_ok(main.waves_fired.has(&"VS") and main.waves_fired.has(&"VI"), "both Vice groups")
		_ok(main.shadow_hero.level == 6 and main.torvald.level == 6, "Malrik / Torvald L6")
		var vi: Array = main.wave_units[&"VI"]
		_ok(vi.filter(func(u: Variant) -> bool: return (u as Unit).unit_type and (u as Unit).unit_type.id == &"rime_colossus").is_empty(),
				"no Colossus after Rimehold")
		return true
	return false


func _vice_pause() -> bool:
	if not _v.has("g"):
		_v["g"] = true
		(main.sites[&"B"] as GroveSite).grove.take_damage(1.0e7, null)
		_t0 = h.frame
		return false
	if h.frame - _t0 == 180:
		_ok(main.vice_paused, "paused: replant")
		var l := main.vice_left
		_v["l"] = l
		main._plant(&"B", [])
		return false
	if h.frame - _t0 > 240:
		_ok(not main.vice_paused, "runs again with 3 groves")
		return true
	return false


func _victory() -> bool:
	if not _v.has("end"):
		_v["end"] = true
		main.vice_left = 0.5
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory (ended %d)" % h.ended)
	_ok(main.said.has(28) and main.said.has(29) and main.said.has(30), "L28-L30")
	var r: Dictionary = CampaignState.reward_of(&"e2m2")
	_ok(r.get("next") == &"e2m3" and (r.get("set_flags", {}) as Dictionary).get("ep2_nature_allied") == true, "rewards %s" % str(r))
	_ok(CampaignState.MISSION_SCENES.has(&"e2m2") and CampaignState.MISSION_ORDER.has(&"e2m2"), "registered")
	return true


# ---------------------------------------------------------------- defeats

func _keep_loss() -> bool:
	if not _v.has("k"):
		_v["k"] = true
		main.keep.take_damage(1.0e7, null)
		return false
	if h.ended == 0:
		_ok(main.said.has(32) and h.saw("obj_keep", "failed"), "E23: L32")
		return true
	return false


func _ally_loss() -> bool:
	if not _v.has("p"):
		_v["p"] = true
		for id: StringName in [&"A", &"B", &"C"]:
			main._plant(id, [])
		return false
	if main.ally_active and not _v.has("k"):
		_v["k"] = true
		for b in Building.for_team(3):
			b.take_damage(1.0e7, null)
		return false
	if h.ended == 0:
		_ok(main.said.has(33) and h.saw("obj_ally", "failed"), "E24: L33")
		return true
	return false
