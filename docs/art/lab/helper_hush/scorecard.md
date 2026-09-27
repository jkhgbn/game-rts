# Art Lab scorecard: helper_hush

Scene `res://art/units/helpers/helper_hush/helper_hush.tscn` · kind **unit** / tier **wizard** · kingdom shadow · ground meadow · 2026-09-27 18:00:44 · lab v3.1

## Result: **WARN** · quality **94 / 100** (94.4) (previous run 95, -1)

0 FAIL · 1 WARN · 31 PASS · 18 info · 0 skipped · 41 s

## Before / after (vs the run of 2026-09-27 17:59:41 in `docs/art/lab/helper_hush`: quality 95 -> 94, -1)
### What got worse (1)
1. **P3 Tops light, bottoms dark: INFO 82 -> INFO 76 (-5)**. Now: top third L* 33.1, bottom third L* 25.2 (+7, world height). Was: top third L* 33.2, bottom third L* 24.3 (+8, world height)

new R5w Glow points while walking (flicker) (PASS)

### Score delta per check (5 changed, 48 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R4 | Contrast on the other grounds | PASS 97 | PASS 98 | +0.5 |
| R6cb | Team colours for colour-blind players | PASS 76 | PASS 75 | -0.9 |
| P3 | Tops light, bottoms dark | INFO 82 | INFO 76 | -5.5 |
| R5c | Glow points stand out (1 m surround) | PASS 91 | PASS 94 | +2.3 (noisy) |
| B13 | Frame cost | PASS 99 | PASS 93 | -6.3 (noisy) |

Changed pixels per shot: z40 0.4 %, z55 0.2 %, z25 0.4 %, close 7.5 %, strike_side 7.6 %, turns 3.2 %, cast 1.5 %, anim 1.7 %, silhouette 0.1 %, lineup 5.1 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (WARN): B4 6157 -> 3082 (want <= 3000): `Merged` 2091 -> 1046 verts; `Merged` 658 -> 329 verts; `Merged` 607 -> 304 verts; `Cape` 554 -> 277 verts; `Merged` 552 -> 276 verts; `Merged` 552 -> 276 verts; `Face` 335 -> 168 verts; `Merged` 246 -> 123 verts; `Merged` 246 -> 123 verts; `EdgeL` 156 -> 78 verts; `EdgeR` 156 -> 78 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.7): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +7 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.61): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Frame cost** (PASS): Cut the per-frame script cost (0.0033 ms per instance): write pivots only when they change, skip work at the far tiers _(from B13 Frame cost)_

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
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmL 2, ArmR 2, Chest 2, Head 2, (root) 1, Hips 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 6157 (biggest: Merged 2091, Merged 658, Merged 607, Cape 554) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (SmokeTrail) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 93 | 7 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 12 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 43 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 621 of 6157 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 93 | 0.0033 ms process per instance (100 animated at 40 m: +0.33 ms process, render CPU +2.27 ms, GPU +0.24 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 96 | head top 2.12 m / body_height 2.0 (x1.06) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R10 | Footprint vs selection radius | INFO | x 0.55 / z 0.79 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 597 px (33 x 39 bbox; 55 m: 305 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 82.9, 0% of the body melts (within dE 15 of the ground); body L* 33.5 C 29.8 vs ground L* 62.4 C 48.4, hue gap 165 deg; top third (world height) dE 89.1, L* 33.1; per-pixel dE 88.0, outline 60.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 38.3, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 98 | worst ash: dE 28.2 (heath dE 50.1, old_wood dE 50.2, riverbank dE 63.4, snow dE 65.1, ash dE 28.2, sand dE 74.3, marsh dE 38.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 44% of body pixels change between kingdom colours (min pair 42%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 45.7 (fire 64.3, shadow 82.3, ice 65.0, nature 45.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 75 | worst pair fire / nature (deutan): dE 7.7 on the team-colour area (normal vision 65.2; 282 px); deutan: fire / nature dE 7.7; protan: fire / nature dE 18.5; worst vs ground: fire colour (deutan) dE 40.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -1 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +31 (point 1 dL +31, point 2 dL +35; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): EdgeR, EdgeL; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 53.8, dL -5 (warm dE 82.5, ice dE 76.2, night dE 53.8, autumn dE 73.5); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 89 | walk frames vs rest: mean IoU 0.65 (min 0.61), area kept 102-114% (min 616 px), frame-to-frame IoU min 0.72; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 2/2/2/1/2/2/2/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.61 (tracker 0.61, nightblood_reaver 0.58, hollow_oathsworn_placeholder 0.55, gloomcap_elder 0.45, bleakbow 0.42, gloom_thrall 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.16 m from the body centre at t 0.14 s (1.15 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 40% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 84% of the silhouette at its peak (t 0.4 s; 0.12 s 34%, 0.25 s 37%, 0.4 s 84%, 0.6 s 53%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 85 | 109 shapes over 7 body parts (15.6 per part: LegL 5, LegR 5, Hips 22, Head 39, ArmL 8, ArmR 8, Chest 22); 32% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.883 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 205% of the 3000 verts budget used (6153) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.15 at the close-up (69941 px), 2.14 at 25 m; close-up outline complexity 5.99 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.29 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 76 | top third L* 33.1, bottom third L* 25.2 (+7, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.7 at 25 m, 21.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 59.4, 0% melts; body L* 32.4 C 24.6 vs floor L* 51.4 C 42.7 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.22 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 2091 v / 8 s; Root/Chest/Merged 658 v / 5 s; Root/Hips/Merged 607 v / 5 s; Root/Chest/Cape 554 v / 3 s; Root/Chest/ArmL/Merged 552 v / 4 s; Root/Chest/ArmR/Merged 552 v / 4 s; Root/Chest/Head/Face 335 v / 5 s; Root/Hips/LegL/Merged 246 v / 3 s
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B4 6157 -> 3082 (want <= 3000): `Merged` 2091 -> 1046 verts; `Merged` 658 -> 329 verts; `Merged` 607 -> 304 verts; `Cape` 554 -> 277 verts; `Merged` 552 -> 276 )
