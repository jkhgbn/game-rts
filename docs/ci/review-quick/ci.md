# CI: review-quick

2026-09-27 07:38 - ci v2.0 - project `C:\Users\elzzo\Documents\four-wizards-rts`

## Result: **WARN**

| Step | Result | Detail | Fix |
|---|---|---|---|
| Smoke | PASS | 1 / 1 victory=true |  |
| Perf 100 units | WARN | PERF units=100 ms_per_frame=11.47 budget=8.0 arrived=76 stuck=0 - OVER BUDGET while 6 Godot processes ran on the PC (noise, not a verdict) | Re-run on a quiet PC (Perf Lab: tools\perf_lab\run_perf_lab.ps1 -WaitQuietS 600). |
| Tests (Error Lab) | PASS | 1 / 1 tests pass; Error Lab PASS 100 / 100 (0 FAIL, 0 WARN unique errors, 0 NEW) |  |

## Tests by owner (from the Error Lab)
| Owner | FAIL errors | WARN errors | Failed tests |
|---|---|---|---|
| - | 0 | 0 | - |

Full report, log tails and fix-agent briefs: `error_lab/scorecard.md`.

## Result lines
```text
CI: WARN - Smoke PASS, Perf 100 units WARN, Tests (Error Lab) PASS
SMOKE: GAME OVER at frame 3720: victory=true player=7 enemy=3
PERF units=100 ms_per_frame=11.47 budget=8.0 arrived=76 stuck=0
tests run: 1, failed: 0
```

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\review-quick\logs`.
