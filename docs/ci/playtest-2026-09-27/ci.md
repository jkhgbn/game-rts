# CI: playtest-2026-09-27

2026-09-27 14:35 - ci v2.0 - project `C:\Users\elzzo\Documents\four-wizards-rts-play`

## Result: **FAIL**

| Step | Result | Detail | Fix |
|---|---|---|---|
| Import | PASS | no script / parse errors (708.1 s) |  |
| Smoke | PASS | 3 / 3 victory=true |  |
| Perf 100 units | WARN | PERF units=100 ms_per_frame=11.41 budget=8.0 arrived=79 stuck=0 - OVER BUDGET while 4 Godot processes ran on the PC (noise, not a verdict) | Re-run on a quiet PC (Perf Lab: tools\perf_lab\run_perf_lab.ps1 -WaitQuietS 600). |
| Perf 200 units | WARN | PERF units=200 ms_per_frame=26.37 budget=16.0 arrived=118 stuck=0 - OVER BUDGET while 4 Godot processes ran on the PC (noise, not a verdict) | Re-run on a quiet PC (Perf Lab: tools\perf_lab\run_perf_lab.ps1 -WaitQuietS 600). |
| Tests (Error Lab) | **FAIL** | 238 / 248 tests pass; Error Lab FAIL 0 / 100 (0 FAIL, 1 WARN unique errors, 1 NEW) | Open error_lab/scorecard.md: 'By owner' + one fix-agent brief per owner. |

## Tests by owner (from the Error Lab)
| Owner | FAIL errors | WARN errors | Failed tests |
|---|---|---|---|
| ai-coder | 0 | 0 | test_12_a1, test_20_a3 |
| lab group A (visual) | 0 | 0 | test_art_lab |
| lab group B (simulation) | 0 | 0 | test_replay_lab |
| task agent of test_10_c6 | 0 | 0 | test_10_c6 |
| task agent of test_10_c7 | 0 | 0 | test_10_c7 |
| task agent of test_9_c5 | 0 | 0 | test_9_c5 |
| task agent of test_9_c9 | 0 | 0 | test_9_c9 |
| task agent of test_art_lab_calibration | 0 | 0 | test_art_lab_calibration |
| tech-artist | 0 | 0 | test_9_v2 |
| lab group A (visual) (engine error, no script frame) | 0 | 1 |  |

Full report, log tails and fix-agent briefs: `error_lab/scorecard.md`.

## Result lines
```text
CI: FAIL - Import PASS, Smoke PASS, Perf 100 units WARN, Perf 200 units WARN, Tests (Error Lab) FAIL
SMOKE: GAME OVER at frame 3780: victory=true player=9 enemy=6
SMOKE: GAME OVER at frame 3660: victory=true player=1 enemy=6
SMOKE: GAME OVER at frame 3720: victory=true player=1 enemy=6
PERF units=100 ms_per_frame=11.41 budget=8.0 arrived=79 stuck=0
PERF units=200 ms_per_frame=26.37 budget=16.0 arrived=118 stuck=0
tests run: 248, failed: 10
FAIL-> test_10_c6: assert (FAIL line; no PASS line) [task agent of test_10_c6] FAIL 10.C6: caravan pop (got 0, want 1)
FAIL-> test_10_c7: assert (FAIL line; no PASS line) [task agent of test_10_c7] FAIL 10.C7: 1 check(s) failed
FAIL-> test_12_a1: assert (FAIL line; no PASS line) [ai-coder] FAIL 12.A1: 2 problem(s)
FAIL-> test_20_a3: assert (FAIL line; no PASS line) [ai-coder] FAIL 20.A3: bot 0 median think 1.621 ms > 1.5 ms
FAIL-> test_9_c5: assert (FAIL line; no PASS line) [task agent of test_9_c5] FAIL timing: brains + senses 112.8 us per frame (< 100)
FAIL-> test_9_c9: assert (FAIL line; no PASS line) [task agent of test_9_c9] FAIL 9.C9: hard: champion rule median 0.184 ms per tick (limit 0.10)
FAIL-> test_9_v2: assert (FAIL line; no PASS line) [tech-artist] FAIL 9.v2: part below the ground (-0.01)
FAIL-> test_art_lab: assert (FAIL line) [lab group A (visual)] FAIL B4t Triangles: 2534
FAIL-> test_art_lab_calibration: assert (FAIL line) [task agent of test_art_lab_calibration] FAIL B4 Vertices: 20663 (biggest: Merged 19645, Merged 253, Merged 229, Merged 215)
FAIL-> test_replay_lab: assert (FAIL line; no PASS line) [lab group B (simulation)] FAIL replay_lab: script replay does not match ({"diff":["pos: [11626.0,-10939.0,0.0] vs [11619.0,-10870.0,0.0]"],"f":900.0,"t":15.0}) | bot-vs-bot seed 3 is not deterministic: first different checkpoint 600 (36 vs 36 checkpoints) | bot replay from file does not match ({"diff":["pos: [8853.0,-8846.0,0.0] vs [8846.0,-8846.0,0.0]"],"f":600.0,"t":10.0})
```

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\logs`.

## Follow-up (tools upgrade U6, same day)
Triage in `docs/plan/error-lab.md` 3e: test_10_c6 / test_10_c7 updated to caravan pop 0 (PASS), test_9_v2 ground
tolerance 3 cm (PASS on both copies), test_art_lab / test_art_lab_calibration were Error Lab false alarms (lab v1.2
`verdict=last`; these logs re-judged: 240 / 248 PASS). Timing tests + replay: "Quiet PC checklist" (3f).
