# Art Lab scorecard: gloom_thrall

Scene `res://art/units/shadow/gloom_thrall.tscn` · kind **unit** / tier **worker** · kingdom shadow · ground meadow · 2026-09-26 22:54:13 · lab v1.0

## Result: **WARN** · quality **96 / 100**

0 FAIL · 1 WARN · 22 PASS · 6 info · 0 skipped · 7 s

## Improve next
1. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.93): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs _(from P1 Silhouette hook, shot silhouette)_
2. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_
3. **Detail density at 25 m** (IDEA): Add 1-2 mid-size value accents (trim band, belt, plate edge, markings) that read at 25 m and merge into the big mass at 40 m _(from shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 27 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | PASS 86 | 22 | <= 22 (art-units.md 8) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8) |  |
| B4 | Vertices | PASS 100 | 1171 | <= 2500 (art-units.md 8) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/worker |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 0 soft (art-units.md 8) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8) |  |
| B8 | Unique materials | INFO | 13 | no budget for unit/worker |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.008 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 99 | head top 1.38 m / body_height 1.4 (x0.99) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.74 / z 0.5 m (radius 0.4, from gloom_thrall.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 420 px (30 x 34 bbox; 55 m: 211 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 89.9, 0% of the body melts (within dE 15 of the ground); body L* 45.1 C 42.0 vs ground L* 63.5 C 48.0, hue gap 155 deg; per-pixel dE 92.8, outline 70.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 45.8 (heath dE 45.8, old_wood dE 63.9, riverbank dE 75.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) (px 13, 10) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 58% of body pixels change between kingdom colours (min pair 56%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -4 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 60% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 0.52 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 1 of 2 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 49 | outline complexity 1.93 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 54.6, bottom third L* 41.2 (+13) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.4 at 25 m, 12.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":22,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":0,"separate":6},"src":"art-units.md 8","verts":2500}`

## Notes
- 3 hidden parts at rest (toggled states, not counted as draws)
- quick=1: references (R2) and frame cost (B13) skipped
