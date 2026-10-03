# Map Lab: Quartermeet (2v2) scorecard: world_forge_quartermeet

2026-10-03 02:45 · lab v1.0 · 1805.64 s · scanned 97 spots

## Result: **WARN** · score **96 / 100**

0 FAIL · 4 WARN · 15 PASS · 2 info checks; findings: 0 FAIL, 838 WARN, 1101 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): tower_r_a2-lairs_two_a2 vs tower_r_b1-lairs_two_b1: 34.9 m vs 42.8 m (18.5 %) -> units walk tower_r_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 5059 / 6982 pairs within 2 % (0 FAIL, 827 WARN, 1096 info))_
2. **Travel times per seat (worker / soldier / cavalry / caravan)** (WARN): enemy keep #2 (worker): 0:33 vs 0:37 between seats -> one seat's route is longer or crosses more ford: see the travel-time table _(from T1 6 / 7 clean (0 FAIL, 1 WARN))_
3. **Clearances (roads, crossings, spacing)** (WARN): well_a1: point 3.7 m from a road centre line (want >= 7) -> push it off the road (auto-fix) _(from R4 83 / 91 clean (0 FAIL, 8 WARN))_
4. **Main routes: narrowest corridor matches the twin** (WARN): keep_t0 -> keep_t1: narrowest 3.9 m at (-7.2, 1.6) vs its twin's 5.8 m -> a collider narrows this route only on one side _(from C2 11 / 12 clean (0 FAIL, 2 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 1129 polygons, main area 28640 m² (92 % of the 176 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 97 / 97 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 4 / 4 clean, 5 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 176 x 176 m ok, 91 spots ok, 2.15x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 2.5x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 97 / 97 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 97 / 97 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (10 cells), 0.00 % (12 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6982 / 6982 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 65 | 5059 / 6982 pairs within 2 % (0 FAIL, 827 WARN, 1096 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | PASS 100 | 10 / 10 clean | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | PASS 100 | 4 / 4 clean | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep, ally / nearest enemy 0.33-0.50 |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | **WARN** 64 | 6 / 7 clean (0 FAIL, 1 WARN) | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | PASS 100 | 24 / 24 clean | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
| R2 | Content per seat (Crown Hollow per side) | PASS 100 | 60 / 60 clean | new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL |  |
| R3 | Contested + raidable objectives per seat | PASS 100 | 4 / 4 clean | own / nearest enemy path 0.9-1.1 (contested) or 1.1-1.45 (raidable): >= 3 per seat |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 6 / 6 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | **WARN** 66 | 11 / 12 clean (0 FAIL, 2 WARN) | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings, spacing) | **WARN** 66 | 83 / 91 clean (0 FAIL, 8 WARN) | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted); spots >= 3 m, structures >= 6 m apart, one den + one lodge per image |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (704 x 704 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | tower_r_a2-lairs_two_a2 vs tower_r_b1-lairs_two_b1 | 34.9 m vs 42.8 m (18.5 %) | units walk tower_r_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_two_b1 vs tower_r_b2-lairs_two_b2 | 42.8 m vs 34.9 m (18.5 %) | units walk tower_r_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_two_a1 vs tower_r_b1-lairs_two_b1 | 34.9 m vs 42.8 m (18.5 %) | units walk tower_r_b1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_two_b1 vs guilds_lodge_a2-lairs_two_b2 | 206.9 m vs 250.3 m (17.3 %) | units walk guilds_lodge_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b2 vs tower_r_a2-cache_b_b1 | 46.0 m vs 55.3 m (16.9 %) | units walk tower_r_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_b_b1 vs tower_r_b1-cache_b_a2 | 55.3 m vs 46.0 m (16.8 %) | units walk tower_r_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b2 vs tower_r_b2-cache_b_a1 | 46.0 m vs 55.3 m (16.8 %) | units walk tower_r_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-cache_b_a2 vs tower_r_b2-cache_b_a1 | 46.0 m vs 55.3 m (16.7 %) | units walk tower_r_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_w_a2 vs tower_r_b2-post_w_a1 | 131.9 m vs 111.2 m (15.7 %) | units walk tower_r_b1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_b2 vs tower_r_b1-post_w_a2 | 111.2 m vs 131.9 m (15.7 %) | units walk tower_r_b1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-x_ford_s vs post_s_a2-x_ford_n | 48.9 m vs 57.4 m (14.8 %) | units walk post_s_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-stag_a2 vs tower_c_b2-stag_a1 | 106.5 m vs 90.8 m (14.8 %) | units walk tower_c_b1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-stag_b1 vs tower_c_b1-stag_a2 | 90.8 m vs 106.5 m (14.7 %) | units walk tower_c_b1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_b2 vs tower_c_b1-stag_a2 | 90.8 m vs 106.5 m (14.7 %) | units walk tower_c_b1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-wallow_b1 vs tower_r_b1-wallow_a2 | 95.5 m vs 112.0 m (14.7 %) | units walk tower_r_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-wallow_a2 vs tower_r_b2-wallow_a1 | 112.0 m vs 95.5 m (14.7 %) | units walk tower_r_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-wallow_b2 vs tower_r_b1-wallow_a2 | 95.5 m vs 112.0 m (14.7 %) | units walk tower_r_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-x_ford_n vs post_s_b2-x_ford_s | 57.4 m vs 49.0 m (14.6 %) | units walk post_s_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-x_ford_n vs post_s_b1-x_ford_n | 57.4 m vs 49.1 m (14.6 %) | units walk post_s_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-lairs_two_b1 vs third_node_a2-lairs_two_b2 | 195.6 m vs 228.2 m (14.3 %) | units walk third_node_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-post_w_a1 vs shrine_b2-post_w_b1 | 38.0 m vs 44.4 m (14.3 %) | units walk shrine_b2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-post_w_b2 vs shrine_b2-post_w_b1 | 38.0 m vs 44.4 m (14.3 %) | units walk shrine_b2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_w_a2 vs shrine_b2-post_w_b1 | 38.0 m vs 44.4 m (14.3 %) | units walk shrine_b2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-well_b1 vs third_node_a2-well_b2 | 169.7 m vs 197.7 m (14.1 %) | units walk third_node_a2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-well_b2 vs third_node_b2-well_a2 | 197.7 m vs 169.7 m (14.1 %) | units walk third_node_a2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-wallow_b1 vs wallow_b2-wallow_a2 | 184.7 m vs 214.9 m (14.0 %) | units walk wallow_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_w_a1 vs well_b2-post_w_a2 | 137.7 m vs 159.8 m (13.8 %) | units walk well_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_b1 vs well_b1-post_w_a1 | 159.8 m vs 137.7 m (13.8 %) | units walk well_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_b1 vs well_a2-post_w_b2 | 159.8 m vs 137.7 m (13.8 %) | units walk well_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_w_b2 vs well_b2-post_w_a2 | 137.7 m vs 159.8 m (13.8 %) | units walk well_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-wallow_b1 vs third_node_a2-wallow_b2 | 194.9 m vs 226.0 m (13.8 %) | units walk third_node_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-wallow_b2 vs third_node_b2-wallow_a2 | 226.0 m vs 194.9 m (13.8 %) | units walk third_node_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_bridge_s vs shrine_a2-x_bridge_n | 74.1 m vs 85.9 m (13.7 %) | units walk shrine_a2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-stag_b2 vs well_b2-stag_a2 | 147.8 m vs 171.3 m (13.7 %) | units walk well_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_bridge_n vs shrine_b2-x_bridge_s | 85.9 m vs 74.2 m (13.7 %) | units walk shrine_a2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t3-peddler_b2 | 143.3 m vs 166.0 m (13.7 %) | units walk keep_t3-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b2 vs keep_t4-peddler_a2 | 166.0 m vs 143.3 m (13.7 %) | units walk keep_t3-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t1-peddler_a1 | 143.3 m vs 166.0 m (13.6 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-peddler_a1 vs keep_t4-peddler_a2 | 166.0 m vs 143.3 m (13.6 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b1 vs tower_r_b1-cache_b_a1 | 114.1 m vs 98.5 m (13.6 %) | units walk tower_r_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-lairs_two_b1 vs tower_c_b1-lairs_two_a2 | 103.8 m vs 120.1 m (13.6 %) | units walk tower_c_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-cache_b_a1 vs tower_r_b2-cache_b_a2 | 98.5 m vs 114.0 m (13.5 %) | units walk tower_r_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-inn_b2 vs keep_t4-inn_a2 | 131.7 m vs 114.0 m (13.4 %) | units walk keep_t3-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-inn_b1 vs keep_t3-inn_b2 | 114.0 m vs 131.7 m (13.4 %) | units walk keep_t3-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-inn_a1 vs keep_t4-inn_a2 | 131.6 m vs 114.0 m (13.4 %) | units walk keep_t1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-inn_b1 vs keep_t1-inn_a1 | 114.0 m vs 131.6 m (13.4 %) | units walk keep_t1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-wallow_b2 vs third_node_b1-wallow_a1 | 226.0 m vs 195.9 m (13.3 %) | units walk third_node_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-nat_node_b2 vs keep_t4-nat_node_a2 | 132.7 m vs 115.1 m (13.3 %) | units walk keep_t3-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_b1 vs keep_t3-nat_node_b2 | 115.1 m vs 132.7 m (13.3 %) | units walk keep_t3-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-nat_node_a1 vs keep_t4-nat_node_a2 | 132.7 m vs 115.1 m (13.3 %) | units walk keep_t1-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_b1 vs keep_t1-nat_node_a1 | 115.1 m vs 132.7 m (13.3 %) | units walk keep_t1-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_bridge_n vs shrine_b1-x_bridge_n | 85.9 m vs 74.6 m (13.2 %) | units walk shrine_a2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-tower_c_a1 vs tower_r_b2-tower_c_a2 | 81.3 m vs 93.6 m (13.2 %) | units walk tower_r_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b1 vs tower_r_b2-tower_c_a2 | 81.3 m vs 93.6 m (13.2 %) | units walk tower_r_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-inn_b2 vs wallow_b2-inn_a2 | 150.8 m vs 131.0 m (13.1 %) | units walk wallow_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-inn_b1 vs wallow_a2-inn_b2 | 131.0 m vs 150.8 m (13.1 %) | units walk wallow_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_b1 vs third_node_a2-cache_a_b2 | 185.8 m vs 213.8 m (13.1 %) | units walk third_node_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_a_b2 vs third_node_b2-cache_a_a2 | 213.8 m vs 185.8 m (13.1 %) | units walk third_node_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_s_b1 vs third_node_b2-post_s_a2 | 203.9 m vs 177.6 m (12.9 %) | units walk third_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-lairs_two_a2 vs tower_c_b2-lairs_two_a1 | 120.1 m vs 104.8 m (12.8 %) | units walk tower_c_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-lairs_two_b2 vs tower_c_b1-lairs_two_a2 | 104.8 m vs 120.1 m (12.8 %) | units walk tower_c_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_s_b1 vs wallow_b2-post_s_a2 | 188.2 m vs 164.2 m (12.7 %) | units walk wallow_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-peddler_b1 vs peddler_b2-peddler_a2 | 136.0 m vs 155.5 m (12.6 %) | units walk peddler_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-third_node_b1 vs third_node_b2-third_node_a2 | 205.0 m vs 234.3 m (12.5 %) | units walk third_node_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-shrine_b1 vs rich_node_b1-shrine_a1 | 91.9 m vs 104.8 m (12.4 %) | units walk rich_node_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_two_b1 vs tower_r_b2-lairs_two_a1 | 73.7 m vs 64.6 m (12.4 %) | units walk tower_r_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_two_b2 vs tower_r_a2-lairs_two_b1 | 64.6 m vs 73.7 m (12.3 %) | units walk tower_r_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a1-x_ford_n vs cache_b_a2-x_ford_s | 73.9 m vs 64.8 m (12.3 %) | units walk cache_b_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a2-x_ford_s vs cache_b_b2-x_ford_n | 64.8 m vs 73.9 m (12.3 %) | units walk cache_b_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-shrine_a1 vs rich_node_b2-shrine_a2 | 104.8 m vs 91.9 m (12.3 %) | units walk rich_node_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b1 vs home_b_a2-peddler_b2 | 149.9 m vs 170.9 m (12.3 %) | units walk home_b_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-peddler_b2 vs home_b_b2-peddler_a2 | 170.9 m vs 149.9 m (12.3 %) | units walk home_b_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b1 vs home_b_b1-peddler_a1 | 149.9 m vs 170.9 m (12.3 %) | units walk home_b_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-peddler_a1 vs home_b_b2-peddler_a2 | 170.9 m vs 149.9 m (12.3 %) | units walk home_b_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a1-x_ford_n vs cache_b_b1-x_ford_s | 73.9 m vs 64.9 m (12.3 %) | units walk cache_b_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_b1-x_ford_s vs cache_b_b2-x_ford_n | 64.9 m vs 73.9 m (12.3 %) | units walk cache_b_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-wallow_a1 vs nat_node_b1-wallow_b1 | 52.6 m vs 60.0 m (12.2 %) | units walk nat_node_b1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-wallow_b1 vs nat_node_b2-wallow_b2 | 60.0 m vs 52.6 m (12.2 %) | units walk nat_node_b1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-post_w_a2 vs stag_b2-post_w_a1 | 150.2 m vs 131.9 m (12.2 %) | units walk stag_b1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_w_b2 vs stag_b1-post_w_a2 | 131.9 m vs 150.2 m (12.2 %) | units walk stag_b1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b1 vs keep_t3-shrine_b2 | 128.4 m vs 146.1 m (12.1 %) | units walk keep_t3-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-shrine_b2 vs keep_t4-shrine_a2 | 146.1 m vs 128.4 m (12.1 %) | units walk keep_t3-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-shrine_a1 vs keep_t4-shrine_a2 | 146.0 m vs 128.4 m (12.1 %) | units walk keep_t1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b1 vs keep_t1-shrine_a1 | 128.4 m vs 146.0 m (12.1 %) | units walk keep_t1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_b1 vs guilds_lodge_a2-cache_a_b2 | 197.3 m vs 224.0 m (11.9 %) | units walk guilds_lodge_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_a_b2 vs guilds_lodge_b2-cache_a_a2 | 224.0 m vs 197.3 m (11.9 %) | units walk guilds_lodge_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-lairs_one_b2 vs third_node_b2-lairs_one_a2 | 236.5 m vs 208.6 m (11.8 %) | units walk third_node_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-x_ford_s vs tower_c_b2-x_ford_n | 47.5 m vs 53.9 m (11.8 %) | units walk tower_c_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-ford_nest_a1 vs tower_c_b2-ford_nest_a2 | 47.5 m vs 53.9 m (11.8 %) | units walk tower_c_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_ford_n vs tower_c_a2-x_ford_s | 53.9 m vs 47.5 m (11.8 %) | units walk tower_c_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-ford_nest_a2 vs tower_c_a2-ford_nest_a1 | 53.9 m vs 47.5 m (11.8 %) | units walk tower_c_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-inn_b1 vs home_b_a2-inn_b2 | 120.6 m vs 136.6 m (11.7 %) | units walk home_b_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-inn_b2 vs home_b_b2-inn_a2 | 136.6 m vs 120.6 m (11.7 %) | units walk home_b_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-inn_a1 vs home_b_b2-inn_a2 | 136.6 m vs 120.6 m (11.7 %) | units walk home_b_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-inn_b1 vs home_b_b1-inn_a1 | 120.6 m vs 136.6 m (11.7 %) | units walk home_b_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-lairs_two_b2 vs post_s_a2-lairs_two_b1 | 73.2 m vs 82.9 m (11.7 %) | units walk post_s_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-ford_nest_a1 vs tower_c_b2-ford_nest_a2 | 47.6 m vs 53.9 m (11.7 %) | units walk tower_c_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-x_ford_s vs tower_c_b2-x_ford_n | 47.6 m vs 53.9 m (11.7 %) | units walk tower_c_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_ford_n vs tower_c_b1-x_ford_s | 53.9 m vs 47.6 m (11.7 %) | units walk tower_c_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-ford_nest_a2 vs tower_c_b1-ford_nest_a1 | 53.9 m vs 47.6 m (11.7 %) | units walk tower_c_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_b1 vs shrine_b1-post_s_a1 | 134.0 m vs 118.4 m (11.7 %) | units walk shrine_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_two_a2 vs stag_b1-lairs_two_b2 | 155.9 m vs 176.4 m (11.7 %) | units walk stag_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-lairs_two_b2 vs stag_b2-lairs_two_b1 | 176.4 m vs 155.9 m (11.7 %) | units walk stag_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-lairs_two_b1 vs post_s_b2-lairs_two_a1 | 82.9 m vs 73.2 m (11.7 %) | units walk post_s_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-nat_node_b2 vs home_b_b2-nat_node_a2 | 137.7 m vs 121.7 m (11.6 %) | units walk home_b_a2-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-nat_node_b1 vs home_b_a2-nat_node_b2 | 121.7 m vs 137.7 m (11.6 %) | units walk home_b_a2-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_b1 vs shrine_a2-post_s_b2 | 134.0 m vs 118.5 m (11.6 %) | units walk shrine_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-nat_node_a1 vs home_b_b2-nat_node_a2 | 137.6 m vs 121.7 m (11.6 %) | units walk home_b_b1-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-nat_node_b1 vs home_b_b1-nat_node_a1 | 121.7 m vs 137.6 m (11.6 %) | units walk home_b_b1-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-x_lane_e vs tower_r_b2-x_lane_w | 81.7 m vs 72.3 m (11.6 %) | units walk tower_r_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_lane_e vs tower_r_a2-x_lane_e | 72.3 m vs 81.7 m (11.6 %) | units walk tower_r_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-stag_b2 vs nat_node_b2-stag_a2 | 115.2 m vs 130.2 m (11.6 %) | units walk nat_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-tower_r_b2 vs nat_node_b2-tower_r_a2 | 96.9 m vs 109.5 m (11.5 %) | units walk nat_node_b2-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-x_lane_e vs tower_r_b1-x_lane_w | 81.7 m vs 72.3 m (11.5 %) | units walk tower_r_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_lodge_b1 vs third_node_a2-guilds_lodge_b2 | 216.4 m vs 244.5 m (11.5 %) | units walk third_node_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-guilds_lodge_b2 vs third_node_b2-guilds_lodge_a2 | 244.5 m vs 216.4 m (11.5 %) | units walk third_node_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_s_b2 vs wallow_b2-post_s_a2 | 185.5 m vs 164.2 m (11.5 %) | units walk wallow_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-post_s_a1 vs wallow_b2-post_s_a2 | 185.4 m vs 164.2 m (11.4 %) | units walk wallow_b1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-guilds_den_b2 vs third_node_b2-guilds_den_a2 | 244.3 m vs 216.3 m (11.4 %) | units walk third_node_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-lairs_two_b1 vs well_b1-lairs_two_a2 | 103.3 m vs 91.6 m (11.4 %) | units walk well_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b2 vs tower_r_b2-tower_c_a1 | 68.1 m vs 76.7 m (11.2 %) | units walk tower_r_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-tower_c_a2 vs tower_r_b2-tower_c_a1 | 68.2 m vs 76.7 m (11.1 %) | units walk tower_r_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_b1 vs well_a2-stag_b2 | 166.1 m vs 147.8 m (11.0 %) | units walk well_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_b2 vs shrine_a2-post_s_b1 | 99.8 m vs 112.1 m (11.0 %) | units walk shrine_a2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-post_s_b1 vs shrine_b2-post_s_a1 | 112.1 m vs 99.9 m (10.9 %) | units walk shrine_a2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-peddler_b1 vs tower_r_b1-peddler_a2 | 91.4 m vs 102.6 m (10.9 %) | units walk tower_r_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-lairs_one_b2 vs guilds_lodge_b2-lairs_one_a2 | 246.7 m vs 220.0 m (10.8 %) | units walk guilds_lodge_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-well_b2 vs third_node_b1-well_a1 | 197.7 m vs 176.3 m (10.8 %) | units walk third_node_a2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-stag_b2 vs tower_c_b2-stag_a2 | 99.6 m vs 111.7 m (10.8 %) | units walk tower_c_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-cache_a_a2 vs stag_b1-cache_a_b2 | 140.9 m vs 157.9 m (10.8 %) | units walk stag_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-cache_a_b2 vs stag_b2-cache_a_b1 | 157.9 m vs 140.9 m (10.8 %) | units walk stag_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-stag_a1 vs tower_c_b2-stag_a2 | 99.7 m vs 111.7 m (10.7 %) | units walk tower_c_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_ford_s vs tower_c_b2-x_ford_s | 34.6 m vs 38.7 m (10.7 %) | units walk tower_c_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-ford_nest_a1 vs tower_c_b2-ford_nest_a1 | 34.6 m vs 38.7 m (10.7 %) | units walk tower_c_b2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-keep_t1 vs keep_t4-keep_t3 | 150.7 m vs 168.8 m (10.7 %) | units walk keep_t4-keep_t3 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-x_ford_n vs ford_nest_a2-x_ford_s | 85.8 m vs 76.7 m (10.6 %) | units walk ford_nest_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-cache_b_b2 vs inn_b2-cache_b_a2 | 74.0 m vs 82.8 m (10.6 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_ford_s vs tower_c_b1-x_ford_n | 34.6 m vs 38.7 m (10.6 %) | units walk tower_c_b1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-ford_nest_a1 vs tower_c_b1-ford_nest_a2 | 34.6 m vs 38.7 m (10.6 %) | units walk tower_c_b1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-x_ford_s vs tower_c_a2-x_ford_n | 34.6 m vs 38.7 m (10.6 %) | units walk tower_c_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-ford_nest_a1 vs tower_c_a2-ford_nest_a2 | 34.6 m vs 38.7 m (10.6 %) | units walk tower_c_a2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b1 vs home_b_a2-shrine_b2 | 135.0 m vs 151.0 m (10.6 %) | units walk home_b_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-shrine_b2 vs home_b_b2-shrine_a2 | 151.0 m vs 135.0 m (10.6 %) | units walk home_b_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-cache_b_a1 vs inn_b2-cache_b_a2 | 74.0 m vs 82.8 m (10.6 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b1 vs home_b_b1-shrine_a1 | 135.0 m vs 151.0 m (10.6 %) | units walk home_b_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-shrine_a1 vs home_b_b2-shrine_a2 | 151.0 m vs 135.0 m (10.6 %) | units walk home_b_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-post_s_b1 vs shrine_b1-post_s_a2 | 112.1 m vs 100.3 m (10.6 %) | units walk shrine_a2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-guilds_lodge_b1 vs guilds_lodge_b2-guilds_lodge_a2 | 227.8 m vs 254.7 m (10.5 %) | units walk guilds_lodge_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_w_b2 vs wallow_b1-post_w_a1 | 194.6 m vs 174.2 m (10.5 %) | units walk wallow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_b1 vs home_a_b1-tower_c_a1 | 97.3 m vs 108.7 m (10.5 %) | units walk home_a_b1-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-tower_c_a1 vs home_a_b2-tower_c_a2 | 108.7 m vs 97.3 m (10.5 %) | units walk home_a_b1-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-tower_c_b2 vs home_a_b1-tower_c_a1 | 97.3 m vs 108.7 m (10.5 %) | units walk home_a_b1-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | x_bridge_n-x_ford_s vs x_bridge_s-x_ford_n | 104.7 m vs 116.9 m (10.4 %) | units walk x_bridge_s-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-stag_b1 vs shrine_b2-stag_a1 | 109.0 m vs 121.6 m (10.4 %) | units walk shrine_b2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_b1-x_bridge_s vs lairs_two_b2-x_bridge_n | 171.9 m vs 154.1 m (10.4 %) | units walk lairs_two_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a2-x_bridge_s vs lairs_two_b2-x_bridge_n | 171.9 m vs 154.1 m (10.3 %) | units walk lairs_two_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-peddler_b2 vs home_a_b2-peddler_a2 | 159.1 m vs 142.7 m (10.3 %) | units walk home_a_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-peddler_b1 vs home_a_a2-peddler_b2 | 142.7 m vs 159.1 m (10.3 %) | units walk home_a_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-peddler_a1 vs home_a_b2-peddler_a2 | 159.1 m vs 142.7 m (10.3 %) | units walk home_a_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-peddler_b1 vs home_a_b1-peddler_a1 | 142.7 m vs 159.1 m (10.3 %) | units walk home_a_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_two_b1 vs stag_b2-lairs_two_a1 | 93.9 m vs 84.2 m (10.3 %) | units walk stag_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_two_b2 vs stag_a2-lairs_two_b1 | 84.2 m vs 93.9 m (10.3 %) | units walk stag_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_w_a2 vs rich_node_b2-post_w_b2 | 86.8 m vs 77.9 m (10.2 %) | units walk rich_node_a2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_w_a1 vs rich_node_a2-post_w_a2 | 77.9 m vs 86.8 m (10.2 %) | units walk rich_node_a2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_w_a1 vs rich_node_b1-post_w_b1 | 77.9 m vs 86.8 m (10.2 %) | units walk rich_node_b1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_w_b1 vs rich_node_b2-post_w_b2 | 86.8 m vs 77.9 m (10.2 %) | units walk rich_node_b1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_a_b1 vs keep_t3-home_a_b2 | 152.6 m vs 170.0 m (10.2 %) | units walk keep_t3-home_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_a_b2 vs keep_t4-home_a_a2 | 170.0 m vs 152.6 m (10.2 %) | units walk keep_t3-home_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_b1 vs wallow_a2-stag_b2 | 169.2 m vs 188.4 m (10.2 %) | units walk wallow_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-home_a_a1 vs keep_t4-home_a_a2 | 169.9 m vs 152.6 m (10.2 %) | units walk keep_t1-home_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_a_b1 vs keep_t1-home_a_a1 | 152.6 m vs 169.9 m (10.2 %) | units walk keep_t1-home_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_b1 vs wallow_b1-stag_a1 | 169.2 m vs 188.4 m (10.2 %) | units walk wallow_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-x_lane_e vs stag_b1-x_lane_w | 100.9 m vs 90.6 m (10.2 %) | units walk stag_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_lane_w vs home_b_b2-x_lane_e | 64.0 m vs 71.2 m (10.2 %) | units walk home_b_b2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_lane_w vs home_b_a2-x_lane_w | 71.2 m vs 64.0 m (10.2 %) | units walk home_b_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-x_lane_e vs home_b_b2-x_lane_e | 64.0 m vs 71.2 m (10.2 %) | units walk home_b_b2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_lane_w vs home_b_b1-x_lane_e | 71.2 m vs 64.0 m (10.2 %) | units walk home_b_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-peddler_b1 vs stag_b1-peddler_a2 | 112.1 m vs 124.8 m (10.2 %) | units walk stag_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_two_b1 vs rich_node_b1-lairs_two_a2 | 75.5 m vs 67.9 m (10.1 %) | units walk rich_node_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_two_b2 vs rich_node_a2-lairs_two_b1 | 67.9 m vs 75.5 m (10.1 %) | units walk rich_node_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_b1 vs shrine_b2-post_s_a2 | 134.0 m vs 120.5 m (10.1 %) | units walk shrine_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-x_lane_e vs stag_b1-x_lane_w | 100.8 m vs 90.6 m (10.1 %) | units walk stag_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_two_b1 vs rich_node_b2-lairs_two_a1 | 75.5 m vs 67.9 m (10.1 %) | units walk rich_node_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_a_b2 vs third_node_b1-cache_a_a1 | 213.8 m vs 192.3 m (10.0 %) | units walk third_node_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_s_a1 vs well_b2-post_s_a2 | 144.9 m vs 161.0 m (10.0 %) | units walk well_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b2 vs tower_r_a2-tower_c_b1 | 68.1 m vs 75.7 m (10.0 %) | units walk tower_r_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_s_b2 vs well_b2-post_s_a2 | 144.9 m vs 161.0 m (10.0 %) | units walk well_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-tower_c_b2 vs tower_r_b1-tower_c_a1 | 90.3 m vs 81.3 m (10.0 %) | units walk tower_r_a2-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_b1 vs tower_r_a2-tower_c_b2 | 81.3 m vs 90.3 m (10.0 %) | units walk tower_r_a2-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-cache_a_a1 vs wallow_b2-cache_a_a2 | 191.2 m vs 172.1 m (10.0 %) | units walk wallow_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_a_b1 vs wallow_b1-cache_a_a1 | 172.1 m vs 191.2 m (10.0 %) | units walk wallow_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-cache_a_b2 vs wallow_b2-cache_a_a2 | 191.2 m vs 172.1 m (10.0 %) | units walk wallow_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_a_b1 vs wallow_a2-cache_a_b2 | 172.1 m vs 191.2 m (10.0 %) | units walk wallow_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-peddler_b2 vs tower_c_b2-peddler_b1 | 58.2 m vs 52.4 m (10.0 %) | units walk tower_c_b1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_a2 vs tower_c_b1-peddler_b2 | 52.4 m vs 58.2 m (10.0 %) | units walk tower_c_b1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-peddler_a1 vs tower_c_b2-peddler_b1 | 58.2 m vs 52.4 m (10.0 %) | units walk tower_c_a2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_a2 vs tower_c_a2-peddler_a1 | 52.4 m vs 58.2 m (10.0 %) | units walk tower_c_a2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_two_b1 vs wallow_b1-lairs_two_a1 | 182.2 m vs 202.3 m (9.9 %) | units walk wallow_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-post_s_b2 vs wallow_b2-post_s_b1 | 159.2 m vs 143.4 m (9.9 %) | units walk wallow_b1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_s_a2 vs wallow_b1-post_s_b2 | 143.4 m vs 159.2 m (9.9 %) | units walk wallow_b1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_two_b1 vs wallow_a2-lairs_two_b2 | 182.2 m vs 202.3 m (9.9 %) | units walk wallow_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-tower_c_b1 vs tower_r_b1-tower_c_a2 | 75.7 m vs 68.2 m (9.9 %) | units walk tower_r_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-inn_a1 vs stag_b2-inn_a2 | 116.6 m vs 129.4 m (9.9 %) | units walk stag_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-lairs_two_b2 vs third_node_b1-lairs_two_a1 | 228.2 m vs 205.6 m (9.9 %) | units walk third_node_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-inn_b2 vs stag_b2-inn_a2 | 116.6 m vs 129.4 m (9.9 %) | units walk stag_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-x_lane_e vs lairs_one_b1-x_lane_w | 119.1 m vs 132.2 m (9.9 %) | units walk lairs_one_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-x_bridge_s vs wallow_b2-x_bridge_n | 153.3 m vs 138.2 m (9.9 %) | units walk wallow_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-inn_b1 vs stag_b2-inn_a2 | 116.6 m vs 129.4 m (9.9 %) | units walk stag_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-peddler_a2 vs tower_c_b2-peddler_b2 | 45.5 m vs 50.4 m (9.9 %) | units walk tower_c_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_a1 vs tower_c_a2-peddler_a2 | 50.4 m vs 45.5 m (9.9 %) | units walk tower_c_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-peddler_b1 vs tower_c_b2-peddler_b2 | 45.5 m vs 50.4 m (9.9 %) | units walk tower_c_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_a1 vs tower_c_b1-peddler_b1 | 50.4 m vs 45.5 m (9.9 %) | units walk tower_c_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-stag_b1 vs third_node_b2-stag_a2 | 182.6 m vs 202.6 m (9.9 %) | units walk third_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-x_bridge_s vs wallow_b2-x_bridge_n | 153.3 m vs 138.2 m (9.8 %) | units walk wallow_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-x_bridge_s vs cache_a_b2-x_bridge_n | 155.2 m vs 140.0 m (9.8 %) | units walk cache_a_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-x_bridge_s vs cache_a_b2-x_bridge_n | 155.2 m vs 140.0 m (9.8 %) | units walk cache_a_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-post_w_b1 vs ford_nest_a2-post_w_a1 | 105.8 m vs 95.5 m (9.8 %) | units walk ford_nest_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-post_w_a2 vs ford_nest_a2-post_w_a1 | 105.8 m vs 95.5 m (9.8 %) | units walk ford_nest_a1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-lairs_two_b2 vs guilds_lodge_b2-lairs_two_a2 | 250.3 m vs 225.9 m (9.8 %) | units walk guilds_lodge_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-post_w_b1 vs ford_nest_a2-post_w_b2 | 105.8 m vs 95.5 m (9.8 %) | units walk ford_nest_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-post_w_a2 vs ford_nest_a2-post_w_b2 | 105.8 m vs 95.5 m (9.8 %) | units walk ford_nest_a1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-wallow_a2 vs nat_node_b1-wallow_b2 | 89.1 m vs 80.4 m (9.7 %) | units walk nat_node_a1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-wallow_a2 vs nat_node_a2-wallow_a1 | 89.1 m vs 80.4 m (9.7 %) | units walk nat_node_a1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_s_b1 vs well_b1-post_s_a1 | 160.5 m vs 144.9 m (9.7 %) | units walk well_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-inn_b1 vs tower_r_b1-inn_a1 | 108.8 m vs 98.3 m (9.7 %) | units walk tower_r_a1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_s_b1 vs well_a2-post_s_b2 | 160.5 m vs 144.9 m (9.7 %) | units walk well_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_b2 vs shrine_b2-stag_a1 | 109.9 m vs 121.6 m (9.7 %) | units walk shrine_b2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_b1 vs tower_r_b1-post_w_a2 | 119.2 m vs 131.9 m (9.6 %) | units walk tower_r_b1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-x_lane_w vs stag_b2-x_lane_w | 90.6 m vs 100.2 m (9.6 %) | units walk stag_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-inn_a1 vs tower_r_b2-inn_a2 | 98.3 m vs 108.7 m (9.6 %) | units walk tower_r_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-lairs_two_b1 vs third_node_b2-lairs_two_a2 | 195.6 m vs 216.2 m (9.5 %) | units walk third_node_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_one_b1 vs wallow_b2-lairs_one_a2 | 197.0 m vs 217.6 m (9.5 %) | units walk wallow_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_b1 vs wallow_b2-stag_a2 | 169.2 m vs 186.8 m (9.4 %) | units walk wallow_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-wallow_a2 vs nat_node_b1-wallow_b1 | 54.3 m vs 60.0 m (9.4 %) | units walk nat_node_b1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_s_a1 vs wallow_b1-post_s_b2 | 144.3 m vs 159.2 m (9.4 %) | units walk wallow_b1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-post_w_a1 vs keep_t4-post_w_a2 | 184.0 m vs 166.8 m (9.3 %) | units walk keep_t1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_w_b1 vs keep_t1-post_w_a1 | 166.8 m vs 184.0 m (9.3 %) | units walk keep_t1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-post_w_b2 vs tower_c_b2-post_w_b1 | 70.3 m vs 63.7 m (9.3 %) | units walk tower_c_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-post_w_a2 vs tower_c_b1-post_w_b2 | 63.7 m vs 70.3 m (9.3 %) | units walk tower_c_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-post_w_a2 vs tower_c_a2-post_w_a1 | 63.7 m vs 70.3 m (9.3 %) | units walk tower_c_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-post_w_a1 vs tower_c_b2-post_w_b1 | 70.3 m vs 63.7 m (9.3 %) | units walk tower_c_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-shrine_b2 vs rich_node_b1-shrine_a1 | 95.1 m vs 104.8 m (9.2 %) | units walk rich_node_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_one_a2 vs tower_r_b1-lairs_one_b1 | 51.6 m vs 56.9 m (9.2 %) | units walk tower_r_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_one_b1 vs tower_r_b2-lairs_one_b2 | 56.9 m vs 51.6 m (9.2 %) | units walk tower_r_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_a1 vs tower_r_b1-lairs_one_b1 | 51.6 m vs 56.9 m (9.2 %) | units walk tower_r_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-inn_a1 vs home_a_b2-inn_a2 | 124.8 m vs 113.4 m (9.2 %) | units walk home_a_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b1 vs home_a_b1-inn_a1 | 113.4 m vs 124.8 m (9.2 %) | units walk home_a_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b1 vs home_a_a2-inn_b2 | 113.4 m vs 124.8 m (9.2 %) | units walk home_a_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-inn_b2 vs home_a_b2-inn_a2 | 124.8 m vs 113.4 m (9.2 %) | units walk home_a_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-stag_a1 vs nat_node_b2-stag_a2 | 118.3 m vs 130.2 m (9.2 %) | units walk nat_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_two_b1 vs guilds_lodge_b1-lairs_two_a1 | 206.9 m vs 227.7 m (9.1 %) | units walk guilds_lodge_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-stag_a2 vs shrine_b2-stag_a1 | 110.5 m vs 121.6 m (9.1 %) | units walk shrine_b2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_two_b1 vs wallow_b2-lairs_two_a2 | 182.2 m vs 200.5 m (9.1 %) | units walk wallow_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_two_a1 vs stag_b1-lairs_two_b2 | 160.4 m vs 176.4 m (9.1 %) | units walk stag_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-guilds_den_b1 vs wallow_b2-guilds_den_a2 | 207.1 m vs 227.8 m (9.1 %) | units walk wallow_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-peddler_a2 vs tower_r_b2-peddler_a1 | 102.6 m vs 93.2 m (9.1 %) | units walk tower_r_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_s_a1 vs tower_r_b2-post_s_a2 | 152.5 m vs 167.7 m (9.1 %) | units walk tower_r_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-peddler_b2 vs tower_r_b1-peddler_a2 | 93.3 m vs 102.6 m (9.1 %) | units walk tower_r_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-nat_node_a1 vs home_a_b2-nat_node_a2 | 125.9 m vs 114.5 m (9.1 %) | units walk home_a_b1-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-nat_node_b1 vs home_a_b1-nat_node_a1 | 114.5 m vs 125.9 m (9.1 %) | units walk home_a_b1-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-nat_node_b1 vs home_a_a2-nat_node_b2 | 114.5 m vs 125.9 m (9.1 %) | units walk home_a_a2-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-nat_node_b2 vs home_a_b2-nat_node_a2 | 125.9 m vs 114.5 m (9.1 %) | units walk home_a_a2-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_bridge_n vs third_node_b2-x_bridge_n | 166.6 m vs 151.6 m (9.0 %) | units walk third_node_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-lairs_two_b2 vs guilds_lodge_b1-lairs_two_a1 | 250.3 m vs 227.7 m (9.0 %) | units walk guilds_lodge_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_bridge_n vs post_w_b2-x_bridge_n | 122.8 m vs 111.8 m (9.0 %) | units walk post_w_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-peddler_b1 vs rich_node_b2-peddler_a2 | 108.5 m vs 119.2 m (9.0 %) | units walk rich_node_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-third_node_b1 vs rich_node_b2-third_node_a2 | 148.0 m vs 162.5 m (8.9 %) | units walk rich_node_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-peddler_a1 vs rich_node_b2-peddler_a2 | 108.5 m vs 119.2 m (8.9 %) | units walk rich_node_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-cache_a_a2 vs tower_r_b2-cache_a_a1 | 67.8 m vs 61.8 m (8.9 %) | units walk tower_r_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_a_b2 vs tower_r_b1-cache_a_a2 | 61.8 m vs 67.8 m (8.9 %) | units walk tower_r_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a2 vs well_b1-post_w_b2 | 84.9 m vs 77.4 m (8.9 %) | units walk well_a1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-post_w_a1 vs well_b2-post_w_b1 | 77.4 m vs 84.9 m (8.9 %) | units walk well_b2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a2 vs well_a2-post_w_a1 | 84.9 m vs 77.4 m (8.9 %) | units walk well_a1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_w_b2 vs well_b2-post_w_b1 | 77.4 m vs 84.9 m (8.9 %) | units walk well_b2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-post_s_a1 vs inn_b2-post_s_a2 | 113.7 m vs 124.8 m (8.9 %) | units walk inn_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-post_s_b2 vs inn_b2-post_s_a2 | 113.7 m vs 124.8 m (8.9 %) | units walk inn_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-x_bridge_s vs guilds_lodge_b2-x_bridge_n | 178.7 m vs 162.9 m (8.8 %) | units walk guilds_lodge_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-home_b_a1 vs keep_t4-home_b_a2 | 165.3 m vs 150.7 m (8.8 %) | units walk keep_t1-home_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_b_b1 vs keep_t1-home_b_a1 | 150.7 m vs 165.3 m (8.8 %) | units walk keep_t1-home_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-x_bridge_s vs guilds_lodge_b2-x_bridge_n | 178.7 m vs 162.9 m (8.8 %) | units walk guilds_lodge_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_b_b2 vs keep_t4-home_b_a2 | 165.3 m vs 150.7 m (8.8 %) | units walk keep_t3-home_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_b_b1 vs keep_t3-home_b_b2 | 150.7 m vs 165.3 m (8.8 %) | units walk keep_t3-home_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-lairs_one_b1 vs third_node_a2-lairs_one_b2 | 215.7 m vs 236.5 m (8.8 %) | units walk third_node_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-tower_r_a1 vs nat_node_b2-tower_r_a2 | 99.9 m vs 109.5 m (8.8 %) | units walk nat_node_b2-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-well_a2 vs third_node_b2-well_a1 | 130.7 m vs 119.3 m (8.7 %) | units walk third_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-well_b2 vs third_node_b1-well_a2 | 119.3 m vs 130.7 m (8.7 %) | units walk third_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_b_b2 vs tower_r_b1-cache_b_a1 | 108.0 m vs 98.5 m (8.7 %) | units walk tower_r_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-peddler_a2 vs stag_b2-peddler_a1 | 124.8 m vs 113.9 m (8.7 %) | units walk stag_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-lairs_one_a1 vs guilds_lodge_b2-lairs_one_a2 | 240.9 m vs 220.0 m (8.7 %) | units walk guilds_lodge_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-peddler_b2 vs stag_b1-peddler_a2 | 113.9 m vs 124.8 m (8.7 %) | units walk stag_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_s_b1 vs home_b_b2-post_s_a2 | 163.6 m vs 149.4 m (8.7 %) | units walk home_b_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-wallow_a2 vs nat_node_b2-wallow_b1 | 89.1 m vs 81.4 m (8.6 %) | units walk nat_node_a1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-post_w_b2 vs keep_t1-post_w_a1 | 168.1 m vs 184.0 m (8.6 %) | units walk keep_t1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_one_b1 vs wallow_b1-lairs_one_a1 | 197.0 m vs 215.5 m (8.6 %) | units walk wallow_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_b1 vs rich_node_b2-wallow_a2 | 136.3 m vs 149.1 m (8.6 %) | units walk rich_node_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_one_b1 vs wallow_a2-lairs_one_b2 | 197.0 m vs 215.4 m (8.6 %) | units walk wallow_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-wallow_b2 vs rich_node_b2-wallow_a2 | 136.3 m vs 149.1 m (8.6 %) | units walk rich_node_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-wallow_a1 vs rich_node_b2-wallow_a2 | 136.3 m vs 149.1 m (8.6 %) | units walk rich_node_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_two_b1 vs tower_r_b1-lairs_two_a2 | 73.7 m vs 67.4 m (8.5 %) | units walk tower_r_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_s_b1 vs tower_r_b1-post_s_a1 | 166.6 m vs 152.5 m (8.5 %) | units walk tower_r_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-well_b1 vs third_node_b1-well_a2 | 119.6 m vs 130.7 m (8.5 %) | units walk third_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_b_b1 vs post_s_b1-cache_b_a1 | 124.5 m vs 114.0 m (8.5 %) | units walk post_s_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_s_b1 vs keep_t4-post_s_a2 | 158.6 m vs 145.2 m (8.5 %) | units walk keep_t0-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a2-peddler_b2 | 97.3 m vs 89.1 m (8.4 %) | units walk ford_nest_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a2-peddler_a1 | 97.3 m vs 89.1 m (8.4 %) | units walk ford_nest_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-x_bridge_n vs wallow_b2-x_bridge_n | 150.9 m vs 138.2 m (8.4 %) | units walk wallow_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_b1 vs ford_nest_a2-peddler_b2 | 97.3 m vs 89.1 m (8.4 %) | units walk ford_nest_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_b1 vs ford_nest_a2-peddler_a1 | 97.3 m vs 89.1 m (8.4 %) | units walk ford_nest_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-cache_b_a1 vs post_s_b2-cache_b_a2 | 114.0 m vs 124.4 m (8.4 %) | units walk post_s_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-lairs_two_b1 vs well_b2-lairs_two_a1 | 103.3 m vs 94.7 m (8.4 %) | units walk well_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_two_b1 vs guilds_lodge_b2-lairs_two_a2 | 206.9 m vs 225.9 m (8.4 %) | units walk guilds_lodge_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-lairs_two_b2 vs well_a2-lairs_two_b1 | 94.7 m vs 103.3 m (8.4 %) | units walk well_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-inn_a1 vs wallow_b2-inn_a2 | 142.9 m vs 131.0 m (8.3 %) | units walk wallow_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-inn_b1 vs wallow_b1-inn_a1 | 131.0 m vs 142.9 m (8.3 %) | units walk wallow_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-guilds_lodge_b1 vs rich_node_b2-guilds_lodge_a2 | 159.4 m vs 173.8 m (8.3 %) | units walk rich_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-guilds_lodge_b1 vs tower_r_b2-guilds_lodge_b2 | 74.3 m vs 68.2 m (8.3 %) | units walk tower_r_b1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_lodge_a1 vs tower_r_b1-guilds_lodge_b1 | 68.2 m vs 74.3 m (8.3 %) | units walk tower_r_b1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-tower_c_b1 vs home_a_b1-tower_c_a2 | 96.9 m vs 105.7 m (8.3 %) | units walk home_a_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_b1 vs home_b_a2-post_w_b2 | 173.3 m vs 188.9 m (8.2 %) | units walk home_b_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-post_w_b2 vs home_b_b2-post_w_a2 | 188.9 m vs 173.3 m (8.2 %) | units walk home_b_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_b2 vs home_a_b1-tower_c_a2 | 97.0 m vs 105.7 m (8.2 %) | units walk home_a_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-tower_c_a2 vs home_a_b2-tower_c_a1 | 105.7 m vs 97.0 m (8.2 %) | units walk home_a_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-cache_b_b1 vs inn_b2-cache_b_a2 | 76.0 m vs 82.8 m (8.2 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-shrine_b2 vs home_a_b2-shrine_a2 | 139.2 m vs 127.8 m (8.2 %) | units walk home_a_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b1 vs home_a_a2-shrine_b2 | 127.8 m vs 139.2 m (8.2 %) | units walk home_a_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-shrine_a1 vs home_a_b2-shrine_a2 | 139.2 m vs 127.8 m (8.2 %) | units walk home_a_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b1 vs home_a_b1-shrine_a1 | 127.8 m vs 139.2 m (8.2 %) | units walk home_a_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-cache_b_b2 vs cache_a_b1-cache_b_a1 | 119.5 m vs 130.1 m (8.2 %) | units walk cache_a_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-guilds_den_b2 vs shrine_b2-guilds_den_a2 | 157.6 m vs 171.6 m (8.2 %) | units walk shrine_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-cache_b_b1 vs nat_node_a2-cache_b_b2 | 79.0 m vs 72.6 m (8.2 %) | units walk nat_node_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-guilds_den_a1 vs shrine_b2-guilds_den_a2 | 157.6 m vs 171.6 m (8.2 %) | units walk shrine_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_a2-guilds_lodge_b2 | 227.7 m vs 247.9 m (8.1 %) | units walk guilds_den_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-lairs_two_b1 vs post_s_b1-lairs_two_a2 | 82.9 m vs 76.2 m (8.1 %) | units walk post_s_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-third_node_a1 vs nat_node_b1-third_node_b1 | 63.0 m vs 68.6 m (8.1 %) | units walk nat_node_b1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-third_node_b1 vs nat_node_b2-third_node_b2 | 68.6 m vs 63.0 m (8.1 %) | units walk nat_node_b1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-lairs_one_b2 vs shrine_b2-lairs_one_a2 | 148.4 m vs 161.5 m (8.1 %) | units walk shrine_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-inn_b2 vs tower_r_b1-inn_a1 | 106.9 m vs 98.3 m (8.1 %) | units walk tower_r_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-stag_a1 vs well_b2-stag_a2 | 157.4 m vs 171.3 m (8.1 %) | units walk well_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-lairs_one_a1 vs shrine_b2-lairs_one_a2 | 148.4 m vs 161.5 m (8.1 %) | units walk shrine_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-cache_b_b2 vs nat_node_b2-cache_b_a2 | 72.6 m vs 78.9 m (8.1 %) | units walk nat_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-x_bridge_n vs well_b1-x_bridge_n | 45.5 m vs 41.8 m (8.1 %) | units walk well_a2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_two_b1 vs cache_a_b1-lairs_two_a2 | 105.0 m vs 96.5 m (8.1 %) | units walk cache_a_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_two_b1 vs home_b_b1-lairs_two_a2 | 128.9 m vs 118.5 m (8.1 %) | units walk home_b_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_two_b1 vs cache_a_b2-lairs_two_a1 | 105.0 m vs 96.5 m (8.0 %) | units walk cache_a_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_two_b2 vs cache_a_a2-lairs_two_b1 | 96.5 m vs 105.0 m (8.0 %) | units walk cache_a_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_s_b1 vs home_a_b2-post_s_a2 | 150.9 m vs 138.8 m (8.0 %) | units walk home_a_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-crown vs home_b_b2-crown | 75.2 m vs 81.8 m (8.0 %) | units walk home_b_b2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-crown vs home_b_b2-crown | 75.2 m vs 81.8 m (8.0 %) | units walk home_b_b2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-crown vs home_b_a2-crown | 81.8 m vs 75.2 m (8.0 %) | units walk home_b_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-crown vs home_b_b1-crown | 81.8 m vs 75.2 m (8.0 %) | units walk home_b_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_bridge_n vs post_w_a2-x_bridge_s | 122.8 m vs 113.0 m (8.0 %) | units walk post_w_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-peddler_a1 vs post_w_b2-peddler_a2 | 163.4 m vs 150.3 m (8.0 %) | units walk post_w_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-peddler_b1 vs post_w_b1-peddler_a1 | 150.3 m vs 163.4 m (8.0 %) | units walk post_w_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-guilds_lodge_a1 vs wallow_b2-guilds_lodge_a2 | 227.7 m vs 209.5 m (8.0 %) | units walk wallow_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-guilds_lodge_b2 vs wallow_b2-guilds_lodge_a2 | 227.7 m vs 209.5 m (8.0 %) | units walk wallow_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_bridge_n vs post_w_b1-x_bridge_s | 122.8 m vs 113.0 m (8.0 %) | units walk post_w_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-peddler_b2 vs post_w_b2-peddler_a2 | 163.4 m vs 150.3 m (8.0 %) | units walk post_w_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-peddler_b1 vs post_w_a2-peddler_b2 | 150.3 m vs 163.4 m (8.0 %) | units walk post_w_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_one_b1 vs guilds_lodge_a2-lairs_one_b2 | 227.1 m vs 246.7 m (7.9 %) | units walk guilds_lodge_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-x_ford_s vs tower_r_b2-x_ford_n | 102.8 m vs 111.6 m (7.9 %) | units walk tower_r_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-ford_nest_a2 vs tower_r_b1-ford_nest_a1 | 111.6 m vs 102.8 m (7.9 %) | units walk tower_r_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_ford_n vs tower_r_b1-x_ford_s | 111.6 m vs 102.8 m (7.9 %) | units walk tower_r_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-ford_nest_a1 vs tower_r_b2-ford_nest_a2 | 102.8 m vs 111.6 m (7.9 %) | units walk tower_r_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_a1 vs keep_t3-nat_node_a2 | 35.8 m vs 38.9 m (7.9 %) | units walk keep_t3-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_a1 vs keep_t1-nat_node_b1 | 35.8 m vs 38.9 m (7.9 %) | units walk keep_t1-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_a_b2 vs post_s_b1-cache_a_a2 | 70.5 m vs 76.6 m (7.9 %) | units walk post_s_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-guilds_den_b1 vs wallow_b1-guilds_den_a1 | 207.1 m vs 224.7 m (7.8 %) | units walk wallow_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_a_a2 vs wallow_b2-cache_a_b1 | 128.7 m vs 118.6 m (7.8 %) | units walk wallow_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-guilds_den_b1 vs wallow_a2-guilds_den_b2 | 207.1 m vs 224.7 m (7.8 %) | units walk wallow_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-cache_a_a1 vs stag_b1-cache_a_b2 | 145.5 m vs 157.9 m (7.8 %) | units walk stag_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-cache_a_a2 vs post_s_b2-cache_a_a1 | 76.6 m vs 70.6 m (7.8 %) | units walk post_s_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-lairs_one_b1 vs inn_b1-lairs_one_a2 | 111.2 m vs 120.6 m (7.8 %) | units walk inn_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-guilds_den_a2 vs tower_r_b1-guilds_den_b1 | 61.8 m vs 67.0 m (7.7 %) | units walk tower_r_b1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-guilds_den_b1 vs tower_r_b2-guilds_den_b2 | 67.0 m vs 61.8 m (7.7 %) | units walk tower_r_b1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_den_a1 vs tower_r_b1-guilds_den_b1 | 61.8 m vs 67.0 m (7.7 %) | units walk tower_r_b1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_a1 vs keep_t4-nat_node_b2 | 35.8 m vs 38.8 m (7.7 %) | units walk keep_t4-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_bridge_s vs well_b1-x_bridge_n | 45.3 m vs 41.8 m (7.7 %) | units walk well_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-x_bridge_n vs well_b2-x_bridge_s | 41.8 m vs 45.3 m (7.7 %) | units walk well_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-lairs_two_b1 vs guilds_lodge_b2-lairs_two_a1 | 145.6 m vs 134.5 m (7.6 %) | units walk guilds_lodge_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_two_b2 vs guilds_lodge_a2-lairs_two_b1 | 134.5 m vs 145.6 m (7.6 %) | units walk guilds_lodge_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_bridge_n vs guilds_lodge_b2-x_bridge_n | 176.3 m vs 162.9 m (7.6 %) | units walk guilds_lodge_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-home_b_b1 vs home_b_b2-home_b_a2 | 157.3 m vs 170.2 m (7.6 %) | units walk home_b_b2-home_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_a2 vs ford_nest_a2-guilds_lodge_a1 | 151.9 m vs 140.4 m (7.6 %) | units walk ford_nest_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_b1 vs ford_nest_a2-guilds_lodge_a1 | 151.9 m vs 140.4 m (7.6 %) | units walk ford_nest_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_den_b1 vs third_node_a2-guilds_den_b2 | 225.8 m vs 244.3 m (7.6 %) | units walk third_node_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_b1 vs ford_nest_a2-guilds_lodge_b2 | 151.9 m vs 140.5 m (7.5 %) | units walk ford_nest_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_a2 vs ford_nest_a2-guilds_lodge_b2 | 151.9 m vs 140.5 m (7.5 %) | units walk ford_nest_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_w_b2 vs rich_node_b2-post_w_a2 | 118.1 m vs 127.7 m (7.5 %) | units walk rich_node_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-ford_nest_a1 vs rich_node_b2-ford_nest_a2 | 92.6 m vs 100.1 m (7.5 %) | units walk rich_node_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-ford_nest_a2 vs rich_node_b1-ford_nest_a1 | 100.1 m vs 92.6 m (7.5 %) | units walk rich_node_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-x_ford_n vs rich_node_b1-x_ford_s | 100.1 m vs 92.6 m (7.5 %) | units walk rich_node_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-x_ford_s vs rich_node_b2-x_ford_n | 92.6 m vs 100.1 m (7.5 %) | units walk rich_node_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-cache_b_a2 vs guilds_den_b2-cache_b_a1 | 110.7 m vs 102.4 m (7.5 %) | units walk guilds_den_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-lairs_one_b2 vs third_node_b1-lairs_one_a1 | 236.5 m vs 218.7 m (7.5 %) | units walk third_node_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-cache_a_a1 vs stag_b2-cache_a_a2 | 161.8 m vs 174.9 m (7.5 %) | units walk stag_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_b_b2 vs guilds_den_b1-cache_b_a2 | 102.4 m vs 110.7 m (7.5 %) | units walk guilds_den_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-x_lane_e vs cache_a_b1-x_lane_w | 96.1 m vs 103.9 m (7.5 %) | units walk cache_a_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-cache_a_b2 vs stag_b2-cache_a_a2 | 161.9 m vs 174.9 m (7.5 %) | units walk stag_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_b_b1 vs guilds_den_b1-cache_b_a2 | 102.5 m vs 110.7 m (7.4 %) | units walk guilds_den_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_s_b1 vs third_node_b1-post_s_a1 | 203.9 m vs 188.7 m (7.4 %) | units walk third_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-cache_a_b1 vs stag_b2-cache_a_a2 | 161.9 m vs 174.9 m (7.4 %) | units walk stag_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_w_a1 vs rich_node_b1-post_w_b2 | 101.0 m vs 93.5 m (7.4 %) | units walk rich_node_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-lairs_one_b1 vs well_b1-lairs_one_a2 | 117.4 m vs 108.7 m (7.4 %) | units walk well_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_s_b1 vs third_node_a2-post_s_b2 | 203.9 m vs 188.8 m (7.4 %) | units walk third_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-post_s_b1 vs nat_node_a2-post_s_b2 | 121.2 m vs 112.3 m (7.3 %) | units walk nat_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-well_b1 vs tower_r_b1-well_a1 | 137.5 m vs 127.4 m (7.3 %) | units walk tower_r_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-x_ford_n vs guilds_lodge_b2-x_ford_s | 98.7 m vs 91.5 m (7.3 %) | units walk guilds_lodge_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_ford_s vs guilds_lodge_a2-x_ford_n | 91.5 m vs 98.7 m (7.3 %) | units walk guilds_lodge_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-x_bridge_n vs peddler_b1-x_bridge_n | 82.1 m vs 76.1 m (7.3 %) | units walk peddler_a2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_ford_n vs lairs_one_a2-x_ford_s | 142.4 m vs 132.0 m (7.3 %) | units walk lairs_one_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-x_ford_s vs lairs_one_b2-x_ford_n | 132.0 m vs 142.4 m (7.3 %) | units walk lairs_one_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t1-wallow_a1 | 167.7 m vs 180.8 m (7.2 %) | units walk keep_t1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_s_b2 vs inn_b2-post_s_a1 | 76.1 m vs 82.0 m (7.2 %) | units walk inn_b2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_ford_n vs lairs_one_b1-x_ford_s | 142.4 m vs 132.1 m (7.2 %) | units walk lairs_one_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_a_b1 vs tower_r_b1-cache_a_a2 | 62.9 m vs 67.8 m (7.2 %) | units walk tower_r_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-guilds_den_b1 vs inn_b1-guilds_den_a2 | 121.3 m vs 130.8 m (7.2 %) | units walk inn_b1-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_w_b1 vs rich_node_b2-post_w_a2 | 118.5 m vs 127.7 m (7.2 %) | units walk rich_node_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-x_ford_s vs lairs_one_b2-x_ford_n | 132.1 m vs 142.4 m (7.2 %) | units walk lairs_one_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-well_a1 vs tower_r_b2-well_a2 | 127.4 m vs 137.3 m (7.2 %) | units walk tower_r_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t3-wallow_b2 | 167.7 m vs 180.8 m (7.2 %) | units walk keep_t3-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_two_b1 vs stag_b1-lairs_two_a2 | 93.9 m vs 87.1 m (7.2 %) | units walk stag_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_two_b1 vs tower_r_b1-lairs_two_a1 | 170.2 m vs 158.0 m (7.2 %) | units walk tower_r_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_b2-guilds_lodge_a2 | 227.7 m vs 245.3 m (7.2 %) | units walk guilds_den_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-stag_a1 vs shrine_b2-stag_a2 | 121.3 m vs 130.7 m (7.1 %) | units walk shrine_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-stag_b2 vs shrine_b2-stag_a2 | 121.4 m vs 130.7 m (7.1 %) | units walk shrine_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-x_bridge_n vs peddler_b2-x_bridge_s | 76.1 m vs 82.0 m (7.1 %) | units walk peddler_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-x_bridge_s vs peddler_b1-x_bridge_n | 82.0 m vs 76.1 m (7.1 %) | units walk peddler_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_w_b2 vs rich_node_b1-post_w_a1 | 118.1 m vs 127.1 m (7.1 %) | units walk rich_node_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-guilds_den_b2 vs inn_b1-guilds_den_a2 | 121.5 m vs 130.8 m (7.1 %) | units walk inn_b1-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-guilds_den_a2 vs inn_b2-guilds_den_a1 | 130.8 m vs 121.5 m (7.1 %) | units walk inn_b1-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_two_a2 vs wallow_b2-lairs_two_b1 | 143.6 m vs 133.5 m (7.0 %) | units walk wallow_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_a2 vs tower_r_b2-post_w_b2 | 89.8 m vs 83.5 m (7.0 %) | units walk tower_r_a2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_w_b1 vs tower_r_b2-post_w_b2 | 89.8 m vs 83.5 m (7.0 %) | units walk tower_r_b1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-post_s_b2 vs stag_b2-post_s_a2 | 163.9 m vs 176.2 m (7.0 %) | units walk stag_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-guilds_lodge_a2 vs tower_r_b1-guilds_lodge_b1 | 69.2 m vs 74.3 m (7.0 %) | units walk tower_r_b1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_b2-cache_a_b1 | 154.1 m vs 143.4 m (7.0 %) | units walk guilds_lodge_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a1 vs tower_r_b2-post_w_b2 | 89.8 m vs 83.5 m (7.0 %) | units walk tower_r_a1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-lairs_two_a1 vs stag_b2-lairs_two_a2 | 176.3 m vs 189.4 m (6.9 %) | units walk stag_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-x_lane_w vs home_b_b2-x_lane_w | 88.1 m vs 94.7 m (6.9 %) | units walk home_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_lane_e vs home_b_a2-x_lane_e | 94.7 m vs 88.1 m (6.9 %) | units walk home_b_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_lane_e vs home_b_b1-x_lane_w | 94.7 m vs 88.1 m (6.9 %) | units walk home_b_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_lane_e vs home_b_b2-x_lane_w | 88.1 m vs 94.7 m (6.9 %) | units walk home_b_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-shrine_b2 vs shrine_a2-shrine_b1 | 120.3 m vs 112.0 m (6.9 %) | units walk shrine_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-lairs_one_a2 vs inn_b2-lairs_one_a1 | 120.6 m vs 112.2 m (6.9 %) | units walk inn_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-lairs_one_b2 vs inn_b1-lairs_one_a2 | 112.2 m vs 120.6 m (6.9 %) | units walk inn_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a2 vs tower_r_a2-post_w_a1 | 109.6 m vs 102.0 m (6.9 %) | units walk tower_r_a1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_a1 vs tower_r_b2-post_w_b1 | 102.0 m vs 109.6 m (6.9 %) | units walk tower_r_b2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_two_b2 vs stag_b2-lairs_two_a2 | 176.3 m vs 189.4 m (6.9 %) | units walk stag_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-well_b1 vs rich_node_b1-well_a2 | 59.0 m vs 63.4 m (6.9 %) | units walk rich_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_a_b2 vs guilds_lodge_b1-cache_a_a1 | 224.0 m vs 208.5 m (6.9 %) | units walk guilds_lodge_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-stag_b1 vs nat_node_b2-stag_a2 | 121.3 m vs 130.2 m (6.9 %) | units walk nat_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-cache_b_b1 vs stag_b1-cache_b_a1 | 125.5 m vs 116.8 m (6.9 %) | units walk stag_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-cache_b_b1 vs stag_b2-cache_b_a2 | 125.5 m vs 116.9 m (6.9 %) | units walk stag_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-post_w_b1 vs stag_b1-post_w_a2 | 139.9 m vs 150.2 m (6.8 %) | units walk stag_b1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a2-x_lane_e vs lairs_two_b1-x_lane_w | 110.3 m vs 118.4 m (6.8 %) | units walk lairs_two_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-stag_a2 vs tower_r_b2-stag_a1 | 54.9 m vs 51.1 m (6.8 %) | units walk tower_r_b1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_b2 vs tower_r_b1-stag_a2 | 51.1 m vs 54.9 m (6.8 %) | units walk tower_r_b1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_b1 vs tower_r_b1-stag_a1 | 160.2 m vs 149.3 m (6.8 %) | units walk tower_r_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_w_b1 vs rich_node_b1-post_w_a1 | 118.5 m vs 127.1 m (6.8 %) | units walk rich_node_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-home_a_b1 vs home_a_b2-home_a_a2 | 152.0 m vs 163.1 m (6.8 %) | units walk home_a_b2-home_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-inn_a2 vs third_node_a2-inn_a1 | 99.9 m vs 107.2 m (6.8 %) | units walk third_node_a2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-inn_a1 vs third_node_b2-inn_b1 | 107.2 m vs 99.9 m (6.8 %) | units walk third_node_a2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_c_b2 vs third_node_b1-tower_c_a2 | 125.1 m vs 116.6 m (6.8 %) | units walk third_node_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-stag_b1 vs tower_r_b1-stag_a2 | 51.2 m vs 54.9 m (6.8 %) | units walk tower_r_b1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-cache_a_a2 vs stag_b2-cache_a_a1 | 87.5 m vs 81.5 m (6.8 %) | units walk stag_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-cache_a_b2 vs stag_b1-cache_a_a2 | 81.6 m vs 87.5 m (6.8 %) | units walk stag_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-stag_a2 vs keep_t4-stag_a1 | 121.9 m vs 113.7 m (6.8 %) | units walk keep_t1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-stag_b2 vs keep_t1-stag_a2 | 113.7 m vs 121.9 m (6.8 %) | units walk keep_t1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-inn_b2 vs third_node_b2-inn_b1 | 107.1 m vs 99.9 m (6.8 %) | units walk third_node_b1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-inn_a2 vs third_node_b1-inn_b2 | 99.9 m vs 107.1 m (6.8 %) | units walk third_node_b1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-lairs_two_b1 vs inn_b1-lairs_two_a2 | 96.5 m vs 103.4 m (6.8 %) | units walk inn_b1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-guilds_den_b1 vs well_b1-guilds_den_a2 | 127.5 m vs 118.9 m (6.8 %) | units walk well_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-lairs_two_b2 vs shrine_b2-lairs_two_b1 | 91.3 m vs 97.9 m (6.8 %) | units walk shrine_b2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_two_a2 vs shrine_b1-lairs_two_b2 | 97.9 m vs 91.3 m (6.8 %) | units walk shrine_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-lairs_two_a1 vs shrine_b2-lairs_two_b1 | 91.3 m vs 97.9 m (6.8 %) | units walk shrine_b2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_two_a2 vs shrine_a2-lairs_two_a1 | 97.9 m vs 91.3 m (6.8 %) | units walk shrine_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-stag_a1 vs tower_r_b2-stag_a2 | 149.3 m vs 160.1 m (6.7 %) | units walk tower_r_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_b1 vs tower_r_b2-post_w_a1 | 119.2 m vs 111.2 m (6.7 %) | units walk tower_r_a2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-third_node_a2 vs nat_node_b1-third_node_b1 | 63.9 m vs 68.6 m (6.7 %) | units walk nat_node_b1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-tower_c_a2 vs third_node_b2-tower_c_a1 | 116.6 m vs 125.0 m (6.7 %) | units walk third_node_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_b_b2 vs post_s_b1-cache_b_a2 | 65.9 m vs 61.4 m (6.7 %) | units walk post_s_a1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-inn_b1 vs tower_r_b2-inn_a1 | 70.4 m vs 65.6 m (6.7 %) | units walk tower_r_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_b2 vs tower_r_a2-post_w_b1 | 111.2 m vs 119.2 m (6.7 %) | units walk tower_r_a2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_a2 vs shrine_b1-inn_b2 | 42.8 m vs 45.8 m (6.7 %) | units walk shrine_b1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-inn_a1 vs shrine_b2-inn_b1 | 45.8 m vs 42.8 m (6.7 %) | units walk shrine_a2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-inn_b2 vs shrine_b2-inn_b1 | 45.8 m vs 42.8 m (6.7 %) | units walk shrine_b1-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_a2 vs shrine_a2-inn_a1 | 42.8 m vs 45.8 m (6.7 %) | units walk shrine_a2-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-x_lane_e vs cache_a_b1-x_lane_w | 97.0 m vs 103.9 m (6.7 %) | units walk cache_a_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-x_lane_w vs cache_a_b2-x_lane_w | 103.9 m vs 97.0 m (6.7 %) | units walk cache_a_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-stag_b1 vs keep_t1-stag_a2 | 113.8 m vs 121.9 m (6.7 %) | units walk keep_t1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-cache_a_b1 vs peddler_b1-cache_a_a2 | 129.2 m vs 120.6 m (6.7 %) | units walk peddler_a2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-guilds_den_b2 vs third_node_b1-guilds_den_a1 | 244.3 m vs 228.0 m (6.7 %) | units walk third_node_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-x_ford_n vs guilds_lodge_b1-x_ford_n | 98.7 m vs 92.1 m (6.7 %) | units walk guilds_lodge_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-well_b1 vs rich_node_b2-well_a1 | 59.0 m vs 63.2 m (6.7 %) | units walk rich_node_b2-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_two_b1 vs home_b_b2-lairs_two_a1 | 128.9 m vs 120.3 m (6.6 %) | units walk home_b_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_b2 vs home_b_a2-lairs_two_b1 | 120.3 m vs 128.9 m (6.6 %) | units walk home_b_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-cache_b_b1 vs post_s_b1-cache_b_a2 | 65.8 m vs 61.4 m (6.6 %) | units walk post_s_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-rich_node_b1 vs nat_node_a2-rich_node_b2 | 91.8 m vs 85.7 m (6.6 %) | units walk nat_node_a1-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_b1 vs cache_a_b1-cache_b_a1 | 121.5 m vs 130.1 m (6.6 %) | units walk cache_a_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-cache_b_a1 vs cache_a_b2-cache_b_a2 | 130.1 m vs 121.5 m (6.6 %) | units walk cache_a_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-post_s_b1 vs tower_c_b1-post_s_a1 | 103.5 m vs 96.7 m (6.6 %) | units walk tower_c_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-post_s_b1 vs tower_c_a2-post_s_b2 | 103.5 m vs 96.7 m (6.6 %) | units walk tower_c_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-lairs_two_b1 vs lairs_one_b2-lairs_two_a1 | 129.9 m vs 121.4 m (6.6 %) | units walk lairs_one_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_b1-guilds_lodge_a1 | 227.7 m vs 243.7 m (6.6 %) | units walk guilds_den_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-inn_b2 vs tower_r_a2-inn_b1 | 65.8 m vs 70.4 m (6.6 %) | units walk tower_r_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-lairs_two_b2 vs lairs_one_a2-lairs_two_b1 | 121.4 m vs 129.9 m (6.6 %) | units walk lairs_one_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_one_b1 vs tower_r_b2-lairs_one_a1 | 87.8 m vs 82.0 m (6.6 %) | units walk tower_r_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-rich_node_b2 vs nat_node_b2-rich_node_a2 | 85.7 m vs 91.7 m (6.5 %) | units walk nat_node_b2-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-lairs_one_b2 vs post_s_a2-lairs_one_b1 | 90.7 m vs 97.0 m (6.5 %) | units walk post_s_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_b2 vs tower_r_a2-lairs_one_b1 | 82.0 m vs 87.8 m (6.5 %) | units walk tower_r_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-well_b2 vs rich_node_a2-well_b1 | 63.1 m vs 59.0 m (6.5 %) | units walk rich_node_a1-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-shrine_a2 vs home_b_b2-shrine_a1 | 123.9 m vs 132.6 m (6.5 %) | units walk home_b_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_lane_e vs lairs_two_b1-x_lane_w | 110.6 m vs 118.4 m (6.5 %) | units walk lairs_two_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_b1-x_lane_w vs lairs_two_b2-x_lane_w | 118.4 m vs 110.6 m (6.5 %) | units walk lairs_two_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-lairs_two_b1 vs lairs_one_b1-lairs_two_a2 | 129.9 m vs 121.4 m (6.5 %) | units walk lairs_one_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-guilds_den_b2 vs nat_node_b1-guilds_den_a2 | 127.8 m vs 136.8 m (6.5 %) | units walk nat_node_b1-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-guilds_den_a2 vs nat_node_b2-guilds_den_a1 | 136.8 m vs 127.8 m (6.5 %) | units walk nat_node_b1-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-shrine_b1 vs home_b_b2-shrine_a1 | 123.9 m vs 132.6 m (6.5 %) | units walk home_b_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b2 vs home_b_b1-shrine_a2 | 132.5 m vs 123.9 m (6.5 %) | units walk home_b_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-well_b2 vs tower_r_b1-well_a1 | 136.3 m vs 127.4 m (6.5 %) | units walk tower_r_a2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-lairs_one_b1 vs post_s_b2-lairs_one_a1 | 97.0 m vs 90.7 m (6.5 %) | units walk post_s_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-lairs_two_b1 vs third_node_b2-lairs_two_a1 | 136.1 m vs 127.2 m (6.5 %) | units walk third_node_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b2 vs home_b_a2-shrine_b1 | 132.5 m vs 123.9 m (6.5 %) | units walk home_b_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-lairs_two_b2 vs third_node_a2-lairs_two_b1 | 127.3 m vs 136.1 m (6.5 %) | units walk third_node_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-ford_nest_a2 vs third_node_a2-ford_nest_a1 | 130.6 m vs 139.6 m (6.5 %) | units walk third_node_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_ford_n vs third_node_a2-x_ford_s | 130.6 m vs 139.6 m (6.5 %) | units walk third_node_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-x_ford_s vs third_node_b2-x_ford_n | 139.6 m vs 130.6 m (6.5 %) | units walk third_node_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-ford_nest_a1 vs third_node_b2-ford_nest_a2 | 139.6 m vs 130.6 m (6.5 %) | units walk third_node_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-cache_b_a2 vs post_s_b2-cache_b_a1 | 61.4 m vs 65.7 m (6.5 %) | units walk post_s_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_a_b1 vs tower_r_b1-cache_a_a1 | 153.5 m vs 143.5 m (6.5 %) | units walk tower_r_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_ford_n vs third_node_b1-x_ford_s | 130.6 m vs 139.6 m (6.5 %) | units walk third_node_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-ford_nest_a2 vs third_node_b1-ford_nest_a1 | 130.6 m vs 139.6 m (6.5 %) | units walk third_node_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-ford_nest_a1 vs third_node_b2-ford_nest_a2 | 139.6 m vs 130.6 m (6.5 %) | units walk third_node_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-x_ford_s vs third_node_b2-x_ford_n | 139.6 m vs 130.6 m (6.5 %) | units walk third_node_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-shrine_a2 vs keep_t4-shrine_a1 | 125.4 m vs 134.0 m (6.4 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-shrine_b1 vs keep_t4-shrine_a1 | 125.4 m vs 134.0 m (6.4 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b2 vs keep_t1-shrine_a2 | 134.0 m vs 125.4 m (6.4 %) | units walk keep_t0-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_s_b2 vs nat_node_b2-post_s_a2 | 112.3 m vs 120.0 m (6.4 %) | units walk nat_node_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-shrine_a2 vs rich_node_b1-shrine_b2 | 73.5 m vs 78.6 m (6.4 %) | units walk rich_node_b1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b2 vs keep_t3-shrine_b1 | 134.0 m vs 125.4 m (6.4 %) | units walk keep_t0-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-cache_a_a1 vs tower_r_b2-cache_a_a2 | 143.5 m vs 153.4 m (6.4 %) | units walk tower_r_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_two_a1 vs tower_r_b2-lairs_two_a2 | 158.0 m vs 168.7 m (6.4 %) | units walk tower_r_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-guilds_lodge_b1 vs well_b1-guilds_lodge_a2 | 134.9 m vs 126.3 m (6.4 %) | units walk well_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-lairs_two_b1 vs keep_t4-lairs_two_a1 | 135.7 m vs 127.1 m (6.3 %) | units walk keep_t3-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-lairs_one_a2 vs nat_node_b2-lairs_one_a1 | 126.6 m vs 118.6 m (6.3 %) | units walk nat_node_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-lairs_one_b2 vs nat_node_b1-lairs_one_a2 | 118.6 m vs 126.6 m (6.3 %) | units walk nat_node_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_two_b2 vs keep_t3-lairs_two_b1 | 127.1 m vs 135.7 m (6.3 %) | units walk keep_t3-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-shrine_b1 vs tower_r_b1-shrine_a2 | 89.2 m vs 95.2 m (6.3 %) | units walk tower_r_b1-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-shrine_a2 vs tower_r_b2-shrine_a1 | 95.2 m vs 89.2 m (6.3 %) | units walk tower_r_b1-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-guilds_lodge_b1 vs third_node_b1-guilds_lodge_a1 | 216.4 m vs 231.0 m (6.3 %) | units walk third_node_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-guilds_lodge_a1 vs third_node_b2-guilds_lodge_a2 | 231.0 m vs 216.4 m (6.3 %) | units walk third_node_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-peddler_b2 vs rich_node_b2-peddler_a2 | 111.7 m vs 119.2 m (6.3 %) | units walk rich_node_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-shrine_a2 vs nat_node_b2-shrine_a1 | 94.1 m vs 100.4 m (6.3 %) | units walk nat_node_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-x_ford_s vs rich_node_b2-x_ford_n | 93.8 m vs 100.1 m (6.3 %) | units walk rich_node_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-ford_nest_a1 vs rich_node_b2-ford_nest_a2 | 93.8 m vs 100.1 m (6.3 %) | units walk rich_node_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-ford_nest_a2 vs rich_node_a2-ford_nest_a1 | 100.1 m vs 93.8 m (6.3 %) | units walk rich_node_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-x_ford_n vs rich_node_a2-x_ford_s | 100.1 m vs 93.8 m (6.3 %) | units walk rich_node_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-wallow_b2 vs third_node_b1-wallow_a2 | 157.5 m vs 168.0 m (6.3 %) | units walk third_node_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-wallow_a2 vs third_node_b2-wallow_a1 | 168.0 m vs 157.5 m (6.3 %) | units walk third_node_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-shrine_b1 vs nat_node_b2-shrine_a1 | 94.1 m vs 100.4 m (6.3 %) | units walk nat_node_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-tower_c_a1 vs home_b_b2-tower_c_a2 | 98.0 m vs 104.5 m (6.3 %) | units walk home_b_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-tower_c_b2 vs home_b_b2-tower_c_a2 | 98.0 m vs 104.5 m (6.3 %) | units walk home_b_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b1 vs home_b_b1-tower_c_a1 | 104.5 m vs 98.0 m (6.3 %) | units walk home_b_a1-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b1 vs home_b_a2-tower_c_b2 | 104.5 m vs 98.0 m (6.3 %) | units walk home_b_a1-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-lairs_two_b2 vs shrine_b2-lairs_two_a2 | 135.3 m vs 144.3 m (6.3 %) | units walk shrine_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-x_ford_s vs post_s_b2-x_ford_n | 117.7 m vs 125.6 m (6.3 %) | units walk post_s_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-x_ford_n vs post_s_b1-x_ford_s | 125.6 m vs 117.7 m (6.3 %) | units walk post_s_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-shrine_b2 vs nat_node_b1-shrine_a2 | 100.4 m vs 94.1 m (6.3 %) | units walk nat_node_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-lairs_two_a1 vs shrine_b2-lairs_two_a2 | 135.3 m vs 144.3 m (6.3 %) | units walk shrine_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-shrine_b2 vs nat_node_a2-shrine_b1 | 100.4 m vs 94.1 m (6.3 %) | units walk nat_node_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a2-lairs_one_a2 vs cache_b_b2-lairs_one_b2 | 84.1 m vs 78.9 m (6.3 %) | units walk cache_b_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b_a1-lairs_one_a1 vs cache_b_a2-lairs_one_a2 | 78.9 m vs 84.1 m (6.3 %) | units walk cache_b_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-shrine_b2 vs tower_r_b1-shrine_a2 | 89.3 m vs 95.2 m (6.3 %) | units walk tower_r_b1-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-lairs_two_a2 vs keep_t4-lairs_two_a1 | 135.5 m vs 127.1 m (6.2 %) | units walk keep_t1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-lairs_two_b1 vs third_node_b1-lairs_two_a2 | 136.1 m vs 127.6 m (6.2 %) | units walk third_node_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_two_b2 vs keep_t1-lairs_two_a2 | 127.1 m vs 135.5 m (6.2 %) | units walk keep_t1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-guilds_lodge_a1 vs rich_node_b2-guilds_lodge_a2 | 163.0 m vs 173.8 m (6.2 %) | units walk rich_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_two_b1 vs stag_b2-lairs_two_a2 | 177.7 m vs 189.4 m (6.2 %) | units walk stag_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-lairs_two_b2 vs keep_t4-lairs_two_b1 | 115.0 m vs 122.6 m (6.2 %) | units walk keep_t4-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_two_a2 vs keep_t1-lairs_two_b2 | 122.6 m vs 115.0 m (6.2 %) | units walk keep_t0-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_w_b1 vs home_a_a2-post_w_b2 | 166.1 m vs 177.1 m (6.2 %) | units walk home_a_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-post_w_b2 vs home_a_b2-post_w_a2 | 177.1 m vs 166.1 m (6.2 %) | units walk home_a_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-guilds_lodge_b2 vs rich_node_b2-guilds_lodge_a2 | 163.1 m vs 173.8 m (6.2 %) | units walk rich_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-lairs_two_b2 vs lairs_one_b1-lairs_two_a1 | 204.4 m vs 217.9 m (6.2 %) | units walk lairs_one_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_lane_w vs post_w_a2-x_lane_w | 69.7 m vs 74.3 m (6.2 %) | units walk post_w_a2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-x_lane_w vs post_w_b1-x_lane_e | 69.7 m vs 74.3 m (6.2 %) | units walk post_w_b1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-x_lane_e vs post_w_b2-x_lane_e | 74.3 m vs 69.7 m (6.2 %) | units walk post_w_b1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-x_lane_w vs post_w_b2-x_lane_e | 74.3 m vs 69.7 m (6.2 %) | units walk post_w_a2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-lairs_two_a1 vs keep_t4-lairs_two_b1 | 115.0 m vs 122.6 m (6.2 %) | units walk keep_t4-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_two_a2 vs keep_t3-lairs_two_a1 | 122.6 m vs 115.0 m (6.2 %) | units walk keep_t0-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_b1 vs home_b_b1-wallow_a1 | 174.3 m vs 185.7 m (6.2 %) | units walk home_b_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-x_bridge_s vs well_b2-x_bridge_n | 135.6 m vs 127.2 m (6.2 %) | units walk well_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a1 vs ford_nest_a2-peddler_b1 | 68.6 m vs 73.1 m (6.2 %) | units walk ford_nest_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_b2 vs ford_nest_a2-peddler_b1 | 68.6 m vs 73.1 m (6.2 %) | units walk ford_nest_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_b1 vs home_b_a2-wallow_b2 | 174.3 m vs 185.7 m (6.2 %) | units walk home_b_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-x_bridge_s vs well_b2-x_bridge_n | 135.6 m vs 127.2 m (6.1 %) | units walk well_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-lairs_one_b1 vs nat_node_b1-lairs_one_a2 | 118.8 m vs 126.6 m (6.1 %) | units walk nat_node_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_b_b1 vs guilds_den_a2-cache_b_b2 | 155.9 m vs 166.0 m (6.1 %) | units walk guilds_den_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-shrine_a2 vs home_a_b2-shrine_a1 | 128.8 m vs 137.2 m (6.1 %) | units walk home_a_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-shrine_b1 vs home_a_b2-shrine_a1 | 128.9 m vs 137.2 m (6.1 %) | units walk home_a_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b2 vs home_a_b1-shrine_a2 | 137.2 m vs 128.8 m (6.1 %) | units walk home_a_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-stag_b2 vs well_b1-stag_a1 | 147.8 m vs 157.4 m (6.1 %) | units walk well_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-lairs_two_b1 vs guilds_den_b2-lairs_two_a1 | 140.0 m vs 131.4 m (6.1 %) | units walk guilds_den_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-lairs_two_b2 vs guilds_den_a2-lairs_two_b1 | 131.5 m vs 140.0 m (6.1 %) | units walk guilds_den_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b2 vs home_a_a2-shrine_b1 | 137.2 m vs 128.9 m (6.1 %) | units walk home_a_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-peddler_b1 vs guilds_lodge_b2-peddler_a2 | 181.9 m vs 193.6 m (6.1 %) | units walk guilds_lodge_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-wallow_b1 vs third_node_b1-wallow_a2 | 157.8 m vs 168.0 m (6.1 %) | units walk third_node_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_a2 vs well_b1-stag_b2 | 123.9 m vs 131.9 m (6.1 %) | units walk well_b1-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_a2 vs well_a2-stag_a1 | 123.9 m vs 131.9 m (6.1 %) | units walk well_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_s_b2 vs tower_r_b1-post_s_a1 | 162.3 m vs 152.5 m (6.1 %) | units walk tower_r_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-lairs_two_b1 vs guilds_den_b1-lairs_two_a2 | 140.0 m vs 131.5 m (6.1 %) | units walk guilds_den_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_b1 vs tower_c_a2-stag_b2 | 106.0 m vs 99.6 m (6.0 %) | units walk tower_c_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_bridge_n vs third_node_a2-x_bridge_s | 166.6 m vs 156.6 m (6.0 %) | units walk third_node_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_bridge_n vs third_node_b1-x_bridge_s | 166.6 m vs 156.6 m (6.0 %) | units walk third_node_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_b1 vs tower_c_b1-stag_a1 | 106.0 m vs 99.7 m (6.0 %) | units walk tower_c_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-tower_r_b1 vs nat_node_b2-tower_r_a2 | 103.0 m vs 109.5 m (6.0 %) | units walk nat_node_b2-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_w_a2 vs rich_node_b1-post_w_b2 | 99.4 m vs 93.5 m (6.0 %) | units walk rich_node_a1-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_w_b2 vs rich_node_b2-post_w_b1 | 93.5 m vs 99.4 m (6.0 %) | units walk rich_node_b2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-peddler_a2 vs guilds_den_b2-peddler_a1 | 169.5 m vs 159.4 m (6.0 %) | units walk guilds_den_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-lairs_two_b1 vs home_a_b2-lairs_two_a1 | 144.3 m vs 135.7 m (6.0 %) | units walk home_a_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_b2 vs home_a_a2-lairs_two_b1 | 135.7 m vs 144.3 m (6.0 %) | units walk home_a_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-peddler_b2 vs guilds_den_b1-peddler_a2 | 159.4 m vs 169.5 m (6.0 %) | units walk guilds_den_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-post_s_b2 vs third_node_b2-post_s_a2 | 188.8 m vs 177.6 m (5.9 %) | units walk third_node_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-tower_r_b1 vs nat_node_a2-tower_r_b2 | 103.0 m vs 96.9 m (5.9 %) | units walk nat_node_a1-tower_r_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-peddler_b2 vs guilds_den_b2-peddler_a2 | 179.4 m vs 190.6 m (5.9 %) | units walk guilds_den_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_b_b2 vs third_node_b2-cache_b_a2 | 149.1 m vs 140.3 m (5.9 %) | units walk third_node_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-third_node_a1 vs rich_node_b2-third_node_a2 | 152.9 m vs 162.5 m (5.9 %) | units walk rich_node_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-lairs_two_b1 vs wallow_b2-lairs_two_a1 | 137.5 m vs 129.4 m (5.9 %) | units walk wallow_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_two_b2 vs wallow_a2-lairs_two_b1 | 129.4 m vs 137.5 m (5.9 %) | units walk wallow_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-lairs_two_b1 vs wallow_b1-lairs_two_a2 | 137.5 m vs 129.4 m (5.9 %) | units walk wallow_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_lodge_b1 vs shrine_a2-guilds_lodge_b2 | 170.7 m vs 160.6 m (5.9 %) | units walk shrine_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-cache_b_b2 vs stag_b1-cache_b_a1 | 124.1 m vs 116.8 m (5.9 %) | units walk stag_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-post_s_a1 vs third_node_b2-post_s_a2 | 188.7 m vs 177.6 m (5.9 %) | units walk third_node_b1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-third_node_b2 vs rich_node_b2-third_node_a2 | 152.9 m vs 162.5 m (5.9 %) | units walk rich_node_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_b_a1 vs third_node_b2-cache_b_a2 | 149.0 m vs 140.3 m (5.9 %) | units walk third_node_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_s_a1 vs rich_node_b2-post_s_a2 | 141.3 m vs 150.1 m (5.9 %) | units walk rich_node_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-cache_b_b2 vs stag_b2-cache_b_a2 | 124.1 m vs 116.9 m (5.9 %) | units walk stag_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_lodge_b1 vs shrine_b1-guilds_lodge_a1 | 170.7 m vs 160.7 m (5.9 %) | units walk shrine_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_e vs lairs_one_b1-x_lane_w | 124.4 m vs 132.2 m (5.9 %) | units walk lairs_one_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-x_lane_w vs lairs_one_b2-x_lane_w | 132.2 m vs 124.4 m (5.9 %) | units walk lairs_one_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_b1 vs third_node_a2-cache_b_b2 | 140.4 m vs 149.1 m (5.9 %) | units walk third_node_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b2 vs home_b_b1-tower_c_a2 | 103.4 m vs 97.3 m (5.9 %) | units walk home_b_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-guilds_lodge_b1 vs wallow_b1-guilds_lodge_a1 | 214.4 m vs 227.7 m (5.8 %) | units walk wallow_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-lairs_one_a1 vs stag_b2-lairs_one_a2 | 184.5 m vs 195.9 m (5.8 %) | units walk stag_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_s_b2 vs rich_node_b2-post_s_a2 | 141.3 m vs 150.1 m (5.8 %) | units walk rich_node_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_one_b2 vs stag_a2-lairs_one_b1 | 101.7 m vs 108.0 m (5.8 %) | units walk stag_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_one_b1 vs stag_b2-lairs_one_a1 | 108.0 m vs 101.7 m (5.8 %) | units walk stag_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_w_b1 vs third_node_b1-post_w_a1 | 193.9 m vs 182.6 m (5.8 %) | units walk third_node_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-post_s_b1 vs inn_b2-post_s_a1 | 77.3 m vs 82.0 m (5.8 %) | units walk inn_b2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-cache_a_a2 vs keep_t4-cache_a_a1 | 131.6 m vs 123.9 m (5.8 %) | units walk keep_t1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_a_b2 vs keep_t1-cache_a_a2 | 123.9 m vs 131.6 m (5.8 %) | units walk keep_t1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-guilds_den_b2 vs post_s_a2-guilds_den_b1 | 100.9 m vs 107.1 m (5.8 %) | units walk post_s_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_a_b2 vs tower_r_b1-cache_a_a1 | 152.4 m vs 143.5 m (5.8 %) | units walk tower_r_a2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-guilds_lodge_b1 vs wallow_a2-guilds_lodge_b2 | 214.4 m vs 227.7 m (5.8 %) | units walk wallow_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-lairs_two_b1 vs guilds_lodge_b1-lairs_two_a2 | 145.6 m vs 137.1 m (5.8 %) | units walk guilds_lodge_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_b1 vs third_node_b1-cache_b_a1 | 140.4 m vs 149.0 m (5.8 %) | units walk third_node_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-cache_a_b1 vs post_s_b1-cache_a_a2 | 72.1 m vs 76.6 m (5.8 %) | units walk post_s_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_one_b2 vs stag_b2-lairs_one_a2 | 184.6 m vs 195.9 m (5.8 %) | units walk stag_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_one_b1 vs stag_b2-lairs_one_a2 | 184.6 m vs 195.9 m (5.8 %) | units walk stag_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_a1 vs ford_nest_a2-guilds_lodge_b1 | 91.5 m vs 97.1 m (5.8 %) | units walk ford_nest_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_b2 vs ford_nest_a2-guilds_lodge_b1 | 91.5 m vs 97.1 m (5.8 %) | units walk ford_nest_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-guilds_den_b1 vs post_s_b2-guilds_den_a1 | 107.1 m vs 100.9 m (5.8 %) | units walk post_s_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-tower_c_a2 vs home_b_b2-tower_c_a1 | 97.3 m vs 103.3 m (5.8 %) | units walk home_b_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-guilds_lodge_a2 vs nat_node_b1-guilds_lodge_b1 | 75.4 m vs 80.0 m (5.8 %) | units walk nat_node_b1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-post_w_b2 vs stag_b1-post_w_a1 | 147.6 m vs 156.6 m (5.8 %) | units walk stag_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-guilds_den_b1 vs tower_r_b2-guilds_den_a1 | 97.9 m vs 92.2 m (5.8 %) | units walk tower_r_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_den_b2 vs tower_r_a2-guilds_den_b1 | 92.2 m vs 97.9 m (5.8 %) | units walk tower_r_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b2 vs home_b_a2-tower_c_b1 | 103.4 m vs 97.4 m (5.8 %) | units walk home_b_a1-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-post_w_b1 vs stag_b2-post_w_a1 | 139.9 m vs 131.9 m (5.7 %) | units walk stag_a2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-guilds_den_b1 vs nat_node_b1-guilds_den_a2 | 128.9 m vs 136.8 m (5.7 %) | units walk nat_node_b1-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_w_b2 vs stag_a2-post_w_b1 | 131.9 m vs 139.9 m (5.7 %) | units walk stag_a2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_one_b1 vs guilds_lodge_b1-lairs_one_a1 | 227.1 m vs 240.9 m (5.7 %) | units walk guilds_lodge_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-tower_c_b1 vs home_b_b2-tower_c_a1 | 97.4 m vs 103.3 m (5.7 %) | units walk home_b_b2-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-ford_nest_a1 vs shrine_b2-ford_nest_a2 | 69.3 m vs 73.5 m (5.7 %) | units walk shrine_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-x_ford_s vs shrine_b2-x_ford_n | 69.3 m vs 73.5 m (5.7 %) | units walk shrine_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_ford_s vs shrine_b2-x_ford_n | 69.3 m vs 73.5 m (5.7 %) | units walk shrine_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-ford_nest_a1 vs shrine_b2-ford_nest_a2 | 69.3 m vs 73.5 m (5.7 %) | units walk shrine_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-ford_nest_a2 vs shrine_b1-ford_nest_a1 | 73.5 m vs 69.3 m (5.7 %) | units walk shrine_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_ford_n vs shrine_a2-x_ford_s | 73.5 m vs 69.3 m (5.7 %) | units walk shrine_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-ford_nest_a2 vs shrine_a2-ford_nest_a1 | 73.5 m vs 69.3 m (5.7 %) | units walk shrine_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-x_ford_n vs shrine_b1-x_ford_s | 73.5 m vs 69.3 m (5.7 %) | units walk shrine_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-guilds_lodge_b2 vs post_s_a2-guilds_lodge_b1 | 108.0 m vs 114.5 m (5.7 %) | units walk post_s_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-stag_b2 vs tower_r_b1-stag_a1 | 158.2 m vs 149.3 m (5.6 %) | units walk tower_r_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_lodge_b2 vs tower_r_a2-guilds_lodge_b1 | 99.3 m vs 105.2 m (5.6 %) | units walk tower_r_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-guilds_lodge_b1 vs tower_r_b2-guilds_lodge_a1 | 105.2 m vs 99.3 m (5.6 %) | units walk tower_r_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-guilds_lodge_b1 vs post_s_b2-guilds_lodge_a1 | 114.5 m vs 108.0 m (5.6 %) | units walk post_s_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-x_ford_s vs tower_r_b2-x_ford_n | 105.3 m vs 111.6 m (5.6 %) | units walk tower_r_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-x_ford_n vs tower_r_a2-x_ford_s | 111.6 m vs 105.3 m (5.6 %) | units walk tower_r_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-ford_nest_a2 vs tower_r_a2-ford_nest_a1 | 111.6 m vs 105.3 m (5.6 %) | units walk tower_r_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-ford_nest_a1 vs tower_r_b2-ford_nest_a2 | 105.3 m vs 111.6 m (5.6 %) | units walk tower_r_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_a1 vs third_node_a2-shrine_a2 | 58.3 m vs 61.7 m (5.6 %) | units walk third_node_a2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_a1 vs third_node_b1-shrine_b1 | 58.3 m vs 61.7 m (5.6 %) | units walk third_node_b1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-shrine_a2 vs third_node_b2-shrine_b2 | 61.7 m vs 58.3 m (5.6 %) | units walk third_node_a2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-shrine_b1 vs third_node_b2-shrine_b2 | 61.7 m vs 58.3 m (5.6 %) | units walk third_node_b1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-post_s_b1 vs stag_a2-post_s_b2 | 173.6 m vs 163.9 m (5.6 %) | units walk stag_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-post_s_a1 vs tower_c_b2-post_s_a2 | 96.7 m vs 102.4 m (5.6 %) | units walk tower_c_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-post_s_b2 vs tower_c_b2-post_s_a2 | 96.7 m vs 102.4 m (5.6 %) | units walk tower_c_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_a_a2 vs well_a2-cache_a_a1 | 123.4 m vs 116.5 m (5.6 %) | units walk well_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_a_a1 vs well_b2-cache_a_b1 | 116.5 m vs 123.4 m (5.6 %) | units walk well_b2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_a_a2 vs well_b1-cache_a_b2 | 123.4 m vs 116.5 m (5.6 %) | units walk well_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-cache_a_b2 vs well_b2-cache_a_b1 | 116.5 m vs 123.4 m (5.6 %) | units walk well_b2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_w_b1 vs wallow_a2-post_w_b2 | 183.8 m vs 194.6 m (5.6 %) | units walk wallow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_w_b2 vs wallow_b2-post_w_a2 | 194.6 m vs 183.8 m (5.6 %) | units walk wallow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-third_node_b1 vs keep_t1-third_node_a2 | 156.0 m vs 165.2 m (5.5 %) | units walk keep_t1-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_two_b2 vs cache_a_b1-lairs_two_a1 | 179.1 m vs 189.6 m (5.5 %) | units walk cache_a_b1-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-shrine_a1 vs well_b2-shrine_a2 | 114.7 m vs 121.4 m (5.5 %) | units walk well_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b1 vs well_b1-shrine_a1 | 121.4 m vs 114.7 m (5.5 %) | units walk well_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b1 vs well_a2-shrine_b2 | 121.4 m vs 114.7 m (5.5 %) | units walk well_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-shrine_b2 vs well_b2-shrine_a2 | 114.7 m vs 121.4 m (5.5 %) | units walk well_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-peddler_b2 vs rich_node_a2-peddler_b1 | 90.4 m vs 95.7 m (5.5 %) | units walk rich_node_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-guilds_lodge_b2 vs third_node_b1-guilds_lodge_a1 | 244.5 m vs 231.0 m (5.5 %) | units walk third_node_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_s_b1 vs inn_b1-post_s_a1 | 120.3 m vs 113.7 m (5.5 %) | units walk inn_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_s_b1 vs inn_a2-post_s_b2 | 120.3 m vs 113.7 m (5.5 %) | units walk inn_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_a_a2 vs wallow_b1-cache_a_b2 | 128.7 m vs 121.7 m (5.5 %) | units walk wallow_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_a_a2 vs wallow_a2-cache_a_a1 | 128.7 m vs 121.7 m (5.5 %) | units walk wallow_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_two_b2 vs home_b_b2-lairs_two_b1 | 119.9 m vs 126.9 m (5.5 %) | units walk home_b_b2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_a2 vs home_b_b1-lairs_two_b2 | 126.9 m vs 119.9 m (5.5 %) | units walk home_b_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-x_bridge_n vs cache_a_b1-x_bridge_s | 146.8 m vs 155.2 m (5.4 %) | units walk cache_a_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b2-cache_b_a2 | 166.0 m vs 157.0 m (5.4 %) | units walk guilds_den_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_bridge_n vs lairs_two_b2-x_bridge_n | 163.0 m vs 154.1 m (5.4 %) | units walk lairs_two_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_b_b1 vs shrine_b1-cache_b_a1 | 83.2 m vs 78.7 m (5.4 %) | units walk shrine_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-x_bridge_n vs cache_a_a2-x_bridge_s | 146.8 m vs 155.2 m (5.4 %) | units walk cache_a_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_two_a1 vs home_b_b2-lairs_two_b1 | 120.0 m vs 126.9 m (5.4 %) | units walk home_b_b2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_a2 vs home_b_a2-lairs_two_a1 | 126.9 m vs 120.0 m (5.4 %) | units walk home_b_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-lairs_two_b1 vs post_w_b2-lairs_two_a1 | 158.6 m vs 150.0 m (5.4 %) | units walk post_w_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-lairs_two_b2 vs post_w_a2-lairs_two_b1 | 150.0 m vs 158.6 m (5.4 %) | units walk post_w_a2-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-peddler_b1 vs rich_node_b2-peddler_a1 | 95.7 m vs 90.5 m (5.4 %) | units walk rich_node_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-guilds_den_a1 vs stag_b2-guilds_den_a2 | 192.3 m vs 203.3 m (5.4 %) | units walk stag_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-crown vs post_w_b1-crown | 82.2 m vs 86.9 m (5.4 %) | units walk post_w_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-crown vs post_w_b2-crown | 86.9 m vs 82.2 m (5.4 %) | units walk post_w_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-crown vs post_w_b2-crown | 86.9 m vs 82.2 m (5.4 %) | units walk post_w_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-crown vs post_w_a2-crown | 82.2 m vs 86.9 m (5.4 %) | units walk post_w_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_b_b1 vs shrine_a2-cache_b_b2 | 83.2 m vs 78.7 m (5.4 %) | units walk shrine_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_a_a1 vs guilds_lodge_b2-cache_a_a2 | 208.5 m vs 197.3 m (5.4 %) | units walk guilds_lodge_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_b1 vs guilds_lodge_b1-cache_a_a1 | 197.3 m vs 208.5 m (5.4 %) | units walk guilds_lodge_b1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-stag_a1 vs third_node_b2-stag_a2 | 191.7 m vs 202.6 m (5.4 %) | units walk third_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-x_lane_w vs lairs_one_b2-x_lane_e | 95.5 m vs 100.9 m (5.4 %) | units walk lairs_one_b2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_w vs lairs_one_a2-x_lane_w | 100.9 m vs 95.5 m (5.4 %) | units walk lairs_one_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-x_lane_e vs lairs_one_b2-x_lane_e | 95.5 m vs 100.9 m (5.4 %) | units walk lairs_one_b2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_w vs lairs_one_b1-x_lane_e | 100.9 m vs 95.5 m (5.4 %) | units walk lairs_one_a1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b1 vs tower_r_a2-cache_b_b2 | 114.1 m vs 108.0 m (5.4 %) | units walk tower_r_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_den_b1 vs stag_b2-guilds_den_a2 | 192.4 m vs 203.3 m (5.4 %) | units walk stag_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_den_b2 vs stag_b2-guilds_den_a2 | 192.4 m vs 203.3 m (5.4 %) | units walk stag_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-stag_b2 vs third_node_b2-stag_a2 | 191.7 m vs 202.6 m (5.4 %) | units walk third_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-cache_b_a1 vs shrine_b2-cache_b_a2 | 78.7 m vs 83.2 m (5.3 %) | units walk shrine_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_two_b2 vs tower_r_b1-lairs_two_a1 | 166.9 m vs 158.0 m (5.3 %) | units walk tower_r_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-lairs_one_a2 vs keep_t4-lairs_one_a1 | 152.7 m vs 144.5 m (5.3 %) | units walk keep_t1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_one_b2 vs keep_t1-lairs_one_a2 | 144.5 m vs 152.7 m (5.3 %) | units walk keep_t1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_b2 vs tower_c_b1-peddler_a2 | 95.2 m vs 90.1 m (5.3 %) | units walk tower_c_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-peddler_a2 vs tower_c_b2-peddler_a1 | 90.1 m vs 95.2 m (5.3 %) | units walk tower_c_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-peddler_b1 vs tower_c_b2-peddler_a1 | 90.1 m vs 95.2 m (5.3 %) | units walk tower_c_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_b2 vs tower_c_a2-peddler_b1 | 95.2 m vs 90.1 m (5.3 %) | units walk tower_c_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_a_b1 vs well_b1-cache_a_a2 | 92.5 m vs 87.6 m (5.3 %) | units walk well_a2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_one_b1 vs home_b_b2-lairs_one_a2 | 182.2 m vs 192.4 m (5.3 %) | units walk home_b_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t4-wallow_a2 | 167.7 m vs 177.2 m (5.3 %) | units walk keep_t4-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-cache_b_b2 vs shrine_b2-cache_b_a2 | 78.7 m vs 83.2 m (5.3 %) | units walk shrine_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-x_bridge_n vs home_a_b1-x_bridge_n | 86.5 m vs 81.9 m (5.3 %) | units walk home_a_a2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_b_b1 vs guilds_lodge_b2-cache_b_a1 | 109.4 m vs 103.6 m (5.3 %) | units walk guilds_lodge_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_one_b2 vs cache_a_b1-lairs_one_a1 | 187.3 m vs 197.8 m (5.3 %) | units walk cache_a_b1-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-home_b_b1 vs home_a_b1-home_b_a1 | 150.1 m vs 158.5 m (5.3 %) | units walk home_a_b1-home_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_b_b2 vs tower_r_b2-cache_b_a2 | 108.0 m vs 114.0 m (5.3 %) | units walk tower_r_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_b1 vs tower_c_a2-peddler_b2 | 90.6 m vs 95.6 m (5.3 %) | units walk tower_c_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-peddler_b2 vs tower_c_b2-peddler_a2 | 95.6 m vs 90.6 m (5.3 %) | units walk tower_c_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-peddler_b1 vs tower_c_b1-peddler_a1 | 90.6 m vs 95.6 m (5.3 %) | units walk tower_c_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-peddler_a1 vs tower_c_b2-peddler_a2 | 95.6 m vs 90.6 m (5.3 %) | units walk tower_c_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-lairs_two_b2 vs third_node_b2-lairs_two_a2 | 228.2 m vs 216.2 m (5.3 %) | units walk third_node_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-home_b_b1 vs home_a_a2-home_b_b2 | 150.1 m vs 158.4 m (5.2 %) | units walk home_a_a2-home_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_den_b2 vs stag_a2-guilds_den_b1 | 111.9 m vs 118.0 m (5.2 %) | units walk stag_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_den_b1 vs stag_b2-guilds_den_a1 | 118.0 m vs 111.9 m (5.2 %) | units walk stag_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_r_b1 vs third_node_a2-tower_r_b2 | 164.3 m vs 173.4 m (5.2 %) | units walk third_node_a2-tower_r_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-third_node_a2 vs home_b_b2-third_node_a1 | 146.0 m vs 154.0 m (5.2 %) | units walk home_b_b2-third_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-inn_b2 vs wallow_b1-inn_a1 | 150.8 m vs 142.9 m (5.2 %) | units walk wallow_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_b2 vs guilds_lodge_a2-cache_b_b1 | 103.6 m vs 109.4 m (5.2 %) | units walk guilds_lodge_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-third_node_b2 vs home_b_b1-third_node_a2 | 154.0 m vs 146.0 m (5.2 %) | units walk home_b_a1-third_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-post_w_a1 vs wallow_b2-post_w_a2 | 174.2 m vs 183.8 m (5.2 %) | units walk wallow_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_w_b1 vs wallow_b1-post_w_a1 | 183.8 m vs 174.2 m (5.2 %) | units walk wallow_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_b1 vs well_b1-stag_a1 | 166.1 m vs 157.4 m (5.2 %) | units walk well_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-guilds_lodge_b1 vs home_a_b1-guilds_lodge_a2 | 174.8 m vs 165.7 m (5.2 %) | units walk home_a_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_b1 vs tower_r_b1-lairs_one_a1 | 175.4 m vs 166.2 m (5.2 %) | units walk tower_r_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_b_a2 vs guilds_lodge_b2-cache_b_a1 | 109.3 m vs 103.6 m (5.2 %) | units walk guilds_lodge_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-wallow_b1 vs tower_r_b1-wallow_a1 | 155.6 m vs 147.5 m (5.2 %) | units walk tower_r_a1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-peddler_b1 vs stag_b1-peddler_a1 | 145.6 m vs 138.0 m (5.2 %) | units walk stag_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_bridge_n vs lairs_two_b1-x_bridge_s | 163.0 m vs 171.9 m (5.2 %) | units walk lairs_two_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-inn_b1 vs tower_r_b1-inn_a2 | 70.4 m vs 66.7 m (5.2 %) | units walk tower_r_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_bridge_n vs lairs_two_a2-x_bridge_s | 163.0 m vs 171.9 m (5.2 %) | units walk lairs_two_a2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_r_b1 vs third_node_b1-tower_r_a1 | 164.3 m vs 173.3 m (5.2 %) | units walk third_node_b1-tower_r_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_one_b1 vs peddler_b2-lairs_one_a2 | 167.6 m vs 176.8 m (5.2 %) | units walk peddler_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-wallow_a1 vs tower_r_b2-wallow_a2 | 147.5 m vs 155.5 m (5.2 %) | units walk tower_r_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-peddler_a1 vs stag_b2-peddler_a2 | 138.0 m vs 145.5 m (5.2 %) | units walk stag_b2-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-x_bridge_n vs home_a_b2-x_bridge_s | 81.9 m vs 86.3 m (5.2 %) | units walk home_a_b2-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_bridge_s vs home_a_b1-x_bridge_n | 86.3 m vs 81.9 m (5.2 %) | units walk home_a_a1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-guilds_lodge_a2 vs ford_nest_a2-guilds_lodge_b1 | 92.1 m vs 97.1 m (5.2 %) | units walk ford_nest_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_one_a1 vs tower_r_b2-lairs_one_a2 | 166.2 m vs 175.3 m (5.2 %) | units walk tower_r_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_b2 vs guilds_lodge_b1-cache_b_a2 | 103.6 m vs 109.3 m (5.2 %) | units walk guilds_lodge_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_lodge_b1 vs stag_b2-guilds_lodge_a1 | 125.4 m vs 119.0 m (5.1 %) | units walk stag_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_lodge_b2 vs stag_a2-guilds_lodge_b1 | 119.0 m vs 125.4 m (5.1 %) | units walk stag_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_one_b1 vs home_b_b1-lairs_one_a2 | 143.0 m vs 135.7 m (5.1 %) | units walk home_b_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-third_node_b1 vs home_a_b1-third_node_a2 | 164.6 m vs 156.2 m (5.1 %) | units walk home_a_a2-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-shrine_a1 vs third_node_b2-shrine_b1 | 83.6 m vs 79.3 m (5.1 %) | units walk third_node_a2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_a2 vs third_node_a2-shrine_a1 | 79.3 m vs 83.6 m (5.1 %) | units walk third_node_a2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_one_b1 vs rich_node_b1-lairs_one_a2 | 89.6 m vs 85.0 m (5.1 %) | units walk rich_node_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_one_b2 vs rich_node_a2-lairs_one_b1 | 85.0 m vs 89.6 m (5.1 %) | units walk rich_node_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_den_b1 vs home_b_b2-guilds_den_a2 | 192.3 m vs 202.6 m (5.1 %) | units walk home_b_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-shrine_a2 vs rich_node_b2-shrine_b1 | 73.5 m vs 77.5 m (5.1 %) | units walk rich_node_b2-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_b1 vs shrine_b2-lairs_one_a2 | 153.2 m vs 161.5 m (5.1 %) | units walk shrine_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_a2 vs third_node_b1-shrine_b2 | 79.3 m vs 83.6 m (5.1 %) | units walk third_node_b1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-shrine_b2 vs third_node_b2-shrine_b1 | 83.6 m vs 79.3 m (5.1 %) | units walk third_node_b1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-guilds_den_a1 vs third_node_b2-guilds_den_a2 | 228.0 m vs 216.3 m (5.1 %) | units walk third_node_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-guilds_lodge_a2 vs inn_a2-guilds_lodge_a1 | 120.4 m vs 114.3 m (5.1 %) | units walk inn_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-guilds_lodge_a2 vs inn_b1-guilds_lodge_b2 | 120.4 m vs 114.3 m (5.1 %) | units walk inn_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-peddler_a2 vs ford_nest_a2-peddler_b1 | 69.4 m vs 73.1 m (5.1 %) | units walk ford_nest_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-cache_a_b1 vs keep_t1-cache_a_a2 | 124.9 m vs 131.6 m (5.1 %) | units walk keep_t1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_one_b2 vs tower_r_b1-lairs_one_a1 | 175.1 m vs 166.2 m (5.1 %) | units walk tower_r_a2-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_one_b1 vs keep_t4-lairs_one_a2 | 177.9 m vs 187.4 m (5.1 %) | units walk keep_t4-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_b1 vs tower_c_b2-stag_a2 | 106.0 m vs 111.7 m (5.1 %) | units walk tower_c_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-shrine_b2 vs tower_r_b1-shrine_a1 | 110.1 m vs 116.0 m (5.1 %) | units walk tower_r_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_one_b1 vs rich_node_b2-lairs_one_a1 | 89.6 m vs 85.1 m (5.1 %) | units walk rich_node_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_a2 vs well_b2-stag_b1 | 123.9 m vs 130.4 m (5.0 %) | units walk well_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-cache_a_b1 vs stag_b1-cache_a_a2 | 83.1 m vs 87.5 m (5.0 %) | units walk stag_b1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-stag_b1 vs nat_node_b2-stag_a1 | 91.1 m vs 95.9 m (5.0 %) | units walk nat_node_b2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-x_ford_n vs stag_a2-x_ford_s | 120.8 m vs 114.7 m (5.0 %) | units walk stag_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-x_ford_s vs stag_b2-x_ford_n | 114.7 m vs 120.8 m (5.0 %) | units walk stag_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-stag_b1 vs stag_b2-stag_a2 | 176.5 m vs 167.6 m (5.0 %) | units walk stag_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-stag_b1 vs nat_node_a2-stag_b2 | 121.3 m vs 115.2 m (5.0 %) | units walk nat_node_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-shrine_b1 vs rich_node_b1-shrine_a2 | 79.8 m vs 84.0 m (5.0 %) | units walk rich_node_b1-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-x_ford_s vs post_s_b2-x_ford_n | 119.3 m vs 125.6 m (5.0 %) | units walk post_s_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-x_ford_n vs post_s_a2-x_ford_s | 125.6 m vs 119.3 m (5.0 %) | units walk post_s_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | T1 | enemy keep #2 (worker) | 0:33 vs 0:37 between seats | one seat's route is longer or crosses more ford: see the travel-time table |
| WARN | C2 | keep_t0 -> keep_t1 | narrowest 3.9 m at (-7.2, 1.6) vs its twin's 5.8 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t0 -> keep_t1 | narrowest 3.9 m at (-7.2, 1.6) vs its twin's 5.8 m | a collider narrows this route only on one side |
| WARN | R4 | well_a1 | point 3.7 m from a road centre line (want >= 7) | push it off the road (auto-fix) |
| WARN | R4 | well_a2 | point 3.7 m from a road centre line (want >= 7) | push it off the road (auto-fix) |
| WARN | R4 | well_b1 | point 3.7 m from a road centre line (want >= 7) | push it off the road (auto-fix) |
| WARN | R4 | well_b2 | point 3.7 m from a road centre line (want >= 7) | push it off the road (auto-fix) |
| WARN | R4 | stag_a1 | camp 7.5 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | stag_a2 | camp 7.5 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | stag_b1 | camp 7.5 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | stag_b2 | camp 7.5 m from a road centre line (want >= 9) | push it off the road (auto-fix) |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-71.6, 32.4) | (-67.9, 32.1) | keep_t4 | (-67.9, 32.1) | 0.0 |
| keep_t3 | keep | (-71.6, -32.4) | (-67.9, -32.1) | keep_t1 | (-67.9, -32.1) | 0.0 |
| keep_t1 | keep | (71.6, -32.4) | (67.9, -32.1) | keep_t3 | (67.9, -32.1) | 0.0 |
| keep_t4 | keep | (71.6, 32.4) | (67.9, 32.1) | keep_t0 | (67.9, 32.1) | 0.0 |
| home_a_a1 | home_node | (-71.2, 22.9) | (-71.1, 22.9) | home_a_b2 | (-71.1, 22.9) | 0.0 |
| home_a_a2 | home_node | (-71.2, -22.9) | (-71.1, -22.9) | home_a_b1 | (-71.1, -22.9) | 0.0 |
| home_a_b1 | home_node | (71.2, -22.9) | (71.1, -22.9) | home_a_a2 | (71.1, -22.9) | 0.0 |
| home_a_b2 | home_node | (71.2, 22.9) | (71.1, 22.9) | home_a_a1 | (71.1, 22.9) | 0.0 |
| home_b_a1 | home_node | (-64.2, 38.4) | (-64.1, 38.4) | home_b_b2 | (-64.1, 38.4) | 0.0 |
| home_b_a2 | home_node | (-64.2, -38.4) | (-64.1, -38.4) | home_b_b1 | (-64.1, -38.4) | 0.0 |
| home_b_b1 | home_node | (64.2, -38.4) | (64.1, -38.4) | home_b_a2 | (64.1, -38.4) | 0.0 |
| home_b_b2 | home_node | (64.2, 38.4) | (64.1, 38.4) | home_b_a1 | (64.1, 38.4) | 0.0 |
| nat_node_a1 | expansion | (-35.3, 17.8) | (-35.1, 17.6) | nat_node_b2 | (-35.1, 17.6) | 0.0 |
| nat_node_a2 | expansion | (-35.3, -17.8) | (-35.1, -17.6) | nat_node_b1 | (-35.1, -17.6) | 0.0 |
| nat_node_b1 | expansion | (35.3, -17.8) | (35.1, -17.6) | nat_node_a2 | (35.1, -17.6) | 0.0 |
| nat_node_b2 | expansion | (35.3, 17.8) | (35.1, 17.6) | nat_node_a1 | (35.1, 17.6) | 0.0 |
| rich_node_a1 | expansion | (-14.6, 52.2) | (-14.4, 52.1) | rich_node_b2 | (-14.4, 52.1) | 0.0 |
| rich_node_a2 | expansion | (-14.6, -52.2) | (-14.4, -52.1) | rich_node_b1 | (-14.4, -52.1) | 0.0 |
| rich_node_b1 | expansion | (14.6, -52.2) | (14.4, -52.1) | rich_node_a2 | (14.4, -52.1) | 0.0 |
| rich_node_b2 | expansion | (14.6, 52.2) | (14.4, 52.1) | rich_node_a1 | (14.4, 52.1) | 0.0 |
| third_node_a1 | expansion | (-77.8, 63.5) | (-77.6, 63.4) | third_node_b2 | (-77.6, 63.4) | 0.0 |
| third_node_a2 | expansion | (-77.8, -63.5) | (-77.6, -63.4) | third_node_b1 | (-77.6, -63.4) | 0.0 |
| third_node_b1 | expansion | (77.8, -63.5) | (77.6, -63.4) | third_node_a2 | (77.6, -63.4) | 0.0 |
| third_node_b2 | expansion | (77.8, 63.5) | (77.6, 63.4) | third_node_a1 | (77.6, 63.4) | 0.0 |
| tower_r_a1 | point | (-15.7, 64.4) | (-15.6, 64.4) | tower_r_b2 | (-15.6, 64.4) | 0.0 |
| tower_r_a2 | point | (-15.7, -64.4) | (-15.6, -64.4) | tower_r_b1 | (-15.6, -64.4) | 0.0 |
| tower_r_b1 | point | (15.7, -64.4) | (15.6, -64.4) | tower_r_a2 | (15.6, -64.4) | 0.0 |
| tower_r_b2 | point | (15.7, 64.4) | (15.6, 64.4) | tower_r_a1 | (15.6, 64.4) | 0.0 |
| tower_c_a1 | point | (-21.3, 7.6) | (-21.1, 7.6) | tower_c_b2 | (-21.1, 7.6) | 0.0 |
| tower_c_a2 | point | (-21.3, -7.6) | (-21.1, -7.6) | tower_c_b1 | (-21.1, -7.6) | 0.0 |
| tower_c_b1 | point | (21.3, -7.6) | (21.1, -7.6) | tower_c_a2 | (21.1, -7.6) | 0.0 |
| tower_c_b2 | point | (21.3, 7.6) | (21.1, 7.6) | tower_c_a1 | (21.1, 7.6) | 0.0 |
| well_a1 | point | (-39.7, 50.1) | (-39.6, 49.9) | well_b2 | (-39.6, 49.9) | 0.0 |
| well_a2 | point | (-39.7, -50.1) | (-39.6, -49.9) | well_b1 | (-39.6, -49.9) | 0.0 |
| well_b1 | point | (39.7, -50.1) | (39.6, -49.9) | well_a2 | (39.6, -49.9) | 0.0 |
| well_b2 | point | (39.7, 50.1) | (39.6, 49.9) | well_a1 | (39.6, 49.9) | 0.0 |
| shrine_a1 | point | (-52.1, 11.1) | (-51.9, 11.1) | shrine_b2 | (-51.9, 11.1) | 0.0 |
| shrine_a2 | point | (-52.1, -11.1) | (-51.9, -11.1) | shrine_b1 | (-51.9, -11.1) | 0.0 |
| shrine_b1 | point | (52.1, -11.1) | (51.9, -11.1) | shrine_a2 | (51.9, -11.1) | 0.0 |
| shrine_b2 | point | (52.1, 11.1) | (51.9, 11.1) | shrine_a1 | (51.9, 11.1) | 0.0 |
| wallow_a1 | camp | (-78.5, 47.6) | (-78.4, 47.6) | wallow_b2 | (-78.4, 47.6) | 0.0 |
| wallow_a2 | camp | (-78.5, -47.6) | (-78.4, -47.6) | wallow_b1 | (-78.4, -47.6) | 0.0 |
| wallow_b1 | camp | (78.5, -47.6) | (78.4, -47.6) | wallow_a2 | (78.4, -47.6) | 0.0 |
| wallow_b2 | camp | (78.5, 47.6) | (78.4, 47.6) | wallow_a1 | (78.4, 47.6) | 0.0 |
| ford_nest_a1 | camp | (0.0, 34.9) | (0.1, 34.9) | ford_nest_a1 | (-0.1, 34.9) | 0.3 |
| ford_nest_a2 | camp | (0.0, -34.9) | (0.1, -34.9) | ford_nest_a2 | (-0.1, -34.9) | 0.3 |
| stag_a1 | camp | (-34.6, 73.8) | (-34.6, 73.6) | stag_b2 | (-34.6, 73.6) | 0.0 |
| stag_a2 | camp | (-34.6, -73.8) | (-34.6, -73.6) | stag_b1 | (-34.6, -73.6) | 0.0 |
| stag_b1 | camp | (34.6, -73.8) | (34.6, -73.6) | stag_a2 | (34.6, -73.6) | 0.0 |
| stag_b2 | camp | (34.6, 73.8) | (34.6, 73.6) | stag_a1 | (34.6, 73.6) | 0.0 |
| inn_a1 | tavern | (-29.2, 22.8) | (-29.1, 22.6) | inn_b2 | (-29.1, 22.6) | 0.0 |
| inn_a2 | tavern | (-29.2, -22.8) | (-29.1, -22.6) | inn_b1 | (-29.1, -22.6) | 0.0 |
| inn_b1 | tavern | (29.2, -22.8) | (29.1, -22.6) | inn_a2 | (29.1, -22.6) | 0.0 |
| inn_b2 | tavern | (29.2, 22.8) | (29.1, 22.6) | inn_a1 | (29.1, 22.6) | 0.0 |
| post_w_a1 | post | (-81.4, 13.0) | (-81.4, 12.9) | post_w_b2 | (-81.4, 12.9) | 0.0 |
| post_w_a2 | post | (-81.4, -13.0) | (-81.4, -12.9) | post_w_b1 | (-81.4, -12.9) | 0.0 |
| post_w_b1 | post | (81.4, -13.0) | (81.4, -12.9) | post_w_a2 | (81.4, -12.9) | 0.0 |
| post_w_b2 | post | (81.4, 13.0) | (81.4, 12.9) | post_w_a1 | (81.4, 12.9) | 0.0 |
| post_s_a1 | post | (-20.5, 79.1) | (-20.4, 79.1) | post_s_b2 | (-20.4, 79.1) | 0.0 |
| post_s_a2 | post | (-20.5, -79.1) | (-20.4, -79.1) | post_s_b1 | (-20.4, -79.1) | 0.0 |
| post_s_b1 | post | (20.5, -79.1) | (20.4, -79.1) | post_s_a2 | (20.4, -79.1) | 0.0 |
| post_s_b2 | post | (20.5, 79.1) | (20.4, 79.1) | post_s_a1 | (20.4, 79.1) | 0.0 |
| guilds_den_a1 | guild | (-74.8, 82.1) | (-74.9, 81.9) | guilds_den_b2 | (-74.9, 81.9) | 0.0 |
| guilds_den_a2 | guild | (-74.8, -82.1) | (-74.9, -81.9) | guilds_den_b1 | (-74.9, -81.9) | 0.0 |
| guilds_den_b1 | guild | (74.8, -82.1) | (74.9, -81.9) | guilds_den_a2 | (74.9, -81.9) | 0.0 |
| guilds_den_b2 | guild | (74.8, 82.1) | (74.9, 81.9) | guilds_den_a1 | (74.9, 81.9) | 0.0 |
| guilds_lodge_a1 | guild | (-83.2, 73.5) | (-83.1, 73.4) | guilds_lodge_b2 | (-83.1, 73.4) | 0.0 |
| guilds_lodge_a2 | guild | (-83.2, -73.5) | (-83.1, -73.4) | guilds_lodge_b1 | (-83.1, -73.4) | 0.0 |
| guilds_lodge_b1 | guild | (83.2, -73.5) | (83.1, -73.4) | guilds_lodge_a2 | (83.1, -73.4) | 0.0 |
| guilds_lodge_b2 | guild | (83.2, 73.5) | (83.1, 73.4) | guilds_lodge_a1 | (83.1, 73.4) | 0.0 |
| peddler_a1 | peddler | (-64.2, 22.4) | (-64.1, 22.4) | peddler_b2 | (-64.1, 22.4) | 0.0 |
| peddler_a2 | peddler | (-64.2, -22.4) | (-64.1, -22.4) | peddler_b1 | (-64.1, -22.4) | 0.0 |
| peddler_b1 | peddler | (64.2, -22.4) | (64.1, -22.4) | peddler_a2 | (64.1, -22.4) | 0.0 |
| peddler_b2 | peddler | (64.2, 22.4) | (64.1, 22.4) | peddler_a1 | (64.1, 22.4) | 0.0 |
| cache_a_a1 | cache | (-46.3, 64.7) | (-46.1, 64.6) | cache_a_b2 | (-46.1, 64.6) | 0.0 |
| cache_a_a2 | cache | (-46.3, -64.7) | (-46.1, -64.6) | cache_a_b1 | (-46.1, -64.6) | 0.0 |
| cache_a_b1 | cache | (46.3, -64.7) | (46.1, -64.6) | cache_a_a2 | (46.1, -64.6) | 0.0 |
| cache_a_b2 | cache | (46.3, 64.7) | (46.1, 64.6) | cache_a_a1 | (46.1, 64.6) | 0.0 |
| cache_b_a1 | cache | (-7.9, 25.5) | (-7.9, 25.4) | cache_b_b2 | (-7.9, 25.4) | 0.0 |
| cache_b_a2 | cache | (-7.9, -25.5) | (-7.9, -25.4) | cache_b_b1 | (-7.9, -25.4) | 0.0 |
| cache_b_b1 | cache | (7.9, -25.5) | (7.9, -25.4) | cache_b_a2 | (7.9, -25.4) | 0.0 |
| cache_b_b2 | cache | (7.9, 25.5) | (7.9, 25.4) | cache_b_a1 | (7.9, 25.4) | 0.0 |
| lairs_one_a1 | lair | (-64.9, 80.0) | (-64.9, 79.9) | lairs_one_b2 | (-64.9, 79.9) | 0.0 |
| lairs_one_a2 | lair | (-64.9, -80.0) | (-64.9, -79.9) | lairs_one_b1 | (-64.9, -79.9) | 0.0 |
| lairs_one_b1 | lair | (64.9, -80.0) | (64.9, -79.9) | lairs_one_a2 | (64.9, -79.9) | 0.0 |
| lairs_one_b2 | lair | (64.9, 80.0) | (64.9, 79.9) | lairs_one_a1 | (64.9, 79.9) | 0.0 |
| lairs_two_a1 | lair | (-46.9, 80.0) | (-46.9, 79.9) | lairs_two_b2 | (-46.9, 79.9) | 0.0 |
| lairs_two_a2 | lair | (-46.9, -80.0) | (-46.9, -79.9) | lairs_two_b1 | (-46.9, -79.9) | 0.0 |
| lairs_two_b1 | lair | (46.9, -80.0) | (46.9, -79.9) | lairs_two_a2 | (46.9, -79.9) | 0.0 |
| lairs_two_b2 | lair | (46.9, 80.0) | (46.9, 79.9) | lairs_two_a1 | (46.9, 79.9) | 0.0 |
| x_bridge_n | crossing_bridge_road | (0.0, -63.6) | (0.1, -63.6) | x_bridge_n | (-0.1, -63.6) | 0.3 |
| x_bridge_s | crossing_bridge_road | (0.0, 63.6) | (0.1, 63.6) | x_bridge_s | (-0.1, 63.6) | 0.3 |
| x_ford_n | crossing_ford | (0.0, -34.9) | (0.1, -34.9) | x_ford_n | (-0.1, -34.9) | 0.3 |
| x_ford_s | crossing_ford | (0.0, 34.9) | (0.1, 34.9) | x_ford_s | (-0.1, 34.9) | 0.3 |
| x_lane_w | crossing_bridge_lane | (-13.0, 0.0) | (-12.9, 0.1) | x_lane_e | (-12.9, 0.1) | 0.0 |
| x_lane_e | crossing_bridge_lane | (13.0, 0.0) | (12.9, 0.1) | x_lane_w | (12.9, 0.1) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 1923)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | tower_r_a2 - lairs_two_a2 | 34.9 | tower_r_b1 - lairs_two_b1 | 42.8 | -18.5 % |
| 2 | tower_r_b1 - lairs_two_b1 | 42.8 | tower_r_b2 - lairs_two_b2 | 34.9 | +18.5 % |
| 3 | tower_r_a1 - lairs_two_a1 | 34.9 | tower_r_b1 - lairs_two_b1 | 42.8 | -18.5 % |
| 4 | guilds_lodge_a1 - lairs_two_b1 | 206.9 | guilds_lodge_a2 - lairs_two_b2 | 250.3 | -17.3 % |
| 5 | tower_r_a1 - cache_b_b2 | 46.0 | tower_r_a2 - cache_b_b1 | 55.3 | -16.9 % |
| 6 | tower_r_a2 - cache_b_b1 | 55.3 | tower_r_b1 - cache_b_a2 | 46.0 | +16.8 % |
| 7 | tower_r_a1 - cache_b_b2 | 46.0 | tower_r_b2 - cache_b_a1 | 55.3 | -16.8 % |
| 8 | tower_r_b1 - cache_b_a2 | 46.0 | tower_r_b2 - cache_b_a1 | 55.3 | -16.7 % |
| 9 | tower_r_b1 - post_w_a2 | 131.9 | tower_r_b2 - post_w_a1 | 111.2 | +15.7 % |
| 10 | tower_r_a1 - post_w_b2 | 111.2 | tower_r_b1 - post_w_a2 | 131.9 | -15.7 % |
| 11 | post_s_a1 - x_ford_s | 48.9 | post_s_a2 - x_ford_n | 57.4 | -14.8 % |
| 12 | tower_c_b1 - stag_a2 | 106.5 | tower_c_b2 - stag_a1 | 90.8 | +14.8 % |
| 13 | tower_c_a2 - stag_b1 | 90.8 | tower_c_b1 - stag_a2 | 106.5 | -14.7 % |
| 14 | tower_c_a1 - stag_b2 | 90.8 | tower_c_b1 - stag_a2 | 106.5 | -14.7 % |
| 15 | tower_r_a2 - wallow_b1 | 95.5 | tower_r_b1 - wallow_a2 | 112.0 | -14.7 % |
| 16 | tower_r_b1 - wallow_a2 | 112.0 | tower_r_b2 - wallow_a1 | 95.5 | +14.7 % |
| 17 | tower_r_a1 - wallow_b2 | 95.5 | tower_r_b1 - wallow_a2 | 112.0 | -14.7 % |
| 18 | post_s_a2 - x_ford_n | 57.4 | post_s_b2 - x_ford_s | 49.0 | +14.6 % |
| 19 | post_s_a2 - x_ford_n | 57.4 | post_s_b1 - x_ford_n | 49.1 | +14.6 % |
| 20 | third_node_a1 - lairs_two_b1 | 195.6 | third_node_a2 - lairs_two_b2 | 228.2 | -14.3 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 south-west | 32.9 (third_node_a1) | 26.4 (shrine_a1) | 19.4 (wallow_a1) | 47.9 (lairs_one_a1) | 40.0 (inn_a1) | 24.0 (post_w_a1) | 10.7 (peddler_a1) | 39.1 (cache_a_a1) | 75.2 (crown) | 139.7 |
| A2 north-west | 32.9 (third_node_a2) | 26.4 (shrine_a2) | 19.4 (wallow_a2) | 48.0 (lairs_one_a2) | 40.0 (inn_a2) | 24.0 (post_w_a2) | 10.6 (peddler_a2) | 39.1 (cache_a_a2) | 75.2 (crown) | 137.3 |
| B1 north-east | 32.9 (third_node_b1) | 26.4 (shrine_b1) | 19.4 (wallow_b1) | 48.0 (lairs_one_b1) | 40.0 (inn_b1) | 24.0 (post_w_b1) | 10.6 (peddler_b1) | 39.1 (cache_a_b1) | 75.2 (crown) | 137.3 |
| B2 south-east | 32.9 (third_node_b2) | 26.4 (shrine_b2) | 19.4 (wallow_b2) | 47.9 (lairs_one_b2) | 40.0 (inn_b2) | 24.0 (post_w_b2) | 10.7 (peddler_b2) | 39.1 (cache_a_b2) | 75.2 (crown) | 139.7 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| home_b_a1 | home_node | 7.3 | home_b_b2 | 7.3 | +0.0 % |
| home_a_a1 | home_node | 10.0 | home_a_b2 | 10.0 | +0.0 % |
| peddler_a1 | peddler | 10.7 | peddler_b2 | 10.7 | -0.0 % |
| wallow_a1 | camp | 19.4 | wallow_b2 | 19.4 | +0.0 % |
| post_w_a1 | post | 24.0 | post_w_b2 | 24.0 | -0.0 % |
| shrine_a1 | point | 26.4 | shrine_b2 | 26.4 | +0.0 % |
| third_node_a1 | expansion | 32.9 | third_node_b2 | 32.9 | -0.0 % |
| well_a1 | point | 33.4 | well_b2 | 33.4 | -0.0 % |
| nat_node_a1 | expansion | 35.8 | nat_node_b2 | 38.8 | -7.7 % |
| cache_a_a1 | cache | 39.1 | cache_a_b2 | 39.1 | +0.0 % |
| inn_a1 | tavern | 40.0 | inn_b2 | 40.0 | +0.0 % |
| guilds_lodge_a1 | guild | 44.2 | guilds_lodge_b2 | 44.2 | -0.0 % |
| shrine_a2 | point | 46.8 | shrine_b1 | 46.8 | +0.0 % |
| lairs_one_a1 | lair | 47.9 | lairs_one_b2 | 47.9 | +0.0 % |
| post_w_a2 | post | 49.6 | post_w_b1 | 49.6 | +0.0 % |
| guilds_den_a1 | guild | 51.8 | guilds_den_b2 | 51.8 | +0.0 % |
| lairs_two_a1 | lair | 52.2 | lairs_two_b2 | 52.2 | +0.0 % |
| tower_c_a1 | point | 52.8 | tower_c_b2 | 52.8 | +0.0 % |
| stag_a1 | camp | 53.2 | stag_b2 | 53.2 | +0.0 % |
| peddler_a2 | peddler | 55.5 | peddler_b1 | 55.5 | +0.0 % |
| home_a_a2 | home_node | 56.5 | home_a_b1 | 56.5 | +0.0 % |
| rich_node_a1 | expansion | 57.1 | rich_node_b2 | 57.1 | +0.0 % |
| nat_node_a2 | expansion | 59.6 | nat_node_b1 | 59.6 | -0.0 % |
| tower_c_a2 | point | 61.4 | tower_c_b1 | 61.4 | -0.0 % |
| cache_b_a1 | cache | 61.9 | cache_b_b2 | 61.9 | +0.0 % |
| tower_r_a1 | point | 62.6 | tower_r_b2 | 62.6 | +0.0 % |
| x_lane_w | crossing_bridge_lane | 63.6 | x_lane_e | 63.6 | +0.0 % |
| keep_t3 | keep | 65.3 | keep_t1 | 65.1 | +0.4 % |
| post_s_a1 | post | 66.8 | post_s_b2 | 66.8 | +0.0 % |
| inn_a2 | tavern | 67.5 | inn_b1 | 67.5 | +0.0 % |
| home_b_a2 | home_node | 72.7 | home_b_b1 | 72.7 | +0.0 % |
| ford_nest_a1 | camp | 73.0 | ford_nest_a1 | 73.0 | +0.0 % |
| x_ford_s | crossing_ford | 73.0 | x_ford_s | 73.0 | +0.0 % |
| crown | crown | 75.2 | crown | 75.2 | +0.0 % |
| x_bridge_s | crossing_bridge_road | 77.7 | x_bridge_s | 77.7 | +0.0 % |
| wallow_a2 | camp | 82.1 | wallow_b1 | 82.1 | +0.0 % |
| cache_b_b2 | cache | 82.7 | cache_b_a1 | 82.6 | +0.1 % |
| cache_b_a2 | cache | 83.1 | cache_b_b1 | 83.1 | +0.0 % |
| well_a2 | point | 87.0 | well_b1 | 87.0 | +0.0 % |
| x_lane_e | crossing_bridge_lane | 88.1 | x_lane_w | 88.1 | +0.0 % |
| tower_r_b2 | point | 93.5 | tower_r_a1 | 93.5 | +0.0 % |
| rich_node_b2 | expansion | 95.5 | rich_node_a1 | 95.5 | +0.1 % |
| third_node_a2 | expansion | 97.7 | third_node_b1 | 97.7 | +0.0 % |
| tower_c_b1 | point | 98.0 | tower_c_a2 | 98.0 | -0.0 % |
| x_ford_n | crossing_ford | 98.2 | x_ford_n | 98.2 | +0.0 % |
| ford_nest_a2 | camp | 98.2 | ford_nest_a2 | 98.2 | +0.0 % |
| cache_a_a2 | cache | 99.5 | cache_a_b1 | 99.5 | +0.0 % |
| rich_node_a2 | expansion | 99.9 | rich_node_b1 | 100.9 | -1.0 % |
| inn_b2 | tavern | 102.4 | inn_a1 | 102.4 | -0.0 % |
| post_s_b2 | post | 102.7 | post_s_a1 | 102.7 | +0.0 % |
| tower_c_b2 | point | 104.8 | tower_c_a1 | 104.7 | +0.1 % |
| cache_b_b1 | cache | 107.9 | cache_b_a2 | 107.9 | +0.1 % |
| guilds_lodge_a2 | guild | 108.3 | guilds_lodge_b1 | 108.3 | +0.0 % |
| nat_node_b2 | expansion | 109.9 | nat_node_a1 | 109.9 | -0.0 % |
| tower_r_a2 | point | 111.2 | tower_r_b1 | 110.0 | +1.0 % |
| stag_b2 | camp | 113.7 | stag_a1 | 113.7 | +0.0 % |
| inn_b1 | tavern | 114.0 | inn_a2 | 114.0 | +0.0 % |
| stag_a2 | camp | 114.5 | stag_b1 | 114.5 | +0.0 % |
| nat_node_b1 | expansion | 115.1 | nat_node_a2 | 115.1 | +0.0 % |
| well_b2 | point | 115.2 | well_a1 | 115.2 | -0.0 % |
| lairs_one_a2 | lair | 115.5 | lairs_one_b1 | 115.5 | +0.0 % |
| guilds_den_a2 | guild | 117.0 | guilds_den_b1 | 117.0 | +0.0 % |
| x_bridge_n | crossing_bridge_road | 120.7 | x_bridge_n | 119.2 | +1.3 % |
| rich_node_b1 | expansion | 120.7 | rich_node_a2 | 120.6 | +0.1 % |
| lairs_two_a2 | lair | 122.6 | lairs_two_b1 | 122.6 | -0.0 % |
| cache_a_b2 | cache | 123.9 | cache_a_a1 | 123.9 | +0.0 % |
| post_s_a2 | post | 124.4 | post_s_b1 | 124.4 | +0.0 % |
| lairs_two_b2 | lair | 127.1 | lairs_two_a1 | 127.1 | +0.0 % |
| shrine_b1 | point | 128.4 | shrine_a2 | 128.4 | +0.0 % |
| tower_r_b1 | point | 131.9 | tower_r_a2 | 134.7 | -2.1 % |
| shrine_b2 | point | 134.0 | shrine_a1 | 134.0 | -0.0 % |
| home_b_b2 | home_node | 136.2 | home_b_a1 | 136.3 | -0.0 % |
| keep_t4 | keep | 139.7 | keep_t0 | 139.7 | +0.0 % |
| peddler_b2 | peddler | 140.5 | peddler_a1 | 140.6 | -0.0 % |
| well_b1 | point | 140.6 | well_a2 | 140.6 | +0.0 % |
| peddler_b1 | peddler | 143.3 | peddler_a2 | 143.3 | +0.0 % |
| home_a_b2 | home_node | 144.5 | home_a_a1 | 144.5 | -0.0 % |
| lairs_one_b2 | lair | 144.5 | lairs_one_a1 | 144.5 | +0.0 % |
| stag_b1 | camp | 150.2 | stag_a2 | 156.7 | -4.1 % |
| keep_t1 | keep | 150.7 | keep_t3 | 168.8 | -10.7 % |
| home_b_b1 | home_node | 150.7 | home_b_a2 | 150.7 | +0.0 % |
| wallow_b2 | camp | 151.7 | wallow_a1 | 151.7 | -0.0 % |
| home_a_b1 | home_node | 152.6 | home_a_a2 | 152.6 | +0.0 % |
| cache_a_b1 | cache | 153.1 | cache_a_a2 | 153.1 | +0.0 % |
| guilds_den_b2 | guild | 154.7 | guilds_den_a1 | 154.7 | +0.0 % |
| third_node_b2 | expansion | 157.2 | third_node_a1 | 157.2 | +0.0 % |
| post_w_b2 | post | 158.5 | post_w_a1 | 158.5 | -0.0 % |
| post_s_b1 | post | 158.6 | post_s_a2 | 145.2 | +8.5 % |
| guilds_lodge_b2 | guild | 161.9 | guilds_lodge_a1 | 161.9 | +0.0 % |
| lairs_two_b1 | lair | 163.2 | lairs_two_a2 | 170.3 | -4.2 % |
| post_w_b1 | post | 166.8 | post_w_a2 | 166.8 | +0.0 % |
| wallow_b1 | camp | 167.7 | wallow_a2 | 177.2 | -5.3 % |
| lairs_one_b1 | lair | 177.9 | lairs_one_a2 | 187.4 | -5.1 % |
| third_node_b1 | expansion | 179.3 | third_node_a2 | 180.9 | -0.9 % |
| guilds_den_b1 | guild | 188.0 | guilds_den_a2 | 197.6 | -4.9 % |
| guilds_lodge_b1 | guild | 195.4 | guilds_lodge_a2 | 190.5 | +2.5 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| A1 south-west | 0 | keep_t3 | 65.3 | no | 139.7 | 150.7 | 0.47 |
| A2 north-west | 0 | keep_t0 | 65.3 | no | 137.3 | 168.8 | 0.48 |
| B1 north-east | 1 | keep_t4 | 65.1 | no | 137.3 | 150.7 | 0.47 |
| B2 south-east | 1 | keep_t1 | 65.1 | no | 139.7 | 168.8 | 0.47 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| A1 south-west | ally keep (keep_t3) | 65.3 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| A1 south-west | enemy keep (nearest) (keep_t4) | 139.7 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| A1 south-west | enemy keep #2 (keep_t1) | 150.7 | 0.0 | 0:33 | 0:30 | 0:20 | 0:38 |
| A1 south-west | nearest expansion (third_node_a1) | 32.9 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| A1 south-west | nearest point (shrine_a1) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| A1 south-west | nearest camp (wallow_a1) | 19.4 | 0.0 | 0:04 | 0:04 | 0:03 | 0:05 |
| A1 south-west | crown (crown) | 75.2 | 0.0 | 0:16 | 0:15 | 0:10 | 0:19 |
| A2 north-west | ally keep (keep_t0) | 65.1 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| A2 north-west | enemy keep (nearest) (keep_t1) | 137.3 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| A2 north-west | enemy keep #2 (keep_t4) | 168.8 | 0.0 | 0:37 | 0:34 | 0:23 | 0:42 |
| A2 north-west | nearest expansion (third_node_a2) | 32.9 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| A2 north-west | nearest point (shrine_a2) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| A2 north-west | nearest camp (wallow_a2) | 19.4 | 0.0 | 0:04 | 0:04 | 0:03 | 0:05 |
| A2 north-west | crown (crown) | 75.2 | 0.0 | 0:16 | 0:15 | 0:10 | 0:19 |
| B1 north-east | ally keep (keep_t4) | 65.1 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| B1 north-east | enemy keep (nearest) (keep_t3) | 137.3 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| B1 north-east | enemy keep #2 (keep_t0) | 168.8 | 0.0 | 0:37 | 0:34 | 0:23 | 0:42 |
| B1 north-east | nearest expansion (third_node_b1) | 32.9 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| B1 north-east | nearest point (shrine_b1) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| B1 north-east | nearest camp (wallow_b1) | 19.4 | 0.0 | 0:04 | 0:04 | 0:03 | 0:05 |
| B1 north-east | crown (crown) | 75.2 | 0.0 | 0:16 | 0:15 | 0:10 | 0:19 |
| B2 south-east | ally keep (keep_t1) | 65.3 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| B2 south-east | enemy keep (nearest) (keep_t0) | 139.8 | 0.0 | 0:30 | 0:28 | 0:19 | 0:35 |
| B2 south-east | enemy keep #2 (keep_t3) | 150.7 | 0.0 | 0:33 | 0:30 | 0:20 | 0:38 |
| B2 south-east | nearest expansion (third_node_b2) | 32.9 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| B2 south-east | nearest point (shrine_b2) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| B2 south-east | nearest camp (wallow_b2) | 19.4 | 0.0 | 0:04 | 0:04 | 0:03 | 0:05 |
| B2 south-east | crown (crown) | 75.2 | 0.0 | 0:16 | 0:15 | 0:10 | 0:19 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| x_bridge_n | bridge_road | 6.0 | 4.8 | 5.8 | x_bridge_n | 4.8 |
| x_bridge_s | bridge_road | 6.0 | 4.8 | 5.8 | x_bridge_s | 4.8 |
| x_ford_n | ford | 7.0 | 5.8 | 6.8 | x_ford_n | 5.8 |
| x_ford_s | ford | 7.0 | 5.8 | 6.8 | x_ford_s | 5.8 |
| x_lane_w | bridge_lane | 8.0 | 7.0 | 8.0 | x_lane_e | 7.5 |
| x_lane_e | bridge_lane | 8.0 | 7.5 | 8.5 | x_lane_w | 7.0 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 75.5 | 3.8 | (-7.2, 1.6) | - |
| keep_t0 -> keep_t1 | 150.7 | 3.9 | (-7.2, 1.6) | - |
| keep_t0 -> keep_t4 | 139.7 | 1.0 | (-37.7, 25.1) | (-37.7, 25.1) 1.0, (-21.4, 21.8) 1.1 |
| keep_t0 -> third_node_a1 | 32.9 | 15.6 | (-74.4, 54.0) | - |
| keep_t3 -> crown | 75.5 | 4.1 | (-7.2, -1.7) | - |
| keep_t3 -> keep_t4 | 168.8 | 5.8 | (-0.8, 31.7) | - |
| keep_t3 -> third_node_a2 | 32.9 | 15.4 | (-74.4, -54.0) | - |
| keep_t1 -> crown | 75.3 | 4.1 | (7.2, -1.7) | - |
| keep_t1 -> keep_t3 | 137.3 | 1.0 | (37.7, -25.2) | (37.7, -25.2) 1.0 |
| keep_t1 -> third_node_b1 | 32.9 | 15.4 | (74.4, -54.0) | - |
| keep_t4 -> crown | 75.2 | 3.8 | (7.2, 1.6) | - |
| keep_t4 -> third_node_b2 | 32.9 | 15.6 | (74.4, 54.0) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| A1 south-west | ally | 60.00-72.00 | 65.35 | - |
| A1 south-west | enemy_ally | 2.00-3.00 | 2.14 | - |
| A1 south-west | keep_enemy | 130.00-185.00 | 139.75 | - |
| A1 south-west | natural | 32.00-56.00 | 35.82 | - |
| A1 south-west | rich | 50.00-95.00 | 57.12 | - |
| A1 south-west | crown | 60.00-95.00 | 75.22 | - |
| A2 north-west | ally | 60.00-72.00 | 65.35 | - |
| A2 north-west | enemy_ally | 2.00-3.00 | 2.10 | - |
| A2 north-west | keep_enemy | 130.00-185.00 | 137.26 | - |
| A2 north-west | natural | 32.00-56.00 | 38.88 | - |
| A2 north-west | rich | 50.00-95.00 | 57.12 | - |
| A2 north-west | crown | 60.00-95.00 | 75.22 | - |
| B1 north-east | ally | 60.00-72.00 | 65.12 | - |
| B1 north-east | enemy_ally | 2.00-3.00 | 2.11 | - |
| B1 north-east | keep_enemy | 130.00-185.00 | 137.26 | - |
| B1 north-east | natural | 32.00-56.00 | 38.88 | - |
| B1 north-east | rich | 50.00-95.00 | 57.12 | - |
| B1 north-east | crown | 60.00-95.00 | 75.22 | - |
| B2 south-east | ally | 60.00-72.00 | 65.12 | - |
| B2 south-east | enemy_ally | 2.00-3.00 | 2.15 | - |
| B2 south-east | keep_enemy | 130.00-185.00 | 139.75 | - |
| B2 south-east | natural | 32.00-56.00 | 38.80 | - |
| B2 south-east | rich | 50.00-95.00 | 57.12 | - |
| B2 south-east | crown | 60.00-95.00 | 75.22 | - |


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
| A1 south-west | 4 | 3 | 20 | 51 |
| A2 north-west | 4 | 3 | 20 | 51 |
| B1 north-east | 4 | 4 | 20 | 51 |
| B2 south-east | 4 | 3 | 20 | 51 |


## Hottest metres (every spot-pair shortest path, 4656 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (53.5, 4.5) | 349 | 7 % |
| 2 | (-52.5, 4.5) | 330 | 7 % |
| 3 | (3.5, 31.5) | 325 | 7 % |
| 4 | (-0.5, -0.5) | 297 | 6 % |
| 5 | (14.5, 4.5) | 266 | 6 % |
| 6 | (-14.5, 4.5) | 266 | 6 % |
| 7 | (-2.5, -31.5) | 262 | 6 % |
| 8 | (-14.5, -4.5) | 261 | 6 % |
| 9 | (3.5, -61.5) | 253 | 5 % |
| 10 | (14.5, -4.5) | 251 | 5 % |


## Info findings (1101)
| Check | Where | What |
|---|---|---|
| N3 | island 19 at (-71.6, -32.4) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 20 at (71.6, -32.4) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 43 at (-71.6, 32.4) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 44 at (71.6, 32.4) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 56 islands on top of colliders (746 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | nat_node_b1-shrine_b2 vs nat_node_b2-shrine_b1 | 35.1 m vs 33.3 m (5.1 %) |
| F2 | nat_node_a2-shrine_a1 vs nat_node_b2-shrine_b1 | 35.1 m vs 33.3 m (5.1 %) |
| F2 | nat_node_a1-shrine_a2 vs nat_node_b1-shrine_b2 | 33.3 m vs 35.1 m (5.1 %) |
| F2 | nat_node_a1-shrine_a2 vs nat_node_a2-shrine_a1 | 33.3 m vs 35.1 m (5.1 %) |
| F2 | rich_node_a1-guilds_lodge_b2 vs rich_node_a2-guilds_lodge_b1 | 101.7 m vs 107.1 m (5.0 %) |
| F2 | guilds_den_a1-lairs_one_b1 vs guilds_den_b1-lairs_one_a1 | 219.9 m vs 231.5 m (5.0 %) |
| F2 | guilds_den_b1-lairs_one_a1 vs guilds_den_b2-lairs_one_a2 | 231.5 m vs 219.9 m (5.0 %) |
| F2 | keep_t1-guilds_den_a2 vs keep_t4-guilds_den_a1 | 162.9 m vs 154.7 m (5.0 %) |
| F2 | keep_t0-guilds_den_b2 vs keep_t1-guilds_den_a2 | 154.7 m vs 162.9 m (5.0 %) |
| F2 | nat_node_a1-stag_b2 vs nat_node_a2-stag_b1 | 95.8 m vs 91.1 m (5.0 %) |
| F2 | third_node_a1-cache_a_a2 vs third_node_b1-cache_a_b2 | 144.5 m vs 137.3 m (4.9 %) |
| F2 | third_node_b1-cache_a_b2 vs third_node_b2-cache_a_b1 | 137.3 m vs 144.5 m (4.9 %) |
| F2 | nat_node_a2-x_bridge_s vs nat_node_b2-x_bridge_n | 89.6 m vs 94.3 m (4.9 %) |
| F2 | guilds_den_a1-x_ford_n vs guilds_den_a2-x_ford_s | 146.6 m vs 139.4 m (4.9 %) |
| F2 | rich_node_a2-guilds_lodge_b1 vs rich_node_b2-guilds_lodge_a1 | 107.1 m vs 101.8 m (4.9 %) |
| F2 | guilds_den_a2-x_ford_s vs guilds_den_b2-x_ford_n | 139.4 m vs 146.6 m (4.9 %) |
| F2 | nat_node_a2-stag_b1 vs nat_node_b1-stag_a2 | 91.1 m vs 95.8 m (4.9 %) |
| F2 | stag_a1-guilds_lodge_b1 vs stag_b1-guilds_lodge_a1 | 202.5 m vs 192.5 m (4.9 %) |
| F2 | third_node_a1-cache_a_a2 vs third_node_a2-cache_a_a1 | 144.5 m vs 137.3 m (4.9 %) |
| F2 | third_node_a2-cache_a_a1 vs third_node_b2-cache_a_b1 | 137.3 m vs 144.5 m (4.9 %) |
| F2 | post_w_a2-guilds_lodge_b1 vs post_w_b1-guilds_lodge_a2 | 189.1 m vs 179.8 m (4.9 %) |
| F2 | nat_node_a1-x_bridge_n vs nat_node_a2-x_bridge_s | 94.3 m vs 89.6 m (4.9 %) |
| F2 | nat_node_a2-lairs_two_b1 vs nat_node_b1-lairs_two_a2 | 104.1 m vs 109.4 m (4.9 %) |
| F2 | keep_t1-guilds_lodge_a2 vs keep_t4-guilds_lodge_a1 | 170.3 m vs 161.9 m (4.9 %) |
| F2 | keep_t0-guilds_lodge_b2 vs keep_t1-guilds_lodge_a2 | 161.9 m vs 170.3 m (4.9 %) |
| F2 | tower_c_a2-cache_b_b2 vs tower_c_b2-cache_b_a2 | 57.0 m vs 59.9 m (4.9 %) |
| F2 | tower_c_a1-cache_b_b1 vs tower_c_a2-cache_b_b2 | 59.9 m vs 57.0 m (4.9 %) |
| F2 | third_node_b1-lairs_two_a1 vs third_node_b2-lairs_two_a2 | 205.6 m vs 216.2 m (4.9 %) |
| F2 | stag_b1-guilds_lodge_a1 vs stag_b2-guilds_lodge_a2 | 192.5 m vs 202.4 m (4.9 %) |
| F2 | stag_a1-guilds_lodge_b1 vs stag_a2-guilds_lodge_b2 | 202.5 m vs 192.5 m (4.9 %) |
| F2 | rich_node_a2-shrine_b1 vs rich_node_b2-shrine_a1 | 79.8 m vs 83.9 m (4.9 %) |
| F2 | post_s_a1-x_lane_e vs post_s_b1-x_lane_w | 92.2 m vs 87.7 m (4.9 %) |
| F2 | post_s_a1-cache_b_b1 vs post_s_a2-cache_b_b2 | 124.5 m vs 118.4 m (4.9 %) |
| F2 | stag_a2-guilds_lodge_b2 vs stag_b2-guilds_lodge_a2 | 192.5 m vs 202.4 m (4.9 %) |
| F2 | guilds_lodge_a2-lairs_one_b1 vs guilds_lodge_b2-lairs_one_a1 | 159.7 m vs 151.9 m (4.9 %) |
| F2 | third_node_a1-lairs_two_b1 vs third_node_b1-lairs_two_a1 | 195.6 m vs 205.6 m (4.9 %) |
| F2 | guilds_lodge_a1-lairs_one_b2 vs guilds_lodge_a2-lairs_one_b1 | 151.9 m vs 159.7 m (4.9 %) |
| F2 | nat_node_b1-x_bridge_s vs nat_node_b2-x_bridge_n | 89.7 m vs 94.3 m (4.9 %) |
| F2 | tower_r_a2-guilds_den_b2 vs tower_r_b1-guilds_den_a1 | 182.9 m vs 174.0 m (4.9 %) |
| F2 | wallow_a2-lairs_two_a1 vs wallow_b2-lairs_two_b1 | 140.3 m vs 133.5 m (4.9 %) |
| F2 | wallow_b1-lairs_two_b2 vs wallow_b2-lairs_two_b1 | 140.3 m vs 133.5 m (4.9 %) |
| F2 | well_a1-lairs_two_a2 vs well_b1-lairs_two_b2 | 138.3 m vs 131.6 m (4.9 %) |
| F2 | well_b1-lairs_two_b2 vs well_b2-lairs_two_b1 | 131.6 m vs 138.3 m (4.9 %) |
| F2 | well_a2-lairs_two_a1 vs well_b2-lairs_two_b1 | 131.6 m vs 138.3 m (4.9 %) |
| F2 | well_a1-lairs_two_a2 vs well_a2-lairs_two_a1 | 138.3 m vs 131.6 m (4.9 %) |
| F2 | keep_t0-guilds_den_b1 vs keep_t4-guilds_den_a2 | 188.0 m vs 197.6 m (4.9 %) |
| F2 | post_s_a2-x_lane_e vs post_s_b1-x_lane_w | 92.2 m vs 87.7 m (4.9 %) |
| F2 | shrine_a1-guilds_den_b1 vs shrine_b2-guilds_den_a2 | 163.3 m vs 171.6 m (4.9 %) |
| F2 | tower_r_a2-guilds_lodge_b2 vs tower_r_b1-guilds_lodge_a1 | 183.1 m vs 174.2 m (4.8 %) |
| F2 | nat_node_a1-x_bridge_n vs nat_node_b1-x_bridge_s | 94.3 m vs 89.7 m (4.8 %) |
| F2 | tower_c_b1-cache_b_a1 vs tower_c_b2-cache_b_a2 | 57.0 m vs 59.9 m (4.8 %) |
| F2 | tower_c_a1-cache_b_b1 vs tower_c_b1-cache_b_a1 | 59.9 m vs 57.0 m (4.8 %) |
| F2 | post_s_a2-cache_b_b2 vs post_s_b2-cache_b_a2 | 118.4 m vs 124.4 m (4.8 %) |
| F2 | keep_t0-third_node_b2 vs keep_t1-third_node_a2 | 157.2 m vs 165.2 m (4.8 %) |
| F2 | keep_t1-third_node_a2 vs keep_t4-third_node_a1 | 165.2 m vs 157.2 m (4.8 %) |
| F2 | post_w_a1-guilds_lodge_b2 vs post_w_a2-guilds_lodge_b1 | 180.0 m vs 189.1 m (4.8 %) |
| F2 | nat_node_a1-post_s_b1 vs nat_node_b1-post_s_a1 | 121.2 m vs 115.3 m (4.8 %) |
| F2 | guilds_lodge_a2-cache_b_b2 vs guilds_lodge_b2-cache_b_a2 | 159.3 m vs 151.6 m (4.8 %) |
| F2 | rich_node_a1-shrine_b2 vs rich_node_a2-shrine_b1 | 83.8 m vs 79.8 m (4.8 %) |
| F2 | post_w_a2-guilds_lodge_b1 vs post_w_b2-guilds_lodge_a1 | 189.1 m vs 180.1 m (4.8 %) |
| F2 | tower_r_a2-wallow_a1 vs tower_r_b1-wallow_b2 | 130.8 m vs 137.3 m (4.8 %) |
| F2 | tower_r_a1-guilds_den_b1 vs tower_r_b1-guilds_den_a1 | 182.7 m vs 174.0 m (4.8 %) |
| F2 | post_w_a2-guilds_den_b2 vs post_w_b2-guilds_den_a2 | 184.4 m vs 193.6 m (4.8 %) |
| F2 | guilds_lodge_b1-cache_b_a1 vs guilds_lodge_b2-cache_b_a2 | 159.2 m vs 151.6 m (4.8 %) |
| F2 | post_w_b1-guilds_den_a1 vs post_w_b2-guilds_den_a2 | 184.4 m vs 193.6 m (4.8 %) |
| F2 | post_w_a1-x_lane_e vs post_w_b1-x_lane_w | 95.2 m vs 99.9 m (4.8 %) |
| F2 | post_w_a1-x_lane_e vs post_w_a2-x_lane_e | 95.2 m vs 99.9 m (4.8 %) |
| F2 | post_w_b1-x_lane_w vs post_w_b2-x_lane_w | 99.9 m vs 95.2 m (4.8 %) |
| F2 | post_w_a2-x_lane_e vs post_w_b2-x_lane_w | 99.9 m vs 95.2 m (4.8 %) |
| F2 | third_node_a1-stag_b1 vs third_node_a2-stag_b2 | 182.6 m vs 191.7 m (4.8 %) |
| F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_a2-cache_b_b2 | 151.7 m vs 159.3 m (4.7 %) |
| F2 | well_a1-x_bridge_n vs well_b2-x_bridge_n | 133.6 m vs 127.2 m (4.7 %) |
| F2 | post_w_a2-x_bridge_n vs post_w_b1-x_bridge_n | 100.8 m vs 96.0 m (4.7 %) |
| F2 | home_b_a2-guilds_den_b1 vs home_b_b1-guilds_den_a2 | 153.1 m vs 145.8 m (4.7 %) |
| F2 | lairs_one_a1-crown vs lairs_one_b1-crown | 111.5 m vs 106.2 m (4.7 %) |
| F2 | lairs_one_a1-crown vs lairs_one_a2-crown | 111.5 m vs 106.2 m (4.7 %) |
| F2 | lairs_one_b1-crown vs lairs_one_b2-crown | 106.2 m vs 111.5 m (4.7 %) |
| F2 | lairs_one_a2-crown vs lairs_one_b2-crown | 106.2 m vs 111.5 m (4.7 %) |
| F2 | post_s_b1-x_lane_w vs post_s_b2-x_lane_w | 87.7 m vs 92.1 m (4.7 %) |
| F2 | third_node_a1-stag_b1 vs third_node_b1-stag_a1 | 182.6 m vs 191.7 m (4.7 %) |
| F2 | guilds_lodge_a2-peddler_b1 vs guilds_lodge_b2-peddler_a1 | 170.5 m vs 162.4 m (4.7 %) |
| F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_b1-cache_b_a1 | 151.7 m vs 159.2 m (4.7 %) |
| F2 | tower_r_b1-guilds_den_a1 vs tower_r_b2-guilds_den_a2 | 174.0 m vs 182.6 m (4.7 %) |
| F2 | guilds_lodge_a1-peddler_b2 vs guilds_lodge_a2-peddler_b1 | 162.5 m vs 170.5 m (4.7 %) |
| F2 | tower_c_b1-guilds_lodge_b2 vs tower_c_b2-guilds_lodge_b1 | 107.5 m vs 102.4 m (4.7 %) |
| F2 | tower_c_a2-guilds_lodge_a1 vs tower_c_b2-guilds_lodge_b1 | 107.5 m vs 102.4 m (4.7 %) |
| F2 | tower_c_a1-guilds_lodge_a2 vs tower_c_b1-guilds_lodge_b2 | 102.4 m vs 107.5 m (4.7 %) |
| F2 | tower_c_a1-guilds_lodge_a2 vs tower_c_a2-guilds_lodge_a1 | 102.4 m vs 107.5 m (4.7 %) |
| F2 | well_a2-post_s_b1 vs well_b1-post_s_a2 | 70.5 m vs 67.2 m (4.7 %) |
| F2 | third_node_a1-post_w_b1 vs third_node_b2-post_w_a2 | 193.9 m vs 184.9 m (4.7 %) |
| F2 | third_node_b1-lairs_one_a1 vs third_node_b2-lairs_one_a2 | 218.7 m vs 208.6 m (4.6 %) |
| F2 | cache_b_a2-x_lane_e vs cache_b_b1-x_lane_w | 50.1 m vs 47.7 m (4.6 %) |
| F2 | tower_r_a2-cache_a_a2 vs tower_r_b1-cache_a_b1 | 30.5 m vs 32.0 m (4.6 %) |
| F2 | tower_r_a1-cache_a_a1 vs tower_r_b1-cache_a_b1 | 30.5 m vs 32.0 m (4.6 %) |
| F2 | tower_r_b1-cache_a_b1 vs tower_r_b2-cache_a_b2 | 32.0 m vs 30.5 m (4.6 %) |
| F2 | guilds_den_a1-peddler_b1 vs guilds_den_b2-peddler_a2 | 181.8 m vs 190.6 m (4.6 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_b2-wallow_a2 | 145.4 m vs 152.5 m (4.6 %) |
| F2 | post_w_b1-x_bridge_n vs post_w_b2-x_bridge_s | 96.0 m vs 100.6 m (4.6 %) |
| F2 | post_w_a1-x_bridge_s vs post_w_b1-x_bridge_n | 100.6 m vs 96.0 m (4.6 %) |
| F2 | cache_a_a1-x_bridge_n vs cache_a_b2-x_bridge_n | 146.8 m vs 140.0 m (4.6 %) |
| F2 | guilds_lodge_a1-guilds_lodge_b2 vs guilds_lodge_a2-guilds_lodge_b1 | 169.0 m vs 177.1 m (4.6 %) |
| F2 | keep_t0-post_s_b1 vs keep_t1-post_s_a1 | 158.6 m vs 151.3 m (4.6 %) |
| F2 | inn_a2-x_ford_n vs inn_b2-x_ford_s | 31.5 m vs 33.0 m (4.6 %) |
| F2 | inn_b1-x_ford_n vs inn_b2-x_ford_s | 31.5 m vs 33.0 m (4.6 %) |
| F2 | inn_a1-x_ford_s vs inn_b1-x_ford_n | 33.0 m vs 31.5 m (4.6 %) |
| F2 | inn_a1-x_ford_s vs inn_a2-x_ford_n | 33.0 m vs 31.5 m (4.6 %) |
| F2 | home_b_a2-post_w_b2 vs home_b_b1-post_w_a1 | 188.9 m vs 180.3 m (4.6 %) |
| F2 | well_a2-lairs_one_b1 vs well_b2-lairs_one_a1 | 117.4 m vs 112.1 m (4.5 %) |
| F2 | well_a1-lairs_one_b2 vs well_a2-lairs_one_b1 | 112.1 m vs 117.4 m (4.5 %) |
| F2 | post_w_a2-lairs_one_b2 vs post_w_b2-lairs_one_a2 | 175.1 m vs 183.4 m (4.5 %) |
| F2 | keep_t0-post_s_b1 vs keep_t3-post_s_b2 | 158.6 m vs 151.4 m (4.5 %) |
| F2 | third_node_a1-shrine_b2 vs third_node_b1-shrine_a2 | 151.3 m vs 144.4 m (4.5 %) |
| F2 | post_w_b1-lairs_one_a1 vs post_w_b2-lairs_one_a2 | 175.2 m vs 183.4 m (4.5 %) |
| F2 | rich_node_a2-guilds_den_b1 vs rich_node_b1-guilds_den_a2 | 99.7 m vs 95.2 m (4.5 %) |
| F2 | rich_node_a1-guilds_den_b2 vs rich_node_a2-guilds_den_b1 | 95.2 m vs 99.7 m (4.5 %) |
| F2 | home_b_a2-guilds_lodge_b1 vs home_b_b1-guilds_lodge_a2 | 160.5 m vs 153.2 m (4.5 %) |
| F2 | third_node_a1-shrine_b2 vs third_node_a2-shrine_b1 | 151.3 m vs 144.5 m (4.5 %) |
| F2 | home_b_a1-lairs_two_b1 vs home_b_b2-lairs_two_a2 | 167.4 m vs 175.3 m (4.5 %) |
| F2 | home_b_a1-post_s_b1 vs home_b_b1-post_s_a1 | 163.6 m vs 156.3 m (4.5 %) |
| F2 | guilds_den_a2-peddler_b2 vs guilds_den_b1-peddler_a1 | 179.4 m vs 187.8 m (4.5 %) |
| F2 | tower_r_a1-post_w_a2 vs tower_r_b1-post_w_b2 | 109.6 m vs 104.7 m (4.5 %) |
| F2 | tower_r_b1-post_w_b2 vs tower_r_b2-post_w_b1 | 104.7 m vs 109.6 m (4.5 %) |
| F2 | rich_node_a2-peddler_b1 vs rich_node_b1-peddler_a2 | 95.7 m vs 91.4 m (4.5 %) |
| F2 | third_node_b1-shrine_a2 vs third_node_b2-shrine_a1 | 144.4 m vs 151.2 m (4.5 %) |
| F2 | inn_a1-peddler_b1 vs inn_a2-peddler_b2 | 106.6 m vs 111.6 m (4.5 %) |
| F2 | inn_a2-peddler_b2 vs inn_b2-peddler_a2 | 111.6 m vs 106.6 m (4.5 %) |
| F2 | inn_a1-peddler_b1 vs inn_b1-peddler_a1 | 106.6 m vs 111.6 m (4.5 %) |
| F2 | inn_b1-peddler_a1 vs inn_b2-peddler_a2 | 111.6 m vs 106.6 m (4.5 %) |
| F2 | home_b_a1-stag_b1 vs home_b_b2-stag_a2 | 154.4 m vs 161.6 m (4.5 %) |
| F2 | home_b_a2-ford_nest_a1 vs home_b_b2-ford_nest_a2 | 107.2 m vs 102.4 m (4.5 %) |
| F2 | home_b_a2-x_ford_s vs home_b_b2-x_ford_n | 107.2 m vs 102.4 m (4.5 %) |
| F2 | home_b_a1-ford_nest_a2 vs home_b_a2-ford_nest_a1 | 102.4 m vs 107.2 m (4.5 %) |
| F2 | home_b_a1-x_ford_n vs home_b_a2-x_ford_s | 102.4 m vs 107.2 m (4.5 %) |
| F2 | third_node_a2-shrine_b1 vs third_node_b2-shrine_a1 | 144.5 m vs 151.2 m (4.5 %) |
| F2 | nat_node_b1-peddler_a1 vs nat_node_b2-peddler_a2 | 112.7 m vs 107.7 m (4.5 %) |
| F2 | nat_node_a2-peddler_b2 vs nat_node_b2-peddler_a2 | 112.7 m vs 107.7 m (4.5 %) |
| F2 | nat_node_a1-peddler_b1 vs nat_node_b1-peddler_a1 | 107.7 m vs 112.7 m (4.5 %) |
| F2 | nat_node_a1-peddler_b1 vs nat_node_a2-peddler_b2 | 107.7 m vs 112.7 m (4.5 %) |
| F2 | rich_node_a2-guilds_den_b1 vs rich_node_b2-guilds_den_a1 | 99.7 m vs 95.3 m (4.4 %) |
| F2 | home_b_a2-post_s_b2 vs home_b_b2-post_s_a2 | 156.4 m vs 149.4 m (4.4 %) |
| F2 | wallow_a2-peddler_b2 vs wallow_b2-peddler_a2 | 167.8 m vs 160.3 m (4.4 %) |
| F2 | wallow_a1-peddler_b1 vs wallow_a2-peddler_b2 | 160.3 m vs 167.8 m (4.4 %) |
| F2 | home_b_b1-x_ford_s vs home_b_b2-x_ford_n | 107.2 m vs 102.4 m (4.4 %) |
| F2 | home_b_b1-ford_nest_a1 vs home_b_b2-ford_nest_a2 | 107.2 m vs 102.4 m (4.4 %) |
| F2 | home_b_a1-ford_nest_a2 vs home_b_b1-ford_nest_a1 | 102.4 m vs 107.2 m (4.4 %) |
| F2 | home_b_a1-x_ford_n vs home_b_b1-x_ford_s | 102.4 m vs 107.2 m (4.4 %) |
| F2 | wallow_a1-peddler_b1 vs wallow_b1-peddler_a1 | 160.3 m vs 167.8 m (4.4 %) |
| F2 | wallow_b1-peddler_a1 vs wallow_b2-peddler_a2 | 167.8 m vs 160.3 m (4.4 %) |
| F2 | home_b_a1-post_s_b1 vs home_b_a2-post_s_b2 | 163.6 m vs 156.4 m (4.4 %) |
| F2 | third_node_a2-tower_r_a1 vs third_node_b2-tower_r_b1 | 149.0 m vs 142.5 m (4.4 %) |
| F2 | nat_node_a1-third_node_b1 vs nat_node_b1-third_node_a1 | 142.2 m vs 148.8 m (4.4 %) |
| F2 | nat_node_b1-third_node_a1 vs nat_node_b2-third_node_a2 | 148.8 m vs 142.2 m (4.4 %) |
| F2 | third_node_a1-post_w_b1 vs third_node_a2-post_w_b2 | 193.9 m vs 185.4 m (4.4 %) |
| F2 | well_a2-shrine_b1 vs well_b1-shrine_a2 | 99.5 m vs 104.1 m (4.4 %) |
| F2 | shrine_a1-ford_nest_a1 vs shrine_a2-ford_nest_a2 | 59.5 m vs 56.9 m (4.4 %) |
| F2 | shrine_a1-x_ford_s vs shrine_a2-x_ford_n | 59.5 m vs 56.9 m (4.4 %) |
| F2 | shrine_a1-ford_nest_a1 vs shrine_b1-ford_nest_a2 | 59.5 m vs 56.9 m (4.4 %) |
| F2 | shrine_a1-x_ford_s vs shrine_b1-x_ford_n | 59.5 m vs 56.9 m (4.4 %) |
| F2 | third_node_b1-tower_r_b2 vs third_node_b2-tower_r_b1 | 149.0 m vs 142.5 m (4.4 %) |
| F2 | home_b_b1-post_s_a1 vs home_b_b2-post_s_a2 | 156.3 m vs 149.4 m (4.4 %) |
| F2 | inn_a1-post_s_b2 vs inn_b1-post_s_a2 | 76.1 m vs 79.6 m (4.4 %) |
| F2 | nat_node_a2-cache_b_b2 vs nat_node_b1-cache_b_a1 | 72.6 m vs 75.9 m (4.4 %) |
| F2 | well_a2-shrine_b1 vs well_b2-shrine_a1 | 99.5 m vs 104.0 m (4.4 %) |
| F2 | tower_r_a2-crown vs tower_r_b1-crown | 78.5 m vs 75.1 m (4.4 %) |
| F2 | well_a1-shrine_b2 vs well_a2-shrine_b1 | 104.0 m vs 99.5 m (4.3 %) |
| F2 | ford_nest_a1-inn_a1 vs ford_nest_a2-inn_b1 | 31.5 m vs 32.9 m (4.3 %) |
| F2 | ford_nest_a1-inn_a1 vs ford_nest_a2-inn_a2 | 31.5 m vs 32.9 m (4.3 %) |
| F2 | ford_nest_a1-inn_b2 vs ford_nest_a2-inn_a2 | 31.5 m vs 32.9 m (4.3 %) |
| F2 | ford_nest_a1-inn_b2 vs ford_nest_a2-inn_b1 | 31.5 m vs 32.9 m (4.3 %) |
| F2 | ford_nest_a1-post_w_a1 vs ford_nest_a2-post_w_b1 | 86.6 m vs 90.5 m (4.3 %) |
| F2 | ford_nest_a1-post_w_b2 vs ford_nest_a2-post_w_b1 | 86.6 m vs 90.5 m (4.3 %) |
| F2 | nat_node_a1-rich_node_a2 vs nat_node_b2-rich_node_b1 | 72.8 m vs 76.1 m (4.3 %) |
| F2 | nat_node_b1-rich_node_b2 vs nat_node_b2-rich_node_b1 | 72.8 m vs 76.1 m (4.3 %) |
| F2 | nat_node_a2-rich_node_a1 vs nat_node_b2-rich_node_b1 | 72.8 m vs 76.1 m (4.3 %) |
| F2 | well_a1-post_s_b2 vs well_b1-post_s_a2 | 70.3 m vs 67.2 m (4.3 %) |
| F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_b1-cache_a_b2 | 154.1 m vs 147.5 m (4.3 %) |
| F2 | cache_a_a2-lairs_one_b1 vs cache_a_b1-lairs_one_a2 | 119.1 m vs 114.0 m (4.3 %) |
| F2 | stag_a1-x_ford_n vs stag_b1-x_ford_s | 120.8 m vs 115.6 m (4.3 %) |
| F2 | stag_b1-x_ford_s vs stag_b2-x_ford_n | 115.6 m vs 120.8 m (4.3 %) |
| F2 | tower_r_b1-shrine_a1 vs tower_r_b2-shrine_a2 | 116.0 m vs 111.0 m (4.3 %) |
| F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_a2-cache_a_a1 | 154.1 m vs 147.5 m (4.3 %) |
| F2 | peddler_a1-x_ford_s vs peddler_a2-x_ford_n | 68.8 m vs 65.8 m (4.3 %) |
| F2 | peddler_a1-x_ford_s vs peddler_b1-x_ford_n | 68.8 m vs 65.8 m (4.3 %) |
| F2 | peddler_b1-x_ford_n vs peddler_b2-x_ford_s | 65.8 m vs 68.8 m (4.3 %) |
| F2 | peddler_a2-x_ford_n vs peddler_b2-x_ford_s | 65.8 m vs 68.8 m (4.3 %) |
| F2 | guilds_den_a1-lairs_two_b1 vs guilds_den_b2-lairs_two_a2 | 221.1 m vs 211.6 m (4.3 %) |
| F2 | cache_a_a2-lairs_one_b1 vs cache_a_b2-lairs_one_a1 | 119.1 m vs 114.0 m (4.3 %) |
| F2 | cache_a_a1-lairs_one_b2 vs cache_a_a2-lairs_one_b1 | 114.0 m vs 119.1 m (4.3 %) |
| F2 | inn_b1-lairs_two_a2 vs inn_b2-lairs_two_a1 | 103.4 m vs 99.0 m (4.3 %) |
| F2 | well_b1-post_s_a2 vs well_b2-post_s_a1 | 67.2 m vs 70.2 m (4.3 %) |
| F2 | third_node_b1-x_ford_n vs third_node_b2-x_ford_s | 88.5 m vs 92.5 m (4.3 %) |
| F2 | third_node_b1-ford_nest_a2 vs third_node_b2-ford_nest_a1 | 88.5 m vs 92.5 m (4.3 %) |
| F2 | third_node_a1-ford_nest_a1 vs third_node_b1-ford_nest_a2 | 92.5 m vs 88.5 m (4.3 %) |
| F2 | third_node_a1-x_ford_s vs third_node_b1-x_ford_n | 92.5 m vs 88.5 m (4.3 %) |
| F2 | third_node_a2-ford_nest_a2 vs third_node_b2-ford_nest_a1 | 88.5 m vs 92.5 m (4.3 %) |
| F2 | third_node_a2-x_ford_n vs third_node_b2-x_ford_s | 88.5 m vs 92.5 m (4.3 %) |
| F2 | third_node_a1-ford_nest_a1 vs third_node_a2-ford_nest_a2 | 92.5 m vs 88.5 m (4.3 %) |
| F2 | third_node_a1-x_ford_s vs third_node_a2-x_ford_n | 92.5 m vs 88.5 m (4.3 %) |
| F2 | inn_a1-lairs_two_b2 vs inn_b1-lairs_two_a2 | 99.0 m vs 103.4 m (4.3 %) |
| F2 | guilds_den_a1-x_ford_n vs guilds_den_b1-x_ford_s | 146.6 m vs 140.4 m (4.3 %) |
| F2 | well_a2-stag_b1 vs well_b1-stag_a2 | 81.4 m vs 78.0 m (4.3 %) |
| F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_b1-guilds_lodge_a2 | 130.3 m vs 136.1 m (4.3 %) |
| F2 | guilds_den_b1-x_ford_s vs guilds_den_b2-x_ford_n | 140.4 m vs 146.6 m (4.3 %) |
| F2 | lairs_one_a2-x_lane_e vs lairs_one_b2-x_lane_w | 119.1 m vs 124.4 m (4.3 %) |
| F2 | lairs_one_a1-x_lane_e vs lairs_one_a2-x_lane_e | 124.4 m vs 119.1 m (4.3 %) |
| F2 | tower_c_b1-guilds_lodge_a2 vs tower_c_b2-guilds_lodge_a1 | 136.1 m vs 130.3 m (4.3 %) |
| F2 | tower_r_a1-shrine_b1 vs tower_r_b1-shrine_a1 | 111.1 m vs 116.0 m (4.2 %) |
| F2 | home_a_a1-post_s_b1 vs home_a_b1-post_s_a1 | 150.9 m vs 144.5 m (4.2 %) |
| F2 | tower_r_a2-wallow_b2 vs tower_r_b1-wallow_a1 | 154.0 m vs 147.5 m (4.2 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_b2-lairs_two_a2 | 152.9 m vs 159.6 m (4.2 %) |
| F2 | cache_b_a2-x_lane_e vs cache_b_b2-x_lane_w | 50.1 m vs 47.9 m (4.2 %) |
| F2 | peddler_a2-x_ford_s vs peddler_b2-x_ford_n | 91.7 m vs 87.8 m (4.2 %) |
| F2 | peddler_a1-x_ford_n vs peddler_a2-x_ford_s | 87.8 m vs 91.7 m (4.2 %) |
| F2 | home_b_a2-x_ford_n vs home_b_b2-x_ford_s | 68.5 m vs 71.5 m (4.2 %) |
| F2 | home_b_a2-ford_nest_a2 vs home_b_b2-ford_nest_a1 | 68.5 m vs 71.5 m (4.2 %) |
| F2 | home_b_a1-x_ford_s vs home_b_a2-x_ford_n | 71.5 m vs 68.5 m (4.2 %) |
| F2 | home_b_a1-ford_nest_a1 vs home_b_a2-ford_nest_a2 | 71.5 m vs 68.5 m (4.2 %) |
| F2 | home_b_a1-ford_nest_a1 vs home_b_b1-ford_nest_a2 | 71.5 m vs 68.5 m (4.2 %) |
| F2 | home_b_a1-x_ford_s vs home_b_b1-x_ford_n | 71.5 m vs 68.5 m (4.2 %) |
| F2 | home_b_b1-ford_nest_a2 vs home_b_b2-ford_nest_a1 | 68.5 m vs 71.5 m (4.2 %) |
| F2 | home_b_b1-x_ford_n vs home_b_b2-x_ford_s | 68.5 m vs 71.5 m (4.2 %) |
| F2 | well_a2-guilds_lodge_b1 vs well_b2-guilds_lodge_a1 | 134.9 m vs 129.2 m (4.2 %) |
| F2 | well_a1-guilds_lodge_b2 vs well_a2-guilds_lodge_b1 | 129.2 m vs 134.9 m (4.2 %) |
| F2 | third_node_a1-tower_c_a2 vs third_node_a2-tower_c_a1 | 91.0 m vs 95.0 m (4.2 %) |
| F2 | third_node_a1-tower_c_a2 vs third_node_b1-tower_c_b2 | 91.0 m vs 95.0 m (4.2 %) |
| F2 | third_node_a2-tower_c_a1 vs third_node_b2-tower_c_b1 | 95.0 m vs 91.0 m (4.2 %) |
| F2 | third_node_b1-tower_c_b2 vs third_node_b2-tower_c_b1 | 95.0 m vs 91.0 m (4.2 %) |
| F2 | well_b1-cache_a_a2 vs well_b2-cache_a_a1 | 87.6 m vs 91.5 m (4.2 %) |
| F2 | well_a1-cache_a_b2 vs well_b1-cache_a_a2 | 91.5 m vs 87.6 m (4.2 %) |
| F2 | peddler_b1-x_ford_s vs peddler_b2-x_ford_n | 91.7 m vs 87.8 m (4.2 %) |
| F2 | peddler_a1-x_ford_n vs peddler_b1-x_ford_s | 87.8 m vs 91.7 m (4.2 %) |
| F2 | inn_a1-guilds_lodge_a2 vs inn_b2-guilds_lodge_b1 | 120.4 m vs 115.4 m (4.2 %) |
| F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_a2-guilds_lodge_b1 | 130.3 m vs 136.0 m (4.2 %) |
| F2 | tower_c_a2-guilds_lodge_b1 vs tower_c_b2-guilds_lodge_a1 | 136.0 m vs 130.3 m (4.2 %) |
| F2 | tower_r_b1-lairs_two_a2 vs tower_r_b2-lairs_two_a1 | 67.4 m vs 64.6 m (4.2 %) |
| F2 | home_a_a1-post_s_b1 vs home_a_a2-post_s_b2 | 150.9 m vs 144.6 m (4.2 %) |
| F2 | wallow_a2-ford_nest_a2 vs wallow_b2-ford_nest_a1 | 81.4 m vs 84.9 m (4.2 %) |
| F2 | wallow_a1-ford_nest_a1 vs wallow_a2-ford_nest_a2 | 84.9 m vs 81.4 m (4.2 %) |
| F2 | wallow_a1-x_ford_s vs wallow_b1-x_ford_n | 84.9 m vs 81.4 m (4.2 %) |
| F2 | wallow_a2-x_ford_n vs wallow_b2-x_ford_s | 81.4 m vs 84.9 m (4.2 %) |
| F2 | wallow_a1-ford_nest_a1 vs wallow_b1-ford_nest_a2 | 84.9 m vs 81.4 m (4.2 %) |
| F2 | wallow_b1-x_ford_n vs wallow_b2-x_ford_s | 81.4 m vs 84.9 m (4.2 %) |
| F2 | wallow_b1-ford_nest_a2 vs wallow_b2-ford_nest_a1 | 81.4 m vs 84.9 m (4.2 %) |
| F2 | wallow_a1-x_ford_s vs wallow_a2-x_ford_n | 84.9 m vs 81.4 m (4.2 %) |
| F2 | peddler_a2-cache_a_b1 vs peddler_b2-cache_a_a1 | 129.2 m vs 123.8 m (4.2 %) |
| F2 | peddler_a1-cache_a_b2 vs peddler_a2-cache_a_b1 | 123.8 m vs 129.2 m (4.2 %) |
| F2 | tower_r_a1-lairs_two_b2 vs tower_r_b1-lairs_two_a2 | 64.6 m vs 67.4 m (4.2 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t4-lairs_two_a2 | 163.2 m vs 170.3 m (4.2 %) |
| F2 | post_w_a1-post_w_b1 vs post_w_b2-post_w_a2 | 173.8 m vs 181.3 m (4.2 %) |
| F2 | third_node_a1-guilds_den_b1 vs third_node_b2-guilds_den_a2 | 225.8 m vs 216.3 m (4.2 %) |
| F2 | tower_r_a1-guilds_lodge_b1 vs tower_r_b1-guilds_lodge_a1 | 181.8 m vs 174.2 m (4.2 %) |
| F2 | rich_node_a1-post_w_b2 vs rich_node_a2-post_w_b1 | 108.3 m vs 113.1 m (4.2 %) |
| F2 | well_b1-x_lane_e vs well_b2-x_lane_e | 60.1 m vs 57.6 m (4.2 %) |
| F2 | well_a2-x_lane_w vs well_b2-x_lane_e | 60.1 m vs 57.6 m (4.2 %) |
| F2 | well_a1-x_lane_w vs well_b1-x_lane_e | 57.6 m vs 60.1 m (4.2 %) |
| F2 | well_a1-x_lane_w vs well_a2-x_lane_w | 57.6 m vs 60.1 m (4.2 %) |
| F2 | rich_node_a2-guilds_lodge_b1 vs rich_node_b1-guilds_lodge_a2 | 107.1 m vs 102.6 m (4.2 %) |
| F2 | tower_r_b1-peddler_a1 vs tower_r_b2-peddler_a2 | 130.2 m vs 124.8 m (4.2 %) |
| F2 | tower_r_b1-guilds_lodge_a1 vs tower_r_b2-guilds_lodge_a2 | 174.2 m vs 181.7 m (4.1 %) |
| F2 | cache_b_a1-x_lane_e vs cache_b_a2-x_lane_e | 48.0 m vs 50.1 m (4.1 %) |
| F2 | keep_t3-post_s_b2 vs keep_t4-post_s_a2 | 151.4 m vs 145.2 m (4.1 %) |
| F2 | rich_node_a1-cache_b_a2 vs rich_node_a2-cache_b_a1 | 81.9 m vs 78.5 m (4.1 %) |
| F2 | rich_node_a1-cache_b_a2 vs rich_node_b1-cache_b_b2 | 81.9 m vs 78.5 m (4.1 %) |
| F2 | rich_node_a2-cache_b_a1 vs rich_node_b2-cache_b_b1 | 78.5 m vs 81.9 m (4.1 %) |
| F2 | rich_node_b1-cache_b_b2 vs rich_node_b2-cache_b_b1 | 78.5 m vs 81.9 m (4.1 %) |
| F2 | keep_t0-stag_b1 vs keep_t4-stag_a2 | 150.2 m vs 156.7 m (4.1 %) |
| F2 | ford_nest_a2-post_w_a2 vs ford_nest_a2-post_w_b1 | 86.8 m vs 90.5 m (4.1 %) |
| F2 | tower_r_a1-peddler_b1 vs tower_r_b1-peddler_a1 | 124.9 m vs 130.2 m (4.1 %) |
| F2 | home_a_a1-lairs_one_b1 vs home_a_b2-lairs_one_a2 | 172.4 m vs 179.8 m (4.1 %) |
| F2 | keep_t0-ford_nest_a1 vs keep_t3-ford_nest_a2 | 73.0 m vs 70.0 m (4.1 %) |
| F2 | keep_t0-x_ford_s vs keep_t3-x_ford_n | 73.0 m vs 70.0 m (4.1 %) |
| F2 | keep_t0-x_ford_s vs keep_t1-x_ford_n | 73.0 m vs 70.0 m (4.1 %) |
| F2 | keep_t3-ford_nest_a2 vs keep_t4-ford_nest_a1 | 70.0 m vs 73.0 m (4.1 %) |
| F2 | keep_t1-ford_nest_a2 vs keep_t4-ford_nest_a1 | 70.0 m vs 73.0 m (4.1 %) |
| F2 | keep_t0-ford_nest_a1 vs keep_t1-ford_nest_a2 | 73.0 m vs 70.0 m (4.1 %) |
| F2 | keep_t1-x_ford_n vs keep_t4-x_ford_s | 70.0 m vs 73.0 m (4.1 %) |
| F2 | keep_t3-x_ford_n vs keep_t4-x_ford_s | 70.0 m vs 73.0 m (4.1 %) |
| F2 | well_a2-guilds_den_b1 vs well_b2-guilds_den_a1 | 127.5 m vs 122.3 m (4.1 %) |
| F2 | well_a1-guilds_den_b2 vs well_a2-guilds_den_b1 | 122.3 m vs 127.5 m (4.1 %) |
| F2 | rich_node_a2-post_w_b1 vs rich_node_b2-post_w_a1 | 113.1 m vs 108.4 m (4.1 %) |
| F2 | keep_t1-post_s_a1 vs keep_t4-post_s_a2 | 151.3 m vs 145.2 m (4.1 %) |
| F2 | shrine_a1-lairs_two_b1 vs shrine_b2-lairs_two_a2 | 138.5 m vs 144.3 m (4.1 %) |
| F2 | tower_r_b1-guilds_lodge_a2 vs tower_r_b2-guilds_lodge_a1 | 103.5 m vs 99.3 m (4.0 %) |
| F2 | tower_r_a1-guilds_lodge_b2 vs tower_r_b1-guilds_lodge_a2 | 99.3 m vs 103.5 m (4.0 %) |
| F2 | well_a1-stag_b2 vs well_b1-stag_a2 | 81.2 m vs 78.0 m (4.0 %) |
| F2 | well_b1-stag_a2 vs well_b2-stag_a1 | 78.0 m vs 81.2 m (4.0 %) |
| F2 | well_a2-crown vs well_b2-crown | 71.1 m vs 68.2 m (4.0 %) |
| F2 | well_b1-crown vs well_b2-crown | 71.1 m vs 68.2 m (4.0 %) |
| F2 | well_a1-crown vs well_a2-crown | 68.2 m vs 71.1 m (4.0 %) |
| F2 | well_a1-crown vs well_b1-crown | 68.2 m vs 71.1 m (4.0 %) |
| F2 | stag_a2-post_s_b2 vs stag_b1-post_s_a1 | 163.9 m vs 170.8 m (4.0 %) |
| F2 | home_b_a2-inn_a1 vs home_b_b2-inn_b1 | 74.7 m vs 71.7 m (4.0 %) |
| F2 | home_b_a1-inn_a2 vs home_b_a2-inn_a1 | 71.7 m vs 74.7 m (4.0 %) |
| F2 | post_w_a1-lairs_one_b1 vs post_w_b2-lairs_one_a2 | 176.1 m vs 183.4 m (4.0 %) |
| F2 | home_a_a2-cache_a_b1 vs home_a_b1-cache_a_a2 | 133.5 m vs 128.1 m (4.0 %) |
| F2 | tower_r_a2-guilds_lodge_a1 vs tower_r_b1-guilds_lodge_b2 | 156.9 m vs 163.5 m (4.0 %) |
| F2 | keep_t3-x_bridge_n vs keep_t1-x_bridge_n | 77.8 m vs 74.7 m (4.0 %) |
| F2 | cache_a_b1-lairs_two_a1 vs cache_a_b2-lairs_two_a2 | 189.6 m vs 182.0 m (4.0 %) |
| F2 | stag_a1-post_w_b1 vs stag_a2-post_w_b2 | 153.7 m vs 147.6 m (4.0 %) |
| F2 | keep_t3-ford_nest_a1 vs keep_t4-ford_nest_a2 | 102.3 m vs 98.2 m (4.0 %) |
| F2 | keep_t3-x_ford_s vs keep_t4-x_ford_n | 102.3 m vs 98.2 m (4.0 %) |
| F2 | keep_t0-ford_nest_a2 vs keep_t3-ford_nest_a1 | 98.2 m vs 102.3 m (4.0 %) |
| F2 | keep_t0-x_ford_n vs keep_t3-x_ford_s | 98.2 m vs 102.3 m (4.0 %) |
| F2 | home_a_a2-post_s_b2 vs home_a_b2-post_s_a2 | 144.6 m vs 138.8 m (4.0 %) |
| F2 | home_b_b1-inn_b2 vs home_b_b2-inn_b1 | 74.7 m vs 71.7 m (4.0 %) |
| F2 | home_b_a1-inn_a2 vs home_b_b1-inn_b2 | 71.7 m vs 74.7 m (4.0 %) |
| F2 | shrine_a2-peddler_b2 vs shrine_b2-peddler_a2 | 126.1 m vs 121.0 m (4.0 %) |
| F2 | shrine_b1-peddler_a1 vs shrine_b2-peddler_a2 | 126.1 m vs 121.0 m (4.0 %) |
| F2 | shrine_a1-peddler_b1 vs shrine_a2-peddler_b2 | 121.0 m vs 126.1 m (4.0 %) |
| F2 | shrine_a1-peddler_b1 vs shrine_b1-peddler_a1 | 121.0 m vs 126.1 m (4.0 %) |
| F2 | keep_t0-x_ford_n vs keep_t1-x_ford_s | 98.2 m vs 102.2 m (4.0 %) |
| F2 | keep_t1-ford_nest_a1 vs keep_t4-ford_nest_a2 | 102.2 m vs 98.2 m (4.0 %) |
| F2 | keep_t0-ford_nest_a2 vs keep_t1-ford_nest_a1 | 98.2 m vs 102.2 m (4.0 %) |
| F2 | keep_t1-x_ford_s vs keep_t4-x_ford_n | 102.2 m vs 98.2 m (4.0 %) |
| F2 | shrine_a1-stag_b1 vs shrine_b2-stag_a2 | 125.5 m vs 130.7 m (4.0 %) |
| F2 | post_s_a1-lairs_two_b1 vs post_s_b1-lairs_two_a1 | 180.6 m vs 173.4 m (4.0 %) |
| F2 | nat_node_a1-cache_b_b1 vs nat_node_b1-cache_b_a1 | 79.0 m vs 75.9 m (4.0 %) |
| F2 | stag_a2-post_w_b2 vs stag_b2-post_w_a2 | 147.6 m vs 153.7 m (4.0 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_b1-wallow_a1 | 167.1 m vs 174.0 m (4.0 %) |
| F2 | home_a_b1-post_s_a1 vs home_a_b2-post_s_a2 | 144.5 m vs 138.8 m (3.9 %) |
| F2 | home_a_a1-guilds_den_b1 vs home_a_b2-guilds_den_a2 | 182.5 m vs 190.0 m (3.9 %) |
| F2 | third_node_a2-tower_c_b1 vs third_node_b1-tower_c_a2 | 121.4 m vs 116.6 m (3.9 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_b2-wallow_a2 | 174.3 m vs 181.4 m (3.9 %) |
| F2 | nat_node_a1-guilds_lodge_b2 vs nat_node_a2-guilds_lodge_b1 | 130.9 m vs 136.3 m (3.9 %) |
| F2 | nat_node_a2-guilds_lodge_b1 vs nat_node_b2-guilds_lodge_a1 | 136.3 m vs 130.9 m (3.9 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_a2-wallow_b2 | 167.1 m vs 173.9 m (3.9 %) |
| F2 | home_b_a2-cache_b_b2 vs home_b_b2-cache_b_a2 | 116.7 m vs 112.1 m (3.9 %) |
| F2 | post_s_a1-lairs_two_b2 vs post_s_b1-lairs_two_a2 | 73.2 m vs 76.2 m (3.9 %) |
| F2 | tower_c_a2-post_s_a2 vs tower_c_b1-post_s_b1 | 71.6 m vs 74.5 m (3.9 %) |
| F2 | nat_node_a1-peddler_a2 vs nat_node_b1-peddler_b2 | 51.5 m vs 49.5 m (3.9 %) |
| F2 | nat_node_a1-peddler_a2 vs nat_node_a2-peddler_a1 | 51.5 m vs 49.5 m (3.9 %) |
| F2 | nat_node_b1-post_s_a1 vs nat_node_b2-post_s_a2 | 115.3 m vs 120.0 m (3.9 %) |
| F2 | home_a_a1-home_b_b1 vs home_a_b2-home_b_a2 | 150.1 m vs 156.2 m (3.9 %) |
| F2 | nat_node_b1-cache_b_a1 vs nat_node_b2-cache_b_a2 | 75.9 m vs 78.9 m (3.9 %) |
| F2 | keep_t0-x_bridge_s vs keep_t1-x_bridge_n | 77.7 m vs 74.7 m (3.9 %) |
| F2 | keep_t1-x_bridge_n vs keep_t4-x_bridge_s | 74.7 m vs 77.7 m (3.9 %) |
| F2 | home_b_a1-post_w_b1 vs home_b_b1-post_w_a1 | 173.3 m vs 180.3 m (3.9 %) |
| F2 | home_b_b1-post_w_a1 vs home_b_b2-post_w_a2 | 180.3 m vs 173.3 m (3.9 %) |
| F2 | third_node_a1-stag_a2 vs third_node_a2-stag_a1 | 147.0 m vs 152.9 m (3.9 %) |
| F2 | third_node_a2-stag_a1 vs third_node_b2-stag_b1 | 152.9 m vs 147.0 m (3.9 %) |
| F2 | stag_a2-inn_a1 vs stag_b1-inn_b2 | 100.4 m vs 96.5 m (3.9 %) |
| F2 | guilds_den_b1-lairs_two_b2 vs guilds_den_b2-lairs_two_b1 | 165.1 m vs 171.7 m (3.9 %) |
| F2 | guilds_den_a1-lairs_two_a2 vs guilds_den_b1-lairs_two_b2 | 171.7 m vs 165.1 m (3.9 %) |
| F2 | post_w_a1-guilds_den_b1 vs post_w_b2-guilds_den_a2 | 186.1 m vs 193.6 m (3.9 %) |
| F2 | nat_node_b1-peddler_b2 vs nat_node_b2-peddler_b1 | 49.5 m vs 51.5 m (3.9 %) |
| F2 | nat_node_a2-peddler_a1 vs nat_node_b2-peddler_b1 | 49.5 m vs 51.5 m (3.9 %) |
| F2 | post_s_b1-lairs_two_a2 vs post_s_b2-lairs_two_a1 | 76.2 m vs 73.2 m (3.8 %) |
| F2 | lairs_one_b1-lairs_two_a1 vs lairs_one_b2-lairs_two_a2 | 217.9 m vs 209.5 m (3.8 %) |
| F2 | lairs_one_a1-lairs_two_b1 vs lairs_one_b1-lairs_two_a1 | 209.5 m vs 217.9 m (3.8 %) |
| F2 | home_b_b1-cache_b_a1 vs home_b_b2-cache_b_a2 | 116.6 m vs 112.1 m (3.8 %) |
| F2 | third_node_a1-stag_a2 vs third_node_b1-stag_b2 | 147.0 m vs 152.8 m (3.8 %) |
| F2 | third_node_b1-stag_b2 vs third_node_b2-stag_b1 | 152.8 m vs 147.0 m (3.8 %) |
| F2 | tower_r_b1-lairs_one_a2 vs tower_r_b2-lairs_one_a1 | 85.3 m vs 82.0 m (3.8 %) |
| F2 | tower_r_a1-lairs_one_b2 vs tower_r_b1-lairs_one_a2 | 82.0 m vs 85.3 m (3.8 %) |
| F2 | rich_node_a1-shrine_a2 vs rich_node_a2-shrine_a1 | 73.5 m vs 76.5 m (3.8 %) |
| F2 | home_b_a1-cache_b_b1 vs home_b_a2-cache_b_b2 | 112.2 m vs 116.7 m (3.8 %) |
| F2 | shrine_a1-ford_nest_a1 vs shrine_b2-ford_nest_a1 | 59.5 m vs 57.3 m (3.8 %) |
| F2 | shrine_a1-x_ford_s vs shrine_b2-x_ford_s | 59.5 m vs 57.3 m (3.8 %) |
| F2 | cache_a_a1-lairs_one_b1 vs cache_a_b1-lairs_one_a1 | 190.3 m vs 197.8 m (3.8 %) |
| F2 | cache_a_b1-lairs_one_a1 vs cache_a_b2-lairs_one_a2 | 197.8 m vs 190.3 m (3.8 %) |
| F2 | post_s_a1-guilds_lodge_b2 vs post_s_b1-guilds_lodge_a2 | 108.0 m vs 112.2 m (3.8 %) |
| F2 | nat_node_a2-lairs_two_b2 vs nat_node_b1-lairs_two_a1 | 137.6 m vs 132.3 m (3.8 %) |
| F2 | third_node_a1-inn_b1 vs third_node_b1-inn_a1 | 141.1 m vs 146.7 m (3.8 %) |
| F2 | third_node_b1-inn_a1 vs third_node_b2-inn_a2 | 146.7 m vs 141.1 m (3.8 %) |
| F2 | guilds_den_a2-lairs_one_b2 vs guilds_den_b1-lairs_one_a1 | 222.7 m vs 231.5 m (3.8 %) |
| F2 | keep_t3-tower_r_b1 vs keep_t1-tower_r_a2 | 93.6 m vs 90.0 m (3.8 %) |
| F2 | rich_node_a2-post_w_b1 vs rich_node_b1-post_w_a2 | 113.1 m vs 108.8 m (3.8 %) |
| F2 | nat_node_b1-lairs_two_a1 vs nat_node_b2-lairs_two_a2 | 132.3 m vs 137.5 m (3.8 %) |
| F2 | inn_a2-guilds_lodge_b1 vs inn_b1-guilds_lodge_a2 | 128.7 m vs 123.8 m (3.8 %) |
| F2 | post_s_a2-guilds_lodge_a2 vs post_s_b2-guilds_lodge_b2 | 63.0 m vs 65.5 m (3.8 %) |
| F2 | post_s_b1-guilds_lodge_b1 vs post_s_b2-guilds_lodge_b2 | 63.0 m vs 65.5 m (3.8 %) |
| F2 | post_s_a1-guilds_lodge_a1 vs post_s_a2-guilds_lodge_a2 | 65.5 m vs 63.0 m (3.8 %) |
| F2 | post_s_a1-guilds_lodge_a1 vs post_s_b1-guilds_lodge_b1 | 65.5 m vs 63.0 m (3.8 %) |
| F2 | post_s_b1-guilds_lodge_a2 vs post_s_b2-guilds_lodge_a1 | 112.2 m vs 108.0 m (3.8 %) |
| F2 | home_b_a2-rich_node_b2 vs home_b_b2-rich_node_a2 | 129.8 m vs 124.9 m (3.8 %) |
| F2 | tower_r_b1-post_s_b2 vs tower_r_b2-post_s_b1 | 144.0 m vs 149.6 m (3.8 %) |
| F2 | well_a1-well_a2 vs well_b2-well_b1 | 107.4 m vs 103.3 m (3.8 %) |
| F2 | home_b_a1-cache_b_b1 vs home_b_b1-cache_b_a1 | 112.2 m vs 116.6 m (3.8 %) |
| F2 | post_s_a2-cache_b_b2 vs post_s_b1-cache_b_a1 | 118.4 m vs 114.0 m (3.8 %) |
| F2 | shrine_b1-guilds_den_a2 vs shrine_b2-guilds_den_a1 | 151.5 m vs 145.8 m (3.8 %) |
| F2 | guilds_lodge_b1-peddler_a1 vs guilds_lodge_b2-peddler_a2 | 186.4 m vs 193.6 m (3.8 %) |
| F2 | post_w_a2-cache_a_b1 vs post_w_b1-cache_a_a2 | 147.8 m vs 142.3 m (3.8 %) |
| F2 | third_node_a1-well_a2 vs third_node_a2-well_a1 | 119.6 m vs 124.3 m (3.7 %) |
| F2 | third_node_a2-well_a1 vs third_node_b2-well_b1 | 124.3 m vs 119.6 m (3.7 %) |
| F2 | guilds_lodge_a2-peddler_b2 vs guilds_lodge_b2-peddler_a2 | 186.4 m vs 193.6 m (3.7 %) |
| F2 | home_b_b1-rich_node_a1 vs home_b_b2-rich_node_a2 | 129.7 m vs 124.9 m (3.7 %) |
| F2 | tower_r_b1-wallow_b2 vs tower_r_b2-wallow_b1 | 137.3 m vs 132.2 m (3.7 %) |
| F2 | tower_r_a1-wallow_a2 vs tower_r_b1-wallow_b2 | 132.2 m vs 137.3 m (3.7 %) |
| F2 | well_a1-peddler_b1 vs well_b1-peddler_a1 | 136.3 m vs 131.3 m (3.7 %) |
| F2 | well_b1-peddler_a1 vs well_b2-peddler_a2 | 131.3 m vs 136.3 m (3.7 %) |
| F2 | home_b_a1-rich_node_b1 vs home_b_a2-rich_node_b2 | 125.0 m vs 129.8 m (3.7 %) |
| F2 | third_node_a1-well_a2 vs third_node_b1-well_b2 | 119.6 m vs 124.2 m (3.7 %) |
| F2 | third_node_b1-well_b2 vs third_node_b2-well_b1 | 124.2 m vs 119.6 m (3.7 %) |
| F2 | third_node_a1-cache_b_b2 vs third_node_b1-cache_b_a2 | 102.9 m vs 99.1 m (3.7 %) |
| F2 | well_a1-peddler_b1 vs well_a2-peddler_b2 | 136.3 m vs 131.3 m (3.7 %) |
| F2 | well_a2-peddler_b2 vs well_b2-peddler_a2 | 131.3 m vs 136.3 m (3.7 %) |
| F2 | nat_node_a1-post_w_a2 vs nat_node_a2-post_w_a1 | 60.0 m vs 57.8 m (3.7 %) |
| F2 | nat_node_a2-post_w_a1 vs nat_node_b2-post_w_b1 | 57.8 m vs 60.0 m (3.7 %) |
| F2 | third_node_a1-well_b1 vs third_node_b1-well_a1 | 169.7 m vs 176.3 m (3.7 %) |
| F2 | third_node_b1-well_a1 vs third_node_b2-well_a2 | 176.3 m vs 169.7 m (3.7 %) |
| F2 | nat_node_b1-lairs_two_a2 vs nat_node_b2-lairs_two_a1 | 109.4 m vs 105.4 m (3.7 %) |
| F2 | nat_node_a1-lairs_two_b2 vs nat_node_b1-lairs_two_a2 | 105.4 m vs 109.4 m (3.7 %) |
| F2 | nat_node_a1-post_w_a2 vs nat_node_b1-post_w_b2 | 60.0 m vs 57.8 m (3.7 %) |
| F2 | nat_node_b1-post_w_b2 vs nat_node_b2-post_w_b1 | 57.8 m vs 60.0 m (3.7 %) |
| F2 | home_b_a1-rich_node_b1 vs home_b_b1-rich_node_a1 | 125.0 m vs 129.7 m (3.7 %) |
| F2 | keep_t0-tower_r_b2 vs keep_t1-tower_r_a2 | 93.5 m vs 90.0 m (3.7 %) |
| F2 | keep_t1-tower_r_a2 vs keep_t4-tower_r_a1 | 90.0 m vs 93.5 m (3.7 %) |
| F2 | post_w_a1-post_s_b1 vs post_w_b2-post_s_a2 | 147.8 m vs 142.4 m (3.7 %) |
| F2 | home_a_a2-lairs_two_b1 vs home_a_b1-lairs_two_a2 | 144.3 m vs 139.0 m (3.7 %) |
| F2 | third_node_a2-lairs_one_b1 vs third_node_b2-lairs_one_a1 | 150.2 m vs 144.7 m (3.7 %) |
| F2 | third_node_a1-lairs_one_b2 vs third_node_a2-lairs_one_b1 | 144.7 m vs 150.2 m (3.7 %) |
| F2 | guilds_den_a1-cache_b_b1 vs guilds_den_b1-cache_b_a1 | 155.9 m vs 161.8 m (3.6 %) |
| F2 | home_b_a2-lairs_one_b1 vs home_b_b2-lairs_one_a1 | 143.0 m vs 137.8 m (3.6 %) |
| F2 | home_b_a1-lairs_one_b2 vs home_b_a2-lairs_one_b1 | 137.8 m vs 143.0 m (3.6 %) |
| F2 | rich_node_a1-post_s_b1 vs rich_node_b2-post_s_a2 | 144.6 m vs 150.1 m (3.6 %) |
| F2 | guilds_den_a2-peddler_b1 vs guilds_den_b1-peddler_a2 | 163.4 m vs 169.5 m (3.6 %) |
| F2 | post_s_a1-lairs_one_b2 vs post_s_b1-lairs_one_a2 | 90.7 m vs 94.1 m (3.6 %) |
| F2 | third_node_b1-cache_b_a2 vs third_node_b2-cache_b_a1 | 99.1 m vs 102.8 m (3.6 %) |
| F2 | stag_a1-inn_a2 vs stag_a2-inn_a1 | 96.7 m vs 100.4 m (3.6 %) |
| F2 | stag_a2-inn_a1 vs stag_b2-inn_b1 | 100.4 m vs 96.7 m (3.6 %) |
| F2 | cache_a_a1-lairs_one_a2 vs cache_a_b1-lairs_one_b2 | 145.7 m vs 151.2 m (3.6 %) |
| F2 | cache_a_a1-lairs_one_a2 vs cache_a_a2-lairs_one_a1 | 145.7 m vs 151.2 m (3.6 %) |
| F2 | cache_a_a2-lairs_one_a1 vs cache_a_b2-lairs_one_b1 | 151.2 m vs 145.7 m (3.6 %) |
| F2 | cache_a_b1-lairs_one_b2 vs cache_a_b2-lairs_one_b1 | 151.2 m vs 145.7 m (3.6 %) |
| F2 | third_node_a1-cache_b_b2 vs third_node_a2-cache_b_b1 | 102.9 m vs 99.2 m (3.6 %) |
| F2 | home_a_a1-x_ford_s vs home_a_b1-x_ford_n | 76.2 m vs 73.4 m (3.6 %) |
| F2 | home_a_b1-x_ford_n vs home_a_b2-x_ford_s | 73.4 m vs 76.2 m (3.6 %) |
| F2 | home_a_a1-ford_nest_a1 vs home_a_b1-ford_nest_a2 | 76.2 m vs 73.4 m (3.6 %) |
| F2 | home_a_b1-ford_nest_a2 vs home_a_b2-ford_nest_a1 | 73.4 m vs 76.2 m (3.6 %) |
| F2 | home_a_a1-x_ford_s vs home_a_a2-x_ford_n | 76.2 m vs 73.4 m (3.6 %) |
| F2 | home_a_a2-x_ford_n vs home_a_b2-x_ford_s | 73.4 m vs 76.2 m (3.6 %) |
| F2 | home_a_a2-ford_nest_a2 vs home_a_b2-ford_nest_a1 | 73.4 m vs 76.2 m (3.6 %) |
| F2 | home_a_a1-ford_nest_a1 vs home_a_a2-ford_nest_a2 | 76.2 m vs 73.4 m (3.6 %) |
| F2 | third_node_a2-tower_r_b2 vs third_node_b2-tower_r_a2 | 173.4 m vs 167.1 m (3.6 %) |
| F2 | nat_node_a2-guilds_lodge_b1 vs nat_node_b1-guilds_lodge_a2 | 136.3 m vs 131.4 m (3.6 %) |
| F2 | wallow_a1-cache_b_b2 vs wallow_b1-cache_b_a2 | 95.4 m vs 92.0 m (3.6 %) |
| F2 | peddler_a2-cache_b_b2 vs peddler_b2-cache_b_a2 | 101.2 m vs 97.6 m (3.6 %) |
| F2 | post_s_b1-lairs_one_a2 vs post_s_b2-lairs_one_a1 | 94.1 m vs 90.7 m (3.6 %) |
| F2 | lairs_one_a1-lairs_one_b2 vs lairs_one_a2-lairs_one_b1 | 138.8 m vs 144.0 m (3.6 %) |
| F2 | home_a_a1-third_node_b2 vs home_a_a2-third_node_b1 | 158.7 m vs 164.6 m (3.6 %) |
| F2 | home_a_a2-third_node_b1 vs home_a_b2-third_node_a1 | 164.6 m vs 158.7 m (3.6 %) |
| F2 | home_a_a2-post_s_b1 vs home_a_b1-post_s_a2 | 111.5 m vs 107.5 m (3.6 %) |
| F2 | inn_a1-post_s_b1 vs inn_b2-post_s_a2 | 120.3 m vs 124.8 m (3.6 %) |
| F2 | inn_a1-peddler_a2 vs inn_b1-peddler_b2 | 59.3 m vs 57.1 m (3.6 %) |
| F2 | inn_a1-peddler_a2 vs inn_a2-peddler_a1 | 59.3 m vs 57.1 m (3.6 %) |
| F2 | third_node_b1-tower_r_a1 vs third_node_b2-tower_r_a2 | 173.3 m vs 167.1 m (3.6 %) |
| F2 | peddler_b1-cache_b_a1 vs peddler_b2-cache_b_a2 | 101.2 m vs 97.6 m (3.6 %) |
| F2 | keep_t3-guilds_den_b2 vs keep_t4-guilds_den_a2 | 190.6 m vs 197.6 m (3.6 %) |
| F2 | guilds_den_a1-lairs_two_a2 vs guilds_den_a2-lairs_two_a1 | 171.7 m vs 165.6 m (3.6 %) |
| F2 | guilds_den_a2-lairs_two_a1 vs guilds_den_b2-lairs_two_b1 | 165.6 m vs 171.7 m (3.6 %) |
| F2 | keep_t1-guilds_den_a1 vs keep_t4-guilds_den_a2 | 190.6 m vs 197.6 m (3.6 %) |
| F2 | third_node_a2-post_s_a1 vs third_node_b2-post_s_b1 | 162.5 m vs 156.8 m (3.5 %) |
| F2 | third_node_a1-post_s_a2 vs third_node_a2-post_s_a1 | 156.8 m vs 162.5 m (3.5 %) |
| F2 | inn_b1-peddler_b2 vs inn_b2-peddler_b1 | 57.1 m vs 59.2 m (3.5 %) |
| F2 | inn_a2-peddler_a1 vs inn_b2-peddler_b1 | 57.1 m vs 59.2 m (3.5 %) |
| F2 | third_node_a2-cache_b_b1 vs third_node_b2-cache_b_a1 | 99.2 m vs 102.8 m (3.5 %) |
| F2 | tower_r_a2-tower_c_b2 vs tower_r_b2-tower_c_a2 | 90.3 m vs 93.6 m (3.5 %) |
| F2 | tower_r_a2-x_lane_w vs tower_r_b1-x_lane_e | 66.9 m vs 64.6 m (3.5 %) |
| F2 | cache_b_a2-lairs_one_a2 vs cache_b_b1-lairs_one_b1 | 84.1 m vs 81.2 m (3.5 %) |
| F2 | third_node_a1-tower_r_a2 vs third_node_a2-tower_r_a1 | 143.8 m vs 149.0 m (3.5 %) |
| F2 | peddler_a1-cache_b_b1 vs peddler_a2-cache_b_b2 | 97.6 m vs 101.2 m (3.5 %) |
| F2 | third_node_b1-post_s_b2 vs third_node_b2-post_s_b1 | 162.5 m vs 156.8 m (3.5 %) |
| F2 | third_node_a1-post_s_a2 vs third_node_b1-post_s_b2 | 156.8 m vs 162.5 m (3.5 %) |
| F2 | tower_r_a2-x_lane_w vs tower_r_b2-x_lane_e | 66.9 m vs 64.6 m (3.5 %) |
| F2 | tower_r_a1-x_lane_w vs tower_r_a2-x_lane_w | 64.6 m vs 66.9 m (3.5 %) |
| F2 | wallow_b1-cache_b_a2 vs wallow_b2-cache_b_a1 | 92.0 m vs 95.3 m (3.5 %) |
| F2 | third_node_a1-tower_r_a2 vs third_node_b1-tower_r_b2 | 143.8 m vs 149.0 m (3.5 %) |
| F2 | nat_node_a2-rich_node_b2 vs nat_node_b1-rich_node_a1 | 85.7 m vs 88.8 m (3.5 %) |
| F2 | third_node_a1-guilds_lodge_b2 vs third_node_a2-guilds_lodge_b1 | 161.8 m vs 167.6 m (3.5 %) |
| F2 | third_node_a2-guilds_lodge_b1 vs third_node_b2-guilds_lodge_a1 | 167.6 m vs 161.8 m (3.5 %) |
| F2 | home_b_b1-guilds_den_a1 vs home_b_b2-guilds_den_a2 | 195.5 m vs 202.6 m (3.5 %) |
| F2 | home_b_a2-guilds_den_b2 vs home_b_b2-guilds_den_a2 | 195.5 m vs 202.6 m (3.5 %) |
| F2 | wallow_a1-cache_b_b2 vs wallow_a2-cache_b_b1 | 95.4 m vs 92.1 m (3.5 %) |
| F2 | keep_t3-lairs_one_b1 vs keep_t4-lairs_one_a1 | 149.8 m vs 144.5 m (3.5 %) |
| F2 | shrine_a1-guilds_den_b1 vs shrine_a2-guilds_den_b2 | 163.3 m vs 157.6 m (3.5 %) |
| F2 | keep_t0-lairs_one_b2 vs keep_t3-lairs_one_b1 | 144.5 m vs 149.8 m (3.5 %) |
| F2 | rich_node_a2-wallow_b1 vs rich_node_b1-wallow_a2 | 97.2 m vs 100.8 m (3.5 %) |
| F2 | well_a1-wallow_b2 vs well_a2-wallow_b1 | 120.7 m vs 125.1 m (3.5 %) |
| F2 | home_b_a2-guilds_lodge_b1 vs home_b_b2-guilds_lodge_a1 | 160.5 m vs 154.9 m (3.5 %) |
| F2 | home_b_a1-guilds_lodge_b2 vs home_b_a2-guilds_lodge_b1 | 154.9 m vs 160.5 m (3.5 %) |
| F2 | peddler_a1-cache_b_b1 vs peddler_b1-cache_b_a1 | 97.6 m vs 101.2 m (3.5 %) |
| F2 | shrine_a1-guilds_den_b1 vs shrine_b1-guilds_den_a1 | 163.3 m vs 157.6 m (3.5 %) |
| F2 | wallow_a1-ford_nest_a2 vs wallow_a2-ford_nest_a1 | 117.2 m vs 121.4 m (3.5 %) |
| F2 | wallow_a2-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 121.4 m vs 117.2 m (3.5 %) |
| F2 | wallow_a2-x_ford_s vs wallow_b2-x_ford_n | 121.4 m vs 117.2 m (3.5 %) |
| F2 | wallow_a1-x_ford_n vs wallow_a2-x_ford_s | 117.2 m vs 121.4 m (3.5 %) |
| F2 | well_a2-wallow_b1 vs well_b2-wallow_a1 | 125.1 m vs 120.7 m (3.5 %) |
| F2 | wallow_b1-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 121.4 m vs 117.2 m (3.5 %) |
| F2 | wallow_b1-x_ford_s vs wallow_b2-x_ford_n | 121.4 m vs 117.2 m (3.5 %) |
| F2 | wallow_a1-x_ford_n vs wallow_b1-x_ford_s | 117.2 m vs 121.4 m (3.5 %) |
| F2 | wallow_a1-ford_nest_a2 vs wallow_b1-ford_nest_a1 | 117.2 m vs 121.4 m (3.5 %) |
| F2 | post_w_a2-lairs_two_b1 vs post_w_b1-lairs_two_a2 | 158.6 m vs 153.1 m (3.5 %) |
| F2 | keep_t3-cache_b_b2 vs keep_t4-cache_b_a2 | 111.7 m vs 107.9 m (3.5 %) |
| F2 | keep_t0-rich_node_b2 vs keep_t1-rich_node_a2 | 95.5 m vs 92.2 m (3.4 %) |
| F2 | nat_node_a1-rich_node_a1 vs nat_node_b1-rich_node_b1 | 40.3 m vs 41.7 m (3.4 %) |
| F2 | nat_node_a2-rich_node_a2 vs nat_node_b1-rich_node_b1 | 40.3 m vs 41.7 m (3.4 %) |
| F2 | nat_node_b1-rich_node_b1 vs nat_node_b2-rich_node_b2 | 41.7 m vs 40.3 m (3.4 %) |
| F2 | rich_node_a1-shrine_b1 vs rich_node_a2-shrine_b2 | 91.9 m vs 95.1 m (3.4 %) |
| F2 | shrine_a1-cache_b_b2 vs shrine_b1-cache_b_a2 | 69.0 m vs 66.6 m (3.4 %) |
| F2 | shrine_a2-guilds_lodge_b1 vs shrine_b2-guilds_lodge_a1 | 154.2 m vs 148.9 m (3.4 %) |
| F2 | inn_a1-cache_b_b2 vs inn_b1-cache_b_a2 | 42.7 m vs 41.2 m (3.4 %) |
| F2 | well_a2-wallow_b1 vs well_b1-wallow_a2 | 125.1 m vs 120.8 m (3.4 %) |
| F2 | home_b_a1-tower_r_b1 vs home_b_a2-tower_r_b2 | 136.1 m vs 141.0 m (3.4 %) |
| F2 | third_node_a2-lairs_one_b1 vs third_node_b1-lairs_one_a2 | 150.2 m vs 145.1 m (3.4 %) |
| F2 | home_a_a1-post_s_b2 vs home_a_b1-post_s_a2 | 111.3 m vs 107.5 m (3.4 %) |
| F2 | third_node_a2-inn_b2 vs third_node_b1-inn_a1 | 141.7 m vs 146.7 m (3.4 %) |
| F2 | keep_t1-cache_b_a1 vs keep_t4-cache_b_a2 | 111.7 m vs 107.9 m (3.4 %) |
| F2 | well_a2-peddler_b1 vs well_b1-peddler_a2 | 115.3 m vs 111.4 m (3.4 %) |
| F2 | rich_node_a2-shrine_b2 vs rich_node_b2-shrine_a2 | 95.1 m vs 91.9 m (3.4 %) |
| F2 | nat_node_a2-third_node_b2 vs nat_node_b1-third_node_a1 | 143.7 m vs 148.8 m (3.4 %) |
| F2 | tower_r_a2-post_s_a1 vs tower_r_b2-post_s_b1 | 144.5 m vs 149.6 m (3.4 %) |
| F2 | tower_r_a1-post_s_a2 vs tower_r_b2-post_s_b1 | 144.5 m vs 149.6 m (3.4 %) |
| F2 | stag_b1-guilds_lodge_a2 vs stag_b2-guilds_lodge_a1 | 123.2 m vs 119.0 m (3.4 %) |
| F2 | stag_a1-guilds_lodge_b2 vs stag_b1-guilds_lodge_a2 | 119.0 m vs 123.2 m (3.4 %) |
| F2 | wallow_a2-cache_b_b1 vs wallow_b2-cache_b_a1 | 92.1 m vs 95.3 m (3.4 %) |
| F2 | lairs_two_a1-lairs_two_b1 vs lairs_two_b2-lairs_two_a2 | 197.0 m vs 190.3 m (3.4 %) |
| F2 | shrine_b1-lairs_one_a2 vs shrine_b2-lairs_one_a1 | 141.3 m vs 136.5 m (3.4 %) |
| F2 | keep_t1-rich_node_a2 vs keep_t4-rich_node_a1 | 92.2 m vs 95.5 m (3.4 %) |
| F2 | guilds_lodge_b1-peddler_a2 vs guilds_lodge_b2-peddler_a1 | 168.1 m vs 162.4 m (3.4 %) |
| F2 | inn_a2-post_w_a1 vs inn_b2-post_w_b1 | 65.5 m vs 67.8 m (3.4 %) |
| F2 | inn_a1-post_w_a2 vs inn_a2-post_w_a1 | 67.8 m vs 65.5 m (3.4 %) |
| F2 | keep_t0-cache_b_b1 vs keep_t3-cache_b_b2 | 107.9 m vs 111.7 m (3.4 %) |
| F2 | home_a_b1-post_s_a2 vs home_a_b2-post_s_a1 | 107.5 m vs 111.2 m (3.4 %) |
| F2 | keep_t3-rich_node_b2 vs keep_t4-rich_node_a2 | 124.9 m vs 120.6 m (3.4 %) |
| F2 | tower_r_b1-guilds_den_a2 vs tower_r_b2-guilds_den_a1 | 95.5 m vs 92.2 m (3.4 %) |
| F2 | tower_r_a1-guilds_den_b2 vs tower_r_b1-guilds_den_a2 | 92.2 m vs 95.5 m (3.4 %) |
| F2 | guilds_lodge_a1-peddler_b2 vs guilds_lodge_b1-peddler_a2 | 162.5 m vs 168.1 m (3.4 %) |
| F2 | inn_a1-post_w_a2 vs inn_b1-post_w_b2 | 67.8 m vs 65.5 m (3.4 %) |
| F2 | inn_b1-post_w_b2 vs inn_b2-post_w_b1 | 65.5 m vs 67.8 m (3.4 %) |
| F2 | peddler_a2-lairs_one_b2 vs peddler_b2-lairs_one_a2 | 170.8 m vs 176.8 m (3.4 %) |
| F2 | third_node_a2-guilds_den_b1 vs third_node_b2-guilds_den_a1 | 160.3 m vs 154.9 m (3.4 %) |
| F2 | peddler_b1-lairs_one_a1 vs peddler_b2-lairs_one_a2 | 170.8 m vs 176.8 m (3.4 %) |
| F2 | third_node_a1-guilds_den_b2 vs third_node_a2-guilds_den_b1 | 154.9 m vs 160.3 m (3.4 %) |
| F2 | guilds_den_a2-lairs_one_b1 vs guilds_den_b2-lairs_one_a1 | 154.1 m vs 148.9 m (3.4 %) |
| F2 | guilds_den_a1-lairs_one_b2 vs guilds_den_a2-lairs_one_b1 | 148.9 m vs 154.1 m (3.4 %) |
| F2 | rich_node_a2-wallow_b1 vs rich_node_b2-wallow_a1 | 97.2 m vs 100.6 m (3.4 %) |
| F2 | third_node_a1-cache_a_b1 vs third_node_b1-cache_a_a1 | 185.8 m vs 192.3 m (3.4 %) |
| F2 | third_node_b1-cache_a_a1 vs third_node_b2-cache_a_a2 | 192.3 m vs 185.8 m (3.4 %) |
| F2 | keep_t0-rich_node_b2 vs keep_t3-rich_node_b1 | 95.5 m vs 92.3 m (3.4 %) |
| F2 | home_b_a1-tower_r_b1 vs home_b_b1-tower_r_a1 | 136.1 m vs 140.9 m (3.3 %) |
| F2 | keep_t1-rich_node_a1 vs keep_t4-rich_node_a2 | 124.8 m vs 120.6 m (3.3 %) |
| F2 | tower_c_a1-post_s_a1 vs tower_c_b1-post_s_b1 | 72.0 m vs 74.5 m (3.3 %) |
| F2 | tower_c_b1-post_s_b1 vs tower_c_b2-post_s_b2 | 74.5 m vs 72.0 m (3.3 %) |
| F2 | keep_t0-cache_b_b1 vs keep_t1-cache_b_a1 | 107.9 m vs 111.7 m (3.3 %) |
| F2 | home_b_a2-guilds_den_b1 vs home_b_b2-guilds_den_a1 | 153.1 m vs 148.0 m (3.3 %) |
| F2 | home_b_a1-guilds_den_b2 vs home_b_a2-guilds_den_b1 | 148.0 m vs 153.1 m (3.3 %) |
| F2 | guilds_den_a2-lairs_one_b1 vs guilds_den_b1-lairs_one_a2 | 154.1 m vs 148.9 m (3.3 %) |
| F2 | keep_t3-inn_a1 vs keep_t4-inn_b1 | 69.8 m vs 67.5 m (3.3 %) |
| F2 | keep_t0-inn_a2 vs keep_t3-inn_a1 | 67.5 m vs 69.8 m (3.3 %) |
| F2 | home_b_a1-lairs_two_b1 vs home_b_a2-lairs_two_b2 | 167.4 m vs 173.2 m (3.3 %) |
| F2 | keep_t0-rich_node_b1 vs keep_t3-rich_node_b2 | 120.7 m vs 124.9 m (3.3 %) |
| F2 | shrine_a1-cache_b_b2 vs shrine_a2-cache_b_b1 | 69.0 m vs 66.7 m (3.3 %) |
| F2 | cache_a_a1-lairs_two_b1 vs cache_a_b1-lairs_two_a1 | 183.3 m vs 189.6 m (3.3 %) |
| F2 | shrine_a1-cache_a_b1 vs shrine_a2-cache_a_b2 | 128.4 m vs 124.1 m (3.3 %) |
| F2 | home_b_a1-lairs_two_b1 vs home_b_b1-lairs_two_a1 | 167.4 m vs 173.2 m (3.3 %) |
| F2 | shrine_a2-cache_a_b2 vs shrine_b2-cache_a_a2 | 124.1 m vs 128.4 m (3.3 %) |
| F2 | post_w_a2-post_s_b1 vs post_w_b1-post_s_a2 | 125.8 m vs 121.6 m (3.3 %) |
| F2 | third_node_a1-lairs_one_b1 vs third_node_b2-lairs_one_a2 | 215.7 m vs 208.6 m (3.3 %) |
| F2 | stag_b1-lairs_two_a2 vs stag_b2-lairs_two_a1 | 87.1 m vs 84.2 m (3.3 %) |
| F2 | keep_t1-inn_b2 vs keep_t4-inn_b1 | 69.8 m vs 67.5 m (3.3 %) |
| F2 | keep_t0-inn_a2 vs keep_t1-inn_b2 | 67.5 m vs 69.8 m (3.3 %) |
| F2 | shrine_a1-cache_a_b1 vs shrine_b1-cache_a_a1 | 128.4 m vs 124.1 m (3.3 %) |
| F2 | stag_a1-lairs_two_b2 vs stag_b1-lairs_two_a2 | 84.2 m vs 87.1 m (3.3 %) |
| F2 | home_a_a2-guilds_den_b2 vs home_a_b2-guilds_den_a2 | 183.7 m vs 190.0 m (3.3 %) |
| F2 | keep_t3-rich_node_b1 vs keep_t4-rich_node_a1 | 92.3 m vs 95.5 m (3.3 %) |
| F2 | shrine_a1-stag_b1 vs shrine_b1-stag_a1 | 125.5 m vs 121.3 m (3.3 %) |
| F2 | well_a1-lairs_two_b2 vs well_b1-lairs_two_a2 | 94.7 m vs 91.6 m (3.3 %) |
| F2 | shrine_b1-cache_a_a1 vs shrine_b2-cache_a_a2 | 124.1 m vs 128.4 m (3.3 %) |
| F2 | well_b1-lairs_two_a2 vs well_b2-lairs_two_a1 | 91.6 m vs 94.7 m (3.3 %) |
| F2 | home_a_a1-cache_a_b2 vs home_a_b1-cache_a_a2 | 132.5 m vs 128.1 m (3.3 %) |
| F2 | keep_t0-rich_node_b1 vs keep_t1-rich_node_a1 | 120.7 m vs 124.8 m (3.3 %) |
| F2 | home_a_b1-guilds_den_a1 vs home_a_b2-guilds_den_a2 | 183.8 m vs 190.0 m (3.3 %) |
| F2 | shrine_a1-stag_b1 vs shrine_a2-stag_b2 | 125.5 m vs 121.4 m (3.3 %) |
| F2 | lairs_one_b1-lairs_two_b2 vs lairs_one_b2-lairs_two_b1 | 162.0 m vs 167.5 m (3.3 %) |
| F2 | lairs_one_a1-lairs_two_a2 vs lairs_one_b1-lairs_two_b2 | 167.5 m vs 162.0 m (3.3 %) |
| F2 | peddler_a1-cache_b_b2 vs peddler_b1-cache_b_a2 | 78.5 m vs 75.9 m (3.3 %) |
| F2 | inn_b1-cache_b_a2 vs inn_b2-cache_b_a1 | 41.2 m vs 42.6 m (3.3 %) |
| F2 | lairs_one_a2-lairs_two_a1 vs lairs_one_b2-lairs_two_b1 | 162.0 m vs 167.5 m (3.3 %) |
| F2 | lairs_one_a1-lairs_two_a2 vs lairs_one_a2-lairs_two_a1 | 167.5 m vs 162.0 m (3.3 %) |
| F2 | rich_node_a1-wallow_b2 vs rich_node_a2-wallow_b1 | 100.5 m vs 97.2 m (3.3 %) |
| F2 | rich_node_a1-third_node_b1 vs rich_node_a2-third_node_b2 | 148.0 m vs 152.9 m (3.3 %) |
| F2 | home_b_a1-home_b_b2 vs home_b_a2-home_b_b1 | 134.8 m vs 139.3 m (3.3 %) |
| F2 | third_node_b1-cache_b_b1 vs third_node_b2-cache_b_b2 | 81.2 m vs 83.9 m (3.3 %) |
| F2 | third_node_a2-cache_b_a2 vs third_node_b2-cache_b_b2 | 81.2 m vs 83.9 m (3.3 %) |
| F2 | third_node_a1-cache_b_a1 vs third_node_b1-cache_b_b1 | 83.9 m vs 81.2 m (3.3 %) |
| F2 | third_node_a1-cache_b_a1 vs third_node_a2-cache_b_a2 | 83.9 m vs 81.2 m (3.3 %) |
| F2 | wallow_a2-stag_a1 vs wallow_b1-stag_b2 | 130.3 m vs 134.6 m (3.3 %) |
| F2 | home_b_a1-cache_b_b2 vs home_b_b1-cache_b_a2 | 81.2 m vs 78.6 m (3.3 %) |
| F2 | shrine_a2-lairs_one_b1 vs shrine_b1-lairs_one_a2 | 136.7 m vs 141.3 m (3.3 %) |
| F2 | keep_t3-lairs_one_b2 vs keep_t4-lairs_one_a2 | 181.4 m vs 187.4 m (3.2 %) |
| F2 | keep_t1-lairs_one_a1 vs keep_t4-lairs_one_a2 | 181.4 m vs 187.4 m (3.2 %) |
| F2 | tower_r_a2-inn_a2 vs tower_r_b1-inn_b1 | 43.9 m vs 45.3 m (3.2 %) |
| F2 | tower_r_b1-inn_b1 vs tower_r_b2-inn_b2 | 45.3 m vs 43.9 m (3.2 %) |
| F2 | tower_r_a1-inn_a1 vs tower_r_b1-inn_b1 | 43.9 m vs 45.3 m (3.2 %) |
| F2 | tower_r_a2-post_s_b2 vs tower_r_b2-post_s_a2 | 162.3 m vs 167.7 m (3.2 %) |
| F2 | inn_a1-cache_b_b2 vs inn_a2-cache_b_b1 | 42.7 m vs 41.3 m (3.2 %) |
| F2 | nat_node_a1-rich_node_b1 vs nat_node_b1-rich_node_a1 | 91.8 m vs 88.8 m (3.2 %) |
| F2 | guilds_den_a1-guilds_lodge_b2 vs guilds_den_a2-guilds_lodge_b1 | 166.0 m vs 171.5 m (3.2 %) |
| F2 | guilds_den_a2-guilds_lodge_b1 vs guilds_den_b2-guilds_lodge_a1 | 171.5 m vs 166.0 m (3.2 %) |
| F2 | post_s_a1-guilds_den_b2 vs post_s_b1-guilds_den_a2 | 100.9 m vs 104.2 m (3.2 %) |
| F2 | post_s_b1-lairs_two_a1 vs post_s_b2-lairs_two_a2 | 173.4 m vs 179.2 m (3.2 %) |
| F2 | rich_node_a1-third_node_b1 vs rich_node_b1-third_node_a1 | 148.0 m vs 152.9 m (3.2 %) |
| F2 | guilds_lodge_a2-lairs_one_b1 vs guilds_lodge_b1-lairs_one_a2 | 159.7 m vs 154.6 m (3.2 %) |
| F2 | wallow_a1-guilds_lodge_b2 vs wallow_a2-guilds_lodge_b1 | 163.6 m vs 169.1 m (3.2 %) |
| F2 | wallow_a2-guilds_lodge_b1 vs wallow_b2-guilds_lodge_a1 | 169.1 m vs 163.6 m (3.2 %) |
| F2 | keep_t3-guilds_den_b1 vs keep_t4-guilds_den_a1 | 159.9 m vs 154.7 m (3.2 %) |
| F2 | keep_t0-guilds_den_b2 vs keep_t3-guilds_den_b1 | 154.7 m vs 159.9 m (3.2 %) |
| F2 | nat_node_a1-guilds_lodge_a2 vs nat_node_a2-guilds_lodge_a1 | 110.1 m vs 106.6 m (3.2 %) |
| F2 | nat_node_a1-guilds_lodge_a2 vs nat_node_b1-guilds_lodge_b2 | 110.1 m vs 106.6 m (3.2 %) |
| F2 | third_node_b1-x_bridge_s vs third_node_b2-x_bridge_n | 156.6 m vs 151.6 m (3.2 %) |
| F2 | peddler_b1-cache_b_a2 vs peddler_b2-cache_b_a1 | 75.9 m vs 78.4 m (3.2 %) |
| F2 | home_b_b1-lairs_one_a1 vs home_b_b2-lairs_one_a2 | 186.3 m vs 192.4 m (3.2 %) |
| F2 | post_s_b1-guilds_den_a2 vs post_s_b2-guilds_den_a1 | 104.2 m vs 100.9 m (3.2 %) |
| F2 | third_node_a2-x_bridge_s vs third_node_b2-x_bridge_n | 156.6 m vs 151.6 m (3.2 %) |
| F2 | home_b_a2-lairs_one_b2 vs home_b_b2-lairs_one_a2 | 186.3 m vs 192.4 m (3.2 %) |
| F2 | shrine_a2-guilds_lodge_b1 vs shrine_b1-guilds_lodge_a2 | 154.2 m vs 149.2 m (3.2 %) |
| F2 | inn_a1-guilds_lodge_b2 vs inn_a2-guilds_lodge_b1 | 124.6 m vs 128.7 m (3.2 %) |
| F2 | inn_a2-guilds_lodge_b1 vs inn_b2-guilds_lodge_a1 | 128.7 m vs 124.6 m (3.2 %) |
| F2 | keep_t3-guilds_lodge_b1 vs keep_t4-guilds_lodge_a1 | 167.2 m vs 161.9 m (3.2 %) |
| F2 | keep_t0-guilds_lodge_b2 vs keep_t3-guilds_lodge_b1 | 161.9 m vs 167.2 m (3.2 %) |
| F2 | guilds_den_a1-peddler_b1 vs guilds_den_b1-peddler_a1 | 181.8 m vs 187.8 m (3.2 %) |
| F2 | well_a1-peddler_b2 vs well_a2-peddler_b1 | 111.7 m vs 115.3 m (3.2 %) |
| F2 | stag_a1-cache_a_a2 vs stag_a2-cache_a_a1 | 140.9 m vs 145.5 m (3.2 %) |
| F2 | stag_a2-cache_a_a1 vs stag_b2-cache_a_b1 | 145.5 m vs 140.9 m (3.2 %) |
| F2 | well_a2-peddler_b1 vs well_b2-peddler_a1 | 115.3 m vs 111.7 m (3.2 %) |
| F2 | nat_node_a2-post_s_a1 vs nat_node_b2-post_s_b1 | 97.9 m vs 101.1 m (3.2 %) |
| F2 | nat_node_a1-post_s_a2 vs nat_node_a2-post_s_a1 | 101.1 m vs 97.9 m (3.2 %) |
| F2 | nat_node_b1-post_s_b2 vs nat_node_b2-post_s_b1 | 97.9 m vs 101.1 m (3.2 %) |
| F2 | nat_node_a1-post_s_a2 vs nat_node_b1-post_s_b2 | 101.1 m vs 97.9 m (3.2 %) |
| F2 | home_b_b1-cache_b_a2 vs home_b_b2-cache_b_a1 | 78.6 m vs 81.1 m (3.2 %) |
| F2 | home_b_a2-x_bridge_n vs home_b_b1-x_bridge_n | 71.1 m vs 68.8 m (3.2 %) |
| F2 | stag_a1-lairs_one_b2 vs stag_b1-lairs_one_a2 | 101.7 m vs 105.0 m (3.2 %) |
| F2 | third_node_a2-peddler_b1 vs third_node_b2-peddler_a1 | 160.3 m vs 155.2 m (3.2 %) |
| F2 | stag_b1-lairs_one_a2 vs stag_b2-lairs_one_a1 | 105.0 m vs 101.7 m (3.2 %) |
| F2 | post_w_a1-post_s_b2 vs post_w_b1-post_s_a2 | 125.6 m vs 121.6 m (3.2 %) |
| F2 | shrine_a1-lairs_one_b1 vs shrine_a2-lairs_one_b2 | 153.2 m vs 148.4 m (3.2 %) |
| F2 | well_b1-wallow_a1 vs well_b2-wallow_a2 | 155.6 m vs 160.7 m (3.2 %) |
| F2 | well_a1-wallow_b1 vs well_b1-wallow_a1 | 160.7 m vs 155.6 m (3.2 %) |
| F2 | post_w_a1-guilds_lodge_b1 vs post_w_a2-guilds_lodge_b2 | 193.5 m vs 187.4 m (3.2 %) |
| F2 | lairs_one_a1-lairs_one_a2 vs lairs_one_b2-lairs_one_b1 | 164.7 m vs 170.1 m (3.2 %) |
| F2 | stag_b1-guilds_lodge_b1 vs stag_b2-guilds_lodge_b2 | 48.7 m vs 50.3 m (3.2 %) |
| F2 | stag_a1-guilds_lodge_a1 vs stag_a2-guilds_lodge_a2 | 50.3 m vs 48.7 m (3.2 %) |
| F2 | stag_a2-guilds_lodge_a2 vs stag_b2-guilds_lodge_b2 | 48.7 m vs 50.3 m (3.2 %) |
| F2 | stag_a1-guilds_lodge_a1 vs stag_b1-guilds_lodge_b1 | 50.3 m vs 48.7 m (3.2 %) |
| F2 | peddler_a1-cache_b_b2 vs peddler_a2-cache_b_b1 | 78.5 m vs 76.0 m (3.2 %) |
| F2 | well_a1-post_w_b2 vs well_a2-post_w_b1 | 128.5 m vs 132.7 m (3.2 %) |
| F2 | keep_t0-cache_b_b2 vs keep_t1-cache_b_a2 | 82.7 m vs 80.1 m (3.2 %) |
| F2 | nat_node_b1-rich_node_a1 vs nat_node_b2-rich_node_a2 | 88.8 m vs 91.7 m (3.2 %) |
| F2 | wallow_a1-wallow_b2 vs wallow_a2-wallow_b1 | 164.4 m vs 159.2 m (3.2 %) |
| F2 | shrine_a1-lairs_one_b1 vs shrine_b1-lairs_one_a1 | 153.2 m vs 148.4 m (3.2 %) |
| F2 | third_node_a1-peddler_b2 vs third_node_a2-peddler_b1 | 155.3 m vs 160.3 m (3.2 %) |
| F2 | home_a_a2-post_w_b2 vs home_a_b1-post_w_a1 | 177.1 m vs 171.5 m (3.1 %) |
| F2 | wallow_a1-lairs_one_b2 vs wallow_a2-lairs_one_b1 | 146.8 m vs 151.6 m (3.1 %) |
| F2 | wallow_a2-lairs_one_b1 vs wallow_b2-lairs_one_a1 | 151.6 m vs 146.8 m (3.1 %) |
| F2 | wallow_a2-lairs_one_b1 vs wallow_b1-lairs_one_a2 | 151.6 m vs 146.8 m (3.1 %) |
| F2 | home_b_a1-cache_b_b2 vs home_b_a2-cache_b_b1 | 81.2 m vs 78.7 m (3.1 %) |
| F2 | post_w_a1-guilds_lodge_b1 vs post_w_b1-guilds_lodge_a1 | 193.5 m vs 187.4 m (3.1 %) |
| F2 | rich_node_a2-guilds_lodge_a1 vs rich_node_b1-guilds_lodge_b2 | 147.6 m vs 152.4 m (3.1 %) |
| F2 | home_a_a1-post_w_b1 vs home_a_b1-post_w_a1 | 166.1 m vs 171.5 m (3.1 %) |
| F2 | home_a_b1-post_w_a1 vs home_a_b2-post_w_a2 | 171.5 m vs 166.1 m (3.1 %) |
| F2 | post_w_b1-post_s_a2 vs post_w_b2-post_s_a1 | 121.6 m vs 125.6 m (3.1 %) |
| F2 | guilds_lodge_a1-lairs_one_b1 vs guilds_lodge_b2-lairs_one_a2 | 227.1 m vs 220.0 m (3.1 %) |
| F2 | tower_r_a1-guilds_lodge_a2 vs tower_r_b1-guilds_lodge_b2 | 158.4 m vs 163.5 m (3.1 %) |
| F2 | tower_r_b1-guilds_lodge_b2 vs tower_r_b2-guilds_lodge_b1 | 163.5 m vs 158.4 m (3.1 %) |
| F2 | well_a2-wallow_b2 vs well_b2-wallow_a2 | 155.7 m vs 160.7 m (3.1 %) |
| F2 | well_a1-wallow_b1 vs well_a2-wallow_b2 | 160.7 m vs 155.7 m (3.1 %) |
| F2 | third_node_a2-guilds_den_b1 vs third_node_b1-guilds_den_a2 | 160.3 m vs 155.3 m (3.1 %) |
| F2 | nat_node_a1-tower_r_b2 vs nat_node_a2-tower_r_b1 | 75.1 m vs 72.8 m (3.1 %) |
| F2 | tower_r_a1-crown vs tower_r_b1-crown | 77.5 m vs 75.1 m (3.1 %) |
| F2 | tower_r_b1-crown vs tower_r_b2-crown | 75.1 m vs 77.5 m (3.1 %) |
| F2 | home_b_a2-third_node_b1 vs home_b_b2-third_node_a1 | 149.2 m vs 154.0 m (3.1 %) |
| F2 | home_b_a1-third_node_b2 vs home_b_a2-third_node_b1 | 154.0 m vs 149.2 m (3.1 %) |
| F2 | home_b_a1-rich_node_b2 vs home_b_b1-rich_node_a2 | 88.7 m vs 85.9 m (3.1 %) |
| F2 | tower_c_a2-x_bridge_n vs tower_c_b2-x_bridge_s | 61.4 m vs 63.4 m (3.1 %) |
| F2 | home_b_a2-rich_node_b1 vs home_b_b1-rich_node_a2 | 88.7 m vs 85.9 m (3.1 %) |
| F2 | stag_b1-post_s_a1 vs stag_b2-post_s_a2 | 170.8 m vs 176.2 m (3.1 %) |
| F2 | shrine_a2-guilds_lodge_b2 vs shrine_b2-guilds_lodge_a2 | 160.6 m vs 165.8 m (3.1 %) |
| F2 | shrine_a2-guilds_den_b1 vs shrine_b1-guilds_den_a2 | 146.8 m vs 151.5 m (3.1 %) |
| F2 | home_a_a1-rich_node_b2 vs home_a_b1-rich_node_a2 | 98.8 m vs 95.7 m (3.1 %) |
| F2 | nat_node_a1-wallow_a1 vs nat_node_a2-wallow_a2 | 52.6 m vs 54.3 m (3.1 %) |
| F2 | nat_node_a2-wallow_a2 vs nat_node_b2-wallow_b2 | 54.3 m vs 52.6 m (3.1 %) |
| F2 | inn_a2-cache_b_b1 vs inn_b2-cache_b_a1 | 41.3 m vs 42.6 m (3.1 %) |
| F2 | guilds_den_a1-guilds_den_b2 vs guilds_den_a2-guilds_den_b1 | 159.1 m vs 164.2 m (3.1 %) |
| F2 | peddler_a2-cache_b_b1 vs peddler_b2-cache_b_a1 | 76.0 m vs 78.4 m (3.1 %) |
| F2 | keep_t1-cache_b_a2 vs keep_t4-cache_b_a1 | 80.1 m vs 82.6 m (3.1 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_b1-lairs_two_a1 | 152.9 m vs 157.7 m (3.1 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_a2-lairs_two_b2 | 152.9 m vs 157.7 m (3.1 %) |
| F2 | nat_node_a2-tower_r_b1 vs nat_node_b1-tower_r_a2 | 72.8 m vs 75.1 m (3.1 %) |
| F2 | nat_node_a1-guilds_lodge_a1 vs nat_node_a2-guilds_lodge_a2 | 77.7 m vs 75.4 m (3.1 %) |
| F2 | nat_node_a2-guilds_lodge_a2 vs nat_node_b2-guilds_lodge_b2 | 75.4 m vs 77.7 m (3.1 %) |
| F2 | shrine_b1-guilds_lodge_a1 vs shrine_b2-guilds_lodge_a2 | 160.7 m vs 165.8 m (3.1 %) |
| F2 | guilds_den_b1-lairs_two_a1 vs guilds_den_b2-lairs_two_a2 | 218.3 m vs 211.6 m (3.1 %) |
| F2 | home_a_a1-lairs_two_b1 vs home_a_b2-lairs_two_a2 | 157.7 m vs 162.7 m (3.1 %) |
| F2 | home_b_a2-cache_b_b1 vs home_b_b2-cache_b_a1 | 78.7 m vs 81.1 m (3.1 %) |
| F2 | nat_node_a2-tower_r_b2 vs nat_node_b1-tower_r_a1 | 96.9 m vs 99.9 m (3.1 %) |
| F2 | wallow_a1-cache_b_a1 vs wallow_b1-cache_b_b1 | 76.4 m vs 74.1 m (3.1 %) |
| F2 | wallow_b1-cache_b_b1 vs wallow_b2-cache_b_b2 | 74.1 m vs 76.4 m (3.1 %) |
| F2 | wallow_a2-cache_b_a2 vs wallow_b2-cache_b_b2 | 74.1 m vs 76.4 m (3.1 %) |
| F2 | wallow_a1-cache_b_a1 vs wallow_a2-cache_b_a2 | 76.4 m vs 74.1 m (3.1 %) |
| F2 | home_b_b1-rich_node_a2 vs home_b_b2-rich_node_a1 | 85.9 m vs 88.6 m (3.1 %) |
| F2 | shrine_a2-wallow_b2 vs shrine_b2-wallow_a2 | 147.8 m vs 152.5 m (3.1 %) |
| F2 | home_b_b1-x_bridge_n vs home_b_b2-x_bridge_s | 68.8 m vs 71.0 m (3.1 %) |
| F2 | home_b_a1-x_bridge_s vs home_b_b1-x_bridge_n | 71.0 m vs 68.8 m (3.1 %) |
| F2 | keep_t0-cache_b_b2 vs keep_t3-cache_b_b1 | 82.7 m vs 80.1 m (3.1 %) |
| F2 | wallow_a2-cache_b_b2 vs wallow_b2-cache_b_a2 | 130.9 m vs 126.9 m (3.0 %) |
| F2 | home_b_a1-stag_b1 vs home_b_a2-stag_b2 | 154.4 m vs 159.3 m (3.0 %) |
| F2 | home_a_b1-rich_node_a2 vs home_a_b2-rich_node_a1 | 95.7 m vs 98.7 m (3.0 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t3-tower_r_b2 | 131.9 m vs 136.0 m (3.0 %) |
| F2 | rich_node_b1-tower_r_b2 vs rich_node_b2-tower_r_b1 | 118.3 m vs 122.0 m (3.0 %) |
| F2 | shrine_a1-cache_b_b2 vs shrine_b2-cache_b_a1 | 69.0 m vs 66.9 m (3.0 %) |
| F2 | stag_a1-peddler_b1 vs stag_a2-peddler_b2 | 145.6 m vs 141.2 m (3.0 %) |
| F2 | home_b_a2-tower_r_b1 vs home_b_b1-tower_r_a2 | 86.8 m vs 84.2 m (3.0 %) |
| F2 | well_a1-stag_b1 vs well_b2-stag_a2 | 166.1 m vs 171.3 m (3.0 %) |
| F2 | post_s_a2-lairs_one_b1 vs post_s_b1-lairs_one_a2 | 97.0 m vs 94.1 m (3.0 %) |
| F2 | guilds_lodge_a2-x_bridge_n vs guilds_lodge_b2-x_bridge_s | 87.7 m vs 85.1 m (3.0 %) |
| F2 | guilds_lodge_b1-x_bridge_n vs guilds_lodge_b2-x_bridge_s | 87.7 m vs 85.1 m (3.0 %) |
| F2 | guilds_lodge_a1-x_bridge_s vs guilds_lodge_b1-x_bridge_n | 85.1 m vs 87.7 m (3.0 %) |
| F2 | guilds_lodge_a1-x_bridge_s vs guilds_lodge_a2-x_bridge_n | 85.1 m vs 87.7 m (3.0 %) |
| F2 | home_b_a2-cache_a_b1 vs home_b_b1-cache_a_a2 | 118.1 m vs 114.5 m (3.0 %) |
| F2 | well_a1-lairs_one_b2 vs well_b1-lairs_one_a2 | 112.1 m vs 108.7 m (3.0 %) |
| F2 | well_b1-lairs_one_a2 vs well_b2-lairs_one_a1 | 108.7 m vs 112.1 m (3.0 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t3-lairs_two_b2 | 163.2 m vs 168.2 m (3.0 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t1-lairs_two_a1 | 163.2 m vs 168.2 m (3.0 %) |
| F2 | shrine_b1-wallow_a1 vs shrine_b2-wallow_a2 | 147.9 m vs 152.5 m (3.0 %) |
| F2 | home_b_a1-stag_b1 vs home_b_b1-stag_a1 | 154.4 m vs 159.2 m (3.0 %) |
| F2 | home_a_a1-rich_node_b2 vs home_a_a2-rich_node_b1 | 98.8 m vs 95.8 m (3.0 %) |
| F2 | post_s_a1-cache_a_b1 vs post_s_b1-cache_a_a1 | 163.9 m vs 159.0 m (3.0 %) |
| F2 | wallow_b1-cache_b_a1 vs wallow_b2-cache_b_a2 | 130.8 m vs 126.9 m (3.0 %) |
| F2 | guilds_den_a1-lairs_two_b1 vs guilds_den_a2-lairs_two_b2 | 221.1 m vs 214.5 m (3.0 %) |
| F2 | post_w_a1-lairs_two_b1 vs post_w_b2-lairs_two_a2 | 161.3 m vs 166.3 m (3.0 %) |
| F2 | inn_b1-post_s_a2 vs inn_b2-post_s_a1 | 79.6 m vs 82.0 m (3.0 %) |
| F2 | stag_a2-peddler_b2 vs stag_b2-peddler_a2 | 141.2 m vs 145.5 m (3.0 %) |
| F2 | tower_c_a1-x_bridge_s vs tower_c_a2-x_bridge_n | 63.3 m vs 61.4 m (3.0 %) |
| F2 | third_node_a1-tower_c_b2 vs third_node_a2-tower_c_b1 | 125.1 m vs 121.4 m (3.0 %) |
| F2 | rich_node_a1-inn_b2 vs rich_node_b1-inn_a2 | 53.9 m vs 55.5 m (3.0 %) |
| F2 | wallow_a1-cache_b_b1 vs wallow_a2-cache_b_b2 | 127.0 m vs 130.9 m (3.0 %) |
| F2 | tower_r_a2-peddler_a2 vs tower_r_b1-peddler_b1 | 66.1 m vs 64.2 m (3.0 %) |
| F2 | keep_t3-cache_b_b1 vs keep_t4-cache_b_a1 | 80.1 m vs 82.6 m (3.0 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t1-tower_r_a1 | 131.9 m vs 135.9 m (3.0 %) |
| F2 | tower_c_b1-x_bridge_n vs tower_c_b2-x_bridge_s | 61.5 m vs 63.4 m (3.0 %) |
| F2 | well_a2-post_w_b1 vs well_b1-post_w_a2 | 132.7 m vs 128.8 m (3.0 %) |
| F2 | post_s_b1-cache_a_a1 vs post_s_b2-cache_a_a2 | 159.0 m vs 163.8 m (3.0 %) |
| F2 | home_a_a2-lairs_one_b2 vs home_a_b2-lairs_one_a2 | 174.5 m vs 179.8 m (3.0 %) |
| F2 | guilds_den_b1-cache_b_a1 vs guilds_den_b2-cache_b_a2 | 161.8 m vs 157.0 m (3.0 %) |
| F2 | home_a_a2-rich_node_b1 vs home_a_b2-rich_node_a1 | 95.8 m vs 98.7 m (3.0 %) |
| F2 | third_node_a1-cache_b_a2 vs third_node_a2-cache_b_a1 | 113.1 m vs 116.6 m (2.9 %) |
| F2 | third_node_a1-cache_b_a2 vs third_node_b1-cache_b_b2 | 113.1 m vs 116.6 m (2.9 %) |
| F2 | third_node_a2-cache_b_a1 vs third_node_b2-cache_b_b1 | 116.6 m vs 113.1 m (2.9 %) |
| F2 | third_node_b1-cache_b_b2 vs third_node_b2-cache_b_b1 | 116.6 m vs 113.1 m (2.9 %) |
| F2 | home_a_b1-lairs_one_a1 vs home_a_b2-lairs_one_a2 | 174.5 m vs 179.8 m (2.9 %) |
| F2 | wallow_a1-cache_b_b1 vs wallow_b1-cache_b_a1 | 127.0 m vs 130.8 m (2.9 %) |
| F2 | nat_node_a1-tower_r_b1 vs nat_node_b1-tower_r_a1 | 103.0 m vs 99.9 m (2.9 %) |
| F2 | home_b_a1-tower_r_b2 vs home_b_b1-tower_r_a2 | 86.7 m vs 84.2 m (2.9 %) |
| F2 | home_b_b1-tower_r_a2 vs home_b_b2-tower_r_a1 | 84.2 m vs 86.7 m (2.9 %) |
| F2 | inn_a2-post_s_b1 vs inn_b1-post_s_a2 | 77.3 m vs 79.6 m (2.9 %) |
| F2 | home_b_b1-well_a1 vs home_b_b2-well_a2 | 149.2 m vs 144.9 m (2.9 %) |
| F2 | home_b_a1-well_b1 vs home_b_b1-well_a1 | 144.9 m vs 149.2 m (2.9 %) |
| F2 | home_a_a1-stag_b1 vs home_a_b2-stag_a2 | 144.7 m vs 149.0 m (2.9 %) |
| F2 | home_b_a2-cache_a_b2 vs home_b_b2-cache_a_a2 | 162.0 m vs 157.3 m (2.9 %) |
| F2 | third_node_a2-tower_c_b1 vs third_node_b2-tower_c_a1 | 121.4 m vs 125.0 m (2.9 %) |
| F2 | home_b_b1-cache_a_a1 vs home_b_b2-cache_a_a2 | 162.0 m vs 157.3 m (2.9 %) |
| F2 | third_node_a2-guilds_lodge_b1 vs third_node_b1-guilds_lodge_a2 | 167.6 m vs 162.8 m (2.9 %) |
| F2 | post_w_a1-cache_a_b2 vs post_w_a2-cache_a_b1 | 143.5 m vs 147.8 m (2.9 %) |
| F2 | home_b_a2-well_b2 vs home_b_b2-well_a2 | 149.2 m vs 144.9 m (2.9 %) |
| F2 | home_b_a1-well_b1 vs home_b_a2-well_b2 | 144.9 m vs 149.2 m (2.9 %) |
| F2 | home_b_a1-cache_a_b1 vs home_b_a2-cache_a_b2 | 157.3 m vs 162.0 m (2.9 %) |
| F2 | home_b_a1-cache_a_b1 vs home_b_b1-cache_a_a1 | 157.3 m vs 162.0 m (2.9 %) |
| F2 | post_w_a2-cache_a_b1 vs post_w_b2-cache_a_a1 | 147.8 m vs 143.6 m (2.9 %) |
| F2 | shrine_a1-guilds_lodge_b1 vs shrine_b2-guilds_lodge_a2 | 170.7 m vs 165.8 m (2.9 %) |
| F2 | wallow_a2-guilds_den_b1 vs wallow_b1-guilds_den_a2 | 161.7 m vs 157.0 m (2.9 %) |
| F2 | wallow_a2-guilds_den_b1 vs wallow_b2-guilds_den_a1 | 161.7 m vs 157.0 m (2.9 %) |
| F2 | wallow_a1-guilds_den_b2 vs wallow_a2-guilds_den_b1 | 157.0 m vs 161.7 m (2.9 %) |
| F2 | rich_node_a1-inn_b2 vs rich_node_a2-inn_b1 | 53.9 m vs 55.5 m (2.9 %) |
| F2 | nat_node_a1-tower_r_b2 vs nat_node_b2-tower_r_a1 | 75.1 m vs 73.0 m (2.9 %) |
| F2 | keep_t0-third_node_b1 vs keep_t1-third_node_a1 | 179.3 m vs 184.6 m (2.9 %) |
| F2 | shrine_a1-lairs_two_b2 vs shrine_a2-lairs_two_b1 | 125.5 m vs 121.9 m (2.9 %) |
| F2 | rich_node_a1-peddler_b1 vs rich_node_a2-peddler_b2 | 108.5 m vs 111.7 m (2.9 %) |
| F2 | home_a_a1-ford_nest_a2 vs home_a_a2-ford_nest_a1 | 92.7 m vs 95.4 m (2.9 %) |
| F2 | home_a_a1-ford_nest_a2 vs home_a_b1-ford_nest_a1 | 92.7 m vs 95.4 m (2.9 %) |
| F2 | home_a_a1-x_ford_n vs home_a_a2-x_ford_s | 92.7 m vs 95.4 m (2.9 %) |
| F2 | home_a_a1-x_ford_n vs home_a_b1-x_ford_s | 92.7 m vs 95.4 m (2.9 %) |
| F2 | home_a_b1-x_ford_s vs home_a_b2-x_ford_n | 95.4 m vs 92.7 m (2.9 %) |
| F2 | home_a_b1-ford_nest_a1 vs home_a_b2-ford_nest_a2 | 95.4 m vs 92.7 m (2.9 %) |
| F2 | home_a_a2-ford_nest_a1 vs home_a_b2-ford_nest_a2 | 95.4 m vs 92.7 m (2.9 %) |
| F2 | home_a_a2-x_ford_s vs home_a_b2-x_ford_n | 95.4 m vs 92.7 m (2.9 %) |
| F2 | rich_node_b1-inn_a2 vs rich_node_b2-inn_a1 | 55.5 m vs 53.9 m (2.9 %) |
| F2 | keep_t0-third_node_b1 vs keep_t3-third_node_b2 | 179.3 m vs 184.5 m (2.8 %) |
| F2 | stag_a1-guilds_den_b2 vs stag_b1-guilds_den_a2 | 111.9 m vs 115.1 m (2.8 %) |
| F2 | stag_b1-guilds_den_a2 vs stag_b2-guilds_den_a1 | 115.1 m vs 111.9 m (2.8 %) |
| F2 | tower_c_a1-x_bridge_s vs tower_c_b1-x_bridge_n | 63.3 m vs 61.5 m (2.8 %) |
| F2 | guilds_den_a2-guilds_lodge_b1 vs guilds_den_b1-guilds_lodge_a2 | 171.5 m vs 166.7 m (2.8 %) |
| F2 | tower_r_b1-post_s_a2 vs tower_r_b2-post_s_a1 | 41.3 m vs 40.1 m (2.8 %) |
| F2 | home_a_a1-guilds_lodge_b2 vs home_a_b1-guilds_lodge_a2 | 170.5 m vs 165.7 m (2.8 %) |
| F2 | home_a_b1-guilds_lodge_a2 vs home_a_b2-guilds_lodge_a1 | 165.7 m vs 170.5 m (2.8 %) |
| F2 | cache_b_a1-lairs_one_a1 vs cache_b_b1-lairs_one_b1 | 78.9 m vs 81.2 m (2.8 %) |
| F2 | cache_b_b1-lairs_one_b1 vs cache_b_b2-lairs_one_b2 | 81.2 m vs 78.9 m (2.8 %) |
| F2 | rich_node_a2-peddler_b2 vs rich_node_b1-peddler_a1 | 111.7 m vs 108.5 m (2.8 %) |
| F2 | tower_r_a2-lairs_one_b1 vs tower_r_b1-lairs_one_a2 | 87.8 m vs 85.3 m (2.8 %) |
| F2 | nat_node_b1-tower_r_a2 vs nat_node_b2-tower_r_a1 | 75.1 m vs 73.0 m (2.8 %) |
| F2 | stag_a1-lairs_two_a2 vs stag_a2-lairs_two_a1 | 155.9 m vs 160.4 m (2.8 %) |
| F2 | stag_a2-lairs_two_a1 vs stag_b2-lairs_two_b1 | 160.4 m vs 155.9 m (2.8 %) |
| F2 | tower_r_a1-cache_b_a2 vs tower_r_b1-cache_b_b2 | 93.4 m vs 90.8 m (2.8 %) |
| F2 | tower_r_b1-cache_b_b2 vs tower_r_b2-cache_b_b1 | 90.8 m vs 93.4 m (2.8 %) |
| F2 | tower_r_a2-peddler_b2 vs tower_r_b1-peddler_a1 | 126.6 m vs 130.2 m (2.8 %) |
| F2 | home_a_a2-tower_r_a2 vs home_a_b1-tower_r_b1 | 71.3 m vs 69.3 m (2.8 %) |
| F2 | tower_r_a1-post_w_b1 vs tower_r_b1-post_w_a1 | 133.0 m vs 129.3 m (2.8 %) |
| F2 | tower_r_a2-cache_b_a1 vs tower_r_b1-cache_b_b2 | 93.4 m vs 90.8 m (2.8 %) |
| F2 | guilds_lodge_a2-cache_a_a1 vs guilds_lodge_b2-cache_a_b1 | 147.5 m vs 143.4 m (2.8 %) |
| F2 | nat_node_a1-guilds_lodge_a1 vs nat_node_b1-guilds_lodge_b1 | 77.7 m vs 80.0 m (2.8 %) |
| F2 | nat_node_b1-guilds_lodge_b1 vs nat_node_b2-guilds_lodge_b2 | 80.0 m vs 77.7 m (2.8 %) |
| F2 | well_a1-guilds_den_b2 vs well_b1-guilds_den_a2 | 122.3 m vs 118.9 m (2.8 %) |
| F2 | well_b1-guilds_den_a2 vs well_b2-guilds_den_a1 | 118.9 m vs 122.3 m (2.8 %) |
| F2 | stag_a2-lairs_one_a1 vs stag_b2-lairs_one_b1 | 167.5 m vs 162.8 m (2.8 %) |
| F2 | stag_a1-lairs_one_a2 vs stag_a2-lairs_one_a1 | 162.8 m vs 167.5 m (2.8 %) |
| F2 | guilds_lodge_b1-cache_a_b2 vs guilds_lodge_b2-cache_a_b1 | 147.5 m vs 143.4 m (2.8 %) |
| F2 | home_a_a1-cache_b_b2 vs home_a_b1-cache_b_a2 | 85.9 m vs 83.5 m (2.8 %) |
| F2 | nat_node_a1-third_node_a2 vs nat_node_a2-third_node_a1 | 98.7 m vs 96.0 m (2.8 %) |
| F2 | nat_node_a1-third_node_a2 vs nat_node_b1-third_node_b2 | 98.7 m vs 96.0 m (2.8 %) |
| F2 | stag_b1-post_s_b2 vs stag_b2-post_s_b1 | 153.4 m vs 157.8 m (2.8 %) |
| F2 | stag_a1-post_s_a2 vs stag_b1-post_s_b2 | 157.8 m vs 153.4 m (2.8 %) |
| F2 | rich_node_b1-guilds_lodge_b2 vs rich_node_b2-guilds_lodge_b1 | 152.4 m vs 148.2 m (2.8 %) |
| F2 | rich_node_a1-guilds_lodge_a2 vs rich_node_b1-guilds_lodge_b2 | 148.2 m vs 152.4 m (2.8 %) |
| F2 | tower_r_b1-post_w_a1 vs tower_r_b2-post_w_a2 | 129.3 m vs 133.0 m (2.8 %) |
| F2 | wallow_a1-inn_a2 vs wallow_a2-inn_a1 | 86.5 m vs 88.9 m (2.8 %) |
| F2 | wallow_a2-inn_a1 vs wallow_b2-inn_b1 | 88.9 m vs 86.5 m (2.8 %) |
| F2 | stag_a2-lairs_one_b1 vs stag_b1-lairs_one_a2 | 108.0 m vs 105.0 m (2.8 %) |
| F2 | rich_node_a2-inn_b1 vs rich_node_b2-inn_a1 | 55.5 m vs 53.9 m (2.7 %) |
| F2 | ford_nest_a1-post_s_b1 vs ford_nest_a2-post_s_a1 | 122.0 m vs 118.7 m (2.7 %) |
| F2 | nat_node_a1-peddler_b2 vs nat_node_a2-peddler_b1 | 106.9 m vs 109.9 m (2.7 %) |
| F2 | tower_r_a1-post_s_b2 vs tower_r_b1-post_s_a2 | 40.2 m vs 41.3 m (2.7 %) |
| F2 | ford_nest_a1-post_s_a2 vs ford_nest_a1-post_s_b1 | 118.7 m vs 122.0 m (2.7 %) |
| F2 | wallow_b1-inn_b2 vs wallow_b2-inn_b1 | 88.9 m vs 86.5 m (2.7 %) |
| F2 | wallow_a1-inn_a2 vs wallow_b1-inn_b2 | 86.5 m vs 88.9 m (2.7 %) |
| F2 | tower_c_a2-wallow_b2 vs tower_c_b2-wallow_a2 | 118.2 m vs 114.9 m (2.7 %) |
| F2 | tower_c_a1-wallow_b1 vs tower_c_a2-wallow_b2 | 114.9 m vs 118.2 m (2.7 %) |
| F2 | tower_c_a1-wallow_b1 vs tower_c_b1-wallow_a1 | 114.9 m vs 118.2 m (2.7 %) |
| F2 | tower_c_b1-wallow_a1 vs tower_c_b2-wallow_a2 | 118.2 m vs 114.9 m (2.7 %) |
| F2 | nat_node_a2-peddler_b1 vs nat_node_b2-peddler_a1 | 109.9 m vs 106.9 m (2.7 %) |
| F2 | wallow_a1-inn_a1 vs wallow_a2-inn_a2 | 57.0 m vs 55.4 m (2.7 %) |
| F2 | wallow_a1-inn_a1 vs wallow_b1-inn_b1 | 57.0 m vs 55.4 m (2.7 %) |
| F2 | wallow_a2-inn_a2 vs wallow_b2-inn_b2 | 55.4 m vs 57.0 m (2.7 %) |
| F2 | wallow_b1-inn_b1 vs wallow_b2-inn_b2 | 55.4 m vs 57.0 m (2.7 %) |
| F2 | post_s_a1-post_s_b1 vs post_s_b2-post_s_a2 | 177.0 m vs 172.3 m (2.7 %) |
| F2 | ford_nest_a1-post_s_b1 vs ford_nest_a2-post_s_b2 | 122.0 m vs 118.8 m (2.7 %) |
| F2 | wallow_a2-guilds_lodge_b1 vs wallow_b1-guilds_lodge_a2 | 169.1 m vs 164.5 m (2.7 %) |
| F2 | home_a_b1-cache_b_a2 vs home_a_b2-cache_b_a1 | 83.5 m vs 85.8 m (2.7 %) |
| F2 | keep_t0-stag_b1 vs keep_t3-stag_b2 | 150.2 m vs 154.3 m (2.7 %) |
| F2 | rich_node_a2-shrine_a1 vs rich_node_b1-shrine_b2 | 76.5 m vs 78.6 m (2.7 %) |
| F2 | post_s_a2-guilds_den_b1 vs post_s_b1-guilds_den_a2 | 107.1 m vs 104.2 m (2.7 %) |
| F2 | inn_a1-cache_b_b1 vs inn_a2-cache_b_b2 | 76.0 m vs 74.0 m (2.7 %) |
| F2 | keep_t0-stag_b1 vs keep_t1-stag_a1 | 150.2 m vs 154.3 m (2.7 %) |
| F2 | home_a_a1-cache_b_b2 vs home_a_a2-cache_b_b1 | 85.9 m vs 83.6 m (2.7 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_b2-wallow_a2 | 167.1 m vs 171.7 m (2.7 %) |
| F2 | nat_node_a1-guilds_lodge_b1 vs nat_node_b1-guilds_lodge_a1 | 153.6 m vs 157.8 m (2.7 %) |
| F2 | nat_node_b1-guilds_lodge_a1 vs nat_node_b2-guilds_lodge_a2 | 157.8 m vs 153.6 m (2.7 %) |
| F2 | tower_r_b1-shrine_b2 vs tower_r_b2-shrine_b1 | 86.2 m vs 83.9 m (2.7 %) |
| F2 | tower_r_a1-shrine_a2 vs tower_r_b1-shrine_b2 | 83.9 m vs 86.2 m (2.7 %) |
| F2 | home_a_a1-tower_r_a1 vs home_a_b1-tower_r_b1 | 71.2 m vs 69.3 m (2.7 %) |
| F2 | home_a_b1-tower_r_b1 vs home_a_b2-tower_r_b2 | 69.3 m vs 71.2 m (2.7 %) |
| F2 | nat_node_a2-post_s_b2 vs nat_node_b1-post_s_a1 | 112.3 m vs 115.3 m (2.6 %) |
| F2 | nat_node_a2-stag_b2 vs nat_node_b1-stag_a1 | 115.2 m vs 118.3 m (2.6 %) |
| F2 | post_s_a2-crown vs post_s_b1-crown | 92.5 m vs 90.1 m (2.6 %) |
| F2 | guilds_lodge_a1-cache_a_b2 vs guilds_lodge_a2-cache_a_b1 | 131.3 m vs 134.8 m (2.6 %) |
| F2 | guilds_lodge_a2-cache_a_b1 vs guilds_lodge_b2-cache_a_a1 | 134.8 m vs 131.3 m (2.6 %) |
| F2 | inn_a1-cache_b_b1 vs inn_b1-cache_b_a1 | 76.0 m vs 74.0 m (2.6 %) |
| F2 | peddler_a1-cache_a_b2 vs peddler_b1-cache_a_a2 | 123.8 m vs 120.6 m (2.6 %) |
| F2 | peddler_b1-cache_a_a2 vs peddler_b2-cache_a_a1 | 120.6 m vs 123.8 m (2.6 %) |
| F2 | peddler_b1-cache_a_a1 vs peddler_b2-cache_a_a2 | 146.6 m vs 142.8 m (2.6 %) |
| F2 | peddler_a2-cache_a_b2 vs peddler_b2-cache_a_a2 | 146.6 m vs 142.8 m (2.6 %) |
| F2 | tower_r_a1-post_s_b1 vs tower_r_a2-post_s_b2 | 166.6 m vs 162.3 m (2.6 %) |
| F2 | peddler_a1-cache_a_b1 vs peddler_b1-cache_a_a1 | 142.8 m vs 146.6 m (2.6 %) |
| F2 | inn_a1-lairs_two_b2 vs inn_a2-lairs_two_b1 | 99.0 m vs 96.5 m (2.6 %) |
| F2 | home_a_a1-guilds_lodge_b1 vs home_a_b2-guilds_lodge_a2 | 189.9 m vs 185.0 m (2.6 %) |
| F2 | peddler_a1-cache_a_b1 vs peddler_a2-cache_a_b2 | 142.8 m vs 146.6 m (2.6 %) |
| F2 | home_a_a2-cache_b_b1 vs home_a_b2-cache_b_a1 | 83.6 m vs 85.8 m (2.6 %) |
| F2 | inn_a2-lairs_two_b1 vs inn_b2-lairs_two_a1 | 96.5 m vs 99.0 m (2.6 %) |
| F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b1-cache_b_a1 | 166.0 m vs 161.8 m (2.6 %) |
| F2 | tower_r_a2-post_s_b1 vs tower_r_b1-post_s_a2 | 40.2 m vs 41.3 m (2.6 %) |
| F2 | keep_t1-cache_a_a1 vs keep_t4-cache_a_a2 | 157.1 m vs 153.1 m (2.6 %) |
| F2 | post_w_a2-lairs_two_b2 vs post_w_b2-lairs_two_a2 | 162.0 m vs 166.3 m (2.6 %) |
| F2 | keep_t3-cache_a_b2 vs keep_t4-cache_a_a2 | 157.1 m vs 153.1 m (2.6 %) |
| F2 | third_node_b1-shrine_a1 vs third_node_b2-shrine_a2 | 159.6 m vs 155.6 m (2.6 %) |
| F2 | third_node_a1-shrine_b1 vs third_node_b1-shrine_a1 | 155.6 m vs 159.6 m (2.6 %) |
| F2 | keep_t0-cache_a_b1 vs keep_t1-cache_a_a1 | 153.1 m vs 157.1 m (2.6 %) |
| F2 | tower_r_a2-post_w_a1 vs tower_r_b1-post_w_b2 | 102.0 m vs 104.7 m (2.6 %) |
| F2 | post_w_b1-lairs_two_a1 vs post_w_b2-lairs_two_a2 | 162.0 m vs 166.3 m (2.6 %) |
| F2 | keep_t0-cache_a_b1 vs keep_t3-cache_a_b2 | 153.1 m vs 157.1 m (2.6 %) |
| F2 | keep_t1-well_a1 vs keep_t4-well_a2 | 144.3 m vs 140.6 m (2.5 %) |
| F2 | keep_t0-well_b1 vs keep_t1-well_a1 | 140.6 m vs 144.3 m (2.5 %) |
| F2 | nat_node_a2-guilds_lodge_b2 vs nat_node_b1-guilds_lodge_a1 | 153.8 m vs 157.8 m (2.5 %) |
| F2 | post_w_a1-guilds_lodge_b1 vs post_w_b2-guilds_lodge_a2 | 193.5 m vs 188.6 m (2.5 %) |
| F2 | third_node_a2-post_w_b1 vs third_node_b2-post_w_a1 | 177.7 m vs 173.2 m (2.5 %) |
| F2 | keep_t3-post_s_b1 vs keep_t1-post_s_a2 | 102.8 m vs 100.2 m (2.5 %) |
| F2 | tower_c_a1-post_s_a2 vs tower_c_b2-post_s_b1 | 86.8 m vs 89.0 m (2.5 %) |
| F2 | keep_t3-well_b2 vs keep_t4-well_a2 | 144.2 m vs 140.6 m (2.5 %) |
| F2 | keep_t0-well_b1 vs keep_t3-well_b2 | 140.6 m vs 144.2 m (2.5 %) |
| F2 | rich_node_a1-guilds_lodge_a1 vs rich_node_a2-guilds_lodge_a2 | 72.0 m vs 73.8 m (2.5 %) |
| F2 | rich_node_a2-guilds_lodge_a2 vs rich_node_b2-guilds_lodge_b2 | 73.8 m vs 72.0 m (2.5 %) |
| F2 | wallow_a2-cache_a_a1 vs wallow_b2-cache_a_b1 | 121.7 m vs 118.6 m (2.5 %) |
| F2 | wallow_b1-cache_a_b2 vs wallow_b2-cache_a_b1 | 121.7 m vs 118.6 m (2.5 %) |
| F2 | home_b_b1-well_a2 vs home_b_b2-well_a1 | 110.9 m vs 113.7 m (2.5 %) |
| F2 | third_node_a1-post_w_b2 vs third_node_a2-post_w_b1 | 173.2 m vs 177.7 m (2.5 %) |
| F2 | keep_t0-guilds_lodge_b1 vs keep_t4-guilds_lodge_a2 | 195.4 m vs 190.5 m (2.5 %) |
| F2 | tower_c_b1-wallow_a2 vs tower_c_b2-wallow_a1 | 114.5 m vs 117.5 m (2.5 %) |
| F2 | tower_c_a2-wallow_b1 vs tower_c_b2-wallow_a1 | 114.5 m vs 117.5 m (2.5 %) |
| F2 | home_b_a1-well_b2 vs home_b_b1-well_a2 | 113.7 m vs 110.9 m (2.5 %) |
| F2 | keep_t0-tower_c_b2 vs keep_t1-tower_c_a2 | 104.8 m vs 102.2 m (2.5 %) |
| F2 | home_a_b1-stag_a2 vs home_a_b2-stag_a1 | 125.4 m vs 122.3 m (2.5 %) |
| F2 | home_a_a1-tower_r_b2 vs home_a_b1-tower_r_a2 | 102.1 m vs 104.7 m (2.5 %) |
| F2 | home_a_b1-tower_r_a2 vs home_a_b2-tower_r_a1 | 104.7 m vs 102.1 m (2.5 %) |
| F2 | home_a_a1-stag_b2 vs home_a_b1-stag_a2 | 122.3 m vs 125.4 m (2.5 %) |
| F2 | tower_c_a1-wallow_b2 vs tower_c_b1-wallow_a2 | 117.4 m vs 114.5 m (2.5 %) |
| F2 | tower_c_a1-wallow_b2 vs tower_c_a2-wallow_b1 | 117.4 m vs 114.5 m (2.5 %) |
| F2 | wallow_a1-stag_a2 vs wallow_a2-stag_a1 | 133.6 m vs 130.3 m (2.5 %) |
| F2 | wallow_a2-stag_a1 vs wallow_b2-stag_b1 | 130.3 m vs 133.6 m (2.5 %) |
| F2 | stag_a2-guilds_den_b1 vs stag_b1-guilds_den_a2 | 118.0 m vs 115.1 m (2.5 %) |
| F2 | tower_r_a2-guilds_den_b1 vs tower_r_b1-guilds_den_a2 | 97.9 m vs 95.5 m (2.5 %) |
| F2 | home_b_a1-guilds_lodge_b1 vs home_b_b2-guilds_lodge_a2 | 199.6 m vs 194.7 m (2.5 %) |
| F2 | home_a_a2-guilds_lodge_b1 vs home_a_b2-guilds_lodge_a1 | 174.8 m vs 170.5 m (2.5 %) |
| F2 | home_a_a1-guilds_lodge_b2 vs home_a_a2-guilds_lodge_b1 | 170.5 m vs 174.8 m (2.5 %) |
| F2 | keep_t1-well_a2 vs keep_t4-well_a1 | 112.4 m vs 115.2 m (2.5 %) |
| F2 | keep_t3-well_b1 vs keep_t4-well_a1 | 112.4 m vs 115.2 m (2.5 %) |
| F2 | keep_t0-well_b2 vs keep_t1-well_a2 | 115.2 m vs 112.4 m (2.5 %) |
| F2 | keep_t0-well_b2 vs keep_t3-well_b1 | 115.2 m vs 112.4 m (2.5 %) |
| F2 | rich_node_a2-peddler_a1 vs rich_node_b1-peddler_b2 | 90.7 m vs 93.0 m (2.4 %) |
| F2 | nat_node_a1-stag_b1 vs nat_node_b1-stag_a1 | 121.3 m vs 118.3 m (2.4 %) |
| F2 | keep_t1-tower_c_a2 vs keep_t4-tower_c_a1 | 102.2 m vs 104.7 m (2.4 %) |
| F2 | lairs_one_a2-lairs_two_b2 vs lairs_one_b2-lairs_two_a2 | 204.4 m vs 209.5 m (2.4 %) |
| F2 | lairs_one_a1-lairs_two_b1 vs lairs_one_a2-lairs_two_b2 | 209.5 m vs 204.4 m (2.4 %) |
| F2 | guilds_lodge_a1-peddler_b1 vs guilds_lodge_a2-peddler_b2 | 181.9 m vs 186.4 m (2.4 %) |
| F2 | tower_r_a2-x_ford_s vs tower_r_b1-x_ford_s | 105.3 m vs 102.8 m (2.4 %) |
| F2 | tower_r_a2-ford_nest_a1 vs tower_r_b1-ford_nest_a1 | 105.3 m vs 102.8 m (2.4 %) |
| F2 | rich_node_a2-tower_r_a1 vs rich_node_b2-tower_r_b1 | 119.0 m vs 122.0 m (2.4 %) |
| F2 | rich_node_a1-tower_r_a2 vs rich_node_b2-tower_r_b1 | 119.0 m vs 122.0 m (2.4 %) |
| F2 | home_a_a2-rich_node_b2 vs home_a_b2-rich_node_a2 | 118.0 m vs 115.1 m (2.4 %) |
| F2 | post_w_a2-cache_b_a2 vs post_w_b2-cache_b_b2 | 78.5 m vs 76.6 m (2.4 %) |
| F2 | post_w_a1-cache_b_a1 vs post_w_a2-cache_b_a2 | 76.6 m vs 78.5 m (2.4 %) |
| F2 | post_w_b1-cache_b_b1 vs post_w_b2-cache_b_b2 | 78.5 m vs 76.6 m (2.4 %) |
| F2 | post_w_a1-cache_b_a1 vs post_w_b1-cache_b_b1 | 76.6 m vs 78.5 m (2.4 %) |
| F2 | post_s_a2-cache_a_b2 vs post_s_b1-cache_a_a1 | 162.9 m vs 159.0 m (2.4 %) |
| F2 | nat_node_a1-lairs_two_b1 vs nat_node_a2-lairs_two_b2 | 134.2 m vs 137.6 m (2.4 %) |
| F2 | guilds_den_a2-peddler_b1 vs guilds_den_b2-peddler_a1 | 163.4 m vs 159.4 m (2.4 %) |
| F2 | keep_t0-tower_c_b2 vs keep_t3-tower_c_b1 | 104.8 m vs 102.3 m (2.4 %) |
| F2 | guilds_lodge_a1-peddler_b1 vs guilds_lodge_b1-peddler_a1 | 181.9 m vs 186.4 m (2.4 %) |
| F2 | nat_node_a1-lairs_two_b1 vs nat_node_b2-lairs_two_a2 | 134.2 m vs 137.5 m (2.4 %) |
| F2 | home_b_a2-post_s_a1 vs home_b_b2-post_s_b1 | 130.1 m vs 127.0 m (2.4 %) |
| F2 | guilds_den_a1-peddler_b2 vs guilds_den_a2-peddler_b1 | 159.4 m vs 163.4 m (2.4 %) |
| F2 | home_a_a2-stag_b1 vs home_a_b1-stag_a2 | 122.4 m vs 125.4 m (2.4 %) |
| F2 | home_a_b1-rich_node_a1 vs home_a_b2-rich_node_a2 | 118.0 m vs 115.1 m (2.4 %) |
| F2 | home_a_b1-lairs_two_a2 vs home_a_b2-lairs_two_a1 | 139.0 m vs 135.7 m (2.4 %) |
| F2 | home_a_a1-lairs_two_b2 vs home_a_b1-lairs_two_a2 | 135.7 m vs 139.0 m (2.4 %) |
| F2 | keep_t0-post_s_b2 vs keep_t1-post_s_a2 | 102.7 m vs 100.2 m (2.4 %) |
| F2 | shrine_a1-guilds_den_b2 vs shrine_b1-guilds_den_a2 | 147.9 m vs 151.5 m (2.4 %) |
| F2 | home_b_b1-post_s_b2 vs home_b_b2-post_s_b1 | 130.1 m vs 127.0 m (2.4 %) |
| F2 | tower_r_a2-post_w_b2 vs tower_r_b1-post_w_a1 | 132.4 m vs 129.3 m (2.4 %) |
| F2 | nat_node_b1-wallow_a1 vs nat_node_b2-wallow_a2 | 135.3 m vs 132.1 m (2.4 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_a2-wallow_b2 | 132.1 m vs 135.3 m (2.4 %) |
| F2 | nat_node_a2-wallow_b2 vs nat_node_b2-wallow_a2 | 135.3 m vs 132.1 m (2.4 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_b1-wallow_a1 | 132.1 m vs 135.3 m (2.4 %) |
| F2 | home_a_a2-cache_b_b2 vs home_a_b2-cache_b_a2 | 104.9 m vs 102.4 m (2.4 %) |
| F2 | home_a_a2-tower_r_b1 vs home_a_b1-tower_r_a2 | 102.2 m vs 104.7 m (2.4 %) |
| F2 | lairs_one_a1-lairs_one_b1 vs lairs_one_b2-lairs_one_a2 | 217.7 m vs 212.6 m (2.4 %) |
| F2 | home_a_a1-rich_node_b1 vs home_a_a2-rich_node_b2 | 115.2 m vs 118.0 m (2.4 %) |
| F2 | guilds_lodge_a2-lairs_one_b2 vs guilds_lodge_b1-lairs_one_a1 | 246.7 m vs 240.9 m (2.4 %) |
| F2 | keep_t1-post_s_a2 vs keep_t4-post_s_a1 | 100.2 m vs 102.7 m (2.3 %) |
| F2 | stag_a2-guilds_den_a1 vs stag_b2-guilds_den_b1 | 166.2 m vs 170.2 m (2.3 %) |
| F2 | stag_b1-guilds_den_b2 vs stag_b2-guilds_den_b1 | 166.2 m vs 170.2 m (2.3 %) |
| F2 | stag_a1-guilds_den_a2 vs stag_a2-guilds_den_a1 | 170.2 m vs 166.2 m (2.3 %) |
| F2 | stag_a1-guilds_den_a2 vs stag_b1-guilds_den_b2 | 170.2 m vs 166.2 m (2.3 %) |
| F2 | home_a_b1-cache_b_a1 vs home_a_b2-cache_b_a2 | 104.8 m vs 102.4 m (2.3 %) |
| F2 | keep_t3-tower_c_b1 vs keep_t4-tower_c_a1 | 102.3 m vs 104.7 m (2.3 %) |
| F2 | inn_a1-peddler_a1 vs inn_a2-peddler_a2 | 39.3 m vs 40.2 m (2.3 %) |
| F2 | inn_a1-peddler_a1 vs inn_b1-peddler_b1 | 39.3 m vs 40.2 m (2.3 %) |
| F2 | inn_b1-peddler_b1 vs inn_b2-peddler_b2 | 40.2 m vs 39.3 m (2.3 %) |
| F2 | inn_a2-peddler_a2 vs inn_b2-peddler_b2 | 40.2 m vs 39.3 m (2.3 %) |
| F2 | home_b_b1-wallow_a1 vs home_b_b2-wallow_a2 | 185.7 m vs 181.4 m (2.3 %) |
| F2 | rich_node_b1-tower_c_b2 vs rich_node_b2-tower_c_b1 | 60.1 m vs 61.6 m (2.3 %) |
| F2 | rich_node_a1-tower_c_a2 vs rich_node_b1-tower_c_b2 | 61.6 m vs 60.1 m (2.3 %) |
| F2 | post_s_a2-peddler_b1 vs post_s_b1-peddler_a2 | 101.8 m vs 104.2 m (2.3 %) |
| F2 | home_a_a1-rich_node_b1 vs home_a_b1-rich_node_a1 | 115.2 m vs 118.0 m (2.3 %) |
| F2 | well_a2-post_w_b1 vs well_b2-post_w_a1 | 132.7 m vs 129.6 m (2.3 %) |
| F2 | home_b_b1-nat_node_a2 vs home_b_b2-nat_node_a1 | 105.9 m vs 108.5 m (2.3 %) |
| F2 | rich_node_a2-tower_c_a1 vs rich_node_b1-tower_c_b2 | 61.6 m vs 60.1 m (2.3 %) |
| F2 | tower_c_a1-x_bridge_n vs tower_c_b1-x_bridge_s | 76.6 m vs 78.5 m (2.3 %) |
| F2 | home_b_a2-wallow_b2 vs home_b_b2-wallow_a2 | 185.7 m vs 181.4 m (2.3 %) |
| F2 | shrine_a1-wallow_a2 vs shrine_b2-wallow_b1 | 65.4 m vs 66.9 m (2.3 %) |
| F2 | home_b_a1-nat_node_b2 vs home_b_b1-nat_node_a2 | 108.5 m vs 105.9 m (2.3 %) |
| F2 | home_a_b1-cache_a_a2 vs home_a_b2-cache_a_a1 | 128.1 m vs 131.2 m (2.3 %) |
| F2 | nat_node_a1-guilds_lodge_a2 vs nat_node_b2-guilds_lodge_b1 | 110.1 m vs 107.6 m (2.3 %) |
| F2 | shrine_a1-lairs_two_b1 vs shrine_a2-lairs_two_b2 | 138.5 m vs 135.3 m (2.3 %) |
| F2 | rich_node_a1-post_s_b1 vs rich_node_b1-post_s_a1 | 144.6 m vs 141.3 m (2.3 %) |
| F2 | home_b_a2-nat_node_b1 vs home_b_b2-nat_node_a1 | 106.0 m vs 108.5 m (2.3 %) |
| F2 | guilds_lodge_a1-cache_b_a1 vs guilds_lodge_a2-cache_b_a2 | 89.3 m vs 91.4 m (2.3 %) |
| F2 | guilds_lodge_a2-cache_b_a2 vs guilds_lodge_b2-cache_b_b2 | 91.4 m vs 89.3 m (2.3 %) |
| F2 | guilds_lodge_a1-cache_b_a1 vs guilds_lodge_b1-cache_b_b1 | 89.3 m vs 91.4 m (2.3 %) |
| F2 | guilds_lodge_b1-cache_b_b1 vs guilds_lodge_b2-cache_b_b2 | 91.4 m vs 89.3 m (2.3 %) |
| F2 | home_a_a1-lairs_two_b1 vs home_a_b1-lairs_two_a1 | 157.7 m vs 161.4 m (2.3 %) |
| F2 | shrine_a1-lairs_two_b1 vs shrine_b1-lairs_two_a1 | 138.5 m vs 135.3 m (2.3 %) |
| F2 | shrine_a2-peddler_b1 vs shrine_b2-peddler_a1 | 127.8 m vs 124.9 m (2.3 %) |
| F2 | wallow_a1-guilds_lodge_b1 vs wallow_b2-guilds_lodge_a2 | 214.4 m vs 209.5 m (2.3 %) |
| F2 | home_a_a1-cache_b_b1 vs home_a_a2-cache_b_b2 | 102.5 m vs 104.9 m (2.3 %) |
| F2 | guilds_lodge_b1-lairs_two_b2 vs guilds_lodge_b2-lairs_two_b1 | 162.6 m vs 166.4 m (2.3 %) |
| F2 | guilds_lodge_a1-lairs_two_a2 vs guilds_lodge_b1-lairs_two_b2 | 166.4 m vs 162.6 m (2.3 %) |
| F2 | home_a_a1-lairs_two_b1 vs home_a_a2-lairs_two_b2 | 157.7 m vs 161.4 m (2.3 %) |
| F2 | home_b_a1-nat_node_b2 vs home_b_a2-nat_node_b1 | 108.5 m vs 106.0 m (2.3 %) |
| F2 | wallow_a1-lairs_two_a2 vs wallow_b1-lairs_two_b2 | 143.6 m vs 140.3 m (2.3 %) |
| F2 | wallow_a1-lairs_two_a2 vs wallow_a2-lairs_two_a1 | 143.6 m vs 140.3 m (2.3 %) |
| F2 | cache_a_a1-lairs_two_b1 vs cache_a_a2-lairs_two_b2 | 183.3 m vs 179.1 m (2.3 %) |
| F2 | inn_a2-guilds_lodge_a2 vs inn_b2-guilds_lodge_b2 | 76.4 m vs 74.7 m (2.3 %) |
| F2 | inn_a1-guilds_lodge_a1 vs inn_b1-guilds_lodge_b1 | 74.7 m vs 76.4 m (2.3 %) |
| F2 | inn_a1-guilds_lodge_a1 vs inn_a2-guilds_lodge_a2 | 74.7 m vs 76.4 m (2.3 %) |
| F2 | inn_b1-guilds_lodge_b1 vs inn_b2-guilds_lodge_b2 | 76.4 m vs 74.7 m (2.3 %) |
| F2 | home_b_b1-third_node_a1 vs home_b_b2-third_node_a2 | 189.5 m vs 185.2 m (2.3 %) |
| F2 | rich_node_a2-guilds_den_a2 vs rich_node_b1-guilds_den_b1 | 69.1 m vs 67.5 m (2.3 %) |
| F2 | guilds_lodge_a2-lairs_two_a1 vs guilds_lodge_b2-lairs_two_b1 | 162.6 m vs 166.4 m (2.3 %) |
| F2 | guilds_lodge_a1-lairs_two_a2 vs guilds_lodge_a2-lairs_two_a1 | 166.4 m vs 162.6 m (2.3 %) |
| F2 | rich_node_a1-post_s_b1 vs rich_node_a2-post_s_b2 | 144.6 m vs 141.3 m (2.3 %) |
| F2 | home_b_a2-third_node_b2 vs home_b_b2-third_node_a2 | 189.5 m vs 185.2 m (2.3 %) |
| F2 | home_a_a1-cache_b_b1 vs home_a_b1-cache_b_a1 | 102.5 m vs 104.8 m (2.3 %) |
| F2 | keep_t1-nat_node_a2 vs keep_t4-nat_node_a1 | 107.4 m vs 109.9 m (2.3 %) |
| F2 | rich_node_a1-guilds_lodge_b1 vs rich_node_a2-guilds_lodge_b2 | 159.4 m vs 163.1 m (2.3 %) |
| F2 | shrine_a1-inn_b2 vs shrine_b2-inn_a1 | 88.7 m vs 86.7 m (2.3 %) |
| F2 | inn_a2-peddler_b1 vs inn_b1-peddler_a2 | 102.4 m vs 100.1 m (2.3 %) |
| F2 | keep_t0-nat_node_b2 vs keep_t1-nat_node_a2 | 109.9 m vs 107.4 m (2.3 %) |
| F2 | keep_t3-nat_node_b1 vs keep_t4-nat_node_a1 | 107.5 m vs 109.9 m (2.2 %) |
| F2 | tower_c_b1-post_s_b2 vs tower_c_b2-post_s_b1 | 87.1 m vs 89.0 m (2.2 %) |
| F2 | tower_c_a2-post_s_a1 vs tower_c_b2-post_s_b1 | 87.1 m vs 89.0 m (2.2 %) |
| F2 | post_s_a2-lairs_two_b2 vs post_s_b1-lairs_two_a1 | 177.4 m vs 173.4 m (2.2 %) |
| F2 | stag_a2-peddler_b2 vs stag_b1-peddler_a1 | 141.2 m vs 138.0 m (2.2 %) |
| F2 | rich_node_a1-guilds_lodge_b1 vs rich_node_b1-guilds_lodge_a1 | 159.4 m vs 163.0 m (2.2 %) |
| F2 | post_s_a1-lairs_one_b1 vs post_s_b1-lairs_one_a1 | 185.8 m vs 181.6 m (2.2 %) |
| F2 | keep_t0-nat_node_b2 vs keep_t3-nat_node_b1 | 109.9 m vs 107.5 m (2.2 %) |
| F2 | third_node_a2-shrine_b2 vs third_node_b1-shrine_a1 | 156.1 m vs 159.6 m (2.2 %) |
| F2 | shrine_a1-cache_a_b2 vs shrine_b1-cache_a_a2 | 114.4 m vs 111.8 m (2.2 %) |
| F2 | rich_node_a1-x_bridge_n vs rich_node_b1-x_bridge_s | 124.3 m vs 127.1 m (2.2 %) |
| F2 | well_b1-guilds_lodge_a2 vs well_b2-guilds_lodge_a1 | 126.3 m vs 129.2 m (2.2 %) |
| F2 | well_a1-guilds_lodge_b2 vs well_b1-guilds_lodge_a2 | 129.2 m vs 126.3 m (2.2 %) |
| F2 | home_b_a1-cache_a_b2 vs home_b_b1-cache_a_a2 | 117.1 m vs 114.5 m (2.2 %) |
| F2 | home_b_b1-cache_a_a2 vs home_b_b2-cache_a_a1 | 114.5 m vs 117.1 m (2.2 %) |
| F2 | tower_c_a1-x_bridge_n vs tower_c_a2-x_bridge_s | 76.6 m vs 78.4 m (2.2 %) |
| F2 | shrine_a1-cache_a_b2 vs shrine_a2-cache_a_b1 | 114.4 m vs 111.9 m (2.2 %) |
| F2 | home_b_a1-lairs_one_b1 vs home_b_a2-lairs_one_b2 | 182.2 m vs 186.3 m (2.2 %) |
| F2 | home_b_a1-lairs_one_b1 vs home_b_b1-lairs_one_a1 | 182.2 m vs 186.3 m (2.2 %) |
| F2 | tower_c_b1-x_bridge_s vs tower_c_b2-x_bridge_n | 78.5 m vs 76.7 m (2.2 %) |
| F2 | home_a_b1-well_a2 vs home_a_b2-well_a1 | 115.8 m vs 118.4 m (2.2 %) |
| F2 | home_a_a2-well_b1 vs home_a_b2-well_a1 | 115.8 m vs 118.4 m (2.2 %) |
| F2 | post_s_b1-lairs_one_a1 vs post_s_b2-lairs_one_a2 | 181.6 m vs 185.7 m (2.2 %) |
| F2 | home_a_a1-well_b2 vs home_a_b1-well_a2 | 118.4 m vs 115.8 m (2.2 %) |
| F2 | home_a_a1-well_b2 vs home_a_a2-well_b1 | 118.4 m vs 115.8 m (2.2 %) |
| F2 | rich_node_a2-x_bridge_s vs rich_node_b1-x_bridge_s | 124.4 m vs 127.1 m (2.2 %) |
| F2 | guilds_lodge_a2-x_ford_s vs guilds_lodge_b2-x_ford_n | 138.8 m vs 141.9 m (2.2 %) |
| F2 | guilds_lodge_a1-x_ford_n vs guilds_lodge_a2-x_ford_s | 141.9 m vs 138.8 m (2.2 %) |
| F2 | home_b_a2-third_node_b1 vs home_b_b1-third_node_a2 | 149.2 m vs 146.0 m (2.2 %) |
| F2 | post_w_a1-cache_a_a2 vs post_w_a2-cache_a_a1 | 85.1 m vs 87.0 m (2.2 %) |
| F2 | post_w_a1-cache_a_a2 vs post_w_b1-cache_a_b2 | 85.1 m vs 87.0 m (2.2 %) |
| F2 | post_w_a2-cache_a_a1 vs post_w_b2-cache_a_b1 | 87.0 m vs 85.1 m (2.2 %) |
| F2 | post_w_b1-cache_a_b2 vs post_w_b2-cache_a_b1 | 87.0 m vs 85.1 m (2.2 %) |
| F2 | post_s_a1-cache_a_b2 vs post_s_a2-cache_a_b1 | 70.5 m vs 72.1 m (2.2 %) |
| F2 | rich_node_a1-guilds_den_a1 vs rich_node_b1-guilds_den_b1 | 69.0 m vs 67.5 m (2.2 %) |
| F2 | rich_node_b1-guilds_den_b1 vs rich_node_b2-guilds_den_b2 | 67.5 m vs 69.0 m (2.2 %) |
| F2 | rich_node_b1-x_bridge_s vs rich_node_b2-x_bridge_n | 127.1 m vs 124.4 m (2.2 %) |
| F2 | guilds_lodge_a1-x_ford_n vs guilds_lodge_b1-x_ford_s | 141.9 m vs 138.9 m (2.2 %) |
| F2 | guilds_lodge_b1-x_ford_s vs guilds_lodge_b2-x_ford_n | 138.9 m vs 141.9 m (2.2 %) |
| F2 | inn_a2-lairs_two_a2 vs inn_b1-lairs_two_b1 | 60.0 m vs 61.4 m (2.1 %) |
| F2 | inn_b1-lairs_two_b1 vs inn_b2-lairs_two_b2 | 61.4 m vs 60.0 m (2.1 %) |
| F2 | inn_a1-lairs_two_a1 vs inn_b1-lairs_two_b1 | 60.0 m vs 61.4 m (2.1 %) |
| F2 | home_a_a1-tower_r_b1 vs home_a_a2-tower_r_b2 | 126.4 m vs 129.2 m (2.1 %) |
| F2 | tower_r_b1-peddler_b1 vs tower_r_b2-peddler_b2 | 64.2 m vs 65.6 m (2.1 %) |
| F2 | tower_r_a1-peddler_a1 vs tower_r_b1-peddler_b1 | 65.6 m vs 64.2 m (2.1 %) |
| F2 | post_s_a2-cache_a_b1 vs post_s_b2-cache_a_a1 | 72.1 m vs 70.6 m (2.1 %) |
| F2 | post_s_a2-lairs_one_b2 vs post_s_b1-lairs_one_a1 | 185.6 m vs 181.6 m (2.1 %) |
| F2 | shrine_a1-guilds_lodge_b2 vs shrine_a2-guilds_lodge_b1 | 150.9 m vs 154.2 m (2.1 %) |
| F2 | nat_node_a2-peddler_b1 vs nat_node_b1-peddler_a2 | 109.9 m vs 107.6 m (2.1 %) |
| F2 | tower_c_a2-x_bridge_s vs tower_c_b2-x_bridge_n | 78.4 m vs 76.7 m (2.1 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t4-tower_r_a2 | 131.9 m vs 134.7 m (2.1 %) |
| F2 | third_node_a1-inn_b2 vs third_node_b1-inn_a2 | 122.6 m vs 120.1 m (2.1 %) |
| F2 | home_a_a1-tower_r_b1 vs home_a_b1-tower_r_a1 | 126.4 m vs 129.1 m (2.1 %) |
| F2 | third_node_b1-inn_a2 vs third_node_b2-inn_a1 | 120.1 m vs 122.6 m (2.1 %) |
| F2 | home_a_a2-guilds_den_b1 vs home_a_b2-guilds_den_a1 | 166.8 m vs 163.3 m (2.1 %) |
| F2 | home_a_a1-guilds_den_b2 vs home_a_a2-guilds_den_b1 | 163.3 m vs 166.8 m (2.1 %) |
| F2 | third_node_a1-inn_b2 vs third_node_a2-inn_b1 | 122.6 m vs 120.1 m (2.1 %) |
| F2 | rich_node_a2-crown vs rich_node_b1-crown | 67.0 m vs 65.7 m (2.0 %) |
| F2 | third_node_a2-inn_b1 vs third_node_b2-inn_a1 | 120.1 m vs 122.6 m (2.0 %) |
| F2 | post_w_b1-lairs_two_a2 vs post_w_b2-lairs_two_a1 | 153.1 m vs 150.0 m (2.0 %) |
| F2 | post_w_a1-lairs_two_b2 vs post_w_b1-lairs_two_a2 | 150.0 m vs 153.1 m (2.0 %) |
| F2 | keep_t3-tower_r_a2 vs keep_t1-tower_r_b1 | 62.7 m vs 61.4 m (2.0 %) |
| F2 | post_s_a2-guilds_den_b2 vs post_s_b1-guilds_den_a1 | 193.4 m vs 189.4 m (2.0 %) |
| F2 | post_s_a2-guilds_lodge_b2 vs post_s_b1-guilds_lodge_a1 | 193.5 m vs 189.6 m (2.0 %) |
| F2 | home_b_a1-tower_r_b1 vs home_b_b2-tower_r_a2 | 136.1 m vs 139.0 m (2.0 %) |
| F2 | keep_t1-wallow_a1 vs keep_t4-wallow_a2 | 180.8 m vs 177.2 m (2.0 %) |
| F2 | tower_r_a1-peddler_b2 vs tower_r_a2-peddler_b1 | 93.3 m vs 91.4 m (2.0 %) |
| F2 | rich_node_a2-crown vs rich_node_b2-crown | 67.0 m vs 65.7 m (2.0 %) |
| F2 | rich_node_a1-crown vs rich_node_a2-crown | 65.7 m vs 67.0 m (2.0 %) |
| F2 | keep_t3-wallow_b2 vs keep_t4-wallow_a2 | 180.8 m vs 177.2 m (2.0 %) |
| F2 | stag_b1-post_s_a2 vs stag_b2-post_s_a1 | 61.0 m vs 59.8 m (2.0 %) |
| F2 | inn_a1-lairs_two_a2 vs inn_b2-lairs_two_b1 | 104.4 m vs 106.5 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 97 sources) 1568.85 s.
- Map Lab v2 (map-production.md 2.5): layout quartermeet, 4 seats, rules tempo standard, 2 fixable findings.
- Navmesh raster 75.69 s (1129 polygons, 495616 cells of 0.25 m), spot / mirror checks 74.91 s, 4656 paths 66.50 s.
- Map Quartermeet (2v2), scene res://docs/tools/world_forge/out/quartermeet/preview.tscn, sim mode off; level load + navmesh bake 16.1 s (1032 frames), lab 1789.6 s. Spec: docs/design/map-production.md.
