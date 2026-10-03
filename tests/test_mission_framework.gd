extends SceneTree
## Mission foundation (MissionBase + MissionConfig + the shared knobs, docs/design/mission-framework.md). Runs the
## MissionSkeleton four times through MissionHarness (tests/helpers/mission_harness.gd), one part per group of knobs,
## then checks CampaignState alone:
##   core     objectives order + Events, briefing(), fire_once, after timers, hold_world (mission_time stops, units
##            dormant, restored with their orders: a worker still gathers, a soldier still attack-moves, the
##            death_guard comes back, a unit the mission put to sleep during the hold stays asleep), play_cutscene
##            fallback end state, dialogue lines, the E-list, a scripted victory, the campaign save (config rewards
##            set_flags, mission flags, a track counter added to the saved value, a replay does not add it twice).
##   start    tiers_enabled / max_tier / bots_upgrade / start_tiers (quiet), casters_enabled, t3_enabled,
##            helpers_enabled + helper_start_called + helper_call_price, titan knobs (scene_knob), start level /
##            spells / spell points / level cap, start crystals by difficulty (player, enemy), start essence + no
##            trickle, pop bonus, resources_hidden, forced artifact slot.
##   runtime  no-economy mode (carried essence held back, grant_carried_essence), lock_base, set_truce,
##            artifact_power_used (gate, Recharging), seats (switch_seat_side with grace that gives an older truce
##            back, withdraw_seat, an untagged seat switched then withdrawn takes only its own units, a dead tagged
##            seat stays empty), truce_count bookkeeping, set_player_hero + the instant-loss rule.
##   keep     the keep-lost defeat.
##   ending   lose(3) then win(0): the first ending stands, no victory save.
##   nokeep   a map without a player keep is never lost by the keep-lost rule.
##   campaign CampaignState: int flags round-trip, set_flags, reward_of (registered), "unlock", "save_items" false,
##            String flags, per-mission track counters, the crash-safe save (.tmp / .bak / .corrupt).
## Run: godot --headless --path . -s tests/test_mission_framework.gd --fixed-fps 60 --quit-after 30000
##   Options after `--`: --only=core|start|runtime|keep|ending|nokeep|campaign

const TASK_ID := "mission_framework"
const SAVE := "user://test_mission_framework.json"
const GAP_FRAMES := 3   # frames between parts: the old scene (banks, rosters, tier system) is really gone

const SAVE_END := "user://test_mission_framework_end.json"

var _parts: Array[String] = ["core", "start", "runtime", "keep", "ending", "nokeep", "campaign"]
var _part := ""
var h: MissionHarness
var main: Node
var _errors: Array[String] = []
var _v := {}          # scratch values between steps
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
	while not _parts.is_empty():
		_part = _parts.pop_front()
		_v = {}
		h = MissionHarness.new()
		h.task_id = "%s/%s" % [TASK_ID, _part]
		match _part:
			"core":
				var cs := CampaignState.open(SAVE)
				cs.reset()
				cs.set_flags({"skel_track": 5}, true)
				main = h.open(self, MissionSkeleton, {"set": {"campaign_save_path": SAVE}})
				main.set(&"save_campaign_on_victory", true)
				h.steps.add("start state", _core_start, 10)
				h.steps.add("after + hold_world", _core_hold, 400)
				h.steps.add("scripted victory", _core_walk, 900)
				h.steps.add("victory checks", _core_saved, 10)
				return
			"start":
				main = h.open(self, MissionSkeleton, {"difficulty": 2, "config": _start_config()})
				h.steps.add("knobs", _start_knobs, 400)
				return
			"runtime":
				var c := _skeleton_config()
				c.economy_enabled = false
				main = h.open(self, MissionSkeleton, {"config": c})
				h.protect_hero = false
				h.steps.add("economy, lock, truce", _rt_setup, 10)
				h.steps.add("truce holds", _rt_truce, 300)
				h.steps.add("artifact power", _rt_artifact, 10)
				h.steps.add("seats", _rt_seats, 400)
				h.steps.add("set_player_hero + instant loss", _rt_hero, 900)
				return
			"keep":
				main = h.open(self, MissionSkeleton)
				h.steps.add("keep lost", _keep_lost, 300)
				return
			"ending":
				CampaignState.open(SAVE_END).reset()
				main = h.open(self, MissionSkeleton, {"set": {"campaign_save_path": SAVE_END}})
				main.set(&"save_campaign_on_victory", true)
				h.protect_hero = false
				h.steps.add("lose(3) then win(0)", _ending_first_wins, 400)
				return
			"nokeep":
				main = h.open(self, NoKeepMission)
				h.steps.add("no keep, no keep-lost defeat", _no_keep, 300)
				return
			"campaign":
				h = null
				_campaign_static()
	_done()


