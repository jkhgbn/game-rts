# Art Lab scorecard: veilborn_dreadrider

Scene `res://art/units/shadow/veilborn_dreadrider/veilborn_dreadrider.tscn` · kind **unit** / tier **rider** · kingdom shadow · ground meadow · 2026-09-30 10:56:23 · lab v3.1

## Result: **WARN** · quality **93 / 100** (93.2) (previous run 92, +1)

0 FAIL · 2 WARN · 30 PASS · 16 info · 0 skipped · 28 s

## Before / after (vs the run of 2026-09-30 10:55:23 in `docs/art/lab/veilborn_dreadrider`: quality 92 -> 93, +1)
### What got worse (0)
Nothing got worse.

### What got better (2)
P3 Tops light, bottoms dark: INFO 46 -> INFO 95 (+48); P2 Asymmetric secondary shape: INFO 95 -> INFO 99 (+4)

### Score delta per check (4 changed, 46 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| P3 | Tops light, bottoms dark | INFO 46 | INFO 95 | +48.5 |
| R5c | Glow points stand out (1 m surround) | PASS 86 | PASS 84 | -1.6 (noisy) |
| P2 | Asymmetric secondary shape | INFO 95 | INFO 99 | +3.9 |
| B13 | Frame cost | PASS 98 | PASS 100 | +1.7 (noisy) |

Changed pixels per shot: z40 0.3 %, z55 0.2 %, z25 0.4 %, close 0.5 %, strike_side 1.6 %, turns 0.4 %, cast 0.4 %, anim 0.3 %, silhouette 1.8 %, lineup 28.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.8 -> 0.98, or pull the widest parts in to x <= 1.4 / z <= 1.4 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Vertices** (WARN): B4 10104 -> 4849 (want <= 5000): `Merged` 3198 -> 1599 verts; `Merged` 3077 -> 1539 verts; `Merged` 668 -> 334 verts; `Merged` 513 -> 257 verts; `Merged` 502 -> 251 verts; `Merged` 502 -> 251 verts; `Merged` 439 -> 220 verts; `Merged` 439 -> 220 verts; `Merged` 418 -> 209 verts; `Merged` 309 -> 155 verts; `Merged` 307 -> 154 verts; `Merged` 144 -> 72 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.4): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.87): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from barrow_knight (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 35 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Head 3, ArmL 1, ArmR 1, Chest 1, Hips 1, LegBL 1 | <= 36 (art-units.md 8 (rider = mount + rider)) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (art-units.md 8 (rider = mount + rider)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (rider = mount + rider)) |  |
| B4 | Vertices | **WARN** 35 | 10104 (body + face above its allowance: face 844 v, allowance 1200, total 10948; biggest: Merged 3198, Merged 3077, Merged 668, Merged 513) | <= 5000 soft (art-units.md 8 (rider = mount + rider)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (rider = mount + rider)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (rider = mount + rider)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (art-units.md 8 (rider = mount + rider)) |  |
| B7 | Shadow casters | PASS 96 | 4 (Merged, Merged, Merged, Merged) | <= 5 soft (art-units.md 8 (rider = mount + rider)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/rider |  |
| B1a | Authored build parts (before the merge) | INFO | 21 (model says 21) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 64 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1356 of 12792 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0006 ms process per instance (100 animated at 40 m: +0.06 ms process, render CPU +1.21 ms, GPU +0.43 ms) | <= 0.005 ms per instance (art-units.md 8 (rider = mount + rider)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.009 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.47 / z 1.72 m (radius 0.8, from veilborn_dreadrider.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1221 px (47 x 63 bbox; 55 m: 616 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 88.3, 0% of the body melts (within dE 15 of the ground); body L* 30.2 C 34.1 vs ground L* 61.3 C 48.9, hue gap 170 deg; top third (world height) dE 82.3, L* 34.9; per-pixel dE 92.5, outline 67.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 41.2, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 31.6 (heath dE 60.0, old_wood dE 54.8, riverbank dE 67.0, snow dE 69.9, ash dE 31.6, sand dE 79.7, marsh dE 41.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 26% of body pixels change between kingdom colours (min pair 26%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.8 (fire 71.4, shadow 86.4, ice 71.3, nature 57.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 10.4 on the team-colour area (normal vision 83.4; 333 px); deutan: fire / nature dE 10.4; protan: fire / nature dE 25.7; worst vs ground: fire colour (deutan) dE 50.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -8 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 2.08 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +16 (point 1 dL +16; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 1/2/2): Merged, Face; soft glows under the bloom (v1 count, luma > 0.4): 4 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 58.7, dL -4 (warm dE 88.6, ice dE 79.4, night dE 58.7, autumn dE 81.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.77 (min 0.68), area kept 97-112% (min 1182 px), frame-to-frame IoU min 0.72; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.67 (barrow_knight 0.67, duskbolt_harrier_placeholder 0.57, shadow_knight 0.47, ruin_warden 0.4, stormbottle_genie 0.38, hollow_oathsworn 0.34) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.76 m from the body centre at t 0.08 s (1.76 m forward; geometry clipped at the ground); declared 2.1 m (UnitType attack_range (veilborn_dreadrider.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 32% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.4 s; 0.12 s 10%, 0.25 s 11%, 0.4 s 12%, 0.6 s 12%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 79 | 304 shapes over 11 body parts (27.6 per part: Head 119, LegFL 14, LegFR 14, LegBL 15, LegBR 15, Tail 11, Mount 69, Hips 14, ArmL 4, ArmR 9, Chest 20); 36% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.874 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 218% of the 5000 verts budget used (10944) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.74 at the close-up (62593 px), 2.65 at 25 m; close-up outline complexity 12.08 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.93 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 95 | top third L* 34.9, bottom third L* 23.8 (+11, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.4 at 25 m, 19.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 65.9, 0% melts; body L* 29.2 C 30.7 vs floor L* 49.9 C 41.7 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 99 | front-view asymmetry 0.2 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (rider = mount + rider))
`{"draw":16,"face_verts":1200,"frame_ms":0.005,"lights":0,"looping":1,"meshes":36,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":5,"separate":6,"verts":5000},"src":"art-units.md 8 (rider = mount + rider)"}`

## Notes
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 3198 v / 7 s; Steed/Root/Mount/Head/Merged 3077 v / 11 s; Rider/Root/Chest/Merged 668 v / 5 s; Rider/Root/Chest/Head/Merged 513 v / 5 s; Steed/Root/Mount/LegBL/Merged 502 v / 5 s; Steed/Root/Mount/LegBR/Merged 502 v / 5 s; Steed/Root/Mount/LegFL/Merged 439 v / 5 s; Steed/Root/Mount/LegFR/Merged 439 v / 5 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R10: raise UnitType.radius 0.8 -> 0.98, or pull the widest parts in to x <= 1.4 / z <= 1.4 m)
