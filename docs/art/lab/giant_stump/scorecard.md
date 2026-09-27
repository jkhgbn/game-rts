# Art Lab scorecard: giant_stump

Scene `res://art/environment/landmarks/giant_stump.tscn` · kind **landmark** / tier **landmark** · kingdom neutral · ground meadow · 2026-09-26 22:57:47 · lab v1.0

## Result: **PASS** · quality **91 / 100**

0 FAIL · 0 WARN · 16 PASS · 6 info · 0 skipped · 14 s

## Improve next
1. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.37): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs _(from P1 Silhouette hook, shot silhouette)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +1 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from colossus (IoU 0.8): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 30.8): the body sits in the ground's hue (gap 23 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
5. **Contrast on the other grounds** (PASS): On old_wood the body drops to dE 12.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 4 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | INFO | 1 | no budget for landmark/landmark |  |
| B2 | Draw instances at rest | PASS 100 | 1 | <= 24 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B4 | Vertices | PASS 100 | 7124 | <= 20000 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B7 | Shadow casters | INFO | 1 | no budget for landmark/landmark |  |
| B8 | Unique materials | PASS 100 | 2 | <= 6 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (4 animated at 40 m: +-0.47 ms process, render CPU +0.03 ms, GPU +0.07 ms) | <= 0.05 ms per instance soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 18000 px (180 x 163 bbox; 55 m: 9427 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 88 | mean-colour dE 30.8, 30% of the body melts (within dE 15 of the ground); body L* 45.4 C 29.8 vs ground L* 62.1 C 50.2, hue gap 23 deg; per-pixel dE 36.9, outline 12.7 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 94 | worst old_wood: dE 12.5 (heath dE 14.7, old_wood dE 12.5, riverbank dE 22.0) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) | 0-3 (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 77 | max IoU 0.8 (colossus 0.8, barge 0.47, standing_stones 0.43, crag_nest 0.37, aqueduct 0.28, old_wood_den 0.16) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 5 | outline complexity 1.37 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 39 | top third L* 50.3, bottom third L* 48.7 (+1) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.0 at 25 m, 5.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 82 | front-view asymmetry 0.17 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

