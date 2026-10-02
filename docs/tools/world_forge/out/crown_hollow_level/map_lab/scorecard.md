# Map Lab: Crown Hollow (1v1) scorecard: world_forge_crown_hollow_level

2026-10-02 18:56 · lab v1.0 · 66.27 s · scanned 59 spots

## Result: **WARN** · score **97 / 100**

0 FAIL · 2 WARN · 16 PASS · 3 info checks; findings: 0 FAIL, 46 WARN, 103 info

## Improve next
1. **Unit paths (NavigationServer): pairs match their twins** (WARN): node_fire_a-heron_ford vs node_shadow_a-lantern_wharf: 38.4 m vs 45.5 m (15.4 %) -> units walk node_shadow_a-lantern_wharf the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 741 / 870 pairs within 2 % (0 FAIL, 42 WARN, 87 info))_
2. **Clearances (roads, crossings)** (WARN): node_fire_mid: node 7.6 m from crossing bridge_crown_w (want >= 8) -> move it off the crossing approach (auto-fix) _(from R4 47 / 51 clean (0 FAIL, 4 WARN))_
3. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 1356 polygons, main area 12083 m² (84 % of the 120 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 59 / 59 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 12 / 12 clean, 13 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 51 spots ok, 1.0x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |
| R6 | Mission marks / triggers / paths | INFO | no mission overlay data |  |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 59 / 59 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 59 / 59 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | layout crown_hollow_level | LayoutLevel: positions come from the layout (no spot constants) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.03 % (64 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 812 / 812 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 67 | 741 / 870 pairs within 2 % (0 FAIL, 42 WARN, 87 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

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
| R4 | Clearances (roads, crossings) | **WARN** 66 | 47 / 51 clean (0 FAIL, 4 WARN) | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (480 x 480 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F2 | node_fire_a-heron_ford vs node_shadow_a-lantern_wharf | 38.4 m vs 45.5 m (15.4 %) | units walk node_shadow_a-lantern_wharf the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-LostCache3 vs tower_se-LostCache1 | 40.8 m vs 35.2 m (13.8 %) | units walk tower_nw-LostCache3 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-tower_n vs tower_se-tower_s | 37.7 m vs 32.8 m (12.9 %) | units walk tower_nw-tower_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_s-GreywaterLodgeSouthEast vs tower_n-GreywaterLodgeNorthWest | 58.8 m vs 52.4 m (10.9 %) | units walk tower_s-GreywaterLodgeSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-RuinPeddlerShadow vs tower_se-RuinPeddlerFire | 93.7 m vs 84.0 m (10.3 %) | units walk tower_nw-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_rich-LostCache3 vs node_shadow_rich-LostCache1 | 50.9 m vs 46.3 m (9.0 %) | units walk node_fire_rich-LostCache3 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-lair_heath_w vs tower_se-lair_heath_e | 63.8 m vs 58.3 m (8.6 %) | units walk tower_nw-lair_heath_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-well_e vs tower_se-well_w | 98.0 m vs 89.7 m (8.5 %) | units walk tower_nw-well_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_mid-bridge_crown_e vs node_shadow_mid-bridge_crown_w | 35.0 m vs 38.2 m (8.2 %) | units walk node_shadow_mid-bridge_crown_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_rich-tower_n vs node_shadow_rich-tower_s | 47.8 m vs 44.0 m (8.0 %) | units walk node_fire_rich-tower_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | TavernFire-LostCache1 vs TavernShadow-LostCache3 | 49.6 m vs 53.7 m (7.6 %) | units walk TavernShadow-LostCache3 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-LostCache2 vs tower_se-LostCache0 | 76.0 m vs 70.3 m (7.5 %) | units walk tower_nw-LostCache2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_hollow_nw-camp_stag_w vs camp_hollow_se-camp_stag_e | 52.7 m vs 48.8 m (7.5 %) | units walk camp_hollow_nw-camp_stag_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_b-millstone_cross vs node_shadow_b-saltgate | 36.5 m vs 39.2 m (6.9 %) | units walk node_shadow_b-saltgate the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-steps_nw vs MagpieDenSouthEast-steps_se | 56.5 m vs 60.7 m (6.9 %) | units walk MagpieDenSouthEast-steps_se the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_hollow_nw-GreywaterLodgeSouthEast vs camp_hollow_se-GreywaterLodgeNorthWest | 163.1 m vs 152.4 m (6.6 %) | units walk camp_hollow_nw-GreywaterLodgeSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-camp_stag_e vs tower_se-camp_stag_w | 88.0 m vs 82.3 m (6.5 %) | units walk tower_nw-camp_stag_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | GreywaterLodgeNorthWest-RuinPeddlerShadow vs GreywaterLodgeSouthEast-RuinPeddlerFire | 114.5 m vs 107.2 m (6.4 %) | units walk GreywaterLodgeNorthWest-RuinPeddlerShadow the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross-bridge_road_n vs saltgate-bridge_road_s | 100.1 m vs 107.0 m (6.4 %) | units walk saltgate-bridge_road_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | millstone_cross-LostCache3 vs saltgate-LostCache1 | 85.6 m vs 80.1 m (6.4 %) | units walk millstone_cross-LostCache3 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_hollow_nw-camp_nest_n vs camp_hollow_se-camp_nest_s | 51.6 m vs 55.1 m (6.2 %) | units walk camp_hollow_se-camp_nest_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_hollow_nw-ford_n vs camp_hollow_se-ford_s | 51.6 m vs 55.1 m (6.2 %) | units walk camp_hollow_se-ford_s the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_stag_w-saltgate vs camp_stag_e-millstone_cross | 54.7 m vs 58.3 m (6.2 %) | units walk camp_stag_e-millstone_cross the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-lair_heath_e vs tower_se-lair_heath_w | 89.7 m vs 84.2 m (6.1 %) | units walk tower_nw-lair_heath_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | lair_crag_w-lair_den_w vs lair_crag_e-lair_den_e | 49.0 m vs 46.1 m (6.1 %) | units walk lair_crag_w-lair_den_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | TavernFire-MagpieDenNorthWest vs TavernShadow-MagpieDenSouthEast | 45.2 m vs 48.1 m (5.9 %) | units walk TavernShadow-MagpieDenSouthEast the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford-ford_n vs lantern_wharf-ford_s | 56.5 m vs 53.2 m (5.8 %) | units walk heron_ford-ford_n the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_s-heron_ford vs tower_n-lantern_wharf | 72.0 m vs 67.8 m (5.8 %) | units walk tower_s-heron_ford the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-crown vs MagpieDenSouthEast-crown | 68.5 m vs 72.7 m (5.7 %) | units walk MagpieDenSouthEast-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | camp_hollow_nw-LostCache0 vs camp_hollow_se-LostCache2 | 63.8 m vs 67.7 m (5.7 %) | units walk camp_hollow_se-LostCache2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | heron_ford-lair_crag_e vs lantern_wharf-lair_crag_w | 115.0 m vs 108.4 m (5.7 %) | units walk heron_ford-lair_crag_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_rich-tower_se vs node_shadow_rich-tower_nw | 111.8 m vs 105.5 m (5.6 %) | units walk node_fire_rich-tower_se the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-lair_crag_e vs tower_se-lair_crag_w | 105.3 m vs 99.6 m (5.4 %) | units walk tower_nw-lair_crag_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_rich-LostCache2 vs node_shadow_rich-LostCache0 | 86.1 m vs 81.5 m (5.4 %) | units walk node_fire_rich-LostCache2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_rich-shrine_e vs node_shadow_rich-shrine_w | 86.2 m vs 81.5 m (5.4 %) | units walk node_fire_rich-shrine_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_fire_b-node_shadow_rich vs node_shadow_b-node_fire_rich | 76.7 m vs 81.0 m (5.3 %) | units walk node_shadow_b-node_fire_rich the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-bridge_crown_e vs MagpieDenSouthEast-bridge_crown_w | 74.2 m vs 78.4 m (5.3 %) | units walk MagpieDenSouthEast-bridge_crown_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-tower_se vs keep_t1-tower_nw | 67.7 m vs 71.5 m (5.3 %) | units walk keep_t1-tower_nw the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | GreywaterLodgeNorthWest-bridge_crown_e vs GreywaterLodgeSouthEast-bridge_crown_w | 72.6 m vs 76.7 m (5.3 %) | units walk GreywaterLodgeSouthEast-bridge_crown_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tower_nw-lantern_wharf vs tower_se-heron_ford | 99.3 m vs 94.1 m (5.2 %) | units walk tower_nw-lantern_wharf the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | MagpieDenNorthWest-bridge_crown_w vs MagpieDenSouthEast-bridge_crown_e | 73.6 m vs 77.6 m (5.2 %) | units walk MagpieDenSouthEast-bridge_crown_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_w-lair_heath_e vs well_e-lair_heath_w | 86.4 m vs 91.1 m (5.1 %) | units walk well_e-lair_heath_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | R4 | node_fire_mid | node 7.6 m from crossing bridge_crown_w (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | node_shadow_mid | node 7.6 m from crossing bridge_crown_e (want >= 8) | move it off the crossing approach (auto-fix) |
| WARN | R4 | tower_s | point 6.7 m from a road centre line (want >= 7) | push it off the road (auto-fix) |
| WARN | R4 | tower_n | point 6.7 m from a road centre line (want >= 7) | push it off the road (auto-fix) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-43.0, 43.0) | (-39.9, 42.1) | keep_t1 | (-39.9, 42.1) | 0.0 |
| keep_t1 | keep | (43.0, -43.0) | (39.9, -42.1) | keep_t0 | (39.9, -42.1) | 0.0 |
| node_fire_a | home_node | (-46.0, 34.0) | (-44.1, 32.9) | node_shadow_a | (-44.1, 32.9) | 0.0 |
| node_shadow_a | home_node | (46.0, -34.0) | (44.1, -32.9) | node_fire_a | (44.1, -32.9) | 0.0 |
| node_fire_b | home_node | (-34.0, 46.0) | (-35.6, 46.4) | node_shadow_b | (-35.6, 46.4) | 0.0 |
| node_shadow_b | home_node | (34.0, -46.0) | (35.6, -46.4) | node_fire_b | (35.6, -46.4) | 0.0 |
| node_fire_mid | expansion | (-16.0, 6.0) | (-14.4, 4.6) | node_shadow_mid | (-14.4, 4.6) | 0.0 |
| node_shadow_mid | expansion | (16.0, -6.0) | (14.4, -4.6) | node_fire_mid | (14.4, -4.6) | 0.0 |
| node_fire_rich | expansion | (-40.0, -40.0) | (-38.4, -38.6) | node_shadow_rich | (-38.4, -38.6) | 0.0 |
| node_shadow_rich | expansion | (40.0, 40.0) | (38.4, 38.6) | node_fire_rich | (38.4, 38.6) | 0.0 |
| shrine_w | point | (-22.0, -6.0) | (-21.9, -5.9) | shrine_e | (-21.9, -5.9) | 0.0 |
| shrine_e | point | (22.0, 6.0) | (21.9, 5.9) | shrine_w | (21.9, 5.9) | 0.0 |
| tower_nw | point | (-24.0, -41.0) | (-26.4, -39.6) | tower_se | (-26.6, -39.1) | 0.6 |
| tower_se | point | (24.0, 41.0) | (26.6, 39.1) | tower_nw | (26.4, 39.6) | 0.6 |
| tower_s | point | (-6.0, 40.0) | (-5.4, 37.4) | tower_n | (-4.9, 36.9) | 0.7 |
| tower_n | point | (6.0, -40.0) | (4.9, -36.9) | tower_s | (5.4, -37.4) | 0.7 |
| well_w | point | (-30.0, -24.0) | (-29.4, -26.1) | well_e | (-28.9, -26.4) | 0.6 |
| well_e | point | (30.0, 24.0) | (28.9, 26.4) | well_w | (29.4, 26.1) | 0.6 |
| camp_hollow_nw | camp | (-55.0, -55.0) | (-54.9, -54.9) | camp_hollow_se | (-54.9, -54.9) | 0.0 |
| camp_hollow_se | camp | (55.0, 55.0) | (54.9, 54.9) | camp_hollow_nw | (54.9, 54.9) | 0.0 |
| camp_nest_n | camp | (-8.5, -34.0) | (-8.4, -33.9) | camp_nest_s | (-8.4, -33.9) | 0.0 |
| camp_nest_s | camp | (8.5, 34.0) | (8.4, 33.9) | camp_nest_n | (8.4, 33.9) | 0.0 |
| camp_stag_w | camp | (-37.0, -10.0) | (-36.9, -9.9) | camp_stag_e | (-36.9, -9.9) | 0.0 |
| camp_stag_e | camp | (37.0, 10.0) | (36.9, 9.9) | camp_stag_w | (36.9, 9.9) | 0.0 |
| camp_wallow_s | camp | (-14.0, 57.0) | (-13.9, 56.9) | camp_wallow_n | (-13.9, 56.9) | 0.0 |
| camp_wallow_n | camp | (14.0, -57.0) | (13.9, -56.9) | camp_wallow_s | (13.9, -56.9) | 0.0 |
| TavernFire | tavern | (-15.0, -15.0) | (-14.1, -18.6) | TavernShadow | (-13.6, -18.9) | 0.6 |
| TavernShadow | tavern | (15.0, 15.0) | (13.6, 18.9) | TavernFire | (14.1, 18.6) | 0.6 |
| heron_ford | post | (-53.0, 1.0) | (-52.1, -2.6) | lantern_wharf | (-51.6, -2.9) | 0.6 |
| lantern_wharf | post | (53.0, -1.0) | (51.6, 2.9) | heron_ford | (52.1, 2.6) | 0.6 |
| millstone_cross | post | (-1.0, 53.0) | (-0.1, 49.4) | saltgate | (0.1, 48.9) | 0.6 |
| saltgate | post | (1.0, -53.0) | (-0.1, -48.9) | millstone_cross | (0.1, -49.4) | 0.6 |
| GreywaterLodgeNorthWest | guild | (-45.0, -55.0) | (-44.1, -51.4) | GreywaterLodgeSouthEast | (-44.1, -51.4) | 0.0 |
| GreywaterLodgeSouthEast | guild | (45.0, 55.0) | (44.1, 51.4) | GreywaterLodgeNorthWest | (44.1, 51.4) | 0.0 |
| MagpieDenNorthWest | guild | (-55.0, -45.0) | (-51.4, -44.1) | MagpieDenSouthEast | (-51.4, -44.1) | 0.0 |
| MagpieDenSouthEast | guild | (55.0, 45.0) | (51.4, 44.1) | MagpieDenNorthWest | (51.4, 44.1) | 0.0 |
| RuinPeddlerFire | peddler | (-22.0, -22.0) | (-23.1, -23.1) | RuinPeddlerShadow | (-23.1, -23.1) | 0.0 |
| RuinPeddlerShadow | peddler | (22.0, 22.0) | (23.1, 23.1) | RuinPeddlerFire | (23.1, 23.1) | 0.0 |
| LostCache0 | cache | (-30.0, 0.0) | (-29.9, 0.1) | LostCache2 | (-29.9, 0.1) | 0.0 |
| LostCache1 | cache | (-6.0, 27.0) | (-5.9, 26.9) | LostCache3 | (-5.9, 26.9) | 0.0 |
| LostCache2 | cache | (30.0, 0.0) | (29.9, -0.1) | LostCache0 | (29.9, -0.1) | 0.0 |
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


## F2 unit paths: most asymmetric pairs (top 20 of 129)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | node_fire_a - heron_ford | 38.4 | node_shadow_a - lantern_wharf | 45.5 | -15.4 % |
| 2 | tower_nw - LostCache3 | 40.8 | tower_se - LostCache1 | 35.2 | +13.8 % |
| 3 | tower_nw - tower_n | 37.7 | tower_se - tower_s | 32.8 | +12.9 % |
| 4 | tower_s - GreywaterLodgeSouthEast | 58.8 | tower_n - GreywaterLodgeNorthWest | 52.4 | +10.9 % |
| 5 | tower_nw - RuinPeddlerShadow | 93.7 | tower_se - RuinPeddlerFire | 84.0 | +10.3 % |
| 6 | node_fire_rich - LostCache3 | 50.9 | node_shadow_rich - LostCache1 | 46.3 | +9.0 % |
| 7 | tower_nw - lair_heath_w | 63.8 | tower_se - lair_heath_e | 58.3 | +8.6 % |
| 8 | tower_nw - well_e | 98.0 | tower_se - well_w | 89.7 | +8.5 % |
| 9 | node_fire_mid - bridge_crown_e | 35.0 | node_shadow_mid - bridge_crown_w | 38.2 | -8.2 % |
| 10 | node_fire_rich - tower_n | 47.8 | node_shadow_rich - tower_s | 44.0 | +8.0 % |
| 11 | TavernFire - LostCache1 | 49.6 | TavernShadow - LostCache3 | 53.7 | -7.6 % |
| 12 | tower_nw - LostCache2 | 76.0 | tower_se - LostCache0 | 70.3 | +7.5 % |
| 13 | camp_hollow_nw - camp_stag_w | 52.7 | camp_hollow_se - camp_stag_e | 48.8 | +7.5 % |
| 14 | node_fire_b - millstone_cross | 36.5 | node_shadow_b - saltgate | 39.2 | -6.9 % |
| 15 | MagpieDenNorthWest - steps_nw | 56.5 | MagpieDenSouthEast - steps_se | 60.7 | -6.9 % |
| 16 | camp_hollow_nw - GreywaterLodgeSouthEast | 163.1 | camp_hollow_se - GreywaterLodgeNorthWest | 152.4 | +6.6 % |
| 17 | node_fire_mid - TavernFire | 27.8 | node_shadow_mid - TavernShadow | 26.0 | +6.6 % |
| 18 | tower_nw - camp_stag_e | 88.0 | tower_se - camp_stag_w | 82.3 | +6.5 % |
| 19 | GreywaterLodgeNorthWest - RuinPeddlerShadow | 114.5 | GreywaterLodgeSouthEast - RuinPeddlerFire | 107.2 | +6.4 % |
| 20 | millstone_cross - bridge_road_n | 100.1 | saltgate - bridge_road_s | 107.0 | -6.4 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| player (south-west) | 47.0 (node_fire_mid) | 34.8 (tower_s) | 30.8 (camp_wallow_s) | 33.1 (lair_heath_w) | 65.2 (TavernShadow) | 40.4 (millstone_cross) | 66.8 (RuinPeddlerShadow) | 37.3 (LostCache1) | 58.0 (crown) | 116.0 |
| enemy (north-east) | 47.0 (node_shadow_mid) | 35.4 (tower_n) | 30.8 (camp_wallow_n) | 33.1 (lair_heath_e) | 65.5 (TavernFire) | 40.6 (saltgate) | 66.8 (RuinPeddlerFire) | 37.3 (LostCache3) | 58.0 (crown) | 116.0 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| node_fire_b | home_node | 6.0 | node_shadow_b | 6.0 | -0.0 % |
| node_fire_a | home_node | 10.4 | node_shadow_a | 10.4 | +0.0 % |
| camp_wallow_s | camp | 30.8 | camp_wallow_n | 30.8 | +0.0 % |
| lair_heath_w | lair | 33.1 | lair_heath_e | 33.1 | +0.0 % |
| tower_s | point | 34.8 | tower_n | 35.4 | -1.6 % |
| LostCache1 | cache | 37.3 | LostCache3 | 37.3 | +0.0 % |
| millstone_cross | post | 40.4 | saltgate | 40.6 | -0.4 % |
| LostCache0 | cache | 43.2 | LostCache2 | 43.2 | +0.0 % |
| bridge_crown_w | crossing_bridge_lane | 45.5 | bridge_crown_e | 45.5 | +0.0 % |
| node_fire_mid | expansion | 47.0 | node_shadow_mid | 47.0 | +0.0 % |
| heron_ford | post | 48.3 | lantern_wharf | 47.9 | +0.9 % |
| ford_s | crossing_ford | 49.0 | ford_n | 49.0 | +0.0 % |
| camp_nest_s | camp | 49.0 | camp_nest_n | 49.0 | +0.0 % |
| shrine_w | point | 52.0 | shrine_e | 51.3 | +1.3 % |
| bridge_road_s | crossing_bridge_road | 52.3 | bridge_road_n | 52.2 | +0.1 % |
| camp_stag_w | camp | 52.4 | camp_stag_e | 52.4 | +0.0 % |
| crown | crown | 58.0 | crown | 58.0 | +0.0 % |
| lair_crag_w | lair | 61.4 | lair_crag_e | 61.4 | +0.0 % |
| steps_nw | crossing_steps | 61.8 | steps_se | 61.8 | +0.0 % |
| steps_se | crossing_steps | 63.9 | steps_nw | 61.6 | +3.6 % |
| TavernShadow | tavern | 65.2 | TavernFire | 65.5 | -0.5 % |
| lair_den_e | lair | 66.8 | lair_den_w | 66.8 | +0.0 % |
| RuinPeddlerShadow | peddler | 66.8 | RuinPeddlerFire | 66.8 | +0.0 % |
| tower_se | point | 67.7 | tower_nw | 71.5 | -5.3 % |
| RuinPeddlerFire | peddler | 69.1 | RuinPeddlerShadow | 69.1 | -0.0 % |
| TavernFire | tavern | 69.2 | TavernShadow | 70.0 | -1.1 % |
| bridge_crown_e | crossing_bridge_lane | 70.6 | bridge_crown_w | 70.6 | +0.0 % |
| well_e | point | 70.6 | well_w | 71.1 | -0.8 % |
| well_w | point | 75.9 | well_e | 73.6 | +3.0 % |
| shrine_e | point | 77.0 | shrine_w | 74.9 | +2.6 % |
| lair_hollow_w | lair | 77.8 | lair_hollow_e | 77.8 | +0.0 % |
| node_shadow_rich | expansion | 81.3 | node_fire_rich | 81.3 | +0.0 % |
| node_fire_rich | expansion | 81.5 | node_shadow_rich | 81.5 | -0.0 % |
| node_shadow_mid | expansion | 83.4 | node_fire_mid | 83.4 | +0.0 % |
| ford_n | crossing_ford | 83.6 | ford_s | 83.6 | -0.1 % |
| camp_nest_n | camp | 83.6 | camp_nest_s | 83.6 | -0.1 % |
| GreywaterLodgeSouthEast | guild | 84.6 | GreywaterLodgeNorthWest | 84.6 | +0.0 % |
| tower_nw | point | 85.2 | tower_se | 84.8 | +0.6 % |
| camp_stag_e | camp | 85.9 | camp_stag_w | 85.9 | +0.0 % |
| LostCache3 | cache | 86.8 | LostCache1 | 86.8 | +0.0 % |
| MagpieDenNorthWest | guild | 87.0 | MagpieDenSouthEast | 87.0 | +0.0 % |
| LostCache2 | cache | 91.6 | LostCache0 | 91.6 | +0.0 % |
| MagpieDenSouthEast | guild | 92.0 | MagpieDenNorthWest | 91.9 | +0.1 % |
| GreywaterLodgeNorthWest | guild | 94.4 | GreywaterLodgeSouthEast | 93.6 | +0.8 % |
| lair_crag_e | lair | 96.1 | lair_crag_w | 96.1 | +0.0 % |
| camp_hollow_se | camp | 96.2 | camp_hollow_nw | 96.2 | -0.0 % |
| tower_n | point | 96.9 | tower_s | 97.3 | -0.5 % |
| camp_hollow_nw | camp | 98.6 | camp_hollow_se | 98.6 | +0.1 % |
| lair_hollow_e | lair | 98.8 | lair_hollow_w | 98.7 | +0.2 % |
| bridge_road_n | crossing_bridge_road | 99.3 | bridge_road_s | 99.3 | +0.0 % |
| lair_den_w | lair | 99.5 | lair_den_e | 99.5 | -0.0 % |
| saltgate | post | 101.3 | millstone_cross | 101.9 | -0.6 % |
| lantern_wharf | post | 104.9 | heron_ford | 105.3 | -0.3 % |
| lair_heath_e | lair | 112.9 | lair_heath_w | 113.0 | -0.0 % |
| node_shadow_a | home_node | 113.4 | node_fire_a | 113.4 | +0.0 % |
| keep_t1 | keep | 116.0 | keep_t0 | 116.0 | +0.0 % |
| node_shadow_b | home_node | 116.7 | node_fire_b | 116.7 | -0.0 % |
| camp_wallow_n | camp | 117.2 | camp_wallow_s | 117.2 | +0.0 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| player (south-west) | enemy keep (keep_t1) | 116.0 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| player (south-west) | nearest expansion (node_fire_mid) | 47.0 | 0.0 | 0:10 | 0:09 | 0:06 | 0:12 |
| player (south-west) | nearest point (tower_s) | 34.8 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| player (south-west) | nearest camp (camp_wallow_s) | 30.8 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| player (south-west) | crown (crown) | 58.0 | 0.0 | 0:13 | 0:12 | 0:08 | 0:15 |
| enemy (north-east) | enemy keep (keep_t0) | 116.0 | 0.0 | 0:25 | 0:23 | 0:15 | 0:29 |
| enemy (north-east) | nearest expansion (node_shadow_mid) | 47.0 | 0.0 | 0:10 | 0:09 | 0:06 | 0:12 |
| enemy (north-east) | nearest point (tower_n) | 35.4 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| enemy (north-east) | nearest camp (camp_wallow_n) | 30.8 | 0.0 | 0:07 | 0:06 | 0:04 | 0:08 |
| enemy (north-east) | crown (crown) | 58.0 | 0.0 | 0:13 | 0:12 | 0:08 | 0:15 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_n | bridge_road | 6.0 | 5.0 | 6.0 | bridge_road_s | 5.0 |
| bridge_road_s | bridge_road | 6.0 | 5.0 | 6.0 | bridge_road_n | 5.0 |
| ford_n | ford | 7.0 | 6.1 | 7.1 | ford_s | 6.1 |
| ford_s | ford | 7.0 | 6.1 | 7.1 | ford_n | 6.1 |
| bridge_crown_w | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_e | 7.1 |
| bridge_crown_e | bridge_lane | 8.0 | 7.1 | 8.1 | bridge_crown_w | 7.1 |
| steps_nw | steps | 6.0 | 5.0 | 6.0 | steps_se | 4.9 |
| steps_se | steps | 6.0 | 4.9 | 5.9 | steps_nw | 5.0 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 58.0 | 6.9 | (-8.2, 8.8) | - |
| keep_t0 -> keep_t1 | 116.0 | 6.9 | (-8.9, 9.4) | - |
| keep_t0 -> node_fire_mid | 47.0 | 16.3 | (-18.3, 6.1) | - |
| keep_t1 -> crown | 58.0 | 6.9 | (9.0, -9.4) | - |
| keep_t1 -> node_shadow_mid | 47.0 | 16.3 | (18.3, -6.1) | - |


## R1 targets per seat (navmesh path m; enemy_ally = ratio)
| Seat | Target | Band | Measured | Miss |
|---|---|---|---|---|
| player (south-west) | keep_enemy | 100.00-150.00 | 116.01 | - |
| player (south-west) | natural | 40.00-60.00 | 46.98 | - |
| player (south-west) | rich | 70.00-95.00 | 81.47 | - |
| player (south-west) | crown | 50.00-75.00 | 58.00 | - |
| enemy (north-east) | keep_enemy | 100.00-150.00 | 116.01 | - |
| enemy (north-east) | natural | 40.00-60.00 | 46.98 | - |
| enemy (north-east) | rich | 70.00-95.00 | 81.49 | - |
| enemy (north-east) | crown | 50.00-75.00 | 58.00 | - |


## R2 content per seat
| Seat | home node | natural | rich | post | tavern | peddler | cache | camp T1 | camp T2 | camp T3 | lair | watchtower | well | shrine | crown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| player (south-west) | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |
| enemy (north-east) | 2 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 2 | 1 | 4 | 2 | 1 | 1 | 1 |


## R3 contest per seat
| Seat | Contested (0.9-1.1) | Raidable (1.1-1.45) | Own (< 0.9) | Objectives |
|---|---|---|---|---|
| player (south-west) | 9 | 1 | 9 | 27 |
| enemy (north-east) | 9 | 2 | 9 | 27 |


## Hottest metres (every spot-pair shortest path, 1711 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (8.5, 33.5) | 188 | 11 % |
| 2 | (-8.5, -33.5) | 175 | 10 % |
| 3 | (5.5, 6.5) | 147 | 9 % |
| 4 | (17.5, -7.5) | 125 | 7 % |
| 5 | (-17.5, 7.5) | 118 | 7 % |
| 6 | (-11.5, -8.5) | 108 | 6 % |
| 7 | (1.5, 28.5) | 93 | 5 % |
| 8 | (8.5, -8.5) | 89 | 5 % |
| 9 | (18.5, 11.5) | 88 | 5 % |
| 10 | (-1.5, -28.5) | 87 | 5 % |


## Info findings (103)
| Check | Where | What |
|---|---|---|
| N3 | island 2 at (-44.9, -54.9) | 22.6 m² inside the footprint of GreywaterLodgeNorthWest (unreachable by design) |
| N3 | island 6 at (1.1, -52.9) | 22.6 m² inside the footprint of saltgate (unreachable by design) |
| N3 | island 9 at (-54.9, -44.9) | 22.6 m² inside the footprint of MagpieDenNorthWest (unreachable by design) |
| N3 | island 12 at (43.1, -42.9) | 14.1 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 25 at (-14.9, -14.9) | 22.6 m² inside the footprint of TavernFire (unreachable by design) |
| N3 | island 31 at (53.1, -0.9) | 22.6 m² inside the footprint of lantern_wharf (unreachable by design) |
| N3 | island 33 at (-52.9, 1.1) | 22.6 m² inside the footprint of heron_ford (unreachable by design) |
| N3 | island 41 at (15.1, 15.1) | 22.6 m² inside the footprint of TavernShadow (unreachable by design) |
| N3 | island 54 at (-42.9, 43.1) | 14.1 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 56 at (55.1, 45.1) | 22.6 m² inside the footprint of MagpieDenSouthEast (unreachable by design) |
| N3 | island 60 at (-0.9, 53.1) | 22.6 m² inside the footprint of millstone_cross (unreachable by design) |
| N3 | island 62 at (45.1, 55.1) | 22.6 m² inside the footprint of GreywaterLodgeSouthEast (unreachable by design) |
| N3 | raised islands | 52 islands on top of colliders (153 m², more than 0.3 m above / below the ground navmesh): harmless |
| M3 | 4 m tile at (-54.0, -50.0) | 11 cells (0.7 m²) walkable on one side only (half_turn) |
| M3 | 4 m tile at (54.0, 50.0) | 10 cells (0.6 m²) walkable on one side only (half_turn) |
| M3 | 4 m tile at (-46.0, -58.0) | 9 cells (0.6 m²) walkable on one side only (half_turn) |
| F2 | node_fire_mid-TavernFire vs node_shadow_mid-TavernShadow | 27.8 m vs 26.0 m (6.6 %) |
| F2 | tower_nw-well_w vs tower_se-well_e | 13.8 m vs 12.9 m (6.4 %) |
| F2 | tower_s-millstone_cross vs tower_n-saltgate | 14.2 m vs 13.4 m (5.5 %) |
| F2 | MagpieDenNorthWest-steps_se vs MagpieDenSouthEast-steps_nw | 81.2 m vs 85.4 m (4.9 %) |
| F2 | heron_ford-LostCache3 vs lantern_wharf-LostCache1 | 71.4 m vs 67.9 m (4.9 %) |
| F2 | node_fire_b-bridge_road_s vs node_shadow_b-bridge_road_n | 48.5 m vs 51.0 m (4.9 %) |
| F2 | camp_hollow_nw-LostCache2 vs camp_hollow_se-LostCache0 | 107.9 m vs 102.7 m (4.8 %) |
| F2 | camp_stag_w-steps_nw vs camp_stag_e-steps_se | 29.4 m vs 28.0 m (4.8 %) |
| F2 | node_fire_rich-camp_stag_e vs node_shadow_rich-camp_stag_w | 98.1 m vs 93.4 m (4.7 %) |
| F2 | tower_nw-GreywaterLodgeSouthEast vs tower_se-GreywaterLodgeNorthWest | 131.0 m vs 124.8 m (4.7 %) |
| F2 | camp_nest_n-saltgate vs camp_nest_s-millstone_cross | 17.4 m vs 18.3 m (4.7 %) |
| F2 | tower_nw-MagpieDenSouthEast vs tower_se-MagpieDenNorthWest | 124.0 m vs 118.3 m (4.6 %) |
| F2 | well_w-GreywaterLodgeNorthWest vs well_e-GreywaterLodgeSouthEast | 29.2 m vs 30.6 m (4.5 %) |
| F2 | tower_nw-lair_hollow_e vs tower_se-lair_hollow_w | 120.1 m vs 114.7 m (4.5 %) |
| F2 | camp_hollow_nw-camp_stag_e vs camp_hollow_se-camp_stag_w | 120.0 m vs 114.7 m (4.5 %) |
| F2 | GreywaterLodgeNorthWest-steps_nw vs GreywaterLodgeSouthEast-steps_se | 56.3 m vs 59.0 m (4.5 %) |
| F2 | node_fire_b-tower_se vs node_shadow_b-tower_nw | 67.2 m vs 70.3 m (4.4 %) |
| F2 | TavernFire-millstone_cross vs TavernShadow-saltgate | 72.8 m vs 76.2 m (4.4 %) |
| F2 | node_fire_rich-lair_heath_e vs node_shadow_rich-lair_heath_w | 99.8 m vs 95.4 m (4.4 %) |
| F2 | node_fire_rich-bridge_crown_w vs node_shadow_rich-bridge_crown_e | 64.9 m vs 62.0 m (4.4 %) |
| F2 | node_fire_rich-bridge_crown_e vs node_shadow_rich-bridge_crown_w | 59.9 m vs 62.6 m (4.3 %) |
| F2 | shrine_w-TavernFire vs shrine_e-TavernShadow | 17.3 m vs 18.0 m (4.3 %) |
| F2 | LostCache0-LostCache3 vs LostCache2-LostCache1 | 57.5 m vs 55.1 m (4.2 %) |
| F2 | node_fire_mid-LostCache3 vs node_shadow_mid-LostCache1 | 49.5 m vs 51.6 m (4.2 %) |
| F2 | GreywaterLodgeNorthWest-crown vs GreywaterLodgeSouthEast-crown | 68.1 m vs 71.0 m (4.1 %) |
| F2 | MagpieDenNorthWest-RuinPeddlerShadow vs MagpieDenSouthEast-RuinPeddlerFire | 104.4 m vs 108.9 m (4.1 %) |
| F2 | well_w-camp_stag_w vs well_e-camp_stag_e | 20.7 m vs 19.9 m (4.0 %) |
| F2 | node_fire_rich-lair_crag_e vs node_shadow_rich-lair_crag_w | 115.4 m vs 110.8 m (4.0 %) |
| F2 | camp_hollow_nw-bridge_crown_e vs camp_hollow_se-bridge_crown_w | 82.9 m vs 86.4 m (4.0 %) |
| F2 | node_fire_mid-LostCache2 vs node_shadow_mid-LostCache0 | 56.2 m vs 58.5 m (3.9 %) |
| F2 | camp_hollow_nw-lair_crag_e vs camp_hollow_se-lair_crag_w | 137.3 m vs 132.0 m (3.8 %) |
| F2 | node_fire_b-steps_se vs node_shadow_b-steps_nw | 64.5 m vs 62.1 m (3.8 %) |
| F2 | node_fire_b-lair_den_e vs node_shadow_b-lair_den_w | 62.9 m vs 65.4 m (3.8 %) |
| F2 | node_fire_rich-lantern_wharf vs node_shadow_rich-heron_ford | 109.4 m vs 105.3 m (3.8 %) |
| F2 | camp_nest_n-millstone_cross vs camp_nest_s-saltgate | 86.4 m vs 89.8 m (3.7 %) |
| F2 | GreywaterLodgeNorthWest-bridge_crown_w vs GreywaterLodgeSouthEast-bridge_crown_e | 79.1 m vs 76.1 m (3.7 %) |
| F2 | LostCache0-lair_hollow_w vs LostCache2-lair_hollow_e | 46.2 m vs 44.5 m (3.7 %) |
| F2 | keep_t0-steps_se vs keep_t1-steps_nw | 63.9 m vs 61.6 m (3.6 %) |
| F2 | GreywaterLodgeNorthWest-steps_se vs GreywaterLodgeSouthEast-steps_nw | 80.8 m vs 83.7 m (3.6 %) |
| F2 | TavernFire-bridge_crown_w vs TavernShadow-bridge_crown_e | 30.3 m vs 31.5 m (3.5 %) |
| F2 | GreywaterLodgeNorthWest-MagpieDenSouthEast vs GreywaterLodgeSouthEast-MagpieDenNorthWest | 144.9 m vs 139.9 m (3.4 %) |
| F2 | tower_nw-saltgate vs tower_se-millstone_cross | 30.6 m vs 31.7 m (3.4 %) |
| F2 | node_fire_rich-lair_hollow_e vs node_shadow_rich-lair_hollow_w | 130.2 m vs 125.8 m (3.4 %) |
| F2 | camp_hollow_nw-lair_hollow_e vs camp_hollow_se-lair_hollow_w | 152.1 m vs 147.1 m (3.3 %) |
| F2 | tower_s-camp_wallow_s vs tower_n-camp_wallow_n | 23.1 m vs 23.8 m (3.3 %) |
| F2 | tower_nw-LostCache0 vs tower_se-LostCache2 | 41.0 m vs 39.6 m (3.3 %) |
| F2 | bridge_road_n-steps_se vs bridge_road_s-steps_nw | 63.1 m vs 65.2 m (3.2 %) |
| F2 | node_fire_mid-GreywaterLodgeNorthWest vs node_shadow_mid-GreywaterLodgeSouthEast | 69.4 m vs 67.1 m (3.2 %) |
| F2 | camp_nest_n-TavernShadow vs camp_nest_s-TavernFire | 60.8 m vs 62.7 m (3.1 %) |
| F2 | node_fire_a-well_w vs node_shadow_a-well_e | 66.7 m vs 64.6 m (3.1 %) |
| F2 | MagpieDenNorthWest-lair_hollow_e vs MagpieDenSouthEast-lair_hollow_w | 134.5 m vs 138.7 m (3.0 %) |
| F2 | tower_nw-camp_hollow_se vs tower_se-camp_hollow_nw | 134.8 m vs 130.7 m (3.0 %) |
| F2 | keep_t0-well_w vs keep_t1-well_e | 75.9 m vs 73.6 m (3.0 %) |
| F2 | node_fire_b-GreywaterLodgeSouthEast vs node_shadow_b-GreywaterLodgeNorthWest | 80.8 m vs 83.3 m (3.0 %) |
| F2 | millstone_cross-bridge_crown_e vs saltgate-bridge_crown_w | 63.8 m vs 61.9 m (3.0 %) |
| F2 | camp_nest_n-bridge_crown_w vs camp_nest_s-bridge_crown_e | 44.2 m vs 45.6 m (2.9 %) |
| F2 | ford_n-bridge_crown_w vs ford_s-bridge_crown_e | 44.2 m vs 45.6 m (2.9 %) |
| F2 | tower_nw-lair_den_e vs tower_se-lair_den_w | 111.8 m vs 108.6 m (2.9 %) |
| F2 | well_w-camp_wallow_n vs well_e-camp_wallow_s | 54.1 m vs 55.7 m (2.9 %) |
| F2 | node_fire_rich-steps_nw vs node_shadow_rich-steps_se | 43.6 m vs 44.9 m (2.9 %) |
| F2 | LostCache1-lair_heath_w vs LostCache3-lair_heath_e | 51.6 m vs 50.1 m (2.8 %) |
| F2 | node_fire_mid-camp_nest_n vs node_shadow_mid-camp_nest_s | 42.2 m vs 41.0 m (2.8 %) |
| F2 | node_fire_mid-ford_n vs node_shadow_mid-ford_s | 42.2 m vs 41.0 m (2.8 %) |
| F2 | node_fire_b-shrine_e vs node_shadow_b-shrine_w | 77.6 m vs 75.4 m (2.8 %) |
| F2 | node_fire_rich-crown vs node_shadow_rich-crown | 55.3 m vs 56.9 m (2.8 %) |
| F2 | node_fire_b-MagpieDenSouthEast vs node_shadow_b-MagpieDenNorthWest | 88.2 m vs 90.7 m (2.8 %) |
| F2 | node_fire_b-camp_hollow_se vs node_shadow_b-camp_hollow_nw | 92.4 m vs 94.9 m (2.7 %) |
| F2 | node_fire_rich-LostCache1 vs node_shadow_rich-LostCache3 | 77.3 m vs 75.2 m (2.7 %) |
| F2 | keep_t0-shrine_e vs keep_t1-shrine_w | 77.0 m vs 74.9 m (2.6 %) |
| F2 | node_fire_b-lair_heath_w vs node_shadow_b-lair_heath_e | 37.7 m vs 38.7 m (2.6 %) |
| F2 | node_fire_rich-ford_s vs node_shadow_rich-ford_n | 92.5 m vs 90.2 m (2.6 %) |
| F2 | node_fire_rich-camp_nest_s vs node_shadow_rich-camp_nest_n | 92.5 m vs 90.2 m (2.6 %) |
| F2 | node_fire_b-lair_hollow_e vs node_shadow_b-lair_hollow_w | 95.0 m vs 97.5 m (2.5 %) |
| F2 | camp_hollow_nw-LostCache3 vs camp_hollow_se-LostCache1 | 72.0 m vs 70.2 m (2.5 %) |
| F2 | node_fire_rich-TavernShadow vs node_shadow_rich-TavernFire | 79.6 m vs 81.6 m (2.4 %) |
| F2 | node_fire_a-steps_se vs node_shadow_a-steps_nw | 62.9 m vs 61.3 m (2.4 %) |
| F2 | node_fire_rich-steps_se vs node_shadow_rich-steps_nw | 68.0 m vs 69.7 m (2.3 %) |
| F2 | LostCache0-lair_crag_e vs LostCache2-lair_crag_w | 86.2 m vs 88.3 m (2.3 %) |
| F2 | camp_hollow_nw-bridge_crown_w vs camp_hollow_se-bridge_crown_e | 88.8 m vs 90.8 m (2.2 %) |
| F2 | tower_nw-heron_ford vs tower_se-lantern_wharf | 45.1 m vs 44.1 m (2.2 %) |
| F2 | bridge_road_n-bridge_crown_w vs bridge_road_s-bridge_crown_e | 58.8 m vs 60.1 m (2.2 %) |
| F2 | camp_wallow_s-TavernFire vs camp_wallow_n-TavernShadow | 79.7 m vs 78.1 m (2.1 %) |
| F2 | node_fire_rich-millstone_cross vs node_shadow_rich-saltgate | 99.2 m vs 97.1 m (2.1 %) |
| F2 | node_fire_rich-well_e vs node_shadow_rich-well_w | 96.8 m vs 98.8 m (2.0 %) |
| F2 | node_fire_mid-camp_hollow_nw vs node_shadow_mid-camp_hollow_se | 73.5 m vs 72.0 m (2.0 %) |
| F2 | lair_den_w-bridge_crown_w vs lair_den_e-bridge_crown_e | 66.6 m vs 68.0 m (2.0 %) |
| F2 | heron_ford-saltgate vs lantern_wharf-millstone_cross | 73.9 m vs 72.4 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 59 sources) 34.52 s.
- Map Lab v2 (map-production.md 2.5): layout crown_hollow_level, 2 seats, rules tempo standard, 2 fixable findings.
- Navmesh raster 1.26 s (1356 polygons, 230400 cells of 0.25 m), spot / mirror checks 0.51 s, 1711 paths 0.74 s.
- Map Crown Hollow (1v1), scene res://docs/tools/world_forge/out/crown_hollow_level/preview.tscn, sim mode on; level load + navmesh bake 28.7 s (12 frames), lab 37.5 s. Spec: docs/design/skirmish-1v1.md,.
