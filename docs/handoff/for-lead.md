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

# F7 bots (ai-coder, 2026-10-12)
- `tests/test_10_a2.gd:165` reads the old tracker meta: change `t1.get_meta(&"contract", null)` to
  `t1.get_meta(&"_contract", null)` (TrackerContract now sets `_contract`; the guild's meta is now `_tracker_contract`).
- saved_state users in scripts/ai: `Commander` (key `commander:<team>`, row -> Building map saved as node refs that
  SaveWorld encodes with its ids) and `TrackerContract` (key `tracker_contract:<team>:<kind>`, static `create_for_save`
  = `HuntersGuild.restore_contract` + saved time left, nothing charged; a refund-only stub when the guild can't).

## SC2 console HUD (ui-coder, 2026-10-13, SC2.U1-U5)
- `project.godot` (yours): ui-sc2-console.md 5 wants tooltips after 0.25 s: `gui/timers/tooltip_delay_sec = 0.25`.
- `tests/smoke_test.gd` / `perf_test.gd` unchanged and passing; the UI Lab cannot check 2560x1440 / 3440x1440 on the
  1920x1080 laptop (windowed sizes are skipped, the headless lab waits forever on `frame_post_draw`): those sizes are
  covered by `tests/test_sc2_console.gd` (the lab's FAIL rules on the live HUD at 1600x900 and 2150x900 virtual).
- `tools/ui_lab/ui_lab.gd` (no owner listed): its HUD shots sit behind the STR / INT pick (the game is paused, the
  panels never refresh). Picking a path in `_run_resolution` before the match clock (`StrIntPath.of(hero).choose(&"str")`,
  as tests/test_ui_card_hotkeys.gd does) would give live HUD shots.

## WS2.U1 (ui-coder, 2026-10-13): UI Lab shot `ws_buy`
- `tools/ui_lab/` is not in ui-coder's folders, so the `ws_buy` shot runs from `tests/test_ws_ui_lab.gd` (windowed, same
  UILabChecks rules as `ui_lab.gd _capture`; Fire + Ice, en + fr, scorecards in `docs/ui/lab/ws_buy/<lang>/`). If you
  want it inside the UI Lab proper: add a `ws_buy` screen to `ALL_SCREENS` that loads `scenes/wave_strike.tscn` and reuses
  the setup of `test_ws_ui_lab.gd _shot` (buys, Stronghold forced, `stats[0].held_horn = 12`).
- 2560x1440 / 3440x1440 could not be checked on this 1920x1080 laptop (the layout is anchored: cards from the left of the
  console zone, right column from its right edge; the emblem fills the middle).

## 2026-10-13 systems-coder (WS4.C1): data/wave_strike/ ownership
The hook (`.claude/hooks/owners.json`) does not give systems-coder `data/wave_strike/`, so `card_upgrades.tres` could not be
written. The 16.1 / 16.2 data lives as the export defaults of `scripts/world/wave_strike/wave_upgrade_table.gd`
(`load_default()` uses them when the .tres is absent). Please either add `data/wave_strike/` to systems-coder in
owners.json (CLAUDE.md already lists WS data under the task) or save the defaults once:
`ResourceSaver.save(WaveUpgradeTable.new(), "res://data/wave_strike/card_upgrades.tres")`.

## UR.U1 / UR.U2 (ui-coder, 2026-10-14)
- CLAUDE.md "Keys": the Hall-only `+` page is now the research page of an own Hall / Stables / keep: `+` (=/numpad +)
  opens it, a unit's training key opens its unit page, there Z = its "+", X C V B = its rows, then the Stables rank-3;
  the same key on a running row cancels it (full refund); Esc = one page back, `+` closes both. Public API on
  SelectionManager: `research_units(b)`, `research_entries(b, unit_id)`, `open_research_unit`, `research_back`,
  `press_research_slot`, `buy_research`, `rank_up_research`, `research_running_at(b)`, `cancel_research_at(b)`.
- UI Lab (`tools/ui_lab/`, not mine): `hud_keep` shows "Nothing selected" at 1600 x 900 because the STR / INT path panel
  is still open when the keep is selected (the lab never picks a path). A `hud_research` screen (keep selected, research
  page open, a row running) would cover UR.U1's "UI Lab hud_keep with the page open"; until then
  `tests/test_research_ui.gd -- shots=<dir> [lang=fr]` (windowed, `--resolution 1600x900`) takes those shots and runs
  the lab's frame / overlap / off-screen checks on them.
- `tests/test_ui_card_hotkeys.gd` updated (keep card has `plus_page`; research page / unit page keys).
- `data/ui/unit_guide.json` (the 4 bowmen "Hall research" abilities removed) and `data/i18n/fr/*.po` (74 row texts,
  refusals, templates) were edited for UR.U2 as the task says; `.claude/hooks/owners.json` does not list them for ui-coder.

## CI speed + load-proof perf gate (four-wizards-high, 2026-10-14): STAGED, the lead installs
The owners hook blocks this agent from `tools/ci/`, `tests/perf_test.gd` and `.claude/skills/`, so the finished files
are staged under `docs/handoff/ci-speed/` with the target paths mirrored. Install (diff first if tools/ci changed since):
```powershell
$s = "docs\handoff\ci-speed"
Copy-Item "$s\tools\ci\*.ps1" tools\ci\ -Force   # dep_index, select_tests_legacy, measure_selection (new); select_tests, ci, ci_quick, test_select_tests
Copy-Item "$s\tests\perf_test.gd" tests\perf_test.gd -Force
Copy-Item "$s\.claude\skills\ci-suite\SKILL.md" .claude\skills\ci-suite\SKILL.md -Force
Remove-Item -Recurse -Force $s                    # no .gd left in docs/ for Godot to import
powershell -NoProfile -File tools\ci\test_select_tests.ps1   # must print PASS (27 checks)
tools\ci\measure_selection.ps1 -Commits 10        # per-commit old / reach / near numbers (agents cannot run git)
```
All files are LF like the originals. Numbers and usage: the agent's report and the updated ci-suite skill.

## From tech-artist G1 (graphics tiers on the lighting rig, 2026-10-15)
- `docs/art/lab/g1_lighting/` got 16 `*.png.import` files from an editor import before I added its `.gdignore`; they are junk (delete them, do not commit them).
- Ultra's GPU margin is thin (~15 ms, ~65 fps on the 3070 Laptop); most of Ultra's extra cost over High is the viewport's 8x MSAA (ui-coder, `GameSettings.apply_viewport_quality`). 4x MSAA + SMAA on Ultra would buy ~3-4 ms if a playtest shows dips.
- `LightingRig.apply` now shows a per-rig copy of the preset Environment: missions that tint `rig.world_environment.environment` (mission_04 storm dusk, e5 `tint_light`) no longer leak the tint into the shared `world_env.tres` for the next mission in the same session.


## From tech-artist G-C champions (2026-10-15)
- `tests/test_9_v2.gd` (Oathwall model test, line `_expect(acc[3] <= 2950, ...)`) still caps the Oathwall at the 9.V2 soldier budget (2500 + face). The G-C hero armour measures 5401 (variant A: body ~4600 + face 746 + door 844), same class as the Wayfinder (6742) / Mender (8353); Art Lab B4 = soft WARN, 0 FAIL. Please raise it to 5600 (or delete the cap: `tests/test_gc_champions.gd` now holds per-champion caps). It is the only test that fails on this pass.
- `ChampionPalette.foldable` now also folds `art/units/nature/nature_living.gdshader` (the G-C Nature move of the nature_* palette files had left the Wildcaller drawing up to 8 unfolded surfaces per pivot; its UVs carry no Nature tag, so nothing of the look is lost).

## From tech-artist G-D ambient life (2026-10-15)
`AmbientLife` (art/environment/ambient/ambient_life.gd, docs/art/gd_ambient.md) installs itself behind a static
`ensure(level)` (null headless / at Low; idempotent). Hook for `scripts/world/main.gd`:
- constant next to `GROUND_DETAIL_PATH` (line ~20):
```gdscript
const AMBIENT_LIFE_PATH := "res://art/environment/ambient/ambient_life.gd"
```
- in `_ready`, right after the G2a GroundDetail block (after `gd_script.call(&"ensure", self)`):
```gdscript
	# G-D ambient life: high flocks, butterflies / fireflies, leaves, dust, mist, ripples, snow (draw-only; Low / headless = no node).
	if ResourceLoader.exists(AMBIENT_LIFE_PATH) and not _SIM.enabled:
		var al_script := load(AMBIENT_LIFE_PATH) as Script
		if al_script and al_script.has_method(&"ensure"):
			al_script.call(&"ensure", self)
```
Wave Strike (extends main.gd) gets it too; headless tests / labs never build it. Shots: commit only
`docs/art/lab/gd_ambient/gd_ambient_sheet.jpg` + the 4 PNGs named in docs/art/gd_ambient.md (the rest stays local).

## From tech-artist G-D autumn maps (2026-10-15)
Autumn maps (Quartermeet, Fourfold Hollow, Ashwind Reach) now turn golden in game through
`art/environment/autumn/autumn_swap.gd` `ensure_for_level(level)` (docs/art/gd_autumn_maps.md): reads the layout /
catalog biome, swaps the shared materials, paints the ground, sets the warm rig to preset_autumn, adds an `AutumnLook`
child whose `_exit_tree` restores every shared material exactly (last autumn level out restores; never in sim mode;
idempotent; also headless: `tests/test_gd_autumn_maps.gd` proves no leak into the next map). Hook for
`scripts/world/main.gd`:
- constant next to `AMBIENT_LIFE_PATH` (line ~21):
```gdscript
const AUTUMN_SWAP_PATH := "res://art/environment/autumn/autumn_swap.gd"
```
- in `_ready`, right BEFORE the G2a GroundDetail block (after the CritterSystem block; the map, its ground and the
  LightingRig exist there, and GroundDetail then bakes the autumn ground colours):
```gdscript
	# G-D autumn maps: an autumn biome (layout / catalog) swaps the shared materials, the ground and the rig preset;
	# its AutumnLook child restores the shared materials when the level leaves (no leak into the next map).
	if ResourceLoader.exists(AUTUMN_SWAP_PATH) and not _SIM.enabled:
		var autumn_script := load(AUTUMN_SWAP_PATH) as Script
		if autumn_script and autumn_script.has_method(&"ensure_for_level"):
			autumn_script.call(&"ensure_for_level", self)
```
Not before `_build_map` (no ground yet). After the AmbientLife block also works (the test calls it on `ready`, after
the whole `_ready`). Wave Strike (Ashwind Reach) gets it through main.gd too. Shots: commit only the 2 PNGs in
`docs/art/lab/gd_autumn/` named in docs/art/gd_autumn_maps.md.

## G-F r2 item 15 (tech-artist, 2026-10-15): the m00 grey disc is MissionBase.flash_ring

Found (node log at the m00 start, `docs/art/lab/gf_r2_ground/tools/gfr2_ground_shots.gd --mode=m00`): at t ~6.8 s a
`CylinderMesh` child of the mission node (`/root/Mission00/@MeshInstance3D@...`, StandardMaterial3D). It is
`MissionBase.flash_ring(pos, SPOTLIGHT_RING_RADIUS = 2.5)` called by `_on_spotlight_unit` when the first Flame Guard
appears (m00's spotlight, trigger `start`): a flat white disc r 2.5 (5 m wide), alpha 0.7 fading over 1 s, **fog not
disabled**, so the night fog turns it into a translucent mid-grey disc. Owner: `scripts/campaign/mission_base.gd` (lead /
systems-coder). Request:
- In `flash_ring(pos, radius)` replace the body with the art helper (new file, `art/vfx/mission_flash_ring.gd`, static,
  draw only: a thin warm-gold rim that grows 0.7 -> 1.0 r and fades in 1 s, additive, `disable_fog`, a soft warm light):
```gdscript
func flash_ring(pos: Vector3, radius: float) -> void:
	MissionFlashRing.play(self, pos, radius)
```
- In `_gold_ring` add `mat.disable_fog = true` (the gold torus under the spotlit unit greys the same way at night).
Every other flash_ring caller (missions) gets the same rim; nothing reads the old disc node.

## G-F r2 item 10 (tech-artist, 2026-10-15): the Muster Pad plate (ui-coder) and the forest grid (systems-coder)

1. **Pad plate (ui-coder, `scripts/ui/wave_strike/pad_view.gd` `_build_plate`)**: the plate is an unlit flat
   `STONE` (0.30, 0.28, 0.27) quad, so it reads as a grey slab at every zoom. The art is ready:
   `art/environment/lane_dressing/muster_plate_mat.tres` (lit worn flagstones, one flag per 1.5 m cell so the drawn grid
   sits on the joints; it reads the view's vertex colour as a value multiplier, so the rim / sides stay darker). Request:
   in `_build_plate` use it for the "Plate" node instead of `unlit(Color.WHITE, false, true)`, load-guarded:
```gdscript
const PLATE_MAT := "res://art/environment/lane_dressing/muster_plate_mat.tres"
...
var plate_mat: Material = load(PLATE_MAT) as Material if ResourceLoader.exists(PLATE_MAT) else null
_mesh_node(st.commit(), plate_mat if plate_mat else unlit(Color.WHITE, false, true), "Plate")  # LOC_IGNORE
```
   Keep the grid lines / chevron / tokens unlit on top (unchanged). The yard round the plate (flagstone apron, 4 corner
   banners) is already in LaneDressing (art).
   **DONE (ui-coder 2026-10-15):** `pad_view.gd` `PLATE_MAT` load-guarded on the "Plate" node (+ `generate_normals()` for the lit
   shader), old unlit fallback; grid / chevron / tokens unchanged. test_ws_pad, test_ws_ui, test_ws_director PASS.
2. **Forest grid (systems-coder, optional)**: `WaveStrikeLevel._add_ws_block` still plants forest blocks on a 4.6 m grid.
   The art now replants them in windowed runs (`art/environment/lane_dressing/forest_replant.gd`, via LevelLooks, after
   `EnvProps.commit()`: treeline + clusters + glades, 3 sizes, every tier). Nothing is needed; if the grid code is ever
   touched, it can stay as is (the replant drops every instance inside a forest block + 1.8 m and plants its own).

## From tech-artist, G-F Shadow leftovers (2026-10-15): Building's own site outline (scripts/buildings/, systems-coder)
Every construction site draws TWO footprint squares: the model's glowing outline (art, now calm on Shadow:
`SiteOutline`) and `Building._build_outline()` (`scripts/buildings/building.gd` ~l.703): four 0.1 m unshaded
`StandardMaterial3D` bars in the full `team_color` (violet on Shadow), shown by `_update_look()` while `site`.
With a model it is now the loudest line of a Shadow site (`docs/art/lab/gf_shadow_left/after/site_tower_p000_z12.jpg`:
the inner square). Request, precise:
1. In `_update_look()`, show `_outline` only when there is no art model: `_outline.visible = site and not
   (_model and _model.has_method(&"set_construction_progress"))` (the model already draws its own site outline,
   pad and scaffold; the placeholder box art still needs the line).
2. If a footprint line must stay with a model (placement read), grade it instead: `mat.albedo_color =
   Color.from_hsv(team_color.h, minf(team_color.s, 0.4), minf(team_color.v, 0.7))` and `w := 0.05`.
Tests that look at `BuildOutline` (`test_10_v*`, `test_13_v25`, `test_a2_6`) read the MODEL's node of that
name, not Building's `_outline`, so option 1 does not touch them.

## From tech-artist, G-F review 2 item 9 (2026-10-15): Thornwater identity, the data side (optional, four-wizards-high)
The art now gives Thornwater its own look in windowed runs (`art/environment/thornwater/`, via LevelLooks; note
`docs/art/gf_thornwater.md`): marsh-meadow ground, peaty water, reed beds, thickets, a fen-wood border belt and four
thorn spires in the moat. It keys on the layout id `thornwater`, so nothing is needed. Data ideas that would go further
(World Forge `data/maps/thornwater.map`, then the gate):
1. **Catalog / layout biome**: `biome=meadow` -> `marsh` (catalog entry + `.map` header) would let biome-driven art
   (AmbientLife mood, future scatters) treat it as wet; the hook text could name the reeds / thorns ("A winding river
   through a reed marsh..."). Check first that nothing keys gameplay on `meadow`.
2. **Border shape**: the map edge is still a straight 120 m square; a few `block kind=cliff` bays / outcrops (2-4 m
   deep, mirrored) would break the box for real (the art can only dress it).
3. **Corner silhouettes**: the shared horizon (`art/environment/horizon/`, baked for Crown Hollow) shows the same
   aqueduct (W) and octagonal pond (E) on every map. A per-map horizon or hiding those on non-Crown-Hollow maps is
   an art task (tech-artist) if wanted; noted in the gf_thornwater note.

## From tech-artist, G-F review 2 item 11 (2026-10-15): m02 Sentinel ice shells (scripts/campaign/mission_02.gd)
The frozen Emberguard blocks and the snow border need nothing: the existing `FrozenLook.dress_level(self)` call at the
end of `_build_map()` now also dresses every block (`FrozenBlockArt.dress_block`) and adds the snow-capped cliffs
(note `docs/art/gf_m02.md`). The two Sentinel shells are made later (`_spawn_sentinels`, after the navmesh bake), so
they still show the old cyan box. One load-guarded hook, at the end of `_add_shell(u)`, right after `u.add_child(mi)`:
```gdscript
	# G-F review 2 item 11: faceted ice shell from the tech-artist (draw-only; _shatter_shell still frees "IceShell").
	if ResourceLoader.exists("res://art/environment/snow/frozen_block_art.gd"):
		var fba := load("res://art/environment/snow/frozen_block_art.gd") as Script
		if fba and fba.has_method(&"dress_shell"):
			fba.call(&"dress_shell", mi)
```
It keeps the node name, position (y 1.8) and collider-free setup, so `_shatter_shell` and saves are unchanged.
Optional (systems-coder, cosmetic): `scripts/campaign/frozen_emberguard.gd` header still says "Placeholder art (M9.V1)";
the art now replaces its box / capsules / stump in place (hidden, not freed, so `_on_thawed` / `load_row` still work).

## From tech-artist, G-F Quartermeet identity (2026-10-15): nothing blocking
Quartermeet now has its own harvest-highland look (`docs/art/gf_quartermeet.md`, `art/environment/quartermeet/`,
one LOOKS entry in `art/environment/level_looks.gd`, `tests/test_gf_quartermeet.gd`). Optional follow-up for the
horizon owner: the horizon backdrop (`horizon_mat`, art/environment/horizon/) still shows the shared autumn orange on
Quartermeet; a per-map tint (paler gold / slate hills) keyed on layout id `quartermeet` would finish the look. It must
leave Ashwind Reach unchanged.

## 2026-10-15 G-F crown isle variants (tech-artist)

The Crown Isle now has a per-map variant (`docs/art/gf_crown_isle.md`, `art/environment/crown_variants/`,
`tests/test_gf_crown_isle.gd`), hooked from `CrownPedestalArt._ready` (no lead hook needed). New `class_name
CrownIsleVariant`: run `--import` once. Optional follow-up for the bridges owner (`art/environment/bridges/`): a
timber-plank deck variant of the crown lane bridge / steps for Thornwater; today they are only repainted (peat-dark,
mossier stone) through level-local mesh copies.

## G-F review 3 item 3 (systems-coder, 2026-10-15): building HP bar hover
`Building.set_hp_bar_hover(on)` now exists (same as Unit). `SelectionManager.set_hovered_unit` only receives `unit_at()`
(Units), so buildings never get hover today. For ui-coder (scripts/ui/selection_manager.gd ~l.350): also pass a hovered
building (the method is called through `has_method`, so a Building works as-is). Selection and hits already work.

## Campaign review 2026-10-16, weakest missions (systems-coder): new player text needs French
e2m3 / e4m2 / e2m5 / e5m1 got new lines, messages and hints (details in each script's header "Campaign review fixes").
`data/i18n/` is not mine: please run `tools/i18n/extract_strings.gd '--' merge` and add these (proposed French):
- e2m3: "The last wagon is always the heaviest, Vessa. My knives can smell it from here." = "Le dernier chariot est toujours
  le plus lourd, Vessa. Mes couteaux le sentent d'ici." · "Everyone on the wagon! If it stops, we stop. If it burns, I burn
  something bigger." = "Tout le monde sur le chariot ! S'il s'arrête, on s'arrête. S'il brûle, je brûle quelque chose de
  plus gros." · "The Grand Tribute sets out. Malrik's knives wait on the Lodge road: escort the wagon!" = "Le Grand Tribut
  part. Les couteaux de Malrik attendent sur la route du Pavillon : escortez le chariot !" · "Ambush on the Lodge road! They
  are going for the Grand Tribute" = "Embuscade sur la route du Pavillon ! Ils visent le Grand Tribut" · "The Grand Tribute
  is lost! Take the gold back before the thieves do" = "Le Grand Tribut est perdu ! Reprenez l'or avant les voleurs" ·
  "Escort the Grand Tribute: %d m to the Lodge" = "Escortez le Grand Tribut : %d m jusqu'au Pavillon".
- e4m2: "The slow ones at the back, my knives. Always the slow ones." = "Les lents, à l'arrière, mes couteaux. Toujours les
  lents." · "Hush's knives at the brook crossing! They are going for the stragglers of convoy {n}" = "Les couteaux de Hush au
  gué du ruisseau ! Ils visent les traînards du convoi {n}".
- e2m5: "The stones up the slope still remember the sun! Carry it down to him, girl, a shard at a time!" = "Les pierres de la
  pente se souviennent encore du soleil ! Porte-le-lui, petite, un éclat à la fois !" · "Walk Vessa onto a lit Sunstone to
  take a sunshard, then carry it to the Door: the Door strikes the jailer. Unlit Sunstones light like beacons." = "Menez
  Vessa sur une Pierre-soleil allumée pour prendre un éclat de soleil, puis portez-le à la Porte : la Porte frappe le
  geôlier. Les Pierres-soleil éteintes s'allument comme des fanaux." · "Sunshard taken: carry it to the Door" = "Éclat de
  soleil pris : portez-le à la Porte" · "Carry the sunshard to the Door" = "Portez l'éclat de soleil à la Porte" · "Carry
  sunshards from the lit Sunstones to the Door: each one makes it strike" = "Portez des éclats de soleil des Pierres-soleil
  allumées jusqu'à la Porte : chacun la fait frapper".
- e5m1: "Behind me, girl. Nobody crosses this bridge while I stand on it." = "Derrière moi, petite. Personne ne traverse ce
  pont tant que je suis dessus." · "And what do I do? Watch?" = "Et moi, je fais quoi ? Je regarde ?" · "You throw fire over
  my shoulder. That is what a spark is for." = "Tu lances le feu par-dessus mon épaule. C'est à ça que sert une étincelle." ·
  "That is how a bridge is held. One sword in front, one spark behind." = "C'est comme ça qu'on tient un pont. Une épée
  devant, une étincelle derrière." · "Years later, she would hold a bridge of her own, and remember who had stood in front
  of her." = "Des années plus tard, elle tiendrait son propre pont, et se souviendrait de celui qui s'était tenu devant
  elle." · "Torches on the west road: reivers are coming for the Millrace farms!" = "Des torches sur la route de l'ouest :
  les pillards viennent pour les fermes de Millrace !" · "Vey holds the Old Bridge: stay behind him and throw Fireballs. They
  cost no mana near him while he stands." = "Vey tient le Vieux Pont : restez derrière lui et lancez des Boules de feu.
  Elles ne coûtent pas de mana près de lui tant qu'il tient."
(Use the glossary's names for Lodge / Sunstone / Old Bridge / Millrace if they differ from mine.)
- e2m5 keeps the old B3 lance (Vessa at the Door with Vey, now 15 / 18 / 21 s) only because tests/test_e2m5.gd `_lance` and
  test_e2m5_sim.gd script it; once those tests carry shards, `_tick_lance` can go.
- test_save_metas: the metas `e2m3_grand`, `knife_convoy` and `walker_ix` are gone. The Grand wagon is now known by its
  saved modifier `mission:grand_tribute`, the knives' target is `_knife_convoy` (transient), and the walker jitter reads
  the walker's place in its saved convoy list. Nothing for you to add to SAVE_METAS for these.

## Campaign review 2026-10-16, e8m2 / e8m3 (systems-coder)
1. **Sim windows** (tests/test_e8_sim.gd is yours): e8m2 is cut to ~20 min (march floors halved, bars faster) and e8m3's
   phases now follow the King's HP (4:00 lock-out, no 17:00 / 25:30 floors), so the old `TARGET` windows (e8m2 25-30 min,
   e8m3 28-35 min) no longer fit. Measured play time (normal): e8m2 20:20; e8m3 20:20 / 21:19 (seeds 0 / 2). Proposed:
   `"e8m2": [1080.0, 1500.0, 75.0]` (18-25 min) and `"e8m3": [1080.0, 1560.0, 60.0]` (18-26 min). `PASSIVE_LIMIT` can stay
   (both passive runs PASS: e8m2 lost at 26:12, e8m3 no win).
2. **French** (`data/i18n/` is not mine; run `tools/i18n/extract_strings.gd '--' merge`, proposed French):
   - e8m2 march beats: "Stand back from the pylon. No, further. Further than that." = "Reculez du pylône. Non, plus loin.
     Plus loin que ça." · "Quietly now. The Hollow hears footsteps better than it hears knives." = "Doucement, maintenant. Le
     Hollow entend les pas mieux que les couteaux." · "Hold still, all of you. That includes the rubble." = "Ne bougez plus,
     tous. Ça vaut aussi pour les gravats." · "Roots, take their feet. We walk, they wait." = "Racines, prenez-leur les pieds.
     Nous marchons, ils attendent." · "The Hollow answers the {kingdom} march!" = "Le Hollow répond à la marche {kingdom} !"
   - e8m3: "The {kingdom} Key-Ward is at {pct} %!" = "La Garde-clé {kingdom} est à {pct} % !" · "The {kingdom} Key-Ward is
     mended." = "La Garde-clé {kingdom} est réparée." · "Ward Mend: stand beside a Key-Ward with your wizard, no Host near,
     for 3 s (+25 %, every 60 s). It relights a broken one." = "Réparation de garde : placez votre sorcier près d'une
     Garde-clé, sans Host autour, pendant 3 s (+25 %, toutes les 60 s). Elle rallume une garde brisée." · "Ward Mend ready" =
     "Réparation de garde prête" · "Ward Mend {time}" = "Réparation de garde {time}" · "Never let two keyholes fall at once
     ({wards}) · {mend}" = "Ne laissez jamais tomber deux serrures en même temps ({wards}) · {mend}" (replaces the old
     "({wards})" key). Use the glossary's word for Key-Ward / Host if it differs.

## Campaign review 2026-10-16: enemy rosters m02-m04, e2m1, e2m2, e2m4 (systems-coder, cr-waves)
Waves now grow across episodes 1-2 (same crystal value per wave within 25 %, `tests/test_cr_waves.gd`):
m02 Bleakbows + the first Gloom Deacon; m03 Hexweavers + Gloam Riders (stake raid = 2 Shades + 2 Bleakbows); m04 Hollow Oathsworn,
raids = Duskbolt Harriers (2 / 1); e2m1 Barrow Ghouls / Knights, Oathsworn, raids = ghouls rising 16 m from the target
after a 3 s ring; e2m2 Gloam Rider raids (+1 on hard), Nightblood Reavers, named elite Grave Marshal Corvane (local
type `grave_marshal`, Barrow Knight base, blows apply `marked`) with the Vice knights; e2m4 Barrow Ghouls (G4, W1),
Barrow Knights, Oathsworn, Veilborn Dreadrider instead of the 2 late Knights.
- For the game-designer: the wave tables in docs/design/mission-02.md / -03 / -04 / e2m1 / e2m2 / e2m4 still list the
  old rows; please update them from the `WAVE_ROWS` / `WAVES` constants.
- For i18n: the new display name "Grave Marshal Corvane" needs a msgid / French line (extract_strings merge).

## Campaign review 2026-10-16: the ending (cr-ending)
- `ep8_ending_b`: the turn line "Nobody sits. Not ever again." is now said by the player's wizard. The format already had
  it: shot `branch=<flag>` / `branch=!<flag>` (`CinematicShot.branch_flag`, a failed branch takes 0 s) on the bool flags
  `e8_road_fire / shadow / ice / nature` the road picker writes. E15 is split: the turn shot E15V / E15M / E15T / E15Y
  (4.8 s, one per road, voiced L1_<wizard>) + the shared strike shot E15 (7.2 s, same camera). The player's own fate
  moves last: E17 / E18+E18B / E19 carry `branch=!e8_road_<k>`, copies E17L / E18L+E18BL / E19L play after E20 on their
  road (Vessa's E20 is last already). No CampaignState / STORY_FILMS / FILM_BRANCHES change, no new film, stage scene
  untouched (same cast); only the .cine + the baked .tres.
- Notes: one road plays 67 s; cine's own tools sum every branch (~106 s), so the header says `length=64..108`.
  `run_cine check` = 0 FAIL, 2 WARN (RT1 / RT2: the runtime partner check plays the dev save, where no road flag is
  set, so it drops the branch shots and its timeline differs from cine's: expected, not a runtime bug). A save with no
  `e8_road_*` flag (only the cine tool; the game always has one) drops the turn shot and starts at the strike.
- Credits (`scripts/campaign/e8_story_screen.gd`, kind credits): a 90 s slow roll (`ROLL_SECONDS`): title, the four
  wizards (portrait from `art/portraits/<w>.png`, name in the kingdom colour, "Kingdom of X", "Relic: <ItemType name>",
  the player's road last), the five thank-you lines, "Made with the Godot Engine.", "Four hands keep the peace, not
  one."; Esc / Enter / Space / a click skip to the end panel (other keys no longer advance). Public: `is_rolling()`,
  `roll_time()`, `skip_credits()`, static `roll_order(road)`, `relic_name(k)`. 7 new campaign.po lines translated.
  Still open from the doc: mission-e8-03.md wants the credits skippable only after a first full viewing, and names /
  roles on the roll (JS has not given any): not done.
- Test: `tests/test_cr_ending.gd` (4 roads: speaker + shot order + length; credits length, roll order, Esc / click skip).

## Campaign review 2026-10-16: readability + roster (cr-read, systems-coder)
- New / changed player text (English in the logic, needs `tools/i18n/extract_strings.gd '--' merge` + French):
  e6m4 "The Master is interrupted: clear the white circle!", "The Hollow counts: {n}" (Label3D, Loc.t),
  "The Master is interrupted: %d %% (clear the circle)", "Nothing may break the seal (%d %%, the Hollow counted %d)",
  the Bramblesage hint (Pollen Haze now blinds the Ruin Slingers), unit name "Ruin Slinger";
  e7m3 "Every pit you hold pays gold (+%d / min each). Every row you leave costs lives." (replaces the old tithe line),
  "{row} is being taken: send soldiers to its bell!"; e6m1 the Lake Rise hint (HINT_LAKE), unit name "Deep Warden" and
  two lines said through `say()` (subtitle only, no voice clip): Aldra "They're coming up through the ice! Stop them out
  there, my lord. Stone that stands still on the ice goes under." / Torvald "Then nobody walks past the floes. Shields
  onto the ice." If they should be voiced, data/voice/lines/e6m1.json needs two rows (L31 / L32) and I switch to say_l.
- The Ruin Slinger (`ruin_slinger`, a Bleakbow copy, `MissionE6_04.make_slinger`) is a mission-local type: no
  data/units file, no Unit Guide block (not a player unit).

## From systems-coder, campaign review 2026-10-16: e7m2 / e7m4 (cr-e7)
- **Sim time windows** (tests are lead / shared files, I did not edit them): the review asked for shorter missions, so
  `tests/test_e7m2_sim.gd` line 92 (18-24 min play) and `tests/test_e7m4_sim.gd` line 93 (25-30 min play) now fail on
  time alone. Please widen them to about 12-24 min (e7m2: about 13:40 play now, was 18:32) and 19-28 min (e7m4: about
  21:20 play now, was 25:19). The comment on line 4 of test_e7m2_sim still names DUEL_FLOOR, which is gone.
- **test_save_metas**: add `e7m4_great` (set on the units of Malrik's great assault M5 in e7m4; a load must keep it so
  that P4's goal still counts them) to SAVE_METAS. The other unlisted metas it reports (e2m3_grand, knife_convoy,
  walker_ix) come from the other agents of this wave.
- **Nav freeze seen in e7m2 runs, under heavy machine load**: sometimes no unit moves (the path is empty, and
  "query made before first map synchronization"). It happens with the old e7m2 script too, so it is not this change.
  It looks like a harness / main.gd nav-sync timing issue. Since e7m2 now has a causeway limit, a frozen run ends in
  defeat ("barricade") instead of a timeout.
- **i18n**: new player text in mission_e7_02.gd (Dacian soon, strongbox window / gone, causeway warn / holds, Sun Cleave
  hint) and mission_e7_04.gd (hunger 50 / 75 / 100, great assault broken, keep mend, hold objective). Please run
  extract + translate them. test_i18n was already failing before this wave (68 campaign keys).

## From systems-coder (cr-read), addendum: the nav freeze in e6m1 / e6m2 sims
- Same freeze as the cr-e7 note above: 3 of the first 4 Glasswater sims (e6m1 + passive, e6m2 open) froze from 0:00.
  A probe showed a baked region (602 polygons) while `NavigationServer3D.map_get_iteration_id(map) == 0` 20 s after the
  match start (the map never synced). Reruns under less load were clean (e6m1 18:57, e6m2 PASS).
- Stopgap in my files: `MissionE6_01.nav_watchdog(level)` (called from e6m1 and e6m2 ticks). If the map has still never
  synced after the match start, it calls `build_grid.request_rebake()` and pushes the warning "nav watchdog: ..." (3 tries
  at most). It has not fired in a clean run. Suggestion: move the same check into main.gd `_on_navigation_ready` / its
  tick for every level, then drop the mission copies.
