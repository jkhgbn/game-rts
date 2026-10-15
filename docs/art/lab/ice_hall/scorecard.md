# Art Lab scorecard: ice_hall

Scene `res://art/buildings/ice_hall.tscn` · kind **building** / tier **hall** · kingdom ice · ground meadow · 2026-10-15 16:25:14 · lab v3.1

## Result: **WARN** · quality **90 / 100** (89.8) (previous run 91, -1)

0 FAIL · 1 WARN · 20 PASS · 18 info · 0 skipped · 42 s

## Before / after (vs the run of 2026-09-30 14:51:05 in `docs/art/lab/ice_hall`: quality 91 -> 90, -1)
### What got worse (3)
1. **C3 Palette depth (close-up): INFO 100 -> INFO 90 (-10)**. Now: 11 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %). Was: 12 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %)
2. **R5c Glow points stand out (1 m surround): PASS 92 -> PASS 86 (-6) (noisy check: re-run before acting)**. Now: worst dL +6 (point 1 dL +25, point 2 dL +6, point 3 dL +15, point 4 dL +29, point 5 dL +20; ring 27 px = 1.0 m at 40 m). Was: worst dL +11 (point 1 dL +36, point 2 dL +11, point 3 dL +40, point 4 dL +25, point 5 dL +37; ring 27 px = 1.0 m at 40 m
3. **P1 Silhouette hook: INFO 31 -> INFO 25 (-5)**. Now: outline complexity 1.63. Was: outline complexity 1.7

### Score delta per check (4 changed, 36 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 100 | INFO 90 | -10.0 |
| R6cb | Team colours for colour-blind players | PASS 79 | PASS 77 | -2.0 |
| P1 | Silhouette hook | INFO 31 | INFO 25 | -5.3 |
| R5c | Glow points stand out (1 m surround) | PASS 92 | PASS 86 | -5.9 (noisy) |

Changed pixels per shot: z40 22.4 %, z55 17.8 %, z25 25.6 %, close 13.7 %, turns 15.2 %, anim 13.6 %, silhouette 0.3 %, lineup 35.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 6 -> 4 (want 2-4): ShaderMaterial#-99987 crack_strength 1.0 -> 0.23 on StoreParts, Roof (dim under the bloom level: 2 point(s), peak 3.2 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.59): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.63): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from market_ice (IoU 0.7): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.3): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 7 material(s), 9 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 15 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 18 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 6124 (biggest: Walls 1777, Roof 1251, PlinthBase 1214, RackParts 631) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 36 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/hall |  |
| B8 | Unique materials | PASS 98 | 6 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 23 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 18 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 944 of 4042 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.03 ms process, render CPU +0.17 ms, GPU +0.14 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.38 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 36288 px (221 x 278 bbox; 55 m: 18253 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 62.4, 0% of the body melts (within dE 15 of the ground); body L* 60.8 C 14.7 vs ground L* 61.2 C 50.7, hue gap n/a (body C* <= 25); top third (world height) dE 57.9, L* 79.9; per-pixel dE 66.1, outline 32.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 34.2, 26% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 34.2 (heath dE 40.9, old_wood dE 47.4, riverbank dE 44.0, snow dE 34.2, ash dE 41.1, sand dE 51.0, marsh dE 51.8) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 36% of body pixels change between kingdom colours (min pair 36%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 41.9 (fire 59.7, shadow 75.8, ice 62.1, nature 41.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 9.7 on the team-colour area (normal vision 80.7; 13564 px); deutan: fire / nature dE 9.7; protan: fire / nature dE 23.7; worst vs ground: fire colour (deutan) dE 35.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 86 | worst dL +6 (point 1 dL +25, point 2 dL +6, point 3 dL +15, point 4 dL +29, point 5 dL +20; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 6 point(s) above the bloom level 1.2 (median of 5/6/8): StoreParts, BannerR x2, HaloShards x2, Roof; soft glows under the bloom (v1 count, luma > 0.4): 22 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): StoreParts, BannerR x2, HaloShards x2, Roof |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.7 (market_ice 0.7, ice_stables 0.64, magpie_den 0.59, ice_keep 0.45, watchtower 0.34, ice_spire 0.16) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 150 shapes over 6 body parts (25.0 per part: Body 114, RidgeCrystal 9, Halo 3, IceStore 8, BrazierShard 1, WeaponRack 15); 85% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.587 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 51% of the 12000 verts budget used (6120) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 11 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.82 at the close-up (74667 px), 5.84 at 25 m; close-up outline complexity 3.07 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 25 | outline complexity 1.63 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 79.9, bottom third L* 48.4 (+31, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 84 | inner detail 2.3 at 25 m, 3.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 50.1, 0% melts; body L* 59.2 C 7.7 vs floor L* 48.4 C 41.2; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.28 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Walls 1777 v / 2 s; Body/Roof 1251 v / 2 s; Body/PlinthBase 1214 v / 1 s; Body/WeaponRack/RackParts 631 v / 1 s; Body/RidgeCrystal/CrystalBase 452 v / 1 s; Body/IceStore/StoreParts 262 v / 2 s; Body/RidgeCrystal/Halo/HaloShards 186 v / 1 s; Body/TurretCapR 110 v / 1 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: Glow points 6 -> 4 (want 2-4): ShaderMaterial#-99987 crack_strength 1.0 -> 0.23 on StoreParts, Roof (dim under the bloom level: 2 point(s), peak 3.2 x the level)
