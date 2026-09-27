# Art Lab scorecard: nature_keep

Scene `res://art/buildings/nature_keep.tscn` · kind **building** / tier **keep** · kingdom nature · ground meadow · 2026-09-27 10:08:23 · lab v2.0

## Result: **FAIL** · quality **72 / 100**

3 FAIL · 5 WARN · 12 PASS · 11 info · 0 skipped · 99 s

## Improve next
1. **Contrast vs ground (meadow)** (FAIL): shader_parameter/base_color of `Leaves` #59b340 -> #65ff85 (21% of the visible body): predicted dE R3 meadow 4.9 -> 18.3, R3t fire 49.2 -> 26.2, R3t shadow 64.8 -> 34.2, R3t ice 36.5 -> 28.9, R3t nature 4.7 -> 18.0, R4k old_wood 35.9 -> 49.6 (want >= 18); other grounds heath 28.1, riverbank 36.2, snow 53.3, ash 66.0, sand 39.0, marsh 67.1; built in code or embedded: change it where the model script creates it [fixes.json #1] _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Vertices** (FAIL): B4 39613 -> 19810 (want <= 12000): `Canopy` 13416 -> 6708 verts; `TrunkLow` 6318 -> 3159 verts; `TrunkHigh` 5103 -> 2552 verts; `Rampart` 3609 -> 1805 verts; `Rubble` 2736 -> 1368 verts; `CanopyLost` 2499 -> 1250 verts; `Bloom` 2028 -> 1014 verts; `Plinth` 1344 -> 672 verts; `Pod` 552 -> 276 verts; `Pod` 552 -> 276 verts; `Pod` 552 -> 276 verts; `BannersSide` 540 -> 270 verts; `BannersGate` 360 -> 180 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Unique materials** (FAIL): B8 20 -> 9 materials: use one material for look-alike pairs: `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0), `Blossom` -> `Petal` (dE 10.6), `Bark` -> `Wood` (dE 15.7), `Wood` -> `Stone` (dE 19.3), `Moss` -> `DarkStone` (dE 23.9), `Stone` -> `DarkStone` (dE 24.8), `nature_keep` -> `nature_keep` (dE 42.2), `Leaves` -> `DarkStone` (dE 71.8), `Petal` -> `LeafCard` (dE 111.7), `nature_keep` -> `GateVoid` (dE 139.2) [fixes.json #3] _(from B8 Unique materials)_
4. **Contrast in every team colour (meadow)** (WARN): In the nature team colour the body drops to dE 4.7 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
5. **Glow points at 40 m** (WARN): Glow points 37 -> 10 (want 4-12): Banner glyph_energy 0.9 -> 0.15 (dim under the bloom level: 17 point(s), peak 4.39 x the level); ? emission x 0.17 (dim under the bloom level: 4 point(s), peak 4.49 x the level; no energy parameter found: scale its emission colour / strength); Heart energy 2.5 -> 0.43 (dim under the bloom level: 3 point(s), peak 4.39 x the level); ? emission x 0.17 (dim under the bloom level: 3 point(s), peak 4.42 x the level; no energy parameter found: scale its emission colour / strength) [fixes.json #4] _(from R5 Glow points at 40 m, shot glow)_
6. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 22 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #5] _(from B9 Materials built per instance)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 40 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 22 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 14 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 100 | 17 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | **FAIL** 0 | 39613 (biggest: Canopy 13416, TrunkLow 6318, TrunkHigh 5103, Rampart 3609) | <= 12000 (art-keep.md 9) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 92 | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 14 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 100 | 56 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/keep |  |
| B8 | Unique materials | **FAIL** 0 | 20 | <= 8 (art-keep.md 9) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 18 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2107 of 13205 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 87637 px (266 x 503 bbox; 55 m: 39685 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **FAIL** 0 | mean-colour dE 4.9, 3% of the body melts (within dE 15 of the ground); body L* 54.8 C 41.1 vs ground L* 55.7 C 40.1, hue gap 6 deg; top third (world height) dE 25.3, L* 64.3; per-pixel dE 42.1, outline 21.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: value is close to the ground (dL +0): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 6 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 35.9, 11% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 87 | worst heath: dE 13.9 (heath dE 13.9, old_wood dE 35.9, riverbank dE 24.6, snow dE 50.6, ash dE 52.1, sand dE 34.2, marsh dE 52.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 63% of body pixels change between kingdom colours (min pair 62%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 35 | worst nature colour: dE 4.7 (fire 49.2, shadow 64.8, ice 36.5, nature 4.7) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 12.3 on the team-colour area (normal vision 77.1; 61376 px); deutan: fire / nature dE 12.3; protan: fire / nature dE 23.9; worst vs ground: nature colour (protan) dE 1.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | **WARN** 63 | worst dL +4 (point 1 dL +4, point 2 dL +59, point 3 dL +42, point 4 dL +48, point 5 dL +59, point 6 dL +60, point 7 dL +28, point 8 dL +24, point 9 dL +34, point 10 dL +34, point 11 dL +29, point 12 dL +27, point 13 dL +24, point 14 dL +48, point 15 dL +43, point 16 dL +38, point 17 dL +30, point 18 dL +36, point 19 dL +47, point 20 dL +54, point 21 dL +51, point 22 dL +37, point 23 dL +36, point 24 dL +53, point 25 dL +63, point 26 dL +39, point 27 dL +5, point 28 dL +56, point 29 dL +53, point 30 dL +56, point 31 dL +44, point 32 dL +41, soft 1 dL +0, soft 2 dL +49 (counts), soft 3 dL +43 (counts), soft 4 dL +46 (counts), soft 5 dL +33 (counts), soft 6 dL +48 (counts), soft 7 dL +41 (counts), soft 8 dL +13, soft 9 dL +41 (counts), soft 10 dL +36 (counts), soft 11 dL +14, soft 12 dL +49 (counts), soft 13 dL +31 (counts), soft 14 dL +36 (counts), soft 15 dL +58 (counts), soft 16 dL +44 (counts), soft 17 dL +10, soft 18 dL +13, soft 19 dL +38 (counts), soft 20 dL +29 (counts), soft 21 dL +48 (counts), soft 22 dL +8, soft 23 dL +33 (counts), soft 24 dL +7, soft 25 dL +4, soft 26 dL +49 (counts), soft 27 dL +24 (counts), soft 28 dL +12, soft 29 dL +9, soft 30 dL +41 (counts), soft 31 dL +17, soft 32 dL +31 (counts), soft 33 dL +15, soft 34 dL +30 (counts), soft 35 dL +24 (counts), soft 36 dL +22 (counts), soft 37 dL -14, soft 38 dL +11; ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 37 point(s) above the bloom level 1.2 (median of 32/37/44): Bloom x3, Pod x7, Rampart x3, BannersSide x15, BannersGate x5, CanopyLost x4; soft glows under the bloom (v1 count, luma > 0.4): 50 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Bloom x3, Pod x7, Rampart x3, BannersSide x15, BannersGate x5, CanopyLost x4 |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.66 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 64.3, bottom third L* 39.0 (+25, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.6 at 25 m, 6.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 94 | 15 of 32 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Model/Canopy 13416 v / 4 s; Model/TrunkLow 6318 v / 2 s; Model/TrunkHigh 5103 v / 2 s; Model/Rampart 3609 v / 6 s; Rubble 2736 v / 3 s; Model/CanopyLost 2499 v / 4 s; Model/Bloom 2028 v / 3 s; Model/Plinth 1344 v / 3 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 16 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 7 in fixes.json (top: shader_parameter/base_color of `Leaves` #59b340 -> #65ff85 (21% of the visible body): predicted dE R3 meadow 4.9 -> 18.3, R3t fire 49.2 -> 26.2, R3t shadow 64.8)
