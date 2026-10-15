# G-D autumn maps: the golden-autumn look in game

Maps whose biome is autumn (catalog `biome: "autumn"` / layout `biome = "autumn"`: Quartermeet, Fourfold Hollow,
Ashwind Reach) used to render green, because only the previews called `art/environment/autumn/autumn_swap.gd`.
The swap edits **shared, cached** materials in place, so it now restores them exactly when the map leaves.

## API (`art/environment/autumn/autumn_swap.gd`, reach it with `load()`)
- `ensure_for_level(level) -> Node` - the game hook (main.gd `_ready`). Reads the biome, and when it is autumn:
  swaps the shared materials, paints the ground (level ground + the shared `plateau_mat.tres`), switches the
  LightingRig to `preset_autumn.tres` (only a rig on the default `warm` preset: a mission's own mood wins), and adds
  an `AutumnLook` child. Idempotent (a second call returns the same node). Null when not autumn, in Bot Lab sim mode,
  or for a level outside the tree. Runs headless too: it is a look change with no cost, and tests prove it never leaks.
- `biome_of(level) -> String` - the level's MapLayout `biome` (`map_layout()` on LayoutLevel, the `layout` property on
  Wave Strike), else `MapCatalog.entry(MapInfo.map_id).biome`. `is_autumn(biome)`.
- `restore() -> int` - every recorded material back to its original shader and the original value of each parameter
  the swap or the ground paint set (unset parameters are unset again). `is_swapped()`.
- Low-level calls kept for the previews / labs: `swap_shared_materials()`, `apply_ground(root)`,
  `apply_lighting(root)`, `release()` (drops references only, no restore).

## How the restore stays exact
- Each material is recorded the first time it is touched: its shader (only when the swap changes it) and the
  original value of each key it is about to set. Later touches (a second autumn level, a second `apply_ground`) never
  overwrite the originals.
- `gd_detail` (PropsLook's tier) and `quality` (WaterQuality's tier) are never copied or recorded: they are carried
  across the shader change both ways, so a Settings change during an autumn match is kept after the restore and the
  autumn nature shader gets the tier (it declares `gd_detail`).
- The `AutumnLook` guards are counted: two autumn levels alive at once (a restart) share the swap, the **last** one
  leaving the tree restores.
- Per-map data the levels themselves write into the shared water material (`fords`, `foam_rocks`...) is not touched.

## Interplay
- **PropsLook**: writes `gd_detail` on the cached `nature_mat.tres` whatever its shader; `nature_autumn.gdshader`
  declares it, so tiers work on the autumn trees (tested at 3 and 0).
- **LightingRig / G1 tiers**: `apply(preset_autumn)` shows the rig's own copy of `world_env_autumn.tres`; `set_quality`
  layers the tier on that copy (tested at Ultra: preset kept, fog on). Nothing global changes.
- **AmbientLife**: its mood reads the rig's preset path (`autumn` -> full leaf fall) every 2 s plus the layout biome
  (`autumn_hint`); with the hook the rig carries `preset_autumn.tres`, so autumn maps get the autumn mood.
- **GroundDetail** bakes the ground 3 frames after `ensure`; the hook runs synchronously inside `_ready`, so the
  grass field is baked from the autumn ground colours in either hook position below.

## The hook (lead, scripts/world/main.gd)
After the map, its ground and the rig exist (`_build_environment`, `_build_map`, map dressing), right before the G2a
GroundDetail block. Placing it before `_build_map` would miss the ground (it does not exist yet). Placing it after
AmbientLife also works (tested: the test calls it on the level's `ready`, after the whole `_ready`), but before
GroundDetail is the clean spot. Exact lines: `docs/handoff/for-lead.md`.

## Tests and shots
- `tests/test_gd_autumn_maps.gd`: Crown Hollow reference snapshot (every shared material: shader + every uniform of
  the original and the autumn shader), two dummy autumn levels (shared swap, last one restores), then twice: Quartermeet
  through `MapCatalog.instantiate_level` with `ensure_for_level` on `ready` (autumn shaders, water colours, plateau and
  level ground, rig preset kept at Ultra, gd_detail 3 / 0, AmbientLife mood autumn), freed (nothing swapped, snapshot
  equal), Crown Hollow again (snapshot equal, no guard).
- Shots: `art/environment/autumn/gd_autumn_shots.gd` (windowed, `'--' --gfx=high tag=after` or `autumn=0 tag=before`),
  `docs/art/lab/gd_autumn/quartermeet_before_ford_z30.png` / `quartermeet_after_ford_z30.png`.
