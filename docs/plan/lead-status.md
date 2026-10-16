# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
History: `docs/plan/history/lead-status-2026-09.md`, restart notes `docs/ideas/restart_*.md`.

**Updated:** 2026-10-16 ~06:00 UTC, laptop (nothing pushed).

## Where things are
- Main repo `Documents\four-wizards-rts` (main). Remote https://github.com/jkhgbn/game-rts (private): push only on JS's word.
- Last playtest build: tag `playtest-2026-10-16` (f223ba20), `Desktop\FourWizards-2026-10-16.zip` (214 MB, not on
  OneDrive), notes `docs/plan/playtest-notes.md` (= LISEZMOI.md in the zip). Exe smoke: main menu loads, 0 errors.
  No new play worktree (disk); `four-wizards-rts-play` still at 9f338fc1.
- CI worktree `four-wizards-rts-ci` at the tag. Full CI `playtest-2026-10-16` (-Parallel 4): import / smoke / perf PASS,
  568 / 576 tests; the 8 fails = the load-sensitive mission sims (e2m1 / e2m2 / e2m4 / e3m2 / e7m1 / e7m4 / e8m3) +
  test_9_c9; re-run at -Parallel 2: `docs/ci/playtest-2026-10-16-rerun` (result below in "Next").
- Disk: C: ~3.1 GB free. Local-only lab PNGs ~3.4 GB in `docs/art/lab` (git-excluded): delete only with JS's OK (asked).
- Weekly usage 81 % (resets 2026-10-18 05:00 UTC). Stop new waves at 85 %, keep 8 % reserve.

## Graphics week (JS 2026-10-15 "les graphiques les + beaux possible"; plan + log `docs/plan/graphics-week.md`)
- G-A to G-E done. G-F review round 3 (`docs/art/gf_review3.md`) top 6 all committed: Ice keep calm c544719d, VfxCap
  427b6bc3 + mount flash 613f0632, building HP bars 2c1b2673 + hover 7e1f52c9, sites 362abe35, autumn haze fd0a191b,
  Fire keep / crucible / keep smoke 69681225; leftovers 8197b17e (Fire Hall chimney, grass under site pads), Thornwater
  timber bridges f3a871a7, frost needle crash 8572ccbf.
- Quick CI on the night's commits green after 53a83c8f; quiet perf_test norm 5.40 (baseline 5.60), test_ws_perf PASS.
- Next: JS playtests the 2026-10-16 build; his notes -> a G-G fix round (budget permitting, weekly reset 10-18).

## Balance (JS "try to 50/50 balance")
- Combo A shipped (decisions 2026-10-15). Round 5 (fs7-r5) done: combo A stays (spread 17), no bot arm ships
  (decisions 2026-10-16). Next step needs a unit change (JS's call: e.g. L3 Gloom Thrall 70 HP).

## Known follow-ups
- Quartermeet bridges read pale (granite). Nature keep smoke starts above the canopy. Fire keep "drop outer ring at tier 1".
- Team ring off at Low; `TEAM_RING_ALPHA` may be weak on dirt. `em_cloth` ownership table vs owners.json mismatch.
- "1 resources still in use at exit" in every test (global).
- Older list (2026-10-14): Wave Strike balance, e3m3 lambda warning, UI Lab `hud_research`, tooltip delay, music.md mono note.
