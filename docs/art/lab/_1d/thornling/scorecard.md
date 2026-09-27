# Art Lab scorecard: thornling

Scene `res://art/units/nature/thornling.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-27 09:41:58 · lab v2.0

## Result: **PASS** · quality **95 / 100**

0 FAIL · 0 WARN · 33 PASS · 11 info · 0 skipped · 34 s

## Improve next
1. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 22.8): value is close to the ground (dL -6): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 12 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 18.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.1): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from magpie (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 19.8: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Contrast in every team colour (meadow)** (PASS): In the nature team colour the body drops to dE 21.7 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 22 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 87 | 2400 (biggest: Merged 559, Merged 479, Merged 479, Merged 332) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 11 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 25 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 386 of 2846 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 95 | 0.003 ms process per instance (100 animated at 40 m: +0.3 ms process, render CPU +1.44 ms, GPU +0.02 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.011 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 96 | head top 1.5 m / body_height 1.4 (x1.07) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.53 / z 0.62 m (radius 0.4, from thornling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 434 px (29 x 35 bbox; 55 m: 226 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 85 | mean-colour dE 22.8, 2% of the body melts (within dE 15 of the ground); body L* 57.0 C 28.1 vs ground L* 63.3 C 48.4, hue gap 12 deg; top third (world height) dE 28.2, L* 61.7; per-pixel dE 40.5, outline 36.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 97 | dE 29.6, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 87 | worst heath: dE 19.8 (heath dE 19.8, old_wood dE 29.6, riverbank dE 30.6, snow dE 42.4, ash dE 44.8, sand dE 25.9, marsh dE 46.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 41% of body pixels change between kingdom colours (min pair 40%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 88 | worst nature colour: dE 21.7 (fire 49.3, shadow 65.4, ice 43.0, nature 21.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 12.5 on the team-colour area (normal vision 74.8; 189 px); deutan: fire / nature dE 12.5; protan: fire / nature dE 23.8; worst vs ground: fire colour (deutan) dE 14.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -1 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +30 (point 1 dL +30, soft 1 dL +32 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/2): Merged, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 78 | worst night: dE 12.4, dL +6 (warm dE 22.1, ice dE 19.7, night dE 12.4, autumn dE 20.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 89 | walk frames vs rest: mean IoU 0.64 (min 0.59), area kept 96-100% (min 417 px), frame-to-frame IoU min 0.64; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 0) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.65 (magpie 0.65, burr_slinger 0.53, sprigling 0.52, bloomtender 0.4, bristleback 0.39, bramblehorn 0.14) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 69% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.07 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 61.7, bottom third L* 34.4 (+27, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 72 | inner detail 12.1 at 25 m, 16.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 32 | on the autumn floor: dE 18.3, 9% melts; body L* 55.1 C 29.7 vs floor L* 52.6 C 43.3; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.34 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Merged 559 v / 5 s; Root/Chest/ArmL/Merged 479 v / 3 s; Root/Chest/ArmR/Merged 479 v / 3 s; Root/Chest/Head/Merged 332 v / 5 s; Root/Hips/LegL/Merged 186 v / 1 s; Root/Hips/LegR/Merged 186 v / 1 s; Root/Hips/Merged 175 v / 1 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