func _done() -> void:
	_finished = true
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])


func _ok(cond: bool, what: String) -> void:
	if h:
		h.check(cond, what)
	elif not cond:
		_errors.append("%s: %s" % [_part, what])
		print("  x ", what)


func _skeleton_config() -> MissionConfig:
	var tmp := MissionSkeleton.new()
	var c: MissionConfig = tmp.config
	tmp.free()
	return c


# ---------------------------------------------------------------- core

func _core_start() -> bool:
	_ok(h.saw("obj_reach", "active") and h.saw("obj_alive", "active"), "start objectives emitted %s" % str(h.objective_log))
	_ok(h.objective_log.find("obj_reach=active") < h.objective_log.find("obj_alive=active"), "objective order")
	var rows: Array = main.call(&"objectives")
	_ok(rows.size() == 4 and rows[0]["id"] == &"obj_reach" and rows[3]["type"] == "secondary", "objectives() rows")
	_ok(rows[0].get("position") == MissionSkeleton.GOAL_POS, "_objective_extra merged")
	_ok(main.call(&"objective_state", "obj_hold") == "", "hidden objective reads ''")
	var b: Dictionary = main.call(&"briefing")
	_ok(b["title"] == "Skeleton" and (b["objectives"] as Array).size() == 2 and b["rule"] == "Vessa must survive",
			"briefing() %s" % str(b))
	_ok((main.get(&"dialogue_log") as Array).size() == 2 and h.dialogue_log.size() == 2, "intro lines L1 L2")
	_ok(bool(main.get(&"gate_open")), "play_cutscene end state ran (cinematics off)")
	_ok(main.call(&"fire_once", &"EX") and not main.call(&"fire_once", &"EX") and main.call(&"has_fired", &"EX"),
			"fire_once")
	main.call(&"set_mission_flag", "skel_count", 3)
	main.call(&"add_track_counter", "skel_track", 2)
	return true


