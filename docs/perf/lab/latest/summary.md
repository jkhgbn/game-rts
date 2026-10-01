# Perf Lab summary: after casters merge

Generated 2026-10-01 03:45:29. One scorecard per scenario and mode in this folder (`<scenario>_<mode>.md`). Budgets: `tools/perf_lab/perf_budgets.gd`; how to read: docs/plan/perf-lab.md.

| Scenario | Mode | Result | Score | Frame avg | p95 | p99 | max | Hitches | GPU ms | Units | Noise | Runs |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| [mid100](mid100_cpu.md) | cpu | FAIL | 66 | 7.08 | 10.78 | 12.48 | 15.1 | 0 | - | 71 | quiet | 3 (3 quiet) |
| [late200](late200_cpu.md) | cpu | FAIL | 66 | 11.49 | 17.66 | 20.17 | 29.7 | 0 | - | 133 | quiet | 3 (3 quiet) |

## Top 15 hot scripts (worst scenario each, avg ms per frame, band profiler)
| # | Script | System | Scenario | Nodes | Avg ms | Max ms |
|---|---|---|---|---|---|---|
| 1 | `scripts/units/unit.gd` | Units (gameplay) | late200/cpu | 224 | 1.343 | 16.51 |
| 2 | `scripts/ui/selection_panel.gd` | HUD / minimap / UI | late200/cpu | 1 | 0.988 | 2.34 |
| 3 | `[GPUParticles3D]` | Built-in nodes ([GPUParticles3D]) | late200/cpu | 2197 | 0.376 | 0.64 |
| 4 | `scripts/ui/command_card.gd` | HUD / minimap / UI | late200/cpu | 1 | 0.208 | 2.54 |
| 5 | `art/vfx/caster_shadow_vfx.gd` | VFX managers | late200/cpu | 1 | 0.171 | 0.52 |
| 6 | `scripts/ui/selection_manager.gd` | HUD / minimap / UI | late200/cpu | 1 | 0.144 | 4.75 |
| 7 | `art/units/fire/blaze_rider/blaze_rider_rider.gd` | Unit / building models (art scripts) | late200/cpu | 8 | 0.114 | 0.46 |
| 8 | `art/units/shadow/shadow_model.gd` | Unit / building models (art scripts) | late200/cpu | 31 | 0.111 | 0.44 |
| 9 | `scripts/units/caster_ability.gd` | Units (gameplay) | late200/cpu | 15 | 0.104 | 1.73 |
| 10 | `art/units/fire/fire_model.gd` | Unit / building models (art scripts) | late200/cpu | 27 | 0.099 | 0.40 |
| 11 | `scripts/units/t3_unit_ability.gd` | Units (gameplay) | late200/cpu | 15 | 0.097 | 0.64 |
| 12 | `art/units/mounts/ember_boar/ember_boar.gd` | Unit / building models (art scripts) | late200/cpu | 8 | 0.082 | 0.34 |
| 13 | `scripts/world/fog_of_war.gd` | Fog of war | late200/cpu | 1 | 0.081 | 1.08 |
| 14 | `art/units/fire/emberdart_harrier/parts/emberdart_harrier_rider.gd` | Unit / building models (art scripts) | late200/cpu | 8 | 0.070 | 0.39 |
| 15 | `scripts/ui/mapfill_bar.gd` | HUD / minimap / UI | late200/cpu | 1 | 0.070 | 0.79 |

## Improve next (top item of each scorecard)
- **mid100 / cpu: Split the Commander's worst think step**: Commander think tick median = 1.259 ms over 33 ticks (step champions). The worst step is `champions` in scripts/ai/ai_champions.gd `tick()` (called from commander.gd `_rule_champions`): cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked.
- **late200 / cpu: Split the Commander's worst think step**: Commander think tick median = 2.108 ms over 33 ticks (step champions). The worst step is `champions` in scripts/ai/ai_champions.gd `tick()` (called from commander.gd `_rule_champions`): cap its work per tick (a budget in usec, continue next tick), cache its group scans (AIWorldCache, ai-2v2.md:336), and move one-time setup / resource loads out of the first ticks. Commander counters: rule_usec_max / rule_usec_max_at say when it spiked.
