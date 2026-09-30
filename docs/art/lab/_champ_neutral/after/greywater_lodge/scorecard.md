# Art Lab scorecard: greywater_lodge

Scene `res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-30 14:54:13 · lab v3.1

## Result: **WARN** · quality **89 / 100** (89.1) (previous run 89, +0)

0 FAIL · 1 WARN · 16 PASS · 19 info · 0 skipped · 19 s

## Before / after (vs the run of 2026-09-30 11:45:49 in `docs/art/lab/_champ_neutral/before/greywater_lodge`: quality 83 -> 89, +6)
### What got worse (1)
1. **P3 Tops light, bottoms dark: INFO 52 -> INFO 50 (-2)**. Now: top third L* 49.7, bottom third L* 46.2 (+3, world height). Was: top third L* 49.8, bottom third L* 46.0 (+3, world height)

### What got better (3)
B8 Unique materials: FAIL 0 -> PASS 88 (+88); B4 Vertices: FAIL 0 -> PASS 86 (+86); B9 Materials built per instance: WARN 35 -> INFO 100 (+65)

### Score delta per check (5 changed, 32 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | FAIL 0 | PASS 86 | +85.6 |
| B8 | Unique materials | FAIL 0 | PASS 88 | +87.6 |
| B9 | Materials built per instance | WARN 35 | INFO 100 | +65.0 |
| P3 | Tops light, bottoms dark | INFO 52 | INFO 50 | -2.2 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 54 | INFO 55 | +1.2 |

Changed pixels per shot: z40 4.4 %, z55 3.5 %, z25 4.7 %, close 1.4 %, turns 1.1 %, anim 0.9 %, silhouette 0.1 %, lineup 0.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #1] _(from A1 Standard hooks)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.67): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from trade_post (IoU 0.64): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 14.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 25.6): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 22 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 7 material(s), 7 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 14 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 16 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 86 | 11847 (biggest: Structure 9990, HoundMesh 616, Rubble 350, Lantern 324) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 2 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 22 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 14 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1663 of 12070 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.06 ms process, render CPU +0.31 ms, GPU +0.17 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.09 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 24143 px (227 x 200 bbox; 55 m: 12366 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 39.7, 1% of the body melts (within dE 15 of the ground); body L* 58.6 C 11.3 vs ground L* 60.9 C 50.2, hue gap n/a (body C* <= 25); top third (world height) dE 38.7, L* 49.7; per-pixel dE 45.6, outline 31.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 88 | worst heath: dE 14.5 (heath dE 14.5, old_wood dE 32.1, riverbank dE 25.8, snow dE 32.5, ash dE 36.9, sand dE 30.7, marsh dE 42.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +25 (point 1 dL +25, point 2 dL +35, point 3 dL +35; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/2/3): BrazierFire, Lantern, Rubble; soft glows under the bloom (v1 count, luma > 0.4): 6 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (trade_post 0.64, tavern_model 0.55) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 467 shapes over 6 body parts (77.8 per part: (root) 433, DoorPivot 5, LanternPivot 10, FlagPivot 1, HornFlagPivot 1, Hound 17); 97% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.67 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 93% of the 12000 verts budget used (11205) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.03 at the close-up (97679 px), 4.27 at 25 m; close-up outline complexity 8.62 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.57 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 50 | top third L* 49.7, bottom third L* 46.2 (+3, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.6 at 25 m, 6.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 67 | 1 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 55 | on the autumn floor: dE 25.6, 4% melts; body L* 56.7 C 17.4 vs floor L* 48.6 C 41.2 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Per-mesh vertices (biggest first): Structure 9990 v / 15 s; Hound/HoundMesh 616 v / 3 s; Rubble 350 v / 1 s x10; LanternPivot/Lantern 324 v / 2 s; ContactDecal 288 v / 1 s; DoorPivot/DoorLeaf 201 v / 3 s; DoorGlow 24 v / 1 s; FlagPivot/Pennant 20 v / 1 s
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed)
