# G-F round 3: Fire keep, Ember Crucible, keep damage smoke (2026-10-15)

Items 6, 7 and 9 of `docs/art/gf_review3.md`. Shots: `docs/art/lab/gf_r3_fire_keep/` (contact sheet
`gf_r3_fire_keep_contact_sheet.jpg`: before / after at `--gfx=high`, key PNGs `gf_r3_key_*.png`). Test and shots:
`tests/test_gf_r3_fire_keep.gd` (shots: `shots=1 tag=X`, `legacy_smoke=1` = the old smoke; always `--fixed-fps 60`).

## Ember Crucible (item 6)

- **Pit floor**: new `materials/ec_pit.tres` (crucible_glow, glow_color (0.25, 0.07, 0.03), energy 0.7). The shown value is
  about 0.22-0.26: dark ember red with a faint pulse, far under the glow cap. It is used for the cold slag crust floor
  in the bowl (the lumps stay ec_dark) and for a round floor in the chimney crown (PilotGlow, always on). Before, the
  cold crown showed the stack's pale stone cap.
- **Round crown**: the 4 dark bars that made a square around the stack became a round lip plus 8 rounded,
  6-sided rim stones of two heights. The lit coal bed is a round disc (it was a 0.52 x 0.42 box).
- **Light pool**: `crucible_pool.gdshader` is now alpha-blended (blend_mix). The colour is at value ~0.5 and alpha is
  at most 0.6, where before it was an additive pool.
- Budget (test_13c_v7): 6 materials (limit 9), 5638 triangles (limit 6000), still inside FOOTPRINT_HALF.
- **For the lead:** the review's "black square pit" in `gf3_key_fire_base_crucible.png` is almost certainly the
  **Fire Hall chimney** (`fire_hall.gd`, another owner). The base shot (`gf3_shots.gd _build_base`) places no Dragon
  Roost, so there is no Ember Crucible in that tile. `gf_r2_buildings_fs.md` traced the same kind of square to the hall
  chimney.

## Fire keep (item 7)

- `CROWN_SLIM` 0.82 -> 0.65: the claws, Ember Heart, rune band and crystal ring (ring radius 2.67 -> 2.11 m).
- New const `HEART_ENERGY` 2.16 (3.6 x 0.6), set on `heart_material` in `_crown_fit()`.
- `tests/test_gf_r2_fs.gd` now reads `FireKeepModel.CROWN_SLIM` and `3.25 x CROWN_SLIM` instead of the hard-coded
  0.82 / 2.67.

## Damage smoke on the Fire, Dusk and Nature keeps (item 9)

New `art/buildings/keep_damage_smoke.gd` (`KeepDamageSmoke.tune(p, low, high, alpha)`). Each keep calls it on
Smoke1 / Smoke2 at the end of setup.
- Puff size: 3.4 m puffs on the keep's own MIX quad (`MoteCap.sized`, so no new material), growing from 0.35 to 1.
- Motion: 5 s lifetime, 1.45-1.9 m/s, so the columns rise about 7-9 m with a slight lean.
- Colour: grey ramps capped by MoteCap (value 0.3-0.72), peak alpha 0.5 (Dusk 0.45), and the near-camera fade on
  the quad material.
  - Fire: warm grey.
  - Dusk: violet-grey, darker.
  - Nature: olive-grey.
- Cost: at Low, 55 % of the puffs are drawn, so fill stays at about the old cost.
- The Ice keep is untouched.

**Shot-tool trap (affects other shot scripts):** Godot only simulates particles that a camera or shadow pass draws.
A transparent emitter that is out of view stays at its birth point, where the ramp alpha is 0, so it is invisible
until the camera has looked at it for a whole lifetime. Shots that move the camera and capture 3 frames later
never show smoke. The "old smoke" in `tests/test_gf_keep_damage.gd`'s shots and possibly in the review's shots is
partly this artefact. The fix is to settle about 330 frames at `--fixed-fps 60` after each camera move
(`_rts(..., settle)` here). In game, smoke regrows within about 5 s when the player looks back at a keep.

## Tests

PASS: test_gf_r3_fire_keep, test_gf_keep_damage, test_gf_billboard_scale, test_gf_r2_fs, test_gb_fire, test_shader_lint,
test_13c_v7, smoke (victory=true).
test_ge_additive_fog FAILs on a hit in `art/vfx/vfx_cap.gd:63`, a new file from another agent, not in this task.

## Not done

- The Nature keep's columns start above the canopy (y 10.8 / 13.4), so the z30 shot crops them out.
- The review's "drop the outer ring at tier 1" (item 7) is not done (not in this task).
