# Map Lab: Template pocket_shelf scorecard: world_forge_tpl_pocket_shelf

2026-10-02 18:53 · lab v1.0 · 9.36 s · scanned 2 spots

## Result: **WARN** · score **97 / 100**

0 FAIL · 1 WARN · 11 PASS · 5 info checks; findings: 0 FAIL, 1 WARN, 2 info

## Improve next
1. **No navmesh islands** (WARN): island 2 at (3.1, -6.9): 25.8 m² of ground-level navmesh cut off from the main area (y 0.50) -> a pocket closed by colliders: widen its gap or fill it (trees / rocks) (close or open the pocket) _(from N3 1 / 2 clean (0 FAIL, 1 WARN), 2 info)_
2. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_
3. **Combat heat from bot games** (IDEA): v2: feed Bot Lab / Replay Lab unit deaths into the heat map _(from lab idea)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 44 polygons, main area 6276 m² (98 % of the 80 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 2 / 2 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | **WARN** 52 | 1 / 2 clean (0 FAIL, 1 WARN), 2 info | ground-level components other than the main one < 2 m² | close or open the pocket |
| R5 | Engine limits | PASS 100 | 0 half widths ok, 0 arms ok, 0 circles ok, 0 segments ok, 80 x 80 m ok, 2 spots ok, 0.4x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 2 / 2 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 2 / 2 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
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
| C1 | Crossing widths | INFO | no river on this map |  |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 1 / 1 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings) | PASS 100 | 2 / 2 clean | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted) |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (320 x 320 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | N3 | island 2 at (3.1, -6.9) | 25.8 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |

## Spot navmesh points (-)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|


## Spot constants (0)
| Constant | Entries | Result |
|---|---|---|


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> t_shelf | 40.7 | 39.3 | (-27.2, 24.7) | - |


## Hottest metres (every spot-pair shortest path, 1 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (-16.5, 14.5) | 1 | 100 % |
| 2 | (-22.5, 20.5) | 1 | 100 % |
| 3 | (-29.5, 26.5) | 1 | 100 % |
| 4 | (-0.5, 0.5) | 1 | 100 % |
| 5 | (-7.5, 6.5) | 1 | 100 % |


## Info findings (2)
| Check | Where | What |
|---|---|---|
| N3 | island 4 at (-30.9, 31.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | raised islands | 2 islands on top of colliders (7 m², more than 0.3 m above / below the ground navmesh): harmless |

## Notes
- Octile grid shortest paths (0.5 m, 2 sources) 4.31 s.
- Navmesh raster 3.45 s (44 polygons, 102400 cells of 0.25 m), spot / mirror checks 0.00 s, 1 paths 0.00 s.
- Map Template pocket_shelf, scene res://docs/tools/world_forge/out/tpl_pocket_shelf/preview.tscn, sim mode off; level load + navmesh bake 1.1 s (14 frames), lab 8.2 s. Spec: -.
