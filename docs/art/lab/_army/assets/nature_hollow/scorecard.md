# Art Lab scorecard: nature_hollow

Scene `res://art/buildings/nature_hollow.tscn` · kind **building** / tier **hall** · kingdom nature · ground meadow · 2026-09-27 10:07:50 · lab v2.0

## Result: **FAIL** · quality **86 / 100**

1 FAIL · 3 WARN · 16 PASS · 11 info · 0 skipped · 31 s

## Improve next
1. **Unique materials** (FAIL): B8 18 -> 9 materials: use one material for look-alike pairs: `StandardMaterial3D#-73353` -> `StandardMaterial3D#-16893` (dE 0.0), `StandardMaterial3D#-16893` -> `StandardMaterial3D#-79643` (dE 0.0), `Wood` -> `Bark` (dE 15.7), `Bark` -> `DarkStone` (dE 17.1), `Moss` -> `DarkStone` (dE 23.9), `Stone` -> `DarkStone` (dE 24.8), `Leaves` -> `DarkStone` (dE 71.8), `StandardMaterial3D#-79643` -> `Void` (dE 97.0), `Blossom` -> `LeafCard` (dE 102.7) [fixes.json #1] _(from B8 Unique materials)_
2. **Contrast vs ground (meadow)** (WARN): shader_parameter/base_color of `LeafCard` #59b340 -> #4a952b (24% of the visible body): predicted dE R3 meadow 13.7 -> 18.6, R3t fire 53.8 -> 63.1, R3t shadow 68.3 -> 84.6, R3t ice 40.0 -> 45.5, R3t nature 13.2 -> 18.1, R4k old_wood 29.7 -> 24.9 (want >= 18); other grounds heath 16.1, riverbank 16.0, snow 52.8, ash 45.6, sand 36.5, marsh 44.8; built in code or embedded: change it where the model script creates it [fixes.json #2] _(from R3 Contrast vs ground (meadow), shot z40)_
3. **Contrast in every team colour (meadow)** (WARN): In the nature team colour the body drops to dE 13.2 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
4. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 21 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
5. **Contrast on the other grounds** (PASS): On riverbank the body drops to dE 18.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 21 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 8 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 5551 (biggest: Walls 2027, GroundDressing 1587, LeafRoof 1162, Banner 280) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 6 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 13 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 18 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 22 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 968 of 5326 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.33 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 12860 px (155 x 170 bbox; 55 m: 6590 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **WARN** 48 | mean-colour dE 13.7, 5% of the body melts (within dE 15 of the ground); body L* 51.6 C 41.6 vs ground L* 62.1 C 50.2, hue gap 2 deg; top third (world height) dE 9.8, L* 67.9; per-pixel dE 34.0, outline 20.9 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: the body sits in the ground's hue (gap 2 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 29.7, 14% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 95 | worst riverbank: dE 18.2 (heath dE 18.7, old_wood dE 29.7, riverbank dE 18.2, snow dE 52.7, ash dE 50.5, sand dE 35.8, marsh dE 50.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 54% of body pixels change between kingdom colours (min pair 52%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 51 | worst nature colour: dE 13.2 (fire 53.8, shadow 68.3, ice 40.0, nature 13.2) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 15.2 on the team-colour area (normal vision 82.5; 7320 px); deutan: fire / nature dE 15.2; protan: fire / nature dE 26.9; worst vs ground: nature colour (deutan) dE 11.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +25 (point 1 dL +32, point 2 dL +30, point 3 dL +36, soft 1 dL +29 (counts), soft 2 dL +31 (counts), soft 3 dL +36 (counts), soft 4 dL +25 (counts), soft 5 dL +57 (counts), soft 6 dL +52 (counts), soft 7 dL +34 (counts), soft 8 dL +38 (counts), soft 9 dL +15, soft 10 dL +14, soft 11 dL +34 (counts), soft 12 dL +25 (counts), soft 13 dL -3, soft 14 dL +36 (counts), soft 15 dL -12; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 3/6/4): Lantern x2, Plinth, Banner; soft glows under the bloom (v1 count, luma > 0.4): 15 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.72 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 67.9, bottom third L* 41.0 (+26, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.9 at 25 m, 8.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Walls 2027 v / 5 s; GroundDressing 1587 v / 4 s; Body/LeafRoof 1162 v / 4 s; Body/Banner 280 v / 3 s; Body/LeafRoofLost 208 v / 2 s; Body/LanternPivot/Lantern 158 v / 2 s; Body/Plinth 125 v / 1 s; ContactDecal 4 v / 1 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- 18 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B8 18 -> 9 materials: use one material for look-alike pairs: `StandardMaterial3D#-73353` -> `StandardMaterial3D#-16893` (dE 0.0), `StandardMaterial3D#-16893` ->)
