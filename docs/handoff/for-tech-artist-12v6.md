# For 12.V6 (biome scatter integration): notes from the biome set agents

Each biome set agent (12.V7-12.V12) appends its own section below. Please keep the sections separate.

## Shared set-file format (agreed for 12.V9-12.V12; 12.V7 riverbank / 12.V8 meadow have ENTRIES only)
`art/environment/biomes/<id>/<id>_set.gd` (extends RefCounted, no class dependency: `load()` it) keeps the
map-fill.md section-10 constants `BIOME_ID`, `GROUND_TINT`, `ENTRIES` (paths + `per_100m2`, `scale`, `cluster`,
`shadow`, `range`, `place`, optional hints) **and** adds
`static func items() -> Array[Dictionary]` with, per item:

| key | type | meaning |
|---|---|---|
| `mesh` | Mesh | the loaded mesh (surface 0 = shared `nature_mat.tres`, optional surface 1 = contact disc) |
| `material` | Material | surface 0's material (the shared painted `nature_mat.tres`) |
| `density` | float | instances per 100 m2 at full biome weight (= `per_100m2`) |
| `scale` | Vector2 | uniform scale range |
| `vis_end` | float | visibility range end (m), fade margin 10 m (= `range`) |
| `shadow` | bool | casts shadows |
| `variants` | int | shape variants in the mesh (3, picked by the shader from the instance position) |

Extra optional keys copied from ENTRIES when present (`path`, `cluster`, `place`, `gap`, `yaw`, `yaw_jitter`...).
Scatter: ONE MultiMesh per mesh and chunk, uniform scale, y = 0, random yaw unless the item has `yaw`.

## 12.V9 Heath (`art/environment/biomes/heath/`)
- Set: `heath_set.gd` (`class_name HeathSet`, but read it by path): `BIOME_ID &"heath"`,
  `GROUND_TINT Color(0.52, 0.47, 0.25)` (slot 1 of the ground's `biome_tints`), `VARIANTS 3`, `INSTANCE_BUDGET 1600`,
  `WIND_YAW -0.6435`, 4 ENTRIES / items(), all `place &"land"`, **nothing casts shadows**:

| mesh | per 100 m2 | scale | cluster | range | extra |
|---|---|---|---|---|---|
| `heath_tall_grass.res` | 36 | 0.8-1.25 | 0.6 | 65 | `yaw -0.6435`, `yaw_jitter 0.35` |
| `heath_heather.res` | 18 | 0.8-1.35 | 0.8 | 90 | |
| `heath_gorse.res` | 3.2 | 0.85-1.2 | 0.5 | 90 | `gap 2.2`, contact disc |
| `heath_lichen_stones.res` | 2.4 | 0.75-1.3 | 0.3 | 90 | `gap 1.8`, contact disc |

- **Please honour `yaw` on the tall grass**: every blade is combed toward the mesh's local +X, and `yaw` turns +X to
  `nature_painted.gdshader`'s default `wind_dir (0.8, 0.6)`, so the whole heath leans one way and the gusts push the bend
  further (`Basis(Vector3.UP, yaw + randf_range(-yaw_jitter, yaw_jitter))`). Random yaw still works, just less windswept.
  If someone changes `wind_dir`, update `WIND_YAW` / the entry's `yaw` (tests/test_12_v9.gd fails when the default moves).
- `cluster`: as the meadow set (a fraction `cluster` in patches of ~8, gaussian sigma 1.2 m, x2 for entries with `gap`).
  `gap` = min distance between two instances of that entry; they need ~gap / 2 clearance from roads / slots / buildings.
- Budget: sum per_100m2 = 59.6 -> <= ~1 400 instances on the ~2 350 m2 of weighted heath (ruins > riverbank > meadow >
  Old Wood > heath, as `ground_params.gd`); ~680 on the real skirmish map once roads, trade posts, trees, landmarks and
  buildings are cleared (`heath_preview.gd mode=map`). Map detail Low: halve it.
- Triangles drawn per variant: grass 144-171, heather 244-370, gorse 570-828, stones 166-292. Remember the collapsed
  variants are still submitted (full meshes: 315 / 880 / 2 044 / 657): on the map the heath adds ~+0.3 M primitives at
  zoom 45 over the west flank, GPU time unchanged on the GTX 1660 (4.54 ms both).
- The existing glade tufts / ferns of `MapDressingArt` still grow on the heath today (see
  `docs/art/screens/12_v9_map_z25.png`); the heath set replaces them there.
- Reference scatter: `heath_preview.gd` `_scatter()` + `heath_weight(q)` (the ground's zone weights without the paint
  jitter). Screens: `docs/art/screens/12_v9_contact.png`, `12_v9_patch_z40.png` (= `biome_heath.png`),
  `12_v9_west_z40.png`, `12_v9_map_*.png`.
