# Art Lab scorecard: bramblehorn

Scene `res://art/units/nature/bramblehorn.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-09-30 09:51:36 · lab v3.1

## Result: **WARN** · quality **92 / 100** (92.4) (previous run 89, +3)

0 FAIL · 1 WARN · 31 PASS · 17 info · 0 skipped · 31 s

## Before / after (vs the run of 2026-09-26 23:11:18 in `docs/art/lab/bramblehorn`: quality 89 -> 92, +3)
### What got worse (1)
1. **P1 Silhouette hook: INFO 22 -> INFO 20 (-2)**. Now: outline complexity 1.56. Was: outline complexity 1.59

### What got better (4)
B1 Meshes after the kit merge: FAIL 0 -> PASS 100 (+100); P3 Tops light, bottoms dark: INFO 13 -> INFO 100 (+87); R2 Distinct from references (black masks): PASS 96 -> PASS 100 (+4); R4 Contrast on the other grounds: PASS 77 -> PASS 80 (+3)

new B1a Authored build parts (before the merge) (INFO); new B11 Surfaces per instance (INFO); new B12 Downward-facing triangles (INFO); new C1 Shape richness (secondary shapes) (INFO); new C2 Vertex use vs budget (INFO); new C3 Palette depth (close-up) (INFO); new C4 Inner detail (close-up / 25 m) (INFO); new R4k Contrast on the home ground (old_wood) (PASS); new R3t Contrast in every team colour (meadow) (PASS); new R6cb Team colours for colour-blind players (WARN); new A3r Weapon reach at the strike (INFO); new R5c Glow points stand out (1 m surround) (PASS); new R12 Contrast under every light preset (meadow) (PASS); new S1 Style bible: golden autumn (style-autumn.md 3) (INFO); new R11 Reads while walking (40 m) (PASS); new R5w Glow points while walking (flicker) (PASS); new A4 Cast pose reads (play_cast) (INFO)

### Score delta per check (7 changed, 27 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B1 | Meshes after the kit merge | FAIL 0 | PASS 100 | +100.0 |
| R3 | Contrast vs ground (meadow) | PASS 83 | PASS 84 | +1.0 |
| R4 | Contrast on the other grounds | PASS 77 | PASS 80 | +3.3 |
| P1 | Silhouette hook | INFO 22 | INFO 20 | -2.4 |
| P3 | Tops light, bottoms dark | INFO 13 | INFO 100 | +86.7 |
| R2 | Distinct from references (black masks) | PASS 96 | PASS 100 | +4.1 |
| B13 | Frame cost | PASS 100 | PASS 99 | -0.7 (noisy) |

## Improve next
1. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 12.6): add a value step inside the team-colour area [fixes.json #1] _(from R6cb Team colours for colour-blind players, shot teams)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.56): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
3. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.06): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_
4. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 21.4): value is close to the ground (dL +3): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the top third (what reads from pitch 55) is close to the ground (dE 17.2): lighten helmets / shoulders / back; the body sits in the ground's hue (gap 18 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 14.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 18.2): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: Head 2, (root) 1, LegBL 1, LegBR 1, LegFL 1, LegFR 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 100 | 3593 (body + face above its allowance: face 534 v, allowance 600, total 4127; biggest: Merged 1588, Merged 1123, Face 534, Merged 243) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 7 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 20 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 2 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 28 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 876 of 6131 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 99 | 0.0021 ms process per instance (100 animated at 40 m: +0.21 ms process, render CPU +1.16 ms, GPU +0.43 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.021 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 1.2 / z 1.73 m (radius 0.7, from bramblehorn.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2606 px (70 x 67 bbox; 55 m: 1345 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 84 | mean-colour dE 21.4, 1% of the body melts (within dE 15 of the ground); body L* 66.8 C 31.7 vs ground L* 62.9 C 48.4, hue gap 18 deg; top third (world height) dE 17.2, L* 72.9; per-pixel dE 39.5, outline 36.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 40.8, 0% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 80 | worst heath: dE 14.3 (heath dE 14.3, old_wood dE 40.8, riverbank dE 37.5, snow dE 37.8, ash dE 54.3, sand dE 15.7, marsh dE 56.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 39% of body pixels change between kingdom colours (min pair 38%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 88 | worst nature colour: dE 21.4 (fire 49.0, shadow 64.6, ice 40.9, nature 21.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 36 | worst pair fire / nature (deutan): dE 12.6 on the team-colour area (normal vision 78.0; 1026 px); deutan: fire / nature dE 12.6; protan: fire / nature dE 23.6; worst vs ground: fire colour (deutan) dE 6.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 4% of the silhouette (gap -10 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.82 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +13 (point 1 dL +24, point 2 dL +24, soft 1 dL +13 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Merged x2; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 81 | worst night: dE 14.7, dL +10 (warm dE 21.9, ice dE 20.2, night dE 14.7, autumn dE 19.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.88 (min 0.85), area kept 98-101% (min 2576 px), frame-to-frame IoU min 0.84; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.41 (ruin_warden 0.41, bramble_harrier_placeholder 0.38, stormbottle_genie 0.3, bloomtender 0.29, greenheart_oathkeeper 0.25, wildwood_archer 0.1) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.5 m from the body centre at t 0.08 s (2.5 m forward; geometry clipped at the ground); declared 1.8 m (UnitType attack_range (bramblehorn.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 44% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 4% of the silhouette at its peak (t 0.6 s; 0.12 s 1%, 0.25 s 2%, 0.4 s 3%, 0.6 s 4%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 128 shapes over 6 body parts (21.3 per part: Head 58, LegFL 5, LegFR 5, LegBL 6, LegBR 6, Mount 48); 24% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.976 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 68% of the 6000 verts budget used (4123) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 11 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.33 at the close-up (60306 px), 4.13 at 25 m; close-up outline complexity 2.82 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 20 | outline complexity 1.56 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 72.9, bottom third L* 37.9 (+34, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.2 at 25 m, 8.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 32 | on the autumn floor: dE 18.2, 1% melts; body L* 63.8 C 34.8 vs floor L* 51.4 C 42.6; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 24 | front-view asymmetry 0.06 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"face_verts":600,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 1588 v / 8 s; Root/Mount/Head/Merged 1123 v / 6 s; Root/Mount/Head/Face 534 v / 1 s; Root/Mount/LegBL/Merged 243 v / 3 s; Root/Mount/LegBR/Merged 243 v / 3 s; Root/Mount/LegFL/Merged 196 v / 3 s; Root/Mount/LegFR/Merged 196 v / 3 s; Shadow 4 v / 1 s
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 12.6): add a value step insid)
