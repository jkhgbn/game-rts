# Art Lab scorecard: nature_hall

Scene `res://art/buildings/nature_hall.tscn` · kind **building** / tier **hall** · kingdom nature · ground meadow · 2026-09-30 14:46:21 · lab v3.1

## Result: **FAIL** · quality **91 / 100** (91.2) (previous run 91, +0)

1 FAIL · 1 WARN · 19 PASS · 18 info · 0 skipped · 49 s

## Before / after (vs the run of 2026-09-30 12:39:13 in `docs/art/lab/nature_hall`: quality 91 -> 91, +0)
### What got worse (0)
Nothing got worse.

### What got better (1)
P5 Glow placement: INFO 78 -> INFO 88 (+10)

### Score delta per check (2 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R5c | Glow points stand out (1 m surround) | PASS 93 | PASS 91 | -1.6 (noisy) |
| P5 | Glow placement | INFO 78 | INFO 88 | +9.7 |

Changed pixels per shot: z40 3.3 %, z55 3.7 %, z25 3.3 %, close 0.8 %, turns 1.3 %, anim 1.3 %, silhouette 9.2 %, lineup 26.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (FAIL): B4 12893 -> 11955 (want <= 12000): `Walls` 3067 -> 2129 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Glow points at 40 m** (WARN): Glow points 16 -> 2 (want 2-4): Banner glyph_energy 0.9 -> 0.15 on BannersGate, BannersSide (dim under the bloom level: 10 point(s), peak 4.55 x the level); Heart energy 2.5 -> 0.43 on Bloom, Lantern, Hedge (dim under the bloom level: 4 point(s), peak 4.39 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 14.3): value is close to the ground (dL -5): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 6 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
4. **Contrast on the other grounds** (PASS): On heath the body drops to dE 10.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from nature_stables (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Contrast in every team colour (meadow)** (PASS): In the nature team colour the body drops to dE 14.4 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 36 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 11 material(s), 5 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 12 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 15 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | **FAIL** 13 | 12893 (biggest: Walls 3067, Hedge 2642, GroundDressing 2074, Frame 1805) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 28 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 19 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 23 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1877 of 11974 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0001 ms process per instance (8 animated at 40 m: +0.0 ms process, render CPU +0.16 ms, GPU +0.22 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.41 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 47777 px (279 x 337 bbox; 55 m: 23437 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 82 | mean-colour dE 14.3, 4% of the body melts (within dE 15 of the ground); body L* 52.4 C 35.7 vs ground L* 57.6 C 48.2, hue gap 6 deg; top third (world height) dE 20.3, L* 70.1; per-pixel dE 40.3, outline 23.2 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 28.6, 15% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 81 | worst heath: dE 10.9 (heath dE 10.9, old_wood dE 28.6, riverbank dE 22.4, snow dE 49.4, ash dE 46.4, sand dE 32.9, marsh dE 46.7) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 47% of body pixels change between kingdom colours (min pair 47%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 86 | worst nature colour: dE 14.4 (fire 51.1, shadow 64.5, ice 40.5, nature 14.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 11.4 on the team-colour area (normal vision 81.8; 23131 px); deutan: fire / nature dE 11.4; protan: fire / nature dE 25.1; worst vs ground: nature colour (deutan) dE 9.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +1 (point 1 dL +5, point 2 dL +39, point 3 dL +45, point 4 dL +28, point 5 dL +30, point 6 dL +28, point 7 dL +26, point 8 dL +63, point 9 dL +22, point 10 dL +39, point 11 dL +28, point 12 dL +67, point 13 dL +28, point 14 dL +36, point 15 dL +44, point 16 dL +27, soft 1 dL +31 (counts), soft 2 dL +40 (counts), soft 3 dL +45 (counts), soft 4 dL +39 (counts), soft 5 dL +42 (counts), soft 6 dL +49 (counts), soft 7 dL +51 (counts), soft 8 dL +19 (counts), soft 9 dL +61 (counts), soft 10 dL +43 (counts), soft 11 dL +20 (counts), soft 12 dL +16 (counts), soft 13 dL +58 (counts), soft 14 dL +18 (counts), soft 15 dL -6, soft 16 dL +16 (counts), soft 17 dL +19 (counts), soft 18 dL -6, soft 19 dL +21 (counts), soft 20 dL +11 (counts), soft 21 dL +20 (counts), soft 22 dL -16, soft 23 dL +52 (counts), soft 24 dL +5 (counts), soft 25 dL +11 (counts), soft 26 dL +6 (counts), soft 27 dL +25 (counts), soft 28 dL +1 (counts), soft 29 dL +12 (counts); ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 16 point(s) above the bloom level 1.2 (median of 16/18/16): Petals, BannersGate x5, Lantern, HedgeLost, BannersSide x5, Hedge x2, Walls, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 35 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Petals, BannersGate x5, Lantern, HedgeLost, BannersSide x5, Hedge x2, Walls |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.67 (nature_stables 0.67, market_nature 0.64, magpie_den 0.6, watchtower 0.35, nature_keep 0.28, nature_spire 0.21) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

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
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 7.13 at the close-up (83518 px), 8.4 at 25 m; close-up outline complexity 8.77 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.1 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 70.1, bottom third L* 33.5 (+36, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.3 at 25 m, 8.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 88 | 7 of 16 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 51 | on the autumn floor: dE 24.3, 11% melts; body L* 51.0 C 36.3 vs floor L* 46.3 C 40.0; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.27 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- 7 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: B4 12893 -> 11955 (want <= 12000): `Walls` 3067 -> 2129 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
