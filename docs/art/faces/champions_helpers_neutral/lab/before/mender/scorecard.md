# Art Lab scorecard: mender

Scene `res://art/units/champions/mender/mender.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-28 21:29:21 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **89 / 100** (88.8)

1 FAIL · 2 WARN · 15 PASS · 7 info · 6 skipped · 11 s

## Improve next
1. **Unique materials** (FAIL): B8 8 -> 8 materials: use one material for look-alike pairs (albedo dE <= 15): (no look-alike pair of the same shader) Snap to the closed palette (art-units 2.2); no per-part materials; 3 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.76 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Vertices** (WARN): B4 7814 -> 3911 (want <= 3000): `Merged` 2993 -> 1497 verts; `Merged` 884 -> 442 verts; `Merged` 707 -> 354 verts; `StaffMesh` 544 -> 272 verts; `Kettle` 510 -> 255 verts; `Core` 432 -> 216 verts; `Jars` 344 -> 172 verts; `Merged` 338 -> 169 verts; `Merged` 338 -> 169 verts; `Variant` 270 -> 135 verts; `Merged` 225 -> 113 verts; `Merged` 225 -> 113 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 28 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 13 drawn (13 mesh + 0 multimesh); per pivot: Censer 2, Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 7814 (biggest: Merged 2993, Merged 884, Merged 707, StaffMesh 544) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (Steam) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | **FAIL** 0 | 8 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 25 (model says 25) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1661 of 11094 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
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
| R8 | Head height vs body_height | PASS 91 | head top 1.95 m / body_height 1.7 (x1.15) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.76 m | narrower than 0.6 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.9 / z 0.72 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.85 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 117 shapes over 9 body parts (13.0 per part: LegL 4, LegR 4, Hips 8, Head 16, ArmL 4, Staff 12, Censer 20, ArmR 4, Chest 45); 10% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.951 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 260% of the 3000 verts budget used (7810) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 2993 v / 4 s; Root/Chest/Head/Merged 884 v / 1 s; Root/Hips/Merged 707 v / 1 s; Root/Chest/ArmR/Staff/StaffMesh 544 v / 1 s; Root/Chest/ArmR/Staff/Censer/Kettle 510 v / 1 s; Root/Chest/ArmR/Staff/Censer/Core 432 v / 1 s; Root/Chest/Jars 344 v / 1 s; Root/Chest/ArmL/Merged 338 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 3 in fixes.json (top: B8 8 -> 8 materials: use one material for look-alike pairs (albedo dE <= 15): (no look-alike pair of the same shader) Snap to the closed palette (art-units 2.2))
