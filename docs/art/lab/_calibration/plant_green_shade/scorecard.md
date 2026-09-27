# Art Lab scorecard: plant_green_shade

Scene `res://tools/art_lab/calibration/virtual/plant_green_shade.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-09-27 14:19:51 · lab v3.1

## Result: **FAIL** · quality **80 / 100** (79.5)

1 FAIL · 3 WARN · 25 PASS · 16 info · 0 skipped · 24 s

## Improve next
1. **Contrast vs ground (meadow)** (FAIL): albedo_color of `StandardMaterial3D#-38053` #8cb847 -> #fffa7f (98% of the visible body): predicted dE R3 meadow 8.4 -> 29.1, R3t fire 8.4 -> 29.1, R3t shadow 8.2 -> 29.1, R3t ice 8.2 -> 29.1, R3t nature 8.4 -> 29.1, R4k marsh 72.2 -> 82.3 (want >= 29); other grounds heath 51.6, old_wood 66.6, riverbank 63.9, snow 48.4, ash 81.4, sand 20.5; built in code or embedded: change it where the model script creates it [fixes.json #1] _(from R3 Contrast vs ground (meadow), shot z40)_
2. **Team-colour visibility at 40 m** (WARN): R6 Team-colour visibility at 40 m: Give the team colour more top-facing area (now 0% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top [fixes.json #2] _(from R6 Team-colour visibility at 40 m, shot teams)_
3. **Contrast in every team colour (meadow)** (WARN): In the shadow team colour the body drops to dE 8.2 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players shadow / ice (deutan) look alike on this model (dE 0.2): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Palette depth (close-up)** (INFO): Flat palette (7 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
6. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: only 3.4 shapes per body part (aim >= 7): add secondary / tertiary shapes (straps, plates, bark ridges, cuffs, knuckles, a collar) on LegL, LegR, Hips; few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Chest 2, (root) 1, ArmL 1, ArmR 1, Head 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1313 (biggest: Merged 295, Merged 253, Merged 229, Merged 215) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 5 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 26 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 17 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 206 of 1596 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 92 | head top 1.82 m / body_height 1.6 (x1.14) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.64 / z 0.33 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 487 px (31 x 34 bbox; 55 m: 255 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | **FAIL** 2 | mean-colour dE 8.4, 36% of the body melts (within dE 15 of the ground); body L* 70.6 C 52.0 vs ground L* 63.3 C 48.0, hue gap 0 deg; top third (world height) dE 12.1, L* 74.6; per-pixel dE 19.4, outline 27.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass | Melts into the meadow: value is close to the ground (dL +7): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 0 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 72.2, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst sand: dE 30.2 (heath dE 46.3, old_wood dE 52.7, riverbank dE 45.1, snow dE 54.1, ash dE 72.1, sand dE 30.2, marsh dE 72.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | **WARN** 36 | 0% of body pixels change between kingdom colours (min pair 0%) | >= 8% (FAIL = set_team_color changes nothing) | Put the team colour on a big, top-facing mass (cloth, plates, cape, caparison); ~25-45 %% of the surface (art-keep 0.2 / art-units 1.3) |
| R3t | Contrast in every team colour (meadow) | **WARN** 38 | worst shadow colour: dE 8.2 (fire 8.4, shadow 8.2, ice 8.2, nature 8.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair shadow / ice (deutan): dE 0.2 on the team-colour area (normal vision 0.4; 6 px); deutan: shadow / ice dE 0.2; protan: shadow / ice dE 0.3; worst vs ground: shadow colour (deutan) dE 8.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 0 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 84 | worst dL +15 (point 1 dL +15; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 86 | walk frames vs rest: mean IoU 0.59 (min 0.53), area kept 81-86% (min 401 px), frame-to-frame IoU min 0.58; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 80 | points per frame 2/2/2/0/1/0/2/2 (median 2, range 2, 2 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.47 m from the body centre at t 0.08 s (1.42 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 69% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 27% of the silhouette at its peak (t 0.4 s; 0.12 s 24%, 0.25 s 26%, 0.4 s 27%, 0.6 s 26%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 33 | 24 shapes over 7 body parts (3.4 per part: LegL 2, LegR 2, Hips 1, Head 4, ArmL 4, ArmR 5, Chest 6); 38% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.838 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 64 | 52% of the 2500 verts budget used (1309) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 25 | 7 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 77 | inner edges per outline px: 2.31 at the close-up (95746 px), 1.21 at 25 m; close-up outline complexity 4.99 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.8 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 73 | top third L* 74.6, bottom third L* 67.2 (+7, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.0 at 25 m, 9.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Merged 295 v / 3 s; Root/Chest/ArmR/Merged 253 v / 3 s; Root/Chest/ArmL/Merged 229 v / 2 s; Root/Chest/Head/Merged 215 v / 4 s; Root/Hips/LegL/Merged 132 v / 1 s; Root/Hips/LegR/Merged 132 v / 1 s; Root/Hips/Merged 37 v / 1 s; Root/Chest/Cape 16 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: albedo_color of `StandardMaterial3D#-38053` #8cb847 -> #fffa7f (98% of the visible body): predicted dE R3 meadow 8.4 -> 29.1, R3t fire 8.4 -> 29.1, R3t shadow 8)
