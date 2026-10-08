extends SceneTree
## Mission e2m1 "The Burning Grove" (docs/design/mission-e2-01.md, E2M1.S1 + S2 checks, scripted through
## MissionHarness; the real-fight timing run is tests/test_e2m1_sim.gd). Parts:
##   start    keep tier 2 (Stronghold), the Citadel refused before 5:45, start army / workers / Wren / story Vey,
##            Torvald + Aldra (dormant story unit), 3 totems, the Heartwood invulnerable and in the truce, objectives,
##            the frost rate (6:00 for 100 % with 3 totems), E2 at 0:25 (Vey leaves, sec_folk / sec_storm).
##   kindle   the kindle refuses with a Shade at 9 m (and while a totem stands), completes in ~3 s once it dies; the
##            frost stops with 0 totems; L10 / Aldra leaves; the Heartwood turns damageable; the 5 wardens (pop 0);
##            obj_hold 12:00; H1 at T + 0:30 (Heartwood mode), H2 with Torvald; a survivor hideout freed (G3 dead +
##            Vessa within 6 m) -> 4 folk walking, counted at the keep; Malrik killed respawns after 60 s; the Frost
##            Hall destroyed -> sec_frosthall + L22; the hold ends -> withdraw, L26-L28, victory; rewards flags.
##   frost    frost 100 % before the kindle = defeat (L29).
##   heart    the Heartwood destroyed after the kindle = defeat (L31).
## Run: godot --headless --path . -s tests/test_e2m1.gd --fixed-fps 60 --quit-after 40000 [-- --only=start|kindle|...]

const TASK_ID := "e2m1"
const MISSION := "res://missions/mission_e2_01.tscn"
const GAP_FRAMES := 3

var _parts: Array[String] = ["start", "kindle", "frost", "heart"]
var _part := ""
var h: MissionHarness
var main: MissionE2_01
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
	h.timeout_frames = 30000
	main = h.open(self, MISSION, {"difficulty": 1, "set": {"campaign_save_path": "user://test_e2m1_none.json"}}) as MissionE2_01
	match _part:
		"start":
			h.steps.add("start state", _start, 10)
			h.steps.add("frost rate + E2", _start_frost, 2400)
		"kindle":
			h.steps.add("clear the glade, kindle refused", _kindle_refused, 800)
			h.steps.add("kindle once the Shade dies", _kindle_done, 400)
			h.steps.add("waves armed: H1", _waves, 4000)
			h.steps.add("a hideout freed, folk home", _folk, 3000)
			h.steps.add("Malrik respawns, Frost Hall burns", _malrik, 6000)
			h.steps.add("the hold ends: victory", _victory, 3000)
		"frost":
			h.steps.add("frost 100 % = defeat", _frost_loss, 600)
		"heart":
			h.steps.add("Heartwood destroyed = defeat", _heart_loss, 600)


func _ok(cond: bool, what: String) -> void:
	h.check(cond, what)


func _units(team: int, type_id: String) -> Array:
	return main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
		var u := n as Unit
		return u and u.is_alive() and int(u.team) == team and u.unit_type and String(u.unit_type.id) == type_id)


# ---------------------------------------------------------------- start

func _start() -> bool:
	var keep: Keep = main.keep
	_ok(keep.tier == 2, "the keep starts as a Stronghold (tier %d)" % keep.tier)
	_ok(keep.can_upgrade() != "", "the Citadel is refused at 0:00 ('%s')" % keep.can_upgrade())
	_ok(main.workers_of(Unit.Team.PLAYER).size() == 6, "6 Cinder Hands")
	var army := _units(0, "flame_guard").size() + _units(0, "ember_archer").size() + _units(0, "blaze_rider").size() \
			+ _units(0, "pyre_adept").size()
	_ok(army == 14, "14 start soldiers (%d)" % army)
	_ok(main.wren != null and main.wren.is_alive() and not main.wren.is_commandable(), "Wren: alive, not commandable")
	_ok(main.vey_npc != null and main.vey_npc.is_alive(), "Old Vey (story) at the start")
	_ok(main.torvald != null and main.torvald.is_alive() and main.torvald.level == 5, "Torvald L5")
	_ok(main.shadow_hero.level == 5, "Malrik L5 (%d)" % main.shadow_hero.level)
	_ok(main.aldra == null or main.is_dormant(main.aldra), "Aldra is a dormant story unit")
	_ok(main.totems_alive() == 3, "3 Rime Totems")
	var sizes := {}
	for g: StringName in main.guard_groups:
		sizes[String(g)] = (main.guard_groups[g] as Array).size()
	_ok(sizes == {"G1": 5, "G2": 10, "G3": 4, "G4": 4, "G5": 7, "G6": 4}, "guard groups %s" % str(sizes))
	_ok(main.heartwood.invulnerable and Unit.in_truce(main.heartwood, main.guard_groups[&"G2"][0]),
			"the Heartwood: invulnerable, in the truce")
	main.heartwood.take_damage(500.0, null)
	_ok(main.heartwood.hp == main.heartwood.max_hp, "no damage before the kindle")
	_ok(h.saw("obj_heartwood", "active") and h.saw("obj_vessa", "active"), "start objectives %s" % str(h.objective_log))
	_ok((main.hero as Wizard).level == 4 and (main.hero as Wizard).spell_points == 3, "Vessa L4 + 3 points")
	_ok(main.frost_hall.is_locked(), "the Frost Hall is locked for the Shadow bot")
	_ok(not main.has_fired(&"spotlight"), "the spotlight waits for the Citadel")
	_v["f0"] = main.frost
	_v["t0"] = main.mission_time()
	return true


