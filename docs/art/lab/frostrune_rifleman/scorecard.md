# Art Lab scorecard: frostrune_rifleman

Scene `res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-09-26 22:55:36 · lab v1.0

## Result: **FAIL** · quality **90 / 100**

2 FAIL · 1 WARN · 22 PASS · 8 info · 0 skipped · 18 s

## Improve next
1. **Authored meshes** (FAIL): Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh _(from B1 Authored meshes)_
2. **Vertices** (FAIL): Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces _(from B4 Vertices)_
3. **Glow points at 40 m** (WARN): Too many glow points read as noise: merge or dim the small ones (energy 1.5, no halo) _(from R5 Glow points at 40 m, shot glow)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from shardcaster (IoU 0.75): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Authored meshes | **FAIL** 0 | 36 (model says 26) | <= 26 (art-units.md 8, tier3-extras.md 12) | Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 3349 | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Rifle, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/soldier |  |
| B13 | Frame cost | PASS 100 | 0.0004 ms process per instance (100 animated at 40 m: +0.04 ms process, render CPU +1.06 ms, GPU +0.32 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 91 | head top 1.85 m / body_height 1.6 (x1.15) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.47 / z 1.77 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 534 px (30 x 47 bbox; 55 m: 269 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 62.6, 0% of the body melts (within dE 15 of the ground); body L* 67.5 C 15.9 vs ground L* 63.2 C 48.0, hue gap 151 deg; per-pixel dE 68.1, outline 50.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 35.4 (heath dE 35.4, old_wood dE 53.1, riverbank dE 54.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 4 point(s) (px 40, 23, 6, 2) | 1-3 (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge or dim the small ones (energy 1.5, no halo) |
| R6 | Team-colour visibility at 40 m | PASS 100 | 59% of body pixels change between kingdom colours (min pair 56%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R2 | Distinct from references (black masks) | PASS 80 | max IoU 0.75 (shardcaster 0.75, tracker 0.64, magpie 0.63, rime_hauler 0.6, rimeshield 0.56, rime_seer 0.54) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 99 | strike pose changes 28% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P5 | Glow placement | INFO 100 | 2 of 4 glow point(s) in the upper half | one glow high (head / weapon / crest) reads over crowds |  |
| P1 | Silhouette hook | INFO 71 | outline complexity 2.22 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 85.3, bottom third L* 57.1 (+28) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.8 at 25 m, 8.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.23 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
