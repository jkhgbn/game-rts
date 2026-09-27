# Error Lab scorecard: fix-2026-09-27_art

2026-09-27 10:32 - lab v1.1 - 5 tests (0 failed) - project `C:\Users\elzzo\Documents\four-wizards-rts` - logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\fix-2026-09-27_art\logs`

## Result: **PASS** - score **100 / 100**

0 unique FAIL errors - 0 unique WARN errors - 0 INFO (exit noise) - 0 NEW (not in the last 10 history rows) - previous run baseline-2026-09-27-partial: FAIL 14

Score = 100 - 8 per unique FAIL error - 3 per unique WARN error - 10 per failed test (min 0).

## Improve next
1. Nothing: no errors, every test passed.

## By owner (who has work)
| Owner | FAIL errors | WARN errors | Failed tests | Tests to re-run |
|---|---|---|---|---|
| - | 0 | 0 | - | - |

## Tests
| Test | Result | Why | Exit | Seconds | Cap |
|---|---|---|---|---|---|
| test_12_v28 | PASS |  | 0 | 4.3 | 40000 |
| test_13_v13 | PASS |  | 0 | 5.4 | 40000 |
| test_13_v5 | PASS |  | 0 | 5.2 | 40000 |
| test_13c_v1 | PASS |  | 0 | 5.4 | 40000 |
| test_13c_v3 | PASS |  | 0 | 3.6 | 40000 |

## Unique errors
| # | Sev | New | Location | Owner | Count | Tests | Message |
|---|---|---|---|---|---|---|---|
| - | - | - | - | - | - | - | none |

## Gone vs the previous run (baseline-2026-09-27-partial): fixed, or their test did not run this time
- Invalid call. Nonexistent 'float' constructor. @ res://tests/test_13c_v1.gd::_run
- Invalid call. Nonexistent 'float' constructor. @ res://tests/test_13_v13.gd::_run

## INFO (known exit noise, never FAIL)

## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)

No briefs: nothing to fix.