func _core_hold() -> bool:
	if not _v.has("t0"):
		_v["t0"] = float(main.call(&"mission_time"))
		_v["m0"] = float(main.call(&"match_time"))
		_v["fired"] = false
		main.call(&"after", 2.0, func() -> void: _v["fired"] = true)
		# H1: what the hold must give back. A gathering worker, a marching soldier, a death_guard (Rekindle-like).
		var workers: Array = main.get_tree().get_nodes_in_group("units").filter(func(n: Node) -> bool:
			return n.has_method(&"command_gather") and int(n.get(&"team")) == Unit.Team.PLAYER)
		_ok(workers.size() >= 1 and workers[0].call(&"is_gathering"), "a worker gathers before the hold")
		_v["worker"] = workers[0] if workers.size() > 0 else null
		_v["worker_node"] = workers[0].get(&"gather_node") if workers.size() > 0 else null
		var soldier: Unit = main.call(&"_spawn", main.call(&"make_unit", "flame_guard"), Unit.Team.PLAYER, Vector3(-30.0, 0.0, -30.0))
		soldier.command_attack_move(Vector3(30.0, 0.0, 30.0))
		_v["soldier"] = soldier
		var sleeper: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.ENEMY, Vector3(30.0, 0.0, -30.0))
		_v["sleeper"] = sleeper
		var enemy0: Unit = main.get(&"shadow_hero")
		var guard := func(_a: Variant) -> bool: return false
		enemy0.death_guard = guard
		_v["guard"] = guard
		main.call(&"hold_world", true, [main.get(&"hero")])
		_t0 = h.frame
		return false
	if h.frame - _t0 == 30:   # the mission puts a held unit to sleep itself: it stays asleep after the release
		main.call(&"set_dormant", _v["sleeper"], true)
	if h.frame - _t0 == 90:
		var dm := float(main.call(&"match_time")) - float(_v["m0"])
		var dt := float(main.call(&"mission_time")) - float(_v["t0"])
		_ok(dm > 1.4 and dt < 0.05, "held: match +%.2f s, mission +%.2f s" % [dm, dt])
		_ok(not bool(_v["fired"]), "timer fired while held")
		var enemy: Unit = main.get(&"shadow_hero")
		_ok(main.call(&"is_dormant", enemy) and not main.call(&"is_dormant", main.get(&"hero")), "hold: dormant / awake")
		main.call(&"hold_world", false)
		_ok(not main.call(&"is_dormant", enemy) and enemy.is_in_group("units"), "hold restored")
		_ok(enemy.death_guard == _v["guard"], "hold release gives the death_guard back (Rekindle)")
		var w: Node = _v["worker"]
		_ok(w != null and w.call(&"is_gathering") and w.get(&"gather_node") == _v["worker_node"],
				"hold release: the worker still gathers the same node")
		var s: Unit = _v["soldier"]
		_ok(s.is_attack_moving() and s.is_in_group("units") and s.aggro_range > 0.0,
				"hold release: the soldier keeps its attack-move order (aggro %.1f)" % s.aggro_range)
		_ok(main.call(&"is_dormant", _v["sleeper"]), "a unit the mission put to sleep during the hold stays asleep")
		main.call(&"set_dormant", _v["sleeper"], false)
		_ok(not main.call(&"is_dormant", _v["sleeper"]) and (_v["sleeper"] as Unit).is_in_group("units"), "and wakes on demand")
		MissionHarness.kill([_v["soldier"], _v["sleeper"]])
		enemy.death_guard = Callable()
	if h.frame - _t0 > 90 and bool(_v["fired"]):
		var dt2 := float(main.call(&"mission_time")) - float(_v["t0"])
		_ok(dt2 >= 2.0 and dt2 < 2.2, "after(2) fired at mission +%.2f" % dt2)
		return true
	return false


func _core_walk() -> bool:
	if not _v.has("walked"):
		_v["walked"] = true
		MissionHarness.put(main.get(&"hero"), MissionSkeleton.GOAL_POS)
	return h.ended >= 0


func _core_saved() -> bool:
	_ok(h.ended == 1, "victory (ended %d)" % h.ended)
	_ok(main.call(&"has_fired", &"E2") and main.call(&"has_fired", &"E3"), "E-list E2 E3 fired")
	_ok(h.saw("obj_reach", "done") and h.saw("obj_hold", "done"), "objectives done %s" % str(h.objective_log))
	_ok((main.get(&"dialogue_log") as Array).size() == 3, "line 3 said")
	_ok(main.call(&"primaries_done"), "primaries_done")
	var cs := CampaignState.open(SAVE)
	_ok(cs.is_completed(&"m_skeleton") and cs.flag("skeleton_done"), "saved: completed + set_flags (config rewards)")
	_ok(int(cs.flag_value("skel_count", 0)) == 3, "saved mission flag %s" % str(cs.flag_value("skel_count")))
	_ok(int(cs.flag_value("skel_track", 0)) == 7, "track counter 5 + 2 = %s" % str(cs.flag_value("skel_track")))
	# M7: a replay of the same mission replaces its contribution (the latest victory counts), never adds it again.
	cs.add_track("m_skeleton", {"skel_track": 2})
	_ok(int(cs.flag_value("skel_track", 0)) == 7, "replay: track counter stays 7 (%s)" % str(cs.flag_value("skel_track")))
	cs.add_track("m_skeleton", {"skel_track": 3})
	_ok(int(cs.flag_value("skel_track", 0)) == 8, "replay with 3 uses: 5 + 3 = %s" % str(cs.flag_value("skel_track")))
	cs.reset()
	return true


# ---------------------------------------------------------------- start state knobs

