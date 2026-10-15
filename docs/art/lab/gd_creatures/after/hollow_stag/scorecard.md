# Art Lab scorecard: hollow_stag

Scene `res://art/units/neutral/hollow_stag/hollow_stag.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-10-15 13:29:56 · lab v3.1

## Result: **WARN** · quality **91 / 100** (91.2)

0 FAIL · 3 WARN · 25 PASS · 19 info · 0 skipped · 25 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 4 -> 1 (want 1-3): hollow_stag_hide crack_strength 1.0 -> 0.2 on Merged, Merged, Merged (dim under the bloom level: 3 point(s), peak 3.67 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Skull 3.02 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Vertices** (WARN): B4 4149 -> 2417 (want <= 2500): `Skull` 1739 -> 870 verts; `Merged` 1520 -> 760 verts; `Shins` 600 -> 497 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +1 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.6): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 19.6: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 32 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: (root) 1, Crown 1, Head 1, LegBL 1, LegBR 1, LegFL 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 87 | 10 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 4149 (body + face above its allowance: face 404 v, allowance 600, total 4553; biggest: Skull 1739, Merged 1520, Shins 600, Merged 262) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Leaves) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 8 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Skull, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 10 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 8 (model says 12) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 506 of 4754 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.01 ms process, render CPU +2.01 ms, GPU +0.62 ms) | <= 0.005 ms per instance (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.0 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Skull 3.02 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | PASS 100 | x 1.68 / z 1.97 m (radius 1.0, from hollow_stag.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1299 px (74 x 65 bbox; 55 m: 665 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 99 | mean-colour dE 38.9, 3% of the body melts (within dE 15 of the ground); body L* 68.9 C 12.3 vs ground L* 61.9 C 49.4, hue gap n/a (body C* <= 25); top third (world height) dE 34.9, L* 57.0; per-pixel dE 49.5, outline 44.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 87 | worst heath: dE 19.6 (heath dE 19.6, old_wood dE 41.8, riverbank dE 40.2, snow dE 23.8, ash dE 47.2, sand dE 23.8, marsh dE 53.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 1% of the silhouette (gap -4 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 2.6 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +28 (point 1 dL +30, point 2 dL +28, point 3 dL +30, point 4 dL +28; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 4 point(s) above the bloom level 1.2 (median of 4/4/4): Skull, Merged x3, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 4 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Skull, Merged x3 |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 34.9, dL +23 (warm dE 39.8, ice dE 38.6, night dE 34.9, autumn dE 35.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 89 | walk frames vs rest: mean IoU 0.65 (min 0.59), area kept 97-102% (min 1296 px), frame-to-frame IoU min 0.62; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 3/3/4/4/5/5/4/4 (median 4, range 2, 0 frame(s) at 0; at rest 4) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.4 (gloomcap_elder 0.4, shadow_knight 0.35, rime_colossus 0.31, ruin_warden 0.31, tracker 0.3, stormbottle_genie 0.27) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 3.3 m from the body centre at t 0.14 s (2.97 m forward; geometry clipped at the ground); declared 2.0 m (UnitType attack_range (hollow_stag.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 52% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 74% of the silhouette at its peak (t 0.4 s; 0.12 s 61%, 0.25 s 69%, 0.4 s 74%, 0.6 s 69%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 280 shapes over 8 body parts (35.0 per part: Crown 187, Head 18, LegFL 4, LegFR 4, LegBL 4, LegBR 4, Mount 35, ShinSkeleton 24); 15% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.921 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 181% of the 2500 verts budget used (4549) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 98 | inner edges per outline px: 1.78 at the close-up (34764 px), 1.49 at 25 m; close-up outline complexity 31.17 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 7.63 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 38 | top third L* 57.0, bottom third L* 55.5 (+1, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 60 | inner detail 12.6 at 25 m, 17.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 75 | on the autumn floor: dE 31.9, 0% melts; body L* 69.3 C 16.9 vs floor L* 50.3 C 42.0 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.36 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Head/Crown/Skull 1739 v / 6 s; Root/Mount/Merged 1520 v / 6 s; ShinSkeleton/Shins 600 v / 3 s; Root/Mount/Head/Merged 262 v / 3 s; Root/Mount/LegFL/Merged 114 v / 2 s; Root/Mount/LegFR/Merged 114 v / 2 s; Root/Mount/LegBL/Merged 100 v / 2 s; Root/Mount/LegBR/Merged 100 v / 2 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: Glow points 4 -> 1 (want 1-3): hollow_stag_hide crack_strength 1.0 -> 0.2 on Merged, Merged, Merged (dim under the bloom level: 3 point(s), peak 3.67 x the leve)
