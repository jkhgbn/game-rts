# Art Lab scorecard: greenheart_oathkeeper

Scene `res://art/units/nature/greenheart_oathkeeper/greenheart_oathkeeper.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-09-27 18:01:38 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.7) (previous run 93, +0)

0 FAIL · 1 WARN · 31 PASS · 17 info · 0 skipped · 35 s

## Before / after (vs the run of 2026-09-27 17:58:35 in `docs/art/lab/greenheart_oathkeeper`: quality 93 -> 93, +0)
### What got worse (0)
Nothing got worse.

gone P5 Glow placement (was INFO)

### Score delta per check (4 changed, 49 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| P3 | Tops light, bottoms dark | INFO 99 | INFO 100 | +1.5 |
| R5c | Glow points stand out (1 m surround) | PASS 93 | PASS 95 | +2.0 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 75 | PASS 84 | +8.3 (noisy) |
| B13 | Frame cost | PASS 99 | PASS 90 | -9.3 (noisy) |

Changed pixels per shot: z40 0.0 %, z55 0.0 %, z25 0.0 %, close 0.1 %, strike_side 2.4 %, turns 0.0 %, cast 0.4 %, anim 0.8 %, silhouette 0.0 %, lineup 4.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `nature_bark_dark` #2e2414 -> #302515 (40% of the visible body): predicted dE R3 meadow 27.6 -> 27.6, R3t fire 48.4 -> 48.3, R3t shadow 62.1 -> 62.1, R3t ice 42.9 -> 42.9, R3t nature 27.6 -> 27.6, R4k old_wood 27.7 -> 27.7 (want >= 24); other grounds heath 6.4, riverbank 31.0, snow 42.3, ash 40.3, sand 27.6, marsh 42.4; `nature_bark_dark` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `nature_bark_sap.tres` (#382514, dE 5.0 from the wanted colour); team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `nature_cloth` 13% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4 Contrast on the other grounds, shot z40)_
2. **Vertex use vs budget** (INFO): Only 54% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.86): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 17.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 27.6): value is close to the ground (dL -8): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast under every light preset (meadow)** (PASS): Under the night light the body drops to dE 14.5: add a value step (light top / pale crest) that survives a dim light _(from R12 Contrast under every light preset (meadow), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Chest 2, (root) 1, ArmL 1, ArmR 1, Head 1, Hips 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 100 | 3253 (biggest: Merged 1080, Merged 429, Merged 381, Merged 329) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 59 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 789 of 4311 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 90 | 0.0039 ms process per instance (100 animated at 40 m: +0.39 ms process, render CPU +1.9 ms, GPU +1.16 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.022 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 89 | head top 2.36 m / body_height 2.0 (x1.18) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.91 / z 0.98 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 779 px (39 x 45 bbox; 55 m: 400 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 89 | mean-colour dE 27.6, 5% of the body melts (within dE 15 of the ground); body L* 54.6 C 24.6 vs ground L* 62.8 C 47.9, hue gap n/a (body C* <= 25); top third (world height) dE 25.3, L* 63.2; per-pixel dE 44.1, outline 42.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 95 | dE 27.7, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | **WARN** 36 | worst heath: dE 6.4 (heath dE 6.4, old_wood dE 27.7, riverbank dE 31.0, snow dE 42.3, ash dE 40.3, sand dE 27.7, marsh dE 42.4) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility at 40 m | PASS 100 | 30% of body pixels change between kingdom colours (min pair 30%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 95 | worst nature colour: dE 27.6 (fire 48.4, shadow 62.1, ice 42.9, nature 27.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.5 on the team-colour area (normal vision 80.1; 241 px); deutan: fire / nature dE 11.5; protan: fire / nature dE 23.6; worst vs ground: fire colour (deutan) dE 17.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +35 (soft 1 dL +35 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 0/1/1): HeartKnot; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 81 | worst night: dE 14.5, dL +4 (warm dE 28.2, ice dE 25.2, night dE 14.5, autumn dE 25.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.83 (min 0.7), area kept 95-108% (min 756 px), frame-to-frame IoU min 0.75; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 84 | points per frame 1/1/1/1/0/0/1/1 (median 1, range 1, 2 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.45 (thornling 0.45, vinelasher 0.42, glade_outrider 0.33, bramblehorn 0.25) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.61 m from the body centre at t 0.14 s (1.54 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 48% of the silhouette at its peak (t 0.6 s; 0.12 s 46%, 0.25 s 47%, 0.4 s 48%, 0.6 s 48%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 75 | 85 shapes over 7 body parts (12.1 per part: LegL 5, LegR 5, Hips 12, Head 9, ArmL 8, ArmR 12, Chest 34); 36% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.862 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 69 | 54% of the 6000 verts budget used (3249) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.64 at the close-up (75248 px), 2.13 at 25 m; close-up outline complexity 5.78 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.46 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 63.2, bottom third L* 51.0 (+12, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.9 at 25 m, 15.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 25 | on the autumn floor: dE 17.3, 1% melts; body L* 52.4 C 26.9 vs floor L* 52.0 C 42.9 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.4 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 1080 v / 6 s; Root/Chest/ArmR/Merged 429 v / 5 s; Root/Chest/Head/Merged 381 v / 7 s; Root/Hips/Merged 329 v / 5 s; Root/Chest/ArmL/Merged 304 v / 4 s; Root/Hips/LegL/Merged 259 v / 2 s; Root/Hips/LegR/Merged 259 v / 2 s; Root/Chest/HeartKnot 208 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: shader_parameter/base_color of `nature_bark_dark` #2e2414 -> #302515 (40% of the visible body): predicted dE R3 meadow 27.6 -> 27.6, R3t fire 48.4 -> 48.3, R3t )
