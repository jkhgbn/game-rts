# Art Lab scorecard: gloam_rider

Scene `res://art/units/shadow/gloam_rider/gloam_rider.tscn` · kind **unit** / tier **cavalry_mounted** · kingdom shadow · ground meadow · 2026-10-15 16:51:03 · lab v3.1

## Result: **WARN** · quality **92 / 100** (91.5) (previous run 90, +2)

0 FAIL · 4 WARN · 29 PASS · 16 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-10-15 16:43:50 in `docs/art/lab/gloam_rider`: quality 90 -> 92, +2)
### What got worse (0)
Nothing got worse.

new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (marsh) (PASS); new R4 Contrast on the other grounds (PASS); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (PASS); new R7 HP bar over the body at 40 m (WARN); new A3r Weapon reach at the strike (INFO); new A3 Attack reads at 40 m (PASS); new P1 Silhouette hook (INFO); new P3 Tops light, bottoms dark (INFO); new P4 Detail density 25 m / 40 m (INFO); new R5c Glow points stand out (1 m surround) (PASS); new P5 Glow placement (INFO); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new R5w Glow points while walking (flicker) (PASS); new A4 Cast pose reads (play_cast) (INFO); new P2 Asymmetric secondary shape (INFO)

### Score delta per check (6 changed, 29 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP  | PASS 100 | +0.0 |
| R3 | Contrast vs ground (meadow) | SKIP  | PASS 100 | +0.0 |
| R6 | Team-colour visibility at 40 m | SKIP  | PASS 100 | +0.0 |
| R5 | Glow points at 40 m | SKIP  | PASS 100 | +0.0 (noisy) |
| R2 | Distinct from references (black masks) | SKIP  | PASS 87 | +0.0 |
| B13 | Frame cost | SKIP  | PASS 100 | +0.0 (noisy) |

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.6 -> 1.22, or pull the widest parts in to x <= 1.05 / z <= 1.05 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.78 m, Lance 1.31 m, Pennon 0.77 m, Merged 0.8 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **HP bar over the body at 40 m** (WARN): R7 HP bar over the body at 40 m: The HP bar hides 10% of the body: lower / narrow what sticks up, or fix body_height [fixes.json #4] _(from R7 HP bar over the body at 40 m, shot z40)_
4. **Vertices** (WARN): B4 10369 -> 8406 (want <= 8500): `Merged` 2421 -> 1211 verts; `Merged` 1975 -> 1222 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (13.0): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from duskbolt_harrier_placeholder (IoU 0.64): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Meshes after the kit merge | PASS 100 | 20 drawn (20 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, Chest 2, ArmL 1, ForearmR 1, Hips 1 | <= 32 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B2 | Draw instances at rest | PASS 86 | 20 | <= 20 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B3 | keep_separate parts | PASS 100 | 5 | <= 12 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B4 | Vertices | **WARN** 40 | 10369 (body + face above its allowance: face 810 v, allowance 1200, total 11179; biggest: Merged 2421, Merged 1975, Merged 1230, Lance 867) | <= 8500 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6 | Particle systems | PASS 100 | 0 | <= 1 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B7 | Shadow casters | PASS 100 | 4 (Merged, Merged, Merged, Merged) | <= 6 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/cavalry_mounted |  |
| B1a | Authored build parts (before the merge) | INFO | 7 (model says 21) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 32 |  |
| B11 | Surfaces per instance | INFO | 76 surfaces over 20 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1672 of 14290 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0027 ms process per instance (100 animated at 40 m: +0.27 ms process, render CPU +1.77 ms, GPU +1.05 ms) | <= 0.01 ms per instance (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.008 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.78 m, Lance 1.31 m, Pennon 0.77 m, Merged 0.8 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.66 / z 2.14 m (radius 0.6, from gloam_rider.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1161 px (59 x 56 bbox; 55 m: 592 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 84.9, 0% of the body melts (within dE 15 of the ground); body L* 31.6 C 30.7 vs ground L* 61.2 C 49.2, hue gap 167 deg; top third (world height) dE 92.3, L* 42.1; per-pixel dE 88.9, outline 67.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 38.0, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 98 | worst ash: dE 28.3 (heath dE 56.1, old_wood dE 51.1, riverbank dE 63.8, snow dE 67.0, ash dE 28.3, sand dE 75.8, marsh dE 38.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 30% of body pixels change between kingdom colours (min pair 29%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 58.0 (fire 70.0, shadow 82.5, ice 69.0, nature 58.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 13.1 on the team-colour area (normal vision 59.1; 370 px); deutan: fire / nature dE 13.1; protan: fire / nature dE 22.0; worst vs ground: fire colour (deutan) dE 48.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | **WARN** 54 | bar hides 10% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.56 m wide | Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +15 (point 1 dL +15; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/0/2): Pennon, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 59.1, dL -6 (warm dE 84.2, ice dE 76.8, night dE 59.1, autumn dE 76.2); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 87 | walk frames vs rest: mean IoU 0.61 (min 0.57), area kept 101-112% (min 1190 px), frame-to-frame IoU min 0.75; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 2/0/0/0/0/0/0/1 (median 0, range 2, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (duskbolt_harrier_placeholder 0.64, barrow_knight_placeholder 0.6, hollow_stag 0.48, veilborn_dreadrider_placeholder 0.45, stormbottle_genie 0.37, barrow_giant 0.21) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 3.58 m from the body centre at t 0.14 s (3.57 m forward; geometry clipped at the ground); declared 1.8 m (UnitType attack_range (gloam_rider.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 42% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 19% of the silhouette at its peak (t 0.4 s; 0.12 s 17%, 0.25 s 18%, 0.4 s 19%, 0.6 s 14%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 98 | 290 shapes over 15 body parts (19.3 per part: Head 92, LegFL 6, LegFR 6, LegBL 8, LegBR 8, Tail 11, Mount 49, LegL 7, LegR 7, Hips 13, ArmL 6, ArmR 6, ForearmR 22, Lance 26, Chest 23); 18% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.915 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 131% of the 8500 verts budget used (11175) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.95 at the close-up (34273 px), 2.17 at 25 m; close-up outline complexity 13.34 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.41 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 42.1, bottom third L* 18.6 (+23, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 50 | inner detail 13.0 at 25 m, 16.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 59.7, 0% melts; body L* 31.4 C 27.0 vs floor L* 49.5 C 41.6 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.24 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 2421 v / 6 s; Steed/Root/Mount/Head/Merged 1975 v / 9 s; Rider/Root/Chest/Merged 1230 v / 6 s; Rider/Root/Chest/ArmR/ForearmR/Lance 867 v / 5 s; Rider/Root/Chest/Head/Merged 673 v / 6 s; Rider/Root/Hips/Merged 599 v / 5 s; Rider/Root/Chest/Head/Face 394 v / 1 s; Rider/Root/Hips/LegR/Merged 357 v / 3 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: R10: raise UnitType.radius 0.6 -> 1.22, or pull the widest parts in to x <= 1.05 / z <= 1.05 m)
