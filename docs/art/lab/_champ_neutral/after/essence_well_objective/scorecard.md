# Art Lab scorecard: essence_well_objective

Scene `res://art/buildings/capture/essence_well/essence_well.tscn` · kind **landmark** / tier **objective** · kingdom neutral · ground meadow · 2026-09-30 14:46:03 · lab v3.1

## Result: **PASS** · quality **87 / 100** (87.2) (previous run 87, +0)

0 FAIL · 0 WARN · 17 PASS · 17 info · 0 skipped · 16 s

## Before / after (vs the run of 2026-09-30 13:17:17 in `docs/art/lab/_champ_neutral/after/essence_well_objective`: quality 87 -> 87, +0)
### What got worse (0)
Nothing got worse.

### Score delta per check (2 changed, 34 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R5c | Glow points stand out (1 m surround) | PASS 83 | PASS 84 | +0.7 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 71 | INFO 71 | +0.5 |

Changed pixels per shot: z40 1.6 %, z55 0.9 %, z25 1.9 %, close 0.7 %, turns 0.6 %, anim 0.5 %, silhouette 0.0 %, lineup 0.1 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.68): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -14 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
4. **Vertex use vs budget** (INFO): Only 31% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 7 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 5 | no budget for landmark/objective |  |
| B2 | Draw instances at rest | PASS 100 | 6 | <= 32 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B4 | Vertices | PASS 100 | 7493 (biggest: Body 6835, Essence 598, Fx 30, Contact 22) | <= 24000 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B6 | Particle systems | INFO | 1 | no budget for landmark/objective |  |
| B6l | Looping particle systems | PASS 100 | 1 (Mist) | <= 3 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B6p | Looping particles alive | INFO | 12 | no budget for landmark/objective |  |
| B7 | Shadow casters | INFO | 1 | no budget for landmark/objective |  |
| B8 | Unique materials | PASS 100 | 5 | <= 10 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B1a | Authored build parts (before the merge) | INFO | 5 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 5 surfaces over 5 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 393 of 6133 triangles (6%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (4 animated at 40 m: +-0.07 ms process, render CPU +0.03 ms, GPU +0.61 ms) | <= 0.05 ms per instance soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.1 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 10380 px (149 x 147 bbox; 55 m: 5334 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 57.5, 0% of the body melts (within dE 15 of the ground); body L* 45.4 C 11.6 vs ground L* 62.0 C 50.0, hue gap n/a (body C* <= 25); top third (world height) dE 62.2, L* 35.4; per-pixel dE 62.1, outline 43.5 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 21.8 (heath dE 29.5, old_wood dE 31.9, riverbank dE 39.8, snow dE 46.3, ash dE 21.8, sand dE 47.1, marsh dE 29.4) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +10 (point 1 dL +21, point 2 dL +12, point 3 dL +15, point 4 dL +10; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/4/4): Fx, Essence x3; soft glows under the bloom (v1 count, luma > 0.4): 4 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 98 | max IoU 0.49 (giant_stump 0.49, colossus 0.42, crag_nest 0.36, aqueduct 0.27, standing_stones 0.23, old_wood_den 0.1) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 201 shapes over 1 body parts (201.0 per part: (root) 201); 47% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.68 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 64 | 31% of the 24000 verts budget used (7463) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.66 at the close-up (58140 px), 3.7 at 25 m; close-up outline complexity 9.58 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.32 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 35.4, bottom third L* 49.6 (-14, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.5 at 25 m, 7.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 71 | on the autumn floor: dE 34.8, 0% melts; body L* 43.0 C 17.3 vs floor L* 49.4 C 41.4 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.31 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12)
`{"lights":0,"n":4,"soft":{"draw":32,"frame_ms":0.05,"looping":3,"materials":10,"verts":24000},"src":"map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12"}`

## Notes
- Per-mesh vertices (biggest first): Body 6835 v / 1 s; Essence 598 v / 1 s; Fx 30 v / 1 s; Contact 22 v / 1 s; FxGround 8 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
