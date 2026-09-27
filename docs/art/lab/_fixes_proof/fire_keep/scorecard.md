# Art Lab scorecard: fire_keep

Scene `res://art/buildings/fire_keep.tscn` · kind **building** / tier **keep** · kingdom fire · ground meadow · 2026-09-27 09:51:48 · lab v2.0

## Result: **WARN** · quality **93 / 100** (previous run 93, +0)

0 FAIL · 2 WARN · 17 PASS · 12 info · 0 skipped · 102 s

## Before / after (vs the run of 2026-09-27 09:43:28 in `docs/art/lab/_fixes_proof/fire_keep`: quality 93 -> 93, -0)
### What got worse (0)
Nothing got worse.

### Score delta per check (2 changed, 31 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6cb | Team colours for colour-blind players | PASS 83 | PASS 83 | -0.6 |
| P3 | Tops light, bottoms dark | INFO 61 | INFO 60 | -0.6 |

Changed pixels per shot: z40 6.4 %, z55 5.2 %, z25 8.9 %, close 1.1 %, turns 1.9 %, anim 1.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 33 -> 10 (want 4-12): FirePainted glow colour #ff801f -> #693106 (x0.14 linear) on Plinth, Spire, Roofs, RoofLost (dim under the bloom level: 12 point(s), peak 5.27 x the level); FireGlow boost 1.4 -> 0.09 on Crystal1, Braziers, Crystal3, Crystal2 (dim under the bloom level: 11 point(s), peak 6.78 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +0): darken around them or raise the energy [fixes.json #2] _(from R5c Glow points stand out (1 m surround), shot glow)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +5 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 41 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 14 material(s), 3 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 19 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 99 | 23 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | PASS 88 | 11397 (biggest: Towers 2544, Walls 2199, Roofs 1068, Braziers 984) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (HeartLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 13 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 4 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 87 | 86 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 11 | no budget for building/keep |  |
| B8 | Unique materials | PASS 93 | 7 | <= 8 (art-keep.md 9) |  |
| B1a | Authored build parts (before the merge) | INFO | 22 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 21 surfaces over 19 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 102 of 3933 triangles (2%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 92482 px (332 x 533 bbox; 55 m: 42411 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 45.9, 0% of the body melts (within dE 15 of the ground); body L* 37.3 C 25.5 vs ground L* 56.3 C 41.8, hue gap 72 deg; top third (world height) dE 29.3, L* 35.9; per-pixel dE 61.4, outline 43.7 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 25.0, 27% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 24.4 (heath dE 33.5, old_wood dE 28.6, riverbank dE 34.9, snow dE 56.9, ash dE 25.0, sand dE 47.4, marsh dE 24.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 26% of body pixels change between kingdom colours (min pair 24%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 35.3 (fire 45.8, shadow 52.9, ice 42.6, nature 35.3) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.4 on the team-colour area (normal vision 47.5; 33078 px); deutan: fire / nature dE 14.4; protan: fire / nature dE 17.0; worst vs ground: fire colour (deutan) dE 23.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 63 | worst dL +0 (point 1 dL +0, point 2 dL +45, point 3 dL +46, point 4 dL +73, point 5 dL +55, point 6 dL +30, point 7 dL +57, point 8 dL +34, point 9 dL +31, point 10 dL +73, point 11 dL +44, point 12 dL +53, point 13 dL +63, point 14 dL +22, point 15 dL +30, point 16 dL +25, point 17 dL +33, point 18 dL +26, point 19 dL +66, point 20 dL +30, point 21 dL +50, point 22 dL +30, point 23 dL +35, point 24 dL +59, point 25 dL +63, point 26 dL +34, point 27 dL +52, point 28 dL +29, point 29 dL +50, point 30 dL +42, point 31 dL +63, point 32 dL +34, point 33 dL +26; ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 5 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 33 point(s) above the bloom level 1.2 (median of 33/34/30): EmberHeart, Plinth, BannersSide, BannersGate x5, Braziers x6, Crystal3, Crystal2, Crystal1, Spire x5, Roofs x3, RoofLost x6, RuneRing x2, 4 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 50 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): EmberHeart, Plinth, BannersSide, BannersGate x5, Braziers x6, Crystal3, Crystal2, Crystal1, Spire x5, Roofs x3, RoofLost x6, RuneRing x2 |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 8.24 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 60 | top third L* 35.9, bottom third L* 30.7 (+5, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.9 at 25 m, 6.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 29 of 33 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Towers 2544 v / 1 s; Body/Walls 2199 v / 2 s; Body/Roofs 1068 v / 1 s; Body/Braziers 984 v / 2 s; Body/Spire 738 v / 1 s; Rubble 591 v / 1 s; Body/Donjon 552 v / 1 s; Body/Windows 549 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 2 in fixes.json (top: Glow points 33 -> 10 (want 4-12): FirePainted glow colour #ff801f -> #693106 (x0.14 linear) on Plinth, Spire, Roofs, RoofLost (dim under the bloom level: 12 poi)
