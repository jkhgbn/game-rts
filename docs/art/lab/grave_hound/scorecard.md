# Art Lab scorecard: grave_hound

Scene `res://art/units/shadow/grave_hound.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-09-26 23:02:09 · lab v1.0

## Result: **PASS** · quality **94 / 100** (previous run 94, +0)

0 FAIL · 0 WARN · 23 PASS · 6 info · 0 skipped · 6 s

## Improve next
1. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (16.5): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | PASS 93 | 22 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1295 | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 9 | no budget for unit/soldier |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.24 / z 0.99 m (radius 0.4, from grave_hound.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 325 px (26 x 35 bbox; 55 m: 168 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 65.4, 0% of the body melts (within dE 15 of the ground); body L* 46.6 C 17.9 vs ground L* 65.0 C 46.4, hue gap 152 deg; per-pixel dE 76.0, outline 49.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 98 | worst heath: dE 28.4 (heath dE 28.4, old_wood dE 43.2, riverbank dE 52.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) (px 14, 8) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 34% of body pixels change between kingdom colours (min pair 23%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -6 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.5 m, 1.04 m wide |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 0.52 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 1 of 2 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 100 | outline complexity 3.07 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 7 | top third L* 53.9, bottom third L* 57.8 (-3) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 16.5 at 25 m, 25.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- 1 hidden parts at rest (toggled states, not counted as draws)
- quick=1: references (R2) and frame cost (B13) skipped
