# G-F review 2 item 11: m02 frozen Emberguard + border cliffs (2026-10-15)

Review item (`docs/art/gf_review2.md` 11): in mission 2 the frozen Emberguard (thaw targets) were plain cyan glass
boxes, and the border read as "grey fish scales".

Shots: `docs/art/lab/gf_m02/gf_m02_contact_sheet.jpg` (before | after, 10 rows) and key PNGs
`gf_m02_key_{block_close,overview,border_north,sentinels}.png`. Tool: `docs/art/lab/gf_m02/tools/gm_shots.gd`
(windowed, `-- --gfx=high --tag=after`, `--undress` for the before set) + `gm_sheet.py`. The overview "before" is the
review's own shot (old painted canopy).

## 1. Frozen Emberguard blocks (`art/environment/snow/frozen_block_art.gd`, `FrozenBlockArt`)
Where they come from: `MissionFrozenEmberguard` (`scripts/campaign/frozen_emberguard.gd`, built in `mission_02.gd`
`_build_map`, rows `EMBERGUARD_TABLE`: 2.4 x 2.0 x 2.4 box + 3 capsules under node `IceBlock`, cylinder `Stump`,
collider radius 1.2; `lit_up` on thaw, then a 1 s tween fades the box and hides `IceBlock`; `load_row` hides it quietly).

`FrozenBlockArt.dress_block(block)` (idempotent, meta `_frozen_block_art`) keeps every gameplay node and hides the
placeholder meshes:
- **Ice**: a faceted block 2.5 x 2.15 x 2.4 (7-9 sided rings: sunk foot, bulge, shoulder, slanted broken top, 3-6
  degree lean) + two smaller crystals grown against the sides. `frozen_ice.gdshader`: deep blue-green ice (darker
  face-on), frosted rim on every facet edge (edge code in COLOR, the triangle diagonals coded out), rime on the base,
  dusting on up faces, a surface crack sheet + a parallax inner crack layer + milky veils + hoar patches (Medium up).
  From Medium up a back-face pass (`frozen_ice_back.gdshader`, drawn first) gives the block volume. Brightest albedo
  = frost 0.76-0.87 (value pass ~0.8); no emission (`glow` 0).
- **Prisoners**: the real Flame Guard (sword arm frozen up, chest twisted) and an Ember Archer behind him (head down),
  process off (no idle motion), shadow blob / Fx hidden, scaled from their mesh bounds to 1.5 m / 1.38 m, a cold
  multiply overlay (`frozen_body.gdshader`, feet darker in the rime). They read as Fire soldiers, muted.
- **Base**: a snow rime mound (FrozenLook snow material) round the foot, always there.
- **Thaw** (`lit_up` -> `shatter(block)`): ice and figures go at once (the real squad spawns 2 m in front), 5 / 7 / 10
  shards (Low / Medium / High+) fly, land and sink into the snow, a low cold puff (alpha 0.32, value ~0.8, not a white
  disc) spreads in 0.7 s; all freed after 4.5 s. When `IceBlock` hides (thaw tween or a load of a thawed block) a ring
  of 7 broken ice teeth + a cracked slab shows on the mound (`IceStump`).
- **Sentinel shells** (`dress_shell(shell)`): the rime colossi's 2.6 x 3.6 x 2.6 "IceShell" box becomes a 2.9 x 3.9
  faceted block (clearer, the colossus shows) + a rime mound. Name / position kept, so `_shatter_shell` still frees it.

Hooking: `FrozenLook.dress_level(level)` (already called at the end of `mission_02.gd` `_build_map`) now dresses every
`IceBlock` parent with `lit_up` and every `IceShell` it finds. The shells are spawned later (`_spawn_sentinels`), so
they need the one-line load-guarded hook in `docs/handoff/for-lead.md` (the shot tool calls `dress_shell` itself).

## 2. Border: snow-capped cliffs, sparse firs (no more scales)
Cause: m02 has no MapDressing (`_use_map_dressing()` false), so its border was ground.gdshader's painted canopy:
a 3.4 m grid of round crowns, every cell filled, each a dark dome with a pale snow crescent = scale mail.
- `FrozenLook.add_snow_border(level)` (from `dress_level`, 120 m levels without MapDressing only, node `SnowBorder`):
  the Crown Hollow cliff + plateau meshes (`map_cliffs.res`, `map_plateau.res`; north 10 m ... south 3 m, never over
  the play square) with their own materials: cliffs = `cliff_mat.tres` copy with `cliff_snow` 1, plateau =
  `plateau_mat.tres` copy with the FrozenLook snow ground. Draw-only, no collider / nav.
- `env_painted.gdshader` `cliff_snow` (0 = off, every other map unchanged): rock pulled to cold blue-grey granite
  (`snow_rock`, painted value pattern kept), snow (`snow_cap` 0.74-0.86) on faces that look up (n.y > 0.55, broken).
- `ground.gdshader`, snow_mode only (other maps unchanged): `canopy_crown(p, sparse, grad)`; with `sparse` the crown
  cell is 2.2 m, crowns 0.4-0.8 x, and a cell keeps its fir only where a clump noise allows (stands and glades);
  `snow_border()` paints firs dark with a little snow on the lit top, each throwing a short shadow on open snow; the
  forest-floor band of the plateau stays snow (no trees stand on it). `cell_vn()` = hash value noise (no texture).

## Tiers / cost
Low: no cracks / veils / hoar, no back-face pass, 5 shards (the old block was one transparent box + 3 capsules + 2
opaque Fire models now: 2 small merged models per block, 3 blocks). The cliff + plateau meshes are the ones every
skirmish map draws at every tier (62k + 3.6k verts, one draw each).

## Tests
`tests/test_gf_m02.gd` (3 real blocks, no mission: crystal size / outward winding, shards winding, figures frozen +
overlay, mound, teeth hidden then shown, shatter count per tier, quiet load before / after the dress, idempotence,
Sentinel shell, snow border). Also run: test_shader_lint, test_ge_additive_fog, test_ge_fixes_b, smoke.
