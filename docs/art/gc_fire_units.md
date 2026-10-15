# G-C: Fire units (shapes pass)

Task G-C of the "graphics as beautiful as possible" block (2026-10-15). Goal: the Fire army reads less like blocky
primitives at zoom 30-40 and at zoom 10, inside the Art Lab budgets. Built on G3b (painted-PBR materials, `surface_kind`)
and G1 lighting. No contract changed: scenes, node names, pivots, attachment nodes (String / DrawnString / DrawnArrow /
AshBall / MineSparks / burn emitters / VetTrim), attack / death styles, body_height, LOD tiers, team-colour API, hit flash.

## What changed

### Hall units + worker (`art/units/fire/build_fire_units.gd` -> flame_guard / ember_archer / ash_hurler / cinder_hand .tscn)
Shared builder helpers (every builder unit gets them):

| Helper | Before | After |
|---|---|---|
| `legs()` | straight 7-sided cylinder | thigh -> narrow knee -> calf swell -> slim ankle (5 rings), optional boot cuff / sole band / knee cop |
| `boot()` | flat side profile extruded 25 cm wide (a "brick" foot) | rounded toe-forward half-ellipsoid foot + tapered shaft |
| `arm()` | two straight tubes + a ball | bicep / forearm swell (3 rings per segment), mitten fist |
| `plate()` (new) | `extrude()` slabs | bevelled plate: inset front face + chamfer ring, flat shaded, so every plate edge catches a light line; `back = true` chamfers both sides (blades, crests) |
| `rivets()` (new) | | cheap domed studs (18 verts) |
| `lathe()` | the last segment duplicated the seam | seam welded (one ring of vertices less per profile point, everywhere) |

