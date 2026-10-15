# Art Lab scorecard: hovel

Scene `res://art/buildings/hovel.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-10-15 11:21:43 · lab v3.1

## Result: **PASS** · quality **88 / 100** (88.3) (previous run 86, +2)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 35 s

## Before / after (vs the run of 2026-10-15 11:05:35 in `docs/art/lab/hovel`: quality 86 -> 88, +2)
### What got worse (2)
1. **P2 Asymmetric secondary shape: INFO 83 -> INFO 49 (-34)**. Now: front-view asymmetry 0.11. Was: front-view asymmetry 0.17
2. **C3 Palette depth (close-up): INFO 63 -> INFO 57 (-7)**. Now: 11 colour steps (L*a*b* bins >= 2 % of the body), 6 value steps (L* bins of 8 >= 3 %). Was: 10 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %)

### What got better (3)
R5 Glow points at 40 m: WARN 49 -> PASS 100 (+51) (noisy check: re-run before acting); C2 Vertex use vs budget: INFO 0 -> INFO 24 (+24); P1 Silhouette hook: INFO 37 -> INFO 60 (+23)

### Score delta per check (8 changed, 34 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C2 | Vertex use vs budget | INFO 0 | INFO 24 | +24.4 |
| C3 | Palette depth (close-up) | INFO 63 | INFO 57 | -6.7 |
| R6cb | Team colours for colour-blind players | PASS 84 | PASS 83 | -1.2 |
| P1 | Silhouette hook | INFO 37 | INFO 60 | +23.2 |
| P4 | Detail density 25 m / 40 m | INFO 95 | INFO 98 | +3.4 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 91 | PASS 90 | -0.8 (noisy) |
| R5 | Glow points at 40 m | WARN 49 | PASS 100 | +51.4 (noisy) |
| P2 | Asymmetric secondary shape | INFO 83 | INFO 49 | -34.0 |

Changed pixels per shot: z40 21.8 %, z55 16.3 %, z25 24.3 %, close 28.8 %, turns 25.1 %, anim 24.3 %, silhouette 0.1 %, lineup 18.2 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.6): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Vertex use vs budget** (INFO): Only 21% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
3. **Palette depth (close-up)** (INFO): Flat palette (11 colour / 6 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
4. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.11): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.08): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 9 material(s), 1 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 7 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 2704 (biggest: Walls 1140, Roof 918, Plinth 349, Rubble 168) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 7 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 24 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | PASS 100 | 5 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 9 surfaces over 7 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 344 of 2136 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0022 ms process per instance (8 animated at 40 m: +0.02 ms process, render CPU +0.17 ms, GPU +0.59 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.29 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 14225 px (137 x 164 bbox; 55 m: 7327 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 100.7, 0% of the body melts (within dE 15 of the ground); body L* 28.3 C 44.9 vs ground L* 62.1 C 50.6, hue gap 166 deg; top third (world height) dE 114.0, L* 43.4; per-pixel dE 104.1, outline 58.3 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 49.8, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 41.4 (heath dE 72.6, old_wood dE 65.4, riverbank dE 76.9, snow dE 77.3, ash dE 41.4, sand dE 87.7, marsh dE 49.8) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 56% of body pixels change between kingdom colours (min pair 55%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 31.4 (fire 68.2, shadow 100.4, ice 63.2, nature 31.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.7 on the team-colour area (normal vision 89.4; 8255 px); deutan: fire / nature dE 14.7; protan: fire / nature dE 26.1; worst vs ground: fire colour (deutan) dE 27.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +17 (point 1 dL +17, point 2 dL +31, point 3 dL +31; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/4/3): LanternOrb, Rubble x2; soft glows under the bloom (v1 count, luma > 0.4): 9 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.4 (greywater_lodge 0.4, shadow_tower 0.35, market_shadow 0.33, shadow_stables 0.32, trade_post 0.31, dread_paddock 0.28) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 87 shapes over 1 body parts (87.0 per part: Body 87); 72% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.599 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 24 | 21% of the 12000 verts budget used (2532) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 57 | 11 colour steps (L*a*b* bins >= 2 % of the body), 6 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.99 at the close-up (64479 px), 3.82 at 25 m; close-up outline complexity 2.51 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 60 | outline complexity 2.08 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 43.4, bottom third L* 11.2 (+32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 98 | inner detail 2.9 at 25 m, 4.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 71.2, 0% melts; body L* 27.5 C 40.5 vs floor L* 49.2 C 41.4; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 49 | front-view asymmetry 0.11 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Walls 1140 v / 2 s; Body/Roof 918 v / 2 s; Body/Plinth 349 v / 1 s; Rubble 168 v / 1 s x7; Body/LanternOrb 104 v / 1 s; Body/TipShard 21 v / 1 s; ContactDecal 4 v / 1 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
