# Art Lab scorecard: kilnwarden

Scene `res://art/units/fire/kilnwarden/kilnwarden.tscn` · kind **unit** / tier **soldier** · kingdom fire · ground meadow · 2026-09-30 16:01:07 · lab v3.1

## Result: **PASS** · quality **96 / 100** (96.1) (previous run 96, +0)

0 FAIL · 0 WARN · 32 PASS · 18 info · 0 skipped · 42 s

## Before / after (vs the run of 2026-09-30 15:54:55 in `docs/art/lab/kilnwarden`: quality 96 -> 96, +0)
### What got worse (1)
1. **P2 Asymmetric secondary shape: INFO 91 -> INFO 88 (-3)**. Now: front-view asymmetry 0.18. Was: front-view asymmetry 0.18

### Score delta per check (7 changed, 49 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 77 | INFO 78 | +0.6 |
| P1 | Silhouette hook | INFO 81 | INFO 79 | -1.5 |
| P4 | Detail density 25 m / 40 m | INFO 100 | INFO 99 | -0.6 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 88 | -1.9 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 46 | INFO 47 | +1.0 |
| P2 | Asymmetric secondary shape | INFO 91 | INFO 88 | -3.0 |
| B13 | Frame cost | PASS 98 | PASS 96 | -1.3 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.1 %, z25 0.1 %, close 4.4 %, strike_side 2.1 %, turns 7.0 %, cast 4.2 %, anim 2.2 %, silhouette 0.1 %, lineup 7.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.87): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 23.1): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 26.8: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: ArmR 2, Chest 2, Head 2, (root) 1, ArmL 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 93 | 12 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 86 | 2446 (body + face above its allowance: face 932 v, allowance 800, total 3246; biggest: Face 932, Merged 887, Merged 384, Merged 326) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 8 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 94 | 1 (Smoke) | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 6 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 24 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 57 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 29 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 368 of 4261 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 96 | 0.0027 ms process per instance (100 animated at 40 m: +0.27 ms process, render CPU +1.88 ms, GPU +0.4 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.026 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.96 m / body_height 1.95 (x1.01) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.58 / z 0.88 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1045 px (41 x 54 bbox; 55 m: 534 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.1, 0% of the body melts (within dE 15 of the ground); body L* 48.5 C 36.2 vs ground L* 61.8 C 48.9, hue gap 74 deg; top third (world height) dE 45.8, L* 64.6; per-pixel dE 66.0, outline 54.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 40.3, 22% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 96 | worst heath: dE 26.8 (heath dE 26.8, old_wood dE 41.2, riverbank dE 54.9, snow dE 53.4, ash dE 40.3, sand dE 40.1, marsh dE 39.7) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 31%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 31.6 (fire 54.0, shadow 64.4, ice 47.0, nature 31.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 15.9 on the team-colour area (normal vision 83.6; 348 px); deutan: fire / nature dE 15.9; protan: fire / nature dE 18.7; worst vs ground: fire colour (deutan) dE 17.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 91 | bar hides 7% of the silhouette (gap -14 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.45 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +20 (point 1 dL +24, point 2 dL +20; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Smoke, Spit; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 32.4, dL -1 (warm dE 54.1, ice dE 48.5, night dE 32.4, autumn dE 50.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.87 (min 0.79), area kept 97-100% (min 1022 px), frame-to-frame IoU min 0.89; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 92 | max IoU 0.57 (emberdart_harrier 0.57, pyrehoof_lancer 0.55, flame_guard 0.5, scorchbow 0.5, ruin_warden 0.43, stormbottle_genie 0.37) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.11 m from the body centre at t 0.24 s (1.04 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 22% of the silhouette at its peak (t 0.4 s; 0.12 s 19%, 0.25 s 21%, 0.4 s 22%, 0.6 s 4%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 78 | 101 shapes over 7 body parts (14.4 per part: LegL 2, LegR 2, Hips 12, Head 35, ArmL 6, ArmR 13, Chest 31); 34% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.866 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 129% of the 2500 verts budget used (3242) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.39 at the close-up (79849 px), 3.28 at 25 m; close-up outline complexity 3.81 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 79 | outline complexity 2.33 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 64.6, bottom third L* 28.7 (+35, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 99 | inner detail 11.0 at 25 m, 16.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 47 | on the autumn floor: dE 23.1, 0% melts; body L* 46.9 C 41.1 vs floor L* 50.7 C 42.2; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 88 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 932 v / 1 s; Root/Chest/Merged 887 v / 9 s; Root/Hips/Merged 384 v / 5 s; Root/Chest/ArmR/Merged 326 v / 3 s; Root/Chest/ArmL/Merged 233 v / 3 s; Root/Chest/KilnFire 153 v / 1 s; Root/Chest/Head/Merged 113 v / 1 s; Root/Hips/LegL/Merged 83 v / 2 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