func _start_frost() -> bool:
	if main.mission_time() - float(_v["t0"]) < 30.0:
		return false
	var rate := (main.frost - float(_v["f0"])) / (main.mission_time() - float(_v["t0"]))
	_ok(absf(100.0 / rate - 360.0) < 6.0, "frost 100 %% at %.0f s with 3 totems (spec 6:00)" % (100.0 / rate))
	_ok(main.has_fired(&"E2") and h.saw("sec_folk", "active") and h.saw("sec_storm", "active"), "E2: sec_folk, sec_storm")
	_ok(main.said.has(4) and main.said.has(5), "L4-L5 %s" % str(main.said))
	return true


# ---------------------------------------------------------------- kindle and the hold

func _kindle_refused() -> bool:
	if not _v.has("put"):
		_v["put"] = true
		MissionHarness.kill(main.guard_groups[&"G2"])
		MissionHarness.kill(main.guard_groups[&"G1"])
		# One totem left: the kindle is refused while it stands.
		MissionHarness.kill([main.totems[0], main.totems[1]])
		MissionHarness.put(main.hero, MissionE2_01.HEARTWOOD_POS + Vector3(3.5, 0.0, 0.0))
		_t0 = h.frame
		return false
	if h.frame - _t0 == 240 and not _v.has("shade"):
		_ok(not main.kindled and main.kindle_blocked, "refused while a totem stands")
		var f := main.frost
		MissionHarness.kill([main.totems[2]])
		_v["frost_at"] = f
		_v["shade"] = main._spawn(main.make_unit("shade"), Unit.Team.ENEMY, MissionE2_01.HEARTWOOD_POS + Vector3(-9.0, 0.0, 0.0))
		MissionHarness.immortal(_v["shade"])
		(_v["shade"] as Unit).aggro_range = 0.0
		_t0 = h.frame
		return false
	if h.frame - _t0 == 240 and _v.has("shade"):
		_ok(main.has_fired(&"E6") and main.said.has(10), "3rd totem: E6 / L10")
		_ok(absf(main.frost - float(_v["frost_at"])) < 0.5, "frost stops with 0 totems (%.1f -> %.1f)" % [_v["frost_at"], main.frost])
		_ok(not main.kindled and main.kindle_blocked, "refused with a Shade at 9 m")
		return true
	return false


func _kindle_done() -> bool:
	if not _v.has("killed"):
		_v["killed"] = true
		var s: Unit = _v["shade"]
		s.death_guard = Callable()
		MissionHarness.kill([s])
		_t0 = h.frame
		return false
	if main.kindled:
		var dt := float(h.frame - _t0) / 60.0
		_ok(dt >= 2.8 and dt <= 4.2, "kindle in %.1f s" % dt)
		_ok(not main.heartwood.invulnerable and not Unit.in_truce(main.heartwood, main.shadow_hero), "the Heartwood can be hit now")
		_ok(main.heart_wardens.size() == 5, "5 wardens (%d)" % main.heart_wardens.size())
		var pop0 := main.heart_wardens.all(func(u: Variant) -> bool: return (u as Unit).unit_type.pop == 0)
		_ok(pop0, "wardens take no pop")
		_ok(h.saw("obj_heartwood", "done") and h.saw("obj_hold", "active"), "obj_hold active")
		_ok(absf(main.hold_left - 720.0) < 1.0, "hold 12:00 (%.0f)" % main.hold_left)
		_ok(main.said.has(11) and main.said.has(12), "L11-L12")
		return true
	return false


