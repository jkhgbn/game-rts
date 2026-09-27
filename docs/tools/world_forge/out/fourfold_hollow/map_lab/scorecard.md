# Map Lab: Fourfold Hollow (2v2) scorecard: world_forge_fourfold_hollow

2026-09-27 08:10 · lab v1.0 · 138.14 s · scanned 95 spots

## Result: **WARN** · score **98 / 100**

0 FAIL · 1 WARN · 11 PASS · 1 info checks; findings: 0 FAIL, 245 WARN, 137 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): node_a_b1-bridge_crown_sw vs node_a_b2-bridge_crown_nw: 121.1 m vs 101.8 m (15.9 %) -> units walk node_a_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 6316 / 6693 pairs within 2 % (0 FAIL, 245 WARN, 132 info))_
2. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_
3. **Combat heat from bot games** (IDEA): v2: feed Bot Lab / Replay Lab unit deaths into the heat map _(from lab idea)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 235 polygons, main area 27073 m² (96 % of the 168 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 95 / 95 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 4 / 4 clean, 5 info | ground-level components other than the main one < 2 m² |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 95 / 95 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 95 / 95 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (4 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6693 / 6693 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 6316 / 6693 pairs within 2 % (0 FAIL, 245 WARN, 132 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | PASS 100 | 10 / 10 clean | per kind, the seats' nearest path lengths differ <= 2 % |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 10 / 10 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 12 / 12 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (672 x 672 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | node_a_b1-bridge_crown_sw vs node_a_b2-bridge_crown_nw | 121.1 m vs 101.8 m (15.9 %) | units walk node_a_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-bridge_crown_se vs node_a_b1-bridge_crown_sw | 101.8 m vs 121.1 m (15.9 %) | units walk node_a_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-bridge_crown_ne vs node_a_b1-bridge_crown_sw | 101.8 m vs 121.1 m (15.9 %) | units walk node_a_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wayshrine_a1-bridge_crown_sw vs wayshrine_b1-bridge_crown_se | 26.6 m vs 22.8 m (14.5 %) | units walk wayshrine_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wayshrine_a1-bridge_crown_sw vs wayshrine_b1-bridge_crown_ne | 26.6 m vs 22.8 m (14.5 %) | units walk wayshrine_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wayshrine_a1-bridge_crown_sw vs wayshrine_a1-bridge_crown_nw | 26.6 m vs 22.8 m (14.5 %) | units walk wayshrine_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-bridge_crown_se vs keep_t1-bridge_crown_sw | 102.0 m vs 118.5 m (13.9 %) | units walk keep_t1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-millrace_a1 vs node_a_b2-millrace_a2 | 148.9 m vs 128.1 m (13.9 %) | units walk node_a_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-millrace_b1 vs node_a_b1-millrace_a1 | 128.1 m vs 148.9 m (13.9 %) | units walk node_a_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-heath_lair_b1 vs ford_nest_a2-heath_lair_b2 | 129.4 m vs 111.4 m (13.9 %) | units walk ford_nest_a1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-millrace_b2 vs node_a_b1-millrace_a1 | 128.2 m vs 148.9 m (13.9 %) | units walk node_a_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-bridge_crown_ne vs millstone_cross_b1-bridge_crown_nw | 88.6 m vs 76.3 m (13.8 %) | units walk millstone_cross_a2-bridge_crown_ne the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-bridge_crown_se vs peddler_b1-bridge_crown_sw | 70.5 m vs 81.8 m (13.8 %) | units walk peddler_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-bridge_crown_sw vs peddler_b2-bridge_crown_nw | 81.8 m vs 70.5 m (13.8 %) | units walk peddler_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-bridge_crown_ne vs peddler_b1-bridge_crown_sw | 70.5 m vs 81.8 m (13.8 %) | units walk peddler_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_b1-bridge_crown_nw vs millstone_cross_b2-bridge_crown_sw | 76.3 m vs 88.5 m (13.7 %) | units walk millstone_cross_b2-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-bridge_crown_se vs millstone_cross_a2-bridge_crown_ne | 76.4 m vs 88.6 m (13.7 %) | units walk millstone_cross_a2-bridge_crown_ne the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-bridge_crown_se vs millstone_cross_b2-bridge_crown_sw | 76.4 m vs 88.5 m (13.6 %) | units walk millstone_cross_b2-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-bridge_crown_sw vs keep_t4-bridge_crown_nw | 118.5 m vs 102.7 m (13.3 %) | units walk keep_t1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-bridge_crown_ne vs keep_t1-bridge_crown_sw | 102.7 m vs 118.5 m (13.3 %) | units walk keep_t1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-node_b_b2 vs keep_t4-node_b_a2 | 178.6 m vs 205.6 m (13.2 %) | units walk keep_t4-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-bridge_crown_se vs millstone_cross_b2-bridge_crown_nw | 92.3 m vs 106.2 m (13.1 %) | units walk millstone_cross_b2-bridge_crown_nw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-bridge_crown_ne vs millstone_cross_b2-bridge_crown_nw | 92.3 m vs 106.2 m (13.0 %) | units walk millstone_cross_b2-bridge_crown_nw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-bridge_crown_se vs millstone_cross_b1-bridge_crown_sw | 92.3 m vs 106.1 m (13.0 %) | units walk millstone_cross_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-bridge_crown_ne vs millstone_cross_b1-bridge_crown_sw | 92.3 m vs 106.1 m (13.0 %) | units walk millstone_cross_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-node_b_b2 vs keep_t1-node_b_a1 | 178.6 m vs 205.1 m (12.9 %) | units walk keep_t1-node_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-steps_e vs node_a_b2-steps_w | 99.6 m vs 113.7 m (12.4 %) | units walk node_a_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-steps_e vs node_a_b2-steps_w | 99.6 m vs 113.7 m (12.4 %) | units walk node_a_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-steps_e vs node_a_b1-steps_w | 99.6 m vs 113.6 m (12.4 %) | units walk node_a_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-steps_e vs node_a_b1-steps_w | 99.6 m vs 113.6 m (12.4 %) | units walk node_a_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-millrace_b2 vs keep_t1-millrace_a1 | 128.5 m vs 146.3 m (12.2 %) | units walk keep_t1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mid_cache_a1-bridge_crown_nw vs mid_cache_b1-bridge_crown_se | 31.3 m vs 35.6 m (12.2 %) | units walk mid_cache_b1-bridge_crown_se the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mid_cache_b1-bridge_crown_ne vs mid_cache_b1-bridge_crown_se | 31.3 m vs 35.6 m (12.2 %) | units walk mid_cache_b1-bridge_crown_se the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mid_cache_a1-bridge_crown_sw vs mid_cache_a1-bridge_crown_nw | 35.6 m vs 31.3 m (12.2 %) | units walk mid_cache_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mid_cache_a1-bridge_crown_sw vs mid_cache_b1-bridge_crown_ne | 35.6 m vs 31.3 m (12.2 %) | units walk mid_cache_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-millwatch_b2 vs keep_t4-millwatch_a2 | 142.9 m vs 162.2 m (11.9 %) | units walk keep_t4-millwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-millrace_a1 vs keep_t4-millrace_a2 | 146.3 m vs 129.2 m (11.7 %) | units walk keep_t1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-millrace_b1 vs keep_t1-millrace_a1 | 129.2 m vs 146.3 m (11.7 %) | units walk keep_t1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-bridge_crown_nw vs glade_vein_b1-bridge_crown_ne | 56.0 m vs 63.4 m (11.7 %) | units walk glade_vein_b1-bridge_crown_ne the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-bridge_crown_ne vs glade_vein_b2-bridge_crown_se | 63.4 m vs 56.0 m (11.7 %) | units walk glade_vein_b1-bridge_crown_ne the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_b1 vs keep_t4-node_b_a2 | 181.6 m vs 205.6 m (11.7 %) | units walk keep_t4-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_b2 vs keep_t1-rich_a1 | 153.3 m vs 173.5 m (11.6 %) | units walk keep_t1-rich_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a2-bridge_crown_nw vs stag_glade_b1-bridge_crown_ne | 51.2 m vs 57.8 m (11.5 %) | units walk stag_glade_b1-bridge_crown_ne the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-millwatch_b2 vs keep_t1-millwatch_a1 | 142.9 m vs 161.5 m (11.5 %) | units walk keep_t1-millwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-millwatch_b1 vs keep_t4-millwatch_a2 | 143.6 m vs 162.2 m (11.5 %) | units walk keep_t4-millwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-bridge_crown_sw vs glade_vein_a2-bridge_crown_nw | 63.2 m vs 56.0 m (11.4 %) | units walk glade_vein_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-bridge_crown_sw vs glade_vein_b2-bridge_crown_se | 63.2 m vs 56.0 m (11.4 %) | units walk glade_vein_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_b1 vs keep_t1-node_b_a1 | 181.6 m vs 205.1 m (11.4 %) | units walk keep_t1-node_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a1-bridge_crown_sw vs stag_glade_a2-bridge_crown_nw | 57.7 m vs 51.2 m (11.3 %) | units walk stag_glade_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_glade_a2-bridge_crown_nw vs stag_glade_b2-bridge_crown_se | 51.2 m vs 57.7 m (11.3 %) | units walk stag_glade_b2-bridge_crown_se the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-peddler_b2 vs millrace_b1-peddler_a1 | 97.5 m vs 109.8 m (11.2 %) | units walk millrace_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-peddler_a1 vs millrace_b2-peddler_a2 | 109.8 m vs 97.5 m (11.2 %) | units walk millrace_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_b1 vs keep_t1-rich_a1 | 154.0 m vs 173.5 m (11.2 %) | units walk keep_t1-rich_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-bridge_crown_se vs heath_lair_a2-bridge_crown_ne | 97.9 m vs 110.2 m (11.2 %) | units walk heath_lair_a2-bridge_crown_ne the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-bridge_crown_se vs heath_lair_b2-bridge_crown_sw | 97.9 m vs 110.1 m (11.1 %) | units walk heath_lair_b2-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_b2 vs keep_t4-rich_a2 | 153.3 m vs 172.5 m (11.1 %) | units walk keep_t4-rich_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-millwatch_b1 vs keep_t1-millwatch_a1 | 143.6 m vs 161.5 m (11.1 %) | units walk keep_t1-millwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-tavern_b2 vs node_a_b2-tavern_a2 | 114.6 m vs 128.9 m (11.1 %) | units walk node_a_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-tavern_b1 vs node_a_b2-tavern_a2 | 114.7 m vs 128.9 m (11.0 %) | units walk node_a_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-steps_e vs keep_t4-steps_w | 99.4 m vs 111.8 m (11.0 %) | units walk keep_t4-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-bridge_crown_se vs heath_lair_b1-bridge_crown_nw | 97.9 m vs 110.0 m (11.0 %) | units walk heath_lair_b1-bridge_crown_nw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-bridge_crown_ne vs node_b_b1-bridge_crown_sw | 101.8 m vs 114.3 m (10.9 %) | units walk node_b_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-bridge_crown_sw vs node_b_b2-bridge_crown_nw | 114.3 m vs 101.8 m (10.9 %) | units walk node_b_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-bridge_crown_se vs node_b_b1-bridge_crown_sw | 101.8 m vs 114.3 m (10.9 %) | units walk node_b_b1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-mouth_lair_b2 vs millrace_a2-mouth_lair_b1 | 51.8 m vs 58.0 m (10.8 %) | units walk millrace_a2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_b1 vs keep_t4-rich_a2 | 154.0 m vs 172.5 m (10.7 %) | units walk keep_t4-rich_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b2 vs keep_t4-peddler_a2 | 147.3 m vs 164.9 m (10.7 %) | units walk keep_t4-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-mouth_lair_b1 vs millrace_b1-mouth_lair_a2 | 58.0 m vs 51.8 m (10.7 %) | units walk millrace_a2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-bridge_crown_sw vs heath_lair_b1-bridge_crown_ne | 84.5 m vs 75.6 m (10.5 %) | units walk heath_lair_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-bridge_crown_sw vs heath_lair_b2-bridge_crown_se | 84.5 m vs 75.6 m (10.5 %) | units walk heath_lair_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-bridge_crown_sw vs heath_lair_a2-bridge_crown_nw | 84.5 m vs 75.6 m (10.5 %) | units walk heath_lair_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-steps_e vs keep_t1-steps_w | 99.4 m vs 111.1 m (10.5 %) | units walk keep_t1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-steps_e vs keep_t4-steps_w | 100.2 m vs 111.8 m (10.4 %) | units walk keep_t4-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-mouth_lair_b2 vs millrace_b2-mouth_lair_a1 | 51.8 m vs 57.7 m (10.3 %) | units walk millrace_b2-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-mouth_lair_a2 vs millrace_b2-mouth_lair_a1 | 51.8 m vs 57.7 m (10.2 %) | units walk millrace_b2-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b2 vs keep_t1-peddler_a1 | 147.3 m vs 163.9 m (10.1 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-bridge_crown_nw vs heron_ford_b1-bridge_crown_ne | 68.7 m vs 76.2 m (9.9 %) | units walk heron_ford_b1-bridge_crown_ne the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-heath_lair_b1 vs millwatch_a2-heath_lair_b2 | 139.8 m vs 126.0 m (9.8 %) | units walk millwatch_a1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-steps_e vs keep_t1-steps_w | 100.2 m vs 111.1 m (9.8 %) | units walk keep_t1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-tavern_b2 vs keep_t4-tavern_a2 | 114.5 m vs 127.0 m (9.8 %) | units walk keep_t4-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-bridge_crown_nw vs heron_ford_b2-bridge_crown_se | 68.7 m vs 76.0 m (9.7 %) | units walk heron_ford_b2-bridge_crown_se the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-bridge_crown_sw vs heron_ford_a2-bridge_crown_nw | 76.0 m vs 68.7 m (9.7 %) | units walk heron_ford_a1-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-ford_n vs node_b_b2-ford_n | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-ford_nest_a2 vs node_b_b2-ford_nest_a2 | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-ford_nest_a2 vs node_b_b1-ford_nest_a1 | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-ford_n vs node_b_b1-ford_s | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b1-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-ford_nest_a1 vs node_b_b2-ford_nest_a2 | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-ford_s vs node_b_b2-ford_n | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-ford_nest_a1 vs node_b_b1-ford_nest_a1 | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-ford_s vs node_b_b1-ford_s | 132.7 m vs 146.8 m (9.6 %) | units walk node_b_b1-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-magpie_den_b1 vs millrace_b1-magpie_den_a1 | 114.5 m vs 103.6 m (9.5 %) | units walk millrace_a2-magpie_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-magpie_den_b1 vs millrace_b1-magpie_den_a1 | 114.5 m vs 103.6 m (9.5 %) | units walk millrace_a1-magpie_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-magpie_den_a1 vs millrace_b2-magpie_den_a1 | 103.6 m vs 114.5 m (9.5 %) | units walk millrace_b2-magpie_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-millrace_b1 vs node_b_b1-millrace_a1 | 128.6 m vs 142.0 m (9.5 %) | units walk node_b_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-millrace_a1 vs node_b_b2-millrace_a2 | 142.0 m vs 128.6 m (9.5 %) | units walk node_b_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-millrace_b2 vs node_b_b1-millrace_a1 | 128.6 m vs 142.0 m (9.5 %) | units walk node_b_b1-millrace_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_nest_a2 vs keep_t1-ford_nest_a1 | 133.3 m vs 120.7 m (9.4 %) | units walk keep_t0-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_n vs keep_t1-ford_s | 133.3 m vs 120.7 m (9.4 %) | units walk keep_t0-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-rich_b1 vs node_b_b1-rich_a1 | 153.4 m vs 169.2 m (9.3 %) | units walk node_b_b1-rich_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-rich_b2 vs node_b_b1-rich_a1 | 153.4 m vs 169.2 m (9.3 %) | units walk node_b_b1-rich_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_a2 vs keep_t3-node_b_a1 | 144.4 m vs 131.0 m (9.3 %) | units walk keep_t0-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_a2 vs keep_t1-node_b_b2 | 144.4 m vs 131.0 m (9.3 %) | units walk keep_t0-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-steps_e vs millstone_cross_b2-steps_w | 89.4 m vs 98.6 m (9.3 %) | units walk millstone_cross_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tavern_b1 vs keep_t4-tavern_a2 | 115.2 m vs 127.0 m (9.2 %) | units walk keep_t4-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-steps_e vs millstone_cross_b2-steps_w | 89.5 m vs 98.6 m (9.2 %) | units walk millstone_cross_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-steps_e vs millstone_cross_b1-steps_w | 89.4 m vs 98.5 m (9.2 %) | units walk millstone_cross_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-steps_e vs millstone_cross_b1-steps_w | 89.5 m vs 98.5 m (9.2 %) | units walk millstone_cross_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_b1 vs ford_nest_a2-peddler_a1 | 105.4 m vs 95.8 m (9.1 %) | units walk ford_nest_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_a1 vs node_a_b2-node_b_b1 | 139.0 m vs 126.3 m (9.1 %) | units walk node_a_a2-node_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_a1 vs node_a_b1-node_b_b2 | 139.0 m vs 126.3 m (9.1 %) | units walk node_a_a2-node_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-millwatch_b1 vs node_b_b2-millwatch_a2 | 142.9 m vs 157.3 m (9.1 %) | units walk node_b_b2-millwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_b1-ford_s vs bristleback_b2-ford_n | 126.9 m vs 139.5 m (9.1 %) | units walk bristleback_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_b1-ford_nest_a1 vs bristleback_b2-ford_nest_a2 | 126.9 m vs 139.5 m (9.1 %) | units walk bristleback_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-millwatch_b2 vs node_b_b2-millwatch_a2 | 143.0 m vs 157.3 m (9.1 %) | units walk node_b_b2-millwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a2-greywater_lodge_b1 vs millrace_b1-greywater_lodge_a1 | 98.5 m vs 89.6 m (9.1 %) | units walk millrace_a2-greywater_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_b1-greywater_lodge_a1 vs millrace_b2-greywater_lodge_a1 | 89.6 m vs 98.5 m (9.1 %) | units walk millrace_b2-greywater_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-greywater_lodge_b1 vs millrace_b1-greywater_lodge_a1 | 98.5 m vs 89.6 m (9.1 %) | units walk millrace_a1-greywater_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a1-peddler_b1 | 95.8 m vs 105.4 m (9.1 %) | units walk ford_nest_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-millwatch_b1 vs node_b_b1-millwatch_a1 | 142.9 m vs 157.2 m (9.1 %) | units walk node_b_b1-millwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-steps_e vs peddler_b2-steps_w | 67.6 m vs 74.4 m (9.0 %) | units walk peddler_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-millwatch_b2 vs node_b_b1-millwatch_a1 | 143.0 m vs 157.2 m (9.0 %) | units walk node_b_b1-millwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_b2-node_b_b1 | 138.8 m vs 126.3 m (9.0 %) | units walk node_a_a1-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_b1-node_b_b2 | 138.8 m vs 126.3 m (9.0 %) | units walk node_a_a1-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_nest_a1 vs keep_t1-ford_nest_a1 | 132.7 m vs 120.7 m (9.0 %) | units walk keep_t3-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_s vs keep_t1-ford_s | 132.7 m vs 120.7 m (9.0 %) | units walk keep_t3-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-steps_e vs peddler_b2-steps_w | 67.7 m vs 74.4 m (9.0 %) | units walk peddler_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-steps_e vs peddler_b1-steps_w | 67.6 m vs 74.3 m (9.0 %) | units walk peddler_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_n vs keep_t4-ford_n | 133.3 m vs 121.4 m (8.9 %) | units walk keep_t0-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_nest_a2 vs keep_t4-ford_nest_a2 | 133.3 m vs 121.4 m (8.9 %) | units walk keep_t0-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_a2 vs keep_t4-node_b_b1 | 144.4 m vs 131.5 m (8.9 %) | units walk keep_t0-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-steps_e vs peddler_b1-steps_w | 67.7 m vs 74.3 m (8.9 %) | units walk peddler_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-mouth_lair_b1 vs ford_nest_a2-mouth_lair_a1 | 133.2 m vs 121.3 m (8.9 %) | units walk ford_nest_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a2-steps_e vs millwatch_b2-steps_w | 63.3 m vs 57.6 m (8.9 %) | units walk millwatch_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-mouth_lair_a2 vs ford_nest_a1-mouth_lair_b1 | 121.4 m vs 133.2 m (8.9 %) | units walk ford_nest_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a2-steps_e vs millwatch_b1-steps_w | 63.3 m vs 57.7 m (8.8 %) | units walk millwatch_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-bristleback_b1 vs node_mid_b2-bristleback_a2 | 135.7 m vs 148.8 m (8.8 %) | units walk node_mid_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-bristleback_b1 vs node_mid_a2-bristleback_b2 | 135.7 m vs 148.8 m (8.8 %) | units walk node_mid_a2-bristleback_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-bristleback_a1 vs node_mid_b2-bristleback_a2 | 135.8 m vs 148.8 m (8.8 %) | units walk node_mid_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a1-steps_e vs millwatch_a2-steps_e | 57.7 m vs 63.3 m (8.8 %) | units walk millwatch_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-peddler_b2 vs millstone_cross_b1-peddler_a1 | 138.1 m vs 151.3 m (8.8 %) | units walk millstone_cross_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-peddler_b1 vs millstone_cross_b1-peddler_a1 | 138.1 m vs 151.3 m (8.8 %) | units walk millstone_cross_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_b1-peddler_a1 vs millstone_cross_b2-peddler_a2 | 151.3 m vs 138.1 m (8.8 %) | units walk millstone_cross_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-tavern_b2 vs node_a_b1-tavern_a1 | 114.6 m vs 125.6 m (8.7 %) | units walk node_a_b1-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-bristleback_b2 vs node_mid_b1-bristleback_a1 | 148.8 m vs 135.8 m (8.7 %) | units walk node_mid_a2-bristleback_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-tavern_b1 vs node_a_b1-tavern_a1 | 114.7 m vs 125.6 m (8.7 %) | units walk node_a_b1-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-mouth_lair_b1 vs millstone_cross_b2-mouth_lair_a2 | 161.7 m vs 177.1 m (8.7 %) | units walk millstone_cross_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-mouth_lair_b2 vs millstone_cross_b2-mouth_lair_a2 | 161.7 m vs 177.1 m (8.7 %) | units walk millstone_cross_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-mouth_lair_b1 vs millstone_cross_b1-mouth_lair_a1 | 161.7 m vs 177.0 m (8.6 %) | units walk millstone_cross_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a2-mouth_lair_b2 vs millstone_cross_b1-mouth_lair_a1 | 161.7 m vs 177.0 m (8.6 %) | units walk millstone_cross_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-ford_nest_a2 vs bristleback_b2-ford_nest_a2 | 127.5 m vs 139.5 m (8.6 %) | units walk bristleback_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-ford_n vs bristleback_b2-ford_n | 127.5 m vs 139.5 m (8.6 %) | units walk bristleback_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_s vs keep_t4-ford_n | 132.7 m vs 121.4 m (8.5 %) | units walk keep_t3-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_nest_a1 vs keep_t4-ford_nest_a2 | 132.7 m vs 121.4 m (8.5 %) | units walk keep_t3-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-mouth_lair_b1 vs peddler_b2-mouth_lair_a2 | 139.9 m vs 152.8 m (8.4 %) | units walk peddler_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-rich_b1 vs node_b_b2-rich_a2 | 153.4 m vs 167.6 m (8.4 %) | units walk node_b_b2-rich_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-mouth_lair_b2 vs peddler_b2-mouth_lair_a2 | 139.9 m vs 152.8 m (8.4 %) | units walk peddler_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-rich_b2 vs node_b_b2-rich_a2 | 153.4 m vs 167.6 m (8.4 %) | units walk node_b_b2-rich_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-mouth_lair_b1 vs peddler_b1-mouth_lair_a1 | 139.9 m vs 152.7 m (8.4 %) | units walk peddler_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-mouth_lair_b2 vs peddler_b1-mouth_lair_a1 | 139.9 m vs 152.7 m (8.4 %) | units walk peddler_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-heath_lair_b1 vs rich_a2-heath_lair_b2 | 150.2 m vs 137.7 m (8.4 %) | units walk rich_a1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-cache_a2 vs node_mid_b2-cache_a1 | 92.3 m vs 100.4 m (8.0 %) | units walk node_mid_b2-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-cache_b1 vs node_mid_b2-cache_a1 | 92.3 m vs 100.4 m (8.0 %) | units walk node_mid_b2-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-cache_b2 vs node_mid_b2-cache_a1 | 92.4 m vs 100.4 m (7.9 %) | units walk node_mid_b2-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-peddler_b2 vs node_b_b2-peddler_a2 | 147.4 m vs 159.9 m (7.9 %) | units walk node_b_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-gloomcap_b1 vs millrace_b1-gloomcap_a1 | 85.5 m vs 78.9 m (7.7 %) | units walk millrace_a1-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-peddler_b1 vs millrace_b1-peddler_a1 | 101.4 m vs 109.8 m (7.7 %) | units walk millrace_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-heath_lair_a2 vs ford_nest_a1-heath_lair_b1 | 119.4 m vs 129.4 m (7.7 %) | units walk ford_nest_a1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-heath_lair_b1 vs ford_nest_a2-heath_lair_a1 | 129.4 m vs 119.5 m (7.7 %) | units walk ford_nest_a1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-peddler_b2 vs node_b_b1-peddler_a1 | 147.4 m vs 159.6 m (7.7 %) | units walk node_b_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-millstone_cross_b1 vs ford_nest_a2-millstone_cross_b2 | 129.6 m vs 119.6 m (7.7 %) | units walk ford_nest_a1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-gloomcap_b1 vs millrace_a2-gloomcap_b1 | 85.5 m vs 79.0 m (7.7 %) | units walk millrace_a1-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millrace_a1-gloomcap_b1 vs millrace_b2-gloomcap_a1 | 85.5 m vs 79.0 m (7.6 %) | units walk millrace_a1-gloomcap_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-heath_lair_b2 vs node_a_b2-heath_lair_a2 | 176.0 m vs 190.2 m (7.4 %) | units walk node_a_b2-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-millstone_cross_b1 vs ford_nest_a2-millstone_cross_a1 | 129.6 m vs 119.9 m (7.4 %) | units walk ford_nest_a1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-heath_lair_b1 vs node_a_b2-heath_lair_a2 | 176.1 m vs 190.2 m (7.4 %) | units walk node_a_b2-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t4-peddler_a2 | 152.6 m vs 164.9 m (7.4 %) | units walk keep_t4-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-heath_lair_b2 vs node_a_b1-heath_lair_a1 | 176.0 m vs 190.1 m (7.4 %) | units walk node_a_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-heath_lair_b1 vs node_a_b1-heath_lair_a1 | 176.1 m vs 190.1 m (7.4 %) | units walk node_a_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a2-heath_lair_b1 vs heron_ford_b1-heath_lair_a2 | 155.1 m vs 167.4 m (7.4 %) | units walk heron_ford_b1-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-bristleback_b2 vs node_b_b1-bristleback_a1 | 178.5 m vs 192.7 m (7.4 %) | units walk node_b_b1-bristleback_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-millstone_cross_a2 vs ford_nest_a1-millstone_cross_b1 | 120.0 m vs 129.6 m (7.4 %) | units walk ford_nest_a1-millstone_cross_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-millstone_cross_b1 vs node_mid_b2-millstone_cross_a2 | 122.6 m vs 132.3 m (7.4 %) | units walk node_mid_b2-millstone_cross_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_b1-heath_lair_a2 vs heron_ford_b2-heath_lair_a1 | 167.4 m vs 155.1 m (7.4 %) | units walk heron_ford_b1-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-steps_e vs node_b_b2-steps_w | 99.0 m vs 106.8 m (7.4 %) | units walk node_b_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-millstone_cross_a1 vs node_mid_b2-millstone_cross_a2 | 122.6 m vs 132.3 m (7.3 %) | units walk node_mid_b2-millstone_cross_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-heath_lair_b2 vs heron_ford_a2-heath_lair_b1 | 167.3 m vs 155.1 m (7.3 %) | units walk heron_ford_a1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-steps_e vs node_b_b2-steps_w | 99.0 m vs 106.8 m (7.3 %) | units walk node_b_b2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-millstone_cross_b1 vs node_mid_a2-millstone_cross_b2 | 122.6 m vs 132.3 m (7.3 %) | units walk node_mid_a2-millstone_cross_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-steps_e vs node_b_b1-steps_w | 99.0 m vs 106.8 m (7.3 %) | units walk node_b_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-bristleback_b2 vs node_b_b2-bristleback_a2 | 178.5 m vs 192.6 m (7.3 %) | units walk node_b_b2-bristleback_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford_a1-heath_lair_b2 vs heron_ford_b2-heath_lair_a1 | 167.3 m vs 155.1 m (7.3 %) | units walk heron_ford_a1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-millstone_cross_b2 vs node_mid_b1-millstone_cross_a1 | 132.3 m vs 122.6 m (7.3 %) | units walk node_mid_a2-millstone_cross_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-steps_e vs node_b_b1-steps_w | 99.0 m vs 106.8 m (7.3 %) | units walk node_b_b1-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-tavern_b2 vs keep_t1-tavern_a1 | 114.5 m vs 123.1 m (6.9 %) | units walk keep_t1-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t1-peddler_a1 | 152.6 m vs 163.9 m (6.9 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a2-peddler_b2 vs bristleback_b1-peddler_a1 | 147.4 m vs 158.3 m (6.9 %) | units walk bristleback_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-heath_lair_a1 vs ford_nest_a2-heath_lair_b2 | 119.5 m vs 111.4 m (6.7 %) | units walk ford_nest_a2-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-heath_lair_a2 vs ford_nest_a2-heath_lair_b2 | 119.4 m vs 111.4 m (6.7 %) | units walk ford_nest_a1-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-heath_lair_b2 vs keep_t4-heath_lair_a2 | 175.9 m vs 188.3 m (6.6 %) | units walk keep_t4-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-tavern_b2 vs node_b_b2-tavern_a2 | 114.1 m vs 122.0 m (6.5 %) | units walk node_b_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-tavern_b1 vs node_b_b2-tavern_a2 | 114.1 m vs 122.0 m (6.5 %) | units walk node_b_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-heron_ford_b1 vs node_mid_b1-heron_ford_a2 | 117.0 m vs 125.2 m (6.5 %) | units walk node_mid_b1-heron_ford_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-heron_ford_b2 vs node_mid_b1-heron_ford_a2 | 117.1 m vs 125.2 m (6.4 %) | units walk node_mid_b1-heron_ford_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a2-heron_ford_b1 vs node_mid_b2-heron_ford_a1 | 117.0 m vs 125.1 m (6.4 %) | units walk node_mid_b2-heron_ford_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-steps_w vs node_a_a2-steps_w | 79.9 m vs 85.4 m (6.4 %) | units walk node_a_a2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-steps_w vs node_a_b2-steps_e | 85.4 m vs 79.9 m (6.4 %) | units walk node_a_a2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-steps_w vs node_a_b1-steps_e | 85.4 m vs 79.9 m (6.4 %) | units walk node_a_a2-steps_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a2-bridge_crown_ne vs cache_b2-bridge_crown_sw | 60.5 m vs 64.6 m (6.4 %) | units walk cache_b2-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b1-bridge_crown_nw vs cache_b2-bridge_crown_sw | 60.5 m vs 64.6 m (6.4 %) | units walk cache_b2-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-mid_cache_b1 vs millstone_cross_a2-mid_cache_b1 | 99.0 m vs 105.7 m (6.4 %) | units walk millstone_cross_a2-mid_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_a1-heron_ford_b2 vs node_mid_b2-heron_ford_a1 | 117.1 m vs 125.1 m (6.4 %) | units walk node_mid_b2-heron_ford_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-mid_cache_b1 vs millstone_cross_b2-mid_cache_a1 | 99.0 m vs 105.7 m (6.4 %) | units walk millstone_cross_b2-mid_cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a1-bridge_crown_se vs cache_b2-bridge_crown_sw | 60.5 m vs 64.6 m (6.4 %) | units walk cache_b2-bridge_crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tavern_b1 vs keep_t1-tavern_a1 | 115.2 m vs 123.1 m (6.4 %) | units walk keep_t1-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-mid_cache_b1 vs millstone_cross_b1-mid_cache_a1 | 99.0 m vs 105.6 m (6.3 %) | units walk millstone_cross_b1-mid_cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-heath_lair_b2 vs keep_t1-heath_lair_a1 | 175.9 m vs 187.6 m (6.2 %) | units walk keep_t1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-heath_lair_b1 vs keep_t4-heath_lair_a2 | 176.6 m vs 188.3 m (6.2 %) | units walk keep_t4-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-mouth_lair_b1 vs ford_nest_a2-mouth_lair_b2 | 133.2 m vs 125.1 m (6.1 %) | units walk ford_nest_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-steps_e vs rich_b2-steps_w | 73.8 m vs 69.3 m (6.1 %) | units walk rich_a1-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a2-heath_lair_b2 vs millwatch_b1-heath_lair_a1 | 126.0 m vs 134.2 m (6.1 %) | units walk millwatch_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-steps_e vs rich_b1-steps_w | 73.8 m vs 69.3 m (6.1 %) | units walk rich_a1-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millwatch_a2-heath_lair_b2 vs millwatch_b2-heath_lair_a2 | 126.0 m vs 134.1 m (6.0 %) | units walk millwatch_b2-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-steps_e vs rich_b2-steps_w | 73.7 m vs 69.3 m (6.0 %) | units walk rich_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-steps_e vs rich_b1-steps_w | 73.7 m vs 69.3 m (6.0 %) | units walk rich_a2-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-heath_lair_b1 vs keep_t1-heath_lair_a1 | 176.6 m vs 187.6 m (5.8 %) | units walk keep_t1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-cache_b1 vs millstone_cross_a2-cache_b2 | 122.8 m vs 130.3 m (5.8 %) | units walk millstone_cross_a2-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-cache_b1 vs millstone_cross_b2-cache_a2 | 122.8 m vs 130.3 m (5.7 %) | units walk millstone_cross_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross_a1-cache_b1 vs millstone_cross_b1-cache_a1 | 122.8 m vs 130.2 m (5.7 %) | units walk millstone_cross_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-peddler_a1 vs ford_nest_a2-peddler_b2 | 95.8 m vs 101.5 m (5.6 %) | units walk ford_nest_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-heath_lair_b2 vs rich_b1-heath_lair_a1 | 137.7 m vs 145.8 m (5.6 %) | units walk rich_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-heath_lair_b2 vs rich_b2-heath_lair_a2 | 137.7 m vs 145.8 m (5.5 %) | units walk rich_b2-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-tavern_a2 vs ford_nest_a2-tavern_a1 | 58.2 m vs 54.9 m (5.5 %) | units walk ford_nest_a1-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-bridge_road_s vs peddler_b2-bridge_road_n | 133.5 m vs 126.2 m (5.5 %) | units walk peddler_a2-bridge_road_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a2-peddler_b2 | 95.8 m vs 101.5 m (5.5 %) | units walk ford_nest_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-bridge_road_n vs peddler_b2-bridge_road_n | 133.5 m vs 126.2 m (5.5 %) | units walk peddler_a1-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-tavern_a2 vs ford_nest_a2-tavern_b2 | 58.2 m vs 55.0 m (5.4 %) | units walk ford_nest_a1-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-heath_lair_b2 vs peddler_b2-heath_lair_a2 | 142.8 m vs 150.9 m (5.3 %) | units walk peddler_b2-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-tavern_a2 vs ford_nest_a1-tavern_b1 | 58.2 m vs 55.1 m (5.3 %) | units walk ford_nest_a1-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-heath_lair_b2 vs peddler_b1-heath_lair_a1 | 142.8 m vs 150.8 m (5.3 %) | units walk peddler_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-peddler_b1 vs node_b_b2-peddler_a2 | 151.5 m vs 159.9 m (5.3 %) | units walk node_b_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_mid_b1-glade_vein_a2 vs node_mid_b2-glade_vein_a1 | 106.4 m vs 112.3 m (5.2 %) | units walk node_mid_b2-glade_vein_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-peddler_b1 vs node_b_b1-peddler_a1 | 151.5 m vs 159.6 m (5.1 %) | units walk node_b_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a2-bridge_crown_se vs bristleback_b2-bridge_crown_nw | 101.7 m vs 107.0 m (5.0 %) | units walk bristleback_b2-bridge_crown_nw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mouth_lair_a1-steps_e vs mouth_lair_b1-steps_w | 91.3 m vs 86.8 m (5.0 %) | units walk mouth_lair_a1-steps_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bristleback_a1-bridge_crown_ne vs bristleback_b2-bridge_crown_nw | 101.7 m vs 107.0 m (5.0 %) | units walk bristleback_b2-bridge_crown_nw the long way: the engine's polygon path, not the map (see F1) |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-66.0, 66.0) | (-65.1, 62.4) | keep_t4 | (-65.1, 62.4) | 0.0 |
| keep_t3 | keep | (-66.0, -66.0) | (-64.6, -61.9) | keep_t1 | (-64.6, -61.9) | 0.0 |
| keep_t1 | keep | (66.0, -66.0) | (64.6, -61.9) | keep_t3 | (64.6, -61.9) | 0.0 |
| keep_t4 | keep | (66.0, 66.0) | (65.1, 62.4) | keep_t0 | (65.1, 62.4) | 0.0 |
| node_a_a1 | home_node | (-69.0, 57.0) | (-68.9, 56.9) | node_a_b2 | (-68.9, 56.9) | 0.0 |
| node_a_a2 | home_node | (-69.0, -57.0) | (-68.9, -56.9) | node_a_b1 | (-68.9, -56.9) | 0.0 |
| node_a_b1 | home_node | (69.0, -57.0) | (68.9, -56.9) | node_a_a2 | (68.9, -56.9) | 0.0 |
| node_a_b2 | home_node | (69.0, 57.0) | (68.9, 56.9) | node_a_a1 | (68.9, 56.9) | 0.0 |
| node_b_a1 | home_node | (-57.0, 69.0) | (-56.9, 68.9) | node_b_b2 | (-56.9, 68.9) | 0.0 |
| node_b_a2 | home_node | (-57.0, -69.0) | (-56.9, -68.9) | node_b_b1 | (-56.9, -68.9) | 0.0 |
| node_b_b1 | home_node | (57.0, -69.0) | (56.9, -68.9) | node_b_a2 | (56.9, -68.9) | 0.0 |
| node_b_b2 | home_node | (57.0, 69.0) | (56.9, 68.9) | node_b_a1 | (56.9, 68.9) | 0.0 |
| node_mid_a1 | expansion | (-39.0, 29.0) | (-38.9, 28.9) | node_mid_b2 | (-38.9, 28.9) | 0.0 |
| node_mid_a2 | expansion | (-39.0, -29.0) | (-38.9, -28.9) | node_mid_b1 | (-38.9, -28.9) | 0.0 |
| node_mid_b1 | expansion | (39.0, -29.0) | (38.9, -28.9) | node_mid_a2 | (38.9, -28.9) | 0.0 |
| node_mid_b2 | expansion | (39.0, 29.0) | (38.9, 28.9) | node_mid_a1 | (38.9, 28.9) | 0.0 |
| glade_vein_a1 | expansion | (-64.0, 19.5) | (-63.9, 19.4) | glade_vein_b2 | (-63.9, 19.4) | 0.0 |
| glade_vein_a2 | expansion | (-64.0, -19.5) | (-63.9, -19.4) | glade_vein_b1 | (-63.9, -19.4) | 0.0 |
| glade_vein_b1 | expansion | (64.0, -19.5) | (63.9, -19.4) | glade_vein_a2 | (63.9, -19.4) | 0.0 |
| glade_vein_b2 | expansion | (64.0, 19.5) | (63.9, 19.4) | glade_vein_a1 | (63.9, 19.4) | 0.0 |
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
| wayshrine_a1 | point | (-30.0, 0.0) | (-29.9, 0.1) | wayshrine_b1 | (-29.9, 0.1) | 0.0 |
| wayshrine_b1 | point | (30.0, 0.0) | (29.9, 0.1) | wayshrine_a1 | (29.9, 0.1) | 0.0 |
| stag_glade_a1 | camp | (-60.0, 13.0) | (-59.9, 12.9) | stag_glade_b2 | (-59.9, 12.9) | 0.0 |
| stag_glade_a2 | camp | (-60.0, -13.0) | (-59.9, -12.9) | stag_glade_b1 | (-59.9, -12.9) | 0.0 |
| stag_glade_b1 | camp | (60.0, -13.0) | (59.9, -12.9) | stag_glade_a2 | (59.9, -12.9) | 0.0 |
| stag_glade_b2 | camp | (60.0, 13.0) | (59.9, 12.9) | stag_glade_a1 | (59.9, 12.9) | 0.0 |
| bristleback_a1 | camp | (-40.0, 80.0) | (-39.9, 79.9) | bristleback_b2 | (-39.9, 79.9) | 0.0 |
| bristleback_a2 | camp | (-40.0, -80.0) | (-39.9, -79.9) | bristleback_b1 | (-39.9, -79.9) | 0.0 |
| bristleback_b1 | camp | (40.0, -80.0) | (39.9, -79.9) | bristleback_a2 | (39.9, -79.9) | 0.0 |
| bristleback_b2 | camp | (40.0, 80.0) | (39.9, 79.9) | bristleback_a1 | (39.9, 79.9) | 0.0 |
| gloomcap_a1 | camp | (-50.0, 0.0) | (-49.9, 0.1) | gloomcap_b1 | (-49.9, 0.1) | 0.0 |
| gloomcap_b1 | camp | (50.0, 0.0) | (49.9, 0.1) | gloomcap_a1 | (49.9, 0.1) | 0.0 |
| ford_nest_a1 | camp | (0.0, 40.0) | (-0.1, 39.9) | ford_nest_a1 | (0.1, 39.9) | 0.3 |
| ford_nest_a2 | camp | (0.0, -40.0) | (-0.1, -39.9) | ford_nest_a2 | (0.1, -39.9) | 0.3 |
| tavern_a1 | tavern | (-25.0, 9.0) | (-24.9, 8.9) | tavern_b2 | (-24.9, 8.9) | 0.0 |
| tavern_a2 | tavern | (-25.0, -9.0) | (-24.9, -8.9) | tavern_b1 | (-24.9, -8.9) | 0.0 |
| tavern_b1 | tavern | (25.0, -9.0) | (24.9, -8.9) | tavern_a2 | (24.9, -8.9) | 0.0 |
| tavern_b2 | tavern | (25.0, 9.0) | (24.9, 8.9) | tavern_a1 | (24.9, 8.9) | 0.0 |
| heron_ford_a1 | post | (-76.0, 24.0) | (-75.9, 23.9) | heron_ford_b2 | (-75.9, 23.9) | 0.0 |
| heron_ford_a2 | post | (-76.0, -24.0) | (-75.9, -23.9) | heron_ford_b1 | (-75.9, -23.9) | 0.0 |
| heron_ford_b1 | post | (76.0, -24.0) | (75.9, -23.9) | heron_ford_a2 | (75.9, -23.9) | 0.0 |
| heron_ford_b2 | post | (76.0, 24.0) | (75.9, 23.9) | heron_ford_a1 | (75.9, 23.9) | 0.0 |
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
| mid_cache_a1 | cache | (-39.0, 0.0) | (-38.9, 0.1) | mid_cache_b1 | (-38.9, 0.1) | 0.0 |
| mid_cache_b1 | cache | (39.0, 0.0) | (38.9, 0.1) | mid_cache_a1 | (38.9, 0.1) | 0.0 |
| heath_lair_a1 | lair | (-78.0, 40.0) | (-77.9, 39.9) | heath_lair_b2 | (-77.9, 39.9) | 0.0 |
| heath_lair_a2 | lair | (-78.0, -40.0) | (-77.9, -39.9) | heath_lair_b1 | (-77.9, -39.9) | 0.0 |
| heath_lair_b1 | lair | (78.0, -40.0) | (77.9, -39.9) | heath_lair_a2 | (77.9, -39.9) | 0.0 |
| heath_lair_b2 | lair | (78.0, 40.0) | (77.9, 39.9) | heath_lair_a1 | (77.9, 39.9) | 0.0 |
| mouth_lair_a1 | lair | (-9.0, 80.0) | (-8.9, 79.9) | mouth_lair_b2 | (-8.9, 79.9) | 0.0 |
| mouth_lair_a2 | lair | (-9.0, -80.0) | (-8.9, -79.9) | mouth_lair_b1 | (-8.9, -79.9) | 0.0 |
| mouth_lair_b1 | lair | (9.0, -80.0) | (8.9, -79.9) | mouth_lair_a2 | (8.9, -79.9) | 0.0 |
| mouth_lair_b2 | lair | (9.0, 80.0) | (8.9, 79.9) | mouth_lair_a1 | (8.9, 79.9) | 0.0 |
| bridge_road_s | crossing_bridge_road | (0.0, 72.0) | (-0.1, 71.9) | bridge_road_s | (0.1, 71.9) | 0.3 |
| bridge_road_n | crossing_bridge_road | (0.0, -72.0) | (-0.1, -71.9) | bridge_road_n | (0.1, -71.9) | 0.3 |
| ford_s | crossing_ford | (0.0, 40.0) | (-0.1, 39.9) | ford_s | (0.1, 39.9) | 0.3 |
| ford_n | crossing_ford | (0.0, -40.0) | (-0.1, -39.9) | ford_n | (0.1, -39.9) | 0.3 |
| bridge_crown_sw | crossing_bridge_lane | (-9.0, 9.0) | (-8.9, 8.9) | bridge_crown_se | (-8.9, 8.9) | 0.0 |
| bridge_crown_nw | crossing_bridge_lane | (-9.0, -9.0) | (-8.9, -8.9) | bridge_crown_ne | (-8.9, -8.9) | 0.0 |
| bridge_crown_ne | crossing_bridge_lane | (9.0, -9.0) | (8.9, -8.9) | bridge_crown_nw | (8.9, -8.9) | 0.0 |
| bridge_crown_se | crossing_bridge_lane | (9.0, 9.0) | (8.9, 8.9) | bridge_crown_sw | (8.9, 8.9) | 0.0 |
| steps_w | crossing_steps | (-12.8, 0.0) | (-12.6, 0.1) | steps_e | (-12.6, 0.1) | 0.0 |
| steps_e | crossing_steps | (12.8, 0.0) | (12.6, 0.1) | steps_w | (12.6, 0.1) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 377)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | node_a_b1 - bridge_crown_sw | 121.1 | node_a_b2 - bridge_crown_nw | 101.8 | +15.9 % |
| 2 | node_a_a2 - bridge_crown_se | 101.8 | node_a_b1 - bridge_crown_sw | 121.1 | -15.9 % |
| 3 | node_a_a1 - bridge_crown_ne | 101.8 | node_a_b1 - bridge_crown_sw | 121.1 | -15.9 % |
| 4 | wayshrine_a1 - bridge_crown_sw | 26.6 | wayshrine_b1 - bridge_crown_se | 22.8 | +14.5 % |
| 5 | wayshrine_a1 - bridge_crown_sw | 26.6 | wayshrine_b1 - bridge_crown_ne | 22.8 | +14.5 % |
| 6 | wayshrine_a1 - bridge_crown_sw | 26.6 | wayshrine_a1 - bridge_crown_nw | 22.8 | +14.5 % |
| 7 | keep_t3 - bridge_crown_se | 102.0 | keep_t1 - bridge_crown_sw | 118.5 | -13.9 % |
| 8 | node_a_b1 - millrace_a1 | 148.9 | node_a_b2 - millrace_a2 | 128.1 | +13.9 % |
| 9 | node_a_a1 - millrace_b1 | 128.1 | node_a_b1 - millrace_a1 | 148.9 | -13.9 % |
| 10 | ford_nest_a1 - heath_lair_b1 | 129.4 | ford_nest_a2 - heath_lair_b2 | 111.4 | +13.9 % |
| 11 | node_a_a2 - millrace_b2 | 128.2 | node_a_b1 - millrace_a1 | 148.9 | -13.9 % |
| 12 | millstone_cross_a2 - bridge_crown_ne | 88.6 | millstone_cross_b1 - bridge_crown_nw | 76.3 | +13.8 % |
| 13 | peddler_a2 - bridge_crown_se | 70.5 | peddler_b1 - bridge_crown_sw | 81.8 | -13.8 % |
| 14 | peddler_b1 - bridge_crown_sw | 81.8 | peddler_b2 - bridge_crown_nw | 70.5 | +13.8 % |
| 15 | peddler_a1 - bridge_crown_ne | 70.5 | peddler_b1 - bridge_crown_sw | 81.8 | -13.8 % |
| 16 | millstone_cross_b1 - bridge_crown_nw | 76.3 | millstone_cross_b2 - bridge_crown_sw | 88.5 | -13.7 % |
| 17 | millstone_cross_a1 - bridge_crown_se | 76.4 | millstone_cross_a2 - bridge_crown_ne | 88.6 | -13.7 % |
| 18 | millstone_cross_a1 - bridge_crown_se | 76.4 | millstone_cross_b2 - bridge_crown_sw | 88.5 | -13.6 % |
| 19 | keep_t1 - bridge_crown_sw | 118.5 | keep_t4 - bridge_crown_nw | 102.7 | +13.3 % |
| 20 | keep_t0 - bridge_crown_ne | 102.7 | keep_t1 - bridge_crown_sw | 118.5 | -13.3 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| player (A1 south-west) | 42.6 (node_mid_a1) | 56.4 (mossmere_a1) | 31.1 (bristleback_a1) | 25.9 (heath_lair_a1) | 67.0 (tavern_a1) | 40.0 (heron_ford_a1) | 37.4 (peddler_a1) | 43.3 (cache_a1) | 90.0 (crown) | 136.4 |
| ally (A2 north-west) | 41.9 (node_mid_a2) | 55.7 (mossmere_a2) | 30.8 (bristleback_a2) | 25.7 (heath_lair_a2) | 66.3 (tavern_a2) | 39.6 (heron_ford_a2) | 36.8 (peddler_a2) | 42.6 (cache_a2) | 89.3 (crown) | 135.2 |
| enemy (B1 north-east) | 41.9 (node_mid_b1) | 55.7 (mossmere_b1) | 30.7 (bristleback_b1) | 25.7 (heath_lair_b1) | 66.3 (tavern_b1) | 39.6 (heron_ford_b1) | 36.8 (peddler_b1) | 42.6 (cache_b1) | 89.3 (crown) | 135.2 |
| enemy 2 (B2 south-east) | 42.6 (node_mid_b2) | 56.4 (mossmere_b2) | 31.1 (bristleback_b2) | 25.9 (heath_lair_b2) | 67.0 (tavern_b2) | 40.0 (heron_ford_b2) | 37.4 (peddler_b2) | 43.3 (cache_b2) | 90.0 (crown) | 136.4 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| node_a_a1 | home_node | 6.7 | node_a_b2 | 6.7 | +0.0 % |
| node_b_a1 | home_node | 11.1 | node_b_b2 | 11.0 | +0.8 % |
| heath_lair_a1 | lair | 25.9 | heath_lair_b2 | 25.9 | +0.0 % |
| bristleback_a1 | camp | 31.1 | bristleback_b2 | 31.1 | +0.2 % |
| peddler_a1 | peddler | 37.4 | peddler_b2 | 37.4 | +0.0 % |
| heron_ford_a1 | post | 40.0 | heron_ford_b2 | 40.0 | +0.0 % |
| node_mid_a1 | expansion | 42.6 | node_mid_b2 | 42.6 | +0.0 % |
| glade_vein_a1 | expansion | 43.0 | glade_vein_b2 | 43.0 | +0.0 % |
| cache_a1 | cache | 43.3 | cache_b2 | 43.3 | +0.0 % |
| millstone_cross_a1 | post | 43.5 | millstone_cross_b2 | 43.5 | +0.0 % |
| stag_glade_a1 | camp | 49.8 | stag_glade_b2 | 49.8 | +0.0 % |
| rich_a1 | expansion | 51.3 | rich_b2 | 51.3 | +0.0 % |
| millrace_a1 | expansion | 55.9 | millrace_b2 | 55.9 | +0.0 % |
| mossmere_a1 | point | 56.4 | mossmere_b2 | 56.4 | +0.0 % |
| millwatch_a1 | point | 58.2 | millwatch_b2 | 58.2 | +0.0 % |
| mouth_lair_a1 | lair | 59.0 | mouth_lair_b2 | 59.0 | +0.0 % |
| greywater_lodge_a1 | guild | 62.3 | greywater_lodge_b1 | 62.3 | +0.0 % |
| magpie_den_a1 | guild | 63.8 | magpie_den_b1 | 63.8 | +0.0 % |
| gloomcap_a1 | camp | 64.1 | gloomcap_b1 | 64.1 | +0.0 % |
| bridge_road_s | crossing_bridge_road | 65.7 | bridge_road_s | 65.7 | +0.0 % |
| tavern_a1 | tavern | 67.0 | tavern_b2 | 67.0 | +0.0 % |
| mid_cache_a1 | cache | 67.6 | mid_cache_b1 | 67.6 | +0.0 % |
| ford_s | crossing_ford | 68.8 | ford_s | 68.8 | +0.0 % |
| ford_nest_a1 | camp | 68.8 | ford_nest_a1 | 68.8 | +0.0 % |
| wayshrine_a1 | point | 71.5 | wayshrine_b1 | 71.5 | +0.0 % |
| stag_glade_a2 | camp | 75.4 | stag_glade_b1 | 75.4 | +0.0 % |
| mouth_lair_b2 | lair | 77.1 | mouth_lair_a1 | 77.1 | +0.1 % |
| bridge_crown_sw | crossing_bridge_lane | 77.6 | bridge_crown_se | 77.6 | +0.0 % |
| millwatch_b2 | point | 81.7 | millwatch_a1 | 81.6 | +0.2 % |
| glade_vein_a2 | expansion | 81.8 | glade_vein_b1 | 81.8 | +0.0 % |
| tavern_a2 | tavern | 81.8 | tavern_b1 | 81.8 | +0.0 % |
| rich_b2 | expansion | 81.9 | rich_a1 | 81.8 | +0.1 % |
| millrace_b2 | expansion | 85.2 | millrace_a1 | 85.2 | +0.0 % |
| cache_a2 | cache | 85.6 | cache_b1 | 85.6 | +0.0 % |
| mossmere_a2 | point | 85.9 | mossmere_b1 | 85.9 | +0.0 % |
| steps_w | crossing_steps | 86.4 | steps_e | 86.4 | +0.0 % |
| heron_ford_a2 | post | 86.9 | heron_ford_b1 | 86.9 | +0.0 % |
| crown | crown | 90.0 | crown | 90.0 | +0.0 % |
| millstone_cross_b2 | post | 90.0 | millstone_cross_a1 | 90.0 | +0.0 % |
| bridge_crown_nw | crossing_bridge_lane | 94.1 | bridge_crown_ne | 94.1 | +0.0 % |
| node_mid_a2 | expansion | 95.0 | node_mid_b1 | 95.0 | +0.0 % |
| peddler_b2 | peddler | 99.0 | peddler_a1 | 99.0 | -0.0 % |
| steps_e | crossing_steps | 100.2 | steps_w | 111.8 | -10.4 % |
| bridge_crown_se | crossing_bridge_lane | 101.9 | bridge_crown_sw | 101.7 | +0.2 % |
| bridge_crown_ne | crossing_bridge_lane | 102.7 | bridge_crown_nw | 102.7 | +0.0 % |
| heath_lair_a2 | lair | 103.0 | heath_lair_b1 | 103.0 | +0.0 % |
| bristleback_b2 | camp | 106.5 | bristleback_a1 | 106.5 | +0.0 % |
| mossmere_b2 | point | 108.1 | mossmere_a1 | 108.0 | +0.0 % |
| tavern_b2 | tavern | 108.6 | tavern_a1 | 108.6 | +0.1 % |
| node_mid_b2 | expansion | 109.3 | node_mid_a1 | 109.3 | +0.0 % |
| millrace_a2 | expansion | 109.9 | millrace_b1 | 109.9 | +0.0 % |
| tavern_b1 | tavern | 115.2 | tavern_a2 | 127.0 | -9.2 % |
| peddler_a2 | peddler | 117.7 | peddler_b1 | 117.7 | +0.0 % |
| wayshrine_b1 | point | 118.7 | wayshrine_a1 | 118.6 | +0.1 % |
| node_a_a2 | home_node | 119.3 | node_a_b1 | 119.3 | +0.0 % |
| cache_b2 | cache | 121.9 | cache_a1 | 121.9 | +0.0 % |
| node_b_b2 | home_node | 122.4 | node_b_a1 | 122.4 | +0.0 % |
| keep_t3 | keep | 124.3 | keep_t1 | 124.3 | -0.0 % |
| mid_cache_b1 | cache | 124.4 | mid_cache_a1 | 124.3 | +0.1 % |
| millwatch_a2 | point | 127.8 | millwatch_b1 | 127.8 | +0.0 % |
| millrace_b1 | expansion | 129.2 | millrace_a2 | 129.2 | +0.0 % |
| gloomcap_b1 | camp | 132.5 | gloomcap_a1 | 132.5 | +0.0 % |
| ford_n | crossing_ford | 133.3 | ford_n | 121.4 | +8.9 % |
| ford_nest_a2 | camp | 133.3 | ford_nest_a2 | 121.4 | +8.9 % |
| mossmere_b1 | point | 134.2 | mossmere_a2 | 134.1 | +0.1 % |
| rich_a2 | expansion | 134.4 | rich_b1 | 134.4 | +0.0 % |
| stag_glade_b2 | camp | 134.5 | stag_glade_a1 | 134.5 | +0.0 % |
| glade_vein_b2 | expansion | 136.0 | glade_vein_a1 | 136.0 | +0.0 % |
| keep_t4 | keep | 136.4 | keep_t0 | 136.4 | +0.0 % |
| greywater_lodge_b1 | guild | 143.1 | greywater_lodge_a1 | 143.1 | +0.0 % |
| millwatch_b1 | point | 143.6 | millwatch_a2 | 162.2 | -11.5 % |
| millstone_cross_a2 | post | 144.3 | millstone_cross_b1 | 144.3 | +0.0 % |
| node_b_a2 | home_node | 144.4 | node_b_b1 | 131.5 | +8.9 % |
| bristleback_a2 | camp | 144.5 | bristleback_b1 | 144.5 | +0.0 % |
| heath_lair_b2 | lair | 146.1 | heath_lair_a1 | 146.1 | -0.0 % |
| heron_ford_b2 | post | 146.3 | heron_ford_a1 | 146.3 | -0.0 % |
| node_a_b2 | home_node | 147.9 | node_a_a1 | 147.7 | +0.2 % |
| node_mid_b1 | expansion | 148.1 | node_mid_a2 | 148.0 | +0.1 % |
| cache_b1 | cache | 148.3 | cache_a2 | 148.2 | +0.1 % |
| stag_glade_b1 | camp | 148.6 | stag_glade_a2 | 148.5 | +0.0 % |
| bridge_road_n | crossing_bridge_road | 149.5 | bridge_road_n | 149.5 | -0.1 % |
| peddler_b1 | peddler | 152.6 | peddler_a2 | 164.9 | -7.4 % |
| mouth_lair_a2 | lair | 153.0 | mouth_lair_b1 | 153.0 | +0.0 % |
| rich_b1 | expansion | 154.0 | rich_a2 | 172.5 | -10.7 % |
| glade_vein_b1 | expansion | 155.9 | glade_vein_a2 | 155.9 | +0.0 % |
| magpie_den_b1 | guild | 157.1 | magpie_den_a1 | 157.1 | +0.0 % |
| mouth_lair_b1 | lair | 161.5 | mouth_lair_a2 | 161.6 | -0.0 % |
| heron_ford_b1 | post | 167.9 | heron_ford_a2 | 167.8 | +0.0 % |
| millstone_cross_b1 | post | 173.3 | millstone_cross_a2 | 173.4 | -0.1 % |
| heath_lair_b1 | lair | 176.6 | heath_lair_a2 | 188.3 | -6.2 % |
| keep_t1 | keep | 180.6 | keep_t3 | 180.6 | +0.0 % |
| node_b_b1 | home_node | 181.6 | node_b_a2 | 205.6 | -11.7 % |
| node_a_b1 | home_node | 187.7 | node_a_a2 | 187.6 | +0.0 % |
| bristleback_b1 | camp | 189.8 | bristleback_a2 | 189.9 | -0.1 % |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_s | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_s | 4.8 |
| bridge_road_n | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_n | 4.8 |
| ford_s | ford | 7.0 | 4.8 | 5.8 | ford_s | 4.8 |
| ford_n | ford | 7.0 | 4.8 | 5.8 | ford_n | 4.8 |
| bridge_crown_sw | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_se | 6.8 |
| bridge_crown_nw | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_ne | 7.1 |
| bridge_crown_ne | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_nw | 7.1 |
| bridge_crown_se | bridge_lane | 8.0 | 6.8 | 7.8 | bridge_crown_sw | 7.1 |
| steps_w | steps | 6.0 | 5.0 | 6.0 | steps_e | 5.3 |
| steps_e | steps | 6.0 | 5.3 | 6.3 | steps_w | 5.0 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 90.2 | 5.9 | (-8.0, 7.8) | - |
| keep_t0 -> keep_t1 | 180.6 | 5.8 | (-6.2, 9.8) | - |
| keep_t0 -> keep_t4 | 136.4 | 4.8 | (-0.2, 42.5) | - |
| keep_t0 -> node_mid_a1 | 42.6 | 40.1 | (-62.7, 59.2) | - |
| keep_t3 -> crown | 89.6 | 5.4 | (-7.6, -7.2) | - |
| keep_t3 -> keep_t4 | 180.6 | 5.8 | (-5.6, -9.4) | - |
| keep_t3 -> node_mid_a2 | 41.9 | 40.1 | (-62.2, -58.7) | - |
| keep_t1 -> crown | 89.5 | 5.5 | (7.7, -7.1) | - |
| keep_t1 -> keep_t3 | 135.2 | 4.8 | (-0.4, -42.3) | - |
| keep_t1 -> node_mid_b1 | 41.9 | 40.1 | (62.2, -58.7) | - |
| keep_t4 -> crown | 90.0 | 5.9 | (8.1, 7.7) | - |
| keep_t4 -> node_mid_b2 | 42.6 | 40.1 | (62.7, 59.2) | - |


## Hottest metres (every spot-pair shortest path, 4465 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-2.5, -37.5) | 261 | 6 % |
| 2 | (-9.5, 2.5) | 255 | 6 % |
| 3 | (-2.5, 37.5) | 240 | 5 % |
| 4 | (-7.5, -13.5) | 169 | 4 % |
| 5 | (-7.5, 13.5) | 160 | 4 % |
| 6 | (24.5, -8.5) | 157 | 4 % |
| 7 | (9.5, 2.5) | 157 | 4 % |
| 8 | (24.5, 8.5) | 147 | 3 % |
| 9 | (-24.5, -8.5) | 144 | 3 % |
| 10 | (0.5, 0.5) | 144 | 3 % |


## Info findings (137)
| Check | Where | What |
|---|---|---|
| N3 | island 5 at (-65.9, -65.9) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 6 at (66.1, -65.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 16 at (-65.9, 66.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 17 at (66.1, 66.1) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 14 islands on top of colliders (547 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | mouth_lair_a1-steps_e vs mouth_lair_b2-steps_w | 91.3 m vs 86.8 m (5.0 %) |
| F2 | node_b_a1-bristleback_b1 vs node_b_b1-bristleback_a1 | 183.1 m vs 192.7 m (5.0 %) |
| F2 | bristleback_a2-bridge_crown_se vs bristleback_b1-bridge_crown_sw | 101.7 m vs 107.0 m (5.0 %) |
| F2 | millrace_a1-millstone_cross_b1 vs millrace_b2-millstone_cross_a2 | 125.5 m vs 119.3 m (5.0 %) |
| F2 | bristleback_a1-bridge_crown_ne vs bristleback_b1-bridge_crown_sw | 101.7 m vs 107.0 m (5.0 %) |
| F2 | millrace_a1-millstone_cross_b1 vs millrace_a2-millstone_cross_b2 | 125.5 m vs 119.3 m (5.0 %) |
| F2 | millrace_a1-mid_cache_b1 vs millrace_a2-mid_cache_b1 | 74.5 m vs 70.8 m (5.0 %) |
| F2 | millrace_a2-mid_cache_b1 vs millrace_b1-mid_cache_a1 | 70.8 m vs 74.5 m (5.0 %) |
| F2 | mouth_lair_a2-steps_e vs mouth_lair_b1-steps_w | 91.3 m vs 86.8 m (4.9 %) |
| F2 | node_b_a1-bristleback_b1 vs node_b_b2-bristleback_a2 | 183.1 m vs 192.6 m (4.9 %) |
| F2 | mouth_lair_a2-steps_e vs mouth_lair_b2-steps_w | 91.3 m vs 86.8 m (4.9 %) |
| F2 | millrace_a1-mid_cache_b1 vs millrace_b2-mid_cache_a1 | 74.5 m vs 70.9 m (4.9 %) |
| F2 | millrace_b1-mid_cache_a1 vs millrace_b2-mid_cache_a1 | 74.5 m vs 70.9 m (4.9 %) |
| F2 | bristleback_a2-ford_nest_a1 vs bristleback_b2-ford_nest_a2 | 132.8 m vs 139.5 m (4.8 %) |
| F2 | bristleback_a2-ford_s vs bristleback_b2-ford_n | 132.8 m vs 139.5 m (4.8 %) |
| F2 | tavern_a2-cache_b1 vs tavern_b1-cache_a2 | 76.5 m vs 80.2 m (4.7 %) |
| F2 | millrace_a2-bristleback_b2 vs millrace_b1-bristleback_a1 | 128.7 m vs 134.9 m (4.7 %) |
| F2 | millrace_b1-bristleback_a1 vs millrace_b2-bristleback_a2 | 134.9 m vs 128.7 m (4.7 %) |
| F2 | tavern_a1-cache_b2 vs tavern_b1-cache_a2 | 76.5 m vs 80.2 m (4.6 %) |
| F2 | bristleback_a2-heath_lair_b2 vs bristleback_b1-heath_lair_a1 | 168.0 m vs 176.1 m (4.6 %) |
| F2 | tavern_a2-cache_b1 vs tavern_b2-cache_a1 | 76.5 m vs 80.2 m (4.6 %) |
| F2 | bristleback_a2-heath_lair_b2 vs bristleback_b2-heath_lair_a2 | 168.0 m vs 176.0 m (4.6 %) |
| F2 | tavern_a1-cache_b2 vs tavern_b2-cache_a1 | 76.5 m vs 80.2 m (4.5 %) |
| F2 | millrace_a2-peddler_a1 vs millrace_b2-peddler_b1 | 91.0 m vs 86.9 m (4.5 %) |
| F2 | millrace_b1-peddler_b2 vs millrace_b2-peddler_b1 | 91.0 m vs 86.9 m (4.5 %) |
| F2 | millrace_a1-peddler_a2 vs millrace_b2-peddler_b1 | 91.0 m vs 86.9 m (4.5 %) |
| F2 | bristleback_a2-ford_s vs bristleback_b1-ford_s | 132.8 m vs 126.9 m (4.5 %) |
| F2 | bristleback_a2-ford_nest_a1 vs bristleback_b1-ford_nest_a1 | 132.8 m vs 126.9 m (4.5 %) |
| F2 | peddler_a1-heath_lair_b1 vs peddler_b2-heath_lair_a2 | 144.2 m vs 150.9 m (4.4 %) |
| F2 | peddler_a1-heath_lair_b1 vs peddler_b1-heath_lair_a1 | 144.2 m vs 150.8 m (4.4 %) |
| F2 | bristleback_a1-peddler_b1 vs bristleback_b1-peddler_a1 | 151.3 m vs 158.3 m (4.4 %) |
| F2 | millwatch_b1-tavern_a1 vs millwatch_b2-tavern_a2 | 69.6 m vs 72.8 m (4.4 %) |
| F2 | millwatch_a2-tavern_b2 vs millwatch_b2-tavern_a2 | 69.7 m vs 72.8 m (4.4 %) |
| F2 | millwatch_a1-tavern_b1 vs millwatch_b2-tavern_a2 | 69.7 m vs 72.8 m (4.4 %) |
| F2 | mossmere_a2-heath_lair_b1 vs mossmere_b1-heath_lair_a2 | 117.0 m vs 122.3 m (4.3 %) |
| F2 | node_b_a2-heath_lair_b2 vs node_b_b2-heath_lair_a2 | 175.5 m vs 183.3 m (4.3 %) |
| F2 | node_b_a2-heath_lair_b2 vs node_b_b1-heath_lair_a1 | 175.5 m vs 183.3 m (4.3 %) |
| F2 | node_b_a1-heath_lair_b1 vs node_b_b2-heath_lair_a2 | 175.5 m vs 183.3 m (4.3 %) |
| F2 | mossmere_a1-heath_lair_b2 vs mossmere_a2-heath_lair_b1 | 122.2 m vs 117.0 m (4.3 %) |
| F2 | mossmere_a2-heath_lair_b1 vs mossmere_b2-heath_lair_a1 | 117.0 m vs 122.2 m (4.3 %) |
| F2 | node_b_a1-heath_lair_b1 vs node_b_b1-heath_lair_a1 | 175.5 m vs 183.3 m (4.3 %) |
| F2 | bristleback_a1-heath_lair_b1 vs bristleback_a2-heath_lair_b2 | 175.3 m vs 168.0 m (4.2 %) |
| F2 | bristleback_a2-millstone_cross_b2 vs bristleback_b2-millstone_cross_a2 | 169.3 m vs 176.6 m (4.2 %) |
| F2 | bristleback_a2-millstone_cross_b2 vs bristleback_b1-millstone_cross_a1 | 169.3 m vs 176.5 m (4.1 %) |
| F2 | peddler_a2-bridge_road_s vs peddler_b1-bridge_road_s | 133.5 m vs 128.1 m (4.1 %) |
| F2 | peddler_a1-bridge_road_n vs peddler_b1-bridge_road_s | 133.5 m vs 128.1 m (4.1 %) |
| F2 | millwatch_a1-heath_lair_b1 vs millwatch_b2-heath_lair_a2 | 139.8 m vs 134.1 m (4.0 %) |
| F2 | millwatch_a1-heath_lair_b1 vs millwatch_b1-heath_lair_a1 | 139.8 m vs 134.2 m (4.0 %) |
| F2 | node_b_a2-millstone_cross_b2 vs node_b_b1-millstone_cross_a1 | 169.2 m vs 176.2 m (4.0 %) |
| F2 | bristleback_a1-ford_n vs bristleback_a2-ford_s | 127.5 m vs 132.8 m (4.0 %) |
| F2 | bristleback_a1-ford_nest_a2 vs bristleback_a2-ford_nest_a1 | 127.5 m vs 132.8 m (4.0 %) |
| F2 | glade_vein_a1-mossmere_b2 vs glade_vein_b2-mossmere_a1 | 100.9 m vs 105.1 m (4.0 %) |
| F2 | node_b_a2-tavern_b2 vs node_b_b1-tavern_a1 | 114.1 m vs 118.8 m (4.0 %) |
| F2 | node_b_a2-millstone_cross_b2 vs node_b_b2-millstone_cross_a2 | 169.2 m vs 176.1 m (4.0 %) |
| F2 | node_b_a1-tavern_b1 vs node_b_b1-tavern_a1 | 114.1 m vs 118.8 m (3.9 %) |
| F2 | glade_vein_a1-mossmere_b2 vs glade_vein_a2-mossmere_b1 | 100.9 m vs 105.0 m (3.9 %) |
| F2 | node_b_a2-mouth_lair_b2 vs node_b_b2-mouth_lair_a2 | 171.0 m vs 164.3 m (3.9 %) |
| F2 | node_b_a1-mouth_lair_b1 vs node_b_b2-mouth_lair_a2 | 171.0 m vs 164.3 m (3.9 %) |
| F2 | bristleback_a1-mouth_lair_b1 vs bristleback_b2-mouth_lair_a2 | 171.1 m vs 178.0 m (3.9 %) |
| F2 | node_b_a2-mouth_lair_b2 vs node_b_b1-mouth_lair_a1 | 171.0 m vs 164.3 m (3.9 %) |
| F2 | bristleback_a2-mouth_lair_b2 vs bristleback_b2-mouth_lair_a2 | 171.1 m vs 178.0 m (3.9 %) |
| F2 | node_b_a1-mouth_lair_b1 vs node_b_b1-mouth_lair_a1 | 171.0 m vs 164.3 m (3.9 %) |
| F2 | bristleback_a1-mouth_lair_b1 vs bristleback_b1-mouth_lair_a1 | 171.1 m vs 177.9 m (3.9 %) |
| F2 | bristleback_a2-mouth_lair_b2 vs bristleback_b1-mouth_lair_a1 | 171.1 m vs 177.9 m (3.9 %) |
| F2 | millrace_a1-peddler_b1 vs millrace_a2-peddler_b2 | 101.4 m vs 97.5 m (3.8 %) |
| F2 | millrace_a1-peddler_b1 vs millrace_b2-peddler_a2 | 101.4 m vs 97.5 m (3.8 %) |
| F2 | mid_cache_a1-mouth_lair_b1 vs mid_cache_a1-mouth_lair_b2 | 97.6 m vs 93.9 m (3.8 %) |
| F2 | rich_b1-tavern_a1 vs rich_b2-tavern_a2 | 81.3 m vs 84.5 m (3.8 %) |
| F2 | mid_cache_a1-mouth_lair_b1 vs mid_cache_b1-mouth_lair_a2 | 97.6 m vs 93.9 m (3.8 %) |
| F2 | rich_a2-tavern_b2 vs rich_b2-tavern_a2 | 81.3 m vs 84.5 m (3.8 %) |
| F2 | rich_a1-tavern_b1 vs rich_b2-tavern_a2 | 81.3 m vs 84.5 m (3.7 %) |
| F2 | ford_nest_a1-peddler_b1 vs ford_nest_a2-peddler_b2 | 105.4 m vs 101.5 m (3.7 %) |
| F2 | bristleback_b1-peddler_a1 vs bristleback_b2-peddler_a2 | 158.3 m vs 152.4 m (3.7 %) |
| F2 | node_b_a1-millstone_cross_b1 vs node_b_a2-millstone_cross_b2 | 175.6 m vs 169.2 m (3.7 %) |
| F2 | mid_cache_a1-mouth_lair_b2 vs mid_cache_b1-mouth_lair_a1 | 93.9 m vs 97.4 m (3.6 %) |
| F2 | mid_cache_b1-mouth_lair_a1 vs mid_cache_b1-mouth_lair_a2 | 97.4 m vs 93.9 m (3.6 %) |
| F2 | bristleback_a1-millstone_cross_b1 vs bristleback_a2-millstone_cross_b2 | 175.5 m vs 169.3 m (3.6 %) |
| F2 | keep_t0-peddler_b1 vs keep_t3-peddler_b2 | 152.6 m vs 147.3 m (3.5 %) |
| F2 | millstone_cross_a1-heath_lair_b1 vs millstone_cross_b2-heath_lair_a2 | 166.0 m vs 160.1 m (3.5 %) |
| F2 | millrace_a2-bristleback_a1 vs millrace_b2-bristleback_b1 | 122.5 m vs 118.2 m (3.5 %) |
| F2 | millrace_b1-bristleback_b2 vs millrace_b2-bristleback_b1 | 122.5 m vs 118.2 m (3.5 %) |
| F2 | millstone_cross_a1-heath_lair_b1 vs millstone_cross_a2-heath_lair_b2 | 166.0 m vs 160.2 m (3.5 %) |
| F2 | millrace_a1-bristleback_a2 vs millrace_b2-bristleback_b1 | 122.5 m vs 118.2 m (3.5 %) |
| F2 | millstone_cross_b1-heath_lair_a1 vs millstone_cross_b2-heath_lair_a2 | 165.9 m vs 160.1 m (3.5 %) |
| F2 | millstone_cross_a2-heath_lair_b2 vs millstone_cross_b1-heath_lair_a1 | 160.2 m vs 165.9 m (3.5 %) |
| F2 | bristleback_a2-peddler_b2 vs bristleback_b2-peddler_a2 | 147.4 m vs 152.4 m (3.3 %) |
| F2 | millrace_a1-bristleback_b1 vs millrace_a2-bristleback_b2 | 133.0 m vs 128.7 m (3.3 %) |
| F2 | millrace_a1-bristleback_b1 vs millrace_b2-bristleback_a2 | 133.0 m vs 128.7 m (3.3 %) |
| F2 | peddler_a1-peddler_b1 vs peddler_b2-peddler_a2 | 120.2 m vs 116.3 m (3.2 %) |
| F2 | tavern_a2-bridge_crown_sw vs tavern_b1-bridge_crown_se | 24.5 m vs 25.3 m (3.1 %) |
| F2 | keep_t1-tavern_a1 vs keep_t4-tavern_a2 | 123.1 m vs 127.0 m (3.1 %) |
| F2 | mossmere_a2-heron_ford_b1 vs mossmere_b2-heron_ford_a1 | 110.3 m vs 113.7 m (3.0 %) |
| F2 | mossmere_b1-heron_ford_a2 vs mossmere_b2-heron_ford_a1 | 110.3 m vs 113.7 m (3.0 %) |
| F2 | millrace_a1-millstone_cross_b1 vs millrace_b1-millstone_cross_a1 | 125.5 m vs 121.8 m (3.0 %) |
| F2 | node_mid_a2-glade_vein_b1 vs node_mid_b2-glade_vein_a1 | 108.9 m vs 112.3 m (3.0 %) |
| F2 | ford_nest_a2-mouth_lair_a1 vs ford_nest_a2-mouth_lair_b2 | 121.3 m vs 125.1 m (3.0 %) |
| F2 | rich_a1-heath_lair_b1 vs rich_b2-heath_lair_a2 | 150.2 m vs 145.8 m (3.0 %) |
| F2 | mossmere_a1-heron_ford_b2 vs mossmere_b2-heron_ford_a1 | 110.4 m vs 113.7 m (3.0 %) |
| F2 | millstone_cross_a2-bridge_road_s vs millstone_cross_b2-bridge_road_n | 155.3 m vs 150.7 m (3.0 %) |
| F2 | rich_a1-heath_lair_b1 vs rich_b1-heath_lair_a1 | 150.2 m vs 145.8 m (3.0 %) |
| F2 | ford_nest_a1-mouth_lair_a2 vs ford_nest_a2-mouth_lair_b2 | 121.4 m vs 125.1 m (2.9 %) |
| F2 | node_mid_a1-glade_vein_b2 vs node_mid_b2-glade_vein_a1 | 109.0 m vs 112.3 m (2.9 %) |
| F2 | millstone_cross_a1-bridge_road_n vs millstone_cross_b2-bridge_road_n | 155.3 m vs 150.7 m (2.9 %) |
| F2 | bristleback_b1-tavern_a1 vs bristleback_b2-tavern_a2 | 111.5 m vs 114.7 m (2.8 %) |
| F2 | millstone_cross_a2-bridge_road_s vs millstone_cross_b1-bridge_road_s | 155.3 m vs 151.0 m (2.8 %) |
| F2 | millstone_cross_a1-bridge_road_n vs millstone_cross_b1-bridge_road_s | 155.3 m vs 151.0 m (2.7 %) |
| F2 | bristleback_a2-tavern_b2 vs bristleback_b2-tavern_a2 | 111.6 m vs 114.7 m (2.7 %) |
| F2 | node_b_a1-peddler_b1 vs node_b_a2-peddler_b2 | 151.5 m vs 147.4 m (2.7 %) |
| F2 | bristleback_a1-tavern_b1 vs bristleback_b2-tavern_a2 | 111.6 m vs 114.7 m (2.7 %) |
| F2 | node_b_b1-tavern_a1 vs node_b_b2-tavern_a2 | 118.8 m vs 122.0 m (2.7 %) |
| F2 | mossmere_a2-stag_glade_b1 vs mossmere_b1-stag_glade_a2 | 92.9 m vs 95.4 m (2.6 %) |
| F2 | tavern_a1-heron_ford_b2 vs tavern_b1-heron_ford_a2 | 102.3 m vs 105.0 m (2.6 %) |
| F2 | tavern_a1-heron_ford_b2 vs tavern_a2-heron_ford_b1 | 102.3 m vs 105.0 m (2.6 %) |
| F2 | mossmere_a1-stag_glade_b2 vs mossmere_b1-stag_glade_a2 | 93.0 m vs 95.4 m (2.6 %) |
| F2 | bristleback_a1-peddler_b1 vs bristleback_a2-peddler_b2 | 151.3 m vs 147.4 m (2.6 %) |
| F2 | node_a_b1-tavern_a1 vs node_a_b2-tavern_a2 | 125.6 m vs 128.9 m (2.5 %) |
| F2 | mossmere_a2-stag_glade_b1 vs mossmere_b2-stag_glade_a1 | 92.9 m vs 95.3 m (2.5 %) |
| F2 | tavern_a1-heron_ford_b2 vs tavern_b2-heron_ford_a1 | 102.3 m vs 104.9 m (2.5 %) |
| F2 | node_b_a1-bristleback_b1 vs node_b_a2-bristleback_b2 | 183.1 m vs 178.5 m (2.5 %) |
| F2 | mossmere_a1-stag_glade_b2 vs mossmere_b2-stag_glade_a1 | 93.0 m vs 95.3 m (2.5 %) |
| F2 | glade_vein_a1-mossmere_b2 vs glade_vein_b1-mossmere_a2 | 100.9 m vs 103.5 m (2.5 %) |
| F2 | bristleback_a1-bristleback_b1 vs bristleback_b2-bristleback_a2 | 183.0 m vs 178.6 m (2.4 %) |
| F2 | node_mid_a2-stag_glade_b1 vs node_mid_b2-stag_glade_a1 | 104.2 m vs 106.7 m (2.4 %) |
| F2 | node_mid_b1-stag_glade_a2 vs node_mid_b2-stag_glade_a1 | 104.2 m vs 106.7 m (2.4 %) |
| F2 | node_mid_a1-glade_vein_b2 vs node_mid_b1-glade_vein_a2 | 109.0 m vs 106.4 m (2.4 %) |
| F2 | node_mid_a1-stag_glade_b2 vs node_mid_b2-stag_glade_a1 | 104.2 m vs 106.7 m (2.3 %) |
| F2 | node_mid_a2-glade_vein_b1 vs node_mid_b1-glade_vein_a2 | 108.9 m vs 106.4 m (2.3 %) |
| F2 | peddler_a1-mouth_lair_a2 vs peddler_b2-mouth_lair_b1 | 134.3 m vs 131.4 m (2.1 %) |
| F2 | peddler_a2-mouth_lair_a1 vs peddler_b2-mouth_lair_b1 | 134.3 m vs 131.4 m (2.1 %) |
| F2 | peddler_b1-mouth_lair_b2 vs peddler_b2-mouth_lair_b1 | 134.3 m vs 131.4 m (2.1 %) |
| F2 | millrace_b1-millstone_cross_a1 vs millrace_b2-millstone_cross_a2 | 121.8 m vs 119.3 m (2.0 %) |
| F2 | millrace_a2-millstone_cross_b2 vs millrace_b1-millstone_cross_a1 | 119.3 m vs 121.8 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 95 sources) 130.20 s.
- Navmesh raster 2.35 s (235 polygons, 451584 cells of 0.25 m), spot / mirror checks 2.73 s, 4465 paths 1.07 s.
- Map Fourfold Hollow (2v2), scene res://docs/tools/world_forge/out/fourfold_hollow/preview.tscn, sim mode off; level load + navmesh bake 0.4 s (14 frames), lab 137.7 s. Spec: docs/design/map-2v2.md.
