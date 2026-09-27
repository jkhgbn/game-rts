# Art Lab scorecard: fire_tower

Scene `res://art/buildings/fire_tower.tscn` · kind **building** / tier **small** · kingdom fire · ground meadow · 2026-09-27 10:46:35 · lab v2.0

## Result: **WARN** · quality **89 / 100** (previous run 89, +0)

0 FAIL · 2 WARN · 20 PASS · 13 info · 0 skipped · 9 s

**Focus run**: focus=B5,R5,R6,B8: 5 check(s) re-measured, 30 kept from the run of 2026-09-27 10:44:28 (rows marked _kept_ were not re-measured).

## Before / after (vs the run of 2026-09-27 10:44:28 in `docs/art/lab/fire_tower`: quality 89 -> 89, +0)
### What got worse (0)
Nothing got worse.

### What got better (1)
R6 Team-colour visibility at 40 m: PASS 88 -> PASS 93 (+5)

### Score delta per check (1 changed, 34 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R6 | Team-colour visibility at 40 m | PASS 88 | PASS 93 | +4.9 |

Changed pixels per shot: z40 0.3 %, z55 0.5 %, z25 0.4 %, close 4.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Unique materials** (WARN): B8 12 -> 6 materials: use one material for look-alike pairs: `StandardMaterial3D#-51813` -> `StandardMaterial3D#-58204` (dE 0.0), `StandardMaterial3D#-22742` -> `StandardMaterial3D#-58204` (dE 0.0), `ShaderMaterial#-70990` -> `ShaderMaterial#-98827` (dE 19.8), `ShaderMaterial#-44393` -> `ShaderMaterial#-21610` (dE 37.8), `ShaderMaterial#-21610` -> `ShaderMaterial#-98827` (dE 58.5), `StandardMaterial3D#-88613` -> `StandardMaterial3D#-58204` (dE 83.1) [fixes.json #1] _(from B8 Unique materials)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 13 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #2] _(from B9 Materials built per instance)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.75): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.09): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from ember_crucible (IoU 0.74): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Silhouette area at 40 m** (PASS): Grow the read at 40 m (now 5281 px): push the key shape (weapon, horns, crest, back mass) 15-25 % bigger _(from R1 Silhouette area at 40 m, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 21 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 _kept_ | 13 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 _kept_ | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 _kept_ | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO _kept_ | 8 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 _kept_ | 9 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 _kept_ | 847 (biggest: Shaft 318, Rubble 168, Orb 104, Cup 94) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO _kept_ | 5 | no budget for building/small |  |
| B6l | Looping particle systems | INFO _kept_ | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 _kept_ | 10 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO _kept_ | 5 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 35 | 12 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO _kept_ | 15 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO _kept_ | 12 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO _kept_ | 105 of 729 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 _kept_ | 0.0 ms process per instance (8 animated at 40 m: +-0.17 ms process, render CPU +0.34 ms, GPU +0.02 ms) | <= 0.05 ms per instance (lab default (towers, walls, posts): half a keep) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 _kept_ | lowest point -0.21 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 82 _kept_ | 5281 px (76 x 127 bbox; 55 m: 2690 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 _kept_ | mean-colour dE 47.7, 1% of the body melts (within dE 15 of the ground); body L* 39.8 C 22.6 vs ground L* 62.4 C 49.3, hue gap n/a (body C* <= 25); top third (world height) dE 47.2, L* 72.4; per-pixel dE 63.9, outline 43.9 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 _kept_ | dE 24.6, 17% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 _kept_ | worst heath: dE 20.9 (heath dE 20.9, old_wood dE 24.1, riverbank dE 36.4, snow dE 54.5, ash dE 24.6, sand dE 44.3, marsh dE 24.0) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 93 | 19% of body pixels change between kingdom colours (min pair 9%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 _kept_ | worst fire colour: dE 47.6 (fire 47.6, shadow 49.9, ice 49.3, nature 48.4) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 76 _kept_ | worst pair shadow / nature (deutan): dE 8.0 on the team-colour area (normal vision 10.8; 1148 px); deutan: shadow / nature dE 8.0; protan: shadow / nature dE 9.1; worst vs ground: fire colour (deutan) dE 29.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 96 _kept_ | worst dL +25 (point 1 dL +25, point 2 dL +46, point 3 dL +57; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/4/3): OrbEmbers, Cup x2, Plinth; soft glows under the bloom (v1 count, luma > 0.4): 5 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 81 _kept_ | max IoU 0.74 (ember_crucible 0.74, trade_post 0.11, market_fire 0.11, fire_hall 0.08, dragon_roost 0.08, essence_well 0.07) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 _kept_ | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 35 _kept_ | outline complexity 1.75 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 _kept_ | top third L* 72.4, bottom third L* 14.0 (+58, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 _kept_ | inner detail 3.5 at 25 m, 4.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 _kept_ | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 36 _kept_ | on the autumn floor: dE 21.4, 2% melts; body L* 39.6 C 26.1 vs floor L* 50.0 C 41.8 (inside the floor band); fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 39 _kept_ | front-view asymmetry 0.09 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Shaft 318 v / 4 s; Rubble 168 v / 1 s x7; Body/Orb 104 v / 1 s; Body/Cup 94 v / 2 s; Body/Claws 84 v / 1 s x4; Body/Plinth 71 v / 1 s; OrbHalo 4 v / 1 s; ContactDecal 4 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 12 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B8 12 -> 6 materials: use one material for look-alike pairs: `StandardMaterial3D#-51813` -> `StandardMaterial3D#-58204` (dE 0.0), `StandardMaterial3D#-22742` ->)
