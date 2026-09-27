# Art Lab scorecard: shadow_tower

Scene `res://art/buildings/shadow_tower.tscn` · kind **building** / tier **small** · kingdom shadow · ground meadow · 2026-09-27 10:20:42 · lab v2.0

## Result: **FAIL** · quality **90 / 100**

1 FAIL · 3 WARN · 16 PASS · 11 info · 0 skipped · 21 s

## Improve next
1. **Real lights** (FAIL): B5 Real lights: No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4) [fixes.json #1] _(from B5 Real lights)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 14 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
3. **Unique materials** (WARN): B8 12 -> 7 materials: use one material for look-alike pairs: `StandardMaterial3D#-73353` -> `StandardMaterial3D#-79643` (dE 0.0), `StandardMaterial3D#-65561` -> `StandardMaterial3D#-79643` (dE 0.0), `ShaderMaterial#-93489` -> `ShaderMaterial#-16370` (dE 12.5), `ShaderMaterial#-62110` -> `ShaderMaterial#-39128` (dE 46.7), `ShaderMaterial#-39128` -> `ShaderMaterial#-16370` (dE 50.3) [fixes.json #2] _(from B8 Unique materials)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 9.5): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Silhouette area at 40 m** (PASS): Grow the read at 40 m (now 5018 px): push the key shape (weapon, horns, crest, back mass) 15-25 % bigger _(from R1 Silhouette area at 40 m, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 14 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 9 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 | 991 (biggest: Shaft 222, RuneRing 175, Rubble 168, RuneStones 144) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | **FAIL** 0 | 1 (OrbLight) | <= 0 (lab default (towers, walls, posts): half a keep) | No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4) |
| B6 | Particle systems | INFO | 5 | no budget for building/small |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 10 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 35 | 12 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 16 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 13 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 164 of 974 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.21 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 81 | 5018 px (71 x 129 bbox; 55 m: 2574 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 86.1, 0% of the body melts (within dE 15 of the ground); body L* 28.6 C 30.4 vs ground L* 62.2 C 49.3, hue gap 168 deg; top third (world height) dE 109.9, L* 64.2; per-pixel dE 93.5, outline 62.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 38.5, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 28.5 (heath dE 59.6, old_wood dE 52.0, riverbank dE 63.4, snow dE 68.7, ash dE 28.5, sand dE 76.9, marsh dE 38.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 48% of body pixels change between kingdom colours (min pair 40%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 56.8 (fire 62.8, shadow 81.5, ice 64.5, nature 56.8) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 42 | worst pair fire / nature (deutan): dE 9.5 on the team-colour area (normal vision 23.4; 2884 px); deutan: fire / nature dE 9.5; protan: fire / nature dE 11.0; worst vs ground: fire colour (deutan) dE 48.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +21 (point 1 dL +21, point 2 dL +60; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/3): OrbMotes, Plinth; soft glows under the bloom (v1 count, luma > 0.4): 2 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.14 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 64.2, bottom third L* 10.4 (+53, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.2 at 25 m, 6.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
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
- Per-mesh vertices (biggest first): Body/Shaft 222 v / 4 s; Body/RuneRing 175 v / 1 s; Rubble 168 v / 1 s x7; Body/RuneStones 144 v / 2 s; Body/Orb 104 v / 1 s; Body/Plinth 74 v / 1 s; Body/Fins 63 v / 1 s x3; Body/Collar 37 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 12 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B5 Real lights: No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4))
