# Lead status — current state (rewrite this file, don't append)

Read first after a reset, with `docs/plan/owner-asks.md` (waiting for JS) and `docs/plan/decisions.md` (already decided).
History: `docs/plan/history/lead-status-2026-09.md`, restart notes `docs/ideas/restart_*.md`.

**Updated:** 2026-10-14 morning, laptop (overnight run while JS slept; nothing pushed).

## Where things are
- Main repo `Documents\four-wizards-rts` (main). Remote https://github.com/jkhgbn/game-rts (private): push only on JS's word.
- Last playtest build: tag `playtest-2026-10-13-3` (zip on Desktop + OneDrive). Everything below is newer than that zip.
- CI worktree `four-wizards-rts-ci` at 69b0b985 (clean). Music samples (CC0) in `Documents\four-wizards-samples\`.
- Full ci_quick on HEAD (9444cce5 + earlier): 421 / 421 tests pass (docs/ci/2026-10-14_0428); perf 100 units WARN only
  under load.

## Done 2026-10-13 / 14 (all committed)
- Mission sims fixed (e3m1, e5m4 incl. Vessa level cap, e6m2, e7m3, e7m4); campaign freed-object sweep.
- SC2-style console HUD; snappy retarget (target dies -> new target next frame).
- Wave Strike M2: 9-10 cards per kingdom (casters, support, T3), caps 36 / 60 / 84, field cap 200 (225 too slow on the
  laptop), WaveBot mixes, UnitGrid perf, 10-card Muster panel; then **wave-strike.md 15 / 16**: the Desert-Strike-style
  deployment pad (place / drag / sell tokens, formations spawn as placed, march locked until contact, bot Line /
  Spearhead) and unit upgrades (Armoury R / Y / O + 2 upgrades per card, bot buys them); Ashwind Reach pad clearings;
  horizon fits every map size.
- Unit icons for all 73 Unit Guide units.
- Music Forge: 4 tracks + choir test, A (synth) and B (CC0 orchestral samples) on JS's Desktop
  (`FourWizards-musique-ecoute`). Waiting for JS's pick.
- Balance (docs/balance/b13_2026-10-13/report.md + diagnosis.md): kept Hush daze + Flash Freeze buff (round 1) and the
  normal-pace bot profiles (Ice 33-35 % -> 42 % at normal; Blitz unchanged). Not kept: Hush cooldown / Rime Bolt
  (round 2), Fireball cut. Wizard retreat rule built, OFF. The 10-13 "Hush A/B" was INVALID (unimported worktree) ->
  run_fg.py now imports when needed and rejects broken games.

## Open
1. Fire beats Shadow at normal pace (~70 %): diagnosis says champions / worker raids decide normal games — next lever
   there (champion use by the Shadow bot, worker defence), not spells.
2. Music: JS's A / B pick, then the remaining tracks + MusicDirector (music.md).
3. Wave Strike: balance batches with formations + upgrades (WS3.B1 / WS4.B1); perf beyond 200 per side (RVO, models).
4. A new playtest build when JS wants one (console, Wave Strike pad + upgrades, icons).
5. Small: e3m3 lambda-capture warning, world_forge nav query warning, UI Lab STR pick before HUD shots, tooltip delay,
   mission objectives folding, lane units' 15-frame periodic scan is fine (event rescans are instant).
