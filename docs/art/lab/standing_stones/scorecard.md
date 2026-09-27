# Art Lab scorecard: standing_stones

Scene `res://art/environment/landmarks/standing_stones.tscn` · kind **landmark** / tier **landmark** · kingdom neutral · ground meadow · 2026-09-26 23:04:23 · lab v1.0

## Result: **WARN** · quality **94 / 100** (previous run 94, +0)

0 FAIL · 1 WARN · 15 PASS · 7 info · 0 skipped · 13 s

## Improve next
1. **Glow points at 40 m** (WARN): Too many glow points read as noise: merge or dim the small ones (energy 1.5, no halo) _(from R5 Glow points at 40 m, shot glow)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +5 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 34.7): the body sits in the ground's hue (gap 4 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 9 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | INFO | 1 | no budget for landmark/landmark |  |
| B2 | Draw instances at rest | PASS 100 | 1 | <= 24 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B4 | Vertices | PASS 100 | 12435 | <= 20000 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B7 | Shadow casters | INFO | 1 | no budget for landmark/landmark |  |
| B8 | Unique materials | PASS 100 | 3 | <= 6 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (4 animated at 40 m: +-0.34 ms process, render CPU +0.03 ms, GPU +-0.09 ms) | <= 0.05 ms per instance soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.44 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 13179 px (186 x 173 bbox; 55 m: 6853 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 91 | mean-colour dE 34.7, 25% of the body melts (within dE 15 of the ground); body L* 48.6 C 18.4 vs ground L* 61.5 C 50.4, hue gap 4 deg; per-pixel dE 38.4, outline 23.9 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 15.0 (heath dE 15.0, old_wood dE 15.7, riverbank dE 17.3) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) (px 108, 65, 33, 32, 31) | 0-3 (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge or dim the small ones (energy 1.5, no halo) |
| R2 | Distinct from references (black masks) | PASS 98 | max IoU 0.48 (colossus 0.48, giant_stump 0.43, barge 0.25, crag_nest 0.23, aqueduct 0.23, old_wood_den 0.09) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 3 of 5 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 100 | outline complexity 8.67 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 61 | top third L* 50.4, bottom third L* 45.0 (+5) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.9 at 25 m, 7.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.47 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

