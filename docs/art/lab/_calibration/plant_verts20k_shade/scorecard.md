# Art Lab scorecard: plant_verts20k_shade

Scene `res://tools/art_lab/calibration/virtual/plant_verts20k_shade.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-09-30 11:46:24 · lab v3.1

## Result: **FAIL** · quality **92 / 100** (91.7)

1 FAIL · 0 WARN · 15 PASS · 8 info · 6 skipped · 8 s

## Improve next
1. **Vertices** (FAIL): B4 20639 -> 10350 (want <= 2500): `Merged` 19645 -> 9823 verts; `Merged` 253 -> 127 verts; `Merged` 229 -> 115 verts; `Merged` 191 -> 96 verts; `Merged` 132 -> 66 verts; `Merged` 132 -> 66 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (18 surfaces for 10 meshes = 18 draw calls) _(from B11)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 20639 (body + face above its allowance: face 497 v, allowance 800, total 21136; biggest: Merged 19645, Face 497, Merged 253, Merged 229) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 11 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 27 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 18 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 9754 of 40772 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | fail_fast: stopped after a headless FAIL | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | fail_fast: stopped after a headless FAIL | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | fail_fast: stopped after a headless FAIL | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | fail_fast: stopped after a headless FAIL | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | fail_fast: stopped after a headless FAIL | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | fail_fast: stopped after a headless FAIL | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 94 | head top 1.77 m / body_height 1.6 (x1.11) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.64 / z 0.33 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.89 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 58 | 44 shapes over 7 body parts (6.3 per part: LegL 2, LegR 2, Hips 1, Head 23, ArmL 4, ArmR 5, Chest 7); 37% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.839 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 845% of the 2500 verts budget used (21132) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 19645 v / 4 s; Root/Chest/Head/Face 497 v / 1 s; Root/Chest/ArmR/Merged 253 v / 3 s; Root/Chest/ArmL/Merged 229 v / 2 s; Root/Chest/Head/Merged 191 v / 3 s; Root/Hips/LegL/Merged 132 v / 1 s; Root/Hips/LegR/Merged 132 v / 1 s; Root/Hips/Merged 37 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- fail_fast=1: stopped after the headless checks (FAIL B4); render checks SKIP
- Fix recipes: 1 in fixes.json (top: B4 20639 -> 10350 (want <= 2500): `Merged` 19645 -> 9823 verts; `Merged` 253 -> 127 verts; `Merged` 229 -> 115 verts; `Merged` 191 -> 96 verts; `Merged` 132 -> )
