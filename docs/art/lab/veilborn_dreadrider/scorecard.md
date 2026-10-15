# Art Lab scorecard: veilborn_dreadrider

Scene `res://art/units/shadow/veilborn_dreadrider/veilborn_dreadrider.tscn` · kind **unit** / tier **cavalry_mounted** · kingdom shadow · ground meadow · 2026-10-15 16:51:29 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.5) (previous run 92, +1)

0 FAIL · 2 WARN · 30 PASS · 16 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-10-15 16:43:59 in `docs/art/lab/veilborn_dreadrider`: quality 92 -> 93, +1)
### What got worse (0)
Nothing got worse.

new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (marsh) (PASS); new R4 Contrast on the other grounds (PASS); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (PASS); new R7 HP bar over the body at 40 m (PASS); new A3r Weapon reach at the strike (INFO); new A3 Attack reads at 40 m (PASS); new P1 Silhouette hook (INFO); new P3 Tops light, bottoms dark (INFO); new P4 Detail density 25 m / 40 m (INFO); new R5c Glow points stand out (1 m surround) (PASS); new P5 Glow placement (INFO); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new R5w Glow points while walking (flicker) (PASS); new A4 Cast pose reads (play_cast) (INFO); new P2 Asymmetric secondary shape (INFO)

### Score delta per check (6 changed, 28 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP  | PASS 100 | +0.0 |
| R3 | Contrast vs ground (meadow) | SKIP  | PASS 100 | +0.0 |
| R6 | Team-colour visibility at 40 m | SKIP  | PASS 99 | +0.0 |
| R5 | Glow points at 40 m | SKIP  | PASS 100 | +0.0 (noisy) |
| R2 | Distinct from references (black masks) | SKIP  | PASS 86 | +0.0 |
| B13 | Frame cost | SKIP  | PASS 100 | +0.0 (noisy) |

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.8 -> 0.99, or pull the widest parts in to x <= 1.4 / z <= 1.4 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Vertices** (WARN): B4 12151 -> 8317 (want <= 8500): `Merged` 3390 -> 1695 verts; `Merged` 3077 -> 1539 verts; `Merged` 1652 -> 1051 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (16.4): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from barrow_knight (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast on the other grounds** (PASS): On ash the body drops to dE 24.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Head 3, ArmL 1, ArmR 1, Chest 1, Hips 1, LegBL 1 | <= 32 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B2 | Draw instances at rest | PASS 100 | 14 | <= 20 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 12 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B4 | Vertices | **WARN** 35 | 12151 (body + face above its allowance: face 844 v, allowance 1200, total 12995; biggest: Merged 3390, Merged 3077, Merged 1652, Merged 1351) | <= 8500 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6 | Particle systems | PASS 100 | 0 | <= 1 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B7 | Shadow casters | PASS 100 | 4 (Merged, Merged, Merged, Merged) | <= 6 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/cavalry_mounted |  |
| B1a | Authored build parts (before the merge) | INFO | 3 (model says 21) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 32 |  |
| B11 | Surfaces per instance | INFO | 64 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2003 of 15976 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0018 ms process per instance (100 animated at 40 m: +0.18 ms process, render CPU +1.91 ms, GPU +1.35 ms) | <= 0.01 ms per instance (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.008 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.47 / z 1.73 m (radius 0.8, from veilborn_dreadrider.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1226 px (47 x 63 bbox; 55 m: 624 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 76.6, 0% of the body melts (within dE 15 of the ground); body L* 36.6 C 24.0 vs ground L* 61.3 C 48.9, hue gap n/a (body C* <= 25); top third (world height) dE 70.2, L* 45.9; per-pixel dE 80.9, outline 58.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 35.2, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 93 | worst ash: dE 24.3 (heath dE 48.2, old_wood dE 45.4, riverbank dE 56.8, snow dE 59.6, ash dE 24.3, sand dE 68.0, marsh dE 35.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 99 | 23% of body pixels change between kingdom colours (min pair 23%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.2 (fire 66.9, shadow 75.5, ice 65.9, nature 57.2) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 11.8 on the team-colour area (normal vision 61.6; 301 px); deutan: fire / nature dE 11.8; protan: fire / nature dE 24.1; worst vs ground: nature colour (deutan) dE 47.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -8 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 2.08 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +4 (point 1 dL +4, point 2 dL +25; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Merged, Face; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 55.4, dL -3 (warm dE 77.1, ice dE 70.3, night dE 55.4, autumn dE 70.2); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.77 (min 0.69), area kept 98-111% (min 1199 px), frame-to-frame IoU min 0.74; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 2/2/2/1/1/1/1/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.67 (barrow_knight 0.67, duskbolt_harrier 0.5, shadow_knight 0.47, gloom_deacon 0.41, ruin_warden 0.41, stormbottle_genie 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.79 m from the body centre at t 0.08 s (1.74 m forward; geometry clipped at the ground); declared 2.1 m (UnitType attack_range (veilborn_dreadrider.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 33% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.6 s; 0.12 s 10%, 0.25 s 11%, 0.4 s 12%, 0.6 s 12%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 86 | 310 shapes over 11 body parts (28.2 per part: Head 119, LegFL 10, LegFR 10, LegBL 12, LegBR 12, Tail 11, Mount 73, Hips 22, ArmL 4, ArmR 12, Chest 25); 24% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.886 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 152% of the 8500 verts budget used (12991) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.15 at the close-up (62752 px), 2.82 at 25 m; close-up outline complexity 12.73 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.98 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 45.9, bottom third L* 22.7 (+23, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 16.4 at 25 m, 20.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 55.2, 0% melts; body L* 34.9 C 22.0 vs floor L* 49.9 C 41.8 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 74 | front-view asymmetry 0.15 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 3390 v / 7 s; Steed/Root/Mount/Head/Merged 3077 v / 11 s; Rider/Root/Chest/Merged 1652 v / 5 s; Rider/Root/Hips/Merged 1351 v / 4 s; Rider/Root/Chest/Head/Merged 533 v / 5 s; Rider/Root/Chest/ArmR/Merged 480 v / 4 s; Steed/Root/Mount/LegBL/Merged 429 v / 5 s; Steed/Root/Mount/LegBR/Merged 429 v / 5 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R10: raise UnitType.radius 0.8 -> 0.99, or pull the widest parts in to x <= 1.4 / z <= 1.4 m)
