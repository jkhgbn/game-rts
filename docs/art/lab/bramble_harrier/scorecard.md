# Art Lab scorecard: bramble_harrier

Scene `res://art/units/nature/bramble_harrier/bramble_harrier.tscn` · kind **unit** / tier **cavalry** · kingdom nature · ground meadow · 2026-09-30 11:36:59 · lab v3.1

## Result: **WARN** · quality **94 / 100** (93.8) (previous run 94, +0)

0 FAIL · 1 WARN · 30 PASS · 15 info · 0 skipped · 29 s

## Before / after (vs the run of 2026-09-30 11:34:44 in `docs/art/lab/bramble_harrier`: quality 94 -> 94, +0)
### What got worse (1)
1. **S1 Style bible: golden autumn (style-autumn.md 3): INFO 10 -> INFO 4 (-6)**. Now: on the autumn floor: dE 9.2, 10% melts; body L* 57.7 C 36.6 vs floor L* 50.3 C 42.0; nature team colour vs the floor swatches: min dE 55.3 (grass_dry). Was: on the autumn floor: dE 11.3, 7% melts; body L* 59.5 C 35.7 vs floor L* 50.1 C 41.9; nature team colour vs the floor swa

### What got better (2)
P2 Asymmetric secondary shape: INFO 79 -> INFO 85 (+6); P1 Silhouette hook: INFO 64 -> INFO 67 (+2)

### Score delta per check (8 changed, 43 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R7 | HP bar over the body at 40 m | PASS 91 | PASS 91 | +0.9 |
| A3 | Attack reads at 40 m | PASS 96 | PASS 94 | -2.4 (noisy) |
| P1 | Silhouette hook | INFO 64 | INFO 67 | +2.3 |
| R5c | Glow points stand out (1 m surround) | PASS 89 | PASS 88 | -1.4 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 87 | PASS 86 | -1.4 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 10 | INFO 4 | -6.5 |
| P2 | Asymmetric secondary shape | INFO 79 | INFO 85 | +6.0 |
| R2 | Distinct from references (black masks) | PASS 89 | PASS 88 | -0.6 |

Changed pixels per shot: z40 0.6 %, z55 0.4 %, z25 0.6 %, close 5.0 %, strike_side 1.7 %, turns 1.0 %, cast 1.0 %, anim 0.7 %, silhouette 0.1 %, lineup 1.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 24.9): add a value step inside the team-colour area [fixes.json #1] _(from R6cb Team colours for colour-blind players, shot teams)_
2. **Contrast on the other grounds** (PASS): On heath the body drops to dE 10.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
3. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 9.2): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
4. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.17): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 30.5): value is close to the ground (dL -2): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from bramble_harrier_placeholder (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 2, ArmL 1, Chest 1, Hare 1, Head 1, Hips 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | PASS 87 | 12 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | PASS 88 | 2344 (body + face above its allowance: face 1050 v, allowance 1200, total 3394; biggest: Merged 1151, Merged 808, Merged 535, Merged 263) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | PASS 94 | 1 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 15 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 47 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 298 of 4694 triangles (6%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0018 ms process per instance (100 animated at 40 m: +0.18 ms process, render CPU +1.04 ms, GPU +0.26 ms) | <= 0.005 ms per instance (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.012 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.56 / z 1.09 m (radius 0.6, from bramble_harrier.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1099 px (32 x 56 bbox; 55 m: 559 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 92 | mean-colour dE 30.5, 2% of the body melts (within dE 15 of the ground); body L* 59.0 C 31.4 vs ground L* 61.5 C 48.8, hue gap 37 deg; top third (world height) dE 33.5, L* 77.9; per-pixel dE 44.1, outline 36.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 35.7, 1% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 76 | worst heath: dE 10.5 (heath dE 10.5, old_wood dE 35.7, riverbank dE 40.3, snow dE 42.5, ash dE 46.8, sand dE 21.7, marsh dE 47.7) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 32%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 98 | worst nature colour: dE 30.4 (fire 47.2, shadow 59.7, ice 39.9, nature 30.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 24.9 on the team-colour area (normal vision 63.0; 360 px); deutan: fire / nature dE 24.9; protan: fire / nature dE 28.1; worst vs ground: fire colour (deutan) dE 6.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 91 | bar hides 7% of the silhouette (gap -8 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +22 (soft 1 dL +22 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 86 | worst night: dE 18.5, dL +11 (warm dE 30.5, ice dE 26.4, night dE 18.5, autumn dE 27.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.78 (min 0.69), area kept 91-96% (min 1020 px), frame-to-frame IoU min 0.71; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (bramble_harrier_placeholder 0.63, bloomtender 0.51, greenheart_oathkeeper 0.41, ruin_warden 0.4, bramblehorn 0.39, stormbottle_genie 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.13 m from the body centre at t 0.08 s (1.13 m forward; geometry clipped at the ground); declared 6.5 m (UnitType attack_range (bramble_harrier.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 94 | strike pose changes 23% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 13% of the silhouette at its peak (t 0.6 s; 0.12 s 6%, 0.25 s 9%, 0.4 s 11%, 0.6 s 13%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 99 | 142 shapes over 10 body parts (14.2 per part: Head 35, LegFL 2, LegFR 2, LegBL 4, LegBR 4, Mount 9, Hips 27, ArmL 4, ArmR 11, Chest 44); 31% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.918 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 135% of the 2500 verts budget used (3390) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.57 at the close-up (72518 px), 3.18 at 25 m; close-up outline complexity 6.51 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 67 | outline complexity 2.17 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 77.9, bottom third L* 39.5 (+38, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 95 | inner detail 11.2 at 25 m, 15.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 4 | on the autumn floor: dE 9.2, 10% melts; body L* 57.7 C 36.6 vs floor L* 50.3 C 42.0; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 85 | front-view asymmetry 0.17 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Rider/Root/Chest/Merged 1151 v / 10 s; Hare/Root/Mount/Head/Merged 808 v / 6 s; Rider/Root/Hips/Merged 535 v / 5 s; Hare/Root/Mount/Merged 263 v / 6 s; Rider/Root/Chest/ArmR/Dart 133 v / 5 s; Hare/Root/Mount/LegBL/Merged 114 v / 2 s; Hare/Root/Mount/LegBR/Merged 114 v / 2 s; Rider/Root/Chest/ArmL/Merged 90 v / 3 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 24.9): add a value step insid)
