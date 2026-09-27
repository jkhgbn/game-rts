# Perf Lab scorecard: late200 (windowed 1600x900)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:13:13 · 1 run(s) (median) · seed 1 · 30 s measured · lab v1.0

Scenario: 100 v 100 + 1 titan per side, every epic beast spawned, river / decor / critters on, camera sweep.

> **NOISY**: 27 other Godot process(es) (max 22 at once); other CPU load 88.6 %. Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **FAIL** · perf score **61 / 100**

Frame avg **28.93 ms** · p95 42.89 · p99 58.86 · max 211.6 · hitches 311 · 1800 frames · units 135 · nodes 10633

Repeats (frame avg ms): [28.929]

## Improve next
1. **Pool the VFX**: nodes were created under a VFX manager during the measure window (5 ({"GPUParticles3D":5})): pre-build them in the manager's _ready and restart them (art-units.md 8). _(check H1)_
2. **GPU: map dressing**: Costs 1.82 ms (25 % of the GPU frame, windowed ablation over the Crown Isle at zoom 55). Fix: art/environment/map_dressing.gd (+ the biome sets): visibility_range_end 65 / 90 m with fade on tufts / flowers / bushes (map-fill.md:400), cast_shadow OFF on everything but trees / logs / big rocks, density x0.6-0.8 (the open 12.L2 question, lead-status.md:115), and map_detail Low = half. _(GPU cost by layer)_
3. **GPU: sun shadows**: Costs 1.06 ms (15 % of the GPU frame, windowed ablation over the Crown Isle at zoom 55). Fix: the sun's shadows: shorter shadow max distance / fewer cascades at RTS zoom, and fewer casters (decor, small props). _(GPU cost by layer)_
4. **Fewer draw calls**: Render objects (avg per frame) = 8288 (max 11589): merge static decor into MultiMeshes per chunk (map-fill.md:400), set visibility_range_end on small props (65 / 90 m), and merge unit parts (art-units.md 8: <= 14 instances per unit). _(check G-objects)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (windowed) | **FAIL** 9 | 28.93 ms | FAIL > 16.67, WARN > 8.33 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | **WARN** 64 | 42.89 ms | WARN > 25.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | **WARN** 63 | 58.86 ms (max 211.6 ms) | WARN > 33.33 ms |
| S3 | Hitches (> 33 ms) | **FAIL** 0 | 311 in 30 s (622.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## GPU / render
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| G1 | GPU render time avg | PASS 71 | 8.21 ms (p95 10.25) | FAIL > 16.7 ms, WARN > 8.3 ms (cinematics.md:316-317, map-fill.md:406 (60 fps at 1600x900 / 3440x1440); warn 120 Hz (lab default)) |
| G-draw_calls | Render draw calls (avg per frame) | PASS 98 | 2156 (max 2754) | WARN > 4000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-objects | Render objects (avg per frame) | **WARN** 50 | 8288 (max 11589) | WARN > 6500 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-primitives | Render primitives (avg per frame) | PASS 93 | 3108289 (max 3602914) | WARN > 5000000 (lab default (art-units.md:627: 200 units ~ 2 800 draw instances; art-keep.md:294: base <= 60 draw calls)) |
| G-vmem | Video memory | INFO | 357 MB | info (GTX 1660: 6 GB) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P0 | Band profiler | INFO | no profiled run | run with --profile=1 for the hot list |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 6.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3795.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 114.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 550.0 | info |
| C6 | shadow casters | INFO | 176.0 | info |
| C7 | particle systems | INFO | 80.0 | info |
| C8 | multimesh nodes | INFO | 136.0 | info |
| C9 | nodes | INFO | 6400.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | **FAIL** 0 | 5 ({"GPUParticles3D":5}) | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | -2.9 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | -18.5 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 27 other Godot process(es) (max 22 at once); other CPU load 88.6 % | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## GPU cost by layer (windowed ablation: tree paused, camera over the Crown Isle at zoom 55)
| Layer hidden | Baseline GPU ms | Hidden GPU ms | Cost ms | Cost % |
|---|---|---|---|---|
| map dressing (biome decor, cliffs, border) | 7.18 | 5.36 | 1.82 | 25.3 % |
| env props (trees, rocks, pillars) | 7.21 | 7.00 | 0.22 | 3.0 % |
| river meshes (water, riverbed, fords, bridges) | 7.19 | 7.02 | 0.17 | 2.3 % |
| cosmetic critters | 7.45 | 7.25 | 0.20 | 2.7 % |
| units, titans, beasts (98) | 7.33 | 6.85 | 0.48 | 6.6 % |
| buildings (3) | 7.15 | 7.18 | -0.03 | -0.4 % |
| sun shadows | 7.24 | 6.18 | 1.06 | 14.6 % |
| HUD | 7.36 | 7.08 | 0.28 | 3.8 % |

## Hitches (worst first, what happened)
| Game time | Frame ms | Top bands | Events |
|---|---|---|---|
| 0:31 | 211.6 |  |  |
| 0:32 | 75.1 |  | 1 nodes added |
| 0:04 | 73.8 |  |  |
| 0:04 | 73.2 |  | 36 nodes added |
| 0:05 | 68.0 |  | 14 nodes added |
| 0:05 | 66.3 |  |  |
| 0:05 | 65.9 |  | 36 nodes added |
| 0:06 | 63.9 |  |  |
| 0:07 | 63.7 |  |  |
| 0:09 | 62.4 |  | 10 nodes added |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 2156.303 |
| draw_calls_max | 2754.0 |
| nav_agents | 147.359 |
| nav_agents_max | 204.0 |
| navigation_ms | 6.371 |
| navigation_ms_max | 8.622 |
| nodes_end | 9394.0 |
| objects | 8288.111 |
| objects_end | 21292.0 |
| objects_max | 11589.0 |
| physics_active_objects | 134.207 |
| physics_active_objects_max | 189.0 |
| physics_ms | 30.977 |
| physics_ms_max | 47.629 |
| physics_pairs | 153.922 |
| physics_pairs_max | 210.0 |
| primitives | 3108289.193 |
| primitives_max | 3602914.0 |
| process_ms | 28.752 |
| process_ms_max | 191.892 |
| resources_end | 1778.0 |
| static_mem_mb | 366.2 |
| video_mem_mb | 356.8 |

## AI think ticks (commander.gd counters)
`{"commanders":1.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":9.084,"tick_median_ms":3.228,"ticks":33.0,"worst_step":"champions","worst_step_ms":4.484}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
- titans: 2 (rime_colossus stats + war_mammoth, nightmare_knight models; no gameplay titan yet)
- epic beasts spawned: 8
