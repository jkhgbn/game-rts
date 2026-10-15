# Art Lab scorecard: vessa

Scene `res://art/units/wizards/vessa.tscn` · kind **unit** / tier **wizard** · kingdom fire · ground meadow · 2026-10-15 10:26:34 · lab v3.1

## Result: **WARN** · quality **93 / 100** (93.4) (previous run 94, -1)

0 FAIL · 3 WARN · 29 PASS · 18 info · 0 skipped · 55 s

## Before / after (vs the run of 2026-10-15 10:23:55 in `docs/art/lab/g3a_wizards/after/vessa`: quality 94 -> 93, -1)
### What got worse (1)
1. **R5c Glow points stand out (1 m surround): PASS 88 -> PASS 83 (-6) (noisy check: re-run before acting)**. Now: worst dL +12 (point 1 dL +12; ring 24 px = 1.0 m at 40 m). Was: worst dL +23 (point 1 dL +23; ring 24 px = 1.0 m at 40 m)

new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new P2 Asymmetric secondary shape (INFO); new R2 Distinct from references (black masks) (PASS); new B13 Frame cost (PASS)

### Score delta per check (4 changed, 44 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R3t | Contrast in every team colour (meadow) | WARN 52 | WARN 51 | -0.8 |
| P1 | Silhouette hook | INFO 89 | INFO 87 | -1.7 |
| R5c | Glow points stand out (1 m surround) | PASS 88 | PASS 83 | -5.8 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 93 | PASS 89 | -3.8 (noisy) |

Changed pixels per shot: z40 0.3 %, z55 0.3 %, z25 0.6 %, close 4.6 %, strike_side 3.8 %, turns 2.7 %, cast 3.7 %, anim 2.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast in every team colour (meadow)** (WARN): shader_parameter/base_color of `fire_bronze` #9e6629 -> #e47555 (13% of the visible body): predicted dE R3 meadow 64.5 -> 66.8, R3t fire 63.2 -> 65.5, R3t shadow 62.8 -> 65.0, R3t ice 39.6 -> 42.7, R3t nature 18.6 -> 24.0, R4k ash 68.2 -> 69.5 (want >= 24); other grounds heath 48.9, old_wood 67.8, riverbank 77.9, snow 65.0, sand 44.7, marsh 67.5; `fire_bronze` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `fire_pennon.tres` (#d94d1f, dE 22.7 from the wanted colour; no palette entry is close: a new palette entry is needed, or give the asset its own copy); team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `fire_cloth_dark` 39%, `fire_cloth` 17% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R3t Contrast in every team colour (meadow), shot teams)_
2. **Vertices** (WARN): B4 4492 -> 2925 (want <= 3000): `Merged` 1111 -> 556 verts; `Merged` 1066 -> 533 verts; `Merged` 786 -> 393 verts; `Merged` 423 -> 337 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (protan) look alike on this model (dE 9.7): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from torvald (IoU 0.72): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (11 mesh + 1 multimesh); per pivot: Head 3, Hips 3, ArmR 2, Chest 2, (root) 1, ArmL 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 4492 (body + face above its allowance: face 1417 v, allowance 2200, total 5909; biggest: Face 1417, Merged 1111, Merged 1066, Merged 786) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (OrbLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (EmberMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 13 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 31 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 730 of 7122 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0008 ms process per instance (100 animated at 40 m: +0.08 ms process, render CPU +1.52 ms, GPU +6.44 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.029 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 92 | head top 3.38 m / body_height 3.0 (x1.13) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R10 | Footprint vs selection radius | INFO | x 0.86 / z 0.87 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1804 px (44 x 65 bbox; 55 m: 924 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 64.5, 0% of the body melts (within dE 15 of the ground); body L* 60.0 C 62.3 vs ground L* 61.3 C 49.0, hue gap 69 deg; top third (world height) dE 69.6, L* 70.2; per-pixel dE 71.2, outline 57.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 68.2, 0% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst sand: dE 43.9 (heath dE 47.2, old_wood dE 65.7, riverbank dE 75.7, snow dE 65.2, ash dE 68.2, sand dE 43.9, marsh dE 65.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 58% of body pixels change between kingdom colours (min pair 54%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 51 | worst nature colour: dE 18.6 (fire 63.2, shadow 62.8, ice 39.6, nature 18.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (protan): dE 9.7 on the team-colour area (normal vision 72.8; 1128 px); deutan: fire / nature dE 18.2; protan: fire / nature dE 9.7; worst vs ground: nature colour (deutan) dE 0.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -4 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 83 | worst dL +12 (point 1 dL +12; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Runes, + 1 glowing surface(s); soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst ice: dE 57.8, dL -3 (warm dE 63.7, ice dE 57.8, night dE 64.3, autumn dE 59.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.86 (min 0.78), area kept 95-103% (min 1748 px), frame-to-frame IoU min 0.83; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 1/2/2/2/2/1/1/2 (median 2, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 82 | max IoU 0.72 (torvald 0.72, malrik 0.63, emberdart_harrier_placeholder 0.49, pyre_adept 0.42, stormbottle_genie 0.41, hollow_stag 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.92 m from the body centre at t 0.08 s (1.65 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 99 | strike pose changes 28% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 36% of the silhouette at its peak (t 0.4 s; 0.12 s 24%, 0.25 s 35%, 0.4 s 36%, 0.6 s 32%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 92 | 124 shapes over 5 body parts (24.8 per part: Hips 38, Head 37, ArmL 3, ArmR 25, Chest 21); 19% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.901 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 187% of the 3000 verts budget used (5612) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.75 at the close-up (93045 px), 3.67 at 25 m; close-up outline complexity 7.49 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 87 | outline complexity 2.44 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 70.2, bottom third L* 49.6 (+20, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.9 at 25 m, 12.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 82 | on the autumn floor: dE 34.1, 0% melts; body L* 60.0 C 64.9 vs floor L* 49.8 C 41.7; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 93 | front-view asymmetry 0.19 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
`{"draw":16,"face_verts":2200,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 1417 v / 1 s; Root/Hips/Merged 1111 v / 5 s; Root/Chest/ArmR/Merged 1066 v / 7 s; Root/Chest/Merged 786 v / 4 s; Root/Chest/Head/Merged 423 v / 3 s; Root/Chest/Cape 398 v / 3 s; Root/Chest/ArmL/Merged 273 v / 3 s; Root/Chest/Head/CrownFlames 174 v / 1 s x6
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: shader_parameter/base_color of `fire_bronze` #9e6629 -> #e47555 (13% of the visible body): predicted dE R3 meadow 64.5 -> 66.8, R3t fire 63.2 -> 65.5, R3t shado)
