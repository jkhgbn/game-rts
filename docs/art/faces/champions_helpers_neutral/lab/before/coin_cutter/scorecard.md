# Art Lab scorecard: coin_cutter

Scene `res://art/units/champions/coin_cutter/coin_cutter.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-28 21:28:59 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **94 / 100** (93.5)

1 FAIL · 1 WARN · 15 PASS · 7 info · 6 skipped · 11 s

## Improve next
1. **Unique materials** (FAIL): B8 7 -> 7 materials: use one material for look-alike pairs (albedo dE <= 15): (no look-alike pair of the same shader) Snap to the closed palette (art-units 2.2); no per-part materials; 2 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Vertices** (WARN): B4 3355 -> 2982 (want <= 3000): `Merged` 682 -> 341 verts; `Merged` 557 -> 525 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (31 surfaces for 10 meshes = 31 draw calls) _(from B11)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Head 2, Hips 2, (root) 1, ArmL 1, ArmR 1, Chest 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 45 | 3355 (biggest: Merged 682, Merged 557, Merged 447, Merged 381) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | **FAIL** 4 | 7 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 18 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 31 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 571 of 4262 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.018 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 97 | head top 1.8 m / body_height 1.7 (x1.06) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R10 | Footprint vs selection radius | INFO | x 0.56 / z 0.46 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.95 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 98 | 77 shapes over 7 body parts (11.0 per part: LegL 5, LegR 5, Hips 26, Head 12, ArmL 8, ArmR 8, Chest 13); 34% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.916 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 111% of the 3000 verts budget used (3351) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 682 v / 4 s; Root/Chest/Head/Merged 557 v / 4 s; Root/Hips/Merged 447 v / 3 s; Root/Chest/ArmL/Merged 381 v / 3 s; Root/Chest/ArmR/Merged 381 v / 3 s; Root/Hips/LootSack 337 v / 4 s; Root/Hips/LegL/Merged 189 v / 3 s; Root/Hips/LegR/Merged 189 v / 3 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 2 in fixes.json (top: B8 7 -> 7 materials: use one material for look-alike pairs (albedo dE <= 15): (no look-alike pair of the same shader) Snap to the closed palette (art-units 2.2))
