# Perf Lab scorecard: late200 (headless logic)

Commit `main@134cf1ef47+wip` · 2026-10-01 03:44:04 · 2 run(s) (median) · seed 1 · 30 s measured · lab v1.0

Scenario: 100 v 100 + 1 titan per side, every epic beast spawned, river / decor / critters on, camera sweep.

## Result: **FAIL** · perf score **66 / 100**

Frame avg **11.49 ms** · p95 17.66 · p99 20.17 · max 29.7 · hitches 0 · 1800 frames · units 133 · nodes 11887

Repeats (frame avg ms): [11.567, 11.411]

## Improve next
1. **Split the Commander's worst think step**: Commander think tick median = 2.108 ms over 33 ticks (step champions). The worst step is `champions` in scripts/ai/ai_champions.gd `tick()` (called from commander.gd `_rule_champions`): cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked. _(check A1)_
2. **Pool the VFX**: nodes were created under a VFX manager during the measure window (8 ({"GPUParticles3D":3,"MeshInstance3D":2,"Node3D":2})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
3. **Find the node leak**: Orphan nodes at the end = 1: something adds nodes and never frees them; compare the node class counts at warm-up and at the end (scorecard json `health.node_classes`). _(check H2)_
4. **Cheaper unit ticks**: 1.343 ms / frame over 224 nodes. shader parameter write (unit.gd:2168 in `_update_hp_bar()`, unit.gd:2169 in `_update_hp_bar()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `scripts/units/unit.gd` `_physics_process`: run target acquisition / aggro scans every 0.2-0.3 s with a per-unit offset instead of every frame, use a spatial hash for nearest-enemy, and skip idle units. _(hot list: `scripts/units/unit.gd`)_
5. **HUD refresh**: 0.988 ms / frame over 1 nodes. string formatting (selection_panel.gd:690 in `_update_hero()`, selection_panel.gd:693 in `_update_hero()`, selection_panel.gd:706 in `_update_hero()`). Fix: build strings only when the text changes. `scripts/ui/selection_panel.gd`: refresh labels / bars on signals or at 4-10 Hz instead of every _process, and only set text when it changed. _(hot list: `scripts/ui/selection_panel.gd`)_
6. **Hot script caster_shadow_vfx.gd**: 0.171 ms / frame over 1 nodes. shader parameter write (caster_shadow_vfx.gd:492 in `_tick_tether()`, caster_shadow_vfx.gd:496 in `_tick_tether()`, caster_shadow_vfx.gd:506 in `_tick_tether()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). _(hot list: `art/vfx/caster_shadow_vfx.gd`)_
7. **Logic frame over budget**: Frame avg 11.49 ms: start with the top rows of the hot list; the unit tick and NavigationAgent3D avoidance scale with the unit count. _(check F1)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (logic) | **WARN** 66 | 11.49 ms | FAIL > 16.00, WARN > 11.00 ms (waves.md:82-83 (200 units: 16 ms scaled), warn waves.md:226 (5.P1: <= 11 ms) (133 units)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | PASS 86 | 17.66 ms | WARN > 24.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | PASS 92 | 20.17 ms (max 29.7 ms) | WARN > 32.00 ms |
| S3 | Hitches (> 33 ms) | PASS 100 | 0 in 30 s (0.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P1 | AI commanders avg | PASS 100 | avg 0.079 ms, median 0.006, max 2.94 ms | FAIL > 0.600 ms, WARN > 0.450 (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1a | AI commanders worst frame | **FAIL** 1 | 2.94 ms | FAIL > 1.5 ms (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1b | AI commanders median frame | PASS 100 | 0.006 ms | WARN > 0.10 ms (lab target) |
| P2 | Epic beast brains avg | PASS 91 | avg 0.015 ms, median 0.008, max 0.77 ms | FAIL > 0.030 ms, WARN > 0.022 (map-fill.md:403 (8 beasts < 0.03 ms)) |
| P3 | Map fill services avg | PASS 100 | avg 0.026 ms, median 0.009, max 0.64 ms | FAIL > 0.200 ms, WARN > 0.150 (map-fill.md:398 (map fill < 0.2 ms: river 0.03, points 0.03, camps 0.02)) |
| P4 | Critters (game + cosmetic) avg | PASS 100 | avg 0.037 ms, median 0.018, max 0.43 ms | FAIL > 0.110 ms, WARN > 0.083 (map-fill.md:398 + :404 (CritterSystem < 0.08, game critters < 0.03)) |
| P5 | Trade avg | PASS 100 | avg 0.024 ms, median 0.015, max 0.90 ms | FAIL > 0.100 ms, WARN > 0.075 (market-trade.md:128 (all trade logic < 0.1 ms)) |
| P6 | Fog of war avg | PASS 100 | avg 0.081 ms, median 0.002, max 1.08 ms | FAIL > 0.300 ms, WARN > 0.225 (lab default (fog-of-war.md:42-47: 5 Hz, < 10 000 byte writes per update)) |
| P7 | VFX managers avg | **WARN** 48 | avg 0.453 ms, median 0.412, max 1.69 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default (for-lead.md:94: MapFillVfx 15-150 us; pools, no runtime instancing)) |
| P8 | HUD / minimap / UI avg | **FAIL** 0 | avg 1.578 ms, median 1.287, max 7.26 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default) |
| P9 | Unit / building models (art scripts) avg | **FAIL** 0 | avg 1.726 ms, median 1.579, max 3.95 ms | FAIL > 0.665 ms, WARN > 0.499 (art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)) |
| P10 | Units (gameplay) | INFO | avg 1.759 ms, median 1.576, max 17.25 ms | inside the frame budget (part of the 8 ms / 100 units logic budget (waves.md:82)) |
| P11 | Buildings | INFO | avg 0.079 ms, median 0.063, max 0.86 ms | inside the frame budget (part of the logic budget) |
| P12 | Level / world | INFO | avg 0.069 ms, median 0.065, max 0.27 ms | inside the frame budget (part of the logic budget) |
| P13 | Other art scripts | INFO | avg 0.049 ms, median 0.048, max 0.21 ms | inside the frame budget (part of the logic budget) |
| A1 | Commander think tick median | **FAIL** 0 | 2.108 ms over 33 ticks (step champions) | FAIL > 0.3 ms (ai.md:146), WARN > 0.1 ms (lab target; ai-2v2.md:340 median <= 0.25) |
| A2 | Commander think tick max | **FAIL** 0 | 3.06 ms (step champions) | FAIL > 1.5 ms (no frame > 1.5 ms of AI), WARN > 0.45 (ai-2v2.md:340) |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 2.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3930.5 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 112.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 653.0 | info |
| C6 | shadow casters | INFO | 183.0 | info |
| C7 | particle systems | INFO | 111.0 | info |
| C8 | multimesh nodes | INFO | 134.0 | info |
| C9 | nodes | INFO | 7403.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 8 ({"GPUParticles3D":3,"MeshInstance3D":2,"Node3D":2}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | **WARN** 50 | 1 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | -3.8 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | -26.8 MB | info |
| H5 | Machine noise | PASS 100 | quiet | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hot list (band profiler, top 15 scripts by avg ms per frame)
| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |
|---|---|---|---|---|---|---|---|---|
| 1 | `scripts/units/unit.gd` | Units (gameplay) | 224 | 1.343 | 1.196 | 2.712 | 16.51 | 11.7 % |
| 2 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | 1 | 0.988 | 0.936 | 1.729 | 2.34 | 8.6 % |
| 3 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | 2197 | 0.376 | 0.370 | 0.472 | 0.64 | 3.3 % |
| 4 | `scripts/ui/command_card.gd` | HUD / minimap / UI | 1 | 0.208 | 0.026 | 1.317 | 2.54 | 1.8 % |
| 5 | `art/vfx/caster_shadow_vfx.gd` | VFX managers | 1 | 0.171 | 0.155 | 0.317 | 0.52 | 1.5 % |
| 6 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | 1 | 0.144 | 0.033 | 0.459 | 4.75 | 1.3 % |
| 7 | `art/units/fire/blaze_rider/blaze_rider_rider.gd` | Unit / building models (art scripts) | 8 | 0.114 | 0.100 | 0.220 | 0.46 | 1.0 % |
| 8 | `art/units/shadow/shadow_model.gd` | Unit / building models (art scripts) | 31 | 0.111 | 0.105 | 0.200 | 0.44 | 1.0 % |
| 9 | `scripts/units/caster_ability.gd` | Units (gameplay) | 15 | 0.104 | 0.040 | 0.378 | 1.73 | 0.9 % |
| 10 | `art/units/fire/fire_model.gd` | Unit / building models (art scripts) | 27 | 0.099 | 0.082 | 0.223 | 0.40 | 0.9 % |
| 11 | `scripts/units/t3_unit_ability.gd` | Units (gameplay) | 15 | 0.097 | 0.102 | 0.243 | 0.64 | 0.8 % |
| 12 | `art/units/mounts/ember_boar/ember_boar.gd` | Unit / building models (art scripts) | 8 | 0.082 | 0.064 | 0.183 | 0.34 | 0.7 % |
| 13 | `scripts/world/fog_of_war.gd` | Fog of war | 1 | 0.081 | 0.002 | 0.553 | 1.08 | 0.7 % |
| 14 | `art/units/fire/emberdart_harrier/parts/emberdart_harrier_rider.gd` | Unit / building models (art scripts) | 8 | 0.070 | 0.061 | 0.192 | 0.39 | 0.6 % |
| 15 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | 1 | 0.070 | 0.010 | 0.415 | 0.79 | 0.6 % |

Engine gaps (avg ms per frame): physics + navigation server step 3.243 · render / tweens / idle 1.014 · unclassified nodes 0.053 · probe overhead ~0.463

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 0.0 |
| draw_calls_max | 0.0 |
| nav_agents | 146.236 |
| nav_agents_max | 228.5 |
| navigation_ms | 3.652 |
| navigation_ms_max | 6.0655 |
| nodes_end | 9942.0 |
| objects | 0.0 |
| objects_end | 26147.5 |
| objects_max | 0.0 |
| physics_active_objects | 131.877 |
| physics_active_objects_max | 211.5 |
| physics_ms | 10.285 |
| physics_ms_max | 21.4025 |
| physics_pairs | 229.4 |
| physics_pairs_max | 356.5 |
| primitives | 0.0 |
| primitives_max | 0.0 |
| process_ms | 9.456 |
| process_ms_max | 16.4765 |
| resources_end | 2274.5 |
| static_mem_mb | 309.7 |
| video_mem_mb | 0.0 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":3.0635,"tick_median_ms":2.108,"ticks":33.0,"worst_step":"champions","worst_step_ms":0.971}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
- titans: 2 (rime_colossus stats + war_mammoth, nightmare_knight models; no gameplay titan yet)
- epic beasts spawned: 8
