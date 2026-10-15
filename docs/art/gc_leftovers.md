# G-C leftovers: units the first G-C pass skipped (2026-10-15)

Graphics week, JS: "make the graphics as beautiful as possible". Tech-artist pass on the units G-C did not reach:
the cavalry riders, the Nature mounts, the untouched Ice soldiers, the Shadow T2 boxes and the Mender's limbs.
Every contract is kept: scenes, node names, keep_separate parts (Muzzle, Maul / MaulMesh / MaulRunes, SlabRune,
Rifle / Monopod, Jaw / JawBone, BladeRune, Sigil, VetTrim), saddle / attachment points, attack / death styles, LOD
tiers, team colour, hit flash, merge per pivot (no new draw instances, no new emitters, no moving glow nodes).

## Shared helpers (new)

- `art/units/fire/rider_shapes.gd` (`RiderShapes`): ChampionShapes (tube, lathe, lame, bevelled plate, cloth, band,
  studs) wrapped for MountModel sculpt dictionaries, plus `limb`, `box_plate` (a bevelled plate with an optional pointed
  hem, the drop-in for a box) and `boot` (heel -> toe, flattened, +Y kept up). Used by every rider.
- `art/units/ice/ice_shapes.gd` (`IceUnitShapes`; not `IceShapes`, which is the G-B buildings' class): builds a pivot's
  pieces once per process into one SurfaceTool per material and adds them with the kit's `add_part` (they merge into
  the pivot: vertices, never draw calls). `put`, `mesh`, `st`, `on`, `xf`, `crystal`, `egg`, `strap`, `limb`.
- The Shadow units use a local `_gc(key, build)` cache (ChampionShapes into one mesh, `_cached`).

## What changed

1. **Cavalry riders** (Fire: Blaze Rider, Emberdart Harrier, Pyrehoof Lancer, Sunforge Cataphract; Shadow: Barrow
   Knight, Duskbolt Harrier, Veilborn Dreadrider, Gloam Rider; Ice: Rimehorn axeman, Rime Harrier, Snowdrift scout,
   Frostcrown rider): smooth thigh / greave tubes with knee cops, shaped boots and sabatons, lathed torsos and
   cuirasses with ridges, curved lame tassets / faulds / gorgets / pauldrons with rolled rims, bevelled tabards with
   pointed hems, real cloth capes (Frostcrown), banded hafts and grips, domed shields with rivets, fur-ring cuffs on the
   Ice riders. The two light Ice riders stay inside their 2500 budget (ring counts kept low).
