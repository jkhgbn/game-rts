# Art Lab scorecard: frost_mortar

Scene `res://art/units/ice/frost_mortar/frost_mortar.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-09-30 11:02:23 · lab v3.1

## Result: **FAIL** · quality **94 / 100** (93.8) (previous run 95, -1)

1 FAIL · 1 WARN · 32 PASS · 17 info · 0 skipped · 23 s

## Before / after (vs the run of 2026-09-27 17:59:50 in `docs/art/lab/frost_mortar`: quality 95 -> 94, -1)
### What got worse (3)
1. **B4 Vertices: PASS 96 -> FAIL 0 (-96)**. Now: 5039 (body + face above its allowance: face 1188 v, allowance 800, total 5839; biggest: Merged 3062, Face 696, Face 492, Merged 289). Was: 4699 (biggest: Merged 3086, Merged 309, Merged 289, Merged 239)
2. **B7 Shadow casters: PASS 100 -> PASS 89 (-11)**. Now: 4 (Merged, Merged, Merged, Merged). Was: 4 (Merged, Merged, Merged, Merged)
3. **B2 Draw instances at rest: PASS 100 -> PASS 96 (-4)**. Now: 11. Was: 9

### What got better (5)
C3 Palette depth (close-up): INFO 60 -> INFO 90 (+30); R4 Contrast on the other grounds: PASS 89 -> PASS 95 (+6); R4k Contrast on the home ground (snow): PASS 88 -> PASS 93 (+5); R8 Head height vs body_height: PASS 95 -> PASS 100 (+5); P1 Silhouette hook: INFO 51 -> INFO 54 (+3)

new B9m Meshes built per instance (WARN)

### Score delta per check (11 changed, 42 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B2 | Draw instances at rest | PASS 100 | PASS 96 | -3.8 |
| B4 | Vertices | PASS 96 | FAIL 0 | -95.8 |
| B7 | Shadow casters | PASS 100 | PASS 89 | -10.6 |
| C1 | Shape richness (secondary shapes) | INFO 64 | INFO 63 | -0.8 |
| R8 | Head height vs body_height | PASS 95 | PASS 100 | +5.0 |
| C3 | Palette depth (close-up) | INFO 60 | INFO 90 | +30.0 |
| R4k | Contrast on the home ground (snow) | PASS 88 | PASS 93 | +5.3 |
| R4 | Contrast on the other grounds | PASS 89 | PASS 95 | +5.8 |
| R7 | HP bar over the body at 40 m | PASS 91 | PASS 93 | +1.9 |
| P1 | Silhouette hook | INFO 51 | INFO 54 | +3.2 |
| B13 | Frame cost | PASS 93 | PASS 100 | +7.5 (noisy) |

Changed pixels per shot: z40 1.8 %, z55 1.0 %, z25 2.2 %, close 7.5 %, strike_side 61.9 %, turns 7.9 %, cast 8.0 %, anim 5.7 %, silhouette 0.2 %, lineup 7.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (FAIL): B4 5039 -> 2719 (want <= 2500): `Merged` 3062 -> 1531 verts; `Merged` 289 -> 145 verts; `Merged` 285 -> 143 verts; `Merged` 239 -> 120 verts; `Merged` 239 -> 120 verts; `Merged` 233 -> 117 verts; `Merged` 233 -> 117 verts; `Muzzle` 67 -> 34 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 2 per-instance mesh(es) in a static dictionary [fixes.json #2] _(from B9m Meshes built per instance)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.83): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.01): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
5. **Contrast on the other grounds** (PASS): On snow the body drops to dE 25.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 29 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 2 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 2 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
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
| B12 | Downward-facing triangles | INFO | 903 of 7830 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0013 ms process per instance (100 animated at 40 m: +0.13 ms process, render CPU +1.02 ms, GPU +0.96 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.021 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.51 m / body_height 1.9 (x0.79) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.92 / z 1.18 m (radius 0.8, from frost_mortar.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1146 px (38 x 59 bbox; 55 m: 594 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.5, 0% of the body melts (within dE 15 of the ground); body L* 67.4 C 7.7 vs ground L* 62.8 C 48.6, hue gap n/a (body C* <= 25); top third (world height) dE 56.0, L* 84.2; per-pixel dE 61.0, outline 46.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 93 | dE 25.9, 35% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 95 | worst snow: dE 25.9 (heath dE 32.3, old_wood dE 47.5, riverbank dE 48.4, snow dE 25.9, ash dE 45.0, sand dE 42.6, marsh dE 54.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 30% of body pixels change between kingdom colours (min pair 30%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 37.7 (fire 50.6, shadow 71.4, ice 54.5, nature 37.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 13.5 on the team-colour area (normal vision 84.0; 347 px); deutan: fire / nature dE 13.5; protan: fire / nature dE 23.9; worst vs ground: fire colour (deutan) dE 31.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 93 | bar hides 5% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.4 m, 2.08 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +31 (point 1 dL +31; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Vapour; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst ice: dE 50.5, dL +6 (warm dE 54.5, ice dE 50.5, night dE 52.6, autumn dE 50.9); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.91 (min 0.87), area kept 96-98% (min 1109 px), frame-to-frame IoU min 0.9; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.38 (bristleback 0.38, rime_hauler 0.34, hoarlight_magebow_placeholder 0.28, magpie 0.27, rimeling_placeholder 0.25, rimeling 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.42 m from the body centre at t 0.24 s (0.53 m forward; geometry clipped at the ground); declared 13.0 m (UnitType attack_range (frost_mortar.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 48% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 48% of the silhouette at its peak (t 0.25 s; 0.12 s 4%, 0.25 s 48%, 0.4 s 42%, 0.6 s 20%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 63 | 128 shapes over 7 body parts (18.3 per part: LegL 3, LegR 3, Head 32, ArmL 2, ArmR 2, Chest 6, Mount 80); 38% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.831 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 233% of the 2500 verts budget used (5835) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.41 at the close-up (71257 px), 2.98 at 25 m; close-up outline complexity 2.2 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 54 | outline complexity 2.01 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 84.2, bottom third L* 49.9 (+34, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.9 at 25 m, 11.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 48.1, 0% melts; body L* 63.0 C 4.0 vs floor L* 51.8 C 42.8; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 3062 v / 12 s; Root/Chest/Head/Face 696 v / 1 s; Root/Mount/Face 492 v / 1 s; Root/Chest/Merged 289 v / 5 s; Root/Chest/Head/Merged 285 v / 3 s; Root/Chest/ArmL/Merged 239 v / 2 s; Root/Chest/ArmR/Merged 239 v / 2 s; Root/Hips/LegL/Merged 233 v / 3 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: B4 5039 -> 2719 (want <= 2500): `Merged` 3062 -> 1531 verts; `Merged` 289 -> 145 verts; `Merged` 285 -> 143 verts; `Merged` 239 -> 120 verts; `Merged` 239 -> 12)
