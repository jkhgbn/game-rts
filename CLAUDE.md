# Four Wizards RTS

3D real-time strategy game in **Godot 4.7** (GDScript). Inspired by Warcraft III and Total Annihilation: Kingdoms.
Four apprentice wizards (Fire, Ice, Nature, Shadow) race to collect their vanished master's artifacts.
The player's wizard is a hero unit; if it dies, the mission is lost.

## The user
- Talk to the user in **Québec French**. Code, file names, comments, docs and the game's text stay in English.
- The user plays on Windows with an AZERTY keyboard: define keys with **physical** keycodes.
- The user playtests at the end of every wave (see `docs/plan/waves.md`).

## Run and test
- Godot (console build, for headless checks):
  `C:\Godot\Godot_v4.7.2-stable_win64_console.exe`
  Below, `$GODOT` means that path (in PowerShell: `& "<path>" <args>`).
- Import (first time, or after adding/moving scripts): `$GODOT --headless --path . --import`
- Smoke test (must print `victory=true`):
  `$GODOT --headless --path . -s tests/smoke_test.gd --fixed-fps 60 --quit-after 7000`
- Perf test (must print `PERF OK`):
  `$GODOT --headless --path . -s tests/perf_test.gd --fixed-fps 60 --quit-after 3000`
- Per-task tests: `tests/test_<task-id>.gd`, copied from `tests/_template.gd`.
- Always pass `--quit-after` so a script error can't hang the run.
- **Fast CI** (2026-10-02, `docs/plan/error-lab.md` 3c-bis): everyday `tools\ci\ci_quick.ps1` (no slow simulations, list in
  `tools/ci/slow_tests.txt`); after a change `tools\ci\ci_quick.ps1 -Changed [-Base HEAD~N | last-green] [-ListOnly]` runs only
  the tests that name the changed files + the core set (full list when a core file changes); milestones `tools\ci\ci.ps1`
  (`-Parallel 4` default). Long bot tests stop as soon as their verdict is final; `-- --full` replays the whole match.
- Test scripts compile **before autoloads exist**: never write `Events` in a test. In game code, reach
  autoloads with `get_node_or_null(^"/root/Events")` so tests that use `Unit`, `Wizard`... still compile.
- Play: desktop shortcut "Four Wizards - Play", or open the editor ("Four Wizards - Editor") and press F5.
- Never edit files in `.godot/` or `*.import` files.

## Code style
- GDScript with static types (`var hp: float`, `func take_damage(amount: float) -> void`).
- `class_name` on every reusable script (except autoloads). Tabs for indentation.
- Public functions for other systems to call (`command_move`, `command_attack`). Prefix private ones with `_`.
  Other systems never call `_private` functions.
- Signals for events other systems react to (`died`, `claimed`, `selection_changed`), global ones on `Events`.
- Unit stats live in data (`UNIT_TYPES` in `scripts/world/main.gd`, moving to `data/units/*.tres` in task 1.G1).
- Placeholder art is built in code. Keep an `@export var model_scene: PackedScene` so real models can drop in later.
- Everything must be original: no names, characters or art from existing games.
- Physics layers: 1 world, 2 units, 3 caster walls (Rime Bulwark; ground units collide, flyers do not).

## Contracts (shared interfaces; only the lead changes them)
- **Unit** (`scripts/units/unit.gd`, group `"units"`): `team`, `command_move(Vector3)`, `command_attack(Unit)`,
  `command_stop()`, `take_damage(amount, attacker)`, `heal(amount)`, `is_alive()`, `is_enemy_of(Unit)`,
  signal `died(unit)`. New orders (attack-move, hold) follow the same `command_*` pattern.
  `set_auto_target(target)` (2026-10-02) points the unit's own auto-aggro at a target (keeps its order, the chase leash
  and the attack-move chase limit apply; not a player order). New code outside Unit uses it (or `command_attack`), never a direct `attack_target` write.
  Moving units have avoidance priority 1.0, idle ones 0.5 (idle units step aside).
- **Wizard** (group `"heroes"`): extends Unit. From wave 2, `command_cast(spell_id: StringName, target) -> String`
  (`""` = ok, otherwise the reason) replaces `command_fireball`.
- **UnitType** resource (`data/units/*.tres`, task 1.G1): `id`, `display_name`, `faction`, `cost`, `pop`,
  `train_time`, `max_hp`, `move_speed`, `attack_damage`, `attack_range`, `attack_cooldown`, `aggro_range`, `model_scene`.
- **Economy** (`scripts/economy/economy.gd`, one node per team in group `"economies"`, task 1.S1): `team`,
  `crystals`, `pop_used`, `pop_cap`, `can_afford(cost)`, `spend(cost) -> bool`, `add(amount)`, signal `changed`,
  signal `spend_failed`. Find one with `static func for_team(team: int) -> Economy`.
- **CrystalNode** (`scripts/economy/crystal_node.gd`, group `"crystal_nodes"`): `crystals_left`,
  `can_mine(worker) -> bool`, `take(amount) -> int`. Numbers and positions in `docs/design/economy.md`.
