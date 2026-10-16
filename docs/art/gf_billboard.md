# G-F root-cause pass: billboard particles kept their scale (2026-10-15)

## The bug class

A billboard particle material rebuilds the model matrix from normalised camera axes. This applies to:

- a `StandardMaterial3D` with `billboard_mode` PARTICLES or ENABLED,
- a ShaderMaterial that billboards in `vertex()`.

The particle's own scale is therefore lost unless `billboard_keep_scale` is set. That scale comes from
`ParticleProcessMaterial.scale_min / scale_max / scale_curve` (or `CPUParticles3D.scale_amount_*`). Without it, every
particle drew at the full quad size, no matter what its author wrote:

- motes meant 0.06 m drew 0.7-1 m,
- sparks meant 0.08-0.14 m drew 1 m,
- flames meant 0.4-0.8 m drew 1 m,
- smoke meant 2.2-2.6 m drew 1 m,
- grow / shrink curves were ignored.

The VFX makers (`art/vfx/*`) and most unit models already set it. The building kits, the keeps, part of the Fire / Shadow
unit kits, the three wizards and two VFX makers did not. The Ice / Nature motes were fixed earlier with sized quads
(`MoteCap`, `docs/art/gf_r2_buildings_in.md`).

## The test: `tests/test_gf_billboard_scale.gd`

The test has two parts.

**A, runtime.** It instances every `.tscn` under `art/buildings`, `art/units` and `art/vfx` (previews and tool folders
skipped). That makes 188 scenes. Each building is checked in three states:

- built, with tier 3 and 20 % HP,
- a construction site at 30 %,
- destroyed.

Each unit is also checked after `play_death`.

For every `GPUParticles3D` / `CPUParticles3D`, the test fails when two things are both true:

- the draw material billboards without keep scale,
- the process scale is not about 1 (± 0.15), or there is a scale curve.

A sized quad (MoteCap style: the size is in the quad and the scale is about 1) passes. The unit kits' High-only
emitters are forced through their quality overrides. The building High-only emitters only exist with `-- --gfx=high`,
which gives 1840 emitters (1710 at Low, which is what CI runs).

**B, source.** These two rules keep the bug from coming back through code paths the instancing does not reach:

- Every `X.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES` in `art/**.gd` and `scripts/vfx/**.gd` must set
  `X.billboard_keep_scale = true` within the next 14 lines. This covers the static VFX makers.
- Every `.tscn` / `.tres` block under `art/` with `billboard_mode = 3` must have keep scale.

`art/environment` and `art/cinematics` belong to other owners, so the test prints them as notes instead of failing on
them (see the end of this note).

**Before the fix:** 664 emitter hits (376 unique) plus 55 source hits. **After:** PASS at Low and at High.

## The fix

`billboard_keep_scale = true` was set on every shared particle material that lacked it. Each line is marked
`# G-F billboard pass` in the GDScript, with the same line in the scenes.

| Where | Materials |
|---|---|
| Building kits | `fire_hall.gd` `_quad` (every Hall / Forge / Stables / Market / lair built on FireHallModel), `hearth_small_building.gd` `_quad` (houses, towers, walls, Shadow tower included), `shadow_dress.gd`, `nature/nature_kit.gd` (2) |
| Keeps | `fire_keep_build.gd`, `dusk_keep_build.gd`, `ice_keep_build.gd`, `nature_keep_build.gd` + the baked materials in `fire_keep.tscn` (2), `dusk_keep.tscn` (2), `ice_keep.tscn` (1), `nature_keep.tscn` (4) |
| Neutral buildings | `capture/essence_well/build_essence_well.gd` + `essence_well_mist_quad.tres`, `guilds/greywater_lodge`, `guilds/magpie_den`, `tavern/neutral_look.gd`, `tavern/tavern_model.gd`, `trade_post/trade_post_model.gd` |
| Units | `fire/build_fire_units.gd` + `ash_hurler / cinder_hand / ember_archer / flame_guard .tscn`, `fire/cinderlock/build_cinderlock.gd` + `cinderlock.tscn`, `shadow/_build_shadow.gd` (2) + `shadow/materials/shadow_particle.tres`, `shadow_smoke.tres`, `neutral/materials/warden_particle.tres`, `helpers/helper_vey/helper_paint.gd`, wizards `malrik.gd`, `vessa.gd`, `ysolde.gd` |
| VFX | `vfx/ice_vfx.gd`, `vfx/str_int/str_int_vfx.gd` |

