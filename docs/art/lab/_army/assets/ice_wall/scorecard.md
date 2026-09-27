# Art Lab scorecard: ice_wall

Scene `res://art/buildings/ice_wall.tscn` · kind **building** / tier **small** · kingdom ice · ground meadow · 2026-09-27 09:58:17 · lab v2.0

## Result: **WARN** · quality **86 / 100**

0 FAIL · 4 WARN · 15 PASS · 11 info · 0 skipped · 20 s

## Improve next
1. **Silhouette area at 40 m** (WARN): R1 2759 -> ~5750 px: grow the 40 m read x1.44 (area goes with the square: scale the key masses / body 44 %) [fixes.json #1] _(from R1 Silhouette area at 40 m, shot z40)_
2. **Glow points at 40 m** (WARN): Glow points 1 -> 2 (want 2-4): ShaderMaterial#-55748 crack_strength 0.0 -> 0.0 (raise over the bloom level: brightest soft glow 0.57 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Unique materials** (WARN): B8 8 -> 6 materials: use one material for look-alike pairs: `StandardMaterial3D#-99462` -> `StandardMaterial3D#-73353` (dE 0.0), `StandardMaterial3D#-79643` -> `StandardMaterial3D#-73353` (dE 0.0) [fixes.json #3] _(from B8 Unique materials)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +15): darken around them or raise the energy [fixes.json #4] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.25): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 14% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 12 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 8 material(s), 2 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 3 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 3 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | PASS 100 | 898 (biggest: Wall 650, Plinth 244, ContactDecal 4) | <= 6000 soft (lab default (towers, walls, posts): half a keep) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6 | Particle systems | INFO | 3 | no budget for building/small |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 1 | no budget for building/small |  |
| B8 | Unique materials | **WARN** 41 | 8 | <= 6 soft (lab default (towers, walls, posts): half a keep) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 10 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 7 surfaces over 3 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 190 of 646 triangles (29%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point 0.0 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | **WARN** 38 | 2759 px (55 x 76 bbox; 55 m: 1444 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 | Exaggerate the big masses (art-keep 0.1 / art-units 1.1): wider shoulders, bigger weapon / head, a taller vertical |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 55.7, 0% of the body melts (within dE 15 of the ground); body L* 67.5 C 8.8 vs ground L* 63.1 C 48.1, hue gap n/a (body C* <= 25); top third (world height) dE 58.4, L* 87.6; per-pixel dE 60.5, outline 35.7 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 26.0, 36% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 26.0 (heath dE 34.7, old_wood dE 48.6, riverbank dE 48.6, snow dE 26.0, ash dE 45.5, sand dE 43.8, marsh dE 54.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 87 | 14% of body pixels change between kingdom colours (min pair 12%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 49.0 (fire 52.9, shadow 62.6, ice 55.8, nature 49.0) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 12.2 on the team-colour area (normal vision 62.3; 476 px); deutan: fire / nature dE 12.2; protan: fire / nature dE 19.2; worst vs ground: fire colour (deutan) dE 43.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 44 | worst dL +15 (point 1 dL +15; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Smoke1; soft glows under the bloom (v1 count, luma > 0.4): 6 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 6 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 0 | outline complexity 1.25 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 87.6, bottom third L* 55.4 (+32, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.4 at 25 m, 4.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Wall 650 v / 4 s; Body/Plinth 244 v / 2 s; ContactDecal 4 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 8 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: R1 2759 -> ~5750 px: grow the 40 m read x1.44 (area goes with the square: scale the key masses / body 44 %))
