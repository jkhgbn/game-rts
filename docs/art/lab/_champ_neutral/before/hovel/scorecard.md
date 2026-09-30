# Art Lab scorecard: hovel

Scene `res://art/buildings/hovel.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-30 11:46:40 · lab v3.1

## Result: **FAIL** · quality **82 / 100** (81.7)

1 FAIL · 1 WARN · 16 PASS · 18 info · 0 skipped · 29 s

## Improve next
1. **Unique materials** (FAIL): B8 13 -> 10 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-76534` -> `StandardMaterial3D#-83678` (dE 0.0), `StandardMaterial3D#-13261` -> `StandardMaterial3D#-83678` (dE 0.0), `ShaderMaterial#-80749` -> `ShaderMaterial#-11372` (dE 12.5); 2 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 17 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #2] _(from B9 Materials built per instance)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.59): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Vertex use vs budget** (INFO): Only 9% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.75): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.8): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 17 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 7 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 1351 (biggest: Walls 598, Roof 395, Rubble 168, LanternOrb 104) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 7 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 24 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 13 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 14 surfaces over 7 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 172 of 1088 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.19 ms process, render CPU +0.49 ms, GPU +6.01 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.29 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 13084 px (123 x 163 bbox; 55 m: 6736 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 96.7, 0% of the body melts (within dE 15 of the ground); body L* 38.7 C 44.3 vs ground L* 62.2 C 50.4, hue gap 164 deg; top third (world height) dE 111.0, L* 49.4; per-pixel dE 101.5, outline 60.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 43.4 (heath dE 68.8, old_wood dE 65.9, riverbank dE 75.6, snow dE 68.9, ash dE 43.4, sand dE 81.2, marsh dE 52.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +16 (point 1 dL +16; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 1/2/2): LanternOrb, Plinth; soft glows under the bloom (v1 count, luma > 0.4): 2 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.36 (greywater_lodge 0.36, trade_post 0.28) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 39 shapes over 1 body parts (39.0 per part: Body 39); 99% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.595 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 0 | 9% of the 12000 verts budget used (1179) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.8 at the close-up (79503 px), 4.18 at 25 m; close-up outline complexity 2.23 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 35 | outline complexity 1.75 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 49.4, bottom third L* 10.2 (+39, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 94 | inner detail 2.8 at 25 m, 4.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 67.5, 0% melts; body L* 37.6 C 40.5 vs floor L* 49.3 C 41.5 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 83 | front-view asymmetry 0.17 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Walls 598 v / 6 s; Body/Roof 395 v / 3 s; Rubble 168 v / 1 s x7; Body/LanternOrb 104 v / 1 s; Body/Plinth 61 v / 1 s; Body/TipShard 21 v / 1 s; ContactDecal 4 v / 1 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 13 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: B8 13 -> 10 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-76534` -> `StandardMaterial3D#-83678` (dE 0.0), `StandardMa)
