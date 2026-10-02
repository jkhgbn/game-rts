# Map Lab: Thornwater (1v1) scorecard: world_forge_thornwater

2026-10-02 19:12 · lab v1.0 · 78.57 s · scanned 65 spots

## Result: **WARN** · score **93 / 100**

0 FAIL · 2 WARN · 16 PASS · 3 info checks; findings: 0 FAIL, 81 WARN, 94 info

## Improve next
1. **Map geometry: path pairs match their mirror twins** (WARN): keep_t0-home_b vs keep_t1-home_b_twin: 5.9 m vs 6.9 m (14.4 %) -> keep_t1-home_b_twin is longer: look for an unmirrored collider on that route (heat map, M3 tiles) (find the unmirrored obstacle on the longer route) _(from F1 1047 / 1056 pairs within 2 % (0 FAIL, 9 WARN, 0 info))_
2. **Unit paths (NavigationServer): pairs match their twins** (WARN): staticbody3d-steps_b vs staticbody3d_2-steps_a: 95.3 m vs 80.0 m (16.1 %) -> units walk staticbody3d-steps_b the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 907 / 1056 pairs within 2 % (0 FAIL, 72 WARN, 77 info))_
3. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 945 polygons, main area 12263 m² (85 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 65 / 65 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 16 / 16 clean, 17 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 57 spots ok, 1.0x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 65 / 65 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 65 / 65 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | layout thornwater | LayoutLevel: positions come from the layout (no spot constants) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | **WARN** 69 | 1047 / 1056 pairs within 2 % (0 FAIL, 9 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) | find the unmirrored obstacle on the longer route |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 907 / 1056 pairs within 2 % (0 FAIL, 72 WARN, 77 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

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
| WARN | F1 | keep_t0-home_b vs keep_t1-home_b_twin | 5.9 m vs 6.9 m (14.4 %) | keep_t1-home_b_twin is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | rich_node-lairs_n_two vs rich_node_twin-lairs_n_two_twin | 10.3 m vs 11.3 m (8.9 %) | rich_node_twin-lairs_n_two_twin is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | rich_node-staticbody3d vs rich_node_twin-staticbody3d_2 | 10.9 m vs 11.9 m (8.4 %) | rich_node_twin-staticbody3d_2 is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | home_a-home_b vs home_a_twin-home_b_twin | 17.1 m vs 18.1 m (5.5 %) | home_a_twin-home_b_twin is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | rich_node-rich_hollow vs rich_node_twin-rich_hollow_twin | 20.1 m vs 21.1 m (4.7 %) | rich_node_twin-rich_hollow_twin is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | rich_node-MagpieDenNorthWest vs rich_node_twin-MagpieDenSouthEast | 24.3 m vs 25.3 m (3.9 %) | rich_node_twin-MagpieDenSouthEast is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | home_b-lairs_w_one vs home_b_twin-lairs_w_one_twin | 47.8 m vs 48.8 m (2.0 %) | home_b_twin-lairs_w_one_twin is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | home_b-LostCache0 vs home_b_twin-LostCache1 | 48.2 m vs 49.2 m (2.0 %) | home_b_twin-LostCache1 is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F1 | home_b-bridge_crown_a vs home_b_twin-bridge_crown_b | 48.5 m vs 49.5 m (2.0 %) | home_b_twin-bridge_crown_b is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F2 | staticbody3d-steps_b vs staticbody3d_2-steps_a | 95.3 m vs 80.0 m (16.1 %) | units walk staticbody3d-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-GreywaterLodgeNorthWest vs home_a_twin-GreywaterLodgeSouthEast | 88.6 m vs 104.4 m (15.1 %) | units walk home_a_twin-GreywaterLodgeSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-GreywaterLodgeNorthWest vs keep_t1-GreywaterLodgeSouthEast | 97.5 m vs 114.5 m (14.9 %) | units walk keep_t1-GreywaterLodgeSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-ford_nest vs tower_b_twin-ford_nest_twin | 17.8 m vs 15.4 m (13.8 %) | units walk tower_b-ford_nest the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-ford_b vs tower_b_twin-ford_a | 17.8 m vs 15.4 m (13.8 %) | units walk tower_b-ford_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-bridge_road_a vs home_a_twin-bridge_road_b | 87.0 m vs 100.2 m (13.2 %) | units walk home_a_twin-bridge_road_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-GreywaterLodgeSouthEast vs rich_hollow_twin-GreywaterLodgeNorthWest | 169.3 m vs 147.8 m (12.7 %) | units walk rich_hollow-GreywaterLodgeSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d-bridge_crown_a vs staticbody3d_2-bridge_crown_b | 66.8 m vs 76.0 m (12.2 %) | units walk staticbody3d_2-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-shrine vs rich_node_twin-shrine_twin | 41.7 m vs 47.2 m (11.6 %) | units walk rich_node_twin-shrine_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d-lairs_w_one_twin vs staticbody3d_2-lairs_w_one | 123.4 m vs 109.7 m (11.1 %) | units walk staticbody3d-lairs_w_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-bridge_crown_a vs rich_hollow_twin-bridge_crown_b | 79.7 m vs 88.8 m (10.2 %) | units walk rich_hollow_twin-bridge_crown_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d-RuinPeddlerShadow vs staticbody3d_2-RuinPeddlerFire | 103.7 m vs 93.3 m (10.0 %) | units walk staticbody3d-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d-lairs_w_two_twin vs staticbody3d_2-lairs_w_two | 137.3 m vs 123.6 m (10.0 %) | units walk staticbody3d-lairs_w_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d-staticbody3d_4 vs staticbody3d_2-staticbody3d_3 | 151.8 m vs 136.7 m (9.9 %) | units walk staticbody3d-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow-RuinPeddlerFire vs wallow_twin-RuinPeddlerShadow | 63.0 m vs 69.8 m (9.7 %) | units walk wallow_twin-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-staticbody3d_4 vs rich_node_twin-staticbody3d_3 | 141.2 m vs 127.7 m (9.6 %) | units walk rich_node-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-staticbody3d_4 vs rich_hollow_twin-staticbody3d_3 | 163.1 m vs 147.7 m (9.4 %) | units walk rich_hollow-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-RuinPeddlerShadow vs rich_node_twin-RuinPeddlerFire | 93.0 m vs 84.3 m (9.4 %) | units walk rich_node-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-staticbody3d_4 vs well_twin-staticbody3d_3 | 115.1 m vs 104.7 m (9.1 %) | units walk well-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-staticbody3d_4 vs MagpieDenSouthEast-staticbody3d_3 | 168.5 m vs 153.2 m (9.1 %) | units walk MagpieDenNorthWest-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-RuinPeddlerFire vs tower_b_twin-RuinPeddlerShadow | 48.9 m vs 53.7 m (9.0 %) | units walk tower_b_twin-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | TavernFire-staticbody3d_4 vs TavernShadow-staticbody3d_3 | 96.2 m vs 87.6 m (8.9 %) | units walk TavernFire-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-rich_hollow_twin vs rich_node_twin-rich_hollow | 150.8 m vs 137.5 m (8.8 %) | units walk rich_node-rich_hollow_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-MagpieDenSouthEast vs rich_node_twin-MagpieDenNorthWest | 151.3 m vs 138.0 m (8.8 %) | units walk rich_node-MagpieDenSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d-lairs_n_two_twin vs staticbody3d_2-lairs_n_two | 141.4 m vs 129.3 m (8.5 %) | units walk staticbody3d-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-crown vs MagpieDenSouthEast-crown | 92.0 m vs 84.2 m (8.5 %) | units walk MagpieDenNorthWest-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-staticbody3d_2 vs rich_node_twin-staticbody3d | 137.5 m vs 125.9 m (8.4 %) | units walk rich_node-staticbody3d_2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-staticbody3d_2 vs MagpieDenSouthEast-staticbody3d | 165.3 m vs 151.5 m (8.3 %) | units walk MagpieDenNorthWest-staticbody3d_2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-RuinPeddlerFire vs post_b_twin-RuinPeddlerShadow | 62.3 m vs 68.0 m (8.3 %) | units walk post_b_twin-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-staticbody3d_2 vs rich_hollow_twin-staticbody3d | 159.1 m vs 145.9 m (8.3 %) | units walk rich_hollow-staticbody3d_2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-rich_hollow_twin vs well_twin-rich_hollow | 124.6 m vs 114.4 m (8.2 %) | units walk well-rich_hollow_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node-lairs_n_two vs third_node_twin-lairs_n_two_twin | 118.7 m vs 109.1 m (8.1 %) | units walk third_node-lairs_n_two the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_n_two-steps_b vs lairs_n_two_twin-steps_a | 80.5 m vs 74.0 m (8.1 %) | units walk lairs_n_two-steps_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-lairs_n_two_twin vs MagpieDenSouthEast-lairs_n_two | 158.6 m vs 145.8 m (8.0 %) | units walk MagpieDenNorthWest-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_node-lairs_n_two_twin vs rich_node_twin-lairs_n_two | 130.8 m vs 120.3 m (8.0 %) | units walk rich_node-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-lairs_n_two_twin vs rich_hollow_twin-lairs_n_two | 152.3 m vs 140.3 m (7.9 %) | units walk rich_hollow-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-lairs_n_one vs home_a_twin-lairs_n_one_twin | 83.3 m vs 90.4 m (7.8 %) | units walk home_a_twin-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d-lairs_n_one_twin vs staticbody3d_2-lairs_n_one | 140.4 m vs 129.4 m (7.8 %) | units walk staticbody3d-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | staticbody3d_3-lairs_n_two_twin vs staticbody3d_4-lairs_n_two | 138.7 m vs 128.3 m (7.5 %) | units walk staticbody3d_3-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-staticbody3d_2 vs stag_twin-staticbody3d | 115.2 m vs 106.7 m (7.4 %) | units walk stag-staticbody3d_2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-steps_a vs home_a_twin-steps_b | 63.3 m vs 58.6 m (7.4 %) | units walk home_a-steps_a the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_a-shrine vs tower_a_twin-shrine_twin | 35.8 m vs 38.6 m (7.3 %) | units walk tower_a_twin-shrine_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-staticbody3d_2 vs well_twin-staticbody3d | 110.9 m vs 102.9 m (7.2 %) | units walk well-staticbody3d_2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-GreywaterLodgeNorthWest vs nat_node_twin-GreywaterLodgeSouthEast | 86.8 m vs 93.5 m (7.2 %) | units walk nat_node_twin-GreywaterLodgeSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | TavernFire-staticbody3d_2 vs TavernShadow-staticbody3d | 92.5 m vs 85.8 m (7.2 %) | units walk TavernFire-staticbody3d_2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-rich_node vs keep_t1-rich_node_twin | 85.5 m vs 92.0 m (7.1 %) | units walk keep_t1-rich_node_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | GreywaterLodgeNorthWest-staticbody3d_4 vs GreywaterLodgeSouthEast-staticbody3d_3 | 149.1 m vs 138.6 m (7.1 %) | units walk GreywaterLodgeNorthWest-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-rich_node vs home_a_twin-rich_node_twin | 76.2 m vs 81.8 m (6.8 %) | units walk home_a_twin-rich_node_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-lairs_n_two_twin vs stag_twin-lairs_n_two | 108.5 m vs 101.1 m (6.8 %) | units walk stag-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_w_two-ford_b vs lairs_w_two_twin-ford_a | 89.5 m vs 83.4 m (6.8 %) | units walk lairs_w_two-ford_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | TavernFire-GreywaterLodgeNorthWest vs TavernShadow-GreywaterLodgeSouthEast | 51.6 m vs 55.3 m (6.8 %) | units walk TavernShadow-GreywaterLodgeSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | third_node-RuinPeddlerFire vs third_node_twin-RuinPeddlerShadow | 81.8 m vs 87.7 m (6.7 %) | units walk third_node_twin-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-lairs_n_two_twin vs well_twin-lairs_n_two | 104.1 m vs 97.2 m (6.6 %) | units walk well-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-stag_twin vs rich_hollow_twin-stag | 117.6 m vs 125.9 m (6.6 %) | units walk rich_hollow_twin-stag the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-RuinPeddlerFire vs ford_nest_twin-RuinPeddlerShadow | 58.8 m vs 62.9 m (6.5 %) | units walk ford_nest_twin-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | TavernFire-lairs_n_two_twin vs TavernShadow-lairs_n_two | 85.7 m vs 80.2 m (6.4 %) | units walk TavernFire-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | rich_hollow-MagpieDenSouthEast vs rich_hollow_twin-MagpieDenNorthWest | 168.5 m vs 158.0 m (6.2 %) | units walk rich_hollow-MagpieDenSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-staticbody3d_4 vs stag_twin-staticbody3d_3 | 115.6 m vs 108.5 m (6.2 %) | units walk stag-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_n_two-crown vs lairs_n_two_twin-crown | 65.6 m vs 61.6 m (6.0 %) | units walk lairs_n_two-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | nat_node-post_b vs nat_node_twin-post_b_twin | 37.5 m vs 35.3 m (5.9 %) | units walk nat_node-post_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-ford_a vs ford_nest_twin-ford_b | 89.6 m vs 95.1 m (5.8 %) | units walk ford_nest_twin-ford_b the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | post_b-GreywaterLodgeNorthWest vs post_b_twin-GreywaterLodgeSouthEast | 121.5 m vs 114.5 m (5.8 %) | units walk post_b-GreywaterLodgeNorthWest the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | GreywaterLodgeNorthWest-staticbody3d_2 vs GreywaterLodgeSouthEast-staticbody3d | 145.2 m vs 136.8 m (5.8 %) | units walk GreywaterLodgeNorthWest-staticbody3d_2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-staticbody3d_3 vs keep_t1-staticbody3d_4 | 92.0 m vs 97.6 m (5.7 %) | units walk keep_t1-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_b-rich_hollow_twin vs tower_b_twin-rich_hollow | 66.2 m vs 70.1 m (5.6 %) | units walk tower_b_twin-rich_hollow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well-RuinPeddlerShadow vs well_twin-RuinPeddlerFire | 66.4 m vs 62.7 m (5.5 %) | units walk well-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-lairs_n_two vs home_a_twin-lairs_n_two_twin | 69.3 m vs 73.3 m (5.5 %) | units walk home_a_twin-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | home_a-staticbody3d_3 vs home_a_twin-staticbody3d_4 | 82.6 m vs 87.4 m (5.4 %) | units walk home_a_twin-staticbody3d_4 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | ford_nest-lairs_n_two_twin vs ford_nest_twin-lairs_n_two | 41.4 m vs 39.2 m (5.4 %) | units walk ford_nest-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lairs_w_two-lairs_n_one_twin vs lairs_w_two_twin-lairs_n_one | 119.0 m vs 112.9 m (5.1 %) | units walk lairs_w_two-lairs_n_one_twin the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag-MagpieDenSouthEast vs stag_twin-MagpieDenNorthWest | 125.0 m vs 118.8 m (5.0 %) | units walk stag-MagpieDenSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-lairs_n_two vs keep_t1-lairs_n_two_twin | 79.3 m vs 83.5 m (5.0 %) | units walk keep_t1-lairs_n_two_twin the long way: the engine's polygon path, not the map (see F1) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-45.0, 41.0) | (-41.9, 40.1) | keep_t1 | (-41.9, 40.1) | 0.0 |
| keep_t1 | keep | (45.0, -41.0) | (41.9, -40.1) | keep_t0 | (41.9, -40.1) | 0.0 |
| home_a | home_node | (-47.6, 32.2) | (-45.9, 30.9) | home_a_twin | (-45.9, 30.9) | 0.0 |
| home_a_twin | home_node | (47.6, -32.2) | (45.9, -30.9) | home_a | (45.9, -30.9) | 0.0 |
| home_b | home_node | (-36.1, 44.7) | (-37.9, 44.9) | home_b_twin | (-37.9, 44.9) | 0.0 |
| home_b_twin | home_node | (36.1, -44.7) | (37.9, -44.9) | home_b | (37.9, -44.9) | 0.0 |
| nat_node | expansion | (-4.5, 15.5) | (-2.4, 14.9) | nat_node_twin | (-2.4, 14.9) | 0.0 |
| nat_node_twin | expansion | (4.5, -15.5) | (2.4, -14.9) | nat_node | (2.4, -14.9) | 0.0 |
| rich_node | expansion | (-38.6, -41.7) | (-38.1, -43.4) | rich_node_twin | (-38.1, -43.4) | 0.0 |
| rich_node_twin | expansion | (38.6, 41.7) | (38.1, 43.4) | rich_node | (38.1, 43.4) | 0.0 |
| third_node | expansion | (9.1, 56.1) | (8.9, 53.9) | third_node_twin | (8.9, 53.9) | 0.0 |
| third_node_twin | expansion | (-9.1, -56.1) | (-8.9, -53.9) | third_node | (-8.9, -53.9) | 0.0 |
| tower_a | point | (-21.8, -41.5) | (-19.1, -40.9) | tower_a_twin | (-19.1, -40.9) | 0.0 |
| tower_a_twin | point | (21.8, 41.5) | (19.1, 40.9) | tower_a | (19.1, 40.9) | 0.0 |
| tower_b | point | (-4.0, 39.7) | (-6.4, 38.4) | tower_b_twin | (-6.6, 37.9) | 0.6 |
| tower_b_twin | point | (4.0, -39.7) | (6.6, -37.9) | tower_b | (6.4, -38.4) | 0.6 |
| well | point | (-26.3, -24.1) | (-24.1, -23.6) | well_twin | (-24.1, -23.6) | 0.0 |
| well_twin | point | (26.3, 24.1) | (24.1, 23.6) | well | (24.1, 23.6) | 0.0 |
| shrine | point | (-22.3, -5.4) | (-22.1, -5.4) | shrine_twin | (-22.1, -5.4) | 0.0 |
| shrine_twin | point | (22.3, 5.4) | (22.1, 5.4) | shrine | (22.1, 5.4) | 0.0 |
| rich_hollow | camp | (-52.4, -57.8) | (-52.4, -57.6) | rich_hollow_twin | (-52.4, -57.6) | 0.0 |
| rich_hollow_twin | camp | (52.4, 57.8) | (52.4, 57.6) | rich_hollow | (52.4, 57.6) | 0.0 |
| wallow | camp | (-18.3, 55.5) | (-18.1, 55.4) | wallow_twin | (-18.1, 55.4) | 0.0 |
| wallow_twin | camp | (18.3, -55.5) | (18.1, -55.4) | wallow | (18.1, -55.4) | 0.0 |
| ford_nest | camp | (7.5, 39.9) | (7.4, 39.9) | ford_nest_twin | (7.4, 39.9) | 0.0 |
| ford_nest_twin | camp | (-7.5, -39.9) | (-7.4, -39.9) | ford_nest | (-7.4, -39.9) | 0.0 |
| stag | camp | (-35.5, -14.4) | (-35.4, -14.4) | stag_twin | (-35.4, -14.4) | 0.0 |
| stag_twin | camp | (35.5, 14.4) | (35.4, 14.4) | stag | (35.4, 14.4) | 0.0 |
| TavernFire | tavern | (-14.8, -15.2) | (-11.1, -14.6) | TavernShadow | (-11.1, -14.6) | 0.0 |
| TavernShadow | tavern | (14.8, 15.2) | (11.1, 14.6) | TavernFire | (11.1, 14.6) | 0.0 |
| post_a | post | (-53.3, -0.3) | (-56.6, 1.4) | post_a_twin | (-56.6, 1.4) | 0.0 |
| post_a_twin | post | (53.3, 0.3) | (56.6, -1.4) | post_a | (56.6, -1.4) | 0.0 |
| post_b | post | (-1.3, 53.7) | (-0.4, 50.1) | post_b_twin | (-0.4, 50.1) | 0.0 |
| post_b_twin | post | (1.3, -53.7) | (0.4, -50.1) | post_b | (0.4, -50.1) | 0.0 |
| MagpieDenNorthWest | guild | (-52.1, -48.8) | (-55.6, -49.9) | MagpieDenSouthEast | (-55.6, -49.9) | 0.0 |
| MagpieDenSouthEast | guild | (52.1, 48.8) | (55.6, 49.9) | MagpieDenNorthWest | (55.6, 49.9) | 0.0 |
| GreywaterLodgeNorthWest | guild | (-43.5, -56.1) | (-39.9, -56.6) | GreywaterLodgeSouthEast | (-39.9, -56.6) | 0.0 |
| GreywaterLodgeSouthEast | guild | (43.5, 56.1) | (39.9, 56.6) | GreywaterLodgeNorthWest | (39.9, 56.6) | 0.0 |
| staticbody3d | guild | (-52.5, -46.9) | (-48.9, -44.6) | staticbody3d_2 | (-48.9, -44.6) | 0.0 |
| staticbody3d_2 | guild | (52.5, 46.9) | (48.9, 44.6) | staticbody3d | (48.9, 44.6) | 0.0 |
| staticbody3d_3 | guild | (-43.7, -55.1) | (-41.4, -51.6) | staticbody3d_4 | (-41.4, -51.6) | 0.0 |
| staticbody3d_4 | guild | (43.7, 55.1) | (41.4, 51.6) | staticbody3d_3 | (41.4, 51.6) | 0.0 |
| RuinPeddlerFire | peddler | (-20.6, -6.9) | (-22.1, -7.4) | RuinPeddlerShadow | (-22.1, -7.4) | 0.0 |
| RuinPeddlerShadow | peddler | (20.6, 6.9) | (22.1, 7.4) | RuinPeddlerFire | (22.1, 7.4) | 0.0 |
| LostCache0 | cache | (-31.7, -0.8) | (-31.6, -0.6) | LostCache1 | (-31.6, -0.6) | 0.0 |
| LostCache1 | cache | (31.7, 0.8) | (31.6, 0.6) | LostCache0 | (31.6, 0.6) | 0.0 |
| LostCache2 | cache | (-8.1, 29.4) | (-7.9, 29.4) | LostCache3 | (-7.9, 29.4) | 0.0 |
| LostCache3 | cache | (8.1, -29.4) | (7.9, -29.4) | LostCache2 | (7.9, -29.4) | 0.0 |
| lairs_w_one | lair | (-46.4, 0.1) | (-46.1, 0.1) | lairs_w_one_twin | (-46.1, 0.1) | 0.0 |
| lairs_w_one_twin | lair | (46.4, -0.1) | (46.1, -0.1) | lairs_w_one | (46.1, -0.1) | 0.0 |
| lairs_w_two | lair | (-57.0, -12.1) | (-56.9, -12.1) | lairs_w_two_twin | (-56.9, -12.1) | 0.0 |
| lairs_w_two_twin | lair | (57.0, 12.1) | (56.9, 12.1) | lairs_w_two | (56.9, 12.1) | 0.0 |
| lairs_n_one | lair | (-34.0, -51.8) | (-34.1, -51.6) | lairs_n_one_twin | (-34.1, -51.6) | 0.0 |
| lairs_n_one_twin | lair | (34.0, 51.8) | (34.1, 51.6) | lairs_n_one | (34.1, 51.6) | 0.0 |
| lairs_n_two | lair | (-46.2, -38.6) | (-46.1, -38.4) | lairs_n_two_twin | (-46.1, -38.4) | 0.0 |
| lairs_n_two_twin | lair | (46.2, 38.6) | (46.1, 38.4) | lairs_n_two | (46.1, 38.4) | 0.0 |
| bridge_road_a | crossing_bridge_road | (-13.3, -48.7) | (-13.1, -48.6) | bridge_road_b | (-13.1, -48.6) | 0.0 |
| bridge_road_b | crossing_bridge_road | (13.3, 48.7) | (13.1, 48.6) | bridge_road_a | (13.1, 48.6) | 0.0 |
| ford_a | crossing_ford | (-7.5, -39.9) | (-7.4, -39.9) | ford_b | (-7.4, -39.9) | 0.0 |
| ford_b | crossing_ford | (7.5, 39.9) | (7.4, 39.9) | ford_a | (7.4, 39.9) | 0.0 |
| bridge_crown_a | crossing_bridge_lane | (-9.4, 8.6) | (-9.4, 8.4) | bridge_crown_b | (-9.4, 8.4) | 0.0 |
| bridge_crown_b | crossing_bridge_lane | (9.4, -8.6) | (9.4, -8.4) | bridge_crown_a | (9.4, -8.4) | 0.0 |
| steps_a | crossing_steps | (-8.6, -9.4) | (-8.4, -9.4) | steps_b | (-8.4, -9.4) | 0.0 |
| steps_b | crossing_steps | (8.6, 9.4) | (8.4, 9.4) | steps_a | (8.4, 9.4) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, -0.1) | 0.4 |


## F1 map geometry: most asymmetric pairs (top 9 of 9)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | keep_t0 - home_b | 5.9 | keep_t1 - home_b_twin | 6.9 | -14.4 % |
| 2 | rich_node - lairs_n_two | 10.3 | rich_node_twin - lairs_n_two_twin | 11.3 | -8.9 % |
| 3 | rich_node - staticbody3d | 10.9 | rich_node_twin - staticbody3d_2 | 11.9 | -8.4 % |
| 4 | home_a - home_b | 17.1 | home_a_twin - home_b_twin | 18.1 | -5.5 % |
| 5 | rich_node - rich_hollow | 20.1 | rich_node_twin - rich_hollow_twin | 21.1 | -4.7 % |
| 6 | rich_node - MagpieDenNorthWest | 24.3 | rich_node_twin - MagpieDenSouthEast | 25.3 | -3.9 % |
| 7 | home_b - lairs_w_one | 47.8 | home_b_twin - lairs_w_one_twin | 48.8 | -2.0 % |
| 8 | home_b - LostCache0 | 48.2 | home_b_twin - LostCache1 | 49.2 | -2.0 % |
| 9 | home_b - bridge_crown_a | 48.5 | home_b_twin - bridge_crown_b | 49.5 | -2.0 % |


## F2 unit paths: most asymmetric pairs (top 20 of 149)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | staticbody3d - steps_b | 95.3 | staticbody3d_2 - steps_a | 80.0 | +16.1 % |
| 2 | home_a - GreywaterLodgeNorthWest | 88.6 | home_a_twin - GreywaterLodgeSouthEast | 104.4 | -15.1 % |
| 3 | keep_t0 - GreywaterLodgeNorthWest | 97.5 | keep_t1 - GreywaterLodgeSouthEast | 114.5 | -14.9 % |
| 4 | tower_b - ford_nest | 17.8 | tower_b_twin - ford_nest_twin | 15.4 | +13.8 % |
| 5 | tower_b - ford_b | 17.8 | tower_b_twin - ford_a | 15.4 | +13.8 % |
| 6 | home_a - bridge_road_a | 87.0 | home_a_twin - bridge_road_b | 100.2 | -13.2 % |
| 7 | rich_hollow - GreywaterLodgeSouthEast | 169.3 | rich_hollow_twin - GreywaterLodgeNorthWest | 147.8 | +12.7 % |
| 8 | staticbody3d - bridge_crown_a | 66.8 | staticbody3d_2 - bridge_crown_b | 76.0 | -12.2 % |
| 9 | rich_node - shrine | 41.7 | rich_node_twin - shrine_twin | 47.2 | -11.6 % |
| 10 | staticbody3d - lairs_w_one_twin | 123.4 | staticbody3d_2 - lairs_w_one | 109.7 | +11.1 % |
| 11 | rich_hollow - bridge_crown_a | 79.7 | rich_hollow_twin - bridge_crown_b | 88.8 | -10.2 % |
| 12 | staticbody3d - RuinPeddlerShadow | 103.7 | staticbody3d_2 - RuinPeddlerFire | 93.3 | +10.0 % |
| 13 | staticbody3d - lairs_w_two_twin | 137.3 | staticbody3d_2 - lairs_w_two | 123.6 | +10.0 % |
| 14 | staticbody3d - staticbody3d_4 | 151.8 | staticbody3d_2 - staticbody3d_3 | 136.7 | +9.9 % |
| 15 | wallow - RuinPeddlerFire | 63.0 | wallow_twin - RuinPeddlerShadow | 69.8 | -9.7 % |
| 16 | rich_node - staticbody3d_4 | 141.2 | rich_node_twin - staticbody3d_3 | 127.7 | +9.6 % |
| 17 | rich_hollow - staticbody3d_4 | 163.1 | rich_hollow_twin - staticbody3d_3 | 147.7 | +9.4 % |
| 18 | rich_node - RuinPeddlerShadow | 93.0 | rich_node_twin - RuinPeddlerFire | 84.3 | +9.4 % |
| 19 | well - staticbody3d_4 | 115.1 | well_twin - staticbody3d_3 | 104.7 | +9.1 % |
| 20 | MagpieDenNorthWest - staticbody3d_4 | 168.5 | MagpieDenSouthEast - staticbody3d_3 | 153.2 | +9.1 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 47.4 (nat_node) | 35.5 (tower_b) | 28.9 (wallow) | 43.1 (lairs_w_one) | 63.5 (TavernFire) | 41.6 (post_a) | 51.4 (RuinPeddlerFire) | 35.7 (LostCache2) | 58.0 (crown) | 116.0 |
| north-east | 47.4 (nat_node_twin) | 35.3 (tower_b_twin) | 28.9 (wallow_twin) | 43.1 (lairs_w_one_twin) | 63.5 (TavernShadow) | 41.6 (post_a_twin) | 51.4 (RuinPeddlerShadow) | 35.7 (LostCache3) | 58.0 (crown) | 116.0 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| home_b | home_node | 6.2 | home_b_twin | 6.2 | +0.0 % |
| home_a | home_node | 10.2 | home_a_twin | 10.2 | +0.0 % |
| wallow | camp | 28.9 | wallow_twin | 28.9 | +0.0 % |
| tower_b | point | 35.5 | tower_b_twin | 35.3 | +0.6 % |
| LostCache2 | cache | 35.7 | LostCache3 | 35.7 | +0.0 % |
| post_a | post | 41.6 | post_a_twin | 41.6 | +0.0 % |
| LostCache0 | cache | 42.0 | LostCache1 | 42.0 | +0.0 % |
| lairs_w_one | lair | 43.1 | lairs_w_one_twin | 43.1 | +0.0 % |
| post_b | post | 45.0 | post_b_twin | 45.0 | +0.0 % |
| bridge_crown_a | crossing_bridge_lane | 45.4 | bridge_crown_b | 45.4 | +0.0 % |
| nat_node | expansion | 47.4 | nat_node_twin | 47.4 | +0.0 % |
| shrine | point | 49.6 | shrine_twin | 49.6 | +0.0 % |
| RuinPeddlerFire | peddler | 51.4 | RuinPeddlerShadow | 51.4 | +0.0 % |
| ford_b | crossing_ford | 52.9 | ford_a | 52.9 | +0.0 % |
| ford_nest | camp | 52.9 | ford_nest_twin | 52.9 | +0.0 % |
| stag | camp | 54.9 | stag_twin | 54.9 | +0.0 % |
| third_node | expansion | 54.9 | third_node_twin | 54.9 | +0.0 % |
| lairs_w_two | lair | 55.4 | lairs_w_two_twin | 55.4 | +0.0 % |
| crown | crown | 58.0 | crown | 58.0 | +0.0 % |
| bridge_road_b | crossing_bridge_road | 58.2 | bridge_road_a | 58.2 | +0.0 % |
| steps_b | crossing_steps | 61.6 | steps_a | 61.6 | +0.0 % |
| steps_a | crossing_steps | 61.9 | steps_b | 61.9 | +0.0 % |
| TavernFire | tavern | 63.5 | TavernShadow | 63.5 | +0.0 % |
| tower_a_twin | point | 64.6 | tower_a | 64.6 | +0.0 % |
| well | point | 66.2 | well_twin | 66.2 | +0.0 % |
| TavernShadow | tavern | 66.7 | TavernFire | 66.7 | +0.0 % |
| bridge_crown_b | crossing_bridge_lane | 70.6 | bridge_crown_a | 70.6 | +0.0 % |
| well_twin | point | 75.8 | well | 75.8 | +0.0 % |
| shrine_twin | point | 76.4 | shrine | 76.4 | +0.0 % |
| RuinPeddlerShadow | peddler | 76.9 | RuinPeddlerFire | 76.9 | +0.0 % |
| lairs_n_two | lair | 79.3 | lairs_n_two_twin | 83.5 | -5.0 % |
| lairs_n_one_twin | lair | 79.3 | lairs_n_one | 79.3 | +0.0 % |
| nat_node_twin | expansion | 82.7 | nat_node | 82.7 | +0.0 % |
| rich_node_twin | expansion | 83.3 | rich_node | 83.3 | +0.0 % |
| tower_a | point | 84.2 | tower_a_twin | 84.2 | +0.0 % |
| rich_node | expansion | 85.5 | rich_node_twin | 92.0 | -7.1 % |
| staticbody3d | guild | 85.9 | staticbody3d_2 | 89.0 | -3.4 % |
| staticbody3d_4 | guild | 86.5 | staticbody3d_3 | 86.5 | +0.0 % |
| LostCache1 | cache | 86.6 | LostCache0 | 86.6 | +0.0 % |
| ford_a | crossing_ford | 87.8 | ford_b | 87.8 | +0.0 % |
| ford_nest_twin | camp | 87.8 | ford_nest | 87.8 | +0.0 % |
| LostCache3 | cache | 89.5 | LostCache2 | 89.5 | +0.0 % |
| stag_twin | camp | 90.4 | stag | 90.3 | +0.0 % |
| GreywaterLodgeSouthEast | guild | 90.5 | GreywaterLodgeNorthWest | 90.5 | +0.0 % |
| staticbody3d_3 | guild | 92.0 | staticbody3d_4 | 97.6 | -5.7 % |
| lairs_n_one | lair | 92.1 | lairs_n_one_twin | 92.1 | +0.0 % |
| lairs_n_two_twin | lair | 93.0 | lairs_n_two | 92.1 | +1.0 % |
| bridge_road_a | crossing_bridge_road | 93.5 | bridge_road_b | 94.8 | -1.4 % |
| MagpieDenNorthWest | guild | 93.5 | MagpieDenSouthEast | 93.5 | +0.0 % |
| staticbody3d_2 | guild | 93.9 | staticbody3d | 96.1 | -2.2 % |
| GreywaterLodgeNorthWest | guild | 97.5 | GreywaterLodgeSouthEast | 114.5 | -14.9 % |
| tower_b_twin | point | 98.0 | tower_b | 98.5 | -0.6 % |
| rich_hollow_twin | camp | 100.3 | rich_hollow | 100.3 | +0.0 % |
| lairs_w_one_twin | lair | 100.8 | lairs_w_one | 101.1 | -0.3 % |
| rich_hollow | camp | 101.9 | rich_hollow_twin | 101.9 | +0.0 % |
| post_b_twin | post | 102.4 | post_b | 100.6 | +1.8 % |
| third_node_twin | expansion | 103.6 | third_node | 101.8 | +1.7 % |
| MagpieDenSouthEast | guild | 108.2 | MagpieDenNorthWest | 109.2 | -0.9 % |
| lairs_w_two_twin | lair | 110.1 | lairs_w_two | 109.6 | +0.5 % |
| home_a_twin | home_node | 113.0 | home_a | 113.0 | +0.0 % |
| keep_t1 | keep | 116.0 | keep_t0 | 116.0 | +0.0 % |
| wallow_twin | camp | 116.7 | wallow | 116.7 | +0.0 % |
| home_b_twin | home_node | 117.0 | home_b | 117.0 | +0.0 % |
| post_a_twin | post | 120.3 | post_a | 120.3 | +0.0 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| south-west | enemy keep (keep_t1) | 116.0 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| south-west | nearest expansion (nat_node) | 47.4 | 0.0 | 0:10 | 0:09 | 0:06 | 0:12 |
| south-west | nearest point (tower_b) | 35.5 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| south-west | nearest camp (wallow) | 28.9 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| south-west | crown (crown) | 58.0 | 0.0 | 0:13 | 0:12 | 0:08 | 0:14 |
| north-east | enemy keep (keep_t0) | 116.0 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| north-east | nearest expansion (nat_node_twin) | 47.4 | 0.0 | 0:10 | 0:09 | 0:06 | 0:12 |
| north-east | nearest point (tower_b_twin) | 35.3 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| north-east | nearest camp (wallow_twin) | 28.9 | 0.0 | 0:06 | 0:06 | 0:04 | 0:07 |
| north-east | crown (crown) | 58.0 | 0.0 | 0:13 | 0:12 | 0:08 | 0:14 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_a | bridge_road | 6.0 | 5.0 | 6.0 | bridge_road_b | 5.0 |
| bridge_road_b | bridge_road | 6.0 | 5.0 | 6.0 | bridge_road_a | 5.0 |
| ford_a | ford | 7.0 | 5.9 | 6.9 | ford_b | 6.0 |
| ford_b | ford | 7.0 | 6.0 | 7.0 | ford_a | 5.9 |
| bridge_crown_a | bridge_lane | 8.0 | 6.8 | 7.8 | bridge_crown_b | 6.8 |
| bridge_crown_b | bridge_lane | 8.0 | 6.8 | 7.8 | bridge_crown_a | 6.8 |
| steps_a | steps | 6.0 | 4.9 | 5.9 | steps_b | 4.9 |
| steps_b | steps | 6.0 | 4.9 | 5.9 | steps_a | 4.9 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 58.0 | 6.9 | (-10.0, 9.8) | - |
| keep_t0 -> keep_t1 | 116.0 | 6.8 | (-8.7, 8.3) | - |
| keep_t0 -> nat_node | 47.4 | 10.5 | (-5.0, 18.0) | - |
| keep_t1 -> crown | 58.0 | 6.9 | (10.2, -9.6) | - |
| keep_t1 -> nat_node_twin | 47.4 | 10.5 | (5.0, -18.0) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| south-west | keep_enemy | 116.00-150.00 | 115.99 | 0.0 % |
| south-west | natural | 38.00-58.00 | 47.38 | - |
| south-west | rich | 65.00-95.00 | 85.50 | - |
| south-west | crown | 50.00-72.00 | 57.99 | - |
| north-east | keep_enemy | 116.00-150.00 | 115.99 | 0.0 % |
| north-east | natural | 38.00-58.00 | 47.38 | - |
| north-east | rich | 65.00-95.00 | 92.00 | - |
| north-east | crown | 50.00-72.00 | 57.99 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| south-west | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |
| north-east | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| south-west | 7 | 2 | 11 | 29 |
| north-east | 6 | 3 | 11 | 29 |


## Hottest metres (every spot-pair shortest path, 2080 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-6.5, -9.5) | 212 | 10 % |
| 2 | (6.5, 9.5) | 210 | 10 % |
| 3 | (-7.5, -39.5) | 188 | 9 % |
| 4 | (7.5, 39.5) | 179 | 9 % |
| 5 | (-11.5, -18.5) | 159 | 8 % |
| 6 | (11.5, 18.5) | 140 | 7 % |
| 7 | (-0.5, -1.5) | 126 | 6 % |
| 8 | (20.5, -6.5) | 125 | 6 % |
| 9 | (-5.5, 8.5) | 123 | 6 % |
| 10 | (6.5, -42.5) | 122 | 6 % |


## Info findings (94)
| Check | Where | What |
|---|---|---|
| N3 | island 2 at (-43.6, -55.6) | 15.9 m² inside the footprint of staticbody3d_3 (unreachable by design) |
| N3 | island 5 at (1.3, -53.7) | 21.3 m² inside the footprint of post_b_twin (unreachable by design) |
| N3 | island 7 at (-49.9, -49.9) | 0.8 m² inside the footprint of staticbody3d (unreachable by design) |
| N3 | island 8 at (-52.2, -47.8) | 10.6 m² inside the footprint of staticbody3d (unreachable by design) |
| N3 | island 9 at (-53.0, -44.7) | 1.8 m² inside the footprint of staticbody3d (unreachable by design) |
| N3 | island 13 at (45.1, -40.9) | 14.1 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 22 at (-14.9, -15.1) | 22.6 m² inside the footprint of TavernFire (unreachable by design) |
| N3 | island 30 at (-53.3, -0.3) | 20.9 m² inside the footprint of post_a (unreachable by design) |
| N3 | island 32 at (53.3, 0.3) | 20.9 m² inside the footprint of post_a_twin (unreachable by design) |
| N3 | island 41 at (14.9, 15.1) | 22.6 m² inside the footprint of TavernShadow (unreachable by design) |
| N3 | island 50 at (-44.9, 41.1) | 14.1 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 55 at (52.9, 44.7) | 1.8 m² inside the footprint of staticbody3d_2 (unreachable by design) |
| N3 | island 56 at (52.2, 47.8) | 10.6 m² inside the footprint of staticbody3d_2 (unreachable by design) |
| N3 | island 57 at (49.9, 49.9) | 0.8 m² inside the footprint of staticbody3d_2 (unreachable by design) |
| N3 | island 59 at (-1.3, 53.7) | 21.3 m² inside the footprint of post_b (unreachable by design) |
| N3 | island 61 at (43.6, 55.6) | 15.9 m² inside the footprint of staticbody3d_4 (unreachable by design) |
| N3 | raised islands | 46 islands on top of colliders (223 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | LostCache0-steps_a vs LostCache1-steps_b | 26.6 m vs 25.1 m (5.7 %) |
| F2 | stag-post_a vs stag_twin-post_a_twin | 31.2 m vs 29.5 m (5.4 %) |
| F2 | TavernFire-bridge_crown_a vs TavernShadow-bridge_crown_b | 25.4 m vs 24.1 m (5.1 %) |
| F2 | nat_node-ford_nest vs nat_node_twin-ford_nest_twin | 31.0 m vs 29.5 m (5.1 %) |
| F2 | nat_node-ford_b vs nat_node_twin-ford_a | 31.0 m vs 29.5 m (5.1 %) |
| F2 | stag-RuinPeddlerShadow vs stag_twin-RuinPeddlerFire | 69.9 m vs 66.4 m (4.9 %) |
| F2 | stag-steps_b vs stag_twin-steps_a | 54.5 m vs 51.9 m (4.8 %) |
| F2 | nat_node-rich_node vs nat_node_twin-rich_node_twin | 74.9 m vs 78.6 m (4.8 %) |
| F2 | well-MagpieDenSouthEast vs well_twin-MagpieDenNorthWest | 120.7 m vs 114.9 m (4.8 %) |
| F2 | lairs_w_two-bridge_road_b vs lairs_w_two_twin-bridge_road_a | 99.4 m vs 94.8 m (4.7 %) |
| F2 | shrine-lairs_w_two_twin vs shrine_twin-lairs_w_two | 89.3 m vs 85.1 m (4.7 %) |
| F2 | stag-ford_a vs stag_twin-ford_b | 40.4 m vs 38.6 m (4.4 %) |
| F2 | TavernFire-MagpieDenSouthEast vs TavernShadow-MagpieDenNorthWest | 102.2 m vs 97.9 m (4.3 %) |
| F2 | post_a-MagpieDenSouthEast vs post_a_twin-MagpieDenNorthWest | 137.6 m vs 131.8 m (4.3 %) |
| F2 | bridge_road_a-steps_a vs bridge_road_b-steps_b | 42.7 m vs 40.9 m (4.2 %) |
| F2 | home_a-staticbody3d vs home_a_twin-staticbody3d_2 | 75.6 m vs 78.8 m (4.1 %) |
| F2 | TavernFire-GreywaterLodgeSouthEast vs TavernShadow-GreywaterLodgeNorthWest | 91.5 m vs 87.7 m (4.1 %) |
| F2 | ford_nest-LostCache3 vs ford_nest_twin-LostCache2 | 73.4 m vs 76.5 m (4.1 %) |
| F2 | lairs_w_one-bridge_road_a vs lairs_w_one_twin-bridge_road_b | 61.3 m vs 58.9 m (3.9 %) |
| F2 | post_a-bridge_crown_a vs post_a_twin-bridge_crown_b | 53.0 m vs 55.2 m (3.9 %) |
| F2 | nat_node-bridge_road_b vs nat_node_twin-bridge_road_a | 40.7 m vs 39.1 m (3.9 %) |
| F2 | bridge_road_a-ford_b vs bridge_road_b-ford_a | 101.6 m vs 97.7 m (3.8 %) |
| F2 | nat_node-third_node vs nat_node_twin-third_node_twin | 42.3 m vs 40.7 m (3.7 %) |
| F2 | shrine-post_b_twin vs shrine_twin-post_b | 53.7 m vs 51.8 m (3.7 %) |
| F2 | nat_node-tower_a_twin vs nat_node_twin-tower_a | 42.8 m vs 41.2 m (3.7 %) |
| F2 | post_b-lairs_w_two_twin vs post_b_twin-lairs_w_two | 71.7 m vs 69.1 m (3.7 %) |
| F2 | post_b-LostCache3 vs post_b_twin-LostCache2 | 86.2 m vs 89.3 m (3.5 %) |
| F2 | well-GreywaterLodgeSouthEast vs well_twin-GreywaterLodgeNorthWest | 108.5 m vs 104.8 m (3.5 %) |
| F2 | third_node-LostCache3 vs third_node_twin-LostCache2 | 87.7 m vs 90.8 m (3.4 %) |
| F2 | LostCache0-bridge_crown_b vs LostCache1-bridge_crown_a | 44.4 m vs 42.9 m (3.4 %) |
| F2 | keep_t0-staticbody3d vs keep_t1-staticbody3d_2 | 85.9 m vs 89.0 m (3.4 %) |
| F2 | nat_node-lairs_n_one vs nat_node_twin-lairs_n_one_twin | 79.9 m vs 82.7 m (3.4 %) |
| F2 | third_node-tower_b_twin vs third_node_twin-tower_b | 96.2 m vs 99.5 m (3.4 %) |
| F2 | shrine-wallow_twin vs shrine_twin-wallow | 71.3 m vs 68.9 m (3.4 %) |
| F2 | stag-TavernShadow vs stag_twin-TavernFire | 59.7 m vs 57.7 m (3.4 %) |
| F2 | third_node-shrine_twin vs third_node_twin-shrine | 54.7 m vs 52.8 m (3.3 %) |
| F2 | bridge_road_a-crown vs bridge_road_b-crown | 54.6 m vs 52.8 m (3.3 %) |
| F2 | well-post_a vs well_twin-post_a_twin | 45.9 m vs 44.4 m (3.3 %) |
| F2 | tower_b-post_b_twin vs tower_b_twin-post_b | 98.4 m vs 95.2 m (3.3 %) |
| F2 | post_a-crown vs post_a_twin-crown | 63.9 m vs 66.0 m (3.2 %) |
| F2 | MagpieDenNorthWest-RuinPeddlerShadow vs MagpieDenSouthEast-RuinPeddlerFire | 115.0 m vs 111.3 m (3.2 %) |
| F2 | third_node-tower_b vs third_node_twin-tower_b_twin | 23.0 m vs 23.7 m (3.2 %) |
| F2 | tower_a-GreywaterLodgeSouthEast vs tower_a_twin-GreywaterLodgeNorthWest | 118.9 m vs 115.2 m (3.1 %) |
| F2 | tower_b-bridge_road_b vs tower_b_twin-bridge_road_a | 24.3 m vs 25.1 m (3.1 %) |
| F2 | ford_nest-post_a_twin vs ford_nest_twin-post_a | 67.1 m vs 69.3 m (3.1 %) |
| F2 | tower_a-staticbody3d_4 vs tower_a_twin-staticbody3d_3 | 118.7 m vs 115.1 m (3.1 %) |
| F2 | MagpieDenNorthWest-steps_b vs MagpieDenSouthEast-steps_a | 99.7 m vs 96.6 m (3.0 %) |
| F2 | nat_node-third_node_twin vs nat_node_twin-third_node | 85.1 m vs 82.5 m (3.0 %) |
| F2 | shrine-staticbody3d_4 vs shrine_twin-staticbody3d_3 | 99.6 m vs 96.7 m (3.0 %) |
| F2 | MagpieDenNorthWest-LostCache0 vs MagpieDenSouthEast-LostCache1 | 58.0 m vs 56.3 m (3.0 %) |
| F2 | post_a-steps_b vs post_a_twin-steps_a | 70.7 m vs 72.9 m (2.9 %) |
| F2 | bridge_road_a-bridge_crown_a vs bridge_road_b-bridge_crown_b | 61.9 m vs 60.2 m (2.9 %) |
| F2 | rich_node-GreywaterLodgeSouthEast vs rich_node_twin-GreywaterLodgeNorthWest | 131.6 m vs 127.8 m (2.8 %) |
| F2 | well-bridge_crown_a vs well_twin-bridge_crown_b | 37.7 m vs 36.7 m (2.8 %) |
| F2 | wallow-post_b_twin vs wallow_twin-post_b | 114.6 m vs 111.4 m (2.8 %) |
| F2 | shrine-rich_hollow_twin vs shrine_twin-rich_hollow | 109.4 m vs 106.4 m (2.7 %) |
| F2 | tower_a-rich_hollow_twin vs tower_a_twin-rich_hollow | 128.3 m vs 124.8 m (2.7 %) |
| F2 | nat_node-rich_node_twin vs nat_node_twin-rich_node | 62.7 m vs 61.0 m (2.7 %) |
| F2 | bridge_road_a-steps_b vs bridge_road_b-steps_a | 67.3 m vs 65.5 m (2.7 %) |
| F2 | staticbody3d-bridge_crown_b vs staticbody3d_2-bridge_crown_a | 73.9 m vs 72.0 m (2.6 %) |
| F2 | nat_node-lairs_n_one_twin vs nat_node_twin-lairs_n_one | 60.5 m vs 58.9 m (2.6 %) |
| F2 | tower_b-post_a_twin vs tower_b_twin-post_a | 84.7 m vs 86.9 m (2.6 %) |
| F2 | ford_nest-post_b_twin vs ford_nest_twin-post_b | 96.2 m vs 98.7 m (2.5 %) |
| F2 | TavernFire-post_b_twin vs TavernShadow-post_b | 39.7 m vs 40.7 m (2.5 %) |
| F2 | post_a-RuinPeddlerShadow vs post_a_twin-RuinPeddlerFire | 86.1 m vs 88.2 m (2.4 %) |
| F2 | LostCache0-LostCache3 vs LostCache1-LostCache2 | 63.5 m vs 61.9 m (2.4 %) |
| F2 | home_b-staticbody3d_2 vs home_b_twin-staticbody3d | 87.9 m vs 90.0 m (2.4 %) |
| F2 | nat_node-staticbody3d_4 vs nat_node_twin-staticbody3d_3 | 67.2 m vs 65.6 m (2.4 %) |
| F2 | home_a-lairs_w_two_twin vs home_a_twin-lairs_w_two | 108.2 m vs 110.8 m (2.3 %) |
| F2 | nat_node-lairs_n_two_twin vs nat_node_twin-lairs_n_two | 70.0 m vs 68.5 m (2.2 %) |
| F2 | keep_t0-staticbody3d_2 vs keep_t1-staticbody3d | 93.9 m vs 96.1 m (2.2 %) |
| F2 | third_node-post_b_twin vs third_node_twin-post_b | 110.5 m vs 113.0 m (2.2 %) |
| F2 | post_a-lairs_w_one_twin vs post_a_twin-lairs_w_one | 110.0 m vs 112.4 m (2.2 %) |
| F2 | nat_node-GreywaterLodgeSouthEast vs nat_node_twin-GreywaterLodgeNorthWest | 73.8 m vs 72.3 m (2.1 %) |
| F2 | nat_node-staticbody3d_2 vs nat_node_twin-staticbody3d | 74.0 m vs 72.5 m (2.1 %) |
| F2 | shrine-staticbody3d_2 vs shrine_twin-staticbody3d | 96.8 m vs 94.9 m (2.0 %) |
| F2 | nat_node-rich_hollow_twin vs nat_node_twin-rich_hollow | 80.5 m vs 78.9 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 65 sources) 45.56 s.
- Map Lab v2 (map-production.md 2.5): layout thornwater, 2 seats, rules tempo standard, 0 fixable findings.
- Navmesh raster 1.26 s (945 polygons, 230400 cells of 0.25 m), spot / mirror checks 0.51 s, 2080 paths 0.75 s.
- Map Thornwater (1v1), scene res://docs/tools/world_forge/out/thornwater/preview.tscn, sim mode on; level load + navmesh bake 29.8 s (12 frames), lab 48.8 s. Spec: docs/design/map-production.md.
