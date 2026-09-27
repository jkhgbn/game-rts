# Map Lab: Kinhearth Vale (2v2) scorecard: world_forge_kinhearth_vale

2026-09-27 14:53 · lab v1.0 · 130.45 s · scanned 89 spots

## Result: **WARN** · score **90 / 100**

0 FAIL · 3 WARN · 11 PASS · 1 info checks; findings: 0 FAIL, 192 WARN, 127 info

## Improve next
1. **Map geometry: path pairs match their mirror twins** (WARN): keep_t0-corner_post_a1 vs keep_t1-corner_post_b1: 39.8 m vs 40.8 m (2.4 %) -> keep_t1-corner_post_b1 is longer: look for an unmirrored collider on that route (heat map, M3 tiles) (find the unmirrored obstacle on the longer route) _(from F1 5869 / 5870 pairs within 2 % (0 FAIL, 1 WARN, 0 info))_
2. **Unit paths (NavigationServer): pairs match their twins** (WARN): node_b_b1-causeway_w vs node_b_b2-causeway_w: 80.0 m vs 101.8 m (21.4 %) -> units walk node_b_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) (engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it) _(from F2 5558 / 5870 pairs within 2 % (0 FAIL, 190 WARN, 122 info))_
3. **Keep to nearest camp / point / expansion... equal per seat** (WARN): nearest post: 37.3 m vs 38.1 m between seats (2.2 %) -> move the far seat's spot closer (or check its route for a blocker) _(from D1 9 / 10 clean (0 FAIL, 1 WARN))_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 208 polygons, main area 29543 m² (95 % of the 176 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 89 / 89 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 4 / 4 clean, 5 info | ground-level components other than the main one < 2 m² |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 89 / 89 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 89 / 89 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (0 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | **WARN** 69 | 5869 / 5870 pairs within 2 % (0 FAIL, 1 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) | find the unmirrored obstacle on the longer route |
| F2 | Unit paths (NavigationServer): pairs match their twins | **WARN** 68 | 5558 / 5870 pairs within 2 % (0 FAIL, 190 WARN, 122 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side | engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | **WARN** 66 | 9 / 10 clean (0 FAIL, 1 WARN) | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps: equal, close, on their bank | PASS 100 | 4 / 4 clean | ally path equal per side (<= 2 %), <= 1.25 x the nearest enemy keep |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 7 / 7 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | PASS 100 | 6 / 6 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 12 / 12 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (704 x 704 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | F1 | keep_t0-corner_post_a1 vs keep_t1-corner_post_b1 | 39.8 m vs 40.8 m (2.4 %) | keep_t1-corner_post_b1 is longer: look for an unmirrored collider on that route (heat map, M3 tiles) |
| WARN | F2 | node_b_b1-causeway_w vs node_b_b2-causeway_w | 80.0 m vs 101.8 m (21.4 %) | units walk node_b_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-causeway_e vs node_b_b2-causeway_w | 80.0 m vs 101.8 m (21.4 %) | units walk node_b_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-causeway_e vs node_b_b2-causeway_w | 80.0 m vs 101.8 m (21.4 %) | units walk node_b_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-corner_post_a1 vs keep_t4-corner_post_a2 | 180.7 m vs 224.5 m (19.5 %) | units walk keep_t4-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-corner_post_b2 vs keep_t4-corner_post_a2 | 180.8 m vs 224.5 m (19.5 %) | units walk keep_t4-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-corner_post_b1 vs keep_t1-corner_post_a1 | 224.2 m vs 180.7 m (19.4 %) | units walk keep_t0-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-corner_post_b1 vs keep_t3-corner_post_b2 | 224.2 m vs 180.8 m (19.4 %) | units walk keep_t0-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-node_b_a1 vs keep_t4-node_b_b1 | 59.3 m vs 72.8 m (18.6 %) | units walk keep_t4-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-node_b_b2 vs keep_t4-node_b_b1 | 59.3 m vs 72.8 m (18.6 %) | units walk keep_t4-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_a2 vs keep_t3-node_b_a1 | 72.5 m vs 59.3 m (18.3 %) | units walk keep_t0-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_a2 vs keep_t1-node_b_b2 | 72.5 m vs 59.3 m (18.3 %) | units walk keep_t0-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_a1 vs node_a_b2-node_b_b1 | 55.1 m vs 67.1 m (17.9 %) | units walk node_a_b2-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-node_b_b2 vs node_a_b2-node_b_b1 | 55.1 m vs 67.1 m (17.9 %) | units walk node_a_b2-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-tavern_a1 vs node_b_b2-tavern_a2 | 97.3 m vs 118.6 m (17.9 %) | units walk node_b_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-tavern_b1 vs node_b_b2-tavern_a2 | 97.4 m vs 118.6 m (17.9 %) | units walk node_b_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-tavern_b2 vs node_b_b2-tavern_a2 | 97.4 m vs 118.6 m (17.9 %) | units walk node_b_b2-tavern_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_a2-node_b_a1 | 66.9 m vs 55.1 m (17.6 %) | units walk node_a_a1-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_a2 vs node_a_b1-node_b_b2 | 66.9 m vs 55.1 m (17.6 %) | units walk node_a_a1-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-corner_post_a1 vs node_a_b2-corner_post_a2 | 183.1 m vs 218.8 m (16.3 %) | units walk node_a_b2-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-well_b1 vs node_b_b1-well_a1 | 136.6 m vs 114.3 m (16.3 %) | units walk node_b_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-well_b1 vs node_b_a2-well_b2 | 136.6 m vs 114.3 m (16.3 %) | units walk node_b_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-corner_post_b2 vs node_a_b2-corner_post_a2 | 183.2 m vs 218.8 m (16.3 %) | units walk node_a_b2-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-corner_post_b1 vs node_a_b1-corner_post_a1 | 218.5 m vs 183.1 m (16.2 %) | units walk node_a_a1-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-well_a1 vs node_b_b2-well_a2 | 114.3 m vs 136.4 m (16.2 %) | units walk node_b_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-well_b2 vs node_b_b2-well_a2 | 114.3 m vs 136.4 m (16.2 %) | units walk node_b_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-corner_post_b1 vs node_a_a2-corner_post_b2 | 218.5 m vs 183.2 m (16.2 %) | units walk node_a_a1-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a1-causeway_e vs cache_b1-causeway_w | 92.9 m vs 78.6 m (15.4 %) | units walk cache_a1-causeway_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a1-causeway_e vs cache_a2-causeway_e | 92.9 m vs 78.6 m (15.4 %) | units walk cache_a1-causeway_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b1-causeway_w vs cache_b2-causeway_w | 78.6 m vs 92.7 m (15.3 %) | units walk cache_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a2-causeway_e vs cache_b2-causeway_w | 78.6 m vs 92.7 m (15.2 %) | units walk cache_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-corner_post_a2 vs well_b2-corner_post_a1 | 119.1 m vs 138.2 m (13.8 %) | units walk well_b2-corner_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-corner_post_b2 vs well_b2-corner_post_a1 | 119.1 m vs 138.2 m (13.8 %) | units walk well_b2-corner_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-corner_post_b1 vs well_b1-corner_post_a2 | 137.9 m vs 119.1 m (13.6 %) | units walk well_a2-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-corner_post_b2 vs well_a2-corner_post_b1 | 119.1 m vs 137.9 m (13.6 %) | units walk well_a2-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | vale_watch_a1-corner_post_a2 vs vale_watch_b1-corner_post_b2 | 136.3 m vs 156.4 m (12.8 %) | units walk vale_watch_b1-corner_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | vale_watch_b1-corner_post_b2 vs vale_watch_b2-corner_post_b1 | 156.4 m vs 136.4 m (12.8 %) | units walk vale_watch_b1-corner_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | vale_watch_a1-corner_post_a2 vs vale_watch_a2-corner_post_a1 | 136.3 m vs 156.2 m (12.7 %) | units walk vale_watch_a2-corner_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | vale_watch_a2-corner_post_a1 vs vale_watch_b2-corner_post_b1 | 156.2 m vs 136.4 m (12.7 %) | units walk vale_watch_a2-corner_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a2-bridge_nest_b2 vs stag_b2-bridge_nest_a2 | 125.1 m vs 109.3 m (12.6 %) | units walk stag_a2-bridge_nest_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-bridge_nest_b1 vs stag_a2-bridge_nest_b2 | 109.4 m vs 125.1 m (12.6 %) | units walk stag_a2-bridge_nest_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_b1-bridge_nest_a1 vs stag_b2-bridge_nest_a2 | 125.0 m vs 109.3 m (12.5 %) | units walk stag_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | stag_a1-bridge_nest_b1 vs stag_b1-bridge_nest_a1 | 109.4 m vs 125.0 m (12.5 %) | units walk stag_b1-bridge_nest_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_b1-cache_a1 vs tavern_b2-cache_a2 | 95.9 m vs 109.6 m (12.4 %) | units walk tavern_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a2-cache_b2 vs tavern_b2-cache_a2 | 96.0 m vs 109.6 m (12.4 %) | units walk tavern_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-cache_b1 vs tavern_b1-cache_a1 | 109.4 m vs 95.9 m (12.3 %) | units walk tavern_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-cache_b1 vs tavern_a2-cache_b2 | 109.4 m vs 96.0 m (12.3 %) | units walk tavern_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-mouth_lair_a1 vs keep_t4-mouth_lair_b1 | 121.8 m vs 138.5 m (12.0 %) | units walk keep_t4-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-mouth_lair_b2 vs keep_t4-mouth_lair_b1 | 121.8 m vs 138.5 m (12.0 %) | units walk keep_t4-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-mouth_lair_a2 vs keep_t3-mouth_lair_a1 | 138.2 m vs 121.8 m (11.9 %) | units walk keep_t0-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-mouth_lair_a2 vs keep_t1-mouth_lair_b2 | 138.2 m vs 121.8 m (11.9 %) | units walk keep_t0-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_b1-corner_post_b2 vs bridge_nest_b2-corner_post_b1 | 164.3 m vs 144.8 m (11.9 %) | units walk bridge_nest_b1-corner_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-corner_post_a2 vs bridge_nest_b2-corner_post_b1 | 164.2 m vs 144.8 m (11.8 %) | units walk bridge_nest_a1-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a2-corner_post_a1 vs bridge_nest_b2-corner_post_b1 | 164.1 m vs 144.8 m (11.8 %) | units walk bridge_nest_a2-corner_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a2-corner_post_a2 vs tavern_b2-corner_post_b2 | 71.2 m vs 80.4 m (11.4 %) | units walk tavern_b2-corner_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_b1-corner_post_b1 vs tavern_b2-corner_post_b2 | 71.2 m vs 80.4 m (11.4 %) | units walk tavern_b2-corner_post_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-cache_a1 vs well_b2-cache_a2 | 112.9 m vs 127.4 m (11.4 %) | units walk well_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-cache_b2 vs well_b2-cache_a2 | 113.0 m vs 127.4 m (11.4 %) | units walk well_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_b1 vs well_b1-cache_a1 | 127.3 m vs 112.9 m (11.3 %) | units walk well_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-corner_post_a1 vs tavern_a2-corner_post_a2 | 80.3 m vs 71.2 m (11.3 %) | units walk tavern_a1-corner_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | tavern_a1-corner_post_a1 vs tavern_b1-corner_post_b1 | 80.3 m vs 71.2 m (11.3 %) | units walk tavern_a1-corner_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-cache_b1 vs well_a2-cache_b2 | 127.3 m vs 113.0 m (11.3 %) | units walk well_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-causeway_e vs corner_post_b1-causeway_w | 127.1 m vs 113.2 m (11.0 %) | units walk corner_post_a1-causeway_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-node_b_b1 vs node_b_b2-node_b_a2 | 152.0 m vs 135.4 m (10.9 %) | units walk node_b_a1-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_b1-causeway_w vs corner_post_b2-causeway_w | 113.2 m vs 127.0 m (10.9 %) | units walk corner_post_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fordwatch_a2-mouth_lair_b2 vs fordwatch_b2-mouth_lair_a2 | 135.1 m vs 121.0 m (10.5 %) | units walk fordwatch_a2-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fordwatch_b1-mouth_lair_a1 vs fordwatch_b2-mouth_lair_a2 | 135.0 m vs 121.0 m (10.4 %) | units walk fordwatch_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fordwatch_a1-mouth_lair_b1 vs fordwatch_a2-mouth_lair_b2 | 121.1 m vs 135.1 m (10.4 %) | units walk fordwatch_a2-mouth_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | fordwatch_a1-mouth_lair_b1 vs fordwatch_b1-mouth_lair_a1 | 121.1 m vs 135.0 m (10.3 %) | units walk fordwatch_b1-mouth_lair_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-mouth_lair_b2 vs node_a_b2-mouth_lair_b1 | 119.5 m vs 132.8 m (10.0 %) | units walk node_a_b2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_a1 vs node_a_b2-mouth_lair_b1 | 119.5 m vs 132.8 m (10.0 %) | units walk node_a_b2-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a2 vs node_a_b1-mouth_lair_b2 | 132.6 m vs 119.5 m (9.9 %) | units walk node_a_a1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a2 vs node_a_a2-mouth_lair_a1 | 132.6 m vs 119.5 m (9.9 %) | units walk node_a_a1-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-shrine_b1 vs node_b_b1-shrine_a1 | 109.6 m vs 99.1 m (9.6 %) | units walk node_b_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-shrine_b1 vs node_b_a2-shrine_b1 | 109.6 m vs 99.1 m (9.5 %) | units walk node_b_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-shrine_a1 vs node_b_b2-shrine_a1 | 99.1 m vs 109.5 m (9.5 %) | units walk node_b_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-shrine_b1 vs node_b_b2-shrine_a1 | 99.1 m vs 109.5 m (9.4 %) | units walk node_b_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-mouth_lair_b2 vs corner_post_b2-mouth_lair_a2 | 169.2 m vs 186.8 m (9.4 %) | units walk corner_post_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_b1-vale_lair_b2 vs cache_b2-vale_lair_b1 | 122.1 m vs 134.7 m (9.3 %) | units walk cache_b2-vale_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a2-vale_lair_a1 vs cache_b2-vale_lair_b1 | 122.1 m vs 134.7 m (9.3 %) | units walk cache_b2-vale_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_b1-mouth_lair_a1 vs corner_post_b2-mouth_lair_a2 | 169.3 m vs 186.8 m (9.3 %) | units walk corner_post_b2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-mouth_lair_b1 vs corner_post_a2-mouth_lair_b2 | 186.6 m vs 169.2 m (9.3 %) | units walk corner_post_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-mouth_lair_b1 vs corner_post_b1-mouth_lair_a1 | 186.6 m vs 169.3 m (9.3 %) | units walk corner_post_a1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a1-vale_lair_a2 vs cache_b1-vale_lair_b2 | 134.5 m vs 122.1 m (9.2 %) | units walk cache_a1-vale_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a1-vale_lair_a2 vs cache_a2-vale_lair_a1 | 134.5 m vs 122.1 m (9.2 %) | units walk cache_a1-vale_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-cache_a1 vs corner_post_b2-cache_b1 | 104.8 m vs 115.2 m (9.1 %) | units walk corner_post_b2-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_b1-cache_b2 vs corner_post_b2-cache_b1 | 104.8 m vs 115.2 m (9.1 %) | units walk corner_post_b2-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-cache_a2 vs corner_post_a2-cache_a1 | 115.0 m vs 104.8 m (8.9 %) | units walk corner_post_a1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-cache_a2 vs corner_post_b1-cache_b2 | 115.0 m vs 104.8 m (8.9 %) | units walk corner_post_a1-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-node_b_a1 vs keep_t4-node_b_a2 | 139.2 m vs 152.7 m (8.8 %) | units walk keep_t4-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-node_b_b2 vs keep_t4-node_b_a2 | 139.2 m vs 152.7 m (8.8 %) | units walk keep_t4-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_b1 vs keep_t1-node_b_a1 | 152.6 m vs 139.2 m (8.8 %) | units walk keep_t0-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-node_b_b1 vs keep_t3-node_b_b2 | 152.6 m vs 139.2 m (8.8 %) | units walk keep_t0-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | cache_a1-cache_b1 vs cache_b2-cache_a2 | 145.3 m vs 132.6 m (8.8 %) | units walk cache_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b1 vs well_b1-shrine_a1 | 85.3 m vs 78.1 m (8.4 %) | units walk well_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-shrine_b1 vs well_a2-shrine_b1 | 85.3 m vs 78.1 m (8.4 %) | units walk well_a1-shrine_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-den_b1 vs corner_post_b2-den_a1 | 190.6 m vs 174.6 m (8.4 %) | units walk corner_post_a2-den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-den_b1 vs corner_post_a2-den_b1 | 174.6 m vs 190.6 m (8.4 %) | units walk corner_post_a2-den_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-shrine_a1 vs well_b2-shrine_a1 | 78.1 m vs 85.2 m (8.4 %) | units walk well_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-shrine_b1 vs well_b2-shrine_a1 | 78.1 m vs 85.2 m (8.3 %) | units walk well_b2-shrine_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_b1 vs peddler_b1-cache_a1 | 164.9 m vs 151.4 m (8.2 %) | units walk peddler_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_b1 vs peddler_b2-cache_a2 | 164.9 m vs 151.4 m (8.1 %) | units walk peddler_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | peddler_a1-cache_b1 vs peddler_a2-cache_b2 | 164.9 m vs 151.5 m (8.1 %) | units walk peddler_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-stag_b1 vs keep_t3-stag_b2 | 111.5 m vs 121.3 m (8.1 %) | units walk keep_t3-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-stag_b1 vs keep_t1-stag_a1 | 111.5 m vs 121.3 m (8.1 %) | units walk keep_t1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-causeway_e vs natural_a2-causeway_e | 84.0 m vs 77.2 m (8.0 %) | units walk natural_a1-causeway_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-stag_b2 vs keep_t4-stag_a2 | 121.3 m vs 111.6 m (8.0 %) | units walk keep_t3-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-stag_a1 vs keep_t4-stag_a2 | 121.3 m vs 111.6 m (8.0 %) | units walk keep_t1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-well_a1 vs keep_t4-well_a2 | 118.1 m vs 128.4 m (8.0 %) | units walk keep_t4-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-well_b2 vs keep_t4-well_a2 | 118.1 m vs 128.4 m (8.0 %) | units walk keep_t4-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-causeway_e vs natural_b2-causeway_w | 77.2 m vs 83.8 m (7.8 %) | units walk natural_b2-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-lodge_b1 vs corner_post_b2-lodge_a1 | 166.6 m vs 153.7 m (7.7 %) | units walk corner_post_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-causeway_e vs natural_b1-causeway_w | 77.2 m vs 83.7 m (7.7 %) | units walk natural_b1-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_b1-crown vs corner_post_b2-crown | 100.7 m vs 109.2 m (7.7 %) | units walk corner_post_b2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-lodge_b1 vs corner_post_a2-lodge_b1 | 153.8 m vs 166.6 m (7.7 %) | units walk corner_post_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-crown vs corner_post_b2-crown | 100.8 m vs 109.2 m (7.7 %) | units walk corner_post_b2-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-crown vs corner_post_b1-crown | 109.0 m vs 100.7 m (7.6 %) | units walk corner_post_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-causeway_w vs corner_post_b2-causeway_e | 90.2 m vs 97.6 m (7.6 %) | units walk corner_post_b2-causeway_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_b1-causeway_e vs corner_post_b2-causeway_e | 90.2 m vs 97.6 m (7.6 %) | units walk corner_post_b2-causeway_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b1 vs wallow_b1-cache_a1 | 175.5 m vs 162.2 m (7.6 %) | units walk wallow_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | vale_watch_a1-vale_watch_b2 vs vale_watch_a2-vale_watch_b1 | 42.0 m vs 38.8 m (7.6 %) | units walk vale_watch_a1-vale_watch_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-crown vs corner_post_a2-crown | 109.0 m vs 100.8 m (7.6 %) | units walk corner_post_a1-crown the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b1 vs wallow_b2-cache_a2 | 175.5 m vs 162.3 m (7.6 %) | units walk wallow_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | wallow_a1-cache_b1 vs wallow_a2-cache_b2 | 175.5 m vs 162.3 m (7.5 %) | units walk wallow_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-causeway_w vs corner_post_a2-causeway_w | 97.4 m vs 90.2 m (7.5 %) | units walk corner_post_a1-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-causeway_w vs corner_post_b1-causeway_e | 97.4 m vs 90.2 m (7.5 %) | units walk corner_post_a1-causeway_w the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-well_b1 vs keep_t4-well_a2 | 118.8 m vs 128.4 m (7.4 %) | units walk keep_t4-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_b1-cache_a1 vs corner_post_b2-cache_a2 | 167.2 m vs 179.9 m (7.1 %) | units walk corner_post_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-cache_b1 vs corner_post_b1-cache_a1 | 179.8 m vs 167.2 m (7.0 %) | units walk corner_post_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-vale_post_b1 vs natural_b1-vale_post_a1 | 159.2 m vs 171.1 m (7.0 %) | units walk natural_b1-vale_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a2-vale_post_b2 vs natural_b1-vale_post_a1 | 159.2 m vs 171.1 m (7.0 %) | units walk natural_b1-vale_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_b1-vale_post_a1 vs natural_b2-vale_post_a2 | 171.1 m vs 159.3 m (6.9 %) | units walk natural_b1-vale_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-causeway_e vs corner_post_b1-causeway_w | 121.5 m vs 113.2 m (6.9 %) | units walk corner_post_a2-causeway_e the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-cache_b1 vs natural_b1-cache_a1 | 146.2 m vs 136.4 m (6.7 %) | units walk natural_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-node_b_b2 vs node_a_b2-node_b_a2 | 141.6 m vs 151.6 m (6.7 %) | units walk node_a_b2-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-node_b_a1 vs node_a_b2-node_b_a2 | 141.6 m vs 151.6 m (6.7 %) | units walk node_a_b2-node_b_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-cache_b2 vs bridge_nest_a2-cache_b1 | 74.7 m vs 69.8 m (6.6 %) | units walk bridge_nest_a1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-cache_b1 vs natural_b2-cache_a2 | 146.2 m vs 136.5 m (6.6 %) | units walk natural_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_b1 vs node_a_a2-node_b_b2 | 151.6 m vs 141.6 m (6.6 %) | units walk node_a_a1-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-node_b_b1 vs node_a_b1-node_b_a1 | 151.6 m vs 141.6 m (6.6 %) | units walk node_a_a1-node_b_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | natural_a1-cache_b1 vs natural_a2-cache_b2 | 146.2 m vs 136.5 m (6.6 %) | units walk natural_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-green_cache_b1 vs corner_post_b2-green_cache_a1 | 152.7 m vs 142.8 m (6.5 %) | units walk corner_post_a2-green_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-corner_post_b1 vs node_b_b1-corner_post_a1 | 189.1 m vs 176.9 m (6.5 %) | units walk node_b_a1-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-cache_b2 vs bridge_nest_b1-cache_a2 | 74.7 m vs 69.9 m (6.5 %) | units walk bridge_nest_a1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a1-green_cache_b1 vs corner_post_a2-green_cache_b1 | 142.8 m vs 152.7 m (6.4 %) | units walk corner_post_a2-green_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-corner_post_a1 vs node_b_b2-corner_post_a2 | 176.9 m vs 188.9 m (6.4 %) | units walk node_b_b2-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-corner_post_b1 vs node_b_a2-corner_post_b2 | 189.1 m vs 177.0 m (6.4 %) | units walk node_b_a1-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-cache_a1 vs node_b_b2-cache_a2 | 133.9 m vs 143.1 m (6.4 %) | units walk node_b_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-cache_b2 vs node_b_b2-cache_a2 | 134.0 m vs 143.1 m (6.4 %) | units walk node_b_b2-cache_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-cache_b1 vs node_b_b1-cache_a1 | 143.0 m vs 133.9 m (6.3 %) | units walk node_b_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-cache_b1 vs node_b_a2-cache_b2 | 143.0 m vs 134.0 m (6.3 %) | units walk node_b_a1-cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-corner_post_b2 vs node_b_b2-corner_post_a2 | 177.0 m vs 188.9 m (6.3 %) | units walk node_b_b2-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t3-peddler_a1 vs keep_t4-peddler_b1 | 91.3 m vs 97.4 m (6.2 %) | units walk keep_t4-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t1-peddler_b2 vs keep_t4-peddler_b1 | 91.3 m vs 97.4 m (6.2 %) | units walk keep_t4-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | bridge_nest_a1-cache_b2 vs bridge_nest_b2-cache_a1 | 74.7 m vs 70.1 m (6.2 %) | units walk bridge_nest_a1-cache_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-vale_lair_a1 vs node_a_b2-vale_lair_b2 | 57.1 m vs 60.8 m (6.1 %) | units walk node_a_b2-vale_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-vale_lair_a2 vs node_a_b2-vale_lair_b2 | 57.1 m vs 60.8 m (6.1 %) | units walk node_a_b2-vale_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-rich_b1 vs node_a_b2-rich_b2 | 73.9 m vs 69.4 m (6.1 %) | units walk node_a_b1-rich_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-vale_lair_b1 vs node_a_b2-vale_lair_b2 | 57.1 m vs 60.8 m (6.1 %) | units walk node_a_b2-vale_lair_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-tavern_b2 vs node_a_a2-tavern_b1 | 109.0 m vs 102.4 m (6.1 %) | units walk node_a_a1-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-rich_a1 vs node_a_b1-rich_b1 | 69.4 m vs 73.9 m (6.0 %) | units walk node_a_b1-rich_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-tavern_b2 vs node_a_b1-tavern_a2 | 109.0 m vs 102.4 m (6.0 %) | units walk node_a_a1-tavern_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-rich_a2 vs node_a_b1-rich_b1 | 69.4 m vs 73.9 m (6.0 %) | units walk node_a_b1-rich_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-tavern_b1 vs node_a_b2-tavern_a1 | 102.4 m vs 108.9 m (6.0 %) | units walk node_a_b2-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-tavern_a2 vs node_a_b2-tavern_a1 | 102.4 m vs 108.9 m (6.0 %) | units walk node_a_b2-tavern_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | keep_t0-peddler_a2 vs keep_t4-peddler_b1 | 91.9 m vs 97.4 m (5.6 %) | units walk keep_t4-peddler_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-stag_b1 vs node_b_a2-stag_b2 | 110.9 m vs 117.6 m (5.6 %) | units walk node_b_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-stag_b1 vs node_b_b1-stag_a1 | 110.9 m vs 117.5 m (5.6 %) | units walk node_b_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-vale_post_a1 vs node_a_b2-vale_post_a2 | 164.9 m vs 155.6 m (5.6 %) | units walk node_a_b1-vale_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-vale_post_b2 vs node_a_b1-vale_post_a1 | 155.6 m vs 164.9 m (5.6 %) | units walk node_a_b1-vale_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-vale_post_b1 vs node_a_b1-vale_post_a1 | 155.6 m vs 164.9 m (5.6 %) | units walk node_a_b1-vale_post_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-green_cache_b1 vs node_b_b1-green_cache_a1 | 117.6 m vs 111.1 m (5.6 %) | units walk node_b_a1-green_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-stag_b2 vs node_b_b2-stag_a2 | 117.6 m vs 111.0 m (5.6 %) | units walk node_b_a2-stag_b2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a1-green_cache_b1 vs node_b_a2-green_cache_b1 | 117.6 m vs 111.1 m (5.6 %) | units walk node_b_a1-green_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-stag_a1 vs node_b_b2-stag_a2 | 117.5 m vs 111.0 m (5.5 %) | units walk node_b_b1-stag_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_b1-green_cache_a1 vs node_b_b2-green_cache_a1 | 111.1 m vs 117.6 m (5.5 %) | units walk node_b_b2-green_cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_b_a2-green_cache_b1 vs node_b_b2-green_cache_a1 | 111.1 m vs 117.6 m (5.5 %) | units walk node_b_b2-green_cache_a1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-green_cache_b1 vs corner_post_b1-green_cache_a1 | 152.7 m vs 144.3 m (5.5 %) | units walk corner_post_a2-green_cache_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-corner_post_b1 vs well_b1-corner_post_a1 | 164.8 m vs 155.9 m (5.4 %) | units walk well_a1-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-well_b2 vs node_a_b2-well_a2 | 120.5 m vs 127.4 m (5.4 %) | units walk node_a_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-well_a1 vs node_a_b2-well_a2 | 120.5 m vs 127.4 m (5.4 %) | units walk node_a_b2-well_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_b1-corner_post_a1 vs well_b2-corner_post_a2 | 155.9 m vs 164.7 m (5.3 %) | units walk well_b2-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-well_b1 vs node_a_a2-well_b2 | 127.3 m vs 120.5 m (5.3 %) | units walk node_a_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-well_b1 vs node_a_b1-well_a1 | 127.3 m vs 120.5 m (5.3 %) | units walk node_a_a1-well_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a1-corner_post_b1 vs well_a2-corner_post_b2 | 164.8 m vs 156.1 m (5.3 %) | units walk well_a1-corner_post_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_b1-mouth_lair_b1 vs node_a_b2-mouth_lair_b2 | 91.1 m vs 86.3 m (5.3 %) | units walk node_a_b1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a1 vs node_a_b1-mouth_lair_b1 | 86.3 m vs 91.1 m (5.2 %) | units walk node_a_b1-mouth_lair_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | well_a2-corner_post_b2 vs well_b2-corner_post_a2 | 156.1 m vs 164.7 m (5.2 %) | units walk well_b2-corner_post_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | corner_post_a2-lodge_b1 vs corner_post_b1-lodge_a1 | 166.6 m vs 158.3 m (5.0 %) | units walk corner_post_a2-lodge_b1 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a2-mouth_lair_a2 vs node_a_b2-mouth_lair_b2 | 90.8 m vs 86.3 m (5.0 %) | units walk node_a_a2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | F2 | node_a_a1-mouth_lair_a1 vs node_a_a2-mouth_lair_a2 | 86.3 m vs 90.8 m (5.0 %) | units walk node_a_a2-mouth_lair_a2 the long way: the engine's polygon path, not the map (see F1) |
| WARN | D1 | nearest post | 37.3 m vs 38.1 m between seats (2.2 %) | move the far seat's spot closer (or check its route for a blocker) |

## Spot navmesh points (mirror_x)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-68.0, 30.0) | (-67.1, 26.4) | keep_t4 | (-67.1, 26.4) | 0.0 |
| keep_t3 | keep | (-68.0, -30.0) | (-66.6, -25.9) | keep_t1 | (-66.6, -25.9) | 0.0 |
| keep_t1 | keep | (68.0, -30.0) | (66.6, -25.9) | keep_t3 | (66.6, -25.9) | 0.0 |
| keep_t4 | keep | (68.0, 30.0) | (67.1, 26.4) | keep_t0 | (67.1, 26.4) | 0.0 |
| node_a_a1 | home_node | (-71.0, 21.0) | (-70.9, 20.9) | node_a_b2 | (-70.9, 20.9) | 0.0 |
| node_a_a2 | home_node | (-71.0, -21.0) | (-70.9, -20.9) | node_a_b1 | (-70.9, -20.9) | 0.0 |
| node_a_b1 | home_node | (71.0, -21.0) | (70.9, -20.9) | node_a_a2 | (70.9, -20.9) | 0.0 |
| node_a_b2 | home_node | (71.0, 21.0) | (70.9, 20.9) | node_a_a1 | (70.9, 20.9) | 0.0 |
| node_b_a1 | home_node | (-59.0, 33.0) | (-58.9, 32.9) | node_b_b2 | (-58.9, 32.9) | 0.0 |
| node_b_a2 | home_node | (-59.0, -33.0) | (-58.9, -32.9) | node_b_b1 | (-58.9, -32.9) | 0.0 |
| node_b_b1 | home_node | (59.0, -33.0) | (58.9, -32.9) | node_b_a2 | (58.9, -32.9) | 0.0 |
| node_b_b2 | home_node | (59.0, 33.0) | (58.9, 32.9) | node_b_a1 | (58.9, 32.9) | 0.0 |
| natural_a1 | expansion | (-40.0, 48.0) | (-39.9, 47.9) | natural_b2 | (-39.9, 47.9) | 0.0 |
| natural_a2 | expansion | (-40.0, -48.0) | (-39.9, -47.9) | natural_b1 | (-39.9, -47.9) | 0.0 |
| natural_b1 | expansion | (40.0, -48.0) | (39.9, -47.9) | natural_a2 | (39.9, -47.9) | 0.0 |
| natural_b2 | expansion | (40.0, 48.0) | (39.9, 47.9) | natural_a1 | (39.9, 47.9) | 0.0 |
| rich_a1 | expansion | (-24.0, 72.0) | (-23.9, 71.9) | rich_b2 | (-23.9, 71.9) | 0.0 |
| rich_a2 | expansion | (-24.0, -72.0) | (-23.9, -71.9) | rich_b1 | (-23.9, -71.9) | 0.0 |
| rich_b1 | expansion | (24.0, -72.0) | (23.9, -71.9) | rich_a2 | (23.9, -71.9) | 0.0 |
| rich_b2 | expansion | (24.0, 72.0) | (23.9, 71.9) | rich_a1 | (23.9, 71.9) | 0.0 |
| vale_watch_a1 | point | (-12.0, 58.0) | (-11.9, 57.9) | vale_watch_b2 | (-11.9, 57.9) | 0.0 |
| vale_watch_a2 | point | (-12.0, -58.0) | (-11.9, -57.9) | vale_watch_b1 | (-11.9, -57.9) | 0.0 |
| vale_watch_b1 | point | (12.0, -58.0) | (11.9, -57.9) | vale_watch_a2 | (11.9, -57.9) | 0.0 |
| vale_watch_b2 | point | (12.0, 58.0) | (11.9, 57.9) | vale_watch_a1 | (11.9, 57.9) | 0.0 |
| well_a1 | point | (-34.0, 30.0) | (-33.9, 29.9) | well_b2 | (-33.9, 29.9) | 0.0 |
| well_a2 | point | (-34.0, -30.0) | (-33.9, -29.9) | well_b1 | (-33.9, -29.9) | 0.0 |
| well_b1 | point | (34.0, -30.0) | (33.9, -29.9) | well_a2 | (33.9, -29.9) | 0.0 |
| well_b2 | point | (34.0, 30.0) | (33.9, 29.9) | well_a1 | (33.9, 29.9) | 0.0 |
| fordwatch_a1 | point | (-9.0, 33.0) | (-8.9, 32.9) | fordwatch_b2 | (-8.9, 32.9) | 0.0 |
| fordwatch_a2 | point | (-9.0, -33.0) | (-8.9, -32.9) | fordwatch_b1 | (-8.9, -32.9) | 0.0 |
| fordwatch_b1 | point | (9.0, -33.0) | (8.9, -32.9) | fordwatch_a2 | (8.9, -32.9) | 0.0 |
| fordwatch_b2 | point | (9.0, 33.0) | (8.9, 32.9) | fordwatch_a1 | (8.9, 32.9) | 0.0 |
| shrine_a1 | point | (-32.0, 0.0) | (-31.9, 0.1) | shrine_b1 | (-31.9, 0.1) | 0.0 |
| shrine_b1 | point | (32.0, 0.0) | (31.9, 0.1) | shrine_a1 | (31.9, 0.1) | 0.0 |
| wallow_a1 | camp | (-58.0, 72.0) | (-57.9, 71.9) | wallow_b2 | (-57.9, 71.9) | 0.0 |
| wallow_a2 | camp | (-58.0, -72.0) | (-57.9, -71.9) | wallow_b1 | (-57.9, -71.9) | 0.0 |
| wallow_b1 | camp | (58.0, -72.0) | (57.9, -71.9) | wallow_a2 | (57.9, -71.9) | 0.0 |
| wallow_b2 | camp | (58.0, 72.0) | (57.9, 71.9) | wallow_a1 | (57.9, 71.9) | 0.0 |
| stag_a1 | camp | (-18.0, 40.0) | (-17.9, 39.9) | stag_b2 | (-17.9, 39.9) | 0.0 |
| stag_a2 | camp | (-18.0, -40.0) | (-17.9, -39.9) | stag_b1 | (-17.9, -39.9) | 0.0 |
| stag_b1 | camp | (18.0, -40.0) | (17.9, -39.9) | stag_a2 | (17.9, -39.9) | 0.0 |
| stag_b2 | camp | (18.0, 40.0) | (17.9, 39.9) | stag_a1 | (17.9, 39.9) | 0.0 |
| bridge_nest_a1 | camp | (-6.0, 64.0) | (-5.9, 63.9) | bridge_nest_b2 | (-5.9, 63.9) | 0.0 |
| bridge_nest_a2 | camp | (-6.0, -64.0) | (-5.9, -63.9) | bridge_nest_b1 | (-5.9, -63.9) | 0.0 |
| bridge_nest_b1 | camp | (6.0, -64.0) | (5.9, -63.9) | bridge_nest_a2 | (5.9, -63.9) | 0.0 |
| bridge_nest_b2 | camp | (6.0, 64.0) | (5.9, 63.9) | bridge_nest_a1 | (5.9, 63.9) | 0.0 |
| ford_nest_a1 | camp | (0.0, 40.0) | (-0.1, 39.9) | ford_nest_a1 | (0.1, 39.9) | 0.3 |
| ford_nest_a2 | camp | (0.0, -40.0) | (-0.1, -39.9) | ford_nest_a2 | (0.1, -39.9) | 0.3 |
| tavern_a1 | tavern | (-26.0, 14.0) | (-25.9, 13.9) | tavern_b2 | (-25.9, 13.9) | 0.0 |
| tavern_a2 | tavern | (-26.0, -14.0) | (-25.9, -13.9) | tavern_b1 | (-25.9, -13.9) | 0.0 |
| tavern_b1 | tavern | (26.0, -14.0) | (25.9, -13.9) | tavern_a2 | (25.9, -13.9) | 0.0 |
| tavern_b2 | tavern | (26.0, 14.0) | (25.9, 13.9) | tavern_a1 | (25.9, 13.9) | 0.0 |
| vale_post_a1 | post | (-46.0, 82.0) | (-45.9, 81.9) | vale_post_b2 | (-45.9, 81.9) | 0.0 |
| vale_post_a2 | post | (-46.0, -82.0) | (-45.9, -81.9) | vale_post_b1 | (-45.9, -81.9) | 0.0 |
| vale_post_b1 | post | (46.0, -82.0) | (45.9, -81.9) | vale_post_a2 | (45.9, -81.9) | 0.0 |
| vale_post_b2 | post | (46.0, 82.0) | (45.9, 81.9) | vale_post_a1 | (45.9, 81.9) | 0.0 |
| corner_post_a1 | post | (-82.0, 58.0) | (-81.9, 57.9) | corner_post_b2 | (-81.9, 57.9) | 0.0 |
| corner_post_a2 | post | (-82.0, -58.0) | (-81.9, -57.9) | corner_post_b1 | (-81.9, -57.9) | 0.0 |
| corner_post_b1 | post | (82.0, -58.0) | (81.9, -57.9) | corner_post_a2 | (81.9, -57.9) | 0.0 |
| corner_post_b2 | post | (82.0, 58.0) | (81.9, 57.9) | corner_post_a1 | (81.9, 57.9) | 0.0 |
| den_a1 | guild | (-82.0, 0.0) | (-81.9, 0.1) | den_b1 | (-81.9, 0.1) | 0.0 |
| den_b1 | guild | (82.0, 0.0) | (81.9, 0.1) | den_a1 | (81.9, 0.1) | 0.0 |
| lodge_a1 | guild | (-58.0, 0.0) | (-57.9, 0.1) | lodge_b1 | (-57.9, 0.1) | 0.0 |
| lodge_b1 | guild | (58.0, 0.0) | (57.9, 0.1) | lodge_a1 | (57.9, 0.1) | 0.0 |
| peddler_a1 | peddler | (-50.0, 64.0) | (-49.9, 63.9) | peddler_b2 | (-49.9, 63.9) | 0.0 |
| peddler_a2 | peddler | (-50.0, -64.0) | (-49.9, -63.9) | peddler_b1 | (-49.9, -63.9) | 0.0 |
| peddler_b1 | peddler | (50.0, -64.0) | (49.9, -63.9) | peddler_a2 | (49.9, -63.9) | 0.0 |
| peddler_b2 | peddler | (50.0, 64.0) | (49.9, 63.9) | peddler_a1 | (49.9, 63.9) | 0.0 |
| cache_a1 | cache | (-50.0, 42.0) | (-49.9, 41.9) | cache_b2 | (-49.9, 41.9) | 0.0 |
| cache_a2 | cache | (-50.0, -42.0) | (-49.9, -41.9) | cache_b1 | (-49.9, -41.9) | 0.0 |
| cache_b1 | cache | (50.0, -42.0) | (49.9, -41.9) | cache_a2 | (49.9, -41.9) | 0.0 |
| cache_b2 | cache | (50.0, 42.0) | (49.9, 41.9) | cache_a1 | (49.9, 41.9) | 0.0 |
| green_cache_a1 | cache | (-44.0, 0.0) | (-43.9, 0.1) | green_cache_b1 | (-43.9, 0.1) | 0.0 |
| green_cache_b1 | cache | (44.0, 0.0) | (43.9, 0.1) | green_cache_a1 | (43.9, 0.1) | 0.0 |
| vale_lair_a1 | lair | (-74.0, 78.0) | (-73.9, 77.9) | vale_lair_b2 | (-73.9, 77.9) | 0.0 |
| vale_lair_a2 | lair | (-74.0, -78.0) | (-73.9, -77.9) | vale_lair_b1 | (-73.9, -77.9) | 0.0 |
| vale_lair_b1 | lair | (74.0, -78.0) | (73.9, -77.9) | vale_lair_a2 | (73.9, -77.9) | 0.0 |
| vale_lair_b2 | lair | (74.0, 78.0) | (73.9, 77.9) | vale_lair_a1 | (73.9, 77.9) | 0.0 |
| mouth_lair_a1 | lair | (-10.0, 82.0) | (-9.9, 81.9) | mouth_lair_b2 | (-9.9, 81.9) | 0.0 |
| mouth_lair_a2 | lair | (-10.0, -82.0) | (-9.9, -81.9) | mouth_lair_b1 | (-9.9, -81.9) | 0.0 |
| mouth_lair_b1 | lair | (10.0, -82.0) | (9.9, -81.9) | mouth_lair_a2 | (9.9, -81.9) | 0.0 |
| mouth_lair_b2 | lair | (10.0, 82.0) | (9.9, 81.9) | mouth_lair_a1 | (9.9, 81.9) | 0.0 |
| bridge_road_s | crossing_bridge_road | (0.0, 74.0) | (-0.1, 73.9) | bridge_road_s | (0.1, 73.9) | 0.3 |
| bridge_road_n | crossing_bridge_road | (0.0, -74.0) | (-0.1, -73.9) | bridge_road_n | (0.1, -73.9) | 0.3 |
| ford_s | crossing_ford | (0.0, 40.0) | (-0.1, 39.9) | ford_s | (0.1, 39.9) | 0.3 |
| ford_n | crossing_ford | (0.0, -40.0) | (-0.1, -39.9) | ford_n | (0.1, -39.9) | 0.3 |
| causeway_w | crossing_bridge_lane | (-12.8, 0.0) | (-12.6, 0.1) | causeway_e | (-12.6, 0.1) | 0.0 |
| causeway_e | crossing_bridge_lane | (12.8, 0.0) | (12.6, 0.1) | causeway_w | (12.6, 0.1) | 0.0 |
| crown | crown | (0.0, 0.0) | (0.1, 0.1) | crown | (-0.1, 0.1) | 0.3 |


## Spot constants (1)
| Constant | Entries | Result |
|---|---|---|
| LAIR_SPOTS | 8 | mirrored |


## F1 map geometry: most asymmetric pairs (top 1 of 1)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | keep_t0 - corner_post_a1 | 39.8 | keep_t1 - corner_post_b1 | 40.8 | -2.4 % |


## F2 unit paths: most asymmetric pairs (top 20 of 312)
| # | Pair | Length | Mirror pair | Length | Diff |
|---|---|---|---|---|---|
| 1 | node_b_b1 - causeway_w | 80.0 | node_b_b2 - causeway_w | 101.8 | -21.4 % |
| 2 | node_b_a1 - causeway_e | 80.0 | node_b_b2 - causeway_w | 101.8 | -21.4 % |
| 3 | node_b_a2 - causeway_e | 80.0 | node_b_b2 - causeway_w | 101.8 | -21.4 % |
| 4 | keep_t1 - corner_post_a1 | 180.7 | keep_t4 - corner_post_a2 | 224.5 | -19.5 % |
| 5 | keep_t3 - corner_post_b2 | 180.8 | keep_t4 - corner_post_a2 | 224.5 | -19.5 % |
| 6 | keep_t0 - corner_post_b1 | 224.2 | keep_t1 - corner_post_a1 | 180.7 | +19.4 % |
| 7 | keep_t0 - corner_post_b1 | 224.2 | keep_t3 - corner_post_b2 | 180.8 | +19.4 % |
| 8 | keep_t3 - node_b_a1 | 59.3 | keep_t4 - node_b_b1 | 72.8 | -18.6 % |
| 9 | keep_t1 - node_b_b2 | 59.3 | keep_t4 - node_b_b1 | 72.8 | -18.6 % |
| 10 | keep_t0 - node_b_a2 | 72.5 | keep_t3 - node_b_a1 | 59.3 | +18.3 % |
| 11 | keep_t0 - node_b_a2 | 72.5 | keep_t1 - node_b_b2 | 59.3 | +18.3 % |
| 12 | node_a_a2 - node_b_a1 | 55.1 | node_a_b2 - node_b_b1 | 67.1 | -17.9 % |
| 13 | node_a_b1 - node_b_b2 | 55.1 | node_a_b2 - node_b_b1 | 67.1 | -17.9 % |
| 14 | node_b_b1 - tavern_a1 | 97.3 | node_b_b2 - tavern_a2 | 118.6 | -17.9 % |
| 15 | node_b_a1 - tavern_b1 | 97.4 | node_b_b2 - tavern_a2 | 118.6 | -17.9 % |
| 16 | node_b_a2 - tavern_b2 | 97.4 | node_b_b2 - tavern_a2 | 118.6 | -17.9 % |
| 17 | node_a_a1 - node_b_a2 | 66.9 | node_a_a2 - node_b_a1 | 55.1 | +17.6 % |
| 18 | node_a_a1 - node_b_a2 | 66.9 | node_a_b1 - node_b_b2 | 55.1 | +17.6 % |
| 19 | node_a_b1 - corner_post_a1 | 183.1 | node_a_b2 - corner_post_a2 | 218.8 | -16.3 % |
| 20 | node_b_a1 - well_b1 | 136.6 | node_b_b1 - well_a1 | 114.3 | +16.3 % |


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| player (A1 west-south) | 35.2 (natural_a1) | 33.4 (well_a1) | 48.6 (wallow_a1) | 55.1 (vale_lair_a1) | 43.1 (tavern_a1) | 37.3 (corner_post_a1) | 42.8 (peddler_a1) | 23.8 (cache_a1) | 72.0 (crown) | 143.1 |
| ally (A2 west-north) | 34.9 (natural_a2) | 33.0 (well_a2) | 48.3 (wallow_a2) | 54.8 (vale_lair_a2) | 42.5 (tavern_a2) | 38.0 (corner_post_a2) | 42.5 (peddler_a2) | 23.5 (cache_a2) | 71.3 (crown) | 141.8 |
| enemy (B1 east-north) | 34.8 (natural_b1) | 33.0 (well_b1) | 48.0 (wallow_b1) | 54.5 (vale_lair_b1) | 42.5 (tavern_b1) | 38.1 (corner_post_b1) | 42.3 (peddler_b1) | 23.4 (cache_b1) | 71.3 (crown) | 141.8 |
| enemy 2 (B2 east-south) | 35.2 (natural_b2) | 33.4 (well_b2) | 48.3 (wallow_b2) | 54.8 (vale_lair_b2) | 43.1 (tavern_b2) | 37.5 (corner_post_b2) | 42.6 (peddler_b2) | 23.8 (cache_b2) | 72.0 (crown) | 143.1 |


## Every spot from the keeps (mirror_x)
| Spot | Kind | From keep_t0 | Twin | From keep_t4 | Diff |
|---|---|---|---|---|---|
| node_a_a1 | home_node | 6.7 | node_a_b2 | 6.7 | +0.0 % |
| node_b_a1 | home_node | 11.1 | node_b_b2 | 11.0 | +0.8 % |
| cache_a1 | cache | 23.8 | cache_b2 | 23.8 | +0.3 % |
| lodge_a1 | guild | 27.8 | lodge_b1 | 27.8 | +0.0 % |
| den_a1 | guild | 30.1 | den_b1 | 30.1 | +0.0 % |
| well_a1 | point | 33.4 | well_b2 | 33.4 | +0.0 % |
| green_cache_a1 | cache | 35.1 | green_cache_b1 | 35.1 | +0.0 % |
| natural_a1 | expansion | 35.2 | natural_b2 | 35.2 | +0.2 % |
| corner_post_a1 | post | 37.3 | corner_post_b2 | 37.5 | -0.5 % |
| peddler_a1 | peddler | 42.8 | peddler_b2 | 42.6 | +0.4 % |
| tavern_a1 | tavern | 43.1 | tavern_b2 | 43.1 | +0.0 % |
| shrine_a1 | point | 44.0 | shrine_b1 | 44.0 | +0.0 % |
| node_a_a2 | home_node | 47.4 | node_a_b1 | 47.4 | +0.0 % |
| wallow_a1 | camp | 48.6 | wallow_b2 | 48.3 | +0.4 % |
| stag_a1 | camp | 51.1 | stag_b2 | 51.1 | +0.0 % |
| keep_t3 | keep | 52.3 | keep_t1 | 52.3 | +0.0 % |
| vale_lair_a1 | lair | 55.1 | vale_lair_b2 | 54.8 | +0.5 % |
| tavern_a2 | tavern | 57.6 | tavern_b1 | 57.6 | +0.0 % |
| fordwatch_a1 | point | 58.6 | fordwatch_b2 | 58.6 | +0.0 % |
| causeway_w | crossing_bridge_lane | 60.5 | causeway_e | 60.5 | +0.0 % |
| vale_post_a1 | post | 61.1 | vale_post_b2 | 60.9 | +0.3 % |
| rich_a1 | expansion | 63.5 | rich_b2 | 63.4 | +0.1 % |
| vale_watch_a1 | point | 63.9 | vale_watch_b2 | 63.9 | +0.1 % |
| well_a2 | point | 65.3 | well_b1 | 65.3 | +0.0 % |
| ford_nest_a1 | camp | 68.4 | ford_nest_a1 | 68.4 | +0.0 % |
| ford_s | crossing_ford | 68.4 | ford_s | 68.4 | +0.0 % |
| cache_a2 | cache | 70.4 | cache_b1 | 70.4 | +0.0 % |
| crown | crown | 72.0 | crown | 72.0 | +0.0 % |
| bridge_nest_a1 | camp | 72.1 | bridge_nest_b2 | 72.1 | +0.1 % |
| node_b_a2 | home_node | 72.5 | node_b_b1 | 72.8 | -0.4 % |
| fordwatch_b2 | point | 78.7 | fordwatch_a1 | 78.7 | +0.1 % |
| natural_a2 | expansion | 79.1 | natural_b1 | 79.1 | +0.0 % |
| mouth_lair_a1 | lair | 80.4 | mouth_lair_b2 | 80.3 | +0.1 % |
| bridge_road_s | crossing_bridge_road | 82.5 | bridge_road_s | 82.5 | +0.1 % |
| stag_a2 | camp | 82.6 | stag_b1 | 82.6 | +0.0 % |
| fordwatch_a2 | point | 83.1 | fordwatch_b1 | 83.1 | -0.0 % |
| causeway_e | crossing_bridge_lane | 84.4 | causeway_w | 84.4 | +0.0 % |
| corner_post_a2 | post | 85.5 | corner_post_b1 | 85.5 | +0.0 % |
| stag_b2 | camp | 86.1 | stag_a1 | 86.1 | +0.0 % |
| vale_watch_b2 | point | 90.0 | vale_watch_a1 | 89.9 | +0.1 % |
| peddler_a2 | peddler | 91.9 | peddler_b1 | 97.4 | -5.6 % |
| bridge_nest_b2 | camp | 93.5 | bridge_nest_a1 | 93.3 | +0.2 % |
| ford_nest_a2 | camp | 94.3 | ford_nest_a2 | 94.3 | -0.0 % |
| ford_n | crossing_ford | 94.3 | ford_n | 94.3 | -0.0 % |
| mouth_lair_b2 | lair | 95.4 | mouth_lair_a1 | 95.3 | +0.1 % |
| wallow_a2 | camp | 100.7 | wallow_b1 | 100.8 | -0.1 % |
| vale_watch_a2 | point | 100.8 | vale_watch_b1 | 100.8 | +0.0 % |
| tavern_b1 | tavern | 101.8 | tavern_a2 | 101.8 | -0.0 % |
| well_b2 | point | 102.9 | well_a1 | 102.9 | +0.0 % |
| shrine_b1 | point | 103.6 | shrine_a1 | 103.6 | +0.0 % |
| fordwatch_b1 | point | 104.1 | fordwatch_a2 | 104.1 | -0.0 % |
| tavern_b2 | tavern | 104.2 | tavern_a1 | 104.1 | +0.1 % |
| vale_lair_a2 | lair | 104.5 | vale_lair_b1 | 104.5 | -0.0 % |
| rich_b2 | expansion | 105.8 | rich_a1 | 105.8 | +0.0 % |
| rich_a2 | expansion | 107.3 | rich_b1 | 107.3 | +0.0 % |
| bridge_nest_a2 | camp | 109.1 | bridge_nest_b1 | 109.1 | +0.0 % |
| natural_b2 | expansion | 109.2 | natural_a1 | 109.2 | +0.0 % |
| vale_post_a2 | post | 110.3 | vale_post_b1 | 114.8 | -3.9 % |
| stag_b1 | camp | 111.5 | stag_a2 | 111.6 | -0.1 % |
| green_cache_b1 | cache | 115.5 | green_cache_a1 | 115.5 | +0.0 % |
| vale_watch_b1 | point | 116.3 | vale_watch_a2 | 116.2 | +0.0 % |
| cache_b2 | cache | 118.2 | cache_a1 | 118.2 | -0.0 % |
| well_b1 | point | 118.8 | well_a2 | 128.4 | -7.4 % |
| bridge_nest_b1 | camp | 120.4 | bridge_nest_a2 | 120.2 | +0.1 % |
| bridge_road_n | crossing_bridge_road | 120.8 | bridge_road_n | 120.9 | -0.1 % |
| node_b_b2 | home_node | 127.2 | node_b_a1 | 127.2 | -0.0 % |
| vale_post_b2 | post | 128.9 | vale_post_a1 | 128.8 | +0.0 % |
| lodge_b1 | guild | 129.5 | lodge_a1 | 129.5 | +0.0 % |
| peddler_b2 | peddler | 132.4 | peddler_a1 | 132.4 | +0.0 % |
| mouth_lair_b1 | lair | 133.6 | mouth_lair_a2 | 133.7 | -0.0 % |
| rich_b1 | expansion | 134.5 | rich_a2 | 134.5 | +0.0 % |
| natural_b1 | expansion | 134.7 | natural_a2 | 134.7 | -0.0 % |
| mouth_lair_a2 | lair | 138.2 | mouth_lair_b1 | 138.5 | -0.2 % |
| wallow_b2 | camp | 139.8 | wallow_a1 | 139.8 | +0.0 % |
| keep_t4 | keep | 143.1 | keep_t0 | 143.1 | +0.0 % |
| cache_b1 | cache | 143.6 | cache_a2 | 143.7 | -0.1 % |
| keep_t1 | keep | 143.6 | keep_t3 | 143.6 | -0.0 % |
| node_a_b2 | home_node | 144.9 | node_a_a1 | 144.9 | +0.0 % |
| node_a_b1 | home_node | 146.0 | node_a_a2 | 146.0 | +0.0 % |
| peddler_b1 | peddler | 149.6 | peddler_a2 | 149.7 | -0.0 % |
| node_b_b1 | home_node | 152.6 | node_b_a2 | 152.7 | -0.0 % |
| den_b1 | guild | 153.5 | den_a1 | 153.5 | +0.0 % |
| vale_lair_b2 | lair | 156.0 | vale_lair_a1 | 156.0 | +0.0 % |
| vale_post_b1 | post | 156.6 | vale_post_a2 | 156.6 | -0.0 % |
| wallow_b1 | camp | 160.5 | wallow_a2 | 160.5 | -0.0 % |
| corner_post_b2 | post | 165.0 | corner_post_a1 | 165.0 | +0.0 % |
| vale_lair_b1 | lair | 177.4 | vale_lair_a2 | 177.4 | -0.0 % |
| corner_post_b1 | post | 224.2 | corner_post_a2 | 224.5 | -0.1 % |


## Ally keeps per seat (navmesh path, m)
| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |
|---|---|---|---|---|---|---|---|
| player (A1 west-south) | 0 | keep_t3 | 52.3 | no | 143.1 | 143.6 | 0.37 |
| ally (A2 west-north) | 0 | keep_t0 | 52.3 | no | 141.8 | 143.6 | 0.37 |
| enemy (B1 east-north) | 1 | keep_t4 | 52.3 | no | 141.8 | 143.6 | 0.37 |
| enemy 2 (B2 east-south) | 1 | keep_t1 | 52.3 | no | 143.1 | 143.6 | 0.37 |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| player (A1 west-south) | ally keep (keep_t3) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| player (A1 west-south) | enemy keep (nearest) (keep_t4) | 143.1 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| player (A1 west-south) | enemy keep #2 (keep_t1) | 143.6 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| player (A1 west-south) | nearest expansion (natural_a1) | 35.2 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| player (A1 west-south) | nearest point (well_a1) | 33.4 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| player (A1 west-south) | nearest camp (wallow_a1) | 48.6 | 0.0 | 0:11 | 0:10 | 0:06 | 0:12 |
| player (A1 west-south) | crown (crown) | 72.0 | 0.0 | 0:16 | 0:14 | 0:10 | 0:18 |
| ally (A2 west-north) | ally keep (keep_t0) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| ally (A2 west-north) | enemy keep (nearest) (keep_t1) | 141.8 | 0.0 | 0:31 | 0:28 | 0:19 | 0:35 |
| ally (A2 west-north) | enemy keep #2 (keep_t4) | 143.6 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| ally (A2 west-north) | nearest expansion (natural_a2) | 34.9 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| ally (A2 west-north) | nearest point (well_a2) | 33.0 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| ally (A2 west-north) | nearest camp (wallow_a2) | 48.3 | 0.0 | 0:10 | 0:10 | 0:06 | 0:12 |
| ally (A2 west-north) | crown (crown) | 71.3 | 0.0 | 0:16 | 0:14 | 0:10 | 0:18 |
| enemy (B1 east-north) | ally keep (keep_t4) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| enemy (B1 east-north) | enemy keep (nearest) (keep_t3) | 141.8 | 0.0 | 0:31 | 0:28 | 0:19 | 0:35 |
| enemy (B1 east-north) | enemy keep #2 (keep_t0) | 143.6 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| enemy (B1 east-north) | nearest expansion (natural_b1) | 34.8 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| enemy (B1 east-north) | nearest point (well_b1) | 33.0 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| enemy (B1 east-north) | nearest camp (wallow_b1) | 48.0 | 0.0 | 0:10 | 0:10 | 0:06 | 0:12 |
| enemy (B1 east-north) | crown (crown) | 71.3 | 0.0 | 0:16 | 0:14 | 0:10 | 0:18 |
| enemy 2 (B2 east-south) | ally keep (keep_t1) | 52.3 | 0.0 | 0:11 | 0:10 | 0:07 | 0:13 |
| enemy 2 (B2 east-south) | enemy keep (nearest) (keep_t0) | 143.1 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| enemy 2 (B2 east-south) | enemy keep #2 (keep_t3) | 143.6 | 0.0 | 0:31 | 0:29 | 0:19 | 0:36 |
| enemy 2 (B2 east-south) | nearest expansion (natural_b2) | 35.2 | 0.0 | 0:08 | 0:07 | 0:05 | 0:09 |
| enemy 2 (B2 east-south) | nearest point (well_b2) | 33.4 | 0.0 | 0:07 | 0:07 | 0:04 | 0:08 |
| enemy 2 (B2 east-south) | nearest camp (wallow_b2) | 48.3 | 0.0 | 0:11 | 0:10 | 0:06 | 0:12 |
| enemy 2 (B2 east-south) | crown (crown) | 72.0 | 0.0 | 0:16 | 0:14 | 0:10 | 0:18 |


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| bridge_road_s | bridge_road | 6.0 | 5.0 | 6.0 | bridge_road_s | 5.0 |
| bridge_road_n | bridge_road | 6.0 | 5.0 | 6.0 | bridge_road_n | 5.0 |
| ford_s | ford | 7.0 | 5.0 | 6.0 | ford_s | 5.0 |
| ford_n | ford | 7.0 | 4.8 | 5.8 | ford_n | 4.8 |
| causeway_w | bridge_lane | 10.0 | 9.0 | 10.0 | causeway_e | 9.3 |
| causeway_e | bridge_lane | 10.0 | 9.3 | 10.3 | causeway_w | 9.0 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> crown | 72.2 | 8.6 | (-9.6, 3.2) | - |
| keep_t0 -> keep_t1 | 143.6 | 8.8 | (-9.6, 3.2) | - |
| keep_t0 -> keep_t4 | 143.1 | 7.5 | (-9.6, 3.4) | - |
| keep_t0 -> natural_a1 | 35.2 | 21.3 | (-63.4, 27.4) | - |
| keep_t3 -> crown | 71.6 | 8.8 | (-9.9, -3.4) | - |
| keep_t3 -> keep_t4 | 143.6 | 8.5 | (10.0, 3.4) | - |
| keep_t3 -> natural_a2 | 34.9 | 21.8 | (-63.1, -27.5) | - |
| keep_t1 -> crown | 71.4 | 9.0 | (9.9, -3.4) | - |
| keep_t1 -> keep_t3 | 141.8 | 7.3 | (9.9, -3.6) | - |
| keep_t1 -> natural_b1 | 34.8 | 22.1 | (63.2, -27.7) | - |
| keep_t4 -> crown | 72.0 | 8.8 | (9.6, 3.2) | - |
| keep_t4 -> natural_b2 | 35.2 | 21.6 | (63.5, 27.6) | - |


## Hottest metres (every spot-pair shortest path, 3916 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-2.5, -37.5) | 365 | 9 % |
| 2 | (-3.5, 37.5) | 321 | 8 % |
| 3 | (4.5, 36.5) | 268 | 7 % |
| 4 | (14.5, -5.5) | 222 | 6 % |
| 5 | (14.5, 5.5) | 207 | 5 % |
| 6 | (-13.5, -4.5) | 183 | 5 % |
| 7 | (-13.5, 4.5) | 172 | 4 % |
| 8 | (3.5, -71.5) | 171 | 4 % |
| 9 | (-2.5, 71.5) | 166 | 4 % |
| 10 | (8.5, -32.5) | 159 | 4 % |


## Info findings (127)
| Check | Where | What |
|---|---|---|
| N3 | island 6 at (-67.9, -29.9) | 22.6 m² inside the footprint of keep_t3 (unreachable by design) |
| N3 | island 7 at (68.1, -29.9) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | island 11 at (-67.9, 30.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 12 at (68.1, 30.1) | 22.6 m² inside the footprint of keep_t4 (unreachable by design) |
| N3 | raised islands | 10 islands on top of colliders (780 m², more than 0.3 m above / below the ground navmesh): harmless |
| F2 | node_a_a2-peddler_a1 vs node_a_b2-peddler_b1 | 87.3 m vs 91.7 m (4.8 %) |
| F2 | node_a_b1-peddler_b2 vs node_a_b2-peddler_b1 | 87.3 m vs 91.7 m (4.8 %) |
| F2 | corner_post_a2-cache_b2 vs corner_post_b1-cache_a1 | 175.5 m vs 167.2 m (4.8 %) |
| F2 | node_a_a1-peddler_a2 vs node_a_a2-peddler_a1 | 91.5 m vs 87.3 m (4.6 %) |
| F2 | node_a_a1-peddler_a2 vs node_a_b1-peddler_b2 | 91.5 m vs 87.3 m (4.6 %) |
| F2 | keep_t3-vale_post_a1 vs keep_t4-vale_post_b1 | 109.7 m vs 114.8 m (4.4 %) |
| F2 | keep_t1-vale_post_b2 vs keep_t4-vale_post_b1 | 109.7 m vs 114.8 m (4.4 %) |
| F2 | corner_post_a2-den_b1 vs corner_post_b1-den_a1 | 190.6 m vs 182.2 m (4.4 %) |
| F2 | corner_post_a1-causeway_e vs corner_post_a2-causeway_e | 127.1 m vs 121.5 m (4.4 %) |
| F2 | corner_post_a2-causeway_e vs corner_post_b2-causeway_w | 121.5 m vs 127.0 m (4.3 %) |
| F2 | wallow_a1-vale_post_b1 vs wallow_b1-vale_post_a1 | 188.6 m vs 196.9 m (4.3 %) |
| F2 | wallow_a2-vale_post_b2 vs wallow_b1-vale_post_a1 | 188.6 m vs 196.9 m (4.2 %) |
| F2 | wallow_b1-vale_post_a1 vs wallow_b2-vale_post_a2 | 196.9 m vs 188.6 m (4.2 %) |
| F2 | peddler_a1-cache_b2 vs peddler_b2-cache_a1 | 104.4 m vs 109.0 m (4.2 %) |
| F2 | corner_post_b1-den_a1 vs corner_post_b2-den_a1 | 182.2 m vs 174.6 m (4.2 %) |
| F2 | corner_post_a1-den_b1 vs corner_post_b1-den_a1 | 174.6 m vs 182.2 m (4.2 %) |
| F2 | peddler_a1-cache_b2 vs peddler_a2-cache_b1 | 104.4 m vs 108.9 m (4.1 %) |
| F2 | keep_t1-cache_a1 vs keep_t4-cache_a2 | 137.7 m vs 143.7 m (4.1 %) |
| F2 | peddler_b1-cache_a2 vs peddler_b2-cache_a1 | 104.5 m vs 109.0 m (4.1 %) |
| F2 | tavern_a1-vale_post_b1 vs tavern_a2-vale_post_b2 | 122.4 m vs 127.7 m (4.1 %) |
| F2 | keep_t3-cache_b2 vs keep_t4-cache_a2 | 137.7 m vs 143.7 m (4.1 %) |
| F2 | tavern_a1-vale_post_b1 vs tavern_b1-vale_post_a1 | 122.4 m vs 127.7 m (4.1 %) |
| F2 | vale_lair_a1-causeway_e vs vale_lair_b1-causeway_w | 126.6 m vs 121.4 m (4.1 %) |
| F2 | wallow_a1-stag_b1 vs wallow_a2-stag_b2 | 143.5 m vs 149.6 m (4.1 %) |
| F2 | keep_t0-cache_b1 vs keep_t1-cache_a1 | 143.6 m vs 137.7 m (4.1 %) |
| F2 | keep_t0-cache_b1 vs keep_t3-cache_b2 | 143.6 m vs 137.7 m (4.1 %) |
| F2 | keep_t0-tavern_b2 vs keep_t3-tavern_b1 | 104.2 m vs 100.0 m (4.1 %) |
| F2 | vale_lair_a1-causeway_e vs vale_lair_a2-causeway_e | 126.6 m vs 121.5 m (4.1 %) |
| F2 | peddler_a2-cache_b1 vs peddler_b1-cache_a2 | 108.9 m vs 104.5 m (4.1 %) |
| F2 | tavern_a2-vale_post_b2 vs tavern_b2-vale_post_a2 | 127.7 m vs 122.5 m (4.1 %) |
| F2 | keep_t0-tavern_b2 vs keep_t1-tavern_a2 | 104.2 m vs 100.0 m (4.0 %) |
| F2 | tavern_b1-vale_post_a1 vs tavern_b2-vale_post_a2 | 127.7 m vs 122.5 m (4.0 %) |
| F2 | wallow_a1-stag_b1 vs wallow_b2-stag_a2 | 143.5 m vs 149.5 m (4.0 %) |
| F2 | wallow_a1-stag_b1 vs wallow_b1-stag_a1 | 143.5 m vs 149.5 m (4.0 %) |
| F2 | keep_t3-tavern_b1 vs keep_t4-tavern_a1 | 100.0 m vs 104.1 m (4.0 %) |
| F2 | vale_lair_b1-causeway_w vs vale_lair_b2-causeway_w | 121.4 m vs 126.5 m (4.0 %) |
| F2 | keep_t1-tavern_a2 vs keep_t4-tavern_a1 | 100.0 m vs 104.1 m (4.0 %) |
| F2 | vale_lair_a2-causeway_e vs vale_lair_b2-causeway_w | 121.5 m vs 126.5 m (4.0 %) |
| F2 | keep_t0-vale_post_a2 vs keep_t4-vale_post_b1 | 110.3 m vs 114.8 m (3.9 %) |
| F2 | well_a1-green_cache_b1 vs well_b1-green_cache_a1 | 93.4 m vs 90.1 m (3.5 %) |
| F2 | well_a1-green_cache_b1 vs well_a2-green_cache_b1 | 93.4 m vs 90.1 m (3.5 %) |
| F2 | well_b1-green_cache_a1 vs well_b2-green_cache_a1 | 90.1 m vs 93.3 m (3.5 %) |
| F2 | well_a2-green_cache_b1 vs well_b2-green_cache_a1 | 90.1 m vs 93.3 m (3.4 %) |
| F2 | well_b1-vale_lair_a1 vs well_b2-vale_lair_a2 | 155.8 m vs 161.2 m (3.4 %) |
| F2 | well_a2-vale_lair_b2 vs well_b1-vale_lair_a1 | 161.2 m vs 155.8 m (3.3 %) |
| F2 | peddler_b1-vale_lair_b2 vs peddler_b2-vale_lair_b1 | 143.8 m vs 148.7 m (3.3 %) |
| F2 | peddler_a2-vale_lair_a1 vs peddler_b2-vale_lair_b1 | 143.8 m vs 148.7 m (3.3 %) |
| F2 | well_a1-vale_lair_b1 vs well_b1-vale_lair_a1 | 161.1 m vs 155.8 m (3.3 %) |
| F2 | den_a1-peddler_b1 vs den_b1-peddler_a1 | 161.5 m vs 167.0 m (3.3 %) |
| F2 | den_a1-peddler_b2 vs den_b1-peddler_a1 | 161.6 m vs 167.0 m (3.2 %) |
| F2 | peddler_a1-vale_lair_a2 vs peddler_b1-vale_lair_b2 | 148.6 m vs 143.8 m (3.2 %) |
| F2 | peddler_a1-vale_lair_a2 vs peddler_a2-vale_lair_a1 | 148.6 m vs 143.8 m (3.2 %) |
| F2 | den_b1-peddler_a1 vs den_b1-peddler_a2 | 167.0 m vs 161.6 m (3.2 %) |
| F2 | tavern_b1-vale_lair_a1 vs tavern_b2-vale_lair_a2 | 138.8 m vs 143.3 m (3.2 %) |
| F2 | tavern_a2-vale_lair_b2 vs tavern_b2-vale_lair_a2 | 138.8 m vs 143.3 m (3.2 %) |
| F2 | node_a_a2-vale_post_a1 vs node_a_b2-vale_post_b1 | 105.7 m vs 109.1 m (3.1 %) |
| F2 | node_a_b1-vale_post_b2 vs node_a_b2-vale_post_b1 | 105.7 m vs 109.1 m (3.1 %) |
| F2 | tavern_a1-vale_lair_b1 vs tavern_b1-vale_lair_a1 | 143.2 m vs 138.8 m (3.1 %) |
| F2 | tavern_a1-vale_lair_b1 vs tavern_a2-vale_lair_b2 | 143.2 m vs 138.8 m (3.1 %) |
| F2 | well_a1-vale_post_b1 vs well_b1-vale_post_a1 | 140.3 m vs 144.7 m (3.0 %) |
| F2 | node_a_a1-vale_post_a2 vs node_a_b1-vale_post_b2 | 109.0 m vs 105.7 m (3.0 %) |
| F2 | node_a_a1-vale_post_a2 vs node_a_a2-vale_post_a1 | 109.0 m vs 105.7 m (3.0 %) |
| F2 | well_a2-vale_post_b2 vs well_b1-vale_post_a1 | 140.3 m vs 144.7 m (3.0 %) |
| F2 | well_b1-vale_post_a1 vs well_b2-vale_post_a2 | 144.7 m vs 140.4 m (3.0 %) |
| F2 | corner_post_b1-green_cache_b1 vs corner_post_b2-green_cache_b1 | 69.2 m vs 71.3 m (2.9 %) |
| F2 | tavern_a1-mouth_lair_b2 vs tavern_a2-mouth_lair_b1 | 78.7 m vs 81.1 m (2.9 %) |
| F2 | corner_post_a1-green_cache_a1 vs corner_post_b2-green_cache_b1 | 69.2 m vs 71.3 m (2.9 %) |
| F2 | corner_post_b1-lodge_a1 vs corner_post_b2-lodge_a1 | 158.3 m vs 153.7 m (2.9 %) |
| F2 | corner_post_a2-green_cache_a1 vs corner_post_b1-green_cache_b1 | 71.2 m vs 69.2 m (2.9 %) |
| F2 | tavern_a2-mouth_lair_b1 vs tavern_b1-mouth_lair_a2 | 81.1 m vs 78.8 m (2.8 %) |
| F2 | corner_post_a1-lodge_b1 vs corner_post_b1-lodge_a1 | 153.8 m vs 158.3 m (2.8 %) |
| F2 | corner_post_a1-green_cache_a1 vs corner_post_a2-green_cache_a1 | 69.2 m vs 71.2 m (2.8 %) |
| F2 | peddler_a1-causeway_e vs peddler_a2-causeway_e | 98.9 m vs 96.1 m (2.8 %) |
| F2 | node_a_b1-peddler_b1 vs node_a_b2-peddler_b2 | 50.0 m vs 48.6 m (2.8 %) |
| F2 | tavern_a2-mouth_lair_b1 vs tavern_b2-mouth_lair_a1 | 81.1 m vs 78.8 m (2.8 %) |
| F2 | node_b_a1-lodge_b1 vs node_b_b1-lodge_a1 | 128.6 m vs 125.1 m (2.7 %) |
| F2 | node_b_a1-lodge_b1 vs node_b_a2-lodge_b1 | 128.6 m vs 125.1 m (2.7 %) |
| F2 | node_b_a1-bridge_nest_b2 vs node_b_a2-bridge_nest_b1 | 84.7 m vs 82.4 m (2.7 %) |
| F2 | node_b_b1-lodge_a1 vs node_b_b2-lodge_a1 | 125.1 m vs 128.5 m (2.7 %) |
| F2 | node_b_a2-lodge_b1 vs node_b_b2-lodge_a1 | 125.1 m vs 128.5 m (2.7 %) |
| F2 | peddler_a2-causeway_e vs peddler_b2-causeway_w | 96.1 m vs 98.7 m (2.7 %) |
| F2 | keep_t3-wallow_a1 vs keep_t4-wallow_b1 | 98.1 m vs 100.8 m (2.7 %) |
| F2 | keep_t1-wallow_b2 vs keep_t4-wallow_b1 | 98.1 m vs 100.8 m (2.7 %) |
| F2 | node_a_a1-peddler_a1 vs node_a_b1-peddler_b1 | 48.7 m vs 50.0 m (2.6 %) |
| F2 | peddler_a2-causeway_e vs peddler_b1-causeway_w | 96.1 m vs 98.7 m (2.6 %) |
| F2 | corner_post_a2-peddler_a1 vs corner_post_b2-peddler_b1 | 125.9 m vs 129.3 m (2.6 %) |
| F2 | corner_post_b1-peddler_b2 vs corner_post_b2-peddler_b1 | 125.9 m vs 129.3 m (2.6 %) |
| F2 | node_b_a2-bridge_nest_b1 vs node_b_b1-bridge_nest_a2 | 82.4 m vs 84.6 m (2.6 %) |
| F2 | node_b_a1-bridge_nest_b2 vs node_b_b2-bridge_nest_a1 | 84.7 m vs 82.5 m (2.6 %) |
| F2 | keep_t0-wallow_a2 vs keep_t3-wallow_a1 | 100.7 m vs 98.1 m (2.5 %) |
| F2 | keep_t0-wallow_a2 vs keep_t1-wallow_b2 | 100.7 m vs 98.1 m (2.5 %) |
| F2 | corner_post_a1-peddler_a2 vs corner_post_b1-peddler_b2 | 129.1 m vs 125.9 m (2.5 %) |
| F2 | corner_post_a1-peddler_a2 vs corner_post_a2-peddler_a1 | 129.1 m vs 125.9 m (2.5 %) |
| F2 | node_b_b1-bridge_nest_a2 vs node_b_b2-bridge_nest_a1 | 84.6 m vs 82.5 m (2.5 %) |
| F2 | node_a_a2-peddler_a2 vs node_a_b2-peddler_b2 | 49.8 m vs 48.6 m (2.5 %) |
| F2 | corner_post_a2-cache_b2 vs corner_post_b2-cache_a2 | 175.5 m vs 179.9 m (2.5 %) |
| F2 | vale_post_b1-vale_lair_b2 vs vale_post_b2-vale_lair_b1 | 162.2 m vs 166.2 m (2.4 %) |
| F2 | vale_post_a2-vale_lair_a1 vs vale_post_b2-vale_lair_b1 | 162.2 m vs 166.2 m (2.4 %) |
| F2 | natural_a1-peddler_b1 vs natural_b1-peddler_a1 | 152.2 m vs 155.9 m (2.4 %) |
| F2 | corner_post_a1-cache_b1 vs corner_post_a2-cache_b2 | 179.8 m vs 175.5 m (2.4 %) |
| F2 | wallow_a1-causeway_e vs wallow_b1-causeway_w | 109.7 m vs 107.1 m (2.3 %) |
| F2 | wallow_a1-causeway_e vs wallow_a2-causeway_e | 109.7 m vs 107.1 m (2.3 %) |
| F2 | natural_a2-peddler_b2 vs natural_b1-peddler_a1 | 152.3 m vs 155.9 m (2.3 %) |
| F2 | vale_post_a1-vale_lair_a2 vs vale_post_b1-vale_lair_b2 | 166.1 m vs 162.2 m (2.3 %) |
| F2 | vale_post_a1-vale_lair_a2 vs vale_post_a2-vale_lair_a1 | 166.1 m vs 162.2 m (2.3 %) |
| F2 | natural_b1-peddler_a1 vs natural_b2-peddler_a2 | 155.9 m vs 152.4 m (2.3 %) |
| F2 | node_a_a1-peddler_a1 vs node_a_a2-peddler_a2 | 48.7 m vs 49.8 m (2.3 %) |
| F2 | well_a2-den_b1 vs well_b2-den_a1 | 128.1 m vs 125.1 m (2.3 %) |
| F2 | well_a1-den_b1 vs well_a2-den_b1 | 125.2 m vs 128.1 m (2.3 %) |
| F2 | well_b1-den_a1 vs well_b2-den_a1 | 128.0 m vs 125.1 m (2.3 %) |
| F2 | well_a1-den_b1 vs well_b1-den_a1 | 125.2 m vs 128.0 m (2.2 %) |
| F2 | wallow_b1-causeway_w vs wallow_b2-causeway_w | 107.1 m vs 109.5 m (2.2 %) |
| F2 | natural_a1-wallow_b1 vs natural_a2-wallow_b2 | 163.1 m vs 166.7 m (2.2 %) |
| F2 | wallow_a2-causeway_e vs wallow_b2-causeway_w | 107.1 m vs 109.5 m (2.2 %) |
| F2 | keep_t0-corner_post_a1 vs keep_t1-corner_post_b1 | 37.3 m vs 38.1 m (2.2 %) |
| F2 | natural_a2-wallow_b2 vs natural_b2-wallow_a2 | 166.7 m vs 163.2 m (2.1 %) |
| F2 | natural_a1-wallow_b1 vs natural_b1-wallow_a1 | 163.1 m vs 166.6 m (2.1 %) |
| F2 | peddler_b1-vale_lair_a1 vs peddler_b2-vale_lair_a2 | 194.6 m vs 198.8 m (2.1 %) |
| F2 | node_a_a1-wallow_a1 vs node_a_a2-wallow_a2 | 54.4 m vs 53.3 m (2.1 %) |
| F2 | natural_b1-wallow_a1 vs natural_b2-wallow_a2 | 166.6 m vs 163.2 m (2.1 %) |
| F2 | peddler_a2-vale_lair_b2 vs peddler_b2-vale_lair_a2 | 194.7 m vs 198.8 m (2.1 %) |
| F2 | peddler_a1-vale_lair_b1 vs peddler_b1-vale_lair_a1 | 198.7 m vs 194.6 m (2.0 %) |

## Notes
- Octile grid shortest paths (0.5 m, 89 sources) 121.47 s.
- Navmesh raster 2.71 s (208 polygons, 495616 cells of 0.25 m), spot / mirror checks 2.68 s, 3916 paths 0.96 s.
- Map Kinhearth Vale (2v2), scene res://docs/tools/world_forge/out/kinhearth_vale/preview.tscn, sim mode off; level load + navmesh bake 0.5 s (14 frames), lab 130.0 s. Spec: docs/design/new-maps.md.
