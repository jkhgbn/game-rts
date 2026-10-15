# Art Lab scorecard: thornback_charger

Scene `res://art/units/nature/thornback_charger/thornback_charger.tscn` · kind **unit** / tier **cavalry_mounted** · kingdom nature · ground meadow · 2026-10-15 16:49:42 · lab v3.1

## Result: **WARN** · quality **94 / 100** (94.4) (previous run 100, -6)

0 FAIL · 1 WARN · 30 PASS · 15 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-10-15 16:43:22 in `docs/art/lab/thornback_charger`: quality 100 -> 94, -6)
### What got worse (0)
Nothing got worse.

new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (old_wood) (PASS); new R4 Contrast on the other grounds (PASS); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (PASS); new R7 HP bar over the body at 40 m (PASS); new A3r Weapon reach at the strike (INFO); new A3 Attack reads at 40 m (PASS); new P1 Silhouette hook (INFO); new P3 Tops light, bottoms dark (INFO); new P4 Detail density 25 m / 40 m (INFO); new R5c Glow points stand out (1 m surround) (PASS); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new A4 Cast pose reads (play_cast) (INFO); new P2 Asymmetric secondary shape (INFO)

### Score delta per check (6 changed, 28 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R1 | Silhouette area at 40 m | SKIP  | PASS 100 | +0.0 |
| R3 | Contrast vs ground (meadow) | SKIP  | PASS 97 | +0.0 |
| R6 | Team-colour visibility at 40 m | SKIP  | PASS 88 | +0.0 |
| R5 | Glow points at 40 m | SKIP  | WARN 49 | +0.0 (noisy) |
| R2 | Distinct from references (black masks) | SKIP  | PASS 89 | +0.0 |
| B13 | Frame cost | SKIP  | PASS 100 | +0.0 (noisy) |

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 0 -> 1 (want 1-3): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 9.4): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.1: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 15% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
5. **Distinct from references (black masks)** (PASS): Make it read apart from stagrunner (IoU 0.61): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
6. **Contrast under every light preset (meadow)** (PASS): Under the night light the body drops to dE 18.8: add a value step (light top / pale crest) that survives a dim light _(from R12 Contrast under every light preset (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 35 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmR 2, ArmL 1, Chest 1, Elk 1, Head 1, Hips 1 | <= 32 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 20 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 12 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B4 | Vertices | PASS 100 | 4513 (body + face above its allowance: face 970 v, allowance 1200, total 5483; biggest: Merged 1279, Merged 1158, Merged 1060, Merged 326) | <= 8500 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6 | Particle systems | PASS 94 | 1 | <= 1 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/cavalry_mounted |  |
| B1a | Authored build parts (before the merge) | INFO | 6 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 32 |  |
| B11 | Surfaces per instance | INFO | 56 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 645 of 7366 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.002 ms process per instance (100 animated at 40 m: +0.2 ms process, render CPU +1.66 ms, GPU +0.7 ms) | <= 0.01 ms per instance (cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.002 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.88 / z 1.73 m (radius 0.7, from thornback_charger.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1680 px (54 x 62 bbox; 55 m: 861 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 97 | mean-colour dE 36.3, 1% of the body melts (within dE 15 of the ground); body L* 53.4 C 28.9 vs ground L* 62.0 C 48.7, hue gap 45 deg; top third (world height) dE 33.4, L* 61.7; per-pixel dE 46.1, outline 38.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 32.1, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 76 | worst heath: dE 11.1 (heath dE 11.1, old_wood dE 32.1, riverbank dE 39.2, snow dE 45.3, ash dE 40.5, sand dE 28.1, marsh dE 41.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 88 | 15% of body pixels change between kingdom colours (min pair 15%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 35.9 (fire 43.0, shadow 48.1, ice 39.8, nature 35.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 22.1 on the team-colour area (normal vision 58.6; 259 px); deutan: fire / nature dE 22.1; protan: fire / nature dE 26.1; worst vs ground: fire colour (deutan) dE 13.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 4% of the silhouette (gap -6 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.9 m, 1.82 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +4 (soft 1 dL +17 (counts), soft 2 dL +4 (counts), soft 3 dL +49 (counts), soft 4 dL +28 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 4; + 4 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 86 | worst night: dE 18.8, dL +4 (warm dE 36.4, ice dE 32.0, night dE 18.8, autumn dE 33.3); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.83 (min 0.78), area kept 98-105% (min 1639 px), frame-to-frame IoU min 0.84; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.61 (stagrunner 0.61, glade_outrider 0.6, hollow_stag 0.53, mossback 0.35, stormbottle_genie 0.34, briar_roc 0.26) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.14 m from the body centre at t 0.08 s (2.03 m forward; geometry clipped at the ground); declared 1.9 m (UnitType attack_range (thornback_charger.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 30% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.4 s; 0.12 s 11%, 0.25 s 11%, 0.4 s 12%, 0.6 s 12%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 160 shapes over 10 body parts (16.0 per part: Head 36, LegFL 5, LegFR 5, LegBL 5, LegBR 5, Mount 28, Hips 12, ArmL 7, ArmR 10, Chest 47); 24% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.949 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 98 | 64% of the 8500 verts budget used (5479) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.46 at the close-up (55341 px), 2.84 at 25 m; close-up outline complexity 7.63 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.48 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 61.7, bottom third L* 42.9 (+18, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 99 | inner detail 11.0 at 25 m, 15.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 4 | on the autumn floor: dE 9.4, 6% melts; body L* 51.5 C 34.3 vs floor L* 50.5 C 42.1 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.27 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene))
`{"draw":20,"face_verts":1200,"frame_ms":0.01,"lights":0,"meshes":32,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":6,"separate":12,"verts":8500},"src":"cavalry-mounts.md 10 (cavalry rider 12 + mount 8 draws, one scene)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Elk/Root/Mount/Merged 1279 v / 7 s; Rider/Root/Chest/Merged 1158 v / 9 s; Elk/Root/Mount/Head/Merged 1060 v / 7 s; Elk/Root/Mount/LegBL/Merged 326 v / 3 s; Elk/Root/Mount/LegBR/Merged 326 v / 3 s; Elk/Root/Mount/LegFL/Merged 317 v / 3 s; Elk/Root/Mount/LegFR/Merged 317 v / 3 s; Rider/Root/Hips/Merged 282 v / 5 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: Glow points 0 -> 1 (want 1-3): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= )
