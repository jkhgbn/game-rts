# Game Health: 77.6 / 100

2026-10-06 09:11:14, commit `31bc830f3641`. Made by `tools\health\run_health.ps1` from the labs' latest outputs (nothing re-run). Coverage 100 % of the weight (areas with no data are left out). Method: docs/design/health-and-playtests.md.

**Trend:** first run (no history yet).

## Top 3 problems to fix next

| # | Problem | Area | Costs (health pts) | Evidence | Owner | Re-check / fix |
|---|---|---|---|---|---|---|
| 1 | 31 of 47 units are Unit Lab outliers at equal cost | Balance | 6.6 | worst: rime_seer too weak (mean score 0 % <= 30 %, loses to 46 / 46); hollow_oathsworn too strong (mean score 100 % >= 70 %, beats 46 / 46); hexweaver too weak (mean score 6 % <= 30 %, loses to 43 / 46); ash_hurler too weak (mean score 6 % <= 30 %, loses to 43 / 46); thistle_darter too weak (mean score 7 % <= 30 %, loses to 43 / 46); rimehorn_rider too strong (mean score 92 % >= 70 %, beats 42 / 46) | gameplay-coder (data/units) | tools\unit_lab\run_unit_lab.ps1 -Matrix, then confirm in the Balance Lab |
| 2 | Replays diverge (Replay Lab FAIL) | Stability | 2.2 | 2026-09-27_selfcheck | lead | tools\replay_lab\run_replay.ps1 -Record |
| 3 | Map thornwater: gate G5 Bot fairness FAIL | Maps | 1.9 | 123 games (123 decided): easy 20 / 40 = 50 %; normal 15 / 40 = 38 %; hard 13 / 43 = 30 % / normal seat rate 38 %, hard seat rate 30 %, cell easy ice 80 %, cell easy nature 30 %, cell normal fire 10 %, | map tools (four-wizards-high) | tools\map_lab\run_map_gate.ps1 thornwater -Resume |

## Areas

| Area | Weight | Score | Status | vs last runs |
|---|---|---|---|---|
| Stability | 20 | 82.9 | Watch | - |
| Performance | 15 | 79.0 | Watch | - |
| Balance | 15 | 56.0 | Poor | - |
| Maps | 10 | 68.3 | Watch | - |
| Art | 10 | 92.9 | Good | - |
| UI/UX | 10 | 96.5 | Good | - |
| Data | 5 | 95.3 | Good | - |
| Content completeness | 15 | 68.4 | Watch | - |

## Components (the evidence)

