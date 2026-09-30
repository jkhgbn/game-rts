# Art Lab scorecard: rime_seer

Scene `res://art/units/ice/rime_seer.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-09-30 11:01:55 · lab v3.1

## Result: **WARN** · quality **93 / 100** (93.3) (previous run 89, +4)

0 FAIL · 1 WARN · 33 PASS · 17 info · 0 skipped · 27 s

## Before / after (vs the run of 2026-09-30 09:36:03 in `docs/art/lab/rime_seer`: quality 89 -> 93, +4)
### What got worse (0)
Nothing got worse.

### What got better (6)
R4k Contrast on the home ground (snow): WARN 50 -> PASS 96 (+46); C4 Inner detail (close-up / 25 m): INFO 50 -> INFO 80 (+30); C3 Palette depth (close-up): INFO 35 -> INFO 65 (+30); R4 Contrast on the other grounds: PASS 84 -> PASS 98 (+14); P3 Tops light, bottoms dark: INFO 40 -> INFO 69 (+28); P2 Asymmetric secondary shape: INFO 90 -> INFO 100 (+10)

### Score delta per check (9 changed, 45 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 35 | INFO 65 | +30.0 |
| C4 | Inner detail (close-up / 25 m) | INFO 50 | INFO 80 | +30.1 |
| R4k | Contrast on the home ground (snow) | WARN 50 | PASS 96 | +46.4 |
| R4 | Contrast on the other grounds | PASS 84 | PASS 98 | +14.2 |
| P3 | Tops light, bottoms dark | INFO 40 | INFO 69 | +28.3 |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 91 | +1.1 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 85 | PASS 89 | +3.8 (noisy) |
| P2 | Asymmetric secondary shape | INFO 90 | INFO 100 | +10.1 |
| B13 | Frame cost | PASS 97 | PASS 100 | +3.0 (noisy) |

Changed pixels per shot: z40 1.1 %, z55 0.7 %, z25 1.2 %, close 7.4 %, strike_side 2.0 %, turns 4.3 %, cast 3.5 %, anim 2.3 %, silhouette 5.8 %, lineup 14.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.42 m so the HP bar reads over the head [fixes.json #1] _(from R8w Parts above body_height + 0.4)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.76): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Palette depth (close-up)** (INFO): Flat palette (12 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +6 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Lantern 4, Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 96 | 11 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1582 (body + face above its allowance: face 594 v, allowance 800, total 2176; biggest: Face 594, Merged 564, Merged 431, Merged 141) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 33 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 23 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 278 of 3252 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0002 ms process per instance (100 animated at 40 m: +0.02 ms process, render CPU +0.57 ms, GPU +0.49 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.016 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 92 | head top 1.82 m / body_height 1.6 (x1.14) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.42 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | PASS 100 | x 0.51 / z 0.63 m (radius 0.45, from rime_seer.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 688 px (28 x 43 bbox; 55 m: 349 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 59.9, 0% of the body melts (within dE 15 of the ground); body L* 71.9 C 18.8 vs ground L* 63.4 C 48.1, hue gap n/a (body C* <= 25); top third (world height) dE 58.6, L* 74.2; per-pixel dE 61.4, outline 46.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 96 | dE 28.5, 6% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 98 | worst snow: dE 28.5 (heath dE 40.5, old_wood dE 55.6, riverbank dE 52.5, snow dE 28.5, ash dE 53.6, sand dE 50.2, marsh dE 63.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 36% of body pixels change between kingdom colours (min pair 36%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 39.6 (fire 49.7, shadow 74.0, ice 59.4, nature 39.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 11.8 on the team-colour area (normal vision 88.2; 255 px); deutan: fire / nature dE 11.8; protan: fire / nature dE 24.7; worst vs ground: fire colour (deutan) dE 36.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -6 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +28 (point 1 dL +28; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Face, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst ice: dE 55.8, dL +11 (warm dE 59.6, ice dE 55.8, night dE 68.7, autumn dE 55.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.87 (min 0.81), area kept 94-104% (min 657 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 2/2/1/1/1/1/1/2 (median 1, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 98 | max IoU 0.48 (rimeshield 0.48, snowdrift_rider_placeholder 0.43, rime_harrier 0.42, rime_harrier_placeholder 0.39, ruin_warden 0.35, gloomcap_elder 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.72 m from the body centre at t 0.36 s (0.59 m forward; geometry clipped at the ground); declared 8.0 m (UnitType attack_range (rime_seer.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 29% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 34% of the silhouette at its peak (t 0.12 s; 0.12 s 34%, 0.25 s 34%, 0.4 s 34%, 0.6 s 30%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 60 | 55 shapes over 6 body parts (9.2 per part: Hips 3, Head 37, ArmL 2, Lantern 4, ArmR 6, Chest 3); 40% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.764 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 86% of the 2500 verts budget used (2172) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 65 | 12 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 80 | inner edges per outline px: 2.45 at the close-up (81393 px), 1.24 at 25 m; close-up outline complexity 5.58 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 79 | outline complexity 2.33 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 69 | top third L* 74.2, bottom third L* 67.6 (+6, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.8 at 25 m, 5.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 58.4, 0% melts; body L* 68.2 C 14.6 vs floor L* 52.5 C 43.4; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.24 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 594 v / 1 s; Root/Chest/Head/Merged 564 v / 6 s; Root/Chest/ArmR/Merged 431 v / 4 s; Root/Chest/Merged 141 v / 3 s; Root/Hips/Merged 138 v / 2 s; Root/Chest/ArmL/Merged 124 v / 2 s; Root/Chest/ArmR/Lantern/Core 77 v / 1 s; Root/Chest/ArmR/Lantern/@MeshInstance3D@192 37 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R8w Parts above body_height + 0.4: Narrow Merged 0.42 m so the HP bar reads over the head)
