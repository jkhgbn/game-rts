# Art Lab scorecard: greenheart_oathkeeper

Scene `res://art/units/nature/greenheart_oathkeeper/greenheart_oathkeeper.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-30 11:05:26 · lab v3.1

## Result: **FAIL** · quality **90 / 100** (89.7) (previous run 93, -3)

1 FAIL · 2 WARN · 30 PASS · 17 info · 0 skipped · 24 s

## Before / after (vs the run of 2026-09-27 18:01:38 in `docs/art/lab/greenheart_oathkeeper`: quality 93 -> 90, -3)
### What got worse (9)
1. **B4 Vertices: PASS 100 -> FAIL 12 (-88)**. Now: 2703 (body + face above its allowance: face 524 v, allowance 800, total 3227; biggest: Merged 871, Face 524, Merged 410, Merged 294). Was: 3253 (biggest: Merged 1080, Merged 429, Merged 381, Merged 329)
2. **R6cb Team colours for colour-blind players: PASS 79 -> WARN 35 (-44)**. Now: worst pair fire / nature (deutan): dE 10.9 on the team-colour area (normal vision 61.0; 242 px); deutan: fire / nature dE 10.9; protan: fire / nature dE 16.9; worst vs ground: fire. Was: worst pair fire / nature (deutan): dE 11.5 on the team-colour area (normal vision 80.1; 241 px); deutan: fire / nature d
3. **R10 Footprint vs selection radius: INFO -> WARN 52 (+0)**. Now: x 0.91 / z 0.98 m (radius 0.55, from greenheart_oathkeeper.tres). Was: x 0.91 / z 0.98 m (radius 0.45, default)
4. **P3 Tops light, bottoms dark: INFO 100 -> INFO 54 (-46)**. Now: top third L* 69.6, bottom third L* 65.4 (+4, world height). Was: top third L* 63.2, bottom third L* 51.0 (+12, world height)
5. **C3 Palette depth (close-up): INFO 100 -> INFO 78 (-23)**. Now: 12 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %). Was: 16 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %)
6. **C1 Shape richness (secondary shapes): INFO 75 -> INFO 61 (-13)**. Now: 103 shapes over 7 body parts (14.7 per part: LegL 5, LegR 5, Hips 11, Head 29, ArmL 8, ArmR 12, Chest 33); 45% of the surface on plain boxes / prisms (<= 10 face directions); norma. Was: 85 shapes over 7 body parts (12.1 per part: LegL 5, LegR 5, Hips 12, Head 9, ArmL 8, ArmR 12, Chest 34); 36% of the surf
7. **R3 Contrast vs ground (meadow): PASS 89 -> PASS 83 (-6)**. Now: mean-colour dE 20.8, 5% of the body melts (within dE 15 of the ground); body L* 66.0 C 36.4 vs ground L* 62.8 C 47.9, hue gap 23 deg; top third (world height) dE 26.7, L* 69.6; per. Was: mean-colour dE 27.6, 5% of the body melts (within dE 15 of the ground); body L* 54.6 C 24.6 vs ground L* 62.8 C 47.9, hu
8. **R3t Contrast in every team colour (meadow): PASS 95 -> PASS 87 (-8)**. Now: worst nature colour: dE 20.7 (fire 38.6, shadow 46.5, ice 33.6, nature 20.7). Was: worst nature colour: dE 27.6 (fire 48.4, shadow 62.1, ice 42.9, nature 27.6)
9. **R2 Distinct from references (black masks): PASS 100 -> PASS 94 (-6)**. Now: max IoU 0.54 (bloomtender 0.54, gloomcap_elder 0.49, ruin_warden 0.43, bramble_harrier 0.41, bramble_harrier_placeholder 0.39, bramblehorn 0.25). Was: max IoU 0.45 (thornling 0.45, vinelasher 0.42, glade_outrider 0.33, bramblehorn 0.25)

### What got better (4)
R4 Contrast on the other grounds: WARN 36 -> PASS 82 (+47); C2 Vertex use vs budget: INFO 69 -> INFO 100 (+31); R4k Contrast on the home ground (old_wood): PASS 95 -> PASS 100 (+5); R12 Contrast under every light preset (meadow): PASS 81 -> PASS 85 (+5)

new P5 Glow placement (INFO)

### Score delta per check (19 changed, 36 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B2 | Draw instances at rest | PASS 100 | PASS 99 | -0.6 |
| B4 | Vertices | PASS 100 | FAIL 12 | -87.6 |
| B7 | Shadow casters | PASS 100 | PASS 98 | -1.8 |
| C1 | Shape richness (secondary shapes) | INFO 75 | INFO 61 | -13.4 |
| C2 | Vertex use vs budget | INFO 69 | INFO 100 | +31.0 |
| R10 | Footprint vs selection radius | INFO  | WARN 52 | +0.0 |
| C3 | Palette depth (close-up) | INFO 100 | INFO 78 | -22.5 |
| R3 | Contrast vs ground (meadow) | PASS 89 | PASS 83 | -6.1 |
| R4k | Contrast on the home ground (old_wood) | PASS 95 | PASS 100 | +5.0 |
| R4 | Contrast on the other grounds | WARN 36 | PASS 82 | +46.7 |
| R3t | Contrast in every team colour (meadow) | PASS 95 | PASS 87 | -7.9 |
| R6cb | Team colours for colour-blind players | PASS 79 | WARN 35 | -44.4 |
| P3 | Tops light, bottoms dark | INFO 100 | INFO 54 | -46.0 |
| R5c | Glow points stand out (1 m surround) | PASS 95 | PASS 90 | -4.8 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 81 | PASS 85 | +4.5 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 25 | INFO 24 | -1.0 |
| R5w | Glow points while walking (flicker) | PASS 84 | PASS 100 | +16.5 (noisy) |
| R2 | Distinct from references (black masks) | PASS 100 | PASS 94 | -5.8 |
| B13 | Frame cost | PASS 90 | PASS 100 | +10.2 (noisy) |

Changed pixels per shot: z40 1.5 %, z55 1.1 %, z25 1.7 %, close 5.8 %, strike_side 28.2 %, turns 4.2 %, cast 4.2 %, anim 3.1 %, silhouette 15.2 %, lineup 49.0 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (FAIL): B4 2703 -> 2489 (want <= 2500): `Merged` 871 -> 657 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.55 -> 0.56, or pull the widest parts in to x <= 0.96 / z <= 0.96 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 10.9): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 45% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.85): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 20.8): value is close to the ground (dL +3): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 23 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +4 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 12 | 2703 (body + face above its allowance: face 524 v, allowance 800, total 3227; biggest: Merged 871, Face 524, Merged 410, Merged 294) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 5 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 32 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 643 of 4570 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0008 ms process per instance (100 animated at 40 m: +0.08 ms process, render CPU +0.91 ms, GPU +0.33 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.021 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 89 | head top 2.36 m / body_height 2.0 (x1.18) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.91 / z 0.98 m (radius 0.55, from greenheart_oathkeeper.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 774 px (39 x 45 bbox; 55 m: 398 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 83 | mean-colour dE 20.8, 5% of the body melts (within dE 15 of the ground); body L* 66.0 C 36.4 vs ground L* 62.8 C 47.9, hue gap 23 deg; top third (world height) dE 26.7, L* 69.6; per-pixel dE 34.6, outline 34.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 42.1, 2% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 82 | worst sand: dE 15.8 (heath dE 22.2, old_wood dE 42.1, riverbank dE 42.1, snow dE 41.8, ash dE 56.2, sand dE 15.8, marsh dE 57.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 31% of body pixels change between kingdom colours (min pair 30%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 87 | worst nature colour: dE 20.7 (fire 38.6, shadow 46.5, ice 33.6, nature 20.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (deutan): dE 10.9 on the team-colour area (normal vision 61.0; 242 px); deutan: fire / nature dE 10.9; protan: fire / nature dE 16.9; worst vs ground: fire colour (deutan) dE 2.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.43 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +23 (point 1 dL +29, soft 1 dL +23 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): HeartKnot; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 85 | worst autumn: dE 18.1, dL +5 (warm dE 20.7, ice dE 19.6, night dE 25.5, autumn dE 18.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.82 (min 0.69), area kept 95-107% (min 748 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 94 | max IoU 0.54 (bloomtender 0.54, gloomcap_elder 0.49, ruin_warden 0.43, bramble_harrier 0.41, bramble_harrier_placeholder 0.39, bramblehorn 0.25) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.61 m from the body centre at t 0.14 s (1.54 m forward; geometry clipped at the ground); declared 1.7 m (UnitType attack_range (greenheart_oathkeeper.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 49% of the silhouette at its peak (t 0.6 s; 0.12 s 46%, 0.25 s 47%, 0.4 s 48%, 0.6 s 49%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 61 | 103 shapes over 7 body parts (14.7 per part: LegL 5, LegR 5, Hips 11, Head 29, ArmL 8, ArmR 12, Chest 33); 45% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.854 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 128% of the 2500 verts budget used (3223) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 78 | 12 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.8 at the close-up (74765 px), 1.94 at 25 m; close-up outline complexity 5.9 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.33 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 54 | top third L* 69.6, bottom third L* 65.4 (+4, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.4 at 25 m, 13.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 24 | on the autumn floor: dE 15.6, 10% melts; body L* 64.2 C 39.8 vs floor L* 51.9 C 42.9; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.4 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Merged 871 v / 6 s; Root/Chest/Head/Face 524 v / 1 s; Root/Chest/ArmR/Merged 410 v / 5 s; Root/Hips/Merged 294 v / 5 s; Root/Chest/ArmL/Merged 285 v / 4 s; Root/Chest/Head/Merged 251 v / 5 s; Root/Hips/LegL/Merged 211 v / 2 s; Root/Hips/LegR/Merged 211 v / 2 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: B4 2703 -> 2489 (want <= 2500): `Merged` 871 -> 657 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
