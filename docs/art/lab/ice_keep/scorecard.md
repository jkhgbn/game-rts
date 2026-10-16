# Art Lab scorecard: ice_keep

Scene `res://art/buildings/ice_keep.tscn` · kind **building** / tier **keep** · kingdom ice · ground meadow · 2026-10-15 22:15:49 · lab v3.1

## Result: **PASS** · quality **86 / 100** (86.1) (previous run 86, +0)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 58 s

## Before / after (vs the run of 2026-10-15 22:12:41 in `docs/art/lab/ice_keep`: quality 86 -> 86, +0)
### What got worse (1)
1. **P3 Tops light, bottoms dark: INFO 66 -> INFO 60 (-6)**. Now: top third L* 62.1, bottom third L* 57.0 (+5, world height). Was: top third L* 63.3, bottom third L* 57.1 (+6, world height)

### Score delta per check (3 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C4 | Inner detail (close-up / 25 m) | INFO 98 | INFO 99 | +1.1 |
| R6cb | Team colours for colour-blind players | PASS 75 | PASS 77 | +2.0 |
| P3 | Tops light, bottoms dark | INFO 66 | INFO 60 | -6.1 |

Changed pixels per shot: z40 0.2 %, z55 0.1 %, z25 0.1 %, close 0.1 %, turns 0.2 %, anim 0.6 %, silhouette 0.0 %, lineup 0.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.55): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Vertex use vs budget** (INFO): Only 17% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
3. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +5 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from market_ice (IoU 0.69): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.1): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 52 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 9 material(s), 0 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 25 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 95 | 26 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | PASS 100 | 7041 (biggest: Icicles 1550, GroundSpikes 1224, Spikes 720, Towers 576) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 10 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 100 | 24 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 12 | no budget for building/keep |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9) |  |
| B1a | Authored build parts (before the merge) | INFO | 31 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 25 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 136 of 3712 triangles (3%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0054 ms process per instance (8 animated at 40 m: +0.04 ms process, render CPU +0.28 ms, GPU +0.28 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.52 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 51389 px (236 x 434 bbox; 55 m: 24588 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 58.9, 0% of the body melts (within dE 15 of the ground); body L* 58.0 C 14.5 vs ground L* 59.5 C 46.8, hue gap n/a (body C* <= 25); top third (world height) dE 43.6, L* 62.1; per-pixel dE 62.9, outline 35.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 36.9, 7% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 36.9 (heath dE 41.0, old_wood dE 45.1, riverbank dE 40.2, snow dE 36.9, ash dE 38.3, sand dE 52.0, marsh dE 49.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 51% of body pixels change between kingdom colours (min pair 50%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 37.5 (fire 53.4, shadow 69.1, ice 57.9, nature 37.5) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 9.5 on the team-colour area (normal vision 50.1; 27719 px); deutan: fire / nature dE 9.5; protan: shadow / ice dE 16.1; worst vs ground: fire colour (deutan) dE 33.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +2 (point 1 dL +17, point 2 dL +19, point 3 dL +2, point 4 dL +4, point 5 dL +18, point 6 dL +40, point 7 dL +13, point 8 dL +45, point 9 dL +37; ring 28 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 9 point(s) above the bloom level 1.2 (median of 9/9/9): Windows x5, CrownShards x2, Gatehouse, CrystalL; soft glows under the bloom (v1 count, luma > 0.4): 10 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (market_ice 0.69, ice_stables 0.66, magpie_den 0.62, ice_hall 0.61, watchtower 0.36, ice_spire 0.16) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 27 shapes over 2 body parts (13.5 per part: Model 26, Tip 1); 73% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.546 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 10 | 17% of the 12000 verts budget used (2113) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 11 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 99 | inner edges per outline px: 2.47 at the close-up (61588 px), 2.97 at 25 m; close-up outline complexity 7.44 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.47 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 60 | top third L* 62.1, bottom third L* 57.0 (+5, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 76 | inner detail 2.1 at 25 m, 3.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 9 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 44.8, 0% melts; body L* 56.2 C 6.8 vs floor L* 56.4 C 38.1; ice team colour vs the floor swatches: min dE 59.9 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 96 | front-view asymmetry 0.19 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Model/Icicles 1550 v / 1 s x62; Model/GroundSpikes 1224 v / 1 s x17; Model/Spikes 720 v / 1 s x10; Model/Towers 576 v / 1 s; Model/Windows 408 v / 1 s x17; Model/Halo/HaloShards 372 v / 1 s x6; Model/CrownShards 360 v / 1 s x5; Model/TowerCaps 288 v / 1 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
