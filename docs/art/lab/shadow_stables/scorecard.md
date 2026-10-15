# Art Lab scorecard: shadow_stables

Scene `res://art/buildings/stables/shadow/shadow_stables.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-10-15 11:22:46 · lab v3.1

## Result: **PASS** · quality **92 / 100** (91.5) (previous run 92, +0)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 46 s

## Before / after (vs the run of 2026-10-15 11:06:32 in `docs/art/lab/shadow_stables`: quality 92 -> 92, +0)
### What got worse (1)
1. **C3 Palette depth (close-up): INFO 63 -> INFO 53 (-10)**. Now: 9 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %). Was: 10 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %)

### Score delta per check (2 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 63 | INFO 53 | -10.0 |
| R5c | Glow points stand out (1 m surround) | PASS 100 | PASS 98 | -1.3 (noisy) |

Changed pixels per shot: z40 0.2 %, z55 0.5 %, z25 0.1 %, close 0.4 %, turns 0.3 %, anim 0.9 %, silhouette 0.0 %, lineup 5.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.69): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from market_shadow (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 46 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 15 material(s), 4 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 17 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 18 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 89 | 10982 (biggest: Walls 2499, TowerStack 1864, Yard 1730, Roof 1271) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 9 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 8 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 14 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 25 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 22 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1266 of 8639 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.05 ms process, render CPU +0.23 ms, GPU +0.28 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 27793 px (219 x 209 bbox; 55 m: 14153 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 94.4, 0% of the body melts (within dE 15 of the ground); body L* 29.7 C 40.0 vs ground L* 60.0 C 49.9, hue gap 168 deg; top third (world height) dE 108.7, L* 50.0; per-pixel dE 98.7, outline 45.9 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 45.4, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 37.0 (heath dE 67.6, old_wood dE 60.2, riverbank dE 65.7, snow dE 73.1, ash dE 37.0, sand dE 83.2, marsh dE 45.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 49% of body pixels change between kingdom colours (min pair 49%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 29.1 (fire 66.3, shadow 94.2, ice 60.2, nature 29.1) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.4 on the team-colour area (normal vision 101.2; 13765 px); deutan: fire / nature dE 14.4; protan: fire / nature dE 27.9; worst vs ground: fire colour (deutan) dE 24.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 98 | worst dL +35 (point 1 dL +35, point 2 dL +75, point 3 dL +67; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): PlinthFence x2, Walls; soft glows under the bloom (v1 count, luma > 0.4): 4 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (market_shadow 0.63, dread_paddock 0.58, magpie_den 0.56, shadow_hall 0.48, watchtower 0.35, shadow_tower 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 371 shapes over 9 body parts (41.2 per part: Body 245, LoftTower 65, BalePivot 6, PlinthFence 2, LeafL 7, LeafR 7, Mount 29, HeadPivot 8, TailPivot 2); 85% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.686 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 89% of the 12000 verts budget used (10762) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 53 | 9 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.89 at the close-up (78073 px), 3.68 at 25 m; close-up outline complexity 4.62 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.98 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 50.0, bottom third L* 17.5 (+32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 98 | inner detail 2.9 at 25 m, 4.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 67 | 1 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 64.5, 0% melts; body L* 27.1 C 33.7 vs floor L* 47.8 C 40.5 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.32 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Walls 2499 v / 2 s; Body/LoftTower/TowerStack 1864 v / 3 s; Body/Yard 1730 v / 2 s; Body/Roof 1271 v / 2 s; Mount/MountBody 968 v / 1 s; Body/PlinthFence 808 v / 1 s; Body/PlinthBase 663 v / 1 s; Mount/HeadPivot/MountHead 295 v / 1 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
