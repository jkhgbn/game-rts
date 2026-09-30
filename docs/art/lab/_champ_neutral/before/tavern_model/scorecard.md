# Art Lab scorecard: tavern_model

Scene `res://art/buildings/tavern/tavern_model.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-30 11:46:08 · lab v3.1

## Result: **FAIL** · quality **83 / 100** (82.8)

1 FAIL · 2 WARN · 14 PASS · 19 info · 0 skipped · 32 s

## Improve next
1. **Unique materials** (FAIL): B8 16 -> 11 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-22347` -> `StandardMaterial3D#-22051` (dE 0.0), `StandardMaterial3D#-22051` -> `StandardMaterial3D#-85324` (dE 0.0), `StandardMaterial3D#-85324` -> `StandardMaterial3D#-3105` (dE 0.0), `ShaderMaterial#-3372` -> `ShaderMaterial#-89383` (dE 7.6), `ShaderMaterial#-31504` -> `ShaderMaterial#-80460` (dE 13.4); 3 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 5 -> 2 (want 2-4): ShaderMaterial#-89383 emission x 0.18 on Rubble (dim under the bloom level: 3 point(s), peak 4.2 x the level; no energy / glow-colour parameter found) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #3] _(from A1 Standard hooks)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.63): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.46): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 10.6): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 17 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 13 material(s), 4 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 11 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 99 | 8642 (biggest: Structure 6260, SignBoard 1000, Rubble 432, Lantern 359) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 1 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 10 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 16 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 11 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 956 of 7474 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0015 ms process per instance (8 animated at 40 m: +0.01 ms process, render CPU +0.69 ms, GPU +-3.43 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.09 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 37967 px (227 x 259 bbox; 55 m: 19286 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 38.5, 0% of the body melts (within dE 15 of the ground); body L* 59.7 C 37.0 vs ground L* 60.6 C 50.6, hue gap 49 deg; top third (world height) dE 38.4, L* 67.3; per-pixel dE 46.3, outline 28.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 21.0 (heath dE 21.0, old_wood dE 41.4, riverbank dE 38.6, snow dE 45.4, ash dE 50.4, sand dE 22.2, marsh dE 50.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 96 | worst dL +18 (point 1 dL +55, point 2 dL +57, point 3 dL +36, point 4 dL +18, point 5 dL +62; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) above the bloom level 1.2 (median of 5/5/5): Rubble x3, Lantern, DoorLeaf; soft glows under the bloom (v1 count, luma > 0.4): 6 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Rubble x3, Lantern, DoorLeaf |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.69 (magpie_den 0.69, greywater_lodge 0.55) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 243 shapes over 4 body parts (60.8 per part: Body 203, DoorPivot 7, SignPivot 21, LanternPivot 12); 89% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.629 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 65% of the 12000 verts budget used (7914) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 8.48 at the close-up (108429 px), 7.41 at 25 m; close-up outline complexity 2.06 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 12 | outline complexity 1.46 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 67.3, bottom third L* 38.4 (+28, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.3 at 25 m, 4.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 40 | 1 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 8 | on the autumn floor: dE 10.6, 11% melts; body L* 56.3 C 42.3 vs floor L* 47.8 C 40.8 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 87 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Structure 6260 v / 9 s; Body/SignPivot/SignBoard 1000 v / 5 s; Body/Rubble 432 v / 1 s x9; Body/LanternPivot/Lantern 359 v / 2 s; Body/ContactDecal 288 v / 1 s; Body/DoorPivot/DoorLeaf 263 v / 3 s; Body/DoorGlow 24 v / 1 s; Body/LanternPivot/Halo 4 v / 1 s
- 15 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: B8 16 -> 11 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-22347` -> `StandardMaterial3D#-22051` (dE 0.0), `StandardMa)
