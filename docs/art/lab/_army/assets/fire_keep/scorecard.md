# Art Lab scorecard: fire_keep

Scene `res://art/buildings/fire_keep.tscn` · kind **building** / tier **keep** · kingdom fire · ground meadow · 2026-09-27 09:50:31 · lab v2.0

## Result: **WARN** · quality **94 / 100**

0 FAIL · 2 WARN · 17 PASS · 12 info · 0 skipped · 98 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 32 -> 7 (want 4-12): FirePainted emission x 0.14 (dim under the bloom level: 14 point(s), peak 5.24 x the level; no energy parameter found: scale its emission colour / strength); FireGlow boost 1.4 -> 0.0 (dim under the bloom level: 11 point(s), peak 6.37 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 2 glow point(s) barely stand out from their 1 m surround (worst dL -5): darken around them or raise the energy [fixes.json #2] _(from R5c Glow points stand out (1 m surround), shot glow)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +8 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

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
| R1 | Silhouette area at 40 m | PASS 100 | 92573 px (332 x 533 bbox; 55 m: 42467 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 45.9, 0% of the body melts (within dE 15 of the ground); body L* 37.3 C 25.4 vs ground L* 56.3 C 41.8, hue gap 72 deg; top third (world height) dE 27.4, L* 38.1; per-pixel dE 61.3, outline 41.3 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 24.9, 26% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 23.0 (heath dE 34.1, old_wood dE 28.2, riverbank dE 33.9, snow dE 57.5, ash dE 24.9, sand dE 47.8, marsh dE 23.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 27% of body pixels change between kingdom colours (min pair 24%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 35.5 (fire 45.1, shadow 53.3, ice 42.8, nature 35.5) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 84 | worst pair fire / nature (deutan): dE 15.9 on the team-colour area (normal vision 46.7; 35096 px); deutan: fire / nature dE 15.9; protan: fire / nature dE 18.6; worst vs ground: fire colour (deutan) dE 22.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 62 | worst dL -5 (point 1 dL +0, point 2 dL +54, point 3 dL +76, point 4 dL +45, point 5 dL +55, point 6 dL +32, point 7 dL +35, point 8 dL +66, point 9 dL +73, point 10 dL +26, point 11 dL +44, point 12 dL +58, point 13 dL +65, point 14 dL +31, point 15 dL +26, point 16 dL +20, point 17 dL +33, point 18 dL +30, point 19 dL +67, point 20 dL +29, point 21 dL +69, point 22 dL +62, point 23 dL +52, point 24 dL +61, point 25 dL +52, point 26 dL +35, point 27 dL +28, point 28 dL -5, point 29 dL +28, point 30 dL +35, point 31 dL +65, point 32 dL +45, point 33 dL +51, point 34 dL +25, point 35 dL +60, point 36 dL +61; ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 32 point(s) above the bloom level 1.2 (median of 36/32/32): EmberHeart, Plinth x2, BannersSide, BannersGate x5, Braziers x7, Crystal3, Crystal2, Crystal1, Spire x4, Roofs x2, RoofLost x6, RuneRing, 9 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 53 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): EmberHeart, Plinth x2, BannersSide, BannersGate x5, Braziers x7, Crystal3, Crystal2, Crystal1, Spire x4, Roofs x2, RoofLost x6, RuneRing |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 8.29 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 78 | top third L* 38.1, bottom third L* 29.9 (+8, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.0 at 25 m, 6.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 30 of 36 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Towers 2544 v / 1 s; Body/Walls 2199 v / 2 s; Body/Roofs 1068 v / 1 s; Body/Braziers 984 v / 2 s; Body/Spire 738 v / 1 s; Rubble 591 v / 1 s; Body/Donjon 552 v / 1 s; Body/Windows 549 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 2 in fixes.json (top: Glow points 32 -> 7 (want 4-12): FirePainted emission x 0.14 (dim under the bloom level: 14 point(s), peak 5.24 x the level; no energy parameter found: scale it)
