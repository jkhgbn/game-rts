# Art Lab scorecard: magpie_den

Scene `res://art/buildings/guilds/magpie_den/magpie_den.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-10-15 12:00:41 · lab v3.1

## Result: **WARN** · quality **87 / 100** (87.2) (previous run 86, +1)

0 FAIL · 1 WARN · 16 PASS · 18 info · 0 skipped · 24 s

## Before / after (vs the run of 2026-10-15 11:51:25 in `docs/art/lab/gb_neutral/after/magpie_den`: quality 86 -> 87, +1)
### What got worse (3)
1. **P5 Glow placement: INFO 100 -> INFO 67 (-33)**. Now: 1 of 3 glow(s) in the upper half of the model's height (world). Was: 1 of 2 glow(s) in the upper half of the model's height (world)
2. **C3 Palette depth (close-up): INFO 100 -> INFO 90 (-10)**. Now: 11 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %). Was: 13 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %)
3. **R4 Contrast on the other grounds: PASS 90 -> PASS 85 (-5)**. Now: worst ash: dE 12.9 (heath dE 28.8, old_wood dE 19.9, riverbank dE 25.1, snow dE 54.6, ash dE 12.9, sand dE 54.5, marsh dE 21.6). Was: worst ash: dE 15.8 (heath dE 26.8, old_wood dE 19.2, riverbank dE 22.4, snow dE 52.6, ash dE 15.8, sand dE 52.6, marsh d

### What got better (3)
B5 Real lights: FAIL 0 -> PASS 100 (+100); P3 Tops light, bottoms dark: INFO 0 -> INFO 6 (+6); S1 Style bible: golden autumn (style-autumn.md 3): INFO 77 -> INFO 79 (+2)

### Score delta per check (7 changed, 29 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B5 | Real lights | FAIL 0 | PASS 100 | +100.0 |
| C3 | Palette depth (close-up) | INFO 100 | INFO 90 | -10.0 |
| R4 | Contrast on the other grounds | PASS 90 | PASS 85 | -5.5 |
| P3 | Tops light, bottoms dark | INFO 0 | INFO 6 | +6.3 |
| R5c | Glow points stand out (1 m surround) | PASS 97 | PASS 100 | +3.0 (noisy) |
| P5 | Glow placement | INFO 100 | INFO 67 | -33.3 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 77 | INFO 79 | +2.0 |

Changed pixels per shot: z40 7.4 %, z55 6.0 %, z25 7.7 %, close 2.2 %, turns 1.1 %, anim 1.1 %, silhouette 0.0 %, lineup 3.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #1] _(from A1 Standard hooks)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.68): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from tavern_model (IoU 0.69): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast on the other grounds** (PASS): On ash the body drops to dE 12.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 19 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 4 material(s), 3 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 12 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 85 | 11912 (biggest: Structure 9686, Vane 564, Sack 292, ContactDecal 288) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 1 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/hall |  |
| B8 | Unique materials | PASS 93 | 7 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 12 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 31 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1195 of 8346 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.17 ms process, render CPU +0.34 ms, GPU +1.65 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.17 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 33887 px (213 x 269 bbox; 55 m: 17184 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.7, 0% of the body melts (within dE 15 of the ground); body L* 34.9 C 1.9 vs ground L* 60.4 C 50.2, hue gap n/a (body C* <= 25); top third (world height) dE 56.1, L* 31.8; per-pixel dE 58.4, outline 30.0 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 85 | worst ash: dE 12.9 (heath dE 28.8, old_wood dE 19.9, riverbank dE 25.1, snow dE 54.6, ash dE 12.9, sand dE 54.5, marsh dE 21.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 100 | worst dL +44 (point 1 dL +55, point 2 dL +44, point 3 dL +45; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 3/2/2): Cloth, Lantern; soft glows under the bloom (v1 count, luma > 0.4): 5 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (tavern_model 0.69, watchtower 0.54) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 387 shapes over 5 body parts (77.4 per part: Body 343, DoorPivot 9, LanternPivot 11, VanePivot 18, SackPivot 6); 98% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.683 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 94% of the 12000 verts budget used (11332) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 11 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 8.74 at the close-up (100466 px), 8.1 at 25 m; close-up outline complexity 3.53 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.82 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 6 | top third L* 31.8, bottom third L* 35.7 (-3, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.8 at 25 m, 7.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 67 | 1 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 79 | on the autumn floor: dE 37.6, 4% melts; body L* 32.0 C 6.8 vs floor L* 47.8 C 40.7 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 75 | front-view asymmetry 0.16 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Structure 9686 v / 11 s; Body/VanePivot/Vane 564 v / 4 s; Body/SackPivot/Sack 292 v / 3 s; Body/ContactDecal 288 v / 1 s; Body/Rubble 288 v / 1 s x12; Body/LanternPivot/Lantern 261 v / 2 s; Body/Cloth 260 v / 1 s; Body/DoorPivot/DoorLeaf 237 v / 4 s
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed)
