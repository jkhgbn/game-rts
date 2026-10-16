# CI: playtest-2026-10-16

2026-10-16 01:21 - ci v2.3 - project `C:\Users\elzzo\Documents\four-wizards-rts-ci` - scope **full**

## Result: **FAIL**

| Step | Result | Detail | Fix |
|---|---|---|---|
| Import | PASS | no script / parse errors (24 s) |  |
| Smoke | PASS | 3 / 3 victory=true |  |
| Perf 100 units | PASS | PERF units=100 ms_per_frame=4.28 budget=8.0 arrived=72 stuck=0 \| load x0.81, normalised 5.32 ms |  |
| Perf 200 units | PASS | PERF units=200 ms_per_frame=7.25 budget=16.0 arrived=106 stuck=0 \| load x0.86, normalised 8.43 ms |  |
| Tests (Error Lab) | **FAIL** | 568 / 576 tests pass; Error Lab FAIL 20 / 100 (0 FAIL, 0 WARN unique errors, 0 NEW) | Open error_lab/scorecard.md: 'By owner' + one fix-agent brief per owner. |

## Tests by owner (from the Error Lab)
| Owner | FAIL errors | WARN errors | Failed tests |
|---|---|---|---|
| task agent of test_9_c9 | 0 | 0 | test_9_c9 |
| task agent of test_e2m1_sim | 0 | 0 | test_e2m1_sim |
| task agent of test_e2m2_sim | 0 | 0 | test_e2m2_sim |
| task agent of test_e2m4_sim | 0 | 0 | test_e2m4_sim |
| task agent of test_e3m2_sim | 0 | 0 | test_e3m2_sim |
| task agent of test_e7m1_sim | 0 | 0 | test_e7m1_sim |
| task agent of test_e7m4_sim | 0 | 0 | test_e7m4_sim |
| task agent of test_e8m3_sim | 0 | 0 | test_e8m3_sim |

Full report, log tails and fix-agent briefs: `error_lab/scorecard.md`.

## Result lines
```text
CI: FAIL - Import PASS, Smoke PASS, Perf 100 units PASS, Perf 200 units PASS, Tests (Error Lab) FAIL
SMOKE: GAME OVER at frame 3840: victory=true player=10 enemy=7
SMOKE: GAME OVER at frame 3840: victory=true player=10 enemy=7
SMOKE: GAME OVER at frame 3840: victory=true player=10 enemy=7
PERF units=100 ms_per_frame=4.28 budget=8.0 arrived=72 stuck=0
PERF load calib_ms=0.137 ref_ms=0.170 load=0.81 norm_ms_per_frame=5.32 window_median=5.42 windows=14 slowdown=0.00
PERF units=200 ms_per_frame=7.25 budget=16.0 arrived=106 stuck=0
PERF load calib_ms=0.146 ref_ms=0.170 load=0.86 norm_ms_per_frame=8.43 window_median=8.46 windows=14 slowdown=0.00
tests run: 576, failed: 8
FAIL-> test_9_c9: assert (FAIL line; no PASS line) [task agent of test_9_c9] FAIL 9.C9: hard: only 2 hires by 9:20; hard: hire order ["coin_cutter", "mender"] (want coin_cutter, mender, wayfinder)
FAIL-> test_e2m1_sim: assert (FAIL line; no PASS line) [task agent of test_e2m1_sim] FAIL e2m1_sim/vey: defeat at 804 s (hold)
FAIL-> test_e2m2_sim: assert (FAIL line; no PASS line) [task agent of test_e2m2_sim] FAIL e2m2_sim/vey: step 'play' timed out
FAIL-> test_e2m4_sim: assert (FAIL line; no PASS line) [task agent of test_e2m4_sim] FAIL e2m4_sim: step 'play' timed out
FAIL-> test_e3m2_sim: assert (FAIL line; no PASS line) [task agent of test_e3m2_sim] FAIL e3m2_sim: defeat at 500 s (flee)
FAIL-> test_e7m1_sim: assert (FAIL line; no PASS line) [task agent of test_e7m1_sim] FAIL e7m1_sim: defeat at 21:20 (final)
FAIL-> test_e7m4_sim: assert (FAIL line; no PASS line) [task agent of test_e7m4_sim] FAIL e7m4_sim: step 'play' timed out
FAIL-> test_e8m3_sim: assert (FAIL line; no PASS line) [task agent of test_e8m3_sim] FAIL e8m3_sim: step 'play' timed out
```

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-10-16\logs`.

## Triage (lead, 2026-10-16)
- 8 / 576 failed at -Parallel 4: test_9_c9 + 7 mission sims (e2m1, e2m2, e2m4, e3m2, e7m1, e7m4, e8m3).
- Re-run at -Parallel 2 (`docs/errors/lab/playtest-2026-10-16-rerun`): test_9_c9, e2m1, e2m4, e7m1 PASS (load);
  e2m2 (defeat 1369 s vice), e3m2 (defeat 500 s flee), e7m4 (defeat 23:45 still), e8m3 (play timed out) still FAIL.
- Bisect of e3m2 (deterministic, same defeat at 500 s every run) between c47509c0 (gf-2026-10-15, PASS) and f223ba20:
  first bad = 2c1b2673 (thin building HP bars). That commit is visual only (bar mesh size, shader instance params,
  read-only hp_bar_width / hp_bar_opacity / set_hp_bar_hover): no gameplay change. So the sims flip on unrelated
  changes (object creation order / RNG stream), not on mission difficulty. Build shipped; root-cause follow-up:
  make the mission sims robust to cosmetic changes (find the order / RNG dependency, or several seeds with a margin).