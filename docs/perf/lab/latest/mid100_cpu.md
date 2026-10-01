# Perf Lab scorecard: mid100 (headless logic)

Commit `main@134cf1ef47+wip` · 2026-10-01 03:42:19 · 2 run(s) (median) · seed 1 · 30 s measured · lab v1.0

Scenario: 50 v 50 mixed soldiers attack-move into each other on the west meadow, enemy Commander on.

## Result: **FAIL** · perf score **66 / 100**

Frame avg **7.08 ms** · p95 10.78 · p99 12.48 · max 15.1 · hitches 0 · 1800 frames · units 71 · nodes 9516

Repeats (frame avg ms): [7.159, 6.993]

## Improve next
1. **Split the Commander's worst think step**: Commander think tick median = 1.259 ms over 33 ticks (step champions). The worst step is `champions` in scripts/ai/ai_champions.gd `tick()` (called from commander.gd `_rule_champions`): cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked. _(check A1)_
2. **Pool the VFX**: nodes were created under a VFX manager during the measure window (2 ({"GPUParticles3D":3})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
3. **Find the node leak**: Orphan nodes at the end = 1: something adds nodes and never frees them; compare the node class counts at warm-up and at the end (scorecard json `health.node_classes`). _(check H2)_
4. **HUD refresh**: 0.631 ms / frame over 1 nodes. string formatting (selection_panel.gd:690 in `_update_hero()`, selection_panel.gd:693 in `_update_hero()`, selection_panel.gd:706 in `_update_hero()`). Fix: build strings only when the text changes. `scripts/ui/selection_panel.gd`: refresh labels / bars on signals or at 4-10 Hz instead of every _process, and only set text when it changed. _(hot list: `scripts/ui/selection_panel.gd`)_
5. **Cheaper unit ticks**: 0.564 ms / frame over 114 nodes. shader parameter write (unit.gd:2168 in `_update_hp_bar()`, unit.gd:2169 in `_update_hp_bar()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `scripts/units/unit.gd` `_physics_process`: run target acquisition / aggro scans every 0.2-0.3 s with a per-unit offset instead of every frame, use a spatial hash for nearest-enemy, and skip idle units. _(hot list: `scripts/units/unit.gd`)_
6. **Hot script caster_shadow_vfx.gd**: 0.067 ms / frame over 1 nodes. shader parameter write (caster_shadow_vfx.gd:492 in `_tick_tether()`, caster_shadow_vfx.gd:496 in `_tick_tether()`, caster_shadow_vfx.gd:506 in `_tick_tether()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). _(hot list: `art/vfx/caster_shadow_vfx.gd`)_
7. **Logic frame over budget**: Frame avg 7.08 ms: start with the top rows of the hot list; the unit tick and NavigationAgent3D avoidance scale with the unit count. _(check F1)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (logic) | **WARN** 48 | 7.08 ms | FAIL > 8.00, WARN > 5.50 ms (waves.md:82 (100 units <= 8 ms), warn waves.md:226 (5.P1: <= 5.5 ms) (71 units)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | PASS 76 | 10.78 ms | WARN > 12.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | PASS 83 | 12.48 ms (max 15.1 ms) | WARN > 16.00 ms |
| S3 | Hitches (> 33 ms) | PASS 100 | 0 in 30 s (0.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P1 | AI commanders avg | PASS 100 | avg 0.040 ms, median 0.005, max 2.33 ms | FAIL > 0.600 ms, WARN > 0.450 (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1a | AI commanders worst frame | **FAIL** 15 | 2.33 ms | FAIL > 1.5 ms (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1b | AI commanders median frame | PASS 100 | 0.005 ms | WARN > 0.10 ms (lab target) |
| P2 | Epic beast brains avg | PASS 100 | avg 0.002 ms, median 0.002, max 0.02 ms | FAIL > 0.030 ms, WARN > 0.022 (map-fill.md:403 (8 beasts < 0.03 ms)) |
| P3 | Map fill services avg | PASS 100 | avg 0.020 ms, median 0.007, max 0.41 ms | FAIL > 0.200 ms, WARN > 0.150 (map-fill.md:398 (map fill < 0.2 ms: river 0.03, points 0.03, camps 0.02)) |
| P4 | Critters (game + cosmetic) avg | PASS 100 | avg 0.032 ms, median 0.014, max 0.37 ms | FAIL > 0.110 ms, WARN > 0.083 (map-fill.md:398 + :404 (CritterSystem < 0.08, game critters < 0.03)) |
| P5 | Trade avg | PASS 100 | avg 0.018 ms, median 0.012, max 0.50 ms | FAIL > 0.100 ms, WARN > 0.075 (market-trade.md:128 (all trade logic < 0.1 ms)) |
| P6 | Fog of war avg | PASS 100 | avg 0.053 ms, median 0.002, max 0.63 ms | FAIL > 0.300 ms, WARN > 0.225 (lab default (fog-of-war.md:42-47: 5 Hz, < 10 000 byte writes per update)) |
| P7 | VFX managers avg | PASS 92 | avg 0.238 ms, median 0.224, max 0.79 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default (for-lead.md:94: MapFillVfx 15-150 us; pools, no runtime instancing)) |
| P8 | HUD / minimap / UI avg | **FAIL** 0 | avg 1.065 ms, median 0.948, max 4.47 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default) |
| P9 | Unit / building models (art scripts) avg | **FAIL** 0 | avg 0.990 ms, median 0.937, max 2.57 ms | FAIL > 0.355 ms, WARN > 0.266 (art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)) |
| P10 | Units (gameplay) | INFO | avg 0.757 ms, median 0.671, max 12.27 ms | inside the frame budget (part of the 8 ms / 100 units logic budget (waves.md:82)) |
| P11 | Buildings | INFO | avg 0.060 ms, median 0.050, max 0.29 ms | inside the frame budget (part of the logic budget) |
| P12 | Level / world | INFO | avg 0.058 ms, median 0.054, max 0.21 ms | inside the frame budget (part of the logic budget) |
| P13 | Other art scripts | INFO | avg 0.041 ms, median 0.039, max 0.19 ms | inside the frame budget (part of the logic budget) |
| A1 | Commander think tick median | **FAIL** 0 | 1.259 ms over 33 ticks (step champions) | FAIL > 0.3 ms (ai.md:146), WARN > 0.1 ms (lab target; ai-2v2.md:340 median <= 0.25) |
| A2 | Commander think tick max | **FAIL** 16 | 2.30 ms (step champions) | FAIL > 1.5 ms (no frame > 1.5 ms of AI), WARN > 0.45 (ai-2v2.md:340) |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 4.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3915.5 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 112.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 564.0 | info |
| C6 | shadow casters | INFO | 171.5 | info |
| C7 | particle systems | INFO | 88.5 | info |
| C8 | multimesh nodes | INFO | 134.0 | info |
| C9 | nodes | INFO | 7132.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 2 ({"GPUParticles3D":3}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | **WARN** 50 | 1 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | -1.6 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | -14.3 MB | info |
| H5 | Machine noise | PASS 100 | quiet | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hot list (band profiler, top 15 scripts by avg ms per frame)
| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |
|---|---|---|---|---|---|---|---|---|
| 1 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | 1 | 0.631 | 0.688 | 1.248 | 2.10 | 9.1 % |
| 2 | `scripts/units/unit.gd` | Units (gameplay) | 114 | 0.564 | 0.479 | 1.350 | 7.08 | 8.1 % |
| 3 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | 1949 | 0.300 | 0.302 | 0.407 | 0.50 | 4.3 % |
| 4 | `scripts/ui/command_card.gd` | HUD / minimap / UI | 1 | 0.164 | 0.023 | 1.037 | 2.40 | 2.4 % |
| 5 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | 1 | 0.078 | 0.020 | 0.214 | 2.44 | 1.1 % |
| 6 | `art/vfx/caster_shadow_vfx.gd` | VFX managers | 1 | 0.067 | 0.063 | 0.156 | 0.32 | 1.0 % |
| 7 | `art/units/fire/fire_model.gd` | Unit / building models (art scripts) | 15 | 0.063 | 0.062 | 0.139 | 0.38 | 0.9 % |
| 8 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | 1 | 0.053 | 0.008 | 0.325 | 0.72 | 0.8 % |
| 9 | `scripts/world/fog_of_war.gd` | Fog of war | 1 | 0.053 | 0.002 | 0.414 | 0.63 | 0.8 % |
| 10 | `art/units/fire/pyrehoof_lancer/parts/pyrehoof_lancer_rider.gd` | Unit / building models (art scripts) | 4 | 0.053 | 0.043 | 0.124 | 0.30 | 0.8 % |
| 11 | `scripts/economy/worker.gd` | Units (gameplay) | 6 | 0.051 | 0.033 | 0.134 | 0.34 | 0.7 % |
| 12 | `art/units/shadow/shadow_model.gd` | Unit / building models (art scripts) | 16 | 0.042 | 0.028 | 0.121 | 0.23 | 0.6 % |
| 13 | `[AudioStreamPlayer3D]` | Built-in nodes ([AudioStreamPlayer3D]) | 19 | 0.041 | 0.029 | 0.097 | 0.22 | 0.6 % |
| 14 | `art/units/fire/emberdart_harrier/parts/emberdart_harrier_rider.gd` | Unit / building models (art scripts) | 4 | 0.040 | 0.031 | 0.118 | 0.23 | 0.6 % |
| 15 | `art/units/fire/pyrehoof_lancer/parts/pyrehoof_boar.gd` | Unit / building models (art scripts) | 4 | 0.040 | 0.025 | 0.104 | 0.31 | 0.6 % |

Engine gaps (avg ms per frame): physics + navigation server step 2.002 · render / tweens / idle 0.789 · unclassified nodes 0.016 · probe overhead ~0.440

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 0.0 |
| draw_calls_max | 0.0 |
| nav_agents | 83.281 |
| nav_agents_max | 124.0 |
| navigation_ms | 2.217 |
| navigation_ms_max | 3.553 |
| nodes_end | 8418.0 |
| objects | 0.0 |
| objects_end | 23671.5 |
| objects_max | 0.0 |
| physics_active_objects | 70.971 |
| physics_active_objects_max | 109.5 |
| physics_ms | 6.365 |
| physics_ms_max | 11.2205 |
| physics_pairs | 82.788 |
| physics_pairs_max | 130.5 |
| primitives | 0.0 |
| primitives_max | 0.0 |
| process_ms | 7.536 |
| process_ms_max | 15.0835 |
| resources_end | 2205.5 |
| static_mem_mb | 288.95 |
| video_mem_mb | 0.0 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":2.2955,"tick_median_ms":1.259,"ticks":33.0,"worst_step":"champions","worst_step_ms":0.834}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
