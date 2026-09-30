# Art Lab scorecard: ice_wall

Scene `res://art/buildings/ice_wall.tscn` · kind **building** / tier **small** · kingdom ice · ground meadow · 2026-09-30 14:50:43 · lab v3.1

## Result: **WARN** · quality **81 / 100** (81.1) (previous run 81, +0)

0 FAIL · 2 WARN · 19 PASS · 17 info · 0 skipped · 21 s

## Before / after (vs the run of 2026-09-30 13:22:48 in `docs/art/lab/ice_wall`: quality 81 -> 81, +0)
### What got worse (0)
Nothing got worse.

### What got better (1)
C4 Inner detail (close-up / 25 m): INFO 96 -> INFO 98 (+2)

### Score delta per check (3 changed, 37 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C4 | Inner detail (close-up / 25 m) | INFO 96 | INFO 98 | +2.2 |
| P4 | Detail density 25 m / 40 m | INFO 91 | INFO 93 | +2.4 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 91 | +0.6 (noisy) |

Changed pixels per shot: z40 0.2 %, z55 0.1 %, z25 0.3 %, close 0.3 %, turns 0.5 %, anim 0.9 %, silhouette 0.0 %, lineup 3.2 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Silhouette area at 40 m** (WARN): R1 3677 -> ~5749 px: grow the 40 m read x1.25 (area goes with the square: scale the key masses / body 25 %) [fixes.json #1] _(from R1 Silhouette area at 40 m, shot z40)_
2. **Glow points at 40 m** (WARN): Glow points 1 -> 2 (want 2-4): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.69): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 6 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.26): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 12 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 5 material(s), 1 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 3 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 3 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 | 1900 (biggest: Wall 1432, Plinth 464, ContactDecal 4) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO | 3 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 1 | no budget for building/small |  |
| B8 | Unique materials | PASS 95 | 5 | <= 6 soft (lab default (towers, walls, posts): half a keep) |  |
| B1a | Authored build parts (before the merge) | INFO | 10 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 3 surfaces over 3 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 368 of 1326 triangles (27%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +-0.03 ms process, render CPU +0.03 ms, GPU +0.02 ms) | <= 0.05 ms per instance (lab default (towers, walls, posts): half a keep) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point 0.0 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | **WARN** 42 | 3677 px (55 x 97 bbox; 55 m: 1899 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 | Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 55.7, 0% of the body melts (within dE 15 of the ground); body L* 69.6 C 9.0 vs ground L* 62.5 C 48.7, hue gap n/a (body C* <= 25); top third (world height) dE 58.4, L* 83.8; per-pixel dE 59.5, outline 33.9 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 24.0, 32% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 24.0 (heath dE 36.9, old_wood dE 50.4, riverbank dE 49.6, snow dE 24.0, ash dE 47.8, sand dE 42.8, marsh dE 57.3) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 96 | 21% of body pixels change between kingdom colours (min pair 20%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 42.3 (fire 50.1, shadow 64.4, ice 53.6, nature 42.3) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 11.8 on the team-colour area (normal vision 78.2; 807 px); deutan: fire / nature dE 11.8; protan: fire / nature dE 22.5; worst vs ground: fire colour (deutan) dE 36.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +28 (point 1 dL +28; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Plinth; soft glows under the bloom (v1 count, luma > 0.4): 7 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 7 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.46 (ice_spire 0.46, essence_well 0.26, ice_lodge 0.24, trade_post 0.09, ice_stables 0.09, market_ice 0.09) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 0 | 64 shapes over 1 body parts (64.0 per part: Body 64); 85% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.694 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 66 | 31% of the 6000 verts budget used (1896) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 37 | 9 colour steps (L*a*b* bins >= 2 % of the body), 6 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 98 | inner edges per outline px: 4.3 at the close-up (118845 px), 2.44 at 25 m; close-up outline complexity 1.94 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 0 | outline complexity 1.26 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 83.8, bottom third L* 58.3 (+25, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 93 | inner detail 2.7 at 25 m, 4.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 47.0, 0% melts; body L* 66.6 C 2.2 vs floor L* 50.7 C 42.1; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 70 | front-view asymmetry 0.15 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Body/Wall 1432 v / 1 s; Body/Plinth 464 v / 1 s; ContactDecal 4 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R1 3677 -> ~5749 px: grow the 40 m read x1.25 (area goes with the square: scale the key masses / body 25 %))