func _start_config() -> MissionConfig:
	var c := _skeleton_config()
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {0: 2, 1: 3}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_start_called = true
	c.helper_call_price = {"crystals": 0, "essence": [10, 20, 30], "time": 5.0}
	c.titans_enabled = true
	c.lair_max = 1
	c.titan_max_trained = 2
	c.lair_min_time = 240.0
	c.start_level = 4
	c.start_spells = [&"fireball"]
	c.start_spell_points = 3
	c.level_cap = 5
	c.start_crystals = [111, 222, 333]
	c.enemy_start_crystals = [999]
	c.start_essence = 400
	c.essence_trickle = false
	c.start_pop_bonus = 10
	c.resources_hidden = true
	c.forced_artifacts = ["ember_crown", ""]
	return c


func _start_knobs() -> bool:
	if h.frame < 120:   # 2 s: the trickle would have added essence by now
		return false
	var ts := TierSystem.instance()
	var keep: Keep = main.get(&"keep")
	var enemy_keep: Keep = main.get(&"shadow_keep")
	_ok(ts != null and ts.max_tier == 3 and not ts.bots_upgrade, "tiers_enabled / max_tier / bots_upgrade")
	_ok(keep.tier == 2 and enemy_keep.tier == 3 and TierSystem.tier_of(0) == 2,
			"start_tiers %d / %d" % [keep.tier, enemy_keep.tier])
	_ok(not keep.is_upgrading() and absf(keep.max_hp - keep.building_type.max_hp * TierSystem.HP_MULT[1]) < 1.0,
			"start tier HP x1.2 (%.0f)" % keep.max_hp)
	_ok(CasterKit.enabled_here(), "casters_enabled -> CasterKit.enabled_here")
	_ok(T3Kit.enabled_here() and T3Kit.helpers_here(), "t3_enabled / helpers_enabled -> T3Kit")
	var ids: Array = keep.trainable_types().map(func(t: UnitType) -> StringName: return t.id)
	_ok(ids.has(T3Kit.KEEP_UNITS[&"fire"]), "keep lists the T3 unit %s" % str(ids))
	var roster := HelperRoster.for_team(0)
	_ok(roster.state() == &"alive" and roster.helper != null, "helper_start_called: helper on the field (%s)" % roster.state())
	_ok(roster.call_type().cost == 0 and roster.call_essence() == 30 and is_equal_approx(roster.call_type().train_time, 5.0),
			"helper_call_price (hard: 30 essence) %d / %d" % [roster.call_type().cost, roster.call_essence()])
	_ok(MissionBase.scene_knob(&"titans_enabled", false) == true and MissionBase.scene_knob(&"lair_max", -1) == 1
			and MissionBase.scene_knob(&"titan_max_trained", -1) == 2 and MissionBase.scene_knob(&"lair_min_time", -1.0) == 240.0
			and MissionBase.scene_knob(&"no_such_knob", 7) == 7, "titan knobs through scene_knob")
	var hero: Wizard = main.get(&"hero")
	_ok(hero.level == 4 and hero.spell_rank(&"fireball") >= 1 and hero.spell_points == 3,
			"start level 4 / fireball / 3 points (L%d r%d p%d)" % [hero.level, hero.spell_rank(&"fireball"), hero.spell_points])
	hero.add_xp(50000)
	_ok(hero.level == 5 and hero.xp == 0, "level cap 5 (L%d xp %d)" % [hero.level, hero.xp])
	var eco: Economy = main.get(&"economy")
	_ok(eco.crystals == 333, "start_crystals hard = %d" % eco.crystals)
	_ok(Economy.for_team(1).crystals == 999, "enemy_start_crystals %d" % Economy.for_team(1).crystals)
	var bank := EssenceBank.for_team(0)
	_ok(bank.essence == 400 and not bank.trickle_enabled, "start_essence 400, no trickle (%d)" % bank.essence)
	_ok(eco.pop_cap == keep.building_type.pop_bonus + 10, "pop bonus: cap %d" % eco.pop_cap)
	var hud: Node = main.get(&"hud")
	_ok(not (hud.get(&"top_bar") as Control).visible, "resources_hidden")
	var inv := ItemDrops.inventory_of(hero) as Inventory
	_ok(inv != null and inv.get_type(Inventory.ARTIFACT_SLOT) != null
			and inv.get_type(Inventory.ARTIFACT_SLOT).id == &"ember_crown", "forced artifact slot 1")
	return true


