# Map Lab: Quartermeet (seed 11) scorecard: world_forge_quartermeet_s11

2026-10-02 18:24 · lab v1.0 · 784.95 s · scanned 97 spots

## Result: **FAIL** · score **89 / 100**

1 FAIL · 5 WARN · 13 PASS · 2 info checks; findings: 4 FAIL, 426 WARN, 522 info

## Improve next
1. **Targets met (rules bands, per seat)** (FAIL): A1 south-west ally: ally 52.8 outside 60-72 (12 %) -> a designer moves the keeps or the river (R1 ally is not auto-fixed) _(from R1 20 / 24 clean (4 FAIL, 0 WARN))_
2. **No navmesh islands** (WARN): island 13 at (-34.8, -56.1): 2.8 m² of ground-level navmesh cut off from the main area (y 0.50) -> a pocket closed by colliders: widen its gap or fill it (trees / rocks) (close or open the pocket) _(from N3 4 / 8 clean (0 FAIL, 4 WARN), 5 info)_
3. **Unit paths (NavigationServer): pairs match their twins** (WARN): stag_a1-stag_a2 vs stag_b2-stag_b1: 160.4 m vs 197.4 m (18.7 %) -> units walk stag_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 6047 / 6982 pairs within 2 % (0 FAIL, 418 WARN, 517 info))_
4. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest enemy keep: 137.0 m vs 151.6 m between seats (9.6 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 9 / 10 clean (0 FAIL, 1 WARN))_
5. **Travel times per seat (worker / soldier / cavalry / caravan)** (WARN): enemy keep (nearest) (worker): 0:30 vs 0:33 between seats -> one seat's route is longer or crosses more ford: see the travel-time table _(from T1 6 / 7 clean (0 FAIL, 1 WARN))_
6. **Main routes: narrowest corridor matches the twin** (WARN): keep_t0 -> keep_t4: narrowest 3.8 m at (-7.0, 1.7) vs its twin's 5.8 m -> a collider narrows this route only on one side _(from C2 11 / 12 clean (0 FAIL, 2 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 1195 polygons, main area 28972 m² (94 % of the 176 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 97 / 97 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | **WARN** 52 | 4 / 8 clean (0 FAIL, 4 WARN), 5 info | ground-level components other than the main one < 2 m² | close or open the pocket |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 176 x 176 m ok, 91 spots ok, 2.2x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 97 / 97 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 97 / 97 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (6 cells), 0.00 % (6 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6982 / 6982 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 6047 / 6982 pairs within 2 % (0 FAIL, 418 WARN, 517 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 66 | 9 / 10 clean (0 FAIL, 1 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | PASS 100 | 4 / 4 clean | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep, ally / nearest enemy 0.33-0.50 |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | **WARN** 64 | 6 / 7 clean (0 FAIL, 1 WARN) | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | **FAIL** 28 | 20 / 24 clean (4 FAIL, 0 WARN) | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
| R2 | Content per seat (Crown Hollow per side) | PASS 100 | 60 / 60 clean | new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL |  |
| R3 | Contested + raidable objectives per seat | PASS 100 | 4 / 4 clean | own / nearest enemy path 0.9-1.1 (contested) or 1.1-1.45 (raidable): >= 3 per seat |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 6 / 6 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | **WARN** 66 | 11 / 12 clean (0 FAIL, 2 WARN) | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | PASS 100 | 91 / 91 clean | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (704 x 704 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| FAIL | R1 | A1 south-west ally | ally 52.8 outside 60-72 (12 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| FAIL | R1 | A2 north-west ally | ally 52.8 outside 60-72 (12 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| FAIL | R1 | B1 north-east ally | ally 52.8 outside 60-72 (12 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| FAIL | R1 | B2 south-east ally | ally 52.8 outside 60-72 (12 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| WARN | N3 | island 13 at (-34.8, -56.1) | 2.8 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 14 at (34.9, -56.0) | 3.0 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 52 at (-34.9, 56.1) | 3.1 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 53 at (34.9, 56.1) | 2.8 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | F2 | stag_a1-stag_a2 vs stag_b2-stag_b1 | 160.4 m vs 197.4 m (18.7 %) | units walk stag_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_two_a1 vs stag_b1-lairs_two_b2 | 184.0 m vs 153.5 m (16.6 %) | units walk stag_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_two_a1 vs stag_b2-lairs_two_b1 | 184.0 m vs 153.8 m (16.4 %) | units walk stag_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_two_a2 vs stag_a2-lairs_two_a1 | 153.8 m vs 184.0 m (16.4 %) | units walk stag_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_b_b1 vs well_a2-cache_b_b2 | 120.1 m vs 101.0 m (15.9 %) | units walk well_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_b_b1 vs well_b1-cache_b_a1 | 120.1 m vs 101.0 m (15.9 %) | units walk well_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-ford_nest_a2 vs home_a_b2-ford_nest_a1 | 86.7 m vs 73.0 m (15.8 %) | units walk home_a_b1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-ford_nest_a1 vs home_a_a2-ford_nest_a2 | 73.0 m vs 86.7 m (15.8 %) | units walk home_a_a2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-ford_nest_a2 vs home_a_b2-ford_nest_a1 | 86.7 m vs 73.0 m (15.8 %) | units walk home_a_a2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_ford_s vs home_a_b1-x_ford_n | 73.0 m vs 86.7 m (15.8 %) | units walk home_a_b1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_ford_s vs home_a_a2-x_ford_n | 73.0 m vs 86.7 m (15.8 %) | units walk home_a_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-ford_nest_a1 vs home_a_b1-ford_nest_a2 | 73.0 m vs 86.7 m (15.8 %) | units walk home_a_b1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-x_ford_n vs home_a_b2-x_ford_s | 86.7 m vs 73.0 m (15.8 %) | units walk home_a_b1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-x_ford_n vs home_a_b2-x_ford_s | 86.7 m vs 73.0 m (15.8 %) | units walk home_a_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-shrine_a2 vs third_node_b2-shrine_a1 | 158.4 m vs 185.1 m (14.4 %) | units walk third_node_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b2 vs third_node_b2-shrine_a1 | 158.4 m vs 185.1 m (14.4 %) | units walk third_node_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_b1 vs cache_a_a2-cache_b_b2 | 138.0 m vs 118.8 m (13.9 %) | units walk cache_a_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_b1 vs cache_a_b1-cache_b_a1 | 138.0 m vs 118.8 m (13.9 %) | units walk cache_a_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-cache_b_b2 vs cache_a_b2-cache_b_a2 | 118.8 m vs 137.9 m (13.8 %) | units walk cache_a_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-cache_b_a1 vs cache_a_b2-cache_b_a2 | 118.8 m vs 137.9 m (13.8 %) | units walk cache_a_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-stag_b2 vs tower_c_b2-stag_a2 | 122.2 m vs 105.7 m (13.6 %) | units walk tower_c_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-stag_a1 vs tower_c_b2-stag_a2 | 122.2 m vs 105.7 m (13.6 %) | units walk tower_c_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_b1 vs tower_c_b2-stag_a2 | 122.1 m vs 105.7 m (13.4 %) | units walk tower_c_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-cache_b_b1 vs home_a_b2-cache_b_a1 | 99.7 m vs 86.7 m (13.0 %) | units walk home_a_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-cache_b_a2 vs home_a_b2-cache_b_a1 | 99.6 m vs 86.7 m (12.9 %) | units walk home_a_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-stag_b2 vs third_node_b2-stag_a2 | 240.8 m vs 209.7 m (12.9 %) | units walk third_node_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-stag_a1 vs third_node_b2-stag_a2 | 240.8 m vs 209.7 m (12.9 %) | units walk third_node_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-cache_b_b2 vs home_a_a2-cache_b_b1 | 86.9 m vs 99.7 m (12.8 %) | units walk home_a_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-stag_b1 vs third_node_b2-stag_a2 | 240.5 m vs 209.7 m (12.8 %) | units walk third_node_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-cache_b_b2 vs home_a_b1-cache_b_a2 | 86.9 m vs 99.6 m (12.7 %) | units walk home_a_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-stag_a1 vs nat_node_b2-stag_a2 | 141.6 m vs 124.1 m (12.3 %) | units walk nat_node_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-stag_b2 vs nat_node_b1-stag_a1 | 124.1 m vs 141.6 m (12.3 %) | units walk nat_node_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b1 vs keep_t1-peddler_a2 | 131.5 m vs 149.9 m (12.3 %) | units walk keep_t1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-stag_b1 vs nat_node_b2-stag_a2 | 141.5 m vs 124.1 m (12.3 %) | units walk nat_node_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-stag_b1 vs nat_node_a2-stag_b2 | 141.5 m vs 124.1 m (12.3 %) | units walk nat_node_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-peddler_a2 vs keep_t4-peddler_a1 | 149.9 m vs 131.6 m (12.2 %) | units walk keep_t1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-shrine_a1 vs tower_c_a2-shrine_a2 | 27.6 m vs 31.3 m (12.1 %) | units walk tower_c_a2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_a_a1 vs guilds_lodge_b2-cache_a_b1 | 163.6 m vs 144.1 m (11.9 %) | units walk guilds_lodge_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_a_b2 vs guilds_lodge_b2-cache_a_b1 | 163.6 m vs 144.1 m (11.9 %) | units walk guilds_lodge_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_b1-cache_a_b2 | 144.1 m vs 163.6 m (11.9 %) | units walk guilds_lodge_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_a2-cache_a_a1 | 144.1 m vs 163.6 m (11.9 %) | units walk guilds_lodge_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-shrine_a2 vs tower_c_b1-shrine_b1 | 31.3 m vs 27.6 m (11.9 %) | units walk tower_c_a2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_two_b2 vs cache_a_b2-lairs_two_a2 | 180.9 m vs 205.1 m (11.8 %) | units walk cache_a_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-lairs_two_a1 vs cache_a_b2-lairs_two_a2 | 180.9 m vs 205.1 m (11.8 %) | units walk cache_a_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-x_ford_n vs post_w_b2-x_ford_s | 94.8 m vs 83.7 m (11.8 %) | units walk post_w_b1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_ford_s vs post_w_b1-x_ford_n | 83.7 m vs 94.8 m (11.8 %) | units walk post_w_b1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-x_ford_n vs post_w_b2-x_ford_s | 94.8 m vs 83.7 m (11.8 %) | units walk post_w_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_ford_s vs post_w_a2-x_ford_n | 83.7 m vs 94.8 m (11.8 %) | units walk post_w_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-inn_a1 vs wallow_b1-inn_b2 | 85.4 m vs 96.8 m (11.7 %) | units walk wallow_b1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-stag_b1 vs home_b_b2-stag_a2 | 171.0 m vs 151.2 m (11.6 %) | units walk home_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-shrine_a1 vs tower_c_b2-shrine_b2 | 27.6 m vs 31.1 m (11.5 %) | units walk tower_c_b2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b2 vs wallow_b1-peddler_a2 | 162.6 m vs 144.0 m (11.4 %) | units walk wallow_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b2 vs wallow_a2-peddler_b1 | 162.6 m vs 144.0 m (11.4 %) | units walk wallow_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b2 vs wallow_b2-peddler_a1 | 162.6 m vs 144.0 m (11.4 %) | units walk wallow_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b2 vs home_b_a2-peddler_b1 | 144.1 m vs 127.7 m (11.4 %) | units walk home_b_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b2 vs home_b_b1-peddler_a2 | 144.1 m vs 127.7 m (11.4 %) | units walk home_b_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b2 vs home_b_b2-peddler_a1 | 144.1 m vs 127.7 m (11.4 %) | units walk home_b_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-shrine_b1 vs tower_c_b2-shrine_b2 | 27.6 m vs 31.1 m (11.3 %) | units walk tower_c_b2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_a2 vs rich_node_b1-wallow_b2 | 118.2 m vs 133.2 m (11.3 %) | units walk rich_node_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-wallow_b2 vs rich_node_b2-wallow_b1 | 133.2 m vs 118.2 m (11.3 %) | units walk rich_node_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_b_b1 vs well_b2-cache_b_a2 | 120.1 m vs 106.6 m (11.3 %) | units walk well_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-inn_b1 vs third_node_a2-inn_b2 | 162.8 m vs 144.5 m (11.3 %) | units walk third_node_a1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-inn_b1 vs third_node_b1-inn_a1 | 162.8 m vs 144.5 m (11.3 %) | units walk third_node_a1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-inn_b2 vs third_node_b2-inn_a2 | 144.5 m vs 162.8 m (11.3 %) | units walk third_node_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-inn_a1 vs third_node_b2-inn_a2 | 144.5 m vs 162.8 m (11.3 %) | units walk third_node_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-inn_a2 vs home_a_b2-inn_a1 | 116.3 m vs 103.3 m (11.1 %) | units walk home_a_b1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b2 vs home_a_b1-inn_a2 | 103.3 m vs 116.3 m (11.1 %) | units walk home_a_b1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-lairs_one_a1 vs cache_a_b2-lairs_one_a2 | 193.6 m vs 217.8 m (11.1 %) | units walk cache_a_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_one_b2 vs cache_a_b2-lairs_one_a2 | 193.6 m vs 217.8 m (11.1 %) | units walk cache_a_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-inn_b1 vs home_a_b2-inn_a1 | 116.2 m vs 103.3 m (11.1 %) | units walk home_a_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b2 vs home_a_a2-inn_b1 | 103.3 m vs 116.2 m (11.1 %) | units walk home_a_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-stag_a1 vs wallow_b2-stag_a2 | 189.7 m vs 169.2 m (10.8 %) | units walk wallow_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-post_s_a1 vs third_node_b2-post_s_a2 | 241.4 m vs 215.3 m (10.8 %) | units walk third_node_b1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-stag_b1 vs home_b_a2-stag_b2 | 171.0 m vs 152.5 m (10.8 %) | units walk home_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-stag_b2 vs wallow_b1-stag_a1 | 169.2 m vs 189.7 m (10.8 %) | units walk wallow_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_a1 vs rich_node_b1-stag_b1 | 30.6 m vs 34.3 m (10.8 %) | units walk rich_node_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_b1 vs wallow_b2-stag_a2 | 189.5 m vs 169.2 m (10.8 %) | units walk wallow_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_b1 vs wallow_a2-stag_b2 | 189.5 m vs 169.2 m (10.7 %) | units walk wallow_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_s_b1 vs third_node_b2-post_s_a2 | 241.1 m vs 215.3 m (10.7 %) | units walk third_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_a1 vs rich_node_b2-stag_b2 | 30.6 m vs 34.3 m (10.7 %) | units walk rich_node_b2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-shrine_b2 vs third_node_b2-shrine_a2 | 158.4 m vs 177.3 m (10.6 %) | units walk third_node_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-shrine_b1 vs third_node_b1-shrine_a2 | 177.3 m vs 158.4 m (10.6 %) | units walk third_node_a2-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b2 vs third_node_a2-shrine_b1 | 158.4 m vs 177.3 m (10.6 %) | units walk third_node_a2-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-shrine_b2 vs third_node_b1-shrine_a1 | 158.4 m vs 177.2 m (10.6 %) | units walk third_node_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_s_a2 vs rich_node_b2-post_s_b2 | 46.6 m vs 41.8 m (10.5 %) | units walk rich_node_a2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_s_a1 vs rich_node_a2-post_s_a2 | 41.8 m vs 46.6 m (10.5 %) | units walk rich_node_a2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b1 vs third_node_b2-shrine_a2 | 158.7 m vs 177.3 m (10.5 %) | units walk third_node_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b1 vs third_node_b1-shrine_a1 | 158.7 m vs 177.2 m (10.5 %) | units walk third_node_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-well_a2 vs home_a_b2-well_a1 | 127.2 m vs 114.0 m (10.4 %) | units walk home_a_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-well_b2 vs home_a_b1-well_a2 | 114.0 m vs 127.2 m (10.4 %) | units walk home_a_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-well_b1 vs home_a_b2-well_a1 | 127.2 m vs 114.0 m (10.4 %) | units walk home_a_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-well_b2 vs home_a_a2-well_b1 | 114.0 m vs 127.2 m (10.4 %) | units walk home_a_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-wallow_a1 vs rich_node_b1-wallow_b2 | 119.4 m vs 133.2 m (10.4 %) | units walk rich_node_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-x_ford_s vs wallow_b1-x_ford_s | 113.3 m vs 126.2 m (10.2 %) | units walk wallow_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-ford_nest_a2 vs wallow_b1-ford_nest_a1 | 113.3 m vs 126.2 m (10.2 %) | units walk wallow_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 126.2 m vs 113.3 m (10.2 %) | units walk wallow_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-x_ford_s vs wallow_b2-x_ford_n | 126.2 m vs 113.3 m (10.2 %) | units walk wallow_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-x_ford_n vs wallow_b1-x_ford_s | 113.3 m vs 126.2 m (10.2 %) | units walk wallow_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-ford_nest_a1 vs wallow_b1-ford_nest_a1 | 113.3 m vs 126.2 m (10.2 %) | units walk wallow_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-nat_node_b1 vs home_a_b2-nat_node_a1 | 126.3 m vs 113.4 m (10.2 %) | units walk home_a_a2-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-nat_node_b2 vs home_a_a2-nat_node_b1 | 113.4 m vs 126.3 m (10.2 %) | units walk home_a_a2-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_s_a1 vs rich_node_b1-post_s_b1 | 41.8 m vs 46.5 m (10.2 %) | units walk rich_node_b1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_s_b1 vs rich_node_b2-post_s_b2 | 46.5 m vs 41.8 m (10.2 %) | units walk rich_node_b1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_bridge_n vs well_b2-x_bridge_n | 135.4 m vs 121.6 m (10.2 %) | units walk well_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_bridge_n vs well_a2-x_bridge_s | 135.4 m vs 121.9 m (9.9 %) | units walk well_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-x_bridge_s vs well_b2-x_bridge_n | 135.0 m vs 121.6 m (9.9 %) | units walk well_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_b1-x_lane_w vs cache_b_b2-x_lane_w | 48.1 m vs 53.3 m (9.9 %) | units walk cache_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a2-x_lane_e vs cache_b_b2-x_lane_w | 48.1 m vs 53.3 m (9.9 %) | units walk cache_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-post_w_b2 vs third_node_b1-post_w_a1 | 186.2 m vs 206.7 m (9.9 %) | units walk third_node_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-peddler_b2 vs third_node_b1-peddler_a1 | 170.4 m vs 189.0 m (9.8 %) | units walk third_node_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-peddler_b1 vs third_node_a2-peddler_b2 | 188.9 m vs 170.4 m (9.8 %) | units walk third_node_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-peddler_b2 vs third_node_b2-peddler_a2 | 170.4 m vs 188.9 m (9.8 %) | units walk third_node_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-cache_b_b1 vs post_w_b2-cache_b_a1 | 107.8 m vs 97.3 m (9.8 %) | units walk post_w_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-x_bridge_s vs well_b1-x_bridge_s | 121.9 m vs 135.0 m (9.7 %) | units walk well_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-cache_b_a2 vs post_w_b2-cache_b_a1 | 107.7 m vs 97.3 m (9.7 %) | units walk post_w_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-keep_t4 vs keep_t3-keep_t1 | 151.6 m vs 137.0 m (9.6 %) | units walk keep_t0-keep_t4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a1-x_lane_e vs cache_b_b2-x_lane_w | 48.2 m vs 53.3 m (9.6 %) | units walk cache_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-cache_b_b2 vs post_w_a2-cache_b_b1 | 97.5 m vs 107.8 m (9.6 %) | units walk post_w_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-cache_b_b2 vs post_w_b1-cache_b_a2 | 97.5 m vs 107.7 m (9.5 %) | units walk post_w_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_two_b1 vs cache_a_b2-lairs_two_a2 | 185.7 m vs 205.1 m (9.5 %) | units walk cache_a_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-cache_b_a1 vs wallow_b2-cache_b_a2 | 139.4 m vs 126.1 m (9.5 %) | units walk wallow_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-peddler_b1 vs tower_c_b1-peddler_a2 | 98.9 m vs 89.5 m (9.5 %) | units walk tower_c_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-lairs_two_b1 vs peddler_b2-lairs_two_b2 | 51.0 m vs 56.4 m (9.5 %) | units walk peddler_b2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_two_a1 vs peddler_b1-lairs_two_b1 | 56.4 m vs 51.0 m (9.5 %) | units walk peddler_a1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-lairs_two_a2 vs peddler_b2-lairs_two_b2 | 51.0 m vs 56.4 m (9.5 %) | units walk peddler_b2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_two_a1 vs peddler_a2-lairs_two_a2 | 56.4 m vs 51.0 m (9.5 %) | units walk peddler_a1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-stag_b1 vs home_b_b1-stag_a1 | 171.0 m vs 154.8 m (9.5 %) | units walk home_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_b2 vs tower_c_a2-peddler_b1 | 89.5 m vs 98.9 m (9.4 %) | units walk tower_c_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b_b1 vs wallow_b1-cache_b_a1 | 126.3 m vs 139.4 m (9.4 %) | units walk wallow_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-shrine_a1 vs well_b2-shrine_a2 | 108.3 m vs 119.5 m (9.4 %) | units walk well_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b1 vs well_b1-shrine_a1 | 119.5 m vs 108.3 m (9.4 %) | units walk well_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-rich_node_a2 vs nat_node_b2-rich_node_a1 | 65.9 m vs 72.7 m (9.4 %) | units walk nat_node_b2-rich_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_b2 vs nat_node_b2-rich_node_a1 | 65.9 m vs 72.7 m (9.4 %) | units walk nat_node_b2-rich_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-stag_a2 vs tower_c_b1-stag_b1 | 82.7 m vs 75.0 m (9.3 %) | units walk tower_c_a2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-peddler_b1 vs nat_node_b1-peddler_a2 | 103.9 m vs 114.6 m (9.3 %) | units walk nat_node_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-peddler_b2 vs nat_node_a2-peddler_b1 | 114.5 m vs 103.9 m (9.3 %) | units walk nat_node_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-peddler_a2 vs nat_node_b2-peddler_a1 | 114.6 m vs 104.0 m (9.2 %) | units walk nat_node_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a1 vs tower_c_b1-stag_b1 | 82.6 m vs 75.0 m (9.2 %) | units walk tower_c_a1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-peddler_b2 vs nat_node_b2-peddler_a1 | 114.5 m vs 104.0 m (9.2 %) | units walk nat_node_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_w_b1 vs third_node_a2-post_w_b2 | 205.0 m vs 186.2 m (9.2 %) | units walk third_node_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-post_w_b2 vs third_node_b2-post_w_a2 | 186.2 m vs 205.0 m (9.2 %) | units walk third_node_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-shrine_b2 vs well_b1-shrine_a1 | 119.2 m vs 108.3 m (9.1 %) | units walk well_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-stag_b1 vs tower_c_b2-stag_b2 | 75.0 m vs 82.5 m (9.1 %) | units walk tower_c_b2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-rich_node_b1 vs nat_node_b1-rich_node_a2 | 72.5 m vs 65.9 m (9.1 %) | units walk nat_node_a2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-cache_a_a1 vs peddler_b2-cache_a_a2 | 154.6 m vs 140.5 m (9.1 %) | units walk peddler_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_b2 vs nat_node_a2-rich_node_b1 | 65.9 m vs 72.5 m (9.1 %) | units walk nat_node_a2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-cache_a_b2 vs peddler_b1-cache_a_a1 | 140.6 m vs 154.6 m (9.1 %) | units walk peddler_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-post_s_b2 vs home_b_b2-post_s_a2 | 181.1 m vs 164.7 m (9.1 %) | units walk home_b_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_bridge_s vs tower_c_a2-x_bridge_n | 65.4 m vs 59.5 m (9.0 %) | units walk tower_c_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-cache_b_a2 vs post_w_b2-cache_b_b2 | 82.1 m vs 74.7 m (9.0 %) | units walk post_w_a2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-cache_b_a1 vs post_w_a2-cache_b_a2 | 74.7 m vs 82.1 m (9.0 %) | units walk post_w_a2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-cache_b_b1 vs post_w_b2-cache_b_b2 | 82.1 m vs 74.7 m (9.0 %) | units walk post_w_b1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-cache_b_a1 vs post_w_b1-cache_b_b1 | 74.7 m vs 82.1 m (9.0 %) | units walk post_w_b1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_b1 vs cache_a_b2-lairs_one_a2 | 198.4 m vs 217.8 m (8.9 %) | units walk cache_a_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-lairs_one_a1 vs post_w_b2-lairs_one_a2 | 193.4 m vs 176.3 m (8.9 %) | units walk post_w_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_bridge_s vs tower_c_b2-x_bridge_s | 65.4 m vs 59.7 m (8.8 %) | units walk tower_c_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-x_bridge_n vs cache_a_a2-x_bridge_s | 153.1 m vs 139.7 m (8.8 %) | units walk cache_a_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-inn_a1 vs wallow_b2-inn_b1 | 85.4 m vs 93.6 m (8.7 %) | units walk wallow_b2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-inn_a2 vs wallow_a2-inn_a1 | 93.6 m vs 85.4 m (8.7 %) | units walk wallow_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-cache_b_b2 vs wallow_b1-cache_b_a1 | 127.2 m vs 139.4 m (8.7 %) | units walk wallow_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-lairs_two_a2 vs home_a_b2-lairs_two_a1 | 157.3 m vs 143.6 m (8.7 %) | units walk home_a_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_b2 vs home_a_b1-lairs_two_a2 | 143.6 m vs 157.3 m (8.7 %) | units walk home_a_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-home_b_a2 vs home_a_b2-home_b_a1 | 150.1 m vs 137.1 m (8.7 %) | units walk home_a_b1-home_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-home_b_b2 vs home_a_b1-home_b_a2 | 137.1 m vs 150.1 m (8.7 %) | units walk home_a_b1-home_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-cache_a_a1 vs keep_t4-cache_a_a2 | 162.3 m vs 148.2 m (8.7 %) | units walk keep_t1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-cache_a_b2 vs keep_t1-cache_a_a1 | 148.3 m vs 162.3 m (8.6 %) | units walk keep_t1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-home_b_b1 vs home_a_b2-home_b_a1 | 150.0 m vs 137.1 m (8.6 %) | units walk home_a_a2-home_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a1-cache_b_b1 vs cache_b_b2-cache_b_a2 | 77.5 m vs 70.8 m (8.6 %) | units walk cache_b_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-home_b_b2 vs home_a_a2-home_b_b1 | 137.1 m vs 150.0 m (8.6 %) | units walk home_a_a2-home_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b2 vs keep_t3-peddler_b1 | 144.0 m vs 131.5 m (8.6 %) | units walk keep_t0-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b2 vs keep_t4-peddler_a1 | 144.0 m vs 131.6 m (8.6 %) | units walk keep_t0-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-x_bridge_s vs cache_a_b2-x_bridge_n | 139.7 m vs 152.7 m (8.5 %) | units walk cache_a_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_b1 vs shrine_b2-lairs_one_a2 | 163.7 m vs 149.7 m (8.5 %) | units walk shrine_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-x_bridge_n vs tower_c_b1-x_bridge_n | 59.5 m vs 65.1 m (8.5 %) | units walk tower_c_b1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-post_s_b2 vs keep_t4-post_s_a2 | 177.3 m vs 162.2 m (8.5 %) | units walk keep_t3-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_b1 vs shrine_a2-lairs_one_b2 | 163.7 m vs 149.8 m (8.5 %) | units walk shrine_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-stag_b2 vs well_b2-stag_a2 | 163.5 m vs 149.6 m (8.5 %) | units walk well_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-stag_a1 vs well_b2-stag_a2 | 163.5 m vs 149.6 m (8.5 %) | units walk well_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_b1 vs well_b2-stag_a2 | 163.5 m vs 149.6 m (8.5 %) | units walk well_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-lairs_one_b1 vs stag_b2-lairs_one_b2 | 27.6 m vs 25.3 m (8.5 %) | units walk stag_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_one_a1 vs stag_b1-lairs_one_b1 | 25.3 m vs 27.6 m (8.5 %) | units walk stag_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_one_a2 vs stag_b2-lairs_one_b2 | 27.6 m vs 25.3 m (8.5 %) | units walk stag_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_one_a1 vs stag_a2-lairs_one_a2 | 25.3 m vs 27.6 m (8.5 %) | units walk stag_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b1 vs home_b_b1-well_a1 | 135.7 m vs 148.3 m (8.5 %) | units walk home_b_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-cache_a_b2 vs home_b_b1-cache_a_a1 | 152.0 m vs 166.1 m (8.4 %) | units walk home_b_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-well_a1 vs home_b_b2-well_a2 | 148.3 m vs 135.8 m (8.4 %) | units walk home_b_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_c_b2 vs third_node_b1-tower_c_a2 | 128.9 m vs 118.1 m (8.4 %) | units walk third_node_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-home_a_a2 vs keep_t4-home_a_a1 | 153.9 m vs 141.0 m (8.4 %) | units walk keep_t1-home_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_a_b1 vs keep_t4-home_a_a1 | 153.9 m vs 141.0 m (8.4 %) | units walk keep_t3-home_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-post_s_b2 vs keep_t1-post_s_a1 | 177.3 m vs 162.4 m (8.4 %) | units walk keep_t3-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_c_b2 vs third_node_b2-tower_c_a1 | 128.9 m vs 118.1 m (8.4 %) | units walk third_node_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_c_b2 vs third_node_a2-tower_c_b1 | 128.9 m vs 118.1 m (8.3 %) | units walk third_node_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-x_bridge_n vs tower_c_b2-x_bridge_s | 65.1 m vs 59.7 m (8.3 %) | units walk tower_c_b1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_a_b1 vs home_b_a2-cache_a_b2 | 165.7 m vs 152.0 m (8.3 %) | units walk home_b_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-lairs_one_b2 vs post_w_b1-lairs_one_a1 | 177.6 m vs 193.4 m (8.1 %) | units walk post_w_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-post_s_b2 vs home_b_b1-post_s_a1 | 181.1 m vs 166.3 m (8.1 %) | units walk home_b_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_one_a1 vs home_b_b2-lairs_one_a2 | 192.8 m vs 177.2 m (8.1 %) | units walk home_b_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_one_b2 vs home_b_b2-lairs_one_a2 | 192.8 m vs 177.2 m (8.1 %) | units walk home_b_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-post_s_b2 vs third_node_b1-post_s_a1 | 221.9 m vs 241.4 m (8.1 %) | units walk third_node_b1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_s_b1 vs keep_t3-post_s_b2 | 163.0 m vs 177.3 m (8.0 %) | units walk keep_t3-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-lairs_two_b1 vs third_node_b1-lairs_two_a1 | 240.2 m vs 220.9 m (8.0 %) | units walk third_node_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-lairs_two_b1 vs third_node_a2-lairs_two_b2 | 240.2 m vs 220.9 m (8.0 %) | units walk third_node_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-post_w_b2 vs home_a_b2-post_w_b1 | 33.9 m vs 31.2 m (8.0 %) | units walk home_a_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-post_w_a1 vs home_a_b2-post_w_b1 | 33.9 m vs 31.2 m (8.0 %) | units walk home_a_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_w_a2 vs home_a_b1-post_w_b2 | 31.2 m vs 33.9 m (8.0 %) | units walk home_a_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_w_a2 vs home_a_a2-post_w_a1 | 31.2 m vs 33.9 m (8.0 %) | units walk home_a_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_s_b1 vs third_node_a2-post_s_b2 | 241.1 m vs 221.9 m (8.0 %) | units walk third_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-cache_b_a1 vs peddler_b2-cache_b_a2 | 106.5 m vs 98.1 m (8.0 %) | units walk peddler_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_one_a1 vs rich_node_b2-lairs_one_b2 | 57.7 m vs 62.6 m (7.9 %) | units walk rich_node_b2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-lairs_one_a1 vs peddler_b2-lairs_one_a2 | 181.3 m vs 167.0 m (7.9 %) | units walk peddler_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-lairs_one_b2 vs peddler_b2-lairs_one_a2 | 181.3 m vs 167.0 m (7.9 %) | units walk peddler_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_b_b1 vs peddler_b1-cache_b_a1 | 98.2 m vs 106.5 m (7.8 %) | units walk peddler_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_b2 vs home_a_b1-wallow_a2 | 153.4 m vs 166.5 m (7.8 %) | units walk home_a_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-wallow_a2 vs home_a_b2-wallow_a1 | 166.5 m vs 153.5 m (7.8 %) | units walk home_a_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_one_b1 vs home_a_b1-lairs_one_a1 | 170.8 m vs 185.3 m (7.8 %) | units walk home_a_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_b2 vs home_a_a2-wallow_b1 | 153.4 m vs 166.4 m (7.8 %) | units walk home_a_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-wallow_b1 vs home_a_b2-wallow_a1 | 166.4 m vs 153.5 m (7.8 %) | units walk home_a_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-lairs_one_b2 vs home_a_b1-lairs_one_a1 | 170.9 m vs 185.3 m (7.8 %) | units walk home_a_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-lairs_one_b1 vs post_w_b2-lairs_one_a2 | 191.1 m vs 176.3 m (7.8 %) | units walk post_w_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b1 vs keep_t1-well_a1 | 133.3 m vs 144.5 m (7.8 %) | units walk keep_t1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-lairs_two_b1 vs home_a_b1-lairs_two_a2 | 145.2 m vs 157.3 m (7.7 %) | units walk home_a_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-well_a1 vs keep_t4-well_a2 | 144.5 m vs 133.3 m (7.7 %) | units walk keep_t1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-well_b2 vs keep_t1-well_a1 | 133.3 m vs 144.5 m (7.7 %) | units walk keep_t1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-guilds_den_a1 vs post_w_b2-guilds_den_a2 | 196.0 m vs 181.0 m (7.7 %) | units walk post_w_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-lairs_one_a1 vs home_a_b2-lairs_one_a2 | 185.3 m vs 171.1 m (7.7 %) | units walk home_a_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t4-wallow_a2 | 164.9 m vs 178.5 m (7.6 %) | units walk keep_t4-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_lodge_b1 vs third_node_b2-guilds_lodge_a2 | 235.4 m vs 254.8 m (7.6 %) | units walk third_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-cache_b_b2 vs peddler_b1-cache_b_a1 | 98.4 m vs 106.5 m (7.6 %) | units walk peddler_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-peddler_b2 vs peddler_a2-peddler_b1 | 136.4 m vs 126.1 m (7.6 %) | units walk peddler_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-lairs_one_b2 vs keep_t4-lairs_one_a2 | 189.0 m vs 174.7 m (7.6 %) | units walk keep_t3-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-lairs_one_a1 vs keep_t4-lairs_one_a2 | 189.0 m vs 174.7 m (7.6 %) | units walk keep_t1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_b1 vs well_b1-post_w_a1 | 147.2 m vs 136.1 m (7.5 %) | units walk well_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_w_a1 vs well_b2-post_w_a2 | 136.1 m vs 147.2 m (7.5 %) | units walk well_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_b1 vs home_a_a2-lairs_two_b2 | 159.5 m vs 172.6 m (7.5 %) | units walk home_a_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_b1 vs home_a_b1-lairs_two_a1 | 159.5 m vs 172.6 m (7.5 %) | units walk home_a_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-guilds_lodge_b2 vs third_node_b2-guilds_lodge_a2 | 235.6 m vs 254.8 m (7.5 %) | units walk third_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-guilds_lodge_a1 vs third_node_b2-guilds_lodge_a2 | 235.6 m vs 254.8 m (7.5 %) | units walk third_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-well_b2 vs home_b_b1-well_a1 | 137.1 m vs 148.3 m (7.5 %) | units walk home_b_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-cache_b_a1 vs keep_t4-cache_b_a2 | 114.2 m vs 105.7 m (7.4 %) | units walk keep_t1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_w_b2 vs well_b1-post_w_a1 | 147.0 m vs 136.1 m (7.4 %) | units walk well_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-lairs_two_b2 vs home_a_b2-lairs_two_a2 | 172.6 m vs 159.8 m (7.4 %) | units walk home_a_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-lairs_two_a1 vs home_a_b2-lairs_two_a2 | 172.6 m vs 159.8 m (7.4 %) | units walk home_a_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_b_b1 vs keep_t1-cache_b_a1 | 105.9 m vs 114.2 m (7.3 %) | units walk keep_t1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-peddler_b1 vs home_a_b2-peddler_a1 | 146.2 m vs 135.5 m (7.3 %) | units walk home_a_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-peddler_a2 vs home_a_b2-peddler_a1 | 146.2 m vs 135.5 m (7.3 %) | units walk home_a_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-stag_a2 vs rich_node_b1-stag_b1 | 31.8 m vs 34.3 m (7.3 %) | units walk rich_node_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-lairs_one_a1 vs shrine_b2-lairs_one_a2 | 161.4 m vs 149.7 m (7.2 %) | units walk shrine_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-cache_a_a1 vs home_b_b2-cache_a_a2 | 166.1 m vs 154.1 m (7.2 %) | units walk home_b_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a1-x_bridge_s vs cache_b_a2-x_bridge_n | 43.8 m vs 40.6 m (7.2 %) | units walk cache_b_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-lairs_one_b2 vs shrine_b1-lairs_one_a1 | 149.8 m vs 161.4 m (7.2 %) | units walk shrine_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_den_b1 vs shrine_b2-guilds_den_a2 | 166.4 m vs 154.5 m (7.2 %) | units walk shrine_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-stag_a2 vs rich_node_b2-stag_b2 | 31.8 m vs 34.3 m (7.2 %) | units walk rich_node_b2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_den_b1 vs shrine_a2-guilds_den_b2 | 166.4 m vs 154.5 m (7.1 %) | units walk shrine_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-peddler_b2 vs home_a_b2-peddler_a1 | 146.0 m vs 135.5 m (7.1 %) | units walk home_a_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-cache_b_b2 vs keep_t1-cache_b_a1 | 106.1 m vs 114.2 m (7.1 %) | units walk keep_t1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-lairs_one_b1 vs post_w_a2-lairs_one_b2 | 191.1 m vs 177.6 m (7.0 %) | units walk post_w_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_a_b1 vs home_b_b2-cache_a_a2 | 165.7 m vs 154.1 m (7.0 %) | units walk home_b_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-wallow_b1 vs third_node_b2-wallow_a2 | 215.0 m vs 231.3 m (7.0 %) | units walk third_node_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-guilds_den_b2 vs post_w_b1-guilds_den_a1 | 182.4 m vs 196.0 m (7.0 %) | units walk post_w_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-peddler_b1 vs shrine_b1-peddler_a2 | 125.0 m vs 116.3 m (6.9 %) | units walk shrine_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-x_bridge_s vs lairs_one_b1-x_bridge_s | 177.9 m vs 165.8 m (6.8 %) | units walk lairs_one_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-x_bridge_s vs cache_a_b1-x_bridge_s | 139.7 m vs 149.8 m (6.8 %) | units walk cache_a_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-x_lane_e vs peddler_b1-x_lane_w | 78.4 m vs 84.0 m (6.8 %) | units walk peddler_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-x_lane_w vs peddler_b2-x_lane_w | 84.0 m vs 78.4 m (6.8 %) | units walk peddler_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-x_lane_e vs peddler_b2-x_lane_w | 84.0 m vs 78.4 m (6.8 %) | units walk peddler_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-x_lane_e vs peddler_a2-x_lane_e | 78.4 m vs 84.0 m (6.8 %) | units walk peddler_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-cache_a_a2 vs nat_node_b2-cache_a_a1 | 97.4 m vs 104.4 m (6.8 %) | units walk nat_node_b2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-cache_a_b2 vs nat_node_b2-cache_a_a1 | 97.4 m vs 104.4 m (6.7 %) | units walk nat_node_b2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_b1 vs rich_node_a2-wallow_b2 | 138.1 m vs 148.0 m (6.7 %) | units walk rich_node_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_b1 vs rich_node_b1-wallow_a1 | 138.1 m vs 148.0 m (6.7 %) | units walk rich_node_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-wallow_b2 vs rich_node_b2-wallow_a2 | 148.0 m vs 138.1 m (6.7 %) | units walk rich_node_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a1-x_bridge_s vs cache_b_b2-x_bridge_s | 43.8 m vs 40.9 m (6.7 %) | units walk cache_b_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-wallow_a1 vs rich_node_b2-wallow_a2 | 148.0 m vs 138.1 m (6.7 %) | units walk rich_node_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-x_bridge_s vs lairs_one_b2-x_bridge_n | 165.8 m vs 177.6 m (6.7 %) | units walk lairs_one_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_a2 vs third_node_b2-cache_b_b1 | 124.4 m vs 116.2 m (6.6 %) | units walk third_node_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_a2 vs third_node_a2-cache_b_a1 | 124.4 m vs 116.2 m (6.6 %) | units walk third_node_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_b_b2 vs third_node_b2-cache_b_b1 | 124.4 m vs 116.2 m (6.6 %) | units walk third_node_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_b_a1 vs third_node_b1-cache_b_b2 | 116.2 m vs 124.4 m (6.6 %) | units walk third_node_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-guilds_den_b1 vs post_w_b2-guilds_den_a2 | 193.8 m vs 181.0 m (6.6 %) | units walk post_w_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-cache_a_b1 vs nat_node_b1-cache_a_a2 | 104.2 m vs 97.4 m (6.6 %) | units walk nat_node_a2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_den_b1 vs home_a_b1-guilds_den_a1 | 175.5 m vs 187.9 m (6.6 %) | units walk home_a_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-cache_a_b2 vs nat_node_a2-cache_a_b1 | 97.4 m vs 104.2 m (6.6 %) | units walk nat_node_a2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-guilds_den_b2 vs home_a_b1-guilds_den_a1 | 175.6 m vs 187.9 m (6.6 %) | units walk home_a_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t3-wallow_b2 | 164.9 m vs 176.5 m (6.5 %) | units walk keep_t3-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t1-wallow_a1 | 164.9 m vs 176.5 m (6.5 %) | units walk keep_t1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-wallow_b1 vs tower_r_b1-wallow_a1 | 142.1 m vs 152.0 m (6.5 %) | units walk tower_r_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a2-x_bridge_n vs cache_b_b1-x_bridge_n | 40.6 m vs 43.5 m (6.5 %) | units walk cache_b_b1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-wallow_b1 vs tower_r_a2-wallow_b2 | 142.1 m vs 152.0 m (6.5 %) | units walk tower_r_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-cache_b_b1 vs inn_a2-cache_b_b2 | 80.2 m vs 75.0 m (6.5 %) | units walk inn_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-cache_b_b1 vs inn_b1-cache_b_a1 | 80.2 m vs 75.0 m (6.5 %) | units walk inn_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-wallow_a1 vs tower_r_b2-wallow_a2 | 152.0 m vs 142.2 m (6.5 %) | units walk tower_r_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-wallow_b2 vs tower_r_b2-wallow_a2 | 152.0 m vs 142.2 m (6.5 %) | units walk tower_r_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-cache_b_b2 vs inn_b2-cache_b_a2 | 75.0 m vs 80.2 m (6.5 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-cache_b_a1 vs inn_b2-cache_b_a2 | 75.0 m vs 80.2 m (6.5 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-guilds_den_a1 vs home_a_b2-guilds_den_a2 | 187.9 m vs 175.8 m (6.4 %) | units walk home_a_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-wallow_b1 vs tower_c_b2-wallow_a2 | 116.1 m vs 124.0 m (6.4 %) | units walk tower_c_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-guilds_den_b2 vs keep_t4-guilds_den_a2 | 191.7 m vs 179.5 m (6.4 %) | units walk keep_t3-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-guilds_den_a1 vs keep_t4-guilds_den_a2 | 191.7 m vs 179.5 m (6.4 %) | units walk keep_t1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_b2 vs shrine_a2-inn_b1 | 93.2 m vs 87.2 m (6.4 %) | units walk shrine_a1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_b_a1 vs guilds_lodge_b2-cache_b_a2 | 180.1 m vs 168.7 m (6.3 %) | units walk guilds_lodge_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_b_b2 vs guilds_lodge_b2-cache_b_a2 | 180.1 m vs 168.7 m (6.3 %) | units walk guilds_lodge_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_a_a1 vs guilds_lodge_b2-cache_a_a2 | 217.0 m vs 203.3 m (6.3 %) | units walk guilds_lodge_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_a_b2 vs guilds_lodge_b2-cache_a_a2 | 217.0 m vs 203.3 m (6.3 %) | units walk guilds_lodge_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_lane_w vs shrine_b1-x_lane_e | 41.0 m vs 38.5 m (6.2 %) | units walk shrine_a2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_b2 vs shrine_b2-inn_a1 | 93.2 m vs 87.4 m (6.2 %) | units walk shrine_a1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_b1-cache_b_a1 | 168.9 m vs 180.1 m (6.2 %) | units walk guilds_lodge_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_a2-cache_b_b2 | 168.9 m vs 180.1 m (6.2 %) | units walk guilds_lodge_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_b1 vs guilds_lodge_b2-cache_a_a2 | 216.7 m vs 203.3 m (6.2 %) | units walk guilds_lodge_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-nat_node_b1 vs home_a_b1-nat_node_a2 | 126.3 m vs 118.5 m (6.2 %) | units walk home_a_a2-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-wallow_b2 vs tower_r_b2-wallow_a1 | 98.8 m vs 105.1 m (6.1 %) | units walk tower_r_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_bridge_n vs lairs_one_a2-x_bridge_s | 167.2 m vs 177.9 m (6.0 %) | units walk lairs_one_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_b1-x_bridge_n vs cache_b_b2-x_bridge_s | 43.5 m vs 40.9 m (6.0 %) | units walk cache_b_b1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_w_a2 vs keep_t3-post_w_a1 | 40.4 m vs 43.0 m (6.0 %) | units walk keep_t3-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-post_w_a1 vs keep_t4-post_w_b1 | 43.0 m vs 40.4 m (6.0 %) | units walk keep_t3-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_w_a2 vs keep_t1-post_w_b2 | 40.4 m vs 43.0 m (6.0 %) | units walk keep_t1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-post_w_b2 vs keep_t4-post_w_b1 | 43.0 m vs 40.4 m (6.0 %) | units walk keep_t1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-third_node_b1 vs home_b_b1-third_node_a1 | 178.1 m vs 189.3 m (5.9 %) | units walk home_b_b1-third_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-third_node_a1 vs home_b_b2-third_node_a2 | 189.3 m vs 178.1 m (5.9 %) | units walk home_b_b1-third_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-x_lane_e vs shrine_b2-x_lane_e | 38.5 m vs 40.9 m (5.9 %) | units walk shrine_b2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_lane_w vs shrine_b1-x_lane_e | 40.9 m vs 38.5 m (5.9 %) | units walk shrine_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-peddler_a2 vs tower_c_b2-peddler_a1 | 89.5 m vs 95.1 m (5.9 %) | units walk tower_c_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-guilds_den_b1 vs post_w_a2-guilds_den_b2 | 193.8 m vs 182.4 m (5.9 %) | units walk post_w_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_w_b2 vs inn_b2-post_w_a1 | 121.0 m vs 113.9 m (5.9 %) | units walk inn_a1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_bridge_n vs lairs_one_b2-x_bridge_n | 167.2 m vs 177.6 m (5.9 %) | units walk lairs_one_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-wallow_a1 vs home_a_b2-wallow_b1 | 65.8 m vs 62.0 m (5.9 %) | units walk home_a_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_a2 vs home_a_a2-wallow_a1 | 62.0 m vs 65.8 m (5.9 %) | units walk home_a_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-wallow_b2 vs home_a_b2-wallow_b1 | 65.8 m vs 62.0 m (5.9 %) | units walk home_a_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_a2 vs home_a_b1-wallow_b2 | 62.0 m vs 65.8 m (5.9 %) | units walk home_a_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_b2 vs tower_c_b2-peddler_a1 | 89.5 m vs 95.1 m (5.9 %) | units walk tower_c_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_a1 vs home_a_b1-lairs_two_b1 | 58.6 m vs 62.2 m (5.8 %) | units walk home_a_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_a1 vs home_a_a2-lairs_two_a2 | 58.6 m vs 62.2 m (5.8 %) | units walk home_a_a2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-lairs_two_a2 vs home_a_b2-lairs_two_b2 | 62.2 m vs 58.6 m (5.8 %) | units walk home_a_a2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-lairs_two_b1 vs home_a_b2-lairs_two_b2 | 62.2 m vs 58.6 m (5.8 %) | units walk home_a_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_bridge_n vs tower_c_a2-x_bridge_s | 73.5 m vs 78.0 m (5.8 %) | units walk tower_c_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-guilds_den_a1 vs shrine_b2-guilds_den_a2 | 164.0 m vs 154.5 m (5.8 %) | units walk shrine_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-guilds_den_b2 vs shrine_b1-guilds_den_a1 | 154.5 m vs 164.0 m (5.8 %) | units walk shrine_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-post_w_b1 vs inn_b2-post_w_a1 | 120.9 m vs 113.9 m (5.8 %) | units walk inn_a2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-post_w_a2 vs inn_b2-post_w_a1 | 120.9 m vs 113.9 m (5.8 %) | units walk inn_b1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_two_a2 vs home_b_b2-lairs_two_b2 | 45.2 m vs 42.6 m (5.7 %) | units walk home_b_a2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_a1 vs home_b_a2-lairs_two_a2 | 42.6 m vs 45.2 m (5.7 %) | units walk home_b_a2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_two_b1 vs home_b_b2-lairs_two_b2 | 45.2 m vs 42.6 m (5.7 %) | units walk home_b_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_a1 vs home_b_b1-lairs_two_b1 | 42.6 m vs 45.2 m (5.7 %) | units walk home_b_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b2 vs keep_t1-tower_c_a2 | 97.1 m vs 102.9 m (5.6 %) | units walk keep_t1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b2 vs keep_t3-tower_c_b1 | 97.1 m vs 102.9 m (5.6 %) | units walk keep_t3-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-tower_c_a2 vs keep_t4-tower_c_a1 | 102.9 m vs 97.1 m (5.6 %) | units walk keep_t1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-tower_c_b1 vs keep_t4-tower_c_a1 | 102.9 m vs 97.1 m (5.6 %) | units walk keep_t3-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_a_b1 vs peddler_b2-cache_a_a2 | 149.0 m vs 140.5 m (5.6 %) | units walk peddler_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_a_b1 vs peddler_a2-cache_a_b2 | 149.0 m vs 140.6 m (5.6 %) | units walk peddler_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-x_bridge_s vs tower_c_b1-x_bridge_s | 78.0 m vs 73.6 m (5.6 %) | units walk tower_c_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-crown vs cache_a_b1-crown | 88.1 m vs 83.2 m (5.6 %) | units walk cache_a_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-crown vs cache_a_a2-crown | 88.1 m vs 83.2 m (5.6 %) | units walk cache_a_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-crown vs cache_a_b2-crown | 83.2 m vs 88.1 m (5.6 %) | units walk cache_a_b2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-crown vs cache_a_b2-crown | 83.2 m vs 88.1 m (5.6 %) | units walk cache_a_b2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-third_node_b1 vs home_a_a2-third_node_b2 | 169.9 m vs 180.0 m (5.6 %) | units walk home_a_a2-third_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-third_node_b1 vs home_a_b1-third_node_a1 | 169.9 m vs 180.0 m (5.6 %) | units walk home_a_b1-third_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-guilds_den_a1 vs post_s_b2-guilds_den_b1 | 177.0 m vs 167.1 m (5.6 %) | units walk post_s_a2-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-guilds_den_b2 vs post_s_b2-guilds_den_b1 | 177.0 m vs 167.1 m (5.6 %) | units walk post_s_b1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-guilds_den_a2 vs post_s_b1-guilds_den_b2 | 167.1 m vs 177.0 m (5.6 %) | units walk post_s_b1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-guilds_den_a2 vs post_s_a2-guilds_den_a1 | 167.1 m vs 177.0 m (5.6 %) | units walk post_s_a2-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_ford_n vs lairs_two_a2-x_ford_s | 132.3 m vs 124.9 m (5.6 %) | units walk lairs_two_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a2-x_ford_s vs lairs_two_b1-x_ford_s | 124.9 m vs 132.3 m (5.6 %) | units walk lairs_two_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_ford_n vs lairs_two_b2-x_ford_n | 132.3 m vs 124.9 m (5.6 %) | units walk lairs_two_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_b1-x_ford_s vs lairs_two_b2-x_ford_n | 132.3 m vs 124.9 m (5.6 %) | units walk lairs_two_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-wallow_b1 vs nat_node_b2-wallow_a2 | 135.5 m vs 143.4 m (5.5 %) | units walk nat_node_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-third_node_b1 vs home_a_b2-third_node_a2 | 169.9 m vs 179.7 m (5.5 %) | units walk home_a_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-lairs_two_b1 vs nat_node_b2-lairs_two_a1 | 112.6 m vs 119.1 m (5.5 %) | units walk nat_node_b2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-lairs_two_a2 vs nat_node_b2-lairs_two_a1 | 112.6 m vs 119.1 m (5.5 %) | units walk nat_node_b2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b1 vs keep_t3-tower_c_b2 | 97.5 m vs 103.1 m (5.4 %) | units walk keep_t3-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b1 vs keep_t1-tower_c_a1 | 97.5 m vs 103.1 m (5.4 %) | units walk keep_t1-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_bridge_n vs tower_c_b2-x_bridge_n | 73.5 m vs 77.7 m (5.4 %) | units walk tower_c_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-lairs_two_b2 vs nat_node_a2-lairs_two_b1 | 119.0 m vs 112.6 m (5.4 %) | units walk nat_node_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-lairs_two_b2 vs nat_node_b1-lairs_two_a2 | 119.0 m vs 112.6 m (5.4 %) | units walk nat_node_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-lairs_one_a2 vs post_s_a2-lairs_one_a1 | 174.1 m vs 184.0 m (5.4 %) | units walk post_s_a2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-lairs_one_b2 vs post_s_b2-lairs_one_b1 | 184.0 m vs 174.1 m (5.4 %) | units walk post_s_b1-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-lairs_one_a1 vs post_s_b2-lairs_one_b1 | 184.0 m vs 174.1 m (5.4 %) | units walk post_s_a2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-lairs_one_a2 vs post_s_b1-lairs_one_b2 | 174.1 m vs 184.0 m (5.4 %) | units walk post_s_b1-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_a2 vs cache_a_b1-cache_b_b2 | 101.5 m vs 96.1 m (5.4 %) | units walk cache_a_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_a2 vs cache_a_a2-cache_b_a1 | 101.5 m vs 96.1 m (5.4 %) | units walk cache_a_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-cache_b_b2 vs cache_a_b2-cache_b_b1 | 96.1 m vs 101.5 m (5.4 %) | units walk cache_a_b2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-cache_b_a1 vs cache_a_b2-cache_b_b1 | 96.1 m vs 101.5 m (5.4 %) | units walk cache_a_b2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_a_a1 vs third_node_b2-cache_a_a2 | 206.9 m vs 195.9 m (5.3 %) | units walk third_node_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_a_b2 vs third_node_b2-cache_a_a2 | 206.9 m vs 195.9 m (5.3 %) | units walk third_node_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-peddler_b1 vs post_w_b2-peddler_a1 | 154.3 m vs 146.1 m (5.3 %) | units walk post_w_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-wallow_b1 vs shrine_b2-wallow_a2 | 145.4 m vs 153.5 m (5.3 %) | units walk shrine_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_a_b1 vs keep_t4-cache_a_a2 | 156.5 m vs 148.2 m (5.3 %) | units walk keep_t0-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b1 vs keep_t4-tower_c_a2 | 97.5 m vs 102.9 m (5.3 %) | units walk keep_t4-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-wallow_a1 vs well_b1-wallow_b2 | 102.3 m vs 108.0 m (5.3 %) | units walk well_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_a_b1 vs keep_t3-cache_a_b2 | 156.5 m vs 148.3 m (5.3 %) | units walk keep_t0-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-guilds_den_a2 vs home_a_b2-guilds_den_b2 | 69.3 m vs 65.7 m (5.3 %) | units walk home_a_a2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-guilds_den_b1 vs home_a_b2-guilds_den_b2 | 69.3 m vs 65.7 m (5.3 %) | units walk home_a_b1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_den_a1 vs home_a_a2-guilds_den_a2 | 65.7 m vs 69.3 m (5.3 %) | units walk home_a_a2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_den_a1 vs home_a_b1-guilds_den_b1 | 65.7 m vs 69.3 m (5.3 %) | units walk home_a_b1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_b_b2 vs well_b2-cache_b_a2 | 101.0 m vs 106.6 m (5.2 %) | units walk well_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-cache_b_a1 vs well_b2-cache_b_a2 | 101.0 m vs 106.6 m (5.2 %) | units walk well_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_two_a1 vs home_b_b2-lairs_two_a2 | 180.1 m vs 170.6 m (5.2 %) | units walk home_b_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_two_b2 vs home_b_b2-lairs_two_a2 | 180.1 m vs 170.6 m (5.2 %) | units walk home_b_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_b1 vs home_b_a2-lairs_two_b2 | 170.6 m vs 180.1 m (5.2 %) | units walk home_b_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_b1 vs home_b_b1-lairs_two_a1 | 170.6 m vs 180.1 m (5.2 %) | units walk home_b_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_s_b1 vs home_b_a2-post_s_b2 | 171.6 m vs 181.1 m (5.2 %) | units walk home_b_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_b1 vs third_node_b2-cache_a_a2 | 206.7 m vs 195.9 m (5.2 %) | units walk third_node_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-peddler_b2 vs post_w_a2-peddler_b1 | 146.3 m vs 154.3 m (5.2 %) | units walk post_w_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_a2 vs third_node_b1-cache_a_b2 | 153.5 m vs 161.9 m (5.2 %) | units walk third_node_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_a2 vs third_node_a2-cache_a_a1 | 153.5 m vs 161.9 m (5.2 %) | units walk third_node_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_a_a1 vs third_node_b2-cache_a_b1 | 161.9 m vs 153.5 m (5.2 %) | units walk third_node_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_a_b2 vs third_node_b2-cache_a_b1 | 161.9 m vs 153.5 m (5.2 %) | units walk third_node_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-x_bridge_s vs tower_c_b2-x_bridge_n | 73.6 m vs 77.7 m (5.2 %) | units walk tower_c_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-inn_a2 vs tower_c_b2-inn_a1 | 63.4 m vs 66.9 m (5.2 %) | units walk tower_c_b2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-guilds_den_a1 vs home_b_b2-guilds_den_a2 | 195.5 m vs 185.3 m (5.2 %) | units walk home_b_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-guilds_den_b2 vs home_b_b2-guilds_den_a2 | 195.5 m vs 185.3 m (5.2 %) | units walk home_b_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-crown vs shrine_b1-crown | 53.7 m vs 51.0 m (5.2 %) | units walk shrine_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_a_b2 vs guilds_den_b2-cache_a_a2 | 218.4 m vs 207.2 m (5.1 %) | units walk guilds_den_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-wallow_b2 vs well_b2-wallow_b1 | 108.0 m vs 102.5 m (5.1 %) | units walk well_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-wallow_a2 vs well_b1-wallow_b2 | 102.5 m vs 108.0 m (5.1 %) | units walk well_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-wallow_a2 vs tower_r_b2-wallow_a1 | 99.8 m vs 105.1 m (5.1 %) | units walk tower_r_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-wallow_b1 vs tower_r_b2-wallow_a1 | 99.8 m vs 105.1 m (5.0 %) | units walk tower_r_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_den_b1 vs home_b_b2-guilds_den_a2 | 195.2 m vs 185.3 m (5.0 %) | units walk home_b_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-third_node_b2 vs home_b_b2-third_node_a2 | 187.5 m vs 178.1 m (5.0 %) | units walk home_b_a2-third_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-third_node_b1 vs home_b_a2-third_node_b2 | 178.1 m vs 187.5 m (5.0 %) | units walk home_b_a2-third_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest enemy keep | 137.0 m vs 151.6 m between seats (9.6 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | T1 | enemy keep (nearest) (worker) | 0:30 vs 0:33 between seats | one seat's route is longer or crosses more ford: see the travel-time table |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 3.8 m at (-7.0, 1.7) vs its twin's 5.8 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 3.8 m at (-7.0, 1.7) vs its twin's 5.8 m | a collider narrows this route only on one side |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-71.8, 27.1) | (-68.1, 26.4) | keep_t4 | (-68.1, 26.4) | 0.0 |
| keep_t3 | keep | (-71.8, -27.1) | (-68.1, -26.4) | keep_t1 | (-68.1, -26.4) | 0.0 |
| keep_t1 | keep | (71.8, -27.1) | (68.1, -26.4) | keep_t3 | (68.1, -26.4) | 0.0 |
| keep_t4 | keep | (71.8, 27.1) | (68.1, 26.4) | keep_t0 | (68.1, 26.4) | 0.0 |
| home_a_a1 | home_node | (-70.8, 17.7) | (-70.6, 17.6) | home_a_b2 | (-70.6, 17.6) | 0.0 |
| home_a_a2 | home_node | (-70.8, -17.7) | (-70.6, -17.6) | home_a_b1 | (-70.6, -17.6) | 0.0 |
| home_a_b1 | home_node | (70.8, -17.7) | (70.6, -17.6) | home_a_a2 | (70.6, -17.6) | 0.0 |
| home_a_b2 | home_node | (70.8, 17.7) | (70.6, 17.6) | home_a_a1 | (70.6, 17.6) | 0.0 |
| home_b_a1 | home_node | (-64.8, 33.5) | (-64.6, 33.6) | home_b_b2 | (-64.6, 33.6) | 0.0 |
| home_b_a2 | home_node | (-64.8, -33.5) | (-64.6, -33.6) | home_b_b1 | (-64.6, -33.6) | 0.0 |
| home_b_b1 | home_node | (64.8, -33.5) | (64.6, -33.6) | home_b_a2 | (64.6, -33.6) | 0.0 |
| home_b_b2 | home_node | (64.8, 33.5) | (64.6, 33.6) | home_b_a1 | (64.6, 33.6) | 0.0 |
| nat_node_a1 | expansion | (-38.4, 20.1) | (-38.4, 19.9) | nat_node_b2 | (-38.4, 19.9) | 0.0 |
| nat_node_a2 | expansion | (-38.4, -20.1) | (-38.4, -19.9) | nat_node_b1 | (-38.4, -19.9) | 0.0 |
| nat_node_b1 | expansion | (38.4, -20.1) | (38.4, -19.9) | nat_node_a2 | (38.4, -19.9) | 0.0 |
| nat_node_b2 | expansion | (38.4, 20.1) | (38.4, 19.9) | nat_node_a1 | (38.4, 19.9) | 0.0 |
| rich_node_a1 | expansion | (-15.8, 55.3) | (-15.6, 55.1) | rich_node_b2 | (-15.6, 55.1) | 0.0 |
| rich_node_a2 | expansion | (-15.8, -55.3) | (-15.6, -55.1) | rich_node_b1 | (-15.6, -55.1) | 0.0 |
| rich_node_b1 | expansion | (15.8, -55.3) | (15.6, -55.1) | rich_node_a2 | (15.6, -55.1) | 0.0 |
| rich_node_b2 | expansion | (15.8, 55.3) | (15.6, 55.1) | rich_node_a1 | (15.6, 55.1) | 0.0 |
| third_node_a1 | expansion | (-72.7, 72.7) | (-72.6, 72.6) | third_node_b2 | (-72.6, 72.6) | 0.0 |
| third_node_a2 | expansion | (-72.7, -72.7) | (-72.6, -72.6) | third_node_b1 | (-72.6, -72.6) | 0.0 |
| third_node_b1 | expansion | (72.7, -72.7) | (72.6, -72.6) | third_node_a2 | (72.6, -72.6) | 0.0 |
| third_node_b2 | expansion | (72.7, 72.7) | (72.6, 72.6) | third_node_a1 | (72.6, 72.6) | 0.0 |
| tower_r_a1 | point | (-15.9, 60.1) | (-15.9, 59.9) | tower_r_b2 | (-15.9, 59.9) | 0.0 |
| tower_r_a2 | point | (-15.9, -60.1) | (-15.9, -59.9) | tower_r_b1 | (-15.9, -59.9) | 0.0 |
| tower_r_b1 | point | (15.9, -60.1) | (15.9, -59.9) | tower_r_a2 | (15.9, -59.9) | 0.0 |
| tower_r_b2 | point | (15.9, 60.1) | (15.9, 59.9) | tower_r_a1 | (15.9, 59.9) | 0.0 |
| tower_c_a1 | point | (-23.3, 7.4) | (-23.1, 7.4) | tower_c_b2 | (-23.1, 7.4) | 0.0 |
| tower_c_a2 | point | (-23.3, -7.4) | (-23.1, -7.4) | tower_c_b1 | (-23.1, -7.4) | 0.0 |
| tower_c_b1 | point | (23.3, -7.4) | (23.1, -7.4) | tower_c_a2 | (23.1, -7.4) | 0.0 |
| tower_c_b2 | point | (23.3, 7.4) | (23.1, 7.4) | tower_c_a1 | (23.1, 7.4) | 0.0 |
| well_a1 | point | (-39.3, 48.4) | (-39.1, 48.4) | well_b2 | (-39.1, 48.4) | 0.0 |
| well_a2 | point | (-39.3, -48.4) | (-39.1, -48.4) | well_b1 | (-39.1, -48.4) | 0.0 |
| well_b1 | point | (39.3, -48.4) | (39.1, -48.4) | well_a2 | (39.1, -48.4) | 0.0 |
| well_b2 | point | (39.3, 48.4) | (39.1, 48.4) | well_a1 | (39.1, 48.4) | 0.0 |
| shrine_a1 | point | (-50.4, 8.7) | (-50.4, 8.6) | shrine_b2 | (-50.4, 8.6) | 0.0 |
| shrine_a2 | point | (-50.4, -8.7) | (-50.4, -8.6) | shrine_b1 | (-50.4, -8.6) | 0.0 |
| shrine_b1 | point | (50.4, -8.7) | (50.4, -8.6) | shrine_a2 | (50.4, -8.6) | 0.0 |
| shrine_b2 | point | (50.4, 8.7) | (50.4, 8.6) | shrine_a1 | (50.4, 8.6) | 0.0 |
| wallow_a1 | camp | (-80.5, 43.5) | (-80.4, 43.4) | wallow_b2 | (-80.4, 43.4) | 0.0 |
| wallow_a2 | camp | (-80.5, -43.5) | (-80.4, -43.4) | wallow_b1 | (-80.4, -43.4) | 0.0 |
| wallow_b1 | camp | (80.5, -43.5) | (80.4, -43.4) | wallow_a2 | (80.4, -43.4) | 0.0 |
| wallow_b2 | camp | (80.5, 43.5) | (80.4, 43.4) | wallow_a1 | (80.4, 43.4) | 0.0 |
| ford_nest_a1 | camp | (0.0, 36.6) | (0.1, 36.6) | ford_nest_a1 | (-0.1, 36.6) | 0.3 |
| ford_nest_a2 | camp | (0.0, -36.6) | (0.1, -36.6) | ford_nest_a2 | (-0.1, -36.6) | 0.3 |
| stag_a1 | camp | (-36.2, 77.6) | (-36.1, 77.4) | stag_b2 | (-36.1, 77.4) | 0.0 |
| stag_a2 | camp | (-36.2, -77.6) | (-36.1, -77.4) | stag_b1 | (-36.1, -77.4) | 0.0 |
| stag_b1 | camp | (36.2, -77.6) | (36.1, -77.4) | stag_a2 | (36.1, -77.4) | 0.0 |
| stag_b2 | camp | (36.2, 77.6) | (36.1, 77.4) | stag_a1 | (36.1, 77.4) | 0.0 |
| inn_a1 | tavern | (-29.3, 24.0) | (-29.1, 23.9) | inn_b2 | (-29.1, 23.9) | 0.0 |
| inn_a2 | tavern | (-29.3, -24.0) | (-29.1, -23.9) | inn_b1 | (-29.1, -23.9) | 0.0 |
| inn_b1 | tavern | (29.3, -24.0) | (29.1, -23.9) | inn_a2 | (29.1, -23.9) | 0.0 |
| inn_b2 | tavern | (29.3, 24.0) | (29.1, 23.9) | inn_a1 | (29.1, 23.9) | 0.0 |
| post_w_a1 | post | (-80.3, 12.3) | (-80.1, 12.1) | post_w_b2 | (-80.1, 12.1) | 0.0 |
| post_w_a2 | post | (-80.3, -12.3) | (-80.1, -12.1) | post_w_b1 | (-80.1, -12.1) | 0.0 |
| post_w_b1 | post | (80.3, -12.3) | (80.1, -12.1) | post_w_a2 | (80.1, -12.1) | 0.0 |
| post_w_b2 | post | (80.3, 12.3) | (80.1, 12.1) | post_w_a1 | (80.1, 12.1) | 0.0 |
| post_s_a1 | post | (-47.2, 81.0) | (-47.1, 80.9) | post_s_b2 | (-47.1, 80.9) | 0.0 |
| post_s_a2 | post | (-47.2, -81.0) | (-47.1, -80.9) | post_s_b1 | (-47.1, -80.9) | 0.0 |
| post_s_b1 | post | (47.2, -81.0) | (47.1, -80.9) | post_s_a2 | (47.1, -80.9) | 0.0 |
| post_s_b2 | post | (47.2, 81.0) | (47.1, 80.9) | post_s_a1 | (47.1, 80.9) | 0.0 |
| guilds_den_a1 | guild | (-72.8, 82.8) | (-72.9, 82.6) | guilds_den_b2 | (-72.9, 82.6) | 0.0 |
| guilds_den_a2 | guild | (-72.8, -82.8) | (-72.9, -82.6) | guilds_den_b1 | (-72.9, -82.6) | 0.0 |
| guilds_den_b1 | guild | (72.8, -82.8) | (72.9, -82.6) | guilds_den_a2 | (72.9, -82.6) | 0.0 |
| guilds_den_b2 | guild | (72.8, 82.8) | (72.9, 82.6) | guilds_den_a1 | (72.9, 82.6) | 0.0 |
| guilds_lodge_a1 | guild | (-81.4, 74.4) | (-81.4, 74.4) | guilds_lodge_b2 | (-81.4, 74.4) | 0.0 |
| guilds_lodge_a2 | guild | (-81.4, -74.4) | (-81.4, -74.4) | guilds_lodge_b1 | (-81.4, -74.4) | 0.0 |
| guilds_lodge_b1 | guild | (81.4, -74.4) | (81.4, -74.4) | guilds_lodge_a2 | (81.4, -74.4) | 0.0 |
| guilds_lodge_b2 | guild | (81.4, 74.4) | (81.4, 74.4) | guilds_lodge_a1 | (81.4, 74.4) | 0.0 |
| peddler_a1 | peddler | (-62.0, 21.6) | (-61.9, 21.6) | peddler_b2 | (-61.9, 21.6) | 0.0 |
| peddler_a2 | peddler | (-62.0, -21.6) | (-61.9, -21.6) | peddler_b1 | (-61.9, -21.6) | 0.0 |
| peddler_b1 | peddler | (62.0, -21.6) | (61.9, -21.6) | peddler_a2 | (61.9, -21.6) | 0.0 |
| peddler_b2 | peddler | (62.0, 21.6) | (61.9, 21.6) | peddler_a1 | (61.9, 21.6) | 0.0 |
| cache_a_a1 | cache | (-47.8, 64.1) | (-47.9, 63.9) | cache_a_b2 | (-47.9, 63.9) | 0.0 |
| cache_a_a2 | cache | (-47.8, -64.1) | (-47.9, -63.9) | cache_a_b1 | (-47.9, -63.9) | 0.0 |
| cache_a_b1 | cache | (47.8, -64.1) | (47.9, -63.9) | cache_a_a2 | (47.9, -63.9) | 0.0 |
| cache_a_b2 | cache | (47.8, 64.1) | (47.9, 63.9) | cache_a_a1 | (47.9, 63.9) | 0.0 |
| cache_b_a1 | cache | (-6.2, 22.7) | (-6.1, 22.6) | cache_b_b2 | (-6.1, 22.6) | 0.0 |
| cache_b_a2 | cache | (-6.2, -22.7) | (-6.1, -22.6) | cache_b_b1 | (-6.1, -22.6) | 0.0 |
| cache_b_b1 | cache | (6.2, -22.7) | (6.1, -22.6) | cache_b_a2 | (6.1, -22.6) | 0.0 |
| cache_b_b2 | cache | (6.2, 22.7) | (6.1, 22.6) | cache_b_a1 | (6.1, 22.6) | 0.0 |
| lairs_one_a1 | lair | (-60.4, 90.8) | (-59.1, 87.9) | lairs_one_b2 | (-59.1, 87.9) | 0.0 |
| lairs_one_a2 | lair | (-60.4, -90.8) | (-59.1, -87.9) | lairs_one_b1 | (-59.1, -87.9) | 0.0 |
| lairs_one_b1 | lair | (60.4, -90.8) | (59.1, -87.9) | lairs_one_a2 | (59.1, -87.9) | 0.0 |
| lairs_one_b2 | lair | (60.4, 90.8) | (59.1, 87.9) | lairs_one_a1 | (59.1, 87.9) | 0.0 |
| lairs_two_a1 | lair | (-60.4, 72.8) | (-60.4, 72.6) | lairs_two_b2 | (-60.4, 72.6) | 0.0 |
| lairs_two_a2 | lair | (-60.4, -72.8) | (-60.4, -72.6) | lairs_two_b1 | (-60.4, -72.6) | 0.0 |
| lairs_two_b1 | lair | (60.4, -72.8) | (60.4, -72.6) | lairs_two_a2 | (60.4, -72.6) | 0.0 |
| lairs_two_b2 | lair | (60.4, 72.8) | (60.4, 72.6) | lairs_two_a1 | (60.4, 72.6) | 0.0 |
| x_bridge_n | crossing_bridge_road | (0.0, -61.9) | (0.1, -61.9) | x_bridge_n | (-0.1, -61.9) | 0.3 |
| x_bridge_s | crossing_bridge_road | (0.0, 61.9) | (0.1, 61.9) | x_bridge_s | (-0.1, 61.9) | 0.3 |
| x_ford_n | crossing_ford | (0.0, -36.6) | (0.1, -36.6) | x_ford_n | (-0.1, -36.6) | 0.3 |
| x_ford_s | crossing_ford | (0.0, 36.6) | (0.1, 36.6) | x_ford_s | (-0.1, 36.6) | 0.3 |
| x_lane_w | crossing_bridge_lane | (-13.0, 0.0) | (-12.9, 0.1) | x_lane_e | (-12.9, 0.1) | 0.0 |
| x_lane_e | crossing_bridge_lane | (13.0, 0.0) | (12.9, 0.1) | x_lane_w | (12.9, 0.1) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 935)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | stag_a1 - stag_a2 | 160.4 | stag_b2 - stag_b1 | 197.4 | -18.7 % |
| 2 | stag_a2 - lairs_two_a1 | 184.0 | stag_b1 - lairs_two_b2 | 153.5 | +16.6 % |
| 3 | stag_a2 - lairs_two_a1 | 184.0 | stag_b2 - lairs_two_b1 | 153.8 | +16.4 % |
| 4 | stag_a1 - lairs_two_a2 | 153.8 | stag_a2 - lairs_two_a1 | 184.0 | -16.4 % |
| 5 | well_a1 - cache_b_b1 | 120.1 | well_a2 - cache_b_b2 | 101.0 | +15.9 % |
| 6 | well_a1 - cache_b_b1 | 120.1 | well_b1 - cache_b_a1 | 101.0 | +15.9 % |
| 7 | home_a_b1 - ford_nest_a2 | 86.7 | home_a_b2 - ford_nest_a1 | 73.0 | +15.8 % |
| 8 | home_a_a1 - ford_nest_a1 | 73.0 | home_a_a2 - ford_nest_a2 | 86.7 | -15.8 % |
| 9 | home_a_a2 - ford_nest_a2 | 86.7 | home_a_b2 - ford_nest_a1 | 73.0 | +15.8 % |
| 10 | home_a_a1 - x_ford_s | 73.0 | home_a_b1 - x_ford_n | 86.7 | -15.8 % |
| 11 | home_a_a1 - x_ford_s | 73.0 | home_a_a2 - x_ford_n | 86.7 | -15.8 % |
| 12 | home_a_a1 - ford_nest_a1 | 73.0 | home_a_b1 - ford_nest_a2 | 86.7 | -15.8 % |
| 13 | home_a_b1 - x_ford_n | 86.7 | home_a_b2 - x_ford_s | 73.0 | +15.8 % |
| 14 | home_a_a2 - x_ford_n | 86.7 | home_a_b2 - x_ford_s | 73.0 | +15.8 % |
| 15 | third_node_b1 - shrine_a2 | 158.4 | third_node_b2 - shrine_a1 | 185.1 | -14.4 % |
| 16 | third_node_a1 - shrine_b2 | 158.4 | third_node_b2 - shrine_a1 | 185.1 | -14.4 % |
| 17 | cache_a_a1 - cache_b_b1 | 138.0 | cache_a_a2 - cache_b_b2 | 118.8 | +13.9 % |
| 18 | cache_a_a1 - cache_b_b1 | 138.0 | cache_a_b1 - cache_b_a1 | 118.8 | +13.9 % |
| 19 | cache_a_a2 - cache_b_b2 | 118.8 | cache_a_b2 - cache_b_a2 | 137.9 | -13.8 % |
| 20 | cache_a_b1 - cache_b_a1 | 118.8 | cache_a_b2 - cache_b_a2 | 137.9 | -13.8 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 south-west | 30.5 (nat_node_a1) | 25.1 (shrine_a1) | 21.8 (wallow_a1) | 49.4 (lairs_two_a1) | 39.1 (inn_a1) | 19.3 (post_w_a1) | 7.9 (peddler_a1) | 42.6 (cache_a_a1) | 73.0 (crown) | 151.6 |
| A2 north-west | 30.5 (nat_node_a2) | 25.1 (shrine_a2) | 21.8 (wallow_a2) | 49.4 (lairs_two_a2) | 39.1 (inn_a2) | 19.2 (post_w_a2) | 7.9 (peddler_a2) | 42.6 (cache_a_a2) | 73.0 (crown) | 137.0 |
| B1 north-east | 30.5 (nat_node_b1) | 25.1 (shrine_b1) | 21.8 (wallow_b1) | 49.4 (lairs_two_b1) | 39.1 (inn_b1) | 19.2 (post_w_b1) | 7.9 (peddler_b1) | 42.6 (cache_a_b1) | 73.0 (crown) | 137.0 |
| B2 south-east | 30.5 (nat_node_b2) | 25.1 (shrine_b2) | 21.8 (wallow_b2) | 49.4 (lairs_two_b2) | 39.1 (inn_b2) | 19.3 (post_w_b2) | 7.9 (peddler_b2) | 42.6 (cache_a_b2) | 73.0 (crown) | 151.6 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| peddler_a1 | peddler | 7.9 | peddler_b2 | 7.9 | +0.0 % |
| home_b_a1 | home_node | 8.1 | home_b_b2 | 8.1 | -0.0 % |
| home_a_a1 | home_node | 9.2 | home_a_b2 | 9.2 | +0.0 % |
| post_w_a1 | post | 19.3 | post_w_b2 | 19.3 | +0.0 % |
| wallow_a1 | camp | 21.8 | wallow_b2 | 21.8 | +0.0 % |
| shrine_a1 | point | 25.1 | shrine_b2 | 25.1 | +0.0 % |
| nat_node_a1 | expansion | 30.5 | nat_node_b2 | 30.5 | +0.0 % |
| well_a1 | point | 36.4 | well_b2 | 36.4 | +0.0 % |
| inn_a1 | tavern | 39.1 | inn_b2 | 39.1 | +0.0 % |
| shrine_a2 | point | 39.2 | shrine_b1 | 39.2 | +0.0 % |
| post_w_a2 | post | 40.4 | post_w_b1 | 40.4 | +0.0 % |
| cache_a_a1 | cache | 42.6 | cache_a_b2 | 42.6 | +0.0 % |
| home_a_a2 | home_node | 44.1 | home_a_b1 | 44.1 | +0.0 % |
| third_node_a1 | expansion | 46.5 | third_node_b2 | 46.5 | +0.0 % |
| peddler_a2 | peddler | 48.4 | peddler_b1 | 48.4 | -0.0 % |
| tower_c_a1 | point | 48.8 | tower_c_b2 | 48.8 | -0.0 % |
| lairs_two_a1 | lair | 49.4 | lairs_two_b2 | 49.4 | -0.0 % |
| guilds_lodge_a1 | guild | 49.9 | guilds_lodge_b2 | 49.9 | -0.0 % |
| keep_t3 | keep | 52.8 | keep_t1 | 52.8 | +0.0 % |
| nat_node_a2 | expansion | 55.0 | nat_node_b1 | 55.0 | +0.0 % |
| tower_c_a2 | point | 56.3 | tower_c_b1 | 56.3 | +0.0 % |
| guilds_den_a1 | guild | 56.5 | guilds_den_b2 | 56.5 | +0.0 % |
| post_s_a1 | post | 58.5 | post_s_b2 | 58.5 | +0.0 % |
| rich_node_a1 | expansion | 59.9 | rich_node_b2 | 59.9 | +0.0 % |
| home_b_a2 | home_node | 60.1 | home_b_b1 | 60.1 | +0.0 % |
| stag_a1 | camp | 60.2 | stag_b2 | 60.2 | +0.0 % |
| x_lane_w | crossing_bridge_lane | 61.2 | x_lane_e | 61.2 | +0.0 % |
| tower_r_a1 | point | 62.1 | tower_r_b2 | 62.1 | +0.0 % |
| cache_b_a1 | cache | 62.1 | cache_b_b2 | 62.1 | +0.0 % |
| lairs_one_a1 | lair | 63.5 | lairs_one_b2 | 63.5 | +0.0 % |
| inn_a2 | tavern | 63.7 | inn_b1 | 63.7 | +0.0 % |
| ford_nest_a1 | camp | 68.8 | ford_nest_a1 | 68.8 | +0.0 % |
| x_ford_s | crossing_ford | 68.8 | x_ford_s | 68.8 | +0.0 % |
| crown | crown | 73.0 | crown | 73.0 | +0.0 % |
| wallow_a2 | camp | 74.5 | wallow_b1 | 74.5 | +0.0 % |
| x_bridge_s | crossing_bridge_road | 76.7 | x_bridge_s | 76.7 | -0.0 % |
| cache_b_a2 | cache | 79.7 | cache_b_b1 | 79.7 | +0.0 % |
| well_a2 | point | 80.2 | well_b1 | 80.2 | +0.0 % |
| cache_b_b2 | cache | 83.0 | cache_b_a1 | 82.8 | +0.2 % |
| x_lane_e | crossing_bridge_lane | 85.9 | x_lane_w | 85.9 | +0.0 % |
| tower_r_b2 | point | 92.0 | tower_r_a1 | 92.0 | -0.0 % |
| cache_a_a2 | cache | 92.5 | cache_a_b1 | 92.5 | -0.0 % |
| rich_node_b2 | expansion | 92.6 | rich_node_a1 | 92.6 | -0.0 % |
| ford_nest_a2 | camp | 92.9 | ford_nest_a2 | 92.9 | -0.0 % |
| x_ford_n | crossing_ford | 92.9 | x_ford_n | 92.9 | -0.0 % |
| rich_node_a2 | expansion | 96.9 | rich_node_b1 | 96.9 | +0.0 % |
| tower_c_b2 | point | 97.1 | tower_c_a1 | 97.1 | -0.0 % |
| tower_c_b1 | point | 97.5 | tower_c_a2 | 102.9 | -5.3 % |
| third_node_a2 | expansion | 99.2 | third_node_b1 | 99.2 | +0.0 % |
| inn_b2 | tavern | 99.4 | inn_a1 | 99.4 | +0.0 % |
| tower_r_a2 | point | 100.8 | tower_r_b1 | 100.8 | -0.0 % |
| guilds_lodge_a2 | guild | 102.7 | guilds_lodge_b1 | 102.7 | +0.0 % |
| lairs_two_a2 | lair | 104.7 | lairs_two_b1 | 104.7 | +0.0 % |
| cache_b_b1 | cache | 105.9 | cache_b_a2 | 105.7 | +0.1 % |
| post_s_a2 | post | 109.4 | post_s_b1 | 109.4 | +0.0 % |
| nat_node_b2 | expansion | 109.4 | nat_node_a1 | 109.4 | +0.0 % |
| well_b2 | point | 109.5 | well_a1 | 109.5 | +0.0 % |
| stag_a2 | camp | 109.9 | stag_b1 | 109.9 | +0.0 % |
| x_bridge_n | crossing_bridge_road | 111.5 | x_bridge_n | 111.6 | -0.0 % |
| guilds_den_a2 | guild | 111.8 | guilds_den_b1 | 111.8 | +0.0 % |
| inn_b1 | tavern | 112.7 | inn_a2 | 118.1 | -4.6 % |
| stag_b2 | camp | 116.1 | stag_a1 | 116.1 | -0.0 % |
| nat_node_b1 | expansion | 116.8 | nat_node_a2 | 122.3 | -4.4 % |
| rich_node_b1 | expansion | 117.2 | rich_node_a2 | 117.2 | +0.0 % |
| lairs_one_a2 | lair | 118.8 | lairs_one_b1 | 118.8 | +0.0 % |
| cache_a_b2 | cache | 124.3 | cache_a_a1 | 124.3 | -0.0 % |
| tower_r_b1 | point | 126.6 | tower_r_a2 | 121.2 | +4.3 % |
| shrine_b2 | point | 126.7 | shrine_a1 | 132.3 | -4.3 % |
| shrine_b1 | point | 126.9 | shrine_a2 | 132.6 | -4.3 % |
| post_s_b2 | post | 127.6 | post_s_a1 | 127.6 | -0.0 % |
| home_b_b2 | home_node | 133.1 | home_b_a1 | 133.1 | +0.0 % |
| well_b1 | point | 133.3 | well_a2 | 133.3 | -0.0 % |
| lairs_two_b2 | lair | 138.6 | lairs_two_a1 | 138.7 | -0.0 % |
| peddler_b1 | peddler | 138.8 | peddler_a2 | 144.2 | -3.8 % |
| lairs_one_b2 | lair | 142.5 | lairs_one_a1 | 142.6 | -0.0 % |
| peddler_b2 | peddler | 144.0 | peddler_a1 | 131.6 | +8.6 % |
| home_b_b1 | home_node | 146.4 | home_b_a2 | 151.8 | -3.6 % |
| home_a_b2 | home_node | 147.9 | home_a_a1 | 141.0 | +4.7 % |
| home_a_b1 | home_node | 148.2 | home_a_a2 | 153.8 | -3.7 % |
| wallow_b2 | camp | 149.5 | wallow_a1 | 149.5 | +0.0 % |
| third_node_b2 | expansion | 150.3 | third_node_a1 | 153.9 | -2.4 % |
| stag_b1 | camp | 150.8 | stag_a2 | 148.7 | +1.4 % |
| keep_t4 | keep | 151.6 | keep_t0 | 151.6 | +0.0 % |
| keep_t1 | keep | 151.9 | keep_t3 | 157.6 | -3.6 % |
| guilds_den_b2 | guild | 153.0 | guilds_den_a1 | 153.0 | -0.0 % |
| post_w_b2 | post | 154.5 | post_w_a1 | 161.8 | -4.5 % |
| post_w_b1 | post | 154.7 | post_w_a2 | 160.3 | -3.5 % |
| cache_a_b1 | cache | 156.5 | cache_a_a2 | 148.2 | +5.3 % |
| guilds_lodge_b2 | guild | 161.9 | guilds_lodge_a1 | 161.9 | -0.0 % |
| post_s_b1 | post | 163.0 | post_s_a2 | 162.2 | +0.5 % |
| wallow_b1 | camp | 164.9 | wallow_a2 | 178.5 | -7.6 % |
| lairs_two_b1 | lair | 170.5 | lairs_two_a2 | 176.0 | -3.1 % |
| third_node_b1 | expansion | 178.0 | third_node_a2 | 183.4 | -3.0 % |
| lairs_one_b1 | lair | 183.3 | lairs_one_a2 | 174.7 | +4.7 % |
| guilds_lodge_b1 | guild | 185.3 | guilds_lodge_a2 | 190.6 | -2.8 % |
| guilds_den_b1 | guild | 185.9 | guilds_den_a2 | 179.5 | +3.5 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| A1 south-west | 0 | keep_t3 | 52.8 | no | 151.6 | 151.9 | 0.35 |
| A2 north-west | 0 | keep_t0 | 52.8 | no | 137.0 | 157.6 | 0.39 |
| B1 north-east | 1 | keep_t4 | 52.8 | no | 137.0 | 151.9 | 0.39 |
| B2 south-east | 1 | keep_t1 | 52.8 | no | 151.6 | 157.6 | 0.35 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| A1 south-west | ally keep (keep_t3) | 52.8 | 0.0 | 0:11 | 0:11 | 0:07 | 0:13 |
| A1 south-west | enemy keep (nearest) (keep_t4) | 151.6 | 0.0 | 0:33 | 0:30 | 0:20 | 0:38 |
| A1 south-west | enemy keep #2 (keep_t1) | 151.9 | 0.0 | 0:33 | 0:30 | 0:20 | 0:38 |
| A1 south-west | nearest expansion (nat_node_a1) | 30.5 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| A1 south-west | nearest point (shrine_a1) | 25.1 | 0.0 | 0:05 | 0:05 | 0:03 | 0:06 |
| A1 south-west | nearest camp (wallow_a1) | 21.8 | 0.0 | 0:05 | 0:04 | 0:03 | 0:05 |
| A1 south-west | crown (crown) | 73.0 | 0.0 | 0:16 | 0:15 | 0:10 | 0:18 |
| A2 north-west | ally keep (keep_t0) | 52.8 | 0.0 | 0:11 | 0:11 | 0:07 | 0:13 |
| A2 north-west | enemy keep (nearest) (keep_t1) | 137.0 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| A2 north-west | enemy keep #2 (keep_t4) | 157.6 | 0.0 | 0:34 | 0:32 | 0:21 | 0:39 |
| A2 north-west | nearest expansion (nat_node_a2) | 30.5 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| A2 north-west | nearest point (shrine_a2) | 25.1 | 0.0 | 0:05 | 0:05 | 0:03 | 0:06 |
| A2 north-west | nearest camp (wallow_a2) | 21.8 | 0.0 | 0:05 | 0:04 | 0:03 | 0:05 |
| A2 north-west | crown (crown) | 73.0 | 0.0 | 0:16 | 0:15 | 0:10 | 0:18 |
| B1 north-east | ally keep (keep_t4) | 52.7 | 0.0 | 0:11 | 0:11 | 0:07 | 0:13 |
| B1 north-east | enemy keep (nearest) (keep_t3) | 137.0 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| B1 north-east | enemy keep #2 (keep_t0) | 157.6 | 0.0 | 0:34 | 0:32 | 0:21 | 0:39 |
| B1 north-east | nearest expansion (nat_node_b1) | 30.5 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| B1 north-east | nearest point (shrine_b1) | 25.1 | 0.0 | 0:05 | 0:05 | 0:03 | 0:06 |
| B1 north-east | nearest camp (wallow_b1) | 21.8 | 0.0 | 0:05 | 0:04 | 0:03 | 0:05 |
| B1 north-east | crown (crown) | 73.0 | 0.0 | 0:16 | 0:15 | 0:10 | 0:18 |
| B2 south-east | ally keep (keep_t1) | 52.7 | 0.0 | 0:11 | 0:11 | 0:07 | 0:13 |
| B2 south-east | enemy keep (nearest) (keep_t0) | 137.0 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| B2 south-east | enemy keep #2 (keep_t3) | 157.6 | 0.0 | 0:34 | 0:32 | 0:21 | 0:39 |
| B2 south-east | nearest expansion (nat_node_b2) | 30.5 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| B2 south-east | nearest point (shrine_b2) | 25.1 | 0.0 | 0:05 | 0:05 | 0:03 | 0:06 |
| B2 south-east | nearest camp (wallow_b2) | 21.8 | 0.0 | 0:05 | 0:04 | 0:03 | 0:05 |
| B2 south-east | crown (crown) | 73.0 | 0.0 | 0:16 | 0:15 | 0:10 | 0:18 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| x_bridge_n | bridge_road | 6.0 | 4.8 | 5.8 | x_bridge_n | 4.8 |
| x_bridge_s | bridge_road | 6.0 | 4.8 | 5.8 | x_bridge_s | 4.8 |
| x_ford_n | ford | 7.0 | 5.8 | 6.8 | x_ford_n | 5.8 |
| x_ford_s | ford | 7.0 | 5.8 | 6.8 | x_ford_s | 5.8 |
| x_lane_w | bridge_lane | 8.0 | 7.3 | 8.3 | x_lane_e | 7.3 |
| x_lane_e | bridge_lane | 8.0 | 7.3 | 8.3 | x_lane_w | 7.3 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 73.3 | 3.6 | (-7.0, 1.6) | - |
| keep_t0 -> keep_t1 | 151.9 | 3.8 | (-7.0, 1.7) | - |
| keep_t0 -> keep_t4 | 151.6 | 3.8 | (-7.0, 1.7) | - |
| keep_t0 -> nat_node_a1 | 30.5 | 36.5 | (-42.7, 20.8) | - |
| keep_t3 -> crown | 73.3 | 4.1 | (-7.0, -1.7) | - |
| keep_t3 -> keep_t4 | 157.6 | 3.8 | (-6.9, -0.2) | - |
| keep_t3 -> nat_node_a2 | 30.5 | 36.5 | (-42.7, -20.8) | - |
| keep_t1 -> crown | 73.1 | 4.1 | (7.0, -1.7) | - |
| keep_t1 -> keep_t3 | 137.0 | 5.8 | (-0.5, -33.5) | - |
| keep_t1 -> nat_node_b1 | 30.5 | 36.5 | (42.7, -20.8) | - |
| keep_t4 -> crown | 73.0 | 3.6 | (7.0, 1.6) | - |
| keep_t4 -> nat_node_b2 | 30.5 | 36.5 | (42.7, 20.8) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| A1 south-west | ally | 60.00-72.00 | 52.75 | 12.1 % |
| A1 south-west | enemy_ally | 2.00-3.00 | 2.87 | - |
| A1 south-west | keep_enemy | 130.00-185.00 | 151.64 | - |
| A1 south-west | natural | 32.00-56.00 | 30.45 | 4.8 % |
| A1 south-west | rich | 50.00-95.00 | 59.86 | - |
| A1 south-west | crown | 60.00-95.00 | 73.01 | - |
| A2 north-west | ally | 60.00-72.00 | 52.75 | 12.1 % |
| A2 north-west | enemy_ally | 2.00-3.00 | 2.60 | - |
| A2 north-west | keep_enemy | 130.00-185.00 | 137.01 | - |
| A2 north-west | natural | 32.00-56.00 | 30.45 | 4.8 % |
| A2 north-west | rich | 50.00-95.00 | 59.86 | - |
| A2 north-west | crown | 60.00-95.00 | 73.01 | - |
| B1 north-east | ally | 60.00-72.00 | 52.75 | 12.1 % |
| B1 north-east | enemy_ally | 2.00-3.00 | 2.60 | - |
| B1 north-east | keep_enemy | 130.00-185.00 | 137.01 | - |
| B1 north-east | natural | 32.00-56.00 | 30.45 | 4.8 % |
| B1 north-east | rich | 50.00-95.00 | 59.86 | - |
| B1 north-east | crown | 60.00-95.00 | 73.01 | - |
| B2 south-east | ally | 60.00-72.00 | 52.75 | 12.1 % |
| B2 south-east | enemy_ally | 2.00-3.00 | 2.87 | - |
| B2 south-east | keep_enemy | 130.00-185.00 | 151.64 | - |
| B2 south-east | natural | 32.00-56.00 | 30.45 | 4.8 % |
| B2 south-east | rich | 50.00-95.00 | 59.86 | - |
| B2 south-east | crown | 60.00-95.00 | 73.01 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A1 south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 2 | 2 | 1 | 1 | 1 |
| A2 north-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 2 | 2 | 1 | 1 | 1 |
| B1 north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 2 | 2 | 1 | 1 | 1 |
| B2 south-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 2 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| A1 south-west | 5 | 1 | 21 | 51 |
| A2 north-west | 4 | 2 | 21 | 51 |
| B1 north-east | 4 | 2 | 21 | 51 |
| B2 south-east | 5 | 1 | 21 | 51 |


## Hottest metres (every spot-pair shortest path, 4656 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-14.5, 3.5) | 374 | 8 % |
| 2 | (-6.5, 1.5) | 330 | 7 % |
| 3 | (14.5, -4.5) | 330 | 7 % |
| 4 | (3.5, -33.5) | 310 | 7 % |
| 5 | (14.5, 3.5) | 307 | 7 % |
| 6 | (6.5, -1.5) | 290 | 6 % |
| 7 | (-14.5, -4.5) | 285 | 6 % |
| 8 | (0.5, 36.5) | 257 | 6 % |
| 9 | (-46.5, -2.5) | 240 | 5 % |
| 10 | (46.5, -2.5) | 240 | 5 % |


## Info findings (522)
| Check | Where | What |
|---|---|---|
| N3 | island 22 at (-71.9, -27.1) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 23 at (71.9, -27.1) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 43 at (-71.9, 27.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 44 at (71.9, 27.1) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 54 islands on top of colliders (735 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | stag_a1-cache_a_a1 vs stag_a2-cache_a_a2 | 17.9 m vs 18.9 m (5.4 %) |
| F2 | stag_a1-cache_a_a1 vs stag_b1-cache_a_b1 | 17.9 m vs 18.9 m (5.4 %) |
| F2 | stag_a2-cache_a_a2 vs stag_b2-cache_a_b2 | 18.9 m vs 17.9 m (5.4 %) |
| F2 | stag_b1-cache_a_b1 vs stag_b2-cache_a_b2 | 18.9 m vs 17.9 m (5.4 %) |
| F2 | third_node_a1-cache_b_b1 vs third_node_a2-cache_b_b2 | 167.2 m vs 158.9 m (5.0 %) |
| F2 | third_node_a1-cache_b_b1 vs third_node_b1-cache_b_a1 | 167.2 m vs 158.9 m (5.0 %) |
| F2 | ford_nest_a1-stag_b1 vs ford_nest_a2-stag_b2 | 129.5 m vs 123.0 m (5.0 %) |
| F2 | home_b_a1-tower_c_a2 vs home_b_b1-tower_c_b2 | 58.3 m vs 61.4 m (5.0 %) |
| F2 | home_b_a1-tower_c_a2 vs home_b_a2-tower_c_a1 | 58.3 m vs 61.4 m (5.0 %) |
| F2 | home_b_a2-tower_c_a1 vs home_b_b2-tower_c_b1 | 61.4 m vs 58.3 m (5.0 %) |
| F2 | home_b_b1-tower_c_b2 vs home_b_b2-tower_c_b1 | 61.4 m vs 58.3 m (5.0 %) |
| F2 | peddler_a1-lairs_one_b1 vs peddler_b2-lairs_one_a2 | 175.7 m vs 167.0 m (4.9 %) |
| F2 | shrine_b1-crown vs shrine_b2-crown | 51.0 m vs 53.6 m (4.9 %) |
| F2 | shrine_a1-crown vs shrine_b1-crown | 53.6 m vs 51.0 m (4.9 %) |
| F2 | cache_a_a2-lairs_one_a1 vs cache_a_b1-lairs_one_b2 | 164.9 m vs 156.8 m (4.9 %) |
| F2 | guilds_den_a1-cache_a_a2 vs guilds_den_a2-cache_a_a1 | 163.4 m vs 171.9 m (4.9 %) |
| F2 | guilds_den_b1-cache_a_b2 vs guilds_den_b2-cache_a_b1 | 171.9 m vs 163.4 m (4.9 %) |
| F2 | guilds_den_a2-cache_a_a1 vs guilds_den_b2-cache_a_b1 | 171.9 m vs 163.4 m (4.9 %) |
| F2 | guilds_den_a1-cache_a_a2 vs guilds_den_b1-cache_a_b2 | 163.4 m vs 171.9 m (4.9 %) |
| F2 | home_b_a1-lairs_one_b1 vs home_b_b1-lairs_one_a1 | 183.4 m vs 192.8 m (4.9 %) |
| F2 | home_b_a1-lairs_one_b1 vs home_b_a2-lairs_one_b2 | 183.4 m vs 192.8 m (4.9 %) |
| F2 | cache_a_a1-x_lane_e vs cache_a_a2-x_lane_e | 101.0 m vs 96.1 m (4.9 %) |
| F2 | cache_a_a1-x_lane_e vs cache_a_b1-x_lane_w | 101.0 m vs 96.1 m (4.9 %) |
| F2 | cache_a_a2-x_lane_e vs cache_a_b2-x_lane_w | 96.1 m vs 101.0 m (4.9 %) |
| F2 | cache_a_b1-x_lane_w vs cache_a_b2-x_lane_w | 96.1 m vs 101.0 m (4.9 %) |
| F2 | tower_c_a1-inn_b2 vs tower_c_b2-inn_a1 | 63.6 m vs 66.9 m (4.9 %) |
| F2 | third_node_a2-cache_b_b2 vs third_node_b2-cache_b_a2 | 158.9 m vs 167.0 m (4.9 %) |
| F2 | third_node_b1-cache_b_a1 vs third_node_b2-cache_b_a2 | 158.9 m vs 167.0 m (4.9 %) |
| F2 | tower_c_a1-wallow_b1 vs tower_c_b1-wallow_a1 | 116.1 m vs 122.0 m (4.9 %) |
| F2 | tower_c_a1-wallow_b1 vs tower_c_a2-wallow_b2 | 116.1 m vs 122.0 m (4.9 %) |
| F2 | home_b_b1-guilds_lodge_a1 vs home_b_b2-guilds_lodge_a2 | 194.8 m vs 185.3 m (4.9 %) |
| F2 | home_b_a2-guilds_lodge_b2 vs home_b_b2-guilds_lodge_a2 | 194.7 m vs 185.3 m (4.9 %) |
| F2 | home_b_b1-guilds_den_b1 vs home_b_b2-guilds_den_b2 | 52.2 m vs 49.7 m (4.9 %) |
| F2 | home_b_a2-guilds_den_a2 vs home_b_b2-guilds_den_b2 | 52.2 m vs 49.7 m (4.9 %) |
| F2 | home_b_a1-guilds_den_a1 vs home_b_b1-guilds_den_b1 | 49.7 m vs 52.2 m (4.9 %) |
| F2 | home_b_a1-guilds_den_a1 vs home_b_a2-guilds_den_a2 | 49.7 m vs 52.2 m (4.9 %) |
| F2 | keep_t0-inn_b1 vs keep_t1-inn_a1 | 112.7 m vs 118.4 m (4.8 %) |
| F2 | keep_t0-inn_b1 vs keep_t3-inn_b2 | 112.7 m vs 118.4 m (4.8 %) |
| F2 | home_b_a1-post_w_a2 vs home_b_a2-post_w_a1 | 48.3 m vs 50.8 m (4.8 %) |
| F2 | home_b_a1-post_w_a2 vs home_b_b1-post_w_b2 | 48.3 m vs 50.8 m (4.8 %) |
| F2 | home_b_b1-post_w_b2 vs home_b_b2-post_w_b1 | 50.8 m vs 48.3 m (4.8 %) |
| F2 | home_b_a2-post_w_a1 vs home_b_b2-post_w_b1 | 50.8 m vs 48.3 m (4.8 %) |
| F2 | tower_c_a2-inn_b1 vs tower_c_b1-inn_a2 | 66.6 m vs 63.4 m (4.8 %) |
| F2 | home_b_a1-guilds_lodge_b1 vs home_b_b1-guilds_lodge_a1 | 185.4 m vs 194.8 m (4.8 %) |
| F2 | home_b_a1-guilds_lodge_b1 vs home_b_a2-guilds_lodge_b2 | 185.4 m vs 194.7 m (4.8 %) |
| F2 | third_node_b1-tower_r_a1 vs third_node_b2-tower_r_a2 | 165.8 m vs 174.2 m (4.8 %) |
| F2 | well_a1-wallow_b1 vs well_b2-wallow_a2 | 157.5 m vs 165.4 m (4.8 %) |
| F2 | cache_a_a1-lairs_one_a2 vs cache_a_a2-lairs_one_a1 | 157.1 m vs 164.9 m (4.8 %) |
| F2 | cache_a_a2-lairs_one_a1 vs cache_a_b2-lairs_one_b1 | 164.9 m vs 157.1 m (4.8 %) |
| F2 | third_node_a2-tower_r_b2 vs third_node_b2-tower_r_a2 | 165.9 m vs 174.2 m (4.8 %) |
| F2 | third_node_a1-lairs_two_b1 vs third_node_b2-lairs_two_a2 | 240.2 m vs 228.7 m (4.8 %) |
| F2 | rich_node_b1-stag_b2 vs rich_node_b2-stag_b1 | 137.7 m vs 144.5 m (4.7 %) |
| F2 | home_a_a1-lairs_one_a1 vs home_a_b1-lairs_one_b1 | 72.7 m vs 76.3 m (4.7 %) |
| F2 | home_a_a1-lairs_one_a1 vs home_a_a2-lairs_one_a2 | 72.7 m vs 76.3 m (4.7 %) |
| F2 | home_a_b1-lairs_one_b1 vs home_a_b2-lairs_one_b2 | 76.3 m vs 72.7 m (4.7 %) |
| F2 | home_a_a2-lairs_one_a2 vs home_a_b2-lairs_one_b2 | 76.3 m vs 72.7 m (4.7 %) |
| F2 | cache_a_a2-x_ford_s vs cache_a_b2-x_ford_n | 111.5 m vs 117.0 m (4.7 %) |
| F2 | inn_a1-x_bridge_n vs inn_a2-x_bridge_s | 91.0 m vs 95.5 m (4.7 %) |
| F2 | keep_t0-home_a_b2 vs keep_t4-home_a_a1 | 147.9 m vs 141.0 m (4.7 %) |
| F2 | shrine_a1-peddler_b2 vs shrine_a2-peddler_b1 | 119.1 m vs 125.0 m (4.7 %) |
| F2 | tower_c_a1-cache_b_b1 vs tower_c_a2-cache_b_b2 | 62.7 m vs 59.8 m (4.7 %) |
| F2 | tower_c_a1-cache_b_b1 vs tower_c_b1-cache_b_a1 | 62.7 m vs 59.8 m (4.7 %) |
| F2 | cache_a_b1-x_ford_s vs cache_a_b2-x_ford_n | 111.5 m vs 117.0 m (4.7 %) |
| F2 | cache_a_a1-x_ford_n vs cache_a_a2-x_ford_s | 116.9 m vs 111.5 m (4.7 %) |
| F2 | third_node_a2-post_s_a1 vs third_node_b2-post_s_b1 | 178.8 m vs 170.5 m (4.7 %) |
| F2 | third_node_a1-post_s_a2 vs third_node_a2-post_s_a1 | 170.5 m vs 178.8 m (4.7 %) |
| F2 | third_node_b1-post_s_b2 vs third_node_b2-post_s_b1 | 178.8 m vs 170.5 m (4.7 %) |
| F2 | third_node_a1-post_s_a2 vs third_node_b1-post_s_b2 | 170.5 m vs 178.8 m (4.7 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t4-lairs_one_a2 | 183.3 m vs 174.7 m (4.7 %) |
| F2 | post_w_a1-post_s_a1 vs post_w_b1-post_s_b1 | 81.3 m vs 77.5 m (4.6 %) |
| F2 | post_w_b1-post_s_b1 vs post_w_b2-post_s_b2 | 77.5 m vs 81.3 m (4.6 %) |
| F2 | home_a_a1-guilds_lodge_b1 vs home_a_a2-guilds_lodge_b2 | 178.5 m vs 187.2 m (4.6 %) |
| F2 | home_a_a1-guilds_lodge_b1 vs home_a_b1-guilds_lodge_a1 | 178.5 m vs 187.2 m (4.6 %) |
| F2 | home_a_a2-nat_node_a1 vs home_a_b2-nat_node_b1 | 51.9 m vs 49.5 m (4.6 %) |
| F2 | home_a_a1-nat_node_a2 vs home_a_a2-nat_node_a1 | 49.5 m vs 51.9 m (4.6 %) |
| F2 | post_s_a1-post_s_b2 vs post_s_a2-post_s_b1 | 101.7 m vs 106.7 m (4.6 %) |
| F2 | keep_t0-nat_node_b1 vs keep_t1-nat_node_a1 | 116.8 m vs 122.5 m (4.6 %) |
| F2 | keep_t0-nat_node_b1 vs keep_t3-nat_node_b2 | 116.8 m vs 122.5 m (4.6 %) |
| F2 | tower_c_a2-cache_b_b2 vs tower_c_b2-cache_b_a2 | 59.8 m vs 62.7 m (4.6 %) |
| F2 | tower_c_b1-cache_b_a1 vs tower_c_b2-cache_b_a2 | 59.8 m vs 62.7 m (4.6 %) |
| F2 | tower_r_b1-stag_b2 vs tower_r_b2-stag_b1 | 142.4 m vs 149.3 m (4.6 %) |
| F2 | cache_a_a1-x_ford_n vs cache_a_b1-x_ford_s | 116.9 m vs 111.5 m (4.6 %) |
| F2 | post_w_a2-post_s_a2 vs post_w_b1-post_s_b1 | 81.3 m vs 77.5 m (4.6 %) |
| F2 | keep_t0-inn_b1 vs keep_t4-inn_a2 | 112.7 m vs 118.1 m (4.6 %) |
| F2 | home_a_a2-nat_node_a1 vs home_a_b1-nat_node_b2 | 51.9 m vs 49.5 m (4.6 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_b2-wallow_a2 | 165.0 m vs 172.9 m (4.6 %) |
| F2 | home_a_b1-tower_c_b2 vs home_a_b2-tower_c_b1 | 53.9 m vs 56.4 m (4.5 %) |
| F2 | home_a_a1-tower_c_a2 vs home_a_b1-tower_c_b2 | 56.4 m vs 53.9 m (4.5 %) |
| F2 | home_a_a2-tower_c_a1 vs home_a_b2-tower_c_b1 | 53.9 m vs 56.4 m (4.5 %) |
| F2 | home_a_a1-tower_c_a2 vs home_a_a2-tower_c_a1 | 56.4 m vs 53.9 m (4.5 %) |
| F2 | keep_t0-post_w_b1 vs keep_t1-post_w_a1 | 154.7 m vs 162.0 m (4.5 %) |
| F2 | tower_c_a1-inn_b2 vs tower_c_a2-inn_b1 | 63.6 m vs 66.6 m (4.5 %) |
| F2 | inn_a2-x_bridge_s vs inn_b1-x_bridge_s | 95.5 m vs 91.2 m (4.5 %) |
| F2 | keep_t0-shrine_b2 vs keep_t3-shrine_b1 | 126.7 m vs 132.6 m (4.5 %) |
| F2 | keep_t0-shrine_b2 vs keep_t1-shrine_a2 | 126.7 m vs 132.6 m (4.5 %) |
| F2 | keep_t0-post_w_b2 vs keep_t4-post_w_a1 | 154.5 m vs 161.8 m (4.5 %) |
| F2 | home_a_a1-guilds_lodge_b1 vs home_a_b2-guilds_lodge_a2 | 178.5 m vs 186.9 m (4.5 %) |
| F2 | rich_node_a1-x_bridge_n vs rich_node_b2-x_bridge_n | 128.9 m vs 123.1 m (4.5 %) |
| F2 | rich_node_a1-lairs_one_a1 vs rich_node_a2-lairs_one_a2 | 57.7 m vs 60.4 m (4.5 %) |
| F2 | keep_t0-nat_node_b1 vs keep_t4-nat_node_a2 | 116.8 m vs 122.3 m (4.4 %) |
| F2 | stag_a1-lairs_one_a2 vs stag_b1-lairs_one_b2 | 175.4 m vs 183.5 m (4.4 %) |
| F2 | stag_b1-lairs_one_b2 vs stag_b2-lairs_one_b1 | 183.5 m vs 175.4 m (4.4 %) |
| F2 | stag_a1-lairs_one_a2 vs stag_a2-lairs_one_a1 | 175.4 m vs 183.5 m (4.4 %) |
| F2 | stag_a2-lairs_one_a1 vs stag_b2-lairs_one_b1 | 183.5 m vs 175.4 m (4.4 %) |
| F2 | rich_node_b1-x_bridge_s vs rich_node_b2-x_bridge_n | 128.7 m vs 123.1 m (4.4 %) |
| F2 | third_node_b1-wallow_a1 vs third_node_b2-wallow_a2 | 221.1 m vs 231.3 m (4.4 %) |
| F2 | third_node_a2-wallow_b2 vs third_node_b2-wallow_a2 | 221.1 m vs 231.3 m (4.4 %) |
| F2 | inn_a1-x_bridge_n vs inn_b2-x_bridge_n | 91.0 m vs 95.2 m (4.4 %) |
| F2 | stag_a2-lairs_two_a2 vs stag_b2-lairs_two_b2 | 29.0 m vs 27.7 m (4.4 %) |
| F2 | stag_b1-lairs_two_b1 vs stag_b2-lairs_two_b2 | 29.0 m vs 27.7 m (4.4 %) |
| F2 | stag_a1-lairs_two_a1 vs stag_a2-lairs_two_a2 | 27.7 m vs 29.0 m (4.4 %) |
| F2 | stag_a1-lairs_two_a1 vs stag_b1-lairs_two_b1 | 27.7 m vs 29.0 m (4.4 %) |
| F2 | home_a_b1-nat_node_a2 vs home_a_b2-nat_node_a1 | 118.5 m vs 113.4 m (4.3 %) |
| F2 | home_a_a1-nat_node_b2 vs home_a_b1-nat_node_a2 | 113.4 m vs 118.5 m (4.3 %) |
| F2 | guilds_den_b1-x_ford_s vs guilds_den_b2-x_ford_n | 149.0 m vs 142.5 m (4.3 %) |
| F2 | third_node_a2-well_b2 vs third_node_b2-well_a2 | 189.1 m vs 181.0 m (4.3 %) |
| F2 | third_node_b1-well_a1 vs third_node_b2-well_a2 | 189.1 m vs 181.0 m (4.3 %) |
| F2 | shrine_a2-x_lane_e vs shrine_b1-x_lane_w | 66.7 m vs 63.9 m (4.3 %) |
| F2 | guilds_den_a1-x_ford_n vs guilds_den_b2-x_ford_n | 149.0 m vs 142.5 m (4.3 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t1-tower_r_a1 | 126.6 m vs 121.2 m (4.3 %) |
| F2 | shrine_a2-peddler_b1 vs shrine_b2-peddler_a1 | 125.0 m vs 119.6 m (4.3 %) |
| F2 | keep_t0-shrine_b2 vs keep_t4-shrine_a1 | 126.7 m vs 132.3 m (4.3 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t4-tower_r_a2 | 126.6 m vs 121.2 m (4.3 %) |
| F2 | home_b_a2-lairs_one_a2 vs home_b_b2-lairs_one_b2 | 59.2 m vs 56.7 m (4.3 %) |
| F2 | home_b_b1-lairs_one_b1 vs home_b_b2-lairs_one_b2 | 59.2 m vs 56.7 m (4.3 %) |
| F2 | home_b_a1-lairs_one_a1 vs home_b_a2-lairs_one_a2 | 56.7 m vs 59.2 m (4.3 %) |
| F2 | home_b_a1-lairs_one_a1 vs home_b_b1-lairs_one_b1 | 56.7 m vs 59.2 m (4.3 %) |
| F2 | rich_node_a1-x_bridge_n vs rich_node_a2-x_bridge_s | 128.9 m vs 123.3 m (4.3 %) |
| F2 | keep_t0-shrine_b1 vs keep_t4-shrine_a2 | 126.9 m vs 132.6 m (4.3 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t3-tower_r_b2 | 126.6 m vs 121.2 m (4.3 %) |
| F2 | guilds_den_a2-x_ford_s vs guilds_den_b1-x_ford_s | 142.6 m vs 149.0 m (4.3 %) |
| F2 | keep_t0-shrine_b1 vs keep_t1-shrine_a1 | 126.9 m vs 132.6 m (4.3 %) |
| F2 | keep_t0-shrine_b1 vs keep_t3-shrine_b2 | 126.9 m vs 132.6 m (4.3 %) |
| F2 | guilds_den_a1-x_ford_n vs guilds_den_a2-x_ford_s | 149.0 m vs 142.6 m (4.2 %) |
| F2 | third_node_a2-stag_a1 vs third_node_b2-stag_b1 | 175.6 m vs 168.1 m (4.2 %) |
| F2 | third_node_a1-stag_a2 vs third_node_b1-stag_b2 | 168.1 m vs 175.6 m (4.2 %) |
| F2 | third_node_a1-stag_a2 vs third_node_a2-stag_a1 | 168.1 m vs 175.6 m (4.2 %) |
| F2 | third_node_b1-stag_b2 vs third_node_b2-stag_b1 | 175.6 m vs 168.1 m (4.2 %) |
| F2 | third_node_a2-shrine_b1 vs third_node_b2-shrine_a1 | 177.3 m vs 185.1 m (4.2 %) |
| F2 | rich_node_a1-lairs_one_a1 vs rich_node_b1-lairs_one_b1 | 57.7 m vs 60.2 m (4.2 %) |
| F2 | inn_b1-x_bridge_s vs inn_b2-x_bridge_n | 91.2 m vs 95.2 m (4.2 %) |
| F2 | third_node_a1-well_b1 vs third_node_b2-well_a2 | 188.9 m vs 181.0 m (4.2 %) |
| F2 | rich_node_a1-stag_b1 vs rich_node_a2-stag_b2 | 153.8 m vs 147.4 m (4.2 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_b1-wallow_a1 | 135.5 m vs 141.4 m (4.2 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_a2-wallow_b2 | 135.5 m vs 141.4 m (4.2 %) |
| F2 | rich_node_a2-x_bridge_s vs rich_node_b1-x_bridge_s | 123.3 m vs 128.7 m (4.2 %) |
| F2 | guilds_den_b1-cache_a_a1 vs guilds_den_b2-cache_a_a2 | 216.2 m vs 207.2 m (4.2 %) |
| F2 | shrine_b1-x_lane_w vs shrine_b2-x_lane_w | 63.9 m vs 66.6 m (4.1 %) |
| F2 | shrine_a1-x_lane_e vs shrine_b1-x_lane_w | 66.6 m vs 63.9 m (4.1 %) |
| F2 | tower_r_a1-stag_b1 vs tower_r_a2-stag_b2 | 157.8 m vs 151.4 m (4.1 %) |
| F2 | tower_r_a2-shrine_b1 vs tower_r_b1-shrine_a2 | 90.0 m vs 93.9 m (4.1 %) |
| F2 | keep_t0-third_node_b1 vs keep_t1-third_node_a1 | 178.0 m vs 185.5 m (4.1 %) |
| F2 | home_b_a1-post_s_b1 vs home_b_b2-post_s_a2 | 171.6 m vs 164.7 m (4.0 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_a2-wallow_b2 | 145.4 m vs 151.5 m (4.0 %) |
| F2 | home_a_a1-third_node_b2 vs home_a_b2-third_node_a1 | 154.0 m vs 160.4 m (4.0 %) |
| F2 | wallow_a2-post_s_b2 vs wallow_b2-post_s_a2 | 190.3 m vs 182.6 m (4.0 %) |
| F2 | wallow_b1-post_s_a1 vs wallow_b2-post_s_a2 | 190.3 m vs 182.6 m (4.0 %) |
| F2 | peddler_a1-peddler_b1 vs peddler_b2-peddler_a2 | 131.2 m vs 136.7 m (4.0 %) |
| F2 | keep_t0-peddler_b2 vs keep_t1-peddler_a2 | 144.0 m vs 149.9 m (4.0 %) |
| F2 | home_a_a1-third_node_b2 vs home_a_b1-third_node_a2 | 154.0 m vs 160.3 m (4.0 %) |
| F2 | wallow_a1-post_s_b1 vs wallow_b2-post_s_a2 | 190.1 m vs 182.6 m (4.0 %) |
| F2 | home_a_a1-third_node_b2 vs home_a_a2-third_node_b1 | 154.0 m vs 160.3 m (3.9 %) |
| F2 | guilds_den_a1-cache_a_b1 vs guilds_den_b2-cache_a_a2 | 215.7 m vs 207.2 m (3.9 %) |
| F2 | keep_t0-peddler_b1 vs keep_t3-peddler_b2 | 138.8 m vs 144.4 m (3.9 %) |
| F2 | keep_t0-peddler_b1 vs keep_t1-peddler_a1 | 138.8 m vs 144.4 m (3.9 %) |
| F2 | keep_t0-home_a_b2 vs keep_t1-home_a_a2 | 147.9 m vs 153.9 m (3.9 %) |
| F2 | keep_t0-home_a_b2 vs keep_t3-home_a_b1 | 147.9 m vs 153.9 m (3.9 %) |
| F2 | rich_node_b1-lairs_one_b1 vs rich_node_b2-lairs_one_b2 | 60.2 m vs 62.6 m (3.8 %) |
| F2 | rich_node_a1-third_node_b2 vs rich_node_b2-third_node_a1 | 90.6 m vs 94.2 m (3.8 %) |
| F2 | tower_c_a2-peddler_b1 vs tower_c_b2-peddler_a1 | 98.9 m vs 95.1 m (3.8 %) |
| F2 | tower_r_a1-x_bridge_n vs tower_r_b2-x_bridge_n | 132.9 m vs 127.8 m (3.8 %) |
| F2 | wallow_b1-cache_a_a1 vs wallow_b2-cache_a_a2 | 175.3 m vs 168.6 m (3.8 %) |
| F2 | wallow_a2-cache_a_b2 vs wallow_b1-cache_a_a1 | 168.7 m vs 175.3 m (3.8 %) |
| F2 | keep_t0-peddler_b1 vs keep_t4-peddler_a2 | 138.8 m vs 144.2 m (3.8 %) |
| F2 | rich_node_a1-stag_a1 vs rich_node_a2-stag_a2 | 30.6 m vs 31.8 m (3.8 %) |
| F2 | tower_r_a1-shrine_b2 vs tower_r_a2-shrine_b1 | 93.6 m vs 90.0 m (3.8 %) |
| F2 | tower_r_b1-shrine_a2 vs tower_r_b2-shrine_a1 | 93.9 m vs 90.3 m (3.8 %) |
| F2 | post_w_a2-peddler_b1 vs post_w_b1-peddler_a2 | 154.3 m vs 148.6 m (3.7 %) |
| F2 | tower_r_b1-x_bridge_s vs tower_r_b2-x_bridge_n | 132.7 m vs 127.8 m (3.7 %) |
| F2 | wallow_a1-cache_a_b1 vs wallow_b2-cache_a_a2 | 175.1 m vs 168.6 m (3.7 %) |
| F2 | rich_node_a1-third_node_b2 vs rich_node_b1-third_node_a2 | 90.6 m vs 94.1 m (3.7 %) |
| F2 | rich_node_a1-third_node_b2 vs rich_node_a2-third_node_b1 | 90.6 m vs 94.1 m (3.7 %) |
| F2 | wallow_a1-cache_a_b1 vs wallow_a2-cache_a_b2 | 175.1 m vs 168.7 m (3.7 %) |
| F2 | keep_t0-home_b_b1 vs keep_t1-home_b_a1 | 146.4 m vs 152.0 m (3.7 %) |
| F2 | keep_t0-home_b_b1 vs keep_t3-home_b_b2 | 146.4 m vs 152.0 m (3.7 %) |
| F2 | keep_t0-home_a_b1 vs keep_t3-home_a_b2 | 148.2 m vs 153.9 m (3.7 %) |
| F2 | keep_t0-home_a_b1 vs keep_t1-home_a_a1 | 148.2 m vs 153.9 m (3.7 %) |
| F2 | keep_t0-home_a_b1 vs keep_t4-home_a_a2 | 148.2 m vs 153.8 m (3.7 %) |
| F2 | keep_t0-post_w_b2 vs keep_t1-post_w_a2 | 154.5 m vs 160.4 m (3.7 %) |
| F2 | keep_t0-post_w_b2 vs keep_t3-post_w_b1 | 154.5 m vs 160.4 m (3.7 %) |
| F2 | peddler_a1-cache_a_b1 vs peddler_b1-cache_a_a1 | 149.0 m vs 154.6 m (3.6 %) |
| F2 | third_node_a1-inn_b2 vs third_node_b1-inn_a2 | 125.9 m vs 121.3 m (3.6 %) |
| F2 | guilds_den_b1-cache_b_a1 vs guilds_den_b2-cache_b_a2 | 168.1 m vs 162.1 m (3.6 %) |
| F2 | rich_node_a2-lairs_one_a2 vs rich_node_b2-lairs_one_b2 | 60.4 m vs 62.6 m (3.6 %) |
| F2 | keep_t0-post_w_b1 vs keep_t3-post_w_b2 | 154.7 m vs 160.4 m (3.6 %) |
| F2 | keep_t0-keep_t1 vs keep_t4-keep_t3 | 151.9 m vs 157.6 m (3.6 %) |
| F2 | tower_r_a1-x_bridge_n vs tower_r_a2-x_bridge_s | 132.9 m vs 128.1 m (3.6 %) |
| F2 | keep_t0-home_b_b1 vs keep_t4-home_b_a2 | 146.4 m vs 151.8 m (3.6 %) |
| F2 | well_a1-wallow_b1 vs well_a2-wallow_b2 | 157.5 m vs 163.3 m (3.6 %) |
| F2 | well_a1-wallow_b1 vs well_b1-wallow_a1 | 157.5 m vs 163.3 m (3.6 %) |
| F2 | keep_t0-cache_a_b1 vs keep_t1-cache_a_a1 | 156.5 m vs 162.3 m (3.5 %) |
| F2 | third_node_b1-inn_a2 vs third_node_b2-inn_a1 | 121.3 m vs 125.8 m (3.5 %) |
| F2 | third_node_a1-inn_b2 vs third_node_a2-inn_b1 | 125.9 m vs 121.4 m (3.5 %) |
| F2 | keep_t0-post_w_b1 vs keep_t4-post_w_a2 | 154.7 m vs 160.3 m (3.5 %) |
| F2 | tower_r_a2-x_bridge_s vs tower_r_b1-x_bridge_s | 128.1 m vs 132.7 m (3.5 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_b2-wallow_a2 | 168.7 m vs 174.8 m (3.5 %) |
| F2 | home_a_b1-tower_r_a1 vs home_a_b2-tower_r_a2 | 117.3 m vs 121.5 m (3.5 %) |
| F2 | post_s_a2-lairs_two_b1 vs post_s_b2-lairs_two_a1 | 117.0 m vs 112.9 m (3.5 %) |
| F2 | keep_t0-guilds_den_b1 vs keep_t4-guilds_den_a2 | 185.9 m vs 179.5 m (3.5 %) |
| F2 | guilds_den_a1-cache_b_b1 vs guilds_den_b1-cache_b_a1 | 162.3 m vs 168.1 m (3.5 %) |
| F2 | third_node_a2-inn_b1 vs third_node_b2-inn_a1 | 121.4 m vs 125.8 m (3.5 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_a2-wallow_b2 | 165.0 m vs 170.9 m (3.5 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_b1-wallow_a1 | 165.0 m vs 170.9 m (3.5 %) |
| F2 | tower_r_a1-shrine_b2 vs tower_r_b2-shrine_a1 | 93.6 m vs 90.3 m (3.5 %) |
| F2 | post_s_a1-cache_a_b2 vs post_s_a2-cache_a_b1 | 100.0 m vs 103.5 m (3.4 %) |
| F2 | post_s_a2-cache_a_b1 vs post_s_b2-cache_a_a1 | 103.5 m vs 100.0 m (3.4 %) |
| F2 | home_a_a2-tower_r_b2 vs home_a_b2-tower_r_a2 | 117.3 m vs 121.5 m (3.4 %) |
| F2 | home_a_a1-tower_r_b1 vs home_a_b1-tower_r_a1 | 121.4 m vs 117.3 m (3.4 %) |
| F2 | wallow_a2-lairs_two_a1 vs wallow_b1-lairs_two_b2 | 124.1 m vs 119.8 m (3.4 %) |
| F2 | third_node_b1-lairs_two_a1 vs third_node_b2-lairs_two_a2 | 220.9 m vs 228.7 m (3.4 %) |
| F2 | third_node_a2-lairs_two_b2 vs third_node_b2-lairs_two_a2 | 220.9 m vs 228.7 m (3.4 %) |
| F2 | wallow_b1-lairs_one_a1 vs wallow_b2-lairs_one_a2 | 202.0 m vs 195.1 m (3.4 %) |
| F2 | wallow_a2-lairs_one_b2 vs wallow_b2-lairs_one_a2 | 202.0 m vs 195.1 m (3.4 %) |
| F2 | wallow_a2-lairs_two_a1 vs wallow_b2-lairs_two_b1 | 124.1 m vs 119.8 m (3.4 %) |
| F2 | wallow_a1-lairs_two_a2 vs wallow_a2-lairs_two_a1 | 119.8 m vs 124.1 m (3.4 %) |
| F2 | home_a_a1-tower_r_b1 vs home_a_a2-tower_r_b2 | 121.4 m vs 117.3 m (3.4 %) |
| F2 | home_b_a1-lairs_one_b1 vs home_b_b2-lairs_one_a2 | 183.4 m vs 177.2 m (3.4 %) |
| F2 | wallow_a1-lairs_one_b1 vs wallow_b2-lairs_one_a2 | 201.9 m vs 195.1 m (3.3 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_b1-lairs_two_a1 | 163.0 m vs 168.6 m (3.3 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_a2-lairs_two_b2 | 163.0 m vs 168.6 m (3.3 %) |
| F2 | stag_b1-guilds_den_b1 vs stag_b2-guilds_den_b2 | 38.4 m vs 37.1 m (3.3 %) |
| F2 | stag_a2-guilds_den_a2 vs stag_b2-guilds_den_b2 | 38.4 m vs 37.1 m (3.3 %) |
| F2 | stag_a1-guilds_den_a1 vs stag_b1-guilds_den_b1 | 37.1 m vs 38.4 m (3.3 %) |
| F2 | stag_a1-guilds_den_a1 vs stag_a2-guilds_den_a2 | 37.1 m vs 38.4 m (3.3 %) |
| F2 | shrine_a2-inn_b1 vs shrine_b1-inn_a2 | 87.2 m vs 90.2 m (3.3 %) |
| F2 | third_node_a1-guilds_den_b1 vs third_node_b2-guilds_den_a2 | 236.1 m vs 244.1 m (3.3 %) |
| F2 | wallow_a1-inn_a2 vs wallow_b1-inn_b2 | 93.6 m vs 96.8 m (3.3 %) |
| F2 | wallow_b1-inn_b2 vs wallow_b2-inn_b1 | 96.8 m vs 93.6 m (3.3 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t1-lairs_two_a1 | 170.5 m vs 176.3 m (3.3 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t3-lairs_two_b2 | 170.5 m vs 176.3 m (3.3 %) |
| F2 | shrine_b1-lairs_two_b2 vs shrine_b2-lairs_two_b1 | 85.4 m vs 82.6 m (3.3 %) |
| F2 | shrine_a2-lairs_two_a1 vs shrine_b2-lairs_two_b1 | 85.4 m vs 82.6 m (3.3 %) |
| F2 | shrine_a1-lairs_two_a2 vs shrine_a2-lairs_two_a1 | 82.6 m vs 85.4 m (3.3 %) |
| F2 | shrine_a1-lairs_two_a2 vs shrine_b1-lairs_two_b2 | 82.6 m vs 85.4 m (3.3 %) |
| F2 | nat_node_a2-post_s_b2 vs nat_node_b1-post_s_a1 | 137.5 m vs 142.2 m (3.3 %) |
| F2 | post_w_a1-x_bridge_n vs post_w_b1-x_bridge_s | 110.5 m vs 114.2 m (3.3 %) |
| F2 | post_w_b1-x_bridge_s vs post_w_b2-x_bridge_n | 114.2 m vs 110.5 m (3.2 %) |
| F2 | nat_node_b1-post_s_a1 vs nat_node_b2-post_s_a2 | 142.2 m vs 137.6 m (3.2 %) |
| F2 | post_w_a1-x_bridge_n vs post_w_a2-x_bridge_s | 110.5 m vs 114.2 m (3.2 %) |
| F2 | third_node_b1-guilds_den_a1 vs third_node_b2-guilds_den_a2 | 236.3 m vs 244.1 m (3.2 %) |
| F2 | third_node_a2-guilds_den_b2 vs third_node_b2-guilds_den_a2 | 236.3 m vs 244.1 m (3.2 %) |
| F2 | post_w_a2-x_bridge_s vs post_w_b2-x_bridge_n | 114.2 m vs 110.5 m (3.2 %) |
| F2 | nat_node_a1-post_s_b1 vs nat_node_a2-post_s_b2 | 142.0 m vs 137.5 m (3.2 %) |
| F2 | shrine_b1-inn_a2 vs shrine_b2-inn_a1 | 90.2 m vs 87.4 m (3.2 %) |
| F2 | shrine_b1-post_w_a2 vs shrine_b2-post_w_a1 | 132.5 m vs 136.8 m (3.2 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_b2-lairs_two_a2 | 163.0 m vs 168.3 m (3.2 %) |
| F2 | shrine_a1-inn_b2 vs shrine_b1-inn_a2 | 93.2 m vs 90.2 m (3.2 %) |
| F2 | tower_c_a1-post_w_a1 vs tower_c_a2-post_w_a2 | 57.2 m vs 59.1 m (3.2 %) |
| F2 | tower_c_a2-post_w_a2 vs tower_c_b1-post_w_b1 | 59.1 m vs 57.2 m (3.2 %) |
| F2 | nat_node_a1-post_s_b1 vs nat_node_b2-post_s_a2 | 142.0 m vs 137.6 m (3.1 %) |
| F2 | home_a_a1-crown vs home_a_b1-crown | 72.6 m vs 75.0 m (3.1 %) |
| F2 | home_a_a1-crown vs home_a_a2-crown | 72.6 m vs 75.0 m (3.1 %) |
| F2 | wallow_a1-wallow_b1 vs wallow_b2-wallow_a2 | 183.5 m vs 189.5 m (3.1 %) |
| F2 | keep_t0-third_node_b1 vs keep_t3-third_node_b2 | 178.0 m vs 183.7 m (3.1 %) |
| F2 | ford_nest_a2-stag_a1 vs ford_nest_a2-stag_b2 | 127.0 m vs 123.0 m (3.1 %) |
| F2 | peddler_a1-lairs_one_b1 vs peddler_a2-lairs_one_b2 | 175.7 m vs 181.3 m (3.1 %) |
| F2 | peddler_a1-lairs_one_b1 vs peddler_b1-lairs_one_a1 | 175.7 m vs 181.3 m (3.1 %) |
| F2 | third_node_a1-tower_r_b1 vs third_node_b2-tower_r_a2 | 168.8 m vs 174.2 m (3.1 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t4-lairs_two_a2 | 170.5 m vs 176.0 m (3.1 %) |
| F2 | home_b_a1-post_s_b1 vs home_b_b1-post_s_a1 | 171.6 m vs 166.3 m (3.1 %) |
| F2 | home_a_a1-x_lane_w vs home_a_b1-x_lane_e | 60.3 m vs 62.3 m (3.1 %) |
| F2 | home_a_a1-x_lane_w vs home_a_a2-x_lane_w | 60.3 m vs 62.3 m (3.1 %) |
| F2 | third_node_a1-wallow_b2 vs third_node_b1-wallow_a2 | 163.2 m vs 158.2 m (3.1 %) |
| F2 | rich_node_a2-stag_a1 vs rich_node_b1-stag_b2 | 142.1 m vs 137.7 m (3.1 %) |
| F2 | third_node_b1-wallow_a2 vs third_node_b2-wallow_a1 | 158.2 m vs 163.2 m (3.1 %) |
| F2 | wallow_a1-lairs_one_a2 vs wallow_a2-lairs_one_a1 | 133.9 m vs 138.1 m (3.1 %) |
| F2 | wallow_b1-lairs_one_b2 vs wallow_b2-lairs_one_b1 | 138.1 m vs 133.9 m (3.1 %) |
| F2 | wallow_a1-lairs_one_a2 vs wallow_b1-lairs_one_b2 | 133.9 m vs 138.1 m (3.1 %) |
| F2 | wallow_a2-lairs_one_a1 vs wallow_b2-lairs_one_b1 | 138.1 m vs 133.9 m (3.1 %) |
| F2 | third_node_a1-wallow_b2 vs third_node_a2-wallow_b1 | 163.2 m vs 158.2 m (3.1 %) |
| F2 | shrine_b1-wallow_a1 vs shrine_b2-wallow_a2 | 148.8 m vs 153.5 m (3.1 %) |
| F2 | third_node_a2-wallow_b1 vs third_node_b2-wallow_a1 | 158.2 m vs 163.2 m (3.1 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t3-lairs_one_b2 | 183.3 m vs 189.0 m (3.1 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t1-lairs_one_a1 | 183.3 m vs 189.0 m (3.1 %) |
| F2 | tower_c_a1-peddler_a2 vs tower_c_b2-peddler_b1 | 48.4 m vs 49.9 m (3.0 %) |
| F2 | tower_c_b1-peddler_b2 vs tower_c_b2-peddler_b1 | 48.4 m vs 49.9 m (3.0 %) |
| F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b2-cache_b_a2 | 167.1 m vs 162.1 m (3.0 %) |
| F2 | tower_c_b1-post_w_b1 vs tower_c_b2-post_w_b2 | 57.2 m vs 59.0 m (3.0 %) |
| F2 | tower_c_a1-post_w_a1 vs tower_c_b2-post_w_b2 | 57.2 m vs 59.0 m (3.0 %) |
| F2 | tower_c_b1-post_s_a1 vs tower_c_b2-post_s_a2 | 122.8 m vs 119.1 m (3.0 %) |
| F2 | tower_c_a2-post_s_b2 vs tower_c_b2-post_s_a2 | 122.8 m vs 119.1 m (3.0 %) |
| F2 | home_a_a2-lairs_two_a1 vs home_a_b2-lairs_two_b1 | 93.5 m vs 96.4 m (3.0 %) |
| F2 | home_a_a1-lairs_two_a2 vs home_a_b1-lairs_two_b2 | 96.4 m vs 93.5 m (3.0 %) |
| F2 | home_a_b1-lairs_two_b2 vs home_a_b2-lairs_two_b1 | 93.5 m vs 96.4 m (3.0 %) |
| F2 | home_a_a1-lairs_two_a2 vs home_a_a2-lairs_two_a1 | 96.4 m vs 93.5 m (3.0 %) |
| F2 | keep_t0-guilds_den_b1 vs keep_t3-guilds_den_b2 | 185.9 m vs 191.7 m (3.0 %) |
| F2 | keep_t0-guilds_den_b1 vs keep_t1-guilds_den_a1 | 185.9 m vs 191.7 m (3.0 %) |
| F2 | home_a_a1-crown vs home_a_b2-crown | 72.6 m vs 74.9 m (3.0 %) |
| F2 | third_node_a2-post_s_b2 vs third_node_b2-post_s_a2 | 221.9 m vs 215.3 m (3.0 %) |
| F2 | tower_r_a2-stag_a1 vs tower_r_b1-stag_b2 | 146.8 m vs 142.4 m (3.0 %) |
| F2 | keep_t0-guilds_lodge_b1 vs keep_t1-guilds_lodge_a1 | 185.3 m vs 191.0 m (3.0 %) |
| F2 | stag_a1-peddler_a1 vs stag_a2-peddler_a2 | 61.5 m vs 63.4 m (3.0 %) |
| F2 | stag_a2-peddler_a2 vs stag_b2-peddler_b2 | 63.4 m vs 61.5 m (3.0 %) |
| F2 | stag_a1-peddler_a1 vs stag_b1-peddler_b1 | 61.5 m vs 63.4 m (3.0 %) |
| F2 | stag_b1-peddler_b1 vs stag_b2-peddler_b2 | 63.4 m vs 61.5 m (3.0 %) |
| F2 | keep_t0-third_node_b1 vs keep_t4-third_node_a2 | 178.0 m vs 183.4 m (3.0 %) |
| F2 | post_s_a2-lairs_one_b1 vs post_s_b2-lairs_one_a1 | 120.4 m vs 116.8 m (3.0 %) |
| F2 | post_s_a1-lairs_one_b2 vs post_s_a2-lairs_one_b1 | 116.8 m vs 120.4 m (2.9 %) |
| F2 | post_s_a2-guilds_den_b1 vs post_s_b2-guilds_den_a1 | 131.2 m vs 127.3 m (2.9 %) |
| F2 | keep_t0-guilds_lodge_b1 vs keep_t3-guilds_lodge_b2 | 185.3 m vs 190.9 m (2.9 %) |
| F2 | post_s_a1-guilds_den_b2 vs post_s_a2-guilds_den_b1 | 127.3 m vs 131.2 m (2.9 %) |
| F2 | guilds_den_a1-cache_b_b1 vs guilds_den_a2-cache_b_b2 | 162.3 m vs 167.1 m (2.9 %) |
| F2 | home_a_a1-x_lane_w vs home_a_b2-x_lane_e | 60.3 m vs 62.2 m (2.9 %) |
| F2 | tower_c_a1-peddler_a2 vs tower_c_a2-peddler_a1 | 48.4 m vs 49.8 m (2.9 %) |
| F2 | tower_c_a2-peddler_a1 vs tower_c_b1-peddler_b2 | 49.8 m vs 48.4 m (2.9 %) |
| F2 | tower_c_a1-post_s_b1 vs tower_c_b2-post_s_a2 | 122.7 m vs 119.1 m (2.9 %) |
| F2 | guilds_lodge_a1-cache_b_a2 vs guilds_lodge_b1-cache_b_b2 | 135.3 m vs 131.4 m (2.9 %) |
| F2 | guilds_lodge_a1-cache_b_a2 vs guilds_lodge_a2-cache_b_a1 | 135.3 m vs 131.4 m (2.9 %) |
| F2 | post_w_b1-x_lane_e vs post_w_b2-x_lane_e | 70.4 m vs 68.3 m (2.9 %) |
| F2 | post_w_a1-x_lane_w vs post_w_b1-x_lane_e | 68.3 m vs 70.4 m (2.9 %) |
| F2 | post_w_a2-x_lane_w vs post_w_b2-x_lane_e | 70.4 m vs 68.3 m (2.9 %) |
| F2 | post_w_a1-x_lane_w vs post_w_a2-x_lane_w | 68.3 m vs 70.4 m (2.9 %) |
| F2 | home_b_a2-cache_b_a1 vs home_b_b2-cache_b_b1 | 83.6 m vs 81.2 m (2.9 %) |
| F2 | home_b_b1-cache_b_b2 vs home_b_b2-cache_b_b1 | 83.6 m vs 81.2 m (2.9 %) |
| F2 | home_b_a1-cache_b_a2 vs home_b_a2-cache_b_a1 | 81.2 m vs 83.6 m (2.9 %) |
| F2 | home_b_a1-cache_b_a2 vs home_b_b1-cache_b_b2 | 81.2 m vs 83.6 m (2.9 %) |
| F2 | shrine_a2-inn_b2 vs shrine_b1-inn_a1 | 93.4 m vs 90.8 m (2.9 %) |
| F2 | guilds_lodge_a1-cache_b_a2 vs guilds_lodge_b2-cache_b_b1 | 135.3 m vs 131.4 m (2.9 %) |
| F2 | ford_nest_a1-stag_a2 vs ford_nest_a1-stag_b1 | 125.8 m vs 129.5 m (2.9 %) |
| F2 | nat_node_b1-third_node_b2 vs nat_node_b2-third_node_b1 | 101.9 m vs 99.0 m (2.9 %) |
| F2 | nat_node_a1-third_node_a2 vs nat_node_b1-third_node_b2 | 99.0 m vs 101.9 m (2.9 %) |
| F2 | home_a_a1-guilds_den_a2 vs home_a_b1-guilds_den_b2 | 103.5 m vs 100.5 m (2.8 %) |
| F2 | home_a_a1-guilds_den_a2 vs home_a_a2-guilds_den_a1 | 103.5 m vs 100.5 m (2.8 %) |
| F2 | home_a_a2-guilds_den_a1 vs home_a_b2-guilds_den_b1 | 100.5 m vs 103.5 m (2.8 %) |
| F2 | home_a_b1-guilds_den_b2 vs home_a_b2-guilds_den_b1 | 100.5 m vs 103.5 m (2.8 %) |
| F2 | nat_node_a2-third_node_a1 vs nat_node_b1-third_node_b2 | 99.0 m vs 101.9 m (2.8 %) |
| F2 | shrine_a2-cache_a_a1 vs shrine_b2-cache_a_b1 | 74.7 m vs 72.6 m (2.8 %) |
| F2 | shrine_a1-cache_a_a2 vs shrine_a2-cache_a_a1 | 72.6 m vs 74.7 m (2.8 %) |
| F2 | shrine_a1-cache_a_a2 vs shrine_b1-cache_a_b2 | 72.6 m vs 74.7 m (2.8 %) |
| F2 | shrine_b1-cache_a_b2 vs shrine_b2-cache_a_b1 | 74.7 m vs 72.6 m (2.8 %) |
| F2 | nat_node_a2-cache_a_b2 vs nat_node_b1-cache_a_a1 | 123.6 m vs 127.2 m (2.8 %) |
| F2 | nat_node_b1-cache_a_a1 vs nat_node_b2-cache_a_a2 | 127.2 m vs 123.6 m (2.8 %) |
| F2 | keep_t0-guilds_lodge_b1 vs keep_t4-guilds_lodge_a2 | 185.3 m vs 190.6 m (2.8 %) |
| F2 | post_s_a2-guilds_lodge_b1 vs post_s_b2-guilds_lodge_a1 | 140.1 m vs 136.2 m (2.8 %) |
| F2 | stag_a1-guilds_lodge_a1 vs stag_a2-guilds_lodge_a2 | 46.0 m vs 47.3 m (2.8 %) |
| F2 | stag_a1-guilds_lodge_a1 vs stag_b1-guilds_lodge_b1 | 46.0 m vs 47.3 m (2.8 %) |
| F2 | stag_a2-guilds_lodge_a2 vs stag_b2-guilds_lodge_b2 | 47.3 m vs 46.0 m (2.8 %) |
| F2 | stag_b1-guilds_lodge_b1 vs stag_b2-guilds_lodge_b2 | 47.3 m vs 46.0 m (2.8 %) |
| F2 | cache_a_a1-cache_a_b1 vs cache_a_b2-cache_a_a2 | 171.6 m vs 166.9 m (2.8 %) |
| F2 | post_s_a1-guilds_lodge_b2 vs post_s_a2-guilds_lodge_b1 | 136.2 m vs 140.1 m (2.8 %) |
| F2 | third_node_a1-wallow_b1 vs third_node_a2-wallow_b2 | 215.0 m vs 221.1 m (2.7 %) |
| F2 | third_node_a1-wallow_b1 vs third_node_b1-wallow_a1 | 215.0 m vs 221.1 m (2.7 %) |
| F2 | shrine_b1-peddler_a2 vs shrine_b2-peddler_a1 | 116.3 m vs 119.6 m (2.7 %) |
| F2 | home_a_a1-home_b_b1 vs home_a_b2-home_b_a2 | 152.3 m vs 148.1 m (2.7 %) |
| F2 | third_node_a2-lairs_two_a1 vs third_node_b1-lairs_two_b2 | 153.3 m vs 149.1 m (2.7 %) |
| F2 | nat_node_a1-cache_a_b1 vs nat_node_a2-cache_a_b2 | 127.1 m vs 123.6 m (2.7 %) |
| F2 | guilds_lodge_a2-lairs_two_a1 vs guilds_lodge_b1-lairs_two_b2 | 155.0 m vs 150.8 m (2.7 %) |
| F2 | third_node_a2-lairs_two_a1 vs third_node_b2-lairs_two_b1 | 153.3 m vs 149.2 m (2.7 %) |
| F2 | third_node_a1-lairs_two_a2 vs third_node_a2-lairs_two_a1 | 149.2 m vs 153.3 m (2.7 %) |
| F2 | nat_node_a1-cache_a_b1 vs nat_node_b2-cache_a_a2 | 127.1 m vs 123.6 m (2.7 %) |
| F2 | guilds_lodge_a2-lairs_two_a1 vs guilds_lodge_b2-lairs_two_b1 | 155.0 m vs 150.8 m (2.7 %) |
| F2 | guilds_lodge_a1-lairs_two_a2 vs guilds_lodge_a2-lairs_two_a1 | 150.8 m vs 155.0 m (2.7 %) |
| F2 | post_s_a2-lairs_two_b1 vs post_s_b1-lairs_two_a2 | 117.0 m vs 113.8 m (2.7 %) |
| F2 | post_w_a1-crown vs post_w_a2-crown | 80.9 m vs 83.1 m (2.7 %) |
| F2 | post_w_a2-crown vs post_w_b2-crown | 83.1 m vs 80.9 m (2.7 %) |
| F2 | post_w_b1-crown vs post_w_b2-crown | 83.1 m vs 80.9 m (2.7 %) |
| F2 | post_w_a1-crown vs post_w_b1-crown | 80.9 m vs 83.1 m (2.7 %) |
| F2 | rich_node_a1-stag_a2 vs rich_node_b2-stag_b1 | 140.7 m vs 144.5 m (2.6 %) |
| F2 | home_a_a1-home_b_b1 vs home_a_a2-home_b_b2 | 152.3 m vs 148.3 m (2.6 %) |
| F2 | home_a_a1-home_b_b1 vs home_a_b1-home_b_a1 | 152.3 m vs 148.3 m (2.6 %) |
| F2 | post_s_a2-lairs_one_b1 vs post_s_b1-lairs_one_a2 | 120.4 m vs 117.2 m (2.6 %) |
| F2 | home_a_b1-lairs_one_b2 vs home_a_b2-lairs_one_b1 | 107.6 m vs 110.5 m (2.6 %) |
| F2 | home_a_a1-lairs_one_a2 vs home_a_a2-lairs_one_a1 | 110.5 m vs 107.6 m (2.6 %) |
| F2 | home_a_a2-lairs_one_a1 vs home_a_b2-lairs_one_b1 | 107.6 m vs 110.5 m (2.6 %) |
| F2 | home_a_a1-lairs_one_a2 vs home_a_b1-lairs_one_b2 | 110.5 m vs 107.6 m (2.6 %) |
| F2 | rich_node_a2-stag_b2 vs rich_node_b1-stag_a1 | 147.4 m vs 151.3 m (2.6 %) |
| F2 | rich_node_a1-guilds_lodge_b2 vs rich_node_b2-guilds_lodge_a1 | 99.5 m vs 102.2 m (2.6 %) |
| F2 | post_s_a2-cache_a_b1 vs post_s_b1-cache_a_a2 | 103.5 m vs 100.8 m (2.6 %) |
| F2 | post_s_a2-guilds_lodge_a1 vs post_s_b1-guilds_lodge_b2 | 161.4 m vs 165.7 m (2.6 %) |
| F2 | wallow_a1-x_bridge_n vs wallow_b1-x_bridge_s | 141.0 m vs 144.7 m (2.6 %) |
| F2 | cache_a_a1-lairs_two_b1 vs cache_a_a2-lairs_two_b2 | 185.7 m vs 180.9 m (2.6 %) |
| F2 | cache_a_a1-lairs_two_b1 vs cache_a_b1-lairs_two_a1 | 185.7 m vs 180.9 m (2.6 %) |
| F2 | tower_r_a2-stag_b2 vs tower_r_b1-stag_a1 | 151.4 m vs 155.4 m (2.6 %) |
| F2 | wallow_b1-x_bridge_s vs wallow_b2-x_bridge_n | 144.7 m vs 141.0 m (2.6 %) |
| F2 | guilds_den_a2-lairs_two_a1 vs guilds_den_b1-lairs_two_b2 | 163.3 m vs 159.1 m (2.6 %) |
| F2 | tower_r_a1-stag_a2 vs tower_r_b2-stag_b1 | 145.5 m vs 149.3 m (2.6 %) |
| F2 | guilds_den_a1-lairs_two_a2 vs guilds_den_a2-lairs_two_a1 | 159.1 m vs 163.3 m (2.6 %) |
| F2 | guilds_den_a2-lairs_two_a1 vs guilds_den_b2-lairs_two_b1 | 163.3 m vs 159.1 m (2.6 %) |
| F2 | shrine_b1-inn_a1 vs shrine_b2-inn_a2 | 90.8 m vs 93.1 m (2.5 %) |
| F2 | shrine_a1-inn_b1 vs shrine_b1-inn_a1 | 93.1 m vs 90.8 m (2.5 %) |
| F2 | wallow_a1-post_s_a1 vs wallow_b2-post_s_b2 | 52.1 m vs 50.7 m (2.5 %) |
| F2 | third_node_a1-lairs_one_a2 vs third_node_a2-lairs_one_a1 | 163.2 m vs 167.4 m (2.5 %) |
| F2 | third_node_b1-lairs_one_b2 vs third_node_b2-lairs_one_b1 | 167.4 m vs 163.2 m (2.5 %) |
| F2 | third_node_a1-lairs_one_a2 vs third_node_b1-lairs_one_b2 | 163.2 m vs 167.4 m (2.5 %) |
| F2 | third_node_a2-lairs_one_a1 vs third_node_b2-lairs_one_b1 | 167.4 m vs 163.2 m (2.5 %) |
| F2 | guilds_lodge_a1-lairs_one_a2 vs guilds_lodge_a2-lairs_one_a1 | 164.9 m vs 169.1 m (2.5 %) |
| F2 | guilds_lodge_a2-lairs_one_a1 vs guilds_lodge_b2-lairs_one_b1 | 169.1 m vs 164.9 m (2.5 %) |
| F2 | guilds_lodge_b1-lairs_one_b2 vs guilds_lodge_b2-lairs_one_b1 | 169.1 m vs 164.9 m (2.5 %) |
| F2 | guilds_lodge_a1-lairs_one_a2 vs guilds_lodge_b1-lairs_one_b2 | 164.9 m vs 169.1 m (2.5 %) |
| F2 | tower_c_a2-cache_a_b2 vs tower_c_b2-cache_a_a2 | 107.8 m vs 105.2 m (2.5 %) |
| F2 | tower_c_b1-cache_a_a1 vs tower_c_b2-cache_a_a2 | 107.8 m vs 105.2 m (2.5 %) |
| F2 | nat_node_b1-lairs_one_a1 vs nat_node_b2-lairs_one_a2 | 153.9 m vs 150.1 m (2.5 %) |
| F2 | nat_node_a2-lairs_one_b2 vs nat_node_b2-lairs_one_a2 | 153.9 m vs 150.1 m (2.5 %) |
| F2 | keep_t1-lairs_two_b2 vs keep_t4-lairs_two_b1 | 102.2 m vs 104.7 m (2.5 %) |
| F2 | keep_t3-lairs_two_a1 vs keep_t4-lairs_two_b1 | 102.2 m vs 104.7 m (2.5 %) |
| F2 | keep_t0-lairs_two_a2 vs keep_t1-lairs_two_b2 | 104.7 m vs 102.2 m (2.5 %) |
| F2 | keep_t0-lairs_two_a2 vs keep_t3-lairs_two_a1 | 104.7 m vs 102.2 m (2.5 %) |
| F2 | rich_node_a1-guilds_lodge_b2 vs rich_node_b1-guilds_lodge_a2 | 99.5 m vs 102.0 m (2.5 %) |
| F2 | rich_node_a1-guilds_lodge_b2 vs rich_node_a2-guilds_lodge_b1 | 99.5 m vs 102.0 m (2.5 %) |
| F2 | post_s_a2-peddler_b1 vs post_s_b2-peddler_a1 | 128.4 m vs 125.3 m (2.5 %) |
| F2 | home_b_a1-third_node_b2 vs home_b_b2-third_node_a1 | 144.1 m vs 147.7 m (2.5 %) |
| F2 | wallow_b1-post_s_b1 vs wallow_b2-post_s_b2 | 52.0 m vs 50.7 m (2.4 %) |
| F2 | wallow_a2-post_s_a2 vs wallow_b2-post_s_b2 | 52.0 m vs 50.7 m (2.4 %) |
| F2 | post_s_a1-peddler_b2 vs post_s_a2-peddler_b1 | 125.3 m vs 128.4 m (2.4 %) |
| F2 | post_s_a1-guilds_lodge_a2 vs post_s_b1-guilds_lodge_b2 | 161.7 m vs 165.7 m (2.4 %) |
| F2 | post_s_b1-guilds_lodge_b2 vs post_s_b2-guilds_lodge_b1 | 165.7 m vs 161.7 m (2.4 %) |
| F2 | post_s_a2-guilds_den_b1 vs post_s_b1-guilds_den_a2 | 131.2 m vs 128.0 m (2.4 %) |
| F2 | nat_node_a1-lairs_one_b1 vs nat_node_b2-lairs_one_a2 | 153.8 m vs 150.1 m (2.4 %) |
| F2 | cache_a_a1-lairs_one_b1 vs cache_a_a2-lairs_one_b2 | 198.4 m vs 193.6 m (2.4 %) |
| F2 | cache_a_a1-lairs_one_b1 vs cache_a_b1-lairs_one_a1 | 198.4 m vs 193.6 m (2.4 %) |
| F2 | rich_node_a1-stag_b1 vs rich_node_b2-stag_a2 | 153.8 m vs 150.1 m (2.4 %) |
| F2 | wallow_a2-x_bridge_s vs wallow_b1-x_bridge_s | 141.2 m vs 144.7 m (2.4 %) |
| F2 | post_w_a1-x_lane_e vs post_w_b1-x_lane_w | 93.8 m vs 96.1 m (2.4 %) |
| F2 | post_w_a2-x_lane_e vs post_w_b2-x_lane_w | 96.1 m vs 93.8 m (2.4 %) |
| F2 | post_w_b1-x_lane_w vs post_w_b2-x_lane_w | 96.1 m vs 93.8 m (2.4 %) |
| F2 | post_w_a1-x_lane_e vs post_w_a2-x_lane_e | 93.8 m vs 96.1 m (2.4 %) |
| F2 | home_b_a1-third_node_b2 vs home_b_b1-third_node_a2 | 144.1 m vs 147.6 m (2.4 %) |
| F2 | home_b_a1-third_node_b2 vs home_b_a2-third_node_b1 | 144.1 m vs 147.6 m (2.4 %) |
| F2 | guilds_den_a2-lairs_one_a1 vs guilds_den_b2-lairs_one_b1 | 177.4 m vs 173.2 m (2.4 %) |
| F2 | guilds_den_b1-lairs_one_b2 vs guilds_den_b2-lairs_one_b1 | 177.4 m vs 173.2 m (2.4 %) |
| F2 | guilds_den_a1-lairs_one_a2 vs guilds_den_a2-lairs_one_a1 | 173.2 m vs 177.4 m (2.4 %) |
| F2 | guilds_den_a1-lairs_one_a2 vs guilds_den_b1-lairs_one_b2 | 173.2 m vs 177.4 m (2.4 %) |
| F2 | keep_t0-third_node_b2 vs keep_t4-third_node_a1 | 150.3 m vs 153.9 m (2.4 %) |
| F2 | home_a_a1-tower_r_a2 vs home_a_b1-tower_r_b2 | 95.1 m vs 97.4 m (2.4 %) |
| F2 | home_a_a1-tower_r_a2 vs home_a_a2-tower_r_a1 | 95.1 m vs 97.4 m (2.4 %) |
| F2 | home_a_a2-tower_r_a1 vs home_a_b2-tower_r_b1 | 97.4 m vs 95.1 m (2.4 %) |
| F2 | home_a_b1-tower_r_b2 vs home_a_b2-tower_r_b1 | 97.4 m vs 95.1 m (2.4 %) |
| F2 | home_b_b1-stag_a1 vs home_b_b2-stag_a2 | 154.8 m vs 151.2 m (2.3 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_b1-wallow_a1 | 168.7 m vs 172.7 m (2.3 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_a2-wallow_b2 | 168.7 m vs 172.7 m (2.3 %) |
| F2 | wallow_b1-guilds_den_a1 vs wallow_b2-guilds_den_a2 | 204.7 m vs 199.9 m (2.3 %) |
| F2 | wallow_a2-guilds_den_b2 vs wallow_b2-guilds_den_a2 | 204.7 m vs 199.9 m (2.3 %) |
| F2 | shrine_a1-inn_a2 vs shrine_b1-inn_b2 | 39.8 m vs 38.8 m (2.3 %) |
| F2 | shrine_b1-inn_b2 vs shrine_b2-inn_b1 | 38.8 m vs 39.8 m (2.3 %) |
| F2 | shrine_a1-inn_a2 vs shrine_a2-inn_a1 | 39.8 m vs 38.8 m (2.3 %) |
| F2 | shrine_a2-inn_a1 vs shrine_b2-inn_b1 | 38.8 m vs 39.8 m (2.3 %) |
| F2 | post_s_a1-lairs_two_b2 vs post_s_a2-lairs_two_b1 | 114.3 m vs 117.0 m (2.3 %) |
| F2 | shrine_a1-peddler_b2 vs shrine_b1-peddler_a2 | 119.1 m vs 116.3 m (2.3 %) |
| F2 | tower_r_a2-post_s_a2 vs tower_r_b2-post_s_b2 | 41.9 m vs 40.9 m (2.3 %) |
| F2 | keep_t1-tower_c_b2 vs keep_t4-tower_c_b1 | 57.6 m vs 56.3 m (2.3 %) |
| F2 | keep_t0-tower_c_a2 vs keep_t3-tower_c_a1 | 56.3 m vs 57.6 m (2.3 %) |
| F2 | keep_t0-tower_c_a2 vs keep_t1-tower_c_b2 | 56.3 m vs 57.6 m (2.3 %) |
| F2 | keep_t3-tower_c_a1 vs keep_t4-tower_c_b1 | 57.6 m vs 56.3 m (2.3 %) |
| F2 | keep_t0-guilds_den_a2 vs keep_t1-guilds_den_b2 | 111.8 m vs 109.2 m (2.3 %) |
| F2 | keep_t1-guilds_den_b2 vs keep_t4-guilds_den_b1 | 109.2 m vs 111.8 m (2.3 %) |
| F2 | keep_t3-guilds_den_a1 vs keep_t4-guilds_den_b1 | 109.2 m vs 111.8 m (2.3 %) |
| F2 | keep_t0-guilds_den_a2 vs keep_t3-guilds_den_a1 | 111.8 m vs 109.2 m (2.3 %) |
| F2 | tower_c_a1-cache_a_b1 vs tower_c_b2-cache_a_a2 | 107.7 m vs 105.2 m (2.3 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_b1-wallow_a1 | 145.4 m vs 148.8 m (2.3 %) |
| F2 | tower_r_a1-stag_b1 vs tower_r_b2-stag_a2 | 157.8 m vs 154.1 m (2.3 %) |
| F2 | wallow_a1-guilds_den_b1 vs wallow_b2-guilds_den_a2 | 204.6 m vs 199.9 m (2.3 %) |
| F2 | guilds_lodge_a1-x_ford_n vs guilds_lodge_a2-x_ford_s | 147.9 m vs 144.5 m (2.3 %) |
| F2 | keep_t0-third_node_b2 vs keep_t1-third_node_a2 | 150.3 m vs 153.8 m (2.3 %) |
| F2 | keep_t0-third_node_b2 vs keep_t3-third_node_b1 | 150.3 m vs 153.8 m (2.3 %) |
| F2 | post_s_a2-guilds_lodge_b1 vs post_s_b1-guilds_lodge_a2 | 140.1 m vs 136.9 m (2.3 %) |
| F2 | third_node_a2-peddler_a2 vs third_node_b1-peddler_b1 | 53.6 m vs 54.8 m (2.3 %) |
| F2 | shrine_a2-peddler_b2 vs shrine_b1-peddler_a1 | 119.4 m vs 116.7 m (2.2 %) |
| F2 | shrine_b1-post_s_b2 vs shrine_b2-post_s_b1 | 91.6 m vs 89.6 m (2.2 %) |
| F2 | shrine_a1-post_s_a2 vs shrine_b1-post_s_b2 | 89.6 m vs 91.6 m (2.2 %) |
| F2 | shrine_a2-post_s_a1 vs shrine_b2-post_s_b1 | 91.6 m vs 89.6 m (2.2 %) |
| F2 | shrine_a1-post_s_a2 vs shrine_a2-post_s_a1 | 89.6 m vs 91.6 m (2.2 %) |
| F2 | ford_nest_a1-stag_a2 vs ford_nest_a2-stag_b2 | 125.8 m vs 123.0 m (2.2 %) |
| F2 | post_s_a2-x_bridge_n vs post_s_b2-x_bridge_s | 52.8 m vs 51.7 m (2.2 %) |
| F2 | post_s_a1-x_bridge_s vs post_s_a2-x_bridge_n | 51.7 m vs 52.8 m (2.2 %) |
| F2 | keep_t0-lairs_one_a2 vs keep_t3-lairs_one_a1 | 118.8 m vs 116.2 m (2.2 %) |
| F2 | keep_t0-lairs_one_a2 vs keep_t1-lairs_one_b2 | 118.8 m vs 116.2 m (2.2 %) |
| F2 | keep_t1-lairs_one_b2 vs keep_t4-lairs_one_b1 | 116.2 m vs 118.8 m (2.2 %) |
| F2 | keep_t3-lairs_one_a1 vs keep_t4-lairs_one_b1 | 116.2 m vs 118.8 m (2.2 %) |
| F2 | rich_node_a1-stag_a2 vs rich_node_b1-stag_b2 | 140.7 m vs 137.7 m (2.2 %) |
| F2 | shrine_a2-post_w_b1 vs shrine_b1-post_w_a2 | 135.4 m vs 132.5 m (2.2 %) |
| F2 | third_node_a1-x_bridge_n vs third_node_b1-x_bridge_s | 170.2 m vs 174.0 m (2.1 %) |
| F2 | cache_a_a1-x_bridge_n vs cache_a_b1-x_bridge_s | 153.1 m vs 149.8 m (2.1 %) |
| F2 | third_node_b1-x_bridge_s vs third_node_b2-x_bridge_n | 174.0 m vs 170.3 m (2.1 %) |
| F2 | guilds_lodge_a1-x_bridge_n vs guilds_lodge_b1-x_bridge_s | 171.9 m vs 175.7 m (2.1 %) |
| F2 | tower_r_a1-post_s_a1 vs tower_r_a2-post_s_a2 | 41.0 m vs 41.9 m (2.1 %) |
| F2 | home_a_a1-rich_node_a2 vs home_a_b1-rich_node_b2 | 91.3 m vs 93.3 m (2.1 %) |
| F2 | home_a_a1-rich_node_a2 vs home_a_a2-rich_node_a1 | 91.3 m vs 93.3 m (2.1 %) |
| F2 | home_a_b1-rich_node_b2 vs home_a_b2-rich_node_b1 | 93.3 m vs 91.3 m (2.1 %) |
| F2 | home_a_a2-rich_node_a1 vs home_a_b2-rich_node_b1 | 93.3 m vs 91.3 m (2.1 %) |
| F2 | third_node_a1-x_bridge_n vs third_node_a2-x_bridge_s | 170.2 m vs 173.9 m (2.1 %) |
| F2 | guilds_lodge_b1-x_bridge_s vs guilds_lodge_b2-x_bridge_n | 175.7 m vs 172.0 m (2.1 %) |
| F2 | stag_a2-guilds_lodge_a1 vs stag_b1-guilds_lodge_b2 | 161.1 m vs 164.6 m (2.1 %) |
| F2 | shrine_a1-peddler_b1 vs shrine_b1-peddler_a1 | 119.2 m vs 116.7 m (2.1 %) |
| F2 | shrine_b1-peddler_a1 vs shrine_b2-peddler_a2 | 116.7 m vs 119.2 m (2.1 %) |
| F2 | third_node_a2-x_bridge_s vs third_node_b2-x_bridge_n | 173.9 m vs 170.3 m (2.1 %) |
| F2 | guilds_lodge_a1-x_bridge_n vs guilds_lodge_a2-x_bridge_s | 171.9 m vs 175.6 m (2.1 %) |
| F2 | tower_r_a1-stag_a2 vs tower_r_b1-stag_b2 | 145.5 m vs 142.4 m (2.1 %) |
| F2 | stag_a1-guilds_lodge_a2 vs stag_b1-guilds_lodge_b2 | 161.2 m vs 164.6 m (2.1 %) |
| F2 | stag_b1-guilds_lodge_b2 vs stag_b2-guilds_lodge_b1 | 164.6 m vs 161.2 m (2.1 %) |
| F2 | guilds_lodge_a2-x_bridge_s vs guilds_lodge_b2-x_bridge_n | 175.6 m vs 172.0 m (2.1 %) |
| F2 | third_node_a1-peddler_a1 vs third_node_a2-peddler_a2 | 54.7 m vs 53.6 m (2.1 %) |
| F2 | tower_c_a2-post_w_a1 vs tower_c_b2-post_w_b1 | 61.5 m vs 60.2 m (2.1 %) |
| F2 | tower_c_a1-post_w_a2 vs tower_c_a2-post_w_a1 | 60.2 m vs 61.5 m (2.1 %) |
| F2 | tower_c_a2-post_w_a1 vs tower_c_b1-post_w_b2 | 61.5 m vs 60.2 m (2.1 %) |
| F2 | third_node_a1-ford_nest_a2 vs third_node_b1-ford_nest_a1 | 140.4 m vs 137.5 m (2.1 %) |
| F2 | third_node_a1-x_ford_n vs third_node_b1-x_ford_s | 140.4 m vs 137.5 m (2.1 %) |
| F2 | third_node_a1-ford_nest_a2 vs third_node_a2-ford_nest_a1 | 140.4 m vs 137.5 m (2.1 %) |
| F2 | third_node_a1-x_ford_n vs third_node_a2-x_ford_s | 140.4 m vs 137.5 m (2.1 %) |
| F2 | rich_node_b1-lairs_one_b2 vs rich_node_b2-lairs_one_b1 | 149.5 m vs 152.6 m (2.1 %) |
| F2 | rich_node_a1-lairs_one_a2 vs rich_node_a2-lairs_one_a1 | 152.6 m vs 149.5 m (2.1 %) |
| F2 | rich_node_a2-lairs_one_a1 vs rich_node_b2-lairs_one_b1 | 149.5 m vs 152.6 m (2.1 %) |
| F2 | rich_node_a1-lairs_one_a2 vs rich_node_b1-lairs_one_b2 | 152.6 m vs 149.5 m (2.1 %) |
| F2 | guilds_lodge_a2-x_ford_s vs guilds_lodge_b1-x_ford_s | 144.5 m vs 147.5 m (2.0 %) |
| F2 | guilds_den_a1-x_bridge_n vs guilds_den_b1-x_bridge_s | 180.2 m vs 183.9 m (2.0 %) |
| F2 | guilds_den_b1-x_bridge_s vs guilds_den_b2-x_bridge_n | 183.9 m vs 180.2 m (2.0 %) |
| F2 | shrine_a1-post_w_b2 vs shrine_b1-post_w_a2 | 135.2 m vs 132.5 m (2.0 %) |
| F2 | guilds_den_a1-x_bridge_n vs guilds_den_a2-x_bridge_s | 180.2 m vs 183.9 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 97 sources) 675.84 s.
- Map Lab v2 (map-production.md 2.5): layout quartermeet_s11, 4 seats, rules tempo standard, 0 fixable findings.
- Navmesh raster 28.10 s (1195 polygons, 495616 cells of 0.25 m), spot / mirror checks 25.07 s, 4656 paths 21.37 s.
- Map Quartermeet (seed 11), scene res://docs/tools/world_forge/out/quartermeet_s11/preview.tscn, sim mode off; level load + navmesh bake 6.6 s (1320 frames), lab 778.3 s. Spec: docs/design/map-production.md.
