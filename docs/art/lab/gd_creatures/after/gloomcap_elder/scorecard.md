# Art Lab scorecard: gloomcap_elder

Scene `res://art/units/neutral/gloomcap/gloomcap_elder.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-10-15 13:34:53 · lab v3.1

## Result: **WARN** · quality **96 / 100** (96.2) (previous run 95, +1)

0 FAIL · 1 WARN · 27 PASS · 19 info · 0 skipped · 28 s

## Before / after (vs the run of 2026-10-15 13:29:31 in `docs/art/lab/gd_creatures/after/gloomcap_elder`: quality 95 -> 96, +1)
### What got worse (1)
1. **C4 Inner detail (close-up / 25 m): INFO 99 -> INFO 90 (-9)**. Now: inner edges per outline px: 1.86 at the close-up (63752 px), 1.32 at 25 m; close-up outline complexity 6.69. Was: inner edges per outline px: 1.79 at the close-up (64531 px), 1.42 at 25 m; close-up outline complexity 6.55

### What got better (4)
R7 HP bar over the body at 40 m: WARN 58 -> PASS 91 (+33); C3 Palette depth (close-up): INFO 90 -> INFO 100 (+10); P1 Silhouette hook: INFO 60 -> INFO 70 (+10); P2 Asymmetric secondary shape: INFO 94 -> INFO 100 (+6)

### Score delta per check (5 changed, 42 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 90 | INFO 100 | +10.0 |
| C4 | Inner detail (close-up / 25 m) | INFO 99 | INFO 90 | -8.7 |
| R7 | HP bar over the body at 40 m | WARN 58 | PASS 91 | +33.1 |
| P1 | Silhouette hook | INFO 60 | INFO 70 | +9.7 |
| P2 | Asymmetric secondary shape | INFO 94 | INFO 100 | +6.0 |

Changed pixels per shot: z40 0.5 %, z55 0.5 %, z25 1.0 %, close 4.8 %, strike_side 5.3 %, turns 2.4 %, cast 4.9 %, anim 3.0 %, silhouette 0.4 %, lineup 9.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (WARN): B4 3100 -> 2470 (want <= 2500): `Merged` 1132 -> 566 verts; `Merged` 995 -> 931 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Distinct from references (black masks)** (PASS): Make it read apart from ruin_warden (IoU 0.6): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
3. **Contrast on the other grounds** (PASS): On ash the body drops to dE 25.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Attack reads at 40 m** (PASS): Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 19%) _(from A3 Attack reads at 40 m, shot anim)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 21 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 91 | 9 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 38 | 3100 (body + face above its allowance: face 524 v, allowance 600, total 3624; biggest: Merged 1132, Merged 995, Merged 542, Merged 412) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Spores) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 7 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 11 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 9 (model says 8) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 18 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 929 of 5468 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0008 ms process per instance (100 animated at 40 m: +0.08 ms process, render CPU +0.63 ms, GPU +0.29 ms) | <= 0.005 ms per instance (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.012 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.89 m / body_height 1.9 (x0.99) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 1.04 / z 0.86 m (radius 0.6, from gloomcap_elder.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1194 px (47 x 42 bbox; 55 m: 620 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 63.3, 0% of the body melts (within dE 15 of the ground); body L* 46.2 C 12.7 vs ground L* 62.2 C 48.7, hue gap n/a (body C* <= 25); top third (world height) dE 65.4, L* 48.9; per-pixel dE 67.1, outline 45.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 95 | worst ash: dE 25.9 (heath dE 36.6, old_wood dE 38.1, riverbank dE 45.1, snow dE 46.9, ash dE 25.9, sand dE 56.4, marsh dE 37.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 91 | bar hides 7% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.4 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +31 (point 1 dL +31; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Burst; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 55.2, dL -3 (warm dE 63.6, ice dE 62.7, night dE 55.2, autumn dE 57.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.74), area kept 96-104% (min 1151 px), frame-to-frame IoU min 0.79; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (ruin_warden 0.6, stormbottle_genie 0.51, rimeshield 0.5, tracker 0.45, gloom_thrall 0.32, magpie 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.3 m from the body centre at t 0.14 s (1.09 m forward; geometry clipped at the ground); declared 6.0 m (UnitType attack_range (gloomcap_elder.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 90 | strike pose changes 19% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 34% of the silhouette at its peak (t 0.25 s; 0.12 s 30%, 0.25 s 34%, 0.4 s 34%, 0.6 s 30%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 92 shapes over 7 body parts (13.1 per part: LegL 6, LegR 6, Hips 2, Head 13, ArmL 14, ArmR 14, Chest 37); 5% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.957 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 144% of the 2500 verts budget used (3620) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 90 | inner edges per outline px: 1.86 at the close-up (63752 px), 1.32 at 25 m; close-up outline complexity 6.69 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 70 | outline complexity 2.21 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 48.9, bottom third L* 32.4 (+16, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.6 at 25 m, 7.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 47.9, 0% melts; body L* 42.6 C 8.4 vs floor L* 51.1 C 42.6 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.2 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 1132 v / 4 s; Root/Chest/Merged 995 v / 4 s; Root/Chest/ArmR/Merged 542 v / 2 s; Root/Chest/ArmL/Merged 412 v / 3 s; Root/Hips/LegL/Merged 187 v / 1 s; Root/Hips/LegR/Merged 187 v / 1 s; Root/Hips/Merged 165 v / 2 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B4 3100 -> 2470 (want <= 2500): `Merged` 1132 -> 566 verts; `Merged` 995 -> 931 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces)
