# Art Lab scorecard: thornling

Scene `res://art/units/nature/thornling.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-10-15 10:11:36 · lab v3.1

## Result: **WARN** · quality **90 / 100** (90.2)

0 FAIL · 3 WARN · 30 PASS · 16 info · 0 skipped · 42 s

## Improve next
1. **Contrast vs ground (meadow)** (WARN): shader_parameter/base_color of `nature_thorn` #8c6b3d -> #ca8a65 (27% of the visible body): predicted dE R3 meadow 15.5 -> 24.2, R3t fire 42.6 -> 47.7, R3t shadow 53.1 -> 56.2, R3t ice 34.8 -> 39.7, R3t nature 15.3 -> 24.1, R4k old_wood 41.6 -> 45.4 (want >= 24); other grounds heath 30.8, riverbank 47.5, snow 40.8, ash 58.9, sand 12.5, marsh 59.8; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `nature_cloth` 23% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Contrast in every team colour (meadow)** (WARN): In the nature team colour the body drops to dE 15.3 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.7): add a value step inside the team-colour area [fixes.json #2] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.6): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 17.0): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
6. **Contrast on the other grounds** (PASS): On sand the body drops to dE 19.0: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B4 | Vertices | PASS 94 | 2026 (body + face above its allowance: face 432 v, allowance 800, total 2458; biggest: Merged 536, Face 432, Merged 340, Merged 340) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 12 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 25 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 19 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 378 of 3246 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0004 ms process per instance (100 animated at 40 m: +0.04 ms process, render CPU +0.7 ms, GPU +1.54 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.012 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 95 | head top 1.53 m / body_height 1.4 (x1.09) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.53 / z 0.62 m (radius 0.4, from thornling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 426 px (28 x 35 bbox; 55 m: 214 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **WARN** 45 | mean-colour dE 15.5, 7% of the body melts (within dE 15 of the ground); body L* 65.1 C 39.5 vs ground L* 63.4 C 48.4, hue gap 16 deg; top third (world height) dE 22.2, L* 69.0; per-pixel dE 31.1, outline 31.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: value is close to the ground (dL +1): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 16 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 41.6, 1% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 86 | worst sand: dE 19.0 (heath dE 32.2, old_wood dE 41.6, riverbank dE 40.9, snow dE 45.0, ash dE 58.1, sand dE 19.0, marsh dE 58.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 42% of body pixels change between kingdom colours (min pair 41%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 47 | worst nature colour: dE 15.3 (fire 42.6, shadow 53.1, ice 34.8, nature 15.3) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 11.7 on the team-colour area (normal vision 65.3; 186 px); deutan: fire / nature dE 11.7; protan: fire / nature dE 19.4; worst vs ground: fire colour (deutan) dE 0.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -1 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +23 (soft 1 dL +23 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/1/0); soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 79 | worst autumn: dE 12.8, dL +3 (warm dE 15.4, ice dE 15.1, night dE 23.5, autumn dE 12.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 88 | walk frames vs rest: mean IoU 0.62 (min 0.58), area kept 96-97% (min 410 px), frame-to-frame IoU min 0.62; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 0/0/1/0/0/0/1/0 (median 0, range 1, 0 frame(s) at 0; at rest 0) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (magpie 0.63, thistle_darter_placeholder 0.54, burr_slinger 0.52, vinelasher 0.45, bristleback 0.4, thistle_darter 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.64 m from the body centre at t 0.08 s (1.64 m forward; geometry clipped at the ground); declared 1.5 m (UnitType attack_range (thornling.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 69% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 37% of the silhouette at its peak (t 0.4 s; 0.12 s 32%, 0.25 s 35%, 0.4 s 37%, 0.6 s 33%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.03 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 85 | 87 shapes over 7 body parts (12.4 per part: LegL 5, LegR 5, Hips 6, Head 27, ArmL 13, ArmR 13, Chest 18); 48% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.93 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 98% of the 2500 verts budget used (2454) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 86 | inner edges per outline px: 3.42 at the close-up (62977 px), 1.29 at 25 m; close-up outline complexity 9.27 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.93 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 69.0, bottom third L* 48.5 (+20, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 60 | inner detail 12.6 at 25 m, 13.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 28 | on the autumn floor: dE 17.0, 21% melts; body L* 63.0 C 41.5 vs floor L* 52.6 C 43.4; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 536 v / 5 s; Root/Chest/Head/Face 432 v / 1 s; Root/Chest/ArmL/Merged 340 v / 3 s; Root/Chest/ArmR/Merged 340 v / 3 s; Root/Chest/Head/Merged 284 v / 3 s; Root/Hips/LegL/Merged 186 v / 1 s; Root/Hips/LegR/Merged 186 v / 1 s; Root/Hips/Merged 150 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: shader_parameter/base_color of `nature_thorn` #8c6b3d -> #ca8a65 (27% of the visible body): predicted dE R3 meadow 15.5 -> 24.2, R3t fire 42.6 -> 47.7, R3t shad)
