---
name: ci-suite
description: How to run Four Wizards tests and CI (quick CI, changed-files CI, full milestone CI in the CI worktree, labs after a wave, nightly report). Use before committing, after agents return, or when asked to run the tests / CI / check that main is green.
---

# Tests and CI

All Godot runs go through `tools\godot_run.ps1` (the Godot gate, max 4 at once; the hook blocks the bare exe).
Quote `'--'` and comma lists when calling through it (PowerShell drops a bare `--` and splits `a,b`).
`-Changed` with no `-Base` only sees UNCOMMITTED changes: to check a commit (or a balance / data commit after the
fact) use `-Changed -Base HEAD~1` (or `last-green`); a yellow "no uncommitted change" warning means only the core set ran.
The opposite for `ci_quick.ps1 -Files` / `ci.ps1 -Tests`: they are `[string[]]`, so pass `-Files a.gd,b.gd` unquoted
(a quoted `'a.gd,b.gd'` is one string and selects the wrong tests).

| When | Command |
|---|---|
| After an agent / small change | `tools\ci\ci_quick.ps1 -Changed` (tests near the changed files + the core set; `-Base HEAD~N` or `last-green`, `-ListOnly` to preview with the reason per test) |
| A risky core change, before a merge | `tools\ci\ci_quick.ps1 -Changed -Mode reach` (every test that reaches the change) |
| Everyday | `tools\ci\ci_quick.ps1` (whole suite minus the slow simulations in `tools/ci/slow_tests.txt`) |
| Milestone / before a playtest build | `tools\ci\ci.ps1` (import, smoke x3, perf 100/200, every test through the Error Lab, long bot tails with `-Full` on) |
| One test | `& tools\godot_run.ps1 --headless --path . -s tests/test_x.gd --fixed-fps 60 --quit-after 6000` |

## Changed-only selection (`select_tests.ps1`, 2026-10-14)
- A static **dependency index** (`tools/ci/dep_index.ps1`, cached per file by size + mtime, then MD5, in
  `%LOCALAPPDATA%\FourWizardsCI\`; ~10 s cold, ~2 s warm) links files by: res:// loads / scene ext_resources (C),
  `Foo.new()` (C), `extends` (E), static calls `Foo.f()` (S, at most 2 in a row), value reads `Foo.CONST` / quoted
  data ids in tests and missions (K, last hop only). Type hints, compared paths and level-scene tables are no edge.
- **`-Mode near`** (default): tests within `-NearHops 3` hops of a changed file. **`-Mode reach`**: every test that
  reaches it (~2x the test time: ~330 of the 501 tests boot a level, which reaches most gameplay scripts).
- No more "full list" for unit.gd / command_card.gd / commander.gd...: only `project.godot` and `tools/godot_run.ps1`
  do that. A file whose pick exceeds `-WideShare 0.5` of the suite prints `WIDE (N %)` with its count, and its tests run.
- Always run: `test_save_metas test_i18n test_tiers test_ui_card_hotkeys test_casters test_stables` (+ smoke, perf).
- `-ListOnly` (ci_quick) / `-Explain` (select_tests) prints, per test, the changed file and the chain, e.g.
  `test_1_g1  scripts/ui/minimap.gd (4 hops: [res://scenes/main.tscn] scenes/main.tscn [...] [Minimap.new()])`.
- Nothing reaches a file (an icon loaded by a computed name): the old name / folder match is the fallback.
- Check the selector: `powershell -NoProfile -File tools\ci\test_select_tests.ps1` (real cases + a fake project).
  Compare with the old picker on real commits: `tools\ci\measure_selection.ps1 [-Commits 10]` (old / reach / near
  counts and test-minutes per commit, and which CI failures each one would have missed).

## Perf gate (`tests/perf_test.gd`, 2026-10-14)
- Load-proof: every frame also times a fixed calibration slice; `load = calib / 0.17 ms` and the verdict uses
  `norm_ms_per_frame = ms_per_frame / load`. Measured 2026-10-14, 100 units: 3 Godot runs + 6 CPU burners busy -> raw 8.25-8.37 ms (the old gate failed: 8.40-9.06),
  norm 5.51-5.64 (quiet 5.6); 5 / 5 OK, 200 units 2 / 2 OK; 30 % slowdown -> norm 7.5 / 12.8: OVER every time.
- PERF OK needs norm <= the budget (8 / 16 ms) AND norm <= this CPU's baseline +20 % (`BASELINES` in the test:
  laptop 5.6 / 10.1). An injected 30 % slowdown (`-- slowdown=0.3` or env `FW_PERF_SLOWDOWN=0.3`) fails it.
- Unknown CPU (the desktop): budget only, the `PERF gate` line says so. After an intended cost increase, or on a new
  machine, copy the `PERF baseline` line of 3 quiet runs into `BASELINES` (note date + commit).
- Output: `PERF units=... ms_per_frame=...` (raw, the old line, kept for history), `PERF load ...`, `PERF absolute ...`,
  `PERF gate ...`, `PERF baseline ...`, then `PERF OK` / `PERF OVER BUDGET (why)`.
- `ci.ps1`: a timing-only miss (stuck=0) is re-measured once and the better run counts; WARN instead of FAIL only when
  the PC was more than 2.5x slower than the reference. Stuck units always FAIL.

## Notes
- Smoke must print `victory=true`, perf `PERF OK`. Always pass `--quit-after`.
- `ci.ps1` uses the CI worktree `..\four-wizards-rts-ci` when it exists, else this folder (`-Dir .`). Results:
  `docs/ci/<run>/` (summary + `error_lab/scorecard.md` with log tails and fix-agent briefs), history in
  `docs/ci/history.jsonl`.
- Milestone CI runs on a **tag** in the CI worktree, so agents can keep working in the main folder:
  `git -C ..\four-wizards-rts-ci checkout --detach <tag>` then `tools\ci\ci.ps1`.
- Failing test -> send the failure (Error Lab brief) back to the owning agent once; JS's rule: launch a fix agent
  right away for any failing test or CI. Known flaky under load: AI timing tests, replay determinism.
- After a wave that changed visuals: `tools\visual_diff_lab\run_visual_diff_lab.ps1` (re-record intended changes
  with `-Golden -Shots <id>`). Overall picture: `tools\health\run_health.ps1`.
- Nightly: `tools\ci\nightly.ps1` (laptop, scheduled; report in `Documents\four-wizards-nightly\`). Read the latest
  report at the start of a session.
