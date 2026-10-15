# Art Lab scorecard: fire_tower

Scene `res://art/buildings/fire_tower.tscn` · kind **building** / tier **small** · kingdom fire · ground meadow · 2026-10-15 11:35:00 · lab v3.1

## Result: **PASS** · quality **90 / 100** (90.0) (previous run 89, +1)

0 FAIL · 0 WARN · 21 PASS · 18 info · 0 skipped · 24 s

## Before / after (vs the run of 2026-10-15 11:26:12 in `docs/art/lab/gb_fire/after/fire_tower`: quality 89 -> 90, +1)
### What got worse (2)
1. **R2 Distinct from references (black masks): PASS 100 -> PASS 85 (-15)**. Now: max IoU 0.68 (ember_crucible 0.68, essence_well 0.33, greywater_lodge 0.14, fire_stables 0.11, market_fire 0.11, dragon_roost 0.08). Was: max IoU 0.14 (greywater_lodge 0.14, trade_post 0.11, fire_stables 0.11, market_fire 0.11, dragon_roost 0.08, fire_hall 0
2. **P1 Silhouette hook: INFO 63 -> INFO 60 (-3)**. Now: outline complexity 2.08. Was: outline complexity 2.12

### What got better (4)
B8 Unique materials: WARN 48 -> PASS 88 (+40); P5 Glow placement: INFO 67 -> INFO 100 (+33); R4 Contrast on the other grounds: PASS 95 -> PASS 97 (+2); S1 Style bible: golden autumn (style-autumn.md 3): INFO 25 -> INFO 31 (+5)

### Score delta per check (9 changed, 33 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | WARN 48 | PASS 88 | +40.0 |
| R1 | Silhouette area at 40 m | PASS 85 | PASS 83 | -1.7 |
| R3 | Contrast vs ground (meadow) | PASS 99 | PASS 100 | +1.3 |
| R4 | Contrast on the other grounds | PASS 95 | PASS 97 | +2.4 |
| R6 | Team-colour visibility at 40 m | PASS 85 | PASS 86 | +0.5 |
| P1 | Silhouette hook | INFO 63 | INFO 60 | -3.3 |
| P5 | Glow placement | INFO 67 | INFO 100 | +33.3 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 25 | INFO 31 | +5.4 |
| R2 | Distinct from references (black masks) | PASS 100 | PASS 85 | -15.2 |

Changed pixels per shot: z40 0.9 %, z55 1.0 %, z25 0.5 %, close 50.8 %, turns 47.4 %, anim 42.1 %, silhouette 14.5 %, lineup 48.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.69): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.09): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.08): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 19.5): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
5. **Silhouette area at 40 m** (PASS): Grow the read at 40 m (now 5559 px): push the key shape (weapon, horns, crest, back mass) 15-25 % bigger _(from R1 Silhouette area at 40 m, shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from ember_crucible (IoU 0.68): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 21 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 7 material(s), 1 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 8 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 | 3027 (biggest: Shaft 1892, Cup 457, Plinth 314, Rubble 168) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO | 5 | no budget for building/small |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 10 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/small |  |
| B8 | Unique materials | PASS 88 | 6 | <= 6 soft (lab default (towers, walls, posts): half a keep) |  |
| B1a | Authored build parts (before the merge) | INFO | 15 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 9 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 349 of 2455 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.18 ms process, render CPU +0.28 ms, GPU +0.04 ms) | <= 0.05 ms per instance (lab default (towers, walls, posts): half a keep) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.21 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 83 | 5559 px (76 x 128 bbox; 55 m: 2834 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 46.3, 1% of the body melts (within dE 15 of the ground); body L* 42.6 C 24.0 vs ground L* 62.4 C 49.5, hue gap n/a (body C* <= 25); top third (world height) dE 48.8, L* 70.8; per-pixel dE 61.5, outline 43.8 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 27.3, 20% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 97 | worst heath: dE 19.5 (heath dE 19.5, old_wood dE 26.0, riverbank dE 37.1, snow dE 52.4, ash dE 27.3, sand dE 40.8, marsh dE 27.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 86 | 13% of body pixels change between kingdom colours (min pair 6%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 46.7 (fire 47.0, shadow 49.2, ice 48.2, nature 46.7) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair shadow / nature (deutan): dE 8.9 on the team-colour area (normal vision 12.7; 1144 px); deutan: shadow / nature dE 8.9; protan: shadow / nature dE 10.5; worst vs ground: fire colour (deutan) dE 26.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 96 | worst dL +22 (point 1 dL +22, point 2 dL +42, point 3 dL +48; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 3/4/4): Orb, Plinth x3; soft glows under the bloom (v1 count, luma > 0.4): 3 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.68 (ember_crucible 0.68, essence_well 0.33, greywater_lodge 0.14, fire_stables 0.11, market_fire 0.11, dragon_roost 0.08) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 88 shapes over 2 body parts (44.0 per part: Body 87, (root) 1); 54% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.691 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 46% of the 6000 verts budget used (2771) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.6 at the close-up (106806 px), 3.95 at 25 m; close-up outline complexity 4.01 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 60 | outline complexity 2.08 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 70.8, bottom third L* 18.9 (+51, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.9 at 25 m, 6.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 31 | on the autumn floor: dE 19.5, 0% melts; body L* 41.2 C 28.1 vs floor L* 50.0 C 41.7 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 37 | front-view asymmetry 0.09 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Shaft 1892 v / 2 s; Body/Cup 457 v / 1 s; Body/Plinth 314 v / 1 s; Rubble 168 v / 1 s x7; Body/Orb 104 v / 1 s; Body/Claws 84 v / 1 s x4; OrbHalo 4 v / 1 s; ContactDecal 4 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