func _waves() -> bool:
	if not _v.has("skip"):
		_v["skip"] = true
		MissionHarness.skip_time(main, 31.0)
		return false
	if main.waves_fired.has(&"H1"):
		var units: Array = main.wave_units[&"H1"]
		_ok(units.size() == 8, "H1: 8 units (%d)" % units.size())
		_ok(StringName((units[0] as Unit).get_meta(MissionBase.META_MODE)) == &"heartwood", "H1 in Heartwood mode")
		_ok(main.said.has(13) and main.said.has(14), "L13-L14")
		MissionHarness.kill(units)
		return true
	return false


func _folk() -> bool:
	if not _v.has("g3"):
		_v["g3"] = true
		MissionHarness.kill(main.guard_groups[&"G3"])
		MissionHarness.put(main.hero, (MissionE2_01.HIDEOUTS[&"S1"] as Array)[1] + Vector3(2.0, 0.0, 0.0))
		return false
	if not _v.has("freed"):
		if main.hideout_freed.has(&"S1"):
			_v["freed"] = true
			_ok(main.folk.size() == 4 and main.said.has(20), "4 survivors walk, L20")
			for f in main.folk:
				MissionHarness.put(f, main.keep.global_position + Vector3(5.0, 0.0, -5.0))
		return false
	if main.folk_home == 4:
		_ok(h.saw("sec_folk", "active"), "sec_folk counts")
		MissionHarness.put(main.hero, MissionE2_01.HEARTWOOD_POS + Vector3(3.5, 0.0, 3.0))
		return true
	return false


func _malrik() -> bool:
	if not _v.has("killed_m"):
		_v["killed_m"] = true
		MissionHarness.kill([main.shadow_hero])
		_v["t"] = main.mission_time()
		main.frost_hall.take_damage(1.0e7, null)
		return false
	if main.shadow_hero.is_alive() and main.mission_time() - float(_v["t"]) > 5.0:
		var dt := main.mission_time() - float(_v["t"])
		_ok(dt >= 59.0 and dt <= 62.0, "Malrik back after %.0f s" % dt)
		_ok(h.saw("sec_frosthall", "done") and main.said.has(22), "Frost Hall: sec_frosthall + L22")
		return true
	return false


func _victory() -> bool:
	if not _v.has("end"):
		_v["end"] = true
		main.hold_left = 0.5
		return false
	if h.ended < 0:
		return false
	_ok(h.ended == 1, "victory (ended %d)" % h.ended)
	_ok(main.hold_done and main.said.has(26) and main.said.has(27) and main.said.has(28), "E20: L26-L28")
	_ok(not main.torvald.is_alive() or Unit.in_truce(main.torvald, main.hero) or main.torvald.has_meta(MissionBase.META_MODE),
			"Torvald withdraws")
	var r: Dictionary = CampaignState.reward_of(&"e2m1")
	_ok(CampaignState.film_target(r.get("next", &"")) == &"e2m2" and (r.get("set_flags", {}) as Dictionary).get("helper_vey_unlocked") == true,
			"rewards e2m1 %s" % str(r))
	_ok(bool(main.mission_flags().get("spotlight_seen_helper_vey", false)) == main.has_fired(&"spotlight"),
			"the spotlight seen flag follows the card")
	return true


# ---------------------------------------------------------------- defeats

func _frost_loss() -> bool:
	if not _v.has("set"):
		_v["set"] = true
		main.frost = 99.95
		return false
	if h.ended == 0:
		_ok(main.said.has(29) and h.saw("obj_heartwood", "failed"), "E15: L29, obj_heartwood failed")
		return true
	return false


func _heart_loss() -> bool:
	if not _v.has("k"):
		_v["k"] = true
		MissionHarness.kill(main.guard_groups[&"G2"])
		MissionHarness.kill(main.totems)
		MissionHarness.put(main.hero, MissionE2_01.HEARTWOOD_POS + Vector3(3.5, 0.0, 0.0))
		return false
	if main.kindled and not _v.has("hit"):
		_v["hit"] = true
		main.heartwood.take_damage(1.0e7, main.shadow_hero)
		return false
	if h.ended == 0:
		_ok(main.said.has(31), "E22: L31")
		return true
	return false
