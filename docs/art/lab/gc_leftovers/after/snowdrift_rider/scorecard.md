# Art Lab scorecard: snowdrift_rider

Scene `res://art/units/ice/snowdrift_rider/snowdrift_rider.tscn` · kind **unit** / tier **cavalry** · kingdom ice · ground meadow · 2026-10-15 15:25:02 · lab v3.1

## Result: **FAIL** · quality **94 / 100** (93.9) (previous run 95, -1)

1 FAIL · 1 WARN · 29 PASS · 15 info · 0 skipped · 27 s

## Before / after (vs the run of 2026-10-15 15:16:18 in `docs/art/lab/gc_leftovers/after/snowdrift_rider`: quality 95 -> 94, -1)
### What got worse (1)
1. **R5 Glow points at 40 m: PASS 100 -> WARN 49 (-51) (noisy check: re-run before acting)**. Now: 0 point(s) above the bloom level 1.2 (median of 0/0/1), 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3. Was: 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged, 1 rim-light speck(s) ignored; soft glows under the bloom

### What got better (2)
R6cb Team colours for colour-blind players: WARN 39 -> PASS 73 (+35); B4 Vertices: WARN 52 -> PASS 85 (+33)

gone R5c Glow points stand out (1 m surround) (was PASS); gone P5 Glow placement (was INFO)

### Score delta per check (6 changed, 43 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | WARN 52 | PASS 85 | +33.3 |
| R6cb | Team colours for colour-blind players | WARN 39 | PASS 73 | +34.7 |
| R5 | Glow points at 40 m | PASS 100 | WARN 49 | -51.4 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 100 | PASS 89 | -11.3 (noisy) |
| P2 | Asymmetric secondary shape | INFO 91 | INFO 90 | -1.6 |
| B13 | Frame cost | PASS 90 | PASS 100 | +10.3 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.1 %, z25 0.3 %, close 3.0 %, strike_side 5.6 %, turns 1.1 %, cast 0.2 %, anim 3.3 %, silhouette 0.1 %, lineup 6.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Particle systems** (FAIL): B6 Particle systems: One system with emission points instead of several; pre-built one-shots [fixes.json #1] _(from B6 Particle systems)_
2. **Glow points at 40 m** (WARN): Glow points 0 -> 1 (want 1-3): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from rime_harrier (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 18% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

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
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmL 1, ArmR 1, Cat 1, Chest 1, Head 1, Hips 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | PASS 87 | 12 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | PASS 85 | 2490 (body + face above its allowance: face 884 v, allowance 1200, total 3374; biggest: Merged 1191, Merged 672, Merged 511, Merged 404) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | **FAIL** 6 | 2 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) | One system with emission points instead of several; pre-built one-shots |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 16 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 43 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 317 of 4527 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.002 ms process per instance (100 animated at 40 m: +0.2 ms process, render CPU +1.35 ms, GPU +1.3 ms) | <= 0.005 ms per instance (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.006 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.73 / z 1.59 m (radius 0.65, from snowdrift_rider.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1075 px (50 x 61 bbox; 55 m: 548 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 68.4, 0% of the body melts (within dE 15 of the ground); body L* 49.8 C 19.7 vs ground L* 62.2 C 48.4, hue gap n/a (body C* <= 25); top third (world height) dE 69.8, L* 53.1; per-pixel dE 71.3, outline 53.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 46.4, 3% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 33.0 (heath dE 43.1, old_wood dE 46.1, riverbank dE 51.1, snow dE 46.4, ash dE 33.0, sand dE 60.3, marsh dE 44.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 92 | 18% of body pixels change between kingdom colours (min pair 17%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.1 (fire 62.1, shadow 68.4, ice 67.4, nature 57.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 73 | worst pair fire / nature (deutan): dE 6.0 on the team-colour area (normal vision 56.9; 197 px); deutan: fire / nature dE 6.0; protan: fire / nature dE 16.8; worst vs ground: fire colour (deutan) dE 51.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 93 | bar hides 6% of the silhouette (gap -13 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.6 m, 1.69 m wide |  |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 0/0/1), 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 3 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 61.2, dL +1 (warm dE 69.0, ice dE 66.9, night dE 61.2, autumn dE 62.9); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 92 | walk frames vs rest: mean IoU 0.7 (min 0.63), area kept 94-102% (min 1039 px), frame-to-frame IoU min 0.72; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 1/1/0/1/0/0/0/0 (median 0, range 1, 0 frame(s) at 0; at rest 0) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.65 (rime_harrier 0.65, snowdrift_rider_placeholder 0.58, rime_harrier_placeholder 0.57, rime_seer 0.39, ruin_warden 0.37, stormbottle_genie 0.36) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.6 m from the body centre at t 0.08 s (1.13 m forward; geometry clipped at the ground); declared 1.8 m (UnitType attack_range (snowdrift_rider.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 29% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 15% of the silhouette at its peak (t 0.4 s; 0.12 s 13%, 0.25 s 15%, 0.4 s 15%, 0.6 s 14%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 131 shapes over 11 body parts (11.9 per part: Head 31, LegFL 2, LegFR 2, LegBL 2, LegBR 2, Tail 4, Mount 19, Hips 14, ArmL 3, ArmR 8, Chest 44); 30% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.919 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 134% of the 2500 verts budget used (3370) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.26 at the close-up (63246 px), 2.64 at 25 m; close-up outline complexity 7.13 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.81 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 53.1, bottom third L* 39.4 (+13, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.2 at 25 m, 13.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 55.0, 0% melts; body L* 45.5 C 14.5 vs floor L* 50.8 C 42.2 (inside the floor band); ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 90 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider, mount separate))
`{"draw":12,"face_verts":1200,"frame_ms":0.005,"lights":0,"meshes":20,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":4,"separate":6,"verts":2500},"src":"cavalry-mounts.md 10 (cavalry rider, mount separate)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Rider/Root/Chest/Merged 1191 v / 9 s; Cat/Root/Mount/Head/Merged 672 v / 4 s; Cat/Root/Mount/Merged 511 v / 6 s; Rider/Root/Hips/Merged 404 v / 5 s; Rider/Root/Chest/ArmR/Merged 212 v / 5 s; Cat/Root/Mount/Tail/Merged 113 v / 2 s; Rider/Root/Chest/ArmL/Merged 71 v / 3 s; Cat/Root/Mount/LegBL/Merged 52 v / 2 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: B6 Particle systems: One system with emission points instead of several; pre-built one-shots)
