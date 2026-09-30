# Art Lab scorecard: briar_roc

Scene `res://art/units/nature/briar_roc/briar_roc.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-09-30 11:04:03 · lab v3.1

## Result: **WARN** · quality **86 / 100** (86.4) (previous run 88, -2)

0 FAIL · 5 WARN · 28 PASS · 18 info · 0 skipped · 29 s

## Before / after (vs the run of 2026-09-30 09:53:10 in `docs/art/lab/briar_roc`: quality 88 -> 86, -2)
### What got worse (6)
1. **R3t Contrast in every team colour (meadow): PASS 88 -> WARN 50 (-38)**. Now: worst nature colour: dE 17.4 (fire 23.5, shadow 26.0, ice 20.9, nature 17.4). Was: worst nature colour: dE 21.7 (fire 44.9, shadow 51.0, ice 33.3, nature 21.7)
2. **R6 Team-colour visibility at 40 m: PASS 100 -> PASS 80 (-20)**. Now: 8% of body pixels change between kingdom colours (min pair 8%). Was: 28% of body pixels change between kingdom colours (min pair 28%)
3. **R7 HP bar over the body at 40 m: PASS 100 -> PASS 93 (-7)**. Now: bar hides 6% of the silhouette (gap -21 px). Was: bar hides 0% of the silhouette (gap 1 px)
4. **S1 Style bible: golden autumn (style-autumn.md 3): INFO 38 -> INFO 20 (-18)**. Now: on the autumn floor: dE 14.5, 4% melts; body L* 56.5 C 42.9 vs floor L* 45.9 C 39.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry). Was: on the autumn floor: dE 20.2, 2% melts; body L* 62.1 C 47.0 vs floor L* 45.9 C 39.6; nature team colour vs the floor swa
5. **R5c Glow points stand out (1 m surround): PASS 93 -> PASS 86 (-7) (noisy check: re-run before acting)**. Now: worst dL +18 (point 1 dL +18; ring 24 px = 1.0 m at 40 m). Was: worst dL +30 (point 1 dL +32, point 2 dL +30; ring 24 px = 1.0 m at 40 m)
6. **R12 Contrast under every light preset (meadow): PASS 85 -> PASS 82 (-3)**. Now: worst night: dE 15.7, dL +8 (warm dE 26.8, ice dE 20.7, night dE 15.7, autumn dE 25.0); night = lab stand-in (warm preset, dim moon sun). Was: worst night: dE 18.3, dL +10 (warm dE 28.3, ice dE 21.8, night dE 18.3, autumn dE 27.3); night = lab stand-in (warm pres

### What got better (4)
P3 Tops light, bottoms dark: INFO 0 -> INFO 100 (+100); R4 Contrast on the other grounds: PASS 82 -> PASS 86 (+4); C4 Inner detail (close-up / 25 m): INFO 97 -> INFO 100 (+3); P2 Asymmetric secondary shape: INFO 48 -> INFO 51 (+3)

new B9m Meshes built per instance (WARN)

### Score delta per check (14 changed, 40 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 68 | INFO 67 | -1.0 |
| C4 | Inner detail (close-up / 25 m) | INFO 97 | INFO 100 | +3.4 |
| R4 | Contrast on the other grounds | PASS 82 | PASS 86 | +4.2 |
| R6 | Team-colour visibility at 40 m | PASS 100 | PASS 80 | -20.2 |
| R3t | Contrast in every team colour (meadow) | PASS 88 | WARN 50 | -38.2 |
| R7 | HP bar over the body at 40 m | PASS 100 | PASS 93 | -7.4 |
| A3r | Weapon reach at the strike | PASS 92 | PASS 93 | +0.8 |
| P3 | Tops light, bottoms dark | INFO 0 | INFO 100 | +100.0 |
| P4 | Detail density 25 m / 40 m | INFO 100 | INFO 96 | -4.0 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 93 | PASS 86 | -7.0 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 85 | PASS 82 | -3.3 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 38 | INFO 20 | -17.8 |
| R5w | Glow points while walking (flicker) | PASS 89 | PASS 85 | -3.8 (noisy) |
| P2 | Asymmetric secondary shape | INFO 48 | INFO 51 | +3.1 |

Changed pixels per shot: z40 4.2 %, z55 5.4 %, z25 10.1 %, close 10.4 %, strike_side 4.8 %, turns 53.1 %, cast 6.5 %, anim 7.6 %, silhouette 5.8 %, lineup 20.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast in every team colour (meadow)** (WARN): shader_parameter/base_color of `briar_dryleaf` #b87a2e -> #ea8f55 (25% of the visible body): predicted dE R3 meadow 26.4 -> 31.7, R3t fire 23.5 -> 29.7, R3t shadow 26.0 -> 31.6, R3t ice 20.9 -> 26.8, R3t nature 17.4 -> 24.0, R4k old_wood 45.2 -> 47.8 (want >= 24); other grounds heath 19.6, riverbank 37.9, snow 47.6, ash 61.4, sand 18.2, marsh 60.8 [fixes.json #1] _(from R3t Contrast in every team colour (meadow), shot teams)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow WingL2Mesh 0.73 m, WingR2Mesh 0.73 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 1.1 -> 1.2, or pull the widest parts in to x <= 1.93 / z <= 1.93 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
4. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #4] _(from B9m Meshes built per instance)_
5. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 13.8): add a value step inside the team-colour area [fixes.json #5] _(from R6cb Team colours for colour-blind players, shot teams)_
6. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 32 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Head 2, (root) 1, Body 1, Jaw 1, LegFL 1, LegFR 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 96 | 4623 (body + face above its allowance: face 352 v, allowance 800, total 4975; biggest: BodyMesh 889, HeadMesh 745, WingL2Mesh 494, WingR2Mesh 494) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 88 | 6 (HeadMesh, WingL2Mesh, WingLMesh, WingR2Mesh, WingRMesh, BodyMesh) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 9 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 34 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1638 of 7000 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0015 ms process per instance (100 animated at 40 m: +0.15 ms process, render CPU +1.06 ms, GPU +0.71 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 0.9 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | WingL2Mesh 0.73 m, WingR2Mesh 0.73 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 2.11 / z 1.37 m (radius 1.1, from briar_roc.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1677 px (103 x 67 bbox; 55 m: 853 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 88 | mean-colour dE 26.4, 1% of the body melts (within dE 15 of the ground); body L* 64.5 C 44.4 vs ground L* 59.1 C 51.5, hue gap 30 deg; top third (world height) dE 27.0, L* 65.1; per-pixel dE 41.4, outline 39.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 45.2, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 86 | worst heath: dE 18.9 (heath dE 18.9, old_wood dE 45.2, riverbank dE 34.3, snow dE 48.8, ash dE 60.6, sand dE 20.8, marsh dE 59.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 80 | 8% of body pixels change between kingdom colours (min pair 8%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 50 | worst nature colour: dE 17.4 (fire 23.5, shadow 26.0, ice 20.9, nature 17.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 13.8 on the team-colour area (normal vision 78.5; 137 px); deutan: fire / nature dE 13.8; protan: fire / nature dE 20.7; worst vs ground: fire colour (deutan) dE 5.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 93 | bar hides 6% of the silhouette (gap -21 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.7 m, 2.86 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 86 | worst dL +18 (point 1 dL +18; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/2/1): Neck2Mesh; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 82 | worst night: dE 15.7, dL +8 (warm dE 26.8, ice dE 20.7, night dE 15.7, autumn dE 25.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.33 (min 0.22), area kept 121-154% (min 1488 px), frame-to-frame IoU min 0.45; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 2/2/2/2/1/1/1/1 (median 2, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.26 (thornback_charger_placeholder 0.26, stormbottle_genie 0.26, stagrunner 0.25, glade_outrider 0.23, mossback 0.22, hollow_stag 0.21); flyer: no flyer reference to phase-match | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | PASS 93 | tip reaches 3.45 m from the body centre at t 0.24 s (3.08 m forward; geometry clipped at the ground); declared 4.0 m (UnitType attack_range (briar_roc.tres)) | the strike frame shows the weapon tip at >= 80% of the declared reach, above the ground (side frames: strike_side.jpg) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 100% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 94% of the silhouette at its peak (t 0.6 s; 0.12 s 93%, 0.25 s 71%, 0.4 s 89%, 0.6 s 94%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.81 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 67 | 149 shapes over 12 body parts (12.4 per part: Jaw 1, Head 36, Neck2 1, Neck1 6, WingL2 17, WingL 7, WingR2 17, WingR 7, Tail1 15, LegFL 4, LegFR 10, Body 28); 8% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.841 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 82% of the 6000 verts budget used (4971) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 70 | 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 1.85 at the close-up (28929 px), 2.51 at 25 m; close-up outline complexity 17.01 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.2 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 74.7, bottom third L* 54.9 (+19, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 96 | inner detail 11.2 at 25 m, 12.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 20 | on the autumn floor: dE 14.5, 4% melts; body L* 56.5 C 42.9 vs floor L* 45.9 C 39.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 51 | front-view asymmetry 0.11 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
`{"draw":16,"face_verts":800,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Body/BodyMesh 889 v / 4 s; Root/Body/Neck1/Neck2/Head/HeadMesh 745 v / 4 s; Root/Body/WingL/WingL2/WingL2Mesh 494 v / 3 s; Root/Body/WingR/WingR2/WingR2Mesh 494 v / 3 s; Root/Body/WingL/WingLMesh 372 v / 3 s; Root/Body/WingR/WingRMesh 372 v / 3 s; Root/Body/LegFR/LegFRMesh 353 v / 3 s; Root/Body/Neck1/Neck2/Head/Face 352 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 5 in fixes.json (top: shader_parameter/base_color of `briar_dryleaf` #b87a2e -> #ea8f55 (25% of the visible body): predicted dE R3 meadow 26.4 -> 31.7, R3t fire 23.5 -> 29.7, R3t sha)
