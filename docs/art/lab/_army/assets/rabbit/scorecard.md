# Art Lab scorecard: rabbit

Scene `res://art/units/neutral/critters/rabbit.tscn` · kind **critter** / tier **rabbit** · kingdom neutral · ground meadow · 2026-09-27 10:27:51 · lab v2.0

## Result: **PASS** · quality **93 / 100**

0 FAIL · 0 WARN · 15 PASS · 10 info · 0 skipped · 13 s

## Improve next
1. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.05): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
2. **Contrast on the other grounds** (PASS): On heath the body drops to dE 8.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
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

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.17 / z 0.34 m (radius 0.3, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 88 px (11 x 11 bbox; 55 m: 44 px) | >= 25 px (FAIL < 8) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 39.3, 5% of the body melts (within dE 15 of the ground); body L* 51.1 C 19.9 vs ground L* 64.1 C 47.7, hue gap n/a (body C* <= 25); top third (world height) dE 28.5, L* 53.1; per-pixel dE 40.8, outline 33.7 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 7 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 78 | worst heath: dE 8.5 (heath dE 8.5, old_wood dE 26.3, riverbank dE 38.7, snow dE 40.9, ash dE 29.8, sand dE 32.6, marsh dE 32.8) | dE >= 7 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 0 | 0-1 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.78 (min 0.69), area kept 100-115% (min 75 px), frame-to-frame IoU min 0.66; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 25 px (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | play_idle, play_move, play_flee, play_hit, play_death |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 0 | outline complexity 1.05 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 53.1, bottom third L* 40.3 (+12, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.7 at 25 m, 10.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 (game critter rabbit))
`{"lights":0,"materials":1,"n":30,"soft":{"draw":6,"frame_ms":0.005,"runtime_mats":0},"src":"map-fill.md 9 (game critter rabbit)","tris":300}`

## Notes
- Per-mesh vertices (biggest first): Mesh 183 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
