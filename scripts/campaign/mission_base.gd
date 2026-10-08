class_name MissionBase
extends Skirmish
## The shared base of every campaign mission (docs/design/mission-framework.md = the API summary and a skeleton).
## Extracted from Mission01 (M9.S1, mission-02.md "Code reuse") with no behaviour change for mission 1.
## A mission script `extends MissionBase`, fills the overridable tables in `_init` (after `super()`), returns its
## knobs from `_mission_config()` (or the scene sets `config` to a MissionConfig `.tres`), builds its map in
## `_build_map()`, spawns its start state in `_on_navigation_ready()` and ends that with `begin_mission(...)`.
##
## What it gives:
## - Objectives: `define_objectives`, `set_objective(id, state)` (Events.objective_changed), `objective_state`,
##   `objectives()` (MissionHud rows), `briefing()`, `primaries_done()`.
## - Events: `fire_once(id)` / `has_fired(id)` and a declarative E-list (`add_event(id, condition, action)`, checked
##   every EVENT_TICK s in order); `after(seconds, callable)` timers on `mission_time()`.
## - Clock: `mission_time()` = match time minus the time held by `hold_world(true, actors)` (cinematics.md HOLD).
## - Dialogue: `say(speaker, text)` / `say_line(n)` (Events.dialogue + `dialogue_said`), `dialogue_log`.
## - Cinematics: `play_cutscene(id, end_state)`: plays data/cinematics/<id>.tres when it exists and cinematics are on,
##   then runs `end_state` once (played, skipped or missing = the direct-effect fallback, the 19.C9 skip rule).
## - End: `win(delay)`, `lose(delay)`, `_end_game` (campaign save on victory through CampaignState, banners), the
##   keep-lost and instant-loss rules of the config.
## - Difficulty: `mission_difficulty` 0-2, `scaled(n, type_id)`, `by_difficulty(values)`.
## - Spawning: `spawn_group` (scripted, ring, hold the spot), `mark_scripted`, `set_dormant`, guards that walk home,
##   waves (`spawn_wave_at`, `order_wave`, refreshed every REFRESH_INTERVAL s), `raise_wizard`.
## - Knobs (MissionConfig): tiers / casters / T3 / helpers / titans switches, start tiers, helper price and start
##   call, level cap / start level / spell points / spells, start crystals / essence / pop, hidden resources,
##   no-economy mode, forced artifact slots, the bot profile; runtime: `set_player_hero`, `lock_base`,
##   `set_truce`, seats (`add_seat`, `switch_seat_side`, `withdraw_seat`), mission-computed campaign flags
##   (`set_mission_flag`, `add_track_counter`), `scene_knob` for kits that read the mission node.
## Tests: set `show_briefing`, `save_campaign_on_victory` and `cinematics_enabled` false before the node enters the
## tree (tests/helpers/mission_harness.gd does it).

signal objectives_changed                                  ## Any objective state / counter changed.
signal dialogue_said(speaker: StringName, text: String)    ## Same as Events.dialogue (for tests).
signal event_fired(id: StringName)                         ## fire_once / the E-list fired an event.
signal world_held(on: bool)                                ## hold_world changed.
signal seat_switched(seat: StringName, team: int)
signal seat_withdrawn(seat: StringName)
signal spotlight_shown(id: StringName, card: String)       ## Same as Events.spotlight_shown (for tests).
signal spotlight_first_unit(unit: Unit)                    ## The first PLAYER unit of the spotlit type appeared.

const SCRIPTED_GROUP := &"scripted"
const EVENT_TICK := 1.0             ## The E-list and the guards are checked once per second.
const REFRESH_INTERVAL := 3.0       ## Waves re-aim this often.
const GUARD_HOME_TOLERANCE := 3.0
const DIALOGUE_SECONDS := 5.0
const SEAT_META := &"mission_seat"
const META_HOME := &"mission_home"
const META_MODE := &"mission_mode"
const META_TARGET := &"mission_target"
const META_DORMANT := &"mission_dormant"
const META_AGGRO := &"mission_aggro"
const META_HELD := &"mission_held"            ## Asleep because of hold_world (not the mission): the release wakes it.
const META_GUARD := &"mission_prev_guard"     ## The death_guard a unit had before set_dormant (Rekindle...).
const META_TRUCE_PREV := &"mission_truce_prev"   ## The truce id a seat node had before its switch grace.
const META_TRUCE_HOOK := &"mission_truce_hook"   ## tree_exiting is wired to clear its truce (Unit.truce_count).
const DEFAULT_SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"malrik": Color(0.7, 0.3, 1.0),
	&"narrator": Color(0.9, 0.85, 0.7),
}

## Set before the node enters the tree (menu / tests): 0 easy, 1 normal, 2 hard.
@export_range(0, 2) var mission_difficulty := 1
## The mission's knobs. Null = `_mission_config()` (code); a scene may set a `.tres` here instead.
@export var config: MissionConfig

# ---- Overridable tables (fill them in the mission's _init after super()).
var mission_id: StringName = &""
var mission_title := ""
var objective_order: Array[StringName] = []
var dialogue_lines: Array = []                  ## [[speaker, text], ...] (line n = index n - 1)
var speaker_colors: Dictionary = DEFAULT_SPEAKER_COLORS.duplicate()
var speaker_names: Dictionary = {}
var briefing_paragraphs: Array[String] = []

# ---- Knobs the kits read from the current scene (copied from the config; tests may change them before _ready).
## CasterKit.enabled_here reads it: the keep lists the kingdom's caster.
var casters_enabled := false
## T3Kit.enabled_here reads it: the Citadel keep lists the kingdom's tier-3 unit.
var t3_enabled := false
## T3Kit.helpers_here reads it: the keep lists the helper call / revive.
var helpers_enabled := false
## Read by the titan kit when it exists (scene_knob).
var titans_enabled := false
var lair_max := -1
var titan_max_trained := -1
var lair_min_time := -1.0
## ForgeKit.enabled_here reads it in a mission (config.forge_enabled).
var forge_enabled := false
## Stables16.enabled_here reads it in a mission (config.cavalry_enabled).
var cavalry_enabled := false

# ---- Test / menu switches.
## True: MissionHud (scripts/ui/mission/) is attached with its briefing, which pauses the game; its `begun` signal
## calls briefing_done(). Tests set it false before the node enters the tree (no MissionHud, the intro at once).
var show_briefing := true
var wait_for_briefing := false               ## True while the intro waits for briefing_done().
var mission_hud: Node = null                 ## Read only: the MissionHud (null in tests).
## Tests turn this off so they don't overwrite the player's campaign save.
var save_campaign_on_victory := true
var campaign_save_path := CampaignState.SAVE_PATH
## False: play_cutscene runs the end state at once (headless tests, the 19.C9 skip check).
var cinematics_enabled := true
## Mid-mission saves (docs/design/save-load.md): false = this mission refuses them ("not supported"). A mission whose
## state the default save_state / load_state cannot carry overrides them (calling super) or sets this false.
var save_supported := true
## True while a save is being loaded into this freshly built mission (SaveGame sets it before the tree): no briefing,
## no film, no dialogue card; the saved state replaces what the rebuilt start did.
var save_restoring := false
## Timer tags (after()): TIMER_START while the mission starts, TIMER_INTRO inside `_intro()`, &"" after.
const TIMER_START := &"start"
const TIMER_INTRO := &"intro"
var _timer_tag: StringName = TIMER_START
var _intro_at := 0.0               # mission time the intro ran (a briefing can hold it)
## Lines a cinematic just subtitled (text -> speaker), read by say() during that cutscene's end state: the end state
## (the direct-effect fallback) re-says the scene's lines, so a line the player already saw in the film is logged
## (dialogue_log, dialogue_said) but not shown again as a dialogue card.
var _cine_said: Dictionary = {}
## Units marked by set_dormant / spawn_group stay this way; read only.
var dialogue_log: Array[String] = []         ## Read only: "speaker: text" of every line said.
var world_is_held := false                   ## Read only (hold_world).
var commanders: Array[Node] = []             ## Read only: the Commanders this mission added.

var _objs := {}                  # id -> {type, state, text}
var _fired := {}                 # event id -> true
var _events: Array = []          # [id, condition, action, repeat]
var _timers: Array = []          # [mission time, Callable]
var _guards: Array = []          # units that hold a spot (meta META_HOME)
var _wave_units: Array = []      # units under wave orders (meta META_MODE)
var _event_tick := 0.0
var _guard_tick := 0.0
var _refresh_tick := 0.0
var _ending := false
var _capping := false
var _intro_done := false
var _held_total := 0.0
var _held: Dictionary = {}       # Unit -> true: made dormant by hold_world (meta META_HELD)
var _held_bots: Dictionary = {}  # Commander -> its `enabled` before the hold (withdraw_seat updates it)
var _keep_seen := false          # the keep-lost rule is armed once the player had a living keep
var _mission_flags: Dictionary = {}
var _track_adds: Dictionary = {}
var _seats: Dictionary = {}      # seat id -> {team, commander}
var _loss_hero: Wizard
var _applied_config: MissionConfig
var _locked: Array = []          # TrainingBuildings locked by lock_base
## Read only (spotlight, mission-framework.md 7): the spotlit id once shown, whether it was the short replay card,
## and the first PLAYER unit of that type (null until it appears).
var spotlight_id: StringName = &""
var spotlight_short := false
var spotlight_unit: Unit = null
var _spotlight_watch := false


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	config = _mission_config()
	_apply_switches(config)


