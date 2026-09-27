# Art Lab scorecard: ice_lodge

Scene `res://art/buildings/ice_lodge.tscn` · kind **building** / tier **hall** · kingdom ice · ground meadow · 2026-09-27 09:57:25 · lab v2.0

## Result: **FAIL** · quality **87 / 100**

1 FAIL · 4 WARN · 15 PASS · 11 info · 0 skipped · 28 s

## Improve next
1. **Unique materials** (FAIL): B8 14 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-90724` -> `StandardMaterial3D#-79643` (dE 0.0), `StandardMaterial3D#-79643` -> `StandardMaterial3D#-73353` (dE 0.0), `ShaderMaterial#-84728` -> `ShaderMaterial#-25225` (dE 8.2), `ShaderMaterial#-70810` -> `ShaderMaterial#-61945` (dE 13.4), `ShaderMaterial#-25225` -> `ShaderMaterial#-48016` (dE 20.3), `ShaderMaterial#-93819` -> `ShaderMaterial#-61945` (dE 28.9) [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 5 -> 2 (want 2-4): ShaderMaterial#-70810 crack_strength 0.0 -> 0.0 (dim under the bloom level: 3 point(s), peak 4.02 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 18 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 10.0): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 2 glow point(s) barely stand out from their 1 m surround (worst dL +7): darken around them or raise the energy [fixes.json #5] _(from R5c Glow points stand out (1 m surround), shot glow)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 18 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 8 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 3087 (biggest: Walls 1069, Dome 970, Plinth 697, Rubble 168) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 6 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 16 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 3 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 14 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 22 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 434 of 1876 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 11008 px (127 x 135 bbox; 55 m: 5694 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 56.4, 0% of the body melts (within dE 15 of the ground); body L* 68.0 C 8.5 vs ground L* 62.3 C 49.9, hue gap n/a (body C* <= 25); top third (world height) dE 56.8, L* 85.0; per-pixel dE 62.2, outline 25.8 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 24.4, 45% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 24.4 (heath dE 37.1, old_wood dE 49.4, riverbank dE 46.3, snow dE 24.4, ash dE 46.6, sand dE 42.4, marsh dE 56.1) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 29% of body pixels change between kingdom colours (min pair 29%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 40.9 (fire 53.9, shadow 66.9, ice 56.3, nature 40.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 43 | worst pair fire / nature (deutan): dE 10.0 on the team-colour area (normal vision 75.7; 3419 px); deutan: fire / nature dE 10.0; protan: fire / nature dE 21.6; worst vs ground: fire colour (deutan) dE 33.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | **WARN** 48 | worst dL +7 (point 1 dL +25, point 2 dL +15, point 3 dL +32, point 4 dL +7, point 5 dL +23; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) above the bloom level 1.2 (median of 5/5/5): CrystalSparkles, Lantern, Dome x3; soft glows under the bloom (v1 count, luma > 0.4): 12 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): CrystalSparkles, Lantern, Dome x3 |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 84 | outline complexity 2.39 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 85.0, bottom third L* 59.5 (+25, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.6 at 25 m, 7.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 80 | 2 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Walls 1069 v / 7 s; Body/Dome 970 v / 6 s; Body/Plinth 697 v / 3 s; Rubble 168 v / 1 s x7; Body/Lantern 69 v / 2 s; Body/ChimneyCrystal 62 v / 1 s; Body/Banner 48 v / 1 s; ContactDecal 4 v / 1 s
- 6 hidden parts at rest (toggled states, not counted as draws)
- 14 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B8 14 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-90724` -> `StandardMaterial3D#-79643` (dE 0.0), `StandardMaterial3D#-79643` ->)
