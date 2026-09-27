# Art Lab scorecard: market_nature

Scene `res://art/buildings/market/nature/market_nature.tscn` · kind **building** / tier **hall** · kingdom nature · ground meadow · 2026-09-27 10:05:20 · lab v2.0

## Result: **FAIL** · quality **86 / 100**

1 FAIL · 3 WARN · 16 PASS · 11 info · 0 skipped · 59 s

## Improve next
1. **Unique materials** (FAIL): B8 19 -> 10 materials: use one material for look-alike pairs: `StandardMaterial3D#-60158` -> `StandardMaterial3D#-46252` (dE 0.0), `StandardMaterial3D#-46252` -> `StandardMaterial3D#-16893` (dE 0.0), `StandardMaterial3D#-16893` -> `StandardMaterial3D#-5531` (dE 0.0), `Clay` -> `Wood` (dE 9.4), `Wood` -> `Bark` (dE 15.7), `Bark` -> `DarkStone` (dE 17.1), `Stone` -> `DarkStone` (dE 24.8), `Leaves` -> `DarkStone` (dE 71.8), `Blossom` -> `LeafCard` (dE 102.7) [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 9 -> 4 (want 2-4): Gold sweep_energy 1.0 -> 0.17 (dim under the bloom level: 3 point(s), peak 4.39 x the level); Banner glyph_energy 0.9 -> 0.16 (dim under the bloom level: 2 point(s), peak 4.27 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 28 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +14): darken around them or raise the energy [fixes.json #4] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Contrast on the other grounds** (PASS): On riverbank the body drops to dE 12.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 22.6): the top third (what reads from pitch 55) is close to the ground (dE 8.2): lighten helmets / shoulders / back; the body sits in the ground's hue (gap 5 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 28 material(s), 5 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 14 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 16 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 87 | 11457 (biggest: Stall 5445, Mast 1643, GroundDressing 1282, BeamParts 986) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 17 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 19 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 21 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 34 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1613 of 10392 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.5 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 27780 px (200 x 246 bbox; 55 m: 14189 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 22.6, 3% of the body melts (within dE 15 of the ground); body L* 45.9 C 34.5 vs ground L* 61.3 C 50.6, hue gap 5 deg; top third (world height) dE 8.2, L* 66.1; per-pixel dE 39.2, outline 23.2 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 99 | dE 21.9, 14% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 84 | worst riverbank: dE 12.5 (heath dE 15.6, old_wood dE 21.9, riverbank dE 12.5, snow dE 53.1, ash dE 42.2, sand dE 37.7, marsh dE 42.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 46% of body pixels change between kingdom colours (min pair 45%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 22.5 (fire 52.6, shadow 67.4, ice 46.1, nature 22.5) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 14.1 on the team-colour area (normal vision 75.5; 13482 px); deutan: fire / nature dE 14.1; protan: fire / nature dE 25.9; worst vs ground: nature colour (deutan) dE 18.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 60 | worst dL +14 (point 1 dL +65, point 2 dL +49, point 3 dL +35, point 4 dL +69, point 5 dL +29, point 6 dL +32, point 7 dL +23, point 8 dL +18, point 9 dL +14, soft 1 dL +67 (counts), soft 2 dL +52 (counts), soft 3 dL +28 (counts), soft 4 dL +55 (counts), soft 5 dL +40 (counts), soft 6 dL +26 (counts), soft 7 dL +35 (counts), soft 8 dL -3, soft 9 dL +0, soft 10 dL +14, soft 11 dL -6; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 9 point(s) above the bloom level 1.2 (median of 9/9/7): SapMotes, Lantern, BannerA, Roof x2, BannerB, PanParts x2, BeamParts, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 14 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): SapMotes, Lantern, BannerA, Roof x2, BannerB, PanParts x2, BeamParts |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.81 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 66.1, bottom third L* 38.5 (+27, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.9 at 25 m, 9.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 44 | 2 of 9 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Stall 5445 v / 6 s; Body/Tree/Mast 1643 v / 4 s; GroundDressing 1282 v / 3 s; Body/Tree/Beam/BeamParts 986 v / 3 s; Body/Tree/PanGold/PanParts 702 v / 2 s; Body/Canopy/Roof 368 v / 2 s; Body/Tree/PanSeed/PanParts 365 v / 3 s; Body/Canopy/LanternPivot0/Lantern 158 v / 2 s
- 7 hidden parts at rest (toggled states, not counted as draws)
- 19 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B8 19 -> 10 materials: use one material for look-alike pairs: `StandardMaterial3D#-60158` -> `StandardMaterial3D#-46252` (dE 0.0), `StandardMaterial3D#-46252` -)
