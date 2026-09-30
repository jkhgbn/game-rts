# Art Lab scorecard: fire_hall

Scene `res://art/buildings/fire_hall.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-09-30 14:44:31 · lab v3.1

## Result: **PASS** · quality **92 / 100** (91.5) (previous run 92, +0)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 44 s

## Before / after (vs the run of 2026-09-30 13:08:25 in `docs/art/lab/fire_hall`: quality 92 -> 92, +0)
### What got worse (1)
1. **R6cb Team colours for colour-blind players: PASS 83 -> PASS 78 (-5)**. Now: worst pair fire / nature (deutan): dE 15.3 on the team-colour area (normal vision 92.4; 18626 px); deutan: fire / nature dE 15.3; protan: fire / nature dE 25.9; worst vs ground: fi. Was: worst pair fire / nature (deutan): dE 16.1 on the team-colour area (normal vision 94.5; 18505 px); deutan: fire / nature

### Score delta per check (3 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6cb | Team colours for colour-blind players | PASS 83 | PASS 78 | -4.6 |
| P4 | Detail density 25 m / 40 m | INFO 92 | INFO 94 | +2.6 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 95 | PASS 98 | +2.4 (noisy) |

Changed pixels per shot: z40 0.4 %, z55 0.3 %, z25 0.5 %, close 0.7 %, turns 1.2 %, anim 0.6 %, silhouette 0.0 %, lineup 0.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.55): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.54): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from market_fire (IoU 0.69): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 23.8): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.8): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 37 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 7 material(s), 6 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 12 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 16 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 4522 (biggest: Walls 2118, Roof 652, PlinthBase 600, ChimneyStack 393) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 4 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 50 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 7 | no budget for building/hall |  |
| B8 | Unique materials | PASS 98 | 6 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 19 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 15 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 457 of 3004 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.58 ms process, render CPU +0.2 ms, GPU +0.35 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 42637 px (251 x 275 bbox; 55 m: 21317 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 60.3, 0% of the body melts (within dE 15 of the ground); body L* 47.6 C 45.7 vs ground L* 59.7 C 49.9, hue gap 76 deg; top third (world height) dE 44.2, L* 58.4; per-pixel dE 71.5, outline 45.7 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 47.0, 13% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 39.0 (heath dE 39.0, old_wood dE 48.4, riverbank dE 52.5, snow dE 60.6, ash dE 47.0, sand dE 44.1, marsh dE 44.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 42% of body pixels change between kingdom colours (min pair 42%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 22.4 (fire 60.5, shadow 79.8, ice 48.1, nature 22.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 15.3 on the team-colour area (normal vision 92.4; 18626 px); deutan: fire / nature dE 15.3; protan: fire / nature dE 25.9; worst vs ground: fire colour (deutan) dE 9.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 98 | worst dL +27 (point 1 dL +48, point 2 dL +56, point 3 dL +60, point 4 dL +27; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/4/4): ChimneyFire, Rubble, LightPool, BannerL; soft glows under the bloom (v1 count, luma > 0.4): 11 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (market_fire 0.69, fire_stables 0.63, magpie_den 0.59, dragon_roost 0.51, watchtower 0.35, fire_tower 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 152 shapes over 3 body parts (50.7 per part: Body 119, Chimney 23, WeaponRack 10); 95% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.552 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 83 | 35% of the 12000 verts budget used (4294) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.36 at the close-up (98773 px), 7.28 at 25 m; close-up outline complexity 2.46 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 18 | outline complexity 1.54 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 58.4, bottom third L* 22.4 (+35, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 94 | inner detail 2.8 at 25 m, 3.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 49 | on the autumn floor: dE 23.8, 0% melts; body L* 48.1 C 49.9 vs floor L* 47.3 C 40.6; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Per-mesh vertices (biggest first): Body/Walls 2118 v / 2 s; Body/Roof 652 v / 2 s; Body/PlinthBase 600 v / 1 s; Body/Chimney/ChimneyStack 393 v / 1 s; Body/WeaponRack/RackParts 300 v / 1 s; Rubble 216 v / 1 s x9; Body/Chimney/ChimneyTop 135 v / 2 s; Body/Chimney/ChimneyBanner 48 v / 1 s
- 7 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
