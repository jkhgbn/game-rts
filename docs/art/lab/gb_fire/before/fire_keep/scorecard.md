# Art Lab scorecard: fire_keep

Scene `res://art/buildings/fire_keep.tscn` · kind **building** / tier **keep** · kingdom fire · ground meadow · 2026-10-15 10:56:18 · lab v3.1

## Result: **WARN** · quality **90 / 100** (89.6)

0 FAIL · 1 WARN · 20 PASS · 18 info · 0 skipped · 90 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 31 -> 4 (want 4-12): FirePainted glow colour #ff801f -> #693006 (x0.14 linear) on Plinth, Spire, Roofs, RoofLost (dim under the bloom level: 17 point(s), peak 5.33 x the level); FireGlow boost 1.4 -> 0.08 on EmberHeart, Crystal3, Crystal2, Braziers (dim under the bloom level: 10 point(s), peak 7.34 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.6): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 18.3): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from fire_hall (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +7 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 17% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

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
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-4.86 ms process, render CPU +0.31 ms, GPU +1.71 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 92717 px (332 x 533 bbox; 55 m: 42537 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 45.5, 0% of the body melts (within dE 15 of the ground); body L* 37.6 C 25.7 vs ground L* 56.3 C 41.7, hue gap 71 deg; top third (world height) dE 27.7, L* 37.6; per-pixel dE 61.0, outline 42.5 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 26.0, 26% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 23.9 (heath dE 33.4, old_wood dE 28.7, riverbank dE 34.9, snow dE 56.4, ash dE 26.0, sand dE 46.8, marsh dE 23.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 91 | 17% of body pixels change between kingdom colours (min pair 16%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 36.4 (fire 46.2, shadow 54.1, ice 44.0, nature 36.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 15.1 on the team-colour area (normal vision 76.0; 17750 px); deutan: fire / nature dE 15.1; protan: fire / nature dE 20.9; worst vs ground: fire colour (deutan) dE 24.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 96 | worst dL +0 (point 1 dL +0, point 2 dL +44, point 3 dL +72, point 4 dL +45, point 5 dL +32, point 6 dL +34, point 7 dL +55, point 8 dL +55, point 9 dL +44, point 10 dL +67, point 11 dL +69, point 12 dL +28, point 13 dL +51, point 14 dL +35, point 15 dL +25, point 16 dL +36, point 17 dL +29, point 18 dL +27, point 19 dL +55, point 20 dL +70, point 21 dL +65, point 22 dL +67, point 23 dL +38, point 24 dL +58, point 25 dL +45, point 26 dL +27, point 27 dL +60, point 28 dL +44, point 29 dL +29, point 30 dL +61, point 31 dL +37; ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 31 point(s) above the bloom level 1.2 (median of 31/34/31): EmberHeart, Plinth x2, BannersGate x5, BannersSide, Crystal3, Crystal2, Braziers x7, Spire x4, Roofs x2, RoofLost x6, RuneRing, 10 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 51 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): EmberHeart, Plinth x2, BannersGate x5, BannersSide, Crystal3, Crystal2, Braziers x7, Spire x4, Roofs x2, RoofLost x6, RuneRing |
| R2 | Distinct from references (black masks) | PASS 86 | max IoU 0.65 (fire_hall 0.65, fire_stables 0.58, magpie_den 0.58, market_fire 0.57, dragon_roost 0.53, watchtower 0.38) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 250 shapes over 4 body parts (62.5 per part: Body 224, RuneTilt 1, Ring 6, (root) 19); 38% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.604 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 94% of the 12000 verts budget used (11393) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.69 at the close-up (100667 px), 10.83 at 25 m; close-up outline complexity 9.21 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 8.28 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 74 | top third L* 37.6, bottom third L* 30.0 (+7, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.9 at 25 m, 6.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 26 of 31 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 27 | on the autumn floor: dE 18.3, 1% melts; body L* 37.5 C 29.8 vs floor L* 45.4 C 38.7 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 over the budget on the first window (0.0699 ms): re-measured 0.0 ms, kept the lower
- Fix recipes: 1 in fixes.json (top: Glow points 31 -> 4 (want 4-12): FirePainted glow colour #ff801f -> #693006 (x0.14 linear) on Plinth, Spire, Roofs, RoofLost (dim under the bloom level: 17 poin)
