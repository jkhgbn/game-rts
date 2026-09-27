# Art Lab scorecard: dusk_steed

Scene `res://art/units/mounts/dusk_steed/dusk_steed.tscn` · kind **mount** / tier **mount** · kingdom shadow · ground meadow · 2026-09-26 21:53:31 · lab v1.0

## Result: **PASS** · quality **98 / 100** (previous run 96, +3)

0 FAIL · 0 WARN · 20 PASS · 7 info · 0 skipped · 20 s

## Improve next
1. **Distinct from references (black masks)** (PASS): Make it read apart from roan_courser (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
2. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_
3. **Detail density at 25 m** (IDEA): Add 1-2 mid-size value accents (trim band, belt, plate edge, markings) that read at 25 m and merge into the big mass at 40 m _(from shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 19 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | PASS 100 | 8 (model says 10) | <= 12 (cavalry-mounts.md 10 (mount)) |  |
| B2 | Draw instances at rest | PASS 88 | 8 | <= 8 (cavalry-mounts.md 10 (mount)) |  |
| B4 | Vertices | PASS 87 | 5769 | <= 6000 soft (cavalry-mounts.md 10 (mount)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (mount)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (cavalry-mounts.md 10 (mount)) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 2 soft (cavalry-mounts.md 10 (mount)) |  |
| B8 | Unique materials | INFO | 12 | no budget for mount/mount |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (50 animated at 40 m: +-0.07 ms process, render CPU +0.29 ms, GPU +0.14 ms) | <= 0.005 ms per instance (cavalry-mounts.md 10 (mount)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.4 / z 1.55 m (radius 0.7, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 803 px (40 x 53 bbox; 55 m: 409 px) | >= 150 px (FAIL < 60) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 98.9, 0% of the body melts (within dE 15 of the ground); body L* 20.4 C 41.4 vs ground L* 62.2 C 48.7, hue gap 167 deg; per-pixel dE 102.1, outline 74.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst old_wood: dE 61.5 (heath dE 65.8, old_wood dE 61.5, riverbank dE 75.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) (px 6, 3) | 0-2 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 57% of body pixels change between kingdom colours (min pair 38%) | >= 2% (FAIL = set_team_color changes nothing) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.67 (roan_courser 0.67, grove_stag 0.55, ember_boar 0.47, rimehorn 0.4, grizzlemaw 0.35, tusker 0.34) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 8 present | set_team_color, set_moving, play_hit, play_death, signal:death_finished, set_barded, play_charge, seat_transform |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 1 of 2 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 100 | outline complexity 3.92 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 25.4, bottom third L* 12.4 (+13) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.5 at 25 m, 12.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.27 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (mount))
`{"draw":8,"frame_ms":0.005,"lights":0,"meshes":12,"n":50,"runtime_mats":0,"soft":{"casters":2,"looping":1,"verts":6000},"src":"cavalry-mounts.md 10 (mount)"}`

