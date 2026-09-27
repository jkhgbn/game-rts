# Tools wave: rules for the tool agents (frozen by the lead, 2026-09-27)

Window 1 on the laptop (user 2026-09-27: "work on movie or scene maker lab"): **tool 1 Cinematic Runtime, tool 2
Movie Maker `cine`, tool 6 World Forge**. Tools 3 (Lens) and 4 (Model Forge) come after these land.

## Where
- Project: `C:\Users\elzzo\Documents\four-wizards-rts` (laptop: i7-12650H + RTX 3070 Laptop, quiet machine).
- Godot: always through `tools\godot_run.ps1` (same arguments as the exe; quote `'--'` and comma lists).
  Console exe behind it: `C:\Godot\Godot_v4.7.2-stable_win64_console.exe`.
- Never run git (the lead commits per tool folder). Never kill Godot processes you did not start.

## The rules
Section 0 of `docs/plan/tools-wave.md` is binding: text in, one CLI (`tools/<tool>/run_<tool>.ps1 <verb> <id>
[key=value...]`, verbs `help` / `check` / `build` / `sheet` / `demo`), readable out (`docs/tools/<tool>/out/<id>/report.md`
+ `report.json` + PNGs, lab scorecard format, a row in `docs/tools/<tool>/history.md`), errors that teach (file, line,
token, "did you mean"), self-validating, deterministic, headless first, plugs into the labs, no asset surgery,
original only. Each tool writes `tools/<tool>/README.md` (grammar table + one complete example): the cold-start
usability trial (section 13.4) uses only that README.

## Shared base `tools/common/`
Owned by the **tool 2 (`cine`) agent for this window** (the lead delegated the T0 base): `tool_cli.gd`,
`tool_report.gd`, `tool_sheet.gd`, `tool_capture.gd`, `tool_spec.gd` as in tools-wave.md section 1. It writes
`tool_spec.gd` + `tool_cli.gd` + `tool_report.gd` **first** (target: 30 min) and posts their API in
`tools/common/README.md`; tools 1 and 6 read them from there and never edit them (requests go in
`docs/handoff/for-cine.md`). Until they exist, tool 6 writes its parser against the README's documented API.

## Frozen contracts (tools-wave.md 13.2)
- Cinematic resources + `CinematicPlayer` API (+ `seek`, `debug_state()`): `docs/design/cinematics.md` 2-4,
  `docs/plan/prologue-movie-plan.md` 2.2-2.5, tools-wave.md section 2. Tool 1 freezes the 4 resource classes first
  (milestone M1) and writes their field list to `scripts/cinematics/README.md`; the lead relays it to tools 2 and 6.
- Set contract + marks file: prologue 2.3; marks = `<set>/marks.json`
  `{shot: {from, to, look_from, look_to, fov_from, fov_to}}`.
- Lead already added (T0): Input Map actions `cinematic_skip` (Esc, Space), `cinematic_advance` (Enter, KP Enter),
  `cinematic_pause` (P), physical keycodes; `Events.cinematic_started(id)` / `cinematic_finished(id, skipped)`
  (reach them with `get_node_or_null(^"/root/Events")`).
- Recording (user answer 2): live in-engine playback is the main path; `record` = Godot Movie Maker PNG sequence + WAV,
  outside `res://`. No ffmpeg or any other download.
- Demo outputs are real deliverables (user answer 3), under the normal review + labs.

## Owns (only these files)
| Tool | Agent | Owns |
|---|---|---|
| 1 Cinematic Runtime | systems-coder-high | `scripts/cinematics/`, `scripts/ui/cinematic/`, `tests/test_tool_cine_runtime.gd`, `docs/tools/cine_runtime/` |
| 2 Movie Maker `cine` | four-wizards-high | `tools/common/`, `tools/cine/`, `data/cinematics/`, `missions/cinematics/tool_demo/`, `tests/test_tool_cine.gd`, `docs/tools/cine/` |
| 6 World Forge | four-wizards-high | `tools/world_forge/`, `art/cinematics/stage_sets/forge_*`, `data/maps/`, `tests/test_tool_world_forge.gd`, `docs/tools/world_forge/`; minimal additive touch `tools/map_lab/map_profiles.gd` + `map_lab.gd` (`profile_json=<path>`, <= 30 lines, Map Lab test still `PASS map_lab`) |

## Done
The tool's acceptance demo (its section in tools-wave.md) passes, its own test prints `PASS tool_<id>`, the smoke test
still prints `victory=true` and the perf test `PERF OK` (nothing in-game changes). Cap: 2.5 h or 3 build iterations
after the first full demo run; then report the gap. Final report (<= 200 words): files, public API / CLI verbs, test
lines, demo result, what the lead must glue, and "<Tool> notes" for the other tools.
