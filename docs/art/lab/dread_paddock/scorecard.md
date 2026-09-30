# Art Lab scorecard: dread_paddock

Scene `res://art/buildings/lair/shadow/dread_paddock.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-09-30 15:01:15 · lab v3.1

## Result: **WARN** · quality **88 / 100** (88.4) (previous run 88, +0)

0 FAIL · 2 WARN · 19 PASS · 18 info · 0 skipped · 42 s

## Before / after (vs the run of 2026-09-30 14:59:52 in `docs/art/lab/dread_paddock`: quality 88 -> 88, +0)
### What got worse (0)
Nothing got worse.

Changed pixels per shot: z40 0.8 %, z55 0.6 %, z25 0.9 %, close 0.1 %, turns 0.7 %, anim 0.7 %, silhouette 0.0 %, lineup 0.2 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 6 -> 3 (want 2-4): ShaderMaterial#-33153 crack_strength 1.0 -> 0.18 on Portcullis, StallRoof, SpireLCrown, Stalls (dim under the bloom level: 3 point(s), peak 4.24 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +0): darken around them or raise the energy [fixes.json #2] _(from R5c Glow points stand out (1 m surround), shot glow)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.51): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from market_shadow (IoU 0.71): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 56 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 9 material(s), 12 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 24 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 93 | 27 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 85 | 11892 (biggest: Fence 2445, PropsMesh 1708, Stalls 1629, GateStack 1585) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 13 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 26 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 10 | no budget for building/hall |  |
| B8 | Unique materials | PASS 88 | 8 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 32 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 30 surfaces over 24 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1650 of 9784 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0052 ms process per instance (8 animated at 40 m: +0.04 ms process, render CPU +0.24 ms, GPU +0.13 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 37453 px (238 x 318 bbox; 55 m: 18916 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 84.6, 0% of the body melts (within dE 15 of the ground); body L* 30.9 C 28.9 vs ground L* 61.5 C 50.4, hue gap 168 deg; top third (world height) dE 100.5, L* 42.4; per-pixel dE 88.5, outline 58.4 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 35.9, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 26.0 (heath dE 57.7, old_wood dE 49.0, riverbank dE 59.4, snow dE 66.8, ash dE 26.0, sand dE 74.9, marsh dE 35.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 99 | 24% of body pixels change between kingdom colours (min pair 23%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.0 (fire 70.2, shadow 84.3, ice 70.0, nature 57.0) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 12.0 on the team-colour area (normal vision 87.1; 9231 px); deutan: fire / nature dE 12.0; protan: fire / nature dE 25.2; worst vs ground: fire colour (deutan) dE 47.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 57 | worst dL +0 (point 1 dL +39, point 2 dL +39, point 3 dL +20, point 4 dL +15, point 5 dL +41, point 6 dL +0; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 6 point(s) above the bloom level 1.2 (median of 6/8/6): Portcullis, StallRoof, Halo2, SpireLCrown, TowerBanner, ScorchDecal; soft glows under the bloom (v1 count, luma > 0.4): 8 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Portcullis, StallRoof, Halo2, SpireLCrown, TowerBanner, ScorchDecal |
| R2 | Distinct from references (black masks) | PASS 83 | max IoU 0.71 (market_shadow 0.71, shadow_stables 0.62, magpie_den 0.59, shadow_hall 0.53, watchtower 0.36, dusk_keep 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 415 shapes over 9 body parts (46.1 per part: Body 216, Gatehouse 64, PortcullisPivot 14, SpireL 14, StallRoofFrame 23, PlinthCallCircle 25, YardProps 31, Nightmares 24, (root) 4); 97% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.51 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 97% of the 12000 verts budget used (11668) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.69 at the close-up (75806 px), 4.98 at 25 m; close-up outline complexity 5.93 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.39 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 42.4, bottom third L* 26.4 (+15, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 5.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 33 | 1 of 6 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 58.1, 0% melts; body L* 29.1 C 24.9 vs floor L* 48.6 C 41.4 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.25 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Fence 2445 v / 1 s; Body/YardProps/PropsMesh 1708 v / 1 s; Body/Stalls 1629 v / 2 s; Body/Gatehouse/GateStack 1585 v / 2 s; Body/PlinthBase 1088 v / 1 s; Body/PlinthCallCircle/RuneRing 600 v / 1 s; Body/Torches 544 v / 2 s; Body/StallRoofFrame/StallRoof 529 v / 1 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: Glow points 6 -> 3 (want 2-4): ShaderMaterial#-33153 crack_strength 1.0 -> 0.18 on Portcullis, StallRoof, SpireLCrown, Stalls (dim under the bloom level: 3 poin)
