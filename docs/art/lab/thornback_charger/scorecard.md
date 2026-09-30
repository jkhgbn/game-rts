# Art Lab scorecard: thornback_charger

Scene `res://art/units/nature/thornback_charger/thornback_charger.tscn` · kind **unit** / tier **cavalry** · kingdom nature · ground meadow · 2026-09-30 11:35:23 · lab v3.1

## Result: **PASS** · quality **95 / 100** (95.2) (previous run 95, +0)

0 FAIL · 0 WARN · 31 PASS · 15 info · 0 skipped · 31 s

## Before / after (vs the run of 2026-09-30 11:24:23 in `docs/art/lab/thornback_charger`: quality 95 -> 95, +0)
### What got worse (0)
Nothing got worse.

### Score delta per check (1 changed, 46 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B13 | Frame cost | PASS 100 | PASS 98 | -1.9 (noisy) |

Changed pixels per shot: z40 0.0 %, z55 0.0 %, z25 0.1 %, close 0.1 %, strike_side 0.8 %, turns 1.4 %, cast 0.0 %, anim 0.3 %, silhouette 1.7 %, lineup 7.1 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 8.2): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
2. **Contrast on the other grounds** (PASS): On heath the body drops to dE 10.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
3. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 15% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from stagrunner (IoU 0.61): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 34.1): value is close to the ground (dL -6): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast under every light preset (meadow)** (PASS): Under the night light the body drops to dE 18.1: add a value step (light top / pale crest) that survives a dim light _(from R12 Contrast under every light preset (meadow), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 2, ArmL 1, Chest 1, Elk 1, Head 1, Hips 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | PASS 87 | 12 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | PASS 85 | 2497 (body + face above its allowance: face 970 v, allowance 1200, total 3467; biggest: Merged 1158, Merged 832, Merged 501, Merged 282) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | PASS 94 | 1 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 16 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 56 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 335 of 4244 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 98 | 0.0024 ms process per instance (100 animated at 40 m: +0.24 ms process, render CPU +1.06 ms, GPU +0.2 ms) | <= 0.005 ms per instance (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.003 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.88 / z 1.72 m (radius 0.7, from thornback_charger.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1657 px (55 x 61 bbox; 55 m: 848 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 95 | mean-colour dE 34.1, 2% of the body melts (within dE 15 of the ground); body L* 55.1 C 30.2 vs ground L* 61.9 C 48.7, hue gap 42 deg; top third (world height) dE 32.2, L* 64.2; per-pixel dE 44.2, outline 36.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 33.1, 2% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 76 | worst heath: dE 10.4 (heath dE 10.4, old_wood dE 33.1, riverbank dE 39.2, snow dE 44.4, ash dE 42.7, sand dE 26.0, marsh dE 43.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 89 | 15% of body pixels change between kingdom colours (min pair 15%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 33.6 (fire 40.9, shadow 45.7, ice 37.5, nature 33.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 75 | worst pair fire / nature (deutan): dE 21.6 on the team-colour area (normal vision 57.7; 261 px); deutan: fire / nature dE 21.6; protan: fire / nature dE 25.2; worst vs ground: fire colour (deutan) dE 10.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 4% of the silhouette (gap -6 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.9 m, 1.82 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +21 (soft 1 dL +21 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 85 | worst night: dE 18.1, dL +6 (warm dE 34.1, ice dE 29.7, night dE 18.1, autumn dE 31.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.8 (min 0.76), area kept 98-106% (min 1599 px), frame-to-frame IoU min 0.81; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.61 (stagrunner 0.61, glade_outrider 0.6, hollow_stag 0.51, mossback 0.35, stormbottle_genie 0.34, briar_roc 0.26) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.16 m from the body centre at t 0.08 s (2.04 m forward; geometry clipped at the ground); declared 1.9 m (UnitType attack_range (thornback_charger.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 31% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.4 s; 0.12 s 11%, 0.25 s 12%, 0.4 s 12%, 0.6 s 12%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 92 | 148 shapes over 10 body parts (14.8 per part: Head 36, LegFL 3, LegFR 3, LegBL 3, LegBR 3, Mount 24, Hips 12, ArmL 7, ArmR 10, Chest 47); 42% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.94 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 138% of the 2500 verts budget used (3463) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 15 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.46 at the close-up (56026 px), 2.82 at 25 m; close-up outline complexity 7.72 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.77 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 64.2, bottom third L* 48.1 (+16, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.2 at 25 m, 14.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 1 | on the autumn floor: dE 8.2, 9% melts; body L* 53.4 C 35.1 vs floor L* 50.5 C 42.1; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider, mount separate))
`{"draw":12,"face_verts":1200,"frame_ms":0.005,"lights":0,"meshes":20,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":4,"separate":6,"verts":2500},"src":"cavalry-mounts.md 10 (cavalry rider, mount separate)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Rider/Root/Chest/Merged 1158 v / 9 s; Elk/Root/Mount/Head/Merged 832 v / 7 s; Elk/Root/Mount/Merged 501 v / 7 s; Rider/Root/Hips/Merged 282 v / 5 s; Rider/Root/Chest/ArmL/Merged 187 v / 6 s; Rider/Root/Chest/ArmR/Lance 161 v / 6 s; Elk/Root/Mount/LegFL/Merged 69 v / 3 s; Elk/Root/Mount/LegFR/Merged 69 v / 3 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
