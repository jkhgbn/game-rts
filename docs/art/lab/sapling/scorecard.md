# Art Lab scorecard: sapling

Scene `res://art/units/nature/sapling.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-26 23:58:30 · lab v2.0

## Result: **WARN** · quality **92 / 100** (previous run 91, +1)

0 FAIL · 2 WARN · 26 PASS · 10 info · 0 skipped · 30 s

## Improve next
1. **Glow points at 40 m** (WARN): Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 3 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 _(from R5 Glow points at 40 m, shot glow)_
2. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 21.0): value is close to the ground (dL -6): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 6 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from magpie (IoU 0.68): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Contrast in every team colour (meadow)** (PASS): In the nature team colour the body drops to dE 21.6 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
5. **Contrast on the other grounds** (PASS): On riverbank the body drops to dE 23.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 21 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 7 drawn (7 mesh + 0 multimesh) | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 7 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 88 | 2343 (biggest: CanopyMesh 992, Merged 474, Merged 314, Merged 263) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 100 | 2 (Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 12 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 15 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 7 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 767 of 3390 triangles (22%) face steeply down (normal y < -0.7) | hint when > 25 %%: the camera looks from above (pitch 55); a sphere has ~15 %%, bottom caps add the rest |  |
| B13 | Frame cost | PASS 96 | 0.0028 ms process per instance (100 animated at 40 m: +0.28 ms process, render CPU +0.53 ms, GPU +0.38 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.06 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 48 | head top 1.56 m / body_height 1.2 (x1.3) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | PASS 100 | x 0.57 / z 0.47 m (radius 0.4, from sapling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 435 px (25 x 32 bbox; 55 m: 222 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 83 | mean-colour dE 21.0, 1% of the body melts (within dE 15 of the ground); body L* 56.8 C 28.9 vs ground L* 63.4 C 48.4, hue gap 6 deg; top third (world height) dE 22.3, L* 79.8; per-pixel dE 43.7, outline 37.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 96 | dE 28.6, 7% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 92 | worst riverbank: dE 23.9 (heath dE 26.8, old_wood dE 28.6, riverbank dE 23.9, snow dE 43.7, ash dE 45.6, sand dE 31.4, marsh dE 48.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 58% of body pixels change between kingdom colours (min pair 46%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 88 | worst nature colour: dE 21.6 (fire 46.5, shadow 68.9, ice 45.2, nature 21.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.7 m, 1.04 m wide |  |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 1/0/0); soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 3 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.68 (magpie 0.68, thornling 0.6, sprigling 0.56, burr_slinger 0.55, tracker 0.52, bloomtender 0.41) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 48% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 73 | outline complexity 2.25 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 79.8, bottom third L* 21.4 (+58, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.1 at 25 m, 16.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.29 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Canopy/CanopyMesh 992 v / 6 s; Root/Chest/ArmL/Merged 474 v / 3 s; Root/Chest/ArmR/Merged 314 v / 2 s; Root/Chest/Merged 263 v / 2 s; Root/Hips/LegL/Merged 148 v / 1 s; Root/Hips/LegR/Merged 148 v / 1 s; Shadow 4 v / 1 s
- 3 materials are built in code (fine when cached per type: see B9)
