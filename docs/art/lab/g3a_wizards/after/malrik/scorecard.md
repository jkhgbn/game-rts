# Art Lab scorecard: malrik

Scene `res://art/units/wizards/malrik.tscn` · kind **unit** / tier **wizard** · kingdom shadow · ground meadow · 2026-10-15 10:31:02 · lab v3.1

## Result: **WARN** · quality **90 / 100** (90.4) (previous run 90, +0)

0 FAIL · 4 WARN · 29 PASS · 18 info · 0 skipped · 131 s

## Before / after (vs the run of 2026-10-15 10:27:30 in `docs/art/lab/g3a_wizards/after/malrik`: quality 90 -> 90, +0)
### What got worse (0)
Nothing got worse.

### What got better (2)
P1 Silhouette hook: INFO 92 -> INFO 100 (+8); R5c Glow points stand out (1 m surround): WARN 47 -> WARN 54 (+6) (noisy check: re-run before acting)

### Score delta per check (3 changed, 49 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| P1 | Silhouette hook | INFO 92 | INFO 100 | +8.1 |
| P4 | Detail density 25 m / 40 m | INFO 7 | INFO 5 | -2.3 (noisy) |
| R5c | Glow points stand out (1 m surround) | WARN 47 | WARN 54 | +6.2 (noisy) |

Changed pixels per shot: z40 0.4 %, z55 0.4 %, z25 0.8 %, close 4.2 %, strike_side 5.4 %, turns 4.8 %, cast 5.5 %, anim 4.7 %, silhouette 0.6 %, lineup 12.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (WARN): B4 4296 -> 2937 (want <= 3000): `Merged` 997 -> 499 verts; `Merged` 918 -> 459 verts; `Merged` 805 -> 403 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 1.18 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Looping particle systems** (WARN): B6l Looping particle systems: Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) [fixes.json #3] _(from B6l Looping particle systems)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL -4): darken around them or raise the energy [fixes.json #4] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (14.8): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
6. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 61% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.9): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 28 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Head 2, Hips 2, (root) 1, ArmL 1, ArmR 1, CapePivot 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 4296 (body + face above its allowance: face 1227 v, allowance 2200, total 5523; biggest: Face 1227, Merged 997, Merged 918, Merged 805) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (ShardLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 5 | no budget for unit/wizard |  |
| B6l | Looping particle systems | **WARN** 41 | 2 (VoidMotes, ShadowMist) | <= 1 soft (art-units.md 8 (wizard)) | Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 21 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 11 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 32 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 727 of 7894 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0012 ms process per instance (100 animated at 40 m: +0.12 ms process, render CPU +1.19 ms, GPU +2.03 ms) | <= 0.005 ms per instance (art-units.md 8 (wizard)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.044 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 77 | head top 2.77 m / body_height 2.0 (x1.38) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 1.18 m | narrower than 0.7 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.75 / z 0.8 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1044 px (35 x 54 bbox; 55 m: 540 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 100.4, 0% of the body melts (within dE 15 of the ground); body L* 49.2 C 52.3 vs ground L* 61.9 C 48.6, hue gap 161 deg; top third (world height) dE 91.9, L* 64.9; per-pixel dE 104.1, outline 70.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 63.6, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 54.5 (heath dE 70.0, old_wood dE 75.6, riverbank dE 86.7, snow dE 67.2, ash dE 54.5, sand dE 82.8, marsh dE 63.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 54% of body pixels change between kingdom colours (min pair 50%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 46.3 (fire 71.7, shadow 99.2, ice 71.6, nature 46.3) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.0 on the team-colour area (normal vision 68.2; 586 px); deutan: fire / nature dE 11.0; protan: fire / nature dE 19.8; worst vs ground: fire colour (deutan) dE 34.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 4% of the silhouette (gap -12 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 54 | worst dL -4 (point 1 dL +21, point 2 dL -4, point 3 dL +42; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): ShardMesh, Merged, Face; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 88.0, dL +8 (warm dE 99.9, ice dE 90.1, night dE 88.0, autumn dE 93.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 89 | walk frames vs rest: mean IoU 0.66 (min 0.64), area kept 98-100% (min 1053 px), frame-to-frame IoU min 0.91; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 2/3/3/3/3/3/3/3 (median 3, range 1, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.65 (shadow_knight 0.65, torvald 0.62, vessa 0.61, stormbottle_genie 0.49, veilborn_dreadrider 0.48, hollow_stag 0.35) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.07 m from the body centre at t 0.08 s (2.0 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 36% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 47% of the silhouette at its peak (t 0.4 s; 0.12 s 31%, 0.25 s 46%, 0.4 s 47%, 0.6 s 38%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 61 | 128 shapes over 8 body parts (16.0 per part: Hips 32, Head 46, ArmL 6, Staff 14, Shard 3, ArmR 3, CapePivot 1, Chest 23); 61% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.896 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 183% of the 3000 verts budget used (5519) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.29 at the close-up (68939 px), 3.51 at 25 m; close-up outline complexity 10.03 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.67 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 64.9, bottom third L* 33.8 (+31, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 5 | inner detail 14.8 at 25 m, 19.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 76.3, 0% melts; body L* 47.7 C 49.2 vs floor L* 50.6 C 42.2; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.24 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (wizard))
`{"draw":16,"face_verts":2200,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 1227 v / 1 s; Root/Chest/Head/Merged 997 v / 7 s; Root/Hips/Merged 918 v / 6 s; Root/Chest/Merged 805 v / 5 s; Root/Chest/ArmR/Staff/StaffMesh 601 v / 2 s; Root/Chest/ArmL/Merged 349 v / 2 s; Root/Chest/ArmR/Merged 286 v / 2 s; Root/Chest/ArmR/Staff/Shard/ShardMesh 215 v / 3 s
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: B4 4296 -> 2937 (want <= 3000): `Merged` 997 -> 499 verts; `Merged` 918 -> 459 verts; `Merged` 805 -> 403 verts (fewer segments: cylinders 6-8, spheres 10 x 5; )
