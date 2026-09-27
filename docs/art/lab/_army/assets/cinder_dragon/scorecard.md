# Art Lab scorecard: cinder_dragon

Scene `res://art/units/titans/cinder_dragon/cinder_dragon.tscn` · kind **titan** / tier **titan** · kingdom fire · ground meadow · 2026-09-27 09:46:16 · lab v2.0

## Result: **WARN** · quality **86 / 100**

0 FAIL · 4 WARN · 21 PASS · 12 info · 0 skipped · 32 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 9 -> 5 (want 1-5): cinder_membrane ember_energy 1.0 -> 0.2 (dim under the bloom level: 4 point(s), peak 3.67 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #2] _(from B9m Meshes built per instance)_
3. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (9/14/15/11/11/12/14/11 per frame): put them on parts the gait does not cover [fixes.json #3] _(from R5w Glow points while walking (flicker), shot glow)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 4 glow point(s) barely stand out from their 1 m surround (worst dL +0): darken around them or raise the energy [fixes.json #4] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -46 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
6. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.8): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 39 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 17 drawn (17 mesh + 0 multimesh); per pivot: (root) 1, Body 1, Head 1, Jaw 1, LegBL 1, LegBR 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 91 | 18 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B4 | Vertices | PASS 96 | 9476 (biggest: HeadMesh 1698, BodyMesh 1277, WingR2Mesh 771, WingL2Mesh 771) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 2 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (SpadeEmbers) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 10 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 94 | 10 (HeadMesh, Neck2Mesh, Neck1Mesh, WingL2Mesh, WingLMesh, WingR2Mesh) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 8 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 42 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2275 of 14326 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 2.27 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 5427 px (133 x 130 bbox; 55 m: 2733 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 62.2, 0% of the body melts (within dE 15 of the ground); body L* 37.5 C 40.2 vs ground L* 61.2 C 51.8, hue gap 76 deg; top third (world height) dE 61.6, L* 37.0; per-pixel dE 72.2, outline 63.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 38.4, 2% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 34.4 (heath dE 36.5, old_wood dE 40.7, riverbank dE 48.5, snow dE 64.7, ash dE 38.4, sand dE 49.6, marsh dE 34.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 87 | 13% of body pixels change between kingdom colours (min pair 12%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 31.7 (fire 35.4, shadow 38.6, ice 34.2, nature 31.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 13.7 on the team-colour area (normal vision 34.2; 1016 px); deutan: fire / nature dE 13.7; protan: fire / nature dE 14.0; worst vs ground: nature colour (deutan) dE 20.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -65 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 5.9 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 48 | worst dL +0 (point 1 dL +37, point 2 dL +29, point 3 dL +0, point 4 dL +3, point 5 dL +11, point 6 dL +55, point 7 dL +13; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 9 point(s) above the bloom level 1.2 (median of 7/12/9): Tail3Mesh, LegFLMesh x2, LegBRMesh, HeadMesh, Neck2Mesh, Tail2Mesh, JawMesh x2, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Tail3Mesh, LegFLMesh x2, LegBRMesh, HeadMesh, Neck2Mesh, Tail2Mesh, JawMesh x2 |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.5 (min 0.38), area kept 99-135% (min 5920 px), frame-to-frame IoU min 0.52; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 39 | points per frame 9/14/15/11/11/12/14/11 (median 12, range 6, 0 frame(s) at 0; at rest 9) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 69% of the silhouette (t 0.36 s) | >= 8% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.85 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.82 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 37.0, bottom third L* 83.9 (-46, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.8 at 25 m, 19.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 6 of 7 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1698 v / 4 s; Root/Body/BodyMesh 1277 v / 2 s; Root/Body/WingR/WingR2/WingR2Mesh 771 v / 3 s; Root/Body/WingL/WingL2/WingL2Mesh 771 v / 3 s; Root/Body/Tail1/Tail2/Tail3/Tail3Mesh 667 v / 4 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 568 v / 3 s; Root/Body/WingL/WingLMesh 566 v / 3 s; Root/Body/WingR/WingRMesh 566 v / 3 s
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: Glow points 9 -> 5 (want 1-5): cinder_membrane ember_energy 1.0 -> 0.2 (dim under the bloom level: 4 point(s), peak 3.67 x the level))
