# Art Lab scorecard: ysolde

Scene `res://art/units/wizards/ysolde.tscn` · kind **unit** / tier **wizard** · kingdom nature · ground meadow · 2026-09-26 23:00:24 · lab v1.0

## Result: **WARN** · quality **88 / 100** (previous run 83, +4)

0 FAIL · 4 WARN · 22 PASS · 8 info · 0 skipped · 23 s

## Improve next
1. **Parts above body_height + 0.4** (WARN): Narrow HeadGlow 1.65 m, Merged 1.77 m, StaffMesh 0.63 m so the HP bar reads over the head _(from R8w Parts above body_height + 0.4)_
2. **Vertices** (WARN): Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces _(from B4 Vertices)_
3. **Looping particle systems** (WARN): Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) _(from B6l Looping particle systems)_
4. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 21.2): value is close to the ground (dL -1): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 9 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from vessa (IoU 0.7): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | PASS 100 | 11 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 7715 | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (SeedLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/wizard |  |
| B6l | Looping particle systems | **WARN** 41 | 2 (CrownPetals, SeedMotes) | <= 1 soft (art-units.md 8 (wizard)) | Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/wizard |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.05 ms process, render CPU +1.67 ms, GPU +3.29 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.014 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 49 | head top 2.59 m / body_height 2.0 (x1.3) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | HeadGlow 1.65 m, Merged 1.77 m, StaffMesh 0.63 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.98 / z 0.85 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1414 px (46 x 62 bbox; 55 m: 731 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 83 | mean-colour dE 21.2, 1% of the body melts (within dE 15 of the ground); body L* 59.9 C 28.7 vs ground L* 61.9 C 48.9, hue gap 9 deg; per-pixel dE 46.2, outline 42.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 77 | worst heath: dE 11.2 (heath dE 11.2, old_wood dE 32.7, riverbank dE 30.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) (px 120, 78, 6) | 1-3 (art-units 1.4 / art-keep 0.4) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 41% of body pixels change between kingdom colours (min pair 34%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -17 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R2 | Distinct from references (black masks) | PASS 83 | max IoU 0.7 (vessa 0.7, ruin_warden 0.5, gloomcap_elder 0.46, bramblehorn 0.4, glade_outrider 0.4, mossback 0.27) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 67 | 1 of 3 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 100 | outline complexity 5.87 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 85.3, bottom third L* 35.0 (+50) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.8 at 25 m, 13.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 89 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- 3 materials are built in code (fine when cached per type: see B9)
