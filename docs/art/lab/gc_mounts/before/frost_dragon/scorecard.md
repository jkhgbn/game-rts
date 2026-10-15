# Art Lab scorecard: frost_dragon

Scene `res://art/units/titans/frost_dragon/frost_dragon.tscn` · kind **titan** / tier **titan** · kingdom ice · ground meadow · 2026-10-15 12:40:21 · lab v3.1

## Result: **WARN** · quality **92 / 100** (92.3)

0 FAIL · 1 WARN · 26 PASS · 20 info · 0 skipped · 36 s

## Improve next
1. **Team-colour visibility at 40 m** (WARN): R6 Team-colour visibility at 40 m: Give the team colour more top-facing area (now 4% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top [fixes.json #1] _(from R6 Team-colour visibility at 40 m, shot teams)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -32 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from cinder_dragon (IoU 0.85): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.9): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

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
| B12 | Downward-facing triangles | INFO | 2217 of 13258 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (12 animated at 40 m: +-0.25 ms process, render CPU +0.28 ms, GPU +0.78 ms) | <= 0.02 ms per instance soft (cavalry-mounts.md 10, titans-2.md 11) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 2.0 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 5422 px (131 x 138 bbox; 55 m: 2709 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 76.8, 0% of the body melts (within dE 15 of the ground); body L* 60.3 C 26.8 vs ground L* 61.4 C 51.9, hue gap 153 deg; top third (world height) dE 77.6, L* 59.9; per-pixel dE 80.0, outline 60.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 42.2, 17% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 42.2 (heath dE 57.4, old_wood dE 57.2, riverbank dE 56.1, snow dE 42.2, ash dE 45.7, sand dE 62.5, marsh dE 57.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | **WARN** 42 | 4% of body pixels change between kingdom colours (min pair 4%) | >= 8% (FAIL = set_team_color changes nothing) | Put the team colour on a big, top-facing mass (cloth, plates, cape, caparison); ~25-45 %% of the surface (art-keep 0.2 / art-units 1.3) |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 40.5 (fire 42.5, shadow 44.6, ice 43.2, nature 40.5) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 74 | worst pair fire / nature (deutan): dE 6.8 on the team-colour area (normal vision 78.0; 275 px); deutan: fire / nature dE 6.8; protan: fire / nature dE 23.7; worst vs ground: fire colour (deutan) dE 35.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -72 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 6.0 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +27 (point 1 dL +30, point 2 dL +29, point 3 dL +27; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 3/2/2): Tail2Mesh, LegBRMesh, 2 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 67.7, dL +19 (warm dE 76.1, ice dE 72.3, night dE 67.7, autumn dE 71.3); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.42 (min 0.31), area kept 113-156% (min 5920 px), frame-to-frame IoU min 0.6; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 3/2/2/2/3/2/1/1 (median 2, range 2, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 74 | max IoU 0.85 (cinder_dragon 0.85, war_mammoth 0.22, roc 0.22, elder_treant 0.21, frost_wyrm 0.2, nightmare_knight 0.17); same shape family as cinder_dragon but told apart by colour (dE 67.3); wing phase matched to the target's (p 0.2; residual per flyer ref: frost_wyrm 0.01, roc 0.0, cinder_dragon 0.0) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 4.08 m from the body centre at t 0.36 s (3.33 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 71% of the silhouette (t 0.36 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 68% of the silhouette at its peak (t 0.6 s; 0.12 s 27%, 0.25 s 30%, 0.4 s 68%, 0.6 s 68%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.86 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 141 shapes over 16 body parts (8.8 per part: Jaw 13, Head 28, Neck2 3, Neck1 4, WingL2 9, WingL 8, WingR2 9, WingR 8, Tail3 7, Tail2 4, Tail1 4, LegFL 7, LegFR 7, LegBL 7, LegBR 7, Body 16); 13% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.927 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 71% of the 12000 verts budget used (8576) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.7 at the close-up (29693 px), 5.51 at 25 m; close-up outline complexity 7.11 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.37 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 59.9, bottom third L* 92.6 (-32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 53 | inner detail 12.9 at 25 m, 16.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 62.4, 0% melts; body L* 58.7 C 22.3 vs floor L* 46.4 C 40.0; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 78 | front-view asymmetry 0.16 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1418 v / 4 s; Root/Body/BodyMesh 1263 v / 2 s; Root/Body/WingL/WingL2/WingL2Mesh 771 v / 3 s; Root/Body/WingR/WingR2/WingR2Mesh 771 v / 3 s; Root/Body/WingL/WingLMesh 532 v / 4 s; Root/Body/WingR/WingRMesh 532 v / 4 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 466 v / 4 s; Root/Body/Tail1/Tail2/Tail3/Tail3Mesh 367 v / 2 s
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R6 Team-colour visibility at 40 m: Give the team colour more top-facing area (now 4% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top)
