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

## Running (night 2026-10-12 -> 13, JS asleep, build wanted by ~noon)
- Code review of scripts/ DONE and ALL verified fixes committed (81750691 waves 1-2, be9445e9 / 9256a30f / ffd9c8f0 /
  f3e9fa2e / d56b44c5 missions Ep1-8, fe0718f5 i18n). ci_quick on the result: 400 / 400 PASS, smoke, perf OK
  (docs/ci/2026-10-12_2206).
- Balance confirmation run (agent, measure only, normal + Blitz, Crown Hollow + Thornwater, runs `fg-confirm-1013-*`).

## Next
1. Save the balance report (docs/balance/confirm_2026-10-13/report.md); route anything clearly broken.
2. Tag `playtest-2026-10-13`, full CI (tools\ci\ci.ps1) on the tag in ..\four-wizards-rts-ci.
3. Export from the CI worktree, smoke-run the exe, zip FourWizards-2026-10-13.zip to the Desktop + OneDrive (JS said yes),
   French notes docs/plan/playtest-notes.md.
4. Known for the playtest: e6m2 hard loses in the sim with any scripted defence (was so before the fixes).
5. Later: follow-ups in docs/handoff/bot-review-2026-10-12.md; perf; art asks; character_model instance-id uses (dance
   variant, ride side) for replay determinism; 29 collapsed `\` continuations (readability only).
