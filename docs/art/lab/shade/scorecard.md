# Art Lab scorecard: shade

Scene `res://art/units/shadow/shade.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-10-15 16:14:15 · lab v3.1

## Result: **PASS** · quality **97 / 100** (97.2) (previous run 98, -1)

0 FAIL · 0 WARN · 33 PASS · 17 info · 0 skipped · 28 s

## Before / after (vs the run of 2026-09-26 22:54:13 in `docs/art/lab/shade`: quality 98 -> 97, -1)
### What got worse (3)
1. **R4 Contrast on the other grounds: PASS 100 -> PASS 89 (-11)**. Now: worst ash: dE 21.2 (heath dE 41.9, old_wood dE 43.2, riverbank dE 57.5, snow dE 64.9, ash dE 21.2, sand dE 71.1, marsh dE 31.0). Was: worst heath: dE 51.7 (heath dE 51.7, old_wood dE 54.4, riverbank dE 68.2)
2. **P1 Silhouette hook: INFO 100 -> INFO 88 (-12)**. Now: outline complexity 2.44. Was: outline complexity 2.92
3. **R7 HP bar over the body at 40 m: PASS 100 -> PASS 96 (-4)**. Now: bar hides 3% of the silhouette (gap -5 px). Was: bar hides 0% of the silhouette (gap 0 px)

### What got better (2)
P3 Tops light, bottoms dark: INFO 59 -> INFO 100 (+41); B1 Meshes after the kit merge: PASS 86 -> PASS 100 (+14)

new B1a Authored build parts (before the merge) (INFO); new B11 Surfaces per instance (INFO); new B12 Downward-facing triangles (INFO); new C1 Shape richness (secondary shapes) (INFO); new C2 Vertex use vs budget (INFO); new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (marsh) (PASS); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (PASS); new A3r Weapon reach at the strike (INFO); new R5c Glow points stand out (1 m surround) (PASS); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new R5w Glow points while walking (flicker) (PASS); new A4 Cast pose reads (play_cast) (INFO); new P2 Asymmetric secondary shape (INFO); new R2 Distinct from references (black masks) (PASS); new B13 Frame cost (PASS)

### Score delta per check (7 changed, 25 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 86 | PASS 100 | +14.1 |
| B2 | Draw instances at rest | PASS 100 | PASS 99 | -0.6 |
| R8 | Head height vs body_height | PASS 93 | PASS 94 | +0.8 |
| R4 | Contrast on the other grounds | PASS 100 | PASS 89 | -11.0 |
| R7 | HP bar over the body at 40 m | PASS 100 | PASS 96 | -4.5 |
| P1 | Silhouette hook | INFO 100 | INFO 88 | -12.5 |
| P3 | Tops light, bottoms dark | INFO 59 | INFO 100 | +41.4 |

## Improve next
1. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.62): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
2. **Contrast on the other grounds** (PASS): On ash the body drops to dE 21.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (20 surfaces for 10 meshes = 20 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1714 (body + face above its allowance: face 497 v, allowance 800, total 2211; biggest: Face 497, Merged 462, Merged 322, Merged 312) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 12 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 49 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 263 of 3594 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 97 | 0.0026 ms process per instance (100 animated at 40 m: +0.26 ms process, render CPU +0.55 ms, GPU +0.26 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.034 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 94 | head top 1.77 m / body_height 1.6 (x1.1) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.64 / z 0.47 m (radius 0.45, from shade.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 510 px (30 x 38 bbox; 55 m: 264 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 77.8, 0% of the body melts (within dE 15 of the ground); body L* 30.7 C 23.8 vs ground L* 62.7 C 48.1, hue gap n/a (body C* <= 25); top third (world height) dE 82.5, L* 36.6; per-pixel dE 81.3, outline 60.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 99 | dE 31.0, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 89 | worst ash: dE 21.2 (heath dE 41.9, old_wood dE 43.2, riverbank dE 57.5, snow dE 64.9, ash dE 21.2, sand dE 71.1, marsh dE 31.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 68% of body pixels change between kingdom colours (min pair 67%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 36.1 (fire 58.0, shadow 77.1, ice 53.9, nature 36.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.3 on the team-colour area (normal vision 47.5; 351 px); deutan: fire / nature dE 11.3; protan: fire / nature dE 18.9; worst vs ground: nature colour (deutan) dE 32.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 97 | worst dL +39 (point 1 dL +39; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Face; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 51.4, dL -11 (warm dE 77.9, ice dE 73.8, night dE 51.4, autumn dE 69.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 90 | walk frames vs rest: mean IoU 0.67 (min 0.64), area kept 83-85% (min 422 px), frame-to-frame IoU min 0.72; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 76 | points per frame 1/2/1/1/0/0/1/2 (median 1, range 2, 2 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.62 (tracker 0.62, barrow_ghoul_placeholder 0.6, bleakbow 0.59, magpie 0.57, hexweaver 0.57, nightbolt 0.51) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.12 m from the body centre at t 0.14 s (1.07 m forward; geometry clipped at the ground); declared 1.6 m (UnitType attack_range (shade.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 66% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 23% of the silhouette at its peak (t 0.4 s; 0.12 s 19%, 0.25 s 21%, 0.4 s 23%, 0.6 s 20%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.72 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 89 | 52 shapes over 7 body parts (7.4 per part: LegL 3, LegR 3, Hips 1, Head 24, ArmL 5, ArmR 6, Chest 10); 10% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.894 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 88% of the 2500 verts budget used (2207) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 1.91 at the close-up (94403 px), 2.04 at 25 m; close-up outline complexity 5.19 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 88 | outline complexity 2.44 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 36.6, bottom third L* 17.2 (+19, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.2 at 25 m, 13.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 55.4, 0% melts; body L* 28.4 C 20.4 vs floor L* 51.8 C 43.1 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.23 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 497 v / 1 s; Root/Chest/Merged 462 v / 4 s; Root/Chest/ArmL/Merged 322 v / 3 s; Root/Chest/Head/Merged 312 v / 3 s; Root/Chest/ArmR/Merged 292 v / 4 s; Root/Hips/LegL/Merged 119 v / 1 s; Root/Hips/LegR/Merged 119 v / 1 s; Root/Hips/Merged 49 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
