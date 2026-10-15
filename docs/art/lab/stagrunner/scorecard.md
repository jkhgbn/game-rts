# Art Lab scorecard: stagrunner

Scene `res://art/units/nature/stagrunner/stagrunner.tscn` · kind **unit** / tier **cavalry_mounted** · kingdom nature · ground meadow · 2026-10-15 16:49:15 · lab v3.1

## Result: **WARN** · quality **90 / 100** (89.9) (previous run 90, +0)

0 FAIL · 4 WARN · 29 PASS · 16 info · 0 skipped · 27 s

## Before / after (vs the run of 2026-10-15 16:43:13 in `docs/art/lab/stagrunner`: quality 90 -> 90, +0)
### What got worse (0)
Nothing got worse.

new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (old_wood) (PASS); new R4 Contrast on the other grounds (PASS); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (WARN); new R7 HP bar over the body at 40 m (PASS); new A3r Weapon reach at the strike (INFO); new A3 Attack reads at 40 m (PASS); new P1 Silhouette hook (INFO); new P3 Tops light, bottoms dark (INFO); new P4 Detail density 25 m / 40 m (INFO); new R5c Glow points stand out (1 m surround) (PASS); new P5 Glow placement (INFO); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new R5w Glow points while walking (flicker) (PASS); new A4 Cast pose reads (play_cast) (INFO); new P2 Asymmetric secondary shape (INFO)

### Score delta per check (6 changed, 29 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP  | PASS 100 | +0.0 |
| R3 | Contrast vs ground (meadow) | SKIP  | PASS 91 | +0.0 |
| R6 | Team-colour visibility at 40 m | SKIP  | PASS 85 | +0.0 |
| R5 | Glow points at 40 m | SKIP  | PASS 100 | +0.0 (noisy) |
| R2 | Distinct from references (black masks) | SKIP  | PASS 79 | +0.0 |
| B13 | Frame cost | SKIP  | PASS 100 | +0.0 (noisy) |

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.6 -> 0.87, or pull the widest parts in to x <= 1.05 / z <= 1.05 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 2.6 m, Merged 0.54 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Vertices** (WARN): B4 10730 -> 8388 (want <= 8500): `Merged` 2791 -> 1396 verts; `Merged` 2558 -> 1611 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.0): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 10.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from glade_outrider (IoU 0.77): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 20 drawn (20 mesh + 0 multimesh); per pivot: Chest 3, Head 3, ArmR 2, ArmL 1, Cloak 1, Hips 1 | <= 32 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B2 | Draw instances at rest | PASS 86 | 20 | <= 20 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B3 | keep_separate parts | PASS 100 | 5 | <= 12 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B4 | Vertices | **WARN** 37 | 10730 (body + face above its allowance: face 812 v, allowance 1200, total 11542; biggest: Merged 2791, Merged 2558, Merged 598, Merged 579) | <= 8500 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6 | Particle systems | PASS 100 | 0 | <= 1 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B7 | Shadow casters | PASS 100 | 4 (Merged, Merged, Merged, Merged) | <= 6 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/cavalry_mounted |  |
| B1a | Authored build parts (before the merge) | INFO | 7 (model says 22) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 32 |  |
| B11 | Surfaces per instance | INFO | 88 surfaces over 20 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1814 of 15027 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0021 ms process per instance (100 animated at 40 m: +0.21 ms process, render CPU +2.17 ms, GPU +1.22 ms) | <= 0.01 ms per instance (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.018 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 2.6 m, Merged 0.54 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.31 / z 1.52 m (radius 0.6, from stagrunner.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1499 px (56 x 64 bbox; 55 m: 762 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 91 | mean-colour dE 29.5, 2% of the body melts (within dE 15 of the ground); body L* 63.2 C 29.3 vs ground L* 61.5 C 49.2, hue gap 33 deg; top third (world height) dE 38.8, L* 76.6; per-pixel dE 43.0, outline 40.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 38.2, 11% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 75 | worst heath: dE 10.3 (heath dE 10.3, old_wood dE 38.2, riverbank dE 39.5, snow dE 38.0, ash dE 49.1, sand dE 17.7, marsh dE 50.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 85 | 12% of body pixels change between kingdom colours (min pair 11%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 97 | worst nature colour: dE 29.6 (fire 36.4, shadow 40.0, ice 34.9, nature 29.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 40 | worst pair fire / nature (deutan): dE 11.0 on the team-colour area (normal vision 62.4; 184 px); deutan: fire / nature dE 11.0; protan: fire / nature dE 18.1; worst vs ground: fire colour (deutan) dE 9.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 91 | bar hides 7% of the silhouette (gap -13 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +23 (point 1 dL +33, point 2 dL +25, point 3 dL +24, soft 1 dL +23 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): Merged x3; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 93 | worst night: dE 24.2, dL +17 (warm dE 29.6, ice dE 26.9, night dE 24.2, autumn dE 26.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 92 | walk frames vs rest: mean IoU 0.7 (min 0.67), area kept 108-116% (min 1632 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 3/4/3/4/3/3/3/3 (median 3, range 1, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 79 | max IoU 0.77 (glade_outrider 0.77, thornback_charger 0.6, hollow_stag 0.53, stormbottle_genie 0.32, mossback 0.3, briar_roc 0.25) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.35 m from the body centre at t 0.14 s (2.34 m forward; geometry clipped at the ground); declared 1.7 m (UnitType attack_range (stagrunner.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 33% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 14% of the silhouette at its peak (t 0.4 s; 0.12 s 10%, 0.25 s 12%, 0.4 s 14%, 0.6 s 11%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 343 shapes over 14 body parts (24.5 per part: Neck 14, Head 128, LegFL 9, LegFR 9, LegBL 10, LegBR 10, Mount 54, LegL 8, LegR 8, Hips 16, ArmL 6, ArmR 7, Chest 52, Cloak 12); 19% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.945 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 135% of the 8500 verts budget used (11538) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.71 at the close-up (50096 px), 2.41 at 25 m; close-up outline complexity 14.31 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.23 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 76.6, bottom third L* 25.9 (+50, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 57 | inner detail 12.7 at 25 m, 17.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 22 | on the autumn floor: dE 15.0, 6% melts; body L* 62.2 C 33.6 vs floor L* 49.8 C 41.7; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.38 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene))
`{"draw":20,"face_verts":1200,"frame_ms":0.01,"lights":0,"meshes":32,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":6,"separate":12,"verts":8500},"src":"cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Stag/Root/Mount/Head/Merged 2791 v / 9 s; Stag/Root/Mount/Merged 2558 v / 8 s; Rider/Root/Chest/Head/Merged 598 v / 7 s; Rider/Root/Chest/Merged 579 v / 6 s; Rider/Root/Chest/Spear 488 v / 8 s; Rider/Root/Hips/LegR/Merged 448 v / 4 s; Rider/Root/Hips/LegL/Merged 448 v / 4 s; Rider/Root/Hips/Merged 441 v / 6 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: R10: raise UnitType.radius 0.6 -> 0.87, or pull the widest parts in to x <= 1.05 / z <= 1.05 m)
