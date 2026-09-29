# Art Lab scorecard: stormbottle_genie

Scene `res://art/units/neutral/stormbottle_genie/stormbottle_genie.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-28 21:32:48 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **97 / 100** (96.7)

0 FAIL · 1 WARN · 14 PASS · 9 info · 6 skipped · 8 s

## Improve next
1. **Vertices** (WARN): B4 4407 -> 2419 (want <= 2500): `Merged` 1353 -> 677 verts; `Merged` 1172 -> 586 verts; `Merged` 727 -> 364 verts; `Merged` 727 -> 364 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (25 surfaces for 6 meshes = 25 draw calls) _(from B11)_
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
| B1 | Meshes after the kit merge | PASS 100 | 6 drawn (6 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 100 | 7 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 4407 (biggest: Merged 1353, Merged 1172, Merged 727, Merged 727) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (LipSparks) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 4 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 13 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 69 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 6 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 863 of 5790 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | INFO | flyer: lowest point 0.28 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R8 | Head height vs body_height | PASS 98 | head top 2.69 m / body_height 2.6 (x1.03) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.93 / z 0.45 m (radius 0.7, from stormbottle_genie.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.95 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 89 shapes over 5 body parts (17.8 per part: Hips 34, Head 11, ArmL 11, ArmR 11, Chest 22); 10% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.955 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 176% of the 2500 verts budget used (4403) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Hips/Merged 1353 v / 5 s; Root/Chest/Merged 1172 v / 6 s; Root/Chest/ArmL/Merged 727 v / 5 s; Root/Chest/ArmR/Merged 727 v / 5 s; Root/Chest/Head/Merged 424 v / 3 s; Shadow 4 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 1 in fixes.json (top: B4 4407 -> 2419 (want <= 2500): `Merged` 1353 -> 677 verts; `Merged` 1172 -> 586 verts; `Merged` 727 -> 364 verts; `Merged` 727 -> 364 verts (fewer segments: cy)
