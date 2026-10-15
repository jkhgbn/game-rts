# Art Lab scorecard: dragon_roost

Scene `res://art/buildings/lair/fire/dragon_roost.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-10-15 11:44:57 · lab v3.1

## Result: **WARN** · quality **89 / 100** (89.1) (previous run 86, +3)

0 FAIL · 1 WARN · 20 PASS · 18 info · 0 skipped · 49 s

## Before / after (vs the run of 2026-10-15 11:27:46 in `docs/art/lab/gb_fire/after/dragon_roost`: quality 86 -> 89, +3)
### What got worse (1)
1. **S1 Style bible: golden autumn (style-autumn.md 3): INFO 55 -> INFO 48 (-7)**. Now: on the autumn floor: dE 26.2, 1% melts; body L* 34.9 C 23.5 vs floor L* 48.1 C 41.2 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color). Was: on the autumn floor: dE 28.7, 1% melts; body L* 32.6 C 22.3 vs floor L* 48.1 C 41.2 (inside the floor band); fire team c

### What got better (4)
B8 Unique materials: FAIL 14 -> PASS 88 (+74); P3 Tops light, bottoms dark: INFO 39 -> INFO 87 (+48); R4k Contrast on the home ground (ash): WARN 44 -> WARN 48 (+4); R4 Contrast on the other grounds: PASS 79 -> PASS 82 (+4)

### Score delta per check (8 changed, 34 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | FAIL 14 | PASS 88 | +73.5 |
| R4k | Contrast on the home ground (ash) | WARN 44 | WARN 48 | +4.0 |
| R4 | Contrast on the other grounds | PASS 79 | PASS 82 | +3.9 |
| R6 | Team-colour visibility at 40 m | PASS 80 | PASS 81 | +0.7 |
| R6cb | Team colours for colour-blind players | PASS 87 | PASS 88 | +1.0 |
| P3 | Tops light, bottoms dark | INFO 39 | INFO 87 | +47.6 |
| R5c | Glow points stand out (1 m surround) | PASS 98 | PASS 96 | -1.9 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 55 | INFO 48 | -6.8 |

Changed pixels per shot: z40 4.8 %, z55 6.5 %, z25 5.0 %, close 1.1 %, turns 1.5 %, anim 1.4 %, silhouette 23.2 %, lineup 50.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the home ground (ash)** (WARN): shader_parameter/base_color of `ShaderMaterial#-56751` #d94d1f -> #d54505 (81% of the visible body): predicted dE R3 meadow 57.2 -> 54.0, R3t fire 61.1 -> 57.1, R3t shadow 64.0 -> 60.3, R3t ice 60.9 -> 57.3, R3t nature 58.1 -> 53.9, R4k ash 11.5 -> 18.2 (want >= 18); other grounds heath 30.3, old_wood 20.3, riverbank 32.2, snow 65.1, sand 53.2, marsh 16.3; built in code or embedded: change it where the model script creates it [fixes.json #1] _(from R4k Contrast on the home ground (ash), shot z40)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.7): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 8% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
4. **Contrast on the other grounds** (PASS): On ash the body drops to dE 11.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from market_fire (IoU 0.7): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 26.2): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 45 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 8 material(s), 7 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 18 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 21 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 5579 (biggest: NestBowl 1567, Spire 1170, Gatehouse 641, NestSpikes 504) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 13 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 36 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 10 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 26 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 18 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 588 of 3760 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0051 ms process per instance (8 animated at 40 m: +0.04 ms process, render CPU +0.25 ms, GPU +1.07 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 39941 px (217 x 300 bbox; 55 m: 19788 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 57.2, 1% of the body melts (within dE 15 of the ground); body L* 31.6 C 16.8 vs ground L* 60.6 C 50.2, hue gap n/a (body C* <= 25); top third (world height) dE 54.2, L* 35.3; per-pixel dE 65.8, outline 47.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | **WARN** 48 | dE 11.5, 22% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 82 | worst ash: dE 11.5 (heath dE 32.4, old_wood dE 22.4, riverbank dE 33.5, snow dE 62.6, ash dE 11.5, sand dE 54.4, marsh dE 15.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 81 | 8% of body pixels change between kingdom colours (min pair 7%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 58.1 (fire 61.1, shadow 64.0, ice 60.9, nature 58.1) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 88 | worst pair fire / nature (deutan): dE 19.5 on the team-colour area (normal vision 52.6; 4551 px); deutan: fire / nature dE 19.5; protan: fire / nature dE 25.5; worst vs ground: nature colour (deutan) dE 45.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 96 | worst dL +30 (point 1 dL +30, point 2 dL +61; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/3/2): RaiseBurst, HeatHaze; soft glows under the bloom (v1 count, luma > 0.4): 23 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.7 (market_fire 0.7, fire_stables 0.66, magpie_den 0.6, fire_hall 0.54, watchtower 0.37, fire_keep 0.25) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 192 shapes over 5 body parts (38.4 per part: Body 83, PlinthBase 8, Perch 12, Nest 87, (root) 2); 83% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.698 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 44% of the 12000 verts budget used (5355) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.7 at the close-up (100495 px), 8.6 at 25 m; close-up outline complexity 4.76 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.01 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 87 | top third L* 35.3, bottom third L* 25.6 (+9, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.7 at 25 m, 7.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 48 | on the autumn floor: dE 26.2, 1% melts; body L* 34.9 C 23.5 vs floor L* 48.1 C 41.2 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Per-mesh vertices (biggest first): Body/Nest/NestBowl 1567 v / 2 s; Body/Spire 1170 v / 2 s; Body/Gatehouse 641 v / 2 s; Body/Nest/NestSpikes 504 v / 2 s; Body/Lava 445 v / 2 s; Body/Perch/PerchParts 279 v / 2 s; Body/PlinthBase 264 v / 1 s; Rubble 216 v / 1 s x9
- 8 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: shader_parameter/base_color of `ShaderMaterial#-56751` #d94d1f -> #d54505 (81% of the visible body): predicted dE R3 meadow 57.2 -> 54.0, R3t fire 61.1 -> 57.1,)