# ---------------------------------------------------------------- runtime knobs

func _rt_setup() -> bool:
	var eco: Economy = main.get(&"economy")
	var bank := EssenceBank.for_team(0)
	_ok(eco.crystals == 0 and bank.essence == 0 and not bank.trickle_enabled and not bank.kill_income_enabled,
			"no-economy: %d crystals / %d essence, no trickle, no kill income" % [eco.crystals, bank.essence])
	_ok(not (main.get(&"hud").get(&"top_bar") as Control).visible, "no-economy hides the top bar")
	# M6: the essence carried from the last mission is held back, then granted when a phase turns the economy on.
	var carried := CampaignState.new()
	carried.items = {"essence": 120}
	carried.apply_to_start(main)
	_ok(bank.essence == 0 and int(main.get_meta(CampaignState.META_CARRIED_ESSENCE, 0)) == 120,
			"no-economy: carried essence held back (bank %d, held %s)" % [bank.essence, str(main.get_meta(CampaignState.META_CARRIED_ESSENCE, 0))])
	_ok(int(main.call(&"grant_carried_essence")) == 120 and bank.essence == 120, "grant_carried_essence: bank %d" % bank.essence)
	bank.essence = 0
	var keep: Keep = main.get(&"keep")
	var worker: UnitType = keep.trainable_types()[0]
	main.call(&"lock_base", true)
	_ok(keep.can_queue(worker) == TrainingBuilding.REASON_LOCKED, "lock_base: '%s'" % keep.can_queue(worker))
	main.call(&"lock_base", false)
	_ok(keep.can_queue(worker) != TrainingBuilding.REASON_LOCKED, "unlock_base")
	# Truce: a Flame Guard and a Shade side by side.
	var at := Vector3(0.0, 0.0, 20.0)
	var a: Unit = main.call(&"_spawn", main.call(&"make_unit", "flame_guard"), Unit.Team.PLAYER, at)
	var b: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.ENEMY, at + Vector3(1.5, 0.0, 0.0))
	main.call(&"set_truce", [a, b], true, &"duel")
	_ok(not a.is_enemy_of(b) and not b.is_enemy_of(a), "truce: not enemies")
	_v["a"] = a
	_v["b"] = b
	_t0 = h.frame
	return true


func _rt_truce() -> bool:
	if h.frame - _t0 < 150:
		return false
	var a: Unit = _v["a"]
	var b: Unit = _v["b"]
	_ok(a.hp >= a.max_hp and b.hp >= b.max_hp, "truce: no damage in 2.5 s (%.0f / %.0f)" % [a.hp, b.hp])
	main.call(&"set_truce", [a, b], false, &"duel")
	_ok(a.is_enemy_of(b), "truce off: enemies again")
	MissionHarness.kill([a, b])
	return true


func _rt_artifact() -> bool:
	var hero: Wizard = main.get(&"hero")
	var inv := ItemDrops.inventory_of(hero) as Inventory
	var crown := ItemDrops.item_type(&"ember_crown") as ItemType
	inv.add_item(crown)
	var old_cd: float = crown.active_cooldown
	crown.active_cooldown = 5.0
	var used: Array = []
	inv.artifact_power_used.connect(func(id: StringName) -> void: used.append(id))
	inv.artifact_power_gate = func(_id: StringName) -> String: return "The stone holds you"
	_ok(inv.use_artifact_power(0) == "The stone holds you" and used.is_empty(), "artifact power gate")
	inv.artifact_power_gate = Callable()
	_ok(inv.use_artifact_power(0) == "" and used == [&"ember_crown"], "artifact_power_used(ember_crown) %s" % str(used))
	_ok(inv.use_artifact_power(0) == Inventory.REASON_RECHARGING, "Recharging")
	_ok(inv.use_artifact_power(1) == "Empty slot", "empty slot 2")
	crown.active_cooldown = old_cd
	return true


