# Perf Lab scorecard: vfx_storm (windowed 1600x900)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:18:50 · 1 run(s) (median) · seed 1 · 25 s measured · lab v1.0

Scenario: 40 v 40 fight + both wizards casting every spell each 0.5 s + every VFX manager's effects round-robin.

> **NOISY**: 38 other Godot process(es) (max 25 at once); other CPU load 101.2 %; calibration 26 ms vs best 19 (x1.3). Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **FAIL** · perf score **68 / 100**

Frame avg **19.21 ms** · p95 31.19 · p99 37.04 · max 47.6 · hitches 36 · 1500 frames · units 38 · nodes 7443

Repeats (frame avg ms): [19.212]

## Improve next
1. **Pool the VFX**: nodes were created under a VFX manager during the measure window (27 ({"GPUParticles3D":9,"MeshInstance3D":16,"Node3D":2})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
2. **Cache group lists**: Many per-frame functions call `get_tree().get_nodes_in_group(&"units")`: a shared per-frame cache (one array per group, rebuilt once per physics frame) removes the repeated allocations (ai-2v2.md:336 AIWorldCache pattern). _(standing idea)_
3. **Stagger periodic work**: Give every timer-driven tick (commander, brains, capture points, camps) a random phase offset so they never all fire on the same frame (ai-2v2.md:334). _(standing idea)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (windowed) | **FAIL** 29 | 19.21 ms | FAIL > 16.67, WARN > 8.33 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | **WARN** 52 | 31.19 ms | WARN > 25.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | **WARN** 61 | 37.04 ms (max 47.6 ms) | WARN > 33.33 ms |
| S3 | Hitches (> 33 ms) | **FAIL** 0 | 36 in 25 s (86.40 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## GPU / render
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| G1 | GPU render time avg | PASS 79 | 7.04 ms (p95 8.51) | FAIL > 16.7 ms, WARN > 8.3 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |
| G-draw_calls | Render draw calls (avg per frame) | PASS 98 | 1581 (max 2246) | WARN > 3000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-objects | Render objects (avg per frame) | PASS 83 | 3924 (max 6340) | WARN > 5000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-primitives | Render primitives (avg per frame) | PASS 94 | 2398892 (max 2671778) | WARN > 4000000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-vmem | Video memory | INFO | 354 MB | info (GTX 1660: 6 GB) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P0 | Band profiler | INFO | no profiled run | run with --profile=1 for the hot list |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 3.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3957.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 114.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 672.0 | info |
| C6 | shadow casters | INFO | 166.0 | info |
| C7 | particle systems | INFO | 157.0 | info |
| C8 | multimesh nodes | INFO | 140.0 | info |
| C9 | nodes | INFO | 6220.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 27 ({"GPUParticles3D":9,"MeshInstance3D":16,"Node3D":2}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | +0.0 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | +2.7 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 38 other Godot process(es) (max 25 at once); other CPU load 101.2 %; calibration 26 ms vs best 19 (x1.3) | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hitches (worst first, what happened)
| Game time | Frame ms | Top bands | Events |
|---|---|---|---|
| 0:03 | 47.6 |  | 4 nodes added |
| 0:14 | 47.2 |  | cast shadow_lance, cast soul_siphon, cast umbral_shroud |
| 0:08 | 45.0 |  | 6 nodes added |
| 0:08 | 43.2 |  | 2 nodes added |
| 0:06 | 42.3 |  | 2 nodes added |
| 0:11 | 42.2 |  | 2 nodes added |
| 0:09 | 41.3 |  | 4 nodes added |
| 0:12 | 41.0 |  | cast shadow_lance, cast soul_siphon, cast umbral_shroud |
| 0:09 | 40.6 |  | 2 nodes added |
| 0:05 | 40.0 |  |  |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 1581.077 |
| draw_calls_max | 2246.0 |
| nav_agents | 50.927 |
| nav_agents_max | 88.0 |
| navigation_ms | 3.274 |
| navigation_ms_max | 4.314 |
| nodes_end | 6892.0 |
| objects | 3923.663 |
| objects_end | 17857.0 |
| objects_max | 6340.0 |
| physics_active_objects | 37.819 |
| physics_active_objects_max | 76.0 |
| physics_ms | 17.142 |
| physics_ms_max | 27.872 |
| physics_pairs | 44.261 |
| physics_pairs_max | 91.0 |
| primitives | 2398891.816 |
| primitives_max | 2671778.0 |
| process_ms | 22.946 |
| process_ms_max | 44.193 |
| resources_end | 1661.0 |
| static_mem_mb | 356.3 |
| video_mem_mb | 354.0 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":3.775,"tick_median_ms":1.036,"ticks":27.0,"worst_step":"wizard","worst_step_ms":2.192}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
- storm: 9 VFX managers driven (TitanVfx, TitanGroundVfx, MapFillVfx, BeastVfx, WyrmVfx, TradeVfx, UnitFireGunVfx, UnitIceRifleVfx, UnitNatureT3Vfx)
