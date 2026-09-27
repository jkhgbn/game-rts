# Art Lab scorecard: rimeling

Scene `res://art/units/ice/rimeling/rimeling.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-09-27 17:52:21 · lab v3.1

## Result: **PASS** · quality **95 / 100** (95.2) (previous run 95, +0)

0 FAIL · 0 WARN · 32 PASS · 18 info · 0 skipped · 36 s

## Before / after (vs the run of 2026-09-27 17:32:35 in `docs/art/lab/rimeling`: quality 95 -> 95, +0)
### What got worse (1)
1. **B4 Vertices: PASS 89 -> PASS 87 (-2)**. Now: 2396 (biggest: Merged 781, Merged 509, Merged 396, Merged 396). Was: 2294 (biggest: Merged 679, Merged 509, Merged 396, Merged 396)

### What got better (2)
C3 Palette depth (close-up): INFO 80 -> INFO 90 (+10); C4 Inner detail (close-up / 25 m): INFO 56 -> INFO 62 (+6)

### Score delta per check (9 changed, 47 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | PASS 89 | PASS 87 | -2.0 |
| C1 | Shape richness (secondary shapes) | INFO 99 | INFO 100 | +1.4 |
| C3 | Palette depth (close-up) | INFO 80 | INFO 90 | +10.0 |
| C4 | Inner detail (close-up / 25 m) | INFO 56 | INFO 62 | +5.8 |
| R4k | Contrast on the home ground (snow) | PASS 87 | PASS 88 | +0.6 |
| R4 | Contrast on the other grounds | PASS 89 | PASS 89 | +0.7 |
| P1 | Silhouette hook | INFO 55 | INFO 53 | -1.0 |
| R5c | Glow points stand out (1 m surround) | PASS 92 | PASS 91 | -1.0 (noisy) |
| B13 | Frame cost | PASS 88 | PASS 100 | +12.1 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.1 %, z25 0.1 %, close 0.9 %, strike_side 3.1 %, turns 0.6 %, cast 0.9 %, anim 1.7 %, silhouette 0.1 %, lineup 3.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (2.62 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.0): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
3. **Contrast on the home ground (snow)** (PASS): On its home ground (snow) the body is only dE 21.3: add a value step for that ground _(from R4k Contrast on the home ground (snow), shot z40)_
4. **Contrast on the other grounds** (PASS): On snow the body drops to dE 21.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from rimeling_placeholder (IoU 0.6): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 22 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 7 drawn (7 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, LegL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 7 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 87 | 2396 (biggest: Merged 781, Merged 509, Merged 396, Merged 396) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 52 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 7 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 419 of 2975 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.001 ms process per instance (100 animated at 40 m: +0.1 ms process, render CPU +1.28 ms, GPU +0.32 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.021 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 89 | head top 1.24 m / body_height 1.05 (x1.18) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.4 / z 0.6 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 295 px (22 x 30 bbox; 55 m: 157 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.0, 0% of the body melts (within dE 15 of the ground); body L* 71.6 C 7.0 vs ground L* 63.4 C 48.3, hue gap n/a (body C* <= 25); top third (world height) dE 54.2, L* 88.0; per-pixel dE 60.0, outline 47.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 88 | dE 21.3, 56% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 89 | worst snow: dE 21.3 (heath dE 28.7, old_wood dE 50.6, riverbank dE 51.4, snow dE 21.3, ash dE 49.5, sand dE 40.5, marsh dE 58.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 40% of body pixels change between kingdom colours (min pair 39%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 98 | worst nature colour: dE 30.4 (fire 47.0, shadow 73.9, ice 53.2, nature 30.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 13.9 on the team-colour area (normal vision 78.2; 120 px); deutan: fire / nature dE 13.9; protan: fire / nature dE 22.1; worst vs ground: fire colour (deutan) dE 23.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 1% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.55 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +28 (point 1 dL +28; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 50.0, dL +10 (warm dE 54.0, ice dE 50.2, night dE 53.5, autumn dE 50.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.77 (min 0.68), area kept 90-95% (min 269 px), frame-to-frame IoU min 0.66; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (rimeling_placeholder 0.6, magpie 0.54, hoarlight_magebow_placeholder 0.53, rime_hauler 0.45, bristleback 0.39, frost_mortar 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.97 m from the body centre at t 0.14 s (0.97 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 44% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 44% of the silhouette at its peak (t 0.4 s; 0.12 s 35%, 0.25 s 36%, 0.4 s 44%, 0.6 s 2%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 44 shapes over 6 body parts (7.3 per part: LegL 4, LegR 4, Head 11, ArmL 5, ArmR 5, Chest 15); 25% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.928 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 95% of the 2500 verts budget used (2392) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 62 | inner edges per outline px: 2.62 at the close-up (69042 px), 1.09 at 25 m; close-up outline complexity 3.1 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 53 | outline complexity 2.0 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 88.0, bottom third L* 48.9 (+39, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.4 at 25 m, 14.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 48.6, 0% melts; body L* 69.4 C 2.5 vs floor L* 52.6 C 43.3; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 781 v / 7 s; Root/Chest/Head/Merged 509 v / 4 s; Root/Chest/ArmL/Merged 396 v / 4 s; Root/Chest/ArmR/Merged 396 v / 4 s; Root/Hips/LegL/Merged 155 v / 3 s; Root/Hips/LegR/Merged 155 v / 3 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
