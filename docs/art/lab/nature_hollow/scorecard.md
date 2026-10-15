# Art Lab scorecard: nature_hollow

Scene `res://art/buildings/nature_hollow.tscn` · kind **building** / tier **hall** · kingdom nature · ground meadow · 2026-10-15 19:20:50 · lab v3.1

## Result: **WARN** · quality **91 / 100** (90.7) (previous run 91, +0)

0 FAIL · 3 WARN · 18 PASS · 18 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-10-15 18:47:07 in `docs/art/lab/nature_hollow`: quality 91 -> 91, +0)
### What got worse (1)
1. **R5 Glow points at 40 m: PASS 100 -> WARN 49 (-51) (noisy check: re-run before acting)**. Now: 5 point(s) above the bloom level 1.2 (median of 3/5/5): Lantern x2, Banner, Plinth x2; soft glows under the bloom (v1 count, luma > 0.4): 13. Was: 2 point(s) above the bloom level 1.2 (median of 2/2/4): Lantern, Plinth, 1 rim-light speck(s) ignored; soft glows under 

### What got better (1)
B8 Unique materials: FAIL 14 -> PASS 88 (+74)

### Score delta per check (3 changed, 37 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | FAIL 14 | PASS 88 | +73.5 |
| R5c | Glow points stand out (1 m surround) | PASS 94 | PASS 93 | -1.0 (noisy) |
| R5 | Glow points at 40 m | PASS 100 | WARN 49 | -51.4 (noisy) |

Changed pixels per shot: z40 3.4 %, z55 2.5 %, z25 3.7 %, close 1.2 %, turns 0.6 %, anim 0.7 %, silhouette 0.0 %, lineup 6.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast vs ground (meadow)** (WARN): Body colour: no single recolourable body material found (all team / emissive / tiny): Melts into the meadow: the body sits in the ground's hue (gap 1 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `NaturePainted` 73% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Glow points at 40 m** (WARN): Glow points 5 -> 3 (want 2-4): Heart energy 2.5 -> 0.57 on Lantern (dim under the bloom level: 2 point(s), peak 3.26 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Contrast in every team colour (meadow)** (WARN): In the nature team colour the body drops to dE 13.6 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 16.1): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Contrast on the other grounds** (PASS): On riverbank the body drops to dE 18.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 13 material(s), 1 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 8 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 5551 (biggest: Walls 2027, GroundDressing 1587, LeafRoof 1162, Banner 280) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 7 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 5 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 968 of 5326 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.22 ms process, render CPU +0.14 ms, GPU +0.09 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.33 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 12831 px (155 x 170 bbox; 55 m: 6573 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **WARN** 47 | mean-colour dE 13.2, 5% of the body melts (within dE 15 of the ground); body L* 51.5 C 42.3 vs ground L* 62.1 C 50.2, hue gap 1 deg; top third (world height) dE 10.7, L* 67.6; per-pixel dE 33.8, outline 21.2 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: the body sits in the ground's hue (gap 1 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 30.2, 14% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 95 | worst riverbank: dE 18.5 (heath dE 19.7, old_wood dE 30.2, riverbank dE 18.5, snow dE 53.3, ash dE 50.8, sand dE 36.1, marsh dE 50.2) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 50% of body pixels change between kingdom colours (min pair 50%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 52 | worst nature colour: dE 13.6 (fire 54.5, shadow 68.4, ice 40.1, nature 13.6) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 12.3 on the team-colour area (normal vision 90.7; 6536 px); deutan: fire / nature dE 12.3; protan: fire / nature dE 26.9; worst vs ground: nature colour (deutan) dE 11.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +3 (point 1 dL +26, point 2 dL +25, point 3 dL +3, soft 1 dL +25 (counts), soft 2 dL +18 (counts), soft 3 dL +25 (counts), soft 4 dL +39 (counts), soft 5 dL +54 (counts), soft 6 dL +49 (counts), soft 7 dL +45 (counts), soft 8 dL +41 (counts), soft 9 dL +23 (counts), soft 10 dL +42 (counts), soft 11 dL +34 (counts), soft 12 dL -4, soft 13 dL -12; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) above the bloom level 1.2 (median of 3/5/5): Lantern x2, Banner, Plinth x2; soft glows under the bloom (v1 count, luma > 0.4): 13 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Lantern x2, Banner, Plinth x2 |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.38 (greywater_lodge 0.38, nature_spire 0.33, nature_forge 0.32, nature_stables 0.31, trade_post 0.3, market_nature 0.3) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 167 shapes over 3 body parts (55.7 per part: Body 114, LanternPivot 8, (root) 45); 28% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.937 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 46% of the 12000 verts budget used (5547) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 18 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.15 at the close-up (62717 px), 3.49 at 25 m; close-up outline complexity 9.28 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.89 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 67.6, bottom third L* 40.9 (+26, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.9 at 25 m, 7.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 25 | on the autumn floor: dE 16.1, 6% melts; body L* 49.5 C 41.4 vs floor L* 59.7 C 40.1; nature team colour vs the floor swatches: min dE 39.4 (grass_light) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.39 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Walls 2027 v / 2 s; GroundDressing 1587 v / 3 s; Body/LeafRoof 1162 v / 2 s; Body/Banner 280 v / 3 s; Body/LeafRoofLost 208 v / 2 s; Body/LanternPivot/Lantern 158 v / 2 s; Body/Plinth 125 v / 1 s; ContactDecal 4 v / 1 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: Body colour: no single recolourable body material found (all team / emissive / tiny): Melts into the meadow: the body sits in the ground's hue (gap 1 deg): push)
