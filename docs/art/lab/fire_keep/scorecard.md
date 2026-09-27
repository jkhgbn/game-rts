# Art Lab scorecard: fire_keep

Scene `res://art/buildings/fire_keep.tscn` · kind **building** / tier **keep** · kingdom fire · ground meadow · 2026-09-26 23:49:32 · lab v2.0

## Result: **WARN** · quality **90 / 100** (previous run 89, +1)

0 FAIL · 1 WARN · 18 PASS · 13 info · 0 skipped · 72 s

## Improve next
1. **Glow points at 40 m** (WARN): Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): EmberHeart, Plinth, BannersGate x5, BannersSide, Braziers x6, Crystal3, Crystal2, Spire x4, Crystal1, Roofs x3, RoofLost x5, RuneRing x3 _(from R5 Glow points at 40 m, shot glow)_
2. **Materials built per instance** (INFO): Share the 14 per-instance material(s) (static cache) so 200 units do not build 200 copies _(from B9 Materials built per instance)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +5 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from fire_hall (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 41 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 0 | 14 material(s), 3 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials) |  |
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
| B12 | Downward-facing triangles | INFO | 102 of 3933 triangles (2%) face steeply down (normal y < -0.7) | hint when > 25 %%: the camera looks from above (pitch 55); a sphere has ~15 %%, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0104 ms process per instance (8 animated at 40 m: +0.08 ms process, render CPU +0.34 ms, GPU +0.67 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 92529 px (332 x 533 bbox; 55 m: 42450 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 46.1, 0% of the body melts (within dE 15 of the ground); body L* 36.6 C 24.9 vs ground L* 56.3 C 41.8, hue gap n/a (body C* <= 25); top third (world height) dE 29.0, L* 35.9; per-pixel dE 61.8, outline 43.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 24.9, 28% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 23.2 (heath dE 33.9, old_wood dE 28.0, riverbank dE 33.5, snow dE 57.1, ash dE 24.9, sand dE 47.5, marsh dE 23.2) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 26% of body pixels change between kingdom colours (min pair 24%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 34.5 (fire 45.4, shadow 53.4, ice 43.1, nature 34.5) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 32 point(s) above the bloom level 1.2 (median of 31/32/35): EmberHeart, Plinth, BannersGate x5, BannersSide, Braziers x6, Crystal3, Crystal2, Spire x4, Crystal1, Roofs x3, RoofLost x5, RuneRing x3, 2 rim-light speck(s) ignored | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): EmberHeart, Plinth, BannersGate x5, BannersSide, Braziers x6, Crystal3, Crystal2, Spire x4, Crystal1, Roofs x3, RoofLost x5, RuneRing x3 |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.65 (fire_hall 0.65, magpie_den 0.58, market_fire 0.58, dragon_roost 0.53, watchtower 0.38, fire_tower 0.12) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 8.24 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 64 | top third L* 35.9, bottom third L* 30.1 (+5, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.9 at 25 m, 6.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 26 of 31 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| P2 | Asymmetric secondary shape | INFO 77 | front-view asymmetry 0.16 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Towers 2544 v / 1 s; Body/Walls 2199 v / 2 s; Body/Roofs 1068 v / 1 s; Body/Braziers 984 v / 2 s; Body/Spire 738 v / 1 s; Rubble 591 v / 1 s; Body/Donjon 552 v / 1 s; Body/Windows 549 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
