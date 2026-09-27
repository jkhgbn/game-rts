# Art Lab scorecard: fire_tower

Scene `res://art/buildings/fire_tower.tscn` · kind **building** / tier **small** · kingdom fire · ground meadow · 2026-09-27 09:52:09 · lab v2.0

## Result: **FAIL** · quality **86 / 100**

1 FAIL · 4 WARN · 15 PASS · 11 info · 0 skipped · 24 s

## Improve next
1. **Real lights** (FAIL): B5 Real lights: No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4) [fixes.json #1] _(from B5 Real lights)_
2. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 13 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
3. **Unique materials** (WARN): B8 11 -> 6 materials: use one material for look-alike pairs: `StandardMaterial3D#-73353` -> `StandardMaterial3D#-79643` (dE 0.0), `StandardMaterial3D#-30717` -> `StandardMaterial3D#-79643` (dE 0.0), `ShaderMaterial#-67185` -> `ShaderMaterial#-90063` (dE 19.8), `ShaderMaterial#-35635` -> `ShaderMaterial#-13155` (dE 37.8), `ShaderMaterial#-13155` -> `ShaderMaterial#-90063` (dE 58.5) [fixes.json #2] _(from B8 Unique materials)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players shadow / ice (deutan) look alike on this model (dE 5.3): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +16): darken around them or raise the energy [fixes.json #5] _(from R5c Glow points stand out (1 m surround), shot glow)_
6. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.72): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 21 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 13 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 7 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 | 843 (biggest: Shaft 318, Rubble 168, Orb 104, Cup 94) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | **FAIL** 0 | 1 (OrbLight) | <= 0 (lab default (towers, walls, posts): half a keep) | No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4) |
| B6 | Particle systems | INFO | 5 | no budget for building/small |  |
| B6l | Looping particle systems | INFO | 1 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 10 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 5 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 35 | 11 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 14 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 11 surfaces over 7 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 105 of 727 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.21 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 82 | 5201 px (76 x 127 bbox; 55 m: 2660 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 46.5, 0% of the body melts (within dE 15 of the ground); body L* 42.5 C 23.7 vs ground L* 62.4 C 49.3, hue gap n/a (body C* <= 25); top third (world height) dE 49.8, L* 79.2; per-pixel dE 64.9, outline 45.4 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 28.7, 13% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 97 | worst heath: dE 19.3 (heath dE 19.3, old_wood dE 26.2, riverbank dE 37.5, snow dE 52.5, ash dE 28.7, sand dE 40.1, marsh dE 29.3) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 29% of body pixels change between kingdom colours (min pair 17%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 44.5 (fire 46.4, shadow 50.4, ice 46.8, nature 44.5) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 37 | worst pair shadow / ice (deutan): dE 5.3 on the team-colour area (normal vision 11.2; 2063 px); deutan: shadow / ice dE 5.3; protan: shadow / ice dE 6.5; worst vs ground: fire colour (deutan) dE 26.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | **WARN** 61 | worst dL +16 (point 1 dL +16, point 2 dL +53, point 3 dL +67; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/4): OrbEmbers, Cup, Plinth; soft glows under the bloom (v1 count, luma > 0.4): 5 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 32 | outline complexity 1.72 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 79.2, bottom third L* 14.3 (+64, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.5 at 25 m, 5.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Shaft 318 v / 4 s; Rubble 168 v / 1 s x7; Body/Orb 104 v / 1 s; Body/Cup 94 v / 2 s; Body/Claws 84 v / 1 s x4; Body/Plinth 71 v / 1 s; ContactDecal 4 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 11 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B5 Real lights: No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4))
