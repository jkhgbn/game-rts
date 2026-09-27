# Map Lab: Gloamspine Divide (2v2) scorecard: world_forge_gloamspine_divide

2026-09-27 15:29 · lab v1.0 · 104.72 s · scanned 95 spots

## Result: **WARN** · score **93 / 100**

0 FAIL · 4 WARN · 10 PASS · 1 info checks; findings: 0 FAIL, 157 WARN, 119 info

## Improve next
1. **No navmesh islands** (WARN): island 14 at (-51.9, 0.1): 40.6 m² of ground-level navmesh cut off from the main area (y 0.50) -> a pocket closed by colliders: widen its gap or fill it (trees / rocks) (close or open the pocket) _(from N3 4 / 8 clean (0 FAIL, 4 WARN), 5 info)_
2. **Unit paths (NavigationServer): pairs match their twins** (WARN): shrine_a1-wallow_b1 vs shrine_b1-wallow_a1: 126.9 m vs 157.9 m (19.6 %) -> units walk shrine_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 6432 / 6694 pairs within 2 % (0 FAIL, 148 WARN, 114 info))_
3. **Main routes: narrowest corridor matches the twin** (WARN): keep_t0 -> keep_t4: narrowest 8.6 m at (7.8, 9.8) vs its twin's 13.3 m -> a collider narrows this route only on one side _(from C2 10 / 12 clean (0 FAIL, 4 WARN))_
4. **Travel times per seat (worker / soldier / cavalry / caravan)** (WARN): enemy keep #2 (worker): 0:29 vs 0:33 between seats -> one seat's route is longer or crosses more ford: see the travel-time table _(from T1 6 / 7 clean (0 FAIL, 1 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 253 polygons, main area 24056 m² (94 % of the 160 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 95 / 95 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | **WARN** 52 | 4 / 8 clean (0 FAIL, 4 WARN), 5 info | ground-level components other than the main one < 2 m² | close or open the pocket |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 95 / 95 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 95 / 95 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (8 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6694 / 6694 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 6432 / 6694 pairs within 2 % (0 FAIL, 148 WARN, 114 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | PASS 100 | 10 / 10 clean | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | PASS 100 | 4 / 4 clean | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | **WARN** 64 | 6 / 7 clean (0 FAIL, 1 WARN) | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 8 / 8 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | **WARN** 63 | 10 / 12 clean (0 FAIL, 4 WARN) | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (640 x 640 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | N3 | island 14 at (-51.9, 0.1) | 40.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 15 at (-25.1, 0.1) | 55.7 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 16 at (25.3, 0.1) | 56.4 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 17 at (52.1, 0.1) | 40.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | F2 | shrine_a1-wallow_b1 vs shrine_b1-wallow_a1 | 126.9 m vs 157.9 m (19.6 %) | units walk shrine_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-wallow_a1 vs shrine_b1-wallow_a2 | 157.9 m vs 126.9 m (19.6 %) | units walk shrine_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_b2-node_b_b1 | 51.2 m vs 61.6 m (16.9 %) | units walk node_a_b2-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_a1 vs node_a_b2-node_b_b1 | 51.2 m vs 61.6 m (16.9 %) | units walk node_a_b2-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_b1-node_b_b2 | 51.2 m vs 61.6 m (16.9 %) | units walk node_a_b1-node_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_a1 vs node_a_b1-node_b_b2 | 51.2 m vs 61.6 m (16.9 %) | units walk node_a_b1-node_b_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-wallow_b2 vs shrine_b1-wallow_a1 | 132.1 m vs 157.9 m (16.4 %) | units walk shrine_b1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-fenwatch_a1 vs keep_t4-fenwatch_a2 | 101.5 m vs 117.1 m (13.3 %) | units walk keep_t4-fenwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-fenwatch_b2 vs keep_t4-fenwatch_a2 | 101.6 m vs 117.1 m (13.2 %) | units walk keep_t4-fenwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-bridge_nest_a1 vs shrine_b1-bridge_nest_a2 | 116.8 m vs 101.8 m (12.8 %) | units walk shrine_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-keep_t1 vs keep_t4-keep_t3 | 150.6 m vs 131.3 m (12.8 %) | units walk keep_t0-keep_t1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-bridge_nest_b2 vs shrine_b1-bridge_nest_a1 | 101.9 m vs 116.8 m (12.7 %) | units walk shrine_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-bridge_nest_b1 vs shrine_b1-bridge_nest_a1 | 102.0 m vs 116.8 m (12.7 %) | units walk shrine_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-fenwatch_b1 vs keep_t4-fenwatch_a2 | 102.3 m vs 117.1 m (12.6 %) | units walk keep_t4-fenwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | den_a1-cache_b2 vs den_b1-cache_a1 | 129.4 m vs 148.0 m (12.6 %) | units walk den_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | den_b1-cache_a1 vs den_b1-cache_a2 | 148.0 m vs 129.4 m (12.6 %) | units walk den_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | den_a1-cache_b1 vs den_b1-cache_a1 | 129.4 m vs 148.0 m (12.6 %) | units walk den_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-fordwatch_b2 vs node_a_b2-fordwatch_a2 | 103.1 m vs 90.5 m (12.2 %) | units walk node_a_a2-fordwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-fordwatch_b2 vs node_a_b1-fordwatch_a1 | 103.1 m vs 90.6 m (12.1 %) | units walk node_a_a2-fordwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b2 vs wallow_b2-peddler_a1 | 78.9 m vs 89.5 m (11.8 %) | units walk wallow_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-peddler_a2 vs wallow_b2-peddler_a1 | 79.0 m vs 89.5 m (11.8 %) | units walk wallow_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-peddler_b2 vs wallow_a2-peddler_b1 | 78.9 m vs 89.3 m (11.7 %) | units walk wallow_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-peddler_b1 vs wallow_b1-peddler_a2 | 89.3 m vs 79.0 m (11.6 %) | units walk wallow_a2-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-rich_a1 vs keep_t4-rich_a2 | 111.4 m vs 125.6 m (11.3 %) | units walk keep_t4-rich_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-peddler_b2 vs well_a2-peddler_b1 | 73.9 m vs 65.6 m (11.3 %) | units walk well_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-peddler_b1 vs well_b2-peddler_a1 | 65.6 m vs 73.9 m (11.3 %) | units walk well_b2-peddler_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-peddler_b1 vs well_b1-peddler_a2 | 65.6 m vs 73.8 m (11.2 %) | units walk well_b1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-rich_b2 vs keep_t1-rich_a1 | 124.9 m vs 111.4 m (10.8 %) | units walk keep_t3-rich_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_b1 vs keep_t4-rich_a2 | 112.1 m vs 125.6 m (10.7 %) | units walk keep_t4-rich_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_b1 vs keep_t3-rich_b2 | 112.1 m vs 124.9 m (10.2 %) | units walk keep_t3-rich_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-fordwatch_a1 vs keep_t4-fordwatch_a2 | 90.9 m vs 101.0 m (10.1 %) | units walk keep_t4-fordwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_b1-ford_s vs peddler_b2-ford_n | 96.4 m vs 86.7 m (10.1 %) | units walk peddler_b1-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-ford_s vs peddler_b2-ford_n | 96.1 m vs 86.7 m (9.8 %) | units walk peddler_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-ford_n vs peddler_b2-ford_n | 96.1 m vs 86.7 m (9.8 %) | units walk peddler_a1-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-bridge_nest_a1 vs node_a_b2-bridge_nest_a2 | 119.9 m vs 108.3 m (9.7 %) | units walk node_a_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_b2 vs shrine_b1-cache_a1 | 124.0 m vs 137.2 m (9.6 %) | units walk shrine_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-cache_a1 vs shrine_b1-cache_a2 | 137.2 m vs 124.0 m (9.6 %) | units walk shrine_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-cache_b1 vs shrine_b1-cache_a1 | 124.0 m vs 137.2 m (9.6 %) | units walk shrine_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-fordwatch_b1 vs keep_t4-fordwatch_a2 | 91.4 m vs 101.0 m (9.5 %) | units walk keep_t4-fordwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-fordwatch_b2 vs keep_t1-fordwatch_a1 | 100.4 m vs 90.9 m (9.5 %) | units walk keep_t3-fordwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-tavern_a1 vs node_a_b1-tavern_b2 | 68.6 m vs 62.3 m (9.2 %) | units walk node_a_a2-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-tavern_a1 vs node_a_b2-tavern_b1 | 68.6 m vs 62.3 m (9.2 %) | units walk node_a_a2-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-tavern_a2 vs node_a_b1-tavern_b2 | 68.5 m vs 62.3 m (9.1 %) | units walk node_a_a1-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-tavern_a2 vs node_a_b2-tavern_b1 | 68.5 m vs 62.3 m (9.1 %) | units walk node_a_a1-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-fordwatch_b1 vs keep_t3-fordwatch_b2 | 91.4 m vs 100.4 m (9.0 %) | units walk keep_t3-fordwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-wallow_b1 vs node_a_b2-wallow_b2 | 35.5 m vs 32.3 m (8.8 %) | units walk node_a_b1-wallow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-peddler_b2 vs bridge_nest_a2-peddler_b1 | 52.7 m vs 48.1 m (8.8 %) | units walk bridge_nest_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_a_b1 vs keep_t1-node_a_a1 | 146.0 m vs 133.4 m (8.6 %) | units walk keep_t0-node_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_a_b1 vs keep_t3-node_a_b2 | 146.0 m vs 133.4 m (8.6 %) | units walk keep_t0-node_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-peddler_b2 vs bridge_nest_b1-peddler_a2 | 52.7 m vs 48.2 m (8.5 %) | units walk bridge_nest_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-wallow_a1 vs node_a_b2-wallow_b2 | 35.3 m vs 32.3 m (8.4 %) | units walk node_a_a1-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_a_b1 vs node_a_b2-node_a_a2 | 148.5 m vs 136.1 m (8.3 %) | units walk node_a_a1-node_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-wallow_a2 vs node_a_b2-wallow_b2 | 35.2 m vs 32.3 m (8.2 %) | units walk node_a_a2-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_a_b1 vs keep_t4-node_a_a2 | 146.0 m vs 134.0 m (8.2 %) | units walk keep_t0-node_a_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-peddler_b2 vs bridge_nest_b2-peddler_a1 | 52.7 m vs 48.5 m (8.1 %) | units walk bridge_nest_a1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a2-cache_a1 vs spine_post_b1-cache_b2 | 132.1 m vs 143.1 m (7.6 %) | units walk spine_post_b1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-cache_a2 vs spine_post_b1-cache_b2 | 132.1 m vs 143.1 m (7.6 %) | units walk spine_post_b1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_b1-cache_b2 vs spine_post_b2-cache_b1 | 143.1 m vs 132.2 m (7.6 %) | units walk spine_post_b1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-fen_post_b1 vs stag_b2-fen_post_a2 | 165.1 m vs 153.2 m (7.2 %) | units walk stag_a1-fen_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-fen_post_b1 vs stag_a2-fen_post_b2 | 165.1 m vs 153.2 m (7.2 %) | units walk stag_a1-fen_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | hollow_a1-cache_b1 vs hollow_b1-cache_a1 | 98.9 m vs 106.4 m (7.0 %) | units walk hollow_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | hollow_a1-cache_b1 vs hollow_a1-cache_b2 | 98.9 m vs 106.3 m (7.0 %) | units walk hollow_a1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | hollow_a1-cache_b1 vs hollow_b1-cache_a2 | 98.9 m vs 106.2 m (6.9 %) | units walk hollow_b1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_b1-heath_lair_b2 vs spine_post_b2-heath_lair_b1 | 159.0 m vs 148.4 m (6.7 %) | units walk spine_post_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a2-heath_lair_a1 vs spine_post_b1-heath_lair_b2 | 148.4 m vs 159.0 m (6.7 %) | units walk spine_post_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-heath_lair_a2 vs spine_post_b1-heath_lair_b2 | 148.4 m vs 159.0 m (6.7 %) | units walk spine_post_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-ford_s vs node_a_b1-ford_s | 90.8 m vs 84.8 m (6.6 %) | units walk node_a_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-ford_nest_a1 vs node_a_b1-ford_nest_a1 | 90.8 m vs 84.8 m (6.6 %) | units walk node_a_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-ford_nest_a1 vs node_a_b2-ford_nest_a2 | 90.8 m vs 84.8 m (6.5 %) | units walk node_a_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-ford_s vs node_a_b2-ford_n | 90.8 m vs 84.8 m (6.5 %) | units walk node_a_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-ford_nest_a2 vs node_a_b1-ford_nest_a1 | 90.7 m vs 84.8 m (6.5 %) | units walk node_a_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-ford_n vs node_a_b1-ford_s | 90.7 m vs 84.8 m (6.5 %) | units walk node_a_a1-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-ford_n vs node_a_b2-ford_n | 90.7 m vs 84.8 m (6.5 %) | units walk node_a_a1-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-ford_nest_a2 vs node_a_b2-ford_nest_a2 | 90.7 m vs 84.8 m (6.5 %) | units walk node_a_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fen_post_a2-cache_b2 vs fen_post_b1-cache_a1 | 147.4 m vs 157.6 m (6.5 %) | units walk fen_post_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fen_post_b1-cache_a1 vs fen_post_b2-cache_a2 | 157.6 m vs 147.4 m (6.5 %) | units walk fen_post_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fen_post_a1-cache_b1 vs fen_post_b1-cache_a1 | 147.4 m vs 157.6 m (6.5 %) | units walk fen_post_b1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-fordwatch_a1 vs node_a_b1-fordwatch_b2 | 83.9 m vs 78.5 m (6.4 %) | units walk node_a_a2-fordwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-fordwatch_a1 vs node_a_b2-fordwatch_b1 | 83.9 m vs 78.5 m (6.4 %) | units walk node_a_a2-fordwatch_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a2-peddler_a1 | 92.5 m vs 86.6 m (6.4 %) | units walk ford_nest_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fordwatch_b1 vs node_a_a2-fordwatch_b2 | 96.6 m vs 103.1 m (6.4 %) | units walk node_a_a2-fordwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fordwatch_a2 vs node_a_b1-fordwatch_b2 | 83.9 m vs 78.5 m (6.3 %) | units walk node_a_a1-fordwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fordwatch_a2 vs node_a_b2-fordwatch_b1 | 83.9 m vs 78.5 m (6.3 %) | units walk node_a_a1-fordwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_b2 vs shrine_b1-stag_a1 | 142.8 m vs 152.5 m (6.3 %) | units walk shrine_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_b1-stag_a1 vs shrine_b1-stag_a2 | 152.5 m vs 142.8 m (6.3 %) | units walk shrine_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fordwatch_b1 vs node_a_b2-fordwatch_a2 | 96.6 m vs 90.5 m (6.3 %) | units walk node_a_a1-fordwatch_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a1-peddler_b1 | 92.5 m vs 86.7 m (6.2 %) | units walk ford_nest_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_b1 vs shrine_a1-stag_b2 | 152.3 m vs 142.8 m (6.2 %) | units walk shrine_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | shrine_a1-stag_b1 vs shrine_b1-stag_a2 | 152.3 m vs 142.8 m (6.2 %) | units walk shrine_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-peddler_a1 vs ford_nest_a2-peddler_b2 | 86.6 m vs 92.3 m (6.2 %) | units walk ford_nest_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fordwatch_b1 vs node_a_b1-fordwatch_a1 | 96.6 m vs 90.6 m (6.2 %) | units walk node_a_a1-fordwatch_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-stag_a1 vs rich_b1-stag_b2 | 132.8 m vs 141.4 m (6.1 %) | units walk rich_b1-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-stag_a2 vs rich_a2-stag_a1 | 141.4 m vs 132.8 m (6.1 %) | units walk rich_a1-stag_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-stag_a1 vs rich_b2-stag_b1 | 132.8 m vs 141.4 m (6.1 %) | units walk rich_b2-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-ford_nest_a2 vs wallow_a2-ford_nest_a1 | 98.9 m vs 105.4 m (6.1 %) | units walk wallow_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-ford_n vs wallow_a2-ford_s | 98.9 m vs 105.4 m (6.1 %) | units walk wallow_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_b1 vs ford_nest_a2-peddler_b2 | 86.7 m vs 92.3 m (6.1 %) | units walk ford_nest_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_b1-well_a1 vs fenwatch_b2-well_a2 | 84.8 m vs 79.6 m (6.0 %) | units walk fenwatch_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a1-well_b1 vs fenwatch_b1-well_a1 | 79.6 m vs 84.8 m (6.0 %) | units walk fenwatch_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a2-well_b2 vs fenwatch_b1-well_a1 | 79.7 m vs 84.8 m (6.0 %) | units walk fenwatch_b1-well_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_b2 vs node_a_a2-mouth_lair_b1 | 95.6 m vs 101.7 m (6.0 %) | units walk node_a_a2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_b1 vs node_a_b1-mouth_lair_a2 | 101.7 m vs 95.6 m (6.0 %) | units walk node_a_a2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_b1 vs node_a_b2-mouth_lair_a1 | 101.7 m vs 95.6 m (6.0 %) | units walk node_a_a2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-ford_nest_a1 vs wallow_b1-ford_nest_a1 | 105.4 m vs 99.1 m (5.9 %) | units walk wallow_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-ford_s vs wallow_b1-ford_s | 105.4 m vs 99.1 m (5.9 %) | units walk wallow_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-ford_nest_a2 vs wallow_b2-ford_nest_a2 | 98.9 m vs 105.2 m (5.9 %) | units walk wallow_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-ford_n vs wallow_b2-ford_n | 98.9 m vs 105.2 m (5.9 %) | units walk wallow_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a2-peddler_a1 vs spine_post_b1-peddler_b2 | 118.6 m vs 126.0 m (5.9 %) | units walk spine_post_b1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-ford_n vs glade_vein_a2-ford_s | 115.2 m vs 122.4 m (5.9 %) | units walk glade_vein_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-ford_nest_a2 vs glade_vein_a2-ford_nest_a1 | 115.2 m vs 122.4 m (5.9 %) | units walk glade_vein_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-peddler_a2 vs spine_post_a2-peddler_a1 | 126.0 m vs 118.6 m (5.9 %) | units walk spine_post_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_b1-peddler_b2 vs spine_post_b2-peddler_b1 | 126.0 m vs 118.6 m (5.8 %) | units walk spine_post_b1-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-ford_s vs natural_b2-ford_n | 81.6 m vs 76.8 m (5.8 %) | units walk natural_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-ford_nest_a1 vs natural_b2-ford_nest_a2 | 81.6 m vs 76.8 m (5.8 %) | units walk natural_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-peddler_a2 vs spine_post_b2-peddler_b1 | 126.0 m vs 118.6 m (5.8 %) | units walk spine_post_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-fen_post_b1 vs stag_b1-fen_post_a1 | 165.1 m vs 155.5 m (5.8 %) | units walk stag_a1-fen_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-ford_n vs natural_b2-ford_n | 81.5 m vs 76.8 m (5.8 %) | units walk natural_a1-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-ford_nest_a2 vs natural_b2-ford_nest_a2 | 81.5 m vs 76.8 m (5.8 %) | units walk natural_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-ford_s vs natural_b1-ford_s | 81.6 m vs 76.9 m (5.8 %) | units walk natural_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-ford_nest_a1 vs natural_b1-ford_nest_a1 | 81.6 m vs 76.9 m (5.8 %) | units walk natural_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-ford_s vs glade_vein_b1-ford_s | 122.4 m vs 115.4 m (5.8 %) | units walk glade_vein_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-ford_nest_a1 vs glade_vein_b1-ford_nest_a1 | 122.4 m vs 115.4 m (5.8 %) | units walk glade_vein_a2-ford_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-ford_s vs wallow_b2-ford_n | 99.1 m vs 105.2 m (5.8 %) | units walk wallow_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 99.1 m vs 105.2 m (5.8 %) | units walk wallow_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-ford_n vs glade_vein_b2-ford_n | 115.2 m vs 122.2 m (5.7 %) | units walk glade_vein_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-ford_nest_a2 vs glade_vein_b2-ford_nest_a2 | 115.2 m vs 122.2 m (5.7 %) | units walk glade_vein_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-ford_nest_a2 vs natural_b1-ford_nest_a1 | 81.5 m vs 76.9 m (5.7 %) | units walk natural_a1-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-ford_n vs natural_b1-ford_s | 81.5 m vs 76.9 m (5.7 %) | units walk natural_a1-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-cache_b1 vs node_a_b2-cache_b2 | 49.5 m vs 46.7 m (5.7 %) | units walk node_a_b1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-ford_nest_a1 vs glade_vein_b2-ford_nest_a2 | 115.4 m vs 122.2 m (5.6 %) | units walk glade_vein_b2-ford_nest_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-ford_s vs glade_vein_b2-ford_n | 115.4 m vs 122.2 m (5.6 %) | units walk glade_vein_b2-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-fenwatch_b2 vs node_a_b1-fenwatch_a1 | 107.2 m vs 101.2 m (5.6 %) | units walk node_a_a2-fenwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fenwatch_b1 vs node_a_b1-fenwatch_a1 | 107.2 m vs 101.2 m (5.6 %) | units walk node_a_a1-fenwatch_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-fenwatch_b2 vs node_a_b2-fenwatch_a2 | 107.2 m vs 101.3 m (5.5 %) | units walk node_a_a2-fenwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fenwatch_b1 vs node_a_b2-fenwatch_a2 | 107.2 m vs 101.3 m (5.5 %) | units walk node_a_a1-fenwatch_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-cache_a2 vs ford_nest_a2-cache_a1 | 109.7 m vs 103.7 m (5.5 %) | units walk ford_nest_a1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-cache_a1 vs node_a_b2-cache_b2 | 49.3 m vs 46.7 m (5.3 %) | units walk node_a_a1-cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-cache_a2 vs ford_nest_a1-cache_b1 | 109.7 m vs 103.8 m (5.3 %) | units walk ford_nest_a1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-cache_a1 vs ford_nest_a2-cache_b2 | 103.7 m vs 109.5 m (5.3 %) | units walk ford_nest_a2-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-cache_a2 vs node_a_b2-cache_b2 | 49.3 m vs 46.7 m (5.3 %) | units walk node_a_a2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-bridge_nest_b1 vs node_a_b2-bridge_nest_a2 | 114.3 m vs 108.3 m (5.2 %) | units walk node_a_a1-bridge_nest_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-bridge_nest_b2 vs node_a_b2-bridge_nest_a2 | 114.3 m vs 108.3 m (5.2 %) | units walk node_a_a2-bridge_nest_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-cache_b1 vs ford_nest_a2-cache_b2 | 103.8 m vs 109.5 m (5.2 %) | units walk ford_nest_a2-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-fen_post_b2 vs bridge_nest_a2-fen_post_b1 | 103.2 m vs 108.8 m (5.1 %) | units walk bridge_nest_a2-fen_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-rich_b2 vs node_a_b1-rich_a1 | 117.0 m vs 111.1 m (5.1 %) | units walk node_a_a2-rich_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-rich_b1 vs node_a_b1-rich_a1 | 117.0 m vs 111.1 m (5.1 %) | units walk node_a_a1-rich_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-rich_b2 vs node_a_b2-rich_a2 | 117.0 m vs 111.1 m (5.1 %) | units walk node_a_a2-rich_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-rich_b1 vs node_a_b2-rich_a2 | 117.0 m vs 111.1 m (5.0 %) | units walk node_a_a1-rich_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | T1 | enemy keep #2 (worker) | 0:29 vs 0:33 between seats | one seat's route is longer or crosses more ford: see the travel-time table |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 8.6 m at (7.8, 9.8) vs its twin's 13.3 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t0 -> keep_t4 | narrowest 8.6 m at (7.8, 9.8) vs its twin's 13.3 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t3 -> keep_t4 | narrowest 6.1 m at (9.2, 5.4) vs its twin's 13.9 m | a collider narrows this route only on one side |
| WARN | C2 | keep_t3 -> keep_t4 | narrowest 6.1 m at (9.2, 5.4) vs its twin's 13.9 m | a collider narrows this route only on one side |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-62.0, 28.0) | (-61.1, 24.4) | keep_t4 | (-61.1, 24.4) | 0.0 |
| keep_t3 | keep | (-62.0, -28.0) | (-60.6, -23.9) | keep_t1 | (-60.6, -23.9) | 0.0 |
| keep_t1 | keep | (62.0, -28.0) | (60.6, -23.9) | keep_t3 | (60.6, -23.9) | 0.0 |
| keep_t4 | keep | (62.0, 28.0) | (61.1, 24.4) | keep_t0 | (61.1, 24.4) | 0.0 |
| node_a_a1 | home_node | (-65.0, 19.0) | (-64.9, 18.9) | node_a_b2 | (-64.9, 18.9) | 0.0 |
| node_a_a2 | home_node | (-65.0, -19.0) | (-64.9, -18.9) | node_a_b1 | (-64.9, -18.9) | 0.0 |
| node_a_b1 | home_node | (65.0, -19.0) | (64.9, -18.9) | node_a_a2 | (64.9, -18.9) | 0.0 |
| node_a_b2 | home_node | (65.0, 19.0) | (64.9, 18.9) | node_a_a1 | (64.9, 18.9) | 0.0 |
| node_b_a1 | home_node | (-53.0, 31.0) | (-52.9, 30.9) | node_b_b2 | (-52.9, 30.9) | 0.0 |
| node_b_a2 | home_node | (-53.0, -31.0) | (-52.9, -30.9) | node_b_b1 | (-52.9, -30.9) | 0.0 |
| node_b_b1 | home_node | (53.0, -31.0) | (52.9, -30.9) | node_b_a2 | (52.9, -30.9) | 0.0 |
| node_b_b2 | home_node | (53.0, 31.0) | (52.9, 30.9) | node_b_a1 | (52.9, 30.9) | 0.0 |
| natural_a1 | expansion | (-35.0, 25.0) | (-34.9, 24.9) | natural_b2 | (-34.9, 24.9) | 0.0 |
| natural_a2 | expansion | (-35.0, -25.0) | (-34.9, -24.9) | natural_b1 | (-34.9, -24.9) | 0.0 |
| natural_b1 | expansion | (35.0, -25.0) | (34.9, -24.9) | natural_a2 | (34.9, -24.9) | 0.0 |
| natural_b2 | expansion | (35.0, 25.0) | (34.9, 24.9) | natural_a1 | (34.9, 24.9) | 0.0 |
| glade_vein_a1 | expansion | (-58.0, 60.0) | (-57.9, 59.9) | glade_vein_b2 | (-57.9, 59.9) | 0.0 |
| glade_vein_a2 | expansion | (-58.0, -60.0) | (-57.9, -59.9) | glade_vein_b1 | (-57.9, -59.9) | 0.0 |
| glade_vein_b1 | expansion | (58.0, -60.0) | (57.9, -59.9) | glade_vein_a2 | (57.9, -59.9) | 0.0 |
| glade_vein_b2 | expansion | (58.0, 60.0) | (57.9, 59.9) | glade_vein_a1 | (57.9, 59.9) | 0.0 |
| rich_a1 | expansion | (-14.0, 58.0) | (-13.9, 57.9) | rich_b2 | (-13.9, 57.9) | 0.0 |
| rich_a2 | expansion | (-14.0, -58.0) | (-13.9, -57.9) | rich_b1 | (-13.9, -57.9) | 0.0 |
| rich_b1 | expansion | (14.0, -58.0) | (13.9, -57.9) | rich_a2 | (13.9, -57.9) | 0.0 |
| rich_b2 | expansion | (14.0, 58.0) | (13.9, 57.9) | rich_a1 | (13.9, 57.9) | 0.0 |
| fenwatch_a1 | point | (-8.0, 50.0) | (-7.9, 49.9) | fenwatch_b2 | (-7.9, 49.9) | 0.0 |
| fenwatch_a2 | point | (-8.0, -50.0) | (-7.9, -49.9) | fenwatch_b1 | (-7.9, -49.9) | 0.0 |
| fenwatch_b1 | point | (8.0, -50.0) | (7.9, -49.9) | fenwatch_a2 | (7.9, -49.9) | 0.0 |
| fenwatch_b2 | point | (8.0, 50.0) | (7.9, 49.9) | fenwatch_a1 | (7.9, 49.9) | 0.0 |
| well_a1 | point | (-26.0, 12.0) | (-25.9, 11.9) | well_b2 | (-25.9, 11.9) | 0.0 |
| well_a2 | point | (-26.0, -12.0) | (-25.9, -11.9) | well_b1 | (-25.9, -11.9) | 0.0 |
| well_b1 | point | (26.0, -12.0) | (25.9, -11.9) | well_a2 | (25.9, -11.9) | 0.0 |
| well_b2 | point | (26.0, 12.0) | (25.9, 11.9) | well_a1 | (25.9, 11.9) | 0.0 |
| fordwatch_a1 | point | (-7.0, 34.0) | (-6.9, 33.9) | fordwatch_b2 | (-6.9, 33.9) | 0.0 |
| fordwatch_a2 | point | (-7.0, -34.0) | (-6.9, -33.9) | fordwatch_b1 | (-6.9, -33.9) | 0.0 |
| fordwatch_b1 | point | (7.0, -34.0) | (6.9, -33.9) | fordwatch_a2 | (6.9, -33.9) | 0.0 |
| fordwatch_b2 | point | (7.0, 34.0) | (6.9, 33.9) | fordwatch_a1 | (6.9, 33.9) | 0.0 |
| shrine_a1 | point | (-70.0, 0.0) | (-69.9, 0.1) | shrine_b1 | (-69.9, 0.1) | 0.0 |
| shrine_b1 | point | (70.0, 0.0) | (69.9, 0.1) | shrine_a1 | (69.9, 0.1) | 0.0 |
| stag_a1 | camp | (-56.0, 68.0) | (-55.9, 67.9) | stag_b2 | (-55.9, 67.9) | 0.0 |
| stag_a2 | camp | (-56.0, -68.0) | (-55.9, -67.9) | stag_b1 | (-55.9, -67.9) | 0.0 |
| stag_b1 | camp | (56.0, -68.0) | (55.9, -67.9) | stag_a2 | (55.9, -67.9) | 0.0 |
| stag_b2 | camp | (56.0, 68.0) | (55.9, 67.9) | stag_a1 | (55.9, 67.9) | 0.0 |
| wallow_a1 | camp | (-48.0, 46.0) | (-47.9, 45.9) | wallow_b2 | (-47.9, 45.9) | 0.0 |
| wallow_a2 | camp | (-48.0, -46.0) | (-47.9, -45.9) | wallow_b1 | (-47.9, -45.9) | 0.0 |
| wallow_b1 | camp | (48.0, -46.0) | (47.9, -45.9) | wallow_a2 | (47.9, -45.9) | 0.0 |
| wallow_b2 | camp | (48.0, 46.0) | (47.9, 45.9) | wallow_a1 | (47.9, 45.9) | 0.0 |
| bridge_nest_a1 | camp | (-5.0, 58.0) | (-4.9, 57.9) | bridge_nest_b2 | (-4.9, 57.9) | 0.0 |
| bridge_nest_a2 | camp | (-5.0, -58.0) | (-4.9, -57.9) | bridge_nest_b1 | (-4.9, -57.9) | 0.0 |
| bridge_nest_b1 | camp | (5.0, -58.0) | (4.9, -57.9) | bridge_nest_a2 | (4.9, -57.9) | 0.0 |
| bridge_nest_b2 | camp | (5.0, 58.0) | (4.9, 57.9) | bridge_nest_a1 | (4.9, 57.9) | 0.0 |
| hollow_a1 | camp | (-40.0, 0.0) | (-39.9, 0.1) | hollow_b1 | (-39.9, 0.1) | 0.0 |
| hollow_b1 | camp | (40.0, 0.0) | (39.9, 0.1) | hollow_a1 | (39.9, 0.1) | 0.0 |
| ford_nest_a1 | camp | (0.0, 36.0) | (-0.1, 35.9) | ford_nest_a1 | (0.1, 35.9) | 0.3 |
| ford_nest_a2 | camp | (0.0, -36.0) | (-0.1, -35.9) | ford_nest_a2 | (0.1, -35.9) | 0.3 |
| tavern_a1 | tavern | (-18.0, 22.0) | (-17.9, 21.9) | tavern_b2 | (-17.9, 21.9) | 0.0 |
| tavern_a2 | tavern | (-18.0, -22.0) | (-17.9, -21.9) | tavern_b1 | (-17.9, -21.9) | 0.0 |
| tavern_b1 | tavern | (18.0, -22.0) | (17.9, -21.9) | tavern_a2 | (17.9, -21.9) | 0.0 |
| tavern_b2 | tavern | (18.0, 22.0) | (17.9, 21.9) | tavern_a1 | (17.9, 21.9) | 0.0 |
| fen_post_a1 | post | (-76.0, 10.0) | (-75.9, 9.9) | fen_post_b2 | (-75.9, 9.9) | 0.0 |
| fen_post_a2 | post | (-76.0, -10.0) | (-75.9, -9.9) | fen_post_b1 | (-75.9, -9.9) | 0.0 |
| fen_post_b1 | post | (76.0, -10.0) | (75.9, -9.9) | fen_post_a2 | (75.9, -9.9) | 0.0 |
| fen_post_b2 | post | (76.0, 10.0) | (75.9, 9.9) | fen_post_a1 | (75.9, 9.9) | 0.0 |
| spine_post_a1 | post | (-30.0, 74.0) | (-29.9, 73.9) | spine_post_b2 | (-29.9, 73.9) | 0.0 |
| spine_post_a2 | post | (-30.0, -74.0) | (-29.9, -73.9) | spine_post_b1 | (-29.9, -73.9) | 0.0 |
| spine_post_b1 | post | (30.0, -74.0) | (29.9, -73.9) | spine_post_a2 | (29.9, -73.9) | 0.0 |
| spine_post_b2 | post | (30.0, 74.0) | (29.9, 73.9) | spine_post_a1 | (29.9, 73.9) | 0.0 |
| den_a1 | guild | (-76.0, 0.0) | (-75.9, 0.1) | den_b1 | (-75.9, 0.1) | 0.0 |
| den_b1 | guild | (76.0, 0.0) | (75.9, 0.1) | den_a1 | (75.9, 0.1) | 0.0 |
| lodge_a1 | guild | (-64.0, 0.0) | (-63.9, 0.1) | lodge_b1 | (-63.9, 0.1) | 0.0 |
| lodge_b1 | guild | (64.0, 0.0) | (63.9, 0.1) | lodge_a1 | (63.9, 0.1) | 0.0 |
| peddler_a1 | peddler | (-30.0, 44.0) | (-29.9, 43.9) | peddler_b2 | (-29.9, 43.9) | 0.0 |
| peddler_a2 | peddler | (-30.0, -44.0) | (-29.9, -43.9) | peddler_b1 | (-29.9, -43.9) | 0.0 |
| peddler_b1 | peddler | (30.0, -44.0) | (29.9, -43.9) | peddler_a2 | (29.9, -43.9) | 0.0 |
| peddler_b2 | peddler | (30.0, 44.0) | (29.9, 43.9) | peddler_a1 | (29.9, 43.9) | 0.0 |
| cache_a1 | cache | (-40.0, 58.0) | (-39.9, 57.9) | cache_b2 | (-39.9, 57.9) | 0.0 |
| cache_a2 | cache | (-40.0, -58.0) | (-39.9, -57.9) | cache_b1 | (-39.9, -57.9) | 0.0 |
| cache_b1 | cache | (40.0, -58.0) | (39.9, -57.9) | cache_a2 | (39.9, -57.9) | 0.0 |
| cache_b2 | cache | (40.0, 58.0) | (39.9, 57.9) | cache_a1 | (39.9, 57.9) | 0.0 |
| heath_lair_a1 | lair | (-44.0, 74.0) | (-43.9, 73.9) | heath_lair_b2 | (-43.9, 73.9) | 0.0 |
| heath_lair_a2 | lair | (-44.0, -74.0) | (-43.9, -73.9) | heath_lair_b1 | (-43.9, -73.9) | 0.0 |
| heath_lair_b1 | lair | (44.0, -74.0) | (43.9, -73.9) | heath_lair_a2 | (43.9, -73.9) | 0.0 |
| heath_lair_b2 | lair | (44.0, 74.0) | (43.9, 73.9) | heath_lair_a1 | (43.9, 73.9) | 0.0 |
| mouth_lair_a1 | lair | (-12.0, 76.0) | (-11.9, 75.9) | mouth_lair_b2 | (-11.9, 75.9) | 0.0 |
| mouth_lair_a2 | lair | (-12.0, -76.0) | (-11.9, -75.9) | mouth_lair_b1 | (-11.9, -75.9) | 0.0 |
| mouth_lair_b1 | lair | (12.0, -76.0) | (11.9, -75.9) | mouth_lair_a2 | (11.9, -75.9) | 0.0 |
| mouth_lair_b2 | lair | (12.0, 76.0) | (11.9, 75.9) | mouth_lair_a1 | (11.9, 75.9) | 0.0 |
| bridge_road_s | crossing_bridge_road | (0.0, 68.0) | (-0.1, 67.9) | bridge_road_s | (0.1, 67.9) | 0.3 |
| bridge_road_n | crossing_bridge_road | (0.0, -68.0) | (-0.1, -67.9) | bridge_road_n | (0.1, -67.9) | 0.3 |
| ford_s | crossing_ford | (0.0, 36.0) | (-0.1, 35.9) | ford_s | (0.1, 35.9) | 0.3 |
| ford_n | crossing_ford | (0.0, -36.0) | (-0.1, -35.9) | ford_n | (0.1, -35.9) | 0.3 |
| crown_sw | crossing_bridge_lane | (-9.0, 9.0) | (-8.9, 8.9) | crown_se | (-8.9, 8.9) | 0.0 |
| crown_nw | crossing_bridge_lane | (-9.0, -9.0) | (-8.9, -8.9) | crown_ne | (-8.9, -8.9) | 0.0 |
| crown_ne | crossing_bridge_lane | (9.0, -9.0) | (8.9, -8.9) | crown_nw | (8.9, -8.9) | 0.0 |
| crown_se | crossing_bridge_lane | (9.0, 9.0) | (8.9, 8.9) | crown_sw | (8.9, 8.9) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 262)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | shrine_a1 - wallow_b1 | 126.9 | shrine_b1 - wallow_a1 | 157.9 | -19.6 % |
| 2 | shrine_b1 - wallow_a1 | 157.9 | shrine_b1 - wallow_a2 | 126.9 | +19.6 % |
| 3 | node_a_a1 - node_b_a2 | 51.2 | node_a_b2 - node_b_b1 | 61.6 | -16.9 % |
| 4 | node_a_a2 - node_b_a1 | 51.2 | node_a_b2 - node_b_b1 | 61.6 | -16.9 % |
| 5 | node_a_a1 - node_b_a2 | 51.2 | node_a_b1 - node_b_b2 | 61.6 | -16.9 % |
| 6 | node_a_a2 - node_b_a1 | 51.2 | node_a_b1 - node_b_b2 | 61.6 | -16.9 % |
| 7 | shrine_a1 - wallow_b2 | 132.1 | shrine_b1 - wallow_a1 | 157.9 | -16.4 % |
| 8 | keep_t1 - fenwatch_a1 | 101.5 | keep_t4 - fenwatch_a2 | 117.1 | -13.3 % |
| 9 | keep_t3 - fenwatch_b2 | 101.6 | keep_t4 - fenwatch_a2 | 117.1 | -13.2 % |
| 10 | shrine_b1 - bridge_nest_a1 | 116.8 | shrine_b1 - bridge_nest_a2 | 101.8 | +12.8 % |
| 11 | keep_t0 - keep_t1 | 150.6 | keep_t4 - keep_t3 | 131.3 | +12.8 % |
| 12 | shrine_a1 - bridge_nest_b2 | 101.9 | shrine_b1 - bridge_nest_a1 | 116.8 | -12.7 % |
| 13 | shrine_a1 - bridge_nest_b1 | 102.0 | shrine_b1 - bridge_nest_a1 | 116.8 | -12.7 % |
| 14 | keep_t0 - fenwatch_b1 | 102.3 | keep_t4 - fenwatch_a2 | 117.1 | -12.6 % |
| 15 | den_a1 - cache_b2 | 129.4 | den_b1 - cache_a1 | 148.0 | -12.6 % |
| 16 | den_b1 - cache_a1 | 148.0 | den_b1 - cache_a2 | 129.4 | +12.6 % |
| 17 | den_a1 - cache_b1 | 129.4 | den_b1 - cache_a1 | 148.0 | -12.6 % |
| 18 | node_a_a2 - fordwatch_b2 | 103.1 | node_a_b2 - fordwatch_a2 | 90.5 | +12.2 % |
| 19 | node_a_a2 - fordwatch_b2 | 103.1 | node_a_b1 - fordwatch_a1 | 90.6 | +12.1 % |
| 20 | wallow_a1 - peddler_b2 | 78.9 | wallow_b2 - peddler_a1 | 89.5 | -11.8 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| player (A1 south-west) | 26.3 (natural_a1) | 25.8 (shrine_a1) | 26.5 (wallow_a1) | 54.1 (heath_lair_a1) | 43.3 (tavern_a1) | 20.7 (fen_post_a1) | 37.1 (peddler_a1) | 40.8 (cache_a1) | 65.8 (crown) | 126.3 |
| ally (A2 north-west) | 25.8 (natural_a2) | 25.5 (shrine_a1) | 26.2 (wallow_a2) | 53.8 (heath_lair_a2) | 42.8 (tavern_a2) | 20.7 (fen_post_a2) | 36.8 (peddler_a2) | 40.5 (cache_a2) | 65.2 (crown) | 125.0 |
| enemy (B1 north-east) | 25.8 (natural_b1) | 25.5 (shrine_b1) | 26.1 (wallow_b1) | 53.7 (heath_lair_b1) | 42.8 (tavern_b1) | 20.7 (fen_post_b1) | 36.8 (peddler_b1) | 40.4 (cache_b1) | 65.2 (crown) | 125.0 |
| enemy 2 (B2 south-east) | 26.3 (natural_b2) | 25.8 (shrine_b1) | 26.3 (wallow_b2) | 54.0 (heath_lair_b2) | 43.3 (tavern_b2) | 20.7 (fen_post_b2) | 37.1 (peddler_b2) | 40.7 (cache_b2) | 65.8 (crown) | 126.3 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| node_a_a1 | home_node | 6.7 | node_a_b2 | 6.7 | +0.0 % |
| node_b_a1 | home_node | 11.1 | node_b_b2 | 11.0 | +0.8 % |
| fen_post_a1 | post | 20.7 | fen_post_b2 | 20.7 | +0.0 % |
| lodge_a1 | guild | 24.4 | lodge_b1 | 24.4 | +0.0 % |
| shrine_a1 | point | 25.8 | shrine_b1 | 25.8 | +0.0 % |
| natural_a1 | expansion | 26.3 | natural_b2 | 26.3 | -0.0 % |
| wallow_a1 | camp | 26.5 | wallow_b2 | 26.3 | +0.5 % |
| den_a1 | guild | 28.4 | den_b1 | 28.4 | +0.0 % |
| hollow_a1 | camp | 32.2 | hollow_b1 | 32.2 | +0.0 % |
| peddler_a1 | peddler | 37.1 | peddler_b2 | 37.1 | +0.1 % |
| fen_post_a2 | post | 37.3 | fen_post_b1 | 37.3 | +0.0 % |
| well_a1 | point | 37.4 | well_b2 | 37.4 | +0.0 % |
| glade_vein_a1 | expansion | 38.1 | glade_vein_b2 | 37.8 | +0.6 % |
| cache_a1 | cache | 40.8 | cache_b2 | 40.7 | +0.3 % |
| tavern_a1 | tavern | 43.3 | tavern_b2 | 43.3 | +0.0 % |
| node_a_a2 | home_node | 43.4 | node_a_b1 | 43.4 | +0.0 % |
| stag_a1 | camp | 46.1 | stag_b2 | 45.9 | +0.5 % |
| keep_t3 | keep | 48.3 | keep_t1 | 48.3 | +0.0 % |
| well_a2 | point | 50.6 | well_b1 | 50.6 | -0.0 % |
| heath_lair_a1 | lair | 54.1 | heath_lair_b2 | 54.0 | +0.3 % |
| crown_sw | crossing_bridge_lane | 54.5 | crown_se | 54.5 | +0.0 % |
| fordwatch_a1 | point | 55.1 | fordwatch_b2 | 55.1 | +0.0 % |
| natural_a2 | expansion | 56.8 | natural_b1 | 56.7 | +0.1 % |
| rich_a1 | expansion | 58.3 | rich_b2 | 58.3 | +0.1 % |
| fenwatch_a1 | point | 59.2 | fenwatch_b2 | 59.2 | +0.0 % |
| spine_post_a1 | post | 59.7 | spine_post_b2 | 59.6 | +0.2 % |
| ford_nest_a1 | camp | 62.1 | ford_nest_a1 | 62.1 | +0.0 % |
| ford_s | crossing_ford | 62.1 | ford_s | 62.1 | +0.0 % |
| node_b_a2 | home_node | 63.0 | node_b_b1 | 62.8 | +0.4 % |
| tavern_a2 | tavern | 63.3 | tavern_b1 | 63.3 | -0.0 % |
| bridge_nest_a1 | camp | 65.7 | bridge_nest_b2 | 65.7 | +0.1 % |
| crown | crown | 65.8 | crown | 65.8 | -0.0 % |
| fordwatch_b2 | point | 68.7 | fordwatch_a1 | 68.7 | +0.0 % |
| crown_nw | crossing_bridge_lane | 69.6 | crown_ne | 69.6 | -0.0 % |
| mouth_lair_a1 | lair | 72.0 | mouth_lair_b2 | 71.9 | +0.1 % |
| crown_se | crossing_bridge_lane | 72.0 | crown_sw | 72.0 | +0.0 % |
| bridge_road_s | crossing_bridge_road | 75.3 | bridge_road_s | 75.3 | +0.1 % |
| peddler_a2 | peddler | 76.5 | peddler_b1 | 76.4 | +0.1 % |
| wallow_a2 | camp | 76.8 | wallow_b1 | 76.6 | +0.2 % |
| fenwatch_b2 | point | 78.1 | fenwatch_a1 | 77.9 | +0.2 % |
| crown_ne | crossing_bridge_lane | 78.3 | crown_nw | 78.4 | -0.0 % |
| fordwatch_a2 | point | 79.6 | fordwatch_b1 | 79.6 | -0.0 % |
| glade_vein_a2 | expansion | 85.4 | glade_vein_b1 | 85.5 | -0.1 % |
| bridge_nest_b2 | camp | 85.6 | bridge_nest_a1 | 85.4 | +0.2 % |
| ford_n | crossing_ford | 85.8 | ford_n | 85.8 | -0.0 % |
| ford_nest_a2 | camp | 85.8 | ford_nest_a2 | 85.8 | -0.0 % |
| tavern_b2 | tavern | 86.4 | tavern_a1 | 83.1 | +3.7 % |
| cache_a2 | cache | 88.6 | cache_b1 | 88.5 | +0.2 % |
| well_b2 | point | 89.2 | well_a1 | 89.2 | +0.0 % |
| mouth_lair_b2 | lair | 89.7 | mouth_lair_a1 | 89.7 | +0.0 % |
| rich_b2 | expansion | 90.9 | rich_a1 | 90.8 | +0.0 % |
| fordwatch_b1 | point | 91.4 | fordwatch_a2 | 101.0 | -9.5 % |
| fenwatch_a2 | point | 91.4 | fenwatch_b1 | 91.4 | +0.0 % |
| peddler_b2 | peddler | 93.1 | peddler_a1 | 93.1 | +0.0 % |
| stag_a2 | camp | 93.6 | stag_b1 | 93.7 | -0.1 % |
| tavern_b1 | tavern | 93.7 | tavern_a2 | 93.8 | -0.0 % |
| well_b1 | point | 94.6 | well_a2 | 94.6 | -0.0 % |
| rich_a2 | expansion | 95.4 | rich_b1 | 95.3 | +0.0 % |
| natural_b2 | expansion | 97.6 | natural_a1 | 97.6 | +0.0 % |
| bridge_nest_a2 | camp | 99.8 | bridge_nest_b1 | 99.8 | +0.0 % |
| fenwatch_b1 | point | 102.3 | fenwatch_a2 | 117.1 | -12.6 % |
| hollow_b1 | camp | 104.4 | hollow_a1 | 104.4 | +0.0 % |
| heath_lair_a2 | lair | 104.5 | heath_lair_b1 | 104.4 | +0.2 % |
| spine_post_b2 | post | 105.5 | spine_post_a1 | 105.5 | +0.0 % |
| spine_post_a2 | post | 105.7 | spine_post_b1 | 105.6 | +0.1 % |
| natural_b1 | expansion | 108.8 | natural_a2 | 108.8 | -0.0 % |
| bridge_nest_b1 | camp | 109.5 | bridge_nest_a2 | 109.3 | +0.1 % |
| bridge_road_n | crossing_bridge_road | 110.9 | bridge_road_n | 111.0 | -0.0 % |
| rich_b1 | expansion | 112.1 | rich_a2 | 125.6 | -10.7 % |
| mouth_lair_a2 | lair | 112.6 | mouth_lair_b1 | 112.6 | +0.1 % |
| node_b_b2 | home_node | 114.7 | node_b_a1 | 114.7 | -0.0 % |
| cache_b2 | cache | 115.2 | cache_a1 | 115.2 | +0.0 % |
| peddler_b1 | peddler | 118.4 | peddler_a2 | 118.4 | -0.0 % |
| heath_lair_b2 | lair | 119.2 | heath_lair_a1 | 119.2 | +0.0 % |
| mouth_lair_b1 | lair | 125.3 | mouth_lair_a2 | 125.4 | -0.0 % |
| keep_t4 | keep | 126.3 | keep_t0 | 126.3 | +0.0 % |
| wallow_b2 | camp | 126.6 | wallow_a1 | 126.5 | +0.0 % |
| node_b_b1 | home_node | 127.2 | node_b_a2 | 127.2 | -0.0 % |
| lodge_b1 | guild | 128.2 | lodge_a1 | 128.1 | +0.0 % |
| node_a_b2 | home_node | 128.8 | node_a_a1 | 128.8 | +0.0 % |
| stag_b2 | camp | 130.5 | stag_a1 | 130.5 | +0.0 % |
| wallow_b1 | camp | 132.0 | wallow_a2 | 132.0 | -0.0 % |
| glade_vein_b2 | expansion | 132.7 | glade_vein_a1 | 132.7 | +0.0 % |
| shrine_b1 | point | 133.7 | shrine_a1 | 133.7 | +0.0 % |
| cache_b1 | cache | 135.6 | cache_a2 | 135.6 | -0.0 % |
| fen_post_b2 | post | 139.0 | fen_post_a1 | 139.0 | +0.0 % |
| den_b1 | guild | 139.6 | den_a1 | 139.6 | +0.0 % |
| fen_post_b1 | post | 143.8 | fen_post_a2 | 143.8 | -0.0 % |
| spine_post_b1 | post | 145.1 | spine_post_a2 | 145.2 | -0.0 % |
| node_a_b1 | home_node | 146.0 | node_a_a2 | 134.0 | +8.2 % |
| glade_vein_b1 | expansion | 148.9 | glade_vein_a2 | 148.9 | -0.0 % |
| keep_t1 | keep | 150.6 | keep_t3 | 131.3 | +12.8 % |
| heath_lair_b1 | lair | 151.2 | heath_lair_a2 | 151.2 | -0.0 % |
| stag_b1 | camp | 153.4 | stag_a2 | 153.4 | -0.0 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| player (A1 south-west) | 0 | keep_t3 | 48.3 | no | 126.3 | 150.6 | 0.38 |
| ally (A2 north-west) | 0 | keep_t0 | 48.3 | no | 125.0 | 131.3 | 0.39 |
| enemy (B1 north-east) | 1 | keep_t4 | 48.3 | no | 125.0 | 150.6 | 0.39 |
| enemy 2 (B2 south-east) | 1 | keep_t1 | 48.3 | no | 126.3 | 131.3 | 0.38 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| player (A1 south-west) | ally keep (keep_t3) | 48.3 | 0.0 | 0:10 | 0:10 | 0:06 | 0:12 |
| player (A1 south-west) | enemy keep (nearest) (keep_t4) | 126.3 | 0.0 | 0:27 | 0:25 | 0:17 | 0:32 |
| player (A1 south-west) | enemy keep #2 (keep_t1) | 150.6 | 0.0 | 0:33 | 0:30 | 0:20 | 0:38 |
| player (A1 south-west) | nearest expansion (natural_a1) | 26.3 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| player (A1 south-west) | nearest point (shrine_a1) | 25.8 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| player (A1 south-west) | nearest camp (wallow_a1) | 26.5 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| player (A1 south-west) | crown (crown) | 65.8 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| ally (A2 north-west) | ally keep (keep_t0) | 48.3 | 0.0 | 0:10 | 0:10 | 0:06 | 0:12 |
| ally (A2 north-west) | enemy keep (nearest) (keep_t1) | 125.0 | 0.0 | 0:27 | 0:25 | 0:17 | 0:31 |
| ally (A2 north-west) | enemy keep #2 (keep_t4) | 131.3 | 0.0 | 0:29 | 0:26 | 0:18 | 0:33 |
| ally (A2 north-west) | nearest expansion (natural_a2) | 25.8 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| ally (A2 north-west) | nearest point (shrine_a1) | 25.5 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| ally (A2 north-west) | nearest camp (wallow_a2) | 26.2 | 0.0 | 0:06 | 0:05 | 0:03 | 0:07 |
| ally (A2 north-west) | crown (crown) | 65.2 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| enemy (B1 north-east) | ally keep (keep_t4) | 48.3 | 0.0 | 0:10 | 0:10 | 0:06 | 0:12 |
| enemy (B1 north-east) | enemy keep (nearest) (keep_t3) | 125.0 | 0.0 | 0:27 | 0:25 | 0:17 | 0:31 |
| enemy (B1 north-east) | enemy keep #2 (keep_t0) | 150.1 | 0.0 | 0:33 | 0:30 | 0:20 | 0:38 |
| enemy (B1 north-east) | nearest expansion (natural_b1) | 25.8 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| enemy (B1 north-east) | nearest point (shrine_b1) | 25.5 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| enemy (B1 north-east) | nearest camp (wallow_b1) | 26.1 | 0.0 | 0:06 | 0:05 | 0:03 | 0:07 |
| enemy (B1 north-east) | crown (crown) | 65.2 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |
| enemy 2 (B2 south-east) | ally keep (keep_t1) | 48.3 | 0.0 | 0:10 | 0:10 | 0:06 | 0:12 |
| enemy 2 (B2 south-east) | enemy keep (nearest) (keep_t0) | 126.3 | 0.0 | 0:27 | 0:25 | 0:17 | 0:32 |
| enemy 2 (B2 south-east) | enemy keep #2 (keep_t3) | 131.3 | 0.0 | 0:29 | 0:26 | 0:18 | 0:33 |
| enemy 2 (B2 south-east) | nearest expansion (natural_b2) | 26.3 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| enemy 2 (B2 south-east) | nearest point (shrine_b1) | 25.8 | 0.0 | 0:06 | 0:05 | 0:03 | 0:06 |
| enemy 2 (B2 south-east) | nearest camp (wallow_b2) | 26.3 | 0.0 | 0:06 | 0:05 | 0:04 | 0:07 |
| enemy 2 (B2 south-east) | crown (crown) | 65.8 | 0.0 | 0:14 | 0:13 | 0:09 | 0:16 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_s | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_s | 4.8 |
| bridge_road_n | bridge_road | 6.0 | 4.8 | 5.8 | bridge_road_n | 4.8 |
| ford_s | ford | 7.0 | 5.5 | 6.5 | ford_s | 5.5 |
| ford_n | ford | 7.0 | 5.5 | 6.5 | ford_n | 5.5 |
| crown_sw | bridge_lane | 8.0 | 7.1 | 8.1 | crown_se | 6.8 |
| crown_nw | bridge_lane | 8.0 | 7.1 | 8.1 | crown_ne | 7.1 |
| crown_ne | bridge_lane | 8.0 | 7.1 | 8.1 | crown_nw | 7.1 |
| crown_se | bridge_lane | 8.0 | 6.8 | 7.8 | crown_sw | 7.1 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 66.0 | 6.8 | (-9.5, 5.6) | - |
| keep_t0 -> keep_t1 | 150.6 | 13.9 | (-7.1, 9.6) | - |
| keep_t0 -> keep_t4 | 126.3 | 8.6 | (7.8, 9.8) | - |
| keep_t0 -> natural_a1 | 26.3 | 40.1 | (-57.1, 24.5) | - |
| keep_t3 -> crown | 65.5 | 6.4 | (-9.8, -5.7) | - |
| keep_t3 -> keep_t4 | 131.3 | 6.1 | (9.2, 5.4) | - |
| keep_t3 -> natural_a2 | 25.8 | 40.1 | (-56.6, -24.0) | - |
| keep_t1 -> crown | 65.3 | 6.5 | (9.8, -5.7) | - |
| keep_t1 -> keep_t3 | 125.0 | 13.3 | (7.5, -9.8) | - |
| keep_t1 -> natural_b1 | 25.8 | 40.1 | (56.6, -24.0) | - |
| keep_t4 -> crown | 65.8 | 6.3 | (9.5, 5.6) | - |
| keep_t4 -> natural_b2 | 26.3 | 40.1 | (57.1, 24.5) | - |


