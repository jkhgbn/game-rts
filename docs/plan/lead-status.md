# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
History: `docs/plan/history/lead-status-2026-09.md`, restart notes `docs/ideas/restart_*.md`.

**Updated:** 2026-10-15 ~22:00 UTC, laptop (nothing pushed).

## Where things are
- Main repo `Documents\four-wizards-rts` (main). Remote https://github.com/jkhgbn/game-rts (private): push only on JS's word.
- Last playtest build: tag `playtest-2026-10-14-5`, `Desktop\FourWizards-2026-10-14-soir.zip` (not on OneDrive).
- CI worktree `four-wizards-rts-ci` moved to c47509c0 (G-F); full CI run `gf-2026-10-15` running there (-Parallel 3).
- Disk: C: ~5.6 GB free. Local-only lab PNGs ~3.4 GB in `docs/art/lab` (git-excluded): delete only with JS's OK (asked).
- Weekly usage 74 % (resets 2026-10-18 05:00 UTC). Stop new waves at 85 %, keep 8 % reserve.

## Graphics week (JS 2026-10-15 "les graphiques les + beaux possible"; plan + full log `docs/plan/graphics-week.md`)
- Done and committed: G-A lighting tiers / water / grass / wizards / shared materials, G-B buildings (4 kingdoms +
  neutral) + spell VFX, G-C units (4 kingdoms, champions, mounts, titans), G-D world life (creatures, props, ambient life,
  combat feedback, rings + HP bars, menu diorama, trees, fog look), G-E review round 1 (`docs/art/ge_review.md`) and all
  its 14 fixes (team readability, value pass, night / snow / forest moods, Ashwind lane, autumn maps).
- G-F committed: minimap framing in small-bounds levels a4b2eef2, Art Lab `cavalry_mounted` tier c036d618, offscreen
  emitters root cause (`OffscreenEmitters`, test_gf_offscreen_emitters) 39a4f8c3, G-E fixes D c47509c0.
- Running: Nature death leaves in `art/vfx/combat_vfx.gd`, art review round 2 (`docs/art/gf_review2.md`, read-only),
  full CI, balance fs7-r5 (1 game at a time, ~95 / 144 at 21:00 UTC).
- Next: fixes from review round 2 while budget allows; windowed fps at High / Ultra (200 units + Wave Strike) on a quiet
  machine; playtest build (playtest-release skill) + French notes in `docs/plan/playtest-notes.md`.

## Balance (JS "try to 50/50 balance")
- Combo A shipped (decisions.md 2026-10-15). fs7-r5 compares 4 bot-only arms; when done: `fg_report.py --run fs7-r5`,
  ship the best variant if it beats combo A, update `docs/balance/fs_2026-10-14/results.md` + decisions.md.

## Known follow-ups
- Team ring off at Low; `TEAM_RING_ALPHA` may be weak on dirt. `em_cloth` ownership table vs owners.json mismatch.
- "1 resources still in use at exit" in every test (global, not a leak of one test).
- Older list (2026-10-14): Wave Strike balance, sims failing e3m1 / e4m4 / e5m4 / e6m2 hard, e3m3 lambda warning, UI Lab
  `hud_research`, tooltip delay, music.md mono note, test_casters_bots hard ice:shadow.
