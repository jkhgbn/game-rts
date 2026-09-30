# Art Lab scorecard: ruin_warden

Scene `res://art/units/neutral/ruin_warden.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-30 11:43:55 · lab v3.1

## Result: **FAIL** · quality **87 / 100** (86.6)

1 FAIL · 4 WARN · 24 PASS · 19 info · 0 skipped · 26 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 12 -> 11 (want <= 10): `GapLight`, `Core` are keep_separate under `Chest`: keep only the animated / toggled one separate [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `warden_stone_dark` #475242 -> #455040 (39% of the visible body): predicted dE R3 meadow 32.3 -> 32.2 (want >= 24); other grounds heath 4.3, old_wood 26.2, riverbank 29.2, snow 41.1, ash 36.7, sand 30.4, marsh 40.0; `warden_stone_dark` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `fire_ash_ball.tres` (#4d4742, dE 9.9 from the wanted colour) [fixes.json #2] _(from R4 Contrast on the other grounds, shot z40)_
3. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 1.66 m so the HP bar reads over the head [fixes.json #5] _(from R8w Parts above body_height + 0.4)_
4. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.5 -> 0.56, or pull the widest parts in to x <= 0.88 / z <= 0.88 m [fixes.json #3] _(from R10 Footprint vs selection radius)_
5. **Vertices** (WARN): B4 3430 -> 2453 (want <= 2500): `Merged` 1385 -> 693 verts; `Merged` 816 -> 531 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #4] _(from B4 Vertices)_
6. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 47% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.89): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 34 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Chest 3, ArmR 2, (root) 1, ArmL 1, Head 1, Hips 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | **FAIL** 10 | 12 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 3430 (biggest: Merged 1385, Merged 816, Merged 287, Merged 281) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 10 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Motes) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 6 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 5 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 28 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 492 of 2716 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0017 ms process per instance (100 animated at 40 m: +0.17 ms process, render CPU +0.98 ms, GPU +-1.12 ms) | <= 0.005 ms per instance (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.018 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 87 | head top 2.19 m / body_height 1.8 (x1.22) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 1.66 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.98 / z 0.72 m (radius 0.5, from ruin_warden.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1780 px (52 x 58 bbox; 55 m: 917 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 32.3, 10% of the body melts (within dE 15 of the ground); body L* 53.4 C 19.9 vs ground L* 62.2 C 48.8, hue gap n/a (body C* <= 25); top third (world height) dE 27.3, L* 60.5; per-pixel dE 39.1, outline 31.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | **WARN** 35 | worst heath: dE 4.4 (heath dE 4.4, old_wood dE 26.4, riverbank dE 29.3, snow dE 41.0, ash dE 36.7, sand dE 30.3, marsh dE 40.1) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 91 | bar hides 7% of the silhouette (gap -15 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.3 m, 1.3 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +31 (point 1 dL +39, point 2 dL +31, point 3 dL +37; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): HitChips, MaulRune, Merged, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 92 | worst night: dE 23.9, dL +0 (warm dE 32.1, ice dE 30.9, night dE 23.9, autumn dE 28.9); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 94 | walk frames vs rest: mean IoU 0.75 (min 0.63), area kept 89-96% (min 1560 px), frame-to-frame IoU min 0.72; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 4/2/4/3/4/3/4/3 (median 4, range 2, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (gloomcap_elder 0.6, stormbottle_genie 0.53, bramblehorn 0.41, tracker 0.39, rime_seer 0.33, magpie 0.26) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.55 m from the body centre at t 0.14 s (1.29 m forward; geometry clipped at the ground); declared 1.6 m (UnitType attack_range (ruin_warden.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 61% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 35% of the silhouette at its peak (t 0.25 s; 0.12 s 33%, 0.25 s 35%, 0.4 s 35%, 0.6 s 22%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 74 | 67 shapes over 7 body parts (9.6 per part: LegL 5, LegR 5, Hips 4, Head 7, ArmL 5, ArmR 15, Chest 26); 47% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.892 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 137% of the 2500 verts budget used (3426) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 88 | 16 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.1 at the close-up (114008 px), 3.58 at 25 m; close-up outline complexity 3.98 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 71 | outline complexity 2.22 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 60.5, bottom third L* 39.9 (+20, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.1 at 25 m, 9.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 29 | on the autumn floor: dE 18.9, 12% melts; body L* 50.9 C 24.2 vs floor L* 51.0 C 42.5 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 1385 v / 6 s; Root/Chest/ArmR/Merged 816 v / 4 s; Root/Chest/Head/Merged 287 v / 4 s; Root/Chest/ArmL/Merged 281 v / 3 s; Root/Hips/LegL/Merged 179 v / 2 s; Root/Hips/LegR/Merged 179 v / 2 s; Root/Hips/Merged 143 v / 3 s; Root/Chest/GapLight 77 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 5 in fixes.json (top: B2 12 -> 11 (want <= 10): `GapLight`, `Core` are keep_separate under `Chest`: keep only the animated / toggled one separate)
