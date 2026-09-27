# Art Lab scorecard: torvald

Scene `res://art/units/wizards/torvald.tscn` · kind **unit** / tier **wizard** · kingdom ice · ground meadow · 2026-09-26 22:57:43 · lab v1.0

## Result: **WARN** · quality **92 / 100** (previous run 92, +0)

0 FAIL · 3 WARN · 23 PASS · 7 info · 0 skipped · 23 s

## Improve next
1. **Parts above body_height + 0.4** (WARN): Narrow Merged 0.81 m, StaffMesh 0.55 m, Flake 0.59 m so the HP bar reads over the head _(from R8w Parts above body_height + 0.4)_
2. **Vertices** (WARN): Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces _(from B4 Vertices)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from vessa (IoU 0.68): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 29 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | PASS 100 | 10 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 100 | 11 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 4596 | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (OrbLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 6 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (SnowMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 19 | no budget for unit/wizard |  |
| B13 | Frame cost | PASS 95 | 0.003 ms process per instance (100 animated at 40 m: +0.3 ms process, render CPU +1.72 ms, GPU +1.9 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.001 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 46 | head top 2.8 m / body_height 2.1 (x1.33) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.81 m, StaffMesh 0.55 m, Flake 0.59 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.94 / z 0.78 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1756 px (45 x 69 bbox; 55 m: 913 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 58.7, 0% of the body melts (within dE 15 of the ground); body L* 78.0 C 9.7 vs ground L* 62.5 C 48.4, hue gap 145 deg; per-pixel dE 63.0, outline 43.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 41.8 (heath dE 41.8, old_wood dE 58.0, riverbank dE 56.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s), + 1 glowing surface(s) > 263 px | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 36% of body pixels change between kingdom colours (min pair 30%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -20 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.6 m, 1.17 m wide |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.68 (vessa 0.68, ysolde 0.64, malrik 0.6, ruin_warden 0.57, rime_colossus 0.49, hollow_stag 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.5 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 90.4, bottom third L* 69.7 (+20) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.3 at 25 m, 8.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
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
- 6 materials are built in code (fine when cached per type: see B9)
