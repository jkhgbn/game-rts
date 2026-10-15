# G-D menu diorama: the four kingdoms at dusk

Graphics week, wave G-D (docs/plan/graphics-week.md). The main menu's 3D backdrop is
`art/environment/menu_diorama/menu_diorama.tscn` (`MenuDiorama`, task A2.10). `scripts/ui/menus/main_menu.gd`
puts it in its own SubViewport and only calls `focus_kingdom()`. That call and the A2.10 API (`set_paused`,
`is_paused`, `focus_kingdom`, `get_focus`, `get_camera`) and the node names (`Wizards/*`, `Altar`, `Crown`,
`Tavern/TavernModel`, `Champions`, `Sun`, `WorldEnvironment`) did not change.

## What changed

- **The four kingdoms' keeps on the horizon** (every tier). The real game models are placed on low procedural hills
  beyond the plaza, each at tier 3 (Citadel) in its kingdom colour, gate facing the crown: Ice (`ice_keep.tscn`,
  far left), Shadow (`dusk_keep.tscn`, left of the title), Nature (`nature_keep.tscn`, right of the title) and Fire
  (`fire_keep.tscn`, right edge). The table is `LANDMARKS` (pos / scale / hill / radius). The far treeline keeps out
  of each hill's clearing; it skips trees only after every rng draw, so the rest of the treeline stays where it was.
  The keeps' own looping emitters (braziers, motes, mist) run from High up. Damage smoke, fire and build rings stay off.
- **Graphics tiers**. `set_quality(q)` reads `GameSettings.effective_graphics_quality()` in `_ready`. The diorama
  joins `"lighting_rigs"`, so a change in Settings reaches the open menu at once. The diorama works on its own copy
  of `menu_diorama_env.tres`, never on the shared resource.

| Tier | Adds |
|---|---|
| Low | Nothing new except the four keeps on their hills (their own emitters and lights off). Same environment, same particle budget as A2.10, SubViewport AA / anisotropy as main_menu sets them (2x MSAA). `PropsLook.apply(q)` runs at every tier (Low = the old prop look). |
| Medium | SSAO; the SubViewport takes `GameSettings.apply_viewport_quality` (4x MSAA, 8x aniso); a dusk flock of 7 birds; the pond and its reeds; a glow pool on each keep's hill; light kingdom weather (35 %). |
| High | + SSIL, PCSS soft sun shadows (soft-shadow filter 4, given back on exit), light volumetric fog (sun haze, halos round the crown beacon and the keeps), a coloured light over each keep, 80 % weather, each wizard's own weather in the plaza (Vessa embers, Torvald snow, Ysolde leaves, Malrik wisps), the keeps' own emitters and lights. |
| Ultra | + denser volumetric light, filter 5, a second flock, full weather. |

- **Kingdom weather** round each keep: Ice snowfall, Fire embers plus a slow forge-smoke plume, Nature drifting
  leaves and pollen, Shadow rising wisps.
- **Birds**: `menu_birds.gdshader` draws one MultiMesh per flock. Each bird flies its own circle in the vertex
  shader, with wing beats and glides. The time comes from the diorama (`anim_time`), so the birds stop when the
  menu is paused.
- **Pond**: `menu_pond.gdshader` is a painted mirror with no SSR, no probe and no screen read. The near water is dark
  and deep, the far water mirrors the gold horizon, and a ragged band of forest is reflected along the far shore.
  It also has shimmer lines, a wet shore and a streak for the crown beacon. It sits in the bottom centre, below the
  menu panel.

## Measures (RTX 3070 laptop, 1920x1080, `menu_diorama_shots.gd`, vsync off, other Godot runs active = noisy)

| | GPU of the diorama viewport | fps (whole window) |
|---|---|---|
| Before (any tier, no tier code) | 1.8-3.1 ms | 194-360 |
| After Low | 1.75-2.0 ms | 284-321 |
| After High | 5.1-5.2 ms | 142-144 |
| After Ultra | 5.4-6.2 ms | 139-140 (one noisy run 69 fps on the UI probe) |

High and Ultra stay far above the 60 fps target, and Low costs the same as before.

## Shots

`docs/art/lab/gd_menu/` (`.gdignore`): `contact_sheet.jpg` (before / Low / High / Ultra main menu, High skirmish
setup, Ultra Ice focus) plus 4 PNGs. Re-shoot windowed with
`tools\godot_run.ps1 --path . -s res://art/environment/menu_diorama/menu_diorama_shots.gd --fixed-fps 60 --quit-after 9000 '--' tag=x size=1920x1080 out=res://docs/art/lab/gd_menu 'shots=wide_ui,focus_ice' '--gfx=high'`.
Quote comma lists in PowerShell, otherwise `shots=a,b` is split into several arguments. The tier now goes in the
file name. The shots script hides the menu's own diorama, so the GPU probe counts one diorama, not two.

## Tests

`tests/test_gd_menu.gd` (keeps and hills, clearings, Low = the authored environment and AA, Ultra on the copy only,
the dressing per tier, pause, back to Low), `tests/test_a2_10.gd`, `test_shader_lint`, smoke and the menu / UI tests
(5_u1, 7_u1, 8_u1, f4_ui, mt9_map_picker, mu13, g1_settings, 12_v2, 16a) pass.

## Not done / notes

- There is no 3D loading screen or mission-briefing scene under `art/`: those screens are 2D UI (ui-coder), so there
  was nothing to restyle here.
- The volumetric fog is kept thin on purpose: denser settings washed the midground (shots a1-a3 during the work).
