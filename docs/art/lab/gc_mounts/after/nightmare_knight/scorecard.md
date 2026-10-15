# Art Lab scorecard: nightmare_knight

Scene `res://art/units/titans/nightmare_knight/nightmare_knight.tscn` · kind **titan** / tier **titan** · kingdom shadow · ground meadow · 2026-10-15 13:11:50 · lab v3.1

## Result: **WARN** · quality **94 / 100** (93.6)

0 FAIL · 1 WARN · 28 PASS · 19 info · 0 skipped · 28 s

## Improve next
1. **Vertices** (WARN): B4 17131 -> 11743 (want <= 12000): `Merged` 2821 -> 1411 verts; `Merged` 1957 -> 979 verts; `Merged` 1734 -> 867 verts; `Merged` 1428 -> 714 verts; `Merged` 1428 -> 714 verts; `Merged` 1425 -> 720 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (17.0): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 11 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 10% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
5. **Contrast on the other grounds** (PASS): On ash the body drops to dE 27.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1a | Authored build parts (before the merge) | INFO | 2 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 60 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1770 of 13928 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (12 animated at 40 m: +-0.01 ms process, render CPU +0.24 ms, GPU +1.0 ms) | <= 0.02 ms per instance soft (cavalry-mounts.md 10, titans-2.md 11) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2662 px (71 x 92 bbox; 55 m: 1343 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 83.0, 0% of the body melts (within dE 15 of the ground); body L* 33.1 C 29.2 vs ground L* 61.2 C 49.5, hue gap 165 deg; top third (world height) dE 103.9, L* 49.2; per-pixel dE 88.9, outline 63.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 36.6, 5% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 97 | worst ash: dE 27.3 (heath dE 58.5, old_wood dE 50.0, riverbank dE 61.3, snow dE 65.5, ash dE 27.3, sand dE 73.4, marsh dE 36.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 83 | 10% of body pixels change between kingdom colours (min pair 8%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 72.0 (fire 74.9, shadow 77.5, ice 74.7, nature 72.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 86 | worst pair fire / nature (deutan): dE 17.2 on the team-colour area (normal vision 41.7; 442 px); deutan: fire / nature dE 17.2; protan: shadow / ice dE 20.0; worst vs ground: nature colour (deutan) dE 57.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -15 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 4.05 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +9 (point 1 dL +30, point 2 dL +41, point 3 dL +63, point 4 dL +50, point 5 dL +9; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 5 point(s) above the bloom level 1.2 (median of 5/5/5): Merged x4, Lance; soft glows under the bloom (v1 count, luma > 0.4): 5 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 55.8, dL +0 (warm dE 82.6, ice dE 73.1, night dE 55.8, autumn dE 77.5); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.82 (min 0.78), area kept 96-102% (min 2576 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 5/6/4/6/5/5/4/5 (median 5, range 2, 0 frame(s) at 0; at rest 5) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.36 (elder_treant 0.36, war_mammoth 0.34, roc 0.32, frost_dragon 0.23, cinder_dragon 0.22, frost_wyrm 0.15) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 4.84 m from the body centre at t 0.08 s (4.83 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 32% of the silhouette (t 0.08 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 20% of the silhouette at its peak (t 0.25 s; 0.12 s 19%, 0.25 s 20%, 0.4 s 18%, 0.6 s 10%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.71 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 99 | 236 shapes over 11 body parts (21.5 per part: Neck 17, Head 45, LegFL 15, LegFR 15, LegBL 16, LegBR 16, Tail 7, Mount 49, ArmL 9, ArmR 20, Chest 27); 15% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.917 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 142% of the 12000 verts budget used (17127) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 60 | 9 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.55 at the close-up (43479 px), 3.94 at 25 m; close-up outline complexity 12.38 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.71 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 49.2, bottom third L* 33.8 (+15, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 17.0 at 25 m, 24.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 60.0, 0% melts; body L* 31.7 C 27.6 vs floor L* 48.9 C 41.1 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 87 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Mount/Merged 2821 v / 7 s; Root/Chest/Head/Merged 1957 v / 4 s; Root/Mount/Neck/Merged 1734 v / 4 s; Root/Mount/LegBL/Merged 1428 v / 4 s; Root/Mount/LegBR/Merged 1428 v / 4 s; Root/Chest/Merged 1425 v / 6 s; Root/Mount/LegFL/Merged 1399 v / 4 s; Root/Mount/LegFR/Merged 1399 v / 4 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B4 17131 -> 11743 (want <= 12000): `Merged` 2821 -> 1411 verts; `Merged` 1957 -> 979 verts; `Merged` 1734 -> 867 verts; `Merged` 1428 -> 714 verts; `Merged` 142)
