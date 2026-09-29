# Art Lab scorecard: tusker

Scene `res://art/units/neutral/beasts/tusker/tusker.tscn` · kind **beast** / tier **hero** · kingdom neutral · ground meadow · 2026-09-28 22:16:49 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **94 / 100** (94.2)

0 FAIL · 1 WARN · 14 PASS · 8 info · 6 skipped · 10 s

## Improve next
1. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #1] _(from B9m Meshes built per instance)_
2. **Vertex use vs budget** (INFO): Only 53% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (25 surfaces for 9 meshes = 25 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, Mount 2, (root) 1, LegBL 1, LegBR 1, LegFL 1 | <= 26 (map-fill.md 10 (epic beast hero budget)) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 16 (map-fill.md 10 (epic beast hero budget)) |  |
| B3 | keep_separate parts | INFO | 2 | no budget for beast/hero |  |
| B4 | Vertices | PASS 100 | 4293 (biggest: Merged 1372, Merged 1043, Bristles 696, Merged 318) | <= 8000 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (epic beast hero budget)) |  |
| B6 | Particle systems | INFO | 3 | no budget for beast/hero |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B7 | Shadow casters | PASS 100 | 4 (TuskR, Merged, Bristles, Merged) | <= 6 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B8 | Unique materials | INFO | 13 | no budget for beast/hero |  |
| B1a | Authored build parts (before the merge) | INFO | 11 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 555 of 5964 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.024 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.77 / z 2.02 m (radius 1.0, from ironhide_tusker.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A2 | death_finished | PASS 100 | after 1.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 148 shapes over 6 body parts (24.7 per part: Head 55, LegFL 6, LegFR 6, LegBL 5, LegBR 5, Mount 71); 9% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.94 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 67 | 53% of the 8000 verts budget used (4289) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (epic beast hero budget))
`{"draw":16,"frame_ms":0.01,"lights":0,"meshes":26,"n":12,"runtime_mats":0,"soft":{"casters":6,"looping":2,"verts":8000},"src":"map-fill.md 10 (epic beast hero budget)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Head/Merged 1372 v / 7 s; Root/Mount/Merged 1043 v / 4 s; Root/Mount/Bristles 696 v / 2 s; Root/Mount/LegFL/Merged 318 v / 3 s; Root/Mount/LegFR/Merged 318 v / 3 s; Root/Mount/LegBL/Merged 241 v / 2 s; Root/Mount/LegBR/Merged 241 v / 2 s; Root/Mount/Head/TuskR 60 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- Fix recipes: 1 in fixes.json (top: B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary)
