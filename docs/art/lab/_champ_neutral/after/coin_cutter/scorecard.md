# Art Lab scorecard: coin_cutter

Scene `res://art/units/champions/coin_cutter/coin_cutter.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-30 14:39:54 · lab v3.1

## Result: **WARN** · quality **95 / 100** (95.1) (previous run 95, +0)

0 FAIL · 1 WARN · 28 PASS · 18 info · 0 skipped · 25 s

## Before / after (vs the run of 2026-09-30 11:42:34 in `docs/art/lab/_champ_neutral/before/coin_cutter`: quality 90 -> 95, +5)
### What got worse (0)
Nothing got worse.

### What got better (6)
B8 Unique materials: FAIL 0 -> PASS 89 (+89); R5 Glow points at 40 m: WARN 49 -> PASS 100 (+51) (noisy check: re-run before acting); C3 Palette depth (close-up): INFO 57 -> INFO 90 (+33); R4 Contrast on the other grounds: PASS 92 -> PASS 99 (+7); P3 Tops light, bottoms dark: INFO 19 -> INFO 26 (+7); S1 Style bible: golden autumn (style-autumn.md 3): INFO 66 -> INFO 80 (+15)

new R5w Glow points while walking (flicker) (PASS)

### Score delta per check (8 changed, 40 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | FAIL 0 | PASS 89 | +88.8 |
| C3 | Palette depth (close-up) | INFO 57 | INFO 90 | +32.5 |
| R4 | Contrast on the other grounds | PASS 92 | PASS 99 | +7.1 |
| P3 | Tops light, bottoms dark | INFO 19 | INFO 26 | +7.4 |
| P4 | Detail density 25 m / 40 m | INFO 70 | INFO 75 | +5.2 (noisy) |
| R5 | Glow points at 40 m | WARN 49 | PASS 100 | +51.4 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 66 | INFO 80 | +14.5 |
| R2 | Distinct from references (black masks) | PASS 84 | PASS 84 | -0.8 |

Changed pixels per shot: z40 0.9 %, z55 0.8 %, z25 1.2 %, close 6.8 %, strike_side 11.1 %, turns 3.9 %, cast 4.0 %, anim 2.5 %, silhouette 4.9 %, lineup 14.6 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertices** (WARN): B4 3157 -> 2992 (want <= 3000): `Merged` 682 -> 517 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +0 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.7): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.0): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Head 3, Hips 2, (root) 1, ArmL 1, ArmR 1, Chest 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 11 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 49 | 3157 (body + face above its allowance: face 672 v, allowance 900, total 3829; biggest: Merged 682, Face 672, Merged 456, Merged 447) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | PASS 89 | 5 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B1a | Authored build parts (before the merge) | INFO | 19 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 12 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 570 of 5204 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.03 ms process, render CPU +0.34 ms, GPU +0.32 ms) | <= 0.005 ms per instance (champions.md 4 / 13, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 95 | head top 1.84 m / body_height 1.7 (x1.08) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R10 | Footprint vs selection radius | INFO | x 0.56 / z 0.47 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 599 px (26 x 46 bbox; 55 m: 308 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 62.9, 0% of the body melts (within dE 15 of the ground); body L* 39.4 C 30.6 vs ground L* 62.1 C 48.4, hue gap 93 deg; top third (world height) dE 63.0, L* 30.1; per-pixel dE 74.2, outline 62.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 99 | worst ash: dE 29.4 (heath dE 29.9, old_wood dE 38.7, riverbank dE 56.2, snow dE 58.4, ash dE 29.4, sand dE 52.3, marsh dE 30.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 5% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +32 (point 1 dL +32; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): CoinSparks; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 38.2, dL -7 (warm dE 62.8, ice dE 60.9, night dE 38.2, autumn dE 57.2); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.77 (min 0.73), area kept 93-97% (min 556 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 84 | max IoU 0.7 (tracker 0.7, ember_archer 0.68, rimeshield 0.58, gloomcap_elder 0.4, stormbottle_genie 0.38, ruin_warden 0.34) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.85 m from the body centre at t 0.24 s (0.71 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 51% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 66% of the silhouette at its peak (t 0.25 s; 0.12 s 26%, 0.25 s 66%, 0.4 s 61%, 0.6 s 11%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 95 shapes over 7 body parts (13.6 per part: LegL 5, LegR 5, Hips 26, Head 30, ArmL 8, ArmR 8, Chest 13); 33% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.922 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 127% of the 3000 verts budget used (3825) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 90 | 12 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.14 at the close-up (90618 px), 1.83 at 25 m; close-up outline complexity 4.91 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.99 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 26 | top third L* 30.1, bottom third L* 30.7 (+0, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 75 | inner detail 12.0 at 25 m, 16.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 80 | on the autumn floor: dE 33.7, 2% melts; body L* 37.9 C 35.3 vs floor L* 51.2 C 42.5 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.39 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"face_verts":900,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 682 v / 2 s; Root/Chest/Head/Face 672 v / 1 s; Root/Chest/Head/Merged 456 v / 1 s; Root/Hips/Merged 447 v / 1 s; Root/Chest/ArmL/Merged 381 v / 1 s; Root/Chest/ArmR/Merged 381 v / 1 s; Root/Hips/LootSack 267 v / 1 s; Root/Hips/LegL/Merged 189 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: B4 3157 -> 2992 (want <= 3000): `Merged` 682 -> 517 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
