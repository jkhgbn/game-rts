# Art Lab scorecard: mirefang

Scene `res://art/units/neutral/mirefang/mirefang.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-28 22:17:58 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **94 / 100** (93.9)

0 FAIL · 2 WARN · 14 PASS · 6 info · 6 skipped · 8 s

## Improve next
1. **Vertices** (WARN): B4 2776 -> 2486 (want <= 2500): `Merged` 986 -> 696 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #2] _(from B9m Meshes built per instance)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (27 surfaces for 10 meshes = 27 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 19 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Head 3, Mount 2, (root) 1, LegBL 1, LegBR 1, LegFL 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 87 | 10 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 46 | 2776 (biggest: Merged 986, Merged 389, Tail 250, Frill 226) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Frill, Merged, Tail, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 7 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 11 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 447 of 3266 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.01 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.5 / z 1.33 m (radius 0.45, from mirefang.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.99 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 133 shapes over 6 body parts (22.2 per part: Head 64, LegFL 9, LegFR 9, LegBL 9, LegBR 9, Mount 33); 21% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.957 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 110% of the 2500 verts budget used (2772) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Head/Merged 986 v / 6 s; Root/Mount/Merged 389 v / 3 s; Root/Mount/Tail 250 v / 4 s; Root/Mount/Head/Frill 226 v / 2 s; Root/Mount/LegFL/Merged 187 v / 2 s; Root/Mount/LegFR/Merged 187 v / 2 s; Root/Mount/LegBL/Merged 187 v / 2 s; Root/Mount/LegBR/Merged 187 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- Fix recipes: 2 in fixes.json (top: B4 2776 -> 2486 (want <= 2500): `Merged` 986 -> 696 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
