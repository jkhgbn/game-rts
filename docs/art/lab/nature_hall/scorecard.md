# Art Lab scorecard: nature_hall

Scene `res://art/buildings/nature_hall.tscn` · kind **building** / tier **hall** · kingdom nature · ground meadow · 2026-10-15 19:20:05 · lab v3.1

## Result: **FAIL** · quality **89 / 100** (88.5) (previous run 89, +0)

1 FAIL · 2 WARN · 18 PASS · 18 info · 0 skipped · 44 s

## Before / after (vs the run of 2026-10-15 18:46:16 in `docs/art/lab/nature_hall`: quality 89 -> 89, +0)
### What got worse (2)
1. **R3 Contrast vs ground (meadow): PASS 82 -> WARN 48 (-34)**. Now: mean-colour dE 14.0, 3% of the body melts (within dE 15 of the ground); body L* 52.2 C 36.1 vs ground L* 57.6 C 48.2, hue gap 6 deg; top third (world height) dE 19.9, L* 69.5; per-. Was: mean-colour dE 14.1, 4% of the body melts (within dE 15 of the ground); body L* 52.1 C 36.0 vs ground L* 57.6 C 48.2, hu
2. **P5 Glow placement: INFO 88 -> INFO 82 (-5)**. Now: 7 of 17 glow(s) in the upper half of the model's height (world). Was: 7 of 16 glow(s) in the upper half of the model's height (world)

### What got better (1)
B8 Unique materials: FAIL 14 -> PASS 88 (+74)

### Score delta per check (5 changed, 36 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | FAIL 14 | PASS 88 | +73.5 |
| R3 | Contrast vs ground (meadow) | PASS 82 | WARN 48 | -33.7 |
| R4 | Contrast on the other grounds | PASS 82 | PASS 82 | +0.7 |
| R5c | Glow points stand out (1 m surround) | PASS 91 | PASS 91 | +0.6 (noisy) |
| P5 | Glow placement | INFO 88 | INFO 82 | -5.1 |

Changed pixels per shot: z40 4.7 %, z55 4.5 %, z25 4.5 %, close 0.9 %, turns 1.4 %, anim 1.2 %, silhouette 0.0 %, lineup 8.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (FAIL): B4 12893 -> 11955 (want <= 12000): `Walls` 3067 -> 2129 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Contrast vs ground (meadow)** (WARN): Body colour: no single recolourable body material found (all team / emissive / tiny): Melts into the meadow: value is close to the ground (dL -5): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 6 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `NaturePainted` 82% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #2] _(from R3 Contrast vs ground (meadow), shot z40)_
3. **Glow points at 40 m** (WARN): Glow points 17 -> 4 (want 2-4): Banner glyph_energy 0.9 -> 0.15 on BannersGate, BannersSide (dim under the bloom level: 13 point(s), peak 4.55 x the level) [fixes.json #3] _(from R5 Glow points at 40 m, shot glow)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 13.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from nature_forge (IoU 0.71): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 37 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 11 material(s), 5 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 12 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 14 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | **FAIL** 13 | 12893 (biggest: Walls 3067, Hedge 2642, GroundDressing 2074, Frame 1805) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 14 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 19 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 23 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1877 of 11974 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.05 ms process, render CPU +0.22 ms, GPU +0.23 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.41 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 47765 px (279 x 337 bbox; 55 m: 23432 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **WARN** 48 | mean-colour dE 14.0, 3% of the body melts (within dE 15 of the ground); body L* 52.2 C 36.1 vs ground L* 57.6 C 48.2, hue gap 6 deg; top third (world height) dE 19.9, L* 69.5; per-pixel dE 40.3, outline 23.0 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: value is close to the ground (dL -5): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 6 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 28.8, 15% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 82 | worst heath: dE 11.4 (heath dE 11.4, old_wood dE 28.8, riverbank dE 22.8, snow dE 50.0, ash dE 46.9, sand dE 33.2, marsh dE 46.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 47% of body pixels change between kingdom colours (min pair 46%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 86 | worst nature colour: dE 14.3 (fire 51.2, shadow 64.4, ice 40.5, nature 14.3) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 11.4 on the team-colour area (normal vision 82.5; 23032 px); deutan: fire / nature dE 11.4; protan: fire / nature dE 25.4; worst vs ground: nature colour (deutan) dE 9.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +2 (point 1 dL +2, point 2 dL +32, point 3 dL +40, point 4 dL +22, point 5 dL +28, point 6 dL +25, point 7 dL +23, point 8 dL +61, point 9 dL +22, point 10 dL +31, point 11 dL +68, point 12 dL +32, point 13 dL +29, point 14 dL +46, point 15 dL +45, point 16 dL +33, point 17 dL +12, soft 1 dL +34 (counts), soft 2 dL +35 (counts), soft 3 dL +41 (counts), soft 4 dL +36 (counts), soft 5 dL +39 (counts), soft 6 dL +40 (counts), soft 7 dL +43 (counts), soft 8 dL +54 (counts), soft 9 dL +53 (counts), soft 10 dL +49 (counts), soft 11 dL +18 (counts), soft 12 dL +46 (counts), soft 13 dL +19 (counts), soft 14 dL +18 (counts), soft 15 dL +11 (counts), soft 16 dL +57 (counts), soft 17 dL +18 (counts), soft 18 dL +59 (counts), soft 19 dL -6, soft 20 dL -13, soft 21 dL +3 (counts), soft 22 dL +2 (counts), soft 23 dL +23 (counts), soft 24 dL +4 (counts), soft 25 dL +21 (counts), soft 26 dL +0, soft 27 dL +11 (counts), soft 28 dL +27 (counts), soft 29 dL +25 (counts); ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 17 point(s) above the bloom level 1.2 (median of 17/11/17): Bloom, BannersGate x6, Lantern, HedgeLost, BannersSide x5, Hedge x2, Walls; soft glows under the bloom (v1 count, luma > 0.4): 35 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Bloom, BannersGate x6, Lantern, HedgeLost, BannersSide x5, Hedge x2, Walls |
| R2 | Distinct from references (black masks) | PASS 82 | max IoU 0.71 (nature_forge 0.71, nature_stables 0.62, market_nature 0.59, magpie_den 0.57, watchtower 0.34, nature_keep 0.27) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 99 | 511 shapes over 4 body parts (127.8 per part: Body 331, Tree 109, LanternPivot 8, (root) 63); 59% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.83 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 107% of the 12000 verts budget used (12889) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 17 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 7.14 at the close-up (83494 px), 8.39 at 25 m; close-up outline complexity 8.81 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.1 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 69.5, bottom third L* 33.4 (+36, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.3 at 25 m, 8.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 82 | 7 of 17 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 17 | on the autumn floor: dE 13.3, 9% melts; body L* 51.3 C 37.1 vs floor L* 59.1 C 40.1; nature team colour vs the floor swatches: min dE 39.4 (grass_light) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Per-mesh vertices (biggest first): Body/Walls 3067 v / 2 s; Body/Hedge 2642 v / 3 s; GroundDressing 2074 v / 3 s; Body/Frame 1805 v / 2 s; Body/Tree/TreeCrown 1474 v / 2 s; Body/Tree/Bloom 584 v / 2 s; Body/PlinthBase 526 v / 2 s; Body/HedgeLost 238 v / 2 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: B4 12893 -> 11955 (want <= 12000): `Walls` 3067 -> 2129 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
