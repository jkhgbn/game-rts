# Art Lab scorecard: war_mammoth

Scene `res://art/units/titans/war_mammoth/war_mammoth.tscn` · kind **titan** / tier **titan** · kingdom ice · ground meadow · 2026-09-28 21:34:34 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **96 / 100** (96.4)

0 FAIL · 1 WARN · 12 PASS · 9 info · 6 skipped · 9 s

## Improve next
1. **Vertices** (WARN): B4 12660 -> 11967 (want <= 12000): `Merged` 3436 -> 2743 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (75 surfaces for 17 meshes = 75 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 38 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 17 drawn (17 mesh + 0 multimesh); per pivot: ArmL 3, Head 2, (root) 1, ArmR 1, Chest 1, Howdah 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 91 | 18 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B3 | keep_separate parts | INFO | 2 | no budget for titan/titan |  |
| B4 | Vertices | **WARN** 49 | 12660 (biggest: Merged 3436, Merged 2340, Frame 2290, Merged 600) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 1 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (FrostMist) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 16 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 94 | 10 (Merged, Merged, Merged, Merged, Merged, Frame) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 19 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 17 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 75 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1842 of 14154 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.032 m | -0.08 .. +0.05 m (art-units 1.6) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.88 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 97 | 309 shapes over 13 body parts (23.8 per part: Trunk2 8, Trunk 5, Head 62, LegFL 11, LegFR 11, LegBL 11, LegBR 11, Tail 7, Howdah 80, ArmL 11, ArmR 10, Chest 14, Mount 68); 18% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.914 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 105% of the 12000 verts budget used (12656) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10, titans-2.md 11)
`{"draw":20,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":12,"frame_ms":0.02,"verts":12000},"src":"cavalry-mounts.md 10, titans-2.md 11"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 3436 v / 8 s; Root/Mount/Head/Merged 2340 v / 9 s; Root/Mount/Seat/Howdah/Frame 2290 v / 11 s; Root/Mount/Seat/Howdah/Root/Chest/ArmR/Merged 600 v / 6 s; Root/Mount/Head/Trunk/Trunk2/Merged 597 v / 2 s; Root/Mount/Seat/Howdah/Root/Chest/Merged 548 v / 6 s; Root/Mount/Seat/Howdah/Root/Chest/ArmL/Merged 482 v / 5 s; Root/Mount/LegFR/Merged 430 v / 4 s
- 1 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 1 in fixes.json (top: B4 12660 -> 11967 (want <= 12000): `Merged` 3436 -> 2743 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