Per unit:
- **Flame Guard**: smooth rounded helm dome with a rolled rim, iron brow band, bronze cheek guards; bevelled breastplate
  with a centre ridge, iron gorget + 2 rivets; smooth stepped pauldrons with an iron stud; team tabards front and back
  (the team colour now reaches the lower body); bevelled shield face + iron rivets; leaf blade double-bevelled with an
  ember-hot fuller on both faces (own glow node, +1 draw instance), swept iron crossguard, grip ring, iron pommel;
  flared bracers; dark boots with brass cuffs. **Plates moved from orange bronze to polished brass**
  (`materials/fire_bronze_guard.tres` #c57535 -> #cc994d): at zoom 30 the plates now separate from the red-orange team
  cloth, and on a blue team they still read as metal instead of a second orange.
- **Ember Archer**: smoother hood / capelet (14 sides), bronze capelet hem, leather baldric with a bronze buckle, bevelled
  belt pouch, flared bracers with a lace band, gold boot cuffs.
- **Ash Hurler**: bevelled apron with a coat-cloth pocket and rivets, bevelled harness straps on an iron ring, bevelled
  cap flaps and scarf tail, lathed respirator, flared cuffs, iron pot band with bronze rivets and iron handles.
- **Cinder Hand**: smoother hard hat (14 sides) with a leather band, bevelled apron + pocket + rivets, bevelled straps
  and buckle, iron-shod boots, a hammer on the left hip, three wicker bands on the basket.

New material `art/units/fire/materials/fire_iron.tres` (blackened forge iron #333030, kit painted shader, surface_kind 2):
a cool dark accent that breaks the orange masses into plates. Not a team-colour material.

### Code-built units (`FireShapes`, `art/units/fire/fire_shapes.gd`, class_name, static)
Scorchling, Scorchbow, Pyre Adept, Kilnwarden, Cinder Arbalest and Ashveil Saboteur swept their limbs, horns, straps
and tails as **stacked CylinderMesh segments**: a hard kink at every joint, two rings per segment. Their path helpers
now call `FireShapes.tube()` (one continuous tube, parallel-transported rings, normals leaning with the taper, welded
seam): rounder limbs and 250-500 vertices **fewer** per unit. `FireShapes.lathe()` + `FireModel.fs_lathe(key, ...)`
(cached in the kit mesh cache) give the code-built units smooth bells:
- Scorchbow: shaped greaves (was a 7-sided can), smooth kettle brim with a rolled edge, bell skirt with a hem roll,
  rounder breastplate / pauldrons / helm dome, 10-sided torso.
- Pyre Adept: cassock as a smooth bell kicking out at the hem, rounded mantle with a rolled edge, 14-sided hem ring.
- Scorchling: 8-sided legs / arms / ears, rounder belly.
- Cinderlock (`cinderlock/build_cinderlock.gd`): 7-sided legs and arms with a calf / bicep swell (were pentagons), rounded
  feet, 11-sided coat, welded lathe seams. The builder no longer re-writes its two materials when they exist (it used to
  drop G3b's `surface_kind`).

Not touched: the cavalry (Blaze Rider, Emberdart Harrier, Pyrehoof Lancer, Sunforge Cataphract: the boars live in
`art/units/mounts/`, the riders were not reworked this pass).

## Measurements

Art Lab before / after, same machine, `--gfx=high`, batch files `docs/art/lab/gc_fire/batch_before.txt` /
`batch_after.txt`, scorecards `docs/art/lab/gc_fire/<before|after>/<unit>/scorecard.md|json` (PNGs local).
B4 = body vertices after the kit merge (the face apart, budget 2500 for a soldier).

| Unit | Before | After | B4 before | B4 after |
|---|---|---|---|---|
| flame_guard | WARN 91 | WARN 90 | 1720 | 2461 |
| ember_archer | WARN 90 | WARN 91 | 1459 | 1954 |
| ash_hurler | WARN 94 | WARN 95 | 1723 | 2354 |
| cinder_hand | PASS 97 | PASS 96 | 1294 | 1886 |
| scorchling | PASS 95 | PASS 97 | 2035 | 1763 |
| scorchbow | PASS 95 | PASS 96 | 2407 | 2140 |
| pyre_adept | WARN 95 | WARN 97 | 2152 | 2202 |
| kilnwarden | WARN 92 | WARN 93 | 2446 | 2124 |
| cinderlock | WARN 93 | WARN 92 | 2396 | 2450 |
| cinder_arbalest | WARN 93 | WARN 92 | 2330 | 2065 |
| ashveil_saboteur | PASS 92 | PASS 92 | 2331 | 1989 |
| blaze_rider | FAIL 91 | FAIL 91 | 9336 | 9336 (untouched; B2 18 draws = pre-existing, the boar is counted) |
| emberdart_harrier / pyrehoof_lancer / sunforge_cataphract | WARN 93 / 94 / 94 | WARN 93 / 94 / 93 | | untouched |

WARN changes: Flame Guard R3t (contrast in every team colour on meadow) worst nature dE 16.2 -> 12.6: the new tabards put
more team colour low on the body, and a green team on green meadow loses a little (still WARN, not FAIL). Cinderlock B13
0.005 -> 0.006 ms process per instance is run noise (no script change). Every other WARN is the same as before.

Draw instances: Flame Guard 11 -> 12 (the blade fuller glow), the rest unchanged; all <= 14.

Shots (`art/units/fire/tools/gc_fire_shots.gd`, windowed, `-- --gfx=high --tag=<before|after>`; `-- --sheet` builds the
JPG): `docs/art/lab/gc_fire/contact_sheet.jpg` = before | after for squad_z30 (30 Hall units in formation), army_z30
(the whole roster + a blue-team Hall row), close_hall / close_t3 (zoom 10), portrait_hall_0 / _1 (zoom 4.5).
Key PNGs (for git): `shots/after_squad_z30.png`, `shots/after_close_hall.png`, `shots/after_portrait_hall_0.png`,
`shots/before_portrait_hall_0.png`. Everything else in `docs/art/lab/gc_fire/` stays local (folder has a `.gdignore`).

Budget probe: `art/units/fire/tools/gc_count.gd` (headless, `-- all`): body / face vertices per node after `_ready`.

Honest read: at zoom 30-40 the visible gains are the Guard's brass plates against the team cloth, the team tabards, the
lighter tops / darker boots and the glowing blade line; the silhouettes per role are unchanged on purpose. At zoom 10
and closer the units stop reading as pipes and bricks: shaped legs and rounded boots, bevel light lines on plates,
shields, blades and aprons, smooth bells and domes, rivets and trims.

## Tests
`tests/test_gc_fire.gd` (headless): Hall exports and nodes kept, glows keep_separate, hit flash lands, every Fire foot unit
<= 2500 body vertices and <= 14 draw instances after `_ready`, set_team_color still recolours, code-built units use
FireShapes (no stacked-cylinder path left), FireShapes tube / lathe normals face outward and the tube welds its rings,
fire_iron is a metal on the kit shader. PASS.
Also run 2026-10-15: smoke victory=true, perf_test PERF OK (norm 5.54 / limit 6.72), test_ws_perf PASS (march p95 20.55,
clash p95 23.21 ms, budget 24.83), test_11_v4, test_kit_team_color, test_face_review, test_g3b_materials, test_13_v10,
test_13_v2, test_13b_v1, test_13b_v6, test_unit_review_fixes, test_4_g2, test_art_lab: PASS.

## Next (not done)
- Cavalry riders (blaze_rider_rider, the three T3 riders) could get the same legs / plates pass; their B2 / B4 sit on the
  rider + mount budget, so the boars (`art/units/mounts/`) would need trimming first.
- Kilnwarden sleeves / gauntlets and the Cinder Arbalest still use 8-sided caps and a few boxes.
