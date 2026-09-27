# Art Lab scorecard: wildcaller

Scene `res://art/units/champions/wildcaller/wildcaller.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-27 10:31:22 · lab v2.0

## Result: **FAIL** · quality **87 / 100**

1 FAIL · 3 WARN · 23 PASS · 10 info · 0 skipped · 24 s

## Improve next
1. **Unique materials** (FAIL): B8 13 -> 5 materials: use one material for look-alike pairs: `StandardMaterial3D#-73732` -> `StandardMaterial3D#-63632` (dE 0.0), `StandardMaterial3D#-63632` -> `StandardMaterial3D#-95199` (dE 0.0), `nature_bark` -> `nature_bark_dark` (dE 22.6), `nature_stone` -> `nature_skin` (dE 24.5), `nature_leaf_dark` -> `nature_bark_dark` (dE 41.0), `nature_blossom` -> `nature_skin` (dE 47.6), `nature_skin` -> `nature_bark_dark` (dE 58.1), `StandardMaterial3D#-68682` -> `StandardMaterial3D#-95199` (dE 191.1) [fixes.json #1] _(from B8 Unique materials)_
2. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `nature_stone` #85806b -> #85806a (14% of the visible body): predicted dE R3 meadow 35.0 -> 34.9 (want >= 24); other grounds heath 6.2, old_wood 20.5, riverbank 27.0, snow 45.9, ash 31.3, sand 36.2, marsh 34.1; shared material (res://art/units/nature/materials/nature_stone.tres): give wildcaller its own copy first, other assets use it too [fixes.json #2] _(from R4 Contrast on the other grounds, shot z40)_
3. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Staff 0.71 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
4. **Vertices** (WARN): B4 26553 -> 13280 (want <= 3000): `Merged` 9415 -> 4708 verts; `Staff` 8598 -> 4299 verts; `Variant` 4614 -> 2307 verts; `Merged` 1668 -> 834 verts; `Merged` 983 -> 492 verts; `Merged` 424 -> 212 verts; `Merged` 287 -> 144 verts; `Merged` 280 -> 140 verts; `Merged` 280 -> 140 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (15.5): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 35.0): raise the value step between the big masses and the ground (dL -14 now) _(from R3 Contrast vs ground (meadow), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: ArmR 2, Head 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 11 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 26553 (biggest: Merged 9415, Staff 8598, Variant 4614, Merged 1668) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (CrownMotes) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | **FAIL** 0 | 13 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 13 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 38 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2931 of 36158 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 85 | head top 2.5 m / body_height 2.0 (x1.25) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Staff 0.71 m | narrower than 0.6 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.92 / z 0.7 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 872 px (41 x 51 bbox; 55 m: 438 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 96 | mean-colour dE 35.0, 0% of the body melts (within dE 15 of the ground); body L* 47.6 C 18.4 vs ground L* 61.9 C 48.7, hue gap n/a (body C* <= 25); top third (world height) dE 40.3, L* 75.2; per-pixel dE 49.3, outline 41.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | **WARN** 35 | worst heath: dE 6.2 (heath dE 6.2, old_wood dE 20.5, riverbank dE 27.0, snow dE 45.9, ash dE 31.2, sand dE 36.3, marsh dE 34.1) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +36 (point 1 dL +36; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): CrownMotes; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.77 (min 0.74), area kept 94-101% (min 819 px), frame-to-frame IoU min 0.75; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 36% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.87 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 75.2, bottom third L* 24.4 (+50, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 15.5 at 25 m, 20.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 9415 v / 5 s; Root/Chest/ArmR/Staff 8598 v / 8 s; Root/Chest/Head/Variant 4614 v / 5 s; Root/Hips/Merged 1668 v / 5 s; Root/Chest/ArmL/Merged 983 v / 4 s; Root/Chest/Head/Merged 424 v / 3 s; Root/Chest/ArmR/Merged 287 v / 3 s; Root/Hips/LegL/Merged 280 v / 2 s
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B8 13 -> 5 materials: use one material for look-alike pairs: `StandardMaterial3D#-73732` -> `StandardMaterial3D#-63632` (dE 0.0), `StandardMaterial3D#-63632` ->)