- **Workers**: units whose `UnitType.is_worker` is true get `command_gather(node: CrystalNode)`
  (`Worker extends Unit`, `scripts/economy/worker.gd`). The UI checks `has_method("command_gather")`.
- **Keep** (`scripts/buildings/keep.gd`, `class_name Keep`, group `"buildings"`, collision layer 2 so clicks
  find it): `team`, `max_hp`, `hp`, `is_alive()`, `take_damage(amount, attacker)`, `set_selected(bool)`,
  `trainable_types() -> Array[UnitType]`, `queue: Array[UnitType]` (read only), `train_progress() -> float`
  (0-1, slot 1), `can_queue(type) -> String` (`""` = ok, else the reason), `queue_unit(type) -> String`,
  `cancel(slot: int)`, `set_rally_point(pos: Vector3)`, `set_rally_node(node: CrystalNode)`,
  `rally_is_node() -> bool`, signal `queue_changed`. Keep hotkeys Q W E R T Y (physical) only act while
  the keep is selected.
- **Building** (`scripts/buildings/building.gd`, `class_name Building`, `Keep extends Building`, group
  `"buildings"`, layer 2): `team`, `building_type: BuildingType`, `hp`, `max_hp`, `is_alive()`,
  `take_damage(amount, attacker)`, `set_selected(bool)`, `is_constructed() -> bool`,
  `construction_progress() -> float`, `target_radius() -> float`, signal `destroyed(building)`.
  Buildings that train (keep, barracks) keep the Keep queue API above (`trainable_types`, `queue_unit`, `cancel`,
  rally...). Construction sites have `cancel_construction()` (75 % refund).
- **BuildingType** resource (`data/buildings/*.tres`): fields in `docs/design/buildings.md`;
  `BuildingType.find(id)`, `BuildingType.buildable_for(faction) -> Array[BuildingType]`.
- **BuildGrid** (`scripts/buildings/build_grid.gd`, reached as `main.build_grid`): `snap(world_pos, footprint) -> Vector3`,
  `check(type, center, team) -> String` (`""` = ok, else the message from buildings.md),
  `place(type, center, team, workers: Array) -> Building` (spends, creates the site, orders the workers).
  Workers: `command_build(site: Building)`.
- **Attack targets**: `Unit.attack_target` can be a Unit or a Building. Anything attackable has `team`,
  `is_alive()`, `take_damage(amount, attacker)`, `target_radius()`. Units prefer units over buildings.
- **Teams**: `Unit.Team` = `PLAYER`, `ENEMY`, `NEUTRAL` (task 2.G3). Neutral is the enemy of both sides, never
  counts for victory, and its units only fight inside their leash. Buildings use the same `Team` values.
- **1v1 rules** (`docs/design/skirmish-1v1.md`): a side loses when it has no living building. A dead wizard
  respawns at its keep: `Wizard.respawn(at: Vector3)` (gameplay), the timer lives in `scripts/world/skirmish.gd` (systems). The 1v1 is `scenes/skirmish.tscn` (`Skirmish extends main.gd`); `scenes/main.tscn` stays the mission 1 map used by the smoke test.
  Crystal drop-off at the keep **and** at barracks: buildings answer `is_drop_off() -> bool`.
  The Ember Crown in the centre is a carried item (systems, `scripts/campaign/`), dropped when its wearer dies.
- **Levels** (wave 3, `docs/design/levels.md`): `Unit.level: int`, `Unit.xp: int`, `add_xp(amount: int)`,
  signal `level_changed(unit, level)` (soldiers level 1-4; workers, towers, wardens never). `Wizard` adds
  `xp_to_next() -> int`, `spell_points: int`, `spell_rank(spell_id) -> int`, `can_learn(spell_id) -> String`,
  `learn_spell(spell_id) -> String`, signals `xp_changed(xp, xp_to_next)`, the inherited `level_changed(unit, level)`,
  `spell_points_changed(points)`, `spell_learned(spell_id, rank)`. `command_cast` can refuse `"Not learned"`.
- **Spells** (wave 3, `docs/design/spells.md` + `levels.md`): `SpellType` resources in `data/spells/`
  (ids from spells.md, rank arrays). `SpellCaster` (`scripts/spells/spell_caster.gd`, a child node named
  `"SpellCaster"` of each wizard, created by the wizard in `_ready` if the script exists): `setup(wizard)`,
  `spell_ids() -> Array[StringName]` (slot order F / Q / E), `cast(spell_id, target) -> String` (`""` = ok, else
  the reason from spells.md), `cooldown_left(id) -> float`, `cooldown_total(id) -> float`, `mana_cost(id) -> float`,
  `rank_of(id) -> int`, `set_rank(id, rank)`, signals `spell_cast(id)`, `cooldown_started(id, seconds)`.
  Refusal `"Frozen"` comes right after `"Dead"`. Each wizard's F / Q / E list is `default_spell_ids`.
  `Wizard.command_cast(spell_id, target)` delegates to it; `command_fireball(p)` stays as a wrapper.
  Learning (points, level requirements) lives in Wizard and calls `set_rank`.
