# Perf Lab scorecard: menu (headless logic)

Commit `main@49ff2b29cb+wip` · 2026-09-26 22:20:33 · 1 run(s) (median) · seed 1 · 20 s measured · lab v1.0

Scenario: main menu with the 3D diorama.

> **NOISY**: 43 other Godot process(es) (max 27 at once); other CPU load 92 %; calibration 25 ms vs best 19 (x1.3); 29 other Godot process(es) (max 23 at once); other CPU load 91 %. Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **WARN** · perf score **97 / 100**

Frame avg **0.25 ms** · p95 0.34 · p99 1.03 · max 27.8 · hitches 0 · 1200 frames · units 0 · nodes 506

Repeats (frame avg ms): [0.254]

## Improve next
1. **Map art**: 0.041 ms / frame over 1 nodes. shader parameter write (menu_diorama.gd:249 in `_animate_glows()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `art/environment/menu_diorama/menu_diorama.gd`: move per-frame animation into shaders (TIME) and use visibility ranges. _(hot list: `art/environment/menu_diorama/menu_diorama.gd`)_
2. **Unit model animation**: 0.028 ms / frame over 1 nodes. shader parameter write (torvald.gd:600 in `_wizard_process()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `art/units/wizards/torvald.gd`: animate at a reduced rate beyond 30 m and freeze off-screen (art-units.md 6.10); keep pivot writes <= 7 per frame. _(hot list: `art/units/wizards/torvald.gd`)_
3. **Cache group lists**: Many per-frame functions call `get_tree().get_nodes_in_group(&"units")`: a shared per-frame cache (one array per group, rebuilt once per physics frame) removes the repeated allocations (ai-2v2.md:336 AIWorldCache pattern). _(standing idea)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (logic) | PASS 100 | 0.25 ms | FAIL > 2.00, WARN > 1.00 ms (lab default (the menu has no game logic: 2 ms, warn 1 ms) (0 units)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | PASS 100 | 0.34 ms | WARN > 3.00 ms (1.5x the avg budget) |
| S2 | Frame p99 | PASS 100 | 1.03 ms (max 27.8 ms) | WARN > 4.00 ms |
| S3 | Hitches (> 33 ms) | PASS 100 | 0 in 20 s (0.00 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P1 | HUD / minimap / UI avg | PASS 100 | avg 0.007 ms, median 0.005, max 1.37 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default) |
| P2 | Unit / building models (art scripts) | INFO | avg 0.144 ms, median 0.115, max 1.96 ms | inside the frame budget (art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)) |
| P3 | Other art scripts | INFO | avg 0.058 ms, median 0.040, max 2.88 ms | inside the frame budget (part of the logic budget) |

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
| H4 | Static memory growth | INFO | +0.0 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 43 other Godot process(es) (max 27 at once); other CPU load 92 %; calibration 25 ms vs best 19 (x1.3); 29 other Godot process(es) (max 23 at once); other CPU load 91 % | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hot list (band profiler, top 15 scripts by avg ms per frame)
| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |
|---|---|---|---|---|---|---|---|---|
| 1 | `art/environment/menu_diorama/menu_diorama.gd` | Other art scripts | 1 | 0.041 | 0.028 | 0.064 | 2.85 | 11.7 % |
| 2 | `art/units/wizards/torvald.gd` | Unit / building models (art scripts) | 1 | 0.028 | 0.019 | 0.040 | 1.69 | 8.0 % |
| 3 | `art/units/wizards/ysolde.gd` | Unit / building models (art scripts) | 1 | 0.024 | 0.016 | 0.046 | 0.82 | 6.9 % |
| 4 | `art/units/wizards/malrik.gd` | Unit / building models (art scripts) | 1 | 0.019 | 0.022 | 0.039 | 0.85 | 5.4 % |
| 5 | `art/units/champions/mender/mender.gd` | Unit / building models (art scripts) | 1 | 0.018 | 0.017 | 0.032 | 1.60 | 5.1 % |
| 6 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | 30 | 0.017 | 0.012 | 0.019 | 1.51 | 4.8 % |
| 7 | `art/environment/crown/crown_pedestal_art.gd` | Other art scripts | 1 | 0.016 | 0.012 | 0.025 | 0.73 | 4.6 % |
| 8 | `art/units/wizards/vessa.gd` | Unit / building models (art scripts) | 1 | 0.015 | 0.016 | 0.030 | 1.11 | 4.3 % |
| 9 | `art/units/champions/oathwall/oathwall.gd` | Unit / building models (art scripts) | 1 | 0.015 | 0.015 | 0.029 | 1.48 | 4.2 % |
| 10 | `art/units/champions/wayfinder/wayfinder.gd` | Unit / building models (art scripts) | 1 | 0.011 | 0.011 | 0.019 | 1.79 | 3.2 % |
| 11 | `art/buildings/tavern/tavern_model.gd` | Unit / building models (art scripts) | 1 | 0.007 | 0.005 | 0.008 | 0.80 | 1.9 % |
| 12 | `art/units/kit/mount_model.gd` | Unit / building models (art scripts) | 0 | 0.003 | 0.002 | 0.003 | 0.74 | 0.9 % |
| 13 | `scripts/ui/menus/main_menu.gd` | HUD / minimap / UI | 1 | 0.003 | 0.002 | 0.002 | 1.36 | 0.9 % |
| 14 | `scripts/ui/menus/kingdom_card.gd` | HUD / minimap / UI | 8 | 0.002 | 0.002 | 0.002 | 0.57 | 0.6 % |
| 15 | `art/units/kit/character_model.gd` | Unit / building models (art scripts) | 0 | 0.002 | 0.002 | 0.002 | 0.15 | 0.6 % |

Engine gaps (avg ms per frame): physics + navigation server step 0.009 · render / tweens / idle 0.054 · unclassified nodes 0.004 · probe overhead ~0.060

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 0.0 |
| draw_calls_max | 0.0 |
| nav_agents | 0.0 |
| nav_agents_max | 0.0 |
| navigation_ms | 0.004 |
| navigation_ms_max | 0.004 |
| nodes_end | 506.0 |
| objects | 0.0 |
| objects_end | 4239.0 |
| objects_max | 0.0 |
| physics_active_objects | 0.0 |
| physics_active_objects_max | 0.0 |
| physics_ms | 152.969 |
| physics_ms_max | 152.969 |
| physics_pairs | 0.0 |
| physics_pairs_max | 0.0 |
| primitives | 0.0 |
| primitives_max | 0.0 |
| process_ms | 0.492 |
| process_ms_max | 0.492 |
| resources_end | 821.0 |
| static_mem_mb | 97.5 |
| video_mem_mb | 0.0 |

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
- menu: diorama in its own SubViewport; GPU time = root + SubViewports
