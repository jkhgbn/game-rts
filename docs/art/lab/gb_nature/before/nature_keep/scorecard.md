# Art Lab scorecard: nature_keep

Scene `res://art/buildings/nature_keep.tscn` · kind **building** / tier **keep** · kingdom nature · ground meadow · 2026-10-15 11:06:48 · lab v3.1

## Result: **FAIL** · quality **88 / 100** (88.1)

1 FAIL · 3 WARN · 18 PASS · 17 info · 0 skipped · 88 s

## Improve next
1. **Unique materials** (FAIL): B8 20 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0), `Blossom` -> `Petal` (dE 10.6), `Bark` -> `Wood` (dE 13.8); 8 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 17 -> 12 (want 4-12): Heart energy 1.4 -> 0.26 on Bloom (dim under the bloom level: 5 point(s), peak 3.98 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 22 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.2): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 15.6): value is close to the ground (dL +3): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 17 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 18.1): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

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
| B12 | Downward-facing triangles | INFO | 1813 of 11558 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0002 ms process per instance (8 animated at 40 m: +0.0 ms process, render CPU +0.52 ms, GPU +2.56 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 85758 px (258 x 509 bbox; 55 m: 38801 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 84 | mean-colour dE 15.6, 3% of the body melts (within dE 15 of the ground); body L* 59.1 C 28.8 vs ground L* 55.9 C 40.3, hue gap 17 deg; top third (world height) dE 21.3, L* 72.4; per-pixel dE 38.4, outline 22.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 34.3, 13% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 87 | worst heath: dE 14.0 (heath dE 14.0, old_wood dE 34.3, riverbank dE 22.2, snow dE 38.9, ash dE 44.7, sand dE 21.2, marsh dE 46.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 93 | 18% of body pixels change between kingdom colours (min pair 16%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 89 | worst nature colour: dE 15.8 (fire 27.0, shadow 30.4, ice 23.7, nature 15.8) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 39 | worst pair fire / nature (deutan): dE 11.2 on the team-colour area (normal vision 53.1; 19482 px); deutan: fire / nature dE 11.2; protan: fire / nature dE 21.5; worst vs ground: fire colour (deutan) dE 6.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +0 (point 1 dL +4, point 2 dL +61, point 3 dL +53, point 4 dL +58, point 5 dL +56, point 6 dL +45, point 7 dL +7, point 8 dL +15, point 9 dL +14, point 10 dL +17, point 11 dL +6, point 12 dL +20, point 13 dL +23, point 14 dL +16, point 15 dL +34, point 16 dL +27, point 17 dL +15, soft 1 dL +0 (counts), soft 2 dL +40 (counts), soft 3 dL +55 (counts), soft 4 dL +37 (counts), soft 5 dL +20 (counts), soft 6 dL +42 (counts), soft 7 dL +43 (counts), soft 8 dL +37 (counts), soft 9 dL +41 (counts), soft 10 dL +23 (counts), soft 11 dL +0, soft 12 dL +39 (counts), soft 13 dL +6 (counts), soft 14 dL +60 (counts), soft 15 dL +9 (counts), soft 16 dL +42 (counts), soft 17 dL +22 (counts), soft 18 dL +25 (counts), soft 19 dL +12 (counts), soft 20 dL +45 (counts), soft 21 dL +21 (counts), soft 22 dL +16 (counts), soft 23 dL +11 (counts), soft 24 dL +53 (counts), soft 25 dL +42 (counts), soft 26 dL +8 (counts), soft 27 dL +49 (counts), soft 28 dL +36 (counts), soft 29 dL +14 (counts), soft 30 dL +0 (counts), soft 31 dL +12 (counts), soft 32 dL +3 (counts), soft 33 dL +0, soft 34 dL +12 (counts), soft 35 dL +0, soft 36 dL +25 (counts), soft 37 dL +12 (counts), soft 38 dL +28 (counts), soft 39 dL -2, soft 40 dL +46 (counts), soft 41 dL +22 (counts), soft 42 dL +0, soft 43 dL +23 (counts), soft 44 dL +14 (counts), soft 45 dL +3 (counts), soft 46 dL -13, soft 47 dL +7 (counts); ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 17 point(s) above the bloom level 1.2 (median of 17/18/16): Bloom x5, Pod x5, Rampart x3, BannersSide x2, CanopyLost, BannersGate; soft glows under the bloom (v1 count, luma > 0.4): 57 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Bloom x5, Pod x5, Rampart x3, BannersSide x2, CanopyLost, BannersGate |
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
| C3 | Palette depth (close-up) | INFO 100 | 15 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.13 at the close-up (84198 px), 8.69 at 25 m; close-up outline complexity 10.36 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.68 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 72.4, bottom third L* 38.1 (+34, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.4 at 25 m, 6.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 12 of 17 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 32 | on the autumn floor: dE 18.1, 10% melts; body L* 57.8 C 33.0 vs floor L* 45.7 C 38.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Model/Canopy 2386 v / 4 s; Model/Rampart 2169 v / 6 s; Model/TrunkLow 1345 v / 2 s; Model/TrunkHigh 1299 v / 2 s; Rubble 1237 v / 3 s; Model/Plinth 976 v / 3 s; Model/Bloom 587 v / 3 s; Model/CanopyLost 546 v / 4 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 16 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 over the budget on the first window (1.6182 ms): re-measured 0.0002 ms, kept the lower
- Fix recipes: 4 in fixes.json (top: B8 20 -> 16 materials: use one material for look-alike pairs (albedo dE <= 15): `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0))
