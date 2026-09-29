# Art Lab scorecard: tracker

Scene `res://art/units/neutral/tracker/tracker.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-28 21:32:57 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **93 / 100** (93.0)

0 FAIL · 1 WARN · 15 PASS · 7 info · 6 skipped · 8 s

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.45 -> 0.56, or pull the widest parts in to x <= 0.79 / z <= 0.79 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (33 surfaces for 9 meshes = 33 draw calls) _(from B11)_
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
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: ArmR 2, (root) 1, ArmL 1, Chest 1, Head 1, Hips 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 91 | 9 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | PASS 85 | 2498 (biggest: Merged 672, Merged 492, Merged 401, Crossbow 388) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Crossbow, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 13 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 16 (model says 16) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 264 of 2836 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
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
| R8 | Head height vs body_height | PASS 94 | head top 1.98 m / body_height 1.8 (x1.1) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.97 / z 0.77 m (radius 0.45, from greywater_tracker.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.97 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 84 | 89 shapes over 7 body parts (12.7 per part: LegL 5, LegR 5, Hips 16, Head 11, ArmL 6, ArmR 21, Chest 25); 34% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.882 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 2500 verts budget used (2494) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 672 v / 6 s; Root/Hips/Merged 492 v / 5 s; Root/Chest/Head/Merged 401 v / 5 s; Root/Chest/ArmR/Crossbow 388 v / 5 s; Root/Chest/ArmL/Merged 196 v / 3 s; Root/Hips/LegL/Merged 123 v / 3 s; Root/Hips/LegR/Merged 123 v / 3 s; Root/Chest/ArmR/Merged 99 v / 2 s
- 1 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 1 in fixes.json (top: R10: raise UnitType.radius 0.45 -> 0.56, or pull the widest parts in to x <= 0.79 / z <= 0.79 m)
