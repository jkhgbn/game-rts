# Art Lab scorecard: mage_archer

Scene `res://art/units/champions/mage_archer/mage_archer.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-28 22:14:44 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **89 / 100** (88.9)

1 FAIL · 2 WARN · 15 PASS · 7 info · 6 skipped · 10 s

## Improve next
1. **Unique materials** (FAIL): B8 12 -> 9 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-77345` -> `StandardMaterial3D#-59610` (dE 0.0), `StandardMaterial3D#-97401` -> `StandardMaterial3D#-59610` (dE 0.0), `shadow_skin` -> `shadow_silver` (dE 9.6); 4 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #3] _(from B9m Meshes built per instance)_
3. **Vertices** (WARN): B4 8662 -> 4336 (want <= 3000): `Variant` 2382 -> 1191 verts; `Bow` 1333 -> 667 verts; `Quiver` 1205 -> 603 verts; `Merged` 805 -> 403 verts; `Merged` 592 -> 296 verts; `Merged` 584 -> 292 verts; `Face` 478 -> 239 verts; `Merged` 361 -> 181 verts; `Merged` 345 -> 173 verts; `Merged` 345 -> 173 verts; `Merged` 228 -> 114 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, Chest 2, (root) 1, ArmL 1, Hips 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 8662 (biggest: Variant 2382, Bow 1333, Quiver 1205, Merged 805) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (QuiverMotes) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | **FAIL** 0 | 12 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1107 of 11422 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
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
| R8 | Head height vs body_height | PASS 98 | head top 2.03 m / body_height 1.95 (x1.04) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R10 | Footprint vs selection radius | INFO | x 0.81 / z 0.55 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.99 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 82 | 247 shapes over 7 body parts (35.3 per part: LegL 9, LegR 9, Hips 15, Head 107, ArmL 6, ArmR 57, Chest 44); 34% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.876 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 288% of the 3000 verts budget used (8658) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Variant 2382 v / 3 s; Root/Chest/ArmR/Bow 1333 v / 3 s; Root/Chest/Quiver 1205 v / 3 s; Root/Hips/Merged 805 v / 4 s; Root/Chest/Merged 592 v / 4 s; Root/Chest/ArmR/Merged 584 v / 3 s; Root/Chest/Head/Face 478 v / 1 s; Root/Chest/Head/Merged 361 v / 2 s
- 3 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 3 in fixes.json (top: B8 12 -> 9 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-77345` -> `StandardMaterial3D#-59610` (dE 0.0), `StandardMat)
