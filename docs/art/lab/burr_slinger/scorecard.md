# Art Lab scorecard: burr_slinger

Scene `res://art/units/nature/burr_slinger.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-10-15 17:11:31 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.5) (previous run 92, +1)

0 FAIL · 1 WARN · 32 PASS · 17 info · 0 skipped · 29 s

## Before / after (vs the run of 2026-09-30 11:06:41 in `docs/art/lab/burr_slinger`: quality 92 -> 93, +1)
### What got worse (2)
1. **P4 Detail density 25 m / 40 m: INFO 100 -> INFO 0 (-100) (noisy check: re-run before acting)**. Now: inner detail 15.0 at 25 m, 19.8 at 40 m (mean /grad L*/ per px). Was: inner detail 10.6 at 25 m, 13.5 at 40 m (mean /grad L*/ per px)
2. **B4 Vertices: PASS 94 -> PASS 91 (-3)**. Now: 2202 (body + face above its allowance: face 458 v, allowance 800, total 2660; biggest: Merged 549, Face 458, Merged 420, Merged 279). Was: 2030 (body + face above its allowance: face 458 v, allowance 800, total 2488; biggest: Merged 486, Face 458, Merged 420,

### What got better (6)
R6cb Team colours for colour-blind players: WARN 35 -> PASS 76 (+41); C1 Shape richness (secondary shapes): INFO 89 -> INFO 100 (+11); R2 Distinct from references (black masks): PASS 79 -> PASS 90 (+10); R3 Contrast vs ground (meadow): PASS 85 -> PASS 89 (+5); R3t Contrast in every team colour (meadow): PASS 89 -> PASS 95 (+6); P1 Silhouette hook: INFO 40 -> INFO 50 (+11)

### Score delta per check (11 changed, 42 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | PASS 94 | PASS 91 | -3.4 |
| C1 | Shape richness (secondary shapes) | INFO 89 | INFO 100 | +10.9 |
| R8 | Head height vs body_height | PASS 97 | PASS 99 | +1.9 |
| R3 | Contrast vs ground (meadow) | PASS 85 | PASS 89 | +4.6 |
| R3t | Contrast in every team colour (meadow) | PASS 89 | PASS 95 | +6.0 |
| R6cb | Team colours for colour-blind players | WARN 35 | PASS 76 | +40.9 |
| P1 | Silhouette hook | INFO 40 | INFO 50 | +10.9 |
| P4 | Detail density 25 m / 40 m | INFO 100 | INFO 0 | -100.0 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 87 | PASS 87 | -0.8 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 1 | INFO 0 | -0.8 |
| R2 | Distinct from references (black masks) | PASS 79 | PASS 90 | +10.4 |

Changed pixels per shot: z40 1.3 %, z55 0.8 %, z25 1.4 %, close 8.4 %, strike_side 6.5 %, turns 13.5 %, cast 5.6 %, anim 4.7 %, silhouette 9.3 %, lineup 28.1 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.4 -> 0.6, or pull the widest parts in to x <= 0.7 / z <= 0.7 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.0): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 8.0): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
4. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.96): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 27.6): value is close to the ground (dL -7): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 31 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 20.7: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 4, Head 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 93 | 12 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 91 | 2202 (body + face above its allowance: face 458 v, allowance 800, total 2660; biggest: Merged 549, Face 458, Merged 420, Merged 279) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 14 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 38 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 507 of 3821 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0008 ms process per instance (100 animated at 40 m: +0.08 ms process, render CPU +0.63 ms, GPU +0.13 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.016 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 99 | head top 1.53 m / body_height 1.5 (x1.02) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.05 / z 0.97 m (radius 0.4, from burr_slinger.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 576 px (31 x 43 bbox; 55 m: 300 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 89 | mean-colour dE 27.6, 3% of the body melts (within dE 15 of the ground); body L* 57.0 C 32.6 vs ground L* 64.0 C 48.4, hue gap 31 deg; top third (world height) dE 29.0, L* 60.3; per-pixel dE 39.9, outline 35.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 33.3, 3% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 88 | worst heath: dE 20.7 (heath dE 20.7, old_wood dE 33.3, riverbank dE 39.3, snow dE 44.9, ash dE 46.4, sand dE 23.5, marsh dE 46.7) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 25% of body pixels change between kingdom colours (min pair 25%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 95 | worst nature colour: dE 27.7 (fire 37.6, shadow 41.3, ice 34.9, nature 27.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 76 | worst pair fire / nature (deutan): dE 8.3 on the team-colour area (normal vision 39.3; 159 px); deutan: fire / nature dE 8.3; protan: fire / nature dE 13.1; worst vs ground: nature colour (deutan) dE 11.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.0 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +19 (point 1 dL +25, point 2 dL +25, soft 1 dL +19 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Merged, Seeds; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 87 | worst night: dE 19.3, dL +9 (warm dE 27.8, ice dE 25.7, night dE 19.3, autumn dE 24.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 91 | walk frames vs rest: mean IoU 0.68 (min 0.66), area kept 99-100% (min 570 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (thistle_darter_placeholder 0.6, magpie 0.56, thornling 0.52, bristleback 0.45, vinelasher 0.41, thistle_darter 0.28) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.42 m from the body centre at t 0.08 s (1.09 m forward; geometry clipped at the ground); declared 8.5 m (UnitType attack_range (burr_slinger.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 44% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 44% of the silhouette at its peak (t 0.25 s; 0.12 s 40%, 0.25 s 44%, 0.4 s 43%, 0.6 s 28%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 82 shapes over 7 body parts (11.7 per part: LegL 3, LegR 3, Hips 3, Head 27, ArmL 2, ArmR 23, Chest 21); 24% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.95 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 106% of the 2500 verts budget used (2656) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.99 at the close-up (49693 px), 2.93 at 25 m; close-up outline complexity 3.52 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 50 | outline complexity 1.96 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 60.3, bottom third L* 46.6 (+13, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.0 at 25 m, 19.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 0 | on the autumn floor: dE 8.0, 6% melts; body L* 55.1 C 35.9 vs floor L* 53.1 C 43.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.52 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Merged 549 v / 4 s; Root/Chest/Head/Face 458 v / 1 s; Root/Chest/ArmR/Merged 420 v / 5 s; Root/Chest/Head/Merged 279 v / 3 s; Root/Chest/ArmR/Burr 203 v / 1 s; Root/Hips/LegL/Merged 182 v / 2 s; Root/Hips/LegR/Merged 182 v / 2 s; Root/Hips/Merged 110 v / 3 s
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R10: raise UnitType.radius 0.4 -> 0.6, or pull the widest parts in to x <= 0.7 / z <= 0.7 m)
