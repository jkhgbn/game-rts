# Art Lab scorecard: nature_keep

Scene `res://art/buildings/nature_keep.tscn` · kind **building** / tier **keep** · kingdom nature · ground meadow · 2026-09-30 09:48:28 · lab v3.1

## Result: **FAIL** · quality **88 / 100** (88.2) (previous run 87, +1)

1 FAIL · 3 WARN · 18 PASS · 17 info · 0 skipped · 125 s

## Before / after (vs the run of 2026-09-30 09:45:48 in `docs/art/lab/nature_keep`: quality 87 -> 88, +1)
### What got worse (0)
Nothing got worse.

### What got better (1)
B4 Vertices: FAIL 15 -> PASS 86 (+70)

### Score delta per check (3 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | FAIL 15 | PASS 86 | +70.2 |
| R5c | Glow points stand out (1 m surround) | PASS 89 | PASS 88 | -0.6 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 34 | INFO 35 | +0.6 |

Changed pixels per shot: z40 1.5 %, z55 1.3 %, z25 2.2 %, close 0.3 %, turns 1.0 %, anim 1.2 %, silhouette 0.0 %, lineup 6.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Unique materials** (FAIL): B8 20 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0), `Blossom` -> `Petal` (dE 10.6), `Bark` -> `Wood` (dE 13.8); 8 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 13 -> 6 (want 4-12): Heart energy 1.4 -> 0.26 on Bloom (dim under the bloom level: 7 point(s), peak 4.05 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 22 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.5): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 16.2): value is close to the ground (dL +3): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 17 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 19.2): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

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
| B4 | Vertices | PASS 86 | 11876 (biggest: Canopy 2386, Rampart 2169, TrunkLow 1345, TrunkHigh 1299) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 14 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 100 | 56 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/keep |  |
| B8 | Unique materials | **FAIL** 0 | 20 | <= 8 (art-keep.md 9) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 18 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1811 of 11558 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-8.36 ms process, render CPU +0.95 ms, GPU +0.27 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 85613 px (258 x 510 bbox; 55 m: 38694 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 85 | mean-colour dE 16.2, 3% of the body melts (within dE 15 of the ground); body L* 59.8 C 28.3 vs ground L* 55.9 C 40.3, hue gap 17 deg; top third (world height) dE 22.0, L* 73.0; per-pixel dE 38.0, outline 22.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 35.0, 13% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 88 | worst heath: dE 14.6 (heath dE 14.6, old_wood dE 35.0, riverbank dE 26.6, snow dE 38.0, ash dE 45.2, sand dE 20.6, marsh dE 47.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 92 | 18% of body pixels change between kingdom colours (min pair 16%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 89 | worst nature colour: dE 16.0 (fire 26.9, shadow 30.6, ice 24.0, nature 16.0) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 40 | worst pair fire / nature (deutan): dE 11.5 on the team-colour area (normal vision 53.8; 19228 px); deutan: fire / nature dE 11.5; protan: fire / nature dE 21.7; worst vs ground: fire colour (deutan) dE 7.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +0 (point 1 dL +2, point 2 dL +61, point 3 dL +3, point 4 dL +6, point 5 dL +20, point 6 dL +14, point 7 dL +14, point 8 dL +5, point 9 dL +15, point 10 dL +19, point 11 dL +16, point 12 dL +34, point 13 dL +29, soft 1 dL +53 (counts), soft 2 dL +51 (counts), soft 3 dL +37 (counts), soft 4 dL +44 (counts), soft 5 dL +52 (counts), soft 6 dL +38 (counts), soft 7 dL +19 (counts), soft 8 dL +36 (counts), soft 9 dL +38 (counts), soft 10 dL +32 (counts), soft 11 dL +45 (counts), soft 12 dL +59 (counts), soft 13 dL +0, soft 14 dL +21 (counts), soft 15 dL +6 (counts), soft 16 dL +7 (counts), soft 17 dL +21 (counts), soft 18 dL +23 (counts), soft 19 dL +6 (counts), soft 20 dL +53 (counts), soft 21 dL +2 (counts), soft 22 dL +28 (counts), soft 23 dL +7 (counts), soft 24 dL +33 (counts), soft 25 dL +60 (counts), soft 26 dL -2, soft 27 dL +33 (counts), soft 28 dL +9 (counts), soft 29 dL +31 (counts), soft 30 dL +16 (counts), soft 31 dL -12, soft 32 dL +40 (counts), soft 33 dL +0 (counts), soft 34 dL +20 (counts), soft 35 dL +13 (counts), soft 36 dL +5 (counts), soft 37 dL +24 (counts), soft 38 dL +13 (counts), soft 39 dL +25 (counts), soft 40 dL +29 (counts), soft 41 dL +7 (counts), soft 42 dL +3 (counts), soft 43 dL +14 (counts), soft 44 dL +16 (counts), soft 45 dL +0, soft 46 dL +30 (counts); ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 13 point(s) above the bloom level 1.2 (median of 13/16/13): Petals, Pod x3, Bloom x5, BannersGate, CanopyLost, Rampart x2; soft glows under the bloom (v1 count, luma > 0.4): 54 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Petals, Pod x3, Bloom x5, BannersGate, CanopyLost, Rampart x2 |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.65 (magpie_den 0.65, market_nature 0.57, nature_hall 0.56, watchtower 0.41, nature_hollow 0.32, nature_spire 0.17) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 487 shapes over 5 body parts (97.4 per part: Model 407, Lantern0 8, Lantern1 8, Lantern2 8, (root) 56); 30% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.921 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 98% of the 12000 verts budget used (11872) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 15 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.08 at the close-up (83993 px), 8.68 at 25 m; close-up outline complexity 10.2 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.6 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 73.0, bottom third L* 39.1 (+33, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.3 at 25 m, 6.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 12 of 13 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 35 | on the autumn floor: dE 19.2, 9% melts; body L* 59.1 C 33.1 vs floor L* 45.7 C 38.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- 4 hidden parts at rest (toggled states, not counted as draws)
- 16 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 over the budget on the first window (0.1026 ms): re-measured 0.0 ms, kept the lower
- Fix recipes: 4 in fixes.json (top: B8 20 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0))
