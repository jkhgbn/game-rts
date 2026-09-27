# Art Lab scorecard: plant_float_deer

Scene `res://tools/art_lab/calibration/virtual/plant_float_deer.tscn` · kind **critter** / tier **deer** · kingdom neutral · ground meadow · 2026-09-27 10:30:43 · lab v2.0

## Result: **FAIL** · quality **91 / 100**

1 FAIL · 0 WARN · 14 PASS · 10 info · 0 skipped · 12 s

## Improve next
1. **Feet on the ground** (FAIL): R9: move `Root` 0.4 m down (lowest point 0.4 -> 0.0 m) [fixes.json #1] _(from R9 Feet on the ground)_
2. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 53.2): raise the value step between the big masses and the ground (dL -28 now) _(from R3 Contrast vs ground (meadow), shot z40)_
3. **Contrast on the other grounds** (PASS): On marsh the body drops to dE 17.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 3 nodes | instantiates without errors |  |
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

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | **FAIL** 0 | lowest point 0.4 m | -0.08 .. +0.05 m (art-units 1.6) | Lower the feet: the model floats 0.4 m above the ground |
| R10 | Footprint vs selection radius | INFO | x 0.47 / z 1.19 m (radius 0.3, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 463 px (25 x 51 bbox; 55 m: 220 px) | >= 25 px (FAIL < 8) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 95 | mean-colour dE 53.2, 15% of the body melts (within dE 15 of the ground); body L* 31.2 C 28.8 vs ground L* 59.8 C 49.9, hue gap 62 deg; top third (world height) dE 28.4, L* 43.4; per-pixel dE 57.0, outline 42.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 7 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 94 | worst marsh: dE 17.5 (heath dE 29.2, old_wood dE 25.5, riverbank dE 43.1, snow dE 59.0, ash dE 22.2, sand dE 49.5, marsh dE 17.5) | dE >= 7 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 0 | 0-1 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.83 (min 0.77), area kept 99-105% (min 434 px), frame-to-frame IoU min 0.8; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 25 px (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | play_idle, play_move, play_flee, play_hit, play_death |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.97 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 43.4, bottom third L* 12.2 (+31, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.6 at 25 m, 10.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 (game critter deer))
`{"lights":0,"materials":1,"n":30,"soft":{"draw":6,"frame_ms":0.005,"runtime_mats":0},"src":"map-fill.md 9 (game critter deer)","tris":1200}`

## Notes
- Per-mesh vertices (biggest first): Mesh 673 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 1 in fixes.json (top: R9: move `Root` 0.4 m down (lowest point 0.4 -> 0.0 m))
