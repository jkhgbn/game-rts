# G-D - map props (2026-10-15)

Goal (JS: "make the graphics as beautiful as possible"): the props on the map look better at zoom 30-40 and zoom 10.
Order: what covers the most screen in a match (trees, rocks, crystals, crown), then camps / lairs / landmarks.
The capture points (watchtower / well / shrine) were redone by G-B neutral buildings. This task did not touch them.

## The lever: one shared material
Every tree, rock, ruin pillar, biome set (heath, meadow, old wood...), camp, lair and landmark mesh draws with
`art/environment/nature_props/nature_mat.tres` (`nature_painted.gdshader`). Upgrading that shader improves all of
them at once, with no new mesh, draw call or node, and the MultiMesh instancing stays as it was. Crystal nodes share
`crystal_cluster_mat.tres`. The crown and its altar trims share `crown_gold_mat.tres`.

## Tier plumbing
- `PropsLook` (`art/environment/nature_props/props_look.gd`, static) writes `gd_detail` = 0 Low .. 3 Ultra into those
  3 shared materials, through the resource cache. It keeps no reference of its own, so `AutumnSwap.release()` and the
  cache stay in charge. `apply(q)` returns the materials it wrote.
- `LightingRig` (every level, Wave Strike and cinematic stage sets included) calls `PropsLook.apply` in `_ready` and in
  `set_quality`, and holds the returned materials for its lifetime, so a Settings change reaches every prop.
- `ensure()` reads `GameSettings.effective_graphics_quality()`, so every headless or `-s` run gets Low. It rewrites
  the tier when the cached nature material does not carry it. `CrystalClusterArt._ready` and `CrownPedestalArt._ready`
  call it, because they can load the materials after the rig. Both also join `"lighting_rigs"`.
- `CrownPedestalArt.set_detail_tier(q)` adds or removes the altar pieces in both directions (`set_quality` calls it).
- Every new shader path sits behind `gd_detail > 0.5` / `> 1.5` (uniform branches). Low is the old look and the old
  cost on the same code path. `gd_detail` defaults to 0 (shader lint rule A), and derivatives are taken only at the
  top of `fragment()` (rule B).
- The autumn variant `autumn/nature_autumn.gdshader` was re-copied from nature_painted with its AUTUMN 20.V0 block
  kept. `autumn_swap` swaps the shader on the same cached material, so `gd_detail` carries over. test_20_v0 passes.

## What changed
| Prop | File | Medium | High / Ultra |
|---|---|---|---|
| Tree crowns (all species, border stand-ins) | `nature_props/nature_painted.gdshader` | Cooler, darker crown undersides and bases. Warm yellow-green light on the leaf clusters that face the sky, in soft broad patches. Warm sunlit leaves in `light()`. Sun shines through the crown edges on the shadow side (translucency). Stronger leaf rim. | A faint finer leaf-dab value layer (the noise mip fades it out with distance) |
| Bark | same | - | Dark vertical bark-plate cracks |
| Rocks, pillars, camp / lair / landmark stone | same | Softer light ramp on stone, so facets no longer flip between lit and unlit ("crumpled paper"). Wavy strata lines on the sides, anti-aliased with `fwidth`. Warm sun-bleached tops. | Small pale lichen rosettes on grey stone only. Red camp rocks and clay keep their own paint. |
| Crystal nodes | `crystal/crystal_cluster.gdshader` | Refraction-like shading: a deep saturated core on faces that look at the camera, a bright cut edge at grazing angles. Depletion now reads: the crystals pale toward a dull grey-blue as the node empties (they still shrink and dim as before). | Inner depth: two layers of glowing veins seen through the crystal along the view ray (parallax). They fade out between 16 and 34 m so they never alias. |
| Crown and altar gold | `crown/crown_gold.gdshader` | Painted-metal reflection band (warm sky above a sharp horizon, dark ground below), so the gold reads polished | + small hard glints hopping across the faces |
| Crown altar stone | `crown/crown_stone.gdshader` + `crown_stone_mat.tres` (new), `crown_pedestal_art.gd` | - | Override on the `Stone` node's env_painted surface. Dressed stone courses (joint lines by height and around the altar), lighter warm tops, cool sides. The crown lights its own altar: faces turned to it take the glow-pool colour (red while sealed, gold when claimable) and the joints glow faintly. |
| Crown beacon | `crown_pedestal_art.gd` (`set_detail_tier`) | - | `BeaconCore`: a narrow, hotter inner column in the claimable beacon. Same beacon mesh and material, instance uniforms only. |
| Crown light | `crown_pedestal_art.gd` | - | Ultra only: `CrownLight`, one OmniLight3D (range 9 m, no shadow) that follows the glow pool's colour and intensity. It is the only prop light. |

