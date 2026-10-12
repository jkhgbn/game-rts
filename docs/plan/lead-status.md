# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
The old running log (2026-09-26/27, Updates 1-12) is in `docs/plan/history/lead-status-2026-09.md`; the restart notes
of 2026-10-01 to 10-10 are in `docs/ideas/restart_*.md` (history now: this file replaces them).

**Updated:** 2026-10-12, desktop PC.

## Where things are
- Main repo: `Documents\four-wizards-rts` (branch main) on the desktop and on the laptop (same path; Godot `C:\Godot` on both).
- Remote: https://github.com/jkhgbn/game-rts (private). Push only on JS's word.
- Playtest worktrees (detached, frozen): `four-wizards-rts-play` .. `play4` (play4 at 664e9f77, older than the latest
  balance / Blitz work). A fresh play5 is due before JS's next playtest (`/playtest-release`).
- CI worktree `four-wizards-rts-ci`: not present on the desktop; `tools\ci\nightly.ps1` creates it. Nightly CI is meant
  for the laptop (`docs/laptop-setup.md`).
- Claude setup (2026-10-12): hooks in `.claude/settings.json` (Godot gate, no git in agents, ownership, GDScript check),
  skills `/wave`, `/ci-suite`, `/playtest-release`, reviewer agent `contract-reviewer`.

## Latest work (all committed)
Campaign Ep1-Ep8 built with films; save/load; Blitz mode (9 workers, median ~11 min); balance rounds 1-2 (T3 = game
changers, T3s 40-60 against each other); Ice bot economy fixes (Ice 23 % -> 40 %); LayoutLevel kits fix; campaign
notes 2026-10-11; perf research 2026-10-12 (`docs/ideas/perf-research-2026-10-12.md`, ranked top 5, nothing applied).

## Uncommitted in the working tree (not reviewed; inspect before committing)
- Lab outputs: ~2900 files under `docs/tools/`, ~320 under `docs/balance/`, `docs/art/lab/_calibration_headless/`, `docs/ui/`.
  Decide: commit as run records or add their folders to `.gitignore`.
- `data/i18n/en/*.pot` + `data/i18n/fr/*.po` (string extraction), a few `tools/map_lab`, `tests/helpers` edits,
  ~45 `tests/*.gd.uid` files (Godot-generated, should be committed with their tests).

## Next
1. JS playtest on a fresh build (play5), then his notes.
2. Shadow weak / Fire strong (normal and Blitz, Thornwater).
3. Perf: pick from the 2026-10-12 research (200 units ~8-13 ms).
4. Open asks in `docs/ideas/jss_asks.md` (faces, hair, films, maps, art under 90).
