# Art Lab scorecard: briar_roc

Scene `res://art/units/nature/briar_roc/briar_roc.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-09-27 17:52:02 · lab v3.1

## Result: **WARN** · quality **87 / 100** (87.2) (previous run 87, +0)

0 FAIL · 3 WARN · 29 PASS · 18 info · 0 skipped · 38 s

## Before / after (vs the run of 2026-09-27 17:50:52 in `docs/art/lab/briar_roc`: quality 87 -> 87, +0)
### What got worse (3)
1. **C3 Palette depth (close-up): INFO 68 -> INFO 57 (-10)**. Now: 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %). Was: 11 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %)
2. **R11 Reads while walking (40 m) (flyer: wing beat): INFO 88 -> INFO 80 (-9) (noisy check: re-run before acting)**. Now: walk frames vs rest: mean IoU 0.4 (min 0.27), area kept 84-112% (min 1478 px), frame-to-frame IoU min 0.46; 8 frames 0.09 s apart. Was: walk frames vs rest: mean IoU 0.33 (min 0.25), area kept 89-116% (min 1503 px), frame-to-frame IoU min 0.48; 8 frames 0.
3. **P3 Tops light, bottoms dark: INFO 100 -> INFO 92 (-8)**. Now: top third L* 73.7, bottom third L* 63.0 (+10, screen rows). Was: top third L* 74.4, bottom third L* 61.0 (+13, screen rows)

### What got better (3)
C4 Inner detail (close-up / 25 m): INFO 73 -> INFO 78 (+5); R2 Distinct from references (black masks): PASS 95 -> PASS 99 (+4); R7 HP bar over the body at 40 m: PASS 94 -> PASS 96 (+2)

### Score delta per check (9 changed, 44 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 68 | INFO 57 | -10.0 |
| C4 | Inner detail (close-up / 25 m) | INFO 73 | INFO 78 | +5.1 |
| R6 | Team-colour visibility at 40 m | PASS 80 | PASS 81 | +0.8 |
| R7 | HP bar over the body at 40 m | PASS 94 | PASS 96 | +2.1 |
| P3 | Tops light, bottoms dark | INFO 100 | INFO 92 | -7.6 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 35 | INFO 37 | +1.9 |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 88 | INFO 80 | -8.5 (noisy) |
| P2 | Asymmetric secondary shape | INFO 43 | INFO 41 | -1.7 |
| R2 | Distinct from references (black masks) | PASS 95 | PASS 99 | +3.9 |

Changed pixels per shot: z40 4.8 %, z55 3.4 %, z25 6.9 %, close 20.1 %, strike_side 8.2 %, turns 16.3 %, cast 18.8 %, anim 14.9 %, silhouette 1.0 %, lineup 17.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.9 -> 1.2, or pull the widest parts in to x <= 1.58 / z <= 1.58 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow WingL2Mesh 0.73 m, WingR2Mesh 0.73 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 14.2): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 8 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
5. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.83): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
6. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.09): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 31 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 13 drawn (13 mesh + 0 multimesh); per pivot: (root) 1, Body 1, Head 1, Jaw 1, LegFL 1, LegFR 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 96 | 4693 (biggest: BodyMesh 889, HeadMesh 815, WingL2Mesh 494, WingR2Mesh 494) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 88 | 6 (HeadMesh, WingL2Mesh, WingLMesh, WingR2Mesh, WingRMesh, BodyMesh) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 8 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 13 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1609 of 6368 triangles (25%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0008 ms process per instance (100 animated at 40 m: +0.08 ms process, render CPU +2.27 ms, GPU +1.59 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 0.9 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | WingL2Mesh 0.73 m, WingR2Mesh 0.73 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 2.11 / z 1.37 m (radius 0.9, from briar_roc.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1699 px (109 x 60 bbox; 55 m: 871 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 90 | mean-colour dE 28.3, 1% of the body melts (within dE 15 of the ground); body L* 64.8 C 44.7 vs ground L* 59.0 C 51.8, hue gap 32 deg; top third (world height) dE 29.2, L* 64.6; per-pixel dE 42.0, outline 38.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 45.5, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 86 | worst heath: dE 18.9 (heath dE 18.9, old_wood dE 45.5, riverbank dE 36.7, snow dE 49.1, ash dE 61.0, sand dE 20.5, marsh dE 60.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 81 | 8% of body pixels change between kingdom colours (min pair 8%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 87 | worst nature colour: dE 20.4 (fire 27.3, shadow 29.9, ice 24.2, nature 20.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 14.2 on the team-colour area (normal vision 80.5; 152 px); deutan: fire / nature dE 14.2; protan: fire / nature dE 21.2; worst vs ground: fire colour (deutan) dE 5.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -15 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.7 m, 2.34 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +16 (point 1 dL +16; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/2): Neck1Mesh; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 85 | worst night: dE 17.9, dL +10 (warm dE 27.3, ice dE 21.2, night dE 17.9, autumn dE 26.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 80 | walk frames vs rest: mean IoU 0.4 (min 0.27), area kept 84-112% (min 1478 px), frame-to-frame IoU min 0.46; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 2/1/1/1/1/2/1/1 (median 1, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 99 | max IoU 0.47 (roc 0.47, bramblehorn 0.25, mossback 0.24, vinelasher 0.08); wing phase matched to the target's (p 0.66; residual per flyer ref: roc 0.0) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | PASS 92 | tip reaches 3.36 m from the body centre at t 0.24 s (3.06 m forward; geometry clipped at the ground); declared 4.0 m (UnitType attack_range (briar_roc.tres)) | the strike frame shows the weapon tip at >= 80% of the declared reach, above the ground (side frames: strike_side.jpg) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 100% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 94% of the silhouette at its peak (t 0.12 s; 0.12 s 94%, 0.25 s 65%, 0.4 s 90%, 0.6 s 94%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.82 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 67 | 135 shapes over 12 body parts (11.3 per part: Jaw 1, Head 22, Neck2 1, Neck1 6, WingL2 17, WingL 7, WingR2 17, WingR 7, Tail1 15, LegFL 4, LegFR 10, Body 28); 8% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.832 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 78% of the 6000 verts budget used (4689) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 57 | 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 78 | inner edges per outline px: 1.58 at the close-up (26497 px), 2.7 at 25 m; close-up outline complexity 18.77 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.92 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 92 | top third L* 73.7, bottom third L* 63.0 (+10, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.2 at 25 m, 12.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 37 | on the autumn floor: dE 19.8, 2% melts; body L* 62.4 C 47.4 vs floor L* 46.6 C 40.0; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 41 | front-view asymmetry 0.09 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Body/BodyMesh 889 v / 4 s; Root/Body/Neck1/Neck2/Head/HeadMesh 815 v / 4 s; Root/Body/WingL/WingL2/WingL2Mesh 494 v / 3 s; Root/Body/WingR/WingR2/WingR2Mesh 494 v / 3 s; Root/Body/WingL/WingLMesh 372 v / 3 s; Root/Body/WingR/WingRMesh 372 v / 3 s; Root/Body/LegFR/LegFRMesh 353 v / 3 s; Root/Body/Tail1/Tail1Mesh 348 v / 3 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: R10: raise UnitType.radius 0.9 -> 1.2, or pull the widest parts in to x <= 1.58 / z <= 1.58 m)