Contracts kept: no scene, node name, collider, nav layer, mesh or MultiMesh changed. The crystal `set_fill_ratio`
hook and the pedestal node contract (`Runes`, `SealRings`, `Beacon`, ...) are unchanged. EmberCrown's rune tint is
untouched. The glowing parts (veins, joints, the crown light) belong to props that already show through fog the
way they did before (crystal nodes, the neutral crown in the open centre). No team-owned prop gained an emitter, so
there is no new fog leak.

## Shots (`docs/art/lab/gd_props/`, `.gdignore`)
Tool: `art/environment/nature_props/gd_props_shots.gd`. It is windowed and takes
`'--' --map=crown|thornwater --gfx=high|ultra --tag=before|after [--fps] [--only=a,b] [--props-tier=N]`.
The HUD is hidden, the lighting rig's vignette and haze stay on, and fog is off. Views: `crown30` / `crown10`,
`crystal30` / `crystal10` (the nearest node; a second node is mined to 40 %), `forest30` / `forest10` (the densest
tree group 12-40 m from the player keep), `camp10`, `point10`, `full55`.
`before_*` were taken before any G-D change. `after_*` are the final state. Both are on Crown Hollow and Thornwater
at High. Crown, crystal and forest views at Ultra are tagged `after_crown_ultra_*`.
- Committed: `gd_props_contact.jpg` (before | after: crown 10, Thornwater crown 30, crystal 10, forest 10,
  forest 30, Thornwater camp 10) and 4 key PNGs: `after_crown_high_crown10.png`, `after_crown_high_crystal10.png`,
  `after_crown_high_forest30.png`, `after_thornwater_high_camp10.png`. The other PNGs stay local
  (`docs/art/lab/gd_props/**/*.png` in `.git/info/exclude`, lead).

## FPS (1920x1080, vsync off, RTX 3070 Laptop, Crown Hollow, 900 frames per view; avg / 1 % low fps, GPU ms)
This is an A/B in one build. `--props-tier=0` puts the shared materials back on the pre-G-D path. The pedestal pieces
stay, because they are one node. Other agents' Godot runs shared the machine.

| Tier | View | Props Low (before) | Props at tier (after) |
|---|---|---|---|
| High | full map, zoom 55 | 118.9 / 106.3, 7.79 ms | 107.8 / 93.6, 8.07 ms |
| High | forest, zoom 30 | 119.5 / 112.9, 7.88 ms | 118.7 / 113.1, 7.60 ms |
| High | crown, zoom 30 | 128.0 / 121.0, 7.02 ms | 127.2 / 121.5, 7.31 ms |
| Ultra | full map, zoom 55 | 92.2 / 81.8, 10.47 ms | 87.1 / 74.7, 10.32 ms |
| Ultra | forest, zoom 30 | 88.3 / 81.7, 10.48 ms | 89.8 / 85.9, 10.45 ms |
| Ultra | crown, zoom 30 | 98.0 / 94.5, 9.44 ms | 97.0 / 93.3, 9.49 ms |

GPU time is unchanged within noise (±0.3 ms). Everything added is fragment ALU on shared materials, plus 3 texture
reads at High+ on foliage and stone, and no new pass. Draw calls and primitives are the same. The first run (before
the A/B) measured 27 fps at full55, because 4 other Godot runs were going at that moment. That number is noise.

## Tests and labs
- `tests/test_gd_props.gd`: PASS. It checks the pedestal at High (BeaconCore and stone override, no light), at Ultra (+ a CrownLight with no shadow) and back at Low (all removed), that `PropsLook.apply` returns the 3 materials, that the shader `gd_detail` defaults are 0, that a headless run applies
  tier 0, that `lighting_rigs.set_quality(3)` reaches the 3 materials, the crystal fill hook, and that the pedestal
  at Low adds nothing (no BeaconCore, CrownLight, stone override or light) and keeps its node contract.
- Pass: smoke (`victory=true`), test_ws_perf, test_shader_lint, test_a2_3, test_a2_8, test_12_v3 / v5 / v7-v14 / v24 /
  v32, test_12b_v2-v5, test_20_v0 (after the autumn re-copy), test_10_v10, test_map_p3, test_g1_settings.
- perf_test reported norm 6.86 and then 7.01 against a limit of 6.72, with 4 other Godot processes running. It is
  headless, so props are at Low there and no shader is compiled. The only headless-side change is one static call per
  crystal node at `_ready`. Re-run it on a quiet PC.
- Art Lab `crown_pedestal` (landmark): PASS 91 (it was 87 on lab v1.0, 2026-09-26). The lab renders at Low, so it shows
  the contract and health side, not the new look.

## Not done / next
- Tree silhouettes are still the faceted lobes and tiers from A2.8. A mesh pass (more scalloped leaf clusters,
  fuller crowns) in `build_nature.gd` would give the biggest further gain. It needs a full re-bake of every tree
  mesh and a vertex-cost check (the props are drawn in 6 passes).
- The heath lichen stones bake their gold lichen per face in the mesh, so they still read faceted at zoom 10.
- The crystal rock mound is still plain dark rock.
