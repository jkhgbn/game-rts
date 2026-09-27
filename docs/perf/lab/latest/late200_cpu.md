# Perf Lab scorecard: late200 (headless logic)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:10:43 · 1 run(s) (median) · seed 1 · 30 s measured · lab v1.0

Scenario: 100 v 100 + 1 titan per side, every epic beast spawned, river / decor / critters on, camera sweep.

> **NOISY**: 44 other Godot process(es) (max 24 at once); other CPU load 92.7 %; calibration 162 ms vs best 19 (x8.3); 33 other Godot process(es) (max 22 at once); calibration 159 ms vs best 19 (x8.2). Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **FAIL** · perf score **38 / 100**

Frame avg **42.68 ms** · p95 129.50 · p99 162.81 · max 275.2 · hitches 547 · 1800 frames · units 135 · nodes 10633

Repeats (frame avg ms): [42.684]

## Improve next
1. **Split the Commander's worst think step**: Commander think tick median = 3.458 ms over 33 ticks (step memory). The worst step is `memory` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked. _(check A1)_
2. **Pool the VFX**: nodes were created under a VFX manager during the measure window (6 ({"GPUParticles3D":6})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
3. **Cheaper unit ticks**: 4.390 ms / frame over 224 nodes. shader parameter write (unit.gd:1948 in `_update_hp_bar()`, unit.gd:1949 in `_update_hp_bar()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `scripts/units/unit.gd` `_physics_process`: run target acquisition / aggro scans every 0.2-0.3 s with a per-unit offset instead of every frame, use a spatial hash for nearest-enemy, and skip idle units. _(hot list: `scripts/units/unit.gd`)_
4. **HUD refresh**: 2.241 ms / frame over 1 nodes. string formatting (selection_panel.gd:564 in `_update_hero()`, selection_panel.gd:567 in `_update_hero()`, selection_panel.gd:580 in `_update_hero()`). Fix: build strings only when the text changes. `scripts/ui/selection_panel.gd`: refresh labels / bars on signals or at 4-10 Hz instead of every _process, and only set text when it changed. _(hot list: `scripts/ui/selection_panel.gd`)_
5. **Unit model animation**: 1.180 ms / frame over 78 nodes. shader parameter write (fire_model.gd:324 in `_set_ball_heat()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `art/units/fire/fire_model.gd`: animate at a reduced rate beyond 30 m and freeze off-screen (art-units.md 6.10); keep pivot writes <= 7 per frame. _(hot list: `art/units/fire/fire_model.gd`)_
6. **Logic frame over budget**: Frame avg 42.68 ms: start with the top rows of the hot list; the unit tick and NavigationAgent3D avoidance scale with the unit count. _(check F1)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (logic) | **FAIL** 0 | 42.68 ms | FAIL > 16.00, WARN > 11.00 ms (waves.md:82-83 (200 units: 16 ms scaled), warn waves.md:226 (5.P1: <= 11 ms) (135 units)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | **WARN** 35 | 129.50 ms | WARN > 24.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | **WARN** 35 | 162.81 ms (max 275.2 ms) | WARN > 32.00 ms |
| S3 | Hitches (> 33 ms) | **FAIL** 0 | 547 in 30 s (1094.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P1 | AI commanders avg | PASS 100 | avg 0.105 ms, median 0.003, max 55.77 ms | FAIL > 0.600 ms, WARN > 0.450 (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1a | AI commanders worst frame | **FAIL** 0 | 55.77 ms | FAIL > 1.5 ms (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1b | AI commanders median frame | PASS 100 | 0.003 ms | WARN > 0.10 ms (lab target) |
| P2 | Epic beast brains avg | **WARN** 46 | avg 0.028 ms, median 0.014, max 0.98 ms | FAIL > 0.030 ms, WARN > 0.022 (map-fill.md:403 (8 beasts < 0.03 ms)) |
| P3 | Map fill services avg | PASS 89 | avg 0.102 ms, median 0.017, max 78.21 ms | FAIL > 0.200 ms, WARN > 0.150 (map-fill.md:398 (map fill < 0.2 ms: river 0.03, points 0.03, camps 0.02)) |
| P4 | Critters (game + cosmetic) avg | **FAIL** 32 | avg 0.118 ms, median 0.034, max 59.87 ms | FAIL > 0.110 ms, WARN > 0.083 (map-fill.md:398 + :404 (CritterSystem < 0.08, game critters < 0.03)) |
| P5 | Trade avg | **WARN** 62 | avg 0.080 ms, median 0.026, max 46.94 ms | FAIL > 0.100 ms, WARN > 0.075 (market-trade.md:128 (all trade logic < 0.1 ms)) |
| P6 | Fog of war avg | **FAIL** 29 | avg 0.347 ms, median 0.004, max 128.87 ms | FAIL > 0.300 ms, WARN > 0.225 (lab default (fog-of-war.md:42-47: 5 Hz, < 10 000 byte writes per update)) |
| P7 | VFX managers avg | **FAIL** 0 | avg 1.211 ms, median 0.384, max 105.97 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default (for-lead.md:94: MapFillVfx 15-150 us; pools, no runtime instancing)) |
| P8 | HUD / minimap / UI avg | **FAIL** 0 | avg 4.533 ms, median 1.738, max 148.17 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default) |
| P9 | Unit / building models (art scripts) avg | **FAIL** 0 | avg 4.493 ms, median 1.873, max 189.34 ms | FAIL > 0.675 ms, WARN > 0.506 (art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)) |
| P10 | Units (gameplay) | INFO | avg 4.887 ms, median 1.507, max 109.15 ms | inside the frame budget (part of the 8 ms / 100 units logic budget (waves.md:82)) |
| P11 | Buildings | INFO | avg 0.162 ms, median 0.045, max 79.59 ms | inside the frame budget (part of the logic budget) |
| P12 | Level / world | INFO | avg 0.415 ms, median 0.134, max 106.86 ms | inside the frame budget (part of the logic budget) |
| P13 | Other art scripts | INFO | avg 0.170 ms, median 0.085, max 52.13 ms | inside the frame budget (part of the logic budget) |
| A1 | Commander think tick median | **FAIL** 0 | 3.458 ms over 33 ticks (step memory) | FAIL > 0.3 ms (ai.md:146), WARN > 0.1 ms (lab target; ai-2v2.md:340 median <= 0.25) |
| A2 | Commander think tick max | **FAIL** 0 | 8.91 ms (step memory) | FAIL > 1.5 ms (no frame > 1.5 ms of AI), WARN > 0.45 (ai-2v2.md:340) |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 6.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3653.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 109.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 548.0 | info |
| C6 | shadow casters | INFO | 176.0 | info |
| C7 | particle systems | INFO | 83.0 | info |
| C8 | multimesh nodes | INFO | 131.0 | info |
| C9 | nodes | INFO | 6398.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 6 ({"GPUParticles3D":6}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | -2.2 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | -16.5 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 44 other Godot process(es) (max 24 at once); other CPU load 92.7 %; calibration 162 ms vs best 19 (x8.3); 33 other Godot process(es) (max 22 at once); calibration 159 ms vs best 19 (x8.2) | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hot list (band profiler, top 15 scripts by avg ms per frame)
| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |
|---|---|---|---|---|---|---|---|---|
| 1 | `scripts/units/unit.gd` | Units (gameplay) | 224 | 4.390 | 1.254 | 17.115 | 108.95 | 11.8 % |
| 2 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | 1 | 2.241 | 0.875 | 2.018 | 147.28 | 6.0 % |
| 3 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | 1994 | 1.192 | 0.687 | 1.389 | 109.34 | 3.2 % |
| 4 | `art/units/fire/fire_model.gd` | Unit / building models (art scripts) | 78 | 1.180 | 0.319 | 1.704 | 93.70 | 3.2 % |
| 5 | `art/units/fire/blaze_rider/blaze_rider_rider.gd` | Unit / building models (art scripts) | 25 | 1.137 | 0.279 | 1.559 | 88.60 | 3.1 % |
| 6 | `scripts/ui/command_card.gd` | HUD / minimap / UI | 1 | 0.659 | 0.043 | 2.246 | 105.21 | 1.8 % |
| 7 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | 1 | 0.618 | 0.072 | 0.736 | 113.77 | 1.7 % |
| 8 | `art/units/mounts/ember_boar/ember_boar.gd` | Unit / building models (art scripts) | 25 | 0.579 | 0.115 | 0.677 | 115.62 | 1.6 % |
| 9 | `scripts/world/fog_of_war.gd` | Fog of war | 1 | 0.347 | 0.004 | 0.884 | 128.87 | 0.9 % |
| 10 | `scripts/vfx/route_line.gd` | VFX managers | 1 | 0.329 | 0.087 | 0.142 | 104.95 | 0.9 % |
| 11 | `art/units/shadow/shadow_model.gd` | Unit / building models (art scripts) | 103 | 0.261 | 0.146 | 0.430 | 87.00 | 0.7 % |
| 12 | `[AudioStreamPlayer3D]` | Built-in nodes ([AudioStreamPlayer3D]) | 19 | 0.232 | 0.029 | 0.113 | 73.16 | 0.6 % |
| 13 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | 1 | 0.223 | 0.019 | 0.835 | 81.65 | 0.6 % |
| 14 | `scripts/economy/worker.gd` | Units (gameplay) | 6 | 0.210 | 0.099 | 0.173 | 64.75 | 0.6 % |
| 15 | `scripts/campaign/ember_crown.gd` | Level / world | 1 | 0.178 | 0.053 | 0.099 | 84.91 | 0.5 % |

Engine gaps (avg ms per frame): physics + navigation server step 11.708 · render / tweens / idle 3.794 · unclassified nodes 0.060 · probe overhead ~0.413

## Hitches (worst first, what happened)
| Game time | Frame ms | Top bands | Events |
|---|---|---|---|
| 0:11 | 275.2 |  |  |
| 0:11 | 209.3 |  |  |
| 0:28 | 195.2 |  |  |
| 0:10 | 185.7 |  |  |
| 0:29 | 183.1 |  |  |
| 0:14 | 177.5 |  |  |
| 0:33 | 177.4 |  |  |
| 0:33 | 177.4 |  |  |
| 0:33 | 175.2 |  |  |
| 0:16 | 173.4 |  |  |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 0.0 |
| draw_calls_max | 0.0 |
| nav_agents | 147.362 |
| nav_agents_max | 204.0 |
| navigation_ms | 83.318 |
| navigation_ms_max | 161.412 |
| nodes_end | 9433.0 |
| objects | 0.0 |
| objects_end | 21916.0 |
| objects_max | 0.0 |
| physics_active_objects | 134.207 |
| physics_active_objects_max | 189.0 |
| physics_ms | 116.384 |
| physics_ms_max | 175.784 |
| physics_pairs | 153.924 |
| physics_pairs_max | 210.0 |
| primitives | 0.0 |
| primitives_max | 0.0 |
| process_ms | 113.239 |
| process_ms_max | 265.767 |
| resources_end | 1778.0 |
| static_mem_mb | 229.4 |
| video_mem_mb | 0.0 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":8.915,"tick_median_ms":3.458,"ticks":33.0,"worst_step":"memory","worst_step_ms":7.275}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
- titans: 2 (rime_colossus stats + war_mammoth, nightmare_knight models; no gameplay titan yet)
- epic beasts spawned: 8
