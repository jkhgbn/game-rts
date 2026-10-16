# G-F VFX caps (review 3, top-6 item 2)

## Problem
`gf_review3.md` found two things in the mixed melee:

- a white HDR steam / frost blob;
- a yellow-white sphere on a Fire unit at z14.

Since the billboard keep-scale pass (`gf_billboard.md`), particles draw at their full size. Their HDR colours (up to 8.0) now read as white balls.

## Root cause and fix
- **`art/vfx/vfx_cap.gd` (`VfxCap`, static).** `VfxCap.fit(emitter)` runs once when an emitter is built, so there is no per-frame cost, the draw calls are the same and Low costs nothing more. It caps three things:
  - **Particle draw materials:** HDR albedo is clamped to 1.0.
  - **Colour ramps:** the ramp is scaled down with its hue kept, using the `test_gf_keep_damage` caps:
    - mix: peak <= 0.72;
    - additive: peak x 6 <= 1.0;
    - specks (drawn size <= 0.25 m) count as a stack of 1.
  - **Lit shards:** the emission scales with the colour.
- **Every maker calls it** at its emitter factory:
  - caster fire / ice / nature / shadow;
  - cavalry, champion, ice, nature, spell, terrain, titan, titan ground, trade;
  - mapfill, mapfill beast, mapfill wyrm;
  - unit fire gun / ice rifle / nature T3;
  - the Medium+ `SpellFxG`.
  `CombatVfx` pools get their look only when they fire, so `_look()` calls `VfxCap.fit_parts(pmat, mesh)`. The new `look_parts()` gives the test a read-only view.
- **`spell_vfx` uses `vfx_particle.gdshader` (premultiplied).** Its `additive` instance uniform (>= 0.5) decides whether it counts as add or mix.
- **Steam (explicit):**
  - `SpellFxG` `steam` palette, was (1.5, 1.7, 1.9): now (0.64, 0.68, 0.72) / (0.54, 0.62, 0.70) / (0.60, 0.66, 0.72, 0.45);
  - `ice` palette core, was 1.6: capped to 0.72;
  - `steam_puff` 10 -> 5;
  - `caster_fire_vfx` `steam_burst`: grey-blue initial ramp <= 0.72;
  - `steam_sparks` and the mana-scald flares: no white HDR.

## Test
`tests/test_gf_vfx_caps.gd` builds every Node3D maker in `art/vfx` and `scripts/vfx`, plus `UnitVfx` (its families) and `SpellFxG` at Ultra. It measures every emitter, plus the CombatVfx looks, using its own copy of the maths. Pale `SpellFxG` billow palettes must be <= 0.72.
- Before the fix: FAIL, 342 emitters over the cap.
- After the fix: PASS, 2497 emitters.
- Shots mode: `shots=1 tag=X [vessa=1]`.

## Still open (not owned here)
The remaining white silhouette in the melee, visible in the after shots, is the **mount hit flash**.
- `art/units/kit/mount_model.gd` adds the whole beast to `_flash_hit_targets`.
- The Frostcrown bear (`art/units/ice/frostcrown_juggernaut/parts/frostcrown_bear.gd`) keeps `hit_flash_scale` 1.0, so the flash adds emission 2.0 x the whole body.
- Proposed fix, after that loop in `mount_model.gd`: `hit_flash_scale = minf(hit_flash_scale, 0.4)`. The other option is to set the bear's `hit_flash_scale` like the blaze and gloam riders do.

## Shots
In `docs/art/lab/gf_vfx_caps/`:
- `gf_vfx_caps_contact_sheet.jpg`: before / after at z30 and z14;
- the `key_*` PNGs.
