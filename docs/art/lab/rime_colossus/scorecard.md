# Art Lab scorecard: rime_colossus

Scene `res://art/units/ice/rime_colossus.tscn` · kind **unit** / tier **heavy** · kingdom ice · ground meadow · 2026-09-26 23:10:01 · lab v1.0

## Result: **FAIL** · quality **90 / 100** (previous run 89, +1)

1 FAIL · 1 WARN · 24 PASS · 7 info · 0 skipped · 18 s

## Improve next
1. **Authored meshes** (FAIL): Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh _(from B1 Authored meshes)_
2. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.17): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs _(from P1 Silhouette hook, shot silhouette)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from ruin_warden (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +8 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 18% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | **FAIL** 0 | 52 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) | Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 100 | 2311 | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 5 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/heavy |  |
| B13 | Frame cost | PASS 100 | 0.0011 ms process per instance (100 animated at 40 m: +0.11 ms process, render CPU +0.79 ms, GPU +0.1 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 95 | head top 2.38 m / body_height 2.6 (x0.91) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.42 / z 1.14 m (radius 0.8, from rime_colossus.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 2498 px (59 x 72 bbox; 55 m: 1291 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 62.1, 0% of the body melts (within dE 15 of the ground); body L* 62.2 C 17.0 vs ground L* 61.3 C 49.4, hue gap 132 deg; per-pixel dE 65.1, outline 48.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 44.6 (heath dE 44.6, old_wood dE 49.3, riverbank dE 48.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) (px 29), + 1 glowing surface(s) > 374 px | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 92 | 18% of body pixels change between kingdom colours (min pair 3%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 7% of the silhouette (gap -18 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 2.08 m wide |  |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (ruin_warden 0.63, rimeshield 0.33, hollow_stag 0.31, rime_seer 0.26, shardcaster 0.22, frostrune_rifleman 0.22) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 0 | 0 of 1 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 67 | outline complexity 2.17 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 78 | top third L* 67.6, bottom third L* 59.3 (+8) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.3 at 25 m, 7.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.33 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- 1 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
