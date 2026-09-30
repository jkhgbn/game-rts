# Art Lab scorecard: frostcrown_juggernaut

Scene `res://art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn` · kind **unit** / tier **cavalry** · kingdom ice · ground meadow · 2026-09-30 11:33:00 · lab v3.1

## Result: **PASS** · quality **97 / 100** (97.2) (previous run 98, -1)

0 FAIL · 0 WARN · 32 PASS · 16 info · 0 skipped · 29 s

## Before / after (vs the run of 2026-09-30 10:33:07 in `docs/art/lab/frostcrown_juggernaut`: quality 98 -> 97, -1)
### What got worse (1)
1. **P2 Asymmetric secondary shape: INFO 100 -> INFO 74 (-26)**. Now: front-view asymmetry 0.15. Was: front-view asymmetry 0.2

### Score delta per check (4 changed, 47 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| A3 | Attack reads at 40 m | PASS 100 | PASS 98 | -2.0 (noisy) |
| P1 | Silhouette hook | INFO 89 | INFO 90 | +1.3 |
| P2 | Asymmetric secondary shape | INFO 100 | INFO 74 | -26.2 |
| B13 | Frame cost | PASS 89 | PASS 100 | +10.9 (noisy) |

Changed pixels per shot: z40 0.2 %, z55 0.2 %, z25 0.5 %, close 0.7 %, strike_side 3.9 %, turns 2.4 %, cast 0.8 %, anim 1.2 %, silhouette 1.2 %, lineup 18.1 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Distinct from references (black masks)** (PASS): Make it read apart from frostcrown_juggernaut_placeholder (IoU 0.7): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (54 surfaces for 12 meshes = 54 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 34 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 2, ArmL 1, Bear 1, Chest 1, Head 1, Hips 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | PASS 87 | 12 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | PASS 85 | 2478 (body + face above its allowance: face 898 v, allowance 1200, total 3376; biggest: Merged 1064, Merged 648, Merged 504, Merged 255) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | PASS 94 | 1 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 15 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 54 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 265 of 4223 triangles (6%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0005 ms process per instance (100 animated at 40 m: +0.05 ms process, render CPU +1.06 ms, GPU +0.29 ms) | <= 0.005 ms per instance (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.003 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 1.06 / z 2.12 m (radius 0.85, from frostcrown_juggernaut.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2686 px (55 x 75 bbox; 55 m: 1385 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 71.9, 0% of the body melts (within dE 15 of the ground); body L* 47.2 C 23.0 vs ground L* 62.1 C 48.9, hue gap n/a (body C* <= 25); top third (world height) dE 71.1, L* 58.4; per-pixel dE 75.2, outline 49.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 50.4, 1% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 33.6 (heath dE 50.7, old_wood dE 47.8, riverbank dE 52.1, snow dE 50.4, ash dE 33.6, sand dE 64.7, marsh dE 45.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 96 | 21% of body pixels change between kingdom colours (min pair 20%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.7 (fire 63.8, shadow 72.7, ice 71.3, nature 57.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 74 | worst pair fire / nature (deutan): dE 7.0 on the team-colour area (normal vision 63.0; 588 px); deutan: fire / nature dE 7.0; protan: fire / nature dE 17.9; worst vs ground: fire colour (deutan) dE 53.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 4% of the silhouette (gap -8 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.2 m, 2.21 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +28 (point 1 dL +28; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Hammer; soft glows under the bloom (v1 count, luma > 0.4): 5 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 60.4, dL +1 (warm dE 72.2, ice dE 69.1, night dE 60.4, autumn dE 66.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.85 (min 0.82), area kept 96-104% (min 2588 px), frame-to-frame IoU min 0.86; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 83 | max IoU 0.7 (frostcrown_juggernaut_placeholder 0.7, rime_harrier_placeholder 0.49, rime_colossus 0.46, hollow_stag 0.4, shardguard 0.28, stormbottle_genie 0.28) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.35 m from the body centre at t 0.14 s (2.35 m forward; geometry clipped at the ground); declared 2.2 m (UnitType attack_range (frostcrown_juggernaut.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 98 | strike pose changes 28% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.4 s; 0.12 s 11%, 0.25 s 11%, 0.4 s 12%, 0.6 s 11%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 99 | 138 shapes over 10 body parts (13.8 per part: Head 26, LegFL 8, LegFR 8, LegBL 4, LegBR 4, Mount 16, Hips 11, ArmL 8, ArmR 10, Chest 43); 35% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.926 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 134% of the 2500 verts budget used (3372) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.66 at the close-up (76265 px), 3.46 at 25 m; close-up outline complexity 4.29 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 90 | outline complexity 2.47 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 58.4, bottom third L* 32.3 (+26, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.9 at 25 m, 9.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 59.0, 0% melts; body L* 43.4 C 17.7 vs floor L* 50.4 C 42.0 (inside the floor band); ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 74 | front-view asymmetry 0.15 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider, mount separate))
`{"draw":12,"face_verts":1200,"frame_ms":0.005,"lights":0,"meshes":20,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":4,"separate":6,"verts":2500},"src":"cavalry-mounts.md 10 (cavalry rider, mount separate)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Rider/Root/Chest/Merged 1064 v / 7 s; Bear/Root/Mount/Head/Merged 648 v / 6 s; Bear/Root/Mount/Merged 504 v / 7 s; Rider/Root/Hips/Merged 255 v / 5 s; Rider/Root/Chest/ArmL/Merged 230 v / 5 s; Rider/Root/Chest/ArmR/Hammer 163 v / 5 s; Bear/Root/Mount/LegFL/Merged 148 v / 5 s; Bear/Root/Mount/LegFR/Merged 148 v / 5 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
