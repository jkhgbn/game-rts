# Art Lab scorecard: war_mammoth

Scene `res://art/units/titans/war_mammoth/war_mammoth.tscn` · kind **titan** / tier **titan** · kingdom ice · ground meadow · 2026-10-15 12:42:00 · lab v3.1

## Result: **WARN** · quality **97 / 100** (97.0)

0 FAIL · 1 WARN · 28 PASS · 19 info · 0 skipped · 34 s

## Improve next
1. **Vertices** (WARN): B4 13040 -> 11948 (want <= 12000): `Merged` 3436 -> 2344 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 10% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (75 surfaces for 17 meshes = 75 draw calls) _(from B11)_

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
| B1 | Meshes after the kit merge | PASS 100 | 17 drawn (17 mesh + 0 multimesh); per pivot: ArmL 3, Head 2, (root) 1, ArmR 1, Chest 1, Howdah 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 91 | 18 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B3 | keep_separate parts | INFO | 2 | no budget for titan/titan |  |
| B4 | Vertices | **WARN** 47 | 13040 (body + face above its allowance: face 404 v, allowance 0, total 13040; biggest: Merged 3436, Merged 2340, Frame 2290, Merged 747) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6 | Particle systems | INFO | 1 | no budget for titan/titan |  |
| B6l | Looping particle systems | PASS 100 | 1 (FrostMist) | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6p | Looping particles alive | INFO | 16 | no budget for titan/titan |  |
| B7 | Shadow casters | PASS 94 | 10 (Merged, Merged, Merged, Merged, Merged, Frame) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 20 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 5 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 75 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1845 of 14966 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0022 ms process per instance (12 animated at 40 m: +0.03 ms process, render CPU +0.44 ms, GPU +1.51 ms) | <= 0.02 ms per instance soft (cavalry-mounts.md 10, titans-2.md 11) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.032 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 8353 px (117 x 170 bbox; 55 m: 4229 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 60.7, 0% of the body melts (within dE 15 of the ground); body L* 57.7 C 11.3 vs ground L* 61.5 C 50.4, hue gap n/a (body C* <= 25); top third (world height) dE 59.7, L* 62.5; per-pixel dE 66.0, outline 45.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 35.8, 12% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 35.8 (heath dE 41.4, old_wood dE 43.8, riverbank dE 44.9, snow dE 35.8, ash dE 36.5, sand dE 49.4, marsh dE 46.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 83 | 10% of body pixels change between kingdom colours (min pair 10%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 53.6 (fire 57.2, shadow 62.7, ice 60.0, nature 53.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 9.6 on the team-colour area (normal vision 65.9; 930 px); deutan: fire / nature dE 9.6; protan: fire / nature dE 20.3; worst vs ground: fire colour (deutan) dE 45.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -33 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 4.7 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +18 (point 1 dL +25, point 2 dL +27, point 3 dL +18; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): Merged x3, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 10 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 54.4, dL -1 (warm dE 60.8, ice dE 59.0, night dE 55.2, autumn dE 54.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.89 (min 0.83), area kept 98-101% (min 8202 px), frame-to-frame IoU min 0.86; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 2/1/2/3/3/3/3/3 (median 3, range 2, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.37 (elder_treant 0.37, nightmare_knight 0.34, frost_dragon 0.3, cinder_dragon 0.3, frost_wyrm 0.23, roc 0.23) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 4.83 m from the body centre at t 0.14 s (4.81 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 23% of the silhouette (t 0.14 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 25% of the silhouette at its peak (t 0.25 s; 0.12 s 24%, 0.25 s 25%, 0.4 s 24%, 0.6 s 3%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 96 | 326 shapes over 13 body parts (25.1 per part: Trunk2 8, Trunk 5, Head 79, LegFL 11, LegFR 11, LegBL 11, LegBR 11, Tail 7, Howdah 80, ArmL 11, ArmR 10, Chest 14, Mount 68); 19% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.91 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 108% of the 12000 verts budget used (13036) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 19 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.58 at the close-up (64879 px), 4.84 at 25 m; close-up outline complexity 4.87 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.58 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 62.5, bottom third L* 47.3 (+15, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.9 at 25 m, 9.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 46.0, 0% melts; body L* 55.4 C 6.0 vs floor L* 48.7 C 41.0; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Per-mesh vertices (biggest first): Root/Mount/Merged 3436 v / 8 s; Root/Mount/Head/Merged 2340 v / 9 s; Root/Mount/Seat/Howdah/Frame 2290 v / 11 s; Root/Mount/Seat/Howdah/Root/Chest/Head/Merged 747 v / 5 s; Root/Mount/Seat/Howdah/Root/Chest/ArmR/Merged 600 v / 6 s; Root/Mount/Head/Trunk/Trunk2/Merged 597 v / 2 s; Root/Mount/Seat/Howdah/Root/Chest/Merged 548 v / 6 s; Root/Mount/Seat/Howdah/Root/Chest/ArmL/Merged 482 v / 5 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B4 13040 -> 11948 (want <= 12000): `Merged` 3436 -> 2344 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
