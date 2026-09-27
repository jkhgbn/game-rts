# Art Lab scorecard: ice_keep

Scene `res://art/buildings/ice_keep.tscn` · kind **building** / tier **keep** · kingdom ice · ground meadow · 2026-09-27 09:56:02 · lab v2.0

## Result: **FAIL** · quality **88 / 100**

1 FAIL · 3 WARN · 15 PASS · 12 info · 0 skipped · 82 s

## Improve next
1. **Unique materials** (FAIL): B8 11 -> 8 materials: use one material for look-alike pairs: `Stone` -> `DarkStone` (dE 12.6), `Silver` -> `Snow` (dE 13.4), `Crystal` -> `Snow` (dE 28.9) [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 52 -> 12 (want 4-12): Glow boost_mult 1.0 -> 0.13 (dim under the bloom level: 20 point(s), peak 5.84 x the level); ? emission x 0.09 (dim under the bloom level: 13 point(s), peak 8.0 x the level (>= 8, clipped); no energy parameter found: scale its emission colour / strength); Crystal crack_strength 0.9 -> 0.12 (dim under the bloom level: 7 point(s), peak 5.55 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 9.9): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 33 glow point(s) barely stand out from their 1 m surround (worst dL +0): darken around them or raise the energy [fixes.json #4] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.1): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Contrast on the home ground (snow)** (PASS): On its home ground (snow) the body is only dE 16.1: add a value step for that ground _(from R4k Contrast on the home ground (snow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 45 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 10 material(s), 0 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 25 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 92 | 28 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | PASS 100 | 7101 (biggest: Icicles 1550, GroundSpikes 1224, Spikes 720, Towers 576) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 89 | 84 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 12 | no budget for building/keep |  |
| B8 | Unique materials | **FAIL** 2 | 11 | <= 8 (art-keep.md 9) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 27 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 25 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 136 of 3712 triangles (3%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.52 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 53827 px (236 x 433 bbox; 55 m: 25522 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.3, 0% of the body melts (within dE 15 of the ground); body L* 79.0 C 8.5 vs ground L* 59.3 C 46.2, hue gap n/a (body C* <= 25); top third (world height) dE 48.6, L* 88.9; per-pixel dE 59.3, outline 26.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 89 | dE 16.1, 48% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 91 | worst snow: dE 16.1 (heath dE 43.5, old_wood dE 57.8, riverbank dE 47.6, snow dE 16.1, ash dE 57.1, sand dE 40.5, marsh dE 65.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 51% of body pixels change between kingdom colours (min pair 49%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 29.9 (fire 48.6, shadow 70.7, ice 51.8, nature 29.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 43 | worst pair fire / nature (deutan): dE 9.9 on the team-colour area (normal vision 63.3; 29434 px); deutan: fire / nature dE 9.9; protan: fire / nature dE 19.3; worst vs ground: fire colour (deutan) dE 24.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | **WARN** 49 | worst dL +0 (point 1 dL +31, point 2 dL +37, point 3 dL +36, point 4 dL +37, point 5 dL +36, point 6 dL +24, point 7 dL +7, point 8 dL +13, point 9 dL +24, point 10 dL +24, point 11 dL +4, point 12 dL +3, point 13 dL +20, point 14 dL +27, point 15 dL +28, point 16 dL +29, point 17 dL +15, point 18 dL +6, point 19 dL +9, point 20 dL +14, point 21 dL +8, point 22 dL +14, point 23 dL +39, point 24 dL +27, point 25 dL +12, point 26 dL +16, point 27 dL +7, point 28 dL +22, point 29 dL +15, point 30 dL +31, point 31 dL +39, point 32 dL +24, point 33 dL +23, point 34 dL +21, point 35 dL +45, point 36 dL +9, point 37 dL +11, point 38 dL +13, point 39 dL +14, point 40 dL +9, point 41 dL +5, point 42 dL +37, point 43 dL +30, point 44 dL +33, point 45 dL +22, point 46 dL +41, point 47 dL +47, point 48 dL +6, point 49 dL +46, point 50 dL +5, point 51 dL +3, point 52 dL +33, point 53 dL +11, point 54 dL +46, point 55 dL +45, point 56 dL +3, point 57 dL +12, point 58 dL +19, point 59 dL +3, point 60 dL +11, point 61 dL +13, point 62 dL +0, point 63 dL +8, point 64 dL +2, point 65 dL +14; ring 28 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 52 point(s) above the bloom level 1.2 (median of 65/50/52): HaloShards x3, TipMesh x2, CrystalR x8, CrystalMain, Core, CrownShards x6, Windows x10, Banner1, Gatehouse, CrystalL x7, GateVoid x3, GateGlow x2, BannerPoles x3, GateFrame, TowerCaps, Rubble, PlinthLower, 6 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 24 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): HaloShards x3, TipMesh x2, CrystalR x8, CrystalMain, Core, CrownShards x6, Windows x10, Banner1, Gatehouse, CrystalL x7, GateVoid x3, GateGlow x2, BannerPoles x3, GateFrame, TowerCaps, Rubble, PlinthLower |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.56 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 88.9, bottom third L* 73.1 (+15, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 76 | inner detail 2.1 at 25 m, 3.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 95 | 31 of 65 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Model/Icicles 1550 v / 1 s x62; Model/GroundSpikes 1224 v / 1 s x17; Model/Spikes 720 v / 1 s x10; Model/Towers 576 v / 1 s; Model/Halo/HaloShards 432 v / 1 s x6; Model/Windows 408 v / 1 s x17; Model/CrownShards 360 v / 1 s x5; Model/TowerCaps 288 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B8 11 -> 8 materials: use one material for look-alike pairs: `Stone` -> `DarkStone` (dE 12.6), `Silver` -> `Snow` (dE 13.4), `Crystal` -> `Snow` (dE 28.9))
