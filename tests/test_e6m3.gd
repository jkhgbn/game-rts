extends SceneTree
## Mission e6m3 "The Year Nothing Grew" (docs/design/mission-e6-03.md, scripted through MissionHarness; the real-fight
## runs are tests/test_e6m3_sim.gd (tending) and tests/test_e6m3_passive_sim.gd). Parts:
##   start   Ysolde L1 (Thornburst, cap 4), Maelis (not commandable), 4 Spriglings, 4 Thornlings + 2 Burr Slingers,
##           250 crystals, the Hollow Oak, 4 gardens at Life 500, tier 1.
##   frost   night 1: an untended garden loses 3 / s, a garden with 2 tending Spriglings grows back; a wolf next to a
##           garden bites the garden, not the Hollow Oak.
##   spring  16:00: victory (cinematics off), flags, flags-only reward, c_e6_seed -> e6m4 unlocked.
##   lost    three gardens lost on normal = defeat.
## Run: godot --headless --path . -s tests/test_e6m3.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|...]

const TASK_ID := "e6m3"
const MISSION := "res://missions/mission_e6_03.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "frost", "spring", "lost"]
var _part := ""
var h: MissionHarness
var main: MissionE6_03
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
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e6m3_none.json"}}) as MissionE6_03
	match _part:
		"start":
			h.steps.add("start state", _start, 30)
		"frost":
			h.steps.add("frost, tending, wolves bite gardens", _frost, 4000)
		"spring":
			h.steps.add("spring, victory, flags", _spring, 4000)
		"lost":
			h.steps.add("too few gardens = defeat", _lost, 2000)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


func _start() -> bool:
	var hero := main.hero
	_ok(hero.level == 1 and hero.level_cap == 4 and hero.spell_rank(&"thornburst") >= 1, "Ysolde L1, Thornburst, cap 4")
	_ok(main.player_kingdom == &"nature", "the Nature kingdom (Ysolde)")
	_ok(main.maelis != null and not main.maelis.is_commandable(), "Maelis, not commandable")
	_ok(_units(0, "sprigling").size() == 4 and _units(0, "thornling").size() == 4 and _units(0, "burr_slinger").size() == 2,
			"4 Spriglings, 4 Thornlings, 2 Burr Slingers")
	_ok(Economy.for_team(0).crystals == 250, "250 crystals (%d)" % Economy.for_team(0).crystals)
	_ok(main.keep != null and main.keep.is_alive(), "the Hollow Oak")
	_ok(main.gardens.size() == 4 and main.gardens.all(func(g: Variant) -> bool: return is_equal_approx((g as MissionE6_03.SeedGarden).hp, 500.0)),
			"4 gardens at 500")
	_ok(main.tier_system != null and main.tier_system.max_tier == 1, "tier 1")
	return true


func _frost() -> bool:
	var g0 := main.gardens[0] as MissionE6_03.SeedGarden   # untended
	var g2 := main.gardens[2] as MissionE6_03.SeedGarden   # tended by 2
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		MissionHarness.put(main.hero, Vector3(40.0, 0.0, 50.0))
		main.hero.command_stop()
		var spr := _units(0, "sprigling")
		for i in 2:
			MissionHarness.put(spr[i] as Unit, g2.global_position + Vector3(0.8 * i, 0.0, 0.8))
			(spr[i] as Unit).command_stop()
		g2.change(-200.0)
		MissionHarness.skip_time(main, 212.0 - main.mission_time())
		return false
	if not _v.has("night"):
		if main.night != 0:
			return false
		_v["night"] = main.mission_time()
		_v["g0"] = g0.hp
		_v["g2"] = g2.hp
		return false
	if main.mission_time() - float(_v["night"]) < 10.0:
		for u in _units(1, "frostfang"):
			(u as Unit).take_damage(1.0e6, null)
		return false
	if not _v.has("checked"):
		_v["checked"] = true
		var lost0 := float(_v["g0"]) - g0.hp
		_ok(lost0 > 25.0 and lost0 < 35.0, "untended: -3 / s at night (%.1f in 10 s)" % lost0)
		_ok(g2.hp > float(_v["g2"]) + 30.0, "tended by 2: grows back (%.0f -> %.0f)" % [float(_v["g2"]), g2.hp])
		var wolf := main.spawn_rows([["frostfang", 1]], main.keep.global_position + Vector3(6.0, 0.0, -6.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		main.arm_enemy(wolf)
		wolf.set_meta(&"garden", 0)
		main.order_wave(wolf, &"garden", g0.global_position)
		MissionHarness.put(wolf, g0.global_position + Vector3(4.0, 0.0, 4.0))
		_v["wolf"] = wolf
		_v["t2"] = main.mission_time()
		_v["keep_hp"] = main.keep.hp
		return false
	if main.mission_time() - float(_v["t2"]) < 6.0:
		return false
	var wolf := _v["wolf"] as Unit
	_ok(is_instance_valid(wolf) and wolf.attack_target == g0, "the wolf bites the garden")
	_ok(is_equal_approx(main.keep.hp, float(_v["keep_hp"])), "never the Hollow Oak")
	return true


func _spring() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		for g: Variant in main.gardens:
			(g as MissionE6_03.SeedGarden).max_hp = 1.0e6
			(g as MissionE6_03.SeedGarden).hp = 1.0e6
		MissionHarness.skip_time(main, 961.0 - main.mission_time())
		return false
	if h.ended < 0:
		for n in main.get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and int(u.team) == Unit.Team.ENEMY:
				u.take_damage(1.0e6, null)
		return false
	_ok(h.ended == 1, "victory at spring")
	_ok(main.said.has("L21") and main.objective_state("sec_all") == "done", "L21, sec_all done")
	var cs := CampaignState.open("user://test_e6m3.json")
	cs.reset()
	var items_before := JSON.stringify(cs.items)
	cs.on_mission_victory(&"e6m3", main)
	_ok(cs.flag("e6m3_all_gardens") and cs.unlocked.has(&"e6m4") and JSON.stringify(cs.items) == items_before,
			"flags only, e6m4 unlocked")
	cs.reset()
	return true


func _lost() -> bool:
	if not _v.has("t"):
		_v["t"] = true
		MissionHarness.immortal(main.hero)
		for i in 3:
			(main.gardens[i] as MissionE6_03.SeedGarden).change(-1.0e6)
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 0 and main.said.has("L23"), "defeat with one garden left, L23")
	return true
