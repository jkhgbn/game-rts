# Art Lab scorecard: market_nature

Scene `res://art/buildings/market/nature/market_nature.tscn` · kind **building** / tier **hall** · kingdom nature · ground meadow · 2026-10-15 11:43:13 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.8)

0 FAIL · 1 WARN · 20 PASS · 18 info · 0 skipped · 50 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 10 -> 4 (want 2-4): NaturePainted sap_energy 1.35 -> 0.23 on PlinthBase, Roof, PanParts, BeamParts (dim under the bloom level: 4 point(s), peak 4.33 x the level); Heart energy 2.5 -> 0.43 on Lantern, PanParts (dim under the bloom level: 2 point(s), peak 4.39 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.81): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 22.4): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
4. **Contrast on the other grounds** (PASS): On riverbank the body drops to dE 13.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from nature_stables (IoU 0.63): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 22.3): the top third (what reads from pitch 55) is close to the ground (dE 8.6): lighten helmets / shoulders / back; the body sits in the ground's hue (gap 6 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 11 material(s), 5 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 14 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 16 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 87 | 11457 (biggest: Stall 5445, Mast 1643, GroundDressing 1282, BeamParts 986) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 2 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 17 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 21 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1611 of 10392 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-6.2 ms process, render CPU +0.31 ms, GPU +0.94 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.5 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 27776 px (200 x 246 bbox; 55 m: 14191 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 22.3, 3% of the body melts (within dE 15 of the ground); body L* 46.5 C 34.6 vs ground L* 61.3 C 50.6, hue gap 6 deg; top third (world height) dE 8.6, L* 67.5; per-pixel dE 39.0, outline 23.2 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 22.3, 13% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 86 | worst riverbank: dE 13.2 (heath dE 15.0, old_wood dE 22.3, riverbank dE 13.2, snow dE 52.3, ash dE 42.3, sand dE 36.7, marsh dE 42.1) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 43% of body pixels change between kingdom colours (min pair 42%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 22.3 (fire 52.1, shadow 66.1, ice 45.2, nature 22.3) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 11.6 on the team-colour area (normal vision 78.8; 12371 px); deutan: fire / nature dE 11.6; protan: fire / nature dE 25.9; worst vs ground: nature colour (deutan) dE 17.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +1 (point 1 dL +65, point 2 dL +51, point 3 dL +70, point 4 dL +27, point 5 dL +31, point 6 dL +22, point 7 dL +21, point 8 dL +26, point 9 dL +21, soft 1 dL +66 (counts), soft 2 dL +51 (counts), soft 3 dL +48 (counts), soft 4 dL +42 (counts), soft 5 dL +25 (counts), soft 6 dL +23 (counts), soft 7 dL +38 (counts), soft 8 dL -3, soft 9 dL +1 (counts), soft 10 dL +19 (counts), soft 11 dL +13 (counts), soft 12 dL -6, soft 13 dL +19 (counts); ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 10 point(s) above the bloom level 1.2 (median of 9/10/10): SapMotes, Lantern, Roof x4, BannerB, PanParts x2, BeamParts, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 18 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): SapMotes, Lantern, Roof x4, BannerB, PanParts x2, BeamParts |
| R2 | Distinct from references (black masks) | PASS 88 | max IoU 0.63 (nature_stables 0.63, magpie_den 0.55, nature_hollow 0.48, nature_hall 0.45, watchtower 0.33, nature_spire 0.22) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 76 | 331 shapes over 9 body parts (36.8 per part: Body 139, Canopy 34, LanternPivot0 8, LanternPivot1 8, Tree 61, Beam 10, PanGold 12, PanSeed 9, (root) 50); 56% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.813 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 95% of the 12000 verts budget used (11453) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 17 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 6.0 at the close-up (54228 px), 6.99 at 25 m; close-up outline complexity 10.02 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.78 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 67.5, bottom third L* 39.0 (+28, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.2 at 25 m, 9.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 67 | 3 of 9 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 38 | on the autumn floor: dE 22.4, 12% melts; body L* 45.0 C 34.9 vs floor L* 48.5 C 41.0 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.23 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Stall 5445 v / 3 s; Body/Tree/Mast 1643 v / 2 s; GroundDressing 1282 v / 3 s; Body/Tree/Beam/BeamParts 986 v / 2 s; Body/Tree/PanGold/PanParts 702 v / 1 s; Body/Canopy/Roof 368 v / 2 s; Body/Tree/PanSeed/PanParts 365 v / 2 s; Body/Canopy/LanternPivot0/Lantern 158 v / 2 s
- 7 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: Glow points 10 -> 4 (want 2-4): NaturePainted sap_energy 1.35 -> 0.23 on PlinthBase, Roof, PanParts, BeamParts (dim under the bloom level: 4 point(s), peak 4.33)
