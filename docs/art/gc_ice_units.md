# G-C: Ice units (graphics week, 2026-10-15)

Goal (JS: "make the graphics as beautiful as possible"): the Ice army read as blocky primitives (box helms, box boots,
straight cylinder torsos and robes, capsule limbs). This pass gives the Hall units and the worker real shapes, and lifts
the other blockiest Ice soldiers, without touching any contract: same scenes, pivots, node names (Tip, Orbit, Lantern,
Core, Cracks, SlamRing, VetTrim, Rifle...), attachment points (HOOK, GRIP, beam origin, muzzle), attack / death styles,
LOD tiers, team-colour API, hit flash, freeze / shatter death. Torvald (G3a) stays the hero reference: same palette,
same materials, the soldiers now share his lathed robes / fur / cape vocabulary at a soldier's vertex budget.

## Shape builders (`art/units/ice/ice_model.gd`, IceModel; cached per shape, merged by the kit like its primitives)

| Builder | What | Vertices |
|---|---|---|
| `lathe(profile, seg, sx, sz, arc_deg)` | surface of revolution from a (radius, y) profile, bottom -> top (a top -> bottom profile is flipped automatically), elliptical section, optional open arc centred on +Z (breastplates, back guards) | (seg + 1) x points |
| `taper(len, r0, r1)` / `add_taper(pivot, a, b, ra, rb, mat)` | tapered limb with rounded ends, from model point a to b | 54 (a `capsule_lo` is 81, `capsule` 162) |
| `soft_box(size, roll)` | box whose corner normals lean to the corners: flat faces with a soft highlight on every edge (a bevel by shading) | 24 |
| `boot(r, h)` | rounded lathed boot / foot (stretch it in Z) | 36 |
| `fur_ring(r_top, r_bot, h, tufts, jag)` | jagged fur ring (collars, hems, cuffs): every other column is a longer tuft, so the silhouette reads as fur | (2 tufts + 1) x 4 |
| `fur_cap(r, rim_deg, tufts, jag_deg, arc_deg)` | hide / pelt over a rounded mass with a tufted rim | (2 tufts + 1) x 5 |
| `cloak(r_top, r_bot, h, wrap_deg)` | curved cape for `banner.gdshader` (UV.y 0 at the top, same convention as the kit's `cape()`); with `ice_cape` it takes the team colour and the G3b `unit_cloth` sway | (cols + 1) x (rows + 1) |
| `add_group(pivot, key, mat, items)` | several shapes as ONE authored part (keeps the authored part count low: the Frostrune Rifleman builds on the Shardcaster and counts its parts) | sum |

## Per unit

| Unit | Before | After (G-C) |
|---|---|---|
| Rimeshield (Hall melee) | box helm, team keg torso + box breastplate, sphere pauldrons, capsule limbs, box boots | lathed close helm (dome, rolled brim, cheek / nape guard open at the front, steel brow ridge carrying the glow band), lathed team gambeson + steel breastplate shell, layered steel pauldron domes + lames (crystal pairs kept), jagged pale fur collar, dark fur tassets, fur boot cuffs, a fur-lined team cape down the back, team tabard flap, crystal belt buckle, tapered limbs, steel bracers, soft gauntlets, rounded sabatons; crest 5 cm lower (R8 head-height WARN fixed) |
| Rime Hauler (worker) | cone coat, box back-frame, sphere lantern hidden behind the head | lathed padded parka, jagged fur hem / ruff / cuffs, belt pouch, leather straps lashing the ice block + 2 frozen crystals, shoulder straps, tapered limbs, round boots, wrapped pick grip; the glow point is now a miner's lamp on the hood brow (Art Lab R5: 0 -> 1 glow point) |
| Shardcaster (Hall caster) | cone greatcoat, straight cone hood (read as a pointed cap), capsule arms | lathed greatcoat flaring to a jagged fur hem, fitted lathed torso, fur collar, a lathed cowl whose tip droops back, tapered sleeves with fur cuffs, gloves, the rod gets a mid band, a wider socket and a 3-crystal fork at the tip; same authored part count (quiver crystals grouped) |
| Rime Seer (Hall support) | cylinder bell robe, cone beard, cone bell sleeves | lathed flowing bell robe + hem band, lathed capelet, lathed beard, flared lathed sleeves, crystal clasp + hem gem, staff with 3 steel bands and a crystal collar, narrower hook ring (R8w) |
| Rime Colossus (Hall heavy) | cylinder legs, box feet / pelvis / brow, team colour only on a loincloth (R6 WARN 3 %) | tapered stone legs, rounded stone feet with ice toe crystals, soft-edged pelvis and brow, tapered off arm + crystal-studded fist, team loincloth front AND back, a shaggy team-dark pelt over the back of the hump (fur_cap, the crystals grow through it) and a jagged hide hem round the shoulders: R6 3 % -> 24 % |
| Shardguard (T3) | box sabatons, capsule legs / sleeves, cylinder helm + cone, cheek boxes, sphere pauldrons | lathed tall close helm with wrap-around guard, lathed pauldron domes, tapered legs / sleeves, rounded sabatons, pale fur collar (was a box); vertices 5539 -> 5096 |
| Frostbow, Hoarlight Magebow | pale cylinder / torus cuffs and collar | jagged fur cuffs / collar (their path-built bodies were already tapered) |

## Snow motes (High / Ultra only)

`IceModel._add_snow_motes()`: 6 soft flakes (Colossus 10) drifting down round each Ice unit, world space, one shared
process / draw material. Built only when `GameSettings.effective_graphics_quality() >= High` (so never in headless / `-s`
runs: tests, labs and Low / Medium players pay nothing), emitting only while the kit tier is 0 (camera within 30 m:
zoom 10, portraits, cinematics) and the unit is alive, on screen and not frozen. Kept OUT of the kit's looping list (the
kit turns every looping system on at the tier 2 -> 1 change): `IceModel._process` drives it every frame after the kit's
own update, so it stops when the model goes off-screen, far or dead. Parented to the model's Fx node: the fog of war hides it with the unit. Test hook
`IceModel.snow_quality_override`. Override `_snow_amount()` per unit (0 = none).

