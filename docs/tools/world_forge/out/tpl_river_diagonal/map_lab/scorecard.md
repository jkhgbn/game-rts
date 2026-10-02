# Map Lab: Template river_diagonal scorecard: world_forge_tpl_river_diagonal

2026-10-02 18:54 · lab v1.0 · 72.76 s · scanned 9 spots

## Result: **PASS** · score **100 / 100**

0 FAIL · 0 WARN · 13 PASS · 4 info checks; findings: 0 FAIL, 0 WARN, 2 info

## Improve next
1. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_
2. **Combat heat from bot games** (IDEA): v2: feed Bot Lab / Replay Lab unit deaths into the heat map _(from lab idea)_
3. **Terrain costs in travel times** (IDEA): T1 has the ford slow; add the step-12b terrain speed costs (mud, heath) per path metre _(from lab idea)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 206 polygons, main area 27384 m² (97 % of the 168 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 9 / 9 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | PASS 100 | 1 / 1 clean, 2 info | ground-level components other than the main one < 2 m² |  |
| R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 168 x 168 m ok, 1 spots ok, 2.0x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 9 / 9 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 9 / 9 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
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
| C1 | Crossing widths | PASS 100 | 8 / 8 clean | navmesh width across each crossing >= 2.0 m and equal to its twin (+-0.5 m) |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 0 / 0 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | PASS 100 | 1 / 1 clean | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (672 x 672 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
None.

## Spot navmesh points (-)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|


## Spot constants (0)
| Constant | Entries | Result |
|---|---|---|


## Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)
| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |
|---|---|---|---|---|---|---|
| t_x_bridge_road_n | bridge_road | 6.0 | 4.3 | 5.3 | - | - |
| t_x_bridge_road_s | bridge_road | 6.0 | 4.3 | 5.3 | - | - |
| t_x_ford_n | ford | 7.0 | 4.9 | 5.9 | - | - |
| t_x_ford_s | ford | 7.0 | 4.9 | 5.9 | - | - |
| t_x_bridge_crown_w | bridge_lane | 8.0 | 7.1 | 8.1 | - | - |
| t_x_bridge_crown_e | bridge_lane | 8.0 | 7.1 | 8.1 | - | - |
| t_x_steps_nw | steps | 6.0 | 5.1 | 6.1 | - | - |
| t_x_steps_se | steps | 6.0 | 5.1 | 6.1 | - | - |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|


## Hottest metres (every spot-pair shortest path, 36 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-8.5, -8.5) | 10 | 28 % |
| 2 | (8.5, 8.5) | 9 | 25 % |
| 3 | (-8.5, 8.5) | 9 | 25 % |
| 4 | (11.5, 29.5) | 9 | 25 % |
| 5 | (-8.5, -33.5) | 8 | 22 % |
| 6 | (11.5, 48.5) | 8 | 22 % |
| 7 | (8.5, -8.5) | 8 | 22 % |
| 8 | (-70.5, 73.5) | 8 | 22 % |
| 9 | (-11.5, -48.5) | 8 | 22 % |
| 10 | (10.5, 21.5) | 6 | 17 % |


## Info findings (2)
| Check | Where | What |
|---|---|---|
| N3 | island 10 at (-74.9, 75.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 9 islands on top of colliders (443 m², more than 0.3 m above / below the ground navmesh): harmless |

## Notes
- Octile grid shortest paths (0.5 m, 9 sources) 53.16 s.
- Navmesh raster 15.19 s (206 polygons, 451584 cells of 0.25 m), spot / mirror checks 0.00 s, 36 paths 0.01 s.
- Map Template river_diagonal, scene res://docs/tools/world_forge/out/tpl_river_diagonal/preview.tscn, sim mode off; level load + navmesh bake 4.1 s (1091 frames), lab 68.6 s. Spec: -.
