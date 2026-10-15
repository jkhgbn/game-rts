# G-E fixes A (2026-10-15): bloom white-outs, fogged additive pads, Ice halo + Fire Hall bugs

Items 4, 5 and 7 of the top-8 list in `docs/art/ge_review.md` (review items 4, 5, 7 + 11). Shots: windowed 1600x900 at
High (`'--' --gfx=high`), tool `docs/art/lab/ge_fixes_a/tools/ge_shots.gd` (the G-E tool + `--orbit` free-camera
close-ups of the player's hall / keep, `--nolineup`, `--hallhide` debug) and `hall_probe.gd` (lists a hall's geometry).
Committed: `docs/art/lab/ge_fixes_a/ge_fixes_a_sheet.jpg` (before | after pairs) + `ge_fixes_a_key_{fire_base,ice_base,overview}.png`; every other
JPG stays local (the folder has a `.gdignore`). Sheet: `python -I docs/art/lab/ge_fixes_a/tools/ge_fixes_sheet.py`.

## 4. Building emissive / bloom white-outs

Cause: the building glow parts are unshaded colours at 3-4x (energy 2.4-4.0, orb / crown / core up to 3.6, plus
selection 1.4 and training pulses), far above `glow_hdr_threshold` 1.2; ACES squeezes every channel of such a colour
to white, so a saturated orange / violet / cyan orb became a white disc with a halo.

Fix: one shared include `art/shaders/glow_cap.gdshaderinc` = `glow_cap(c, glow_cap_max)`: a hue-keeping soft cap on
the brightest channel (knee at 0.6 x cap, asymptote at the cap, default 1.5) that also deepens the hue as it squeezes
(`pow(c / max, 1 + k x squeeze)`); pale colours (Ice cyan-white, lightened team colours) white out first, so their
cap drops to 0.72 x and k grows from 0.9 to 2.3 as the colour's saturation falls. Below the knee nothing changes; pulses, selection and upgrade flashes still read
(they saturate instead of whiting out). Applied as the last line of the BUILDING glow shaders only:
`art/shaders/rune_glow.gdshader` (every hall / house / tower / market / guild glow part), `rune_glow_vc.gdshader`
(the merged per-building glow), `art/buildings/fire_keep_glow.gdshader` (orb heart, crown crystal, braziers, lava,
windows), `ice_keep_glow.gdshader` (crown core, gate), `dusk_keep_glow.gdshader` (eye / orb, blade tips, rune ring),
`nature_keep_glow.gdshader` (lantern pods) and `nature_keep/nature_keep_seed.gdshader` (heart seeds). Same cost at
every tier (a few ALU ops), no new pass.
Plus the two additive stacks that summed to white on top of a capped glow:
- `art/buildings/fire_hall.gd` `_fire_ramp` (chimney flames, forge sparks, the Ice / Shadow hall braziers and the
  damage blaze, all ADD quads stacking 4-6 deep): hot end half-way to the mid colour, both dimmed (x 0.5 / x 0.6).
- `art/buildings/ice_hall.gd` ColdFlame (12 additive quads in a 0.22 m sphere by the gate, ~8 deep): own deep-blue
  ramp instead of the near-white danger ramp (the Ice Hall "door" white disc).
- `art/buildings/fire_tower.gd` orb halo billboard: flat centre (alpha 0.5 -> 0.4 ring) instead of a 1.0 hot core.

Not changed: `art/environment/world_env.tres` (glow threshold / intensity) and every spell / combat / unit VFX
shader: they never include the cap, so spells and hits still burn hot (battle shots in `after_fi/battle_*`).
Result: Fire keep orb reads as a swirling orange sphere, Shadow tower / hall orbs as violet eyes, the Ice crown core
as cyan, Nature lantern pods green; the hall chimney / forge mouth keep a warm glow without a white blob.

## 5. Square light pads at distance (fogged additive quads)

Cause: an additive material drawn WITH depth fog gets the fog colour mixed into its output over the whole quad,
transparent corners included, and blend_add adds that to the frame: a pale square at range.

