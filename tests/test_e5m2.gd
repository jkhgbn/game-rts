extends SceneTree
## Mission e5m2 "Burn a Door" (docs/design/mission-e5-02.md, scripted through MissionHarness; the real-fight timing run
## is tests/test_e5m2_sim.gd). Parts:
##   start   Vessa L2 (Fireball, Ember Step, cap 4), Sergeant Ashby (commandable), 4 Flame Guards + 4 Ember Archers,
##           5 Cinder Hands, 300 / 150, the field camp + Ember Hall, the closed palisade ring with the Rook Gate and the
##           Postern, 2 towers, the Nest, 2 tents, Gannet in the fort, 3 hidden bands.
##   spring  Vessa alone into the Near Reeds springs B1 (its Reivers on the r 6 ring around her, sec_patience failed).
##   spot    soldiers first into the Heron Pools spot B2 (counter 1 / 3).
##   wood    a Flame Guard hit on a palisade block x1, Vessa's x2; a burned block = obj_door (E11) and the sally (S1).
##   win     the Nest below 50 % = the Final (L17); the Nest burned = victory (cinematics off) and the flags.
## Run: godot --headless --path . -s tests/test_e5m2.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e5m2"
const MISSION := "res://missions/mission_e5_02.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "spring", "spot", "wood", "win"]
var _part := ""
var h: MissionHarness
var main: MissionE5_02
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e5m2_none.json"}}) as MissionE5_02
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"spring":
			h.steps.add("Vessa alone springs B1", _spring, 600)
		"spot":
			h.steps.add("soldiers first spot B2", _spot, 600)
		"wood":
			h.steps.add("wood x2, a door, the sally", _wood, 1200)
		"win":
			h.steps.add("the Final, the Nest, victory", _win, 3000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _soldiers() -> Array:
	return main.units_of(0, true).filter(func(u: Unit) -> bool: return u != main.ashby)


func _start() -> bool:
	var hero := main.hero
	_ok(hero.level == 2 and hero.level_cap == 4 and hero.spell_rank(&"ember_step") >= 1, "Vessa L2, Ember Step, cap 4")
	_ok(main.ashby != null and main.ashby.is_commandable(), "Sergeant Ashby, commandable")
	_ok(_units(0, "flame_guard").size() == 4 and _units(0, "ember_archer").size() == 4, "4 Flame Guards + 4 Ember Archers")
	_ok(_units(0, "cinder_hand").size() == 5, "5 Cinder Hands")
	_ok(Economy.for_team(0).crystals == 300 and EssenceBank.for_team(0).essence == 150, "300 / 150")
	_ok(main.rook_gate != null and main.postern != null and main.palisade.size() == 22, "the ring (%d blocks + 2 gates)" % main.palisade.size())
	_ok(is_equal_approx(main.rook_gate.max_hp, 2400.0) and is_equal_approx(main.nest.max_hp, 3200.0), "gate 2 400 / Nest 3 200 HP")
	_ok(main.towers.size() == 2 and main.tents.size() == 2, "2 towers, 2 tents")
	_ok(main.gannet != null and main.gannet.max_hp > 1000.0, "Gannet in the fort")
	var hidden := 0
	for id: StringName in main.band_units:
		for u: Variant in main.band_units[id]:
			if main.is_dormant(u) and not (u as Node3D).visible:
				hidden += 1
	_ok(hidden == 14, "3 hidden bands (%d)" % hidden)
	_ok(main.objective_state("obj_door") == "active" and main.objective_state("obj_nest") == "", "objectives")
	return true


func _spring() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		MissionHarness.put(main.hero, MissionE5_02.REEDS[&"R1"][1] + Vector3(-6.0, 0.0, 0.0))
		main.hero.command_stop()
		return false
	if String(main.band_state[&"R1"]) == "hidden":
		return false
	_ok(String(main.band_state[&"R1"]) == "sprung", "B1 sprung (%s)" % main.band_state[&"R1"])
	var ring := 0
	for u: Variant in main.band_units[&"R1"]:
		if is_instance_valid(u) and absf(MissionBase._flat((u as Node3D).global_position, main.hero.global_position) - 6.0) < 1.5:
			ring += 1
	_ok(ring >= 3, "its Reivers on the r 6 ring (%d)" % ring)
	_ok(main.objective_state("sec_patience") == "failed" and main.said.has("L6"), "sec_patience failed, L6")
	return true


func _spot() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		var c: Vector3 = MissionE5_02.REEDS[&"R2"][1]
		var s := _soldiers()
		MissionHarness.put(s[0], c + Vector3(-10.0, 0.0, -2.0))
		s[0].command_stop()
		return false
	if String(main.band_state[&"R2"]) == "hidden":
		return false
	_ok(String(main.band_state[&"R2"]) == "spotted", "B2 spotted (%s)" % main.band_state[&"R2"])
	_ok(main.bands_spotted == 1 and main.objective_state("sec_patience") == "active", "counter 1 / 3")
	var seen := 0
	for u: Variant in main.band_units[&"R2"]:
		if is_instance_valid(u) and not main.is_dormant(u) and (u as Node3D).visible:
			seen += 1
	_ok(seen == 5, "B2 visible and awake (%d)" % seen)
	return true


func _wood() -> bool:
	var piece: Building = null
	for v: Variant in main.palisade:
		if is_instance_valid(v) and (v as Building).is_alive():
			piece = v
			break
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		var fg: Unit = _units(0, "flame_guard")[0]
		var before := piece.hp
		piece.take_damage(50.0, fg)
		_ok(absf(before - piece.hp - 50.0) < 0.5, "a Flame Guard hit x1 (%.1f)" % (before - piece.hp))
		before = piece.hp
		piece.take_damage(50.0, main.hero)
		_ok(absf(before - piece.hp - 100.0) < 0.5, "Vessa's hit x2 (%.1f)" % (before - piece.hp))
		_v["piece"] = piece
		piece.take_damage(1.0e6, null)
		return false
	if not main.has_fired(&"E11"):
		return false
	_ok(main.objective_state("obj_door") == "done" and main.objective_state("obj_nest") == "active", "obj_door -> obj_nest")
	_ok(main.waves_fired.has("S1") and main.said.has("L13") and main.said.has("L14"), "the sally, L13, L14")
	return true


func _win() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		(main.palisade[0] as Building).take_damage(1.0e6, null)
		return false
	if not _v.has("final"):
		if main.objective_state("obj_nest") != "active":
			return false
		_v["final"] = true
		main.nest.take_damage(main.nest.max_hp * 0.8, null)
		_ok(main.has_fired(&"E13") and main.said.has("L17"), "the Final at 50 %, L17")
		_ok(absf(main.nest.hp - main.nest.max_hp * 0.5) < 2.0, "fen-wet: not past half before dry (%.0f)" % main.nest.hp)
		MissionHarness.skip_time(main, main.nest_dry_at() - main.mission_time() + 1.0)
		main.gannet.take_damage(main.gannet.max_hp * 0.95, main.hero)
		return false
	if not _v.has("fled"):
		if not main.gannet_fled:
			return false
		_v["fled"] = true
		_ok(main.said.has("L18"), "Gannet flees at 25 %, L18")
		main.nest.take_damage(1.0e6, null)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory")
	_ok(main.objective_state("obj_nest") == "done" and main.said.has("L23"), "obj_nest done, the morning lines")
	var flags := main.mission_flags()
	_ok(flags.has("e5m2_time") and flags.has("e5m2_bands_sprung"), "flags (%s)" % str(flags))
	var cs := CampaignState.open("user://test_e5m2.json")
	cs.reset()
	cs.on_mission_victory(&"e5m2", main)
	_ok(cs.flag("e5m2_patient") and cs.unlocked.has(&"e5m3"), "e5m2_patient, e5m3 unlocked (via c_e5_turn)")
	cs.reset()
	return true
