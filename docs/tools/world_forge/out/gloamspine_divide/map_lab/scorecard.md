# Map Lab: Gloamspine Divide (2v2) scorecard: world_forge_gloamspine_divide

2026-09-27 13:35 · lab v1.0 · 126.66 s · scanned 87 spots

## Result: **WARN** · score **93 / 100**

0 FAIL · 3 WARN · 9 PASS · 1 info checks; findings: 0 FAIL, 178 WARN, 154 info

## Improve next
1. **No navmesh islands** (WARN): island 14 at (-51.9, 0.1): 40.6 m² of ground-level navmesh cut off from the main area (y 0.50) -> a pocket closed by colliders: widen its gap or fill it (trees / rocks) (close or open the pocket) _(from N3 4 / 8 clean (0 FAIL, 4 WARN), 5 info)_
2. **Unit paths (NavigationServer): pairs match their twins** (WARN): node_b_a2-lodge_a1 vs node_b_b2-lodge_b1: 65.7 m vs 89.0 m (26.2 %) -> units walk node_b_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 5286 / 5608 pairs within 2 % (0 FAIL, 173 WARN, 149 info))_
3. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest enemy keep: 122.2 m vs 138.7 m between seats (11.9 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 9 / 10 clean (0 FAIL, 1 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 260 polygons, main area 24057 m² (94 % of the 160 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 87 / 87 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | **WARN** 52 | 4 / 8 clean (0 FAIL, 4 WARN), 5 info | ground-level components other than the main one < 2 m² | close or open the pocket |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 87 / 87 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 87 / 87 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (8 cells), 0.00 % (0 cells), 0.00 % (8 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 5608 / 5608 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 5286 / 5608 pairs within 2 % (0 FAIL, 173 WARN, 149 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 66 | 9 / 10 clean (0 FAIL, 1 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 8 / 8 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 12 / 12 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |

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
| WARN | F2 | node_b_a2-lodge_a1 vs node_b_b2-lodge_b1 | 65.7 m vs 89.0 m (26.2 %) | units walk node_b_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-lodge_b1 vs node_b_b2-lodge_b1 | 65.7 m vs 89.0 m (26.2 %) | units walk node_b_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-lodge_a1 vs node_b_b2-lodge_b1 | 65.7 m vs 89.0 m (26.2 %) | units walk node_b_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-mouth_lair_b2 vs glade_vein_b2-mouth_lair_b1 | 105.3 m vs 135.8 m (22.5 %) | units walk glade_vein_b2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-mouth_lair_a1 vs glade_vein_b1-mouth_lair_b2 | 135.7 m vs 105.3 m (22.4 %) | units walk glade_vein_a2-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-mouth_lair_a2 vs glade_vein_b1-mouth_lair_b2 | 135.5 m vs 105.3 m (22.3 %) | units walk glade_vein_a1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fen_post_a2-mouth_lair_b2 vs fen_post_b1-mouth_lair_a1 | 138.4 m vs 174.9 m (20.9 %) | units walk fen_post_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fen_post_a2-mouth_lair_b2 vs fen_post_b2-mouth_lair_a2 | 138.4 m vs 174.8 m (20.8 %) | units walk fen_post_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fen_post_a1-mouth_lair_b1 vs fen_post_a2-mouth_lair_b2 | 174.6 m vs 138.4 m (20.7 %) | units walk fen_post_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a1-lodge_b1 vs fenwatch_a2-lodge_b1 | 89.4 m vs 111.5 m (19.8 %) | units walk fenwatch_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a2-lodge_b1 vs fenwatch_b2-lodge_a1 | 111.5 m vs 89.5 m (19.7 %) | units walk fenwatch_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a2-lodge_b1 vs fenwatch_b1-lodge_a1 | 111.5 m vs 89.6 m (19.6 %) | units walk fenwatch_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-hollow_b1 vs keep_t1-hollow_a1 | 139.7 m vs 117.6 m (15.8 %) | units walk keep_t0-hollow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | hollow_b1-mouth_lair_a1 vs hollow_b1-mouth_lair_a2 | 114.0 m vs 95.9 m (15.8 %) | units walk hollow_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-hollow_a1 vs keep_t4-hollow_a1 | 117.6 m vs 139.6 m (15.8 %) | units walk keep_t4-hollow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | hollow_a1-mouth_lair_b2 vs hollow_b1-mouth_lair_a1 | 96.0 m vs 114.0 m (15.8 %) | units walk hollow_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | hollow_a1-mouth_lair_b1 vs hollow_b1-mouth_lair_a1 | 96.1 m vs 114.0 m (15.7 %) | units walk hollow_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-hollow_b1 vs keep_t1-hollow_a1 | 139.1 m vs 117.6 m (15.5 %) | units walk keep_t3-hollow_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_b1-den_b1 vs spine_post_b2-den_b1 | 102.8 m vs 86.9 m (15.5 %) | units walk spine_post_b1-den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-den_a1 vs spine_post_b2-den_b1 | 102.8 m vs 86.9 m (15.4 %) | units walk spine_post_a1-den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-mouth_lair_b1 vs stag_b2-mouth_lair_a2 | 135.0 m vs 114.3 m (15.3 %) | units walk stag_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a2-den_a1 vs spine_post_b2-den_b1 | 102.6 m vs 86.9 m (15.3 %) | units walk spine_post_a2-den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-mouth_lair_b1 vs stag_a2-mouth_lair_b2 | 135.0 m vs 114.4 m (15.3 %) | units walk stag_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-glade_vein_a2 vs node_a_b1-glade_vein_b2 | 68.4 m vs 80.4 m (14.8 %) | units walk node_a_b1-glade_vein_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-glade_vein_a1 vs node_a_b1-glade_vein_b2 | 68.4 m vs 80.4 m (14.8 %) | units walk node_a_b1-glade_vein_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-glade_vein_a2 vs node_a_b2-glade_vein_b1 | 68.4 m vs 80.3 m (14.8 %) | units walk node_a_b2-glade_vein_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-glade_vein_a1 vs node_a_b2-glade_vein_b1 | 68.4 m vs 80.3 m (14.8 %) | units walk node_a_b2-glade_vein_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-fen_post_b1 vs wallow_b2-fen_post_b2 | 63.0 m vs 54.0 m (14.3 %) | units walk wallow_b1-fen_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-mouth_lair_b1 vs node_a_b2-mouth_lair_b2 | 67.4 m vs 57.8 m (14.2 %) | units walk node_a_b1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-fen_post_a1 vs wallow_b2-fen_post_b2 | 63.0 m vs 54.0 m (14.2 %) | units walk wallow_a1-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a1 vs node_a_b2-mouth_lair_b2 | 67.2 m vs 57.8 m (14.1 %) | units walk node_a_a1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-fen_post_a2 vs wallow_b2-fen_post_b2 | 62.9 m vs 54.0 m (14.0 %) | units walk wallow_a2-fen_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_a2 vs node_a_b2-mouth_lair_b2 | 67.1 m vs 57.8 m (13.9 %) | units walk node_a_a2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-mouth_lair_a1 vs stag_b2-mouth_lair_a2 | 132.4 m vs 114.3 m (13.6 %) | units walk stag_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-wallow_b2 vs well_a2-wallow_b1 | 103.0 m vs 89.0 m (13.6 %) | units walk well_a1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-wallow_b1 vs well_b2-wallow_a1 | 89.0 m vs 103.0 m (13.6 %) | units walk well_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_b1-heath_lair_b2 vs spine_post_b2-heath_lair_b1 | 144.6 m vs 125.0 m (13.6 %) | units walk spine_post_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-mouth_lair_b2 vs stag_b1-mouth_lair_a1 | 114.4 m vs 132.4 m (13.6 %) | units walk stag_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-wallow_b1 vs well_b1-wallow_a2 | 89.0 m vs 102.9 m (13.5 %) | units walk well_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-lodge_a1 vs rich_b2-lodge_b1 | 76.4 m vs 88.3 m (13.5 %) | units walk rich_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_b1-lodge_b1 vs rich_b2-lodge_b1 | 76.4 m vs 88.3 m (13.5 %) | units walk rich_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-lodge_a1 vs rich_b2-lodge_b1 | 76.4 m vs 88.3 m (13.5 %) | units walk rich_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a2-heath_lair_a1 vs spine_post_b2-heath_lair_b1 | 144.4 m vs 125.0 m (13.5 %) | units walk spine_post_a2-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-den_b1 vs wallow_b2-den_b1 | 92.6 m vs 80.3 m (13.3 %) | units walk wallow_b1-den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-den_a1 vs wallow_b2-den_b1 | 92.6 m vs 80.3 m (13.3 %) | units walk wallow_a1-den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-den_a1 vs wallow_b2-den_b1 | 92.5 m vs 80.3 m (13.2 %) | units walk wallow_a2-den_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-mouth_lair_b2 vs glade_vein_b1-mouth_lair_a1 | 121.3 m vs 139.7 m (13.2 %) | units walk glade_vein_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-mouth_lair_b2 vs glade_vein_b2-mouth_lair_a2 | 121.3 m vs 139.7 m (13.2 %) | units walk glade_vein_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-mouth_lair_b1 vs glade_vein_a2-mouth_lair_b2 | 139.7 m vs 121.3 m (13.2 %) | units walk glade_vein_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-wallow_b1 vs stag_b2-wallow_a1 | 115.7 m vs 132.9 m (12.9 %) | units walk stag_b2-wallow_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-wallow_b2 vs stag_a2-wallow_b1 | 132.9 m vs 115.7 m (12.9 %) | units walk stag_a1-wallow_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-wallow_b1 vs stag_b1-wallow_a2 | 115.7 m vs 132.8 m (12.9 %) | units walk stag_b1-wallow_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-fen_post_b2 vs wallow_b2-fen_post_b1 | 122.2 m vs 107.3 m (12.2 %) | units walk wallow_b1-fen_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-fen_post_a2 vs wallow_b2-fen_post_b1 | 122.1 m vs 107.3 m (12.1 %) | units walk wallow_a1-fen_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-fen_post_a1 vs wallow_b2-fen_post_b1 | 122.0 m vs 107.3 m (12.1 %) | units walk wallow_a2-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a2-mouth_lair_b2 vs heath_lair_b1-mouth_lair_a1 | 164.8 m vs 187.1 m (11.9 %) | units walk heath_lair_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_b1-mouth_lair_a1 vs heath_lair_b2-mouth_lair_a2 | 187.1 m vs 164.8 m (11.9 %) | units walk heath_lair_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-keep_t4 vs keep_t3-keep_t1 | 138.7 m vs 122.2 m (11.9 %) | units walk keep_t0-keep_t4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-mouth_lair_b1 vs heath_lair_a2-mouth_lair_b2 | 186.9 m vs 164.8 m (11.8 %) | units walk heath_lair_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-mouth_lair_b1 vs heath_lair_b2-mouth_lair_a2 | 186.9 m vs 164.8 m (11.8 %) | units walk heath_lair_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-lodge_b1 vs node_a_b1-lodge_a1 | 158.5 m vs 139.8 m (11.8 %) | units walk node_a_a1-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-lodge_b1 vs node_a_b2-lodge_a1 | 158.5 m vs 139.9 m (11.8 %) | units walk node_a_a1-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-lodge_b1 vs node_a_b1-lodge_a1 | 158.4 m vs 139.8 m (11.7 %) | units walk node_a_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-lodge_b1 vs node_a_b2-lodge_a1 | 158.4 m vs 139.9 m (11.7 %) | units walk node_a_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_b1-bridge_road_n vs heath_lair_b2-bridge_road_s | 91.7 m vs 81.0 m (11.6 %) | units walk heath_lair_b1-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-bridge_road_s vs heath_lair_b2-bridge_road_s | 91.6 m vs 81.0 m (11.5 %) | units walk heath_lair_a1-bridge_road_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a2-bridge_road_n vs heath_lair_b2-bridge_road_s | 91.5 m vs 81.0 m (11.4 %) | units walk heath_lair_a2-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a2-lodge_a1 vs fenwatch_b2-lodge_b1 | 74.9 m vs 84.4 m (11.3 %) | units walk fenwatch_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_b1-lodge_b1 vs fenwatch_b2-lodge_b1 | 74.9 m vs 84.4 m (11.3 %) | units walk fenwatch_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a1-lodge_a1 vs fenwatch_b2-lodge_b1 | 74.9 m vs 84.4 m (11.3 %) | units walk fenwatch_b2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-heath_lair_b2 vs wallow_b2-heath_lair_b1 | 134.4 m vs 119.6 m (11.0 %) | units walk wallow_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-heath_lair_a2 vs wallow_b2-heath_lair_b1 | 134.3 m vs 119.6 m (11.0 %) | units walk wallow_a1-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-heath_lair_a1 vs wallow_b2-heath_lair_b1 | 134.2 m vs 119.6 m (10.9 %) | units walk wallow_a2-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-heath_lair_b2 vs well_b2-heath_lair_b1 | 83.2 m vs 74.2 m (10.8 %) | units walk well_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-heath_lair_a2 vs well_b2-heath_lair_b1 | 83.2 m vs 74.2 m (10.8 %) | units walk well_a1-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a2-cache_a1 vs tavern_b1-cache_b2 | 69.8 m vs 78.3 m (10.8 %) | units walk tavern_b1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a2-cache_a1 vs tavern_b2-cache_b1 | 69.8 m vs 78.2 m (10.7 %) | units walk tavern_b2-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-cache_a2 vs tavern_a2-cache_a1 | 78.2 m vs 69.8 m (10.7 %) | units walk tavern_a1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-heath_lair_a1 vs well_b2-heath_lair_b1 | 83.1 m vs 74.2 m (10.7 %) | units walk well_a2-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-heath_lair_a2 vs spine_post_b1-heath_lair_b2 | 129.2 m vs 144.6 m (10.7 %) | units walk spine_post_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-heath_lair_a2 vs spine_post_a2-heath_lair_a1 | 129.2 m vs 144.4 m (10.5 %) | units walk spine_post_a2-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-fen_post_b2 vs well_b2-fen_post_b1 | 70.9 m vs 63.6 m (10.3 %) | units walk well_b1-fen_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-fen_post_a2 vs well_b2-fen_post_b1 | 70.9 m vs 63.6 m (10.3 %) | units walk well_a1-fen_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-spine_post_a1 vs glade_vein_b2-spine_post_a2 | 127.2 m vs 141.6 m (10.2 %) | units walk glade_vein_b2-spine_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-spine_post_b1 vs glade_vein_b1-spine_post_a1 | 141.6 m vs 127.2 m (10.2 %) | units walk glade_vein_a1-spine_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-fen_post_a1 vs well_b2-fen_post_b1 | 70.8 m vs 63.6 m (10.1 %) | units walk well_a2-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-spine_post_b2 vs glade_vein_b1-spine_post_a1 | 141.1 m vs 127.2 m (9.9 %) | units walk glade_vein_a2-spine_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-shrine_a1 vs keep_t4-shrine_a1 | 142.8 m vs 158.1 m (9.7 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-shrine_b1 vs keep_t4-shrine_a1 | 142.8 m vs 158.1 m (9.7 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_b1-mouth_lair_a2 vs heath_lair_b2-mouth_lair_a1 | 105.3 m vs 95.2 m (9.6 %) | units walk heath_lair_b1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_b1-heath_lair_b1 vs wallow_b2-heath_lair_b2 | 52.7 m vs 47.6 m (9.5 %) | units walk wallow_b1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-heath_lair_a1 vs spine_post_b1-heath_lair_b1 | 56.9 m vs 62.9 m (9.5 %) | units walk spine_post_b1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a2-heath_lair_a2 vs spine_post_b1-heath_lair_b1 | 56.9 m vs 62.9 m (9.5 %) | units walk spine_post_b1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_b1-heath_lair_b1 vs spine_post_b2-heath_lair_b2 | 62.9 m vs 56.9 m (9.5 %) | units walk spine_post_b1-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a1-mouth_lair_b2 vs heath_lair_b2-mouth_lair_a1 | 105.2 m vs 95.2 m (9.5 %) | units walk heath_lair_a1-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heath_lair_a2-mouth_lair_b1 vs heath_lair_b2-mouth_lair_a1 | 105.1 m vs 95.2 m (9.5 %) | units walk heath_lair_a2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-heath_lair_a1 vs wallow_b2-heath_lair_b2 | 52.6 m vs 47.6 m (9.4 %) | units walk wallow_a1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a2-heath_lair_a2 vs wallow_b2-heath_lair_b2 | 52.5 m vs 47.6 m (9.3 %) | units walk wallow_a2-heath_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-shrine_b1 vs keep_t4-shrine_a1 | 143.5 m vs 158.1 m (9.2 %) | units walk keep_t4-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-bridge_road_n vs rich_b1-bridge_road_s | 127.5 m vs 140.1 m (9.0 %) | units walk rich_b1-bridge_road_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-bridge_road_n vs rich_b2-bridge_road_n | 127.5 m vs 140.0 m (8.9 %) | units walk rich_b2-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-heath_lair_b1 vs node_b_b1-heath_lair_a1 | 170.7 m vs 186.5 m (8.5 %) | units walk node_b_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-heath_lair_a1 vs node_b_b2-heath_lair_a2 | 186.5 m vs 170.7 m (8.5 %) | units walk node_b_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-cache_a1 vs rich_b1-cache_b2 | 102.8 m vs 112.4 m (8.5 %) | units walk rich_b1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-heath_lair_b2 vs node_b_b1-heath_lair_a1 | 170.7 m vs 186.5 m (8.5 %) | units walk node_b_b1-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-den_b1 vs keep_t1-den_a1 | 162.0 m vs 148.2 m (8.5 %) | units walk keep_t3-den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-cache_a2 vs rich_a2-cache_a1 | 112.3 m vs 102.8 m (8.5 %) | units walk rich_a1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-cache_a1 vs rich_b2-cache_b1 | 102.8 m vs 112.3 m (8.5 %) | units walk rich_b2-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-mouth_lair_b2 vs stag_a2-mouth_lair_b1 | 104.4 m vs 95.6 m (8.4 %) | units walk stag_a1-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-mouth_lair_b2 vs stag_b2-mouth_lair_a1 | 104.4 m vs 95.6 m (8.4 %) | units walk stag_a1-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-mouth_lair_b1 vs stag_b1-mouth_lair_a2 | 95.6 m vs 104.3 m (8.4 %) | units walk stag_b1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-mouth_lair_a2 vs stag_b2-mouth_lair_a1 | 104.3 m vs 95.6 m (8.3 %) | units walk stag_b1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-lodge_b1 vs spine_post_b1-lodge_a1 | 134.2 m vs 123.2 m (8.3 %) | units walk spine_post_a1-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-lodge_b1 vs spine_post_a2-lodge_b1 | 134.2 m vs 123.2 m (8.2 %) | units walk spine_post_a1-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | spine_post_a1-lodge_b1 vs spine_post_b2-lodge_a1 | 134.2 m vs 123.2 m (8.2 %) | units walk spine_post_a1-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-den_b1 vs keep_t4-den_a1 | 162.0 m vs 148.9 m (8.1 %) | units walk keep_t3-den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-den_b1 vs keep_t3-den_b1 | 148.9 m vs 162.0 m (8.1 %) | units walk keep_t3-den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-tavern_b2 vs natural_a2-tavern_b1 | 62.0 m vs 57.2 m (7.8 %) | units walk natural_a1-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mouth_lair_a1-bridge_road_n vs mouth_lair_b2-bridge_road_n | 145.3 m vs 157.6 m (7.8 %) | units walk mouth_lair_b2-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-heath_lair_a2 vs tavern_b1-heath_lair_b2 | 86.9 m vs 94.1 m (7.7 %) | units walk tavern_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_b1-heath_lair_b2 vs tavern_b2-heath_lair_b1 | 94.1 m vs 86.9 m (7.7 %) | units walk tavern_b1-heath_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-tavern_b2 vs natural_b2-tavern_a1 | 62.0 m vs 57.2 m (7.7 %) | units walk natural_a1-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mouth_lair_b1-bridge_road_s vs mouth_lair_b2-bridge_road_n | 145.5 m vs 157.6 m (7.7 %) | units walk mouth_lair_b2-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-tavern_b1 vs natural_b1-tavern_a2 | 57.2 m vs 61.9 m (7.6 %) | units walk natural_b1-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-heath_lair_a2 vs tavern_a2-heath_lair_a1 | 86.9 m vs 94.0 m (7.6 %) | units walk tavern_a2-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a2-heath_lair_a1 vs tavern_b2-heath_lair_b1 | 94.0 m vs 86.9 m (7.6 %) | units walk tavern_a2-heath_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a1-heath_lair_b2 vs fenwatch_a2-heath_lair_b1 | 92.2 m vs 99.7 m (7.6 %) | units walk fenwatch_a2-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_b1-tavern_a2 vs natural_b2-tavern_a1 | 61.9 m vs 57.2 m (7.5 %) | units walk natural_b1-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a2-heath_lair_b1 vs fenwatch_b2-heath_lair_a1 | 99.7 m vs 92.3 m (7.4 %) | units walk fenwatch_a2-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-fen_post_a1 vs node_b_b2-fen_post_a2 | 175.8 m vs 163.0 m (7.3 %) | units walk node_b_b1-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-fen_post_b1 vs node_b_b1-fen_post_a1 | 163.0 m vs 175.8 m (7.3 %) | units walk node_b_b1-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-fen_post_b2 vs node_b_b1-fen_post_a1 | 163.0 m vs 175.8 m (7.3 %) | units walk node_b_b1-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fenwatch_a2-heath_lair_b1 vs fenwatch_b1-heath_lair_a2 | 99.7 m vs 92.5 m (7.3 %) | units walk fenwatch_a2-heath_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a2-cache_b1 vs glade_vein_b1-cache_a2 | 106.9 m vs 114.8 m (6.9 %) | units walk glade_vein_b1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_a1-cache_b2 vs glade_vein_b1-cache_a2 | 106.9 m vs 114.8 m (6.9 %) | units walk glade_vein_b1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | glade_vein_b1-cache_a2 vs glade_vein_b2-cache_a1 | 114.8 m vs 106.9 m (6.9 %) | units walk glade_vein_b1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_b1-fen_post_b2 vs tavern_b2-fen_post_b1 | 81.9 m vs 76.3 m (6.9 %) | units walk tavern_b1-fen_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-fen_post_a2 vs tavern_b1-fen_post_b2 | 76.3 m vs 81.9 m (6.9 %) | units walk tavern_b1-fen_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a2-fen_post_a1 vs tavern_b2-fen_post_b1 | 81.7 m vs 76.3 m (6.7 %) | units walk tavern_a2-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-fen_post_a2 vs tavern_a2-fen_post_a1 | 76.3 m vs 81.7 m (6.7 %) | units walk tavern_a2-fen_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-ford_n vs peddler_a2-ford_s | 86.6 m vs 92.5 m (6.4 %) | units walk peddler_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a2-peddler_a1 | 92.5 m vs 86.6 m (6.4 %) | units walk ford_nest_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-glade_vein_b2 vs node_b_b2-glade_vein_a1 | 123.4 m vs 131.7 m (6.3 %) | units walk node_b_b2-glade_vein_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-glade_vein_b2 vs node_b_a2-glade_vein_b1 | 123.4 m vs 131.6 m (6.3 %) | units walk node_b_a2-glade_vein_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-ford_s vs peddler_b2-ford_n | 92.5 m vs 86.7 m (6.3 %) | units walk peddler_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a2-ford_s vs peddler_b1-ford_s | 92.5 m vs 86.7 m (6.2 %) | units walk peddler_a2-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_a2 vs ford_nest_a1-peddler_b1 | 92.5 m vs 86.7 m (6.2 %) | units walk ford_nest_a1-peddler_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-glade_vein_b2 vs node_b_b1-glade_vein_a2 | 123.4 m vs 131.6 m (6.2 %) | units walk node_b_b1-glade_vein_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a2-peddler_a1 vs ford_nest_a2-peddler_b2 | 86.6 m vs 92.3 m (6.2 %) | units walk ford_nest_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-crown_sw vs keep_t1-crown_se | 93.3 m vs 87.7 m (6.1 %) | units walk keep_t3-crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest_a1-peddler_b1 vs ford_nest_a2-peddler_b2 | 86.7 m vs 92.3 m (6.1 %) | units walk ford_nest_a2-peddler_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-bridge_road_s vs rich_b1-bridge_road_s | 131.7 m vs 140.1 m (6.0 %) | units walk rich_b1-bridge_road_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a2-bridge_road_s vs rich_b2-bridge_road_n | 131.7 m vs 140.0 m (6.0 %) | units walk rich_b2-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_b1 vs node_a_a2-mouth_lair_b2 | 151.6 m vs 161.1 m (5.9 %) | units walk node_a_a2-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_b1 vs node_a_b2-mouth_lair_a2 | 151.6 m vs 161.1 m (5.9 %) | units walk node_a_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-mouth_lair_a2 vs rich_b1-mouth_lair_b2 | 134.0 m vs 142.3 m (5.8 %) | units walk rich_b1-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-mouth_lair_a2 vs rich_b2-mouth_lair_b1 | 134.0 m vs 142.3 m (5.8 %) | units walk rich_b2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_b2 vs node_a_b1-mouth_lair_a1 | 161.1 m vs 151.8 m (5.8 %) | units walk node_a_a2-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-mouth_lair_a1 vs node_a_b2-mouth_lair_a2 | 151.8 m vs 161.1 m (5.8 %) | units walk node_a_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_a1-mouth_lair_a2 vs rich_a2-mouth_lair_a1 | 134.0 m vs 142.2 m (5.8 %) | units walk rich_a2-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-stag_b1 vs node_b_b2-stag_a2 | 149.0 m vs 140.9 m (5.4 %) | units walk node_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-stag_b1 vs node_b_a2-stag_b2 | 149.0 m vs 140.9 m (5.4 %) | units walk node_b_a1-stag_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-stag_a1 vs node_b_b2-stag_a2 | 148.9 m vs 140.9 m (5.4 %) | units walk node_b_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-stag_b2 vs node_b_b1-stag_a1 | 140.9 m vs 148.9 m (5.4 %) | units walk node_b_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-fenwatch_a2 vs natural_b1-fenwatch_b2 | 82.8 m vs 87.4 m (5.4 %) | units walk natural_b1-fenwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-fenwatch_a1 vs natural_b1-fenwatch_b2 | 82.8 m vs 87.4 m (5.3 %) | units walk natural_b1-fenwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-crown_sw vs keep_t4-crown_ne | 93.3 m vs 88.4 m (5.3 %) | units walk keep_t3-crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-crown_nw vs keep_t3-crown_sw | 88.4 m vs 93.3 m (5.3 %) | units walk keep_t3-crown_sw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | mouth_lair_a2-bridge_road_s vs mouth_lair_b2-bridge_road_n | 149.3 m vs 157.6 m (5.3 %) | units walk mouth_lair_b2-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_b1-fenwatch_b2 vs natural_b2-fenwatch_b1 | 87.4 m vs 82.9 m (5.2 %) | units walk natural_b1-fenwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-fenwatch_b2 vs node_a_b1-fenwatch_a1 | 134.9 m vs 128.0 m (5.1 %) | units walk node_a_a2-fenwatch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-fenwatch_a1 vs node_a_b2-fenwatch_a2 | 128.0 m vs 134.9 m (5.1 %) | units walk node_a_b2-fenwatch_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-fenwatch_b1 vs node_a_b1-fenwatch_a1 | 134.9 m vs 128.0 m (5.1 %) | units walk node_a_a1-fenwatch_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest enemy keep | 122.2 m vs 138.7 m between seats (11.9 %) | move the far seat's spot closer (or check its route for a blocker) |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-62.0, 62.0) | (-61.1, 58.4) | keep_t4 | (-61.1, 58.4) | 0.0 |
| keep_t3 | keep | (-62.0, -62.0) | (-60.6, -57.9) | keep_t1 | (-60.6, -57.9) | 0.0 |
| keep_t1 | keep | (62.0, -62.0) | (60.6, -57.9) | keep_t3 | (60.6, -57.9) | 0.0 |
| keep_t4 | keep | (62.0, 62.0) | (61.1, 58.4) | keep_t0 | (61.1, 58.4) | 0.0 |
| node_a_a1 | home_node | (-65.0, 53.0) | (-64.9, 52.9) | node_a_b2 | (-64.9, 52.9) | 0.0 |
| node_a_a2 | home_node | (-65.0, -53.0) | (-64.9, -52.9) | node_a_b1 | (-64.9, -52.9) | 0.0 |
| node_a_b1 | home_node | (65.0, -53.0) | (64.9, -52.9) | node_a_a2 | (64.9, -52.9) | 0.0 |
| node_a_b2 | home_node | (65.0, 53.0) | (64.9, 52.9) | node_a_a1 | (64.9, 52.9) | 0.0 |
| node_b_a1 | home_node | (-53.0, 65.0) | (-52.9, 64.9) | node_b_b2 | (-52.9, 64.9) | 0.0 |
| node_b_a2 | home_node | (-53.0, -65.0) | (-52.9, -64.9) | node_b_b1 | (-52.9, -64.9) | 0.0 |
| node_b_b1 | home_node | (53.0, -65.0) | (52.9, -64.9) | node_b_a2 | (52.9, -64.9) | 0.0 |
| node_b_b2 | home_node | (53.0, 65.0) | (52.9, 64.9) | node_b_a1 | (52.9, 64.9) | 0.0 |
| natural_a1 | expansion | (-35.0, 25.0) | (-34.9, 24.9) | natural_b2 | (-34.9, 24.9) | 0.0 |
| natural_a2 | expansion | (-35.0, -25.0) | (-34.9, -24.9) | natural_b1 | (-34.9, -24.9) | 0.0 |
| natural_b1 | expansion | (35.0, -25.0) | (34.9, -24.9) | natural_a2 | (34.9, -24.9) | 0.0 |
| natural_b2 | expansion | (35.0, 25.0) | (34.9, 24.9) | natural_a1 | (34.9, 24.9) | 0.0 |
| glade_vein_a1 | expansion | (-60.0, 15.5) | (-59.9, 15.4) | glade_vein_b2 | (-59.9, 15.4) | 0.0 |
| glade_vein_a2 | expansion | (-60.0, -15.5) | (-59.9, -15.4) | glade_vein_b1 | (-59.9, -15.4) | 0.0 |
| glade_vein_b1 | expansion | (60.0, -15.5) | (59.9, -15.4) | glade_vein_a2 | (59.9, -15.4) | 0.0 |
| glade_vein_b2 | expansion | (60.0, 15.5) | (59.9, 15.4) | glade_vein_a1 | (59.9, 15.4) | 0.0 |
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
| shrine_a1 | point | (-70.0, 0.0) | (-69.9, 0.1) | shrine_b1 | (-69.9, 0.1) | 0.0 |
| shrine_b1 | point | (70.0, 0.0) | (69.9, 0.1) | shrine_a1 | (69.9, 0.1) | 0.0 |
| stag_a1 | camp | (-56.0, 9.0) | (-55.9, 8.9) | stag_b2 | (-55.9, 8.9) | 0.0 |
| stag_a2 | camp | (-56.0, -9.0) | (-55.9, -8.9) | stag_b1 | (-55.9, -8.9) | 0.0 |
| stag_b1 | camp | (56.0, -9.0) | (55.9, -8.9) | stag_a2 | (55.9, -8.9) | 0.0 |
| stag_b2 | camp | (56.0, 9.0) | (55.9, 8.9) | stag_a1 | (55.9, 8.9) | 0.0 |
| wallow_a1 | camp | (-40.0, 72.0) | (-39.9, 71.9) | wallow_b2 | (-39.9, 71.9) | 0.0 |
| wallow_a2 | camp | (-40.0, -72.0) | (-39.9, -71.9) | wallow_b1 | (-39.9, -71.9) | 0.0 |
| wallow_b1 | camp | (40.0, -72.0) | (39.9, -71.9) | wallow_a2 | (39.9, -71.9) | 0.0 |
| wallow_b2 | camp | (40.0, 72.0) | (39.9, 71.9) | wallow_a1 | (39.9, 71.9) | 0.0 |
| hollow_a1 | camp | (-40.0, 0.0) | (-39.9, 0.1) | hollow_b1 | (-39.9, 0.1) | 0.0 |
| hollow_b1 | camp | (40.0, 0.0) | (39.9, 0.1) | hollow_a1 | (39.9, 0.1) | 0.0 |
| ford_nest_a1 | camp | (0.0, 36.0) | (-0.1, 35.9) | ford_nest_a1 | (0.1, 35.9) | 0.3 |
| ford_nest_a2 | camp | (0.0, -36.0) | (-0.1, -35.9) | ford_nest_a2 | (0.1, -35.9) | 0.3 |
| tavern_a1 | tavern | (-18.0, 22.0) | (-17.9, 21.9) | tavern_b2 | (-17.9, 21.9) | 0.0 |
| tavern_a2 | tavern | (-18.0, -22.0) | (-17.9, -21.9) | tavern_b1 | (-17.9, -21.9) | 0.0 |
| tavern_b1 | tavern | (18.0, -22.0) | (17.9, -21.9) | tavern_a2 | (17.9, -21.9) | 0.0 |
| tavern_b2 | tavern | (18.0, 22.0) | (17.9, 21.9) | tavern_a1 | (17.9, 21.9) | 0.0 |
| fen_post_a1 | post | (-74.0, 30.0) | (-73.9, 29.9) | fen_post_b2 | (-73.9, 29.9) | 0.0 |
| fen_post_a2 | post | (-74.0, -30.0) | (-73.9, -29.9) | fen_post_b1 | (-73.9, -29.9) | 0.0 |
| fen_post_b1 | post | (74.0, -30.0) | (73.9, -29.9) | fen_post_a2 | (73.9, -29.9) | 0.0 |
| fen_post_b2 | post | (74.0, 30.0) | (73.9, 29.9) | fen_post_a1 | (73.9, 29.9) | 0.0 |
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
| cache_a1 | cache | (-44.0, 40.0) | (-43.9, 39.9) | cache_b2 | (-43.9, 39.9) | 0.0 |
| cache_a2 | cache | (-44.0, -40.0) | (-43.9, -39.9) | cache_b1 | (-43.9, -39.9) | 0.0 |
| cache_b1 | cache | (44.0, -40.0) | (43.9, -39.9) | cache_a2 | (43.9, -39.9) | 0.0 |
| cache_b2 | cache | (44.0, 40.0) | (43.9, 39.9) | cache_a1 | (43.9, 39.9) | 0.0 |
| heath_lair_a1 | lair | (-77.0, 42.0) | (-76.9, 41.9) | heath_lair_b2 | (-76.9, 41.9) | 0.0 |
| heath_lair_a2 | lair | (-77.0, -42.0) | (-76.9, -41.9) | heath_lair_b1 | (-76.9, -41.9) | 0.0 |
| heath_lair_b1 | lair | (77.0, -42.0) | (76.9, -41.9) | heath_lair_a2 | (76.9, -41.9) | 0.0 |
| heath_lair_b2 | lair | (77.0, 42.0) | (76.9, 41.9) | heath_lair_a1 | (76.9, 41.9) | 0.0 |
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


## F2 unit paths: most asymmetric pairs (top 20 of 322)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | node_b_a2 - lodge_a1 | 65.7 | node_b_b2 - lodge_b1 | 89.0 | -26.2 % |
| 2 | node_b_b1 - lodge_b1 | 65.7 | node_b_b2 - lodge_b1 | 89.0 | -26.2 % |
| 3 | node_b_a1 - lodge_a1 | 65.7 | node_b_b2 - lodge_b1 | 89.0 | -26.2 % |
| 4 | glade_vein_b1 - mouth_lair_b2 | 105.3 | glade_vein_b2 - mouth_lair_b1 | 135.8 | -22.5 % |
| 5 | glade_vein_a2 - mouth_lair_a1 | 135.7 | glade_vein_b1 - mouth_lair_b2 | 105.3 | +22.4 % |
| 6 | glade_vein_a1 - mouth_lair_a2 | 135.5 | glade_vein_b1 - mouth_lair_b2 | 105.3 | +22.3 % |
| 7 | fen_post_a2 - mouth_lair_b2 | 138.4 | fen_post_b1 - mouth_lair_a1 | 174.9 | -20.9 % |
| 8 | fen_post_a2 - mouth_lair_b2 | 138.4 | fen_post_b2 - mouth_lair_a2 | 174.8 | -20.8 % |
| 9 | fen_post_a1 - mouth_lair_b1 | 174.6 | fen_post_a2 - mouth_lair_b2 | 138.4 | +20.7 % |
| 10 | fenwatch_a1 - lodge_b1 | 89.4 | fenwatch_a2 - lodge_b1 | 111.5 | -19.8 % |
| 11 | fenwatch_a2 - lodge_b1 | 111.5 | fenwatch_b2 - lodge_a1 | 89.5 | +19.7 % |
| 12 | fenwatch_a2 - lodge_b1 | 111.5 | fenwatch_b1 - lodge_a1 | 89.6 | +19.6 % |
| 13 | keep_t0 - hollow_b1 | 139.7 | keep_t1 - hollow_a1 | 117.6 | +15.8 % |
| 14 | hollow_b1 - mouth_lair_a1 | 114.0 | hollow_b1 - mouth_lair_a2 | 95.9 | +15.8 % |
| 15 | keep_t1 - hollow_a1 | 117.6 | keep_t4 - hollow_a1 | 139.6 | -15.8 % |
| 16 | hollow_a1 - mouth_lair_b2 | 96.0 | hollow_b1 - mouth_lair_a1 | 114.0 | -15.8 % |
| 17 | hollow_a1 - mouth_lair_b1 | 96.1 | hollow_b1 - mouth_lair_a1 | 114.0 | -15.7 % |
| 18 | keep_t3 - hollow_b1 | 139.1 | keep_t1 - hollow_a1 | 117.6 | +15.5 % |
| 19 | spine_post_b1 - den_b1 | 102.8 | spine_post_b2 - den_b1 | 86.9 | +15.5 % |
| 20 | spine_post_a1 - den_a1 | 102.8 | spine_post_b2 - den_b1 | 86.9 | +15.4 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| player (A1 south-west) | 42.6 (natural_a1) | 53.9 (fenwatch_a1) | 25.6 (wallow_a1) | 22.8 (heath_lair_a1) | 56.6 (tavern_a1) | 31.2 (fen_post_a1) | 34.5 (peddler_a1) | 25.3 (cache_a1) | 84.3 (crown) | 138.7 |
| ally (A2 north-west) | 41.9 (natural_a2) | 53.4 (fenwatch_a2) | 25.2 (wallow_a2) | 22.8 (heath_lair_a2) | 55.9 (tavern_a2) | 31.0 (fen_post_a2) | 33.8 (peddler_a2) | 24.6 (cache_a2) | 83.6 (crown) | 122.2 |
| enemy (B1 north-east) | 41.9 (natural_b1) | 53.4 (fenwatch_b1) | 25.2 (wallow_b1) | 22.8 (heath_lair_b1) | 55.9 (tavern_b1) | 31.0 (fen_post_b1) | 33.8 (peddler_b1) | 24.6 (cache_b1) | 83.6 (crown) | 122.2 |
| enemy 2 (B2 south-east) | 42.6 (natural_b2) | 53.9 (fenwatch_b2) | 25.5 (wallow_b2) | 22.8 (heath_lair_b2) | 56.6 (tavern_b2) | 31.2 (fen_post_b2) | 34.5 (peddler_b2) | 25.3 (cache_b2) | 84.3 (crown) | 138.7 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| node_a_a1 | home_node | 6.7 | node_a_b2 | 6.7 | +0.0 % |
| node_b_a1 | home_node | 11.2 | node_b_b2 | 11.1 | +0.7 % |
| heath_lair_a1 | lair | 22.8 | heath_lair_b2 | 22.8 | +0.0 % |
| cache_a1 | cache | 25.3 | cache_b2 | 25.3 | +0.0 % |
| wallow_a1 | camp | 25.6 | wallow_b2 | 25.5 | +0.2 % |
| fen_post_a1 | post | 31.2 | fen_post_b2 | 31.2 | +0.0 % |
| peddler_a1 | peddler | 34.5 | peddler_b2 | 34.5 | +0.0 % |
| spine_post_a1 | post | 35.1 | spine_post_b2 | 35.1 | +0.1 % |
| natural_a1 | expansion | 42.6 | natural_b2 | 42.6 | +0.0 % |
| glade_vein_a1 | expansion | 43.0 | glade_vein_b2 | 43.0 | +0.0 % |
| rich_a1 | expansion | 47.3 | rich_b2 | 47.3 | +0.0 % |
| stag_a1 | camp | 49.8 | stag_b2 | 49.8 | +0.0 % |
| mouth_lair_a1 | lair | 52.4 | mouth_lair_b2 | 52.4 | +0.0 % |
| fenwatch_a1 | point | 53.9 | fenwatch_b2 | 53.9 | +0.0 % |
| tavern_a1 | tavern | 56.6 | tavern_b2 | 56.6 | +0.0 % |
| lodge_a1 | guild | 58.3 | lodge_b1 | 58.3 | +0.0 % |
| well_a1 | point | 58.4 | well_b2 | 58.4 | +0.0 % |
| shrine_a1 | point | 58.9 | shrine_b1 | 58.9 | +0.0 % |
| den_a1 | guild | 60.1 | den_b1 | 60.1 | +0.0 % |
| bridge_road_s | crossing_bridge_road | 61.8 | bridge_road_s | 61.8 | +0.0 % |
| hollow_a1 | camp | 62.0 | hollow_b1 | 62.0 | +0.0 % |
| ford_nest_a1 | camp | 65.0 | ford_nest_a1 | 65.0 | +0.0 % |
| ford_s | crossing_ford | 65.0 | ford_s | 65.0 | +0.0 % |
| crown_sw | crossing_bridge_lane | 72.0 | crown_se | 72.0 | +0.0 % |
| mouth_lair_b2 | lair | 75.6 | mouth_lair_a1 | 75.6 | +0.0 % |
| stag_a2 | camp | 77.6 | stag_b1 | 77.3 | +0.4 % |
| rich_b2 | expansion | 77.9 | rich_a1 | 77.8 | +0.1 % |
| fenwatch_b2 | point | 79.7 | fenwatch_a1 | 79.6 | +0.2 % |
| well_a2 | point | 79.8 | well_b1 | 79.9 | -0.1 % |
| crown | crown | 84.3 | crown | 84.3 | +0.0 % |
| glade_vein_a2 | expansion | 84.5 | glade_vein_b1 | 84.2 | +0.3 % |
| natural_a2 | expansion | 87.3 | natural_b1 | 87.3 | +0.0 % |
| tavern_b2 | tavern | 87.5 | tavern_a1 | 87.5 | +0.0 % |
| crown_nw | crossing_bridge_lane | 88.4 | crown_ne | 88.4 | +0.0 % |
| crown_se | crossing_bridge_lane | 88.6 | crown_sw | 88.6 | +0.0 % |
| fen_post_a2 | post | 89.2 | fen_post_b1 | 89.2 | +0.0 % |
| spine_post_b2 | post | 92.3 | spine_post_a1 | 92.3 | +0.0 % |
| tavern_a2 | tavern | 92.5 | tavern_b1 | 92.6 | -0.1 % |
| peddler_b2 | peddler | 94.8 | peddler_a1 | 94.8 | -0.0 % |
| crown_ne | crossing_bridge_lane | 97.1 | crown_nw | 97.1 | +0.0 % |
| well_b2 | point | 100.1 | well_a1 | 100.0 | +0.0 % |
| cache_a2 | cache | 101.0 | cache_b1 | 100.9 | +0.1 % |
| heath_lair_a2 | lair | 101.5 | heath_lair_b1 | 101.5 | +0.0 % |
| natural_b2 | expansion | 101.7 | natural_a1 | 101.7 | +0.0 % |
| wallow_b2 | camp | 101.9 | wallow_a1 | 101.9 | +0.0 % |
| peddler_a2 | peddler | 106.9 | peddler_b1 | 106.9 | +0.0 % |
| cache_b2 | cache | 108.3 | cache_a1 | 108.3 | -0.0 % |
| tavern_b1 | tavern | 112.6 | tavern_a2 | 112.6 | +0.0 % |
| well_b1 | point | 112.8 | well_a2 | 112.8 | +0.0 % |
| node_b_b2 | home_node | 114.5 | node_b_a1 | 114.5 | +0.0 % |
| ford_nest_a2 | camp | 115.0 | ford_nest_a2 | 115.1 | -0.1 % |
| ford_n | crossing_ford | 115.0 | ford_n | 115.1 | -0.1 % |
| node_a_a2 | home_node | 118.3 | node_a_b1 | 118.2 | +0.1 % |
| fenwatch_a2 | point | 121.0 | fenwatch_b1 | 121.0 | -0.0 % |
| keep_t3 | keep | 121.6 | keep_t1 | 121.4 | +0.1 % |
| rich_a2 | expansion | 125.5 | rich_b1 | 125.5 | -0.0 % |
| node_b_a2 | home_node | 126.7 | node_b_b1 | 126.6 | +0.1 % |
| stag_b2 | camp | 127.1 | stag_a1 | 127.1 | +0.0 % |
| natural_b1 | expansion | 127.2 | natural_a2 | 127.2 | +0.0 % |
| glade_vein_b2 | expansion | 128.4 | glade_vein_a1 | 128.4 | +0.0 % |
| wallow_a2 | camp | 133.1 | wallow_b1 | 133.0 | +0.1 % |
| fenwatch_b1 | point | 135.9 | fenwatch_a2 | 135.9 | +0.0 % |
| spine_post_a2 | post | 136.2 | spine_post_b1 | 136.1 | +0.0 % |
| peddler_b1 | peddler | 137.3 | peddler_a2 | 137.3 | +0.0 % |
| keep_t4 | keep | 138.7 | keep_t0 | 138.7 | +0.0 % |
| fen_post_b2 | post | 138.7 | fen_post_a1 | 138.8 | -0.0 % |
| hollow_b1 | camp | 139.7 | hollow_a1 | 139.6 | +0.1 % |
| node_a_b2 | home_node | 140.0 | node_a_a1 | 139.7 | +0.2 % |
| bridge_road_n | crossing_bridge_road | 140.7 | bridge_road_n | 140.8 | -0.1 % |
| stag_b1 | camp | 142.0 | stag_a2 | 142.0 | +0.0 % |
| heath_lair_b2 | lair | 142.1 | heath_lair_a1 | 142.1 | +0.0 % |
| mouth_lair_a2 | lair | 143.0 | mouth_lair_b1 | 143.0 | +0.0 % |
| shrine_b1 | point | 143.5 | shrine_a1 | 158.1 | -9.2 % |
| cache_b1 | cache | 143.8 | cache_a2 | 143.8 | +0.0 % |
| rich_b1 | expansion | 144.4 | rich_a2 | 144.4 | +0.0 % |
| glade_vein_b1 | expansion | 146.7 | glade_vein_a2 | 146.7 | +0.0 % |
| den_b1 | guild | 148.9 | den_a1 | 148.9 | +0.0 % |
| lodge_b1 | guild | 154.0 | lodge_a1 | 153.9 | +0.1 % |
| mouth_lair_b1 | lair | 162.1 | mouth_lair_a2 | 162.1 | +0.0 % |
| spine_post_b1 | post | 164.0 | spine_post_a2 | 164.0 | +0.0 % |
| fen_post_b1 | post | 164.1 | fen_post_a2 | 164.1 | +0.0 % |
| wallow_b1 | camp | 166.4 | wallow_a2 | 166.4 | +0.0 % |
| node_b_b1 | home_node | 168.0 | node_b_a2 | 168.0 | +0.0 % |
| node_a_b1 | home_node | 168.1 | node_a_a2 | 168.1 | +0.0 % |
| keep_t1 | keep | 168.3 | keep_t3 | 168.3 | +0.0 % |
| heath_lair_b1 | lair | 171.8 | heath_lair_a2 | 171.8 | +0.0 % |


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
| keep_t0 -> crown | 84.5 | 5.5 | (-7.5, 7.4) | - |
| keep_t0 -> keep_t1 | 168.3 | 5.5 | (-7.6, 7.3) | - |
| keep_t0 -> keep_t4 | 138.7 | 4.8 | (-0.6, 65.7) | - |
| keep_t0 -> natural_a1 | 42.6 | 40.1 | (-58.7, 55.2) | - |
| keep_t3 -> crown | 84.0 | 5.8 | (-7.8, -7.5) | - |
| keep_t3 -> keep_t4 | 168.3 | 5.8 | (-7.8, -7.5) | - |
| keep_t3 -> natural_a2 | 41.9 | 40.1 | (-58.2, -54.7) | - |
| keep_t1 -> crown | 83.8 | 5.8 | (7.9, -7.4) | - |
| keep_t1 -> keep_t3 | 138.3 | 4.8 | (0.1, -65.5) | - |
| keep_t1 -> natural_b1 | 41.9 | 40.1 | (58.2, -54.7) | - |
| keep_t4 -> crown | 84.3 | 5.5 | (7.6, 7.3) | - |
| keep_t4 -> natural_b2 | 42.6 | 40.1 | (58.7, 55.2) | - |


## Hottest metres (every spot-pair shortest path, 3741 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (5.5, 9.5) | 224 | 6 % |
| 2 | (-5.5, -9.5) | 220 | 6 % |
| 3 | (1.5, -1.5) | 194 | 5 % |
| 4 | (-9.5, 5.5) | 188 | 5 % |
| 5 | (9.5, -5.5) | 183 | 5 % |
| 6 | (0.5, 35.5) | 146 | 4 % |
| 7 | (-0.5, -35.5) | 136 | 4 % |
| 8 | (-2.5, -65.5) | 134 | 4 % |
| 9 | (3.5, 65.5) | 133 | 4 % |
| 10 | (36.5, 2.5) | 121 | 3 % |


## Info findings (154)
| Check | Where | What |
|---|---|---|
| N3 | island 5 at (-61.9, -61.9) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 6 at (62.1, -61.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 22 at (-61.9, 62.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 23 at (62.1, 62.1) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 16 islands on top of colliders (582 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | fen_post_a2-ford_s vs fen_post_b2-ford_n | 104.0 m vs 98.8 m (5.0 %) |
| F2 | fen_post_a2-ford_s vs fen_post_b1-ford_s | 104.0 m vs 98.8 m (5.0 %) |
| F2 | fen_post_a1-ford_n vs fen_post_b2-ford_n | 103.9 m vs 98.8 m (4.9 %) |
| F2 | fen_post_a1-ford_n vs fen_post_b1-ford_s | 103.9 m vs 98.8 m (4.9 %) |
| F2 | glade_vein_b1-peddler_a1 vs glade_vein_b2-peddler_a2 | 109.3 m vs 114.9 m (4.9 %) |
| F2 | glade_vein_a1-peddler_b1 vs glade_vein_b1-peddler_a1 | 114.9 m vs 109.3 m (4.9 %) |
| F2 | fen_post_a1-spine_post_a2 vs fen_post_b2-spine_post_b1 | 112.7 m vs 118.4 m (4.8 %) |
| F2 | fen_post_a2-spine_post_a1 vs fen_post_b2-spine_post_b1 | 112.7 m vs 118.4 m (4.8 %) |
| F2 | fen_post_a1-spine_post_a2 vs fen_post_b1-spine_post_b2 | 112.7 m vs 118.3 m (4.8 %) |
| F2 | fen_post_a2-spine_post_a1 vs fen_post_b1-spine_post_b2 | 112.7 m vs 118.3 m (4.8 %) |
| F2 | stag_a1-peddler_b1 vs stag_b2-peddler_a2 | 102.3 m vs 107.4 m (4.8 %) |
| F2 | stag_a2-peddler_b2 vs stag_b2-peddler_a2 | 102.3 m vs 107.4 m (4.7 %) |
| F2 | stag_b1-peddler_a1 vs stag_b2-peddler_a2 | 102.3 m vs 107.4 m (4.7 %) |
| F2 | stag_a1-cache_b2 vs stag_a2-cache_b1 | 110.5 m vs 105.4 m (4.6 %) |
| F2 | stag_a2-cache_b1 vs stag_b2-cache_a1 | 105.4 m vs 110.5 m (4.6 %) |
| F2 | keep_t0-mouth_lair_b1 vs keep_t1-mouth_lair_a1 | 162.1 m vs 154.6 m (4.6 %) |
| F2 | keep_t1-mouth_lair_a1 vs keep_t4-mouth_lair_a2 | 154.6 m vs 162.1 m (4.6 %) |
| F2 | stag_a2-cache_b1 vs stag_b1-cache_a2 | 105.4 m vs 110.4 m (4.6 %) |
| F2 | wallow_a1-ford_n vs wallow_a2-ford_s | 116.1 m vs 121.6 m (4.5 %) |
| F2 | wallow_a1-ford_nest_a2 vs wallow_a2-ford_nest_a1 | 116.1 m vs 121.6 m (4.5 %) |
| F2 | glade_vein_a2-peddler_b2 vs glade_vein_b1-peddler_a1 | 114.4 m vs 109.3 m (4.5 %) |
| F2 | wallow_a2-ford_nest_a1 vs wallow_b2-ford_nest_a2 | 121.6 m vs 116.2 m (4.4 %) |
| F2 | wallow_a2-ford_s vs wallow_b2-ford_n | 121.6 m vs 116.2 m (4.4 %) |
| F2 | wallow_a2-ford_nest_a1 vs wallow_b1-ford_nest_a1 | 121.6 m vs 116.2 m (4.4 %) |
| F2 | wallow_a2-ford_s vs wallow_b1-ford_s | 121.6 m vs 116.2 m (4.4 %) |
| F2 | rich_b1-stag_a1 vs rich_b2-stag_a2 | 112.2 m vs 117.3 m (4.4 %) |
| F2 | rich_a2-stag_b2 vs rich_b1-stag_a1 | 117.3 m vs 112.2 m (4.3 %) |
| F2 | fenwatch_a1-ford_n vs fenwatch_a2-ford_s | 87.2 m vs 91.1 m (4.3 %) |
| F2 | fenwatch_a1-ford_nest_a2 vs fenwatch_a2-ford_nest_a1 | 87.2 m vs 91.1 m (4.3 %) |
| F2 | rich_a1-stag_b1 vs rich_b2-stag_a2 | 112.3 m vs 117.3 m (4.2 %) |
| F2 | fen_post_a2-crown_sw vs fen_post_b1-crown_se | 87.1 m vs 83.4 m (4.2 %) |
| F2 | rich_a1-stag_b1 vs rich_a2-stag_b2 | 112.3 m vs 117.3 m (4.2 %) |
| F2 | keep_t3-mouth_lair_b2 vs keep_t1-mouth_lair_a1 | 161.4 m vs 154.6 m (4.2 %) |
| F2 | fen_post_a1-crown_nw vs fen_post_a2-crown_sw | 83.4 m vs 87.1 m (4.2 %) |
| F2 | fen_post_a2-crown_sw vs fen_post_b2-crown_ne | 87.1 m vs 83.4 m (4.1 %) |
| F2 | fenwatch_a2-ford_s vs fenwatch_b2-ford_n | 91.1 m vs 87.4 m (4.1 %) |
| F2 | fenwatch_a2-ford_nest_a1 vs fenwatch_b2-ford_nest_a2 | 91.1 m vs 87.4 m (4.1 %) |
| F2 | fenwatch_a2-ford_nest_a1 vs fenwatch_b1-ford_nest_a1 | 91.1 m vs 87.4 m (4.1 %) |
| F2 | fenwatch_a2-ford_s vs fenwatch_b1-ford_s | 91.1 m vs 87.4 m (4.1 %) |
| F2 | rich_a1-ford_nest_a2 vs rich_a2-ford_nest_a1 | 95.6 m vs 99.6 m (4.1 %) |
| F2 | rich_a1-ford_n vs rich_a2-ford_s | 95.6 m vs 99.6 m (4.1 %) |
| F2 | hollow_a1-heath_lair_b1 vs hollow_b1-heath_lair_a2 | 130.4 m vs 125.1 m (4.1 %) |
| F2 | spine_post_a1-ford_n vs spine_post_a2-ford_s | 114.4 m vs 119.2 m (4.0 %) |
| F2 | ford_nest_a1-spine_post_a2 vs ford_nest_a2-spine_post_a1 | 119.2 m vs 114.4 m (4.0 %) |
| F2 | hollow_a1-heath_lair_b1 vs hollow_a1-heath_lair_b2 | 130.4 m vs 125.2 m (4.0 %) |
| F2 | rich_a2-ford_s vs rich_b2-ford_n | 99.6 m vs 95.7 m (4.0 %) |
| F2 | rich_a2-ford_nest_a1 vs rich_b2-ford_nest_a2 | 99.6 m vs 95.7 m (4.0 %) |
| F2 | hollow_a1-heath_lair_b1 vs hollow_b1-heath_lair_a1 | 130.4 m vs 125.3 m (4.0 %) |
| F2 | wallow_a2-lodge_a1 vs wallow_b2-lodge_b1 | 91.7 m vs 95.4 m (4.0 %) |
| F2 | spine_post_a2-ford_s vs spine_post_b2-ford_n | 119.2 m vs 114.5 m (3.9 %) |
| F2 | rich_a2-ford_s vs rich_b1-ford_s | 99.6 m vs 95.7 m (3.9 %) |
| F2 | rich_a2-ford_nest_a1 vs rich_b1-ford_nest_a1 | 99.6 m vs 95.7 m (3.9 %) |
| F2 | ford_nest_a1-spine_post_a2 vs ford_nest_a1-spine_post_b1 | 119.2 m vs 114.6 m (3.9 %) |
| F2 | spine_post_a2-ford_s vs spine_post_b1-ford_s | 119.2 m vs 114.6 m (3.9 %) |
| F2 | ford_nest_a2-spine_post_a1 vs ford_nest_a2-spine_post_b2 | 114.4 m vs 119.1 m (3.9 %) |
| F2 | wallow_a1-lodge_a1 vs wallow_b2-lodge_b1 | 91.8 m vs 95.4 m (3.8 %) |
| F2 | node_b_a1-hollow_b1 vs node_b_b2-hollow_a1 | 131.0 m vs 126.0 m (3.8 %) |
| F2 | ford_nest_a1-spine_post_b1 vs ford_nest_a2-spine_post_b2 | 114.6 m vs 119.1 m (3.8 %) |
| F2 | hollow_a1-fen_post_b1 vs hollow_b1-fen_post_a2 | 122.7 m vs 118.1 m (3.8 %) |
| F2 | rich_a2-peddler_b1 vs rich_b1-peddler_a2 | 53.6 m vs 55.7 m (3.8 %) |
| F2 | hollow_a1-fen_post_b1 vs hollow_a1-fen_post_b2 | 122.7 m vs 118.1 m (3.8 %) |
| F2 | node_b_a2-hollow_b1 vs node_b_b2-hollow_a1 | 130.9 m vs 126.0 m (3.7 %) |
| F2 | wallow_b1-lodge_b1 vs wallow_b2-lodge_b1 | 91.9 m vs 95.4 m (3.7 %) |
| F2 | keep_t0-fenwatch_b1 vs keep_t1-fenwatch_a1 | 135.9 m vs 130.8 m (3.7 %) |
| F2 | keep_t1-fenwatch_a1 vs keep_t4-fenwatch_a2 | 130.8 m vs 135.9 m (3.7 %) |
| F2 | hollow_a1-fen_post_b1 vs hollow_b1-fen_post_a1 | 122.7 m vs 118.2 m (3.7 %) |
| F2 | node_b_b1-hollow_a1 vs node_b_b2-hollow_a1 | 130.8 m vs 126.0 m (3.7 %) |
| F2 | node_b_a1-ford_nest_a2 vs node_b_a2-ford_nest_a1 | 118.6 m vs 123.0 m (3.5 %) |
| F2 | node_b_a1-ford_n vs node_b_a2-ford_s | 118.6 m vs 123.0 m (3.5 %) |
| F2 | node_a_a2-crown_sw vs node_a_b1-crown_se | 90.6 m vs 87.4 m (3.5 %) |
| F2 | rich_b1-peddler_a2 vs rich_b2-peddler_a1 | 55.7 m vs 53.8 m (3.5 %) |
| F2 | node_a_a2-crown_sw vs node_a_b2-crown_ne | 90.6 m vs 87.4 m (3.5 %) |
| F2 | node_a_a1-crown_nw vs node_a_a2-crown_sw | 87.4 m vs 90.6 m (3.5 %) |
| F2 | lodge_a1-heath_lair_b1 vs lodge_b1-heath_lair_a2 | 154.3 m vs 149.0 m (3.4 %) |
| F2 | node_b_a2-ford_s vs node_b_b1-ford_s | 123.0 m vs 118.8 m (3.4 %) |
| F2 | node_b_a2-ford_nest_a1 vs node_b_b1-ford_nest_a1 | 123.0 m vs 118.8 m (3.4 %) |
| F2 | node_b_a2-ford_nest_a1 vs node_b_b2-ford_nest_a2 | 123.0 m vs 118.8 m (3.4 %) |
| F2 | node_b_a2-ford_s vs node_b_b2-ford_n | 123.0 m vs 118.8 m (3.4 %) |
| F2 | lodge_a1-heath_lair_b1 vs lodge_a1-heath_lair_b2 | 154.3 m vs 149.0 m (3.4 %) |
| F2 | spine_post_b1-lodge_b1 vs spine_post_b2-lodge_b1 | 102.1 m vs 98.6 m (3.4 %) |
| F2 | lodge_a1-heath_lair_b1 vs lodge_b1-heath_lair_a1 | 154.3 m vs 149.1 m (3.4 %) |
| F2 | ford_nest_a1-mouth_lair_a2 vs ford_nest_a2-mouth_lair_a1 | 117.3 m vs 113.4 m (3.4 %) |
| F2 | mouth_lair_a1-ford_n vs mouth_lair_a2-ford_s | 113.4 m vs 117.3 m (3.4 %) |
| F2 | shrine_a1-heath_lair_b1 vs shrine_b1-heath_lair_a2 | 159.8 m vs 154.5 m (3.3 %) |
| F2 | shrine_a1-heath_lair_b1 vs shrine_a1-heath_lair_b2 | 159.8 m vs 154.5 m (3.3 %) |
| F2 | rich_a1-peddler_b2 vs rich_a2-peddler_b1 | 55.4 m vs 53.6 m (3.3 %) |
| F2 | shrine_a1-heath_lair_b1 vs shrine_b1-heath_lair_a1 | 159.8 m vs 154.5 m (3.3 %) |
| F2 | spine_post_a1-heath_lair_a2 vs spine_post_b2-heath_lair_b1 | 129.2 m vs 125.0 m (3.3 %) |
| F2 | mouth_lair_a2-ford_s vs mouth_lair_b2-ford_n | 117.3 m vs 113.5 m (3.3 %) |
| F2 | spine_post_a1-lodge_a1 vs spine_post_b1-lodge_b1 | 98.7 m vs 102.1 m (3.2 %) |
| F2 | keep_t3-fenwatch_b2 vs keep_t1-fenwatch_a1 | 135.2 m vs 130.8 m (3.2 %) |
| F2 | ford_nest_a2-mouth_lair_a1 vs ford_nest_a2-mouth_lair_b2 | 113.4 m vs 117.2 m (3.2 %) |
| F2 | ford_nest_a1-mouth_lair_a2 vs ford_nest_a1-mouth_lair_b1 | 117.3 m vs 113.5 m (3.2 %) |
| F2 | mouth_lair_a2-ford_s vs mouth_lair_b1-ford_s | 117.3 m vs 113.5 m (3.2 %) |
| F2 | fenwatch_a1-bridge_road_n vs fenwatch_a2-bridge_road_s | 119.2 m vs 123.2 m (3.2 %) |
| F2 | spine_post_a2-lodge_a1 vs spine_post_b2-lodge_b1 | 101.8 m vs 98.6 m (3.2 %) |
| F2 | den_a1-heath_lair_b1 vs den_b1-heath_lair_a2 | 165.7 m vs 160.4 m (3.2 %) |
| F2 | rich_a1-heath_lair_b1 vs rich_b2-heath_lair_a2 | 152.0 m vs 147.1 m (3.2 %) |
| F2 | rich_a1-heath_lair_b1 vs rich_a2-heath_lair_b2 | 152.0 m vs 147.1 m (3.2 %) |
| F2 | stag_a1-tavern_b1 vs stag_a2-tavern_b2 | 85.5 m vs 82.8 m (3.2 %) |
| F2 | den_a1-heath_lair_b1 vs den_a1-heath_lair_b2 | 165.7 m vs 160.4 m (3.2 %) |
| F2 | den_a1-heath_lair_b1 vs den_b1-heath_lair_a1 | 165.7 m vs 160.4 m (3.2 %) |
| F2 | stag_a2-tavern_b2 vs stag_b2-tavern_a2 | 82.8 m vs 85.5 m (3.2 %) |
| F2 | rich_a1-bridge_road_n vs rich_a2-bridge_road_s | 127.5 m vs 131.7 m (3.2 %) |
| F2 | stag_a1-tavern_b1 vs stag_b1-tavern_a1 | 85.5 m vs 82.9 m (3.1 %) |
| F2 | ford_nest_a1-mouth_lair_b1 vs ford_nest_a2-mouth_lair_b2 | 113.5 m vs 117.2 m (3.1 %) |
| F2 | stag_b1-tavern_a1 vs stag_b2-tavern_a2 | 82.9 m vs 85.5 m (3.1 %) |
| F2 | heath_lair_a2-crown_sw vs heath_lair_b2-crown_ne | 88.3 m vs 91.1 m (3.1 %) |
| F2 | heath_lair_a1-crown_nw vs heath_lair_a2-crown_sw | 91.1 m vs 88.3 m (3.1 %) |
| F2 | fenwatch_a2-bridge_road_s vs fenwatch_b2-bridge_road_n | 123.2 m vs 119.4 m (3.1 %) |
| F2 | shrine_a1-fen_post_b1 vs shrine_b1-fen_post_a2 | 152.1 m vs 147.4 m (3.1 %) |
| F2 | shrine_a1-fen_post_b1 vs shrine_a1-fen_post_b2 | 152.1 m vs 147.5 m (3.0 %) |
| F2 | spine_post_a1-lodge_a1 vs spine_post_a2-lodge_a1 | 98.7 m vs 101.8 m (3.0 %) |
| F2 | shrine_a1-fen_post_b1 vs shrine_b1-fen_post_a1 | 152.1 m vs 147.5 m (3.0 %) |
| F2 | fenwatch_a2-bridge_road_s vs fenwatch_b1-bridge_road_s | 123.2 m vs 119.4 m (3.0 %) |
| F2 | heath_lair_a2-crown_sw vs heath_lair_b1-crown_se | 88.3 m vs 91.1 m (3.0 %) |
| F2 | rich_a1-peddler_b2 vs rich_b2-peddler_a1 | 55.4 m vs 53.8 m (3.0 %) |
| F2 | well_a2-cache_b1 vs well_b2-cache_a1 | 78.3 m vs 80.7 m (3.0 %) |
| F2 | well_a1-cache_b2 vs well_a2-cache_b1 | 80.7 m vs 78.3 m (3.0 %) |
| F2 | rich_b1-heath_lair_a1 vs rich_b2-heath_lair_a2 | 151.6 m vs 147.1 m (3.0 %) |
| F2 | rich_a2-heath_lair_b2 vs rich_b1-heath_lair_a1 | 147.1 m vs 151.6 m (3.0 %) |
| F2 | den_a1-cache_b1 vs den_b1-cache_a1 | 127.2 m vs 131.0 m (2.9 %) |
| F2 | den_a1-cache_b1 vs den_a1-cache_b2 | 127.2 m vs 131.0 m (2.9 %) |
| F2 | well_a2-cache_b1 vs well_b1-cache_a2 | 78.3 m vs 80.6 m (2.9 %) |
| F2 | den_a1-cache_b1 vs den_b1-cache_a2 | 127.2 m vs 131.0 m (2.9 %) |
| F2 | shrine_a1-stag_b1 vs shrine_b1-stag_a2 | 130.0 m vs 126.3 m (2.9 %) |
| F2 | shrine_a1-stag_b1 vs shrine_a1-stag_b2 | 130.0 m vs 126.3 m (2.8 %) |
| F2 | shrine_a1-stag_b1 vs shrine_b1-stag_a1 | 130.0 m vs 126.3 m (2.8 %) |
| F2 | natural_a1-hollow_b1 vs natural_b2-hollow_a1 | 88.1 m vs 85.7 m (2.8 %) |
| F2 | mouth_lair_a1-bridge_road_n vs mouth_lair_a2-bridge_road_s | 145.3 m vs 149.3 m (2.7 %) |
| F2 | rich_a2-cache_b1 vs rich_b1-cache_a2 | 67.4 m vs 69.2 m (2.7 %) |
| F2 | natural_a1-hollow_b1 vs natural_a2-hollow_b1 | 88.1 m vs 85.8 m (2.7 %) |
| F2 | natural_b1-hollow_a1 vs natural_b2-hollow_a1 | 87.9 m vs 85.7 m (2.6 %) |
| F2 | mouth_lair_a2-bridge_road_s vs mouth_lair_b1-bridge_road_s | 149.3 m vs 145.5 m (2.5 %) |
| F2 | natural_a2-hollow_b1 vs natural_b1-hollow_a1 | 85.8 m vs 87.9 m (2.4 %) |
| F2 | rich_b1-cache_a2 vs rich_b2-cache_a1 | 69.2 m vs 67.5 m (2.4 %) |
| F2 | stag_a1-crown_ne vs stag_b1-crown_sw | 70.1 m vs 68.5 m (2.4 %) |
| F2 | stag_b1-crown_sw vs stag_b2-crown_nw | 68.5 m vs 70.1 m (2.3 %) |
| F2 | stag_a2-crown_se vs stag_b1-crown_sw | 70.1 m vs 68.5 m (2.3 %) |
| F2 | stag_a1-cache_b1 vs stag_b2-cache_a2 | 116.9 m vs 114.2 m (2.3 %) |
| F2 | rich_a1-cache_b2 vs rich_a2-cache_b1 | 69.0 m vs 67.4 m (2.3 %) |
| F2 | natural_b1-stag_a2 vs natural_b2-stag_a1 | 94.6 m vs 96.8 m (2.3 %) |
| F2 | stag_a1-cache_b1 vs stag_a2-cache_b2 | 116.9 m vs 114.2 m (2.3 %) |
| F2 | natural_a1-stag_b2 vs natural_b2-stag_a1 | 94.7 m vs 96.8 m (2.2 %) |
| F2 | natural_a2-stag_b1 vs natural_b1-stag_a2 | 96.8 m vs 94.6 m (2.2 %) |
| F2 | stag_a1-cache_b1 vs stag_b1-cache_a1 | 116.9 m vs 114.3 m (2.2 %) |
| F2 | natural_a1-stag_b2 vs natural_a2-stag_b1 | 94.7 m vs 96.8 m (2.2 %) |
| F2 | rich_a1-cache_b2 vs rich_b2-cache_a1 | 69.0 m vs 67.5 m (2.0 %) |
| F2 | stag_a1-wallow_b1 vs stag_b2-wallow_a2 | 139.3 m vs 136.5 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 87 sources) 118.90 s.
- Navmesh raster 2.24 s (260 polygons, 409600 cells of 0.25 m), spot / mirror checks 2.74 s, 3741 paths 1.13 s.
- Map Gloamspine Divide (2v2), scene res://docs/tools/world_forge/out/gloamspine_divide/preview.tscn, sim mode off; level load + navmesh bake 0.5 s (296 frames), lab 126.2 s. Spec: docs/design/new-maps.md.
