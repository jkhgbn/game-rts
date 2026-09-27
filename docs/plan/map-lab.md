# Map Lab: path fairness, symmetry, distances, chokes, heat map

The Map Lab is the headless check of a skirmish map's layout (Labs program item 6, `docs/plan/waves.md`). It loads the
map scene (map fill on, bots off), waits for the navmesh bake and measures what a map designer argues about: is every
important spot reachable, is the map really mirrored (constants, live spots, the navmesh itself), are the path lengths
between every pair of spots equal to their mirror twins' (map geometry and the paths units really walk), how far each
keep is from the nearest camp / point / expansion, how wide the crossings and the narrowest corridors of the main routes
are, and where all the shortest paths crowd (heat map). It writes a **scorecard** in the Data / Art Lab format
(PASS / WARN / FAIL, measured value, rule, fix hint, **score 0-100**, **"Improve next"**, findings, tables) plus a
**history** row. It never edits the map: findings name the spot / constant and the fix for the owner (systems-coder for
`scripts/world/skirmish.gd`, tech-artist for dressing colliders).

Files: `tools/map_lab/` (`map_lab.gd` entry + `run_on()`, `map_profiles.gd` one profile per map, `map_checks.gd` every
check and **all rule numbers** at the top, `map_grid.gd` navmesh raster / widths / mirror diff / octile Dijkstra / heat
image, `map_report.gd` scorecard + history), test `tests/test_map_lab.gd` (`PASS map_lab`). No `class_name` (preloaded).

## 1. One command
```powershell
cd C:\Users\elzzo\Documents\four-wizards-rts
& .\tools\godot_run.ps1 --headless --path . -s res://tools/map_lab/map_lab.gd --fixed-fps 60 --quit-after 9000 '--' map=1v1
```
**Quote the `'--'`** when going through `godot_run.ps1`: PowerShell eats a bare `--`, and the lab then sees no arguments
(it still runs with the defaults). Called on the Godot exe directly, a bare `--` works.

| Arg (after `--`) | Meaning |
|---|---|
| `map=` | `1v1` (Crown Hollow, default) or `2v2` (Fourfold Hollow, `docs/design/map-2v2.md`; prints `MAP LAB: SKIP` and exits 0 until `scenes/skirmish_2v2.tscn` exists) |
| `scene=` | another scene path for the profile (e.g. the 2v2 under another name) |
| `out=` | output folder, default `docs/maps/lab/<run>/` |
| `run=` | run name, default `<date>_<time>_<map>` (`2026-09-26_2358_1v1`) |
| `log=0` | no row in `docs/maps/lab/history.md` (experiments) |
| `heat=0` | no heat map |
| `sim=0` | load the full art (default: Bot Lab sim mode = same colliders and navmesh, no draw-only art, faster load) |

Runtime ~40 s on the 1v1 (load + bake ~12 s, octile Dijkstra from 59 spots ~20 s, the rest ~5 s). Exit code **1 on any
FAIL**. Console: `MAP LAB: <RESULT> score <N> / 100 (...)` then one line per FAIL / WARN check. Output: `scorecard.md`,
`scorecard.json`, `heatmap.png` in the out folder, one row in `docs/maps/lab/history.md` (one history for all maps; the
score delta compares with the previous row of the same map).

