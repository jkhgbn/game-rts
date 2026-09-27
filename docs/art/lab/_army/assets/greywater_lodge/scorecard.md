# Art Lab scorecard: greywater_lodge

Scene `res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-09-27 10:24:06 · lab v2.0

## Result: **FAIL** · quality **83 / 100**

2 FAIL · 2 WARN · 12 PASS · 12 info · 0 skipped · 16 s

## Improve next
1. **Vertices** (FAIL): B4 24101 -> 12093 (want <= 12000): `Structure` 21865 -> 10933 verts; `HoundMesh` 861 -> 431 verts; `Rubble` 480 -> 240 verts; `Lantern` 324 -> 162 verts; `ContactDecal` 288 -> 144 verts; `DoorLeaf` 201 -> 101 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Unique materials** (FAIL): B8 27 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-90308` -> `StandardMaterial3D#-30905` (dE 0.0), `StandardMaterial3D#-27004` -> `StandardMaterial3D#-30905` (dE 0.0), `StandardMaterial3D#-9269` -> `StandardMaterial3D#-30905` (dE 0.0), `StandardMaterial3D#-56068` -> `StandardMaterial3D#-30905` (dE 0.0), `StandardMaterial3D#-47200` -> `StandardMaterial3D#-30905` (dE 0.0), `StandardMaterial3D#-80083` -> `StandardMaterial3D#-30905` (dE 0.0), `ShaderMaterial#-18735` -> `ShaderMaterial#-50478` (dE 3.4), `ShaderMaterial#-9881` -> `ShaderMaterial#-50478` (dE 3.7), `ShaderMaterial#-55655` -> `ShaderMaterial#-73215` (dE 5.8), `ShaderMaterial#-96093` -> `ShaderMaterial#-27551` (dE 6.4), `ShaderMaterial#-78176` -> `ShaderMaterial#-27551` (dE 6.7), `ShaderMaterial#-32519` -> `ShaderMaterial#-35` (dE 9.1), `ShaderMaterial#-35` -> `ShaderMaterial#-50478` (dE 9.1), `ShaderMaterial#-41352` -> `ShaderMaterial#-50478` (dE 12.2), `ShaderMaterial#-64127` -> `ShaderMaterial#-73215` (dE 20.0), `ShaderMaterial#-73215` -> `ShaderMaterial#-50478` (dE 21.4), `ShaderMaterial#-87144` -> `ShaderMaterial#-50478` (dE 29.5), `ShaderMaterial#-50478` -> `ShaderMaterial#-27551` (dE 31.4), `ShaderMaterial#-19812` -> `ShaderMaterial#-92083` (dE 69.9) [fixes.json #2] _(from B8 Unique materials)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 23 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #4] _(from A1 Standard hooks)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 14.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B12 | Downward-facing triangles | INFO | 3920 of 25922 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.09 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 24211 px (227 x 200 bbox; 55 m: 12419 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 40.0, 1% of the body melts (within dE 15 of the ground); body L* 58.4 C 11.2 vs ground L* 60.9 C 50.2, hue gap n/a (body C* <= 25); top third (world height) dE 38.8, L* 49.9; per-pixel dE 46.1, outline 31.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 88 | worst heath: dE 14.3 (heath dE 14.3, old_wood dE 31.9, riverbank dE 25.9, snow dE 32.8, ash dE 36.4, sand dE 30.9, marsh dE 42.2) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +30 (point 1 dL +30, point 2 dL +32, point 3 dL +36; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): BrazierFire, Lantern, Rubble; soft glows under the bloom (v1 count, luma > 0.4): 5 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.59 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 51 | top third L* 49.9, bottom third L* 46.2 (+3, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.7 at 25 m, 6.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 67 | 1 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Structure 21865 v / 15 s; Hound/HoundMesh 861 v / 3 s; Rubble 480 v / 1 s x10; LanternPivot/Lantern 324 v / 2 s; ContactDecal 288 v / 1 s; DoorPivot/DoorLeaf 201 v / 3 s; DoorGlow 24 v / 1 s; FlagPivot/Pennant 20 v / 1 s
- 26 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B4 24101 -> 12093 (want <= 12000): `Structure` 21865 -> 10933 verts; `HoundMesh` 861 -> 431 verts; `Rubble` 480 -> 240 verts; `Lantern` 324 -> 162 verts; `Conta)
