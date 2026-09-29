# Art Lab scorecard: vessa

Scene `res://art/units/wizards/vessa.tscn` · kind **unit** / tier **wizard** · kingdom fire · ground meadow · 2026-09-28 20:08:13 · lab v3.1

## Result: **WARN** · quality **90 / 100** (90.3) (previous run 90, +0)

0 FAIL · 5 WARN · 28 PASS · 19 info · 0 skipped · 29 s

## Before / after (vs the run of 2026-09-28 20:00:38 in `docs/art/lab/vessa`: quality 90 -> 90, +0)
### What got worse (0)
Nothing got worse.

new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new P2 Asymmetric secondary shape (INFO); new R2 Distinct from references (black masks) (PASS); new B13 Frame cost (PASS)

Changed pixels per shot: z40 0.0 %, z55 0.0 %, z25 0.0 %, close 0.1 %, strike_side 1.3 %, turns 0.4 %, cast 0.2 %, anim 0.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 2.0 -> 2.9 in res://art/units/wizards/vessa.tscn (root) (the head top; x1.45 now), or lower the head / crest 0.0 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Contrast in every team colour (meadow)** (WARN): shader_parameter/base_color of `fire_bronze` #9e6629 -> #ff8565 (13% of the visible body): predicted dE R3 meadow 68.1 -> 70.4, R3t fire 67.1 -> 69.5, R3t shadow 67.9 -> 68.8, R3t ice 41.6 -> 44.6, R3t nature 17.1 -> 24.0, R4k ash 68.8 -> 70.7 (want >= 24); other grounds heath 53.0, old_wood 69.7, riverbank 81.7, snow 70.0, sand 50.7, marsh 68.2; `fire_bronze` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `fire_pennon.tres` (#d94d1f, dE 24.6 from the wanted colour; no palette entry is close: a new palette entry is needed, or give the asset its own copy); team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `fire_cloth_dark` 42%, `fire_cloth` 17% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #2] _(from R3t Contrast in every team colour (meadow), shot teams)_
3. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #4] _(from B9m Meshes built per instance)_
4. **Vertices** (WARN): B4 4987 -> 2900 (want <= 3000): `Face` 1417 -> 709 verts; `Merged` 786 -> 393 verts; `Merged` 768 -> 384 verts; `Merged` 521 -> 261 verts; `Merged` 423 -> 212 verts; `Cape` 398 -> 267 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (protan) look alike on this model (dE 9.4): add a value step inside the team-colour area [fixes.json #5] _(from R6cb Team colours for colour-blind players, shot teams)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from ysolde (IoU 0.71): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (10 mesh + 1 multimesh); per pivot: Head 3, ArmR 2, Chest 2, Hips 2, (root) 1, ArmL 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 4987 (biggest: Face 1417, Merged 786, Merged 768, Merged 521) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (OrbLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (EmberMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 14 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 12 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 28 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 636 of 6284 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0012 ms process per instance (100 animated at 40 m: +0.12 ms process, render CPU +0.8 ms, GPU +0.95 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.025 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 38 | head top 2.9 m / body_height 2.0 (x1.45) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | INFO | identity crest: CrownFlames 0.61 m, Merged 0.44 m, Orb 0.41 m, Merged 0.46 m | wizard tier: a crest up to 0.7 m wide is part of the identity (the HP bar sits on it) |  |
| R10 | Footprint vs selection radius | INFO | x 0.75 / z 0.76 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1348 px (37 x 56 bbox; 55 m: 694 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 68.1, 0% of the body melts (within dE 15 of the ground); body L* 56.5 C 64.6 vs ground L* 61.7 C 48.7, hue gap 72 deg; top third (world height) dE 76.1, L* 65.6; per-pixel dE 74.4, outline 62.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 68.8, 0% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst sand: dE 50.3 (heath dE 51.1, old_wood dE 67.0, riverbank dE 79.1, snow dE 70.8, ash dE 68.8, sand dE 50.3, marsh dE 65.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 61% of body pixels change between kingdom colours (min pair 60%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 49 | worst nature colour: dE 17.1 (fire 67.1, shadow 67.9, ice 41.6, nature 17.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (protan): dE 9.4 on the team-colour area (normal vision 83.6; 845 px); deutan: fire / nature dE 22.3; protan: fire / nature dE 9.4; worst vs ground: nature colour (deutan) dE 5.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -12 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +25 (point 1 dL +25; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Orb; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst ice: dE 60.9, dL -8 (warm dE 67.3, ice dE 60.9, night dE 63.4, autumn dE 62.5); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.85 (min 0.78), area kept 96-102% (min 1314 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 84 | points per frame 1/1/1/1/0/0/1/1 (median 1, range 1, 2 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 83 | max IoU 0.71 (ysolde 0.71, emberdart_harrier_placeholder 0.58, ruin_warden 0.57, ash_hurler 0.5, pyre_adept 0.46, stormbottle_genie 0.45) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.6 m from the body centre at t 0.14 s (1.37 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 38% of the silhouette at its peak (t 0.4 s; 0.12 s 26%, 0.25 s 36%, 0.4 s 38%, 0.6 s 31%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 88 | 92 shapes over 5 body parts (18.4 per part: Hips 14, Head 37, ArmL 3, ArmR 17, Chest 21); 15% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.89 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 156% of the 3000 verts budget used (4690) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.72 at the close-up (92631 px), 2.71 at 25 m; close-up outline complexity 7.84 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 85 | outline complexity 2.41 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 65.6, bottom third L* 43.8 (+21, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.1 at 25 m, 11.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 87 | on the autumn floor: dE 35.8, 0% melts; body L* 57.2 C 65.9 vs floor L* 50.3 C 42.0; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 92 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 1417 v / 1 s; Root/Chest/Merged 786 v / 4 s; Root/Chest/ArmR/Merged 768 v / 5 s; Root/Hips/Merged 521 v / 5 s; Root/Chest/Head/Merged 423 v / 3 s; Root/Chest/Cape 398 v / 3 s; Root/Chest/ArmL/Merged 273 v / 3 s; Root/Chest/Head/CrownFlames 174 v / 1 s x6
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 5 in fixes.json (top: R8: body_height 2.0 -> 2.9 in res://art/units/wizards/vessa.tscn (root) (the head top; x1.45 now), or lower the head / crest 0.0 m)
