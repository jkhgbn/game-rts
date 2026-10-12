# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
The old running log (2026-09-26/27, Updates 1-12) is in `docs/plan/history/lead-status-2026-09.md`; the restart notes
of 2026-10-01 to 10-10 are in `docs/ideas/restart_*.md` (history now: this file replaces them).

**Updated:** 2026-10-12 midday, laptop, first lead session opened in the repo folder (hooks, /wave, contract-reviewer active).

## Where things are
- Main repo: `Documents\four-wizards-rts` (branch main) on the desktop and on the laptop (same path; Godot `C:\Godot` on both).
- Remote: https://github.com/jkhgbn/game-rts (private). Push only on JS's word.
- Playtest worktrees (detached, frozen): `four-wizards-rts-play` and `play3` (play2 and play4 removed 2026-10-12 on JS's word). A fresh play5 is due before JS's next playtest (`/playtest-release`).
- CI worktree `four-wizards-rts-ci` on the laptop (created by `tools\ci\nightly.ps1`); nightly CI scheduled there at
  03:00, report `Documents\four-wizards-nightly\latest.txt` (`docs/laptop-setup.md`).
- Claude setup (2026-10-12): hooks in `.claude/settings.json` (Godot gate, no git in agents, ownership, GDScript check),
  skills `/wave`, `/ci-suite`, `/playtest-release`, reviewer agent `contract-reviewer`.

## Latest work (all committed)
Campaign Ep1-Ep8 built with films; save/load; Blitz mode (9 workers, median ~11 min); balance rounds 1-2 (T3 = game
changers, T3s 40-60 against each other); Ice bot economy fixes (Ice 23 % -> 40 %); LayoutLevel kits fix; campaign
notes 2026-10-11; perf research 2026-10-12 (`docs/ideas/perf-research-2026-10-12.md`, ranked top 5, nothing applied).

## Uncommitted in the working tree
- Lab outputs only: ~2900 files under `docs/tools/` (incl. 61 `world_forge/out/*/preview_level.gd.uid`), ~320 under
  `docs/balance/`, `docs/art/lab/_calibration_headless/`, `docs/ui/`, `docs/visual/`; plus `art/blender/prologue_castle/export/`,
  `docs/ci/nightly_2026-10-11/`. Waiting for JS (owner-asks: gitignore the generated runs, keep summaries).
- 2026-10-12 midday: tests/tools `.gd.uid` files, e3 spec notes, i18n re-run and map gate knob committed (0a222e53, 9bc86021).

## Running
- Shadow / Fire balance study (agent, measure only, writes `docs/balance/shadow_fire_2026-10-12/report.md`; changes then
  go through gameplay-coder / ai-coder / systems-coder). Last night's attempt drifted onto Ice and never reported.
- Disk C: ~15 GB free after removing play2 / play4 (was 71 MB at 23:40). Nightly CI task re-enabled on JS's word (next run 03:00).

## Next
1. JS playtest on a fresh build (play5), then his notes.
2. Shadow weak / Fire strong (normal and Blitz, Thornwater).
3. Perf: pick from the 2026-10-12 research (200 units ~8-13 ms).
4. Open asks in `docs/ideas/jss_asks.md` (faces, hair, films, maps, art under 90).