func _ready() -> void:
	if config == null:
		config = MissionConfig.new()
	if config != _applied_config:   # a scene / test gave another config
		_apply_switches(config)
	Unit.truce_count = 0   # static: a truce of the previous scene (F9, mission to mission) must not survive it
	super()
	if tier_system:
		tier_system.max_tier = config.max_tier
		tier_system.bots_upgrade = config.bots_upgrade
		for team: Variant in config.start_tiers:
			tier_system.set_start_tier(int(team), int(config.start_tiers[team]))
	_apply_economy_start()


## The mission's knobs (override). Default: an empty config (everything off / untouched).
func _mission_config() -> MissionConfig:
	return MissionConfig.new()


## Copies the switches the kits read off the scene (before any building exists).
func _apply_switches(c: MissionConfig) -> void:
	_applied_config = c
	if c == null:
		return
	if c.mission_id != &"":
		mission_id = c.mission_id
	if c.title != "":
		mission_title = c.title
	tiers_enabled = c.tiers_enabled
	casters_enabled = c.casters_enabled
	t3_enabled = c.t3_enabled
	helpers_enabled = c.helpers_enabled
	titans_enabled = c.titans_enabled
	lair_max = c.lair_max
	titan_max_trained = c.titan_max_trained
	lair_min_time = c.lair_min_time
	forge_enabled = c.forge_enabled
	cavalry_enabled = c.cavalry_enabled
	if not c.seat_sides.is_empty():
		seat_sides = c.seat_sides.duplicate()
		seat_opponents = c.seat_opponents.duplicate()
	for k: Variant in c.seat_kingdoms:
		seat_kingdoms[int(k)] = StringName(c.seat_kingdoms[k])


func _apply_economy_start() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	var crystals: Variant = MissionConfig.pick(config.start_crystals, diff)
	if not config.economy_enabled:
		crystals = 0
	if crystals != null and economy:
		economy.crystals = int(crystals)
		economy.changed.emit()
	var enemy_crystals: Variant = MissionConfig.pick(config.enemy_start_crystals, diff)
	var enemy_eco := Economy.for_team(Unit.Team.ENEMY)
	if enemy_crystals != null and enemy_eco:
		enemy_eco.crystals = int(enemy_crystals)
		enemy_eco.changed.emit()
	if config.start_pop_bonus != 0 and economy:
		economy.add_pop_bonus(config.start_pop_bonus)
	var essence := config.start_essence if config.economy_enabled else 0
	if essence >= 0 or not config.essence_trickle or not config.kill_essence or not config.economy_enabled:
		var bank := EssenceBank.for_team(Unit.Team.PLAYER)
		if bank:
			if essence >= 0:
				bank.essence = essence
				bank.changed.emit()
			bank.trickle_enabled = config.essence_trickle and config.economy_enabled
			bank.kill_income_enabled = config.kill_essence and config.economy_enabled


## The intro once the briefing is closed (override; called once).
func _intro() -> void:
	pass


## The UI closed the briefing: the intro (E1).
func briefing_done() -> void:
	wait_for_briefing = false
	if hero != null and match_started:
		_begin_intro()


func _begin_intro() -> void:
	if _intro_done:
		return
	_intro_done = true
	_intro_at = mission_time()
	var tag_before := _timer_tag
	_timer_tag = TIMER_INTRO   # timers set by the intro itself: a load rebuilds them (save-load.md)
	_intro()
	_timer_tag = tag_before


## Call at the end of `_on_navigation_ready()`, once the start state is spawned: the hero knobs, the HUD, the match
## clock, the Commander (config.bot_profile_id), the objectives in `initial` turned active (in that order), the
## MissionHud with its briefing, the helper / artifact knobs, then the intro unless the briefing holds it.
func begin_mission(initial: Array = []) -> void:
	if keep != null and is_instance_valid(keep) and keep.is_alive():
		_keep_seen = true   # arms the keep-lost rule (config.defeat_on_keep_lost)
	_apply_hero_start()
	_setup_hud()
	_start_match()
	if config.bot_profile_id != &"":
		_add_commander()
	for id: Variant in initial:
		set_objective(StringName(id), "active")
	_apply_late_knobs()
	_attach_mission_hud()
	_watch_spotlight()
	if spotlight_trigger() == &"start":
		show_spotlight()
	if not wait_for_briefing:
		_begin_intro()


## Level cap / start level / spell points / spells of the player's wizard, the instant-loss rule.
func _apply_hero_start() -> void:
	if hero == null:
		return
	if config.start_level > 1:
		raise_wizard(hero, config.start_level, [])
	for id in config.start_spells:
		hero.learn_spell(id)
	if config.start_spell_points >= 0 and hero.spell_points != config.start_spell_points:
		hero.spell_points = config.start_spell_points
		hero.spell_points_changed.emit(hero.spell_points)
	_cap_level(hero)
	_watch_loss_hero(hero)


## The level cap on `w`: Wizard.level_cap (no level past it, even from one big XP grant) and mission 1's rule (XP
## that still arrives at the cap is dropped, the bar reads full).
func _cap_level(w: Wizard) -> void:
	if config.level_cap <= 0 or w == null:
		return
	if &"level_cap" in w:
		w.set(&"level_cap", config.level_cap)
	if w.has_signal(&"xp_changed") and not w.xp_changed.is_connected(_on_hero_xp_changed):
		w.xp_changed.connect(_on_hero_xp_changed)


func _apply_late_knobs() -> void:
	if config.resources_hidden or not config.economy_enabled:
		set_resources_hidden(true)
	if not config.helper_call_price.is_empty() or config.helper_start_called:
		var roster := HelperRoster.for_team(Unit.Team.PLAYER)
		if roster:
			var price := {}
			for k: Variant in config.helper_call_price:
				var v: Variant = config.helper_call_price[k]
				price[k] = MissionConfig.pick(v, mission_difficulty) if v is Array else v
			if not price.is_empty():
				roster.set_call_price(price)
			if config.helper_start_called:
				roster.grant()
	if not config.forced_artifacts.is_empty() and hero:
		force_artifacts(hero, config.forced_artifacts)


## MissionHud.attach(self, self, hud): objectives panel, dialogue box and the briefing (pauses the game until Begin;
## `begun` starts the intro).
func _attach_mission_hud() -> void:
	var path := "res://scripts/ui/mission/mission_hud.gd"
	if not show_briefing or not ResourceLoader.exists(path):
		return
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return
	mission_hud = script.call(&"attach", self, self, hud) as Node
	if mission_hud and mission_hud.has_signal(&"begun"):
		wait_for_briefing = true
		mission_hud.connect(&"begun", briefing_done)


## The Commander of config.bot_team with profile config.bot_profile_id (AIProfile); without the profile in
## AIProfile: easy knobs that never attack. Returns it (null without scripts/ai/commander.gd).
func _add_commander(team: int = -1, profile_id: StringName = &"") -> Node:
	if team < 0:
		team = config.bot_team
	if profile_id == &"":
		profile_id = config.bot_profile_id
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var bot: Node = script.new()
	bot.name = "ShadowBot" if team == Unit.Team.ENEMY else "Bot%d" % team
	bot.set(&"team", team)
	if &"profile_id" in bot:
		bot.set(&"profile_id", profile_id)
	else:
		var prof := _mission_profile(profile_id)
		if prof and &"profile" in bot:
			bot.set(&"profile", prof)
	add_child(bot)
	commanders.append(bot)
	return bot


## AIProfile.<profile_id>() when the ai-coder added it, else easy knobs that never attack.
func _mission_profile(profile_id: StringName) -> Resource:
	var script := load("res://scripts/ai/ai_profile.gd") as Script
	if script == null:
		return null
	for m in script.get_script_method_list():
		if StringName(m["name"]) == profile_id:
			return script.call(profile_id) as Resource
	var p: Resource = script.call(&"easy")
	p.set(&"id", profile_id)
	p.set(&"min_attack_pop", 99)
	p.set(&"worker_target_home", 4)
	p.set(&"worker_target_expanded", 4)
	p.set(&"second_expansion", false)
	p.set(&"malrik_joins", 0)
	return p


# ---------------------------------------------------------------- objectives

## Declares the objectives in panel order: [[id, "primary" | "secondary"], ...] or [[id, type, text], ...]
## (text optional: else objective_text(id) is overridden by the mission). All start "hidden".
func define_objectives(rows: Array) -> void:
	_objs.clear()
	objective_order.clear()
	for row: Array in rows:
		var id := StringName(row[0])
		objective_order.append(id)
		_objs[id] = {"type": String(row[1]), "state": "hidden", "text": String(row[2]) if row.size() > 2 else ""}


## Every objective, panel order (MissionHud format): {id, text (without the counter), type, primary, state
## ("hidden" / "active" / "done" / "failed"), progress, goal, time_left, counter, countdown} (_objective_extra).
func objectives() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in objective_order:
		var o: Dictionary = _objs[id]
		var row := {
			"id": id,
			"type": o["type"],
			"primary": o["type"] == "primary",
			"text": objective_text(id, false),
			"state": o["state"],
			"progress": 0,
			"goal": 0,
			"time_left": -1.0,
			"counter": "",
			"countdown": -1.0,
		}
		row.merge(_objective_extra(id, o), true)
		out.append(row)
	return out


