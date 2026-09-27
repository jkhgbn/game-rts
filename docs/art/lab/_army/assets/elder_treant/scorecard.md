# Art Lab scorecard: elder_treant

Scene `res://art/units/titans/elder_treant/elder_treant.tscn` · kind **titan** / tier **titan** · kingdom nature · ground meadow · 2026-09-27 10:04:05 · lab v2.0

## Result: **WARN** · quality **90 / 100**

0 FAIL · 3 WARN · 24 PASS · 10 info · 0 skipped · 27 s

## Improve next
1. **Vertices** (WARN): B4 12777 -> 11961 (want <= 12000): `HeadMesh` 5409 -> 4593 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Contrast on the home ground (old_wood)** (WARN): R4k Contrast on the home ground (old_wood): On its home ground (old_wood) the body is only dE 19.8: add a value step for that ground [fixes.json #2] _(from R4k Contrast on the home ground (old_wood), shot z40)_
3. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #3] _(from B9m Meshes built per instance)_
4. **Contrast on the other grounds** (PASS): On heath the body drops to dE 12.8: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.5): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 28.0): the top third (what reads from pitch 55) is close to the ground (dE 19.5): lighten helmets / shoulders / back; the body sits in the ground's hue (gap 13 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

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
| B12 | Downward-facing triangles | INFO | 3044 of 19570 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.006 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 4813 px (84 x 109 bbox; 55 m: 2438 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 89 | mean-colour dE 28.0, 16% of the body melts (within dE 15 of the ground); body L* 45.9 C 28.3 vs ground L* 61.5 C 49.9, hue gap 13 deg; top third (world height) dE 19.5, L* 64.7; per-pixel dE 43.5, outline 37.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | **WARN** 53 | dE 19.8, 7% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 79 | worst heath: dE 12.8 (heath dE 12.8, old_wood dE 19.8, riverbank dE 18.6, snow dE 51.0, ash dE 37.3, sand dE 36.6, marsh dE 37.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 88 | 14% of body pixels change between kingdom colours (min pair 11%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 93 | worst nature colour: dE 26.2 (fire 27.1, shadow 28.1, ice 27.1, nature 26.2) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair shadow / ice (deutan): dE 12.3 on the team-colour area (normal vision 16.3; 1211 px); deutan: shadow / ice dE 12.3; protan: shadow / ice dE 14.2; worst vs ground: fire colour (deutan) dE 19.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 3% of the silhouette (gap -11 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 4.7 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +27 (point 1 dL +27, soft 1 dL -1; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): LegRMesh; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.76 (min 0.72), area kept 93-95% (min 4517 px), frame-to-frame IoU min 0.81; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 55% of the silhouette (t 0.14 s) | >= 8% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.81 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.42 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 64.7, bottom third L* 25.7 (+39, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 63 | inner detail 12.5 at 25 m, 15.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10, titans-2.md 11)
`{"draw":20,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":12,"frame_ms":0.02,"verts":12000},"src":"cavalry-mounts.md 10, titans-2.md 11"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/HeadMesh 5409 v / 3 s; Root/Chest/ChestMesh 1743 v / 2 s; Root/Hips/HipsMesh 1389 v / 2 s; Root/Chest/ArmL/ForeL/ForeLMesh 943 v / 2 s; Root/Chest/ArmR/ForeR/ForeRMesh 943 v / 2 s; Root/Chest/ArmL/ArmLMesh 502 v / 2 s; Root/Chest/ArmR/ArmRMesh 502 v / 2 s; Root/Hips/LegL/ShinL/ShinLMesh 413 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- fix recipes: colour not computed (no body material with an albedo among 3 drawn materials)
- Fix recipes: 3 in fixes.json (top: B4 12777 -> 11961 (want <= 12000): `HeadMesh` 5409 -> 4593 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
