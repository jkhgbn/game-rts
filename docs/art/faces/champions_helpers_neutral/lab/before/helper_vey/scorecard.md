# Art Lab scorecard: helper_vey

Scene `res://art/units/helpers/helper_vey/helper_vey.tscn` · kind **unit** / tier **soldier** · kingdom neutral · ground meadow · 2026-09-28 21:30:29 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **95 / 100** (94.6)

1 FAIL · 0 WARN · 15 PASS · 8 info · 6 skipped · 8 s

## Improve next
1. **Vertices** (FAIL): B4 6070 -> 3039 (want <= 2500): `Merged` 1968 -> 984 verts; `Merged` 808 -> 404 verts; `Merged` 667 -> 334 verts; `Merged` 590 -> 295 verts; `Face` 492 -> 246 verts; `StormRunes` 426 -> 213 verts; `Cape` 294 -> 147 verts; `Merged` 279 -> 140 verts; `Merged` 279 -> 140 verts; `Merged` 263 -> 132 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (45 surfaces for 11 meshes = 45 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: ArmR 2, Chest 2, Head 2, (root) 1, ArmL 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 93 | 12 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 6070 (biggest: Merged 1968, Merged 808, Merged 667, Merged 590) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 94 | 1 (StormSparks) | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 6 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 20 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 13 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 45 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 855 of 6455 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 98 | head top 2.08 m / body_height 2.0 (x1.04) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.74 / z 1.05 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.97 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 94 | 101 shapes over 7 body parts (14.4 per part: LegL 5, LegR 5, Hips 15, Head 43, ArmL 3, ArmR 12, Chest 18); 23% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.907 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 242% of the 2500 verts budget used (6066) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 1968 v / 4 s; Root/Chest/Merged 808 v / 7 s; Root/Chest/ArmR/Merged 667 v / 5 s; Root/Hips/Merged 590 v / 6 s; Root/Chest/Head/Face 492 v / 7 s; Root/Chest/ArmR/StormRunes 426 v / 1 s; Root/Chest/Cape 294 v / 3 s; Root/Hips/LegL/Merged 279 v / 4 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 1 in fixes.json (top: B4 6070 -> 3039 (want <= 2500): `Merged` 1968 -> 984 verts; `Merged` 808 -> 404 verts; `Merged` 667 -> 334 verts; `Merged` 590 -> 295 verts; `Face` 492 -> 246 v)