## Extra row values for objective `id` (override): progress / goal / counter / time_left / countdown, "position(s)".
func _objective_extra(_id: StringName, _o: Dictionary) -> Dictionary:
	return {}


## The objective's line (override for counters): the text given to define_objectives, else the id.
func objective_text(id: StringName, _with_counter := true) -> String:
	var o: Variant = _objs.get(id)
	if o is Dictionary and String((o as Dictionary)["text"]) != "":
		return String((o as Dictionary)["text"])
	return String(id)


## "active" / "done" / "failed", or "" while hidden / unknown (CampaignState reads it).
func objective_state(id: String) -> String:
	var o: Variant = _objs.get(StringName(id))
	if o == null or (o as Dictionary)["state"] == "hidden":
		return ""
	return String((o as Dictionary)["state"])


## Sets the state ("hidden" / "active" / "done" / "failed") and emits Events.objective_changed(id, state) (also for a
## counter change: call it again with "active"). Done / failed objectives never change again.
func set_objective(id: StringName, state: String) -> void:
	var o: Dictionary = _objs[id]
	if o["state"] == "done" or o["state"] == "failed":
		return
	o["state"] = state
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.objective_changed.emit(id, StringName(state))
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())


## True when every primary objective is done.
func primaries_done() -> bool:
	for id in objective_order:
		var o: Dictionary = _objs[id]
		if o["type"] == "primary" and o["state"] != "done":
			return false
	return true


## The briefing screen: {title, paragraphs, objectives (primary texts except the last one), rule (the last
## primary)}. Override for another layout.
func briefing() -> Dictionary:
	var prim: Array = []
	for id in objective_order:
		if _objs[id]["type"] == "primary":
			prim.append(objective_text(id))
	var rule: String = prim.pop_back() if prim.size() > 1 else ""
	return {"title": _title_line(), "paragraphs": briefing_paragraphs.duplicate(), "objectives": prim, "rule": rule}


func _title_line() -> String:
	return mission_title


## The plain HUD objective text (no MissionHud): title + visible objectives with their marks.
func _objective_text() -> String:
	var lines: Array[String] = [_title_line()]
	for id in objective_order:
		var state: String = _objs[id]["state"]
		if state == "hidden":
			continue
		var mark := "[x] " if state == "done" else ("[!] " if state == "failed" else "- ")
		lines.append(mark + objective_text(id))
	return "\n".join(lines)


# ---------------------------------------------------------------- events, timers, clock

## True the first time it is called for `id` (then false): `if fire_once(&"E4"): ...`.
func fire_once(id: StringName) -> bool:
	if _fired.has(id):
		return false
	_fired[id] = true
	event_fired.emit(id)
	return true


func has_fired(id: StringName) -> bool:
	return _fired.has(id)


## Adds an entry to the E-list: every EVENT_TICK s (while the match runs, not held, not ending) `condition.call()`
## is checked in insertion order; true -> `action.call()` and the event counts as fired (once, unless `repeat`).
func add_event(id: StringName, condition: Callable, action: Callable, repeat := false) -> void:
	_events.append([id, condition, action, repeat])


## Runs `c` once `seconds` of mission time have passed (held time does not count).
## A timer set while the mission starts (before its first scripted tick) or by `_intro()` is tagged: a save does not
## write it, the rebuilt mission sets it again at the same mission time (docs/design/save-load.md).
func after(seconds: float, c: Callable) -> void:
	_timers.append([mission_time() + seconds, c, _timer_tag])


## Seconds since the navmesh was ready, minus the time held by hold_world (cinematics.md HOLD).
func mission_time() -> float:
	return match_time() - _held_total


## cinematics.md HOLD: the mission clock stops, every Commander pauses, every living unit that is not in
## `keep_awake` goes dormant (units already dormant for mission reasons stay so after); false restores exactly that.
## The hold is a ceasefire, not a freeze: orders are kept (workers keep gathering / building, armies keep their move
## and attack-move orders, waves their targets) and the release gives each unit back its own death_guard (Rekindle).
## A unit the mission puts to sleep / wakes itself during the hold (set_dormant) is the mission's again: the release
## leaves it alone; a Commander the mission switched (withdraw_seat) during the hold keeps that state.
func hold_world(on: bool, keep_awake: Array = []) -> void:
	if on == world_is_held:
		return
	world_is_held = on
	if on:
		for node in get_tree().get_nodes_in_group("units"):
			var u := node as Unit
			if u == null or not u.is_alive() or keep_awake.has(u) or u.has_meta(META_DORMANT):
				continue
			_sleep(u)
			u.set_meta(META_HELD, true)
			_held[u] = true
		for bot in _all_commanders():
			_held_bots[bot] = bool(bot.get(&"enabled"))
			bot.set(&"enabled", false)
	else:
		for u: Variant in _held:
			if not is_instance_valid(u):
				continue
			var unit := u as Unit
			unit.remove_meta(META_HELD)
			if unit.has_meta(META_DORMANT):
				_wake(unit)   # orders untouched
		_held.clear()
		for bot: Variant in _held_bots:
			if is_instance_valid(bot):
				(bot as Node).set(&"enabled", _held_bots[bot])
		_held_bots.clear()
	world_held.emit(on)


func _all_commanders() -> Array[Node]:
	var out: Array[Node] = []
	for c in commanders:
		if is_instance_valid(c):
			out.append(c)
	for c in get_children():
		if c.get_script() and String((c.get_script() as Script).resource_path).ends_with("ai/commander.gd") \
				and not out.has(c):
			out.append(c)
	return out


func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over:
		return
	if save_restoring:
		return   # a save is being put back: no timer / event of the rebuilt start runs meanwhile
	_timer_tag = &""   # the start is over: later timers are mid-mission ones
	if world_is_held:
		_held_total += delta
		return
	_run_timers(mission_time())
	if game_over or _ending or _events.is_empty():
		return
	_event_tick -= delta
	if _event_tick <= 0.0:
		_event_tick = EVENT_TICK
		_run_events()


func _run_timers(now: float) -> void:
	var i := 0
	while i < _timers.size():
		if now >= float(_timers[i][0]):
			var c: Callable = _timers[i][1]
			_timers.remove_at(i)
			c.call()
		else:
			i += 1


func _run_events() -> void:
	for e: Array in _events.duplicate():
		if game_over or _ending:
			return
		var id: StringName = e[0]
		var repeat: bool = e[3]
		if not repeat and _fired.has(id):
			continue
		if bool((e[1] as Callable).call()):
			if not repeat:
				_fired[id] = true
			event_fired.emit(id)
			(e[2] as Callable).call()


## Guards walk home (every EVENT_TICK s) and waves re-aim (every REFRESH_INTERVAL s). Missions call it from their
## own tick, or rely on it through `tick_scripted(delta)`.
func tick_scripted(delta: float) -> void:
	_guard_tick -= delta
	if _guard_tick <= 0.0:
		_guard_tick = EVENT_TICK
		_tick_guards()
	_refresh_tick -= delta
	if _refresh_tick <= 0.0:
		_refresh_tick = REFRESH_INTERVAL
		_refresh_waves()


# ---------------------------------------------------------------- dialogue, cinematics

## Emits a line through Events.dialogue (the UI queues them, DIALOGUE_SECONDS each) and dialogue_said.
func say(speaker: StringName, text: String) -> void:
	if save_restoring:
		return   # a save is being rebuilt: the start's lines were said before the save
	dialogue_log.append("%s: %s" % [speaker, text])
	if _cine_said.has(text):   # the cutscene that just ended showed it (play_cutscene): no second card
		_cine_said.erase(text)
		dialogue_said.emit(speaker, text)
		return
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"dialogue"):
		events.emit_signal(&"dialogue", speaker, text)
	dialogue_said.emit(speaker, text)


## Says line `n` (1-based) of `dialogue_lines`.
func say_line(n: int) -> void:
	var line: Array = dialogue_lines[n - 1]
	say(StringName(line[0]), String(line[1]))


func speaker_color_of(speaker: StringName) -> Color:
	return speaker_colors.get(speaker, Color.WHITE)


func speaker_name_of(speaker: StringName) -> String:
	return speaker_names.get(speaker, String(speaker).capitalize())


## CinematicPlayer actor lookup for in-mission scenes (mode=pause .cine files): `tag` = a mission property holding a
## living Node3D (`torvald`, `hush`, `vey`, `sexton`...), `hero` = the player's wizard, or the tag of the hero's model
## (`malrik` when the hero wears res://art/units/wizards/malrik.tscn). Null = unknown (the shot keeps its baked camera).
func cinematic_actor(tag: StringName) -> Node3D:
	if tag == &"":
		return null
	if tag != &"hero" and tag in self:
		var v: Variant = get(tag)
		if v is Node3D and is_instance_valid(v) and (v as Node3D).is_inside_tree():
			return v as Node3D
	var h: Variant = get(&"hero") if &"hero" in self else null
	if h is Node3D and is_instance_valid(h):
		if tag == &"hero":
			return h as Node3D
		var mp: Variant = (h as Node).get(&"default_model_path")
		if mp is String and String(mp).get_file().get_basename() == String(tag):
			return h as Node3D
	return null


