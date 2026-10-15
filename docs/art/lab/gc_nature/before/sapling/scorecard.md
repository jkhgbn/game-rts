# Art Lab scorecard: sapling

Scene `res://art/units/nature/sapling.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-10-15 12:25:33 · lab v3.1

## Result: **WARN** · quality **91 / 100** (91.3)

0 FAIL · 3 WARN · 29 PASS · 16 info · 0 skipped · 30 s

## Improve next
1. **Contrast vs ground (meadow)** (WARN): shader_parameter/base_color of `nature_blossom` #f299bf -> #ffb5ff (7% of the visible body): predicted dE R3 meadow 19.3 -> 24.0, R3t fire 42.5 -> 45.5, R3t shadow 63.3 -> 66.1, R3t ice 43.0 -> 46.1, R3t nature 19.9 -> 24.6, R4k old_wood 32.4 -> 32.4 (want >= 24); other grounds heath 23.6, riverbank 29.8, snow 36.1, ash 46.1, sand 25.6, marsh 49.6; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `nature_cloth` 34% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Head height vs body_height** (WARN): R8: body_height 1.2 -> 1.56 in res://art/units/nature/sapling.tscn (root) and res://data/units/sapling.tres (the head top; x1.3 now), or lower the head / crest 0.06 m [fixes.json #2] _(from R8 Head height vs body_height)_
3. **Contrast in every team colour (meadow)** (WARN): In the nature team colour the body drops to dE 19.9 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from magpie (IoU 0.66): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 24.9): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
6. **Contrast under every light preset (meadow)** (PASS): Under the night light the body drops to dE 15.2: add a value step (light top / pale crest) that survives a dim light _(from R12 Contrast under every light preset (meadow), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: Canopy 2, (root) 1, ArmL 1, ArmR 1, Chest 1, LegL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 96 | 1957 (body + face above its allowance: face 485 v, allowance 800, total 2442; biggest: CanopyMesh 968, Face 485, Merged 318, Merged 263) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 100 | 2 (Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 12 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 3 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 680 of 3942 triangles (17%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0009 ms process per instance (100 animated at 40 m: +0.09 ms process, render CPU +0.63 ms, GPU +1.38 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.038 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 48 | head top 1.56 m / body_height 1.2 (x1.3) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | PASS 100 | x 0.57 / z 0.47 m (radius 0.4, from sapling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 432 px (25 x 33 bbox; 55 m: 222 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **WARN** 48 | mean-colour dE 19.3, 4% of the body melts (within dE 15 of the ground); body L* 60.6 C 29.3 vs ground L* 63.5 C 48.4, hue gap 0 deg; top third (world height) dE 27.0, L* 85.1; per-pixel dE 40.9, outline 35.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: value is close to the ground (dL -2): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 0 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 32.4, 8% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 94 | worst sand: dE 25.3 (heath dE 26.7, old_wood dE 32.4, riverbank dE 29.1, snow dE 39.6, ash dE 48.3, sand dE 25.3, marsh dE 50.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 46% of body pixels change between kingdom colours (min pair 45%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 53 | worst nature colour: dE 19.9 (fire 42.5, shadow 63.3, ice 43.0, nature 19.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 12.7 on the team-colour area (normal vision 64.5; 207 px); deutan: fire / nature dE 12.7; protan: fire / nature dE 21.4; worst vs ground: fire colour (deutan) dE 15.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.7 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +18 (soft 1 dL +18 (counts), soft 2 dL +31 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0), 2 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2; + 2 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 81 | worst night: dE 15.2, dL +12 (warm dE 20.3, ice dE 19.1, night dE 15.2, autumn dE 17.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.76 (min 0.67), area kept 95-97% (min 413 px), frame-to-frame IoU min 0.67; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.66 (magpie 0.66, thornling 0.6, thistle_darter_placeholder 0.59, burr_slinger 0.55, tracker 0.52, thistle_darter 0.39) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.7 m from the body centre at t 0.14 s (0.55 m forward; geometry clipped at the ground); declared 1.5 m (UnitType attack_range (sapling.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 35% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 33% of the silhouette at its peak (t 0.25 s; 0.12 s 29%, 0.25 s 33%, 0.4 s 32%, 0.6 s 20%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.04 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 59 shapes over 6 body parts (9.8 per part: LegL 4, LegR 4, Canopy 39, ArmL 4, ArmR 3, Chest 5); 26% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.946 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 97% of the 2500 verts budget used (2438) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 11 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.16 at the close-up (71112 px), 1.43 at 25 m; close-up outline complexity 7.55 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.61 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 85.1, bottom third L* 20.6 (+64, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.7 at 25 m, 13.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 53 | on the autumn floor: dE 24.9, 0% melts; body L* 57.9 C 29.9 vs floor L* 52.6 C 43.4; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.29 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Canopy/CanopyMesh 968 v / 5 s; Root/Chest/Head/Canopy/Face 485 v / 1 s; Root/Chest/ArmL/Merged 318 v / 3 s; Root/Chest/Merged 263 v / 2 s; Root/Chest/ArmR/Merged 236 v / 2 s; Root/Hips/LegL/Merged 84 v / 1 s; Root/Hips/LegR/Merged 84 v / 1 s; Shadow 4 v / 1 s
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: shader_parameter/base_color of `nature_blossom` #f299bf -> #ffb5ff (7% of the visible body): predicted dE R3 meadow 19.3 -> 24.0, R3t fire 42.5 -> 45.5, R3t sha)
