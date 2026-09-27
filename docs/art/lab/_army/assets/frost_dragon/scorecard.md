# Art Lab scorecard: frost_dragon

Scene `res://art/units/titans/frost_dragon/frost_dragon.tscn` · kind **titan** / tier **titan** · kingdom ice · ground meadow · 2026-09-27 09:54:18 · lab v2.0

## Result: **WARN** · quality **96 / 100**

0 FAIL · 2 WARN · 22 PASS · 12 info · 0 skipped · 29 s

## Improve next
1. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 9.2): add a value step inside the team-colour area [fixes.json #1] _(from R6cb Team colours for colour-blind players, shot teams)_
2. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (3/3/3/2/2/3/1/1 per frame): put them on parts the gait does not cover [fixes.json #2] _(from R5w Glow points while walking (flicker), shot glow)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +8 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 39 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 17 drawn (17 mesh + 0 multimesh); per pivot: (root) 1, Body 1, Head 1, Jaw 1, LegBL 1, LegBR 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 91 | 18 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B4 | Vertices | PASS 99 | 8580 (biggest: HeadMesh 1418, BodyMesh 1263, WingL2Mesh 771, WingR2Mesh 771) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 2 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (TailFrost) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 10 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 94 | 10 (HeadMesh, Neck2Mesh, Neck1Mesh, WingL2Mesh, WingLMesh, WingR2Mesh) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 8 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 43 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2243 of 13258 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 2.09 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 5386 px (149 x 106 bbox; 55 m: 2758 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 76.1, 0% of the body melts (within dE 15 of the ground); body L* 63.3 C 25.9 vs ground L* 60.7 C 52.5, hue gap 150 deg; top third (world height) dE 81.3, L* 61.2; per-pixel dE 79.3, outline 55.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 39.4, 20% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 39.4 (heath dE 56.3, old_wood dE 58.2, riverbank dE 55.3, snow dE 39.4, ash dE 47.6, sand dE 60.8, marsh dE 59.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 98 | 23% of body pixels change between kingdom colours (min pair 21%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 54.3 (fire 65.1, shadow 75.4, ice 67.9, nature 54.3) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 42 | worst pair fire / nature (deutan): dE 9.2 on the team-colour area (normal vision 80.7; 1362 px); deutan: fire / nature dE 9.2; protan: fire / nature dE 24.9; worst vs ground: fire colour (deutan) dE 48.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -17 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 6.0 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +26 (point 1 dL +30, point 2 dL +31, point 3 dL +26; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 3/2/1): LegBRMesh, Tail3Mesh, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 4 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.5 (min 0.4), area kept 96-126% (min 6015 px), frame-to-frame IoU min 0.63; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 52 | points per frame 3/3/3/2/2/3/1/1 (median 3, range 2, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 71% of the silhouette (t 0.24 s) | >= 8% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.86 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.28 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 81 | top third L* 70.6, bottom third L* 61.9 (+8, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.6 at 25 m, 14.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1418 v / 4 s; Root/Body/BodyMesh 1263 v / 2 s; Root/Body/WingL/WingL2/WingL2Mesh 771 v / 3 s; Root/Body/WingR/WingR2/WingR2Mesh 771 v / 3 s; Root/Body/WingL/WingLMesh 532 v / 4 s; Root/Body/WingR/WingRMesh 532 v / 4 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 466 v / 4 s; Root/Body/Tail1/Tail2/Tail3/Tail3Mesh 367 v / 2 s
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 2 in fixes.json (top: R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 9.2): add a value step inside)
