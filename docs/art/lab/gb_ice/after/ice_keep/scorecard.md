# Art Lab scorecard: ice_keep

Scene `res://art/buildings/ice_keep.tscn` · kind **building** / tier **keep** · kingdom ice · ground meadow · 2026-10-15 12:03:50 · lab v3.1

## Result: **PASS** · quality **87 / 100** (87.4) (previous run 85, +2)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 71 s

## Before / after (vs the run of 2026-10-15 11:57:20 in `docs/art/lab/gb_ice/after/ice_keep`: quality 85 -> 87, +2)
### What got worse (1)
1. **P5 Glow placement: INFO 17 -> INFO 0 (-17)**. Now: 0 of 10 glow(s) in the upper half of the model's height (world). Was: 1 of 12 glow(s) in the upper half of the model's height (world)

### What got better (2)
B6p Looping particles alive: FAIL 10 -> PASS 89 (+79); B8 Unique materials: FAIL 14 -> PASS 88 (+74)

### Score delta per check (5 changed, 36 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B6p | Looping particles alive | FAIL 10 | PASS 89 | +78.7 |
| B8 | Unique materials | FAIL 14 | PASS 88 | +73.5 |
| P4 | Detail density 25 m / 40 m | INFO 93 | INFO 92 | -0.7 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 87 | PASS 89 | +2.3 (noisy) |
| P5 | Glow placement | INFO 17 | INFO 0 | -16.7 |

Changed pixels per shot: z40 0.5 %, z55 0.5 %, z25 0.2 %, close 0.5 %, turns 0.6 %, anim 0.6 %, silhouette 0.0 %, lineup 0.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.55): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Vertex use vs budget** (INFO): Only 17% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
3. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from market_ice (IoU 0.69): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.7): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

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
| B2 | Draw instances at rest | PASS 92 | 28 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | PASS 100 | 7101 (biggest: Icicles 1550, GroundSpikes 1224, Spikes 720, Towers 576) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 89 | 84 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 12 | no budget for building/keep |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9) |  |
| B1a | Authored build parts (before the merge) | INFO | 31 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 25 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 136 of 3712 triangles (3%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.38 ms process, render CPU +0.35 ms, GPU +1.27 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.52 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 53693 px (236 x 435 bbox; 55 m: 25550 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 56.9, 0% of the body melts (within dE 15 of the ground); body L* 71.1 C 13.7 vs ground L* 59.2 C 46.1, hue gap n/a (body C* <= 25); top third (world height) dE 47.8, L* 80.5; per-pixel dE 61.9, outline 32.8 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 25.4, 24% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 25.4 (heath dE 43.5, old_wood dE 53.5, riverbank dE 45.0, snow dE 25.4, ash dE 50.7, sand dE 46.6, marsh dE 60.3) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 52% of body pixels change between kingdom colours (min pair 50%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 27.7 (fire 53.0, shadow 74.1, ice 54.6, nature 27.7) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 8.9 on the team-colour area (normal vision 77.5; 28951 px); deutan: fire / nature dE 8.9; protan: fire / nature dE 24.2; worst vs ground: fire colour (deutan) dE 24.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +9 (point 1 dL +41, point 2 dL +20, point 3 dL +19, point 4 dL +21, point 5 dL +25, point 6 dL +15, point 7 dL +9, point 8 dL +32, point 9 dL +28, point 10 dL +33; ring 28 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 10 point(s) above the bloom level 1.2 (median of 10/8/10): Windows x5, CrownShards x3, GateFrame, CrystalL; soft glows under the bloom (v1 count, luma > 0.4): 52 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (market_ice 0.69, ice_stables 0.66, magpie_den 0.62, ice_hall 0.62, watchtower 0.36, ice_spire 0.16) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 27 shapes over 2 body parts (13.5 per part: Model 26, Tip 1); 73% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.546 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 10 | 17% of the 12000 verts budget used (2113) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.98 at the close-up (63656 px), 3.84 at 25 m; close-up outline complexity 7.07 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.17 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 80.5, bottom third L* 65.0 (+15, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 92 | inner detail 2.7 at 25 m, 3.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 10 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 54.0, 0% melts; body L* 69.8 C 8.8 vs floor L* 47.1 C 40.2; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Per-mesh vertices (biggest first): Model/Icicles 1550 v / 1 s x62; Model/GroundSpikes 1224 v / 1 s x17; Model/Spikes 720 v / 1 s x10; Model/Towers 576 v / 1 s; Model/Halo/HaloShards 432 v / 1 s x6; Model/Windows 408 v / 1 s x17; Model/CrownShards 360 v / 1 s x5; Model/TowerCaps 288 v / 1 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
