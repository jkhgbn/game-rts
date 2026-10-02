# Map Lab: Quartermeet (seed 25) scorecard: world_forge_quartermeet_s25

2026-10-02 19:00 · lab v1.0 · 149.40 s · scanned 97 spots

## Result: **FAIL** · score **87 / 100**

1 FAIL · 5 WARN · 13 PASS · 2 info checks; findings: 4 FAIL, 691 WARN, 963 info

## Improve next
1. **Targets met (rules bands, per seat)** (FAIL): A1 south-west ally: ally 79.4 outside 60-72 (10 %) -> a designer moves the keeps or the river (R1 ally is not auto-fixed) _(from R1 16 / 24 clean (4 FAIL, 4 WARN))_
2. **Ally keeps: equal, close, on their bank** (WARN): A1 south-west: ally / nearest enemy 0.55 outside 0.33-0.50 (ally 79.4 m, enemy 144.4 m = 1.8x) -> aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally _(from A1 0 / 4 clean (0 FAIL, 4 WARN))_
3. **No navmesh islands** (WARN): island 6 at (-67.1, -78.5): 2.4 m² of ground-level navmesh cut off from the main area (y 0.50) -> a pocket closed by colliders: widen its gap or fill it (trees / rocks) (close or open the pocket) _(from N3 4 / 8 clean (0 FAIL, 4 WARN), 5 info)_
4. **Unit paths (NavigationServer): pairs match their twins** (WARN): tower_c_a1-post_w_a2 vs tower_c_b1-post_w_b2: 63.4 m vs 78.9 m (19.6 %) -> units walk tower_c_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 5350 / 6982 pairs within 2 % (0 FAIL, 674 WARN, 958 info))_
5. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest point: 34.6 m vs 36.1 m between seats (4.2 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 7 / 10 clean (0 FAIL, 3 WARN))_
6. **Main routes: narrowest corridor matches the twin** (WARN): keep_t0 -> keep_t4: narrowest 2.0 m at (10.8, 44.4) vs its twin's 5.8 m -> a collider narrows this route only on one side _(from C2 11 / 12 clean (0 FAIL, 2 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 1017 polygons, main area 29129 m² (94 % of the 176 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
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
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6982 / 6982 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 66 | 5350 / 6982 pairs within 2 % (0 FAIL, 674 WARN, 958 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 59 | 7 / 10 clean (0 FAIL, 3 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | **WARN** 35 | 0 / 4 clean (0 FAIL, 4 WARN) | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep, ally / nearest enemy 0.33-0.50 |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 7 / 7 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | **FAIL** 23 | 16 / 24 clean (4 FAIL, 4 WARN) | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
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
| FAIL | R1 | A1 south-west ally | ally 79.4 outside 60-72 (10 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| FAIL | R1 | A2 north-west ally | ally 79.4 outside 60-72 (10 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| FAIL | R1 | B1 north-east ally | ally 79.4 outside 60-72 (10 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| FAIL | R1 | B2 south-east ally | ally 79.4 outside 60-72 (10 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| WARN | N3 | island 6 at (-67.1, -78.5) | 2.4 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 7 at (67.2, -78.6) | 2.1 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 61 at (-67.2, 78.6) | 2.3 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 62 at (67.2, 78.6) | 2.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | F2 | tower_c_a1-post_w_a2 vs tower_c_b1-post_w_b2 | 63.4 m vs 78.9 m (19.6 %) | units walk tower_c_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-post_w_a2 vs tower_c_a2-post_w_a1 | 63.4 m vs 78.9 m (19.6 %) | units walk tower_c_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-post_w_b2 vs tower_c_b2-post_w_b1 | 78.9 m vs 63.4 m (19.6 %) | units walk tower_c_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-post_w_a1 vs tower_c_b2-post_w_b1 | 78.9 m vs 63.4 m (19.6 %) | units walk tower_c_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-cache_b_a2 vs tower_r_b2-cache_b_a1 | 48.1 m vs 59.3 m (18.9 %) | units walk tower_r_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_b_b1 vs tower_r_b2-cache_b_a1 | 48.2 m vs 59.3 m (18.7 %) | units walk tower_r_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-stag_b1 vs tower_c_b2-stag_b2 | 78.9 m vs 65.5 m (17.0 %) | units walk tower_c_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a1 vs tower_c_b1-stag_b1 | 65.5 m vs 78.9 m (17.0 %) | units walk tower_c_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_node_a1 vs keep_t3-rich_node_a2 | 58.6 m vs 70.0 m (16.2 %) | units walk keep_t3-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_node_a2 vs keep_t4-rich_node_b2 | 70.0 m vs 58.6 m (16.2 %) | units walk keep_t3-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_lane_w vs shrine_b1-x_lane_e | 38.6 m vs 45.9 m (15.8 %) | units walk shrine_b1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_lane_w vs shrine_a2-x_lane_w | 38.6 m vs 45.8 m (15.7 %) | units walk shrine_a2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-cache_b_b2 vs nat_node_b2-cache_b_a2 | 79.0 m vs 93.6 m (15.6 %) | units walk nat_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-cache_b_a1 vs nat_node_b2-cache_b_a2 | 79.0 m vs 93.6 m (15.6 %) | units walk nat_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-cache_b_b1 vs nat_node_b2-cache_b_a2 | 79.0 m vs 93.6 m (15.6 %) | units walk nat_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_node_a1 vs keep_t1-rich_node_b1 | 58.6 m vs 69.3 m (15.5 %) | units walk keep_t1-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-rich_node_b1 vs keep_t4-rich_node_b2 | 69.3 m vs 58.6 m (15.5 %) | units walk keep_t1-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-rich_node_b2 vs nat_node_b2-rich_node_b1 | 73.1 m vs 86.0 m (15.0 %) | units walk nat_node_b2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_a2 vs nat_node_b1-rich_node_b2 | 86.0 m vs 73.1 m (15.0 %) | units walk nat_node_a1-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_a2 vs nat_node_a2-rich_node_a1 | 86.0 m vs 73.1 m (15.0 %) | units walk nat_node_a1-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-rich_node_a1 vs nat_node_b2-rich_node_b1 | 73.1 m vs 86.0 m (15.0 %) | units walk nat_node_b2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b2-cache_b_a2 | 153.0 m vs 178.1 m (14.1 %) | units walk guilds_den_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-cache_b_a1 vs guilds_den_b2-cache_b_a2 | 153.0 m vs 178.1 m (14.1 %) | units walk guilds_den_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-stag_a1 vs tower_r_b2-stag_a2 | 153.6 m vs 177.9 m (13.7 %) | units walk tower_r_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-ford_nest_a2 vs tower_r_b2-ford_nest_a1 | 32.7 m vs 37.6 m (13.1 %) | units walk tower_r_b2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-x_ford_n vs tower_r_b2-x_ford_s | 32.7 m vs 37.6 m (13.1 %) | units walk tower_r_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-x_ford_n vs tower_r_b2-x_ford_s | 32.7 m vs 37.6 m (13.0 %) | units walk tower_r_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-ford_nest_a2 vs tower_r_b2-ford_nest_a1 | 32.7 m vs 37.6 m (13.0 %) | units walk tower_r_b2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a2 vs tower_c_b1-stag_b2 | 98.1 m vs 85.3 m (13.0 %) | units walk tower_c_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a2 vs tower_c_a2-stag_a1 | 98.1 m vs 85.3 m (13.0 %) | units walk tower_c_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-x_ford_s vs nat_node_a2-x_ford_n | 52.1 m vs 45.5 m (12.6 %) | units walk nat_node_a1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-ford_nest_a1 vs nat_node_a2-ford_nest_a2 | 52.1 m vs 45.5 m (12.6 %) | units walk nat_node_a1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-ford_nest_a1 vs nat_node_b2-ford_nest_a1 | 52.1 m vs 45.5 m (12.6 %) | units walk nat_node_a1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-x_ford_s vs nat_node_b2-x_ford_s | 52.1 m vs 45.5 m (12.6 %) | units walk nat_node_a1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-ford_nest_a1 vs nat_node_b1-ford_nest_a2 | 52.1 m vs 45.5 m (12.6 %) | units walk nat_node_a1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-x_ford_s vs nat_node_b1-x_ford_n | 52.1 m vs 45.5 m (12.6 %) | units walk nat_node_a1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_b_a1 vs third_node_b2-cache_b_a2 | 140.8 m vs 161.1 m (12.6 %) | units walk third_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_b_b2 vs third_node_b2-cache_b_a2 | 140.8 m vs 161.1 m (12.6 %) | units walk third_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_b1 vs third_node_b2-cache_b_a2 | 140.8 m vs 161.1 m (12.6 %) | units walk third_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-x_lane_w vs wallow_b2-x_lane_w | 106.4 m vs 121.6 m (12.5 %) | units walk wallow_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-x_lane_e vs wallow_b2-x_lane_w | 106.4 m vs 121.6 m (12.5 %) | units walk wallow_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-x_lane_e vs wallow_b2-x_lane_w | 106.4 m vs 121.6 m (12.5 %) | units walk wallow_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-nat_node_b2 vs home_a_b2-nat_node_b1 | 49.7 m vs 56.8 m (12.5 %) | units walk home_a_b2-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-nat_node_a2 vs home_a_b1-nat_node_b2 | 56.8 m vs 49.7 m (12.5 %) | units walk home_a_a1-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-nat_node_a1 vs home_a_b2-nat_node_b1 | 49.7 m vs 56.8 m (12.5 %) | units walk home_a_b2-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-nat_node_a2 vs home_a_a2-nat_node_a1 | 56.8 m vs 49.7 m (12.5 %) | units walk home_a_a1-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-crown vs rich_node_b2-crown | 73.3 m vs 64.1 m (12.5 %) | units walk rich_node_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-crown vs rich_node_b2-crown | 73.3 m vs 64.1 m (12.5 %) | units walk rich_node_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-crown vs rich_node_a2-crown | 64.1 m vs 73.3 m (12.5 %) | units walk rich_node_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-crown vs rich_node_b1-crown | 64.1 m vs 73.3 m (12.5 %) | units walk rich_node_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-wallow_b1 vs shrine_b1-wallow_a1 | 144.8 m vs 165.4 m (12.4 %) | units walk shrine_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a2 vs well_b1-post_w_b2 | 83.0 m vs 94.7 m (12.3 %) | units walk well_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_w_b2 vs well_b2-post_w_b1 | 94.7 m vs 83.0 m (12.3 %) | units walk well_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a2 vs well_a2-post_w_a1 | 83.0 m vs 94.7 m (12.3 %) | units walk well_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_w_a1 vs well_b2-post_w_b1 | 94.7 m vs 83.0 m (12.3 %) | units walk well_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-x_lane_w vs tower_r_b2-x_lane_w | 75.5 m vs 85.9 m (12.2 %) | units walk tower_r_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_bridge_s vs well_b1-x_bridge_n | 41.6 m vs 36.5 m (12.1 %) | units walk well_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_bridge_s vs well_a2-x_bridge_n | 41.6 m vs 36.5 m (12.1 %) | units walk well_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-x_bridge_n vs well_b2-x_bridge_s | 36.5 m vs 41.6 m (12.1 %) | units walk well_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-x_bridge_n vs well_b2-x_bridge_s | 36.5 m vs 41.6 m (12.1 %) | units walk well_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-x_lane_e vs tower_r_b2-x_lane_w | 75.5 m vs 85.9 m (12.1 %) | units walk tower_r_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-lairs_two_b1 vs nat_node_b1-lairs_two_a1 | 146.6 m vs 129.0 m (12.0 %) | units walk nat_node_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a2 vs tower_c_b2-stag_b1 | 98.1 m vs 86.3 m (12.0 %) | units walk tower_c_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-tower_c_b2 vs home_b_b1-tower_c_a1 | 115.4 m vs 101.6 m (11.9 %) | units walk home_b_a2-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b1 vs home_b_a2-tower_c_b2 | 101.6 m vs 115.4 m (11.9 %) | units walk home_b_a2-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_b1 vs nat_node_a2-rich_node_b2 | 100.1 m vs 88.2 m (11.9 %) | units walk nat_node_a1-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_b1 vs nat_node_b2-rich_node_a2 | 100.1 m vs 88.2 m (11.9 %) | units walk nat_node_a1-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_b1 vs nat_node_b1-rich_node_a1 | 100.1 m vs 88.2 m (11.9 %) | units walk nat_node_a1-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-lairs_two_a1 vs nat_node_b2-lairs_two_a2 | 129.0 m vs 146.4 m (11.8 %) | units walk nat_node_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-ford_nest_a1 vs home_b_b2-ford_nest_a2 | 114.3 m vs 100.8 m (11.8 %) | units walk home_b_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_ford_s vs home_b_b2-x_ford_n | 114.3 m vs 100.8 m (11.8 %) | units walk home_b_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_ford_n vs home_b_a2-x_ford_s | 100.8 m vs 114.3 m (11.8 %) | units walk home_b_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-ford_nest_a2 vs home_b_a2-ford_nest_a1 | 100.8 m vs 114.3 m (11.8 %) | units walk home_b_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_a_b2 vs well_b2-cache_a_a2 | 148.5 m vs 168.3 m (11.8 %) | units walk well_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-guilds_lodge_b2 vs guilds_den_b2-guilds_lodge_a2 | 229.6 m vs 260.1 m (11.7 %) | units walk guilds_den_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-third_node_a1 vs nat_node_b2-third_node_a2 | 143.3 m vs 162.2 m (11.6 %) | units walk nat_node_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-third_node_b1 vs nat_node_b1-third_node_a1 | 162.2 m vs 143.3 m (11.6 %) | units walk nat_node_a1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-third_node_b2 vs nat_node_b2-third_node_a2 | 143.3 m vs 162.2 m (11.6 %) | units walk nat_node_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-third_node_b1 vs nat_node_a2-third_node_b2 | 162.2 m vs 143.3 m (11.6 %) | units walk nat_node_a1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_b_b1 vs guilds_den_b2-cache_b_a2 | 157.6 m vs 178.1 m (11.5 %) | units walk guilds_den_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-guilds_lodge_b1 vs nat_node_a2-guilds_lodge_b2 | 175.8 m vs 155.6 m (11.5 %) | units walk nat_node_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-guilds_lodge_b1 vs nat_node_b1-guilds_lodge_a1 | 175.8 m vs 155.6 m (11.5 %) | units walk nat_node_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_two_b1 vs tower_r_b1-lairs_two_a1 | 182.9 m vs 161.9 m (11.5 %) | units walk tower_r_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_two_b1 vs tower_r_a2-lairs_two_b2 | 182.9 m vs 162.0 m (11.5 %) | units walk tower_r_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-cache_b_b2 vs home_b_b1-cache_b_a1 | 128.7 m vs 114.0 m (11.4 %) | units walk home_b_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-guilds_lodge_a1 vs nat_node_b2-guilds_lodge_a2 | 155.6 m vs 175.6 m (11.4 %) | units walk nat_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-guilds_lodge_b2 vs nat_node_b2-guilds_lodge_a2 | 155.6 m vs 175.6 m (11.4 %) | units walk nat_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_b_b1 vs home_b_a2-cache_b_b2 | 114.0 m vs 128.7 m (11.4 %) | units walk home_b_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_a_b1 vs tower_r_b1-cache_a_a1 | 164.1 m vs 145.5 m (11.3 %) | units walk tower_r_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_a_b1 vs tower_r_a2-cache_a_b2 | 164.1 m vs 145.5 m (11.3 %) | units walk tower_r_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_a1 vs home_a_a2-wallow_a2 | 30.2 m vs 26.8 m (11.2 %) | units walk home_a_a1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-wallow_a2 vs home_a_b2-wallow_b2 | 26.8 m vs 30.2 m (11.2 %) | units walk home_a_b2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_a1 vs home_a_b1-wallow_b1 | 30.2 m vs 26.8 m (11.2 %) | units walk home_a_a1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-wallow_b1 vs home_a_b2-wallow_b2 | 26.8 m vs 30.2 m (11.2 %) | units walk home_a_b2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-cache_b_a1 vs home_b_b2-cache_b_a2 | 114.0 m vs 128.3 m (11.2 %) | units walk home_b_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_b_b1 vs home_b_b2-cache_b_a2 | 114.0 m vs 128.3 m (11.1 %) | units walk home_b_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-stag_a2 vs tower_c_b2-stag_b2 | 73.7 m vs 65.5 m (11.1 %) | units walk tower_c_a2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a1 vs tower_c_a2-stag_a2 | 65.5 m vs 73.7 m (11.1 %) | units walk tower_c_a2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_b_b2 vs guilds_lodge_b2-cache_b_a2 | 150.1 m vs 168.7 m (11.0 %) | units walk guilds_lodge_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_b_a1 vs guilds_lodge_b2-cache_b_a2 | 150.1 m vs 168.7 m (11.0 %) | units walk guilds_lodge_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_b2-cache_b_a2 | 150.1 m vs 168.7 m (11.0 %) | units walk guilds_lodge_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-x_lane_e vs keep_t1-x_lane_w | 105.9 m vs 94.3 m (11.0 %) | units walk keep_t3-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-tower_c_b1 vs tower_r_b2-tower_c_a1 | 70.1 m vs 78.7 m (11.0 %) | units walk tower_r_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-tower_c_a2 vs tower_r_b2-tower_c_a1 | 70.1 m vs 78.7 m (11.0 %) | units walk tower_r_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b2 vs tower_r_b2-cache_b_a1 | 52.8 m vs 59.3 m (11.0 %) | units walk tower_r_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-x_lane_e vs keep_t3-x_lane_e | 94.3 m vs 105.9 m (11.0 %) | units walk keep_t3-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-x_ford_n vs peddler_a2-x_ford_s | 85.8 m vs 96.3 m (10.9 %) | units walk peddler_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-stag_b1 vs nat_node_b1-stag_a1 | 132.0 m vs 117.6 m (10.9 %) | units walk nat_node_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-x_ford_s vs peddler_b2-x_ford_n | 96.3 m vs 85.8 m (10.9 %) | units walk peddler_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a1 vs tower_r_b1-post_w_b1 | 94.1 m vs 83.8 m (10.9 %) | units walk tower_r_a1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a1 vs tower_r_a2-post_w_a2 | 94.1 m vs 83.8 m (10.9 %) | units walk tower_r_a1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_w_b1 vs tower_r_b2-post_w_b2 | 83.8 m vs 94.1 m (10.9 %) | units walk tower_r_b2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_a2 vs tower_r_b2-post_w_b2 | 83.8 m vs 94.1 m (10.9 %) | units walk tower_r_b2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_a2-guilds_lodge_b2 | 257.6 m vs 229.6 m (10.8 %) | units walk guilds_den_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b2 vs home_a_b1-inn_a2 | 117.1 m vs 104.4 m (10.8 %) | units walk home_a_a1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-inn_b1 vs home_b_a2-inn_b2 | 113.7 m vs 127.5 m (10.8 %) | units walk home_b_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b2 vs home_a_a2-inn_b1 | 117.1 m vs 104.5 m (10.8 %) | units walk home_a_a1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-inn_b2 vs home_b_b1-inn_a1 | 127.5 m vs 113.7 m (10.8 %) | units walk home_b_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_b_b1 vs keep_t1-cache_b_a1 | 134.2 m vs 119.8 m (10.8 %) | units walk keep_t0-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b2 vs home_a_b2-inn_a1 | 117.1 m vs 104.5 m (10.8 %) | units walk home_a_a1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-stag_a1 vs nat_node_b2-stag_a2 | 117.6 m vs 131.8 m (10.8 %) | units walk nat_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-x_ford_s vs peddler_b1-x_ford_s | 96.3 m vs 85.9 m (10.7 %) | units walk peddler_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-tower_r_b1 vs nat_node_b1-tower_r_a1 | 111.7 m vs 99.7 m (10.7 %) | units walk nat_node_a1-tower_r_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_w_b2 vs tower_r_b2-post_w_b1 | 114.4 m vs 102.2 m (10.7 %) | units walk tower_r_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a2 vs tower_r_b1-post_w_b2 | 102.2 m vs 114.4 m (10.7 %) | units walk tower_r_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_a1 vs tower_r_b2-post_w_b1 | 114.4 m vs 102.2 m (10.7 %) | units walk tower_r_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a2 vs tower_r_a2-post_w_a1 | 102.2 m vs 114.4 m (10.7 %) | units walk tower_r_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-tower_r_b1 vs nat_node_a2-tower_r_b2 | 111.7 m vs 99.7 m (10.7 %) | units walk nat_node_a1-tower_r_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-tower_r_b1 vs nat_node_b2-tower_r_a2 | 111.7 m vs 99.7 m (10.7 %) | units walk nat_node_a1-tower_r_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-third_node_b1 vs third_node_b2-third_node_a2 | 229.7 m vs 205.1 m (10.7 %) | units walk third_node_a1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_ford_s vs home_b_b1-x_ford_s | 114.3 m vs 102.1 m (10.7 %) | units walk home_b_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-ford_nest_a1 vs home_b_b1-ford_nest_a1 | 114.3 m vs 102.1 m (10.7 %) | units walk home_b_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_a_b1 vs well_b1-cache_a_a2 | 85.7 m vs 95.9 m (10.7 %) | units walk well_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-cache_b_a1 vs keep_t4-cache_b_a2 | 119.8 m vs 134.0 m (10.7 %) | units walk keep_t4-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | x_bridge_n-x_ford_s vs x_bridge_s-x_ford_n | 123.1 m vs 110.0 m (10.6 %) | units walk x_bridge_n-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-guilds_lodge_a1 vs third_node_b2-guilds_lodge_a2 | 217.4 m vs 243.1 m (10.6 %) | units walk third_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-guilds_lodge_b2 vs third_node_b2-guilds_lodge_a2 | 217.4 m vs 243.1 m (10.6 %) | units walk third_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-nat_node_b2 vs home_b_b1-nat_node_a1 | 130.3 m vs 116.5 m (10.6 %) | units walk home_b_a2-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-nat_node_b1 vs home_b_a2-nat_node_b2 | 116.6 m vs 130.3 m (10.5 %) | units walk home_b_a2-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_lodge_b1 vs third_node_b1-guilds_lodge_a1 | 243.0 m vs 217.4 m (10.5 %) | units walk third_node_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_lodge_b1 vs third_node_a2-guilds_lodge_b2 | 243.0 m vs 217.4 m (10.5 %) | units walk third_node_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-wallow_a1 vs shrine_b2-wallow_a2 | 165.4 m vs 148.0 m (10.5 %) | units walk shrine_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_bridge_n vs shrine_b1-x_bridge_s | 92.0 m vs 102.7 m (10.5 %) | units walk shrine_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_one_a2 vs home_b_b1-lairs_one_b2 | 133.9 m vs 119.8 m (10.5 %) | units walk home_b_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_one_a1 vs home_b_b2-lairs_one_b1 | 119.8 m vs 133.9 m (10.5 %) | units walk home_b_b2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_one_a2 vs home_b_a2-lairs_one_a1 | 133.9 m vs 119.8 m (10.5 %) | units walk home_b_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_one_b2 vs home_b_b2-lairs_one_b1 | 119.8 m vs 133.9 m (10.5 %) | units walk home_b_b2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_bridge_n vs shrine_a2-x_bridge_s | 92.0 m vs 102.7 m (10.4 %) | units walk shrine_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_a2 vs home_b_b1-post_w_b2 | 55.3 m vs 61.8 m (10.4 %) | units walk home_b_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-post_w_b2 vs home_b_b2-post_w_b1 | 61.8 m vs 55.3 m (10.4 %) | units walk home_b_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-post_w_a1 vs home_b_b2-post_w_b1 | 61.8 m vs 55.3 m (10.4 %) | units walk home_b_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_a2 vs home_b_a2-post_w_a1 | 55.3 m vs 61.8 m (10.4 %) | units walk home_b_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-guilds_den_b1 vs guilds_den_b2-guilds_den_a2 | 254.5 m vs 228.1 m (10.4 %) | units walk guilds_den_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-tower_c_a1 vs tower_r_b2-tower_c_a2 | 87.6 m vs 97.6 m (10.3 %) | units walk tower_r_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-tower_c_b2 vs tower_r_b2-tower_c_a2 | 87.6 m vs 97.6 m (10.2 %) | units walk tower_r_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-nat_node_b1 vs keep_t4-nat_node_a1 | 116.2 m vs 129.4 m (10.2 %) | units walk keep_t4-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_a2 vs shrine_a2-lairs_one_a1 | 102.7 m vs 92.3 m (10.1 %) | units walk shrine_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_a2 vs shrine_b1-lairs_one_b2 | 102.7 m vs 92.3 m (10.1 %) | units walk shrine_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-x_bridge_s vs shrine_b2-x_bridge_n | 102.7 m vs 92.3 m (10.1 %) | units walk shrine_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-inn_b1 vs wallow_b2-inn_a2 | 131.6 m vs 146.4 m (10.1 %) | units walk wallow_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-inn_a1 vs wallow_b2-inn_a2 | 131.6 m vs 146.4 m (10.1 %) | units walk wallow_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-inn_b2 vs wallow_b2-inn_a2 | 131.6 m vs 146.4 m (10.1 %) | units walk wallow_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-tower_c_b1 vs keep_t1-tower_c_a2 | 118.9 m vs 106.9 m (10.1 %) | units walk keep_t3-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-ford_nest_a1 vs tower_r_b2-ford_nest_a1 | 33.8 m vs 37.6 m (10.1 %) | units walk tower_r_b2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_ford_s vs tower_r_b2-x_ford_s | 33.8 m vs 37.6 m (10.1 %) | units walk tower_r_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_bridge_s vs shrine_b2-x_bridge_n | 102.7 m vs 92.3 m (10.1 %) | units walk shrine_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-x_ford_n vs keep_t3-x_ford_s | 104.6 m vs 116.3 m (10.0 %) | units walk keep_t3-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_nest_a2 vs keep_t3-ford_nest_a1 | 104.6 m vs 116.3 m (10.0 %) | units walk keep_t3-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-x_ford_s vs keep_t4-x_ford_n | 116.3 m vs 104.6 m (10.0 %) | units walk keep_t3-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_nest_a1 vs keep_t4-ford_nest_a2 | 116.3 m vs 104.6 m (10.0 %) | units walk keep_t3-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b2 vs keep_t3-tower_c_b1 | 107.0 m vs 118.9 m (10.0 %) | units walk keep_t3-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_w_b2 vs wallow_b1-post_w_a1 | 196.1 m vs 176.7 m (9.9 %) | units walk wallow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-shrine_b2 vs home_b_b1-shrine_a1 | 140.7 m vs 127.0 m (9.8 %) | units walk home_b_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_w_b2 vs wallow_b2-post_w_a2 | 196.1 m vs 176.9 m (9.8 %) | units walk wallow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b_b1 vs wallow_a2-cache_b_b2 | 146.1 m vs 131.9 m (9.8 %) | units walk wallow_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b_b1 vs wallow_b1-cache_b_a1 | 146.1 m vs 131.9 m (9.8 %) | units walk wallow_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b1 vs home_b_a2-shrine_b2 | 127.0 m vs 140.7 m (9.8 %) | units walk home_b_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_two_a1 vs tower_r_b2-lairs_two_a2 | 161.9 m vs 179.3 m (9.7 %) | units walk tower_r_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_two_b2 vs tower_r_b2-lairs_two_a2 | 162.0 m vs 179.3 m (9.7 %) | units walk tower_r_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_a2 vs shrine_b2-lairs_one_b1 | 102.7 m vs 92.8 m (9.6 %) | units walk shrine_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-cache_b_b2 vs wallow_b2-cache_b_a2 | 131.9 m vs 145.9 m (9.6 %) | units walk wallow_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-cache_b_a1 vs wallow_b2-cache_b_a2 | 131.9 m vs 145.9 m (9.6 %) | units walk wallow_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b2 vs home_b_b2-well_a1 | 100.1 m vs 110.7 m (9.6 %) | units walk home_b_b2-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-guilds_lodge_b1 vs guilds_lodge_b2-guilds_lodge_a2 | 250.5 m vs 226.7 m (9.5 %) | units walk guilds_lodge_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-tower_c_b2 vs keep_t1-tower_c_a1 | 118.6 m vs 107.4 m (9.5 %) | units walk keep_t3-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b1 vs keep_t3-tower_c_b2 | 107.4 m vs 118.6 m (9.5 %) | units walk keep_t3-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_nest_a1 vs keep_t1-ford_nest_a1 | 116.3 m vs 105.4 m (9.4 %) | units walk keep_t3-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-x_ford_s vs keep_t1-x_ford_s | 116.3 m vs 105.4 m (9.4 %) | units walk keep_t3-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-x_lane_w vs home_b_b2-x_lane_w | 88.5 m vs 97.7 m (9.4 %) | units walk home_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_lane_e vs home_b_b2-x_lane_w | 88.5 m vs 97.7 m (9.4 %) | units walk home_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_lane_e vs home_b_b2-x_lane_w | 88.6 m vs 97.7 m (9.3 %) | units walk home_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-cache_b_a1 vs tower_r_b2-cache_b_a2 | 102.6 m vs 113.1 m (9.3 %) | units walk tower_r_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-well_b1 vs home_b_b2-well_a1 | 100.4 m vs 110.7 m (9.3 %) | units walk home_b_b2-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-well_a2 vs home_b_b2-well_a1 | 100.4 m vs 110.7 m (9.3 %) | units walk home_b_b2-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_b_b2 vs tower_r_b2-cache_b_a2 | 102.7 m vs 113.1 m (9.3 %) | units walk tower_r_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-guilds_den_b2 vs nat_node_b2-guilds_den_a2 | 154.0 m vs 169.7 m (9.2 %) | units walk nat_node_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-guilds_den_a1 vs nat_node_b2-guilds_den_a2 | 154.0 m vs 169.7 m (9.2 %) | units walk nat_node_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-guilds_den_b1 vs nat_node_b2-guilds_den_a2 | 154.1 m vs 169.7 m (9.2 %) | units walk nat_node_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-x_lane_w vs third_node_b2-x_lane_w | 115.3 m vs 126.9 m (9.1 %) | units walk third_node_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-x_lane_e vs third_node_b2-x_lane_w | 115.3 m vs 126.9 m (9.1 %) | units walk third_node_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-ford_nest_a2 vs tower_r_b2-ford_nest_a2 | 113.5 m vs 124.9 m (9.1 %) | units walk tower_r_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_ford_n vs tower_r_b2-x_ford_n | 113.5 m vs 124.9 m (9.1 %) | units walk tower_r_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-stag_b2 vs nat_node_b1-stag_a1 | 129.4 m vs 117.6 m (9.1 %) | units walk nat_node_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_lane_e vs third_node_b2-x_lane_w | 115.3 m vs 126.9 m (9.1 %) | units walk third_node_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-ford_nest_a1 vs tower_r_b2-ford_nest_a2 | 113.5 m vs 124.9 m (9.1 %) | units walk tower_r_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-x_ford_s vs tower_r_b2-x_ford_n | 113.5 m vs 124.9 m (9.1 %) | units walk tower_r_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-inn_a1 vs tower_r_b2-inn_a2 | 100.9 m vs 110.9 m (9.1 %) | units walk tower_r_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_a2 vs cache_a_b1-lairs_one_b2 | 157.9 m vs 143.6 m (9.1 %) | units walk cache_a_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_a2 vs cache_a_a2-lairs_one_a1 | 157.9 m vs 143.6 m (9.1 %) | units walk cache_a_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-wallow_a1 vs home_b_b2-wallow_b1 | 96.5 m vs 87.8 m (9.0 %) | units walk home_b_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_a2 vs home_b_a2-wallow_a1 | 87.8 m vs 96.5 m (9.0 %) | units walk home_b_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-wallow_b2 vs home_b_b2-wallow_b1 | 96.5 m vs 87.8 m (9.0 %) | units walk home_b_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_a2 vs home_b_b1-wallow_b2 | 87.8 m vs 96.5 m (9.0 %) | units walk home_b_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_one_a1 vs cache_a_b2-lairs_one_b1 | 143.6 m vs 157.9 m (9.0 %) | units walk cache_a_b2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-lairs_one_b2 vs cache_a_b2-lairs_one_b1 | 143.6 m vs 157.9 m (9.0 %) | units walk cache_a_b2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-well_b1 vs rich_node_b1-well_a2 | 54.3 m vs 59.7 m (9.0 %) | units walk rich_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-inn_b2 vs tower_r_b2-inn_a2 | 100.9 m vs 110.9 m (9.0 %) | units walk tower_r_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-x_lane_w vs guilds_den_b2-x_lane_w | 127.5 m vs 140.1 m (9.0 %) | units walk guilds_den_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-x_lane_e vs guilds_den_b2-x_lane_w | 127.5 m vs 140.1 m (9.0 %) | units walk guilds_den_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b1 vs home_b_a2-well_b2 | 136.6 m vs 150.1 m (9.0 %) | units walk home_b_a2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b1 vs home_b_b1-well_a1 | 136.6 m vs 150.1 m (9.0 %) | units walk home_b_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-guilds_den_a1 vs third_node_b2-guilds_den_a2 | 215.8 m vs 237.2 m (9.0 %) | units walk third_node_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-guilds_den_b2 vs third_node_b2-guilds_den_a2 | 215.8 m vs 237.2 m (9.0 %) | units walk third_node_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_w_b1 vs wallow_a2-post_w_b2 | 178.4 m vs 196.1 m (9.0 %) | units walk wallow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-ford_nest_a1 vs tower_r_b2-ford_nest_a2 | 113.6 m vs 124.9 m (9.0 %) | units walk tower_r_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-x_ford_s vs tower_r_b2-x_ford_n | 113.6 m vs 124.9 m (9.0 %) | units walk tower_r_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_a2 vs cache_a_b1-cache_b_b2 | 107.6 m vs 97.9 m (9.0 %) | units walk cache_a_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_a2 vs cache_a_a2-cache_b_a1 | 107.6 m vs 97.9 m (9.0 %) | units walk cache_a_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-cache_b_b2 vs cache_a_b2-cache_b_b1 | 97.9 m vs 107.6 m (9.0 %) | units walk cache_a_b2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-cache_b_a1 vs cache_a_b2-cache_b_b1 | 97.9 m vs 107.6 m (9.0 %) | units walk cache_a_b2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-well_b2 vs home_b_b2-well_a2 | 150.1 m vs 136.6 m (9.0 %) | units walk home_b_a2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-well_a1 vs home_b_b2-well_a2 | 150.1 m vs 136.6 m (9.0 %) | units walk home_b_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_den_b1 vs third_node_a2-guilds_den_b2 | 237.1 m vs 215.8 m (8.9 %) | units walk third_node_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_den_b1 vs third_node_b1-guilds_den_a1 | 237.1 m vs 215.8 m (8.9 %) | units walk third_node_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b2 vs tower_r_b1-cache_b_a2 | 52.8 m vs 48.1 m (8.9 %) | units walk tower_r_a1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-peddler_b2 vs home_b_b1-peddler_a1 | 155.1 m vs 141.4 m (8.9 %) | units walk home_b_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b1 vs home_b_a2-peddler_b2 | 141.4 m vs 155.1 m (8.8 %) | units walk home_b_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-cache_a_a1 vs tower_r_b2-cache_a_a2 | 145.5 m vs 159.5 m (8.8 %) | units walk tower_r_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_a_b2 vs tower_r_b2-cache_a_a2 | 145.5 m vs 159.5 m (8.8 %) | units walk tower_r_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-x_lane_e vs shrine_b2-x_lane_e | 45.9 m vs 41.9 m (8.8 %) | units walk shrine_b1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-peddler_a2 vs keep_t4-peddler_a1 | 140.7 m vs 154.2 m (8.8 %) | units walk keep_t4-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-well_a2 vs rich_node_b2-well_a1 | 59.7 m vs 54.5 m (8.8 %) | units walk rich_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b1 vs keep_t4-peddler_a1 | 140.7 m vs 154.2 m (8.8 %) | units walk keep_t4-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b2 vs tower_r_a2-cache_b_b1 | 52.8 m vs 48.2 m (8.7 %) | units walk tower_r_a1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_a1 vs home_a_b1-inn_b1 | 47.4 m vs 51.9 m (8.7 %) | units walk home_a_b1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-inn_b1 vs home_a_b2-inn_b2 | 51.9 m vs 47.4 m (8.7 %) | units walk home_a_b1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-inn_b1 vs keep_t3-inn_b2 | 119.5 m vs 130.7 m (8.6 %) | units walk keep_t3-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-peddler_a1 vs inn_b1-peddler_b1 | 34.5 m vs 37.8 m (8.6 %) | units walk inn_b1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-peddler_a1 vs inn_a2-peddler_a2 | 34.5 m vs 37.8 m (8.6 %) | units walk inn_a2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-peddler_b1 vs inn_b2-peddler_b2 | 37.8 m vs 34.5 m (8.6 %) | units walk inn_b1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-peddler_a2 vs inn_b2-peddler_b2 | 37.8 m vs 34.5 m (8.6 %) | units walk inn_a2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-inn_b2 vs keep_t1-inn_a1 | 130.7 m vs 119.5 m (8.6 %) | units walk keep_t3-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_lane_w vs shrine_b2-x_lane_e | 45.8 m vs 41.9 m (8.6 %) | units walk shrine_a2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-x_lane_e vs guilds_lodge_b2-x_lane_w | 124.6 m vs 136.3 m (8.6 %) | units walk guilds_lodge_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-x_lane_w vs guilds_lodge_b2-x_lane_w | 124.6 m vs 136.3 m (8.6 %) | units walk guilds_lodge_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_e vs guilds_lodge_b2-x_lane_w | 124.6 m vs 136.3 m (8.5 %) | units walk guilds_lodge_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-peddler_b2 vs wallow_b2-peddler_a2 | 159.3 m vs 174.1 m (8.5 %) | units walk wallow_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-peddler_a1 vs wallow_b2-peddler_a2 | 159.3 m vs 174.1 m (8.5 %) | units walk wallow_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b1 vs wallow_b2-peddler_a2 | 159.3 m vs 174.1 m (8.5 %) | units walk wallow_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b2 vs keep_t3-well_b1 | 117.7 m vs 107.8 m (8.4 %) | units walk keep_t0-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b2 vs keep_t1-well_a2 | 117.7 m vs 107.8 m (8.4 %) | units walk keep_t0-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-nat_node_b2 vs keep_t1-nat_node_a1 | 133.6 m vs 122.3 m (8.4 %) | units walk keep_t3-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-well_a2 vs keep_t4-well_a1 | 107.8 m vs 117.7 m (8.4 %) | units walk keep_t4-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-well_b1 vs keep_t4-well_a1 | 107.8 m vs 117.7 m (8.4 %) | units walk keep_t4-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_b1 vs keep_t3-nat_node_b2 | 122.3 m vs 133.6 m (8.4 %) | units walk keep_t3-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-lairs_two_b2 vs nat_node_b1-lairs_two_a1 | 140.8 m vs 129.0 m (8.4 %) | units walk nat_node_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-crown vs keep_t1-crown | 88.8 m vs 81.4 m (8.4 %) | units walk keep_t3-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_ford_n vs well_b2-x_ford_n | 97.0 m vs 105.9 m (8.4 %) | units walk well_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-ford_nest_a2 vs well_b2-ford_nest_a2 | 97.0 m vs 105.9 m (8.4 %) | units walk well_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-crown vs keep_t3-crown | 81.4 m vs 88.8 m (8.3 %) | units walk keep_t3-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-cache_b_b2 vs keep_t1-cache_b_a1 | 130.7 m vs 119.8 m (8.3 %) | units walk keep_t3-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-home_b_b1 vs home_b_b2-home_b_a2 | 151.6 m vs 165.3 m (8.3 %) | units walk home_b_b2-home_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-ford_nest_a1 vs well_b2-ford_nest_a2 | 97.1 m vs 105.9 m (8.3 %) | units walk well_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-x_ford_s vs well_b2-x_ford_n | 97.1 m vs 105.9 m (8.3 %) | units walk well_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_b_b2 vs post_s_a2-cache_b_b1 | 60.4 m vs 65.9 m (8.3 %) | units walk post_s_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-inn_a2 vs rich_node_b2-inn_b2 | 36.1 m vs 33.1 m (8.3 %) | units walk rich_node_a2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-inn_b1 vs rich_node_b2-inn_b2 | 36.1 m vs 33.1 m (8.3 %) | units walk rich_node_b1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-inn_a1 vs rich_node_a2-inn_a2 | 33.1 m vs 36.1 m (8.3 %) | units walk rich_node_a2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-inn_a1 vs rich_node_b1-inn_b1 | 33.1 m vs 36.1 m (8.3 %) | units walk rich_node_b1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-well_b2 vs rich_node_b1-well_a2 | 54.8 m vs 59.7 m (8.3 %) | units walk rich_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-home_a_a2 vs keep_t4-home_a_a1 | 150.3 m vs 163.8 m (8.3 %) | units walk keep_t4-home_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_bridge_s vs home_a_a2-x_bridge_n | 90.7 m vs 83.2 m (8.3 %) | units walk home_a_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-x_bridge_n vs home_a_b2-x_bridge_s | 83.2 m vs 90.7 m (8.3 %) | units walk home_a_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_bridge_s vs home_a_b1-x_bridge_n | 90.7 m vs 83.2 m (8.3 %) | units walk home_a_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-x_bridge_n vs home_a_b2-x_bridge_s | 83.2 m vs 90.7 m (8.3 %) | units walk home_a_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_w vs lairs_one_b1-x_lane_e | 104.1 m vs 95.5 m (8.3 %) | units walk lairs_one_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_w vs lairs_one_a2-x_lane_w | 104.1 m vs 95.5 m (8.3 %) | units walk lairs_one_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_a_b1 vs keep_t4-home_a_a1 | 150.3 m vs 163.8 m (8.3 %) | units walk keep_t4-home_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-x_ford_s vs post_s_b2-x_ford_n | 125.3 m vs 136.6 m (8.2 %) | units walk post_s_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-lairs_two_b2 vs well_b2-lairs_two_a2 | 159.2 m vs 173.5 m (8.2 %) | units walk well_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-x_ford_s vs well_b2-x_ford_n | 97.2 m vs 105.9 m (8.2 %) | units walk well_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-ford_nest_a1 vs well_b2-ford_nest_a2 | 97.2 m vs 105.9 m (8.2 %) | units walk well_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_den_b1 vs home_b_b1-guilds_den_a1 | 189.1 m vs 206.0 m (8.2 %) | units walk home_b_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_den_b1 vs home_b_a2-guilds_den_b2 | 189.1 m vs 206.0 m (8.2 %) | units walk home_b_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-lairs_two_a1 vs well_b2-lairs_two_a2 | 159.3 m vs 173.5 m (8.2 %) | units walk well_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-wallow_b2 vs shrine_b1-wallow_a1 | 151.9 m vs 165.4 m (8.2 %) | units walk shrine_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-x_ford_s vs post_s_b2-x_ford_n | 125.4 m vs 136.6 m (8.2 %) | units walk post_s_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-inn_b1 vs tower_r_b2-inn_a1 | 65.0 m vs 70.7 m (8.1 %) | units walk tower_r_b2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_b_b2 vs post_s_b2-cache_b_a1 | 60.4 m vs 65.8 m (8.1 %) | units walk post_s_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-shrine_b1 vs keep_t4-shrine_a1 | 128.5 m vs 139.8 m (8.1 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_w vs lairs_one_b2-x_lane_e | 104.1 m vs 95.7 m (8.1 %) | units walk lairs_one_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-peddler_a1 vs post_w_b2-peddler_a2 | 148.7 m vs 161.7 m (8.1 %) | units walk post_w_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-peddler_b1 vs post_w_b1-peddler_a1 | 161.7 m vs 148.7 m (8.1 %) | units walk post_w_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-crown vs keep_t4-crown | 81.4 m vs 88.5 m (8.0 %) | units walk keep_t4-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-inn_a2 vs tower_r_b2-inn_a1 | 65.0 m vs 70.7 m (8.0 %) | units walk tower_r_b2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_b_b2 vs post_s_b1-cache_b_a2 | 60.4 m vs 65.7 m (8.0 %) | units walk post_s_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-crown vs keep_t4-crown | 81.4 m vs 88.5 m (8.0 %) | units walk keep_t4-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-tower_c_a1 vs third_node_b2-tower_c_a2 | 128.4 m vs 139.5 m (8.0 %) | units walk third_node_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-tower_c_b2 vs third_node_b2-tower_c_a2 | 128.4 m vs 139.5 m (8.0 %) | units walk third_node_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-post_w_b2 vs home_b_b1-post_w_a1 | 172.6 m vs 158.9 m (8.0 %) | units walk home_b_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_c_b1 vs third_node_b2-tower_c_a2 | 128.4 m vs 139.5 m (8.0 %) | units walk third_node_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-ford_nest_a2 vs rich_node_b1-ford_nest_a1 | 95.8 m vs 104.1 m (8.0 %) | units walk rich_node_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-x_ford_n vs rich_node_b1-x_ford_s | 95.8 m vs 104.1 m (8.0 %) | units walk rich_node_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_b1 vs home_b_a2-post_w_b2 | 158.9 m vs 172.6 m (7.9 %) | units walk home_b_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-tower_c_a1 vs home_b_b2-tower_c_a2 | 101.6 m vs 110.3 m (7.9 %) | units walk home_b_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b1 vs home_b_b2-tower_c_a2 | 101.6 m vs 110.3 m (7.9 %) | units walk home_b_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-x_ford_n vs rich_node_a2-x_ford_s | 95.8 m vs 104.0 m (7.9 %) | units walk rich_node_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-ford_nest_a2 vs rich_node_a2-ford_nest_a1 | 95.8 m vs 104.0 m (7.9 %) | units walk rich_node_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-x_ford_s vs rich_node_b2-x_ford_n | 104.1 m vs 95.9 m (7.9 %) | units walk rich_node_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-ford_nest_a1 vs rich_node_b2-ford_nest_a2 | 104.1 m vs 95.9 m (7.9 %) | units walk rich_node_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_two_b1 vs cache_a_b1-lairs_two_a1 | 200.5 m vs 184.7 m (7.9 %) | units walk cache_a_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-shrine_b2 vs keep_t1-shrine_a1 | 144.0 m vs 132.7 m (7.8 %) | units walk keep_t3-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b1 vs keep_t3-shrine_b2 | 132.8 m vs 144.0 m (7.8 %) | units walk keep_t3-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-guilds_lodge_b2 vs guilds_den_b1-guilds_lodge_a1 | 229.6 m vs 249.0 m (7.8 %) | units walk guilds_den_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-ford_nest_a1 vs rich_node_b2-ford_nest_a2 | 104.0 m vs 95.9 m (7.8 %) | units walk rich_node_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-x_ford_s vs rich_node_b2-x_ford_n | 104.0 m vs 95.9 m (7.8 %) | units walk rich_node_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_b_b2 vs third_node_b2-cache_b_b1 | 126.5 m vs 116.7 m (7.8 %) | units walk third_node_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_a2 vs third_node_b1-cache_b_b2 | 116.7 m vs 126.5 m (7.8 %) | units walk third_node_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-lairs_two_a1 vs cache_a_b2-lairs_two_a2 | 184.7 m vs 200.3 m (7.8 %) | units walk cache_a_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_lane_w vs shrine_b2-x_lane_e | 38.6 m vs 41.9 m (7.7 %) | units walk shrine_b2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-tower_r_a2 vs rich_node_b1-tower_r_b2 | 119.8 m vs 129.8 m (7.7 %) | units walk rich_node_b1-tower_r_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-tower_r_b2 vs rich_node_b2-tower_r_b1 | 129.8 m vs 119.8 m (7.7 %) | units walk rich_node_b1-tower_r_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_b1 vs tower_r_b2-stag_a2 | 164.2 m vs 177.9 m (7.7 %) | units walk tower_r_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_a1 vs home_a_a2-inn_a2 | 47.4 m vs 51.3 m (7.7 %) | units walk home_a_a2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-inn_a2 vs home_a_b2-inn_b2 | 51.3 m vs 47.4 m (7.7 %) | units walk home_a_a2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-stag_b2 vs tower_r_b2-stag_a2 | 164.3 m vs 177.9 m (7.7 %) | units walk tower_r_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-cache_a_b1 vs guilds_den_b2-cache_a_b2 | 32.1 m vs 34.8 m (7.7 %) | units walk guilds_den_b2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_a_a2 vs guilds_den_b2-cache_a_b2 | 32.1 m vs 34.8 m (7.7 %) | units walk guilds_den_b2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_a_a1 vs guilds_den_a2-cache_a_a2 | 34.8 m vs 32.1 m (7.7 %) | units walk guilds_den_a1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_a_a1 vs guilds_den_b1-cache_a_b1 | 34.8 m vs 32.1 m (7.7 %) | units walk guilds_den_a1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-cache_a_b2 vs tower_c_b2-cache_a_a2 | 108.4 m vs 117.3 m (7.6 %) | units walk tower_c_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b2 vs keep_t1-wallow_a2 | 164.3 m vs 151.8 m (7.6 %) | units walk keep_t0-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b2 vs keep_t3-wallow_b1 | 164.3 m vs 151.8 m (7.6 %) | units walk keep_t0-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-post_w_b2 vs third_node_b2-post_w_a2 | 194.6 m vs 179.8 m (7.6 %) | units walk third_node_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-guilds_den_b2 vs tower_c_b1-guilds_den_a2 | 138.7 m vs 128.2 m (7.6 %) | units walk tower_c_a1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_a_b1 vs well_b2-cache_a_a2 | 155.6 m vs 168.3 m (7.6 %) | units walk well_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-post_w_a2 vs keep_t4-post_w_a1 | 158.7 m vs 171.7 m (7.6 %) | units walk keep_t4-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-post_w_b1 vs keep_t4-post_w_a1 | 158.8 m vs 171.7 m (7.5 %) | units walk keep_t4-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-cache_a_a1 vs well_b2-cache_a_a2 | 155.7 m vs 168.3 m (7.5 %) | units walk well_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_den_b1 vs home_b_b2-guilds_den_a2 | 189.1 m vs 204.5 m (7.5 %) | units walk home_b_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-wallow_b2 vs home_b_b1-wallow_a1 | 183.2 m vs 169.5 m (7.5 %) | units walk home_b_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_b1 vs home_b_a2-wallow_b2 | 169.5 m vs 183.2 m (7.5 %) | units walk home_b_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_ford_n vs home_a_b1-x_ford_s | 102.1 m vs 94.4 m (7.5 %) | units walk home_a_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-ford_nest_a2 vs home_a_b1-ford_nest_a1 | 102.1 m vs 94.4 m (7.5 %) | units walk home_a_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-ford_nest_a1 vs home_a_b2-ford_nest_a2 | 94.4 m vs 102.1 m (7.5 %) | units walk home_a_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-x_ford_s vs home_a_b2-x_ford_n | 94.4 m vs 102.1 m (7.5 %) | units walk home_a_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-x_ford_s vs home_a_b1-x_ford_s | 102.1 m vs 94.4 m (7.5 %) | units walk home_a_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-ford_nest_a1 vs home_a_b1-ford_nest_a1 | 102.1 m vs 94.4 m (7.5 %) | units walk home_a_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-cache_b_b2 vs rich_node_a2-cache_b_b1 | 36.7 m vs 39.7 m (7.5 %) | units walk rich_node_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-crown vs lairs_one_b1-crown | 114.7 m vs 106.2 m (7.5 %) | units walk lairs_one_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-crown vs lairs_one_a2-crown | 114.7 m vs 106.2 m (7.5 %) | units walk lairs_one_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-guilds_den_b2 vs tower_c_a2-guilds_den_b1 | 138.7 m vs 128.4 m (7.5 %) | units walk tower_c_a1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-x_bridge_s vs lairs_one_b2-x_bridge_n | 174.0 m vs 161.0 m (7.5 %) | units walk lairs_one_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-cache_b_b2 vs rich_node_b2-cache_b_a1 | 36.7 m vs 39.7 m (7.4 %) | units walk rich_node_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-x_bridge_s vs lairs_one_b2-x_bridge_n | 174.0 m vs 161.0 m (7.4 %) | units walk lairs_one_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_b1 vs shrine_b1-inn_a1 | 89.1 m vs 96.2 m (7.4 %) | units walk shrine_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-post_s_b1 vs post_w_b2-post_s_a1 | 121.3 m vs 131.0 m (7.4 %) | units walk post_w_b2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-post_s_a2 vs post_w_b2-post_s_a1 | 121.3 m vs 131.0 m (7.4 %) | units walk post_w_b2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-post_s_b2 vs post_w_a2-post_s_b1 | 130.9 m vs 121.3 m (7.4 %) | units walk post_w_a1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-crown vs lairs_one_b2-crown | 114.7 m vs 106.3 m (7.4 %) | units walk lairs_one_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-post_s_b2 vs post_w_b1-post_s_a2 | 130.9 m vs 121.3 m (7.4 %) | units walk post_w_a1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-inn_b1 vs third_node_b2-inn_a2 | 140.5 m vs 151.6 m (7.3 %) | units walk third_node_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-inn_b2 vs third_node_b2-inn_a2 | 140.5 m vs 151.6 m (7.3 %) | units walk third_node_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-inn_a1 vs third_node_b2-inn_a2 | 140.5 m vs 151.6 m (7.3 %) | units walk third_node_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_b1 vs shrine_a2-inn_b2 | 89.1 m vs 96.1 m (7.3 %) | units walk shrine_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_w_b1 vs third_node_a2-post_w_b2 | 180.3 m vs 194.6 m (7.3 %) | units walk third_node_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-x_bridge_s vs nat_node_b2-x_bridge_s | 69.8 m vs 64.7 m (7.3 %) | units walk nat_node_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-x_bridge_s vs nat_node_a2-x_bridge_n | 69.8 m vs 64.7 m (7.3 %) | units walk nat_node_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-x_bridge_s vs nat_node_b1-x_bridge_n | 69.8 m vs 64.7 m (7.3 %) | units walk nat_node_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_a1 vs third_node_b1-cache_a_b1 | 29.3 m vs 31.6 m (7.3 %) | units walk third_node_b1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_a1 vs third_node_a2-cache_a_a2 | 29.3 m vs 31.6 m (7.3 %) | units walk third_node_a2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_a_b1 vs third_node_b2-cache_a_b2 | 31.6 m vs 29.3 m (7.3 %) | units walk third_node_b1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_a_a2 vs third_node_b2-cache_a_b2 | 31.6 m vs 29.3 m (7.3 %) | units walk third_node_a2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-peddler_b2 vs post_w_b2-peddler_a2 | 150.0 m vs 161.7 m (7.3 %) | units walk post_w_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-peddler_b1 vs post_w_a2-peddler_b2 | 161.7 m vs 150.0 m (7.3 %) | units walk post_w_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-well_a1 vs tower_r_b2-well_a2 | 129.9 m vs 140.0 m (7.2 %) | units walk tower_r_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-x_lane_e vs guilds_den_b2-x_lane_w | 130.0 m vs 140.1 m (7.2 %) | units walk guilds_den_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-well_b2 vs tower_r_b2-well_a2 | 129.9 m vs 140.0 m (7.2 %) | units walk tower_r_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_two_b2 vs stag_b2-lairs_two_a2 | 182.4 m vs 196.5 m (7.2 %) | units walk stag_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_s_b1 vs nat_node_b1-post_s_a2 | 89.4 m vs 96.4 m (7.2 %) | units walk nat_node_b1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-lairs_two_b1 vs well_b2-lairs_two_a2 | 161.0 m vs 173.5 m (7.2 %) | units walk well_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-shrine_b1 vs third_node_b2-shrine_b2 | 61.4 m vs 66.2 m (7.2 %) | units walk third_node_b2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-shrine_a2 vs third_node_b2-shrine_b2 | 61.4 m vs 66.2 m (7.2 %) | units walk third_node_b2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_a1 vs third_node_b1-shrine_b1 | 66.2 m vs 61.4 m (7.2 %) | units walk third_node_a1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_a1 vs third_node_a2-shrine_a2 | 66.2 m vs 61.4 m (7.2 %) | units walk third_node_a1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-lairs_two_a1 vs stag_b2-lairs_two_a2 | 182.4 m vs 196.5 m (7.2 %) | units walk stag_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-inn_b1 vs home_b_b2-inn_a2 | 113.7 m vs 122.4 m (7.1 %) | units walk home_b_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-post_w_b2 vs nat_node_b2-post_w_b1 | 56.1 m vs 52.1 m (7.1 %) | units walk nat_node_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-post_w_a2 vs nat_node_b1-post_w_b2 | 52.1 m vs 56.1 m (7.1 %) | units walk nat_node_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-post_w_a2 vs nat_node_a2-post_w_a1 | 52.1 m vs 56.1 m (7.1 %) | units walk nat_node_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_w_a1 vs nat_node_b2-post_w_b1 | 56.1 m vs 52.1 m (7.1 %) | units walk nat_node_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-inn_a1 vs home_b_b2-inn_a2 | 113.7 m vs 122.4 m (7.1 %) | units walk home_b_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b2 vs keep_t1-peddler_a1 | 158.4 m vs 147.2 m (7.1 %) | units walk keep_t3-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-x_lane_w vs keep_t4-x_lane_w | 94.3 m vs 101.5 m (7.1 %) | units walk keep_t4-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-peddler_a2 vs well_b2-peddler_b2 | 41.6 m vs 44.8 m (7.1 %) | units walk well_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-peddler_b1 vs well_b2-peddler_b2 | 41.6 m vs 44.8 m (7.1 %) | units walk well_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-peddler_a1 vs well_a2-peddler_a2 | 44.8 m vs 41.6 m (7.1 %) | units walk well_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-peddler_a1 vs well_b1-peddler_b1 | 44.8 m vs 41.6 m (7.1 %) | units walk well_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_s_b2 vs well_b1-post_s_a2 | 65.8 m vs 61.2 m (7.1 %) | units walk well_a1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t3-peddler_b2 | 147.2 m vs 158.4 m (7.1 %) | units walk keep_t3-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-x_lane_e vs keep_t4-x_lane_w | 94.3 m vs 101.5 m (7.1 %) | units walk keep_t4-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_s_b2 vs well_a2-post_s_b1 | 65.8 m vs 61.2 m (7.1 %) | units walk well_a1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-cache_b_b2 vs rich_node_b1-cache_b_a2 | 36.7 m vs 39.5 m (7.1 %) | units walk rich_node_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_s_a2 vs well_b2-post_s_a1 | 61.2 m vs 65.8 m (7.0 %) | units walk well_b2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_b1 vs well_b2-stag_a2 | 147.8 m vs 158.9 m (7.0 %) | units walk well_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_s_b1 vs well_b2-post_s_a1 | 61.2 m vs 65.8 m (7.0 %) | units walk well_b2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-stag_b2 vs well_b2-stag_a2 | 147.8 m vs 158.9 m (7.0 %) | units walk well_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-x_bridge_n vs post_w_b2-x_bridge_s | 96.5 m vs 103.8 m (7.0 %) | units walk post_w_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-x_bridge_n vs post_w_b2-x_bridge_s | 96.5 m vs 103.8 m (7.0 %) | units walk post_w_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-nat_node_a1 vs home_b_b2-nat_node_a2 | 116.5 m vs 125.3 m (7.0 %) | units walk home_b_b2-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_bridge_s vs post_w_a2-x_bridge_n | 103.8 m vs 96.5 m (7.0 %) | units walk post_w_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_bridge_s vs post_w_b1-x_bridge_n | 103.8 m vs 96.5 m (7.0 %) | units walk post_w_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_w_b2 vs stag_b1-post_w_a2 | 143.9 m vs 133.9 m (7.0 %) | units walk stag_a1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-nat_node_b1 vs home_b_b2-nat_node_a2 | 116.6 m vs 125.3 m (6.9 %) | units walk home_b_b2-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-stag_a1 vs well_b2-stag_a2 | 147.9 m vs 158.9 m (6.9 %) | units walk well_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_s_a1 vs tower_r_b2-post_s_a2 | 158.1 m vs 169.9 m (6.9 %) | units walk tower_r_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_w_b2 vs stag_a2-post_w_b1 | 143.9 m vs 133.9 m (6.9 %) | units walk stag_a1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_w_b2 vs stag_b2-post_w_a1 | 143.9 m vs 134.0 m (6.9 %) | units walk stag_a1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-x_ford_n vs post_s_b2-x_ford_n | 127.2 m vs 136.6 m (6.9 %) | units walk post_s_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-inn_b2 vs tower_r_a2-inn_b1 | 69.8 m vs 65.0 m (6.9 %) | units walk tower_r_a1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a1 vs well_a2-post_w_a2 | 65.1 m vs 60.6 m (6.9 %) | units walk well_a1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a1 vs well_b1-post_w_b1 | 65.1 m vs 60.6 m (6.9 %) | units walk well_a1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_w_a2 vs well_b2-post_w_b2 | 60.6 m vs 65.1 m (6.9 %) | units walk well_b2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_w_b1 vs well_b2-post_w_b2 | 60.6 m vs 65.1 m (6.9 %) | units walk well_b2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b2 vs keep_t4-wallow_a1 | 164.3 m vs 153.1 m (6.8 %) | units walk keep_t0-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_s_b1 vs tower_r_b2-post_s_a2 | 158.3 m vs 169.9 m (6.8 %) | units walk tower_r_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-guilds_den_b1 vs post_w_b2-guilds_den_a1 | 174.0 m vs 186.8 m (6.8 %) | units walk post_w_b2-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-guilds_den_b2 vs post_w_a2-guilds_den_b1 | 186.8 m vs 174.0 m (6.8 %) | units walk post_w_a1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_b2-guilds_lodge_a1 | 130.7 m vs 140.3 m (6.8 %) | units walk tower_c_b2-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_s_b2 vs tower_r_b2-post_s_a2 | 158.3 m vs 169.9 m (6.8 %) | units walk tower_r_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-guilds_den_a2 vs post_w_b2-guilds_den_a1 | 174.1 m vs 186.8 m (6.8 %) | units walk post_w_b2-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-guilds_den_b2 vs post_w_b1-guilds_den_a2 | 186.8 m vs 174.1 m (6.8 %) | units walk post_w_a1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_lane_e vs tower_r_b2-x_lane_w | 80.1 m vs 85.9 m (6.8 %) | units walk tower_r_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-x_ford_n vs stag_b2-x_ford_n | 120.2 m vs 128.9 m (6.8 %) | units walk stag_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-inn_b2 vs tower_r_b1-inn_a2 | 69.8 m vs 65.0 m (6.8 %) | units walk tower_r_a1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_s_b1 vs nat_node_b2-post_s_a1 | 89.4 m vs 95.9 m (6.8 %) | units walk nat_node_b2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-crown vs shrine_b2-crown | 58.5 m vs 54.5 m (6.8 %) | units walk shrine_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-crown vs shrine_b1-crown | 54.5 m vs 58.5 m (6.8 %) | units walk shrine_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-x_ford_s vs stag_b2-x_ford_n | 120.2 m vs 128.9 m (6.8 %) | units walk stag_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-stag_a2 vs third_node_b1-stag_b2 | 147.4 m vs 158.1 m (6.7 %) | units walk third_node_b1-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-stag_a2 vs third_node_a2-stag_a1 | 147.4 m vs 158.1 m (6.7 %) | units walk third_node_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-stag_a1 vs third_node_b2-stag_b1 | 158.1 m vs 147.4 m (6.7 %) | units walk third_node_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-stag_b2 vs third_node_b2-stag_b1 | 158.1 m vs 147.4 m (6.7 %) | units walk third_node_b1-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-shrine_b2 vs keep_t4-shrine_b1 | 53.0 m vs 56.8 m (6.7 %) | units walk keep_t4-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_a2 vs keep_t1-shrine_b2 | 56.8 m vs 53.0 m (6.7 %) | units walk keep_t0-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_e vs lairs_one_b1-x_lane_w | 127.6 m vs 119.0 m (6.7 %) | units walk lairs_one_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_e vs lairs_one_a2-x_lane_e | 127.6 m vs 119.0 m (6.7 %) | units walk lairs_one_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-shrine_a1 vs keep_t4-shrine_b1 | 53.0 m vs 56.8 m (6.7 %) | units walk keep_t4-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_a2 vs keep_t3-shrine_a1 | 56.8 m vs 53.0 m (6.7 %) | units walk keep_t0-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_s_a2 vs rich_node_b1-post_s_b2 | 132.6 m vs 142.1 m (6.7 %) | units walk rich_node_b1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_s_b2 vs rich_node_b2-post_s_b1 | 142.1 m vs 132.6 m (6.7 %) | units walk rich_node_b1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_a_b2 vs keep_t1-home_a_a1 | 168.0 m vs 156.7 m (6.7 %) | units walk keep_t3-home_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-lairs_one_b1 vs well_b2-lairs_one_a2 | 173.9 m vs 186.4 m (6.7 %) | units walk well_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-x_ford_s vs stag_b2-x_ford_n | 120.3 m vs 128.9 m (6.7 %) | units walk stag_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_b_b1 vs keep_t3-home_b_b2 | 157.4 m vs 168.6 m (6.7 %) | units walk keep_t3-home_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_b_b2 vs keep_t1-home_b_a1 | 168.6 m vs 157.4 m (6.7 %) | units walk keep_t3-home_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-peddler_b1 vs guilds_den_b2-peddler_a2 | 173.6 m vs 185.9 m (6.6 %) | units walk guilds_den_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-crown vs shrine_b2-crown | 58.4 m vs 54.5 m (6.6 %) | units walk shrine_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-stag_a2 vs tower_c_b1-stag_b1 | 73.7 m vs 78.9 m (6.6 %) | units walk tower_c_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-crown vs shrine_a2-crown | 54.5 m vs 58.4 m (6.6 %) | units walk shrine_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_two_b2 vs cache_a_b1-lairs_two_a1 | 197.7 m vs 184.7 m (6.6 %) | units walk cache_a_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-post_w_b1 vs post_w_b2-post_w_a2 | 179.2 m vs 167.5 m (6.6 %) | units walk post_w_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-tower_c_a2 vs keep_t4-tower_c_a1 | 106.9 m vs 114.4 m (6.6 %) | units walk keep_t4-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-peddler_a2 vs wallow_b2-peddler_b2 | 33.3 m vs 35.6 m (6.5 %) | units walk wallow_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_a1 vs wallow_a2-peddler_a2 | 35.6 m vs 33.3 m (6.5 %) | units walk wallow_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_a1 vs wallow_b1-peddler_b1 | 35.6 m vs 33.3 m (6.5 %) | units walk wallow_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-peddler_b1 vs wallow_b2-peddler_b2 | 33.3 m vs 35.6 m (6.5 %) | units walk wallow_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-stag_b2 vs tower_r_b1-stag_a1 | 164.3 m vs 153.6 m (6.5 %) | units walk tower_r_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b2 vs keep_t4-tower_c_a1 | 107.0 m vs 114.4 m (6.5 %) | units walk keep_t4-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-inn_b2 vs third_node_b2-inn_b1 | 108.0 m vs 101.0 m (6.5 %) | units walk third_node_b1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-inn_a1 vs third_node_b2-inn_b1 | 108.0 m vs 101.0 m (6.5 %) | units walk third_node_a2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_b2 vs well_a2-stag_b1 | 79.3 m vs 74.2 m (6.5 %) | units walk well_a1-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-stag_b1 vs well_b2-stag_a1 | 74.2 m vs 79.3 m (6.5 %) | units walk well_b2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_b1 vs tower_r_b1-stag_a1 | 164.2 m vs 153.6 m (6.5 %) | units walk tower_r_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_b2 vs well_b1-stag_a2 | 79.3 m vs 74.2 m (6.5 %) | units walk well_a1-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-stag_a2 vs well_b2-stag_a1 | 74.2 m vs 79.3 m (6.5 %) | units walk well_b2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-keep_t1 vs keep_t4-keep_t3 | 163.1 m vs 174.4 m (6.4 %) | units walk keep_t4-keep_t3 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_b_a1 vs third_node_b1-cache_b_b2 | 118.4 m vs 126.5 m (6.4 %) | units walk third_node_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-shrine_a1 vs home_b_b2-shrine_a2 | 127.0 m vs 135.7 m (6.4 %) | units walk home_b_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-lairs_two_b1 vs ford_nest_a2-lairs_two_a1 | 137.9 m vs 129.0 m (6.4 %) | units walk ford_nest_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-inn_a2 vs third_node_b1-inn_b2 | 101.1 m vs 108.0 m (6.4 %) | units walk third_node_b1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-inn_a2 vs third_node_a2-inn_a1 | 101.1 m vs 108.0 m (6.4 %) | units walk third_node_a2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b1 vs home_b_b2-shrine_a2 | 127.0 m vs 135.7 m (6.4 %) | units walk home_b_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-lairs_one_b2 vs well_b2-lairs_one_a2 | 174.4 m vs 186.4 m (6.4 %) | units walk well_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-post_w_b2 vs keep_t1-post_w_a1 | 175.9 m vs 164.6 m (6.4 %) | units walk keep_t3-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-stag_a1 vs ford_nest_a2-stag_b2 | 120.8 m vs 129.0 m (6.4 %) | units walk ford_nest_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-lairs_two_a2 vs ford_nest_a1-lairs_two_b1 | 129.1 m vs 137.9 m (6.4 %) | units walk ford_nest_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-lairs_two_b1 vs ford_nest_a2-lairs_two_b2 | 137.9 m vs 129.1 m (6.4 %) | units walk ford_nest_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_w_b1 vs keep_t3-post_w_b2 | 164.7 m vs 175.9 m (6.4 %) | units walk keep_t3-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-lairs_one_a1 vs well_b2-lairs_one_a2 | 174.5 m vs 186.4 m (6.4 %) | units walk well_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-rich_node_b1 vs rich_node_b2-rich_node_a2 | 117.4 m vs 125.4 m (6.3 %) | units walk rich_node_b2-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-x_bridge_s vs rich_node_b2-x_bridge_n | 129.3 m vs 121.1 m (6.3 %) | units walk rich_node_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_b_a1 vs guilds_lodge_b2-cache_b_b1 | 134.6 m vs 126.1 m (6.3 %) | units walk guilds_lodge_a2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_a2 vs guilds_lodge_a2-cache_b_a1 | 126.1 m vs 134.6 m (6.3 %) | units walk guilds_lodge_a2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-x_bridge_s vs rich_node_b2-x_bridge_n | 129.2 m vs 121.1 m (6.3 %) | units walk rich_node_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_e vs lairs_one_b2-x_lane_w | 127.6 m vs 119.6 m (6.3 %) | units walk lairs_one_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-peddler_b1 vs post_w_b2-peddler_a1 | 152.1 m vs 162.1 m (6.2 %) | units walk post_w_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-peddler_b2 vs post_w_a2-peddler_b1 | 162.1 m vs 152.1 m (6.2 %) | units walk post_w_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-peddler_a2 vs post_w_b2-peddler_a1 | 152.1 m vs 162.1 m (6.2 %) | units walk post_w_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-peddler_b2 vs post_w_b1-peddler_a2 | 162.1 m vs 152.1 m (6.2 %) | units walk post_w_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_bridge_n vs lairs_one_b1-x_bridge_s | 163.3 m vs 174.0 m (6.2 %) | units walk lairs_one_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-cache_a_b2 vs inn_b2-cache_a_a2 | 122.5 m vs 130.6 m (6.2 %) | units walk inn_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b2 vs tower_r_a2-tower_c_b1 | 74.7 m vs 70.1 m (6.1 %) | units walk tower_r_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_bridge_n vs lairs_one_a2-x_bridge_s | 163.3 m vs 174.0 m (6.1 %) | units walk lairs_one_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b2 vs tower_r_b1-tower_c_a2 | 74.7 m vs 70.1 m (6.1 %) | units walk tower_r_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_a_b1 vs well_b2-cache_a_a1 | 85.7 m vs 91.3 m (6.1 %) | units walk well_b2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_a_b2 vs well_a2-cache_a_b1 | 91.3 m vs 85.7 m (6.1 %) | units walk well_a1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-home_a_b2 vs home_a_a2-home_a_b1 | 154.4 m vs 164.3 m (6.0 %) | units walk home_a_a2-home_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t3-wallow_b2 | 175.2 m vs 186.5 m (6.0 %) | units walk keep_t3-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-wallow_b2 vs keep_t1-wallow_a1 | 186.5 m vs 175.2 m (6.0 %) | units walk keep_t3-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_s_b1 vs well_b2-post_s_a2 | 141.8 m vs 150.9 m (6.0 %) | units walk well_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_s_a1 vs tower_r_b2-post_s_b1 | 147.6 m vs 157.1 m (6.0 %) | units walk tower_r_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_s_a2 vs tower_r_a2-post_s_a1 | 157.1 m vs 147.6 m (6.0 %) | units walk tower_r_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_s_b2 vs well_b2-post_s_a2 | 141.9 m vs 150.9 m (6.0 %) | units walk well_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_s_a1 vs well_b2-post_s_a2 | 141.9 m vs 150.9 m (6.0 %) | units walk well_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_b_b2 vs guilds_lodge_b2-cache_b_b1 | 134.1 m vs 126.1 m (6.0 %) | units walk guilds_lodge_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_a2 vs guilds_lodge_b1-cache_b_b2 | 126.1 m vs 134.1 m (6.0 %) | units walk guilds_lodge_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-tower_r_a1 vs rich_node_b2-tower_r_a2 | 136.9 m vs 128.7 m (6.0 %) | units walk rich_node_b1-tower_r_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-x_ford_n vs stag_b2-x_ford_s | 50.6 m vs 53.8 m (5.9 %) | units walk stag_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-x_ford_n vs stag_b2-x_ford_s | 50.6 m vs 53.8 m (5.9 %) | units walk stag_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-tower_r_b2 vs rich_node_b2-tower_r_a2 | 136.9 m vs 128.7 m (5.9 %) | units walk rich_node_a2-tower_r_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-inn_b2 vs rich_node_b2-inn_a1 | 53.5 m vs 56.8 m (5.9 %) | units walk rich_node_b2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-tower_c_a1 vs keep_t4-tower_c_a2 | 107.4 m vs 114.1 m (5.9 %) | units walk keep_t4-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b1 vs keep_t4-tower_c_a2 | 107.4 m vs 114.1 m (5.9 %) | units walk keep_t4-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-cache_b_b2 vs shrine_b2-cache_b_a2 | 99.3 m vs 93.4 m (5.9 %) | units walk shrine_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_s_b2 vs home_a_a2-post_s_b1 | 114.7 m vs 107.9 m (5.9 %) | units walk home_a_a1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_s_b2 vs home_a_b1-post_s_a2 | 114.7 m vs 107.9 m (5.9 %) | units walk home_a_a1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-guilds_lodge_b2 vs shrine_b2-guilds_lodge_b1 | 95.9 m vs 90.2 m (5.9 %) | units walk shrine_b1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-guilds_lodge_a1 vs shrine_b2-guilds_lodge_b1 | 95.9 m vs 90.2 m (5.9 %) | units walk shrine_a2-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_lodge_a2 vs shrine_b1-guilds_lodge_b2 | 90.2 m vs 95.9 m (5.9 %) | units walk shrine_b1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_lodge_a2 vs shrine_a2-guilds_lodge_a1 | 90.2 m vs 95.9 m (5.9 %) | units walk shrine_a2-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_w_b1 vs rich_node_a2-post_w_b2 | 118.8 m vs 126.2 m (5.9 %) | units walk rich_node_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_w_b1 vs rich_node_b1-post_w_a1 | 118.8 m vs 126.2 m (5.9 %) | units walk rich_node_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-peddler_a1 vs home_b_b2-peddler_a2 | 141.4 m vs 150.2 m (5.8 %) | units walk home_b_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_one_b1 vs stag_b2-lairs_one_a2 | 197.0 m vs 209.2 m (5.8 %) | units walk stag_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-x_ford_n vs wallow_b1-x_ford_s | 131.9 m vs 124.2 m (5.8 %) | units walk wallow_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-x_ford_s vs wallow_b2-x_ford_n | 124.2 m vs 131.9 m (5.8 %) | units walk wallow_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 124.2 m vs 131.9 m (5.8 %) | units walk wallow_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-ford_nest_a2 vs wallow_b1-ford_nest_a1 | 131.9 m vs 124.2 m (5.8 %) | units walk wallow_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-inn_b2 vs rich_node_a2-inn_b1 | 53.5 m vs 56.7 m (5.8 %) | units walk rich_node_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b1 vs home_b_b2-peddler_a2 | 141.4 m vs 150.2 m (5.8 %) | units walk home_b_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-x_ford_s vs wallow_b1-x_ford_s | 131.9 m vs 124.2 m (5.8 %) | units walk wallow_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-ford_nest_a1 vs wallow_b1-ford_nest_a1 | 131.9 m vs 124.2 m (5.8 %) | units walk wallow_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-nat_node_a2 vs keep_t4-nat_node_a1 | 121.9 m vs 129.4 m (5.8 %) | units walk keep_t4-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-inn_b2 vs rich_node_b1-inn_a2 | 53.5 m vs 56.7 m (5.8 %) | units walk rich_node_b1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_lane_e vs tower_r_b1-x_lane_w | 80.1 m vs 75.5 m (5.8 %) | units walk tower_r_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_b2 vs keep_t4-nat_node_a1 | 122.0 m vs 129.4 m (5.7 %) | units walk keep_t4-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-cache_b_a1 vs shrine_b2-cache_b_a2 | 99.1 m vs 93.4 m (5.7 %) | units walk shrine_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_den_b1 vs stag_a2-guilds_den_b2 | 196.0 m vs 207.9 m (5.7 %) | units walk stag_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_b_b1 vs shrine_a2-cache_b_b2 | 93.6 m vs 99.3 m (5.7 %) | units walk shrine_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_lodge_b1 vs stag_a2-guilds_lodge_b2 | 197.4 m vs 209.4 m (5.7 %) | units walk stag_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-peddler_b1 vs shrine_b1-peddler_a1 | 116.8 m vs 123.9 m (5.7 %) | units walk shrine_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_den_b1 vs stag_b1-guilds_den_a1 | 196.0 m vs 207.9 m (5.7 %) | units walk stag_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_lane_e vs tower_r_a2-x_lane_e | 80.1 m vs 75.5 m (5.7 %) | units walk tower_r_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_w_a2 vs inn_b1-post_w_b2 | 65.3 m vs 69.3 m (5.7 %) | units walk inn_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-post_w_b2 vs inn_b2-post_w_b1 | 69.3 m vs 65.3 m (5.7 %) | units walk inn_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-lairs_two_b1 vs inn_b2-lairs_two_a1 | 99.9 m vs 94.3 m (5.7 %) | units walk inn_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-x_ford_n vs post_w_b2-x_ford_s | 86.0 m vs 91.1 m (5.7 %) | units walk post_w_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_ford_s vs post_w_a2-x_ford_n | 91.1 m vs 86.0 m (5.7 %) | units walk post_w_a1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_ford_s vs post_w_b1-x_ford_n | 91.1 m vs 86.0 m (5.7 %) | units walk post_w_a1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-x_ford_n vs post_w_b2-x_ford_s | 86.0 m vs 91.1 m (5.7 %) | units walk post_w_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_lodge_b1 vs stag_b1-guilds_lodge_a1 | 197.4 m vs 209.3 m (5.7 %) | units walk stag_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-lairs_two_a1 vs rich_node_b2-lairs_two_a2 | 153.4 m vs 162.6 m (5.7 %) | units walk rich_node_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-lairs_two_b2 vs inn_a2-lairs_two_b1 | 94.3 m vs 99.9 m (5.6 %) | units walk inn_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-post_w_a1 vs inn_b1-post_w_b2 | 65.4 m vs 69.3 m (5.6 %) | units walk inn_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-x_bridge_s vs tower_r_b2-x_bridge_n | 138.7 m vs 147.0 m (5.6 %) | units walk tower_r_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-peddler_b1 vs shrine_a2-peddler_b2 | 116.8 m vs 123.8 m (5.6 %) | units walk shrine_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-post_w_b2 vs post_w_a2-post_w_b1 | 179.6 m vs 169.6 m (5.6 %) | units walk post_w_a1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-post_w_b2 vs stag_b2-post_w_b1 | 112.3 m vs 106.0 m (5.6 %) | units walk stag_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_w_a2 vs stag_b1-post_w_b2 | 106.0 m vs 112.3 m (5.6 %) | units walk stag_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_w_a2 vs stag_a2-post_w_a1 | 106.0 m vs 112.3 m (5.6 %) | units walk stag_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-post_w_a1 vs stag_b2-post_w_b1 | 112.3 m vs 106.0 m (5.6 %) | units walk stag_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-x_bridge_s vs tower_r_b2-x_bridge_n | 138.8 m vs 147.0 m (5.6 %) | units walk tower_r_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_two_b2 vs rich_node_b2-lairs_two_a2 | 153.5 m vs 162.6 m (5.6 %) | units walk rich_node_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_one_b2 vs stag_b2-lairs_one_a2 | 197.6 m vs 209.2 m (5.6 %) | units walk stag_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-lairs_one_a2 vs lairs_one_b2-lairs_one_b1 | 172.2 m vs 162.7 m (5.5 %) | units walk lairs_one_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_one_a1 vs tower_r_b2-lairs_one_a2 | 169.7 m vs 179.7 m (5.5 %) | units walk tower_r_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_b_b1 vs shrine_b1-cache_b_a1 | 93.6 m vs 99.1 m (5.5 %) | units walk shrine_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-lairs_one_a1 vs stag_b2-lairs_one_a2 | 197.7 m vs 209.2 m (5.5 %) | units walk stag_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b1 vs tower_r_b2-tower_c_a2 | 92.3 m vs 97.6 m (5.5 %) | units walk tower_r_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_one_b2 vs tower_r_b2-lairs_one_a2 | 169.8 m vs 179.7 m (5.5 %) | units walk tower_r_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-lairs_two_a2 vs inn_b2-lairs_two_a1 | 99.8 m vs 94.3 m (5.5 %) | units walk inn_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-wallow_a1 vs home_a_b2-wallow_a2 | 182.6 m vs 172.6 m (5.5 %) | units walk home_a_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-x_lane_w vs shrine_b2-x_lane_w | 71.4 m vs 67.5 m (5.5 %) | units walk shrine_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_lane_e vs shrine_b1-x_lane_w | 67.5 m vs 71.4 m (5.5 %) | units walk shrine_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-lairs_two_b2 vs inn_b1-lairs_two_a2 | 94.3 m vs 99.8 m (5.5 %) | units walk inn_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-post_w_b2 vs third_node_b1-post_w_a1 | 194.6 m vs 184.0 m (5.5 %) | units walk third_node_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-cache_a_b1 vs ford_nest_a2-cache_a_a1 | 119.1 m vs 112.6 m (5.4 %) | units walk ford_nest_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-cache_a_a2 vs ford_nest_a1-cache_a_b1 | 112.6 m vs 119.1 m (5.4 %) | units walk ford_nest_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-post_s_b2 vs nat_node_a2-post_s_b1 | 94.5 m vs 89.4 m (5.4 %) | units walk nat_node_a1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-rich_node_a2 vs rich_node_b2-rich_node_b1 | 106.9 m vs 113.0 m (5.4 %) | units walk rich_node_b2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-peddler_b1 vs stag_b2-peddler_a2 | 138.3 m vs 146.2 m (5.4 %) | units walk stag_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-cache_a_b1 vs ford_nest_a2-cache_a_b2 | 119.1 m vs 112.7 m (5.4 %) | units walk ford_nest_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_bridge_n vs tower_r_b2-x_bridge_n | 139.1 m vs 147.0 m (5.4 %) | units walk tower_r_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-lairs_two_b2 vs well_b1-lairs_two_a2 | 89.9 m vs 85.1 m (5.4 %) | units walk well_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-lairs_two_b2 vs well_a2-lairs_two_b1 | 89.9 m vs 85.1 m (5.4 %) | units walk well_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-inn_b1 vs keep_t4-inn_a2 | 119.5 m vs 126.2 m (5.4 %) | units walk keep_t4-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-peddler_b1 vs stag_a2-peddler_b2 | 138.3 m vs 146.2 m (5.4 %) | units walk stag_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-shrine_a2 vs keep_t4-shrine_a1 | 132.3 m vs 139.8 m (5.4 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-lairs_two_a2 vs well_b2-lairs_two_a1 | 85.1 m vs 89.9 m (5.4 %) | units walk well_b2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-lairs_two_b1 vs well_b2-lairs_two_a1 | 85.1 m vs 89.9 m (5.4 %) | units walk well_b2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-peddler_b1 vs guilds_den_a2-peddler_b2 | 173.6 m vs 183.4 m (5.3 %) | units walk guilds_den_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-lairs_two_b2 vs tower_c_a2-lairs_two_b1 | 99.4 m vs 105.0 m (5.3 %) | units walk tower_c_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_lane_e vs shrine_b2-x_lane_w | 71.3 m vs 67.5 m (5.3 %) | units walk shrine_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_lane_e vs shrine_a2-x_lane_e | 67.5 m vs 71.3 m (5.3 %) | units walk shrine_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-inn_a1 vs keep_t4-inn_a2 | 119.5 m vs 126.2 m (5.3 %) | units walk keep_t4-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-lairs_two_b1 vs tower_c_b2-lairs_two_a1 | 105.0 m vs 99.4 m (5.3 %) | units walk tower_c_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-peddler_b1 vs guilds_den_b1-peddler_a1 | 173.6 m vs 183.3 m (5.3 %) | units walk guilds_den_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b2 vs keep_t4-shrine_a1 | 132.4 m vs 139.8 m (5.3 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_s_a1 vs rich_node_b2-post_s_a2 | 148.8 m vs 141.0 m (5.3 %) | units walk rich_node_b1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_s_b2 vs rich_node_b2-post_s_a2 | 148.8 m vs 141.0 m (5.3 %) | units walk rich_node_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-post_w_a1 vs home_b_b2-post_w_a2 | 158.9 m vs 167.7 m (5.3 %) | units walk home_b_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-nat_node_a1 vs keep_t4-nat_node_a2 | 122.3 m vs 129.1 m (5.3 %) | units walk keep_t4-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_b1 vs keep_t4-nat_node_a2 | 122.3 m vs 129.1 m (5.2 %) | units walk keep_t4-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-cache_b_b2 vs post_w_b1-cache_b_a2 | 105.5 m vs 100.0 m (5.2 %) | units walk post_w_a1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_b1 vs home_a_b2-wallow_a2 | 182.1 m vs 172.6 m (5.2 %) | units walk home_a_a1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-wallow_b1 vs rich_node_b1-wallow_a2 | 99.2 m vs 104.6 m (5.2 %) | units walk rich_node_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-lairs_two_b2 vs tower_c_b1-lairs_two_a2 | 99.4 m vs 104.9 m (5.2 %) | units walk tower_c_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-x_ford_s vs third_node_b2-x_ford_n | 139.4 m vs 147.1 m (5.2 %) | units walk third_node_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-ford_nest_a1 vs third_node_b2-ford_nest_a2 | 139.4 m vs 147.1 m (5.2 %) | units walk third_node_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_ford_n vs third_node_a2-x_ford_s | 147.1 m vs 139.4 m (5.2 %) | units walk third_node_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-ford_nest_a2 vs third_node_a2-ford_nest_a1 | 147.1 m vs 139.4 m (5.2 %) | units walk third_node_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_b1 vs home_b_b2-post_w_a2 | 158.9 m vs 167.7 m (5.2 %) | units walk home_b_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-x_ford_s vs third_node_b2-x_ford_n | 139.4 m vs 147.1 m (5.2 %) | units walk third_node_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-ford_nest_a1 vs third_node_b2-ford_nest_a2 | 139.4 m vs 147.1 m (5.2 %) | units walk third_node_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_ford_n vs third_node_b1-x_ford_s | 147.1 m vs 139.4 m (5.2 %) | units walk third_node_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-ford_nest_a2 vs third_node_b1-ford_nest_a1 | 147.1 m vs 139.4 m (5.2 %) | units walk third_node_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-lairs_two_a2 vs tower_c_b2-lairs_two_a1 | 104.9 m vs 99.4 m (5.2 %) | units walk tower_c_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_den_b2 vs stag_b2-guilds_den_a2 | 207.9 m vs 197.2 m (5.2 %) | units walk stag_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-lairs_two_a2 vs lairs_one_b1-lairs_two_b2 | 171.7 m vs 162.9 m (5.2 %) | units walk lairs_one_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-lairs_two_b2 vs lairs_one_b2-lairs_two_b1 | 162.9 m vs 171.7 m (5.2 %) | units walk lairs_one_b2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-lairs_two_a1 vs lairs_one_b2-lairs_two_b1 | 162.9 m vs 171.7 m (5.2 %) | units walk lairs_one_b2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-lairs_two_a2 vs lairs_one_a2-lairs_two_a1 | 171.7 m vs 162.9 m (5.2 %) | units walk lairs_one_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-post_s_a1 vs tower_c_a2-post_s_a2 | 73.6 m vs 69.8 m (5.2 %) | units walk tower_c_a1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b1 vs tower_r_b2-cache_b_a2 | 107.3 m vs 113.1 m (5.2 %) | units walk tower_r_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_lodge_b2 vs stag_b2-guilds_lodge_a2 | 209.4 m vs 198.6 m (5.2 %) | units walk stag_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-guilds_den_b1 vs shrine_b2-guilds_den_a1 | 151.8 m vs 160.1 m (5.2 %) | units walk shrine_b2-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_s_b1 vs stag_b2-post_s_a2 | 165.0 m vs 174.0 m (5.2 %) | units walk stag_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_den_b2 vs shrine_a2-guilds_den_b1 | 160.1 m vs 151.8 m (5.2 %) | units walk shrine_a1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b2 vs tower_r_b2-tower_c_a1 | 74.7 m vs 78.7 m (5.1 %) | units walk tower_r_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-post_s_b2 vs stag_b2-post_s_a2 | 165.0 m vs 174.0 m (5.1 %) | units walk stag_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-guilds_den_a1 vs stag_b2-guilds_den_a2 | 207.9 m vs 197.2 m (5.1 %) | units walk stag_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-guilds_lodge_a1 vs stag_b2-guilds_lodge_a2 | 209.3 m vs 198.6 m (5.1 %) | units walk stag_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-post_s_a1 vs stag_b2-post_s_a2 | 165.0 m vs 174.0 m (5.1 %) | units walk stag_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_b1 vs rich_node_b1-stag_a1 | 146.9 m vs 154.9 m (5.1 %) | units walk rich_node_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-x_bridge_n vs rich_node_b1-x_bridge_s | 122.6 m vs 129.3 m (5.1 %) | units walk rich_node_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-guilds_den_a2 vs shrine_b2-guilds_den_a1 | 151.9 m vs 160.1 m (5.1 %) | units walk shrine_b2-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-lairs_two_b1 vs guilds_den_b1-lairs_two_a1 | 231.1 m vs 219.3 m (5.1 %) | units walk guilds_den_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_den_b2 vs shrine_b1-guilds_den_a2 | 160.1 m vs 151.9 m (5.1 %) | units walk shrine_a1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-wallow_b1 vs rich_node_b2-wallow_a1 | 99.2 m vs 104.5 m (5.1 %) | units walk rich_node_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-post_s_a2 vs tower_c_b1-post_s_b1 | 69.8 m vs 73.6 m (5.1 %) | units walk tower_c_b1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-lairs_two_b1 vs guilds_den_a2-lairs_two_b2 | 231.1 m vs 219.3 m (5.1 %) | units walk guilds_den_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-x_bridge_n vs rich_node_a2-x_bridge_s | 122.6 m vs 129.2 m (5.1 %) | units walk rich_node_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-crown vs peddler_b1-crown | 69.9 m vs 73.7 m (5.1 %) | units walk peddler_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_two_b1 vs keep_t1-lairs_two_a1 | 187.0 m vs 177.5 m (5.1 %) | units walk keep_t0-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_b1 vs rich_node_a2-stag_b2 | 146.9 m vs 154.8 m (5.1 %) | units walk rich_node_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-cache_b_a2 vs post_w_b2-cache_b_a1 | 100.0 m vs 105.3 m (5.1 %) | units walk post_w_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-cache_b_b2 vs post_w_a2-cache_b_b1 | 105.5 m vs 100.2 m (5.0 %) | units walk post_w_a1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_two_b1 vs keep_t3-lairs_two_b2 | 187.0 m vs 177.6 m (5.0 %) | units walk keep_t0-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b1 vs tower_r_b1-tower_c_a1 | 92.3 m vs 87.6 m (5.0 %) | units walk tower_r_a1-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-crown vs peddler_b2-crown | 73.7 m vs 69.9 m (5.0 %) | units walk peddler_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-crown vs peddler_b1-crown | 69.9 m vs 73.7 m (5.0 %) | units walk peddler_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-lairs_two_a1 vs guilds_den_b2-lairs_two_a2 | 219.3 m vs 230.9 m (5.0 %) | units walk guilds_den_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-lairs_two_b2 vs post_w_a2-lairs_two_b1 | 152.5 m vs 144.8 m (5.0 %) | units walk post_w_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest point | 34.6 m vs 36.1 m between seats (4.2 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | D1 | nearest lair | 48.5 m vs 50.7 m between seats (4.4 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | D1 | nearest crown | 81.4 m vs 88.8 m between seats (8.4 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | A1 | A1 south-west | ally / nearest enemy 0.55 outside 0.33-0.50 (ally 79.4 m, enemy 144.4 m = 1.8x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | A1 | A2 north-west | ally / nearest enemy 0.55 outside 0.33-0.50 (ally 79.4 m, enemy 143.3 m = 1.8x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | A1 | B1 north-east | ally / nearest enemy 0.55 outside 0.33-0.50 (ally 79.4 m, enemy 143.3 m = 1.8x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | A1 | B2 south-east | ally / nearest enemy 0.55 outside 0.33-0.50 (ally 79.4 m, enemy 144.4 m = 1.8x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 2.0 m at (10.8, 44.4) vs its twin's 5.8 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 2.0 m at (10.8, 44.4) vs its twin's 5.8 m | a collider narrows this route only on one side |
| WARN | R1 | A1 south-west enemy_ally | enemy_ally 1.8 outside 2-3 (9 %) | a designer moves the keeps or the river (R1 enemy_ally is not auto-fixed) |
| WARN | R1 | A2 north-west enemy_ally | enemy_ally 1.8 outside 2-3 (10 %) | a designer moves the keeps or the river (R1 enemy_ally is not auto-fixed) |
| WARN | R1 | B1 north-east enemy_ally | enemy_ally 1.8 outside 2-3 (10 %) | a designer moves the keeps or the river (R1 enemy_ally is not auto-fixed) |
| WARN | R1 | B2 south-east enemy_ally | enemy_ally 1.8 outside 2-3 (9 %) | a designer moves the keeps or the river (R1 enemy_ally is not auto-fixed) |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-71.9, 32.4) | (-71.6, 36.1) | keep_t4 | (-71.6, 36.1) | 0.0 |
| keep_t3 | keep | (-71.9, -32.4) | (-71.6, -36.1) | keep_t1 | (-71.6, -36.1) | 0.0 |
| keep_t1 | keep | (71.9, -32.4) | (71.6, -36.1) | keep_t3 | (71.6, -36.1) | 0.0 |
| keep_t4 | keep | (71.9, 32.4) | (71.6, 36.1) | keep_t0 | (71.6, 36.1) | 0.0 |
| home_a_a1 | home_node | (-71.5, 22.9) | (-71.4, 22.9) | home_a_b2 | (-71.4, 22.9) | 0.0 |
| home_a_a2 | home_node | (-71.5, -22.9) | (-71.4, -22.9) | home_a_b1 | (-71.4, -22.9) | 0.0 |
| home_a_b1 | home_node | (71.5, -22.9) | (71.4, -22.9) | home_a_a2 | (71.4, -22.9) | 0.0 |
| home_a_b2 | home_node | (71.5, 22.9) | (71.4, 22.9) | home_a_a1 | (71.4, 22.9) | 0.0 |
| home_b_a1 | home_node | (-64.5, 38.4) | (-64.4, 38.4) | home_b_b2 | (-64.4, 38.4) | 0.0 |
| home_b_a2 | home_node | (-64.5, -38.4) | (-64.4, -38.4) | home_b_b1 | (-64.4, -38.4) | 0.0 |
| home_b_b1 | home_node | (64.5, -38.4) | (64.4, -38.4) | home_b_a2 | (64.4, -38.4) | 0.0 |
| home_b_b2 | home_node | (64.5, 38.4) | (64.4, 38.4) | home_b_a1 | (64.4, 38.4) | 0.0 |
| nat_node_a1 | expansion | (-38.2, 14.2) | (-38.1, 14.1) | nat_node_b2 | (-38.1, 14.1) | 0.0 |
| nat_node_a2 | expansion | (-38.2, -14.2) | (-38.1, -14.1) | nat_node_b1 | (-38.1, -14.1) | 0.0 |
| nat_node_b1 | expansion | (38.2, -14.2) | (38.1, -14.1) | nat_node_a2 | (38.1, -14.1) | 0.0 |
| nat_node_b2 | expansion | (38.2, 14.2) | (38.1, 14.1) | nat_node_a1 | (38.1, 14.1) | 0.0 |
| rich_node_a1 | expansion | (-15.6, 53.5) | (-15.6, 53.4) | rich_node_b2 | (-15.6, 53.4) | 0.0 |
| rich_node_a2 | expansion | (-15.6, -53.5) | (-15.6, -53.4) | rich_node_b1 | (-15.6, -53.4) | 0.0 |
| rich_node_b1 | expansion | (15.6, -53.5) | (15.6, -53.4) | rich_node_a2 | (15.6, -53.4) | 0.0 |
| rich_node_b2 | expansion | (15.6, 53.5) | (15.6, 53.4) | rich_node_a1 | (15.6, 53.4) | 0.0 |
| third_node_a1 | expansion | (-78.8, 63.7) | (-78.6, 63.6) | third_node_b2 | (-78.6, 63.6) | 0.0 |
| third_node_a2 | expansion | (-78.8, -63.7) | (-78.6, -63.6) | third_node_b1 | (-78.6, -63.6) | 0.0 |
| third_node_b1 | expansion | (78.8, -63.7) | (78.6, -63.6) | third_node_a2 | (78.6, -63.6) | 0.0 |
| third_node_b2 | expansion | (78.8, 63.7) | (78.6, 63.6) | third_node_a1 | (78.6, 63.6) | 0.0 |
| tower_r_a1 | point | (-19.1, 65.9) | (-18.9, 65.9) | tower_r_b2 | (-18.9, 65.9) | 0.0 |
| tower_r_a2 | point | (-19.1, -65.9) | (-18.9, -65.9) | tower_r_b1 | (-18.9, -65.9) | 0.0 |
| tower_r_b1 | point | (19.1, -65.9) | (18.9, -65.9) | tower_r_a2 | (18.9, -65.9) | 0.0 |
| tower_r_b2 | point | (19.1, 65.9) | (18.9, 65.9) | tower_r_a1 | (18.9, 65.9) | 0.0 |
| tower_c_a1 | point | (-23.6, 10.2) | (-23.4, 10.1) | tower_c_b2 | (-23.4, 10.1) | 0.0 |
| tower_c_a2 | point | (-23.6, -10.2) | (-23.4, -10.1) | tower_c_b1 | (-23.4, -10.1) | 0.0 |
| tower_c_b1 | point | (23.6, -10.2) | (23.4, -10.1) | tower_c_a2 | (23.4, -10.1) | 0.0 |
| tower_c_b2 | point | (23.6, 10.2) | (23.4, 10.1) | tower_c_a1 | (23.4, 10.1) | 0.0 |
| well_a1 | point | (-33.9, 51.2) | (-33.9, 51.1) | well_b2 | (-33.9, 51.1) | 0.0 |
| well_a2 | point | (-33.9, -51.2) | (-33.9, -51.1) | well_b1 | (-33.9, -51.1) | 0.0 |
| well_b1 | point | (33.9, -51.2) | (33.9, -51.1) | well_a2 | (33.9, -51.1) | 0.0 |
| well_b2 | point | (33.9, 51.2) | (33.9, 51.1) | well_a1 | (33.9, 51.1) | 0.0 |
| shrine_a1 | point | (-50.3, 10.4) | (-50.1, 10.4) | shrine_b2 | (-50.1, 10.4) | 0.0 |
| shrine_a2 | point | (-50.3, -10.4) | (-50.1, -10.4) | shrine_b1 | (-50.1, -10.4) | 0.0 |
| shrine_b1 | point | (50.3, -10.4) | (50.1, -10.4) | shrine_a2 | (50.1, -10.4) | 0.0 |
| shrine_b2 | point | (50.3, 10.4) | (50.1, 10.4) | shrine_a1 | (50.1, 10.4) | 0.0 |
| wallow_a1 | camp | (-79.5, 48.1) | (-79.4, 48.1) | wallow_b2 | (-79.4, 48.1) | 0.0 |
| wallow_a2 | camp | (-79.5, -48.1) | (-79.4, -48.1) | wallow_b1 | (-79.4, -48.1) | 0.0 |
| wallow_b1 | camp | (79.5, -48.1) | (79.4, -48.1) | wallow_a2 | (79.4, -48.1) | 0.0 |
| wallow_b2 | camp | (79.5, 48.1) | (79.4, 48.1) | wallow_a1 | (79.4, 48.1) | 0.0 |
| ford_nest_a1 | camp | (0.0, 39.2) | (0.1, 39.1) | ford_nest_a1 | (-0.1, 39.1) | 0.3 |
| ford_nest_a2 | camp | (0.0, -39.2) | (0.1, -39.1) | ford_nest_a2 | (-0.1, -39.1) | 0.3 |
| stag_a1 | camp | (-36.8, 74.2) | (-36.6, 74.1) | stag_b2 | (-36.6, 74.1) | 0.0 |
| stag_a2 | camp | (-36.8, -74.2) | (-36.6, -74.1) | stag_b1 | (-36.6, -74.1) | 0.0 |
| stag_b1 | camp | (36.8, -74.2) | (36.6, -74.1) | stag_a2 | (36.6, -74.1) | 0.0 |
| stag_b2 | camp | (36.8, 74.2) | (36.6, 74.1) | stag_a1 | (36.6, 74.1) | 0.0 |
| inn_a1 | tavern | (-27.9, 22.7) | (-27.9, 22.6) | inn_b2 | (-27.9, 22.6) | 0.0 |
| inn_a2 | tavern | (-27.9, -22.7) | (-27.9, -22.6) | inn_b1 | (-27.9, -22.6) | 0.0 |
| inn_b1 | tavern | (27.9, -22.7) | (27.9, -22.6) | inn_a2 | (27.9, -22.6) | 0.0 |
| inn_b2 | tavern | (27.9, 22.7) | (27.9, 22.6) | inn_a1 | (27.9, 22.6) | 0.0 |
| post_w_a1 | post | (-82.0, 14.3) | (-81.9, 14.1) | post_w_b2 | (-81.9, 14.1) | 0.0 |
| post_w_a2 | post | (-82.0, -14.3) | (-81.9, -14.1) | post_w_b1 | (-81.9, -14.1) | 0.0 |
| post_w_b1 | post | (82.0, -14.3) | (81.9, -14.1) | post_w_a2 | (81.9, -14.1) | 0.0 |
| post_w_b2 | post | (82.0, 14.3) | (81.9, 14.1) | post_w_a1 | (81.9, 14.1) | 0.0 |
| post_s_a1 | post | (-20.6, 78.8) | (-20.6, 78.6) | post_s_b2 | (-20.6, 78.6) | 0.0 |
| post_s_a2 | post | (-20.6, -78.8) | (-20.6, -78.6) | post_s_b1 | (-20.6, -78.6) | 0.0 |
| post_s_b1 | post | (20.6, -78.8) | (20.6, -78.6) | post_s_a2 | (20.6, -78.6) | 0.0 |
| post_s_b2 | post | (20.6, 78.8) | (20.6, 78.6) | post_s_a1 | (20.6, 78.6) | 0.0 |
| guilds_den_a1 | guild | (-75.7, 80.4) | (-75.6, 80.4) | guilds_den_b2 | (-75.6, 80.4) | 0.0 |
| guilds_den_a2 | guild | (-75.7, -80.4) | (-75.6, -80.4) | guilds_den_b1 | (-75.6, -80.4) | 0.0 |
| guilds_den_b1 | guild | (75.7, -80.4) | (75.6, -80.4) | guilds_den_a2 | (75.6, -80.4) | 0.0 |
| guilds_den_b2 | guild | (75.7, 80.4) | (75.6, 80.4) | guilds_den_a1 | (75.6, 80.4) | 0.0 |
| guilds_lodge_a1 | guild | (-83.9, 71.8) | (-83.9, 71.6) | guilds_lodge_b2 | (-83.9, 71.6) | 0.0 |
| guilds_lodge_a2 | guild | (-83.9, -71.8) | (-83.9, -71.6) | guilds_lodge_b1 | (-83.9, -71.6) | 0.0 |
| guilds_lodge_b1 | guild | (83.9, -71.8) | (83.9, -71.6) | guilds_lodge_a2 | (83.9, -71.6) | 0.0 |
| guilds_lodge_b2 | guild | (83.9, 71.8) | (83.9, 71.6) | guilds_lodge_a1 | (83.9, 71.6) | 0.0 |
| peddler_a1 | peddler | (-61.9, 20.4) | (-61.9, 20.4) | peddler_b2 | (-61.9, 20.4) | 0.0 |
| peddler_a2 | peddler | (-61.9, -20.4) | (-61.9, -20.4) | peddler_b1 | (-61.9, -20.4) | 0.0 |
| peddler_b1 | peddler | (61.9, -20.4) | (61.9, -20.4) | peddler_a2 | (61.9, -20.4) | 0.0 |
| peddler_b2 | peddler | (61.9, 20.4) | (61.9, 20.4) | peddler_a1 | (61.9, 20.4) | 0.0 |
| cache_a_a1 | cache | (-49.4, 62.0) | (-49.4, 61.9) | cache_a_b2 | (-49.4, 61.9) | 0.0 |
| cache_a_a2 | cache | (-49.4, -62.0) | (-49.4, -61.9) | cache_a_b1 | (-49.4, -61.9) | 0.0 |
| cache_a_b1 | cache | (49.4, -62.0) | (49.4, -61.9) | cache_a_a2 | (49.4, -61.9) | 0.0 |
| cache_a_b2 | cache | (49.4, 62.0) | (49.4, 61.9) | cache_a_a1 | (49.4, 61.9) | 0.0 |
| cache_b_a1 | cache | (-5.4, 25.5) | (-5.4, 25.4) | cache_b_b2 | (-5.4, 25.4) | 0.0 |
| cache_b_a2 | cache | (-5.4, -25.5) | (-5.4, -25.4) | cache_b_b1 | (-5.4, -25.4) | 0.0 |
| cache_b_b1 | cache | (5.4, -25.5) | (5.4, -25.4) | cache_b_a2 | (5.4, -25.4) | 0.0 |
| cache_b_b2 | cache | (5.4, 25.5) | (5.4, 25.4) | cache_b_a1 | (5.4, 25.4) | 0.0 |
| lairs_one_a1 | lair | (-64.0, 80.9) | (-63.9, 80.9) | lairs_one_b2 | (-63.9, 80.9) | 0.0 |
| lairs_one_a2 | lair | (-64.0, -80.9) | (-63.9, -80.9) | lairs_one_b1 | (-63.9, -80.9) | 0.0 |
| lairs_one_b1 | lair | (64.0, -80.9) | (63.9, -80.9) | lairs_one_a2 | (63.9, -80.9) | 0.0 |
| lairs_one_b2 | lair | (64.0, 80.9) | (63.9, 80.9) | lairs_one_a1 | (63.9, 80.9) | 0.0 |
| lairs_two_a1 | lair | (-46.0, 80.9) | (-45.9, 80.9) | lairs_two_b2 | (-45.9, 80.9) | 0.0 |
| lairs_two_a2 | lair | (-46.0, -80.9) | (-45.9, -80.9) | lairs_two_b1 | (-45.9, -80.9) | 0.0 |
| lairs_two_b1 | lair | (46.0, -80.9) | (45.9, -80.9) | lairs_two_a2 | (45.9, -80.9) | 0.0 |
| lairs_two_b2 | lair | (46.0, 80.9) | (45.9, 80.9) | lairs_two_a1 | (45.9, 80.9) | 0.0 |
| x_bridge_n | crossing_bridge_road | (0.0, -65.1) | (0.1, -65.1) | x_bridge_n | (-0.1, -65.1) | 0.3 |
| x_bridge_s | crossing_bridge_road | (0.0, 65.1) | (0.1, 65.1) | x_bridge_s | (-0.1, 65.1) | 0.3 |
| x_ford_n | crossing_ford | (0.0, -39.2) | (0.1, -39.1) | x_ford_n | (-0.1, -39.1) | 0.3 |
| x_ford_s | crossing_ford | (0.0, 39.2) | (0.1, 39.1) | x_ford_s | (-0.1, 39.1) | 0.3 |
| x_lane_w | crossing_bridge_lane | (-13.0, 0.0) | (-12.9, 0.1) | x_lane_e | (-12.9, 0.1) | 0.0 |
| x_lane_e | crossing_bridge_lane | (13.0, 0.0) | (12.9, 0.1) | x_lane_w | (12.9, 0.1) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 1632)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | tower_c_a1 - post_w_a2 | 63.4 | tower_c_b1 - post_w_b2 | 78.9 | -19.6 % |
| 2 | tower_c_a1 - post_w_a2 | 63.4 | tower_c_a2 - post_w_a1 | 78.9 | -19.6 % |
| 3 | tower_c_b1 - post_w_b2 | 78.9 | tower_c_b2 - post_w_b1 | 63.4 | +19.6 % |
| 4 | tower_c_a2 - post_w_a1 | 78.9 | tower_c_b2 - post_w_b1 | 63.4 | +19.6 % |
| 5 | tower_r_b1 - cache_b_a2 | 48.1 | tower_r_b2 - cache_b_a1 | 59.3 | -18.9 % |
| 6 | tower_r_a2 - cache_b_b1 | 48.2 | tower_r_b2 - cache_b_a1 | 59.3 | -18.7 % |
| 7 | tower_c_b1 - stag_b1 | 78.9 | tower_c_b2 - stag_b2 | 65.5 | +17.0 % |
| 8 | tower_c_a1 - stag_a1 | 65.5 | tower_c_b1 - stag_b1 | 78.9 | -17.0 % |
| 9 | keep_t0 - rich_node_a1 | 58.6 | keep_t3 - rich_node_a2 | 70.0 | -16.2 % |
| 10 | keep_t3 - rich_node_a2 | 70.0 | keep_t4 - rich_node_b2 | 58.6 | +16.2 % |
| 11 | shrine_a1 - x_lane_w | 38.6 | shrine_b1 - x_lane_e | 45.9 | -15.8 % |
| 12 | shrine_a1 - x_lane_w | 38.6 | shrine_a2 - x_lane_w | 45.8 | -15.7 % |
| 13 | nat_node_a2 - cache_b_b2 | 79.0 | nat_node_b2 - cache_b_a2 | 93.6 | -15.6 % |
| 14 | nat_node_b1 - cache_b_a1 | 79.0 | nat_node_b2 - cache_b_a2 | 93.6 | -15.6 % |
| 15 | nat_node_a1 - cache_b_b1 | 79.0 | nat_node_b2 - cache_b_a2 | 93.6 | -15.6 % |
| 16 | keep_t0 - rich_node_a1 | 58.6 | keep_t1 - rich_node_b1 | 69.3 | -15.5 % |
| 17 | keep_t1 - rich_node_b1 | 69.3 | keep_t4 - rich_node_b2 | 58.6 | +15.5 % |
| 18 | nat_node_b1 - rich_node_b2 | 73.1 | nat_node_b2 - rich_node_b1 | 86.0 | -15.0 % |
| 19 | nat_node_a1 - rich_node_a2 | 86.0 | nat_node_b1 - rich_node_b2 | 73.1 | +15.0 % |
| 20 | nat_node_a1 - rich_node_a2 | 86.0 | nat_node_a2 - rich_node_a1 | 73.1 | +15.0 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 south-west | 28.4 (third_node_a1) | 36.1 (shrine_a1) | 14.3 (wallow_a1) | 50.7 (lairs_one_a1) | 45.8 (inn_a1) | 26.4 (post_w_a1) | 20.0 (peddler_a1) | 34.0 (cache_a_a1) | 81.4 (crown) | 144.4 |
| A2 north-west | 28.4 (third_node_a2) | 34.6 (shrine_a2) | 14.3 (wallow_a2) | 48.5 (lairs_one_a2) | 45.9 (inn_a2) | 26.5 (post_w_a2) | 20.1 (peddler_a2) | 34.0 (cache_a_a2) | 88.8 (crown) | 143.3 |
| B1 north-east | 28.4 (third_node_b1) | 34.6 (shrine_b1) | 14.3 (wallow_b1) | 48.5 (lairs_one_b1) | 45.9 (inn_b1) | 26.5 (post_w_b1) | 20.1 (peddler_b1) | 34.0 (cache_a_b1) | 81.4 (crown) | 143.3 |
| B2 south-east | 28.4 (third_node_b2) | 36.1 (shrine_b2) | 14.3 (wallow_b2) | 50.7 (lairs_one_b2) | 45.8 (inn_b2) | 26.4 (post_w_b2) | 20.0 (peddler_b2) | 34.0 (cache_a_b2) | 88.5 (crown) | 144.4 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| home_b_a1 | home_node | 7.6 | home_b_b2 | 7.6 | +0.0 % |
| wallow_a1 | camp | 14.3 | wallow_b2 | 14.3 | +0.0 % |
| home_a_a1 | home_node | 17.0 | home_a_b2 | 17.0 | +0.0 % |
| peddler_a1 | peddler | 20.0 | peddler_b2 | 20.0 | +0.0 % |
| post_w_a1 | post | 26.4 | post_w_b2 | 26.4 | +0.0 % |
| third_node_a1 | expansion | 28.4 | third_node_b2 | 28.4 | -0.0 % |
| cache_a_a1 | cache | 34.0 | cache_a_b2 | 34.0 | -0.0 % |
| shrine_a1 | point | 36.1 | shrine_b2 | 36.1 | -0.0 % |
| guilds_lodge_a1 | guild | 37.6 | guilds_lodge_b2 | 37.6 | +0.0 % |
| nat_node_a1 | expansion | 40.5 | nat_node_b2 | 40.5 | +0.0 % |
| well_a1 | point | 40.6 | well_b2 | 40.6 | -0.0 % |
| guilds_den_a1 | guild | 44.4 | guilds_den_b2 | 44.4 | +0.0 % |
| inn_a1 | tavern | 45.8 | inn_b2 | 45.8 | +0.0 % |
| lairs_one_a1 | lair | 50.7 | lairs_one_b2 | 50.7 | -0.1 % |
| lairs_two_a1 | lair | 51.6 | lairs_two_b2 | 51.6 | +0.0 % |
| post_w_a2 | post | 54.2 | post_w_b1 | 54.2 | +0.0 % |
| stag_a1 | camp | 54.7 | stag_b2 | 54.7 | -0.0 % |
| tower_c_a1 | point | 55.1 | tower_c_b2 | 55.1 | +0.0 % |
| shrine_a2 | point | 56.8 | shrine_b1 | 56.8 | +0.0 % |
| rich_node_a1 | expansion | 58.6 | rich_node_b2 | 58.6 | -0.0 % |
| tower_r_a1 | point | 60.7 | tower_r_b2 | 60.7 | +0.0 % |
| peddler_a2 | peddler | 61.8 | peddler_b1 | 61.8 | +0.0 % |
| home_a_a2 | home_node | 62.7 | home_a_b1 | 62.7 | +0.0 % |
| nat_node_a2 | expansion | 62.7 | nat_node_b1 | 62.7 | +0.0 % |
| post_s_a1 | post | 66.4 | post_s_b2 | 66.4 | +0.0 % |
| cache_b_a1 | cache | 67.1 | cache_b_b2 | 67.1 | +0.0 % |
| tower_c_a2 | point | 67.7 | tower_c_b1 | 67.7 | +0.0 % |
| x_lane_w | crossing_bridge_lane | 70.3 | x_lane_e | 70.3 | +0.0 % |
| x_ford_s | crossing_ford | 71.7 | x_ford_s | 71.7 | +0.0 % |
| ford_nest_a1 | camp | 71.7 | ford_nest_a1 | 71.7 | +0.0 % |
| inn_a2 | tavern | 74.8 | inn_b1 | 74.8 | +0.0 % |
| home_b_a2 | home_node | 78.9 | home_b_b1 | 78.9 | +0.0 % |
| keep_t3 | keep | 79.4 | keep_t1 | 79.4 | +0.0 % |
| crown | crown | 81.4 | crown | 88.5 | -8.0 % |
| x_bridge_s | crossing_bridge_road | 81.6 | x_bridge_s | 81.6 | +0.0 % |
| cache_b_b2 | cache | 86.5 | cache_b_a1 | 86.3 | +0.2 % |
| wallow_a2 | camp | 87.9 | wallow_b1 | 87.9 | +0.0 % |
| cache_b_a2 | cache | 91.3 | cache_b_b1 | 91.3 | +0.0 % |
| x_lane_e | crossing_bridge_lane | 94.3 | x_lane_w | 101.5 | -7.1 % |
| rich_node_b2 | expansion | 100.4 | rich_node_a1 | 100.3 | +0.0 % |
| tower_r_b2 | point | 100.6 | tower_r_a1 | 100.6 | +0.0 % |
| well_a2 | point | 101.7 | well_b1 | 101.7 | +0.0 % |
| post_s_b2 | post | 101.8 | post_s_a1 | 101.8 | +0.0 % |
| third_node_a2 | expansion | 103.3 | third_node_b1 | 103.3 | +0.0 % |
| inn_b2 | tavern | 103.4 | inn_a1 | 103.4 | +0.0 % |
| x_ford_n | crossing_ford | 104.6 | x_ford_n | 104.6 | -0.0 % |
| ford_nest_a2 | camp | 104.6 | ford_nest_a2 | 104.6 | -0.0 % |
| cache_a_a2 | cache | 105.1 | cache_a_b1 | 105.1 | +0.0 % |
| tower_c_b2 | point | 107.0 | tower_c_a1 | 114.4 | -6.5 % |
| tower_c_b1 | point | 107.4 | tower_c_a2 | 114.1 | -5.9 % |
| guilds_lodge_a2 | guild | 111.6 | guilds_lodge_b1 | 111.6 | +0.0 % |
| rich_node_a2 | expansion | 113.8 | rich_node_b1 | 113.8 | +0.0 % |
| well_b2 | point | 117.7 | well_a1 | 117.7 | +0.0 % |
| stag_b2 | camp | 119.1 | stag_a1 | 119.1 | +0.0 % |
| inn_b1 | tavern | 119.5 | inn_a2 | 126.2 | -5.4 % |
| guilds_den_a2 | guild | 120.0 | guilds_den_b1 | 120.0 | -0.0 % |
| stag_a2 | camp | 120.8 | stag_b1 | 120.8 | +0.0 % |
| tower_r_a2 | point | 121.1 | tower_r_b1 | 121.1 | +0.0 % |
| nat_node_b2 | expansion | 122.0 | nat_node_a1 | 129.4 | -5.7 % |
| nat_node_b1 | expansion | 122.3 | nat_node_a2 | 129.1 | -5.2 % |
| lairs_two_a2 | lair | 124.4 | lairs_two_b1 | 124.4 | +0.0 % |
| lairs_one_a2 | lair | 126.3 | lairs_one_b1 | 126.3 | -0.0 % |
| lairs_two_b2 | lair | 129.7 | lairs_two_a1 | 129.7 | +0.0 % |
| cache_a_b2 | cache | 131.4 | cache_a_a1 | 131.4 | -0.0 % |
| post_s_a2 | post | 131.8 | post_s_b1 | 131.8 | +0.0 % |
| shrine_b2 | point | 132.4 | shrine_a1 | 139.8 | -5.3 % |
| x_bridge_n | crossing_bridge_road | 132.5 | x_bridge_n | 132.5 | -0.0 % |
| shrine_b1 | point | 132.8 | shrine_a2 | 139.5 | -4.8 % |
| cache_b_b1 | cache | 134.2 | cache_b_a2 | 134.0 | +0.1 % |
| home_b_b2 | home_node | 138.3 | home_b_a1 | 138.3 | -0.0 % |
| rich_node_b1 | expansion | 140.6 | rich_node_a2 | 140.5 | +0.0 % |
| keep_t4 | keep | 144.4 | keep_t0 | 144.4 | +0.0 % |
| peddler_b2 | peddler | 146.8 | peddler_a1 | 154.2 | -4.8 % |
| lairs_one_b2 | lair | 147.1 | lairs_one_a1 | 147.1 | +0.0 % |
| peddler_b1 | peddler | 147.2 | peddler_a2 | 154.0 | -4.4 % |
| tower_r_b1 | point | 152.1 | tower_r_a2 | 152.0 | +0.1 % |
| well_b1 | point | 156.3 | well_a2 | 156.3 | +0.0 % |
| home_a_b2 | home_node | 156.4 | home_a_a1 | 163.8 | -4.5 % |
| home_b_b1 | home_node | 157.4 | home_b_a2 | 164.1 | -4.1 % |
| guilds_den_b2 | guild | 158.8 | guilds_den_a1 | 158.8 | +0.0 % |
| third_node_b2 | expansion | 160.4 | third_node_a1 | 160.4 | +0.0 % |
| keep_t1 | keep | 163.1 | keep_t3 | 174.4 | -6.4 % |
| home_a_b1 | home_node | 163.6 | home_a_a2 | 164.0 | -0.3 % |
| post_s_b1 | post | 164.1 | post_s_a2 | 164.2 | -0.1 % |
| post_w_b2 | post | 164.3 | post_w_a1 | 171.7 | -4.3 % |
| wallow_b2 | camp | 164.3 | wallow_a1 | 153.1 | +6.8 % |
| post_w_b1 | post | 164.7 | post_w_a2 | 171.5 | -4.0 % |
| guilds_lodge_b2 | guild | 165.9 | guilds_lodge_a1 | 165.9 | +0.0 % |
| stag_b1 | camp | 172.5 | stag_a2 | 172.2 | +0.1 % |
| wallow_b1 | camp | 175.2 | wallow_a2 | 182.0 | -3.7 % |
| cache_a_b1 | cache | 181.6 | cache_a_a2 | 181.7 | -0.0 % |
| lairs_two_b1 | lair | 187.0 | lairs_two_a2 | 186.8 | +0.1 % |
| lairs_one_b1 | lair | 199.9 | lairs_one_a2 | 199.7 | +0.1 % |
| third_node_b1 | expansion | 202.7 | third_node_a2 | 202.7 | +0.0 % |
| guilds_den_b1 | guild | 210.4 | guilds_den_a2 | 210.2 | +0.1 % |
| guilds_lodge_b1 | guild | 216.2 | guilds_lodge_a2 | 216.0 | +0.1 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| A1 south-west | 0 | keep_t3 | 79.4 | no | 144.4 | 163.1 | 0.55 |
| A2 north-west | 0 | keep_t0 | 79.4 | no | 143.3 | 174.4 | 0.55 |
| B1 north-east | 1 | keep_t4 | 79.4 | no | 143.3 | 163.1 | 0.55 |
| B2 south-east | 1 | keep_t1 | 79.4 | no | 144.4 | 174.4 | 0.55 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| A1 south-west | ally keep (keep_t3) | 79.4 | 0.0 | 0:17 | 0:16 | 0:11 | 0:20 |
| A1 south-west | enemy keep (nearest) (keep_t4) | 144.4 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| A1 south-west | enemy keep #2 (keep_t1) | 163.1 | 0.0 | 0:35 | 0:33 | 0:22 | 0:41 |
| A1 south-west | nearest expansion (third_node_a1) | 28.4 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| A1 south-west | nearest point (shrine_a1) | 36.1 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| A1 south-west | nearest camp (wallow_a1) | 14.3 | 0.0 | 0:03 | 0:03 | 0:02 | 0:04 |
| A1 south-west | crown (crown) | 81.4 | 0.0 | 0:18 | 0:16 | 0:11 | 0:20 |
| A2 north-west | ally keep (keep_t0) | 79.4 | 0.0 | 0:17 | 0:16 | 0:11 | 0:20 |
| A2 north-west | enemy keep (nearest) (keep_t1) | 143.3 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| A2 north-west | enemy keep #2 (keep_t4) | 174.4 | 0.0 | 0:38 | 0:35 | 0:23 | 0:44 |
| A2 north-west | nearest expansion (third_node_a2) | 28.4 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| A2 north-west | nearest point (shrine_a2) | 34.6 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| A2 north-west | nearest camp (wallow_a2) | 14.3 | 0.0 | 0:03 | 0:03 | 0:02 | 0:04 |
| A2 north-west | crown (crown) | 88.8 | 0.0 | 0:19 | 0:18 | 0:12 | 0:22 |
| B1 north-east | ally keep (keep_t4) | 79.4 | 0.0 | 0:17 | 0:16 | 0:11 | 0:20 |
| B1 north-east | enemy keep (nearest) (keep_t3) | 143.3 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| B1 north-east | enemy keep #2 (keep_t0) | 163.1 | 0.0 | 0:35 | 0:33 | 0:22 | 0:41 |
| B1 north-east | nearest expansion (third_node_b1) | 28.4 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| B1 north-east | nearest point (shrine_b1) | 34.6 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| B1 north-east | nearest camp (wallow_b1) | 14.3 | 0.0 | 0:03 | 0:03 | 0:02 | 0:04 |
| B1 north-east | crown (crown) | 81.4 | 0.0 | 0:18 | 0:16 | 0:11 | 0:20 |
| B2 south-east | ally keep (keep_t1) | 79.4 | 0.0 | 0:17 | 0:16 | 0:11 | 0:20 |
| B2 south-east | enemy keep (nearest) (keep_t0) | 144.4 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| B2 south-east | enemy keep #2 (keep_t3) | 169.9 | 0.0 | 0:37 | 0:34 | 0:23 | 0:42 |
| B2 south-east | nearest expansion (third_node_b2) | 28.4 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| B2 south-east | nearest point (shrine_b2) | 36.1 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| B2 south-east | nearest camp (wallow_b2) | 14.3 | 0.0 | 0:03 | 0:03 | 0:02 | 0:04 |
| B2 south-east | crown (crown) | 88.5 | 0.0 | 0:19 | 0:18 | 0:12 | 0:22 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| x_bridge_n | bridge_road | 6.0 | 4.8 | 5.8 | x_bridge_n | 4.8 |
| x_bridge_s | bridge_road | 6.0 | 4.8 | 5.8 | x_bridge_s | 4.8 |
| x_ford_n | ford | 7.0 | 5.8 | 6.8 | x_ford_n | 5.8 |
| x_ford_s | ford | 7.0 | 5.8 | 6.8 | x_ford_s | 5.8 |
| x_lane_w | bridge_lane | 8.0 | 7.0 | 8.0 | x_lane_e | 7.0 |
| x_lane_e | bridge_lane | 8.0 | 7.0 | 8.0 | x_lane_w | 7.0 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 81.7 | 3.9 | (-7.4, 1.7) | - |
| keep_t0 -> keep_t1 | 163.1 | 4.1 | (-7.4, 1.7) | - |
| keep_t0 -> keep_t4 | 144.4 | 2.0 | (10.8, 44.4) | (10.8, 44.4) 2.0 |
| keep_t0 -> third_node_a1 | 28.4 | 17.5 | (-75.3, 50.7) | - |
| keep_t3 -> crown | 89.1 | 3.8 | (-6.9, 0.8) | - |
| keep_t3 -> keep_t4 | 174.4 | 3.8 | (-7.0, 1.7) | - |
| keep_t3 -> third_node_a2 | 28.4 | 17.5 | (-75.3, -50.7) | - |
| keep_t1 -> crown | 81.5 | 4.1 | (7.3, -1.8) | - |
| keep_t1 -> keep_t3 | 143.3 | 5.8 | (1.6, -36.5) | - |
| keep_t1 -> third_node_b1 | 28.4 | 17.5 | (75.3, -50.7) | - |
| keep_t4 -> crown | 88.5 | 3.8 | (7.6, -0.6) | - |
| keep_t4 -> third_node_b2 | 28.4 | 17.5 | (75.3, 50.7) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| A1 south-west | ally | 60.00-72.00 | 79.37 | 10.2 % |
| A1 south-west | enemy_ally | 2.00-3.00 | 1.82 | 9.0 % |
| A1 south-west | keep_enemy | 130.00-185.00 | 144.44 | - |
| A1 south-west | natural | 32.00-56.00 | 40.46 | - |
| A1 south-west | rich | 50.00-95.00 | 58.60 | - |
| A1 south-west | crown | 60.00-95.00 | 81.42 | - |
| A2 north-west | ally | 60.00-72.00 | 79.37 | 10.2 % |
| A2 north-west | enemy_ally | 2.00-3.00 | 1.80 | 9.8 % |
| A2 north-west | keep_enemy | 130.00-185.00 | 143.25 | - |
| A2 north-west | natural | 32.00-56.00 | 40.51 | - |
| A2 north-west | rich | 50.00-95.00 | 69.96 | - |
| A2 north-west | crown | 60.00-95.00 | 88.83 | - |
| B1 north-east | ally | 60.00-72.00 | 79.37 | 10.2 % |
| B1 north-east | enemy_ally | 2.00-3.00 | 1.80 | 9.8 % |
| B1 north-east | keep_enemy | 130.00-185.00 | 143.25 | - |
| B1 north-east | natural | 32.00-56.00 | 40.51 | - |
| B1 north-east | rich | 50.00-95.00 | 69.35 | - |
| B1 north-east | crown | 60.00-95.00 | 81.40 | - |
| B2 south-east | ally | 60.00-72.00 | 79.37 | 10.2 % |
| B2 south-east | enemy_ally | 2.00-3.00 | 1.82 | 9.0 % |
| B2 south-east | keep_enemy | 130.00-185.00 | 144.44 | - |
| B2 south-east | natural | 32.00-56.00 | 40.46 | - |
| B2 south-east | rich | 50.00-95.00 | 58.60 | - |
| B2 south-east | crown | 60.00-95.00 | 88.52 | - |


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
| A1 south-west | 4 | 3 | 19 | 51 |
| A2 north-west | 4 | 2 | 20 | 51 |
| B1 north-east | 4 | 3 | 20 | 51 |
| B2 south-east | 4 | 3 | 19 | 51 |


## Hottest metres (every spot-pair shortest path, 4656 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-8.5, 1.5) | 248 | 5 % |
| 2 | (7.5, -1.5) | 238 | 5 % |
| 3 | (-0.5, -0.5) | 231 | 5 % |
| 4 | (1.5, 37.5) | 230 | 5 % |
| 5 | (3.5, -36.5) | 224 | 5 % |
| 6 | (30.5, -34.5) | 221 | 5 % |
| 7 | (14.5, 3.5) | 217 | 5 % |
| 8 | (-30.5, 33.5) | 217 | 5 % |
| 9 | (-30.5, -34.5) | 206 | 4 % |
| 10 | (-35.5, -65.5) | 204 | 4 % |


## Info findings (963)
| Check | Where | What |
|---|---|---|
| N3 | island 24 at (-71.9, -32.4) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 25 at (71.9, -32.4) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 43 at (-71.9, 32.4) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 44 at (71.9, 32.4) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 56 islands on top of colliders (722 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | shrine_a1-inn_a1 vs shrine_b1-inn_b1 | 25.4 m vs 27.3 m (7.1 %) |
| F2 | shrine_b1-inn_b1 vs shrine_b2-inn_b2 | 27.3 m vs 25.4 m (7.1 %) |
| F2 | shrine_a1-inn_a1 vs shrine_a2-inn_a2 | 25.4 m vs 26.8 m (5.2 %) |
| F2 | shrine_a2-inn_a2 vs shrine_b2-inn_b2 | 26.8 m vs 25.4 m (5.2 %) |
| F2 | tower_c_b1-shrine_b2 vs tower_c_b2-shrine_b1 | 33.7 m vs 35.6 m (5.2 %) |
| F2 | tower_c_a2-shrine_a1 vs tower_c_b2-shrine_b1 | 33.7 m vs 35.6 m (5.2 %) |
| F2 | nat_node_a1-tower_c_a2 vs nat_node_b1-tower_c_b2 | 30.0 m vs 28.4 m (5.2 %) |
| F2 | nat_node_b1-tower_c_b2 vs nat_node_b2-tower_c_b1 | 28.4 m vs 30.0 m (5.2 %) |
| F2 | nat_node_a2-tower_c_a1 vs nat_node_b1-tower_c_b2 | 29.9 m vs 28.4 m (5.1 %) |
| F2 | shrine_a2-post_s_b1 vs shrine_b2-post_s_a1 | 99.1 m vs 104.3 m (5.0 %) |
| F2 | tower_r_a1-shrine_b2 vs tower_r_b1-shrine_a2 | 95.2 m vs 90.4 m (5.0 %) |
| F2 | tower_r_a1-tower_c_b1 vs tower_r_a2-tower_c_b2 | 92.3 m vs 87.6 m (5.0 %) |
| F2 | guilds_den_a2-lairs_two_b2 vs guilds_den_b2-lairs_two_a2 | 219.3 m vs 230.9 m (5.0 %) |
| F2 | tower_c_a1-shrine_a2 vs tower_c_b1-shrine_b2 | 35.5 m vs 33.7 m (5.0 %) |
| F2 | tower_c_a1-shrine_a2 vs tower_c_a2-shrine_a1 | 35.5 m vs 33.7 m (5.0 %) |
| F2 | post_w_a2-lairs_two_b1 vs post_w_b2-lairs_two_a1 | 144.8 m vs 152.4 m (5.0 %) |
| F2 | shrine_b1-post_s_a2 vs shrine_b2-post_s_a1 | 99.1 m vs 104.3 m (5.0 %) |
| F2 | keep_t1-lairs_two_a1 vs keep_t4-lairs_two_a2 | 177.5 m vs 186.8 m (5.0 %) |
| F2 | rich_node_a1-tower_c_b2 vs rich_node_b2-tower_c_a1 | 58.6 m vs 61.7 m (5.0 %) |
| F2 | guilds_lodge_b1-x_ford_s vs guilds_lodge_b2-x_ford_n | 147.0 m vs 154.6 m (5.0 %) |
| F2 | guilds_lodge_a1-x_ford_n vs guilds_lodge_b1-x_ford_s | 154.6 m vs 147.0 m (5.0 %) |
| F2 | post_s_a2-x_bridge_s vs post_s_b2-x_bridge_n | 150.5 m vs 158.4 m (5.0 %) |
| F2 | guilds_lodge_a2-x_ford_s vs guilds_lodge_b1-x_ford_s | 154.6 m vs 147.0 m (4.9 %) |
| F2 | keep_t3-lairs_two_b2 vs keep_t4-lairs_two_a2 | 177.6 m vs 186.8 m (4.9 %) |
| F2 | shrine_a1-post_s_b2 vs shrine_a2-post_s_b1 | 104.2 m vs 99.1 m (4.9 %) |
| F2 | post_s_b1-x_bridge_s vs post_s_b2-x_bridge_n | 150.6 m vs 158.4 m (4.9 %) |
| F2 | shrine_a1-post_s_b2 vs shrine_b1-post_s_a2 | 104.2 m vs 99.1 m (4.9 %) |
| F2 | nat_node_a2-lairs_two_b1 vs nat_node_b2-lairs_two_a1 | 119.1 m vs 113.3 m (4.9 %) |
| F2 | home_b_b1-wallow_a1 vs home_b_b2-wallow_a2 | 169.5 m vs 178.2 m (4.9 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_b2-wallow_a2 | 169.5 m vs 178.2 m (4.9 %) |
| F2 | rich_node_a1-tower_c_b2 vs rich_node_a2-tower_c_b1 | 58.6 m vs 61.6 m (4.9 %) |
| F2 | rich_node_a1-tower_r_b1 vs rich_node_b1-tower_r_a1 | 130.2 m vs 136.9 m (4.9 %) |
| F2 | post_w_a2-cache_b_b1 vs post_w_b2-cache_b_a1 | 100.2 m vs 105.3 m (4.9 %) |
| F2 | tower_r_a1-inn_b1 vs tower_r_b2-inn_a2 | 105.5 m vs 110.9 m (4.9 %) |
| F2 | keep_t1-shrine_a1 vs keep_t4-shrine_a2 | 132.7 m vs 139.5 m (4.9 %) |
| F2 | shrine_b1-stag_b1 vs shrine_b2-stag_b2 | 66.1 m vs 69.5 m (4.9 %) |
| F2 | shrine_a2-stag_a2 vs shrine_b2-stag_b2 | 66.1 m vs 69.5 m (4.9 %) |
| F2 | shrine_a1-stag_a1 vs shrine_b1-stag_b1 | 69.5 m vs 66.1 m (4.9 %) |
| F2 | shrine_a1-stag_a1 vs shrine_a2-stag_a2 | 69.5 m vs 66.1 m (4.9 %) |
| F2 | well_a1-cache_a_b2 vs well_b1-cache_a_a2 | 91.3 m vs 95.9 m (4.8 %) |
| F2 | keep_t0-shrine_b1 vs keep_t4-shrine_a2 | 132.8 m vs 139.5 m (4.8 %) |
| F2 | well_b1-cache_a_a2 vs well_b2-cache_a_a1 | 95.9 m vs 91.3 m (4.8 %) |
| F2 | home_a_a2-guilds_den_b1 vs home_a_b2-guilds_den_a1 | 160.7 m vs 168.8 m (4.8 %) |
| F2 | rich_node_a1-tower_r_b1 vs rich_node_a2-tower_r_b2 | 130.2 m vs 136.9 m (4.8 %) |
| F2 | nat_node_a1-lairs_two_b2 vs nat_node_a2-lairs_two_b1 | 113.4 m vs 119.1 m (4.8 %) |
| F2 | stag_a1-lairs_one_a2 vs stag_a2-lairs_one_a1 | 165.9 m vs 157.9 m (4.8 %) |
| F2 | stag_a2-lairs_one_a1 vs stag_b2-lairs_one_b1 | 157.9 m vs 165.8 m (4.8 %) |
| F2 | keep_t0-peddler_b2 vs keep_t4-peddler_a1 | 146.8 m vs 154.2 m (4.8 %) |
| F2 | home_a_b1-guilds_den_a2 vs home_a_b2-guilds_den_a1 | 160.7 m vs 168.8 m (4.8 %) |
| F2 | stag_a2-post_w_a2 vs stag_b1-post_w_b1 | 77.1 m vs 81.0 m (4.8 %) |
| F2 | well_a1-lairs_one_b2 vs well_a2-lairs_one_b1 | 107.4 m vs 102.2 m (4.8 %) |
| F2 | well_a2-lairs_one_b1 vs well_b2-lairs_one_a1 | 102.2 m vs 107.4 m (4.8 %) |
| F2 | well_a1-lairs_one_b2 vs well_b1-lairs_one_a2 | 107.4 m vs 102.2 m (4.8 %) |
| F2 | well_b1-lairs_one_a2 vs well_b2-lairs_one_a1 | 102.2 m vs 107.4 m (4.8 %) |
| F2 | rich_node_a1-tower_c_b2 vs rich_node_b1-tower_c_a2 | 58.6 m vs 61.5 m (4.7 %) |
| F2 | nat_node_b1-lairs_two_a2 vs nat_node_b2-lairs_two_a1 | 118.9 m vs 113.3 m (4.7 %) |
| F2 | keep_t0-nat_node_b2 vs keep_t3-nat_node_b1 | 122.0 m vs 116.2 m (4.7 %) |
| F2 | well_a1-x_bridge_n vs well_b2-x_bridge_n | 121.7 m vs 127.7 m (4.7 %) |
| F2 | nat_node_a1-lairs_two_b2 vs nat_node_b1-lairs_two_a2 | 113.4 m vs 118.9 m (4.7 %) |
| F2 | third_node_a1-peddler_a1 vs third_node_a2-peddler_a2 | 50.8 m vs 48.5 m (4.7 %) |
| F2 | third_node_a2-peddler_a2 vs third_node_b2-peddler_b2 | 48.5 m vs 50.8 m (4.7 %) |
| F2 | third_node_a1-peddler_a1 vs third_node_b1-peddler_b1 | 50.8 m vs 48.5 m (4.7 %) |
| F2 | third_node_b1-peddler_b1 vs third_node_b2-peddler_b2 | 48.5 m vs 50.8 m (4.7 %) |
| F2 | keep_t3-nat_node_b1 vs keep_t1-nat_node_a2 | 116.2 m vs 121.9 m (4.7 %) |
| F2 | well_b1-stag_b1 vs well_b2-stag_b2 | 24.3 m vs 23.2 m (4.6 %) |
| F2 | well_a2-stag_a2 vs well_b2-stag_b2 | 24.3 m vs 23.2 m (4.6 %) |
| F2 | well_a1-stag_a1 vs well_b1-stag_b1 | 23.2 m vs 24.3 m (4.6 %) |
| F2 | well_a1-stag_a1 vs well_a2-stag_a2 | 23.2 m vs 24.3 m (4.6 %) |
| F2 | well_a2-cache_a_b2 vs well_b1-cache_a_a1 | 148.5 m vs 155.7 m (4.6 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_a2-wallow_b2 | 144.8 m vs 151.9 m (4.6 %) |
| F2 | wallow_a1-cache_a_a2 vs wallow_b1-cache_a_b2 | 116.3 m vs 121.9 m (4.6 %) |
| F2 | wallow_b1-cache_a_b2 vs wallow_b2-cache_a_b1 | 121.9 m vs 116.3 m (4.6 %) |
| F2 | wallow_a1-cache_a_a2 vs wallow_a2-cache_a_a1 | 116.3 m vs 121.9 m (4.6 %) |
| F2 | wallow_a2-cache_a_a1 vs wallow_b2-cache_a_b1 | 121.9 m vs 116.3 m (4.6 %) |
| F2 | well_a1-cache_a_b1 vs well_a2-cache_a_b2 | 155.6 m vs 148.5 m (4.6 %) |
| F2 | home_a_a1-post_s_b1 vs home_a_b1-post_s_a1 | 139.3 m vs 145.9 m (4.5 %) |
| F2 | keep_t0-home_a_b2 vs keep_t4-home_a_a1 | 156.4 m vs 163.8 m (4.5 %) |
| F2 | rich_node_a1-x_lane_e vs rich_node_a2-x_lane_e | 64.0 m vs 67.0 m (4.5 %) |
| F2 | home_a_b1-post_s_a1 vs home_a_b2-post_s_a2 | 145.9 m vs 139.4 m (4.5 %) |
| F2 | stag_a1-lairs_one_a2 vs stag_b1-lairs_one_b2 | 165.9 m vs 158.4 m (4.5 %) |
| F2 | tower_c_a2-lairs_two_b2 vs tower_c_b2-lairs_two_a2 | 116.9 m vs 122.4 m (4.5 %) |
| F2 | stag_b1-lairs_one_b2 vs stag_b2-lairs_one_b1 | 158.4 m vs 165.8 m (4.5 %) |
| F2 | home_b_a1-nat_node_a2 vs home_b_a2-nat_node_a1 | 61.5 m vs 58.7 m (4.5 %) |
| F2 | home_b_a1-nat_node_a2 vs home_b_b1-nat_node_b2 | 61.5 m vs 58.7 m (4.5 %) |
| F2 | rich_node_a1-x_lane_e vs rich_node_b2-x_lane_w | 64.0 m vs 67.0 m (4.5 %) |
| F2 | home_b_b1-shrine_b2 vs home_b_b2-shrine_b1 | 50.8 m vs 53.2 m (4.5 %) |
| F2 | home_b_a1-shrine_a2 vs home_b_b1-shrine_b2 | 53.2 m vs 50.8 m (4.5 %) |
| F2 | home_b_a2-shrine_a1 vs home_b_b2-shrine_b1 | 50.8 m vs 53.2 m (4.5 %) |
| F2 | home_b_a1-shrine_a2 vs home_b_a2-shrine_a1 | 53.2 m vs 50.8 m (4.5 %) |
| F2 | guilds_den_b1-cache_a_a1 vs guilds_den_b2-cache_a_a2 | 215.7 m vs 225.7 m (4.5 %) |
| F2 | well_a1-guilds_lodge_b2 vs well_a2-guilds_lodge_b1 | 125.8 m vs 120.2 m (4.5 %) |
| F2 | well_a2-guilds_lodge_b1 vs well_b2-guilds_lodge_a1 | 120.2 m vs 125.8 m (4.5 %) |
| F2 | post_w_a2-guilds_lodge_b1 vs post_w_b2-guilds_lodge_a1 | 179.9 m vs 188.3 m (4.5 %) |
| F2 | post_w_a1-guilds_lodge_b2 vs post_w_a2-guilds_lodge_b1 | 188.3 m vs 179.9 m (4.5 %) |
| F2 | keep_t1-home_a_a1 vs keep_t4-home_a_a2 | 156.7 m vs 164.0 m (4.4 %) |
| F2 | tower_c_a2-cache_a_b2 vs tower_c_b1-cache_a_a1 | 108.4 m vs 113.4 m (4.4 %) |
| F2 | tower_c_b1-lairs_two_a1 vs tower_c_b2-lairs_two_a2 | 117.0 m vs 122.4 m (4.4 %) |
| F2 | guilds_den_a1-cache_a_b1 vs guilds_den_b1-cache_a_a1 | 225.7 m vs 215.7 m (4.4 %) |
| F2 | post_w_b1-guilds_lodge_a2 vs post_w_b2-guilds_lodge_a1 | 180.0 m vs 188.3 m (4.4 %) |
| F2 | guilds_den_a2-cache_a_b2 vs guilds_den_b2-cache_a_a2 | 215.7 m vs 225.7 m (4.4 %) |
| F2 | post_w_a1-guilds_lodge_b2 vs post_w_b1-guilds_lodge_a2 | 188.3 m vs 180.0 m (4.4 %) |
| F2 | keep_t1-peddler_a1 vs keep_t4-peddler_a2 | 147.2 m vs 154.0 m (4.4 %) |
| F2 | home_b_a1-third_node_a1 vs home_b_b1-third_node_b1 | 29.0 m vs 30.3 m (4.4 %) |
| F2 | home_b_a1-third_node_a1 vs home_b_a2-third_node_a2 | 29.0 m vs 30.3 m (4.4 %) |
| F2 | home_b_b1-third_node_b1 vs home_b_b2-third_node_b2 | 30.3 m vs 29.0 m (4.4 %) |
| F2 | home_b_a2-third_node_a2 vs home_b_b2-third_node_b2 | 30.3 m vs 29.0 m (4.4 %) |
| F2 | tower_r_a1-inn_b1 vs tower_r_b1-inn_a1 | 105.5 m vs 100.9 m (4.4 %) |
| F2 | guilds_den_a1-cache_a_b1 vs guilds_den_a2-cache_a_b2 | 225.7 m vs 215.7 m (4.4 %) |
| F2 | tower_c_b1-guilds_lodge_a2 vs tower_c_b2-guilds_lodge_a1 | 134.1 m vs 140.3 m (4.4 %) |
| F2 | keep_t0-peddler_b1 vs keep_t4-peddler_a2 | 147.2 m vs 154.0 m (4.4 %) |
| F2 | tower_c_a1-cache_a_b1 vs tower_c_a2-cache_a_b2 | 113.3 m vs 108.4 m (4.4 %) |
| F2 | tower_r_a1-inn_b1 vs tower_r_a2-inn_b2 | 105.5 m vs 100.9 m (4.4 %) |
| F2 | tower_r_a1-cache_b_b1 vs tower_r_b1-cache_b_a1 | 107.3 m vs 102.6 m (4.4 %) |
| F2 | keep_t3-lairs_one_a2 vs keep_t4-lairs_one_b2 | 48.5 m vs 50.7 m (4.4 %) |
| F2 | keep_t1-lairs_one_b1 vs keep_t4-lairs_one_b2 | 48.5 m vs 50.7 m (4.4 %) |
| F2 | home_b_a2-tower_c_b2 vs home_b_b2-tower_c_a2 | 115.4 m vs 110.3 m (4.4 %) |
| F2 | home_a_a1-x_bridge_n vs home_a_a2-x_bridge_s | 114.6 m vs 119.9 m (4.4 %) |
| F2 | home_a_a1-guilds_den_b2 vs home_a_b2-guilds_den_a1 | 161.5 m vs 168.8 m (4.4 %) |
| F2 | home_a_a2-x_bridge_s vs home_a_b2-x_bridge_n | 119.9 m vs 114.6 m (4.4 %) |
| F2 | tower_c_a2-guilds_lodge_b1 vs tower_c_b2-guilds_lodge_a1 | 134.2 m vs 140.3 m (4.3 %) |
| F2 | home_a_a2-x_bridge_s vs home_a_b1-x_bridge_s | 119.9 m vs 114.7 m (4.3 %) |
| F2 | keep_t0-post_w_b2 vs keep_t4-post_w_a1 | 164.3 m vs 171.7 m (4.3 %) |
| F2 | well_a1-guilds_den_b2 vs well_a2-guilds_den_b1 | 119.1 m vs 113.9 m (4.3 %) |
| F2 | tower_r_a1-cache_b_b1 vs tower_r_a2-cache_b_b2 | 107.3 m vs 102.7 m (4.3 %) |
| F2 | rich_node_a1-x_lane_e vs rich_node_b1-x_lane_w | 64.0 m vs 66.9 m (4.3 %) |
| F2 | well_a2-guilds_den_b1 vs well_b2-guilds_den_a1 | 113.9 m vs 119.1 m (4.3 %) |
| F2 | well_a1-guilds_den_b2 vs well_b1-guilds_den_a2 | 119.1 m vs 113.9 m (4.3 %) |
| F2 | well_b1-guilds_den_a2 vs well_b2-guilds_den_a1 | 113.9 m vs 119.1 m (4.3 %) |
| F2 | home_b_a1-third_node_b2 vs home_b_a2-third_node_b1 | 153.4 m vs 146.8 m (4.3 %) |
| F2 | home_b_a2-third_node_b1 vs home_b_b2-third_node_a1 | 146.8 m vs 153.4 m (4.3 %) |
| F2 | home_b_b1-third_node_a2 vs home_b_b2-third_node_a1 | 146.8 m vs 153.4 m (4.3 %) |
| F2 | home_b_a1-third_node_b2 vs home_b_b1-third_node_a2 | 153.4 m vs 146.8 m (4.3 %) |
| F2 | rich_node_a2-lairs_two_a2 vs rich_node_b2-lairs_two_b2 | 42.7 m vs 40.9 m (4.3 %) |
| F2 | rich_node_a1-lairs_two_a1 vs rich_node_a2-lairs_two_a2 | 40.9 m vs 42.7 m (4.3 %) |
| F2 | well_a1-guilds_lodge_b2 vs well_b1-guilds_lodge_a2 | 125.8 m vs 120.4 m (4.3 %) |
| F2 | well_b1-guilds_lodge_a2 vs well_b2-guilds_lodge_a1 | 120.4 m vs 125.8 m (4.3 %) |
| F2 | keep_t0-lairs_one_a1 vs keep_t1-lairs_one_b1 | 50.7 m vs 48.5 m (4.3 %) |
| F2 | keep_t0-lairs_one_a1 vs keep_t3-lairs_one_a2 | 50.7 m vs 48.5 m (4.3 %) |
| F2 | keep_t1-cache_a_a1 vs keep_t4-cache_a_a2 | 173.9 m vs 181.7 m (4.3 %) |
| F2 | well_a1-wallow_a2 vs well_b1-wallow_b2 | 115.2 m vs 110.3 m (4.3 %) |
| F2 | well_a1-wallow_a2 vs well_a2-wallow_a1 | 115.2 m vs 110.3 m (4.3 %) |
| F2 | home_b_a2-nat_node_a1 vs home_b_b2-nat_node_b1 | 58.7 m vs 61.3 m (4.3 %) |
| F2 | home_b_b1-nat_node_b2 vs home_b_b2-nat_node_b1 | 58.7 m vs 61.3 m (4.3 %) |
| F2 | home_a_a1-tower_r_b2 vs home_a_a2-tower_r_b1 | 105.8 m vs 101.3 m (4.3 %) |
| F2 | guilds_den_b1-guilds_lodge_a1 vs guilds_den_b2-guilds_lodge_a2 | 249.0 m vs 260.1 m (4.3 %) |
| F2 | peddler_a1-x_lane_e vs peddler_b1-x_lane_w | 82.9 m vs 86.6 m (4.2 %) |
| F2 | peddler_b1-x_lane_w vs peddler_b2-x_lane_w | 86.6 m vs 82.9 m (4.2 %) |
| F2 | well_a2-x_bridge_s vs well_b2-x_bridge_n | 122.3 m vs 127.7 m (4.2 %) |
| F2 | keep_t0-cache_a_b1 vs keep_t1-cache_a_a1 | 181.6 m vs 173.9 m (4.2 %) |
| F2 | keep_t3-cache_a_b2 vs keep_t4-cache_a_a2 | 174.0 m vs 181.7 m (4.2 %) |
| F2 | keep_t0-tower_r_a1 vs keep_t3-tower_r_a2 | 60.7 m vs 63.4 m (4.2 %) |
| F2 | keep_t3-tower_r_a2 vs keep_t4-tower_r_b2 | 63.4 m vs 60.7 m (4.2 %) |
| F2 | keep_t3-third_node_b1 vs keep_t1-third_node_a2 | 160.9 m vs 154.1 m (4.2 %) |
| F2 | rich_node_a1-well_a2 vs rich_node_a2-well_a1 | 114.5 m vs 109.7 m (4.2 %) |
| F2 | rich_node_a1-well_a2 vs rich_node_b1-well_b2 | 114.5 m vs 109.7 m (4.2 %) |
| F2 | stag_a1-lairs_two_b1 vs stag_a2-lairs_two_b2 | 190.4 m vs 182.4 m (4.2 %) |
| F2 | keep_t0-cache_a_b1 vs keep_t3-cache_a_b2 | 181.6 m vs 174.0 m (4.2 %) |
| F2 | well_b1-x_bridge_s vs well_b2-x_bridge_n | 122.3 m vs 127.7 m (4.2 %) |
| F2 | keep_t3-x_lane_e vs keep_t4-x_lane_w | 105.9 m vs 101.5 m (4.2 %) |
| F2 | rich_node_a2-well_a1 vs rich_node_b2-well_b1 | 109.7 m vs 114.5 m (4.2 %) |
| F2 | rich_node_b1-well_b2 vs rich_node_b2-well_b1 | 109.7 m vs 114.5 m (4.2 %) |
| F2 | inn_b1-cache_a_a2 vs inn_b2-cache_a_a1 | 94.6 m vs 90.7 m (4.2 %) |
| F2 | keep_t1-shrine_b1 vs keep_t4-shrine_b2 | 34.6 m vs 36.1 m (4.2 %) |
| F2 | keep_t3-shrine_a2 vs keep_t4-shrine_b2 | 34.6 m vs 36.1 m (4.2 %) |
| F2 | keep_t0-shrine_a1 vs keep_t1-shrine_b1 | 36.1 m vs 34.6 m (4.2 %) |
| F2 | keep_t0-shrine_a1 vs keep_t3-shrine_a2 | 36.1 m vs 34.6 m (4.2 %) |
| F2 | keep_t0-home_a_b1 vs keep_t1-home_a_a1 | 163.6 m vs 156.7 m (4.2 %) |
| F2 | rich_node_b1-lairs_two_b1 vs rich_node_b2-lairs_two_b2 | 42.7 m vs 40.9 m (4.2 %) |
| F2 | rich_node_a1-lairs_two_a1 vs rich_node_b1-lairs_two_b1 | 40.9 m vs 42.7 m (4.2 %) |
| F2 | stag_a1-lairs_two_b1 vs stag_b1-lairs_two_a1 | 190.4 m vs 182.4 m (4.2 %) |
| F2 | rich_node_a1-tower_r_a2 vs rich_node_a2-tower_r_a1 | 119.8 m vs 124.9 m (4.2 %) |
| F2 | rich_node_a2-tower_r_a1 vs rich_node_b2-tower_r_b1 | 124.9 m vs 119.8 m (4.2 %) |
| F2 | peddler_a1-x_lane_e vs peddler_a2-x_lane_e | 82.9 m vs 86.5 m (4.1 %) |
| F2 | peddler_a2-x_lane_e vs peddler_b2-x_lane_w | 86.5 m vs 82.9 m (4.1 %) |
| F2 | inn_a1-cache_a_b2 vs inn_b1-cache_a_a2 | 90.7 m vs 94.6 m (4.1 %) |
| F2 | keep_t0-peddler_b2 vs keep_t1-peddler_a2 | 146.8 m vs 140.7 m (4.1 %) |
| F2 | keep_t3-post_s_b1 vs keep_t4-post_s_a1 | 106.2 m vs 101.8 m (4.1 %) |
| F2 | post_s_a1-x_bridge_n vs post_s_b2-x_bridge_n | 151.8 m vs 158.4 m (4.1 %) |
| F2 | rich_node_a1-shrine_b2 vs rich_node_b2-shrine_a1 | 78.8 m vs 82.2 m (4.1 %) |
| F2 | keep_t0-peddler_b2 vs keep_t3-peddler_b1 | 146.8 m vs 140.7 m (4.1 %) |
| F2 | shrine_b1-inn_a1 vs shrine_b2-inn_a2 | 96.2 m vs 92.2 m (4.1 %) |
| F2 | shrine_b1-x_ford_n vs shrine_b2-x_ford_s | 61.8 m vs 64.4 m (4.1 %) |
| F2 | shrine_a2-ford_nest_a2 vs shrine_b2-ford_nest_a1 | 61.8 m vs 64.4 m (4.1 %) |
| F2 | shrine_a2-x_ford_n vs shrine_b2-x_ford_s | 61.8 m vs 64.4 m (4.1 %) |
| F2 | shrine_b1-ford_nest_a2 vs shrine_b2-ford_nest_a1 | 61.8 m vs 64.4 m (4.1 %) |
| F2 | keep_t0-post_s_b2 vs keep_t3-post_s_b1 | 101.8 m vs 106.2 m (4.1 %) |
| F2 | shrine_a1-ford_nest_a1 vs shrine_a2-ford_nest_a2 | 64.4 m vs 61.8 m (4.1 %) |
| F2 | shrine_a1-ford_nest_a1 vs shrine_b1-ford_nest_a2 | 64.4 m vs 61.8 m (4.1 %) |
| F2 | shrine_a1-x_ford_s vs shrine_a2-x_ford_n | 64.4 m vs 61.8 m (4.1 %) |
| F2 | shrine_a1-x_ford_s vs shrine_b1-x_ford_n | 64.4 m vs 61.8 m (4.1 %) |
| F2 | well_b1-wallow_b2 vs well_b2-wallow_b1 | 110.3 m vs 115.1 m (4.1 %) |
| F2 | well_a2-wallow_a1 vs well_b2-wallow_b1 | 110.3 m vs 115.1 m (4.1 %) |
| F2 | keep_t0-home_b_b1 vs keep_t4-home_b_a2 | 157.4 m vs 164.1 m (4.1 %) |
| F2 | keep_t1-home_b_a1 vs keep_t4-home_b_a2 | 157.4 m vs 164.1 m (4.1 %) |
| F2 | home_a_a2-tower_r_b1 vs home_a_b2-tower_r_a1 | 101.3 m vs 105.7 m (4.1 %) |
| F2 | inn_a2-cache_a_b1 vs inn_b2-cache_a_a1 | 94.5 m vs 90.7 m (4.1 %) |
| F2 | third_node_b1-cache_a_b2 vs third_node_b2-cache_a_b1 | 137.1 m vs 131.5 m (4.1 %) |
| F2 | third_node_a1-cache_a_a2 vs third_node_b1-cache_a_b2 | 131.5 m vs 137.1 m (4.1 %) |
| F2 | third_node_a2-cache_a_a1 vs third_node_b2-cache_a_b1 | 137.1 m vs 131.5 m (4.1 %) |
| F2 | third_node_a1-cache_a_a2 vs third_node_a2-cache_a_a1 | 131.5 m vs 137.1 m (4.1 %) |
| F2 | shrine_b1-inn_a2 vs shrine_b2-inn_a1 | 96.5 m vs 92.5 m (4.1 %) |
| F2 | shrine_a1-inn_b2 vs shrine_b1-inn_a2 | 92.5 m vs 96.5 m (4.1 %) |
| F2 | tower_c_a2-wallow_a1 vs tower_c_b2-wallow_b1 | 84.6 m vs 81.1 m (4.1 %) |
| F2 | tower_c_b1-wallow_b2 vs tower_c_b2-wallow_b1 | 84.6 m vs 81.1 m (4.1 %) |
| F2 | inn_a2-lairs_two_b2 vs inn_b2-lairs_two_a2 | 130.2 m vs 135.7 m (4.1 %) |
| F2 | inn_a1-cache_a_b2 vs inn_a2-cache_a_b1 | 90.7 m vs 94.5 m (4.1 %) |
| F2 | inn_b1-guilds_den_a2 vs inn_b2-guilds_den_a1 | 123.1 m vs 128.3 m (4.1 %) |
| F2 | shrine_a2-guilds_den_b2 vs shrine_b1-guilds_den_a1 | 171.5 m vs 164.5 m (4.1 %) |
| F2 | rich_node_a1-shrine_b2 vs rich_node_a2-shrine_b1 | 78.8 m vs 82.1 m (4.1 %) |
| F2 | well_a1-lairs_one_a2 vs well_b1-lairs_one_b2 | 142.8 m vs 137.0 m (4.1 %) |
| F2 | well_a1-lairs_one_a2 vs well_a2-lairs_one_a1 | 142.8 m vs 137.0 m (4.1 %) |
| F2 | tower_c_a1-wallow_a2 vs tower_c_a2-wallow_a1 | 81.1 m vs 84.6 m (4.0 %) |
| F2 | tower_c_a1-wallow_a2 vs tower_c_b1-wallow_b2 | 81.1 m vs 84.6 m (4.0 %) |
| F2 | well_a2-lairs_one_a1 vs well_b2-lairs_one_b1 | 137.0 m vs 142.8 m (4.0 %) |
| F2 | well_b1-lairs_one_b2 vs well_b2-lairs_one_b1 | 137.0 m vs 142.8 m (4.0 %) |
| F2 | shrine_a2-inn_b2 vs shrine_b2-inn_a2 | 96.1 m vs 92.2 m (4.0 %) |
| F2 | rich_node_a1-shrine_b2 vs rich_node_b1-shrine_a2 | 78.8 m vs 82.1 m (4.0 %) |
| F2 | tower_c_a1-post_s_b2 vs tower_c_b2-post_s_a1 | 85.4 m vs 82.0 m (4.0 %) |
| F2 | rich_node_a1-post_s_a2 vs rich_node_a2-post_s_a1 | 132.6 m vs 138.1 m (4.0 %) |
| F2 | rich_node_a2-post_s_a1 vs rich_node_b2-post_s_b1 | 138.1 m vs 132.6 m (4.0 %) |
| F2 | home_a_a2-post_s_b1 vs home_a_b2-post_s_a1 | 107.9 m vs 112.4 m (4.0 %) |
| F2 | inn_a1-guilds_den_b2 vs inn_b1-guilds_den_a2 | 128.3 m vs 123.1 m (4.0 %) |
| F2 | home_b_a2-tower_r_b1 vs home_b_b2-tower_r_a1 | 94.2 m vs 90.5 m (4.0 %) |
| F2 | home_a_b1-post_s_a2 vs home_a_b2-post_s_a1 | 107.9 m vs 112.4 m (4.0 %) |
| F2 | inn_b1-lairs_two_a1 vs inn_b2-lairs_two_a2 | 130.3 m vs 135.7 m (4.0 %) |
| F2 | cache_b_a2-lairs_two_b2 vs cache_b_b2-lairs_two_a2 | 132.0 m vs 137.5 m (4.0 %) |
| F2 | shrine_b1-post_s_a1 vs shrine_b2-post_s_a2 | 128.7 m vs 123.6 m (4.0 %) |
| F2 | home_a_a2-cache_b_a2 vs home_a_b1-cache_b_b1 | 72.5 m vs 69.6 m (4.0 %) |
| F2 | keep_t1-post_w_a1 vs keep_t4-post_w_a2 | 164.6 m vs 171.5 m (4.0 %) |
| F2 | shrine_a2-inn_b1 vs shrine_b2-inn_a1 | 96.4 m vs 92.5 m (4.0 %) |
| F2 | shrine_a1-inn_b2 vs shrine_a2-inn_b1 | 92.5 m vs 96.4 m (4.0 %) |
| F2 | home_b_a2-inn_b2 vs home_b_b2-inn_a2 | 127.5 m vs 122.4 m (4.0 %) |
| F2 | tower_c_a1-guilds_den_b2 vs tower_c_b2-guilds_den_a1 | 138.7 m vs 133.2 m (4.0 %) |
| F2 | keep_t0-post_w_b1 vs keep_t4-post_w_a2 | 164.7 m vs 171.5 m (4.0 %) |
| F2 | tower_c_a1-cache_a_b2 vs tower_c_b1-cache_a_a2 | 95.8 m vs 99.7 m (4.0 %) |
| F2 | home_a_a1-cache_b_a1 vs home_a_a2-cache_b_a2 | 69.6 m vs 72.5 m (3.9 %) |
| F2 | home_a_a2-cache_b_a2 vs home_a_b2-cache_b_b2 | 72.5 m vs 69.6 m (3.9 %) |
| F2 | cache_b_b1-lairs_two_a1 vs cache_b_b2-lairs_two_a2 | 132.1 m vs 137.5 m (3.9 %) |
| F2 | nat_node_a1-lairs_two_b1 vs nat_node_a2-lairs_two_b2 | 146.6 m vs 140.8 m (3.9 %) |
| F2 | tower_c_b1-cache_a_a2 vs tower_c_b2-cache_a_a1 | 99.7 m vs 95.8 m (3.9 %) |
| F2 | stag_a1-x_bridge_n vs stag_b2-x_bridge_n | 144.8 m vs 150.7 m (3.9 %) |
| F2 | inn_a2-guilds_den_b1 vs inn_b2-guilds_den_a1 | 123.3 m vs 128.3 m (3.9 %) |
| F2 | tower_r_a1-well_b1 vs tower_r_b2-well_a2 | 134.6 m vs 140.0 m (3.9 %) |
| F2 | stag_a1-stag_a2 vs stag_b2-stag_b1 | 150.1 m vs 156.2 m (3.9 %) |
| F2 | keep_t0-home_a_b2 vs keep_t1-home_a_a2 | 156.4 m vs 150.3 m (3.9 %) |
| F2 | shrine_a2-post_s_a1 vs shrine_b2-post_s_b1 | 97.6 m vs 93.8 m (3.9 %) |
| F2 | shrine_b1-post_s_b2 vs shrine_b2-post_s_b1 | 97.6 m vs 93.8 m (3.9 %) |
| F2 | shrine_a1-post_s_a2 vs shrine_b1-post_s_b2 | 93.8 m vs 97.6 m (3.9 %) |
| F2 | shrine_a1-post_s_a2 vs shrine_a2-post_s_a1 | 93.8 m vs 97.6 m (3.9 %) |
| F2 | keep_t0-home_a_b2 vs keep_t3-home_a_b1 | 156.4 m vs 150.3 m (3.9 %) |
| F2 | rich_node_a1-post_s_b1 vs rich_node_b1-post_s_a1 | 143.0 m vs 148.8 m (3.9 %) |
| F2 | guilds_den_a1-lairs_one_b1 vs guilds_den_b1-lairs_one_a1 | 244.0 m vs 234.5 m (3.9 %) |
| F2 | keep_t1-third_node_a2 vs keep_t4-third_node_a1 | 154.1 m vs 160.4 m (3.9 %) |
| F2 | keep_t0-third_node_b2 vs keep_t1-third_node_a2 | 160.4 m vs 154.1 m (3.9 %) |
| F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_b1-cache_a_b2 | 139.1 m vs 144.7 m (3.9 %) |
| F2 | guilds_lodge_b1-cache_a_b2 vs guilds_lodge_b2-cache_a_b1 | 144.7 m vs 139.1 m (3.9 %) |
| F2 | guilds_lodge_a2-cache_a_a1 vs guilds_lodge_b2-cache_a_b1 | 144.7 m vs 139.1 m (3.9 %) |
| F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_a2-cache_a_a1 | 139.1 m vs 144.7 m (3.9 %) |
| F2 | rich_node_a1-post_s_b1 vs rich_node_a2-post_s_b2 | 143.0 m vs 148.8 m (3.9 %) |
| F2 | inn_a1-guilds_den_b2 vs inn_a2-guilds_den_b1 | 128.3 m vs 123.3 m (3.9 %) |
| F2 | guilds_den_a1-lairs_one_b1 vs guilds_den_a2-lairs_one_b2 | 244.0 m vs 234.6 m (3.9 %) |
| F2 | home_b_a2-nat_node_b2 vs home_b_b2-nat_node_a2 | 130.3 m vs 125.3 m (3.9 %) |
| F2 | rich_node_a1-wallow_b2 vs rich_node_b1-wallow_a2 | 100.6 m vs 104.6 m (3.8 %) |
| F2 | ford_nest_a1-stag_b1 vs ford_nest_a2-stag_a1 | 125.6 m vs 120.8 m (3.8 %) |
| F2 | shrine_a1-post_s_b1 vs shrine_b1-post_s_a1 | 123.8 m vs 128.7 m (3.8 %) |
| F2 | home_a_a1-stag_a2 vs home_a_a2-stag_a1 | 103.1 m vs 107.2 m (3.8 %) |
| F2 | home_a_a2-stag_a1 vs home_a_b2-stag_b1 | 107.2 m vs 103.1 m (3.8 %) |
| F2 | home_a_a1-stag_a2 vs home_a_b1-stag_b2 | 103.1 m vs 107.2 m (3.8 %) |
| F2 | home_a_b1-stag_b2 vs home_a_b2-stag_b1 | 107.2 m vs 103.1 m (3.8 %) |
| F2 | tower_c_a1-cache_a_b2 vs tower_c_a2-cache_a_b1 | 95.8 m vs 99.6 m (3.8 %) |
| F2 | cache_b_a2-x_bridge_n vs cache_b_b2-x_bridge_s | 41.0 m vs 42.7 m (3.8 %) |
| F2 | shrine_a1-cache_b_b2 vs shrine_b1-cache_b_a2 | 78.8 m vs 75.8 m (3.8 %) |
| F2 | home_a_a2-wallow_b2 vs home_a_b1-wallow_a1 | 175.6 m vs 182.6 m (3.8 %) |
| F2 | guilds_den_b1-lairs_one_a1 vs guilds_den_b2-lairs_one_a2 | 234.5 m vs 243.8 m (3.8 %) |
| F2 | tower_c_a2-cache_a_b1 vs tower_c_b2-cache_a_a1 | 99.6 m vs 95.8 m (3.8 %) |
| F2 | rich_node_b1-stag_a1 vs rich_node_b2-stag_a2 | 154.9 m vs 149.0 m (3.8 %) |
| F2 | rich_node_a1-tower_c_b1 vs rich_node_b2-tower_c_a2 | 76.2 m vs 79.2 m (3.8 %) |
| F2 | nat_node_a2-lairs_two_b2 vs nat_node_b2-lairs_two_a2 | 140.8 m vs 146.4 m (3.8 %) |
| F2 | keep_t3-tower_c_b2 vs keep_t4-tower_c_a2 | 118.6 m vs 114.1 m (3.8 %) |
| F2 | lairs_two_a1-lairs_two_a2 vs lairs_two_b2-lairs_two_b1 | 168.6 m vs 162.3 m (3.8 %) |
| F2 | guilds_den_a2-lairs_one_b2 vs guilds_den_b2-lairs_one_a2 | 234.6 m vs 243.8 m (3.8 %) |
| F2 | keep_t3-tower_c_b1 vs keep_t4-tower_c_a1 | 118.9 m vs 114.4 m (3.8 %) |
| F2 | rich_node_a1-tower_c_b1 vs rich_node_a2-tower_c_b2 | 76.2 m vs 79.2 m (3.8 %) |
| F2 | ford_nest_a1-stag_a2 vs ford_nest_a2-stag_a1 | 125.5 m vs 120.8 m (3.8 %) |
| F2 | wallow_a1-post_s_b1 vs wallow_b1-post_s_a1 | 169.1 m vs 175.7 m (3.8 %) |
| F2 | tower_c_b1-guilds_den_a2 vs tower_c_b2-guilds_den_a1 | 128.2 m vs 133.2 m (3.8 %) |
| F2 | home_a_b1-crown vs home_a_b2-crown | 82.2 m vs 79.1 m (3.8 %) |
| F2 | home_a_a1-crown vs home_a_b1-crown | 79.1 m vs 82.2 m (3.8 %) |
| F2 | keep_t1-post_s_a2 vs keep_t4-post_s_a1 | 105.7 m vs 101.8 m (3.8 %) |
| F2 | rich_node_a2-stag_b2 vs rich_node_b2-stag_a2 | 154.8 m vs 149.0 m (3.7 %) |
| F2 | wallow_b1-post_s_a1 vs wallow_b2-post_s_a2 | 175.7 m vs 169.1 m (3.7 %) |
| F2 | tower_c_a2-post_s_a2 vs tower_c_b2-post_s_b2 | 69.8 m vs 72.5 m (3.7 %) |
| F2 | keep_t0-post_s_b2 vs keep_t1-post_s_a2 | 101.8 m vs 105.7 m (3.7 %) |
| F2 | rich_node_a2-tower_r_a1 vs rich_node_b1-tower_r_b2 | 124.9 m vs 129.8 m (3.7 %) |
| F2 | home_a_a2-guilds_lodge_a2 vs home_a_b2-guilds_lodge_b2 | 50.8 m vs 52.7 m (3.7 %) |
| F2 | home_a_a1-guilds_lodge_a1 vs home_a_a2-guilds_lodge_a2 | 52.7 m vs 50.8 m (3.7 %) |
| F2 | home_a_b1-guilds_lodge_b1 vs home_a_b2-guilds_lodge_b2 | 50.8 m vs 52.7 m (3.7 %) |
| F2 | home_a_a1-guilds_lodge_a1 vs home_a_b1-guilds_lodge_b1 | 52.7 m vs 50.8 m (3.7 %) |
| F2 | rich_node_a1-peddler_b2 vs rich_node_b2-peddler_a1 | 91.0 m vs 94.5 m (3.7 %) |
| F2 | well_a2-post_s_a1 vs well_b2-post_s_b1 | 132.9 m vs 138.0 m (3.7 %) |
| F2 | well_b1-post_s_b2 vs well_b2-post_s_b1 | 132.9 m vs 138.0 m (3.7 %) |
| F2 | keep_t0-wallow_b1 vs keep_t4-wallow_a2 | 175.2 m vs 182.0 m (3.7 %) |
| F2 | rich_node_a1-lairs_two_b1 vs rich_node_b1-lairs_two_a1 | 159.3 m vs 153.4 m (3.7 %) |
| F2 | ford_nest_a1-post_w_a2 vs ford_nest_a2-post_w_a1 | 97.6 m vs 101.3 m (3.7 %) |
| F2 | ford_nest_a1-post_w_b1 vs ford_nest_a2-post_w_a1 | 97.6 m vs 101.3 m (3.7 %) |
| F2 | keep_t1-wallow_a1 vs keep_t4-wallow_a2 | 175.2 m vs 182.0 m (3.7 %) |
| F2 | keep_t0-rich_node_a2 vs keep_t3-rich_node_a1 | 113.8 m vs 109.6 m (3.7 %) |
| F2 | keep_t0-rich_node_a2 vs keep_t1-rich_node_b2 | 113.8 m vs 109.6 m (3.7 %) |
| F2 | keep_t3-rich_node_a1 vs keep_t4-rich_node_b1 | 109.6 m vs 113.8 m (3.7 %) |
| F2 | keep_t1-rich_node_b2 vs keep_t4-rich_node_b1 | 109.6 m vs 113.8 m (3.7 %) |
| F2 | rich_node_a1-wallow_b2 vs rich_node_b2-wallow_a1 | 100.6 m vs 104.5 m (3.7 %) |
| F2 | ford_nest_a2-post_w_a1 vs ford_nest_a2-post_w_b2 | 101.3 m vs 97.6 m (3.7 %) |
| F2 | stag_b1-post_w_b1 vs stag_b2-post_w_b2 | 81.0 m vs 78.0 m (3.7 %) |
| F2 | stag_a1-post_w_a1 vs stag_b1-post_w_b1 | 78.0 m vs 81.0 m (3.7 %) |
| F2 | cache_b_a1-x_bridge_s vs cache_b_a2-x_bridge_n | 42.6 m vs 41.0 m (3.7 %) |
| F2 | home_a_a1-crown vs home_a_a2-crown | 79.1 m vs 82.1 m (3.7 %) |
| F2 | home_a_a2-crown vs home_a_b2-crown | 82.1 m vs 79.1 m (3.7 %) |
| F2 | tower_c_a1-post_s_b2 vs tower_c_b1-post_s_a2 | 85.4 m vs 82.3 m (3.7 %) |
| F2 | keep_t0-stag_b1 vs keep_t1-stag_a1 | 172.5 m vs 166.1 m (3.7 %) |
| F2 | home_a_a2-tower_r_b1 vs home_a_b1-tower_r_a2 | 101.3 m vs 105.2 m (3.7 %) |
| F2 | tower_c_a2-guilds_den_b1 vs tower_c_b2-guilds_den_a1 | 128.4 m vs 133.2 m (3.7 %) |
| F2 | nat_node_b1-guilds_den_a2 vs nat_node_b2-guilds_den_a1 | 142.3 m vs 147.7 m (3.7 %) |
| F2 | nat_node_a1-guilds_den_b2 vs nat_node_b1-guilds_den_a2 | 147.7 m vs 142.3 m (3.7 %) |
| F2 | cache_a_a1-cache_a_b1 vs cache_a_b2-cache_a_a2 | 173.5 m vs 167.2 m (3.6 %) |
| F2 | lairs_two_a1-lairs_two_b1 vs lairs_two_b2-lairs_two_a2 | 200.2 m vs 193.0 m (3.6 %) |
| F2 | stag_a1-peddler_b1 vs stag_b1-peddler_a1 | 138.3 m vs 143.6 m (3.6 %) |
| F2 | keep_t0-stag_b1 vs keep_t3-stag_b2 | 172.5 m vs 166.2 m (3.6 %) |
| F2 | home_a_a1-post_s_b1 vs home_a_a2-post_s_b2 | 139.3 m vs 144.6 m (3.6 %) |
| F2 | home_a_a2-lairs_two_b1 vs home_a_b1-lairs_two_a2 | 131.5 m vs 136.4 m (3.6 %) |
| F2 | rich_node_a1-lairs_two_b1 vs rich_node_a2-lairs_two_b2 | 159.3 m vs 153.5 m (3.6 %) |
| F2 | stag_a1-cache_a_b1 vs stag_b1-cache_a_a1 | 171.5 m vs 165.3 m (3.6 %) |
| F2 | rich_node_a1-peddler_b2 vs rich_node_a2-peddler_b1 | 91.0 m vs 94.4 m (3.6 %) |
| F2 | home_a_a2-post_s_b2 vs home_a_b2-post_s_a2 | 144.6 m vs 139.4 m (3.6 %) |
| F2 | rich_node_a1-tower_c_b1 vs rich_node_b1-tower_c_a1 | 76.2 m vs 79.0 m (3.6 %) |
| F2 | rich_node_a1-peddler_b2 vs rich_node_b1-peddler_a2 | 91.0 m vs 94.4 m (3.6 %) |
| F2 | keep_t1-tower_r_b1 vs keep_t4-tower_r_b2 | 63.0 m vs 60.7 m (3.6 %) |
| F2 | keep_t0-tower_r_a1 vs keep_t1-tower_r_b1 | 60.7 m vs 63.0 m (3.6 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t1-lairs_one_a1 | 199.9 m vs 192.7 m (3.6 %) |
| F2 | nat_node_b1-cache_a_a2 vs nat_node_b2-cache_a_a1 | 113.8 m vs 109.7 m (3.6 %) |
| F2 | shrine_b1-cache_b_a2 vs shrine_b2-cache_b_a1 | 75.8 m vs 78.6 m (3.6 %) |
| F2 | shrine_a1-cache_b_b2 vs shrine_a2-cache_b_b1 | 78.8 m vs 76.0 m (3.6 %) |
| F2 | home_b_a2-shrine_b2 vs home_b_b2-shrine_a2 | 140.7 m vs 135.7 m (3.6 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_a2-wallow_b2 | 182.1 m vs 175.6 m (3.6 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t3-lairs_one_b2 | 199.9 m vs 192.8 m (3.6 %) |
| F2 | inn_a2-x_bridge_n vs inn_b2-x_bridge_s | 50.9 m vs 52.8 m (3.5 %) |
| F2 | keep_t1-stag_a1 vs keep_t4-stag_a2 | 166.1 m vs 172.2 m (3.5 %) |
| F2 | stag_a1-cache_a_b1 vs stag_a2-cache_a_b2 | 171.5 m vs 165.4 m (3.5 %) |
| F2 | tower_c_a1-post_s_b2 vs tower_c_a2-post_s_b1 | 85.4 m vs 82.4 m (3.5 %) |
| F2 | nat_node_a2-cache_a_b1 vs nat_node_b2-cache_a_a1 | 113.7 m vs 109.7 m (3.5 %) |
| F2 | shrine_a1-shrine_b2 vs shrine_a2-shrine_b1 | 105.8 m vs 109.7 m (3.5 %) |
| F2 | shrine_a2-post_s_a2 vs shrine_b2-post_s_b2 | 74.4 m vs 77.2 m (3.5 %) |
| F2 | shrine_b1-post_s_b1 vs shrine_b2-post_s_b2 | 74.4 m vs 77.2 m (3.5 %) |
| F2 | shrine_a1-post_s_a1 vs shrine_a2-post_s_a2 | 77.2 m vs 74.4 m (3.5 %) |
| F2 | shrine_a1-post_s_a1 vs shrine_b1-post_s_b1 | 77.2 m vs 74.4 m (3.5 %) |
| F2 | home_b_b1-tower_r_a2 vs home_b_b2-tower_r_a1 | 93.8 m vs 90.5 m (3.5 %) |
| F2 | stag_a2-x_bridge_s vs stag_b2-x_bridge_n | 145.4 m vs 150.7 m (3.5 %) |
| F2 | nat_node_a1-cache_a_b2 vs nat_node_b1-cache_a_a2 | 109.8 m vs 113.8 m (3.5 %) |
| F2 | wallow_a1-x_bridge_n vs wallow_b1-x_bridge_s | 144.4 m vs 149.7 m (3.5 %) |
| F2 | wallow_b1-x_bridge_s vs wallow_b2-x_bridge_n | 149.7 m vs 144.4 m (3.5 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_b1-lairs_two_a1 | 163.3 m vs 157.5 m (3.5 %) |
| F2 | nat_node_a2-guilds_den_b1 vs nat_node_b2-guilds_den_a1 | 142.5 m vs 147.7 m (3.5 %) |
| F2 | nat_node_a1-guilds_den_b2 vs nat_node_a2-guilds_den_b1 | 147.7 m vs 142.5 m (3.5 %) |
| F2 | keep_t3-stag_b2 vs keep_t4-stag_a2 | 166.2 m vs 172.2 m (3.5 %) |
| F2 | shrine_a1-shrine_b1 vs shrine_b2-shrine_a2 | 105.5 m vs 109.4 m (3.5 %) |
| F2 | post_w_b1-post_s_b1 vs post_w_b2-post_s_b2 | 92.2 m vs 88.9 m (3.5 %) |
| F2 | post_w_a2-post_s_a2 vs post_w_b2-post_s_b2 | 92.2 m vs 88.9 m (3.5 %) |
| F2 | post_w_a1-post_s_a1 vs post_w_b1-post_s_b1 | 88.9 m vs 92.2 m (3.5 %) |
| F2 | post_w_a1-post_s_a1 vs post_w_a2-post_s_a2 | 88.9 m vs 92.2 m (3.5 %) |
| F2 | stag_b1-x_bridge_s vs stag_b2-x_bridge_n | 145.5 m vs 150.7 m (3.5 %) |
| F2 | wallow_a1-x_bridge_n vs wallow_a2-x_bridge_s | 144.4 m vs 149.7 m (3.5 %) |
| F2 | wallow_a2-x_bridge_s vs wallow_b2-x_bridge_n | 149.7 m vs 144.4 m (3.5 %) |
| F2 | keep_t1-lairs_one_a1 vs keep_t4-lairs_one_a2 | 192.7 m vs 199.7 m (3.5 %) |
| F2 | nat_node_a1-cache_a_b2 vs nat_node_a2-cache_a_b1 | 109.8 m vs 113.7 m (3.5 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_a2-lairs_two_b2 | 163.3 m vs 157.6 m (3.5 %) |
| F2 | inn_b1-x_bridge_n vs inn_b2-x_bridge_s | 50.9 m vs 52.8 m (3.5 %) |
| F2 | tower_r_a1-well_b1 vs tower_r_b1-well_a1 | 134.6 m vs 129.9 m (3.5 %) |
| F2 | third_node_a1-post_s_b1 vs third_node_b1-post_s_a1 | 184.3 m vs 190.9 m (3.5 %) |
| F2 | tower_r_b1-post_s_b2 vs tower_r_b2-post_s_b1 | 151.6 m vs 157.1 m (3.5 %) |
| F2 | tower_r_a1-post_s_a2 vs tower_r_b1-post_s_b2 | 157.1 m vs 151.6 m (3.5 %) |
| F2 | shrine_a2-x_bridge_n vs shrine_b2-x_bridge_s | 74.4 m vs 77.0 m (3.5 %) |
| F2 | keep_t3-inn_b2 vs keep_t4-inn_a2 | 130.7 m vs 126.2 m (3.4 %) |
| F2 | keep_t3-lairs_one_b2 vs keep_t4-lairs_one_a2 | 192.8 m vs 199.7 m (3.4 %) |
| F2 | shrine_b1-x_bridge_n vs shrine_b2-x_bridge_s | 74.4 m vs 77.0 m (3.4 %) |
| F2 | shrine_a1-x_bridge_s vs shrine_a2-x_bridge_n | 77.0 m vs 74.4 m (3.4 %) |
| F2 | inn_a1-x_bridge_s vs inn_a2-x_bridge_n | 52.7 m vs 50.9 m (3.4 %) |
| F2 | third_node_b1-post_s_a1 vs third_node_b2-post_s_a2 | 190.9 m vs 184.3 m (3.4 %) |
| F2 | shrine_a1-x_bridge_s vs shrine_b1-x_bridge_n | 77.0 m vs 74.4 m (3.4 %) |
| F2 | tower_r_a1-well_b1 vs tower_r_a2-well_b2 | 134.6 m vs 129.9 m (3.4 %) |
| F2 | stag_a1-post_s_a2 vs stag_b1-post_s_b2 | 158.2 m vs 163.9 m (3.4 %) |
| F2 | tower_r_a1-tower_r_a2 vs tower_r_b2-tower_r_b1 | 144.3 m vs 139.3 m (3.4 %) |
| F2 | cache_b_b1-x_bridge_n vs cache_b_b2-x_bridge_s | 41.2 m vs 42.7 m (3.4 %) |
| F2 | shrine_a1-inn_b1 vs shrine_b2-inn_a2 | 89.1 m vs 92.2 m (3.4 %) |
| F2 | wallow_b1-stag_b2 vs wallow_b2-stag_b1 | 136.9 m vs 132.3 m (3.4 %) |
| F2 | wallow_a1-stag_a2 vs wallow_b1-stag_b2 | 132.3 m vs 136.9 m (3.4 %) |
| F2 | wallow_a2-stag_a1 vs wallow_b2-stag_b1 | 136.9 m vs 132.3 m (3.4 %) |
| F2 | wallow_a1-stag_a2 vs wallow_a2-stag_a1 | 132.3 m vs 136.9 m (3.4 %) |
| F2 | tower_c_a1-cache_a_b1 vs tower_c_b2-cache_a_a2 | 113.3 m vs 117.3 m (3.4 %) |
| F2 | peddler_b1-lairs_two_a1 vs peddler_b2-lairs_two_a2 | 157.5 m vs 163.0 m (3.4 %) |
| F2 | home_b_a1-tower_r_b2 vs home_b_b2-tower_r_a1 | 93.6 m vs 90.5 m (3.4 %) |
| F2 | keep_t0-post_w_b2 vs keep_t1-post_w_a2 | 164.3 m vs 158.7 m (3.4 %) |
| F2 | post_s_a2-lairs_one_b2 vs post_s_b2-lairs_one_a2 | 192.7 m vs 186.2 m (3.4 %) |
| F2 | keep_t0-post_w_b2 vs keep_t3-post_w_b1 | 164.3 m vs 158.8 m (3.4 %) |
| F2 | stag_a1-peddler_a2 vs stag_a2-peddler_a1 | 101.3 m vs 97.9 m (3.4 %) |
| F2 | stag_a2-peddler_a1 vs stag_b2-peddler_b1 | 97.9 m vs 101.3 m (3.4 %) |
| F2 | home_a_a2-cache_a_b1 vs home_a_b2-cache_a_a1 | 132.0 m vs 136.6 m (3.4 %) |
| F2 | inn_a1-x_bridge_s vs inn_b1-x_bridge_n | 52.7 m vs 50.9 m (3.4 %) |
| F2 | home_a_a2-lairs_two_b1 vs home_a_b2-lairs_two_a1 | 131.5 m vs 136.0 m (3.4 %) |
| F2 | tower_r_a1-x_ford_s vs tower_r_a2-x_ford_n | 33.8 m vs 32.7 m (3.4 %) |
| F2 | tower_r_a1-ford_nest_a1 vs tower_r_a2-ford_nest_a2 | 33.8 m vs 32.7 m (3.4 %) |
| F2 | post_s_b1-lairs_one_a1 vs post_s_b2-lairs_one_a2 | 192.6 m vs 186.2 m (3.4 %) |
| F2 | peddler_a2-lairs_two_b2 vs peddler_b2-lairs_two_a2 | 157.6 m vs 163.0 m (3.3 %) |
| F2 | keep_t3-nat_node_b2 vs keep_t4-nat_node_a2 | 133.6 m vs 129.1 m (3.3 %) |
| F2 | shrine_a1-stag_a2 vs shrine_a2-stag_a1 | 87.0 m vs 90.0 m (3.3 %) |
| F2 | shrine_a1-stag_a2 vs shrine_b1-stag_b2 | 87.0 m vs 90.0 m (3.3 %) |
| F2 | lairs_two_a2-x_ford_n vs lairs_two_b2-x_ford_s | 62.0 m vs 64.1 m (3.3 %) |
| F2 | lairs_two_b1-x_ford_n vs lairs_two_b2-x_ford_s | 62.0 m vs 64.1 m (3.3 %) |
| F2 | keep_t3-post_s_b2 vs keep_t4-post_s_a2 | 158.7 m vs 164.2 m (3.3 %) |
| F2 | keep_t0-well_a2 vs keep_t3-well_a1 | 101.7 m vs 98.3 m (3.3 %) |
| F2 | keep_t3-well_a1 vs keep_t4-well_b1 | 98.3 m vs 101.7 m (3.3 %) |
| F2 | keep_t0-well_a2 vs keep_t1-well_b2 | 101.7 m vs 98.3 m (3.3 %) |
| F2 | keep_t1-well_b2 vs keep_t4-well_b1 | 98.3 m vs 101.7 m (3.3 %) |
| F2 | tower_c_b1-cache_a_a1 vs tower_c_b2-cache_a_a2 | 113.4 m vs 117.3 m (3.3 %) |
| F2 | guilds_den_a2-x_bridge_s vs guilds_den_b2-x_bridge_n | 175.8 m vs 181.8 m (3.3 %) |
| F2 | shrine_a2-cache_b_b1 vs shrine_b2-cache_b_a1 | 76.0 m vs 78.6 m (3.3 %) |
| F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_b1-guilds_lodge_a1 | 257.6 m vs 249.0 m (3.3 %) |
| F2 | guilds_den_a1-x_bridge_n vs guilds_den_a2-x_bridge_s | 181.8 m vs 175.8 m (3.3 %) |
| F2 | cache_b_a1-x_bridge_s vs cache_b_b1-x_bridge_n | 42.6 m vs 41.2 m (3.3 %) |
| F2 | guilds_den_b1-x_bridge_s vs guilds_den_b2-x_bridge_n | 175.8 m vs 181.8 m (3.3 %) |
| F2 | home_a_a1-lairs_two_b2 vs home_a_a2-lairs_two_b1 | 135.9 m vs 131.5 m (3.3 %) |
| F2 | tower_r_a1-x_ford_s vs tower_r_b1-x_ford_n | 33.8 m vs 32.7 m (3.3 %) |
| F2 | tower_r_a1-ford_nest_a1 vs tower_r_b1-ford_nest_a2 | 33.8 m vs 32.7 m (3.3 %) |
| F2 | home_a_a1-cache_a_b2 vs home_a_a2-cache_a_b1 | 136.5 m vs 132.0 m (3.3 %) |
| F2 | guilds_den_a1-x_bridge_n vs guilds_den_b1-x_bridge_s | 181.8 m vs 175.8 m (3.3 %) |
| F2 | post_s_a1-lairs_one_b1 vs post_s_a2-lairs_one_b2 | 186.4 m vs 192.7 m (3.3 %) |
| F2 | rich_node_a2-post_w_b2 vs rich_node_b2-post_w_a2 | 126.2 m vs 122.1 m (3.3 %) |
| F2 | rich_node_b1-post_w_a1 vs rich_node_b2-post_w_a2 | 126.2 m vs 122.1 m (3.3 %) |
| F2 | inn_a2-cache_a_b2 vs inn_b1-cache_a_a1 | 122.5 m vs 126.7 m (3.3 %) |
| F2 | post_s_a1-lairs_one_b1 vs post_s_b1-lairs_one_a1 | 186.4 m vs 192.6 m (3.3 %) |
| F2 | rich_node_a1-inn_b1 vs rich_node_b2-inn_a2 | 89.5 m vs 92.5 m (3.2 %) |
| F2 | keep_t0-post_s_b1 vs keep_t3-post_s_b2 | 164.1 m vs 158.7 m (3.2 %) |
| F2 | wallow_a2-cache_b_a1 vs wallow_b2-cache_b_b1 | 111.8 m vs 108.2 m (3.2 %) |
| F2 | wallow_a1-cache_b_a2 vs wallow_a2-cache_b_a1 | 108.2 m vs 111.8 m (3.2 %) |
| F2 | rich_node_a1-inn_b1 vs rich_node_a2-inn_b2 | 89.5 m vs 92.4 m (3.2 %) |
| F2 | rich_node_a1-shrine_b1 vs rich_node_b2-shrine_a2 | 92.1 m vs 95.1 m (3.2 %) |
| F2 | shrine_b1-peddler_a2 vs shrine_b2-peddler_a1 | 124.2 m vs 120.2 m (3.2 %) |
| F2 | shrine_a1-peddler_b2 vs shrine_b1-peddler_a2 | 120.2 m vs 124.2 m (3.2 %) |
| F2 | home_b_a2-peddler_b2 vs home_b_b2-peddler_a2 | 155.1 m vs 150.2 m (3.2 %) |
| F2 | home_a_b1-x_lane_w vs home_a_b2-x_lane_w | 95.1 m vs 92.1 m (3.2 %) |
| F2 | home_a_a1-x_lane_e vs home_a_b1-x_lane_w | 92.1 m vs 95.1 m (3.2 %) |
| F2 | inn_a1-cache_a_b1 vs inn_a2-cache_a_b2 | 126.6 m vs 122.5 m (3.2 %) |
| F2 | third_node_a1-x_bridge_n vs third_node_b1-x_bridge_s | 159.6 m vs 164.9 m (3.2 %) |
| F2 | third_node_b1-x_bridge_s vs third_node_b2-x_bridge_n | 164.9 m vs 159.6 m (3.2 %) |
| F2 | peddler_b1-cache_a_a2 vs peddler_b2-cache_a_a1 | 126.7 m vs 122.7 m (3.2 %) |
| F2 | rich_node_a1-cache_b_b1 vs rich_node_b2-cache_b_a2 | 91.3 m vs 94.2 m (3.2 %) |
| F2 | inn_a1-post_s_a1 vs inn_a2-post_s_a2 | 59.3 m vs 57.4 m (3.2 %) |
| F2 | inn_a2-post_s_a2 vs inn_b2-post_s_b2 | 57.4 m vs 59.3 m (3.2 %) |
| F2 | inn_a1-post_s_a1 vs inn_b1-post_s_b1 | 59.3 m vs 57.4 m (3.2 %) |
| F2 | inn_b1-post_s_b1 vs inn_b2-post_s_b2 | 57.4 m vs 59.3 m (3.2 %) |
| F2 | stag_a1-x_ford_s vs stag_b1-x_ford_n | 52.2 m vs 50.6 m (3.2 %) |
| F2 | stag_a1-x_ford_s vs stag_a2-x_ford_n | 52.2 m vs 50.6 m (3.2 %) |
| F2 | home_b_a1-lairs_two_b1 vs home_b_b1-lairs_two_a1 | 181.3 m vs 175.6 m (3.2 %) |
| F2 | third_node_a1-x_bridge_n vs third_node_a2-x_bridge_s | 159.6 m vs 164.8 m (3.2 %) |
| F2 | third_node_a2-x_bridge_s vs third_node_b2-x_bridge_n | 164.8 m vs 159.6 m (3.2 %) |
| F2 | shrine_b1-peddler_a1 vs shrine_b2-peddler_a2 | 123.9 m vs 120.0 m (3.2 %) |
| F2 | post_s_a1-cache_a_a1 vs post_s_a2-cache_a_a2 | 34.4 m vs 33.3 m (3.1 %) |
| F2 | post_s_a1-cache_a_a1 vs post_s_b1-cache_a_b1 | 34.4 m vs 33.3 m (3.1 %) |
| F2 | post_s_b1-cache_a_b1 vs post_s_b2-cache_a_b2 | 33.3 m vs 34.4 m (3.1 %) |
| F2 | post_s_a2-cache_a_a2 vs post_s_b2-cache_a_b2 | 33.3 m vs 34.4 m (3.1 %) |
| F2 | home_a_a1-x_lane_e vs home_a_a2-x_lane_e | 92.1 m vs 95.1 m (3.1 %) |
| F2 | home_a_a2-x_lane_e vs home_a_b2-x_lane_w | 95.1 m vs 92.1 m (3.1 %) |
| F2 | shrine_a2-peddler_b1 vs shrine_b2-peddler_a1 | 124.1 m vs 120.2 m (3.1 %) |
| F2 | shrine_a1-peddler_b2 vs shrine_a2-peddler_b1 | 120.2 m vs 124.1 m (3.1 %) |
| F2 | rich_node_a1-cache_b_b1 vs rich_node_a2-cache_b_b2 | 91.3 m vs 94.2 m (3.1 %) |
| F2 | stag_a1-lairs_two_b1 vs stag_b2-lairs_two_a2 | 190.4 m vs 196.5 m (3.1 %) |
| F2 | wallow_b1-peddler_b2 vs wallow_b2-peddler_b1 | 73.0 m vs 70.7 m (3.1 %) |
| F2 | wallow_a2-peddler_a1 vs wallow_b2-peddler_b1 | 73.0 m vs 70.7 m (3.1 %) |
| F2 | wallow_a1-peddler_a2 vs wallow_a2-peddler_a1 | 70.7 m vs 73.0 m (3.1 %) |
| F2 | wallow_a1-peddler_a2 vs wallow_b1-peddler_b2 | 70.7 m vs 73.0 m (3.1 %) |
| F2 | home_b_a1-lairs_two_b1 vs home_b_a2-lairs_two_b2 | 181.3 m vs 175.6 m (3.1 %) |
| F2 | rich_node_a1-post_w_b2 vs rich_node_b2-post_w_a1 | 109.1 m vs 112.6 m (3.1 %) |
| F2 | peddler_a1-cache_a_b2 vs peddler_b1-cache_a_a2 | 122.8 m vs 126.7 m (3.1 %) |
| F2 | stag_a1-cache_a_b1 vs stag_b2-cache_a_a2 | 171.5 m vs 166.2 m (3.1 %) |
| F2 | tower_r_a1-well_a2 vs tower_r_a2-well_a1 | 123.1 m vs 119.2 m (3.1 %) |
| F2 | tower_r_a1-well_a2 vs tower_r_b1-well_b2 | 123.1 m vs 119.2 m (3.1 %) |
| F2 | stag_a1-post_s_a2 vs stag_a2-post_s_a1 | 158.2 m vs 163.3 m (3.1 %) |
| F2 | lairs_two_a1-x_ford_s vs lairs_two_b2-x_ford_s | 62.1 m vs 64.1 m (3.1 %) |
| F2 | keep_t3-shrine_b2 vs keep_t4-shrine_a2 | 144.0 m vs 139.5 m (3.1 %) |
| F2 | tower_r_a2-well_a1 vs tower_r_b2-well_b1 | 119.2 m vs 123.1 m (3.1 %) |
| F2 | tower_r_b1-well_b2 vs tower_r_b2-well_b1 | 119.2 m vs 123.1 m (3.1 %) |
| F2 | keep_t0-guilds_lodge_b1 vs keep_t3-guilds_lodge_b2 | 216.2 m vs 209.5 m (3.1 %) |
| F2 | keep_t0-guilds_lodge_b1 vs keep_t1-guilds_lodge_a1 | 216.2 m vs 209.5 m (3.1 %) |
| F2 | shrine_a1-guilds_den_b1 vs shrine_b1-guilds_den_a1 | 169.8 m vs 164.5 m (3.1 %) |
| F2 | rich_node_a1-inn_b1 vs rich_node_b1-inn_a1 | 89.5 m vs 92.3 m (3.1 %) |
| F2 | shrine_a2-peddler_b2 vs shrine_b2-peddler_a2 | 123.8 m vs 120.0 m (3.1 %) |
| F2 | well_a2-post_w_b2 vs well_b1-post_w_a1 | 137.6 m vs 133.4 m (3.1 %) |
| F2 | tower_c_b1-post_s_b2 vs tower_c_b2-post_s_b1 | 92.3 m vs 95.2 m (3.1 %) |
| F2 | tower_c_a1-post_s_a2 vs tower_c_b1-post_s_b2 | 95.2 m vs 92.3 m (3.1 %) |
| F2 | tower_c_a2-post_s_a1 vs tower_c_b2-post_s_b1 | 92.3 m vs 95.2 m (3.1 %) |
| F2 | tower_c_a1-post_s_a2 vs tower_c_a2-post_s_a1 | 95.2 m vs 92.3 m (3.1 %) |
| F2 | inn_a1-cache_a_b1 vs inn_b2-cache_a_a2 | 126.6 m vs 130.6 m (3.1 %) |
| F2 | guilds_lodge_a1-x_bridge_n vs guilds_lodge_b1-x_bridge_s | 167.2 m vs 172.4 m (3.1 %) |
| F2 | guilds_lodge_b1-x_bridge_s vs guilds_lodge_b2-x_bridge_n | 172.4 m vs 167.2 m (3.1 %) |
| F2 | home_b_b1-lairs_two_a1 vs home_b_b2-lairs_two_a2 | 175.6 m vs 181.1 m (3.1 %) |
| F2 | keep_t0-tower_r_a2 vs keep_t3-tower_r_a1 | 121.1 m vs 117.4 m (3.0 %) |
| F2 | keep_t0-tower_r_a2 vs keep_t1-tower_r_b2 | 121.1 m vs 117.4 m (3.0 %) |
| F2 | keep_t3-tower_r_a1 vs keep_t4-tower_r_b1 | 117.4 m vs 121.1 m (3.0 %) |
| F2 | keep_t1-tower_r_b2 vs keep_t4-tower_r_b1 | 117.4 m vs 121.1 m (3.0 %) |
| F2 | lairs_one_a1-x_ford_n vs lairs_one_b1-x_ford_s | 138.3 m vs 142.6 m (3.0 %) |
| F2 | tower_c_a1-lairs_two_b1 vs tower_c_b2-lairs_two_a2 | 118.7 m vs 122.4 m (3.0 %) |
| F2 | well_a2-post_w_b2 vs well_b2-post_w_a2 | 137.6 m vs 133.4 m (3.0 %) |
| F2 | keep_t3-guilds_lodge_b2 vs keep_t4-guilds_lodge_a2 | 209.5 m vs 216.0 m (3.0 %) |
| F2 | keep_t1-guilds_lodge_a1 vs keep_t4-guilds_lodge_a2 | 209.5 m vs 216.0 m (3.0 %) |
| F2 | keep_t0-peddler_a2 vs keep_t3-peddler_a1 | 61.8 m vs 59.9 m (3.0 %) |
| F2 | keep_t0-peddler_a2 vs keep_t1-peddler_b2 | 61.8 m vs 59.9 m (3.0 %) |
| F2 | keep_t3-peddler_a1 vs keep_t4-peddler_b1 | 59.9 m vs 61.8 m (3.0 %) |
| F2 | keep_t1-peddler_b2 vs keep_t4-peddler_b1 | 59.9 m vs 61.8 m (3.0 %) |
| F2 | lairs_one_b1-x_ford_s vs lairs_one_b2-x_ford_n | 142.6 m vs 138.3 m (3.0 %) |
| F2 | rich_node_a1-post_w_b2 vs rich_node_a2-post_w_b1 | 109.1 m vs 112.5 m (3.0 %) |
| F2 | guilds_lodge_a1-x_bridge_n vs guilds_lodge_a2-x_bridge_s | 167.2 m vs 172.4 m (3.0 %) |
| F2 | guilds_lodge_a2-x_bridge_s vs guilds_lodge_b2-x_bridge_n | 172.4 m vs 167.2 m (3.0 %) |
| F2 | home_b_a2-lairs_two_b2 vs home_b_b2-lairs_two_a2 | 175.6 m vs 181.1 m (3.0 %) |
| F2 | rich_node_a1-post_w_b2 vs rich_node_b1-post_w_a2 | 109.1 m vs 112.4 m (3.0 %) |
| F2 | lairs_one_a1-x_ford_n vs lairs_one_a2-x_ford_s | 138.3 m vs 142.6 m (3.0 %) |
| F2 | wallow_a1-post_s_b1 vs wallow_a2-post_s_b2 | 169.1 m vs 174.4 m (3.0 %) |
| F2 | lairs_one_a2-x_ford_s vs lairs_one_b2-x_ford_n | 142.6 m vs 138.3 m (3.0 %) |
| F2 | inn_b1-cache_a_a1 vs inn_b2-cache_a_a2 | 126.7 m vs 130.6 m (3.0 %) |
| F2 | wallow_a2-post_s_b2 vs wallow_b2-post_s_a2 | 174.4 m vs 169.1 m (3.0 %) |
| F2 | rich_node_a1-cache_b_b1 vs rich_node_b1-cache_b_a1 | 91.3 m vs 94.1 m (3.0 %) |
| F2 | inn_a2-lairs_one_b1 vs inn_b2-lairs_one_a1 | 112.8 m vs 109.5 m (3.0 %) |
| F2 | tower_r_a1-lairs_one_b1 vs tower_r_b2-lairs_one_a2 | 174.3 m vs 179.7 m (3.0 %) |
| F2 | keep_t0-shrine_b2 vs keep_t3-shrine_b1 | 132.4 m vs 128.5 m (3.0 %) |
| F2 | shrine_a2-post_s_b2 vs shrine_b2-post_s_a2 | 127.4 m vs 123.6 m (3.0 %) |
| F2 | shrine_b1-guilds_den_a1 vs shrine_b2-guilds_den_a2 | 164.5 m vs 169.5 m (3.0 %) |
| F2 | inn_a1-lairs_one_b2 vs inn_a2-lairs_one_b1 | 109.5 m vs 112.8 m (2.9 %) |
| F2 | home_a_a1-third_node_a1 vs home_a_a2-third_node_a2 | 43.3 m vs 42.1 m (2.9 %) |
| F2 | home_a_a2-third_node_a2 vs home_a_b2-third_node_b2 | 42.1 m vs 43.3 m (2.9 %) |
| F2 | home_a_a1-third_node_a1 vs home_a_b1-third_node_b1 | 43.3 m vs 42.1 m (2.9 %) |
| F2 | home_a_b1-third_node_b1 vs home_a_b2-third_node_b2 | 42.1 m vs 43.3 m (2.9 %) |
| F2 | ford_nest_a1-lairs_two_b2 vs ford_nest_a2-lairs_two_a2 | 62.0 m vs 63.9 m (2.9 %) |
| F2 | ford_nest_a1-lairs_two_a1 vs ford_nest_a2-lairs_two_a2 | 62.0 m vs 63.9 m (2.9 %) |
| F2 | ford_nest_a1-post_s_a2 vs ford_nest_a2-post_s_a1 | 121.6 m vs 125.3 m (2.9 %) |
| F2 | keep_t3-shrine_b1 vs keep_t1-shrine_a2 | 128.5 m vs 132.3 m (2.9 %) |
| F2 | post_w_a2-lairs_two_b1 vs post_w_b1-lairs_two_a2 | 144.8 m vs 149.2 m (2.9 %) |
| F2 | guilds_den_a1-cache_b_b1 vs guilds_den_b1-cache_b_a1 | 157.6 m vs 153.0 m (2.9 %) |
| F2 | guilds_den_a1-cache_b_b1 vs guilds_den_a2-cache_b_b2 | 157.6 m vs 153.0 m (2.9 %) |
| F2 | peddler_a2-lairs_two_b1 vs peddler_b1-lairs_two_a2 | 124.6 m vs 128.3 m (2.9 %) |
| F2 | rich_node_a1-third_node_a1 vs rich_node_a2-third_node_a2 | 64.4 m vs 66.4 m (2.9 %) |
| F2 | rich_node_a2-third_node_a2 vs rich_node_b2-third_node_b2 | 66.4 m vs 64.4 m (2.9 %) |
| F2 | nat_node_b1-cache_a_a1 vs nat_node_b2-cache_a_a2 | 137.1 m vs 141.2 m (2.9 %) |
| F2 | nat_node_a1-x_bridge_n vs nat_node_a2-x_bridge_s | 92.2 m vs 89.5 m (2.9 %) |
| F2 | home_b_a2-post_w_b2 vs home_b_b2-post_w_a2 | 172.6 m vs 167.7 m (2.9 %) |
| F2 | rich_node_a1-lairs_one_a2 vs rich_node_a2-lairs_one_a1 | 153.3 m vs 148.9 m (2.9 %) |
| F2 | rich_node_a1-lairs_one_a2 vs rich_node_b1-lairs_one_b2 | 153.3 m vs 148.9 m (2.9 %) |
| F2 | home_a_a1-tower_c_b1 vs home_a_b1-tower_c_a1 | 104.7 m vs 107.8 m (2.9 %) |
| F2 | home_a_b1-tower_c_a1 vs home_a_b2-tower_c_a2 | 107.8 m vs 104.7 m (2.9 %) |
| F2 | shrine_b1-wallow_a2 vs shrine_b2-wallow_a1 | 141.9 m vs 146.1 m (2.9 %) |
| F2 | shrine_a2-wallow_b1 vs shrine_b2-wallow_a1 | 141.9 m vs 146.1 m (2.9 %) |
| F2 | shrine_a1-wallow_b2 vs shrine_a2-wallow_b1 | 146.1 m vs 141.9 m (2.9 %) |
| F2 | shrine_a1-wallow_b2 vs shrine_b1-wallow_a2 | 146.1 m vs 141.9 m (2.9 %) |
| F2 | stag_a1-x_ford_s vs stag_b2-x_ford_s | 52.2 m vs 53.8 m (2.9 %) |
| F2 | ford_nest_a1-lairs_two_b2 vs ford_nest_a2-lairs_two_b1 | 62.0 m vs 63.8 m (2.9 %) |
| F2 | ford_nest_a1-lairs_two_a1 vs ford_nest_a2-lairs_two_b1 | 62.0 m vs 63.8 m (2.9 %) |
| F2 | home_a_b1-tower_c_a2 vs home_a_b2-tower_c_a1 | 108.1 m vs 105.0 m (2.9 %) |
| F2 | home_a_a1-tower_c_b2 vs home_a_b1-tower_c_a2 | 105.0 m vs 108.1 m (2.9 %) |
| F2 | rich_node_a2-lairs_one_a1 vs rich_node_b2-lairs_one_b1 | 148.9 m vs 153.3 m (2.9 %) |
| F2 | rich_node_b1-lairs_one_b2 vs rich_node_b2-lairs_one_b1 | 148.9 m vs 153.3 m (2.9 %) |
| F2 | nat_node_a1-cache_a_b1 vs nat_node_b1-cache_a_a1 | 141.2 m vs 137.1 m (2.9 %) |
| F2 | ford_nest_a1-post_s_b1 vs ford_nest_a2-post_s_a1 | 121.7 m vs 125.3 m (2.9 %) |
| F2 | post_w_a1-guilds_den_b1 vs post_w_b1-guilds_den_a1 | 191.3 m vs 196.9 m (2.8 %) |
| F2 | nat_node_a2-cache_a_b2 vs nat_node_b2-cache_a_a2 | 137.2 m vs 141.2 m (2.8 %) |
| F2 | post_w_a1-guilds_den_b1 vs post_w_a2-guilds_den_b2 | 191.3 m vs 196.9 m (2.8 %) |
| F2 | home_b_a1-stag_a2 vs home_b_a2-stag_a1 | 116.0 m vs 119.4 m (2.8 %) |
| F2 | home_b_a2-stag_a1 vs home_b_b2-stag_b1 | 119.4 m vs 116.0 m (2.8 %) |
| F2 | home_b_b1-stag_b2 vs home_b_b2-stag_b1 | 119.4 m vs 116.0 m (2.8 %) |
| F2 | home_b_a1-stag_a2 vs home_b_b1-stag_b2 | 116.0 m vs 119.4 m (2.8 %) |
| F2 | shrine_b1-post_w_a2 vs shrine_b2-post_w_a1 | 141.7 m vs 137.7 m (2.8 %) |
| F2 | shrine_a1-post_w_b2 vs shrine_b1-post_w_a2 | 137.7 m vs 141.7 m (2.8 %) |
| F2 | well_a1-post_w_b1 vs well_a2-post_w_b2 | 133.7 m vs 137.6 m (2.8 %) |
| F2 | wallow_a1-cache_b_a2 vs wallow_b1-cache_b_b2 | 108.2 m vs 111.4 m (2.8 %) |
| F2 | wallow_b1-cache_b_b2 vs wallow_b2-cache_b_b1 | 111.4 m vs 108.2 m (2.8 %) |
| F2 | nat_node_a1-x_bridge_n vs nat_node_b1-x_bridge_s | 92.2 m vs 89.6 m (2.8 %) |
| F2 | inn_b1-lairs_one_a2 vs inn_b2-lairs_one_a1 | 112.7 m vs 109.5 m (2.8 %) |
| F2 | rich_node_a1-shrine_b1 vs rich_node_a2-shrine_b2 | 92.1 m vs 94.7 m (2.8 %) |
| F2 | home_a_a1-tower_c_b1 vs home_a_a2-tower_c_b2 | 104.7 m vs 107.8 m (2.8 %) |
| F2 | home_a_a2-tower_c_b2 vs home_a_b2-tower_c_a2 | 107.8 m vs 104.7 m (2.8 %) |
| F2 | stag_a1-peddler_a2 vs stag_b1-peddler_b2 | 101.3 m vs 98.5 m (2.8 %) |
| F2 | stag_b1-peddler_b2 vs stag_b2-peddler_b1 | 98.5 m vs 101.3 m (2.8 %) |
| F2 | post_w_b1-guilds_den_a1 vs post_w_b2-guilds_den_a2 | 196.9 m vs 191.4 m (2.8 %) |
| F2 | rich_node_a2-post_s_a1 vs rich_node_b1-post_s_b2 | 138.1 m vs 142.1 m (2.8 %) |
| F2 | home_a_a2-tower_c_b1 vs home_a_b2-tower_c_a1 | 108.1 m vs 105.0 m (2.8 %) |
| F2 | home_a_a1-tower_c_b2 vs home_a_a2-tower_c_b1 | 105.0 m vs 108.1 m (2.8 %) |
| F2 | nat_node_a1-cache_a_b1 vs nat_node_a2-cache_a_b2 | 141.2 m vs 137.2 m (2.8 %) |
| F2 | post_w_a2-guilds_den_b2 vs post_w_b2-guilds_den_a2 | 196.9 m vs 191.4 m (2.8 %) |
| F2 | nat_node_a1-x_bridge_n vs nat_node_b2-x_bridge_n | 92.2 m vs 89.6 m (2.8 %) |
| F2 | shrine_a1-post_s_b1 vs shrine_a2-post_s_b2 | 123.8 m vs 127.4 m (2.8 %) |
| F2 | keep_t3-peddler_b2 vs keep_t4-peddler_a2 | 158.4 m vs 154.0 m (2.8 %) |
| F2 | rich_node_a1-peddler_b1 vs rich_node_b2-peddler_a2 | 107.2 m vs 110.3 m (2.8 %) |
| F2 | tower_c_a1-lairs_one_b2 vs tower_c_a2-lairs_one_b1 | 114.6 m vs 117.9 m (2.8 %) |
| F2 | inn_a1-lairs_one_b2 vs inn_b1-lairs_one_a2 | 109.5 m vs 112.7 m (2.8 %) |
| F2 | tower_r_a1-cache_a_b1 vs tower_r_b2-cache_a_a2 | 164.1 m vs 159.5 m (2.8 %) |
| F2 | tower_c_a2-lairs_one_b1 vs tower_c_b2-lairs_one_a1 | 117.9 m vs 114.6 m (2.8 %) |
| F2 | shrine_a1-post_w_b1 vs shrine_b1-post_w_a1 | 137.5 m vs 141.4 m (2.8 %) |
| F2 | home_a_a1-home_a_b1 vs home_a_b2-home_a_a2 | 161.6 m vs 157.1 m (2.8 %) |
| F2 | third_node_a1-post_s_b1 vs third_node_a2-post_s_b2 | 184.3 m vs 189.5 m (2.8 %) |
| F2 | rich_node_a1-shrine_b1 vs rich_node_b1-shrine_a1 | 92.1 m vs 94.7 m (2.8 %) |
| F2 | home_b_a2-wallow_b2 vs home_b_b2-wallow_a2 | 183.2 m vs 178.2 m (2.8 %) |
| F2 | shrine_b1-post_w_a1 vs shrine_b2-post_w_a2 | 141.4 m vs 137.5 m (2.8 %) |
| F2 | ford_nest_a1-stag_a2 vs ford_nest_a2-stag_b2 | 125.5 m vs 129.0 m (2.7 %) |
| F2 | shrine_a2-post_w_b1 vs shrine_b2-post_w_a1 | 141.6 m vs 137.7 m (2.7 %) |
| F2 | shrine_a1-post_w_b2 vs shrine_a2-post_w_b1 | 137.7 m vs 141.6 m (2.7 %) |
| F2 | tower_c_a1-lairs_one_b1 vs tower_c_b2-lairs_one_a2 | 131.6 m vs 135.3 m (2.7 %) |
| F2 | third_node_a2-post_s_b2 vs third_node_b2-post_s_a2 | 189.5 m vs 184.3 m (2.7 %) |
| F2 | inn_a1-lairs_two_b1 vs inn_b2-lairs_two_a2 | 132.0 m vs 135.7 m (2.7 %) |
| F2 | keep_t0-rich_node_b1 vs keep_t1-rich_node_a1 | 140.6 m vs 136.7 m (2.7 %) |
| F2 | guilds_den_a1-peddler_a2 vs guilds_den_a2-peddler_a1 | 105.2 m vs 102.3 m (2.7 %) |
| F2 | guilds_den_a1-peddler_a2 vs guilds_den_b1-peddler_b2 | 105.2 m vs 102.3 m (2.7 %) |
| F2 | guilds_den_a2-peddler_a1 vs guilds_den_b2-peddler_b1 | 102.3 m vs 105.2 m (2.7 %) |
| F2 | guilds_den_b1-peddler_b2 vs guilds_den_b2-peddler_b1 | 102.3 m vs 105.2 m (2.7 %) |
| F2 | keep_t0-well_b1 vs keep_t1-well_a1 | 156.3 m vs 152.1 m (2.7 %) |
| F2 | keep_t1-well_a1 vs keep_t4-well_a2 | 152.1 m vs 156.3 m (2.7 %) |
| F2 | tower_r_a1-wallow_a2 vs tower_r_a2-wallow_a1 | 134.2 m vs 130.6 m (2.7 %) |
| F2 | tower_r_a1-wallow_a2 vs tower_r_b1-wallow_b2 | 134.2 m vs 130.6 m (2.7 %) |
| F2 | keep_t0-well_b1 vs keep_t3-well_b2 | 156.3 m vs 152.1 m (2.7 %) |
| F2 | keep_t3-well_b2 vs keep_t4-well_a2 | 152.1 m vs 156.3 m (2.7 %) |
| F2 | tower_c_a1-stag_b2 vs tower_c_a2-stag_b1 | 88.0 m vs 90.4 m (2.7 %) |
| F2 | inn_b1-post_s_b2 vs inn_b2-post_s_b1 | 104.3 m vs 107.2 m (2.7 %) |
| F2 | inn_a2-post_s_a1 vs inn_b2-post_s_b1 | 104.3 m vs 107.2 m (2.7 %) |
| F2 | inn_a1-post_s_a2 vs inn_b1-post_s_b2 | 107.2 m vs 104.3 m (2.7 %) |
| F2 | inn_a1-post_s_a2 vs inn_a2-post_s_a1 | 107.2 m vs 104.3 m (2.7 %) |
| F2 | cache_b_a1-lairs_two_b1 vs cache_b_b2-lairs_two_a2 | 133.7 m vs 137.5 m (2.7 %) |
| F2 | stag_a1-peddler_a1 vs stag_a2-peddler_a2 | 61.0 m vs 59.4 m (2.7 %) |
| F2 | stag_a2-peddler_a2 vs stag_b2-peddler_b2 | 59.4 m vs 61.0 m (2.7 %) |
| F2 | guilds_den_a2-cache_b_a2 vs guilds_den_b2-cache_b_b2 | 89.2 m vs 91.7 m (2.7 %) |
| F2 | guilds_den_b1-cache_b_b1 vs guilds_den_b2-cache_b_b2 | 89.2 m vs 91.7 m (2.7 %) |
| F2 | shrine_a1-post_w_b1 vs shrine_a2-post_w_b2 | 137.5 m vs 141.3 m (2.7 %) |
| F2 | tower_r_a1-shrine_b2 vs tower_r_b2-shrine_a1 | 95.2 m vs 92.6 m (2.7 %) |
| F2 | guilds_den_a1-cache_b_a1 vs guilds_den_b1-cache_b_b1 | 91.7 m vs 89.2 m (2.7 %) |
| F2 | guilds_den_a1-cache_b_a1 vs guilds_den_a2-cache_b_a2 | 91.7 m vs 89.2 m (2.7 %) |
| F2 | rich_node_a1-post_w_b1 vs rich_node_b2-post_w_a2 | 118.8 m vs 122.1 m (2.7 %) |
| F2 | tower_c_a2-stag_b1 vs tower_c_b2-stag_a1 | 90.4 m vs 88.0 m (2.7 %) |
| F2 | keep_t1-rich_node_a1 vs keep_t4-rich_node_a2 | 136.7 m vs 140.5 m (2.7 %) |
| F2 | keep_t0-rich_node_b1 vs keep_t3-rich_node_b2 | 140.6 m vs 136.8 m (2.7 %) |
| F2 | tower_c_a1-lairs_one_b2 vs tower_c_b1-lairs_one_a2 | 114.6 m vs 117.8 m (2.7 %) |
| F2 | shrine_a2-post_w_b2 vs shrine_b2-post_w_a2 | 141.3 m vs 137.5 m (2.7 %) |
| F2 | post_w_a2-cache_b_a2 vs post_w_b1-cache_b_b1 | 78.0 m vs 80.2 m (2.7 %) |
| F2 | keep_t0-cache_b_b1 vs keep_t3-cache_b_b2 | 134.2 m vs 130.7 m (2.7 %) |
| F2 | ford_nest_a1-stag_b1 vs ford_nest_a2-stag_b2 | 125.6 m vs 129.0 m (2.7 %) |
| F2 | tower_r_a1-shrine_b2 vs tower_r_a2-shrine_b1 | 95.2 m vs 92.6 m (2.7 %) |
| F2 | keep_t3-home_b_b2 vs keep_t4-home_b_a2 | 168.6 m vs 164.1 m (2.7 %) |
| F2 | tower_c_b1-lairs_one_a2 vs tower_c_b2-lairs_one_a1 | 117.8 m vs 114.6 m (2.7 %) |
| F2 | nat_node_a2-lairs_one_b1 vs nat_node_b2-lairs_one_a1 | 132.0 m vs 128.5 m (2.7 %) |
| F2 | tower_r_a1-lairs_one_b1 vs tower_r_b1-lairs_one_a1 | 174.3 m vs 169.7 m (2.6 %) |
| F2 | post_w_a1-cache_b_a1 vs post_w_b1-cache_b_b1 | 78.1 m vs 80.2 m (2.6 %) |
| F2 | post_w_b1-cache_b_b1 vs post_w_b2-cache_b_b2 | 80.2 m vs 78.1 m (2.6 %) |
| F2 | peddler_a1-peddler_b2 vs peddler_a2-peddler_b1 | 135.6 m vs 139.3 m (2.6 %) |
| F2 | keep_t3-rich_node_b2 vs keep_t4-rich_node_a2 | 136.8 m vs 140.5 m (2.6 %) |
| F2 | well_a1-well_b2 vs well_a2-well_b1 | 70.1 m vs 72.0 m (2.6 %) |
| F2 | tower_r_a2-post_s_a1 vs tower_r_b1-post_s_b2 | 147.6 m vs 151.6 m (2.6 %) |
| F2 | home_a_b1-tower_c_b1 vs home_a_b2-tower_c_b2 | 51.6 m vs 50.2 m (2.6 %) |
| F2 | home_a_a1-tower_c_a1 vs home_a_b1-tower_c_b1 | 50.2 m vs 51.6 m (2.6 %) |
| F2 | shrine_a1-peddler_b1 vs shrine_b2-peddler_a2 | 116.8 m vs 120.0 m (2.6 %) |
| F2 | post_s_b1-lairs_two_a1 vs post_s_b2-lairs_two_a2 | 184.7 m vs 189.7 m (2.6 %) |
| F2 | tower_r_a1-lairs_one_b1 vs tower_r_a2-lairs_one_b2 | 174.3 m vs 169.8 m (2.6 %) |
| F2 | keep_t0-home_a_b1 vs keep_t3-home_a_b2 | 163.6 m vs 168.0 m (2.6 %) |
| F2 | rich_node_a1-peddler_b1 vs rich_node_a2-peddler_b2 | 107.2 m vs 110.1 m (2.6 %) |
| F2 | rich_node_b1-stag_b2 vs rich_node_b2-stag_b1 | 132.9 m vs 136.4 m (2.6 %) |
| F2 | rich_node_a1-stag_a2 vs rich_node_b1-stag_b2 | 136.4 m vs 132.9 m (2.6 %) |
| F2 | post_s_a2-lairs_two_b2 vs post_s_b2-lairs_two_a2 | 184.7 m vs 189.7 m (2.6 %) |
| F2 | nat_node_a1-lairs_one_b2 vs nat_node_a2-lairs_one_b1 | 128.6 m vs 132.0 m (2.6 %) |
| F2 | tower_r_b1-wallow_b2 vs tower_r_b2-wallow_b1 | 130.6 m vs 134.1 m (2.6 %) |
| F2 | tower_r_a2-wallow_a1 vs tower_r_b2-wallow_b1 | 130.6 m vs 134.1 m (2.6 %) |
| F2 | home_a_a1-inn_b1 vs home_a_b1-inn_a1 | 116.8 m vs 119.9 m (2.6 %) |
| F2 | home_a_b1-inn_a1 vs home_a_b2-inn_a2 | 119.9 m vs 116.8 m (2.6 %) |
| F2 | rich_node_a1-third_node_a1 vs rich_node_b1-third_node_b1 | 64.4 m vs 66.2 m (2.6 %) |
| F2 | rich_node_b1-third_node_b1 vs rich_node_b2-third_node_b2 | 66.2 m vs 64.4 m (2.6 %) |
| F2 | third_node_b1-lairs_two_a1 vs third_node_b2-lairs_two_a2 | 208.3 m vs 213.9 m (2.6 %) |
| F2 | wallow_b1-lairs_two_b2 vs wallow_b2-lairs_two_b1 | 139.1 m vs 135.5 m (2.6 %) |
| F2 | wallow_a1-lairs_two_a2 vs wallow_b1-lairs_two_b2 | 135.5 m vs 139.1 m (2.6 %) |
| F2 | wallow_a1-lairs_two_a2 vs wallow_a2-lairs_two_a1 | 135.5 m vs 139.1 m (2.6 %) |
| F2 | wallow_a2-lairs_two_a1 vs wallow_b2-lairs_two_b1 | 139.1 m vs 135.5 m (2.6 %) |
| F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_a2-guilds_lodge_b1 | 130.7 m vs 134.2 m (2.6 %) |
| F2 | peddler_a1-peddler_b1 vs peddler_b2-peddler_a2 | 135.4 m vs 139.0 m (2.6 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t1-tower_r_a1 | 152.1 m vs 148.2 m (2.6 %) |
| F2 | rich_node_a1-peddler_b1 vs rich_node_b1-peddler_a1 | 107.2 m vs 110.1 m (2.6 %) |
| F2 | third_node_a2-lairs_two_b2 vs third_node_b2-lairs_two_a2 | 208.4 m vs 213.9 m (2.6 %) |
| F2 | tower_c_a1-stag_b2 vs tower_c_b1-stag_a2 | 88.0 m vs 90.3 m (2.6 %) |
| F2 | inn_b1-lairs_two_b2 vs inn_b2-lairs_two_b1 | 105.2 m vs 108.0 m (2.6 %) |
| F2 | inn_a2-lairs_two_a1 vs inn_b2-lairs_two_b1 | 105.2 m vs 108.0 m (2.6 %) |
| F2 | stag_a1-guilds_den_a2 vs stag_a2-guilds_den_a1 | 163.9 m vs 159.7 m (2.6 %) |
| F2 | nat_node_a2-stag_b1 vs nat_node_b2-stag_a1 | 104.6 m vs 101.9 m (2.6 %) |
| F2 | home_a_a2-inn_b2 vs home_a_b2-inn_a2 | 119.9 m vs 116.8 m (2.6 %) |
| F2 | home_a_a1-inn_b1 vs home_a_a2-inn_b2 | 116.8 m vs 119.9 m (2.6 %) |
| F2 | shrine_a2-wallow_b2 vs shrine_b2-wallow_a2 | 151.9 m vs 148.0 m (2.5 %) |
| F2 | shrine_a2-stag_a1 vs shrine_b2-stag_b1 | 90.0 m vs 87.7 m (2.5 %) |
| F2 | shrine_b1-stag_b2 vs shrine_b2-stag_b1 | 90.0 m vs 87.7 m (2.5 %) |
| F2 | tower_c_b1-stag_a2 vs tower_c_b2-stag_a1 | 90.3 m vs 88.0 m (2.5 %) |
| F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_b1-guilds_lodge_a2 | 130.7 m vs 134.1 m (2.5 %) |
| F2 | keep_t3-cache_b_b2 vs keep_t4-cache_b_a2 | 130.7 m vs 134.0 m (2.5 %) |
| F2 | peddler_b1-cache_a_a1 vs peddler_b2-cache_a_a2 | 153.9 m vs 157.9 m (2.5 %) |
| F2 | home_a_b1-nat_node_a2 vs home_a_b2-nat_node_a1 | 123.1 m vs 120.0 m (2.5 %) |
| F2 | home_a_a1-nat_node_b2 vs home_a_b1-nat_node_a2 | 120.0 m vs 123.1 m (2.5 %) |
| F2 | third_node_a1-lairs_two_b1 vs third_node_b1-lairs_two_a1 | 213.7 m vs 208.3 m (2.5 %) |
| F2 | keep_t3-post_w_b2 vs keep_t4-post_w_a2 | 175.9 m vs 171.5 m (2.5 %) |
| F2 | keep_t1-tower_r_a1 vs keep_t4-tower_r_a2 | 148.2 m vs 152.0 m (2.5 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t3-tower_r_b2 | 152.1 m vs 148.3 m (2.5 %) |
| F2 | home_a_a1-stag_b2 vs home_a_a2-stag_b1 | 123.6 m vs 120.5 m (2.5 %) |
| F2 | home_a_b1-nat_node_a1 vs home_a_b2-nat_node_a2 | 122.7 m vs 119.7 m (2.5 %) |
| F2 | home_a_a1-nat_node_b1 vs home_a_b1-nat_node_a1 | 119.7 m vs 122.7 m (2.5 %) |
| F2 | tower_r_a1-stag_a2 vs tower_r_b1-stag_b2 | 146.1 m vs 142.4 m (2.5 %) |
| F2 | keep_t1-post_s_a1 vs keep_t4-post_s_a2 | 160.1 m vs 164.2 m (2.5 %) |
| F2 | inn_a1-lairs_one_b1 vs inn_b2-lairs_one_a2 | 144.9 m vs 148.6 m (2.5 %) |
| F2 | nat_node_a2-third_node_b1 vs nat_node_b2-third_node_a1 | 134.8 m vs 138.2 m (2.5 %) |
| F2 | nat_node_b1-third_node_a2 vs nat_node_b2-third_node_a1 | 134.8 m vs 138.2 m (2.5 %) |
| F2 | rich_node_a1-cache_a_b1 vs rich_node_b1-cache_a_a1 | 140.4 m vs 136.9 m (2.5 %) |
| F2 | shrine_a1-lairs_two_b2 vs shrine_a2-lairs_two_b1 | 125.8 m vs 122.6 m (2.5 %) |
| F2 | nat_node_b1-lairs_one_a2 vs nat_node_b2-lairs_one_a1 | 131.8 m vs 128.5 m (2.5 %) |
| F2 | nat_node_a1-third_node_b2 vs nat_node_b1-third_node_a2 | 138.2 m vs 134.8 m (2.5 %) |
| F2 | nat_node_a1-third_node_b2 vs nat_node_a2-third_node_b1 | 138.2 m vs 134.8 m (2.5 %) |
| F2 | peddler_a1-cache_a_b1 vs peddler_b1-cache_a_a1 | 157.9 m vs 153.9 m (2.5 %) |
| F2 | nat_node_a1-stag_b2 vs nat_node_a2-stag_b1 | 102.0 m vs 104.6 m (2.5 %) |
| F2 | third_node_a1-lairs_two_b1 vs third_node_a2-lairs_two_b2 | 213.7 m vs 208.4 m (2.5 %) |
| F2 | tower_r_b1-stag_b2 vs tower_r_b2-stag_b1 | 142.4 m vs 146.0 m (2.5 %) |
| F2 | peddler_a2-cache_a_b2 vs peddler_b2-cache_a_a2 | 154.0 m vs 157.9 m (2.5 %) |
| F2 | post_w_b1-cache_a_a1 vs post_w_b2-cache_a_a2 | 158.9 m vs 163.0 m (2.5 %) |
| F2 | home_a_a1-nat_node_b2 vs home_a_a2-nat_node_b1 | 120.0 m vs 123.0 m (2.5 %) |
| F2 | home_a_a2-nat_node_b1 vs home_a_b2-nat_node_a1 | 123.0 m vs 120.0 m (2.5 %) |
| F2 | post_s_a1-lairs_two_b1 vs post_s_b1-lairs_two_a1 | 189.4 m vs 184.7 m (2.5 %) |
| F2 | cache_b_a1-lairs_one_b1 vs cache_b_b2-lairs_one_a2 | 146.6 m vs 150.4 m (2.5 %) |
| F2 | cache_b_a1-lairs_two_b2 vs cache_b_b1-lairs_two_a2 | 77.4 m vs 79.4 m (2.5 %) |
| F2 | ford_nest_a1-guilds_lodge_b2 vs ford_nest_a2-guilds_lodge_b1 | 95.6 m vs 93.2 m (2.5 %) |
| F2 | ford_nest_a1-guilds_lodge_a1 vs ford_nest_a2-guilds_lodge_a2 | 95.6 m vs 93.2 m (2.5 %) |
| F2 | ford_nest_a1-guilds_lodge_b2 vs ford_nest_a2-guilds_lodge_a2 | 95.6 m vs 93.2 m (2.5 %) |
| F2 | ford_nest_a1-guilds_lodge_a1 vs ford_nest_a2-guilds_lodge_b1 | 95.6 m vs 93.2 m (2.5 %) |
| F2 | home_a_a2-stag_b1 vs home_a_b2-stag_a1 | 120.5 m vs 123.6 m (2.5 %) |
| F2 | rich_node_a1-well_b1 vs rich_node_b2-well_a2 | 118.5 m vs 121.5 m (2.5 %) |
| F2 | stag_a2-guilds_den_a1 vs stag_b2-guilds_den_b1 | 159.7 m vs 163.7 m (2.5 %) |
| F2 | post_s_a1-lairs_two_b1 vs post_s_a2-lairs_two_b2 | 189.4 m vs 184.7 m (2.5 %) |
| F2 | home_a_a2-nat_node_b2 vs home_a_b2-nat_node_a2 | 122.7 m vs 119.7 m (2.5 %) |
| F2 | home_a_a1-nat_node_b1 vs home_a_a2-nat_node_b2 | 119.7 m vs 122.7 m (2.5 %) |
| F2 | ford_nest_a1-guilds_den_b2 vs ford_nest_a2-guilds_den_a2 | 94.1 m vs 91.8 m (2.5 %) |
| F2 | ford_nest_a1-guilds_den_a1 vs ford_nest_a2-guilds_den_b1 | 94.1 m vs 91.8 m (2.5 %) |
| F2 | ford_nest_a1-guilds_den_b2 vs ford_nest_a2-guilds_den_b1 | 94.1 m vs 91.8 m (2.5 %) |
| F2 | ford_nest_a1-guilds_den_a1 vs ford_nest_a2-guilds_den_a2 | 94.1 m vs 91.8 m (2.5 %) |
| F2 | post_w_a1-lairs_one_b2 vs post_w_a2-lairs_one_b1 | 167.7 m vs 163.6 m (2.5 %) |
| F2 | peddler_a1-cache_a_b1 vs peddler_a2-cache_a_b2 | 157.9 m vs 154.0 m (2.5 %) |
| F2 | stag_a2-peddler_a2 vs stag_b1-peddler_b1 | 59.4 m vs 60.9 m (2.5 %) |
| F2 | inn_a1-lairs_two_a2 vs inn_b2-lairs_two_b1 | 105.3 m vs 108.0 m (2.4 %) |
| F2 | rich_node_a1-well_b1 vs rich_node_a2-well_b2 | 118.5 m vs 121.5 m (2.4 %) |
| F2 | shrine_a2-lairs_two_b1 vs shrine_b2-lairs_two_a1 | 122.6 m vs 125.7 m (2.4 %) |
| F2 | nat_node_a1-lairs_one_b2 vs nat_node_b1-lairs_one_a2 | 128.6 m vs 131.8 m (2.4 %) |
| F2 | keep_t3-tower_r_b2 vs keep_t4-tower_r_a2 | 148.3 m vs 152.0 m (2.4 %) |
| F2 | home_a_b1-cache_a_a1 vs home_a_b2-cache_a_a2 | 159.8 m vs 163.8 m (2.4 %) |
| F2 | post_w_a2-cache_a_b2 vs post_w_b2-cache_a_a2 | 159.0 m vs 163.0 m (2.4 %) |
| F2 | home_b_a2-cache_b_a1 vs home_b_b2-cache_b_b1 | 89.7 m vs 87.5 m (2.4 %) |
| F2 | rich_node_a1-guilds_lodge_b1 vs rich_node_a2-guilds_lodge_b2 | 166.3 m vs 170.5 m (2.4 %) |
| F2 | rich_node_a1-guilds_den_b1 vs rich_node_a2-guilds_den_b2 | 165.0 m vs 169.1 m (2.4 %) |
| F2 | post_w_a1-lairs_one_b2 vs post_w_b1-lairs_one_a2 | 167.7 m vs 163.6 m (2.4 %) |
| F2 | rich_node_a1-third_node_b1 vs rich_node_a2-third_node_b2 | 152.1 m vs 155.9 m (2.4 %) |
| F2 | cache_b_a1-lairs_one_a1 vs cache_b_b1-lairs_one_b1 | 87.7 m vs 85.5 m (2.4 %) |
| F2 | cache_b_b1-lairs_one_b1 vs cache_b_b2-lairs_one_b2 | 85.5 m vs 87.7 m (2.4 %) |
| F2 | home_b_a1-cache_b_a2 vs home_b_a2-cache_b_a1 | 87.5 m vs 89.7 m (2.4 %) |
| F2 | post_w_a2-lairs_one_b1 vs post_w_b2-lairs_one_a1 | 163.6 m vs 167.6 m (2.4 %) |
| F2 | keep_t3-wallow_b2 vs keep_t4-wallow_a2 | 186.5 m vs 182.0 m (2.4 %) |
| F2 | shrine_a2-guilds_lodge_b1 vs shrine_b2-guilds_lodge_a1 | 157.7 m vs 161.6 m (2.4 %) |
| F2 | keep_t0-post_s_b1 vs keep_t1-post_s_a1 | 164.1 m vs 160.1 m (2.4 %) |
| F2 | rich_node_a1-cache_a_b1 vs rich_node_a2-cache_a_b2 | 140.4 m vs 137.1 m (2.4 %) |
| F2 | shrine_a1-guilds_lodge_b2 vs shrine_a2-guilds_lodge_b1 | 161.6 m vs 157.7 m (2.4 %) |
| F2 | home_a_a2-cache_a_b2 vs home_a_b2-cache_a_a2 | 159.8 m vs 163.8 m (2.4 %) |
| F2 | rich_node_a1-guilds_lodge_b1 vs rich_node_b1-guilds_lodge_a1 | 166.3 m vs 170.4 m (2.4 %) |
| F2 | rich_node_a1-guilds_den_b1 vs rich_node_b1-guilds_den_a1 | 165.0 m vs 169.0 m (2.4 %) |
| F2 | tower_r_a2-shrine_b1 vs tower_r_b1-shrine_a2 | 92.6 m vs 90.4 m (2.4 %) |
| F2 | rich_node_a1-cache_a_b1 vs rich_node_b2-cache_a_a2 | 140.4 m vs 137.1 m (2.4 %) |
| F2 | shrine_a2-stag_b2 vs shrine_b2-stag_a2 | 134.8 m vs 131.6 m (2.4 %) |
| F2 | post_w_b1-lairs_one_a2 vs post_w_b2-lairs_one_a1 | 163.6 m vs 167.6 m (2.4 %) |
| F2 | rich_node_a1-third_node_b1 vs rich_node_b1-third_node_a1 | 152.1 m vs 155.8 m (2.4 %) |
| F2 | shrine_b1-guilds_lodge_a2 vs shrine_b2-guilds_lodge_a1 | 157.8 m vs 161.6 m (2.4 %) |
| F2 | tower_c_a2-lairs_one_b2 vs tower_c_b2-lairs_one_a2 | 132.1 m vs 135.3 m (2.4 %) |
| F2 | tower_r_b1-shrine_a2 vs tower_r_b2-shrine_a1 | 90.4 m vs 92.6 m (2.4 %) |
| F2 | shrine_a1-guilds_lodge_b2 vs shrine_b1-guilds_lodge_a2 | 161.6 m vs 157.8 m (2.4 %) |
| F2 | cache_b_a1-lairs_one_a1 vs cache_b_a2-lairs_one_a2 | 87.7 m vs 85.6 m (2.4 %) |
| F2 | cache_b_a2-lairs_one_a2 vs cache_b_b2-lairs_one_b2 | 85.6 m vs 87.7 m (2.4 %) |
| F2 | keep_t3-home_a_b2 vs keep_t4-home_a_a2 | 168.0 m vs 164.0 m (2.3 %) |
| F2 | rich_node_a1-wallow_a2 vs rich_node_b1-wallow_b2 | 125.7 m vs 122.7 m (2.3 %) |
| F2 | rich_node_a1-wallow_a2 vs rich_node_a2-wallow_a1 | 125.7 m vs 122.7 m (2.3 %) |
| F2 | post_w_a1-cache_a_a1 vs post_w_b1-cache_a_b1 | 58.1 m vs 59.5 m (2.3 %) |
| F2 | post_w_a1-cache_a_a1 vs post_w_a2-cache_a_a2 | 58.1 m vs 59.5 m (2.3 %) |
| F2 | post_w_b1-cache_a_b1 vs post_w_b2-cache_a_b2 | 59.5 m vs 58.1 m (2.3 %) |
| F2 | post_w_a2-cache_a_a2 vs post_w_b2-cache_a_b2 | 59.5 m vs 58.1 m (2.3 %) |
| F2 | rich_node_b1-cache_a_b2 vs rich_node_b2-cache_a_b1 | 129.7 m vs 126.6 m (2.3 %) |
| F2 | rich_node_a2-cache_a_a1 vs rich_node_b2-cache_a_b1 | 129.7 m vs 126.6 m (2.3 %) |
| F2 | nat_node_b1-stag_a2 vs nat_node_b2-stag_a1 | 104.4 m vs 101.9 m (2.3 %) |
| F2 | shrine_a1-stag_b2 vs shrine_a2-stag_b1 | 114.4 m vs 111.7 m (2.3 %) |
| F2 | shrine_b1-stag_a1 vs shrine_b2-stag_a2 | 134.8 m vs 131.6 m (2.3 %) |
| F2 | post_w_a1-cache_a_b2 vs post_w_a2-cache_a_b1 | 148.9 m vs 145.4 m (2.3 %) |
| F2 | shrine_a1-stag_b2 vs shrine_b1-stag_a2 | 114.4 m vs 111.7 m (2.3 %) |
| F2 | home_a_a1-shrine_b2 vs home_a_b1-shrine_a2 | 130.4 m vs 133.5 m (2.3 %) |
| F2 | home_a_b1-shrine_a2 vs home_a_b2-shrine_a1 | 133.5 m vs 130.4 m (2.3 %) |
| F2 | rich_node_a1-well_b1 vs rich_node_b1-well_a1 | 118.5 m vs 121.3 m (2.3 %) |
| F2 | third_node_a2-lairs_two_a1 vs third_node_b2-lairs_two_b1 | 154.2 m vs 150.6 m (2.3 %) |
| F2 | third_node_b1-lairs_two_b2 vs third_node_b2-lairs_two_b1 | 154.2 m vs 150.6 m (2.3 %) |
| F2 | third_node_a1-lairs_two_a2 vs third_node_b1-lairs_two_b2 | 150.6 m vs 154.2 m (2.3 %) |
| F2 | third_node_a1-lairs_two_a2 vs third_node_a2-lairs_two_a1 | 150.6 m vs 154.2 m (2.3 %) |
| F2 | guilds_den_a1-cache_a_a2 vs guilds_den_a2-cache_a_a1 | 148.5 m vs 145.0 m (2.3 %) |
| F2 | guilds_den_a2-cache_a_a1 vs guilds_den_b2-cache_a_b1 | 145.0 m vs 148.5 m (2.3 %) |
| F2 | guilds_den_a1-cache_a_a2 vs guilds_den_b1-cache_a_b2 | 148.5 m vs 145.0 m (2.3 %) |
| F2 | guilds_den_b1-cache_a_b2 vs guilds_den_b2-cache_a_b1 | 145.0 m vs 148.5 m (2.3 %) |
| F2 | cache_b_b1-lairs_two_a2 vs cache_b_b2-lairs_two_a1 | 79.4 m vs 77.5 m (2.3 %) |
| F2 | home_a_b1-shrine_a1 vs home_a_b2-shrine_a2 | 133.2 m vs 130.1 m (2.3 %) |
| F2 | home_a_a1-shrine_b1 vs home_a_b1-shrine_a1 | 130.1 m vs 133.2 m (2.3 %) |
| F2 | tower_c_b1-lairs_one_a1 vs tower_c_b2-lairs_one_a2 | 132.2 m vs 135.3 m (2.3 %) |
| F2 | post_w_a1-x_lane_w vs post_w_b1-x_lane_e | 72.1 m vs 73.8 m (2.3 %) |
| F2 | post_w_b1-x_lane_e vs post_w_b2-x_lane_e | 73.8 m vs 72.1 m (2.3 %) |
| F2 | post_w_a1-cache_a_b1 vs post_w_b1-cache_a_a1 | 162.7 m vs 158.9 m (2.3 %) |
| F2 | shrine_a1-cache_b_a1 vs shrine_b1-cache_b_b1 | 47.2 m vs 48.3 m (2.3 %) |
| F2 | shrine_b1-cache_b_b1 vs shrine_b2-cache_b_b2 | 48.3 m vs 47.2 m (2.3 %) |
| F2 | post_w_a2-cache_a_b1 vs post_w_b2-cache_a_a1 | 145.4 m vs 148.8 m (2.3 %) |
| F2 | home_a_a1-shrine_b2 vs home_a_a2-shrine_b1 | 130.4 m vs 133.4 m (2.3 %) |
| F2 | home_a_a2-shrine_b1 vs home_a_b2-shrine_a1 | 133.4 m vs 130.4 m (2.3 %) |
| F2 | shrine_a2-stag_b1 vs shrine_b2-stag_a1 | 111.7 m vs 114.3 m (2.3 %) |
| F2 | rich_node_a2-lairs_two_a1 vs rich_node_b2-lairs_two_b1 | 148.9 m vs 145.5 m (2.3 %) |
| F2 | rich_node_b1-lairs_two_b2 vs rich_node_b2-lairs_two_b1 | 148.9 m vs 145.5 m (2.3 %) |
| F2 | post_s_b1-guilds_lodge_b2 vs post_s_b2-guilds_lodge_b1 | 171.2 m vs 167.3 m (2.3 %) |
| F2 | post_s_a2-guilds_lodge_a1 vs post_s_b2-guilds_lodge_b1 | 171.2 m vs 167.3 m (2.3 %) |
| F2 | nat_node_a1-stag_b2 vs nat_node_b1-stag_a2 | 102.0 m vs 104.4 m (2.3 %) |
| F2 | third_node_b1-post_w_a1 vs third_node_b2-post_w_a2 | 184.0 m vs 179.8 m (2.3 %) |
| F2 | shrine_b1-stag_a2 vs shrine_b2-stag_a1 | 111.7 m vs 114.3 m (2.3 %) |
| F2 | post_w_a1-x_lane_w vs post_w_a2-x_lane_w | 72.1 m vs 73.8 m (2.3 %) |
| F2 | post_w_a2-x_lane_w vs post_w_b2-x_lane_e | 73.8 m vs 72.1 m (2.3 %) |
| F2 | home_a_a1-lairs_one_a2 vs home_a_b1-lairs_one_b2 | 109.7 m vs 112.3 m (2.3 %) |
| F2 | home_a_b1-lairs_one_b2 vs home_a_b2-lairs_one_b1 | 112.3 m vs 109.7 m (2.3 %) |
| F2 | home_b_b1-cache_a_a1 vs home_b_b2-cache_a_a2 | 172.0 m vs 176.0 m (2.3 %) |
| F2 | wallow_a2-guilds_lodge_b2 vs wallow_b2-guilds_lodge_a2 | 222.7 m vs 227.9 m (2.3 %) |
| F2 | wallow_b1-guilds_lodge_a1 vs wallow_b2-guilds_lodge_a2 | 222.7 m vs 227.9 m (2.3 %) |
| F2 | home_a_a2-shrine_b2 vs home_a_b2-shrine_a2 | 133.1 m vs 130.1 m (2.3 %) |
| F2 | home_a_a1-shrine_b1 vs home_a_a2-shrine_b2 | 130.1 m vs 133.1 m (2.3 %) |
| F2 | home_a_a1-cache_a_b1 vs home_a_b1-cache_a_a1 | 163.5 m vs 159.8 m (2.3 %) |
| F2 | cache_b_a1-lairs_two_b2 vs cache_b_a2-lairs_two_b1 | 77.4 m vs 79.2 m (2.3 %) |
| F2 | post_w_a1-cache_a_b1 vs post_w_a2-cache_a_b2 | 162.7 m vs 159.0 m (2.3 %) |
| F2 | home_a_a2-tower_c_a2 vs home_a_b2-tower_c_b2 | 51.4 m vs 50.2 m (2.2 %) |
| F2 | home_a_a1-tower_c_a1 vs home_a_a2-tower_c_a2 | 50.2 m vs 51.4 m (2.2 %) |
| F2 | home_b_a1-cache_a_b1 vs home_b_b1-cache_a_a1 | 175.9 m vs 172.0 m (2.2 %) |
| F2 | home_a_a2-guilds_lodge_b1 vs home_a_b2-guilds_lodge_a1 | 166.6 m vs 170.4 m (2.2 %) |
| F2 | wallow_a1-guilds_lodge_b1 vs wallow_a2-guilds_lodge_b2 | 227.8 m vs 222.7 m (2.2 %) |
| F2 | wallow_a1-guilds_lodge_b1 vs wallow_b1-guilds_lodge_a1 | 227.8 m vs 222.7 m (2.2 %) |
| F2 | stag_a1-guilds_den_a2 vs stag_b1-guilds_den_b2 | 163.9 m vs 160.2 m (2.2 %) |
| F2 | home_a_a1-guilds_lodge_b2 vs home_a_a2-guilds_lodge_b1 | 170.4 m vs 166.6 m (2.2 %) |
| F2 | home_b_a2-cache_a_b2 vs home_b_b2-cache_a_a2 | 172.0 m vs 176.0 m (2.2 %) |
| F2 | rich_node_b1-wallow_b2 vs rich_node_b2-wallow_b1 | 122.7 m vs 125.5 m (2.2 %) |
| F2 | rich_node_a2-wallow_a1 vs rich_node_b2-wallow_b1 | 122.7 m vs 125.5 m (2.2 %) |
| F2 | home_a_a1-lairs_one_a2 vs home_a_a2-lairs_one_a1 | 109.7 m vs 112.2 m (2.2 %) |
| F2 | home_a_a2-lairs_one_a1 vs home_a_b2-lairs_one_b1 | 112.2 m vs 109.7 m (2.2 %) |
| F2 | tower_c_a1-peddler_a2 vs tower_c_b1-peddler_b2 | 50.2 m vs 49.1 m (2.2 %) |
| F2 | tower_c_a1-peddler_a2 vs tower_c_a2-peddler_a1 | 50.2 m vs 49.1 m (2.2 %) |
| F2 | home_a_a1-cache_a_b1 vs home_a_a2-cache_a_b2 | 163.5 m vs 159.8 m (2.2 %) |
| F2 | guilds_lodge_b1-lairs_two_b2 vs guilds_lodge_b2-lairs_two_b1 | 161.8 m vs 158.2 m (2.2 %) |
| F2 | guilds_lodge_a1-lairs_two_a2 vs guilds_lodge_a2-lairs_two_a1 | 158.2 m vs 161.8 m (2.2 %) |
| F2 | guilds_lodge_a2-lairs_two_a1 vs guilds_lodge_b2-lairs_two_b1 | 161.8 m vs 158.2 m (2.2 %) |
| F2 | guilds_lodge_a1-lairs_two_a2 vs guilds_lodge_b1-lairs_two_b2 | 158.2 m vs 161.8 m (2.2 %) |
| F2 | shrine_a1-stag_b1 vs shrine_a2-stag_b2 | 131.8 m vs 134.8 m (2.2 %) |
| F2 | tower_c_a1-stag_b1 vs tower_c_b2-stag_a2 | 105.5 m vs 107.9 m (2.2 %) |
| F2 | home_a_a2-third_node_b1 vs home_a_b2-third_node_a1 | 155.9 m vs 159.4 m (2.2 %) |
| F2 | home_a_b1-third_node_a2 vs home_a_b2-third_node_a1 | 155.9 m vs 159.4 m (2.2 %) |
| F2 | home_a_a1-third_node_b2 vs home_a_a2-third_node_b1 | 159.4 m vs 155.9 m (2.2 %) |
| F2 | home_a_a1-third_node_b2 vs home_a_b1-third_node_a2 | 159.4 m vs 155.9 m (2.2 %) |
| F2 | home_a_b1-guilds_lodge_a2 vs home_a_b2-guilds_lodge_a1 | 166.6 m vs 170.4 m (2.2 %) |
| F2 | nat_node_a1-lairs_one_b1 vs nat_node_b1-lairs_one_a1 | 159.5 m vs 156.0 m (2.2 %) |
| F2 | home_a_a1-guilds_lodge_b2 vs home_a_b1-guilds_lodge_a2 | 170.4 m vs 166.6 m (2.2 %) |
| F2 | nat_node_a1-wallow_a2 vs nat_node_b1-wallow_b2 | 76.6 m vs 74.9 m (2.2 %) |
| F2 | nat_node_a1-wallow_a2 vs nat_node_a2-wallow_a1 | 76.6 m vs 74.9 m (2.2 %) |
| F2 | home_b_a1-cache_a_b1 vs home_b_a2-cache_a_b2 | 175.9 m vs 172.0 m (2.2 %) |
| F2 | post_s_a1-guilds_lodge_a2 vs post_s_b1-guilds_lodge_b2 | 167.5 m vs 171.2 m (2.2 %) |
| F2 | post_s_a1-guilds_lodge_a2 vs post_s_a2-guilds_lodge_a1 | 167.5 m vs 171.2 m (2.2 %) |
| F2 | tower_c_b1-peddler_b2 vs tower_c_b2-peddler_b1 | 49.1 m vs 50.2 m (2.2 %) |
| F2 | tower_c_a2-peddler_a1 vs tower_c_b2-peddler_b1 | 49.1 m vs 50.2 m (2.2 %) |
| F2 | tower_c_a2-stag_b2 vs tower_c_b2-stag_a2 | 105.5 m vs 107.9 m (2.2 %) |
| F2 | post_s_a2-x_lane_w vs post_s_b2-x_lane_e | 84.0 m vs 85.9 m (2.2 %) |
| F2 | post_s_a1-x_lane_w vs post_s_a2-x_lane_w | 85.9 m vs 84.0 m (2.2 %) |
| F2 | post_s_b1-x_lane_e vs post_s_b2-x_lane_e | 84.0 m vs 85.9 m (2.2 %) |
| F2 | post_s_a1-x_lane_w vs post_s_b1-x_lane_e | 85.9 m vs 84.0 m (2.2 %) |
| F2 | rich_node_a1-wallow_b1 vs rich_node_b2-wallow_a2 | 139.4 m vs 142.5 m (2.2 %) |
| F2 | shrine_a1-stag_b1 vs shrine_b1-stag_a1 | 131.8 m vs 134.8 m (2.2 %) |
| F2 | post_w_a1-lairs_two_b2 vs post_w_b1-lairs_two_a2 | 152.5 m vs 149.2 m (2.2 %) |
| F2 | nat_node_a1-lairs_one_b1 vs nat_node_a2-lairs_one_b2 | 159.5 m vs 156.0 m (2.2 %) |
| F2 | tower_r_a1-peddler_b1 vs tower_r_b1-peddler_a1 | 127.1 m vs 124.4 m (2.2 %) |
| F2 | cache_a_a1-cache_a_a2 vs cache_a_b2-cache_a_b1 | 126.6 m vs 123.9 m (2.2 %) |
| F2 | inn_a2-lairs_one_b2 vs inn_b2-lairs_one_a2 | 145.4 m vs 148.6 m (2.2 %) |
| F2 | keep_t3-cache_a_a1 vs keep_t4-cache_a_b1 | 102.9 m vs 105.1 m (2.1 %) |
| F2 | keep_t0-cache_a_a2 vs keep_t3-cache_a_a1 | 105.1 m vs 102.9 m (2.1 %) |
| F2 | keep_t0-cache_a_a2 vs keep_t1-cache_a_b2 | 105.1 m vs 102.9 m (2.1 %) |
| F2 | keep_t1-cache_a_b2 vs keep_t4-cache_a_b1 | 102.9 m vs 105.1 m (2.1 %) |
| F2 | well_a1-post_s_a2 vs well_b2-post_s_b1 | 135.1 m vs 138.0 m (2.1 %) |
| F2 | stag_b1-guilds_den_b2 vs stag_b2-guilds_den_b1 | 160.2 m vs 163.7 m (2.1 %) |
| F2 | guilds_den_a2-crown vs guilds_den_b2-crown | 114.6 m vs 117.1 m (2.1 %) |
| F2 | guilds_den_b1-crown vs guilds_den_b2-crown | 114.6 m vs 117.1 m (2.1 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_b2-wallow_a2 | 144.8 m vs 148.0 m (2.1 %) |
| F2 | rich_node_a1-cache_a_a2 vs rich_node_b1-cache_a_b2 | 126.9 m vs 129.7 m (2.1 %) |
| F2 | rich_node_a1-cache_a_a2 vs rich_node_a2-cache_a_a1 | 126.9 m vs 129.7 m (2.1 %) |
| F2 | guilds_den_a1-crown vs guilds_den_a2-crown | 117.1 m vs 114.6 m (2.1 %) |
| F2 | guilds_den_a1-crown vs guilds_den_b1-crown | 117.1 m vs 114.6 m (2.1 %) |
| F2 | keep_t3-post_s_a1 vs keep_t4-post_s_b1 | 129.0 m vs 131.8 m (2.1 %) |
| F2 | keep_t0-post_s_a2 vs keep_t1-post_s_b2 | 131.8 m vs 129.0 m (2.1 %) |
| F2 | keep_t1-post_s_b2 vs keep_t4-post_s_b1 | 129.0 m vs 131.8 m (2.1 %) |
| F2 | keep_t0-post_s_a2 vs keep_t3-post_s_a1 | 131.8 m vs 129.0 m (2.1 %) |
| F2 | rich_node_a1-wallow_b1 vs rich_node_a2-wallow_b2 | 139.4 m vs 142.4 m (2.1 %) |
| F2 | home_a_a1-peddler_b2 vs home_a_b1-peddler_a2 | 144.8 m vs 147.9 m (2.1 %) |
| F2 | home_a_b1-peddler_a2 vs home_a_b2-peddler_a1 | 147.9 m vs 144.8 m (2.1 %) |
| F2 | post_w_b1-lairs_two_a2 vs post_w_b2-lairs_two_a1 | 149.2 m vs 152.4 m (2.1 %) |
| F2 | cache_b_a2-lairs_one_b2 vs cache_b_b2-lairs_one_a2 | 147.2 m vs 150.4 m (2.1 %) |
| F2 | tower_r_a1-lairs_one_a2 vs tower_r_a2-lairs_one_a1 | 161.8 m vs 158.4 m (2.1 %) |
| F2 | tower_r_a1-lairs_one_a2 vs tower_r_b1-lairs_one_b2 | 161.8 m vs 158.4 m (2.1 %) |
| F2 | home_a_a2-stag_b1 vs home_a_b1-stag_a2 | 120.5 m vs 123.1 m (2.1 %) |
| F2 | post_s_b1-cache_a_a1 vs post_s_b2-cache_a_a2 | 167.2 m vs 170.8 m (2.1 %) |
| F2 | home_a_a2-cache_a_b1 vs home_a_b1-cache_a_a2 | 132.0 m vs 134.9 m (2.1 %) |
| F2 | tower_c_b1-stag_a1 vs tower_c_b2-stag_a2 | 105.6 m vs 107.9 m (2.1 %) |
| F2 | tower_r_b1-peddler_a1 vs tower_r_b2-peddler_a2 | 124.4 m vs 127.1 m (2.1 %) |
| F2 | wallow_a2-x_bridge_n vs wallow_b2-x_bridge_s | 82.8 m vs 81.1 m (2.1 %) |
| F2 | wallow_a1-x_bridge_s vs wallow_a2-x_bridge_n | 81.1 m vs 82.8 m (2.1 %) |
| F2 | inn_b1-lairs_one_a1 vs inn_b2-lairs_one_a2 | 145.5 m vs 148.6 m (2.1 %) |
| F2 | cache_b_a2-lairs_two_b1 vs cache_b_b2-lairs_two_a1 | 79.2 m vs 77.5 m (2.1 %) |
| F2 | tower_r_a2-lairs_one_a1 vs tower_r_b2-lairs_one_b1 | 158.4 m vs 161.8 m (2.1 %) |
| F2 | tower_r_b1-lairs_one_b2 vs tower_r_b2-lairs_one_b1 | 158.4 m vs 161.8 m (2.1 %) |
| F2 | post_s_a2-cache_a_b2 vs post_s_b2-cache_a_a2 | 167.2 m vs 170.8 m (2.1 %) |
| F2 | tower_r_a2-guilds_lodge_b2 vs tower_r_b2-guilds_lodge_a2 | 190.2 m vs 186.2 m (2.1 %) |
| F2 | home_a_a1-peddler_b2 vs home_a_a2-peddler_b1 | 144.8 m vs 147.9 m (2.1 %) |
| F2 | home_a_a2-peddler_b1 vs home_a_b2-peddler_a1 | 147.9 m vs 144.8 m (2.1 %) |
| F2 | rich_node_a1-wallow_b1 vs rich_node_b1-wallow_a1 | 139.4 m vs 142.3 m (2.1 %) |
| F2 | rich_node_a1-stag_a2 vs rich_node_a2-stag_a1 | 136.4 m vs 133.6 m (2.1 %) |
| F2 | rich_node_a2-stag_a1 vs rich_node_b2-stag_b1 | 133.6 m vs 136.4 m (2.1 %) |
| F2 | tower_r_a2-guilds_den_b2 vs tower_r_b2-guilds_den_a2 | 188.7 m vs 184.8 m (2.1 %) |
| F2 | nat_node_b1-wallow_b2 vs nat_node_b2-wallow_b1 | 74.9 m vs 76.5 m (2.1 %) |
| F2 | nat_node_a2-wallow_a1 vs nat_node_b2-wallow_b1 | 74.9 m vs 76.5 m (2.1 %) |
| F2 | wallow_b1-cache_a_a1 vs wallow_b2-cache_a_a2 | 189.5 m vs 193.6 m (2.1 %) |
| F2 | rich_node_a1-lairs_two_a2 vs rich_node_a2-lairs_two_a1 | 145.8 m vs 148.9 m (2.1 %) |
| F2 | rich_node_a1-lairs_two_a2 vs rich_node_b1-lairs_two_b2 | 145.8 m vs 148.9 m (2.1 %) |
| F2 | nat_node_b1-lairs_one_a1 vs nat_node_b2-lairs_one_a2 | 156.0 m vs 159.3 m (2.1 %) |
| F2 | home_a_b1-peddler_a1 vs home_a_b2-peddler_a2 | 147.6 m vs 144.5 m (2.1 %) |
| F2 | home_a_a1-peddler_b1 vs home_a_b1-peddler_a1 | 144.5 m vs 147.6 m (2.1 %) |
| F2 | cache_b_b1-lairs_one_a1 vs cache_b_b2-lairs_one_a2 | 147.3 m vs 150.4 m (2.1 %) |
| F2 | tower_r_a2-peddler_b2 vs tower_r_b1-peddler_a1 | 127.0 m vs 124.4 m (2.1 %) |
| F2 | tower_r_b1-guilds_lodge_a1 vs tower_r_b2-guilds_lodge_a2 | 190.1 m vs 186.2 m (2.1 %) |
| F2 | tower_r_b1-guilds_den_a1 vs tower_r_b2-guilds_den_a2 | 188.7 m vs 184.8 m (2.0 %) |
| F2 | wallow_a2-cache_a_b2 vs wallow_b2-cache_a_a2 | 189.6 m vs 193.6 m (2.0 %) |
| F2 | guilds_den_b1-x_ford_n vs guilds_den_b2-x_ford_s | 86.7 m vs 88.5 m (2.0 %) |
| F2 | guilds_den_a2-x_ford_n vs guilds_den_b2-x_ford_s | 86.7 m vs 88.5 m (2.0 %) |
| F2 | nat_node_a2-lairs_one_b2 vs nat_node_b2-lairs_one_a2 | 156.0 m vs 159.3 m (2.0 %) |
| F2 | home_a_a2-peddler_b2 vs home_a_b2-peddler_a2 | 147.5 m vs 144.5 m (2.0 %) |
| F2 | home_a_a1-peddler_b1 vs home_a_a2-peddler_b2 | 144.5 m vs 147.5 m (2.0 %) |
| F2 | inn_a1-cache_a_a2 vs inn_a2-cache_a_a1 | 89.3 m vs 87.5 m (2.0 %) |
| F2 | rich_node_a1-lairs_two_b1 vs rich_node_b2-lairs_two_a2 | 159.3 m vs 162.6 m (2.0 %) |
| F2 | nat_node_b1-cache_a_b2 vs nat_node_b2-cache_a_b1 | 79.2 m vs 77.6 m (2.0 %) |
| F2 | nat_node_a2-cache_a_a1 vs nat_node_b2-cache_a_b1 | 79.2 m vs 77.6 m (2.0 %) |
| F2 | rich_node_a1-shrine_a2 vs rich_node_b1-shrine_b2 | 74.4 m vs 72.9 m (2.0 %) |
| F2 | rich_node_b1-shrine_b2 vs rich_node_b2-shrine_b1 | 72.9 m vs 74.4 m (2.0 %) |
| F2 | rich_node_a2-shrine_a1 vs rich_node_b2-shrine_b1 | 72.9 m vs 74.4 m (2.0 %) |
| F2 | rich_node_a1-shrine_a2 vs rich_node_a2-shrine_a1 | 74.4 m vs 72.9 m (2.0 %) |
| F2 | rich_node_a1-third_node_b1 vs rich_node_b2-third_node_a2 | 152.1 m vs 155.2 m (2.0 %) |
| F2 | tower_r_a1-stag_a2 vs tower_r_a2-stag_a1 | 146.1 m vs 143.1 m (2.0 %) |
| F2 | tower_r_a1-guilds_den_b1 vs tower_r_b2-guilds_den_a2 | 188.6 m vs 184.8 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 97 sources) 138.80 s.
- Map Lab v2 (map-production.md 2.5): layout quartermeet_s25, 4 seats, rules tempo standard, 0 fixable findings.
- Navmesh raster 3.13 s (1017 polygons, 495616 cells of 0.25 m), spot / mirror checks 3.04 s, 4656 paths 2.20 s.
- Map Quartermeet (seed 25), scene res://docs/tools/world_forge/out/quartermeet_s25/preview.tscn, sim mode off; level load + navmesh bake 0.6 s (71 frames), lab 148.8 s. Spec: docs/design/map-production.md.
