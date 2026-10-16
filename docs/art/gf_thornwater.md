# G-F review 2 item 9: Thornwater gets its own identity (2026-10-15)

Problem (`docs/art/gf_review2.md` item 9, tiles 13 / 14): Crown Hollow and Thornwater read as the same map: the same
sunny meadow green, the same teal river and crown isle, a straight rectangular rim, and a uniform wall of identical
round crowns (the ground shader's painted canopy) all round Thornwater.

Thornwater's catalog entry is "a winding river splits the meadow", so it became a **wet marsh-meadow by a peaty river,
with reed beds, briars and a fen wood**, and a crown isle ringed by thorn spires. Art-side only: the map data, its
colliders and the navmesh are unchanged (the gate's approval stands).

- Contact sheet (rows: overview, crown isle z35, river + ford z30, west border z40; columns: Crown Hollow, Thornwater
  before, Thornwater after): `docs/art/lab/gf_thornwater/tw_contact_sheet.jpg`
- Key PNGs (same 3 columns): `docs/art/lab/gf_thornwater/tw_key_overview.png`, `tw_key_river_z30.png`,
  `tw_key_crown_isle.png`
- Shots: `art/environment/thornwater/tw_shots.gd` (windowed, `--gfx=high`; `--before` = the look disabled), sheet:
  `docs/art/lab/gf_thornwater/tools/tw_sheet.py`. Folder has a `.gdignore`.

## What changed

Hook: `LevelLooks` (`art/environment/level_looks.gd`) now lists `art/environment/thornwater/thornwater_look.gd`, called
from `GroundDetail._ready` in windowed runs, before the ground bake. It keys on the layout id `thornwater`; every other
map is untouched. Headless / sim runs never create GroundDetail, so tests and labs are unchanged.

**Every tier (colour only, no extra cost)**
- Ground (`thornwater_palette.gd`, on the level's own ground material): deeper, bluer greens (mean value ~0.30 vs
  Crown Hollow ~0.36), fewer flowers in wet-meadow colours (meadowsweet, marsh marigold, loosestrife, ragged robin),
  dark peat dirt with the roads one step lighter so the ring road still reads, black-brown mud banks with no sand lip,
  a mossy rim instead of grey rock. The biome zones are turned on with Thornwater numbers: a **9 m wet band** along the
  river and moat (Crown Hollow 6 m) in deep lush green, peat-fen floor in the two lair corners, a rush heath in the last
  9 m (dark rush clumps and dry sedge instead of heather / gorse), the keep hubs on the real keeps.
- Water (shared `water_mat`, `water_ford_mat`, the mouth fallback): peaty dark tea-green, murkier (`clarity` 3.8),
  a muted sky reflection. Shared `nature_mat`: no random autumn crowns (0.02), wetter moss. Every shared value is
  recorded on first touch and put back when the last `ThornwaterLook` guard leaves the tree (the AutumnSwap pattern):
  no leak into the next map or the menu (tested twice in a row, then Crown Hollow again).
- Light: `preset_thornwater.tres` (cooler sun 1.27, a stronger blue fill, a damp green vignette / haze). Same
  `world_env.tres` as warm, so the fog and the tier values do not change.

**Medium+ only** (`ThornwaterDressing`, `thornwater_dressing.gd`; Map detail Low keeps half of every kind but the
spires; nothing at Low): about 1 100 pieces in 17 MultiMeshes (550 at Map detail Low).
- Water edges: reed beds in broken runs (noise) along both banks of the river arms and the moat, in the water at the
  trench edge and on the bank; cattail stands; lily pads on the calm margins; marsh pockets (puddles + rushes) round the
  two fords. Reused biome meshes (riverbank, marsh); the puddle film is the shared ford film (recoloured with the water).
- Rim: thickets, gorse, rushes and mossy boulders clumped in the last ~3 m of the map; their depth follows noise
  (outcrops and open bays), and some bays hold a reed pool. Breaks the straight edge at play zoom.
- Border belt: a fen wood 12 m deep outside the map (willow, broadleaf, pine and fir in species clusters, 3 sizes), a
  ragged inner line (closer behind an outcrop, set back behind a bay). Only the front row uses the full tree meshes
  (~200); the ~470 behind are the ~110-triangle far stand-ins. No birch: its white trunks read as sticks lying on the
  rim. It hides the uniform painted canopy band. Medium uses the far stand-ins for the whole belt.
- Crown isle landmark: **four thorn spires** rising from the moat (three thick braided thorn canes, ~6.6 m, root canes
  into the water, leaf clumps, pale roses at the hooked tip), placed at the angles furthest from the crossings (a river
  arm's mouth only needs 16 deg; a spire in a tight gap is smaller), plus briars at the feet of the ruin pillars.
  Crown Hollow has none, so the centre now reads as Thornwater's own.
- New meshes, built in code once per run (`thornwater_meshes.gd`, shared `nature_mat`, no new material / shader /
  light / particle): the bramble thicket (3 variants by the variant mask: blackberry / dog-rose / dead canes with red
  hips, ~420-570 triangles each) and the thorn spire (~2 000 triangles).
- Draw-only: no collider, no navmesh, nothing on nav layers. Kept clear: keeps, nodes, building slots, points, camps,
  lairs, taverns, posts, caches, roads, crossings; a building placed later hides the small decor under it (node_added,
  `clear_area`).

## Tests
- `tests/test_gf_thornwater.gd` (new): meshes and budgets; LevelLooks lists the look; Crown Hollow gets nothing (no
  guard, no dressing, shared materials untouched); Thornwater: guard, idempotent, ground painted, water / nature
  recoloured, rig on the Thornwater preset, the dressing (reeds, thickets, 4 spires in water away from crossings, belt
  trees all outside the map, <= 260 full trees, nothing small on keeps / crossings, clear_area, Map detail Low halves);
  freed: shared materials equal the snapshot (twice); Low tier = palette, no dressing; sim mode / `disabled` = nothing.
  PASS.
- test_shader_lint, test_ge_additive_fog, test_gd_autumn_maps, test_map_review, test_map_start, test_mt10_bot_slots,
  test_mt9_catalog: PASS. smoke_test: victory=true. perf_test: OVER BUDGET on this run (norm 6.94-7.70 vs limit 6.72)
  with 6-8 other Godot processes running on the machine; the look never runs in perf_test (headless: GroundDetail is
  never created, so LevelLooks is never called), so this is machine load, to re-check on a quiet PC.
- Tiers: Low = palette only (the pre-G1 cost); Medium = the dressing with far tree stand-ins only; High / Ultra = the
  belt's front row in full trees (~200).

## The other ready maps (sameness check, not fixed)
1. **One horizon for every map.** `art/environment/horizon/` was baked for Crown Hollow's 120 m cliffs, and every level
   scene includes it: the same broken aqueduct (W) and octagonal pond (E) sit in the corners of Crown Hollow,
   Thornwater and Quartermeet (on the 176 m Quartermeet it also sits inside the camera's view ring). The worst shared
   element now. Fix: per-map horizon (or hide the landmark silhouettes off Crown Hollow).
2. **Quartermeet and Ashwind Reach share one autumn palette** (AutumnSwap is per biome, not per map): same olive /
   red-brown ground, same orange crowns and fog. Wave Strike's lane dressing sets Ashwind apart at play zoom, but the
   overviews still read as one set. Fix: a per-map accent on top of the autumn swap (e.g. Quartermeet golden fields /
   hay, Ashwind ash and heath).
3. **The crown isle is one template on all three skirmish maps** (same pillar ring, paving, pedestal and bridges).
   Thornwater now has its spires; Quartermeet's isle is still Crown Hollow's.
4. **Straight map edges** on the generated maps (Thornwater, Quartermeet): the rim is a painted square. The art can
   dress it (as here); bays / outcrops in the map data would fix it for real (`docs/handoff/for-lead.md`).
