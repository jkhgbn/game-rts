# Perf Lab scorecard: vfx_storm (headless logic)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:16:46 · 1 run(s) (median) · seed 1 · 25 s measured · lab v1.0

Scenario: 40 v 40 fight + both wizards casting every spell each 0.5 s + every VFX manager's effects round-robin.

> **NOISY**: 25 other Godot process(es) (max 22 at once); other CPU load 93.1 %; 30 other Godot process(es) (max 27 at once); other CPU load 101.8 %. Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **FAIL** · perf score **41 / 100**

Frame avg **40.79 ms** · p95 182.00 · p99 219.44 · max 303.1 · hitches 307 · 1500 frames · units 38 · nodes 7417

Repeats (frame avg ms): [40.788]

## Improve next
1. **Split the Commander's worst think step**: Commander think tick median = 1.077 ms over 27 ticks (step memory). The worst step is `memory` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked. _(check A1)_
2. **Pool the VFX**: nodes were created under a VFX manager during the measure window (28 ({"GPUParticles3D":9,"MeshInstance3D":17,"Node3D":2})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
3. **Cheaper unit ticks**: 1.537 ms / frame over 94 nodes. shader parameter write (unit.gd:1948 in `_update_hp_bar()`, unit.gd:1949 in `_update_hp_bar()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `scripts/units/unit.gd` `_physics_process`: run target acquisition / aggro scans every 0.2-0.3 s with a per-unit offset instead of every frame, use a spatial hash for nearest-enemy, and skip idle units. _(hot list: `scripts/units/unit.gd`)_
4. **HUD refresh**: 1.531 ms / frame over 1 nodes. string formatting (selection_panel.gd:564 in `_update_hero()`, selection_panel.gd:567 in `_update_hero()`, selection_panel.gd:580 in `_update_hero()`). Fix: build strings only when the text changes. `scripts/ui/selection_panel.gd`: refresh labels / bars on signals or at 4-10 Hz instead of every _process, and only set text when it changed. _(hot list: `scripts/ui/selection_panel.gd`)_
5. **Hot script mapfill_wyrm_vfx.gd**: 0.796 ms / frame over 1 nodes. allocation (.new()) (mapfill_wyrm_vfx.gd:640 in `_start_breath()`, mapfill_wyrm_vfx.gd:1085 in `_start_blizzard()`). Fix: pool the object / node, or reuse a member instead of allocating per frame. _(hot list: `art/vfx/mapfill_wyrm_vfx.gd`)_
6. **Unit model animation**: 0.726 ms / frame over 33 nodes. shader parameter write (fire_model.gd:324 in `_set_ball_heat()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `art/units/fire/fire_model.gd`: animate at a reduced rate beyond 30 m and freeze off-screen (art-units.md 6.10); keep pivot writes <= 7 per frame. _(hot list: `art/units/fire/fire_model.gd`)_
7. **Logic frame over budget**: Frame avg 40.79 ms: start with the top rows of the hot list; the unit tick and NavigationAgent3D avoidance scale with the unit count. _(check F1)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (logic) | **FAIL** 0 | 40.79 ms | FAIL > 4.04, WARN > 2.80 ms (waves.md:82 (8 ms / 100 units, scaled) + lab default 1 ms VFX allowance; warn 5.5 / 100 (38 units)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | **WARN** 35 | 182.00 ms | WARN > 6.06 ms (1.5x the avg budget) |
| S2 | Frame p99 | **WARN** 35 | 219.44 ms (max 303.1 ms) | WARN > 8.08 ms |
| S3 | Hitches (> 33 ms) | **FAIL** 0 | 307 in 25 s (736.80 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P1 | AI commanders avg | PASS 100 | avg 0.028 ms, median 0.003, max 2.12 ms | FAIL > 0.600 ms, WARN > 0.450 (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1a | AI commanders worst frame | **FAIL** 20 | 2.12 ms | FAIL > 1.5 ms (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1b | AI commanders median frame | PASS 100 | 0.003 ms | WARN > 0.10 ms (lab target) |
| P2 | Epic beast brains avg | PASS 100 | avg 0.006 ms, median 0.004, max 0.68 ms | FAIL > 0.030 ms, WARN > 0.022 (map-fill.md:403 (8 beasts < 0.03 ms)) |
| P3 | Map fill services avg | PASS 98 | avg 0.079 ms, median 0.017, max 58.88 ms | FAIL > 0.200 ms, WARN > 0.150 (map-fill.md:398 (map fill < 0.2 ms: river 0.03, points 0.03, camps 0.02)) |
| P4 | Critters (game + cosmetic) avg | **FAIL** 0 | avg 0.224 ms, median 0.031, max 85.63 ms | FAIL > 0.110 ms, WARN > 0.083 (map-fill.md:398 + :404 (CritterSystem < 0.08, game critters < 0.03)) |
| P5 | Trade avg | **WARN** 40 | avg 0.097 ms, median 0.025, max 86.81 ms | FAIL > 0.100 ms, WARN > 0.075 (market-trade.md:128 (all trade logic < 0.1 ms)) |
| P6 | Fog of war avg | **WARN** 67 | avg 0.230 ms, median 0.004, max 123.92 ms | FAIL > 0.300 ms, WARN > 0.225 (lab default (fog-of-war.md:42-47: 5 Hz, < 10 000 byte writes per update)) |
| P7 | VFX managers avg | **FAIL** 0 | avg 3.502 ms, median 1.313, max 150.26 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default (for-lead.md:94: MapFillVfx 15-150 us; pools, no runtime instancing)) |
| P8 | HUD / minimap / UI avg | **FAIL** 0 | avg 3.862 ms, median 0.969, max 166.06 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default) |
| P9 | Unit / building models (art scripts) avg | **FAIL** 0 | avg 2.680 ms, median 0.716, max 158.70 ms | FAIL > 0.190 ms, WARN > 0.143 (art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)) |
| P10 | Units (gameplay) | INFO | avg 2.408 ms, median 0.540, max 139.19 ms | inside the frame budget (part of the 8 ms / 100 units logic budget (waves.md:82)) |
| P11 | Buildings | INFO | avg 0.293 ms, median 0.104, max 98.67 ms | inside the frame budget (part of the logic budget) |
| P12 | Level / world | INFO | avg 0.551 ms, median 0.128, max 112.08 ms | inside the frame budget (part of the logic budget) |
| P13 | Other art scripts | INFO | avg 0.279 ms, median 0.082, max 130.87 ms | inside the frame budget (part of the logic budget) |
| A1 | Commander think tick median | **FAIL** 0 | 1.077 ms over 27 ticks (step memory) | FAIL > 0.3 ms (ai.md:146), WARN > 0.1 ms (lab target; ai-2v2.md:340 median <= 0.25) |
| A2 | Commander think tick max | **FAIL** 0 | 8.24 ms (step memory) | FAIL > 1.5 ms (no frame > 1.5 ms of AI), WARN > 0.45 (ai-2v2.md:340) |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 2.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3805.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 109.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 667.0 | info |
| C6 | shadow casters | INFO | 166.0 | info |
| C7 | particle systems | INFO | 161.0 | info |
| C8 | multimesh nodes | INFO | 134.0 | info |
| C9 | nodes | INFO | 6241.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 28 ({"GPUParticles3D":9,"MeshInstance3D":17,"Node3D":2}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | -0.4 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | -8.6 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 25 other Godot process(es) (max 22 at once); other CPU load 93.1 %; 30 other Godot process(es) (max 27 at once); other CPU load 101.8 % | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hot list (band profiler, top 15 scripts by avg ms per frame)
| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |
|---|---|---|---|---|---|---|---|---|
| 1 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | 1733 | 1.849 | 0.599 | 1.345 | 126.71 | 6.6 % |
| 2 | `scripts/units/unit.gd` | Units (gameplay) | 94 | 1.537 | 0.295 | 2.336 | 139.06 | 5.5 % |
| 3 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | 1 | 1.531 | 0.449 | 1.136 | 165.68 | 5.5 % |
| 4 | `art/vfx/mapfill_wyrm_vfx.gd` | VFX managers | 1 | 0.796 | 0.298 | 0.512 | 128.72 | 2.9 % |
| 5 | `art/units/fire/fire_model.gd` | Unit / building models (art scripts) | 33 | 0.726 | 0.069 | 0.835 | 141.41 | 2.6 % |
| 6 | `scripts/ui/command_card.gd` | HUD / minimap / UI | 1 | 0.713 | 0.041 | 1.638 | 124.20 | 2.6 % |
| 7 | `art/vfx/titan_ground_vfx.gd` | VFX managers | 1 | 0.645 | 0.151 | 0.334 | 134.22 | 2.3 % |
| 8 | `art/units/fire/blaze_rider/blaze_rider_rider.gd` | Unit / building models (art scripts) | 11 | 0.630 | 0.020 | 0.602 | 157.89 | 2.3 % |
| 9 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | 1 | 0.574 | 0.017 | 0.634 | 150.81 | 2.1 % |
| 10 | `art/vfx/mapfill_beast_vfx.gd` | VFX managers | 1 | 0.461 | 0.109 | 0.212 | 128.90 | 1.7 % |
| 11 | `art/vfx/spell_vfx.gd` | VFX managers | 1 | 0.435 | 0.143 | 0.392 | 111.69 | 1.6 % |
| 12 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | 1 | 0.312 | 0.031 | 0.405 | 132.72 | 1.1 % |
| 13 | `scripts/units/shadow_wizard.gd` | Units (gameplay) | 1 | 0.298 | 0.029 | 0.060 | 131.95 | 1.1 % |
| 14 | `scripts/ui/champion_bar.gd` | HUD / minimap / UI | 1 | 0.258 | 0.021 | 0.240 | 127.99 | 0.9 % |
| 15 | `scripts/spells/spell_zone.gd` | Units (gameplay) | 54 | 0.240 | 0.016 | 0.237 | 86.00 | 0.9 % |

Engine gaps (avg ms per frame): physics + navigation server step 5.044 · render / tweens / idle 4.763 · unclassified nodes 0.105 · probe overhead ~0.383

## Hitches (worst first, what happened)
| Game time | Frame ms | Top bands | Events |
|---|---|---|---|
| 0:24 | 303.1 |  |  |
| 0:16 | 286.0 |  |  |
| 0:22 | 266.1 |  |  |
| 0:23 | 263.2 |  |  |
| 0:12 | 253.5 |  |  |
| 0:08 | 249.6 |  |  |
| 0:08 | 247.0 |  |  |
| 0:08 | 244.2 |  | 2 nodes added |
| 0:08 | 242.1 |  |  |
| 0:14 | 241.8 |  |  |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 0.0 |
| draw_calls_max | 0.0 |
| nav_agents | 50.243 |
| nav_agents_max | 88.0 |
| navigation_ms | 92.357 |
| navigation_ms_max | 246.857 |
| nodes_end | 6983.0 |
| objects | 0.0 |
| objects_end | 18552.0 |
| objects_max | 0.0 |
| physics_active_objects | 37.281 |
| physics_active_objects_max | 75.0 |
| physics_ms | 176.065 |
| physics_ms_max | 300.307 |
| physics_pairs | 44.991 |
| physics_pairs_max | 87.0 |
| primitives | 0.0 |
| primitives_max | 0.0 |
| process_ms | 175.61 |
| process_ms_max | 283.152 |
| resources_end | 1661.0 |
| static_mem_mb | 208.0 |
| video_mem_mb | 0.0 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":8.236,"tick_median_ms":1.077,"ticks":27.0,"worst_step":"memory","worst_step_ms":5.423}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
- storm: 9 VFX managers driven (TitanVfx, TitanGroundVfx, MapFillVfx, BeastVfx, WyrmVfx, TradeVfx, UnitFireGunVfx, UnitIceRifleVfx, UnitNatureT3Vfx)
