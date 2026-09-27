# Replay Lab scorecard: 2026-09-27_selfcheck

**FAIL, score 0 / 100**: 1 replay(s), 0 PASS, 0 WARN, 1 FAIL. 2026-09-27 07:45, project commit `0fca55bc2db5` (+ uncommitted work), wall 71 s.

> Avoidance runs on several threads (`project.godot` has no `avoidance_use_multiple_threads=false`, replay-lab.md step 0): replays are expected to drift on unit positions after 10-20 s. That FAIL is the determinism signal, not a broken lab.

PASS = every checkpoint + the end hash (a file cut mid-match: every checkpoint). WARN = nothing to compare, or recorded on another commit. FAIL = diverged on this commit, no result, SCRIPT ERROR.

| Replay | Status | Mode | Pair / seed | Length | Cmds | Result | Recorded on |
|---|---|---|---|---|---|---|---|
| recorded_bots_s3 | **FAIL** | bots (sim) | fire:shadow s3 | 0:09 | 0 | 1/1 checkpoints; diverged at 0:09 (frame 540): pos | 0fca55bc2db5 (this) |

## Next steps

- **recorded_bots_s3** (FAIL): Only unit positions drift: multi-threaded avoidance (replay-lab.md step 0: project.godot avoidance_use_multiple_threads=false, lead).

Watch one: `& tools\godot_run.ps1 --path . -s tools/replay_lab/replay_match.gd --fixed-fps 60 ++ --mode=watch --file=<replay>` (the timeline bar marks the diverged checkpoints in red; click it to seek). Raw run: `C:\Users\elzzo\Documents\four-wizards-replay-runs\2026-09-27_selfcheck`.
