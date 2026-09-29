# Art Lab scorecard: rabbit

Scene `res://art/units/neutral/critters/rabbit.tscn` · kind **critter** / tier **rabbit** · kingdom neutral · ground meadow · 2026-09-28 21:31:49 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **94 / 100** (94.2)

0 FAIL · 1 WARN · 10 PASS · 9 info · 6 skipped · 9 s

## Improve next
1. **death_finished** (WARN): A2 death_finished: Emit death_finished at the end of the death timeline (it must fire even at the far distance tier) [fixes.json #1] _(from A2 death_finished)_
2. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_
3. **Detail density at 25 m** (IDEA): Add 1-2 mid-size value accents (trim band, belt, plate edge, markings) that read at 25 m and merge into the big mass at 40 m _(from shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 2 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 1 | no budget for critter/rabbit |  |
| B2 | Draw instances at rest | PASS 100 | 1 | <= 6 soft (map-fill.md 9 (game critter rabbit)) |  |
| B4 | Vertices | INFO | 183 | no budget for critter/rabbit |  |
| B4t | Triangles | PASS 86 | 297 | <= 300 (map-fill.md 9 (game critter rabbit)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (game critter rabbit)) |  |
| B7 | Shadow casters | INFO | 1 | no budget for critter/rabbit |  |
| B8 | Unique materials | PASS 94 | 1 | <= 1 (map-fill.md 9 (game critter rabbit)) |  |
| B1a | Authored build parts (before the merge) | INFO | 1 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 1 surfaces over 1 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 36 of 297 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.17 / z 0.34 m (radius 0.3, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | play_idle, play_move, play_flee, play_hit, play_death |  |
| A2 | death_finished | **WARN** 45 | never (3 s) | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) | Emit death_finished at the end of the death timeline (it must fire even at the far distance tier) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 85 | 13 shapes over 1 body parts (13.0 per part: (root) 13); 7% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.842 | craft (lab v3.1): >= 7 separate shapes per body part, <= 30% plain boxes / prisms, normal variety >= 0.86 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 300 tris budget used (297) | craft (lab v3.1): a finished model uses >= 80% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 (game critter rabbit))
`{"lights":0,"materials":1,"n":30,"soft":{"draw":6,"frame_ms":0.005,"runtime_mats":0},"src":"map-fill.md 9 (game critter rabbit)","tris":300}`

## Notes
- Per-mesh vertices (biggest first): Mesh 183 v / 1 s
- Fix recipes: 1 in fixes.json (top: A2 death_finished: Emit death_finished at the end of the death timeline (it must fire even at the far distance tier))
