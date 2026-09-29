# Art Lab scorecard: caravan

Scene `res://art/units/caravan/caravan.tscn` · kind **unit** / tier **soldier** · kingdom neutral · ground meadow · 2026-09-28 22:19:11 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **91 / 100** (90.5)

1 FAIL · 1 WARN · 16 PASS · 7 info · 6 skipped · 8 s

## Improve next
1. **Vertices** (FAIL): B4 5547 -> 2779 (want <= 2500): `Merged` 1710 -> 855 verts; `Face` 994 -> 497 verts; `Merged` 902 -> 451 verts; `Merged` 582 -> 291 verts; `Merged` 427 -> 214 verts; `Lantern` 231 -> 116 verts; `Merged` 197 -> 99 verts; `Merged` 111 -> 56 verts; `Merged` 111 -> 56 verts; `Merged` 111 -> 56 verts; `Merged` 111 -> 56 verts; `Pennant` 56 -> 28 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #2] _(from B9m Meshes built per instance)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 45% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.85): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 27 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 13 drawn (13 mesh + 0 multimesh); per pivot: Chest 3, Head 3, (root) 1, Hips 1, LegBL 1, LegBR 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 90 | 13 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 5547 (biggest: Merged 1710, Face 994, Merged 902, Merged 582) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 8 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 14 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 753 of 7004 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point -0.005 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.89 m / body_height 1.9 (x1.0) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.85 / z 1.81 m (radius 0.8, from caravan.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.99 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 61 | 123 shapes over 8 body parts (15.4 per part: Hips 12, Head 41, Chest 45, LegFL 3, LegFR 3, LegBL 3, LegBR 3, Mount 13); 45% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.854 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 221% of the 2500 verts budget used (5543) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 1710 v / 4 s; Root/Chest/Head/Face 994 v / 1 s; Root/Mount/Merged 902 v / 4 s; Root/Hips/Merged 582 v / 2 s; Root/Mount/Head/Merged 427 v / 2 s; Root/Chest/Lantern 231 v / 2 s; Root/Chest/Head/Merged 197 v / 2 s; Root/Mount/LegFL/Merged 111 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 2 in fixes.json (top: B4 5547 -> 2779 (want <= 2500): `Merged` 1710 -> 855 verts; `Face` 994 -> 497 verts; `Merged` 902 -> 451 verts; `Merged` 582 -> 291 verts; `Merged` 427 -> 214 v)