func _rt_seats() -> bool:
	if not _v.has("seat_a"):
		var at := Vector3(10.0, 0.0, -10.0)
		var s1: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.ENEMY, at)
		var s2: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.ENEMY, at + Vector3(1.5, 0, 0))
		var w1: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.ENEMY, Vector3(-10.0, 0.0, 10.0))
		var p1: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.ENEMY, at + Vector3(0, 0, 3.0))
		main.call(&"add_seat", &"turncoat", Unit.Team.ENEMY)
		main.call(&"add_seat", &"leaver", Unit.Team.ENEMY)
		for u in [s1, s2]:
			main.call(&"tag_seat", u, &"turncoat")
		main.call(&"tag_seat", w1, &"leaver")
		main.call(&"set_truce", [s2, p1], true, &"pact")   # M2: a truce the switch grace must not erase
		main.call(&"switch_seat_side", &"turncoat", Unit.Team.PLAYER, 1.0)
		_ok(int(s1.team) == Unit.Team.PLAYER and int(s2.team) == Unit.Team.PLAYER
				and main.call(&"seat_team", &"turncoat") == Unit.Team.PLAYER, "switch_seat_side: team changed")
		_ok(Unit.in_truce(s1, main.get(&"shadow_hero")), "switch_seat_side: grace truce")
		main.call(&"withdraw_seat", &"leaver", Vector3(-12.0, 0.0, 12.0), 4.0)
		_ok(not (main.get(&"shadow_hero") as Unit).is_enemy_of(w1), "withdraw_seat: at peace")
		# H3: an UNTAGGED seat (team NEUTRAL here) switched to the player, then withdrawn: only its own two units go.
		var n1: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.NEUTRAL, Vector3(14.0, 0.0, 14.0))
		var n2: Unit = main.call(&"_spawn", main.call(&"make_unit", "shade"), Unit.Team.NEUTRAL, Vector3(15.5, 0.0, 14.0))
		main.call(&"add_seat", &"allies", Unit.Team.NEUTRAL)
		var before: Array = main.call(&"seat_nodes", &"allies")
		_ok(before.has(n1) and before.has(n2), "untagged seat covers its team's untagged units (%d)" % before.size())
		main.call(&"switch_seat_side", &"allies", Unit.Team.PLAYER, 0.0)
		var after_switch: Array = main.call(&"seat_nodes", &"allies")
		var hero: Unit = main.get(&"hero")
		_ok(after_switch.size() == before.size() and not after_switch.has(hero) and not after_switch.has(main.get(&"keep")),
				"switched untagged seat = the nodes it moved, not the player's side (%d nodes)" % after_switch.size())
		main.call(&"withdraw_seat", &"allies", Vector3(16.0, 0.0, 16.0), 4.0)
		_ok(not hero.has_meta(Unit.TRUCE_META)
				and not (main.get(&"keep") as Node).has_meta(Unit.TRUCE_META), "withdraw: the player's hero / keep stay in the fight")
		_ok(n1.has_meta(Unit.TRUCE_META) and n2.has_meta(Unit.TRUCE_META), "withdraw: the seat's own units at peace")
		_v["seat_a"] = s1
		_v["seat_b"] = s2
		_v["leaver"] = w1
		_v["allies"] = [n1, n2]
		_t0 = h.frame
		return false
	if h.frame - _t0 < 300:
		return false
	var s1b: Unit = _v["seat_a"]
	_ok(not Unit.in_truce(s1b, main.get(&"shadow_hero")), "grace over after 1 s")
	var s2b: Unit = _v["seat_b"]
	_ok(StringName(s2b.get_meta(Unit.TRUCE_META, &"")) == &"pact", "grace end gives the 'pact' truce back (%s)"
			% str(s2b.get_meta(Unit.TRUCE_META, &"")))
	var w1b: Variant = _v["leaver"]
	_ok(not is_instance_valid(w1b) or not (w1b as Unit).is_alive(), "withdraw_seat: the unit left the map")
	_ok((main.call(&"seat_nodes", &"leaver") as Array).is_empty(),
			"a tagged seat whose units are gone is empty (no fallback to the team)")
	_ok(_v["allies"].all(func(u: Variant) -> bool: return not is_instance_valid(u) or not (u as Unit).is_alive()),
			"the switched seat's units left the map")
	var hero2: Unit = main.get(&"hero")
	_ok(hero2.is_alive() and hero2.is_in_group("units"), "the player's hero is still here")
	MissionHarness.kill([_v["seat_a"], _v["seat_b"]])
	_ok((main.call(&"seat_nodes", &"turncoat") as Array).is_empty(), "a dead tagged seat never covers its new team")
	return true


