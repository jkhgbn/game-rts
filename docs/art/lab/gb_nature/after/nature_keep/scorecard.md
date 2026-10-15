# Art Lab scorecard: nature_keep

Scene `res://art/buildings/nature_keep.tscn` · kind **building** / tier **keep** · kingdom nature · ground meadow · 2026-10-15 12:07:50 · lab v3.1

## Result: **FAIL** · quality **89 / 100** (88.8) (previous run 85, +4)

1 FAIL · 2 WARN · 19 PASS · 17 info · 0 skipped · 79 s

## Before / after (vs the run of 2026-10-15 12:06:07 in `docs/art/lab/gb_nature/after/nature_keep`: quality 85 -> 89, +4)
### What got worse (0)
Nothing got worse.

### What got better (3)
R3 Contrast vs ground (meadow): WARN 46 -> PASS 84 (+38); R3t Contrast in every team colour (meadow): WARN 50 -> PASS 89 (+39); R6cb Team colours for colour-blind players: PASS 76 -> PASS 79 (+3)

### Score delta per check (4 changed, 36 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R3 | Contrast vs ground (meadow) | WARN 46 | PASS 84 | +38.1 |
| R3t | Contrast in every team colour (meadow) | WARN 50 | PASS 89 | +39.1 |
| R6cb | Team colours for colour-blind players | PASS 76 | PASS 79 | +2.6 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 46 | INFO 47 | +1.7 |

Changed pixels per shot: z40 7.9 %, z55 7.0 %, z25 8.2 %, close 1.1 %, turns 3.9 %, anim 1.5 %, silhouette 0.0 %, lineup 11.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Unique materials** (FAIL): B8 21 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-78303` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0), `Blossom` -> `Petal` (dE 10.6), `Bark` -> `Wood` (dE 13.8); 8 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 17 -> 12 (want 4-12): Heart energy 1.4 -> 0.26 on Bloom (dim under the bloom level: 5 point(s), peak 4.02 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 23 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 16.0): value is close to the ground (dL +2): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from magpie_den (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 46 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 23 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 14 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 100 | 18 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | PASS 86 | 11876 (biggest: Canopy 2386, Rampart 2169, TrunkLow 1345, TrunkHigh 1299) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 15 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 4 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 93 | 76 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/keep |  |
| B8 | Unique materials | **FAIL** 0 | 21 | <= 8 (art-keep.md 9) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 23 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1813 of 11558 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.01 ms process, render CPU +0.67 ms, GPU +1.83 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 85751 px (258 x 509 bbox; 55 m: 38789 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 84 | mean-colour dE 16.0, 5% of the body melts (within dE 15 of the ground); body L* 58.8 C 24.8 vs ground L* 55.9 C 40.3, hue gap n/a (body C* <= 25); top third (world height) dE 21.6, L* 70.3; per-pixel dE 37.8, outline 22.8 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 32.7, 11% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 82 | worst heath: dE 11.4 (heath dE 11.4, old_wood dE 32.7, riverbank dE 19.9, snow dE 36.7, ash dE 43.0, sand dE 24.5, marsh dE 45.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 93 | 19% of body pixels change between kingdom colours (min pair 16%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 89 | worst nature colour: dE 16.0 (fire 25.6, shadow 31.4, ice 25.5, nature 16.0) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.1 on the team-colour area (normal vision 50.1; 20421 px); deutan: fire / nature dE 11.1; protan: fire / nature dE 20.8; worst vs ground: fire colour (deutan) dE 12.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +0 (point 1 dL +4, point 2 dL +60, point 3 dL +52, point 4 dL +55, point 5 dL +54, point 6 dL +44, point 7 dL +13, point 8 dL +18, point 9 dL +19, point 10 dL +29, point 11 dL +11, point 12 dL +27, point 13 dL +24, point 14 dL +6, point 15 dL +19, point 16 dL +33, point 17 dL +31, point 18 dL +18, soft 1 dL +0 (counts), soft 2 dL +49 (counts), soft 3 dL +22 (counts), soft 4 dL +38 (counts), soft 5 dL +26 (counts), soft 6 dL +36 (counts), soft 7 dL +36 (counts), soft 8 dL +32 (counts), soft 9 dL +56 (counts), soft 10 dL +15 (counts), soft 11 dL +17 (counts), soft 12 dL +29 (counts), soft 13 dL +43 (counts), soft 14 dL +6 (counts), soft 15 dL +52 (counts), soft 16 dL +27 (counts), soft 17 dL +29 (counts), soft 18 dL +30 (counts), soft 19 dL +61 (counts), soft 20 dL +20 (counts), soft 21 dL +19 (counts), soft 22 dL +11 (counts), soft 23 dL +8 (counts), soft 24 dL +30 (counts), soft 25 dL +61 (counts), soft 26 dL +30 (counts), soft 27 dL +37 (counts), soft 28 dL +2 (counts), soft 29 dL +12 (counts), soft 30 dL +41 (counts), soft 31 dL +24 (counts), soft 32 dL +1 (counts), soft 33 dL +16 (counts), soft 34 dL +3 (counts), soft 35 dL +14 (counts), soft 36 dL +23 (counts), soft 37 dL +12 (counts), soft 38 dL +35 (counts), soft 39 dL +22 (counts), soft 40 dL -15, soft 41 dL +7 (counts), soft 42 dL +29 (counts), soft 43 dL +27 (counts), soft 44 dL +1 (counts), soft 45 dL +6 (counts), soft 46 dL +14 (counts), soft 47 dL +4 (counts), soft 48 dL +0, soft 49 dL +28 (counts); ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 17 point(s) above the bloom level 1.2 (median of 18/17/16): Bloom x5, Pod x4, Rampart x4, BannersSide x2, CanopyLost, BannersGate; soft glows under the bloom (v1 count, luma > 0.4): 60 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Bloom x5, Pod x4, Rampart x4, BannersSide x2, CanopyLost, BannersGate |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.65 (magpie_den 0.65, nature_stables 0.59, market_nature 0.57, nature_hall 0.56, watchtower 0.41, nature_spire 0.17) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 487 shapes over 5 body parts (97.4 per part: Model 407, Lantern0 8, Lantern1 8, Lantern2 8, (root) 56); 30% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.92 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 98% of the 12000 verts budget used (11872) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.51 at the close-up (84206 px), 8.89 at 25 m; close-up outline complexity 10.36 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.67 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 70.3, bottom third L* 40.6 (+29, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.5 at 25 m, 6.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 13 of 18 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 47 | on the autumn floor: dE 23.2, 9% melts; body L* 57.5 C 28.7 vs floor L* 45.7 C 38.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.31 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Model/Canopy 2386 v / 4 s; Model/Rampart 2169 v / 6 s; Model/TrunkLow 1345 v / 2 s; Model/TrunkHigh 1299 v / 2 s; Rubble 1237 v / 3 s; Model/Plinth 976 v / 3 s; Model/Bloom 587 v / 3 s; Model/CanopyLost 546 v / 4 s
- 9 hidden parts at rest (toggled states, not counted as draws)
- 17 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: B8 21 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-78303` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_)
