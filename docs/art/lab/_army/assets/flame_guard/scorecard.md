# Art Lab scorecard: flame_guard

Scene `res://art/units/fire/flame_guard.tscn` · kind **unit** / tier **soldier** · kingdom fire · ground meadow · 2026-09-27 09:52:34 · lab v2.0

## Result: **WARN** · quality **89 / 100**

0 FAIL · 5 WARN · 25 PASS · 9 info · 0 skipped · 25 s

## Improve next
1. **Contrast in every team colour (meadow)** (WARN): shader_parameter/base_color of `fire_bronze` #9e6629 -> #c57535 (45% of the visible body): predicted dE R3 meadow 61.3 -> 64.6, R3t fire 61.2 -> 64.5, R3t shadow 77.6 -> 74.2, R3t ice 38.5 -> 42.0, R3t nature 14.0 -> 24.2, R4k ash 72.3 -> 77.9 (want >= 24); other grounds heath 56.4, old_wood 72.5, riverbank 83.0, snow 68.1, sand 45.7, marsh 75.8; shared material (res://art/units/kit/materials/fire_bronze.tres): give flame_guard its own copy first, other assets use it too [fixes.json #1] _(from R3t Contrast in every team colour (meadow), shot teams)_
2. **Head height vs body_height** (WARN): R8: body_height 1.6 -> 2.01 in res://art/units/fire/flame_guard.tscn (root) and res://data/units/flame_guard.tres (the head top; x1.26 now), or lower the head / crest 0.01 m [fixes.json #2] _(from R8 Head height vs body_height)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.45 -> 0.49, or pull the widest parts in to x <= 0.79 / z <= 0.79 m [fixes.json #3] _(from R10 Footprint vs selection radius)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 13.5): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 2 glow point(s) barely stand out from their 1 m surround (worst dL +4): darken around them or raise the energy [fixes.json #5] _(from R5c Glow points stand out (1 m surround), shot glow)_
6. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.96): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: ArmL 2, Head 2, (root) 1, ArmR 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1702 (biggest: Merged 482, Merged 313, Merged 305, Merged 261) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 9 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 20 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 19 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 198 of 1618 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.055 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 52 | head top 2.01 m / body_height 1.6 (x1.25) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.86 / z 0.82 m (radius 0.45, from flame_guard.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 939 px (38 x 42 bbox; 55 m: 476 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 61.3, 0% of the body melts (within dE 15 of the ground); body L* 62.9 C 64.9 vs ground L* 63.1 C 48.0, hue gap 63 deg; top third (world height) dE 61.4, L* 64.3; per-pixel dE 62.6, outline 54.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 72.3, 0% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst sand: dE 44.4 (heath dE 51.9, old_wood dE 66.8, riverbank dE 77.9, snow dE 67.3, ash dE 72.3, sand dE 44.4, marsh dE 69.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 61% of body pixels change between kingdom colours (min pair 59%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 45 | worst nature colour: dE 14.0 (fire 61.2, shadow 77.6, ice 38.5, nature 14.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 36 | worst pair fire / nature (deutan): dE 13.5 on the team-colour area (normal vision 80.5; 598 px); deutan: fire / nature dE 13.5; protan: fire / nature dE 23.1; worst vs ground: fire colour (protan) dE 6.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 38 | worst dL +4 (point 1 dL +13, point 2 dL +4; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 2/1/1): GlowFireGlow; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.9 (min 0.81), area kept 94-102% (min 905 px), frame-to-frame IoU min 0.86; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 1/1/2/1/1/1/1/1 (median 1, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 51% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.09 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 51 | outline complexity 1.96 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 67 | top third L* 64.3, bottom third L* 57.9 (+6, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 89 | inner detail 2.5 at 25 m, 2.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 482 v / 2 s; Root/Chest/ArmR/Merged 313 v / 3 s; Root/Chest/ArmL/Merged 305 v / 3 s; Root/Chest/Head/Merged 261 v / 2 s; Root/Hips/LegL/Merged 91 v / 2 s; Root/Hips/LegR/Merged 91 v / 2 s; Root/Hips/Merged 77 v / 2 s; Root/Chest/ArmL/GlowFireGlow 54 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: shader_parameter/base_color of `fire_bronze` #9e6629 -> #c57535 (45% of the visible body): predicted dE R3 meadow 61.3 -> 64.6, R3t fire 61.2 -> 64.5, R3t shado)
