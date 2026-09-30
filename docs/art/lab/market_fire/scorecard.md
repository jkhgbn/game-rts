# Art Lab scorecard: market_fire

Scene `res://art/buildings/market/fire/market_fire.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-09-30 14:54:22 · lab v3.1

## Result: **PASS** · quality **92 / 100** (91.8) (previous run 90, +2)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 42 s

## Before / after (vs the run of 2026-09-30 14:43:51 in `docs/art/lab/market_fire`: quality 90 -> 92, +2)
### What got worse (0)
Nothing got worse.

### What got better (1)
R5 Glow points at 40 m: WARN 49 -> PASS 100 (+51) (noisy check: re-run before acting)

### Score delta per check (2 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R5 | Glow points at 40 m | WARN 49 | PASS 100 | +51.4 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 41 | INFO 43 | +1.6 |

Changed pixels per shot: z40 1.9 %, z55 1.8 %, z25 3.7 %, close 0.5 %, turns 0.6 %, anim 1.0 %, silhouette 0.0 %, lineup 0.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.52): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 8 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.07): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 21.6): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from fire_stables (IoU 0.64): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 49 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 8 material(s), 6 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 20 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 99 | 23 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 6460 (biggest: Stall 1677, Crates 933, PanParts 434, House 432) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 36 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 16 | no budget for building/hall |  |
| B8 | Unique materials | PASS 93 | 7 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 28 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 20 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1020 of 5360 triangles (19%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.31 ms process, render CPU +0.35 ms, GPU +0.07 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 26956 px (213 x 243 bbox; 55 m: 13784 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 57.2, 0% of the body melts (within dE 15 of the ground); body L* 37.8 C 30.6 vs ground L* 61.6 C 50.5, hue gap 75 deg; top third (world height) dE 47.6, L* 49.9; per-pixel dE 69.1, outline 47.0 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 29.1, 12% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 26.5 (heath dE 29.1, old_wood dE 32.5, riverbank dE 42.3, snow dE 58.5, ash dE 29.1, sand dE 47.9, marsh dE 26.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 29% of body pixels change between kingdom colours (min pair 28%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 41.4 (fire 60.1, shadow 73.5, ice 56.0, nature 41.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.4 on the team-colour area (normal vision 83.9; 8380 px); deutan: fire / nature dE 14.4; protan: fire / nature dE 25.8; worst vs ground: fire colour (deutan) dE 32.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +24 (point 1 dL +29, point 2 dL +30, point 3 dL +57, point 4 dL +24, point 5 dL +25, point 6 dL +28; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 6/4/3): MastTop, Brazier, PanParts, BeamParts; soft glows under the bloom (v1 count, luma > 0.4): 8 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (fire_stables 0.64, magpie_den 0.58, fire_hall 0.54, dragon_roost 0.51, watchtower 0.35, fire_tower 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 183 shapes over 8 body parts (22.9 per part: Body 129, Awning 7, Mast 21, ScalePivot 2, Beam 7, PanA 9, PanB 6, (root) 2); 95% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.517 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 52% of the 12000 verts budget used (6240) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 70 | 9 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.29 at the close-up (67709 px), 5.51 at 25 m; close-up outline complexity 6.31 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 59 | outline complexity 2.07 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 49.9, bottom third L* 27.2 (+22, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.5 at 25 m, 5.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 5 of 6 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 43 | on the autumn floor: dE 21.6, 2% melts; body L* 39.9 C 35.9 vs floor L* 49.0 C 41.4; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
