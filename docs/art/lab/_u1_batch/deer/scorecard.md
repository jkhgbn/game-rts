# Art Lab scorecard: deer

Scene `res://art/units/neutral/critters/deer.tscn` · kind **critter** / tier **deer** · kingdom neutral · ground meadow · 2026-09-27 14:12:19 · lab v3.1

## Result: **PASS** · quality **98 / 100** (97.9) (previous run 98, +0)

0 FAIL · 0 WARN · 18 PASS · 16 info · 0 skipped · 17 s

## Improve next
1. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 50.5): raise the value step between the big masses and the ground (dL -28 now) _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Contrast on the other grounds** (PASS): On marsh the body drops to dE 18.0: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

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
| B1 | Meshes after the kit merge | INFO | 1 | no budget for critter/deer |  |
| B2 | Draw instances at rest | PASS 100 | 1 | <= 6 soft (map-fill.md 9 (game critter deer)) |  |
| B4 | Vertices | INFO | 673 | no budget for critter/deer |  |
| B4t | Triangles | PASS 88 | 1134 | <= 1200 (map-fill.md 9 (game critter deer)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (game critter deer)) |  |
| B7 | Shadow casters | INFO | 1 | no budget for critter/deer |  |
| B8 | Unique materials | PASS 94 | 1 | <= 1 (map-fill.md 9 (game critter deer)) |  |
| B1a | Authored build parts (before the merge) | INFO | 1 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 1 surfaces over 1 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 106 of 1134 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (30 animated at 40 m: +-0.0 ms process, render CPU +0.04 ms, GPU +0.09 ms) | <= 0.005 ms per instance soft (map-fill.md 9 (game critter deer)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.47 / z 1.19 m (radius 0.3, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 442 px (26 x 48 bbox; 55 m: 214 px) | >= 25 px (FAIL < 8) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 95 | mean-colour dE 50.5, 16% of the body melts (within dE 15 of the ground); body L* 33.4 C 29.1 vs ground L* 62.1 C 49.1, hue gap 57 deg; top third (world height) dE 25.9, L* 46.2; per-pixel dE 54.4, outline 36.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 7 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 95 | worst marsh: dE 18.0 (heath dE 25.6, old_wood dE 24.6, riverbank dE 42.1, snow dE 56.9, ash dE 22.2, sand dE 47.5, marsh dE 18.0) | dE >= 7 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 0 | 0-1 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 26.3, dL -12 (warm dE 52.8, ice dE 47.0, night dE 26.3, autumn dE 49.2); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 7 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.83 (min 0.78), area kept 98-103% (min 424 px), frame-to-frame IoU min 0.79; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 25 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.15 (ruin_warden 0.15, rabbit 0.01) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | play_idle, play_move, play_flee, play_hit, play_death |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 28 shapes over 1 body parts (28.0 per part: (root) 28); 3% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.872 | craft (lab v3.1): >= 7 separate shapes per body part, <= 30% plain boxes / prisms, normal variety >= 0.86 |  |
| C2 | Vertex use vs budget | INFO 100 | 94% of the 1200 tris budget used (1134) | craft (lab v3.1): a finished model uses >= 80% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 10 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 91 | inner edges per outline px: 0.63 at the close-up (31480 px), 0.8 at 25 m; close-up outline complexity 17.26 | craft (lab v3.1): >= 0.7 inner edge px per outline px at the close-up, >= 0.7 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.67 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 46.2, bottom third L* 18.4 (+27, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.5 at 25 m, 13.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 61 | on the autumn floor: dE 27.7, 9% melts; body L* 35.3 C 41.5 vs floor L* 52.6 C 43.1 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.91 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 (game critter deer))
`{"lights":0,"materials":1,"n":30,"soft":{"draw":6,"frame_ms":0.005,"runtime_mats":0},"src":"map-fill.md 9 (game critter deer)","tris":1200}`

## Notes
- Per-mesh vertices (biggest first): Mesh 673 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
