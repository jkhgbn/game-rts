# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
History: `docs/plan/history/lead-status-2026-09.md`, restart notes `docs/ideas/restart_*.md`.

**Updated:** 2026-10-16 ~03:10 UTC, laptop (nothing pushed).

## Where things are
- Main repo `Documents\four-wizards-rts` (main). Remote https://github.com/jkhgbn/game-rts (private): push only on JS's word.
- Last playtest build: tag `playtest-2026-10-14-5`, `Desktop\FourWizards-2026-10-14-soir.zip` (not on OneDrive).
- CI worktree `four-wizards-rts-ci` at c47509c0. Full CI `gf-2026-10-15` (under heavy load) failed 13 / 549; re-run at HEAD
  on a quieter machine: all pass (sims, test_9_c9, test_save_load_missions); 2 false FAILs fixed in the Error Lab 8449c5af.
- Disk: C: ~4.5 GB free. Local-only lab PNGs ~3.4 GB in `docs/art/lab` (git-excluded): delete only with JS's OK (asked).
- Weekly usage 81 % (resets 2026-10-18 05:00 UTC). Stop new waves at 85 %, keep 8 % reserve.

## Graphics week (JS 2026-10-15 "les graphiques les + beaux possible"; plan + log `docs/plan/graphics-week.md`)
- G-A to G-E done. G-F review round 3 (`docs/art/gf_review3.md`) top 6 all committed: Ice keep calm c544719d, VfxCap
  427b6bc3 + mount flash 613f0632, building HP bars 2c1b2673 + hover 7e1f52c9, sites 362abe35, autumn haze fd0a191b,
  Fire keep / crucible / keep smoke 69681225; leftovers 8197b17e (Fire Hall chimney, grass under site pads), Thornwater
  timber bridges f3a871a7, frost needle crash 8572ccbf.
- Next: quick CI on the night's commits (`ci_quick -Changed -Base 2c1b2673`), quiet perf_test + test_ws_perf, playtest
  build (playtest-release skill: tag, CI on the tag, export, zip on the Desktop) + French notes `docs/plan/playtest-notes.md`.

## Balance (JS "try to 50/50 balance")
- Combo A shipped (decisions 2026-10-15). Round 5 (fs7-r5) done: combo A stays (spread 17), no bot arm ships
  (decisions 2026-10-16). Next step needs a unit change (JS's call: e.g. L3 Gloom Thrall 70 HP).

## Known follow-ups
- Quartermeet bridges read pale (granite). Nature keep smoke starts above the canopy. Fire keep "drop outer ring at tier 1".
- Team ring off at Low; `TEAM_RING_ALPHA` may be weak on dirt. `em_cloth` ownership table vs owners.json mismatch.
- "1 resources still in use at exit" in every test (global).
- Older list (2026-10-14): Wave Strike balance, e3m3 lambda warning, UI Lab `hud_research`, tooltip delay, music.md mono note.
