# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
History: `docs/plan/history/lead-status-2026-09.md`, restart notes `docs/ideas/restart_*.md`.

**Updated:** 2026-10-14 evening, laptop (nothing pushed).

## Where things are
- Main repo `Documents\four-wizards-rts` (main). Remote https://github.com/jkhgbn/game-rts (private): push only on JS's word.
- Last playtest build: tag `playtest-2026-10-14-5`, `Desktop\FourWizards-2026-10-14-soir.zip` (a real single
  FourWizards.exe + debug-draw dll; export templates 4.7.2 installed with JS's OK, Windows only). NOT copied to OneDrive.
- CI worktree `four-wizards-rts-ci` at playtest-2026-10-14-5. Music samples (CC0) in `Documents\four-wizards-samples\`.
  Template download kept in `Documents\four-wizards-downloads\` (1.28 GB, checksum verified; delete only with JS's OK).
- ci_quick on ce2076c9: 434 / 434, Error Lab WARN (both fixed after), perf 6.9 / 12.8 ms.
- Pre-commit guard installed (`core.hooksPath tools/git_hooks`): EOL flips, BOM, lost `\` continuations.

## Done 2026-10-14
- Music B for every track (13 + 7 drives), MusicDirector (random pool with the 4 kingdom themes, drive stems, boss,
  film hold, briefings), missions get GameAudio (they had no SFX), GameAudio own RNG.
- Unit research (unit-upgrades.md 7-15, ui-sc2-console.md 7): 55 rows + Forge V B N + bowman rows at the training
  buildings, effects, kits, UI pages, French, bot (AIResearch). Reviews done and fixed.
- Recurring-bug rules: check_gd R6 (lost `\` continuation, 30 old ones fixed), R7 (bare `free()`: a parse error in the
  exported game; broke items / inventory / champions / helpers in the 10-13 and 10-14 morning builds), BootCheck
  (`-- --boot-check` in the exe), playtest-release fails a build on SCRIPT ERROR.

## Running / next (JS picked all four 2026-10-14)
1. UR.B1 balance: `run_fg.py` arms baseline vs `docs/balance/ur_2026-10-14/variants/ur_off.json` (fg `research_off`;
   the JSON now lists research rows bought per side), then Fire vs Shadow at normal pace (champions / worker raids).
2. Faster CI + reliable perf: four-wizards-high agent working in `tools/ci/` + `tests/perf_test.gd`.
3. Wave Strike balance (WS3.B1 / WS4.B1) + more units on screen; missions our sims fail (e3m1, e4m4, e5m4, e6m2 hard).
4. Small: e3m3 lambda-capture warning, world_forge nav warning, UI Lab `hud_research` screen + STR pick, tooltip delay,
   mission objectives folding, music.md still says mono / 77 MB, skirmish beast boss bars without boss music,
   test_casters_bots hard ice:shadow fails (pre-existing, research off too), test_e5m1 flaked once.
