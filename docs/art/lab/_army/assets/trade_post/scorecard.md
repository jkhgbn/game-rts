# Art Lab scorecard: trade_post

Scene `res://art/buildings/trade_post/trade_post.tscn` · kind **building** / tier **small** · kingdom neutral · ground meadow · 2026-09-27 10:29:49 · lab v2.0

## Result: **WARN** · quality **86 / 100**

0 FAIL · 4 WARN · 12 PASS · 12 info · 0 skipped · 19 s

## Improve next
1. **Vertices** (WARN): B4 10711 -> 5764 (want <= 6000): `Structure` 6310 -> 3155 verts; `Sign0` 1824 -> 912 verts; `Awning` 546 -> 273 verts; `Rubble` 480 -> 240 verts; `AwningFrame` 357 -> 179 verts; `Lantern` 335 -> 168 verts; `Arm` 334 -> 312 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 19 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
3. **Unique materials** (WARN): B8 22 -> 6 materials: use one material for look-alike pairs: `StandardMaterial3D#-58804` -> `StandardMaterial3D#-22106` (dE 0.0), `StandardMaterial3D#-22106` -> `StandardMaterial3D#-85405` (dE 0.0), `StandardMaterial3D#-85405` -> `StandardMaterial3D#-29739` (dE 0.0), `ShaderMaterial#-28860` -> `ShaderMaterial#-83312` (dE 0.0), `ShaderMaterial#-6095` -> `ShaderMaterial#-60960` (dE 0.0), `ShaderMaterial#-97224` -> `ShaderMaterial#-92158` (dE 4.2), `ShaderMaterial#-83312` -> `ShaderMaterial#-15288` (dE 6.3), `ShaderMaterial#-37798` -> `ShaderMaterial#-23814` (dE 8.1), `ShaderMaterial#-74567` -> `ShaderMaterial#-69531` (dE 13.7), `ShaderMaterial#-51648` -> `ShaderMaterial#-23814` (dE 14.4), `ShaderMaterial#-92158` -> `ShaderMaterial#-69531` (dE 14.7), `ShaderMaterial#-47503` -> `ShaderMaterial#-23814` (dE 16.5), `ShaderMaterial#-95970` -> `ShaderMaterial#-23814` (dE 20.6), `ShaderMaterial#-69531` -> `ShaderMaterial#-23814` (dE 31.3), `ShaderMaterial#-60960` -> `ShaderMaterial#-15288` (dE 42.7), `ShaderMaterial#-15288` -> `ShaderMaterial#-23814` (dE 59.2) [fixes.json #2] _(from B8 Unique materials)_
4. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #4] _(from A1 Standard hooks)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -5 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

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
| B4 | Vertices | **WARN** 35 | 10711 (biggest: Structure 6310, Sign0 1824, Awning 546, Rubble 480) | <= 6000 soft (lab default (towers, walls, posts): half a keep) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO | 1 | no budget for building/small |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 8 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 7 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 35 | 22 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 18 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1456 of 10614 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.08 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 34410 px (264 x 224 bbox; 55 m: 17712 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 45.2, 1% of the body melts (within dE 15 of the ground); body L* 49.7 C 32.2 vs ground L* 58.7 C 49.1, hue gap 61 deg; top third (world height) dE 46.1, L* 37.5; per-pixel dE 53.2, outline 24.2 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 21.2 (heath dE 21.2, old_wood dE 34.2, riverbank dE 35.4, snow dE 45.0, ash dE 37.4, sand dE 32.3, marsh dE 36.7) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 99 | worst dL +41 (point 1 dL +48, point 2 dL +41; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Flames, Lantern; soft glows under the bloom (v1 count, luma > 0.4): 3 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.6 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 37.5, bottom third L* 43.3 (-5, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 5.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Structure 6310 v / 11 s; Body/SignHead/SignPivot/Sign0 1824 v / 5 s; Body/AwningPivot/Awning 546 v / 2 s; Body/Rubble 480 v / 1 s x10; Body/AwningFrame 357 v / 4 s; Body/LanternPivot/Lantern 335 v / 2 s; Body/SignHead/Arm 334 v / 2 s; Body/ContactDecal 288 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 21 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B4 10711 -> 5764 (want <= 6000): `Structure` 6310 -> 3155 verts; `Sign0` 1824 -> 912 verts; `Awning` 546 -> 273 verts; `Rubble` 480 -> 240 verts; `AwningFrame` )
