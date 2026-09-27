# Map Lab: Crown Hollow (1v1) scorecard: world_forge_crown_hollow

2026-09-27 07:48 · lab v1.0 · 39.55 s · scanned 59 spots

## Result: **WARN** · score **98 / 100**

0 FAIL · 1 WARN · 11 PASS · 1 info checks; findings: 0 FAIL, 16 WARN, 14 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): camp_wallow_s-bridge_crown_e vs camp_wallow_n-bridge_crown_w: 85.3 m vs 71.6 m (16.0 %) -> units walk camp_wallow_s-bridge_crown_e the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 843 / 870 pairs within 2 % (0 FAIL, 16 WARN, 11 info))_
2. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_
3. **Combat heat from bot games** (IDEA): v2: feed Bot Lab / Replay Lab unit deaths into the heat map _(from lab idea)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 226 polygons, main area 13540 m² (94 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 59 / 59 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 2 / 2 clean, 3 info | ground-level components other than the main one < 2 m² |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 59 / 59 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 59 / 59 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 870 / 870 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 843 / 870 pairs within 2 % (0 FAIL, 16 WARN, 11 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | PASS 100 | 10 / 10 clean | per kind, the seats' nearest path lengths differ <= 2 % |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 8 / 8 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 5 / 5 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (480 x 480 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | camp_wallow_s-bridge_crown_e vs camp_wallow_n-bridge_crown_w | 85.3 m vs 71.6 m (16.0 %) | units walk camp_wallow_s-bridge_crown_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross-ford_n vs saltgate-ford_s | 107.0 m vs 90.0 m (15.9 %) | units walk millstone_cross-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross-bridge_road_n vs saltgate-bridge_road_s | 120.1 m vs 104.3 m (13.2 %) | units walk millstone_cross-bridge_road_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_wallow_s-saltgate vs camp_wallow_n-millstone_cross | 129.8 m vs 113.3 m (12.7 %) | units walk camp_wallow_s-saltgate the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | RuinPeddlerFire-lair_heath_e vs RuinPeddlerShadow-lair_heath_w | 85.4 m vs 94.1 m (9.3 %) | units walk RuinPeddlerShadow-lair_heath_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_nest_n-lair_hollow_e vs camp_nest_s-lair_hollow_w | 93.5 m vs 102.6 m (8.9 %) | units walk camp_nest_s-lair_hollow_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_s-LostCache3 vs tower_n-LostCache1 | 77.3 m vs 70.5 m (8.7 %) | units walk tower_s-LostCache3 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-bridge_crown_e vs tower_se-bridge_crown_w | 47.7 m vs 51.5 m (7.4 %) | units walk tower_se-bridge_crown_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross-GreywaterLodgeNorthWest vs saltgate-GreywaterLodgeSouthEast | 124.6 m vs 116.4 m (6.6 %) | units walk millstone_cross-GreywaterLodgeNorthWest the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_nest_n-MagpieDenSouthEast vs camp_nest_s-MagpieDenNorthWest | 101.2 m vs 108.1 m (6.4 %) | units walk camp_nest_s-MagpieDenNorthWest the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_b-camp_wallow_n vs node_shadow_b-camp_wallow_s | 116.2 m vs 124.0 m (6.3 %) | units walk node_shadow_b-camp_wallow_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-lair_crag_e vs tower_se-lair_crag_w | 97.2 m vs 103.5 m (6.1 %) | units walk tower_se-lair_crag_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | LostCache1-lair_heath_e vs LostCache3-lair_heath_w | 78.8 m vs 83.3 m (5.4 %) | units walk LostCache3-lair_heath_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lair_crag_w-lair_heath_e vs lair_crag_e-lair_heath_w | 115.0 m vs 121.4 m (5.3 %) | units walk lair_crag_e-lair_heath_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lair_den_w-bridge_crown_e vs lair_den_e-bridge_crown_w | 60.8 m vs 64.1 m (5.1 %) | units walk lair_den_e-bridge_crown_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_nest_n-RuinPeddlerShadow vs camp_nest_s-RuinPeddlerFire | 64.9 m vs 68.4 m (5.0 %) | units walk camp_nest_s-RuinPeddlerFire the long way: the engine's polygon path, not the map (see F1) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-43.0, 43.0) | (-42.1, 39.4) | keep_t1 | (-41.6, 38.9) | 0.7 |
| keep_t1 | keep | (43.0, -43.0) | (41.6, -38.9) | keep_t0 | (42.1, -39.4) | 0.7 |
| node_fire_a | home_node | (-46.0, 34.0) | (-45.9, 33.9) | node_shadow_a | (-45.9, 33.9) | 0.0 |
| node_shadow_a | home_node | (46.0, -34.0) | (45.9, -33.9) | node_fire_a | (45.9, -33.9) | 0.0 |
| node_fire_b | home_node | (-34.0, 46.0) | (-33.9, 45.9) | node_shadow_b | (-33.9, 45.9) | 0.0 |
| node_shadow_b | home_node | (34.0, -46.0) | (33.9, -45.9) | node_fire_b | (33.9, -45.9) | 0.0 |
| node_fire_mid | expansion | (-16.0, 6.0) | (-15.9, 5.9) | node_shadow_mid | (-15.9, 5.9) | 0.0 |
| node_shadow_mid | expansion | (16.0, -6.0) | (15.9, -5.9) | node_fire_mid | (15.9, -5.9) | 0.0 |
| node_fire_rich | expansion | (-40.0, -40.0) | (-39.9, -39.9) | node_shadow_rich | (-39.9, -39.9) | 0.0 |
| node_shadow_rich | expansion | (40.0, 40.0) | (39.9, 39.9) | node_fire_rich | (39.9, 39.9) | 0.0 |
| shrine_w | point | (-22.0, -6.0) | (-21.9, -5.9) | shrine_e | (-21.9, -5.9) | 0.0 |
| shrine_e | point | (22.0, 6.0) | (21.9, 5.9) | shrine_w | (21.9, 5.9) | 0.0 |
| tower_nw | point | (-24.0, -41.0) | (-23.9, -40.9) | tower_se | (-23.9, -40.9) | 0.0 |
| tower_se | point | (24.0, 41.0) | (23.9, 40.9) | tower_nw | (23.9, 40.9) | 0.0 |
| tower_s | point | (-6.0, 40.0) | (-5.9, 39.9) | tower_n | (-5.9, 39.9) | 0.0 |
| tower_n | point | (6.0, -40.0) | (5.9, -39.9) | tower_s | (5.9, -39.9) | 0.0 |
| well_w | point | (-30.0, -24.0) | (-29.9, -23.9) | well_e | (-29.9, -23.9) | 0.0 |
| well_e | point | (30.0, 24.0) | (29.9, 23.9) | well_w | (29.9, 23.9) | 0.0 |
| camp_hollow_nw | camp | (-55.0, -55.0) | (-54.9, -54.9) | camp_hollow_se | (-54.9, -54.9) | 0.0 |
| camp_hollow_se | camp | (55.0, 55.0) | (54.9, 54.9) | camp_hollow_nw | (54.9, 54.9) | 0.0 |
| camp_nest_n | camp | (-8.5, -34.0) | (-8.4, -33.9) | camp_nest_s | (-8.4, -33.9) | 0.0 |
| camp_nest_s | camp | (8.5, 34.0) | (8.4, 33.9) | camp_nest_n | (8.4, 33.9) | 0.0 |
| camp_stag_w | camp | (-37.0, -10.0) | (-36.9, -9.9) | camp_stag_e | (-36.9, -9.9) | 0.0 |
| camp_stag_e | camp | (37.0, 10.0) | (36.9, 9.9) | camp_stag_w | (36.9, 9.9) | 0.0 |
| camp_wallow_s | camp | (-14.0, 57.0) | (-13.9, 56.9) | camp_wallow_n | (-13.9, 56.9) | 0.0 |
| camp_wallow_n | camp | (14.0, -57.0) | (13.9, -56.9) | camp_wallow_s | (13.9, -56.9) | 0.0 |
| TavernFire | tavern | (-15.0, -15.0) | (-14.9, -14.9) | TavernShadow | (-14.9, -14.9) | 0.0 |
| TavernShadow | tavern | (15.0, 15.0) | (14.9, 14.9) | TavernFire | (14.9, 14.9) | 0.0 |
| heron_ford | post | (-53.0, 1.0) | (-52.9, 0.9) | lantern_wharf | (-52.9, 0.9) | 0.0 |
| lantern_wharf | post | (53.0, -1.0) | (52.9, -0.9) | heron_ford | (52.9, -0.9) | 0.0 |
| millstone_cross | post | (-1.0, 53.0) | (-0.9, 52.9) | saltgate | (-0.9, 52.9) | 0.0 |
| saltgate | post | (1.0, -53.0) | (0.9, -52.9) | millstone_cross | (0.9, -52.9) | 0.0 |
| GreywaterLodgeNorthWest | guild | (-45.0, -55.0) | (-44.9, -54.9) | GreywaterLodgeSouthEast | (-44.9, -54.9) | 0.0 |
| GreywaterLodgeSouthEast | guild | (45.0, 55.0) | (44.9, 54.9) | GreywaterLodgeNorthWest | (44.9, 54.9) | 0.0 |
| MagpieDenNorthWest | guild | (-55.0, -45.0) | (-54.9, -44.9) | MagpieDenSouthEast | (-54.9, -44.9) | 0.0 |
| MagpieDenSouthEast | guild | (55.0, 45.0) | (54.9, 44.9) | MagpieDenNorthWest | (54.9, 44.9) | 0.0 |
| RuinPeddlerFire | peddler | (-22.0, -22.0) | (-21.9, -21.9) | RuinPeddlerShadow | (-21.9, -21.9) | 0.0 |
| RuinPeddlerShadow | peddler | (22.0, 22.0) | (21.9, 21.9) | RuinPeddlerFire | (21.9, 21.9) | 0.0 |
| LostCache0 | cache | (-30.0, 0.0) | (-29.9, 0.1) | LostCache2 | (-29.9, 0.1) | 0.0 |
| LostCache2 | cache | (30.0, 0.0) | (29.9, -0.1) | LostCache0 | (29.9, -0.1) | 0.0 |
| LostCache1 | cache | (-6.0, 27.0) | (-5.9, 26.9) | LostCache3 | (-5.9, 26.9) | 0.0 |
| LostCache3 | cache | (6.0, -27.0) | (5.9, -26.9) | LostCache1 | (5.9, -26.9) | 0.0 |
| lair_crag_w | lair | (-53.0, -18.0) | (-52.9, -17.9) | lair_crag_e | (-52.9, -17.9) | 0.0 |
| lair_crag_e | lair | (53.0, 18.0) | (52.9, 17.9) | lair_crag_w | (52.9, 17.9) | 0.0 |
| lair_den_w | lair | (-26.0, -54.0) | (-25.9, -53.9) | lair_den_e | (-25.9, -53.9) | 0.0 |
| lair_den_e | lair | (26.0, 54.0) | (25.9, 53.9) | lair_den_w | (25.9, 53.9) | 0.0 |
| lair_heath_w | lair | (-53.0, 13.0) | (-52.9, 12.9) | lair_heath_e | (-52.9, 12.9) | 0.0 |
| lair_heath_e | lair | (53.0, -13.0) | (52.9, -12.9) | lair_heath_w | (52.9, -12.9) | 0.0 |
| lair_hollow_w | lair | (-56.0, -34.0) | (-55.9, -33.9) | lair_hollow_e | (-55.9, -33.9) | 0.0 |
| lair_hollow_e | lair | (56.0, 34.0) | (55.9, 33.9) | lair_hollow_w | (55.9, 33.9) | 0.0 |
| bridge_road_n | crossing_bridge_road | (-12.0, -48.7) | (-11.9, -48.6) | bridge_road_s | (-11.9, -48.6) | 0.0 |
| bridge_road_s | crossing_bridge_road | (12.0, 48.7) | (11.9, 48.6) | bridge_road_n | (11.9, 48.6) | 0.0 |
| ford_n | crossing_ford | (-8.5, -34.0) | (-8.4, -33.9) | ford_s | (-8.4, -33.9) | 0.0 |
| ford_s | crossing_ford | (8.5, 34.0) | (8.4, 33.9) | ford_n | (8.4, 33.9) | 0.0 |
| bridge_crown_w | crossing_bridge_lane | (-9.0, 9.0) | (-8.9, 8.9) | bridge_crown_e | (-8.9, 8.9) | 0.0 |
| bridge_crown_e | crossing_bridge_lane | (9.0, -9.0) | (8.9, -8.9) | bridge_crown_w | (8.9, -8.9) | 0.0 |
| steps_nw | crossing_steps | (-9.0, -9.0) | (-8.9, -8.9) | steps_se | (-8.9, -8.9) | 0.0 |
| steps_se | crossing_steps | (9.0, 9.0) | (8.9, 8.9) | steps_nw | (8.9, 8.9) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, -0.1) | 0.4 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F2 unit paths: most asymmetric pairs (top 20 of 27)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | camp_wallow_s - bridge_crown_e | 85.3 | camp_wallow_n - bridge_crown_w | 71.6 | +16.0 % |
| 2 | millstone_cross - ford_n | 107.0 | saltgate - ford_s | 90.0 | +15.9 % |
| 3 | millstone_cross - bridge_road_n | 120.1 | saltgate - bridge_road_s | 104.3 | +13.2 % |
| 4 | camp_wallow_s - saltgate | 129.8 | camp_wallow_n - millstone_cross | 113.3 | +12.7 % |
| 5 | RuinPeddlerFire - lair_heath_e | 85.4 | RuinPeddlerShadow - lair_heath_w | 94.1 | -9.3 % |
| 6 | camp_nest_n - lair_hollow_e | 93.5 | camp_nest_s - lair_hollow_w | 102.6 | -8.9 % |
| 7 | tower_s - LostCache3 | 77.3 | tower_n - LostCache1 | 70.5 | +8.7 % |
| 8 | tower_nw - bridge_crown_e | 47.7 | tower_se - bridge_crown_w | 51.5 | -7.4 % |
| 9 | millstone_cross - GreywaterLodgeNorthWest | 124.6 | saltgate - GreywaterLodgeSouthEast | 116.4 | +6.6 % |
| 10 | camp_nest_n - MagpieDenSouthEast | 101.2 | camp_nest_s - MagpieDenNorthWest | 108.1 | -6.4 % |
| 11 | node_fire_b - camp_wallow_n | 116.2 | node_shadow_b - camp_wallow_s | 124.0 | -6.3 % |
| 12 | tower_nw - lair_crag_e | 97.2 | tower_se - lair_crag_w | 103.5 | -6.1 % |
| 13 | TavernFire - bridge_crown_w | 27.2 | TavernShadow - bridge_crown_e | 25.6 | +5.9 % |
| 14 | LostCache1 - lair_heath_e | 78.8 | LostCache3 - lair_heath_w | 83.3 | -5.4 % |
| 15 | lair_crag_w - lair_heath_e | 115.0 | lair_crag_e - lair_heath_w | 121.4 | -5.3 % |
| 16 | lair_den_w - bridge_crown_e | 60.8 | lair_den_e - bridge_crown_w | 64.1 | -5.1 % |
| 17 | camp_nest_n - RuinPeddlerShadow | 64.9 | camp_nest_s - RuinPeddlerFire | 68.4 | -5.0 % |
| 18 | millstone_cross - MagpieDenNorthWest | 117.1 | saltgate - MagpieDenSouthEast | 111.7 | +4.6 % |
| 19 | node_fire_rich - tower_n | 46.5 | node_shadow_rich - tower_s | 48.4 | -4.0 % |
| 20 | millstone_cross - lair_hollow_w | 107.0 | saltgate - lair_hollow_e | 102.7 | +4.0 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| player (south-west) | 43.2 (node_fire_mid) | 36.3 (tower_s) | 33.6 (camp_wallow_s) | 28.6 (lair_heath_w) | 60.7 (TavernFire) | 40.0 (heron_ford) | 64.5 (RuinPeddlerFire) | 38.3 (LostCache1) | 57.7 (crown) | 114.7 |
| enemy (north-east) | 42.3 (node_shadow_mid) | 35.8 (tower_n) | 33.2 (camp_wallow_n) | 28.3 (lair_heath_e) | 60.0 (TavernShadow) | 39.6 (lantern_wharf) | 63.9 (RuinPeddlerShadow) | 37.7 (LostCache3) | 57.0 (crown) | 114.7 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| node_fire_a | home_node | 6.7 | node_shadow_a | 6.6 | +1.4 % |
| node_fire_b | home_node | 11.2 | node_shadow_b | 10.7 | +4.3 % |
| lair_heath_w | lair | 28.6 | lair_heath_e | 28.3 | +0.9 % |
| camp_wallow_s | camp | 33.6 | camp_wallow_n | 33.2 | +1.3 % |
| tower_s | point | 36.3 | tower_n | 35.8 | +1.4 % |
| LostCache1 | cache | 38.3 | LostCache3 | 37.7 | +1.7 % |
| heron_ford | post | 40.0 | lantern_wharf | 39.6 | +0.9 % |
| LostCache0 | cache | 41.1 | LostCache2 | 40.5 | +1.5 % |
| node_fire_mid | expansion | 43.2 | node_shadow_mid | 42.3 | +2.0 % |
| millstone_cross | post | 43.5 | saltgate | 43.1 | +1.0 % |
| bridge_crown_w | crossing_bridge_lane | 45.2 | bridge_crown_e | 44.4 | +1.6 % |
| camp_stag_w | camp | 49.5 | camp_stag_e | 49.0 | +1.1 % |
| shrine_w | point | 49.6 | shrine_e | 48.9 | +1.3 % |
| ford_s | crossing_ford | 50.8 | ford_n | 50.2 | +1.1 % |
| camp_nest_s | camp | 50.8 | camp_nest_n | 50.2 | +1.1 % |
| bridge_road_s | crossing_bridge_road | 54.8 | bridge_road_n | 54.4 | +0.8 % |
| crown | crown | 57.7 | crown | 57.0 | +1.3 % |
| lair_crag_w | lair | 58.3 | lair_crag_e | 57.9 | +0.7 % |
| TavernFire | tavern | 60.7 | TavernShadow | 60.0 | +1.1 % |
| steps_nw | crossing_steps | 61.8 | steps_se | 61.0 | +1.3 % |
| steps_se | crossing_steps | 61.8 | steps_nw | 61.1 | +1.1 % |
| well_w | point | 64.4 | well_e | 63.8 | +0.9 % |
| RuinPeddlerFire | peddler | 64.5 | RuinPeddlerShadow | 63.9 | +1.0 % |
| tower_se | point | 66.9 | tower_nw | 66.4 | +0.8 % |
| RuinPeddlerShadow | peddler | 68.1 | RuinPeddlerFire | 67.6 | +0.8 % |
| lair_den_e | lair | 69.6 | lair_den_w | 69.2 | +0.6 % |
| bridge_crown_e | crossing_bridge_lane | 70.3 | bridge_crown_w | 69.5 | +1.1 % |
| TavernShadow | tavern | 70.5 | TavernFire | 70.1 | +0.6 % |
| well_e | point | 74.0 | well_w | 73.5 | +0.8 % |
| lair_hollow_w | lair | 74.5 | lair_hollow_e | 74.1 | +0.5 % |
| shrine_e | point | 75.1 | shrine_w | 74.4 | +0.9 % |
| node_shadow_mid | expansion | 75.5 | node_fire_mid | 74.8 | +0.9 % |
| node_fire_rich | expansion | 79.3 | node_shadow_rich | 78.8 | +0.6 % |
| camp_nest_n | camp | 80.9 | camp_nest_s | 80.2 | +0.9 % |
| ford_n | crossing_ford | 80.9 | ford_s | 80.2 | +0.9 % |
| tower_nw | point | 82.3 | tower_se | 81.7 | +0.7 % |
| node_shadow_rich | expansion | 82.3 | node_fire_rich | 81.8 | +0.6 % |
| MagpieDenNorthWest | guild | 85.2 | MagpieDenSouthEast | 84.8 | +0.5 % |
| LostCache3 | cache | 86.2 | LostCache1 | 85.4 | +0.9 % |
| camp_stag_e | camp | 87.3 | camp_stag_w | 86.8 | +0.6 % |
| GreywaterLodgeSouthEast | guild | 88.4 | GreywaterLodgeNorthWest | 88.0 | +0.5 % |
| LostCache2 | cache | 90.3 | LostCache0 | 89.9 | +0.5 % |
| bridge_road_n | crossing_bridge_road | 93.3 | bridge_road_s | 92.7 | +0.7 % |
| GreywaterLodgeNorthWest | guild | 94.3 | GreywaterLodgeSouthEast | 93.8 | +0.5 % |
| lair_den_w | lair | 94.7 | lair_den_e | 94.1 | +0.6 % |
| camp_hollow_nw | camp | 95.1 | camp_hollow_se | 94.7 | +0.4 % |
| tower_n | point | 96.2 | tower_s | 95.4 | +0.8 % |
| lair_crag_e | lair | 97.7 | lair_crag_w | 97.1 | +0.6 % |
| MagpieDenSouthEast | guild | 97.9 | MagpieDenNorthWest | 97.4 | +0.5 % |
| lair_hollow_e | lair | 98.2 | lair_hollow_w | 97.6 | +0.5 % |
| camp_hollow_se | camp | 100.9 | camp_hollow_nw | 100.4 | +0.5 % |
| saltgate | post | 102.2 | millstone_cross | 101.5 | +0.7 % |
| lantern_wharf | post | 106.5 | heron_ford | 106.0 | +0.5 % |
| lair_heath_e | lair | 112.6 | lair_heath_w | 111.9 | +0.6 % |
| camp_wallow_n | camp | 112.9 | camp_wallow_s | 115.9 | -2.6 % |
| node_shadow_b | home_node | 114.5 | node_fire_b | 113.8 | +0.7 % |
| node_shadow_a | home_node | 114.6 | node_fire_a | 113.8 | +0.6 % |
| keep_t1 | keep | 114.7 | keep_t0 | 114.7 | +0.0 % |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_n | bridge_road | 6.0 | 4.3 | 5.3 | bridge_road_s | 4.0 |
| bridge_road_s | bridge_road | 6.0 | 4.0 | 5.0 | bridge_road_n | 4.3 |
| ford_n | ford | 7.0 | 4.6 | 5.6 | ford_s | 4.6 |
| ford_s | ford | 7.0 | 4.6 | 5.6 | ford_n | 4.6 |
| bridge_crown_w | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_e | 7.1 |
| bridge_crown_e | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_w | 7.1 |
| steps_nw | steps | 6.0 | 5.1 | 6.1 | steps_se | 5.1 |
| steps_se | steps | 6.0 | 5.1 | 6.1 | steps_nw | 5.1 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 57.7 | 5.8 | (-7.5, 7.6) | - |
| keep_t0 -> keep_t1 | 114.7 | 5.6 | (7.5, -7.0) | - |
| keep_t0 -> node_fire_mid | 43.2 | 40.1 | (-39.0, 36.9) | - |
| keep_t1 -> crown | 57.0 | 5.8 | (8.0, -7.6) | - |
| keep_t1 -> node_shadow_mid | 42.3 | 40.1 | (38.5, -36.4) | - |


