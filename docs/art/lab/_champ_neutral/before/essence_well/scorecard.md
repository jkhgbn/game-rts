# Art Lab scorecard: essence_well

Scene `res://art/buildings/capture/essence_well/essence_well.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-30 11:47:27 · lab v3.1

## Result: **FAIL** · quality **69 / 100** (69.2)

1 FAIL · 2 WARN · 15 PASS · 18 info · 0 skipped · 38 s

## Improve next
1. **Contrast vs ground (meadow)** (FAIL): R3 Contrast vs ground (meadow): Raise the contrast of the key read on meadow (dE 15.0): value is close to the ground (dL -5): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 2 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it [fixes.json #1] _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Contrast on the other grounds** (WARN): R4 Contrast on the other grounds: On ash the body drops to dE 4.4: add a value accent that separates it there too [fixes.json #2] _(from R4 Contrast on the other grounds, shot z40)_
3. **Standard hooks** (WARN): A1 Standard hooks: Implement set_team_color, set_construction_progress, set_health_ratio, play_destroyed [fixes.json #3] _(from A1 Standard hooks)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.4): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 0.96): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -20 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 5 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 3 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 4 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 7493 (biggest: Body 6857, Essence 598, Fx 38) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 1 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 12 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 1 | no budget for building/hall |  |
| B8 | Unique materials | PASS 100 | 5 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 3 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 4 surfaces over 3 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 393 of 6133 triangles (6%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0032 ms process per instance (8 animated at 40 m: +0.03 ms process, render CPU +0.12 ms, GPU +-1.7 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.1 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 48143 px (329 x 272 bbox; 55 m: 25286 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **FAIL** 2 | mean-colour dE 15.0, 66% of the body melts (within dE 15 of the ground); body L* 54.6 C 35.6 vs ground L* 59.7 C 49.6, hue gap 2 deg; top third (world height) dE 62.3, L* 35.3; per-pixel dE 16.4, outline 2.4 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: value is close to the ground (dL -5): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 2 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4 | Contrast on the other grounds | **WARN** 35 | worst ash: dE 4.4 (heath dE 8.7, old_wood dE 8.5, riverbank dE 10.6, snow dE 11.1, ash dE 4.4, sand dE 12.2, marsh dE 6.9) | dE >= 8 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 83 | worst dL +7 (point 1 dL +22, point 2 dL +10, point 3 dL +7, point 4 dL +12; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/4/4): Essence x4; soft glows under the bloom (v1 count, luma > 0.4): 4 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 92 | max IoU 0.57 (trade_post 0.57, greywater_lodge 0.42) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 42 | missing: set_team_color, set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 204 shapes over 1 body parts (204.0 per part: (root) 204); 75% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.398 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 62% of the 12000 verts budget used (7493) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 70 | 9 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.1 at the close-up (61125 px), 7.49 at 25 m; close-up outline complexity 2.24 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 0 | outline complexity 0.96 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 35.3, bottom third L* 56.1 (-20, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 81 | inner detail 2.2 at 25 m, 3.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 0 | on the autumn floor: dE 10.4, 70% melts; body L* 44.2 C 31.1 vs floor L* 47.2 C 40.2 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 0 | front-view asymmetry 0.01 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body 6857 v / 2 s; Essence 598 v / 1 s; Fx 38 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- fix recipes: colour not computed (no body material with an albedo among 4 drawn materials)
- Fix recipes: 3 in fixes.json (top: R3 Contrast vs ground (meadow): Raise the contrast of the key read on meadow (dE 15.0): value is close to the ground (dL -5): lighten the top / back 15-20 % or )
