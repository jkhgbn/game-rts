# Art Lab scorecard: gloom_thrall

Scene `res://art/units/shadow/gloom_thrall.tscn` · kind **unit** / tier **worker** · kingdom shadow · ground meadow · 2026-10-15 13:00:28 · lab v3.1

## Result: **WARN** · quality **96 / 100** (95.9) (previous run 93, +3)

0 FAIL · 1 WARN · 31 PASS · 17 info · 0 skipped · 35 s

## Before / after (vs the run of 2026-10-15 12:46:28 in `docs/art/lab/gc_shadow/after/gloom_thrall`: quality 93 -> 96, +3)
### What got worse (1)
1. **P1 Silhouette hook: INFO 34 -> INFO 31 (-2)**. Now: outline complexity 1.71. Was: outline complexity 1.74

### What got better (2)
H1 Errors from the asset while running: FAIL 0 -> PASS 100 (+100); C3 Palette depth (close-up): INFO 90 -> INFO 100 (+10)

gone H2 Errors from other files during the run (was INFO)

### Score delta per check (6 changed, 46 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 90 | INFO 100 | +10.0 |
| P1 | Silhouette hook | INFO 34 | INFO 31 | -2.3 |
| R5c | Glow points stand out (1 m surround) | PASS 87 | PASS 90 | +2.9 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 75 | PASS 84 | +8.3 (noisy) |
| B13 | Frame cost | PASS 96 | PASS 100 | +3.9 (noisy) |
| H1 | Errors from the asset while running | FAIL 0 | PASS 100 | +100.0 |

Changed pixels per shot: z40 0.0 %, z55 0.0 %, z25 0.1 %, close 1.1 %, strike_side 2.3 %, turns 1.6 %, cast 0.9 %, anim 1.2 %, silhouette 5.1 %, lineup 9.8 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.4 -> 0.44, or pull the widest parts in to x <= 0.7 / z <= 0.7 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.71): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (20 surfaces for 10 meshes = 20 draw calls) _(from B11)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 28 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Head 2, Lantern 2, (root) 1, ArmL 1, ArmR 1, Chest 1 | <= 22 (art-units.md 8) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8) |  |
| B4 | Vertices | PASS 100 | 1557 (body + face above its allowance: face 431 v, allowance 800, total 1988; biggest: Face 431, Merged 323, Merged 319, Merged 278) | <= 2500 (art-units.md 8) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/worker |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 0 soft (art-units.md 8) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8) |  |
| B8 | Unique materials | INFO | 14 | no budget for unit/worker |  |
| B1a | Authored build parts (before the merge) | INFO | 41 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 22 |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 279 of 3446 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-5.75 ms process, render CPU +0.63 ms, GPU +0.68 ms) | <= 0.005 ms per instance (art-units.md 8) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.034 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.37 m / body_height 1.4 (x0.98) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.77 / z 0.56 m (radius 0.4, from gloom_thrall.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 476 px (31 x 35 bbox; 55 m: 243 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 87.7, 0% of the body melts (within dE 15 of the ground); body L* 49.7 C 40.9 vs ground L* 63.4 C 48.1, hue gap 153 deg; top third (world height) dE 67.9, L* 70.8; per-pixel dE 89.8, outline 70.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 54.1, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 44.7 (heath dE 46.5, old_wood dE 63.9, riverbank dE 75.5, snow dE 58.4, ash dE 44.7, sand dE 72.0, marsh dE 54.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 53% of body pixels change between kingdom colours (min pair 52%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 98 | worst nature colour: dE 29.9 (fire 56.8, shadow 85.2, ice 56.6, nature 29.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 11.7 on the team-colour area (normal vision 71.8; 262 px); deutan: fire / nature dE 11.7; protan: fire / nature dE 21.0; worst vs ground: fire colour (deutan) dE 21.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -6 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +25 (point 1 dL +25; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): LanternOrb; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 76.5, dL +0 (warm dE 88.6, ice dE 84.7, night dE 76.5, autumn dE 79.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.77 (min 0.73), area kept 92-99% (min 435 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 84 | points per frame 1/1/1/1/0/0/1/1 (median 1, range 1, 2 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 93 | max IoU 0.56 (tracker 0.56, hollow_oathsworn 0.46, hollow_oathsworn_placeholder 0.45, bleakbow 0.43, nightblood_reaver 0.42, gloomcap_elder 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.62 m from the body centre at t 0.14 s (1.61 m forward; geometry clipped at the ground); declared 1.4 m (UnitType attack_range (gloom_thrall.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 61% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 32% of the silhouette at its peak (t 0.4 s; 0.12 s 31%, 0.25 s 31%, 0.4 s 32%, 0.6 s 31%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 94 | 48 shapes over 7 body parts (6.9 per part: LegL 3, LegR 3, Head 20, ArmL 3, Lantern 7, ArmR 7, Chest 5); 6% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.909 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 79% of the 2500 verts budget used (1984) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.78 at the close-up (61970 px), 1.95 at 25 m; close-up outline complexity 5.07 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 31 | outline complexity 1.71 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 70.8, bottom third L* 46.3 (+24, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.2 at 25 m, 12.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 63.9, 0% melts; body L* 47.3 C 38.2 vs floor L* 52.7 C 43.5; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.3 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":22,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":0,"separate":6},"src":"art-units.md 8","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 431 v / 1 s; Root/Chest/Merged 323 v / 4 s; Root/Chest/Head/Merged 319 v / 3 s; Root/Chest/ArmR/Merged 278 v / 5 s; Root/Chest/ArmL/Merged 211 v / 2 s; Root/Hips/LegL/Merged 119 v / 1 s; Root/Hips/LegR/Merged 119 v / 1 s; Root/Chest/ArmR/Lantern/MeshInstance3D 107 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 over the budget on the first window (0.0052 ms): re-measured 0.0 ms, kept the lower
- Fix recipes: 1 in fixes.json (top: R10: raise UnitType.radius 0.4 -> 0.44, or pull the widest parts in to x <= 0.7 / z <= 0.7 m)