Test: `& .\tools\godot_run.ps1 --headless --path . -s tests/test_map_lab.gd --fixed-fps 60 --quit-after 9000` (grid maths on
a synthetic navmesh with a one-sided bump and an island, every constant-mirror rule on synthetic entries, the 2v2
profile's symmetries map the A1 keep onto the other 3 keeps, then one real run on Crown Hollow into `user://`).

## 2. What it reads
- **Profile** (`map_profiles.gd`): scene, half size, **symmetries** (1v1: half turn `(x, z) -> (-x, -z)`; 2v2: mirror x,
  mirror z, half turn), **seats** (team, name, side), settings put on the level before it enters the tree.
- **Spots, from the live level** (so a new map needs no spot list): keeps (group `buildings`, `is Keep`), crystal nodes
  (group `crystal_nodes`; within 16 m of a keep = home node, else expansion), capture points, neutral camps, taverns,
  trade posts, guild houses (Den / Lodge), peddlers, Lost Caches (their groups), lairs (`LAIR_SPOTS` of the map script:
  no lair node exists before a beast spawns), river crossings (`RiverSystem.crossings()`), the crown. 59 spots on the 1v1.
- **The navmesh**: every `NavigationRegion3D` polygon rasterised on a 0.25 m grid (one pixel of the heat map), split into
  connected components by shared edges. The largest is the main navmesh; the others are islands. Note: the navmesh is
  shrunk by the agent radius (0.5 m), so "navmesh width W" means a real gap of about W + 1.0 m.
- **Where a spot meets the navmesh**: the nearest main-navmesh cell (a building's own centre is inside its footprint, and
  the plain `map_get_closest_point` often lands on its roof island). The twins of a spot take the mirror image of its
  point (so a square building doesn't start the path on another face); a spot that is its own twin (the crown) counts as
  all mirror images of its point (distance to the nearest).

## 3. The checks (numbers at the top of `tools/map_lab/map_checks.gd`)
Scored like the other labs (PASS = 100, WARN 35-69, FAIL 0-34 graded by the share of clean items). Group weights: nav x2,
fair x2, mirror x1.5, dist / choke x1.

| # | Check | Rule |
|---|---|---|
| N1 | Navmesh baked | polygons > 0; main area and its height shown |
| N2 | Every spot reachable | a NavigationServer path from the first keep ends within 1 m of the spot (FAIL); a spot > 6 m from the navmesh = WARN (buried in a collider) |
| N3 | No navmesh islands | ground-level components (same height as the main navmesh +-0.3 m) >= 2 m² = WARN; pockets inside a building footprint and islands on top of colliders (rocks, roofs) = INFO |
| M1 | Live spots have their twins | every spot has a spot of the same kind within 1 m of each symmetry image (FAIL) |
| M2 | Spot constants mirror | every position constant of the map script and its base scripts (`Vector3`, arrays of `Vector3` / `Vector2`, dicts with `pos` / `center`, `patrol` / `spots` arrays, `[pos, r, n]` rows): the whole list mirrors onto itself (+-0.05 m) with the same `kind`, and twins agree on every other field (tier, first_spawn, respawn, width, length, radius...), on the mirrored `door`, on `dir` as a line, and on the mirrored `patrol` / `spots` points (FAIL); a list with no twin at all = one-sided, mirrored in code (INFO: `FIRE_NODES`, `LANDMARK_SPOTS`, `RIVER_POLYLINE_N`, slots...) |
| M3 | Navmesh mirrors itself | cells on the main navmesh whose mirror image is not (1-cell edge noise ignored): WARN > 0.3 %, FAIL > 2 %; the worst 4 m tiles name where the unmirrored collider is |
| M4 | Spots meet the navmesh at mirrored points | a spot's navmesh point vs its twin's, mirrored back: <= 1 m (WARN) |
| F1 | **Map geometry** fair | octile shortest path on a 0.5 m grid of the main navmesh (exactly mirror-invariant) for every spot pair vs its mirrored pair: WARN > 2 % and > 0.75 m, FAIL > 5 % and > 2 m |
| F2 | **Unit paths** fair | the same with `NavigationServer3D.map_get_path` (what units walk): INFO > 2 %, WARN > 5 % and > 2 m. The polygon A* runs on a triangulation that is not mirrored, so F2 measures how much the engine's path choice (not the map) favours a side |
| D1 | Keep distances per seat | per kind (expansion, point, camp, lair, tavern, post, peddler, cache, crown, enemy keep) the nearest unit-path length from each keep; seats differ <= 2 % (WARN) |
| A1 | Ally keeps (team maps; INFO on a 1v1) | per seat with an ally (same `side`): path to the ally keep, nearest / farthest enemy keep. WARN: ally paths differ between sides > 2 %, ally > 1.25 x the nearest enemy keep, the ally road crosses the river (profile `ally_dry`), a profile `targets` distance (`ally_keep`, `enemy_keep_near`, `enemy_keep_far`, from the map spec) missed by > 10 %. Table "Ally keeps per seat" |
| T1 | Travel times per seat | keep -> ally keep(s), every enemy keep, nearest expansion / point / camp, crown: path length / `UnitType.move_speed` for worker (`cinder_hand`), soldier (`flame_guard`), cavalry (`blaze_rider`), caravan (`caravan`), ford / steps metres at `FORD_SLOW` -35 %; seats' times per destination within 3 s and 3 % (WARN). Table "Travel times per seat" (m:ss) |
| C1 | Crossing widths | navmesh width across each crossing (fords: along the flow; bridges / steps: across `dir`) >= 2 m and equal to its twin +-0.5 m (WARN) |
| C2 | Main-route chokes | keep -> crown, keep -> enemy keep, keep -> nearest expansion: navmesh width sampled every metre (4 m from the ends skipped), narrowest point and every choke < 3 m; the twin route's narrowest point within 1 m (WARN) |
| H1 | Heat map | `heatmap.png`: 4 px per metre, +x right / +z down (the minimap view); dark = no navmesh, grey = navmesh, blue = islands, yellow -> red = how many of the 1 711 spot-pair unit paths cross that metre; dots = spots. Table of the 10 hottest metres |

Tables in the scorecard: spot constants, spot navmesh points, F1 / F2 worst pairs (top 20), keep to nearest spot by kind,
every spot from both keeps with the diff, crossings, main routes with chokes, hottest metres.

## 4. First results (2026-09-26, lab v1.0, Crown Hollow 1v1, map fill on)
Scorecard: `docs/maps/lab/2026-09-27_0002_1v1/scorecard.md` + `heatmap.png` (row in `docs/maps/lab/history.md`).
**Result WARN, score 98 / 100: 0 FAIL, 1 WARN (F2), 11 PASS**, 36.5 s.
- **The map is fair.** 59 spots all reachable; every live spot has its twin; the 31 position constants of
  `skirmish.gd` / `main.gd` mirror (11 one-sided lists / slots are mirrored in code: INFO); the navmesh mirrors to 0.03 %
  (64 cells of edge noise); **812 / 812 spot pairs** have the same geometric path length as their mirror pair (< 2 %).
- **Unit paths are not quite fair (F2 WARN, engine noise):** 741 / 870 pairs within 2 %, 87 at 2-5 % (INFO), 42 above
  5 %. Worst: `node_fire_a -> heron_ford` 38.4 m vs `node_shadow_a -> lantern_wharf` 45.5 m (15 %), `tower_nw -> LostCache3`
  40.8 vs 35.2 m, `tower_nw -> tower_n` 37.7 vs 32.8 m. The map is symmetric, so this is Godot's polygon A* (not optimal on
  large polygons, triangulation not mirrored): units of one side sometimes walk a longer way for the same trip. Candidate
  fixes (lead / systems-coder): smaller navmesh polygons (`edge_max_length`, `region_min_size`), or `path_postprocessing`
  / a string-pulling pass. Worth a Bot Lab A/B before touching it.
- **Distances are equal per seat:** keep -> nearest expansion (natural) 47.0 m, capture point 34.8 / 35.4 m, camp 30.8,
  lair 33.1, trading post 40.4 / 40.6, cache 37.3, crown 58.0, **enemy keep 116.0 m** (unit path).
- **Crossings:** road bridges 5.0 m of navmesh (~6 m real), fords 6.1 (~7), Crown Bridges 7.1 (~8), Crown Steps 5.0 / 4.9;
  twins equal. **Main routes** never go under 6.9 m (the Crown Bridges are the narrowest point of the lane); no choke < 3 m.
- **Heat map:** the two **fords are the busiest metres of the map** (11 % and 10 % of all spot-pair paths cross them),
  then the Crown Isle approach (5.5, 6.5) and the natural-expansion roads (+-17.5, +-7.5). That is where fights will be.

## 5. Rule to add (for the lead, next map / map-fill tasks)
> **N. Map Lab (every task that moves a spot, a collider, a crossing or the river, `docs/plan/map-lab.md`).** Before your
> report, run `& .\tools\godot_run.ps1 --headless --path . -s res://tools/map_lab/map_lab.gd --fixed-fps 60 --quit-after 9000`
> (about 40 s) and open `docs/maps/lab/<run>/scorecard.md` + `heatmap.png`. **No new FAIL**; N2 / M1 / M2 / M3 / F1 must stay
> PASS on a mirrored map. Report the score before / after and end with **"Map Lab notes"** (false alarms, checks to add).
> Never edit `tools/map_lab/` yourself.

## 6. 2v2 readiness (Fourfold Hollow)
The `2v2` profile is in place (168 m, 3 symmetries, 4 seats PLAYER 0 / ALLY 3 / ENEMY 1 / ENEMY_2 4, sides from
`map-2v2.md` 2.1); the test checks its symmetries map the A1 keep `(-66, 66)` onto the other three keeps. Everything else is
generic: spots come from groups, the pair check runs once per symmetry, D1 compares all 4 seats, C2 builds keep -> crown /
every enemy keep / nearest expansion per seat. What the 2v2 needs when its scene lands:
- the scene path (`scenes/skirmish_2v2.tscn` assumed; else `scene=`), keeps findable as `Keep` in group `buildings` with
  `team` = seat;
- `LAIR_SPOTS` (or lair nodes in a group) on its map script; its position constants mirrored under the 4-way symmetry
  (canonical-quadrant lists read as "one-sided" INFO, which is right for `seat_frame`-placed tables);
- runtime: ~4x the navmesh cells and ~2x the spots, so the octile Dijkstra will take ~2-3 min; if too slow, v2 can run it
  on a 1 m grid for maps with `half_size > 70`.

**2v2 support (tools upgrade U5, 2026-09-27):** generic for N seats. The profile's `seats` give the sides; **A1** checks the
ally distance (equal per side, not much farther than the nearest enemy, `ally_dry` = the ally road never crosses the river,
`targets` from `map-2v2.md` 1: ally ~142 m, facing enemy ~142 m, diagonal enemy ~187 m, +-10 %); **T1** is the
travel-time table (per seat, per unit class, ford slow included). A World Forge `map_profile.json` can carry `targets` /
`ally_dry` too (read as-is). On the 1v1, A1 is INFO and T1 PASS (enemy keep 116 m = 0:23 soldier / 0:15 cavalry /
0:29 caravan). The 2v2 audit (`docs/design/map-2v2-audit.md`, written in parallel) was not out yet: its numbers go into
the 2v2 profile's `targets` when it lands.
First 4-seat run (World Forge `fourfold_hollow/map_profile.json`, preview scene, `log=0 heat=0`, 157 s): A1 PASS (ally 124.3 m by
road on every seat, dry; nearest enemy 135-136 m, diagonal 181 m: ~13 % under the map-2v2.md targets, which the WF profile
does not carry), T1 WARN (enemy keep #2 by caravan 0:45 vs 0:48 between seats: engine path noise like F2).

## 7. Known limits
- F2 / D1 / C2 / the heat map use `map_get_path` (what units walk), F1 the grid geometry; the octile metric overestimates
  diagonal-ish lengths by up to ~8 %, identically on both sides (it only compares, never reports absolute lengths).
- A spot's navmesh point is the nearest walkable cell to its centre: for buildings with a door on one face that is not the
  door. Posts / guilds have a `door` in the constants; v2 can use it.
- Ford slow (`terrain:ford` -35 %) and terrain speed are not in the path lengths yet (lengths, not times).
- Crossing widths are measured through the crossing centre only; a bridge narrower at its ends would not show.
- Islands on top of colliders are counted but not listed (INFO); a mis-sized collider top could hide there.

## 8. Next steps (Map Lab v2 backlog)
- Travel times: done in U5 (T1, ford slow in); still to add: the step-12b terrain speed costs per path metre.
- **Combat heat** from Bot Lab / Replay Lab games (unit deaths, fights) next to the path heat.
- Doors as spot points (posts, guilds, taverns); vision / fog checks (watchtower sight radius coverage per side).
- F2 root cause: try a finer bake in a lab copy and report how much F2 improves (no game change without the lead).
- 2v2 run as soon as `scenes/skirmish_2v2.tscn` exists; 1 m Dijkstra grid for big maps.

Progress: v1.0 done 2026-09-27 00:05 (all checks above, first scorecard + heat map on Crown Hollow, `tests/test_map_lab.gd`
PASS; 2v2 prints SKIP until its scene exists). Not done in v1: travel times, door points, combat heat (section 8).