- **Kingdoms Ice / Nature** (step 7-8, `docs/design/kingdom-ice.md` section 2 = FROZEN, `kingdom-nature.md`):
  factions `&"fire"`, `&"shadow"`, `&"ice"`, `&"nature"`. New `UnitType` fields: `armor`, `idle_regen_pct`,
  `on_hit_status`, `on_hit_duration`, `support_kind`, `support_amount`, `support_interval`, `support_range`,
  `support_duration`, `lifetime`. New `BuildingType` fields: `on_hit_status`, `on_hit_duration`, `idle_regen_pct`,
  `aura_radius`, `aura_stats`, `counts_for_defeat` (walls: false). Statuses `chill`, `frozen` (2 s immunity after),
  `rooted` via `apply_status`; `Unit.can_move()`, `Unit.can_act()`. Support autocast in
  `scripts/units/support_caster.gd`. Skirmish settings `player_kingdom` (default `&"fire"`) and `enemy_kingdom` (default `&"shadow"`), any of the 4 kingdoms
  (mirror allowed), set on the skirmish node before it enters the tree (the menu does it). House `max_count` is per kingdom
  (2026-09-27: every kingdom cap 200 = keep +20 + 9 houses x +20). Ice wizard: Torvald (`torvald`).
- **Campaign** (`docs/design/mission-01.md`, framework `docs/design/mission-framework.md`): missions in `missions/`
  (`mission_01.tscn` + script in `scripts/campaign/`). Every mission `extends MissionBase` (`scripts/campaign/mission_base.gd`,
  `extends Skirmish`; `Mission01` is on it): knobs in a `MissionConfig` resource (`_mission_config()` or a `.tres` on
  `config`: tiers / `max_tier` / `bots_upgrade` / `start_tiers`, `casters_enabled`, `t3_enabled`, `helpers_enabled`,
  `helper_start_called`, `helper_call_price`, titan values, start level / spell points / spells / `level_cap`, start
  crystals / essence / pop, `resources_hidden`, `economy_enabled`, `forced_artifacts`, `bot_profile_id`, end texts,
  `rewards`); API `define_objectives`, `set_objective(id, state)` (→ `Events.objective_changed`), `objective_state`,
  `objectives()`, `briefing()`, `fire_once` / `add_event` (E-list), `after(s, c)` on `mission_time()` (held time
  excluded, `hold_world(on, keep_awake)`), `say` / `say_line` (→ `Events.dialogue(speaker, text)`), `play_cutscene(id,
  end_state)` (end state also when skipped / missing / tests), `win` / `lose(delay)`, `scaled`, `spawn_group`,
  `spawn_wave_at`, `order_wave`, `set_dormant`, `raise_wizard`, `set_player_hero`, `lock_base`, `set_truce` (meta
  `truce`, `Unit.in_truce`), seats `add_seat` / `switch_seat_side` / `withdraw_seat`, `set_mission_flag` /
  `add_track_counter`, `MissionBase.scene_knob`. `CampaignState`: `MISSION_REWARDS` keys `artifact`, `flags`, `bonus_essence`,
  `set_flags`, `items`, `unlock`, `next`, `save_items`; `set_flags`, `flag_value` (int counters), `reward_of`.
  Kits: `T3Kit.enabled_here()` reads the scene's `t3_enabled`, `T3Kit.helpers_here()` its `helpers_enabled`;
  `TierSystem.set_start_tier(team, tier)` / `Keep.set_start_tier(t)` (quiet); `HelperRoster.set_call_price`, `grant()`;
  `Inventory.use_artifact_power(i)` + signal `artifact_power_used(item_id)`. Tests: `tests/helpers/mission_harness.gd`.
  Save via `scripts/campaign/campaign_items.gd`.
- **Wizard direct control**: `Wizard.set_move_input(dir: Vector3)` (world space, length 0-1, `ZERO` = released).
  While non-zero she walks that way and drops her current order; released = stands still, auto-aggro resumes.
- **Controls setting** (UX.1, `GameSettings.control_scheme`): **Classic (default)** = right-click moves the wizard like any
  unit, **A or X then click** = attack-move (3D view or minimap), arrows / edge pan, W S D unused; **RTS camera (WASD)** = right-click moves, **W A S D** pan the camera (Shift faster), X = attack-move; wheel over the minimap = minimap zoom 1-3x; **Hero WASD** = W A S D
  walk the wizard, X = attack-move. Key labels shown layout-aware (`KeyLabels`). Tab / Shift+Tab = next / previous active building when 2+ buildings are selected (control groups can hold buildings; mounts need another key).
