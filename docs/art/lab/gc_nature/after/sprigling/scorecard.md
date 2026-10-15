# Art Lab scorecard: sprigling

Scene `res://art/units/nature/sprigling.tscn` · kind **unit** / tier **worker** · kingdom nature · ground meadow · 2026-10-15 12:55:37 · lab v3.1

## Result: **WARN** · quality **89 / 100** (89.3) (previous run 90, -1)

0 FAIL · 3 WARN · 30 PASS · 16 info · 0 skipped · 35 s

## Before / after (vs the run of 2026-10-15 12:45:26 in `docs/art/lab/gc_nature/after/sprigling`: quality 90 -> 89, -1)
### What got worse (0)
Nothing got worse.

gone P5 Glow placement (was INFO)

### Score delta per check (6 changed, 49 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6cb | Team colours for colour-blind players | PASS 76 | PASS 74 | -2.0 |
| R7 | HP bar over the body at 40 m | WARN 57 | WARN 56 | -1.0 |
| P1 | Silhouette hook | INFO 63 | INFO 61 | -1.6 |
| R5c | Glow points stand out (1 m surround) | PASS 91 | PASS 90 | -0.6 (noisy) |
| R11 | Reads while walking (40 m) | PASS 93 | PASS 93 | +0.5 (noisy) |
| R2 | Distinct from references (black masks) | PASS 90 | PASS 90 | -0.5 |

Changed pixels per shot: z40 0.3 %, z55 0.2 %, z25 0.3 %, close 5.1 %, strike_side 5.0 %, turns 5.5 %, cast 1.1 %, anim 1.6 %, silhouette 0.0 %, lineup 6.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 1.2 -> 1.94 in res://art/units/nature/sprigling.tscn (root) and res://data/units/sprigling.tres (the head top; x1.62 now), or lower the head / crest 0.44 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow SproutMesh 0.56 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **HP bar over the body at 40 m** (WARN): R7 HP bar over the body at 40 m: The HP bar hides 9% of the body: lower / narrow what sticks up, or fix body_height [fixes.json #3] _(from R7 HP bar over the body at 40 m, shot z40)_
4. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 9 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 22.7): the body sits in the ground's hue (gap 12 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast on the other grounds** (PASS): On sand the body drops to dE 12.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1, Hips 1 | <= 22 (art-units.md 8) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8) |  |
| B4 | Vertices | PASS 98 | 1830 (body + face above its allowance: face 476 v, allowance 800, total 2306; biggest: Merged 603, Face 476, Merged 304, Merged 174) | <= 2500 (art-units.md 8) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/worker |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 0 soft (art-units.md 8) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/worker |  |
| B1a | Authored build parts (before the merge) | INFO | 28 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 22 |  |
| B11 | Surfaces per instance | INFO | 24 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 532 of 3548 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0008 ms process per instance (100 animated at 40 m: +0.08 ms process, render CPU +0.7 ms, GPU +1.03 ms) | <= 0.005 ms per instance (art-units.md 8) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 35 | head top 1.94 m / body_height 1.2 (x1.62) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | SproutMesh 0.56 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | PASS 100 | x 0.48 / z 0.49 m (radius 0.35, from sprigling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 426 px (19 x 37 bbox; 55 m: 219 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 85 | mean-colour dE 22.7, 5% of the body melts (within dE 15 of the ground); body L* 74.4 C 30.9 vs ground L* 62.5 C 48.3, hue gap 12 deg; top third (world height) dE 40.3, L* 90.3; per-pixel dE 34.7, outline 35.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 46.9, 2% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 78 | worst sand: dE 12.3 (heath dE 30.8, old_wood dE 46.9, riverbank dE 44.7, snow dE 32.6, ash dE 60.1, sand dE 12.3, marsh dE 63.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 37% of body pixels change between kingdom colours (min pair 32%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 88 | worst nature colour: dE 21.7 (fire 35.5, shadow 40.3, ice 34.7, nature 21.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 74 | worst pair fire / nature (deutan): dE 6.9 on the team-colour area (normal vision 43.5; 184 px); deutan: fire / nature dE 6.9; protan: fire / nature dE 14.9; worst vs ground: fire colour (deutan) dE 13.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | **WARN** 56 | bar hides 9% of the silhouette (gap -10 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.7 m, 1.0 m wide | Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +27 (soft 1 dL +27 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0), 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 88 | worst autumn: dE 20.5, dL +15 (warm dE 22.9, ice dE 25.4, night dE 25.9, autumn dE 20.5); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 93 | walk frames vs rest: mean IoU 0.72 (min 0.61), area kept 95-98% (min 403 px), frame-to-frame IoU min 0.63; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 0/0/0/0/1/0/1/1 (median 0, range 1, 0 frame(s) at 0; at rest 0) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (magpie 0.6, tracker 0.57, bramblesage 0.52, wildwood_archer 0.47, vinelasher 0.46, greenheart_oathkeeper_placeholder 0.39) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.03 m from the body centre at t 0.08 s (1.03 m forward; geometry clipped at the ground); declared 1.4 m (UnitType attack_range (sprigling.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 58% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 24% of the silhouette at its peak (t 0.12 s; 0.12 s 24%, 0.25 s 24%, 0.4 s 17%, 0.6 s 9%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 61 shapes over 8 body parts (7.6 per part: LegL 2, LegR 2, Hips 1, Head 25, Sprout 4, ArmL 3, ArmR 7, Chest 17); 10% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.965 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 92% of the 2500 verts budget used (2302) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 60 | 9 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.02 at the close-up (67633 px), 1.82 at 25 m; close-up outline complexity 3.78 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 61 | outline complexity 2.1 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 90.3, bottom third L* 60.6 (+29, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.2 at 25 m, 14.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 61 | on the autumn floor: dE 27.4, 2% melts; body L* 73.3 C 36.1 vs floor L* 51.5 C 42.9; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.33 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":22,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":0,"separate":6},"src":"art-units.md 8","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 603 v / 4 s; Root/Chest/Head/Face 476 v / 1 s; Root/Chest/ArmR/Merged 304 v / 6 s; Root/Chest/Head/Merged 174 v / 3 s; Root/Chest/ArmL/Merged 163 v / 2 s; Root/Hips/LegL/Merged 161 v / 1 s; Root/Hips/LegR/Merged 161 v / 1 s; Root/Chest/Head/Sprout/SproutMesh 141 v / 4 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: R8: body_height 1.2 -> 1.94 in res://art/units/nature/sprigling.tscn (root) and res://data/units/sprigling.tres (the head top; x1.62 now), or lower the head / c)
