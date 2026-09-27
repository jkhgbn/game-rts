# Error Lab: every runtime error, deduped, with an owner and a fix-agent brief

The Error Lab runs the tests through the Godot gate (or reads logs that already exist), collects every runtime /
script error, dedupes them into **unique errors** (count + the tests that hit them), maps each one to its file:line
and to its **owner** (CLAUDE.md "Who owns what", longest folder prefix wins), flags the errors that are **NEW** vs the
previous run, and writes a scorecard in the lab format (PASS / WARN / FAIL, score 0-100, "Improve next") plus one
ready-to-paste **fix-agent brief per owner**. The lead's rule: any FAIL -> launch a fix agent with that brief.
It never edits game code and never runs git.

Files: `tools/error_lab/error_lab.ps1` (the whole lab, Windows PowerShell 5.1), test `tests/test_error_lab.ps1`
(`PASS error_lab`; parse mode on synthetic logs, no Godot, ~5 s).

## 1. Commands
```powershell
cd C:\Users\elzzo\Documents\four-wizards-rts
tools\error_lab\error_lab.ps1                                   # every tests/test_*.gd
tools\error_lab\error_lab.ps1 -Tests test_16a,test_12_c2        # a list
tools\error_lab\error_lab.ps1 -Changed (git diff --name-only HEAD)   # tests that touch the changed files
tools\error_lab\error_lab.ps1 -Logs <folder of *.log>           # parse existing logs only (no Godot)
powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_error_lab.ps1
```
| Parameter | Meaning |
|---|---|
| `-Tests a,b,c` | test names (`test_x`, `test_x.gd` or a path) |
| `-Changed <files>` | changed file list (array, or one `.txt` file with one path per line). Picks `tests/test_*.gd` in the list, plus every test whose source contains `res://<file>` or the file's `class_name` |
| `-Logs <folder>` | parse mode: reads every `*.log` there (the log name = the test name) |
| `-OutDir` | default `docs/errors/lab/<run>/` (logs go to `<OutDir>/logs/` in run mode) |
| `-Run` | run name, default `yyyy-MM-dd_HHmm` |
| `-Parallel N` | tests launched at once (default 3; the gate itself caps Godot at 4 runs) |
| `-TimeoutSec` | wall-clock kill of one test's own process tree (default 2400 s) |
| `-ListOnly` | print the picked tests and their caps, run nothing (check a `-Changed` pick) |
| `-NoHistory` | no row in `docs/errors/lab/history.jsonl` (experiments, fix-agent re-checks) |
| `-HistoryFile` | another history file (the test uses a temp one) |
| `-ProjectDir` | run the tests of another checkout (the desktop CI copy); default = this repo in place |
| `-TailLines` | log lines quoted per failed test (default 15) |

Each test runs as `tools/godot_run.ps1 --headless --path <root> -s tests/<t>.gd --fixed-fps 60 --quit-after <cap>`
through `cmd /c ... > log 2>&1`, so stdout and stderr land in one full log per test. Caps (ONE table, the CI runs its
tests through this lab): default 40000; `*bot_vs_bot*` 116000; `test_9_c9`, `test_10_a3` 150000; `test_8_a1` 200000;
`test_12_a1`, `test_20_a2` 60000; `test_20_a3` 80000; `test_9_c11`, `test_2_a1_attack`, `test_8_b3` 95000; `test_8_a2`
100000 (`$Caps` at the top of the script). **A test can declare its own cap** in its first 20 lines:
`# error_lab: quit-after=95000` (wins over the table; the task agent sets it with the test, nobody edits the lab). Exit code **1 when the result is FAIL**, else 0. The console ends with
`ERROR LAB: <RESULT> score <N> / 100 (...)` and the top 3 errors.

## 2. What it collects and how it classes it
Lines matching `SCRIPT ERROR`, `ERROR:`, `Parse Error`, `Invalid call`, `Nonexistent function`, `freed object`,
`leaked` (continuation lines `at:` / backtrace `[N]` are frames, not errors). The frame is the first `res://` frame in
the following `at:` / backtrace lines; else a `res://` path in the message; else the engine C++ frame.

| Class | Lines | Effect |
|---|---|---|
| FAIL | `SCRIPT ERROR`, `Parse Error`, `Invalid call`, `Nonexistent function`, `freed object`, `Failed to load script` | -8 score per unique error, result FAIL |
| WARN | every other `ERROR:` / `leaked` line (engine errors, `push_error`) | -3 per unique error |
| INFO | known exit noise: `resources still in use at exit`, `ObjectDB instances (were) leaked at exit`, `RID allocations ... leaked at exit`, `Leaked instance:`, `Orphan StringName` | listed, never scored |
| test FAIL | exit code != 0, a line starting `FAIL`, or no line starting `PASS` (timeout / crash) | -10 per failed test, result FAIL |

Normalisation (so the same bug in 30 tests is one error): drops the `ERROR:` / `SCRIPT ERROR:` prefix, `0x...`
addresses, `<Object#id>` ids, `@Node@123` names and every number; the key is `normalised message @ file:line`
(`(engine)` when there is no script frame). Owner: longest CLAUDE.md prefix; `tests/test_x.gd` -> the task agent of
test_x; `tools/<lab>/` -> that lab's owner; engine errors without a script frame -> the task agent of the tests that
hit them. NEW = the key is not in the last row of `history.jsonl`.

Score = 100 - 8 x unique FAIL errors - 3 x unique WARN errors - 10 x failed tests (min 0). PASS = nothing but INFO.