- **Keys** (physical keycodes; AZERTY prints other letters). In Hero WASD mode: **W A S D** = the player's wizard walks (camera-relative,
  the camera follows her while a key is held), **F / Q / E** = Vessa's spells 1 / 2 / 3, **Ctrl+F / Q / E** = learn or rank up that spell, Space = centre on Vessa,
  F1 = select Vessa, F9 = restart, Esc = cancel targeting. Units selected: right-click = move / attack / gather,
  **X** = attack-move, **C** = stop, **H** = hold, **G** = gather, **B** = build menu (workers only) then
  **Z / X / C** = Hearth / Hall / Spire, **Z / V** = caster spells (Ctrl+Z / Ctrl+V autocast; any selection holding
  casters). Building selected: **Z X C V B** = its training slots 1-5 (keep **B** = caster, T2), right-click = rally.
  Construction site selected: **Delete** = cancel. Groups (SC2 style): Ctrl+N set, Shift+N add, Alt+N steal,
  Shift+Alt+N steal-add, N select, N twice = centre (N = 1-9, 0 = group 10); F2 = all army (twice = centre, Shift+F2 = add), F3 = next idle worker (Ctrl+F3 = all; idle button on the minimap: click next, Ctrl+click all); Ctrl+A = all own units (Ctrl+Shift+A adds); Tab / Shift+Tab = next / previous unit type (order: Settings > Unit priority).
  **R** = bounty mode (Shift+click stays), **Y** = tavern window, **F5 / F6 / F7** = centre on champion 1 / 2 / 3;
  bounty flag selected: **Z** = raise +25 (Shift+Z +100), **Delete** = remove.
  Trade: **U** = trade window (Bazaar wares / exchange, Lodge contracts); worker build menu **B** then **B** = Bazaar;
  Bazaar selected: **Z** = train caravan, right-click a trading post = route; caravans selected: **G** = trade
  (right-click a post / own Bazaar also works).
  Letters W A S D Q E F are never used for anything else.
- **Stats** (built in wave 3, task 3.G2, used by levels, the Crown and items in wave 4): every Unit has
  base stats (from its `UnitType` / level) plus named modifiers: `add_modifier(source_id: StringName, stats: Dictionary)`,
  `remove_modifier(source_id)`, `get_stat(name: StringName) -> float` for `max_hp`, `max_mana`, `mana_regen`,
  `hp_regen`, `attack_damage`, `attack_cooldown`, `move_speed`, `armor`, `spell_power`, `cooldown_reduction`;
  signal `stats_changed`. Flat and percent values (`"attack_damage": 10`, `"attack_damage_pct": 0.1`).
  Code never writes stat fields directly once this exists (`add_bonus_stats` becomes a modifier).
- **Items** (wave 4, `docs/design/items.md` "Suggested API" = FROZEN, items-coder): `ItemType` (`data/items/*.tres`,
  fields and `find(id)`, `total_cost()` as in items.md), `Inventory` (child of each wizard, `wizard.inventory`:
  `slots` (6), `artifacts` (2), `add_item`, `remove_item`, `use_item(slot, target) -> String`, `can_buy`, `buy`,
  `sell`, `drop`, `swap`, `nearest_shop()`, `total_item_value()`, signals `inventory_changed`, `item_used`,
  `item_bought`; stat modifiers `item:<slot>`). **Essence** lives in `scripts/items/essence_bank.gd`
  (`EssenceBank.for_team(team)`: `essence`, `add(n)`, `spend(n) -> bool`, signal `changed`; start 150, +1/s,
  kill income from items.md). **Recipes** `scripts/items/recipes.gd` (`Recipes.plan(inventory, type) -> Dictionary`
  parts to consume + essence cost), **actives/consumables** `scripts/items/item_actives.gd`.
  Shops: buildings with `is_shop() -> bool` (keep, barracks, peddler) within 12 m. Ground items `ItemPickup`
  (group `"item_pickups"`). Gameplay hooks for item effects: `attack_landed(target, amount)` on Unit,
  `spell_hit(target, amount, spell_id)` on Wizard, `apply_dot(...)`, `add_shield(amount, duration)`,
  `apply_aura(source_id, radius, stats, filter)`.
  Item keys: **Numpad 1-6 or click** the slot (Alt+N stays the group steal), **T** = shop window.
- **Champions** (step 9, `docs/design/champions.md` section 13 = FROZEN, full signatures there). Autonomous hired heroes:
  the player never orders them (bounty flags, base layout and essence only). Summary:
  `Champion extends Unit` (`scripts/units/champion.gd`, groups `"units"`, `"champions"`; `champion_type`, `variant`,
  `display_name`, `level` 1-6, `xp`, `add_xp`, `purse`, `add_purse`, `spend_purse`, `intent`, `set_intent(id, target)`,
  `inventory` (4 slots, 0 artifacts), `abilities`, `brain`, `power()`, `is_unpaid`, save state; signals
  `intent_changed(champion, intent)`, `purse_changed(amount)`; creates children `"ChampionAbilities"` and `"Brain"`).
  `Unit.is_commandable() -> bool` (Champion false): **nothing in selection / groups / F2 / right-click / command card may
  order a unit that returns false**; clicking one = read-only inspect. New statuses `taunted`, `dazed`, `braced`,
  `marked`. Veterancy rank 4 is **"Paragon"** (`VETERANCY_NAMES[3]`). `ChampionType` (`data/champions/<id>.tres`,
  `find(id)`, `all()`), `ChampionAbilities.cast(id, target) -> String`, `ChampionGuild.for_team(team)` (hire / revive /
  dismiss / costs 200+75, 250+100, 300+125 crystals+essence, pop 2, max 3, taverns open 2:00), `BountyBoard.for_team(team)`
  + `Bounty` (Hunt / Explore / Guard / Escort, group `"bounties"`), `SightMarker` (group `"fog_sources"`, FogOfWar stamps
  it), Inventory per-owner slot counts + purse buying with 20 % tithe, `ChampionVfx.play(ability_id, caster, target)`.
  Taverns: `scripts/world/tavern.gd`, neutral, invulnerable, at `(-15, -15)` / `(15, 15)`, group `"taverns"`.
