# Art Lab scorecard: rimeshield

Scene `res://art/units/ice/rimeshield.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-09-26 23:11:17 · lab v1.0

## Result: **FAIL** · quality **89 / 100** (previous run 91, -2)

1 FAIL · 2 WARN · 23 PASS · 6 info · 0 skipped · 18 s

## Improve next
1. **Authored meshes** (FAIL): Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh _(from B1 Authored meshes)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -6 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Authored meshes | **FAIL** 0 | 43 | <= 26 (art-units.md 8, tier3-extras.md 12) | Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 94 | 2038 | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/soldier |  |
| B13 | Frame cost | PASS 99 | 0.0021 ms process per instance (100 animated at 40 m: +0.21 ms process, render CPU +0.79 ms, GPU +0.23 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 50 | head top 2.17 m / body_height 1.7 (x1.28) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.9 / z 0.69 m (radius 0.5, from rimeshield.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 824 px (34 x 41 bbox; 55 m: 415 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 58.0, 0% of the body melts (within dE 15 of the ground); body L* 67.9 C 12.8 vs ground L* 62.8 C 48.0, hue gap 134 deg; per-pixel dE 61.8, outline 50.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 35.5 (heath dE 35.5, old_wood dE 50.5, riverbank dE 50.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s), + 1 glowing surface(s) > 123 px | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 26% of body pixels change between kingdom colours (min pair 17%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.3 m wide |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.65 (tracker 0.65, shardcaster 0.58, frostrune_rifleman 0.55, gloomcap_elder 0.51, rime_seer 0.5, rime_hauler 0.48) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 41% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.03 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 85 | outline complexity 2.41 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 64.5, bottom third L* 70.6 (-6) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.4 at 25 m, 10.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.37 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