Fix (every art/ case):
- `fog_disabled` added to the 8 shaders: `art/environment/crown/glow_pool.gdshader` (crystal-node pools + crown
  altar), `crown_beacon.gdshader`, `art/buildings/fire_keep_runes.gdshader`, `fire/ember_crucible/crucible_pool.gdshader`,
  `capture/essence_well/essence_well_fx.gdshader`, `capture/wayshrine/wayshrine_beam.gdshader`,
  `wayshrine_motes.gdshader`, `art/environment/critters/critter_firefly.gdshader`.
- `disable_fog` set next to every `.blend_mode = ` that can be ADD in code: 68 sites in 64 .gd files under art/
  (`= true` for a constant ADD, `= additive` / `= not blend_mix` for the ternaries, `= blend == BLEND_MODE_ADD` in
  the `_quad(blend)` / `_particle_quad(blend)` helpers), each tagged `# G-E 5`.
- `disable_fog = true` in 19 StandardMaterial3D sections with `blend_mode = 1` in 15 .tscn / .tres under art/
  (keep particle quads, crystal_node sparkles, crown pedestal, lost cache, ash scar, essence-well mist, unit / creature
  motes, loot sack).
- scripts/: no hit (no .gd builds an additive StandardMaterial3D there, no blend_add shader without fog_disabled),
  so no handoff was needed. Reported only (not failed): 32 hits under `art/cinematics/` (films: close
  cameras and their own environments; the forge_* stage sets belong to four-wizards-high).

Guards (recurring class):
- `tests/test_shader_lint.gd` rule C: a spatial shader whose render_mode has `blend_add` but no `fog_disabled` is a
  hit; `// lint: fog-ok` on the render_mode line exempts one (self-test covers a multi-line render_mode, a good one and
  an exempt one).
- `tests/test_ge_additive_fog.gd` (new, headless, ~1 s): every .gd under art/ and scripts/ (a function that sets
  `<mat>.blend_mode` to ADD or to a variable, in a file that uses BLEND_MODE_ADD, must touch `<mat>.disable_fog` /
  FLAG_DISABLE_FOG in the same function; `# lint: fog-ok` exempts; CanvasItemMaterial ignored) and every .tres / .tscn
  (StandardMaterial3D / ORMMaterial3D section with `blend_mode = 1` needs `disable_fog = true`). Fails on art/ hits;
  scripts/ hits and art/cinematics/ are printed as known (`-- --verbose` lists the cinematics ones). PENDING list for
  files another agent still holds (empty).

## 7. Model bugs

- Ice keep halo (`art/buildings/ice_keep.gd` `_reshape_halo`, `_update_halo`): the six HaloShards were squat
  hexagonal prisms in the unshaded glow material, seen face-on = floating white paper. At `_ready` they now take a
  thin tall faceted crystal (`IceShapes.crystal(0.12, 0.85, 0.55, 0.4)`) in the keep's lit crystal material (team
  tint, darkened, value under the crown core), tilted out 15 deg more, no shadow. The health state no longer sets the
  glow `energy` instance uniform on them (`_halo_crystal`). The baked .tscn is unchanged (legacy path keeps the old
  shards).
- Fire Hall (`art/buildings/fire_hall.gd`, every hall built on FireHallModel):
  - the "black quad with grass through it" by the door = the three path stones in front of the gate: flat slabs at
    ground level outside the plinth, so the building's height AO painted them black and the grass grew through.
    Found by hiding parts one by one (`--hallhide`): removed (the rng draws stay, the rest of the layout is identical).
  - the "stray black cube(s)" = `Rubble`, nine near-black 0.5 m cubes on the grass round EVERY healthy hall (collapse
    debris shown all the time). Hidden until the collapse shows the wreck (step 2 of play_destroyed).

## Tests (all PASS)

smoke_test (victory=true), perf_test (PERF OK, norm 6.38; two earlier runs read 6.75 / 7.80 while 6 other Godot
processes ran: noise, every change here is GPU-side or one-time at _ready), test_ws_perf, test_shader_lint (A 0 / B 0 / C 0), test_ge_additive_fog,
test_gb_fire, test_gb_ice, test_gb_nature, test_gb_shadow, test_gb_leftovers, test_fog_leak.
