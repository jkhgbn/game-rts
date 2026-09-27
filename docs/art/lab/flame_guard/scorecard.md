# Art Lab scorecard: flame_guard

Scene `res://art/units/fire/flame_guard.tscn` · kind **unit** / tier **soldier** · kingdom fire · ground meadow · 2026-09-26 22:54:33 · lab v1.0

## Result: **WARN** · quality **94 / 100**

0 FAIL · 1 WARN · 23 PASS · 6 info · 0 skipped · 7 s

## Improve next
1. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +1 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.04): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs _(from P1 Silhouette hook, shot silhouette)_
3. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.4): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

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
| B1 | Authored meshes | PASS 97 | 20 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1702 | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 9 | no budget for unit/soldier |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.053 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 86 | head top 1.98 m / body_height 1.6 (x1.24) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.86 / z 0.85 m (radius 0.45, from flame_guard.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 951 px (38 x 42 bbox; 55 m: 479 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 60.4, 0% of the body melts (within dE 15 of the ground); body L* 63.6 C 64.2 vs ground L* 63.1 C 48.1, hue gap 63 deg; per-pixel dE 61.9, outline 55.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 51.4 (heath dE 51.4, old_wood dE 66.6, riverbank dE 77.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) (px 47, 11) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 66% of body pixels change between kingdom colours (min pair 58%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 52% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 0.52 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 1 of 2 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 57 | outline complexity 2.04 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 41 | top third L* 65.0, bottom third L* 63.1 (+1) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 84 | inner detail 2.4 at 25 m, 3.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

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
