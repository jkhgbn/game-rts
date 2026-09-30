# Art Lab scorecard: plant_permat_dusk_steed

Scene `res://tools/art_lab/calibration/virtual/plant_permat_dusk_steed.tscn` · kind **mount** / tier **mount** · kingdom shadow · ground meadow · 2026-09-30 10:13:56 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **90 / 100** (89.6)

1 FAIL · 0 WARN · 12 PASS · 7 info · 6 skipped · 0 s

## Improve next
1. **Materials built per instance** (FAIL): B9 Materials built per instance: Share the 35 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #1] _(from B9 Materials built per instance)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (35 surfaces for 8 meshes = 35 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 21 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **FAIL** 0 | 35 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, Head 1, LegBL 1, LegBR 1, LegFL 1, LegFR 1 | <= 12 (cavalry-mounts.md 10 (mount)) |  |
| B2 | Draw instances at rest | PASS 88 | 8 | <= 8 (cavalry-mounts.md 10 (mount)) |  |
| B4 | Vertices | PASS 88 | 5581 (body + face above its allowance: face 416 v, allowance 600, total 5997; biggest: Merged 2229, Merged 1975, Merged 402, Merged 402) | <= 6000 soft (cavalry-mounts.md 10 (mount)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (mount)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (cavalry-mounts.md 10 (mount)) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 2 soft (cavalry-mounts.md 10 (mount)) |  |
| B8 | Unique materials | INFO | 35 | no budget for mount/mount |  |
| B1a | Authored build parts (before the merge) | INFO | 9 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 12 |  |
| B11 | Surfaces per instance | INFO | 35 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 699 of 7368 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.008 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.4 / z 1.55 m (radius 0.7, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 8 present | set_team_color, set_moving, play_hit, play_death, signal:death_finished, set_barded, play_charge, seat_transform |  |
| A2 | death_finished | PASS 100 | after 0.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 83 | 161 shapes over 7 body parts (23.0 per part: Head 63, LegFL 10, LegFR 10, LegBL 11, LegBR 11, Tail 11, Mount 45); 24% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.88 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 6000 verts budget used (5993) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (mount))
`{"draw":8,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":12,"n":50,"runtime_mats":0,"soft":{"casters":2,"looping":1,"verts":6000},"src":"cavalry-mounts.md 10 (mount)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 2229 v / 6 s; Root/Mount/Head/Merged 1975 v / 9 s; Root/Mount/LegBL/Merged 402 v / 4 s; Root/Mount/LegBR/Merged 402 v / 4 s; Root/Mount/LegFL/Merged 339 v / 4 s; Root/Mount/LegFR/Merged 339 v / 4 s; Root/Mount/Tail/Merged 307 v / 3 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 35 materials are built in code (fine when cached per type: see B9)
- fail_fast=1: stopped after the headless checks (FAIL B9); render checks SKIP
- Fix recipes: 1 in fixes.json (top: B9 Materials built per instance: Share the 35 per-instance material(s) (static cache) so 200 units do not build 200 copies)
