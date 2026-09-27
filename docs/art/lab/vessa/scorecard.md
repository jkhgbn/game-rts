# Art Lab scorecard: vessa

Scene `res://art/units/wizards/vessa.tscn` · kind **unit** / tier **wizard** · kingdom fire · ground meadow · 2026-09-26 22:57:21 · lab v1.0

## Result: **WARN** · quality **89 / 100** (previous run 89, +0)

0 FAIL · 3 WARN · 23 PASS · 8 info · 0 skipped · 22 s

## Improve next
1. **Parts above body_height + 0.4** (WARN): Narrow CrownFlames 0.63 m, Merged 0.45 m, Orb 0.41 m, Merged 0.46 m so the HP bar reads over the head _(from R8w Parts above body_height + 0.4)_
2. **Vertices** (WARN): Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces _(from B4 Vertices)_
3. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from malrik (IoU 0.72): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Frame cost** (PASS): Cut the per-frame script cost (0.0033 ms per instance): write pivots only when they change, skip work at the far tiers _(from B13 Frame cost)_

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
| B1 | Authored meshes | PASS 100 | 12 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 37 | 3795 | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (OrbLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (EmberMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 14 | no budget for unit/wizard |  |
| B13 | Frame cost | PASS 93 | 0.0033 ms process per instance (100 animated at 40 m: +0.33 ms process, render CPU +1.36 ms, GPU +1.28 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.013 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 37 | head top 2.94 m / body_height 2.0 (x1.47) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | CrownFlames 0.63 m, Merged 0.45 m, Orb 0.41 m, Merged 0.46 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.75 / z 0.71 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1329 px (37 x 55 bbox; 55 m: 679 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 67.1, 0% of the body melts (within dE 15 of the ground); body L* 58.1 C 63.8 vs ground L* 61.7 C 48.8, hue gap 71 deg; per-pixel dE 73.8, outline 61.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 50.4 (heath dE 50.4, old_wood dE 66.9, riverbank dE 78.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) (px 25), + 1 glowing surface(s) > 199 px | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 73% of body pixels change between kingdom colours (min pair 64%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R2 | Distinct from references (black masks) | PASS 82 | max IoU 0.72 (malrik 0.72, ysolde 0.69, torvald 0.68, ruin_warden 0.56, ash_hurler 0.48, hollow_stag 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 99 | strike pose changes 28% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 0 | 0 of 1 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 75 | outline complexity 2.28 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 68.2, bottom third L* 46.4 (+21) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.6 at 25 m, 10.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.22 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (wizard))
`{"draw":16,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
