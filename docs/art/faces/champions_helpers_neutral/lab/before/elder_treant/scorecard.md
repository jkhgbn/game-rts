# Art Lab scorecard: elder_treant

Scene `res://art/units/titans/elder_treant/elder_treant.tscn` · kind **titan** / tier **titan** · kingdom nature · ground meadow · 2026-09-28 21:34:05 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **94 / 100** (93.8)

0 FAIL · 2 WARN · 12 PASS · 8 info · 6 skipped · 10 s

## Improve next
1. **Vertices** (WARN): B4 12777 -> 11961 (want <= 12000): `HeadMesh` 5409 -> 4593 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #2] _(from B9m Meshes built per instance)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (20 surfaces for 12 meshes = 20 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 36 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, ForeL 1, ForeR 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 100 | 13 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B4 | Vertices | **WARN** 48 | 12777 (biggest: HeadMesh 5409, ChestMesh 1743, HipsMesh 1389, ForeLMesh 943) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 2 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (Petals) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 8 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 90 | 11 (ShinLMesh, LegLMesh, ShinRMesh, LegRMesh, HipsMesh, HeadMesh) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 6 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 3044 of 19570 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point -0.006 m | -0.08 .. +0.05 m (art-units 1.6) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 1.68 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 181 shapes over 11 body parts (16.5 per part: ShinL 6, LegL 3, ShinR 6, LegR 3, Hips 19, Head 81, ForeL 15, ArmL 7, ForeR 15, ArmR 7, Chest 19); 0% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.958 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 106% of the 12000 verts budget used (12773) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10, titans-2.md 11)
`{"draw":20,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":12,"frame_ms":0.02,"verts":12000},"src":"cavalry-mounts.md 10, titans-2.md 11"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/HeadMesh 5409 v / 3 s; Root/Chest/ChestMesh 1743 v / 2 s; Root/Hips/HipsMesh 1389 v / 2 s; Root/Chest/ArmL/ForeL/ForeLMesh 943 v / 2 s; Root/Chest/ArmR/ForeR/ForeRMesh 943 v / 2 s; Root/Chest/ArmL/ArmLMesh 502 v / 2 s; Root/Chest/ArmR/ArmRMesh 502 v / 2 s; Root/Hips/LegL/ShinL/ShinLMesh 413 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 2 in fixes.json (top: B4 12777 -> 11961 (want <= 12000): `HeadMesh` 5409 -> 4593 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
