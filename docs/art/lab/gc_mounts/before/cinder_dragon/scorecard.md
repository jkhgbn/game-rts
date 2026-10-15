# Art Lab scorecard: cinder_dragon

Scene `res://art/units/titans/cinder_dragon/cinder_dragon.tscn` · kind **titan** / tier **titan** · kingdom fire · ground meadow · 2026-10-15 12:39:41 · lab v3.1

## Result: **WARN** · quality **95 / 100** (94.5)

0 FAIL · 1 WARN · 27 PASS · 20 info · 0 skipped · 39 s

## Improve next
1. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #1] _(from B9m Meshes built per instance)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +2 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from frost_dragon (IoU 0.77): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 24.7): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (11.4): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

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
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (12 animated at 40 m: +-0.25 ms process, render CPU +0.32 ms, GPU +0.77 ms) | <= 0.02 ms per instance soft (cavalry-mounts.md 10, titans-2.md 11) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 2.26 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 5181 px (129 x 115 bbox; 55 m: 2635 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 64.8, 0% of the body melts (within dE 15 of the ground); body L* 32.2 C 35.2 vs ground L* 60.5 C 52.2, hue gap 81 deg; top third (world height) dE 67.4, L* 21.2; per-pixel dE 74.4, outline 61.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 32.1, 2% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 97 | worst marsh: dE 27.9 (heath dE 36.8, old_wood dE 35.9, riverbank dE 47.5, snow dE 66.5, ash dE 32.1, sand dE 53.4, marsh dE 27.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 25% of body pixels change between kingdom colours (min pair 25%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 45.4 (fire 58.6, shadow 68.9, ice 54.4, nature 45.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 84 | worst pair fire / nature (deutan): dE 15.6 on the team-colour area (normal vision 63.5; 1340 px); deutan: fire / nature dE 15.6; protan: fire / nature dE 17.2; worst vs ground: fire colour (deutan) dE 27.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 2% of the silhouette (gap -23 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 5.9 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +31 (point 1 dL +31, point 2 dL +34; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 2/3/4): Tail2Mesh, LegFRMesh, JawMesh, 2 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 9 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 42.2, dL -2 (warm dE 64.2, ice dE 56.5, night dE 42.2, autumn dE 60.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.49 (min 0.39), area kept 96-133% (min 5961 px), frame-to-frame IoU min 0.61; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 3/4/3/3/3/3/3/2 (median 3, range 2, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 78 | max IoU 0.77 (frost_dragon 0.77, war_mammoth 0.27, elder_treant 0.25, roc 0.23, frost_wyrm 0.2, nightmare_knight 0.2); wing phase matched to the target's (p 0.61; residual per flyer ref: frost_wyrm 0.01, roc 0.0, frost_dragon 0.0) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 4.77 m from the body centre at t 0.14 s (2.04 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 71% of the silhouette (t 0.14 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 65% of the silhouette at its peak (t 0.6 s; 0.12 s 49%, 0.25 s 59%, 0.4 s 50%, 0.6 s 65%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.86 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 91 | 137 shapes over 16 body parts (8.6 per part: Jaw 13, Head 29, Neck2 3, Neck1 4, WingL2 9, WingL 8, WingR2 9, WingR 8, Tail3 6, Tail2 4, Tail1 4, LegFL 7, LegFR 7, LegBL 7, LegBR 7, Body 12); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.898 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 78% of the 12000 verts budget used (9472) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.63 at the close-up (27357 px), 5.18 at 25 m; close-up outline complexity 12.4 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.11 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 45 | top third L* 38.8, bottom third L* 36.2 (+2, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 90 | inner detail 11.4 at 25 m, 16.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 52 | on the autumn floor: dE 24.7, 1% melts; body L* 35.4 C 43.8 vs floor L* 46.2 C 39.9; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 82 | front-view asymmetry 0.17 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Fix recipes: 1 in fixes.json (top: B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary)