## Hottest metres (every spot-pair shortest path, 1711 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-8.5, -33.5) | 151 | 9 % |
| 2 | (8.5, 33.5) | 148 | 9 % |
| 3 | (6.5, 8.5) | 115 | 7 % |
| 4 | (-13.5, 7.5) | 110 | 6 % |
| 5 | (-8.5, -8.5) | 107 | 6 % |
| 6 | (-14.5, -14.5) | 102 | 6 % |
| 7 | (14.5, 14.5) | 98 | 6 % |
| 8 | (13.5, -7.5) | 97 | 6 % |
| 9 | (0.5, 0.5) | 95 | 6 % |
| 10 | (29.5, 23.5) | 79 | 5 % |


## Info findings (14)
| Check | Where | What |
|---|---|---|
| N3 | island 4 at (43.1, -42.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 11 at (-42.9, 43.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 10 islands on top of colliders (432 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | TavernFire-bridge_crown_w vs TavernShadow-bridge_crown_e | 27.2 m vs 25.6 m (5.9 %) |
| F2 | millstone_cross-MagpieDenNorthWest vs saltgate-MagpieDenSouthEast | 117.1 m vs 111.7 m (4.6 %) |
| F2 | node_fire_rich-tower_n vs node_shadow_rich-tower_s | 46.5 m vs 48.4 m (4.0 %) |
| F2 | millstone_cross-lair_hollow_w vs saltgate-lair_hollow_e | 107.0 m vs 102.7 m (4.0 %) |
| F2 | GreywaterLodgeNorthWest-ford_s vs GreywaterLodgeSouthEast-ford_n | 104.3 m vs 108.5 m (3.9 %) |
| F2 | camp_nest_n-ford_s vs camp_nest_s-ford_n | 77.4 m vs 74.4 m (3.9 %) |
| F2 | camp_nest_n-GreywaterLodgeSouthEast vs camp_nest_s-GreywaterLodgeNorthWest | 104.2 m vs 108.4 m (3.9 %) |
| F2 | millstone_cross-lair_crag_w vs saltgate-lair_crag_e | 91.0 m vs 87.8 m (3.5 %) |
| F2 | camp_nest_n-bridge_road_s vs camp_nest_s-bridge_road_n | 92.1 m vs 89.5 m (2.9 %) |
| F2 | bridge_road_n-ford_s vs bridge_road_s-ford_n | 91.6 m vs 89.1 m (2.7 %) |
| F2 | keep_t0-camp_wallow_n vs keep_t1-camp_wallow_s | 112.9 m vs 115.9 m (2.6 %) |

## Notes
- Octile grid shortest paths (0.5 m, 59 sources) 36.88 s.
- Navmesh raster 1.21 s (226 polygons, 230400 cells of 0.25 m), spot / mirror checks 0.45 s, 1711 paths 0.34 s.
- Map Crown Hollow (1v1), scene res://docs/tools/world_forge/out/crown_hollow/preview.tscn, sim mode on; level load + navmesh bake 0.2 s (13 frames), lab 39.3 s. Spec: docs/design/skirmish-1v1.md,.
