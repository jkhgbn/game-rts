# Art Lab scorecard: wildwood_archer

Scene `res://art/units/nature/wildwood_archer/wildwood_archer.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-27 12:10:01 · lab v3.1

## Result: **PASS** · quality **94 / 100** (93.5) (previous run 93, +1)

0 FAIL · 0 WARN · 33 PASS · 16 info · 0 skipped · 33 s

## Before / after (vs the run of 2026-09-27 12:05:50 in `docs/art/lab/new-units/wildwood_archer`: quality 93 -> 94, +1)
### What got worse (2)
1. **R4k Contrast on the home ground (old_wood): PASS 96 -> PASS 89 (-7)**. Now: dE 22.4, 0% melts (old_wood is where nature units stand most). Was: dE 28.8, 0% melts (old_wood is where nature units stand most)
2. **R4 Contrast on the other grounds: PASS 82 -> PASS 77 (-5)**. Now: worst heath: dE 11.7 (heath dE 11.7, old_wood dE 22.4, riverbank dE 30.3, snow dE 46.7, ash dE 36.0, sand dE 32.4, marsh dE 36.8). Was: worst heath: dE 15.5 (heath dE 15.5, old_wood dE 28.8, riverbank dE 33.6, snow dE 43.5, ash dE 42.7, sand dE 26.0, marsh

### What got better (5)
P4 Detail density 25 m / 40 m: INFO 10 -> INFO 42 (+32) (noisy check: re-run before acting); R3 Contrast vs ground (meadow): PASS 87 -> PASS 91 (+4); R3t Contrast in every team colour (meadow): PASS 93 -> PASS 98 (+5); R12 Contrast under every light preset (meadow): PASS 77 -> PASS 83 (+7); S1 Style bible: golden autumn (style-autumn.md 3): INFO 14 -> INFO 25 (+11)

### Score delta per check (10 changed, 42 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C4 | Inner detail (close-up / 25 m) | INFO 81 | INFO 82 | +0.9 |
| R3 | Contrast vs ground (meadow) | PASS 87 | PASS 91 | +4.2 |
| R4k | Contrast on the home ground (old_wood) | PASS 96 | PASS 89 | -7.4 |
| R4 | Contrast on the other grounds | PASS 82 | PASS 77 | -4.8 |
| R3t | Contrast in every team colour (meadow) | PASS 93 | PASS 98 | +5.3 |
| P4 | Detail density 25 m / 40 m | INFO 10 | INFO 42 | +32.0 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 77 | PASS 83 | +6.7 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 14 | INFO 25 | +10.8 |
| R11 | Reads while walking (40 m) | PASS 90 | PASS 91 | +0.7 (noisy) |
| B13 | Frame cost | PASS 97 | PASS 100 | +2.6 (noisy) |

Changed pixels per shot: z40 0.4 %, z55 0.2 %, z25 0.4 %, close 2.4 %, strike_side 1.2 %, turns 2.2 %, anim 1.0 %, silhouette 0.0 %, lineup 5.8 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 52% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.9): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (13.3): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.7: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 17.4): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 30.3): the body sits in the ground's hue (gap 24 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Contrast on the home ground (old_wood)** (PASS): On its home ground (old_wood) the body is only dE 22.4: add a value step for that ground _(from R4k Contrast on the home ground (old_wood), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Bow 2, (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 86 | 2455 (biggest: Merged 531, Merged 406, BowBody 389, Merged 281) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, BowBody, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 37 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 435 of 3252 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0006 ms process per instance (100 animated at 40 m: +0.06 ms process, render CPU +2.15 ms, GPU +-1.36 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.025 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 92 | head top 1.81 m / body_height 1.6 (x1.13) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.42 / z 0.35 m (radius 0.45, from wildwood_archer.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 309 px (19 x 34 bbox; 55 m: 163 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 91 | mean-colour dE 30.3, 3% of the body melts (within dE 15 of the ground); body L* 49.1 C 25.4 vs ground L* 62.9 C 48.1, hue gap 24 deg; top third (world height) dE 26.0, L* 66.9; per-pixel dE 46.7, outline 41.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 89 | dE 22.4, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 77 | worst heath: dE 11.7 (heath dE 11.7, old_wood dE 22.4, riverbank dE 30.3, snow dE 46.7, ash dE 36.0, sand dE 32.4, marsh dE 36.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 30%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 98 | worst nature colour: dE 30.2 (fire 49.0, shadow 57.5, ice 44.9, nature 30.2) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.4 on the team-colour area (normal vision 62.3; 110 px); deutan: fire / nature dE 11.4; protan: fire / nature dE 24.2; worst vs ground: nature colour (deutan) dE 20.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 97 | worst dL +39 (point 1 dL +39; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): BowString; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 83 | worst night: dE 16.6, dL -1 (warm dE 31.0, ice dE 28.1, night dE 16.6, autumn dE 28.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 91 | walk frames vs rest: mean IoU 0.68 (min 0.59), area kept 99-103% (min 306 px), frame-to-frame IoU min 0.58; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 92 | max IoU 0.57 (vinelasher 0.57, thornling 0.49, burr_slinger 0.41) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.78 m from the body centre at t 0.14 s (0.35 m forward; geometry clipped at the ground); declared 9.0 m (UnitType attack_range (wildwood_archer.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 44% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 71 | 69 shapes over 8 body parts (8.6 per part: LegL 4, LegR 4, Hips 9, Head 10, Bow 17, ArmL 3, ArmR 2, Chest 20); 52% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.896 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 98% of the 2500 verts budget used (2451) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 82 | inner edges per outline px: 2.11 at the close-up (61329 px), 1.26 at 25 m; close-up outline complexity 15.14 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.22 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 66.9, bottom third L* 24.2 (+42, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 42 | inner detail 13.3 at 25 m, 17.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 25 | on the autumn floor: dE 17.4, 2% melts; body L* 46.1 C 27.1 vs floor L* 51.8 C 43.0 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.41 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- strike_side: [strike_side.jpg](strike_side.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 531 v / 6 s; Root/Chest/Head/Merged 406 v / 5 s; Root/Chest/ArmL/Bow/BowBody 389 v / 3 s; Root/Chest/ArmL/Merged 281 v / 3 s; Root/Hips/Merged 262 v / 1 s; Root/Chest/ArmR/Merged 239 v / 2 s; Root/Hips/LegL/Merged 164 v / 2 s; Root/Hips/LegR/Merged 164 v / 2 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
