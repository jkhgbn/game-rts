# For the lead

## From ui-coder 9.C8 (bounty mode, flag card, selection filter, minimap icons, barks)
Nothing has to be glued: every 9.C8 piece installs itself.
- `SelectionManager._ready` creates the scene's one `BountyMode` (in its canvas layer, group `"bounty_mode"`) and the
  one `ChampionBarks` (group `"champion_barks"`). `CommandCard.setup` attaches the `FlagCard` under the HUD.
  9.C7's `hud.gd` also calls `FlagCard.attach(hud, selection)` / `BountyMode.attach(hud)`: both return the existing
  instance (no duplicates; a second BountyMode / ChampionBarks frees itself).
- Esc: the selection manager takes Esc in `_input` (before the pause menu's `_unhandled_input`) only while bounty
  mode is on, a champion is inspected or a flag is selected, so Esc leaves the mode / clears the view instead of opening
  the pause menu. No change needed in `pause_menu.gd`.
- Messages of champions.md section 9 are emitted by their owners (guild 9.C3, board 9.C4, inventory 9.C6), as
  ui-champions.md 11 says; 9.C8 only shows its own refusals (`No champions`, `Too many bounties`, `Invalid target`,
  `Not enough essence`, `Max bounty`) through `selection.message`.
- The hunted-coin marker of ui-champions.md 8 is already drawn by `bounty.gd` (OwnerMark + the lifted flag), so the
  barks node does not add a second one. The stake label is bounty.gd's own `Stake` Label3D; the barks node only
  rewrites its text at 2 Hz for the timers (`150 · 1:20` Guard / Escort, `150 · 42 s` WARN for a lost Hunt target).
- `tests/test_3_u3.gd` now fails with `help text has 8 lines (max 7)`: that is 9.C7's 8th help line
  (ui-champions.md 12 asks for it). The old test's limit needs updating to 8 (not a 9.C8 file).

# Task A2.7 (tech-artist): two generators would overwrite the new neutral art
- `art/units/shadow/_build_shadow.gd` line ~729 still `finish()`es `res://art/units/neutral/ruin_warden.tscn` with the old
  look / ShadowModel: drop that line before re-running it (the warden is now `art/units/neutral/warden_model.gd`,
  code-built like the wizards).
- `art/environment/build_env.gd` `_init` still calls `_build_cache()` / `_build_peddler()`, which write
  `lost_cache.tscn` / `ruin_peddler.tscn`: drop those two calls (the new generator is
  `art/environment/neutral/build_neutral.gd`). After that, `art/environment/lost_cache_art.gd`, `ruin_peddler_art.gd` and
  `art/environment/meshes/lost_cache_*.res`, `peddler_*.res` are unused and can be deleted.
# Task 10.C2 (systems): the frozen `Market.for_team(team) -> Market` cannot exist (contract fix needed)
- GDScript refuses it: `Market extends TrainingBuilding extends Building`, and Building already has
  `static func for_team(team) -> Array[Building]` ("The function signature doesn't match the parent").
- Shipped instead: **`Market.of_team(team: int) -> Market`** (completed + alive, else null) and the group
  **`"markets"`** (every Bazaar, sites too). Please change section 12 of `market-trade.md` / the Trade bullet of
  `CLAUDE.md` to `of_team`.
- Trap for every load-guarded caller: `load("res://scripts/buildings/market.gd").call(&"for_team", t)` does NOT fail, it
  runs `Building.for_team` and returns the team's whole building Array (never null). Callers must use `&"of_team"` or
  the `"markets"` group. Likely callers: GoldBank "No Bazaar" (10.C11), trade window / cards (10.C7 / 10.C8), bot
  (10.A3). caravan.gd (10.C3) is fine (it scans "buildings" for kind market).
- The Bazaar is listed by `BuildingType.buildable_for(faction)` only while `BuildingType.trade_active()` (a node in
  group `"gold_banks"` or `"trade_network"` exists), so missions and the older build-menu tests are unchanged.
- Victim XP "Bazaar 80" is not in my files: `Unit.BUILDING_KILL_XP` (unit.gd, gameplay) needs
  `fire_market / shadow_market / ice_market / nature_market: 80` (handoff for-gameplay-coder.md).
## From 10.C11 (GoldBank), 2026-09-26
- **10.C1 (skirmish)**: create the banks with `GoldBank.create(parent, team)` (load-guarded: `load("res://scripts/economy/gold_bank.gd").call(&"create", self, team)`) for PLAYER and ENEMY **only when `trade_enabled`**. `GoldBank.for_team` never creates a bank, so it is null with trade off (that is the on/off rule). `GoldBank.trade_active()` = a bank exists.
- **10.C6 (Unit._ready)**: call `apply_wares(self)` on the team's bank (group `"gold_banks"`, match `team`). Idempotent. The bank also applies wares itself at the end of the frame a unit enters the tree (safety net), so nothing breaks before 10.C6 lands.
- **10.C8 (UI)**: signals `changed(gold)`, `spend_failed`, `ware_bought(id)`, plus an extra `exchanged(gold, to, received)` for the `Exchanged 100 gold for 80 crystals` message. Helpers: `ware_name(id)`, `ware_price(id)`, `ware_text(id)`, `owns_ware(id)`, `can_exchange(amount, to)`, `has_bazaar()`, `earned(&"trade")` for the end screen.
- **Unrelated failure seen**: `tests/test_7_s1.gd` fails because 10.C2 added the Bazaar to the build menus ("Ice build menu is [..., &"ice_market"]"). That test's expected lists need the market ids.

# Step 10 (task 10.C1, from systems-coder)
- `TradePost` / `GuildHouse` extend **StaticBody3D** (a Node3D, like `Tavern`), not Node3D directly: their own 6 x 6
  collider on layers 1 + 2 (build grid, navmesh, clicks). Worth writing as such in the CLAUDE.md Trade bullet.
- Extra public members beyond section 12 (additive): TradeNetwork `post_by_id`, `guild_houses`, `road_nodes`,
  `guilds_open`, `value_for_length`, `route_income`, `traded_total`, `trips_total`, `robbed_total`, `loot_total`,
  `magpies_slain`, `raids_on`, `holder_of`, `spot_valid`, `unit_strength`, `is_caravan`, `refresh`,
  `record_workers_raided`, `record_loot_pickup`, signals `loot_picked(team, amount, sack)`, `guilds_opened`;
  Skirmish `trade_stats_of(team)`, `gold_bank_of(team)`, `road_param()`, vars `trade_posts`, `guild_houses`,
  `gold_banks`; `EnvProps.set_roads(mat, roads, width)`.
- `--no-trade` for 10.L2: `main.set(&"trade_enabled", false)` before `add_child` (as `--no-champions` does).

# Step 10 (task 10.C7, from ui-coder)
- **Test expectations changed by 10.C8's HUD work (not 10.C7 code)**: `tests/test_9_c7.gd` `_check_help` looks for the old
  one-line `R: bounty ... F5-F7: find champion    Flag: Z raise · Delete remove` (ui-trade.md 14.1 re-cuts it; the rest of
  9.C7 passes with that check skipped); `tests/test_3_u3.gd` fails "help text has 11 lines (max 8)" (14.1 = 11 lines);
  `tests/test_2_u1.gd` / `tests/test_4_u1a.gd` fail "top bar 624 x 40 at (488, 8)" on main.tscn (no GoldBank there:
  the top bar should stay 500 wide without a bank, ui-trade.md 3.1). All other `test_*_u*.gd`, 9.C8, smoke pass.
- **Glue**: none needed. `CommandCard.setup` attaches the RouteLine itself (like the flag card); hud.gd's guarded
  `attach_optional(route_line.gd)` finds it in group `"route_line"` (a second `RouteLine.attach` returns the same node).
- **Behaviour change to know**: a left click on a visible enemy / neutral unit now *inspects* it read-only
  (`selection.inspected`, the single view; needed for the Magpie / enemy caravan views of ui-trade.md 6.2 / 6.3). Before,
  it just cleared the selection. Champions and orders are unchanged (inspected units are never ordered).
- `SelectionManager.build_reason(type)` now follows BuildGrid: `prerequisite_reason`, crystals, then `limit_message`
  (walls now say `Wall limit reached` in the build menu instead of `Population limit reached`).
# Step 12 (task 12.C1, RiverSystem + Crown Hollow map changes, from systems-coder)
- `tests/test_4_s1.gd` line ~127 still expects both crown drops within 2 m of `(0, 3)`; map-fill.md 2.3 moved them to
  `Skirmish.CAMP_DROP_SPOTS` = Warden Scale `(2, 2)`, Ember Draught `(-2, -2)` (`CAMP_DROP_POS` is now their centre `(0, 0)`).
  Please check each pickup against `CAMP_DROP_SPOTS[i]` instead (the only 4.S1 failure).
- Glue: none. skirmish.gd creates the RiverSystem (under the NavigationRegion3D, before the bake), CapturePoints (before the
  bake), CampManager / EpicBeasts / CritterHerds (after the bake, children of the level), all load-guarded, messages to the HUD.
  Flags `river_enabled` / `points_enabled` / `camps_enabled` / `beasts_enabled` (missions false): for `--no-mapfill` set the
  first three false before `add_child` (river off = the step-11 forest, caches back at `CACHE_SPOTS_NO_RIVER`).
- main.gd `_build_ground`: the ground plane no longer casts shadows (12.V2 request: keeps the river discard out of the
  shadow cascades).
- Pathfinding note for 12.L2 fairness runs: Godot's own `map_get_path` corridor choice is not optimal and is NOT mirror
  symmetric (up to ~10 % between mirrored targets even with map fill off, e.g. keep -> centre); the navmesh itself is
  symmetric (test_12_c1 measures the geodesic on the baked navmesh: 0.00 % over 33 mirrored targets).
# Step 12 (task 12.V25, map-fill VFX, from tech-artist)
- **Glue (12.L2)**: add one node to `scenes/skirmish.tscn`, next to `TradeVfx`: `[node name="MapFillVfx" type="Node3D" parent="."]`
  with `script = ExtResource(...)` -> `res://art/vfx/mapfill_vfx.gd` (same pattern as the other VFX nodes; `main.tscn` does not
  need it). Nothing else: it joins group `"mapfill_vfx"` (the finished callers find it), loads 12.V31's
  `art/vfx/mapfill_beast_vfx.gd` as its child `BeastVfx` and forwards the beast ids, and connects itself (rescanned every
  second) to CapturePoints `blessing_started / blessing_ended` (runes), CampManager `camp_cleared` and every NeutralCamp
  `respawned`, and finds waders through the RiverSystem. Nobody has to call `camp_cleared` / `camp_respawn` / `blessing` /
  `wade` (a later direct call is deduplicated: same id + spot within 0.3 s plays once).
- Cost: idle ~0 (one hook scan per second, a wade pass over "units" spread over 12 frames: ~15 us / frame for 200 units);
  60 blessing runes ~70-150 us / frame while a blessing runs; 0 lights, 2 MultiMeshes + pooled meshes / particles.
- Headless note for tests that use the real skirmish: the RTS camera edge-pans to a corner (mouse at 0, 0); waders are
  only searched within 70 m of the camera, so `tests/test_12_v25.gd` phase 2 sets `edge_pan_enabled = false` + `focus_on`.
# Step 12 (task 12.A1, bot rules 11-13, from ai-coder)
- Glue: none. `Commander` creates `AIMapFill` (`scripts/ai/ai_mapfill.gd`) in its setup; it finds the step-12 systems by
  group (`"river"`, `"capture_points_service"`, `"camp_manager"`, `"epic_beasts"`, fallbacks `"capture_points"` /
  `"neutral_camps"` / `"beasts"`) every 5 s. `AIProfile.map_fill` (mission_01: false) switches rules 11-13 off.
- `tests/test_2_a1_rules.gd` (not mine to edit): its 3 Flame Guards are dropped at `GUARDS_POS (20, -55)`, 6 m from the new
  Bristleback Wallow N `(14, -57)`, so the creatures fight them and "a home soldier attack-moves within 6 s" fails. Same
  failure with the bot's `map_fill` off (checked), passes with the skirmish's map-fill flags off. Suggest `GUARDS_POS`
  `(28, -55)` (14 m from the wallow, same distance to the Gloom Hall slot) or `(40, -52)`.
- `perf_test` printed OVER BUDGET (19 ms / frame) during my runs while ~15 Godot runs shared the CPU; it runs `main.tscn`
  (no map fill, mission profile: rules 11-13 off), so please re-check it on a quiet machine.
# Art Lab warnings pass (tech-artist, 2026-09-26)
- Cinder Dragon (owner of `art/units/titans/cinder_dragon/`): `FlyerModel.ensure_shadow_blob` (flyer_model.gd) builds a
  new `PlaneMesh` per dragon (Art Lab B9m "1 mesh built per instance"). The Frost Dragon now overrides it and shares one
  blob mesh (`frost_dragon.gd`, static `_blob_mesh`); the same fix belongs in `flyer_model.gd` itself (static cached
  PlaneMesh, size 1 x 1; per-dragon size is the node scale, tint the instance uniform), then the override can go.

# Replay Lab determinism (lab review 2026-09-27, group B; details: docs/plan/replay-lab.md 'Determinism audit')
- **Step 0**: add `[navigation] avoidance/thread_model/avoidance_use_multiple_threads=false` to `project.godot`, then the
  perf test and `tests/test_replay_lab.gd` (expected PASS). Until then every replay drifts on unit positions after
  9-20 s: `tools/replay_lab/run_replay.ps1 -Record` shows it (docs/replay/lab/2026-09-27_selfcheck: end hash off at
  frame 540, `pos` only).
- CLAUDE.md "Keys": F8 = save bug report (replay-lab.md step 4). New lab commands for the Labs docs:
  `run_replay.ps1` (scorecard + history), `run_lab.ps1 -Validate` / `-DryRun`, `run_balance.ps1 -DryRun`.
- Perf Lab noise guard (2026-09-27 07:50, two samples): besides other agents' Godot runs, a process **AlsulicsService**
  used ~76 % of the whole CPU. Check it before the quiet baseline run (`run_perf_lab.ps1 -WaitQuietS 600 -Repeats 3`).
# T3 helpers + extra T3 units (game-designer, 2026-09-27; docs/design/t3-helpers.md)
- TH.L1 before TH.G1 / TH.S1: freeze section 12 in CLAUDE.md: `HelperType` (`data/helpers/`, gameplay), `Helper extends Champion`
  (groups `"units"`, `"champions"`, `"helpers"`, `is_commandable()` false, level = bonded wizard's level, stances escort /
  vanguard / home), `HelperRoster.for_team(team)` (systems, `scripts/buildings/helper_roster.gd`), `helpers_enabled` /
  `t3_expansion_units` flags (missions false), `HelperVfx`, new status `disguised` + `Unit.is_disguised_for(team)`,
  `UnitType.disguise_as_worker` / `lifesteal_pct`, `Tavern.wonders_for` / `hire_wonder` (the neutral Genie).
- Keys line: **F4** = centre on the helper (twice = inspect). Keep card r1c4 **N** after the Citadel = `Call <helper>` / `Revive`.
- Owner rows: `data/helpers/` + `scripts/units/helper*.gd` -> gameplay-coder; `art/units/helpers/`, `art/vfx/helper_*` -> tech-artist;
  `data/cinematics/helper_*.tres` -> four-wizards-high.
- Cross-spec edits TH.D2 will make (game-designer): `titans-2.md` 5 (Maelis leaves Elder Circle C, Briar Roc takes it),
  `level-boons.md` (41st boon `sworn_bond`, `requires &"helper"`), `levels.md` victim row. Story: Aldra's 2-line M2 patch for 19.D2.
- Open with the user (5 questions at the end of the spec): Ice helper (Aldra is new), what "campaign 3" means, the unit picks
  (spy / vampire / genie placement), control mode, timing anchor (E at level 4 vs level 6). Build nothing until Q3 is answered.
- Balance Lab needs a `helpers` variant key and a `rush_t3` bot profile (section 11).

# Level boons (game-designer, 2026-09-27; docs/design/level-boons.md)
- LB.L1 before LB.G1: freeze section 11 in CLAUDE.md (Stats `luck` + `spell<N>_power/cooldown/radius/duration_pct`, BoonType / BoonBook, `Events.boon_taken(wizard, boon_id, tier)`, owner row `scripts/boons/` + `data/boons/` -> gameplay-coder). Keys line: **Ctrl+Z / Ctrl+X / Ctrl+C** = take boon 1 / 2 / 3, **Ctrl+V** = reroll, **Ctrl+Space** = show / hide boon panel (only while a pick is pending). Balance Lab needs a `boons` variant key (section 13). Replay Lab must record boon picks / rerolls as inputs.