- **Champion classes** (step 11, `docs/design/skills-rework.md` section 10 = FROZEN). At level 2 a champion draws a
  class (`ChampionClass`, `data/champion_classes/{spear,sword_shield,two_hand,wizard}.tres`, `pick(champion, rng)` weighted
  by `ChampionType.class_weights` + bounty leans). `Champion.champion_class`, `class_id()`, `set_champion_class(id)`,
  `is_ranged()`, signal `class_chosen(champion, class_id)`; XP table `[0, 190, 500, 940, 1500, 2190]`. Class skills
  **add** to the 3 archetype abilities (6 max; class skills unlock at L2 / L3 / L5); `ChampionAbilities` gains the 12
  ids + one autocast order. Hire 225+75 / 275+100 / 325+125, revive `80 + 35 x level`. Model kit:
  `set_weapon_class(class_id)`, attack styles `spear_thrust`, `sword_slash`, `great_cleave`, `staff_bolt`; ChampionVfx
  gains the 12 ids + `class_chosen`. Campaign companion gains optional `class`.
- **Trade** (step 10, `docs/design/market-trade.md` section 12 = FROZEN, full signatures there). Gold is a **third
  resource** (`GoldBank.for_team(team)`, `scripts/economy/gold_bank.gd`, group `"gold_banks"`, null when trade is off;
  sources trade / loot / reward; wares + exchange). `TradeNetwork.instance(tree)` (ring road, routes, ledger),
  `TradePost` (group `"trade_posts"`), `GuildHouse` (group `"guilds"`, kind `&"den"` / `&"lodge"`), `LootSack`,
  `Market extends TrainingBuilding` (Bazaar, one per team, near the keep, needs a Hall; `Market.of_team(team)`, NOT
  `for_team` which is Building's; group `"markets"`), `Caravan extends Unit`
  (group `"caravans"`, `command_trade`), `ThievesGuild.instance(tree)` + `ThiefBand` (Magpies: neutral, raid caravans
  from 5:00 and remote-node workers from 8:00, nobody can pay them), `HuntersGuild.instance(tree)` + `TrackerContract`
  (autonomous gold contracts). `UnitType.is_caravan`, `UnitType.commandable` (`Unit.is_commandable()` reads it),
  `Unit.leave_map()`, `Unit._ready` applies wares. ChampionGuild hire / revive take `pay_gold := false`.
  `Skirmish.trade_enabled := true` (missions false). `TradeVfx.play(id, at, target)` (group `"trade_vfx"`).
- **Map fill** (step 12, `docs/design/map-fill.md` section 13 = FROZEN, full signatures there; step-12 agents reach each
  other's new classes only through load-guards / groups / `has_method()`). `RiverSystem` (group `"river"`, `instance(tree)`,
  `setup(polylines, half_width, moat, crossings)`, `is_water / is_ford / is_bridge / distance_to_water / bank_of /
  crossings / nearest_land / mask_image / shader_params`, `WATER_Y -0.35`, `FORD_SLOW -0.35` as modifier `terrain:ford`,
  **`var ford_modifier_enabled := true`** — TerrainSystem (step 12b) sets it false; amphibious units group `"amphibious"`).
  `CapturePoint` / `CapturePoints` (watchtower / well / shrine, groups `"capture_points"` / `"capture_points_service"`,
  blessing 60 s), `NeutralCamp` / `CampManager` (kinds bristleback / mirefang / gloomcap / hollow_stag, `underdog_team()`),
  `CreatureAbilities.cast(id, target)`, `EpicBeasts` + `BeastBrain` (8 beast `.tres`, max 8 alive, group `"beasts"` never
  targeted by towers / keeps), `GameCritter` (NOT in `"units"`, group `"game_critters"`) + `CritterHerds.grant(team,
  reward, by)`, `CritterSystem` (cosmetic), `MapFillVfx`. BuildGrid messages `"Can't build on water"`, `"Too close to a
  crossing"`, `"Too close to a monster camp"`. `Skirmish.river_enabled / points_enabled / camps_enabled / beasts_enabled
  := true` (missions: no river). Settings `map_detail` (`&"high"` / `&"low"`). Ground river uniforms: 12.V2 `shader_params()`.
- **Map layouts** (map tools MT1-MT7, `docs/design/map-production.md` 2.8; review fixes 2026-10-02). `MapInfo`
  (`scripts/core/map_info.gd`, static): `size_x`, `size_z`, `map_id`, `setup(w, d, id, by)` (main.gd `_ready`, first thing),
  `reset()`, `release(by)` (the level leaving the tree gives the 120 m default back), `half_x/half_z/half_max/size_max`,
  `bounds()`, `contains(p, margin)`, `clamp_point(p, margin)`; fog, BuildGrid, river, minimap, camera and the ground
  shader (`main.gd apply_map_size`: `map_half_xz`) read it, never a 120 m constant. `MapLayout` (`data/maps/map_layout.gd`,
  `data/maps/<id>_layout.tres`, built by World Forge `map <id>` from `<id>.map`): `id`, `size_x/size_z`, `symmetry`,
  `seats` ({team, side, frame, frame_name}), `closed_seats`, `spots` ({id, kind, sub, pos, team, twin_of, props, image}),
  `spots_of(kind)`, `spot(id)`, `seat_frame(team)`, `keep_of(team)`, river / moat / crossings / roads / blocks / props /
  forest, `rules`, and the mission accessors `mark(id)`, `trigger(id)`, `path(id)`, `play_bounds()`, `open_seats()`,
  `target(key)`. `LayoutLevel extends Skirmish` (`scripts/world/layout_level.gd`, `scenes/layout_level.tscn`): set
  `layout_path` (or `layout`) before it enters the tree; `load_layout(path)` (static, null on failure), `layout_error()`
  ("" = ok; set = the HUD says why and the match never starts), `map_layout()`, the Skirmish slot API from the layout
  (`base_center`, `start_position`, `node_of`, `natural_hall_spot`, `rich_hall_spot`, `market_slot`, `tower_slot`,
  `cache_spots`), `bot_point(team, p)` for Commander's Crown Hollow points and `bot_vector(team, v)` for its relative
  offsets (never `bot_point` on an offset). The layout's terrain (river, crossings, landmark props) is always built; a
  mission subclass's `river_enabled = false` only turns the ford slow off.
  **Bots read the layout** (MT10): `bot_reads_layout()` (false on Crown Hollow layouts: the bot keeps Crown Hollow's
  points, identical to skirmish.tscn), `bot_mark(team, key)` (`crown`, `rally` / `anchor` = a `slot sub=bot_rally /
  bot_anchor` else 18.4 m from the keep toward the natural / the wizard start, `natural`, `rich`, `hub`; INF = none),
  `bot_scout_path(team)` (the layout's `path bot_scout`, else own side of the crown -> enemy natural -> enemy rich ->
  enemy approach). Commander: build rows X1 / X2 / M1 / S3 / S4 on the layout slots, `planned_spot(row_id)`,
  `scout_loop()` (read only), enemy explore points through the enemy's `bot_point`.
- **Map catalog + picker + gate** (MT8 / MT9, `docs/design/map-production.md` 4.2). `MapCatalog`
  (`scripts/world/map_catalog.gd`, `data/maps/catalog.tres`, `load_default()`): entries {id, title, scene | layout, size,
  seats, biome, kingdom (look), preview (`data/maps/previews/<id>.png`, the World Forge `mapsheet` render), hook, tags,
  ready, note}; `list(seats, ready_only)`, `entry(id)`, `is_ready`, `pick_random(seats, rng)`, `resolve(id, seats)`
  (`&"random"` -> a ready map; unknown / not ready -> `&"crown_hollow"`), `instantiate_level(id)` (skirmish.tscn for
  Crown Hollow, LayoutLevel + `layout_path` otherwise), `mode_note(e)`; `FOUR_SEAT_RUNTIME` false = 4-seat maps play
  1v1 (one seat per side). Menu: the skirmish setup's map column (1v1 / 2v2 seat filter, list with Random first,
  preview, info); `GameSettings.map_id` (saved), `MenuFlow.start_skirmish(..., map, seats)`, `MenuFlow.map_id` /
  `map_layout_path` (the restart hook gives a reloaded LayoutLevel its layout back). Only `ready` maps are listed.
  Gate: `tools\map_lab\run_map_gate.ps1 <map>` = `tools\world_forge\run_world_forge.ps1 gate <map>` (World Forge + Map
  Lab >= 75 / 0 FAIL, spacing, symmetry, bot fairness 40 games then 120 when close to the 45-55 % edge, perf,
  scorecard in `docs/tools/map_gate/<map>/`); a map is `ready` in the catalog only after its gate PASSes (exception
  2026-10-04: Thornwater / Quartermeet stay ready with G5 FAIL / not run, see map-production.md MT8). A stopped
  gate goes on with `-Resume` (keeps each difficulty's `results.jsonl`, plays only the missing seeds; only while the
  map and the bot code are unchanged). `-SkipBots` / `-SkipPerf` give PARTIAL at best; exit 0 PASS / PARTIAL, 1 FAIL.
