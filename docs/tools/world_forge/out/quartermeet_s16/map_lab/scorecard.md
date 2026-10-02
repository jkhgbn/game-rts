# Map Lab: Quartermeet (seed 16) scorecard: world_forge_quartermeet_s16

2026-10-02 18:54 · lab v1.0 · 220.11 s · scanned 97 spots

## Result: **WARN** · score **95 / 100**

0 FAIL · 4 WARN · 15 PASS · 2 info checks; findings: 0 FAIL, 488 WARN, 732 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): post_s_a2-lairs_two_b2 vs post_s_b1-lairs_two_a1: 228.8 m vs 177.8 m (22.3 %) -> units walk post_s_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 5782 / 6982 pairs within 2 % (0 FAIL, 473 WARN, 727 info))_
2. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest enemy keep: 135.8 m vs 138.7 m between seats (2.1 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 9 / 10 clean (0 FAIL, 1 WARN))_
3. **Main routes: narrowest corridor matches the twin** (WARN): keep_t0 -> keep_t4: narrowest 2.1 m at (9.5, 42.1) vs its twin's 5.8 m -> a collider narrows this route only on one side _(from C2 9 / 12 clean (0 FAIL, 6 WARN))_
4. **Clearances (roads, crossings)** (WARN): well_a1: point 3.7 m from a road centre line (want >= 7) -> push it off the road (auto-fix) _(from R4 83 / 91 clean (0 FAIL, 8 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 1116 polygons, main area 28977 m² (94 % of the 176 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 97 / 97 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 4 / 4 clean, 5 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 176 x 176 m ok, 91 spots ok, 2.2x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 97 / 97 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 97 / 97 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (8 cells), 0.00 % (8 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6982 / 6982 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 5782 / 6982 pairs within 2 % (0 FAIL, 473 WARN, 727 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 66 | 9 / 10 clean (0 FAIL, 1 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | PASS 100 | 4 / 4 clean | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep, ally / nearest enemy 0.33-0.50 |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 7 / 7 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | PASS 100 | 24 / 24 clean | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
| R2 | Content per seat (Crown Hollow per side) | PASS 100 | 60 / 60 clean | new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL |  |
| R3 | Contested + raidable objectives per seat | PASS 100 | 4 / 4 clean | own / nearest enemy path 0.9-1.1 (contested) or 1.1-1.45 (raidable): >= 3 per seat |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 6 / 6 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | **WARN** 61 | 9 / 12 clean (0 FAIL, 6 WARN) | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | **WARN** 66 | 83 / 91 clean (0 FAIL, 8 WARN) | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (704 x 704 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | post_s_a2-lairs_two_b2 vs post_s_b1-lairs_two_a1 | 228.8 m vs 177.8 m (22.3 %) | units walk post_s_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-lairs_two_b2 vs post_s_b2-lairs_two_a2 | 228.8 m vs 177.9 m (22.3 %) | units walk post_s_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-lairs_two_b1 vs post_s_a2-lairs_two_b2 | 178.1 m vs 228.8 m (22.2 %) | units walk post_s_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-stag_b2 vs tower_r_b2-stag_a2 | 195.0 m vs 152.0 m (22.1 %) | units walk tower_r_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_b1 vs tower_r_a2-stag_b2 | 152.1 m vs 195.0 m (22.0 %) | units walk tower_r_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_a1 vs shrine_a2-stag_a2 | 81.4 m vs 64.8 m (20.3 %) | units walk shrine_a1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_a1 vs shrine_b1-stag_b1 | 81.4 m vs 64.8 m (20.3 %) | units walk shrine_a1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-stag_b2 vs shrine_b2-stag_b1 | 86.5 m vs 106.2 m (18.6 %) | units walk shrine_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-stag_a1 vs shrine_b2-stag_b1 | 86.5 m vs 106.2 m (18.6 %) | units walk shrine_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-stag_a2 vs shrine_b2-stag_b2 | 64.8 m vs 79.5 m (18.4 %) | units walk shrine_b2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-stag_b1 vs shrine_b2-stag_b2 | 64.8 m vs 79.5 m (18.4 %) | units walk shrine_b2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-stag_a1 vs rich_node_b1-stag_b2 | 156.7 m vs 128.0 m (18.3 %) | units walk rich_node_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_a2 vs rich_node_a2-stag_a1 | 128.0 m vs 156.7 m (18.3 %) | units walk rich_node_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-stag_a1 vs rich_node_b2-stag_b1 | 156.7 m vs 128.0 m (18.3 %) | units walk rich_node_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-cache_a_a1 vs rich_node_b1-cache_a_b2 | 147.8 m vs 121.1 m (18.0 %) | units walk rich_node_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-cache_a_a2 vs rich_node_a2-cache_a_a1 | 121.2 m vs 147.8 m (18.0 %) | units walk rich_node_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-cache_a_a1 vs rich_node_b2-cache_a_b1 | 147.8 m vs 121.2 m (18.0 %) | units walk rich_node_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-peddler_b2 vs rich_node_b2-peddler_b1 | 89.6 m vs 108.4 m (17.4 %) | units walk rich_node_b2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-peddler_a2 vs rich_node_b2-peddler_b1 | 89.6 m vs 108.4 m (17.4 %) | units walk rich_node_b2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-peddler_a1 vs rich_node_b1-peddler_b2 | 108.3 m vs 89.6 m (17.3 %) | units walk rich_node_a2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-peddler_a2 vs rich_node_a2-peddler_a1 | 89.6 m vs 108.3 m (17.3 %) | units walk rich_node_a2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-well_a1 vs third_node_a2-well_a2 | 48.8 m vs 40.3 m (17.3 %) | units walk third_node_a1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-well_a1 vs third_node_b1-well_b1 | 48.8 m vs 40.3 m (17.3 %) | units walk third_node_a1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-well_a2 vs third_node_b2-well_b2 | 40.3 m vs 48.8 m (17.3 %) | units walk third_node_b2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-well_b1 vs third_node_b2-well_b2 | 40.3 m vs 48.8 m (17.3 %) | units walk third_node_b2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-stag_a1 vs home_b_b1-stag_b2 | 138.8 m vs 115.8 m (16.6 %) | units walk home_b_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_two_a1 vs rich_node_b1-lairs_two_b2 | 162.9 m vs 136.3 m (16.4 %) | units walk rich_node_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_two_a2 vs rich_node_a2-lairs_two_a1 | 136.3 m vs 162.9 m (16.3 %) | units walk rich_node_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_two_a1 vs rich_node_b2-lairs_two_b1 | 162.9 m vs 136.3 m (16.3 %) | units walk rich_node_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-stag_a1 vs home_b_b2-stag_b1 | 138.8 m vs 116.8 m (15.9 %) | units walk home_b_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-stag_a2 vs home_b_a2-stag_a1 | 116.8 m vs 138.8 m (15.9 %) | units walk home_b_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-wallow_b2 vs rich_node_b2-wallow_b1 | 118.8 m vs 138.0 m (13.9 %) | units walk rich_node_b2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_a2 vs rich_node_b2-wallow_b1 | 118.8 m vs 138.0 m (13.9 %) | units walk rich_node_b2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-wallow_a1 vs rich_node_b1-wallow_b2 | 137.9 m vs 118.8 m (13.9 %) | units walk rich_node_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_a2 vs rich_node_a2-wallow_a1 | 118.8 m vs 137.9 m (13.9 %) | units walk rich_node_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-stag_b2 vs tower_r_b1-stag_a1 | 195.0 m vs 168.5 m (13.6 %) | units walk tower_r_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-third_node_a2 vs rich_node_a2-third_node_a1 | 132.9 m vs 153.1 m (13.2 %) | units walk rich_node_a2-third_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-third_node_a1 vs rich_node_b2-third_node_b1 | 153.1 m vs 132.9 m (13.2 %) | units walk rich_node_a2-third_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-third_node_a1 vs rich_node_b1-third_node_b2 | 153.1 m vs 133.0 m (13.1 %) | units walk rich_node_a2-third_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_one_a2 vs tower_r_b2-lairs_one_b2 | 61.6 m vs 53.8 m (12.7 %) | units walk tower_r_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_a1 vs tower_r_a2-lairs_one_a2 | 53.8 m vs 61.6 m (12.7 %) | units walk tower_r_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_one_b1 vs tower_r_b2-lairs_one_b2 | 61.6 m vs 53.8 m (12.7 %) | units walk tower_r_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_a1 vs tower_r_b1-lairs_one_b1 | 53.8 m vs 61.6 m (12.7 %) | units walk tower_r_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-stag_a1 vs well_b2-stag_b1 | 141.6 m vs 124.2 m (12.3 %) | units walk well_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-stag_a2 vs well_a2-stag_a1 | 124.2 m vs 141.6 m (12.3 %) | units walk well_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-stag_a1 vs well_b1-stag_b2 | 141.6 m vs 124.2 m (12.3 %) | units walk well_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-guilds_den_a2 vs rich_node_b2-guilds_den_b1 | 147.9 m vs 168.3 m (12.1 %) | units walk rich_node_b2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-guilds_den_a1 vs rich_node_b2-guilds_den_b1 | 148.0 m vs 168.3 m (12.1 %) | units walk rich_node_b2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-guilds_den_b2 vs rich_node_b2-guilds_den_b1 | 148.0 m vs 168.3 m (12.1 %) | units walk rich_node_b2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-cache_b_b2 vs tower_c_b1-cache_b_a1 | 59.8 m vs 68.0 m (12.0 %) | units walk tower_c_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-guilds_lodge_a1 vs stag_b2-guilds_lodge_a2 | 215.3 m vs 189.6 m (12.0 %) | units walk stag_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-cache_b_a1 vs tower_c_b2-cache_b_a2 | 68.0 m vs 59.9 m (11.9 %) | units walk tower_c_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-cache_b_b1 vs tower_c_b1-cache_b_a1 | 59.9 m vs 68.0 m (11.9 %) | units walk tower_c_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-peddler_b1 vs tower_r_b2-peddler_a2 | 139.2 m vs 122.6 m (11.9 %) | units walk tower_r_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-peddler_b1 vs tower_r_a2-peddler_b2 | 139.2 m vs 122.6 m (11.9 %) | units walk tower_r_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_one_a1 vs tower_r_b2-lairs_one_a2 | 172.0 m vs 195.1 m (11.8 %) | units walk tower_r_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-peddler_a1 vs tower_r_b2-peddler_a2 | 139.0 m vs 122.6 m (11.8 %) | units walk tower_r_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-peddler_b2 vs tower_r_b1-peddler_a1 | 122.6 m vs 139.0 m (11.8 %) | units walk tower_r_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-cache_b_b2 vs nat_node_b2-cache_b_a2 | 89.5 m vs 78.9 m (11.8 %) | units walk nat_node_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_one_b2 vs tower_r_b2-lairs_one_a2 | 172.2 m vs 195.1 m (11.8 %) | units walk tower_r_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-cache_b_b1 vs nat_node_a2-cache_b_b2 | 79.0 m vs 89.5 m (11.7 %) | units walk nat_node_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_b1 vs tower_r_b2-lairs_one_a2 | 172.4 m vs 195.1 m (11.7 %) | units walk tower_r_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_a2 vs keep_t3-nat_node_a1 | 67.4 m vs 59.6 m (11.6 %) | units walk keep_t0-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_a2 vs keep_t4-nat_node_b1 | 67.4 m vs 59.7 m (11.5 %) | units walk keep_t0-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-cache_b_b2 vs nat_node_b1-cache_b_a1 | 89.5 m vs 79.2 m (11.5 %) | units walk nat_node_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-nat_node_a2 vs keep_t1-nat_node_b2 | 67.4 m vs 59.8 m (11.4 %) | units walk keep_t0-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_a2 vs tower_r_b2-stag_b1 | 139.5 m vs 157.3 m (11.3 %) | units walk tower_r_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-stag_b2 vs tower_r_b2-stag_b1 | 139.5 m vs 157.3 m (11.3 %) | units walk tower_r_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-rich_node_a1 vs home_b_b2-rich_node_a2 | 120.4 m vs 135.8 m (11.3 %) | units walk home_b_b2-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_a2 vs tower_r_a2-stag_a1 | 139.5 m vs 157.1 m (11.2 %) | units walk tower_r_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-stag_a1 vs tower_r_b1-stag_b2 | 157.1 m vs 139.5 m (11.2 %) | units walk tower_r_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_lane_e vs third_node_b1-x_lane_w | 128.8 m vs 114.4 m (11.2 %) | units walk third_node_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_lane_e vs third_node_a2-x_lane_e | 128.8 m vs 114.4 m (11.2 %) | units walk third_node_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-x_lane_w vs third_node_b2-x_lane_w | 114.4 m vs 128.8 m (11.2 %) | units walk third_node_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-x_lane_e vs third_node_b2-x_lane_w | 114.4 m vs 128.8 m (11.2 %) | units walk third_node_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_a2 vs shrine_b2-stag_b1 | 94.4 m vs 106.2 m (11.1 %) | units walk shrine_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-stag_b2 vs rich_node_b2-stag_a2 | 157.1 m vs 139.7 m (11.1 %) | units walk rich_node_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-well_b2 vs rich_node_b2-well_a1 | 66.6 m vs 59.2 m (11.1 %) | units walk rich_node_a1-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_b1 vs rich_node_a2-stag_b2 | 139.8 m vs 157.1 m (11.0 %) | units walk rich_node_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-stag_a1 vs rich_node_b2-stag_a2 | 157.0 m vs 139.7 m (11.0 %) | units walk rich_node_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_b1 vs rich_node_b1-stag_a1 | 139.8 m vs 157.0 m (10.9 %) | units walk rich_node_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-x_ford_s vs peddler_b2-x_ford_n | 85.9 m vs 96.1 m (10.6 %) | units walk peddler_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-well_b2 vs tower_c_b1-well_a2 | 76.4 m vs 85.4 m (10.6 %) | units walk tower_c_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-well_b2 vs tower_c_a2-well_b1 | 76.4 m vs 85.4 m (10.6 %) | units walk tower_c_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-guilds_lodge_b2 vs well_b2-guilds_lodge_a2 | 201.0 m vs 179.8 m (10.6 %) | units walk well_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-guilds_lodge_b1 vs well_a2-guilds_lodge_b2 | 179.9 m vs 201.0 m (10.5 %) | units walk well_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-peddler_b1 vs post_s_b2-peddler_a2 | 148.7 m vs 133.1 m (10.5 %) | units walk post_s_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-well_a2 vs tower_c_b2-well_a1 | 85.4 m vs 76.5 m (10.5 %) | units walk tower_c_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-well_b1 vs tower_c_b2-well_a1 | 85.4 m vs 76.5 m (10.5 %) | units walk tower_c_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-well_a2 vs rich_node_b2-well_a1 | 66.1 m vs 59.2 m (10.5 %) | units walk rich_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-well_b1 vs rich_node_b2-well_a1 | 66.1 m vs 59.2 m (10.5 %) | units walk rich_node_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-peddler_b1 vs post_s_a2-peddler_b2 | 148.7 m vs 133.1 m (10.5 %) | units walk post_s_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-peddler_a1 vs post_s_b2-peddler_a2 | 148.6 m vs 133.1 m (10.5 %) | units walk post_s_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-peddler_b2 vs post_s_b1-peddler_a1 | 133.1 m vs 148.6 m (10.5 %) | units walk post_s_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-stag_a1 vs home_b_b2-stag_a2 | 150.9 m vs 168.5 m (10.4 %) | units walk home_b_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-x_ford_s vs keep_t4-x_ford_n | 95.3 m vs 106.4 m (10.4 %) | units walk keep_t4-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-ford_nest_a1 vs keep_t4-ford_nest_a2 | 95.3 m vs 106.4 m (10.4 %) | units walk keep_t4-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-post_w_a1 vs third_node_b2-post_w_a2 | 178.0 m vs 198.7 m (10.4 %) | units walk third_node_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-cache_a_a1 vs post_s_b1-cache_a_b2 | 163.2 m vs 146.2 m (10.4 %) | units walk post_s_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-stag_a2 vs third_node_b2-stag_b1 | 147.6 m vs 164.7 m (10.4 %) | units walk third_node_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-cache_a_b2 vs post_s_b2-cache_a_b1 | 146.2 m vs 163.1 m (10.4 %) | units walk post_s_b2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_a_a2 vs post_s_b1-cache_a_b2 | 163.1 m vs 146.2 m (10.4 %) | units walk post_s_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-post_w_b2 vs third_node_b2-post_w_a2 | 178.1 m vs 198.7 m (10.4 %) | units walk third_node_b2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_c_b1 vs third_node_a2-tower_c_b2 | 138.6 m vs 124.2 m (10.4 %) | units walk third_node_a1-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-tower_c_b2 vs third_node_b2-tower_c_a2 | 124.2 m vs 138.6 m (10.4 %) | units walk third_node_b2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-shrine_a1 vs third_node_b2-shrine_a2 | 152.1 m vs 169.5 m (10.3 %) | units walk third_node_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-shrine_b2 vs third_node_b2-shrine_a2 | 152.1 m vs 169.5 m (10.3 %) | units walk third_node_b2-shrine_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-peddler_b1 vs stag_b2-peddler_a2 | 159.7 m vs 143.3 m (10.3 %) | units walk stag_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-peddler_b1 vs stag_a2-peddler_b2 | 159.7 m vs 143.3 m (10.2 %) | units walk stag_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-peddler_a1 vs stag_b2-peddler_a2 | 159.5 m vs 143.3 m (10.2 %) | units walk stag_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-peddler_b2 vs stag_b1-peddler_a1 | 143.3 m vs 159.5 m (10.2 %) | units walk stag_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-stag_a2 vs third_node_b1-stag_b2 | 147.6 m vs 164.3 m (10.1 %) | units walk third_node_b1-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-stag_a2 vs third_node_a2-stag_a1 | 147.6 m vs 164.3 m (10.1 %) | units walk third_node_a2-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_a2 vs third_node_b1-cache_a_b2 | 134.3 m vs 149.3 m (10.0 %) | units walk third_node_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_a_b2 vs third_node_b2-cache_a_b1 | 149.3 m vs 134.3 m (10.0 %) | units walk third_node_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-cache_b_a2 vs home_a_b1-cache_b_b2 | 88.3 m vs 79.6 m (9.9 %) | units walk home_a_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-x_ford_s vs stag_b2-x_ford_n | 114.7 m vs 127.2 m (9.8 %) | units walk stag_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-x_ford_n vs stag_a2-x_ford_s | 127.2 m vs 114.7 m (9.8 %) | units walk stag_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-x_ford_s vs stag_b1-x_ford_s | 114.7 m vs 127.1 m (9.8 %) | units walk stag_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-stag_a1 vs tower_r_b2-stag_a2 | 168.5 m vs 152.0 m (9.8 %) | units walk tower_r_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_den_b2 vs stag_b2-guilds_den_a2 | 223.4 m vs 201.6 m (9.7 %) | units walk stag_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_den_b1 vs stag_a2-guilds_den_b2 | 201.7 m vs 223.4 m (9.7 %) | units walk stag_a2-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-stag_b1 vs tower_r_b1-stag_a1 | 152.1 m vs 168.5 m (9.7 %) | units walk tower_r_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-tower_r_a1 vs home_b_b2-tower_r_a2 | 131.6 m vs 145.7 m (9.7 %) | units walk home_b_b2-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_b_b2 vs well_b1-cache_b_a1 | 104.5 m vs 115.5 m (9.5 %) | units walk well_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_node_b1 vs home_b_b2-rich_node_a2 | 122.9 m vs 135.8 m (9.5 %) | units walk home_b_b2-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-post_s_b1 vs nat_node_a2-post_s_b2 | 116.5 m vs 128.6 m (9.5 %) | units walk nat_node_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_s_b2 vs nat_node_b2-post_s_a2 | 128.6 m vs 116.5 m (9.4 %) | units walk nat_node_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-rich_node_a1 vs keep_t4-rich_node_a2 | 117.9 m vs 130.1 m (9.4 %) | units walk keep_t4-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_b1 vs third_node_b2-cache_b_a2 | 139.1 m vs 153.3 m (9.3 %) | units walk third_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-x_lane_e vs stag_b2-x_lane_w | 100.9 m vs 91.6 m (9.2 %) | units walk stag_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-x_lane_e vs stag_b1-x_lane_w | 100.9 m vs 91.6 m (9.2 %) | units walk stag_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_lodge_b1 vs tower_r_b2-guilds_lodge_a2 | 194.9 m vs 177.0 m (9.2 %) | units walk tower_r_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-guilds_lodge_a1 vs tower_r_b2-guilds_lodge_a2 | 194.8 m vs 177.0 m (9.2 %) | units walk tower_r_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_lodge_b1 vs tower_r_a2-guilds_lodge_b2 | 194.9 m vs 177.1 m (9.1 %) | units walk tower_r_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-guilds_lodge_b2 vs tower_r_b1-guilds_lodge_a1 | 177.1 m vs 194.8 m (9.1 %) | units walk tower_r_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-lairs_two_a2 vs inn_b1-lairs_two_b2 | 114.6 m vs 104.2 m (9.1 %) | units walk inn_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-lairs_two_a2 vs inn_a2-lairs_two_a1 | 114.6 m vs 104.2 m (9.1 %) | units walk inn_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_den_b1 vs tower_r_b2-guilds_den_a2 | 199.1 m vs 180.9 m (9.1 %) | units walk tower_r_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-x_lane_e vs stag_a2-x_lane_e | 100.9 m vs 91.7 m (9.1 %) | units walk stag_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-lairs_one_b2 vs well_b1-lairs_one_a2 | 123.6 m vs 112.3 m (9.1 %) | units walk well_a1-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_a2 vs home_a_b1-tower_c_b2 | 64.4 m vs 58.6 m (9.1 %) | units walk home_a_a1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-guilds_den_b1 vs tower_r_a2-guilds_den_b2 | 199.1 m vs 181.0 m (9.1 %) | units walk tower_r_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-x_ford_s vs well_b2-x_ford_n | 93.7 m vs 103.0 m (9.1 %) | units walk well_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-ford_nest_a1 vs well_b2-ford_nest_a2 | 93.7 m vs 103.0 m (9.1 %) | units walk well_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_ford_n vs well_a2-x_ford_s | 103.0 m vs 93.7 m (9.1 %) | units walk well_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-ford_nest_a2 vs well_a2-ford_nest_a1 | 103.0 m vs 93.7 m (9.1 %) | units walk well_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-lairs_two_a2 vs inn_b2-lairs_two_b1 | 114.6 m vs 104.2 m (9.1 %) | units walk inn_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-lairs_one_a2 vs well_b2-lairs_one_a1 | 112.3 m vs 123.5 m (9.1 %) | units walk well_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-guilds_den_a1 vs tower_r_b2-guilds_den_a2 | 199.0 m vs 180.9 m (9.1 %) | units walk tower_r_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-guilds_den_b2 vs tower_r_b1-guilds_den_a1 | 181.0 m vs 199.0 m (9.0 %) | units walk tower_r_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-x_ford_s vs well_b2-x_ford_n | 93.7 m vs 103.0 m (9.0 %) | units walk well_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-ford_nest_a2 vs well_b1-ford_nest_a1 | 103.0 m vs 93.7 m (9.0 %) | units walk well_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_ford_n vs well_b1-x_ford_s | 103.0 m vs 93.7 m (9.0 %) | units walk well_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-ford_nest_a1 vs well_b2-ford_nest_a2 | 93.7 m vs 103.0 m (9.0 %) | units walk well_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-lairs_one_b2 vs well_a2-lairs_one_b1 | 123.6 m vs 112.4 m (9.0 %) | units walk well_a1-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-lairs_one_b1 vs well_b2-lairs_one_a1 | 112.4 m vs 123.5 m (9.0 %) | units walk well_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-guilds_lodge_a1 vs well_b2-guilds_lodge_a2 | 197.5 m vs 179.8 m (9.0 %) | units walk well_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-guilds_lodge_b1 vs well_b1-guilds_lodge_a1 | 179.9 m vs 197.5 m (8.9 %) | units walk well_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-x_ford_n vs peddler_b2-x_ford_n | 87.5 m vs 96.1 m (8.9 %) | units walk peddler_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-guilds_lodge_b2 vs guilds_den_b2-guilds_lodge_a2 | 248.7 m vs 226.5 m (8.9 %) | units walk guilds_den_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-guilds_lodge_a1 vs guilds_den_b2-guilds_lodge_a2 | 248.7 m vs 226.5 m (8.9 %) | units walk guilds_den_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_a2-guilds_lodge_b2 | 226.6 m vs 248.7 m (8.9 %) | units walk guilds_den_a2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-stag_a1 vs keep_t4-stag_a2 | 148.4 m vs 162.8 m (8.9 %) | units walk keep_t4-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_b1-guilds_lodge_a1 | 226.6 m vs 248.7 m (8.9 %) | units walk guilds_den_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_two_a1 vs home_b_b1-lairs_two_b2 | 119.6 m vs 131.0 m (8.7 %) | units walk home_b_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_two_a2 vs home_b_b1-lairs_two_b2 | 119.6 m vs 131.0 m (8.7 %) | units walk home_b_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-cache_b_b2 vs inn_b1-cache_b_a1 | 75.9 m vs 83.0 m (8.6 %) | units walk inn_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-cache_b_a1 vs cache_a_b2-cache_b_a2 | 130.8 m vs 119.6 m (8.6 %) | units walk cache_a_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_a2 vs guilds_lodge_b1-cache_a_b2 | 145.3 m vs 158.9 m (8.6 %) | units walk guilds_lodge_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_a_b2 vs guilds_lodge_b2-cache_a_b1 | 158.9 m vs 145.3 m (8.6 %) | units walk guilds_lodge_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-cache_b_b2 vs cache_a_b1-cache_b_a1 | 119.6 m vs 130.8 m (8.6 %) | units walk cache_a_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_a2 vs shrine_b1-inn_b2 | 45.1 m vs 41.2 m (8.5 %) | units walk shrine_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_a2 vs shrine_a2-inn_a1 | 45.1 m vs 41.2 m (8.5 %) | units walk shrine_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-inn_a2 vs shrine_b2-inn_b1 | 45.1 m vs 41.3 m (8.4 %) | units walk shrine_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_b1 vs cache_a_b2-cache_b_a2 | 130.6 m vs 119.6 m (8.4 %) | units walk cache_a_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-cache_b_b1 vs inn_a2-cache_b_b2 | 82.9 m vs 75.9 m (8.4 %) | units walk inn_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-nat_node_b2 vs home_a_b2-nat_node_b1 | 54.4 m vs 59.4 m (8.4 %) | units walk home_a_b2-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-nat_node_a2 vs home_a_b1-nat_node_b2 | 59.4 m vs 54.4 m (8.4 %) | units walk home_a_a1-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-x_ford_n vs keep_t4-x_ford_n | 97.4 m vs 106.4 m (8.4 %) | units walk keep_t4-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_nest_a2 vs keep_t4-ford_nest_a2 | 97.4 m vs 106.4 m (8.4 %) | units walk keep_t4-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-nat_node_a1 vs home_a_b2-nat_node_b1 | 54.4 m vs 59.4 m (8.4 %) | units walk home_a_b2-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-nat_node_a2 vs home_a_a2-nat_node_a1 | 59.4 m vs 54.4 m (8.4 %) | units walk home_a_a1-nat_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_a2 vs shrine_b1-stag_b2 | 94.4 m vs 86.5 m (8.4 %) | units walk shrine_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_a2 vs shrine_a2-stag_a1 | 94.4 m vs 86.5 m (8.4 %) | units walk shrine_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-cache_b_b1 vs cache_a_a2-cache_b_b2 | 130.6 m vs 119.6 m (8.4 %) | units walk cache_a_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-cache_b_b2 vs inn_b2-cache_b_a2 | 75.9 m vs 82.8 m (8.3 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-x_ford_s vs peddler_b2-x_ford_n | 88.1 m vs 96.1 m (8.3 %) | units walk peddler_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-guilds_lodge_a1 vs post_s_b2-guilds_lodge_a2 | 204.4 m vs 187.5 m (8.3 %) | units walk post_s_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-cache_b_a2 vs home_a_a2-cache_b_a1 | 88.3 m vs 81.0 m (8.3 %) | units walk home_a_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-guilds_den_a1 vs stag_b2-guilds_den_a2 | 219.9 m vs 201.6 m (8.3 %) | units walk stag_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-post_s_b2 vs post_w_b2-post_s_b1 | 110.9 m vs 120.9 m (8.3 %) | units walk post_w_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-guilds_lodge_b1 vs post_s_b2-guilds_lodge_a2 | 204.4 m vs 187.5 m (8.3 %) | units walk post_s_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-post_s_a1 vs post_w_b1-post_s_b2 | 120.9 m vs 110.9 m (8.3 %) | units walk post_w_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_den_b1 vs stag_b1-guilds_den_a1 | 201.7 m vs 219.9 m (8.3 %) | units walk stag_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-guilds_lodge_b2 vs post_s_b1-guilds_lodge_a1 | 187.5 m vs 204.4 m (8.3 %) | units walk post_s_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-guilds_lodge_b1 vs post_s_a2-guilds_lodge_b2 | 204.4 m vs 187.5 m (8.2 %) | units walk post_s_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-rich_node_b2 vs home_b_b2-rich_node_a2 | 124.6 m vs 135.8 m (8.2 %) | units walk home_b_b2-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-guilds_den_b2 vs post_s_b2-guilds_den_a2 | 191.5 m vs 208.6 m (8.2 %) | units walk post_s_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_a2 vs home_a_a2-tower_c_a1 | 64.4 m vs 59.1 m (8.2 %) | units walk home_a_a1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-guilds_den_b1 vs post_s_a2-guilds_den_b2 | 208.6 m vs 191.5 m (8.2 %) | units walk post_s_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-cache_b_a2 vs home_a_b2-cache_b_b1 | 88.3 m vs 81.1 m (8.2 %) | units walk home_a_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_b1 vs shrine_b1-stag_a1 | 135.3 m vs 124.2 m (8.2 %) | units walk shrine_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-guilds_den_b2 vs post_s_b1-guilds_den_a1 | 191.5 m vs 208.6 m (8.2 %) | units walk post_s_b1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-x_bridge_n vs post_s_a2-x_bridge_s | 165.1 m vs 151.6 m (8.2 %) | units walk post_s_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-peddler_a2 vs post_s_b1-peddler_b2 | 123.3 m vs 113.2 m (8.2 %) | units walk post_s_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-peddler_b2 vs post_s_b2-peddler_b1 | 113.2 m vs 123.3 m (8.2 %) | units walk post_s_b2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_b2 vs tower_r_b2-lairs_one_a1 | 85.2 m vs 92.8 m (8.2 %) | units walk tower_r_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-peddler_a1 vs post_s_b1-peddler_b2 | 123.3 m vs 113.2 m (8.2 %) | units walk post_s_a2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_two_b2 vs home_b_b2-lairs_two_b1 | 131.0 m vs 120.3 m (8.2 %) | units walk home_b_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_lodge_b2 vs stag_b1-guilds_lodge_a1 | 197.8 m vs 215.3 m (8.2 %) | units walk stag_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_lodge_b1 vs stag_b1-guilds_lodge_a1 | 197.8 m vs 215.3 m (8.2 %) | units walk stag_b1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-lairs_one_a2 vs tower_r_b2-lairs_one_a1 | 85.3 m vs 92.8 m (8.1 %) | units walk tower_r_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b2 vs third_node_b1-shrine_a2 | 152.5 m vs 140.1 m (8.1 %) | units walk third_node_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b2 vs third_node_a2-shrine_b1 | 152.5 m vs 140.1 m (8.1 %) | units walk third_node_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-x_bridge_n vs post_s_b1-x_bridge_s | 165.1 m vs 151.8 m (8.1 %) | units walk post_s_a1-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-lairs_one_b2 vs tower_r_a2-lairs_one_b1 | 85.2 m vs 92.7 m (8.1 %) | units walk tower_r_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-peddler_b2 vs third_node_a2-peddler_b1 | 161.1 m vs 148.1 m (8.1 %) | units walk third_node_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-peddler_b1 vs third_node_b2-peddler_a1 | 148.1 m vs 161.1 m (8.0 %) | units walk third_node_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-peddler_b2 vs third_node_b1-peddler_a2 | 161.1 m vs 148.1 m (8.0 %) | units walk third_node_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-peddler_a2 vs third_node_b2-peddler_a1 | 148.1 m vs 161.1 m (8.0 %) | units walk third_node_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_s_b2 vs nat_node_b1-post_s_a1 | 128.6 m vs 118.3 m (8.0 %) | units walk nat_node_a2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-lairs_one_b1 vs rich_node_b2-lairs_one_b2 | 63.4 m vs 58.3 m (8.0 %) | units walk rich_node_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_one_a2 vs rich_node_b2-lairs_one_b2 | 63.4 m vs 58.3 m (8.0 %) | units walk rich_node_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_one_a1 vs rich_node_b1-lairs_one_b1 | 58.3 m vs 63.4 m (8.0 %) | units walk rich_node_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_one_a1 vs rich_node_a2-lairs_one_a2 | 58.3 m vs 63.4 m (8.0 %) | units walk rich_node_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-cache_b_a1 vs home_b_b2-cache_b_a2 | 111.9 m vs 121.7 m (8.0 %) | units walk home_b_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-lairs_one_b1 vs tower_r_b1-lairs_one_a2 | 92.7 m vs 85.3 m (8.0 %) | units walk tower_r_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_a_a2 vs guilds_den_b1-cache_a_b2 | 149.5 m vs 162.4 m (7.9 %) | units walk guilds_den_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-cache_a_b2 vs guilds_den_b2-cache_a_b1 | 162.4 m vs 149.5 m (7.9 %) | units walk guilds_den_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_a_a1 vs guilds_den_b2-cache_a_b1 | 162.4 m vs 149.5 m (7.9 %) | units walk guilds_den_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_a_a2 vs guilds_den_a2-cache_a_a1 | 149.5 m vs 162.4 m (7.9 %) | units walk guilds_den_a2-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_a_a1 vs third_node_b1-cache_a_b2 | 137.4 m vs 149.3 m (7.9 %) | units walk third_node_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-well_a1 vs third_node_b2-well_a2 | 168.8 m vs 183.2 m (7.9 %) | units walk third_node_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-lairs_one_b2 vs post_s_b2-lairs_one_a1 | 93.9 m vs 101.9 m (7.9 %) | units walk post_s_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_w_b1 vs third_node_b1-post_w_a1 | 193.2 m vs 178.0 m (7.9 %) | units walk third_node_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_two_a1 vs home_b_b2-lairs_two_a2 | 166.5 m vs 180.6 m (7.8 %) | units walk home_b_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_b_a1 vs third_node_b2-cache_b_a2 | 141.3 m vs 153.3 m (7.8 %) | units walk third_node_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-post_w_b1 vs third_node_a2-post_w_b2 | 193.2 m vs 178.1 m (7.8 %) | units walk third_node_a1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-tower_r_a1 vs keep_t4-tower_r_a2 | 129.1 m vs 140.0 m (7.8 %) | units walk keep_t4-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-stag_b2 vs nat_node_b1-stag_a1 | 132.5 m vs 122.2 m (7.8 %) | units walk nat_node_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-lairs_one_b2 vs post_s_a2-lairs_one_b1 | 93.9 m vs 101.8 m (7.8 %) | units walk post_s_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_node_b1 vs keep_t4-rich_node_a2 | 120.0 m vs 130.1 m (7.8 %) | units walk keep_t4-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-shrine_b2 vs rich_node_b1-shrine_a2 | 89.2 m vs 82.3 m (7.8 %) | units walk rich_node_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-shrine_b2 vs rich_node_a2-shrine_b1 | 89.2 m vs 82.3 m (7.8 %) | units walk rich_node_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-stag_a1 vs wallow_b2-stag_a2 | 166.9 m vs 180.9 m (7.8 %) | units walk wallow_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-lairs_one_a1 vs keep_t4-lairs_one_a2 | 174.6 m vs 189.2 m (7.8 %) | units walk keep_t4-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_one_b2 vs rich_node_b1-lairs_one_a2 | 87.3 m vs 94.7 m (7.7 %) | units walk rich_node_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-shrine_b2 vs rich_node_b2-shrine_a1 | 89.2 m vs 82.3 m (7.7 %) | units walk rich_node_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_a1 vs cache_a_b1-lairs_one_b1 | 24.3 m vs 26.3 m (7.7 %) | units walk cache_a_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_a1 vs cache_a_a2-lairs_one_a2 | 24.3 m vs 26.3 m (7.7 %) | units walk cache_a_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-lairs_one_b1 vs cache_a_b2-lairs_one_b2 | 26.3 m vs 24.3 m (7.7 %) | units walk cache_a_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_one_a2 vs cache_a_b2-lairs_one_b2 | 26.3 m vs 24.3 m (7.7 %) | units walk cache_a_a2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-lairs_one_b2 vs rich_node_a2-lairs_one_b1 | 87.3 m vs 94.6 m (7.7 %) | units walk rich_node_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-lairs_one_a2 vs rich_node_b2-lairs_one_a1 | 94.7 m vs 87.4 m (7.7 %) | units walk rich_node_b1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-lairs_one_a2 vs post_s_b2-lairs_one_a1 | 94.1 m vs 101.9 m (7.7 %) | units walk post_s_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-lairs_one_b1 vs rich_node_b2-lairs_one_a1 | 94.6 m vs 87.4 m (7.6 %) | units walk rich_node_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-lairs_two_a1 vs lairs_one_b2-lairs_two_b1 | 175.1 m vs 161.8 m (7.6 %) | units walk lairs_one_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-cache_b_a1 vs well_b2-cache_b_a2 | 115.5 m vs 106.7 m (7.6 %) | units walk well_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-lairs_one_b1 vs post_s_b1-lairs_one_a2 | 101.8 m vs 94.1 m (7.6 %) | units walk post_s_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-x_ford_s vs keep_t4-x_ford_n | 98.3 m vs 106.4 m (7.6 %) | units walk keep_t4-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_nest_a1 vs keep_t4-ford_nest_a2 | 98.3 m vs 106.4 m (7.6 %) | units walk keep_t4-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_b_b1 vs well_b1-cache_b_a1 | 106.8 m vs 115.5 m (7.5 %) | units walk well_b1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_a2 vs home_b_b2-shrine_b1 | 51.0 m vs 55.1 m (7.5 %) | units walk home_b_b2-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-shrine_b2 vs home_b_b2-shrine_b1 | 51.0 m vs 55.1 m (7.5 %) | units walk home_b_b2-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-shrine_a1 vs home_b_b2-shrine_b1 | 51.0 m vs 55.1 m (7.5 %) | units walk home_b_b2-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b1 vs third_node_b1-shrine_a1 | 164.4 m vs 152.1 m (7.5 %) | units walk third_node_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_b_b1 vs peddler_b1-cache_b_a1 | 105.9 m vs 98.0 m (7.5 %) | units walk peddler_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-shrine_b1 vs third_node_a2-shrine_b2 | 164.4 m vs 152.1 m (7.5 %) | units walk third_node_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_a_a1 vs guilds_lodge_b1-cache_a_b2 | 147.1 m vs 158.9 m (7.4 %) | units walk guilds_lodge_b1-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-cache_b_a1 vs peddler_b2-cache_b_a2 | 98.0 m vs 105.8 m (7.4 %) | units walk peddler_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_b_b1 vs peddler_a2-cache_b_b2 | 105.9 m vs 98.1 m (7.4 %) | units walk peddler_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-cache_b_b2 vs peddler_b2-cache_b_a2 | 98.1 m vs 105.8 m (7.3 %) | units walk peddler_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-tower_c_b1 vs home_a_b2-tower_c_a1 | 104.6 m vs 97.0 m (7.3 %) | units walk home_a_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-x_bridge_s vs post_s_b2-x_bridge_n | 151.6 m vs 163.5 m (7.3 %) | units walk post_s_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-tower_c_a2 vs home_a_b2-tower_c_a1 | 104.5 m vs 97.0 m (7.2 %) | units walk home_a_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_w_a2 vs rich_node_b2-post_w_a1 | 109.4 m vs 117.8 m (7.2 %) | units walk rich_node_b2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-x_bridge_s vs post_s_b2-x_bridge_n | 151.8 m vs 163.5 m (7.2 %) | units walk post_s_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_node_b2 vs keep_t4-rich_node_a2 | 120.8 m vs 130.1 m (7.1 %) | units walk keep_t4-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b2 vs home_a_b1-shrine_a2 | 137.3 m vs 127.6 m (7.1 %) | units walk home_a_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_one_b2 vs stag_b2-lairs_one_a1 | 104.9 m vs 112.8 m (7.1 %) | units walk stag_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b2 vs home_a_a2-shrine_b1 | 137.3 m vs 127.6 m (7.1 %) | units walk home_a_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_w_b1 vs rich_node_b1-post_w_a2 | 117.6 m vs 109.4 m (7.0 %) | units walk rich_node_a2-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b2 vs home_a_b2-shrine_a1 | 137.3 m vs 127.7 m (7.0 %) | units walk home_a_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-lairs_one_a1 vs home_b_b2-lairs_one_a2 | 181.2 m vs 194.9 m (7.0 %) | units walk home_b_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_one_b2 vs home_b_b2-lairs_one_a2 | 181.2 m vs 194.9 m (7.0 %) | units walk home_b_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-lairs_one_b2 vs stag_a2-lairs_one_b1 | 104.9 m vs 112.7 m (7.0 %) | units walk stag_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-inn_b2 vs home_a_b2-inn_b1 | 62.2 m vs 66.9 m (7.0 %) | units walk home_a_b2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_a2 vs home_a_b1-inn_b2 | 66.9 m vs 62.2 m (7.0 %) | units walk home_a_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_a2 vs home_a_a2-inn_a1 | 66.9 m vs 62.2 m (7.0 %) | units walk home_a_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-inn_a1 vs home_a_b2-inn_b1 | 62.2 m vs 66.9 m (7.0 %) | units walk home_a_b2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_a_b1 vs home_b_b2-cache_a_a2 | 155.3 m vs 166.9 m (7.0 %) | units walk home_b_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-lairs_one_a2 vs stag_b2-lairs_one_a1 | 105.0 m vs 112.8 m (7.0 %) | units walk stag_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_b_a2 vs guilds_den_b1-cache_b_b2 | 139.8 m vs 130.1 m (6.9 %) | units walk guilds_den_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_b_a2 vs guilds_den_a2-cache_b_a1 | 139.8 m vs 130.1 m (6.9 %) | units walk guilds_den_a1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-cache_b_b2 vs guilds_den_b2-cache_b_b1 | 130.1 m vs 139.8 m (6.9 %) | units walk guilds_den_b2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_b_a1 vs guilds_den_b2-cache_b_b1 | 130.1 m vs 139.8 m (6.9 %) | units walk guilds_den_b2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-lairs_two_b2 vs nat_node_b1-lairs_two_a1 | 148.1 m vs 137.9 m (6.9 %) | units walk nat_node_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-lairs_two_b2 vs nat_node_b2-lairs_two_a2 | 148.1 m vs 137.9 m (6.9 %) | units walk nat_node_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-lairs_two_b1 vs nat_node_a2-lairs_two_b2 | 137.9 m vs 148.1 m (6.9 %) | units walk nat_node_a2-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-lairs_one_b1 vs stag_b1-lairs_one_a2 | 112.7 m vs 105.0 m (6.9 %) | units walk stag_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-post_s_a2 vs post_w_b2-post_s_b1 | 112.6 m vs 120.9 m (6.9 %) | units walk post_w_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-post_s_a2 vs post_w_a2-post_s_a1 | 112.6 m vs 120.9 m (6.9 %) | units walk post_w_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_lane_e vs home_b_b1-x_lane_w | 88.1 m vs 94.5 m (6.8 %) | units walk home_b_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-lairs_one_b1 vs wallow_b1-lairs_one_a2 | 161.0 m vs 150.1 m (6.8 %) | units walk wallow_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-tower_c_b2 vs third_node_b1-tower_c_a1 | 124.2 m vs 133.3 m (6.8 %) | units walk third_node_b1-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b2 vs keep_t1-shrine_a2 | 132.8 m vs 123.8 m (6.8 %) | units walk keep_t0-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_r_b1 vs home_b_b2-tower_r_a2 | 135.8 m vs 145.7 m (6.8 %) | units walk home_b_b2-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b2 vs keep_t3-shrine_b1 | 132.8 m vs 123.8 m (6.8 %) | units walk keep_t0-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_one_b2 vs wallow_b1-lairs_one_a2 | 161.0 m vs 150.1 m (6.8 %) | units walk wallow_a1-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-tower_r_b2 vs home_b_b2-tower_r_a2 | 135.8 m vs 145.7 m (6.8 %) | units walk home_b_b2-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-x_lane_w vs home_b_b2-x_lane_w | 94.5 m vs 88.2 m (6.7 %) | units walk home_b_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_lane_e vs home_b_b1-x_lane_w | 88.2 m vs 94.5 m (6.7 %) | units walk home_b_b1-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-lairs_one_a2 vs wallow_b2-lairs_one_a1 | 150.1 m vs 160.9 m (6.7 %) | units walk wallow_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b2 vs keep_t4-shrine_a1 | 132.8 m vs 123.9 m (6.7 %) | units walk keep_t0-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-stag_b2 vs home_b_b1-stag_a1 | 161.7 m vs 150.9 m (6.7 %) | units walk home_b_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_a_a1 vs third_node_a2-cache_a_a2 | 33.9 m vs 31.6 m (6.6 %) | units walk third_node_a1-cache_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_a_a2 vs third_node_b2-cache_a_b2 | 31.6 m vs 33.9 m (6.6 %) | units walk third_node_b2-cache_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-peddler_b1 vs guilds_lodge_b1-peddler_a2 | 167.8 m vs 156.7 m (6.6 %) | units walk guilds_lodge_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b2 vs well_b1-shrine_a2 | 106.4 m vs 99.4 m (6.6 %) | units walk well_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b2 vs well_a2-shrine_b1 | 106.4 m vs 99.4 m (6.6 %) | units walk well_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b2 vs well_b2-shrine_a1 | 106.4 m vs 99.4 m (6.6 %) | units walk well_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b2 vs home_b_b1-shrine_a2 | 128.9 m vs 120.4 m (6.5 %) | units walk home_b_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b2 vs home_b_a2-shrine_b1 | 128.9 m vs 120.4 m (6.5 %) | units walk home_b_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-lairs_one_a1 vs peddler_b2-lairs_one_a2 | 167.3 m vs 179.0 m (6.5 %) | units walk peddler_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-post_s_a2 vs post_s_b2-post_s_b1 | 169.6 m vs 158.5 m (6.5 %) | units walk post_s_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-lairs_one_b2 vs peddler_b2-lairs_one_a2 | 167.3 m vs 179.0 m (6.5 %) | units walk peddler_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_two_a2 vs wallow_a2-lairs_two_a1 | 131.6 m vs 140.7 m (6.5 %) | units walk wallow_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_two_a2 vs wallow_b1-lairs_two_b2 | 131.6 m vs 140.7 m (6.5 %) | units walk wallow_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b2 vs home_b_b2-shrine_a1 | 128.9 m vs 120.5 m (6.5 %) | units walk home_b_a1-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-peddler_b1 vs guilds_lodge_b2-peddler_a2 | 191.8 m vs 179.4 m (6.5 %) | units walk guilds_lodge_a1-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_ford_s vs third_node_a2-x_ford_n | 88.7 m vs 83.0 m (6.5 %) | units walk third_node_a1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-ford_nest_a1 vs third_node_a2-ford_nest_a2 | 88.7 m vs 83.0 m (6.5 %) | units walk third_node_a1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-ford_nest_a2 vs third_node_b2-ford_nest_a1 | 83.0 m vs 88.7 m (6.5 %) | units walk third_node_b2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-x_ford_n vs third_node_b2-x_ford_s | 83.0 m vs 88.7 m (6.5 %) | units walk third_node_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-ford_nest_a1 vs third_node_b1-ford_nest_a2 | 88.7 m vs 83.0 m (6.5 %) | units walk third_node_a1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-x_ford_s vs third_node_b1-x_ford_n | 88.7 m vs 83.0 m (6.5 %) | units walk third_node_a1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-ford_nest_a2 vs third_node_b2-ford_nest_a1 | 83.0 m vs 88.7 m (6.5 %) | units walk third_node_b2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-x_ford_n vs third_node_b2-x_ford_s | 83.0 m vs 88.7 m (6.5 %) | units walk third_node_b2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-lairs_two_a1 vs wallow_b2-lairs_two_b1 | 140.7 m vs 131.7 m (6.4 %) | units walk wallow_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-lairs_two_b2 vs wallow_b2-lairs_two_b1 | 140.7 m vs 131.7 m (6.4 %) | units walk wallow_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-stag_b1 vs home_b_b1-stag_a1 | 161.1 m vs 150.9 m (6.3 %) | units walk home_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-lairs_two_a1 vs keep_t4-lairs_two_a2 | 163.9 m vs 175.0 m (6.3 %) | units walk keep_t4-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b1 vs keep_t1-well_a1 | 146.5 m vs 137.3 m (6.3 %) | units walk keep_t0-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_b2 vs cache_a_b2-lairs_one_a1 | 115.6 m vs 123.3 m (6.2 %) | units walk cache_a_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-lairs_two_a2 vs guilds_den_a2-lairs_two_a1 | 164.3 m vs 175.2 m (6.2 %) | units walk guilds_den_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-lairs_two_a2 vs guilds_den_b1-lairs_two_b2 | 164.3 m vs 175.2 m (6.2 %) | units walk guilds_den_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-lairs_one_b2 vs keep_t4-lairs_one_a2 | 177.5 m vs 189.2 m (6.2 %) | units walk keep_t4-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_a2 vs shrine_b1-post_s_b2 | 101.9 m vs 95.6 m (6.2 %) | units walk shrine_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_a2 vs shrine_b2-post_s_b1 | 101.9 m vs 95.6 m (6.2 %) | units walk shrine_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_a2 vs shrine_a2-post_s_a1 | 101.9 m vs 95.6 m (6.2 %) | units walk shrine_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b1 vs home_b_b1-well_a1 | 149.0 m vs 139.8 m (6.2 %) | units walk home_b_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_one_b2 vs guilds_lodge_a2-lairs_one_b1 | 153.0 m vs 163.0 m (6.1 %) | units walk guilds_lodge_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-lairs_one_a2 vs cache_a_b2-lairs_one_a1 | 115.7 m vs 123.3 m (6.1 %) | units walk cache_a_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_b2 vs cache_a_a2-lairs_one_b1 | 115.6 m vs 123.2 m (6.1 %) | units walk cache_a_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b1 vs home_b_b2-tower_c_a2 | 104.4 m vs 98.0 m (6.1 %) | units walk home_b_a1-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_e vs guilds_lodge_b1-x_lane_w | 133.4 m vs 125.3 m (6.1 %) | units walk guilds_lodge_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_e vs guilds_lodge_a2-x_lane_e | 133.4 m vs 125.3 m (6.1 %) | units walk guilds_lodge_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-x_lane_e vs guilds_lodge_b2-x_lane_w | 125.3 m vs 133.4 m (6.1 %) | units walk guilds_lodge_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-x_lane_w vs guilds_lodge_b2-x_lane_w | 125.3 m vs 133.4 m (6.1 %) | units walk guilds_lodge_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-tower_c_a1 vs home_b_b2-tower_c_a2 | 104.3 m vs 98.0 m (6.1 %) | units walk home_b_b1-tower_c_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-tower_c_b2 vs home_b_b2-tower_c_a2 | 104.3 m vs 98.0 m (6.1 %) | units walk home_b_a2-tower_c_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_one_b1 vs cache_a_b1-lairs_one_a2 | 123.2 m vs 115.7 m (6.1 %) | units walk cache_a_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-stag_b2 vs keep_t1-stag_a1 | 157.9 m vs 148.4 m (6.1 %) | units walk keep_t3-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-stag_b1 vs keep_t1-stag_a1 | 157.9 m vs 148.4 m (6.1 %) | units walk keep_t0-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-stag_a1 vs nat_node_b2-stag_a2 | 122.2 m vs 130.1 m (6.0 %) | units walk nat_node_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-stag_b1 vs nat_node_b1-stag_a1 | 130.0 m vs 122.2 m (6.0 %) | units walk nat_node_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_b2 vs third_node_b1-cache_b_a2 | 101.1 m vs 95.0 m (6.0 %) | units walk third_node_a1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_b_b1 vs home_b_b1-cache_b_a1 | 119.1 m vs 111.9 m (6.0 %) | units walk home_b_a1-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-cache_b_a2 vs third_node_b2-cache_b_a1 | 95.0 m vs 101.1 m (6.0 %) | units walk third_node_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a2-lairs_two_a1 vs post_w_b2-lairs_two_b1 | 105.3 m vs 99.0 m (6.0 %) | units walk post_w_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_b1-lairs_two_b2 vs post_w_b2-lairs_two_b1 | 105.3 m vs 99.0 m (6.0 %) | units walk post_w_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_one_b1 vs home_b_b2-lairs_one_a2 | 183.2 m vs 194.9 m (6.0 %) | units walk home_b_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-peddler_a1 vs wallow_b1-peddler_b2 | 71.5 m vs 76.0 m (6.0 %) | units walk wallow_b1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-peddler_b2 vs wallow_b2-peddler_b1 | 76.0 m vs 71.5 m (6.0 %) | units walk wallow_b1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_a2 vs wallow_b1-peddler_b2 | 71.5 m vs 76.0 m (6.0 %) | units walk wallow_b1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_b1 vs third_node_a2-cache_b_b2 | 139.1 m vs 147.9 m (6.0 %) | units walk third_node_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-cache_b_b2 vs third_node_a2-cache_b_b1 | 101.1 m vs 95.1 m (6.0 %) | units walk third_node_a1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-cache_a_a1 vs home_b_b2-cache_a_a2 | 156.9 m vs 166.9 m (6.0 %) | units walk home_b_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_b2 vs home_a_a2-tower_c_b1 | 98.4 m vs 104.6 m (5.9 %) | units walk home_a_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-cache_a_b2 vs home_b_b2-cache_a_a2 | 157.0 m vs 166.9 m (5.9 %) | units walk home_b_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-lairs_two_a2 vs lairs_one_b2-lairs_two_b1 | 172.0 m vs 161.8 m (5.9 %) | units walk lairs_one_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_node_a2 vs home_b_b2-rich_node_b1 | 103.3 m vs 109.8 m (5.9 %) | units walk home_b_b2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-cache_b_b2 vs home_b_b1-cache_b_a1 | 119.0 m vs 111.9 m (5.9 %) | units walk home_b_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-cache_b_b1 vs third_node_b2-cache_b_a1 | 95.1 m vs 101.1 m (5.9 %) | units walk third_node_b2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_b2 vs home_a_b1-tower_c_a2 | 98.4 m vs 104.5 m (5.9 %) | units walk home_a_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-stag_a1 vs shrine_b2-stag_a2 | 124.2 m vs 131.9 m (5.8 %) | units walk shrine_b2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-x_ford_s vs lairs_one_b2-x_ford_n | 142.3 m vs 151.1 m (5.8 %) | units walk lairs_one_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a2-x_ford_s vs lairs_one_b2-x_ford_n | 142.3 m vs 151.1 m (5.8 %) | units walk lairs_one_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-lairs_two_a1 vs guilds_den_b2-lairs_two_b1 | 175.2 m vs 165.0 m (5.8 %) | units walk guilds_den_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_b1-lairs_two_b2 vs guilds_den_b2-lairs_two_b1 | 175.2 m vs 165.0 m (5.8 %) | units walk guilds_den_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_bridge_n vs home_b_b2-x_bridge_n | 120.6 m vs 128.1 m (5.8 %) | units walk home_b_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-stag_b2 vs shrine_b1-stag_a1 | 131.8 m vs 124.2 m (5.8 %) | units walk shrine_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_den_b1 vs home_b_b2-guilds_den_a2 | 190.5 m vs 202.1 m (5.7 %) | units walk home_b_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-x_lane_e vs lairs_one_b1-x_lane_w | 124.5 m vs 117.4 m (5.7 %) | units walk lairs_one_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_b1-x_lane_w vs lairs_one_b2-x_lane_w | 117.4 m vs 124.5 m (5.7 %) | units walk lairs_one_b2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_lane_e vs lairs_two_b2-x_lane_w | 110.3 m vs 104.1 m (5.7 %) | units walk lairs_two_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-inn_a1 vs tower_c_b2-inn_a2 | 64.9 m vs 61.2 m (5.7 %) | units walk tower_c_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-rich_node_a1 vs home_b_b2-rich_node_b1 | 103.5 m vs 109.8 m (5.7 %) | units walk home_b_b2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-rich_node_b2 vs home_b_b2-rich_node_b1 | 103.5 m vs 109.8 m (5.7 %) | units walk home_b_b2-rich_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-inn_b1 vs tower_c_b1-inn_a1 | 61.2 m vs 64.9 m (5.7 %) | units walk tower_c_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a1-x_lane_e vs lairs_two_b1-x_lane_w | 110.3 m vs 104.1 m (5.7 %) | units walk lairs_two_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_s_a2 vs tower_r_a2-post_s_a1 | 144.6 m vs 153.3 m (5.7 %) | units walk tower_r_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_s_a1 vs tower_r_b1-post_s_b2 | 153.3 m vs 144.6 m (5.7 %) | units walk tower_r_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-tower_r_b2 vs keep_t4-tower_r_a2 | 132.1 m vs 140.0 m (5.7 %) | units walk keep_t4-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_s_a2 vs tower_r_b2-post_s_b1 | 144.6 m vs 153.3 m (5.7 %) | units walk tower_r_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_s_b2 vs tower_r_b2-post_s_b1 | 144.6 m vs 153.3 m (5.7 %) | units walk tower_r_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_a_b1 vs peddler_b2-cache_a_a2 | 142.4 m vs 151.0 m (5.7 %) | units walk peddler_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-stag_b2 vs wallow_b1-stag_a1 | 176.9 m vs 166.9 m (5.6 %) | units walk wallow_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a2-x_lane_e vs lairs_two_b2-x_lane_w | 110.3 m vs 104.1 m (5.6 %) | units walk lairs_two_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_two_a2-x_lane_e vs lairs_two_b1-x_lane_w | 110.3 m vs 104.1 m (5.6 %) | units walk lairs_two_a2-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-inn_b2 vs tower_c_b1-inn_a1 | 61.3 m vs 64.9 m (5.6 %) | units walk tower_c_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_b1 vs wallow_b1-stag_a1 | 176.7 m vs 166.9 m (5.6 %) | units walk wallow_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-cache_b_b2 vs keep_t1-cache_b_a1 | 116.5 m vs 110.0 m (5.6 %) | units walk keep_t3-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_b_b2 vs tower_r_b1-cache_b_a1 | 107.9 m vs 101.9 m (5.6 %) | units walk tower_r_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_a2-cache_b_b2 | 150.2 m vs 159.0 m (5.6 %) | units walk guilds_lodge_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-x_bridge_s vs shrine_b1-x_bridge_s | 91.4 m vs 96.8 m (5.5 %) | units walk shrine_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-lairs_two_b2 vs home_b_b2-lairs_two_a2 | 170.6 m vs 180.6 m (5.5 %) | units walk home_b_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_a_b1 vs keep_t4-cache_a_a2 | 152.3 m vs 161.2 m (5.5 %) | units walk keep_t4-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-lairs_two_a2 vs post_w_a2-lairs_two_a1 | 99.5 m vs 105.3 m (5.5 %) | units walk post_w_a2-lairs_two_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-lairs_two_a2 vs post_w_b1-lairs_two_b2 | 99.5 m vs 105.3 m (5.5 %) | units walk post_w_b1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-lairs_two_a1 vs wallow_b2-lairs_two_a2 | 182.5 m vs 193.1 m (5.5 %) | units walk wallow_b2-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-x_bridge_s vs shrine_b2-x_bridge_n | 96.8 m vs 91.5 m (5.5 %) | units walk shrine_b1-x_bridge_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-lairs_one_b2 vs lairs_one_a2-lairs_one_b1 | 135.8 m vs 143.6 m (5.5 %) | units walk lairs_one_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-peddler_b2 vs guilds_lodge_b1-peddler_a2 | 165.8 m vs 156.7 m (5.5 %) | units walk guilds_lodge_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-peddler_a2 vs guilds_lodge_b2-peddler_a1 | 156.7 m vs 165.8 m (5.5 %) | units walk guilds_lodge_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-cache_b_b2 vs tower_r_b2-cache_b_a2 | 107.9 m vs 102.0 m (5.5 %) | units walk tower_r_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-peddler_a1 vs guilds_lodge_b2-peddler_a2 | 189.7 m vs 179.4 m (5.5 %) | units walk guilds_lodge_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-peddler_b2 vs guilds_lodge_b2-peddler_a2 | 189.7 m vs 179.4 m (5.4 %) | units walk guilds_lodge_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_two_b1 vs shrine_b1-lairs_two_a1 | 147.8 m vs 139.8 m (5.4 %) | units walk shrine_a1-lairs_two_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-lairs_one_a2 vs third_node_b2-lairs_one_a1 | 147.8 m vs 156.3 m (5.4 %) | units walk third_node_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-cache_b_b1 vs tower_r_a2-cache_b_b2 | 102.1 m vs 107.9 m (5.4 %) | units walk tower_r_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-guilds_lodge_b1 vs keep_t3-guilds_lodge_b2 | 201.1 m vs 190.3 m (5.4 %) | units walk keep_t0-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-lairs_one_b2 vs guilds_den_a2-lairs_one_b1 | 147.4 m vs 155.8 m (5.4 %) | units walk guilds_den_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-well_b1 vs home_a_b1-well_a1 | 143.3 m vs 135.7 m (5.3 %) | units walk home_a_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-well_b1 vs home_a_a2-well_b2 | 143.3 m vs 135.7 m (5.3 %) | units walk home_a_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-inn_b1 vs home_b_b2-inn_a2 | 120.4 m vs 114.0 m (5.3 %) | units walk home_b_a1-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_b_b1 vs keep_t1-cache_b_a1 | 116.2 m vs 110.0 m (5.3 %) | units walk keep_t0-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-inn_a1 vs home_b_b2-inn_a2 | 120.4 m vs 114.0 m (5.3 %) | units walk home_b_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-inn_b2 vs home_b_b2-inn_a2 | 120.4 m vs 114.0 m (5.3 %) | units walk home_b_a2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-cache_a_a1 vs peddler_b2-cache_a_a2 | 143.0 m vs 151.0 m (5.3 %) | units walk peddler_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-rich_node_a1 vs home_a_b2-rich_node_a2 | 115.7 m vs 122.1 m (5.3 %) | units walk home_a_b2-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_r_b1 vs keep_t4-tower_r_a2 | 132.6 m vs 140.0 m (5.3 %) | units walk keep_t4-tower_r_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-cache_a_b2 vs peddler_b2-cache_a_a2 | 143.0 m vs 151.0 m (5.3 %) | units walk peddler_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_bridge_s vs home_b_b2-x_bridge_n | 121.3 m vs 128.1 m (5.3 %) | units walk home_b_b2-x_bridge_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-nat_node_b1 vs home_b_b2-nat_node_a2 | 121.5 m vs 115.1 m (5.3 %) | units walk home_b_a1-nat_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-lairs_one_b2 vs wallow_b2-lairs_one_a2 | 196.5 m vs 207.3 m (5.2 %) | units walk wallow_b2-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-ford_nest_a1 vs home_a_b2-ford_nest_a2 | 93.2 m vs 98.4 m (5.2 %) | units walk home_a_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-x_ford_s vs home_a_b2-x_ford_n | 93.2 m vs 98.4 m (5.2 %) | units walk home_a_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_ford_n vs home_a_b1-x_ford_s | 98.4 m vs 93.2 m (5.2 %) | units walk home_a_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-ford_nest_a2 vs home_a_b1-ford_nest_a1 | 98.4 m vs 93.2 m (5.2 %) | units walk home_a_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-cache_b_a1 vs keep_t4-cache_b_a2 | 110.0 m vs 116.1 m (5.2 %) | units walk keep_t4-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-rich_node_b2 vs home_a_b2-rich_node_a2 | 115.7 m vs 122.1 m (5.2 %) | units walk home_a_b2-rich_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-nat_node_a1 vs home_b_b2-nat_node_a2 | 121.5 m vs 115.1 m (5.2 %) | units walk home_b_b1-nat_node_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-nat_node_b2 vs home_b_b2-nat_node_a2 | 121.5 m vs 115.1 m (5.2 %) | units walk home_b_a2-nat_node_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-ford_nest_a1 vs home_a_b2-ford_nest_a2 | 93.2 m vs 98.4 m (5.2 %) | units walk home_a_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-ford_nest_a2 vs home_a_a2-ford_nest_a1 | 98.4 m vs 93.2 m (5.2 %) | units walk home_a_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-x_ford_n vs home_a_a2-x_ford_s | 98.4 m vs 93.2 m (5.2 %) | units walk home_a_a1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-x_ford_s vs home_a_b2-x_ford_n | 93.2 m vs 98.4 m (5.2 %) | units walk home_a_b2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_one_a1-lairs_one_a2 vs lairs_one_b2-lairs_one_b1 | 173.8 m vs 164.7 m (5.2 %) | units walk lairs_one_a1-lairs_one_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-well_b1 vs third_node_b1-well_a1 | 178.0 m vs 168.8 m (5.2 %) | units walk third_node_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-well_b2 vs third_node_b1-well_a1 | 177.9 m vs 168.8 m (5.2 %) | units walk third_node_a2-well_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-post_s_a1 vs home_b_b2-post_s_a2 | 147.0 m vs 154.9 m (5.1 %) | units walk home_b_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-third_node_a1 vs home_b_b2-third_node_a2 | 185.5 m vs 195.4 m (5.1 %) | units walk home_b_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-lairs_one_b2 vs guilds_den_b2-lairs_one_a1 | 147.4 m vs 155.3 m (5.1 %) | units walk guilds_den_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-third_node_b2 vs home_b_b2-third_node_a2 | 185.5 m vs 195.4 m (5.1 %) | units walk home_b_b2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-lairs_one_b2 vs third_node_b2-lairs_one_a1 | 148.4 m vs 156.3 m (5.1 %) | units walk third_node_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-post_s_a2 vs nat_node_a2-post_s_a1 | 97.9 m vs 103.1 m (5.0 %) | units walk nat_node_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_s_a1 vs nat_node_b2-post_s_b1 | 103.1 m vs 97.9 m (5.0 %) | units walk nat_node_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-post_s_a1 vs nat_node_b1-post_s_b2 | 103.1 m vs 97.9 m (5.0 %) | units walk nat_node_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-shrine_b2 vs shrine_a2-shrine_b1 | 106.3 m vs 111.9 m (5.0 %) | units walk shrine_a2-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-wallow_b2 vs third_node_b2-wallow_a2 | 203.1 m vs 213.8 m (5.0 %) | units walk third_node_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-wallow_a1 vs third_node_b2-wallow_a2 | 203.1 m vs 213.8 m (5.0 %) | units walk third_node_b2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest enemy keep | 135.8 m vs 138.7 m between seats (2.1 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 2.1 m at (9.5, 42.1) vs its twin's 5.8 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 2.1 m at (9.5, 42.1) vs its twin's 5.8 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t3 -> third_node_a2 | narrowest 13.9 m at (-69.3, -55.9) vs its twin's 15.9 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t3 -> third_node_a2 | narrowest 13.9 m at (-69.3, -55.9) vs its twin's 15.9 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t1 -> third_node_b1 | narrowest 13.8 m at (69.3, -55.9) vs its twin's 15.9 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t1 -> third_node_b1 | narrowest 13.8 m at (69.3, -55.9) vs its twin's 15.9 m | a collider narrows this route only on one side |
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


## F2 unit paths: most asymmetric pairs (top 20 of 1200)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | post_s_a2 - lairs_two_b2 | 228.8 | post_s_b1 - lairs_two_a1 | 177.8 | +22.3 % |
| 2 | post_s_a2 - lairs_two_b2 | 228.8 | post_s_b2 - lairs_two_a2 | 177.9 | +22.3 % |
| 3 | post_s_a1 - lairs_two_b1 | 178.1 | post_s_a2 - lairs_two_b2 | 228.8 | -22.2 % |
| 4 | tower_r_a2 - stag_b2 | 195.0 | tower_r_b2 - stag_a2 | 152.0 | +22.1 % |
| 5 | tower_r_a1 - stag_b1 | 152.1 | tower_r_a2 - stag_b2 | 195.0 | -22.0 % |
| 6 | shrine_a1 - stag_a1 | 81.4 | shrine_a2 - stag_a2 | 64.8 | +20.3 % |
| 7 | shrine_a1 - stag_a1 | 81.4 | shrine_b1 - stag_b1 | 64.8 | +20.3 % |
| 8 | shrine_b1 - stag_b2 | 86.5 | shrine_b2 - stag_b1 | 106.2 | -18.6 % |
| 9 | shrine_a2 - stag_a1 | 86.5 | shrine_b2 - stag_b1 | 106.2 | -18.6 % |
| 10 | shrine_a2 - stag_a2 | 64.8 | shrine_b2 - stag_b2 | 79.5 | -18.4 % |
| 11 | shrine_b1 - stag_b1 | 64.8 | shrine_b2 - stag_b2 | 79.5 | -18.4 % |
| 12 | rich_node_a2 - stag_a1 | 156.7 | rich_node_b1 - stag_b2 | 128.0 | +18.3 % |
| 13 | rich_node_a1 - stag_a2 | 128.0 | rich_node_a2 - stag_a1 | 156.7 | -18.3 % |
| 14 | rich_node_a2 - stag_a1 | 156.7 | rich_node_b2 - stag_b1 | 128.0 | +18.3 % |
| 15 | rich_node_a2 - cache_a_a1 | 147.8 | rich_node_b1 - cache_a_b2 | 121.1 | +18.0 % |
| 16 | rich_node_a1 - cache_a_a2 | 121.2 | rich_node_a2 - cache_a_a1 | 147.8 | -18.0 % |
| 17 | rich_node_a2 - cache_a_a1 | 147.8 | rich_node_b2 - cache_a_b1 | 121.2 | +18.0 % |
| 18 | rich_node_b1 - peddler_b2 | 89.6 | rich_node_b2 - peddler_b1 | 108.4 | -17.4 % |
| 19 | rich_node_a1 - peddler_a2 | 89.6 | rich_node_b2 - peddler_b1 | 108.4 | -17.4 % |
| 20 | rich_node_a2 - peddler_a1 | 108.3 | rich_node_b1 - peddler_b2 | 89.6 | +17.3 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 south-west | 35.3 (third_node_a1) | 26.4 (shrine_a1) | 19.4 (wallow_a1) | 47.8 (lairs_one_a1) | 39.9 (inn_a1) | 24.0 (post_w_a1) | 10.4 (peddler_a1) | 39.1 (cache_a_a1) | 75.2 (crown) | 138.7 |
| A2 north-west | 35.2 (third_node_a2) | 26.4 (shrine_a2) | 19.4 (wallow_a2) | 47.8 (lairs_one_a2) | 39.9 (inn_a2) | 24.0 (post_w_a2) | 10.4 (peddler_a2) | 39.1 (cache_a_a2) | 75.2 (crown) | 135.8 |
| B1 north-east | 35.2 (third_node_b1) | 26.4 (shrine_b1) | 19.4 (wallow_b1) | 47.8 (lairs_one_b1) | 39.9 (inn_b1) | 24.0 (post_w_b1) | 10.4 (peddler_b1) | 39.1 (cache_a_b1) | 75.2 (crown) | 135.8 |
| B2 south-east | 35.3 (third_node_b2) | 26.4 (shrine_b2) | 19.4 (wallow_b2) | 47.8 (lairs_one_b2) | 39.9 (inn_b2) | 24.0 (post_w_b2) | 10.4 (peddler_b2) | 39.1 (cache_a_b2) | 75.2 (crown) | 138.7 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| home_b_a1 | home_node | 7.3 | home_b_b2 | 7.3 | +0.0 % |
| home_a_a1 | home_node | 10.0 | home_a_b2 | 10.0 | -0.0 % |
| peddler_a1 | peddler | 10.4 | peddler_b2 | 10.4 | -0.0 % |
| wallow_a1 | camp | 19.4 | wallow_b2 | 19.4 | +0.0 % |
| post_w_a1 | post | 24.0 | post_w_b2 | 24.0 | -0.0 % |
| shrine_a1 | point | 26.4 | shrine_b2 | 26.4 | -0.0 % |
| well_a1 | point | 33.4 | well_b2 | 33.4 | +0.0 % |
| third_node_a1 | expansion | 35.3 | third_node_b2 | 35.3 | +0.0 % |
| nat_node_a1 | expansion | 35.8 | nat_node_b2 | 35.8 | -0.0 % |
| cache_a_a1 | cache | 39.1 | cache_a_b2 | 39.1 | +0.0 % |
| inn_a1 | tavern | 39.9 | inn_b2 | 39.9 | -0.0 % |
| shrine_a2 | point | 46.2 | shrine_b1 | 46.2 | +0.0 % |
| guilds_lodge_a1 | guild | 46.4 | guilds_lodge_b2 | 46.4 | +0.0 % |
| post_w_a2 | post | 47.1 | post_w_b1 | 47.1 | -0.0 % |
| lairs_one_a1 | lair | 47.8 | lairs_one_b2 | 47.8 | +0.0 % |
| guilds_den_a1 | guild | 50.5 | guilds_den_b2 | 50.5 | +0.0 % |
| tower_c_a1 | point | 52.8 | tower_c_b2 | 52.8 | -0.0 % |
| stag_a1 | camp | 53.2 | stag_b2 | 53.2 | +0.0 % |
| lairs_two_a1 | lair | 53.2 | lairs_two_b2 | 53.2 | +0.0 % |
| peddler_a2 | peddler | 54.6 | peddler_b1 | 54.6 | +0.0 % |
| home_a_a2 | home_node | 55.1 | home_a_b1 | 55.1 | -0.0 % |
| rich_node_a1 | expansion | 57.1 | rich_node_b2 | 57.1 | +0.0 % |
| cache_b_a1 | cache | 60.4 | cache_b_b2 | 60.4 | -0.0 % |
| tower_r_a1 | point | 61.4 | tower_r_b2 | 61.4 | +0.0 % |
| tower_c_a2 | point | 61.8 | tower_c_b1 | 61.8 | -0.0 % |
| x_lane_w | crossing_bridge_lane | 63.6 | x_lane_e | 63.6 | -0.0 % |
| keep_t3 | keep | 64.3 | keep_t1 | 64.3 | +0.0 % |
| post_s_a1 | post | 66.8 | post_s_b2 | 66.8 | +0.0 % |
| inn_a2 | tavern | 67.1 | inn_b1 | 67.4 | -0.5 % |
| nat_node_a2 | expansion | 67.4 | nat_node_b1 | 59.7 | +11.5 % |
| ford_nest_a1 | camp | 67.8 | ford_nest_a1 | 67.8 | -0.0 % |
| x_ford_s | crossing_ford | 67.8 | x_ford_s | 67.8 | -0.0 % |
| home_b_a2 | home_node | 70.6 | home_b_b1 | 70.6 | -0.0 % |
| x_bridge_s | crossing_bridge_road | 74.7 | x_bridge_s | 74.7 | -0.0 % |
| crown | crown | 75.2 | crown | 75.2 | +0.0 % |
| cache_b_b2 | cache | 78.8 | cache_b_a1 | 78.7 | +0.1 % |
| cache_b_a2 | cache | 83.1 | cache_b_b1 | 83.1 | -0.0 % |
| wallow_a2 | camp | 83.7 | wallow_b1 | 80.5 | +3.8 % |
| well_a2 | point | 87.3 | well_b1 | 91.1 | -4.1 % |
| x_lane_e | crossing_bridge_lane | 88.1 | x_lane_w | 88.1 | +0.0 % |
| rich_node_b2 | expansion | 89.6 | rich_node_a1 | 89.5 | +0.1 % |
| tower_r_b2 | point | 90.0 | tower_r_a1 | 90.1 | -0.0 % |
| x_ford_n | crossing_ford | 97.4 | x_ford_n | 106.4 | -8.4 % |
| ford_nest_a2 | camp | 97.4 | ford_nest_a2 | 106.4 | -8.4 % |
| inn_b2 | tavern | 98.5 | inn_a1 | 98.5 | +0.0 % |
| cache_a_a2 | cache | 99.2 | cache_a_b1 | 99.2 | -0.0 % |
| third_node_a2 | expansion | 99.5 | third_node_b1 | 99.5 | -0.0 % |
| rich_node_a2 | expansion | 100.0 | rich_node_b1 | 100.0 | -0.0 % |
| tower_c_b2 | point | 101.6 | tower_c_a1 | 100.8 | +0.7 % |
| tower_c_b1 | point | 101.9 | tower_c_a2 | 98.0 | +3.8 % |
| post_s_b2 | post | 103.4 | post_s_a1 | 103.3 | +0.1 % |
| nat_node_b2 | expansion | 106.0 | nat_node_a1 | 106.0 | +0.0 % |
| well_b2 | point | 110.2 | well_a1 | 109.7 | +0.4 % |
| tower_r_a2 | point | 110.4 | tower_r_b1 | 110.4 | -0.0 % |
| guilds_lodge_a2 | guild | 110.5 | guilds_lodge_b1 | 110.5 | -0.0 % |
| stag_a2 | camp | 111.2 | stag_b1 | 111.2 | -0.0 % |
| lairs_one_a2 | lair | 112.0 | lairs_one_b1 | 112.0 | -0.0 % |
| lairs_two_a2 | lair | 114.0 | lairs_two_b1 | 114.6 | -0.5 % |
| guilds_den_a2 | guild | 114.8 | guilds_den_b1 | 114.8 | -0.0 % |
| cache_b_b1 | cache | 116.2 | cache_b_a2 | 116.1 | +0.1 % |
| stag_b2 | camp | 116.9 | stag_a1 | 116.8 | +0.1 % |
| x_bridge_n | crossing_bridge_road | 117.4 | x_bridge_n | 122.4 | -4.1 % |
| inn_b1 | tavern | 117.9 | inn_a2 | 114.0 | +3.3 % |
| nat_node_b1 | expansion | 119.0 | nat_node_a2 | 115.1 | +3.3 % |
| rich_node_b1 | expansion | 120.0 | rich_node_a2 | 130.1 | -7.8 % |
| cache_a_b2 | cache | 122.0 | cache_a_a1 | 121.9 | +0.0 % |
| post_s_a2 | post | 122.9 | post_s_b1 | 122.9 | -0.0 % |
| lairs_two_b2 | lair | 129.5 | lairs_two_a1 | 129.4 | +0.1 % |
| tower_r_b1 | point | 132.6 | tower_r_a2 | 140.0 | -5.3 % |
| shrine_b2 | point | 132.8 | shrine_a1 | 123.9 | +6.7 % |
| shrine_b1 | point | 132.8 | shrine_a2 | 128.9 | +3.0 % |
| home_b_b2 | home_node | 134.1 | home_b_a1 | 132.1 | +1.4 % |
| peddler_b2 | peddler | 137.8 | peddler_a1 | 132.7 | +3.7 % |
| keep_t4 | keep | 138.7 | keep_t0 | 138.7 | +0.0 % |
| home_a_b2 | home_node | 144.2 | home_a_a1 | 139.6 | +3.2 % |
| post_s_b1 | post | 144.3 | post_s_a2 | 149.3 | -3.3 % |
| lairs_one_b2 | lair | 146.3 | lairs_one_a1 | 146.2 | +0.0 % |
| well_b1 | point | 146.5 | well_a2 | 142.6 | +2.7 % |
| peddler_b1 | peddler | 149.3 | peddler_a2 | 145.3 | +2.6 % |
| third_node_b2 | expansion | 150.5 | third_node_a1 | 150.5 | +0.0 % |
| wallow_b2 | camp | 150.8 | wallow_a1 | 150.7 | +0.0 % |
| cache_a_b1 | cache | 152.3 | cache_a_a2 | 161.2 | -5.5 % |
| home_b_b1 | home_node | 154.7 | home_b_a2 | 150.8 | +2.5 % |
| home_a_b1 | home_node | 155.4 | home_a_a2 | 151.4 | +2.5 % |
| guilds_den_b2 | guild | 157.3 | guilds_den_a1 | 157.2 | +0.0 % |
| post_w_b2 | post | 157.4 | post_w_a1 | 151.4 | +3.8 % |
| stag_b1 | camp | 157.9 | stag_a2 | 162.8 | -3.0 % |
| keep_t1 | keep | 158.6 | keep_t3 | 154.6 | +2.5 % |
| guilds_lodge_b2 | guild | 159.0 | guilds_lodge_a1 | 159.0 | +0.0 % |
| post_w_b1 | post | 161.7 | post_w_a2 | 158.1 | +2.2 % |
| lairs_two_b1 | lair | 170.4 | lairs_two_a2 | 175.0 | -2.6 % |
| wallow_b1 | camp | 177.1 | wallow_a2 | 173.1 | +2.2 % |
| lairs_one_b1 | lair | 180.3 | lairs_one_a2 | 189.2 | -4.7 % |
| guilds_den_b1 | guild | 187.6 | guilds_den_a2 | 196.5 | -4.5 % |
| third_node_b1 | expansion | 190.0 | third_node_a2 | 189.8 | +0.1 % |
| guilds_lodge_b1 | guild | 201.1 | guilds_lodge_a2 | 198.3 | +1.4 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| A1 south-west | 0 | keep_t3 | 64.3 | no | 138.7 | 158.6 | 0.46 |
| A2 north-west | 0 | keep_t0 | 64.3 | no | 135.8 | 154.6 | 0.47 |
| B1 north-east | 1 | keep_t4 | 64.3 | no | 135.8 | 158.6 | 0.47 |
| B2 south-east | 1 | keep_t1 | 64.3 | no | 138.7 | 154.6 | 0.46 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| A1 south-west | ally keep (keep_t3) | 64.3 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| A1 south-west | enemy keep (nearest) (keep_t4) | 138.7 | 0.0 | 0:30 | 0:28 | 0:18 | 0:35 |
| A1 south-west | enemy keep #2 (keep_t1) | 158.6 | 0.0 | 0:34 | 0:32 | 0:21 | 0:40 |
| A1 south-west | nearest expansion (third_node_a1) | 35.3 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| A1 south-west | nearest point (shrine_a1) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| A1 south-west | nearest camp (wallow_a1) | 19.4 | 0.0 | 0:04 | 0:04 | 0:03 | 0:05 |
| A1 south-west | crown (crown) | 75.2 | 0.0 | 0:16 | 0:15 | 0:10 | 0:19 |
| A2 north-west | ally keep (keep_t0) | 64.3 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| A2 north-west | enemy keep (nearest) (keep_t1) | 135.8 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| A2 north-west | enemy keep #2 (keep_t4) | 154.6 | 0.0 | 0:34 | 0:31 | 0:21 | 0:39 |
| A2 north-west | nearest expansion (third_node_a2) | 35.2 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| A2 north-west | nearest point (shrine_a2) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| A2 north-west | nearest camp (wallow_a2) | 19.4 | 0.0 | 0:04 | 0:04 | 0:03 | 0:05 |
| A2 north-west | crown (crown) | 75.2 | 0.0 | 0:16 | 0:15 | 0:10 | 0:19 |
| B1 north-east | ally keep (keep_t4) | 64.3 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| B1 north-east | enemy keep (nearest) (keep_t3) | 135.8 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| B1 north-east | enemy keep #2 (keep_t0) | 154.6 | 0.0 | 0:34 | 0:31 | 0:21 | 0:39 |
| B1 north-east | nearest expansion (third_node_b1) | 35.2 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| B1 north-east | nearest point (shrine_b1) | 26.4 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| B1 north-east | nearest camp (wallow_b1) | 19.4 | 0.0 | 0:04 | 0:04 | 0:03 | 0:05 |
| B1 north-east | crown (crown) | 75.2 | 0.0 | 0:16 | 0:15 | 0:10 | 0:19 |
| B2 south-east | ally keep (keep_t1) | 64.3 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| B2 south-east | enemy keep (nearest) (keep_t0) | 135.8 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| B2 south-east | enemy keep #2 (keep_t3) | 154.6 | 0.0 | 0:34 | 0:31 | 0:21 | 0:39 |
| B2 south-east | nearest expansion (third_node_b2) | 35.3 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
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
| x_lane_w | bridge_lane | 8.0 | 7.0 | 8.0 | x_lane_e | 7.3 |
| x_lane_e | bridge_lane | 8.0 | 7.3 | 8.3 | x_lane_w | 7.0 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 75.5 | 3.8 | (-7.2, 1.6) | - |
| keep_t0 -> keep_t1 | 158.6 | 3.6 | (-7.2, 1.0) | - |
| keep_t0 -> keep_t4 | 138.7 | 2.1 | (9.5, 42.1) | (9.5, 42.1) 2.1 |
| keep_t0 -> third_node_a1 | 35.3 | 15.9 | (-68.7, 55.0) | - |
| keep_t3 -> crown | 75.5 | 4.1 | (-7.2, -1.7) | - |
| keep_t3 -> keep_t4 | 154.6 | 3.8 | (6.6, 1.6) | - |
| keep_t3 -> third_node_a2 | 35.2 | 13.9 | (-69.3, -55.9) | - |
| keep_t1 -> crown | 75.3 | 4.1 | (7.2, -1.7) | - |
| keep_t1 -> keep_t3 | 135.8 | 5.8 | (-0.1, -32.1) | - |
| keep_t1 -> third_node_b1 | 35.2 | 13.8 | (69.3, -55.9) | - |
| keep_t4 -> crown | 75.2 | 3.8 | (7.2, 1.6) | - |
| keep_t4 -> third_node_b2 | 35.3 | 15.9 | (68.7, 55.0) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| A1 south-west | ally | 60.00-72.00 | 64.25 | - |
| A1 south-west | enemy_ally | 2.00-3.00 | 2.16 | - |
| A1 south-west | keep_enemy | 130.00-185.00 | 138.67 | - |
| A1 south-west | natural | 32.00-56.00 | 35.82 | - |
| A1 south-west | rich | 50.00-95.00 | 57.12 | - |
| A1 south-west | crown | 60.00-95.00 | 75.23 | - |
| A2 north-west | ally | 60.00-72.00 | 64.25 | - |
| A2 north-west | enemy_ally | 2.00-3.00 | 2.11 | - |
| A2 north-west | keep_enemy | 130.00-185.00 | 135.75 | - |
| A2 north-west | natural | 32.00-56.00 | 35.82 | - |
| A2 north-west | rich | 50.00-95.00 | 57.12 | - |
| A2 north-west | crown | 60.00-95.00 | 75.22 | - |
| B1 north-east | ally | 60.00-72.00 | 64.25 | - |
| B1 north-east | enemy_ally | 2.00-3.00 | 2.11 | - |
| B1 north-east | keep_enemy | 130.00-185.00 | 135.75 | - |
| B1 north-east | natural | 32.00-56.00 | 35.82 | - |
| B1 north-east | rich | 50.00-95.00 | 57.12 | - |
| B1 north-east | crown | 60.00-95.00 | 75.22 | - |
| B2 south-east | ally | 60.00-72.00 | 64.25 | - |
| B2 south-east | enemy_ally | 2.00-3.00 | 2.16 | - |
| B2 south-east | keep_enemy | 130.00-185.00 | 138.67 | - |
| B2 south-east | natural | 32.00-56.00 | 35.82 | - |
| B2 south-east | rich | 50.00-95.00 | 57.12 | - |
| B2 south-east | crown | 60.00-95.00 | 75.23 | - |


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
| A2 north-west | 3 | 3 | 20 | 51 |
| B1 north-east | 3 | 4 | 20 | 51 |
| B2 south-east | 3 | 3 | 20 | 51 |


## Hottest metres (every spot-pair shortest path, 4656 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-0.5, 36.5) | 279 | 6 % |
| 2 | (43.5, -7.5) | 239 | 5 % |
| 3 | (-23.5, 24.5) | 226 | 5 % |
| 4 | (-43.5, 6.5) | 224 | 5 % |
| 5 | (14.5, 4.5) | 211 | 5 % |
| 6 | (23.5, 24.5) | 211 | 5 % |
| 7 | (-24.5, -23.5) | 209 | 4 % |
| 8 | (8.5, 41.5) | 208 | 4 % |
| 9 | (1.5, 0.5) | 206 | 4 % |
| 10 | (-2.5, -37.5) | 199 | 4 % |


## Info findings (732)
| Check | Where | What |
|---|---|---|
| N3 | island 15 at (-71.6, -32.4) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 16 at (71.6, -32.4) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 45 at (-71.6, 32.4) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 46 at (71.6, 32.4) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 54 islands on top of colliders (743 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | keep_t3-cache_a_b2 vs keep_t4-cache_a_a2 | 153.2 m vs 161.2 m (5.0 %) |
| F2 | home_a_a1-tower_c_a2 vs home_a_b2-tower_c_b1 | 64.4 m vs 61.2 m (5.0 %) |
| F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_b2-cache_b_a2 | 150.2 m vs 158.0 m (4.9 %) |
| F2 | third_node_a1-tower_c_b2 vs third_node_b1-tower_c_a2 | 123.2 m vs 117.1 m (4.9 %) |
| F2 | wallow_a2-x_lane_e vs wallow_b1-x_lane_w | 105.1 m vs 110.5 m (4.9 %) |
| F2 | guilds_den_a2-lairs_one_b1 vs guilds_den_b1-lairs_one_a2 | 155.8 m vs 148.1 m (4.9 %) |
| F2 | third_node_b1-tower_c_a2 vs third_node_b2-tower_c_a1 | 117.1 m vs 123.2 m (4.9 %) |
| F2 | guilds_lodge_a1-lairs_one_b2 vs guilds_lodge_b2-lairs_one_a1 | 153.0 m vs 160.9 m (4.9 %) |
| F2 | home_a_a1-lairs_one_b1 vs home_a_b1-lairs_one_a1 | 181.2 m vs 172.4 m (4.9 %) |
| F2 | wallow_b1-x_lane_w vs wallow_b2-x_lane_w | 110.5 m vs 105.1 m (4.9 %) |
| F2 | home_b_b1-guilds_den_a1 vs home_b_b2-guilds_den_a2 | 192.2 m vs 202.1 m (4.9 %) |
| F2 | wallow_a1-x_lane_e vs wallow_b1-x_lane_w | 105.1 m vs 110.5 m (4.9 %) |
| F2 | peddler_b1-lairs_two_a1 vs peddler_b2-lairs_two_a2 | 156.7 m vs 164.7 m (4.9 %) |
| F2 | third_node_a1-tower_c_b2 vs third_node_a2-tower_c_b1 | 123.2 m vs 117.2 m (4.9 %) |
| F2 | home_a_b1-lairs_one_a1 vs home_a_b2-lairs_one_a2 | 172.4 m vs 181.2 m (4.9 %) |
| F2 | home_b_a2-guilds_den_b2 vs home_b_b2-guilds_den_a2 | 192.2 m vs 202.1 m (4.9 %) |
| F2 | home_a_a1-lairs_one_b1 vs home_a_a2-lairs_one_b2 | 181.2 m vs 172.4 m (4.9 %) |
| F2 | peddler_a2-lairs_two_b2 vs peddler_b2-lairs_two_a2 | 156.7 m vs 164.7 m (4.9 %) |
| F2 | tower_r_a2-post_s_b2 vs tower_r_b2-post_s_a2 | 164.7 m vs 156.7 m (4.9 %) |
| F2 | home_a_a2-lairs_one_b2 vs home_a_b2-lairs_one_a2 | 172.4 m vs 181.2 m (4.9 %) |
| F2 | home_b_b1-guilds_lodge_a1 vs home_b_b2-guilds_lodge_a2 | 194.0 m vs 203.9 m (4.9 %) |
| F2 | home_b_a2-guilds_lodge_b2 vs home_b_b2-guilds_lodge_a2 | 194.0 m vs 203.9 m (4.9 %) |
| F2 | third_node_a2-tower_c_b1 vs third_node_b2-tower_c_a1 | 117.2 m vs 123.2 m (4.9 %) |
| F2 | guilds_den_a2-peddler_a1 vs guilds_den_b2-peddler_b1 | 110.5 m vs 105.1 m (4.8 %) |
| F2 | guilds_den_a1-peddler_a2 vs guilds_den_a2-peddler_a1 | 105.1 m vs 110.5 m (4.8 %) |
| F2 | tower_r_a1-post_s_b1 vs tower_r_a2-post_s_b2 | 156.8 m vs 164.7 m (4.8 %) |
| F2 | tower_r_b1-post_s_a1 vs tower_r_b2-post_s_a2 | 164.6 m vs 156.7 m (4.8 %) |
| F2 | shrine_a1-lairs_two_b1 vs shrine_a2-lairs_two_b2 | 147.8 m vs 140.8 m (4.8 %) |
| F2 | peddler_a1-lairs_one_b1 vs peddler_b2-lairs_one_a2 | 170.4 m vs 179.0 m (4.8 %) |
| F2 | wallow_a2-guilds_den_b1 vs wallow_b1-guilds_den_a2 | 168.3 m vs 160.2 m (4.8 %) |
| F2 | home_b_a1-post_s_b1 vs home_b_b2-post_s_a2 | 147.5 m vs 154.9 m (4.8 %) |
| F2 | home_b_a1-shrine_b1 vs home_b_b2-shrine_a2 | 135.4 m vs 128.9 m (4.8 %) |
| F2 | keep_t1-well_b2 vs keep_t4-well_b1 | 86.7 m vs 91.1 m (4.7 %) |
| F2 | wallow_a1-guilds_den_b2 vs wallow_b1-guilds_den_a2 | 168.2 m vs 160.2 m (4.7 %) |
| F2 | home_b_b1-shrine_a1 vs home_b_b2-shrine_a2 | 135.3 m vs 128.9 m (4.7 %) |
| F2 | home_b_a2-shrine_b2 vs home_b_b2-shrine_a2 | 135.3 m vs 128.9 m (4.7 %) |
| F2 | shrine_a1-lairs_two_b1 vs shrine_b2-lairs_two_a2 | 147.8 m vs 140.8 m (4.7 %) |
| F2 | wallow_a1-guilds_lodge_b1 vs wallow_a2-guilds_lodge_b2 | 219.6 m vs 209.2 m (4.7 %) |
| F2 | tower_r_a1-post_s_b1 vs tower_r_b1-post_s_a1 | 156.8 m vs 164.6 m (4.7 %) |
| F2 | third_node_a1-lairs_two_a2 vs third_node_a2-lairs_two_a1 | 149.1 m vs 156.5 m (4.7 %) |
| F2 | third_node_a1-lairs_two_a2 vs third_node_b1-lairs_two_b2 | 149.1 m vs 156.5 m (4.7 %) |
| F2 | home_b_a1-guilds_lodge_b1 vs home_b_b1-guilds_lodge_a1 | 203.6 m vs 194.0 m (4.7 %) |
| F2 | wallow_b1-guilds_den_a2 vs wallow_b2-guilds_den_a1 | 160.2 m vs 168.2 m (4.7 %) |
| F2 | home_b_a1-guilds_lodge_b1 vs home_b_a2-guilds_lodge_b2 | 203.6 m vs 194.0 m (4.7 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t4-lairs_one_a2 | 180.3 m vs 189.2 m (4.7 %) |
| F2 | home_a_a1-cache_b_b1 vs home_a_b1-cache_b_a1 | 108.1 m vs 103.1 m (4.7 %) |
| F2 | guilds_den_a2-x_ford_s vs guilds_den_b2-x_ford_n | 150.7 m vs 158.0 m (4.7 %) |
| F2 | guilds_den_b1-x_ford_s vs guilds_den_b2-x_ford_n | 150.7 m vs 158.0 m (4.7 %) |
| F2 | guilds_den_b1-lairs_one_a2 vs guilds_den_b2-lairs_one_a1 | 148.1 m vs 155.3 m (4.7 %) |
| F2 | cache_b_a1-x_lane_e vs cache_b_b1-x_lane_w | 50.0 m vs 47.7 m (4.6 %) |
| F2 | keep_t3-lairs_two_b2 vs keep_t4-lairs_two_a2 | 166.9 m vs 175.0 m (4.6 %) |
| F2 | wallow_a1-cache_a_b1 vs wallow_b2-cache_a_a2 | 171.1 m vs 179.4 m (4.6 %) |
| F2 | third_node_a2-inn_b1 vs third_node_b2-inn_a1 | 114.7 m vs 120.2 m (4.6 %) |
| F2 | third_node_b1-inn_a2 vs third_node_b2-inn_a1 | 114.7 m vs 120.2 m (4.6 %) |
| F2 | home_a_b1-cache_b_a1 vs home_a_b2-cache_b_a2 | 103.1 m vs 108.1 m (4.6 %) |
| F2 | tower_r_a1-guilds_den_b2 vs tower_r_b1-guilds_den_a2 | 100.1 m vs 95.5 m (4.6 %) |
| F2 | tower_r_b1-guilds_den_a2 vs tower_r_b2-guilds_den_a1 | 95.5 m vs 100.1 m (4.6 %) |
| F2 | third_node_a1-inn_b2 vs third_node_a2-inn_b1 | 120.2 m vs 114.7 m (4.6 %) |
| F2 | third_node_a1-inn_b2 vs third_node_b1-inn_a2 | 120.2 m vs 114.7 m (4.6 %) |
| F2 | home_a_a1-cache_b_b1 vs home_a_a2-cache_b_b2 | 108.1 m vs 103.2 m (4.6 %) |
| F2 | third_node_a2-lairs_one_b1 vs third_node_b1-lairs_one_a2 | 154.9 m vs 147.8 m (4.6 %) |
| F2 | keep_t3-well_a1 vs keep_t4-well_b1 | 86.9 m vs 91.1 m (4.5 %) |
| F2 | keep_t0-guilds_den_b1 vs keep_t4-guilds_den_a2 | 187.6 m vs 196.5 m (4.5 %) |
| F2 | tower_r_a2-guilds_den_b1 vs tower_r_b1-guilds_den_a2 | 100.0 m vs 95.5 m (4.5 %) |
| F2 | home_a_a2-cache_b_b2 vs home_a_b2-cache_b_a2 | 103.2 m vs 108.1 m (4.5 %) |
| F2 | cache_b_a1-x_lane_e vs cache_b_a2-x_lane_e | 50.0 m vs 47.7 m (4.5 %) |
| F2 | keep_t0-guilds_lodge_b1 vs keep_t1-guilds_lodge_a1 | 201.1 m vs 192.0 m (4.5 %) |
| F2 | post_s_b1-guilds_den_a2 vs post_s_b2-guilds_den_a1 | 104.2 m vs 109.1 m (4.5 %) |
| F2 | third_node_a2-cache_b_b2 vs third_node_b1-cache_b_a1 | 147.9 m vs 141.3 m (4.5 %) |
| F2 | tower_c_a1-wallow_b1 vs tower_c_a2-wallow_b2 | 120.4 m vs 115.0 m (4.5 %) |
| F2 | ford_nest_a1-lairs_one_a1 vs ford_nest_a2-lairs_one_b1 | 79.1 m vs 82.8 m (4.5 %) |
| F2 | ford_nest_a1-lairs_one_b2 vs ford_nest_a2-lairs_one_a2 | 79.1 m vs 82.8 m (4.5 %) |
| F2 | ford_nest_a1-lairs_one_a1 vs ford_nest_a2-lairs_one_a2 | 79.1 m vs 82.8 m (4.5 %) |
| F2 | ford_nest_a1-lairs_one_b2 vs ford_nest_a2-lairs_one_b1 | 79.1 m vs 82.8 m (4.5 %) |
| F2 | tower_c_a2-wallow_b2 vs tower_c_b2-wallow_a2 | 115.0 m vs 120.4 m (4.5 %) |
| F2 | tower_r_a2-cache_a_a1 vs tower_r_b1-cache_a_b2 | 138.8 m vs 132.6 m (4.4 %) |
| F2 | home_a_b1-well_a1 vs home_a_b2-well_a2 | 135.7 m vs 142.0 m (4.4 %) |
| F2 | tower_r_b1-cache_a_b2 vs tower_r_b2-cache_a_b1 | 132.6 m vs 138.8 m (4.4 %) |
| F2 | home_a_a2-well_b2 vs home_a_b2-well_a2 | 135.7 m vs 142.0 m (4.4 %) |
| F2 | post_s_a1-guilds_den_b2 vs post_s_b1-guilds_den_a2 | 109.1 m vs 104.2 m (4.4 %) |
| F2 | lairs_one_b1-lairs_two_b2 vs lairs_one_b2-lairs_two_b1 | 169.3 m vs 161.8 m (4.4 %) |
| F2 | third_node_a1-shrine_b2 vs third_node_b2-shrine_a1 | 152.5 m vs 145.7 m (4.4 %) |
| F2 | tower_r_a1-cache_a_a2 vs tower_r_a2-cache_a_a1 | 132.7 m vs 138.8 m (4.4 %) |
| F2 | post_s_a2-guilds_den_b1 vs post_s_b1-guilds_den_a2 | 109.0 m vs 104.2 m (4.4 %) |
| F2 | tower_r_a1-cache_a_a2 vs tower_r_b2-cache_a_b1 | 132.7 m vs 138.8 m (4.4 %) |
| F2 | peddler_a1-peddler_b2 vs peddler_a2-peddler_b1 | 135.6 m vs 129.6 m (4.4 %) |
| F2 | home_b_a1-stag_b1 vs home_b_b2-stag_a2 | 161.1 m vs 168.5 m (4.4 %) |
| F2 | home_b_a2-post_s_b2 vs home_b_b2-post_s_a2 | 148.1 m vs 154.9 m (4.4 %) |
| F2 | home_a_b1-tower_c_b2 vs home_a_b2-tower_c_b1 | 58.6 m vs 61.2 m (4.4 %) |
| F2 | guilds_lodge_a2-lairs_one_b1 vs guilds_lodge_b1-lairs_one_a2 | 163.0 m vs 156.0 m (4.3 %) |
| F2 | keep_t0-third_node_b1 vs keep_t3-third_node_b2 | 190.0 m vs 181.7 m (4.3 %) |
| F2 | home_a_a1-rich_node_b1 vs home_a_b1-rich_node_a1 | 120.9 m vs 115.7 m (4.3 %) |
| F2 | home_a_a1-guilds_lodge_a2 vs home_a_a2-guilds_lodge_a1 | 101.4 m vs 97.0 m (4.3 %) |
| F2 | home_a_a1-guilds_lodge_a2 vs home_a_b2-guilds_lodge_b1 | 101.4 m vs 97.0 m (4.3 %) |
| F2 | home_a_a1-guilds_lodge_a2 vs home_a_b1-guilds_lodge_b2 | 101.4 m vs 97.0 m (4.3 %) |
| F2 | wallow_a2-stag_a1 vs wallow_b1-stag_b2 | 129.3 m vs 135.1 m (4.3 %) |
| F2 | wallow_b1-stag_b2 vs wallow_b2-stag_b1 | 135.1 m vs 129.3 m (4.3 %) |
| F2 | wallow_a1-stag_a2 vs wallow_b1-stag_b2 | 129.3 m vs 135.1 m (4.3 %) |
| F2 | cache_b_a1-x_lane_e vs cache_b_b2-x_lane_w | 50.0 m vs 47.8 m (4.3 %) |
| F2 | home_b_a1-well_b1 vs home_b_b2-well_a2 | 149.0 m vs 142.6 m (4.3 %) |
| F2 | wallow_a1-lairs_two_b1 vs wallow_b2-lairs_two_a2 | 184.8 m vs 193.1 m (4.3 %) |
| F2 | home_a_a1-rich_node_b1 vs home_a_a2-rich_node_b2 | 120.9 m vs 115.7 m (4.3 %) |
| F2 | third_node_a2-lairs_two_a1 vs third_node_b2-lairs_two_b1 | 156.5 m vs 149.8 m (4.3 %) |
| F2 | third_node_b1-lairs_two_b2 vs third_node_b2-lairs_two_b1 | 156.5 m vs 149.8 m (4.3 %) |
| F2 | peddler_a2-x_bridge_s vs peddler_b2-x_bridge_n | 107.4 m vs 112.2 m (4.3 %) |
| F2 | tower_r_a2-post_w_a1 vs tower_r_b2-post_w_b1 | 109.9 m vs 114.8 m (4.3 %) |
| F2 | tower_r_b1-post_w_b2 vs tower_r_b2-post_w_b1 | 109.9 m vs 114.8 m (4.3 %) |
| F2 | wallow_a1-cache_b_b1 vs wallow_b1-cache_b_a1 | 135.1 m vs 129.3 m (4.3 %) |
| F2 | keep_t3-x_lane_e vs keep_t1-x_lane_w | 88.1 m vs 92.0 m (4.3 %) |
| F2 | home_b_a1-peddler_b1 vs home_b_b2-peddler_a2 | 151.8 m vs 145.3 m (4.2 %) |
| F2 | peddler_b1-x_bridge_s vs peddler_b2-x_bridge_n | 107.4 m vs 112.2 m (4.2 %) |
| F2 | keep_t3-third_node_b2 vs keep_t4-third_node_a2 | 181.7 m vs 189.8 m (4.2 %) |
| F2 | keep_t1-x_lane_w vs keep_t4-x_lane_w | 92.0 m vs 88.1 m (4.2 %) |
| F2 | keep_t0-x_lane_e vs keep_t1-x_lane_w | 88.1 m vs 92.0 m (4.2 %) |
| F2 | home_a_a1-third_node_a2 vs home_a_b2-third_node_b1 | 90.3 m vs 86.5 m (4.2 %) |
| F2 | home_a_a1-third_node_a2 vs home_a_a2-third_node_a1 | 90.3 m vs 86.5 m (4.2 %) |
| F2 | home_a_a1-third_node_a2 vs home_a_b1-third_node_b2 | 90.3 m vs 86.5 m (4.2 %) |
| F2 | peddler_a1-x_bridge_n vs peddler_b2-x_bridge_n | 107.4 m vs 112.2 m (4.2 %) |
| F2 | third_node_a1-lairs_one_b2 vs third_node_a2-lairs_one_b1 | 148.4 m vs 154.9 m (4.2 %) |
| F2 | wallow_b1-lairs_one_a1 vs wallow_b2-lairs_one_a2 | 198.6 m vs 207.3 m (4.2 %) |
| F2 | wallow_a2-cache_b_b2 vs wallow_b1-cache_b_a1 | 135.0 m vs 129.3 m (4.2 %) |
| F2 | tower_r_a1-post_w_a2 vs tower_r_b2-post_w_b1 | 110.0 m vs 114.8 m (4.2 %) |
| F2 | third_node_a2-cache_a_a2 vs third_node_b1-cache_a_b1 | 31.6 m vs 33.0 m (4.2 %) |
| F2 | home_b_b1-x_ford_s vs home_b_b2-x_ford_n | 97.8 m vs 102.1 m (4.2 %) |
| F2 | home_b_b1-ford_nest_a1 vs home_b_b2-ford_nest_a2 | 97.8 m vs 102.1 m (4.2 %) |
| F2 | home_a_b1-post_s_b2 vs home_a_b2-post_s_b1 | 113.9 m vs 118.9 m (4.2 %) |
| F2 | home_a_a2-post_s_a1 vs home_a_b2-post_s_b1 | 113.9 m vs 118.9 m (4.2 %) |
| F2 | guilds_lodge_a2-cache_b_b2 vs guilds_lodge_b1-cache_b_a1 | 159.0 m vs 152.4 m (4.2 %) |
| F2 | home_b_a2-ford_nest_a1 vs home_b_b1-ford_nest_a1 | 102.1 m vs 97.8 m (4.2 %) |
| F2 | home_b_a2-x_ford_s vs home_b_b1-x_ford_s | 102.1 m vs 97.8 m (4.2 %) |
| F2 | peddler_a2-lairs_two_b1 vs peddler_b2-lairs_two_a1 | 134.5 m vs 128.9 m (4.2 %) |
| F2 | rich_node_a1-peddler_b2 vs rich_node_a2-peddler_b1 | 94.2 m vs 90.3 m (4.1 %) |
| F2 | rich_node_a1-peddler_b2 vs rich_node_b1-peddler_a2 | 94.2 m vs 90.3 m (4.1 %) |
| F2 | stag_a1-guilds_lodge_b1 vs stag_b2-guilds_lodge_a2 | 197.8 m vs 189.6 m (4.1 %) |
| F2 | stag_a2-guilds_lodge_b2 vs stag_b2-guilds_lodge_a2 | 197.8 m vs 189.6 m (4.1 %) |
| F2 | home_a_a1-post_w_b2 vs home_a_b1-post_w_a2 | 161.9 m vs 155.2 m (4.1 %) |
| F2 | home_a_a1-post_w_b2 vs home_a_a2-post_w_b1 | 161.9 m vs 155.2 m (4.1 %) |
| F2 | rich_node_a1-peddler_b2 vs rich_node_b2-peddler_a1 | 94.2 m vs 90.3 m (4.1 %) |
| F2 | home_b_a1-lairs_two_b1 vs home_b_b1-lairs_two_a1 | 173.6 m vs 166.5 m (4.1 %) |
| F2 | home_a_a1-peddler_b2 vs home_a_b1-peddler_a2 | 142.3 m vs 136.4 m (4.1 %) |
| F2 | home_a_a1-peddler_b2 vs home_a_a2-peddler_b1 | 142.3 m vs 136.4 m (4.1 %) |
| F2 | stag_b1-guilds_den_a2 vs stag_b2-guilds_den_a1 | 115.1 m vs 120.1 m (4.1 %) |
| F2 | stag_a1-guilds_den_b2 vs stag_b1-guilds_den_a2 | 120.1 m vs 115.1 m (4.1 %) |
| F2 | home_a_a1-post_w_b2 vs home_a_b2-post_w_a1 | 161.9 m vs 155.2 m (4.1 %) |
| F2 | peddler_a1-lairs_two_b2 vs peddler_a2-lairs_two_b1 | 129.0 m vs 134.5 m (4.1 %) |
| F2 | home_a_a1-peddler_b2 vs home_a_b2-peddler_a1 | 142.3 m vs 136.5 m (4.1 %) |
| F2 | keep_t0-well_a2 vs keep_t4-well_b1 | 87.3 m vs 91.1 m (4.1 %) |
| F2 | peddler_a2-lairs_two_b1 vs peddler_b1-lairs_two_a2 | 134.5 m vs 129.0 m (4.1 %) |
| F2 | keep_t0-x_bridge_n vs keep_t4-x_bridge_n | 117.4 m vs 122.4 m (4.1 %) |
| F2 | keep_t3-guilds_den_b2 vs keep_t4-guilds_den_a2 | 188.5 m vs 196.5 m (4.1 %) |
| F2 | stag_a2-guilds_den_b1 vs stag_b1-guilds_den_a2 | 120.0 m vs 115.1 m (4.1 %) |
| F2 | keep_t3-guilds_lodge_b2 vs keep_t4-guilds_lodge_a2 | 190.3 m vs 198.3 m (4.0 %) |
| F2 | home_b_a2-stag_b2 vs home_b_b2-stag_a2 | 161.7 m vs 168.5 m (4.0 %) |
| F2 | lairs_one_a1-x_ford_n vs lairs_one_b2-x_ford_n | 145.0 m vs 151.1 m (4.0 %) |
| F2 | wallow_a1-cache_b_b1 vs wallow_b2-cache_b_a2 | 135.1 m vs 129.7 m (4.0 %) |
| F2 | wallow_a2-cache_a_b2 vs wallow_b2-cache_a_a2 | 172.2 m vs 179.4 m (4.0 %) |
| F2 | wallow_a1-lairs_one_b1 vs wallow_b2-lairs_one_a2 | 199.1 m vs 207.3 m (4.0 %) |
| F2 | nat_node_a2-well_a1 vs nat_node_b1-well_b2 | 70.5 m vs 67.6 m (4.0 %) |
| F2 | nat_node_a2-well_a1 vs nat_node_b2-well_b1 | 70.5 m vs 67.6 m (4.0 %) |
| F2 | nat_node_a1-well_a2 vs nat_node_a2-well_a1 | 67.6 m vs 70.5 m (4.0 %) |
| F2 | wallow_b1-inn_a1 vs wallow_b2-inn_a2 | 136.4 m vs 131.0 m (4.0 %) |
| F2 | wallow_a2-inn_b2 vs wallow_b2-inn_a2 | 136.4 m vs 131.0 m (4.0 %) |
| F2 | wallow_a1-inn_b1 vs wallow_b2-inn_a2 | 136.4 m vs 131.0 m (4.0 %) |
| F2 | home_a_a1-post_s_a2 vs home_a_b2-post_s_b1 | 114.2 m vs 118.9 m (4.0 %) |
| F2 | third_node_a1-guilds_lodge_b1 vs third_node_b1-guilds_lodge_a1 | 232.6 m vs 223.4 m (4.0 %) |
| F2 | keep_t3-x_bridge_s vs keep_t4-x_bridge_n | 117.6 m vs 122.4 m (4.0 %) |
| F2 | third_node_a1-guilds_lodge_b1 vs third_node_a2-guilds_lodge_b2 | 232.6 m vs 223.4 m (4.0 %) |
| F2 | wallow_a2-cache_b_b2 vs wallow_b2-cache_b_a2 | 135.0 m vs 129.7 m (3.9 %) |
| F2 | third_node_a2-peddler_b2 vs third_node_b2-peddler_a2 | 178.6 m vs 186.0 m (3.9 %) |
| F2 | third_node_b1-peddler_a1 vs third_node_b2-peddler_a2 | 178.7 m vs 186.0 m (3.9 %) |
| F2 | third_node_a1-guilds_lodge_b1 vs third_node_b2-guilds_lodge_a2 | 232.6 m vs 223.5 m (3.9 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_a2-wallow_b2 | 137.5 m vs 132.1 m (3.9 %) |
| F2 | nat_node_a2-wallow_b2 vs nat_node_b2-wallow_a2 | 132.1 m vs 137.5 m (3.9 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_b1-wallow_a1 | 137.5 m vs 132.1 m (3.9 %) |
| F2 | nat_node_b1-wallow_a1 vs nat_node_b2-wallow_a2 | 132.1 m vs 137.5 m (3.9 %) |
| F2 | keep_t0-well_b1 vs keep_t3-well_b2 | 146.5 m vs 140.8 m (3.9 %) |
| F2 | cache_b_a1-lairs_one_b2 vs cache_b_b1-lairs_one_a2 | 91.5 m vs 95.2 m (3.9 %) |
| F2 | home_b_b1-post_w_a1 vs home_b_b2-post_w_a2 | 164.5 m vs 158.1 m (3.9 %) |
| F2 | home_b_a2-post_w_b2 vs home_b_b2-post_w_a2 | 164.5 m vs 158.1 m (3.9 %) |
| F2 | nat_node_a2-wallow_b1 vs nat_node_b1-wallow_a2 | 118.0 m vs 122.8 m (3.9 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_a2-wallow_b2 | 173.9 m vs 167.1 m (3.9 %) |
| F2 | home_b_a1-lairs_two_b1 vs home_b_b2-lairs_two_a2 | 173.6 m vs 180.6 m (3.9 %) |
| F2 | keep_t1-cache_a_a1 vs keep_t4-cache_a_a2 | 155.0 m vs 161.2 m (3.9 %) |
| F2 | cache_b_a1-lairs_one_b2 vs cache_b_a2-lairs_one_b1 | 91.5 m vs 95.2 m (3.9 %) |
| F2 | cache_b_b1-lairs_one_a2 vs cache_b_b2-lairs_one_a1 | 95.2 m vs 91.5 m (3.9 %) |
| F2 | wallow_a2-cache_a_a1 vs wallow_b1-cache_a_b2 | 116.9 m vs 121.6 m (3.9 %) |
| F2 | rich_node_a1-post_w_b2 vs rich_node_b1-post_w_a2 | 113.8 m vs 109.4 m (3.9 %) |
| F2 | wallow_a1-cache_a_a2 vs wallow_b1-cache_a_b2 | 116.9 m vs 121.6 m (3.9 %) |
| F2 | wallow_b1-cache_a_b2 vs wallow_b2-cache_a_b1 | 121.6 m vs 116.9 m (3.9 %) |
| F2 | wallow_a1-guilds_den_b1 vs wallow_b2-guilds_den_a2 | 206.3 m vs 214.6 m (3.9 %) |
| F2 | shrine_a1-lairs_one_b1 vs shrine_b1-lairs_one_a1 | 157.4 m vs 151.3 m (3.9 %) |
| F2 | nat_node_a1-wallow_b2 vs nat_node_a2-wallow_b1 | 122.8 m vs 118.0 m (3.9 %) |
| F2 | guilds_den_a1-x_ford_n vs guilds_den_b2-x_ford_n | 152.0 m vs 158.0 m (3.8 %) |
| F2 | third_node_a1-tower_c_b1 vs third_node_b1-tower_c_a1 | 138.6 m vs 133.3 m (3.8 %) |
| F2 | third_node_b1-tower_c_a1 vs third_node_b2-tower_c_a2 | 133.3 m vs 138.6 m (3.8 %) |
| F2 | shrine_a1-lairs_one_b1 vs shrine_a2-lairs_one_b2 | 157.4 m vs 151.4 m (3.8 %) |
| F2 | nat_node_a2-wallow_b1 vs nat_node_b2-wallow_a1 | 118.0 m vs 122.7 m (3.8 %) |
| F2 | keep_t0-wallow_a2 vs keep_t1-wallow_b2 | 83.7 m vs 80.4 m (3.8 %) |
| F2 | keep_t0-wallow_a2 vs keep_t3-wallow_a1 | 83.7 m vs 80.4 m (3.8 %) |
| F2 | keep_t0-wallow_a2 vs keep_t4-wallow_b1 | 83.7 m vs 80.5 m (3.8 %) |
| F2 | cache_b_a2-lairs_one_b1 vs cache_b_b2-lairs_one_a1 | 95.2 m vs 91.5 m (3.8 %) |
| F2 | third_node_b1-shrine_a2 vs third_node_b2-shrine_a1 | 140.1 m vs 145.7 m (3.8 %) |
| F2 | third_node_a2-shrine_b1 vs third_node_b2-shrine_a1 | 140.1 m vs 145.7 m (3.8 %) |
| F2 | keep_t0-tower_c_b1 vs keep_t4-tower_c_a2 | 101.9 m vs 98.0 m (3.8 %) |
| F2 | guilds_den_a1-cache_b_b1 vs guilds_den_b1-cache_b_a1 | 173.2 m vs 166.6 m (3.8 %) |
| F2 | tower_c_a1-guilds_lodge_b1 vs tower_c_a2-guilds_lodge_b2 | 144.4 m vs 150.1 m (3.8 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t1-lairs_two_a1 | 170.4 m vs 163.9 m (3.8 %) |
| F2 | tower_r_a1-tower_r_b1 vs tower_r_b2-tower_r_a2 | 142.8 m vs 148.5 m (3.8 %) |
| F2 | tower_c_a1-guilds_lodge_b1 vs tower_c_b1-guilds_lodge_a1 | 144.4 m vs 150.1 m (3.8 %) |
| F2 | keep_t0-post_w_b2 vs keep_t3-post_w_b1 | 157.4 m vs 151.4 m (3.8 %) |
| F2 | keep_t0-post_w_b2 vs keep_t1-post_w_a2 | 157.4 m vs 151.4 m (3.8 %) |
| F2 | shrine_b1-cache_a_b2 vs shrine_b2-cache_a_b1 | 76.0 m vs 79.0 m (3.8 %) |
| F2 | shrine_a2-cache_a_a1 vs shrine_b2-cache_a_b1 | 76.0 m vs 79.0 m (3.8 %) |
| F2 | shrine_a1-cache_a_a2 vs shrine_b2-cache_a_b1 | 76.0 m vs 79.0 m (3.8 %) |
| F2 | keep_t1-tower_c_a1 vs keep_t4-tower_c_a2 | 101.8 m vs 98.0 m (3.8 %) |
| F2 | keep_t3-tower_c_b2 vs keep_t4-tower_c_a2 | 101.8 m vs 98.0 m (3.8 %) |
| F2 | well_a1-lairs_one_b1 vs well_b1-lairs_one_a1 | 192.0 m vs 184.8 m (3.8 %) |
| F2 | keep_t0-post_w_b2 vs keep_t4-post_w_a1 | 157.4 m vs 151.4 m (3.8 %) |
| F2 | well_b1-lairs_one_a1 vs well_b2-lairs_one_a2 | 184.8 m vs 192.0 m (3.8 %) |
| F2 | home_b_a2-tower_r_a1 vs home_b_b2-tower_r_b1 | 113.6 m vs 118.1 m (3.8 %) |
| F2 | home_b_b1-tower_r_b2 vs home_b_b2-tower_r_b1 | 113.6 m vs 118.1 m (3.8 %) |
| F2 | guilds_lodge_a1-guilds_lodge_b1 vs guilds_lodge_b2-guilds_lodge_a2 | 243.6 m vs 234.5 m (3.8 %) |
| F2 | tower_c_a1-guilds_lodge_b1 vs tower_c_b2-guilds_lodge_a2 | 144.4 m vs 150.0 m (3.8 %) |
| F2 | wallow_a2-lairs_two_b2 vs wallow_b2-lairs_two_a2 | 185.8 m vs 193.1 m (3.8 %) |
| F2 | wallow_a1-guilds_lodge_b1 vs wallow_b1-guilds_lodge_a1 | 219.6 m vs 211.4 m (3.7 %) |
| F2 | keep_t0-peddler_b2 vs keep_t3-peddler_b1 | 137.8 m vs 132.7 m (3.7 %) |
| F2 | keep_t0-peddler_b2 vs keep_t1-peddler_a2 | 137.8 m vs 132.7 m (3.7 %) |
| F2 | home_b_a1-post_w_b1 vs home_b_b2-post_w_a2 | 164.2 m vs 158.1 m (3.7 %) |
| F2 | keep_t0-peddler_b2 vs keep_t4-peddler_a1 | 137.8 m vs 132.7 m (3.7 %) |
| F2 | keep_t1-well_a1 vs keep_t4-well_a2 | 137.3 m vs 142.6 m (3.7 %) |
| F2 | well_a2-guilds_den_b2 vs well_b2-guilds_den_a2 | 191.9 m vs 199.3 m (3.7 %) |
| F2 | home_b_a1-tower_r_a2 vs home_b_b2-tower_r_b1 | 113.7 m vs 118.1 m (3.7 %) |
| F2 | home_b_a1-third_node_b1 vs home_b_b1-third_node_a1 | 192.5 m vs 185.5 m (3.7 %) |
| F2 | home_b_a1-third_node_b1 vs home_b_a2-third_node_b2 | 192.5 m vs 185.5 m (3.7 %) |
| F2 | home_b_b1-x_bridge_s vs home_b_b2-x_bridge_n | 123.4 m vs 128.1 m (3.6 %) |
| F2 | third_node_b1-x_ford_s vs third_node_b2-x_ford_n | 126.7 m vs 131.5 m (3.6 %) |
| F2 | third_node_a2-x_ford_s vs third_node_b2-x_ford_n | 126.7 m vs 131.5 m (3.6 %) |
| F2 | third_node_b1-ford_nest_a1 vs third_node_b2-ford_nest_a2 | 126.7 m vs 131.5 m (3.6 %) |
| F2 | third_node_a2-ford_nest_a1 vs third_node_b2-ford_nest_a2 | 126.7 m vs 131.5 m (3.6 %) |
| F2 | home_a_a1-home_a_b2 vs home_a_a2-home_a_b1 | 148.7 m vs 143.3 m (3.6 %) |
| F2 | guilds_lodge_a1-lairs_two_a2 vs guilds_lodge_a2-lairs_two_a1 | 160.1 m vs 166.2 m (3.6 %) |
| F2 | guilds_lodge_a1-lairs_two_a2 vs guilds_lodge_b1-lairs_two_b2 | 160.1 m vs 166.2 m (3.6 %) |
| F2 | third_node_b1-stag_a1 vs third_node_b2-stag_a2 | 184.3 m vs 191.2 m (3.6 %) |
| F2 | shrine_a1-x_bridge_n vs shrine_a2-x_bridge_s | 94.8 m vs 91.4 m (3.6 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_b2-wallow_a2 | 179.6 m vs 173.2 m (3.6 %) |
| F2 | cache_a_a1-x_bridge_n vs cache_a_a2-x_bridge_s | 141.1 m vs 146.4 m (3.6 %) |
| F2 | lairs_one_a1-x_lane_e vs lairs_one_a2-x_lane_e | 124.5 m vs 120.1 m (3.6 %) |
| F2 | lairs_one_a2-x_lane_e vs lairs_one_b2-x_lane_w | 120.1 m vs 124.5 m (3.6 %) |
| F2 | tower_r_a2-cache_a_b2 vs tower_r_b1-cache_a_a1 | 152.4 m vs 147.0 m (3.6 %) |
| F2 | third_node_a1-ford_nest_a2 vs third_node_b2-ford_nest_a2 | 126.8 m vs 131.5 m (3.6 %) |
| F2 | third_node_a1-x_ford_n vs third_node_b2-x_ford_n | 126.8 m vs 131.5 m (3.6 %) |
| F2 | keep_t1-guilds_lodge_b2 vs keep_t4-guilds_lodge_b1 | 106.6 m vs 110.5 m (3.6 %) |
| F2 | keep_t0-guilds_lodge_a2 vs keep_t1-guilds_lodge_b2 | 110.5 m vs 106.6 m (3.6 %) |
| F2 | keep_t3-guilds_lodge_a1 vs keep_t4-guilds_lodge_b1 | 106.6 m vs 110.5 m (3.6 %) |
| F2 | keep_t0-guilds_lodge_a2 vs keep_t3-guilds_lodge_a1 | 110.5 m vs 106.6 m (3.6 %) |
| F2 | shrine_a1-x_bridge_n vs shrine_b2-x_bridge_n | 94.8 m vs 91.5 m (3.5 %) |
| F2 | shrine_b1-lairs_two_b2 vs shrine_b2-lairs_two_b1 | 91.1 m vs 94.5 m (3.5 %) |
| F2 | shrine_a1-lairs_two_a2 vs shrine_b2-lairs_two_b1 | 91.1 m vs 94.5 m (3.5 %) |
| F2 | shrine_a2-lairs_two_a1 vs shrine_b2-lairs_two_b1 | 91.1 m vs 94.5 m (3.5 %) |
| F2 | guilds_lodge_b1-cache_b_a1 vs guilds_lodge_b2-cache_b_a2 | 152.4 m vs 158.0 m (3.5 %) |
| F2 | nat_node_a1-stag_a2 vs nat_node_a2-stag_a1 | 91.3 m vs 94.6 m (3.5 %) |
| F2 | nat_node_a2-stag_a1 vs nat_node_b2-stag_b1 | 94.6 m vs 91.3 m (3.5 %) |
| F2 | nat_node_a2-stag_a1 vs nat_node_b1-stag_b2 | 94.6 m vs 91.3 m (3.5 %) |
| F2 | home_b_a1-post_w_b2 vs home_b_b1-post_w_a2 | 153.4 m vs 148.0 m (3.5 %) |
| F2 | home_b_a1-post_w_b2 vs home_b_a2-post_w_b1 | 153.4 m vs 148.0 m (3.5 %) |
| F2 | home_b_a1-post_w_b2 vs home_b_b2-post_w_a1 | 153.4 m vs 148.0 m (3.5 %) |
| F2 | third_node_a2-cache_b_b2 vs third_node_b2-cache_b_a2 | 147.9 m vs 153.3 m (3.5 %) |
| F2 | third_node_a2-stag_b2 vs third_node_b1-stag_a1 | 191.0 m vs 184.3 m (3.5 %) |
| F2 | tower_r_a2-cache_a_b2 vs tower_r_b2-cache_a_a2 | 152.4 m vs 147.1 m (3.5 %) |
| F2 | well_a1-peddler_b2 vs well_b2-peddler_a1 | 111.3 m vs 107.5 m (3.5 %) |
| F2 | well_a1-post_w_a2 vs well_b1-post_w_b2 | 78.1 m vs 75.4 m (3.5 %) |
| F2 | well_a1-post_w_a2 vs well_a2-post_w_a1 | 78.1 m vs 75.4 m (3.5 %) |
| F2 | well_a1-peddler_b2 vs well_a2-peddler_b1 | 111.3 m vs 107.5 m (3.5 %) |
| F2 | stag_b1-post_w_b2 vs stag_b2-post_w_b1 | 98.5 m vs 102.0 m (3.5 %) |
| F2 | stag_a2-post_w_a1 vs stag_b2-post_w_b1 | 98.5 m vs 102.0 m (3.5 %) |
| F2 | well_a1-peddler_b2 vs well_b1-peddler_a2 | 111.3 m vs 107.5 m (3.5 %) |
| F2 | rich_node_a1-post_w_b2 vs rich_node_b2-post_w_a1 | 113.8 m vs 117.8 m (3.5 %) |
| F2 | keep_t1-third_node_b2 vs keep_t4-third_node_b1 | 96.0 m vs 99.5 m (3.5 %) |
| F2 | keep_t0-third_node_a2 vs keep_t1-third_node_b2 | 99.5 m vs 96.0 m (3.5 %) |
| F2 | keep_t3-third_node_a1 vs keep_t4-third_node_b1 | 96.0 m vs 99.5 m (3.5 %) |
| F2 | keep_t0-third_node_a2 vs keep_t3-third_node_a1 | 99.5 m vs 96.0 m (3.5 %) |
| F2 | home_a_a2-tower_c_a1 vs home_a_b2-tower_c_b1 | 59.1 m vs 61.2 m (3.4 %) |
| F2 | cache_a_b1-lairs_one_a1 vs cache_a_b2-lairs_one_a2 | 200.1 m vs 207.2 m (3.4 %) |
| F2 | tower_r_a1-cache_a_b1 vs tower_r_a2-cache_a_b2 | 147.2 m vs 152.4 m (3.4 %) |
| F2 | home_b_a1-peddler_b2 vs home_b_b1-peddler_a2 | 133.9 m vs 129.3 m (3.4 %) |
| F2 | home_b_a1-peddler_b2 vs home_b_a2-peddler_b1 | 133.9 m vs 129.3 m (3.4 %) |
| F2 | third_node_a2-inn_b2 vs third_node_b2-inn_a2 | 149.4 m vs 154.6 m (3.4 %) |
| F2 | third_node_b1-inn_a1 vs third_node_b2-inn_a2 | 149.4 m vs 154.6 m (3.4 %) |
| F2 | home_b_a1-peddler_b2 vs home_b_b2-peddler_a1 | 133.9 m vs 129.3 m (3.4 %) |
| F2 | keep_t0-third_node_b1 vs keep_t1-third_node_a1 | 190.0 m vs 183.5 m (3.4 %) |
| F2 | tower_c_a1-shrine_a1 vs tower_c_a2-shrine_a2 | 30.9 m vs 32.0 m (3.4 %) |
| F2 | tower_c_a2-shrine_a2 vs tower_c_b2-shrine_b2 | 32.0 m vs 30.9 m (3.4 %) |
| F2 | tower_c_a1-shrine_a1 vs tower_c_b1-shrine_b1 | 30.9 m vs 32.0 m (3.4 %) |
| F2 | tower_c_b1-shrine_b1 vs tower_c_b2-shrine_b2 | 32.0 m vs 30.9 m (3.4 %) |
| F2 | third_node_a1-guilds_den_b2 vs third_node_b1-guilds_den_a2 | 163.5 m vs 157.9 m (3.4 %) |
| F2 | third_node_b1-guilds_den_a2 vs third_node_b2-guilds_den_a1 | 157.9 m vs 163.5 m (3.4 %) |
| F2 | shrine_a2-wallow_b1 vs shrine_b1-wallow_a2 | 135.9 m vs 140.7 m (3.4 %) |
| F2 | third_node_a1-inn_b1 vs third_node_b2-inn_a2 | 149.4 m vs 154.6 m (3.4 %) |
| F2 | home_a_a1-cache_a_b1 vs home_a_b1-cache_a_a1 | 153.3 m vs 148.1 m (3.4 %) |
| F2 | home_a_a1-lairs_two_b1 vs home_a_b1-lairs_two_a1 | 167.4 m vs 161.8 m (3.4 %) |
| F2 | home_a_b1-cache_a_a1 vs home_a_b2-cache_a_a2 | 148.1 m vs 153.2 m (3.4 %) |
| F2 | home_a_a1-cache_a_b1 vs home_a_a2-cache_a_b2 | 153.3 m vs 148.1 m (3.4 %) |
| F2 | well_b1-post_w_b2 vs well_b2-post_w_b1 | 75.4 m vs 78.0 m (3.4 %) |
| F2 | well_a2-post_w_a1 vs well_b2-post_w_b1 | 75.4 m vs 78.0 m (3.4 %) |
| F2 | stag_b1-lairs_one_a1 vs stag_b2-lairs_one_a2 | 208.9 m vs 216.1 m (3.4 %) |
| F2 | shrine_a1-wallow_b2 vs shrine_a2-wallow_b1 | 140.6 m vs 135.9 m (3.3 %) |
| F2 | home_a_a1-lairs_two_b1 vs home_a_a2-lairs_two_b2 | 167.4 m vs 161.8 m (3.3 %) |
| F2 | home_a_a2-cache_a_b2 vs home_a_b2-cache_a_a2 | 148.1 m vs 153.2 m (3.3 %) |
| F2 | shrine_a2-wallow_b1 vs shrine_b2-wallow_a1 | 135.9 m vs 140.6 m (3.3 %) |
| F2 | lairs_one_a2-lairs_two_a1 vs lairs_one_b1-lairs_two_b2 | 175.1 m vs 169.3 m (3.3 %) |
| F2 | well_a1-post_w_b2 vs well_b2-post_w_a1 | 130.9 m vs 126.6 m (3.3 %) |
| F2 | well_a1-post_w_b2 vs well_b1-post_w_a2 | 130.9 m vs 126.6 m (3.3 %) |
| F2 | well_a1-post_w_b2 vs well_a2-post_w_b1 | 130.9 m vs 126.6 m (3.3 %) |
| F2 | wallow_a2-guilds_den_b2 vs wallow_b2-guilds_den_a2 | 207.5 m vs 214.6 m (3.3 %) |
| F2 | guilds_lodge_b1-x_ford_s vs guilds_lodge_b2-x_ford_n | 137.8 m vs 142.6 m (3.3 %) |
| F2 | guilds_lodge_a2-x_ford_s vs guilds_lodge_b2-x_ford_n | 137.8 m vs 142.6 m (3.3 %) |
| F2 | home_b_a2-rich_node_b2 vs home_b_b1-rich_node_a1 | 124.6 m vs 120.4 m (3.3 %) |
| F2 | wallow_a2-guilds_lodge_b2 vs wallow_b2-guilds_lodge_a2 | 209.2 m vs 216.4 m (3.3 %) |
| F2 | keep_t1-inn_a1 vs keep_t4-inn_a2 | 117.9 m vs 114.0 m (3.3 %) |
| F2 | keep_t3-inn_b2 vs keep_t4-inn_a2 | 117.9 m vs 114.0 m (3.3 %) |
| F2 | keep_t0-inn_b1 vs keep_t4-inn_a2 | 117.9 m vs 114.0 m (3.3 %) |
| F2 | guilds_den_a1-guilds_lodge_a2 vs guilds_den_a2-guilds_lodge_a1 | 161.1 m vs 155.8 m (3.3 %) |
| F2 | guilds_den_a2-guilds_lodge_a1 vs guilds_den_b2-guilds_lodge_b1 | 155.8 m vs 161.1 m (3.3 %) |
| F2 | guilds_den_b1-guilds_lodge_b2 vs guilds_den_b2-guilds_lodge_b1 | 155.8 m vs 161.1 m (3.3 %) |
| F2 | guilds_den_a1-guilds_lodge_a2 vs guilds_den_b1-guilds_lodge_b2 | 161.1 m vs 155.8 m (3.3 %) |
| F2 | keep_t1-third_node_a1 vs keep_t4-third_node_a2 | 183.5 m vs 189.8 m (3.3 %) |
| F2 | tower_r_a2-lairs_two_b2 vs tower_r_b1-lairs_two_a1 | 167.5 m vs 162.0 m (3.3 %) |
| F2 | keep_t0-post_s_b1 vs keep_t4-post_s_a2 | 144.3 m vs 149.3 m (3.3 %) |
| F2 | rich_node_a1-post_w_b2 vs rich_node_a2-post_w_b1 | 113.8 m vs 117.6 m (3.3 %) |
| F2 | guilds_lodge_a1-x_ford_n vs guilds_lodge_b2-x_ford_n | 137.9 m vs 142.6 m (3.3 %) |
| F2 | inn_a2-lairs_one_b1 vs inn_b2-lairs_one_a1 | 114.4 m vs 110.6 m (3.3 %) |
| F2 | keep_t0-nat_node_b1 vs keep_t4-nat_node_a2 | 119.0 m vs 115.1 m (3.3 %) |
| F2 | keep_t3-post_s_b2 vs keep_t4-post_s_a2 | 144.4 m vs 149.3 m (3.3 %) |
| F2 | wallow_a1-peddler_b1 vs wallow_b2-peddler_a2 | 167.8 m vs 162.3 m (3.3 %) |
| F2 | inn_a1-lairs_one_b2 vs inn_a2-lairs_one_b1 | 110.6 m vs 114.4 m (3.3 %) |
| F2 | inn_b1-lairs_one_a2 vs inn_b2-lairs_one_a1 | 114.3 m vs 110.6 m (3.3 %) |
| F2 | keep_t1-nat_node_a1 vs keep_t4-nat_node_a2 | 119.0 m vs 115.1 m (3.3 %) |
| F2 | keep_t3-nat_node_b2 vs keep_t4-nat_node_a2 | 119.0 m vs 115.1 m (3.3 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_a2-wallow_b2 | 150.8 m vs 155.9 m (3.3 %) |
| F2 | shrine_a2-wallow_b2 vs shrine_b2-wallow_a2 | 155.9 m vs 150.8 m (3.3 %) |
| F2 | tower_r_a2-well_a1 vs tower_r_b2-well_b1 | 120.7 m vs 116.7 m (3.3 %) |
| F2 | tower_r_a1-well_a2 vs tower_r_a2-well_a1 | 116.7 m vs 120.7 m (3.3 %) |
| F2 | tower_r_a2-well_a1 vs tower_r_b1-well_b2 | 120.7 m vs 116.7 m (3.3 %) |
| F2 | well_a1-inn_a2 vs well_a2-inn_a1 | 75.7 m vs 73.3 m (3.2 %) |
| F2 | well_a2-inn_a1 vs well_b2-inn_b1 | 73.3 m vs 75.7 m (3.2 %) |
| F2 | shrine_b1-wallow_a1 vs shrine_b2-wallow_a2 | 155.9 m vs 150.8 m (3.2 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_b1-wallow_a1 | 150.8 m vs 155.9 m (3.2 %) |
| F2 | post_w_a1-x_bridge_n vs post_w_b2-x_bridge_n | 111.8 m vs 115.6 m (3.2 %) |
| F2 | inn_a1-lairs_one_b2 vs inn_b1-lairs_one_a2 | 110.6 m vs 114.3 m (3.2 %) |
| F2 | keep_t0-home_a_b2 vs keep_t3-home_a_b1 | 144.2 m vs 139.5 m (3.2 %) |
| F2 | keep_t0-home_a_b2 vs keep_t1-home_a_a2 | 144.2 m vs 139.5 m (3.2 %) |
| F2 | tower_r_a2-lairs_two_b2 vs tower_r_b2-lairs_two_a2 | 167.5 m vs 162.1 m (3.2 %) |
| F2 | well_a2-inn_a1 vs well_b1-inn_b2 | 73.3 m vs 75.7 m (3.2 %) |
| F2 | home_b_a2-well_b2 vs home_b_b1-well_a1 | 144.5 m vs 139.8 m (3.2 %) |
| F2 | keep_t1-post_s_a1 vs keep_t4-post_s_a2 | 144.4 m vs 149.3 m (3.2 %) |
| F2 | keep_t0-home_a_b2 vs keep_t4-home_a_a1 | 144.2 m vs 139.6 m (3.2 %) |
| F2 | inn_a1-lairs_two_b2 vs inn_a2-lairs_two_b1 | 100.0 m vs 103.4 m (3.2 %) |
| F2 | inn_a1-lairs_two_b2 vs inn_b1-lairs_two_a2 | 100.0 m vs 103.4 m (3.2 %) |
| F2 | guilds_lodge_a2-lairs_two_a1 vs guilds_lodge_b2-lairs_two_b1 | 166.2 m vs 160.8 m (3.2 %) |
| F2 | guilds_lodge_b1-lairs_two_b2 vs guilds_lodge_b2-lairs_two_b1 | 166.2 m vs 160.8 m (3.2 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t1-lairs_one_a1 | 180.3 m vs 174.6 m (3.2 %) |
| F2 | lairs_two_a1-x_bridge_n vs lairs_two_a2-x_bridge_s | 156.4 m vs 161.6 m (3.2 %) |
| F2 | post_w_a1-x_bridge_n vs post_w_a2-x_bridge_s | 111.8 m vs 115.5 m (3.2 %) |
| F2 | post_w_b1-x_bridge_s vs post_w_b2-x_bridge_n | 111.9 m vs 115.6 m (3.2 %) |
| F2 | guilds_den_a1-cache_b_b1 vs guilds_den_b2-cache_b_a2 | 173.2 m vs 167.7 m (3.2 %) |
| F2 | tower_r_a1-lairs_two_b1 vs tower_r_a2-lairs_two_b2 | 162.2 m vs 167.5 m (3.2 %) |
| F2 | keep_t1-guilds_den_a1 vs keep_t4-guilds_den_a2 | 190.3 m vs 196.5 m (3.2 %) |
| F2 | inn_a1-lairs_two_b2 vs inn_b2-lairs_two_a1 | 100.0 m vs 103.3 m (3.2 %) |
| F2 | home_b_a1-wallow_a2 vs home_b_a2-wallow_a1 | 90.0 m vs 87.2 m (3.1 %) |
| F2 | home_b_a1-wallow_a2 vs home_b_b2-wallow_b1 | 90.0 m vs 87.2 m (3.1 %) |
| F2 | home_b_a1-wallow_a2 vs home_b_b1-wallow_b2 | 90.0 m vs 87.2 m (3.1 %) |
| F2 | keep_t1-guilds_lodge_a1 vs keep_t4-guilds_lodge_a2 | 192.0 m vs 198.3 m (3.1 %) |
| F2 | post_w_a2-x_bridge_s vs post_w_b1-x_bridge_s | 115.5 m vs 111.9 m (3.1 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_b1-wallow_a1 | 173.9 m vs 168.5 m (3.1 %) |
| F2 | home_a_b1-lairs_two_a1 vs home_a_b2-lairs_two_a2 | 161.8 m vs 167.0 m (3.1 %) |
| F2 | home_a_a2-wallow_b2 vs home_a_b2-wallow_a2 | 167.1 m vs 172.5 m (3.1 %) |
| F2 | shrine_a1-x_ford_n vs shrine_b1-x_ford_s | 74.5 m vs 72.2 m (3.1 %) |
| F2 | shrine_a1-ford_nest_a2 vs shrine_b1-ford_nest_a1 | 74.5 m vs 72.2 m (3.1 %) |
| F2 | shrine_a1-x_ford_n vs shrine_a2-x_ford_s | 74.5 m vs 72.2 m (3.1 %) |
| F2 | shrine_a1-ford_nest_a2 vs shrine_a2-ford_nest_a1 | 74.5 m vs 72.2 m (3.1 %) |
| F2 | home_a_a2-lairs_two_b2 vs home_a_b2-lairs_two_a2 | 161.8 m vs 167.0 m (3.1 %) |
| F2 | home_b_a2-tower_r_b2 vs home_b_b1-tower_r_a1 | 135.8 m vs 131.6 m (3.1 %) |
| F2 | shrine_a1-x_ford_n vs shrine_b2-x_ford_n | 74.5 m vs 72.2 m (3.1 %) |
| F2 | shrine_a1-ford_nest_a2 vs shrine_b2-ford_nest_a2 | 74.5 m vs 72.2 m (3.1 %) |
| F2 | home_b_a1-tower_r_b1 vs home_b_b1-tower_r_a1 | 135.8 m vs 131.6 m (3.1 %) |
| F2 | keep_t0-wallow_b1 vs keep_t3-wallow_b2 | 177.1 m vs 171.6 m (3.1 %) |
| F2 | keep_t0-wallow_b1 vs keep_t1-wallow_a1 | 177.1 m vs 171.6 m (3.1 %) |
| F2 | guilds_lodge_b1-lairs_one_a2 vs guilds_lodge_b2-lairs_one_a1 | 156.0 m vs 160.9 m (3.1 %) |
| F2 | keep_t3-ford_nest_a1 vs keep_t1-ford_nest_a1 | 98.3 m vs 95.3 m (3.1 %) |
| F2 | keep_t3-x_ford_s vs keep_t1-x_ford_s | 98.3 m vs 95.3 m (3.1 %) |
| F2 | nat_node_a2-lairs_one_b1 vs nat_node_b2-lairs_one_a1 | 122.0 m vs 118.2 m (3.1 %) |
| F2 | third_node_a1-stag_b1 vs third_node_b1-stag_a1 | 190.1 m vs 184.3 m (3.1 %) |
| F2 | third_node_a1-shrine_b1 vs third_node_b2-shrine_a2 | 164.4 m vs 169.5 m (3.1 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_a2-wallow_b2 | 179.6 m vs 174.1 m (3.0 %) |
| F2 | home_b_a1-wallow_b1 vs home_b_b1-wallow_a1 | 179.6 m vs 174.1 m (3.0 %) |
| F2 | nat_node_a1-lairs_one_b2 vs nat_node_a2-lairs_one_b1 | 118.2 m vs 122.0 m (3.0 %) |
| F2 | nat_node_b1-lairs_one_a2 vs nat_node_b2-lairs_one_a1 | 121.9 m vs 118.2 m (3.0 %) |
| F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b1-cache_b_a1 | 171.8 m vs 166.6 m (3.0 %) |
| F2 | wallow_a1-x_bridge_n vs wallow_b2-x_bridge_n | 136.3 m vs 140.5 m (3.0 %) |
| F2 | nat_node_a1-lairs_one_b2 vs nat_node_b1-lairs_one_a2 | 118.2 m vs 121.9 m (3.0 %) |
| F2 | home_b_a1-well_b1 vs home_b_a2-well_b2 | 149.0 m vs 144.5 m (3.0 %) |
| F2 | keep_t0-stag_b1 vs keep_t4-stag_a2 | 157.9 m vs 162.8 m (3.0 %) |
| F2 | home_b_a1-guilds_lodge_a2 vs home_b_a2-guilds_lodge_a1 | 116.9 m vs 113.4 m (3.0 %) |
| F2 | home_b_a2-guilds_lodge_a1 vs home_b_b2-guilds_lodge_b1 | 113.4 m vs 116.9 m (3.0 %) |
| F2 | home_b_b1-guilds_lodge_b2 vs home_b_b2-guilds_lodge_b1 | 113.4 m vs 116.9 m (3.0 %) |
| F2 | home_b_a1-guilds_lodge_a2 vs home_b_b1-guilds_lodge_b2 | 116.9 m vs 113.4 m (3.0 %) |
| F2 | keep_t3-stag_b2 vs keep_t4-stag_a2 | 157.9 m vs 162.8 m (3.0 %) |
| F2 | well_a2-wallow_b1 vs well_b1-wallow_a2 | 120.7 m vs 124.5 m (3.0 %) |
| F2 | wallow_a2-post_w_b2 vs wallow_b2-post_w_a2 | 180.5 m vs 175.1 m (3.0 %) |
| F2 | wallow_b1-post_w_a1 vs wallow_b2-post_w_a2 | 180.5 m vs 175.1 m (3.0 %) |
| F2 | third_node_a1-third_node_b1 vs third_node_b2-third_node_a2 | 221.5 m vs 214.9 m (3.0 %) |
| F2 | home_a_a2-stag_b1 vs home_a_b1-stag_a2 | 125.9 m vs 122.2 m (3.0 %) |
| F2 | keep_t0-shrine_b1 vs keep_t4-shrine_a2 | 132.8 m vs 128.9 m (3.0 %) |
| F2 | cache_a_a1-x_lane_e vs cache_a_b2-x_lane_w | 96.1 m vs 93.2 m (3.0 %) |
| F2 | home_b_a2-well_a1 vs home_b_b2-well_b1 | 91.6 m vs 94.4 m (3.0 %) |
| F2 | home_b_a1-well_a2 vs home_b_a2-well_a1 | 94.4 m vs 91.6 m (3.0 %) |
| F2 | home_b_b1-well_b2 vs home_b_b2-well_b1 | 91.6 m vs 94.4 m (3.0 %) |
| F2 | home_b_a1-well_a2 vs home_b_b1-well_b2 | 94.4 m vs 91.6 m (3.0 %) |
| F2 | keep_t3-shrine_b2 vs keep_t4-shrine_a2 | 132.8 m vs 128.9 m (3.0 %) |
| F2 | keep_t1-shrine_a1 vs keep_t4-shrine_a2 | 132.8 m vs 128.9 m (3.0 %) |
| F2 | nat_node_a1-lairs_two_b2 vs nat_node_a2-lairs_two_b1 | 107.6 m vs 110.9 m (2.9 %) |
| F2 | wallow_a2-x_ford_s vs wallow_b1-x_ford_s | 117.3 m vs 113.8 m (2.9 %) |
| F2 | wallow_a2-ford_nest_a1 vs wallow_b1-ford_nest_a1 | 117.3 m vs 113.8 m (2.9 %) |
| F2 | cache_a_a1-x_lane_e vs cache_a_b1-x_lane_w | 96.1 m vs 93.3 m (2.9 %) |
| F2 | shrine_b1-post_w_a2 vs shrine_b2-post_w_a1 | 135.5 m vs 139.6 m (2.9 %) |
| F2 | wallow_a1-ford_nest_a2 vs wallow_a2-ford_nest_a1 | 113.8 m vs 117.3 m (2.9 %) |
| F2 | wallow_a1-x_ford_n vs wallow_a2-x_ford_s | 113.8 m vs 117.3 m (2.9 %) |
| F2 | nat_node_a1-lairs_two_b2 vs nat_node_b1-lairs_two_a2 | 107.6 m vs 110.9 m (2.9 %) |
| F2 | wallow_b1-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 113.8 m vs 117.3 m (2.9 %) |
| F2 | wallow_b1-x_ford_s vs wallow_b2-x_ford_n | 113.8 m vs 117.3 m (2.9 %) |
| F2 | wallow_a1-x_ford_n vs wallow_b2-x_ford_n | 113.8 m vs 117.3 m (2.9 %) |
| F2 | wallow_a1-ford_nest_a2 vs wallow_b2-ford_nest_a2 | 113.8 m vs 117.3 m (2.9 %) |
| F2 | home_b_b1-peddler_a1 vs home_b_b2-peddler_a2 | 149.7 m vs 145.3 m (2.9 %) |
| F2 | home_b_a2-peddler_b2 vs home_b_b2-peddler_a2 | 149.7 m vs 145.3 m (2.9 %) |
| F2 | tower_c_a2-lairs_one_b1 vs tower_c_b2-lairs_one_a1 | 125.9 m vs 122.2 m (2.9 %) |
| F2 | shrine_a1-post_w_b2 vs shrine_b2-post_w_a1 | 135.5 m vs 139.6 m (2.9 %) |
| F2 | cache_a_a2-x_lane_e vs cache_a_b2-x_lane_w | 96.0 m vs 93.2 m (2.9 %) |
| F2 | well_a1-wallow_b2 vs well_a2-wallow_b1 | 124.3 m vs 120.7 m (2.9 %) |
| F2 | home_b_a2-third_node_a1 vs home_b_b2-third_node_b1 | 102.7 m vs 105.8 m (2.9 %) |
| F2 | home_b_a1-third_node_a2 vs home_b_a2-third_node_a1 | 105.8 m vs 102.7 m (2.9 %) |
| F2 | home_b_b1-third_node_b2 vs home_b_b2-third_node_b1 | 102.7 m vs 105.8 m (2.9 %) |
| F2 | home_b_a1-third_node_a2 vs home_b_b1-third_node_b2 | 105.8 m vs 102.7 m (2.9 %) |
| F2 | tower_c_a1-lairs_one_b2 vs tower_c_a2-lairs_one_b1 | 122.2 m vs 125.9 m (2.9 %) |
| F2 | tower_c_b1-lairs_one_a2 vs tower_c_b2-lairs_one_a1 | 125.9 m vs 122.2 m (2.9 %) |
| F2 | third_node_a2-well_b2 vs third_node_b2-well_a2 | 177.9 m vs 183.2 m (2.9 %) |
| F2 | tower_c_a1-lairs_one_b2 vs tower_c_b1-lairs_one_a2 | 122.2 m vs 125.9 m (2.9 %) |
| F2 | peddler_a1-peddler_b1 vs peddler_b2-peddler_a2 | 140.0 m vs 135.9 m (2.9 %) |
| F2 | shrine_a1-post_s_b1 vs shrine_a2-post_s_b2 | 121.7 m vs 118.2 m (2.9 %) |
| F2 | wallow_a1-post_w_b2 vs wallow_b1-post_w_a2 | 168.3 m vs 163.5 m (2.9 %) |
| F2 | well_a2-wallow_b1 vs well_b2-wallow_a1 | 120.7 m vs 124.3 m (2.9 %) |
| F2 | wallow_a1-post_w_b2 vs wallow_a2-post_w_b1 | 168.3 m vs 163.5 m (2.9 %) |
| F2 | cache_a_a2-x_lane_e vs cache_a_b1-x_lane_w | 96.0 m vs 93.3 m (2.9 %) |
| F2 | wallow_a1-post_w_b2 vs wallow_b2-post_w_a1 | 168.3 m vs 163.5 m (2.9 %) |
| F2 | peddler_a2-crown vs peddler_b1-crown | 67.8 m vs 69.8 m (2.9 %) |
| F2 | nat_node_a1-lairs_two_b2 vs nat_node_b2-lairs_two_a1 | 107.6 m vs 110.8 m (2.9 %) |
| F2 | shrine_a2-post_w_b1 vs shrine_b1-post_w_a2 | 139.5 m vs 135.5 m (2.9 %) |
| F2 | home_a_a1-stag_b2 vs home_a_b1-stag_a2 | 125.8 m vs 122.2 m (2.9 %) |
| F2 | peddler_b1-crown vs peddler_b2-crown | 69.8 m vs 67.8 m (2.9 %) |
| F2 | home_a_a2-tower_r_a1 vs home_a_b2-tower_r_b1 | 103.4 m vs 106.4 m (2.9 %) |
| F2 | home_a_b1-tower_r_b2 vs home_a_b2-tower_r_b1 | 103.4 m vs 106.4 m (2.9 %) |
| F2 | peddler_a1-crown vs peddler_b1-crown | 67.8 m vs 69.8 m (2.9 %) |
| F2 | nat_node_a2-cache_a_a1 vs nat_node_b1-cache_a_b2 | 85.7 m vs 83.3 m (2.9 %) |
| F2 | third_node_a1-well_b1 vs third_node_b2-well_a2 | 178.0 m vs 183.2 m (2.9 %) |
| F2 | home_a_a1-third_node_b1 vs home_a_b1-third_node_a1 | 181.8 m vs 176.6 m (2.9 %) |
| F2 | wallow_a2-x_bridge_s vs wallow_b2-x_bridge_n | 136.5 m vs 140.5 m (2.9 %) |
| F2 | wallow_a1-post_w_b1 vs wallow_b2-post_w_a2 | 180.2 m vs 175.1 m (2.9 %) |
| F2 | inn_a1-guilds_lodge_b1 vs inn_a2-guilds_lodge_b2 | 160.4 m vs 165.1 m (2.8 %) |
| F2 | home_a_b1-third_node_a1 vs home_a_b2-third_node_a2 | 176.6 m vs 181.8 m (2.8 %) |
| F2 | home_a_a1-third_node_b1 vs home_a_a2-third_node_b2 | 181.8 m vs 176.6 m (2.8 %) |
| F2 | keep_t0-x_bridge_n vs keep_t1-x_bridge_s | 117.4 m vs 120.9 m (2.8 %) |
| F2 | shrine_a1-cache_b_b1 vs shrine_b2-cache_b_a2 | 84.3 m vs 81.9 m (2.8 %) |
| F2 | inn_a1-guilds_lodge_b1 vs inn_b1-guilds_lodge_a1 | 160.4 m vs 165.1 m (2.8 %) |
| F2 | shrine_a1-post_w_b2 vs shrine_a2-post_w_b1 | 135.5 m vs 139.5 m (2.8 %) |
| F2 | home_a_a2-third_node_b2 vs home_a_b2-third_node_a2 | 176.6 m vs 181.8 m (2.8 %) |
| F2 | shrine_a1-post_s_b1 vs shrine_b2-post_s_a2 | 121.7 m vs 118.3 m (2.8 %) |
| F2 | guilds_lodge_a1-x_bridge_s vs guilds_lodge_b1-x_bridge_n | 83.6 m vs 86.0 m (2.8 %) |
| F2 | guilds_lodge_a1-x_bridge_s vs guilds_lodge_a2-x_bridge_n | 83.6 m vs 86.0 m (2.8 %) |
| F2 | guilds_lodge_a2-x_bridge_n vs guilds_lodge_b2-x_bridge_s | 86.0 m vs 83.6 m (2.8 %) |
| F2 | guilds_lodge_b1-x_bridge_n vs guilds_lodge_b2-x_bridge_s | 86.0 m vs 83.6 m (2.8 %) |
| F2 | tower_c_a1-peddler_b2 vs tower_c_b1-peddler_a2 | 90.2 m vs 92.8 m (2.8 %) |
| F2 | tower_c_b1-peddler_a2 vs tower_c_b2-peddler_a1 | 92.8 m vs 90.2 m (2.8 %) |
| F2 | wallow_a1-wallow_b1 vs wallow_b2-wallow_a2 | 195.6 m vs 190.1 m (2.8 %) |
| F2 | inn_a1-guilds_lodge_b1 vs inn_b2-guilds_lodge_a2 | 160.4 m vs 165.0 m (2.8 %) |
| F2 | wallow_b1-cache_a_a1 vs wallow_b2-cache_a_a2 | 174.4 m vs 179.4 m (2.8 %) |
| F2 | guilds_den_b1-peddler_b2 vs guilds_den_b2-peddler_b1 | 108.2 m vs 105.1 m (2.8 %) |
| F2 | guilds_den_a1-peddler_a2 vs guilds_den_b1-peddler_b2 | 105.1 m vs 108.2 m (2.8 %) |
| F2 | third_node_a1-peddler_b1 vs third_node_b2-peddler_a2 | 180.8 m vs 186.0 m (2.8 %) |
| F2 | lairs_one_a1-x_lane_w vs lairs_one_b1-x_lane_e | 99.4 m vs 96.6 m (2.8 %) |
| F2 | lairs_one_a1-x_lane_w vs lairs_one_a2-x_lane_w | 99.4 m vs 96.6 m (2.8 %) |
| F2 | lairs_one_a2-x_lane_w vs lairs_one_b2-x_lane_e | 96.6 m vs 99.4 m (2.8 %) |
| F2 | lairs_one_b1-x_lane_e vs lairs_one_b2-x_lane_e | 96.6 m vs 99.4 m (2.8 %) |
| F2 | home_a_b1-stag_a2 vs home_a_b2-stag_a1 | 122.2 m vs 125.7 m (2.8 %) |
| F2 | nat_node_a1-cache_a_a2 vs nat_node_a2-cache_a_a1 | 83.3 m vs 85.7 m (2.8 %) |
| F2 | nat_node_a2-cache_a_a1 vs nat_node_b2-cache_a_b1 | 85.7 m vs 83.3 m (2.8 %) |
| F2 | third_node_a1-post_w_b1 vs third_node_b2-post_w_a2 | 193.2 m vs 198.7 m (2.8 %) |
| F2 | post_w_b1-lairs_one_a1 vs post_w_b2-lairs_one_a2 | 173.6 m vs 178.5 m (2.7 %) |
| F2 | keep_t3-x_bridge_s vs keep_t1-x_bridge_s | 117.6 m vs 120.9 m (2.7 %) |
| F2 | home_a_a1-guilds_den_b1 vs home_a_b1-guilds_den_a1 | 188.5 m vs 183.4 m (2.7 %) |
| F2 | wallow_a1-peddler_b2 vs wallow_a2-peddler_b1 | 148.8 m vs 144.7 m (2.7 %) |
| F2 | wallow_a1-peddler_b2 vs wallow_b2-peddler_a1 | 148.8 m vs 144.7 m (2.7 %) |
| F2 | wallow_a1-peddler_b2 vs wallow_b1-peddler_a2 | 148.8 m vs 144.7 m (2.7 %) |
| F2 | home_a_a1-guilds_lodge_b1 vs home_a_b1-guilds_lodge_a1 | 190.3 m vs 185.1 m (2.7 %) |
| F2 | home_a_b1-guilds_den_a1 vs home_a_b2-guilds_den_a2 | 183.4 m vs 188.5 m (2.7 %) |
| F2 | home_a_a1-guilds_den_b1 vs home_a_a2-guilds_den_b2 | 188.5 m vs 183.4 m (2.7 %) |
| F2 | home_a_b1-guilds_lodge_a1 vs home_a_b2-guilds_lodge_a2 | 185.1 m vs 190.3 m (2.7 %) |
| F2 | home_a_a1-guilds_lodge_b1 vs home_a_a2-guilds_lodge_b2 | 190.3 m vs 185.2 m (2.7 %) |
| F2 | home_a_a2-guilds_den_b2 vs home_a_b2-guilds_den_a2 | 183.4 m vs 188.5 m (2.7 %) |
| F2 | home_a_a2-guilds_lodge_b2 vs home_a_b2-guilds_lodge_a2 | 185.2 m vs 190.3 m (2.7 %) |
| F2 | shrine_a2-lairs_one_b1 vs shrine_b2-lairs_one_a1 | 139.8 m vs 136.1 m (2.7 %) |
| F2 | cache_b_a2-lairs_one_a2 vs cache_b_b2-lairs_one_b2 | 81.0 m vs 78.9 m (2.7 %) |
| F2 | cache_b_b1-lairs_one_b1 vs cache_b_b2-lairs_one_b2 | 81.0 m vs 78.9 m (2.7 %) |
| F2 | cache_b_a1-lairs_one_a1 vs cache_b_b1-lairs_one_b1 | 78.9 m vs 81.0 m (2.7 %) |
| F2 | cache_b_a1-lairs_one_a1 vs cache_b_a2-lairs_one_a2 | 78.9 m vs 81.0 m (2.7 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t1-tower_r_a1 | 132.6 m vs 129.1 m (2.7 %) |
| F2 | shrine_a1-lairs_one_b2 vs shrine_a2-lairs_one_b1 | 136.1 m vs 139.8 m (2.7 %) |
| F2 | shrine_b1-lairs_one_a2 vs shrine_b2-lairs_one_a1 | 139.8 m vs 136.1 m (2.7 %) |
| F2 | keep_t0-well_b1 vs keep_t4-well_a2 | 146.5 m vs 142.6 m (2.7 %) |
| F2 | third_node_b1-well_a2 vs third_node_b2-well_a1 | 124.0 m vs 120.7 m (2.7 %) |
| F2 | third_node_a2-well_b1 vs third_node_b2-well_a1 | 124.0 m vs 120.7 m (2.7 %) |
| F2 | third_node_a1-wallow_b1 vs third_node_a2-wallow_b2 | 208.6 m vs 203.1 m (2.7 %) |
| F2 | third_node_a1-wallow_b1 vs third_node_b1-wallow_a1 | 208.6 m vs 203.1 m (2.7 %) |
| F2 | post_w_b1-post_s_a1 vs post_w_b2-post_s_a2 | 138.6 m vs 142.4 m (2.7 %) |
| F2 | shrine_a1-lairs_one_b2 vs shrine_b1-lairs_one_a2 | 136.1 m vs 139.8 m (2.6 %) |
| F2 | third_node_a1-well_b2 vs third_node_b1-well_a2 | 120.7 m vs 124.0 m (2.6 %) |
| F2 | third_node_a1-well_b2 vs third_node_a2-well_b1 | 120.7 m vs 124.0 m (2.6 %) |
| F2 | tower_c_a2-wallow_b2 vs tower_c_b1-wallow_a1 | 115.0 m vs 118.1 m (2.6 %) |
| F2 | keep_t0-peddler_b1 vs keep_t4-peddler_a2 | 149.3 m vs 145.3 m (2.6 %) |
| F2 | well_a1-x_bridge_n vs well_a2-x_bridge_s | 127.6 m vs 131.0 m (2.6 %) |
| F2 | shrine_a1-cache_b_b1 vs shrine_b1-cache_b_a1 | 84.3 m vs 82.1 m (2.6 %) |
| F2 | wallow_b1-post_s_a1 vs wallow_b2-post_s_a2 | 163.0 m vs 167.4 m (2.6 %) |
| F2 | home_b_a2-lairs_one_b1 vs home_b_b2-lairs_one_a1 | 146.1 m vs 142.3 m (2.6 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_b2-lairs_two_a2 | 160.4 m vs 164.7 m (2.6 %) |
| F2 | shrine_a1-stag_b1 vs shrine_a2-stag_b2 | 135.3 m vs 131.8 m (2.6 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t4-lairs_two_a2 | 170.4 m vs 175.0 m (2.6 %) |
| F2 | post_w_a2-post_s_b2 vs post_w_b1-post_s_a1 | 142.3 m vs 138.6 m (2.6 %) |
| F2 | tower_c_a1-lairs_one_b1 vs tower_c_b1-lairs_one_a1 | 140.9 m vs 137.3 m (2.6 %) |
| F2 | home_b_a1-lairs_one_b2 vs home_b_a2-lairs_one_b1 | 142.3 m vs 146.1 m (2.6 %) |
| F2 | home_b_b1-lairs_one_a2 vs home_b_b2-lairs_one_a1 | 146.1 m vs 142.3 m (2.6 %) |
| F2 | post_w_a1-post_s_b1 vs post_w_b2-post_s_a2 | 138.7 m vs 142.4 m (2.6 %) |
| F2 | third_node_a2-guilds_den_b1 vs third_node_b1-guilds_den_a2 | 162.1 m vs 157.9 m (2.6 %) |
| F2 | tower_c_a1-lairs_one_b1 vs tower_c_a2-lairs_one_b2 | 140.9 m vs 137.3 m (2.6 %) |
| F2 | tower_c_b1-lairs_one_a1 vs tower_c_b2-lairs_one_a2 | 137.3 m vs 140.9 m (2.6 %) |
| F2 | tower_c_a2-lairs_one_b2 vs tower_c_b2-lairs_one_a2 | 137.3 m vs 140.9 m (2.6 %) |
| F2 | home_b_a1-lairs_one_b2 vs home_b_b1-lairs_one_a2 | 142.3 m vs 146.1 m (2.6 %) |
| F2 | peddler_a2-lairs_one_b1 vs peddler_b2-lairs_one_a1 | 147.8 m vs 144.0 m (2.6 %) |
| F2 | third_node_a1-cache_a_a1 vs third_node_b1-cache_a_b1 | 33.9 m vs 33.0 m (2.6 %) |
| F2 | third_node_b1-cache_a_b1 vs third_node_b2-cache_a_b2 | 33.0 m vs 33.9 m (2.6 %) |
| F2 | lairs_one_a1-crown vs lairs_one_b1-crown | 110.0 m vs 107.2 m (2.6 %) |
| F2 | lairs_one_a1-crown vs lairs_one_a2-crown | 110.0 m vs 107.2 m (2.6 %) |
| F2 | lairs_one_b1-crown vs lairs_one_b2-crown | 107.2 m vs 110.0 m (2.6 %) |
| F2 | lairs_one_a2-crown vs lairs_one_b2-crown | 107.2 m vs 110.0 m (2.6 %) |
| F2 | home_b_a2-wallow_b1 vs home_b_b1-wallow_a2 | 143.2 m vs 146.9 m (2.6 %) |
| F2 | keep_t3-lairs_one_b1 vs keep_t4-lairs_one_a1 | 150.0 m vs 146.2 m (2.5 %) |
| F2 | peddler_a1-lairs_one_b2 vs peddler_a2-lairs_one_b1 | 144.0 m vs 147.8 m (2.5 %) |
| F2 | peddler_b1-lairs_one_a2 vs peddler_b2-lairs_one_a1 | 147.7 m vs 144.0 m (2.5 %) |
| F2 | shrine_a1-cache_b_b1 vs shrine_a2-cache_b_b2 | 84.3 m vs 82.1 m (2.5 %) |
| F2 | keep_t0-home_a_b1 vs keep_t4-home_a_a2 | 155.4 m vs 151.4 m (2.5 %) |
| F2 | post_w_a1-post_s_b1 vs post_w_a2-post_s_b2 | 138.7 m vs 142.3 m (2.5 %) |
| F2 | shrine_a1-stag_b1 vs shrine_b2-stag_a2 | 135.3 m vs 131.9 m (2.5 %) |
| F2 | keep_t0-home_b_b1 vs keep_t4-home_b_a2 | 154.7 m vs 150.8 m (2.5 %) |
| F2 | keep_t1-lairs_one_a2 vs keep_t4-lairs_one_a1 | 150.0 m vs 146.2 m (2.5 %) |
| F2 | third_node_a1-tower_c_a2 vs third_node_a2-tower_c_a1 | 93.3 m vs 90.9 m (2.5 %) |
| F2 | third_node_a1-tower_c_a2 vs third_node_b1-tower_c_b2 | 93.3 m vs 90.9 m (2.5 %) |
| F2 | third_node_b1-tower_c_b2 vs third_node_b2-tower_c_b1 | 90.9 m vs 93.3 m (2.5 %) |
| F2 | third_node_a2-tower_c_a1 vs third_node_b2-tower_c_b1 | 90.9 m vs 93.3 m (2.5 %) |
| F2 | keep_t0-lairs_one_b2 vs keep_t3-lairs_one_b1 | 146.3 m vs 150.0 m (2.5 %) |
| F2 | peddler_a1-x_lane_e vs peddler_a2-x_lane_e | 82.8 m vs 80.7 m (2.5 %) |
| F2 | peddler_a1-lairs_one_b2 vs peddler_b1-lairs_one_a2 | 144.0 m vs 147.7 m (2.5 %) |
| F2 | home_b_a1-x_ford_n vs home_b_b1-x_ford_s | 100.3 m vs 97.8 m (2.5 %) |
| F2 | home_b_a1-ford_nest_a2 vs home_b_b1-ford_nest_a1 | 100.3 m vs 97.8 m (2.5 %) |
| F2 | wallow_a1-post_s_b1 vs wallow_b2-post_s_a2 | 163.2 m vs 167.4 m (2.5 %) |
| F2 | keep_t1-home_b_a1 vs keep_t4-home_b_a2 | 154.6 m vs 150.8 m (2.5 %) |
| F2 | keep_t3-home_b_b2 vs keep_t4-home_b_a2 | 154.6 m vs 150.8 m (2.5 %) |
| F2 | peddler_a2-x_ford_s vs peddler_b1-x_ford_s | 88.1 m vs 85.9 m (2.5 %) |
| F2 | peddler_a1-x_lane_e vs peddler_b2-x_lane_w | 82.8 m vs 80.7 m (2.5 %) |
| F2 | peddler_a2-lairs_one_a1 vs peddler_b2-lairs_one_b1 | 104.9 m vs 102.3 m (2.5 %) |
| F2 | peddler_a1-lairs_one_a2 vs peddler_a2-lairs_one_a1 | 102.3 m vs 104.9 m (2.5 %) |
| F2 | peddler_b1-lairs_one_b2 vs peddler_b2-lairs_one_b1 | 104.9 m vs 102.3 m (2.5 %) |
| F2 | peddler_a1-lairs_one_a2 vs peddler_b1-lairs_one_b2 | 102.3 m vs 104.9 m (2.5 %) |
| F2 | keep_t0-lairs_one_b2 vs keep_t1-lairs_one_a2 | 146.3 m vs 150.0 m (2.5 %) |
| F2 | keep_t0-keep_t1 vs keep_t4-keep_t3 | 158.6 m vs 154.6 m (2.5 %) |
| F2 | keep_t3-wallow_b1 vs keep_t1-wallow_a2 | 147.1 m vs 150.9 m (2.5 %) |
| F2 | home_b_a1-wallow_b2 vs home_b_a2-wallow_b1 | 146.8 m vs 143.2 m (2.5 %) |
| F2 | home_a_a2-lairs_one_b1 vs home_a_b2-lairs_one_a1 | 154.5 m vs 150.7 m (2.5 %) |
| F2 | home_a_a2-wallow_b1 vs home_a_b1-wallow_a2 | 151.5 m vs 155.4 m (2.5 %) |
| F2 | home_b_a2-rich_node_b1 vs home_b_b2-rich_node_a1 | 87.7 m vs 85.6 m (2.5 %) |
| F2 | home_b_a2-wallow_b1 vs home_b_b2-wallow_a1 | 143.2 m vs 146.8 m (2.5 %) |
| F2 | peddler_a2-x_lane_e vs peddler_b1-x_lane_w | 80.7 m vs 82.7 m (2.5 %) |
| F2 | well_a2-x_bridge_s vs well_b1-x_bridge_s | 131.0 m vs 127.8 m (2.5 %) |
| F2 | home_b_a2-lairs_two_b2 vs home_b_b1-lairs_two_a1 | 170.6 m vs 166.5 m (2.4 %) |
| F2 | keep_t3-well_b2 vs keep_t1-well_a1 | 140.8 m vs 137.3 m (2.4 %) |
| F2 | home_a_a1-lairs_one_b2 vs home_a_a2-lairs_one_b1 | 150.8 m vs 154.5 m (2.4 %) |
| F2 | home_a_b1-lairs_one_a2 vs home_a_b2-lairs_one_a1 | 154.5 m vs 150.7 m (2.4 %) |
| F2 | peddler_b1-x_lane_w vs peddler_b2-x_lane_w | 82.7 m vs 80.7 m (2.4 %) |
| F2 | stag_b1-inn_b2 vs stag_b2-inn_b1 | 99.8 m vs 102.3 m (2.4 %) |
| F2 | tower_c_a2-peddler_b2 vs tower_c_b1-peddler_a1 | 90.6 m vs 92.8 m (2.4 %) |
| F2 | keep_t0-wallow_b2 vs keep_t3-wallow_b1 | 150.8 m vs 147.1 m (2.4 %) |
| F2 | third_node_a1-wallow_b1 vs third_node_b2-wallow_a2 | 208.6 m vs 213.8 m (2.4 %) |
| F2 | stag_a1-inn_a2 vs stag_b2-inn_b1 | 99.9 m vs 102.3 m (2.4 %) |
| F2 | keep_t3-post_w_b2 vs keep_t4-post_w_a2 | 162.0 m vs 158.1 m (2.4 %) |
| F2 | keep_t1-post_w_a1 vs keep_t4-post_w_a2 | 162.0 m vs 158.1 m (2.4 %) |
| F2 | peddler_b1-x_lane_e vs peddler_b2-x_lane_e | 57.3 m vs 55.9 m (2.4 %) |
| F2 | peddler_a1-x_lane_w vs peddler_b1-x_lane_e | 55.9 m vs 57.3 m (2.4 %) |
| F2 | home_a_a1-wallow_b2 vs home_a_a2-wallow_b1 | 155.3 m vs 151.5 m (2.4 %) |
| F2 | peddler_a2-x_lane_w vs peddler_b1-x_lane_e | 55.9 m vs 57.3 m (2.4 %) |
| F2 | shrine_b1-lairs_one_a1 vs shrine_b2-lairs_one_a2 | 151.3 m vs 155.1 m (2.4 %) |
| F2 | wallow_a2-post_s_b2 vs wallow_b2-post_s_a2 | 163.3 m vs 167.4 m (2.4 %) |
| F2 | home_a_a1-lairs_one_b2 vs home_a_b1-lairs_one_a2 | 150.8 m vs 154.5 m (2.4 %) |
| F2 | nat_node_a1-lairs_one_b1 vs nat_node_b1-lairs_one_a1 | 152.1 m vs 148.5 m (2.4 %) |
| F2 | keep_t3-rich_node_b2 vs keep_t1-rich_node_a1 | 120.8 m vs 117.9 m (2.4 %) |
| F2 | shrine_a2-lairs_one_b2 vs shrine_b2-lairs_one_a2 | 151.4 m vs 155.1 m (2.4 %) |
| F2 | keep_t3-wallow_b1 vs keep_t4-wallow_a1 | 147.1 m vs 150.7 m (2.4 %) |
| F2 | nat_node_a1-lairs_one_b1 vs nat_node_a2-lairs_one_b2 | 152.1 m vs 148.5 m (2.4 %) |
| F2 | nat_node_b1-lairs_one_a1 vs nat_node_b2-lairs_one_a2 | 148.5 m vs 152.1 m (2.4 %) |
| F2 | lairs_one_a1-lairs_one_b1 vs lairs_one_b2-lairs_one_a2 | 233.2 m vs 227.6 m (2.4 %) |
| F2 | home_a_a2-wallow_b1 vs home_a_b2-wallow_a1 | 151.5 m vs 155.2 m (2.4 %) |
| F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b2-cache_b_a2 | 171.8 m vs 167.7 m (2.4 %) |
| F2 | nat_node_a2-lairs_one_b2 vs nat_node_b2-lairs_one_a2 | 148.5 m vs 152.1 m (2.4 %) |
| F2 | stag_a2-inn_a1 vs stag_b1-inn_b2 | 102.3 m vs 99.8 m (2.4 %) |
| F2 | cache_b_a1-lairs_one_a2 vs cache_b_a2-lairs_one_a1 | 123.9 m vs 121.0 m (2.4 %) |
| F2 | home_b_a1-rich_node_b2 vs home_b_a2-rich_node_b1 | 85.6 m vs 87.7 m (2.4 %) |
| F2 | stag_a1-inn_a2 vs stag_a2-inn_a1 | 99.9 m vs 102.3 m (2.4 %) |
| F2 | stag_a1-post_w_a2 vs stag_a2-post_w_a1 | 100.9 m vs 98.5 m (2.4 %) |
| F2 | stag_a1-post_w_a2 vs stag_b1-post_w_b2 | 100.9 m vs 98.5 m (2.4 %) |
| F2 | shrine_a1-stag_a1 vs shrine_b2-stag_b2 | 81.4 m vs 79.5 m (2.4 %) |
| F2 | lairs_one_b1-x_ford_n vs lairs_one_b2-x_ford_s | 78.9 m vs 80.8 m (2.4 %) |
| F2 | home_a_b1-wallow_a1 vs home_a_b2-wallow_a2 | 168.5 m vs 172.5 m (2.4 %) |
| F2 | inn_a1-lairs_one_b1 vs inn_b1-lairs_one_a1 | 156.0 m vs 152.3 m (2.3 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_b1-lairs_two_a1 | 160.4 m vs 156.7 m (2.3 %) |
| F2 | inn_a1-lairs_one_b1 vs inn_a2-lairs_one_b2 | 156.0 m vs 152.3 m (2.3 %) |
| F2 | inn_b1-lairs_one_a1 vs inn_b2-lairs_one_a2 | 152.3 m vs 156.0 m (2.3 %) |
| F2 | peddler_a1-lairs_two_b1 vs peddler_a2-lairs_two_b2 | 160.4 m vs 156.7 m (2.3 %) |
| F2 | tower_c_b1-x_bridge_s vs tower_c_b2-x_bridge_n | 80.3 m vs 78.5 m (2.3 %) |
| F2 | inn_a2-lairs_one_b2 vs inn_b2-lairs_one_a2 | 152.3 m vs 156.0 m (2.3 %) |
| F2 | wallow_a1-stag_b1 vs wallow_b2-stag_a2 | 176.7 m vs 180.9 m (2.3 %) |
| F2 | wallow_b1-guilds_den_a1 vs wallow_b2-guilds_den_a2 | 209.6 m vs 214.6 m (2.3 %) |
| F2 | wallow_b1-guilds_lodge_a1 vs wallow_b2-guilds_lodge_a2 | 211.4 m vs 216.4 m (2.3 %) |
| F2 | home_a_a1-peddler_b1 vs home_a_a2-peddler_b2 | 146.1 m vs 142.7 m (2.3 %) |
| F2 | third_node_a2-cache_a_a1 vs third_node_b2-cache_a_b1 | 137.4 m vs 134.3 m (2.3 %) |
| F2 | third_node_a1-cache_a_a2 vs third_node_a2-cache_a_a1 | 134.3 m vs 137.4 m (2.3 %) |
| F2 | ford_nest_a1-lairs_one_a2 vs ford_nest_a2-lairs_one_a1 | 136.1 m vs 133.0 m (2.3 %) |
| F2 | guilds_lodge_a2-lairs_two_b1 vs guilds_lodge_b2-lairs_two_a1 | 138.2 m vs 135.0 m (2.3 %) |
| F2 | cache_b_a1-lairs_one_b1 vs cache_b_b1-lairs_one_a1 | 161.3 m vs 157.7 m (2.3 %) |
| F2 | post_w_a2-lairs_one_b1 vs post_w_b2-lairs_one_a1 | 166.9 m vs 163.1 m (2.3 %) |
| F2 | keep_t3-tower_r_b2 vs keep_t1-tower_r_a1 | 132.1 m vs 129.1 m (2.3 %) |
| F2 | guilds_den_a1-x_bridge_n vs guilds_den_b1-x_bridge_s | 174.8 m vs 178.8 m (2.3 %) |
| F2 | cache_b_a1-lairs_one_b1 vs cache_b_a2-lairs_one_b2 | 161.3 m vs 157.7 m (2.3 %) |
| F2 | cache_b_b1-lairs_one_a1 vs cache_b_b2-lairs_one_a2 | 157.7 m vs 161.3 m (2.3 %) |
| F2 | wallow_a1-x_bridge_n vs wallow_b1-x_bridge_s | 136.3 m vs 139.4 m (2.3 %) |
| F2 | wallow_a2-stag_b2 vs wallow_b2-stag_a2 | 176.9 m vs 180.9 m (2.2 %) |
| F2 | post_w_a1-lairs_one_b2 vs post_w_a2-lairs_one_b1 | 163.1 m vs 166.9 m (2.2 %) |
| F2 | post_w_b1-lairs_one_a2 vs post_w_b2-lairs_one_a1 | 166.8 m vs 163.1 m (2.2 %) |
| F2 | cache_b_a2-lairs_one_b2 vs cache_b_b2-lairs_one_a2 | 157.7 m vs 161.3 m (2.2 %) |
| F2 | home_b_a1-x_bridge_n vs home_b_b1-x_bridge_s | 120.6 m vs 123.4 m (2.2 %) |
| F2 | wallow_a1-wallow_b2 vs wallow_a2-wallow_b1 | 161.7 m vs 158.1 m (2.2 %) |
| F2 | keep_t0-post_w_b1 vs keep_t4-post_w_a2 | 161.7 m vs 158.1 m (2.2 %) |
| F2 | home_b_a2-cache_b_b2 vs home_b_b2-cache_b_a2 | 119.0 m vs 121.7 m (2.2 %) |
| F2 | stag_a1-x_bridge_n vs stag_a2-x_bridge_s | 151.7 m vs 155.2 m (2.2 %) |
| F2 | keep_t0-wallow_b1 vs keep_t4-wallow_a2 | 177.1 m vs 173.1 m (2.2 %) |
| F2 | post_w_a1-lairs_one_b2 vs post_w_b1-lairs_one_a2 | 163.1 m vs 166.8 m (2.2 %) |
| F2 | lairs_one_a2-x_lane_e vs lairs_one_b1-x_lane_w | 120.1 m vs 117.4 m (2.2 %) |
| F2 | guilds_lodge_a1-lairs_two_b2 vs guilds_lodge_a2-lairs_two_b1 | 135.1 m vs 138.2 m (2.2 %) |
| F2 | guilds_lodge_b1-lairs_two_a2 vs guilds_lodge_b2-lairs_two_a1 | 138.1 m vs 135.0 m (2.2 %) |
| F2 | cache_a_a2-x_bridge_s vs cache_a_b1-x_bridge_s | 146.4 m vs 143.1 m (2.2 %) |
| F2 | shrine_a1-lairs_two_a1 vs shrine_b1-lairs_two_b1 | 68.9 m vs 70.5 m (2.2 %) |
| F2 | shrine_a2-lairs_two_a2 vs shrine_b1-lairs_two_b1 | 68.9 m vs 70.5 m (2.2 %) |
| F2 | shrine_b1-lairs_two_b1 vs shrine_b2-lairs_two_b2 | 70.5 m vs 68.9 m (2.2 %) |
| F2 | well_a1-cache_b_b1 vs well_a2-cache_b_b2 | 106.8 m vs 104.5 m (2.2 %) |
| F2 | keep_t0-ford_nest_a2 vs keep_t1-ford_nest_a1 | 97.4 m vs 95.3 m (2.2 %) |
| F2 | keep_t0-x_ford_n vs keep_t1-x_ford_s | 97.4 m vs 95.3 m (2.2 %) |
| F2 | well_a1-cache_a_b1 vs well_b2-cache_a_a2 | 160.5 m vs 164.0 m (2.2 %) |
| F2 | well_b1-cache_a_a1 vs well_b2-cache_a_a2 | 160.5 m vs 164.0 m (2.2 %) |
| F2 | home_a_a1-rich_node_a2 vs home_a_b1-rich_node_b2 | 96.1 m vs 94.1 m (2.2 %) |
| F2 | home_a_a1-rich_node_a2 vs home_a_a2-rich_node_a1 | 96.1 m vs 94.1 m (2.1 %) |
| F2 | lairs_one_a1-x_ford_s vs lairs_one_b1-x_ford_n | 80.6 m vs 78.9 m (2.1 %) |
| F2 | well_a1-cache_a_b1 vs well_a2-cache_a_b2 | 160.5 m vs 164.0 m (2.1 %) |
| F2 | home_b_a1-cache_b_b1 vs home_b_b2-cache_b_a2 | 119.1 m vs 121.7 m (2.1 %) |
| F2 | tower_c_a1-peddler_b1 vs tower_c_a2-peddler_b2 | 92.5 m vs 90.6 m (2.1 %) |
| F2 | well_a2-cache_a_b2 vs well_b1-cache_a_a1 | 164.0 m vs 160.5 m (2.1 %) |
| F2 | tower_c_a2-peddler_b2 vs tower_c_b2-peddler_a2 | 90.6 m vs 92.5 m (2.1 %) |
| F2 | tower_c_a1-peddler_b2 vs tower_c_a2-peddler_b1 | 90.2 m vs 92.2 m (2.1 %) |
| F2 | tower_c_a2-peddler_b1 vs tower_c_b2-peddler_a1 | 92.2 m vs 90.2 m (2.1 %) |
| F2 | tower_c_a2-x_bridge_s vs tower_c_b2-x_bridge_n | 80.2 m vs 78.5 m (2.1 %) |
| F2 | guilds_lodge_a1-lairs_two_b2 vs guilds_lodge_b1-lairs_two_a2 | 135.1 m vs 138.1 m (2.1 %) |
| F2 | nat_node_a1-x_bridge_n vs nat_node_b1-x_bridge_s | 89.6 m vs 91.5 m (2.1 %) |
| F2 | post_w_a2-lairs_one_b2 vs post_w_b2-lairs_one_a2 | 174.7 m vs 178.5 m (2.1 %) |
| F2 | guilds_den_a2-peddler_a1 vs guilds_den_b1-peddler_b2 | 110.5 m vs 108.2 m (2.1 %) |
| F2 | keep_t0-keep_t4 vs keep_t3-keep_t1 | 138.7 m vs 135.8 m (2.1 %) |
| F2 | post_w_a1-lairs_one_b1 vs post_w_b1-lairs_one_a1 | 177.3 m vs 173.6 m (2.1 %) |
| F2 | nat_node_b1-rich_node_a2 vs nat_node_b2-rich_node_a1 | 62.8 m vs 61.5 m (2.1 %) |
| F2 | guilds_lodge_a1-cache_b_b2 vs guilds_lodge_b1-cache_b_a2 | 105.8 m vs 103.5 m (2.1 %) |
| F2 | guilds_den_b1-lairs_one_a1 vs guilds_den_b2-lairs_one_a2 | 235.9 m vs 240.9 m (2.1 %) |
| F2 | guilds_den_a2-lairs_one_b2 vs guilds_den_b2-lairs_one_a2 | 235.9 m vs 240.9 m (2.1 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t3-lairs_two_b2 | 170.4 m vs 166.9 m (2.1 %) |
| F2 | stag_a2-x_bridge_s vs stag_b1-x_bridge_s | 155.2 m vs 151.9 m (2.1 %) |
| F2 | nat_node_a2-x_bridge_s vs nat_node_b1-x_bridge_s | 89.6 m vs 91.5 m (2.1 %) |
| F2 | wallow_a2-x_bridge_s vs wallow_b1-x_bridge_s | 136.5 m vs 139.4 m (2.1 %) |
| F2 | well_a2-cache_b_b2 vs well_b2-cache_b_a2 | 104.5 m vs 106.7 m (2.1 %) |
| F2 | home_b_a1-tower_c_a2 vs home_b_a2-tower_c_a1 | 64.3 m vs 63.0 m (2.1 %) |
| F2 | home_b_a2-tower_c_a1 vs home_b_b2-tower_c_b1 | 63.0 m vs 64.3 m (2.1 %) |
| F2 | home_b_b1-tower_c_b2 vs home_b_b2-tower_c_b1 | 63.0 m vs 64.3 m (2.1 %) |
| F2 | home_b_a1-tower_c_a2 vs home_b_b1-tower_c_b2 | 64.3 m vs 63.0 m (2.1 %) |
| F2 | lairs_one_a2-x_ford_n vs lairs_one_b2-x_ford_s | 79.1 m vs 80.8 m (2.1 %) |
| F2 | wallow_b1-peddler_a1 vs wallow_b2-peddler_a2 | 165.7 m vs 162.3 m (2.1 %) |
| F2 | wallow_a2-peddler_b2 vs wallow_b2-peddler_a2 | 165.7 m vs 162.3 m (2.1 %) |
| F2 | guilds_lodge_b1-cache_b_a2 vs guilds_lodge_b2-cache_b_a1 | 103.5 m vs 105.7 m (2.0 %) |
| F2 | third_node_a1-well_a2 vs third_node_a2-well_a1 | 123.6 m vs 121.1 m (2.0 %) |
| F2 | guilds_lodge_a1-x_ford_s vs guilds_lodge_b1-x_ford_n | 93.4 m vs 91.5 m (2.0 %) |
| F2 | guilds_lodge_a1-x_ford_s vs guilds_lodge_a2-x_ford_n | 93.4 m vs 91.5 m (2.0 %) |
| F2 | nat_node_b1-x_bridge_s vs nat_node_b2-x_bridge_n | 91.5 m vs 89.7 m (2.0 %) |
| F2 | inn_a1-x_bridge_n vs inn_b1-x_bridge_s | 93.4 m vs 95.4 m (2.0 %) |
| F2 | home_a_a1-x_bridge_n vs home_a_a2-x_bridge_s | 114.4 m vs 112.1 m (2.0 %) |
| F2 | guilds_lodge_a1-cache_b_b2 vs guilds_lodge_a2-cache_b_b1 | 105.8 m vs 103.6 m (2.0 %) |
| F2 | guilds_den_a1-x_bridge_s vs guilds_den_a2-x_bridge_n | 77.0 m vs 78.6 m (2.0 %) |
| F2 | guilds_den_a1-x_bridge_s vs guilds_den_b1-x_bridge_n | 77.0 m vs 78.6 m (2.0 %) |
| F2 | guilds_den_a2-x_bridge_n vs guilds_den_b2-x_bridge_s | 78.6 m vs 77.0 m (2.0 %) |
| F2 | guilds_den_b1-x_bridge_n vs guilds_den_b2-x_bridge_s | 78.6 m vs 77.0 m (2.0 %) |
| F2 | keep_t0-lairs_two_a1 vs keep_t1-lairs_two_b1 | 53.2 m vs 52.2 m (2.0 %) |
| F2 | keep_t1-lairs_two_b1 vs keep_t4-lairs_two_b2 | 52.2 m vs 53.2 m (2.0 %) |
| F2 | home_a_a1-tower_r_b1 vs home_a_a2-tower_r_b2 | 129.6 m vs 127.0 m (2.0 %) |
| F2 | cache_a_a1-cache_a_b1 vs cache_a_b2-cache_a_a2 | 175.7 m vs 179.3 m (2.0 %) |
| F2 | third_node_a2-well_a1 vs third_node_b1-well_b2 | 121.1 m vs 123.6 m (2.0 %) |
| F2 | nat_node_a1-rich_node_b2 vs nat_node_b1-rich_node_a2 | 61.6 m vs 62.8 m (2.0 %) |
| F2 | shrine_a1-x_bridge_n vs shrine_b1-x_bridge_s | 94.8 m vs 96.8 m (2.0 %) |
| F2 | home_b_a1-rich_node_b1 vs home_b_b1-rich_node_a1 | 122.9 m vs 120.4 m (2.0 %) |
| F2 | third_node_a2-peddler_a1 vs third_node_b2-peddler_b1 | 91.8 m vs 90.0 m (2.0 %) |
| F2 | third_node_a1-peddler_a2 vs third_node_a2-peddler_a1 | 90.0 m vs 91.8 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 97 sources) 153.19 s.
- Map Lab v2 (map-production.md 2.5): layout quartermeet_s16, 4 seats, rules tempo standard, 2 fixable findings.
- Navmesh raster 23.18 s (1116 polygons, 495616 cells of 0.25 m), spot / mirror checks 20.40 s, 4656 paths 16.35 s.
- Map Quartermeet (seed 16), scene res://docs/tools/world_forge/out/quartermeet_s16/preview.tscn, sim mode off; level load + navmesh bake 4.3 s (13 frames), lab 215.8 s. Spec: docs/design/map-production.md.