Notes on the fix:

- **Shared materials.** Every user of each material was checked. The materials are particle-only, and sized quads
  (scale 1) look the same with keep scale.
- **Shadow `.tres` users.** `shadow_particle.tres` and `shadow_smoke.tres` are also used by the cinematics stage sets.
  Their emitters now draw at their written size too.
- **MoteCap emitters** on a building's own soft dot (`apply_own`) now also apply their relative 0.x-1 spread. That
  spread is what `normalize_scale` intended.
- **Cost.** Particle counts, materials and draw passes are unchanged. Keep scale adds one matrix multiply in the vertex
  stage, so the Low tier costs the same. The additive materials keep `disable_fog`.

## The look (shots: `docs/art/lab/gf_billboard/`)

Shots were taken windowed at High, 1600 x 900, with `--gfx=high`, on a Fire / Shadow match and an Ice / Nature match:

- Contact sheet: `gf_billboard_contact_sheet.jpg` (12 before | after pairs).
- Key PNGs (before above after): `gf_billboard_key_{fire_hall_dmg_z18,fire_base_dmg_z30,shadow_hall_dmg_z18,fire_site_z14}.png`.
- The raw shots stay in `before/` and `after/`. The folder has a `.gdignore`.
- Shot tool: `tools/gfbb_shots.gd`. Sheet tool: `tools/gfbb_sheet.py`.

What changed on screen:

- **Flames:** damaged Hall, Hearth, keep, Gloom Hall and Frost Hall; chimney, brazier and kiln fires; soul flame. The
  1-1.2 m white-hot balls are now 0.3-0.8 m licks of flame. The damage reads as fire, not as a glare.
- **Sparks, embers, motes and glints:** the Fire tower orb, forge anvil, chimney embers, void motes and the construction
  BuildRing. These were the remaining 1 m golden or lilac "balls" around buildings. They are now the specks their
  authors wrote. The construction ring is subtle at z30, which matches the Ice / Shadow / Nature keeps (sized quads,
  0.12-0.15 m). The site still reads through the outline and the scaffold.
- **Smoke, mist and dust:** damage smoke, chimney smoke, ground mist, frost mist, collapse / settle dust. These grow from
  1 m to their written 1.3-3.0 m. Their alpha ramps (0.45-0.8, MIX, dark colours) stay readable at that size. Damage
  smoke now forms a column instead of a few beads.
- **Units:** the Ash Hurler / Cinder Hand ash puff (0.35 m quad, curve peak x2.6) now swells to about 1 m as written.
  The other unit emitters changed by under 20 %.

**Retune:** none was needed. At z12 and z30 every family looks right at its written size. That includes the subtle
BuildRing, which stays at its written size for consistency with the other kingdoms' keeps.

**Seen, not changed** (correct size, out of scope): the Dusk Keep damage `Rift` is a 0.9 m sized quad with an HDR
x3 albedo, and it still blooms into a white-lilac ball when the keep is under 25 % HP. It is a candidate for a
`MoteCap.cap`-style value cap in a later pass.

## Left for other owners (printed as notes by the test)

These emitters draw at the quad size today:

- `art/environment/build_env.gd:987` (`star_mat`)
- `art/environment/crown/build_crown.gd:653`
- `art/environment/crystal/build_crystal.gd:224` (`star_mat`)
- `art/environment/menu_diorama/menu_diorama.gd:543`
- `art/environment/crown_pedestal.tscn` (2 materials)
- `art/environment/crystal_node.tscn` (1 material)

`art/cinematics` had no hit.

The fix is the same one line, plus a look at the result. Once those owners take it, the test can drop `NOTE_ONLY`.

## Tests

PASS:

- `test_gf_billboard_scale` (Low and `-- --gfx=high`)
- `test_shader_lint`
- `test_ge_additive_fog`
- `test_gf_offscreen_emitters`
- `test_gf_r2_in`
- `test_gf_r2_fs`
- `test_gb_fire`, `test_gb_ice`, `test_gb_leftovers`, `test_gb_nature`, `test_gb_neutral`, `test_gb_shadow`, `test_gb_vfx`
- smoke (`victory=true`)
