# Art Lab scorecard: fire_stables

Scene `res://art/buildings/stables/fire/fire_stables.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-10-15 11:20:51 · lab v3.1

## Result: **FAIL** · quality **89 / 100** (89.4)

1 FAIL · 1 WARN · 20 PASS · 17 info · 0 skipped · 55 s

## Improve next
1. **Unique materials** (FAIL): B8 9 -> 8 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-91469` -> `StandardMaterial3D#-77559` (dE 0.0) [fixes.json #1] _(from B8 Unique materials)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 17 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #2] _(from B9 Materials built per instance)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.68): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 25.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from market_fire (IoU 0.61): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 48 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 17 material(s), 4 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 18 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 20 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 88 | 11168 (biggest: Walls 2464, TowerStack 1873, Yard 1848, Roof 1167) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 10 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 20 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 14 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 14 | 9 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 26 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 23 surfaces over 18 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1340 of 8827 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0016 ms process per instance (8 animated at 40 m: +0.01 ms process, render CPU +0.39 ms, GPU +11.44 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 28257 px (220 x 214 bbox; 55 m: 14327 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 60.4, 1% of the body melts (within dE 15 of the ground); body L* 43.8 C 42.9 vs ground L* 60.1 C 50.0, hue gap 77 deg; top third (world height) dE 34.0, L* 74.6; per-pixel dE 73.2, outline 34.4 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 42.7, 13% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 36.1 (heath dE 36.1, old_wood dE 44.1, riverbank dE 48.9, snow dE 60.6, ash dE 42.7, sand dE 45.5, marsh dE 40.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 45% of body pixels change between kingdom colours (min pair 44%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 23.7 (fire 61.9, shadow 81.4, ice 50.3, nature 23.7) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.3 on the team-colour area (normal vision 97.3; 13033 px); deutan: fire / nature dE 14.3; protan: fire / nature dE 27.3; worst vs ground: fire colour (deutan) dE 18.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 94 | worst dL +23 (point 1 dL +23, point 2 dL +67, point 3 dL +40, point 4 dL +26; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 4/3/3): MountHead, PlinthFence, Walls, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 11 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.61 (market_fire 0.61, magpie_den 0.57, fire_hall 0.49, dragon_roost 0.47, watchtower 0.35, fire_tower 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 374 shapes over 9 body parts (41.6 per part: Body 243, LoftTower 66, BalePivot 6, PlinthFence 2, LeafL 7, LeafR 7, Mount 32, HeadPivot 9, TailPivot 2); 85% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.677 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 91% of the 12000 verts budget used (10948) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.53 at the close-up (77767 px), 5.0 at 25 m; close-up outline complexity 4.62 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.69 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 74.6, bottom third L* 26.6 (+48, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.4 at 25 m, 4.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 54 | on the autumn floor: dE 25.3, 2% melts; body L* 42.2 C 47.4 vs floor L* 47.8 C 40.6; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.32 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Walls 2464 v / 2 s; Body/LoftTower/TowerStack 1873 v / 3 s; Body/Yard 1848 v / 2 s; Body/Roof 1167 v / 2 s; Mount/MountBody 1120 v / 1 s; Body/PlinthFence 808 v / 1 s; Body/PlinthBase 663 v / 1 s; Mount/HeadPivot/MountHead 331 v / 1 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 9 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: B8 9 -> 8 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-91469` -> `StandardMaterial3D#-77559` (dE 0.0))
