# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
History: `docs/plan/history/lead-status-2026-09.md`, restart notes `docs/ideas/restart_*.md`.

**Updated:** 2026-10-13 evening, laptop (JS playtests the 10-13 build when he can; asked to keep working).

## Where things are
- Main repo `Documents\four-wizards-rts` (main). Remote https://github.com/jkhgbn/game-rts (private): push only on JS's word
  (nothing pushed since 10-12).
- Playtest build: tag `playtest-2026-10-13-3`, `FourWizards-2026-10-13.zip` on the Desktop + OneDrive (stock Godot + .pck;
  export templates = owner ask).
- CI worktree `four-wizards-rts-ci` at 69b0b985 (imported). Playtest worktrees `play`, `play3` (frozen).
- Music samples (CC0 VSCO 2 CE subset, 753 MB): `Documents\four-wizards-samples\VSCO-2-CE` (outside the repo; JS approved).

## Done today (all committed)
- Mission sims: e7m3 / e7m4 / e3m1 / e5m4 / e6m2 scripted players fixed (e5m4 Vessa level cap 5 = real fix); freed-object
  sweep in scripts/campaign (+ test_freed_cast_sweep).
- Balance B13 round 1 (69b0b985, report docs/balance/b13_2026-10-13): Hush daze + Flash Freeze buff. Normal Fire 63 /
  Ice 35 / Nature 67 / Shadow 35 (Fire-Shadow 11 / 16); Blitz 54 / 42 / 60 / 44.
- Wave Strike M2 (wave-strike.md 14; 005191e0, 4361059c, a903663a): 9-10 cards per kingdom (casters, support, T3), caps
  x1.5 = 36 / 60 / 84, WaveBot mixes, lane casters, UnitGrid + scan buckets + avoidance gating, 10-card Muster panel.
  Perf gate (laptop, load x1.75): 200 per side slightly over budget (clash p95 40 ms vs 35), 225 clearly over (60 ms) ->
  field_cap 200. Further perf: RVO avoidance, model animation cost.
- SC2-style console HUD (0a7c01a6, ui-sc2-console.md).
- Snappy retarget (2fbdf910): a unit whose target dies rescans in the same physics pass (cap 20 per frame).
- Music Forge (65cd395a, dce0cc7c; music.md): 4 tracks + choir test, version A (synth) and B (CC0 samples, stereo);
  listening folder on JS's Desktop `FourWizards-musique-ecoute`. Waiting for JS: A or B, the melodies, the choir.

## Running
- gameplay-coder: B13 round 2 (H2 Smoke Cloak 16 s / autocast at 2+, I2 Rime Bolt 55/70/85) -> then screens.
- fw-art-medium: 21 missing unit icons (Wave Strike cards show initials).

## Next
1. B13 round 2 screens (run in the CI worktree, isolated): Fire-Shadow normal, Ice pairs normal; then a confirmation.
2. Music: after JS's pick, the remaining tracks (Ice, Nature, Shadow, Wave Strike, finale, defeat, calm), MusicDirector,
   contexts / rotation / combat layer (music.md tasks), QOA import.
3. WS2.B1: Wave Strike balance batches (wave-strike.md 14.5) with the new cards.
4. New playtest build when JS wants one (console + WS M2 + music if picked).
5. Follow-ups: UI Lab picks STR before HUD shots (for-lead.md), tooltip delay 0.25 s (project.godot), 2v2 Team button,
   mission objectives folding, designer notes (e5m4 crystal nodes dry at 9:00; e3m1 Torvald pings), WS 2560 / 3440 shots.
