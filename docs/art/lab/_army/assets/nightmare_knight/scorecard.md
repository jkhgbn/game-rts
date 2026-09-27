# Art Lab scorecard: nightmare_knight

Scene `res://art/units/titans/nightmare_knight/nightmare_knight.tscn` · kind **titan** / tier **titan** · kingdom shadow · ground meadow · 2026-09-27 10:18:37 · lab v2.0

## Result: **WARN** · quality **92 / 100**

0 FAIL · 4 WARN · 22 PASS · 11 info · 0 skipped · 27 s

## Improve next
1. **Vertices** (WARN): B4 17131 -> 11743 (want <= 12000): `Merged` 2821 -> 1411 verts; `Merged` 1957 -> 979 verts; `Merged` 1734 -> 867 verts; `Merged` 1428 -> 714 verts; `Merged` 1428 -> 714 verts; `Merged` 1425 -> 720 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **death_finished** (WARN): A2 death_finished: Emit death_finished at the end of the death timeline (it must fire even at the far distance tier) [fixes.json #2] _(from A2 death_finished)_
3. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (4/5/6/6/5/5/4/4 per frame): put them on parts the gait does not cover [fixes.json #3] _(from R5w Glow points while walking (flicker), shot glow)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +9): darken around them or raise the energy [fixes.json #4] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.5): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 32 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: ArmR 2, Head 2, (root) 1, ArmL 1, Chest 1, LegBL 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 98 | 15 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B3 | keep_separate parts | INFO | 1 | no budget for titan/titan |  |
| B4 | Vertices | **WARN** 35 | 17131 (biggest: Merged 2821, Merged 1957, Merged 1734, Merged 1428) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 2 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (ManeWisps) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 12 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 100 | 4 (Merged, Merged, Merged, Merged) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 15 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 60 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1763 of 13928 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.001 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2669 px (71 x 92 bbox; 55 m: 1358 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 86.5, 0% of the body melts (within dE 15 of the ground); body L* 28.1 C 30.8 vs ground L* 61.2 C 49.5, hue gap 168 deg; top third (world height) dE 102.8, L* 46.9; per-pixel dE 92.5, outline 67.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 36.9, 2% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 97 | worst ash: dE 27.8 (heath dE 62.7, old_wood dE 51.2, riverbank dE 63.7, snow dE 70.6, ash dE 27.8, sand dE 77.8, marsh dE 36.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 99 | 23% of body pixels change between kingdom colours (min pair 20%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 75.6 (fire 78.7, shadow 81.6, ice 78.9, nature 75.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 89 | worst pair fire / nature (deutan): dE 20.1 on the team-colour area (normal vision 34.6; 876 px); deutan: fire / nature dE 20.1; protan: fire / ice dE 22.9; worst vs ground: nature colour (deutan) dE 61.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -15 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 4.05 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 60 | worst dL +9 (point 1 dL +29, point 2 dL +40, point 3 dL +63, point 4 dL +59, point 5 dL +9; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 5 point(s) above the bloom level 1.2 (median of 5/5/4): Merged x4, Lance; soft glows under the bloom (v1 count, luma > 0.4): 5 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.82 (min 0.78), area kept 96-102% (min 2582 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 48 | points per frame 4/5/6/6/5/5/4/4 (median 5, range 2, 0 frame(s) at 0; at rest 5) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 31% of the silhouette (t 0.14 s) | >= 8% (1 - IoU rest vs strike) |  |
| A2 | death_finished | **WARN** 45 | after 2.38 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) | Emit death_finished at the end of the death timeline (it must fire even at the far distance tier) |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.8 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 46.9, bottom third L* 33.4 (+13, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.5 at 25 m, 21.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Root/Mount/Merged 2821 v / 7 s; Root/Chest/Head/Merged 1957 v / 4 s; Root/Mount/Neck/Merged 1734 v / 4 s; Root/Mount/LegBL/Merged 1428 v / 4 s; Root/Mount/LegBR/Merged 1428 v / 4 s; Root/Chest/Merged 1425 v / 6 s; Root/Mount/LegFL/Merged 1399 v / 4 s; Root/Mount/LegFR/Merged 1399 v / 4 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B4 17131 -> 11743 (want <= 12000): `Merged` 2821 -> 1411 verts; `Merged` 1957 -> 979 verts; `Merged` 1734 -> 867 verts; `Merged` 1428 -> 714 verts; `Merged` 142)
