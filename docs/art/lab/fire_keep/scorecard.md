# Art Lab scorecard: fire_keep

Scene `res://art/buildings/fire_keep.tscn` · kind **building** / tier **keep** · kingdom fire · ground meadow · 2026-10-15 18:33:36 · lab v3.1

## Result: **PASS** · quality **92 / 100** (92.2) (previous run 95, -3)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 54 s

## Before / after (vs the run of 2026-09-27 07:47:08 in `docs/art/lab/fire_keep`: quality 95 -> 92, -3)
### What got worse (1)
1. **R6 Team-colour visibility at 40 m: PASS 100 -> PASS 91 (-9)**. Now: 17% of body pixels change between kingdom colours (min pair 17%). Was: 26% of body pixels change between kingdom colours (min pair 24%)

### What got better (2)
R5 Glow points at 40 m: WARN 49 -> PASS 100 (+51) (noisy check: re-run before acting); P3 Tops light, bottoms dark: INFO 65 -> INFO 83 (+18)

new C1 Shape richness (secondary shapes) (INFO); new C2 Vertex use vs budget (INFO); new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R6cb Team colours for colour-blind players (PASS); new R5c Glow points stand out (1 m surround) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new P2 Asymmetric secondary shape (INFO); new R2 Distinct from references (black masks) (PASS); new B13 Frame cost (PASS)

### Score delta per check (3 changed, 26 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6 | Team-colour visibility at 40 m | PASS 100 | PASS 91 | -8.5 |
| P3 | Tops light, bottoms dark | INFO 65 | INFO 83 | +18.3 |
| R5 | Glow points at 40 m | WARN 49 | PASS 100 | +51.4 (noisy) |

Changed pixels per shot: z40 18.1 %, z55 14.7 %, z25 17.0 %, close 48.7 %, turns 52.2 %, anim 46.8 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.6): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Distinct from references (black masks)** (PASS): Make it read apart from fire_hall (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +9 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 17% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
5. **Frame cost** (PASS): Cut the per-frame script cost (0.0367 ms per instance): write pivots only when they change, skip work at the far tiers _(from B13 Frame cost)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 52 nodes | instantiates without errors |  |
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
| B1a | Authored build parts (before the merge) | INFO | 29 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 21 surfaces over 19 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 102 of 3933 triangles (2%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 91 | 0.0367 ms process per instance (8 animated at 40 m: +0.29 ms process, render CPU +0.21 ms, GPU +0.52 ms) | <= 0.05 ms per instance (art-keep.md 9) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 86261 px (332 x 474 bbox; 55 m: 40172 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 49.4, 0% of the body melts (within dE 15 of the ground); body L* 35.1 C 27.2 vs ground L* 56.9 C 42.4, hue gap 75 deg; top third (world height) dE 32.1, L* 37.4; per-pixel dE 65.3, outline 47.9 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 25.2, 22% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst marsh: dE 23.0 (heath dE 36.5, old_wood dE 30.1, riverbank dE 37.3, snow dE 60.3, ash dE 25.2, sand dE 50.7, marsh dE 23.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 91 | 17% of body pixels change between kingdom colours (min pair 17%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 37.9 (fire 49.2, shadow 57.6, ice 46.4, nature 37.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 86 | worst pair fire / nature (deutan): dE 17.0 on the team-colour area (normal vision 85.9; 16034 px); deutan: fire / nature dE 17.0; protan: fire / nature dE 23.8; worst vs ground: fire colour (deutan) dE 26.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 96 | worst dL +24 (point 1 dL +30, point 2 dL +37, point 3 dL +72, point 4 dL +39, point 5 dL +47, point 6 dL +26, point 7 dL +24, point 8 dL +69, point 9 dL +51, point 10 dL +43; ring 29 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 12 point(s) above the bloom level 1.2 (median of 10/13/12): EmberHeart, BannersGate x2, Plinth, BannersSide x3, Braziers x3, Crystal2, Crystal3; soft glows under the bloom (v1 count, luma > 0.4): 38 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.67 (fire_hall 0.67, magpie_den 0.6, fire_stables 0.6, market_fire 0.59, dragon_roost 0.54, watchtower 0.39) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 250 shapes over 4 body parts (62.5 per part: Body 224, RuneTilt 1, Ring 6, (root) 19); 35% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.597 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 94% of the 12000 verts budget used (11393) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.9 at the close-up (106855 px), 10.36 at 25 m; close-up outline complexity 7.66 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.3 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 83 | top third L* 37.4, bottom third L* 28.3 (+9, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 6.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 5 of 10 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 63 | on the autumn floor: dE 31.6, 0% melts; body L* 35.6 C 31.4 vs floor L* 53.0 C 36.0 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 80 | front-view asymmetry 0.16 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Towers 2544 v / 1 s; Body/Walls 2199 v / 2 s; Body/Roofs 1068 v / 1 s; Body/Braziers 984 v / 2 s; Body/Spire 738 v / 1 s; Rubble 591 v / 1 s; Body/Donjon 552 v / 1 s; Body/Windows 549 v / 1 s
- 10 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