- **Score** (step 16a): `ScoreKeeper` (`scripts/world/score_keeper.gd`, group `"score"`, `instance(tree)`, `score(team)`,
  `breakdown(team)`, `history(team)`, `leader()`, `margin()`, `table_text()`; WEIGHTS table at the top). Every skirmish
  end shows the Score tab (`GameHUD.show_score`, `select_end_tab`); the match still ends on kill / concede, score decides
  only at `Skirmish.time_limit_s` (0 = off; `ended_on_score`), set from `GameSettings.time_limit_min` (0 / 30 / 45).
  `GameHUD.is_message_shown() -> bool`. Bot-vs-bot tests end on score at 30:00 ("PASS … (on score)").
- **STR / INT path** (2026-09-27, `docs/design/level-boons.md` 14): `StrIntPath` (`scripts/units/str_int_path.gd`, child of each skirmish wizard; switch `StrIntPath.ENABLED`): mandatory STR or INT pick at match start, locked; STR +15 % attack_damage / +20 % max_hp + Vigor (regen), INT +15 spell_power / +25 % max_mana + Snow Shield; `ABILITY_DURATION` / `ABILITY_COOLDOWN` constants; key **J** (physical) = use the path ability. Bots pick in `scripts/ai/ai_str_int.gd`. Missions: off.
- **Keep tiers** (`docs/design/tiers.md`): `TierSystem` (`scripts/buildings/tier_system.gd`, group `"tier_systems"`, one
  per game; switch `ENABLED`): `tier_of(team)` (1-3; 3 without a TierSystem), `instance()`, `gate_reason(needed, team)`,
  `tier_name(tier)`, `status(team) -> Dictionary` (the UI's view of the next upgrade: tier, next, name, upgrading,
  progress, left, reason, crystals, time, from, short_crystals, keep), `unlocks(team, tier) -> Array[Dictionary]`,
  `unlock_text`, `announce_text`, `bot_try_upgrade`, signal `tier_changed(team, tier)`; campaign knobs `max_tier`
  (mission 1: 2 = Stronghold only) and `bots_upgrade` (missions false). `Keep.tier`, `upgrade()`, `can_upgrade()`,
  `is_upgrading()`, `upgrade_progress()`, `upgrade_time_left()`, signal `tier_changed(keep, tier)`.
  `Skirmish.tiers_enabled` (missions off except mission 1). UI: `hud.tier_chip` (`TierChip`, `scripts/ui/tier_chip.gd`,
  null without tiers) + the Next hint (`NextStepHint`).