func _rt_hero() -> bool:
	if not _v.has("w2"):
		# L1: Unit.truce_count follows the nodes that really carry a truce (units that left the map gave theirs back).
		var carrying := main.find_children("*", "", true, false).filter(func(n: Node) -> bool:
			return n.has_meta(Unit.TRUCE_META)).size()
		_ok(Unit.truce_count == carrying, "truce_count %d = %d nodes in a truce" % [Unit.truce_count, carrying])
		var old: Wizard = main.get(&"hero")
		var w2 := Wizard.new()
		main.call(&"_spawn", w2, Unit.Team.PLAYER, old.global_position + Vector3(2.0, 0.0, 0.0))
		ItemDrops.ensure_inventory(w2)
		main.call(&"set_player_hero", w2)
		_ok(main.get(&"hero") == w2 and main.get(&"selection").get(&"hero") == w2, "set_player_hero re-points")
		MissionHarness.kill([old])
		_v["w2"] = w2
		_t0 = h.frame
		return false
	if h.frame - _t0 == 240:
		_ok(h.ended == -1, "the old hero's death is no longer a defeat")
		MissionHarness.kill([_v["w2"]])
	if h.frame - _t0 > 240 and h.ended == 0:
		_ok(h.frame - _t0 >= 240 + 170, "defeat after the 3 s delay (%d frames)" % (h.frame - _t0 - 240))
		return true
	return false


# ---------------------------------------------------------------- keep lost

func _keep_lost() -> bool:
	if not _v.has("killed"):
		_v["killed"] = true
		(main.get(&"keep") as Keep).take_damage(1.0e7, null)
		return false
	if h.ended == 0:
		_ok(bool(main.call(&"is_ending")), "is_ending")
		return true
	return false


# ---------------------------------------------------------------- the first ending is final (H2)

func _ending_first_wins() -> bool:
	if not _v.has("lost"):
		_v["lost"] = true
		main.call(&"lose", 3.0)   # the instant-loss shape: defeat pending for 3 s
		_t0 = h.frame
		return false
	if h.frame - _t0 == 1:
		main.call(&"win", 0.0)    # a later scripted victory (a `destroyed` handler) must not replace it
		_ok(h.ended == -1, "win(0) after lose(3) did nothing (ended %d)" % h.ended)
	if h.ended < 0:
		return false
	_ok(h.ended == 0, "the pending defeat stands (ended %d)" % h.ended)
	_ok(h.frame - _t0 >= 170, "defeat after its 3 s delay (%d frames)" % (h.frame - _t0))
	var cs := CampaignState.open(SAVE_END)
	_ok(not cs.is_completed(&"m_skeleton") and cs.loaded_from == "", "no victory save written")
	cs.reset()
	return true


# ---------------------------------------------------------------- no player keep (M4)

## A mission whose map has no player keep (hero-only phase): the keep-lost rule never arms.
class NoKeepMission extends MissionSkeleton:
	func _on_navigation_ready() -> void:
		keep = null
		super()


func _no_keep() -> bool:
	if not _v.has("t"):
		_v["t"] = h.frame
		return false
	if h.frame - int(_v["t"]) < 150:   # 2.5 s: five keep checks
		return false
	_ok(h.ended == -1 and not bool(main.call(&"is_ending")), "no player keep: no 'keep has fallen' defeat (ended %d)" % h.ended)
	return true


# ---------------------------------------------------------------- CampaignState alone

