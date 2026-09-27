# Art Lab scorecard: ruin_warden

Scene `res://art/units/neutral/ruin_warden.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-27 10:28:48 · lab v2.0

## Result: **FAIL** · quality **83 / 100**

1 FAIL · 6 WARN · 19 PASS · 11 info · 0 skipped · 20 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 12 -> 11 (want <= 10): `GapLight`, `Core` are keep_separate under `Chest`: keep only the animated / toggled one separate [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `warden_bronze` #7a5e33 -> #7a6035 (23% of the visible body): predicted dE R3 meadow 32.5 -> 32.4 (want >= 24); other grounds heath 4.5, old_wood 26.4, riverbank 29.3, snow 40.7, ash 36.7, sand 30.4, marsh 40.2 [fixes.json #2] _(from R4 Contrast on the other grounds, shot z40)_
3. **Glow points at 40 m** (WARN): Glow points 4 -> 3 (want 1-3): warden_core_glow energy 3.2 -> 0.09 (dim under the bloom level: 1 point(s), peak 5.46 x the level) [fixes.json #3] _(from R5 Glow points at 40 m, shot glow)_
4. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 1.66 m so the HP bar reads over the head [fixes.json #6] _(from R8w Parts above body_height + 0.4)_
5. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.5 -> 0.56, or pull the widest parts in to x <= 0.88 / z <= 0.88 m [fixes.json #4] _(from R10 Footprint vs selection radius)_
6. **Vertices** (WARN): B4 3430 -> 2453 (want <= 2500): `Merged` 1385 -> 693 verts; `Merged` 816 -> 531 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #5] _(from B4 Vertices)_

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
| B1a | Authored build parts (before the merge) | INFO | 69 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 28 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 492 of 2716 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.016 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 87 | head top 2.19 m / body_height 1.8 (x1.22) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 1.66 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.98 / z 0.72 m (radius 0.5, from ruin_warden.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1775 px (52 x 57 bbox; 55 m: 918 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 32.5, 10% of the body melts (within dE 15 of the ground); body L* 53.2 C 19.7 vs ground L* 62.2 C 48.8, hue gap n/a (body C* <= 25); top third (world height) dE 27.4, L* 60.4; per-pixel dE 39.1, outline 30.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | **WARN** 35 | worst heath: dE 4.5 (heath dE 4.5, old_wood dE 26.3, riverbank dE 29.4, snow dE 40.8, ash dE 36.6, sand dE 30.4, marsh dE 40.1) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 91 | bar hides 7% of the silhouette (gap -15 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.3 m, 1.3 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +28 (point 1 dL +35, point 2 dL +28, point 3 dL +37; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 4 point(s) above the bloom level 1.2 (median of 3/4/4): Core, MaulRune x2, Merged; soft glows under the bloom (v1 count, luma > 0.4): 7 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Core, MaulRune x2, Merged |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.75 (min 0.63), area kept 89-95% (min 1558 px), frame-to-frame IoU min 0.72; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 61 | points per frame 3/3/2/3/3/3/4/3 (median 3, range 2, 0 frame(s) at 0; at rest 4) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 61% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.03 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 70 | outline complexity 2.21 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 60.4, bottom third L* 39.4 (+21, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.0 at 25 m, 10.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 1385 v / 6 s; Root/Chest/ArmR/Merged 816 v / 4 s; Root/Chest/Head/Merged 287 v / 4 s; Root/Chest/ArmL/Merged 281 v / 3 s; Root/Hips/LegL/Merged 179 v / 2 s; Root/Hips/LegR/Merged 179 v / 2 s; Root/Hips/Merged 143 v / 3 s; Root/Chest/GapLight 77 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 7 in fixes.json (top: B2 12 -> 11 (want <= 10): `GapLight`, `Core` are keep_separate under `Chest`: keep only the animated / toggled one separate)
