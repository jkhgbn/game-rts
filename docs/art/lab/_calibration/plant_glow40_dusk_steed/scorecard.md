# Art Lab scorecard: plant_glow40_dusk_steed

Scene `res://tools/art_lab/calibration/virtual/plant_glow40_dusk_steed.tscn` · kind **mount** / tier **mount** · kingdom shadow · ground meadow · 2026-09-27 09:35:44 · lab v2.0

## Result: **WARN** · quality **94 / 100**

0 FAIL · 1 WARN · 21 PASS · 9 info · 0 skipped · 22 s

## Improve next
1. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.1): add a value step inside the team-colour area [fixes.json #1] _(from R6cb Team colours for colour-blind players, shot teams)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (22.5): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +9 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Contrast on the other grounds** (PASS): On ash the body drops to dE 27.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 20 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, Head 1, LegBL 1, LegBR 1, LegFL 1, LegFR 1 | <= 12 (cavalry-mounts.md 10 (mount)) |  |
| B2 | Draw instances at rest | PASS 88 | 8 | <= 8 (cavalry-mounts.md 10 (mount)) |  |
| B4 | Vertices | PASS 86 | 5929 (biggest: Merged 2389, Merged 1747, Merged 402, Merged 402) | <= 6000 soft (cavalry-mounts.md 10 (mount)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (mount)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (cavalry-mounts.md 10 (mount)) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 2 soft (cavalry-mounts.md 10 (mount)) |  |
| B8 | Unique materials | INFO | 13 | no budget for mount/mount |  |
| B1a | Authored build parts (before the merge) | INFO | 8 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 12 |  |
| B11 | Surfaces per instance | INFO | 35 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 712 of 6884 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.009 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.48 / z 1.55 m (radius 0.7, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 816 px (37 x 54 bbox; 55 m: 417 px) | >= 150 px (FAIL < 60) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 81.4, 0% of the body melts (within dE 15 of the ground); body L* 34.9 C 29.0 vs ground L* 62.2 C 48.7, hue gap 161 deg; top third (world height) dE 85.5, L* 31.6; per-pixel dE 90.3, outline 73.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 37.2, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 97 | worst ash: dE 27.4 (heath dE 48.2, old_wood dE 48.6, riverbank dE 61.8, snow dE 63.2, ash dE 27.4, sand dE 71.7, marsh dE 37.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 94 | 20% of body pixels change between kingdom colours (min pair 18%) | >= 2% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.9 (fire 66.6, shadow 78.5, ice 67.4, nature 57.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 44 | worst pair fire / nature (deutan): dE 11.1 on the team-colour area (normal vision 69.9; 175 px); deutan: fire / nature dE 11.1; protan: fire / nature dE 20.4; worst vs ground: fire colour (deutan) dE 47.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0), + 1 glowing surface(s); soft glows under the bloom (v1 count, luma > 0.4): 1 | 0-2 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.82 (min 0.78), area kept 98-102% (min 810 px), frame-to-frame IoU min 0.81; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 150 px (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 8 present | set_team_color, set_moving, play_hit, play_death, signal:death_finished, set_barded, play_charge, seat_transform |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.22 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 83 | top third L* 31.6, bottom third L* 22.4 (+9, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 22.5 at 25 m, 31.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (mount))
`{"draw":8,"frame_ms":0.005,"lights":0,"meshes":12,"n":50,"runtime_mats":0,"soft":{"casters":2,"looping":1,"verts":6000},"src":"cavalry-mounts.md 10 (mount)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 2389 v / 7 s; Root/Mount/Head/Merged 1747 v / 8 s; Root/Mount/LegBL/Merged 402 v / 4 s; Root/Mount/LegBR/Merged 402 v / 4 s; Root/Mount/LegFL/Merged 339 v / 4 s; Root/Mount/LegFR/Merged 339 v / 4 s; Root/Mount/Tail/Merged 307 v / 3 s; Shadow 4 v / 1 s
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 1 in fixes.json (top: R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.1): add a value step insid)
