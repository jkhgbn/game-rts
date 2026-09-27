# Perf Lab scorecard: early (headless logic)

Commit `main@49ff2b29cb+wip` · 2026-09-26 21:56:45 · 1 run(s) (median) · seed 1 · 45 s measured · lab v1.0

Scenario: 1v1 skirmish from 0:20 to 1:05, both sides normal Commanders, full art and map fill.

> **NOISY**: 40 other Godot process(es) (max 30 at once); other CPU load 100.2 %; 46 other Godot process(es) (max 31 at once); other CPU load 102.5 %; calibration 109 ms vs best 19 (x5.6). Treat the numbers as an upper bound; re-run on a quiet PC before comparing.

## Result: **FAIL** · perf score **42 / 100**

Frame avg **22.82 ms** · p95 150.78 · p99 207.39 · max 381.0 · hitches 328 · 2700 frames · units 26 · nodes 6832

Repeats (frame avg ms): [22.818]

## Improve next
1. **Split the Commander's worst think step**: Commander think tick median = 0.631 ms over 128 ticks (step scout). The worst step is `scout` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked. _(check A1)_
2. **HUD refresh**: 1.926 ms / frame over 1 nodes. `scripts/ui/command_card.gd`: refresh labels / bars on signals or at 4-10 Hz instead of every _process, and only set text when it changed. _(hot list: `scripts/ui/command_card.gd`)_
3. **Cheaper unit ticks**: 0.404 ms / frame over 14 nodes. shader parameter write (unit.gd:1948 in `_update_hp_bar()`, unit.gd:1949 in `_update_hp_bar()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `scripts/units/unit.gd` `_physics_process`: run target acquisition / aggro scans every 0.2-0.3 s with a per-unit offset instead of every frame, use a spatial hash for nearest-enemy, and skip idle units. _(hot list: `scripts/units/unit.gd`)_
4. **VFX manager**: 0.368 ms / frame over 1 nodes. allocation (.new()) (capture_rings.gd:284 in `_add_ring()`, capture_rings.gd:287 in `_add_ring()`, capture_rings.gd:289 in `_add_ring()`). Fix: pool the object / node, or reuse a member instead of allocating per frame. `scripts/vfx/capture_rings.gd`: keep effects pooled (pre-built, restarted) and let idle pools stop processing (set_process(false) while nothing plays). _(hot list: `scripts/vfx/capture_rings.gd`)_
5. **Logic frame over budget**: Frame avg 22.82 ms: start with the top rows of the hot list; the unit tick and NavigationAgent3D avoidance scale with the unit count. _(check F1)_

## Frame time
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| F1 | Frame avg (logic) | **FAIL** 0 | 22.82 ms | FAIL > 3.00, WARN > 2.10 ms (waves.md:82 (8 ms / 100 units, scaled to the early-game unit count, floor 3 ms); warn 5.5 / 100 (waves.md:226) (26 units)) |

## Frame shape (spikes, hitches)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| S1 | Frame p95 | **WARN** 35 | 150.78 ms | WARN > 4.50 ms (1.5x the avg budget) |
| S2 | Frame p99 | **WARN** 35 | 207.39 ms (max 381.0 ms) | WARN > 6.00 ms |
| S3 | Hitches (> 33 ms) | **FAIL** 0 | 328 in 45 s (437.33 / min) | FAIL > 3.0 / min, WARN > 0.5 / min (lab default (docs/plan/perf-lab.md 'Budgets')) |

## Systems (band profiler)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| P1 | AI commanders avg | PASS 100 | avg 0.128 ms, median 0.003, max 146.06 ms | FAIL > 0.600 ms, WARN > 0.450 (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1a | AI commanders worst frame | **FAIL** 0 | 146.06 ms | FAIL > 1.5 ms (ai-2v2.md:340 (AI <= 0.6 ms/frame avg, no frame > 1.5 ms); ai.md:146 (tick < 0.3 ms); median 0.1 = lab target) |
| P1b | AI commanders median frame | PASS 100 | 0.003 ms | WARN > 0.10 ms (lab target) |
| P2 | Epic beast brains avg | **FAIL** 15 | avg 0.047 ms, median 0.004, max 113.63 ms | FAIL > 0.030 ms, WARN > 0.022 (map-fill.md:403 (8 beasts < 0.03 ms)) |
| P3 | Map fill services avg | PASS 86 | avg 0.111 ms, median 0.016, max 98.49 ms | FAIL > 0.200 ms, WARN > 0.150 (map-fill.md:398 (map fill < 0.2 ms: river 0.03, points 0.03, camps 0.02)) |
| P4 | Critters (game + cosmetic) avg | **FAIL** 0 | avg 0.249 ms, median 0.036, max 141.23 ms | FAIL > 0.110 ms, WARN > 0.083 (map-fill.md:398 + :404 (CritterSystem < 0.08, game critters < 0.03)) |
| P5 | Trade avg | **FAIL** 33 | avg 0.103 ms, median 0.026, max 183.53 ms | FAIL > 0.100 ms, WARN > 0.075 (market-trade.md:128 (all trade logic < 0.1 ms)) |
| P6 | Fog of war avg | PASS 100 | avg 0.068 ms, median 0.004, max 8.09 ms | FAIL > 0.300 ms, WARN > 0.225 (lab default (fog-of-war.md:42-47: 5 Hz, < 10 000 byte writes per update)) |
| P7 | VFX managers avg | **FAIL** 15 | avg 0.777 ms, median 0.190, max 155.13 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default (for-lead.md:94: MapFillVfx 15-150 us; pools, no runtime instancing)) |
| P8 | HUD / minimap / UI avg | **FAIL** 0 | avg 4.368 ms, median 0.694, max 276.08 ms | FAIL > 0.500 ms, WARN > 0.375 (lab default) |
| P9 | Unit / building models (art scripts) avg | **FAIL** 0 | avg 1.406 ms, median 0.371, max 165.27 ms | FAIL > 0.130 ms, WARN > 0.098 (art-units.md:633 (<= +0.5 ms per 100 units of animation CPU)) |
| P10 | Units (gameplay) | INFO | avg 1.314 ms, median 0.269, max 187.00 ms | inside the frame budget (part of the 8 ms / 100 units logic budget (waves.md:82)) |
| P11 | Buildings | INFO | avg 0.158 ms, median 0.043, max 152.80 ms | inside the frame budget (part of the logic budget) |
| P12 | Level / world | INFO | avg 0.460 ms, median 0.123, max 161.24 ms | inside the frame budget (part of the logic budget) |
| P13 | Other art scripts | INFO | avg 0.345 ms, median 0.081, max 202.19 ms | inside the frame budget (part of the logic budget) |
| A1 | Commander think tick median | **FAIL** 0 | 0.631 ms over 128 ticks (step scout) | FAIL > 0.3 ms (ai.md:146), WARN > 0.1 ms (lab target; ai-2v2.md:340 median <= 0.25) |
| A2 | Commander think tick max | **FAIL** 0 | 186.84 ms (step scout) | FAIL > 1.5 ms (no frame > 1.5 ms of AI), WARN > 0.45 (ai-2v2.md:340) |

## Scene census
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| C1 | lights | PASS 100 | 4.0 | FAIL > 15 (step12-agent-rules.md:27-28 (the skirmish's 15 omni lights are the cap; 0 new real lights)) |
| C2 | shadow lights | PASS 100 | 1.0 | FAIL > 1 (art-keep.md:291 / map-fill.md:400 (the sun is the only shadow-casting light)) |
| C3 | decor instances | PASS 100 | 3664.0 | FAIL > 12000 (map-fill.md:400 (<= 12 000 decor instances)) |
| C4 | draw nodes decor | PASS 100 | 109.0 | WARN > 140 (map-2v2.md:227 (<= 140 draw nodes; 1v1 checked as WARN)) |
| C5 | geometry nodes | INFO | 451.0 | info |
| C6 | shadow casters | INFO | 161.0 | info |
| C7 | particle systems | INFO | 41.0 | info |
| C8 | multimesh nodes | INFO | 134.0 | info |
| C9 | nodes | INFO | 6044.0 | info |

## Health (leaks, pools, noise)
| # | Check | Result | Measured | Rule |
|---|---|---|---|---|
| H1 | VFX nodes created after warm-up | PASS 100 | 0 | FAIL > 0 (art-units.md:631, champion-skill-tree.md:361 (pooled one-shots, never instanced at runtime)) |
| H2 | Orphan nodes at the end | PASS 100 | 0 | WARN > 0 (lab default (orphans = leaked nodes)) |
| H3 | Node growth (non-unit) | PASS 100 | +0.0 % | WARN > 10 % (lab default (nodes after warm-up vs the end, units excluded)) |
| H4 | Static memory growth | INFO | +0.9 MB | info |
| H5 | Machine noise | **WARN** 50 | noisy: 40 other Godot process(es) (max 30 at once); other CPU load 100.2 %; 46 other Godot process(es) (max 31 at once); other CPU load 102.5 %; calibration 109 ms vs best 19 (x5.6) | WARN when other Godot processes ran or the CPU was busy (numbers not comparable) |

## Hot list (band profiler, top 15 scripts by avg ms per frame)
| # | Script | System | Nodes | Avg ms | Median | p95 | Max ms | Share |
|---|---|---|---|---|---|---|---|---|
| 1 | `scripts/ui/command_card.gd` | HUD / minimap / UI | 1 | 1.926 | 0.094 | 3.286 | 275.24 | 9.0 % |
| 2 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | 1 | 0.848 | 0.230 | 0.446 | 159.52 | 3.9 % |
| 3 | `scripts/economy/worker.gd` | Units (gameplay) | 10 | 0.487 | 0.143 | 0.259 | 164.05 | 2.3 % |
| 4 | `scripts/units/unit.gd` | Units (gameplay) | 14 | 0.404 | 0.072 | 0.740 | 186.83 | 1.9 % |
| 5 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | 1 | 0.376 | 0.017 | 0.613 | 154.29 | 1.7 % |
| 6 | `scripts/vfx/capture_rings.gd` | VFX managers | 1 | 0.368 | 0.004 | 0.177 | 148.34 | 1.7 % |
| 7 | `art/buildings/capture/wayshrine/wayshrine.gd` | Unit / building models (art scripts) | 2 | 0.235 | 0.050 | 0.080 | 161.49 | 1.1 % |
| 8 | `art/units/wizards/vessa.gd` | Unit / building models (art scripts) | 2 | 0.203 | 0.040 | 0.084 | 150.30 | 0.9 % |
| 9 | `scripts/ui/champion_bar.gd` | HUD / minimap / UI | 1 | 0.201 | 0.021 | 0.237 | 139.12 | 0.9 % |
| 10 | `scripts/ui/inventory_bar.gd` | HUD / minimap / UI | 1 | 0.193 | 0.037 | 0.055 | 149.41 | 0.9 % |
| 11 | `scripts/ui/portrait.gd` | HUD / minimap / UI | 1 | 0.175 | 0.015 | 0.023 | 161.93 | 0.8 % |
| 12 | `[NavigationAgent3D]` | Built-in nodes ([NavigationAgent3D]) | 26 | 0.173 | 0.013 | 0.016 | 129.70 | 0.8 % |
| 13 | `art/buildings/guilds/magpie_den/magpie_den_model.gd` | Unit / building models (art scripts) | 2 | 0.160 | 0.014 | 0.017 | 139.31 | 0.7 % |
| 14 | `art/units/neutral/critters/rabbit.gd` | Unit / building models (art scripts) | 12 | 0.152 | 0.012 | 0.015 | 134.72 | 0.7 % |
| 15 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | 1 | 0.149 | 0.020 | 0.156 | 125.82 | 0.7 % |

Engine gaps (avg ms per frame): physics + navigation server step 5.916 · render / tweens / idle 3.020 · unclassified nodes 2.268 · probe overhead ~0.367

## Hitches (worst first, what happened)
| Game time | Frame ms | Top bands | Events |
|---|---|---|---|
| 0:23 | 381.0 |  |  |
| 0:47 | 247.9 |  |  |
| 0:23 | 243.1 |  |  |
| 0:23 | 235.4 |  |  |
| 0:32 | 234.6 |  |  |
| 0:37 | 233.2 |  |  |
| 0:48 | 230.7 |  |  |
| 0:22 | 228.7 |  |  |
| 0:27 | 228.6 |  |  |
| 0:22 | 224.0 |  |  |

## Performance monitors (avg over the measured frames)
Godot's TIME_* monitors (process_ms, physics_ms, navigation_ms) are not reliable headless (see tests/perf_test.gd): use the frame times and the band profiler.

| Monitor | Value |
|---|---|
| draw_calls | 0.0 |
| draw_calls_max | 0.0 |
| nav_agents | 35.789 |
| nav_agents_max | 36.0 |
| navigation_ms | 82.892 |
| navigation_ms_max | 216.467 |
| nodes_end | 6839.0 |
| objects | 0.0 |
| objects_end | 17985.0 |
| objects_max | 0.0 |
| physics_active_objects | 25.789 |
| physics_active_objects_max | 26.0 |
| physics_ms | 143.423 |
| physics_ms_max | 241.323 |
| physics_pairs | 27.802 |
| physics_pairs_max | 64.0 |
| primitives | 0.0 |
| primitives_max | 0.0 |
| process_ms | 160.977 |
| process_ms_max | 377.239 |
| resources_end | 1640.0 |
| static_mem_mb | 195.1 |
| video_mem_mb | 0.0 |

## AI think ticks (commander.gd counters)
`{"commanders":2.0,"note":"commander.gd counters since the match start (first tick not counted)","tick_max_ms":186.838,"tick_median_ms":0.631,"ticks":128.0,"worst_step":"scout","worst_step_ms":186.003}`

## Notes
- Budgets: `tools/perf_lab/perf_budgets.gd` (sources in the Rule column). Score: weighted checks, PASS 70-100, WARN 35-69, FAIL 0-34.
- Frame numbers come from runs without the band profiler; the hot list from one profiled run (marker overhead listed above).
