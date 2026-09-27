# Art Lab scorecard: nature_keep

Scene `res://art/buildings/nature_keep.tscn` · kind **building** / tier **keep** · kingdom nature · ground meadow · 2026-09-27 10:52:07 · lab v2.0

## Result: **FAIL** · quality **85 / 100** (previous run 83, +3)

2 FAIL · 3 WARN · 17 PASS · 13 info · 0 skipped · 9 s

**Focus run**: focus=B13: 2 check(s) re-measured, 33 kept from the run of 2026-09-27 10:49:23 (rows marked _kept_ were not re-measured).

## Before / after (vs the run of 2026-09-27 10:49:23 in `docs/art/lab/nature_keep`: quality 83 -> 85, +2)
### What got worse (0)
Nothing got worse.

### What got better (1)
B13 Frame cost: FAIL 0 -> PASS 100 (+100) (noisy check: re-run before acting)

### Score delta per check (1 changed, 34 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B13 | Frame cost | FAIL 0 | PASS 100 | +100.0 (noisy) |

Changed pixels per shot: z40 3.9 %, z55 3.6 %, z25 4.4 %, close 4.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (FAIL): B4 39613 -> 19810 (want <= 12000): `Canopy` 13416 -> 6708 verts; `TrunkLow` 6318 -> 3159 verts; `TrunkHigh` 5103 -> 2552 verts; `Rampart` 3609 -> 1805 verts; `Rubble` 2736 -> 1368 verts; `CanopyLost` 2499 -> 1250 verts; `Bloom` 2028 -> 1014 verts; `Plinth` 1344 -> 672 verts; `Pod` 552 -> 276 verts; `Pod` 552 -> 276 verts; `Pod` 552 -> 276 verts; `BannersSide` 540 -> 270 verts; `BannersGate` 360 -> 180 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Unique materials** (FAIL): B8 20 -> 9 materials: use one material for look-alike pairs: `nature_keep` -> `nature_keep` (dE 0.0), `nature_keep` -> `nature_keep` (dE 0.0), `Blossom` -> `Petal` (dE 10.6), `Bark` -> `Wood` (dE 15.7), `Wood` -> `Stone` (dE 19.3), `Moss` -> `DarkStone` (dE 23.9), `Stone` -> `DarkStone` (dE 24.8), `nature_keep` -> `nature_keep` (dE 42.2), `Leaves` -> `DarkStone` (dE 88.0), `Petal` -> `LeafCard` (dE 114.3), `nature_keep` -> `GateVoid` (dE 139.2) [fixes.json #2] _(from B8 Unique materials)_
3. **Glow points at 40 m** (WARN): Glow points 41 -> 12 (want 4-12): Banner glyph_energy 0.9 -> 0.15 on BannersSide, BannersGate (dim under the bloom level: 15 point(s), peak 4.39 x the level); Heart energy 2.5 -> 0.42 on Bloom (dim under the bloom level: 7 point(s), peak 4.49 x the level); Gate energy 1.6 -> 0.16 on Rampart, Plinth (dim under the bloom level: 4 point(s), peak 4.39 x the level); ? emission x 0.17 on Pod (dim under the bloom level: 3 point(s), peak 4.42 x the level; no energy / glow-colour parameter found) [fixes.json #4] _(from R5 Glow points at 40 m, shot glow)_
4. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 22 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #5] _(from B9 Materials built per instance)_
5. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players ice / nature (deutan) look alike on this model (dE 27.5): add a value step inside the team-colour area [fixes.json #6] _(from R6cb Team colours for colour-blind players, shot teams)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 17.3): value is close to the ground (dL +7): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 15 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 40 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 _kept_ | 22 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 _kept_ | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 _kept_ | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO _kept_ | 14 | no budget for building/keep |  |
| B2 | Draw instances at rest | PASS 100 _kept_ | 17 | <= 32 (art-keep.md 9) |  |
| B4 | Vertices | **FAIL** 0 _kept_ | 39613 (biggest: Canopy 13416, TrunkLow 6318, TrunkHigh 5103, Rampart 3609) | <= 12000 (art-keep.md 9) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 92 _kept_ | 2 (CrownLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO _kept_ | 14 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO _kept_ | 3 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 100 _kept_ | 56 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO _kept_ | 6 | no budget for building/keep |  |
| B8 | Unique materials | **FAIL** 0 _kept_ | 20 | <= 8 (art-keep.md 9) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO _kept_ | 18 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO _kept_ | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO _kept_ | 2107 of 13205 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.0 ms process, render CPU +0.77 ms, GPU +0.3 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 _kept_ | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 _kept_ | 87732 px (266 x 501 bbox; 55 m: 39718 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 86 _kept_ | mean-colour dE 17.3, 2% of the body melts (within dE 15 of the ground); body L* 62.9 C 27.4 vs ground L* 55.7 C 40.2, hue gap 15 deg; top third (world height) dE 32.0, L* 76.6; per-pixel dE 43.1, outline 21.4 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 _kept_ | dE 37.2, 11% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 91 _kept_ | worst heath: dE 16.1 (heath dE 16.1, old_wood dE 37.2, riverbank dE 22.4, snow dE 35.6, ash dE 48.7, sand dE 28.2, marsh dE 52.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 _kept_ | 66% of body pixels change between kingdom colours (min pair 65%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 91 _kept_ | worst nature colour: dE 17.2 (fire 49.1, shadow 65.0, ice 36.7, nature 17.2) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 35 _kept_ | worst pair ice / nature (deutan): dE 27.5 on the team-colour area (normal vision 34.1; 66146 px); deutan: ice / nature dE 27.5; protan: ice / nature dE 30.5; worst vs ground: fire colour (deutan) dE 4.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | PASS 90 _kept_ | worst dL +0 (point 1 dL +3, point 2 dL +63, point 3 dL +48, point 4 dL +48, point 5 dL +59, point 6 dL +60, point 7 dL +12, point 8 dL +8, point 9 dL +11, point 10 dL +16, point 11 dL +13, point 12 dL +16, point 13 dL +12, point 14 dL +23, point 15 dL +36, point 16 dL +49, point 17 dL +34, point 18 dL +11, point 19 dL +13, point 20 dL +27, point 21 dL +37, point 22 dL +44, point 23 dL +6, point 24 dL +40, point 25 dL +43, point 26 dL +64, point 27 dL +37, point 28 dL +16, point 29 dL +42, point 30 dL +49, point 31 dL +42, point 32 dL +5, soft 1 dL +0 (counts), soft 2 dL +56 (counts), soft 3 dL +29 (counts), soft 4 dL +31 (counts), soft 5 dL +0 (counts), soft 6 dL +10 (counts), soft 7 dL +48 (counts), soft 8 dL +26 (counts), soft 9 dL +14 (counts), soft 10 dL +45 (counts), soft 11 dL -9, soft 12 dL +9 (counts), soft 13 dL +41 (counts), soft 14 dL +14 (counts), soft 15 dL +9 (counts), soft 16 dL +36 (counts), soft 17 dL +0, soft 18 dL +3 (counts), soft 19 dL +55 (counts), soft 20 dL +20 (counts), soft 21 dL +6 (counts), soft 22 dL +7 (counts), soft 23 dL +6 (counts), soft 24 dL -25, soft 25 dL +49 (counts), soft 26 dL -14, soft 27 dL +20 (counts), soft 28 dL +32 (counts), soft 29 dL -7, soft 30 dL +32 (counts), soft 31 dL +8 (counts); ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 _kept_ | 41 point(s) above the bloom level 1.2 (median of 32/41/44): Bloom x8, Pod x6, Rampart x2, BannersSide x17, BannersGate x6, CanopyLost x2; soft glows under the bloom (v1 count, luma > 0.4): 45 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Bloom x8, Pod x6, Rampart x2, BannersSide x17, BannersGate x6, CanopyLost x2 |
| R2 | Distinct from references (black masks) | PASS 88 _kept_ | max IoU 0.64 (magpie_den 0.64, market_nature 0.57, nature_hall 0.56, watchtower 0.41, nature_hollow 0.31, nature_spire 0.16) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 _kept_ | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 _kept_ | outline complexity 5.77 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 _kept_ | top third L* 76.6, bottom third L* 39.7 (+36, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 _kept_ | inner detail 5.6 at 25 m, 6.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 _kept_ | 16 of 32 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 87 _kept_ | on the autumn floor: dE 36.0, 8% melts; body L* 61.8 C 30.8 vs floor L* 45.4 C 38.4; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 _kept_ | front-view asymmetry 0.34 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- anim: [anim.jpg](anim.jpg)
- close: [close.jpg](close.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- lineup: [lineup.jpg](lineup.jpg)
- silhouette: [silhouette.png](silhouette.png)
- turns: [turns.jpg](turns.jpg)
- z25: [z25.jpg](z25.jpg)
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- contact_focus: [contact_focus.png](contact_focus.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

