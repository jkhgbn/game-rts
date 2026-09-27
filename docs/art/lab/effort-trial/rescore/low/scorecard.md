# Art Lab scorecard: low

Scene `res://art/units/_effort_trial/low/vinelasher.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-27 12:05:02 · lab v3.1

## Result: **WARN** · quality **87 / 100** (87.1)

0 FAIL · 1 WARN · 31 PASS · 15 info · 0 skipped · 32 s

## Before / after (vs the run of 2026-09-27 10:53:24 in `docs/art/lab/effort-trial/low`: quality 95 -> 87, -8)
### What got worse (0)
Nothing got worse.

new C1 Shape richness (secondary shapes) (INFO); new C2 Vertex use vs budget (INFO); new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new A3r Weapon reach at the strike (PASS)

### Score delta per check (2 changed, 42 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R12 | Contrast under every light preset (meadow) | PASS 78 | PASS 79 | +0.5 |
| B13 | Frame cost | PASS 100 | PASS 97 | -3.1 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.0 %, z25 0.1 %, close 0.9 %, turns 0.4 %, anim 1.8 %, silhouette 17.1 %, lineup 16.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the home ground (old_wood)** (WARN): shader_parameter/base_color of `nature_sec_slinger_c` #bd8038 -> #ffb510 (17% of the visible body): predicted dE R3 meadow 31.9 -> 28.3, R3t fire 51.9 -> 47.8, R3t shadow 66.3 -> 58.8, R3t ice 46.5 -> 41.9, R3t nature 31.0 -> 27.4, R4k old_wood 17.7 -> 24.0 (want >= 24); other grounds heath 18.9, riverbank 31.0, snow 51.0, ash 39.5, sand 32.8, marsh 38.6; shared material (res://art/units/nature/materials/nature_sec_slinger_c.tres): give low its own copy first, other assets use it too; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `nature_cloth` 20% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4k Contrast on the home ground (old_wood), shot z40)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: only 3.4 shapes per body part (aim >= 7): add secondary / tertiary shapes (straps, plates, bark ridges, cuffs, knuckles, a collar) on LegL, LegR, ArmL, Chest; 57% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.86): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Vertex use vs budget** (INFO): Only 38% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
4. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (1.46 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
5. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 9 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 15.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: ArmR 2, (root) 1, ArmL 1, Chest 1, Head 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 969 (biggest: Merged 261, Merged 175, Merged 126, Merged 101) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 11 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 21 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 184 of 1250 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 97 | 0.0026 ms process per instance (100 animated at 40 m: +0.26 ms process, render CPU +1.04 ms, GPU +0.18 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 98 | head top 1.85 m / body_height 1.8 (x1.03) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.55 / z 0.29 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 363 px (20 x 35 bbox; 55 m: 180 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 31.9, 2% of the body melts (within dE 15 of the ground); body L* 44.5 C 24.8 vs ground L* 63.2 C 47.8, hue gap n/a (body C* <= 25); top third (world height) dE 19.6, L* 54.8; per-pixel dE 49.4, outline 41.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | **WARN** 50 | dE 17.7, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 82 | worst heath: dE 15.4 (heath dE 15.4, old_wood dE 17.7, riverbank dE 25.9, snow dE 50.7, ash dE 33.1, sand dE 37.1, marsh dE 33.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 34% of body pixels change between kingdom colours (min pair 33%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 99 | worst nature colour: dE 31.0 (fire 51.9, shadow 66.3, ice 46.5, nature 31.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 12.7 on the team-colour area (normal vision 75.2; 127 px); deutan: fire / nature dE 12.7; protan: fire / nature dE 24.6; worst vs ground: nature colour (deutan) dE 24.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 1 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.3 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +28 (soft 1 dL +28 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 79 | worst night: dE 13.2, dL -3 (warm dE 31.6, ice dE 28.8, night dE 13.2, autumn dE 28.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 91 | walk frames vs rest: mean IoU 0.69 (min 0.59), area kept 93-100% (min 338 px), frame-to-frame IoU min 0.56; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 97 | max IoU 0.5 (thornling 0.5, burr_slinger 0.44, bramblehorn 0.11) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | PASS 100 | tip reaches 3.23 m from the body centre at t 0.24 s (3.23 m forward; geometry clipped at the ground); declared 3.0 m (reach= (brief)) | the strike frame shows the weapon tip at >= 80% of the declared reach, above the ground (side frames: strike_side.jpg) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 56% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 21 | 24 shapes over 7 body parts (3.4 per part: LegL 2, LegR 2, Hips 7, Head 3, ArmL 2, ArmR 6, Chest 2); 57% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.864 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 25 | 38% of the 2500 verts budget used (965) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 70 | 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 39 | inner edges per outline px: 1.46 at the close-up (83945 px), 1.19 at 25 m; close-up outline complexity 8.51 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.82 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 54.8, bottom third L* 9.7 (+45, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.7 at 25 m, 15.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 34 | on the autumn floor: dE 20.7, 0% melts; body L* 42.7 C 26.5 vs floor L* 52.0 C 43.3 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.39 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- strike_side: [strike_side.jpg](strike_side.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/ArmR/Merged 261 v / 4 s; Root/Hips/Merged 175 v / 1 s; Root/Chest/Head/Merged 126 v / 3 s; Root/Chest/Merged 101 v / 2 s; Root/Chest/ArmR/Coil 91 v / 1 s; Root/Chest/ArmL/Merged 79 v / 2 s; Root/Hips/LegL/Merged 66 v / 1 s; Root/Hips/LegR/Merged 66 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: shader_parameter/base_color of `nature_sec_slinger_c` #bd8038 -> #ffb510 (17% of the visible body): predicted dE R3 meadow 31.9 -> 28.3, R3t fire 51.9 -> 47.8, )
