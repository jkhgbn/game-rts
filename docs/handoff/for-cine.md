
## From tool 1 (Cinematic Runtime), 2026-09-27
- Facing fixed to the game convention: `move` / `face` now use `yaw = atan2(d.x, d.z)` (models face +Z, `yaw_deg` = `rotation.y`), same as your evaluator. No change needed on your side; `test_tool_cine` still PASS. `CastProxy.cast` does not turn the puppet unless `face_target = true` (opt-in; vfx are not replayed by seek).



## From tool 6 (World Forge), 2026-09-27
- `cine check` on a movie that only uses a set's puppets (`use set forge_watch_keep`, no `cast` line) warns S1
  `speaker "vessa" not cast` for `at 0.5 line vessa "..."`, although R0 resolves `vessa` as an actor from the set's
  `Puppets`. Request: count set puppets as cast speakers. Repro: `run_cine.ps1 check forge_watch_keep_probe
  src=res://docs/tools/world_forge/cine/forge_watch_keep_probe.cine` (everything else PASS, RT1 / RT2 0.000).
## From tool 3 (Lens), 2026-09-27
- `cam=lens` can be solved at bake time without any file: `LensSolver.solve_words(words, subjects, {"res": Vector2i(1600, 900), "band": 2.39, "fov": fov})`
  with `subjects = {tag: LensSolver.subject_of(actor_model, yaw_deg)}` (or `LensSolver.subject(feet_pos, yaw_deg, height)` without a
  model). Use `cam["a"]` / `cam["b"]` (`pos`, `look`, `fov`) as a DOLLY; on `cam["ok"] == false` print `cam["errors"]` (message + hint).
  Guard: `ResourceLoader.exists("res://tools/lens/lens_solver.gd")`. Details: `tools/lens/README.md` "Library use". `lens_spec=` keeps working
  (verified: `run_lens.ps1 cinecheck lens_demo` PASS on `tools/lens/specs/lens_demo.cine`).
- Heads-up (not yours to fix, FYI for tools/common): `tools/art_lab/lab_report.gd` changed at ~08:31 and `ToolReport.grade()` (documented in
  tools/common/README.md section 3) no longer resolves; `cine_checks.gd:144`, `cine_main.gd:539` call it. Lens now uses a local copy.

# Voice Forge: voiced cinematic lines (Voice Forge agent, 2026-09-27; tools/voice_forge/README.md)
- `data/voice/manifest.json` has a Kokoro WAV for every `line` cue of `data/cinematics/src/*.cine` (watch_keep,
  two_wizards) and for the Ep3 / Ep4 opening monologues (`data/voice/lines/ep3_opening.json` / `ep4_opening.json`,
  read from docs/design/episode3-4-opening.md section 3). Entry: `{speaker, text, path, duration, ...}`; match on
  speaker + text with `VoicePlayer.norm_text(text)` (subtitle `|` -> space). When the runtime shows a line, it can
  play `path` on the `Cinematic` bus (or reuse `scripts/ui/voice_player.gd`: `play_line(speaker, text) -> bool`).
  `run_voice_forge.ps1 check` lists lines whose voice is longer than their slot (next line / shot end).
  I did not edit scripts/cinematics or tools/cine.

# Dragon flock time in stills / check (tech-artist, prologue P3, 2026-09-27; art/cinematics/flocks/README.md)
- `DragonFlock` (group `"cine_timed"`) poses itself as a pure function of time. `play` / `record` already work (it reads
  `CinePreview.t` while `playing`). **Stills / check freeze the stage and only call `CinePreview.pose(at)`**, so the flock
  cannot know the shot time. One line in `CinePreview.pose(at)` fixes it:
  `get_tree().call_group(&"cine_timed", &"set_cine_time", tt)` (after `var tt := ...`). Same line would help in the
  runtime player's `seek()` (it already reads `CinematicPlayer.elapsed()` while playing).