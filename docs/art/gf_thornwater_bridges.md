# G-F Thornwater timber bridges (2026-10-15)

Thornwater's two crown lane bridges (`bridge_crown_a` / `bridge_crown_b`) read as flat green "carpets": the stone
lane bridge deck carries moss in `nature_mat`, and Thornwater's wet moss tint turned the whole deck green. On
Thornwater only, they now become a timber trestle.

## What changed
- `art/environment/bridges/timber_bridge_meshes.gd` (new, no class_name, reached with `load()`):
  `lane_bridge(src) -> ArrayMesh`, built once per source mesh and cached. It has:
  - **Deck:** planks with 4.5 cm gaps, split over stringers, grain strips, silvered / damp boards. Stringers, fascia
    and kerb logs below.
  - **Supports:** three pile bents per bridge with cross braces and fender clusters (where the foam rocks sit).
  - **Rails:** a top rail and a mid rail on posts; one mid rail is broken.
  - **Ends:** the corner posts stay under the original braziers, with stones and moss. Sill logs and sheet-pile bank
    revetments.
  - **Wet foot:** every pile has a dark wet band and a slime band at the waterline.
  - **Material and colours:**
    - Surface 0 uses `env_painted_mat` (same format as the road bridge's timber; COLOR.a = height gradient) with
      Thornwater wood colours: grey-brown planks, dark beams, slime green only at the waterline.
    - The gold and ember surfaces and the braziers are the source's own, so the lit braziers stay.
  - 4635 tris against 6536 for the stone source. Same 3 surfaces, so **0 extra draws** at every tier, Low included.
- `art/environment/crown_variants/crown_isle_variant.gd`:
  - `_recolor_crossings` swaps the `lane_bridge.res` mesh for the timber one when `variant == &"thornwater"`, through
    the existing `_swap` / `_restore`. The original mesh comes back on `_exit_tree` / rebuild.
  - The new count is `counts["timber_bridges"]`.
  - Nothing is written to shared materials or source meshes. No colliders, navmesh or map data change. Crown Hollow
    and every other variant are unchanged.
- The Thornwater **steps** (`steps_a` / `steps_b`) stay stone (repainted as before). They are a wading crossing that
  slows units, so a boardwalk there would tell the player something false.

## Shots
`docs/art/lab/gf_thornwater_bridges/` (windowed, `--gfx=high`, script `art/environment/bridges/tw_bridge_shots.gd`,
`--before` = `CrownIsleLook.disabled`):
- `contact_before_after.jpg`: game camera zoom 20, a three-quarter view and a close view, before | after.
- `before_bridge_side.png`, `after_bridge_side.png`, `after_bridge_close.png`, `after_bridge_game_z20.png`.

## Test
`tests/test_gf_thornwater_bridges.gd` checks:
- **Mesh:** cached, surface count kept, gold / ember untouched, tri budget, footprint, braziers copied, flat deck,
  no green deck, dark wet foot, plank gaps.
- **Levels:**
  - Crown Hollow and Quartermeet are unchanged.
  - Thornwater High and Low get 2 timber bridges, with 0 Low draws, no colliders and no new children.
  - A `set_quality` toggle keeps the timber, and removing the variant restores the stone mesh.
- **Shared materials and meshes:** a snapshot before and after must match.
