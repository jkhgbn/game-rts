# Effort trial brief: the Vinelasher at 4 effort levels (Art Lab v3 phase 4.1)

One brief for 4 separate sessions (Opus 5.5 at **low / medium / high / xhigh** effort). Same task, same rules, so the
only difference is the effort. Your level is `<LEVEL>` (the session that starts you tells you which).

## Where
- Project: `C:\Users\elzzo\Documents\four-wizards-rts` (Windows, PowerShell). Read `CLAUDE.md` first, then
  `art/units/kit/README.md` (the character kit) and `docs/plan/art-lab.md` (the Art Lab manual). Nothing else is needed.
- Your folder (write ONLY here): `art/units/_effort_trial/<LEVEL>/` (scene `vinelasher.tscn` + its scripts / meshes).
  Your report: `docs/art/lab/effort-trial/<LEVEL>.md`. Your Art Lab output: `docs/art/lab/effort-trial/<LEVEL>/`.
- Never run git, never edit anything outside those paths, never kill Godot processes you did not start, no downloads.
  Other sessions and agents work in the same folder at the same time.
- Godot only through `tools\art_lab\run_art_lab.ps1` or `tools\godot_run.ps1` (quote `'--'` and comma lists).

## The unit (from `docs/design/rush-balance.md` sections 5.1 / 5.4)
**Vinelasher**, Nature T2 soldier: "a lean bark warrior with a **coiled thorn whip 3 m long**". Silhouette hook: the whip
coils around the arm (circle read). Attack: the whip lashes out, blossoms on the handle. Glow: whip tip only (1 point).
Hooks: `play_attack()`, `play_cast()` (the Snare Lash). Stats for scale: body height ~1.8 m, melee reach 3.0 m.
Style: `art-units.md` rules (chunky, silhouette = role, painted shaders, 1-2 glow points at 40 m, 0 lights), Nature
palette (`docs/design/kingdom-nature.md` 7). Known hard problem: **green on grass** (the Art Lab R3 / R4k checks) and
the 3 m whip reading at 40 m. Original design only.

## The loop (Art Lab v3)
1. Build the model with the kit (`CharacterModel` like the other Nature soldiers in `art/units/nature/`).
2. Run: `.\tools\art_lab\run_art_lab.ps1 art/units/_effort_trial/<LEVEL>/vinelasher.tscn unit nature -Extra 'out=docs/art/lab/effort-trial/<LEVEL>','ref=thornling,bramblehorn,burr_slinger'`
3. Read `scorecard.md`, `fixes.json`, `contact_sheet.png` (look at it). Fix every FAIL and the top "Improve next" item.
   Re-run with `compare=prev` (and `focus=<checks>` for quick re-checks of one fix).
4. Stop when there is no FAIL and the quality score stops rising, or at **75 minutes**, whichever comes first.

## Report `docs/art/lab/effort-trial/<LEVEL>.md` (the lead compares the 4)
- Start time, end time, total minutes.
- Every Art Lab run: command, wall seconds, quality, FAIL / WARN counts.
- Final quality (median of your last 2 full runs if you have them), final FAIL / WARN list.
- Mesh count / draws / vertices / glow points from the final scorecard.
- What you built (5 lines), what you would do next with more time (3 lines), "Art Lab notes" (confusing messages,
  wrong recipes, false alarms).
Do not look at the other levels' folders or reports.
