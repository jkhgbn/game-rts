# Art Lab scorecard: hollow_stag

Scene `res://art/units/neutral/hollow_stag/hollow_stag.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-10-12 00:46:43 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **93 / 100** (92.8)

0 FAIL · 2 WARN · 14 PASS · 8 info · 6 skipped · 9 s

## Improve next
1. **Vertices** (WARN): B4 4149 -> 2417 (want <= 2500): `Skull` 1739 -> 870 verts; `Merged` 1520 -> 760 verts; `Shins` 600 -> 497 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Skull 3.02 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (27 surfaces for 9 meshes = 27 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 32 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: (root) 1, Crown 1, Head 1, LegBL 1, LegBR 1, LegFL 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 87 | 10 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 4149 (body + face above its allowance: face 404 v, allowance 600, total 4553; biggest: Skull 1739, Merged 1520, Shins 600, Merged 262) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Leaves) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 8 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Skull, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 10 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 12) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 507 of 4754 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point -0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Skull 3.02 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | PASS 100 | x 1.69 / z 1.99 m (radius 1.0, from hollow_stag.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.99 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 280 shapes over 8 body parts (35.0 per part: Crown 187, Head 18, LegFL 4, LegFR 4, LegBL 4, LegBR 4, Mount 35, ShinSkeleton 24); 15% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.921 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 181% of the 2500 verts budget used (4549) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Head/Crown/Skull 1739 v / 6 s; Root/Mount/Merged 1520 v / 6 s; ShinSkeleton/Shins 600 v / 3 s; Root/Mount/Head/Merged 262 v / 3 s; Root/Mount/LegFL/Merged 114 v / 2 s; Root/Mount/LegFR/Merged 114 v / 2 s; Root/Mount/LegBL/Merged 100 v / 2 s; Root/Mount/LegBR/Merged 100 v / 2 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- Fix recipes: 2 in fixes.json (top: B4 4149 -> 2417 (want <= 2500): `Skull` 1739 -> 870 verts; `Merged` 1520 -> 760 verts; `Shins` 600 -> 497 verts (fewer segments: cylinders 6-8, spheres 10 x 5; )
