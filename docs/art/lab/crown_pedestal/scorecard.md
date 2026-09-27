# Art Lab scorecard: crown_pedestal

Scene `res://art/environment/crown_pedestal.tscn` · kind **landmark** / tier **landmark** · kingdom neutral · ground meadow · 2026-09-26 23:00:56 · lab v1.0

## Result: **WARN** · quality **87 / 100** (previous run 87, +0)

0 FAIL · 2 WARN · 13 PASS · 10 info · 0 skipped · 32 s

## Improve next
1. **Glow points at 40 m** (WARN): Too many glow points read as noise: merge or dim the small ones (energy 1.5, no halo) _(from R5 Glow points at 40 m, shot glow)_
2. **Unique materials** (WARN): Snap to the closed palette (art-units 2.2); no per-part materials _(from B8 Unique materials)_
3. **Materials built per instance** (INFO): Share the 1 per-instance material(s) (static cache) so 200 units do not build 200 copies _(from B9 Materials built per instance)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 31.8): value is close to the ground (dL -2): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 23 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 12.8: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 13 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 0 | 1 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 0 new material(s) during move / attack / hit / cast | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Authored meshes | INFO | 9 | no budget for landmark/landmark |  |
| B2 | Draw instances at rest | PASS 100 | 6 | <= 24 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B4 | Vertices | PASS 99 | 14517 | <= 20000 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B6 | Particle systems | INFO | 2 | no budget for landmark/landmark |  |
| B6l | Looping particle systems | PASS 100 | 1 (Embers) | <= 2 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B6p | Looping particles alive | INFO | 22 | no budget for landmark/landmark |  |
| B7 | Shadow casters | INFO | 2 | no budget for landmark/landmark |  |
| B8 | Unique materials | **WARN** 35 | 10 | <= 6 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (4 animated at 40 m: +-1.08 ms process, render CPU +0.02 ms, GPU +-0.06 ms) | <= 0.05 ms per instance soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 25248 px (505 x 437 bbox; 55 m: 12709 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 94 | mean-colour dE 31.8, 18% of the body melts (within dE 15 of the ground); body L* 57.4 C 16.2 vs ground L* 59.7 C 45.8, hue gap 23 deg; per-pixel dE 38.7, outline 33.5 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 94 | worst heath: dE 12.8 (heath dE 12.8, old_wood dE 26.9, riverbank dE 27.5) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 11 point(s) (px 2781, 58, 51, 42, 39, 12) | 0-3 (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge or dim the small ones (energy 1.5, no halo) |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.29 (giant_stump 0.29, aqueduct 0.28, colossus 0.27, crag_nest 0.18, standing_stones 0.13, old_wood_den 0.07) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 10 of 11 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 100 | outline complexity 27.69 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 52 | top third L* 62.9, bottom third L* 59.0 (+3) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 5.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.6 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Notes
- 4 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
