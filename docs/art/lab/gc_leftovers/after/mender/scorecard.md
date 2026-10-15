# Art Lab scorecard: mender

Scene `res://art/units/champions/mender/mender.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-10-15 15:22:40 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.6)

0 FAIL · 2 WARN · 28 PASS · 18 info · 0 skipped · 27 s

## Improve next
1. **Vertices** (WARN): B4 7715 -> 3861 (want <= 3000): `Merged` 2949 -> 1475 verts; `Merged` 747 -> 374 verts; `Merged` 707 -> 354 verts; `StaffMesh` 544 -> 272 verts; `Kettle` 510 -> 255 verts; `Core` 432 -> 216 verts; `Jars` 344 -> 172 verts; `Merged` 336 -> 168 verts; `Merged` 336 -> 168 verts; `Variant` 270 -> 135 verts; `Merged` 268 -> 134 verts; `Merged` 268 -> 134 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.76 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Contrast on the other grounds** (PASS): On sand the body drops to dE 15.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 18.7): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +7 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.61): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 29 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Head 3, Censer 2, Chest 2, (root) 1, ArmL 1, ArmR 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 89 | 15 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 88 | 6 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 7715 (body + face above its allowance: face 656 v, allowance 900, total 8371; biggest: Merged 2949, Merged 747, Merged 707, Face 656) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (Steam) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | PASS 89 | 5 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B1a | Authored build parts (before the merge) | INFO | 26 (model says 25) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 15 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1599 of 12014 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0008 ms process per instance (100 animated at 40 m: +0.08 ms process, render CPU +0.6 ms, GPU +1.92 ms) | <= 0.005 ms per instance (champions.md 4 / 13, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 92 | head top 1.93 m / body_height 1.7 (x1.13) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.76 m | narrower than 0.6 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.9 / z 0.73 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 948 px (38 x 55 bbox; 55 m: 488 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 96 | mean-colour dE 36.0, 0% of the body melts (within dE 15 of the ground); body L* 68.1 C 25.6 vs ground L* 62.0 C 48.4, hue gap 45 deg; top third (world height) dE 41.8, L* 70.4; per-pixel dE 49.4, outline 46.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 82 | worst sand: dE 15.5 (heath dE 17.7, old_wood dE 43.5, riverbank dE 47.2, snow dE 31.3, ash dE 50.3, sand dE 15.5, marsh dE 53.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -19 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +31 (point 1 dL +31, point 2 dL +36; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 2/1/1): Variant; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 98 | worst night: dE 28.0, dL +12 (warm dE 36.6, ice dE 35.2, night dE 28.0, autumn dE 32.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 94 | walk frames vs rest: mean IoU 0.74 (min 0.65), area kept 95-102% (min 925 px), frame-to-frame IoU min 0.66; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 2/2/2/2/2/1/1/1 (median 2, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.61 (tracker 0.61, rime_seer 0.53, gloomcap_elder 0.52, ruin_warden 0.42, stormbottle_genie 0.36, bramblehorn 0.28) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.28 m from the body centre at t 0.24 s (2.26 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 45% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 31% of the silhouette at its peak (t 0.4 s; 0.12 s 29%, 0.25 s 31%, 0.4 s 31%, 0.6 s 26%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 143 shapes over 9 body parts (15.9 per part: LegL 5, LegR 5, Hips 8, Head 36, ArmL 6, Staff 12, Censer 20, ArmR 6, Chest 45); 7% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.95 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 278% of the 3000 verts budget used (8367) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.87 at the close-up (88082 px), 1.95 at 25 m; close-up outline complexity 8.51 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.88 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 71 | top third L* 70.4, bottom third L* 63.2 (+7, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.8 at 25 m, 13.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 33 | on the autumn floor: dE 18.7, 0% melts; body L* 65.8 C 32.2 vs floor L* 50.8 C 42.4 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.39 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"face_verts":900,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 2949 v / 2 s; Root/Chest/Head/Merged 747 v / 1 s; Root/Hips/Merged 707 v / 1 s; Root/Chest/Head/Face 656 v / 1 s; Root/Chest/ArmR/Staff/StaffMesh 544 v / 1 s; Root/Chest/ArmR/Staff/Censer/Kettle 510 v / 1 s; Root/Chest/ArmR/Staff/Censer/Core 432 v / 1 s; Root/Chest/Jars 344 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: B4 7715 -> 3861 (want <= 3000): `Merged` 2949 -> 1475 verts; `Merged` 747 -> 374 verts; `Merged` 707 -> 354 verts; `StaffMesh` 544 -> 272 verts; `Kettle` 510 ->)
