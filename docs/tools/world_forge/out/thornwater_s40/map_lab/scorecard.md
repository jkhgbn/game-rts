# Map Lab: Thornwater (seed 40) scorecard: world_forge_thornwater_s40

2026-10-02 18:12 · lab v1.0 · 349.89 s · scanned 65 spots

## Result: **FAIL** · score **88 / 100**

1 FAIL · 1 WARN · 16 PASS · 3 info checks; findings: 1 FAIL, 48 WARN, 90 info

## Improve next
1. **Map geometry: path pairs match their mirror twins** (FAIL): post_a-cache_a vs post_a_twin-cache_a_twin: 28.9 m vs 26.8 m (7.2 %) -> post_a-cache_a is longer: look for an unmirrored collider on that route (heat map, M3 tiles) (find the unmirrored obstacle on the longer route) _(from F1 1055 / 1056 pairs within 2 % (1 FAIL, 0 WARN, 0 info))_
2. **Unit paths (NavigationServer): pairs match their twins** (WARN): keep_t0-lairs_n_one_twin vs keep_t1-lairs_n_one: 101.1 m vs 87.0 m (13.9 %) -> units walk keep_t0-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 921 / 1056 pairs within 2 % (0 FAIL, 48 WARN, 87 info))_
3. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 856 polygons, main area 13160 m² (91 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
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
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (4 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | **FAIL** 34 | 1055 / 1056 pairs within 2 % (1 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) | find the unmirrored obstacle on the longer route |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 921 / 1056 pairs within 2 % (0 FAIL, 48 WARN, 87 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

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
| FAIL | F1 | post_a-cache_a vs post_a_twin-cache_a_twin | 28.9 m vs 26.8 m (7.2 %) | post_a-cache_a is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F2 | keep_t0-lairs_n_one_twin vs keep_t1-lairs_n_one | 101.1 m vs 87.0 m (13.9 %) | units walk keep_t0-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-lairs_n_two vs shrine_twin-lairs_n_two_twin | 45.9 m vs 40.3 m (12.2 %) | units walk shrine-lairs_n_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow-lairs_n_one_twin vs wallow_twin-lairs_n_one | 49.9 m vs 56.5 m (11.6 %) | units walk wallow_twin-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-bridge_crown_a vs well_twin-bridge_crown_b | 38.6 m vs 43.3 m (10.9 %) | units walk well_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-inn_peddler_twin vs post_b_twin-inn_peddler | 52.1 m vs 58.4 m (10.8 %) | units walk post_b_twin-inn_peddler the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-steps_a vs tower_a_twin-steps_b | 35.9 m vs 40.1 m (10.5 %) | units walk tower_a_twin-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-inn_peddler_twin vs rich_hollow_twin-inn_peddler | 112.9 m vs 101.5 m (10.1 %) | units walk rich_hollow-inn_peddler_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_a-ford_a vs post_a_twin-ford_b | 65.8 m vs 59.6 m (9.4 %) | units walk post_a-ford_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_a-post_b_twin vs post_a_twin-post_b | 81.1 m vs 89.1 m (8.9 %) | units walk post_a_twin-post_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_peddler-ford_a vs inn_peddler_twin-ford_b | 36.4 m vs 33.5 m (8.1 %) | units walk inn_peddler-ford_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-inn_peddler_twin vs ford_nest_twin-inn_peddler | 33.5 m vs 36.4 m (8.1 %) | units walk ford_nest_twin-inn_peddler the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_n_one-steps_b vs lairs_n_one_twin-steps_a | 74.1 m vs 80.5 m (8.0 %) | units walk lairs_n_one_twin-steps_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-lairs_n_one_twin vs rich_node_twin-lairs_n_one | 129.5 m vs 119.2 m (7.9 %) | units walk rich_node-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-inn_tavern_twin vs home_b_twin-inn_tavern | 73.4 m vs 67.7 m (7.9 %) | units walk home_b-inn_tavern_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-lairs_w_two_twin vs ford_nest_twin-lairs_w_two | 56.4 m vs 61.1 m (7.7 %) | units walk ford_nest_twin-lairs_w_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-post_a_twin vs tower_a_twin-post_a | 103.4 m vs 95.6 m (7.5 %) | units walk tower_a-post_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-guilds_den vs shrine_twin-guilds_den_twin | 52.5 m vs 48.6 m (7.4 %) | units walk shrine-guilds_den the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge-lairs_n_one_twin vs rich_lodge_twin-lairs_n_one | 144.6 m vs 133.9 m (7.4 %) | units walk rich_lodge-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-bridge_crown_a vs tower_a_twin-bridge_crown_b | 55.9 m vs 60.3 m (7.4 %) | units walk tower_a_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-cache_a_twin vs post_b_twin-cache_a | 62.8 m vs 67.7 m (7.4 %) | units walk post_b_twin-cache_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-rich_den vs post_b_twin-rich_den_twin | 121.2 m vs 112.3 m (7.3 %) | units walk post_b-rich_den the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-guilds_lodge_twin vs tower_a_twin-guilds_lodge | 133.6 m vs 123.8 m (7.3 %) | units walk tower_a-guilds_lodge_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-lairs_w_two_twin vs tower_a_twin-lairs_w_two | 107.0 m vs 99.3 m (7.2 %) | units walk tower_a-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_n_one-steps_a vs lairs_n_one_twin-steps_b | 49.1 m vs 52.7 m (6.9 %) | units walk lairs_n_one_twin-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-post_a_twin vs ford_nest_twin-post_a | 63.8 m vs 59.4 m (6.8 %) | units walk ford_nest-post_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_peddler-lairs_n_two vs inn_peddler_twin-lairs_n_two_twin | 42.9 m vs 46.1 m (6.8 %) | units walk inn_peddler_twin-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-lairs_w_two vs tower_a_twin-lairs_w_two_twin | 47.5 m vs 44.2 m (6.8 %) | units walk tower_a-lairs_w_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-steps_b vs tower_a_twin-steps_a | 60.9 m vs 65.3 m (6.8 %) | units walk tower_a_twin-steps_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_tavern-lairs_n_one vs inn_tavern_twin-lairs_n_one_twin | 44.0 m vs 41.2 m (6.4 %) | units walk inn_tavern-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-ford_nest_twin vs shrine_twin-ford_nest | 37.3 m vs 35.0 m (6.2 %) | units walk shrine-ford_nest_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-ford_a vs shrine_twin-ford_b | 37.3 m vs 35.0 m (6.2 %) | units walk shrine-ford_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-lairs_w_one_twin vs tower_a_twin-lairs_w_one | 87.9 m vs 82.5 m (6.1 %) | units walk tower_a-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-inn_tavern_twin vs tower_a_twin-inn_tavern | 69.1 m vs 73.6 m (6.0 %) | units walk tower_a_twin-inn_tavern the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-guilds_lodge_twin vs rich_hollow_twin-guilds_lodge | 158.1 m vs 148.6 m (6.0 %) | units walk rich_hollow-guilds_lodge_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_n_one-crown vs lairs_n_one_twin-crown | 61.2 m vs 65.1 m (6.0 %) | units walk lairs_n_one_twin-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b-lairs_n_two vs cache_b_twin-lairs_n_two_twin | 77.7 m vs 82.6 m (6.0 %) | units walk cache_b_twin-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den-lairs_n_one_twin vs guilds_den_twin-lairs_n_one | 140.6 m vs 132.2 m (6.0 %) | units walk guilds_den-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-lairs_n_two vs tower_b_twin-lairs_n_two_twin | 92.0 m vs 97.6 m (5.8 %) | units walk tower_b_twin-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node-rich_den_twin vs third_node_twin-rich_den | 36.9 m vs 39.2 m (5.7 %) | units walk third_node_twin-rich_den the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-inn_peddler_twin vs tower_b_twin-inn_peddler | 50.7 m vs 53.8 m (5.7 %) | units walk tower_b_twin-inn_peddler the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-lairs_n_one vs cache_a_twin-lairs_n_one_twin | 53.3 m vs 56.5 m (5.7 %) | units walk cache_a_twin-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den-lairs_n_one_twin vs rich_den_twin-lairs_n_one | 142.0 m vs 133.9 m (5.7 %) | units walk rich_den-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-lairs_n_one_twin vs rich_hollow_twin-lairs_n_one | 148.2 m vs 140.1 m (5.5 %) | units walk rich_hollow-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-rich_hollow vs shrine_twin-rich_hollow_twin | 59.8 m vs 56.6 m (5.4 %) | units walk shrine-rich_hollow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-lairs_n_one vs shrine_twin-lairs_n_one_twin | 45.3 m vs 47.8 m (5.2 %) | units walk shrine_twin-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge-inn_peddler_twin vs rich_lodge_twin-inn_peddler | 104.3 m vs 99.0 m (5.2 %) | units walk rich_lodge-inn_peddler_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-tower_a_twin vs rich_node_twin-tower_a | 112.3 m vs 106.5 m (5.1 %) | units walk rich_node-tower_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-well_twin vs tower_a_twin-well | 83.9 m vs 88.3 m (5.0 %) | units walk tower_a_twin-well the long way: the engine's polygon path, not the map (see F1) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-40.4, 43.9) | (-44.1, 43.6) | keep_t1 | (-44.1, 43.6) | 0.0 |
| keep_t1 | keep | (40.4, -43.9) | (44.1, -43.6) | keep_t0 | (44.1, -43.6) | 0.0 |
| home_a | home_node | (-43.8, 35.0) | (-43.6, 34.9) | home_a_twin | (-43.6, 34.9) | 0.0 |
| home_a_twin | home_node | (43.8, -35.0) | (43.6, -34.9) | home_a | (43.6, -34.9) | 0.0 |
| home_b | home_node | (-31.3, 46.5) | (-31.1, 46.4) | home_b_twin | (-31.1, 46.4) | 0.0 |
| home_b_twin | home_node | (31.3, -46.5) | (31.1, -46.4) | home_b | (31.1, -46.4) | 0.0 |
| nat_node | expansion | (-5.3, 17.3) | (-5.1, 17.1) | nat_node_twin | (-5.1, 17.1) | 0.0 |
| nat_node_twin | expansion | (5.3, -17.3) | (5.1, -17.1) | nat_node | (5.1, -17.1) | 0.0 |
| rich_node | expansion | (-44.8, -35.7) | (-44.6, -35.6) | rich_node_twin | (-44.6, -35.6) | 0.0 |
| rich_node_twin | expansion | (44.8, 35.7) | (44.6, 35.6) | rich_node | (44.6, 35.6) | 0.0 |
| third_node | expansion | (22.5, 46.5) | (22.4, 46.4) | third_node_twin | (22.4, 46.4) | 0.0 |
| third_node_twin | expansion | (-22.5, -46.5) | (-22.4, -46.4) | third_node | (-22.4, -46.4) | 0.0 |
| tower_a | point | (-26.8, -39.5) | (-26.6, -39.4) | tower_a_twin | (-26.6, -39.4) | 0.0 |
| tower_a_twin | point | (26.8, 39.5) | (26.6, 39.4) | tower_a | (26.6, 39.4) | 0.0 |
| tower_b | point | (-5.5, 42.4) | (-5.4, 42.4) | tower_b_twin | (-5.4, 42.4) | 0.0 |
| tower_b_twin | point | (5.5, -42.4) | (5.4, -42.4) | tower_b | (5.4, -42.4) | 0.0 |
| well | point | (-27.7, -22.6) | (-27.6, -22.4) | well_twin | (-27.6, -22.4) | 0.0 |
| well_twin | point | (27.7, 22.6) | (27.6, 22.4) | well | (27.6, 22.4) | 0.0 |
| shrine | point | (-23.6, -6.6) | (-23.4, -6.6) | shrine_twin | (-23.4, -6.6) | 0.0 |
| shrine_twin | point | (23.6, 6.6) | (23.4, 6.6) | shrine | (23.4, 6.6) | 0.0 |
| rich_hollow | camp | (-60.6, -49.8) | (-59.9, -49.9) | rich_hollow_twin | (-59.9, -49.9) | 0.0 |
| rich_hollow_twin | camp | (60.6, 49.8) | (59.9, 49.9) | rich_hollow | (59.9, 49.9) | 0.0 |
| wallow | camp | (-13.4, 57.0) | (-13.4, 56.9) | wallow_twin | (-13.4, 56.9) | 0.0 |
| wallow_twin | camp | (13.4, -57.0) | (13.4, -56.9) | wallow | (13.4, -56.9) | 0.0 |
| ford_nest | camp | (12.9, 39.4) | (12.9, 39.4) | ford_nest_twin | (12.9, 39.4) | 0.0 |
| ford_nest_twin | camp | (-12.9, -39.4) | (-12.9, -39.4) | ford_nest | (-12.9, -39.4) | 0.0 |
| stag | camp | (-37.8, -7.1) | (-37.6, -7.1) | stag_twin | (-37.6, -7.1) | 0.0 |
| stag_twin | camp | (37.8, 7.1) | (37.6, 7.1) | stag | (37.6, 7.1) | 0.0 |
| inn_tavern | tavern | (-14.1, -15.7) | (-13.9, -15.6) | inn_tavern_twin | (-13.9, -15.6) | 0.0 |
| inn_tavern_twin | tavern | (14.1, 15.7) | (13.9, 15.6) | inn_tavern | (13.9, 15.6) | 0.0 |
| post_a | post | (-53.8, 3.9) | (-53.6, 3.9) | post_a_twin | (-53.6, 3.9) | 0.0 |
| post_a_twin | post | (53.8, -3.9) | (53.6, -3.9) | post_a | (53.6, -3.9) | 0.0 |
| post_b | post | (1.2, 54.0) | (1.1, 53.9) | post_b_twin | (1.1, 53.9) | 0.0 |
| post_b_twin | post | (-1.2, -54.0) | (-1.1, -53.9) | post_b | (-1.1, -53.9) | 0.0 |
| rich_den | guild | (-59.1, -40.9) | (-58.9, -40.9) | rich_den_twin | (-58.9, -40.9) | 0.0 |
| rich_den_twin | guild | (59.1, 40.9) | (58.9, 40.9) | rich_den | (58.9, 40.9) | 0.0 |
| rich_lodge | guild | (-51.6, -49.3) | (-51.4, -49.4) | rich_lodge_twin | (-51.4, -49.4) | 0.0 |
| rich_lodge_twin | guild | (51.6, 49.3) | (51.4, 49.4) | rich_lodge | (51.4, 49.4) | 0.0 |
| guilds_den | guild | (-54.7, -44.1) | (-54.6, -43.9) | guilds_den_twin | (-54.6, -43.9) | 0.0 |
| guilds_den_twin | guild | (54.7, 44.1) | (54.6, 43.9) | guilds_den | (54.6, 43.9) | 0.0 |
| guilds_lodge | guild | (-46.3, -52.7) | (-46.1, -52.6) | guilds_lodge_twin | (-46.1, -52.6) | 0.0 |
| guilds_lodge_twin | guild | (46.3, 52.7) | (46.1, 52.6) | guilds_lodge | (46.1, 52.6) | 0.0 |
| inn_peddler | peddler | (-20.8, -7.9) | (-20.6, -7.9) | inn_peddler_twin | (-20.6, -7.9) | 0.0 |
| inn_peddler_twin | peddler | (20.8, 7.9) | (20.6, 7.9) | inn_peddler | (20.6, 7.9) | 0.0 |
| cache_a | cache | (-28.0, 1.7) | (-27.9, 1.6) | cache_a_twin | (-27.9, 1.6) | 0.0 |
| cache_a_twin | cache | (28.0, -1.7) | (27.9, -1.6) | cache_a | (27.9, -1.6) | 0.0 |
| cache_b | cache | (-9.1, 27.3) | (-9.1, 27.1) | cache_b_twin | (-9.1, 27.1) | 0.0 |
| cache_b_twin | cache | (9.1, -27.3) | (9.1, -27.1) | cache_b | (9.1, -27.1) | 0.0 |
| lairs_w_one | lair | (-45.1, 5.7) | (-44.4, 5.6) | lairs_w_one_twin | (-44.4, 5.6) | 0.0 |
| lairs_w_one_twin | lair | (45.1, -5.7) | (44.4, -5.6) | lairs_w_one | (44.4, -5.6) | 0.0 |
| lairs_w_two | lair | (-57.3, -7.5) | (-57.1, -7.4) | lairs_w_two_twin | (-57.1, -7.4) | 0.0 |
| lairs_w_two_twin | lair | (57.3, 7.5) | (57.1, 7.4) | lairs_w_two | (57.1, 7.4) | 0.0 |
| lairs_n_one | lair | (-36.0, -49.8) | (-35.9, -49.6) | lairs_n_one_twin | (-35.9, -49.6) | 0.0 |
| lairs_n_one_twin | lair | (36.0, 49.8) | (35.9, 49.6) | lairs_n_one | (35.9, 49.6) | 0.0 |
| lairs_n_two | lair | (-49.2, -37.6) | (-49.1, -37.6) | lairs_n_two_twin | (-49.1, -37.6) | 0.0 |
| lairs_n_two_twin | lair | (49.2, 37.6) | (49.1, 37.6) | lairs_n_two | (49.1, 37.6) | 0.0 |
| bridge_road_a | crossing_bridge_road | (-14.6, -49.7) | (-14.4, -49.6) | bridge_road_b | (-14.4, -49.6) | 0.0 |
| bridge_road_b | crossing_bridge_road | (14.6, 49.7) | (14.4, 49.6) | bridge_road_a | (14.4, 49.6) | 0.0 |
| ford_a | crossing_ford | (-12.9, -39.4) | (-12.9, -39.4) | ford_b | (-12.9, -39.4) | 0.0 |
| ford_b | crossing_ford | (12.9, 39.4) | (12.9, 39.4) | ford_a | (12.9, 39.4) | 0.0 |
| bridge_crown_a | crossing_bridge_lane | (-8.6, 9.4) | (-8.4, 9.4) | bridge_crown_b | (-8.4, 9.4) | 0.0 |
| bridge_crown_b | crossing_bridge_lane | (8.6, -9.4) | (8.4, -9.4) | bridge_crown_a | (8.4, -9.4) | 0.0 |
| steps_a | crossing_steps | (-9.4, -8.6) | (-9.4, -8.4) | steps_b | (-9.4, -8.4) | 0.0 |
| steps_b | crossing_steps | (9.4, 8.6) | (9.4, 8.4) | steps_a | (9.4, 8.4) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, -0.1) | 0.4 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F1 map geometry: most asymmetric pairs (top 1 of 1)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | post_a - cache_a | 28.9 | post_a_twin - cache_a_twin | 26.8 | +7.2 % |


## F2 unit paths: most asymmetric pairs (top 20 of 135)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | keep_t0 - lairs_n_one_twin | 101.1 | keep_t1 - lairs_n_one | 87.0 | +13.9 % |
| 2 | shrine - lairs_n_two | 45.9 | shrine_twin - lairs_n_two_twin | 40.3 | +12.2 % |
| 3 | wallow - lairs_n_one_twin | 49.9 | wallow_twin - lairs_n_one | 56.5 | -11.6 % |
| 4 | well - bridge_crown_a | 38.6 | well_twin - bridge_crown_b | 43.3 | -10.9 % |
| 5 | post_b - inn_peddler_twin | 52.1 | post_b_twin - inn_peddler | 58.4 | -10.8 % |
| 6 | tower_a - steps_a | 35.9 | tower_a_twin - steps_b | 40.1 | -10.5 % |
| 7 | rich_hollow - inn_peddler_twin | 112.9 | rich_hollow_twin - inn_peddler | 101.5 | +10.1 % |
| 8 | post_a - ford_a | 65.8 | post_a_twin - ford_b | 59.6 | +9.4 % |
| 9 | post_a - post_b_twin | 81.1 | post_a_twin - post_b | 89.1 | -8.9 % |
| 10 | inn_peddler - ford_a | 36.4 | inn_peddler_twin - ford_b | 33.5 | +8.1 % |
| 11 | ford_nest - inn_peddler_twin | 33.5 | ford_nest_twin - inn_peddler | 36.4 | -8.1 % |
| 12 | lairs_n_one - steps_b | 74.1 | lairs_n_one_twin - steps_a | 80.5 | -8.0 % |
| 13 | rich_node - lairs_n_one_twin | 129.5 | rich_node_twin - lairs_n_one | 119.2 | +7.9 % |
| 14 | home_b - inn_tavern_twin | 73.4 | home_b_twin - inn_tavern | 67.7 | +7.9 % |
| 15 | ford_nest - lairs_w_two_twin | 56.4 | ford_nest_twin - lairs_w_two | 61.1 | -7.7 % |
| 16 | tower_a - well | 17.0 | tower_a_twin - well_twin | 18.4 | -7.6 % |
| 17 | tower_a - post_a_twin | 103.4 | tower_a_twin - post_a | 95.6 | +7.5 % |
| 18 | shrine - guilds_den | 52.5 | shrine_twin - guilds_den_twin | 48.6 | +7.4 % |
| 19 | rich_lodge - lairs_n_one_twin | 144.6 | rich_lodge_twin - lairs_n_one | 133.9 | +7.4 % |
| 20 | tower_a - bridge_crown_a | 55.9 | tower_a_twin - bridge_crown_b | 60.3 | -7.4 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 48.4 (nat_node) | 41.9 (tower_b) | 35.7 (wallow) | 38.4 (lairs_w_one) | 66.8 (inn_tavern) | 40.9 (post_a) | 56.8 (inn_peddler) | 40.5 (cache_b) | 63.4 (crown) | 133.8 |
| north-east | 48.5 (nat_node_twin) | 41.8 (tower_b_twin) | 35.7 (wallow_twin) | 38.4 (lairs_w_one_twin) | 66.8 (inn_tavern_twin) | 40.9 (post_a_twin) | 56.8 (inn_peddler_twin) | 40.5 (cache_b_twin) | 63.4 (crown) | 133.8 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| home_a | home_node | 8.8 | home_a_twin | 8.8 | -0.0 % |
| home_b | home_node | 16.6 | home_b_twin | 16.6 | -0.5 % |
| wallow | camp | 35.7 | wallow_twin | 35.7 | -0.0 % |
| lairs_w_one | lair | 38.4 | lairs_w_one_twin | 38.4 | +0.0 % |
| cache_b | cache | 40.5 | cache_b_twin | 40.5 | -0.0 % |
| post_a | post | 40.9 | post_a_twin | 40.9 | -0.0 % |
| tower_b | point | 41.9 | tower_b_twin | 41.8 | +0.2 % |
| cache_a | cache | 45.2 | cache_a_twin | 45.2 | -0.1 % |
| nat_node | expansion | 48.4 | nat_node_twin | 48.5 | -0.1 % |
| post_b | post | 49.2 | post_b_twin | 49.3 | -0.1 % |
| bridge_crown_a | crossing_bridge_lane | 51.3 | bridge_crown_b | 51.3 | -0.1 % |
| lairs_w_two | lair | 52.6 | lairs_w_two_twin | 52.6 | -0.0 % |
| stag | camp | 53.9 | stag_twin | 53.9 | -0.1 % |
| shrine | point | 54.5 | shrine_twin | 54.6 | -0.1 % |
| inn_peddler | peddler | 56.8 | inn_peddler_twin | 56.8 | -0.1 % |
| ford_nest | camp | 61.1 | ford_nest_twin | 61.2 | -0.1 % |
| ford_b | crossing_ford | 61.1 | ford_a | 61.2 | -0.1 % |
| bridge_road_b | crossing_bridge_road | 62.0 | bridge_road_a | 62.1 | -0.1 % |
| crown | crown | 63.4 | crown | 63.4 | -0.1 % |
| inn_tavern | tavern | 66.8 | inn_tavern_twin | 66.8 | -0.1 % |
| steps_a | crossing_steps | 67.2 | steps_b | 64.3 | +4.3 % |
| well | point | 68.1 | well_twin | 68.1 | -0.1 % |
| steps_b | crossing_steps | 68.8 | steps_a | 68.8 | -0.0 % |
| third_node | expansion | 71.9 | third_node_twin | 72.1 | -0.3 % |
| tower_a_twin | point | 74.7 | tower_a | 74.8 | -0.1 % |
| bridge_crown_b | crossing_bridge_lane | 75.8 | bridge_crown_a | 75.8 | -0.1 % |
| inn_tavern_twin | tavern | 76.2 | inn_tavern | 76.2 | +0.1 % |
| rich_node | expansion | 79.4 | rich_node_twin | 79.4 | +0.0 % |
| inn_peddler_twin | peddler | 80.1 | inn_peddler | 80.1 | -0.0 % |
| lairs_n_two | lair | 81.4 | lairs_n_two_twin | 81.4 | +0.0 % |
| nat_node_twin | expansion | 82.3 | nat_node | 82.4 | -0.1 % |
| well_twin | point | 82.4 | well | 82.5 | -0.1 % |
| shrine_twin | point | 82.9 | shrine | 82.9 | -0.0 % |
| tower_a | point | 85.0 | tower_a_twin | 88.8 | -4.2 % |
| rich_den | guild | 85.8 | rich_den_twin | 85.8 | +0.0 % |
| guilds_den | guild | 88.1 | guilds_den_twin | 88.1 | -0.0 % |
| ford_a | crossing_ford | 90.3 | ford_b | 89.2 | +1.2 % |
| ford_nest_twin | camp | 90.3 | ford_nest | 89.2 | +1.2 % |
| cache_b_twin | cache | 92.0 | cache_b | 92.1 | -0.1 % |
| third_node_twin | expansion | 93.0 | third_node | 94.1 | -1.2 % |
| rich_node_twin | expansion | 93.3 | rich_node | 93.2 | +0.0 % |
| rich_lodge | guild | 93.3 | rich_lodge_twin | 93.3 | +0.0 % |
| cache_a_twin | cache | 94.8 | cache_a | 94.9 | -0.1 % |
| rich_hollow | camp | 94.8 | rich_hollow_twin | 94.8 | -0.0 % |
| lairs_n_one | lair | 95.0 | lairs_n_one_twin | 94.8 | +0.3 % |
| guilds_lodge | guild | 96.3 | guilds_lodge_twin | 96.3 | +0.0 % |
| guilds_lodge_twin | guild | 96.8 | guilds_lodge | 96.9 | -0.2 % |
| stag_twin | camp | 97.1 | stag | 97.1 | -0.0 % |
| lairs_n_two_twin | lair | 97.3 | lairs_n_two | 97.4 | -0.1 % |
| bridge_road_a | crossing_bridge_road | 98.3 | bridge_road_b | 98.4 | -0.1 % |
| lairs_n_one_twin | lair | 101.1 | lairs_n_one | 87.0 | +13.9 % |
| guilds_den_twin | guild | 102.6 | guilds_den | 103.7 | -1.1 % |
| rich_lodge_twin | guild | 103.4 | rich_lodge | 103.4 | -0.0 % |
| tower_b_twin | point | 107.2 | tower_b | 107.3 | -0.1 % |
| rich_den_twin | guild | 107.5 | rich_den | 107.3 | +0.2 % |
| rich_hollow_twin | camp | 108.6 | rich_hollow | 110.9 | -2.0 % |
| post_b_twin | post | 108.9 | post_b | 107.8 | +1.0 % |
| lairs_w_one_twin | lair | 109.9 | lairs_w_one | 110.5 | -0.5 % |
| post_a_twin | post | 114.9 | post_a | 119.3 | -3.7 % |
| lairs_w_two_twin | lair | 117.5 | lairs_w_two | 117.6 | -0.1 % |
| home_b_twin | home_node | 118.8 | home_b | 118.9 | -0.1 % |
| home_a_twin | home_node | 119.3 | home_a | 119.4 | -0.0 % |
| wallow_twin | camp | 122.1 | wallow | 122.2 | -0.1 % |
| keep_t1 | keep | 133.8 | keep_t0 | 133.8 | +0.0 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| south-west | enemy keep (keep_t1) | 133.8 | 0.0 | 0:29 | 0:27 | 0:18 | 0:33 |
| south-west | nearest expansion (nat_node) | 48.4 | 0.0 | 0:11 | 0:10 | 0:06 | 0:12 |
| south-west | nearest point (tower_b) | 41.9 | 0.0 | 0:09 | 0:08 | 0:06 | 0:10 |
| south-west | nearest camp (wallow) | 35.7 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| south-west | crown (crown) | 63.4 | 0.0 | 0:14 | 0:13 | 0:08 | 0:16 |
| north-east | enemy keep (keep_t0) | 133.8 | 0.0 | 0:29 | 0:27 | 0:18 | 0:33 |
| north-east | nearest expansion (nat_node_twin) | 48.5 | 0.0 | 0:11 | 0:10 | 0:06 | 0:12 |
| north-east | nearest point (tower_b_twin) | 41.8 | 0.0 | 0:09 | 0:08 | 0:06 | 0:10 |
| north-east | nearest camp (wallow_twin) | 35.7 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| north-east | crown (crown) | 63.4 | 0.0 | 0:14 | 0:13 | 0:08 | 0:16 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_a | bridge_road | 6.0 | 4.5 | 5.5 | bridge_road_b | 4.5 |
| bridge_road_b | bridge_road | 6.0 | 4.5 | 5.5 | bridge_road_a | 4.5 |
| ford_a | ford | 7.0 | 5.5 | 6.5 | ford_b | 5.5 |
| ford_b | ford | 7.0 | 5.5 | 6.5 | ford_a | 5.5 |
| bridge_crown_a | bridge_lane | 8.0 | 6.4 | 7.4 | bridge_crown_b | 6.0 |
| bridge_crown_b | bridge_lane | 8.0 | 6.0 | 7.0 | bridge_crown_a | 6.4 |
| steps_a | steps | 6.0 | 4.3 | 5.3 | steps_b | 4.3 |
| steps_b | steps | 6.0 | 4.3 | 5.3 | steps_a | 4.3 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 63.4 | 5.1 | (-8.3, 6.2) | - |
| keep_t0 -> keep_t1 | 133.8 | 4.9 | (5.9, -9.4) | - |
| keep_t0 -> nat_node | 48.4 | 20.5 | (-43.3, 39.9) | - |
| keep_t1 -> crown | 63.4 | 5.1 | (8.5, -6.0) | - |
| keep_t1 -> nat_node_twin | 48.5 | 20.6 | (43.2, -40.1) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| south-west | keep_enemy | 116.00-150.00 | 133.83 | - |
| south-west | natural | 38.00-58.00 | 48.43 | - |
| south-west | rich | 65.00-95.00 | 79.39 | - |
| south-west | crown | 50.00-72.00 | 63.35 | - |
| north-east | keep_enemy | 116.00-150.00 | 133.83 | - |
| north-east | natural | 38.00-58.00 | 48.47 | - |
| north-east | rich | 65.00-95.00 | 79.39 | - |
| north-east | crown | 50.00-72.00 | 63.41 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |
| north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| south-west | 1 | 6 | 14 | 29 |
| north-east | 1 | 6 | 14 | 29 |


## Hottest metres (every spot-pair shortest path, 2080 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (5.5, 6.5) | 225 | 11 % |
| 2 | (-5.5, -6.5) | 212 | 10 % |
| 3 | (-0.5, 0.5) | 171 | 8 % |
| 4 | (9.5, 37.5) | 145 | 7 % |
| 5 | (-27.5, -22.5) | 140 | 7 % |
| 6 | (-12.5, -39.5) | 136 | 7 % |
| 7 | (-13.5, 7.5) | 133 | 6 % |
| 8 | (13.5, -7.5) | 121 | 6 % |
| 9 | (26.5, 21.5) | 120 | 6 % |
| 10 | (3.5, -6.5) | 106 | 5 % |


## Info findings (90)
| Check | Where | What |
|---|---|---|
| N3 | island 4 at (40.4, -43.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 24 at (-40.4, 43.9) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 24 islands on top of colliders (455 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | tower_a-well vs tower_a_twin-well_twin | 17.0 m vs 18.4 m (7.6 %) |
| F2 | tower_a-rich_lodge vs tower_a_twin-rich_lodge_twin | 28.6 m vs 26.8 m (6.3 %) |
| F2 | steps_a-crown vs steps_b-crown | 13.3 m vs 12.5 m (6.2 %) |
| F2 | third_node-well_twin vs third_node_twin-well | 25.2 m vs 26.8 m (6.1 %) |
| F2 | inn_tavern-bridge_crown_b vs inn_tavern_twin-bridge_crown_a | 26.6 m vs 25.2 m (5.3 %) |
| F2 | ford_nest-rich_den vs ford_nest_twin-rich_den_twin | 115.0 m vs 109.3 m (4.9 %) |
| F2 | third_node-rich_den vs third_node_twin-rich_den_twin | 131.3 m vs 124.8 m (4.9 %) |
| F2 | cache_a-lairs_w_one_twin vs cache_a_twin-lairs_w_one | 79.7 m vs 75.9 m (4.8 %) |
| F2 | nat_node-rich_den vs nat_node_twin-rich_den_twin | 85.7 m vs 81.6 m (4.8 %) |
| F2 | rich_den-guilds_lodge_twin vs rich_den_twin-guilds_lodge | 149.6 m vs 142.5 m (4.8 %) |
| F2 | guilds_lodge-steps_a vs guilds_lodge_twin-steps_b | 59.3 m vs 62.3 m (4.8 %) |
| F2 | lairs_n_one-ford_a vs lairs_n_one_twin-ford_b | 25.2 m vs 26.4 m (4.6 %) |
| F2 | rich_hollow-cache_a_twin vs rich_hollow_twin-cache_a | 109.0 m vs 104.0 m (4.5 %) |
| F2 | home_b-cache_a_twin vs home_b_twin-cache_a | 87.8 m vs 92.0 m (4.5 %) |
| F2 | cache_b-ford_a vs cache_b_twin-ford_b | 73.2 m vs 69.9 m (4.5 %) |
| F2 | wallow-inn_peddler_twin vs wallow_twin-inn_peddler | 64.7 m vs 67.7 m (4.5 %) |
| F2 | tower_b-shrine_twin vs tower_b_twin-shrine | 52.2 m vs 54.7 m (4.4 %) |
| F2 | wallow-post_a_twin vs wallow_twin-post_a | 94.9 m vs 90.7 m (4.4 %) |
| F2 | guilds_den-lairs_w_two_twin vs guilds_den_twin-lairs_w_two | 132.6 m vs 126.7 m (4.4 %) |
| F2 | post_b-lairs_w_one_twin vs post_b_twin-lairs_w_one | 74.4 m vs 77.8 m (4.4 %) |
| F2 | lairs_w_two-steps_a vs lairs_w_two_twin-steps_b | 47.8 m vs 49.9 m (4.3 %) |
| F2 | keep_t0-steps_a vs keep_t1-steps_b | 67.2 m vs 64.3 m (4.3 %) |
| F2 | cache_b-bridge_road_a vs cache_b_twin-bridge_road_b | 83.0 m vs 79.4 m (4.2 %) |
| F2 | keep_t0-tower_a vs keep_t1-tower_a_twin | 85.0 m vs 88.8 m (4.2 %) |
| F2 | lairs_n_one-lairs_n_two_twin vs lairs_n_one_twin-lairs_n_two | 134.9 m vs 129.3 m (4.1 %) |
| F2 | shrine-post_b_twin vs shrine_twin-post_b | 56.0 m vs 53.7 m (4.1 %) |
| F2 | inn_peddler-lairs_n_one vs inn_peddler_twin-lairs_n_one_twin | 44.7 m vs 46.6 m (4.1 %) |
| F2 | tower_a-rich_lodge_twin vs tower_a_twin-rich_lodge | 119.9 m vs 124.8 m (4.0 %) |
| F2 | tower_a-guilds_den_twin vs tower_a_twin-guilds_den | 120.0 m vs 124.9 m (3.9 %) |
| F2 | nat_node-ford_nest_twin vs nat_node_twin-ford_nest | 60.5 m vs 63.0 m (3.9 %) |
| F2 | nat_node-ford_a vs nat_node_twin-ford_b | 60.5 m vs 63.0 m (3.9 %) |
| F2 | lairs_w_two-ford_a vs lairs_w_two_twin-ford_b | 56.4 m vs 58.7 m (3.9 %) |
| F2 | tower_a-lairs_n_two_twin vs tower_a_twin-lairs_n_two | 110.7 m vs 115.2 m (3.9 %) |
| F2 | third_node-lairs_w_one_twin vs third_node_twin-lairs_w_one | 57.1 m vs 59.4 m (3.9 %) |
| F2 | tower_a-rich_den_twin vs tower_a_twin-rich_den | 123.4 m vs 128.3 m (3.8 %) |
| F2 | post_a-cache_a vs post_a_twin-cache_a_twin | 27.0 m vs 25.9 m (3.8 %) |
| F2 | keep_t0-post_a_twin vs keep_t1-post_a | 114.9 m vs 119.3 m (3.7 %) |
| F2 | tower_a-rich_hollow_twin vs tower_a_twin-rich_hollow | 127.2 m vs 132.2 m (3.7 %) |
| F2 | guilds_den-guilds_lodge_twin vs guilds_den_twin-guilds_lodge | 146.2 m vs 140.7 m (3.7 %) |
| F2 | cache_a-ford_a vs cache_a_twin-ford_b | 45.7 m vs 44.1 m (3.6 %) |
| F2 | ford_nest-cache_a_twin vs ford_nest_twin-cache_a | 44.1 m vs 45.7 m (3.6 %) |
| F2 | third_node-lairs_w_two_twin vs third_node_twin-lairs_w_two | 52.2 m vs 54.2 m (3.6 %) |
| F2 | shrine-wallow_twin vs shrine_twin-wallow | 68.6 m vs 66.2 m (3.5 %) |
| F2 | post_b-lairs_w_two_twin vs post_b_twin-lairs_w_two | 73.7 m vs 76.4 m (3.5 %) |
| F2 | well-bridge_crown_b vs well_twin-bridge_crown_a | 41.6 m vs 40.2 m (3.4 %) |
| F2 | inn_peddler-bridge_road_a vs inn_peddler_twin-bridge_road_b | 44.5 m vs 43.0 m (3.4 %) |
| F2 | lairs_w_one-steps_a vs lairs_w_one_twin-steps_b | 41.1 m vs 42.5 m (3.3 %) |
| F2 | stag-bridge_road_b vs stag_twin-bridge_road_a | 77.7 m vs 80.4 m (3.3 %) |
| F2 | ford_nest-lairs_w_one vs ford_nest_twin-lairs_w_one_twin | 69.2 m vs 66.9 m (3.3 %) |
| F2 | inn_tavern-ford_b vs inn_tavern_twin-ford_a | 66.9 m vs 64.7 m (3.3 %) |
| F2 | well-cache_b_twin vs well_twin-cache_b | 47.1 m vs 45.6 m (3.2 %) |
| F2 | home_a-tower_a vs home_a_twin-tower_a_twin | 76.4 m vs 79.0 m (3.2 %) |
| F2 | wallow-bridge_road_a vs wallow_twin-bridge_road_b | 111.5 m vs 108.0 m (3.2 %) |
| F2 | tower_a-ford_nest vs tower_a_twin-ford_nest_twin | 93.5 m vs 96.5 m (3.1 %) |
| F2 | tower_a-ford_b vs tower_a_twin-ford_a | 93.5 m vs 96.5 m (3.1 %) |
| F2 | home_b-lairs_n_one vs home_b_twin-lairs_n_one_twin | 98.1 m vs 101.3 m (3.1 %) |
| F2 | tower_b-rich_hollow_twin vs tower_b_twin-rich_hollow | 66.1 m vs 68.2 m (3.1 %) |
| F2 | lairs_n_one-bridge_crown_a vs lairs_n_one_twin-bridge_crown_b | 69.0 m vs 71.2 m (3.0 %) |
| F2 | post_a-steps_a vs post_a_twin-steps_b | 46.1 m vs 47.4 m (2.9 %) |
| F2 | tower_b-cache_a_twin vs tower_b_twin-cache_a | 61.3 m vs 63.1 m (2.8 %) |
| F2 | stag-cache_b_twin vs stag_twin-cache_b | 65.3 m vs 63.5 m (2.8 %) |
| F2 | wallow-lairs_n_one vs wallow_twin-lairs_n_one_twin | 111.1 m vs 114.2 m (2.7 %) |
| F2 | ford_nest-ford_a vs ford_nest_twin-ford_b | 89.8 m vs 92.2 m (2.6 %) |
| F2 | guilds_lodge-crown vs guilds_lodge_twin-crown | 71.8 m vs 73.7 m (2.6 %) |
| F2 | lairs_w_one-bridge_crown_b vs lairs_w_one_twin-bridge_crown_a | 61.1 m vs 59.5 m (2.5 %) |
| F2 | guilds_lodge-lairs_n_two_twin vs guilds_lodge_twin-lairs_n_two | 145.4 m vs 141.8 m (2.5 %) |
| F2 | guilds_lodge-bridge_crown_a vs guilds_lodge_twin-bridge_crown_b | 79.6 m vs 81.6 m (2.5 %) |
| F2 | nat_node-bridge_road_a vs nat_node_twin-bridge_road_b | 74.3 m vs 72.5 m (2.5 %) |
| F2 | bridge_road_a-ford_b vs bridge_road_b-ford_a | 101.1 m vs 98.7 m (2.4 %) |
| F2 | lairs_w_one-bridge_road_a vs lairs_w_one_twin-bridge_road_b | 66.2 m vs 64.6 m (2.4 %) |
| F2 | guilds_den-bridge_crown_a vs guilds_den_twin-bridge_crown_b | 76.0 m vs 77.8 m (2.4 %) |
| F2 | tower_b-ford_a vs tower_b_twin-ford_b | 83.6 m vs 85.6 m (2.3 %) |
| F2 | tower_b-ford_nest_twin vs tower_b_twin-ford_nest | 83.6 m vs 85.6 m (2.3 %) |
| F2 | home_b-rich_hollow_twin vs home_b_twin-rich_hollow | 92.1 m vs 94.2 m (2.3 %) |
| F2 | nat_node-lairs_n_one vs nat_node_twin-lairs_n_one_twin | 74.5 m vs 76.3 m (2.3 %) |
| F2 | wallow-cache_a_twin vs wallow_twin-cache_a | 75.3 m vs 77.0 m (2.3 %) |
| F2 | rich_node-bridge_crown_b vs rich_node_twin-bridge_crown_a | 63.2 m vs 61.7 m (2.3 %) |
| F2 | home_b-ford_nest_twin vs home_b_twin-ford_nest | 90.6 m vs 88.6 m (2.2 %) |
| F2 | home_b-ford_a vs home_b_twin-ford_b | 90.6 m vs 88.6 m (2.2 %) |
| F2 | tower_a-crown vs tower_a_twin-crown | 48.1 m vs 49.1 m (2.2 %) |
| F2 | nat_node-rich_node vs nat_node_twin-rich_node_twin | 67.7 m vs 69.1 m (2.1 %) |
| F2 | post_b-ford_a vs post_b_twin-ford_b | 96.5 m vs 98.6 m (2.1 %) |
| F2 | guilds_lodge-steps_b vs guilds_lodge_twin-steps_a | 84.6 m vs 86.5 m (2.1 %) |
| F2 | lairs_n_two-bridge_crown_b vs lairs_n_two_twin-bridge_crown_a | 68.0 m vs 66.6 m (2.1 %) |
| F2 | well-shrine_twin vs well_twin-shrine | 63.2 m vs 61.9 m (2.1 %) |
| F2 | cache_b-lairs_n_one vs cache_b_twin-lairs_n_one_twin | 81.5 m vs 83.2 m (2.1 %) |
| F2 | keep_t0-rich_hollow_twin vs keep_t1-rich_hollow | 108.6 m vs 110.9 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 65 sources) 308.74 s.
- Map Lab v2 (map-production.md 2.5): layout thornwater_s40, 2 seats, rules tempo standard, 0 fixable findings.
- Navmesh raster 11.20 s (856 polygons, 230400 cells of 0.25 m), spot / mirror checks 4.31 s, 2080 paths 6.58 s.
- Map Thornwater (seed 40), scene res://docs/tools/world_forge/out/thornwater_s40/preview.tscn, sim mode off; level load + navmesh bake 4.2 s (946 frames), lab 345.7 s. Spec: docs/design/map-production.md.
