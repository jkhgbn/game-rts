# Art Lab scorecard: greywater_lodge

Scene `res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-30 11:45:49 · lab v3.1

## Result: **FAIL** · quality **83 / 100** (82.5)

2 FAIL · 2 WARN · 14 PASS · 18 info · 0 skipped · 18 s

## Improve next
1. **Vertices** (FAIL): B4 24101 -> 12093 (want <= 12000): `Structure` 21865 -> 10933 verts; `HoundMesh` 861 -> 431 verts; `Rubble` 480 -> 240 verts; `Lantern` 324 -> 162 verts; `ContactDecal` 288 -> 144 verts; `DoorLeaf` 201 -> 101 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Unique materials** (FAIL): B8 27 -> 13 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-84578` -> `StandardMaterial3D#-46447` (dE 0.0), `StandardMaterial3D#-21237` -> `StandardMaterial3D#-46447` (dE 0.0), `StandardMaterial3D#-3371` -> `StandardMaterial3D#-46447` (dE 0.0), `StandardMaterial3D#-14765` -> `StandardMaterial3D#-46447` (dE 0.0), `StandardMaterial3D#-46499` -> `StandardMaterial3D#-46447` (dE 0.0), `StandardMaterial3D#-60204` -> `StandardMaterial3D#-46447` (dE 0.0), `ShaderMaterial#-8492` -> `ShaderMaterial#-36624` (dE 3.4), `ShaderMaterial#-96095` -> `ShaderMaterial#-36624` (dE 3.7), `ShaderMaterial#-43755` -> `ShaderMaterial#-63141` (dE 5.8), `ShaderMaterial#-85580` -> `ShaderMaterial#-14990` (dE 6.4), `ShaderMaterial#-66514` -> `ShaderMaterial#-14990` (dE 6.7), `ShaderMaterial#-22994` -> `ShaderMaterial#-94503` (dE 9.1), `ShaderMaterial#-94503` -> `ShaderMaterial#-36624` (dE 9.1), `ShaderMaterial#-31179` -> `ShaderMaterial#-36624` (dE 12.2); 5 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #2] _(from B8 Unique materials)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 23 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #4] _(from A1 Standard hooks)_
5. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.65): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
6. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 23 material(s), 8 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 15 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 17 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | **FAIL** 0 | 24101 (biggest: Structure 21865, HoundMesh 861, Rubble 480, Lantern 324) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 2 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 22 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 27 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 15 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 34 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 3916 of 25922 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.1 ms process, render CPU +0.42 ms, GPU +1.06 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.09 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 24188 px (226 x 200 bbox; 55 m: 12390 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 40.1, 1% of the body melts (within dE 15 of the ground); body L* 58.3 C 11.2 vs ground L* 60.9 C 50.2, hue gap n/a (body C* <= 25); top third (world height) dE 39.1, L* 49.8; per-pixel dE 46.2, outline 31.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 88 | worst heath: dE 14.3 (heath dE 14.3, old_wood dE 31.9, riverbank dE 26.0, snow dE 32.8, ash dE 36.4, sand dE 30.9, marsh dE 42.2) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +29 (point 1 dL +29, point 2 dL +32, point 3 dL +36; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): BrazierFire, Lantern, Rubble; soft glows under the bloom (v1 count, luma > 0.4): 6 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (trade_post 0.64, tavern_model 0.55) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 551 shapes over 6 body parts (91.8 per part: (root) 517, DoorPivot 5, LanternPivot 10, FlagPivot 1, HornFlagPivot 1, Hound 17); 91% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.648 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 194% of the 12000 verts budget used (23325) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.26 at the close-up (97890 px), 4.37 at 25 m; close-up outline complexity 8.49 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.56 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 52 | top third L* 49.8, bottom third L* 46.0 (+3, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.7 at 25 m, 6.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 67 | 1 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 54 | on the autumn floor: dE 25.2, 3% melts; body L* 56.2 C 17.5 vs floor L* 48.6 C 41.2 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.24 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Structure 21865 v / 15 s; Hound/HoundMesh 861 v / 3 s; Rubble 480 v / 1 s x10; LanternPivot/Lantern 324 v / 2 s; ContactDecal 288 v / 1 s; DoorPivot/DoorLeaf 201 v / 3 s; DoorGlow 24 v / 1 s; FlagPivot/Pennant 20 v / 1 s
- 26 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: B4 24101 -> 12093 (want <= 12000): `Structure` 21865 -> 10933 verts; `HoundMesh` 861 -> 431 verts; `Rubble` 480 -> 240 verts; `Lantern` 324 -> 162 verts; `Conta)
