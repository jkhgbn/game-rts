# Map Lab: Fourfold Hollow (2v2) scorecard: world_forge_fourfold_hollow

2026-09-27 15:32 · lab v1.0 · 123.04 s · scanned 99 spots

## Result: **WARN** · score **98 / 100**

0 FAIL · 1 WARN · 13 PASS · 1 info checks; findings: 0 FAIL, 205 WARN, 136 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): node_a_a1-bristleback_b1 vs node_a_b2-bristleback_a2: 143.8 m vs 176.7 m (18.6 %) -> units walk node_a_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 6936 / 7272 pairs within 2 % (0 FAIL, 205 WARN, 131 info))_
2. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_
3. **Combat heat from bot games** (IDEA): v2: feed Bot Lab / Replay Lab unit deaths into the heat map _(from lab idea)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 213 polygons, main area 26951 m² (95 % of the 168 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 99 / 99 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 4 / 4 clean, 5 info | ground-level components other than the main one < 2 m² |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 99 / 99 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 99 / 99 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 7272 / 7272 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 6936 / 7272 pairs within 2 % (0 FAIL, 205 WARN, 131 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | PASS 100 | 10 / 10 clean | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | PASS 100 | 4 / 4 clean | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 7 / 7 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 6 / 6 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 12 / 12 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (672 x 672 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | node_a_a1-bristleback_b1 vs node_a_b2-bristleback_a2 | 143.8 m vs 176.7 m (18.6 %) | units walk node_a_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-node_b_a1 vs keep_t4-node_b_b1 | 59.3 m vs 72.8 m (18.6 %) | units walk keep_t4-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-node_b_b2 vs keep_t4-node_b_b1 | 59.3 m vs 72.8 m (18.6 %) | units walk keep_t4-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-bristleback_b2 vs node_a_b2-bristleback_a2 | 143.8 m vs 176.7 m (18.6 %) | units walk node_a_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-bristleback_a1 vs node_a_b2-bristleback_a2 | 143.9 m vs 176.7 m (18.5 %) | units walk node_a_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_a1 vs node_a_b2-node_b_b1 | 55.1 m vs 67.1 m (17.9 %) | units walk node_a_b2-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-node_b_b2 vs node_a_b2-node_b_b1 | 55.1 m vs 67.1 m (17.9 %) | units walk node_a_b2-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_a2 vs keep_t4-node_b_b1 | 59.8 m vs 72.8 m (17.8 %) | units walk keep_t4-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_a2-node_b_a1 | 66.9 m vs 55.1 m (17.6 %) | units walk node_a_a1-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_b1-node_b_b2 | 66.9 m vs 55.1 m (17.6 %) | units walk node_a_a1-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-mossmere_b2 vs node_mid_b2-mossmere_a2 | 86.3 m vs 104.4 m (17.4 %) | units walk node_mid_b2-mossmere_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-mossmere_a1 vs node_mid_b2-mossmere_a2 | 86.4 m vs 104.4 m (17.3 %) | units walk node_mid_b2-mossmere_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-mossmere_b1 vs node_mid_b2-mossmere_a2 | 86.4 m vs 104.4 m (17.3 %) | units walk node_mid_b2-mossmere_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-tavern_b1 vs node_b_b2-tavern_a2 | 92.8 m vs 111.3 m (16.7 %) | units walk node_b_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-tavern_a1 vs node_b_b2-tavern_a2 | 92.8 m vs 111.3 m (16.7 %) | units walk node_b_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-tavern_b1 vs node_b_a2-tavern_b2 | 92.8 m vs 111.3 m (16.7 %) | units walk node_b_a2-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-tavern_b2 vs node_b_b1-tavern_a1 | 111.3 m vs 92.8 m (16.7 %) | units walk node_b_a2-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-bridge_nest_b2 vs millwatch_b1-bridge_nest_a2 | 37.0 m vs 31.0 m (16.3 %) | units walk millwatch_a1-bridge_nest_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-bridge_nest_b2 vs millwatch_a2-bridge_nest_b1 | 37.0 m vs 31.0 m (16.3 %) | units walk millwatch_a1-bridge_nest_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-bristleback_b2 vs millwatch_b2-bristleback_a1 | 65.7 m vs 77.9 m (15.7 %) | units walk millwatch_b2-bristleback_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-bridge_nest_b2 vs millwatch_b2-bridge_nest_a1 | 37.0 m vs 31.3 m (15.5 %) | units walk millwatch_a1-bridge_nest_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-bristleback_b2 vs millwatch_b1-bristleback_a2 | 65.7 m vs 77.7 m (15.5 %) | units walk millwatch_b1-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-mossmere_b1 vs node_b_b2-mossmere_a2 | 102.9 m vs 121.6 m (15.4 %) | units walk node_b_b2-mossmere_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-mossmere_a1 vs node_b_b2-mossmere_a2 | 102.9 m vs 121.6 m (15.4 %) | units walk node_b_b2-mossmere_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-mossmere_b1 vs node_b_a2-mossmere_b2 | 102.9 m vs 121.6 m (15.4 %) | units walk node_b_a2-mossmere_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-mossmere_b2 vs node_b_b1-mossmere_a1 | 121.6 m vs 102.9 m (15.4 %) | units walk node_b_a2-mossmere_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-bristleback_b2 vs millwatch_a2-bristleback_b1 | 65.7 m vs 77.5 m (15.3 %) | units walk millwatch_a2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-millwatch_b2 vs millrace_b1-millwatch_a1 | 93.7 m vs 110.5 m (15.2 %) | units walk millrace_b1-millwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-millwatch_a1 vs millrace_b2-millwatch_a2 | 110.5 m vs 93.7 m (15.2 %) | units walk millrace_b1-millwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-millwatch_b1 vs millrace_b1-millwatch_a1 | 93.7 m vs 110.5 m (15.2 %) | units walk millrace_b1-millwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-bridge_nest_a1 vs millrace_b2-bridge_nest_a2 | 121.8 m vs 103.6 m (15.0 %) | units walk millrace_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-bridge_nest_b2 vs millrace_b1-bridge_nest_a1 | 103.6 m vs 121.8 m (15.0 %) | units walk millrace_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-bridge_nest_b1 vs millrace_b1-bridge_nest_a1 | 103.7 m vs 121.8 m (14.9 %) | units walk millrace_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-node_mid_b1 vs node_b_a2-node_mid_b2 | 116.0 m vs 135.5 m (14.4 %) | units walk node_b_a2-node_mid_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-node_mid_b2 vs node_b_b1-node_mid_a1 | 135.5 m vs 116.0 m (14.3 %) | units walk node_b_a2-node_mid_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-greywater_lodge_a1 vs bristleback_a2-greywater_lodge_a1 | 49.0 m vs 56.7 m (13.6 %) | units walk bristleback_a2-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a2-greywater_lodge_a1 vs bristleback_b2-greywater_lodge_b1 | 56.7 m vs 49.0 m (13.6 %) | units walk bristleback_a2-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a2-greywater_lodge_a1 vs bristleback_b1-greywater_lodge_b1 | 56.7 m vs 49.0 m (13.6 %) | units walk bristleback_a2-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-mouth_lair_b1 vs millrace_b2-mouth_lair_a2 | 138.6 m vs 120.9 m (12.8 %) | units walk millrace_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-mouth_lair_b1 vs millrace_a2-mouth_lair_b2 | 138.6 m vs 121.0 m (12.7 %) | units walk millrace_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-mouth_lair_a1 vs millrace_b2-mouth_lair_a2 | 138.3 m vs 120.9 m (12.5 %) | units walk millrace_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-mouth_lair_b2 vs millrace_b1-mouth_lair_a1 | 121.0 m vs 138.3 m (12.5 %) | units walk millrace_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-mouth_lair_a1 vs keep_t4-mouth_lair_b1 | 119.5 m vs 136.4 m (12.4 %) | units walk keep_t4-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-mouth_lair_b2 vs keep_t4-mouth_lair_b1 | 119.5 m vs 136.4 m (12.4 %) | units walk keep_t4-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-mouth_lair_a2 vs keep_t3-mouth_lair_a1 | 136.2 m vs 119.5 m (12.2 %) | units walk keep_t0-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-mouth_lair_a2 vs keep_t1-mouth_lair_b2 | 136.2 m vs 119.5 m (12.2 %) | units walk keep_t0-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-cache_b2 vs node_mid_b2-cache_a2 | 104.3 m vs 118.5 m (12.0 %) | units walk node_mid_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-cache_a1 vs node_mid_b2-cache_a2 | 104.4 m vs 118.5 m (11.9 %) | units walk node_mid_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-cache_b1 vs node_mid_b2-cache_a2 | 104.4 m vs 118.5 m (11.9 %) | units walk node_mid_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-node_mid_b1 vs node_b_b2-node_mid_a2 | 116.0 m vs 131.4 m (11.7 %) | units walk node_b_b2-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-node_mid_a1 vs node_b_b2-node_mid_a2 | 116.0 m vs 131.4 m (11.7 %) | units walk node_b_b2-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-magpie_den_b1 vs rich_a2-magpie_den_b1 | 114.3 m vs 129.4 m (11.7 %) | units walk rich_a2-magpie_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-magpie_den_b1 vs rich_b2-magpie_den_a1 | 129.4 m vs 114.4 m (11.6 %) | units walk rich_a2-magpie_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-magpie_den_b1 vs rich_b1-magpie_den_a1 | 129.4 m vs 114.5 m (11.5 %) | units walk rich_a2-magpie_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-greywater_lodge_a1 vs millstone_cross_b1-greywater_lodge_b1 | 96.3 m vs 85.2 m (11.5 %) | units walk millstone_cross_a1-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-greywater_lodge_a1 vs millstone_cross_b2-greywater_lodge_b1 | 96.3 m vs 85.2 m (11.5 %) | units walk millstone_cross_a1-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-greywater_lodge_a1 vs millstone_cross_b2-greywater_lodge_b1 | 96.3 m vs 85.2 m (11.5 %) | units walk millstone_cross_a2-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-greywater_lodge_a1 vs millstone_cross_b1-greywater_lodge_b1 | 96.3 m vs 85.2 m (11.5 %) | units walk millstone_cross_a2-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-heath_lair_b2 vs heron_ford_b2-heath_lair_a2 | 152.1 m vs 171.8 m (11.5 %) | units walk heron_ford_b2-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a2-steps_e vs bristleback_b1-steps_w | 95.4 m vs 85.0 m (11.0 %) | units walk bristleback_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-steps_e vs bristleback_a2-steps_e | 85.0 m vs 95.4 m (10.9 %) | units walk bristleback_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-cache_b1 vs node_b_b2-cache_a2 | 120.9 m vs 135.7 m (10.9 %) | units walk node_b_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-cache_a1 vs node_b_b2-cache_a2 | 120.9 m vs 135.7 m (10.9 %) | units walk node_b_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-cache_b1 vs node_b_a2-cache_b2 | 120.9 m vs 135.7 m (10.9 %) | units walk node_b_a2-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-cache_b2 vs node_b_b1-cache_a1 | 135.7 m vs 120.9 m (10.9 %) | units walk node_b_a2-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-node_b_b1 vs node_b_b2-node_b_a2 | 132.6 m vs 148.7 m (10.8 %) | units walk node_b_b2-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_b1-steps_w vs bristleback_b2-steps_w | 85.0 m vs 95.3 m (10.8 %) | units walk bristleback_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-wayshrine_b1 vs node_mid_b2-wayshrine_a1 | 79.3 m vs 88.9 m (10.8 %) | units walk node_mid_b2-wayshrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-steps_e vs bristleback_b2-steps_w | 85.0 m vs 95.3 m (10.8 %) | units walk bristleback_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-wayshrine_a1 vs node_mid_b2-wayshrine_a1 | 79.4 m vs 88.9 m (10.7 %) | units walk node_mid_b2-wayshrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-wayshrine_b1 vs node_mid_b2-wayshrine_a1 | 79.4 m vs 88.9 m (10.7 %) | units walk node_mid_b2-wayshrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-bristleback_a1 vs millrace_b2-bristleback_a2 | 117.2 m vs 131.2 m (10.7 %) | units walk millrace_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-bristleback_b2 vs millrace_b1-bristleback_a1 | 131.1 m vs 117.2 m (10.6 %) | units walk millrace_a2-bristleback_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-bristleback_b1 vs millrace_b2-bristleback_a2 | 117.5 m vs 131.2 m (10.4 %) | units walk millrace_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-bristleback_b1 vs millrace_a2-bristleback_b2 | 117.5 m vs 131.1 m (10.4 %) | units walk millrace_a2-bristleback_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-fordwatch_b1 vs millrace_b2-fordwatch_a2 | 95.3 m vs 85.4 m (10.3 %) | units walk millrace_a1-fordwatch_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-mouth_lair_b2 vs node_a_b2-mouth_lair_b1 | 117.3 m vs 130.7 m (10.3 %) | units walk node_a_b2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_a1 vs node_a_b2-mouth_lair_b1 | 117.3 m vs 130.7 m (10.3 %) | units walk node_a_b2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-fordwatch_b1 vs millrace_a2-fordwatch_b2 | 95.3 m vs 85.5 m (10.3 %) | units walk millrace_a1-fordwatch_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a2 vs node_a_b1-mouth_lair_b2 | 130.5 m vs 117.3 m (10.2 %) | units walk node_a_a1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a2 vs node_a_a2-mouth_lair_a1 | 130.5 m vs 117.3 m (10.2 %) | units walk node_a_a1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-fordwatch_a1 vs millrace_b2-fordwatch_a2 | 94.9 m vs 85.4 m (10.0 %) | units walk millrace_b1-fordwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-fordwatch_b2 vs millrace_b1-fordwatch_a1 | 85.5 m vs 94.9 m (10.0 %) | units walk millrace_b1-fordwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-millrace_b1 vs node_a_b1-millrace_a1 | 106.9 m vs 118.5 m (9.8 %) | units walk node_a_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-millrace_a1 vs node_a_b2-millrace_a2 | 118.5 m vs 106.9 m (9.8 %) | units walk node_a_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-millrace_b2 vs node_a_b1-millrace_a1 | 107.0 m vs 118.5 m (9.7 %) | units walk node_a_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-bristleback_a1 vs keep_t4-bristleback_b1 | 74.8 m vs 82.9 m (9.7 %) | units walk keep_t4-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-bristleback_b2 vs keep_t4-bristleback_b1 | 74.8 m vs 82.9 m (9.7 %) | units walk keep_t4-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-wayshrine_a1 vs node_b_b2-wayshrine_a1 | 95.9 m vs 106.1 m (9.6 %) | units walk node_b_b2-wayshrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_b1-heron_ford_b2 vs bridge_nest_b2-heron_ford_b1 | 115.6 m vs 104.5 m (9.6 %) | units walk bridge_nest_b1-heron_ford_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-heron_ford_a2 vs bridge_nest_b1-heron_ford_b2 | 104.5 m vs 115.6 m (9.6 %) | units walk bridge_nest_b1-heron_ford_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-wayshrine_b1 vs node_b_b2-wayshrine_a1 | 95.9 m vs 106.1 m (9.6 %) | units walk node_b_b2-wayshrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-wayshrine_b1 vs node_b_b1-wayshrine_a1 | 106.1 m vs 95.9 m (9.6 %) | units walk node_b_a2-wayshrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-wayshrine_b1 vs node_b_a2-wayshrine_b1 | 95.9 m vs 106.1 m (9.6 %) | units walk node_b_a2-wayshrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a2-heron_ford_a1 vs bridge_nest_b2-heron_ford_b1 | 115.4 m vs 104.5 m (9.5 %) | units walk bridge_nest_a2-heron_ford_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-heron_ford_a2 vs bridge_nest_a2-heron_ford_a1 | 104.5 m vs 115.4 m (9.5 %) | units walk bridge_nest_a2-heron_ford_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-node_mid_b2 vs keep_t4-node_mid_a2 | 119.4 m vs 131.9 m (9.4 %) | units walk keep_t4-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-heath_lair_b2 vs heron_ford_b1-heath_lair_a1 | 152.1 m vs 167.9 m (9.4 %) | units walk heron_ford_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-node_mid_a1 vs keep_t4-node_mid_a2 | 119.5 m vs 131.9 m (9.4 %) | units walk keep_t4-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-millstone_cross_b1 vs millrace_a2-millstone_cross_b2 | 135.0 m vs 122.5 m (9.3 %) | units walk millrace_a1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-heath_lair_b1 vs heron_ford_a2-heath_lair_b2 | 167.6 m vs 152.1 m (9.3 %) | units walk heron_ford_a1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-millstone_cross_b1 vs millrace_b2-millstone_cross_a2 | 135.0 m vs 122.5 m (9.2 %) | units walk millrace_a1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-millstone_cross_b2 vs millrace_b1-millstone_cross_a1 | 122.5 m vs 134.7 m (9.1 %) | units walk millrace_b1-millstone_cross_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-millstone_cross_a1 vs millrace_b2-millstone_cross_a2 | 134.7 m vs 122.5 m (9.0 %) | units walk millrace_b1-millstone_cross_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-bristleback_a2 vs keep_t4-bristleback_b1 | 75.4 m vs 82.9 m (9.0 %) | units walk keep_t4-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-cache_b1 vs heron_ford_b1-cache_a2 | 147.7 m vs 134.5 m (8.9 %) | units walk heron_ford_a2-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_mid_b1 vs keep_t4-node_mid_a2 | 120.1 m vs 131.9 m (8.9 %) | units walk keep_t4-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-cache_b2 vs heron_ford_a2-cache_b1 | 134.6 m vs 147.7 m (8.9 %) | units walk heron_ford_a2-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-cache_b1 vs heron_ford_b2-cache_a1 | 147.7 m vs 134.6 m (8.9 %) | units walk heron_ford_a2-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-bristleback_b1 vs node_a_b2-bristleback_b2 | 35.5 m vs 32.3 m (8.8 %) | units walk node_a_b1-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-node_b_a1 vs keep_t4-node_b_a2 | 136.0 m vs 149.1 m (8.8 %) | units walk keep_t4-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-bristleback_a1 vs node_a_b1-bristleback_b1 | 32.4 m vs 35.5 m (8.6 %) | units walk node_a_b1-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-millstone_cross_a1 vs node_a_b2-millstone_cross_b1 | 106.7 m vs 116.7 m (8.6 %) | units walk node_a_b2-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-millstone_cross_a2 vs node_a_b2-millstone_cross_b1 | 106.7 m vs 116.7 m (8.6 %) | units walk node_a_b2-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-millstone_cross_b2 vs node_a_b2-millstone_cross_b1 | 106.7 m vs 116.7 m (8.6 %) | units walk node_a_b2-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-node_b_b2 vs keep_t1-node_b_a1 | 148.5 m vs 136.0 m (8.4 %) | units walk keep_t3-node_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_b1 vs keep_t4-node_b_a2 | 136.7 m vs 149.1 m (8.4 %) | units walk keep_t4-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-bristleback_a2 vs node_a_b2-bristleback_b2 | 35.2 m vs 32.3 m (8.2 %) | units walk node_a_a2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-millrace_b1 vs keep_t3-millrace_b2 | 117.0 m vs 107.4 m (8.2 %) | units walk keep_t0-millrace_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-bristleback_a1 vs node_a_b2-bristleback_b1 | 70.8 m vs 77.2 m (8.2 %) | units walk node_a_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-bristleback_b2 vs node_a_b2-bristleback_b1 | 70.8 m vs 77.2 m (8.2 %) | units walk node_a_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-greywater_lodge_b1 vs glade_vein_b1-greywater_lodge_a1 | 155.1 m vs 142.4 m (8.2 %) | units walk glade_vein_a1-greywater_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-greywater_lodge_b1 vs glade_vein_a2-greywater_lodge_b1 | 155.1 m vs 142.5 m (8.2 %) | units walk glade_vein_a1-greywater_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-greywater_lodge_b1 vs glade_vein_b2-greywater_lodge_a1 | 155.1 m vs 142.5 m (8.1 %) | units walk glade_vein_a1-greywater_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-bristleback_a1 vs node_a_a2-bristleback_a2 | 32.4 m vs 35.2 m (8.0 %) | units walk node_a_a2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-bristleback_a2 vs node_a_a2-bristleback_a1 | 77.0 m vs 70.8 m (8.0 %) | units walk node_a_a1-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-bristleback_a2 vs node_a_b1-bristleback_b2 | 77.0 m vs 70.8 m (8.0 %) | units walk node_a_a1-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_b1 vs keep_t3-node_b_b2 | 136.7 m vs 148.5 m (7.9 %) | units walk keep_t3-node_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fordwatch_a1-bridge_nest_b1 vs fordwatch_a2-bridge_nest_b2 | 113.4 m vs 104.4 m (7.9 %) | units walk fordwatch_a1-bridge_nest_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_b1-bridge_road_s vs heron_ford_b2-bridge_road_n | 114.2 m vs 123.9 m (7.8 %) | units walk heron_ford_b2-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-bridge_road_s vs heron_ford_b1-bridge_road_s | 123.8 m vs 114.2 m (7.7 %) | units walk heron_ford_a2-bridge_road_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fordwatch_a2-bridge_nest_b2 vs fordwatch_b2-bridge_nest_a2 | 104.4 m vs 113.2 m (7.7 %) | units walk fordwatch_b2-bridge_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a1-heath_lair_b1 vs cache_b1-heath_lair_a1 | 137.5 m vs 149.0 m (7.7 %) | units walk cache_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a2-heath_lair_b2 vs cache_b1-heath_lair_a1 | 137.5 m vs 149.0 m (7.7 %) | units walk cache_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-bridge_road_n vs heron_ford_b1-bridge_road_s | 123.7 m vs 114.2 m (7.7 %) | units walk heron_ford_a1-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b1-heath_lair_a1 vs cache_b2-heath_lair_a2 | 149.0 m vs 137.5 m (7.7 %) | units walk cache_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-millrace_b1 vs keep_t4-millrace_a2 | 117.0 m vs 108.0 m (7.7 %) | units walk keep_t0-millrace_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-millrace_b2 vs keep_t1-millrace_a1 | 107.4 m vs 116.3 m (7.7 %) | units walk keep_t1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fordwatch_a2-bridge_nest_b2 vs fordwatch_b1-bridge_nest_a1 | 104.4 m vs 113.0 m (7.6 %) | units walk fordwatch_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a2-tavern_b2 vs bristleback_b1-tavern_a1 | 107.1 m vs 99.0 m (7.5 %) | units walk bristleback_a2-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-tavern_b1 vs bristleback_a2-tavern_b2 | 99.1 m vs 107.1 m (7.5 %) | units walk bristleback_a2-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_b1-tavern_a1 vs bristleback_b2-tavern_a2 | 99.0 m vs 107.1 m (7.5 %) | units walk bristleback_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-tavern_b1 vs bristleback_b2-tavern_a2 | 99.1 m vs 107.1 m (7.5 %) | units walk bristleback_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-mid_cache_b1 vs glade_vein_b1-mid_cache_a1 | 142.1 m vs 131.8 m (7.3 %) | units walk glade_vein_a1-mid_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-mid_cache_b1 vs glade_vein_a2-mid_cache_b1 | 142.1 m vs 131.8 m (7.2 %) | units walk glade_vein_a1-mid_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-mid_cache_b1 vs glade_vein_b2-mid_cache_a1 | 142.1 m vs 131.8 m (7.2 %) | units walk glade_vein_a1-mid_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_b1-bristleback_b2 vs stag_glade_b2-bristleback_b1 | 120.0 m vs 129.4 m (7.2 %) | units walk stag_glade_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a1-bristleback_a2 vs stag_glade_b2-bristleback_b1 | 120.0 m vs 129.4 m (7.2 %) | units walk stag_glade_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a2-bristleback_a1 vs stag_glade_b2-bristleback_b1 | 120.0 m vs 129.4 m (7.2 %) | units walk stag_glade_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-millrace_a1 vs keep_t4-millrace_a2 | 116.3 m vs 108.0 m (7.1 %) | units walk keep_t1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b2 vs keep_t1-peddler_a1 | 123.5 m vs 132.9 m (7.1 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-millstone_cross_b2 vs heron_ford_b2-millstone_cross_a2 | 137.4 m vs 147.8 m (7.0 %) | units walk heron_ford_b2-millstone_cross_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_mid_b2 vs node_a_b2-node_mid_a2 | 121.7 m vs 130.8 m (7.0 %) | units walk node_a_b2-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_mid_b1 vs node_a_b2-node_mid_a2 | 121.7 m vs 130.8 m (6.9 %) | units walk node_a_b2-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-node_mid_a1 vs node_a_b2-node_mid_a2 | 121.7 m vs 130.8 m (6.9 %) | units walk node_a_b2-node_mid_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-millstone_cross_b1 vs heron_ford_a2-millstone_cross_b2 | 147.7 m vs 137.4 m (6.9 %) | units walk heron_ford_a1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-bristleback_b2 vs glade_vein_b2-bristleback_b1 | 112.4 m vs 120.7 m (6.9 %) | units walk glade_vein_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-bristleback_a2 vs glade_vein_b2-bristleback_b1 | 112.4 m vs 120.7 m (6.9 %) | units walk glade_vein_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-bristleback_a1 vs glade_vein_b2-bristleback_b1 | 112.4 m vs 120.7 m (6.9 %) | units walk glade_vein_b2-bristleback_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a1-heron_ford_b2 vs stag_glade_a2-heron_ford_b1 | 153.1 m vs 164.3 m (6.8 %) | units walk stag_glade_a2-heron_ford_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a1-heron_ford_b2 vs stag_glade_b2-heron_ford_a1 | 153.1 m vs 164.3 m (6.8 %) | units walk stag_glade_b2-heron_ford_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a2-heron_ford_b1 vs stag_glade_b1-heron_ford_a2 | 164.3 m vs 153.1 m (6.8 %) | units walk stag_glade_a2-heron_ford_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_b1-heron_ford_a2 vs stag_glade_b2-heron_ford_a1 | 153.1 m vs 164.3 m (6.8 %) | units walk stag_glade_b2-heron_ford_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_b2 vs node_a_b1-node_b_a1 | 148.1 m vs 138.3 m (6.6 %) | units walk node_a_a2-node_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_b1 vs node_a_a2-node_b_b2 | 138.3 m vs 148.1 m (6.6 %) | units walk node_a_a2-node_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-node_b_a1 vs node_a_b2-node_b_a2 | 138.3 m vs 148.0 m (6.6 %) | units walk node_a_b2-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_b1 vs node_a_b2-node_b_a2 | 138.3 m vs 148.0 m (6.6 %) | units walk node_a_b2-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t1-peddler_a1 | 124.2 m vs 132.9 m (6.6 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_b1-millstone_cross_a1 vs heron_ford_b2-millstone_cross_a2 | 138.2 m vs 147.8 m (6.5 %) | units walk heron_ford_b2-millstone_cross_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-peddler_a1 vs keep_t4-peddler_a2 | 132.9 m vs 124.2 m (6.5 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-millstone_cross_b1 vs heron_ford_b1-millstone_cross_a1 | 147.7 m vs 138.2 m (6.4 %) | units walk heron_ford_a1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-gloomcap_b1 vs node_mid_b2-gloomcap_a1 | 89.3 m vs 95.4 m (6.4 %) | units walk node_mid_b2-gloomcap_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-heath_lair_b1 vs tavern_b1-heath_lair_a1 | 113.1 m vs 120.8 m (6.4 %) | units walk tavern_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a2-heath_lair_b2 vs tavern_b1-heath_lair_a1 | 113.1 m vs 120.8 m (6.3 %) | units walk tavern_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-gloomcap_a1 vs node_mid_b2-gloomcap_a1 | 89.3 m vs 95.4 m (6.3 %) | units walk node_mid_b2-gloomcap_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-gloomcap_b1 vs node_mid_b2-gloomcap_a1 | 89.4 m vs 95.4 m (6.3 %) | units walk node_mid_b2-gloomcap_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_b1-heath_lair_a1 vs tavern_b2-heath_lair_a2 | 120.8 m vs 113.2 m (6.3 %) | units walk tavern_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-heath_lair_b1 vs node_b_b1-heath_lair_a1 | 150.5 m vs 160.6 m (6.3 %) | units walk node_b_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-heath_lair_b2 vs node_b_b1-heath_lair_a1 | 150.5 m vs 160.6 m (6.3 %) | units walk node_b_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-heath_lair_a1 vs node_b_b2-heath_lair_a2 | 160.6 m vs 150.5 m (6.3 %) | units walk node_b_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | magpie_den_b1-bridge_road_s vs magpie_den_b1-bridge_road_n | 106.9 m vs 114.0 m (6.2 %) | units walk magpie_den_b1-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | magpie_den_a1-bridge_road_s vs magpie_den_b1-bridge_road_s | 113.9 m vs 106.9 m (6.1 %) | units walk magpie_den_a1-bridge_road_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | magpie_den_a1-bridge_road_n vs magpie_den_b1-bridge_road_s | 113.8 m vs 106.9 m (6.1 %) | units walk magpie_den_a1-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-gloomcap_a1 vs node_b_b2-gloomcap_a1 | 105.9 m vs 112.6 m (6.0 %) | units walk node_b_b2-gloomcap_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-gloomcap_b1 vs node_b_b2-gloomcap_a1 | 105.9 m vs 112.6 m (5.9 %) | units walk node_b_b2-gloomcap_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-gloomcap_b1 vs node_b_b1-gloomcap_a1 | 112.5 m vs 105.9 m (5.9 %) | units walk node_b_a2-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-gloomcap_b1 vs glade_vein_b1-gloomcap_a1 | 132.1 m vs 124.3 m (5.9 %) | units walk glade_vein_a1-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-gloomcap_b1 vs node_b_a2-gloomcap_b1 | 105.9 m vs 112.5 m (5.9 %) | units walk node_b_a2-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-steps_e vs glade_vein_b1-steps_w | 111.5 m vs 104.9 m (5.9 %) | units walk glade_vein_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-steps_e vs glade_vein_a2-steps_e | 104.9 m vs 111.5 m (5.9 %) | units walk glade_vein_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-gloomcap_b1 vs glade_vein_b2-gloomcap_a1 | 132.1 m vs 124.4 m (5.9 %) | units walk glade_vein_a1-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-gloomcap_b1 vs glade_vein_a2-gloomcap_b1 | 132.1 m vs 124.4 m (5.9 %) | units walk glade_vein_a1-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-steps_w vs glade_vein_b2-steps_w | 104.9 m vs 111.3 m (5.8 %) | units walk glade_vein_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mossmere_a1-heath_lair_b1 vs mossmere_b1-heath_lair_a1 | 123.4 m vs 130.9 m (5.7 %) | units walk mossmere_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-steps_e vs glade_vein_b2-steps_w | 104.9 m vs 111.3 m (5.7 %) | units walk glade_vein_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mossmere_a2-heath_lair_b2 vs mossmere_b1-heath_lair_a1 | 123.4 m vs 130.9 m (5.7 %) | units walk mossmere_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mossmere_b1-heath_lair_a1 vs mossmere_b2-heath_lair_a2 | 130.9 m vs 123.5 m (5.7 %) | units walk mossmere_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-mouth_lair_b1 vs node_a_b2-mouth_lair_b2 | 89.0 m vs 84.2 m (5.5 %) | units walk node_a_b1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a1 vs node_a_b1-mouth_lair_b1 | 84.2 m vs 89.0 m (5.5 %) | units walk node_a_b1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_a2 vs node_a_b2-mouth_lair_b2 | 88.8 m vs 84.2 m (5.2 %) | units walk node_a_a2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a1 vs node_a_a2-mouth_lair_a2 | 84.2 m vs 88.8 m (5.2 %) | units walk node_a_a2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-millstone_cross_b1 vs node_a_b2-millstone_cross_b2 | 75.0 m vs 71.2 m (5.1 %) | units walk node_a_b1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-glade_vein_a2 vs node_a_b2-glade_vein_b2 | 43.5 m vs 45.8 m (5.1 %) | units walk node_a_b2-glade_vein_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-glade_vein_a1 vs node_a_b2-glade_vein_b2 | 43.5 m vs 45.8 m (5.1 %) | units walk node_a_b2-glade_vein_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-millstone_cross_a1 vs node_a_b1-millstone_cross_b1 | 71.2 m vs 75.0 m (5.0 %) | units walk node_a_b1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-66.0, 30.0) | (-65.1, 26.4) | keep_t4 | (-65.1, 26.4) | 0.0 |
| keep_t3 | keep | (-66.0, -30.0) | (-64.6, -25.9) | keep_t1 | (-64.6, -25.9) | 0.0 |
| keep_t1 | keep | (66.0, -30.0) | (64.6, -25.9) | keep_t3 | (64.6, -25.9) | 0.0 |
| keep_t4 | keep | (66.0, 30.0) | (65.1, 26.4) | keep_t0 | (65.1, 26.4) | 0.0 |
| node_a_a1 | home_node | (-69.0, 21.0) | (-68.9, 20.9) | node_a_b2 | (-68.9, 20.9) | 0.0 |
| node_a_a2 | home_node | (-69.0, -21.0) | (-68.9, -20.9) | node_a_b1 | (-68.9, -20.9) | 0.0 |
| node_a_b1 | home_node | (69.0, -21.0) | (68.9, -20.9) | node_a_a2 | (68.9, -20.9) | 0.0 |
| node_a_b2 | home_node | (69.0, 21.0) | (68.9, 20.9) | node_a_a1 | (68.9, 20.9) | 0.0 |
| node_b_a1 | home_node | (-57.0, 33.0) | (-56.9, 32.9) | node_b_b2 | (-56.9, 32.9) | 0.0 |
| node_b_a2 | home_node | (-57.0, -33.0) | (-56.9, -32.9) | node_b_b1 | (-56.9, -32.9) | 0.0 |
| node_b_b1 | home_node | (57.0, -33.0) | (56.9, -32.9) | node_b_a2 | (56.9, -32.9) | 0.0 |
| node_b_b2 | home_node | (57.0, 33.0) | (56.9, 32.9) | node_b_a1 | (56.9, 32.9) | 0.0 |
| node_mid_a1 | expansion | (-39.0, 29.0) | (-38.9, 28.9) | node_mid_b2 | (-38.9, 28.9) | 0.0 |
| node_mid_a2 | expansion | (-39.0, -29.0) | (-38.9, -28.9) | node_mid_b1 | (-38.9, -28.9) | 0.0 |
| node_mid_b1 | expansion | (39.0, -29.0) | (38.9, -28.9) | node_mid_a2 | (38.9, -28.9) | 0.0 |
| node_mid_b2 | expansion | (39.0, 29.0) | (38.9, 28.9) | node_mid_a1 | (38.9, 28.9) | 0.0 |
| glade_vein_a1 | expansion | (-64.0, 64.0) | (-63.9, 63.9) | glade_vein_b2 | (-63.9, 63.9) | 0.0 |
| glade_vein_a2 | expansion | (-64.0, -64.0) | (-63.9, -63.9) | glade_vein_b1 | (-63.9, -63.9) | 0.0 |
| glade_vein_b1 | expansion | (64.0, -64.0) | (63.9, -63.9) | glade_vein_a2 | (63.9, -63.9) | 0.0 |
| glade_vein_b2 | expansion | (64.0, 64.0) | (63.9, 63.9) | glade_vein_a1 | (63.9, 63.9) | 0.0 |
| rich_a1 | expansion | (-14.0, 62.0) | (-13.9, 61.9) | rich_b2 | (-13.9, 61.9) | 0.0 |
| rich_a2 | expansion | (-14.0, -62.0) | (-13.9, -61.9) | rich_b1 | (-13.9, -61.9) | 0.0 |
| rich_b1 | expansion | (14.0, -62.0) | (13.9, -61.9) | rich_a2 | (13.9, -61.9) | 0.0 |
| rich_b2 | expansion | (14.0, 62.0) | (13.9, 61.9) | rich_a1 | (13.9, 61.9) | 0.0 |
| millrace_a1 | expansion | (-16.0, 36.0) | (-15.9, 35.9) | millrace_b2 | (-15.9, 35.9) | 0.0 |
| millrace_a2 | expansion | (-16.0, -36.0) | (-15.9, -35.9) | millrace_b1 | (-15.9, -35.9) | 0.0 |
| millrace_b1 | expansion | (16.0, -36.0) | (15.9, -35.9) | millrace_a2 | (15.9, -35.9) | 0.0 |
| millrace_b2 | expansion | (16.0, 36.0) | (15.9, 35.9) | millrace_a1 | (15.9, 35.9) | 0.0 |
| millwatch_a1 | point | (-8.0, 52.0) | (-7.9, 51.9) | millwatch_b2 | (-7.9, 51.9) | 0.0 |
| millwatch_a2 | point | (-8.0, -52.0) | (-7.9, -51.9) | millwatch_b1 | (-7.9, -51.9) | 0.0 |
| millwatch_b1 | point | (8.0, -52.0) | (7.9, -51.9) | millwatch_a2 | (7.9, -51.9) | 0.0 |
| millwatch_b2 | point | (8.0, 52.0) | (7.9, 51.9) | millwatch_a1 | (7.9, 51.9) | 0.0 |
| mossmere_a1 | point | (-32.0, 17.0) | (-31.9, 16.9) | mossmere_b2 | (-31.9, 16.9) | 0.0 |
| mossmere_a2 | point | (-32.0, -17.0) | (-31.9, -16.9) | mossmere_b1 | (-31.9, -16.9) | 0.0 |
| mossmere_b1 | point | (32.0, -17.0) | (31.9, -16.9) | mossmere_a2 | (31.9, -16.9) | 0.0 |
| mossmere_b2 | point | (32.0, 17.0) | (31.9, 16.9) | mossmere_a1 | (31.9, 16.9) | 0.0 |
| fordwatch_a1 | point | (-7.0, 36.0) | (-6.9, 35.9) | fordwatch_b2 | (-6.9, 35.9) | 0.0 |
| fordwatch_a2 | point | (-7.0, -36.0) | (-6.9, -35.9) | fordwatch_b1 | (-6.9, -35.9) | 0.0 |
| fordwatch_b1 | point | (7.0, -36.0) | (6.9, -35.9) | fordwatch_a2 | (6.9, -35.9) | 0.0 |
| fordwatch_b2 | point | (7.0, 36.0) | (6.9, 35.9) | fordwatch_a1 | (6.9, 35.9) | 0.0 |
| wayshrine_a1 | point | (-30.0, 0.0) | (-29.9, 0.1) | wayshrine_b1 | (-29.9, 0.1) | 0.0 |
| wayshrine_b1 | point | (30.0, 0.0) | (29.9, 0.1) | wayshrine_a1 | (29.9, 0.1) | 0.0 |
| stag_glade_a1 | camp | (-60.0, 72.0) | (-59.9, 71.9) | stag_glade_b2 | (-59.9, 71.9) | 0.0 |
| stag_glade_a2 | camp | (-60.0, -72.0) | (-59.9, -71.9) | stag_glade_b1 | (-59.9, -71.9) | 0.0 |
| stag_glade_b1 | camp | (60.0, -72.0) | (59.9, -71.9) | stag_glade_a2 | (59.9, -71.9) | 0.0 |
| stag_glade_b2 | camp | (60.0, 72.0) | (59.9, 71.9) | stag_glade_a1 | (59.9, 71.9) | 0.0 |
| bristleback_a1 | camp | (-52.0, 48.0) | (-51.9, 47.9) | bristleback_b2 | (-51.9, 47.9) | 0.0 |
| bristleback_a2 | camp | (-52.0, -48.0) | (-51.9, -47.9) | bristleback_b1 | (-51.9, -47.9) | 0.0 |
| bristleback_b1 | camp | (52.0, -48.0) | (51.9, -47.9) | bristleback_a2 | (51.9, -47.9) | 0.0 |
| bristleback_b2 | camp | (52.0, 48.0) | (51.9, 47.9) | bristleback_a1 | (51.9, 47.9) | 0.0 |
| bridge_nest_a1 | camp | (-5.0, 63.0) | (-4.9, 62.9) | bridge_nest_b2 | (-4.9, 62.9) | 0.0 |
| bridge_nest_a2 | camp | (-5.0, -63.0) | (-4.9, -62.9) | bridge_nest_b1 | (-4.9, -62.9) | 0.0 |
| bridge_nest_b1 | camp | (5.0, -63.0) | (4.9, -62.9) | bridge_nest_a2 | (4.9, -62.9) | 0.0 |
| bridge_nest_b2 | camp | (5.0, 63.0) | (4.9, 62.9) | bridge_nest_a1 | (4.9, 62.9) | 0.0 |
| gloomcap_a1 | camp | (-40.0, 0.0) | (-39.9, 0.1) | gloomcap_b1 | (-39.9, 0.1) | 0.0 |
| gloomcap_b1 | camp | (40.0, 0.0) | (39.9, 0.1) | gloomcap_a1 | (39.9, 0.1) | 0.0 |
| ford_nest_a1 | camp | (0.0, 40.0) | (-0.1, 39.9) | ford_nest_a1 | (0.1, 39.9) | 0.3 |
| ford_nest_a2 | camp | (0.0, -40.0) | (-0.1, -39.9) | ford_nest_a2 | (0.1, -39.9) | 0.3 |
| tavern_a1 | tavern | (-25.0, 9.0) | (-24.9, 8.9) | tavern_b2 | (-24.9, 8.9) | 0.0 |
| tavern_a2 | tavern | (-25.0, -9.0) | (-24.9, -8.9) | tavern_b1 | (-24.9, -8.9) | 0.0 |
| tavern_b1 | tavern | (25.0, -9.0) | (24.9, -8.9) | tavern_a2 | (24.9, -8.9) | 0.0 |
| tavern_b2 | tavern | (25.0, 9.0) | (24.9, 8.9) | tavern_a1 | (24.9, 8.9) | 0.0 |
| heron_ford_a1 | post | (-80.0, 10.0) | (-79.9, 9.9) | heron_ford_b2 | (-79.9, 9.9) | 0.0 |
| heron_ford_a2 | post | (-80.0, -10.0) | (-79.9, -9.9) | heron_ford_b1 | (-79.9, -9.9) | 0.0 |
| heron_ford_b1 | post | (80.0, -10.0) | (79.9, -9.9) | heron_ford_a2 | (79.9, -9.9) | 0.0 |
| heron_ford_b2 | post | (80.0, 10.0) | (79.9, 9.9) | heron_ford_a1 | (79.9, 9.9) | 0.0 |
| millstone_cross_a1 | post | (-24.0, 76.0) | (-23.9, 75.9) | millstone_cross_b2 | (-23.9, 75.9) | 0.0 |
| millstone_cross_a2 | post | (-24.0, -76.0) | (-23.9, -75.9) | millstone_cross_b1 | (-23.9, -75.9) | 0.0 |
| millstone_cross_b1 | post | (24.0, -76.0) | (23.9, -75.9) | millstone_cross_a2 | (23.9, -75.9) | 0.0 |
| millstone_cross_b2 | post | (24.0, 76.0) | (23.9, 75.9) | millstone_cross_a1 | (23.9, 75.9) | 0.0 |
| magpie_den_a1 | guild | (-79.0, 0.0) | (-78.9, 0.1) | magpie_den_b1 | (-78.9, 0.1) | 0.0 |
| magpie_den_b1 | guild | (79.0, 0.0) | (78.9, 0.1) | magpie_den_a1 | (78.9, 0.1) | 0.0 |
| greywater_lodge_a1 | guild | (-63.0, 0.0) | (-62.9, 0.1) | greywater_lodge_b1 | (-62.9, 0.1) | 0.0 |
| greywater_lodge_b1 | guild | (63.0, 0.0) | (62.9, 0.1) | greywater_lodge_a1 | (62.9, 0.1) | 0.0 |
| peddler_a1 | peddler | (-30.0, 50.0) | (-29.9, 49.9) | peddler_b2 | (-29.9, 49.9) | 0.0 |
| peddler_a2 | peddler | (-30.0, -50.0) | (-29.9, -49.9) | peddler_b1 | (-29.9, -49.9) | 0.0 |
| peddler_b1 | peddler | (30.0, -50.0) | (29.9, -49.9) | peddler_a2 | (29.9, -49.9) | 0.0 |
| peddler_b2 | peddler | (30.0, 50.0) | (29.9, 49.9) | peddler_a1 | (29.9, 49.9) | 0.0 |
| cache_a1 | cache | (-50.0, 22.0) | (-49.9, 21.9) | cache_b2 | (-49.9, 21.9) | 0.0 |
| cache_a2 | cache | (-50.0, -22.0) | (-49.9, -21.9) | cache_b1 | (-49.9, -21.9) | 0.0 |
| cache_b1 | cache | (50.0, -22.0) | (49.9, -21.9) | cache_a2 | (49.9, -21.9) | 0.0 |
| cache_b2 | cache | (50.0, 22.0) | (49.9, 21.9) | cache_a1 | (49.9, 21.9) | 0.0 |
| mid_cache_a1 | cache | (-50.0, 0.0) | (-49.9, 0.1) | mid_cache_b1 | (-49.9, 0.1) | 0.0 |
| mid_cache_b1 | cache | (50.0, 0.0) | (49.9, 0.1) | mid_cache_a1 | (49.9, 0.1) | 0.0 |
| heath_lair_a1 | lair | (-44.0, 78.0) | (-43.9, 77.9) | heath_lair_b2 | (-43.9, 77.9) | 0.0 |
| heath_lair_a2 | lair | (-44.0, -78.0) | (-43.9, -77.9) | heath_lair_b1 | (-43.9, -77.9) | 0.0 |
| heath_lair_b1 | lair | (44.0, -78.0) | (43.9, -77.9) | heath_lair_a2 | (43.9, -77.9) | 0.0 |
| heath_lair_b2 | lair | (44.0, 78.0) | (43.9, 77.9) | heath_lair_a1 | (43.9, 77.9) | 0.0 |
| mouth_lair_a1 | lair | (-9.0, 80.0) | (-8.9, 79.9) | mouth_lair_b2 | (-8.9, 79.9) | 0.0 |
| mouth_lair_a2 | lair | (-9.0, -80.0) | (-8.9, -79.9) | mouth_lair_b1 | (-8.9, -79.9) | 0.0 |
| mouth_lair_b1 | lair | (9.0, -80.0) | (8.9, -79.9) | mouth_lair_a2 | (8.9, -79.9) | 0.0 |
| mouth_lair_b2 | lair | (9.0, 80.0) | (8.9, 79.9) | mouth_lair_a1 | (8.9, 79.9) | 0.0 |
| bridge_road_s | crossing_bridge_road | (0.0, 72.0) | (-0.1, 71.9) | bridge_road_s | (0.1, 71.9) | 0.3 |
| bridge_road_n | crossing_bridge_road | (0.0, -72.0) | (-0.1, -71.9) | bridge_road_n | (0.1, -71.9) | 0.3 |
| ford_s | crossing_ford | (0.0, 40.0) | (-0.1, 39.9) | ford_s | (0.1, 39.9) | 0.3 |
| ford_n | crossing_ford | (0.0, -40.0) | (-0.1, -39.9) | ford_n | (0.1, -39.9) | 0.3 |
| steps_w | crossing_steps | (-12.8, 0.0) | (-12.6, 0.1) | steps_e | (-12.6, 0.1) | 0.0 |
| steps_e | crossing_steps | (12.8, 0.0) | (12.6, 0.1) | steps_w | (12.6, 0.1) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 336)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | node_a_a1 - bristleback_b1 | 143.8 | node_a_b2 - bristleback_a2 | 176.7 | -18.6 % |
| 2 | keep_t3 - node_b_a1 | 59.3 | keep_t4 - node_b_b1 | 72.8 | -18.6 % |
| 3 | keep_t1 - node_b_b2 | 59.3 | keep_t4 - node_b_b1 | 72.8 | -18.6 % |
| 4 | node_a_a2 - bristleback_b2 | 143.8 | node_a_b2 - bristleback_a2 | 176.7 | -18.6 % |
| 5 | node_a_b1 - bristleback_a1 | 143.9 | node_a_b2 - bristleback_a2 | 176.7 | -18.5 % |
| 6 | node_a_a2 - node_b_a1 | 55.1 | node_a_b2 - node_b_b1 | 67.1 | -17.9 % |
| 7 | node_a_b1 - node_b_b2 | 55.1 | node_a_b2 - node_b_b1 | 67.1 | -17.9 % |
| 8 | keep_t0 - node_b_a2 | 59.8 | keep_t4 - node_b_b1 | 72.8 | -17.8 % |
| 9 | node_a_a1 - node_b_a2 | 66.9 | node_a_a2 - node_b_a1 | 55.1 | +17.6 % |
| 10 | node_a_a1 - node_b_a2 | 66.9 | node_a_b1 - node_b_b2 | 55.1 | +17.6 % |
| 11 | node_mid_a2 - mossmere_b2 | 86.3 | node_mid_b2 - mossmere_a2 | 104.4 | -17.4 % |
| 12 | node_mid_b1 - mossmere_a1 | 86.4 | node_mid_b2 - mossmere_a2 | 104.4 | -17.3 % |
| 13 | node_mid_a1 - mossmere_b1 | 86.4 | node_mid_b2 - mossmere_a2 | 104.4 | -17.3 % |
| 14 | node_b_a1 - tavern_b1 | 92.8 | node_b_b2 - tavern_a2 | 111.3 | -16.7 % |
| 15 | node_b_b1 - tavern_a1 | 92.8 | node_b_b2 - tavern_a2 | 111.3 | -16.7 % |
| 16 | node_b_a1 - tavern_b1 | 92.8 | node_b_a2 - tavern_b2 | 111.3 | -16.7 % |
| 17 | node_b_a2 - tavern_b2 | 111.3 | node_b_b1 - tavern_a1 | 92.8 | +16.7 % |
| 18 | millwatch_a1 - bridge_nest_b2 | 37.0 | millwatch_b1 - bridge_nest_a2 | 31.0 | +16.3 % |
| 19 | millwatch_a1 - bridge_nest_b2 | 37.0 | millwatch_a2 - bridge_nest_b1 | 31.0 | +16.3 % |
| 20 | millwatch_a1 - bristleback_b2 | 65.7 | millwatch_b2 - bristleback_a1 | 77.9 | -15.7 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| player (A1 south-west) | 26.4 (node_mid_a1) | 34.6 (mossmere_a1) | 26.5 (bristleback_a1) | 57.3 (heath_lair_a1) | 43.9 (tavern_a1) | 22.1 (heron_ford_a1) | 42.8 (peddler_a1) | 15.9 (cache_a1) | 70.2 (crown) | 140.1 |
| ally (A2 north-west) | 25.9 (node_mid_a2) | 34.0 (mossmere_a2) | 26.1 (bristleback_a2) | 56.9 (heath_lair_a2) | 43.2 (tavern_a2) | 22.1 (heron_ford_a2) | 42.4 (peddler_a2) | 15.3 (cache_a2) | 69.6 (crown) | 138.7 |
| enemy (B1 north-east) | 25.9 (node_mid_b1) | 34.0 (mossmere_b1) | 26.1 (bristleback_b1) | 56.8 (heath_lair_b1) | 43.2 (tavern_b1) | 22.1 (heron_ford_b1) | 42.3 (peddler_b1) | 15.3 (cache_b1) | 69.6 (crown) | 138.7 |
| enemy 2 (B2 south-east) | 26.4 (node_mid_b2) | 34.6 (mossmere_b2) | 26.4 (bristleback_b2) | 57.1 (heath_lair_b2) | 43.9 (tavern_b2) | 22.1 (heron_ford_b2) | 42.7 (peddler_b2) | 15.9 (cache_b2) | 70.2 (crown) | 140.1 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| node_a_a1 | home_node | 6.7 | node_a_b2 | 6.7 | +0.0 % |
| node_b_a1 | home_node | 11.1 | node_b_b2 | 11.0 | +0.8 % |
| cache_a1 | cache | 15.9 | cache_b2 | 15.9 | +0.0 % |
| heron_ford_a1 | post | 22.1 | heron_ford_b2 | 22.1 | +0.0 % |
| greywater_lodge_a1 | guild | 26.3 | greywater_lodge_b1 | 26.3 | +0.0 % |
| node_mid_a1 | expansion | 26.4 | node_mid_b2 | 26.4 | +0.0 % |
| bristleback_a1 | camp | 26.5 | bristleback_b2 | 26.4 | +0.5 % |
| magpie_den_a1 | guild | 29.6 | magpie_den_b1 | 29.6 | +0.0 % |
| mid_cache_a1 | cache | 30.4 | mid_cache_b1 | 30.4 | +0.0 % |
| mossmere_a1 | point | 34.6 | mossmere_b2 | 34.6 | +0.0 % |
| gloomcap_a1 | camp | 36.4 | gloomcap_b1 | 36.4 | +0.0 % |
| heron_ford_a2 | post | 39.1 | heron_ford_b1 | 39.1 | +0.0 % |
| glade_vein_a1 | expansion | 40.2 | glade_vein_b2 | 39.9 | +0.7 % |
| peddler_a1 | peddler | 42.8 | peddler_b2 | 42.7 | +0.1 % |
| tavern_a1 | tavern | 43.9 | tavern_b2 | 43.9 | +0.0 % |
| wayshrine_a1 | point | 44.0 | wayshrine_b1 | 44.0 | +0.0 % |
| node_a_a2 | home_node | 47.4 | node_a_b1 | 47.4 | +0.0 % |
| stag_glade_a1 | camp | 48.2 | stag_glade_b2 | 47.9 | +0.5 % |
| millrace_a1 | expansion | 50.2 | millrace_b2 | 50.2 | +0.0 % |
| cache_a2 | cache | 50.6 | cache_b1 | 50.6 | +0.0 % |
| keep_t3 | keep | 52.3 | keep_t1 | 52.3 | +0.0 % |
| tavern_a2 | tavern | 53.5 | tavern_b1 | 53.5 | +0.0 % |
| mossmere_a2 | point | 54.6 | mossmere_b1 | 54.6 | +0.0 % |
| heath_lair_a1 | lair | 57.3 | heath_lair_b2 | 57.1 | +0.3 % |
| steps_w | crossing_steps | 58.7 | steps_e | 58.7 | +0.0 % |
| fordwatch_a1 | point | 59.0 | fordwatch_b2 | 59.0 | +0.0 % |
| node_b_a2 | home_node | 59.8 | node_b_b1 | 72.8 | -17.8 % |
| node_mid_a2 | expansion | 61.2 | node_mid_b1 | 61.2 | +0.0 % |
| rich_a1 | expansion | 62.7 | rich_b2 | 62.7 | +0.1 % |
| millwatch_a1 | point | 62.9 | millwatch_b2 | 62.8 | +0.0 % |
| millstone_cross_a1 | post | 65.3 | millstone_cross_b2 | 65.2 | +0.1 % |
| ford_nest_a1 | camp | 66.4 | ford_nest_a1 | 66.4 | +0.0 % |
| ford_s | crossing_ford | 66.4 | ford_s | 66.4 | +0.0 % |
| crown | crown | 70.2 | crown | 70.2 | +0.0 % |
| bridge_nest_a1 | camp | 70.8 | bridge_nest_b2 | 70.7 | +0.1 % |
| fordwatch_b2 | point | 73.4 | fordwatch_a1 | 73.3 | +0.0 % |
| bristleback_a2 | camp | 75.4 | bristleback_b1 | 82.9 | -9.0 % |
| mouth_lair_a1 | lair | 78.3 | mouth_lair_b2 | 78.2 | +0.1 % |
| millrace_a2 | expansion | 79.4 | millrace_b1 | 79.4 | -0.0 % |
| bridge_road_s | crossing_bridge_road | 79.7 | bridge_road_s | 79.7 | +0.1 % |
| millwatch_b2 | point | 80.7 | millwatch_a1 | 80.5 | +0.2 % |
| millrace_b2 | expansion | 82.1 | millrace_a1 | 82.1 | +0.0 % |
| steps_e | crossing_steps | 82.8 | steps_w | 82.8 | +0.0 % |
| peddler_a2 | peddler | 84.0 | peddler_b1 | 84.0 | +0.0 % |
| fordwatch_a2 | point | 85.3 | fordwatch_b1 | 85.3 | +0.0 % |
| bridge_nest_b2 | camp | 89.0 | bridge_nest_a1 | 88.9 | +0.2 % |
| glade_vein_a2 | expansion | 90.9 | glade_vein_b1 | 91.0 | -0.1 % |
| mouth_lair_b2 | lair | 91.8 | mouth_lair_a1 | 91.7 | +0.1 % |
| rich_b2 | expansion | 92.3 | rich_a1 | 95.3 | -3.1 % |
| ford_nest_a2 | camp | 92.8 | ford_nest_a2 | 92.8 | -0.0 % |
| ford_n | crossing_ford | 92.8 | ford_n | 92.8 | -0.0 % |
| tavern_b2 | tavern | 96.2 | tavern_a1 | 96.2 | -0.0 % |
| tavern_b1 | tavern | 96.9 | tavern_a2 | 96.9 | +0.0 % |
| millwatch_a2 | point | 97.0 | millwatch_b1 | 97.0 | +0.0 % |
| peddler_b2 | peddler | 97.9 | peddler_a1 | 97.9 | +0.0 % |
| fordwatch_b1 | point | 99.1 | fordwatch_a2 | 99.2 | -0.1 % |
| stag_glade_a2 | camp | 99.6 | stag_glade_b1 | 99.7 | -0.1 % |
| wayshrine_b1 | point | 100.0 | wayshrine_a1 | 100.0 | +0.0 % |
| rich_a2 | expansion | 102.1 | rich_b1 | 102.1 | +0.0 % |
| millstone_cross_b2 | post | 103.6 | millstone_cross_a1 | 103.6 | +0.0 % |
| node_mid_b2 | expansion | 106.0 | node_mid_a1 | 106.0 | +0.0 % |
| mossmere_b2 | point | 106.3 | mossmere_a1 | 104.6 | +1.6 % |
| heath_lair_a2 | lair | 106.4 | heath_lair_b1 | 106.4 | +0.0 % |
| mossmere_b1 | point | 107.0 | mossmere_a2 | 106.9 | +0.1 % |
| millwatch_b1 | point | 107.5 | millwatch_a2 | 107.5 | +0.1 % |
| bridge_nest_a2 | camp | 107.7 | bridge_nest_b1 | 107.7 | +0.0 % |
| gloomcap_b1 | camp | 110.0 | gloomcap_a1 | 110.0 | +0.0 % |
| millstone_cross_a2 | post | 110.3 | millstone_cross_b1 | 110.3 | +0.0 % |
| millrace_b1 | expansion | 117.0 | millrace_a2 | 108.0 | +7.7 % |
| bridge_nest_b1 | camp | 117.5 | bridge_nest_a2 | 117.3 | +0.1 % |
| bridge_road_n | crossing_bridge_road | 117.9 | bridge_road_n | 118.0 | -0.0 % |
| cache_b2 | cache | 118.6 | cache_a1 | 118.5 | +0.0 % |
| rich_b1 | expansion | 119.2 | rich_a2 | 119.1 | +0.0 % |
| mid_cache_b1 | cache | 120.0 | mid_cache_a1 | 120.0 | +0.0 % |
| node_mid_b1 | expansion | 120.1 | node_mid_a2 | 131.9 | -8.9 % |
| node_b_b2 | home_node | 123.2 | node_b_a1 | 123.2 | -0.0 % |
| heath_lair_b2 | lair | 123.6 | heath_lair_a1 | 123.6 | +0.0 % |
| peddler_b1 | peddler | 124.2 | peddler_a2 | 124.2 | -0.0 % |
| cache_b1 | cache | 125.0 | cache_a2 | 125.0 | +0.0 % |
| mouth_lair_b1 | lair | 130.0 | mouth_lair_a2 | 130.0 | -0.0 % |
| greywater_lodge_b1 | guild | 133.0 | greywater_lodge_a1 | 133.0 | +0.0 % |
| bristleback_b2 | camp | 135.5 | bristleback_a1 | 135.4 | +0.0 % |
| mouth_lair_a2 | lair | 136.2 | mouth_lair_b1 | 136.4 | -0.2 % |
| node_b_b1 | home_node | 136.7 | node_b_a2 | 149.1 | -8.4 % |
| stag_glade_b2 | camp | 138.9 | stag_glade_a1 | 138.9 | +0.0 % |
| keep_t4 | keep | 140.1 | keep_t0 | 140.1 | +0.0 % |
| keep_t1 | keep | 140.1 | keep_t3 | 140.1 | +0.0 % |
| node_a_b2 | home_node | 141.7 | node_a_a1 | 141.7 | +0.0 % |
| millstone_cross_b1 | post | 141.7 | millstone_cross_a2 | 136.3 | +3.9 % |
| node_a_b1 | home_node | 142.4 | node_a_a2 | 142.4 | +0.0 % |
| glade_vein_b2 | expansion | 143.2 | glade_vein_a1 | 143.1 | +0.0 % |
| bristleback_b1 | camp | 144.8 | bristleback_a2 | 144.9 | -0.0 % |
| magpie_den_b1 | guild | 149.0 | magpie_den_a1 | 148.9 | +0.0 % |
| heron_ford_b2 | post | 150.3 | heron_ford_a1 | 150.3 | +0.0 % |
| heron_ford_b1 | post | 150.8 | heron_ford_a2 | 150.8 | +0.0 % |
| heath_lair_b1 | lair | 151.0 | heath_lair_a2 | 151.0 | -0.0 % |
| stag_glade_b1 | camp | 160.7 | stag_glade_a2 | 160.8 | -0.0 % |
| glade_vein_b1 | expansion | 160.9 | glade_vein_a2 | 161.0 | -0.0 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| player (A1 south-west) | 0 | keep_t3 | 52.3 | no | 140.1 | 140.1 | 0.37 |
| ally (A2 north-west) | 0 | keep_t0 | 52.3 | no | 138.7 | 140.1 | 0.38 |
| enemy (B1 north-east) | 1 | keep_t4 | 52.3 | no | 138.7 | 140.1 | 0.38 |
| enemy 2 (B2 south-east) | 1 | keep_t1 | 52.3 | no | 140.1 | 140.1 | 0.37 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| player (A1 south-west) | ally keep (keep_t3) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| player (A1 south-west) | enemy keep (nearest) (keep_t4) | 140.1 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| player (A1 south-west) | enemy keep #2 (keep_t1) | 140.1 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| player (A1 south-west) | nearest expansion (node_mid_a1) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| player (A1 south-west) | nearest point (mossmere_a1) | 34.6 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| player (A1 south-west) | nearest camp (bristleback_a1) | 26.5 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| player (A1 south-west) | crown (crown) | 70.2 | 0.0 | 0:15 | 0:14 | 0:09 | 0:18 |
| ally (A2 north-west) | ally keep (keep_t0) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| ally (A2 north-west) | enemy keep (nearest) (keep_t1) | 138.7 | 0.0 | 0:30 | 0:28 | 0:18 | 0:35 |
| ally (A2 north-west) | enemy keep #2 (keep_t4) | 140.1 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| ally (A2 north-west) | nearest expansion (node_mid_a2) | 25.9 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| ally (A2 north-west) | nearest point (mossmere_a2) | 34.0 | 0.0 | 0:07 | 0:07 | 0:05 | 0:08 |
| ally (A2 north-west) | nearest camp (bristleback_a2) | 26.1 | 0.0 | 0:06 | 0:05 | 0:03 | 0:07 |
| ally (A2 north-west) | crown (crown) | 69.6 | 0.0 | 0:15 | 0:14 | 0:09 | 0:17 |
| enemy (B1 north-east) | ally keep (keep_t4) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| enemy (B1 north-east) | enemy keep (nearest) (keep_t3) | 138.7 | 0.0 | 0:30 | 0:28 | 0:18 | 0:35 |
| enemy (B1 north-east) | enemy keep #2 (keep_t0) | 140.1 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| enemy (B1 north-east) | nearest expansion (node_mid_b1) | 25.9 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| enemy (B1 north-east) | nearest point (mossmere_b1) | 34.0 | 0.0 | 0:07 | 0:07 | 0:05 | 0:08 |
| enemy (B1 north-east) | nearest camp (bristleback_b1) | 26.1 | 0.0 | 0:06 | 0:05 | 0:03 | 0:07 |
| enemy (B1 north-east) | crown (crown) | 69.6 | 0.0 | 0:15 | 0:14 | 0:09 | 0:17 |
| enemy 2 (B2 south-east) | ally keep (keep_t1) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| enemy 2 (B2 south-east) | enemy keep (nearest) (keep_t0) | 140.1 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| enemy 2 (B2 south-east) | enemy keep #2 (keep_t3) | 140.1 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| enemy 2 (B2 south-east) | nearest expansion (node_mid_b2) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| enemy 2 (B2 south-east) | nearest point (mossmere_b2) | 34.6 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| enemy 2 (B2 south-east) | nearest camp (bristleback_b2) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| enemy 2 (B2 south-east) | crown (crown) | 70.2 | 0.0 | 0:15 | 0:14 | 0:09 | 0:18 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_s | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_s | 4.8 |
| bridge_road_n | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_n | 4.8 |
| ford_s | ford | 7.0 | 4.8 | 5.8 | ford_s | 4.8 |
| ford_n | ford | 7.0 | 4.8 | 5.8 | ford_n | 4.8 |
| steps_w | steps | 8.0 | 7.3 | 8.3 | steps_e | 7.3 |
| steps_e | steps | 8.0 | 7.3 | 8.3 | steps_w | 7.3 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 70.5 | 6.5 | (-10.1, 2.6) | - |
| keep_t0 -> keep_t1 | 140.1 | 6.5 | (-10.1, 2.6) | - |
| keep_t0 -> keep_t4 | 140.1 | 5.8 | (-10.0, 2.7) | - |
| keep_t0 -> node_mid_a1 | 26.4 | 40.1 | (-61.1, 26.6) | - |
| keep_t3 -> crown | 69.9 | 6.3 | (-10.3, -2.8) | - |
| keep_t3 -> keep_t4 | 140.1 | 6.1 | (-10.3, -2.8) | - |
| keep_t3 -> node_mid_a2 | 25.9 | 40.1 | (-60.7, -26.3) | - |
| keep_t1 -> crown | 69.6 | 6.5 | (10.4, -2.8) | - |
| keep_t1 -> keep_t3 | 138.7 | 5.5 | (10.4, -2.8) | - |
| keep_t1 -> node_mid_b1 | 25.9 | 40.1 | (60.7, -26.3) | - |
| keep_t4 -> crown | 70.2 | 6.3 | (10.1, 2.6) | - |
| keep_t4 -> node_mid_b2 | 26.4 | 40.1 | (61.1, 26.6) | - |


## Hottest metres (every spot-pair shortest path, 4851 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-3.5, 37.5) | 424 | 9 % |
| 2 | (3.5, -37.5) | 421 | 9 % |
| 3 | (14.5, -4.5) | 362 | 7 % |
| 4 | (-14.5, 4.5) | 337 | 7 % |
| 5 | (-14.5, -4.5) | 283 | 6 % |
| 6 | (14.5, 4.5) | 266 | 5 % |
| 7 | (4.5, 35.5) | 193 | 4 % |
| 8 | (-4.5, -34.5) | 175 | 4 % |
| 9 | (3.5, 43.5) | 169 | 3 % |
| 10 | (-3.5, -43.5) | 167 | 3 % |


## Info findings (136)
| Check | Where | What |
|---|---|---|
| N3 | island 6 at (-65.9, -29.9) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 7 at (66.1, -29.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 11 at (-65.9, 30.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 12 at (66.1, 30.1) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 10 islands on top of colliders (636 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | node_a_b1-glade_vein_b1 vs node_a_b2-glade_vein_b2 | 43.6 m vs 45.8 m (4.9 %) |
| F2 | node_a_a2-millstone_cross_a2 vs node_a_b2-millstone_cross_b2 | 74.8 m vs 71.2 m (4.8 %) |
| F2 | node_a_a1-millstone_cross_a1 vs node_a_a2-millstone_cross_a2 | 71.2 m vs 74.8 m (4.8 %) |
| F2 | node_b_a1-millrace_b1 vs node_b_b2-millrace_a2 | 112.9 m vs 107.5 m (4.7 %) |
| F2 | node_mid_a1-heath_lair_b1 vs node_mid_b1-heath_lair_a1 | 137.3 m vs 144.1 m (4.7 %) |
| F2 | node_mid_a2-heath_lair_b2 vs node_mid_b1-heath_lair_a1 | 137.3 m vs 144.1 m (4.7 %) |
| F2 | node_b_a1-millrace_b1 vs node_b_a2-millrace_b2 | 112.9 m vs 107.6 m (4.7 %) |
| F2 | node_b_b1-millrace_a1 vs node_b_b2-millrace_a2 | 112.8 m vs 107.5 m (4.7 %) |
| F2 | node_mid_b1-heath_lair_a1 vs node_mid_b2-heath_lair_a2 | 144.1 m vs 137.3 m (4.7 %) |
| F2 | node_b_a2-millrace_b2 vs node_b_b1-millrace_a1 | 107.6 m vs 112.8 m (4.6 %) |
| F2 | stag_glade_a1-heath_lair_b1 vs stag_glade_b1-heath_lair_a1 | 185.1 m vs 194.0 m (4.6 %) |
| F2 | stag_glade_a2-heath_lair_b2 vs stag_glade_b1-heath_lair_a1 | 185.1 m vs 194.0 m (4.6 %) |
| F2 | stag_glade_b1-heath_lair_a1 vs stag_glade_b2-heath_lair_a2 | 194.0 m vs 185.2 m (4.5 %) |
| F2 | node_b_a1-peddler_b1 vs node_b_b1-peddler_a1 | 123.7 m vs 129.4 m (4.4 %) |
| F2 | node_b_a2-peddler_b2 vs node_b_b1-peddler_a1 | 123.7 m vs 129.4 m (4.4 %) |
| F2 | node_b_b1-peddler_a1 vs node_b_b2-peddler_a2 | 129.4 m vs 123.8 m (4.4 %) |
| F2 | keep_t0-millstone_cross_b1 vs keep_t3-millstone_cross_b2 | 141.7 m vs 135.6 m (4.3 %) |
| F2 | node_mid_b1-tavern_a2 vs node_mid_b2-tavern_a1 | 75.5 m vs 78.9 m (4.3 %) |
| F2 | node_mid_a2-tavern_b1 vs node_mid_b1-tavern_a2 | 78.8 m vs 75.5 m (4.2 %) |
| F2 | node_b_b1-tavern_a2 vs node_b_b2-tavern_a1 | 92.0 m vs 96.1 m (4.2 %) |
| F2 | node_mid_a1-tavern_b2 vs node_mid_b2-tavern_a1 | 75.6 m vs 78.9 m (4.2 %) |
| F2 | node_b_a2-tavern_b1 vs node_b_b1-tavern_a2 | 96.0 m vs 92.0 m (4.2 %) |
| F2 | node_b_a1-tavern_b2 vs node_b_b2-tavern_a1 | 92.1 m vs 96.1 m (4.2 %) |
| F2 | node_mid_a1-tavern_b2 vs node_mid_a2-tavern_b1 | 75.6 m vs 78.8 m (4.1 %) |
| F2 | node_b_a1-tavern_b2 vs node_b_a2-tavern_b1 | 92.1 m vs 96.0 m (4.1 %) |
| F2 | keep_t3-millstone_cross_b2 vs keep_t1-millstone_cross_a1 | 135.6 m vs 141.2 m (4.0 %) |
| F2 | bristleback_a1-heath_lair_b1 vs bristleback_b1-heath_lair_a1 | 160.2 m vs 166.8 m (4.0 %) |
| F2 | bristleback_a2-heath_lair_b2 vs bristleback_b1-heath_lair_a1 | 160.2 m vs 166.8 m (4.0 %) |
| F2 | bristleback_b1-heath_lair_a1 vs bristleback_b2-heath_lair_a2 | 166.8 m vs 160.3 m (3.9 %) |
| F2 | node_mid_a1-heron_ford_b2 vs node_mid_b2-heron_ford_a1 | 129.7 m vs 124.6 m (3.9 %) |
| F2 | node_mid_b1-heron_ford_a2 vs node_mid_b2-heron_ford_a1 | 129.6 m vs 124.6 m (3.9 %) |
| F2 | keep_t0-millstone_cross_b1 vs keep_t4-millstone_cross_a2 | 141.7 m vs 136.3 m (3.9 %) |
| F2 | node_a_b1-rich_a2 vs node_a_b2-rich_a1 | 97.3 m vs 101.2 m (3.9 %) |
| F2 | node_mid_a2-heron_ford_b1 vs node_mid_b2-heron_ford_a1 | 129.6 m vs 124.6 m (3.8 %) |
| F2 | node_a_a1-rich_b2 vs node_a_b2-rich_a1 | 97.3 m vs 101.2 m (3.8 %) |
| F2 | node_a_a2-rich_b1 vs node_a_b1-rich_a2 | 101.0 m vs 97.3 m (3.7 %) |
| F2 | tavern_a1-peddler_b1 vs tavern_a2-peddler_b2 | 89.6 m vs 86.4 m (3.7 %) |
| F2 | node_a_a1-rich_b2 vs node_a_a2-rich_b1 | 97.3 m vs 101.0 m (3.7 %) |
| F2 | tavern_a2-peddler_b2 vs tavern_b1-peddler_a1 | 86.4 m vs 89.6 m (3.6 %) |
| F2 | tavern_a1-peddler_b1 vs tavern_b2-peddler_a2 | 89.6 m vs 86.4 m (3.6 %) |
| F2 | glade_vein_a1-heath_lair_b1 vs glade_vein_b1-heath_lair_a1 | 180.1 m vs 186.8 m (3.6 %) |
| F2 | tavern_b1-peddler_a1 vs tavern_b2-peddler_a2 | 89.6 m vs 86.4 m (3.6 %) |
| F2 | cache_a1-cache_b2 vs cache_a2-cache_b1 | 108.6 m vs 104.7 m (3.6 %) |
| F2 | glade_vein_a2-heath_lair_b2 vs glade_vein_b1-heath_lair_a1 | 180.1 m vs 186.8 m (3.6 %) |
| F2 | node_a_a2-heath_lair_a1 vs node_a_b2-heath_lair_b1 | 101.9 m vs 105.6 m (3.6 %) |
| F2 | node_a_b1-heath_lair_b2 vs node_a_b2-heath_lair_b1 | 101.9 m vs 105.6 m (3.6 %) |
| F2 | keep_t1-rich_a2 vs keep_t4-rich_a1 | 91.9 m vs 95.3 m (3.6 %) |
| F2 | glade_vein_b1-heath_lair_a1 vs glade_vein_b2-heath_lair_a2 | 186.8 m vs 180.1 m (3.6 %) |
| F2 | keep_t1-millstone_cross_a1 vs keep_t4-millstone_cross_a2 | 141.2 m vs 136.3 m (3.5 %) |
| F2 | glade_vein_a1-wayshrine_b1 vs glade_vein_b1-wayshrine_a1 | 122.1 m vs 117.8 m (3.5 %) |
| F2 | node_mid_a2-mid_cache_b1 vs node_mid_b2-mid_cache_a1 | 99.3 m vs 102.8 m (3.5 %) |
| F2 | node_b_b1-mid_cache_a1 vs node_b_b2-mid_cache_a1 | 115.8 m vs 120.0 m (3.5 %) |
| F2 | glade_vein_a1-wayshrine_b1 vs glade_vein_b2-wayshrine_a1 | 122.1 m vs 117.9 m (3.5 %) |
| F2 | node_a_a1-heath_lair_a2 vs node_a_a2-heath_lair_a1 | 105.5 m vs 101.9 m (3.5 %) |
| F2 | node_a_a1-heath_lair_a2 vs node_a_b1-heath_lair_b2 | 105.5 m vs 101.9 m (3.5 %) |
| F2 | node_b_a1-mid_cache_b1 vs node_b_b2-mid_cache_a1 | 115.9 m vs 120.0 m (3.5 %) |
| F2 | glade_vein_a1-wayshrine_b1 vs glade_vein_a2-wayshrine_b1 | 122.1 m vs 117.9 m (3.5 %) |
| F2 | node_b_a2-mid_cache_b1 vs node_b_b1-mid_cache_a1 | 120.0 m vs 115.8 m (3.4 %) |
| F2 | node_b_a1-mid_cache_b1 vs node_b_a2-mid_cache_b1 | 115.9 m vs 120.0 m (3.4 %) |
| F2 | node_mid_b1-mid_cache_a1 vs node_mid_b2-mid_cache_a1 | 99.3 m vs 102.8 m (3.4 %) |
| F2 | glade_vein_a2-tavern_b2 vs glade_vein_b1-tavern_a1 | 123.2 m vs 119.0 m (3.4 %) |
| F2 | glade_vein_a1-tavern_b1 vs glade_vein_a2-tavern_b2 | 119.0 m vs 123.2 m (3.4 %) |
| F2 | node_mid_a1-mid_cache_b1 vs node_mid_b2-mid_cache_a1 | 99.4 m vs 102.8 m (3.4 %) |
| F2 | glade_vein_b1-tavern_a1 vs glade_vein_b2-tavern_a2 | 119.0 m vs 123.1 m (3.4 %) |
| F2 | glade_vein_a1-tavern_b1 vs glade_vein_b2-tavern_a2 | 119.0 m vs 123.1 m (3.3 %) |
| F2 | glade_vein_a2-mossmere_b2 vs glade_vein_b1-mossmere_a1 | 133.5 m vs 129.1 m (3.3 %) |
| F2 | glade_vein_a1-mossmere_b1 vs glade_vein_a2-mossmere_b2 | 129.1 m vs 133.5 m (3.2 %) |
| F2 | bristleback_a2-cache_b2 vs bristleback_b1-cache_a1 | 131.5 m vs 127.2 m (3.2 %) |
| F2 | bristleback_b1-cache_a1 vs bristleback_b2-cache_a2 | 127.2 m vs 131.5 m (3.2 %) |
| F2 | bristleback_a1-cache_b1 vs bristleback_a2-cache_b2 | 127.2 m vs 131.5 m (3.2 %) |
| F2 | bristleback_a1-cache_b1 vs bristleback_b2-cache_a2 | 127.2 m vs 131.5 m (3.2 %) |
| F2 | glade_vein_b1-mossmere_a1 vs glade_vein_b2-mossmere_a2 | 129.1 m vs 133.4 m (3.2 %) |
| F2 | glade_vein_a1-mossmere_b1 vs glade_vein_b2-mossmere_a2 | 129.1 m vs 133.4 m (3.2 %) |
| F2 | node_a_a2-stag_glade_a2 vs node_a_b2-stag_glade_b2 | 52.2 m vs 53.9 m (3.2 %) |
| F2 | node_a_a1-stag_glade_a1 vs node_a_b2-stag_glade_b2 | 52.2 m vs 53.9 m (3.2 %) |
| F2 | node_a_b1-millstone_cross_a1 vs node_a_b2-millstone_cross_a2 | 139.5 m vs 135.2 m (3.1 %) |
| F2 | keep_t0-rich_b2 vs keep_t4-rich_a1 | 92.3 m vs 95.3 m (3.1 %) |
| F2 | mossmere_a1-peddler_b1 vs mossmere_a2-peddler_b2 | 99.8 m vs 96.7 m (3.1 %) |
| F2 | mossmere_a2-peddler_b2 vs mossmere_b1-peddler_a1 | 96.7 m vs 99.8 m (3.1 %) |
| F2 | node_a_a2-millstone_cross_b2 vs node_a_b1-millstone_cross_a1 | 135.2 m vs 139.5 m (3.1 %) |
| F2 | mossmere_a1-peddler_b1 vs mossmere_b2-peddler_a2 | 99.8 m vs 96.7 m (3.1 %) |
| F2 | keep_t3-rich_b1 vs keep_t1-rich_a2 | 94.8 m vs 91.9 m (3.1 %) |
| F2 | mossmere_b1-peddler_a1 vs mossmere_b2-peddler_a2 | 99.8 m vs 96.7 m (3.1 %) |
| F2 | node_b_a1-heron_ford_b2 vs node_b_a2-heron_ford_b1 | 146.2 m vs 141.7 m (3.1 %) |
| F2 | node_b_a2-heron_ford_b1 vs node_b_b1-heron_ford_a2 | 141.7 m vs 146.1 m (3.0 %) |
| F2 | node_b_a1-heron_ford_b2 vs node_b_b2-heron_ford_a1 | 146.2 m vs 141.8 m (3.0 %) |
| F2 | node_a_b1-stag_glade_b1 vs node_a_b2-stag_glade_b2 | 52.3 m vs 53.9 m (3.0 %) |
| F2 | node_b_b1-heron_ford_a2 vs node_b_b2-heron_ford_a1 | 146.1 m vs 141.8 m (3.0 %) |
| F2 | node_a_a1-millstone_cross_b1 vs node_a_b2-millstone_cross_a2 | 139.3 m vs 135.2 m (3.0 %) |
| F2 | node_b_a2-node_mid_b2 vs node_b_b2-node_mid_a2 | 135.5 m vs 131.4 m (3.0 %) |
| F2 | stag_glade_a1-peddler_b1 vs stag_glade_a2-peddler_b2 | 163.2 m vs 158.4 m (3.0 %) |
| F2 | node_a_a1-millstone_cross_b1 vs node_a_a2-millstone_cross_b2 | 139.3 m vs 135.2 m (3.0 %) |
| F2 | stag_glade_a1-peddler_b1 vs stag_glade_b2-peddler_a2 | 163.2 m vs 158.4 m (2.9 %) |
| F2 | stag_glade_a2-peddler_b2 vs stag_glade_b1-peddler_a1 | 158.4 m vs 163.0 m (2.8 %) |
| F2 | stag_glade_b1-peddler_a1 vs stag_glade_b2-peddler_a2 | 163.0 m vs 158.4 m (2.8 %) |
| F2 | rich_a1-bridge_nest_b1 vs rich_a2-bridge_nest_b2 | 133.1 m vs 129.6 m (2.7 %) |
| F2 | rich_a2-bridge_nest_b2 vs rich_b1-bridge_nest_a1 | 129.6 m vs 133.0 m (2.6 %) |
| F2 | rich_a2-bridge_nest_b2 vs rich_b2-bridge_nest_a2 | 129.6 m vs 133.0 m (2.6 %) |
| F2 | keep_t0-rich_b2 vs keep_t3-rich_b1 | 92.3 m vs 94.8 m (2.6 %) |
| F2 | stag_glade_a1-greywater_lodge_a1 vs stag_glade_b2-greywater_lodge_b1 | 73.7 m vs 71.8 m (2.5 %) |
| F2 | stag_glade_a1-greywater_lodge_a1 vs stag_glade_b1-greywater_lodge_b1 | 73.7 m vs 71.8 m (2.5 %) |
| F2 | stag_glade_a2-greywater_lodge_a1 vs stag_glade_b2-greywater_lodge_b1 | 73.7 m vs 71.8 m (2.5 %) |
| F2 | stag_glade_a2-greywater_lodge_a1 vs stag_glade_b1-greywater_lodge_b1 | 73.7 m vs 71.8 m (2.5 %) |
| F2 | magpie_den_a1-heath_lair_b1 vs magpie_den_a1-heath_lair_b2 | 157.7 m vs 161.8 m (2.5 %) |
| F2 | node_b_b1-heron_ford_a1 vs node_b_b2-heron_ford_a2 | 146.7 m vs 150.4 m (2.5 %) |
| F2 | node_b_a1-heron_ford_b1 vs node_b_b2-heron_ford_a2 | 146.7 m vs 150.4 m (2.4 %) |
| F2 | heron_ford_a1-heath_lair_b1 vs heron_ford_b2-heath_lair_a2 | 167.6 m vs 171.8 m (2.4 %) |
| F2 | node_b_a2-heron_ford_b2 vs node_b_b1-heron_ford_a1 | 150.3 m vs 146.7 m (2.4 %) |
| F2 | node_b_a1-heron_ford_b1 vs node_b_a2-heron_ford_b2 | 146.7 m vs 150.3 m (2.4 %) |
| F2 | magpie_den_a1-heath_lair_b2 vs magpie_den_b1-heath_lair_a2 | 161.8 m vs 157.9 m (2.4 %) |
| F2 | node_b_a2-stag_glade_a1 vs node_b_b2-stag_glade_b1 | 104.8 m vs 107.3 m (2.3 %) |
| F2 | node_b_b1-stag_glade_b2 vs node_b_b2-stag_glade_b1 | 104.8 m vs 107.3 m (2.3 %) |
| F2 | node_b_a1-stag_glade_a2 vs node_b_b2-stag_glade_b1 | 104.8 m vs 107.3 m (2.3 %) |
| F2 | magpie_den_a1-heath_lair_b2 vs magpie_den_b1-heath_lair_a1 | 161.8 m vs 158.0 m (2.3 %) |
| F2 | node_mid_a2-heron_ford_b2 vs node_mid_b2-heron_ford_a2 | 130.1 m vs 133.2 m (2.3 %) |
| F2 | node_mid_b1-heron_ford_a1 vs node_mid_b2-heron_ford_a2 | 130.2 m vs 133.2 m (2.3 %) |
| F2 | node_mid_a1-heron_ford_b1 vs node_mid_b2-heron_ford_a2 | 130.2 m vs 133.2 m (2.3 %) |
| F2 | heron_ford_b1-heath_lair_a1 vs heron_ford_b2-heath_lair_a2 | 167.9 m vs 171.8 m (2.2 %) |
| F2 | node_a_a1-cache_b2 vs node_a_b1-cache_a2 | 125.9 m vs 123.3 m (2.1 %) |
| F2 | node_a_a1-cache_b2 vs node_a_a2-cache_b1 | 125.9 m vs 123.3 m (2.1 %) |
| F2 | stag_glade_a2-steps_e vs stag_glade_b1-steps_w | 111.3 m vs 108.9 m (2.1 %) |
| F2 | node_mid_a1-peddler_b1 vs node_mid_a2-peddler_b2 | 112.9 m vs 110.6 m (2.1 %) |
| F2 | node_mid_a2-peddler_b2 vs node_mid_b1-peddler_a1 | 110.6 m vs 112.9 m (2.1 %) |
| F2 | keep_t0-mossmere_b2 vs keep_t1-mossmere_a2 | 106.3 m vs 104.1 m (2.1 %) |
| F2 | stag_glade_a1-steps_e vs stag_glade_a2-steps_e | 108.9 m vs 111.3 m (2.1 %) |
| F2 | node_mid_a1-peddler_b1 vs node_mid_b2-peddler_a2 | 112.9 m vs 110.6 m (2.1 %) |
| F2 | node_mid_b1-peddler_a1 vs node_mid_b2-peddler_a2 | 112.9 m vs 110.6 m (2.1 %) |
| F2 | node_a_a1-cache_b2 vs node_a_b2-cache_a1 | 125.9 m vs 123.4 m (2.1 %) |
| F2 | node_mid_a1-millrace_b1 vs node_mid_b2-millrace_a2 | 96.4 m vs 94.4 m (2.1 %) |
| F2 | keep_t0-mossmere_b2 vs keep_t3-mossmere_b1 | 106.3 m vs 104.1 m (2.0 %) |
| F2 | node_mid_a1-millrace_b1 vs node_mid_a2-millrace_b2 | 96.4 m vs 94.4 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 99 sources) 115.15 s.
- Navmesh raster 2.35 s (213 polygons, 451584 cells of 0.25 m), spot / mirror checks 2.23 s, 4851 paths 1.00 s.
- Map Fourfold Hollow (2v2), scene res://docs/tools/world_forge/out/fourfold_hollow/preview.tscn, sim mode off; level load + navmesh bake 0.4 s (14 frames), lab 122.7 s. Spec: docs/design/map-2v2.md.