## Plays the cinematic `id` (data/cinematics/<id>.tres, PAUSE / STAGE) in this mission's context, then calls
## `end_state` once when it finishes, skipped or not. Without the script, with cinematics off (tests) or when the
## player refuses it, `end_state` runs at once: the direct-effect fallback, so a mission is playable without films and
## every skip leaves the same state (19.C9). Returns "" when it plays, else why it did not.
func play_cutscene(id: StringName, end_state: Callable = Callable()) -> String:
	var why := ""
	var script: CinematicScript = CinematicScript.find(id) if cinematics_enabled else null
	if not cinematics_enabled:
		why = "Cinematics off"
	elif script == null:
		why = "No cinematic %s" % id
	else:
		var player := CinematicPlayer.instance(get_tree())
		var shown := {}
		var on_line := func(sp: StringName, text: String) -> void: shown[text] = sp
		if player.has_signal(&"line_started"):
			player.connect(&"line_started", on_line)
		why = player.play(script, self)
		if why == "":
			player.finished.connect(func(_fid: StringName, _skipped: bool) -> void:
				if player.is_connected(&"line_started", on_line):
					player.disconnect(&"line_started", on_line)
				_cine_said = shown
				if end_state.is_valid():
					end_state.call()
				_cine_said = {}, CONNECT_ONE_SHOT)
			return ""
		if player.is_connected(&"line_started", on_line):
			player.disconnect(&"line_started", on_line)
	if end_state.is_valid():
		end_state.call()
	return why


# ---------------------------------------------------------------- end of the mission

## Victory after `delay` seconds of mission time (0 = now). The first ending decided wins: once win / lose (or the
## keep-lost rule) is pending, later calls are ignored, unless `force` (it then replaces the pending one).
func win(delay := 0.0, force := false) -> void:
	_finish(true, delay, force)


## Defeat after `delay` seconds of mission time (0 = now). Same first-ending-is-final rule as win().
func lose(delay := 0.0, force := false) -> void:
	_finish(false, delay, force)


var _end_serial := 0   # bumped by every accepted ending: a replaced pending one does nothing when its timer fires


func _finish(victory: bool, delay: float, force := false) -> void:
	if game_over or (_ending and not force):
		return
	_ending = true
	_end_serial += 1
	var serial := _end_serial
	if delay <= 0.0:
		_end_game(victory)
	else:
		after(delay, func() -> void:
			if serial == _end_serial:
				_end_game(victory))


## True once the mission is ending (win / lose called, or the end game).
func is_ending() -> bool:
	return _ending or game_over


## config.defeat_on_keep_lost: armed once the player has had a living keep (a map without one is never lost here).
func _check_end() -> void:
	if _ending or not config.defeat_on_keep_lost:
		return
	var alive := keep != null and is_instance_valid(keep) and keep.is_alive()
	if alive:
		_keep_seen = true
	if not _keep_seen:
		return
	if not alive:
		_ending = true
		hud.show_message(config.keep_lost_message, 4.0)
		_end_game(false)


func _end_game(victory: bool) -> void:
	if game_over:
		return
	_ending = true
	if victory and save_campaign_on_victory:
		CampaignState.open(campaign_save_path).on_mission_victory(mission_id, self)
	super(victory)
	if victory:
		hud.show_banner(config.victory_banner, Color(1.0, 0.85, 0.3))
		_add_continue_button()
	else:
		hud.show_banner(config.defeat_banner, Color(0.9, 0.3, 0.3))


## Story flow (ep1 4.2): the victory screen's first button starts the next campaign mission (rewards "next"), when
## its scene exists: prologue -> M0 -> M1 -> M2 -> ...
func _add_continue_button() -> void:
	var next_id := StringName(mission_rewards().get("next", &""))
	var film := CampaignState.is_film(next_id)   # a story film first (StoryFilms: ep2_ending -> ep3_opening -> e3m1)
	var target := CampaignState.film_target(next_id) if film else next_id
	var path := CampaignState.mission_scene(target) if target != &"" else ""
	if path == "" or not ResourceLoader.exists(path) or hud == null or hud.end_menu_button == null:
		if not (film and StoryFilms.available(next_id)) or hud == null or hud.end_menu_button == null:
			return
	var row := hud.end_menu_button.get_parent()
	if row == null or row.has_node(^"ContinueNext"):
		return
	var next := Button.new()   # the end screen's own button look (GameHUD._end_button), gold rim: the way on
	next.name = "ContinueNext"
	next.text = continue_label(target, film)
	if film:
		next.focus_mode = Control.FOCUS_NONE
		next.custom_minimum_size = Vector2(200, 38)
		next.add_theme_font_size_override("font_size", 17)
		UIStyle.style_button(next, UIStyle.GOLD)
		next.process_mode = Node.PROCESS_MODE_ALWAYS
		next.pressed.connect(func() -> void: StoryFilms.play_chain(get_tree(), next_id, mission_difficulty))
		row.add_child(next)
		row.move_child(next, 0)
		return
	next.focus_mode = Control.FOCUS_NONE
	next.custom_minimum_size = Vector2(200, 38)
	next.add_theme_font_size_override("font_size", 17)
	UIStyle.style_button(next, UIStyle.GOLD)
	next.process_mode = Node.PROCESS_MODE_ALWAYS
	next.pressed.connect(func() -> void: MenuFlow.start_mission(get_tree(), path, mission_difficulty))
	row.add_child(next)
	row.move_child(next, 0)


## The victory "Continue" button's text: the mission's number inside its episode, read from its id (m02 = 2,
## e2m1 = 1, e3m4 = 4); a film or an id without a number says plain "Continue" (review 2026-10-08 LOW 3).
static func continue_label(target: StringName, film: bool) -> String:
	var s := String(target)
	var at := s.rfind("m")
	var num := s.substr(at + 1) if at >= 0 else ""
	if film or num == "" or not num.is_valid_int():
		return "Continue"
	return "Continue: Mission %d" % int(num)


## MISSION_REWARDS-shaped entry from the config (CampaignState.reward_of reads it when its table has none).
func mission_rewards() -> Dictionary:
	return config.rewards if config else {}


## Mission-computed campaign flags (counters, bools) written on victory, after the reward table's flags.
## Only bool / int / float values (floats are saved as ints): anything else is refused with an error at once, so the
## victory save can never fail on it.
func set_mission_flag(flag_name: String, value: Variant) -> void:
	if not (value is bool or value is int or value is float):
		push_error("set_mission_flag(%s): only bool / int / float values, got %s" % [flag_name, type_string(typeof(value))])
		return
	_mission_flags[flag_name] = value


## Adds `amount` to a track counter saved across missions (e.g. `shadow_stone_uses`), on victory.
func add_track_counter(flag_name: String, amount: int) -> void:
	_track_adds[flag_name] = int(_track_adds.get(flag_name, 0)) + amount


## What CampaignState.on_mission_victory writes for this mission (set flags + counters added to the saved values).
func mission_flags() -> Dictionary:
	return _mission_flags.duplicate()


func mission_flag_adds() -> Dictionary:
	return _track_adds.duplicate()


# ---------------------------------------------------------------- the player's hero, base, truce

## Level cap (config.level_cap): XP past it is dropped (the bar reads full).
func _on_hero_xp_changed(_xp: int, _to_next: int) -> void:
	if _capping or hero == null or config.level_cap <= 0 or hero.level < config.level_cap:
		return
	_capping = true
	hero.xp = 0
	hero.xp_changed.emit(0, 0)
	_capping = false


## Re-points the player's hero (mission-e3-02.md phase switch): selection F1 / Space / spells, the HUD, the level cap
## and the instant-loss rule follow `wizard`.
func set_player_hero(wizard: Wizard) -> void:
	if wizard == null or wizard == hero:
		return
	if hero and is_instance_valid(hero) and hero.xp_changed.is_connected(_on_hero_xp_changed):
		hero.xp_changed.disconnect(_on_hero_xp_changed)
	hero = wizard
	if selection:
		selection.hero = wizard
	if hud and selection:
		hud.setup(wizard, selection)
	_cap_level(wizard)
	_watch_loss_hero(wizard)


func _watch_loss_hero(w: Wizard) -> void:
	if _loss_hero and is_instance_valid(_loss_hero) and _loss_hero.died.is_connected(_on_loss_hero_died):
		_loss_hero.died.disconnect(_on_loss_hero_died)
	_loss_hero = w
	if config.instant_loss_on_wizard_death and w and not w.died.is_connected(_on_loss_hero_died):
		w.died.connect(_on_loss_hero_died)


func _on_loss_hero_died(_u: Unit) -> void:
	if game_over or _ending:
		return
	_on_player_hero_fell()


## The instant-loss rule fired (override to add a line first): defeat after config.defeat_delay.
func _on_player_hero_fell() -> void:
	lose(config.defeat_delay)


