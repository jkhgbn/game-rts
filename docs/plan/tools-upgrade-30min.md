# Tools upgrade pass: ~30 minutes, right after tonight's playtest (2026-09-27)

User (JS, 13:30): "make a plan for after playtest: have all tools upgraded, must take like 30 min". Starts when JS says
go after the playtest. 6 agents in parallel (Opus 5.5, medium; each owns one group, no shared files), ~25 min each,
then the lead runs every tool's test + smoke + perf (5 min) and commits per group. Input = today's weak spots.

| # | Group (owner files) | Upgrades (from today's notes) | Done when |
|---|---|---|---|
| U1 | **Art Lab** (`tools/art_lab/`) | craft checks C1-C4 graded for critters / buildings / landmarks (today: values only); a cast-pose shot (`play_cast` is never exercised: Pyre Adept / Hexweaver casts unchecked); per-run improvement log option `log=<file>` (the effort trial saw other runs' rows); shared-kit-material snap recipe; batch speed: parallel settle waits (27 s -> target 15 s / asset) | `PASS art_lab`, `PASS art_lab_calibration`, batch timing printed |
| U2 | **cine + Cinematic Runtime** (`tools/cine/`, `scripts/cinematics/`) | `record` at the requested size (today 1600x900 only: set the window / viewport size override for the record run); a set cue API so sets can fire spell VFX (today only the .cine can); puppets count as speakers (W in probes); Lens marks solved at bake | `PASS tool_cine`, `PASS tool_cine_runtime`, a 5 s 1920x804 record |
| U3 | **World Forge + Lens** (`tools/world_forge/`, `tools/lens/`) | `flock` line (request in for-world-forge.md); `keep_height=1` / pads so raised pieces sit on rock tiers over terrain (the citadel could not use hills); set generators live in the set folder by convention; Lens idle-sway tolerance (62 mm vs 60 WARN); switch Lens to `ToolReport.grade()` | `PASS tool_world_forge`, `PASS tool_lens` |
| U4 | **Voice Forge + Audio Lab** (`tools/voice_forge/`, `tools/audio_lab/`) | `audition only=` no longer rewrites the whole auditions.md; auto speed-fit per line to its slot (5 lines run long today); direction tags in lines (`[scared]` -> speed / pauses / stutter text); voice lines checked by the Audio Lab (loudness per speaker) | `PASS tool_voice_forge`, `PASS audio_lab` |
| U5 | **Map Lab + Bot / Balance Labs** (`tools/map_lab/`, `tools/bot_lab/`, `tools/balance_lab/`) | 2v2 support from the 2v2 audit (`docs/design/map-2v2-audit.md`: seats, ally distance, travel-time table as a Map Lab section); Bot Lab `-Validate` short mode (2 seeds) that fits in 10 min; Balance Lab arms for the new bowmen / caravan 0 supply | `PASS map_lab`, bot / balance tests PASS |
| U6 | **Error Lab / CI / Replay / Perf** (`tools/error_lab/`, `tools/ci/`, `tools/replay_lab/`, `tools/perf_lab/`) | today's CI result folded in (history); the Replay avoidance line in `project.godot` (lead) with a quick A/B + `test_replay_lab`; Perf Lab quiet baseline run while the PC is otherwise idle (last 10 min, alone); AI timing tests test_20_a3 / test_12_a1 re-run quiet | CI summary PASS lines, replay test result, perf baseline table |

**Not in 30 min** (next tools wave, window 2 of tools-wave.md): tool 4 Model Forge, 5 Motion Lab, 7 VFX Composer,
8 Palette Studio, 9 Sound Forge, 10 Script Desk; Build Lab export (needs export templates: a download to approve).

**Optional in the same pass:** the free-tools pack (fonts, Phantom Camera, Proton Scatter, icons) is staged by the
project; it is installed only if JS writes "install the free-tools pack" (downloads / new plugins need his word).

**Order:** launch U1-U5 together at go; U6 starts its code parts at go and runs the perf baseline + AI timing tests in
the last 10 minutes when the other agents are done (quiet PC). Lead: collect, test, commit per group, one reply with a
table (tool, what changed, test line).
