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
- Code review fix wave 1 (batches in `docs/handoff/fix-batches-2026-10-12.md`, file-disjoint): F1 save framework
  (general agent, scripts/core save_* + mission_base + mission_e5_base + ember_crown + mission_hud attach param), F2
  gameplay-coder, F3a systems-coder (world / skirmish save), F3b systems-coder (buildings / economy / story_films), F4
  ui-coder, F7 ai-coder. Each returns -> contract-reviewer -> ci_quick -Changed -> commit.
- Disk C: ~15 GB free. Nightly CI at 03:00 tests local main.

## Next (JS 2026-10-12 evening: whole code review + all fixes, then the build)
1. Review DONE for all of scripts/ (R, W, V, U, C1-C6) and verified (`code-review-2026-10-12.md`, verify section;
   mission save design `mission-save-hardening-2026-10-12.md`).
2. Wave 2 after F1-F4: F5 cinematics (V1-1..4), F6 items (R1-1 inventory, R5-4..7, U2-5), then mission batches
   M1 Ep1, M2 Ep2, M3 Ep3/4, M4 Ep5/6 (C5), M5 Ep7/8 (C6, re-check each item) on F1's framework (systems-coder).
3. Commit `tests/test_save_metas.gd` (core CI list) once all renames land; un-skip `mission_e4_*` + late-step saves in
   `tests/test_save_load_missions.gd`; CLAUDE.md contracts: Unit `set_down`, `drop_target_if`, `add_modifier` heal_gain,
   saved_state group, MissionBase save hooks.
4. Balance confirmation run (normal + Blitz, 2 maps) after the fixes.
5. Tag, full CI, export, zip to Desktop + OneDrive (JS plays on the desktop).
6. Later: perf (pose scripts 3.6 ms), art asks; follow-ups in `docs/handoff/bot-review-2026-10-12.md`.
