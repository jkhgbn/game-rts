# Art Lab scorecard: shadow_hall

Scene `res://art/buildings/shadow_hall.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-10-15 18:35:23 · lab v3.1

## Result: **PASS** · quality **90 / 100** (90.1) (previous run 90, +0)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 40 s

## Before / after (vs the run of 2026-10-15 16:23:42 in `docs/art/lab/shadow_hall`: quality 90 -> 90, +0)
### What got worse (1)
1. **C3 Palette depth (close-up): INFO 73 -> INFO 53 (-20)**. Now: 9 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %). Was: 11 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %)

### What got better (1)
C2 Vertex use vs budget: INFO 80 -> INFO 100 (+20)

### Score delta per check (6 changed, 37 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C2 | Vertex use vs budget | INFO 80 | INFO 100 | +20.1 |
| C3 | Palette depth (close-up) | INFO 73 | INFO 53 | -20.0 |
| R4 | Contrast on the other grounds | PASS 93 | PASS 92 | -0.5 |
| R6cb | Team colours for colour-blind players | PASS 83 | PASS 85 | +1.1 |
| P1 | Silhouette hook | INFO 0 | INFO 2 | +1.8 |
| P4 | Detail density 25 m / 40 m | INFO 93 | INFO 95 | +1.7 (noisy) |

Changed pixels per shot: z40 7.3 %, z55 6.6 %, z25 7.1 %, close 1.2 %, turns 3.1 %, anim 1.3 %, silhouette 0.1 %, lineup 2.2 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.57): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.32): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
3. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from market_shadow (IoU 0.7): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast on the other grounds** (PASS): On ash the body drops to dE 16.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.8): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 41 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 7 material(s), 8 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 13 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 16 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 6729 (biggest: Roof 3555, Walls 1315, PlinthBase 789, TowerStack 504) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 44 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/hall |  |
| B8 | Unique materials | PASS 98 | 6 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 22 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 718 of 4144 triangles (17%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.07 ms process, render CPU +0.18 ms, GPU +0.09 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.01 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 40623 px (239 x 297 bbox; 55 m: 20676 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 79.7, 0% of the body melts (within dE 15 of the ground); body L* 22.2 C 19.4 vs ground L* 60.7 C 50.4, hue gap n/a (body C* <= 25); top third (world height) dE 85.3, L* 31.2; per-pixel dE 82.4, outline 49.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 26.5, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 92 | worst ash: dE 16.9 (heath dE 53.5, old_wood dE 40.1, riverbank dE 48.6, snow dE 71.5, ash dE 16.9, sand dE 76.0, marsh dE 26.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 32%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 60.0 (fire 70.2, shadow 79.7, ice 67.1, nature 60.0) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 85 | worst pair fire / nature (deutan): dE 16.1 on the team-colour area (normal vision 46.7; 13567 px); deutan: fire / nature dE 16.1; protan: fire / nature dE 23.7; worst vs ground: nature colour (deutan) dE 51.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +31 (point 1 dL +31, point 2 dL +31, point 3 dL +33, point 4 dL +33; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/4/4): TowerStack, TowerBanner, ScorchDecal x2; soft glows under the bloom (v1 count, luma > 0.4): 0 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.7 (market_shadow 0.7, shadow_stables 0.64, dread_paddock 0.63, magpie_den 0.59, watchtower 0.35, dusk_keep 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 265 shapes over 3 body parts (88.3 per part: Body 229, BellTower 29, PikeRack 7); 98% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.571 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 55% of the 12000 verts budget used (6717) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 53 | 9 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.47 at the close-up (89942 px), 8.18 at 25 m; close-up outline complexity 3.32 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 2 | outline complexity 1.32 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 31.2, bottom third L* 12.4 (+18, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 95 | inner detail 2.8 at 25 m, 4.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 65.9, 0% melts; body L* 20.8 C 16.7 vs floor L* 59.5 C 40.3; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.29 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Roof 3555 v / 2 s; Body/Walls 1315 v / 2 s; Body/PlinthBase 789 v / 1 s; Body/BellTower/TowerStack 504 v / 2 s; Body/PikeRack/RackParts 156 v / 1 s; Body/BellTower/TowerTop 150 v / 1 s; Body/SoulOrb 104 v / 1 s; Body/BellTower/TowerBanner 48 v / 1 s
- 9 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
