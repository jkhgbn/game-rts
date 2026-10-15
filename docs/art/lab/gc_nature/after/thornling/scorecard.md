# Art Lab scorecard: thornling

Scene `res://art/units/nature/thornling.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-10-15 12:56:14 · lab v3.1

## Result: **WARN** · quality **94 / 100** (93.5) (previous run 93, +1)

0 FAIL · 1 WARN · 32 PASS · 16 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-10-15 12:46:00 in `docs/art/lab/gc_nature/after/thornling`: quality 93 -> 94, +1)
### What got worse (1)
1. **C4 Inner detail (close-up / 25 m): INFO 100 -> INFO 89 (-11)**. Now: inner edges per outline px: 4.51 at the close-up (62859 px), 1.31 at 25 m; close-up outline complexity 9.26. Was: inner edges per outline px: 4.51 at the close-up (63252 px), 1.55 at 25 m; close-up outline complexity 9.2

### What got better (1)
P4 Detail density 25 m / 40 m: INFO 4 -> INFO 45 (+41) (noisy check: re-run before acting)

### Score delta per check (7 changed, 47 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C4 | Inner detail (close-up / 25 m) | INFO 100 | INFO 89 | -11.5 |
| R4 | Contrast on the other grounds | PASS 82 | PASS 80 | -1.6 |
| P4 | Detail density 25 m / 40 m | INFO 4 | INFO 45 | +41.3 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 89 | -0.6 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 27 | INFO 28 | +1.3 |
| R11 | Reads while walking (40 m) | PASS 87 | PASS 88 | +0.6 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 96 | PASS 93 | -3.8 (noisy) |

Changed pixels per shot: z40 0.3 %, z55 0.2 %, z25 0.3 %, close 2.1 %, strike_side 8.9 %, turns 3.2 %, cast 1.8 %, anim 2.6 %, silhouette 0.0 %, lineup 0.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 8.1): add a value step inside the team-colour area [fixes.json #1] _(from R6cb Team colours for colour-blind players, shot teams)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (13.2): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 21.5): value is close to the ground (dL +3): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 20 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
4. **Contrast on the other grounds** (PASS): On sand the body drops to dE 14.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 16.9): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from magpie (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 92 | 2137 (body + face above its allowance: face 432 v, allowance 800, total 2569; biggest: Merged 621, Face 432, Merged 373, Merged 373) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 12 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 3 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 424 of 3562 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0004 ms process per instance (100 animated at 40 m: +0.04 ms process, render CPU +0.94 ms, GPU +1.21 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.014 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 95 | head top 1.52 m / body_height 1.4 (x1.09) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.53 / z 0.62 m (radius 0.4, from thornling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 425 px (28 x 35 bbox; 55 m: 212 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 84 | mean-colour dE 21.5, 5% of the body melts (within dE 15 of the ground); body L* 67.3 C 32.3 vs ground L* 63.5 C 48.4, hue gap 20 deg; top third (world height) dE 26.1, L* 75.7; per-pixel dE 33.4, outline 31.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 40.9, 4% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 80 | worst sand: dE 14.2 (heath dE 26.7, old_wood dE 40.9, riverbank dE 41.5, snow dE 37.5, ash dE 54.7, sand dE 14.2, marsh dE 56.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 35% of body pixels change between kingdom colours (min pair 34%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 88 | worst nature colour: dE 21.6 (fire 36.3, shadow 44.5, ice 34.9, nature 21.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 38 | worst pair fire / nature (deutan): dE 8.1 on the team-colour area (normal vision 46.8; 154 px); deutan: fire / nature dE 8.1; protan: fire / nature dE 14.4; worst vs ground: fire colour (deutan) dE 8.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -1 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +24 (soft 1 dL +24 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/1/0); soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 86 | worst autumn: dE 18.4, dL +5 (warm dE 21.4, ice dE 21.7, night dE 24.0, autumn dE 18.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 88 | walk frames vs rest: mean IoU 0.62 (min 0.57), area kept 94-97% (min 402 px), frame-to-frame IoU min 0.62; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 0/0/1/0/0/1/0/0 (median 0, range 1, 0 frame(s) at 0; at rest 0) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.65 (magpie 0.65, thistle_darter_placeholder 0.53, burr_slinger 0.52, vinelasher 0.46, bristleback 0.39, thistle_darter 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.51 m from the body centre at t 0.24 s (1.47 m forward; geometry clipped at the ground); declared 1.5 m (UnitType attack_range (thornling.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 68% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 35% of the silhouette at its peak (t 0.4 s; 0.12 s 31%, 0.25 s 33%, 0.4 s 35%, 0.6 s 33%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 93 | 92 shapes over 7 body parts (13.1 per part: LegL 5, LegR 5, Hips 6, Head 27, ArmL 15, ArmR 15, Chest 19); 41% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.937 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 102% of the 2500 verts budget used (2565) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 89 | inner edges per outline px: 4.51 at the close-up (62859 px), 1.31 at 25 m; close-up outline complexity 9.26 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.05 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 75.7, bottom third L* 52.3 (+23, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 45 | inner detail 13.2 at 25 m, 14.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 28 | on the autumn floor: dE 16.9, 16% melts; body L* 64.8 C 35.9 vs floor L* 52.7 C 43.4; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.34 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Merged 621 v / 6 s; Root/Chest/Head/Face 432 v / 1 s; Root/Chest/ArmL/Merged 373 v / 3 s; Root/Chest/ArmR/Merged 373 v / 3 s; Root/Chest/Head/Merged 244 v / 3 s; Root/Hips/LegL/Merged 186 v / 1 s; Root/Hips/LegR/Merged 186 v / 1 s; Root/Hips/Merged 150 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 8.1): add a value step inside)
