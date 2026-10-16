# CI: gf-2026-10-15

2026-10-15 22:05 - ci v2.3 - project `C:\Users\elzzo\Documents\four-wizards-rts-ci` - scope **full**

## Result: **FAIL**

| Step | Result | Detail | Fix |
|---|---|---|---|
| Import | PASS | no script / parse errors (50.4 s) |  |
| Smoke | PASS | 3 / 3 victory=true |  |
| Perf 100 units | PASS | PERF units=100 ms_per_frame=8.86 budget=8.0 arrived=72 stuck=0 \| load x1.35, normalised 6.56 ms |  |
| Perf 200 units | PASS | PERF units=200 ms_per_frame=14.05 budget=16.0 arrived=106 stuck=0 \| load x1.24, normalised 11.35 ms |  |
| Tests (Error Lab) | **FAIL** | 536 / 549 tests pass; Error Lab FAIL 0 / 100 (3 FAIL, 0 WARN unique errors, 1 NEW) | Open error_lab/scorecard.md: 'By owner' + one fix-agent brief per owner. |

## Tests by owner (from the Error Lab)
| Owner | FAIL errors | WARN errors | Failed tests |
|---|---|---|---|
| task agent of test_mt10_layout_bots (engine error, no script frame) | 2 | 0 |  |
| task agent of test_map_big_e2e (engine error, no script frame) | 1 | 0 |  |
| task agent of test_9_c9 | 0 | 0 | test_9_c9 |
| task agent of test_e2m1_sim | 0 | 0 | test_e2m1_sim |
| task agent of test_e2m2_sim | 0 | 0 | test_e2m2_sim |
| task agent of test_e2m3_sim | 0 | 0 | test_e2m3_sim |
| task agent of test_e2m4_sim | 0 | 0 | test_e2m4_sim |
| task agent of test_e2m5_sim | 0 | 0 | test_e2m5_sim |
| task agent of test_e3m1_sim | 0 | 0 | test_e3m1_sim |
| task agent of test_e3m4_sim | 0 | 0 | test_e3m4_sim |
| task agent of test_e4m4_sim | 0 | 0 | test_e4m4_sim |
| task agent of test_e7m2_sim | 0 | 0 | test_e7m2_sim |
| task agent of test_g2a_ground | 0 | 0 | test_g2a_ground |
| task agent of test_m3_sim | 0 | 0 | test_m3_sim |
| task agent of test_save_load_missions | 0 | 0 | test_save_load_missions |

Full report, log tails and fix-agent briefs: `error_lab/scorecard.md`.

## Result lines
```text
CI: FAIL - Import PASS, Smoke PASS, Perf 100 units PASS, Perf 200 units PASS, Tests (Error Lab) FAIL
SMOKE: GAME OVER at frame 3840: victory=true player=10 enemy=7
SMOKE: GAME OVER at frame 3840: victory=true player=10 enemy=7
SMOKE: GAME OVER at frame 3840: victory=true player=10 enemy=7
PERF units=100 ms_per_frame=8.86 budget=8.0 arrived=72 stuck=0
PERF load calib_ms=0.230 ref_ms=0.170 load=1.35 norm_ms_per_frame=6.56 window_median=6.83 windows=14 slowdown=0.00
PERF units=200 ms_per_frame=14.05 budget=16.0 arrived=106 stuck=0
PERF load calib_ms=0.210 ref_ms=0.170 load=1.24 norm_ms_per_frame=11.35 window_median=11.37 windows=14 slowdown=0.00
tests run: 549, failed: 13
FAIL-> test_9_c9: assert (FAIL line; no PASS line) [task agent of test_9_c9] FAIL 9.C9: hard: only 2 hires by 9:20; hard: hire order ["coin_cutter", "mender"] (want coin_cutter, mender, wayfinder)
FAIL-> test_e2m1_sim: assert (FAIL line; no PASS line) [task agent of test_e2m1_sim] FAIL e2m1_sim/vey: defeat at 532 s (hold)
FAIL-> test_e2m2_sim: assert (FAIL line; no PASS line) [task agent of test_e2m2_sim] FAIL e2m2_sim/vey: step 'play' timed out
FAIL-> test_e2m3_sim: assert (FAIL line; no PASS line) [task agent of test_e2m3_sim] FAIL e2m3_sim: step 'play' timed out
FAIL-> test_e2m4_sim: assert (FAIL line; no PASS line) [task agent of test_e2m4_sim] FAIL e2m4_sim: step 'play' timed out
FAIL-> test_e2m5_sim: assert (FAIL line; no PASS line) [task agent of test_e2m5_sim] FAIL e2m5_sim: defeat at 1410 s (boss3)
FAIL-> test_e3m1_sim: assert (FAIL line; no PASS line) [task agent of test_e3m1_sim] FAIL e3m1_sim: step 'play' timed out
FAIL-> test_e3m4_sim: assert (FAIL line; no PASS line) [task agent of test_e3m4_sim] FAIL e3m4_sim: defeat at 1645 s (raid)
FAIL-> test_e4m4_sim: assert (FAIL line; no PASS line) [task agent of test_e4m4_sim] FAIL e4m4_sim: step 'play' timed out
FAIL-> test_e7m2_sim: assert (FAIL line; no PASS line) [task agent of test_e7m2_sim] FAIL e7m2_sim: step 'play' timed out
FAIL-> test_g2a_ground: cap reached (no PASS line) [task agent of test_g2a_ground]
FAIL-> test_m3_sim: assert (FAIL line; no PASS line) [task agent of test_m3_sim] FAIL m3_sim/victory: defeat at 982 s (phase race)
FAIL-> test_save_load_missions: assert (FAIL line; no PASS line) [task agent of test_save_load_missions] FAIL save_load_missions: mission_e8_02 FAIL team 2 units 5 -> 1
```

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\gf-2026-10-15\logs`.
