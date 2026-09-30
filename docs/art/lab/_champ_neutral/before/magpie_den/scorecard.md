# Art Lab scorecard: magpie_den

Scene `res://art/buildings/guilds/magpie_den/magpie_den.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-30 11:45:24 · lab v3.1

## Result: **FAIL** · quality **79 / 100** (79.0)

2 FAIL · 2 WARN · 13 PASS · 18 info · 0 skipped · 24 s

## Improve next
1. **Unique materials** (FAIL): B8 19 -> 13 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-78062` -> `StandardMaterial3D#-31136` (dE 0.0), `StandardMaterial3D#-31136` -> `StandardMaterial3D#-94409` (dE 0.0), `StandardMaterial3D#-94409` -> `StandardMaterial3D#-61465` (dE 0.0), `ShaderMaterial#-61643` -> `ShaderMaterial#-45454` (dE 2.3), `ShaderMaterial#-38956` -> `ShaderMaterial#-45454` (dE 4.5), `ShaderMaterial#-67088` -> `ShaderMaterial#-45454` (dE 13.8); 5 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Vertices** (FAIL): B4 13525 -> 11923 (want <= 12000): `Structure` 10616 -> 9014 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Glow points at 40 m** (WARN): Glow points 5 -> 4 (want 2-4): ShaderMaterial#-23927 emission x 0.14 on Cloth (dim under the bloom level: 1 point(s), peak 5.24 x the level; no energy / glow-colour parameter found) [fixes.json #3] _(from R5 Glow points at 40 m, shot glow)_
4. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #4] _(from A1 Standard hooks)_
5. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.68): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
6. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -11 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 19 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 16 material(s), 3 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 12 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | **FAIL** 10 | 13525 (biggest: Structure 10616, Vane 946, Sack 529, Lantern 293) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 1 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 19 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 12 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 31 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1691 of 10928 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.08 ms process, render CPU +0.33 ms, GPU +-0.62 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.17 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 33932 px (213 x 269 bbox; 55 m: 17209 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 59.3, 0% of the body melts (within dE 15 of the ground); body L* 29.7 C 2.3 vs ground L* 60.4 C 50.2, hue gap n/a (body C* <= 25); top third (world height) dE 61.4, L* 25.5; per-pixel dE 63.1, outline 32.3 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 79 | worst ash: dE 9.8 (heath dE 34.2, old_wood dE 21.1, riverbank dE 27.8, snow dE 60.0, ash dE 9.8, sand dE 60.6, marsh dE 19.7) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 99 | worst dL +38 (point 1 dL +68, point 2 dL +62, point 3 dL +61, point 4 dL +64, point 5 dL +38; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) above the bloom level 1.2 (median of 5/6/3): Cloth, LightPool, Sack, Rubble, Lantern; soft glows under the bloom (v1 count, luma > 0.4): 5 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Cloth, LightPool, Sack, Rubble, Lantern |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (tavern_model 0.69, watchtower 0.54) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 387 shapes over 5 body parts (77.4 per part: Body 343, DoorPivot 9, LanternPivot 11, VanePivot 18, SackPivot 6); 95% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.683 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 107% of the 12000 verts budget used (12945) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 8.15 at the close-up (100530 px), 7.72 at 25 m; close-up outline complexity 3.53 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.81 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 25.5, bottom third L* 36.7 (-11, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.8 at 25 m, 6.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 40 | 1 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 43.1, 4% melts; body L* 27.4 C 2.9 vs floor L* 47.8 C 40.7 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 75 | front-view asymmetry 0.16 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Structure 10616 v / 11 s; Body/VanePivot/Vane 946 v / 4 s; Body/SackPivot/Sack 529 v / 3 s; Body/LanternPivot/Lantern 293 v / 2 s; Body/ContactDecal 288 v / 1 s; Body/Rubble 288 v / 1 s x12; Body/DoorPivot/DoorLeaf 269 v / 4 s; Body/Cloth 260 v / 1 s
- 18 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: B8 19 -> 13 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-78062` -> `StandardMaterial3D#-31136` (dE 0.0), `StandardMa)
