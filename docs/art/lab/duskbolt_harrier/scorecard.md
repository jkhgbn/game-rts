# Art Lab scorecard: duskbolt_harrier

Scene `res://art/units/shadow/duskbolt_harrier/duskbolt_harrier.tscn` · kind **unit** / tier **rider** · kingdom shadow · ground meadow · 2026-09-30 11:16:34 · lab v3.1

## Result: **WARN** · quality **92 / 100** (92.0) (previous run 92, +0)

0 FAIL · 2 WARN · 30 PASS · 16 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-09-30 11:03:22 in `docs/art/lab/duskbolt_harrier`: quality 92 -> 92, +0)
### What got worse (0)
Nothing got worse.

### What got better (1)
P2 Asymmetric secondary shape: INFO 98 -> INFO 100 (+2)

### Score delta per check (6 changed, 47 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6cb | Team colours for colour-blind players | PASS 79 | PASS 78 | -0.6 |
| A3 | Attack reads at 40 m | PASS 87 | PASS 86 | -0.8 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 92 | PASS 100 | +8.3 (noisy) |
| P2 | Asymmetric secondary shape | INFO 98 | INFO 100 | +2.3 |
| R2 | Distinct from references (black masks) | PASS 87 | PASS 87 | +0.8 |
| B13 | Frame cost | PASS 99 | PASS 100 | +0.8 (noisy) |

Changed pixels per shot: z40 1.3 %, z55 0.8 %, z25 1.4 %, close 5.9 %, strike_side 1.8 %, turns 2.5 %, cast 0.5 %, anim 2.7 %, silhouette 0.2 %, lineup 6.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.6 -> 0.76, or pull the widest parts in to x <= 1.05 / z <= 1.05 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Vertices** (WARN): B4 7878 -> 4856 (want <= 5000): `Merged` 2902 -> 1451 verts; `Merged` 1975 -> 988 verts; `Merged` 496 -> 248 verts; `Merged` 402 -> 201 verts; `Merged` 402 -> 267 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 6 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.4): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from barrow_knight (IoU 0.64): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Attack reads at 40 m** (PASS): Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 16%) _(from A3 Attack reads at 40 m, shot anim)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 36 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 15 drawn (15 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, ArmL 1, Chest 1, Hips 1, LegBL 1 | <= 36 (art-units.md 8 (rider = mount + rider)) |  |
| B2 | Draw instances at rest | PASS 89 | 15 | <= 16 (art-units.md 8 (rider = mount + rider)) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8 (rider = mount + rider)) |  |
| B4 | Vertices | **WARN** 35 | 7878 (body + face above its allowance: face 840 v, allowance 1200, total 8718; biggest: Merged 2902, Merged 1975, Merged 496, Face 424) | <= 5000 soft (art-units.md 8 (rider = mount + rider)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (rider = mount + rider)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (rider = mount + rider)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (art-units.md 8 (rider = mount + rider)) |  |
| B7 | Shadow casters | PASS 89 | 5 (Merged, Merged, Crossbow, Merged, Merged) | <= 5 soft (art-units.md 8 (rider = mount + rider)) |  |
| B8 | Unique materials | INFO | 14 | no budget for unit/rider |  |
| B1a | Authored build parts (before the merge) | INFO | 17 (model says 17) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 59 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1034 of 10500 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.002 ms process per instance (100 animated at 40 m: +0.2 ms process, render CPU +1.24 ms, GPU +0.6 ms) | <= 0.005 ms per instance (art-units.md 8 (rider = mount + rider)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.008 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.62 / z 1.33 m (radius 0.6, from duskbolt_harrier.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 699 px (34 x 49 bbox; 55 m: 361 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 98.4, 0% of the body melts (within dE 15 of the ground); body L* 23.4 C 42.0 vs ground L* 62.3 C 48.9, hue gap 167 deg; top third (world height) dE 103.2, L* 32.9; per-pixel dE 102.1, outline 76.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 46.6, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 38.6 (heath dE 64.5, old_wood dE 62.3, riverbank dE 76.1, snow dE 79.6, ash dE 38.6, sand dE 89.0, marsh dE 46.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 37% of body pixels change between kingdom colours (min pair 36%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 58.8 (fire 75.0, shadow 95.0, ice 75.8, nature 58.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 10.4 on the team-colour area (normal vision 73.3; 264 px); deutan: fire / nature dE 10.4; protan: fire / nature dE 21.1; worst vs ground: fire colour (deutan) dE 51.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 81 | worst dL +9 (point 1 dL +9; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 62.6, dL -10 (warm dE 98.0, ice dE 87.9, night dE 62.6, autumn dE 89.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.75 (min 0.68), area kept 92-100% (min 658 px), frame-to-frame IoU min 0.71; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (barrow_knight 0.64, veilborn_dreadrider 0.5, hollow_oathsworn 0.47, hollow_oathsworn_placeholder 0.42, stormbottle_genie 0.36, ruin_warden 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.34 m from the body centre at t 0.08 s (1.34 m forward; geometry clipped at the ground); declared 6.5 m (UnitType attack_range (duskbolt_harrier.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 86 | strike pose changes 16% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.4 s; 0.12 s 9%, 0.25 s 11%, 0.4 s 12%, 0.6 s 9%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 94 | 250 shapes over 11 body parts (22.7 per part: Head 87, LegFL 10, LegFR 10, LegBL 11, LegBR 11, Tail 11, Mount 70, Hips 13, ArmL 3, ArmR 13, Chest 11); 31% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.904 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 174% of the 5000 verts budget used (8714) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 23 | 9 colour steps (L*a*b* bins >= 2 % of the body), 6 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.84 at the close-up (53534 px), 1.96 at 25 m; close-up outline complexity 10.69 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.55 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 32.9, bottom third L* 10.5 (+22, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 66 | inner detail 12.4 at 25 m, 15.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 73.9, 0% melts; body L* 22.6 C 37.2 vs floor L* 50.9 C 42.4; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.23 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (rider = mount + rider))
`{"draw":16,"face_verts":1200,"frame_ms":0.005,"lights":0,"looping":1,"meshes":36,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":5,"separate":6,"verts":5000},"src":"art-units.md 8 (rider = mount + rider)"}`

## Notes
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 2902 v / 7 s; Steed/Root/Mount/Head/Merged 1975 v / 9 s; Rider/Root/Hips/Merged 496 v / 6 s; Rider/Root/Chest/Head/Face 424 v / 1 s; Steed/Root/Mount/LegBL/Merged 402 v / 4 s; Steed/Root/Mount/LegBR/Merged 402 v / 4 s; Rider/Root/Chest/Merged 360 v / 4 s; Steed/Root/Mount/LegFL/Merged 339 v / 4 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R10: raise UnitType.radius 0.6 -> 0.76, or pull the widest parts in to x <= 1.05 / z <= 1.05 m)
