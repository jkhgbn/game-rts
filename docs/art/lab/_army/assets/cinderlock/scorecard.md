# Art Lab scorecard: cinderlock

Scene `res://art/units/fire/cinderlock/cinderlock.tscn` · kind **unit** / tier **soldier** · kingdom fire · ground meadow · 2026-09-27 09:47:10 · lab v2.0

## Result: **FAIL** · quality **90 / 100**

1 FAIL · 2 WARN · 26 PASS · 10 info · 0 skipped · 24 s

## Improve next
1. **Vertices** (FAIL): B4 3725 -> 2438 (want <= 2500): `Merged` 1226 -> 613 verts; `Merged` 925 -> 463 verts; `Musket` 542 -> 330 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Head height vs body_height** (WARN): R8: body_height 1.7 -> 2.18 in res://art/units/fire/cinderlock/cinderlock.tscn (root) (the head top; x1.28 now), or lower the head / crest 0.06 m [fixes.json #2] _(from R8 Head height vs body_height)_
3. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 2 glow point(s) barely stand out from their 1 m surround (worst dL +11): darken around them or raise the energy [fixes.json #3] _(from R5c Glow points stand out (1 m surround), shot glow)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -8 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.57): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Chest 3, (root) 1, ArmL 1, ArmR 1, Head 1, LegL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 3725 (biggest: Merged 1226, Merged 925, Musket 542, GlowFireGlow 315) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 15 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 25 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 613 of 4240 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 50 | head top 2.18 m / body_height 1.7 (x1.28) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | INFO | x 0.79 / z 0.68 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 740 px (27 x 44 bbox; 55 m: 377 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 57.6, 0% of the body melts (within dE 15 of the ground); body L* 35.8 C 36.3 vs ground L* 62.0 C 48.8, hue gap 72 deg; top third (world height) dE 63.4, L* 28.5; per-pixel dE 69.0, outline 60.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 34.2, 35% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 99 | worst heath: dE 29.4 (heath dE 29.4, old_wood dE 35.9, riverbank dE 53.0, snow dE 64.3, ash dE 34.2, sand dE 50.7, marsh dE 30.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 29% of body pixels change between kingdom colours (min pair 25%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 40.0 (fire 56.3, shadow 67.8, ice 50.4, nature 40.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 13.9 on the team-colour area (normal vision 66.8; 236 px); deutan: fire / nature dE 13.9; protan: fire / nature dE 17.9; worst vs ground: fire colour (deutan) dE 26.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 7% of the silhouette (gap -10 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 41 | worst dL +11 (point 1 dL +11, point 2 dL +12; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Merged x2; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.9 (min 0.85), area kept 100-101% (min 739 px), frame-to-frame IoU min 0.84; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.08 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 21 | outline complexity 1.57 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 28.5, bottom third L* 37.1 (-8, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.8 at 25 m, 14.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 1226 v / 6 s; Root/Chest/Merged 925 v / 5 s; Root/Chest/Musket 542 v / 3 s; Root/Chest/GlowFireGlow 315 v / 1 s; Root/Hips/LegL/Merged 168 v / 2 s; Root/Hips/LegR/Merged 168 v / 2 s; Root/Chest/ArmL/Merged 150 v / 2 s; Root/Chest/ArmR/Merged 150 v / 2 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B4 3725 -> 2438 (want <= 2500): `Merged` 1226 -> 613 verts; `Merged` 925 -> 463 verts; `Musket` 542 -> 330 verts (fewer segments: cylinders 6-8, spheres 10 x 5;)
