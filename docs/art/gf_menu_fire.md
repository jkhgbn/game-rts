# G-F review 2 item 13 (art half): menu fire pillar and diorama glows

Owner: tech-artist. Files: `art/environment/menu_diorama/menu_diorama.gd`, `art/environment/menu_diorama/menu_beacon.gdshader`,
`tests/test_gf_menu_fire.gd`, shots in `docs/art/lab/gf_menu_fire/`.

## The cap
- Menu environment (`menu_diorama_env.tres`): ACES, `glow_hdr_threshold` 1.1.
- `MenuDiorama.GLOW_CAP` = 1.0, under the threshold, so nothing in the diorama feeds the bloom up to white.
- Additive emitters: peak = draw albedo max x colour ramp max x process colour, kept <= GLOW_CAP.
- Pillar: alpha-blended (`blend_mix`). Its pixel is a mix of what is behind it and its own colours, which are <= `BEACON_MAX` 0.9
  per channel. It can never be brighter than that.

## What changed
- **Pillar** (the altar's Beacon from `crown_pedestal.tscn`; that file is not edited):
  - The diorama sets a `material_override` with `menu_beacon.gdshader`. It uses the same cone mesh and the same `intensity` / `tint`
    instance uniforms that `CrownPedestalArt` drives.
  - Saturated amber core (0.9, 0.56, 0.12) where the cone faces the camera.
  - Orange rim (0.86, 0.32, 0.06) that fades out toward the silhouette.
  - The top fades out, and faint rings climb the column.
  - The High+ BeaconCore gets the same shader, with a lighter amber and a lower opacity.
  - The game's own beacon (`crown_beacon.gdshader`, additive) is unchanged.
- **Altar embers**: a per-diorama copy of the process material with its ramp scaled by GLOW_CAP / the pedestal's EMBERS
  gain (2.6).
- **Diorama emitters** (fireflies, kingdom motes, landmark and wizard weather): `_fade_ramp` caps its colour through
  `cap_glow`.
- **Wizards' and champions' own motes** (Vessa EmberMotes, Malrik VoidMotes, Torvald SnowMotes, Ysolde SeedMotes, Wayfinder
  LanternMotes, Mender Steam, which peaked at 2.0-2.2): `_cap_model_emitters` gives each one a duplicated draw material
  scaled under the cap, set as `material_override`. The shared model materials are untouched.
- **Kingdom glow pools**:
  - strength 1.1 -> 0.6;
  - focus level 2.1 -> 1.6;
  - dim level 0.55.
- **Not changed**:
  - Runes, crown jewel and CrownLight (small and gold, not white).
  - The landmark keeps' own emitters (keep art, High+ only).
- **Cost**: material swaps only, with no new nodes, passes or particles. BeaconCore still exists only at High+. Low costs the
  same as before.

## Framing rule
- **Panel on the right** (`MainMenu.column_on_side`, about >= 1222 px wide; checked at 1920x1080 and 1280x720): all 4 wizards
  are left of the panel. The shot is as authored.
- **Centred panel** (narrower windows, for example 1152x648): the panel hid Malrik.
  - The diorama reads `column_on_side` / `main_panel` (read-only, ancestors or their children).
  - It eases the wide shot (1.2 s) to:
    - `narrow_distance` 37 m (inside the far treeline);
    - `narrow_fov_deg` 41;
    - `narrow_focus_screen` (0.155, 0.64).
  - All 4 wizards then sit left of the panel.
  - It eases back when the panel goes to the side.

## Tests
- `tests/test_gf_menu_fire.gd`:
  - Runs tiers 0-3, then 0 again.
  - Checks:
    - the cap is under the threshold;
    - the Beacon and BeaconCore wear `menu_beacon` (blend_mix), with colours <= 0.9;
    - every additive emitter (landmark keeps excluded) and every pool is <= the cap.
  - Centred-menu framing: the camera pulls back more than 2 m, then comes back.
  - Result: `PASS gf_menu_fire (138 glow checks over 5 tier passes)`, camera 33.0 -> 38.3 m.
- Also pass:
  - test_gf_billboard_scale, test_shader_lint, test_ge_additive_fog, test_gf_r2_ui;
  - test_gd_menu, test_a2_10, test_gd_autumn_maps, test_12_v2;
  - smoke (`victory=true`).

## Shots (`docs/art/lab/gf_menu_fire/`, windowed `--gfx=high`)
- `contact_sheet.jpg`:
  - before / after at 1920x1080 and 1280x720;
  - before / after altar close-up;
  - after at 1152x648 with the centred panel.
- PNGs: `menu_diorama_before_high_1920x1080_wide_ui.png`, `menu_diorama_after_high_{1920x1080,1280x720,1152x648}_wide_ui.png`.
