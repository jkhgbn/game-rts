# Art Lab scorecard: scorchling

Scene `res://art/units/fire/scorchling/scorchling.tscn` · kind **unit** / tier **soldier** · kingdom fire · ground meadow · 2026-09-27 18:07:19 · lab v3.1

## Result: **PASS** · quality **95 / 100** (94.7) (previous run 95, +0)

0 FAIL · 0 WARN · 33 PASS · 17 info · 0 skipped · 37 s

## Before / after (vs the run of 2026-09-27 18:06:49 in `docs/art/lab/scorchling`: quality 95 -> 95, +0)
### What got worse (0)
Nothing got worse.

### Score delta per check (6 changed, 50 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C4 | Inner detail (close-up / 25 m) | INFO 70 | INFO 69 | -1.8 |
| R6cb | Team colours for colour-blind players | PASS 80 | PASS 80 | +0.6 |
| R5c | Glow points stand out (1 m surround) | PASS 89 | PASS 86 | -3.3 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 54 | INFO 53 | -0.7 |
| R5w | Glow points while walking (flicker) | PASS 100 | PASS 96 | -3.8 (noisy) |
| B13 | Frame cost | PASS 100 | PASS 93 | -7.2 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.1 %, z25 0.1 %, close 4.5 %, strike_side 12.5 %, turns 9.4 %, cast 1.4 %, anim 1.7 %, silhouette 0.1 %, lineup 3.8 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.5): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
2. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (2.16 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
3. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 24.9): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 15% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
5. **Silhouette area at 40 m** (PASS): Grow the read at 40 m (now 215 px): push the key shape (weapon, horns, crest, back mass) 15-25 % bigger _(from R1 Silhouette area at 40 m, shot z40)_
6. **Frame cost** (PASS): Cut the per-frame script cost (0.0033 ms per instance): write pivots only when they change, skip work at the far tiers _(from B13 Frame cost)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 91 | 2217 (biggest: Merged 486, Merged 405, Merged 290, Merged 290) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 53 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 309 of 2401 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 93 | 0.0033 ms process per instance (100 animated at 40 m: +0.33 ms process, render CPU +1.57 ms, GPU +0.86 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.001 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 95 | head top 1.19 m / body_height 1.1 (x1.09) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.54 / z 0.54 m (radius 0.35, from scorchling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 96 | 215 px (20 x 24 bbox; 55 m: 112 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 55.3, 0% of the body melts (within dE 15 of the ground); body L* 48.6 C 43.9 vs ground L* 63.4 C 48.2, hue gap 70 deg; top third (world height) dE 54.1, L* 60.0; per-pixel dE 62.1, outline 53.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 46.2, 2% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 30.7 (heath dE 30.7, old_wood dE 45.1, riverbank dE 61.4, snow dE 58.3, ash dE 46.2, sand dE 42.7, marsh dE 44.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 89 | 15% of body pixels change between kingdom colours (min pair 13%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 42.3 (fire 52.0, shadow 53.8, ice 46.8, nature 42.3) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 13.1 on the team-colour area (normal vision 68.1; 38 px); deutan: fire / nature dE 13.1; protan: fire / nature dE 20.1; worst vs ground: fire colour (deutan) dE 15.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.6 m, 1.0 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 86 | worst dL +14 (point 1 dL +22, point 2 dL +14; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Tuft, PopRing; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 30.8, dL -1 (warm dE 53.8, ice dE 47.0, night dE 30.8, autumn dE 50.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.77 (min 0.68), area kept 101-104% (min 214 px), frame-to-frame IoU min 0.65; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 2/2/2/1/2/2/2/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 96 | max IoU 0.5 (scorchling_placeholder 0.5, ashveil_saboteur 0.47, magpie 0.43, cinder_arbalest 0.4, cinder_hand 0.35, bristleback 0.33) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.16 m from the body centre at t 0.14 s (1.13 m forward; geometry clipped at the ground); declared 1.4 m (UnitType attack_range (scorchling.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 89% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 43% of the silhouette at its peak (t 0.25 s; 0.12 s 32%, 0.25 s 43%, 0.4 s 11%, 0.6 s 16%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 86 | 70 shapes over 7 body parts (10.0 per part: LegL 6, LegR 6, Hips 7, Head 21, ArmL 10, ArmR 10, Chest 10); 47% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.931 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 88% of the 2500 verts budget used (2213) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 15 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 69 | inner edges per outline px: 2.16 at the close-up (68283 px), 1.15 at 25 m; close-up outline complexity 7.14 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.87 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 60.0, bottom third L* 39.9 (+20, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.5 at 25 m, 20.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 53 | on the autumn floor: dE 24.9, 0% melts; body L* 48.2 C 48.1 vs floor L* 52.6 C 43.3; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.35 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 486 v / 6 s; Root/Chest/Merged 405 v / 4 s; Root/Chest/ArmL/Merged 290 v / 3 s; Root/Chest/ArmR/Merged 290 v / 3 s; Root/Hips/Merged 208 v / 4 s; Root/Hips/LegL/Merged 188 v / 2 s; Root/Hips/LegR/Merged 188 v / 2 s; Root/Chest/Head/Tuft 104 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
