# Art Lab scorecard: maelis

Scene `res://art/units/helpers/helper_maelis/helper_maelis.tscn` · kind **unit** / tier **wizard** · kingdom nature · ground meadow · 2026-09-27 18:06:30 · lab v3.1

## Result: **WARN** · quality **88 / 100** (87.7) (previous run 88, +0)

0 FAIL · 4 WARN · 29 PASS · 18 info · 0 skipped · 38 s

## Before / after (vs the run of 2026-09-27 18:05:00 in `docs/art/lab/maelis`: quality 88 -> 88, +0)
### What got worse (2)
1. **R4k Contrast on the home ground (old_wood): PASS 95 -> PASS 90 (-5)**. Now: dE 23.0, 4% melts (old_wood is where nature units stand most). Was: dE 27.3, 1% melts (old_wood is where nature units stand most)
2. **R12 Contrast under every light preset (meadow): PASS 95 -> PASS 92 (-3)**. Now: worst night: dE 23.6, dL +1 (warm dE 36.4, ice dE 33.4, night dE 23.6, autumn dE 32.7); night = lab stand-in (warm preset, dim moon sun). Was: worst night: dE 25.9, dL +3 (warm dE 36.2, ice dE 34.0, night dE 25.9, autumn dE 32.1); night = lab stand-in (warm prese

### What got better (1)
S1 Style bible: golden autumn (style-autumn.md 3): INFO 38 -> INFO 41 (+2)

### Score delta per check (8 changed, 48 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 82 | INFO 82 | +0.6 |
| R4k | Contrast on the home ground (old_wood) | PASS 95 | PASS 90 | -5.0 |
| R6 | Team-colour visibility at 40 m | PASS 85 | PASS 86 | +0.5 |
| R6cb | Team colours for colour-blind players | PASS 81 | PASS 82 | +1.3 |
| R12 | Contrast under every light preset (meadow) | PASS 95 | PASS 92 | -2.8 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 38 | INFO 41 | +2.4 |
| R11 | Reads while walking (40 m) | PASS 97 | PASS 96 | -0.6 (noisy) |
| B13 | Frame cost | PASS 93 | PASS 91 | -2.1 (noisy) |

Changed pixels per shot: z40 0.4 %, z55 0.3 %, z25 0.6 %, close 1.8 %, strike_side 2.9 %, turns 3.7 %, cast 0.7 %, anim 0.9 %, silhouette 0.3 %, lineup 11.0 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `nature_stone` #85806b -> #9f9585 (12% of the visible body): predicted dE R3 meadow 36.5 -> 36.7, R3t fire 42.4 -> 42.4, R3t shadow 49.8 -> 49.6, R3t ice 42.0 -> 42.0, R3t nature 35.8 -> 36.0, R4k old_wood 23.0 -> 24.1 (want >= 24); other grounds heath 5.5, riverbank 29.6, snow 41.9, ash 32.0, sand 34.8, marsh 36.1; `nature_stone` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `nature_skin.tres` (#c7a87a, dE 20.3 from the wanted colour; no palette entry is close: a new palette entry is needed, or give the asset its own copy) [fixes.json #1] _(from R4 Contrast on the other grounds, shot z40)_
2. **Distinct from references (black masks)** (WARN): R2 Distinct from references (black masks): Make it read apart from wildcaller (IoU 0.97): change one big shape of the silhouette [fixes.json #2] _(from R2 Distinct from references (black masks), shot silhouette)_
3. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Staff 0.71 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
4. **Vertices** (WARN): B4 29619 -> 14813 (want <= 3000): `Merged` 10540 -> 5270 verts; `Staff` 8598 -> 4299 verts; `Merged` 6449 -> 3225 verts; `Merged` 1668 -> 834 verts; `Merged` 983 -> 492 verts; `Face` 530 -> 265 verts; `Merged` 287 -> 144 verts; `Merged` 280 -> 140 verts; `Merged` 280 -> 140 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.1): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 23.4): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: ArmR 2, Head 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 100 | 11 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 29619 (biggest: Merged 10540, Staff 8598, Merged 6449, Merged 1668) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (CrownMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 16 (model says 16) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 48 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 3225 of 39900 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 91 | 0.0037 ms process per instance (100 animated at 40 m: +0.37 ms process, render CPU +2.96 ms, GPU +3.67 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 85 | head top 2.5 m / body_height 2.0 (x1.25) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Staff 0.71 m | narrower than 0.7 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.92 / z 0.7 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 889 px (41 x 51 bbox; 55 m: 448 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 97 | mean-colour dE 36.5, 0% of the body melts (within dE 15 of the ground); body L* 49.8 C 15.8 vs ground L* 61.9 C 48.7, hue gap n/a (body C* <= 25); top third (world height) dE 41.2, L* 76.4; per-pixel dE 50.6, outline 43.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 90 | dE 23.0, 4% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | **WARN** 35 | worst heath: dE 5.7 (heath dE 5.7, old_wood dE 23.0, riverbank dE 28.8, snow dE 43.0, ash dE 31.5, sand dE 35.4, marsh dE 35.4) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility at 40 m | PASS 86 | 13% of body pixels change between kingdom colours (min pair 11%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 35.8 (fire 42.4, shadow 49.8, ice 42.0, nature 35.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 14.0 on the team-colour area (normal vision 73.5; 123 px); deutan: fire / nature dE 14.0; protan: fire / nature dE 23.0; worst vs ground: fire colour (deutan) dE 26.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +35 (point 1 dL +35; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): CrownMotes; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 92 | worst night: dE 23.6, dL +1 (warm dE 36.4, ice dE 33.4, night dE 23.6, autumn dE 32.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.78 (min 0.76), area kept 93-101% (min 831 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | **WARN** 35 | max IoU 0.97 (wildcaller 0.97, vessa 0.63, ysolde 0.59) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) | Reads like wildcaller at 40 m (IoU 0.97, colour dE 4.3): change the silhouette hook (a different vertical, weapon, head shape) |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.19 m from the body centre at t 0.08 s (2.15 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 38% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 38% of the silhouette at its peak (t 0.25 s; 0.12 s 34%, 0.25 s 38%, 0.4 s 35%, 0.6 s 9%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 82 | 830 shapes over 7 body parts (118.6 per part: LegL 7, LegR 7, Hips 39, Head 199, ArmL 15, ArmR 286, Chest 277); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.878 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 987% of the 3000 verts budget used (29615) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.88 at the close-up (67829 px), 2.09 at 25 m; close-up outline complexity 13.08 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.2 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 76.4, bottom third L* 23.7 (+52, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.1 at 25 m, 19.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 41 | on the autumn floor: dE 23.4, 1% melts; body L* 48.1 C 19.4 vs floor L* 50.8 C 42.3 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.34 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Merged 10540 v / 8 s; Root/Chest/ArmR/Staff 8598 v / 8 s; Root/Chest/Head/Merged 6449 v / 8 s; Root/Hips/Merged 1668 v / 5 s; Root/Chest/ArmL/Merged 983 v / 4 s; Root/Chest/Head/Face 530 v / 7 s; Root/Chest/ArmR/Merged 287 v / 3 s; Root/Hips/LegL/Merged 280 v / 2 s
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: shader_parameter/base_color of `nature_stone` #85806b -> #9f9585 (12% of the visible body): predicted dE R3 meadow 36.5 -> 36.7, R3t fire 42.4 -> 42.4, R3t shad)
