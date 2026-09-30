# Art Lab scorecard: sunforge_cataphract

Scene `res://art/units/fire/sunforge_cataphract/sunforge_cataphract.tscn` · kind **unit** / tier **rider** · kingdom fire · ground meadow · 2026-09-30 11:25:45 · lab v3.1

## Result: **WARN** · quality **94 / 100** (93.7) (previous run 94, +0)

0 FAIL · 3 WARN · 29 PASS · 17 info · 0 skipped · 25 s

## Before / after (vs the run of 2026-09-30 10:23:11 in `docs/art/lab/sunforge_cataphract`: quality 94 -> 94, +0)
### What got worse (0)
Nothing got worse.

### Score delta per check (8 changed, 49 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6 | Team-colour visibility at 40 m | PASS 89 | PASS 90 | +0.6 |
| A3 | Attack reads at 40 m | PASS 100 | PASS 98 | -1.5 (noisy) |
| P4 | Detail density 25 m / 40 m | INFO 100 | INFO 98 | -2.1 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 89 | PASS 87 | -2.2 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 98 | PASS 99 | +1.0 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 15 | INFO 16 | +1.4 |
| R5w | Glow points while walking (flicker) | PASS 89 | PASS 96 | +7.5 (noisy) |
| R2 | Distinct from references (black masks) | PASS 87 | PASS 86 | -1.2 |

Changed pixels per shot: z40 0.8 %, z55 0.5 %, z25 0.9 %, close 1.3 %, strike_side 12.6 %, turns 5.8 %, cast 3.6 %, anim 3.6 %, silhouette 0.9 %, lineup 6.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.8 -> 0.95, or pull the widest parts in to x <= 1.4 / z <= 1.4 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Vertices** (WARN): B4 8473 -> 4826 (want <= 5000): `Merged` 3363 -> 1682 verts; `Merged` 1905 -> 953 verts; `Merged` 795 -> 398 verts; `Merged` 521 -> 261 verts; `Merged` 483 -> 242 verts; `Merged` 414 -> 298 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 13.5): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 13.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from pyrehoof_lancer (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 16% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 37 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Head 3, ArmL 1, ArmR 1, Boar 1, Chest 1, Hips 1 | <= 36 (art-units.md 8 (rider = mount + rider)) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (art-units.md 8 (rider = mount + rider)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (rider = mount + rider)) |  |
| B4 | Vertices | **WARN** 35 | 8473 (body + face above its allowance: face 1088 v, allowance 1200, total 9561; biggest: Merged 3363, Merged 1905, Merged 795, Face 606) | <= 5000 soft (art-units.md 8 (rider = mount + rider)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (rider = mount + rider)) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/rider |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (rider = mount + rider)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (art-units.md 8 (rider = mount + rider)) |  |
| B7 | Shadow casters | PASS 96 | 4 (Merged, Merged, Merged, Merged) | <= 5 soft (art-units.md 8 (rider = mount + rider)) |  |
| B8 | Unique materials | INFO | 20 | no budget for unit/rider |  |
| B1a | Authored build parts (before the merge) | INFO | 4 (model says 22) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 69 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1267 of 11949 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0018 ms process per instance (100 animated at 40 m: +0.18 ms process, render CPU +1.57 ms, GPU +0.78 ms) | <= 0.005 ms per instance (art-units.md 8 (rider = mount + rider)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.018 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.01 / z 1.67 m (radius 0.8, from sunforge_cataphract.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1750 px (46 x 88 bbox; 55 m: 894 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 43.2, 0% of the body melts (within dE 15 of the ground); body L* 54.9 C 42.7 vs ground L* 62.0 C 48.7, hue gap 55 deg; top third (world height) dE 47.7, L* 72.6; per-pixel dE 58.0, outline 50.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 51.5, 4% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 93 | worst heath: dE 24.6 (heath dE 24.6, old_wood dE 44.4, riverbank dE 52.4, snow dE 53.0, ash dE 51.5, sand dE 30.0, marsh dE 49.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 90 | 16% of body pixels change between kingdom colours (min pair 16%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 99 | worst nature colour: dE 31.3 (fire 43.1, shadow 44.9, ice 36.7, nature 31.3) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 13.5 on the team-colour area (normal vision 73.7; 286 px); deutan: fire / nature dE 13.5; protan: fire / nature dE 17.9; worst vs ground: fire colour (deutan) dE 4.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -23 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.2 m, 2.08 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +19 (point 1 dL +24, point 2 dL +19; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Merged x2, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 99 | worst night: dE 28.9, dL +6 (warm dE 43.3, ice dE 36.6, night dE 28.9, autumn dE 40.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.84 (min 0.78), area kept 96-100% (min 1710 px), frame-to-frame IoU min 0.79; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 3/2/2/2/2/2/2/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.67 (pyrehoof_lancer 0.67, emberdart_harrier 0.56, hollow_stag 0.45, ash_hurler 0.33, stormbottle_genie 0.32, pyre_adept 0.3) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.88 m from the body centre at t 0.14 s (1.88 m forward; geometry clipped at the ground); declared 2.1 m (UnitType attack_range (sunforge_cataphract.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 98 | strike pose changes 28% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 21% of the silhouette at its peak (t 0.25 s; 0.12 s 20%, 0.25 s 21%, 0.4 s 19%, 0.6 s 10%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 278 shapes over 11 body parts (25.3 per part: Head 99, LegFL 8, LegFR 8, LegBL 8, LegBR 8, Tail 6, Mount 87, Hips 12, ArmL 5, ArmR 13, Chest 24); 26% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.938 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 191% of the 5000 verts budget used (9557) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.48 at the close-up (69678 px), 2.68 at 25 m; close-up outline complexity 5.22 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.64 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 72.6, bottom third L* 40.3 (+32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 98 | inner detail 11.1 at 25 m, 15.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 16 | on the autumn floor: dE 13.3, 0% melts; body L* 54.8 C 47.1 vs floor L* 50.5 C 42.0; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (rider = mount + rider))
`{"draw":16,"face_verts":1200,"frame_ms":0.005,"lights":0,"looping":1,"meshes":36,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":5,"separate":6,"verts":5000},"src":"art-units.md 8 (rider = mount + rider)"}`

## Notes
- Per-mesh vertices (biggest first): Boar/Root/Mount/Merged 3363 v / 10 s; Boar/Root/Mount/Head/Merged 1905 v / 10 s; Rider/Root/Chest/Merged 795 v / 7 s; Rider/Root/Chest/Head/Face 606 v / 1 s; Rider/Root/Chest/Head/Merged 521 v / 6 s; Rider/Root/Chest/ArmR/Merged 483 v / 7 s; Rider/Root/Hips/Merged 414 v / 6 s; Boar/Root/Mount/LegBL/Merged 297 v / 3 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: R10: raise UnitType.radius 0.8 -> 0.95, or pull the widest parts in to x <= 1.4 / z <= 1.4 m)
