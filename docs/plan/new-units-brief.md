# New units brief: Pyre Adept, Hexweaver, Frostbow (Art Lab v3 phase 4.2)

Effort trial result (2026-09-27, JS blind pick): **medium effort is best for art** (JS: "D is the best"; high acceptable
for light tasks). One session per unit, Opus 5.5 **medium** effort. Your unit is `<UNIT>` (the session that starts you
tells you which). The Nature Vinelasher (medium trial winner) is at `art/units/nature/vinelasher/`: use it as the
quality bar and the kit pattern.

## Where
- Project: `C:\Users\elzzo\Documents\four-wizards-rts` (Windows, PowerShell). Read `CLAUDE.md`, `art/units/kit/README.md`,
  `docs/plan/art-lab.md`, and `docs/design/rush-balance.md` section 5 (stats 5.1, art briefs 5.4) for your unit only.
- Write ONLY in your folder: Pyre Adept `art/units/fire/pyre_adept/`, Hexweaver `art/units/shadow/hexweaver/`,
  Frostbow `art/units/ice/frostbow/` (scene `<id>.tscn` + scripts). Report: `docs/art/lab/new-units/<id>.md`.
  Art Lab output: `docs/art/lab/new-units/<id>/`.
- Never run git, never edit outside those paths, never kill Godot you did not start, no downloads. Other sessions
  work in the same folder. Godot only through `tools\art_lab\run_art_lab.ps1` or `tools\godot_run.ps1`.
- Art only: no UnitType .tres, no gameplay code (step 16 code tasks do that). Hooks per the brief (`play_attack()`,
  `play_cast()`, ...). Original design only, 0 lights, kingdom palette, 1-2 glow points at 40 m.

## Must read apart from (use as `ref=`)
- Pyre Adept (Fire caster): `ember_archer`, `flame_guard`, and Vessa's silhouette (a caster must not look like the hero).
- Hexweaver (Shadow caster): `nightbolt`, `shade`, `shadow_knight`.
- Frostbow (Ice ranged): `frostrune_rifleman`, `rimeshield`, `shardcaster`.

## Loop
`.\tools\art_lab\run_art_lab.ps1 art/units/<kingdom>/<id>/<id>.tscn unit <kingdom> -Extra 'out=docs/art/lab/new-units/<id>','ref=<refs>'`
then fix every FAIL and the top "Improve next" (read `fixes.json` + the contact sheet), re-run with `compare=prev`
(`focus=` for single-check re-checks). Stop at no FAIL and quality no longer rising, or **75 minutes**, and in any case
before **17:15 laptop time** (the laptop must be quiet for an 18:00 playtest).

## Report `docs/art/lab/new-units/<id>.md`
Start / end time, each run (command, wall s, quality, FAIL / WARN), final quality, meshes / draws / vertices / glow
points, what you built (5 lines), next steps (3 lines), "Art Lab notes".