- **Casters** (step 21, `docs/design/caster-units.md`): `CasterKit` (`scripts/units/caster_kit.gd`: switch `ENABLED`,
  `CASTERS` / `SPELLS` / `PASSIVES` tables, `enabled_here`, `keep_types`, `gate_reason`, `description`, `pick_caster`),
  `CasterAbility` node `"CasterAbility"` on each caster: `mana`, `max_mana()`, `cast(id, target) -> String`,
  `order_cast(id, target)` (walks into range), `set_autocast(id, on)`, `autocast(id)`, signals `mana_changed`,
  `spell_cast(id)`; statuses `slagged`, `scalded`, `hazed`, `tithed`; `Unit.displace(to: Vector3, seconds: float)`
  (+ signal `displaced`), `Unit.set_cast_lock(s)`, `Unit.attacks_blocked`, `Unit.order_serial`, `Unit.prefer_casters`.
  `RimeBulwark` (group `"rime_bulwarks"`), `CasterHaze` (group `"pollen_hazes"`). Skirmish only, plus a mission that
  sets `casters_enabled := true` (mission 1: its Stronghold opens the caster). Bot: `AICasters` (child of each
  Commander; `last_cast(team)` test hook). Team claims `CasterKit.claim / is_claimed` + `CasterAbility.claimed_elsewhere`
  (no two casters of a team cast one spell on one target); `CasterKit.reset()` + `AICasters.reset_history()` run in
  main.gd `_ready` (every new match / F9).
- **Events** autoload (`scripts/core/events.gd`): `unit_died(unit)`, `building_completed(building)`,
  `artifact_claimed(artifact, wizard)`, `objective_changed(id, state)`, `mission_ended(victory)`.
- **SelectionManager**: `select_units(units)`, `formation_move(center)` are public (the smoke test uses them).

