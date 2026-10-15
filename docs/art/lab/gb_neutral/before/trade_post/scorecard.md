# Art Lab scorecard: trade_post

Scene `res://art/buildings/trade_post/trade_post.tscn` · kind **building** / tier **small** · kingdom neutral · ground meadow · 2026-10-15 11:17:05 · lab v3.1

## Result: **WARN** · quality **85 / 100** (85.1)

0 FAIL · 3 WARN · 15 PASS · 18 info · 0 skipped · 21 s

## Improve next
1. **Unique materials** (WARN): B8 22 -> 11 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-23007` -> `StandardMaterial3D#-86309` (dE 0.0), `StandardMaterial3D#-86309` -> `StandardMaterial3D#-18981` (dE 0.0), `StandardMaterial3D#-18981` -> `StandardMaterial3D#-88886` (dE 0.0), `ShaderMaterial#-53267` -> `ShaderMaterial#-7704` (dE 0.0), `ShaderMaterial#-30485` -> `ShaderMaterial#-85018` (dE 0.0), `ShaderMaterial#-21601` -> `ShaderMaterial#-16663` (dE 4.2), `ShaderMaterial#-7704` -> `ShaderMaterial#-39446` (dE 6.3), `ShaderMaterial#-62064` -> `ShaderMaterial#-48306` (dE 8.1), `ShaderMaterial#-98828` -> `ShaderMaterial#-93877` (dE 13.7), `ShaderMaterial#-76046` -> `ShaderMaterial#-48306` (dE 14.4), `ShaderMaterial#-16663` -> `ShaderMaterial#-93877` (dE 14.7); 5 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 19 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #2] _(from B9 Materials built per instance)_
3. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #3] _(from A1 Standard hooks)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.62): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -6 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 13.5): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 19 material(s), 5 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 14 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 89 | 15 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 87 | 5716 (biggest: Structure 3673, Sign0 418, ContactDecal 288, Rubble 280) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO | 1 | no budget for building/small |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 8 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 7 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 35 | 22 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 18 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 282 of 4461 triangles (6%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.15 ms process, render CPU +0.66 ms, GPU +0.79 ms) | <= 0.05 ms per instance (lab default (towers, walls, posts): half a keep) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.08 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 34395 px (264 x 224 bbox; 55 m: 17705 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 45.5, 1% of the body melts (within dE 15 of the ground); body L* 49.1 C 32.4 vs ground L* 58.7 C 49.1, hue gap 62 deg; top third (world height) dE 47.0, L* 35.6; per-pixel dE 53.6, outline 24.4 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 21.4 (heath dE 21.4, old_wood dE 34.1, riverbank dE 35.4, snow dE 45.7, ash dE 37.3, sand dE 32.8, marsh dE 36.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 100 | worst dL +44 (point 1 dL +48, point 2 dL +44; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Flames, Lantern; soft glows under the bloom (v1 count, luma > 0.4): 4 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (greywater_lodge 0.63, tavern_model 0.55) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 235 shapes over 6 body parts (39.2 per part: Body 159, ShutterPivot 6, AwningPivot 11, SignHead 6, SignPivot 43, LanternPivot 10); 77% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.616 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 85% of the 6000 verts budget used (5144) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.53 at the close-up (85825 px), 5.38 at 25 m; close-up outline complexity 5.17 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.6 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 35.6, bottom third L* 42.4 (-6, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 5.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 17 | on the autumn floor: dE 13.5, 20% melts; body L* 46.4 C 38.6 vs floor L* 47.1 C 40.1 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.33 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Structure 3673 v / 11 s; Body/SignHead/SignPivot/Sign0 418 v / 5 s; Body/ContactDecal 288 v / 1 s; Body/Rubble 280 v / 1 s x10; Body/LanternPivot/Lantern 251 v / 2 s; Body/AwningPivot/Awning 206 v / 2 s; Body/AwningFrame 200 v / 4 s; Body/SignHead/Arm 186 v / 2 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 21 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: B8 22 -> 11 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-23007` -> `StandardMaterial3D#-86309` (dE 0.0), `StandardMa)
