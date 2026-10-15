# Art Lab scorecard: barrow_knight

Scene `res://art/units/shadow/barrow_knight/barrow_knight.tscn` · kind **unit** / tier **heavy** · kingdom shadow · ground meadow · 2026-10-15 14:15:44 · lab v3.1

## Result: **WARN** · quality **93 / 100** (93.2)

0 FAIL · 2 WARN · 30 PASS · 16 info · 0 skipped · 28 s

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.7 -> 0.83, or pull the widest parts in to x <= 1.22 / z <= 1.22 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Vertices** (WARN): B4 10545 -> 5772 (want <= 6000): `Merged` 3615 -> 1808 verts; `Merged` 3246 -> 1623 verts; `Merged` 592 -> 296 verts; `Merged` 530 -> 265 verts; `Merged` 528 -> 264 verts; `Merged` 460 -> 230 verts; `Merged` 329 -> 165 verts; `Merged` 329 -> 205 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (19.1): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from veilborn_dreadrider (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Frame cost** (PASS): Cut the per-frame script cost (0.0033 ms per instance): write pivots only when they change, skip work at the far tiers _(from B13 Frame cost)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 37 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 15 drawn (15 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, ArmL 1, Chest 1, Hips 1, LegBL 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 89 | 15 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | **WARN** 35 | 10545 (body + face above its allowance: face 806 v, allowance 800, total 11345; biggest: Merged 3615, Merged 3246, Merged 592, Merged 530) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 95 | 5 (Merged, Merged, FlailHead, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 19 (model says 19) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 68 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1342 of 13448 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 93 | 0.0033 ms process per instance (100 animated at 40 m: +0.33 ms process, render CPU +2.35 ms, GPU +2.09 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.008 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.53 / z 1.46 m (radius 0.7, from barrow_knight.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 917 px (36 x 50 bbox; 55 m: 468 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 90.4, 0% of the body melts (within dE 15 of the ground); body L* 38.4 C 38.8 vs ground L* 61.6 C 49.1, hue gap 167 deg; top third (world height) dE 89.7, L* 47.4; per-pixel dE 94.1, outline 69.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 48.1, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 38.2 (heath dE 58.6, old_wood dE 59.9, riverbank dE 71.9, snow dE 65.7, ash dE 38.2, sand dE 77.8, marsh dE 48.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 94 | 20% of body pixels change between kingdom colours (min pair 19%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 67.8 (fire 77.8, shadow 87.6, ice 77.6, nature 67.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 75 | worst pair fire / nature (deutan): dE 7.9 on the team-colour area (normal vision 75.6; 191 px); deutan: fire / nature dE 7.9; protan: fire / nature dE 24.2; worst vs ground: fire colour (deutan) dE 55.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -1 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.8 m, 1.82 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +22 (point 1 dL +22, point 2 dL +27; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 2/1/1): Face; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 70.6, dL +0 (warm dE 90.3, ice dE 81.3, night dE 70.6, autumn dE 83.2); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.7), area kept 95-106% (min 873 px), frame-to-frame IoU min 0.77; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 2/2/2/2/2/1/1/1 (median 2, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.65 (veilborn_dreadrider 0.65, duskbolt_harrier 0.65, gloom_deacon 0.44, stormbottle_genie 0.43, hollow_oathsworn 0.42, ruin_warden 0.4) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.49 m from the body centre at t 0.14 s (1.49 m forward; geometry clipped at the ground); declared 1.9 m (UnitType attack_range (barrow_knight.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 32% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.6 s; 0.12 s 7%, 0.25 s 9%, 0.4 s 11%, 0.6 s 12%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 83 | 307 shapes over 11 body parts (27.9 per part: Head 122, LegFL 6, LegFR 6, LegBL 8, LegBR 8, Tail 11, Mount 82, Hips 17, ArmL 11, ArmR 18, Chest 18); 28% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.88 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 189% of the 6000 verts budget used (11341) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.7 at the close-up (64105 px), 3.28 at 25 m; close-up outline complexity 8.22 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.58 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 47.4, bottom third L* 18.1 (+29, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 19.1 at 25 m, 23.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 67.1, 0% melts; body L* 37.0 C 35.8 vs floor L* 50.2 C 41.9; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.26 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"face_verts":800,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 3615 v / 7 s; Steed/Root/Mount/Head/Merged 3246 v / 12 s; Rider/Root/Chest/Merged 592 v / 6 s; Rider/Root/Chest/Head/Merged 530 v / 4 s; Rider/Root/Hips/Merged 528 v / 6 s; Rider/Root/Chest/ArmL/Merged 460 v / 6 s; Rider/Root/Chest/Head/Face 390 v / 1 s; Steed/Root/Mount/LegBL/Merged 329 v / 4 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R10: raise UnitType.radius 0.7 -> 0.83, or pull the widest parts in to x <= 1.22 / z <= 1.22 m)
