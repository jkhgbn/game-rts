# Art Lab scorecard: plant_glow40_frost_dragon

Scene `res://tools/art_lab/calibration/virtual/plant_glow40_frost_dragon.tscn` · kind **titan** / tier **titan** · kingdom ice · ground meadow · 2026-09-30 18:37:59 · lab v3.1

## Result: **WARN** · quality **94 / 100** (94.0)

0 FAIL · 2 WARN · 22 PASS · 18 info · 0 skipped · 24 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 18 -> 2 (want 1-5): frost_membrane shimmer_energy 1.0 -> 0.13 on WingRMesh, WingL2Mesh, WingLMesh, WingR2Mesh (dim under the bloom level: 16 point(s), peak 5.99 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (23/21/17/18/17/21/27/27 per frame): put them on parts the gait does not cover [fixes.json #2] _(from R5w Glow points while walking (flicker), shot glow)_
3. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 9% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.3): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 40 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 17 drawn (17 mesh + 0 multimesh); per pivot: (root) 1, Body 1, Head 1, Jaw 1, LegBL 1, LegBR 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 91 | 18 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B4 | Vertices | PASS 99 | 8740 (biggest: HeadMesh 1458, BodyMesh 1303, WingL2Mesh 811, WingR2Mesh 811) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 2 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (TailFrost) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 10 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 94 | 10 (HeadMesh, Neck2Mesh, Neck1Mesh, WingL2Mesh, WingLMesh, WingR2Mesh) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 9 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 47 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2232 of 13418 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 1.91 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 6341 px (172 x 111 bbox; 55 m: 3210 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 72.1, 0% of the body melts (within dE 15 of the ground); body L* 65.8 C 22.4 vs ground L* 60.5 C 51.7, hue gap n/a (body C* <= 25); top third (world height) dE 76.7, L* 62.8; per-pixel dE 76.0, outline 54.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 35.2, 18% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 35.2 (heath dE 49.1, old_wood dE 57.1, riverbank dE 51.6, snow dE 35.2, ash dE 48.1, sand dE 56.8, marsh dE 59.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 81 | 9% of body pixels change between kingdom colours (min pair 8%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 38.2 (fire 42.3, shadow 46.8, ice 43.7, nature 38.2) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 75 | worst pair fire / nature (deutan): dE 7.3 on the team-colour area (normal vision 85.1; 591 px); deutan: fire / nature dE 7.3; protan: fire / nature dE 25.1; worst vs ground: fire colour (deutan) dE 33.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 4% of the silhouette (gap -47 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 6.0 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +24 (point 1 dL +31, point 2 dL +24, point 3 dL +31, point 4 dL +35, point 5 dL +34, point 6 dL +34, point 7 dL +34, point 8 dL +31, point 9 dL +52, point 10 dL +34, point 11 dL +42, point 12 dL +43, point 13 dL +33, point 14 dL +32, point 15 dL +44, point 16 dL +28, point 17 dL +31, point 18 dL +38, point 19 dL +29, point 20 dL +32, point 21 dL +34, point 22 dL +34, point 23 dL +32; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 18 point(s) above the bloom level 1.2 (median of 23/18/15): LegBRMesh, Tail3Mesh x2, ? x4, LegFLMesh, WingRMesh x3, HeadMesh x2, JawMesh x2, Neck1Mesh, WingR2Mesh, LegFRMesh, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 8 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): LegBRMesh, Tail3Mesh x2, ? x4, LegFLMesh, WingRMesh x3, HeadMesh x2, JawMesh x2, Neck1Mesh, WingR2Mesh, LegFRMesh |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.35 (min 0.32), area kept 115-155% (min 6149 px), frame-to-frame IoU min 0.6; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 43 | points per frame 23/21/17/18/17/21/27/27 (median 21, range 10, 0 frame(s) at 0; at rest 18) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 3.79 m from the body centre at t 0.14 s (2.01 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 68% of the silhouette (t 0.24 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 69% of the silhouette at its peak (t 0.25 s; 0.12 s 57%, 0.25 s 69%, 0.4 s 60%, 0.6 s 61%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.86 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 181 shapes over 16 body parts (11.3 per part: Jaw 13, Head 38, Neck2 3, Neck1 4, WingL2 19, WingL 8, WingR2 19, WingR 8, Tail3 7, Tail2 4, Tail1 4, LegFL 7, LegFR 7, LegBL 7, LegBR 7, Body 26); 16% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.929 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 72% of the 12000 verts budget used (8736) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 19 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.14 at the close-up (21434 px), 5.12 at 25 m; close-up outline complexity 14.57 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.71 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 71.4, bottom third L* 59.4 (+12, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 67 | inner detail 12.3 at 25 m, 15.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 23 of 23 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- strike_side: [strike_side.jpg](strike_side.jpg)
- turns: [turns.jpg](turns.jpg)
- cast: [cast.jpg](cast.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10, titans-2.md 11)
`{"draw":20,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":12,"frame_ms":0.02,"verts":12000},"src":"cavalry-mounts.md 10, titans-2.md 11"}`

## Notes
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1458 v / 5 s; Root/Body/BodyMesh 1303 v / 3 s; Root/Body/WingL/WingL2/WingL2Mesh 811 v / 4 s; Root/Body/WingR/WingR2/WingR2Mesh 811 v / 4 s; Root/Body/WingL/WingLMesh 532 v / 4 s; Root/Body/WingR/WingRMesh 532 v / 4 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 466 v / 4 s; Root/Body/Tail1/Tail2/Tail3/Tail3Mesh 367 v / 2 s
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 2 in fixes.json (top: Glow points 18 -> 2 (want 1-5): frost_membrane shimmer_energy 1.0 -> 0.13 on WingRMesh, WingL2Mesh, WingLMesh, WingR2Mesh (dim under the bloom level: 16 point(s)
