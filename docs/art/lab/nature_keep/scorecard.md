# Art Lab scorecard: nature_keep

Scene `res://art/buildings/nature_keep.tscn` · kind **building** / tier **keep** · kingdom nature · ground meadow · 2026-10-15 19:19:08 · lab v3.1

## Result: **FAIL** · quality **89 / 100** (88.5) (previous run 91, -2)

1 FAIL · 2 WARN · 19 PASS · 17 info · 0 skipped · 56 s

## Before / after (vs the run of 2026-10-15 18:45:10 in `docs/art/lab/nature_keep`: quality 91 -> 89, -2)
### What got worse (1)
1. **R5 Glow points at 40 m: PASS 100 -> WARN 49 (-51) (noisy check: re-run before acting)**. Now: 13 point(s) above the bloom level 1.2 (median of 16/13/13): Bloom x5, Pod x4, BannersGate, CanopyLost, Rampart x2; soft glows under the bloom (v1 count, luma > 0.4): 50. Was: 12 point(s) above the bloom level 1.2 (median of 11/12/13): Petals, Bloom x5, CanopyLost, Pod x3, Rampart x2; soft glows

### Score delta per check (2 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R5 | Glow points at 40 m | PASS 100 | WARN 49 | -51.4 (noisy) |
| B13 | Frame cost | PASS 91 | PASS 100 | +8.6 (noisy) |

Changed pixels per shot: z40 2.9 %, z55 2.6 %, z25 2.6 %, close 0.6 %, turns 0.6 %, anim 1.1 %, silhouette 0.0 %, lineup 0.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Unique materials** (FAIL): B8 20 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0), `Blossom` -> `Petal` (dE 10.6), `Bark` -> `Wood` (dE 13.8); 8 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 13 -> 7 (want 4-12): Heart energy 1.4 -> 0.26 on Bloom (dim under the bloom level: 6 point(s), peak 4.05 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 22 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 10.6): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 16.3): value is close to the ground (dL +2): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.8: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 45 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 22 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 14 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 100 | 16 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | PASS 86 | 11876 (biggest: Canopy 2386, Rampart 2169, TrunkLow 1345, TrunkHigh 1299) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 13 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 100 | 26 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/keep |  |
| B8 | Unique materials | **FAIL** 0 | 20 | <= 8 (art-keep.md 9) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 23 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1811 of 11558 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-2.15 ms process, render CPU +0.37 ms, GPU +0.44 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 85735 px (258 x 509 bbox; 55 m: 38800 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 85 | mean-colour dE 16.3, 3% of the body melts (within dE 15 of the ground); body L* 58.7 C 24.4 vs ground L* 55.9 C 40.1, hue gap n/a (body C* <= 25); top third (world height) dE 22.4, L* 71.5; per-pixel dE 38.5, outline 22.3 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 32.5, 11% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 83 | worst heath: dE 11.8 (heath dE 11.8, old_wood dE 32.5, riverbank dE 17.9, snow dE 36.5, ash dE 42.4, sand dE 24.4, marsh dE 45.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 92 | 18% of body pixels change between kingdom colours (min pair 15%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 90 | worst nature colour: dE 16.4 (fire 25.8, shadow 31.6, ice 25.6, nature 16.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.3 on the team-colour area (normal vision 54.9; 18874 px); deutan: fire / nature dE 11.3; protan: fire / nature dE 22.0; worst vs ground: fire colour (deutan) dE 12.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +0 (point 1 dL +2, point 2 dL +58, point 3 dL +52, point 4 dL +57, point 5 dL +45, point 6 dL +8, point 7 dL +15, point 8 dL +16, point 9 dL +24, point 10 dL +22, point 11 dL +5, point 12 dL +25, point 13 dL +17, point 14 dL +17, point 15 dL +34, point 16 dL +29, soft 1 dL +0 (counts), soft 2 dL +50 (counts), soft 3 dL +43 (counts), soft 4 dL +39 (counts), soft 5 dL +23 (counts), soft 6 dL +37 (counts), soft 7 dL +24 (counts), soft 8 dL +60 (counts), soft 9 dL +0, soft 10 dL +10 (counts), soft 11 dL +37 (counts), soft 12 dL +47 (counts), soft 13 dL +20 (counts), soft 14 dL +9 (counts), soft 15 dL +17 (counts), soft 16 dL +16 (counts), soft 17 dL +36 (counts), soft 18 dL +53 (counts), soft 19 dL +18 (counts), soft 20 dL +15 (counts), soft 21 dL +9 (counts), soft 22 dL +20 (counts), soft 23 dL +41 (counts), soft 24 dL +15 (counts), soft 25 dL +0 (counts), soft 26 dL +12 (counts), soft 27 dL +48 (counts), soft 28 dL +5 (counts), soft 29 dL +19 (counts), soft 30 dL +12 (counts), soft 31 dL +26 (counts), soft 32 dL -12, soft 33 dL +7 (counts), soft 34 dL +32 (counts), soft 35 dL +24 (counts), soft 36 dL +29 (counts), soft 37 dL +0, soft 38 dL +13 (counts), soft 39 dL +3 (counts), soft 40 dL +4 (counts); ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 13 point(s) above the bloom level 1.2 (median of 16/13/13): Bloom x5, Pod x4, BannersGate, CanopyLost, Rampart x2; soft glows under the bloom (v1 count, luma > 0.4): 50 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Bloom x5, Pod x4, BannersGate, CanopyLost, Rampart x2 |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.65 (magpie_den 0.65, nature_forge 0.6, nature_stables 0.59, market_nature 0.57, nature_hall 0.56, watchtower 0.41) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 487 shapes over 5 body parts (97.4 per part: Model 407, Lantern0 8, Lantern1 8, Lantern2 8, (root) 56); 30% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.92 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 98% of the 12000 verts budget used (11872) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.1 at the close-up (84198 px), 8.86 at 25 m; close-up outline complexity 10.27 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.69 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 71.5, bottom third L* 38.6 (+32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.4 at 25 m, 6.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 12 of 16 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 8 | on the autumn floor: dE 10.6, 9% melts; body L* 57.7 C 28.1 vs floor L* 52.2 C 34.9; nature team colour vs the floor swatches: min dE 39.4 (grass_light) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- 10 hidden parts at rest (toggled states, not counted as draws)
- 16 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 over the budget on the first window (0.0629 ms): re-measured 0.0 ms, kept the lower
- Fix recipes: 3 in fixes.json (top: B8 20 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0))