## Locks (true) or unlocks every training building of `team`: no new orders ("Not now"), queues wait.
func lock_base(on: bool, team: int = Unit.Team.PLAYER) -> void:
	if on:
		for b in Building.for_team(team):
			var t := b as TrainingBuilding
			if t:
				t.set_meta(TrainingBuilding.META_LOCKED, true)
				t.queue_changed.emit()
				if not _locked.has(t):
					_locked.append(t)
	else:
		for t: Variant in _locked:
			if is_instance_valid(t) and int((t as TrainingBuilding).team) == team:
				(t as TrainingBuilding).remove_meta(TrainingBuilding.META_LOCKED)
				(t as TrainingBuilding).queue_changed.emit()
		_locked = _locked.filter(func(t: Variant) -> bool:
				return is_instance_valid(t) and (t as TrainingBuilding).has_meta(TrainingBuilding.META_LOCKED))


## Truce (mission-e7-02.md D8): every node of `nodes` shares truce `id`; nodes in the same truce never target each
## other (Unit.in_truce: auto-aggro, attack orders, towers). off = they fight again. Use the id &"all" to be at peace
## with everyone. A node holds one truce id: joining another truce leaves the old one (a warning says so).
## Limit: the truce covers `is_enemy_of` (auto-aggro, attack orders) and the tower gun; ability / spell area
## filters that compare `team` directly (caster spells, champion abilities) still hit a truce partner.
func set_truce(nodes: Array, on: bool, id: StringName = &"truce") -> void:
	for n: Variant in nodes:
		if not is_instance_valid(n):
			continue
		var node := n as Node
		if on:
			var old := StringName(node.get_meta(Unit.TRUCE_META, &""))
			if old != &"" and old != id:
				push_warning("set_truce: %s leaves truce '%s' for '%s'" % [node.name, old, id])
			_set_truce_id(node, id)
			_stop_truce_target(node)
		elif StringName(node.get_meta(Unit.TRUCE_META, &"")) == id:
			Unit.set_truce_id(node, &"")


func _stop_truce_target(node: Node) -> void:
	var u := node as Unit
	if u and u.attack_target != null and is_instance_valid(u.attack_target) and Unit.in_truce(u, u.attack_target):
		u.command_stop()


## Unit.set_truce_id + the node clears its truce when it leaves the tree (dies, leaves the map), so
## Unit.truce_count goes back to 0 once no truce is left.
func _set_truce_id(node: Node, id: StringName) -> void:
	Unit.set_truce_id(node, id)
	if id != &"" and not node.has_meta(META_TRUCE_HOOK):
		node.set_meta(META_TRUCE_HOOK, true)
		node.tree_exiting.connect(_on_truce_node_exiting.bind(node), CONNECT_ONE_SHOT)


func _on_truce_node_exiting(node: Node) -> void:
	if not is_instance_valid(node):
		return
	node.remove_meta(META_TRUCE_HOOK)
	if node.has_meta(Unit.TRUCE_META):
		Unit.set_truce_id(node, &"")


## Forces the hero's artifact slots: `ids[i]` != "" goes in artifact slot i (moved there if already carried, added
## if owned nowhere); "" leaves that slot alone. A forced id is never left in the other slot.
func force_artifacts(wizard: Node, ids: Array) -> void:
	var inv := ItemDrops.inventory_of(wizard) as Inventory
	if inv == null:
		ItemDrops.ensure_inventory(wizard)
		inv = ItemDrops.inventory_of(wizard) as Inventory
	if inv == null:
		return
	var want: Array = []
	for i in inv.artifacts.size():
		var forced := String(ids[i]) if i < ids.size() else ""
		var current := inv.get_type(Inventory.ARTIFACT_SLOT + i)
		want.append(forced if forced != "" else (String(current.id) if current else ""))
	for i in inv.artifacts.size():   # a kept id that is forced elsewhere moves out of its old slot
		var forced := String(ids[i]) if i < ids.size() else ""
		for j in want.size():
			if j != i and forced != "" and String(want[j]) == forced and (j >= ids.size() or String(ids[j]) == ""):
				want[j] = ""
	for i in inv.artifacts.size():
		inv.remove_item(Inventory.ARTIFACT_SLOT + i)
	for i in want.size():
		if String(want[i]) == "":
			continue
		var t := ItemDrops.item_type(StringName(want[i])) as ItemType
		if t == null or not inv.add_item(t):
			continue
		var at := inv.find_slot(t.id)
		if at != Inventory.ARTIFACT_SLOT + i:
			inv.swap(at, Inventory.ARTIFACT_SLOT + i)


## No-economy mode keeps the essence carried from the previous mission out of the bank (CampaignState.apply_to_start
## stores it in the meta `carried_essence`): the phase that turns the economy on calls this to add it. Returns it.
func grant_carried_essence() -> int:
	var n := int(get_meta(CampaignState.META_CARRIED_ESSENCE, 0))
	remove_meta(CampaignState.META_CARRIED_ESSENCE)
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if bank and n > 0:
		bank.add(n)
	return n


## Hides (true) or shows the top bar (crystals, essence, pop).
func set_resources_hidden(on: bool) -> void:
	if hud and hud.top_bar:
		hud.top_bar.visible = not on


## A knob of the running mission for kits that read the scene (titans_enabled, lair_max...), `default` when the
## current scene has no such property (skirmish, tests).
static func scene_knob(knob: StringName, default: Variant = null) -> Variant:
	var tree := Engine.get_main_loop() as SceneTree
	var scene: Node = tree.current_scene if tree else null
	if scene == null or not knob in scene:
		return default
	return scene.get(knob)


# ---------------------------------------------------------------- unit spotlight (mission-framework.md 7)

const SPOTLIGHT_FLAG_PREFIX := "spotlight_seen_"
const SPOTLIGHT_RING_RADIUS := 2.5
const SPOTLIGHT_GOLD := Color(1.0, 0.82, 0.3)


## The spotlit id of config.spotlight (a {kingdom: id} Dictionary is resolved from the player's kingdom); &"" = none.
func spotlight_target() -> StringName:
	if config == null or config.spotlight.is_empty():
		return &""
	var v: Variant = config.spotlight.get("id", &"")
	if v is Dictionary:
		var by_kingdom := v as Dictionary
		return StringName(by_kingdom.get(player_kingdom, by_kingdom.get(String(player_kingdom), &"")))
	return StringName(v)


## &"start" / &"unlock" / &"manual" (&"" without a spotlight).
func spotlight_trigger() -> StringName:
	if spotlight_target() == &"":
		return &""
	return StringName(config.spotlight.get("trigger", &"start"))


## Shows the spotlight card once per run (fire_once(&"spotlight")): Events.spotlight_shown + spotlight_shown, the
## MissionHud card (short one-line card when the save already has `spotlight_seen_<id>`), and the seen flag for the
## victory save. begin_mission calls it for trigger "start"; the mission calls it for "unlock" / "manual".
func show_spotlight() -> void:
	var id := spotlight_target()
	if id == &"" or not fire_once(&"spotlight"):
		return
	spotlight_id = id
	var flag := SPOTLIGHT_FLAG_PREFIX + String(id)
	spotlight_short = bool(CampaignState.open(campaign_save_path).flag_value(flag, false))
	set_mission_flag(flag, true)
	var card := String(config.spotlight.get("card", ""))
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"spotlight_shown"):
		events.emit_signal(&"spotlight_shown", id, card)
	spotlight_shown.emit(id, card)
	if mission_hud and mission_hud.has_method(&"show_spotlight"):
		mission_hud.call(&"show_spotlight", {"id": id, "card": card, "key_hint": String(config.spotlight.get("key_hint", "")),
				"short": spotlight_short, "mission_title": mission_title})
	if spotlight_unit == null:   # a unit of that type already on the field (given at start, freed earlier)
		for n in get_tree().get_nodes_in_group(&"units"):
			if _is_spotlight_unit(n):
				_on_spotlight_unit(n as Unit)
				break


## Watches every node that enters the tree for the first PLAYER unit of the spotlit type (trained, called, spawned).
func _watch_spotlight() -> void:
	if _spotlight_watch or spotlight_target() == &"":
		return
	_spotlight_watch = true
	get_tree().node_added.connect(_on_spotlight_node_added)
	tree_exiting.connect(func() -> void:
		if get_tree() and get_tree().node_added.is_connected(_on_spotlight_node_added):
			get_tree().node_added.disconnect(_on_spotlight_node_added), CONNECT_ONE_SHOT)


func _on_spotlight_node_added(n: Node) -> void:
	if spotlight_unit == null and n is Unit:
		_check_spotlight_unit.call_deferred(n)   # team / type are set by the spawner right after add_child


func _check_spotlight_unit(n: Variant) -> void:
	if spotlight_unit == null and is_instance_valid(n) and _is_spotlight_unit(n as Node):
		_on_spotlight_unit(n as Unit)


func _is_spotlight_unit(n: Node) -> bool:
	var u := n as Unit
	if u == null or not u.is_inside_tree() or not u.is_alive() or int(u.team) != Unit.Team.PLAYER:
		return false
	var id := spotlight_target()
	if u.unit_type and u.unit_type.id == id:
		return true
	return u.has_method(&"type_id") and StringName(u.call(&"type_id")) == id


## The first unit of the spotlit type: a flash ring, a gold ring under it for `highlight_s` s, spotlight_first_unit.
func _on_spotlight_unit(u: Unit) -> void:
	spotlight_unit = u
	flash_ring(u.global_position, SPOTLIGHT_RING_RADIUS)
	_gold_ring(u, float(config.spotlight.get("highlight_s", 6.0)))
	spotlight_first_unit.emit(u)


