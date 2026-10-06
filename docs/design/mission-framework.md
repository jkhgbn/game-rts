# Mission framework (MissionBase, MissionConfig, the shared knobs)

Status: **built** (2026-10-02, the M9.S1 extraction of `mission-02.md` "Code reuse" plus the shared "new engine needs"
of the episode 2-8 specs). Mission 1 runs on it with no behaviour change (`test_m7_s1/s2/s3`, `test_m7_u1`,
`test_tier_path`, `test_campaign_prologue`, the smoke test). Test of every knob: `tests/test_mission_framework.gd`.

| File | What |
|---|---|
| `scripts/campaign/mission_base.gd` | `MissionBase extends Skirmish`: the shared mission runtime |
| `scripts/campaign/mission_config.gd` | `MissionConfig extends Resource`: every knob as data |
| `scripts/campaign/mission_skeleton.gd` | `MissionSkeleton`: the smallest complete mission (copy it to start one) |
| `scripts/campaign/mission_01.gd` | `Mission01 extends MissionBase` (the reference for a full mission) |
| `tests/helpers/mission_harness.gd` | `MissionHarness`: headless scripted-run helper for acceptance tests (option `"set"` wins over `"config"`: a config field named in it is also written into a copy of the config; a run with no steps FAILS) |
| `tests/test_mission_framework.gd` | The skeleton with every knob (parts core / start / runtime / keep / campaign) |

## 1. How a mission is built

1. `_init()`: `super()`, then the tables: `mission_title`, `dialogue_lines` (`[[speaker, text], ...]`, line n = index
   n - 1), `speaker_colors`, `speaker_names`, `briefing_paragraphs`, `define_objectives([[id, "primary" |
   "secondary", text?], ...])` (panel order, all hidden).
2. `_mission_config() -> MissionConfig`: the knobs (section 3). `MissionBase._init` calls it and copies the switches
   the kits read off the scene (`tiers_enabled`, `casters_enabled`, `t3_enabled`, `helpers_enabled`, titan values)
   before any building exists. A scene may instead set `config` to a `.tres` (re-applied in `_ready` when it differs).
