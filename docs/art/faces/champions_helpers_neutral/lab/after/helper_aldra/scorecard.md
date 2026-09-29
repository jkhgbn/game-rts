# Art Lab scorecard: helper_aldra

Scene `res://art/units/helpers/helper_aldra/helper_aldra.tscn` · kind **unit** / tier **soldier** · kingdom neutral · ground meadow · 2026-09-28 22:15:35 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **92 / 100** (91.8)

1 FAIL · 1 WARN · 15 PASS · 8 info · 6 skipped · 8 s

## Improve next
1. **Vertices** (FAIL): B4 10957 -> 5502 (want <= 2500): `Merged` 3339 -> 1670 verts; `Merged` 2495 -> 1248 verts; `Merged` 2285 -> 1143 verts; `Merged` 979 -> 490 verts; `Face` 651 -> 326 verts; `Merged` 378 -> 189 verts; `Merged` 359 -> 180 verts; `Merged` 359 -> 180 verts; `Chips` 72 -> 36 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Chips 0.38 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (40 surfaces for 11 meshes = 40 draw calls) _(from B11)_

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
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: ArmR 3, Head 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 93 | 12 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 10957 (biggest: Merged 3339, Merged 2495, Merged 2285, Merged 979) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 94 | 1 (CrystalMotes) | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 6 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 19 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 11 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 40 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1368 of 12758 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.014 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 99 | head top 2.04 m / body_height 2.0 (x1.02) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Chips 0.38 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.61 / z 0.5 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.99 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 304 shapes over 7 body parts (43.4 per part: LegL 6, LegR 6, Hips 77, Head 83, ArmL 10, ArmR 29, Chest 93); 21% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.923 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 438% of the 2500 verts budget used (10953) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 3339 v / 7 s; Root/Chest/Head/Merged 2495 v / 4 s; Root/Hips/Merged 2285 v / 8 s; Root/Chest/ArmR/Merged 979 v / 7 s; Root/Chest/Head/Face 651 v / 1 s; Root/Chest/ArmL/Merged 378 v / 4 s; Root/Hips/LegL/Merged 359 v / 3 s; Root/Hips/LegR/Merged 359 v / 3 s
- 3 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 2 in fixes.json (top: B4 10957 -> 5502 (want <= 2500): `Merged` 3339 -> 1670 verts; `Merged` 2495 -> 1248 verts; `Merged` 2285 -> 1143 verts; `Merged` 979 -> 490 verts; `Face` 651 ->)
