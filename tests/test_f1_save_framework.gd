extends SceneTree
## Fix batch F1 (docs/handoff/fix-batches-2026-10-12.md, mission-save-hardening-2026-10-12.md A / B): a mission save
## made after mid-mission changes, loaded into a freshly built mission whose start redoes the old state. Checks:
## - a unit the start puts to sleep and the mission woke comes back awake (meta reconcile, B1);
## - a truce lifted mid-mission stays lifted, a kept truce stays, Unit.truce_count is right (R5-2b);
## - the hero switched mid-mission is the hero again (C1-2), hidden resources stay hidden;
## - a unit of a code-made (local) type spawned mid-mission comes back with its type (B4) and save_spawned runs;
## - an after() timer with bound arguments is saved and fires after the load (B5);
## - an actor row (register_actor) and a generic saved_state node get their state back;
## - the MissionHud is attached after the load without a briefing (B3), the tree is not paused;
## - a win(delay) still ends the mission while the world is held (C1-7).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_f1_save_framework.gd --fixed-fps 60 --quit-after 9000
## Prints "PASS f1_save_framework" or "FAIL f1_save_framework: <reasons>".

const TASK_ID := "f1_save_framework"
const TIMEOUT_FRAMES := 8000
const LOCAL_ID := "f1_brute"
const CROWN_POS := Vector3(20.0, 0.0, 20.0)
const ALLY_KEEP_POS := Vector3(-30.0, 0.0, -30.0)


## A prop the save does not rebuild: its state travels as an actor row.
class F1Actor extends Node3D:
	var lit := false

	func save_row() -> Array:
		return [lit]

	func load_row(row: Array) -> void:
		lit = bool(row[0]) if row.size() > 0 else lit


## A generic saved_state node (group "saved_state").
class F1State extends Node:
	var counter := 0

	func _ready() -> void:
		add_to_group(&"saved_state")

	func save_key() -> String:
		return "f1_state"

	func save_state() -> Dictionary:
		return {"counter": counter}

	func load_state(d: Dictionary, _nodes: Dictionary) -> void:
		counter = int(d.get("counter", 0))


