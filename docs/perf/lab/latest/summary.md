# Perf Lab summary: Validation run 2026-09-26 (machine busy with other agents)

Generated 2026-09-26 22:25:45. One scorecard per scenario and mode in this folder (`<scenario>_<mode>.md`). Budgets: `tools/perf_lab/perf_budgets.gd`; how to read: docs/plan/perf-lab.md.

| Scenario | Mode | Result | Score | Frame avg | p95 | p99 | max | Hitches | GPU ms | Units | Noise | Runs |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [early](early_cpu.md) | cpu | FAIL | 42 | 22.82 | 150.78 | 207.39 | 381.0 | 328 | - | 26 | **noisy** | 2 (0 quiet) |
| [early](early_gpu.md) | gpu 1600x900 | WARN | 82 | 10.79 | 17.12 | 18.09 | 21.4 | 0 | 5.71 | 26 | **noisy** | 1 (0 quiet) |
| [mid100](mid100_cpu.md) | cpu | FAIL | 42 | 36.23 | 188.73 | 260.50 | 405.7 | 301 | - | 62 | **noisy** | 2 (0 quiet) |
| [mid100](mid100_gpu.md) | gpu 1600x900 | FAIL | 65 | 19.06 | 27.53 | 41.35 | 55.6 | 62 | 6.21 | 62 | **noisy** | 1 (0 quiet) |
| [late200](late200_cpu.md) | cpu | FAIL | 38 | 42.68 | 129.50 | 162.81 | 275.2 | 547 | - | 135 | **noisy** | 2 (0 quiet) |
| [late200](late200_gpu.md) | gpu 1600x900 | FAIL | 61 | 28.93 | 42.89 | 58.86 | 211.6 | 311 | 8.21 | 135 | **noisy** | 1 (0 quiet) |
| [vfx_storm](vfx_storm_cpu.md) | cpu | FAIL | 41 | 40.79 | 182.00 | 219.44 | 303.1 | 307 | - | 38 | **noisy** | 2 (0 quiet) |
| [vfx_storm](vfx_storm_gpu.md) | gpu 1600x900 | FAIL | 68 | 19.21 | 31.19 | 37.04 | 47.6 | 36 | 7.04 | 38 | **noisy** | 1 (0 quiet) |
| [menu](menu_cpu.md) | cpu | WARN | 97 | 0.25 | 0.34 | 1.03 | 27.8 | 0 | - | 0 | **noisy** | 2 (0 quiet) |
| [menu](menu_gpu.md) | gpu 1600x900 | WARN | 98 | 3.60 | 5.04 | 5.35 | 10.2 | 0 | 2.50 | 0 | **noisy** | 1 (0 quiet) |

## Top 15 hot scripts (worst scenario each, avg ms per frame, band profiler)
| # | Script | System | Scenario | Nodes | Avg ms | Max ms |
|---|---|---|---|---|---|---|
| 1 | `scripts/units/unit.gd` | Units (gameplay) | late200/cpu | 224 | 4.390 | 108.95 |
| 2 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | late200/cpu | 1 | 2.241 | 147.28 |
| 3 | `scripts/ui/command_card.gd` | HUD / minimap / UI | early/cpu | 1 | 1.926 | 275.24 |
| 4 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | vfx_storm/cpu | 1733 | 1.849 | 126.71 |
| 5 | `art/units/fire/fire_model.gd` | Unit / building models (art scripts) | late200/cpu | 78 | 1.180 | 93.70 |
| 6 | `art/units/fire/blaze_rider/blaze_rider_rider.gd` | Unit / building models (art scripts) | late200/cpu | 25 | 1.137 | 88.60 |
| 7 | `art/vfx/mapfill_wyrm_vfx.gd` | VFX managers | vfx_storm/cpu | 1 | 0.796 | 128.72 |
| 8 | `art/vfx/titan_ground_vfx.gd` | VFX managers | vfx_storm/cpu | 1 | 0.645 | 134.22 |
| 9 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | late200/cpu | 1 | 0.618 | 113.77 |
| 10 | `art/units/mounts/ember_boar/ember_boar.gd` | Unit / building models (art scripts) | late200/cpu | 25 | 0.579 | 115.62 |
| 11 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | vfx_storm/cpu | 1 | 0.574 | 150.81 |
| 12 | `scripts/economy/worker.gd` | Units (gameplay) | early/cpu | 10 | 0.487 | 164.05 |
| 13 | `art/vfx/mapfill_beast_vfx.gd` | VFX managers | vfx_storm/cpu | 1 | 0.461 | 128.90 |
| 14 | `art/units/shadow/shadow_model.gd` | Unit / building models (art scripts) | mid100/cpu | 53 | 0.436 | 183.84 |
| 15 | `art/vfx/spell_vfx.gd` | VFX managers | vfx_storm/cpu | 1 | 0.435 | 111.69 |

## Improve next (top item of each scorecard)
- **early / cpu: Split the Commander's worst think step**: Commander think tick median = 0.631 ms over 128 ticks (step scout). The worst step is `scout` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked.
- **early / gpu: Fewer draw calls**: Render objects (avg per frame) = 2767 (max 3055): merge static decor into MultiMeshes per chunk (map-fill.md:400), set visibility_range_end on small props (65 / 90 m), and merge unit parts (art-units.md 8: <= 14 instances per unit).
- **mid100 / cpu: Split the Commander's worst think step**: Commander think tick median = 2.318 ms over 33 ticks (step attack). The worst step is `attack` in commander.gd `_rule_attack()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked.
- **mid100 / gpu: Pool the VFX**: nodes were created under a VFX manager during the measure window (3 ({"GPUParticles3D":3})): pre-build them in the manager's _ready and restart them (art-units.md 8).
- **late200 / cpu: Split the Commander's worst think step**: Commander think tick median = 3.458 ms over 33 ticks (step memory). The worst step is `memory` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked.
- **late200 / gpu: Pool the VFX**: nodes were created under a VFX manager during the measure window (5 ({"GPUParticles3D":5})): pre-build them in the manager's _ready and restart them (art-units.md 8).
- **vfx_storm / cpu: Split the Commander's worst think step**: Commander think tick median = 1.077 ms over 27 ticks (step memory). The worst step is `memory` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked.
- **vfx_storm / gpu: Pool the VFX**: nodes were created under a VFX manager during the measure window (27 ({"GPUParticles3D":9,"MeshInstance3D":16,"Node3D":2})): pre-build them in the manager's _ready and restart them (art-units.md 8).
- **menu / cpu: Map art**: 0.041 ms / frame over 1 nodes. shader parameter write (menu_diorama.gd:249 in `_animate_glows()`). Fix: write only when the value changes (compare first) or move the animation into the shader (TIME). `art/environment/menu_diorama/menu_diorama.gd`: move per-frame animation into shaders (TIME) and use visibility ranges.
- **menu / gpu: Cache group lists**: Many per-frame functions call `get_tree().get_nodes_in_group(&"units")`: a shared per-frame cache (one array per group, rebuilt once per physics frame) removes the repeated allocations (ai-2v2.md:336 AIWorldCache pattern).
