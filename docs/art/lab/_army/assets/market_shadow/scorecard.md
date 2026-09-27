# Art Lab scorecard: market_shadow

Scene `res://art/buildings/market/shadow/market_shadow.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-09-27 10:17:27 · lab v2.0

## Result: **FAIL** · quality **91 / 100**

1 FAIL · 2 WARN · 17 PASS · 11 info · 0 skipped · 47 s

## Improve next
1. **Unique materials** (FAIL): B8 19 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-21696` -> `StandardMaterial3D#-84939` (dE 0.0), `StandardMaterial3D#-84939` -> `StandardMaterial3D#-24444` (dE 0.0), `StandardMaterial3D#-24444` -> `StandardMaterial3D#-10495` (dE 0.0), `StandardMaterial3D#-10495` -> `StandardMaterial3D#-12901` (dE 0.0), `ShaderMaterial#-91601` -> `ShaderMaterial#-96655` (dE 10.3), `ShaderMaterial#-96655` -> `ShaderMaterial#-14409` (dE 23.5), `ShaderMaterial#-50965` -> `ShaderMaterial#-59913` (dE 25.3), `ShaderMaterial#-74409` -> `ShaderMaterial#-37220` (dE 36.0), `StandardMaterial3D#-6654` -> `StandardMaterial3D#-12901` (dE 36.8), `ShaderMaterial#-59913` -> `ShaderMaterial#-37220` (dE 46.7), `ShaderMaterial#-37220` -> `ShaderMaterial#-14409` (dE 51.5) [fixes.json #1] _(from B8 Unique materials)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 30 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #2] _(from B9 Materials built per instance)_
3. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 2 glow point(s) barely stand out from their 1 m surround (worst dL +0): darken around them or raise the energy [fixes.json #3] _(from R5c Glow points stand out (1 m surround), shot glow)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 46 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 30 material(s), 10 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 17 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 19 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 95 | 9615 (biggest: StallFrame 2854, NightStall 2137, MastStack 1241, PanLMesh 624) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 17 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 19 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 23 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 41 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1755 of 9194 triangles (19%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 27319 px (213 x 208 bbox; 55 m: 14001 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 83.3, 0% of the body melts (within dE 15 of the ground); body L* 26.3 C 25.3 vs ground L* 61.4 C 50.4, hue gap 171 deg; top third (world height) dE 56.0, L* 57.8; per-pixel dE 88.5, outline 51.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 32.3, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 22.5 (heath dE 55.9, old_wood dE 46.0, riverbank dE 56.1, snow dE 69.3, ash dE 22.5, sand dE 76.1, marsh dE 32.3) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 24% of body pixels change between kingdom colours (min pair 24%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 62.6 (fire 72.7, shadow 83.3, ice 72.5, nature 62.6) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 14.2 on the team-colour area (normal vision 69.5; 7661 px); deutan: fire / nature dE 14.2; protan: fire / nature dE 24.4; worst vs ground: fire colour (deutan) dE 54.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 52 | worst dL +0 (point 1 dL +38, point 2 dL +42, point 3 dL +15, point 4 dL +0; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 4/3/3): MouthPool x2, CoinMesh; soft glows under the bloom (v1 count, luma > 0.4): 8 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.66 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 57.8, bottom third L* 18.9 (+38, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.5 at 25 m, 6.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 50 | 1 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/StallFrame 2854 v / 7 s; Body/NightStall 2137 v / 6 s; Body/Mast/MastStack 1241 v / 4 s; Body/Mast/ScalePivot/ScaleBeam/PanL/PanLMesh 624 v / 2 s; Body/PlinthBase 576 v / 2 s; Body/Mast/ScalePivot/ScaleBeam/PanR/PanRMesh 547 v / 2 s; Body/Awning/AwningWhole 448 v / 4 s; Body/Mast/ScalePivot/ScaleBeam/BeamMesh 390 v / 2 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 19 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B8 19 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-21696` -> `StandardMaterial3D#-84939` (dE 0.0), `StandardMaterial3D#-84939` ->)
