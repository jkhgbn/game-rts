# Art Lab scorecard: ruin_warden

Scene `res://art/units/neutral/ruin_warden.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-30 14:41:14 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.6) (previous run 91, +2)

0 FAIL · 2 WARN · 26 PASS · 19 info · 0 skipped · 24 s

## Before / after (vs the run of 2026-09-30 11:43:55 in `docs/art/lab/_champ_neutral/before/ruin_warden`: quality 87 -> 93, +6)
### What got worse (1)
1. **P1 Silhouette hook: INFO 71 -> INFO 66 (-5)**. Now: outline complexity 2.15. Was: outline complexity 2.22

### What got better (8)
B2 Draw instances at rest: FAIL 10 -> PASS 87 (+77); R4 Contrast on the other grounds: WARN 35 -> PASS 77 (+42); R8 Head height vs body_height: PASS 87 -> PASS 100 (+13); C3 Palette depth (close-up): INFO 88 -> INFO 100 (+13); R7 HP bar over the body at 40 m: PASS 91 -> PASS 98 (+7); R3 Contrast vs ground (meadow): PASS 93 -> PASS 98 (+5); S1 Style bible: golden autumn (style-autumn.md 3): INFO 29 -> INFO 41 (+12); R12 Contrast under every light preset (meadow): PASS 92 -> PASS 98 (+6)

gone R8w Parts above body_height + 0.4 (was WARN)

### Score delta per check (12 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B2 | Draw instances at rest | FAIL 10 | PASS 87 | +77.4 |
| C1 | Shape richness (secondary shapes) | INFO 74 | INFO 75 | +0.7 |
| R8 | Head height vs body_height | PASS 87 | PASS 100 | +13.1 |
| C3 | Palette depth (close-up) | INFO 88 | INFO 100 | +12.5 |
| R3 | Contrast vs ground (meadow) | PASS 93 | PASS 98 | +4.5 |
| R4 | Contrast on the other grounds | WARN 35 | PASS 77 | +42.1 |
| R7 | HP bar over the body at 40 m | PASS 91 | PASS 98 | +6.8 |
| P1 | Silhouette hook | INFO 71 | INFO 66 | -5.3 |
| R5c | Glow points stand out (1 m surround) | PASS 95 | PASS 91 | -4.0 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 92 | PASS 98 | +6.0 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 29 | INFO 41 | +12.3 |
| R5w | Glow points while walking (flicker) | PASS 85 | PASS 93 | +7.5 (noisy) |

Changed pixels per shot: z40 1.5 %, z55 1.1 %, z25 2.8 %, close 8.3 %, strike_side 7.7 %, turns 4.4 %, cast 2.6 %, anim 3.1 %, silhouette 0.1 %, lineup 6.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.5 -> 0.56, or pull the widest parts in to x <= 0.88 / z <= 0.88 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Vertices** (WARN): B4 3430 -> 2453 (want <= 2500): `Merged` 1462 -> 731 verts; `Merged` 863 -> 617 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 47% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.89): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Contrast on the other grounds** (PASS): On heath the body drops to dE 11.7: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.15): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 23.6): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 32 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Chest 2, (root) 1, ArmL 1, ArmR 1, Head 1, Hips 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | PASS 87 | 10 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 3430 (biggest: Merged 1462, Merged 863, Merged 287, Merged 281) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 10 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Motes) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 6 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 3 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 492 of 2716 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.04 ms process, render CPU +0.77 ms, GPU +0.36 ms) | <= 0.005 ms per instance (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.017 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 2.19 m / body_height 2.2 (x1.0) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.98 / z 0.72 m (radius 0.5, from ruin_warden.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1772 px (52 x 57 bbox; 55 m: 918 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 98 | mean-colour dE 40.0, 9% of the body melts (within dE 15 of the ground); body L* 51.0 C 13.0 vs ground L* 62.2 C 48.8, hue gap n/a (body C* <= 25); top third (world height) dE 32.9, L* 58.6; per-pixel dE 46.6, outline 37.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 77 | worst heath: dE 11.7 (heath dE 11.7, old_wood dE 25.6, riverbank dE 31.7, snow dE 40.7, ash dE 30.9, sand dE 35.2, marsh dE 35.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -9 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.3 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +5 (point 1 dL +38, point 2 dL +31, point 3 dL +39, point 4 dL +5, point 5 dL +29; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 5/3/3): Core, Merged x2; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 98 | worst night: dE 28.7, dL +0 (warm dE 39.7, ice dE 38.5, night dE 28.7, autumn dE 35.3); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 94 | walk frames vs rest: mean IoU 0.74 (min 0.63), area kept 89-95% (min 1559 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 3/2/3/3/3/3/4/3 (median 3, range 2, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (gloomcap_elder 0.6, stormbottle_genie 0.53, bramblehorn 0.41, tracker 0.39, rime_seer 0.33, magpie 0.26) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.54 m from the body centre at t 0.14 s (1.31 m forward; geometry clipped at the ground); declared 1.6 m (UnitType attack_range (ruin_warden.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 62% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 35% of the silhouette at its peak (t 0.25 s; 0.12 s 33%, 0.25 s 35%, 0.4 s 35%, 0.6 s 22%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 75 | 67 shapes over 7 body parts (9.6 per part: LegL 5, LegR 5, Hips 4, Head 7, ArmL 5, ArmR 15, Chest 26); 47% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.894 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 137% of the 2500 verts budget used (3426) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 5.32 at the close-up (115186 px), 3.78 at 25 m; close-up outline complexity 3.89 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 66 | outline complexity 2.15 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 58.6, bottom third L* 36.1 (+22, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.1 at 25 m, 11.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 41 | on the autumn floor: dE 23.6, 11% melts; body L* 48.5 C 19.1 vs floor L* 51.0 C 42.5 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 1462 v / 7 s; Root/Chest/ArmR/Merged 863 v / 4 s; Root/Chest/Head/Merged 287 v / 4 s; Root/Chest/ArmL/Merged 281 v / 3 s; Root/Hips/LegL/Merged 179 v / 2 s; Root/Hips/LegR/Merged 179 v / 2 s; Root/Hips/Merged 143 v / 3 s; Root/Chest/Core 32 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 9 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R10: raise UnitType.radius 0.5 -> 0.56, or pull the widest parts in to x <= 0.88 / z <= 0.88 m)
