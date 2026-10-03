# Map Lab: Thornwater (seed 4) scorecard: world_forge_thornwater_s4

2026-10-03 01:23 · lab v1.0 · 733.59 s · scanned 57 spots

## Result: **WARN** · score **96 / 100**

0 FAIL · 3 WARN · 15 PASS · 3 info checks; findings: 0 FAIL, 47 WARN, 103 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): stag-steps_a vs stag_twin-steps_b: 34.3 m vs 27.8 m (19.2 %) -> units walk stag-steps_a the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 670 / 812 pairs within 2 % (0 FAIL, 42 WARN, 100 info))_
2. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest peddler: 52.0 m vs 54.1 m between seats (3.9 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 9 / 10 clean (0 FAIL, 1 WARN))_
3. **Clearances (roads, crossings, spacing)** (WARN): nat_node: node 7.4 m from crossing bridge_crown_a (want >= 8) -> move it off the crossing approach (auto-fix) _(from R4 45 / 49 clean (0 FAIL, 4 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 691 polygons, main area 13015 m² (90 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 57 / 57 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 2 / 2 clean, 3 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 49 spots ok, 1.00x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 2.5x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 57 / 57 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 57 / 57 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 812 / 812 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 670 / 812 pairs within 2 % (0 FAIL, 42 WARN, 100 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 66 | 9 / 10 clean (0 FAIL, 1 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
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
| R4 | Clearances (roads, crossings, spacing) | **WARN** 66 | 45 / 49 clean (0 FAIL, 4 WARN) | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted); spots >= 3 m, structures >= 6 m apart, one den + one lodge per image |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (480 x 480 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | stag-steps_a vs stag_twin-steps_b | 34.3 m vs 27.8 m (19.2 %) | units walk stag-steps_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-inn_tavern vs stag_twin-inn_tavern_twin | 26.1 m vs 21.6 m (17.0 %) | units walk stag-inn_tavern the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-crown vs stag_twin-crown | 46.7 m vs 39.6 m (15.3 %) | units walk stag-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_road_a-bridge_crown_a vs bridge_road_b-bridge_crown_b | 61.7 m vs 72.1 m (14.4 %) | units walk bridge_road_b-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-steps_b vs post_b_twin-steps_a | 58.7 m vs 52.3 m (10.9 %) | units walk post_b-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-steps_b vs stag_twin-steps_a | 53.2 m vs 59.6 m (10.8 %) | units walk stag_twin-steps_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b-lairs_w_one vs cache_b_twin-lairs_w_one_twin | 48.2 m vs 53.9 m (10.7 %) | units walk cache_b_twin-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-lairs_n_one_twin vs shrine_twin-lairs_n_one | 75.9 m vs 84.9 m (10.6 %) | units walk shrine_twin-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-lairs_w_two vs post_b_twin-lairs_w_two_twin | 85.3 m vs 95.2 m (10.4 %) | units walk post_b_twin-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-home_b_twin vs home_a_twin-home_b | 112.5 m vs 125.4 m (10.3 %) | units walk home_a_twin-home_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-inn_tavern_twin vs stag_twin-inn_tavern | 61.2 m vs 67.9 m (9.9 %) | units walk stag_twin-inn_tavern the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-guilds_lodge_twin vs shrine_twin-guilds_lodge | 84.9 m vs 93.9 m (9.6 %) | units walk shrine_twin-guilds_lodge the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-lairs_w_two_twin vs tower_a_twin-lairs_w_two | 104.4 m vs 115.3 m (9.5 %) | units walk tower_a_twin-lairs_w_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_road_a-crown vs bridge_road_b-crown | 54.0 m vs 59.6 m (9.4 %) | units walk bridge_road_b-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den-cache_b_twin vs guilds_den_twin-cache_b | 62.0 m vs 67.3 m (8.0 %) | units walk guilds_den_twin-cache_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_w_two-crown vs lairs_w_two_twin-crown | 64.9 m vs 60.0 m (7.7 %) | units walk lairs_w_two-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b-lairs_w_two vs cache_b_twin-lairs_w_two_twin | 65.6 m vs 70.9 m (7.4 %) | units walk cache_b_twin-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-guilds_den_twin vs nat_node_twin-guilds_den | 74.9 m vs 80.8 m (7.4 %) | units walk nat_node_twin-guilds_den the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-inn_peddler_twin vs post_b_twin-inn_peddler | 59.9 m vs 55.5 m (7.4 %) | units walk post_b-inn_peddler_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-bridge_crown_b vs cache_a_twin-bridge_crown_a | 38.3 m vs 41.3 m (7.2 %) | units walk cache_a_twin-bridge_crown_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-inn_tavern vs rich_node_twin-inn_tavern_twin | 33.2 m vs 35.8 m (7.2 %) | units walk rich_node_twin-inn_tavern_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_tavern-cache_b_twin vs inn_tavern_twin-cache_b | 43.0 m vs 46.1 m (6.6 %) | units walk inn_tavern_twin-cache_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow-lairs_n_one vs wallow_twin-lairs_n_one_twin | 117.7 m vs 109.9 m (6.6 %) | units walk wallow-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-cache_b_twin vs cache_a_twin-cache_b | 55.6 m vs 59.4 m (6.3 %) | units walk cache_a_twin-cache_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-wallow vs shrine_twin-wallow_twin | 51.9 m vs 55.4 m (6.2 %) | units walk shrine_twin-wallow_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-cache_a_twin vs post_b_twin-cache_a | 66.8 m vs 62.7 m (6.2 %) | units walk post_b-cache_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_w_one_twin vs keep_t1-lairs_w_one | 106.5 m vs 100.0 m (6.1 %) | units walk keep_t0-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_w_two-bridge_crown_b vs lairs_w_two_twin-bridge_crown_a | 69.9 m vs 74.5 m (6.1 %) | units walk lairs_w_two_twin-bridge_crown_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-inn_peddler vs home_b_twin-inn_peddler_twin | 57.3 m vs 53.8 m (6.1 %) | units walk home_b-inn_peddler the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-guilds_lodge vs tower_b_twin-guilds_lodge_twin | 110.1 m vs 103.5 m (6.0 %) | units walk tower_b-guilds_lodge the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_peddler-lairs_n_two_twin vs inn_peddler_twin-lairs_n_two | 90.8 m vs 96.6 m (6.0 %) | units walk inn_peddler_twin-lairs_n_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_peddler-lairs_w_two_twin vs inn_peddler_twin-lairs_w_two | 92.1 m vs 97.7 m (5.8 %) | units walk inn_peddler_twin-lairs_w_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow-cache_a vs wallow_twin-cache_a_twin | 57.2 m vs 60.7 m (5.7 %) | units walk wallow_twin-cache_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_w_one-bridge_road_b vs lairs_w_one_twin-bridge_road_a | 80.7 m vs 76.1 m (5.7 %) | units walk lairs_w_one-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-lairs_w_one vs nat_node_twin-lairs_w_one_twin | 39.1 m vs 41.4 m (5.5 %) | units walk nat_node_twin-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_peddler-lairs_n_one_twin vs inn_peddler_twin-lairs_n_one | 86.1 m vs 91.1 m (5.4 %) | units walk inn_peddler_twin-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge-lairs_w_one_twin vs guilds_lodge_twin-lairs_w_one | 113.0 m vs 106.9 m (5.4 %) | units walk guilds_lodge-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-crown vs rich_node_twin-crown | 53.8 m vs 56.9 m (5.4 %) | units walk rich_node_twin-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_a-bridge_road_b vs post_a_twin-bridge_road_a | 89.6 m vs 84.8 m (5.4 %) | units walk post_a-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-lairs_n_one vs post_b_twin-lairs_n_one_twin | 118.6 m vs 112.5 m (5.1 %) | units walk post_b-lairs_n_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-stag_twin vs rich_node_twin-stag | 91.9 m vs 96.7 m (5.0 %) | units walk rich_node_twin-stag the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge-steps_a vs guilds_lodge_twin-steps_b | 58.8 m vs 61.9 m (5.0 %) | units walk guilds_lodge_twin-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest peddler | 52.0 m vs 54.1 m between seats (3.9 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | R4 | nat_node | node 7.4 m from crossing bridge_crown_a (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | nat_node_twin | node 7.4 m from crossing bridge_crown_b (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | wallow | camp 6.0 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | wallow_twin | camp 6.0 m from a road centre line (want >= 9) | push it off the road (auto-fix) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-41.1, 43.9) | (-37.4, 43.6) | keep_t1 | (-37.4, 43.6) | 0.0 |
| keep_t1 | keep | (41.1, -43.9) | (37.4, -43.6) | keep_t0 | (37.4, -43.6) | 0.0 |
| home_a | home_node | (-44.4, 35.0) | (-44.4, 34.9) | home_a_twin | (-44.4, 34.9) | 0.0 |
| home_a_twin | home_node | (44.4, -35.0) | (44.4, -34.9) | home_a | (44.4, -34.9) | 0.0 |
| home_b | home_node | (-32.0, 46.6) | (-31.9, 46.6) | home_b_twin | (-31.9, 46.6) | 0.0 |
| home_b_twin | home_node | (32.0, -46.6) | (31.9, -46.6) | home_b | (31.9, -46.6) | 0.0 |
| nat_node | expansion | (-8.3, 16.7) | (-8.1, 16.6) | nat_node_twin | (-8.1, 16.6) | 0.0 |
| nat_node_twin | expansion | (8.3, -16.7) | (8.1, -16.6) | nat_node | (8.1, -16.6) | 0.0 |
| rich_node | expansion | (-40.1, -36.3) | (-39.9, -36.4) | rich_node_twin | (-39.9, -36.4) | 0.0 |
| rich_node_twin | expansion | (40.1, 36.3) | (39.9, 36.4) | rich_node | (39.9, 36.4) | 0.0 |
| tower_a | point | (-28.8, -40.4) | (-28.6, -40.4) | tower_a_twin | (-28.6, -40.4) | 0.0 |
| tower_a_twin | point | (28.8, 40.4) | (28.6, 40.4) | tower_a | (28.6, 40.4) | 0.0 |
| tower_b | point | (-4.3, 40.5) | (-4.1, 40.4) | tower_b_twin | (-4.1, 40.4) | 0.0 |
| tower_b_twin | point | (4.3, -40.5) | (4.1, -40.4) | tower_b | (4.1, -40.4) | 0.0 |
| well | point | (-31.8, -26.0) | (-31.6, -25.9) | well_twin | (-31.6, -25.9) | 0.0 |
| well_twin | point | (31.8, 26.0) | (31.6, 25.9) | well | (31.6, 25.9) | 0.0 |
| shrine | point | (-17.5, 2.3) | (-17.4, 2.1) | shrine_twin | (-17.4, 2.1) | 0.0 |
| shrine_twin | point | (17.5, -2.3) | (17.4, -2.1) | shrine | (17.4, -2.1) | 0.0 |
| wallow | camp | (-13.2, 54.0) | (-13.1, 53.9) | wallow_twin | (-13.1, 53.9) | 0.0 |
| wallow_twin | camp | (13.2, -54.0) | (13.1, -53.9) | wallow | (13.1, -53.9) | 0.0 |
| ford_nest | camp | (13.7, 38.8) | (13.6, 38.6) | ford_nest_twin | (13.6, 38.6) | 0.0 |
| ford_nest_twin | camp | (-13.7, -38.8) | (-13.6, -38.6) | ford_nest | (-13.6, -38.6) | 0.0 |
| stag | camp | (-36.9, -8.2) | (-36.9, -8.1) | stag_twin | (-36.9, -8.1) | 0.0 |
| stag_twin | camp | (36.9, 8.2) | (36.9, 8.1) | stag | (36.9, 8.1) | 0.0 |
| inn_tavern | tavern | (-15.9, -13.4) | (-15.9, -13.4) | inn_tavern_twin | (-15.9, -13.4) | 0.0 |
| inn_tavern_twin | tavern | (15.9, 13.4) | (15.9, 13.4) | inn_tavern | (15.9, 13.4) | 0.0 |
| post_a | post | (-53.5, 0.5) | (-53.4, 0.4) | post_a_twin | (-53.4, 0.4) | 0.0 |
| post_a_twin | post | (53.5, -0.5) | (53.4, -0.4) | post_a | (53.4, -0.4) | 0.0 |
| post_b | post | (0.1, 54.0) | (0.1, 53.9) | post_b_twin | (0.1, 53.9) | 0.0 |
| post_b_twin | post | (-0.1, -54.0) | (-0.1, -53.9) | post_b | (-0.1, -53.9) | 0.0 |
| guilds_den | guild | (-55.2, -45.4) | (-55.1, -45.4) | guilds_den_twin | (-55.1, -45.4) | 0.0 |
| guilds_den_twin | guild | (55.2, 45.4) | (55.1, 45.4) | guilds_den | (55.1, 45.4) | 0.0 |
| guilds_lodge | guild | (-46.8, -54.0) | (-46.6, -53.9) | guilds_lodge_twin | (-46.6, -53.9) | 0.0 |
| guilds_lodge_twin | guild | (46.8, 54.0) | (46.6, 53.9) | guilds_lodge | (46.6, 53.9) | 0.0 |
| inn_peddler | peddler | (-23.2, -6.6) | (-23.1, -6.4) | inn_peddler_twin | (-23.1, -6.4) | 0.0 |
| inn_peddler_twin | peddler | (23.2, 6.6) | (23.1, 6.4) | inn_peddler | (23.1, 6.4) | 0.0 |
| cache_a | cache | (-28.1, -1.0) | (-28.1, -0.9) | cache_a_twin | (-28.1, -0.9) | 0.0 |
| cache_a_twin | cache | (28.1, 1.0) | (28.1, 0.9) | cache_a | (28.1, 0.9) | 0.0 |
| cache_b | cache | (-4.2, 29.3) | (-4.1, 29.1) | cache_b_twin | (-4.1, 29.1) | 0.0 |
| cache_b_twin | cache | (4.2, -29.3) | (4.1, -29.1) | cache_b | (4.1, -29.1) | 0.0 |
| lairs_w_one | lair | (-45.2, 3.9) | (-45.1, 3.9) | lairs_w_one_twin | (-45.1, 3.9) | 0.0 |
| lairs_w_one_twin | lair | (45.2, -3.9) | (45.1, -3.9) | lairs_w_one | (45.1, -3.9) | 0.0 |
| lairs_w_two | lair | (-57.6, -9.3) | (-57.4, -9.1) | lairs_w_two_twin | (-57.4, -9.1) | 0.0 |
| lairs_w_two_twin | lair | (57.6, 9.3) | (57.4, 9.1) | lairs_w_two | (57.4, 9.1) | 0.0 |
| lairs_n_one | lair | (-38.4, -50.3) | (-38.4, -50.1) | lairs_n_one_twin | (-38.4, -50.1) | 0.0 |
| lairs_n_one_twin | lair | (38.4, 50.3) | (38.4, 50.1) | lairs_n_one | (38.4, 50.1) | 0.0 |
| lairs_n_two | lair | (-51.6, -37.9) | (-51.4, -37.9) | lairs_n_two_twin | (-51.4, -37.9) | 0.0 |
| lairs_n_two_twin | lair | (51.6, 37.9) | (51.4, 37.9) | lairs_n_two | (51.4, 37.9) | 0.0 |
| bridge_road_a | crossing_bridge_road | (-16.1, -49.1) | (-16.1, -48.9) | bridge_road_b | (-16.1, -48.9) | 0.0 |
| bridge_road_b | crossing_bridge_road | (16.1, 49.1) | (16.1, 48.9) | bridge_road_a | (16.1, 48.9) | 0.0 |
| ford_a | crossing_ford | (-13.7, -38.8) | (-13.6, -38.6) | ford_b | (-13.6, -38.6) | 0.0 |
| ford_b | crossing_ford | (13.7, 38.8) | (13.6, 38.6) | ford_a | (13.6, 38.6) | 0.0 |
| bridge_crown_a | crossing_bridge_lane | (-8.7, 9.3) | (-8.6, 9.1) | bridge_crown_b | (-8.6, 9.1) | 0.0 |
| bridge_crown_b | crossing_bridge_lane | (8.7, -9.3) | (8.6, -9.1) | bridge_crown_a | (8.6, -9.1) | 0.0 |
| steps_a | crossing_steps | (-9.3, -8.7) | (-9.1, -8.6) | steps_b | (-9.1, -8.6) | 0.0 |
| steps_b | crossing_steps | (9.3, 8.7) | (9.1, 8.6) | steps_a | (9.1, 8.6) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, -0.1) | 0.4 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 142)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | stag - steps_a | 34.3 | stag_twin - steps_b | 27.8 | +19.2 % |
| 2 | stag - inn_tavern | 26.1 | stag_twin - inn_tavern_twin | 21.6 | +17.0 % |
| 3 | stag - crown | 46.7 | stag_twin - crown | 39.6 | +15.3 % |
| 4 | bridge_road_a - bridge_crown_a | 61.7 | bridge_road_b - bridge_crown_b | 72.1 | -14.4 % |
| 5 | post_b - steps_b | 58.7 | post_b_twin - steps_a | 52.3 | +10.9 % |
| 6 | stag - steps_b | 53.2 | stag_twin - steps_a | 59.6 | -10.8 % |
| 7 | cache_b - lairs_w_one | 48.2 | cache_b_twin - lairs_w_one_twin | 53.9 | -10.7 % |
| 8 | shrine - lairs_n_one_twin | 75.9 | shrine_twin - lairs_n_one | 84.9 | -10.6 % |
| 9 | post_b - lairs_w_two | 85.3 | post_b_twin - lairs_w_two_twin | 95.2 | -10.4 % |
| 10 | home_a - home_b_twin | 112.5 | home_a_twin - home_b | 125.4 | -10.3 % |
| 11 | stag - inn_tavern_twin | 61.2 | stag_twin - inn_tavern | 67.9 | -9.9 % |
| 12 | shrine - guilds_lodge_twin | 84.9 | shrine_twin - guilds_lodge | 93.9 | -9.6 % |
| 13 | tower_a - lairs_w_two_twin | 104.4 | tower_a_twin - lairs_w_two | 115.3 | -9.5 % |
| 14 | bridge_road_a - crown | 54.0 | bridge_road_b - crown | 59.6 | -9.4 % |
| 15 | guilds_den - cache_b_twin | 62.0 | guilds_den_twin - cache_b | 67.3 | -8.0 % |
| 16 | cache_a - bridge_crown_a | 22.1 | cache_a_twin - bridge_crown_b | 23.9 | -7.7 % |
| 17 | lairs_w_two - crown | 64.9 | lairs_w_two_twin - crown | 60.0 | +7.7 % |
| 18 | cache_b - lairs_w_two | 65.6 | cache_b_twin - lairs_w_two_twin | 70.9 | -7.4 % |
| 19 | nat_node - guilds_den_twin | 74.9 | nat_node_twin - guilds_den | 80.8 | -7.4 % |
| 20 | post_b - inn_peddler_twin | 59.9 | post_b_twin - inn_peddler | 55.5 | +7.4 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 39.8 (nat_node) | 33.4 (tower_b) | 26.3 (wallow) | 40.5 (lairs_w_one) | 61.4 (inn_tavern) | 38.9 (post_b) | 54.1 (inn_peddler) | 36.3 (cache_b) | 57.4 (crown) | 114.9 |
| north-east | 39.8 (nat_node_twin) | 33.4 (tower_b_twin) | 26.3 (wallow_twin) | 40.5 (lairs_w_one_twin) | 61.5 (inn_tavern_twin) | 38.9 (post_b_twin) | 52.0 (inn_peddler_twin) | 36.3 (cache_b_twin) | 57.4 (crown) | 114.9 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| home_b | home_node | 6.3 | home_b_twin | 6.3 | +0.0 % |
| home_a | home_node | 12.0 | home_a_twin | 11.9 | +0.7 % |
| wallow | camp | 26.3 | wallow_twin | 26.3 | +0.0 % |
| tower_b | point | 33.4 | tower_b_twin | 33.4 | -0.0 % |
| cache_b | cache | 36.3 | cache_b_twin | 36.3 | +0.0 % |
| post_b | post | 38.9 | post_b_twin | 38.9 | -0.0 % |
| nat_node | expansion | 39.8 | nat_node_twin | 39.8 | +0.0 % |
| lairs_w_one | lair | 40.5 | lairs_w_one_twin | 40.5 | +0.0 % |
| bridge_crown_a | crossing_bridge_lane | 44.9 | bridge_crown_b | 44.9 | +0.0 % |
| cache_a | cache | 45.5 | cache_a_twin | 45.5 | +0.0 % |
| post_a | post | 46.3 | post_a_twin | 46.3 | +0.0 % |
| shrine | point | 47.2 | shrine_twin | 47.1 | +0.1 % |
| ford_nest | camp | 51.2 | ford_nest_twin | 51.2 | +0.0 % |
| ford_b | crossing_ford | 51.2 | ford_a | 51.2 | +0.0 % |
| stag | camp | 51.8 | stag_twin | 51.8 | +0.0 % |
| bridge_road_b | crossing_bridge_road | 53.8 | bridge_road_a | 53.8 | +0.0 % |
| inn_peddler | peddler | 54.1 | inn_peddler_twin | 52.0 | +3.9 % |
| lairs_w_two | lair | 56.6 | lairs_w_two_twin | 56.6 | +0.0 % |
| crown | crown | 57.4 | crown | 57.4 | +0.0 % |
| inn_tavern | tavern | 61.4 | inn_tavern_twin | 61.5 | -0.1 % |
| steps_b | crossing_steps | 61.6 | steps_a | 61.5 | +0.2 % |
| steps_a | crossing_steps | 61.9 | steps_b | 64.4 | -3.8 % |
| tower_a_twin | point | 66.1 | tower_a | 66.1 | +0.0 % |
| inn_tavern_twin | tavern | 69.6 | inn_tavern | 69.4 | +0.2 % |
| well | point | 69.8 | well_twin | 69.8 | +0.0 % |
| bridge_crown_b | crossing_bridge_lane | 70.0 | bridge_crown_a | 70.0 | +0.0 % |
| well_twin | point | 72.4 | well | 72.4 | +0.0 % |
| inn_peddler_twin | peddler | 75.7 | inn_peddler | 75.6 | +0.1 % |
| nat_node_twin | expansion | 75.9 | nat_node | 76.0 | -0.0 % |
| rich_node_twin | expansion | 77.6 | rich_node | 77.6 | -0.0 % |
| lairs_n_one_twin | lair | 77.6 | lairs_n_one | 77.7 | -0.1 % |
| shrine_twin | point | 79.7 | shrine | 76.3 | +4.3 % |
| rich_node | expansion | 80.2 | rich_node_twin | 80.2 | -0.0 % |
| cache_a_twin | cache | 82.1 | cache_a | 82.0 | +0.1 % |
| lairs_n_two | lair | 82.7 | lairs_n_two_twin | 82.7 | +0.0 % |
| tower_a | point | 84.5 | tower_a_twin | 84.5 | +0.0 % |
| guilds_lodge_twin | guild | 86.7 | guilds_lodge | 86.7 | -0.1 % |
| ford_a | crossing_ford | 87.5 | ford_b | 87.5 | -0.0 % |
| ford_nest_twin | camp | 87.5 | ford_nest | 87.5 | -0.0 % |
| cache_b_twin | cache | 88.6 | cache_b | 88.6 | -0.0 % |
| lairs_n_two_twin | lair | 88.9 | lairs_n_two | 88.9 | +0.0 % |
| stag_twin | camp | 89.3 | stag | 89.2 | +0.1 % |
| guilds_den | guild | 90.8 | guilds_den_twin | 90.8 | +0.0 % |
| guilds_den_twin | guild | 93.3 | guilds_den | 92.8 | +0.5 % |
| lairs_n_one | lair | 94.1 | lairs_n_one_twin | 94.1 | +0.0 % |
| bridge_road_a | crossing_bridge_road | 96.1 | bridge_road_b | 96.0 | +0.0 % |
| guilds_lodge | guild | 97.9 | guilds_lodge_twin | 97.9 | +0.0 % |
| tower_b_twin | point | 99.7 | tower_b | 99.7 | -0.0 % |
| lairs_w_two_twin | lair | 103.1 | lairs_w_two | 103.1 | +0.0 % |
| lairs_w_one_twin | lair | 106.5 | lairs_w_one | 100.0 | +6.1 % |
| post_a_twin | post | 107.0 | post_a | 106.9 | +0.0 % |
| post_b_twin | post | 107.9 | post_b | 107.9 | -0.0 % |
| wallow_twin | camp | 113.5 | wallow | 113.5 | -0.0 % |
| home_a_twin | home_node | 113.6 | home_a | 113.6 | +0.0 % |
| home_b_twin | home_node | 113.8 | home_b | 113.8 | -0.0 % |
| keep_t1 | keep | 114.9 | keep_t0 | 114.9 | +0.0 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| south-west | enemy keep (keep_t1) | 114.9 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| south-west | nearest expansion (nat_node) | 39.8 | 0.0 | 0:09 | 0:08 | 0:05 | 0:10 |
| south-west | nearest point (tower_b) | 33.4 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| south-west | nearest camp (wallow) | 26.3 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| south-west | crown (crown) | 57.4 | 0.0 | 0:12 | 0:11 | 0:08 | 0:14 |
| north-east | enemy keep (keep_t0) | 114.9 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| north-east | nearest expansion (nat_node_twin) | 39.8 | 0.0 | 0:09 | 0:08 | 0:05 | 0:10 |
| north-east | nearest point (tower_b_twin) | 33.4 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| north-east | nearest camp (wallow_twin) | 26.3 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| north-east | crown (crown) | 57.4 | 0.0 | 0:12 | 0:11 | 0:08 | 0:14 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_a | bridge_road | 6.0 | 4.4 | 5.4 | bridge_road_b | 4.4 |
| bridge_road_b | bridge_road | 6.0 | 4.4 | 5.4 | bridge_road_a | 4.4 |
| ford_a | ford | 7.0 | 5.1 | 6.1 | ford_b | 5.1 |
| ford_b | ford | 7.0 | 5.1 | 6.1 | ford_a | 5.1 |
| bridge_crown_a | bridge_lane | 8.0 | 6.0 | 7.0 | bridge_crown_b | 6.0 |
| bridge_crown_b | bridge_lane | 8.0 | 6.0 | 7.0 | bridge_crown_a | 6.0 |
| steps_a | steps | 6.0 | 4.3 | 5.3 | steps_b | 4.3 |
| steps_b | steps | 6.0 | 4.3 | 5.3 | steps_a | 4.3 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 57.4 | 4.9 | (-6.7, 8.0) | - |
| keep_t0 -> keep_t1 | 114.9 | 4.8 | (6.9, -8.0) | - |
| keep_t0 -> nat_node | 39.8 | 32.8 | (-12.4, 20.6) | - |
| keep_t1 -> crown | 57.5 | 5.0 | (6.9, -7.8) | - |
| keep_t1 -> nat_node_twin | 39.8 | 32.8 | (12.4, -20.6) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| south-west | keep_enemy | 116.00-150.00 | 114.89 | 1.0 % |
| south-west | natural | 38.00-58.00 | 39.81 | - |
| south-west | rich | 65.00-95.00 | 80.25 | - |
| south-west | crown | 50.00-72.00 | 57.43 | - |
| north-east | keep_enemy | 116.00-150.00 | 114.89 | 1.0 % |
| north-east | natural | 38.00-58.00 | 39.81 | - |
| north-east | rich | 65.00-95.00 | 80.25 | - |
| north-east | crown | 50.00-72.00 | 57.43 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 4 | 2 | 1 | 1 | 1 |
| north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 4 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| south-west | 5 | 2 | 10 | 25 |
| north-east | 5 | 2 | 10 | 25 |


## Hottest metres (every spot-pair shortest path, 1596 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (0.5, 0.5) | 153 | 10 % |
| 2 | (-9.5, -8.5) | 143 | 9 % |
| 3 | (6.5, 8.5) | 142 | 9 % |
| 4 | (13.5, 38.5) | 138 | 9 % |
| 5 | (-13.5, -38.5) | 137 | 9 % |
| 6 | (-5.5, 9.5) | 130 | 8 % |
| 7 | (5.5, -9.5) | 113 | 7 % |
| 8 | (13.5, -7.5) | 105 | 7 % |
| 9 | (-13.5, 7.5) | 97 | 6 % |
| 10 | (7.5, 32.5) | 92 | 6 % |


## Info findings (103)
| Check | Where | What |
|---|---|---|
| N3 | island 4 at (41.1, -43.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 24 at (-41.1, 43.9) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 24 islands on top of colliders (471 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | cache_a-bridge_crown_a vs cache_a_twin-bridge_crown_b | 22.1 m vs 23.9 m (7.7 %) |
| F2 | well-steps_a vs well_twin-steps_b | 28.4 m vs 30.1 m (5.8 %) |
| F2 | ford_nest-inn_tavern_twin vs ford_nest_twin-inn_tavern | 27.6 m vs 26.2 m (5.0 %) |
| F2 | guilds_lodge-bridge_crown_a vs guilds_lodge_twin-bridge_crown_b | 78.7 m vs 74.8 m (4.9 %) |
| F2 | rich_node-bridge_crown_b vs rich_node_twin-bridge_crown_a | 58.6 m vs 61.6 m (4.8 %) |
| F2 | post_b-lairs_n_two_twin vs post_b_twin-lairs_n_two | 53.7 m vs 56.4 m (4.8 %) |
| F2 | home_b-lairs_w_one_twin vs home_b_twin-lairs_w_one | 103.8 m vs 98.9 m (4.8 %) |
| F2 | rich_node-steps_a vs rich_node_twin-steps_b | 41.4 m vs 43.4 m (4.6 %) |
| F2 | well-bridge_crown_b vs well_twin-bridge_crown_a | 45.7 m vs 47.8 m (4.5 %) |
| F2 | home_b-post_a_twin vs home_b_twin-post_a | 101.0 m vs 105.8 m (4.5 %) |
| F2 | home_b-shrine_twin vs home_b_twin-shrine | 78.6 m vs 75.1 m (4.4 %) |
| F2 | nat_node-lairs_n_one vs nat_node_twin-lairs_n_one_twin | 78.2 m vs 74.8 m (4.4 %) |
| F2 | rich_node-steps_b vs rich_node_twin-steps_a | 66.6 m vs 69.6 m (4.3 %) |
| F2 | post_b-guilds_lodge vs post_b_twin-guilds_lodge_twin | 122.9 m vs 117.6 m (4.3 %) |
| F2 | guilds_den-crown vs guilds_den_twin-crown | 71.3 m vs 74.5 m (4.3 %) |
| F2 | shrine-wallow_twin vs shrine_twin-wallow | 76.3 m vs 73.0 m (4.3 %) |
| F2 | keep_t0-shrine_twin vs keep_t1-shrine | 79.7 m vs 76.3 m (4.3 %) |
| F2 | nat_node-post_a vs nat_node_twin-post_a_twin | 48.1 m vs 50.2 m (4.3 %) |
| F2 | rich_node-shrine_twin vs rich_node_twin-shrine | 70.2 m vs 73.3 m (4.2 %) |
| F2 | inn_peddler-bridge_road_b vs inn_peddler_twin-bridge_road_a | 69.6 m vs 72.6 m (4.1 %) |
| F2 | nat_node-bridge_road_b vs nat_node_twin-bridge_road_a | 42.7 m vs 40.9 m (4.1 %) |
| F2 | well-stag_twin vs well_twin-stag | 78.9 m vs 82.2 m (4.0 %) |
| F2 | post_b-lairs_w_one_twin vs post_b_twin-lairs_w_one | 76.5 m vs 73.4 m (4.0 %) |
| F2 | rich_node-post_b_twin vs rich_node_twin-post_b | 45.2 m vs 43.4 m (3.9 %) |
| F2 | keep_t0-inn_peddler vs keep_t1-inn_peddler_twin | 54.1 m vs 52.0 m (3.9 %) |
| F2 | ford_nest-lairs_n_one vs ford_nest_twin-lairs_n_one_twin | 110.0 m vs 105.8 m (3.9 %) |
| F2 | well-post_a_twin vs well_twin-post_a | 91.3 m vs 95.0 m (3.9 %) |
| F2 | rich_node-inn_tavern_twin vs rich_node_twin-inn_tavern | 74.9 m vs 77.9 m (3.9 %) |
| F2 | home_b-steps_a vs home_b_twin-steps_b | 61.4 m vs 63.9 m (3.8 %) |
| F2 | keep_t0-steps_a vs keep_t1-steps_b | 61.9 m vs 64.4 m (3.8 %) |
| F2 | well-shrine_twin vs well_twin-shrine | 57.3 m vs 59.5 m (3.8 %) |
| F2 | guilds_lodge-lairs_w_two_twin vs guilds_lodge_twin-lairs_w_two | 136.5 m vs 131.3 m (3.8 %) |
| F2 | home_a-shrine_twin vs home_a_twin-shrine | 79.0 m vs 76.0 m (3.8 %) |
| F2 | well-crown vs well_twin-crown | 40.8 m vs 42.4 m (3.8 %) |
| F2 | tower_a-guilds_lodge_twin vs tower_a_twin-guilds_lodge | 126.2 m vs 121.4 m (3.8 %) |
| F2 | lairs_n_one-bridge_crown_a vs lairs_n_one_twin-bridge_crown_b | 70.6 m vs 68.0 m (3.7 %) |
| F2 | wallow-steps_b vs wallow_twin-steps_a | 60.2 m vs 62.5 m (3.7 %) |
| F2 | rich_node-guilds_lodge_twin vs rich_node_twin-guilds_lodge | 125.2 m vs 130.0 m (3.6 %) |
| F2 | rich_node-cache_a_twin vs rich_node_twin-cache_a | 80.5 m vs 83.5 m (3.6 %) |
| F2 | guilds_den-steps_b vs guilds_den_twin-steps_a | 84.1 m vs 87.2 m (3.6 %) |
| F2 | cache_a-lairs_n_two_twin vs cache_a_twin-lairs_n_two | 92.6 m vs 96.1 m (3.6 %) |
| F2 | rich_node-tower_a_twin vs rich_node_twin-tower_a | 103.7 m vs 107.6 m (3.6 %) |
| F2 | lairs_w_two-bridge_crown_a vs lairs_w_two_twin-bridge_crown_b | 53.3 m vs 55.3 m (3.6 %) |
| F2 | cache_a-lairs_w_one_twin vs cache_a_twin-lairs_w_one | 76.3 m vs 79.0 m (3.5 %) |
| F2 | lairs_w_one-steps_a vs lairs_w_one_twin-steps_b | 40.1 m vs 38.7 m (3.4 %) |
| F2 | nat_node-steps_a vs nat_node_twin-steps_b | 28.3 m vs 27.3 m (3.4 %) |
| F2 | guilds_den-guilds_lodge_twin vs guilds_den_twin-guilds_lodge | 142.7 m vs 147.6 m (3.3 %) |
| F2 | tower_b-inn_tavern_twin vs tower_b_twin-inn_tavern | 44.5 m vs 43.0 m (3.2 %) |
| F2 | cache_b-lairs_n_one vs cache_b_twin-lairs_n_one_twin | 90.7 m vs 87.8 m (3.2 %) |
| F2 | bridge_road_a-steps_b vs bridge_road_b-steps_a | 67.1 m vs 69.3 m (3.2 %) |
| F2 | well-cache_a_twin vs well_twin-cache_a | 67.5 m vs 69.8 m (3.2 %) |
| F2 | rich_node-inn_peddler_twin vs rich_node_twin-inn_peddler | 80.4 m vs 83.1 m (3.2 %) |
| F2 | guilds_den-cache_a_twin vs guilds_den_twin-cache_a | 98.0 m vs 101.1 m (3.1 %) |
| F2 | rich_node-well_twin vs rich_node_twin-well | 95.0 m vs 98.0 m (3.1 %) |
| F2 | ford_nest-cache_a_twin vs ford_nest_twin-cache_a | 41.0 m vs 42.3 m (3.1 %) |
| F2 | well-lairs_w_one_twin vs well_twin-lairs_w_one | 88.7 m vs 86.0 m (3.1 %) |
| F2 | tower_a-steps_a vs tower_a_twin-steps_b | 37.3 m vs 38.5 m (3.0 %) |
| F2 | lairs_n_one-steps_a vs lairs_n_one_twin-steps_b | 50.8 m vs 52.3 m (3.0 %) |
| F2 | tower_b-lairs_n_two vs tower_b_twin-lairs_n_two_twin | 95.0 m vs 92.3 m (2.9 %) |
| F2 | well-steps_b vs well_twin-steps_a | 53.6 m vs 55.1 m (2.9 %) |
| F2 | stag-bridge_crown_b vs stag_twin-bridge_crown_a | 51.7 m vs 53.2 m (2.8 %) |
| F2 | ford_nest-inn_peddler_twin vs ford_nest_twin-inn_peddler | 34.1 m vs 35.1 m (2.8 %) |
| F2 | post_a-lairs_n_two_twin vs post_a_twin-lairs_n_two | 114.7 m vs 118.1 m (2.8 %) |
| F2 | tower_a-lairs_w_one_twin vs tower_a_twin-lairs_w_one | 87.4 m vs 90.0 m (2.8 %) |
| F2 | inn_peddler-bridge_crown_b vs inn_peddler_twin-bridge_crown_a | 31.9 m vs 32.8 m (2.7 %) |
| F2 | guilds_den-inn_peddler_twin vs guilds_den_twin-inn_peddler | 98.0 m vs 100.7 m (2.7 %) |
| F2 | ford_a-steps_b vs ford_b-steps_a | 57.0 m vs 58.6 m (2.7 %) |
| F2 | ford_nest-steps_a vs ford_nest_twin-steps_b | 58.6 m vs 57.0 m (2.7 %) |
| F2 | bridge_road_a-bridge_crown_b vs bridge_road_b-bridge_crown_a | 47.6 m vs 48.9 m (2.7 %) |
| F2 | rich_node-lairs_w_one_twin vs rich_node_twin-lairs_w_one | 95.4 m vs 98.0 m (2.6 %) |
| F2 | tower_b-guilds_den vs tower_b_twin-guilds_den_twin | 103.2 m vs 100.5 m (2.6 %) |
| F2 | nat_node-ford_nest vs nat_node_twin-ford_nest_twin | 32.0 m vs 31.1 m (2.6 %) |
| F2 | nat_node-ford_b vs nat_node_twin-ford_a | 32.0 m vs 31.1 m (2.6 %) |
| F2 | inn_peddler-steps_b vs inn_peddler_twin-steps_a | 39.8 m vs 38.7 m (2.6 %) |
| F2 | rich_node-lairs_n_one_twin vs rich_node_twin-lairs_n_one | 117.9 m vs 121.0 m (2.6 %) |
| F2 | well-inn_tavern_twin vs well_twin-inn_tavern | 61.8 m vs 63.4 m (2.5 %) |
| F2 | rich_node-lairs_n_two_twin vs rich_node_twin-lairs_n_two | 118.0 m vs 121.0 m (2.5 %) |
| F2 | tower_b-lairs_n_one vs tower_b_twin-lairs_n_one_twin | 100.9 m vs 98.4 m (2.5 %) |
| F2 | nat_node-well vs nat_node_twin-well_twin | 49.8 m vs 48.6 m (2.4 %) |
| F2 | lairs_w_one-ford_b vs lairs_w_one_twin-ford_a | 70.0 m vs 68.3 m (2.4 %) |
| F2 | wallow-inn_tavern_twin vs wallow_twin-inn_tavern | 58.1 m vs 56.7 m (2.4 %) |
| F2 | rich_node-post_a_twin vs rich_node_twin-post_a | 104.2 m vs 106.8 m (2.4 %) |
| F2 | rich_node-lairs_w_two_twin vs rich_node_twin-lairs_w_two | 119.2 m vs 122.2 m (2.4 %) |
| F2 | tower_b-stag vs tower_b_twin-stag_twin | 59.7 m vs 61.2 m (2.4 %) |
| F2 | rich_node-guilds_den_twin vs rich_node_twin-guilds_den | 125.5 m vs 128.5 m (2.3 %) |
| F2 | nat_node-rich_node vs nat_node_twin-rich_node_twin | 63.3 m vs 61.8 m (2.3 %) |
| F2 | cache_b-steps_a vs cache_b_twin-steps_b | 40.9 m vs 40.0 m (2.3 %) |
| F2 | guilds_den-lairs_n_two_twin vs guilds_den_twin-lairs_n_two | 135.5 m vs 138.6 m (2.3 %) |
| F2 | post_a-ford_b vs post_a_twin-ford_a | 78.9 m vs 77.2 m (2.2 %) |
| F2 | ford_nest-guilds_lodge vs ford_nest_twin-guilds_lodge_twin | 113.8 m vs 111.3 m (2.2 %) |
| F2 | tower_b-well vs tower_b_twin-well_twin | 73.4 m vs 71.8 m (2.2 %) |
| F2 | guilds_den-bridge_crown_b vs guilds_den_twin-bridge_crown_a | 76.1 m vs 77.8 m (2.2 %) |
| F2 | guilds_den-lairs_w_two_twin vs guilds_den_twin-lairs_w_two | 136.7 m vs 139.8 m (2.2 %) |
| F2 | guilds_den-steps_a vs guilds_den_twin-steps_b | 58.9 m vs 60.1 m (2.1 %) |
| F2 | tower_b-cache_a_twin vs tower_b_twin-cache_a | 57.9 m vs 59.2 m (2.1 %) |
| F2 | nat_node-guilds_lodge vs nat_node_twin-guilds_lodge_twin | 82.0 m vs 80.3 m (2.1 %) |
| F2 | ford_nest-guilds_den_twin vs ford_nest_twin-guilds_den | 42.9 m vs 42.0 m (2.0 %) |
| F2 | shrine-bridge_road_b vs shrine_twin-bridge_road_a | 59.3 m vs 58.1 m (2.0 %) |
| F2 | inn_peddler-ford_b vs inn_peddler_twin-ford_a | 58.9 m vs 60.1 m (2.0 %) |
| F2 | inn_tavern-lairs_n_one vs inn_tavern_twin-lairs_n_one_twin | 43.1 m vs 44.0 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 57 sources) 686.77 s.
- Map Lab v2 (map-production.md 2.5): layout thornwater_s4, 2 seats, rules tempo standard, 2 fixable findings.
- Navmesh raster 19.60 s (691 polygons, 230400 cells of 0.25 m), spot / mirror checks 6.22 s, 1596 paths 4.79 s.
- Map Thornwater (seed 4), scene res://docs/tools/world_forge/out/thornwater_s4/preview.tscn, sim mode off; level load + navmesh bake 9.0 s (191 frames), lab 724.6 s. Spec: docs/design/map-production.md.
