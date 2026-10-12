# Art Lab scorecard: gloam_rider

Scene `res://art/units/shadow/gloam_rider/gloam_rider.tscn` · kind **unit** / tier **cavalry** · kingdom shadow · ground meadow · 2026-10-12 00:47:26 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **85 / 100** (85.0)

1 FAIL · 3 WARN · 13 PASS · 6 info · 6 skipped · 9 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 20 -> 20 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.76 m, Lance 1.29 m, Pennon 0.75 m, Merged 0.8 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.6 -> 1.23, or pull the widest parts in to x <= 1.05 / z <= 1.05 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
4. **Vertices** (WARN): B4 9979 -> 4788 (want <= 2500): `Merged` 2229 -> 1115 verts; `Merged` 1975 -> 988 verts; `Merged` 985 -> 493 verts; `Lance` 867 -> 434 verts; `Merged` 673 -> 337 verts; `Merged` 402 -> 201 verts; `Merged` 402 -> 201 verts; `Merged` 386 -> 193 verts; `Merged` 386 -> 193 verts; `Merged` 339 -> 170 verts; `Merged` 339 -> 170 verts; `Merged` 307 -> 154 verts; `Merged` 289 -> 145 verts; `Merged` 278 -> 139 verts; `Pennon` 160 -> 80 verts; `ForearmR` 148 -> 74 verts; `Merged` 130 -> 65 verts; `Cloak` 96 -> 48 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 86 | 20 drawn (20 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, Chest 2, ArmL 1, ForearmR 1, Hips 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | **FAIL** 0 | 20 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | **WARN** 35 | 9979 (body + face above its allowance: face 810 v, allowance 1200, total 10789; biggest: Merged 2229, Merged 1975, Merged 985, Lance 867) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | PASS 100 | 0 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 21 (model says 21) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 76 surfaces over 20 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1556 of 13514 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.009 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.76 m, Lance 1.29 m, Pennon 0.75 m, Merged 0.8 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.65 / z 2.15 m (radius 0.6, from gloam_rider.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.94 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 98 | 295 shapes over 15 body parts (19.7 per part: Head 92, LegFL 10, LegFR 10, LegBL 11, LegBR 11, Tail 11, Mount 45, LegL 6, LegR 6, Hips 11, ArmL 6, ArmR 6, ForearmR 22, Lance 26, Chest 22); 23% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.916 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 431% of the 2500 verts budget used (10785) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider, mount separate))
`{"draw":12,"face_verts":1200,"frame_ms":0.005,"lights":0,"meshes":20,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":4,"separate":6,"verts":2500},"src":"cavalry-mounts.md 10 (cavalry rider, mount separate)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 2229 v / 6 s; Steed/Root/Mount/Head/Merged 1975 v / 9 s; Rider/Root/Chest/Merged 985 v / 6 s; Rider/Root/Chest/ArmR/ForearmR/Lance 867 v / 5 s; Rider/Root/Chest/Head/Merged 673 v / 6 s; Steed/Root/Mount/LegBL/Merged 402 v / 4 s; Steed/Root/Mount/LegBR/Merged 402 v / 4 s; Rider/Root/Chest/Head/Face 394 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- Fix recipes: 4 in fixes.json (top: B2 20 -> 20 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
