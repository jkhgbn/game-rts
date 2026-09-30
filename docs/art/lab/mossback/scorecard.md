# Art Lab scorecard: mossback

Scene `res://art/units/nature/mossback/mossback.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-09-30 11:07:29 · lab v3.1

## Result: **WARN** · quality **91 / 100** (90.9) (previous run 93, -2)

0 FAIL · 2 WARN · 29 PASS · 18 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-09-26 22:36:31 in `docs/art/lab/mossback`: quality 93 -> 91, -2)
### What got worse (3)
1. **R6 Team-colour visibility at 40 m: PASS 90 -> WARN 45 (-45)**. Now: 7% of body pixels change between kingdom colours (min pair 7%). Was: 16% of body pixels change between kingdom colours (min pair 8%)
2. **P1 Silhouette hook: INFO 10 -> INFO 2 (-8)**. Now: outline complexity 1.32. Was: outline complexity 1.43
3. **B2 Draw instances at rest: PASS 92 -> PASS 89 (-3)**. Now: 15. Was: 14

### What got better (2)
P2 Asymmetric secondary shape: INFO 45 -> INFO 53 (+8); R2 Distinct from references (black masks): PASS 96 -> PASS 100 (+4)

new B1a Authored build parts (before the merge) (INFO); new B11 Surfaces per instance (INFO); new B12 Downward-facing triangles (INFO); new C1 Shape richness (secondary shapes) (INFO); new C2 Vertex use vs budget (INFO); new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (old_wood) (WARN); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (PASS); new A3r Weapon reach at the strike (INFO); new R5c Glow points stand out (1 m surround) (PASS); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new R5w Glow points while walking (flicker) (PASS); new A4 Cast pose reads (play_cast) (INFO)

### Score delta per check (8 changed, 27 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B2 | Draw instances at rest | PASS 92 | PASS 89 | -2.8 |
| B4 | Vertices | PASS 86 | PASS 87 | +0.9 |
| R3 | Contrast vs ground (meadow) | PASS 94 | PASS 93 | -0.7 |
| R4 | Contrast on the other grounds | PASS 81 | PASS 79 | -1.5 |
| R6 | Team-colour visibility at 40 m | PASS 90 | WARN 45 | -45.1 |
| P1 | Silhouette hook | INFO 10 | INFO 2 | -8.4 |
| P2 | Asymmetric secondary shape | INFO 45 | INFO 53 | +8.4 |
| R2 | Distinct from references (black masks) | PASS 96 | PASS 100 | +4.1 |

## Improve next
1. **Contrast on the home ground (old_wood)** (WARN): shader_parameter/base_color of `mossback_moss` #45664f -> #7ac5b5 (15% of the visible body): predicted dE R3 meadow 32.1 -> 32.1, R3t fire 34.6 -> 33.8, R3t shadow 39.5 -> 38.0, R3t ice 35.4 -> 34.9, R3t nature 31.7 -> 31.9, R4k old_wood 17.4 -> 24.0 (want >= 24); other grounds heath 16.1, riverbank 18.4, snow 44.0, ash 37.1, sand 38.5, marsh 41.7 [fixes.json #1] _(from R4k Contrast on the home ground (old_wood), shot z40)_
2. **Team-colour visibility at 40 m** (WARN): R6 Team-colour visibility at 40 m: Give the team colour more top-facing area (now 7% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top [fixes.json #2] _(from R6 Team-colour visibility at 40 m, shot teams)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.32): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.12): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 13.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 27.7): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 32 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 15 drawn (15 mesh + 0 multimesh); per pivot: Crown 3, Head 2, (root) 1, Jaw 1, LegBL 1, LegBR 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 89 | 15 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 87 | 5714 (body + face above its allowance: face 360 v, allowance 800, total 6074; biggest: Merged 2611, Merged 468, Merged 410, Face 360) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 22 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 2 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 46 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1176 of 7524 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.07 ms process, render CPU +1.16 ms, GPU +0.72 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.017 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 1.49 / z 2.49 m (radius 0.45, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 4886 px (89 x 91 bbox; 55 m: 2523 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 32.1, 1% of the body melts (within dE 15 of the ground); body L* 45.3 C 22.1 vs ground L* 63.2 C 48.7, hue gap n/a (body C* <= 25); top third (world height) dE 27.6, L* 58.4; per-pixel dE 41.8, outline 33.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | **WARN** 50 | dE 17.4, 3% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 79 | worst heath: dE 13.3 (heath dE 13.3, old_wood dE 17.4, riverbank dE 16.6, snow dE 49.5, ash dE 33.4, sand dE 40.0, marsh dE 36.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | **WARN** 45 | 7% of body pixels change between kingdom colours (min pair 7%) | >= 8% (FAIL = set_team_color changes nothing) | Put the team colour on a big, top-facing mass (cloth, plates, cape, caparison); ~25-45 %% of the surface (art-keep 0.2 / art-units 1.3) |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 31.7 (fire 34.6, shadow 39.5, ice 35.4, nature 31.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 13.3 on the team-colour area (normal vision 77.7; 383 px); deutan: fire / nature dE 13.3; protan: fire / nature dE 23.0; worst vs ground: fire colour (deutan) dE 28.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -13 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +6 (point 1 dL +40, soft 1 dL +24 (counts), soft 2 dL +21 (counts), soft 3 dL +6 (counts), soft 4 dL +20 (counts), soft 5 dL +15 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 6 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 88 | worst night: dE 20.1, dL -6 (warm dE 32.3, ice dE 32.3, night dE 20.1, autumn dE 29.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.92 (min 0.9), area kept 98-101% (min 4820 px), frame-to-frame IoU min 0.93; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.3 (stagrunner 0.3, glade_outrider 0.28, hollow_stag 0.25, bramble_harrier 0.23, bramble_harrier_placeholder 0.21, stormbottle_genie 0.17) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 3.23 m from the body centre at t 0.14 s (3.23 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 89 | strike pose changes 19% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 14% of the silhouette at its peak (t 0.25 s; 0.12 s 12%, 0.25 s 14%, 0.4 s 13%, 0.6 s 1%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.61 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 179 shapes over 11 body parts (16.3 per part: Jaw 3, Head 28, LegFL 8, LegFR 8, LegBL 9, LegBR 9, Crown 24, TreeA 8, TreeB 5, TreeC 5, Mount 72); 5% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.945 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 101% of the 6000 verts budget used (6070) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.86 at the close-up (75879 px), 5.03 at 25 m; close-up outline complexity 3.77 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 2 | outline complexity 1.32 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 58.4, bottom third L* 31.5 (+26, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.2 at 25 m, 6.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 52 | on the autumn floor: dE 27.7, 1% melts; body L* 42.1 C 23.7 vs floor L* 51.6 C 42.6 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 53 | front-view asymmetry 0.12 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"face_verts":800,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 2611 v / 13 s; Root/Mount/Head/Merged 468 v / 5 s; Root/Mount/TreeA/Crown/Merged 410 v / 2 s; Root/Mount/Head/Face 360 v / 1 s; Root/Mount/TreeB/Crown/Merged 356 v / 2 s; Root/Mount/TreeC/Crown/Merged 302 v / 2 s; Root/Mount/LegBL/Merged 277 v / 3 s; Root/Mount/LegBR/Merged 277 v / 3 s
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: shader_parameter/base_color of `mossback_moss` #45664f -> #7ac5b5 (15% of the visible body): predicted dE R3 meadow 32.1 -> 32.1, R3t fire 34.6 -> 33.8, R3t sha)
