# Art Lab scorecard: ember_crucible

Scene `res://art/buildings/fire/ember_crucible/ember_crucible.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-09-27 09:49:23 · lab v2.0

## Result: **FAIL** · quality **73 / 100**

1 FAIL · 5 WARN · 10 PASS · 10 info · 0 skipped · 11 s

## Improve next
1. **Unique materials** (FAIL): B8 12 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-17671` -> `StandardMaterial3D#-25632` (dE 0.0), `StandardMaterial3D#-91110` -> `StandardMaterial3D#-25632` (dE 0.0), `ec_iron` -> `ec_dark` (dE 9.1), `ec_stone` -> `ec_dark` (dE 20.3) [fixes.json #1] _(from B8 Unique materials)_
2. **Contrast on the home ground (ash)** (WARN): shader_parameter/base_color of `ec_stone` #4d423d -> #6a6a8a (29% of the visible body): predicted dE R3 meadow 66.3 -> 77.1, R4k ash 3.9 -> 18.6 (want >= 18); other grounds heath 48.5, old_wood 41.5, riverbank 53.9, snow 65.8, sand 71.9, marsh 29.1 [fixes.json #2] _(from R4k Contrast on the home ground (ash), shot z40)_
3. **Contrast on the other grounds** (WARN): On ash the body drops to dE 3.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Silhouette area at 40 m** (WARN): R1 3774 -> ~5750 px: grow the 40 m read x1.23 (area goes with the square: scale the key masses / body 23 %) [fixes.json #3] _(from R1 Silhouette area at 40 m, shot z40)_
5. **Glow points at 40 m** (WARN): Glow points 0 -> 2 (want 2-4): ec_iron crack_strength 1.0 -> 3.13 (raise over the bloom level: brightest soft glow 0.42 x the level); add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #4] _(from R5 Glow points at 40 m, shot glow)_
6. **Standard hooks** (WARN): A1 Standard hooks: Implement set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed [fixes.json #5] _(from A1 Standard hooks)_

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
| B8 | Unique materials | **FAIL** 0 | 12 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 10 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 11 surfaces over 5 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 514 of 2356 triangles (21%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point 0.0 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | **WARN** 43 | 3774 px (87 x 78 bbox; 55 m: 1972 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 | Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 66.3, 0% of the body melts (within dE 15 of the ground); body L* 21.4 C 9.2 vs ground L* 64.3 C 47.9, hue gap n/a (body C* <= 25); top third (world height) dE 57.3, L* 29.3; per-pixel dE 71.8, outline 60.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | **WARN** 35 | dE 3.9, 38% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | **WARN** 35 | worst ash: dE 3.9 (heath dE 39.0, old_wood dE 25.5, riverbank dE 42.4, snow dE 69.4, ash dE 3.9, sand dE 66.4, marsh dE 9.0) | dE >= 8 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 0 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it) |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 35 | missing: set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 0 | outline complexity 1.25 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 97 | top third L* 29.3, bottom third L* 17.8 (+11, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.2 at 25 m, 9.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

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
- Per-mesh vertices (biggest first): Static 1836 v / 4 s; CruciblePivot/CrucibleBody 772 v / 3 s; CruciblePivot/Crust 301 v / 1 s; BellowsTop/BellowsBoard 86 v / 2 s; BellowsLeather/Leather 20 v / 1 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B8 12 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-17671` -> `StandardMaterial3D#-25632` (dE 0.0), `StandardMaterial3D#-91110` ->)
