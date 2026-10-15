# Art Lab scorecard: market_fire

Scene `res://art/buildings/market/fire/market_fire.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-10-15 11:44:08 · lab v3.1

## Result: **PASS** · quality **92 / 100** (92.4) (previous run 91, +1)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 48 s

## Before / after (vs the run of 2026-10-15 11:26:59 in `docs/art/lab/gb_fire/after/market_fire`: quality 91 -> 92, +1)
### What got worse (0)
Nothing got worse.

### What got better (2)
B8 Unique materials: FAIL 14 -> PASS 88 (+74); C3 Palette depth (close-up): INFO 70 -> INFO 80 (+10)

### Score delta per check (6 changed, 37 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | FAIL 14 | PASS 88 | +73.5 |
| C3 | Palette depth (close-up) | INFO 70 | INFO 80 | +10.0 |
| R6cb | Team colours for colour-blind players | PASS 83 | PASS 83 | +0.6 |
| R5c | Glow points stand out (1 m surround) | PASS 94 | PASS 94 | -0.6 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 38 | INFO 37 | -1.0 |
| R2 | Distinct from references (black masks) | PASS 88 | PASS 87 | -0.7 |

Changed pixels per shot: z40 1.9 %, z55 1.8 %, z25 3.5 %, close 1.1 %, turns 0.2 %, anim 0.6 %, silhouette 0.1 %, lineup 1.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.52): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 19.9): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from fire_stables (IoU 0.64): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 51 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 8 material(s), 6 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 22 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 96 | 25 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 6468 (biggest: Stall 1677, Crates 933, PanParts 434, House 432) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 36 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 16 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 30 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 29 surfaces over 22 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1020 of 5364 triangles (19%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-5.73 ms process, render CPU +0.49 ms, GPU +0.91 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 28209 px (213 x 269 bbox; 55 m: 14291 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.1, 3% of the body melts (within dE 15 of the ground); body L* 40.8 C 30.9 vs ground L* 61.6 C 50.5, hue gap 71 deg; top third (world height) dE 23.9, L* 68.1; per-pixel dE 65.5, outline 40.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 29.4, 21% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 27.1 (heath dE 27.1, old_wood dE 31.6, riverbank dE 40.3, snow dE 54.8, ash dE 29.4, sand dE 43.5, marsh dE 29.1) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 28% of body pixels change between kingdom colours (min pair 28%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 38.8 (fire 57.2, shadow 70.5, ice 53.1, nature 38.8) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.8 on the team-colour area (normal vision 83.7; 8607 px); deutan: fire / nature dE 14.8; protan: fire / nature dE 25.9; worst vs ground: fire colour (deutan) dE 30.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +27 (point 1 dL +31, point 2 dL +28, point 3 dL +57, point 4 dL +27; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/5/3): Awning, HeatHaze x2, PanParts; soft glows under the bloom (v1 count, luma > 0.4): 6 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (fire_stables 0.64, magpie_den 0.58, fire_hall 0.52, dragon_roost 0.51, watchtower 0.35, fire_keep 0.25) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 185 shapes over 8 body parts (23.1 per part: Body 130, Awning 7, Mast 22, ScalePivot 2, Beam 7, PanA 9, PanB 6, (root) 2); 95% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.515 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 52% of the 12000 verts budget used (6248) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.78 at the close-up (63384 px), 6.08 at 25 m; close-up outline complexity 6.41 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 75 | outline complexity 2.28 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 68.1, bottom third L* 33.2 (+34, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.8 at 25 m, 5.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 37 | on the autumn floor: dE 19.9, 4% melts; body L* 41.9 C 36.2 vs floor L* 49.0 C 41.5; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.24 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Stall 1677 v / 2 s; Body/Crates 933 v / 1 s; Body/Mast/ScalePivot/PanA/PanParts 434 v / 2 s; Body/House 432 v / 2 s; Body/Awning 420 v / 1 s; Body/Mast/MastStack 355 v / 1 s; Body/Mast/ScalePivot/Beam/BeamParts 332 v / 1 s; Body/Brazier 305 v / 2 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