func _gold_ring(u: Unit, seconds: float) -> void:
	if seconds <= 0.0:
		return
	var ring := TorusMesh.new()
	ring.inner_radius = maxf(0.6, u.target_radius() + 0.2) if u.has_method(&"target_radius") else 0.8
	ring.outer_radius = ring.inner_radius + 0.18
	ring.rings = 32
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SPOTLIGHT_GOLD
	mat.emission_enabled = true
	mat.emission = SPOTLIGHT_GOLD
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	mi.name = "SpotlightRing"
	mi.mesh = ring
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	u.add_child(mi)
	mi.position = Vector3(0.0, 0.08, 0.0)
	var tween := mi.create_tween()
	tween.tween_interval(maxf(0.0, seconds - 1.0))
	tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tween.tween_callback(mi.queue_free)


# ---------------------------------------------------------------- seats (scripted sides)

## Declares a seat: a named side of the mission (`team`, its Commander or null). Membership:
## - a **tagged** seat (tag_seat was used for it, before or after add_seat) is exactly its tagged nodes, for good:
##   once they are all dead it is empty (it never falls back to its team);
## - an **untagged** seat covers every untagged unit / building of the team it was declared with (so its Commander's
##   new units join it) until switch_seat_side, which tags every node it moves: from then on the seat is those nodes
##   only (it never grows into the side it joined).
func add_seat(seat: StringName, team: int, commander: Node = null) -> void:
	var tagged := false
	for group: String in ["units", "buildings"]:
		for n in get_tree().get_nodes_in_group(group):
			if StringName(n.get_meta(SEAT_META, &"")) == seat:
				tagged = true
				break
	_seats[seat] = {"team": team, "commander": commander, "tagged": tagged or _tagged_seats.has(seat)}


var _tagged_seats: Dictionary = {}   # seat id -> true once tag_seat named it (even before add_seat)


func seat_team(seat: StringName) -> int:
	return int((_seats.get(seat, {"team": -1}) as Dictionary)["team"])


func tag_seat(node: Node, seat: StringName) -> void:
	node.set_meta(SEAT_META, seat)
	_tagged_seats[seat] = true
	if _seats.has(seat):
		(_seats[seat] as Dictionary)["tagged"] = true


## The living units and buildings of `seat` (see add_seat for who belongs to it).
func seat_nodes(seat: StringName) -> Array:
	var out: Array = []
	if not _seats.has(seat):
		return out
	var d: Dictionary = _seats[seat]
	var tagged := bool(d.get("tagged", false))
	var team := int(d["team"])
	for group: String in ["units", "buildings"]:
		for n in get_tree().get_nodes_in_group(group):
			if n.is_queued_for_deletion() or (n.has_method(&"is_alive") and not bool(n.call(&"is_alive"))):
				continue
			if n.has_meta(SEAT_META):
				if tagged and StringName(n.get_meta(SEAT_META)) == seat:
					out.append(n)
			elif not tagged and n.get(&"team") != null and int(n.get(&"team")) == team:
				out.append(n)
	return out


## mission-e7-04.md: every unit / building of `seat` changes to `team`, its Commander follows (with `profile_id` when
## given), current orders stop, and for `grace` seconds the seat is at peace with everyone (the grace walk). The
## models keep their colours (they read the team at spawn).
func switch_seat_side(seat: StringName, team: int, grace := 10.0, profile_id: StringName = &"") -> void:
	if not _seats.has(seat):
		return
	var nodes := seat_nodes(seat)
	for n: Variant in nodes:
		var node := n as Node
		tag_seat(node, seat)   # the seat is now exactly these nodes (H3: never the whole side it joins)
		node.set(&"team", team)
		var u := node as Unit
		if u and u.is_alive():
			u.command_stop()
	var d: Dictionary = _seats[seat]
	d["team"] = team
	d["tagged"] = true
	var bot: Node = d["commander"]
	if bot and is_instance_valid(bot):
		bot.set(&"team", team)
		if profile_id != &"" and &"profile_id" in bot:
			bot.set(&"profile_id", profile_id)
	if grace > 0.0:
		var grace_id := StringName("grace_%s" % seat)
		for n: Variant in nodes:   # the grace walk: at peace with everyone; the truce each node had comes back after
			var node := n as Node
			var old := StringName(node.get_meta(Unit.TRUCE_META, &""))
			if old != Unit.TRUCE_ALL:
				node.set_meta(META_TRUCE_PREV, old)
				_set_truce_id(node, Unit.TRUCE_ALL)
				_stop_truce_target(node)
		after(grace, func() -> void:
			for n: Variant in nodes:
				if not is_instance_valid(n) or not (n as Node).has_meta(META_TRUCE_PREV):
					continue   # gone, or withdraw_seat made its peace for good
				var node := n as Node
				var prev := StringName(node.get_meta(META_TRUCE_PREV))
				node.remove_meta(META_TRUCE_PREV)
				if StringName(node.get_meta(Unit.TRUCE_META, &"")) == Unit.TRUCE_ALL:
					_set_truce_id(node, prev)
			event_fired.emit(grace_id))
	seat_switched.emit(seat, team)


## mission-e7-04.md: the seat leaves the fight: its Commander pauses, its units walk to `exit` and leave the map
## (Unit.leave_map once there, or after `walk_time` s), its buildings stay at peace with everyone (truce &"all":
## nothing targets them).
func withdraw_seat(seat: StringName, exit: Vector3, walk_time := 30.0) -> void:
	if not _seats.has(seat):
		return
	var bot: Node = (_seats[seat] as Dictionary)["commander"]
	if bot and is_instance_valid(bot):
		bot.set(&"enabled", false)
		if _held_bots.has(bot):
			_held_bots[bot] = false   # a hold release must not switch a withdrawn seat's Commander back on
	var walkers: Array = []
	for n: Variant in seat_nodes(seat):
		(n as Node).remove_meta(META_TRUCE_PREV)   # a running switch grace must not end this peace
		_set_truce_id(n as Node, Unit.TRUCE_ALL)
		var u := n as Unit
		if u and u.is_alive():
			u.command_move(exit)
			walkers.append(u)
	var leave := func() -> void:
		for u: Variant in walkers:
			if is_instance_valid(u) and (u as Unit).is_alive():
				(u as Unit).leave_map()
	after(walk_time, leave)
	_withdraw_watch.append([walkers, exit])
	seat_withdrawn.emit(seat)


var _withdraw_watch: Array = []   # [units, exit]: units leave once within 3 m of the exit


# ---------------------------------------------------------------- 2v2 seats (map-2v2.md 8, scripts/core/teams.gd)

## The real seat API (the 2v2 runtime): `config.seat_sides` makes ALLY / ENEMY_2 real teams (own Economy, own
## Commander, hostility by side, fog per side). `activate_seat` brings a seat into the match (at 0:00 or mid-mission:
## e2m2's Heartwood). `start_state` keys (all optional):
##   "keep": {"type": id, "pos": Vector3, "tier": int} - the seat's keep (also its base centre);
##   "buildings": [[type_id, pos], ...] complete buildings; "workers": [[type_id, count, CrystalNode], ...] gathering;
##   "units": [[type_id, count, pos], ...] around pos (ring 2.5); "wizard": {"pos", "level", "spells"};
##   "start": Vector3 (the wizard / rally start; default the keep); "crystals": int; "profile": Commander profile id.
## Returns {keep, buildings, units, workers, wizard, commander}.
func activate_seat(seat: int, kingdom: StringName, start_state: Dictionary = {}) -> Dictionary:
	var out := {"keep": null, "buildings": [], "units": [], "workers": [], "wizard": null, "commander": null}
	if not Teams.has_seat(seat):
		push_error("activate_seat: seat %d is not in config.seat_sides" % seat)
		return out
	seat_kingdoms[seat] = kingdom
	if Economy.for_team(seat) == null:
		_add_economy(seat as Unit.Team)
	var eco := Economy.for_team(seat)
	if start_state.has("crystals") and eco:
		eco.crystals = int(start_state["crystals"])
		eco.changed.emit()
	var kd: Dictionary = start_state.get("keep", {})
	if not kd.is_empty():
		var kt := BuildingType.find(String(kd["type"]))
		var k := build_grid.spawn_complete(kt, kd["pos"], seat) if kt else null
		out["keep"] = k
		if k:
			seat_keeps[seat] = k
			seat_bases[seat] = k.global_position
			if int(kd.get("tier", 1)) > 1 and k is Keep:
				(k as Keep).set_start_tier(int(kd["tier"]))
	seat_starts[seat] = start_state.get("start", seat_bases.get(seat, Vector3.ZERO))
	for row: Array in start_state.get("buildings", []):
		var bt := BuildingType.find(String(row[0]))
		if bt:
			(out["buildings"] as Array).append(build_grid.spawn_complete(bt, row[1], seat))
	for row: Array in start_state.get("workers", []):
		var node: CrystalNode = row[2] if row.size() > 2 else null
		var at: Vector3 = node.global_position if node else seat_starts[seat]
		for i in int(row[1]):
			var w := _spawn(make_unit(String(row[0])), seat as Unit.Team, at + Vector3(cos(i * 1.3) * 2.0, 0.0, sin(i * 1.3) * 2.0))
			if w and node and w.has_method(&"command_gather"):
				w.call(&"command_gather", node)
			(out["workers"] as Array).append(w)
	for row: Array in start_state.get("units", []):
		var n := int(row[1])
		for i in n:
			var a := TAU * float(i) / maxf(1.0, float(n))
			var u := _spawn(make_unit(String(row[0])), seat as Unit.Team, (row[2] as Vector3) + Vector3(cos(a) * 2.5, 0.0, sin(a) * 2.5))
			if u:
				(out["units"] as Array).append(u)
	var wd: Dictionary = start_state.get("wizard", {})
	if not wd.is_empty():
		var wiz := _make_wizard(seat)
		_spawn(wiz, seat as Unit.Team, wd.get("pos", seat_starts[seat]))
		_claim_wizard(wiz, seat)
		if int(wd.get("level", 1)) > 1:
			raise_wizard(wiz, int(wd["level"]), wd.get("spells", []))
		ItemDrops.ensure_inventory(wiz)
		seat_heroes[seat] = wiz
		out["wizard"] = wiz
	var profile := StringName(start_state.get("profile", &""))
	if profile != &"":
		out["commander"] = _add_commander(seat, profile)
	var fog_n := get_node_or_null(^"FogOfWar") as FogOfWar
	if fog_n and seat_bases.has(seat):
		fog_n.reveal(seat, seat_bases[seat], FogOfWar.START_REVEAL)
	seat_activated.emit(seat)
	return out


