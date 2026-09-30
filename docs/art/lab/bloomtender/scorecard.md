# Art Lab scorecard: bloomtender

Scene `res://art/units/nature/bloomtender.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-30 09:54:14 · lab v3.1

## Result: **WARN** · quality **91 / 100** (91.4) (previous run 92, -1)

0 FAIL · 3 WARN · 31 PASS · 17 info · 0 skipped · 30 s

## Before / after (vs the run of 2026-09-26 22:56:44 in `docs/art/lab/bloomtender`: quality 92 -> 91, -1)
### What got worse (2)
1. **P2 Asymmetric secondary shape: INFO 100 -> INFO 88 (-12)**. Now: front-view asymmetry 0.18. Was: front-view asymmetry 0.24
2. **R2 Distinct from references (black masks): PASS 98 -> PASS 95 (-3)**. Now: max IoU 0.53 (greenheart_oathkeeper 0.53, greenheart_oathkeeper_placeholder 0.51, ruin_warden 0.47, gloomcap_elder 0.46, wildwood_archer 0.3, bramblehorn 0.29). Was: max IoU 0.48 (ruin_warden 0.48, gloomcap_elder 0.46, sprigling 0.39, glade_outrider 0.37, bramblehorn 0.29, mossback 0.1

### What got better (3)
R3 Contrast vs ground (meadow): PASS 83 -> PASS 90 (+7); B4 Vertices: PASS 87 -> PASS 93 (+7); B1 Meshes after the kit merge: PASS 95 -> PASS 100 (+5)

new B1a Authored build parts (before the merge) (INFO); new B11 Surfaces per instance (INFO); new B12 Downward-facing triangles (INFO); new C1 Shape richness (secondary shapes) (INFO); new C2 Vertex use vs budget (INFO); new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (old_wood) (PASS); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (WARN); new A3r Weapon reach at the strike (INFO); new R5c Glow points stand out (1 m surround) (PASS); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new R5w Glow points while walking (flicker) (PASS); new A4 Cast pose reads (play_cast) (INFO)

### Score delta per check (8 changed, 29 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 95 | PASS 100 | +5.1 |
| B4 | Vertices | PASS 87 | PASS 93 | +6.7 |
| R8 | Head height vs body_height | WARN 42 | WARN 41 | -0.8 |
| R3 | Contrast vs ground (meadow) | PASS 83 | PASS 90 | +7.2 |
| A3 | Attack reads at 40 m | PASS 99 | PASS 97 | -2.0 (noisy) |
| P2 | Asymmetric secondary shape | INFO 100 | INFO 88 | -12.1 |
| R2 | Distinct from references (black masks) | PASS 98 | PASS 95 | -3.5 |
| B13 | Frame cost | PASS 100 | PASS 98 | -2.1 (noisy) |

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 1.6 -> 2.26 in res://art/units/nature/bloomtender.tscn (root) and res://data/units/bloomtender.tres (the head top; x1.41 now), or lower the head / crest 0.26 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.43 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 20.1): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 9 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 12.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 16.0): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Censer 1, Chest 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 93 | 2082 (body + face above its allowance: face 408 v, allowance 600, total 2490; biggest: HatMesh 584, Merged 476, Face 408, Pod 352) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 5 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 528 of 3894 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 98 | 0.0024 ms process per instance (100 animated at 40 m: +0.24 ms process, render CPU +1.36 ms, GPU +0.27 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.034 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 41 | head top 2.26 m / body_height 1.6 (x1.41) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.43 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | PASS 100 | x 0.62 / z 0.61 m (radius 0.45, from bloomtender.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 910 px (30 x 47 bbox; 55 m: 471 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 90 | mean-colour dE 28.9, 2% of the body melts (within dE 15 of the ground); body L* 62.9 C 26.1 vs ground L* 63.0 C 48.0, hue gap 31 deg; top third (world height) dE 41.8, L* 79.6; per-pixel dE 45.1, outline 43.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 36.7, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 78 | worst heath: dE 12.2 (heath dE 12.2, old_wood dE 36.7, riverbank dE 39.8, snow dE 36.3, ash dE 47.0, sand dE 18.9, marsh dE 49.7) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 40% of body pixels change between kingdom colours (min pair 39%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 97 | worst nature colour: dE 29.0 (fire 51.5, shadow 65.6, ice 43.8, nature 29.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 40 | worst pair fire / nature (deutan): dE 20.1 on the team-colour area (normal vision 68.9; 373 px); deutan: fire / nature dE 20.1; protan: fire / nature dE 28.3; worst vs ground: fire colour (deutan) dE 9.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -9 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +30 (point 1 dL +32, point 2 dL +30, soft 1 dL +32 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/1): Pod, HatMesh; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 89 | worst night: dE 21.6, dL +10 (warm dE 28.7, ice dE 25.5, night dE 21.6, autumn dE 26.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.86 (min 0.83), area kept 100-103% (min 928 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 2/2/2/2/2/1/2/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 95 | max IoU 0.53 (greenheart_oathkeeper 0.53, greenheart_oathkeeper_placeholder 0.51, ruin_warden 0.47, gloomcap_elder 0.46, wildwood_archer 0.3, bramblehorn 0.29) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.31 m from the body centre at t 0.24 s (1.27 m forward; geometry clipped at the ground); declared 7.0 m (UnitType attack_range (bloomtender.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 26% of the silhouette at its peak (t 0.6 s; 0.12 s 25%, 0.25 s 26%, 0.4 s 26%, 0.6 s 26%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 91 | 74 shapes over 7 body parts (10.6 per part: Hips 15, Head 20, Hat 16, ArmL 2, Censer 8, ArmR 6, Chest 7); 12% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.899 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 2500 verts budget used (2486) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 70 | 10 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 1.92 at the close-up (90823 px), 1.43 at 25 m; close-up outline complexity 8.41 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.74 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 79.6, bottom third L* 43.3 (+36, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.2 at 25 m, 9.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 25 | on the autumn floor: dE 16.0, 3% melts; body L* 60.4 C 29.6 vs floor L* 51.9 C 43.0; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 88 | front-view asymmetry 0.18 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
`{"draw":14,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Hat/HatMesh 584 v / 6 s; Root/Hips/Merged 476 v / 3 s; Root/Chest/Head/Face 408 v / 1 s; Root/Chest/ArmR/Censer/Pod 352 v / 4 s; Root/Chest/ArmR/Merged 236 v / 5 s; Root/Chest/Merged 217 v / 3 s; Root/Chest/Head/Merged 131 v / 2 s; Root/Chest/ArmL/Merged 82 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: R8: body_height 1.6 -> 2.26 in res://art/units/nature/bloomtender.tscn (root) and res://data/units/bloomtender.tres (the head top; x1.41 now), or lower the head)