2. **Nature mounts**: Thornback elk and Bramble hare legs on `MountShapes.leg` / `leg_bands` / `muscle` (horse
   templates scaled for the elk, custom rows for the hare's long hind foot), rounder barrels (16 sides), shoulder /
   haunch muscles, a lathed hoof with a cleft (elk), paws and toes, a cotton tail of locks (hare), smoother neck / skull
   / muzzle / antlers.
3. **Ice soldiers**: Frost Mortar rebuilt (curled iron-shod runners, bevelled plank deck, a faceted ice block on a dark
   plinth, a lathed mortar with breech, banded barrel, flared lip and dark bore, egg shells, a hunched hooded loader and
   gunner with fur hems): 5039 -> 2441 B4, under the soldier budget. Frostrune Rifleman: tube arms with fur cuffs and
   mitts, a fur-ring mantle with a domed pauldron, a lame visor band, a rifle whose stock / grip / forestock are bevelled
   side outlines, banded rune collars and a crystal crown: 3317 -> 2254. Rimecarver: shaped trousers and fur boots,
   a curved stone apron with a pocket of rune pebbles, toggled placket, flat harness straps, iron slab bands that wrap
   the slab, an octagonal chamfered maul head with steel collars. Rimeling: bowed tube legs and arms, fur kilt / mantle /
   cuffs, a hooked nose, bat-wing ears, curved tusks, a drooping hood tip, faceted icicles: 2143 -> 1620.
4. **Shadow T2**: Barrow Ghoul (ragged-hem rags instead of boxes, bony rib arcs riding the hide, an arched brow ridge,
   a U-shaped bevelled jaw with four teeth), Hollow Oathsworn (curved tassets, pointed silver-hemmed tabard, torn back
   panel, wrapped sash with forked tails, ridge / nasal tubes, a bevelled haute-piece, pointed lappets, curled quillons,
   one bevelled single-edged blade outline with a clip point and a round spine), Nightblood Reaver (lathed fauld,
   oxblood tasset lames, pointed tabard and torn back panel, round belt, rolled waist ribbing, pointed fan-collar
   blades, smooth pauldron domes with rolled oxblood rims, domed knee cops, long pointed sabatons), Bleakbow (curved
   baldric), Hexweaver (finger-bone charms). Gloom Deacon left as is (its remaining boxes are flat orphrey strips and
   reliquary caps that read correctly).
5. **Mender**: stockings with a calf swell, a lathed boot shaft with a rolled cuff, a rounded foot and a bevelled
   rounded sole (was a cylinder, a torus and a box), forearms with a swell and narrower wrists, mitten hands with a
   thumb (were balls). 8473 -> 8555 vertices in test_9_v4: under its 8750 cap, **no cap change needed** (nothing in
   docs/handoff/for-lead.md).

## Measurements (Art Lab, `--gfx=high`; md / json in `docs/art/lab/gc_leftovers/<before|after>/<asset>/`)

| Asset | Before | After | B4 before | B4 after |
|---|---|---|---|---|
| blaze_rider | FAIL 91 | FAIL 91 | 9306 | 9990 |
| emberdart_harrier | WARN 92 | WARN 92 | 7541 | 8406 |
| pyrehoof_lancer | WARN 93 | WARN 94 | 8578 | 10087 |
| sunforge_cataphract | WARN 94 | WARN 93 | 8731 | 10833 |
| barrow_knight | WARN 93 | WARN 93 | 10545 | 12493 |
| duskbolt_harrier | FAIL 89 | FAIL 90 | 7792 | 8260 |
| veilborn_dreadrider | WARN 93 | WARN 93 | 10022 | 12195 |
| gloam_rider | FAIL 90 | FAIL 89 | 9853 | 10369 |
| rimehorn_rider | FAIL 88 | FAIL 89 | 8922 | 9634 |
| rime_harrier | PASS 98 | PASS 98 | 2384 | 2485 |
| snowdrift_rider | FAIL 94 | FAIL 94 | 2400 | 2490 |
| frostcrown_juggernaut | PASS 97 | PASS 98 | 2576 | 4760 |
| thornback_charger | WARN 95 | WARN 94 | 2667 | 4683 |
| bramble_harrier | WARN 93 | WARN 95 | 2594 | 4329 |
| rimecarver | WARN 95 | WARN 95 | 2111 | 2063 |
| rimeling | WARN 96 | WARN 93 | 2143 | 1620 |
| frost_mortar | **FAIL 95** | **PASS 98** | 5039 | 2441 |
| frostrune_rifleman | **FAIL 96** | **PASS 97** | 3317 | 2254 |
| barrow_ghoul | WARN 94 | WARN 94 | 1544 | 1877 |
| hollow_oathsworn | PASS 95 | PASS 95 | 2285 | 2470 |
| bleakbow | PASS 94 | PASS 95 | 1915 | 1911 |
| nightblood_reaver | PASS 93 | PASS 94 | 1822 | 2311 |
| hexweaver | WARN 95 | WARN 95 | 1673 | 1665 |
| gloom_deacon | PASS 96 | PASS 96 | 2088 | 2088 |
| mender | WARN 95 | WARN 93 | 7633 | 7715 |

The cavalry FAILs are pre-existing: B2 draw instances (blaze 18, gloam 20, rimehorn 17, duskbolt 15; unchanged, no
node added), B6 particle systems (rimehorn, snowdrift), and duskbolt's B4 read against the soldier tier (7792 before).
Cavalry B4 rises are inside the riders' own budget (tests: <= 12000 vertices / <= 12 draws per rider; the whole unit
<= 14000 in test_gc_leftovers). Rimeling 96 -> 93 = R5 glow points (the lab marks it noisy; the eyes did not change)
and R4k snow contrast (pale fur on snow). Mender 95 -> 93 = B4 soft (+82 v) and R8w (the staff, unchanged).

## Shots (`docs/art/lab/gc_leftovers/`, `.gdignore` first)

- Script: `art/units/fire/tools/gc_leftovers_shots.gd` (windowed: `'--' --gfx=high --tag=after`; `--sheet` builds the
  contact sheet; `--count` headless prints body / face / draws per scene).
- Commit: `contact_sheet.jpg` (before | after, every view) and 4 key PNGs: `shots/after_all_z30.png`,
  `shots/after_portrait_frost_mortar.png`, `shots/after_portrait_blaze_rider.png`, `shots/after_close_shadow_t2_l.png`.
  The other PNGs stay local. The new portraits (rimecarver, rimeling, frostrune, barrow_ghoul, reaver, bramble) have no
  before shot (dark tile on the sheet).

## Tests

- New: `tests/test_gc_leftovers.gd` (PASS): every reshaped scene builds, soldier B4 <= 2500 with no Box / Capsule
  mesh drawn (glow nodes excepted), shared merges, hooks / named nodes, cavalry <= 20 draws / <= 14000 vertices,
  Nature mounts <= 6000, Mender <= 8750, outward normals of the IceUnitShapes pieces.
- PASS: smoke (victory=true), test_ws_perf, test_11_v4, test_gc_fire / shadow / ice / nature / champions, test_13_v10,
  13_v2, 13_v7, 13_v8, 13b_v2, 13b_v7, test_g3b_materials, test_kit_team_color, test_shader_lint, test_9_v4.
- perf_test: OVER on two runs (normalised 7.48, then 6.88 vs limit 6.72, load x1.3 with other agents running). It
  spawns only Flame Guards, which this pass does not touch: noise / machine load, not this pass.

## Left undone

- The Thornback warden and Bramble dartcaster riders (green saddle-cloth panels still read boxy): only their mounts
  were in scope.
- Gloom Deacon's flat orphrey strips and reliquary caps (boxes that read as intended).
- The pre-existing cavalry B2 / B6 FAILs (would need merging rider pivots or emitters: contract changes).
