# Art Lab scorecard: stormbottle_genie

Scene `res://art/units/neutral/stormbottle_genie/stormbottle_genie.tscn` · kind **unit** / tier **heavy** · kingdom neutral · ground meadow · 2026-09-27 17:50:08 · lab v3.1

## Result: **PASS** · quality **95 / 100** (94.8) (previous run 93, +2)

0 FAIL · 0 WARN · 26 PASS · 21 info · 0 skipped · 40 s

## Before / after (vs the run of 2026-09-27 17:46:39 in `docs/art/lab/stormbottle_genie`: quality 93 -> 95, +2)
### What got worse (1)
1. **P2 Asymmetric secondary shape: INFO 80 -> INFO 75 (-5)**. Now: front-view asymmetry 0.15. Was: front-view asymmetry 0.16

### What got better (2)
C3 Palette depth (close-up): INFO 0 -> INFO 33 (+33); C4 Inner detail (close-up / 25 m): INFO 87 -> INFO 98 (+11)

### Score delta per check (8 changed, 44 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 0 | INFO 33 | +32.5 |
| C4 | Inner detail (close-up / 25 m) | INFO 87 | INFO 98 | +11.1 |
| R4 | Contrast on the other grounds | PASS 81 | PASS 82 | +2.0 |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 90 | +0.8 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 80 | INFO 79 | -0.9 |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 85 | INFO 86 | +0.7 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 88 | PASS 93 | +4.5 (noisy) |
| P2 | Asymmetric secondary shape | INFO 80 | INFO 75 | -5.3 |

Changed pixels per shot: z40 0.4 %, z55 0.3 %, z25 0.6 %, close 1.4 %, strike_side 1.2 %, turns 4.6 %, cast 1.8 %, anim 1.9 %, silhouette 8.1 %, lineup 34.8 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 6 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
2. **Contrast on the other grounds** (PASS): On sand the body drops to dE 16.0: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (25 surfaces for 6 meshes = 25 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 20 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 6 drawn (6 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 100 | 7 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 98 | 4407 (biggest: Merged 1353, Merged 1172, Merged 727, Merged 727) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 94 | 1 (LipSparks) | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 4 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 13 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 69 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 6 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 871 of 5790 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.05 ms process, render CPU +1.75 ms, GPU +0.8 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 0.29 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R8 | Head height vs body_height | PASS 100 | head top 2.58 m / body_height 2.6 (x0.99) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.93 / z 0.45 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1043 px (42 x 43 bbox; 55 m: 532 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 43.6, 0% of the body melts (within dE 15 of the ground); body L* 80.0 C 17.9 vs ground L* 61.1 C 48.8, hue gap n/a (body C* <= 25); top third (world height) dE 51.1, L* 86.8; per-pixel dE 49.7, outline 41.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 82 | worst sand: dE 16.0 (heath dE 29.6, old_wood dE 54.5, riverbank dE 54.3, snow dE 18.3, ash dE 58.7, sand dE 16.0, marsh dE 64.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 0 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +25 (point 1 dL +25, point 2 dL +29; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Merged x2; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 39.6, dL +21 (warm dE 43.2, ice dE 42.9, night dE 39.7, autumn dE 39.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 86 | walk frames vs rest: mean IoU 0.6 (min 0.57), area kept 88-94% (min 934 px), frame-to-frame IoU min 0.81; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 2/2/2/1/2/2/2/1 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 93 | max IoU 0.56 (gloomcap_elder 0.56, ruin_warden 0.55, tracker 0.44, ash_hurler 0.37, bramblehorn 0.3, hollow_stag 0.28) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 3.89 m from the body centre at t 0.14 s (3.87 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 58% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 67% of the silhouette at its peak (t 0.4 s; 0.12 s 53%, 0.25 s 65%, 0.4 s 67%, 0.6 s 50%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 89 shapes over 5 body parts (17.8 per part: Hips 34, Head 11, ArmL 11, ArmR 11, Chest 22); 10% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.954 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 73% of the 6000 verts budget used (4403) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 33 | 10 colour steps (L*a*b* bins >= 2 % of the body), 6 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 98 | inner edges per outline px: 2.67 at the close-up (89003 px), 1.38 at 25 m; close-up outline complexity 4.19 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.84 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 86.8, bottom third L* 60.8 (+26, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.1 at 25 m, 7.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 79 | on the autumn floor: dE 33.2, 0% melts; body L* 78.4 C 25.0 vs floor L* 50.1 C 41.9 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 75 | front-view asymmetry 0.15 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Hips/Merged 1353 v / 5 s; Root/Chest/Merged 1172 v / 6 s; Root/Chest/ArmL/Merged 727 v / 5 s; Root/Chest/ArmR/Merged 727 v / 5 s; Root/Chest/Head/Merged 424 v / 3 s; Shadow 4 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
