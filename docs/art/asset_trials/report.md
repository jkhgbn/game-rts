# Asset trials: new free addons and tools used in the real game (2026-09-28)

Each test is small and lives in `tests/asset_trials/`. No shipped game code changed. Laptop RTX 3070, 1280x720, Godot 4.7.2; GPU times are indications (other Godot runs may have been open). Smoke test after: `victory=true`.

| Asset | Grade | Verdict | Reason |
|---|---|---|---|
| Debug Draw 3D | 70 | keep as dev tool | Rings and paths on the real map cost 0.28 ms per frame; release export gets a no-op stub. Skirmish pauses at start, so drawer and DebugDrawManager need `process_mode = ALWAYS` or nothing draws. Use line thickness, 1 px is invisible at RTS zoom. |
| Rhubarb | 55 | keep as dev tool | 0.5-2 s per line, good mouth cues. Vessa's only hook swaps the whole face (smile closes her eyes); Malrik has no mouth. Needs 4-6 mouth decals first. |
| Sky3D | 45 | keep, cinematics only | Good clouds in low shots; never visible from the RTS camera, washes out the warm look, +0.3-0.6 ms GPU, dusk too dark to play. |
| Material Maker | 35 | keep as dev tool, low priority | CLI export failed on 2 of 3 runs, .tres is Godot 3 format with black emission; runes already drawn in code. Export PNGs only. |
| Dialogue Manager | 30 | remove or park | Branching and state work, but our dialogue is linear and the DialogueManager autoload is not registered in project.godot. |
| LimboAI | 15 | remove | Same decisions as GDScript but 2x slower (0.0050 vs 0.0025 ms per agent-tick), 88 MB; tuned GDScript brains already exist. |

Evidence: `docs/art/asset_trials/` (14 stills, output logs, rhubarb and material_maker folders). Tests: `tests/asset_trials/` (`trial_stills.gd` windowed, `trial_limboai.gd`, `trial_dialogue.gd`, `trial_rhubarb.gd`, `probe_extensions.gd`).
