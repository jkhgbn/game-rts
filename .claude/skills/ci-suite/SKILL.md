---
name: ci-suite
description: How to run Four Wizards tests and CI (quick CI, changed-files CI, full milestone CI in the CI worktree, labs after a wave, nightly report). Use before committing, after agents return, or when asked to run the tests / CI / check that main is green.
---

# Tests and CI

All Godot runs go through `tools\godot_run.ps1` (the Godot gate, max 4 at once; the hook blocks the bare exe).
Quote `'--'` and comma lists when calling through it (PowerShell drops a bare `--` and splits `a,b`).

| When | Command |
|---|---|
| After an agent / small change | `tools\ci\ci_quick.ps1 -Changed` (tests naming the changed files + the core set; `-Base HEAD~N` or `last-green`, `-ListOnly` to preview) |
| Everyday | `tools\ci\ci_quick.ps1` (whole suite minus the slow simulations in `tools/ci/slow_tests.txt`) |
| Milestone / before a playtest build | `tools\ci\ci.ps1` (import, smoke x3, perf 100/200, every test through the Error Lab, long bot tails with `-Full` on) |
| One test | `& tools\godot_run.ps1 --headless --path . -s tests/test_x.gd --fixed-fps 60 --quit-after 6000` |

- Smoke must print `victory=true`, perf `PERF OK`. Always pass `--quit-after`.
- `ci.ps1` uses the CI worktree `..\four-wizards-rts-ci` when it exists, else this folder (`-Dir .`). Results:
  `docs/ci/<run>/` (summary + `error_lab/scorecard.md` with log tails and fix-agent briefs), history in
  `docs/ci/history.jsonl`.
- Milestone CI runs on a **tag** in the CI worktree, so agents can keep working in the main folder:
  `git -C ..\four-wizards-rts-ci checkout --detach <tag>` then `tools\ci\ci.ps1`.
- Perf numbers are only valid on a quiet machine (no other Godot running). Quiet reference: 100 units ~5-7 ms,
  200 units ~8-13 ms, stuck=0.
- Failing test -> send the failure (Error Lab brief) back to the owning agent once; JS's rule: launch a fix agent
  right away for any failing test or CI. Known flaky under load: AI timing tests, replay determinism.
- After a wave that changed visuals: `tools\visual_diff_lab\run_visual_diff_lab.ps1` (re-record intended changes
  with `-Golden -Shots <id>`). Overall picture: `tools\health\run_health.ps1`.
- Nightly: `tools\ci\nightly.ps1` (laptop, scheduled; report in `Documents\four-wizards-nightly\`). Read the latest
  report at the start of a session.
