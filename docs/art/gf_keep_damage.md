# G-F keep damage pass: no white blobs under 25 % HP (2026-10-15)

## The problem

After the billboard pass (`gf_billboard.md`) the Dusk Keep's damage Rift had the right size (a 0.9 m quad), but under
25 % HP it still bloomed into a white-lilac ball. The cause was the material, not the size:

- the Rift drew 24 quads per emitter on the keep's shared `ParticleAdd` material (additive, `albedo_color` x3 HDR),
- its ramp started at (0.45, 0.25, 0.55), so a single particle was already (1.35, 0.75, 1.65), past every glow threshold,
- additive quads sum: the plume's core piled up to white, and the bloom spread it.

## The cap (`tests/test_gf_keep_damage.gd`)

The test treats as **damage effects** every particle emitter that emits on a keep at 20 % HP and not on the same keep at full
HP (tier 3, built). It runs on all four keeps, each with 7 team colours (red, blue, green, yellow, violet, near-white,
near-black). For each emitter it computes the brightest colour one particle can draw: albedo x albedo texture x process
colour x colour ramp, plus emission x energy.

- **Alpha-blended (MIX):** max channel <= **0.72** (`MoteCap.VALUE_CAP`). A blended stack never sums past its own colour.
- **Additive (ADD):** (rgb x alpha) max channel x **6** (the particles that overlap at a plume's core) <= **1.0**, which is
  under every world environment's glow threshold (1.1-1.3). A *speck* emitter (drawn size <= 0.25 m, for example the
  ShadowDress soul embers) counts as a stack of 1.
- No HDR albedo (> 1.0) on any damage-effect material.

It passes at Low (224 emitter x team checks) and at High (`-- --gfx=high`, 133 checks; this adds the ShadowDress embers).

## The fixes

| Keep | Effect < 25 % | Before | After |
|---|---|---|---|
| Dusk (Shadow) | Rift1 / Rift2 | ADD x3 HDR, peak 1.65, stack 9.9 | Its own `RiftMix` material, alpha-blended, on a rift dot: a dark violet core (0.08-0.15) with a soft lilac rim (0.66, 0.46, 0.72); the ramp is only a fade; on a tall 0.55 x 1 m quad (a slit, not a ball). Peak 0.72 |
| Fire | Blaze1 / Blaze2 | Shared the brazier ramp (born pale yellow 1 / 0.92 / 0.55 at alpha 1), ADD, stack 6.0 | Its own ramp, same fire hues (1 / 0.55 / 0.12 -> 1 / 0.36 / 0.05 -> deep red) at alpha 0.16. Stack 0.96: the core stays orange. The brazier and the collapse burst are not damage effects and are unchanged |
| Ice | FrostFlare1 / 2 | Already alpha-blended (G-F round 2), peak 0.42 | unchanged |
| Nature | Wither1 / 2 (falling leaves) | MIX, peak 0.66 | unchanged |
| all | damage Smoke1 / 2 | MIX, 0.16-0.42 | unchanged |
| Dusk (High+) | ShadowDress SoulEmbers (< 50 %) | ADD specks 0.07-0.13 m, peak 0.79-0.83 | unchanged (specks, under 1.0; `shadow_dress.gd` is shared) |

The Rift's colours are fixed Shadow violet, so they look the same for every team colour. Only the keep's lights and
outline follow the team (graded by `LIGHT_SAT`).

## Cost

- Particle counts, emitters and draw passes are unchanged.
- The Rift swaps one additive material for one alpha-blended material, so the Dusk Keep has one more material resource
  but still the same draws.
- The fire blaze adds one gradient texture.
- Low costs the same as before.

## Files

- `art/buildings/dusk_keep.tscn`: new `Gradient_riftx` / `GradientTexture2D_riftx` / `StandardMaterial3D_riftx`; the Rift
  quads (0.55 x 1) and their two ramps. `art/buildings/dusk_keep_build.gd` makes the same change.
- `art/buildings/fire_keep.gd`: `_build_state_nodes` gives the blaze its own capped ramp (built at runtime, so there is no
  scene change).
- `tests/test_gf_keep_damage.gd`: the cap test, plus a windowed shot mode.

## Shots (`docs/art/lab/gf_keep_damage/`, windowed, `--gfx=high`, `art/environment/world_env.tres`)

- `contact_sheet.jpg`: before / after rows for the four keeps, the Dusk Keep close-up, the Dusk Keep with white and blue
  teams, and two near (13 m) after views.
- `before_q2_row.png` / `after_q2_row.png`: the four keeps at 20 % HP.
- `before_q2_dusk.png` / `after_q2_dusk.png`: the white-lilac ball, then the dark tear.

Re-take the shots with:

```
tools\godot_run.ps1 --path . -s tests/test_gf_keep_damage.gd --resolution 1600x900 --quit-after 3000 '--' --gfx=high shots=1 tag=after [near=13]
```
