# Art Lab scorecard: ruin_warden

Scene `res://art/units/neutral/ruin_warden.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-28 22:18:06 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **84 / 100** (83.9)

1 FAIL · 3 WARN · 13 PASS · 8 info · 6 skipped · 8 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 12 -> 11 (want <= 10): `GapLight`, `Core` are keep_separate under `Chest`: keep only the animated / toggled one separate [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.57 m, Merged 1.66 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.5 -> 0.56, or pull the widest parts in to x <= 0.88 / z <= 0.88 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
4. **Vertices** (WARN): B4 3430 -> 2453 (want <= 2500): `Merged` 1385 -> 693 verts; `Merged` 816 -> 531 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 47% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.89): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 34 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Chest 3, ArmR 2, (root) 1, ArmL 1, Head 1, Hips 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | **FAIL** 10 | 12 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 3430 (biggest: Merged 1385, Merged 816, Merged 287, Merged 281) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 10 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Motes) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 6 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 69 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 28 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 492 of 2716 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point -0.017 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 85 | head top 2.24 m / body_height 1.8 (x1.25) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.57 m, Merged 1.66 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.98 / z 0.72 m (radius 0.5, from ruin_warden.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 1.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 74 | 67 shapes over 7 body parts (9.6 per part: LegL 5, LegR 5, Hips 4, Head 7, ArmL 5, ArmR 15, Chest 26); 47% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.892 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 137% of the 2500 verts budget used (3426) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 1385 v / 6 s; Root/Chest/ArmR/Merged 816 v / 4 s; Root/Chest/Head/Merged 287 v / 4 s; Root/Chest/ArmL/Merged 281 v / 3 s; Root/Hips/LegL/Merged 179 v / 2 s; Root/Hips/LegR/Merged 179 v / 2 s; Root/Hips/Merged 143 v / 3 s; Root/Chest/GapLight 77 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 7 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 4 in fixes.json (top: B2 12 -> 11 (want <= 10): `GapLight`, `Core` are keep_separate under `Chest`: keep only the animated / toggled one separate)
