# Art Lab scorecard: ysolde

Scene `res://art/units/wizards/ysolde.tscn` · kind **unit** / tier **wizard** · kingdom nature · ground meadow · 2026-10-15 10:08:31 · lab v3.1

## Result: **WARN** · quality **91 / 100** (90.5)

0 FAIL · 4 WARN · 29 PASS · 18 info · 0 skipped · 38 s

## Improve next
1. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `ysolde_blossom` #ed70a8 -> #fa75b5 (9% of the visible body): predicted dE R3 meadow 22.9 -> 24.0, R3t fire 44.0 -> 44.9, R3t shadow 52.6 -> 53.5, R3t ice 37.5 -> 38.3, R3t nature 22.9 -> 24.0, R4k old_wood 32.9 -> 33.1 (want >= 24); other grounds heath 8.9, riverbank 32.6, snow 39.4, ash 46.8, sand 22.8, marsh 49.0; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `ysolde_cloth_dark` 13%, `ysolde_cloth` 25% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4 Contrast on the other grounds, shot z40)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Face 1.65 m, Merged 1.64 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Vertices** (WARN): B4 6984 -> 3497 (want <= 3000): `Merged` 2409 -> 1205 verts; `StaffMesh` 1401 -> 701 verts; `Merged` 747 -> 374 verts; `Cape` 682 -> 341 verts; `Merged` 632 -> 316 verts; `Merged` 441 -> 221 verts; `Merged` 441 -> 221 verts; `Petals` 150 -> 75 verts; `Seed` 77 -> 39 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
4. **Looping particle systems** (WARN): B6l Looping particle systems: Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) [fixes.json #4] _(from B6l Looping particle systems)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 22.9): value is close to the ground (dL -1): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 14 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 19.5): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (10 mesh + 1 multimesh); per pivot: Bloom 2, Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 6984 (body + face above its allowance: face 2002 v, allowance 2200, total 8986; biggest: Merged 2409, Face 2002, StaffMesh 1401, Merged 747) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (SeedLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/wizard |  |
| B6l | Looping particle systems | **WARN** 41 | 2 (CrownPetals, SeedMotes) | <= 1 soft (art-units.md 8 (wizard)) | Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 6 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2299 of 12892 triangles (17%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.01 ms process, render CPU +1.12 ms, GPU +2.09 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.034 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 83 | head top 2.57 m / body_height 2.0 (x1.29) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Face 1.65 m, Merged 1.64 m | narrower than 0.7 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.98 / z 0.85 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1428 px (47 x 63 bbox; 55 m: 712 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 85 | mean-colour dE 22.9, 1% of the body melts (within dE 15 of the ground); body L* 60.3 C 28.1 vs ground L* 61.9 C 48.9, hue gap 14 deg; top third (world height) dE 50.6, L* 82.0; per-pixel dE 47.3, outline 41.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 32.9, 6% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | **WARN** 40 | worst heath: dE 9.5 (heath dE 9.5, old_wood dE 32.9, riverbank dE 32.0, snow dE 40.2, ash dE 47.2, sand dE 23.2, marsh dE 49.3) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility at 40 m | PASS 100 | 31% of body pixels change between kingdom colours (min pair 30%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 90 | worst nature colour: dE 22.9 (fire 44.0, shadow 52.6, ice 37.5, nature 22.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 15.5 on the team-colour area (normal vision 73.0; 476 px); deutan: fire / nature dE 15.5; protan: fire / nature dE 30.5; worst vs ground: nature colour (deutan) dE 13.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 4% of the silhouette (gap -18 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +15 (point 1 dL +33, point 2 dL +22, soft 1 dL +30 (counts), soft 2 dL +22 (counts), soft 3 dL +15 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Seed, Cape; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 89 | worst autumn: dE 21.1, dL +1 (warm dE 24.6, ice dE 23.0, night dE 26.1, autumn dE 21.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.85 (min 0.8), area kept 100-103% (min 1430 px), frame-to-frame IoU min 0.84; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 96 | max IoU 0.5 (bramble_harrier 0.5, ruin_warden 0.49, bramblehorn 0.4, bramble_harrier_placeholder 0.4, stormbottle_genie 0.39, mossback 0.27) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.4 m from the body centre at t 0.08 s (1.29 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 29% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 51% of the silhouette at its peak (t 0.4 s; 0.12 s 40%, 0.25 s 40%, 0.4 s 51%, 0.6 s 49%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.14 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 198 shapes over 7 body parts (28.3 per part: Hips 10, Head 129, ArmL 8, Staff 16, Bloom 1, ArmR 8, Chest 26); 4% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.965 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 294% of the 3000 verts budget used (8832) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.29 at the close-up (89944 px), 2.22 at 25 m; close-up outline complexity 18.59 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.89 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 82.0, bottom third L* 34.3 (+47, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.2 at 25 m, 14.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 36 | on the autumn floor: dE 19.5, 5% melts; body L* 58.7 C 29.2 vs floor L* 50.5 C 42.1; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 90 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (wizard))
`{"draw":16,"face_verts":2200,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 2409 v / 5 s; Root/Chest/Head/Face 2002 v / 1 s; Root/Chest/ArmR/Staff/StaffMesh 1401 v / 3 s; Root/Chest/Merged 747 v / 4 s; Root/Chest/Cape 682 v / 1 s; Root/Hips/Merged 632 v / 3 s; Root/Chest/ArmL/Merged 441 v / 3 s; Root/Chest/ArmR/Merged 441 v / 3 s
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: shader_parameter/base_color of `ysolde_blossom` #ed70a8 -> #fa75b5 (9% of the visible body): predicted dE R3 meadow 22.9 -> 24.0, R3t fire 44.0 -> 44.9, R3t sha)