## 3. Output
`scorecard.md` (result, Improve next = top 3 by severity, NEW first, most tests hit; the tests table; every unique
error with owner, count and tests; the INFO list; the fix-agent briefs), `scorecard.json` (same data, for scripts),
one compact JSON row in `docs/errors/lab/history.jsonl` (run, result, score, counts, keys).

Each brief is a `text` block for the owner: the errors (location, message, hits, NEW), repro commands through the
gate, "Done when: `error_lab.ps1 -Tests <those tests> -NoHistory` shows none of these errors and the tests PASS".

## 3b. v1.1 (2026-09-27 lab review, group C)
- **Failed-test diagnosis** per test: `timeout` (wall-clock kill), `crash` (Godot crash handler), `assert` (a FAIL line),
  `script error` (a FAIL-class error and no PASS), `exit code` (non-zero, no FAIL line), `cap reached` (exit 0, no PASS /
  FAIL: the test did not finish within `--quit-after`; hint: raise its cap or find the stall), `no PASS line` (parse
  mode, exit unknown). Each with a fix hint and the **log tail** (last 15 lines without exit noise).
- **Report grouped by owner**: "By owner" table (FAIL / WARN errors, failed tests, tests to re-run) right under
  "Improve next", a "Failed tests" section (diagnosis + FAIL line + log tail), and one brief per owner with its errors
  AND its failed tests (tail included). JSON: `owners`, `tests[].kind / hint / owner / fail_lines / tail`, `gone`.
- **Test owners from the task id** (waves.md letters): `test_<step>_g*` gameplay-coder, `_s*` systems-coder, `_u*`
  ui-coder, `_a*` ai-coder, `_i*` items-coder, `_v*` tech-artist, `_d*` game-designer; `test_<lab>_lab` the lab group;
  C / B / P... stay "task agent of test_x". Engine errors (no script frame) hit in tests of several owners go to the lead
  (one line, not a 120-test owner string).
- **Fewer false NEW**: the key uses the script function (`file::func`), not the line number, so an edit above a known
  bug no longer makes it NEW; NEW = not in the last 10 history rows (a subset run no longer makes the next full run's
  errors NEW). "Gone vs the previous run" lists keys that disappeared. (Keys changed format in v1.1: the first v1.1 run
  shows the day-end keys as gone / NEW once.)
- **PowerShell-wrapped stderr**: logs captured inside PowerShell 5.1 (`*>` / `2>&1` on `godot_run.ps1`) turn the first
  stderr line into `Godot_...exe : ERROR: ...` + `At ...char` / `CategoryInfo` lines; the lab cleans them, so the error
  is counted once and keeps its `at:` frame (before: a second, differently keyed error and a lost frame).
- Progress with ETA while running; `-ListOnly` shows each test's cap and owner; `-ProjectDir` for the CI copy.
- Test `tests/test_error_lab.ps1` covers all of it (wrapped stderr, function key, diagnosis, tail, owner guess).

Laptop baseline 2026-09-27 (`docs/errors/lab/baseline-2026-09-27/`, Parallel 2, PC shared with 5 agents): stopped
after 180 / 243 tests (test_8_a1 onward not run: ~1 h more), parsed with `-Logs`: 173 / 180 PASS, 2 unique FAIL errors
(`Nonexistent 'float' constructor` in test_13_v13.gd:287 and test_13c_v1.gd:317, tech-artist), failed: test_12_v28,
test_13_v5, test_13c_v3 (asserts, tech-artist), test_12_a1 (assert, ai-coder), test_20_a3 (think-time 1.7 ms > 1.5 ms:
timing on a loaded PC, likely noise). Paths are now made absolute (a relative `-OutDir` used to fail on write).

## 3c. CI (`tools/ci/ci.ps1`, v2.0)
One command for the whole integration check, **in place on the laptop** (it uses the desktop CI worktree
`..\four-wizards-rts-ci` only when that folder exists):
```powershell
tools\ci\ci.ps1                                  # import, smoke x3, perf 100 / 200, every test (Error Lab)
tools\ci\ci.ps1 -Tests test_16a,test_12_c2       # same, a test subset (no history row)
tools\ci\ci.ps1 -SkipTests -SmokeRuns 1          # quick gate
tools\ci\ci.ps1 -Dir C:\path\to\copy -ResultFile <scratchpad>\ci_result.txt   # the old desktop call still works
```
Every Godot run goes through `tools/godot_run.ps1` (before: the exe directly, sequential, no timeout). Tests run
through the Error Lab (`-ProjectDir`, parallel `-Parallel 3`, the caps above, owners, briefs) instead of a second copy
of the cap table. Perf OVER BUDGET while other Godot runs share the PC (and no stuck units) is a **WARN (noise)**, not
a FAIL. Output: `docs/ci/<run>/ci.md` (steps, tests by owner, the classic result lines), `ci_result.txt`, `logs/`,
`error_lab/` (the full Error Lab scorecard), and a row in `docs/ci/history.jsonl`. Exit 1 on FAIL.
Laptop check 2026-09-27 (`-SkipImport -SmokeRuns 1 -PerfUnits 100 -Tests test_1_g1`): smoke PASS, perf WARN (11.5 ms
with 6 Godot runs on the PC), test PASS, CI WARN.

## 4. First run (2026-09-26, validation)
`-Logs` on 5 real tests (test_16a, test_12_c2, test_12_c3, test_data_lab, test_12b_v2, cap 40000): **PASS 100 / 100**,
0 FAIL, 0 WARN, 2 INFO (resources still in use at exit, ObjectDB leaked at exit, 3 tests each), 5 / 5 tests PASS.
Scorecard: `docs/errors/lab/validation_5tests/`. The full-suite baseline (every test) is the lead's next run.
