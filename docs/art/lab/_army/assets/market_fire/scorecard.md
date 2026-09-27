# Art Lab scorecard: market_fire

Scene `res://art/buildings/market/fire/market_fire.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-09-27 09:53:00 · lab v2.0

## Result: **FAIL** · quality **89 / 100**

1 FAIL · 2 WARN · 17 PASS · 11 info · 0 skipped · 47 s

## Improve next
1. **Unique materials** (FAIL): B8 15 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-96354` -> `StandardMaterial3D#-84138` (dE 0.0), `StandardMaterial3D#-97847` -> `StandardMaterial3D#-84138` (dE 0.0), `ShaderMaterial#-56290` -> `ShaderMaterial#-78942` (dE 22.5), `StandardMaterial3D#-80376` -> `StandardMaterial3D#-84138` (dE 36.8), `ShaderMaterial#-24397` -> `ShaderMaterial#-1868` (dE 37.8), `ShaderMaterial#-15585` -> `ShaderMaterial#-1868` (dE 42.6), `ShaderMaterial#-1868` -> `ShaderMaterial#-78942` (dE 61.2) [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 5 -> 2 (want 2-4): ShaderMaterial#-70029 energy 3.0 -> 0.0 (dim under the bloom level: 3 point(s), peak 7.44 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 27 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.03): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 49 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 27 material(s), 8 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 20 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 99 | 23 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 6460 (biggest: Stall 1677, Crates 933, PanParts 434, House 432) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 36 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 16 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 15 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 28 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 49 surfaces over 20 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1052 of 5360 triangles (19%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 27839 px (213 x 244 bbox; 55 m: 14232 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 55.3, 0% of the body melts (within dE 15 of the ground); body L* 43.0 C 32.8 vs ground L* 61.6 C 50.6, hue gap 73 deg; top third (world height) dE 45.7, L* 54.0; per-pixel dE 68.3, outline 46.0 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 34.5, 12% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 26.6 (heath dE 26.6, old_wood dE 35.9, riverbank dE 43.1, snow dE 54.7, ash dE 34.5, sand dE 41.6, marsh dE 34.2) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 34% of body pixels change between kingdom colours (min pair 31%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 33.3 (fire 55.0, shadow 68.4, ice 49.3, nature 33.3) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 12.7 on the team-colour area (normal vision 65.3; 11491 px); deutan: fire / nature dE 12.7; protan: fire / nature dE 20.9; worst vs ground: fire colour (deutan) dE 21.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +22 (point 1 dL +25, point 2 dL +26, point 3 dL +44, point 4 dL +22, point 5 dL +26, point 6 dL +22; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) above the bloom level 1.2 (median of 6/5/5): MastTop, Brazier, PanParts x2, Medallion; soft glows under the bloom (v1 count, luma > 0.4): 8 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): MastTop, Brazier, PanParts x2, Medallion |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 56 | outline complexity 2.03 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 54.0, bottom third L* 35.3 (+18, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.5 at 25 m, 5.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 5 of 6 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Stall 1677 v / 6 s; Body/Crates 933 v / 3 s; Body/Mast/ScalePivot/PanA/PanParts 434 v / 3 s; Body/House 432 v / 5 s; Body/Awning 420 v / 2 s; Body/Mast/MastStack 355 v / 2 s; Body/Mast/ScalePivot/Beam/BeamParts 332 v / 3 s; Body/Brazier 305 v / 3 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 15 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B8 15 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-96354` -> `StandardMaterial3D#-84138` (dE 0.0), `StandardMaterial3D#-97847` ->)
