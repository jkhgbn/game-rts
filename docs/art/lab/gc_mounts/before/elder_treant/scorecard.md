# Art Lab scorecard: elder_treant

Scene `res://art/units/titans/elder_treant/elder_treant.tscn` · kind **titan** / tier **titan** · kingdom nature · ground meadow · 2026-10-15 12:40:58 · lab v3.1

## Result: **WARN** · quality **90 / 100** (89.8)

0 FAIL · 4 WARN · 26 PASS · 18 info · 0 skipped · 31 s

## Improve next
1. **Team-colour visibility at 40 m** (WARN): R6 Team-colour visibility at 40 m: Give the team colour more top-facing area (now 3% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top [fixes.json #1] _(from R6 Team-colour visibility at 40 m, shot teams)_
2. **Contrast on the home ground (old_wood)** (WARN): R4k Contrast on the home ground (old_wood): On its home ground (old_wood) the body is only dE 19.0: add a value step for that ground [fixes.json #3] _(from R4k Contrast on the home ground (old_wood), shot z40)_
3. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #4] _(from B9m Meshes built per instance)_
4. **Vertices** (WARN): B4 12777 -> 11961 (want <= 12000): `HeadMesh` 5409 -> 4593 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (13.1): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 13.6: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 36 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, ForeL 1, ForeR 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 100 | 13 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B4 | Vertices | **WARN** 48 | 12777 (biggest: HeadMesh 5409, ChestMesh 1743, HipsMesh 1389, ForeLMesh 943) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 2 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (Petals) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 8 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 90 | 11 (ShinLMesh, LegLMesh, ShinRMesh, LegRMesh, HipsMesh, HeadMesh) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 6 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 3051 of 19570 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (12 animated at 40 m: +-0.05 ms process, render CPU +0.11 ms, GPU +0.49 ms) | <= 0.02 ms per instance soft (cavalry-mounts.md 10, titans-2.md 11) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.01 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 4841 px (86 x 110 bbox; 55 m: 2449 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 90 | mean-colour dE 28.5, 15% of the body melts (within dE 15 of the ground); body L* 45.1 C 28.3 vs ground L* 61.6 C 49.9, hue gap 13 deg; top third (world height) dE 19.4, L* 63.7; per-pixel dE 43.9, outline 36.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | **WARN** 52 | dE 19.0, 7% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 79 | worst heath: dE 13.6 (heath dE 13.6, old_wood dE 19.0, riverbank dE 18.3, snow dE 51.5, ash dE 36.4, sand dE 37.3, marsh dE 36.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | **WARN** 40 | 3% of body pixels change between kingdom colours (min pair 2%) | >= 8% (FAIL = set_team_color changes nothing) | Put the team colour on a big, top-facing mass (cloth, plates, cape, caparison); ~25-45 %% of the surface (art-keep 0.2 / art-units 1.3) |
| R3t | Contrast in every team colour (meadow) | PASS 95 | worst nature colour: dE 27.5 (fire 28.8, shadow 29.5, ice 28.4, nature 27.5) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 15.1 on the team-colour area (normal vision 50.7; 225 px); deutan: fire / nature dE 15.1; protan: fire / nature dE 22.0; worst vs ground: fire colour (deutan) dE 20.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 3% of the silhouette (gap -11 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 4.7 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +25 (point 1 dL +43, soft 1 dL +25 (counts), soft 2 dL +34 (counts), soft 3 dL +42 (counts); ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): LegRMesh; soft glows under the bloom (v1 count, luma > 0.4): 4 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 76 | worst night: dE 10.4, dL +0 (warm dE 28.5, ice dE 25.8, night dE 10.4, autumn dE 25.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.76 (min 0.73), area kept 93-95% (min 4512 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.39 (roc 0.39, war_mammoth 0.37, nightmare_knight 0.36, frost_dragon 0.33, cinder_dragon 0.31, frost_wyrm 0.22) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 3.1 m from the body centre at t 0.08 s (2.94 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 55% of the silhouette (t 0.14 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 48% of the silhouette at its peak (t 0.25 s; 0.12 s 26%, 0.25 s 48%, 0.4 s 43%, 0.6 s 27%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.81 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 181 shapes over 11 body parts (16.5 per part: ShinL 6, LegL 3, ShinR 6, LegR 3, Hips 19, Head 81, ForeL 15, ArmL 7, ForeR 15, ArmR 7, Chest 19); 0% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.958 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 106% of the 12000 verts budget used (12773) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 9.26 at the close-up (93001 px), 5.39 at 25 m; close-up outline complexity 9.12 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.4 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 63.7, bottom third L* 25.2 (+38, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 47 | inner detail 13.1 at 25 m, 15.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 31 | on the autumn floor: dE 19.5, 0% melts; body L* 42.9 C 28.6 vs floor L* 49.0 C 41.2 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.22 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10, titans-2.md 11)
`{"draw":20,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":12,"frame_ms":0.02,"verts":12000},"src":"cavalry-mounts.md 10, titans-2.md 11"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/HeadMesh 5409 v / 3 s; Root/Chest/ChestMesh 1743 v / 2 s; Root/Hips/HipsMesh 1389 v / 2 s; Root/Chest/ArmL/ForeL/ForeLMesh 943 v / 2 s; Root/Chest/ArmR/ForeR/ForeRMesh 943 v / 2 s; Root/Chest/ArmL/ArmLMesh 502 v / 2 s; Root/Chest/ArmR/ArmRMesh 502 v / 2 s; Root/Hips/LegL/ShinL/ShinLMesh 413 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- fix recipes: colour not computed (no body material with an albedo among 3 drawn materials)
- Fix recipes: 4 in fixes.json (top: R6 Team-colour visibility at 40 m: Give the team colour more top-facing area (now 3% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top)
