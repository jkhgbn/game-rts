# Art Lab scorecard: wildcaller

Scene `res://art/units/champions/wildcaller/wildcaller.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-28 22:15:24 · lab v3.1 · **headless: render checks skipped**

## Result: **FAIL** · quality **86 / 100** (85.5)

1 FAIL · 3 WARN · 15 PASS · 7 info · 6 skipped · 10 s

## Improve next
1. **Unique materials** (FAIL): B8 14 -> 12 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-906` -> `StandardMaterial3D#-36376` (dE 0.0), `StandardMaterial3D#-36376` -> `StandardMaterial3D#-54111` (dE 0.0); 7 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Staff 0.71 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #4] _(from B9m Meshes built per instance)_
4. **Vertices** (WARN): B4 27121 -> 13564 (want <= 3000): `Merged` 9415 -> 4708 verts; `Staff` 8598 -> 4299 verts; `Variant` 4614 -> 2307 verts; `Merged` 1668 -> 834 verts; `Merged` 983 -> 492 verts; `Face` 708 -> 354 verts; `Merged` 287 -> 144 verts; `Merged` 284 -> 142 verts; `Merged` 280 -> 140 verts; `Merged` 280 -> 140 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
5. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.87): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

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
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 27121 (biggest: Merged 9415, Staff 8598, Variant 4614, Merged 1668) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (CrownMotes) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | **FAIL** 0 | 14 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 37 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2903 of 37394 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | SKIP | headless | needs a windowed run (1600 x 900) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R2 | Distinct from references | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R3 | Contrast vs ground | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R5 | Glow points at 40 m | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R6 | Team-colour visibility | SKIP | headless | needs a windowed run (1600 x 900) |  |
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 86 | head top 2.47 m / body_height 2.0 (x1.23) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Staff 0.71 m | narrower than 0.6 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.92 / z 0.7 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A2 | death_finished | PASS 100 | after 0.95 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 79 | 774 shapes over 7 body parts (110.6 per part: LegL 7, LegR 7, Hips 39, Head 180, ArmL 15, ArmR 286, Chest 240); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.87 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 903% of the 3000 verts budget used (27117) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 9415 v / 5 s; Root/Chest/ArmR/Staff 8598 v / 8 s; Root/Chest/Head/Variant 4614 v / 5 s; Root/Hips/Merged 1668 v / 5 s; Root/Chest/ArmL/Merged 983 v / 4 s; Root/Chest/Head/Face 708 v / 1 s; Root/Chest/ArmR/Merged 287 v / 3 s; Root/Chest/Head/Merged 284 v / 1 s
- 4 materials are built in code (fine when cached per type: see B9)
- Fix recipes: 4 in fixes.json (top: B8 14 -> 12 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-906` -> `StandardMaterial3D#-36376` (dE 0.0), `StandardMate)
