# Map Lab: Ashwind Reach scorecard: world_forge_ashwind_reach

2026-10-06 06:40 · lab v1.0 · 3.15 s · scanned 2 spots

## Result: **WARN** · score **97 / 100**

0 FAIL · 1 WARN · 14 PASS · 6 info checks; findings: 0 FAIL, 14 WARN, 5 info

## Improve next
1. **No navmesh islands** (WARN): island 1 at (-71.9, -33.9): 1250.6 m² of ground-level navmesh cut off from the main area (y 0.50) -> a pocket closed by colliders: widen its gap or fill it (trees / rocks) (close or open the pocket) _(from N3 2 / 16 clean (0 FAIL, 14 WARN), 3 info)_
2. **Open the heat map** (IDEA): heatmap.png shows where the shortest paths crowd: the red metres are the likely fights _(from H1)_
3. **Combat heat from bot games** (IDEA): v2: feed Bot Lab / Replay Lab unit deaths into the heat map _(from lab idea)_

## Navmesh (reachability, islands)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N1 | Navmesh baked | PASS 100 | 134 polygons, main area 6644 m² (18 % of the 192 m map), ground y 0.50 | polygons > 0; main walkable area shown |  |
| N2 | Every spot reachable | PASS 100 | 2 / 2 clean | a path from the first keep ends within 1.0 m of each spot; spot <= 6 m from the navmesh |  |
| N3 | No navmesh islands | **WARN** 39 | 2 / 16 clean (0 FAIL, 14 WARN), 3 info | ground-level components other than the main one < 2 m² | close or open the pocket |
| R5 | Engine limits | PASS 100 | 0 half widths ok, 0 arms ok, 0 circles ok, 0 segments ok, 192 x 96 m ok, 2 spots ok, 1.28x ok | one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 2.5x CH |  |
| R6 | Mission marks / triggers / paths reachable | PASS 100 | 5 / 5 clean | every mark, trigger centre and path point reachable from the player's keep; spawns > 20 m from it |  |

