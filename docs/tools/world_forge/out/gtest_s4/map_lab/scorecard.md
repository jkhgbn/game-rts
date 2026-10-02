# Map Lab: Gtest (seed 4) scorecard: world_forge_gtest_s4

2026-10-02 17:20 · lab v1.0 · 45.89 s · scanned 63 spots

## Result: **WARN** · score **89 / 100**

0 FAIL · 5 WARN · 13 PASS · 3 info checks; findings: 0 FAIL, 45 WARN, 31 info

## Improve next
1. **Map geometry: path pairs match their mirror twins** (WARN): well-ford_nest vs well_twin-ford_nest_twin: 4.3 m vs 3.3 m (23.1 %) -> well-ford_nest is longer: look for an unmirrored collider on that route (heat map, M3 tiles) (find the unmirrored obstacle on the longer route) _(from F1 979 / 992 pairs within 2 % (0 FAIL, 13 WARN, 0 info))_
2. **Targets met (rules bands, per seat)** (WARN): south-west keep_enemy: keep_enemy 107.6 outside 116-150 (7 %) -> a designer moves the keeps or the river (R1 keep_enemy is not auto-fixed) _(from R1 6 / 8 clean (0 FAIL, 2 WARN))_
3. **Unit paths (NavigationServer): pairs match their twins** (WARN): lairs_n_one-bridge_crown_a vs lairs_n_one_twin-bridge_crown_b: 68.0 m vs 81.2 m (16.3 %) -> units walk lairs_n_one_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 941 / 992 pairs within 2 % (0 FAIL, 23 WARN, 28 info))_
4. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest post: 39.4 m vs 41.3 m between seats (4.6 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 9 / 10 clean (0 FAIL, 1 WARN))_
5. **Clearances (roads, crossings)** (WARN): nat_node: node 7.9 m from crossing bridge_crown_a (want >= 8) -> move it off the crossing approach (auto-fix) _(from R4 51 / 57 clean (0 FAIL, 6 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 592 polygons, main area 13198 m² (92 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 63 / 63 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 2 / 2 clean, 3 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 2 circles ok, 10 segments ok, 120 x 120 m ok, 89 spots ok, 1.0x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 63 / 63 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 63 / 63 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.01 % (11 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | **WARN** 69 | 979 / 992 pairs within 2 % (0 FAIL, 13 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) | find the unmirrored obstacle on the longer route |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 941 / 992 pairs within 2 % (0 FAIL, 23 WARN, 28 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 66 | 9 / 10 clean (0 FAIL, 1 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps (team maps) | INFO | no side has 2 seats (1v1): nothing to check |  |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 5 / 5 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | **WARN** 61 | 6 / 8 clean (0 FAIL, 2 WARN) | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
| R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL |  |
| R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | own / nearest enemy path 0.9-1.1 (contested) or 1.1-1.45 (raidable): >= 5 per seat |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 6 / 6 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 5 / 5 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | **WARN** 65 | 51 / 57 clean (0 FAIL, 6 WARN) | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (480 x 480 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F1 | well-ford_nest vs well_twin-ford_nest_twin | 4.3 m vs 3.3 m (23.1 %) | well-ford_nest is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-ford_a vs well_twin-ford_b | 4.3 m vs 3.3 m (23.1 %) | well-ford_a is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-stag vs well_twin-stag_twin | 12.3 m vs 11.3 m (8.1 %) | well-stag is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-inn_peddler vs well_twin-inn_peddler_twin | 13.2 m vs 12.2 m (7.6 %) | well-inn_peddler is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-shrine vs well_twin-shrine_twin | 16.3 m vs 15.3 m (6.1 %) | well-shrine is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-bridge_road_a vs well_twin-bridge_road_b | 20.0 m vs 21.0 m (4.8 %) | well_twin-bridge_road_b is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-cache_a vs well_twin-cache_a_twin | 23.4 m vs 22.4 m (4.3 %) | well-cache_a is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-lairs_n_two vs well_twin-lairs_n_two_twin | 30.7 m vs 31.7 m (3.1 %) | well_twin-lairs_n_two_twin is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-post_a vs well_twin-post_a_twin | 32.5 m vs 31.5 m (3.1 %) | well-post_a is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | nat_node-well vs nat_node_twin-well_twin | 32.6 m vs 31.6 m (3.1 %) | nat_node-well is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-lairs_w_one vs well_twin-lairs_w_one_twin | 34.8 m vs 33.8 m (2.9 %) | well-lairs_w_one is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-lairs_w_two vs well_twin-lairs_w_two_twin | 36.8 m vs 35.8 m (2.7 %) | well-lairs_w_two is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | well-bridge_crown_a vs well_twin-bridge_crown_b | 39.3 m vs 38.3 m (2.5 %) | well-bridge_crown_a is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F2 | lairs_n_one-bridge_crown_a vs lairs_n_one_twin-bridge_crown_b | 68.0 m vs 81.2 m (16.3 %) | units walk lairs_n_one_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-bridge_crown_a vs rich_node_twin-bridge_crown_b | 60.7 m vs 70.6 m (14.1 %) | units walk rich_node_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-cache_b vs rich_node_twin-cache_b_twin | 78.4 m vs 88.4 m (11.2 %) | units walk rich_node_twin-cache_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-inn_tavern_twin vs rich_node_twin-inn_tavern | 86.0 m vs 96.0 m (10.4 %) | units walk rich_node_twin-inn_tavern the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_a vs keep_t1-post_a_twin | 43.9 m vs 39.4 m (10.3 %) | units walk keep_t0-post_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-tower_b vs rich_node_twin-tower_b_twin | 90.6 m vs 100.5 m (9.9 %) | units walk rich_node_twin-tower_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-cache_a_twin vs well_twin-cache_a | 70.6 m vs 63.8 m (9.6 %) | units walk well-cache_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge-bridge_crown_a vs rich_lodge_twin-bridge_crown_b | 75.9 m vs 83.5 m (9.2 %) | units walk rich_lodge_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-lairs_w_one_twin vs ford_nest_twin-lairs_w_one | 86.9 m vs 79.1 m (9.0 %) | units walk ford_nest-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-wallow vs rich_node_twin-wallow_twin | 101.3 m vs 111.2 m (8.9 %) | units walk rich_node_twin-wallow_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-post_b vs rich_node_twin-post_b_twin | 103.0 m vs 113.0 m (8.8 %) | units walk rich_node_twin-post_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-tower_a_twin vs rich_node_twin-tower_a | 104.6 m vs 114.5 m (8.7 %) | units walk rich_node_twin-tower_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-third_node vs rich_node_twin-third_node_twin | 105.3 m vs 115.2 m (8.6 %) | units walk rich_node_twin-third_node_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-lairs_w_two_twin vs ford_nest_twin-lairs_w_two | 93.7 m vs 102.0 m (8.1 %) | units walk ford_nest_twin-lairs_w_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_n_two vs keep_t1-lairs_n_two_twin | 80.9 m vs 87.9 m (8.0 %) | units walk keep_t1-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-lairs_n_one_twin vs rich_node_twin-lairs_n_one | 121.9 m vs 131.9 m (7.6 %) | units walk rich_node_twin-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge-cache_b vs rich_lodge_twin-cache_b_twin | 93.7 m vs 101.2 m (7.5 %) | units walk rich_lodge_twin-cache_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-guilds_lodge_twin vs rich_node_twin-guilds_lodge | 127.8 m vs 137.7 m (7.2 %) | units walk rich_node_twin-guilds_lodge the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-lairs_n_two vs home_b_twin-lairs_n_two_twin | 87.0 m vs 93.6 m (7.1 %) | units walk home_b_twin-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-rich_lodge_twin vs rich_node_twin-rich_lodge | 131.2 m vs 141.2 m (7.1 %) | units walk rich_node_twin-rich_lodge the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-post_a_twin vs shrine_twin-post_a | 87.0 m vs 92.9 m (6.3 %) | units walk shrine_twin-post_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den-bridge_crown_a vs guilds_den_twin-bridge_crown_b | 69.7 m vs 74.1 m (6.0 %) | units walk guilds_den_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-bridge_crown_a vs rich_hollow_twin-bridge_crown_b | 80.4 m vs 85.3 m (5.7 %) | units walk rich_hollow_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest post | 39.4 m vs 41.3 m between seats (4.6 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | R1 | south-west keep_enemy | keep_enemy 107.6 outside 116-150 (7 %) | a designer moves the keeps or the river (R1 keep_enemy is not auto-fixed) |
| WARN | R1 | north-east keep_enemy | keep_enemy 107.6 outside 116-150 (7 %) | a designer moves the keeps or the river (R1 keep_enemy is not auto-fixed) |
| WARN | R4 | nat_node | node 7.9 m from crossing bridge_crown_a (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | nat_node_twin | node 7.9 m from crossing bridge_crown_b (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | well | point 4.0 m from crossing ford_a (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | well_twin | point 4.0 m from crossing ford_b (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | wallow | camp 8.9 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | wallow_twin | camp 8.9 m from a road centre line (want >= 9) | push it off the road (auto-fix) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-35.3, 45.0) | (-34.4, 41.4) | keep_t1 | (-34.4, 41.4) | 0.0 |
| keep_t1 | keep | (35.3, -45.0) | (34.4, -41.4) | keep_t0 | (34.4, -41.4) | 0.0 |
| home_a | home_node | (-39.4, 36.4) | (-39.1, 36.4) | home_a_twin | (-39.1, 36.4) | 0.0 |
| home_a_twin | home_node | (39.4, -36.4) | (39.1, -36.4) | home_a | (39.1, -36.4) | 0.0 |
| home_b | home_node | (-26.0, 46.9) | (-25.9, 46.9) | home_b_twin | (-25.9, 46.9) | 0.0 |
| home_b_twin | home_node | (26.0, -46.9) | (25.9, -46.9) | home_b | (25.9, -46.9) | 0.0 |
| nat_node | expansion | (-15.7, 9.0) | (-15.6, 8.9) | nat_node_twin | (-15.6, 8.9) | 0.0 |
| nat_node_twin | expansion | (15.7, -9.0) | (15.6, -8.9) | nat_node | (15.6, -8.9) | 0.0 |
| rich_node | expansion | (-43.2, -35.5) | (-43.1, -35.4) | rich_node_twin | (-43.1, -35.4) | 0.0 |
| rich_node_twin | expansion | (43.2, 35.5) | (43.1, 35.4) | rich_node | (43.1, 35.4) | 0.0 |
| third_node | expansion | (19.1, 46.9) | (18.9, 46.9) | third_node_twin | (18.9, 46.9) | 0.0 |
| third_node_twin | expansion | (-19.1, -46.9) | (-18.9, -46.9) | third_node | (-18.9, -46.9) | 0.0 |
| tower_a | point | (-26.2, -37.7) | (-26.1, -37.6) | tower_a_twin | (-26.1, -37.6) | 0.0 |
| tower_a_twin | point | (26.2, 37.7) | (26.1, 37.6) | tower_a | (26.1, 37.6) | 0.0 |
| tower_b | point | (0.7, 39.3) | (0.6, 39.1) | tower_b_twin | (0.6, 39.1) | 0.0 |
| tower_b_twin | point | (-0.7, -39.3) | (-0.6, -39.1) | tower_b | (-0.6, -39.1) | 0.0 |
| well | point | (-32.3, -17.0) | (-32.1, -16.9) | well_twin | (-31.6, -16.4) | 0.7 |
| well_twin | point | (32.3, 17.0) | (31.6, 16.4) | well | (32.1, 16.9) | 0.7 |
| shrine | point | (-23.9, -4.3) | (-23.9, -4.1) | shrine_twin | (-23.9, -4.1) | 0.0 |
| shrine_twin | point | (23.9, 4.3) | (23.9, 4.1) | shrine | (23.9, 4.1) | 0.0 |
| rich_hollow | camp | (-59.6, -49.0) | (-59.4, -48.9) | rich_hollow_twin | (-59.4, -48.9) | 0.0 |
| rich_hollow_twin | camp | (59.6, 49.0) | (59.4, 48.9) | rich_hollow | (59.4, 48.9) | 0.0 |
| wallow | camp | (-5.8, 54.0) | (-5.6, 53.9) | wallow_twin | (-5.6, 53.9) | 0.0 |
| wallow_twin | camp | (5.8, -54.0) | (5.6, -53.9) | wallow | (5.6, -53.9) | 0.0 |
| ford_nest | camp | (-29.6, -14.0) | (-29.6, -13.9) | ford_nest_twin | (-29.6, -13.9) | 0.0 |
| ford_nest_twin | camp | (29.6, 14.0) | (29.6, 13.9) | ford_nest | (29.6, 13.9) | 0.0 |
| stag | camp | (-34.1, -5.9) | (-33.9, -5.9) | stag_twin | (-33.9, -5.9) | 0.0 |
| stag_twin | camp | (34.1, 5.9) | (33.9, 5.9) | stag | (33.9, 5.9) | 0.0 |
| inn_tavern | tavern | (-15.7, -14.6) | (-15.6, -14.4) | inn_tavern_twin | (-15.6, -14.4) | 0.0 |
| inn_tavern_twin | tavern | (15.7, 14.6) | (15.6, 14.4) | inn_tavern | (15.6, 14.4) | 0.0 |
| post_a | post | (-51.4, 6.1) | (-51.4, 5.9) | post_a_twin | (-51.4, 5.9) | 0.0 |
| post_a_twin | post | (51.4, -6.1) | (51.4, -5.9) | post_a | (51.4, -5.9) | 0.0 |
| post_b | post | (5.8, 51.4) | (5.6, 51.4) | post_b_twin | (5.6, 51.4) | 0.0 |
| post_b_twin | post | (-5.8, -51.4) | (-5.6, -51.4) | post_b | (-5.6, -51.4) | 0.0 |
| rich_den | guild | (-57.7, -40.1) | (-57.6, -39.9) | rich_den_twin | (-57.6, -39.9) | 0.0 |
| rich_den_twin | guild | (57.7, 40.1) | (57.6, 39.9) | rich_den | (57.6, 39.9) | 0.0 |
| rich_lodge | guild | (-50.5, -48.8) | (-50.4, -48.9) | rich_lodge_twin | (-50.4, -48.9) | 0.0 |
| rich_lodge_twin | guild | (50.5, 48.8) | (50.4, 48.9) | rich_lodge | (50.4, 48.9) | 0.0 |
| guilds_den | guild | (-54.9, -38.7) | (-54.9, -38.6) | guilds_den_twin | (-54.9, -38.6) | 0.0 |
| guilds_den_twin | guild | (54.9, 38.7) | (54.9, 38.6) | guilds_den | (54.9, 38.6) | 0.0 |
| guilds_lodge | guild | (-47.1, -47.9) | (-47.1, -47.6) | guilds_lodge_twin | (-47.1, -47.6) | 0.0 |
| guilds_lodge_twin | guild | (47.1, 47.9) | (47.1, 47.6) | guilds_lodge | (47.1, 47.6) | 0.0 |
| inn_peddler | peddler | (-23.6, -8.4) | (-24.6, -7.1) | inn_peddler_twin | (-24.6, -7.1) | 0.0 |
| inn_peddler_twin | peddler | (23.6, 8.4) | (24.6, 7.1) | inn_peddler | (24.6, 7.1) | 0.0 |
| cache_a | cache | (-28.3, 4.6) | (-28.1, 4.6) | cache_a_twin | (-28.1, 4.6) | 0.0 |
| cache_a_twin | cache | (28.3, -4.6) | (28.1, -4.6) | cache_a | (28.1, -4.6) | 0.0 |
| cache_b | cache | (-0.6, 28.1) | (-0.6, 27.9) | cache_b_twin | (-0.6, 27.9) | 0.0 |
| cache_b_twin | cache | (0.6, -28.1) | (0.6, -27.9) | cache_b | (0.6, -27.9) | 0.0 |
| lairs_w_one | lair | (-48.2, 11.1) | (-48.1, 10.9) | lairs_w_one_twin | (-48.1, 10.9) | 0.0 |
| lairs_w_one_twin | lair | (48.2, -11.1) | (48.1, -10.9) | lairs_w_one | (48.1, -10.9) | 0.0 |
| lairs_w_two | lair | (-59.4, -3.1) | (-59.1, -3.1) | lairs_w_two_twin | (-59.1, -3.1) | 0.0 |
| lairs_w_two_twin | lair | (59.4, 3.1) | (59.1, 3.1) | lairs_w_two | (59.1, 3.1) | 0.0 |
| lairs_n_one | lair | (-41.4, -46.0) | (-41.4, -45.9) | lairs_n_one_twin | (-41.4, -45.9) | 0.0 |
| lairs_n_one_twin | lair | (41.4, 46.0) | (41.4, 45.9) | lairs_n_one | (41.4, 45.9) | 0.0 |
| lairs_n_two | lair | (-55.6, -34.8) | (-55.4, -34.9) | lairs_n_two_twin | (-55.4, -34.9) | 0.0 |
| lairs_n_two_twin | lair | (55.6, 34.8) | (55.4, 34.9) | lairs_n_two | (55.4, 34.9) | 0.0 |
| bridge_road_a | crossing_bridge_road | (-49.1, -19.5) | (-49.1, -19.4) | bridge_road_b | (-49.1, -19.4) | 0.0 |
| bridge_road_b | crossing_bridge_road | (49.1, 19.5) | (49.1, 19.4) | bridge_road_a | (49.1, 19.4) | 0.0 |
| ford_a | crossing_ford | (-29.6, -14.0) | (-29.6, -13.9) | ford_b | (-29.6, -13.9) | 0.0 |
| ford_b | crossing_ford | (29.6, 14.0) | (29.6, 13.9) | ford_a | (29.6, 13.9) | 0.0 |
| bridge_crown_a | crossing_bridge_lane | (-7.9, 10.0) | (-7.9, 9.9) | bridge_crown_b | (-7.9, 9.9) | 0.0 |
| bridge_crown_b | crossing_bridge_lane | (7.9, -10.0) | (7.9, -9.9) | bridge_crown_a | (7.9, -9.9) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, -0.1) | 0.4 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F1 map geometry: most asymmetric pairs (top 13 of 13)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | well - ford_nest | 4.3 | well_twin - ford_nest_twin | 3.3 | +23.1 % |
| 2 | well - ford_a | 4.3 | well_twin - ford_b | 3.3 | +23.1 % |
| 3 | well - stag | 12.3 | well_twin - stag_twin | 11.3 | +8.1 % |
| 4 | well - inn_peddler | 13.2 | well_twin - inn_peddler_twin | 12.2 | +7.6 % |
| 5 | well - shrine | 16.3 | well_twin - shrine_twin | 15.3 | +6.1 % |
| 6 | well - bridge_road_a | 20.0 | well_twin - bridge_road_b | 21.0 | -4.8 % |
| 7 | well - cache_a | 23.4 | well_twin - cache_a_twin | 22.4 | +4.3 % |
| 8 | well - lairs_n_two | 30.7 | well_twin - lairs_n_two_twin | 31.7 | -3.1 % |
| 9 | well - post_a | 32.5 | well_twin - post_a_twin | 31.5 | +3.1 % |
| 10 | nat_node - well | 32.6 | nat_node_twin - well_twin | 31.6 | +3.1 % |
| 11 | well - lairs_w_one | 34.8 | well_twin - lairs_w_one_twin | 33.8 | +2.9 % |
| 12 | well - lairs_w_two | 36.8 | well_twin - lairs_w_two_twin | 35.8 | +2.7 % |
| 13 | well - bridge_crown_a | 39.3 | well_twin - bridge_crown_b | 38.3 | +2.5 % |


## F2 unit paths: most asymmetric pairs (top 20 of 51)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | lairs_n_one - bridge_crown_a | 68.0 | lairs_n_one_twin - bridge_crown_b | 81.2 | -16.3 % |
| 2 | rich_node - bridge_crown_a | 60.7 | rich_node_twin - bridge_crown_b | 70.6 | -14.1 % |
| 3 | rich_node - cache_b | 78.4 | rich_node_twin - cache_b_twin | 88.4 | -11.2 % |
| 4 | rich_node - inn_tavern_twin | 86.0 | rich_node_twin - inn_tavern | 96.0 | -10.4 % |
| 5 | keep_t0 - post_a | 43.9 | keep_t1 - post_a_twin | 39.4 | +10.3 % |
| 6 | rich_node - tower_b | 90.6 | rich_node_twin - tower_b_twin | 100.5 | -9.9 % |
| 7 | well - cache_a_twin | 70.6 | well_twin - cache_a | 63.8 | +9.6 % |
| 8 | rich_lodge - bridge_crown_a | 75.9 | rich_lodge_twin - bridge_crown_b | 83.5 | -9.2 % |
| 9 | ford_nest - lairs_w_one_twin | 86.9 | ford_nest_twin - lairs_w_one | 79.1 | +9.0 % |
| 10 | rich_node - wallow | 101.3 | rich_node_twin - wallow_twin | 111.2 | -8.9 % |
| 11 | rich_node - post_b | 103.0 | rich_node_twin - post_b_twin | 113.0 | -8.8 % |
| 12 | rich_node - tower_a_twin | 104.6 | rich_node_twin - tower_a | 114.5 | -8.7 % |
| 13 | rich_node - third_node | 105.3 | rich_node_twin - third_node_twin | 115.2 | -8.6 % |
| 14 | ford_nest - lairs_w_two_twin | 93.7 | ford_nest_twin - lairs_w_two | 102.0 | -8.1 % |
| 15 | keep_t0 - lairs_n_two | 80.9 | keep_t1 - lairs_n_two_twin | 87.9 | -8.0 % |
| 16 | rich_node - lairs_n_one_twin | 121.9 | rich_node_twin - lairs_n_one | 131.9 | -7.6 % |
| 17 | rich_lodge - cache_b | 93.7 | rich_lodge_twin - cache_b_twin | 101.2 | -7.5 % |
| 18 | rich_node - guilds_lodge_twin | 127.8 | rich_node_twin - guilds_lodge | 137.7 | -7.2 % |
| 19 | home_b - lairs_n_two | 87.0 | home_b_twin - lairs_n_two_twin | 93.6 | -7.1 % |
| 20 | rich_node - rich_lodge_twin | 131.2 | rich_node_twin - rich_lodge | 141.2 | -7.1 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 37.5 (nat_node) | 36.2 (tower_b) | 31.5 (wallow) | 33.5 (lairs_w_one) | 56.8 (inn_tavern_twin) | 41.3 (post_b) | 49.5 (inn_peddler) | 36.3 (cache_b) | 53.8 (crown) | 107.6 |
| north-east | 37.5 (nat_node_twin) | 36.2 (tower_b_twin) | 31.6 (wallow_twin) | 33.5 (lairs_w_one_twin) | 56.8 (inn_tavern) | 39.4 (post_a_twin) | 49.5 (inn_peddler_twin) | 36.3 (cache_b_twin) | 53.8 (crown) | 107.6 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| home_a | home_node | 6.9 | home_a_twin | 6.9 | +0.0 % |
| home_b | home_node | 10.5 | home_b_twin | 10.6 | -0.9 % |
| wallow | camp | 31.5 | wallow_twin | 31.6 | -0.1 % |
| lairs_w_one | lair | 33.5 | lairs_w_one_twin | 33.5 | +0.0 % |
| tower_b | point | 36.2 | tower_b_twin | 36.2 | -0.1 % |
| cache_b | cache | 36.3 | cache_b_twin | 36.3 | -0.0 % |
| cache_a | cache | 37.3 | cache_a_twin | 37.3 | +0.0 % |
| nat_node | expansion | 37.5 | nat_node_twin | 37.5 | +0.0 % |
| bridge_crown_a | crossing_bridge_lane | 41.2 | bridge_crown_b | 41.2 | +0.0 % |
| post_b | post | 41.3 | post_b_twin | 41.3 | -0.0 % |
| post_a | post | 43.9 | post_a_twin | 39.4 | +10.3 % |
| shrine | point | 46.7 | shrine_twin | 46.7 | -0.0 % |
| stag | camp | 47.3 | stag_twin | 47.3 | +0.0 % |
| inn_peddler | peddler | 49.5 | inn_peddler_twin | 49.5 | +0.0 % |
| third_node | expansion | 53.6 | third_node_twin | 53.6 | -0.0 % |
| crown | crown | 53.8 | crown | 53.8 | +0.0 % |
| lairs_w_two | lair | 54.1 | lairs_w_two_twin | 54.0 | +0.1 % |
| ford_a | crossing_ford | 55.5 | ford_b | 55.5 | +0.0 % |
| ford_nest | camp | 55.5 | ford_nest_twin | 55.5 | +0.0 % |
| inn_tavern_twin | tavern | 56.8 | inn_tavern | 56.8 | +0.0 % |
| well | point | 58.3 | well_twin | 57.8 | +0.8 % |
| tower_a_twin | point | 62.4 | tower_a | 62.4 | -0.0 % |
| bridge_road_a | crossing_bridge_road | 64.2 | bridge_road_b | 64.3 | -0.2 % |
| bridge_crown_b | crossing_bridge_lane | 66.4 | bridge_crown_a | 66.4 | +0.0 % |
| inn_tavern | tavern | 68.8 | inn_tavern_twin | 68.7 | +0.2 % |
| ford_b | crossing_ford | 69.7 | ford_a | 69.7 | -0.0 % |
| ford_nest_twin | camp | 69.7 | ford_nest | 69.7 | -0.0 % |
| well_twin | point | 70.6 | well | 70.9 | -0.4 % |
| nat_node_twin | expansion | 72.2 | nat_node | 72.2 | -0.0 % |
| lairs_n_one_twin | lair | 76.1 | lairs_n_one | 76.1 | -0.0 % |
| inn_peddler_twin | peddler | 76.2 | inn_peddler | 76.3 | -0.1 % |
| stag_twin | camp | 78.0 | stag | 78.1 | -0.1 % |
| shrine_twin | point | 79.1 | shrine | 79.2 | -0.1 % |
| rich_node_twin | expansion | 79.2 | rich_node | 79.2 | -0.0 % |
| tower_a | point | 79.4 | tower_a_twin | 79.4 | -0.0 % |
| rich_node | expansion | 79.9 | rich_node_twin | 79.9 | -0.0 % |
| lairs_n_two | lair | 80.9 | lairs_n_two_twin | 87.9 | -8.0 % |
| guilds_lodge_twin | guild | 81.9 | guilds_lodge | 81.9 | -0.0 % |
| rich_lodge_twin | guild | 85.2 | rich_lodge | 85.2 | -0.0 % |
| cache_a_twin | cache | 86.6 | cache_a | 86.7 | -0.1 % |
| cache_b_twin | cache | 87.4 | cache_b | 87.3 | +0.1 % |
| bridge_road_b | crossing_bridge_road | 87.4 | bridge_road_a | 87.4 | +0.0 % |
| lairs_n_one | lair | 88.8 | lairs_n_one_twin | 88.8 | -0.0 % |
| third_node_twin | expansion | 89.9 | third_node | 89.9 | -0.0 % |
| guilds_den_twin | guild | 90.1 | guilds_den | 90.1 | -0.0 % |
| guilds_den | guild | 90.2 | guilds_den_twin | 90.1 | +0.1 % |
| lairs_n_two_twin | lair | 91.2 | lairs_n_two | 91.3 | -0.0 % |
| guilds_lodge | guild | 92.5 | guilds_lodge_twin | 92.6 | -0.0 % |
| rich_den_twin | guild | 92.7 | rich_den | 92.7 | -0.0 % |
| rich_den | guild | 93.0 | rich_den_twin | 92.9 | +0.1 % |
| tower_b_twin | point | 93.4 | tower_b | 93.4 | +0.1 % |
| rich_hollow_twin | camp | 94.1 | rich_hollow | 94.1 | -0.0 % |
| rich_lodge | guild | 95.2 | rich_lodge_twin | 95.2 | -0.0 % |
| post_a_twin | post | 98.8 | post_a | 98.8 | -0.1 % |
| post_b_twin | post | 99.3 | post_b | 99.3 | +0.0 % |
| lairs_w_one_twin | lair | 100.0 | lairs_w_one | 100.1 | -0.1 % |
| rich_hollow | camp | 100.9 | rich_hollow_twin | 100.9 | +0.1 % |
| lairs_w_two_twin | lair | 103.2 | lairs_w_two | 103.2 | -0.0 % |
| home_a_twin | home_node | 107.1 | home_a | 107.1 | -0.0 % |
| home_b_twin | home_node | 107.2 | home_b | 107.2 | +0.0 % |
| keep_t1 | keep | 107.6 | keep_t0 | 107.6 | +0.0 % |
| wallow_twin | camp | 108.9 | wallow | 108.6 | +0.3 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| south-west | enemy keep (keep_t1) | 107.6 | 0.0 | 0:23 | 0:22 | 0:14 | 0:27 |
| south-west | nearest expansion (nat_node) | 37.5 | 0.0 | 0:08 | 0:08 | 0:05 | 0:09 |
| south-west | nearest point (tower_b) | 36.2 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| south-west | nearest camp (wallow) | 31.5 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| south-west | crown (crown) | 53.8 | 0.0 | 0:12 | 0:11 | 0:07 | 0:13 |
| north-east | enemy keep (keep_t0) | 107.6 | 0.0 | 0:23 | 0:22 | 0:14 | 0:27 |
| north-east | nearest expansion (nat_node_twin) | 37.5 | 0.0 | 0:08 | 0:08 | 0:05 | 0:09 |
| north-east | nearest point (tower_b_twin) | 36.2 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| north-east | nearest camp (wallow_twin) | 31.6 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| north-east | crown (crown) | 53.8 | 0.0 | 0:12 | 0:11 | 0:07 | 0:13 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_a | bridge_road | 6.0 | 4.4 | 5.4 | bridge_road_b | 4.4 |
| bridge_road_b | bridge_road | 6.0 | 4.4 | 5.4 | bridge_road_a | 4.4 |
| ford_a | ford | 7.0 | 4.8 | 5.8 | ford_b | 4.8 |
| ford_b | ford | 7.0 | 4.8 | 5.8 | ford_a | 4.8 |
| bridge_crown_a | bridge_lane | 8.0 | 7.3 | 8.3 | bridge_crown_b | 7.1 |
| bridge_crown_b | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_a | 7.3 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 53.8 | 5.5 | (-6.8, 8.4) | - |
| keep_t0 -> keep_t1 | 107.6 | 5.5 | (-6.9, 8.3) | - |
| keep_t0 -> nat_node | 37.5 | 34.4 | (-32.4, 37.9) | - |
| keep_t1 -> crown | 53.8 | 5.5 | (7.0, -8.2) | - |
| keep_t1 -> nat_node_twin | 37.5 | 34.4 | (32.4, -37.9) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| south-west | keep_enemy | 116.00-150.00 | 107.58 | 7.3 % |
| south-west | natural | 38.00-58.00 | 37.52 | 1.3 % |
| south-west | rich | 65.00-95.00 | 79.86 | - |
| south-west | crown | 50.00-72.00 | 53.78 | - |
| north-east | keep_enemy | 116.00-150.00 | 107.58 | 7.3 % |
| north-east | natural | 38.00-58.00 | 37.52 | 1.3 % |
| north-east | rich | 65.00-95.00 | 79.87 | - |
| north-east | crown | 50.00-72.00 | 53.78 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |
| north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| south-west | 5 | 4 | 12 | 29 |
| north-east | 5 | 4 | 12 | 29 |


## Hottest metres (every spot-pair shortest path, 1953 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-29.5, -13.5) | 283 | 14 % |
| 2 | (28.5, 12.5) | 253 | 13 % |
| 3 | (-13.5, 7.5) | 233 | 12 % |
| 4 | (-18.5, -1.5) | 228 | 12 % |
| 5 | (13.5, -7.5) | 227 | 12 % |
| 6 | (18.5, 1.5) | 223 | 11 % |
| 7 | (4.5, -18.5) | 174 | 9 % |
| 8 | (-4.5, 18.5) | 173 | 9 % |
| 9 | (-5.5, -24.5) | 162 | 8 % |
| 10 | (5.5, 24.5) | 160 | 8 % |


## Info findings (31)
| Check | Where | What |
|---|---|---|
| N3 | island 3 at (35.1, -44.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 25 at (-35.4, 45.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 24 islands on top of colliders (526 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | rich_den-bridge_crown_a vs rich_den_twin-bridge_crown_b | 72.5 m vs 76.3 m (5.0 %) |
| F2 | guilds_den-cache_b vs guilds_den_twin-cache_b_twin | 87.4 m vs 91.9 m (4.8 %) |
| F2 | lairs_n_two-bridge_crown_a vs lairs_n_two_twin-bridge_crown_b | 67.4 m vs 70.8 m (4.8 %) |
| F2 | rich_hollow-cache_b vs rich_hollow_twin-cache_b_twin | 98.2 m vs 103.0 m (4.7 %) |
| F2 | rich_hollow-inn_tavern_twin vs rich_hollow_twin-inn_tavern | 105.8 m vs 110.6 m (4.4 %) |
| F2 | cache_b-bridge_crown_a vs cache_b_twin-bridge_crown_b | 20.3 m vs 19.4 m (4.2 %) |
| F2 | rich_den-cache_b vs rich_den_twin-cache_b_twin | 90.2 m vs 94.0 m (4.0 %) |
| F2 | inn_tavern-bridge_crown_a vs inn_tavern_twin-bridge_crown_b | 46.9 m vs 48.8 m (4.0 %) |
| F2 | rich_node-inn_peddler vs rich_node_twin-inn_peddler_twin | 35.1 m vs 33.8 m (3.8 %) |
| F2 | rich_hollow-wallow vs rich_hollow_twin-wallow_twin | 121.1 m vs 125.9 m (3.8 %) |
| F2 | rich_hollow-post_b vs rich_hollow_twin-post_b_twin | 122.8 m vs 127.6 m (3.8 %) |
| F2 | rich_hollow-lairs_n_one_twin vs rich_hollow_twin-lairs_n_one | 141.7 m vs 146.5 m (3.3 %) |
| F2 | guilds_den-lairs_n_one_twin vs guilds_den_twin-lairs_n_one | 130.9 m vs 135.4 m (3.3 %) |
| F2 | inn_peddler-bridge_crown_b vs inn_peddler_twin-bridge_crown_a | 48.7 m vs 47.1 m (3.2 %) |
| F2 | rich_hollow-guilds_lodge_twin vs rich_hollow_twin-guilds_lodge | 147.5 m vs 152.4 m (3.2 %) |
| F2 | guilds_den-guilds_lodge_twin vs guilds_den_twin-guilds_lodge | 136.8 m vs 141.2 m (3.2 %) |
| F2 | rich_hollow-rich_lodge_twin vs rich_hollow_twin-rich_lodge | 151.0 m vs 155.8 m (3.1 %) |
| F2 | bridge_road_a-bridge_crown_a vs bridge_road_b-bridge_crown_b | 52.4 m vs 54.0 m (3.0 %) |
| F2 | rich_den-lairs_n_one_twin vs rich_den_twin-lairs_n_one | 133.7 m vs 137.5 m (2.8 %) |
| F2 | rich_den-guilds_lodge_twin vs rich_den_twin-guilds_lodge | 139.6 m vs 143.4 m (2.6 %) |
| F2 | rich_den-rich_lodge_twin vs rich_den_twin-rich_lodge | 143.0 m vs 146.8 m (2.6 %) |
| F2 | inn_tavern-lairs_n_two vs inn_tavern_twin-lairs_n_two_twin | 45.9 m vs 44.7 m (2.5 %) |
| F2 | lairs_w_two-lairs_n_two_twin vs lairs_w_two_twin-lairs_n_two | 123.1 m vs 126.0 m (2.3 %) |
| F2 | stag-lairs_n_two vs stag_twin-lairs_n_two_twin | 37.9 m vs 38.8 m (2.3 %) |
| F2 | stag-guilds_den vs stag_twin-guilds_den_twin | 41.2 m vs 42.1 m (2.1 %) |
| F2 | third_node-cache_b_twin vs third_node_twin-cache_b | 87.5 m vs 85.7 m (2.1 %) |
| F2 | guilds_lodge-bridge_crown_a vs guilds_lodge_twin-bridge_crown_b | 80.6 m vs 82.2 m (2.0 %) |
| F2 | stag-rich_den vs stag_twin-rich_den_twin | 43.4 m vs 44.2 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 63 sources) 41.16 s.
- Map Lab v2 (map-production.md 2.5): layout gtest_s4, 2 seats, rules tempo standard, 3 fixable findings.
- Navmesh raster 1.32 s (592 polygons, 230400 cells of 0.25 m), spot / mirror checks 0.48 s, 1953 paths 0.57 s.
- Map Gtest (seed 4), scene res://docs/tools/world_forge/out/gtest_s4/preview.tscn, sim mode off; level load + navmesh bake 0.5 s (217 frames), lab 45.4 s. Spec: docs/design/map-production.md.
