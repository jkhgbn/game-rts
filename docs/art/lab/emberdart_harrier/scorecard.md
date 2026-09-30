# Art Lab scorecard: emberdart_harrier

Scene `res://art/units/fire/emberdart_harrier/emberdart_harrier.tscn` · kind **unit** / tier **rider** · kingdom fire · ground meadow · 2026-09-30 10:34:08 · lab v3.1

## Result: **WARN** · quality **94 / 100** (93.5) (previous run 92, +2)

0 FAIL · 2 WARN · 30 PASS · 17 info · 0 skipped · 41 s

## Before / after (vs the run of 2026-09-30 10:32:08 in `docs/art/lab/emberdart_harrier`: quality 92 -> 94, +2)
### What got worse (0)
Nothing got worse.

### What got better (4)
C3 Palette depth (close-up): INFO 80 -> INFO 100 (+20); R5c Glow points stand out (1 m surround): PASS 90 -> PASS 99 (+9) (noisy check: re-run before acting); R6 Team-colour visibility at 40 m: PASS 87 -> PASS 91 (+4); R4 Contrast on the other grounds: PASS 97 -> PASS 100 (+2)

### Score delta per check (7 changed, 45 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 80 | INFO 100 | +20.0 |
| R4 | Contrast on the other grounds | PASS 97 | PASS 100 | +2.5 |
| R6 | Team-colour visibility at 40 m | PASS 87 | PASS 91 | +4.4 |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 99 | +9.0 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 99 | PASS 100 | +0.6 |
| R5w | Glow points while walking (flicker) | PASS 81 | PASS 89 | +7.5 (noisy) |
| B13 | Frame cost | PASS 100 | PASS 96 | -4.0 (noisy) |

Changed pixels per shot: z40 0.3 %, z55 0.2 %, z25 0.7 %, close 1.6 %, strike_side 1.7 %, turns 1.0 %, cast 0.9 %, anim 0.8 %, silhouette 0.1 %, lineup 8.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.6 -> 0.79, or pull the widest parts in to x <= 1.05 / z <= 1.05 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Vertices** (WARN): B4 7171 -> 4891 (want <= 5000): `Merged` 3090 -> 1545 verts; `Merged` 1491 -> 756 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (14.3): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from pyrehoof_lancer (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 17% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
6. **Attack reads at 40 m** (PASS): Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 12%) _(from A3 Attack reads at 40 m, shot anim)_

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
| B1 | Meshes after the kit merge | PASS 100 | 15 drawn (15 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, ArmL 1, Boar 1, Chest 1, Hips 1 | <= 36 (art-units.md 8 (rider = mount + rider)) |  |
| B2 | Draw instances at rest | PASS 89 | 15 | <= 16 (art-units.md 8 (rider = mount + rider)) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8 (rider = mount + rider)) |  |
| B4 | Vertices | **WARN** 35 | 7171 (body + face above its allowance: face 1246 v, allowance 1200, total 8371; biggest: Merged 3090, Merged 1491, Face 764, Merged 640) | <= 5000 soft (art-units.md 8 (rider = mount + rider)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (rider = mount + rider)) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/rider |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (rider = mount + rider)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (art-units.md 8 (rider = mount + rider)) |  |
| B7 | Shadow casters | PASS 89 | 5 (Merged, Merged, Javelin, Merged, Merged) | <= 5 soft (art-units.md 8 (rider = mount + rider)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/rider |  |
| B1a | Authored build parts (before the merge) | INFO | 18 (model says 20) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 58 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1217 of 10936 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 96 | 0.0027 ms process per instance (100 animated at 40 m: +0.27 ms process, render CPU +2.8 ms, GPU +0.62 ms) | <= 0.005 ms per instance (art-units.md 8 (rider = mount + rider)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.009 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.63 / z 1.38 m (radius 0.6, from emberdart_harrier.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1052 px (40 x 60 bbox; 55 m: 540 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 58.7, 0% of the body melts (within dE 15 of the ground); body L* 34.4 C 35.8 vs ground L* 62.8 C 48.1, hue gap 73 deg; top third (world height) dE 62.9, L* 43.8; per-pixel dE 69.8, outline 56.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 34.9, 7% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 29.8 (heath dE 32.3, old_wood dE 37.5, riverbank dE 52.1, snow dE 62.6, ash dE 34.9, sand dE 49.3, marsh dE 29.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 91 | 17% of body pixels change between kingdom colours (min pair 17%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 45.0 (fire 55.2, shadow 60.8, ice 51.3, nature 45.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 85 | worst pair fire / nature (deutan): dE 16.8 on the team-colour area (normal vision 79.0; 189 px); deutan: fire / nature dE 16.8; protan: fire / nature dE 18.9; worst vs ground: fire colour (deutan) dE 29.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -7 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 99 | worst dL +43 (point 1 dL +43; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 1/3/2): Merged x2, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 29.9, dL -5 (warm dE 59.3, ice dE 53.7, night dE 29.9, autumn dE 54.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.81 (min 0.76), area kept 97-100% (min 1022 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 1/2/2/1/1/1/1/3 (median 1, range 2, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.67 (pyrehoof_lancer 0.67, cinderlock 0.48, ash_hurler 0.46, pyre_adept 0.45, ruin_warden 0.36, stormbottle_genie 0.31) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.38 m from the body centre at t 0.36 s (1.38 m forward; geometry clipped at the ground); declared 6.5 m (UnitType attack_range (emberdart_harrier.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 82 | strike pose changes 12% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 26% of the silhouette at its peak (t 0.25 s; 0.12 s 26%, 0.25 s 26%, 0.4 s 24%, 0.6 s 11%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 240 shapes over 11 body parts (21.8 per part: Head 78, LegFL 7, LegFR 7, LegBL 8, LegBR 8, Tail 6, Mount 79, Hips 13, ArmL 4, ArmR 9, Chest 21); 24% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.946 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 167% of the 5000 verts budget used (8367) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.66 at the close-up (60449 px), 1.84 at 25 m; close-up outline complexity 11.99 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.18 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 43.8, bottom third L* 22.5 (+21, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 17 | inner detail 14.3 at 25 m, 19.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 68 | on the autumn floor: dE 29.9, 0% melts; body L* 33.6 C 37.8 vs floor L* 51.7 C 42.7; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.26 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Boar/Root/Mount/Merged 3090 v / 9 s; Boar/Root/Mount/Head/Merged 1491 v / 7 s; Rider/Root/Chest/Head/Face 764 v / 1 s; Rider/Root/Chest/Merged 640 v / 7 s; Rider/Root/Hips/Merged 497 v / 4 s; Boar/Root/Mount/LegBL/Merged 297 v / 3 s; Boar/Root/Mount/LegBR/Merged 297 v / 3 s; Rider/Root/Chest/Head/Merged 281 v / 3 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R10: raise UnitType.radius 0.6 -> 0.79, or pull the widest parts in to x <= 1.05 / z <= 1.05 m)
