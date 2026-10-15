# Art Lab scorecard: grove_stag

Scene `res://art/units/mounts/grove_stag/grove_stag.tscn` · kind **mount** / tier **mount** · kingdom nature · ground meadow · 2026-10-15 13:08:24 · lab v3.1

## Result: **WARN** · quality **92 / 100** (92.2)

0 FAIL · 2 WARN · 25 PASS · 16 info · 0 skipped · 25 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 3 -> 1 (want 0-2): grove_stag_hide crack_strength 1.0 -> 0.21 on Merged, Merged (dim under the bloom level: 2 point(s), peak 3.51 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Vertices** (WARN): B4 6549 -> 5972 (want <= 6000): `Merged` 2791 -> 2214 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 12.6: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 19.5): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 28.3): value is close to the ground (dL +2): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 12% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 20 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, Head 1, LegBL 1, LegBR 1, LegFL 1, LegFR 1 | <= 12 (cavalry-mounts.md 10 (mount)) |  |
| B2 | Draw instances at rest | PASS 88 | 8 | <= 8 (cavalry-mounts.md 10 (mount)) |  |
| B4 | Vertices | **WARN** 47 | 6549 (body + face above its allowance: face 412 v, allowance 600, total 6961; biggest: Merged 2791, Merged 2558, Merged 371, Merged 371) | <= 6000 soft (cavalry-mounts.md 10 (mount)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (mount)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (cavalry-mounts.md 10 (mount)) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 2 soft (cavalry-mounts.md 10 (mount)) |  |
| B8 | Unique materials | INFO | 13 | no budget for mount/mount |  |
| B1a | Authored build parts (before the merge) | INFO | 2 (model says 11) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 12 |  |
| B11 | Surfaces per instance | INFO | 37 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 991 of 8918 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0002 ms process per instance (50 animated at 40 m: +0.01 ms process, render CPU +0.39 ms, GPU +1.15 ms) | <= 0.005 ms per instance (cavalry-mounts.md 10 (mount)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.018 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 1.31 / z 1.52 m (radius 0.7, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1254 px (56 x 55 bbox; 55 m: 643 px) | >= 150 px (FAIL < 60) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 90 | mean-colour dE 28.3, 1% of the body melts (within dE 15 of the ground); body L* 65.3 C 24.6 vs ground L* 62.4 C 48.7, hue gap n/a (body C* <= 25); top third (world height) dE 42.7, L* 80.5; per-pixel dE 40.6, outline 40.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 38.3, 21% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 78 | worst heath: dE 12.6 (heath dE 12.6, old_wood dE 38.3, riverbank dE 37.4, snow dE 33.3, ash dE 48.9, sand dE 17.7, marsh dE 51.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 85 | 12% of body pixels change between kingdom colours (min pair 11%) | >= 6% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 96 | worst nature colour: dE 28.2 (fire 34.2, shadow 39.5, ice 34.0, nature 28.2) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 12.4 on the team-colour area (normal vision 64.5; 154 px); deutan: fire / nature dE 12.4; protan: fire / nature dE 19.8; worst vs ground: fire colour (deutan) dE 14.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +26 (point 1 dL +37, point 2 dL +26, point 3 dL +26; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): Merged x3; soft glows under the bloom (v1 count, luma > 0.4): 3 | 0-2 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Merged x3 |
| R12 | Contrast under every light preset (meadow) | PASS 90 | worst night: dE 22.3, dL +17 (warm dE 28.7, ice dE 27.9, night dE 22.3, autumn dE 24.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.83 (min 0.78), area kept 98-101% (min 1238 px), frame-to-frame IoU min 0.79; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 150 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 3/3/3/3/3/3/3/3 (median 3, range 0, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 91 | max IoU 0.58 (roan_courser 0.58, dusk_steed 0.55, ember_boar 0.5, rimehorn 0.5, grizzlemaw 0.47, roc 0.16) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 8 present | set_team_color, set_moving, play_hit, play_death, signal:death_finished, set_barded, play_charge, seat_transform |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 33% of the silhouette at its peak (t 0.25 s; 0.12 s 31%, 0.25 s 33%, 0.4 s 31%, 0.6 s 10%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 202 shapes over 7 body parts (28.9 per part: Neck 14, Head 96, LegFL 9, LegFR 9, LegBL 10, LegBR 10, Mount 54); 13% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.934 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 115% of the 6000 verts budget used (6957) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 11 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.52 at the close-up (44965 px), 2.02 at 25 m; close-up outline complexity 13.85 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.42 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 80.5, bottom third L* 31.6 (+48, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.8 at 25 m, 13.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 36 | on the autumn floor: dE 19.5, 5% melts; body L* 63.3 C 29.0 vs floor L* 50.8 C 42.2; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.4 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- cast: [cast.jpg](cast.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (mount))
`{"draw":8,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":12,"n":50,"runtime_mats":0,"soft":{"casters":2,"looping":1,"verts":6000},"src":"cavalry-mounts.md 10 (mount)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Head/Merged 2791 v / 9 s; Root/Mount/Merged 2558 v / 8 s; Root/Mount/LegBL/Merged 371 v / 4 s; Root/Mount/LegBR/Merged 371 v / 4 s; Root/Mount/LegFL/Merged 311 v / 4 s; Root/Mount/LegFR/Merged 311 v / 4 s; Root/Mount/Neck/Merged 244 v / 3 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: Glow points 3 -> 1 (want 0-2): grove_stag_hide crack_strength 1.0 -> 0.21 on Merged, Merged (dim under the bloom level: 2 point(s), peak 3.51 x the level))
