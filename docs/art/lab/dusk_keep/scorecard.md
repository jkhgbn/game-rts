# Art Lab scorecard: dusk_keep

Scene `res://art/buildings/dusk_keep.tscn` · kind **building** / tier **keep** · kingdom shadow · ground meadow · 2026-10-15 11:19:23 · lab v3.1

## Result: **WARN** · quality **89 / 100** (89.1) (previous run 89, +0)

0 FAIL · 1 WARN · 20 PASS · 18 info · 0 skipped · 79 s

## Before / after (vs the run of 2026-10-15 11:03:04 in `docs/art/lab/dusk_keep`: quality 89 -> 89, +0)
### What got worse (3)
1. **C3 Palette depth (close-up): INFO 100 -> INFO 83 (-17)**. Now: 13 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %). Was: 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %)
2. **P3 Tops light, bottoms dark: INFO 95 -> INFO 88 (-7)**. Now: top third L* 34.4, bottom third L* 24.4 (+10, world height). Was: top third L* 35.2, bottom third L* 24.1 (+11, world height)
3. **R6 Team-colour visibility at 40 m: PASS 93 -> PASS 91 (-2)**. Now: 17% of body pixels change between kingdom colours (min pair 13%). Was: 19% of body pixels change between kingdom colours (min pair 13%)

### What got better (1)
R5c Glow points stand out (1 m surround): WARN 62 -> PASS 94 (+32) (noisy check: re-run before acting)

### Score delta per check (6 changed, 35 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 100 | INFO 83 | -16.7 |
| R6 | Team-colour visibility at 40 m | PASS 93 | PASS 91 | -2.4 |
| P3 | Tops light, bottoms dark | INFO 95 | INFO 88 | -6.8 |
| P4 | Detail density 25 m / 40 m | INFO 93 | INFO 92 | -0.6 (noisy) |
| R5c | Glow points stand out (1 m surround) | WARN 62 | PASS 94 | +31.5 (noisy) |
| P5 | Glow placement | INFO 86 | INFO 87 | +0.7 |

Changed pixels per shot: z40 14.1 %, z55 11.5 %, z25 20.8 %, close 1.7 %, turns 2.6 %, anim 2.8 %, silhouette 0.0 %, lineup 0.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 46 -> 11 (want 4-12): DarkStone crack_strength 1.0 -> 0.12 on LanternStems, GateFrame, Body, Prism1 (dim under the bloom level: 18 point(s), peak 6.12 x the level); Glow boost_mult 1.0 -> 0.09 on ShardCore, LanternOrb2, LanternOrb1, Windows (dim under the bloom level: 17 point(s), peak 8.0 x the level (>= 8, clipped)) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.59): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from market_shadow (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 17% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
5. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.7): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 67 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 7 material(s), 4 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
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
| B1a | Authored build parts (before the merge) | INFO | 49 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 29 surfaces over 29 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 600 of 4108 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-4.7 ms process, render CPU +0.52 ms, GPU +0.29 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 62123 px (291 x 549 bbox; 55 m: 28442 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 97.5, 0% of the body melts (within dE 15 of the ground); body L* 31.8 C 51.0 vs ground L* 57.4 C 43.7, hue gap 166 deg; top third (world height) dE 69.9, L* 34.4; per-pixel dE 101.5, outline 63.0 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 56.2, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 48.8 (heath dE 80.2, old_wood dE 69.2, riverbank dE 73.8, snow dE 77.4, ash dE 48.8, sand dE 90.4, marsh dE 56.2) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 91 | 17% of body pixels change between kingdom colours (min pair 13%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 86.6 (fire 88.9, shadow 97.0, ice 88.8, nature 86.6) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 74 | worst pair fire / nature (deutan): dE 6.3 on the team-colour area (normal vision 18.9; 14299 px); deutan: fire / nature dE 6.3; protan: fire / nature dE 8.0; worst vs ground: fire colour (deutan) dE 71.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +4 (point 1 dL +22, point 2 dL +44, point 3 dL +29, point 4 dL +51, point 5 dL +51, point 6 dL +41, point 7 dL +58, point 8 dL +33, point 9 dL +53, point 10 dL +25, point 11 dL +43, point 12 dL +30, point 13 dL +32, point 14 dL +34, point 15 dL +46, point 16 dL +26, point 17 dL +21, point 18 dL +33, point 19 dL +36, point 20 dL +53, point 21 dL +34, point 22 dL +4, point 23 dL +43, point 24 dL +30, point 25 dL +47, point 26 dL +49, point 27 dL +20, point 28 dL +38, point 29 dL +35, point 30 dL +22, point 31 dL +27, point 32 dL +26, point 33 dL +35, point 34 dL +50, point 35 dL +36, point 36 dL +9, point 37 dL +36, point 38 dL +18, point 39 dL +61, point 40 dL +24, point 41 dL +32, point 42 dL +16, point 43 dL +8, point 44 dL +44, point 45 dL +57, point 46 dL +81; ring 30 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 46 point(s) above the bloom level 1.2 (median of 46/46/49): ShardCore, LanternStems x7, LanternOrb2, GateFrame x4, Windows x6, Banner2, LanternOrb1, RuneRing x5, Thorns, LanternOrb3, FinTips x2, Prism1, Prism3 x3, GateSlits x2, Banner1 x2, WatchNeedle x3, Plinth, Tip, ShardMesh, EyeShards, Prism2, 2 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 48 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): ShardCore, LanternStems x7, LanternOrb2, GateFrame x4, Windows x6, Banner2, LanternOrb1, RuneRing x5, Thorns, LanternOrb3, FinTips x2, Prism1, Prism3 x3, GateSlits x2, Banner1 x2, WatchNeedle x3, Plinth, Tip, ShardMesh, EyeShards, Prism2 |
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
| C3 | Palette depth (close-up) | INFO 83 | 13 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.0 at the close-up (55139 px), 3.96 at 25 m; close-up outline complexity 9.54 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 9.65 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 88 | top third L* 34.4, bottom third L* 24.4 (+10, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 92 | inner detail 2.7 at 25 m, 4.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 87 | 20 of 46 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 75.4, 0% melts; body L* 32.3 C 48.5 vs floor L* 46.2 C 39.2; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- 16 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: Glow points 46 -> 11 (want 4-12): DarkStone crack_strength 1.0 -> 0.12 on LanternStems, GateFrame, Body, Prism1 (dim under the bloom level: 18 point(s), peak 6.)
