# Art Lab scorecard: ember_crucible

Scene `res://art/buildings/fire/ember_crucible/ember_crucible.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-09-30 14:43:28 · lab v3.1

## Result: **WARN** · quality **70 / 100** (69.9) (previous run 70, +0)

0 FAIL · 5 WARN · 13 PASS · 16 info · 0 skipped · 23 s

## Before / after (vs the run of 2026-09-30 13:06:48 in `docs/art/lab/ember_crucible`: quality 70 -> 70, +0)
### What got worse (0)
Nothing got worse.

Changed pixels per shot: z40 0.0 %, z55 0.0 %, z25 0.0 %, close 0.0 %, turns 0.0 %, anim 0.0 %, silhouette 12.8 %, lineup 39.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Silhouette area at 40 m** (WARN): R1 3774 -> ~5750 px: grow the 40 m read x1.23 (area goes with the square: scale the key masses / body 23 %) [fixes.json #1] _(from R1 Silhouette area at 40 m, shot z40)_
2. **Contrast on the home ground (ash)** (WARN): R4k Contrast on the home ground (ash): On its home ground (ash) the body is only dE 3.9: add a value step for that ground [fixes.json #3] _(from R4k Contrast on the home ground (ash), shot z40)_
3. **Contrast on the other grounds** (WARN): R4 Contrast on the other grounds: On ash the body drops to dE 3.9: add a value accent that separates it there too [fixes.json #4] _(from R4 Contrast on the other grounds, shot z40)_
4. **Glow points at 40 m** (WARN): Glow points 0 -> 2 (want 2-4): ec_painted crack_strength 1.0 -> 3.13 on CrucibleBody (raise over the bloom level: brightest soft glow 0.42 x the level); add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
5. **Standard hooks** (WARN): A1 Standard hooks: Implement set_team_color [fixes.json #5] _(from A1 Standard hooks)_
6. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.44): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 17 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 5 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 5 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 3015 (biggest: Static 1836, CrucibleBody 772, Crust 301, BellowsBoard 86) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/hall |  |
| B8 | Unique materials | PASS 93 | 7 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 10 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 5 surfaces over 5 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 514 of 2356 triangles (21%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.16 ms process, render CPU +0.05 ms, GPU +-0.24 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point 0.0 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | **WARN** 43 | 3774 px (87 x 78 bbox; 55 m: 1972 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 | Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 66.3, 0% of the body melts (within dE 15 of the ground); body L* 21.3 C 9.1 vs ground L* 64.3 C 47.9, hue gap n/a (body C* <= 25); top third (world height) dE 57.2, L* 29.2; per-pixel dE 71.8, outline 60.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | **WARN** 35 | dE 3.9, 38% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | **WARN** 35 | worst ash: dE 3.9 (heath dE 39.0, old_wood dE 25.4, riverbank dE 42.3, snow dE 69.5, ash dE 3.9, sand dE 66.5, marsh dE 8.9) | dE >= 8 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 0 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it) |
| R2 | Distinct from references (black masks) | PASS 94 | max IoU 0.54 (wayshrine 0.54, fire_tower 0.54, essence_well 0.41, market_fire 0.15, fire_stables 0.14, fire_hall 0.11) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 62 | missing: set_team_color | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 91 shapes over 4 body parts (22.8 per part: (root) 71, CruciblePivot 16, BellowsTop 3, BellowsLeather 1); 86% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.439 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 40 | 25% of the 12000 verts budget used (3015) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 10 | 8 colour steps (L*a*b* bins >= 2 % of the body), 4 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.03 at the close-up (102679 px), 6.17 at 25 m; close-up outline complexity 2.07 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 0 | outline complexity 1.25 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 97 | top third L* 29.2, bottom third L* 17.7 (+11, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.2 at 25 m, 9.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 49.5, 0% melts; body L* 20.0 C 12.9 vs floor L* 53.1 C 43.5; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 16 | front-view asymmetry 0.05 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Static 1836 v / 1 s; CruciblePivot/CrucibleBody 772 v / 1 s; CruciblePivot/Crust 301 v / 1 s; BellowsTop/BellowsBoard 86 v / 1 s; BellowsLeather/Leather 20 v / 1 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- fix recipes: colour not computed (no body material with an albedo among 1 drawn materials)
- Fix recipes: 5 in fixes.json (top: R1 3774 -> ~5750 px: grow the 40 m read x1.23 (area goes with the square: scale the key masses / body 23 %))
