# Map Lab: Thornwater (seed 2) scorecard: world_forge_thornwater_s2

2026-10-02 17:46 · lab v1.0 · 363.27 s · scanned 65 spots

## Result: **WARN** · score **95 / 100**

0 FAIL · 4 WARN · 14 PASS · 3 info checks; findings: 0 FAIL, 58 WARN, 108 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): tower_b-bridge_crown_a vs tower_b_twin-bridge_crown_b: 39.0 m vs 31.6 m (19.1 %) -> units walk tower_b-bridge_crown_a the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 900 / 1056 pairs within 2 % (0 FAIL, 51 WARN, 105 info))_
2. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest expansion: 46.0 m vs 50.5 m between seats (8.9 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 8 / 10 clean (0 FAIL, 2 WARN))_
3. **Main routes: narrowest corridor matches the twin** (WARN): keep_t0 -> nat_node: narrowest 2.1 m at (-15.4, 31.4) vs its twin's 15.9 m -> a collider narrows this route only on one side _(from C2 4 / 5 clean (0 FAIL, 1 WARN))_
4. **Clearances (roads, crossings)** (WARN): third_node: node 1.0 m from crossing bridge_road_b (want >= 8) -> move it off the crossing approach (auto-fix) _(from R4 53 / 57 clean (0 FAIL, 4 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 727 polygons, main area 13217 m² (92 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
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
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (1 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 1056 / 1056 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 900 / 1056 pairs within 2 % (0 FAIL, 51 WARN, 105 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 62 | 8 / 10 clean (0 FAIL, 2 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps (team maps) | INFO | no side has 2 seats (1v1): nothing to check |  |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 5 / 5 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | PASS 100 | 8 / 8 clean | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
| R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL |  |
| R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | own / nearest enemy path 0.9-1.1 (contested) or 1.1-1.45 (raidable): >= 5 per seat |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 8 / 8 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | **WARN** 62 | 4 / 5 clean (0 FAIL, 1 WARN) | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | **WARN** 67 | 53 / 57 clean (0 FAIL, 4 WARN) | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (480 x 480 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | tower_b-bridge_crown_a vs tower_b_twin-bridge_crown_b | 39.0 m vs 31.6 m (19.1 %) | units walk tower_b-bridge_crown_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-crown vs tower_b_twin-crown | 50.5 m vs 42.3 m (16.3 %) | units walk tower_b-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-ford_nest vs home_a_twin-ford_nest_twin | 54.9 m vs 64.4 m (14.7 %) | units walk home_a_twin-ford_nest_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-ford_b vs home_a_twin-ford_a | 54.9 m vs 64.4 m (14.7 %) | units walk home_a_twin-ford_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-steps_a vs tower_b_twin-steps_b | 57.0 m vs 49.5 m (13.1 %) | units walk tower_b-steps_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-cache_a vs home_a_twin-cache_a_twin | 39.5 m vs 45.2 m (12.6 %) | units walk home_a_twin-cache_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-post_b_twin vs rich_hollow_twin-post_b | 63.1 m vs 55.6 m (11.9 %) | units walk rich_hollow-post_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-tower_a vs nat_node_twin-tower_a_twin | 62.9 m vs 71.1 m (11.6 %) | units walk nat_node_twin-tower_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-shrine vs tower_b_twin-shrine_twin | 53.7 m vs 48.4 m (9.9 %) | units walk tower_b-shrine the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-inn_peddler vs tower_b_twin-inn_peddler_twin | 56.6 m vs 51.3 m (9.4 %) | units walk tower_b-inn_peddler the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_a-bridge_road_b vs post_a_twin-bridge_road_a | 90.3 m vs 82.0 m (9.2 %) | units walk post_a-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-well_twin vs home_a_twin-well | 79.3 m vs 87.2 m (9.1 %) | units walk home_a_twin-well the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node vs keep_t1-nat_node_twin | 50.5 m vs 46.0 m (8.9 %) | units walk keep_t0-nat_node the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-inn_tavern vs tower_b_twin-inn_tavern_twin | 62.5 m vs 57.0 m (8.7 %) | units walk tower_b-inn_tavern the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-post_b_twin vs tower_b_twin-post_b | 107.9 m vs 98.7 m (8.5 %) | units walk tower_b-post_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-stag_twin vs home_b_twin-stag | 83.0 m vs 90.6 m (8.4 %) | units walk home_b_twin-stag the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_twin vs keep_t1-well | 76.1 m vs 83.0 m (8.4 %) | units walk keep_t1-well the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_w_two_twin vs keep_t1-lairs_w_two | 124.8 m vs 114.4 m (8.3 %) | units walk keep_t0-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b-ford_a vs cache_b_twin-ford_b | 65.8 m vs 71.5 m (8.0 %) | units walk cache_b_twin-ford_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b-bridge_road_a vs cache_b_twin-bridge_road_b | 75.0 m vs 81.5 m (7.9 %) | units walk cache_b_twin-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-lairs_w_two_twin vs home_a_twin-lairs_w_two | 123.9 m vs 114.2 m (7.9 %) | units walk home_a-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-well vs nat_node_twin-well_twin | 50.9 m vs 55.2 m (7.8 %) | units walk nat_node_twin-well_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-crown vs cache_a_twin-crown | 32.7 m vs 35.3 m (7.5 %) | units walk cache_a_twin-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-cache_b_twin vs tower_b_twin-cache_b | 73.6 m vs 68.1 m (7.5 %) | units walk tower_b-cache_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-crown vs post_b_twin-crown | 60.7 m vs 56.3 m (7.3 %) | units walk post_b-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-bridge_crown_b vs tower_b_twin-bridge_crown_a | 59.2 m vs 54.9 m (7.2 %) | units walk tower_b-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-wallow_twin vs tower_b_twin-wallow | 107.1 m vs 99.6 m (7.1 %) | units walk tower_b-wallow_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-lairs_w_one_twin vs home_b_twin-lairs_w_one | 100.2 m vs 107.7 m (7.0 %) | units walk home_b_twin-lairs_w_one the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-lairs_n_one_twin vs well_twin-lairs_n_one | 111.9 m vs 104.3 m (6.8 %) | units walk well-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-lairs_w_two_twin vs ford_nest_twin-lairs_w_two | 64.6 m vs 60.2 m (6.8 %) | units walk ford_nest-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-inn_peddler vs home_a_twin-inn_peddler_twin | 48.5 m vs 51.9 m (6.5 %) | units walk home_a_twin-inn_peddler_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-cache_b vs home_a_twin-cache_b_twin | 41.5 m vs 44.4 m (6.5 %) | units walk home_a_twin-cache_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-ford_nest_twin vs tower_b_twin-ford_nest | 87.8 m vs 82.1 m (6.4 %) | units walk tower_b-ford_nest_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-ford_a vs tower_b_twin-ford_b | 87.8 m vs 82.1 m (6.4 %) | units walk tower_b-ford_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_a-cache_a_twin vs post_a_twin-cache_a | 91.7 m vs 86.0 m (6.1 %) | units walk post_a-cache_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_a-post_b vs post_a_twin-post_b_twin | 78.6 m vs 73.8 m (6.1 %) | units walk post_a-post_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-steps_a vs home_a_twin-steps_b | 58.2 m vs 61.9 m (5.9 %) | units walk home_a_twin-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine-bridge_road_b vs shrine_twin-bridge_road_a | 67.7 m vs 63.7 m (5.8 %) | units walk shrine-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a-bridge_road_b vs cache_a_twin-bridge_road_a | 68.3 m vs 64.4 m (5.8 %) | units walk cache_a-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_a_twin vs keep_t1-post_a | 115.7 m vs 109.0 m (5.7 %) | units walk keep_t0-post_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-lairs_w_two_twin vs tower_b_twin-lairs_w_two | 74.3 m vs 70.1 m (5.6 %) | units walk tower_b-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_peddler-bridge_road_b vs inn_peddler_twin-bridge_road_a | 70.5 m vs 66.6 m (5.6 %) | units walk inn_peddler-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-cache_b_twin vs stag_twin-cache_b | 60.5 m vs 57.2 m (5.4 %) | units walk stag-cache_b_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_b vs keep_t1-cache_b_twin | 42.5 m vs 40.2 m (5.4 %) | units walk keep_t0-cache_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b-post_a_twin vs home_b_twin-post_a | 104.3 m vs 110.3 m (5.4 %) | units walk home_b_twin-post_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-well vs tower_b_twin-well_twin | 78.0 m vs 73.8 m (5.3 %) | units walk tower_b-well the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-post_a_twin vs home_a_twin-post_a | 114.8 m vs 108.8 m (5.2 %) | units walk home_a-post_a_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_w_one_twin vs keep_t1-lairs_w_one | 108.9 m vs 103.2 m (5.2 %) | units walk keep_t0-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-shrine vs home_a_twin-shrine_twin | 47.4 m vs 49.9 m (5.2 %) | units walk home_a_twin-shrine_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-bridge_road_a vs tower_b_twin-bridge_road_b | 97.0 m vs 92.0 m (5.1 %) | units walk tower_b-bridge_road_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-cache_a vs tower_b_twin-cache_a_twin | 51.1 m vs 48.5 m (5.0 %) | units walk tower_b-cache_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest expansion | 46.0 m vs 50.5 m between seats (8.9 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | D1 | nearest cache | 40.2 m vs 42.5 m between seats (5.4 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | C2 | keep_t0 -> nat_node | narrowest 2.1 m at (-15.4, 31.4) vs its twin's 15.9 m | a collider narrows this route only on one side |
| WARN | R4 | third_node | node 1.0 m from crossing bridge_road_b (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | third_node_twin | node 1.0 m from crossing bridge_road_a (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | wallow | camp 6.4 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | wallow_twin | camp 6.4 m from a road centre line (want >= 9) | push it off the road (auto-fix) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-45.0, 41.6) | (-44.6, 37.9) | keep_t1 | (-44.6, 37.9) | 0.0 |
| keep_t1 | keep | (45.0, -41.6) | (44.6, -37.9) | keep_t0 | (44.6, -37.9) | 0.0 |
| home_a | home_node | (-47.7, 32.5) | (-47.6, 32.4) | home_a_twin | (-47.6, 32.4) | 0.0 |
| home_a_twin | home_node | (47.7, -32.5) | (47.6, -32.4) | home_a | (47.6, -32.4) | 0.0 |
| home_b | home_node | (-36.1, 45.0) | (-36.1, 44.9) | home_b_twin | (-36.1, 44.9) | 0.0 |
| home_b_twin | home_node | (36.1, -45.0) | (36.1, -44.9) | home_b | (36.1, -44.9) | 0.0 |
| nat_node | expansion | (-4.8, 15.3) | (-4.6, 15.1) | nat_node_twin | (-4.6, 15.1) | 0.0 |
| nat_node_twin | expansion | (4.8, -15.3) | (4.6, -15.1) | nat_node | (4.6, -15.1) | 0.0 |
| rich_node | expansion | (-37.5, -39.8) | (-37.4, -39.6) | rich_node_twin | (-37.4, -39.6) | 0.0 |
| rich_node_twin | expansion | (37.5, 39.8) | (37.4, 39.6) | rich_node | (37.4, 39.6) | 0.0 |
| third_node | expansion | (9.5, 50.3) | (9.4, 50.1) | third_node_twin | (9.4, 50.1) | 0.0 |
| third_node_twin | expansion | (-9.5, -50.3) | (-9.4, -50.1) | third_node | (-9.4, -50.1) | 0.0 |
| tower_a | point | (-20.5, -43.1) | (-20.4, -43.1) | tower_a_twin | (-20.4, -43.1) | 0.0 |
| tower_a_twin | point | (20.5, 43.1) | (20.4, 43.1) | tower_a | (20.4, 43.1) | 0.0 |
| tower_b | point | (-3.7, 39.8) | (-3.6, 39.6) | tower_b_twin | (-3.6, 39.6) | 0.0 |
| tower_b_twin | point | (3.7, -39.8) | (3.6, -39.6) | tower_b | (3.6, -39.6) | 0.0 |
| well | point | (-29.8, -28.1) | (-29.6, -28.1) | well_twin | (-29.6, -28.1) | 0.0 |
| well_twin | point | (29.8, 28.1) | (29.6, 28.1) | well | (29.6, 28.1) | 0.0 |
| shrine | point | (-19.6, -5.7) | (-19.4, -5.6) | shrine_twin | (-19.4, -5.6) | 0.0 |
| shrine_twin | point | (19.6, 5.7) | (19.4, 5.6) | shrine | (19.4, 5.6) | 0.0 |
| rich_hollow | camp | (-51.0, -56.1) | (-50.9, -56.1) | rich_hollow_twin | (-50.9, -56.1) | 0.0 |
| rich_hollow_twin | camp | (51.0, 56.1) | (50.9, 56.1) | rich_hollow | (50.9, 56.1) | 0.0 |
| wallow | camp | (-17.1, 54.0) | (-17.1, 53.9) | wallow_twin | (-17.1, 53.9) | 0.0 |
| wallow_twin | camp | (17.1, -54.0) | (17.1, -53.9) | wallow | (17.1, -53.9) | 0.0 |
| ford_nest | camp | (6.8, 39.6) | (6.9, 39.4) | ford_nest_twin | (6.9, 39.4) | 0.0 |
| ford_nest_twin | camp | (-6.8, -39.6) | (-6.9, -39.4) | ford_nest | (-6.9, -39.4) | 0.0 |
| stag | camp | (-35.2, -11.1) | (-35.1, -10.9) | stag_twin | (-35.1, -10.9) | 0.0 |
| stag_twin | camp | (35.2, 11.1) | (35.1, 10.9) | stag | (35.1, 10.9) | 0.0 |
| inn_tavern | tavern | (-14.1, -15.7) | (-13.9, -15.6) | inn_tavern_twin | (-13.9, -15.6) | 0.0 |
| inn_tavern_twin | tavern | (14.1, 15.7) | (13.9, 15.6) | inn_tavern | (13.9, 15.6) | 0.0 |
| post_a | post | (-54.0, -0.8) | (-53.9, -0.6) | post_a_twin | (-53.9, -0.6) | 0.0 |
| post_a_twin | post | (54.0, 0.8) | (53.9, 0.6) | post_a | (53.9, 0.6) | 0.0 |
| post_b | post | (-4.2, 54.0) | (-4.1, 53.9) | post_b_twin | (-4.1, 53.9) | 0.0 |
| post_b_twin | post | (4.2, -54.0) | (4.1, -53.9) | post_b | (4.1, -53.9) | 0.0 |
| rich_den | guild | (-50.9, -47.1) | (-50.9, -46.9) | rich_den_twin | (-50.9, -46.9) | 0.0 |
| rich_den_twin | guild | (50.9, 47.1) | (50.9, 46.9) | rich_den | (50.9, 46.9) | 0.0 |
| rich_lodge | guild | (-42.2, -54.3) | (-42.1, -54.1) | rich_lodge_twin | (-42.1, -54.1) | 0.0 |
| rich_lodge_twin | guild | (42.2, 54.3) | (42.1, 54.1) | rich_lodge | (42.1, 54.1) | 0.0 |
| guilds_den | guild | (-51.5, -46.9) | (-51.4, -46.9) | guilds_den_twin | (-51.4, -46.9) | 0.0 |
| guilds_den_twin | guild | (51.5, 46.9) | (51.4, 46.9) | guilds_den | (51.4, 46.9) | 0.0 |
| guilds_lodge | guild | (-42.7, -55.1) | (-42.6, -54.9) | guilds_lodge_twin | (-42.6, -54.9) | 0.0 |
| guilds_lodge_twin | guild | (42.7, 55.1) | (42.6, 54.9) | guilds_lodge | (42.6, 54.9) | 0.0 |
| inn_peddler | peddler | (-20.9, -8.4) | (-20.9, -8.1) | inn_peddler_twin | (-20.9, -8.1) | 0.0 |
| inn_peddler_twin | peddler | (20.9, 8.4) | (20.9, 8.1) | inn_peddler | (20.9, 8.1) | 0.0 |
| cache_a | cache | (-28.5, -2.3) | (-28.4, -2.1) | cache_a_twin | (-28.4, -2.1) | 0.0 |
| cache_a_twin | cache | (28.5, 2.3) | (28.4, 2.1) | cache_a | (28.4, 2.1) | 0.0 |
| cache_b | cache | (-7.2, 23.4) | (-7.1, 23.4) | cache_b_twin | (-7.1, 23.4) | 0.0 |
| cache_b_twin | cache | (7.2, -23.4) | (7.1, -23.4) | cache_b | (7.1, -23.4) | 0.0 |
| lairs_w_one | lair | (-47.4, 1.4) | (-47.4, 1.4) | lairs_w_one_twin | (-47.4, 1.4) | 0.0 |
| lairs_w_one_twin | lair | (47.4, -1.4) | (47.4, -1.4) | lairs_w_one | (47.4, -1.4) | 0.0 |
| lairs_w_two | lair | (-60.6, -10.8) | (-59.9, -10.9) | lairs_w_two_twin | (-59.9, -10.9) | 0.0 |
| lairs_w_two_twin | lair | (60.6, 10.8) | (59.9, 10.9) | lairs_w_two | (59.9, 10.9) | 0.0 |
| lairs_n_one | lair | (-33.6, -54.0) | (-33.4, -53.9) | lairs_n_one_twin | (-33.4, -53.9) | 0.0 |
| lairs_n_one_twin | lair | (33.6, 54.0) | (33.4, 53.9) | lairs_n_one | (33.4, 53.9) | 0.0 |
| lairs_n_two | lair | (-45.8, -40.8) | (-45.6, -40.9) | lairs_n_two_twin | (-45.6, -40.9) | 0.0 |
| lairs_n_two_twin | lair | (45.8, 40.8) | (45.6, 40.9) | lairs_n_two | (45.6, 40.9) | 0.0 |
| bridge_road_a | crossing_bridge_road | (-9.8, -49.3) | (-9.6, -49.1) | bridge_road_b | (-9.6, -49.1) | 0.0 |
| bridge_road_b | crossing_bridge_road | (9.8, 49.3) | (9.6, 49.1) | bridge_road_a | (9.6, 49.1) | 0.0 |
| ford_a | crossing_ford | (-6.8, -39.6) | (-6.9, -39.4) | ford_b | (-6.9, -39.4) | 0.0 |
| ford_b | crossing_ford | (6.8, 39.6) | (6.9, 39.4) | ford_a | (6.9, 39.4) | 0.0 |
| bridge_crown_a | crossing_bridge_lane | (-9.4, 8.7) | (-9.4, 8.6) | bridge_crown_b | (-9.4, 8.6) | 0.0 |
| bridge_crown_b | crossing_bridge_lane | (9.4, -8.7) | (9.4, -8.6) | bridge_crown_a | (9.4, -8.6) | 0.0 |
| steps_a | crossing_steps | (-8.7, -9.4) | (-8.6, -9.4) | steps_b | (-8.6, -9.4) | 0.0 |
| steps_b | crossing_steps | (8.7, 9.4) | (8.6, 9.4) | steps_a | (8.6, 9.4) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, -0.1) | 0.4 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 156)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | tower_b - bridge_crown_a | 39.0 | tower_b_twin - bridge_crown_b | 31.6 | +19.1 % |
| 2 | tower_b - crown | 50.5 | tower_b_twin - crown | 42.3 | +16.3 % |
| 3 | home_a - ford_nest | 54.9 | home_a_twin - ford_nest_twin | 64.4 | -14.7 % |
| 4 | home_a - ford_b | 54.9 | home_a_twin - ford_a | 64.4 | -14.7 % |
| 5 | tower_b - steps_a | 57.0 | tower_b_twin - steps_b | 49.5 | +13.1 % |
| 6 | home_a - cache_a | 39.5 | home_a_twin - cache_a_twin | 45.2 | -12.6 % |
| 7 | rich_hollow - post_b_twin | 63.1 | rich_hollow_twin - post_b | 55.6 | +11.9 % |
| 8 | nat_node - tower_a | 62.9 | nat_node_twin - tower_a_twin | 71.1 | -11.6 % |
| 9 | tower_b - shrine | 53.7 | tower_b_twin - shrine_twin | 48.4 | +9.9 % |
| 10 | home_a - home_b | 18.8 | home_a_twin - home_b_twin | 17.0 | +9.8 % |
| 11 | tower_b - inn_peddler | 56.6 | tower_b_twin - inn_peddler_twin | 51.3 | +9.4 % |
| 12 | post_a - bridge_road_b | 90.3 | post_a_twin - bridge_road_a | 82.0 | +9.2 % |
| 13 | home_a - well_twin | 79.3 | home_a_twin - well | 87.2 | -9.1 % |
| 14 | keep_t0 - nat_node | 50.5 | keep_t1 - nat_node_twin | 46.0 | +8.9 % |
| 15 | tower_b - inn_tavern | 62.5 | tower_b_twin - inn_tavern_twin | 57.0 | +8.7 % |
| 16 | tower_b - post_b_twin | 107.9 | tower_b_twin - post_b | 98.7 | +8.5 % |
| 17 | home_b - stag_twin | 83.0 | home_b_twin - stag | 90.6 | -8.4 % |
| 18 | keep_t0 - well_twin | 76.1 | keep_t1 - well | 83.0 | -8.4 % |
| 19 | keep_t0 - lairs_w_two_twin | 124.8 | keep_t1 - lairs_w_two | 114.4 | +8.3 % |
| 20 | cache_b - ford_a | 65.8 | cache_b_twin - ford_b | 71.5 | -8.0 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 50.5 (nat_node) | 41.2 (tower_b) | 32.2 (wallow) | 36.6 (lairs_w_one) | 62.6 (inn_tavern) | 39.6 (post_a) | 53.3 (inn_peddler) | 42.5 (cache_b) | 58.5 (crown) | 117.1 |
| north-east | 46.0 (nat_node_twin) | 41.1 (tower_b_twin) | 32.1 (wallow_twin) | 36.6 (lairs_w_one_twin) | 62.6 (inn_tavern_twin) | 39.6 (post_a_twin) | 53.3 (inn_peddler_twin) | 40.2 (cache_b_twin) | 58.5 (crown) | 117.1 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| home_a | home_node | 6.3 | home_a_twin | 6.3 | +0.0 % |
| home_b | home_node | 11.8 | home_b_twin | 11.7 | +1.6 % |
| wallow | camp | 32.2 | wallow_twin | 32.1 | +0.2 % |
| lairs_w_one | lair | 36.6 | lairs_w_one_twin | 36.6 | +0.0 % |
| post_a | post | 39.6 | post_a_twin | 39.6 | +0.0 % |
| tower_b | point | 41.2 | tower_b_twin | 41.1 | +0.3 % |
| cache_b | cache | 42.5 | cache_b_twin | 40.2 | +5.4 % |
| post_b | post | 43.7 | post_b_twin | 43.7 | +0.1 % |
| bridge_crown_a | crossing_bridge_lane | 45.8 | bridge_crown_b | 45.8 | +0.0 % |
| cache_a | cache | 46.5 | cache_a_twin | 46.6 | -0.0 % |
| stag | camp | 49.7 | stag_twin | 49.7 | +0.0 % |
| nat_node | expansion | 50.5 | nat_node_twin | 46.0 | +8.9 % |
| lairs_w_two | lair | 51.1 | lairs_w_two_twin | 51.1 | +0.0 % |
| shrine | point | 51.3 | shrine_twin | 51.3 | -0.0 % |
| ford_nest | camp | 51.6 | ford_nest_twin | 53.7 | -3.9 % |
| ford_b | crossing_ford | 51.6 | ford_a | 53.7 | -3.9 % |
| inn_peddler | peddler | 53.3 | inn_peddler_twin | 53.3 | -0.0 % |
| bridge_road_b | crossing_bridge_road | 56.7 | bridge_road_a | 55.4 | +2.3 % |
| third_node | expansion | 56.9 | third_node_twin | 55.4 | +2.6 % |
| crown | crown | 58.5 | crown | 58.5 | +0.0 % |
| inn_tavern | tavern | 62.6 | inn_tavern_twin | 62.6 | -0.0 % |
| steps_a | crossing_steps | 62.9 | steps_b | 62.9 | -0.0 % |
| steps_b | crossing_steps | 64.8 | steps_a | 63.1 | +2.7 % |
| tower_a_twin | point | 65.4 | tower_a | 66.8 | -2.0 % |
| well | point | 67.7 | well_twin | 67.7 | +0.0 % |
| bridge_crown_b | crossing_bridge_lane | 71.3 | bridge_crown_a | 71.3 | +0.0 % |
| inn_tavern_twin | tavern | 72.7 | inn_tavern | 70.8 | +2.7 % |
| shrine_twin | point | 75.6 | shrine | 74.4 | +1.6 % |
| well_twin | point | 76.1 | well | 83.0 | -8.4 % |
| inn_peddler_twin | peddler | 76.6 | inn_peddler | 75.3 | +1.7 % |
| nat_node_twin | expansion | 77.3 | nat_node | 77.2 | +0.1 % |
| rich_node | expansion | 77.8 | rich_node_twin | 77.8 | +0.0 % |
| lairs_n_two | lair | 78.8 | lairs_n_two_twin | 78.8 | +0.0 % |
| lairs_n_one_twin | lair | 81.5 | lairs_n_one | 79.7 | +2.2 % |
| rich_node_twin | expansion | 82.0 | rich_node | 84.1 | -2.4 % |
| cache_b_twin | cache | 83.9 | cache_b | 83.9 | +0.0 % |
| tower_a | point | 84.8 | tower_a_twin | 84.8 | +0.0 % |
| rich_den | guild | 85.0 | rich_den_twin | 85.0 | +0.0 % |
| guilds_den | guild | 85.0 | guilds_den_twin | 85.0 | +0.0 % |
| cache_a_twin | cache | 85.3 | cache_a | 84.1 | +1.4 % |
| rich_lodge_twin | guild | 89.5 | rich_lodge | 88.3 | +1.4 % |
| ford_a | crossing_ford | 89.9 | ford_b | 87.8 | +2.3 % |
| ford_nest_twin | camp | 89.9 | ford_nest | 87.8 | +2.3 % |
| guilds_lodge_twin | guild | 90.2 | guilds_lodge | 88.9 | +1.5 % |
| lairs_n_two_twin | lair | 90.3 | lairs_n_two | 91.8 | -1.6 % |
| stag_twin | camp | 90.8 | stag | 90.0 | +0.9 % |
| rich_lodge | guild | 92.0 | rich_lodge_twin | 92.0 | +0.0 % |
| lairs_n_one | lair | 92.4 | lairs_n_one_twin | 92.4 | +0.0 % |
| guilds_lodge | guild | 92.8 | guilds_lodge_twin | 92.8 | +0.0 % |
| rich_hollow | camp | 94.2 | rich_hollow_twin | 94.2 | +0.0 % |
| bridge_road_a | crossing_bridge_road | 95.2 | bridge_road_b | 95.2 | +0.0 % |
| rich_den_twin | guild | 96.2 | rich_den | 96.5 | -0.3 % |
| third_node_twin | expansion | 96.2 | third_node | 96.2 | +0.0 % |
| guilds_den_twin | guild | 96.6 | guilds_den | 97.0 | -0.3 % |
| rich_hollow_twin | camp | 98.4 | rich_hollow | 97.3 | +1.2 % |
| tower_b_twin | point | 100.5 | tower_b | 100.5 | +0.0 % |
| post_b_twin | post | 107.7 | post_b | 107.7 | +0.0 % |
| lairs_w_one_twin | lair | 108.9 | lairs_w_one | 103.2 | +5.2 % |
| wallow_twin | camp | 115.4 | wallow | 115.4 | +0.0 % |
| post_a_twin | post | 115.7 | post_a | 109.0 | +5.7 % |
| home_b_twin | home_node | 115.9 | home_b | 118.3 | -2.1 % |
| home_a_twin | home_node | 116.0 | home_a | 116.0 | +0.0 % |
| keep_t1 | keep | 117.1 | keep_t0 | 117.1 | +0.0 % |
| lairs_w_two_twin | lair | 124.8 | lairs_w_two | 114.4 | +8.3 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| south-west | enemy keep (keep_t1) | 117.1 | 0.0 | 0:25 | 0:23 | 0:16 | 0:29 |
| south-west | nearest expansion (nat_node) | 50.5 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| south-west | nearest point (tower_b) | 41.2 | 0.0 | 0:09 | 0:08 | 0:05 | 0:10 |
| south-west | nearest camp (wallow) | 32.2 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| south-west | crown (crown) | 58.5 | 0.0 | 0:13 | 0:12 | 0:08 | 0:15 |
| north-east | enemy keep (keep_t0) | 117.2 | 0.0 | 0:25 | 0:23 | 0:16 | 0:29 |
| north-east | nearest expansion (nat_node_twin) | 46.0 | 0.0 | 0:10 | 0:09 | 0:06 | 0:12 |
| north-east | nearest point (tower_b_twin) | 41.1 | 0.0 | 0:09 | 0:08 | 0:05 | 0:10 |
| north-east | nearest camp (wallow_twin) | 32.1 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| north-east | crown (crown) | 58.5 | 0.0 | 0:13 | 0:12 | 0:08 | 0:15 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_a | bridge_road | 6.0 | 4.5 | 5.5 | bridge_road_b | 4.3 |
| bridge_road_b | bridge_road | 6.0 | 4.3 | 5.3 | bridge_road_a | 4.5 |
| ford_a | ford | 7.0 | 5.0 | 6.0 | ford_b | 5.3 |
| ford_b | ford | 7.0 | 5.3 | 6.3 | ford_a | 5.0 |
| bridge_crown_a | bridge_lane | 8.0 | 6.0 | 7.0 | bridge_crown_b | 6.0 |
| bridge_crown_b | bridge_lane | 8.0 | 6.0 | 7.0 | bridge_crown_a | 6.0 |
| steps_a | steps | 6.0 | 4.4 | 5.4 | steps_b | 4.3 |
| steps_b | steps | 6.0 | 4.3 | 5.3 | steps_a | 4.4 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 58.5 | 5.1 | (-7.9, 6.9) | - |
| keep_t0 -> keep_t1 | 117.1 | 4.9 | (8.0, -6.8) | - |
| keep_t0 -> nat_node | 50.5 | 2.1 | (-15.4, 31.4) | (-15.4, 31.4) 2.1 |
| keep_t1 -> crown | 58.5 | 4.8 | (8.1, -6.7) | - |
| keep_t1 -> nat_node_twin | 46.0 | 15.9 | (23.8, -26.0) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| south-west | keep_enemy | 116.00-150.00 | 117.06 | - |
| south-west | natural | 38.00-58.00 | 50.53 | - |
| south-west | rich | 65.00-95.00 | 77.84 | - |
| south-west | crown | 50.00-72.00 | 58.52 | - |
| north-east | keep_enemy | 116.00-150.00 | 117.06 | - |
| north-east | natural | 38.00-58.00 | 46.02 | - |
| north-east | rich | 65.00-95.00 | 77.84 | - |
| north-east | crown | 50.00-72.00 | 58.52 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |
| north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| south-west | 5 | 3 | 12 | 29 |
| north-east | 5 | 3 | 12 | 29 |


## Hottest metres (every spot-pair shortest path, 2080 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (0.5, 0.5) | 196 | 9 % |
| 2 | (6.5, 7.5) | 179 | 9 % |
| 3 | (-5.5, -6.5) | 177 | 9 % |
| 4 | (6.5, 39.5) | 174 | 8 % |
| 5 | (-6.5, -39.5) | 154 | 7 % |
| 6 | (22.5, -6.5) | 139 | 7 % |
| 7 | (-42.5, -54.5) | 133 | 6 % |
| 8 | (6.5, -8.5) | 132 | 6 % |
| 9 | (6.5, -29.5) | 129 | 6 % |
| 10 | (42.5, 54.5) | 129 | 6 % |


## Info findings (108)
| Check | Where | What |
|---|---|---|
| N3 | island 4 at (45.1, -41.6) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 26 at (-44.9, 41.6) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 26 islands on top of colliders (455 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | home_a-home_b vs home_a_twin-home_b_twin | 18.8 m vs 17.0 m (9.8 %) |
| F2 | cache_b-steps_b vs cache_b_twin-steps_a | 31.5 m vs 29.8 m (5.4 %) |
| F2 | stag-bridge_road_b vs stag_twin-bridge_road_a | 79.3 m vs 75.4 m (5.0 %) |
| F2 | rich_lodge-lairs_n_one_twin vs rich_lodge_twin-lairs_n_one | 138.9 m vs 132.0 m (4.9 %) |
| F2 | guilds_lodge-lairs_n_one_twin vs guilds_lodge_twin-lairs_n_one | 139.7 m vs 132.9 m (4.9 %) |
| F2 | lairs_w_two-bridge_road_b vs lairs_w_two_twin-bridge_road_a | 96.7 m vs 92.0 m (4.8 %) |
| F2 | cache_b-lairs_w_two_twin vs cache_b_twin-lairs_w_two | 85.5 m vs 81.4 m (4.8 %) |
| F2 | post_a-bridge_crown_b vs post_a_twin-bridge_crown_a | 68.1 m vs 64.8 m (4.7 %) |
| F2 | rich_node-lairs_n_one_twin vs rich_node_twin-lairs_n_one | 123.7 m vs 117.9 m (4.7 %) |
| F2 | home_a-lairs_w_one_twin vs home_a_twin-lairs_w_one | 108.0 m vs 103.0 m (4.7 %) |
| F2 | shrine-cache_a_twin vs shrine_twin-cache_a | 53.8 m vs 51.4 m (4.5 %) |
| F2 | rich_node-tower_a_twin vs rich_node_twin-tower_a | 107.3 m vs 102.5 m (4.5 %) |
| F2 | cache_b-lairs_w_one_twin vs cache_b_twin-lairs_w_one | 78.5 m vs 82.1 m (4.4 %) |
| F2 | home_a-tower_b_twin vs home_a_twin-tower_b | 95.2 m vs 99.5 m (4.3 %) |
| F2 | inn_peddler-cache_a_twin vs inn_peddler_twin-cache_a | 54.6 m vs 52.3 m (4.3 %) |
| F2 | inn_tavern-cache_a_twin vs inn_tavern_twin-cache_a | 49.6 m vs 47.5 m (4.3 %) |
| F2 | home_a-inn_tavern vs home_a_twin-inn_tavern_twin | 58.7 m vs 61.3 m (4.2 %) |
| F2 | well-bridge_road_b vs well_twin-bridge_road_a | 94.8 m vs 90.9 m (4.2 %) |
| F2 | nat_node-rich_hollow_twin vs nat_node_twin-rich_hollow | 78.0 m vs 74.7 m (4.2 %) |
| F2 | stag-bridge_crown_a vs stag_twin-bridge_crown_b | 33.4 m vs 34.9 m (4.1 %) |
| F2 | post_a-cache_b_twin vs post_a_twin-cache_b | 80.3 m vs 77.0 m (4.0 %) |
| F2 | lairs_w_one-bridge_road_b vs lairs_w_one_twin-bridge_road_a | 79.4 m vs 76.2 m (4.0 %) |
| F2 | keep_t0-ford_b vs keep_t1-ford_a | 51.6 m vs 53.7 m (3.9 %) |
| F2 | keep_t0-ford_nest vs keep_t1-ford_nest_twin | 51.6 m vs 53.7 m (3.9 %) |
| F2 | lairs_w_one-lairs_w_two_twin vs lairs_w_one_twin-lairs_w_two | 118.2 m vs 113.6 m (3.9 %) |
| F2 | third_node-tower_a vs third_node_twin-tower_a_twin | 101.8 m vs 105.7 m (3.7 %) |
| F2 | rich_node-bridge_road_b vs rich_node_twin-bridge_road_a | 106.6 m vs 102.7 m (3.7 %) |
| F2 | tower_b-stag vs tower_b_twin-stag_twin | 61.8 m vs 59.5 m (3.6 %) |
| F2 | lairs_n_two-bridge_road_b vs lairs_n_two_twin-bridge_road_a | 110.5 m vs 106.6 m (3.6 %) |
| F2 | tower_b-lairs_n_one vs tower_b_twin-lairs_n_one_twin | 103.5 m vs 99.8 m (3.6 %) |
| F2 | shrine-inn_peddler_twin vs shrine_twin-inn_peddler | 49.1 m vs 47.4 m (3.5 %) |
| F2 | shrine-steps_b vs shrine_twin-steps_a | 37.3 m vs 36.0 m (3.5 %) |
| F2 | ford_nest-cache_b_twin vs ford_nest_twin-cache_b | 68.1 m vs 65.7 m (3.5 %) |
| F2 | cache_a-lairs_n_two_twin vs cache_a_twin-lairs_n_two | 93.4 m vs 90.2 m (3.4 %) |
| F2 | rich_den-bridge_road_b vs rich_den_twin-bridge_road_a | 118.3 m vs 114.3 m (3.3 %) |
| F2 | guilds_den-bridge_road_b vs guilds_den_twin-bridge_road_a | 118.5 m vs 114.5 m (3.3 %) |
| F2 | home_a-rich_node_twin vs home_a_twin-rich_node | 85.3 m vs 88.2 m (3.3 %) |
| F2 | lairs_n_one-bridge_road_b vs lairs_n_one_twin-bridge_road_a | 120.4 m vs 116.4 m (3.3 %) |
| F2 | rich_lodge-bridge_road_b vs rich_lodge_twin-bridge_road_a | 121.8 m vs 117.9 m (3.3 %) |
| F2 | guilds_lodge-bridge_road_b vs guilds_lodge_twin-bridge_road_a | 122.7 m vs 118.7 m (3.2 %) |
| F2 | rich_node-third_node vs rich_node_twin-third_node_twin | 106.3 m vs 103.0 m (3.1 %) |
| F2 | rich_hollow-bridge_road_b vs rich_hollow_twin-bridge_road_a | 126.6 m vs 122.6 m (3.1 %) |
| F2 | ford_nest-lairs_w_one vs ford_nest_twin-lairs_w_one_twin | 70.6 m vs 68.4 m (3.1 %) |
| F2 | rich_hollow-lairs_n_one_twin vs rich_hollow_twin-lairs_n_one | 143.6 m vs 139.2 m (3.1 %) |
| F2 | tower_a-inn_peddler_twin vs tower_a_twin-inn_peddler | 75.6 m vs 73.3 m (3.1 %) |
| F2 | well-cache_a_twin vs well_twin-cache_a | 69.7 m vs 67.6 m (3.0 %) |
| F2 | post_a-lairs_w_one_twin vs post_a_twin-lairs_w_one | 106.8 m vs 103.5 m (3.0 %) |
| F2 | lairs_w_two-steps_b vs lairs_w_two_twin-steps_a | 75.0 m vs 77.4 m (3.0 %) |
| F2 | stag-cache_a_twin vs stag_twin-cache_a | 69.5 m vs 67.5 m (3.0 %) |
| F2 | tower_b-rich_lodge vs tower_b_twin-rich_lodge_twin | 104.9 m vs 101.8 m (3.0 %) |
| F2 | home_a-tower_a_twin vs home_a_twin-tower_a | 68.8 m vs 70.9 m (2.9 %) |
| F2 | tower_b-lairs_w_one vs tower_b_twin-lairs_w_one_twin | 60.4 m vs 58.6 m (2.9 %) |
| F2 | tower_b-guilds_lodge vs tower_b_twin-guilds_lodge_twin | 105.8 m vs 102.7 m (2.9 %) |
| F2 | lairs_w_two-bridge_crown_a vs lairs_w_two_twin-bridge_crown_b | 56.5 m vs 54.8 m (2.9 %) |
| F2 | ford_nest-bridge_road_a vs ford_nest_twin-bridge_road_b | 95.4 m vs 98.3 m (2.9 %) |
| F2 | nat_node-lairs_n_two vs nat_node_twin-lairs_n_two_twin | 70.3 m vs 72.4 m (2.9 %) |
| F2 | nat_node-rich_hollow vs nat_node_twin-rich_hollow_twin | 85.8 m vs 88.3 m (2.8 %) |
| F2 | home_b-nat_node vs home_b_twin-nat_node_twin | 44.6 m vs 43.3 m (2.8 %) |
| F2 | post_b-cache_b_twin vs post_b_twin-cache_b | 86.3 m vs 83.9 m (2.7 %) |
| F2 | cache_a-ford_a vs cache_a_twin-ford_b | 45.8 m vs 44.6 m (2.7 %) |
| F2 | home_b-steps_b vs home_b_twin-steps_a | 63.4 m vs 61.7 m (2.7 %) |
| F2 | tower_b-lairs_n_two vs tower_b_twin-lairs_n_two_twin | 93.5 m vs 91.0 m (2.7 %) |
| F2 | ford_nest-ford_a vs ford_nest_twin-ford_b | 90.8 m vs 88.3 m (2.7 %) |
| F2 | keep_t0-inn_tavern_twin vs keep_t1-inn_tavern | 72.7 m vs 70.8 m (2.7 %) |
| F2 | shrine-inn_tavern_twin vs shrine_twin-inn_tavern | 45.3 m vs 44.1 m (2.7 %) |
| F2 | keep_t0-steps_b vs keep_t1-steps_a | 64.8 m vs 63.1 m (2.7 %) |
| F2 | keep_t0-third_node vs keep_t1-third_node_twin | 56.9 m vs 55.4 m (2.6 %) |
| F2 | post_a-lairs_w_two_twin vs post_a_twin-lairs_w_two | 122.7 m vs 119.5 m (2.6 %) |
| F2 | shrine-rich_hollow_twin vs shrine_twin-rich_hollow | 101.5 m vs 98.9 m (2.6 %) |
| F2 | cache_a-steps_b vs cache_a_twin-steps_a | 43.0 m vs 41.9 m (2.6 %) |
| F2 | rich_node-cache_a_twin vs rich_node_twin-cache_a | 83.2 m vs 81.1 m (2.6 %) |
| F2 | tower_a-lairs_w_one_twin vs tower_a_twin-lairs_w_one | 82.4 m vs 84.6 m (2.6 %) |
| F2 | ford_nest-post_a vs ford_nest_twin-post_a_twin | 76.4 m vs 74.5 m (2.5 %) |
| F2 | tower_b-rich_hollow vs tower_b_twin-rich_hollow_twin | 109.6 m vs 106.9 m (2.5 %) |
| F2 | nat_node-rich_den vs nat_node_twin-rich_den_twin | 78.3 m vs 80.3 m (2.5 %) |
| F2 | home_a-lairs_n_two_twin vs home_a_twin-lairs_n_two | 93.6 m vs 96.0 m (2.5 %) |
| F2 | ford_nest-lairs_w_two vs ford_nest_twin-lairs_w_two_twin | 88.0 m vs 85.9 m (2.4 %) |
| F2 | third_node-inn_tavern vs third_node_twin-inn_tavern_twin | 74.5 m vs 72.7 m (2.4 %) |
| F2 | lairs_n_one-lairs_n_two_twin vs lairs_n_one_twin-lairs_n_two | 127.8 m vs 124.7 m (2.4 %) |
| F2 | post_a-rich_den_twin vs post_a_twin-rich_den | 117.0 m vs 119.9 m (2.4 %) |
| F2 | ford_nest-post_b_twin vs ford_nest_twin-post_b | 98.2 m vs 95.9 m (2.4 %) |
| F2 | nat_node-guilds_den vs nat_node_twin-guilds_den_twin | 78.6 m vs 80.5 m (2.4 %) |
| F2 | keep_t0-rich_node_twin vs keep_t1-rich_node | 82.0 m vs 84.1 m (2.4 %) |
| F2 | rich_node-lairs_w_one_twin vs rich_node_twin-lairs_w_one | 98.6 m vs 100.9 m (2.3 %) |
| F2 | home_a-nat_node vs home_a_twin-nat_node_twin | 46.3 m vs 47.4 m (2.3 %) |
| F2 | post_a-guilds_den_twin vs post_a_twin-guilds_den | 117.5 m vs 120.3 m (2.3 %) |
| F2 | keep_t0-ford_nest_twin vs keep_t1-ford_nest | 89.9 m vs 87.8 m (2.3 %) |
| F2 | keep_t0-ford_a vs keep_t1-ford_b | 89.9 m vs 87.8 m (2.3 %) |
| F2 | keep_t0-bridge_road_b vs keep_t1-bridge_road_a | 56.7 m vs 55.4 m (2.3 %) |
| F2 | tower_b-post_a vs tower_b_twin-post_a_twin | 66.2 m vs 64.7 m (2.3 %) |
| F2 | keep_t0-lairs_n_one_twin vs keep_t1-lairs_n_one | 81.5 m vs 79.7 m (2.2 %) |
| F2 | tower_b-rich_den vs tower_b_twin-rich_den_twin | 101.1 m vs 98.8 m (2.2 %) |
| F2 | home_a-inn_tavern_twin vs home_a_twin-inn_tavern | 72.2 m vs 70.6 m (2.2 %) |
| F2 | home_a-home_b_twin vs home_a_twin-home_b | 114.8 m vs 117.3 m (2.2 %) |
| F2 | tower_b-lairs_w_two vs tower_b_twin-lairs_w_two_twin | 77.8 m vs 76.1 m (2.2 %) |
| F2 | rich_den-cache_a_twin vs rich_den_twin-cache_a | 98.1 m vs 95.9 m (2.2 %) |
| F2 | guilds_den-cache_a_twin vs guilds_den_twin-cache_a | 98.4 m vs 96.3 m (2.2 %) |
| F2 | tower_b-guilds_den vs tower_b_twin-guilds_den_twin | 101.3 m vs 99.1 m (2.1 %) |
| F2 | home_a-steps_b vs home_a_twin-steps_a | 64.2 m vs 62.8 m (2.1 %) |
| F2 | stag-inn_peddler_twin vs stag_twin-inn_peddler | 63.8 m vs 65.1 m (2.1 %) |
| F2 | keep_t0-home_b_twin vs keep_t1-home_b | 115.9 m vs 118.3 m (2.1 %) |
| F2 | tower_a-post_a_twin vs tower_a_twin-post_a | 88.5 m vs 90.3 m (2.1 %) |
| F2 | tower_a-lairs_w_two_twin vs tower_a_twin-lairs_w_two | 99.9 m vs 102.0 m (2.0 %) |
| F2 | rich_den-lairs_n_one_twin vs rich_den_twin-lairs_n_one | 135.3 m vs 132.6 m (2.0 %) |
| F2 | keep_t0-tower_a_twin vs keep_t1-tower_a | 65.4 m vs 66.8 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 65 sources) 319.66 s.
- Map Lab v2 (map-production.md 2.5): layout thornwater_s2, 2 seats, rules tempo standard, 2 fixable findings.
- Navmesh raster 12.68 s (727 polygons, 230400 cells of 0.25 m), spot / mirror checks 4.60 s, 2080 paths 4.13 s.
- Map Thornwater (seed 2), scene res://docs/tools/world_forge/out/thornwater_s2/preview.tscn, sim mode off; level load + navmesh bake 4.7 s (1090 frames), lab 358.6 s. Spec: docs/design/map-production.md.
