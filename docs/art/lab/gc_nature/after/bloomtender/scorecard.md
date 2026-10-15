# Art Lab scorecard: bloomtender

Scene `res://art/units/nature/bloomtender.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-10-15 12:57:09 · lab v3.1

## Result: **WARN** · quality **91 / 100** (91.4) (previous run 91, +0)

0 FAIL · 3 WARN · 31 PASS · 17 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-10-15 12:46:56 in `docs/art/lab/gc_nature/after/bloomtender`: quality 91 -> 91, +0)
### What got worse (1)
1. **P1 Silhouette hook: INFO 94 -> INFO 87 (-7)**. Now: outline complexity 2.43. Was: outline complexity 2.52

### What got better (1)
C3 Palette depth (close-up): INFO 70 -> INFO 80 (+10)

### Score delta per check (9 changed, 49 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 92 | INFO 91 | -1.0 |
| C3 | Palette depth (close-up) | INFO 70 | INFO 80 | +10.0 |
| R4 | Contrast on the other grounds | PASS 82 | PASS 80 | -1.7 |
| R6cb | Team colours for colour-blind players | WARN 36 | WARN 35 | -0.8 |
| R7 | HP bar over the body at 40 m | PASS 91 | PASS 92 | +0.5 |
| P1 | Silhouette hook | INFO 94 | INFO 87 | -6.7 |
| R12 | Contrast under every light preset (meadow) | PASS 92 | PASS 93 | +0.6 |
| R5w | Glow points while walking (flicker) | PASS 89 | PASS 96 | +7.5 (noisy) |
| P2 | Asymmetric secondary shape | INFO 87 | INFO 88 | +1.1 |

Changed pixels per shot: z40 0.4 %, z55 0.3 %, z25 0.5 %, close 4.4 %, strike_side 2.4 %, turns 18.3 %, cast 2.4 %, anim 1.4 %, silhouette 2.1 %, lineup 0.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 1.6 -> 2.28 in res://art/units/nature/bloomtender.tscn (root) and res://data/units/bloomtender.tres (the head top; x1.42 now), or lower the head / crest 0.28 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.45 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 18.4): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Contrast on the other grounds** (PASS): On sand the body drops to dE 13.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 15.7): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 27.8): value is close to the ground (dL +3): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 31 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Censer 1, Chest 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 93 | 2082 (body + face above its allowance: face 408 v, allowance 800, total 2490; biggest: HatMesh 584, Merged 476, Face 408, Pod 352) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 5 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 530 of 3894 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.05 ms process, render CPU +1.05 ms, GPU +1.24 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.035 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 40 | head top 2.28 m / body_height 1.6 (x1.42) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.45 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | PASS 100 | x 0.62 / z 0.61 m (radius 0.45, from bloomtender.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 923 px (31 x 46 bbox; 55 m: 475 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 89 | mean-colour dE 27.8, 7% of the body melts (within dE 15 of the ground); body L* 66.8 C 29.6 vs ground L* 63.0 C 48.1, hue gap 31 deg; top third (world height) dE 41.5, L* 81.9; per-pixel dE 40.7, outline 35.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 41.1, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 80 | worst sand: dE 13.9 (heath dE 17.2, old_wood dE 41.1, riverbank dE 43.3, snow dE 35.6, ash dE 52.0, sand dE 13.9, marsh dE 54.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 39% of body pixels change between kingdom colours (min pair 39%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 95 | worst nature colour: dE 27.7 (fire 46.0, shadow 56.6, ice 39.8, nature 27.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 18.4 on the team-colour area (normal vision 57.9; 371 px); deutan: fire / nature dE 18.4; protan: fire / nature dE 24.3; worst vs ground: fire colour (deutan) dE 5.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -8 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +28 (point 1 dL +31, point 2 dL +28, soft 1 dL +28 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/1): HatMesh, Pod; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 93 | worst autumn: dE 24.5, dL +5 (warm dE 27.2, ice dE 25.1, night dE 24.5, autumn dE 24.5); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.86 (min 0.83), area kept 100-103% (min 928 px), frame-to-frame IoU min 0.86; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 2/2/2/2/2/1/2/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 93 | max IoU 0.55 (bramblesage 0.55, greenheart_oathkeeper 0.51, ruin_warden 0.47, gloomcap_elder 0.46, wildwood_archer 0.3, bramblehorn 0.29) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.36 m from the body centre at t 0.24 s (1.36 m forward; geometry clipped at the ground); declared 7.0 m (UnitType attack_range (bloomtender.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 28% of the silhouette at its peak (t 0.4 s; 0.12 s 24%, 0.25 s 28%, 0.4 s 28%, 0.6 s 28%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 91 | 74 shapes over 7 body parts (10.6 per part: Hips 15, Head 20, Hat 16, ArmL 2, Censer 8, ArmR 6, Chest 7); 12% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.898 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 2500 verts budget used (2486) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 11 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.23 at the close-up (91246 px), 1.6 at 25 m; close-up outline complexity 8.33 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 87 | outline complexity 2.43 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 81.9, bottom third L* 49.0 (+32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.5 at 25 m, 9.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 24 | on the autumn floor: dE 15.7, 12% melts; body L* 64.2 C 33.7 vs floor L* 51.9 C 43.0; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 88 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Hat/HatMesh 584 v / 6 s; Root/Hips/Merged 476 v / 3 s; Root/Chest/Head/Face 408 v / 1 s; Root/Chest/ArmR/Censer/Pod 352 v / 4 s; Root/Chest/ArmR/Merged 236 v / 5 s; Root/Chest/Merged 217 v / 3 s; Root/Chest/Head/Merged 131 v / 2 s; Root/Chest/ArmL/Merged 82 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: R8: body_height 1.6 -> 2.28 in res://art/units/nature/bloomtender.tscn (root) and res://data/units/bloomtender.tres (the head top; x1.42 now), or lower the head)
