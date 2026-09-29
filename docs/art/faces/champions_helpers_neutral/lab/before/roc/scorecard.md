# Art Lab scorecard: roc

Scene `res://art/units/neutral/beasts/roc/roc.tscn` · kind **beast** / tier **hero** · kingdom neutral · ground meadow · 2026-09-28 21:31:10 · lab v3.1 · **headless: render checks skipped**

## Result: **WARN** · quality **87 / 100** (86.5)

0 FAIL · 3 WARN · 11 PASS · 8 info · 6 skipped · 11 s

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.9 -> 1.53, or pull the widest parts in to x <= 1.58 / z <= 2.7 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #3] _(from B9m Meshes built per instance)_
3. **Shadow casters** (WARN): B7 8 -> 6 casters: cast_shadow off on the 2 smallest: `Neck1Mesh`, `Tail1Mesh` [fixes.json #2] _(from B7 Shadow casters)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.85): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 30 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 13 drawn (13 mesh + 0 multimesh); per pivot: (root) 1, Body 1, Head 1, Jaw 1, LegFL 1, LegFR 1 | <= 26 (map-fill.md 10 (epic beast hero budget)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (map-fill.md 10 (epic beast hero budget)) |  |
| B4 | Vertices | PASS 99 | 5731 (biggest: HeadMesh 1102, BodyMesh 622, WingL2Mesh 597, WingR2Mesh 597) | <= 8000 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (epic beast hero budget)) |  |
| B6 | Particle systems | INFO | 1 | no budget for beast/hero |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B7 | Shadow casters | **WARN** 41 | 8 (HeadMesh, Neck1Mesh, WingL2Mesh, WingLMesh, WingR2Mesh, WingRMesh) | <= 6 soft (map-fill.md 10 (epic beast hero budget)) | cast_shadow only on the 3-4 biggest parts (art-units 1.5 / 8) |
| B8 | Unique materials | INFO | 5 | no budget for beast/hero |  |
| B1a | Authored build parts (before the merge) | INFO | 13 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 17 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2207 of 8620 triangles (25%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | INFO | flyer: lowest point 1.13 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 2.69 / z 1.68 m (radius 0.9, from duskwing_roc.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A2 | death_finished | PASS 100 | after 1.69 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 72 | 97 shapes over 12 body parts (8.1 per part: Jaw 1, Head 23, Neck2 1, Neck1 8, WingL2 17, WingL 3, WingR2 17, WingR 3, Tail1 2, LegFL 9, LegFR 9, Body 4); 6% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.852 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 71% of the 8000 verts budget used (5727) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (epic beast hero budget))
`{"draw":16,"frame_ms":0.01,"lights":0,"meshes":26,"n":12,"runtime_mats":0,"soft":{"casters":6,"looping":2,"verts":8000},"src":"map-fill.md 10 (epic beast hero budget)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1102 v / 3 s; Root/Body/BodyMesh 622 v / 1 s; Root/Body/WingL/WingL2/WingL2Mesh 597 v / 1 s; Root/Body/WingR/WingR2/WingR2Mesh 597 v / 1 s; Root/Body/Tail1/Tail1Mesh 504 v / 1 s; Root/Body/WingL/WingLMesh 499 v / 1 s; Root/Body/WingR/WingRMesh 499 v / 1 s; Root/Body/LegFL/LegFLMesh 386 v / 2 s
- Fix recipes: 3 in fixes.json (top: R10: raise UnitType.radius 0.9 -> 1.53, or pull the widest parts in to x <= 1.58 / z <= 2.7 m)
