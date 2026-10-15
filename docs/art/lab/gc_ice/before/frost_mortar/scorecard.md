# Art Lab scorecard: frost_mortar

Scene `res://art/units/ice/frost_mortar/frost_mortar.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-10-15 12:18:58 · lab v3.1

## Result: **FAIL** · quality **95 / 100** (95.0)

1 FAIL · 0 WARN · 32 PASS · 17 info · 0 skipped · 26 s

## Improve next
1. **Vertices** (FAIL): B4 5039 -> 2719 (want <= 2500): `Merged` 3062 -> 1531 verts; `Merged` 289 -> 145 verts; `Merged` 285 -> 143 verts; `Merged` 239 -> 120 verts; `Merged` 239 -> 120 verts; `Merged` 233 -> 117 verts; `Merged` 233 -> 117 verts; `Muzzle` 67 -> 34 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.97): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Contrast on the other grounds** (PASS): On snow the body drops to dE 24.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 29 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Mount 3, Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 96 | 11 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 5039 (body + face above its allowance: face 1188 v, allowance 800, total 5839; biggest: Merged 3062, Face 696, Face 492, Merged 289) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 6 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 23 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 5 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 34 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 901 of 7830 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0014 ms process per instance (100 animated at 40 m: +0.14 ms process, render CPU +1.44 ms, GPU +0.98 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.022 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.52 m / body_height 1.9 (x0.8) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.92 / z 1.18 m (radius 0.8, from frost_mortar.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1142 px (38 x 59 bbox; 55 m: 588 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.4, 0% of the body melts (within dE 15 of the ground); body L* 68.4 C 7.4 vs ground L* 62.7 C 48.6, hue gap n/a (body C* <= 25); top third (world height) dE 55.9, L* 84.8; per-pixel dE 60.8, outline 44.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 91 | dE 24.5, 33% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 93 | worst snow: dE 24.5 (heath dE 32.4, old_wood dE 48.2, riverbank dE 49.0, snow dE 24.5, ash dE 46.0, sand dE 41.7, marsh dE 55.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 30% of body pixels change between kingdom colours (min pair 30%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 37.7 (fire 50.4, shadow 71.1, ice 54.4, nature 37.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 13.3 on the team-colour area (normal vision 82.0; 348 px); deutan: fire / nature dE 13.3; protan: fire / nature dE 23.5; worst vs ground: fire colour (deutan) dE 31.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 93 | bar hides 5% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.4 m, 2.08 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +27 (point 1 dL +27; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Vapour; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst ice: dE 50.2, dL +8 (warm dE 54.3, ice dE 50.2, night dE 53.7, autumn dE 50.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.91 (min 0.87), area kept 96-98% (min 1109 px), frame-to-frame IoU min 0.91; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.39 (bristleback 0.39, rime_hauler 0.34, hoarlight_magebow_placeholder 0.29, magpie 0.27, rimeling_placeholder 0.25, rimeling 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.42 m from the body centre at t 0.24 s (0.53 m forward; geometry clipped at the ground); declared 13.0 m (UnitType attack_range (frost_mortar.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 48% of the silhouette at its peak (t 0.25 s; 0.12 s 5%, 0.25 s 48%, 0.4 s 42%, 0.6 s 19%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 64 | 128 shapes over 7 body parts (18.3 per part: LegL 3, LegR 3, Head 32, ArmL 2, ArmR 2, Chest 6, Mount 80); 38% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.842 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 233% of the 2500 verts budget used (5835) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.93 at the close-up (71064 px), 3.16 at 25 m; close-up outline complexity 2.19 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 51 | outline complexity 1.97 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 84.8, bottom third L* 51.1 (+33, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.7 at 25 m, 11.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 48.2, 0% melts; body L* 64.8 C 3.5 vs floor L* 51.8 C 42.8; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.6 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Mount/Merged 3062 v / 12 s; Root/Chest/Head/Face 696 v / 1 s; Root/Mount/Face 492 v / 1 s; Root/Chest/Merged 289 v / 5 s; Root/Chest/Head/Merged 285 v / 3 s; Root/Chest/ArmL/Merged 239 v / 2 s; Root/Chest/ArmR/Merged 239 v / 2 s; Root/Hips/LegL/Merged 233 v / 3 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B4 5039 -> 2719 (want <= 2500): `Merged` 3062 -> 1531 verts; `Merged` 289 -> 145 verts; `Merged` 285 -> 143 verts; `Merged` 239 -> 120 verts; `Merged` 239 -> 12)
