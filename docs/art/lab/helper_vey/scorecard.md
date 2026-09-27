# Art Lab scorecard: helper_vey

Scene `res://art/units/helpers/helper_vey/helper_vey.tscn` · kind **unit** / tier **wizard** · kingdom fire · ground meadow · 2026-09-27 17:57:46 · lab v3.1

## Result: **WARN** · quality **94 / 100** (93.9) (previous run 94, +0)

0 FAIL · 1 WARN · 31 PASS · 18 info · 0 skipped · 43 s

## Before / after (vs the run of 2026-09-27 17:54:50 in `docs/art/lab/helper_vey`: quality 94 -> 94, +0)
### What got worse (0)
Nothing got worse.

### Score delta per check (3 changed, 50 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6cb | Team colours for colour-blind players | PASS 82 | PASS 83 | +0.7 |
| P4 | Detail density 25 m / 40 m | INFO 100 | INFO 94 | -5.7 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 89 | PASS 85 | -3.8 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.0 %, z25 0.1 %, close 0.9 %, strike_side 8.2 %, turns 3.0 %, cast 3.8 %, anim 2.3 %, silhouette 0.2 %, lineup 2.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (WARN): B4 6070 -> 3039 (want <= 3000): `Merged` 1968 -> 984 verts; `Merged` 808 -> 404 verts; `Merged` 667 -> 334 verts; `Merged` 590 -> 295 verts; `Face` 492 -> 246 verts; `StormRunes` 426 -> 213 verts; `Cape` 294 -> 147 verts; `Merged` 279 -> 140 verts; `Merged` 279 -> 140 verts; `Merged` 263 -> 132 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 19.1: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 26.7): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
6. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (11.2): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: ArmR 2, Chest 2, Head 2, (root) 1, ArmL 1, Hips 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 6070 (biggest: Merged 1968, Merged 808, Merged 667, Merged 590) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (StormSparks) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 20 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 13 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 45 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 851 of 6455 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.002 ms process per instance (100 animated at 40 m: +0.2 ms process, render CPU +2.29 ms, GPU +0.95 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 97 | head top 2.11 m / body_height 2.0 (x1.05) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R10 | Footprint vs selection radius | INFO | x 0.74 / z 1.05 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 844 px (44 x 45 bbox; 55 m: 433 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 50.4, 0% of the body melts (within dE 15 of the ground); body L* 52.4 C 19.8 vs ground L* 62.9 C 47.8, hue gap n/a (body C* <= 25); top third (world height) dE 48.1, L* 74.7; per-pixel dE 65.0, outline 58.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 32.0, 22% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 86 | worst heath: dE 19.1 (heath dE 19.1, old_wood dE 34.8, riverbank dE 46.8, snow dE 42.3, ash dE 32.0, sand dE 38.3, marsh dE 36.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 25% of body pixels change between kingdom colours (min pair 24%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 38.3 (fire 50.6, shadow 64.5, ice 51.1, nature 38.3) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.6 on the team-colour area (normal vision 79.0; 217 px); deutan: fire / nature dE 14.6; protan: fire / nature dE 22.5; worst vs ground: fire colour (deutan) dE 29.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 0 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +35 (point 1 dL +35; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 1/3/2): StormRunes, Merged, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 36.1, dL +3 (warm dE 50.4, ice dE 46.9, night dE 36.1, autumn dE 44.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.77 (min 0.68), area kept 99-105% (min 858 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 2/3/2/1/3/1/2/2 (median 2, range 2, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.65 (tracker 0.65, cinder_arbalest_placeholder 0.61, cinderlock 0.59, flame_guard 0.58, scorchbow 0.52, gloomcap_elder 0.51) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.79 m from the body centre at t 0.14 s (1.68 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 41% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 37% of the silhouette at its peak (t 0.4 s; 0.12 s 29%, 0.25 s 36%, 0.4 s 37%, 0.6 s 25%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 0.99 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 93 | 101 shapes over 7 body parts (14.4 per part: LegL 5, LegR 5, Hips 15, Head 43, ArmL 3, ArmR 12, Chest 18); 23% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.904 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 202% of the 3000 verts budget used (6066) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 11 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.45 at the close-up (81225 px), 2.49 at 25 m; close-up outline complexity 5.36 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.66 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 74.7, bottom third L* 27.3 (+47, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 94 | inner detail 11.2 at 25 m, 14.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 50 | on the autumn floor: dE 26.7, 0% melts; body L* 51.4 C 25.0 vs floor L* 52.0 C 42.9 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (wizard))
`{"draw":16,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 1968 v / 4 s; Root/Chest/Merged 808 v / 7 s; Root/Chest/ArmR/Merged 667 v / 5 s; Root/Hips/Merged 590 v / 6 s; Root/Chest/Head/Face 492 v / 7 s; Root/Chest/ArmR/StormRunes 426 v / 1 s; Root/Chest/Cape 294 v / 3 s; Root/Hips/LegL/Merged 279 v / 4 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B4 6070 -> 3039 (want <= 3000): `Merged` 1968 -> 984 verts; `Merged` 808 -> 404 verts; `Merged` 667 -> 334 verts; `Merged` 590 -> 295 verts; `Face` 492 -> 246 v)
