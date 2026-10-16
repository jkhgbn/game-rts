# G-F: Quartermeet gets its own identity (2026-10-15)

Problem: Quartermeet and Ashwind Reach (Wave Strike) are both biome `autumn`. AutumnSwap works per biome, so both
maps got one palette: olive grass, red-brown roads, orange / russet crowns, the same fog and light.

Quartermeet became a **late-autumn harvest highland**:
- straw-gold stubble fields, with green infield round the keeps;
- grey granite gravel roads;
- a purple heather moor along the rim;
- golden birch crowns and a cold slate-teal burn;
- stook fields with drystone walls, and granite standing stones round the crown isle.

This is art-side only. The map data, colliders and navmesh are unchanged, so the gate's approval stands. Ashwind Reach
looks exactly as before.

- Contact sheet: `docs/art/lab/gf_quartermeet/qm_contact_sheet.jpg`
  - Columns: Ashwind Reach (unchanged), Quartermeet before, Quartermeet after.
  - Rows: in-game z32, overview, crown isle z35, field z36, west edge z40, ford z30.
- Key PNGs: `key_after_overview.png`, `key_before_overview.png`, `key_after_field_z36.png`, `key_after_centre_z35.png`
  (same folder).
- Shots: `art/environment/quartermeet/qm_shots.gd`. Run it windowed with `'--' --gfx=high --map=<id> --tag=<tag>`;
  `--before` turns the look off.
- Sheet: `docs/art/lab/gf_quartermeet/tools/qm_sheet.py`. The folder has a `.gdignore`.

## How it hooks in

`LevelLooks` (`art/environment/level_looks.gd`) now lists `art/environment/quartermeet/quartermeet_look.gd`.

- `GroundDetail._ready` calls it in windowed runs only. That happens after main.gd's AutumnSwap hook and before the
  ground bake.
- It acts only when the layout id is `quartermeet`. Every other map, Ashwind included, gets nothing.
- Headless and sim runs never create GroundDetail, so tests and labs are unchanged.

**Guard / restore.** The `QuartermeetLook` guard node is a child of AutumnSwap's `AutumnLook` guard, so it always leaves
the tree first (children exit before their parent).

- When it leaves, it puts back every shared value it recorded. Each value was recorded the first time it was touched.
- AutumnLook then puts back the originals.
- So nothing leaks into the next map or the menu. The test loads Quartermeet twice, then Ashwind and Crown Hollow, and
  compares the values.

## Every tier (colour only, no extra cost)

**Ground** (`quartermeet_palette.gd`): set on the level's own ground material and on the shared `plateau_mat.tres`
(recorded first).
- Grass is straw-gold, with amber and sage patches in a field patchwork. Straw saturation is kept at or below 0.55 so
  Fire's red-orange units stay readable.
- Field-margin flowers: yarrow, tansy, muted heather and cornflower.
- Roads and dirt are grey-brown granite. The road value sits 0.15 or more below the lit grass, so the long roads read.
- Banks: dark peat with a pale gravel lip. Rim rock is grey granite. The painted canopy band is olive-gold.

**Biome zones** (ground shader):
- green infield (radius 21 m) round the two live keeps, read from the level;
- a muted heather moor (heather and gorse) in the last 11 m of the map;
- a 7 m sage band along the river and moat;
- no old-wood zone;
- the crown isle as a ruin circle.

**Shared materials:**
- **Water** (`water_mat`, `water_ford_mat`, `mouth_water_fallback_mat`): a cold, clear slate-teal highland burn with a
  pale grey-blue sky reflection.
- **Foliage** (`nature_mat`, on the autumn shader while the swap is on): golden-yellow and lemon crowns weighted toward
  gold instead of russet, straw undergrowth, a paler sun tint.

**Light** (`preset_quartermeet.tres`): a crisper, higher, paler-gold sun (energy 1.3), a cooler fill and a lighter
vignette. It uses the same Environment as the autumn preset, so fog and tier values do not change. The rig only switches
when it shows the default warm / autumn mood; a level's own preset wins.

## Medium+ only: `QuartermeetDressing` (`quartermeet_dressing.gd`)

**Kinds.** The dressing uses 8 MultiMesh draws. It is draw-only: no colliders, nothing on nav layers. About 820 pieces,
of which 4 cast shadows (walls, bales, stones and lichen; stooks do not).

**Stook fields.**
- Up to 3 open spots are found in the x < 0, z > 0 quadrant, the most room first and at least 20 m apart. They are
  mirrored fourfold, matching the map's own symmetry, which gives 12 fields.
- Each field has:
  - stook rows laid along the nearest road;
  - stubble tufts;
  - broken drystone walls on two sides, with a gate gap;
  - 2-3 round bales at the corners.
- Every piece is checked again on its own side.

**Moor rim.** Heather, gorse and lichen stones are clumped along the last ~3 m of the map, with noise making outcrops
and bays. A bale sits out on the moor now and then.

**Crown isle.** Four granite standing stones with straw harvest garlands rise from the moat. They stand at the angles
furthest from every crossing, using the same picking as Thornwater's spires.

**Kept clear:**
- keeps, nodes and building slots;
- capture points, camps, lairs, the tavern, peddler, posts, caches and critter slots;
- roads, crossings and water;
- the planned forest trees, rocks and ruin pillars.

A building placed later hides the decor under its footprint. Map detail Low keeps half of everything except the stones.
The dressing is deterministic.

**Meshes** (`quartermeet_meshes.gd`): built in code once per run, in the shared `nature_mat` vertex format. There is no
new material, shader, light or particle.

| Mesh | Size | Triangles | Material kind |
|---|---|---|---|
| stook | 1.4 m tall, 0.7 m wide, 7 / 6 / 5 sheaves | 350 / 300 / 250 | bark kind (straw) |
| round bale | 1.25 m; single, squat or a pair | 96 / 96 / 192 | |
| drystone wall | 2.4 m segment | 400-530 | stone kind with moss |
| standing stone | 5.6 m | 415 | |

The wall comes whole, slumped, or half-fallen with stones at its foot.

## Tests

`tests/test_gf_quartermeet.gd` (PASS) checks:
- **Meshes:** budgets and sizes, all on `nature_mat`.
- **Palette:** the keys are real uniforms, roads contrast with the grass, and the straw saturation stays capped.
- **LevelLooks** lists the look.
- **Other maps:** Crown Hollow and Ashwind get no guard and no dressing. Ashwind's values are snapshotted, and match
  again after Quartermeet has run.
- **Quartermeet, run twice:**
  - the guard sits under AutumnLook and the look is idempotent;
  - the ground, plateau, water, crowns and rig preset change;
  - the dressing has 12 fields, 197 stooks, 58 walls, 32 bales, 312 rim pieces and 4 stones in the moat water;
  - nothing sits on keeps, crossings, water or roads;
  - `clear_area` works, Map detail Low halves the decor, and a rebuild gives the same result.
- **After leaving:** the shared values equal the snapshot.
- **Low tier** gets the palette only. Sim mode and `disabled` change nothing.

Also passing: `test_gf_thornwater`, `test_gd_autumn_maps`, `test_shader_lint`, `test_ge_additive_fog`,
`test_map_start`, and the smoke test (`victory=true`).

## Known limits

- The horizon backdrop (`horizon_mat`, owned elsewhere) and the dense border forest outside the map still use the
  autumn orange / russet / gold mix. The gold crown weighting softens it but does not remove it. A per-map horizon tint
  for Quartermeet would finish the look (request in `docs/handoff/for-lead.md`).
