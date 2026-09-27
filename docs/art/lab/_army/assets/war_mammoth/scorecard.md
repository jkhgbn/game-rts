# Art Lab scorecard: war_mammoth

Scene `res://art/units/titans/war_mammoth/war_mammoth.tscn` · kind **titan** / tier **titan** · kingdom ice · ground meadow · 2026-09-27 10:02:28 · lab v2.0

## Result: **WARN** · quality **95 / 100**

0 FAIL · 3 WARN · 23 PASS · 11 info · 0 skipped · 30 s

## Improve next
1. **Vertices** (WARN): B4 12660 -> 11967 (want <= 12000): `Merged` 3436 -> 2743 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.9): add a value step inside the team-colour area [fixes.json #2] _(from R6cb Team colours for colour-blind players, shot teams)_
3. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (5/4/4/3/3/3/3/4 per frame): put them on parts the gait does not cover [fixes.json #3] _(from R5w Glow points while walking (flicker), shot glow)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 12% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 38 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 17 drawn (17 mesh + 0 multimesh); per pivot: ArmL 3, Head 2, (root) 1, ArmR 1, Chest 1, Howdah 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 91 | 18 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B3 | keep_separate parts | INFO | 2 | no budget for titan/titan |  |
| B4 | Vertices | **WARN** 49 | 12660 (biggest: Merged 3436, Merged 2340, Frame 2290, Merged 600) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 1 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (FrostMist) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 16 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 94 | 10 (Merged, Merged, Merged, Merged, Merged, Frame) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 19 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 17 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 75 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1842 of 14154 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.032 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 8363 px (118 x 169 bbox; 55 m: 4236 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 60.9, 0% of the body melts (within dE 15 of the ground); body L* 57.4 C 11.3 vs ground L* 61.5 C 50.4, hue gap n/a (body C* <= 25); top third (world height) dE 59.6, L* 62.4; per-pixel dE 66.0, outline 45.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 35.9, 14% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 35.9 (heath dE 41.3, old_wood dE 43.5, riverbank dE 44.7, snow dE 35.9, ash dE 36.0, sand dE 49.7, marsh dE 46.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 85 | 12% of body pixels change between kingdom colours (min pair 11%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 53.1 (fire 57.0, shadow 62.6, ice 59.5, nature 53.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 45 | worst pair fire / nature (deutan): dE 11.9 on the team-colour area (normal vision 59.9; 1124 px); deutan: fire / nature dE 11.9; protan: fire / nature dE 19.8; worst vs ground: fire colour (deutan) dE 45.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -33 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 4.7 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +29 (point 1 dL +29, point 2 dL +31, point 3 dL +30, point 4 dL +34; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/5/4): Merged x3, StringU, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 10 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.89 (min 0.85), area kept 98-101% (min 8176 px), frame-to-frame IoU min 0.83; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 48 | points per frame 5/4/4/3/3/3/3/4 (median 4, range 2, 0 frame(s) at 0; at rest 4) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 25% of the silhouette (t 0.14 s) | >= 8% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.41 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 62.4, bottom third L* 46.8 (+15, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.8 at 25 m, 9.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Root/Mount/Merged 3436 v / 8 s; Root/Mount/Head/Merged 2340 v / 9 s; Root/Mount/Seat/Howdah/Frame 2290 v / 11 s; Root/Mount/Seat/Howdah/Root/Chest/ArmR/Merged 600 v / 6 s; Root/Mount/Head/Trunk/Trunk2/Merged 597 v / 2 s; Root/Mount/Seat/Howdah/Root/Chest/Merged 548 v / 6 s; Root/Mount/Seat/Howdah/Root/Chest/ArmL/Merged 482 v / 5 s; Root/Mount/LegFR/Merged 430 v / 4 s
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B4 12660 -> 11967 (want <= 12000): `Merged` 3436 -> 2743 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