## Who owns what
| Folder / file | Owner |
|---|---|
| `scripts/units/` (incl. `creature_abilities.gd`), `scripts/spells/`, `data/units/` (incl. caravan / magpie / greywater_tracker, creatures, beasts), `data/spells/`, `data/champions/`, `data/champion_classes/` | gameplay-coder |
| `scripts/economy/`, `scripts/buildings/`, `scripts/world/` (incl. river_system, capture_point(s), neutral_camp, camp_manager, game_critter, critter_herds, epic_beasts), `scripts/campaign/`, `data/buildings/`, `missions/` | systems-coder |
| `scripts/ui/`, `scripts/vfx/`, `scenes/ui/`, `assets/audio/` | ui-coder |
| `scripts/ai/` (incl. `beast_brain.gd`, `ai_mapfill.gd`) | ai-coder |
| `scripts/items/`, `data/items/` | items-coder (from wave 4) |
| `art/`, `docs/art/` (incl. `art/units/champions/<id>/`, `art/buildings/tavern/`, `art/vfx/champion_*`, `art/buildings/market/`, `art/buildings/guilds/`, `art/buildings/trade_post/`, `art/units/caravan/`, `art/units/neutral/magpie|tracker/`, `art/vfx/trade_*`, `art/units/champions/weapons/`, `art/vfx/champion_class_*`, `art/environment/water|bridges|biomes|landmarks|critters|camps|lairs/`, `art/buildings/capture/`, `art/units/neutral/<creatures>|critters|beasts/`, `art/vfx/mapfill_*`, `art/units/titans/`) | tech-artist (from wave 3) |
| `docs/design/` | game-designer (Opus 5.5 high); `docs/design/ui-*.md` ui-designer (Opus 5.5; no Fable — user 2026-09-26, keep the Fable-made UI specs as they are) |
| `scripts/cinematics/`, `scripts/ui/cinematic/` (tools wave, tool 1) | systems-coder-high |
| `tools/common/`, `tools/cine/`, `data/cinematics/`, `missions/cinematics/tool_demo/` (tools wave, tool 2) · `tools/world_forge/`, `art/cinematics/stage_sets/forge_*`, `data/maps/` (tool 6) | four-wizards-high (rules: `docs/plan/tools-wave-agent-rules.md`) |
| `project.godot`, `scenes/main.tscn`, `scripts/core/`, `tests/smoke_test.gd`, `tests/perf_test.gd`, `tests/_template.gd`, `docs/plan/`, `CLAUDE.md` | lead (the main session) |

Agents only edit what they own (plus their own `tests/test_<task-id>.gd`). Requests to another owner go in
`docs/handoff/for-<agent>.md`. The `-high` agents (`gameplay-coder-high`, `systems-coder-high`,
`items-coder-high`) are the same agents with high effort, only for tasks tagged **[H]**.

## Lead playbook (for the main session)
You are the lead. You plan, delegate, merge and check. You write only glue code and the files you own.

When the user says "run wave N session X":
1. **Budget check first.** Read the plan limits yourself with the desktop app's usage tool
   (`get_usage`: weekly all-models %, weekly Fable %, 5-hour %). Compare with the pace line in
   `docs/plan/waves.md`. If above it, or the 5-hour meter is above 70%, say so and offer the "slow down"
   options instead of starting.
2. Read `docs/plan/waves.md` and pick the tasks marked for this session. Nothing else.
3. Delegate each task to its owner agent (the `-high` one for [H] tasks) with a short prompt: task id, the
   spec file to read and the "done when" list. **No time box any more** (user request 2026-09-26): quality first, especially art.
   Up to **6 agents at the same time** while the 5-hour meter is under 50 % (3 above that, 0 above 80 %),
   only agents whose files don't overlap. **Art is split into small sub-elements** (one agent per character, building, effect family, lighting...) so each gets time and attention. Agents never run git.
4. Git: `C:\Program Files\Git\cmd\git.exe` (add it to PATH in the shell). Agents work directly in this folder.
   Remote: `origin` = https://github.com/jkhgbn/game-rts (push needs the user's GitHub sign-in once).
5. When the agents return: run the import, smoke test, perf test and each task test. If one fails, send the
   failure back to the same agent once; if it still fails, stop and tell the user. Relay API changes between
   running agents with SendMessage.
6. Green: tick the tasks in `docs/plan/waves.md`, add a line to `docs/plan/usage-log.md` (usage before/after),
   commit only the finished agents' folders, tag `wave<N>-<session>-green`, push if signed in.
7. Tell the user in 3-5 lines (Québec French) what changed and what to playtest.

**Godot gate (2026-09-26):** agents and scripts launch Godot through `tools/godot_run.ps1` (same arguments as the
exe; at most 4 runs at once via a named semaphore, waits while 6+ Godot processes run, 15-min max wait). Today 20-30
parallel Godot runs made every test slow and every perf number noise.
**Model rule (user 2026-09-27, after a trial):** never use Haiku; art = Opus MEDIUM (blind effort trial winner); AI / perf / contracts = Opus high.
**Effort rule (user 2026-09-26):** HIGH effort for complex code (river / nav, AI, contracts, labs like Replay),
debugging and design specs; MEDIUM effort for serial art / VFX (another rider, a decor set in the known format),
small test fixes and simple docs — the Art / Perf labs catch quality issues. Saves ~20-30 % of the budget on art.
Design tasks go to `game-designer` (Opus 5.5, high effort), except UI / HUD / menu layout specs, which go to `ui-designer` (Opus 5.5 — the user asked not to use Fable any more; the existing Fable-made specs stay). Code tasks go to the owner agent (Opus 5.5); visuals in `art/` go to `tech-artist`.
