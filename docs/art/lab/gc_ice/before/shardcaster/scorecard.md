# Art Lab scorecard: shardcaster

Scene `res://art/units/ice/shardcaster.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-10-15 12:14:56 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.9)

0 FAIL · 1 WARN · 32 PASS · 17 info · 0 skipped · 25 s

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.45 -> 0.5, or pull the widest parts in to x <= 0.79 / z <= 0.79 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 63% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.85): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from hoarlight_magebow_placeholder (IoU 0.86): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Attack reads at 40 m** (PASS): Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 21%) _(from A3 Attack reads at 40 m, shot anim)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 27 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (9 mesh + 1 multimesh); per pivot: ArmR 2, Head 2, (root) 1, ArmL 1, Chest 1, LegL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1751 (body + face above its allowance: face 558 v, allowance 800, total 2309; biggest: Face 558, Merged 458, Merged 379, Merged 239) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 5 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 21 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 297 of 3286 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0014 ms process per instance (100 animated at 40 m: +0.14 ms process, render CPU +1.27 ms, GPU +0.26 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 89 | head top 1.88 m / body_height 1.6 (x1.18) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.88 / z 0.72 m (radius 0.45, from shardcaster.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 492 px (27 x 37 bbox; 55 m: 251 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 64.7, 0% of the body melts (within dE 15 of the ground); body L* 68.2 C 19.0 vs ground L* 63.0 C 48.3, hue gap n/a (body C* <= 25); top third (world height) dE 57.2, L* 82.5; per-pixel dE 69.1, outline 48.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 31.7, 36% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 31.7 (heath dE 37.7, old_wood dE 55.1, riverbank dE 55.7, snow dE 31.7, ash dE 49.2, sand dE 53.4, marsh dE 60.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 57% of body pixels change between kingdom colours (min pair 55%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 31.8 (fire 50.2, shadow 74.7, ice 63.9, nature 31.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 76 | worst pair fire / nature (deutan): dE 8.6 on the team-colour area (normal vision 62.3; 291 px); deutan: fire / nature dE 8.6; protan: fire / nature dE 17.9; worst vs ground: fire colour (deutan) dE 27.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +22 (point 1 dL +22; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Tip; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 59.5, dL +6 (warm dE 64.3, ice dE 59.7, night dE 62.3, autumn dE 59.5); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.83 (min 0.76), area kept 101-105% (min 497 px), frame-to-frame IoU min 0.78; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 73 | max IoU 0.86 (hoarlight_magebow_placeholder 0.86, frostrune_rifleman 0.73, magpie 0.62, tracker 0.61, hoarlight_magebow 0.6, frost_mortar_placeholder 0.5); same shape family as hoarlight_magebow_placeholder but told apart by colour (dE 16.1) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.17 m from the body centre at t 0.14 s (0.66 m forward; geometry clipped at the ground); declared 9.0 m (UnitType attack_range (shardcaster.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 91 | strike pose changes 21% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 25% of the silhouette at its peak (t 0.25 s; 0.12 s 22%, 0.25 s 25%, 0.4 s 24%, 0.6 s 16%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 35 | 45 shapes over 6 body parts (7.5 per part: LegL 2, LegR 2, Head 24, ArmL 2, ArmR 6, Chest 9); 63% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.841 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 88% of the 2500 verts budget used (2218) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 96 | inner edges per outline px: 1.78 at the close-up (56786 px), 1.39 at 25 m; close-up outline complexity 3.66 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 42 | outline complexity 1.85 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 82.5, bottom third L* 38.3 (+44, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.7 at 25 m, 9.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 58.0, 0% melts; body L* 65.1 C 13.4 vs floor L* 52.1 C 43.1; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.33 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 558 v / 1 s; Root/Chest/Merged 458 v / 5 s; Root/Chest/ArmR/Merged 379 v / 4 s; Root/Chest/ArmL/Merged 239 v / 2 s; Root/Hips/LegL/Merged 186 v / 2 s; Root/Hips/LegR/Merged 186 v / 2 s; Root/Chest/Head/Merged 183 v / 2 s; Root/Chest/ArmR/Orbit/Spin/Shards 87 v / 1 s x3
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R10: raise UnitType.radius 0.45 -> 0.5, or pull the widest parts in to x <= 0.79 / z <= 0.79 m)
