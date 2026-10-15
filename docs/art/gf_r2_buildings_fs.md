# G-F round 2: Fire / Shadow building fixes (2026-10-15)

Items 3, 4 and 8 of `docs/art/gf_review2.md`. Shots: `docs/art/lab/gf_r2_fs/` (contact sheet
`gf_r2_fs_contact_sheet.jpg`, key PNGs `gf_r2_fs_key_*.png`, `before/` and `after/` at `--gfx=high`). The script is
`docs/art/lab/gf_r2_fs/tools/gf_r2_fs_shots.gd` (`--mode=fs` = Fire vs Shadow, `--mode=mirror` = Shadow vs Shadow).
Fire keep "before" = the review's own shots (`gf_review2/high_fs/`), because the keep change was live before the first
local run.

## Item 4: Fire keep and the bright Fire glows

- **Crown lower and slimmer** (`art/buildings/fire_keep.gd`, `_crown_fit()` in `_ready`, before `_collect_parts`):
  spire claws scale (0.82, 0.75, 0.82) about their foot (y 12), the Ember Heart, rune band and crystal ring sit 25 %
  lower (`HEART_Y` 16.2 -> 15.15, `RING_Y` 14.0 -> 13.5) and scale 0.82 (the crystal ring radius 3.25 -> 2.67 m); the
  heart light and sparks follow. Every scale write in the hooks (appear, site, collapse, rune wobble) carries
  `CROWN_SLIM`; the spire topple keeps its scale. The `.tscn` and `fire_keep_build.gd` are unchanged (run time only).
  The crown is still the keep's tallest part (claw tips ~17 m, chimney 14.9 m) and no longer reaches the top edge of
  the start view.
- **Ember Crucible**: `ec_molten`, `ec_white_hot`, `ec_coals` now draw with
  `art/buildings/fire/ember_crucible/crucible_glow.gdshader` (the kit's `unit_glow` + the buildings' `glow_cap`, same
  uniforms and instance slot 5). The bowl reads saturated orange instead of a white disc; forge flares still read.
- **The white square in the review shot was the Ember Hall chimney** (not the crucible): its coal bed was a 1.35 m
  glowing box under 20 additive flames. Now an own dimmer glow channel (energy 1.1, under the cap's knee), set deeper,
  broken by five dark clinker lumps, and 12 smaller flames (`fire_hall.gd`, FireHallModel's own `_build_structure`
  only: every other hall overrides it).

## Item 3: Shadow roofs and the Dusk Keep

- **Gloom Hall / Gloom Forge** (`shadow_hall.gd` `_slate_roof`, also used by `forge/shadow/shadow_forge.gd`): same
  outline as `_gable_roof` (roof holes still fit), but single slates ~0.6 m wide in staggered rows, tilted 7 deg
  flatter (a shadow line per row), shade per slate from three team shades (dark x0.74, mid x0.87, team) with a lighter
  row every other course, a sawtooth eave row, a thick dark eave board, a dark ridge cap with a thin iron line. One
  merged painted surface (no new draw call; `_vc_team` lists the mid shade).
- **Hovel** (`hovel.gd` `_slates`): the four smooth stepped bands became ~100 slates on the six faces (same shading
  rules, sawtooth eave), and the eave ring is twice as thick.
- **Dusk Keep** (`dusk_keep.gd`): the body was violet because of its lights: the default team kept a full-saturation
  spire light (0.6, 0.3, 1.0) at energy 2, other teams a lightened team colour. Both lights now use
  `light_tint(glow)` = the team glow at saturation <= 0.4 for every team (energies 1.3 / 1.0), the idle rim is slate
  lilac (0.55, 0.5, 0.7) at 0.45, and the merged body's vein emission is x0.7 (`CRACK_ENERGY`). The glow parts keep
  the full glow. The value-pass grade uniforms (`ShadowDress.grade`: team 0.4 / 0.88, body 0.4) are applied the same
  way to both sides (they are per material, not per team); the difference came from the lights, not the grade.
  Art Lab: body chroma 43 -> 23 (S1 line), body L* 29 -> 26.

## Item 8: Shadow construction site

The black square was the squashed plinth (dark stone, 5 % of its height) plus the half-size dead ground.
- **Site pad** (`ShadowDress.site_pad_items`, every tier, merged with the model's painted material): loose slate flags
  with gaps (edge cells mostly missing, never a square), layout stakes with cords, timber beams and cut slate. Gloom
  Hall-type models build it in `_build_state_nodes` (Bazaar / Paddock / Forge inherit it), the Hovel in `_build_parts`.
- The scaffold shows from progress 0; the plinth stays hidden until the walls start (`SITE_PLINTH_AT` 0.07 Hall,
  0.08 Hovel); the pad hides when built or destroyed.
- **Dead ground** (`shadow_dead_ground.gdshader`, Medium+): while building the ash is lifted toward value ~0.2
  (fades out by build 0.85) and the soul veins show faintly (x0.3) from the first frame.

## Art Lab (windowed rescore, no FAIL)

| Asset | Before | After | Notes |
|---|---|---|---|
| fire_keep | PASS 95 | PASS 92 | R6 team-colour area -9 (the slimmer crown is less of the body) |
| dusk_keep | PASS 87 | WARN 86 | R5c (noisy) one glow point dL -3 on the darker body (twice); R5 WARN as before |
| shadow_hall | PASS 90 | PASS 90 | |
| hovel | PASS 85 | PASS 89 | |
| ember_crucible | WARN 92 | WARN 92 | R1 silhouette area WARN unchanged |
| fire_hall | PASS 92 | PASS 91 | |
| shadow_forge | - | PASS 90 | first scorecard |

## Tests

`tests/test_gf_r2_fs.gd` (crown, crucible cap, chimney flames, Dusk Keep light grade for two teams, three slate
shades on the Hall / Hovel, site pad / scaffold / plinth at 0, 0.5 and 1, collapse still finishes). Passing:
test_gf_r2_fs, test_shader_lint, test_ge_additive_fog, test_ge_value_pass, test_gb_fire, test_gb_shadow, test_gc_shadow,
test_13c_v7, test_forge_model, test_gb_leftovers, smoke (victory=true).

## Not done

- The construction outline (glowing violet square, art-keep 8.2) is unchanged; it is now the loudest part of a site.
- The Shadow BuildRing motes (pale violet puffs round a site) could follow the item-7 particle cap.
- The Shadow tower roof (review item 3 mentions it with the Hovel) was not touched.
