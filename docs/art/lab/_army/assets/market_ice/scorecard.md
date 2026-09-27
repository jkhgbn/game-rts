# Art Lab scorecard: market_ice

Scene `res://art/buildings/market/ice/market_ice.tscn` · kind **building** / tier **hall** · kingdom ice · ground meadow · 2026-09-27 09:58:37 · lab v2.0

## Result: **FAIL** · quality **88 / 100**

1 FAIL · 4 WARN · 15 PASS · 11 info · 0 skipped · 48 s

## Improve next
1. **Unique materials** (FAIL): B8 17 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-63210` -> `StandardMaterial3D#-49274` (dE 0.0), `ShaderMaterial#-96435` -> `ShaderMaterial#-12612` (dE 0.0), `ShaderMaterial#-73286` -> `ShaderMaterial#-44276` (dE 8.2), `ShaderMaterial#-89804` -> `ShaderMaterial#-50486` (dE 13.4), `ShaderMaterial#-44276` -> `ShaderMaterial#-66884` (dE 20.3), `ShaderMaterial#-12612` -> `ShaderMaterial#-50486` (dE 28.9), `ShaderMaterial#-18963` -> `ShaderMaterial#-66884` (dE 38.4), `ShaderMaterial#-50486` -> `ShaderMaterial#-66884` (dE 58.9), `ShaderMaterial#-41407` -> `ShaderMaterial#-66884` (dE 90.1) [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 8 -> 4 (want 2-4): ShaderMaterial#-66884 crack_strength 0.0 -> 0.0 (dim under the bloom level: 4 point(s), peak 4.45 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 29 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 10.0): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 4 glow point(s) barely stand out from their 1 m surround (worst dL +2): darken around them or raise the energy [fixes.json #5] _(from R5c Glow points stand out (1 m surround), shot glow)_
6. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.8): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 45 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 29 material(s), 7 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 15 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 17 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 7956 (biggest: Walls 1741, PlinthBase 1574, Roof 1158, CargoParts 843) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 22 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 17 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 22 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 47 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1264 of 5330 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.34 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 27566 px (226 x 229 bbox; 55 m: 14218 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 57.0, 0% of the body melts (within dE 15 of the ground); body L* 68.2 C 8.5 vs ground L* 60.4 C 50.0, hue gap n/a (body C* <= 25); top third (world height) dE 54.5, L* 83.6; per-pixel dE 63.2, outline 28.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 24.7, 44% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 24.7 (heath dE 37.4, old_wood dE 49.3, riverbank dE 43.8, snow dE 24.7, ash dE 46.3, sand dE 42.7, marsh dE 55.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 29% of body pixels change between kingdom colours (min pair 28%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 41.2 (fire 54.6, shadow 67.6, ice 57.2, nature 41.2) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 43 | worst pair fire / nature (deutan): dE 10.0 on the team-colour area (normal vision 75.5; 8485 px); deutan: fire / nature dE 10.0; protan: fire / nature dE 22.2; worst vs ground: fire colour (deutan) dE 33.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | **WARN** 53 | worst dL +2 (point 1 dL +13, point 2 dL +45, point 3 dL +45, point 4 dL +14, point 5 dL +2, point 6 dL +54, point 7 dL +11, point 8 dL +25; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 8 point(s) above the bloom level 1.2 (median of 8/9/8): StallCanopy, MastGem, PanRParts, MastParts x3, Roof, MastBanner; soft glows under the bloom (v1 count, luma > 0.4): 28 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): StallCanopy, MastGem, PanRParts, MastParts x3, Roof, MastBanner |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.51 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 83.6, bottom third L* 54.4 (+29, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 94 | inner detail 2.8 at 25 m, 4.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 5 of 8 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Walls 1741 v / 11 s; Body/PlinthBase 1574 v / 4 s; Body/Roof 1158 v / 6 s; Body/CargoSled/CargoParts 843 v / 4 s; Body/SledStall/StallParts 751 v / 5 s; Body/Mast/MastParts 670 v / 4 s; Body/SledStall/StallCanopy 242 v / 2 s; Body/Mast/ScaleBeam/PanL/PanLParts 240 v / 2 s
- 7 hidden parts at rest (toggled states, not counted as draws)
- 17 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B8 17 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-63210` -> `StandardMaterial3D#-49274` (dE 0.0), `ShaderMaterial#-96435` -> `Sh)
