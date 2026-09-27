# Art Lab scorecard: shade

Scene `res://art/units/shadow/shade.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-09-27 09:41:23 · lab v2.0

## Result: **WARN** · quality **95 / 100**

0 FAIL · 4 WARN · 29 PASS · 11 info · 0 skipped · 34 s

## Improve next
1. **Frame cost** (WARN): B13 Frame cost: Cut the per-frame script cost (0.0065 ms per instance): write pivots only when they change, skip work at the far tiers [fixes.json #1] _(from B13 Frame cost)_
2. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 9.2): add a value step inside the team-colour area [fixes.json #2] _(from R6cb Team colours for colour-blind players, shot teams)_
3. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +14): darken around them or raise the energy [fixes.json #3] _(from R5c Glow points stand out (1 m surround), shot glow)_
4. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (2/2/2/0/1/0/2/2 per frame): put them on parts the gait does not cover [fixes.json #4] _(from R5w Glow points while walking (flicker), shot glow)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from magpie (IoU 0.6): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 22 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Chest 2, (root) 1, ArmL 1, ArmR 1, Head 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1313 (biggest: Merged 295, Merged 253, Merged 229, Merged 215) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 10 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 26 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 17 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 214 of 1596 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | **WARN** 41 | 0.0065 ms process per instance (100 animated at 40 m: +0.65 ms process, render CPU +1.31 ms, GPU +0.56 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) | One _process per model, cached pivots, no get_node / allocation per frame, respect the distance tiers (art-units 6.10) |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 92 | head top 1.82 m / body_height 1.6 (x1.14) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.64 / z 0.33 m (radius 0.45, from shade.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 487 px (31 x 34 bbox; 55 m: 255 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 90.3, 0% of the body melts (within dE 15 of the ground); body L* 24.0 C 34.2 vs ground L* 63.3 C 48.0, hue gap 163 deg; top third (world height) dE 93.0, L* 29.0; per-pixel dE 93.9, outline 67.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 38.6, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 30.3 (heath dE 51.4, old_wood dE 54.3, riverbank dE 68.0, snow dE 75.0, ash dE 30.3, sand dE 83.0, marsh dE 38.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 60% of body pixels change between kingdom colours (min pair 58%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 42.6 (fire 67.8, shadow 90.6, ice 66.3, nature 42.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 42 | worst pair fire / nature (deutan): dE 9.2 on the team-colour area (normal vision 71.2; 300 px); deutan: fire / nature dE 9.2; protan: fire / nature dE 20.7; worst vs ground: fire colour (deutan) dE 40.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 0 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 43 | worst dL +14 (point 1 dL +14; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 52.8, dL -11 (warm dE 89.9, ice dE 82.5, night dE 52.8, autumn dE 80.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 86 | walk frames vs rest: mean IoU 0.59 (min 0.53), area kept 82-87% (min 401 px), frame-to-frame IoU min 0.57; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 46 | points per frame 2/2/2/0/1/0/2/2 (median 2, range 2, 2 frame(s) at 0; at rest 0) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (magpie 0.6, tracker 0.56, gloom_thrall 0.53, nightbolt 0.48, shadow_knight 0.32, grave_hound 0.31) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 69% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.8 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 29.0, bottom third L* 11.9 (+17, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.6 at 25 m, 12.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 67.5, 0% melts; body L* 22.3 C 28.1 vs floor L* 52.5 C 43.4; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.22 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 295 v / 3 s; Root/Chest/ArmR/Merged 253 v / 3 s; Root/Chest/ArmL/Merged 229 v / 2 s; Root/Chest/Head/Merged 215 v / 4 s; Root/Hips/LegL/Merged 132 v / 1 s; Root/Hips/LegR/Merged 132 v / 1 s; Root/Hips/Merged 37 v / 1 s; Root/Chest/Cape 16 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 in the noise band (0.0065 ms, budget 0.005): re-run on a quiet PC before fixing
- Fix recipes: 4 in fixes.json (top: B13 Frame cost: Cut the per-frame script cost (0.0065 ms per instance): write pivots only when they change, skip work at the far tiers)
