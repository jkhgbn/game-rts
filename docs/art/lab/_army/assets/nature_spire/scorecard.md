# Art Lab scorecard: nature_spire

Scene `res://art/buildings/nature_spire.tscn` · kind **building** / tier **small** · kingdom nature · ground meadow · 2026-09-27 10:10:02 · lab v2.0

## Result: **WARN** · quality **92 / 100**

0 FAIL · 2 WARN · 18 PASS · 11 info · 0 skipped · 23 s

## Improve next
1. **Unique materials** (WARN): B8 16 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-16893` -> `StandardMaterial3D#-73353` (dE 0.0), `StandardMaterial3D#-73353` -> `StandardMaterial3D#-79643` (dE 0.0), `Thorn` -> `DarkStone` (dE 12.2), `Wood` -> `Bark` (dE 15.7), `Bark` -> `DarkStone` (dE 17.1), `Stone` -> `DarkStone` (dE 24.8), `StandardMaterial3D#-6890` -> `StandardMaterial3D#-79643` (dE 78.1), `Petal` -> `LeafCard` (dE 111.7) [fixes.json #1] _(from B8 Unique materials)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 18 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #2] _(from B9 Materials built per instance)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.1: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Silhouette area at 40 m** (PASS): Grow the read at 40 m (now 6416 px): push the key shape (weapon, horns, crest, back mass) 15-25 % bigger _(from R1 Silhouette area at 40 m, shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 22.5): the top third (what reads from pitch 55) is close to the ground (dE 12.9): lighten helmets / shoulders / back; the body sits in the ground's hue (gap 7 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 18 material(s), 2 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 9 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 | 2278 (biggest: Trunk 1072, Plinth 430, Orb 345, GroundDressing 234) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO | 5 | no budget for building/small |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 10 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 4 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 35 | 16 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 17 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 166 of 2142 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.29 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 87 | 6416 px (85 x 144 bbox; 55 m: 3270 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 22.5, 10% of the body melts (within dE 15 of the ground); body L* 50.3 C 31.8 vs ground L* 62.4 C 50.0, hue gap 7 deg; top third (world height) dE 12.9, L* 69.5; per-pixel dE 38.7, outline 20.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 99 | dE 21.6, 22% melts (old_wood is where nature units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 82 | worst heath: dE 11.1 (heath dE 11.1, old_wood dE 21.6, riverbank dE 17.3, snow dE 44.0, ash dE 39.2, sand dE 30.4, marsh dE 38.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 43% of body pixels change between kingdom colours (min pair 37%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 98 | worst nature colour: dE 21.5 (fire 40.6, shadow 53.0, ice 37.3, nature 21.5) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 88 | worst pair fire / nature (deutan): dE 19.9 on the team-colour area (normal vision 50.1; 3381 px); deutan: fire / nature dE 19.9; protan: fire / nature dE 24.0; worst vs ground: nature colour (deutan) dE 16.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +26 (point 1 dL +26, point 2 dL +59, soft 1 dL +52 (counts); ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 4 point(s) above the bloom level 1.2 (median of 2/5/4): Pollen, Plinth x3; soft glows under the bloom (v1 count, luma > 0.4): 2 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.19 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 69.5, bottom third L* 36.4 (+33, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.5 at 25 m, 11.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Trunk 1072 v / 3 s; Body/Plinth 430 v / 3 s; Body/Orb 345 v / 1 s; GroundDressing 234 v / 2 s; Body/Crown 125 v / 3 s; Body/Pennant 44 v / 1 s; Body/CrownLost 20 v / 1 s; AuraRing 4 v / 1 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- 16 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 2 in fixes.json (top: B8 16 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-16893` -> `StandardMaterial3D#-73353` (dE 0.0), `StandardMaterial3D#-73353` ->)
