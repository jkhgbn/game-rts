# Art Lab scorecard: rabbit

Scene `res://art/units/neutral/critters/rabbit.tscn` · kind **critter** / tier **rabbit** · kingdom neutral · ground meadow · 2026-10-15 13:34:20 · lab v3.1

## Result: **PASS** · quality **84 / 100** (84.0)

0 FAIL · 0 WARN · 18 PASS · 16 info · 0 skipped · 15 s

## Improve next
1. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (0.37 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
2. **Palette depth (close-up)** (INFO): Flat palette (7 colour / 4 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 0.89): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +2 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Contrast on the other grounds** (PASS): On snow the body drops to dE 8.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 21.0): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 2 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 1 | no budget for critter/rabbit |  |
| B2 | Draw instances at rest | PASS 100 | 1 | <= 6 soft (map-fill.md 9 (game critter rabbit)) |  |
| B4 | Vertices | INFO | 183 | no budget for critter/rabbit |  |
| B4t | Triangles | PASS 86 | 297 | <= 300 (map-fill.md 9 (game critter rabbit)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (game critter rabbit)) |  |
| B7 | Shadow casters | INFO | 1 | no budget for critter/rabbit |  |
| B8 | Unique materials | PASS 94 | 1 | <= 1 (map-fill.md 9 (game critter rabbit)) |  |
| B1a | Authored build parts (before the merge) | INFO | 1 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 1 surfaces over 1 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 36 of 297 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (30 animated at 40 m: +-0.0 ms process, render CPU +0.05 ms, GPU +0.01 ms) | <= 0.005 ms per instance soft (map-fill.md 9 (game critter rabbit)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.17 / z 0.34 m (radius 0.3, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 70 px (8 x 12 bbox; 55 m: 34 px) | >= 25 px (FAIL < 8) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 45.8, 0% of the body melts (within dE 15 of the ground); body L* 83.8 C 7.7 vs ground L* 65.0 C 47.9, hue gap n/a (body C* <= 25); top third (world height) dE 45.9, L* 85.7; per-pixel dE 46.0, outline 43.4 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 7 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 77 | worst snow: dE 8.2 (heath dE 33.5, old_wood dE 56.8, riverbank dE 58.9, snow dE 8.2, ash dE 60.7, sand dE 25.2, marsh dE 67.6) | dE >= 7 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 1 | 0-1 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 32.7, dL -5 (warm dE 41.5, ice dE 40.8, night dE 32.7, autumn dE 38.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 7 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.71), area kept 98-115% (min 74 px), frame-to-frame IoU min 0.65; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 25 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.08 (deer 0.08, ruin_warden 0.06) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | play_idle, play_move, play_flee, play_hit, play_death |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 85 | 13 shapes over 1 body parts (13.0 per part: (root) 13); 7% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.842 | craft (lab v3.1): >= 7 separate shapes per body part, <= 30% plain boxes / prisms, normal variety >= 0.86 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 300 tris budget used (297) | craft (lab v3.1): a finished model uses >= 80% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 20 | 7 colour steps (L*a*b* bins >= 2 % of the body), 4 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 10 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 9 | inner edges per outline px: 0.37 at the close-up (51218 px), 0.19 at 25 m; close-up outline complexity 3.44 | craft (lab v3.1): >= 0.7 inner edge px per outline px at the close-up, >= 0.7 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 0 | outline complexity 0.89 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 42 | top third L* 84.8, bottom third L* 82.8 (+2, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 4.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 35 | on the autumn floor: dE 21.0, 8% melts; body L* 47.9 C 27.2 vs floor L* 53.4 C 43.7 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.83 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 (game critter rabbit))
`{"lights":0,"materials":1,"n":30,"soft":{"draw":6,"frame_ms":0.005,"runtime_mats":0},"src":"map-fill.md 9 (game critter rabbit)","tris":300}`

## Notes
- Per-mesh vertices (biggest first): Mesh 183 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
