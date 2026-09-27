# World Forge set: forge_watch_keep

**Result: PASS**, score **100 / 100** (0 FAIL, 0 WARN, 9 PASS). Hash `e081912a67ec`. 6.4 s.

| ID | Check | Status | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) | rebuild the set; never hand-edit the generated scene |
| B1 | Draw calls | PASS | 118 surfaces (20 particles / multimesh) | <= 150 (budget line) | scatter bakes to one surface per material; drop a placed model or use a mesh-only kit |
| B2 | Lights | PASS | 0 visible Light3D  | <= 0 (0 = the stage's LightingRig only) | add lights=off to the place / actor line of the model that brings them (the path is in the measured value) |
| B3 | Triangles | PASS | 70849 | <= 400000 | lower scatter count or use smaller kits |
| S3 | Scatter counts | PASS | 68 instances | every scatter line places its count | widen the area, lower gap= or count= (the area is full) |
| M1 | Subject inside the 2.39 band | PASS | 12 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c | aim look= closer to the subject, or raise from= y |
| M2 | Cameras clear of geometry | PASS | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) | move from= / to= out of the model (see plan.png) |
| M3 | Line of sight to the subject | PASS | ok | nothing placed between the camera and the subject (bounding boxes) | raise the camera or move it round the blocker |
| D1 | Deterministic layout | PASS | e081912a67ec vs e081912a67ec | same spec + seed = the same layout (every transform) | a scatter / row depends on something outside the spec |

## Improve next
- Look at the PNGs in this folder: one question per image (plan = placement, stills = framing).
- Run `run_world_forge.ps1 sheet <id>` (windowed) for the real stills of every mark.

## Files
- `res://art/cinematics/stage_sets/forge_watch_keep/forge_watch_keep.tscn`
- `res://art/cinematics/stage_sets/forge_watch_keep/meshes/ground.res`
- `res://art/cinematics/stage_sets/forge_watch_keep/meshes/paths.res`
- `res://art/cinematics/stage_sets/forge_watch_keep/meshes/scatter.res`
- `res://art/cinematics/stage_sets/forge_watch_keep/meshes/masonry.res`
- `res://art/cinematics/stage_sets/forge_watch_keep/forge_watch_keep_lighting.tres`
- `res://art/cinematics/stage_sets/forge_watch_keep/marks.json`
- `res://docs/tools/world_forge/out/forge_watch_keep/plan.png`

## Notes
- Mark projections: W01_a ndc (-0.03, 0.13), W01_b ndc (-0.02, 0.11), W01_c ndc (-0.01, 0.08), W02_a ndc (0.00, 0.03), W02_b ndc (0.00, 0.03), W02_c ndc (0.00, 0.04), W03_a ndc (0.00, 0.08), W03_b ndc (0.00, 0.08), W03_c ndc (0.00, 0.08), W04_a ndc (0.11, 0.45), W04_b ndc (0.08, 0.41), W04_c ndc (0.05, 0.36)
- Mesh file md5: ground.res 42f483e2, paths.res 67bda8d0, scatter.res f11f50c7, masonry.res 0d481713
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
