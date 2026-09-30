# Art Lab scorecard: gloom_deacon

Scene `res://art/units/shadow/gloom_deacon/gloom_deacon.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-09-30 15:59:11 · lab v3.1

## Result: **PASS** · quality **97 / 100** (96.5) (previous run 96, +1)

0 FAIL · 0 WARN · 32 PASS · 18 info · 0 skipped · 40 s

## Before / after (vs the run of 2026-09-30 15:32:07 in `docs/art/lab/gloom_deacon`: quality 96 -> 97, +1)
### What got worse (1)
1. **P1 Silhouette hook: INFO 84 -> INFO 81 (-3)**. Now: outline complexity 2.35. Was: outline complexity 2.39

### What got better (2)
P4 Detail density 25 m / 40 m: INFO 73 -> INFO 89 (+17) (noisy check: re-run before acting); R2 Distinct from references (black masks): PASS 89 -> PASS 92 (+3)

### Score delta per check (4 changed, 47 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R8 | Head height vs body_height | PASS 93 | PASS 92 | -0.6 |
| P1 | Silhouette hook | INFO 84 | INFO 81 | -2.8 |
| P4 | Detail density 25 m / 40 m | INFO 73 | INFO 89 | +16.8 (noisy) |
| R2 | Distinct from references (black masks) | PASS 89 | PASS 92 | +2.7 |

Changed pixels per shot: z40 1.5 %, z55 1.0 %, z25 1.7 %, close 10.6 %, strike_side 6.0 %, turns 12.9 %, cast 23.4 %, anim 16.9 %, silhouette 2.7 %, lineup 16.0 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.81): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (11.4): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (33 surfaces for 12 meshes = 33 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 29 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 2, Head 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 90 | 13 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 90 | 2275 (body + face above its allowance: face 725 v, allowance 800, total 3000; biggest: Face 725, Merged 428, Merged 406, Staff 373) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 94 | 1 (FlameMotes) | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 5 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Staff, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 39 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 213 of 3833 triangles (5%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0011 ms process per instance (100 animated at 40 m: +0.11 ms process, render CPU +1.83 ms, GPU +-0.01 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.024 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 92 | head top 2.31 m / body_height 2.05 (x1.13) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.54 / z 0.38 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 635 px (26 x 41 bbox; 55 m: 316 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 94.2, 0% of the body melts (within dE 15 of the ground); body L* 39.8 C 44.1 vs ground L* 61.8 C 48.8, hue gap 160 deg; top third (world height) dE 84.2, L* 54.7; per-pixel dE 97.8, outline 79.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 52.3, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 43.3 (heath dE 58.2, old_wood dE 65.5, riverbank dE 78.1, snow dE 68.1, ash dE 43.3, sand dE 80.3, marsh dE 52.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 64% of body pixels change between kingdom colours (min pair 62%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 94 | worst nature colour: dE 26.9 (fire 64.3, shadow 93.5, ice 59.5, nature 26.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.4 on the team-colour area (normal vision 78.4; 417 px); deutan: fire / nature dE 11.4; protan: fire / nature dE 23.1; worst vs ground: fire colour (deutan) dE 20.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 0 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.55 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +29 (point 1 dL +29; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): FlameMotes, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 68.8, dL -2 (warm dE 93.5, ice dE 88.4, night dE 68.8, autumn dE 82.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.89 (min 0.81), area kept 98-100% (min 638 px), frame-to-frame IoU min 0.86; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 92 | max IoU 0.58 (hollow_oathsworn 0.58, duskbolt_harrier 0.45, stormbottle_genie 0.44, barrow_knight 0.44, veilborn_dreadrider 0.41, ruin_warden 0.37) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.07 m from the body centre at t 0.08 s (1.07 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 32% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 26% of the silhouette at its peak (t 0.25 s; 0.12 s 18%, 0.25 s 26%, 0.4 s 25%, 0.6 s 26%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 67 | 82 shapes over 9 body parts (9.1 per part: LegL 1, LegR 1, Hips 11, Head 34, ArmL 5, ArmR 13, Reliquary 5, LidHinge 3, Chest 9); 22% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.812 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 119% of the 2500 verts budget used (2996) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.85 at the close-up (82702 px), 2.31 at 25 m; close-up outline complexity 6.66 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 81 | outline complexity 2.35 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 54.7, bottom third L* 31.0 (+23, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 89 | inner detail 11.4 at 25 m, 15.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 65.5, 0% melts; body L* 38.6 C 38.1 vs floor L* 50.7 C 42.3; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.25 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 725 v / 1 s; Root/Hips/Merged 428 v / 5 s; Root/Chest/Head/Merged 406 v / 4 s; Root/Chest/ArmR/Staff 373 v / 4 s; Root/Chest/Merged 358 v / 4 s; Root/Chest/ArmL/Merged 180 v / 3 s; Root/Chest/Reliquary/LidHinge/Lid 155 v / 3 s; Root/Chest/ArmR/Merged 153 v / 3 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
