# Art Lab scorecard: mirefang

Scene `res://art/units/neutral/mirefang/mirefang.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-26 22:58:22 · lab v1.0

## Result: **PASS** · quality **90 / 100** (previous run 87, +3)

0 FAIL · 0 WARN · 23 PASS · 7 info · 0 skipped · 14 s

## Improve next
1. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (14.2): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Contrast on the other grounds** (PASS): On old_wood the body drops to dE 11.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 35.7): the body sits in the ground's hue (gap 11 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 18 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | PASS 100 | 10 (model says 10) | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 87 | 10 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | PASS 86 | 2440 | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Frill, Merged, Tail, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 6 | no budget for unit/creature |  |
| B13 | Frame cost | PASS 100 | 0.001 ms process per instance (100 animated at 40 m: +0.1 ms process, render CPU +0.83 ms, GPU +-0.11 ms) | <= 0.005 ms per instance (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.5 / z 1.32 m (radius 0.45, from mirefang.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 349 px (27 x 37 bbox; 55 m: 180 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 96 | mean-colour dE 35.7, 0% of the body melts (within dE 15 of the ground); body L* 37.5 C 25.6 vs ground L* 65.0 C 47.3, hue gap 11 deg; per-pixel dE 40.9, outline 32.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 77 | worst old_wood: dE 11.3 (heath dE 17.0, old_wood dE 11.3, riverbank dE 22.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) (px 7) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -6 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.3 m, 1.17 m wide |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.42 (bristleback 0.42, grave_hound 0.4, gloomcap_sprout 0.31, magpie 0.3, tracker 0.27, sapling 0.03) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 52% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 0.52 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 0 | 0 of 1 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 100 | outline complexity 3.12 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 7 | top third L* 35.6, bottom third L* 39.5 (-3) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 19 | inner detail 14.2 at 25 m, 18.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.28 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