## Measures

Art Lab v3.1 before / after, same batch, same tier (Low, the lab default; batch files `docs/art/lab/gc_ice/batch_before.txt` /
`batch_after.txt`, scorecards `docs/art/lab/gc_ice/<before|after>/<unit>/scorecard.md|json`). B4 = body vertices (face
above its allowance counted), C1 = craft shape richness (lab v3.1: >= 7 shapes per part, <= 35 % plain boxes / prisms,
normal variety), R6 = team colour changing between kingdom colours at 40 m.

| Unit | Result before -> after | B4 verts (budget) | C1 shapes | R6 team colour | WARNs after |
|---|---|---|---|---|---|
| Rimeshield | WARN 93 -> WARN 93 | 1714 -> 2096 (2500) | 43 -> 82 | 19 % -> 14 % | R10 footprint (the 0.9 m shield, pre-existing), R6cb deutan fire / nature dE 3.7 (was 6.6: the cape's fixed dark stripes dilute the team area); R8 head height FIXED |
| Rime Hauler | WARN 90 -> WARN 94 | 1705 -> 1777 (2500) | 33 -> 76 | 40 % -> 35 % | R7 HP bar 13 % (was 10 %: the back-frame projects into the bar at 40 m); R5 glow FIXED (0 -> 1 point) |
| Shardcaster | WARN 93 -> WARN 94 | 1751 -> 1823 (2500) | 35 -> 94 | 57 % -> 51 % | R10 footprint (the 1.4 m rod, pre-existing) |
| Rime Seer | WARN 92 -> WARN 93 | 1582 -> 1844 (2500) | 60 -> 69 | 36 % -> 37 % | R8w staff head 0.43 -> 0.36 m above the bar line (limit 0.35) |
| Rime Colossus | WARN 91 -> WARN 93 | 2311 -> 2627 (6000 soft) | 78 -> 100 | **3 % (WARN) -> 24 % (PASS)** | R10 footprint (the club arm, pre-existing) |
| Shardguard | PASS 97 -> PASS 96 | 5539 -> 5096 (6000 soft) | 54 -> 61 | 16 % -> 11 % | none |
| Frostbow | PASS 94 -> PASS 96 | 2222 -> 2206 | 45 -> 44 | 61 % -> 61 % | none |
| Hoarlight Magebow | PASS 95 -> PASS 94 | 2304 -> 2305 | 39 -> 40 | 68 % -> 63 % | none |
| Frostrune Rifleman (inherits the Shardcaster body) | FAIL 94 -> FAIL 96 | 3349 -> 3317 | 52 -> 95 | 57 % -> 51 % | B4 FAIL pre-existing (soldier budget 2500; its own test allows 5000) |
| Rimecarver, Rimeling, Frost Mortar | unchanged (96 / 94 / 95) | unchanged | | | Frost Mortar B4 FAIL pre-existing (crew + mortar on the soldier budget) |

Every check outside those rows is unchanged (0 new FAIL). Draw instances are unchanged per unit (the new shapes merge
into the existing pivot meshes; `add_group` keeps the authored part count of the Shardcaster at its old value so the
Rifleman's "authored meshes <= 27" holds: 24).

GPU (`art/units/ice/tools/gc_ice_shots.gd -- --gfx=<tier> --perf`: 240 Ice Hall units + workers filling the zoom-30 view,
1600 x 900, MSAA 4x, RTX 3070 Laptop, with other agents' Godot runs in parallel, so noisy): High gpu 6.67 ms / cpu
2.65 ms, Ultra gpu 5.68 ms / cpu 3.07 ms per frame (whole frame, ground included). No "before" GPU number for Ice alone
(the G3b 240-unit mix of the 4 kingdoms measured 4.2-4.7 ms on a loaded machine); the extra cost is vertices only (about
+70 .. +380 per unit), no new draw call, no new material, no shader pass. Headless perf (CPU): perf_test PERF OK (norm
6.68 / limit 6.72, with 6 Godot processes of other agents running), test_ws_perf PASS (march p95 26.6 ms, clash p95
31.06 ms, budget 38.58 ms at load x2.31).

## Shots

`docs/art/lab/gc_ice/shots/` (folder has a `.gdignore`), High tier, windowed:
`tools\godot_run.ps1 --path . -s res://art/units/ice/tools/gc_ice_shots.gd --quit-after 30000 '--' --gfx=high`
- `high_g3b_close_ice.png` (zoom 9), `high_g3b_portrait_ice.png` (zoom 4), `high_g3b_army_z30_crop2x.png`: the G3b shot
  layout, 1:1 with `docs/art/lab/g3b_materials/shots/after_close_ice.png` / `after_portrait_ice.png` /
  `after_army_z30_crop2x.png`, which are the Ice units before G-C (the mounts row is left empty: the mount scripts were
  mid-rework by another agent and did not parse);
- `high_army_meadow_z30|z10.png`, `high_army_snow_z30|z10.png`: an Ice army in 3 ranks (Hall units, worker, Lodge /
  T3 units) facing 4 red-team Ice units, on the meadow and on the lab's snow patch;
- contact sheet `docs/art/lab/gc_ice/gc_ice_contact_sheet.jpg` (`art/units/ice/tools/gc_ice_sheet.gd`, headless): left
  before, right after for the first 3 rows (close zoom 9, portrait zoom 4, zoom-30 crop), last row the army at zoom 10
  on the meadow and on snow.
Commit: the contact sheet + `high_g3b_portrait_ice.png`, `high_g3b_close_ice.png`, `high_army_snow_z10.png`,
`high_army_meadow_z30.png`; the per-unit lab JPG / PNG files stay local (the md / json scorecards are commit-friendly).

Read on the shots: at zoom 30-40 the Ice line is the same silhouette family (wide shields, crystal pairs, pale hoods)
with better value structure: dark steel domes and helms on top, team capes / pelts seen from the RTS camera, jagged
fur edges instead of pipes; the Colossus now carries the team colour. At zoom 10 and in portraits the box helm, box
boots, keg torsos and stick limbs are gone: helms, robes, parkas and greatcoats are turned shapes with folds of light.

## Tests

- `tests/test_gc_ice.gd` (headless): builders (vertex counts, unit normals, every triangle front-out, a top -> bottom
  profile flipped, cloak UV, arc centring); 9 Ice scenes x 2 instances (IceModel, pivots / Fx, chest merge shared, no
  snow at Low, body vertices and mesh draws within budget, walk / attack / hit / cast / level-up / death_finished /
  revive, the Rimeshield cape takes the team colour); the 4 Ice riders (meshes, hooks, death_finished); snow motes
  forced High (built, <= 10, looping, world space, on at 7 m, off at 40 m, off while dead, back on revive, Colossus 10).
  PASS.
- Also PASS: smoke (victory=true), perf_test (PERF OK), test_ws_perf, test_11_v4, test_13b_v2 (Frostrune Rifleman on
  the Shardcaster: 24 authored meshes, 4224 vertices), test_13_v8 (Rimehorn Rider), test_g3b_materials,
  test_kit_team_color, test_a17, test_ice_vfx_read, test_13_v1b (Rimeshield seated on the Rimehorn; one mid-session run failed
  on another agent's in-progress `oathwall.gd`, the final run PASS).

## Left for a next pass

- Riders (Rimehorn axeman, Harrier, Snowdrift scout, Frostcrown rider) only got soft-edged plates (`box` -> `soft_box`,
  same vertices); their own shape pass (and the bear / ram / cat mounts) is open.
- Rimecarver, Rimeling, Frost Mortar untouched (the lab rates their shapes well; the Mortar's B4 FAIL is a budget
  question for the lead).
- The `ice_cape` banner stripes are a fixed dark blue: a team-tinted stripe would raise the Rimeshield's team share
  and the colour-blind read (R6cb); it is a material change for every Ice cape (Torvald's is his own material).
- The Hauler's R7 (HP bar over the back-frame at 40 m) needs body_height 1.4 -> ~1.55 in the scene and
  `data/units/rime_hauler.tres` (gameplay-coder's file).
