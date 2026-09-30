# Art Lab scorecard: crown_pedestal_objective

Scene `res://art/environment/crown_pedestal.tscn` · kind **landmark** / tier **objective** · kingdom neutral · ground meadow · 2026-09-30 14:45:16 · lab v3.1

## Result: **PASS** · quality **91 / 100** (91.0) (previous run 92, -1)

0 FAIL · 0 WARN · 16 PASS · 18 info · 0 skipped · 31 s

## Before / after (vs the run of 2026-09-30 13:04:22 in `docs/art/lab/_champ_neutral/after/crown_pedestal_objective`: quality 92 -> 91, -1)
### What got worse (1)
1. **P5 Glow placement: INFO 22 -> INFO 0 (-22)**. Now: 0 of 9 glow(s) in the upper half of the model's height (world). Was: 1 of 9 glow(s) in the upper half of the model's height (world)

### Score delta per check (3 changed, 33 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C4 | Inner detail (close-up / 25 m) | INFO 14 | INFO 13 | -0.5 |
| R5c | Glow points stand out (1 m surround) | PASS 92 | PASS 95 | +2.5 (noisy) |
| P5 | Glow placement | INFO 22 | INFO 0 | -22.2 |

Changed pixels per shot: z40 1.5 %, z55 1.1 %, z25 1.5 %, close 0.1 %, turns 0.0 %, anim 0.5 %, silhouette 0.0 %, lineup 0.1 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (1.18 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
2. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
3. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 19.2): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
4. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 31.6): value is close to the ground (dL -2): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the top third (what reads from pitch 55) is close to the ground (dE 7.4): lighten helmets / shoulders / back _(from R3 Contrast vs ground (meadow), shot z40)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 12.7: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 13 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 1 material(s), 0 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 5 | no budget for landmark/objective |  |
| B2 | Draw instances at rest | PASS 100 | 6 | <= 32 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B4 | Vertices | PASS 100 | 14517 (biggest: Stone 7032, RuinDressing 5808, Runes 1548, Beacon 125) | <= 24000 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B6 | Particle systems | INFO | 2 | no budget for landmark/objective |  |
| B6l | Looping particle systems | PASS 100 | 1 (Embers) | <= 3 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B6p | Looping particles alive | INFO | 22 | no budget for landmark/objective |  |
| B7 | Shadow casters | INFO | 2 | no budget for landmark/objective |  |
| B8 | Unique materials | PASS 87 | 10 | <= 10 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B1a | Authored build parts (before the merge) | INFO | 9 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 7 surfaces over 5 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 743 of 4990 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0015 ms process per instance (4 animated at 40 m: +0.01 ms process, render CPU +0.02 ms, GPU +0.05 ms) | <= 0.05 ms per instance soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 25248 px (505 x 437 bbox; 55 m: 12709 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 94 | mean-colour dE 31.6, 18% of the body melts (within dE 15 of the ground); body L* 57.3 C 16.4 vs ground L* 59.7 C 45.8, hue gap n/a (body C* <= 25); top third (world height) dE 7.4, L* 66.9; per-pixel dE 38.5, outline 33.5 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 94 | worst heath: dE 12.7 (heath dE 12.7, old_wood dE 26.8, riverbank dE 27.8, snow dE 26.8, ash dE 27.7, sand dE 26.6, marsh dE 32.4) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +25 (point 1 dL +25, point 2 dL +49, point 3 dL +44, point 4 dL +38, point 5 dL +33, point 6 dL +30, point 7 dL +27, point 8 dL +45, point 9 dL +27; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 9 point(s) above the bloom level 1.2 (median of 9/9/8): Beacon x7, Runes x2, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 10 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.29 (giant_stump 0.29, aqueduct 0.28, colossus 0.27, crag_nest 0.18, standing_stones 0.13, old_wood_den 0.07) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 159 shapes over 1 body parts (159.0 per part: (root) 159); 39% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.851 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 60% of the 24000 verts budget used (14513) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 18 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 13 | inner edges per outline px: 1.18 at the close-up (10750 px), 1.55 at 25 m; close-up outline complexity 23.56 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 27.69 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 66.9, bottom third L* 52.6 (+14, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 5.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 9 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 30 | on the autumn floor: dE 19.2, 19% melts; body L* 52.5 C 22.5 vs floor L* 47.3 C 40.8 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.6 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Stone 7032 v / 2 s; RuinDressing 5808 v / 1 s; Runes 1548 v / 2 s; Beacon 125 v / 1 s; GroundGlow 4 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
