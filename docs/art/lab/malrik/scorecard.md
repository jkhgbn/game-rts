# Art Lab scorecard: malrik

Scene `res://art/units/wizards/malrik.tscn` · kind **unit** / tier **wizard** · kingdom shadow · ground meadow · 2026-09-26 22:59:13 · lab v1.0

## Result: **WARN** · quality **90 / 100** (previous run 86, +3)

0 FAIL · 4 WARN · 22 PASS · 8 info · 0 skipped · 22 s

## Improve next
1. **Parts above body_height + 0.4** (WARN): Narrow Merged 1.18 m, StaffMesh 0.35 m, ShardMesh 0.52 m so the HP bar reads over the head _(from R8w Parts above body_height + 0.4)_
2. **Vertices** (WARN): Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces _(from B4 Vertices)_
3. **Looping particle systems** (WARN): Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) _(from B6l Looping particle systems)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.8): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from vessa (IoU 0.74): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Authored meshes | PASS 100 | 10 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 40 | 3632 | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (ShardLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/wizard |  |
| B6l | Looping particle systems | **WARN** 41 | 2 (VoidMotes, ShadowMist) | <= 1 soft (art-units.md 8 (wizard)) | Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/wizard |  |
| B13 | Frame cost | PASS 100 | 0.0009 ms process per instance (100 animated at 40 m: +0.09 ms process, render CPU +1.65 ms, GPU +2.03 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.06 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 45 | head top 2.71 m / body_height 2.0 (x1.36) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 1.18 m, StaffMesh 0.35 m, ShardMesh 0.52 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.75 / z 0.78 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1071 px (34 x 54 bbox; 55 m: 546 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 96.9, 0% of the body melts (within dE 15 of the ground); body L* 40.1 C 46.8 vs ground L* 61.9 C 48.6, hue gap 163 deg; per-pixel dE 102.0, outline 70.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 66.5 (heath dE 66.5, old_wood dE 68.4, riverbank dE 80.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) (px 24, 18) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 74% of body pixels change between kingdom colours (min pair 60%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 4% of the silhouette (gap -12 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R2 | Distinct from references (black masks) | PASS 81 | max IoU 0.74 (vessa 0.74, ysolde 0.65, shadow_knight 0.64, torvald 0.59, ruin_warden 0.51, hollow_stag 0.35) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 35% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 2 of 2 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 100 | outline complexity 3.21 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 51.7, bottom third L* 27.0 (+24) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 55 | inner detail 12.8 at 25 m, 18.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
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
- 4 materials are built in code (fine when cached per type: see B9)