## Mirror / symmetry
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Every live spot has its mirror twins | PASS 100 | 2 / 2 clean | same kind within 1.0 m of each symmetry image |  |
| M4 | Spots meet the navmesh at mirrored points | PASS 100 | 2 / 2 clean | each spot's navmesh point vs its twin's, mirrored back: <= 1 m |  |
| M2 | Spot constants mirror | PASS 100 | 0 / 0 clean | every position constant of preview_level.gd: all entries have a twin under each symmetry (+-0.05 m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code) |  |
| M3 | Navmesh mirrors itself | PASS 100 | 0.03 % (36 cells) | cells walkable on one side only (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 % |  |

## Path fairness (navmesh path lengths between every pair of spots)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 1 / 1 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > 2 % (and > 0.75 m), FAIL > 5 % (and > 2 m) |  |
| F2 | Unit paths (NavigationServer): pairs match their twins | PASS 100 | 1 / 1 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > 2 % (and > 0.75 m), WARN > 5 % (and > 2 m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side |  |

## Distances per side
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Keep to nearest camp / point / expansion... equal per seat | PASS 100 | 1 / 1 clean | per kind, the seats' nearest path lengths differ <= 2 % |  |
| A1 | Ally keeps (team maps) | INFO | no side has 2 seats (1v1): nothing to check |  |  |
| T1 | Travel times per seat (worker / soldier / cavalry / caravan) | PASS 100 | 1 / 1 clean | path length / UnitType.move_speed with fords and steps at -35 %; seats' times per destination within 3 s (and 3 %) |  |
| R1 | Targets (rules) | INFO | no `rules` targets in the .map (add `rules tempo=... keep_enemy=a..b natural=a..b`) |  |  |
| R2 | Content per seat | INFO | no `rules` line: content per seat not judged |  |  |
| R3 | Contest per seat | INFO | no `rules` line: contest not judged |  |  |

## Choke points (crossings, narrowest corridors)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Crossing widths | INFO | no river on this map |  |  |
| C2 | Main routes: narrowest corridor matches the twin | PASS 100 | 1 / 1 clean | keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= 1.0 m |  |
| R4 | Clearances (roads, crossings, spacing) | PASS 100 | 2 / 2 clean | points >= 7 m and camps >= 9 m from road centre lines; no spot within 8 m of a crossing (ford nests excepted); spots >= 3 m, structures >= 6 m apart, one den + one lodge per image |  |

## Info
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | Heat map (sum of all shortest paths) | INFO | heatmap.png written (768 x 768 px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots) |  |  |

## Findings (FAIL and WARN)
| Sev | Check | Where | What | Fix |
|---|---|---|---|---|
| WARN | N3 | island 1 at (-71.9, -33.9) | 1250.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 2 at (-23.9, -33.9) | 1250.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 3 at (24.1, -33.9) | 1250.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 4 at (72.1, -33.9) | 1250.6 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 5 at (-92.9, 0.1) | 184.1 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 7 at (-39.9, -17.4) | 25.3 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 8 at (36.1, -17.4) | 25.3 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 9 at (93.1, 0.1) | 184.1 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 14 at (-35.9, 17.6) | 25.3 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 15 at (40.1, 17.6) | 25.3 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 16 at (-71.9, 34.0) | 1238.9 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 17 at (-23.9, 34.0) | 1238.9 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 18 at (24.1, 34.0) | 1238.9 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |
| WARN | N3 | island 19 at (72.1, 34.0) | 1238.9 m² of ground-level navmesh cut off from the main area (y 0.50) | a pocket closed by colliders: widen its gap or fill it (trees / rocks) |

## Spot navmesh points (half_turn)
| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |
|---|---|---|---|---|---|---|
| keep_t0 | keep | (-84.0, 0.0) | (-82.4, -3.4) | keep_t1 | (-81.9, -3.6) | 0.6 |
| keep_t1 | keep | (84.0, 0.0) | (81.9, 3.6) | keep_t0 | (82.4, 3.4) | 0.6 |


## Spot constants (0)
| Constant | Entries | Result |
|---|---|---|


## Keep to nearest spot by kind (navmesh path, m)
| From keep | nearest expansion | nearest point | nearest camp | nearest lair | nearest tavern | nearest post | nearest peddler | nearest cache | nearest crown | enemy keep |
|---|---|---|---|---|---|---|---|---|---|---|
| west | - | - | - | - | - | - | - | - | - | 164.4 |
| east | - | - | - | - | - | - | - | - | - | 164.4 |


## Every spot from the keeps (half_turn)
| Spot | Kind | From keep_t0 | Twin | From keep_t1 | Diff |
|---|---|---|---|---|---|
| keep_t1 | keep | 164.4 | keep_t0 | 164.4 | +0.0 % |


## Travel times per seat (m:ss from the keep; terrain speed costs not included)
| Seat | Destination | Path (m) | Ford (m) | worker (4.6 m/s) | soldier (5.0 m/s) | cavalry (7.5 m/s) | caravan (4.0 m/s) |
|---|---|---|---|---|---|---|---|
| west | enemy keep (keep_t1) | 164.4 | 0.0 | 0:36 | 0:33 | 0:22 | 0:41 |
| east | enemy keep (keep_t0) | 164.4 | 0.0 | 0:36 | 0:33 | 0:22 | 0:41 |


## Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)
| Route | Length | Narrowest (navmesh m) | At | Chokes < 3 m |
|---|---|---|---|---|
| keep_t0 -> keep_t1 | 164.4 | 28.8 | (-37.4, -1.5) | - |


## Hottest metres (every spot-pair shortest path, 1 paths)
| # | Where (x, z) | Shortest paths through this metre | Share |
|---|---|---|---|
| 1 | (20.5, 1.5) | 1 | 100 % |
| 2 | (28.5, 1.5) | 1 | 100 % |
| 3 | (36.5, 1.5) | 1 | 100 % |
| 4 | (-0.5, 0.5) | 1 | 100 % |
| 5 | (7.5, 0.5) | 1 | 100 % |
| 6 | (62.5, 2.5) | 1 | 100 % |
| 7 | (70.5, 3.5) | 1 | 100 % |
| 8 | (78.5, 3.5) | 1 | 100 % |
| 9 | (44.5, 2.5) | 1 | 100 % |
| 10 | (52.5, 2.5) | 1 | 100 % |


## Info findings (5)
| Check | Where | What |
|---|---|---|
| N3 | island 12 at (-83.9, 0.1) | 22.6 m² inside the footprint of keep_t0 (unreachable by design) |
| N3 | island 13 at (84.1, 0.1) | 22.6 m² inside the footprint of keep_t1 (unreachable by design) |
| N3 | raised islands | 3 islands on top of colliders (446 m², more than 0.3 m above / below the ground navmesh): harmless |
| M3 | 4 m tile at (82.0, -2.0) | 12 cells (0.8 m²) walkable on one side only (half_turn) |
| M3 | 4 m tile at (-82.0, 2.0) | 12 cells (0.8 m²) walkable on one side only (half_turn) |

## Notes
- Octile grid shortest paths (0.5 m, 2 sources) 0.36 s.
- Map Lab v2 (map-production.md 2.5): layout ashwind_reach, 2 seats, rules none, 0 fixable findings.
- Navmesh raster 0.95 s (134 polygons, 589824 cells of 0.25 m), spot / mirror checks 0.62 s, 1 paths 0.00 s.
- Map Ashwind Reach, scene res://docs/tools/world_forge/out/ashwind_reach/preview.tscn, sim mode off; level load + navmesh bake 0.2 s (14 frames), lab 2.9 s. Spec: docs/design/wave-strike.md.
