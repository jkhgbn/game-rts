# Art Lab scorecard: rime_harrier

Scene `res://art/units/ice/rime_harrier/rime_harrier.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-10-15 15:24:30 · lab v3.1

## Result: **PASS** · quality **98 / 100** (97.9) (previous run 95, +3)

0 FAIL · 0 WARN · 32 PASS · 17 info · 0 skipped · 31 s

## Before / after (vs the run of 2026-10-15 15:15:52 in `docs/art/lab/gc_leftovers/after/rime_harrier`: quality 95 -> 98, +3)
### What got worse (0)
Nothing got worse.

### What got better (2)
B4 Vertices: FAIL 17 -> PASS 85 (+68); R5 Glow points at 40 m: WARN 49 -> PASS 100 (+51) (noisy check: re-run before acting)

### Score delta per check (4 changed, 47 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | FAIL 17 | PASS 85 | +68.3 |
| C1 | Shape richness (secondary shapes) | INFO 86 | INFO 87 | +0.6 |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 89 | -0.9 (noisy) |
| R5 | Glow points at 40 m | WARN 49 | PASS 100 | +51.4 (noisy) |

Changed pixels per shot: z40 0.2 %, z55 0.1 %, z25 0.1 %, close 0.4 %, strike_side 1.6 %, turns 0.9 %, cast 0.9 %, anim 2.9 %, silhouette 0.2 %, lineup 5.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Surfaces per instance** (IDEA): Merge surfaces that share a material (47 surfaces for 12 meshes = 47 draw calls) _(from B11)_
2. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_
3. **Detail density at 25 m** (IDEA): Add 1-2 mid-size value accents (trim band, belt, plate edge, markings) that read at 25 m and merge into the big mass at 40 m _(from shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 35 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 2, ArmL 1, Chest 1, Head 1, Hips 1, LegBL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 93 | 12 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 85 | 2485 (body + face above its allowance: face 1112 v, allowance 800, total 3285; biggest: Merged 1211, Merged 790, Merged 356, Merged 335) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 15 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 47 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 302 of 4468 triangles (6%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 95 | 0.003 ms process per instance (100 animated at 40 m: +0.3 ms process, render CPU +1.23 ms, GPU +0.86 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.45 / z 1.26 m (radius 0.6, from rime_harrier.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 883 px (34 x 51 bbox; 55 m: 452 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 70.5, 0% of the body melts (within dE 15 of the ground); body L* 48.6 C 21.2 vs ground L* 62.1 C 48.9, hue gap n/a (body C* <= 25); top third (world height) dE 67.5, L* 54.7; per-pixel dE 73.5, outline 53.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 48.1, 5% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 33.1 (heath dE 41.9, old_wood dE 46.6, riverbank dE 52.2, snow dE 48.1, ash dE 33.1, sand dE 62.2, marsh dE 45.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 29% of body pixels change between kingdom colours (min pair 29%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 51.8 (fire 61.2, shadow 73.1, ice 69.8, nature 51.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 75 | worst pair fire / nature (deutan): dE 7.4 on the team-colour area (normal vision 64.0; 261 px); deutan: fire / nature dE 7.4; protan: fire / nature dE 18.7; worst vs ground: fire colour (deutan) dE 46.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 93 | bar hides 5% of the silhouette (gap -7 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +24 (point 1 dL +24; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/0): Merged; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 63.0, dL +1 (warm dE 70.4, ice dE 68.3, night dE 63.0, autumn dE 63.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.81 (min 0.71), area kept 94-103% (min 833 px), frame-to-frame IoU min 0.73; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 95 | max IoU 0.52 (snowdrift_rider_placeholder 0.52, shardguard 0.51, rime_harrier_placeholder 0.5, rime_seer 0.42, ruin_warden 0.38, stormbottle_genie 0.37) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.26 m from the body centre at t 0.14 s (1.25 m forward; geometry clipped at the ground); declared 6.5 m (UnitType attack_range (rime_harrier.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 33% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 13% of the silhouette at its peak (t 0.6 s; 0.12 s 8%, 0.25 s 10%, 0.4 s 12%, 0.6 s 13%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 87 | 132 shapes over 10 body parts (13.2 per part: Head 33, LegFL 4, LegFR 4, LegBL 4, LegBR 4, Mount 11, Hips 12, ArmL 5, ArmR 9, Chest 46); 35% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.89 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 131% of the 2500 verts budget used (3281) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.57 at the close-up (60511 px), 1.97 at 25 m; close-up outline complexity 7.51 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.39 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 54.7, bottom third L* 31.0 (+23, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.3 at 25 m, 12.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 56.5, 0% melts; body L* 45.3 C 15.5 vs floor L* 51.0 C 42.4 (inside the floor band); ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Rider/Root/Chest/Merged 1211 v / 8 s; Ram/Root/Mount/Head/Merged 790 v / 5 s; Rider/Root/Hips/Merged 356 v / 4 s; Ram/Root/Mount/Merged 335 v / 6 s; Rider/Root/Chest/ArmL/Merged 131 v / 4 s; Rider/Root/Chest/ArmR/Javelin 94 v / 4 s; Rider/Root/Chest/ArmR/Merged 84 v / 3 s; Ram/Root/Mount/LegFL/Merged 70 v / 3 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
