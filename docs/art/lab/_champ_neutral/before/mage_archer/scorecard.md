# Art Lab scorecard: mage_archer

Scene `res://art/units/champions/mage_archer/mage_archer.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-30 11:41:41 · lab v3.1

## Result: **FAIL** · quality **93 / 100** (92.7)

1 FAIL · 1 WARN · 27 PASS · 18 info · 0 skipped · 25 s

## Improve next
1. **Unique materials** (FAIL): B8 12 -> 9 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-93568` -> `StandardMaterial3D#-98622` (dE 0.0), `StandardMaterial3D#-63261` -> `StandardMaterial3D#-98622` (dE 0.0), `shadow_skin` -> `shadow_silver` (dE 9.6); 4 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #1] _(from B8 Unique materials)_
2. **Vertices** (WARN): B4 8184 -> 4097 (want <= 3000): `Variant` 2382 -> 1191 verts; `Bow` 1333 -> 667 verts; `Quiver` 1205 -> 603 verts; `Merged` 805 -> 403 verts; `Merged` 592 -> 296 verts; `Merged` 584 -> 292 verts; `Merged` 361 -> 181 verts; `Merged` 345 -> 173 verts; `Merged` 345 -> 173 verts; `Merged` 228 -> 114 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (18.8): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.64): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, Chest 2, (root) 1, ArmL 1, Hips 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 8184 (body + face above its allowance: face 478 v, allowance 900, total 8662; biggest: Variant 2382, Bow 1333, Quiver 1205, Merged 805) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (QuiverMotes) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | **FAIL** 0 | 12 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1107 of 11422 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0003 ms process per instance (100 animated at 40 m: +0.03 ms process, render CPU +0.68 ms, GPU +0.87 ms) | <= 0.005 ms per instance (champions.md 4 / 13, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 98 | head top 2.01 m / body_height 1.95 (x1.03) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R10 | Footprint vs selection radius | INFO | x 0.81 / z 0.55 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 581 px (36 x 41 bbox; 55 m: 290 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 85.4, 0% of the body melts (within dE 15 of the ground); body L* 33.8 C 33.0 vs ground L* 62.8 C 48.1, hue gap 164 deg; top third (world height) dE 87.5, L* 46.3; per-pixel dE 90.6, outline 69.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 31.6 (heath dE 52.8, old_wood dE 53.4, riverbank dE 66.6, snow dE 66.5, ash dE 31.6, sand dE 76.5, marsh dE 41.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.45 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 86 | worst dL +18 (point 1 dL +18, point 2 dL +19; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): QuiverMotes, Bow; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 57.5, dL -4 (warm dE 85.0, ice dE 77.9, night dE 57.5, autumn dE 76.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 96 | walk frames vs rest: mean IoU 0.77 (min 0.68), area kept 95-104% (min 546 px), frame-to-frame IoU min 0.69; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (tracker 0.64, rimeshield 0.55, magpie 0.51, bloomtender 0.48, gloomcap_elder 0.39, ruin_warden 0.33) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.99 m from the body centre at t 0.14 s (0.99 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 41% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 37% of the silhouette at its peak (t 0.25 s; 0.12 s 37%, 0.25 s 37%, 0.4 s 32%, 0.6 s 8%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 81 | 247 shapes over 7 body parts (35.3 per part: LegL 9, LegR 9, Hips 15, Head 107, ArmL 6, ArmR 57, Chest 44); 34% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.875 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 288% of the 3000 verts budget used (8658) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 94 | inner edges per outline px: 3.21 at the close-up (91025 px), 1.35 at 25 m; close-up outline complexity 11.01 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.93 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 46.3, bottom third L* 24.8 (+21, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 18.8 at 25 m, 21.1 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 62.7, 0% melts; body L* 33.4 C 29.2 vs floor L* 51.6 C 42.9 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.37 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"face_verts":900,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Variant 2382 v / 3 s; Root/Chest/ArmR/Bow 1333 v / 3 s; Root/Chest/Quiver 1205 v / 3 s; Root/Hips/Merged 805 v / 4 s; Root/Chest/Merged 592 v / 4 s; Root/Chest/ArmR/Merged 584 v / 3 s; Root/Chest/Head/Face 478 v / 1 s; Root/Chest/Head/Merged 361 v / 2 s
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: B8 12 -> 9 materials: use one material for look-alike pairs (albedo dE <= 15): `StandardMaterial3D#-93568` -> `StandardMaterial3D#-98622` (dE 0.0), `StandardMat)
