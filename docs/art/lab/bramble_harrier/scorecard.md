# Art Lab scorecard: bramble_harrier

Scene `res://art/units/nature/bramble_harrier/bramble_harrier.tscn` · kind **unit** / tier **cavalry_mounted** · kingdom nature · ground meadow · 2026-10-15 17:09:10 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.7) (previous run 93, +0)

0 FAIL · 1 WARN · 30 PASS · 15 info · 0 skipped · 30 s

## Before / after (vs the run of 2026-10-15 16:48:18 in `docs/art/lab/bramble_harrier`: quality 93 -> 93, +0)
### What got worse (4)
1. **R6 Team-colour visibility at 40 m: PASS 100 -> PASS 88 (-12)**. Now: 15% of body pixels change between kingdom colours (min pair 14%). Was: 30% of body pixels change between kingdom colours (min pair 30%)
2. **P4 Detail density 25 m / 40 m: INFO 75 -> INFO 53 (-23) (noisy check: re-run before acting)**. Now: inner detail 12.9 at 25 m, 17.3 at 40 m (mean /grad L*/ per px). Was: inner detail 12.0 at 25 m, 15.9 at 40 m (mean /grad L*/ per px)
3. **R4 Contrast on the other grounds: WARN 40 -> WARN 36 (-4)**. Now: worst heath: dE 6.9 (heath dE 6.9, old_wood dE 31.5, riverbank dE 38.3, snow dE 42.6, ash dE 40.5, sand dE 26.5, marsh dE 41.8). Was: worst heath: dE 9.7 (heath dE 9.7, old_wood dE 34.7, riverbank dE 40.1, snow dE 42.6, ash dE 45.1, sand dE 23.0, marsh d
4. **P1 Silhouette hook: INFO 84 -> INFO 80 (-4)**. Now: outline complexity 2.34. Was: outline complexity 2.39

### What got better (4)
R6cb Team colours for colour-blind players: WARN 37 -> PASS 79 (+42); R3 Contrast vs ground (meadow): PASS 93 -> PASS 95 (+2); P2 Asymmetric secondary shape: INFO 81 -> INFO 83 (+2); S1 Style bible: golden autumn (style-autumn.md 3): INFO 3 -> INFO 7 (+4)

### Score delta per check (11 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C2 | Vertex use vs budget | INFO 87 | INFO 88 | +1.4 |
| R3 | Contrast vs ground (meadow) | PASS 93 | PASS 95 | +2.2 |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | PASS 99 | -0.6 |
| R4 | Contrast on the other grounds | WARN 40 | WARN 36 | -4.0 |
| R6 | Team-colour visibility at 40 m | PASS 100 | PASS 88 | -11.6 |
| R6cb | Team colours for colour-blind players | WARN 37 | PASS 79 | +41.8 |
| P1 | Silhouette hook | INFO 84 | INFO 80 | -3.9 |
| P4 | Detail density 25 m / 40 m | INFO 75 | INFO 53 | -22.6 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 85 | PASS 85 | +0.5 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 3 | INFO 7 | +4.1 |
| P2 | Asymmetric secondary shape | INFO 81 | INFO 83 | +2.4 |

Changed pixels per shot: z40 1.1 %, z55 0.7 %, z25 1.2 %, close 3.6 %, strike_side 2.3 %, turns 4.6 %, cast 1.8 %, anim 3.8 %, silhouette 0.1 %, lineup 1.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `bh_coat` #4d301c -> #4a301b (50% of the visible body): predicted dE R3 meadow 34.3 -> 34.2, R3t fire 40.9 -> 40.8, R3t shadow 44.9 -> 44.7, R3t ice 39.3 -> 39.1, R3t nature 34.3 -> 34.2, R4k old_wood 31.5 -> 31.4 (want >= 24); other grounds heath 6.8, riverbank 38.1, snow 42.7, ash 40.4, sand 26.5, marsh 41.8; team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `nature_cloth` 11% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4 Contrast on the other grounds, shot z40)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.9): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 10.5): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from bramble_harrier_placeholder (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 15% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 34.3): value is close to the ground (dL -6): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 34 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 2, ArmL 1, Chest 1, Hare 1, Head 1, Hips 1 | <= 32 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 20 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 12 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B4 | Vertices | PASS 100 | 4121 (body + face above its allowance: face 1050 v, allowance 1200, total 5171; biggest: Merged 1193, Merged 947, Merged 677, Merged 535) | <= 8500 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6 | Particle systems | PASS 94 | 1 | <= 1 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/cavalry_mounted |  |
| B1a | Authored build parts (before the merge) | INFO | 15 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 32 |  |
| B11 | Surfaces per instance | INFO | 47 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 688 of 7522 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0015 ms process per instance (100 animated at 40 m: +0.15 ms process, render CPU +0.96 ms, GPU +0.18 ms) | <= 0.01 ms per instance (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.001 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.56 / z 1.09 m (radius 0.6, from bramble_harrier.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1102 px (32 x 56 bbox; 55 m: 560 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 95 | mean-colour dE 34.3, 1% of the body melts (within dE 15 of the ground); body L* 55.0 C 26.5 vs ground L* 61.6 C 48.6, hue gap 41 deg; top third (world height) dE 36.6, L* 77.0; per-pixel dE 46.6, outline 35.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 99 | dE 31.5, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | **WARN** 36 | worst heath: dE 6.9 (heath dE 6.9, old_wood dE 31.5, riverbank dE 38.3, snow dE 42.6, ash dE 40.5, sand dE 26.5, marsh dE 41.8) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility at 40 m | PASS 88 | 15% of body pixels change between kingdom colours (min pair 14%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 34.3 (fire 40.9, shadow 44.9, ice 39.3, nature 34.3) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.0 on the team-colour area (normal vision 49.3; 172 px); deutan: fire / nature dE 11.0; protan: fire / nature dE 15.2; worst vs ground: fire colour (deutan) dE 14.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -7 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +23 (soft 1 dL +23 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0), 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 85 | worst night: dE 18.2, dL +8 (warm dE 34.9, ice dE 31.0, night dE 18.2, autumn dE 30.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.72), area kept 92-96% (min 1042 px), frame-to-frame IoU min 0.73; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (bramble_harrier_placeholder 0.63, bloomtender 0.51, greenheart_oathkeeper 0.4, ruin_warden 0.4, bramblehorn 0.39, stormbottle_genie 0.37) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.11 m from the body centre at t 0.08 s (1.08 m forward; geometry clipped at the ground); declared 6.5 m (UnitType attack_range (bramble_harrier.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 9% of the silhouette at its peak (t 0.4 s; 0.12 s 7%, 0.25 s 8%, 0.4 s 9%, 0.6 s 9%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 164 shapes over 10 body parts (16.4 per part: Head 35, LegFL 6, LegFR 6, LegBL 7, LegBR 7, Mount 15, Hips 27, ArmL 4, ArmR 11, Chest 46); 17% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.949 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 88 | 60% of the 8500 verts budget used (5167) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.24 at the close-up (70577 px), 3.41 at 25 m; close-up outline complexity 5.66 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 80 | outline complexity 2.34 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 77.0, bottom third L* 39.0 (+38, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 53 | inner detail 12.9 at 25 m, 17.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 7 | on the autumn floor: dE 10.5, 7% melts; body L* 53.5 C 32.3 vs floor L* 50.3 C 42.0 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 83 | front-view asymmetry 0.17 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene))
`{"draw":20,"face_verts":1200,"frame_ms":0.01,"lights":0,"meshes":32,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":6,"separate":12,"verts":8500},"src":"cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Rider/Root/Chest/Merged 1193 v / 10 s; Hare/Root/Mount/Head/Merged 947 v / 6 s; Hare/Root/Mount/Merged 677 v / 6 s; Rider/Root/Hips/Merged 535 v / 5 s; Hare/Root/Mount/LegBL/Merged 427 v / 2 s; Hare/Root/Mount/LegBR/Merged 427 v / 2 s; Hare/Root/Mount/LegFL/Merged 324 v / 2 s; Hare/Root/Mount/LegFR/Merged 324 v / 2 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: shader_parameter/base_color of `bh_coat` #4d301c -> #4a301b (50% of the visible body): predicted dE R3 meadow 34.3 -> 34.2, R3t fire 40.9 -> 40.8, R3t shadow 44)
