# Art Lab scorecard: plant_permat_frost_dragon

Scene `res://tools/art_lab/calibration/virtual/plant_permat_frost_dragon.tscn` · kind **titan** / tier **titan** · kingdom ice · ground meadow · 2026-09-27 09:32:02 · lab v2.0

## Result: **FAIL** · quality **87 / 100**

1 FAIL · 0 WARN · 10 PASS · 6 info · 0 skipped · 7 s

## Improve next
1. **Materials built per instance** (FAIL): Share the 43 per-instance material(s) (static cache) so 200 units do not build 200 copies _(from B9 Materials built per instance)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (43 surfaces for 17 meshes = 43 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 40 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **FAIL** 0 | 43 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 17 drawn (17 mesh + 0 multimesh); per pivot: (root) 1, Body 1, Head 1, Jaw 1, LegBL 1, LegBR 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 91 | 18 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B4 | Vertices | PASS 99 | 8580 (biggest: HeadMesh 1418, BodyMesh 1263, WingL2Mesh 771, WingR2Mesh 771) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 2 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (TailFrost) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 10 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 94 | 10 (HeadMesh, Neck2Mesh, Neck1Mesh, WingL2Mesh, WingLMesh, WingR2Mesh) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 45 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 43 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2217 of 13258 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10, titans-2.md 11)
`{"draw":20,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":12,"frame_ms":0.02,"verts":12000},"src":"cavalry-mounts.md 10, titans-2.md 11"}`

## Notes
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1418 v / 4 s; Root/Body/BodyMesh 1263 v / 2 s; Root/Body/WingL/WingL2/WingL2Mesh 771 v / 3 s; Root/Body/WingR/WingR2/WingR2Mesh 771 v / 3 s; Root/Body/WingL/WingLMesh 532 v / 4 s; Root/Body/WingR/WingRMesh 532 v / 4 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 466 v / 4 s; Root/Body/Tail1/Tail2/Tail3/Tail3Mesh 367 v / 2 s
- 45 materials are built in code (fine when cached per type: see B9)
- Art Lab errors (a lab bug, tell the lead): lab_runner.gd:395 Invalid call. Nonexistent function 'check_geometry' in base 'GDScript'.
