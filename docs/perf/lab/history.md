# Perf Lab history

One row per scenario and mode per lab run (`tools/perf_lab/run_perf_lab.ps1`, docs/plan/perf-lab.md). Frame numbers in ms (median of the repeats). **noisy** rows were measured while other Godot processes or programs loaded the CPU: never compare them with quiet rows.

| When | Commit | Scenario | Mode | Noise | avg | p95 | p99 | max | Hitches | GPU ms | Units | Score | Result | Top 3 scripts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-09-26 21:56:45 | main@49ff2b29cb+wip | early | cpu | **noisy** | 22.82 | 150.78 | 207.39 | 381.0 | 328 | - | 26 | 42 | FAIL | command_card 1.93, selection_panel 0.85, worker 0.49 |
| 2026-09-26 22:01:38 | main@49ff2b29cb+wip | early | gpu 1600x900 | **noisy** | 10.79 | 17.12 | 18.09 | 21.4 | 0 | 5.71 | 26 | 82 | WARN |  |
| 2026-09-26 22:05:00 | main@49ff2b29cb+wip | mid100 | cpu | **noisy** | 36.23 | 188.73 | 260.50 | 405.7 | 301 | - | 62 | 42 | FAIL | unit 2.18, selection_panel 1.86, [GPUParticles3D] 1.53 |
| 2026-09-26 22:07:09 | main@49ff2b29cb+wip | mid100 | gpu 1600x900 | **noisy** | 19.06 | 27.53 | 41.35 | 55.6 | 62 | 6.21 | 62 | 65 | FAIL |  |
| 2026-09-26 22:10:43 | main@49ff2b29cb+wip | late200 | cpu | **noisy** | 42.68 | 129.50 | 162.81 | 275.2 | 547 | - | 135 | 38 | FAIL | unit 4.39, selection_panel 2.24, [GPUParticles3D] 1.19 |
| 2026-09-26 22:13:13 | main@49ff2b29cb+wip | late200 | gpu 1600x900 | **noisy** | 28.93 | 42.89 | 58.86 | 211.6 | 311 | 8.21 | 135 | 61 | FAIL |  |
| 2026-09-26 22:16:46 | main@49ff2b29cb+wip | vfx_storm | cpu | **noisy** | 40.79 | 182.00 | 219.44 | 303.1 | 307 | - | 38 | 41 | FAIL | [GPUParticles3D] 1.85, unit 1.54, selection_panel 1.53 |
| 2026-09-26 22:18:50 | main@49ff2b29cb+wip | vfx_storm | gpu 1600x900 | **noisy** | 19.21 | 31.19 | 37.04 | 47.6 | 36 | 7.04 | 38 | 68 | FAIL |  |
| 2026-09-26 22:20:33 | main@49ff2b29cb+wip | menu | cpu | **noisy** | 0.25 | 0.34 | 1.03 | 27.8 | 0 | - | 0 | 97 | WARN | menu_diorama 0.04, torvald 0.03, ysolde 0.02 |
| 2026-09-26 22:21:07 | main@49ff2b29cb+wip | menu | gpu 1600x900 | **noisy** | 3.60 | 5.04 | 5.35 | 10.2 | 0 | 2.50 | 0 | 98 | WARN |  |
