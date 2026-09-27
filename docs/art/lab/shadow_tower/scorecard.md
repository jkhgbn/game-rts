# Art Lab scorecard: shadow_tower

Scene `res://art/buildings/shadow_tower.tscn` · kind **building** / tier **small** · kingdom shadow · ground meadow · 2026-09-27 10:47:04 · lab v2.0

## Result: **WARN** · quality **92 / 100** (previous run 92, +0)

0 FAIL · 3 WARN · 19 PASS · 13 info · 0 skipped · 9 s

**Focus run**: focus=B5,R5,R6,R1: 5 check(s) re-measured, 30 kept from the run of 2026-09-27 10:45:11 (rows marked _kept_ were not re-measured).

## Before / after (vs the run of 2026-09-27 10:45:11 in `docs/art/lab/shadow_tower`: quality 92 -> 92, +0)
### What got worse (0)
Nothing got worse.

Changed pixels per shot: z40 2.4 %, z55 1.8 %, z25 2.4 %, close 5.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Silhouette area at 40 m** (WARN): R1 4920 -> ~5750 px: grow the 40 m read x1.08 (area goes with the square: scale the key masses / body 8 %) [fixes.json #1] _(from R1 Silhouette area at 40 m, shot z40)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 14 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
3. **Unique materials** (WARN): B8 13 -> 7 materials: use one material for look-alike pairs: `StandardMaterial3D#-3752` -> `StandardMaterial3D#-10143` (dE 0.0), `StandardMaterial3D#-67661` -> `StandardMaterial3D#-10143` (dE 0.0), `ShaderMaterial#-31797` -> `ShaderMaterial#-59634` (dE 12.5), `ShaderMaterial#-5200` -> `ShaderMaterial#-82417` (dE 46.7), `ShaderMaterial#-82417` -> `ShaderMaterial#-59634` (dE 50.3), `StandardMaterial3D#-72203` -> `StandardMaterial3D#-10143` (dE 110.3) [fixes.json #2] _(from B8 Unique materials)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 _kept_ | 14 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 _kept_ | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 _kept_ | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO _kept_ | 10 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 _kept_ | 11 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 _kept_ | 995 (biggest: Shaft 222, RuneRing 175, Rubble 168, RuneStones 144) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO _kept_ | 5 | no budget for building/small |  |
| B6l | Looping particle systems | INFO _kept_ | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 _kept_ | 10 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO _kept_ | 5 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 35 _kept_ | 13 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO _kept_ | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO _kept_ | 14 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO _kept_ | 164 of 976 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 _kept_ | 0.0 ms process per instance (8 animated at 40 m: +-9.32 ms process, render CPU +0.44 ms, GPU +0.12 ms) | <= 0.05 ms per instance (lab default (towers, walls, posts): half a keep) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 _kept_ | lowest point -0.21 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | **WARN** 47 | 4920 px (72 x 129 bbox; 55 m: 2524 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 | Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical |
| R3 | Contrast vs ground (meadow) | PASS 100 _kept_ | mean-colour dE 83.6, 0% of the body melts (within dE 15 of the ground); body L* 28.6 C 27.6 vs ground L* 62.2 C 49.3, hue gap 168 deg; top third (world height) dE 99.6, L* 63.3; per-pixel dE 90.5, outline 58.7 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 _kept_ | dE 34.4, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 _kept_ | worst ash: dE 24.6 (heath dE 57.5, old_wood dE 49.6, riverbank dE 60.8, snow dE 68.3, ash dE 24.6, sand dE 75.8, marsh dE 34.4) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 27% of body pixels change between kingdom colours (min pair 25%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 _kept_ | worst nature colour: dE 58.1 (fire 64.5, shadow 78.2, ice 65.1, nature 58.1) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 _kept_ | worst pair fire / nature (deutan): dE 10.5 on the team-colour area (normal vision 33.5; 1991 px); deutan: fire / nature dE 10.5; protan: fire / nature dE 14.2; worst vs ground: fire colour (deutan) dE 50.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 _kept_ | worst dL +20 (point 1 dL +20, point 2 dL +48; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 4/4/3): OrbMotes, RuneStones x3; soft glows under the bloom (v1 count, luma > 0.4): 4 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R2 | Distinct from references (black masks) | PASS 100 _kept_ | max IoU 0.13 (greywater_lodge 0.13, market_shadow 0.11, trade_post 0.1, dread_paddock 0.09, shadow_hall 0.07, dusk_keep 0.06) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 _kept_ | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 _kept_ | outline complexity 2.9 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 _kept_ | top third L* 63.3, bottom third L* 10.0 (+53, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 _kept_ | inner detail 4.2 at 25 m, 6.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 _kept_ | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 _kept_ | on the autumn floor: dE 60.0, 0% melts; body L* 29.3 C 24.0 vs floor L* 50.0 C 41.7 (inside the floor band); shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 86 _kept_ | front-view asymmetry 0.17 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- anim: [anim.jpg](anim.jpg)
- close: [close.jpg](close.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)
- lineup: [lineup.jpg](lineup.jpg)
- silhouette: [silhouette.png](silhouette.png)
- turns: [turns.jpg](turns.jpg)
- z25: [z25.jpg](z25.jpg)
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_focus: [contact_focus.png](contact_focus.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Shaft 222 v / 4 s; Body/RuneRing 175 v / 1 s; Rubble 168 v / 1 s x7; Body/RuneStones 144 v / 2 s; Body/Orb 104 v / 1 s; Body/Plinth 74 v / 1 s; Body/Fins 63 v / 1 s x3; Body/Collar 37 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 13 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R1 4920 -> ~5750 px: grow the 40 m read x1.08 (area goes with the square: scale the key masses / body 8 %))
