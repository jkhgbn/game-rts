# Perf Lab scorecard: mid100 (windowed 1600x900)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:07:09 · 1 run(s) (median) · seed 1 · 30 s measured · lab v1.0

Scenario: 50 v 50 mixed soldiers attack-move into each other on the west meadow, enemy Commander on.

> **NOISY**: 26 other Godot process(es) (max 22 at once); other CPU load 105.2 %; calibration 27 ms vs best 19 (x1.4). Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **FAIL** · perf score **65 / 100**

Frame avg **19.06 ms** · p95 27.53 · p99 41.35 · max 55.6 · hitches 62 · 1800 frames · units 62 · nodes 8096

Repeats (frame avg ms): [19.063]

## Improve next
1. **Pool the VFX**: nodes were created under a VFX manager during the measure window (3 ({"GPUParticles3D":3})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
2. **Fewer draw calls**: Render objects (avg per frame) = 5339 (max 7079): merge static decor into MultiMeshes per chunk (map-fill.md:400), set visibility_range_end on small props (65 / 90 m), and merge unit parts (art-units.md 8: <= 14 instances per unit). _(check G-objects)_
3. **Cache group lists**: Many per-frame functions call `get_tree().get_nodes_in_group(&"units")`: a shared per-frame cache (one array per group, rebuilt once per physics frame) removes the repeated allocations (ai-2v2.md:336 AIWorldCache pattern). _(standing idea)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (windowed) | **FAIL** 29 | 19.06 ms | FAIL > 16.67, WARN > 8.33 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | **WARN** 62 | 27.53 ms | WARN > 25.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | **WARN** 53 | 41.35 ms (max 55.6 ms) | WARN > 33.33 ms |
| S3 | Hitches (> 33 ms) | **FAIL** 0 | 62 in 30 s (124.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## GPU / render
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| G1 | GPU render time avg | PASS 85 | 6.21 ms (p95 6.94) | FAIL > 16.7 ms, WARN > 8.3 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |
| G-draw_calls | Render draw calls (avg per frame) | PASS 87 | 1795 (max 1977) | WARN > 2500 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-objects | Render objects (avg per frame) | **WARN** 46 | 5339 (max 7079) | WARN > 4000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-primitives | Render primitives (avg per frame) | PASS 86 | 2591018 (max 2718830) | WARN > 3500000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-vmem | Video memory | INFO | 350 MB | info (GTX 1660: 6 GB) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P0 | Band profiler | INFO | no profiled run | run with --profile=1 for the hot list |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 3.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3805.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 114.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 507.0 | info |
| C6 | shadow casters | INFO | 170.0 | info |
| C7 | particle systems | INFO | 64.0 | info |
| C8 | multimesh nodes | INFO | 136.0 | info |
| C9 | nodes | INFO | 6213.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 3 ({"GPUParticles3D":3}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | -1.3 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | -11.6 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 26 other Godot process(es) (max 22 at once); other CPU load 105.2 %; calibration 27 ms vs best 19 (x1.4) | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hitches (worst first, what happened)
| Game time | Frame ms | Top bands | Events |
|---|---|---|---|
| 0:24 | 55.6 |  |  |
| 0:04 | 51.8 |  | 16 nodes added |
| 0:13 | 51.7 |  | 12 nodes added |
| 0:07 | 49.9 |  | 14 nodes added |
| 0:09 | 47.7 |  | 14 nodes added |
| 0:05 | 47.0 |  | 20 nodes added |
| 0:12 | 45.9 |  | 4 nodes added |
| 0:11 | 45.7 |  | 16 nodes added |
| 0:15 | 44.9 |  | 12 nodes added |
| 0:09 | 44.6 |  | 4 nodes added |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 1794.508 |
| draw_calls_max | 1977.0 |
| nav_agents | 74.003 |
| nav_agents_max | 109.0 |
| navigation_ms | 3.906 |
| navigation_ms_max | 5.146 |
| nodes_end | 7322.0 |
| objects | 5338.514 |
| objects_end | 18236.0 |
| objects_max | 7079.0 |
| physics_active_objects | 62.034 |
| physics_active_objects_max | 96.0 |
| physics_ms | 26.178 |
| physics_ms_max | 41.601 |
| physics_pairs | 66.003 |
| physics_pairs_max | 101.0 |
| primitives | 2591017.775 |
| primitives_max | 2718830.0 |
| process_ms | 20.473 |
| process_ms_max | 38.036 |
| resources_end | 1668.0 |
| static_mem_mb | 337.7 |
| video_mem_mb | 350.2 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":7.684,"tick_median_ms":1.738,"ticks":33.0,"worst_step":"champions","worst_step_ms":4.686}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
