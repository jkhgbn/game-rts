# Perf Lab scorecard: menu (windowed 1600x900)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:21:07 · 1 run(s) (median) · seed 1 · 20 s measured · lab v1.0

Scenario: main menu with the 3D diorama.

> **NOISY**: 33 other Godot process(es) (max 29 at once); other CPU load 94.8 %; calibration 26 ms vs best 19 (x1.3). Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **WARN** · perf score **98 / 100**

Frame avg **3.60 ms** · p95 5.04 · p99 5.35 · max 10.2 · hitches 0 · 1200 frames · units 0 · nodes 506

Repeats (frame avg ms): [3.595]

## Improve next
1. **Cache group lists**: Many per-frame functions call `get_tree().get_nodes_in_group(&"units")`: a shared per-frame cache (one array per group, rebuilt once per physics frame) removes the repeated allocations (ai-2v2.md:336 AIWorldCache pattern). _(standing idea)_
2. **Stagger periodic work**: Give every timer-driven tick (commander, brains, capture points, camps) a random phase offset so they never all fire on the same frame (ai-2v2.md:334). _(standing idea)_
3. **Visibility ranges and shadows**: Set visibility_range_end (with fade) on decor, critters and small props, and cast_shadow OFF on everything but trees / big rocks / buildings (map-fill.md:400). _(standing idea)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (windowed) | PASS 100 | 3.60 ms | FAIL > 16.67, WARN > 8.33 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | PASS 100 | 5.04 ms | WARN > 25.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | PASS 100 | 5.35 ms (max 10.2 ms) | WARN > 33.33 ms |
| S3 | Hitches (> 33 ms) | PASS 100 | 0 in 20 s (0.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## GPU / render
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| G1 | GPU render time avg | PASS 100 | 2.50 ms (p95 2.92) | FAIL > 16.7 ms, WARN > 8.3 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |
| G-draw_calls | Render draw calls (avg per frame) | PASS 96 | 449 (max 450) | WARN > 800 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-objects | Render objects (avg per frame) | PASS 100 | 688 (max 689) | WARN > 1500 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-primitives | Render primitives (avg per frame) | PASS 100 | 150026 (max 150775) | WARN > 1500000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-vmem | Video memory | INFO | 232 MB | info (GTX 1660: 6 GB) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P0 | Band profiler | INFO | no profiled run | run with --profile=1 for the hot list |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 5.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 455.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 0.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 194.0 | info |
| C6 | shadow casters | INFO | 51.0 | info |
| C7 | particle systems | INFO | 30.0 | info |
| C8 | multimesh nodes | INFO | 44.0 | info |
| C9 | nodes | INFO | 478.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | PASS 100 | 0 | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | +0.0 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | +0.1 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 33 other Godot process(es) (max 29 at once); other CPU load 94.8 %; calibration 26 ms vs best 19 (x1.3) | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 448.943 |
| draw_calls_max | 450.0 |
| nav_agents | 0.0 |
| nav_agents_max | 0.0 |
| navigation_ms | 0.489 |
| navigation_ms_max | 2.028 |
| nodes_end | 506.0 |
| objects | 687.791 |
| objects_end | 4149.0 |
| objects_max | 689.0 |
| physics_active_objects | 0.0 |
| physics_active_objects_max | 0.0 |
| physics_ms | 1.46 |
| physics_ms_max | 2.071 |
| physics_pairs | 0.0 |
| physics_pairs_max | 0.0 |
| primitives | 150025.623 |
| primitives_max | 150775.0 |
| process_ms | 23.865 |
| process_ms_max | 175.152 |
| resources_end | 821.0 |
| static_mem_mb | 199.6 |
| video_mem_mb | 231.8 |

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
- menu: diorama in its own SubViewport; GPU time = root + SubViewports
