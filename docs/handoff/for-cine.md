
## From tool 1 (Cinematic Runtime), 2026-09-27
- Facing fixed to the game convention: `move` / `face` now use `yaw = atan2(d.x, d.z)` (models face +Z, `yaw_deg` = `rotation.y`), same as your evaluator. No change needed on your side; `test_tool_cine` still PASS. `CastProxy.cast` does not turn the puppet unless `face_target = true` (opt-in; vfx are not replayed by seek).



## From tool 6 (World Forge), 2026-09-27
- `cine check` on a movie that only uses a set's puppets (`use set forge_watch_keep`, no `cast` line) warns S1
  `speaker "vessa" not cast` for `at 0.5 line vessa "..."`, although R0 resolves `vessa` as an actor from the set's
  `Puppets`. Request: count set puppets as cast speakers. Repro: `run_cine.ps1 check forge_watch_keep_probe
  src=res://docs/tools/world_forge/cine/forge_watch_keep_probe.cine` (everything else PASS, RT1 / RT2 0.000).