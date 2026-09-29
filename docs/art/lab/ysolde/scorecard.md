# Art Lab scorecard: ysolde

Scene `res://art/units/wizards/ysolde.tscn` · kind **unit** / tier **wizard** · kingdom nature · ground meadow · 2026-09-28 20:09:40 · lab v3.1

## Result: **WARN** · quality **89 / 100** (88.9) (previous run 91, -2)

0 FAIL · 5 WARN · 29 PASS · 18 info · 0 skipped · 28 s

## Before / after (vs the run of 2026-09-28 20:01:49 in `docs/art/lab/ysolde`: quality 91 -> 89, -2)
### What got worse (1)
1. **R4 Contrast on the other grounds: PASS 75 -> WARN 40 (-35)**. Now: worst heath: dE 9.6 (heath dE 9.6, old_wood dE 32.5, riverbank dE 31.3, snow dE 40.9, ash dE 47.2, sand dE 24.0, marsh dE 49.2). Was: worst heath: dE 10.1 (heath dE 10.1, old_wood dE 32.7, riverbank dE 31.1, snow dE 40.8, ash dE 47.4, sand dE 24.1, marsh

new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new P2 Asymmetric secondary shape (INFO); new R2 Distinct from references (black masks) (PASS); new B13 Frame cost (PASS)

### Score delta per check (1 changed, 46 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R4 | Contrast on the other grounds | PASS 75 | WARN 40 | -34.9 |

Changed pixels per shot: z40 0.5 %, z55 0.5 %, z25 0.9 %, close 11.4 %, strike_side 7.1 %, turns 3.2 %, cast 7.5 %, anim 5.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `ysolde_blossom` #ed70a8 -> #ff80bf (10% of the visible body): predicted dE R3 meadow 22.4 -> 24.1, R3t fire 43.6 -> 44.9, R3t shadow 52.4 -> 53.6, R3t ice 37.3 -> 38.6, R3t nature 22.4 -> 24.2, R4k old_wood 32.5 -> 32.8 (want >= 24); other grounds heath 8.8, riverbank 32.1, snow 39.4, ash 46.5, sand 23.4, marsh 48.9; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `ysolde_cloth_dark` 13%, `ysolde_cloth` 25% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4 Contrast on the other grounds, shot z40)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Face 1.67 m, Merged 1.81 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #4] _(from B9m Meshes built per instance)_
4. **Vertices** (WARN): B4 8986 -> 4498 (want <= 3000): `Merged` 2409 -> 1205 verts; `Face` 2002 -> 1001 verts; `StaffMesh` 1401 -> 701 verts; `Merged` 747 -> 374 verts; `Cape` 682 -> 341 verts; `Merged` 632 -> 316 verts; `Merged` 441 -> 221 verts; `Merged` 441 -> 221 verts; `Petals` 150 -> 75 verts; `Seed` 77 -> 39 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
5. **Looping particle systems** (WARN): B6l Looping particle systems: Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) [fixes.json #5] _(from B6l Looping particle systems)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 22.4): value is close to the ground (dL -2): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 13 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (10 mesh + 1 multimesh); per pivot: Bloom 2, Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 8986 (biggest: Merged 2409, Face 2002, StaffMesh 1401, Merged 747) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (SeedLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/wizard |  |
| B6l | Looping particle systems | **WARN** 41 | 2 (CrownPetals, SeedMotes) | <= 1 soft (art-units.md 8 (wizard)) | Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 6 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2293 of 12892 triangles (17%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0011 ms process per instance (100 animated at 40 m: +0.11 ms process, render CPU +1.0 ms, GPU +2.07 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.035 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 82 | head top 2.59 m / body_height 2.0 (x1.3) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Face 1.67 m, Merged 1.81 m | narrower than 0.7 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.98 / z 0.85 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1420 px (46 x 62 bbox; 55 m: 728 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 84 | mean-colour dE 22.4, 0% of the body melts (within dE 15 of the ground); body L* 59.5 C 28.6 vs ground L* 61.9 C 48.9, hue gap 13 deg; top third (world height) dE 47.6, L* 81.2; per-pixel dE 47.2, outline 41.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 32.5, 5% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | **WARN** 40 | worst heath: dE 9.6 (heath dE 9.6, old_wood dE 32.5, riverbank dE 31.3, snow dE 40.9, ash dE 47.2, sand dE 24.0, marsh dE 49.2) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility at 40 m | PASS 100 | 31% of body pixels change between kingdom colours (min pair 30%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 89 | worst nature colour: dE 22.4 (fire 43.6, shadow 52.4, ice 37.3, nature 22.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 15.5 on the team-colour area (normal vision 74.4; 465 px); deutan: fire / nature dE 15.5; protan: fire / nature dE 30.8; worst vs ground: nature colour (deutan) dE 14.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -17 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +18 (point 1 dL +31, point 2 dL +21, soft 1 dL +18 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Seed, Cape; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 87 | worst autumn: dE 19.3, dL +0 (warm dE 22.7, ice dE 21.2, night dE 25.7, autumn dE 19.3); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.85 (min 0.8), area kept 100-102% (min 1429 px), frame-to-frame IoU min 0.84; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (vessa 0.69, ruin_warden 0.49, bramblehorn 0.4, bramble_harrier_placeholder 0.4, stormbottle_genie 0.38, mossback 0.27) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.38 m from the body centre at t 0.14 s (1.25 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 99 | strike pose changes 28% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 52% of the silhouette at its peak (t 0.4 s; 0.12 s 40%, 0.25 s 42%, 0.4 s 52%, 0.6 s 50%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 198 shapes over 7 body parts (28.3 per part: Hips 10, Head 129, ArmL 8, Staff 16, Bloom 1, ArmR 8, Chest 26); 4% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.966 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 294% of the 3000 verts budget used (8832) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 15 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.29 at the close-up (89887 px), 2.16 at 25 m; close-up outline complexity 18.64 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.85 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 81.2, bottom third L* 32.6 (+48, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.1 at 25 m, 13.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 38 | on the autumn floor: dE 20.3, 5% melts; body L* 58.5 C 30.1 vs floor L* 50.6 C 42.1; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 72 | front-view asymmetry 0.15 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (wizard))
`{"draw":16,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 2409 v / 5 s; Root/Chest/Head/Face 2002 v / 1 s; Root/Chest/ArmR/Staff/StaffMesh 1401 v / 3 s; Root/Chest/Merged 747 v / 4 s; Root/Chest/Cape 682 v / 1 s; Root/Hips/Merged 632 v / 3 s; Root/Chest/ArmL/Merged 441 v / 3 s; Root/Chest/ArmR/Merged 441 v / 3 s
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 5 in fixes.json (top: shader_parameter/base_color of `ysolde_blossom` #ed70a8 -> #ff80bf (10% of the visible body): predicted dE R3 meadow 22.4 -> 24.1, R3t fire 43.6 -> 44.9, R3t sh)
