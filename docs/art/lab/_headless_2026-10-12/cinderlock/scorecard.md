# Art Lab scorecard: cinderlock

Scene `res://art/units/fire/cinderlock/cinderlock.tscn` · kind **unit** / tier **soldier** · kingdom fire · ground meadow · 2026-10-12 00:47:14 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **95 / 100** (95.0)

0 FAIL · 1 WARN · 15 PASS · 8 info · 6 skipped · 9 s

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 1.7 -> 2.14 in res://art/units/fire/cinderlock/cinderlock.tscn (root) (the head top; x1.26 now), or lower the head / crest 0.02 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (25 surfaces for 11 meshes = 25 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Chest 3, Head 2, (root) 1, ArmL 1, ArmR 1, LegL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 96 | 11 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 87 | 2396 (body + face above its allowance: face 676 v, allowance 800, total 3072; biggest: Merged 717, Face 676, Merged 543, Musket 425) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 25 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 366 of 3930 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
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
| R8 | Head height vs body_height | **WARN** 51 | head top 2.14 m / body_height 1.7 (x1.26) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | INFO | x 0.79 / z 0.68 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.97 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 81 shapes over 7 body parts (11.6 per part: LegL 4, LegR 4, Head 35, ArmL 3, ArmR 3, Chest 31, Musket 1); 20% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.942 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 122% of the 2500 verts budget used (3068) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 717 v / 5 s; Root/Chest/Head/Face 676 v / 1 s; Root/Chest/Merged 543 v / 5 s; Root/Chest/Musket 425 v / 3 s; Root/Chest/GlowFireGlow 150 v / 1 s; Root/Hips/LegL/Merged 136 v / 2 s; Root/Hips/LegR/Merged 136 v / 2 s; Root/Chest/ArmL/Merged 104 v / 2 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- Fix recipes: 1 in fixes.json (top: R8: body_height 1.7 -> 2.14 in res://art/units/fire/cinderlock/cinderlock.tscn (root) (the head top; x1.26 now), or lower the head / crest 0.02 m)
