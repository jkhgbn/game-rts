# Art Lab scorecard: vinelasher_low

Scene `res://art/units/_effort_trial/low/vinelasher.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-27 14:19:27 · lab v3.1

## Result: **WARN** · quality **87 / 100** (86.9)

0 FAIL · 1 WARN · 28 PASS · 14 info · 0 skipped · 24 s

## Improve next
1. **Contrast on the home ground (old_wood)** (WARN): shader_parameter/base_color of `nature_sec_slinger_c` #bd8038 -> #ffba10 (17% of the visible body): predicted dE R3 meadow 32.1 -> 28.0, R3t fire 51.7 -> 47.1, R3t shadow 66.1 -> 58.0, R3t ice 46.3 -> 41.3, R3t nature 30.9 -> 26.8, R4k old_wood 17.6 -> 24.0 (want >= 24); other grounds heath 19.2, riverbank 30.7, snow 51.1, ash 39.7, sand 32.8, marsh 38.8; `nature_sec_slinger_c` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `nature_sec_slinger_b.tres` (#99b340, dE 48.0 from the wanted colour; no palette entry is close: a new palette entry is needed, or give the asset its own copy); team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `nature_cloth` 20% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4k Contrast on the home ground (old_wood), shot z40)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: only 3.4 shapes per body part (aim >= 7): add secondary / tertiary shapes (straps, plates, bark ridges, cuffs, knuckles, a collar) on LegL, LegR, ArmL, Chest; 57% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.86): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Vertex use vs budget** (INFO): Only 38% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
4. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (1.45 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
5. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 9 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
6. **Contrast on the other grounds** (PASS): On heath the body drops to dE 15.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: ArmR 2, (root) 1, ArmL 1, Chest 1, Head 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 969 (biggest: Merged 261, Merged 175, Merged 126, Merged 101) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 11 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 21 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 184 of 1250 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 98 | head top 1.85 m / body_height 1.8 (x1.03) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.55 / z 0.29 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 363 px (20 x 35 bbox; 55 m: 181 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 32.1, 1% of the body melts (within dE 15 of the ground); body L* 44.3 C 24.7 vs ground L* 63.1 C 47.9, hue gap n/a (body C* <= 25); top third (world height) dE 20.0, L* 54.5; per-pixel dE 49.6, outline 40.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | **WARN** 50 | dE 17.6, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 82 | worst heath: dE 15.4 (heath dE 15.4, old_wood dE 17.6, riverbank dE 25.9, snow dE 50.9, ash dE 32.9, sand dE 37.3, marsh dE 33.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 34% of body pixels change between kingdom colours (min pair 33%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 99 | worst nature colour: dE 30.9 (fire 51.7, shadow 66.1, ice 46.3, nature 30.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 12.7 on the team-colour area (normal vision 75.2; 127 px); deutan: fire / nature dE 12.7; protan: fire / nature dE 24.6; worst vs ground: nature colour (deutan) dE 24.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 1 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.3 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +29 (soft 1 dL +29 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 1; + 1 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 92 | walk frames vs rest: mean IoU 0.7 (min 0.59), area kept 93-99% (min 338 px), frame-to-frame IoU min 0.56; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | PASS 100 | tip reaches 3.23 m from the body centre at t 0.24 s (3.23 m forward; geometry clipped at the ground); declared 3.0 m (reach= (brief)) | the strike frame shows the weapon tip at >= 80% of the declared reach, above the ground (side frames: strike_side.jpg) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 63% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 36% of the silhouette at its peak (t 0.4 s; 0.12 s 35%, 0.25 s 36%, 0.4 s 36%, 0.6 s 17%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 21 | 24 shapes over 7 body parts (3.4 per part: LegL 2, LegR 2, Hips 7, Head 3, ArmL 2, ArmR 6, Chest 2); 57% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.864 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 25 | 38% of the 2500 verts budget used (965) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 70 | 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 38 | inner edges per outline px: 1.45 at the close-up (83900 px), 1.19 at 25 m; close-up outline complexity 8.52 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.94 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 54.5, bottom third L* 9.5 (+44, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.7 at 25 m, 15.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- strike_side: [strike_side.jpg](strike_side.jpg)
- turns: [turns.jpg](turns.jpg)
- cast: [cast.jpg](cast.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/ArmR/Merged 261 v / 4 s; Root/Hips/Merged 175 v / 1 s; Root/Chest/Head/Merged 126 v / 3 s; Root/Chest/Merged 101 v / 2 s; Root/Chest/ArmR/Coil 91 v / 1 s; Root/Chest/ArmL/Merged 79 v / 2 s; Root/Hips/LegL/Merged 66 v / 1 s; Root/Hips/LegR/Merged 66 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 1 in fixes.json (top: shader_parameter/base_color of `nature_sec_slinger_c` #bd8038 -> #ffba10 (17% of the visible body): predicted dE R3 meadow 32.1 -> 28.0, R3t fire 51.7 -> 47.1, )
