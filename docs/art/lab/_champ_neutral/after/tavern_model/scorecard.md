# Art Lab scorecard: tavern_model

Scene `res://art/buildings/tavern/tavern_model.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-30 14:43:13 · lab v3.1

## Result: **WARN** · quality **88 / 100** (87.6) (previous run 87, +1)

0 FAIL · 1 WARN · 16 PASS · 19 info · 0 skipped · 19 s

## Before / after (vs the run of 2026-09-30 11:46:08 in `docs/art/lab/_champ_neutral/before/tavern_model`: quality 83 -> 88, +5)
### What got worse (0)
Nothing got worse.

### What got better (2)
B8 Unique materials: FAIL 0 -> PASS 98 (+98); R5 Glow points at 40 m: WARN 49 -> PASS 100 (+51) (noisy check: re-run before acting)

### Score delta per check (6 changed, 34 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | PASS 99 | PASS 98 | -0.7 |
| B8 | Unique materials | FAIL 0 | PASS 98 | +97.9 |
| R4 | Contrast on the other grounds | PASS 100 | PASS 99 | -0.7 |
| P1 | Silhouette hook | INFO 12 | INFO 12 | -0.5 |
| R5 | Glow points at 40 m | WARN 49 | PASS 100 | +51.4 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 8 | INFO 7 | -1.0 |

Changed pixels per shot: z40 5.1 %, z55 4.8 %, z25 5.1 %, close 1.2 %, turns 3.9 %, anim 0.9 %, silhouette 0.1 %, lineup 7.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #1] _(from A1 Standard hooks)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.64): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.45): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 10.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from magpie_den (IoU 0.69): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 17 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 3 material(s), 4 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 11 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 98 | 8816 (biggest: Structure 6434, SignBoard 1000, Rubble 432, Lantern 359) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 1 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 10 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | PASS 98 | 6 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 11 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 956 of 7758 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.04 ms process, render CPU +0.22 ms, GPU +0.67 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.09 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 37970 px (227 x 259 bbox; 55 m: 19286 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 38.6, 0% of the body melts (within dE 15 of the ground); body L* 59.2 C 36.7 vs ground L* 60.6 C 50.6, hue gap 49 deg; top third (world height) dE 38.4, L* 66.6; per-pixel dE 46.4, outline 28.8 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 99 | worst heath: dE 20.6 (heath dE 20.6, old_wood dE 40.9, riverbank dE 38.1, snow dE 45.5, ash dE 49.8, sand dE 22.6, marsh dE 49.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 96 | worst dL +16 (point 1 dL +52, point 2 dL +40, point 3 dL +53, point 4 dL +16, point 5 dL +58; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 5/2/2): Lantern, DoorLeaf; soft glows under the bloom (v1 count, luma > 0.4): 5 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (magpie_den 0.69, greywater_lodge 0.55) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 243 shapes over 4 body parts (60.8 per part: Body 203, DoorPivot 7, SignPivot 21, LanternPivot 12); 80% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.637 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 67% of the 12000 verts budget used (8088) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 8.5 at the close-up (108052 px), 7.53 at 25 m; close-up outline complexity 2.06 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 12 | outline complexity 1.45 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 66.6, bottom third L* 37.0 (+29, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.3 at 25 m, 4.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 40 | 1 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 7 | on the autumn floor: dE 10.3, 11% melts; body L* 56.0 C 42.1 vs floor L* 47.8 C 40.8 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 87 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Structure 6434 v / 9 s; Body/SignPivot/SignBoard 1000 v / 5 s; Body/Rubble 432 v / 1 s x9; Body/LanternPivot/Lantern 359 v / 2 s; Body/ContactDecal 288 v / 1 s; Body/DoorPivot/DoorLeaf 263 v / 3 s; Body/DoorGlow 24 v / 1 s; Body/LanternPivot/Halo 4 v / 1 s
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed)
