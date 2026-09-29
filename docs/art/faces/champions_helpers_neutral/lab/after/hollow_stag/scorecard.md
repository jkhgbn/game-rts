# Art Lab scorecard: hollow_stag

Scene `res://art/units/neutral/hollow_stag/hollow_stag.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-28 22:17:42 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **84 / 100** (83.5)

1 FAIL · 4 WARN · 12 PASS · 8 info · 6 skipped · 8 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 13 -> 13 (want <= 10): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Skull 3.02 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.9 -> 0.96, or pull the widest parts in to x <= 1.58 / z <= 2.7 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
4. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #5] _(from B9m Meshes built per instance)_
5. **Vertices** (WARN): B4 4553 -> 2397 (want <= 2500): `Skull` 1739 -> 870 verts; `Merged` 1520 -> 760 verts; `Merged` 262 -> 131 verts; `Shin` 150 -> 75 verts; `Shin` 150 -> 75 verts; `Shin` 150 -> 75 verts; `Shin` 150 -> 75 verts; `Merged` 114 -> 57 verts; `Merged` 114 -> 75 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 29 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: Lower 4, (root) 1, Crown 1, Head 1, LegBL 1, LegBR 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | **FAIL** 5 | 13 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 4553 (biggest: Skull 1739, Merged 1520, Merged 262, Shin 150) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Leaves) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 8 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Skull, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 10 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 13 (model says 12) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 506 of 4754 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Skull 3.02 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.68 / z 1.98 m (radius 0.9, from hollow_stag.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 1.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 280 shapes over 8 body parts (35.0 per part: Crown 187, Head 18, Lower 24, LegFL 4, LegFR 4, LegBL 4, LegBR 4, Mount 35); 15% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.922 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 181% of the 2500 verts budget used (4549) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Head/Crown/Skull 1739 v / 6 s; Root/Mount/Merged 1520 v / 6 s; Root/Mount/Head/Merged 262 v / 3 s; Root/Mount/LegFL/Lower/Shin 150 v / 3 s; Root/Mount/LegFR/Lower/Shin 150 v / 3 s; Root/Mount/LegBL/Lower/Shin 150 v / 3 s; Root/Mount/LegBR/Lower/Shin 150 v / 3 s; Root/Mount/LegFL/Merged 114 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- Fix recipes: 5 in fixes.json (top: B2 13 -> 13 (want <= 10): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
