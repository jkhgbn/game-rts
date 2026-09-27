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

Each test runs as `tools/godot_run.ps1 --headless --path <root> -s tests/<t>.gd --fixed-fps 60 --quit-after <cap>`
through `cmd /c ... > log 2>&1`, so stdout and stderr land in one full log per test. Caps (the CI table): default
40000; `*bot_vs_bot*` 116000; `test_9_c9`, `test_10_a3` 150000; `test_8_a1` 200000; `test_12_a1` 60000; `test_8_a2`
100000 (`$Caps` at the top of the script). Exit code **1 when the result is FAIL**, else 0. The console ends with
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

## 4. First run (2026-09-26, validation)
`-Logs` on 5 real tests (test_16a, test_12_c2, test_12_c3, test_data_lab, test_12b_v2, cap 40000): **PASS 100 / 100**,
0 FAIL, 0 WARN, 2 INFO (resources still in use at exit, ObjectDB leaked at exit, 3 tests each), 5 / 5 tests PASS.
Scorecard: `docs/errors/lab/validation_5tests/`. The full-suite baseline (every test) is the lead's next run.