signal seat_activated(seat: int)


## A seat is out when it has no defeat-relevant building (map-2v2.md 4.4); a seat never activated is never out.
func seat_out(seat: int) -> bool:
	if not seat_keeps.has(seat) and seat != Unit.Team.PLAYER and seat != Unit.Team.ENEMY:
		return false
	return Building.defeat_relevant(seat).is_empty()


## A small mission button panel (first cut of a card button the UI owner may replace): top right, under the
## controls help panel, HUD theme and slate frame. `rows` = [[text, callable], ...]; returns the panel.
func mission_button_panel(panel_name: String, rows: Array) -> Control:
	if hud == null:
		return null
	var frame := PanelContainer.new()
	frame.name = panel_name
	frame.theme = UIStyle.hud_theme()
	frame.add_theme_stylebox_override("panel", UIStyle.slate_style(8.0, UIStyle.GOLD))
	frame.anchor_left = 1.0
	frame.anchor_right = 1.0
	frame.offset_left = -268.0
	frame.offset_right = -12.0
	frame.offset_top = MISSION_PANEL_TOP
	frame.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 4)
	frame.add_child(box)
	for row: Array in rows:
		var b := Button.new()
		b.text = String(row[0])
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # the caller passes translated text
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(row[1])
		box.add_child(b)
	hud.add_child(frame)
	return frame


const MISSION_PANEL_TOP := 312.0   ## Below the controls help panel (top right, ~15-295 px at 1600 x 900 and 1920 x 1080).


## The 2v2 colour of a team (Unit.team_color by relation to the human seat).
static func seat_color(team: int) -> Color:
	return Unit.team_color(team)


func _process(_delta: float) -> void:
	if _withdraw_watch.is_empty():
		return
	for w: Array in _withdraw_watch:
		for u: Variant in w[0]:
			if is_instance_valid(u) and (u as Unit).is_alive() and _flat((u as Unit).global_position, w[1]) <= 3.0:
				(u as Unit).leave_map()
	_withdraw_watch = _withdraw_watch.filter(func(w: Array) -> bool:
		return (w[0] as Array).any(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive()))


# ---------------------------------------------------------------- difficulty and spawning

## `n` scaled by config.count_mult for the difficulty (rounded, min 1 when n > 0; 0 stays 0); 0 for
## config.easy_skip_types on easy. Empty count_mult = no scaling.
func scaled(n: int, type_id: String = "") -> int:
	if n <= 0:
		return 0
	var diff := clampi(mission_difficulty, 0, 2)
	if diff == 0 and config.easy_skip_types.has(StringName(type_id)):
		return 0
	return maxi(1, roundi(float(n) * float(MissionConfig.pick(config.count_mult, diff, 1.0))))


## values[difficulty] ([easy, normal, hard]; one value = all).
func by_difficulty(values: Array) -> Variant:
	return MissionConfig.pick(values, mission_difficulty)


## Spawns `rows` ([type_id, normal count]) in a ring around `center` (counts through scaled()). Units join group
## "scripted"; `hold_spot` makes them guards that walk back home when idle; `fixed_ring` keeps the ring even for one
## unit.
func spawn_group(rows: Array, center: Vector3, ring: float, team: Unit.Team, hold_spot: bool,
		fixed_ring := false) -> Array:
	var types: Array[String] = []
	for row in rows:
		for i in scaled(int(row[1]), String(row[0])):
			types.append(String(row[0]))
	var out: Array = []
	for i in types.size():
		if UnitType.find(types[i]) == null:
			continue
		var a := TAU / 8.0 + float(i) * TAU / maxf(1.0, float(types.size()))
		var r := ring if fixed_ring or types.size() > 1 else 0.0
		var u := _spawn(make_unit(types[i]), team, center + Vector3(cos(a) * r, 0.0, sin(a) * r))
		mark_scripted(u)
		if hold_spot:
			u.set_meta(META_HOME, u.global_position)
			_guards.append(u)
		out.append(u)
	return out


## Spawns a wave of `rows` (counts through scaled(), then `count_filter.call(n) -> int` when valid) in a spiral at
## `at`, team ENEMY unless given, all scripted.
func spawn_wave_at(rows: Array, at: Vector3, team: Unit.Team = Unit.Team.ENEMY,
		count_filter: Callable = Callable()) -> Array:
	var types: Array[String] = []
	for row in rows:
		var n := scaled(int(row[1]), String(row[0]))
		if count_filter.is_valid():
			n = int(count_filter.call(n))
		for i in n:
			types.append(String(row[0]))
	var out: Array = []
	for i in types.size():
		if UnitType.find(types[i]) == null:
			continue
		var a := float(i) * 2.39996
		var r := 1.0 + 0.45 * sqrt(float(i))
		var u := _spawn(make_unit(types[i]), team, at + Vector3(cos(a) * r, 0.0, sin(a) * r))
		mark_scripted(u)
		out.append(u)
	return out


## Group "scripted" + meta "scripted" = true: the Commander leaves it alone.
func mark_scripted(n: Node) -> void:
	n.add_to_group(SCRIPTED_GROUP)
	n.set_meta(SCRIPTED_GROUP, true)


## Dormant: out of "units" (nothing targets it), no aggro, hp kept full. Awake: normal unit, orders cleared, its own
## death_guard back (an item passive such as Rekindle). A unit asleep because of hold_world becomes the mission's: it
## stays as asked after the release.
func set_dormant(u: Unit, dormant: bool) -> void:
	if _held.has(u) or u.has_meta(META_HELD):
		_held.erase(u)
		u.remove_meta(META_HELD)
	if dormant:
		_sleep(u)
	else:
		if u.has_meta(META_DORMANT):
			_wake(u)
		u.command_stop()


func _sleep(u: Unit) -> void:
	if u.has_meta(META_DORMANT):
		return
	u.set_meta(META_AGGRO, u.aggro_range)
	u.aggro_range = 0.0
	u.remove_from_group("units")
	u.set_meta(META_GUARD, u.death_guard)
	u.death_guard = func(_attacker: Variant) -> bool:
		u.hp = u.max_hp
		return true
	u.set_meta(META_DORMANT, true)


func _wake(u: Unit) -> void:
	u.aggro_range = float(u.get_meta(META_AGGRO, 8.0))
	u.remove_meta(META_AGGRO)
	if not u.is_in_group("units"):
		u.add_to_group("units")
	var guard: Variant = u.get_meta(META_GUARD, Callable())
	u.death_guard = guard if guard is Callable else Callable()
	u.remove_meta(META_GUARD)
	u.remove_meta(META_DORMANT)


func is_dormant(u: Variant) -> bool:
	return u != null and is_instance_valid(u) and (u as Node).has_meta(META_DORMANT)


## Scripted guards walk back to their spot when they have nothing to fight.
func _tick_guards() -> void:
	var alive: Array = []
	for g in _guards:
		if not is_instance_valid(g) or not (g as Unit).is_alive():
			continue
		alive.append(g)
		var u := g as Unit
		if u.has_meta(META_DORMANT) or u.attack_target != null or u.is_attack_moving():
			continue
		var home: Vector3 = u.get_meta(META_HOME)
		if Vector2(u.global_position.x - home.x, u.global_position.z - home.z).length() > GUARD_HOME_TOLERANCE:
			u.command_attack_move(home)
	_guards = alive


## Puts `u` under wave orders: attack-move to `target`; refreshed by _refresh_waves (mode &"hero" re-aims at the
## player's hero, &"point" pushes on to the player's keep once idle, other modes: _refresh_wave_unit).
func order_wave(u: Unit, mode: StringName, target: Vector3) -> void:
	u.set_meta(META_MODE, mode)
	u.set_meta(META_TARGET, target)
	u.command_attack_move(target)
	if not _wave_units.has(u):
		_wave_units.append(u)


