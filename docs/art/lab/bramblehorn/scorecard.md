# Art Lab scorecard: bramblehorn

Scene `res://art/units/nature/bramblehorn.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-09-26 23:11:18 · lab v1.0

## Result: **FAIL** · quality **89 / 100** (previous run 89, +0)

1 FAIL · 0 WARN · 24 PASS · 7 info · 0 skipped · 19 s

## Improve next
1. **Authored meshes** (FAIL): Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh _(from B1 Authored meshes)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -2 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.59): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs _(from P1 Silhouette hook, shot silhouette)_
4. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.06): a shoulder banner, a one-sided weapon / shield, a broken horn _(from P2 Asymmetric secondary shape, shot silhouette)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 20.2): value is close to the ground (dL +1): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 15 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.7: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1 | Authored meshes | **FAIL** 0 | 46 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) | Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh |
| B2 | Draw instances at rest | PASS 100 | 7 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 100 | 3705 | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 7 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 19 | no budget for unit/heavy |  |
| B13 | Frame cost | PASS 100 | 0.0005 ms process per instance (100 animated at 40 m: +0.05 ms process, render CPU +0.81 ms, GPU +0.52 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.034 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 1.2 / z 1.74 m (radius 0.7, from bramblehorn.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2600 px (69 x 66 bbox; 55 m: 1350 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 83 | mean-colour dE 20.2, 3% of the body melts (within dE 15 of the ground); body L* 64.1 C 31.2 vs ground L* 62.9 C 48.4, hue gap 15 deg; per-pixel dE 39.5, outline 36.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 77 | worst heath: dE 11.7 (heath dE 11.7, old_wood dE 37.9, riverbank dE 34.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) (px 44, 22, 12) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 52% of body pixels change between kingdom colours (min pair 42%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 4% of the silhouette (gap -10 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.82 m wide |  |
| R2 | Distinct from references (black masks) | PASS 96 | max IoU 0.51 (mossback 0.51, glade_outrider 0.47, ruin_warden 0.41, gloomcap_elder 0.41, bloomtender 0.29, sprigling 0.13) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 43% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 2 of 3 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 22 | outline complexity 1.59 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 13 | top third L* 59.7, bottom third L* 62.4 (-2) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.7 at 25 m, 9.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 23 | front-view asymmetry 0.06 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- 7 materials are built in code (fine when cached per type: see B9)
