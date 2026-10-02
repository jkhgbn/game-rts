# Map Lab: Quartermeet (seed 18) scorecard: world_forge_quartermeet_s18

2026-10-02 17:55 · lab v1.0 · 571.85 s · scanned 109 spots

## Result: **FAIL** · score **76 / 100**

2 FAIL · 7 WARN · 10 PASS · 2 info checks; findings: 3 FAIL, 518 WARN, 1208 info

## Improve next
1. **Engine limits** (FAIL): engine: <= 140 spots: 159 spots -> the map breaks an engine limit (map-production.md 2.5 R5): a designer changes it _(from R5 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 168 x 168 m ok, 159 spots OVER, 2.0x ok)_
2. **Targets met (rules bands, per seat)** (FAIL): A1 south-west enemy_ally: enemy_ally 1.8 outside 2-3 (12 %) -> a designer moves the keeps or the river (R1 enemy_ally is not auto-fixed) _(from R1 18 / 24 clean (2 FAIL, 4 WARN))_
3. **Map geometry: path pairs match their mirror twins** (WARN): tower_r_a1-tower_r_b2 vs tower_r_a2-tower_r_b1: 36.7 m vs 35.9 m (2.3 %) -> tower_r_a1-tower_r_b2 is longer: look for an unmirrored collider on that route (heat map, M3 tiles) (find the unmirrored obstacle on the longer route) _(from F1 8826 / 8827 pairs within 2 % (0 FAIL, 1 WARN, 0 info))_
4. **Ally keeps: equal, close, on their bank** (WARN): A1 south-west: ally / nearest enemy 0.57 outside 0.33-0.50 (ally 77.4 m, enemy 136.2 m = 1.8x) -> aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally _(from A1 0 / 4 clean (0 FAIL, 4 WARN))_
5. **No navmesh islands** (WARN): island 28 at (-34.5, -32.6): 2.4 m² of ground-level navmesh cut off from the main area (y 0.50) -> a pocket closed by colliders: widen its gap or fill it (trees / rocks) (close or open the pocket) _(from N3 4 / 8 clean (0 FAIL, 4 WARN), 5 info)_
6. **Unit paths (NavigationServer): pairs match their twins** (WARN): well_a2-post_w_a1 vs well_b2-post_w_b1: 83.8 m vs 71.9 m (14.1 %) -> units walk well_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 7135 / 8827 pairs within 2 % (0 FAIL, 489 WARN, 1203 info))_
7. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest camp: 11.9 m vs 13.0 m between seats (8.4 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 8 / 10 clean (0 FAIL, 2 WARN))_
8. **Travel times per seat (worker / soldier / cavalry / caravan)** (WARN): enemy keep (nearest) (caravan): 0:34 vs 0:37 between seats -> one seat's route is longer or crosses more ford: see the travel-time table _(from T1 5 / 7 clean (0 FAIL, 2 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 1302 polygons, main area 26146 m² (93 % of the 168 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 109 / 109 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | **WARN** 52 | 4 / 8 clean (0 FAIL, 4 WARN), 5 info | ground-level components other than the main one < 2 m² | close or open the pocket |
| R5 | Engine limits | **FAIL** 29 | 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 168 x 168 m ok, 159 spots OVER, 2.0x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 109 / 109 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 109 / 109 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | **WARN** 69 | 8826 / 8827 pairs within 2 % (0 FAIL, 1 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) | find the unmirrored obstacle on the longer route |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 7135 / 8827 pairs within 2 % (0 FAIL, 489 WARN, 1203 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 62 | 8 / 10 clean (0 FAIL, 2 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | **WARN** 35 | 0 / 4 clean (0 FAIL, 4 WARN) | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep, ally / nearest enemy 0.33-0.50 |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | **WARN** 59 | 5 / 7 clean (0 FAIL, 2 WARN) | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets met (rules bands, per seat) | **FAIL** 26 | 18 / 24 clean (2 FAIL, 4 WARN) | every `rules` band per seat: FAIL > 10 % outside, WARN 5-10 % |  |
| R2 | Content per seat (Crown Hollow per side) | PASS 100 | 60 / 60 clean | new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL |  |
| R3 | Contested + raidable objectives per seat | PASS 100 | 4 / 4 clean | own / nearest enemy path 0.9-1.1 (contested) or 1.1-1.45 (raidable): >= 3 per seat |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 6 / 6 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 12 / 12 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | **WARN** 65 | 91 / 103 clean (0 FAIL, 12 WARN) | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (672 x 672 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| FAIL | R1 | A1 south-west enemy_ally | enemy_ally 1.8 outside 2-3 (12 %) | a designer moves the keeps or the river (R1 enemy_ally is not auto-fixed) |
| FAIL | R1 | B2 south-east enemy_ally | enemy_ally 1.8 outside 2-3 (12 %) | a designer moves the keeps or the river (R1 enemy_ally is not auto-fixed) |
| FAIL | R5 | engine | <= 140 spots: 159 spots | the map breaks an engine limit (map-production.md 2.5 R5): a designer changes it |
| WARN | N3 | island 28 at (-34.5, -32.6) | 2.4 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 29 at (34.6, -32.7) | 2.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 47 at (-34.6, 32.7) | 2.8 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 48 at (34.6, 32.7) | 2.8 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | F1 | tower_r_a1-tower_r_b2 vs tower_r_a2-tower_r_b1 | 36.7 m vs 35.9 m (2.3 %) | tower_r_a1-tower_r_b2 is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F2 | well_a2-post_w_a1 vs well_b2-post_w_b1 | 83.8 m vs 71.9 m (14.1 %) | units walk well_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a2 vs well_a2-post_w_a1 | 71.9 m vs 83.8 m (14.1 %) | units walk well_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-post_w_b2 vs well_b2-post_w_b1 | 83.8 m vs 71.9 m (14.1 %) | units walk well_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-post_w_a2 vs well_b1-post_w_b2 | 71.9 m vs 83.8 m (14.1 %) | units walk well_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-wallow_a2 vs well_b1-wallow_b2 | 97.9 m vs 113.3 m (13.6 %) | units walk well_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-wallow_a2 vs well_a2-wallow_a1 | 97.9 m vs 113.3 m (13.6 %) | units walk well_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-wallow_b2 vs well_b2-wallow_b1 | 113.3 m vs 97.9 m (13.6 %) | units walk well_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-wallow_a1 vs well_b2-wallow_b1 | 113.3 m vs 97.9 m (13.6 %) | units walk well_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-wallow_b1 vs shrine_a2-wallow_b2 | 167.6 m vs 145.2 m (13.4 %) | units walk shrine_a1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-guilds_lodge_b2 vs well_b2-guilds_lodge_b1 | 146.5 m vs 127.4 m (13.0 %) | units walk well_b1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-guilds_lodge_a2 vs well_b1-guilds_lodge_b2 | 127.4 m vs 146.5 m (13.0 %) | units walk well_b1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-guilds_lodge_a2 vs well_a2-guilds_lodge_a1 | 127.4 m vs 146.5 m (13.0 %) | units walk well_a2-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-guilds_lodge_a1 vs well_b2-guilds_lodge_b1 | 146.5 m vs 127.4 m (13.0 %) | units walk well_a2-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-stag_a2 vs wallow_b2-stag_b2 | 59.3 m vs 52.1 m (12.2 %) | units walk wallow_a2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-stag_b1 vs wallow_b2-stag_b2 | 59.3 m vs 52.1 m (12.2 %) | units walk wallow_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_a1 vs wallow_a2-stag_a2 | 52.1 m vs 59.3 m (12.2 %) | units walk wallow_a2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-stag_a1 vs wallow_b1-stag_b1 | 52.1 m vs 59.3 m (12.2 %) | units walk wallow_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-well_b2 vs rich_node_b1-well_a2 | 56.6 m vs 63.6 m (11.0 %) | units walk rich_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-well_b2 vs rich_node_a2-well_b1 | 56.6 m vs 63.6 m (11.0 %) | units walk rich_node_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-well_a2 vs rich_node_b2-well_a1 | 63.6 m vs 56.6 m (10.9 %) | units walk rich_node_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-well_b1 vs rich_node_b2-well_a1 | 63.6 m vs 56.6 m (10.9 %) | units walk rich_node_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-post_w_b2 vs home_b_b2-post_w_b1 | 58.3 m vs 51.9 m (10.8 %) | units walk home_b_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_a2 vs home_b_b1-post_w_b2 | 51.9 m vs 58.3 m (10.8 %) | units walk home_b_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-post_w_a1 vs home_b_b2-post_w_b1 | 58.3 m vs 51.9 m (10.8 %) | units walk home_b_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_a2 vs home_b_a2-post_w_a1 | 51.9 m vs 58.3 m (10.8 %) | units walk home_b_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-third_node_a1 vs home_b_a2-third_node_a2 | 30.2 m vs 33.7 m (10.6 %) | units walk home_b_a2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-third_node_a2 vs home_b_b2-third_node_b2 | 33.7 m vs 30.2 m (10.6 %) | units walk home_b_a2-third_node_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-third_node_b1 vs home_b_b2-third_node_b2 | 33.7 m vs 30.2 m (10.5 %) | units walk home_b_b1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-third_node_a1 vs home_b_b1-third_node_b1 | 30.2 m vs 33.7 m (10.5 %) | units walk home_b_b1-third_node_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_a1 vs tower_r_a2-tower_c_a2 | 56.8 m vs 63.4 m (10.4 %) | units walk tower_r_a2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-tower_c_a2 vs tower_r_b2-tower_c_b2 | 63.4 m vs 56.8 m (10.4 %) | units walk tower_r_a2-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-tower_c_b1 vs tower_r_b2-tower_c_b2 | 63.4 m vs 56.8 m (10.4 %) | units walk tower_r_b1-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-tower_c_a1 vs tower_r_b1-tower_c_b1 | 56.8 m vs 63.4 m (10.4 %) | units walk tower_r_b1-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-peddler_b2 vs home_a_b2-peddler_a2 | 150.7 m vs 135.1 m (10.3 %) | units walk home_a_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-peddler_b1 vs home_a_a2-peddler_b2 | 135.1 m vs 150.7 m (10.3 %) | units walk home_a_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-peddler_a1 vs home_a_b2-peddler_a2 | 150.6 m vs 135.1 m (10.3 %) | units walk home_a_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-peddler_b1 vs home_a_b1-peddler_a1 | 135.1 m vs 150.6 m (10.3 %) | units walk home_a_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-inn_a1 vs wallow_a2-inn_a2 | 57.6 m vs 51.8 m (10.1 %) | units walk wallow_a1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-inn_a1 vs wallow_b1-inn_b1 | 57.6 m vs 51.8 m (10.1 %) | units walk wallow_a1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-inn_a2 vs wallow_b2-inn_b2 | 51.8 m vs 57.6 m (10.1 %) | units walk wallow_b2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-inn_b1 vs wallow_b2-inn_b2 | 51.8 m vs 57.6 m (10.1 %) | units walk wallow_b2-inn_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-peddler_b2 vs inn_a2-peddler_b1 | 103.0 m vs 92.7 m (10.0 %) | units walk inn_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-peddler_b1 vs inn_b2-peddler_a1 | 92.7 m vs 103.0 m (10.0 %) | units walk inn_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-peddler_b2 vs inn_b1-peddler_a2 | 103.0 m vs 92.7 m (10.0 %) | units walk inn_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-peddler_a2 vs inn_b2-peddler_a1 | 92.7 m vs 103.0 m (10.0 %) | units walk inn_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-wallow_b1 vs shrine_b1-wallow_a1 | 167.6 m vs 151.1 m (9.9 %) | units walk shrine_a1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-wallow_b1 vs shrine_b2-wallow_a2 | 167.6 m vs 151.3 m (9.8 %) | units walk shrine_a1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-tower_c_b1 vs home_a_b2-tower_c_a1 | 102.5 m vs 92.6 m (9.7 %) | units walk home_a_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_b2 vs home_a_a2-tower_c_b1 | 92.6 m vs 102.5 m (9.7 %) | units walk home_a_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-tower_c_a2 vs home_a_b2-tower_c_a1 | 102.4 m vs 92.6 m (9.6 %) | units walk home_a_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-tower_c_b2 vs home_a_b1-tower_c_a2 | 92.6 m vs 102.4 m (9.6 %) | units walk home_a_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_a_b1 vs keep_t1-home_a_a1 | 148.5 m vs 163.9 m (9.4 %) | units walk keep_t1-home_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-home_a_a1 vs keep_t4-home_a_a2 | 163.9 m vs 148.5 m (9.4 %) | units walk keep_t1-home_a_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_b2 vs keep_t4-peddler_a2 | 155.4 m vs 140.9 m (9.3 %) | units walk keep_t3-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t3-peddler_b2 | 140.9 m vs 155.4 m (9.3 %) | units walk keep_t3-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-peddler_a1 vs keep_t4-peddler_a2 | 155.4 m vs 140.9 m (9.3 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_b1 vs keep_t1-peddler_a1 | 140.9 m vs 155.4 m (9.3 %) | units walk keep_t1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-shrine_b2 vs home_a_b2-shrine_a2 | 135.7 m vs 123.1 m (9.3 %) | units walk home_a_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b1 vs home_a_a2-shrine_b2 | 123.1 m vs 135.7 m (9.3 %) | units walk home_a_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-home_a_b1 vs home_a_b2-home_a_a2 | 142.7 m vs 157.2 m (9.3 %) | units walk home_a_b2-home_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-shrine_a1 vs home_a_b2-shrine_a2 | 135.7 m vs 123.1 m (9.2 %) | units walk home_a_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-shrine_b1 vs home_a_b1-shrine_a1 | 123.1 m vs 135.7 m (9.2 %) | units walk home_a_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-wallow_b2 vs keep_t1-wallow_a1 | 165.9 m vs 182.7 m (9.2 %) | units walk keep_t1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-home_b_b2 vs home_b_a2-home_b_b1 | 121.7 m vs 134.0 m (9.2 %) | units walk home_b_a2-home_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b2 vs home_b_b2-peddler_a1 | 135.3 m vs 123.0 m (9.1 %) | units walk home_b_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a2 vs tower_r_b1-post_w_b2 | 99.2 m vs 109.1 m (9.0 %) | units walk tower_r_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a2 vs tower_r_a2-post_w_a1 | 99.2 m vs 109.1 m (9.0 %) | units walk tower_r_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_a1 vs tower_r_b2-post_w_b1 | 109.1 m vs 99.2 m (9.0 %) | units walk tower_r_a2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_w_b2 vs tower_r_b2-post_w_b1 | 109.1 m vs 99.2 m (9.0 %) | units walk tower_r_b1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-guilds_lodge_a2 vs home_b_b2-guilds_lodge_b2 | 42.0 m vs 38.3 m (9.0 %) | units walk home_b_a2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_lodge_a1 vs home_b_a2-guilds_lodge_a2 | 38.3 m vs 42.0 m (9.0 %) | units walk home_b_a2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-guilds_lodge_b1 vs home_b_b2-guilds_lodge_b2 | 42.0 m vs 38.3 m (9.0 %) | units walk home_b_b1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-guilds_lodge_a1 vs home_b_b1-guilds_lodge_b1 | 38.3 m vs 42.0 m (9.0 %) | units walk home_b_b1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-stag_b1 vs home_b_a2-stag_b2 | 163.5 m vs 149.1 m (8.8 %) | units walk home_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-stag_b1 vs home_b_b1-stag_a1 | 163.5 m vs 149.1 m (8.8 %) | units walk home_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_b_b2 vs keep_t3-home_b_b1 | 129.0 m vs 141.5 m (8.8 %) | units walk keep_t3-home_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_b_b2 vs keep_t4-home_b_a1 | 129.0 m vs 141.4 m (8.8 %) | units walk keep_t4-home_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_lodge_b1 vs shrine_b2-guilds_lodge_a2 | 166.7 m vs 152.2 m (8.7 %) | units walk shrine_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_a_a2 vs shrine_b1-cache_a_b2 | 78.9 m vs 72.0 m (8.6 %) | units walk shrine_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_a_a2 vs shrine_a2-cache_a_a1 | 78.9 m vs 72.0 m (8.6 %) | units walk shrine_a1-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-cache_a_b2 vs shrine_b2-cache_a_b1 | 72.0 m vs 78.9 m (8.6 %) | units walk shrine_b2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-cache_a_a1 vs shrine_b2-cache_a_b1 | 72.0 m vs 78.9 m (8.6 %) | units walk shrine_b2-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_a2-guilds_lodge_b1 | 129.9 m vs 118.7 m (8.6 %) | units walk tower_c_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_den_b1 vs shrine_a2-guilds_den_b2 | 162.8 m vs 148.8 m (8.6 %) | units walk shrine_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_one_b1 vs guilds_lodge_b2-lairs_one_a2 | 227.6 m vs 208.0 m (8.6 %) | units walk guilds_lodge_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_den_b1 vs shrine_b1-guilds_den_a1 | 162.8 m vs 148.8 m (8.6 %) | units walk shrine_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_b1-guilds_lodge_a2 | 129.9 m vs 118.8 m (8.6 %) | units walk tower_c_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-keep_t4 vs keep_t3-keep_t1 | 136.2 m vs 148.9 m (8.5 %) | units walk keep_t3-keep_t1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-guilds_lodge_a2 vs keep_t4-guilds_lodge_b2 | 37.4 m vs 40.8 m (8.5 %) | units walk keep_t4-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-guilds_lodge_a1 vs keep_t3-guilds_lodge_a2 | 40.8 m vs 37.4 m (8.5 %) | units walk keep_t0-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-guilds_lodge_a1 vs keep_t1-guilds_lodge_b1 | 40.8 m vs 37.4 m (8.5 %) | units walk keep_t0-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-guilds_lodge_b1 vs keep_t4-guilds_lodge_b2 | 37.4 m vs 40.8 m (8.5 %) | units walk keep_t4-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b_a1 vs wallow_b1-cache_b_b1 | 78.8 m vs 72.2 m (8.4 %) | units walk wallow_a1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b_a1 vs wallow_a2-cache_b_a2 | 78.8 m vs 72.2 m (8.4 %) | units walk wallow_a1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-cache_b_a2 vs wallow_b2-cache_b_b2 | 72.2 m vs 78.8 m (8.4 %) | units walk wallow_b2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-cache_b_b1 vs wallow_b2-cache_b_b2 | 72.2 m vs 78.8 m (8.4 %) | units walk wallow_b2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_b1 vs home_b_b1-wallow_a1 | 163.8 m vs 178.7 m (8.4 %) | units walk home_b_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-wallow_a1 vs home_b_b2-wallow_a2 | 178.7 m vs 163.8 m (8.4 %) | units walk home_b_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-home_a_b1 vs keep_t3-home_a_b2 | 148.5 m vs 162.0 m (8.3 %) | units walk keep_t3-home_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_a_b2 vs keep_t4-home_a_a2 | 162.0 m vs 148.5 m (8.3 %) | units walk keep_t3-home_a_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-tower_c_b1 vs keep_t4-tower_c_a1 | 107.3 m vs 98.3 m (8.3 %) | units walk keep_t3-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b2 vs keep_t3-tower_c_b1 | 98.3 m vs 107.3 m (8.3 %) | units walk keep_t3-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_b1 vs home_b_a2-wallow_b2 | 163.8 m vs 178.6 m (8.3 %) | units walk home_b_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-wallow_b2 vs home_b_b2-wallow_a2 | 178.6 m vs 163.8 m (8.3 %) | units walk home_b_a2-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b1 vs home_b_a2-peddler_b2 | 135.7 m vs 147.9 m (8.3 %) | units walk home_b_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-peddler_b2 vs home_b_b2-peddler_a2 | 147.9 m vs 135.7 m (8.3 %) | units walk home_b_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-tower_c_a2 vs keep_t4-tower_c_a1 | 107.2 m vs 98.3 m (8.2 %) | units walk keep_t1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_c_b2 vs keep_t1-tower_c_a2 | 98.3 m vs 107.2 m (8.2 %) | units walk keep_t1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_a2 vs home_b_b1-wallow_b2 | 80.6 m vs 87.9 m (8.2 %) | units walk home_b_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-wallow_b2 vs home_b_b2-wallow_b1 | 87.9 m vs 80.6 m (8.2 %) | units walk home_b_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-wallow_a1 vs home_b_b2-wallow_b1 | 87.9 m vs 80.6 m (8.2 %) | units walk home_b_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_a2 vs home_b_a2-wallow_a1 | 80.6 m vs 87.9 m (8.2 %) | units walk home_b_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b1 vs keep_t3-shrine_b2 | 128.9 m vs 140.5 m (8.2 %) | units walk keep_t3-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-shrine_b2 vs keep_t4-shrine_a2 | 140.5 m vs 128.9 m (8.2 %) | units walk keep_t3-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-peddler_a1 vs home_b_b2-peddler_a2 | 147.9 m vs 135.7 m (8.2 %) | units walk home_b_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b1 vs home_b_b1-peddler_a1 | 135.7 m vs 147.9 m (8.2 %) | units walk home_b_b1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-post_w_b1 vs rich_hollow_b1-post_w_a1 | 89.0 m vs 97.0 m (8.2 %) | units walk rich_hollow_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-post_w_b1 vs rich_hollow_a2-post_w_b2 | 89.0 m vs 97.0 m (8.2 %) | units walk rich_hollow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-post_w_a1 vs rich_hollow_b2-post_w_a2 | 97.0 m vs 89.0 m (8.2 %) | units walk rich_hollow_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-post_w_b2 vs rich_hollow_b2-post_w_a2 | 97.0 m vs 89.0 m (8.2 %) | units walk rich_hollow_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b1 vs keep_t1-shrine_a1 | 128.9 m vs 140.5 m (8.2 %) | units walk keep_t1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-shrine_a1 vs keep_t4-shrine_a2 | 140.5 m vs 128.9 m (8.2 %) | units walk keep_t1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-well_b2 vs well_a2-well_b1 | 79.1 m vs 86.1 m (8.2 %) | units walk well_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-post_w_a1 vs home_a_b2-post_w_a2 | 163.3 m vs 150.1 m (8.1 %) | units walk home_a_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_w_b1 vs home_a_b1-post_w_a1 | 150.1 m vs 163.3 m (8.1 %) | units walk home_a_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b2-cache_b_a2 | 162.4 m vs 149.3 m (8.1 %) | units walk guilds_den_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a1-cache_b_b1 vs guilds_den_a2-cache_b_b2 | 149.3 m vs 162.4 m (8.0 %) | units walk guilds_den_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-wallow_a1 vs tower_r_b2-wallow_b1 | 136.8 m vs 125.8 m (8.0 %) | units walk tower_r_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-wallow_a2 vs tower_r_a2-wallow_a1 | 125.8 m vs 136.8 m (8.0 %) | units walk tower_r_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-wallow_a2 vs tower_r_b1-wallow_b2 | 125.8 m vs 136.7 m (8.0 %) | units walk tower_r_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-wallow_b2 vs tower_r_b2-wallow_b1 | 136.7 m vs 125.8 m (8.0 %) | units walk tower_r_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-lairs_one_b1 vs nat_node_b1-lairs_one_a2 | 124.8 m vs 114.8 m (8.0 %) | units walk nat_node_a2-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_b1-guilds_den_b1 vs rich_lodge_b2-guilds_den_b2 | 93.4 m vs 85.9 m (8.0 %) | units walk rich_lodge_b1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-peddler_a2 vs wallow_b2-peddler_a1 | 142.9 m vs 155.3 m (7.9 %) | units walk wallow_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b2 vs wallow_b1-peddler_a2 | 155.3 m vs 142.9 m (7.9 %) | units walk wallow_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-peddler_b1 vs wallow_b2-peddler_a1 | 142.9 m vs 155.3 m (7.9 %) | units walk wallow_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b2 vs wallow_a2-peddler_b1 | 155.3 m vs 142.9 m (7.9 %) | units walk wallow_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a2-guilds_den_a2 vs rich_lodge_b1-guilds_den_b1 | 86.1 m vs 93.4 m (7.8 %) | units walk rich_lodge_b1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_b1-guilds_lodge_b1 vs rich_lodge_b2-guilds_lodge_b2 | 94.5 m vs 102.5 m (7.8 %) | units walk rich_lodge_b2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_b2 vs home_b_a2-wallow_b1 | 139.3 m vs 151.1 m (7.8 %) | units walk home_b_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-wallow_b2 vs home_b_b2-wallow_a1 | 139.3 m vs 151.0 m (7.8 %) | units walk home_b_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-guilds_den_b1 vs keep_t3-guilds_den_b2 | 195.5 m vs 180.4 m (7.7 %) | units walk keep_t0-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_one_b1 vs guilds_lodge_a2-lairs_one_b2 | 227.6 m vs 210.0 m (7.7 %) | units walk guilds_lodge_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-guilds_den_b1 vs keep_t1-guilds_den_a1 | 195.5 m vs 180.4 m (7.7 %) | units walk keep_t0-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-lairs_one_b1 vs guilds_lodge_b1-lairs_one_a1 | 227.6 m vs 210.1 m (7.7 %) | units walk guilds_lodge_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_den_a2-cache_b_b2 vs guilds_den_b1-cache_b_a1 | 162.4 m vs 149.9 m (7.7 %) | units walk guilds_den_a2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-home_b_b1 vs home_b_b2-home_b_a2 | 148.7 m vs 161.0 m (7.7 %) | units walk home_b_b2-home_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-wallow_b1 vs keep_t1-wallow_a1 | 169.0 m vs 182.7 m (7.5 %) | units walk keep_t1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-wallow_a1 vs keep_t4-wallow_a2 | 182.7 m vs 169.0 m (7.5 %) | units walk keep_t1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-wallow_a1 vs nat_node_a2-wallow_a2 | 48.2 m vs 52.2 m (7.5 %) | units walk nat_node_a2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-wallow_a1 vs nat_node_b1-wallow_b1 | 48.2 m vs 52.2 m (7.5 %) | units walk nat_node_b1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_b1-wallow_b1 vs nat_node_b2-wallow_b2 | 52.2 m vs 48.2 m (7.5 %) | units walk nat_node_b1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a2-wallow_a2 vs nat_node_b2-wallow_b2 | 52.2 m vs 48.2 m (7.5 %) | units walk nat_node_a2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a1-guilds_lodge_b2 vs rich_den_b1-guilds_lodge_a2 | 92.8 m vs 85.9 m (7.5 %) | units walk rich_den_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a1-guilds_lodge_b2 vs rich_den_a2-guilds_lodge_b1 | 92.8 m vs 85.9 m (7.4 %) | units walk rich_den_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_lodge_b1 vs home_a_b2-guilds_lodge_a2 | 187.6 m vs 173.7 m (7.4 %) | units walk home_a_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_e vs guilds_lodge_b1-x_lane_w | 134.1 m vs 124.3 m (7.4 %) | units walk guilds_lodge_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-x_ford_n vs home_b_b2-x_ford_s | 65.4 m vs 60.6 m (7.3 %) | units walk home_b_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-ford_nest_a1 vs home_b_a2-ford_nest_a2 | 60.6 m vs 65.4 m (7.3 %) | units walk home_b_a2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-ford_nest_a2 vs home_b_b2-ford_nest_a1 | 65.4 m vs 60.6 m (7.3 %) | units walk home_b_a2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_ford_s vs home_b_a2-x_ford_n | 60.6 m vs 65.4 m (7.3 %) | units walk home_b_a2-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-ford_nest_a2 vs home_b_b2-ford_nest_a1 | 65.4 m vs 60.6 m (7.3 %) | units walk home_b_b1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-x_ford_s vs home_b_b1-x_ford_n | 60.6 m vs 65.4 m (7.3 %) | units walk home_b_b1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-x_ford_n vs home_b_b2-x_ford_s | 65.4 m vs 60.6 m (7.3 %) | units walk home_b_b1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-ford_nest_a1 vs home_b_b1-ford_nest_a2 | 60.6 m vs 65.4 m (7.3 %) | units walk home_b_b1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_b1-lairs_one_b1 vs rich_lodge_b2-lairs_one_b2 | 83.1 m vs 77.0 m (7.3 %) | units walk rich_lodge_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_e vs guilds_lodge_b2-x_lane_w | 134.1 m vs 124.3 m (7.3 %) | units walk guilds_lodge_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_den_b1 vs home_a_a2-guilds_den_b2 | 183.7 m vs 170.3 m (7.3 %) | units walk home_a_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_s_a2 vs wallow_b2-post_s_b2 | 49.5 m vs 53.4 m (7.3 %) | units walk wallow_b2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_s_a1 vs wallow_a2-post_s_a2 | 53.4 m vs 49.5 m (7.3 %) | units walk wallow_a1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-post_w_a1 vs keep_t4-post_w_a2 | 168.1 m vs 155.9 m (7.3 %) | units walk keep_t1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_w_b1 vs keep_t1-post_w_a1 | 155.9 m vs 168.1 m (7.3 %) | units walk keep_t1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_den_b1 vs home_a_b1-guilds_den_a1 | 183.7 m vs 170.3 m (7.3 %) | units walk home_a_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_e vs guilds_lodge_a2-x_lane_e | 134.1 m vs 124.4 m (7.3 %) | units walk guilds_lodge_a1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_a2 vs rich_node_a2-wallow_a1 | 112.9 m vs 121.6 m (7.2 %) | units walk rich_node_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-wallow_b2 vs rich_node_b2-wallow_b1 | 121.6 m vs 112.9 m (7.2 %) | units walk rich_node_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-wallow_a1 vs rich_node_b2-wallow_b1 | 121.6 m vs 112.9 m (7.2 %) | units walk rich_node_a2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_a2 vs rich_node_b1-wallow_b2 | 112.9 m vs 121.6 m (7.2 %) | units walk rich_node_b1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a2-lairs_one_a2 vs rich_lodge_b1-lairs_one_b1 | 77.2 m vs 83.1 m (7.2 %) | units walk rich_lodge_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-guilds_lodge_b1 vs shrine_b1-guilds_lodge_a2 | 153.7 m vs 142.7 m (7.1 %) | units walk shrine_a2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-guilds_lodge_b1 vs rich_hollow_b2-guilds_lodge_b2 | 90.2 m vs 97.2 m (7.1 %) | units walk rich_hollow_b2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-guilds_lodge_a2 vs rich_hollow_b2-guilds_lodge_b2 | 90.2 m vs 97.2 m (7.1 %) | units walk rich_hollow_b2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_b_a1 vs post_s_b1-cache_b_b1 | 70.2 m vs 65.2 m (7.1 %) | units walk post_s_a1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-cache_b_a1 vs post_s_a2-cache_b_a2 | 70.2 m vs 65.2 m (7.1 %) | units walk post_s_a1-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-cache_b_a2 vs post_s_b2-cache_b_b2 | 65.2 m vs 70.2 m (7.1 %) | units walk post_s_b2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-cache_b_b1 vs post_s_b2-cache_b_b2 | 65.2 m vs 70.2 m (7.1 %) | units walk post_s_b2-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-post_w_a2 vs tower_r_b2-post_w_b2 | 87.1 m vs 80.9 m (7.1 %) | units walk tower_r_a2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a1 vs tower_r_b1-post_w_b1 | 80.9 m vs 87.1 m (7.1 %) | units walk tower_r_b1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-post_w_b1 vs tower_r_b2-post_w_b2 | 87.1 m vs 80.9 m (7.1 %) | units walk tower_r_b1-post_w_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-post_w_a1 vs tower_r_a2-post_w_a2 | 80.9 m vs 87.1 m (7.1 %) | units walk tower_r_a2-post_w_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_s_a2 vs wallow_b1-post_s_b1 | 49.5 m vs 53.3 m (7.1 %) | units walk wallow_b1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-guilds_den_b1 vs shrine_b2-guilds_den_a1 | 149.8 m vs 139.1 m (7.1 %) | units walk shrine_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_den_b2 vs shrine_a2-guilds_den_b1 | 139.1 m vs 149.8 m (7.1 %) | units walk shrine_a2-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-lairs_one_a1 vs rich_lodge_b1-lairs_one_b1 | 77.3 m vs 83.1 m (7.0 %) | units walk rich_lodge_b1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-inn_a1 vs home_a_b2-inn_a2 | 119.3 m vs 111.0 m (7.0 %) | units walk home_a_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-inn_b1 vs home_a_b1-inn_a1 | 111.0 m vs 119.3 m (7.0 %) | units walk home_a_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b1 vs home_b_a2-shrine_b2 | 123.7 m vs 133.0 m (7.0 %) | units walk home_b_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-shrine_b2 vs home_b_b2-shrine_a2 | 133.0 m vs 123.7 m (7.0 %) | units walk home_b_a2-shrine_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-inn_b2 vs home_a_b1-inn_a1 | 111.0 m vs 119.3 m (7.0 %) | units walk home_a_b1-inn_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-shrine_a1 vs home_b_b2-shrine_a2 | 133.0 m vs 123.7 m (6.9 %) | units walk home_b_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-shrine_b1 vs home_b_b1-shrine_a1 | 123.7 m vs 133.0 m (6.9 %) | units walk home_b_b1-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-stag_a2 vs tower_c_b2-stag_b2 | 74.0 m vs 68.8 m (6.9 %) | units walk tower_c_a2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a1 vs tower_c_a2-stag_a2 | 68.8 m vs 74.0 m (6.9 %) | units walk tower_c_a2-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-stag_b1 vs tower_c_b2-stag_b2 | 74.0 m vs 68.8 m (6.9 %) | units walk tower_c_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-stag_a1 vs tower_c_b1-stag_b1 | 68.8 m vs 74.0 m (6.9 %) | units walk tower_c_b1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-post_s_a1 vs shrine_b2-post_s_b1 | 85.1 m vs 91.4 m (6.9 %) | units walk shrine_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_a2 vs shrine_b1-post_s_b2 | 91.4 m vs 85.1 m (6.9 %) | units walk shrine_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-post_s_a2 vs shrine_a2-post_s_a1 | 91.4 m vs 85.1 m (6.9 %) | units walk shrine_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-post_s_b2 vs shrine_b2-post_s_b1 | 85.1 m vs 91.4 m (6.9 %) | units walk shrine_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-well_b2 vs third_node_b2-well_a2 | 164.2 m vs 176.3 m (6.9 %) | units walk third_node_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-peddler_a1 vs post_s_a2-peddler_a2 | 62.6 m vs 58.3 m (6.9 %) | units walk post_s_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-peddler_a1 vs post_s_b1-peddler_b1 | 62.6 m vs 58.3 m (6.9 %) | units walk post_s_a1-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_b1-peddler_b1 vs post_s_b2-peddler_b2 | 58.3 m vs 62.6 m (6.9 %) | units walk post_s_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-peddler_a2 vs post_s_b2-peddler_b2 | 58.3 m vs 62.6 m (6.9 %) | units walk post_s_b2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-ford_nest_a2 vs keep_t4-ford_nest_a1 | 72.9 m vs 67.9 m (6.8 %) | units walk keep_t3-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-x_ford_n vs keep_t4-x_ford_s | 72.9 m vs 67.9 m (6.8 %) | units walk keep_t3-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_nest_a1 vs keep_t3-ford_nest_a2 | 67.9 m vs 72.9 m (6.8 %) | units walk keep_t3-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-x_ford_s vs keep_t3-x_ford_n | 67.9 m vs 72.9 m (6.8 %) | units walk keep_t3-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-x_ford_s vs keep_t1-x_ford_n | 67.9 m vs 72.9 m (6.8 %) | units walk keep_t1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-ford_nest_a1 vs keep_t1-ford_nest_a2 | 67.9 m vs 72.9 m (6.8 %) | units walk keep_t1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-ford_nest_a2 vs keep_t4-ford_nest_a1 | 72.9 m vs 67.9 m (6.8 %) | units walk keep_t1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-x_ford_n vs keep_t4-x_ford_s | 72.9 m vs 67.9 m (6.8 %) | units walk keep_t1-x_ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-inn_a1 vs stag_b2-inn_a2 | 122.7 m vs 131.6 m (6.8 %) | units walk stag_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-inn_b2 vs stag_b2-inn_a2 | 122.7 m vs 131.6 m (6.8 %) | units walk stag_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-wallow_a2 vs tower_c_b2-wallow_a1 | 109.8 m vs 117.7 m (6.7 %) | units walk tower_c_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_one_b1 vs home_b_a2-lairs_one_b2 | 184.9 m vs 172.4 m (6.7 %) | units walk home_b_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_b1 vs shrine_a2-lairs_one_b2 | 155.3 m vs 144.9 m (6.7 %) | units walk shrine_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-lairs_one_b1 vs shrine_b1-lairs_one_a1 | 155.3 m vs 144.9 m (6.7 %) | units walk shrine_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-lairs_one_b1 vs home_b_b1-lairs_one_a1 | 184.9 m vs 172.5 m (6.7 %) | units walk home_b_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_lodge_b1 vs shrine_b1-guilds_lodge_a1 | 166.7 m vs 155.6 m (6.7 %) | units walk shrine_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-wallow_b2 vs tower_c_b1-wallow_a2 | 117.7 m vs 109.8 m (6.7 %) | units walk tower_c_a1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b2 vs home_b_a2-tower_c_b1 | 93.2 m vs 99.8 m (6.7 %) | units walk home_b_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-tower_c_b1 vs home_b_b2-tower_c_a1 | 99.8 m vs 93.2 m (6.7 %) | units walk home_b_a2-tower_c_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_b_a1 vs guilds_lodge_b2-cache_b_a2 | 145.9 m vs 156.4 m (6.7 %) | units walk guilds_lodge_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_b_b2 vs guilds_lodge_b2-cache_b_a2 | 146.0 m vs 156.4 m (6.7 %) | units walk guilds_lodge_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-guilds_den_b1 vs wallow_a2-guilds_den_b2 | 205.6 m vs 191.9 m (6.6 %) | units walk wallow_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-guilds_den_b1 vs wallow_b1-guilds_den_a1 | 205.6 m vs 191.9 m (6.6 %) | units walk wallow_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_den_a1 vs home_b_a2-rich_den_a2 | 58.3 m vs 62.4 m (6.6 %) | units walk home_b_a2-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-rich_den_a2 vs home_b_b2-rich_den_b2 | 62.4 m vs 58.3 m (6.6 %) | units walk home_b_a2-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-rich_den_b1 vs home_b_b2-rich_den_b2 | 62.4 m vs 58.3 m (6.6 %) | units walk home_b_b1-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_den_a1 vs home_b_b1-rich_den_b1 | 58.3 m vs 62.4 m (6.6 %) | units walk home_b_b1-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-cache_b_b1 vs tower_c_b2-cache_b_a2 | 57.5 m vs 61.6 m (6.6 %) | units walk tower_c_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-tower_c_a2 vs home_b_b2-tower_c_a1 | 99.7 m vs 93.2 m (6.6 %) | units walk home_b_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-tower_c_b2 vs home_b_b1-tower_c_a2 | 93.2 m vs 99.7 m (6.6 %) | units walk home_b_b1-tower_c_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a2-cache_b_b2 vs tower_c_b2-cache_b_a2 | 57.5 m vs 61.6 m (6.5 %) | units walk tower_c_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_b1-cache_b_a1 vs tower_c_b2-cache_b_a2 | 57.5 m vs 61.6 m (6.5 %) | units walk tower_c_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b2 vs home_b_a2-well_b1 | 104.7 m vs 112.0 m (6.5 %) | units walk home_b_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-well_b1 vs home_b_b2-well_a1 | 112.0 m vs 104.7 m (6.5 %) | units walk home_b_a2-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-guilds_den_a1 vs rich_lodge_b2-guilds_den_b2 | 91.9 m vs 85.9 m (6.5 %) | units walk rich_lodge_a1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b2 vs home_b_b1-well_a2 | 104.7 m vs 111.9 m (6.5 %) | units walk home_b_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-well_a2 vs home_b_b2-well_a1 | 111.9 m vs 104.7 m (6.5 %) | units walk home_b_b1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a2-guilds_lodge_a2 vs rich_lodge_b2-guilds_lodge_b2 | 95.9 m vs 102.5 m (6.5 %) | units walk rich_lodge_b2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-post_s_a2 vs inn_b2-post_s_b2 | 56.2 m vs 60.0 m (6.4 %) | units walk inn_b2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-post_s_b1 vs inn_b2-post_s_b2 | 56.2 m vs 60.0 m (6.4 %) | units walk inn_b2-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_s_a1 vs inn_a2-post_s_a2 | 60.0 m vs 56.2 m (6.4 %) | units walk inn_a1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_s_a1 vs inn_b1-post_s_b1 | 60.0 m vs 56.2 m (6.4 %) | units walk inn_a1-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-wallow_a2 vs well_b2-wallow_a1 | 117.3 m vs 125.4 m (6.4 %) | units walk well_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-inn_b1 vs stag_b2-inn_a2 | 123.2 m vs 131.6 m (6.4 %) | units walk stag_b2-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-keep_t1 vs keep_t4-keep_t3 | 164.9 m vs 154.3 m (6.4 %) | units walk keep_t0-keep_t1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-guilds_den_a1 vs rich_lodge_a2-guilds_den_a2 | 91.9 m vs 86.1 m (6.4 %) | units walk rich_lodge_a1-guilds_den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_b_b2 vs keep_t1-home_b_a1 | 149.2 m vs 159.3 m (6.4 %) | units walk keep_t1-home_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-cache_b_b1 vs home_b_b2-cache_b_a1 | 80.0 m vs 75.0 m (6.3 %) | units walk home_b_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-wallow_b1 vs well_b1-wallow_a2 | 125.2 m vs 117.3 m (6.3 %) | units walk well_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_one_b1 vs peddler_a2-lairs_one_b2 | 170.5 m vs 159.8 m (6.3 %) | units walk peddler_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_one_b1 vs peddler_b1-lairs_one_a1 | 170.5 m vs 159.8 m (6.3 %) | units walk peddler_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_b1 vs home_b_a2-post_w_b2 | 150.7 m vs 160.7 m (6.3 %) | units walk home_b_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-post_w_b2 vs home_b_b2-post_w_a2 | 160.7 m vs 150.7 m (6.3 %) | units walk home_b_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-guilds_lodge_b1 vs shrine_a2-guilds_lodge_b2 | 166.7 m vs 156.4 m (6.2 %) | units walk shrine_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-post_w_a1 vs home_b_b2-post_w_a2 | 160.6 m vs 150.7 m (6.2 %) | units walk home_b_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-post_w_b1 vs home_b_b1-post_w_a1 | 150.7 m vs 160.6 m (6.2 %) | units walk home_b_b1-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-cache_b_a2 vs home_b_b2-cache_b_a1 | 79.9 m vs 75.0 m (6.2 %) | units walk home_b_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_b_b2 vs home_b_a2-cache_b_b1 | 75.1 m vs 80.0 m (6.2 %) | units walk home_b_a2-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_one_b1 vs keep_t3-lairs_one_b2 | 188.0 m vs 176.5 m (6.1 %) | units walk keep_t0-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_one_b1 vs keep_t1-lairs_one_a1 | 188.0 m vs 176.5 m (6.1 %) | units walk keep_t0-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_den_b2 vs home_b_b1-rich_den_a2 | 63.0 m vs 67.1 m (6.1 %) | units walk home_b_b1-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-rich_den_a2 vs home_b_b2-rich_den_a1 | 67.1 m vs 63.0 m (6.1 %) | units walk home_b_b1-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_den_b2 vs home_b_a2-rich_den_b1 | 63.0 m vs 67.1 m (6.1 %) | units walk home_b_a2-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-rich_den_b1 vs home_b_b2-rich_den_a1 | 67.1 m vs 63.0 m (6.1 %) | units walk home_b_a2-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_r_b1 vs third_node_b1-tower_r_a1 | 168.2 m vs 157.9 m (6.1 %) | units walk third_node_a1-tower_r_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-tower_r_b1 vs third_node_a2-tower_r_b2 | 168.2 m vs 157.9 m (6.1 %) | units walk third_node_a1-tower_r_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_den_a2 vs keep_t4-rich_den_b2 | 69.9 m vs 65.6 m (6.1 %) | units walk keep_t3-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_den_a1 vs keep_t3-rich_den_a2 | 65.6 m vs 69.9 m (6.1 %) | units walk keep_t3-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-rich_den_b1 vs keep_t4-rich_den_b2 | 69.9 m vs 65.6 m (6.1 %) | units walk keep_t1-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_den_a1 vs keep_t1-rich_den_b1 | 65.6 m vs 69.9 m (6.1 %) | units walk keep_t1-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a2-crown vs third_node_b2-crown | 104.8 m vs 98.5 m (6.1 %) | units walk third_node_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_b1-crown vs third_node_b2-crown | 104.8 m vs 98.5 m (6.1 %) | units walk third_node_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-crown vs third_node_a2-crown | 98.5 m vs 104.8 m (6.1 %) | units walk third_node_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node_a1-crown vs third_node_b1-crown | 98.5 m vs 104.8 m (6.1 %) | units walk third_node_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_b_a2 vs well_a2-cache_b_a1 | 77.3 m vs 82.2 m (6.1 %) | units walk well_a2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_b_a1 vs well_b2-cache_b_b1 | 82.2 m vs 77.3 m (6.1 %) | units walk well_a2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b2 vs keep_t3-well_b1 | 112.3 m vs 119.5 m (6.0 %) | units walk keep_t3-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-well_b1 vs keep_t4-well_a1 | 119.5 m vs 112.3 m (6.0 %) | units walk keep_t3-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-cache_b_b2 vs home_b_b1-cache_b_a2 | 75.1 m vs 79.9 m (6.0 %) | units walk home_b_b1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-stag_a2 vs rich_node_b2-stag_b1 | 136.1 m vs 127.9 m (6.0 %) | units walk rich_node_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-wallow_b2 vs well_b2-wallow_a1 | 117.8 m vs 125.4 m (6.0 %) | units walk well_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b2 vs keep_t1-well_a2 | 112.3 m vs 119.4 m (6.0 %) | units walk keep_t1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-well_a2 vs keep_t4-well_a1 | 119.4 m vs 112.3 m (6.0 %) | units walk keep_t1-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-cache_b_b1 vs keep_t4-cache_b_a1 | 87.5 m vs 82.3 m (6.0 %) | units walk keep_t3-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_b2 vs rich_node_b2-wallow_a1 | 96.8 m vs 102.9 m (5.9 %) | units walk rich_node_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-post_s_a2 vs ford_nest_a2-post_s_a1 | 131.5 m vs 123.7 m (5.9 %) | units walk ford_nest_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-guilds_den_b2 vs shrine_b2-guilds_den_a2 | 148.8 m vs 158.1 m (5.9 %) | units walk shrine_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-guilds_den_a1 vs shrine_b2-guilds_den_a2 | 148.8 m vs 158.1 m (5.9 %) | units walk shrine_b2-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-rich_lodge_b2 vs well_b2-rich_lodge_a2 | 108.5 m vs 102.2 m (5.9 %) | units walk well_a2-rich_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-rich_lodge_b1 vs well_a2-rich_lodge_b2 | 102.2 m vs 108.5 m (5.9 %) | units walk well_a2-rich_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_s_a2 vs wallow_a2-post_s_a1 | 124.9 m vs 132.7 m (5.9 %) | units walk wallow_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-post_s_a1 vs wallow_b2-post_s_b1 | 132.7 m vs 124.9 m (5.9 %) | units walk wallow_a2-post_s_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-post_s_b2 vs wallow_b2-post_s_b1 | 132.7 m vs 124.9 m (5.9 %) | units walk wallow_b1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-post_s_a2 vs wallow_b1-post_s_b2 | 124.9 m vs 132.7 m (5.9 %) | units walk wallow_b1-post_s_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-post_s_a2 vs ford_nest_a2-post_s_b2 | 131.5 m vs 123.7 m (5.9 %) | units walk ford_nest_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-wallow_b2 vs well_a2-wallow_b1 | 117.8 m vs 125.2 m (5.9 %) | units walk well_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-well_b1 vs tower_c_b1-well_a1 | 91.0 m vs 85.7 m (5.9 %) | units walk tower_c_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-well_b1 vs tower_c_a2-well_b2 | 91.0 m vs 85.7 m (5.9 %) | units walk tower_c_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b1 vs keep_t3-well_b2 | 146.6 m vs 138.0 m (5.9 %) | units walk keep_t0-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-post_s_b1 vs rich_hollow_a2-post_s_b2 | 133.1 m vs 125.3 m (5.8 %) | units walk rich_hollow_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-post_s_b1 vs rich_hollow_b1-post_s_a1 | 133.1 m vs 125.3 m (5.8 %) | units walk rich_hollow_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-post_s_b2 vs rich_hollow_b2-post_s_a2 | 125.3 m vs 133.1 m (5.8 %) | units walk rich_hollow_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-post_s_a1 vs rich_hollow_b2-post_s_a2 | 125.3 m vs 133.1 m (5.8 %) | units walk rich_hollow_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-cache_b_a2 vs keep_t4-cache_b_a1 | 87.4 m vs 82.3 m (5.8 %) | units walk keep_t1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-guilds_lodge_b1 vs post_w_b2-guilds_lodge_a2 | 186.7 m vs 175.8 m (5.8 %) | units walk post_w_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-post_w_b2 vs home_a_b2-post_w_a2 | 159.4 m vs 150.1 m (5.8 %) | units walk home_a_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-post_w_b1 vs home_a_a2-post_w_b2 | 150.1 m vs 159.4 m (5.8 %) | units walk home_a_a2-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-rich_hollow_a2 vs home_b_b2-rich_hollow_b2 | 71.5 m vs 67.3 m (5.8 %) | units walk home_b_a2-rich_hollow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-wallow_b1 vs rich_hollow_b2-wallow_a1 | 75.9 m vs 71.5 m (5.8 %) | units walk rich_hollow_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-wallow_b2 vs rich_hollow_a2-wallow_b1 | 71.5 m vs 75.9 m (5.8 %) | units walk rich_hollow_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-wallow_a2 vs rich_hollow_b2-wallow_a1 | 75.9 m vs 71.5 m (5.8 %) | units walk rich_hollow_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-wallow_b2 vs rich_hollow_b1-wallow_a2 | 71.5 m vs 75.9 m (5.8 %) | units walk rich_hollow_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_b_b2 vs keep_t3-cache_b_b1 | 82.4 m vs 87.5 m (5.8 %) | units walk keep_t3-cache_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b1 vs keep_t1-well_a1 | 146.6 m vs 138.0 m (5.8 %) | units walk keep_t0-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-rich_hollow_b1 vs home_b_b2-rich_hollow_b2 | 71.5 m vs 67.3 m (5.8 %) | units walk home_b_b1-rich_hollow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-rich_lodge_a2 vs home_b_b2-rich_lodge_b2 | 77.1 m vs 72.7 m (5.8 %) | units walk home_b_a2-rich_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_hollow_a1 vs home_b_a2-rich_hollow_a2 | 67.3 m vs 71.5 m (5.8 %) | units walk home_b_a2-rich_hollow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_hollow_a1 vs home_b_b1-rich_hollow_b1 | 67.3 m vs 71.5 m (5.8 %) | units walk home_b_b1-rich_hollow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_b2 vs ford_nest_a2-guilds_lodge_b1 | 89.6 m vs 84.5 m (5.8 %) | units walk ford_nest_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_b2 vs ford_nest_a2-guilds_lodge_a2 | 89.6 m vs 84.5 m (5.8 %) | units walk ford_nest_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_lodge_a2 vs stag_b1-guilds_lodge_b2 | 161.0 m vs 151.7 m (5.8 %) | units walk stag_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-guilds_lodge_a1 vs stag_b2-guilds_lodge_b1 | 151.7 m vs 161.0 m (5.8 %) | units walk stag_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-guilds_lodge_b2 vs stag_b2-guilds_lodge_b1 | 151.7 m vs 161.0 m (5.8 %) | units walk stag_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-guilds_lodge_a2 vs stag_a2-guilds_lodge_a1 | 161.0 m vs 151.7 m (5.8 %) | units walk stag_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-guilds_lodge_b1 vs keep_t4-guilds_lodge_a2 | 187.3 m vs 198.7 m (5.7 %) | units walk keep_t4-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-guilds_den_b1 vs post_w_a2-guilds_den_b2 | 182.8 m vs 172.4 m (5.7 %) | units walk post_w_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_w_a1-guilds_den_b1 vs post_w_b1-guilds_den_a1 | 182.8 m vs 172.4 m (5.7 %) | units walk post_w_a1-guilds_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_a2 vs ford_nest_a2-guilds_lodge_a1 | 140.3 m vs 132.3 m (5.7 %) | units walk ford_nest_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_den_b2 vs keep_t1-rich_den_a2 | 70.4 m vs 74.6 m (5.7 %) | units walk keep_t1-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-rich_den_a2 vs keep_t4-rich_den_a1 | 74.6 m vs 70.4 m (5.7 %) | units walk keep_t1-rich_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-cache_b_b2 vs keep_t1-cache_b_a2 | 82.4 m vs 87.4 m (5.7 %) | units walk keep_t1-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_b2 vs rich_node_b1-wallow_a2 | 96.8 m vs 102.6 m (5.7 %) | units walk rich_node_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_den_b2 vs keep_t3-rich_den_b1 | 70.4 m vs 74.6 m (5.7 %) | units walk keep_t3-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_den_b1 vs keep_t4-rich_den_a1 | 74.6 m vs 70.4 m (5.7 %) | units walk keep_t3-rich_den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-wallow_b2 vs rich_node_a2-wallow_b1 | 96.8 m vs 102.6 m (5.7 %) | units walk rich_node_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-stag_b2 vs shrine_b2-stag_b1 | 83.5 m vs 88.5 m (5.7 %) | units walk shrine_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_a2 vs shrine_b1-stag_b2 | 88.5 m vs 83.5 m (5.7 %) | units walk shrine_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_a2 vs shrine_a2-stag_a1 | 88.5 m vs 83.5 m (5.7 %) | units walk shrine_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a2-stag_a1 vs shrine_b2-stag_b1 | 83.5 m vs 88.5 m (5.7 %) | units walk shrine_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-wallow_b2 vs wallow_a2-wallow_b1 | 156.6 m vs 166.0 m (5.7 %) | units walk wallow_a2-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-post_s_a1 vs rich_hollow_b2-post_s_b1 | 131.7 m vs 139.6 m (5.7 %) | units walk rich_hollow_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-guilds_lodge_a2 vs ford_nest_a2-guilds_lodge_b2 | 140.3 m vs 132.3 m (5.6 %) | units walk ford_nest_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-guilds_lodge_b2 vs rich_hollow_b1-guilds_lodge_a2 | 81.4 m vs 76.8 m (5.6 %) | units walk rich_hollow_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-guilds_lodge_b2 vs rich_hollow_a2-guilds_lodge_b1 | 81.4 m vs 76.8 m (5.6 %) | units walk rich_hollow_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-guilds_lodge_b1 vs rich_hollow_b2-guilds_lodge_a1 | 76.8 m vs 81.4 m (5.6 %) | units walk rich_hollow_b2-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-guilds_lodge_a2 vs rich_hollow_b2-guilds_lodge_a1 | 76.8 m vs 81.4 m (5.6 %) | units walk rich_hollow_b2-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a1-guilds_lodge_a2 vs rich_den_b1-guilds_lodge_b2 | 141.7 m vs 133.7 m (5.6 %) | units walk rich_den_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a1-guilds_lodge_a2 vs rich_den_a2-guilds_lodge_a1 | 141.7 m vs 133.7 m (5.6 %) | units walk rich_den_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a2-guilds_lodge_a1 vs rich_den_b2-guilds_lodge_b1 | 133.7 m vs 141.7 m (5.6 %) | units walk rich_den_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_b1-guilds_lodge_b2 vs rich_den_b2-guilds_lodge_b1 | 133.7 m vs 141.7 m (5.6 %) | units walk rich_den_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-guilds_lodge_b1 vs rich_hollow_a2-guilds_lodge_b2 | 141.9 m vs 134.0 m (5.6 %) | units walk rich_hollow_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-guilds_lodge_b2 vs rich_hollow_b2-guilds_lodge_a2 | 134.0 m vs 141.9 m (5.6 %) | units walk rich_hollow_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-guilds_lodge_b1 vs rich_hollow_b1-guilds_lodge_a1 | 141.9 m vs 134.0 m (5.6 %) | units walk rich_hollow_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-guilds_lodge_a1 vs rich_hollow_b2-guilds_lodge_a2 | 134.0 m vs 141.9 m (5.6 %) | units walk rich_hollow_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-guilds_den_b2 vs inn_b2-guilds_den_a1 | 119.1 m vs 112.4 m (5.6 %) | units walk inn_a1-guilds_den_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-post_s_a2 vs rich_hollow_a2-post_s_a1 | 139.5 m vs 131.7 m (5.6 %) | units walk rich_hollow_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-post_s_b2 vs rich_hollow_b2-post_s_b1 | 131.8 m vs 139.6 m (5.6 %) | units walk rich_hollow_b2-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_lodge_b1 vs home_a_b1-guilds_lodge_a1 | 187.6 m vs 177.1 m (5.6 %) | units walk home_a_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a1-guilds_lodge_b1 vs rich_den_b1-guilds_lodge_a1 | 144.2 m vs 136.2 m (5.6 %) | units walk rich_den_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_one_b1 vs home_a_b1-lairs_one_a1 | 176.2 m vs 166.4 m (5.6 %) | units walk home_a_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_one_b1 vs home_a_a2-lairs_one_b2 | 176.2 m vs 166.4 m (5.6 %) | units walk home_a_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-post_s_a2 vs rich_hollow_b1-post_s_b2 | 139.5 m vs 131.8 m (5.5 %) | units walk rich_hollow_a1-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a1-guilds_lodge_b1 vs rich_den_a2-guilds_lodge_b2 | 144.2 m vs 136.2 m (5.5 %) | units walk rich_den_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_b1-guilds_lodge_a1 vs rich_den_b2-guilds_lodge_a2 | 136.2 m vs 144.1 m (5.5 %) | units walk rich_den_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-guilds_lodge_a1 vs rich_lodge_b1-guilds_lodge_b1 | 100.0 m vs 94.5 m (5.5 %) | units walk rich_lodge_a1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b2 vs home_b_b1-peddler_a2 | 135.3 m vs 127.9 m (5.5 %) | units walk home_b_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-peddler_b2 vs home_b_a2-peddler_b1 | 135.3 m vs 127.9 m (5.5 %) | units walk home_b_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_den_a2-guilds_lodge_b2 vs rich_den_b2-guilds_lodge_a2 | 136.2 m vs 144.1 m (5.5 %) | units walk rich_den_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-rich_lodge_b1 vs home_b_b2-rich_lodge_b2 | 76.9 m vs 72.7 m (5.5 %) | units walk home_b_b1-rich_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_lodge_a1 vs home_b_a2-rich_lodge_a2 | 72.9 m vs 77.1 m (5.5 %) | units walk home_b_a2-rich_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-guilds_den_b2 vs keep_t4-guilds_den_a2 | 180.4 m vs 190.8 m (5.5 %) | units walk keep_t4-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-wallow_a1 vs home_a_b2-wallow_a2 | 172.6 m vs 163.2 m (5.5 %) | units walk home_a_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-wallow_b1 vs home_a_b1-wallow_a1 | 163.2 m vs 172.6 m (5.5 %) | units walk home_a_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-cache_a_b2 vs guilds_lodge_b2-cache_a_a2 | 185.1 m vs 195.9 m (5.5 %) | units walk guilds_lodge_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-guilds_den_a1 vs keep_t4-guilds_den_a2 | 180.4 m vs 190.8 m (5.5 %) | units walk keep_t4-guilds_den_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_lodge_a2 vs keep_t4-rich_lodge_b2 | 84.6 m vs 80.0 m (5.4 %) | units walk keep_t3-rich_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_hollow_a2 vs keep_t4-rich_hollow_b2 | 78.9 m vs 74.7 m (5.4 %) | units walk keep_t3-rich_hollow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a2-guilds_lodge_a1 vs rich_hollow_b2-guilds_lodge_b1 | 140.3 m vs 148.4 m (5.4 %) | units walk rich_hollow_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-cache_a_a1 vs guilds_lodge_b2-cache_a_a2 | 185.2 m vs 195.9 m (5.4 %) | units walk guilds_lodge_b2-cache_a_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-rich_hollow_b1 vs keep_t4-rich_hollow_b2 | 78.9 m vs 74.7 m (5.4 %) | units walk keep_t1-rich_hollow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_hollow_a1 vs keep_t3-rich_hollow_a2 | 74.7 m vs 78.9 m (5.4 %) | units walk keep_t3-rich_hollow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_b1 vs guilds_lodge_a2-cache_a_b2 | 195.8 m vs 185.1 m (5.4 %) | units walk guilds_lodge_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_two_b2 vs peddler_b2-lairs_two_a1 | 136.0 m vs 128.7 m (5.4 %) | units walk peddler_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_hollow_a1 vs keep_t1-rich_hollow_b1 | 74.7 m vs 78.9 m (5.4 %) | units walk keep_t1-rich_hollow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-x_lane_e vs guilds_lodge_b2-x_lane_e | 101.3 m vs 95.8 m (5.4 %) | units walk guilds_lodge_b1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_w vs guilds_lodge_b1-x_lane_e | 95.8 m vs 101.3 m (5.4 %) | units walk guilds_lodge_b1-x_lane_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-x_lane_w vs guilds_lodge_a2-x_lane_w | 95.8 m vs 101.3 m (5.4 %) | units walk guilds_lodge_a2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-x_lane_w vs guilds_lodge_b2-x_lane_e | 101.3 m vs 95.8 m (5.4 %) | units walk guilds_lodge_a2-x_lane_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_two_b2 vs peddler_b1-lairs_two_a2 | 136.0 m vs 128.7 m (5.4 %) | units walk peddler_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-guilds_lodge_a2 vs rich_hollow_a2-guilds_lodge_a1 | 148.3 m vs 140.3 m (5.4 %) | units walk rich_hollow_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_b1-guilds_lodge_b2 vs rich_hollow_b2-guilds_lodge_b1 | 140.4 m vs 148.4 m (5.4 %) | units walk rich_hollow_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-lairs_two_b2 vs peddler_a2-lairs_two_b1 | 136.0 m vs 128.7 m (5.4 %) | units walk peddler_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-guilds_lodge_b2 vs keep_t4-guilds_lodge_a2 | 188.0 m vs 198.7 m (5.4 %) | units walk keep_t4-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-cache_a_b1 vs guilds_lodge_b1-cache_a_a1 | 195.8 m vs 185.2 m (5.4 %) | units walk guilds_lodge_a1-cache_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-home_b_b1 vs keep_t1-home_b_a2 | 141.5 m vs 133.9 m (5.4 %) | units walk keep_t3-home_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-wallow_a1 vs rich_hollow_a2-wallow_a2 | 84.6 m vs 89.4 m (5.4 %) | units walk rich_hollow_a2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-home_b_a2 vs keep_t4-home_b_a1 | 133.9 m vs 141.4 m (5.4 %) | units walk keep_t4-home_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-wallow_a1 vs rich_hollow_b1-wallow_b1 | 84.6 m vs 89.3 m (5.4 %) | units walk rich_hollow_b1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-guilds_lodge_a1 vs keep_t4-guilds_lodge_a2 | 188.1 m vs 198.7 m (5.3 %) | units walk keep_t4-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow_a1-guilds_lodge_a2 vs rich_hollow_b1-guilds_lodge_b2 | 148.3 m vs 140.4 m (5.3 %) | units walk rich_hollow_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-well_a1 vs home_b_b2-well_a2 | 134.0 m vs 141.5 m (5.3 %) | units walk home_b_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-crown vs tower_r_b1-crown | 76.6 m vs 80.9 m (5.3 %) | units walk tower_r_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-crown vs tower_r_a2-crown | 76.6 m vs 80.9 m (5.3 %) | units walk tower_r_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-crown vs tower_r_b2-crown | 80.9 m vs 76.6 m (5.3 %) | units walk tower_r_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-crown vs tower_r_b2-crown | 80.9 m vs 76.6 m (5.3 %) | units walk tower_r_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-guilds_lodge_b1 vs rich_lodge_b1-guilds_lodge_a1 | 150.2 m vs 142.2 m (5.3 %) | units walk rich_lodge_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a2-guilds_lodge_b2 vs rich_lodge_b2-guilds_lodge_a2 | 142.2 m vs 150.2 m (5.3 %) | units walk rich_lodge_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-guilds_lodge_b1 vs rich_lodge_a2-guilds_lodge_b2 | 150.2 m vs 142.2 m (5.3 %) | units walk rich_lodge_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_b1-guilds_lodge_a1 vs rich_lodge_b2-guilds_lodge_a2 | 142.2 m vs 150.2 m (5.3 %) | units walk rich_lodge_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-cache_b_b1 vs inn_b2-cache_b_a2 | 75.6 m vs 79.8 m (5.3 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-cache_b_a1 vs inn_b2-cache_b_a2 | 75.6 m vs 79.8 m (5.3 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-cache_b_b2 vs inn_b2-cache_b_a2 | 75.6 m vs 79.8 m (5.3 %) | units walk inn_b2-cache_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_c_a1-guilds_lodge_b2 vs tower_c_b2-guilds_lodge_a1 | 129.9 m vs 123.1 m (5.3 %) | units walk tower_c_a1-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-crown vs guilds_lodge_a2-crown | 106.7 m vs 112.6 m (5.2 %) | units walk guilds_lodge_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a2-crown vs guilds_lodge_b2-crown | 112.6 m vs 106.7 m (5.2 %) | units walk guilds_lodge_a2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_a1-crown vs guilds_lodge_b1-crown | 106.7 m vs 112.6 m (5.2 %) | units walk guilds_lodge_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | guilds_lodge_b1-crown vs guilds_lodge_b2-crown | 112.6 m vs 106.7 m (5.2 %) | units walk guilds_lodge_b1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-guilds_lodge_a2 vs rich_lodge_b1-guilds_lodge_b2 | 154.0 m vs 146.0 m (5.2 %) | units walk rich_lodge_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_w_b2 vs inn_a2-post_w_b1 | 118.0 m vs 111.9 m (5.2 %) | units walk inn_a1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a2-post_w_b1 vs inn_b2-post_w_a1 | 111.9 m vs 118.0 m (5.2 %) | units walk inn_b2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_b1-post_w_a2 vs inn_b2-post_w_a1 | 111.9 m vs 118.0 m (5.2 %) | units walk inn_b2-post_w_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | inn_a1-post_w_b2 vs inn_b1-post_w_a2 | 118.0 m vs 111.9 m (5.2 %) | units walk inn_a1-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-well_b1 vs home_b_b1-well_a1 | 141.4 m vs 134.0 m (5.2 %) | units walk home_b_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_s_b1 vs rich_node_b1-post_s_a1 | 150.6 m vs 142.8 m (5.2 %) | units walk rich_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a2-guilds_lodge_a2 vs home_a_b2-guilds_lodge_b2 | 51.5 m vs 54.3 m (5.2 %) | units walk home_a_b2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_lodge_a1 vs home_a_a2-guilds_lodge_a2 | 54.3 m vs 51.5 m (5.2 %) | units walk home_a_a1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_b1-guilds_lodge_b1 vs home_a_b2-guilds_lodge_b2 | 51.5 m vs 54.3 m (5.2 %) | units walk home_a_b2-guilds_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_lodge_a1 vs home_a_b1-guilds_lodge_b1 | 54.3 m vs 51.5 m (5.2 %) | units walk home_a_a1-guilds_lodge_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-rich_lodge_a1 vs home_b_b1-rich_lodge_b1 | 72.9 m vs 76.9 m (5.2 %) | units walk home_b_b1-rich_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-post_s_b1 vs rich_node_a2-post_s_b2 | 150.6 m vs 142.8 m (5.2 %) | units walk rich_node_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-post_s_a1 vs rich_node_b2-post_s_a2 | 142.8 m vs 150.6 m (5.2 %) | units walk rich_node_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_b1-guilds_lodge_b2 vs rich_lodge_b2-guilds_lodge_b1 | 146.0 m vs 153.9 m (5.2 %) | units walk rich_lodge_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a2-inn_b1 vs home_b_b2-inn_a1 | 97.1 m vs 92.0 m (5.2 %) | units walk home_b_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_b1-inn_a2 vs home_b_b2-inn_a1 | 97.1 m vs 92.0 m (5.2 %) | units walk home_b_b1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-rich_lodge_b1 vs keep_t4-rich_lodge_b2 | 84.4 m vs 80.0 m (5.2 %) | units walk keep_t1-rich_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_lodge_a1 vs keep_t3-rich_lodge_a2 | 80.2 m vs 84.6 m (5.2 %) | units walk keep_t3-rich_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-inn_b2 vs home_b_a2-inn_b1 | 92.1 m vs 97.1 m (5.2 %) | units walk home_b_a2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-rich_lodge_b1 vs stag_a2-rich_lodge_b2 | 129.0 m vs 136.0 m (5.2 %) | units walk stag_a2-rich_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-rich_lodge_b2 vs stag_b2-rich_lodge_a2 | 136.0 m vs 129.0 m (5.2 %) | units walk stag_a2-rich_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_b_a1-inn_b2 vs home_b_b1-inn_a2 | 92.1 m vs 97.1 m (5.2 %) | units walk home_b_b1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-guilds_lodge_b1 vs home_a_a2-guilds_lodge_b2 | 187.6 m vs 177.9 m (5.2 %) | units walk home_a_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a1-guilds_lodge_a2 vs rich_lodge_a2-guilds_lodge_a1 | 154.0 m vs 146.1 m (5.2 %) | units walk rich_lodge_a1-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a2-post_s_b2 vs rich_node_b2-post_s_a2 | 142.8 m vs 150.6 m (5.1 %) | units walk rich_node_b2-post_s_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-cache_b_a1 vs stag_b2-cache_b_b1 | 109.7 m vs 104.1 m (5.1 %) | units walk stag_a2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-cache_b_b2 vs stag_b2-cache_b_b1 | 109.7 m vs 104.1 m (5.1 %) | units walk stag_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-cache_b_a2 vs stag_a2-cache_b_a1 | 104.1 m vs 109.7 m (5.1 %) | units walk stag_a2-cache_b_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-cache_b_a2 vs stag_b1-cache_b_b2 | 104.1 m vs 109.7 m (5.1 %) | units walk stag_b1-cache_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_one_b1 vs wallow_a2-lairs_one_b2 | 198.1 m vs 188.0 m (5.1 %) | units walk wallow_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-lairs_one_b1 vs wallow_b1-lairs_one_a1 | 198.1 m vs 188.0 m (5.1 %) | units walk wallow_a1-lairs_one_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-inn_a2 vs tower_r_b1-inn_b2 | 97.4 m vs 92.4 m (5.1 %) | units walk tower_r_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_b1-inn_b2 vs tower_r_b2-inn_b1 | 92.4 m vs 97.4 m (5.1 %) | units walk tower_r_b2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_lodge_a2-guilds_lodge_a1 vs rich_lodge_b2-guilds_lodge_b1 | 146.1 m vs 153.9 m (5.1 %) | units walk rich_lodge_b2-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-ford_nest_a2 vs well_b1-ford_nest_a1 | 91.8 m vs 96.7 m (5.1 %) | units walk well_b1-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_ford_n vs well_b1-x_ford_s | 91.8 m vs 96.7 m (5.1 %) | units walk well_b1-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a1-inn_a2 vs tower_r_a2-inn_a1 | 97.4 m vs 92.4 m (5.1 %) | units walk tower_r_a1-inn_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_r_a2-inn_a1 vs tower_r_b2-inn_b1 | 92.4 m vs 97.4 m (5.1 %) | units walk tower_r_b2-inn_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_b2 vs home_a_b2-lairs_two_a1 | 142.8 m vs 135.6 m (5.1 %) | units walk home_a_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a2-rich_lodge_b2 vs post_s_b2-rich_lodge_a2 | 138.9 m vs 131.9 m (5.1 %) | units walk post_s_a2-rich_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_s_a1-rich_lodge_b1 vs post_s_a2-rich_lodge_b2 | 131.9 m vs 138.9 m (5.1 %) | units walk post_s_a2-rich_lodge_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node_a1-well_b1 vs nat_node_b2-well_a2 | 109.8 m vs 104.3 m (5.0 %) | units walk nat_node_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_b2 vs home_a_b1-lairs_two_a2 | 142.8 m vs 135.6 m (5.0 %) | units walk home_a_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-post_w_b2 vs keep_t4-post_w_a2 | 164.1 m vs 155.9 m (5.0 %) | units walk keep_t3-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-post_w_b1 vs keep_t3-post_w_b2 | 155.9 m vs 164.1 m (5.0 %) | units walk keep_t3-post_w_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a_a1-lairs_two_b2 vs home_a_a2-lairs_two_b1 | 142.8 m vs 135.6 m (5.0 %) | units walk home_a_a1-lairs_two_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_b1-lairs_one_a2 vs cache_a_b2-lairs_one_a1 | 108.2 m vs 113.9 m (5.0 %) | units walk cache_a_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_b2 vs cache_a_b1-lairs_one_a2 | 113.9 m vs 108.2 m (5.0 %) | units walk cache_a_a1-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-post_s_b1 vs ford_nest_a2-post_s_a1 | 130.2 m vs 123.7 m (5.0 %) | units walk ford_nest_a1-post_s_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a1-lairs_one_b2 vs cache_a_a2-lairs_one_b1 | 113.9 m vs 108.2 m (5.0 %) | units walk cache_a_a1-lairs_one_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a_a2-lairs_one_b1 vs cache_a_b2-lairs_one_a1 | 108.2 m vs 113.9 m (5.0 %) | units walk cache_a_b2-lairs_one_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-lairs_two_a2 vs ford_nest_a2-lairs_two_a1 | 125.8 m vs 119.5 m (5.0 %) | units walk ford_nest_a1-lairs_two_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-x_ford_n vs well_a2-x_ford_s | 91.8 m vs 96.7 m (5.0 %) | units walk well_a2-x_ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-ford_nest_a2 vs well_a2-ford_nest_a1 | 91.8 m vs 96.7 m (5.0 %) | units walk well_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-guilds_lodge_b1 vs rich_node_b1-guilds_lodge_a1 | 159.4 m vs 151.4 m (5.0 %) | units walk rich_node_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_a1-guilds_lodge_b1 vs rich_node_a2-guilds_lodge_b2 | 159.4 m vs 151.4 m (5.0 %) | units walk rich_node_a1-guilds_lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node_b1-guilds_lodge_a1 vs rich_node_b2-guilds_lodge_a2 | 151.4 m vs 159.4 m (5.0 %) | units walk rich_node_b2-guilds_lodge_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest camp | 11.9 m vs 13.0 m between seats (8.4 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | D1 | nearest enemy keep | 136.2 m vs 148.9 m between seats (8.5 %) | move the far seat's spot closer (or check its route for a blocker) |
| WARN | A1 | A1 south-west | ally / nearest enemy 0.57 outside 0.33-0.50 (ally 77.4 m, enemy 136.2 m = 1.8x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | A1 | A2 north-west | ally / nearest enemy 0.52 outside 0.33-0.50 (ally 77.4 m, enemy 148.9 m = 1.9x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | A1 | B1 north-east | ally / nearest enemy 0.52 outside 0.33-0.50 (ally 77.4 m, enemy 148.9 m = 1.9x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | A1 | B2 south-east | ally / nearest enemy 0.57 outside 0.33-0.50 (ally 77.4 m, enemy 136.2 m = 1.8x) | aim the enemy 2-3x farther than the ally (map-2v2-audit.md 6): move the keeps toward / away from the ally |
| WARN | T1 | enemy keep (nearest) (caravan) | 0:34 vs 0:37 between seats | one seat's route is longer or crosses more ford: see the travel-time table |
| WARN | T1 | enemy keep #2 (worker) | 0:34 vs 0:38 between seats | one seat's route is longer or crosses more ford: see the travel-time table |
| WARN | R1 | A1 south-west ally | ally 77.4 outside 60-72 (7 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| WARN | R1 | A2 north-west ally | ally 77.4 outside 60-72 (7 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| WARN | R1 | B1 north-east ally | ally 77.4 outside 60-72 (7 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| WARN | R1 | B2 south-east ally | ally 77.4 outside 60-72 (7 %) | a designer moves the keeps or the river (R1 ally is not auto-fixed) |
| WARN | R4 | rich_den_a1 | guild 3.7 m from crossing x_ford_s (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | rich_den_a2 | guild 3.7 m from crossing x_ford_n (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | rich_den_b1 | guild 3.7 m from crossing x_ford_n (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | rich_den_b2 | guild 3.7 m from crossing x_ford_s (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | rich_hollow_a1 | camp 7.9 m from crossing x_ford_s (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | rich_hollow_a2 | camp 7.9 m from crossing x_ford_n (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | rich_hollow_b1 | camp 7.9 m from crossing x_ford_n (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | rich_hollow_b2 | camp 7.9 m from crossing x_ford_s (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | stag_a1 | camp 7.7 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | stag_a2 | camp 7.7 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | stag_b1 | camp 7.7 m from a road centre line (want >= 9) | push it off the road (auto-fix) |
| WARN | R4 | stag_b2 | camp 7.7 m from a road centre line (want >= 9) | push it off the road (auto-fix) |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-68.2, 31.4) | (-67.9, 35.1) | keep_t4 | (-67.9, 35.1) | 0.0 |
| keep_t3 | keep | (-68.2, -31.4) | (-67.9, -35.1) | keep_t1 | (-67.9, -35.1) | 0.0 |
| keep_t1 | keep | (68.2, -31.4) | (67.9, -35.1) | keep_t3 | (67.9, -35.1) | 0.0 |
| keep_t4 | keep | (68.2, 31.4) | (67.9, 35.1) | keep_t0 | (67.9, 35.1) | 0.0 |
| home_a_a1 | home_node | (-67.9, 21.9) | (-67.9, 21.9) | home_a_b2 | (-67.9, 21.9) | 0.0 |
| home_a_a2 | home_node | (-67.9, -21.9) | (-67.9, -21.9) | home_a_b1 | (-67.9, -21.9) | 0.0 |
| home_a_b1 | home_node | (67.9, -21.9) | (67.9, -21.9) | home_a_a2 | (67.9, -21.9) | 0.0 |
| home_a_b2 | home_node | (67.9, 21.9) | (67.9, 21.9) | home_a_a1 | (67.9, 21.9) | 0.0 |
| home_b_a1 | home_node | (-60.8, 37.3) | (-60.6, 37.4) | home_b_b2 | (-60.6, 37.4) | 0.0 |
| home_b_a2 | home_node | (-60.8, -37.3) | (-60.6, -37.4) | home_b_b1 | (-60.6, -37.4) | 0.0 |
| home_b_b1 | home_node | (60.8, -37.3) | (60.6, -37.4) | home_b_a2 | (60.6, -37.4) | 0.0 |
| home_b_b2 | home_node | (60.8, 37.3) | (60.6, 37.4) | home_b_a1 | (60.6, 37.4) | 0.0 |
| nat_node_a1 | expansion | (-35.7, 18.3) | (-35.6, 18.1) | nat_node_b2 | (-35.6, 18.1) | 0.0 |
| nat_node_a2 | expansion | (-35.7, -18.3) | (-35.6, -18.1) | nat_node_b1 | (-35.6, -18.1) | 0.0 |
| nat_node_b1 | expansion | (35.7, -18.3) | (35.6, -18.1) | nat_node_a2 | (35.6, -18.1) | 0.0 |
| nat_node_b2 | expansion | (35.7, 18.3) | (35.6, 18.1) | nat_node_a1 | (35.6, 18.1) | 0.0 |
| rich_node_a1 | expansion | (-12.7, 50.4) | (-12.6, 50.4) | rich_node_b2 | (-12.6, 50.4) | 0.0 |
| rich_node_a2 | expansion | (-12.7, -50.4) | (-12.6, -50.4) | rich_node_b1 | (-12.6, -50.4) | 0.0 |
| rich_node_b1 | expansion | (12.7, -50.4) | (12.6, -50.4) | rich_node_a2 | (12.6, -50.4) | 0.0 |
| rich_node_b2 | expansion | (12.7, 50.4) | (12.6, 50.4) | rich_node_a1 | (12.6, 50.4) | 0.0 |
| third_node_a1 | expansion | (-71.1, 65.5) | (-71.1, 65.4) | third_node_b2 | (-71.1, 65.4) | 0.0 |
| third_node_a2 | expansion | (-71.1, -65.5) | (-71.1, -65.4) | third_node_b1 | (-71.1, -65.4) | 0.0 |
| third_node_b1 | expansion | (71.1, -65.5) | (71.1, -65.4) | third_node_a2 | (71.1, -65.4) | 0.0 |
| third_node_b2 | expansion | (71.1, 65.5) | (71.1, 65.4) | third_node_a1 | (71.1, 65.4) | 0.0 |
| tower_r_a1 | point | (-17.7, 65.0) | (-17.6, 64.9) | tower_r_b2 | (-17.6, 64.9) | 0.0 |
| tower_r_a2 | point | (-17.7, -65.0) | (-17.6, -64.9) | tower_r_b1 | (-17.6, -64.9) | 0.0 |
| tower_r_b1 | point | (17.7, -65.0) | (17.6, -64.9) | tower_r_a2 | (17.6, -64.9) | 0.0 |
| tower_r_b2 | point | (17.7, 65.0) | (17.6, 64.9) | tower_r_a1 | (17.6, 64.9) | 0.0 |
| tower_c_a1 | point | (-19.7, 8.3) | (-19.6, 8.1) | tower_c_b2 | (-19.6, 8.1) | 0.0 |
| tower_c_a2 | point | (-19.7, -8.3) | (-19.6, -8.1) | tower_c_b1 | (-19.6, -8.1) | 0.0 |
| tower_c_b1 | point | (19.7, -8.3) | (19.6, -8.1) | tower_c_a2 | (19.6, -8.1) | 0.0 |
| tower_c_b2 | point | (19.7, 8.3) | (19.6, 8.1) | tower_c_a1 | (19.6, 8.1) | 0.0 |
| well_a1 | point | (-37.2, 47.8) | (-37.1, 47.6) | well_b2 | (-37.1, 47.6) | 0.0 |
| well_a2 | point | (-37.2, -47.8) | (-37.1, -47.6) | well_b1 | (-37.1, -47.6) | 0.0 |
| well_b1 | point | (37.2, -47.8) | (37.1, -47.6) | well_a2 | (37.1, -47.6) | 0.0 |
| well_b2 | point | (37.2, 47.8) | (37.1, 47.6) | well_a1 | (37.1, 47.6) | 0.0 |
| shrine_a1 | point | (-51.1, 8.5) | (-51.1, 8.4) | shrine_b2 | (-51.1, 8.4) | 0.0 |
| shrine_a2 | point | (-51.1, -8.5) | (-51.1, -8.4) | shrine_b1 | (-51.1, -8.4) | 0.0 |
| shrine_b1 | point | (51.1, -8.5) | (51.1, -8.4) | shrine_a2 | (51.1, -8.4) | 0.0 |
| shrine_b2 | point | (51.1, 8.5) | (51.1, 8.4) | shrine_a1 | (51.1, 8.4) | 0.0 |
| rich_hollow_a1 | camp | (6.3, 41.1) | (6.4, 40.9) | rich_hollow_b2 | (6.4, 40.9) | 0.0 |
| rich_hollow_a2 | camp | (6.3, -41.1) | (6.4, -40.9) | rich_hollow_b1 | (6.4, -40.9) | 0.0 |
| rich_hollow_b1 | camp | (-6.3, -41.1) | (-6.4, -40.9) | rich_hollow_a2 | (-6.4, -40.9) | 0.0 |
| rich_hollow_b2 | camp | (-6.3, 41.1) | (-6.4, 40.9) | rich_hollow_a1 | (-6.4, 40.9) | 0.0 |
| wallow_a1 | camp | (-78.0, 41.4) | (-77.9, 41.4) | wallow_b2 | (-77.9, 41.4) | 0.0 |
| wallow_a2 | camp | (-78.0, -41.4) | (-77.9, -41.4) | wallow_b1 | (-77.9, -41.4) | 0.0 |
| wallow_b1 | camp | (78.0, -41.4) | (77.9, -41.4) | wallow_a2 | (77.9, -41.4) | 0.0 |
| wallow_b2 | camp | (78.0, 41.4) | (77.9, 41.4) | wallow_a1 | (77.9, 41.4) | 0.0 |
| ford_nest_a1 | camp | (0.0, 36.3) | (-0.1, 36.1) | ford_nest_a1 | (0.1, 36.1) | 0.3 |
| ford_nest_a2 | camp | (0.0, -36.3) | (-0.1, -36.1) | ford_nest_a2 | (0.1, -36.1) | 0.3 |
| stag_a1 | camp | (-37.7, 73.8) | (-37.6, 73.6) | stag_b2 | (-37.6, 73.6) | 0.0 |
| stag_a2 | camp | (-37.7, -73.8) | (-37.6, -73.6) | stag_b1 | (-37.6, -73.6) | 0.0 |
| stag_b1 | camp | (37.7, -73.8) | (37.6, -73.6) | stag_a2 | (37.6, -73.6) | 0.0 |
| stag_b2 | camp | (37.7, 73.8) | (37.6, 73.6) | stag_a1 | (37.6, 73.6) | 0.0 |
| inn_a1 | tavern | (-29.2, 24.1) | (-29.1, 23.9) | inn_b2 | (-29.1, 23.9) | 0.0 |
| inn_a2 | tavern | (-29.2, -24.1) | (-29.1, -23.9) | inn_b1 | (-29.1, -23.9) | 0.0 |
| inn_b1 | tavern | (29.2, -24.1) | (29.1, -23.9) | inn_a2 | (29.1, -23.9) | 0.0 |
| inn_b2 | tavern | (29.2, 24.1) | (29.1, 23.9) | inn_a1 | (29.1, 23.9) | 0.0 |
| post_w_a1 | post | (-78.0, 11.7) | (-77.9, 11.6) | post_w_b2 | (-77.9, 11.6) | 0.0 |
| post_w_a2 | post | (-78.0, -11.7) | (-77.9, -11.6) | post_w_b1 | (-77.9, -11.6) | 0.0 |
| post_w_b1 | post | (78.0, -11.7) | (77.9, -11.6) | post_w_a2 | (77.9, -11.6) | 0.0 |
| post_w_b2 | post | (78.0, 11.7) | (77.9, 11.6) | post_w_a1 | (77.9, 11.6) | 0.0 |
| post_s_a1 | post | (-44.1, 76.6) | (-44.1, 76.4) | post_s_b2 | (-44.1, 76.4) | 0.0 |
| post_s_a2 | post | (-44.1, -76.6) | (-44.1, -76.4) | post_s_b1 | (-44.1, -76.4) | 0.0 |
| post_s_b1 | post | (44.1, -76.6) | (44.1, -76.4) | post_s_a2 | (44.1, -76.4) | 0.0 |
| post_s_b2 | post | (44.1, 76.6) | (44.1, 76.4) | post_s_a1 | (44.1, 76.4) | 0.0 |
| rich_den_a1 | guild | (-2.5, 39.1) | (-2.4, 39.1) | rich_den_b2 | (-2.4, 39.1) | 0.0 |
| rich_den_a2 | guild | (-2.5, -39.1) | (-2.4, -39.1) | rich_den_b1 | (-2.4, -39.1) | 0.0 |
| rich_den_b1 | guild | (2.5, -39.1) | (2.4, -39.1) | rich_den_a2 | (2.4, -39.1) | 0.0 |
| rich_den_b2 | guild | (2.5, 39.1) | (2.4, 39.1) | rich_den_a1 | (2.4, 39.1) | 0.0 |
| rich_lodge_a1 | guild | (2.5, 49.3) | (3.4, 48.6) | rich_lodge_b2 | (3.4, 48.6) | 0.0 |
| rich_lodge_a2 | guild | (2.5, -49.3) | (3.4, -48.6) | rich_lodge_b1 | (3.4, -48.6) | 0.0 |
| rich_lodge_b1 | guild | (-2.5, -49.3) | (-3.4, -48.6) | rich_lodge_a2 | (-3.4, -48.6) | 0.0 |
| rich_lodge_b2 | guild | (-2.5, 49.3) | (-3.4, 48.6) | rich_lodge_a1 | (-3.4, 48.6) | 0.0 |
| guilds_den_a1 | guild | (-68.4, 79.7) | (-68.4, 79.6) | guilds_den_b2 | (-68.4, 79.6) | 0.0 |
| guilds_den_a2 | guild | (-68.4, -79.7) | (-68.4, -79.6) | guilds_den_b1 | (-68.4, -79.6) | 0.0 |
| guilds_den_b1 | guild | (68.4, -79.7) | (68.4, -79.6) | guilds_den_a2 | (68.4, -79.6) | 0.0 |
| guilds_den_b2 | guild | (68.4, 79.7) | (68.4, 79.6) | guilds_den_a1 | (68.4, 79.6) | 0.0 |
| guilds_lodge_a1 | guild | (-77.0, 71.3) | (-76.9, 71.4) | guilds_lodge_b2 | (-76.9, 71.4) | 0.0 |
| guilds_lodge_a2 | guild | (-77.0, -71.3) | (-76.9, -71.4) | guilds_lodge_b1 | (-76.9, -71.4) | 0.0 |
| guilds_lodge_b1 | guild | (77.0, -71.3) | (76.9, -71.4) | guilds_lodge_a2 | (76.9, -71.4) | 0.0 |
| guilds_lodge_b2 | guild | (77.0, 71.3) | (76.9, 71.4) | guilds_lodge_a1 | (76.9, 71.4) | 0.0 |
| peddler_a1 | peddler | (-60.5, 20.5) | (-60.4, 20.4) | peddler_b2 | (-60.4, 20.4) | 0.0 |
| peddler_a2 | peddler | (-60.5, -20.5) | (-60.4, -20.4) | peddler_b1 | (-60.4, -20.4) | 0.0 |
| peddler_b1 | peddler | (60.5, -20.5) | (60.4, -20.4) | peddler_a2 | (60.4, -20.4) | 0.0 |
| peddler_b2 | peddler | (60.5, 20.5) | (60.4, 20.4) | peddler_a1 | (60.4, 20.4) | 0.0 |
| cache_a_a1 | cache | (-44.8, 63.5) | (-44.6, 63.4) | cache_a_b2 | (-44.6, 63.4) | 0.0 |
| cache_a_a2 | cache | (-44.8, -63.5) | (-44.6, -63.4) | cache_a_b1 | (-44.6, -63.4) | 0.0 |
| cache_a_b1 | cache | (44.8, -63.5) | (44.6, -63.4) | cache_a_a2 | (44.6, -63.4) | 0.0 |
| cache_a_b2 | cache | (44.8, 63.5) | (44.6, 63.4) | cache_a_a1 | (44.6, 63.4) | 0.0 |
| cache_b_a1 | cache | (-8.1, 23.9) | (-7.9, 23.9) | cache_b_b2 | (-7.9, 23.9) | 0.0 |
| cache_b_a2 | cache | (-8.1, -23.9) | (-7.9, -23.9) | cache_b_b1 | (-7.9, -23.9) | 0.0 |
| cache_b_b1 | cache | (8.1, -23.9) | (7.9, -23.9) | cache_b_a2 | (7.9, -23.9) | 0.0 |
| cache_b_b2 | cache | (8.1, 23.9) | (7.9, 23.9) | cache_b_a1 | (7.9, 23.9) | 0.0 |
| lairs_one_a1 | lair | (-58.7, 85.9) | (-57.9, 83.9) | lairs_one_b2 | (-57.9, 83.9) | 0.0 |
| lairs_one_a2 | lair | (-58.7, -85.9) | (-57.9, -83.9) | lairs_one_b1 | (-57.9, -83.9) | 0.0 |
| lairs_one_b1 | lair | (58.7, -85.9) | (57.9, -83.9) | lairs_one_a2 | (57.9, -83.9) | 0.0 |
| lairs_one_b2 | lair | (58.7, 85.9) | (57.9, 83.9) | lairs_one_a1 | (57.9, 83.9) | 0.0 |
| lairs_two_a1 | lair | (-58.7, 67.9) | (-58.6, 67.9) | lairs_two_b2 | (-58.6, 67.9) | 0.0 |
| lairs_two_a2 | lair | (-58.7, -67.9) | (-58.6, -67.9) | lairs_two_b1 | (-58.6, -67.9) | 0.0 |
| lairs_two_b1 | lair | (58.7, -67.9) | (58.6, -67.9) | lairs_two_a2 | (58.6, -67.9) | 0.0 |
| lairs_two_b2 | lair | (58.7, 67.9) | (58.6, 67.9) | lairs_two_a1 | (58.6, 67.9) | 0.0 |
| x_bridge_n | crossing_bridge_road | (0.0, -63.4) | (0.1, -63.4) | x_bridge_n | (-0.1, -63.4) | 0.3 |
| x_bridge_s | crossing_bridge_road | (0.0, 63.4) | (0.1, 63.4) | x_bridge_s | (-0.1, 63.4) | 0.3 |
| x_ford_n | crossing_ford | (0.0, -36.3) | (-0.1, -36.1) | x_ford_n | (0.1, -36.1) | 0.3 |
| x_ford_s | crossing_ford | (0.0, 36.3) | (-0.1, 36.1) | x_ford_s | (0.1, 36.1) | 0.3 |
| x_lane_w | crossing_bridge_lane | (-13.0, 0.0) | (-12.9, 0.1) | x_lane_e | (-12.9, 0.1) | 0.0 |
| x_lane_e | crossing_bridge_lane | (13.0, 0.0) | (12.9, 0.1) | x_lane_w | (12.9, 0.1) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F1 map geometry: most asymmetric pairs (top 1 of 1)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | tower_r_a1 - tower_r_b2 | 36.7 | tower_r_a2 - tower_r_b1 | 35.9 | +2.3 % |


## F2 unit paths: most asymmetric pairs (top 20 of 1692)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | well_a2 - post_w_a1 | 83.8 | well_b2 - post_w_b1 | 71.9 | +14.1 % |
| 2 | well_a1 - post_w_a2 | 71.9 | well_a2 - post_w_a1 | 83.8 | -14.1 % |
| 3 | well_b1 - post_w_b2 | 83.8 | well_b2 - post_w_b1 | 71.9 | +14.1 % |
| 4 | well_a1 - post_w_a2 | 71.9 | well_b1 - post_w_b2 | 83.8 | -14.1 % |
| 5 | well_a1 - wallow_a2 | 97.9 | well_b1 - wallow_b2 | 113.3 | -13.6 % |
| 6 | well_a1 - wallow_a2 | 97.9 | well_a2 - wallow_a1 | 113.3 | -13.6 % |
| 7 | well_b1 - wallow_b2 | 113.3 | well_b2 - wallow_b1 | 97.9 | +13.6 % |
| 8 | well_a2 - wallow_a1 | 113.3 | well_b2 - wallow_b1 | 97.9 | +13.6 % |
| 9 | shrine_a1 - wallow_b1 | 167.6 | shrine_a2 - wallow_b2 | 145.2 | +13.4 % |
| 10 | well_b1 - guilds_lodge_b2 | 146.5 | well_b2 - guilds_lodge_b1 | 127.4 | +13.0 % |
| 11 | well_a1 - guilds_lodge_a2 | 127.4 | well_b1 - guilds_lodge_b2 | 146.5 | -13.0 % |
| 12 | well_a1 - guilds_lodge_a2 | 127.4 | well_a2 - guilds_lodge_a1 | 146.5 | -13.0 % |
| 13 | well_a2 - guilds_lodge_a1 | 146.5 | well_b2 - guilds_lodge_b1 | 127.4 | +13.0 % |
| 14 | wallow_a2 - stag_a2 | 59.3 | wallow_b2 - stag_b2 | 52.1 | +12.2 % |
| 15 | wallow_b1 - stag_b1 | 59.3 | wallow_b2 - stag_b2 | 52.1 | +12.2 % |
| 16 | wallow_a1 - stag_a1 | 52.1 | wallow_a2 - stag_a2 | 59.3 | -12.2 % |
| 17 | wallow_a1 - stag_a1 | 52.1 | wallow_b1 - stag_b1 | 59.3 | -12.2 % |
| 18 | rich_node_a1 - well_b2 | 56.6 | rich_node_b1 - well_a2 | 63.6 | -11.0 % |
| 19 | rich_node_a1 - well_b2 | 56.6 | rich_node_a2 - well_b1 | 63.6 | -11.0 % |
| 20 | rich_node_b1 - well_a2 | 63.6 | rich_node_b2 - well_a1 | 56.6 | +10.9 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 south-west | 30.4 (third_node_a1) | 32.9 (shrine_a1) | 11.9 (wallow_a1) | 35.0 (lairs_two_a1) | 40.4 (inn_a1) | 27.8 (post_w_a1) | 18.3 (peddler_a1) | 36.6 (cache_a_a1) | 77.0 (crown) | 136.2 |
| A2 north-west | 30.4 (third_node_a2) | 33.1 (shrine_a2) | 13.0 (wallow_a2) | 35.0 (lairs_two_a2) | 40.5 (inn_a2) | 27.9 (post_w_a2) | 18.4 (peddler_a2) | 36.6 (cache_a_a2) | 77.1 (crown) | 148.9 |
| B1 north-east | 30.4 (third_node_b1) | 33.1 (shrine_b1) | 13.0 (wallow_b1) | 35.0 (lairs_two_b1) | 40.5 (inn_b1) | 27.9 (post_w_b1) | 18.4 (peddler_b1) | 36.6 (cache_a_b1) | 77.1 (crown) | 148.9 |
| B2 south-east | 30.4 (third_node_b2) | 32.9 (shrine_b2) | 11.9 (wallow_b2) | 35.0 (lairs_two_b2) | 40.4 (inn_b2) | 27.8 (post_w_b2) | 18.3 (peddler_b2) | 36.6 (cache_a_b2) | 77.0 (crown) | 136.2 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| home_b_a1 | home_node | 7.6 | home_b_b2 | 7.6 | +0.0 % |
| wallow_a1 | camp | 11.9 | wallow_b2 | 11.9 | +0.0 % |
| home_a_a1 | home_node | 17.8 | home_a_b2 | 17.8 | -0.0 % |
| peddler_a1 | peddler | 18.3 | peddler_b2 | 18.3 | +0.0 % |
| post_w_a1 | post | 27.8 | post_w_b2 | 27.8 | -0.0 % |
| third_node_a1 | expansion | 30.4 | third_node_b2 | 30.4 | +0.0 % |
| shrine_a1 | point | 32.9 | shrine_b2 | 32.9 | +0.0 % |
| well_a1 | point | 33.2 | well_b2 | 33.2 | +0.0 % |
| lairs_two_a1 | lair | 35.0 | lairs_two_b2 | 35.0 | +0.0 % |
| cache_a_a1 | cache | 36.6 | cache_a_b2 | 36.6 | +0.0 % |
| nat_node_a1 | expansion | 36.7 | nat_node_b2 | 36.7 | -0.0 % |
| inn_a1 | tavern | 40.4 | inn_b2 | 40.4 | +0.0 % |
| guilds_lodge_a1 | guild | 40.8 | guilds_lodge_b2 | 40.8 | +0.0 % |
| guilds_den_a1 | guild | 45.5 | guilds_den_b2 | 45.5 | +0.0 % |
| post_s_a1 | post | 47.6 | post_s_b2 | 47.6 | +0.0 % |
| shrine_a2 | point | 48.5 | shrine_b1 | 48.5 | +0.0 % |
| stag_a1 | camp | 49.0 | stag_b2 | 49.0 | -0.0 % |
| lairs_one_a1 | lair | 50.5 | lairs_one_b2 | 50.5 | +0.0 % |
| post_w_a2 | post | 50.7 | post_w_b1 | 50.7 | +0.0 % |
| tower_c_a1 | point | 55.6 | tower_c_b2 | 55.6 | +0.0 % |
| rich_node_a1 | expansion | 57.3 | rich_node_b2 | 57.3 | +0.0 % |
| peddler_a2 | peddler | 58.6 | peddler_b1 | 58.6 | +0.0 % |
| tower_r_a1 | point | 58.7 | tower_r_b2 | 58.7 | +0.0 % |
| home_a_a2 | home_node | 60.0 | home_a_b1 | 60.0 | +0.0 % |
| cache_b_a1 | cache | 61.1 | cache_b_b2 | 61.1 | +0.0 % |
| rich_hollow_b2 | camp | 61.8 | rich_hollow_a1 | 61.8 | -0.0 % |
| nat_node_a2 | expansion | 63.6 | nat_node_b1 | 63.6 | +0.0 % |
| tower_c_a2 | point | 65.4 | tower_c_b1 | 65.4 | +0.0 % |
| x_lane_w | crossing_bridge_lane | 65.6 | x_lane_e | 65.6 | +0.0 % |
| rich_den_a1 | guild | 65.6 | rich_den_b2 | 65.6 | +0.0 % |
| rich_lodge_b2 | guild | 66.3 | rich_lodge_a1 | 66.3 | +0.0 % |
| x_ford_s | crossing_ford | 67.9 | x_ford_s | 67.9 | +0.0 % |
| ford_nest_a1 | camp | 67.9 | ford_nest_a1 | 67.9 | +0.0 % |
| rich_den_b2 | guild | 70.4 | rich_den_a1 | 70.4 | +0.0 % |
| inn_a2 | tavern | 71.8 | inn_b1 | 71.8 | +0.0 % |
| x_bridge_s | crossing_bridge_road | 73.4 | x_bridge_s | 73.4 | -0.0 % |
| rich_hollow_a1 | camp | 74.7 | rich_hollow_b2 | 74.7 | +0.0 % |
| home_b_a2 | home_node | 75.5 | home_b_b1 | 75.5 | -0.0 % |
| crown | crown | 77.0 | crown | 77.0 | +0.0 % |
| keep_t3 | keep | 77.4 | keep_t1 | 77.4 | +0.0 % |
| rich_lodge_a1 | guild | 80.2 | rich_lodge_b2 | 80.0 | +0.3 % |
| wallow_a2 | camp | 80.3 | wallow_b1 | 80.3 | +0.0 % |
| cache_b_b2 | cache | 82.4 | cache_b_a1 | 82.3 | +0.2 % |
| cache_b_a2 | cache | 86.2 | cache_b_b1 | 86.2 | +0.0 % |
| rich_node_b2 | expansion | 89.8 | rich_node_a1 | 89.8 | +0.1 % |
| x_lane_e | crossing_bridge_lane | 89.9 | x_lane_w | 89.9 | +0.0 % |
| well_a2 | point | 90.1 | well_b1 | 90.1 | +0.0 % |
| tower_r_b2 | point | 91.3 | tower_r_a1 | 91.3 | -0.0 % |
| tower_c_b2 | point | 98.3 | tower_c_a1 | 98.3 | +0.0 % |
| tower_c_b1 | point | 98.7 | tower_c_a2 | 98.7 | +0.0 % |
| inn_b2 | tavern | 99.4 | inn_a1 | 99.4 | +0.0 % |
| rich_hollow_b1 | camp | 100.1 | rich_hollow_a2 | 100.1 | +0.0 % |
| ford_nest_a2 | camp | 100.8 | ford_nest_a2 | 100.9 | -0.1 % |
| x_ford_n | crossing_ford | 100.8 | x_ford_n | 100.9 | -0.1 % |
| rich_den_a2 | guild | 102.4 | rich_den_b1 | 102.4 | +0.0 % |
| rich_node_a2 | expansion | 103.0 | rich_node_b1 | 103.0 | +0.0 % |
| third_node_a2 | expansion | 104.6 | third_node_b1 | 104.6 | +0.0 % |
| rich_den_b1 | guild | 104.7 | rich_den_a2 | 104.8 | -0.1 % |
| cache_a_a2 | cache | 104.9 | cache_a_b1 | 104.9 | +0.0 % |
| lairs_two_a2 | lair | 106.1 | lairs_two_b1 | 106.1 | -0.0 % |
| rich_lodge_b1 | guild | 107.0 | rich_lodge_a2 | 107.0 | +0.0 % |
| nat_node_b2 | expansion | 107.6 | nat_node_a1 | 107.6 | +0.0 % |
| rich_hollow_a2 | camp | 108.9 | rich_hollow_b1 | 108.9 | -0.1 % |
| guilds_lodge_a2 | guild | 110.1 | guilds_lodge_b1 | 110.1 | +0.0 % |
| well_b2 | point | 112.3 | well_a1 | 112.3 | -0.0 % |
| stag_b2 | camp | 112.4 | stag_a1 | 112.5 | -0.0 % |
| cache_b_b1 | cache | 113.1 | cache_b_a2 | 113.7 | -0.6 % |
| tower_r_a2 | point | 114.1 | tower_r_b1 | 114.1 | +0.0 % |
| rich_lodge_a2 | guild | 114.7 | rich_lodge_b1 | 114.6 | +0.1 % |
| stag_a2 | camp | 115.1 | stag_b1 | 115.1 | +0.0 % |
| inn_b1 | tavern | 116.7 | inn_a2 | 116.7 | +0.0 % |
| nat_node_b1 | expansion | 117.6 | nat_node_a2 | 117.6 | +0.0 % |
| post_s_a2 | post | 117.6 | post_s_b1 | 117.6 | +0.0 % |
| guilds_den_a2 | guild | 119.1 | guilds_den_b1 | 119.1 | +0.0 % |
| cache_a_b2 | cache | 119.3 | cache_a_a1 | 119.3 | -0.0 % |
| post_s_b2 | post | 119.4 | post_s_a1 | 119.4 | -0.0 % |
| rich_node_b1 | expansion | 120.0 | rich_node_a2 | 120.0 | -0.0 % |
| x_bridge_n | crossing_bridge_road | 120.7 | x_bridge_n | 120.8 | -0.0 % |
| lairs_one_a2 | lair | 126.8 | lairs_one_b1 | 126.8 | -0.0 % |
| shrine_b2 | point | 128.6 | shrine_a1 | 128.6 | +0.0 % |
| shrine_b1 | point | 128.9 | shrine_a2 | 128.9 | +0.0 % |
| home_b_b2 | home_node | 129.0 | home_b_a1 | 141.4 | -8.8 % |
| lairs_two_b2 | lair | 134.0 | lairs_two_a1 | 134.0 | -0.0 % |
| lairs_one_b2 | lair | 134.9 | lairs_one_a1 | 134.9 | -0.0 % |
| keep_t4 | keep | 136.2 | keep_t0 | 136.2 | +0.0 % |
| tower_r_b1 | point | 138.7 | tower_r_a2 | 138.3 | +0.2 % |
| peddler_b2 | peddler | 140.5 | peddler_a1 | 140.5 | +0.0 % |
| peddler_b1 | peddler | 140.9 | peddler_a2 | 140.9 | +0.0 % |
| guilds_den_b2 | guild | 143.8 | guilds_den_a1 | 143.8 | -0.0 % |
| third_node_b2 | expansion | 145.5 | third_node_a1 | 145.5 | -0.0 % |
| well_b1 | point | 146.6 | well_a2 | 144.8 | +1.2 % |
| home_a_b2 | home_node | 148.1 | home_a_a1 | 148.1 | -0.0 % |
| home_a_b1 | home_node | 148.5 | home_a_a2 | 148.5 | -0.0 % |
| guilds_lodge_b2 | guild | 151.6 | guilds_lodge_a1 | 151.6 | -0.0 % |
| wallow_b2 | camp | 153.5 | wallow_a1 | 158.5 | -3.2 % |
| home_b_b1 | home_node | 153.9 | home_b_a2 | 153.9 | -0.0 % |
| post_w_b2 | post | 155.5 | post_w_a1 | 155.5 | +0.0 % |
| post_w_b1 | post | 155.9 | post_w_a2 | 155.9 | +0.0 % |
| cache_a_b1 | cache | 157.0 | cache_a_a2 | 157.0 | +0.0 % |
| stag_b1 | camp | 159.4 | stag_a2 | 159.5 | -0.1 % |
| post_s_b1 | post | 160.7 | post_s_a2 | 166.5 | -3.5 % |
| keep_t1 | keep | 164.9 | keep_t3 | 154.3 | +6.4 % |
| wallow_b1 | camp | 169.0 | wallow_a2 | 169.0 | +0.0 % |
| lairs_two_b1 | lair | 169.8 | lairs_two_a2 | 169.8 | -0.0 % |
| third_node_b1 | expansion | 175.7 | third_node_a2 | 175.7 | -0.0 % |
| guilds_lodge_b1 | guild | 187.3 | guilds_lodge_a2 | 198.7 | -5.7 % |
| lairs_one_b1 | lair | 188.0 | lairs_one_a2 | 181.9 | +3.2 % |
| guilds_den_b1 | guild | 195.5 | guilds_den_a2 | 190.8 | +2.4 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| A1 south-west | 0 | keep_t3 | 77.4 | no | 136.2 | 164.9 | 0.57 |
| A2 north-west | 0 | keep_t0 | 77.4 | no | 148.9 | 154.3 | 0.52 |
| B1 north-east | 1 | keep_t4 | 77.4 | no | 148.9 | 164.9 | 0.52 |
| B2 south-east | 1 | keep_t1 | 77.4 | no | 136.2 | 154.3 | 0.57 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| A1 south-west | ally keep (keep_t3) | 77.4 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |
| A1 south-west | enemy keep (nearest) (keep_t4) | 136.2 | 0.0 | 0:30 | 0:27 | 0:18 | 0:34 |
| A1 south-west | enemy keep #2 (keep_t1) | 164.9 | 0.0 | 0:36 | 0:33 | 0:22 | 0:41 |
| A1 south-west | nearest expansion (third_node_a1) | 30.4 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| A1 south-west | nearest point (shrine_a1) | 32.9 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| A1 south-west | nearest camp (wallow_a1) | 11.9 | 0.0 | 0:03 | 0:02 | 0:02 | 0:03 |
| A1 south-west | crown (crown) | 77.0 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |
| A2 north-west | ally keep (keep_t0) | 77.4 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |
| A2 north-west | enemy keep (nearest) (keep_t1) | 148.9 | 0.0 | 0:32 | 0:30 | 0:20 | 0:37 |
| A2 north-west | enemy keep #2 (keep_t4) | 154.3 | 0.0 | 0:34 | 0:31 | 0:21 | 0:39 |
| A2 north-west | nearest expansion (third_node_a2) | 30.4 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| A2 north-west | nearest point (shrine_a2) | 33.1 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| A2 north-west | nearest camp (wallow_a2) | 13.0 | 0.0 | 0:03 | 0:03 | 0:02 | 0:03 |
| A2 north-west | crown (crown) | 77.1 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |
| B1 north-east | ally keep (keep_t4) | 77.4 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |
| B1 north-east | enemy keep (nearest) (keep_t3) | 141.1 | 0.0 | 0:31 | 0:28 | 0:19 | 0:35 |
| B1 north-east | enemy keep #2 (keep_t0) | 176.6 | 0.0 | 0:38 | 0:35 | 0:24 | 0:44 |
| B1 north-east | nearest expansion (third_node_b1) | 30.4 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| B1 north-east | nearest point (shrine_b1) | 33.1 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| B1 north-east | nearest camp (wallow_b1) | 13.0 | 0.0 | 0:03 | 0:03 | 0:02 | 0:03 |
| B1 north-east | crown (crown) | 77.1 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |
| B2 south-east | ally keep (keep_t1) | 77.4 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |
| B2 south-east | enemy keep (nearest) (keep_t0) | 148.9 | 0.0 | 0:32 | 0:30 | 0:20 | 0:37 |
| B2 south-east | enemy keep #2 (keep_t3) | 164.9 | 0.0 | 0:36 | 0:33 | 0:22 | 0:41 |
| B2 south-east | nearest expansion (third_node_b2) | 30.4 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| B2 south-east | nearest point (shrine_b2) | 32.9 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| B2 south-east | nearest camp (wallow_b2) | 11.9 | 0.0 | 0:03 | 0:02 | 0:02 | 0:03 |
| B2 south-east | crown (crown) | 77.0 | 0.0 | 0:17 | 0:15 | 0:10 | 0:19 |


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
| keep_t0 -> crown | 77.2 | 3.6 | (-7.0, 1.6) | - |
| keep_t0 -> keep_t1 | 164.9 | 3.9 | (-7.0, 1.6) | - |
| keep_t0 -> keep_t4 | 136.2 | 5.8 | (-1.1, 36.0) | - |
| keep_t0 -> third_node_a1 | 30.4 | 22.6 | (-69.7, 52.0) | - |
| keep_t3 -> crown | 77.4 | 4.1 | (-7.0, -1.7) | - |
| keep_t3 -> keep_t4 | 154.3 | 3.6 | (6.6, 1.5) | - |
| keep_t3 -> third_node_a2 | 30.4 | 22.6 | (-69.7, -52.0) | - |
| keep_t1 -> crown | 77.1 | 4.1 | (7.0, -1.7) | - |
| keep_t1 -> keep_t3 | 141.1 | 5.9 | (-1.3, -37.1) | - |
| keep_t1 -> third_node_b1 | 30.4 | 22.6 | (69.7, -52.0) | - |
| keep_t4 -> crown | 77.0 | 3.6 | (7.0, 1.6) | - |
| keep_t4 -> third_node_b2 | 30.4 | 22.6 | (69.7, 52.0) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| A1 south-west | ally | 60.00-72.00 | 77.37 | 7.5 % |
| A1 south-west | enemy_ally | 2.00-3.00 | 1.76 | 12.0 % |
| A1 south-west | keep_enemy | 130.00-185.00 | 136.20 | - |
| A1 south-west | natural | 32.00-56.00 | 36.73 | - |
| A1 south-west | rich | 50.00-95.00 | 57.32 | - |
| A1 south-west | crown | 60.00-95.00 | 76.99 | - |
| A2 north-west | ally | 60.00-72.00 | 77.37 | 7.5 % |
| A2 north-west | enemy_ally | 2.00-3.00 | 1.92 | 3.8 % |
| A2 north-west | keep_enemy | 130.00-185.00 | 148.91 | - |
| A2 north-west | natural | 32.00-56.00 | 36.81 | - |
| A2 north-west | rich | 50.00-95.00 | 57.32 | - |
| A2 north-west | crown | 60.00-95.00 | 77.06 | - |
| B1 north-east | ally | 60.00-72.00 | 77.37 | 7.5 % |
| B1 north-east | enemy_ally | 2.00-3.00 | 1.92 | 3.8 % |
| B1 north-east | keep_enemy | 130.00-185.00 | 148.91 | - |
| B1 north-east | natural | 32.00-56.00 | 36.81 | - |
| B1 north-east | rich | 50.00-95.00 | 57.32 | - |
| B1 north-east | crown | 60.00-95.00 | 77.06 | - |
| B2 south-east | ally | 60.00-72.00 | 77.37 | 7.5 % |
| B2 south-east | enemy_ally | 2.00-3.00 | 1.76 | 12.0 % |
| B2 south-east | keep_enemy | 130.00-185.00 | 136.20 | - |
| B2 south-east | natural | 32.00-56.00 | 36.73 | - |
| B2 south-east | rich | 50.00-95.00 | 57.32 | - |
| B2 south-east | crown | 60.00-95.00 | 76.99 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A1 south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 2 | 2 | 1 | 1 | 1 |
| A2 north-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 2 | 2 | 1 | 1 | 1 |
| B1 north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 2 | 2 | 1 | 1 | 1 |
| B2 south-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 2 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| A1 south-west | 4 | 5 | 21 | 55 |
| A2 north-west | 4 | 4 | 21 | 55 |
| B1 north-east | 4 | 4 | 21 | 55 |
| B2 south-east | 4 | 5 | 21 | 55 |


## Hottest metres (every spot-pair shortest path, 5886 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (0.5, -36.5) | 473 | 8 % |
| 2 | (0.5, 36.5) | 453 | 8 % |
| 3 | (14.5, -12.5) | 364 | 6 % |
| 4 | (-14.5, -12.5) | 356 | 6 % |
| 5 | (14.5, -4.5) | 339 | 6 % |
| 6 | (-14.5, -4.5) | 325 | 6 % |
| 7 | (-15.5, 4.5) | 307 | 5 % |
| 8 | (6.5, -26.5) | 300 | 5 % |
| 9 | (-4.5, -29.5) | 292 | 5 % |
| 10 | (15.5, 4.5) | 285 | 5 % |


## Info findings (1208)
| Check | Where | What |
|---|---|---|
| N3 | island 27 at (-68.1, -31.4) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 30 at (68.1, -31.4) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 43 at (-68.1, 31.4) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 44 at (68.1, 31.4) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 60 islands on top of colliders (745 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | keep_t1-wallow_b1 vs keep_t4-wallow_b2 | 13.0 m vs 11.9 m (8.4 %) |
| F2 | keep_t0-wallow_a1 vs keep_t1-wallow_b1 | 11.9 m vs 13.0 m (8.4 %) |
| F2 | keep_t0-wallow_a1 vs keep_t3-wallow_a2 | 11.9 m vs 13.0 m (8.4 %) |
| F2 | keep_t3-wallow_a2 vs keep_t4-wallow_b2 | 13.0 m vs 11.9 m (8.4 %) |
| F2 | home_b_a1-rich_node_b1 vs home_b_a2-rich_node_b2 | 120.4 m vs 114.3 m (5.0 %) |
| F2 | rich_den_a2-guilds_lodge_a2 vs rich_den_b2-guilds_lodge_b2 | 81.2 m vs 85.4 m (5.0 %) |
| F2 | rich_den_a1-guilds_lodge_a1 vs rich_den_a2-guilds_lodge_a2 | 85.4 m vs 81.2 m (5.0 %) |
| F2 | ford_nest_a1-post_s_b1 vs ford_nest_a2-post_s_b2 | 130.2 m vs 123.7 m (5.0 %) |
| F2 | home_b_a1-rich_node_b1 vs home_b_b1-rich_node_a1 | 120.4 m vs 114.4 m (5.0 %) |
| F2 | rich_den_b1-guilds_lodge_b1 vs rich_den_b2-guilds_lodge_b2 | 81.2 m vs 85.4 m (5.0 %) |
| F2 | rich_den_a1-guilds_lodge_a1 vs rich_den_b1-guilds_lodge_b1 | 85.4 m vs 81.2 m (5.0 %) |
| F2 | well_b1-ford_nest_a1 vs well_b2-ford_nest_a2 | 96.7 m vs 91.9 m (5.0 %) |
| F2 | well_b1-x_ford_s vs well_b2-x_ford_n | 96.7 m vs 91.9 m (5.0 %) |
| F2 | ford_nest_a1-lairs_two_a2 vs ford_nest_a2-lairs_two_b2 | 125.8 m vs 119.5 m (5.0 %) |
| F2 | rich_node_a2-guilds_lodge_b2 vs rich_node_b2-guilds_lodge_a2 | 151.4 m vs 159.4 m (5.0 %) |
| F2 | post_s_a2-cache_b_a1 vs post_s_b2-cache_b_b1 | 112.6 m vs 107.0 m (5.0 %) |
| F2 | post_s_a1-cache_b_a2 vs post_s_a2-cache_b_a1 | 107.0 m vs 112.6 m (5.0 %) |
| F2 | shrine_a2-guilds_lodge_b1 vs shrine_b2-guilds_lodge_a1 | 153.7 m vs 146.0 m (5.0 %) |
| F2 | keep_t3-inn_b1 vs keep_t4-inn_a1 | 104.5 m vs 99.4 m (5.0 %) |
| F2 | keep_t1-inn_a2 vs keep_t4-inn_a1 | 104.5 m vs 99.4 m (5.0 %) |
| F2 | rich_den_a1-lairs_two_a2 vs rich_den_a2-lairs_two_a1 | 127.2 m vs 120.9 m (5.0 %) |
| F2 | rich_den_a1-lairs_two_a2 vs rich_den_b1-lairs_two_b2 | 127.2 m vs 120.9 m (5.0 %) |
| F2 | rich_den_a2-lairs_two_a1 vs rich_den_b2-lairs_two_b1 | 120.9 m vs 127.2 m (5.0 %) |
| F2 | rich_den_b1-lairs_two_b2 vs rich_den_b2-lairs_two_b1 | 120.9 m vs 127.2 m (5.0 %) |
| F2 | keep_t0-inn_b2 vs keep_t1-inn_a2 | 99.4 m vs 104.5 m (4.9 %) |
| F2 | keep_t0-inn_b2 vs keep_t3-inn_b1 | 99.4 m vs 104.5 m (4.9 %) |
| F2 | well_a2-ford_nest_a1 vs well_b2-ford_nest_a2 | 96.7 m vs 91.9 m (4.9 %) |
| F2 | well_a2-x_ford_s vs well_b2-x_ford_n | 96.7 m vs 91.9 m (4.9 %) |
| F2 | home_b_a2-rich_node_b2 vs home_b_b2-rich_node_a2 | 114.3 m vs 120.3 m (4.9 %) |
| F2 | home_b_b1-rich_node_a1 vs home_b_b2-rich_node_a2 | 114.4 m vs 120.3 m (4.9 %) |
| F2 | nat_node_a1-wallow_b2 vs nat_node_a2-wallow_b1 | 117.5 m vs 123.5 m (4.9 %) |
| F2 | nat_node_a1-wallow_b2 vs nat_node_b1-wallow_a2 | 117.5 m vs 123.5 m (4.9 %) |
| F2 | rich_den_a1-lairs_two_b1 vs rich_den_b1-lairs_two_a1 | 129.7 m vs 123.4 m (4.9 %) |
| F2 | nat_node_a1-lairs_one_b2 vs nat_node_a2-lairs_one_b1 | 118.7 m vs 124.8 m (4.9 %) |
| F2 | keep_t0-rich_lodge_a1 vs keep_t1-rich_lodge_b1 | 80.2 m vs 84.4 m (4.9 %) |
| F2 | rich_den_a1-lairs_two_b1 vs rich_den_a2-lairs_two_b2 | 129.7 m vs 123.4 m (4.9 %) |
| F2 | rich_den_b1-lairs_two_a1 vs rich_den_b2-lairs_two_a2 | 123.4 m vs 129.7 m (4.9 %) |
| F2 | home_a_a2-guilds_den_b2 vs home_a_b2-guilds_den_a2 | 170.3 m vs 179.0 m (4.9 %) |
| F2 | well_a1-rich_den_b1 vs well_b1-rich_den_a1 | 95.7 m vs 100.6 m (4.9 %) |
| F2 | nat_node_a1-well_b1 vs nat_node_b1-well_a1 | 109.8 m vs 104.5 m (4.9 %) |
| F2 | nat_node_a1-well_b1 vs nat_node_a2-well_b2 | 109.8 m vs 104.5 m (4.9 %) |
| F2 | home_a_b1-guilds_den_a1 vs home_a_b2-guilds_den_a2 | 170.3 m vs 179.0 m (4.8 %) |
| F2 | ford_nest_a1-guilds_lodge_b1 vs ford_nest_a2-guilds_lodge_a1 | 139.0 m vs 132.3 m (4.8 %) |
| F2 | post_w_a1-lairs_two_b2 vs post_w_b2-lairs_two_a1 | 155.5 m vs 148.0 m (4.8 %) |
| F2 | rich_den_a2-lairs_two_b2 vs rich_den_b2-lairs_two_a2 | 123.4 m vs 129.7 m (4.8 %) |
| F2 | well_a1-rich_den_b1 vs well_a2-rich_den_b2 | 95.7 m vs 100.6 m (4.8 %) |
| F2 | nat_node_a2-lairs_one_b1 vs nat_node_b2-lairs_one_a1 | 124.8 m vs 118.8 m (4.8 %) |
| F2 | post_w_a1-lairs_two_b2 vs post_w_b1-lairs_two_a2 | 155.5 m vs 148.0 m (4.8 %) |
| F2 | cache_b_a2-lairs_one_a2 vs cache_b_b2-lairs_one_b2 | 80.3 m vs 84.4 m (4.8 %) |
| F2 | cache_b_b1-lairs_one_b1 vs cache_b_b2-lairs_one_b2 | 80.3 m vs 84.4 m (4.8 %) |
| F2 | post_w_a1-lairs_two_b2 vs post_w_a2-lairs_two_b1 | 155.5 m vs 148.0 m (4.8 %) |
| F2 | third_node_a1-well_b1 vs third_node_a2-well_b2 | 172.5 m vs 164.2 m (4.8 %) |
| F2 | ford_nest_a1-guilds_lodge_b1 vs ford_nest_a2-guilds_lodge_b2 | 139.0 m vs 132.3 m (4.8 %) |
| F2 | rich_hollow_a2-lairs_two_a1 vs rich_hollow_b2-lairs_two_b1 | 127.5 m vs 133.9 m (4.8 %) |
| F2 | well_b1-rich_den_a1 vs well_b2-rich_den_a2 | 100.6 m vs 95.8 m (4.8 %) |
| F2 | nat_node_a2-wallow_b1 vs nat_node_b2-wallow_a1 | 123.5 m vs 117.6 m (4.8 %) |
| F2 | nat_node_b1-wallow_a2 vs nat_node_b2-wallow_a1 | 123.5 m vs 117.6 m (4.8 %) |
| F2 | cache_a_a1-lairs_two_b1 vs cache_a_b1-lairs_two_a1 | 180.4 m vs 171.8 m (4.8 %) |
| F2 | home_b_a2-nat_node_b1 vs home_b_b2-nat_node_a1 | 105.3 m vs 100.3 m (4.8 %) |
| F2 | rich_den_b1-guilds_lodge_a2 vs rich_den_b2-guilds_lodge_a1 | 85.9 m vs 90.2 m (4.8 %) |
| F2 | well_a2-rich_den_b2 vs well_b2-rich_den_a2 | 100.6 m vs 95.8 m (4.8 %) |
| F2 | home_b_b1-nat_node_a2 vs home_b_b2-nat_node_a1 | 105.3 m vs 100.3 m (4.8 %) |
| F2 | home_b_a1-nat_node_b2 vs home_b_a2-nat_node_b1 | 100.3 m vs 105.3 m (4.7 %) |
| F2 | tower_r_b1-well_b2 vs tower_r_b2-well_b1 | 118.7 m vs 124.6 m (4.7 %) |
| F2 | tower_r_a1-well_a2 vs tower_r_b1-well_b2 | 124.6 m vs 118.7 m (4.7 %) |
| F2 | home_b_a1-nat_node_b2 vs home_b_b1-nat_node_a2 | 100.3 m vs 105.3 m (4.7 %) |
| F2 | ford_nest_a1-cache_a_a2 vs ford_nest_a2-cache_a_a1 | 116.2 m vs 110.7 m (4.7 %) |
| F2 | rich_hollow_a1-lairs_two_a2 vs rich_hollow_a2-lairs_two_a1 | 133.8 m vs 127.5 m (4.7 %) |
| F2 | rich_hollow_b1-lairs_two_b2 vs rich_hollow_b2-lairs_two_b1 | 127.6 m vs 133.9 m (4.7 %) |
| F2 | rich_den_a2-guilds_lodge_b1 vs rich_den_b2-guilds_lodge_a1 | 85.9 m vs 90.2 m (4.7 %) |
| F2 | wallow_a1-post_w_b2 vs wallow_a2-post_w_b1 | 170.3 m vs 162.2 m (4.7 %) |
| F2 | wallow_b1-post_w_a2 vs wallow_b2-post_w_a1 | 162.2 m vs 170.3 m (4.7 %) |
| F2 | wallow_a1-post_w_b2 vs wallow_b1-post_w_a2 | 170.3 m vs 162.2 m (4.7 %) |
| F2 | wallow_a2-post_w_b1 vs wallow_b2-post_w_a1 | 162.2 m vs 170.3 m (4.7 %) |
| F2 | tower_r_a1-well_a2 vs tower_r_a2-well_a1 | 124.6 m vs 118.7 m (4.7 %) |
| F2 | tower_r_a2-well_a1 vs tower_r_b2-well_b1 | 118.7 m vs 124.6 m (4.7 %) |
| F2 | home_b_a2-wallow_b1 vs home_b_b1-wallow_a2 | 151.1 m vs 143.9 m (4.7 %) |
| F2 | keep_t3-well_b2 vs keep_t4-well_a2 | 138.0 m vs 144.8 m (4.7 %) |
| F2 | cache_a_a1-lairs_two_b1 vs cache_a_a2-lairs_two_b2 | 180.4 m vs 171.9 m (4.7 %) |
| F2 | tower_r_a1-post_s_b1 vs tower_r_b1-post_s_a1 | 165.5 m vs 157.7 m (4.7 %) |
| F2 | cache_a_b1-lairs_two_a1 vs cache_a_b2-lairs_two_a2 | 171.8 m vs 180.3 m (4.7 %) |
| F2 | tower_r_a1-post_s_b1 vs tower_r_a2-post_s_b2 | 165.5 m vs 157.7 m (4.7 %) |
| F2 | tower_r_b1-post_s_a1 vs tower_r_b2-post_s_a2 | 157.7 m vs 165.4 m (4.7 %) |
| F2 | well_a1-rich_hollow_a2 vs well_b1-rich_hollow_b2 | 99.9 m vs 104.8 m (4.7 %) |
| F2 | tower_r_a2-post_s_b2 vs tower_r_b2-post_s_a2 | 157.7 m vs 165.4 m (4.7 %) |
| F2 | home_a_a2-guilds_lodge_b1 vs home_a_b1-guilds_lodge_a2 | 161.2 m vs 153.6 m (4.7 %) |
| F2 | ford_nest_a1-cache_a_a2 vs ford_nest_a2-cache_a_b2 | 116.2 m vs 110.7 m (4.7 %) |
| F2 | shrine_a1-post_s_b1 vs shrine_b2-post_s_a2 | 127.5 m vs 133.8 m (4.7 %) |
| F2 | rich_hollow_a1-lairs_two_a2 vs rich_hollow_b1-lairs_two_b2 | 133.8 m vs 127.6 m (4.7 %) |
| F2 | shrine_a2-post_s_b2 vs shrine_b2-post_s_a2 | 127.5 m vs 133.8 m (4.7 %) |
| F2 | shrine_b1-post_s_a1 vs shrine_b2-post_s_a2 | 127.5 m vs 133.8 m (4.7 %) |
| F2 | home_b_a1-tower_r_b1 vs home_b_b1-tower_r_a1 | 135.5 m vs 129.2 m (4.7 %) |
| F2 | keep_t1-well_a1 vs keep_t4-well_a2 | 138.0 m vs 144.8 m (4.7 %) |
| F2 | home_b_a2-stag_b2 vs home_b_b2-stag_a2 | 149.1 m vs 156.4 m (4.7 %) |
| F2 | cache_a_a2-lairs_two_b2 vs cache_a_b2-lairs_two_a2 | 171.9 m vs 180.3 m (4.7 %) |
| F2 | rich_den_a1-cache_a_a2 vs rich_den_b1-cache_a_b2 | 117.6 m vs 112.1 m (4.7 %) |
| F2 | rich_den_b1-cache_a_b2 vs rich_den_b2-cache_a_b1 | 112.1 m vs 117.6 m (4.7 %) |
| F2 | rich_den_a2-cache_a_a1 vs rich_den_b2-cache_a_b1 | 112.1 m vs 117.6 m (4.7 %) |
| F2 | rich_den_a1-cache_a_a2 vs rich_den_a2-cache_a_a1 | 117.6 m vs 112.1 m (4.7 %) |
| F2 | home_b_b1-wallow_a2 vs home_b_b2-wallow_a1 | 143.9 m vs 151.0 m (4.7 %) |
| F2 | rich_hollow_a1-cache_a_b1 vs rich_hollow_a2-cache_a_b2 | 117.8 m vs 112.3 m (4.7 %) |
| F2 | rich_hollow_a1-cache_a_b1 vs rich_hollow_b1-cache_a_a1 | 117.8 m vs 112.3 m (4.7 %) |
| F2 | rich_hollow_a2-cache_a_b2 vs rich_hollow_b2-cache_a_a2 | 112.3 m vs 117.8 m (4.7 %) |
| F2 | rich_hollow_b1-cache_a_a1 vs rich_hollow_b2-cache_a_a2 | 112.3 m vs 117.8 m (4.7 %) |
| F2 | home_b_a1-tower_r_b1 vs home_b_a2-tower_r_b2 | 135.5 m vs 129.2 m (4.7 %) |
| F2 | well_a1-rich_hollow_a2 vs well_a2-rich_hollow_a1 | 99.9 m vs 104.7 m (4.7 %) |
| F2 | rich_lodge_b1-lairs_two_a1 vs rich_lodge_b2-lairs_two_a2 | 129.4 m vs 135.8 m (4.6 %) |
| F2 | rich_lodge_a2-lairs_two_b2 vs rich_lodge_b2-lairs_two_a2 | 129.4 m vs 135.8 m (4.6 %) |
| F2 | rich_lodge_a1-lairs_two_b1 vs rich_lodge_b1-lairs_two_a1 | 135.8 m vs 129.4 m (4.6 %) |
| F2 | rich_lodge_a1-lairs_two_b1 vs rich_lodge_a2-lairs_two_b2 | 135.8 m vs 129.4 m (4.6 %) |
| F2 | third_node_a1-x_lane_e vs third_node_a2-x_lane_e | 111.3 m vs 116.8 m (4.6 %) |
| F2 | home_b_b1-stag_a1 vs home_b_b2-stag_a2 | 149.1 m vs 156.4 m (4.6 %) |
| F2 | cache_a_a1-x_ford_n vs cache_a_b1-x_ford_s | 109.3 m vs 114.6 m (4.6 %) |
| F2 | rich_den_a1-cache_a_b1 vs rich_den_b1-cache_a_a1 | 120.1 m vs 114.6 m (4.6 %) |
| F2 | nat_node_a2-guilds_lodge_b2 vs nat_node_b1-guilds_lodge_a1 | 147.3 m vs 154.4 m (4.6 %) |
| F2 | well_b1-rich_hollow_b2 vs well_b2-rich_hollow_b1 | 104.8 m vs 100.0 m (4.6 %) |
| F2 | cache_a_a1-x_ford_n vs cache_a_a2-x_ford_s | 109.3 m vs 114.5 m (4.6 %) |
| F2 | rich_lodge_a1-lairs_two_a2 vs rich_lodge_b1-lairs_two_b2 | 139.6 m vs 133.2 m (4.6 %) |
| F2 | keep_t3-nat_node_b1 vs keep_t4-nat_node_a1 | 112.8 m vs 107.6 m (4.6 %) |
| F2 | keep_t1-nat_node_a2 vs keep_t4-nat_node_a1 | 112.8 m vs 107.6 m (4.6 %) |
| F2 | rich_den_a1-cache_a_b1 vs rich_den_a2-cache_a_b2 | 120.1 m vs 114.6 m (4.6 %) |
| F2 | tower_r_a1-guilds_lodge_b1 vs tower_r_b1-guilds_lodge_a1 | 174.2 m vs 166.3 m (4.6 %) |
| F2 | rich_den_b1-cache_a_a1 vs rich_den_b2-cache_a_a2 | 114.6 m vs 120.1 m (4.6 %) |
| F2 | home_b_a1-lairs_one_b1 vs home_b_b2-lairs_one_a2 | 184.9 m vs 176.4 m (4.6 %) |
| F2 | keep_t0-nat_node_b2 vs keep_t3-nat_node_b1 | 107.6 m vs 112.8 m (4.6 %) |
| F2 | tower_r_a1-guilds_lodge_b1 vs tower_r_a2-guilds_lodge_b2 | 174.2 m vs 166.3 m (4.6 %) |
| F2 | tower_r_b1-guilds_lodge_a1 vs tower_r_b2-guilds_lodge_a2 | 166.3 m vs 174.2 m (4.6 %) |
| F2 | keep_t0-nat_node_b2 vs keep_t1-nat_node_a2 | 107.6 m vs 112.8 m (4.6 %) |
| F2 | cache_a_b1-x_ford_s vs cache_a_b2-x_ford_n | 114.6 m vs 109.3 m (4.6 %) |
| F2 | tower_c_a2-rich_lodge_b1 vs tower_c_b2-rich_lodge_a1 | 45.7 m vs 43.6 m (4.6 %) |
| F2 | tower_c_b1-rich_lodge_a2 vs tower_c_b2-rich_lodge_a1 | 45.7 m vs 43.6 m (4.6 %) |
| F2 | tower_r_a2-guilds_lodge_b2 vs tower_r_b2-guilds_lodge_a2 | 166.3 m vs 174.2 m (4.6 %) |
| F2 | tower_r_a2-cache_b_a1 vs tower_r_b2-cache_b_b1 | 95.0 m vs 90.6 m (4.6 %) |
| F2 | tower_r_b1-cache_b_b2 vs tower_r_b2-cache_b_b1 | 95.0 m vs 90.6 m (4.6 %) |
| F2 | tower_r_a1-cache_b_a2 vs tower_r_a2-cache_b_a1 | 90.6 m vs 95.0 m (4.6 %) |
| F2 | tower_r_a1-cache_b_a2 vs tower_r_b1-cache_b_b2 | 90.6 m vs 95.0 m (4.6 %) |
| F2 | cache_b_a1-lairs_two_a2 vs cache_b_a2-lairs_two_a1 | 109.9 m vs 104.9 m (4.6 %) |
| F2 | cache_b_a1-lairs_two_a2 vs cache_b_b1-lairs_two_b2 | 109.9 m vs 104.9 m (4.6 %) |
| F2 | well_a2-rich_hollow_a1 vs well_b2-rich_hollow_b1 | 104.7 m vs 100.0 m (4.6 %) |
| F2 | well_a2-rich_den_a1 vs well_b2-rich_den_b1 | 97.9 m vs 93.5 m (4.5 %) |
| F2 | well_a1-rich_den_a2 vs well_a2-rich_den_a1 | 93.5 m vs 97.9 m (4.5 %) |
| F2 | well_a1-rich_den_a2 vs well_b1-rich_den_b2 | 93.5 m vs 97.9 m (4.5 %) |
| F2 | well_b1-rich_den_b2 vs well_b2-rich_den_b1 | 97.9 m vs 93.5 m (4.5 %) |
| F2 | third_node_a1-x_lane_e vs third_node_b1-x_lane_w | 111.3 m vs 116.6 m (4.5 %) |
| F2 | rich_den_a2-cache_a_b2 vs rich_den_b2-cache_a_a2 | 114.6 m vs 120.1 m (4.5 %) |
| F2 | cache_a_a2-x_ford_s vs cache_a_b2-x_ford_n | 114.5 m vs 109.3 m (4.5 %) |
| F2 | third_node_a1-x_lane_e vs third_node_b2-x_lane_w | 111.3 m vs 116.6 m (4.5 %) |
| F2 | post_w_a2-guilds_lodge_b1 vs post_w_b1-guilds_lodge_a2 | 173.9 m vs 166.0 m (4.5 %) |
| F2 | well_a1-cache_b_b1 vs well_b2-cache_b_a2 | 100.0 m vs 104.8 m (4.5 %) |
| F2 | rich_lodge_b1-lairs_two_b2 vs rich_lodge_b2-lairs_two_b1 | 133.2 m vs 139.5 m (4.5 %) |
| F2 | wallow_a1-peddler_b1 vs wallow_a2-peddler_b2 | 155.6 m vs 163.0 m (4.5 %) |
| F2 | wallow_a2-peddler_b2 vs wallow_b2-peddler_a2 | 163.0 m vs 155.6 m (4.5 %) |
| F2 | rich_lodge_a1-lairs_two_a2 vs rich_lodge_a2-lairs_two_a1 | 139.6 m vs 133.3 m (4.5 %) |
| F2 | well_a1-cache_b_b1 vs well_a2-cache_b_b2 | 100.0 m vs 104.7 m (4.5 %) |
| F2 | rich_hollow_a2-cache_a_a1 vs rich_hollow_b2-cache_a_b1 | 118.7 m vs 124.3 m (4.5 %) |
| F2 | keep_t3-wallow_b1 vs keep_t1-wallow_a2 | 158.6 m vs 151.4 m (4.5 %) |
| F2 | keep_t1-wallow_a2 vs keep_t4-wallow_a1 | 151.4 m vs 158.5 m (4.5 %) |
| F2 | tower_c_a1-rich_lodge_b2 vs tower_c_b2-rich_lodge_a1 | 45.7 m vs 43.6 m (4.5 %) |
| F2 | tower_c_a1-rich_lodge_b1 vs tower_c_a2-rich_lodge_b2 | 59.0 m vs 61.8 m (4.5 %) |
| F2 | tower_c_a2-rich_lodge_b2 vs tower_c_b2-rich_lodge_a2 | 61.8 m vs 59.0 m (4.5 %) |
| F2 | wallow_a1-peddler_b1 vs wallow_b1-peddler_a1 | 155.6 m vs 162.9 m (4.5 %) |
| F2 | wallow_b1-peddler_a1 vs wallow_b2-peddler_a2 | 162.9 m vs 155.6 m (4.5 %) |
| F2 | rich_hollow_a1-guilds_lodge_a1 vs rich_hollow_b1-guilds_lodge_b1 | 94.5 m vs 90.2 m (4.5 %) |
| F2 | rich_hollow_a1-guilds_lodge_a1 vs rich_hollow_a2-guilds_lodge_a2 | 94.5 m vs 90.2 m (4.5 %) |
| F2 | wallow_a2-guilds_den_b2 vs wallow_b2-guilds_den_a2 | 191.9 m vs 200.9 m (4.5 %) |
| F2 | third_node_a1-cache_b_a1 vs third_node_a2-cache_b_a2 | 76.5 m vs 80.0 m (4.5 %) |
| F2 | third_node_a2-cache_b_a2 vs third_node_b2-cache_b_b2 | 80.0 m vs 76.5 m (4.5 %) |
| F2 | third_node_b1-cache_b_b1 vs third_node_b2-cache_b_b2 | 80.0 m vs 76.5 m (4.5 %) |
| F2 | third_node_a1-cache_b_a1 vs third_node_b1-cache_b_b1 | 76.5 m vs 80.0 m (4.5 %) |
| F2 | shrine_a1-x_bridge_n vs shrine_b1-x_bridge_s | 88.1 m vs 92.2 m (4.5 %) |
| F2 | well_a2-rich_lodge_a1 vs well_b2-rich_lodge_b1 | 110.5 m vs 105.6 m (4.5 %) |
| F2 | wallow_b1-guilds_den_a1 vs wallow_b2-guilds_den_a2 | 191.9 m vs 200.9 m (4.5 %) |
| F2 | ford_nest_a1-guilds_den_a2 vs ford_nest_a2-guilds_den_a1 | 141.5 m vs 135.1 m (4.5 %) |
| F2 | ford_nest_a1-lairs_one_a2 vs ford_nest_a2-lairs_one_a1 | 139.8 m vs 133.6 m (4.5 %) |
| F2 | cache_b_a1-lairs_one_a1 vs cache_b_b1-lairs_one_b1 | 84.1 m vs 80.3 m (4.4 %) |
| F2 | cache_b_a1-lairs_one_a1 vs cache_b_a2-lairs_one_a2 | 84.1 m vs 80.3 m (4.4 %) |
| F2 | stag_a1-x_ford_n vs stag_b1-x_ford_s | 118.7 m vs 124.2 m (4.4 %) |
| F2 | shrine_a2-x_bridge_s vs shrine_b1-x_bridge_s | 88.1 m vs 92.2 m (4.4 %) |
| F2 | home_b_b1-tower_r_a1 vs home_b_b2-tower_r_a2 | 129.2 m vs 135.2 m (4.4 %) |
| F2 | rich_hollow_a1-cache_a_a2 vs rich_hollow_a2-cache_a_a1 | 124.2 m vs 118.7 m (4.4 %) |
| F2 | rich_hollow_b1-cache_a_b2 vs rich_hollow_b2-cache_a_b1 | 118.8 m vs 124.3 m (4.4 %) |
| F2 | shrine_b1-x_bridge_s vs shrine_b2-x_bridge_n | 92.2 m vs 88.1 m (4.4 %) |
| F2 | home_b_a2-tower_r_b2 vs home_b_b2-tower_r_a2 | 129.2 m vs 135.2 m (4.4 %) |
| F2 | keep_t3-post_s_b2 vs keep_t4-post_s_a2 | 159.1 m vs 166.5 m (4.4 %) |
| F2 | rich_lodge_a2-lairs_two_a1 vs rich_lodge_b2-lairs_two_b1 | 133.3 m vs 139.5 m (4.4 %) |
| F2 | ford_nest_a1-guilds_den_a2 vs ford_nest_a2-guilds_den_b2 | 141.5 m vs 135.2 m (4.4 %) |
| F2 | shrine_a1-guilds_lodge_b2 vs shrine_a2-guilds_lodge_b1 | 146.9 m vs 153.7 m (4.4 %) |
| F2 | stag_a1-x_ford_n vs stag_a2-x_ford_s | 118.7 m vs 124.2 m (4.4 %) |
| F2 | ford_nest_a1-lairs_one_a2 vs ford_nest_a2-lairs_one_b2 | 139.8 m vs 133.7 m (4.4 %) |
| F2 | wallow_a2-guilds_lodge_b2 vs wallow_b2-guilds_lodge_a2 | 199.5 m vs 208.7 m (4.4 %) |
| F2 | keep_t1-post_s_a1 vs keep_t4-post_s_a2 | 159.2 m vs 166.5 m (4.4 %) |
| F2 | inn_a1-guilds_den_b2 vs inn_b1-guilds_den_a2 | 119.1 m vs 113.9 m (4.4 %) |
| F2 | well_a1-cache_b_b1 vs well_b1-cache_b_a1 | 100.0 m vs 104.6 m (4.4 %) |
| F2 | rich_den_a2-guilds_den_a1 vs rich_den_b2-guilds_den_b1 | 136.6 m vs 142.9 m (4.4 %) |
| F2 | rich_den_a1-guilds_den_a2 vs rich_den_b1-guilds_den_b2 | 142.9 m vs 136.6 m (4.4 %) |
| F2 | rich_den_a1-guilds_den_a2 vs rich_den_a2-guilds_den_a1 | 142.9 m vs 136.6 m (4.4 %) |
| F2 | rich_den_b1-guilds_den_b2 vs rich_den_b2-guilds_den_b1 | 136.6 m vs 142.9 m (4.4 %) |
| F2 | rich_den_a1-lairs_one_a2 vs rich_den_b1-lairs_one_b2 | 141.2 m vs 135.0 m (4.4 %) |
| F2 | rich_den_a1-lairs_one_a2 vs rich_den_a2-lairs_one_a1 | 141.2 m vs 135.0 m (4.4 %) |
| F2 | rich_den_a2-lairs_one_a1 vs rich_den_b2-lairs_one_b1 | 135.0 m vs 141.2 m (4.4 %) |
| F2 | rich_den_b1-lairs_one_b2 vs rich_den_b2-lairs_one_b1 | 135.0 m vs 141.2 m (4.4 %) |
| F2 | rich_hollow_a1-guilds_den_b1 vs rich_hollow_b1-guilds_den_a1 | 143.1 m vs 136.8 m (4.4 %) |
| F2 | rich_hollow_a1-guilds_den_b1 vs rich_hollow_a2-guilds_den_b2 | 143.1 m vs 136.8 m (4.4 %) |
| F2 | rich_hollow_b1-guilds_den_a1 vs rich_hollow_b2-guilds_den_a2 | 136.8 m vs 143.1 m (4.4 %) |
| F2 | rich_hollow_a2-guilds_den_b2 vs rich_hollow_b2-guilds_den_a2 | 136.8 m vs 143.1 m (4.4 %) |
| F2 | rich_node_a1-lairs_two_b1 vs rich_node_b1-lairs_two_a1 | 145.0 m vs 138.6 m (4.4 %) |
| F2 | rich_hollow_a1-lairs_one_b1 vs rich_hollow_b1-lairs_one_a1 | 141.5 m vs 135.3 m (4.4 %) |
| F2 | rich_hollow_a1-lairs_one_b1 vs rich_hollow_a2-lairs_one_b2 | 141.5 m vs 135.3 m (4.4 %) |
| F2 | rich_hollow_a2-lairs_one_b2 vs rich_hollow_b2-lairs_one_a2 | 135.3 m vs 141.5 m (4.4 %) |
| F2 | rich_hollow_b1-lairs_one_a1 vs rich_hollow_b2-lairs_one_a2 | 135.3 m vs 141.5 m (4.4 %) |
| F2 | rich_hollow_a1-cache_a_a2 vs rich_hollow_b1-cache_a_b2 | 124.2 m vs 118.8 m (4.4 %) |
| F2 | wallow_b1-guilds_lodge_a1 vs wallow_b2-guilds_lodge_a2 | 199.6 m vs 208.7 m (4.4 %) |
| F2 | stag_b1-x_ford_s vs stag_b2-x_ford_n | 124.2 m vs 118.8 m (4.4 %) |
| F2 | home_b_a1-stag_b1 vs home_b_b2-stag_a2 | 163.5 m vs 156.4 m (4.4 %) |
| F2 | inn_a1-guilds_den_b2 vs inn_a2-guilds_den_b1 | 119.1 m vs 113.9 m (4.4 %) |
| F2 | rich_den_a1-guilds_den_b1 vs rich_den_b1-guilds_den_a1 | 145.4 m vs 139.0 m (4.4 %) |
| F2 | rich_den_a1-lairs_one_b1 vs rich_den_b1-lairs_one_a1 | 143.8 m vs 137.5 m (4.4 %) |
| F2 | rich_node_a1-lairs_two_b1 vs rich_node_a2-lairs_two_b2 | 145.0 m vs 138.6 m (4.4 %) |
| F2 | rich_node_b1-lairs_two_a1 vs rich_node_b2-lairs_two_a2 | 138.6 m vs 144.9 m (4.4 %) |
| F2 | well_a1-rich_lodge_a2 vs well_a2-rich_lodge_a1 | 105.7 m vs 110.5 m (4.4 %) |
| F2 | rich_lodge_a1-cache_a_b1 vs rich_lodge_b1-cache_a_a1 | 126.1 m vs 120.6 m (4.3 %) |
| F2 | rich_lodge_a1-cache_a_b1 vs rich_lodge_a2-cache_a_b2 | 126.1 m vs 120.6 m (4.3 %) |
| F2 | post_s_a1-x_ford_n vs post_s_b1-x_ford_s | 121.6 m vs 127.1 m (4.3 %) |
| F2 | stag_a2-x_ford_s vs stag_b2-x_ford_n | 124.2 m vs 118.8 m (4.3 %) |
| F2 | well_b1-rich_lodge_b2 vs well_b2-rich_lodge_b1 | 110.4 m vs 105.6 m (4.3 %) |
| F2 | rich_den_a1-guilds_den_b1 vs rich_den_a2-guilds_den_b2 | 145.4 m vs 139.1 m (4.3 %) |
| F2 | ford_nest_a1-post_w_a2 vs ford_nest_a2-post_w_b2 | 91.2 m vs 95.4 m (4.3 %) |
| F2 | ford_nest_a1-post_w_b1 vs ford_nest_a2-post_w_b2 | 91.2 m vs 95.4 m (4.3 %) |
| F2 | rich_den_b1-guilds_den_a1 vs rich_den_b2-guilds_den_a2 | 139.0 m vs 145.3 m (4.3 %) |
| F2 | rich_node_a2-lairs_two_b2 vs rich_node_b2-lairs_two_a2 | 138.6 m vs 144.9 m (4.3 %) |
| F2 | rich_den_a1-lairs_one_b1 vs rich_den_a2-lairs_one_b2 | 143.8 m vs 137.5 m (4.3 %) |
| F2 | rich_den_b1-lairs_one_a1 vs rich_den_b2-lairs_one_a2 | 137.5 m vs 143.7 m (4.3 %) |
| F2 | post_s_a1-x_ford_n vs post_s_a2-x_ford_s | 121.6 m vs 127.1 m (4.3 %) |
| F2 | rich_lodge_a1-cache_a_a2 vs rich_lodge_b1-cache_a_b2 | 130.0 m vs 124.4 m (4.3 %) |
| F2 | rich_den_a2-guilds_den_b2 vs rich_den_b2-guilds_den_a2 | 139.1 m vs 145.3 m (4.3 %) |
| F2 | shrine_a1-lairs_one_b2 vs shrine_a2-lairs_one_b1 | 136.2 m vs 142.3 m (4.3 %) |
| F2 | peddler_a1-lairs_one_b2 vs peddler_a2-lairs_one_b1 | 136.9 m vs 143.0 m (4.3 %) |
| F2 | rich_den_a2-lairs_one_b2 vs rich_den_b2-lairs_one_a2 | 137.5 m vs 143.7 m (4.3 %) |
| F2 | stag_a1-rich_den_b1 vs stag_b1-rich_den_a1 | 122.6 m vs 128.1 m (4.3 %) |
| F2 | shrine_a2-lairs_one_b1 vs shrine_b1-lairs_one_a2 | 142.3 m vs 136.2 m (4.3 %) |
| F2 | home_b_a2-well_b2 vs home_b_b2-well_a2 | 135.5 m vs 141.5 m (4.3 %) |
| F2 | shrine_a1-wallow_b2 vs shrine_b1-wallow_a2 | 135.7 m vs 141.8 m (4.3 %) |
| F2 | tower_r_a1-cache_a_b2 vs tower_r_b1-cache_a_a2 | 65.2 m vs 62.4 m (4.3 %) |
| F2 | rich_node_a1-wallow_a1 vs rich_node_b2-wallow_b2 | 65.9 m vs 68.8 m (4.3 %) |
| F2 | shrine_a1-wallow_b2 vs shrine_a2-wallow_b1 | 135.7 m vs 141.8 m (4.3 %) |
| F2 | peddler_a2-lairs_one_b1 vs peddler_b1-lairs_one_a2 | 143.0 m vs 136.9 m (4.3 %) |
| F2 | post_s_b1-x_ford_s vs post_s_b2-x_ford_n | 127.1 m vs 121.7 m (4.3 %) |
| F2 | ford_nest_a1-post_w_a2 vs ford_nest_a2-post_w_a1 | 91.2 m vs 95.3 m (4.3 %) |
| F2 | ford_nest_a1-post_w_b1 vs ford_nest_a2-post_w_a1 | 91.2 m vs 95.3 m (4.3 %) |
| F2 | stag_a1-rich_den_b1 vs stag_a2-rich_den_b2 | 122.6 m vs 128.1 m (4.3 %) |
| F2 | rich_hollow_a2-guilds_den_a1 vs rich_hollow_b2-guilds_den_b1 | 143.2 m vs 149.6 m (4.3 %) |
| F2 | rich_hollow_a2-lairs_one_a1 vs rich_hollow_b2-lairs_one_b1 | 141.6 m vs 147.9 m (4.3 %) |
| F2 | tower_r_b1-cache_a_a2 vs tower_r_b2-cache_a_a1 | 62.4 m vs 65.1 m (4.3 %) |
| F2 | peddler_a2-lairs_one_b1 vs peddler_b2-lairs_one_a1 | 143.0 m vs 136.9 m (4.3 %) |
| F2 | shrine_a2-lairs_one_b1 vs shrine_b2-lairs_one_a1 | 142.3 m vs 136.2 m (4.3 %) |
| F2 | post_s_a2-x_ford_s vs post_s_b2-x_ford_n | 127.1 m vs 121.7 m (4.2 %) |
| F2 | well_a1-rich_lodge_a2 vs well_b1-rich_lodge_b2 | 105.7 m vs 110.4 m (4.2 %) |
| F2 | stag_b1-rich_den_a1 vs stag_b2-rich_den_a2 | 128.1 m vs 122.7 m (4.2 %) |
| F2 | wallow_a1-wallow_b1 vs wallow_b2-wallow_a2 | 183.7 m vs 191.8 m (4.2 %) |
| F2 | rich_hollow_a1-guilds_den_a2 vs rich_hollow_a2-guilds_den_a1 | 149.5 m vs 143.2 m (4.2 %) |
| F2 | rich_hollow_b1-guilds_den_b2 vs rich_hollow_b2-guilds_den_b1 | 143.2 m vs 149.6 m (4.2 %) |
| F2 | cache_b_a1-lairs_two_a2 vs cache_b_b2-lairs_two_b1 | 109.9 m vs 105.2 m (4.2 %) |
| F2 | tower_r_a2-cache_a_b1 vs tower_r_b1-cache_a_a2 | 65.1 m vs 62.4 m (4.2 %) |
| F2 | rich_hollow_a1-lairs_one_a2 vs rich_hollow_a2-lairs_one_a1 | 147.9 m vs 141.6 m (4.2 %) |
| F2 | rich_lodge_b1-cache_a_b2 vs rich_lodge_b2-cache_a_b1 | 124.4 m vs 129.8 m (4.2 %) |
| F2 | rich_hollow_b1-lairs_one_b2 vs rich_hollow_b2-lairs_one_b1 | 141.7 m vs 147.9 m (4.2 %) |
| F2 | stag_a2-rich_den_b2 vs stag_b2-rich_den_a2 | 128.1 m vs 122.7 m (4.2 %) |
| F2 | tower_c_b1-well_b1 vs tower_c_b2-well_b2 | 45.1 m vs 43.2 m (4.2 %) |
| F2 | tower_c_a1-well_a1 vs tower_c_b1-well_b1 | 43.2 m vs 45.1 m (4.2 %) |
| F2 | tower_c_a1-well_a1 vs tower_c_a2-well_a2 | 43.2 m vs 45.1 m (4.2 %) |
| F2 | tower_c_a2-well_a2 vs tower_c_b2-well_b2 | 45.1 m vs 43.2 m (4.2 %) |
| F2 | post_s_a1-rich_den_b1 vs post_s_b1-rich_den_a1 | 125.5 m vs 131.0 m (4.2 %) |
| F2 | rich_lodge_a1-cache_a_a2 vs rich_lodge_a2-cache_a_a1 | 130.0 m vs 124.5 m (4.2 %) |
| F2 | post_s_a1-rich_den_b1 vs post_s_a2-rich_den_b2 | 125.5 m vs 131.0 m (4.2 %) |
| F2 | rich_hollow_a1-guilds_den_a2 vs rich_hollow_b1-guilds_den_b2 | 149.5 m vs 143.2 m (4.2 %) |
| F2 | rich_hollow_a1-lairs_one_a2 vs rich_hollow_b1-lairs_one_b2 | 147.9 m vs 141.7 m (4.2 %) |
| F2 | home_b_a1-well_b1 vs home_b_a2-well_b2 | 141.4 m vs 135.5 m (4.2 %) |
| F2 | shrine_a2-stag_b2 vs shrine_b2-stag_a2 | 121.5 m vs 126.8 m (4.2 %) |
| F2 | shrine_b1-stag_a1 vs shrine_b2-stag_a2 | 121.5 m vs 126.8 m (4.2 %) |
| F2 | shrine_b1-wallow_a2 vs shrine_b2-wallow_a1 | 141.8 m vs 135.9 m (4.2 %) |
| F2 | rich_lodge_a1-guilds_den_b1 vs rich_lodge_b1-guilds_den_a1 | 151.4 m vs 145.1 m (4.2 %) |
| F2 | rich_lodge_b1-guilds_den_a1 vs rich_lodge_b2-guilds_den_a2 | 145.1 m vs 151.4 m (4.2 %) |
| F2 | rich_lodge_a1-guilds_den_b1 vs rich_lodge_a2-guilds_den_b2 | 151.4 m vs 145.1 m (4.2 %) |
| F2 | rich_lodge_a2-guilds_den_b2 vs rich_lodge_b2-guilds_den_a2 | 145.1 m vs 151.4 m (4.2 %) |
| F2 | shrine_a2-wallow_b1 vs shrine_b2-wallow_a1 | 141.8 m vs 135.9 m (4.1 %) |
| F2 | home_b_a1-guilds_den_b1 vs home_b_a2-guilds_den_b2 | 183.9 m vs 176.3 m (4.1 %) |
| F2 | rich_lodge_b1-lairs_one_a1 vs rich_lodge_b2-lairs_one_a2 | 143.6 m vs 149.8 m (4.1 %) |
| F2 | rich_lodge_a1-lairs_one_b1 vs rich_lodge_b1-lairs_one_a1 | 149.8 m vs 143.6 m (4.1 %) |
| F2 | rich_lodge_a2-lairs_one_b2 vs rich_lodge_b2-lairs_one_a2 | 143.6 m vs 149.8 m (4.1 %) |
| F2 | rich_lodge_a1-lairs_one_b1 vs rich_lodge_a2-lairs_one_b2 | 149.8 m vs 143.6 m (4.1 %) |
| F2 | home_b_a1-x_bridge_n vs home_b_b1-x_bridge_s | 117.6 m vs 122.7 m (4.1 %) |
| F2 | home_b_a1-x_bridge_n vs home_b_a2-x_bridge_s | 117.6 m vs 122.7 m (4.1 %) |
| F2 | post_s_b1-rich_den_a1 vs post_s_b2-rich_den_a2 | 131.0 m vs 125.6 m (4.1 %) |
| F2 | third_node_b1-tower_r_a1 vs third_node_b2-tower_r_a2 | 157.9 m vs 164.7 m (4.1 %) |
| F2 | rich_lodge_a1-guilds_lodge_a1 vs rich_lodge_a2-guilds_lodge_a2 | 100.0 m vs 95.9 m (4.1 %) |
| F2 | third_node_a2-tower_r_b2 vs third_node_b2-tower_r_a2 | 157.9 m vs 164.7 m (4.1 %) |
| F2 | cache_a_b1-x_ford_n vs cache_a_b2-x_ford_s | 52.2 m vs 54.4 m (4.1 %) |
| F2 | cache_a_a1-x_ford_s vs cache_a_b1-x_ford_n | 54.4 m vs 52.2 m (4.1 %) |
| F2 | cache_a_a1-x_ford_s vs cache_a_a2-x_ford_n | 54.4 m vs 52.2 m (4.1 %) |
| F2 | cache_a_a2-x_ford_n vs cache_a_b2-x_ford_s | 52.2 m vs 54.4 m (4.1 %) |
| F2 | post_s_a2-rich_den_b2 vs post_s_b2-rich_den_a2 | 131.0 m vs 125.6 m (4.1 %) |
| F2 | home_b_a1-guilds_den_b1 vs home_b_b1-guilds_den_a1 | 183.9 m vs 176.4 m (4.1 %) |
| F2 | home_b_a2-guilds_den_b2 vs home_b_b2-guilds_den_a2 | 176.3 m vs 183.9 m (4.1 %) |
| F2 | rich_lodge_a1-guilds_den_a2 vs rich_lodge_b1-guilds_den_b2 | 155.2 m vs 148.9 m (4.1 %) |
| F2 | rich_lodge_a2-cache_a_a1 vs rich_lodge_b2-cache_a_b1 | 124.5 m vs 129.8 m (4.1 %) |
| F2 | third_node_a1-cache_b_b1 vs third_node_b1-cache_b_a1 | 142.9 m vs 137.1 m (4.1 %) |
| F2 | rich_lodge_a1-lairs_one_a2 vs rich_lodge_b1-lairs_one_b2 | 153.6 m vs 147.3 m (4.1 %) |
| F2 | home_b_b1-x_bridge_s vs home_b_b2-x_bridge_n | 122.7 m vs 117.7 m (4.1 %) |
| F2 | home_b_a2-x_bridge_s vs home_b_b2-x_bridge_n | 122.7 m vs 117.7 m (4.1 %) |
| F2 | ford_nest_a1-guilds_lodge_a1 vs ford_nest_a2-guilds_lodge_b1 | 88.1 m vs 84.5 m (4.1 %) |
| F2 | ford_nest_a1-guilds_lodge_a1 vs ford_nest_a2-guilds_lodge_a2 | 88.1 m vs 84.5 m (4.1 %) |
| F2 | home_a_a1-lairs_one_b2 vs home_a_a2-lairs_one_b1 | 143.6 m vs 149.8 m (4.1 %) |
| F2 | shrine_a1-stag_b1 vs shrine_a2-stag_b2 | 126.7 m vs 121.5 m (4.1 %) |
| F2 | rich_node_a1-cache_a_b1 vs rich_node_b1-cache_a_a1 | 135.3 m vs 129.8 m (4.1 %) |
| F2 | third_node_a1-cache_b_b1 vs third_node_a2-cache_b_b2 | 142.9 m vs 137.1 m (4.1 %) |
| F2 | shrine_a1-stag_b1 vs shrine_b1-stag_a1 | 126.7 m vs 121.5 m (4.1 %) |
| F2 | home_b_b1-guilds_den_a1 vs home_b_b2-guilds_den_a2 | 176.4 m vs 183.9 m (4.1 %) |
| F2 | stag_a1-guilds_lodge_b1 vs stag_b1-guilds_lodge_a1 | 195.9 m vs 187.9 m (4.1 %) |
| F2 | home_a_a2-lairs_one_b1 vs home_a_b1-lairs_one_a2 | 149.8 m vs 143.7 m (4.1 %) |
| F2 | ford_nest_a1-lairs_two_b1 vs ford_nest_a2-lairs_two_a1 | 124.6 m vs 119.5 m (4.1 %) |
| F2 | rich_node_a2-tower_c_a2 vs rich_node_b2-tower_c_b2 | 44.6 m vs 42.8 m (4.1 %) |
| F2 | rich_node_a1-tower_c_a1 vs rich_node_a2-tower_c_a2 | 42.8 m vs 44.6 m (4.1 %) |
| F2 | rich_node_b1-tower_c_b1 vs rich_node_b2-tower_c_b2 | 44.6 m vs 42.8 m (4.1 %) |
| F2 | rich_node_a1-tower_c_a1 vs rich_node_b1-tower_c_b1 | 42.8 m vs 44.6 m (4.1 %) |
| F2 | stag_a1-guilds_lodge_b1 vs stag_a2-guilds_lodge_b2 | 195.9 m vs 187.9 m (4.1 %) |
| F2 | stag_b1-guilds_lodge_a1 vs stag_b2-guilds_lodge_a2 | 187.9 m vs 195.9 m (4.1 %) |
| F2 | shrine_b1-guilds_den_a2 vs shrine_b2-guilds_den_a1 | 145.1 m vs 139.1 m (4.1 %) |
| F2 | shrine_a1-guilds_den_b2 vs shrine_b1-guilds_den_a2 | 139.1 m vs 145.1 m (4.1 %) |
| F2 | stag_a2-guilds_lodge_b2 vs stag_b2-guilds_lodge_a2 | 187.9 m vs 195.9 m (4.1 %) |
| F2 | tower_r_a1-ford_nest_a2 vs tower_r_b1-ford_nest_a1 | 105.2 m vs 109.7 m (4.1 %) |
| F2 | tower_r_a1-x_ford_n vs tower_r_b1-x_ford_s | 105.2 m vs 109.7 m (4.1 %) |
| F2 | rich_node_a1-guilds_den_a1 vs rich_node_b1-guilds_den_b1 | 66.7 m vs 64.0 m (4.1 %) |
| F2 | rich_node_b1-guilds_den_b1 vs rich_node_b2-guilds_den_b2 | 64.0 m vs 66.7 m (4.1 %) |
| F2 | rich_node_a1-guilds_den_a1 vs rich_node_a2-guilds_den_a2 | 66.7 m vs 64.0 m (4.1 %) |
| F2 | rich_node_a2-guilds_den_a2 vs rich_node_b2-guilds_den_b2 | 64.0 m vs 66.7 m (4.1 %) |
| F2 | home_a_a2-lairs_one_b1 vs home_a_b2-lairs_one_a1 | 149.8 m vs 143.7 m (4.1 %) |
| F2 | rich_node_a1-cache_a_b1 vs rich_node_a2-cache_a_b2 | 135.3 m vs 129.8 m (4.1 %) |
| F2 | rich_node_b1-cache_a_a1 vs rich_node_b2-cache_a_a2 | 129.8 m vs 135.3 m (4.1 %) |
| F2 | tower_c_a2-wallow_b1 vs tower_c_b2-wallow_a1 | 113.0 m vs 117.7 m (4.1 %) |
| F2 | home_b_a2-shrine_b1 vs home_b_b2-shrine_a1 | 123.5 m vs 118.5 m (4.1 %) |
| F2 | home_b_b1-shrine_a2 vs home_b_b2-shrine_a1 | 123.5 m vs 118.5 m (4.0 %) |
| F2 | stag_a1-rich_den_a2 vs stag_b1-rich_den_b2 | 120.3 m vs 125.4 m (4.0 %) |
| F2 | stag_b1-rich_den_b2 vs stag_b2-rich_den_b1 | 125.4 m vs 120.3 m (4.0 %) |
| F2 | stag_a2-rich_den_a1 vs stag_b2-rich_den_b1 | 125.4 m vs 120.3 m (4.0 %) |
| F2 | stag_a1-rich_den_a2 vs stag_a2-rich_den_a1 | 120.3 m vs 125.4 m (4.0 %) |
| F2 | rich_lodge_b1-guilds_den_b2 vs rich_lodge_b2-guilds_den_b1 | 148.9 m vs 155.1 m (4.0 %) |
| F2 | home_b_a1-cache_a_b1 vs home_b_a2-cache_a_b2 | 153.8 m vs 147.6 m (4.0 %) |
| F2 | tower_c_b1-cache_b_b2 vs tower_c_b2-cache_b_b1 | 35.5 m vs 34.1 m (4.0 %) |
| F2 | tower_c_a1-cache_b_a2 vs tower_c_b1-cache_b_b2 | 34.1 m vs 35.5 m (4.0 %) |
| F2 | tower_c_a1-cache_b_a2 vs tower_c_a2-cache_b_a1 | 34.1 m vs 35.5 m (4.0 %) |
| F2 | tower_c_a2-cache_b_a1 vs tower_c_b2-cache_b_b1 | 35.5 m vs 34.1 m (4.0 %) |
| F2 | home_b_a1-shrine_b2 vs home_b_a2-shrine_b1 | 118.5 m vs 123.5 m (4.0 %) |
| F2 | rich_lodge_b1-lairs_one_b2 vs rich_lodge_b2-lairs_one_b1 | 147.3 m vs 153.5 m (4.0 %) |
| F2 | post_w_a1-guilds_lodge_b1 vs post_w_b1-guilds_lodge_a1 | 186.7 m vs 179.2 m (4.0 %) |
| F2 | ford_nest_a1-lairs_two_b1 vs ford_nest_a2-lairs_two_b2 | 124.6 m vs 119.5 m (4.0 %) |
| F2 | home_b_a1-shrine_b2 vs home_b_b1-shrine_a2 | 118.5 m vs 123.5 m (4.0 %) |
| F2 | rich_node_a2-cache_a_b2 vs rich_node_b2-cache_a_a2 | 129.8 m vs 135.3 m (4.0 %) |
| F2 | rich_lodge_a1-guilds_den_a2 vs rich_lodge_a2-guilds_den_a1 | 155.2 m vs 149.0 m (4.0 %) |
| F2 | rich_lodge_a1-lairs_one_a2 vs rich_lodge_a2-lairs_one_a1 | 153.6 m vs 147.4 m (4.0 %) |
| F2 | home_b_a2-cache_a_b2 vs home_b_b2-cache_a_a2 | 147.6 m vs 153.7 m (4.0 %) |
| F2 | stag_a2-rich_lodge_a1 vs stag_b2-rich_lodge_b1 | 138.0 m vs 132.4 m (4.0 %) |
| F2 | shrine_a2-wallow_b2 vs shrine_b2-wallow_a2 | 145.2 m vs 151.3 m (4.0 %) |
| F2 | home_b_a1-cache_a_b1 vs home_b_b1-cache_a_a1 | 153.8 m vs 147.6 m (4.0 %) |
| F2 | rich_hollow_b1-post_w_b2 vs rich_hollow_b2-post_w_b1 | 103.4 m vs 99.3 m (4.0 %) |
| F2 | rich_hollow_a1-post_w_a2 vs rich_hollow_b1-post_w_b2 | 99.3 m vs 103.4 m (4.0 %) |
| F2 | lairs_one_a1-x_bridge_n vs lairs_one_b1-x_bridge_s | 158.7 m vs 165.3 m (4.0 %) |
| F2 | post_w_a1-lairs_one_b1 vs post_w_b1-lairs_one_a1 | 175.3 m vs 168.3 m (4.0 %) |
| F2 | keep_t3-stag_b2 vs keep_t4-stag_a2 | 153.1 m vs 159.5 m (4.0 %) |
| F2 | tower_c_a1-wallow_b2 vs tower_c_a2-wallow_b1 | 117.7 m vs 113.0 m (4.0 %) |
| F2 | keep_t1-stag_a1 vs keep_t4-stag_a2 | 153.1 m vs 159.5 m (4.0 %) |
| F2 | home_b_b1-cache_a_a1 vs home_b_b2-cache_a_a2 | 147.6 m vs 153.7 m (4.0 %) |
| F2 | tower_r_b1-ford_nest_a1 vs tower_r_b2-ford_nest_a2 | 109.7 m vs 105.3 m (4.0 %) |
| F2 | tower_r_b1-x_ford_s vs tower_r_b2-x_ford_n | 109.7 m vs 105.3 m (4.0 %) |
| F2 | tower_r_a1-ford_nest_a2 vs tower_r_a2-ford_nest_a1 | 105.2 m vs 109.6 m (4.0 %) |
| F2 | tower_r_a1-x_ford_n vs tower_r_a2-x_ford_s | 105.2 m vs 109.6 m (4.0 %) |
| F2 | well_b1-rich_hollow_a1 vs well_b2-rich_hollow_a2 | 97.8 m vs 93.9 m (4.0 %) |
| F2 | well_a1-rich_hollow_b1 vs well_b1-rich_hollow_a1 | 93.9 m vs 97.8 m (4.0 %) |
| F2 | well_a2-rich_hollow_b2 vs well_b2-rich_hollow_a2 | 97.8 m vs 93.9 m (4.0 %) |
| F2 | well_a1-rich_hollow_b1 vs well_a2-rich_hollow_b2 | 93.9 m vs 97.8 m (4.0 %) |
| F2 | cache_a_a1-lairs_two_b2 vs cache_a_a2-lairs_two_b1 | 113.1 m vs 108.6 m (4.0 %) |
| F2 | cache_a_a1-lairs_two_b2 vs cache_a_b1-lairs_two_a2 | 113.1 m vs 108.6 m (4.0 %) |
| F2 | lairs_one_b1-x_bridge_s vs lairs_one_b2-x_bridge_n | 165.3 m vs 158.7 m (4.0 %) |
| F2 | lairs_one_a1-x_bridge_n vs lairs_one_a2-x_bridge_s | 158.7 m vs 165.2 m (4.0 %) |
| F2 | post_s_a2-rich_lodge_b2 vs post_s_b1-rich_lodge_a1 | 138.9 m vs 133.4 m (4.0 %) |
| F2 | inn_a1-post_s_b2 vs inn_b2-post_s_a1 | 94.8 m vs 91.0 m (4.0 %) |
| F2 | cache_b_b1-lairs_one_b2 vs cache_b_b2-lairs_one_b1 | 119.0 m vs 123.9 m (4.0 %) |
| F2 | cache_b_a1-lairs_one_a2 vs cache_b_a2-lairs_one_a1 | 123.9 m vs 119.0 m (4.0 %) |
| F2 | cache_b_a1-lairs_one_a2 vs cache_b_b1-lairs_one_b2 | 123.9 m vs 119.0 m (4.0 %) |
| F2 | cache_b_a2-lairs_one_a1 vs cache_b_b2-lairs_one_b1 | 119.0 m vs 123.9 m (4.0 %) |
| F2 | rich_lodge_a2-guilds_den_a1 vs rich_lodge_b2-guilds_den_b1 | 149.0 m vs 155.1 m (4.0 %) |
| F2 | tower_r_a1-lairs_two_b1 vs tower_r_b1-lairs_two_a1 | 159.8 m vs 153.5 m (4.0 %) |
| F2 | post_s_a2-rich_den_a1 vs post_s_b2-rich_den_b1 | 128.3 m vs 123.2 m (4.0 %) |
| F2 | post_s_b1-rich_den_b2 vs post_s_b2-rich_den_b1 | 128.3 m vs 123.2 m (4.0 %) |
| F2 | post_s_a1-rich_den_a2 vs post_s_a2-rich_den_a1 | 123.2 m vs 128.3 m (4.0 %) |
| F2 | post_s_a1-rich_den_a2 vs post_s_b1-rich_den_b2 | 123.2 m vs 128.3 m (4.0 %) |
| F2 | tower_r_a1-lairs_two_b1 vs tower_r_a2-lairs_two_b2 | 159.8 m vs 153.5 m (4.0 %) |
| F2 | rich_lodge_a2-lairs_one_a1 vs rich_lodge_b2-lairs_one_b1 | 147.4 m vs 153.5 m (4.0 %) |
| F2 | tower_r_b1-lairs_two_a1 vs tower_r_b2-lairs_two_a2 | 153.5 m vs 159.8 m (4.0 %) |
| F2 | rich_node_a1-guilds_den_b1 vs rich_node_b1-guilds_den_a1 | 160.6 m vs 154.3 m (3.9 %) |
| F2 | tower_r_a2-lairs_two_b2 vs tower_r_b2-lairs_two_a2 | 153.5 m vs 159.8 m (3.9 %) |
| F2 | keep_t0-stag_b1 vs keep_t3-stag_b2 | 159.4 m vs 153.1 m (3.9 %) |
| F2 | post_s_a1-guilds_lodge_b1 vs post_s_b1-guilds_lodge_a1 | 202.9 m vs 194.9 m (3.9 %) |
| F2 | inn_a1-post_s_b2 vs inn_b1-post_s_a2 | 94.8 m vs 91.0 m (3.9 %) |
| F2 | keep_t1-home_a_a2 vs keep_t4-home_a_a1 | 142.3 m vs 148.1 m (3.9 %) |
| F2 | keep_t0-home_a_b2 vs keep_t1-home_a_a2 | 148.1 m vs 142.3 m (3.9 %) |
| F2 | rich_hollow_a2-post_w_a1 vs rich_hollow_b2-post_w_b1 | 103.3 m vs 99.3 m (3.9 %) |
| F2 | rich_hollow_a1-post_w_a2 vs rich_hollow_a2-post_w_a1 | 99.3 m vs 103.3 m (3.9 %) |
| F2 | rich_node_a1-lairs_one_b1 vs rich_node_b1-lairs_one_a1 | 159.0 m vs 152.7 m (3.9 %) |
| F2 | keep_t0-stag_a1 vs keep_t3-stag_a2 | 49.0 m vs 51.0 m (3.9 %) |
| F2 | keep_t0-stag_a1 vs keep_t1-stag_b1 | 49.0 m vs 51.0 m (3.9 %) |
| F2 | keep_t1-stag_b1 vs keep_t4-stag_b2 | 51.0 m vs 49.0 m (3.9 %) |
| F2 | keep_t3-stag_a2 vs keep_t4-stag_b2 | 51.0 m vs 49.0 m (3.9 %) |
| F2 | keep_t3-home_a_b1 vs keep_t4-home_a_a1 | 142.3 m vs 148.1 m (3.9 %) |
| F2 | keep_t0-home_a_b2 vs keep_t3-home_a_b1 | 148.1 m vs 142.3 m (3.9 %) |
| F2 | stag_a1-rich_lodge_a2 vs stag_a2-rich_lodge_a1 | 132.5 m vs 138.0 m (3.9 %) |
| F2 | post_s_a1-guilds_lodge_b1 vs post_s_a2-guilds_lodge_b2 | 202.9 m vs 194.9 m (3.9 %) |
| F2 | post_s_b1-guilds_lodge_a1 vs post_s_b2-guilds_lodge_a2 | 194.9 m vs 202.9 m (3.9 %) |
| F2 | post_s_a2-rich_lodge_a1 vs post_s_b2-rich_lodge_b1 | 140.9 m vs 135.3 m (3.9 %) |
| F2 | lairs_one_a2-x_bridge_s vs lairs_one_b2-x_bridge_n | 165.2 m vs 158.7 m (3.9 %) |
| F2 | keep_t0-stag_b1 vs keep_t1-stag_a1 | 159.4 m vs 153.1 m (3.9 %) |
| F2 | post_s_a2-guilds_lodge_b2 vs post_s_b2-guilds_lodge_a2 | 194.9 m vs 202.9 m (3.9 %) |
| F2 | third_node_a1-cache_b_b1 vs third_node_b2-cache_b_a2 | 142.9 m vs 137.3 m (3.9 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t1-tower_r_a1 | 138.7 m vs 133.2 m (3.9 %) |
| F2 | stag_b1-rich_lodge_b2 vs stag_b2-rich_lodge_b1 | 137.8 m vs 132.4 m (3.9 %) |
| F2 | rich_node_a1-guilds_den_b1 vs rich_node_a2-guilds_den_b2 | 160.6 m vs 154.3 m (3.9 %) |
| F2 | rich_node_b1-guilds_den_a1 vs rich_node_b2-guilds_den_a2 | 154.3 m vs 160.6 m (3.9 %) |
| F2 | tower_c_a2-rich_lodge_b2 vs tower_c_b1-rich_lodge_a1 | 61.8 m vs 59.4 m (3.9 %) |
| F2 | shrine_a1-lairs_one_b1 vs shrine_b2-lairs_one_a2 | 155.3 m vs 149.3 m (3.9 %) |
| F2 | shrine_a2-wallow_b2 vs shrine_b1-wallow_a1 | 145.2 m vs 151.1 m (3.9 %) |
| F2 | rich_node_a1-lairs_one_b1 vs rich_node_a2-lairs_one_b2 | 159.0 m vs 152.8 m (3.9 %) |
| F2 | rich_node_b1-lairs_one_a1 vs rich_node_b2-lairs_one_a2 | 152.7 m vs 158.9 m (3.9 %) |
| F2 | tower_r_a1-rich_den_b1 vs tower_r_b1-rich_den_a1 | 109.1 m vs 113.5 m (3.9 %) |
| F2 | guilds_den_a1-cache_a_b1 vs guilds_den_a2-cache_a_b2 | 187.0 m vs 194.6 m (3.9 %) |
| F2 | tower_r_a2-x_ford_s vs tower_r_b2-x_ford_n | 109.6 m vs 105.3 m (3.9 %) |
| F2 | tower_r_a2-ford_nest_a1 vs tower_r_b2-ford_nest_a2 | 109.6 m vs 105.3 m (3.9 %) |
| F2 | inn_a1-post_s_b2 vs inn_a2-post_s_b1 | 94.8 m vs 91.1 m (3.9 %) |
| F2 | keep_t0-tower_r_b1 vs keep_t3-tower_r_b2 | 138.7 m vs 133.2 m (3.9 %) |
| F2 | tower_r_a2-rich_den_a1 vs tower_r_b2-rich_den_b1 | 111.2 m vs 106.8 m (3.9 %) |
| F2 | tower_r_b1-rich_den_b2 vs tower_r_b2-rich_den_b1 | 111.2 m vs 106.8 m (3.9 %) |
| F2 | tower_r_a1-rich_den_a2 vs tower_r_a2-rich_den_a1 | 106.8 m vs 111.2 m (3.9 %) |
| F2 | tower_r_a1-rich_den_a2 vs tower_r_b1-rich_den_b2 | 106.8 m vs 111.2 m (3.9 %) |
| F2 | guilds_den_a1-cache_a_b1 vs guilds_den_b1-cache_a_a1 | 187.0 m vs 194.6 m (3.9 %) |
| F2 | rich_node_a2-guilds_den_b2 vs rich_node_b2-guilds_den_a2 | 154.3 m vs 160.6 m (3.9 %) |
| F2 | guilds_lodge_a1-cache_b_a1 vs guilds_lodge_a2-cache_b_a2 | 84.3 m vs 87.7 m (3.9 %) |
| F2 | guilds_lodge_b1-cache_b_b1 vs guilds_lodge_b2-cache_b_b2 | 87.7 m vs 84.3 m (3.9 %) |
| F2 | guilds_lodge_a1-cache_b_a1 vs guilds_lodge_b1-cache_b_b1 | 84.3 m vs 87.7 m (3.9 %) |
| F2 | guilds_lodge_a2-cache_b_a2 vs guilds_lodge_b2-cache_b_b2 | 87.7 m vs 84.3 m (3.9 %) |
| F2 | rich_node_a2-lairs_one_b2 vs rich_node_b2-lairs_one_a2 | 152.8 m vs 158.9 m (3.9 %) |
| F2 | tower_r_b1-rich_hollow_a1 vs tower_r_b2-rich_hollow_a2 | 111.7 m vs 107.4 m (3.9 %) |
| F2 | tower_r_a1-rich_hollow_b1 vs tower_r_b1-rich_hollow_a1 | 107.4 m vs 111.7 m (3.9 %) |
| F2 | tower_r_a2-rich_hollow_b2 vs tower_r_b2-rich_hollow_a2 | 111.7 m vs 107.4 m (3.9 %) |
| F2 | tower_r_a1-rich_hollow_b1 vs tower_r_a2-rich_hollow_b2 | 107.4 m vs 111.7 m (3.9 %) |
| F2 | shrine_a1-guilds_lodge_a1 vs shrine_b1-guilds_lodge_b1 | 68.7 m vs 71.5 m (3.9 %) |
| F2 | shrine_a2-guilds_lodge_a2 vs shrine_b2-guilds_lodge_b2 | 71.5 m vs 68.7 m (3.9 %) |
| F2 | shrine_b1-guilds_lodge_b1 vs shrine_b2-guilds_lodge_b2 | 71.5 m vs 68.7 m (3.9 %) |
| F2 | shrine_a1-guilds_lodge_a1 vs shrine_a2-guilds_lodge_a2 | 68.7 m vs 71.5 m (3.9 %) |
| F2 | post_s_a1-rich_lodge_a2 vs post_s_a2-rich_lodge_a1 | 135.4 m vs 140.9 m (3.9 %) |
| F2 | guilds_den_a2-cache_a_b2 vs guilds_den_b2-cache_a_a2 | 194.6 m vs 187.1 m (3.9 %) |
| F2 | tower_r_b1-rich_den_a1 vs tower_r_b2-rich_den_a2 | 113.5 m vs 109.2 m (3.8 %) |
| F2 | tower_r_a1-rich_den_b1 vs tower_r_a2-rich_den_b2 | 109.1 m vs 113.5 m (3.8 %) |
| F2 | wallow_a2-lairs_two_b2 vs wallow_b2-lairs_two_a2 | 177.5 m vs 184.6 m (3.8 %) |
| F2 | wallow_a1-lairs_two_b1 vs wallow_a2-lairs_two_b2 | 184.6 m vs 177.5 m (3.8 %) |
| F2 | stag_a1-rich_lodge_a2 vs stag_b1-rich_lodge_b2 | 132.5 m vs 137.8 m (3.8 %) |
| F2 | post_s_b1-rich_lodge_b2 vs post_s_b2-rich_lodge_b1 | 140.7 m vs 135.3 m (3.8 %) |
| F2 | guilds_den_b1-cache_a_a1 vs guilds_den_b2-cache_a_a2 | 194.6 m vs 187.1 m (3.8 %) |
| F2 | wallow_b1-lairs_two_a1 vs wallow_b2-lairs_two_a2 | 177.5 m vs 184.6 m (3.8 %) |
| F2 | wallow_a1-lairs_two_b1 vs wallow_b1-lairs_two_a1 | 184.6 m vs 177.5 m (3.8 %) |
| F2 | tower_r_a1-rich_hollow_a2 vs tower_r_b1-rich_hollow_b2 | 113.2 m vs 117.7 m (3.8 %) |
| F2 | home_b_a2-peddler_b1 vs home_b_b2-peddler_a1 | 127.9 m vs 123.0 m (3.8 %) |
| F2 | home_b_b1-peddler_a2 vs home_b_b2-peddler_a1 | 127.9 m vs 123.0 m (3.8 %) |
| F2 | post_w_a1-lairs_one_b2 vs post_w_a2-lairs_one_b1 | 156.3 m vs 162.5 m (3.8 %) |
| F2 | rich_hollow_a2-wallow_a2 vs rich_hollow_b2-wallow_b2 | 89.4 m vs 86.0 m (3.8 %) |
| F2 | tower_r_a2-rich_den_b2 vs tower_r_b2-rich_den_a2 | 113.5 m vs 109.2 m (3.8 %) |
| F2 | rich_hollow_b1-wallow_b1 vs rich_hollow_b2-wallow_b2 | 89.3 m vs 86.0 m (3.8 %) |
| F2 | stag_a2-post_w_a2 vs stag_b2-post_w_b2 | 75.7 m vs 78.6 m (3.8 %) |
| F2 | stag_b1-post_w_b1 vs stag_b2-post_w_b2 | 75.7 m vs 78.6 m (3.8 %) |
| F2 | stag_a1-post_w_a1 vs stag_a2-post_w_a2 | 78.6 m vs 75.7 m (3.8 %) |
| F2 | stag_a1-post_w_a1 vs stag_b1-post_w_b1 | 78.6 m vs 75.7 m (3.8 %) |
| F2 | rich_node_a1-post_w_b1 vs rich_node_a2-post_w_b2 | 110.2 m vs 114.5 m (3.8 %) |
| F2 | post_w_a2-lairs_one_b1 vs post_w_b1-lairs_one_a2 | 162.5 m vs 156.4 m (3.8 %) |
| F2 | post_s_a1-rich_lodge_a2 vs post_s_b1-rich_lodge_b2 | 135.4 m vs 140.7 m (3.8 %) |
| F2 | post_w_a2-lairs_one_b1 vs post_w_b2-lairs_one_a1 | 162.5 m vs 156.4 m (3.7 %) |
| F2 | stag_a1-lairs_two_a1 vs stag_a2-lairs_two_a2 | 22.1 m vs 22.9 m (3.7 %) |
| F2 | stag_a2-lairs_two_a2 vs stag_b2-lairs_two_b2 | 22.9 m vs 22.1 m (3.7 %) |
| F2 | stag_a1-lairs_two_a1 vs stag_b1-lairs_two_b1 | 22.1 m vs 22.9 m (3.7 %) |
| F2 | stag_b1-lairs_two_b1 vs stag_b2-lairs_two_b2 | 22.9 m vs 22.1 m (3.7 %) |
| F2 | well_a2-cache_b_a1 vs well_b1-cache_b_b2 | 82.2 m vs 79.2 m (3.7 %) |
| F2 | home_b_a1-post_s_b1 vs home_b_a2-post_s_b2 | 161.1 m vs 155.1 m (3.7 %) |
| F2 | rich_node_a1-post_w_b1 vs rich_node_b1-post_w_a1 | 110.2 m vs 114.4 m (3.7 %) |
| F2 | rich_node_a2-post_w_b2 vs rich_node_b2-post_w_a2 | 114.5 m vs 110.2 m (3.7 %) |
| F2 | tower_r_a1-rich_hollow_a2 vs tower_r_a2-rich_hollow_a1 | 113.2 m vs 117.6 m (3.7 %) |
| F2 | tower_r_b1-rich_hollow_b2 vs tower_r_b2-rich_hollow_b1 | 117.7 m vs 113.3 m (3.7 %) |
| F2 | well_a1-rich_lodge_b1 vs well_b1-rich_lodge_a1 | 102.2 m vs 106.1 m (3.7 %) |
| F2 | well_b1-rich_lodge_a1 vs well_b2-rich_lodge_a2 | 106.1 m vs 102.2 m (3.7 %) |
| F2 | home_b_a1-post_s_b1 vs home_b_b1-post_s_a1 | 161.1 m vs 155.1 m (3.7 %) |
| F2 | ford_nest_a1-cache_a_b1 vs ford_nest_a2-cache_a_a1 | 114.9 m vs 110.7 m (3.7 %) |
| F2 | nat_node_a1-post_s_b2 vs nat_node_b2-post_s_a1 | 103.3 m vs 99.4 m (3.7 %) |
| F2 | third_node_a1-guilds_lodge_b1 vs third_node_b1-guilds_lodge_a1 | 217.2 m vs 209.1 m (3.7 %) |
| F2 | home_b_a2-post_s_b2 vs home_b_b2-post_s_a2 | 155.1 m vs 161.1 m (3.7 %) |
| F2 | tower_c_a1-well_b1 vs tower_c_b2-well_a2 | 91.0 m vs 87.6 m (3.7 %) |
| F2 | rich_node_b1-post_w_a1 vs rich_node_b2-post_w_a2 | 114.4 m vs 110.2 m (3.7 %) |
| F2 | nat_node_a1-post_s_b2 vs nat_node_b1-post_s_a2 | 103.3 m vs 99.4 m (3.7 %) |
| F2 | keep_t1-tower_r_a1 vs keep_t4-tower_r_a2 | 133.2 m vs 138.3 m (3.7 %) |
| F2 | home_b_b1-post_s_a1 vs home_b_b2-post_s_a2 | 155.1 m vs 161.1 m (3.7 %) |
| F2 | keep_t1-peddler_a2 vs keep_t4-peddler_a1 | 135.4 m vs 140.5 m (3.7 %) |
| F2 | keep_t0-peddler_b2 vs keep_t1-peddler_a2 | 140.5 m vs 135.4 m (3.7 %) |
| F2 | keep_t3-peddler_b1 vs keep_t4-peddler_a1 | 135.4 m vs 140.5 m (3.7 %) |
| F2 | keep_t0-peddler_b2 vs keep_t3-peddler_b1 | 140.5 m vs 135.4 m (3.7 %) |
| F2 | keep_t3-tower_r_b2 vs keep_t4-tower_r_a2 | 133.2 m vs 138.3 m (3.7 %) |
| F2 | nat_node_a1-post_s_b2 vs nat_node_a2-post_s_b1 | 103.3 m vs 99.5 m (3.7 %) |
| F2 | tower_r_a1-cache_a_b1 vs tower_r_b1-cache_a_a1 | 150.1 m vs 144.6 m (3.7 %) |
| F2 | third_node_a1-guilds_lodge_b1 vs third_node_a2-guilds_lodge_b2 | 217.2 m vs 209.2 m (3.7 %) |
| F2 | tower_r_a1-cache_a_b1 vs tower_r_a2-cache_a_b2 | 150.1 m vs 144.7 m (3.7 %) |
| F2 | third_node_b1-guilds_lodge_a1 vs third_node_b2-guilds_lodge_a2 | 209.1 m vs 217.1 m (3.7 %) |
| F2 | tower_r_b1-cache_a_a1 vs tower_r_b2-cache_a_a2 | 144.6 m vs 150.1 m (3.7 %) |
| F2 | ford_nest_a1-cache_a_b1 vs ford_nest_a2-cache_a_b2 | 114.9 m vs 110.7 m (3.7 %) |
| F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_b2-cache_b_a2 | 150.7 m vs 156.4 m (3.6 %) |
| F2 | tower_r_a2-cache_a_b2 vs tower_r_b2-cache_a_a2 | 144.7 m vs 150.1 m (3.6 %) |
| F2 | tower_r_a2-rich_hollow_a1 vs tower_r_b2-rich_hollow_b1 | 117.6 m vs 113.3 m (3.6 %) |
| F2 | tower_r_a1-stag_a2 vs tower_r_b1-stag_b2 | 153.0 m vs 147.4 m (3.6 %) |
| F2 | keep_t0-home_b_b2 vs keep_t1-home_b_a2 | 129.0 m vs 133.9 m (3.6 %) |
| F2 | home_a_a1-post_s_b1 vs home_a_b2-post_s_a2 | 149.0 m vs 154.6 m (3.6 %) |
| F2 | tower_r_a1-stag_a2 vs tower_r_a2-stag_a1 | 153.0 m vs 147.4 m (3.6 %) |
| F2 | tower_r_a2-rich_lodge_b2 vs tower_r_b2-rich_lodge_a2 | 120.0 m vs 115.6 m (3.6 %) |
| F2 | tower_r_a1-rich_lodge_b1 vs tower_r_a2-rich_lodge_b2 | 115.6 m vs 120.0 m (3.6 %) |
| F2 | tower_r_b1-rich_lodge_a1 vs tower_r_b2-rich_lodge_a2 | 120.0 m vs 115.6 m (3.6 %) |
| F2 | tower_r_a1-rich_lodge_b1 vs tower_r_b1-rich_lodge_a1 | 115.6 m vs 120.0 m (3.6 %) |
| F2 | home_a_b1-post_s_a1 vs home_a_b2-post_s_a2 | 149.0 m vs 154.6 m (3.6 %) |
| F2 | home_a_a2-post_s_b2 vs home_a_b2-post_s_a2 | 149.0 m vs 154.6 m (3.6 %) |
| F2 | third_node_a2-guilds_lodge_b2 vs third_node_b2-guilds_lodge_a2 | 209.2 m vs 217.1 m (3.6 %) |
| F2 | ford_nest_a1-guilds_den_b1 vs ford_nest_a2-guilds_den_a1 | 140.2 m vs 135.1 m (3.6 %) |
| F2 | ford_nest_a1-lairs_one_b1 vs ford_nest_a2-lairs_one_a1 | 138.6 m vs 133.6 m (3.6 %) |
| F2 | tower_r_a1-guilds_den_b1 vs tower_r_b1-guilds_den_a1 | 175.4 m vs 169.1 m (3.6 %) |
| F2 | tower_r_a2-rich_lodge_a1 vs tower_r_b2-rich_lodge_b1 | 123.4 m vs 118.9 m (3.6 %) |
| F2 | tower_r_a1-guilds_den_b1 vs tower_r_a2-guilds_den_b2 | 175.4 m vs 169.1 m (3.6 %) |
| F2 | tower_r_b1-guilds_den_a1 vs tower_r_b2-guilds_den_a2 | 169.1 m vs 175.4 m (3.6 %) |
| F2 | post_w_a1-guilds_lodge_b1 vs post_w_a2-guilds_lodge_b2 | 186.7 m vs 180.0 m (3.6 %) |
| F2 | tower_r_a1-lairs_one_b1 vs tower_r_b1-lairs_one_a1 | 173.8 m vs 167.6 m (3.6 %) |
| F2 | tower_r_a2-guilds_den_b2 vs tower_r_b2-guilds_den_a2 | 169.1 m vs 175.4 m (3.6 %) |
| F2 | tower_r_a1-lairs_one_b1 vs tower_r_a2-lairs_one_b2 | 173.8 m vs 167.6 m (3.6 %) |
| F2 | tower_r_b1-lairs_one_a1 vs tower_r_b2-lairs_one_a2 | 167.6 m vs 173.8 m (3.6 %) |
| F2 | guilds_lodge_a1-guilds_lodge_b1 vs guilds_lodge_b2-guilds_lodge_a2 | 224.9 m vs 216.9 m (3.6 %) |
| F2 | home_a_a1-wallow_b2 vs home_a_b1-wallow_a2 | 147.3 m vs 152.7 m (3.6 %) |
| F2 | peddler_a1-lairs_one_b1 vs peddler_b2-lairs_one_a2 | 170.5 m vs 164.4 m (3.6 %) |
| F2 | tower_r_a2-lairs_one_b2 vs tower_r_b2-lairs_one_a2 | 167.6 m vs 173.8 m (3.6 %) |
| F2 | home_a_a1-wallow_b2 vs home_a_a2-wallow_b1 | 147.3 m vs 152.7 m (3.6 %) |
| F2 | ford_nest_a1-guilds_den_b1 vs ford_nest_a2-guilds_den_b2 | 140.2 m vs 135.2 m (3.6 %) |
| F2 | tower_c_a2-guilds_lodge_b1 vs tower_c_b2-guilds_lodge_a1 | 118.7 m vs 123.1 m (3.6 %) |
| F2 | third_node_a1-x_bridge_n vs third_node_b1-x_bridge_s | 147.1 m vs 152.6 m (3.6 %) |
| F2 | third_node_a1-x_bridge_n vs third_node_a2-x_bridge_s | 147.1 m vs 152.6 m (3.6 %) |
| F2 | third_node_a1-well_a1 vs third_node_b1-well_b1 | 38.9 m vs 40.3 m (3.6 %) |
| F2 | third_node_a1-well_a1 vs third_node_a2-well_a2 | 38.9 m vs 40.3 m (3.6 %) |
| F2 | third_node_b1-well_b1 vs third_node_b2-well_b2 | 40.3 m vs 38.9 m (3.6 %) |
| F2 | third_node_a2-well_a2 vs third_node_b2-well_b2 | 40.3 m vs 38.9 m (3.6 %) |
| F2 | keep_t1-lairs_one_b2 vs keep_t4-lairs_one_b1 | 122.3 m vs 126.8 m (3.6 %) |
| F2 | keep_t3-lairs_one_a1 vs keep_t4-lairs_one_b1 | 122.3 m vs 126.8 m (3.6 %) |
| F2 | keep_t0-lairs_one_a2 vs keep_t1-lairs_one_b2 | 126.8 m vs 122.3 m (3.6 %) |
| F2 | keep_t0-lairs_one_a2 vs keep_t3-lairs_one_a1 | 126.8 m vs 122.3 m (3.6 %) |
| F2 | inn_a1-guilds_lodge_b2 vs inn_b1-guilds_lodge_a2 | 120.4 m vs 116.2 m (3.6 %) |
| F2 | inn_a1-guilds_lodge_b2 vs inn_a2-guilds_lodge_b1 | 120.4 m vs 116.2 m (3.6 %) |
| F2 | rich_lodge_a2-guilds_den_b1 vs rich_lodge_b2-guilds_den_a1 | 73.1 m vs 75.8 m (3.6 %) |
| F2 | rich_lodge_a1-guilds_den_b2 vs rich_lodge_a2-guilds_den_b1 | 75.8 m vs 73.1 m (3.6 %) |
| F2 | rich_lodge_b1-guilds_den_a2 vs rich_lodge_b2-guilds_den_a1 | 73.1 m vs 75.8 m (3.6 %) |
| F2 | rich_lodge_a1-guilds_den_b2 vs rich_lodge_b1-guilds_den_a2 | 75.8 m vs 73.1 m (3.6 %) |
| F2 | ford_nest_a1-lairs_one_b1 vs ford_nest_a2-lairs_one_b2 | 138.6 m vs 133.7 m (3.6 %) |
| F2 | well_a1-cache_a_b1 vs well_a2-cache_a_b2 | 144.1 m vs 149.4 m (3.5 %) |
| F2 | third_node_b1-x_bridge_s vs third_node_b2-x_bridge_n | 152.6 m vs 147.2 m (3.5 %) |
| F2 | third_node_a2-x_bridge_s vs third_node_b2-x_bridge_n | 152.6 m vs 147.2 m (3.5 %) |
| F2 | tower_r_b1-rich_lodge_b2 vs tower_r_b2-rich_lodge_b1 | 123.3 m vs 118.9 m (3.5 %) |
| F2 | cache_a_a1-cache_a_b2 vs cache_a_a2-cache_a_b1 | 98.4 m vs 95.0 m (3.5 %) |
| F2 | guilds_den_a1-lairs_one_b1 vs guilds_den_a2-lairs_one_b2 | 209.9 m vs 217.6 m (3.5 %) |
| F2 | third_node_a2-well_b2 vs third_node_b1-well_a1 | 164.2 m vs 170.2 m (3.5 %) |
| F2 | tower_r_a1-rich_lodge_a2 vs tower_r_a2-rich_lodge_a1 | 119.0 m vs 123.4 m (3.5 %) |
| F2 | stag_a1-lairs_two_b1 vs stag_b1-lairs_two_a1 | 181.5 m vs 175.1 m (3.5 %) |
| F2 | third_node_b1-well_a1 vs third_node_b2-well_a2 | 170.2 m vs 176.3 m (3.5 %) |
| F2 | tower_c_b1-guilds_lodge_a2 vs tower_c_b2-guilds_lodge_a1 | 118.8 m vs 123.1 m (3.5 %) |
| F2 | keep_t0-post_s_b1 vs keep_t4-post_s_a2 | 160.7 m vs 166.5 m (3.5 %) |
| F2 | guilds_den_a1-lairs_one_b1 vs guilds_den_b1-lairs_one_a1 | 209.9 m vs 217.5 m (3.5 %) |
| F2 | post_w_a1-lairs_one_b1 vs post_w_a2-lairs_one_b2 | 175.3 m vs 169.2 m (3.5 %) |
| F2 | inn_a1-lairs_one_b2 vs inn_b2-lairs_one_a1 | 110.2 m vs 106.4 m (3.5 %) |
| F2 | stag_a1-lairs_two_b1 vs stag_a2-lairs_two_b2 | 181.5 m vs 175.1 m (3.5 %) |
| F2 | stag_b1-lairs_two_a1 vs stag_b2-lairs_two_a2 | 175.1 m vs 181.5 m (3.5 %) |
| F2 | home_a_b1-wallow_a2 vs home_a_b2-wallow_a1 | 152.7 m vs 147.4 m (3.5 %) |
| F2 | post_w_a1-lairs_one_b1 vs post_w_b2-lairs_one_a2 | 175.3 m vs 169.2 m (3.5 %) |
| F2 | home_a_a2-wallow_b1 vs home_a_b2-wallow_a1 | 152.7 m vs 147.4 m (3.5 %) |
| F2 | stag_a2-lairs_two_b2 vs stag_b2-lairs_two_a2 | 175.1 m vs 181.5 m (3.5 %) |
| F2 | guilds_den_a2-lairs_one_b2 vs guilds_den_b2-lairs_one_a2 | 217.6 m vs 210.0 m (3.5 %) |
| F2 | inn_a1-lairs_one_b2 vs inn_b1-lairs_one_a2 | 110.2 m vs 106.4 m (3.5 %) |
| F2 | well_a1-cache_a_b1 vs well_b1-cache_a_a1 | 144.1 m vs 149.3 m (3.5 %) |
| F2 | home_a_a1-lairs_one_b1 vs home_a_b2-lairs_one_a2 | 176.2 m vs 170.1 m (3.5 %) |
| F2 | guilds_den_b1-lairs_one_a1 vs guilds_den_b2-lairs_one_a2 | 217.5 m vs 210.0 m (3.5 %) |
| F2 | well_a2-cache_a_b2 vs well_b2-cache_a_a2 | 149.4 m vs 144.3 m (3.5 %) |
| F2 | keep_t0-cache_a_b1 vs keep_t3-cache_a_b2 | 157.0 m vs 151.6 m (3.5 %) |
| F2 | keep_t0-x_bridge_n vs keep_t1-x_bridge_s | 120.7 m vs 125.0 m (3.4 %) |
| F2 | keep_t0-x_bridge_n vs keep_t3-x_bridge_s | 120.7 m vs 125.0 m (3.4 %) |
| F2 | tower_r_a1-rich_lodge_a2 vs tower_r_b1-rich_lodge_b2 | 119.0 m vs 123.3 m (3.4 %) |
| F2 | keep_t3-cache_a_b2 vs keep_t4-cache_a_a2 | 151.6 m vs 157.0 m (3.4 %) |
| F2 | stag_a2-cache_a_b1 vs stag_b1-cache_a_a2 | 86.3 m vs 83.3 m (3.4 %) |
| F2 | inn_a1-lairs_one_b2 vs inn_a2-lairs_one_b1 | 110.2 m vs 106.4 m (3.4 %) |
| F2 | stag_a1-cache_a_b2 vs stag_b1-cache_a_a2 | 86.3 m vs 83.3 m (3.4 %) |
| F2 | stag_b1-cache_a_a2 vs stag_b2-cache_a_a1 | 83.3 m vs 86.3 m (3.4 %) |
| F2 | home_a_a2-wallow_b2 vs home_a_b1-wallow_a1 | 166.7 m vs 172.6 m (3.4 %) |
| F2 | keep_t0-cache_a_b1 vs keep_t1-cache_a_a1 | 157.0 m vs 151.6 m (3.4 %) |
| F2 | stag_a1-rich_lodge_b1 vs stag_b1-rich_lodge_a1 | 129.0 m vs 133.6 m (3.4 %) |
| F2 | stag_b1-rich_lodge_a1 vs stag_b2-rich_lodge_a2 | 133.6 m vs 129.0 m (3.4 %) |
| F2 | nat_node_b1-stag_b1 vs nat_node_b2-stag_b2 | 56.0 m vs 57.9 m (3.4 %) |
| F2 | nat_node_a1-stag_a1 vs nat_node_b1-stag_b1 | 57.9 m vs 56.0 m (3.4 %) |
| F2 | nat_node_a1-stag_a1 vs nat_node_a2-stag_a2 | 57.9 m vs 56.0 m (3.4 %) |
| F2 | nat_node_a2-stag_a2 vs nat_node_b2-stag_b2 | 56.0 m vs 57.9 m (3.4 %) |
| F2 | rich_node_a1-third_node_a2 vs rich_node_a2-third_node_a1 | 129.7 m vs 134.3 m (3.4 %) |
| F2 | rich_node_a2-third_node_a1 vs rich_node_b2-third_node_b1 | 134.3 m vs 129.7 m (3.4 %) |
| F2 | rich_node_b1-third_node_b2 vs rich_node_b2-third_node_b1 | 134.3 m vs 129.7 m (3.4 %) |
| F2 | rich_node_a1-third_node_a2 vs rich_node_b1-third_node_b2 | 129.7 m vs 134.3 m (3.4 %) |
| F2 | keep_t1-x_bridge_s vs keep_t4-x_bridge_n | 125.0 m vs 120.8 m (3.4 %) |
| F2 | keep_t3-x_bridge_s vs keep_t4-x_bridge_n | 125.0 m vs 120.8 m (3.4 %) |
| F2 | keep_t1-cache_a_a1 vs keep_t4-cache_a_a2 | 151.6 m vs 157.0 m (3.4 %) |
| F2 | rich_node_a1-guilds_lodge_a2 vs rich_node_a2-guilds_lodge_a1 | 137.7 m vs 142.5 m (3.4 %) |
| F2 | rich_node_b1-guilds_lodge_b2 vs rich_node_b2-guilds_lodge_b1 | 142.5 m vs 137.7 m (3.4 %) |
| F2 | rich_node_a1-guilds_lodge_a2 vs rich_node_b1-guilds_lodge_b2 | 137.7 m vs 142.5 m (3.4 %) |
| F2 | rich_node_a2-guilds_lodge_a1 vs rich_node_b2-guilds_lodge_b1 | 142.5 m vs 137.7 m (3.4 %) |
| F2 | keep_t0-home_b_b1 vs keep_t1-home_b_a1 | 153.9 m vs 159.3 m (3.4 %) |
| F2 | keep_t1-home_b_a1 vs keep_t4-home_b_a2 | 159.3 m vs 153.9 m (3.4 %) |
| F2 | well_b1-cache_a_a1 vs well_b2-cache_a_a2 | 149.3 m vs 144.3 m (3.4 %) |
| F2 | rich_node_a2-lairs_one_a2 vs rich_node_b2-lairs_one_b2 | 56.5 m vs 58.5 m (3.4 %) |
| F2 | rich_node_a1-lairs_one_a1 vs rich_node_a2-lairs_one_a2 | 58.5 m vs 56.5 m (3.4 %) |
| F2 | rich_node_a1-lairs_one_a1 vs rich_node_b1-lairs_one_b1 | 58.5 m vs 56.5 m (3.4 %) |
| F2 | rich_node_b1-lairs_one_b1 vs rich_node_b2-lairs_one_b2 | 56.5 m vs 58.5 m (3.4 %) |
| F2 | ford_nest_a1-stag_b1 vs ford_nest_a2-stag_b2 | 118.5 m vs 122.6 m (3.4 %) |
| F2 | cache_a_a1-x_bridge_n vs cache_a_a2-x_bridge_s | 145.3 m vs 140.4 m (3.4 %) |
| F2 | cache_a_a2-x_bridge_s vs cache_a_b2-x_bridge_n | 140.4 m vs 145.3 m (3.4 %) |
| F2 | post_s_a1-lairs_two_b1 vs post_s_b1-lairs_two_a1 | 188.5 m vs 182.1 m (3.4 %) |
| F2 | post_s_a1-lairs_two_b1 vs post_s_a2-lairs_two_b2 | 188.5 m vs 182.1 m (3.4 %) |
| F2 | post_s_b1-lairs_two_a1 vs post_s_b2-lairs_two_a2 | 182.1 m vs 188.4 m (3.4 %) |
| F2 | post_s_a2-lairs_two_b2 vs post_s_b2-lairs_two_a2 | 182.1 m vs 188.4 m (3.3 %) |
| F2 | nat_node_b1-lairs_one_a2 vs nat_node_b2-lairs_one_a1 | 114.8 m vs 118.8 m (3.3 %) |
| F2 | tower_r_a1-post_w_b1 vs tower_r_a2-post_w_b2 | 125.0 m vs 129.3 m (3.3 %) |
| F2 | tower_r_a1-post_w_b1 vs tower_r_b1-post_w_a1 | 125.0 m vs 129.3 m (3.3 %) |
| F2 | cache_a_a1-cache_b_b2 vs cache_a_b1-cache_b_a2 | 69.2 m vs 66.9 m (3.3 %) |
| F2 | tower_r_a1-cache_a_a2 vs tower_r_b1-cache_a_b2 | 140.7 m vs 136.0 m (3.3 %) |
| F2 | tower_r_b1-cache_a_b2 vs tower_r_b2-cache_a_b1 | 136.0 m vs 140.7 m (3.3 %) |
| F2 | wallow_a2-post_s_b2 vs wallow_b2-post_s_a2 | 170.7 m vs 176.5 m (3.3 %) |
| F2 | cache_a_b1-x_bridge_s vs cache_a_b2-x_bridge_n | 140.4 m vs 145.3 m (3.3 %) |
| F2 | cache_a_a1-x_bridge_n vs cache_a_b1-x_bridge_s | 145.3 m vs 140.4 m (3.3 %) |
| F2 | wallow_b1-post_s_a1 vs wallow_b2-post_s_a2 | 170.7 m vs 176.5 m (3.3 %) |
| F2 | tower_r_a2-cache_a_a1 vs tower_r_b2-cache_a_b1 | 136.0 m vs 140.7 m (3.3 %) |
| F2 | tower_r_a1-cache_a_a2 vs tower_r_a2-cache_a_a1 | 140.7 m vs 136.0 m (3.3 %) |
| F2 | lairs_two_a1-lairs_two_b1 vs lairs_two_b2-lairs_two_a2 | 192.6 m vs 186.2 m (3.3 %) |
| F2 | guilds_den_a1-cache_a_a2 vs guilds_den_b1-cache_a_b2 | 150.6 m vs 145.6 m (3.3 %) |
| F2 | guilds_den_a1-cache_a_a2 vs guilds_den_a2-cache_a_a1 | 150.6 m vs 145.6 m (3.3 %) |
| F2 | guilds_den_b1-cache_a_b2 vs guilds_den_b2-cache_a_b1 | 145.6 m vs 150.6 m (3.3 %) |
| F2 | guilds_den_a2-cache_a_a1 vs guilds_den_b2-cache_a_b1 | 145.6 m vs 150.6 m (3.3 %) |
| F2 | rich_node_a2-stag_a1 vs rich_node_b2-stag_b1 | 132.3 m vs 127.9 m (3.3 %) |
| F2 | rich_node_b1-stag_b2 vs rich_node_b2-stag_b1 | 132.3 m vs 127.9 m (3.3 %) |
| F2 | well_a2-crown vs well_b2-crown | 66.1 m vs 63.9 m (3.3 %) |
| F2 | well_a1-crown vs well_b1-crown | 63.9 m vs 66.1 m (3.3 %) |
| F2 | well_a1-crown vs well_a2-crown | 63.9 m vs 66.1 m (3.3 %) |
| F2 | well_b1-crown vs well_b2-crown | 66.1 m vs 63.9 m (3.3 %) |
| F2 | tower_r_a2-post_w_b2 vs tower_r_b2-post_w_a2 | 129.3 m vs 125.1 m (3.3 %) |
| F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_b1-guilds_lodge_a1 | 223.6 m vs 216.2 m (3.3 %) |
| F2 | nat_node_a1-lairs_one_b2 vs nat_node_b1-lairs_one_a2 | 118.7 m vs 114.8 m (3.3 %) |
| F2 | tower_r_b1-post_w_a1 vs tower_r_b2-post_w_a2 | 129.3 m vs 125.1 m (3.3 %) |
| F2 | peddler_a1-x_bridge_n vs peddler_b1-x_bridge_s | 103.2 m vs 106.7 m (3.3 %) |
| F2 | peddler_a1-x_bridge_n vs peddler_a2-x_bridge_s | 103.2 m vs 106.7 m (3.3 %) |
| F2 | nat_node_a1-guilds_lodge_b2 vs nat_node_b1-guilds_lodge_a2 | 128.7 m vs 124.5 m (3.3 %) |
| F2 | nat_node_a1-guilds_lodge_b2 vs nat_node_a2-guilds_lodge_b1 | 128.7 m vs 124.5 m (3.3 %) |
| F2 | guilds_den_a1-guilds_lodge_b1 vs guilds_den_a2-guilds_lodge_b2 | 223.6 m vs 216.3 m (3.3 %) |
| F2 | well_a1-stag_b1 vs well_b1-stag_a1 | 145.7 m vs 150.6 m (3.3 %) |
| F2 | stag_a1-x_bridge_n vs stag_a2-x_bridge_s | 155.1 m vs 150.0 m (3.3 %) |
| F2 | stag_a2-x_bridge_s vs stag_b2-x_bridge_n | 150.0 m vs 155.1 m (3.3 %) |
| F2 | guilds_den_b1-guilds_lodge_a1 vs guilds_den_b2-guilds_lodge_a2 | 216.2 m vs 223.5 m (3.2 %) |
| F2 | inn_a1-rich_lodge_b2 vs inn_b2-rich_lodge_a1 | 36.9 m vs 35.7 m (3.2 %) |
| F2 | inn_a1-rich_lodge_b2 vs inn_a2-rich_lodge_b1 | 36.9 m vs 35.7 m (3.2 %) |
| F2 | inn_a1-rich_lodge_b2 vs inn_b1-rich_lodge_a2 | 36.9 m vs 35.7 m (3.2 %) |
| F2 | home_b_a1-wallow_b2 vs home_b_b1-wallow_a2 | 139.3 m vs 143.9 m (3.2 %) |
| F2 | peddler_b1-x_bridge_s vs peddler_b2-x_bridge_n | 106.7 m vs 103.2 m (3.2 %) |
| F2 | peddler_a2-x_bridge_s vs peddler_b2-x_bridge_n | 106.7 m vs 103.2 m (3.2 %) |
| F2 | guilds_den_a2-guilds_lodge_b2 vs guilds_den_b2-guilds_lodge_a2 | 216.3 m vs 223.5 m (3.2 %) |
| F2 | keep_t0-lairs_one_b1 vs keep_t4-lairs_one_a2 | 188.0 m vs 181.9 m (3.2 %) |
| F2 | well_a1-stag_b1 vs well_a2-stag_b2 | 145.7 m vs 150.5 m (3.2 %) |
| F2 | wallow_a1-guilds_lodge_b1 vs wallow_b2-guilds_lodge_a2 | 202.0 m vs 208.7 m (3.2 %) |
| F2 | stag_a1-cache_a_b1 vs stag_b1-cache_a_a1 | 171.8 m vs 166.3 m (3.2 %) |
| F2 | keep_t0-wallow_b2 vs keep_t3-wallow_b1 | 153.5 m vs 158.6 m (3.2 %) |
| F2 | stag_a1-guilds_den_b1 vs stag_b1-guilds_den_a1 | 197.1 m vs 190.8 m (3.2 %) |
| F2 | stag_b1-x_bridge_s vs stag_b2-x_bridge_n | 150.1 m vs 155.1 m (3.2 %) |
| F2 | stag_a1-x_bridge_n vs stag_b1-x_bridge_s | 155.1 m vs 150.1 m (3.2 %) |
| F2 | stag_a1-cache_a_b1 vs stag_a2-cache_a_b2 | 171.8 m vs 166.3 m (3.2 %) |
| F2 | stag_b1-cache_a_a1 vs stag_b2-cache_a_a2 | 166.3 m vs 171.8 m (3.2 %) |
| F2 | keep_t0-wallow_b2 vs keep_t4-wallow_a1 | 153.5 m vs 158.5 m (3.2 %) |
| F2 | post_w_b1-guilds_den_a1 vs post_w_b2-guilds_den_a2 | 172.4 m vs 178.1 m (3.2 %) |
| F2 | post_w_a2-guilds_den_b2 vs post_w_b2-guilds_den_a2 | 172.4 m vs 178.1 m (3.2 %) |
| F2 | stag_a1-guilds_den_b1 vs stag_a2-guilds_den_b2 | 197.1 m vs 190.8 m (3.2 %) |
| F2 | stag_b1-guilds_den_a1 vs stag_b2-guilds_den_a2 | 190.8 m vs 197.1 m (3.2 %) |
| F2 | stag_a2-cache_a_b2 vs stag_b2-cache_a_a2 | 166.3 m vs 171.8 m (3.2 %) |
| F2 | stag_a2-guilds_den_b2 vs stag_b2-guilds_den_a2 | 190.8 m vs 197.1 m (3.2 %) |
| F2 | cache_a_b1-cache_b_a1 vs cache_a_b2-cache_b_a2 | 118.3 m vs 122.2 m (3.2 %) |
| F2 | cache_a_a1-cache_b_b2 vs cache_a_a2-cache_b_b1 | 69.2 m vs 67.0 m (3.2 %) |
| F2 | well_b1-stag_a1 vs well_b2-stag_a2 | 150.6 m vs 145.8 m (3.2 %) |
| F2 | post_s_a2-cache_a_b1 vs post_s_b1-cache_a_a2 | 93.3 m vs 90.3 m (3.2 %) |
| F2 | post_s_a1-cache_a_b2 vs post_s_b1-cache_a_a2 | 93.3 m vs 90.3 m (3.2 %) |
| F2 | post_s_b1-cache_a_a2 vs post_s_b2-cache_a_a1 | 90.3 m vs 93.3 m (3.2 %) |
| F2 | cache_a_b1-cache_b_a2 vs cache_a_b2-cache_b_a1 | 66.9 m vs 69.1 m (3.2 %) |
| F2 | tower_r_a1-x_bridge_n vs tower_r_b1-x_bridge_s | 133.0 m vs 137.4 m (3.2 %) |
| F2 | well_a2-stag_b2 vs well_b2-stag_a2 | 150.5 m vs 145.8 m (3.2 %) |
| F2 | third_node_a1-lairs_two_b1 vs third_node_b1-lairs_two_a1 | 202.7 m vs 196.3 m (3.2 %) |
| F2 | home_a_a1-home_a_b2 vs home_a_a2-home_a_b1 | 142.3 m vs 137.8 m (3.2 %) |
| F2 | lairs_two_a1-crown vs lairs_two_a2-crown | 92.6 m vs 95.6 m (3.1 %) |
| F2 | lairs_two_a2-crown vs lairs_two_b2-crown | 95.6 m vs 92.6 m (3.1 %) |
| F2 | lairs_two_a1-crown vs lairs_two_b1-crown | 92.6 m vs 95.6 m (3.1 %) |
| F2 | lairs_two_b1-crown vs lairs_two_b2-crown | 95.6 m vs 92.6 m (3.1 %) |
| F2 | well_a1-post_s_b1 vs well_b1-post_s_a1 | 151.7 m vs 156.6 m (3.1 %) |
| F2 | post_s_a1-x_bridge_n vs post_s_a2-x_bridge_s | 157.9 m vs 152.9 m (3.1 %) |
| F2 | post_s_a2-x_bridge_s vs post_s_b2-x_bridge_n | 152.9 m vs 157.9 m (3.1 %) |
| F2 | shrine_a2-guilds_den_b1 vs shrine_b1-guilds_den_a2 | 149.8 m vs 145.1 m (3.1 %) |
| F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_b1-cache_b_a1 | 150.7 m vs 145.9 m (3.1 %) |
| F2 | tower_r_b1-x_bridge_s vs tower_r_b2-x_bridge_n | 137.4 m vs 133.1 m (3.1 %) |
| F2 | home_a_b1-stag_a1 vs home_a_b2-stag_a2 | 143.0 m vs 147.6 m (3.1 %) |
| F2 | home_a_a2-stag_b2 vs home_a_b2-stag_a2 | 143.0 m vs 147.6 m (3.1 %) |
| F2 | tower_r_a1-x_bridge_n vs tower_r_a2-x_bridge_s | 133.0 m vs 137.3 m (3.1 %) |
| F2 | cache_a_a2-cache_b_b2 vs cache_a_b2-cache_b_a2 | 118.4 m vs 122.2 m (3.1 %) |
| F2 | guilds_lodge_a1-cache_b_b1 vs guilds_lodge_a2-cache_b_b2 | 150.7 m vs 146.0 m (3.1 %) |
| F2 | well_a1-post_s_b1 vs well_a2-post_s_b2 | 151.7 m vs 156.6 m (3.1 %) |
| F2 | post_s_a2-rich_den_a2 vs post_s_b1-rich_den_b1 | 57.0 m vs 58.8 m (3.1 %) |
| F2 | third_node_a1-lairs_two_b1 vs third_node_a2-lairs_two_b2 | 202.7 m vs 196.4 m (3.1 %) |
| F2 | third_node_b1-lairs_two_a1 vs third_node_b2-lairs_two_a2 | 196.3 m vs 202.6 m (3.1 %) |
| F2 | post_s_a1-x_bridge_n vs post_s_b1-x_bridge_s | 157.9 m vs 153.0 m (3.1 %) |
| F2 | post_s_b1-x_bridge_s vs post_s_b2-x_bridge_n | 153.0 m vs 157.9 m (3.1 %) |
| F2 | wallow_b1-ford_nest_a2 vs wallow_b2-ford_nest_a1 | 80.4 m vs 78.0 m (3.1 %) |
| F2 | wallow_a2-x_ford_n vs wallow_b2-x_ford_s | 80.4 m vs 78.0 m (3.1 %) |
| F2 | wallow_b1-x_ford_n vs wallow_b2-x_ford_s | 80.4 m vs 78.0 m (3.1 %) |
| F2 | wallow_a2-ford_nest_a2 vs wallow_b2-ford_nest_a1 | 80.4 m vs 78.0 m (3.1 %) |
| F2 | wallow_a1-x_ford_s vs wallow_b1-x_ford_n | 78.0 m vs 80.4 m (3.1 %) |
| F2 | wallow_a1-x_ford_s vs wallow_a2-x_ford_n | 78.0 m vs 80.4 m (3.1 %) |
| F2 | wallow_a1-ford_nest_a1 vs wallow_a2-ford_nest_a2 | 78.0 m vs 80.4 m (3.1 %) |
| F2 | wallow_a1-ford_nest_a1 vs wallow_b1-ford_nest_a2 | 78.0 m vs 80.4 m (3.1 %) |
| F2 | post_s_a1-guilds_den_b1 vs post_s_b1-guilds_den_a1 | 204.1 m vs 197.8 m (3.1 %) |
| F2 | post_s_a1-guilds_den_b1 vs post_s_a2-guilds_den_b2 | 204.1 m vs 197.8 m (3.1 %) |
| F2 | post_s_b1-guilds_den_a1 vs post_s_b2-guilds_den_a2 | 197.8 m vs 204.1 m (3.1 %) |
| F2 | well_b1-post_s_a1 vs well_b2-post_s_a2 | 156.6 m vs 151.8 m (3.1 %) |
| F2 | keep_t3-home_b_b2 vs keep_t4-home_b_a2 | 149.2 m vs 153.9 m (3.1 %) |
| F2 | keep_t0-home_b_b1 vs keep_t3-home_b_b2 | 153.9 m vs 149.2 m (3.1 %) |
| F2 | post_s_a2-guilds_den_b2 vs post_s_b2-guilds_den_a2 | 197.8 m vs 204.1 m (3.1 %) |
| F2 | tower_r_a2-x_bridge_s vs tower_r_b2-x_bridge_n | 137.3 m vs 133.1 m (3.1 %) |
| F2 | guilds_lodge_a1-lairs_two_b1 vs guilds_lodge_b1-lairs_two_a1 | 210.4 m vs 204.0 m (3.1 %) |
| F2 | wallow_a1-lairs_one_b1 vs wallow_b2-lairs_one_a2 | 198.1 m vs 192.0 m (3.1 %) |
| F2 | well_a1-lairs_one_b1 vs well_a2-lairs_one_b2 | 167.0 m vs 172.3 m (3.1 %) |
| F2 | tower_r_a1-tower_r_a2 vs tower_r_b2-tower_r_b1 | 130.6 m vs 134.7 m (3.1 %) |
| F2 | home_a_a1-guilds_lodge_b2 vs home_a_b1-guilds_lodge_a2 | 158.5 m vs 153.6 m (3.1 %) |
| F2 | home_a_a1-stag_b1 vs home_a_b1-stag_a1 | 147.6 m vs 143.0 m (3.1 %) |
| F2 | home_a_a1-stag_b1 vs home_a_a2-stag_b2 | 147.6 m vs 143.0 m (3.1 %) |
| F2 | cache_a_a1-crown vs cache_a_b1-crown | 81.4 m vs 84.0 m (3.1 %) |
| F2 | cache_a_b1-crown vs cache_a_b2-crown | 84.0 m vs 81.4 m (3.1 %) |
| F2 | cache_a_a1-crown vs cache_a_a2-crown | 81.4 m vs 84.0 m (3.1 %) |
| F2 | cache_a_a2-crown vs cache_a_b2-crown | 84.0 m vs 81.4 m (3.1 %) |
| F2 | wallow_a1-cache_b_b1 vs wallow_b1-cache_b_a1 | 127.8 m vs 123.9 m (3.1 %) |
| F2 | well_a2-post_s_b2 vs well_b2-post_s_a2 | 156.6 m vs 151.8 m (3.1 %) |
| F2 | third_node_a2-lairs_two_b2 vs third_node_b2-lairs_two_a2 | 196.4 m vs 202.6 m (3.0 %) |
| F2 | home_b_a2-rich_lodge_b1 vs home_b_b2-rich_lodge_a1 | 60.2 m vs 58.3 m (3.0 %) |
| F2 | home_b_a1-rich_lodge_b2 vs home_b_a2-rich_lodge_b1 | 58.3 m vs 60.2 m (3.0 %) |
| F2 | home_b_b1-rich_lodge_a2 vs home_b_b2-rich_lodge_a1 | 60.2 m vs 58.3 m (3.0 %) |
| F2 | home_b_a1-rich_lodge_b2 vs home_b_b1-rich_lodge_a2 | 58.3 m vs 60.2 m (3.0 %) |
| F2 | cache_a_a2-cache_b_b1 vs cache_a_b2-cache_b_a1 | 67.0 m vs 69.1 m (3.0 %) |
| F2 | guilds_lodge_b1-lairs_two_a1 vs guilds_lodge_b2-lairs_two_a2 | 204.0 m vs 210.3 m (3.0 %) |
| F2 | guilds_lodge_a1-lairs_two_b1 vs guilds_lodge_a2-lairs_two_b2 | 210.4 m vs 204.1 m (3.0 %) |
| F2 | well_a2-lairs_one_b2 vs well_b2-lairs_one_a2 | 172.3 m vs 167.1 m (3.0 %) |
| F2 | post_s_a2-rich_den_a2 vs post_s_b2-rich_den_b2 | 57.0 m vs 58.8 m (3.0 %) |
| F2 | well_a1-lairs_one_b1 vs well_b1-lairs_one_a1 | 167.0 m vs 172.2 m (3.0 %) |
| F2 | keep_t3-lairs_one_b2 vs keep_t4-lairs_one_a2 | 176.5 m vs 181.9 m (3.0 %) |
| F2 | wallow_a1-cache_b_b1 vs wallow_a2-cache_b_b2 | 127.8 m vs 124.0 m (3.0 %) |
| F2 | home_a_a1-guilds_den_b2 vs home_a_a2-guilds_den_b1 | 152.5 m vs 157.3 m (3.0 %) |
| F2 | keep_t1-lairs_one_a1 vs keep_t4-lairs_one_a2 | 176.5 m vs 181.9 m (3.0 %) |
| F2 | rich_hollow_a1-wallow_b1 vs rich_hollow_a2-wallow_b2 | 109.7 m vs 113.1 m (3.0 %) |
| F2 | rich_hollow_a1-wallow_b1 vs rich_hollow_b1-wallow_a1 | 109.7 m vs 113.1 m (3.0 %) |
| F2 | rich_hollow_a2-wallow_b2 vs rich_hollow_b2-wallow_a2 | 113.1 m vs 109.7 m (3.0 %) |
| F2 | rich_hollow_b1-wallow_a1 vs rich_hollow_b2-wallow_a2 | 113.1 m vs 109.7 m (3.0 %) |
| F2 | home_a_a2-guilds_den_b1 vs home_a_b1-guilds_den_a2 | 157.3 m vs 152.6 m (3.0 %) |
| F2 | guilds_lodge_a2-lairs_two_b2 vs guilds_lodge_b2-lairs_two_a2 | 204.1 m vs 210.3 m (3.0 %) |
| F2 | stag_a2-crown vs stag_b2-crown | 93.6 m vs 90.8 m (3.0 %) |
| F2 | stag_b1-crown vs stag_b2-crown | 93.6 m vs 90.8 m (3.0 %) |
| F2 | stag_a1-crown vs stag_a2-crown | 90.8 m vs 93.6 m (3.0 %) |
| F2 | stag_a1-crown vs stag_b1-crown | 90.8 m vs 93.6 m (3.0 %) |
| F2 | nat_node_b1-stag_a2 vs nat_node_b2-stag_a1 | 96.3 m vs 93.4 m (3.0 %) |
| F2 | nat_node_a1-stag_b2 vs nat_node_b2-stag_a1 | 96.3 m vs 93.4 m (3.0 %) |
| F2 | well_b1-lairs_one_a1 vs well_b2-lairs_one_a2 | 172.2 m vs 167.1 m (3.0 %) |
| F2 | home_a_a2-guilds_den_b1 vs home_a_b2-guilds_den_a1 | 157.3 m vs 152.6 m (3.0 %) |
| F2 | wallow_a2-post_w_b2 vs wallow_b2-post_w_a2 | 175.8 m vs 170.6 m (2.9 %) |
| F2 | wallow_a1-post_w_b1 vs wallow_a2-post_w_b2 | 170.6 m vs 175.8 m (2.9 %) |
| F2 | home_a_a1-tower_r_b1 vs home_a_b1-tower_r_a1 | 126.8 m vs 123.1 m (2.9 %) |
| F2 | ford_nest_a1-stag_b1 vs ford_nest_a2-stag_a1 | 118.5 m vs 122.1 m (2.9 %) |
| F2 | home_a_a1-peddler_b2 vs home_a_b1-peddler_a2 | 134.7 m vs 130.8 m (2.9 %) |
| F2 | home_a_b1-peddler_a2 vs home_a_b2-peddler_a1 | 130.8 m vs 134.7 m (2.9 %) |
| F2 | home_a_a1-peddler_b2 vs home_a_a2-peddler_b1 | 134.7 m vs 130.8 m (2.9 %) |
| F2 | home_a_a2-peddler_b1 vs home_a_b2-peddler_a1 | 130.8 m vs 134.7 m (2.9 %) |
| F2 | shrine_a2-lairs_one_b2 vs shrine_b2-lairs_one_a2 | 144.9 m vs 149.3 m (2.9 %) |
| F2 | shrine_b1-lairs_one_a1 vs shrine_b2-lairs_one_a2 | 144.9 m vs 149.3 m (2.9 %) |
| F2 | post_s_a1-rich_den_a1 vs post_s_a2-rich_den_a2 | 58.7 m vs 57.0 m (2.9 %) |
| F2 | nat_node_a2-stag_b1 vs nat_node_b1-stag_a2 | 93.5 m vs 96.3 m (2.9 %) |
| F2 | stag_a1-stag_b1 vs stag_b2-stag_a2 | 172.6 m vs 177.7 m (2.9 %) |
| F2 | nat_node_a1-stag_b2 vs nat_node_a2-stag_b1 | 96.3 m vs 93.5 m (2.9 %) |
| F2 | home_a_a1-tower_r_b1 vs home_a_a2-tower_r_b2 | 126.8 m vs 123.1 m (2.9 %) |
| F2 | rich_lodge_a1-lairs_one_b2 vs rich_lodge_a2-lairs_one_b1 | 67.6 m vs 65.6 m (2.9 %) |
| F2 | rich_lodge_a2-lairs_one_b1 vs rich_lodge_b2-lairs_one_a1 | 65.6 m vs 67.6 m (2.9 %) |
| F2 | rich_lodge_b1-lairs_one_a2 vs rich_lodge_b2-lairs_one_a1 | 65.6 m vs 67.6 m (2.9 %) |
| F2 | rich_lodge_a1-lairs_one_b2 vs rich_lodge_b1-lairs_one_a2 | 67.6 m vs 65.6 m (2.9 %) |
| F2 | wallow_a2-cache_b_b1 vs wallow_b2-cache_b_a1 | 95.1 m vs 92.3 m (2.9 %) |
| F2 | wallow_a2-stag_b2 vs wallow_b2-stag_a2 | 164.7 m vs 169.6 m (2.9 %) |
| F2 | wallow_b1-stag_a1 vs wallow_b2-stag_a2 | 164.7 m vs 169.6 m (2.9 %) |
| F2 | post_s_b1-crown vs post_s_b2-crown | 96.5 m vs 93.7 m (2.9 %) |
| F2 | post_s_a1-crown vs post_s_a2-crown | 93.7 m vs 96.5 m (2.9 %) |
| F2 | post_s_a1-crown vs post_s_b1-crown | 93.7 m vs 96.5 m (2.9 %) |
| F2 | post_s_a2-crown vs post_s_b2-crown | 96.5 m vs 93.7 m (2.9 %) |
| F2 | wallow_a1-post_w_b1 vs wallow_b1-post_w_a1 | 170.6 m vs 175.7 m (2.9 %) |
| F2 | wallow_b1-post_w_a1 vs wallow_b2-post_w_a2 | 175.7 m vs 170.6 m (2.9 %) |
| F2 | third_node_a2-lairs_two_a1 vs third_node_b2-lairs_two_b1 | 134.2 m vs 138.1 m (2.9 %) |
| F2 | third_node_b1-lairs_two_b2 vs third_node_b2-lairs_two_b1 | 134.2 m vs 138.1 m (2.9 %) |
| F2 | third_node_a1-lairs_two_a2 vs third_node_a2-lairs_two_a1 | 138.1 m vs 134.2 m (2.9 %) |
| F2 | third_node_a1-lairs_two_a2 vs third_node_b1-lairs_two_b2 | 138.1 m vs 134.2 m (2.9 %) |
| F2 | shrine_a1-guilds_den_b1 vs shrine_b2-guilds_den_a2 | 162.8 m vs 158.1 m (2.9 %) |
| F2 | cache_a_a1-cache_a_a2 vs cache_a_b2-cache_a_b1 | 130.5 m vs 126.8 m (2.9 %) |
| F2 | shrine_a1-guilds_lodge_b2 vs shrine_b1-guilds_lodge_a2 | 146.9 m vs 142.7 m (2.9 %) |
| F2 | rich_hollow_b1-lairs_one_a2 vs rich_hollow_b2-lairs_one_a1 | 67.2 m vs 69.2 m (2.9 %) |
| F2 | rich_hollow_a2-lairs_one_b1 vs rich_hollow_b2-lairs_one_a1 | 67.2 m vs 69.2 m (2.9 %) |
| F2 | rich_hollow_a1-lairs_one_b2 vs rich_hollow_b1-lairs_one_a2 | 69.2 m vs 67.2 m (2.9 %) |
| F2 | rich_hollow_a1-lairs_one_b2 vs rich_hollow_a2-lairs_one_b1 | 69.2 m vs 67.2 m (2.9 %) |
| F2 | tower_r_a1-post_s_a2 vs tower_r_b1-post_s_b2 | 153.4 m vs 149.0 m (2.9 %) |
| F2 | tower_r_b1-post_s_b2 vs tower_r_b2-post_s_b1 | 149.0 m vs 153.4 m (2.9 %) |
| F2 | inn_a2-guilds_lodge_b1 vs inn_b2-guilds_lodge_a1 | 116.2 m vs 119.6 m (2.9 %) |
| F2 | inn_b1-guilds_lodge_a2 vs inn_b2-guilds_lodge_a1 | 116.2 m vs 119.6 m (2.9 %) |
| F2 | well_a2-post_w_b2 vs well_b2-post_w_a2 | 134.1 m vs 130.2 m (2.9 %) |
| F2 | tower_r_a2-post_s_a1 vs tower_r_b2-post_s_b1 | 149.0 m vs 153.4 m (2.8 %) |
| F2 | tower_r_a1-post_s_a2 vs tower_r_a2-post_s_a1 | 153.4 m vs 149.0 m (2.8 %) |
| F2 | rich_den_a1-guilds_lodge_b2 vs rich_den_b2-guilds_lodge_a1 | 92.8 m vs 90.2 m (2.8 %) |
| F2 | home_b_a1-guilds_den_a1 vs home_b_a2-guilds_den_a2 | 43.0 m vs 44.2 m (2.8 %) |
| F2 | home_b_a2-guilds_den_a2 vs home_b_b2-guilds_den_b2 | 44.2 m vs 43.0 m (2.8 %) |
| F2 | home_b_b1-guilds_den_b1 vs home_b_b2-guilds_den_b2 | 44.2 m vs 43.0 m (2.8 %) |
| F2 | home_b_a1-guilds_den_a1 vs home_b_b1-guilds_den_b1 | 43.0 m vs 44.2 m (2.8 %) |
| F2 | wallow_a1-stag_b1 vs wallow_a2-stag_b2 | 169.5 m vs 164.7 m (2.8 %) |
| F2 | wallow_a1-stag_b1 vs wallow_b1-stag_a1 | 169.5 m vs 164.7 m (2.8 %) |
| F2 | well_a1-post_w_b1 vs well_a2-post_w_b2 | 130.3 m vs 134.1 m (2.8 %) |
| F2 | lairs_one_a1-lairs_two_b1 vs lairs_one_b1-lairs_two_a1 | 201.7 m vs 196.0 m (2.8 %) |
| F2 | rich_node_a1-stag_a2 vs rich_node_a2-stag_a1 | 136.1 m vs 132.3 m (2.8 %) |
| F2 | rich_node_a1-stag_a2 vs rich_node_b1-stag_b2 | 136.1 m vs 132.3 m (2.8 %) |
| F2 | tower_c_a1-wallow_b1 vs tower_c_b1-wallow_a1 | 113.4 m vs 110.2 m (2.8 %) |
| F2 | tower_c_b1-wallow_a1 vs tower_c_b2-wallow_a2 | 110.2 m vs 113.4 m (2.8 %) |
| F2 | tower_c_a2-wallow_b2 vs tower_c_b2-wallow_a2 | 110.2 m vs 113.4 m (2.8 %) |
| F2 | tower_c_a1-wallow_b1 vs tower_c_a2-wallow_b2 | 113.4 m vs 110.2 m (2.8 %) |
| F2 | wallow_a2-x_ford_s vs wallow_b2-x_ford_n | 110.8 m vs 114.0 m (2.8 %) |
| F2 | wallow_a2-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 110.8 m vs 114.0 m (2.8 %) |
| F2 | wallow_b1-x_ford_s vs wallow_b2-x_ford_n | 110.8 m vs 114.0 m (2.8 %) |
| F2 | wallow_b1-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 110.8 m vs 114.0 m (2.8 %) |
| F2 | lairs_one_a1-lairs_two_b1 vs lairs_one_a2-lairs_two_b2 | 201.7 m vs 196.0 m (2.8 %) |
| F2 | tower_c_a2-wallow_b1 vs tower_c_b1-wallow_a2 | 113.0 m vs 109.8 m (2.8 %) |
| F2 | peddler_a2-lairs_one_b2 vs peddler_b2-lairs_one_a2 | 159.8 m vs 164.4 m (2.8 %) |
| F2 | rich_hollow_a1-guilds_lodge_a1 vs rich_hollow_b2-guilds_lodge_b2 | 94.5 m vs 97.2 m (2.8 %) |
| F2 | peddler_b1-lairs_one_a1 vs peddler_b2-lairs_one_a2 | 159.8 m vs 164.4 m (2.8 %) |
| F2 | guilds_den_b1-crown vs guilds_den_b2-crown | 111.1 m vs 108.0 m (2.8 %) |
| F2 | guilds_den_a2-crown vs guilds_den_b2-crown | 111.1 m vs 108.0 m (2.8 %) |
| F2 | guilds_den_a1-crown vs guilds_den_b1-crown | 108.0 m vs 111.1 m (2.8 %) |
| F2 | guilds_den_a1-crown vs guilds_den_a2-crown | 108.0 m vs 111.1 m (2.8 %) |
| F2 | lairs_one_b1-lairs_two_a1 vs lairs_one_b2-lairs_two_a2 | 196.0 m vs 201.6 m (2.8 %) |
| F2 | stag_a2-post_w_b2 vs stag_b2-post_w_a2 | 151.0 m vs 146.8 m (2.8 %) |
| F2 | post_w_a1-guilds_den_b2 vs post_w_a2-guilds_den_b1 | 165.2 m vs 170.0 m (2.8 %) |
| F2 | lairs_one_a2-lairs_two_b2 vs lairs_one_b2-lairs_two_a2 | 196.0 m vs 201.6 m (2.8 %) |
| F2 | well_b1-post_w_a1 vs well_b2-post_w_a2 | 134.0 m vs 130.2 m (2.8 %) |
| F2 | stag_b1-post_w_a1 vs stag_b2-post_w_a2 | 151.0 m vs 146.8 m (2.8 %) |
| F2 | post_w_a2-guilds_den_b1 vs post_w_b1-guilds_den_a2 | 170.0 m vs 165.3 m (2.8 %) |
| F2 | wallow_b1-cache_b_a2 vs wallow_b2-cache_b_a1 | 95.0 m vs 92.3 m (2.8 %) |
| F2 | post_s_b1-guilds_lodge_b2 vs post_s_b2-guilds_lodge_b1 | 153.2 m vs 157.5 m (2.8 %) |
| F2 | post_s_a1-guilds_lodge_a2 vs post_s_a2-guilds_lodge_a1 | 157.5 m vs 153.2 m (2.8 %) |
| F2 | post_s_a2-guilds_lodge_a1 vs post_s_b2-guilds_lodge_b1 | 153.2 m vs 157.5 m (2.8 %) |
| F2 | post_s_a1-guilds_lodge_a2 vs post_s_b1-guilds_lodge_b2 | 157.5 m vs 153.2 m (2.8 %) |
| F2 | wallow_a1-cache_b_b2 vs wallow_a2-cache_b_b1 | 92.5 m vs 95.1 m (2.8 %) |
| F2 | well_a1-post_w_b1 vs well_b1-post_w_a1 | 130.3 m vs 134.0 m (2.8 %) |
| F2 | tower_c_a1-ford_nest_a2 vs tower_c_b1-ford_nest_a1 | 48.7 m vs 50.0 m (2.7 %) |
| F2 | tower_c_a1-x_ford_n vs tower_c_b1-x_ford_s | 48.7 m vs 50.0 m (2.7 %) |
| F2 | wallow_a1-ford_nest_a2 vs wallow_a2-ford_nest_a1 | 113.9 m vs 110.8 m (2.7 %) |
| F2 | wallow_a1-x_ford_n vs wallow_a2-x_ford_s | 113.9 m vs 110.8 m (2.7 %) |
| F2 | post_s_a2-rich_den_b1 vs post_s_b2-rich_den_a1 | 61.7 m vs 63.5 m (2.7 %) |
| F2 | wallow_a1-ford_nest_a2 vs wallow_b1-ford_nest_a1 | 113.9 m vs 110.8 m (2.7 %) |
| F2 | wallow_a1-x_ford_n vs wallow_b1-x_ford_s | 113.9 m vs 110.8 m (2.7 %) |
| F2 | post_w_a2-guilds_den_b1 vs post_w_b2-guilds_den_a1 | 170.0 m vs 165.3 m (2.7 %) |
| F2 | stag_a1-post_w_b1 vs stag_a2-post_w_b2 | 146.8 m vs 151.0 m (2.7 %) |
| F2 | wallow_a2-rich_den_b2 vs wallow_b2-rich_den_a2 | 114.7 m vs 117.9 m (2.7 %) |
| F2 | wallow_b1-rich_den_a1 vs wallow_b2-rich_den_a2 | 114.7 m vs 117.9 m (2.7 %) |
| F2 | stag_a1-post_w_b1 vs stag_b1-post_w_a1 | 146.8 m vs 151.0 m (2.7 %) |
| F2 | x_bridge_n-x_lane_w vs x_bridge_s-x_lane_e | 65.9 m vs 67.7 m (2.7 %) |
| F2 | home_a_a2-shrine_b1 vs home_a_b2-shrine_a1 | 126.2 m vs 122.8 m (2.7 %) |
| F2 | home_a_a1-shrine_b2 vs home_a_a2-shrine_b1 | 122.8 m vs 126.2 m (2.7 %) |
| F2 | guilds_den_a1-lairs_two_b1 vs guilds_den_b1-lairs_two_a1 | 209.1 m vs 203.4 m (2.7 %) |
| F2 | rich_den_a2-lairs_one_a2 vs rich_den_b2-lairs_one_b2 | 71.4 m vs 73.4 m (2.7 %) |
| F2 | home_a_b1-shrine_a2 vs home_a_b2-shrine_a1 | 126.2 m vs 122.8 m (2.7 %) |
| F2 | home_a_a1-shrine_b2 vs home_a_b1-shrine_a2 | 122.8 m vs 126.2 m (2.7 %) |
| F2 | guilds_den_a1-lairs_two_b1 vs guilds_den_a2-lairs_two_b2 | 209.1 m vs 203.5 m (2.7 %) |
| F2 | tower_c_a1-stag_a2 vs tower_c_a2-stag_a1 | 85.7 m vs 88.1 m (2.7 %) |
| F2 | tower_c_b1-stag_b2 vs tower_c_b2-stag_b1 | 88.1 m vs 85.7 m (2.7 %) |
| F2 | tower_c_a1-stag_a2 vs tower_c_b1-stag_b2 | 85.7 m vs 88.1 m (2.7 %) |
| F2 | tower_c_a2-stag_a1 vs tower_c_b2-stag_b1 | 88.1 m vs 85.7 m (2.7 %) |
| F2 | peddler_a1-peddler_b2 vs peddler_a2-peddler_b1 | 127.2 m vs 123.7 m (2.7 %) |
| F2 | shrine_a2-guilds_lodge_b2 vs shrine_b2-guilds_lodge_a2 | 156.4 m vs 152.2 m (2.7 %) |
| F2 | post_s_a2-cache_b_a1 vs post_s_b1-cache_b_b2 | 112.6 m vs 109.6 m (2.7 %) |
| F2 | post_w_a1-guilds_lodge_b2 vs post_w_b1-guilds_lodge_a2 | 170.6 m vs 166.0 m (2.7 %) |
| F2 | rich_den_a1-lairs_one_a1 vs rich_den_a2-lairs_one_a2 | 73.4 m vs 71.4 m (2.7 %) |
| F2 | guilds_den_b1-lairs_two_a1 vs guilds_den_b2-lairs_two_a2 | 203.4 m vs 209.0 m (2.7 %) |
| F2 | wallow_a1-rich_den_b1 vs wallow_a2-rich_den_b2 | 117.8 m vs 114.7 m (2.7 %) |
| F2 | wallow_a1-rich_den_b1 vs wallow_b1-rich_den_a1 | 117.8 m vs 114.7 m (2.7 %) |
| F2 | guilds_den_a2-lairs_two_b2 vs guilds_den_b2-lairs_two_a2 | 203.5 m vs 209.0 m (2.7 %) |
| F2 | x_ford_n-crown vs x_ford_s-crown | 51.9 m vs 50.5 m (2.7 %) |
| F2 | ford_nest_a1-crown vs ford_nest_a2-crown | 50.5 m vs 51.9 m (2.7 %) |
| F2 | home_a_b1-tower_r_a1 vs home_a_b2-tower_r_a2 | 123.1 m vs 126.5 m (2.7 %) |
| F2 | post_s_b1-rich_den_a2 vs post_s_b2-rich_den_a1 | 61.8 m vs 63.5 m (2.7 %) |
| F2 | tower_c_a1-ford_nest_a2 vs tower_c_a2-ford_nest_a1 | 48.7 m vs 50.0 m (2.7 %) |
| F2 | tower_c_a1-x_ford_n vs tower_c_a2-x_ford_s | 48.7 m vs 50.0 m (2.7 %) |
| F2 | stag_a1-peddler_b1 vs stag_a2-peddler_b2 | 138.2 m vs 142.0 m (2.6 %) |
| F2 | rich_den_b1-lairs_one_b1 vs rich_den_b2-lairs_one_b2 | 71.4 m vs 73.4 m (2.6 %) |
| F2 | tower_c_a1-lairs_one_b1 vs tower_c_b1-lairs_one_a1 | 123.9 m vs 127.2 m (2.6 %) |
| F2 | well_a1-lairs_two_a1 vs well_a2-lairs_two_a2 | 29.6 m vs 30.4 m (2.6 %) |
| F2 | well_a2-lairs_two_a2 vs well_b2-lairs_two_b2 | 30.4 m vs 29.6 m (2.6 %) |
| F2 | well_a1-lairs_two_a1 vs well_b1-lairs_two_b1 | 29.6 m vs 30.4 m (2.6 %) |
| F2 | well_b1-lairs_two_b1 vs well_b2-lairs_two_b2 | 30.4 m vs 29.6 m (2.6 %) |
| F2 | well_a1-x_lane_w vs well_b1-x_lane_e | 53.3 m vs 54.8 m (2.6 %) |
| F2 | well_b1-x_lane_e vs well_b2-x_lane_e | 54.8 m vs 53.3 m (2.6 %) |
| F2 | well_a2-x_lane_w vs well_b2-x_lane_e | 54.8 m vs 53.3 m (2.6 %) |
| F2 | well_a1-x_lane_w vs well_a2-x_lane_w | 53.3 m vs 54.8 m (2.6 %) |
| F2 | wallow_a1-cache_b_b2 vs wallow_b1-cache_b_a2 | 92.5 m vs 95.0 m (2.6 %) |
| F2 | wallow_a1-rich_lodge_a2 vs wallow_b1-rich_lodge_b2 | 127.8 m vs 124.4 m (2.6 %) |
| F2 | nat_node_a2-tower_r_b1 vs nat_node_b2-tower_r_a1 | 75.4 m vs 73.4 m (2.6 %) |
| F2 | x_bridge_n-x_lane_w vs x_bridge_s-x_lane_w | 65.9 m vs 67.6 m (2.6 %) |
| F2 | rich_den_a1-lairs_one_a1 vs rich_den_b1-lairs_one_b1 | 73.4 m vs 71.4 m (2.6 %) |
| F2 | home_a_a2-tower_r_b2 vs home_a_b2-tower_r_a2 | 123.1 m vs 126.5 m (2.6 %) |
| F2 | stag_a2-peddler_b2 vs stag_b1-peddler_a1 | 142.0 m vs 138.2 m (2.6 %) |
| F2 | stag_a2-peddler_b2 vs stag_b2-peddler_a2 | 142.0 m vs 138.2 m (2.6 %) |
| F2 | nat_node_a2-guilds_lodge_b1 vs nat_node_b2-guilds_lodge_a1 | 124.5 m vs 127.8 m (2.6 %) |
| F2 | nat_node_b1-guilds_lodge_a2 vs nat_node_b2-guilds_lodge_a1 | 124.5 m vs 127.8 m (2.6 %) |
| F2 | tower_c_a1-lairs_one_b1 vs tower_c_a2-lairs_one_b2 | 123.9 m vs 127.2 m (2.6 %) |
| F2 | rich_lodge_a1-cache_a_b1 vs rich_lodge_b2-cache_a_a2 | 126.1 m vs 122.8 m (2.6 %) |
| F2 | post_s_a1-post_s_b1 vs post_s_b2-post_s_a2 | 181.5 m vs 186.3 m (2.6 %) |
| F2 | wallow_a1-cache_a_b1 vs wallow_a2-cache_a_b2 | 167.5 m vs 163.1 m (2.6 %) |
| F2 | wallow_a1-cache_a_b1 vs wallow_b1-cache_a_a1 | 167.5 m vs 163.2 m (2.6 %) |
| F2 | tower_c_b1-x_ford_s vs tower_c_b2-x_ford_n | 50.0 m vs 48.7 m (2.6 %) |
| F2 | tower_c_b1-ford_nest_a1 vs tower_c_b2-ford_nest_a2 | 50.0 m vs 48.7 m (2.6 %) |
| F2 | wallow_a2-cache_a_b2 vs wallow_b2-cache_a_a2 | 163.1 m vs 167.5 m (2.6 %) |
| F2 | post_w_a1-guilds_den_b1 vs post_w_b2-guilds_den_a2 | 182.8 m vs 178.1 m (2.6 %) |
| F2 | ford_nest_a1-lairs_one_a1 vs ford_nest_a2-lairs_one_b1 | 77.0 m vs 75.0 m (2.6 %) |
| F2 | ford_nest_a1-lairs_one_b2 vs ford_nest_a2-lairs_one_a2 | 77.0 m vs 75.0 m (2.6 %) |
| F2 | ford_nest_a1-lairs_one_b2 vs ford_nest_a2-lairs_one_b1 | 77.0 m vs 75.0 m (2.6 %) |
| F2 | ford_nest_a1-lairs_one_a1 vs ford_nest_a2-lairs_one_a2 | 77.0 m vs 75.0 m (2.6 %) |
| F2 | post_s_a1-rich_den_b2 vs post_s_a2-rich_den_b1 | 63.3 m vs 61.7 m (2.6 %) |
| F2 | tower_c_b1-lairs_one_a1 vs tower_c_b2-lairs_one_a2 | 127.2 m vs 124.0 m (2.6 %) |
| F2 | well_a1-x_bridge_n vs well_b1-x_bridge_s | 119.4 m vs 122.6 m (2.6 %) |
| F2 | wallow_b1-cache_a_a1 vs wallow_b2-cache_a_a2 | 163.2 m vs 167.5 m (2.6 %) |
| F2 | tower_r_a2-peddler_b1 vs tower_r_b1-peddler_a2 | 93.3 m vs 95.7 m (2.6 %) |
| F2 | home_a_a1-guilds_den_b1 vs home_a_b2-guilds_den_a2 | 183.7 m vs 179.0 m (2.5 %) |
| F2 | wallow_b1-rich_lodge_b2 vs wallow_b2-rich_lodge_b1 | 124.4 m vs 127.7 m (2.5 %) |
| F2 | x_bridge_n-x_lane_e vs x_bridge_s-x_lane_e | 66.0 m vs 67.7 m (2.5 %) |
| F2 | tower_c_a2-lairs_one_b2 vs tower_c_b2-lairs_one_a2 | 127.2 m vs 124.0 m (2.5 %) |
| F2 | cache_a_a1-x_lane_w vs cache_a_a2-x_lane_w | 70.8 m vs 72.6 m (2.5 %) |
| F2 | cache_a_a2-x_lane_w vs cache_a_b2-x_lane_e | 72.6 m vs 70.8 m (2.5 %) |
| F2 | cache_a_a1-x_lane_w vs cache_a_b1-x_lane_e | 70.8 m vs 72.6 m (2.5 %) |
| F2 | cache_a_b1-x_lane_e vs cache_a_b2-x_lane_e | 72.6 m vs 70.8 m (2.5 %) |
| F2 | tower_c_a1-rich_den_b1 vs tower_c_b1-rich_den_a1 | 52.5 m vs 53.9 m (2.5 %) |
| F2 | well_b1-x_bridge_s vs well_b2-x_bridge_n | 122.6 m vs 119.5 m (2.5 %) |
| F2 | inn_a2-rich_lodge_b2 vs inn_b1-rich_lodge_a1 | 78.9 m vs 77.0 m (2.5 %) |
| F2 | well_a1-x_bridge_n vs well_a2-x_bridge_s | 119.4 m vs 122.5 m (2.5 %) |
| F2 | cache_a_b1-cache_b_b1 vs cache_a_b2-cache_b_b2 | 56.0 m vs 54.6 m (2.5 %) |
| F2 | cache_a_a1-cache_b_a1 vs cache_a_b1-cache_b_b1 | 54.6 m vs 56.0 m (2.5 %) |
| F2 | cache_a_a1-cache_b_a1 vs cache_a_a2-cache_b_a2 | 54.6 m vs 56.0 m (2.5 %) |
| F2 | cache_a_a2-cache_b_a2 vs cache_a_b2-cache_b_b2 | 56.0 m vs 54.6 m (2.5 %) |
| F2 | tower_c_a1-guilds_lodge_b1 vs tower_c_b1-guilds_lodge_a1 | 131.7 m vs 128.4 m (2.5 %) |
| F2 | tower_c_a1-guilds_lodge_b1 vs tower_c_a2-guilds_lodge_b2 | 131.7 m vs 128.4 m (2.5 %) |
| F2 | tower_c_b1-guilds_lodge_a1 vs tower_c_b2-guilds_lodge_a2 | 128.4 m vs 131.7 m (2.5 %) |
| F2 | tower_c_a2-guilds_lodge_b2 vs tower_c_b2-guilds_lodge_a2 | 128.4 m vs 131.7 m (2.5 %) |
| F2 | rich_den_a1-lairs_one_b2 vs rich_den_b1-lairs_one_a2 | 78.1 m vs 76.1 m (2.5 %) |
| F2 | post_s_a1-rich_den_b2 vs post_s_b1-rich_den_a2 | 63.3 m vs 61.8 m (2.5 %) |
| F2 | home_a_b1-guilds_lodge_a2 vs home_a_b2-guilds_lodge_a1 | 153.6 m vs 157.5 m (2.5 %) |
| F2 | tower_c_a2-x_ford_s vs tower_c_b2-x_ford_n | 50.0 m vs 48.7 m (2.5 %) |
| F2 | tower_c_a2-ford_nest_a1 vs tower_c_b2-ford_nest_a2 | 50.0 m vs 48.7 m (2.5 %) |
| F2 | wallow_a1-rich_lodge_a2 vs wallow_a2-rich_lodge_a1 | 127.8 m vs 124.6 m (2.5 %) |
| F2 | shrine_b1-post_s_a2 vs shrine_b2-post_s_a1 | 120.7 m vs 117.7 m (2.5 %) |
| F2 | tower_r_a2-peddler_b1 vs tower_r_b2-peddler_a1 | 93.3 m vs 95.6 m (2.5 %) |
| F2 | stag_a2-x_lane_w vs stag_b2-x_lane_e | 82.3 m vs 80.2 m (2.5 %) |
| F2 | stag_b1-x_lane_e vs stag_b2-x_lane_e | 82.3 m vs 80.2 m (2.5 %) |
| F2 | stag_a1-x_lane_w vs stag_b1-x_lane_e | 80.2 m vs 82.3 m (2.5 %) |
| F2 | stag_a1-x_lane_w vs stag_a2-x_lane_w | 80.2 m vs 82.3 m (2.5 %) |
| F2 | nat_node_b1-guilds_lodge_a1 vs nat_node_b2-guilds_lodge_a2 | 154.4 m vs 150.6 m (2.5 %) |
| F2 | nat_node_a1-guilds_lodge_b1 vs nat_node_b1-guilds_lodge_a1 | 150.6 m vs 154.4 m (2.5 %) |
| F2 | shrine_a1-post_s_b2 vs shrine_b2-post_s_a1 | 120.7 m vs 117.7 m (2.5 %) |
| F2 | stag_b1-peddler_a2 vs stag_b2-peddler_a1 | 117.3 m vs 114.4 m (2.5 %) |
| F2 | wallow_a2-rich_lodge_a2 vs wallow_b2-rich_lodge_b2 | 92.2 m vs 89.9 m (2.5 %) |
| F2 | wallow_a2-rich_den_a2 vs wallow_b2-rich_den_b2 | 77.4 m vs 75.5 m (2.5 %) |
| F2 | wallow_a1-rich_den_a1 vs wallow_a2-rich_den_a2 | 75.5 m vs 77.4 m (2.5 %) |
| F2 | wallow_a1-rich_den_a1 vs wallow_b1-rich_den_b1 | 75.5 m vs 77.4 m (2.5 %) |
| F2 | wallow_b1-rich_den_b1 vs wallow_b2-rich_den_b2 | 77.4 m vs 75.5 m (2.5 %) |
| F2 | stag_a2-peddler_b1 vs stag_b1-peddler_a2 | 114.4 m vs 117.3 m (2.5 %) |
| F2 | stag_b1-lairs_one_a1 vs stag_b2-lairs_one_a2 | 189.2 m vs 194.0 m (2.5 %) |
| F2 | home_b_a1-stag_a1 vs home_b_a2-stag_a2 | 42.9 m vs 44.0 m (2.5 %) |
| F2 | home_b_a2-stag_a2 vs home_b_b2-stag_b2 | 44.0 m vs 42.9 m (2.5 %) |
| F2 | well_a2-x_bridge_s vs well_b2-x_bridge_n | 122.5 m vs 119.5 m (2.5 %) |
| F2 | home_b_a1-stag_a1 vs home_b_b1-stag_b1 | 42.9 m vs 44.0 m (2.5 %) |
| F2 | home_b_b1-stag_b1 vs home_b_b2-stag_b2 | 44.0 m vs 42.9 m (2.5 %) |
| F2 | tower_c_a1-rich_den_b1 vs tower_c_a2-rich_den_b2 | 52.5 m vs 53.9 m (2.5 %) |
| F2 | shrine_a2-post_s_b1 vs shrine_b1-post_s_a2 | 117.8 m vs 120.7 m (2.5 %) |
| F2 | shrine_a1-post_s_b2 vs shrine_a2-post_s_b1 | 120.7 m vs 117.8 m (2.5 %) |
| F2 | stag_a2-lairs_one_b2 vs stag_b2-lairs_one_a2 | 189.2 m vs 194.0 m (2.5 %) |
| F2 | x_bridge_n-x_lane_e vs x_bridge_s-x_lane_w | 66.0 m vs 67.6 m (2.4 %) |
| F2 | third_node_a2-cache_a_b1 vs third_node_b1-cache_a_a2 | 121.1 m vs 118.2 m (2.4 %) |
| F2 | stag_a1-peddler_b2 vs stag_b1-peddler_a2 | 114.5 m vs 117.3 m (2.4 %) |
| F2 | rich_lodge_a1-guilds_lodge_a1 vs rich_lodge_b2-guilds_lodge_b2 | 100.0 m vs 102.5 m (2.4 %) |
| F2 | home_b_a2-rich_node_a2 vs home_b_b2-rich_node_b2 | 51.0 m vs 49.7 m (2.4 %) |
| F2 | home_b_a1-rich_node_a1 vs home_b_a2-rich_node_a2 | 49.7 m vs 51.0 m (2.4 %) |
| F2 | rich_den_b1-lairs_one_a2 vs rich_den_b2-lairs_one_a1 | 76.1 m vs 78.0 m (2.4 %) |
| F2 | home_b_b1-rich_node_b1 vs home_b_b2-rich_node_b2 | 51.0 m vs 49.7 m (2.4 %) |
| F2 | home_b_a1-rich_node_a1 vs home_b_b1-rich_node_b1 | 49.7 m vs 51.0 m (2.4 %) |
| F2 | rich_den_a1-lairs_one_b2 vs rich_den_a2-lairs_one_b1 | 78.1 m vs 76.2 m (2.4 %) |
| F2 | stag_a1-lairs_one_b1 vs stag_b1-lairs_one_a1 | 193.9 m vs 189.2 m (2.4 %) |
| F2 | home_a_a2-post_w_b2 vs home_a_b1-post_w_a1 | 159.4 m vs 163.3 m (2.4 %) |
| F2 | wallow_b1-inn_a2 vs wallow_b2-inn_a1 | 112.1 m vs 109.4 m (2.4 %) |
| F2 | wallow_a2-inn_b1 vs wallow_b2-inn_a1 | 112.1 m vs 109.4 m (2.4 %) |
| F2 | well_b1-cache_b_b2 vs well_b2-cache_b_b1 | 79.2 m vs 77.3 m (2.4 %) |
| F2 | well_a1-cache_b_a2 vs well_b1-cache_b_b2 | 77.3 m vs 79.2 m (2.4 %) |
| F2 | inn_a1-post_w_b1 vs inn_a2-post_w_b2 | 118.4 m vs 121.3 m (2.4 %) |
| F2 | inn_a2-post_w_b2 vs inn_b2-post_w_a2 | 121.3 m vs 118.4 m (2.4 %) |
| F2 | nat_node_a1-cache_b_b1 vs nat_node_b2-cache_b_a2 | 76.4 m vs 78.2 m (2.4 %) |
| F2 | third_node_a2-post_w_b2 vs third_node_b2-post_w_a2 | 172.3 m vs 168.1 m (2.4 %) |
| F2 | stag_a1-lairs_one_b1 vs stag_a2-lairs_one_b2 | 193.9 m vs 189.2 m (2.4 %) |
| F2 | wallow_a1-inn_b2 vs wallow_a2-inn_b1 | 109.4 m vs 112.1 m (2.4 %) |
| F2 | wallow_a1-inn_b2 vs wallow_b1-inn_a2 | 109.4 m vs 112.1 m (2.4 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_b1-wallow_a1 | 132.3 m vs 129.1 m (2.4 %) |
| F2 | nat_node_a1-wallow_b1 vs nat_node_a2-wallow_b2 | 132.3 m vs 129.1 m (2.4 %) |
| F2 | nat_node_a2-wallow_b2 vs nat_node_b2-wallow_a2 | 129.1 m vs 132.3 m (2.4 %) |
| F2 | nat_node_b1-wallow_a1 vs nat_node_b2-wallow_a2 | 129.1 m vs 132.3 m (2.4 %) |
| F2 | post_s_b1-x_lane_e vs post_s_b2-x_lane_e | 85.2 m vs 83.1 m (2.4 %) |
| F2 | post_s_a1-x_lane_w vs post_s_b1-x_lane_e | 83.1 m vs 85.2 m (2.4 %) |
| F2 | post_s_a2-x_lane_w vs post_s_b2-x_lane_e | 85.2 m vs 83.1 m (2.4 %) |
| F2 | post_s_a1-x_lane_w vs post_s_a2-x_lane_w | 83.1 m vs 85.2 m (2.4 %) |
| F2 | tower_c_a1-rich_hollow_a2 vs tower_c_b1-rich_hollow_b2 | 56.7 m vs 58.1 m (2.4 %) |
| F2 | wallow_a2-rich_lodge_a1 vs wallow_b2-rich_lodge_b1 | 124.6 m vs 127.7 m (2.4 %) |
| F2 | third_node_a1-post_w_b1 vs third_node_a2-post_w_b2 | 168.1 m vs 172.3 m (2.4 %) |
| F2 | inn_a1-post_w_b1 vs inn_b1-post_w_a1 | 118.4 m vs 121.3 m (2.4 %) |
| F2 | inn_b1-post_w_a1 vs inn_b2-post_w_a2 | 121.3 m vs 118.4 m (2.4 %) |
| F2 | post_w_a2-guilds_lodge_b1 vs post_w_b2-guilds_lodge_a1 | 173.9 m vs 169.7 m (2.4 %) |
| F2 | wallow_a1-cache_b_a2 vs wallow_b1-cache_b_b2 | 99.3 m vs 97.0 m (2.4 %) |
| F2 | wallow_a1-cache_b_a2 vs wallow_a2-cache_b_a1 | 99.3 m vs 97.0 m (2.4 %) |
| F2 | wallow_b1-cache_b_b2 vs wallow_b2-cache_b_b1 | 97.0 m vs 99.3 m (2.4 %) |
| F2 | wallow_a2-cache_b_a1 vs wallow_b2-cache_b_b1 | 97.0 m vs 99.3 m (2.4 %) |
| F2 | stag_a1-post_w_a2 vs stag_b1-post_w_b2 | 96.2 m vs 98.5 m (2.4 %) |
| F2 | stag_a1-post_w_a2 vs stag_a2-post_w_a1 | 96.2 m vs 98.5 m (2.4 %) |
| F2 | stag_a2-post_w_a1 vs stag_b2-post_w_b1 | 98.5 m vs 96.2 m (2.4 %) |
| F2 | stag_b1-post_w_b2 vs stag_b2-post_w_b1 | 98.5 m vs 96.2 m (2.4 %) |
| F2 | keep_t0-guilds_den_b1 vs keep_t4-guilds_den_a2 | 195.5 m vs 190.8 m (2.4 %) |
| F2 | guilds_den_a2-cache_a_b1 vs guilds_den_b1-cache_a_a2 | 118.2 m vs 115.4 m (2.4 %) |
| F2 | tower_c_b1-rich_den_a1 vs tower_c_b2-rich_den_a2 | 53.9 m vs 52.6 m (2.4 %) |
| F2 | tower_r_a1-peddler_b2 vs tower_r_a2-peddler_b1 | 95.5 m vs 93.3 m (2.4 %) |
| F2 | rich_node_a1-wallow_a1 vs rich_node_a2-wallow_a2 | 65.9 m vs 67.5 m (2.4 %) |
| F2 | rich_node_a1-wallow_a1 vs rich_node_b1-wallow_b1 | 65.9 m vs 67.5 m (2.4 %) |
| F2 | home_a_a2-guilds_lodge_b2 vs home_a_b2-guilds_lodge_a2 | 177.9 m vs 173.7 m (2.4 %) |
| F2 | nat_node_a2-cache_b_b2 vs nat_node_b2-cache_b_a2 | 76.4 m vs 78.2 m (2.4 %) |
| F2 | rich_den_a2-lairs_one_b1 vs rich_den_b2-lairs_one_a1 | 76.2 m vs 78.0 m (2.4 %) |
| F2 | keep_t3-post_w_b2 vs keep_t1-post_w_a1 | 164.1 m vs 168.1 m (2.4 %) |
| F2 | ford_nest_a1-stag_a2 vs ford_nest_a2-stag_b2 | 119.7 m vs 122.6 m (2.4 %) |
| F2 | third_node_a1-guilds_den_b1 vs third_node_a2-guilds_den_b2 | 207.1 m vs 212.1 m (2.4 %) |
| F2 | post_s_a1-cache_b_a2 vs post_s_b1-cache_b_b2 | 107.0 m vs 109.6 m (2.4 %) |
| F2 | post_s_b1-cache_b_b2 vs post_s_b2-cache_b_b1 | 109.6 m vs 107.0 m (2.4 %) |
| F2 | third_node_b1-post_w_a1 vs third_node_b2-post_w_a2 | 172.2 m vs 168.1 m (2.4 %) |
| F2 | tower_r_a1-inn_b2 vs tower_r_a2-inn_b1 | 65.0 m vs 66.6 m (2.3 %) |
| F2 | third_node_a1-post_w_b1 vs third_node_b1-post_w_a1 | 168.1 m vs 172.2 m (2.3 %) |
| F2 | home_a_a1-guilds_den_a1 vs home_a_b1-guilds_den_b1 | 59.0 m vs 60.4 m (2.3 %) |
| F2 | home_a_b1-guilds_den_b1 vs home_a_b2-guilds_den_b2 | 60.4 m vs 59.0 m (2.3 %) |
| F2 | home_a_a1-guilds_den_a1 vs home_a_a2-guilds_den_a2 | 59.0 m vs 60.4 m (2.3 %) |
| F2 | home_a_a2-guilds_den_a2 vs home_a_b2-guilds_den_b2 | 60.4 m vs 59.0 m (2.3 %) |
| F2 | cache_a_a1-lairs_two_b2 vs cache_a_b2-lairs_two_a1 | 113.1 m vs 110.5 m (2.3 %) |
| F2 | wallow_b1-cache_b_a1 vs wallow_b2-cache_b_a2 | 123.9 m vs 126.9 m (2.3 %) |
| F2 | post_w_a2-guilds_lodge_b2 vs post_w_b2-guilds_lodge_a2 | 180.0 m vs 175.8 m (2.3 %) |
| F2 | guilds_lodge_a2-cache_a_b1 vs guilds_lodge_b1-cache_a_a2 | 126.9 m vs 123.9 m (2.3 %) |
| F2 | cache_a_b1-x_lane_w vs cache_a_b2-x_lane_w | 92.1 m vs 94.3 m (2.3 %) |
| F2 | keep_t0-rich_den_a2 vs keep_t3-rich_den_a1 | 102.4 m vs 100.0 m (2.3 %) |
| F2 | keep_t3-rich_den_a1 vs keep_t4-rich_den_b1 | 100.0 m vs 102.4 m (2.3 %) |
| F2 | keep_t0-rich_den_a2 vs keep_t1-rich_den_b2 | 102.4 m vs 100.0 m (2.3 %) |
| F2 | keep_t1-rich_den_b2 vs keep_t4-rich_den_b1 | 100.0 m vs 102.4 m (2.3 %) |
| F2 | cache_a_a1-x_lane_e vs cache_a_b1-x_lane_w | 94.3 m vs 92.1 m (2.3 %) |
| F2 | tower_c_a2-rich_den_b2 vs tower_c_b2-rich_den_a2 | 53.9 m vs 52.6 m (2.3 %) |
| F2 | third_node_a2-guilds_den_b2 vs third_node_b2-guilds_den_a2 | 212.1 m vs 207.2 m (2.3 %) |
| F2 | tower_c_a1-rich_hollow_a2 vs tower_c_a2-rich_hollow_a1 | 56.7 m vs 58.0 m (2.3 %) |
| F2 | wallow_b1-rich_den_a2 vs wallow_b2-rich_den_a1 | 82.2 m vs 80.3 m (2.3 %) |
| F2 | wallow_a1-rich_den_b2 vs wallow_b1-rich_den_a2 | 80.3 m vs 82.2 m (2.3 %) |
| F2 | third_node_a1-guilds_den_b1 vs third_node_b1-guilds_den_a1 | 207.1 m vs 212.0 m (2.3 %) |
| F2 | wallow_a2-rich_den_b1 vs wallow_b2-rich_den_a1 | 82.2 m vs 80.3 m (2.3 %) |
| F2 | wallow_a1-rich_den_b2 vs wallow_a2-rich_den_b1 | 80.3 m vs 82.2 m (2.3 %) |
| F2 | shrine_b1-guilds_lodge_a2 vs shrine_b2-guilds_lodge_a1 | 142.7 m vs 146.0 m (2.3 %) |
| F2 | keep_t3-lairs_two_b2 vs keep_t4-lairs_two_a2 | 166.0 m vs 169.8 m (2.3 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t3-lairs_two_b2 | 169.8 m vs 166.0 m (2.3 %) |
| F2 | wallow_a2-cache_b_b2 vs wallow_b2-cache_b_a2 | 124.0 m vs 126.9 m (2.3 %) |
| F2 | rich_node_b1-post_s_b2 vs rich_node_b2-post_s_b1 | 133.9 m vs 130.9 m (2.3 %) |
| F2 | rich_node_a1-post_s_a2 vs rich_node_a2-post_s_a1 | 130.9 m vs 133.9 m (2.3 %) |
| F2 | rich_node_a1-post_s_a2 vs rich_node_b1-post_s_b2 | 130.9 m vs 133.9 m (2.3 %) |
| F2 | rich_node_a2-post_s_a1 vs rich_node_b2-post_s_b1 | 133.9 m vs 130.9 m (2.3 %) |
| F2 | wallow_a1-guilds_den_b1 vs wallow_b2-guilds_den_a2 | 205.6 m vs 200.9 m (2.3 %) |
| F2 | cache_b_a2-lairs_one_b1 vs cache_b_b2-lairs_one_a1 | 89.8 m vs 91.9 m (2.3 %) |
| F2 | third_node_b1-guilds_den_a1 vs third_node_b2-guilds_den_a2 | 212.0 m vs 207.2 m (2.3 %) |
| F2 | rich_hollow_a2-lairs_one_a2 vs rich_hollow_b2-lairs_one_b2 | 80.5 m vs 82.3 m (2.3 %) |
| F2 | keep_t1-lairs_two_a1 vs keep_t4-lairs_two_a2 | 166.0 m vs 169.8 m (2.3 %) |
| F2 | keep_t0-lairs_two_b1 vs keep_t1-lairs_two_a1 | 169.8 m vs 166.0 m (2.3 %) |
| F2 | home_b_a2-lairs_one_b2 vs home_b_b2-lairs_one_a2 | 172.4 m vs 176.4 m (2.3 %) |
| F2 | well_a2-rich_lodge_b2 vs well_b1-rich_lodge_a1 | 108.5 m vs 106.1 m (2.3 %) |
| F2 | home_a_a2-guilds_lodge_b1 vs home_a_b2-guilds_lodge_a1 | 161.2 m vs 157.5 m (2.3 %) |
| F2 | tower_c_a2-well_b2 vs tower_c_b2-well_a2 | 85.7 m vs 87.6 m (2.3 %) |
| F2 | tower_c_b1-well_a1 vs tower_c_b2-well_a2 | 85.7 m vs 87.6 m (2.3 %) |
| F2 | inn_a2-rich_lodge_b2 vs inn_b2-rich_lodge_a2 | 78.9 m vs 77.2 m (2.3 %) |
| F2 | inn_a1-rich_lodge_b1 vs inn_a2-rich_lodge_b2 | 77.2 m vs 78.9 m (2.3 %) |
| F2 | nat_node_a1-cache_b_b1 vs nat_node_b1-cache_b_a1 | 76.4 m vs 78.1 m (2.2 %) |
| F2 | home_b_b1-lairs_one_a1 vs home_b_b2-lairs_one_a2 | 172.5 m vs 176.4 m (2.2 %) |
| F2 | nat_node_a2-rich_hollow_b2 vs nat_node_b2-rich_hollow_a2 | 65.9 m vs 67.4 m (2.2 %) |
| F2 | nat_node_a1-rich_hollow_b1 vs nat_node_a2-rich_hollow_b2 | 67.4 m vs 65.9 m (2.2 %) |
| F2 | nat_node_b1-rich_hollow_a1 vs nat_node_b2-rich_hollow_a2 | 65.9 m vs 67.4 m (2.2 %) |
| F2 | nat_node_a1-rich_hollow_b1 vs nat_node_b1-rich_hollow_a1 | 67.4 m vs 65.9 m (2.2 %) |
| F2 | tower_c_b1-rich_hollow_b2 vs tower_c_b2-rich_hollow_b1 | 58.1 m vs 56.8 m (2.2 %) |
| F2 | rich_node_a2-cache_a_a1 vs rich_node_b2-cache_a_b1 | 120.9 m vs 118.2 m (2.2 %) |
| F2 | rich_node_a1-cache_a_a2 vs rich_node_a2-cache_a_a1 | 118.2 m vs 120.9 m (2.2 %) |
| F2 | rich_node_b1-cache_a_b2 vs rich_node_b2-cache_a_b1 | 120.9 m vs 118.2 m (2.2 %) |
| F2 | rich_node_a1-cache_a_a2 vs rich_node_b1-cache_a_b2 | 118.2 m vs 120.9 m (2.2 %) |
| F2 | lairs_one_a1-crown vs lairs_one_a2-crown | 106.6 m vs 109.0 m (2.2 %) |
| F2 | lairs_one_b1-crown vs lairs_one_b2-crown | 109.0 m vs 106.6 m (2.2 %) |
| F2 | lairs_one_a2-crown vs lairs_one_b2-crown | 109.0 m vs 106.6 m (2.2 %) |
| F2 | lairs_one_a1-crown vs lairs_one_b1-crown | 106.6 m vs 109.0 m (2.2 %) |
| F2 | rich_hollow_b1-lairs_one_b1 vs rich_hollow_b2-lairs_one_b2 | 80.5 m vs 82.3 m (2.2 %) |
| F2 | rich_hollow_a1-lairs_one_a1 vs rich_hollow_a2-lairs_one_a2 | 82.3 m vs 80.5 m (2.2 %) |
| F2 | wallow_a1-rich_lodge_a1 vs wallow_a2-rich_lodge_a2 | 90.1 m vs 92.2 m (2.2 %) |
| F2 | keep_t0-guilds_den_a1 vs keep_t3-guilds_den_a2 | 45.5 m vs 44.5 m (2.2 %) |
| F2 | keep_t3-guilds_den_a2 vs keep_t4-guilds_den_b2 | 44.5 m vs 45.5 m (2.2 %) |
| F2 | keep_t1-guilds_den_b1 vs keep_t4-guilds_den_b2 | 44.5 m vs 45.5 m (2.2 %) |
| F2 | keep_t0-guilds_den_a1 vs keep_t1-guilds_den_b1 | 45.5 m vs 44.5 m (2.2 %) |
| F2 | inn_a2-guilds_lodge_b2 vs inn_b2-guilds_lodge_a2 | 146.5 m vs 149.8 m (2.2 %) |
| F2 | inn_a1-guilds_lodge_b1 vs inn_b1-guilds_lodge_a1 | 149.8 m vs 146.5 m (2.2 %) |
| F2 | inn_a1-guilds_lodge_b1 vs inn_a2-guilds_lodge_b2 | 149.8 m vs 146.5 m (2.2 %) |
| F2 | inn_b1-guilds_lodge_a1 vs inn_b2-guilds_lodge_a2 | 146.5 m vs 149.8 m (2.2 %) |
| F2 | tower_r_a2-inn_b1 vs tower_r_b2-inn_a1 | 66.6 m vs 65.1 m (2.2 %) |
| F2 | nat_node_a1-tower_r_b2 vs nat_node_b2-tower_r_a1 | 75.1 m vs 73.4 m (2.2 %) |
| F2 | wallow_b1-rich_lodge_b1 vs wallow_b2-rich_lodge_b2 | 91.9 m vs 89.9 m (2.2 %) |
| F2 | cache_a_a2-x_lane_e vs cache_a_b2-x_lane_w | 92.2 m vs 94.3 m (2.2 %) |
| F2 | well_a1-x_lane_e vs well_a2-x_lane_e | 76.8 m vs 78.6 m (2.2 %) |
| F2 | well_a2-x_lane_e vs well_b2-x_lane_w | 78.6 m vs 76.8 m (2.2 %) |
| F2 | third_node_a1-cache_a_b2 vs third_node_b1-cache_a_a2 | 120.8 m vs 118.2 m (2.2 %) |
| F2 | third_node_b1-cache_a_a2 vs third_node_b2-cache_a_a1 | 118.2 m vs 120.8 m (2.2 %) |
| F2 | cache_a_a1-x_lane_e vs cache_a_a2-x_lane_e | 94.3 m vs 92.2 m (2.2 %) |
| F2 | nat_node_a2-cache_b_b2 vs nat_node_b1-cache_b_a1 | 76.4 m vs 78.1 m (2.2 %) |
| F2 | cache_b_b1-lairs_one_a2 vs cache_b_b2-lairs_one_a1 | 89.9 m vs 91.9 m (2.2 %) |
| F2 | cache_b_a1-lairs_one_b2 vs cache_b_a2-lairs_one_b1 | 91.9 m vs 89.8 m (2.2 %) |
| F2 | nat_node_a1-guilds_lodge_b1 vs nat_node_a2-guilds_lodge_b2 | 150.6 m vs 147.3 m (2.2 %) |
| F2 | nat_node_a2-guilds_lodge_b2 vs nat_node_b2-guilds_lodge_a2 | 147.3 m vs 150.6 m (2.2 %) |
| F2 | rich_node_b1-lairs_two_b2 vs rich_node_b2-lairs_two_b1 | 129.7 m vs 126.9 m (2.2 %) |
| F2 | rich_node_a2-lairs_two_a1 vs rich_node_b2-lairs_two_b1 | 129.7 m vs 126.9 m (2.2 %) |
| F2 | rich_node_a1-lairs_two_a2 vs rich_node_b1-lairs_two_b2 | 126.9 m vs 129.7 m (2.2 %) |
| F2 | rich_node_a1-lairs_two_a2 vs rich_node_a2-lairs_two_a1 | 126.9 m vs 129.7 m (2.2 %) |
| F2 | tower_c_a2-rich_lodge_a1 vs tower_c_b2-rich_lodge_b1 | 63.8 m vs 62.4 m (2.2 %) |
| F2 | post_w_b1-guilds_lodge_a2 vs post_w_b2-guilds_lodge_a1 | 166.0 m vs 169.7 m (2.2 %) |
| F2 | guilds_den_a2-peddler_a2 vs guilds_den_b2-peddler_b2 | 59.8 m vs 61.1 m (2.2 %) |
| F2 | guilds_den_a1-peddler_a1 vs guilds_den_b1-peddler_b1 | 61.1 m vs 59.8 m (2.2 %) |
| F2 | guilds_den_b1-peddler_b1 vs guilds_den_b2-peddler_b2 | 59.8 m vs 61.1 m (2.2 %) |
| F2 | guilds_den_a1-peddler_a1 vs guilds_den_a2-peddler_a2 | 61.1 m vs 59.8 m (2.2 %) |
| F2 | third_node_a1-well_b1 vs third_node_b2-well_a2 | 172.5 m vs 176.3 m (2.2 %) |
| F2 | rich_hollow_a1-lairs_one_a1 vs rich_hollow_b1-lairs_one_b1 | 82.3 m vs 80.5 m (2.2 %) |
| F2 | home_a_b1-lairs_one_a1 vs home_a_b2-lairs_one_a2 | 166.4 m vs 170.1 m (2.2 %) |
| F2 | home_a_a2-lairs_one_b2 vs home_a_b2-lairs_one_a2 | 166.4 m vs 170.1 m (2.2 %) |
| F2 | shrine_b1-guilds_lodge_a1 vs shrine_b2-guilds_lodge_a2 | 155.6 m vs 152.2 m (2.2 %) |
| F2 | nat_node_b1-tower_r_a2 vs nat_node_b2-tower_r_a1 | 75.1 m vs 73.4 m (2.2 %) |
| F2 | tower_r_a1-tower_c_a2 vs tower_r_a2-tower_c_a1 | 73.0 m vs 74.6 m (2.2 %) |
| F2 | tower_r_a2-tower_c_a1 vs tower_r_b2-tower_c_b1 | 74.6 m vs 73.0 m (2.2 %) |
| F2 | tower_r_a1-tower_c_a2 vs tower_r_b1-tower_c_b2 | 73.0 m vs 74.6 m (2.1 %) |
| F2 | tower_r_b1-tower_c_b2 vs tower_r_b2-tower_c_b1 | 74.6 m vs 73.0 m (2.1 %) |
| F2 | tower_c_a2-rich_hollow_a1 vs tower_c_b2-rich_hollow_b1 | 58.0 m vs 56.8 m (2.1 %) |
| F2 | tower_r_a2-inn_b1 vs tower_r_b1-inn_a2 | 66.6 m vs 65.2 m (2.1 %) |
| F2 | home_a_a2-wallow_b2 vs home_a_b2-wallow_a2 | 166.7 m vs 163.2 m (2.1 %) |
| F2 | home_a_a1-wallow_b1 vs home_a_a2-wallow_b2 | 163.2 m vs 166.7 m (2.1 %) |
| F2 | cache_b_a1-lairs_one_b2 vs cache_b_b1-lairs_one_a2 | 91.9 m vs 89.9 m (2.1 %) |
| F2 | home_b_a1-post_w_b2 vs home_b_b1-post_w_a2 | 150.3 m vs 147.2 m (2.1 %) |
| F2 | home_b_b1-post_w_a2 vs home_b_b2-post_w_a1 | 147.2 m vs 150.3 m (2.1 %) |
| F2 | home_b_a1-post_w_b2 vs home_b_a2-post_w_b1 | 150.3 m vs 147.2 m (2.1 %) |
| F2 | home_b_a2-post_w_b1 vs home_b_b2-post_w_a1 | 147.2 m vs 150.3 m (2.1 %) |
| F2 | rich_hollow_a2-guilds_den_b1 vs rich_hollow_b2-guilds_den_a1 | 74.7 m vs 73.1 m (2.1 %) |
| F2 | rich_hollow_a1-guilds_den_b2 vs rich_hollow_a2-guilds_den_b1 | 73.1 m vs 74.7 m (2.1 %) |
| F2 | rich_hollow_b1-guilds_den_a2 vs rich_hollow_b2-guilds_den_a1 | 74.7 m vs 73.1 m (2.1 %) |
| F2 | rich_hollow_a1-guilds_den_b2 vs rich_hollow_b1-guilds_den_a2 | 73.1 m vs 74.7 m (2.1 %) |
| F2 | well_a1-rich_den_a1 vs well_a2-rich_den_a2 | 36.5 m vs 35.8 m (2.1 %) |
| F2 | well_a2-rich_den_a2 vs well_b2-rich_den_b2 | 35.8 m vs 36.5 m (2.1 %) |
| F2 | well_a1-rich_den_a1 vs well_b1-rich_den_b1 | 36.5 m vs 35.8 m (2.1 %) |
| F2 | well_b1-rich_den_b1 vs well_b2-rich_den_b2 | 35.8 m vs 36.5 m (2.1 %) |
| F2 | wallow_a2-lairs_one_b2 vs wallow_b2-lairs_one_a2 | 188.0 m vs 192.0 m (2.1 %) |
| F2 | wallow_b1-lairs_one_a1 vs wallow_b2-lairs_one_a2 | 188.0 m vs 192.0 m (2.1 %) |
| F2 | tower_r_b1-stag_b2 vs tower_r_b2-stag_b1 | 147.4 m vs 150.5 m (2.0 %) |
| F2 | third_node_a1-tower_r_b1 vs third_node_b2-tower_r_a2 | 168.2 m vs 164.7 m (2.0 %) |
| F2 | tower_r_a2-stag_a1 vs tower_r_b2-stag_b1 | 147.4 m vs 150.5 m (2.0 %) |
| F2 | well_b1-x_lane_w vs well_b2-x_lane_w | 78.4 m vs 76.8 m (2.0 %) |
| F2 | well_a1-x_lane_e vs well_b1-x_lane_w | 76.8 m vs 78.4 m (2.0 %) |
| F2 | tower_c_a1-rich_lodge_a2 vs tower_c_a2-rich_lodge_a1 | 62.5 m vs 63.8 m (2.0 %) |
| F2 | shrine_a2-cache_a_a2 vs shrine_b2-cache_a_b2 | 56.5 m vs 55.4 m (2.0 %) |
| F2 | shrine_a1-cache_a_a1 vs shrine_a2-cache_a_a2 | 55.4 m vs 56.5 m (2.0 %) |
| F2 | shrine_b1-cache_a_b1 vs shrine_b2-cache_a_b2 | 56.5 m vs 55.4 m (2.0 %) |
| F2 | shrine_a1-cache_a_a1 vs shrine_b1-cache_a_b1 | 55.4 m vs 56.5 m (2.0 %) |
| F2 | stag_b1-post_w_a2 vs stag_b2-post_w_a1 | 136.7 m vs 133.9 m (2.0 %) |
| F2 | rich_node_a1-well_b1 vs rich_node_b1-well_a1 | 114.7 m vs 112.4 m (2.0 %) |
| F2 | stag_a2-post_w_b1 vs stag_b1-post_w_a2 | 133.9 m vs 136.7 m (2.0 %) |
| F2 | wallow_a1-cache_a_a2 vs wallow_b1-cache_a_b2 | 112.1 m vs 109.9 m (2.0 %) |
| F2 | wallow_b1-cache_a_b2 vs wallow_b2-cache_a_b1 | 109.9 m vs 112.1 m (2.0 %) |
| F2 | wallow_a2-cache_a_a1 vs wallow_b2-cache_a_b1 | 109.9 m vs 112.1 m (2.0 %) |
| F2 | wallow_a1-cache_a_a2 vs wallow_a2-cache_a_a1 | 112.1 m vs 109.9 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 109 sources) 541.49 s.
- Map Lab v2 (map-production.md 2.5): layout quartermeet_s18, 4 seats, rules tempo standard, 3 fixable findings.
- Navmesh raster 2.61 s (1302 polygons, 451584 cells of 0.25 m), spot / mirror checks 3.02 s, 5886 paths 2.95 s.
- Map Quartermeet (seed 18), scene res://docs/tools/world_forge/out/quartermeet_s18/preview.tscn, sim mode off; level load + navmesh bake 0.7 s (677 frames), lab 571.2 s. Spec: docs/design/map-production.md.
