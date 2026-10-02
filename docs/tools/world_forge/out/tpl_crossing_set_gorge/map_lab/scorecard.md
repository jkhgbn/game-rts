# Map Lab: Template crossing_set_gorge scorecard: world_forge_tpl_crossing_set_gorge

2026-10-02 18:50 · lab v1.0 · 13.47 s · scanned 6 spots

## Result: **WARN** · score **93 / 100**

0 FAIL · 2 WARN · 11 PASS · 4 info checks; findings: 0 FAIL, 4 WARN, 2 info

## Improve next
1. **Every spot reachable** (WARN): t_home_bridge_w: crossing_bridge_road is 8.1 m from the nearest navmesh -> the spot sits deep inside a collider: check its clearing (open the blocked spot or move it) _(from N2 4 / 6 clean (0 FAIL, 2 WARN))_
2. **Crossing widths** (WARN): t_home_bridge_w: only 0.0 m of navmesh across (units pass single file) -> widen the crossing or clear its approach _(from C1 3 / 5 clean (0 FAIL, 2 WARN))_
3. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 19 polygons, main area 4045 m² (99 % of the 64 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | **WARN** 58 | 4 / 6 clean (0 FAIL, 2 WARN) | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh | open the blocked spot or move it |
| N3 | No navmesh islands | PASS 100 | 1 / 1 clean, 2 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 0 half widths ok, 0 arms ok, 1 circles ok, 0 segments ok, 64 x 64 m ok, 1 spots ok, 0.3x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 6 / 6 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 6 / 6 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 0 / 0 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 1 / 1 clean | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 0 / 0 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | PASS 100 | 0 / 0 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side |  |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep distances per seat | INFO | fewer than 2 keeps found |  |  |
| A1 | Ally keeps (team maps) | INFO | no side has 2 seats (1v1): nothing to check |  |  |
| T1 | Travel times per seat | INFO | fewer than 2 keeps found |  |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | **WARN** 55 | 3 / 5 clean (0 FAIL, 2 WARN) | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 0 / 0 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | PASS 100 | 1 / 1 clean | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (256 x 256 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | N2 | t_home_bridge_w | crossing_bridge_road is 8.1 m from the nearest navmesh | the spot sits deep inside a collider: check its clearing |
| WARN | N2 | t_home_bridge_e | crossing_bridge_road is 8.1 m from the nearest navmesh | the spot sits deep inside a collider: check its clearing |
| WARN | C1 | t_home_bridge_w | only 0.0 m of navmesh across (units pass single file) | widen the crossing or clear its approach |
| WARN | C1 | t_home_bridge_e | only 0.0 m of navmesh across (units pass single file) | widen the crossing or clear its approach |

## Spot navmesh points (-)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|


## Spot constants (0)
| Constant | Entries | Result |
|---|---|---|


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| t_home_bridge_w | bridge_road | 6.0 | 0.0 | 1.0 | - | - |
| t_home_bridge_e | bridge_road | 6.0 | 0.0 | 1.0 | - | - |
| t_lane_w | bridge_lane | 7.0 | 24.1 | 25.1 | - | - |
| t_lane_e | bridge_lane | 7.0 | 24.1 | 25.1 | - | - |
| t_mid_ford | ford | 7.0 | 24.1 | 25.1 | - | - |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|


## Hottest metres (every spot-pair shortest path, 15 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (15.5, -0.5) | 7 | 47 % |
| 2 | (0.5, 0.5) | 6 | 40 % |
| 3 | (-15.5, 0.5) | 6 | 40 % |
| 4 | (-19.5, 22.5) | 5 | 33 % |
| 5 | (31.5, -0.5) | 5 | 33 % |
| 6 | (-31.5, -0.5) | 5 | 33 % |
| 7 | (23.5, -0.5) | 4 | 27 % |
| 8 | (-7.5, 0.5) | 4 | 27 % |
| 9 | (-23.5, -0.5) | 3 | 20 % |
| 10 | (-0.5, 13.5) | 1 | 7 % |


## Info findings (2)
| Check | Where | What |
|---|---|---|
| N3 | island 2 at (-22.9, 23.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 1 islands on top of colliders (2 m², more than 0.3 m above / below the ground navmesh): harmless |

## Notes
- Octile grid shortest paths (0.5 m, 6 sources) 9.72 s.
- Navmesh raster 1.69 s (19 polygons, 65536 cells of 0.25 m), spot / mirror checks 0.24 s, 15 paths 0.00 s.
- Map Template crossing_set_gorge, scene res://docs/tools/world_forge/out/tpl_crossing_set_gorge/preview.tscn, sim mode off; level load + navmesh bake 1.1 s (31 frames), lab 12.3 s. Spec: -.
