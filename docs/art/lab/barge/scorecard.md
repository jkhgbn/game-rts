# Art Lab scorecard: barge

Scene `res://art/environment/landmarks/barge.tscn` · kind **landmark** / tier **landmark** · kingdom neutral · ground meadow · 2026-09-26 22:53:15 · lab v1.0

## Result: **PASS** · quality **95 / 100**

0 FAIL · 0 WARN · 16 PASS · 6 info · 0 skipped · 12 s

## Improve next
1. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +0 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
2. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 28.2): the body sits in the ground's hue (gap 17 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
3. **Contrast on the other grounds** (PASS): On old_wood the body drops to dE 10.7: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 2 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | INFO | 1 | no budget for landmark/landmark |  |
| B2 | Draw instances at rest | PASS 100 | 1 | <= 24 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B4 | Vertices | PASS 100 | 4648 | <= 20000 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B7 | Shadow casters | INFO | 1 | no budget for landmark/landmark |  |
| B8 | Unique materials | PASS 100 | 1 | <= 6 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (4 animated at 40 m: +-0.39 ms process, render CPU +0.01 ms, GPU +-0.08 ms) | <= 0.05 ms per instance soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -2.19 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 8300 px (151 x 123 bbox; 55 m: 4377 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 85 | mean-colour dE 28.2, 37% of the body melts (within dE 15 of the ground); body L* 48.2 C 28.6 vs ground L* 63.0 C 49.8, hue gap 17 deg; per-pixel dE 31.9, outline 20.7 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 89 | worst old_wood: dE 10.7 (heath dE 14.2, old_wood dE 10.7, riverbank dE 18.8) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) | 0-3 (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 99 | max IoU 0.47 (giant_stump 0.47, colossus 0.41, crag_nest 0.27, standing_stones 0.25, aqueduct 0.19, old_wood_den 0.07) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.37 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 30 | top third L* 43.6, bottom third L* 43.5 (+0) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.3 at 25 m, 8.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.68 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 (emission only, shadows allowed); counts = lab defaults)
`{"lights":0,"n":4,"soft":{"draw":24,"frame_ms":0.05,"looping":2,"materials":6,"verts":20000},"src":"map-fill.md 9 (emission only, shadows allowed); counts = lab defaults"}`

