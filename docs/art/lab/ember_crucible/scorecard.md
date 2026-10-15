# Art Lab scorecard: ember_crucible

Scene `res://art/buildings/fire/ember_crucible/ember_crucible.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-10-15 18:36:25 · lab v3.1

## Result: **WARN** · quality **92 / 100** (91.8) (previous run 92, +0)

0 FAIL · 1 WARN · 21 PASS · 16 info · 0 skipped · 20 s

## Before / after (vs the run of 2026-10-12 01:11:03 in `docs/art/lab/ember_crucible`: quality 92 -> 92, +0)
### What got worse (1)
1. **R5c Glow points stand out (1 m surround): PASS 95 -> PASS 83 (-11) (noisy check: re-run before acting)**. Now: worst dL +4 (point 1 dL +4, point 2 dL +24; ring 24 px = 1.0 m at 40 m). Was: worst dL +25 (point 1 dL +25, point 2 dL +47; ring 24 px = 1.0 m at 40 m)

### What got better (1)
S1 Style bible: golden autumn (style-autumn.md 3): INFO 62 -> INFO 85 (+23)

### Score delta per check (2 changed, 36 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R5c | Glow points stand out (1 m surround) | PASS 95 | PASS 83 | -11.4 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 62 | INFO 85 | +22.5 |

Changed pixels per shot: z40 1.1 %, z55 0.5 %, z25 2.0 %, close 4.0 %, turns 4.2 %, anim 2.6 %, silhouette 4.8 %, lineup 43.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Silhouette area at 40 m** (WARN): R1 4119 -> ~5749 px: grow the 40 m read x1.18 (area goes with the square: scale the key masses / body 18 %) [fixes.json #1] _(from R1 Silhouette area at 40 m, shot z40)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.78): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 16% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 18 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 6 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 6 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 4482 (biggest: Static 2078, CrucibleBody 1934, Crust 271, PilotGlow 109) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/hall |  |
| B8 | Unique materials | PASS 93 | 7 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 11 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 6 surfaces over 6 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 698 of 4976 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.0 ms process, render CPU +0.03 ms, GPU +0.06 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point 0.0 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | **WARN** 44 | 4119 px (88 x 114 bbox; 55 m: 2135 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 | Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 56.1, 0% of the body melts (within dE 15 of the ground); body L* 38.2 C 21.9 vs ground L* 64.0 C 48.2, hue gap n/a (body C* <= 25); top third (world height) dE 48.3, L* 49.4; per-pixel dE 64.6, outline 58.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 22.3, 20% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 22.3 (heath dE 27.4, old_wood dE 29.7, riverbank dE 44.6, snow dE 55.4, ash dE 22.3, sand dE 48.7, marsh dE 24.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 90 | 16% of body pixels change between kingdom colours (min pair 16%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 47.0 (fire 56.1, shadow 61.1, ice 53.3, nature 47.0) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 75 | worst pair fire / nature (deutan): dE 7.1 on the team-colour area (normal vision 78.7; 680 px); deutan: fire / nature dE 7.1; protan: fire / nature dE 23.6; worst vs ground: fire colour (deutan) dE 36.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 83 | worst dL +4 (point 1 dL +4, point 2 dL +24; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): PilotGlow, Crust; soft glows under the bloom (v1 count, luma > 0.4): 2 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 94 | max IoU 0.54 (wayshrine 0.54, fire_tower 0.53, essence_well 0.44, fire_forge 0.16, fire_stables 0.16, fire_hall 0.12) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 26 | 125 shapes over 4 body parts (31.3 per part: (root) 91, CruciblePivot 30, BellowsTop 3, BellowsLeather 1); 73% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.778 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 89 | 37% of the 12000 verts budget used (4482) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.41 at the close-up (99689 px), 4.18 at 25 m; close-up outline complexity 6.15 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.88 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 49.4, bottom third L* 36.4 (+12, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.8 at 25 m, 13.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 41.5, 0% melts; body L* 36.9 C 27.1 vs floor L* 61.0 C 40.0 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 83 | front-view asymmetry 0.17 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Static 2078 v / 1 s; CruciblePivot/CrucibleBody 1934 v / 1 s; CruciblePivot/Crust 271 v / 1 s; PilotGlow 109 v / 1 s; BellowsTop/BellowsBoard 70 v / 1 s; BellowsLeather/Leather 20 v / 1 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R1 4119 -> ~5749 px: grow the 40 m read x1.18 (area goes with the square: scale the key masses / body 18 %))
