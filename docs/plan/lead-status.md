# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
The old running log (2026-09-26/27, Updates 1-12) is in `docs/plan/history/lead-status-2026-09.md`; the restart notes
of 2026-10-01 to 10-10 are in `docs/ideas/restart_*.md` (history now: this file replaces them).

**Updated:** 2026-10-13 morning, laptop (overnight run while JS slept).

## Where things are
- Main repo: `Documents\four-wizards-rts` (branch main) on the desktop and on the laptop (same path; Godot `C:\Godot` on both).
- Remote: https://github.com/jkhgbn/game-rts (private). Push only on JS's word (nothing pushed overnight).
- Playtest worktrees (detached, frozen): `four-wizards-rts-play` and `play3`.
- CI worktree `four-wizards-rts-ci` on the laptop (nightly CI at 03:00, `Documents\four-wizards-nightly\latest.txt`).
- Claude setup: hooks in `.claude/settings.json`, skills `/wave`, `/ci-suite`, `/playtest-release`, reviewer `contract-reviewer`.

## Playtest build 2026-10-13 (ready)
- Tag `playtest-2026-10-13-3` (f9b71e34: + e8m1 freed-scout fix, campaign freed-object sweep). Zip replaced 10:24. `FourWizards-2026-10-13.zip` (239 MB) on the Desktop and in OneDrive;
  build folder `Documents\four-wizards-build\FourWizards-2026-10-13\` (FourWizards.exe = stock Godot 4.7.2 renamed,
  FourWizards.pck, Jouer.bat = `--main-pack`, LISEZMOI.md). Boot-tested from the extracted zip.
- Why a pck: export templates are missing (`%APPDATA%\Godot\export_templates` empty); `--export-pack` works without
  them. Downloading the templates needs JS's OK (owner-asks).
- Notes for JS: `docs/plan/playtest-notes.md` (French).
- CI: ci_quick 400 / 400 (docs/ci/2026-10-12_2206); full CI on the first tag 40 / 45 (docs/ci/playtest-2026-10-13-sims).
  Of the 5 failing sims: e7m3 / e7m4 were sims following old buggy behaviour (fixed in the tests, 8dcc0bb9);
  e3m1 / e5m4 / e4m4 also fail on the 57f8851b baseline (pre-existing; e4m4 flaky). After the first tag only
  commander.gd (Vessa threat memory) and test files changed. ci_quick -Changed -Base 0abaccfe: 404 / 404 (found the e8m1 error).
  All 54 mission sims on tag -3 (docs/ci/playtest-2026-10-13-3-sims): 48 / 54, 0 script errors; e2m4 / e2m5 pass on rerun
  (flaky), e6m2 also fails seeds 1-2 on tag -2 (flaky / pre-existing), e3m1 / e5m4 pre-existing, e8m3 flaky (3 / 4).

## Balance (open)
- `docs/balance/confirm_2026-10-13/report.md`: Blitz fine (Ice weak 29 %); normal pace Fire 72-75 % vs Shadow.
- Prime suspect R2-3: Mother Hush used to `command_stop` her attackers (wiped the Fire bot's attack-move orders);
  the review fix (`drop_target_if`) is correct play but removed that edge. A/B runs: `fg-ab-prefix-57f8` (bot fixes
  only: Fire 7 / 12) and `fg-ab-hush-main` (current main + old Hush: Fire 2 / 12). CONFIRMED: R2-3 is the cause
  (report A/B 2). Patch reverted; CI worktree clean at 8dcc0bb9.
- Next: a Shadow / Hush compensation that keeps the fix (e.g. Hush's slow / blink / taunt), measured with
  `run_fg.py --pairs fire:shadow,shadow:fire --seeds 1-6` on Crown Hollow, then normal-pace re-check.

## Uncommitted in the working tree
- Lab outputs only (docs/tools, docs/balance, docs/art/lab, docs/ui, docs/visual, generated `.uid` / `.import`).
  Waiting for JS (owner-asks: gitignore the generated runs, keep summaries).

## Next
1. JS playtests the zip; collect feedback in `docs/ideas/jss_asks.md`.
2. Hush / Shadow compensation (above), Ice in Blitz.
3. Sims e3m1 / e5m4 / e4m4: improve the scripted players (pre-existing failures), e6m2 hard sizing (designer).
4. Later: follow-ups in docs/handoff/bot-review-2026-10-12.md; perf; art asks; 29 collapsed `\` continuations.
