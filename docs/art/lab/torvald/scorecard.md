# Art Lab scorecard: torvald

Scene `res://art/units/wizards/torvald.tscn` · kind **unit** / tier **wizard** · kingdom ice · ground meadow · 2026-09-28 20:09:11 · lab v3.1

## Result: **WARN** · quality **92 / 100** (91.5) (previous run 92, +0)

0 FAIL · 4 WARN · 30 PASS · 18 info · 0 skipped · 28 s

## Before / after (vs the run of 2026-09-28 20:01:25 in `docs/art/lab/torvald`: quality 92 -> 92, +0)
### What got worse (1)
1. **C3 Palette depth (close-up): INFO 100 -> INFO 90 (-10)**. Now: 12 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %). Was: 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %)

new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new P2 Asymmetric secondary shape (INFO); new R2 Distinct from references (black masks) (PASS); new B13 Frame cost (PASS)

### Score delta per check (6 changed, 46 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 99 | INFO 100 | +0.6 |
| C3 | Palette depth (close-up) | INFO 100 | INFO 90 | -10.0 |
| R4k | Contrast on the home ground (snow) | WARN 51 | WARN 50 | -0.6 |
| R4 | Contrast on the other grounds | PASS 85 | PASS 85 | -0.6 |
| A3 | Attack reads at 40 m | PASS 96 | PASS 99 | +3.0 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 91 | PASS 90 | -0.9 (noisy) |

Changed pixels per shot: z40 0.7 %, z55 0.6 %, z25 0.9 %, close 5.7 %, strike_side 7.1 %, turns 7.8 %, cast 7.2 %, anim 4.1 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the home ground (snow)** (WARN): shader_parameter/base_color of `torvald_fur_pale` #bdcce0 -> #5580ff (15% of the visible body): predicted dE R3 meadow 58.9 -> 64.3, R3t fire 48.7 -> 55.2, R3t shadow 59.6 -> 67.3, R3t ice 57.9 -> 63.5, R3t nature 39.2 -> 45.1, R4k snow 17.8 -> 24.0 (want >= 24); other grounds heath 45.7, old_wood 59.3, riverbank 58.7, ash 54.3, sand 49.0, marsh 64.6; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `torvald_cloth_dark` 33% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4k Contrast on the home ground (snow), shot z40)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.81 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #4] _(from B9m Meshes built per instance)_
4. **Vertices** (WARN): B4 5713 -> 2885 (want <= 3000): `Face` 1637 -> 819 verts; `Merged` 869 -> 435 verts; `StaffMesh` 632 -> 316 verts; `Flake` 576 -> 288 verts; `Merged` 543 -> 272 verts; `Merged` 507 -> 254 verts; `Merged` 507 -> 254 verts; `Merged` 390 -> 195 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from vessa (IoU 0.69): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Contrast on the other grounds** (PASS): On snow the body drops to dE 17.8: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 30 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (10 mesh + 1 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1, Hips 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 5713 (biggest: Face 1637, Merged 869, StaffMesh 632, Flake 576) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (OrbLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 6 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (SnowMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 19 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 4 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 35 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 958 of 7124 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0011 ms process per instance (100 animated at 40 m: +0.11 ms process, render CPU +1.0 ms, GPU +1.16 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 80 | head top 2.8 m / body_height 2.1 (x1.34) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.81 m | narrower than 0.7 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 1.0 / z 0.77 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1746 px (46 x 67 bbox; 55 m: 896 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 58.9, 0% of the body melts (within dE 15 of the ground); body L* 77.9 C 9.9 vs ground L* 62.5 C 48.4, hue gap n/a (body C* <= 25); top third (world height) dE 63.1, L* 87.2; per-pixel dE 63.2, outline 40.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | **WARN** 50 | dE 17.8, 63% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 85 | worst snow: dE 17.8 (heath dE 41.9, old_wood dE 58.0, riverbank dE 56.4, snow dE 17.8, ash dE 55.6, sand dE 42.7, marsh dE 65.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 31% of body pixels change between kingdom colours (min pair 29%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 39.2 (fire 48.7, shadow 59.6, ice 57.9, nature 39.2) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 74 | worst pair fire / nature (deutan): dE 6.5 on the team-colour area (normal vision 56.4; 612 px); deutan: fire / nature dE 6.5; protan: fire / nature dE 16.9; worst vs ground: fire colour (deutan) dE 34.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -18 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.6 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +18 (point 1 dL +33, point 2 dL +18; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): SnowMotes, Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst ice: dE 54.3, dL +19 (warm dE 58.7, ice dE 54.3, night dE 56.2, autumn dE 55.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.89 (min 0.85), area kept 98-101% (min 1724 px), frame-to-frame IoU min 0.87; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (vessa 0.69, malrik 0.59, rime_colossus 0.49, shardguard 0.45, stormbottle_genie 0.4, hollow_stag 0.33) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.44 m from the body centre at t 0.08 s (2.4 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 99 | strike pose changes 28% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 44% of the silhouette at its peak (t 0.12 s; 0.12 s 44%, 0.25 s 44%, 0.4 s 42%, 0.6 s 33%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 92 shapes over 8 body parts (11.5 per part: LegL 1, LegR 1, Hips 6, Head 47, ArmL 7, Staff 15, ArmR 7, Chest 8); 20% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.92 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 171% of the 3000 verts budget used (5133) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 1.8 at the close-up (92123 px), 1.82 at 25 m; close-up outline complexity 9.65 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.25 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 87.2, bottom third L* 67.6 (+19, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.4 at 25 m, 9.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 54.3, 0% melts; body L* 76.2 C 5.9 vs floor L* 51.2 C 42.4; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 96 | front-view asymmetry 0.19 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 1637 v / 1 s; Root/Chest/Head/Merged 869 v / 5 s; Root/Chest/ArmR/Staff/StaffMesh 632 v / 4 s; Root/Chest/ArmR/Staff/Snowflake/Flake 576 v / 1 s x24; Root/Chest/Merged 543 v / 4 s; Root/Chest/ArmL/Merged 507 v / 6 s; Root/Chest/ArmR/Merged 507 v / 6 s; Root/Hips/Merged 390 v / 5 s
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: shader_parameter/base_color of `torvald_fur_pale` #bdcce0 -> #5580ff (15% of the visible body): predicted dE R3 meadow 58.9 -> 64.3, R3t fire 48.7 -> 55.2, R3t )
