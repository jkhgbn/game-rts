# Art Lab scorecard: cinder_dragon

Scene `res://art/units/titans/cinder_dragon/cinder_dragon.tscn` · kind **titan** / tier **titan** · kingdom fire · ground meadow · 2026-09-30 11:56:27 · lab v3.1

## Result: **WARN** · quality **89 / 100** (89.0)

0 FAIL · 3 WARN · 25 PASS · 20 info · 0 skipped · 52 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 7 -> 3 (want 1-5): cinder_scale lava_energy 2.6 -> 0.34 on LegFLMesh, Tail2Mesh, LegBRMesh (dim under the bloom level: 4 point(s), peak 5.68 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #2] _(from B9m Meshes built per instance)_
3. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (10/14/14/11/14/14/13/6 per frame): put them on parts the gait does not cover [fixes.json #3] _(from R5w Glow points while walking (flicker), shot glow)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -48 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.3): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from frost_dragon (IoU 0.76): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B12 | Downward-facing triangles | INFO | 2274 of 14326 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0029 ms process per instance (12 animated at 40 m: +0.03 ms process, render CPU +0.52 ms, GPU +0.29 ms) | <= 0.02 ms per instance soft (cavalry-mounts.md 10, titans-2.md 11) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 2.28 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 4959 px (116 x 132 bbox; 55 m: 2459 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 64.1, 0% of the body melts (within dE 15 of the ground); body L* 34.2 C 37.9 vs ground L* 61.2 C 52.2, hue gap 78 deg; top third (world height) dE 62.9, L* 35.6; per-pixel dE 73.5, outline 64.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 34.5, 3% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 30.6 (heath dE 37.6, old_wood dE 38.3, riverbank dE 50.1, snow dE 66.4, ash dE 34.5, sand dE 52.8, marsh dE 30.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 80 | 8% of body pixels change between kingdom colours (min pair 8%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 34.1 (fire 37.7, shadow 41.2, ice 36.7, nature 34.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.8 on the team-colour area (normal vision 56.7; 427 px); deutan: fire / nature dE 14.8; protan: fire / nature dE 15.9; worst vs ground: fire colour (deutan) dE 22.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -65 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 5.9 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 85 | worst dL +1 (point 1 dL +23, point 2 dL +32, point 3 dL +9, point 4 dL +3, point 5 dL +29, point 6 dL +60, point 7 dL +7, point 8 dL +1, point 9 dL +5, point 10 dL +10; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 7 point(s) above the bloom level 1.2 (median of 10/7/6): Tail3Mesh x2, WingLMesh x2, LegBRMesh, LegFLMesh, LegBLMesh, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Tail3Mesh x2, WingLMesh x2, LegBRMesh, LegFLMesh, LegBLMesh |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 43.8, dL +1 (warm dE 61.7, ice dE 54.9, night dE 43.8, autumn dE 57.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.48 (min 0.37), area kept 102-137% (min 6116 px), frame-to-frame IoU min 0.5; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 52 | points per frame 10/14/14/11/14/14/13/6 (median 14, range 8, 0 frame(s) at 0; at rest 7) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |
| R2 | Distinct from references (black masks) | PASS 79 | max IoU 0.76 (frost_dragon 0.76, roc 0.21, frost_wyrm 0.21, elder_treant 0.2, war_mammoth 0.2, nightmare_knight 0.14); wing phase matched to the target's (p 0.16; residual per flyer ref: frost_wyrm 0.02, roc 0.0, frost_dragon 0.0) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 4.51 m from the body centre at t 0.24 s (2.3 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 71% of the silhouette (t 0.36 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 64% of the silhouette at its peak (t 0.25 s; 0.12 s 51%, 0.25 s 64%, 0.4 s 62%, 0.6 s 54%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.85 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 96 | 137 shapes over 16 body parts (8.6 per part: Jaw 13, Head 29, Neck2 3, Neck1 4, WingL2 9, WingL 8, WingR2 9, WingR 8, Tail3 6, Tail2 4, Tail1 4, LegFL 7, LegFR 7, LegBL 7, LegBR 7, Body 12); 9% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.91 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 78% of the 12000 verts budget used (9472) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 20 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.48 at the close-up (32062 px), 5.13 at 25 m; close-up outline complexity 8.42 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.88 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 35.6, bottom third L* 83.7 (-48, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.3 at 25 m, 20.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 10 of 10 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 44 | on the autumn floor: dE 22.0, 1% melts; body L* 39.4 C 45.6 vs floor L* 46.8 C 40.4; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.21 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1698 v / 4 s; Root/Body/BodyMesh 1277 v / 2 s; Root/Body/WingR/WingR2/WingR2Mesh 771 v / 3 s; Root/Body/WingL/WingL2/WingL2Mesh 771 v / 3 s; Root/Body/Tail1/Tail2/Tail3/Tail3Mesh 667 v / 4 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 568 v / 3 s; Root/Body/WingL/WingLMesh 566 v / 3 s; Root/Body/WingR/WingRMesh 566 v / 3 s
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: Glow points 7 -> 3 (want 1-5): cinder_scale lava_energy 2.6 -> 0.34 on LegFLMesh, Tail2Mesh, LegBRMesh (dim under the bloom level: 4 point(s), peak 5.68 x the l)
