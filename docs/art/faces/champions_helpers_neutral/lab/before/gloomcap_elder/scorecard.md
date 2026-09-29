# Art Lab scorecard: gloomcap_elder

Scene `res://art/units/neutral/gloomcap/gloomcap_elder.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-28 21:31:58 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **97 / 100** (96.8)

0 FAIL · 1 WARN · 15 PASS · 8 info · 6 skipped · 8 s

## Improve next
1. **Vertices** (WARN): B4 3180 -> 2466 (want <= 2500): `Merged` 1132 -> 566 verts; `Merged` 551 -> 403 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (18 surfaces for 8 meshes = 18 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 20 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 91 | 9 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 37 | 3180 (biggest: Merged 1132, Merged 551, Merged 542, Merged 412) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Spores) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 7 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 10 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 8 (model says 8) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 18 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 950 of 4548 triangles (20%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.011 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.9 m / body_height 1.9 (x1.0) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 1.04 / z 0.86 m (radius 0.6, from gloomcap_elder.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.95 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 68 shapes over 7 body parts (9.7 per part: LegL 6, LegR 6, Hips 2, Head 13, ArmL 14, ArmR 14, Chest 13); 6% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.96 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 127% of the 2500 verts budget used (3176) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 1132 v / 4 s; Root/Chest/Merged 551 v / 4 s; Root/Chest/ArmR/Merged 542 v / 2 s; Root/Chest/ArmL/Merged 412 v / 3 s; Root/Hips/LegL/Merged 187 v / 1 s; Root/Hips/LegR/Merged 187 v / 1 s; Root/Hips/Merged 165 v / 2 s; Shadow 4 v / 1 s
- Fix recipes: 1 in fixes.json (top: B4 3180 -> 2466 (want <= 2500): `Merged` 1132 -> 566 verts; `Merged` 551 -> 403 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces)
