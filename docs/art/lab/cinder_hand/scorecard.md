# Art Lab scorecard: cinder_hand

Scene `res://art/units/fire/cinder_hand.tscn` · kind **unit** / tier **worker** · kingdom fire · ground meadow · 2026-09-26 23:01:50 · lab v1.0

## Result: **PASS** · quality **97 / 100** (previous run 95, +2)

0 FAIL · 0 WARN · 23 PASS · 6 info · 0 skipped · 7 s

## Improve next
1. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.16): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs _(from P1 Silhouette hook, shot silhouette)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +9 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 23.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | PASS 86 | 22 | <= 22 (art-units.md 8) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8) |  |
| B4 | Vertices | PASS 100 | 1318 | <= 2500 (art-units.md 8) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/worker |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 0 soft (art-units.md 8) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8) |  |
| B8 | Unique materials | INFO | 13 | no budget for unit/worker |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.006 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 94 | head top 1.54 m / body_height 1.4 (x1.1) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.67 / z 0.69 m (radius 0.4, from cinder_hand.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 612 px (26 x 39 bbox; 55 m: 316 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 50.5, 0% of the body melts (within dE 15 of the ground); body L* 47.1 C 36.4 vs ground L* 62.8 C 48.3, hue gap 67 deg; per-pixel dE 63.8, outline 51.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 92 | worst heath: dE 23.9 (heath dE 23.9, old_wood dE 37.9, riverbank dE 53.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) (px 19) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 36% of body pixels change between kingdom colours (min pair 30%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 4% of the silhouette (gap -8 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 57% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 0.52 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 1 of 1 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 66 | outline complexity 2.16 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 84 | top third L* 44.9, bottom third L* 35.7 (+9) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.7 at 25 m, 15.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

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
- 1 hidden parts at rest (toggled states, not counted as draws)
- quick=1: references (R2) and frame cost (B13) skipped