func _campaign_static() -> void:
	var path := "user://test_mission_framework_static.json"
	var cs := CampaignState.open(path)
	cs.reset()
	cs.set_flags({"count": 3, "yes": true, "f": 2.0})
	cs.save()
	var back := CampaignState.open(path)
	_ok(back.flag_value("count") is int and int(back.flag_value("count")) == 3 and back.flag("yes")
			and int(back.flag_value("f")) == 2, "int flags round-trip %s" % str(back.flags))
	CampaignState.registered_rewards[&"x_test"] = {"set_flags": {"x_done": true}, "unlock": [&"x_a", &"x_b"],
			"save_items": false, "next": &""}
	var level := Node.new()
	back.items = {"essence": 77}
	_ok(back.on_mission_victory(&"x_test", level) == OK, "save")
	_ok(back.flag("x_done") and back.unlocked.has(&"x_a") and back.unlocked.has(&"x_b")
			and int(back.items.get("essence", 0)) == 77 and back.is_completed(&"x_test"),
			"registered reward / unlock / save_items false (%s, %s)" % [str(back.flags), str(back.unlocked)])
	_ok(str(CampaignState.reward_of(&"m01").get("artifact", "")) == "ember_crown", "MISSION_REWARDS m01 still first")
	CampaignState.registered_rewards.erase(&"x_test")
	level.free()
	back.reset()
	# L4: a String flag value no longer breaks the save (bool(String) does not exist in Godot 4).
	back.set_flags({"s_yes": "true", "s_no": "nope", "sn": &"1"})
	_ok(back.flag("s_yes") and not back.flag("s_no") and back.flag("sn"), "String flags cleaned to bools %s" % str(back.flags))
	back.reset()
	# M7: track counters per mission; the per-mission table survives a save / load.
	back.add_track("m_a", {"uses": 2})
	back.add_track("m_a", {"uses": 2})
	back.add_track("m_b", {"uses": 3})
	_ok(int(back.flag_value("uses", 0)) == 5, "track: m_a twice + m_b = %s (not 7)" % str(back.flag_value("uses")))
	back.save()
	var again := CampaignState.open(path)
	again.add_track("m_a", {"uses": 1})
	_ok(int(again.flag_value("uses", 0)) == 4, "track after load: m_a replay with 1 -> %s" % str(again.flag_value("uses")))
	again.reset()
	_campaign_crash_safe()


## M1: the save survives a crash mid-write: tmp + rename, the previous save kept as .bak, an unreadable main file
## is never taken for a new campaign (the .bak loads instead and the bad file is kept as .corrupt).
func _campaign_crash_safe() -> void:
	var path := "user://test_mission_framework_crash.json"
	var cs := CampaignState.open(path)
	cs.reset()
	_ok(cs.loaded_from == "", "no save: new campaign")
	cs.set_flags({"step": 1}, true)
	cs.completed.append(&"m01")
	cs.set_flags({"step": 2}, true)
	_ok(FileAccess.file_exists(path) and FileAccess.file_exists(path + CampaignState.BACKUP_SUFFIX)
			and not FileAccess.file_exists(path + CampaignState.TMP_SUFFIX), "save: main + .bak, no .tmp left")
	var ok := CampaignState.open(path)
	_ok(ok.loaded_from == path and int(ok.flag_value("step", 0)) == 2 and ok.is_completed(&"m01"), "main save loads (step 2)")
	# The power cut: the main file is truncated mid-write.
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string('{\n\t"version": 1,\n\t"unlocked": ["m01", "m0')
	f.close()
	var back := CampaignState.open(path)
	_ok(back.loaded_from == path + CampaignState.BACKUP_SUFFIX and int(back.flag_value("step", 0)) == 1,
			"cut save: the backup loads (step %s from '%s'), not a new campaign" % [str(back.flag_value("step")), back.loaded_from])
	_ok(FileAccess.file_exists(path + CampaignState.CORRUPT_SUFFIX), "the cut file is kept as .corrupt")
	# The next save repairs the main file and does not replace the good backup with the cut one.
	back.set_flags({"step": 3}, true)
	var fixed := CampaignState.open(path)
	_ok(fixed.loaded_from == path and int(fixed.flag_value("step", 0)) == 3, "next save repairs the main file")
	var bak := CampaignState.new()
	bak.path = path + CampaignState.BACKUP_SUFFIX
	bak.load()
	_ok(int(bak.flag_value("step", 0)) == 1, "the backup is still the last good save (step %s)" % str(bak.flag_value("step")))
	# Crash between the two renames: no main file, only the .bak.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var lost := CampaignState.open(path)
	_ok(lost.loaded_from == path + CampaignState.BACKUP_SUFFIX, "main file missing: the backup loads")
	cs.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + CampaignState.CORRUPT_SUFFIX))
