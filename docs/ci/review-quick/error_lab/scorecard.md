# Error Lab scorecard: ci-review-quick

2026-09-27 07:38 - lab v1.1 - 1 tests (0 failed) - project `C:\Users\elzzo\Documents\four-wizards-rts` - logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\review-quick\error_lab\logs`

## Result: **PASS** - score **100 / 100**

0 unique FAIL errors - 0 unique WARN errors - 2 INFO (exit noise) - 0 NEW (not in the last 10 history rows) - previous run day-end-2026-09-26: FAIL 38

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
| test_1_g1 | PASS |  | 0 | 17.4 | 40000 |

## Unique errors
| # | Sev | New | Location | Owner | Count | Tests | Message |
|---|---|---|---|---|---|---|---|
| - | - | - | - | - | - | - | none |

## Gone vs the previous run (day-end-2026-09-26): fixed, or their test did not run this time
- hard: no B7 Guard flag after a raid @ (engine)
- N RIDs of type "CanvasItem" were leaked. @ (engine)
- N RID of type "CanvasItem" was leaked. @ (engine)
- ART LAB ERROR: scene not found: res://nope.tscn @ res://nope.tscn:0

## INFO (known exit noise, never FAIL)
- N ObjectDB instances were leaked at exit (run with `--verbose` for details). - x1 in 1 tests
- N resources still in use at exit (run with --verbose for details). - x1 in 1 tests

## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)

No briefs: nothing to fix.
