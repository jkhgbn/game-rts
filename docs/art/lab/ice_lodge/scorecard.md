# Art Lab scorecard: ice_lodge

Scene `res://art/buildings/ice_lodge.tscn` · kind **building** / tier **hall** · kingdom ice · ground meadow · 2026-09-30 14:51:49 · lab v3.1

## Result: **PASS** · quality **90 / 100** (90.2) (previous run 91, -1)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 25 s

## Before / after (vs the run of 2026-09-30 12:50:19 in `docs/art/lab/ice_lodge`: quality 91 -> 90, -1)
### What got worse (1)
1. **R2 Distinct from references (black masks): PASS 100 -> PASS 91 (-9)**. Now: max IoU 0.59 (essence_well 0.59, ice_wall 0.34, ice_spire 0.32, ice_stables 0.32, market_ice 0.31, trade_post 0.31). Was: max IoU 0.34 (ice_wall 0.34, ice_spire 0.32, ice_stables 0.32, market_ice 0.31, trade_post 0.31, essence_well 0.19)

### Score delta per check (1 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R2 | Distinct from references (black masks) | PASS 100 | PASS 91 | -9.1 |

Changed pixels per shot: z40 0.5 %, z55 0.5 %, z25 0.3 %, close 1.0 %, turns 3.9 %, anim 5.9 %, silhouette 13.8 %, lineup 40.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.52): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Vertex use vs budget** (INFO): Only 24% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
3. **Dominant vertical + asymmetric secondary** (IDEA): Push the one dominant vertical 10-15 % taller and make the secondary element clearly one-sided _(from silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 10 material(s), 1 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 8 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 3087 (biggest: Walls 1069, Dome 970, Plinth 697, Rubble 168) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 6 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 16 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 3 | no budget for building/hall |  |
| B8 | Unique materials | PASS 98 | 6 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 10 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 434 of 1876 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.23 ms process, render CPU +0.15 ms, GPU +0.06 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 10966 px (127 x 135 bbox; 55 m: 5671 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 56.6, 0% of the body melts (within dE 15 of the ground); body L* 68.0 C 8.8 vs ground L* 62.3 C 49.9, hue gap n/a (body C* <= 25); top third (world height) dE 57.3, L* 86.7; per-pixel dE 62.5, outline 19.8 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 25.3, 44% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 25.3 (heath dE 37.3, old_wood dE 49.3, riverbank dE 46.3, snow dE 25.3, ash dE 46.0, sand dE 43.2, marsh dE 55.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 29% of body pixels change between kingdom colours (min pair 29%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 40.9 (fire 54.2, shadow 67.2, ice 56.6, nature 40.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 10.1 on the team-colour area (normal vision 77.3; 3387 px); deutan: fire / nature dE 10.1; protan: fire / nature dE 22.2; worst vs ground: fire colour (deutan) dE 34.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +16 (point 1 dL +30, point 2 dL +16, point 3 dL +31, point 4 dL +18, point 5 dL +32; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 5/3/4): ChimneyCrystal, Lantern, Dome x2; soft glows under the bloom (v1 count, luma > 0.4): 13 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 91 | max IoU 0.59 (essence_well 0.59, ice_wall 0.34, ice_spire 0.32, ice_stables 0.32, market_ice 0.31, trade_post 0.31) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 55 shapes over 1 body parts (55.0 per part: Body 55); 33% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.518 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 37 | 24% of the 12000 verts budget used (2915) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.48 at the close-up (70256 px), 4.5 at 25 m; close-up outline complexity 3.53 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 81 | outline complexity 2.35 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 86.7, bottom third L* 59.4 (+27, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.6 at 25 m, 7.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 40 | 1 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 47.5, 0% melts; body L* 65.4 C 3.2 vs floor L* 49.8 C 41.6; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 93 | front-view asymmetry 0.19 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Walls 1069 v / 2 s; Body/Dome 970 v / 1 s; Body/Plinth 697 v / 1 s; Rubble 168 v / 1 s x7; Body/Lantern 69 v / 2 s; Body/ChimneyCrystal 62 v / 1 s; Body/Banner 48 v / 1 s; ContactDecal 4 v / 1 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
