# Art Lab scorecard: frost_wyrm

Scene `res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn` · kind **beast** / tier **titan** · kingdom ice · ground meadow · 2026-09-28 22:16:17 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **93 / 100** (93.4)

0 FAIL · 1 WARN · 12 PASS · 10 info · 6 skipped · 11 s

## Improve next
1. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #1] _(from B9m Meshes built per instance)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.85): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (25 surfaces for 9 meshes = 25 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, (root) 1, FinL 1, FinR 1, Jaw 1, LegFL 1 | <= 36 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 20 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B3 | keep_separate parts | INFO | 1 | no budget for beast/titan |  |
| B4 | Vertices | PASS 98 | 8778 (biggest: BodyMesh 4340, HeadMesh 1995, JawMesh 545, Face 480) | <= 12000 soft (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B6 | Particle systems | INFO | 1 | no budget for beast/titan |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B7 | Shadow casters | PASS 100 | 2 (HeadMesh, BodyMesh) | <= 8 soft (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B8 | Unique materials | INFO | 9 | no budget for beast/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 9 (model says 8) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1946 of 13864 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | INFO | flyer: lowest point 3.25 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R10 | Footprint vs selection radius | INFO | x 1.67 / z 9.62 m (radius 1.0, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A2 | death_finished | PASS 100 | after 1.83 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 72 | 121 shapes over 7 body parts (17.3 per part: Jaw 14, Head 62, LegFL 8, LegFR 8, FinL 6, FinR 6, Spine 17); 21% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.853 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 73% of the 12000 verts budget used (8774) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, titans-2.md 11 (Frost Wyrm uses the titan budget))
`{"draw":20,"frame_ms":0.02,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":8,"verts":12000},"src":"titans-2.md 11 (Frost Wyrm uses the titan budget)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Spine/BodyMesh 4340 v / 3 s; Root/Body/Neck1/Neck2/Head/HeadMesh 1995 v / 5 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 545 v / 5 s; Root/Body/Neck1/Neck2/Head/Face 480 v / 1 s; Root/Body/LegFL/LegFLMesh 414 v / 3 s; Root/Body/LegFR/LegFRMesh 414 v / 3 s; Root/Body/FinL/FinLMesh 293 v / 2 s; Root/Body/FinR/FinRMesh 293 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 1 in fixes.json (top: B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary)
