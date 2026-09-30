# Art Lab scorecard: thistle_darter

Scene `res://art/units/nature/thistle_darter/thistle_darter.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-30 11:05:52 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.8) (previous run 93, +0)

0 FAIL · 1 WARN · 32 PASS · 17 info · 0 skipped · 23 s

## Before / after (vs the run of 2026-09-27 17:53:00 in `docs/art/lab/thistle_darter`: quality 93 -> 93, +0)
### What got worse (5)
1. **R10 Footprint vs selection radius: INFO -> WARN 52 (+0)**. Now: x 0.35 / z 0.92 m (radius 0.4, from thistle_darter.tres). Was: x 0.35 / z 0.92 m (radius 0.45, default)
2. **C4 Inner detail (close-up / 25 m): INFO 69 -> INFO 50 (-19)**. Now: inner edges per outline px: 2.86 at the close-up (40969 px), 1.0 at 25 m; close-up outline complexity 9.27. Was: inner edges per outline px: 2.7 at the close-up (41631 px), 1.16 at 25 m; close-up outline complexity 8.8
3. **R4 Contrast on the other grounds: PASS 85 -> PASS 78 (-7)**. Now: worst sand: dE 12.3 (heath dE 33.3, old_wood dE 44.4, riverbank dE 43.8, snow dE 34.1, ash dE 57.6, sand dE 12.3, marsh dE 60.3). Was: worst sand: dE 17.6 (heath dE 28.5, old_wood dE 39.7, riverbank dE 38.8, snow dE 33.7, ash dE 52.6, sand dE 17.6, marsh 
4. **R6cb Team colours for colour-blind players: PASS 79 -> PASS 76 (-3)**. Now: worst pair fire / nature (deutan): dE 11.2 on the team-colour area (normal vision 63.7; 61 px); deutan: fire / nature dE 11.2; protan: fire / nature dE 19.7; worst vs ground: fire . Was: worst pair fire / nature (deutan): dE 11.0 on the team-colour area (normal vision 65.8; 66 px); deutan: fire / nature dE
5. **S1 Style bible: golden autumn (style-autumn.md 3): INFO 47 -> INFO 45 (-2)**. Now: on the autumn floor: dE 22.4, 3% melts; body L* 69.7 C 34.6 vs floor L* 53.2 C 43.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry). Was: on the autumn floor: dE 23.2, 2% melts; body L* 65.9 C 29.5 vs floor L* 53.2 C 43.6; nature team colour vs the floor swa

### What got better (3)
P4 Detail density 25 m / 40 m: INFO 15 -> INFO 94 (+80) (noisy check: re-run before acting); R8 Head height vs body_height: PASS 90 -> PASS 100 (+10); B4 Vertices: PASS 87 -> PASS 94 (+7)

### Score delta per check (17 changed, 42 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B2 | Draw instances at rest | PASS 100 | PASS 99 | -0.6 |
| B4 | Vertices | PASS 87 | PASS 94 | +6.8 |
| C1 | Shape richness (secondary shapes) | INFO 95 | INFO 94 | -1.4 |
| R8 | Head height vs body_height | PASS 90 | PASS 100 | +9.9 |
| R10 | Footprint vs selection radius | INFO  | WARN 52 | +0.0 |
| C4 | Inner detail (close-up / 25 m) | INFO 69 | INFO 50 | -19.4 |
| R1 | Silhouette area at 40 m | PASS 93 | PASS 92 | -1.1 |
| R3 | Contrast vs ground (meadow) | PASS 85 | PASS 84 | -0.9 |
| R4 | Contrast on the other grounds | PASS 85 | PASS 78 | -6.7 |
| R3t | Contrast in every team colour (meadow) | PASS 90 | PASS 88 | -1.6 |
| R6cb | Team colours for colour-blind players | PASS 79 | PASS 76 | -3.1 |
| P4 | Detail density 25 m / 40 m | INFO 15 | INFO 94 | +79.9 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 91 | PASS 89 | -1.4 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 88 | PASS 86 | -1.7 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 47 | INFO 45 | -2.4 |
| R5w | Glow points while walking (flicker) | PASS 93 | PASS 96 | +3.8 (noisy) |
| B13 | Frame cost | PASS 93 | PASS 100 | +6.7 (noisy) |

Changed pixels per shot: z40 0.3 %, z55 0.2 %, z25 0.3 %, close 3.4 %, strike_side 75.2 %, turns 4.9 %, cast 3.3 %, anim 2.2 %, silhouette 18.8 %, lineup 52.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.4 -> 0.52, or pull the widest parts in to x <= 0.7 / z <= 0.7 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (2.86 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
3. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 21.9): value is close to the ground (dL +7): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 15 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
4. **Contrast on the other grounds** (PASS): On sand the body drops to dE 12.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 22.4): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
6. **Contrast in every team colour (meadow)** (PASS): In the nature team colour the body drops to dE 21.7 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: ArmR 2, Head 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 94 | 2042 (body + face above its allowance: face 456 v, allowance 800, total 2498; biggest: Merged 542, Merged 511, Face 456, Merged 353) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 5 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 4 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 22 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 345 of 3479 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0003 ms process per instance (100 animated at 40 m: +0.03 ms process, render CPU +0.72 ms, GPU +0.22 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.018 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.39 m / body_height 1.4 (x0.99) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.35 / z 0.92 m (radius 0.4, from thistle_darter.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 92 | 187 px (18 x 32 bbox; 55 m: 91 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 84 | mean-colour dE 21.9, 4% of the body melts (within dE 15 of the ground); body L* 71.6 C 30.3 vs ground L* 64.1 C 48.3, hue gap 15 deg; top third (world height) dE 23.9, L* 81.8; per-pixel dE 35.0, outline 34.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 44.4, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 78 | worst sand: dE 12.3 (heath dE 33.3, old_wood dE 44.4, riverbank dE 43.8, snow dE 34.1, ash dE 57.6, sand dE 12.3, marsh dE 60.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 32%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 88 | worst nature colour: dE 21.7 (fire 38.0, shadow 48.8, ice 36.7, nature 21.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 76 | worst pair fire / nature (deutan): dE 11.2 on the team-colour area (normal vision 63.7; 61 px); deutan: fire / nature dE 11.2; protan: fire / nature dE 19.7; worst vs ground: fire colour (deutan) dE 11.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 4 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +22 (point 1 dL +27, soft 1 dL +22 (counts), soft 2 dL +25 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 1/2/2): Merged, MuzzlePuff; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 86 | worst autumn: dE 18.6, dL +9 (warm dE 21.7, ice dE 22.1, night dE 22.1, autumn dE 18.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 92 | walk frames vs rest: mean IoU 0.71 (min 0.57), area kept 94-104% (min 177 px), frame-to-frame IoU min 0.56; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 2/2/2/1/2/2/2/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.4 (magpie 0.4, thornling 0.36, thistle_darter_placeholder 0.35, placeholder 0.33, bristleback 0.29, burr_slinger 0.29) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.04 m from the body centre at t 0.14 s (1.04 m forward; geometry clipped at the ground); declared 8.0 m (UnitType attack_range (thistle_darter.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 38% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 71% of the silhouette at its peak (t 0.25 s; 0.12 s 67%, 0.25 s 71%, 0.4 s 54%, 0.6 s 10%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 94 | 87 shapes over 7 body parts (12.4 per part: LegL 4, LegR 4, Hips 6, Head 38, ArmL 3, ArmR 12, Chest 20); 29% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.906 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 2500 verts budget used (2494) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 50 | inner edges per outline px: 2.86 at the close-up (40969 px), 1.0 at 25 m; close-up outline complexity 9.27 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.07 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 81.8, bottom third L* 49.3 (+32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 94 | inner detail 11.2 at 25 m, 14.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 45 | on the autumn floor: dE 22.4, 3% melts; body L* 69.7 C 34.6 vs floor L* 53.2 C 43.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.33 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- strike_side: [strike_side.jpg](strike_side.jpg)
- turns: [turns.jpg](turns.jpg)
- cast: [cast.jpg](cast.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 542 v / 5 s; Root/Chest/Merged 511 v / 4 s; Root/Chest/Head/Face 456 v / 1 s; Root/Chest/ArmR/Merged 353 v / 4 s; Root/Hips/LegL/Merged 153 v / 2 s; Root/Hips/LegR/Merged 153 v / 2 s; Root/Hips/Merged 150 v / 1 s; Root/Chest/ArmL/Merged 122 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R10: raise UnitType.radius 0.4 -> 0.52, or pull the widest parts in to x <= 0.7 / z <= 0.7 m)