3. `_build_map()`: the map (keeps through `build_grid.spawn_complete`, nodes, props). The Skirmish map is the default.
4. `_on_navigation_ready()`: the start state (wizards with `_make_wizard` / `_claim_wizard`, armies, guards with
   `spawn_group`, the E-list with `add_event`), then **`begin_mission([initial objective ids])`**: hero knobs, HUD,
   match clock, the Commander (`config.bot_profile_id`), the objectives turned active in that order, late knobs
   (helper, artifacts, hidden resources), the MissionHud with its briefing, then `_intro()` (at once, or when the
   briefing's Begin is pressed).
5. Overrides as needed: `_intro()`, `objective_text(id, with_counter)`, `_objective_extra(id, o)` (progress, goal,
   counter, time_left, countdown, position), `briefing()`, `_title_line()`, `_refresh_wave_unit(u, mode, hero_at)`,
   `_on_player_hero_fell()`, `_physics_process` (call `super(delta)` first: Skirmish tick + timers + E-list),
   `_process` (call `super(delta)` too: MissionBase uses it for `withdraw_seat`'s exit check).

## 2. API (MissionBase)

| Group | Calls |
|---|---|
| Objectives | `define_objectives(rows)`, `set_objective(id, state)` ("hidden" / "active" / "done" / "failed"; emits `Events.objective_changed(id, state)` and `objectives_changed`; done / failed never change; call again with "active" for a counter change), `objective_state(id) -> String` ("" while hidden), `objectives() -> Array[Dictionary]` (MissionHud rows), `objective_text(id, with_counter)`, `primaries_done()`, `briefing() -> {title, paragraphs, objectives, rule}` |
| Events | `fire_once(id) -> bool` (true the first time), `has_fired(id)`, `add_event(id, condition, action, repeat := false)` (the E-list: checked every `EVENT_TICK` = 1 s in insertion order while the match runs, not held, not ending), signal `event_fired(id)` |
| Clock | `mission_time()` (match time minus held time), `after(seconds, callable)` (mission time), `hold_world(on, keep_awake := [])` (cinematics.md HOLD: clock stops, every Commander `enabled = false`, every other living unit dormant; `false` restores exactly what it changed: a ceasefire, not a freeze, so orders are kept (workers keep gathering / building, armies their move / attack-move, waves their targets) and each unit gets its own `death_guard` back (Rekindle); a unit the mission puts to sleep or wakes with `set_dormant` during the hold, and a Commander `withdraw_seat` turned off during it, keep the mission's state), `world_is_held`, signal `world_held(on)` |
| Dialogue | `say(speaker, text)`, `say_line(n)` (both: `Events.dialogue`, `dialogue_said`, `dialogue_log`), `speaker_color_of`, `speaker_name_of` |
| Cinematics | `play_cutscene(id, end_state := Callable()) -> String`: plays `data/cinematics/<id>.tres` in this context; `end_state` runs once at the end, skipped or not; with `cinematics_enabled = false`, no script or a refused play it runs at once (the direct-effect fallback; the 19.C9 skip rule) |
| End | `win(delay := 0, force := false)`, `lose(delay := 0, force := false)` (mission time; the first ending decided is final: a later win / lose is ignored while one is pending, unless `force`, which replaces it), `is_ending()`, `_end_game(victory)` (campaign save on victory when `save_campaign_on_victory`, then `Events.mission_ended`, banners from the config), keep-lost defeat (`config.defeat_on_keep_lost`, `keep_lost_message`; armed once the player has had a living keep, so a map without one is never lost by it), instant loss (`config.instant_loss_on_wizard_death`, `defeat_delay`; follows `set_player_hero`) |
| Difficulty | `mission_difficulty` 0-2 (export), `scaled(n, type_id)` (`count_mult`, rounded, min 1 unless `n` is 0; `easy_skip_types` give 0 on easy), `by_difficulty([easy, normal, hard])` |
| Spawning | `spawn_group(rows, center, ring, team, hold_spot, fixed_ring := false)` (scripted; guards walk home), `spawn_wave_at(rows, at, team := ENEMY, count_filter := Callable())`, `mark_scripted(n)`, `set_dormant(u, on)`, `is_dormant(u)`, `order_wave(u, mode, target)` (modes `&"point"` (then the keep), `&"hero"` (re-aims at the hero every `REFRESH_INTERVAL` = 3 s), own modes in `_refresh_wave_unit`), `clear_waves()`, `tick_scripted(delta)` (guards + waves when the mission has no own tick), `raise_wizard(w, level, learn)`, `flash_ring(pos, radius)` |
| Hero / base | `set_player_hero(wizard)` (selection F1 / Space / spells, HUD, level cap, instant loss), `lock_base(on, team := PLAYER)` (training buildings refuse with `"Not now"`, queues wait), `set_resources_hidden(on)`, `force_artifacts(wizard, [slot1, slot2])` ("" = leave) |
| Truce | `set_truce(nodes, on, id := &"truce")`: meta `truce` = id; `Unit.in_truce(a, b)` (same id, or either id `&"all"`) makes `Unit.is_enemy_of` false both ways (auto-aggro, attack orders) and towers skip them. One id per node: joining another truce leaves the old one (warning). A node that leaves the tree gives its truce back (`Unit.truce_count` returns to 0; MissionBase also resets it in `_ready`). **Limit:** ability / spell area filters that compare `team` directly (caster spells, champion abilities) still hit a truce partner |
| Seats | `add_seat(seat, team, commander := null)`, `tag_seat(node, seat)` (a seat tagged once = exactly its tagged nodes for good, empty when they are gone; an untagged seat = every untagged node of the team it was declared with, until it switches), `seat_nodes(seat)` (living), `seat_team(seat)`, `switch_seat_side(seat, team, grace := 10, profile_id := &"")` (team of every unit / building + its Commander, orders stopped, the moved nodes are tagged: the seat never grows into the side it joins; `&"all"` truce for `grace` s, then each node's earlier truce id comes back), `withdraw_seat(seat, exit, walk_time := 30)` (Commander off, units walk to `exit` and `leave_map` there or after `walk_time`, everything at peace with all), signals `seat_switched`, `seat_withdrawn` |
| Campaign | `mission_rewards()` (= `config.rewards`), `set_mission_flag(name, value)` (computed bools / ints / floats written on victory; any other type is refused with an error at once), `add_track_counter(name, amount)` (added to the saved value, e.g. `shadow_stone_uses`; **each mission counts once**: a replayed mission replaces its own previous contribution, the latest victory counts, so a replay never inflates a counter), `mission_flags()`, `mission_flag_adds()`, `grant_carried_essence()` (no-economy mode: adds the essence carried from the last mission, held back until then) |
| Kits | `static scene_knob(name, default)` (reads a property of the running mission; `default` in the skirmish / tests) |
| Spotlight | `show_spotlight()`, `spotlight_target()`, `spotlight_trigger()`, `spotlight_id` / `spotlight_short` / `spotlight_unit`, signals `spotlight_shown(id, card)`, `spotlight_first_unit(unit)` (section 7) |
| Test switches (set before the tree) | `show_briefing`, `save_campaign_on_victory`, `campaign_save_path`, `cinematics_enabled`, `mission_difficulty`, `config` |

Engine hooks added with it:
- `TierSystem.set_start_tier(team, tier)` and `Keep.set_start_tier(t)`: tier HP / attack / look with no announcement,
  no timer and no tier-up flourish (a running upgrade is refunded); works mid-mission. (The specs write both forms.)
- `T3Kit.enabled_here()` also reads the scene's `t3_enabled`; `T3Kit.helpers_here()` reads `helpers_enabled` (the keep
  lists the helper call / revive). Skirmish unchanged.
- `HelperRoster.call_price` / `set_call_price({crystals, essence, time})`, `call_essence()`, `grant(at := INF)` (the
  helper on the field as if called, no price; `helper_start_called` and the e2m4 / e2m5 free grant).
- `TrainingBuilding.is_locked()`, `REASON_LOCKED = "Not now"`, `META_LOCKED`.
- `EssenceBank.kill_income_enabled`.
- `Inventory.use_artifact_power(index := 0) -> String` ("Dead", "Empty slot", the mission's `artifact_power_gate`
  refusal, `"Recharging"` while the artifact's `active_cooldown` runs), signal `artifact_power_used(item_id)`; the
  effect belongs to the mission listening to it.
- `Unit.TRUCE_META`, `Unit.TRUCE_ALL`, `Unit.in_truce(a, b)`, `Unit.set_truce_id(node, id)` (keeps `Unit.truce_count`; with no truce
  anywhere `is_enemy_of` and the towers skip the check).
- `CampaignState`: flags keep ints (counters) as well as bools; `flag_value(name, default)`, `set_flags(values,
  save_now := false)`, `reward_of(id, level)` (`MISSION_REWARDS` first, then the mission's `mission_rewards()`, then
  `registered_rewards`), reward keys `artifact`, `flags`, `bonus_essence`, `set_flags`, `items` (extra owned
  artifacts), `unlock` (several missions), `next`, `save_items` (false = flags only, items / essence untouched).
  Track counters per mission (`track`, `add_track(mission_id, adds)`). Crash-safe save: `save()` writes `<path>.tmp`,
  keeps the previous save as `<path>.bak` and renames into place; `load()` never takes an unreadable save for a new
  campaign (warning, the file kept as `<path>.corrupt`, the `.bak` loads; `loaded_from` says which file was read).
  `apply_to_start` holds the carried essence back on a no-economy mission (meta `carried_essence`).

## 3. MissionConfig (the knobs)

Defaults = off / untouched. Difficulty arrays are `[easy, normal, hard]`; one value applies to all; `[]` = untouched.

| Knob | Effect | When |
|---|---|---|
| `mission_id`, `title` | save id, panel title | `_init` |
| `count_mult` ([] = no scaling; mission 1: 0.6 / 1 / 1.4), `easy_skip_types` ([]; mission 1: `shadow_knight`) | `scaled()` | runtime |
| `defeat_on_keep_lost` (true), `keep_lost_message` | defeat when the player's keep falls (armed only once a living player keep existed) | every 0.5 s |
| `instant_loss_on_wizard_death`, `defeat_delay` (3 s) | the hero's death = defeat | `begin_mission`, `set_player_hero` |
| `victory_banner`, `defeat_banner` | end banners | `_end_game` |
| `rewards` | MISSION_REWARDS-shaped entry when the table has none | victory |
| `tiers_enabled`, `max_tier`, `bots_upgrade` (false), `start_tiers` ({team: tier}) | TierSystem node, cap, bots, quiet start tiers | `_init` / `_ready` |
| `casters_enabled`, `t3_enabled`, `helpers_enabled` | read by CasterKit / T3Kit from the scene | `_init` |
| `helper_start_called`, `helper_call_price` ({crystals, essence, time}, arrays per difficulty allowed) | `HelperRoster.grant()`, `set_call_price` | `begin_mission` |
| `titans_enabled`, `lair_max`, `titan_max_trained`, `lair_min_time` | copied to the mission node for the future titan kit (`scene_knob`) | `_init` |
| `start_level`, `start_spells`, `start_spell_points` (-1 = as levelled), `level_cap` (0 = none) | the player's wizard (`Wizard.level_cap` + mission 1's XP drop) | `begin_mission` |
| `start_crystals`, `enemy_start_crystals` | Economy crystals by difficulty | `_ready` |
| `start_essence` (-1 = 150), `essence_trickle`, `kill_essence` | EssenceBank (carried essence is added later by `CampaignState.apply_to_start`) | `_ready` |
| `start_pop_bonus` | player pop cap + n | `_ready` |
| `resources_hidden` | the top bar hidden | `begin_mission` |
| `economy_enabled` (false = no-economy mode) | 0 crystals, 0 essence (the carried essence waits for `grant_carried_essence()`), no trickle, no kill income, top bar hidden | `_ready` / `begin_mission` |
| `forced_artifacts` | artifact slots forced (key relic) | `begin_mission` |
| `bot_profile_id`, `bot_team` | the Commander (AIProfile id; unknown id = passive easy knobs); `&""` = scripted enemy only | `begin_mission` |
| `spotlight` | the unit spotlight (section 7): {id, card, trigger, key_hint, highlight_s} | `begin_mission` ("start") / `show_spotlight()` |

## 4. Skeleton

`scripts/campaign/mission_skeleton.gd` (runs in `tests/test_mission_framework.gd`):

```gdscript
class_name MissionMyMission
extends MissionBase

const DIALOGUE := [[&"narrator", "..."], [&"vessa", "..."]]

var guard_g1: Array = []

func _init() -> void:
	super()
	mission_title = "Mission X: Title"
	dialogue_lines = DIALOGUE
	briefing_paragraphs = ["..."]
	define_objectives([[&"obj_main", "primary", "Do the thing"], [&"obj_vessa", "primary", "Vessa must survive"],
			[&"sec_extra", "secondary", "Optional thing"]])

func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = &"e2m1"
	c.tiers_enabled = true
	c.max_tier = 3
	c.start_tiers = {Unit.Team.PLAYER: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_call_price = {"crystals": 250, "essence": 100, "time": 30.0}
	c.start_level = 4
	c.start_spell_points = 3
	c.level_cap = 8
	c.start_crystals = [500, 400, 350]
	c.instant_loss_on_wizard_death = true
	c.bot_profile_id = &"mission_e2_01"
	c.rewards = {"flags": {"e2m1_folk_saved": "sec_extra"}, "set_flags": {"helper_vey_unlocked": true}, "next": &"e2m2"}
	return c

func _on_navigation_ready() -> void:
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	CampaignState.open(campaign_save_path).apply_to_start(self)   # items, carried essence, companion, flags meta
	guard_g1 = spawn_group([["shade", 3], ["nightbolt", 1]], Vector3(-10, 0, 10), 2.0, Unit.Team.ENEMY, true)
	add_event(&"E2", func() -> bool: return _all_dead(guard_g1), func() -> void:
		say_line(2)
		set_objective(&"obj_main", "done")
		win(4.0))
	after(300.0, func() -> void:   # W1 at 5:00 of mission time
		for u in spawn_wave_at([["shade", 4]], SHADOW_START):
			order_wave(u, &"hero", hero_pos()))
	begin_mission([&"obj_main", &"obj_vessa", &"sec_extra"])

func _intro() -> void:
	play_cutscene(&"e2m1_open", func() -> void: say_line(1))   # end state = what a skip leaves
```

Register the scene in `CampaignState.MISSION_SCENES` / `MISSION_ORDER` (and `MISSION_REWARDS` when the spec gives the
table; `config.rewards` is the fallback).

## 5. Testing a mission (MissionHarness)

```gdscript
extends SceneTree
var h := MissionHarness.new()
var main: Node

func _initialize() -> void:
	h.task_id = "e2m1_s2"
	main = h.open(self, "res://missions/mission_e2_01.tscn", {"difficulty": 1})
	h.steps.add("clear G1", _clear_g1, 600)
	h.steps.add("victory", func() -> bool: return h.ended == 1, 1200)

func _clear_g1() -> bool:
	MissionHarness.kill(main.guard_g1)
	return h.saw("obj_main", "done")

func _process(_d: float) -> bool:
	return h.tick()
```
`open` turns the briefing, the campaign save and cinematics off (end states run at once), records
`objective_log` ("id=state"), `dialogue_log` and `ended` (-1 / 0 / 1), and heals the hero every frame
(`protect_hero`). Helpers: `kill(nodes)`, `put(unit, at)`, `immortal(unit)`, `skip_time(mission, s)` (jumps the
clock; timers fire next frame), `saw(id, state)`, `check(cond, what)`. Steps run in order, one call per frame, each
with its own frame budget; the verdict prints `PASS <task_id>` / `FAIL <task_id>: ...`. Pass a method for any step
longer than one line (a multi-line lambda followed by another argument does not parse well).

## 6. Knobs the specs name that are NOT built (and why)

| Knob (specs) | Why not | Next owner |
|---|---|---|
| `FogOfWar.sight_scale` per team (m02, e2m4, e3m2, e5m3, e6m1, M0) | `scripts/world/fog_of_war.gd` is in `scripts/world/`, reserved for the map-tools agent while this was built | systems, after the map tools land |
| Statuses `concealed` (e3m2 only), `stilled` (e3m3 only) | one spec each (the rule: build when 2+ specs need it); belong to `Unit.STATUSES` (gameplay) | gameplay with the e3m2 / e3m3 builds |
| `hidden` visibility filters (e5m2, e5m3, e5m4, e7m3) | four different meanings (untargetable band, team-side filter at 2.5 m, hidden dockers); needs FogOfWar + targeting work | design to unify, then gameplay |
| The real 2v2 seat API (`ai-2v2.md`: `seats()`, `side_of`, `for_seat` services, `activate_seat`, `Teams.configure`, `AllyChannel`) | step 20 is not built; MissionBase seats are a team-level stand-in (switch / withdraw / tag) | 20.D1 |
| Titan rules (`titans_enabled`, `lair_max`, `titan_max_trained`, `lair_min_time` consumers) | no titan / Lair code exists yet; the values are on the mission node (`scene_knob`) | the titan kit |
| `items_locked` (e3m2, e5m1, e5m3) | shop / inventory UI lock: items and UI owners | items + ui |
| Key **J** for the artifact power, the card slot, `key_relic` no drop / sell / swap | input and command card are UI; drop / sell rules are Inventory / shop; `use_artifact_power` and the forced slot exist | ui + items |
| Per-wizard save tracks, the `ep5` track, `resume`, `episode`, film ids in `next` (StoryFlow) | 19.C2 story flow; `save_items: false` already gives flags-only victories | systems (19.C2) |
| `research_enabled` / `research_max_tier`, `cavalry_enabled`, trade timing overrides | knobs of systems that live elsewhere (ResearchBank, stables, TradeNetwork) | their owners |
| Commander `set_paused` (19.A1), per-mission AIProfile entries | ai-coder files; MissionBase uses `enabled` and a passive fallback profile | ai |
| `Wizard.set_kneel_instead_of_death`, `Building.set_hp_floor` (e8m2), `set_look` model looks | one spec each / art | gameplay / art |
| "pop off until the claim" (e2m4) | one spec | with e2m4 |

Known limits of what is built: `switch_seat_side` does not recolour models (they read the team at spawn) and the
switched units' pop stays counted by their old Economy until they die; `withdraw_seat` buildings are untargetable
through the truce, not invulnerable to area spells; `set_player_hero` re-runs `hud.setup` (made for it) but does not
move the wizard between the `"heroes"` / `"enemy_heroes"` groups (call `_claim_wizard` when the new hero changes
side).

## 7. Unit spotlight hook (built 2026-10-06; the design table below is kept)

**Built:** `Events.spotlight_shown(id, card)`; `MissionConfig.spotlight` ({id (or {kingdom: id}), card, trigger
`&"start"` / `&"unlock"` / `&"manual"`, key_hint, highlight_s}); `MissionBase.show_spotlight()` (once per run,
`fire_once(&"spotlight")`; begin_mission calls it for "start"), `spotlight_target()`, `spotlight_trigger()`, read-only
`spotlight_id` / `spotlight_short` / `spotlight_unit`, signals `spotlight_shown(id, card)` and
`spotlight_first_unit(unit)`; the first-unit watch (SceneTree `node_added`, checked one frame later; a unit of that type
already on the field when the card shows counts): `flash_ring(pos, 2.5)` + a gold ring child `SpotlightRing` for
`highlight_s` s (no `Unit.set_highlight` look hook: the ring is a mesh under the unit); `SpotlightCard`
(`scripts/ui/mission/spotlight_card.gd`) shown by `MissionHud.show_spotlight(data)` **under** the objectives panel (the
panel sits at the left edge), after the briefing closes; click = the pause menu's Unit Guide on that unit; harness
`saw_spotlight(id)` / `spotlight_log`; test parts `spotlight` and `spot_manual` in `test_mission_framework.gd`.
**Seen flag:** `spotlight_seen_<id>` is a mission flag (`set_mission_flag`), written by the victory save: a replay after
a won run shows the short card (a lost run shows the full card again). **Not built:** the Unit Guide's "Spotlight:
<mission title>" line (ui-coder), `forge_enabled` (with e2m4). Missions m00-m04 and e2m1 fill `spotlight` and say their
moment's hint (unit-spotlights.md 2.1 / 2.2).

### 7.1 The design (2026-10-06)

Each mission shows one unit at its best (`unit-spotlights.md`). This is the hook every mission uses; a mission adds
only its own "moment" through the E-list.

| Part | Proposal | Owner |
|---|---|---|
| Data | `MissionConfig.spotlight: Dictionary = {}`: `id` (UnitType / helper / titan / building id; Ep8 missions: `{kingdom: id}` resolved from the player's kingdom), `card` (the English intro line, <= 110 chars, through `Loc.sink`), `trigger` (`&"start"` / `&"unlock"` / `&"manual"`), `key_hint` (`"Ember Hall: V"`), `highlight_s` (6.0) | systems-coder |
| Show | `MissionBase.show_spotlight() -> void` (once per run; `fire_once(&"spotlight")`): emits `Events.spotlight_shown(id, card)`; called by `begin_mission` for `start`, by the mission for `unlock` (e.g. m01's Brazier 2 event) or `manual` | systems-coder |
| First train | MissionBase listens to `Events.unit_spawned` (or the training building's `unit_trained`, whichever exists) for the first PLAYER unit whose type id = `spotlight.id`: `flash_ring(pos, 2.5)`, a gold outline for `highlight_s` (a `Unit.set_highlight(on)` look hook or a decal), signal `spotlight_first_unit(unit)` so the mission plays its own line. Helpers / titans: the same on `HelperRoster` call / Lair spawn | systems-coder (+ gameplay for the look hook) |
| Card | `SpotlightCard` in the MissionHud, left of the objectives: portrait (`art/icons/units/<id>.png`, else `UIStyle.abbrev`), name, card line, the Unit Guide's `strong_against` tags (`UnitGuideData`), the key hint; 12 s or a click; click = open the Unit Guide on that unit (pause menu). Never holds the world | ui-coder (layout ui-designer) |
| Save | `CampaignState` flag `spotlight_seen_<id>`: a replay shows the short card (one line, 4 s); the Unit Guide shows "Spotlight: <mission title>" for seen units | systems-coder + ui-coder |
| Core | `Events.spotlight_shown(id: StringName, card: String)` | lead (core) |
| Forge knob | `MissionConfig.forge_enabled` read by `ForgeKit.enabled_here()` (today skirmish only) so e2m4 can spotlight the real Forge | systems-coder |
| Tests | `test_mission_framework.gd` part `spotlight`: card on start / unlock / manual, once only; first-train highlight on the right type only; the seen flag; harness `saw_spotlight(id)`. Strings: `extract_strings.gd merge` + `test_i18n` | systems-coder |

Order: Events signal and MissionConfig field first, then MissionBase, then the card; missions fill `spotlight` in their
own `_mission_config()`.
