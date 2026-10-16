# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
History: `docs/plan/history/lead-status-2026-09.md`, restart notes `docs/ideas/restart_*.md`.

**Updated:** 2026-10-16 ~19:30 UTC, laptop (nothing pushed).

## Where things are
- Main repo `Documents\four-wizards-rts` (main). Remote https://github.com/jkhgbn/game-rts (private): push only on JS's word.
- Last playtest build: tag `playtest-2026-10-16` (f223ba20), `Desktop\FourWizards-2026-10-16.zip`, notes
  `docs/plan/playtest-notes.md`. The campaign fix wave below is NOT in a build yet.
- Disk: C: ~4 GB free (local lab PNGs deleted with JS's OK). Weekly usage 88 % (resets 2026-10-18 05:00 UTC): JS's cap
  is 95 %, so no new agent waves before the reset.

## Campaign review + fix wave (JS 2026-10-16 "grade all missions" then "fait tout jusqua 95%")
- Review: `docs/playtests/campaign_review_2026-10-16/summary.md` (avg C+ 6.7; fixes list at the end).
- Done and committed: ending_b speaker per road + 90 s credits (c0a1b0e0), Hollow King silhouette (e158a6fd), e7m2 / e7m4
  goal-based phases (f962d82a), e8m2 ~20 min + e8m3 HP phases / Ward Mend (e09b86e5), weakest missions e2m3 / e2m5 /
  e4m2 new final verbs (a85658d9), e5m1 nightfall (rush stall fix), readability + Ruin Slinger (8b3d34ed), ep1-2
  Shadow wave variety (a1e704db), French for all new text (02379595).
- Sims: 34 / 36 green on the wave run (cr-wave-sims), then e8m2 window and e5m1 fixed.
- Determinism (side session, f9e938bf): the mission harness bakes nav on the main thread, turns nav async off and fixes
  seeds. Sims no longer flip on load; e2m2 still drifts after ~3:44 with one seed (cause open, note
  `sim-determinism-root-cause.md` in the side-session notes folder). `mission_e2_03.gd:959` still bakes on a thread.
- Not done from the review: "another final verb" for more missions beyond the weakest four; e6m1 / e6m2, e3m4 / e4m1,
  e4m3 / e4m4 near-twins; new genre breaks after ep5; the player's own keyhole step in e8m3; credits names / roles.

## Open points for JS (also in the final message)
- Credits line "Made with the Godot Engine." (agent-added) and whether credits are skippable before a first viewing.
- Dacian's gender: e7m2 English says "him", the French of e7 says "la". One must change.
- e6m1 new Aldra / Torvald lines are subtitle-only (no voice clip).

## Known follow-ups
- Design docs' wave tables (mission-02/-03/-04, e2m1, e2m2, e2m4) still list the old rows (game-designer).
- Nav watchdog copies in e6m1 / e6m2: move into main.gd for every level, then drop them.
- i18n extractor catches fire_once ids (`knives_%d`, `beat%s`) and the fog shader in fog_of_war.gd:542.
- Quartermeet bridges pale; Nature keep smoke above the canopy; "1 resources still in use at exit" in every test.
- Balance: next step needs a unit change (JS's call, e.g. L3 Gloom Thrall 70 HP).