| Area | Component | Score | Weight | Evidence | Source | Age (days) |
|---|---|---|---|---|---|---|
| Stability | Tests pass (latest CI / Error Lab run) | 100.0 | 3.0 | 37 / 37 pass in ci-2026-10-04_2052 (subset run: 37 of 309 test files) | `docs/ci/2026-10-04_2052/error_lab/scorecard.json` | 1.5 |
| Stability | Error Lab score (unique errors) | 100.0 | 2.0 | PASS 100 / 100, 0 FAIL / 0 WARN unique errors, 0 new | `docs/ci/2026-10-04_2052/error_lab/scorecard.json` | 1.5 |
| Stability | Flip-flop tests (last 6 Error Lab runs) | 46.0 | 1.0 | 9 tests flipped: test_10_c1, test_11_c2, test_12_a1, test_12_c1, test_7_a1, test_7_u1, test_9_c5, test_replay_lab, test_sound_plan | `docs/ci/*/error_lab` | - |
| Stability | Smoke test (mission 1 won) | 100.0 | 1.0 | SMOKE: GAME OVER at frame 3840: victory=true player=10 enemy=7 | `docs/ci/2026-10-04_2052/ci_result.txt` | 1.5 |
| Stability | Replay Lab (determinism) | 0.0 | 1.0 | 2026-09-27_selfcheck: FAIL, 1 replays (0 pass, 1 fail) | `docs/replay/lab/history.jsonl` | 9.1 |
| Stability | Build Lab (exported game) | 100.0 | 1.0 | 2026-09-26_2350: PASS, 0 fails | `docs/build/lab/history.jsonl` | 9.1 |
| Performance | Perf Lab scenarios (latest) | 68.5 | 2.0 | early cpu 41.8 (noisy), early gpu 82.3 (noisy), late200 cpu 66.2, late200 gpu 61.0 (noisy), menu cpu 96.6 (noisy), menu gpu 97.6 (noisy), mid100 cpu 65.9, mid100 gpu 64.5 (noisy), vfx_storm cpu 40.9 (noisy), vfx_storm gpu 68.2 (noisy) | `docs/perf/lab/latest` | 5.2 |
| Performance | CI perf tests (frame ms vs budget) | 100.0 | 1.0 | 100 units 6.70 / 8.0 ms, 200 units 11.97 / 16.0 ms | `docs/ci/2026-10-04_2052/ci_result.txt` | 1.5 |
| Balance | Balance Lab (bot matches) | 100.0 | 0.5 | 2026-09-26_validation WARN, 4 matches, best arm baseline | `docs/balance/lab/2026-09-26_validation/scorecard.json` | 9.1 |
| Balance | Unit Lab matrix: entries that are not outliers | 34.0 | 1.0 | 31 outliers of 47 entries (16 too strong, 15 too weak; matrix_both, variant baseline) | `docs/balance/unit_lab/matrix_both/scorecard.json` | 0.5 |
| Maps | Map gate verdicts | 52.5 | 2.0 | thornwater FAIL (G5 FAIL); quartermeet PARTIAL (G5 SKIP) | `docs/tools/map_gate` | 0.9 |
| Maps | Map balance model (ready maps) | 85.2 | 1.0 | crown_hollow 78 (uncertain), thornwater 88 (uncertain), quartermeet 89 (uncertain) | `tools/map_lab/balance/dataset` | 0.8 |
| Maps | Map Lab (Crown Hollow) | 97.7 | 0.5 | 2026-09-27_0002_1v1 WARN | `docs/maps/lab/2026-09-27_0002_1v1/scorecard.json` | 9.1 |
| Art | Art Lab mean quality (107 assets) | 92.9 | 2.0 | mean 92.9 over 107 scorecards | `docs/art/lab/*/scorecard.json` | 3.4 |
| Art | Art assets without a FAIL | 89.7 | 1.0 | 11 of 107 assets FAIL | `docs/art/lab/*/scorecard.json` | 3.4 |
| Art | Visual Diff Lab (golden shots) | 100.0 | 0.5 | PASS 100 (2026-09-27 07:38:59) | `docs/visual/lab/history.jsonl` | 9.1 |
| Art | Audio Lab mean score (15 sets) | 92.1 | 0.5 | mean 92.1 | `docs/audio/lab/*/scorecard.json` | 7.7 |
| UI/UX | UI Lab quality | 95.8 | 2.0 | FAIL 95.8 (FAIL 2, WARN 8 checks) | `docs/ui/lab/scorecard.json` | 9.1 |
| UI/UX | UI lab_u7 | 99.3 | 0.5 | WARN | `docs/ui/lab_u7/scorecard.json` | 8.8 |
| Data | Data Lab quality | 95.3 | 1.0 | caster-cost120 FAIL 95.3 (1 FAIL, 13 WARN findings) | `docs/data/lab/caster-cost120/scorecard.json` | 0.6 |
| Content completeness | Episode 1 missions built vs specified | 100.0 | 1.0 | 5 built / 5 episode-1 specs | `missions/` | - |
| Content completeness | Campaign missions built vs all specs | 15.2 | 0.5 | 5 built / 33 specs (episodes 1-8) | `docs/design/mission-*.md` | - |
| Content completeness | Kingdom units with a Unit Guide entry | 93.7 | 1.0 | 59 / 63 (missing: mother_hush, sapling, spirit_wolf, torren_vey) | `data/units` | - |
| Content completeness | Kingdom units with a unit icon | 47.6 | 1.0 | 30 / 63 (missing: ashveil_saboteur, barrow_knight, bleakbow, bramble_harrier, bramblesage, briar_roc, duskbolt_harrier, emberdart_harrier) | `data/units` | - |
| Content completeness | Kingdom units with a voice barks | 58.7 | 1.0 | 37 / 63 (missing: barrow_knight, bramble_harrier, bramblesage, briar_roc, duskbolt_harrier, emberdart_harrier, frostcrown_juggernaut, glade_outrider) | `data/units` | - |
| Content completeness | Localization coverage | no data | 1.0 | no data: no locale folder yet | `` | - |

## Next problems (after the top 3)

- 1.75 pts, Content completeness: 33 kingdom units have no unit icon (tech-artist (art/icons/units))
- 1.41 pts, Content completeness: Campaign: 28 of 33 specified missions not built yet (systems-coder)
- 1.38 pts, Content completeness: 26 kingdom units have no voice barks (audio (assets/audio/voice))
- 1.20 pts, Stability: 9 tests flip between pass and fail (last 6 Error Lab runs) (test owners)
- 0.81 pts, Maps: Map quartermeet: gate G5 Bot fairness SKIP (map tools (four-wizards-high))
- 0.59 pts, Performance: Perf vfx_storm (cpu) FAILs its budget: Commander think tick median = 1.077 ms over 27 ticks (step memory). The worst step is `memory` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group (perf (owner of the hot file))
- 0.58 pts, Performance: Perf early (cpu) FAILs its budget: Commander think tick median = 0.631 ms over 128 ticks (step scout). The worst step is `scout` in commander.gd `_think()`: cap its work per tick (a budget in usec, continue next tick), cache its group  (perf (owner of the hot file))
- 0.42 pts, Maps: Map crown_hollow internal balance 78 / 100 (uncertain) (map tools)
- 0.39 pts, Performance: Perf late200 (gpu) FAILs its budget: nodes were created under a VFX manager during the measure window (5 ({"GPUParticles3D":5})): pre-build them in the manager's _ready and restart them (art-units.md 8). (perf (owner of the hot file))
- 0.36 pts, Performance: Perf mid100 (gpu) FAILs its budget: nodes were created under a VFX manager during the measure window (3 ({"GPUParticles3D":3})): pre-build them in the manager's _ready and restart them (art-units.md 8). (perf (owner of the hot file))
- 0.34 pts, Performance: Perf mid100 (cpu) FAILs its budget: Commander think tick median = 1.259 ms over 33 ticks (step champions). The worst step is `champions` in scripts/ai/ai_champions.gd `tick()` (called from commander.gd `_rule_champions`): cap its work p (perf (owner of the hot file))
- 0.34 pts, Performance: Perf late200 (cpu) FAILs its budget: Commander think tick median = 2.108 ms over 33 ticks (step champions). The worst step is `champions` in scripts/ai/ai_champions.gd `tick()` (called from commander.gd `_rule_champions`): cap its work p (perf (owner of the hot file))

Weights: Stability 20, Performance 15, Balance 15, Maps 10, Art 10, UI/UX 10, Data 5, Content completeness 15.