## The skeleton mission plus the start state the checks need.
class F1Mission extends MissionSkeleton:
	# save_spawned records into a meta: the mission's own vars are overwritten by load_state
	var after_load_ran := false
	var f1_actor: F1Actor
	var f1_state: F1State
	var f1_bot: Node

	func _mission_config() -> MissionConfig:
		var c := super()
		c.seat_sides = {Unit.Team.PLAYER: 0, Unit.Team.ALLY: 0, Unit.Team.ENEMY: 1}
		c.seat_opponents = {Unit.Team.ENEMY: Unit.Team.PLAYER, Unit.Team.ALLY: Unit.Team.ENEMY,
				Unit.Team.PLAYER: Unit.Team.ENEMY}
		c.spotlight = {"id": &"flame_guard", "trigger": &"manual", "card": "F1 card"}
		return c

	func _on_navigation_ready() -> void:
		var base := UnitType.find("flame_guard")
		var t := base.duplicate() as UnitType
		t.id = StringName(LOCAL_ID)
		t.display_name = "F1 Brute"
		register_local_unit_type(t)
		super()
		var sleeper := spawn_group([["flame_guard", 1]], Vector3(12.0, 0.0, -12.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		sleeper.name = "F1Sleeper"
		set_dormant(sleeper, true)
		var a := spawn_group([["flame_guard", 1]], Vector3(-6.0, 0.0, 14.0), 0.0, Unit.Team.PLAYER, false)[0] as Unit
		a.name = "F1TruceA"
		var b := spawn_group([["flame_guard", 1]], Vector3(-6.0, 0.0, 30.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		b.name = "F1TruceB"
		var c := spawn_group([["flame_guard", 1]], Vector3(6.0, 0.0, 14.0), 0.0, Unit.Team.PLAYER, false)[0] as Unit
		c.name = "F1KeepC"
		var d := spawn_group([["flame_guard", 1]], Vector3(6.0, 0.0, 30.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		d.name = "F1KeepD"
		set_truce([a, b], true, &"f1")
		set_truce([c, d], true, &"f1_keep")
		var second := _make_wizard(Unit.Team.PLAYER)
		second.name = "F1Second"
		_spawn(second, Unit.Team.PLAYER, PLAYER_START + Vector3(4.0, 0.0, 4.0))
		f1_actor = F1Actor.new()
		add_child(f1_actor)
		register_actor("f1_actor", f1_actor)
		f1_bot = _add_commander(Unit.Team.ENEMY, &"easy")   # a real saved_state node (key commander:1, ids passed)
		f1_state = F1State.new()
		add_child(f1_state)
		var napper := spawn_group([["flame_guard", 1]], Vector3(18.0, 0.0, -12.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		napper.name = "F1Napper"
		var turncoat := spawn_group([["flame_guard", 1]], Vector3(24.0, 0.0, -12.0), 0.0, Unit.Team.ENEMY, false)[0] as Unit
		turncoat.name = "F1Turncoat"
		tag_seat(turncoat, &"f1_turn")
		add_seat(&"f1_turn", Unit.Team.ENEMY)
		add_seat(&"f1_bot_seat", Unit.Team.ENEMY, f1_bot)
		crown = EmberCrown.new()
		crown.name = "EmberCrown"
		crown.seal_time = 1.0e12   # sealed until the mission breaks it (mission 1's braziers)
		crown.match_time_source = match_time
		add_child(crown)
		crown.global_position = CROWN_POS

	func save_spawned(u: Unit, _row: Dictionary) -> void:
		set_meta(&"_f1_spawned", String(get_meta(&"_f1_spawned", "")) + "|" + (String(u.unit_type.id) if u.unit_type else ""))

	func _after_load(_nodes: Dictionary) -> void:
		after_load_ran = save_restoring


var level: MissionBase
var step := "start"
var frames := 0
var total := 0
var data: Dictionary = {}
var restorer_done := false
var restorer_ok := false
var fails: Array[String] = []


func _initialize() -> void:
	level = _new_mission()
	root.add_child(level)
	current_scene = level


func _new_mission() -> MissionBase:
	var m := F1Mission.new()
	m.show_briefing = false
	m.save_campaign_on_victory = false
	m.cinematics_enabled = false
	m.mission_difficulty = 1
	return m


func _process(_delta: float) -> bool:
	total += 1
	frames += 1
	if total > TIMEOUT_FRAMES:
		fails.append("timed out at step %s" % step)
		return _finish()
	if level and level.hero and is_instance_valid(level.hero) and level.hero.is_alive():
		level.hero.heal(1.0e6)
	match step:
		"start":
			if level.hero != null and level.match_started and frames > 120:
				_mid_mission()
				_goto("save")
		"save":
			if frames >= 30:
				var why := SaveGame.block_reason(level)
				if why != "":
					fails.append("save refused: %s" % why)
					return _finish()
				data = SaveGame.capture(level)
				_reload()
				_goto("wait")
		"wait":
			if restorer_done:
				if not restorer_ok:
					fails.append("the restorer failed")
					return _finish()
				_check_load()
				MissionHarness.skip_time(level, 40.0)
				_goto("timer")
		"timer":
			if frames >= 150:   # the Commander applies a load on its first tick
				fails.append_array(_expect(level.objective_state("sec_bonus") == "done",
						"the bound timer did not fire after the load (sec_bonus %s)" % level.objective_state("sec_bonus")))
				var states: Array = (data.get("world", {}) as Dictionary).get("saved_states", [])
				fails.append_array(_expect(states.any(func(r: Dictionary) -> bool: return r.get("key") == "commander:1"),
						"no saved_state row for the Commander (commander:1)"))
				var bot: Node = (level as F1Mission).f1_bot
				fails.append_array(_expect(bot != null and int(bot.get(&"attacks_launched")) >= 3,
						"the Commander's attacks_launched was not restored (%s)" % (bot.get(&"attacks_launched") if bot else "no bot")))
				_crown_wizard = _other_player_wizard()
				if _crown_wizard == null:
					fails.append("no second player wizard for the crown check")
					return _finish()
				MissionHarness.put(_crown_wizard, CROWN_POS)
				_goto("crown_claim")
		"crown_claim":   # C1-9: the wearer leaves the map without dying: the crown drops
			var crown: EmberCrown = level.get(&"crown")
			if crown.is_worn():
				_crown_wizard.leave_map()
				_goto("crown_drop")
			elif frames > 180:
				fails.append("the unsealed crown was not claimed after the load")
				return _finish()
		"crown_drop":
			var crown: EmberCrown = level.get(&"crown")
			if crown.is_available():
				level.hold_world(true)
				level.win(1.0)
				_goto("hold_end")
			elif frames > 600:
				fails.append("the crown stayed on a wearer that left the map (C1-9)")
				return _finish()
		"hold_end":
			if level.game_over:
				return _finish()
			if frames > 240:
				fails.append("win(1.0) never ended the mission while the world was held (C1-7)")
				return _finish()
	return false


func _goto(s: String) -> void:
	step = s
	frames = 0


## The mid-mission changes the save must carry.
func _mid_mission() -> void:
	var m := level as F1Mission
	m.set_dormant(_unit("F1Sleeper"), false)
	m.set_truce([_unit("F1TruceA"), _unit("F1TruceB")], false, &"f1")
	m.set_player_hero(_unit("F1Second") as Wizard)
	m.set_resources_hidden(true)
	m.spawn_wave_at([[LOCAL_ID, 1]], Vector3(14.0, 0.0, 14.0), Unit.Team.ENEMY)
	m.after(30.0, m.set_objective.bind(&"sec_bonus", "done"))
	m.f1_actor.lit = true
	m.f1_state.counter = 7
	if m.f1_bot and &"attacks_launched" in m.f1_bot:
		m.f1_bot.set(&"attacks_launched", 3)
	# X1: put to sleep mid-mission (the rebuilt start has it awake)
	m.set_dormant(_unit("F1Napper"), true)
	# C1-6: a seat switched, a seat's Commander paused, a seat activated mid-mission
	m.switch_seat_side(&"f1_turn", Unit.Team.PLAYER, 0.0)
	m.f1_bot.set(&"enabled", false)
	var out := m.activate_seat(Unit.Team.ALLY, &"nature", {"keep": {"type": "nature_keep", "pos": ALLY_KEEP_POS},
			"crystals": 123, "profile": &"easy"})
	if out["keep"] == null:
		fails.append("activate_seat made no keep")
	# C1-8: the manual spotlight rang nothing before it was shown; shown now, it rings an existing Flame Guard
	if m.spotlight_unit != null:
		fails.append("the spotlight ring fired before show_spotlight (manual trigger)")
	m.show_spotlight()
	if m.spotlight_unit == null:
		fails.append("show_spotlight found no Flame Guard to ring")
	# C2-4: the mission breaks the crown's seal
	m.crown.seal_time = 0.0
	if Unit.truce_count != 2:
		fails.append("before the save truce_count is %d, not 2" % Unit.truce_count)


## What SaveGame.instantiate_level does, for a mission script made in this test (an inner class has no path).
func _reload() -> void:
	root.remove_child(level)
	level.queue_free()
	level = _new_mission()
	level.show_briefing = true   # a real game: the load attaches the MissionHud without its briefing
	var restorer: Node = (load(SaveGame.RESTORER_SCRIPT) as Script).new()
	restorer.name = SaveGame.RESTORER_NAME
	restorer.set(&"data", data)
	restorer.call(&"prepare", level)
	restorer.set(&"_restore_cinematics", false)
	level.add_child(restorer)
	restorer.connect(&"finished", func(ok: bool) -> void:
		restorer_done = true
		restorer_ok = ok)
	root.add_child(level)
	current_scene = level


func _check_load() -> void:
	var m := level as F1Mission
	var sleeper := _unit("F1Sleeper")
	fails.append_array(_expect(sleeper != null and not m.is_dormant(sleeper) and sleeper.is_in_group(&"units")
			and not sleeper.has_meta(MissionBase.META_AGGRO), "the woken unit is asleep again after the load"))
	var a := _unit("F1TruceA")
	var c := _unit("F1KeepC")
	fails.append_array(_expect(a != null and not a.has_meta(Unit.TRUCE_META), "the lifted truce came back"))
	fails.append_array(_expect(c != null and StringName(c.get_meta(Unit.TRUCE_META, &"")) == &"f1_keep",
			"the kept truce was lost"))
	fails.append_array(_expect(Unit.truce_count == 2, "truce_count is %d after the load, not 2" % Unit.truce_count))
	fails.append_array(_expect(c != null and c.has_meta(MissionBase.META_TRUCE_HOOK), "the kept truce node is not hooked"))
	fails.append_array(_expect(m.hero != null and String(m.hero.name) == "F1Second", "the hero switch was lost (%s)"
			% (m.hero.name if m.hero else "null")))
	fails.append_array(_expect(bool(m.get(&"_resources_hidden")), "hidden resources came back shown"))
	var brutes := 0
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.unit_type and String(u.unit_type.id) == LOCAL_ID:
			brutes += 1
	fails.append_array(_expect(brutes == 1, "%d units of the local type after the load, not 1" % brutes))
	fails.append_array(_expect(String(m.get_meta(&"_f1_spawned", "")).contains(LOCAL_ID), "save_spawned was not called for the local unit"))
	fails.append_array(_expect(m.f1_actor.lit, "the actor row was not loaded"))
	fails.append_array(_expect(m.f1_state.counter == 7, "the saved_state node got %d, not 7" % m.f1_state.counter))
	fails.append_array(_expect(m.after_load_ran, "_after_load did not run while save_restoring"))
	fails.append_array(_expect(m.mission_hud != null and is_instance_valid(m.mission_hud), "no MissionHud after the load"))
	fails.append_array(_expect(not m.wait_for_briefing and not paused, "the load waits on a briefing / paused the tree"))
	var napper := _unit("F1Napper")
	fails.append_array(_expect(napper != null and m.is_dormant(napper) and napper.has_meta(MissionBase.META_ASLEEP)
			and not napper.is_in_group(&"units") and napper.death_guard.is_valid(),
			"the unit asleep in the save is not really asleep after the load (X1)"))
	var turncoat := _unit("F1Turncoat")
	fails.append_array(_expect(m.seat_team(&"f1_turn") == Unit.Team.PLAYER and turncoat != null
			and int(turncoat.team) == Unit.Team.PLAYER, "the switched seat came back on its old side (C1-6)"))
	fails.append_array(_expect(m.f1_bot != null and not bool(m.f1_bot.get(&"enabled")),
			"the paused seat Commander is enabled again (C1-6)"))
	if m.f1_bot:
		m.f1_bot.set(&"enabled", true)   # a Commander applies a pending load on its first tick (needs enabled)
	var ally_eco := Economy.for_team(Unit.Team.ALLY)
	var ally_bot := false
	for bot_node in m.commanders:
		if is_instance_valid(bot_node) and int(bot_node.get(&"team")) == Unit.Team.ALLY:
			ally_bot = true
	var ally_keep: Variant = m.seat_keeps.get(Unit.Team.ALLY)
	fails.append_array(_expect(ally_eco != null and ally_eco.crystals == 123 and ally_bot and ally_keep is Keep
			and is_instance_valid(ally_keep) and m.seat_kingdoms.get(Unit.Team.ALLY) == &"nature",
			"the seat activated mid-mission lost its Economy / crystals / Commander / keep (C1-6: eco %s, bot %s, keep %s)"
			% [ally_eco.crystals if ally_eco else -1, ally_bot, ally_keep]))
	fails.append_array(_expect(m.spotlight_id == &"flame_guard" and bool(m.get(&"_spotlight_ring_done"))
			and m.spotlight_unit == null and level.find_child("SpotlightRing", true, false) == null,
			"the spotlight rang again on a rebuilt unit / lost its state (C1-8)"))
	fails.append_array(_expect(m.crown != null and m.crown.seal_time == 0.0 and not m.crown.is_sealed(),
			"the crown's broken seal came back (C2-4)"))
	var bound := false
	for t: Array in m.get(&"_timers"):
		var cb := t[1] as Callable
		if cb.get_method() == &"set_objective" and cb.get_bound_arguments().size() == 2:
			bound = true
	fails.append_array(_expect(bound, "the bound timer was not restored"))


var _crown_wizard: Unit


## A living PLAYER wizard that is not the current hero (the start's Vessa after the hero switch).
func _other_player_wizard() -> Unit:
	for n in get_nodes_in_group(&"heroes"):
		var w := n as Wizard
		if w and w.is_alive() and int(w.team) == Unit.Team.PLAYER and w != level.hero:
			return w
	return null


func _unit(unit_name: String) -> Unit:
	return level.find_child(unit_name, true, false) as Unit if level else null


func _expect(cond: bool, what: String) -> Array[String]:
	var out: Array[String] = []
	if not cond:
		out.append(what)
	return out


func _finish() -> bool:
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	return true