func _refresh_waves() -> void:
	var alive: Array = []
	var to := hero_pos()
	for w in _wave_units:
		if not is_instance_valid(w) or not (w as Unit).is_alive():
			continue
		alive.append(w)
		var u := w as Unit
		var mode: StringName = u.get_meta(META_MODE, &"point")
		if _refresh_wave_unit(u, mode, to):
			continue
		match mode:
			&"hero":
				if u.attack_target == null or not u.attack_target is Unit:
					u.command_attack_move(to)
			_:
				if u.attack_target == null and not u.is_attack_moving():
					u.set_meta(META_MODE, &"keep")
					u.command_attack_move(_alive_pos(keep, to))
	_wave_units = alive


## Mission wave modes (override): true when `u` was handled.
func _refresh_wave_unit(_u: Unit, _mode: StringName, _hero_at: Vector3) -> bool:
	return false


## Clears every wave order (units keep what they do now).
func clear_waves() -> void:
	_wave_units.clear()


## Levels a wizard up to `to_level` (spell points as usual), then learns `learn` in order.
func raise_wizard(w: Wizard, to_level: int, learn: Array) -> void:
	var guard := 0
	while w.level < to_level and guard < 20:
		guard += 1
		w.add_xp(maxi(1, w.xp_to_next() - w.xp))
	for id: StringName in learn:
		w.learn_spell(id)


## A white ring flash (radius `radius`, 1 s) with a light at `pos` (mission 1's seal flash).
func flash_ring(pos: Vector3, radius: float) -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.05
	disc.radial_segments = 48
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = disc
	mi.material_override = mat
	add_child(mi)
	mi.global_position = pos + Vector3(0.0, 0.1, 0.0)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.85)
	light.light_energy = 6.0
	light.omni_range = radius
	mi.add_child(light)
	light.position.y = 3.0
	var tween := create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tween.parallel().tween_property(light, "light_energy", 0.0, 1.0)
	tween.tween_callback(mi.queue_free)


# ---------------------------------------------------------------- helpers

func hero_alive() -> bool:
	return hero != null and is_instance_valid(hero) and hero.is_alive()


## The hero's position, else the player's keep, else PLAYER_START.
func hero_pos() -> Vector3:
	if hero_alive():
		return hero.global_position
	return _alive_pos(keep, PLAYER_START)


static func _alive_pos(n: Node3D, fallback: Vector3) -> Vector3:
	if n != null and is_instance_valid(n) and (not n.has_method(&"is_alive") or bool(n.call(&"is_alive"))):
		return n.global_position
	return fallback


static func _all_dead(units: Array) -> bool:
	for u in units:
		if is_instance_valid(u) and (u as Unit).is_alive():
			return false
	return true


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()



# ---------------------------------------------------------------- mid-mission save / load (docs/design/save-load.md)

const SAVE_REASON_UNSUPPORTED := "Saving is not supported in this mission"
const SAVE_REASON_SCENE := "Can't save during a scene"
const SAVE_REASON_SCRIPTED := "Can't save now: a scripted event is in progress"


## "" when the mission can be saved now, else why not (shown to the player).
func save_block_reason() -> String:
	if not save_supported:
		return SAVE_REASON_UNSUPPORTED
	if world_is_held or wait_for_briefing or not _intro_done:
		return SAVE_REASON_SCENE
	if _ending or game_over:
		return SAVE_REASON_SCRIPTED
	for t: Array in _timers:
		if not _timer_rebuilt(t) and not _save_timer_ok(t[1] as Callable):
			return SAVE_REASON_SCRIPTED
	return ""


## True for a timer the rebuilt mission sets again by itself (set during the start or by the intro).
static func _timer_rebuilt(t: Array) -> bool:
	return t.size() > 2 and StringName(t[2]) != &""


## A pending after() timer survives a save only when it calls one of this mission's methods by name (no lambda, no
## bound arguments): lambdas cannot be written to a file.
func _save_timer_ok(c: Callable) -> bool:
	return c.is_standard() and c.get_object() == self and has_method(c.get_method())


## The default mission save: objectives (state + text), fired events, flags and track counters, intro / keep-seen,
## held time, pending timers (by method name), bases locked by lock_base, guards and wave units (their metas travel
## with the units), and the mission script's own variables
## (plain values; units / buildings by save id; a variable holding anything else keeps the rebuilt mission's value).
## `ids`: saved node -> save id. Override to add more (call super and merge).
func save_state(ids: Dictionary = {}) -> Dictionary:
	var fired: Array = []
	for id: Variant in _fired:
		fired.append(String(id))
	var timers: Array = []
	for t: Array in _timers:
		var c := t[1] as Callable
		if not _timer_rebuilt(t) and _save_timer_ok(c):
			timers.append([float(t[0]), String(c.get_method())])
	var events: Array = []
	for e: Array in _events:
		events.append(String(e[0]))
	var locked: Array = []
	for b: Variant in _locked:
		if is_instance_valid(b) and ids.has(b):
			locked.append(ids[b])
	var guards: Array = []
	for u: Variant in _guards:
		if is_instance_valid(u) and ids.has(u):
			guards.append(ids[u])
	var waves: Array = []
	for u: Variant in _wave_units:
		if is_instance_valid(u) and ids.has(u):
			waves.append(ids[u])
	var vars := {}
	for prop in _save_own_vars():
		var x: Variant = SaveCodec.encode(get(prop), ids)
		if not SaveCodec.is_skip(x):
			vars[String(prop)] = x
	return {
		"mission_id": String(mission_id),
		"objs": _objs.duplicate(true),
		"fired": fired,
		"flags": _mission_flags.duplicate(true),
		"track": _track_adds.duplicate(true),
		"intro_done": _intro_done,
		"intro_at": _intro_at,
		"time": mission_time(),
		"keep_seen": _keep_seen,
		"held_total": _held_total,
		"timers": timers,
		"events": events,
		"locked": locked,
		"guards": guards,
		"waves": waves,
		"vars": vars,
	}


## Puts save_state() back on this rebuilt mission (its start already ran). `nodes`: save id -> rebuilt node.
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	var objs: Dictionary = d.get("objs", {})
	for id: Variant in objs:
		var key := StringName(str(id))
		if _objs.has(key):
			_objs[key] = (objs[id] as Dictionary).duplicate(true)
	_fired.clear()
	for id: Variant in d.get("fired", []):
		_fired[StringName(str(id))] = true
	_mission_flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	_track_adds = (d.get("track", {}) as Dictionary).duplicate(true)
	_intro_done = bool(d.get("intro_done", _intro_done))
	_keep_seen = bool(d.get("keep_seen", _keep_seen))
	_held_total = float(d.get("held_total", 0.0))
	# Timers: the rebuilt start / intro set theirs again (the intro's moved to the saved intro time); those due before
	# the save already ran then. Mid-mission timers come from the save (named methods only).
	var saved_time := float(d.get("time", 0.0))
	var shift := float(d.get("intro_at", _intro_at)) - _intro_at
	var kept: Array = []
	for t: Array in _timers:
		if not _timer_rebuilt(t):
			continue
		var due := float(t[0]) + (shift if StringName(t[2]) == TIMER_INTRO else 0.0)
		if due > saved_time:
			kept.append([due, t[1], t[2]])
	_timers = kept
	_intro_at = float(d.get("intro_at", _intro_at))
	for t: Variant in d.get("timers", []):
		var method := StringName(str((t as Array)[1]))
		if has_method(method):
			_timers.append([float((t as Array)[0]), Callable(self, method), &""])
	var have := {}
	for e: Array in _events:
		have[String(e[0])] = true
	for id: Variant in d.get("events", []):
		if not have.has(String(id)) and not _fired.has(StringName(str(id))):
			push_warning("Save: mission event %s was added mid-mission and is not rebuilt by the load" % id)
	_locked.clear()
	for sid: Variant in d.get("locked", []):
		var b: Variant = nodes.get(sid)
		if b is TrainingBuilding and is_instance_valid(b):
			_locked.append(b)
	_guards.clear()
	for sid: Variant in d.get("guards", []):
		if nodes.get(sid) is Unit and is_instance_valid(nodes.get(sid)):
			_guards.append(nodes.get(sid))
	_wave_units.clear()
	for sid: Variant in d.get("waves", []):
		if nodes.get(sid) is Unit and is_instance_valid(nodes.get(sid)):
			_wave_units.append(nodes.get(sid))
	var vars: Dictionary = d.get("vars", {})
	for prop: Variant in vars:
		var name_sn := StringName(str(prop))
		if name_sn in self:
			if not SaveCodec.assign_property(self, name_sn, SaveCodec.decode(vars[prop], nodes)):
				push_warning("Save: mission variable %s did not fit, kept the rebuilt value" % prop)
	var events := get_node_or_null(^"/root/Events")
	for id in objective_order:
		var st := String((_objs[id] as Dictionary)["state"])
		if st != "hidden" and events:
			events.objective_changed.emit(id, StringName(st))
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())


## The mission script's own variables (declared below MissionBase: Mission01's, MissionSkeleton's...).
func _save_own_vars() -> Array[StringName]:
	var base := {}
	var base_script := load("res://scripts/campaign/mission_base.gd") as Script
	for p: Dictionary in base_script.get_script_property_list():
		base[p["name"]] = true
	var out: Array[StringName] = []
	var s := get_script() as Script
	if s == null or s == base_script:
		return out
	for p: Dictionary in s.get_script_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE and not base.has(p["name"]):
			out.append(StringName(p["name"]))
	return out
