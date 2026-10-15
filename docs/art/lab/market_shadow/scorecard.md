# Art Lab scorecard: market_shadow

Scene `res://art/buildings/market/shadow/market_shadow.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-10-15 11:23:33 · lab v3.1

## Result: **FAIL** · quality **91 / 100** (90.9) (previous run 91, +0)

1 FAIL · 0 WARN · 20 PASS · 18 info · 0 skipped · 47 s

## Before / after (vs the run of 2026-10-15 11:07:23 in `docs/art/lab/market_shadow`: quality 91 -> 91, +0)
### What got worse (1)
1. **C3 Palette depth (close-up): INFO 90 -> INFO 80 (-10)**. Now: 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %). Was: 11 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %)

### Score delta per check (4 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 90 | INFO 80 | -10.0 |
| R6 | Team-colour visibility at 40 m | PASS 97 | PASS 97 | +0.5 |
| R6cb | Team colours for colour-blind players | PASS 81 | PASS 79 | -1.7 |
| R5c | Glow points stand out (1 m surround) | PASS 95 | PASS 97 | +1.8 (noisy) |

Changed pixels per shot: z40 7.8 %, z55 7.2 %, z25 8.7 %, close 1.5 %, turns 1.9 %, anim 1.3 %, silhouette 0.0 %, lineup 4.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Unique materials** (FAIL): B8 9 -> 8 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-35197` -> `StandardMaterial3D#-58559` (dE 0.0) [fixes.json #1] _(from B8 Unique materials)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.53): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from dread_paddock (IoU 0.62): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 46 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 10 material(s), 9 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 17 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 19 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 95 | 9615 (biggest: StallFrame 2854, NightStall 2137, MastStack 1241, PanLMesh 624) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 17 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 14 | 9 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 23 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 22 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1755 of 9194 triangles (19%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0085 ms process per instance (8 animated at 40 m: +0.07 ms process, render CPU +0.23 ms, GPU +0.23 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 27333 px (213 x 208 bbox; 55 m: 14002 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 84.7, 0% of the body melts (within dE 15 of the ground); body L* 24.9 C 26.2 vs ground L* 61.4 C 50.4, hue gap 172 deg; top third (world height) dE 61.5, L* 50.4; per-pixel dE 89.3, outline 51.9 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 32.6, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 23.1 (heath dE 57.4, old_wood dE 47.0, riverbank dE 56.9, snow dE 70.4, ash dE 23.1, sand dE 77.6, marsh dE 32.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 97 | 22% of body pixels change between kingdom colours (min pair 21%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 63.3 (fire 73.6, shadow 84.2, ice 73.1, nature 63.3) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.5 on the team-colour area (normal vision 75.6; 6811 px); deutan: fire / nature dE 11.5; protan: fire / nature dE 23.6; worst vs ground: fire colour (deutan) dE 55.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 97 | worst dL +23 (point 1 dL +47, point 2 dL +42, point 3 dL +23, point 4 dL +53; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/4/3): MastStack, MouthPool, CoinMesh, LanternMesh; soft glows under the bloom (v1 count, luma > 0.4): 5 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.62 (dread_paddock 0.62, shadow_stables 0.61, magpie_den 0.57, shadow_hall 0.5, watchtower 0.34, shadow_tower 0.17) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 223 shapes over 9 body parts (24.8 per part: Body 135, Awning 15, LanternPivot 10, Mast 35, CoinPivot 4, ScaleBeam 8, PanL 8, PanR 6, (root) 2); 82% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.529 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 78% of the 12000 verts budget used (9395) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.65 at the close-up (64682 px), 7.18 at 25 m; close-up outline complexity 9.99 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.68 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 50.4, bottom third L* 18.4 (+31, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.3 at 25 m, 6.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 50 | 1 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 61.7, 0% melts; body L* 19.7 C 21.1 vs floor L* 48.8 C 41.3; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- Per-mesh vertices (biggest first): Body/StallFrame 2854 v / 2 s; Body/NightStall 2137 v / 2 s; Body/Mast/MastStack 1241 v / 2 s; Body/Mast/ScalePivot/ScaleBeam/PanL/PanLMesh 624 v / 1 s; Body/PlinthBase 576 v / 1 s; Body/Mast/ScalePivot/ScaleBeam/PanR/PanRMesh 547 v / 1 s; Body/Awning/AwningWhole 448 v / 1 s; Body/Mast/ScalePivot/ScaleBeam/BeamMesh 390 v / 1 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 9 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B8 9 -> 8 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-35197` -> `StandardMaterial3D#-58559` (dE 0.0))
