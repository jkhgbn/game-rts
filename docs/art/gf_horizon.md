# G-F per-map horizon

G-F "The other ready maps" item 1 (`docs/art/gf_thornwater.md`). Owner: tech-artist. Date: 2026-10-15.

## Problem
`art/environment/horizon/` was baked around Crown Hollow (120 x 120 m). Every map showed its landmarks: the
watchtower (NE), the hill shrine (NW), the aqueduct (W), the stone ring (SW) and the octagonal pond (E).

There was a second bug. On autumn maps, `AutumnSwap` replaces the horizon shader with `horizon_autumn.gdshader`,
which has no `fit_xz`. So the Quartermeet and Ashwind Reach horizons were **not fitted**: the ring stayed at the
120 m size inside a 176 m (or 192 x 96 m) map. The aqueduct and the forest sat on the play area
(`lab/gf_horizon/key_quartermeet_west_z55_before.png`).

## Design
- **Tags, not copies.** `horizon_tag_bake.gd` (run once; run it again after a horizon re-bake) writes a landmark
  tag into UV.y of the 8 baked sector meshes:
  - 1 = tower, 2 = shrine, 3 = aqueduct, 4 = stone ring, 5 = pond, 6 = granite crag, 0 = everything else.
  - Only small pieces (20 m or less) that are flat rock / ruin (UV.x 1.0) or water discs (UV.x 0) are tagged.
    Crowns and ground sheets never are.
  - `horizon.gdshader` never reads UV.y, so Crown Hollow is identical: same vertices, same 96 407 triangles.
- **Variants.** `HorizonVariant` (`horizon_variant.gd`) picks the kind:
  - `crown_hollow`: map id "" / crown_hollow.
  - `fen`: thornwater, or biome marsh / fen / swamp.
  - `autumn`: biome autumn.
  - `neutral`: everything else.
  - The id comes from `MapInfo.map_id`; the biome comes from the level's layout, then the MapCatalog entry.
- **What a variant mesh is.** For a non-Crown-Hollow kind, `meshes_for(kind, half, base, tier)` builds 8 new
  ArrayMeshes:
  - the base triangles minus the landmark tags (fen also drops the granite crags);
  - the map's own dressing, tagged 10, made from the builder's own primitives (domes, conifers, prisms, discs,
    boulders);
  - the fit applied **on the CPU** (`v += HorizonFit.fit_point(anchor, half) - anchor`, so the result is the same
    as the shader). The shader fit then rests at 60 x 60, so the result is right under either shader, which fixes
    autumn maps;
  - the same `horizon_mat.tres` material, so AutumnSwap and the fog still apply.
  - The result is cached per kind / size / tier.
- **Dressing per kind** (in the baked frame, at the old landmark sites, all outside the view ring):
  - Fen: a mere with snags and sedge (E), a stilt hut in a pool (NE), a drowned grove (NW), a giant willow by a
    pool (W). Domes are retinted to willow, conifers to alder, ground to peat / sedge.
  - Autumn: a windmill facing the map (NE), a farmstead (NW), an orchard (W), a stubble field with stooks and ricks
    (E).
  - Neutral: tors (NE, NW), a boulder field (W), a pine stand (E).
  - All kinds: crowns fill the old aqueduct corridor.
  - Medium and above add glade pools, fences and extra stooks.
- **Hook.** None needed: `HorizonFit._fit_to_map` (already deferred after the level's `MapInfo.setup`) calls
  `apply_variant`. `level_looks.gd` is not touched.

## Quartermeet palette (follow-up)
Quartermeet has its own look (`docs/art/gf_quartermeet.md`). Its horizon used to keep AutumnSwap's shared orange /
russet mix; it now has its own palette:
- On the layout id `quartermeet`, `HorizonFit.apply_palette` sets a `material_override` on the 8 sectors. The
  override comes from `HorizonVariant.palette_override(map_id)`: a cached duplicate of `horizon_autumn_mat.tres`
  (same shader, same cost) whose `far_*` tones come from `QuartermeetPalette.NATURE` (×0.86 for haze), plus a
  late-green minority (share 0.14).
- The shared materials are never touched, so Ashwind Reach and every other map are unchanged.
- The test checks both maps: Quartermeet has the override, and Ashwind has none and its shared material is
  intact.
- The dense band just outside the map is the ground's painted canopy, which QuartermeetLook already recolours.
- Shot: `lab/gf_horizon/after/quartermeet_overview_qm_palette.jpg`, also `key_quartermeet_overview_after.png`.

## Cost
- No new shader pass, light or particle. Draw-only, with no colliders and nothing on the navmesh.
- Triangles (baked 96 407):

  | Kind | Low | High |
  |---|---|---|
  | Fen | 95 567 | 96 127 |
  | Autumn | 96 213 | 96 736 |
  | Neutral | 96 011 | 96 319 |

  Low is always at or below the baked ring.
- Draw calls are unchanged: 8 sectors, 1 material.
- Building a variant takes about 100-160 ms on the CPU the first time it loads (cached after). Crown Hollow costs
  nothing new.
- Every vertex is at least 9.5 m outside the map rectangle on every tested size (120, 176, 192 x 96).

## Tests
- `tests/test_gf_horizon.gd`: checks that the tags exist, then runs 5 maps at tiers Low and High and checks:
  - the variant chosen;
  - Crown Hollow keeps all 5 landmarks, has no dressing and keeps the baked triangle count;
  - the other maps have no landmarks and have their own dressing;
  - the material;
  - no vertex inside the map.
  - It also loads the real Quartermeet level through MapCatalog.
- Also passing: test_shader_lint, test_ge_additive_fog, test_gf_thornwater, test_map_start, test_horizon_fit,
  test_map_p3, test_gd_autumn_maps, and smoke (`victory=true`).

## Shots
`docs/art/lab/gf_horizon/`:
- `before/` and `after/`: windowed `--gfx=high`, made with `art/environment/horizon/gf_horizon_shots.gd`;
- `gf_horizon_contact.jpg`: the before / after contact sheet;
- 4 `key_*.png` files.

The Crown Hollow before / after difference is about 1 % of pixels, spread evenly over each frame. That is ambient
motion, not geometry.
