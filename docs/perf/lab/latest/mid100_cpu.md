# Perf Lab scorecard: mid100 (headless logic)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:05:00 · 1 run(s) (median) · seed 1 · 30 s measured · lab v1.0

Scenario: 50 v 50 mixed soldiers attack-move into each other on the west meadow, enemy Commander on.

> **NOISY**: 31 other Godot process(es) (max 27 at once); other CPU load 103.4 %; calibration 87 ms vs best 19 (x4.5); 36 other Godot process(es) (max 22 at once); other CPU load 101.1 %. Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **FAIL** · perf score **42 / 100**

Frame avg **36.23 ms** · p95 188.73 · p99 260.50 · max 405.7 · hitches 301 · 1800 frames · units 62 · nodes 8080

Repeats (frame avg ms): [36.231]

## Improve next
1. **Split the Commander's worst think step**: Commander think tick median = 2.318 ms over 33 ticks (step attack). The worst step is `attack` in commander.gd `_rule_attack()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked. _(check A1)_
2. **Pool the VFX**: nodes were created under a VFX manager during the measure window (52 ({"GPUParticles3D":39,"MeshInstance3D":10,"OmniLight3D":3})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
3. **Cheaper unit ticks**: 2.184 ms / frame over 114 nodes. shader parameter write (unit.gd:1948 in `_update_hp_bar()`, unit.gd:1949 in `_update_hp_bar()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `scripts/units/unit.gd` `_physics_process`: run target acquisition / aggro scans every 0.2-0.3 s with a per-unit offset instead of every frame, use a spatial hash for nearest-enemy, and skip idle units. _(hot list: `scripts/units/unit.gd`)_
4. **HUD refresh**: 1.860 ms / frame over 1 nodes. string formatting (selection_panel.gd:564 in `_update_hero()`, selection_panel.gd:567 in `_update_hero()`, selection_panel.gd:580 in `_update_hero()`). Fix: build strings only when the text changes. `scripts/ui/selection_panel.gd`: refresh labels / bars on signals or at 4-10 Hz instead of every _process, and only set text when it changed. _(hot list: `scripts/ui/selection_panel.gd`)_
5. **Unit model animation**: 0.436 ms / frame over 53 nodes. shader parameter write (shadow_model.gd:315 in `_dissolve_extra()`, shadow_model.gd:317 in `_dissolve_extra()`, shadow_model.gd:365 in `_thrall_extra()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `art/units/shadow/shadow_model.gd`: animate at a reduced rate beyond 30 m and freeze off-screen (art-units.md 6.10); keep pivot writes <= 7 per frame. _(hot list: `art/units/shadow/shadow_model.gd`)_
6. **Logic frame over budget**: Frame avg 36.23 ms: start with the top rows of the hot list; the unit tick and NavigationAgent3D avoidance scale with the unit count. _(check F1)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (logic) | **FAIL** 0 | 36.23 ms | FAIL > 8.00, WARN > 5.50 ms (waves.md:82 (100 units <= 8 ms), warn waves.md:226 (5.P1: <= 5.5 ms) (62 units)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | **WARN** 35 | 188.73 ms | WARN > 12.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | **WARN** 35 | 260.50 ms (max 405.7 ms) | WARN > 16.00 ms |
| S3 | Hitches (> 33 ms) | **FAIL** 0 | 301 in 30 s (602.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P1 | AI commanders avg | PASS 100 | avg 0.067 ms, median 0.003, max 21.45 ms | FAIL > 0.600 ms, WARN > 0.450 (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1a | AI commanders worst frame | **FAIL** 0 | 21.45 ms | FAIL > 1.5 ms (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1b | AI commanders median frame | PASS 100 | 0.003 ms | WARN > 0.10 ms (lab target) |
| P2 | Epic beast brains avg | PASS 100 | avg 0.005 ms, median 0.004, max 0.23 ms | FAIL > 0.030 ms, WARN > 0.022 (map-fill.md:403 (8 beasts < 0.03 ms)) |
| P3 | Map fill services avg | PASS 90 | avg 0.101 ms, median 0.017, max 89.93 ms | FAIL > 0.200 ms, WARN > 0.150 (map-fill.md:398 (map fill < 0.2 ms: river 0.03, points 0.03, camps 0.02)) |
| P4 | Critters (game + cosmetic) avg | **FAIL** 27 | avg 0.133 ms, median 0.032, max 113.46 ms | FAIL > 0.110 ms, WARN > 0.083 (map-fill.md:398 + :404 (CritterSystem < 0.08, game critters < 0.03)) |
| P5 | Trade avg | **WARN** 56 | avg 0.085 ms, median 0.025, max 83.04 ms | FAIL > 0.100 ms, WARN > 0.075 (market-trade.md:128 (all trade logic < 0.1 ms)) |
| P6 | Fog of war avg | PASS 87 | avg 0.163 ms, median 0.004, max 71.83 ms | FAIL > 0.300 ms, WARN > 0.225 (lab default (fog-of-war.md:42-47: 5 Hz, < 10 000 byte writes per update)) |
| P7 | VFX managers avg | **FAIL** 0 | avg 1.127 ms, median 0.248, max 147.28 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default (for-lead.md:94: MapFillVfx 15-150 us; pools, no runtime instancing)) |
| P8 | HUD / minimap / UI avg | **FAIL** 0 | avg 4.428 ms, median 1.312, max 172.14 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default) |
| P9 | Unit / building models (art scripts) avg | **FAIL** 0 | avg 2.473 ms, median 0.921, max 184.92 ms | FAIL > 0.310 ms, WARN > 0.232 (art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)) |
| P10 | Units (gameplay) | INFO | avg 2.827 ms, median 0.740, max 211.26 ms | inside the frame budget (part of the 8 ms / 100 units logic budget (waves.md:82)) |
| P11 | Buildings | INFO | avg 0.165 ms, median 0.043, max 121.80 ms | inside the frame budget (part of the logic budget) |
| P12 | Level / world | INFO | avg 0.213 ms, median 0.125, max 118.82 ms | inside the frame budget (part of the logic budget) |
| P13 | Other art scripts | INFO | avg 0.142 ms, median 0.082, max 80.73 ms | inside the frame budget (part of the logic budget) |
| A1 | Commander think tick median | **FAIL** 0 | 2.318 ms over 33 ticks (step attack) | FAIL > 0.3 ms (ai.md:146), WARN > 0.1 ms (lab target; ai-2v2.md:340 median <= 0.25) |
| A2 | Commander think tick max | **FAIL** 0 | 190.05 ms (step attack) | FAIL > 1.5 ms (no frame > 1.5 ms of AI), WARN > 0.45 (ai-2v2.md:340) |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 3.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3661.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 109.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 475.0 | info |
| C6 | shadow casters | INFO | 170.0 | info |
| C7 | particle systems | INFO | 37.0 | info |
| C8 | multimesh nodes | INFO | 131.0 | info |
| C9 | nodes | INFO | 6159.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 52 ({"GPUParticles3D":39,"MeshInstance3D":10,"OmniLight3D":3}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | -0.5 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | -10.7 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 31 other Godot process(es) (max 27 at once); other CPU load 103.4 %; calibration 87 ms vs best 19 (x4.5); 36 other Godot process(es) (max 22 at once); other CPU load 101.1 % | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hot list (band profiler, top 15 scripts by avg ms per frame)
| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |
|---|---|---|---|---|---|---|---|---|
| 1 | `scripts/units/unit.gd` | Units (gameplay) | 114 | 2.184 | 0.542 | 2.948 | 188.82 | 8.6 % |
| 2 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | 1 | 1.860 | 0.781 | 1.437 | 163.29 | 7.3 % |
| 3 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | 1736 | 1.530 | 0.614 | 1.021 | 142.12 | 6.0 % |
| 4 | `scripts/ui/command_card.gd` | HUD / minimap / UI | 1 | 0.816 | 0.042 | 1.840 | 170.86 | 3.2 % |
| 5 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | 1 | 0.487 | 0.036 | 0.356 | 147.74 | 1.9 % |
| 6 | `art/units/shadow/shadow_model.gd` | Unit / building models (art scripts) | 53 | 0.436 | 0.124 | 0.479 | 183.84 | 1.7 % |
| 7 | `art/units/fire/blaze_rider/blaze_rider_rider.gd` | Unit / building models (art scripts) | 13 | 0.409 | 0.096 | 0.535 | 128.96 | 1.6 % |
| 8 | `art/units/fire/fire_model.gd` | Unit / building models (art scripts) | 40 | 0.409 | 0.115 | 0.588 | 126.60 | 1.6 % |
| 9 | `scripts/economy/worker.gd` | Units (gameplay) | 6 | 0.396 | 0.097 | 0.162 | 210.84 | 1.6 % |
| 10 | `scripts/ui/champion_bar.gd` | HUD / minimap / UI | 1 | 0.300 | 0.022 | 0.242 | 94.94 | 1.2 % |
| 11 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | 1 | 0.297 | 0.017 | 0.699 | 114.60 | 1.2 % |
| 12 | `art/buildings/capture/wayshrine/wayshrine.gd` | Unit / building models (art scripts) | 2 | 0.276 | 0.052 | 0.082 | 121.15 | 1.1 % |
| 13 | `scripts/vfx/capture_rings.gd` | VFX managers | 1 | 0.222 | 0.004 | 0.181 | 147.06 | 0.9 % |
| 14 | `scripts/vfx/route_line.gd` | VFX managers | 1 | 0.202 | 0.037 | 0.057 | 128.85 | 0.8 % |
| 15 | `art/units/mounts/ember_boar/ember_boar.gd` | Unit / building models (art scripts) | 13 | 0.195 | 0.052 | 0.303 | 94.64 | 0.8 % |

Engine gaps (avg ms per frame): physics + navigation server step 6.967 · render / tweens / idle 2.778 · unclassified nodes 0.083 · probe overhead ~0.394

## Hitches (worst first, what happened)
| Game time | Frame ms | Top bands | Events |
|---|---|---|---|
| 0:08 | 405.7 |  |  |
| 0:08 | 378.6 |  | 4 nodes added |
| 0:19 | 333.5 |  |  |
| 0:14 | 313.5 |  |  |
| 0:07 | 311.4 |  |  |
| 0:15 | 292.1 |  |  |
| 0:17 | 291.4 |  |  |
| 0:07 | 284.2 |  |  |
| 0:22 | 281.9 |  | 2 nodes added |
| 0:18 | 280.7 |  |  |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 0.0 |
| draw_calls_max | 0.0 |
| nav_agents | 74.0 |
| nav_agents_max | 110.0 |
| navigation_ms | 91.994 |
| navigation_ms_max | 385.342 |
| nodes_end | 7317.0 |
| objects | 0.0 |
| objects_end | 18738.0 |
| objects_max | 0.0 |
| physics_active_objects | 62.034 |
| physics_active_objects_max | 96.0 |
| physics_ms | 177.083 |
| physics_ms_max | 396.727 |
| physics_pairs | 66.0 |
| physics_pairs_max | 102.0 |
| primitives | 0.0 |
| primitives_max | 0.0 |
| process_ms | 161.443 |
| process_ms_max | 304.579 |
| resources_end | 1668.0 |
| static_mem_mb | 208.4 |
| video_mem_mb | 0.0 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":190.049,"tick_median_ms":2.318,"ticks":33.0,"worst_step":"attack","worst_step_ms":188.304}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
