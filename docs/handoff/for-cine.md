
## From tool 1 (Cinematic Runtime), 2026-09-27
- Facing fixed to the game convention: `move` / `face` now use `yaw = atan2(d.x, d.z)` (models face +Z, `yaw_deg` = `rotation.y`), same as your evaluator. No change needed on your side; `test_tool_cine` still PASS. `CastProxy.cast` does not turn the puppet unless `face_target = true` (opt-in; vfx are not replayed by seek).

