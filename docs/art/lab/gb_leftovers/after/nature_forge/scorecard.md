# Art Lab scorecard: nature_forge

Scene `res://art/buildings/forge/nature/nature_forge.tscn` · kind **building** / tier **hall** · kingdom nature · ground meadow · 2026-10-15 14:42:23 · lab v3.1

## Result: **WARN** · quality **91 / 100** (90.7) (previous run 92, -1)

0 FAIL · 1 WARN · 20 PASS · 18 info · 0 skipped · 48 s

## Before / after (vs the run of 2026-10-15 14:37:45 in `docs/art/lab/gb_leftovers/after/nature_forge`: quality 92 -> 91, -1)
### What got worse (2)
1. **P5 Glow placement: INFO 92 -> INFO 57 (-35)**. Now: 4 of 14 glow(s) in the upper half of the model's height (world). Was: 6 of 13 glow(s) in the upper half of the model's height (world)
2. **C1 Shape richness (secondary shapes): INFO 27 -> INFO 25 (-3)**. Now: 185 shapes over 3 body parts (61.7 per part: Body 92, ChimneyTree 30, (root) 63); 53% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.777. Was: 212 shapes over 3 body parts (70.7 per part: Body 118, ChimneyTree 31, (root) 63); 53% of the surface on plain boxes / p

### Score delta per check (5 changed, 37 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 27 | INFO 25 | -2.7 |
| R4 | Contrast on the other grounds | PASS 82 | PASS 83 | +0.9 |
| R5c | Glow points stand out (1 m surround) | PASS 95 | PASS 94 | -1.0 (noisy) |
| P5 | Glow placement | INFO 92 | INFO 57 | -35.2 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 32 | INFO 33 | +0.7 |

Changed pixels per shot: z40 3.2 %, z55 3.5 %, z25 3.3 %, close 0.6 %, turns 1.1 %, anim 1.4 %, silhouette 0.0 %, lineup 10.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 12 -> 2 (want 2-4): NaturePainted sap_energy 1.35 -> 0.23 on Branch, Banners, LeanHedge, PlinthBase (dim under the bloom level: 10 point(s), peak 4.39 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.78): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 20.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from nature_stables (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 33 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 11 material(s), 5 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 9 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 5973 (biggest: GroundDressing 2074, LeanHedge 816, PlinthBase 808, Trunk 722) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 23 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1021 of 4923 triangles (20%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.09 ms process, render CPU +0.23 ms, GPU +1.02 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 30119 px (220 x 225 bbox; 55 m: 15308 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 28.2, 3% of the body melts (within dE 15 of the ground); body L* 43.9 C 29.5 vs ground L* 60.7 C 50.4, hue gap 12 deg; top third (world height) dE 9.1, L* 60.0; per-pixel dE 41.0, outline 25.2 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 93 | dE 18.4, 23% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 83 | worst heath: dE 11.9 (heath dE 11.9, old_wood dE 18.4, riverbank dE 12.4, snow dE 52.9, ash dE 37.1, sand dE 38.3, marsh dE 36.7) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 99 | 24% of body pixels change between kingdom colours (min pair 23%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 28.4 (fire 44.7, shadow 52.7, ice 39.2, nature 28.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 12.3 on the team-colour area (normal vision 81.3; 7448 px); deutan: fire / nature dE 12.3; protan: fire / nature dE 26.1; worst vs ground: nature colour (deutan) dE 21.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +6 (point 1 dL +46, point 2 dL +68, point 3 dL +60, point 4 dL +29, point 5 dL +41, point 6 dL +40, point 7 dL +24, point 8 dL +43, point 9 dL +52, point 10 dL +43, point 11 dL +44, point 12 dL +45, point 13 dL +51, point 14 dL +48, soft 1 dL +50 (counts), soft 2 dL +30 (counts), soft 3 dL +41 (counts), soft 4 dL +14 (counts), soft 5 dL +68 (counts), soft 6 dL +41 (counts), soft 7 dL +50 (counts), soft 8 dL +13 (counts), soft 9 dL +21 (counts), soft 10 dL +28 (counts), soft 11 dL +62 (counts), soft 12 dL +57 (counts), soft 13 dL +9 (counts), soft 14 dL +44 (counts), soft 15 dL +6 (counts), soft 16 dL +17 (counts), soft 17 dL +32 (counts), soft 18 dL +36 (counts), soft 19 dL +14 (counts), soft 20 dL +29 (counts), soft 21 dL +13 (counts); ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 12 point(s) above the bloom level 1.2 (median of 14/12/8): Branch x4, Kiln x2, LeanHedge x4, Banners, Trunk; soft glows under the bloom (v1 count, luma > 0.4): 25 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Branch x4, Kiln x2, LeanHedge x4, Banners, Trunk |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.65 (nature_stables 0.65, market_nature 0.63, magpie_den 0.58, tavern_model 0.5, nature_hollow 0.47, nature_spire 0.21) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 25 | 185 shapes over 3 body parts (61.7 per part: Body 92, ChimneyTree 30, (root) 63); 53% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.777 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 49% of the 12000 verts budget used (5969) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.68 at the close-up (57299 px), 6.63 at 25 m; close-up outline complexity 12.17 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.72 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 60.0, bottom third L* 35.7 (+24, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.4 at 25 m, 8.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 57 | 4 of 14 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 33 | on the autumn floor: dE 20.3, 15% melts; body L* 40.9 C 29.8 vs floor L* 48.1 C 40.8 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.24 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): GroundDressing 2074 v / 3 s; Body/LeanHedge 816 v / 2 s; Body/PlinthBase 808 v / 2 s; Body/ChimneyTree/Trunk 722 v / 2 s; Body/Workshop 558 v / 2 s; Body/Kiln 476 v / 3 s; Body/ChimneyTree/Branch 258 v / 2 s; Body/Banners 257 v / 3 s
- 7 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: Glow points 12 -> 2 (want 2-4): NaturePainted sap_energy 1.35 -> 0.23 on Branch, Banners, LeanHedge, PlinthBase (dim under the bloom level: 10 point(s), peak 4.)
