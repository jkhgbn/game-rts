# Art Lab scorecard: dusk_keep

Scene `res://art/buildings/dusk_keep.tscn` · kind **building** / tier **keep** · kingdom shadow · ground meadow · 2026-10-15 17:12:22 · lab v3.1

## Result: **WARN** · quality **87 / 100** (87.2) (previous run 87, +0)

0 FAIL · 1 WARN · 20 PASS · 18 info · 0 skipped · 52 s

## Before / after (vs the run of 2026-10-15 17:08:07 in `docs/art/lab/dusk_keep`: quality 87 -> 87, +0)
### What got worse (1)
1. **P5 Glow placement: INFO 70 -> INFO 52 (-18)**. Now: 8 of 31 glow(s) in the upper half of the model's height (world). Was: 15 of 43 glow(s) in the upper half of the model's height (world)

### What got better (2)
R5c Glow points stand out (1 m surround): WARN 57 -> PASS 89 (+32) (noisy check: re-run before acting); P3 Tops light, bottoms dark: INFO 67 -> INFO 70 (+3)

### Score delta per check (6 changed, 36 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6 | Team-colour visibility at 40 m | PASS 86 | PASS 86 | -0.6 |
| R6cb | Team colours for colour-blind players | PASS 77 | PASS 78 | +1.5 |
| P3 | Tops light, bottoms dark | INFO 67 | INFO 70 | +3.0 |
| P4 | Detail density 25 m / 40 m | INFO 91 | INFO 90 | -0.7 (noisy) |
| R5c | Glow points stand out (1 m surround) | WARN 57 | PASS 89 | +31.6 (noisy) |
| P5 | Glow placement | INFO 70 | INFO 52 | -18.2 |

Changed pixels per shot: z40 7.7 %, z55 5.9 %, z25 7.4 %, close 0.4 %, turns 0.5 %, anim 0.6 %, silhouette 0.0 %, lineup 0.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 27 -> 12 (want 4-12): DarkStone crack_strength 1.0 -> 0.12 on LanternStems, GateFrame, Prism1, WatchNeedle (dim under the bloom level: 15 point(s), peak 6.46 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.58): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Palette depth (close-up)** (INFO): Flat palette (11 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +6 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 13% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from market_shadow (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.19 ms process, render CPU +0.25 ms, GPU +0.35 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 61464 px (291 x 549 bbox; 55 m: 28133 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 93.5, 0% of the body melts (within dE 15 of the ground); body L* 29.1 C 45.9 vs ground L* 57.4 C 43.7, hue gap 167 deg; top third (world height) dE 69.9, L* 30.1; per-pixel dE 97.3, outline 71.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 51.1, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 42.8 (heath dE 76.0, old_wood dE 64.1, riverbank dE 69.0, snow dE 76.4, ash dE 42.8, sand dE 87.6, marsh dE 51.1) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 86 | 13% of body pixels change between kingdom colours (min pair 9%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 82.9 (fire 84.9, shadow 93.5, ice 85.6, nature 82.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 10.4 on the team-colour area (normal vision 27.9; 10708 px); deutan: fire / nature dE 10.4; protan: fire / nature dE 12.2; worst vs ground: fire colour (deutan) dE 68.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +4 (point 1 dL +33, point 2 dL +5, point 3 dL +20, point 4 dL +21, point 5 dL +22, point 6 dL +22, point 7 dL +9, point 8 dL +25, point 9 dL +25, point 10 dL +29, point 11 dL +4, point 12 dL +21, point 13 dL +27, point 14 dL +23, point 15 dL +16, point 16 dL +34, point 17 dL +30, point 18 dL +4, point 19 dL +13, point 20 dL +26, point 21 dL +22, point 22 dL +32, point 23 dL +38, point 24 dL +15, point 25 dL +63, point 26 dL +34, point 27 dL +24, point 28 dL +37, point 29 dL +20, point 30 dL +27, point 31 dL +35; ring 30 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 27 point(s) above the bloom level 1.2 (median of 31/24/27): ShardCore, LanternOrb2, LanternOrb3, LanternOrb1, RuneRing x3, Body, Thorns, FinTips, LanternStems x5, Prism3, GateFrame x2, WatchNeedle x2, EyeShards, GateSlits, ShardMesh, Windows, Banner3, Plinth, Prism2, 6 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 34 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): ShardCore, LanternOrb2, LanternOrb3, LanternOrb1, RuneRing x3, Body, Thorns, FinTips, LanternStems x5, Prism3, GateFrame x2, WatchNeedle x2, EyeShards, GateSlits, ShardMesh, Windows, Banner3, Plinth, Prism2 |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (market_shadow 0.63, shadow_stables 0.61, magpie_den 0.61, dread_paddock 0.59, shadow_hall 0.54, watchtower 0.41) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 111 shapes over 2 body parts (55.5 per part: Model 109, Shard 2); 75% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.584 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 84 | 35% of the 12000 verts budget used (4319) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 73 | 11 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.89 at the close-up (54896 px), 3.83 at 25 m; close-up outline complexity 10.02 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 9.96 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 70 | top third L* 30.1, bottom third L* 23.2 (+6, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 90 | inner detail 2.6 at 25 m, 4.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 52 | 8 of 31 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 71.6, 0% melts; body L* 29.1 C 43.3 vs floor L* 46.2 C 39.2; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Fix recipes: 1 in fixes.json (top: Glow points 27 -> 12 (want 4-12): DarkStone crack_strength 1.0 -> 0.12 on LanternStems, GateFrame, Prism1, WatchNeedle (dim under the bloom level: 15 point(s), )
