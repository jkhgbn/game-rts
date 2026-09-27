# Lab review and improvement pass (2026-09-27, laptop)

User request (2026-09-27): "look at all tools I have made so far and work on right now and find a way to improve them
all; say yes to all suggestions that will improve the quality of the tool". Every improvement to a tool's quality is
pre-approved. Game code, gameplay data and other owners' files stay out of scope (write a handoff note instead).

## Groups (one agent each, folders never overlap)
| Group | Labs | Owns |
|---|---|---|
| A visual | Art Lab, Visual Diff Lab, UI Lab | `tools/art_lab/`, `tools/visual_diff_lab/`, `tools/ui_lab/`, their `docs/plan/*-lab.md`, their tests, their `docs/<lab>/` output |
| B simulation | Perf Lab, Bot Lab, Balance Lab, Replay Lab runner | `tools/perf_lab/`, `tools/bot_lab/`, `tools/balance_lab/`, `tools/replay_lab/`, their docs / tests / output |
| C checks | Error Lab, CI script, Data Lab, Build Lab, Audio Lab | `tools/error_lab/`, `tools/ci/`, `tools/data_lab/`, `tools/build_lab/`, `tools/audio_lab/`, their docs / tests / output |
| later | Map Lab (after World Forge lands: it touches map_lab), tools 1 / 2 / 6 (after they land) | - |

## Common rules
- Project `C:\Users\elzzo\Documents\four-wizards-rts`; Godot only through `tools\godot_run.ps1` (quote `'--'` and comma
  lists). The laptop is shared with 5 other agents: **no perf numbers are meaningful now** — never change a perf
  threshold from today's timings; functional runs only.
- Never run git, never kill Godot processes you did not start, no downloads, no deleting files outside your folders.
- Paths: several scripts still default to desktop paths (`four-wizards-rts-lab`, `four-wizards-rts-ci`, Downloads Godot):
  make them work on this laptop (default to the repo itself when the worktree is missing) without breaking the desktop.
- Keep each lab's own test passing; smoke test `victory=true` and perf test `PERF OK` at the end.
- Report (<= 250 words): per lab, what you found, what you improved, what you left (and why), test lines.

## Known notes per lab (from lead-status.md, 2026-09-26)
- **Art Lab** (v2 done): R5 rim-light counted as glow on painted shaders (ignore <= 4 px edge clusters / drop rim in the
  dark pass); R3 hue gap misleading at low chroma (only when C* > 25); P1/P2 thin hooks (< 0.25 m) don't register at
  40 m (say so in the hint); add emission crop with marked clusters + per-mesh vertex breakdown; B9 should accept
  per-keep copies (art-keep 8.6); surfaces-per-instance count + downward-facing-face waste hint; B1 per-pivot breakdown;
  R3 variant with enemy team colour; ref= short names; objective vs decor landmark budgets; per-variant tris for decor
  sets; screen-space P3/P5 for flat creatures; glow-point local contrast; identity-crest exemption; army batch runner.
  Check which of these v2 already did (c48d59c notes in lead-status) before redoing.
- **Perf Lab**: quiet baseline command `run_perf_lab.ps1 -WaitQuietS 600 -Repeats 3` (run later on a quiet PC, not
  now). The noise guard must also notice other agents' non-Godot load.
- **Audio Lab**: fold `<id>_N` takes into the parent cue (volume / 3D / category); QOA import overshoots ~+7 dB on
  harmonic tones (hint: import as PCM / ADPCM); CATEGORY_BY_ID lacks `wizard_fell` / `ability_cast` / `skill_hit`.
- **UI Lab**: 3 FAIL contrast on empty ChampionBar slots (game UI, ui-coder: handoff); the lab missed the HUD keeping
  the 1600 px layout at 3440, selection text through the end panel, invisible Fullscreen switch, setup panel 5 px from
  the bottom at 900p: add checks that would have caught these.
- **Visual Diff Lab**: known noise = neutral creatures' idle pose near the Crown isle (map shots pass up to 0.35 %).
- **Data Lab**: stale `card_key` on Fire units; 244 hard-coded UI strings (no tr()) — reports exist; make them actionable.
- **Bot Lab**: 8 seeds x 2 pairs sim-vs-normal validation; navmesh cache decision from logged start-up parts; default
  `-Dir` points at a lab worktree that does not exist on the laptop.
- **Balance Lab**: default dir / worktree; ~98 games per arm for 20 pts: say the expected wall time before a run.
- **Replay Lab**: next steps in `docs/plan/replay-lab.md` 5-6 (watch-mode polish, `tools/replay_lab/run_replay.ps1`
  scorecard runner + history). Step 0 (project.godot avoidance line) stays with the lead; steps 1-4 touch game code
  (handoff only).
- **Error Lab**: day-end baseline 230/235; caps per test; make the report group failures by owner with the log tail.
- **CI**: `tools/ci/ci.ps1` + scratchpad copies; make it run in-place on the laptop.
