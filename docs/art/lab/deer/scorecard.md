# Art Lab scorecard: deer

Scene `res://art/units/neutral/critters/deer.tscn` · kind **critter** / tier **deer** · kingdom neutral · ground meadow · 2026-09-26 21:57:44 · lab v1.0

## Result: **PASS** · quality **98 / 100**

0 FAIL · 0 WARN · 16 PASS · 8 info · 0 skipped · 10 s

## Improve next
1. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.3): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
2. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_
3. **Detail density at 25 m** (IDEA): Add 1-2 mid-size value accents (trim band, belt, plate edge, markings) that read at 25 m and merge into the big mass at 40 m _(from shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 2 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | INFO | 1 | no budget for critter/deer |  |
| B2 | Draw instances at rest | PASS 100 | 1 | <= 6 soft (map-fill.md 9 (game critter deer)) |  |
| B4 | Vertices | INFO | 673 | no budget for critter/deer |  |
| B4t | Triangles | PASS 88 | 1134 | <= 1200 (map-fill.md 9 (game critter deer)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (game critter deer)) |  |
| B7 | Shadow casters | INFO | 1 | no budget for critter/deer |  |
| B8 | Unique materials | PASS 94 | 1 | <= 1 (map-fill.md 9 (game critter deer)) |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (30 animated at 40 m: +-0.0 ms process, render CPU +-0.23 ms, GPU +-0.01 ms) | <= 0.005 ms per instance soft (map-fill.md 9 (game critter deer)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.47 / z 1.19 m (radius 0.3, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 430 px (27 x 47 bbox; 55 m: 220 px) | >= 25 px (FAIL < 8) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 98 | mean-colour dE 51.1, 10% of the body melts (within dE 15 of the ground); body L* 40.2 C 35.1 vs ground L* 62.4 C 49.0, hue gap 63 deg; per-pixel dE 57.0, outline 48.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 7 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 25.7 (heath dE 25.7, old_wood dE 31.5, riverbank dE 48.2) | dE >= 7 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) | 0-1 (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.15 (ruin_warden 0.15, rabbit 0.01) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | play_idle, play_move, play_flee, play_hit, play_death |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.39 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 47.1, bottom third L* 25.7 (+21) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 68 | inner detail 12.3 at 25 m, 18.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
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