## Hottest metres (every spot-pair shortest path, 4465 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (5.5, 9.5) | 281 | 6 % |
| 2 | (-5.5, -9.5) | 278 | 6 % |
| 3 | (-5.5, 9.5) | 260 | 6 % |
| 4 | (5.5, -9.5) | 259 | 6 % |
| 5 | (1.5, -1.5) | 237 | 5 % |
| 6 | (3.5, 65.5) | 187 | 4 % |
| 7 | (-2.5, -65.5) | 182 | 4 % |
| 8 | (-0.5, -35.5) | 168 | 4 % |
| 9 | (0.5, 35.5) | 166 | 4 % |
| 10 | (-13.5, -7.5) | 150 | 3 % |


## Info findings (119)
| Check | Where | What |
|---|---|---|
| N3 | island 6 at (-61.9, -27.9) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 7 at (62.1, -27.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 21 at (-61.9, 28.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 22 at (62.1, 28.1) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 16 islands on top of colliders (582 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | den_a1-mouth_lair_b1 vs den_a1-mouth_lair_b2 | 122.1 m vs 116.0 m (5.0 %) |
| F2 | den_a1-mouth_lair_b1 vs den_b1-mouth_lair_a2 | 122.1 m vs 116.0 m (5.0 %) |
| F2 | den_a1-mouth_lair_b1 vs den_b1-mouth_lair_a1 | 122.1 m vs 116.1 m (5.0 %) |
| F2 | bridge_nest_a2-fen_post_b1 vs bridge_nest_b2-fen_post_a1 | 108.8 m vs 103.4 m (4.9 %) |
| F2 | node_a_b1-heath_lair_a2 vs node_a_b2-heath_lair_a1 | 131.5 m vs 125.1 m (4.8 %) |
| F2 | bridge_nest_a2-fen_post_b1 vs bridge_nest_b1-fen_post_a2 | 108.8 m vs 103.5 m (4.8 %) |
| F2 | node_a_a1-heath_lair_b2 vs node_a_b2-heath_lair_a1 | 131.3 m vs 125.1 m (4.7 %) |
| F2 | node_a_a2-bridge_nest_b2 vs node_a_b1-bridge_nest_a1 | 114.3 m vs 119.9 m (4.7 %) |
| F2 | node_a_a1-bridge_nest_b1 vs node_a_b1-bridge_nest_a1 | 114.3 m vs 119.9 m (4.7 %) |
| F2 | node_a_a2-heath_lair_b1 vs node_a_b2-heath_lair_a1 | 131.2 m vs 125.1 m (4.6 %) |
| F2 | ford_nest_a1-heath_lair_a2 vs ford_nest_a2-heath_lair_a1 | 125.3 m vs 119.6 m (4.5 %) |
| F2 | ford_nest_a1-heath_lair_a2 vs ford_nest_a1-heath_lair_b1 | 125.3 m vs 119.8 m (4.4 %) |
| F2 | ford_nest_a2-heath_lair_a1 vs ford_nest_a2-heath_lair_b2 | 119.6 m vs 125.1 m (4.4 %) |
| F2 | keep_t0-tavern_b2 vs keep_t3-tavern_b1 | 86.4 m vs 82.7 m (4.3 %) |
| F2 | ford_nest_a1-heath_lair_b1 vs ford_nest_a2-heath_lair_b2 | 119.8 m vs 125.1 m (4.3 %) |
| F2 | den_b1-heath_lair_a1 vs den_b1-heath_lair_a2 | 145.6 m vs 151.8 m (4.1 %) |
| F2 | den_a1-heath_lair_b2 vs den_b1-heath_lair_a1 | 151.8 m vs 145.6 m (4.1 %) |
| F2 | ford_nest_a1-spine_post_a2 vs ford_nest_a2-spine_post_a1 | 119.2 m vs 114.4 m (4.0 %) |
| F2 | den_a1-heath_lair_b1 vs den_b1-heath_lair_a1 | 151.6 m vs 145.6 m (4.0 %) |
| F2 | ford_nest_a1-spine_post_a2 vs ford_nest_a2-spine_post_b2 | 119.2 m vs 114.5 m (3.9 %) |
| F2 | ford_nest_a1-spine_post_a2 vs ford_nest_a1-spine_post_b1 | 119.2 m vs 114.6 m (3.9 %) |
| F2 | shrine_a1-wallow_b1 vs shrine_a1-wallow_b2 | 126.9 m vs 132.1 m (3.9 %) |
| F2 | stag_a1-ford_n vs stag_a2-ford_s | 122.3 m vs 127.2 m (3.9 %) |
| F2 | stag_a1-ford_nest_a2 vs stag_a2-ford_nest_a1 | 122.3 m vs 127.2 m (3.9 %) |
| F2 | shrine_a1-wallow_b2 vs shrine_b1-wallow_a2 | 132.1 m vs 126.9 m (3.9 %) |
| F2 | well_b1-bridge_nest_a1 vs well_b2-bridge_nest_a2 | 84.3 m vs 87.7 m (3.9 %) |
| F2 | well_a2-bridge_nest_b2 vs well_b1-bridge_nest_a1 | 87.7 m vs 84.3 m (3.9 %) |
| F2 | stag_a2-ford_s vs stag_b1-ford_s | 127.2 m vs 122.4 m (3.8 %) |
| F2 | stag_a2-ford_nest_a1 vs stag_b1-ford_nest_a1 | 127.2 m vs 122.4 m (3.8 %) |
| F2 | stag_a1-ford_nest_a2 vs stag_b2-ford_nest_a2 | 122.3 m vs 127.0 m (3.8 %) |
| F2 | stag_a1-ford_n vs stag_b2-ford_n | 122.3 m vs 127.0 m (3.8 %) |
| F2 | well_a1-bridge_nest_b1 vs well_b2-bridge_nest_a2 | 84.4 m vs 87.7 m (3.7 %) |
| F2 | well_a1-bridge_nest_b1 vs well_a2-bridge_nest_b2 | 84.4 m vs 87.7 m (3.7 %) |
| F2 | keep_t0-tavern_b2 vs keep_t4-tavern_a1 | 86.4 m vs 83.1 m (3.7 %) |
| F2 | node_a_b1-spine_post_b1 vs node_a_b2-spine_post_b2 | 68.1 m vs 65.5 m (3.7 %) |
| F2 | stag_b1-ford_nest_a1 vs stag_b2-ford_nest_a2 | 122.4 m vs 127.0 m (3.6 %) |
| F2 | stag_b1-ford_s vs stag_b2-ford_n | 122.4 m vs 127.0 m (3.6 %) |
| F2 | keep_t3-tavern_b1 vs keep_t1-tavern_a2 | 82.7 m vs 85.7 m (3.5 %) |
| F2 | node_a_a1-spine_post_a1 vs node_a_b2-spine_post_b2 | 67.9 m vs 65.5 m (3.5 %) |
| F2 | glade_vein_a1-peddler_b2 vs glade_vein_b2-peddler_a1 | 92.3 m vs 95.6 m (3.5 %) |
| F2 | node_a_a2-spine_post_a2 vs node_a_b2-spine_post_b2 | 67.9 m vs 65.5 m (3.4 %) |
| F2 | glade_vein_a1-peddler_b2 vs glade_vein_a2-peddler_b1 | 92.3 m vs 95.6 m (3.4 %) |
| F2 | glade_vein_b1-peddler_a2 vs glade_vein_b2-peddler_a1 | 92.4 m vs 95.6 m (3.4 %) |
| F2 | ford_nest_a1-mouth_lair_a2 vs ford_nest_a2-mouth_lair_a1 | 117.3 m vs 113.4 m (3.4 %) |
| F2 | glade_vein_a2-peddler_b1 vs glade_vein_b1-peddler_a2 | 95.6 m vs 92.4 m (3.3 %) |
| F2 | ford_nest_a1-bridge_road_n vs ford_nest_a2-bridge_road_s | 107.0 m vs 110.6 m (3.3 %) |
| F2 | tavern_a2-cache_a1 vs tavern_b1-cache_b2 | 87.2 m vs 90.1 m (3.3 %) |
| F2 | tavern_a1-cache_a2 vs tavern_a2-cache_a1 | 90.1 m vs 87.2 m (3.3 %) |
| F2 | tavern_a2-cache_a1 vs tavern_b2-cache_b1 | 87.2 m vs 90.1 m (3.3 %) |
| F2 | rich_a2-cache_a1 vs rich_b1-cache_b2 | 120.2 m vs 124.2 m (3.2 %) |
| F2 | ford_nest_a2-mouth_lair_a1 vs ford_nest_a2-mouth_lair_b2 | 113.4 m vs 117.2 m (3.2 %) |
| F2 | rich_a1-cache_a2 vs rich_a2-cache_a1 | 124.2 m vs 120.2 m (3.2 %) |
| F2 | rich_a2-cache_a1 vs rich_b2-cache_b1 | 120.2 m vs 124.2 m (3.2 %) |
| F2 | ford_nest_a1-mouth_lair_a2 vs ford_nest_a1-mouth_lair_b1 | 117.3 m vs 113.5 m (3.2 %) |
| F2 | rich_a1-well_a2 vs rich_b1-well_b2 | 78.8 m vs 81.4 m (3.2 %) |
| F2 | well_a2-tavern_a1 vs well_b2-tavern_b1 | 45.8 m vs 47.3 m (3.2 %) |
| F2 | rich_a2-well_a1 vs rich_b1-well_b2 | 78.8 m vs 81.4 m (3.2 %) |
| F2 | well_a1-tavern_a2 vs well_a2-tavern_a1 | 47.3 m vs 45.8 m (3.2 %) |
| F2 | ford_nest_a1-mouth_lair_b1 vs ford_nest_a2-mouth_lair_b2 | 113.5 m vs 117.2 m (3.1 %) |
| F2 | hollow_a1-fen_post_b1 vs hollow_b1-fen_post_a2 | 120.7 m vs 117.0 m (3.1 %) |
| F2 | hollow_a1-fen_post_b1 vs hollow_a1-fen_post_b2 | 120.7 m vs 117.0 m (3.1 %) |
| F2 | well_a2-tavern_a1 vs well_b1-tavern_b2 | 45.8 m vs 47.2 m (3.1 %) |
| F2 | hollow_a1-fen_post_b1 vs hollow_b1-fen_post_a1 | 120.7 m vs 117.1 m (3.0 %) |
| F2 | bridge_nest_a1-bridge_road_n vs bridge_nest_a2-bridge_road_s | 127.2 m vs 131.2 m (3.0 %) |
| F2 | keep_t1-tavern_a2 vs keep_t4-tavern_a1 | 85.7 m vs 83.1 m (2.9 %) |
| F2 | well_a2-mouth_lair_a1 vs well_b2-mouth_lair_b1 | 96.4 m vs 99.2 m (2.9 %) |
| F2 | bridge_nest_a2-bridge_road_s vs bridge_nest_b2-bridge_road_n | 131.2 m vs 127.4 m (2.9 %) |
| F2 | well_a1-mouth_lair_a2 vs well_a2-mouth_lair_a1 | 99.2 m vs 96.4 m (2.9 %) |
| F2 | rich_b1-well_b2 vs rich_b2-well_b1 | 81.4 m vs 79.0 m (2.9 %) |
| F2 | bridge_nest_a2-bridge_road_s vs bridge_nest_b1-bridge_road_s | 131.2 m vs 127.5 m (2.8 %) |
| F2 | well_a2-mouth_lair_a1 vs well_b1-mouth_lair_b2 | 96.4 m vs 99.1 m (2.8 %) |
| F2 | ford_nest_a1-fen_post_a2 vs ford_nest_a2-fen_post_a1 | 88.7 m vs 91.2 m (2.7 %) |
| F2 | ford_nest_a2-fen_post_a1 vs ford_nest_a2-fen_post_b2 | 91.2 m vs 88.7 m (2.7 %) |
| F2 | rich_a2-heath_lair_a1 vs rich_b1-heath_lair_b2 | 136.5 m vs 140.2 m (2.7 %) |
| F2 | rich_a2-heath_lair_a1 vs rich_b2-heath_lair_b1 | 136.5 m vs 140.2 m (2.7 %) |
| F2 | rich_a1-heath_lair_a2 vs rich_a2-heath_lair_a1 | 140.2 m vs 136.5 m (2.7 %) |
| F2 | ford_nest_a1-fen_post_a2 vs ford_nest_a1-fen_post_b1 | 88.7 m vs 91.1 m (2.6 %) |
| F2 | ford_nest_a1-fen_post_b1 vs ford_nest_a2-fen_post_b2 | 91.1 m vs 88.7 m (2.6 %) |
| F2 | node_a_a2-fenwatch_a1 vs node_a_b1-fenwatch_b2 | 92.6 m vs 90.2 m (2.6 %) |
| F2 | node_a_a2-fenwatch_a1 vs node_a_b2-fenwatch_b1 | 92.6 m vs 90.3 m (2.5 %) |
| F2 | node_a_a1-fenwatch_a2 vs node_a_b1-fenwatch_b2 | 92.6 m vs 90.2 m (2.5 %) |
| F2 | heath_lair_a1-mouth_lair_a2 vs heath_lair_a2-mouth_lair_a1 | 158.1 m vs 154.1 m (2.5 %) |
| F2 | heath_lair_a2-mouth_lair_a1 vs heath_lair_b1-mouth_lair_b2 | 154.1 m vs 158.0 m (2.5 %) |
| F2 | tavern_a1-heath_lair_a2 vs tavern_a2-heath_lair_a1 | 106.1 m vs 103.5 m (2.5 %) |
| F2 | tavern_a2-heath_lair_a1 vs tavern_b2-heath_lair_b1 | 103.5 m vs 106.1 m (2.5 %) |
| F2 | tavern_a2-heath_lair_a1 vs tavern_b1-heath_lair_b2 | 103.5 m vs 106.1 m (2.5 %) |
| F2 | fenwatch_a1-fen_post_b1 vs fenwatch_b1-fen_post_a1 | 105.0 m vs 107.7 m (2.5 %) |
| F2 | node_a_a1-fenwatch_a2 vs node_a_b2-fenwatch_b1 | 92.6 m vs 90.3 m (2.5 %) |
| F2 | heath_lair_a1-mouth_lair_a2 vs heath_lair_b2-mouth_lair_b1 | 158.1 m vs 154.1 m (2.5 %) |
| F2 | heath_lair_b1-mouth_lair_b2 vs heath_lair_b2-mouth_lair_b1 | 158.0 m vs 154.1 m (2.5 %) |
| F2 | shrine_a1-fen_post_b1 vs shrine_b1-fen_post_a2 | 150.0 m vs 146.3 m (2.5 %) |
| F2 | shrine_a1-fen_post_b1 vs shrine_a1-fen_post_b2 | 150.0 m vs 146.3 m (2.5 %) |
| F2 | shrine_a1-fen_post_b1 vs shrine_b1-fen_post_a1 | 150.0 m vs 146.3 m (2.5 %) |
| F2 | fenwatch_a2-fen_post_b2 vs fenwatch_b1-fen_post_a1 | 105.1 m vs 107.7 m (2.5 %) |
| F2 | bridge_nest_a1-fen_post_b1 vs bridge_nest_b1-fen_post_a1 | 112.1 m vs 114.9 m (2.4 %) |
| F2 | fenwatch_b1-fen_post_a1 vs fenwatch_b2-fen_post_a2 | 107.7 m vs 105.1 m (2.4 %) |
| F2 | natural_a1-fen_post_b1 vs natural_b1-fen_post_a1 | 120.6 m vs 117.7 m (2.4 %) |
| F2 | natural_b1-fen_post_a1 vs natural_b2-fen_post_a2 | 117.7 m vs 120.6 m (2.4 %) |
| F2 | natural_a2-fen_post_b2 vs natural_b1-fen_post_a1 | 120.6 m vs 117.7 m (2.4 %) |
| F2 | wallow_a2-fen_post_b2 vs wallow_b1-fen_post_a1 | 143.8 m vs 140.4 m (2.4 %) |
| F2 | wallow_a1-fen_post_b1 vs wallow_b1-fen_post_a1 | 143.8 m vs 140.4 m (2.4 %) |
| F2 | wallow_b1-fen_post_a1 vs wallow_b2-fen_post_a2 | 140.4 m vs 143.8 m (2.4 %) |
| F2 | bridge_nest_a2-fen_post_b2 vs bridge_nest_b1-fen_post_a1 | 112.1 m vs 114.9 m (2.4 %) |
| F2 | fordwatch_a1-fen_post_b1 vs fordwatch_a2-fen_post_b2 | 96.8 m vs 94.6 m (2.3 %) |
| F2 | fordwatch_a2-fen_post_b2 vs fordwatch_b1-fen_post_a1 | 94.6 m vs 96.8 m (2.3 %) |
| F2 | fordwatch_a1-fen_post_b1 vs fordwatch_b2-fen_post_a2 | 96.8 m vs 94.6 m (2.3 %) |
| F2 | bridge_nest_b1-fen_post_a1 vs bridge_nest_b2-fen_post_a2 | 114.9 m vs 112.3 m (2.3 %) |
| F2 | fordwatch_b1-fen_post_a1 vs fordwatch_b2-fen_post_a2 | 96.8 m vs 94.6 m (2.3 %) |
| F2 | rich_a1-fen_post_b1 vs rich_b1-fen_post_a1 | 114.9 m vs 117.5 m (2.3 %) |
| F2 | rich_a2-fen_post_b2 vs rich_b1-fen_post_a1 | 114.9 m vs 117.5 m (2.2 %) |
| F2 | rich_b1-fen_post_a1 vs rich_b2-fen_post_a2 | 117.5 m vs 115.0 m (2.2 %) |
| F2 | glade_vein_a2-fen_post_b2 vs glade_vein_b1-fen_post_a1 | 160.7 m vs 157.2 m (2.1 %) |
| F2 | glade_vein_b1-fen_post_a1 vs glade_vein_b2-fen_post_a2 | 157.2 m vs 160.7 m (2.1 %) |
| F2 | glade_vein_a1-fen_post_b1 vs glade_vein_b1-fen_post_a1 | 160.7 m vs 157.2 m (2.1 %) |

## Notes
- Octile grid shortest paths (0.5 m, 95 sources) 97.63 s.
- Navmesh raster 1.92 s (253 polygons, 409600 cells of 0.25 m), spot / mirror checks 2.04 s, 4465 paths 0.95 s.
- Map Gloamspine Divide (2v2), scene res://docs/tools/world_forge/out/gloamspine_divide/preview.tscn, sim mode off; level load + navmesh bake 0.4 s (25 frames), lab 104.3 s. Spec: docs/design/new-maps.md.
