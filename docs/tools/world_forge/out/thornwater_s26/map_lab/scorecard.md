# Map Lab: Thornwater (seed 26) scorecard: world_forge_thornwater_s26

2026-10-02 17:55 · lab v1.0 · 46.86 s · scanned 65 spots

## Result: **WARN** · score **98 / 100**

0 FAIL · 1 WARN · 17 PASS · 3 info checks; findings: 0 FAIL, 25 WARN, 80 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): nat_node-tower_a_twin vs nat_node_twin-tower_a: 58.1 m vs 42.4 m (26.9 %) -> units walk nat_node-tower_a_twin the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 954 / 1056 pairs within 2 % (0 FAIL, 25 WARN, 77 info))_
2. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_
3. **Combat heat from bot games** (IDEA): v2: feed Bot Lab / Replay Lab unit deaths into the heat map _(from lab idea)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 614 polygons, main area 13285 m² (92 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 65 / 65 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 2 / 2 clean, 3 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 89 spots ok, 1.0x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 65 / 65 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 65 / 65 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 1056 / 1056 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 954 / 1056 pairs within 2 % (0 FAIL, 25 WARN, 77 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | PASS 100 | 10 / 10 clean | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps (team maps) | INFO | no side has 2 seats (1v1): nothing to check |  |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 5 / 5 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | PASS 100 | 8 / 8 clean | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
| R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL |  |
| R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | own / nearest enemy path 0.9-1.1 (contested) or 1.1-1.45 (raidable): >= 5 per seat |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 8 / 8 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 5 / 5 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | PASS 100 | 57 / 57 clean | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (480 x 480 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | nat_node-tower_a_twin vs nat_node_twin-tower_a | 58.1 m vs 42.4 m (26.9 %) | units walk nat_node-tower_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-tower_b vs tower_a_twin-tower_b_twin | 84.9 m vs 104.5 m (18.7 %) | units walk tower_a_twin-tower_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-bridge_road_b vs cache_a_twin-bridge_road_a | 81.6 m vs 67.5 m (17.3 %) | units walk cache_a-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-lairs_n_two vs nat_node_twin-lairs_n_two_twin | 81.6 m vs 68.4 m (16.2 %) | units walk nat_node-lairs_n_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-bridge_road_a vs rich_hollow_twin-bridge_road_b | 46.1 m vs 40.3 m (12.6 %) | units walk rich_hollow-bridge_road_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_a-bridge_crown_a vs ford_b-bridge_crown_b | 57.2 m vs 51.1 m (10.6 %) | units walk ford_a-bridge_crown_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-bridge_crown_b vs ford_nest_twin-bridge_crown_a | 51.1 m vs 57.2 m (10.6 %) | units walk ford_nest_twin-bridge_crown_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-inn_peddler_twin vs ford_nest_twin-inn_peddler | 35.7 m vs 39.5 m (9.8 %) | units walk ford_nest_twin-inn_peddler the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-post_b_twin vs rich_hollow_twin-post_b | 59.8 m vs 54.4 m (9.1 %) | units walk rich_hollow-post_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-cache_a_twin vs ford_nest_twin-cache_a | 46.1 m vs 50.6 m (8.7 %) | units walk ford_nest_twin-cache_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-inn_peddler_twin vs rich_hollow_twin-inn_peddler | 113.2 m vs 103.6 m (8.5 %) | units walk rich_hollow-inn_peddler_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-lairs_w_one_twin vs nat_node_twin-lairs_w_one | 62.0 m vs 67.4 m (8.0 %) | units walk nat_node_twin-lairs_w_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-lairs_n_one_twin vs cache_a_twin-lairs_n_one | 90.9 m vs 98.2 m (7.5 %) | units walk cache_a_twin-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-lairs_n_two_twin vs cache_a_twin-lairs_n_two | 89.5 m vs 96.5 m (7.2 %) | units walk cache_a_twin-lairs_n_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-wallow_twin vs rich_hollow_twin-wallow | 76.9 m vs 71.4 m (7.1 %) | units walk rich_hollow-wallow_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-cache_a_twin vs post_b_twin-cache_a | 63.5 m vs 68.2 m (6.8 %) | units walk post_b_twin-cache_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-lairs_w_two_twin vs rich_hollow_twin-lairs_w_two | 142.8 m vs 133.1 m (6.8 %) | units walk rich_hollow-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-cache_b_twin vs ford_nest_twin-cache_b | 71.8 m vs 76.8 m (6.5 %) | units walk ford_nest_twin-cache_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-post_a_twin vs nat_node_twin-post_a | 68.7 m vs 73.5 m (6.5 %) | units walk nat_node_twin-post_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-inn_peddler_twin vs home_b_twin-inn_peddler | 73.3 m vs 78.2 m (6.3 %) | units walk home_b_twin-inn_peddler the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-shrine_twin vs home_b_twin-shrine | 75.4 m vs 80.2 m (6.0 %) | units walk home_b_twin-shrine the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-inn_peddler_twin vs stag_twin-inn_peddler | 67.9 m vs 64.1 m (5.7 %) | units walk stag-inn_peddler_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-steps_b vs shrine_twin-steps_a | 40.7 m vs 38.4 m (5.6 %) | units walk shrine-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-lairs_w_one_twin vs home_a_twin-lairs_w_one | 100.7 m vs 106.2 m (5.1 %) | units walk home_a_twin-lairs_w_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-inn_tavern_twin vs stag_twin-inn_tavern | 64.7 m vs 61.4 m (5.1 %) | units walk stag-inn_tavern_twin the long way: the engine's polygon path, not the map (see F1) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-45.0, 41.3) | (-41.4, 40.4) | keep_t1 | (-41.4, 40.4) | 0.0 |
| keep_t1 | keep | (45.0, -41.3) | (41.4, -40.4) | keep_t0 | (41.4, -40.4) | 0.0 |
| home_a | home_node | (-47.6, 32.2) | (-47.4, 32.1) | home_a_twin | (-47.4, 32.1) | 0.0 |
| home_a_twin | home_node | (47.6, -32.2) | (47.4, -32.1) | home_a | (47.4, -32.1) | 0.0 |
| home_b | home_node | (-36.1, 44.7) | (-36.1, 44.6) | home_b_twin | (-36.1, 44.6) | 0.0 |
| home_b_twin | home_node | (36.1, -44.7) | (36.1, -44.6) | home_b | (36.1, -44.6) | 0.0 |
| nat_node | expansion | (-4.5, 15.5) | (-4.4, 15.4) | nat_node_twin | (-4.4, 15.4) | 0.0 |
| nat_node_twin | expansion | (4.5, -15.5) | (4.4, -15.4) | nat_node | (4.4, -15.4) | 0.0 |
| rich_node | expansion | (-38.6, -41.7) | (-38.4, -41.6) | rich_node_twin | (-38.4, -41.6) | 0.0 |
| rich_node_twin | expansion | (38.6, 41.7) | (38.4, 41.6) | rich_node | (38.4, 41.6) | 0.0 |
| third_node | expansion | (9.1, 56.1) | (9.1, 55.9) | third_node_twin | (9.1, 55.9) | 0.0 |
| third_node_twin | expansion | (-9.1, -56.1) | (-9.1, -55.9) | third_node | (-9.1, -55.9) | 0.0 |
| tower_a | point | (-21.8, -41.5) | (-21.6, -41.4) | tower_a_twin | (-21.6, -41.4) | 0.0 |
| tower_a_twin | point | (21.8, 41.5) | (21.6, 41.4) | tower_a | (21.6, 41.4) | 0.0 |
| tower_b | point | (-4.0, 39.7) | (-3.9, 39.6) | tower_b_twin | (-3.9, 39.6) | 0.0 |
| tower_b_twin | point | (4.0, -39.7) | (3.9, -39.6) | tower_b | (3.9, -39.6) | 0.0 |
| well | point | (-26.3, -24.1) | (-26.1, -24.1) | well_twin | (-26.1, -24.1) | 0.0 |
| well_twin | point | (26.3, 24.1) | (26.1, 24.1) | well | (26.1, 24.1) | 0.0 |
| shrine | point | (-22.3, -5.4) | (-22.1, -5.4) | shrine_twin | (-22.1, -5.4) | 0.0 |
| shrine_twin | point | (22.3, 5.4) | (22.1, 5.4) | shrine | (22.1, 5.4) | 0.0 |
| rich_hollow | camp | (-52.4, -57.8) | (-52.4, -57.6) | rich_hollow_twin | (-52.4, -57.6) | 0.0 |
| rich_hollow_twin | camp | (52.4, 57.8) | (52.4, 57.6) | rich_hollow | (52.4, 57.6) | 0.0 |
| wallow | camp | (-18.3, 55.5) | (-18.1, 55.4) | wallow_twin | (-18.1, 55.4) | 0.0 |
| wallow_twin | camp | (18.3, -55.5) | (18.1, -55.4) | wallow | (18.1, -55.4) | 0.0 |
| ford_nest | camp | (7.5, 39.9) | (7.4, 39.9) | ford_nest_twin | (7.4, 39.9) | 0.0 |
| ford_nest_twin | camp | (-7.5, -39.9) | (-7.4, -39.9) | ford_nest | (-7.4, -39.9) | 0.0 |
| stag | camp | (-35.5, -14.4) | (-35.4, -14.4) | stag_twin | (-35.4, -14.4) | 0.0 |
| stag_twin | camp | (35.5, 14.4) | (35.4, 14.4) | stag | (35.4, 14.4) | 0.0 |
| inn_tavern | tavern | (-14.8, -15.2) | (-14.6, -15.1) | inn_tavern_twin | (-14.6, -15.1) | 0.0 |
| inn_tavern_twin | tavern | (14.8, 15.2) | (14.6, 15.1) | inn_tavern | (14.6, 15.1) | 0.0 |
| post_a | post | (-53.3, -0.3) | (-53.1, -0.1) | post_a_twin | (-53.1, -0.1) | 0.0 |
| post_a_twin | post | (53.3, 0.3) | (53.1, 0.1) | post_a | (53.1, 0.1) | 0.0 |
| post_b | post | (-1.3, 53.7) | (-1.1, 53.6) | post_b_twin | (-1.1, 53.6) | 0.0 |
| post_b_twin | post | (1.3, -53.7) | (1.1, -53.6) | post_b | (1.1, -53.6) | 0.0 |
| rich_den | guild | (-52.1, -48.8) | (-52.1, -48.6) | rich_den_twin | (-52.1, -48.6) | 0.0 |
| rich_den_twin | guild | (52.1, 48.8) | (52.1, 48.6) | rich_den | (52.1, 48.6) | 0.0 |
| rich_lodge | guild | (-43.5, -56.1) | (-43.4, -56.1) | rich_lodge_twin | (-43.4, -56.1) | 0.0 |
| rich_lodge_twin | guild | (43.5, 56.1) | (43.4, 56.1) | rich_lodge | (43.4, 56.1) | 0.0 |
| guilds_den | guild | (-52.5, -46.9) | (-52.4, -46.9) | guilds_den_twin | (-52.4, -46.9) | 0.0 |
| guilds_den_twin | guild | (52.5, 46.9) | (52.4, 46.9) | guilds_den | (52.4, 46.9) | 0.0 |
| guilds_lodge | guild | (-43.7, -55.1) | (-43.6, -55.1) | guilds_lodge_twin | (-43.6, -55.1) | 0.0 |
| guilds_lodge_twin | guild | (43.7, 55.1) | (43.6, 55.1) | guilds_lodge | (43.6, 55.1) | 0.0 |
| inn_peddler | peddler | (-20.6, -6.9) | (-20.4, -6.9) | inn_peddler_twin | (-20.4, -6.9) | 0.0 |
| inn_peddler_twin | peddler | (20.6, 6.9) | (20.4, 6.9) | inn_peddler | (20.4, 6.9) | 0.0 |
| cache_a | cache | (-31.7, -0.8) | (-31.6, -0.6) | cache_a_twin | (-31.6, -0.6) | 0.0 |
| cache_a_twin | cache | (31.7, 0.8) | (31.6, 0.6) | cache_a | (31.6, 0.6) | 0.0 |
| cache_b | cache | (-8.1, 29.4) | (-7.9, 29.4) | cache_b_twin | (-7.9, 29.4) | 0.0 |
| cache_b_twin | cache | (8.1, -29.4) | (7.9, -29.4) | cache_b | (7.9, -29.4) | 0.0 |
| lairs_w_one | lair | (-46.4, 0.1) | (-46.1, 0.1) | lairs_w_one_twin | (-46.1, 0.1) | 0.0 |
| lairs_w_one_twin | lair | (46.4, -0.1) | (46.1, -0.1) | lairs_w_one | (46.1, -0.1) | 0.0 |
| lairs_w_two | lair | (-59.6, -12.1) | (-59.6, -11.9) | lairs_w_two_twin | (-59.6, -11.9) | 0.0 |
| lairs_w_two_twin | lair | (59.6, 12.1) | (59.6, 11.9) | lairs_w_two | (59.6, 11.9) | 0.0 |
| lairs_n_one | lair | (-34.0, -51.8) | (-34.1, -51.6) | lairs_n_one_twin | (-34.1, -51.6) | 0.0 |
| lairs_n_one_twin | lair | (34.0, 51.8) | (34.1, 51.6) | lairs_n_one | (34.1, 51.6) | 0.0 |
| lairs_n_two | lair | (-46.2, -38.6) | (-46.1, -38.4) | lairs_n_two_twin | (-46.1, -38.4) | 0.0 |
| lairs_n_two_twin | lair | (46.2, 38.6) | (46.1, 38.4) | lairs_n_two | (46.1, 38.4) | 0.0 |
| bridge_road_a | crossing_bridge_road | (-13.3, -48.7) | (-13.1, -48.6) | bridge_road_b | (-13.1, -48.6) | 0.0 |
| bridge_road_b | crossing_bridge_road | (13.3, 48.7) | (13.1, 48.6) | bridge_road_a | (13.1, 48.6) | 0.0 |
| ford_a | crossing_ford | (-7.5, -39.9) | (-7.4, -39.9) | ford_b | (-7.4, -39.9) | 0.0 |
| ford_b | crossing_ford | (7.5, 39.9) | (7.4, 39.9) | ford_a | (7.4, 39.9) | 0.0 |
| bridge_crown_a | crossing_bridge_lane | (-9.4, 8.6) | (-9.4, 8.4) | bridge_crown_b | (-9.4, 8.4) | 0.0 |
| bridge_crown_b | crossing_bridge_lane | (9.4, -8.6) | (9.4, -8.4) | bridge_crown_a | (9.4, -8.4) | 0.0 |
| steps_a | crossing_steps | (-8.6, -9.4) | (-8.4, -9.4) | steps_b | (-8.4, -9.4) | 0.0 |
| steps_b | crossing_steps | (8.6, 9.4) | (8.4, 9.4) | steps_a | (8.4, 9.4) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, -0.1) | 0.4 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 102)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | nat_node - tower_a_twin | 58.1 | nat_node_twin - tower_a | 42.4 | +26.9 % |
| 2 | tower_a - tower_b | 84.9 | tower_a_twin - tower_b_twin | 104.5 | -18.7 % |
| 3 | cache_a - bridge_road_b | 81.6 | cache_a_twin - bridge_road_a | 67.5 | +17.3 % |
| 4 | nat_node - lairs_n_two | 81.6 | nat_node_twin - lairs_n_two_twin | 68.4 | +16.2 % |
| 5 | rich_hollow - bridge_road_a | 46.1 | rich_hollow_twin - bridge_road_b | 40.3 | +12.6 % |
| 6 | ford_a - bridge_crown_a | 57.2 | ford_b - bridge_crown_b | 51.1 | +10.6 % |
| 7 | ford_nest - bridge_crown_b | 51.1 | ford_nest_twin - bridge_crown_a | 57.2 | -10.6 % |
| 8 | ford_nest - inn_peddler_twin | 35.7 | ford_nest_twin - inn_peddler | 39.5 | -9.8 % |
| 9 | rich_hollow - post_b_twin | 59.8 | rich_hollow_twin - post_b | 54.4 | +9.1 % |
| 10 | ford_nest - cache_a_twin | 46.1 | ford_nest_twin - cache_a | 50.6 | -8.7 % |
| 11 | rich_hollow - inn_peddler_twin | 113.2 | rich_hollow_twin - inn_peddler | 103.6 | +8.5 % |
| 12 | bridge_crown_a - steps_b | 17.8 | bridge_crown_b - steps_a | 19.5 | -8.5 % |
| 13 | nat_node - lairs_w_one_twin | 62.0 | nat_node_twin - lairs_w_one | 67.4 | -8.0 % |
| 14 | cache_a - lairs_n_one_twin | 90.9 | cache_a_twin - lairs_n_one | 98.2 | -7.5 % |
| 15 | cache_a - lairs_n_two_twin | 89.5 | cache_a_twin - lairs_n_two | 96.5 | -7.2 % |
| 16 | rich_hollow - wallow_twin | 76.9 | rich_hollow_twin - wallow | 71.4 | +7.1 % |
| 17 | post_b - cache_a_twin | 63.5 | post_b_twin - cache_a | 68.2 | -6.8 % |
| 18 | rich_hollow - lairs_w_two_twin | 142.8 | rich_hollow_twin - lairs_w_two | 133.1 | +6.8 % |
| 19 | nat_node - steps_b | 23.1 | nat_node_twin - steps_a | 24.8 | -6.7 % |
| 20 | ford_nest - cache_b_twin | 71.8 | ford_nest_twin - cache_b | 76.8 | -6.5 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 44.7 (nat_node) | 37.5 (tower_b) | 27.7 (wallow) | 40.5 (lairs_w_one) | 63.0 (inn_tavern) | 42.3 (post_a) | 54.7 (inn_peddler) | 35.3 (cache_b) | 57.8 (crown) | 115.6 |
| north-east | 44.7 (nat_node_twin) | 37.5 (tower_b_twin) | 27.7 (wallow_twin) | 40.7 (lairs_w_one_twin) | 63.0 (inn_tavern_twin) | 42.3 (post_a_twin) | 54.7 (inn_peddler_twin) | 35.3 (cache_b_twin) | 57.8 (crown) | 115.6 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| home_b | home_node | 6.8 | home_b_twin | 6.8 | +0.0 % |
| home_a | home_node | 10.8 | home_a_twin | 10.7 | +0.5 % |
| wallow | camp | 27.7 | wallow_twin | 27.7 | +0.0 % |
| cache_b | cache | 35.3 | cache_b_twin | 35.3 | +0.0 % |
| tower_b | point | 37.5 | tower_b_twin | 37.5 | +0.0 % |
| lairs_w_one | lair | 40.5 | lairs_w_one_twin | 40.7 | -0.4 % |
| cache_a | cache | 42.1 | cache_a_twin | 42.1 | -0.0 % |
| post_a | post | 42.3 | post_a_twin | 42.3 | -0.2 % |
| post_b | post | 42.4 | post_b_twin | 42.4 | -0.0 % |
| nat_node | expansion | 44.7 | nat_node_twin | 44.7 | +0.0 % |
| bridge_crown_a | crossing_bridge_lane | 45.3 | bridge_crown_b | 45.3 | +0.0 % |
| ford_b | crossing_ford | 48.8 | ford_a | 48.8 | +0.0 % |
| ford_nest | camp | 48.8 | ford_nest_twin | 48.8 | +0.0 % |
| shrine | point | 49.6 | shrine_twin | 49.6 | +0.0 % |
| third_node | expansion | 52.8 | third_node_twin | 52.8 | -0.0 % |
| inn_peddler | peddler | 54.7 | inn_peddler_twin | 54.7 | +0.0 % |
| bridge_road_b | crossing_bridge_road | 55.1 | bridge_road_a | 55.1 | +0.0 % |
| lairs_w_two | lair | 55.5 | lairs_w_two_twin | 55.5 | -0.1 % |
| stag | camp | 55.7 | stag_twin | 55.9 | -0.3 % |
| crown | crown | 57.8 | crown | 57.8 | -0.0 % |
| steps_a | crossing_steps | 61.4 | steps_b | 61.5 | -0.1 % |
| steps_b | crossing_steps | 61.7 | steps_a | 63.6 | -2.9 % |
| inn_tavern | tavern | 63.0 | inn_tavern_twin | 63.0 | +0.0 % |
| tower_a_twin | point | 63.0 | tower_a | 63.0 | -0.0 % |
| well | point | 68.2 | well_twin | 68.4 | -0.3 % |
| inn_tavern_twin | tavern | 69.9 | inn_tavern | 72.0 | -3.0 % |
| bridge_crown_b | crossing_bridge_lane | 70.4 | bridge_crown_a | 70.4 | +0.0 % |
| well_twin | point | 72.6 | well | 72.6 | +0.1 % |
| inn_peddler_twin | peddler | 73.9 | inn_peddler | 75.2 | -1.7 % |
| shrine_twin | point | 76.0 | shrine | 77.3 | -1.7 % |
| nat_node_twin | expansion | 77.0 | nat_node | 77.1 | -0.1 % |
| lairs_n_one_twin | lair | 78.0 | lairs_n_one | 78.0 | -0.0 % |
| lairs_n_two | lair | 78.9 | lairs_n_two_twin | 79.1 | -0.2 % |
| rich_node_twin | expansion | 79.8 | rich_node | 79.8 | -0.0 % |
| rich_node | expansion | 82.2 | rich_node_twin | 82.4 | -0.2 % |
| stag_twin | camp | 85.7 | stag | 85.6 | +0.1 % |
| tower_a | point | 85.8 | tower_a_twin | 86.0 | -0.2 % |
| cache_a_twin | cache | 86.6 | cache_a | 87.9 | -1.5 % |
| lairs_n_two_twin | lair | 87.5 | lairs_n_two | 87.5 | +0.0 % |
| guilds_den | guild | 87.9 | guilds_den_twin | 88.1 | -0.2 % |
| guilds_lodge_twin | guild | 88.1 | guilds_lodge | 88.1 | -0.0 % |
| rich_lodge_twin | guild | 88.3 | rich_lodge | 88.3 | -0.0 % |
| cache_b_twin | cache | 89.3 | cache_b | 89.3 | -0.0 % |
| rich_den | guild | 89.7 | rich_den_twin | 89.8 | -0.2 % |
| ford_a | crossing_ford | 90.3 | ford_b | 89.3 | +1.0 % |
| ford_nest_twin | camp | 90.3 | ford_nest | 89.3 | +1.0 % |
| lairs_n_one | lair | 92.5 | lairs_n_one_twin | 92.7 | -0.2 % |
| guilds_den_twin | guild | 94.2 | guilds_den | 94.2 | -0.0 % |
| rich_den_twin | guild | 94.2 | rich_den | 94.3 | -0.0 % |
| guilds_lodge | guild | 95.5 | guilds_lodge_twin | 95.7 | -0.2 % |
| rich_lodge | guild | 96.5 | rich_lodge_twin | 96.7 | -0.2 % |
| bridge_road_a | crossing_bridge_road | 96.8 | bridge_road_b | 96.8 | +0.0 % |
| rich_hollow_twin | camp | 97.1 | rich_hollow | 97.1 | -0.0 % |
| rich_hollow | camp | 98.6 | rich_hollow_twin | 98.8 | -0.2 % |
| tower_b_twin | point | 100.6 | tower_b | 99.3 | +1.3 % |
| lairs_w_one_twin | lair | 103.3 | lairs_w_one | 103.3 | +0.1 % |
| third_node_twin | expansion | 105.3 | third_node | 105.3 | +0.0 % |
| post_b_twin | post | 106.1 | post_b | 106.1 | +0.1 % |
| lairs_w_two_twin | lair | 108.2 | lairs_w_two | 108.2 | +0.1 % |
| post_a_twin | post | 108.5 | post_a | 108.4 | +0.1 % |
| home_a_twin | home_node | 114.8 | home_a | 114.8 | -0.0 % |
| home_b_twin | home_node | 115.1 | home_b | 115.1 | +0.0 % |
| keep_t1 | keep | 115.6 | keep_t0 | 115.6 | +0.0 % |
| wallow_twin | camp | 120.1 | wallow | 120.0 | +0.1 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| south-west | enemy keep (keep_t1) | 115.6 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| south-west | nearest expansion (nat_node) | 44.7 | 0.0 | 0:10 | 0:09 | 0:06 | 0:11 |
| south-west | nearest point (tower_b) | 37.5 | 0.0 | 0:08 | 0:08 | 0:05 | 0:09 |
| south-west | nearest camp (wallow) | 27.7 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| south-west | crown (crown) | 57.8 | 0.0 | 0:13 | 0:12 | 0:08 | 0:14 |
| north-east | enemy keep (keep_t0) | 115.6 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| north-east | nearest expansion (nat_node_twin) | 44.7 | 0.0 | 0:10 | 0:09 | 0:06 | 0:11 |
| north-east | nearest point (tower_b_twin) | 37.5 | 0.0 | 0:08 | 0:08 | 0:05 | 0:09 |
| north-east | nearest camp (wallow_twin) | 27.7 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| north-east | crown (crown) | 57.8 | 0.0 | 0:13 | 0:12 | 0:08 | 0:14 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_a | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_b | 4.8 |
| bridge_road_b | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_a | 4.8 |
| ford_a | ford | 7.0 | 6.3 | 7.3 | ford_b | 6.0 |
| ford_b | ford | 7.0 | 6.0 | 7.0 | ford_a | 6.3 |
| bridge_crown_a | bridge_lane | 8.0 | 6.0 | 7.0 | bridge_crown_b | 6.0 |
| bridge_crown_b | bridge_lane | 8.0 | 6.0 | 7.0 | bridge_crown_a | 6.0 |
| steps_a | steps | 6.0 | 3.9 | 4.9 | steps_b | 4.3 |
| steps_b | steps | 6.0 | 4.3 | 5.3 | steps_a | 3.9 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 57.8 | 4.9 | (-7.6, 7.7) | - |
| keep_t0 -> keep_t1 | 115.6 | 5.0 | (-7.7, 7.5) | - |
| keep_t0 -> nat_node | 44.7 | 35.3 | (-9.9, 19.1) | - |
| keep_t1 -> crown | 57.8 | 5.0 | (7.8, -7.4) | - |
| keep_t1 -> nat_node_twin | 44.7 | 35.3 | (9.9, -19.1) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| south-west | keep_enemy | 116.00-150.00 | 115.62 | 0.3 % |
| south-west | natural | 38.00-58.00 | 44.65 | - |
| south-west | rich | 65.00-95.00 | 82.16 | - |
| south-west | crown | 50.00-72.00 | 57.81 | - |
| north-east | keep_enemy | 116.00-150.00 | 115.62 | 0.3 % |
| north-east | natural | 38.00-58.00 | 44.65 | - |
| north-east | rich | 65.00-95.00 | 82.36 | - |
| north-east | crown | 50.00-72.00 | 57.81 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |
| north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| south-west | 7 | 2 | 11 | 29 |
| north-east | 8 | 2 | 10 | 29 |


## Hottest metres (every spot-pair shortest path, 2080 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (5.5, 8.5) | 249 | 12 % |
| 2 | (0.5, 0.5) | 208 | 10 % |
| 3 | (-4.5, -6.5) | 207 | 10 % |
| 4 | (-5.5, 8.5) | 168 | 8 % |
| 5 | (7.5, 39.5) | 150 | 7 % |
| 6 | (-7.5, -39.5) | 143 | 7 % |
| 7 | (-10.5, -16.5) | 136 | 7 % |
| 8 | (-19.5, 6.5) | 125 | 6 % |
| 9 | (13.5, 23.5) | 116 | 6 % |
| 10 | (43.5, 55.5) | 114 | 5 % |


## Info findings (80)
| Check | Where | What |
|---|---|---|
| N3 | island 4 at (45.1, -41.1) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 26 at (-44.9, 41.4) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 26 islands on top of colliders (460 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | bridge_crown_a-steps_b vs bridge_crown_b-steps_a | 17.8 m vs 19.5 m (8.5 %) |
| F2 | nat_node-steps_b vs nat_node_twin-steps_a | 23.1 m vs 24.8 m (6.7 %) |
| F2 | tower_a-tower_b_twin vs tower_a_twin-tower_b | 27.2 m vs 25.6 m (6.1 %) |
| F2 | nat_node-inn_tavern_twin vs nat_node_twin-inn_tavern | 31.2 m vs 33.2 m (5.9 %) |
| F2 | lairs_w_two-lairs_n_two vs lairs_w_two_twin-lairs_n_two_twin | 31.6 m vs 29.7 m (5.9 %) |
| F2 | home_b-tower_a vs home_b_twin-tower_a_twin | 91.7 m vs 87.2 m (4.9 %) |
| F2 | wallow-post_a vs wallow_twin-post_a_twin | 65.6 m vs 69.0 m (4.9 %) |
| F2 | cache_b-steps_b vs cache_b_twin-steps_a | 35.4 m vs 37.1 m (4.6 %) |
| F2 | rich_hollow-lairs_w_one_twin vs rich_hollow_twin-lairs_w_one | 123.0 m vs 117.4 m (4.5 %) |
| F2 | bridge_road_a-steps_a vs bridge_road_b-steps_b | 42.4 m vs 40.5 m (4.5 %) |
| F2 | rich_hollow-post_a_twin vs rich_hollow_twin-post_a | 128.7 m vs 123.2 m (4.3 %) |
| F2 | home_a-post_a_twin vs home_a_twin-post_a | 107.5 m vs 112.3 m (4.3 %) |
| F2 | post_a-lairs_w_one_twin vs post_a_twin-lairs_w_one | 101.2 m vs 105.6 m (4.2 %) |
| F2 | post_b-inn_peddler_twin vs post_b_twin-inn_peddler | 54.8 m vs 57.2 m (4.2 %) |
| F2 | nat_node-well_twin vs nat_node_twin-well | 45.8 m vs 47.8 m (4.1 %) |
| F2 | nat_node-stag_twin vs nat_node_twin-stag | 50.6 m vs 52.7 m (4.0 %) |
| F2 | shrine-inn_tavern_twin vs shrine_twin-inn_tavern | 48.8 m vs 50.8 m (4.0 %) |
| F2 | home_b-cache_a_twin vs home_b_twin-cache_a | 86.0 m vs 89.4 m (3.9 %) |
| F2 | rich_lodge-bridge_crown_b vs rich_lodge_twin-bridge_crown_a | 79.0 m vs 76.3 m (3.5 %) |
| F2 | tower_a-cache_b_twin vs tower_a_twin-cache_b | 33.8 m vs 32.7 m (3.5 %) |
| F2 | inn_tavern-ford_a vs inn_tavern_twin-ford_b | 27.3 m vs 26.3 m (3.4 %) |
| F2 | stag-lairs_n_two_twin vs stag_twin-lairs_n_two | 103.8 m vs 100.4 m (3.3 %) |
| F2 | rich_lodge-cache_b_twin vs rich_lodge_twin-cache_b | 60.1 m vs 58.1 m (3.2 %) |
| F2 | nat_node-inn_peddler_twin vs nat_node_twin-inn_peddler | 35.3 m vs 36.4 m (3.2 %) |
| F2 | guilds_lodge-inn_peddler_twin vs guilds_lodge_twin-inn_peddler | 97.5 m vs 94.6 m (3.0 %) |
| F2 | nat_node-post_a vs nat_node_twin-post_a_twin | 51.2 m vs 52.7 m (3.0 %) |
| F2 | nat_node-shrine_twin vs nat_node_twin-shrine | 37.4 m vs 38.5 m (3.0 %) |
| F2 | guilds_lodge-cache_b_twin vs guilds_lodge_twin-cache_b | 59.7 m vs 57.9 m (3.0 %) |
| F2 | keep_t0-inn_tavern_twin vs keep_t1-inn_tavern | 69.9 m vs 72.0 m (3.0 %) |
| F2 | stag-steps_b vs stag_twin-steps_a | 54.5 m vs 52.9 m (2.9 %) |
| F2 | nat_node-rich_node_twin vs nat_node_twin-rich_node | 66.6 m vs 68.6 m (2.9 %) |
| F2 | stag-guilds_den_twin vs stag_twin-guilds_den | 114.0 m vs 110.7 m (2.9 %) |
| F2 | home_b-steps_b vs home_b_twin-steps_a | 61.1 m vs 63.0 m (2.9 %) |
| F2 | nat_node-lairs_w_one vs nat_node_twin-lairs_w_one_twin | 44.4 m vs 45.8 m (2.9 %) |
| F2 | keep_t0-steps_b vs keep_t1-steps_a | 61.7 m vs 63.6 m (2.9 %) |
| F2 | stag-rich_den_twin vs stag_twin-rich_den | 114.9 m vs 111.6 m (2.9 %) |
| F2 | home_a-inn_tavern_twin vs home_a_twin-inn_tavern | 70.0 m vs 72.0 m (2.8 %) |
| F2 | guilds_lodge-cache_a_twin vs guilds_lodge_twin-cache_a | 98.7 m vs 95.9 m (2.8 %) |
| F2 | stag-crown vs stag_twin-crown | 39.0 m vs 40.2 m (2.8 %) |
| F2 | wallow-cache_a_twin vs wallow_twin-cache_a | 78.1 m vs 80.4 m (2.8 %) |
| F2 | nat_node-lairs_n_two_twin vs nat_node_twin-lairs_n_two | 70.4 m vs 72.4 m (2.7 %) |
| F2 | nat_node-lairs_n_one_twin vs nat_node_twin-lairs_n_one | 71.7 m vs 73.8 m (2.7 %) |
| F2 | home_a-steps_b vs home_a_twin-steps_a | 61.8 m vs 63.6 m (2.7 %) |
| F2 | inn_peddler-cache_b_twin vs inn_peddler_twin-cache_b | 48.9 m vs 47.5 m (2.7 %) |
| F2 | wallow-steps_b vs wallow_twin-steps_a | 62.6 m vs 64.3 m (2.6 %) |
| F2 | ford_nest-lairs_w_two_twin vs ford_nest_twin-lairs_w_two | 60.9 m vs 59.3 m (2.6 %) |
| F2 | rich_lodge-cache_a_twin vs rich_lodge_twin-cache_a | 98.6 m vs 96.1 m (2.6 %) |
| F2 | shrine-cache_b_twin vs shrine_twin-cache_b | 50.9 m vs 49.6 m (2.5 %) |
| F2 | guilds_den-inn_peddler_twin vs guilds_den_twin-inn_peddler | 98.5 m vs 101.0 m (2.5 %) |
| F2 | nat_node-guilds_lodge_twin vs nat_node_twin-guilds_lodge | 80.2 m vs 82.2 m (2.4 %) |
| F2 | nat_node-rich_lodge_twin vs nat_node_twin-rich_lodge | 80.8 m vs 82.8 m (2.4 %) |
| F2 | nat_node-guilds_den_twin vs nat_node_twin-guilds_den | 80.5 m vs 82.5 m (2.4 %) |
| F2 | stag-bridge_crown_b vs stag_twin-bridge_crown_a | 47.0 m vs 45.8 m (2.4 %) |
| F2 | nat_node-rich_den_twin vs nat_node_twin-rich_den | 81.5 m vs 83.5 m (2.4 %) |
| F2 | rich_den-inn_peddler_twin vs rich_den_twin-inn_peddler | 98.9 m vs 101.3 m (2.4 %) |
| F2 | home_a-stag_twin vs home_a_twin-stag | 89.3 m vs 91.5 m (2.4 %) |
| F2 | nat_node-cache_a_twin vs nat_node_twin-cache_a | 48.0 m vs 49.1 m (2.3 %) |
| F2 | third_node-inn_tavern_twin vs third_node_twin-inn_tavern | 42.5 m vs 43.5 m (2.3 %) |
| F2 | shrine-lairs_n_two_twin vs shrine_twin-lairs_n_two | 87.9 m vs 89.9 m (2.3 %) |
| F2 | shrine-lairs_n_one_twin vs shrine_twin-lairs_n_one | 89.3 m vs 91.3 m (2.3 %) |
| F2 | guilds_lodge-bridge_crown_b vs guilds_lodge_twin-bridge_crown_a | 77.8 m vs 76.1 m (2.3 %) |
| F2 | post_b-lairs_w_one_twin vs post_b_twin-lairs_w_one | 71.7 m vs 73.3 m (2.3 %) |
| F2 | shrine-inn_peddler_twin vs shrine_twin-inn_peddler | 52.8 m vs 54.0 m (2.2 %) |
| F2 | inn_peddler-ford_a vs inn_peddler_twin-ford_b | 36.5 m vs 35.7 m (2.2 %) |
| F2 | nat_node-rich_hollow_twin vs nat_node_twin-rich_hollow | 87.8 m vs 89.9 m (2.2 %) |
| F2 | tower_a-bridge_crown_b vs tower_a_twin-bridge_crown_a | 52.0 m vs 50.8 m (2.2 %) |
| F2 | cache_a-lairs_w_two_twin vs cache_a_twin-lairs_w_two | 94.6 m vs 96.7 m (2.2 %) |
| F2 | nat_node-lairs_w_two_twin vs nat_node_twin-lairs_w_two | 75.5 m vs 77.2 m (2.2 %) |
| F2 | cache_a-cache_b_twin vs cache_a_twin-cache_b | 61.5 m vs 60.2 m (2.1 %) |
| F2 | shrine-guilds_lodge_twin vs shrine_twin-guilds_lodge | 97.7 m vs 99.8 m (2.1 %) |
| F2 | nat_node-guilds_den vs nat_node_twin-guilds_den_twin | 80.6 m vs 78.9 m (2.1 %) |
| F2 | shrine-rich_lodge_twin vs shrine_twin-rich_lodge | 98.3 m vs 100.4 m (2.1 %) |
| F2 | home_b-rich_node vs home_b_twin-rich_node_twin | 88.1 m vs 86.3 m (2.1 %) |
| F2 | shrine-guilds_den_twin vs shrine_twin-guilds_den | 98.1 m vs 100.1 m (2.1 %) |
| F2 | shrine-rich_den_twin vs shrine_twin-rich_den | 99.0 m vs 101.1 m (2.0 %) |
| F2 | shrine-ford_nest_twin vs shrine_twin-ford_nest | 38.4 m vs 37.7 m (2.0 %) |
| F2 | shrine-ford_a vs shrine_twin-ford_b | 38.4 m vs 37.7 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 65 sources) 43.23 s.
- Map Lab v2 (map-production.md 2.5): layout thornwater_s26, 2 seats, rules tempo standard, 0 fixable findings.
- Navmesh raster 1.48 s (614 polygons, 230400 cells of 0.25 m), spot / mirror checks 0.50 s, 2080 paths 0.66 s.
- Map Thornwater (seed 26), scene res://docs/tools/world_forge/out/thornwater_s26/preview.tscn, sim mode off; level load + navmesh bake 0.4 s (13 frames), lab 46.4 s. Spec: docs/design/map-production.md.
