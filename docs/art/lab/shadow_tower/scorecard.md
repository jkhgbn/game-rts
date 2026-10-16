# Art Lab scorecard: shadow_tower

Scene `res://art/buildings/shadow_tower.tscn` · kind **building** / tier **small** · kingdom shadow · ground meadow · 2026-10-15 20:12:16 · lab v3.1

## Result: **PASS** · quality **93 / 100** (93.0) (previous run 88, +5)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 25 s

## Before / after (vs the run of 2026-10-15 11:22:20 in `docs/art/lab/shadow_tower`: quality 88 -> 93, +5)
### What got worse (2)
1. **R4 Contrast on the other grounds: PASS 100 -> PASS 95 (-5)**. Now: worst ash: dE 18.1 (heath dE 53.3, old_wood dE 42.4, riverbank dE 53.9, snow dE 67.4, ash dE 18.1, sand dE 72.6, marsh dE 28.4). Was: worst ash: dE 24.0 (heath dE 54.5, old_wood dE 47.8, riverbank dE 58.9, snow dE 65.1, ash dE 24.0, sand dE 72.4, marsh d
2. **R5c Glow points stand out (1 m surround): PASS 94 -> PASS 88 (-6) (noisy check: re-run before acting)**. Now: worst dL +12 (point 1 dL +12, point 2 dL +34; ring 25 px = 1.0 m at 40 m). Was: worst dL +23 (point 1 dL +23, point 2 dL +60; ring 25 px = 1.0 m at 40 m)

### What got better (5)
C2 Vertex use vs budget: INFO 24 -> INFO 100 (+76); C3 Palette depth (close-up): INFO 50 -> INFO 80 (+30); C4 Inner detail (close-up / 25 m): INFO 92 -> INFO 100 (+8); S1 Style bible: golden autumn (style-autumn.md 3): INFO 85 -> INFO 100 (+15); R6cb Team colours for colour-blind players: PASS 81 -> PASS 84 (+4)

### Score delta per check (8 changed, 32 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C2 | Vertex use vs budget | INFO 24 | INFO 100 | +75.5 |
| C3 | Palette depth (close-up) | INFO 50 | INFO 80 | +30.0 |
| C4 | Inner detail (close-up / 25 m) | INFO 92 | INFO 100 | +8.2 |
| R1 | Silhouette area at 40 m | PASS 81 | PASS 83 | +1.3 |
| R4 | Contrast on the other grounds | PASS 100 | PASS 95 | -5.5 |
| R6cb | Team colours for colour-blind players | PASS 81 | PASS 84 | +3.8 |
| R5c | Glow points stand out (1 m surround) | PASS 94 | PASS 88 | -5.6 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | INFO 100 | +15.0 |

Changed pixels per shot: z40 5.5 %, z55 4.3 %, z25 5.3 %, close 6.7 %, turns 2.8 %, anim 6.3 %, silhouette 5.5 %, lineup 48.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.73): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Silhouette area at 40 m** (PASS): Grow the read at 40 m (now 5371 px): push the key shape (weapon, horns, crest, back mass) 15-25 % bigger _(from R1 Silhouette area at 40 m, shot z40)_
3. **Contrast on the other grounds** (PASS): On ash the body drops to dE 18.1: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 8 material(s), 1 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 10 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 11 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 | 4187 (biggest: Collar 2722, Shaft 729, RuneRing 175, Rubble 168) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO | 7 | no budget for building/small |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 10 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/small |  |
| B8 | Unique materials | PASS 88 | 6 | <= 6 soft (lab default (towers, walls, posts): half a keep) |  |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 12 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 502 of 2908 triangles (17%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.04 ms process, render CPU +0.12 ms, GPU +0.01 ms) | <= 0.05 ms per instance (lab default (towers, walls, posts): half a keep) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.21 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 83 | 5371 px (79 x 129 bbox; 55 m: 2754 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 78.0, 1% of the body melts (within dE 15 of the ground); body L* 26.4 C 20.2 vs ground L* 62.1 C 49.4, hue gap n/a (body C* <= 25); top third (world height) dE 85.9, L* 39.0; per-pixel dE 83.5, outline 50.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 28.4, 1% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 95 | worst ash: dE 18.1 (heath dE 53.3, old_wood dE 42.4, riverbank dE 53.9, snow dE 67.4, ash dE 18.1, sand dE 72.6, marsh dE 28.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 30% of body pixels change between kingdom colours (min pair 29%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 54.8 (fire 63.8, shadow 78.8, ice 62.7, nature 54.8) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 84 | worst pair fire / nature (deutan): dE 16.0 on the team-colour area (normal vision 49.8; 1630 px); deutan: fire / nature dE 16.0; protan: fire / nature dE 22.2; worst vs ground: nature colour (deutan) dE 47.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +12 (point 1 dL +12, point 2 dL +34; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 2/3/4): OrbMotes, RuneStones x2; soft glows under the bloom (v1 count, luma > 0.4): 1 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.14 (greywater_lodge 0.14, shadow_forge 0.11, market_shadow 0.11, shadow_stables 0.11, trade_post 0.1, dread_paddock 0.09) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 146 shapes over 2 body parts (73.0 per part: Body 145, (root) 1); 48% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.729 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 65% of the 6000 verts budget used (3952) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.95 at the close-up (70219 px), 3.76 at 25 m; close-up outline complexity 6.21 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.12 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 39.0, bottom third L* 14.7 (+24, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.3 at 25 m, 9.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 64.0, 0% melts; body L* 24.9 C 19.0 vs floor L* 59.3 C 39.8; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 91 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Collar 2722 v / 1 s; Body/Shaft 729 v / 2 s; Body/RuneRing 175 v / 1 s; Rubble 168 v / 1 s x7; Body/RuneStones 144 v / 2 s; Body/Orb 104 v / 1 s; Body/Plinth 74 v / 1 s; Body/Fins 63 v / 1 s x3
- 4 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
