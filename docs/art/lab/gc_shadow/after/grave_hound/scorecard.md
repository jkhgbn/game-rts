# Art Lab scorecard: grave_hound

Scene `res://art/units/shadow/grave_hound.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-10-15 13:01:59 · lab v3.1

## Result: **PASS** · quality **95 / 100** (94.5) (previous run 95, +0)

0 FAIL · 0 WARN · 32 PASS · 17 info · 0 skipped · 25 s

## Before / after (vs the run of 2026-10-15 12:48:05 in `docs/art/lab/gc_shadow/after/grave_hound`: quality 95 -> 95, +0)
### What got worse (2)
1. **C3 Palette depth (close-up): INFO 60 -> INFO 48 (-13)**. Now: 9 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %). Was: 9 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %)
2. **R6cb Team colours for colour-blind players: PASS 82 -> PASS 77 (-5)**. Now: worst pair fire / nature (deutan): dE 9.2 on the team-colour area (normal vision 54.7; 74 px); deutan: fire / nature dE 9.2; protan: fire / nature dE 17.6; worst vs ground: fire co. Was: worst pair fire / nature (deutan): dE 13.5 on the team-colour area (normal vision 60.1; 70 px); deutan: fire / nature dE

### Score delta per check (5 changed, 47 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 60 | INFO 48 | -12.5 |
| R6 | Team-colour visibility at 40 m | PASS 91 | PASS 92 | +1.1 |
| R6cb | Team colours for colour-blind players | PASS 82 | PASS 77 | -4.8 |
| R5w | Glow points while walking (flicker) | PASS 92 | PASS 100 | +8.3 (noisy) |
| B13 | Frame cost | PASS 92 | PASS 91 | -0.6 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.1 %, z25 0.2 %, close 6.9 %, strike_side 13.1 %, turns 5.3 %, cast 6.0 %, anim 4.5 %, silhouette 4.9 %, lineup 10.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 8 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (20.8): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 18% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
4. **Contrast on the other grounds** (PASS): On heath the body drops to dE 25.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Frame cost** (PASS): Cut the per-frame script cost (0.0037 ms per instance): write pivots only when they change, skip work at the far tiers _(from B13 Frame cost)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Head 2, (root) 1, Jaw 1, LegBL 1, LegBR 1, LegFL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1382 (body + face above its allowance: face 412 v, allowance 800, total 1794; biggest: Merged 851, Face 412, Merged 113, Merged 76) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 9 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 23 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 17 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 700 of 2998 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 91 | 0.0037 ms process per instance (100 animated at 40 m: +0.37 ms process, render CPU +0.65 ms, GPU +0.27 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.029 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.28 / z 1.09 m (radius 0.4, from grave_hound.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 355 px (28 x 40 bbox; 55 m: 186 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 59.7, 0% of the body melts (within dE 15 of the ground); body L* 61.3 C 15.3 vs ground L* 64.8 C 46.7, hue gap n/a (body C* <= 25); top third (world height) dE 53.6, L* 76.6; per-pixel dE 68.8, outline 51.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 48.4, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 94 | worst heath: dE 25.4 (heath dE 25.4, old_wood dE 48.2, riverbank dE 55.1, snow dE 33.2, ash dE 39.1, sand dE 45.5, marsh dE 48.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 92 | 18% of body pixels change between kingdom colours (min pair 16%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 43.1 (fire 49.2, shadow 57.6, ice 49.3, nature 43.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 9.2 on the team-colour area (normal vision 54.7; 74 px); deutan: fire / nature dE 9.2; protan: fire / nature dE 17.6; worst vs ground: fire colour (deutan) dE 35.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.5 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +14 (point 1 dL +14; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 48.8, dL +11 (warm dE 59.7, ice dE 55.2, night dE 48.8, autumn dE 52.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 92 | walk frames vs rest: mean IoU 0.71 (min 0.63), area kept 97-100% (min 349 px), frame-to-frame IoU min 0.59; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 93 | max IoU 0.56 (bristleback 0.56, barrow_ghoul 0.36, barrow_ghoul_placeholder 0.34, nightbolt 0.3, shade 0.3, gloomcap_sprout 0.28) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.27 m from the body centre at t 0.08 s (1.27 m forward; geometry clipped at the ground); declared 1.4 m (UnitType attack_range (grave_hound.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 52% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 16% of the silhouette at its peak (t 0.4 s; 0.12 s 9%, 0.25 s 14%, 0.4 s 16%, 0.6 s 13%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 93 | 63 shapes over 8 body parts (7.9 per part: Jaw 5, Head 23, LegFL 4, LegFR 4, LegBL 4, LegBR 4, Tail 1, Mount 18); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.903 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 71% of the 2500 verts budget used (1790) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 48 | 9 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.71 at the close-up (48433 px), 1.46 at 25 m; close-up outline complexity 7.93 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.62 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 76.6, bottom third L* 10.2 (+66, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 20.8 at 25 m, 26.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 43.1, 0% melts; body L* 58.4 C 14.6 vs floor L* 53.6 C 43.5; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.29 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 851 v / 4 s; Root/Mount/Head/Face 412 v / 1 s; Root/Mount/Head/Merged 113 v / 1 s; Root/Mount/LegFL/Merged 76 v / 2 s; Root/Mount/LegFR/Merged 76 v / 2 s; Root/Mount/LegBL/Merged 76 v / 2 s; Root/Mount/LegBR/Merged 76 v / 2 s; Root/Mount/Head/Jaw/MeshInstance3D 66 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
