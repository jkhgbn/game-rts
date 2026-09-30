# Art Lab scorecard: flame_guard

Scene `res://art/units/fire/flame_guard.tscn` · kind **unit** / tier **soldier** · kingdom fire · ground meadow · 2026-09-30 11:46:22 · lab v3.1

## Result: **FAIL** · quality **85 / 100** (85.3)

1 FAIL · 4 WARN · 28 PASS · 17 info · 0 skipped · 33 s

## Improve next
1. **Frame cost** (FAIL): B13 Frame cost: Cut the per-frame script cost (0.0213 ms per instance): write pivots only when they change, skip work at the far tiers [fixes.json #1] _(from B13 Frame cost)_
2. **Contrast in every team colour (meadow)** (WARN): shader_parameter/base_color of `fire_bronze` #9e6629 -> #ea8f55 (45% of the visible body): predicted dE R3 meadow 60.3 -> 61.5, R3t fire 60.9 -> 61.9, R3t shadow 77.3 -> 71.9, R3t ice 38.6 -> 42.8, R3t nature 14.0 -> 24.1, R4k ash 72.2 -> 74.8 (want >= 24); other grounds heath 52.1, old_wood 69.9, riverbank 80.0, snow 62.0, sand 41.0, marsh 73.6; `fire_bronze` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `fire_sec_archer.tres` (#f28c33, dE 16.5 from the wanted colour; no palette entry is close: a new palette entry is needed, or give the asset its own copy); team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `fire_cloth_dark` 11%, `fire_cloth` 34% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #2] _(from R3t Contrast in every team colour (meadow), shot teams)_
3. **Head height vs body_height** (WARN): R8: body_height 1.6 -> 2.0 in res://art/units/fire/flame_guard.tscn (root) and res://data/units/flame_guard.tres (the head top; x1.25 now), or lower the head / crest 0.0 m [fixes.json #3] _(from R8 Head height vs body_height)_
4. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.45 -> 0.49, or pull the widest parts in to x <= 0.79 / z <= 0.79 m [fixes.json #4] _(from R10 Footprint vs selection radius)_
5. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 14.0): add a value step inside the team-colour area [fixes.json #5] _(from R6cb Team colours for colour-blind players, shot teams)_
6. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 5 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Head 3, ArmL 2, (root) 1, ArmR 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 96 | 11 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1678 (body + face above its allowance: face 718 v, allowance 800, total 2396; biggest: Face 718, Merged 482, Merged 313, Merged 305) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 10 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 21 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 20 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 232 of 2814 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | **FAIL** 0 | 0.0213 ms process per instance (100 animated at 40 m: +2.13 ms process, render CPU +1.08 ms, GPU +0.12 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) | One _process per model, cached pivots, no get_node / allocation per frame, respect the distance tiers (art-units 6.10) |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.055 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 52 | head top 2.0 m / body_height 1.6 (x1.25) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.86 / z 0.82 m (radius 0.45, from flame_guard.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 939 px (38 x 42 bbox; 55 m: 476 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 60.3, 0% of the body melts (within dE 15 of the ground); body L* 63.7 C 63.9 vs ground L* 63.1 C 48.0, hue gap 63 deg; top third (world height) dE 59.8, L* 65.6; per-pixel dE 62.0, outline 54.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 72.2, 0% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst sand: dE 43.9 (heath dE 51.2, old_wood dE 66.4, riverbank dE 77.5, snow dE 66.7, ash dE 72.2, sand dE 43.9, marsh dE 69.7) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 59% of body pixels change between kingdom colours (min pair 59%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 45 | worst nature colour: dE 14.0 (fire 60.9, shadow 77.3, ice 38.6, nature 14.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 36 | worst pair fire / nature (deutan): dE 14.0 on the team-colour area (normal vision 85.3; 560 px); deutan: fire / nature dE 14.0; protan: fire / nature dE 24.3; worst vs ground: fire colour (protan) dE 6.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +19 (point 1 dL +19, point 2 dL +21; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): GlowFireGlow x2; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 42.7, dL +3 (warm dE 60.8, ice dE 51.5, night dE 42.7, autumn dE 58.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.9 (min 0.82), area kept 95-102% (min 911 px), frame-to-frame IoU min 0.84; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.62 (cinder_arbalest_placeholder 0.62, cinderlock 0.61, tracker 0.6, ember_archer 0.57, scorchbow 0.53, gloomcap_elder 0.5) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.15 m from the body centre at t 0.24 s (1.07 m forward; geometry clipped at the ground); declared 1.6 m (UnitType attack_range (flame_guard.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 48% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 34% of the silhouette at its peak (t 0.25 s; 0.12 s 32%, 0.25 s 34%, 0.4 s 34%, 0.6 s 26%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 67 | 55 shapes over 7 body parts (7.9 per part: LegL 2, LegR 2, Hips 2, Head 28, ArmL 6, ArmR 7, Chest 8); 19% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.814 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 95% of the 2500 verts budget used (2392) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 20 | 10 colour steps (L*a*b* bins >= 2 % of the body), 5 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 59 | inner edges per outline px: 1.95 at the close-up (102165 px), 1.07 at 25 m; close-up outline complexity 2.76 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 57 | outline complexity 2.04 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 73 | top third L* 65.6, bottom third L* 58.1 (+7, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 96 | inner detail 2.8 at 25 m, 4.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 86 | on the autumn floor: dE 35.5, 0% melts; body L* 62.5 C 68.0 vs floor L* 52.2 C 43.2; fire team colour vs the floor swatches: min dE 45.2 (gorse_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.31 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- strike_side: [strike_side.jpg](strike_side.jpg)
- turns: [turns.jpg](turns.jpg)
- cast: [cast.jpg](cast.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 718 v / 1 s; Root/Chest/Merged 482 v / 2 s; Root/Chest/ArmR/Merged 313 v / 3 s; Root/Chest/ArmL/Merged 305 v / 3 s; Root/Chest/Head/Merged 237 v / 2 s; Root/Hips/LegL/Merged 91 v / 2 s; Root/Hips/LegR/Merged 91 v / 2 s; Root/Hips/Merged 77 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 over the budget on the first window (0.0213 ms): re-measured 0.0704 ms, kept the lower
- Fix recipes: 5 in fixes.json (top: B13 Frame cost: Cut the per-frame script cost (0.0213 ms per instance): write pivots only when they change, skip work at the far tiers)
