# Art Lab scorecard: dusk_keep

Scene `res://art/buildings/dusk_keep.tscn` · kind **building** / tier **keep** · kingdom shadow · ground meadow · 2026-09-30 14:55:28 · lab v3.1

## Result: **WARN** · quality **89 / 100** (88.9) (previous run 89, +0)

0 FAIL · 2 WARN · 19 PASS · 18 info · 0 skipped · 61 s

## Before / after (vs the run of 2026-09-30 14:49:07 in `docs/art/lab/dusk_keep`: quality 89 -> 89, +0)
### What got worse (3)
1. **R6 Team-colour visibility at 40 m: PASS 97 -> PASS 94 (-3)**. Now: 19% of body pixels change between kingdom colours (min pair 14%). Was: 22% of body pixels change between kingdom colours (min pair 16%)
2. **P5 Glow placement: INFO 86 -> INFO 81 (-5)**. Now: 19 of 47 glow(s) in the upper half of the model's height (world). Was: 18 of 42 glow(s) in the upper half of the model's height (world)
3. **P3 Tops light, bottoms dark: INFO 86 -> INFO 83 (-3)**. Now: top third L* 33.5, bottom third L* 24.4 (+9, world height). Was: top third L* 34.3, bottom third L* 24.6 (+9, world height)

### What got better (1)
C3 Palette depth (close-up): INFO 83 -> INFO 100 (+17)

### Score delta per check (5 changed, 35 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 83 | INFO 100 | +16.7 |
| R6 | Team-colour visibility at 40 m | PASS 97 | PASS 94 | -2.8 |
| P3 | Tops light, bottoms dark | INFO 86 | INFO 83 | -2.8 |
| P5 | Glow placement | INFO 86 | INFO 81 | -4.9 |
| B13 | Frame cost | PASS 100 | PASS 99 | -1.5 (noisy) |

Changed pixels per shot: z40 17.1 %, z55 13.3 %, z25 21.1 %, close 1.2 %, turns 0.9 %, anim 0.7 %, silhouette 0.0 %, lineup 0.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 47 -> 10 (want 4-12): DarkStone crack_strength 1.0 -> 0.11 on GateFrame, LanternStems, Body, Prism1 (dim under the bloom level: 19 point(s), peak 6.81 x the level); Glow boost_mult 1.0 -> 0.11 on ShardCore, LanternOrb2, Windows, LanternOrb1 (dim under the bloom level: 18 point(s), peak 6.9 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 5.1): add a value step inside the team-colour area [fixes.json #2] _(from R6cb Team colours for colour-blind players, shot teams)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.59): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from market_shadow (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +9 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 19% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 49 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 7 material(s), 2 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 29 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 86 | 32 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | PASS 100 | 6173 (biggest: Carving 2058, Fins 576, RuneRing 343, Rubble 336) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (SpireLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 89 | 84 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 11 | no budget for building/keep |  |
| B8 | Unique materials | PASS 93 | 7 | <= 8 (art-keep.md 9) |  |
| B1a | Authored build parts (before the merge) | INFO | 35 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 29 surfaces over 29 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 600 of 4108 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 99 | 0.0227 ms process per instance (8 animated at 40 m: +0.18 ms process, render CPU +0.3 ms, GPU +0.27 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 62029 px (291 x 549 bbox; 55 m: 28433 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 97.5, 0% of the body melts (within dE 15 of the ground); body L* 31.1 C 50.8 vs ground L* 57.4 C 43.7, hue gap 166 deg; top third (world height) dE 69.9, L* 33.5; per-pixel dE 101.4, outline 64.8 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 56.4, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 48.0 (heath dE 80.2, old_wood dE 69.6, riverbank dE 74.6, snow dE 77.7, ash dE 48.0, sand dE 90.3, marsh dE 56.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 94 | 19% of body pixels change between kingdom colours (min pair 14%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 86.7 (fire 88.5, shadow 97.1, ice 88.2, nature 86.7) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 38 | worst pair fire / nature (deutan): dE 5.1 on the team-colour area (normal vision 14.5; 18004 px); deutan: fire / nature dE 5.1; protan: fire / nature dE 6.3; worst vs ground: fire colour (deutan) dE 70.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +8 (point 1 dL +21, point 2 dL +32, point 3 dL +43, point 4 dL +43, point 5 dL +34, point 6 dL +34, point 7 dL +37, point 8 dL +59, point 9 dL +62, point 10 dL +33, point 11 dL +53, point 12 dL +25, point 13 dL +30, point 14 dL +24, point 15 dL +36, point 16 dL +37, point 17 dL +56, point 18 dL +20, point 19 dL +24, point 20 dL +61, point 21 dL +44, point 22 dL +44, point 23 dL +29, point 24 dL +25, point 25 dL +11, point 26 dL +19, point 27 dL +53, point 28 dL +28, point 29 dL +52, point 30 dL +8, point 31 dL +55, point 32 dL +31, point 33 dL +27, point 34 dL +18, point 35 dL +71, point 36 dL +18, point 37 dL +16, point 38 dL +70, point 39 dL +83, point 40 dL +22, point 41 dL +51, point 42 dL +30, point 43 dL +34, point 44 dL +29, point 45 dL +40, point 46 dL +11, point 47 dL +10; ring 30 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 47 point(s) above the bloom level 1.2 (median of 47/44/49): ShardCore, LanternOrb2, GateFrame x2, Windows x6, LanternStems x7, Banner2, Prism3 x3, LanternOrb1 x2, LanternOrb3, RuneRing x4, Thorns, FinTips x2, Prism1 x2, Tip x2, Banner1 x2, GateSlits x3, WatchNeedle x3, ShardMesh, Plinth, Prism2, Banner3, 4 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 48 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): ShardCore, LanternOrb2, GateFrame x2, Windows x6, LanternStems x7, Banner2, Prism3 x3, LanternOrb1 x2, LanternOrb3, RuneRing x4, Thorns, FinTips x2, Prism1 x2, Tip x2, Banner1 x2, GateSlits x3, WatchNeedle x3, ShardMesh, Plinth, Prism2, Banner3 |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (market_shadow 0.63, shadow_stables 0.61, magpie_den 0.61, dread_paddock 0.59, shadow_hall 0.54, watchtower 0.41) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 111 shapes over 2 body parts (55.5 per part: Model 109, Shard 2); 74% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.591 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 84 | 35% of the 12000 verts budget used (4319) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.01 at the close-up (55065 px), 4.05 at 25 m; close-up outline complexity 9.5 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 9.58 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 83 | top third L* 33.5, bottom third L* 24.4 (+9, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 95 | inner detail 2.8 at 25 m, 4.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 81 | 19 of 47 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 74.8, 0% melts; body L* 31.0 C 47.5 vs floor L* 46.2 C 39.2; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 99 | front-view asymmetry 0.2 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Model/Carving 2058 v / 1 s; Model/Fins 576 v / 1 s x6; Model/RuneRing 343 v / 1 s; Model/Rubble 336 v / 1 s x14; Model/Thorns 288 v / 1 s x3; Model/Body 264 v / 1 s; Model/WatchNeedle 252 v / 1 s; Model/SpireBands 216 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: Glow points 47 -> 10 (want 4-12): DarkStone crack_strength 1.0 -> 0.11 on GateFrame, LanternStems, Body, Prism1 (dim under the bloom level: 19 point(s), peak 6.)
