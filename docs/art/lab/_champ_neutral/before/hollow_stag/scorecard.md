# Art Lab scorecard: hollow_stag

Scene `res://art/units/neutral/hollow_stag/hollow_stag.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-30 11:44:22 · lab v3.1

## Result: **FAIL** · quality **87 / 100** (86.9)

1 FAIL · 4 WARN · 23 PASS · 19 info · 0 skipped · 27 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 13 -> 13 (want <= 10): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Glow points at 40 m** (WARN): Glow points 4 -> 2 (want 1-3): hollow_stag_shade crack_strength 1.0 -> 0.19 on Shin, Shin (dim under the bloom level: 2 point(s), peak 3.86 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Skull 3.02 m so the HP bar reads over the head [fixes.json #5] _(from R8w Parts above body_height + 0.4)_
4. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.9 -> 0.96, or pull the widest parts in to x <= 1.58 / z <= 2.7 m [fixes.json #3] _(from R10 Footprint vs selection radius)_
5. **Vertices** (WARN): B4 4149 -> 2417 (want <= 2500): `Skull` 1739 -> 870 verts; `Merged` 1520 -> 760 verts; `Merged` 262 -> 159 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #4] _(from B4 Vertices)_
6. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +0 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: Lower 4, (root) 1, Crown 1, Head 1, LegBL 1, LegBR 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | **FAIL** 5 | 13 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 4149 (body + face above its allowance: face 404 v, allowance 600, total 4553; biggest: Skull 1739, Merged 1520, Merged 262, Shin 150) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Leaves) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 8 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Skull, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 10 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 7 (model says 12) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 506 of 4754 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0006 ms process per instance (100 animated at 40 m: +0.06 ms process, render CPU +0.98 ms, GPU +2.15 ms) | <= 0.005 ms per instance (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.006 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Skull 3.02 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.68 / z 1.97 m (radius 0.9, from hollow_stag.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1298 px (74 x 66 bbox; 55 m: 656 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 98 | mean-colour dE 38.3, 3% of the body melts (within dE 15 of the ground); body L* 67.1 C 12.4 vs ground L* 61.9 C 49.4, hue gap n/a (body C* <= 25); top third (world height) dE 34.2, L* 54.9; per-pixel dE 49.3, outline 44.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 85 | worst heath: dE 18.3 (heath dE 18.3, old_wood dE 40.1, riverbank dE 38.8, snow dE 25.2, ash dE 45.5, sand dE 24.7, marsh dE 51.7) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 1% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 2.34 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +26 (point 1 dL +26, point 2 dL +30, point 3 dL +31, point 4 dL +28; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 4 point(s) above the bloom level 1.2 (median of 4/4/4): Skull, Shin x2, Merged, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Skull, Shin x2, Merged |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 31.9, dL +21 (warm dE 38.5, ice dE 37.0, night dE 31.9, autumn dE 34.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 89 | walk frames vs rest: mean IoU 0.64 (min 0.59), area kept 98-102% (min 1303 px), frame-to-frame IoU min 0.62; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 4/4/5/5/5/5/3/3 (median 5, range 2, 0 frame(s) at 0; at rest 4) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.4 (gloomcap_elder 0.4, shadow_knight 0.36, ruin_warden 0.31, rime_colossus 0.3, tracker 0.3, stormbottle_genie 0.27) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 3.25 m from the body centre at t 0.08 s (2.99 m forward; geometry clipped at the ground); declared 2.0 m (UnitType attack_range (hollow_stag.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 53% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 74% of the silhouette at its peak (t 0.4 s; 0.12 s 61%, 0.25 s 69%, 0.4 s 74%, 0.6 s 70%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.03 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 280 shapes over 8 body parts (35.0 per part: Crown 187, Head 18, Lower 24, LegFL 4, LegFR 4, LegBL 4, LegBR 4, Mount 35); 15% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.922 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 181% of the 2500 verts budget used (4549) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 85 | inner edges per outline px: 1.65 at the close-up (34490 px), 1.45 at 25 m; close-up outline complexity 31.01 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 7.73 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 31 | top third L* 54.9, bottom third L* 54.5 (+0, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 53 | inner detail 12.9 at 25 m, 16.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 4 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 69 | on the autumn floor: dE 30.2, 0% melts; body L* 67.0 C 17.6 vs floor L* 50.3 C 42.0 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.32 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Mount/Head/Crown/Skull 1739 v / 6 s; Root/Mount/Merged 1520 v / 6 s; Root/Mount/Head/Merged 262 v / 3 s; Root/Mount/LegFL/Lower/Shin 150 v / 3 s; Root/Mount/LegFR/Lower/Shin 150 v / 3 s; Root/Mount/LegBL/Lower/Shin 150 v / 3 s; Root/Mount/LegBR/Lower/Shin 150 v / 3 s; Root/Mount/LegFL/Merged 114 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 5 in fixes.json (top: B2 13 -> 13 (want <= 10): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
