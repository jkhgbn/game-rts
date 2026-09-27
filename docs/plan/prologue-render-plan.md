# Prologue render plan: the 3-minute cutscene before tonight's playtest (2026-09-27)

User (JS, 12:15 local): once the 3-min script is done, Opus 5.5 medium art agents finish the visuals and render the
3 minutes for the playtest, within ~5 hours. Hard cutoff: render finished and laptop quiet at **17:30** local.
Script + narration: `docs/design/prologue-1min.md` (being extended to ~3 min), `data/cinematics/src/prologue_*.cine`,
voice lines in `data/voice/lines/`. Tools: World Forge (sets), Lens (framing), cine (assembly / check / record),
Cinematic Runtime (playback), Voice Forge (narration). Godot's Movie Maker writes **.avi (MJPEG + PCM) natively**: no
ffmpeg needed for a watchable file.

## Timeline (laptop local time)
| When | Track | Owner (Opus 5.5, medium unless noted) | Output |
|---|---|---|---|
| 12:20-14:30 | **P1 World Forge terrain**: hills (height field from spec: `hill` / `ridge` / `valley` ops, smooth, baked mesh + collision, flat pads for placements), sky / distant mountains card, water plane | tools agent (high: World Forge code) | `tools/world_forge/` terrain ops + README |
| 12:20-14:30 | **P2 The Master's citadel set** `forge_citadel`: a mega castle built from existing building kits + new big parts (towers, bridges, banners, waterfalls, a market ring), marks for the opening shots; uses P1 hills when ready (flat fallback) | tech-artist | `art/cinematics/stage_sets/forge_citadel/` |
| 12:20-14:30 | **P3 Dragon sky**: a flock actor for sets: big + small dragons (reuse frost / cinder dragon, roc, wyrm models; LOD, looping flight paths, banking, wing phases), 30-60 flyers within budget | tech-artist | `art/cinematics/flocks/` + a World Forge `flock` line |
| 12:20-14:30 | **P4 Four wizard vignettes**: one small set per wizard (strength beat + weakness beat) reusing existing sets / biome kits and each wizard's `play_cast` / spell VFX | tech-artist | `art/cinematics/stage_sets/forge_intro_<wizard>/` |
| 14:30-16:00 | **P5 Assembly**: final `.cine` for the 3 min (Lens framing words, marks from P2 / P4, dragons from P3, narration lines at their times, subtitles), `cine check` PASS, stills + timing sheet, fixes | cine owner (high) | `data/cinematics/src/prologue.cine`, stills sheet |
| 16:00-17:15 | **P6 Render**: `cine record` windowed 1920x804 30 fps -> `.avi` (and PNG fallback), narration mixed, check a few frames by eye | lead | `Desktop\Four Wizards - Prologue.avi` + OneDrive copy |
| 17:15-17:30 | Stop every agent, laptop quiet | lead | - |
**Cut order if late:** render the first minute only (citadel + dragons + opening narration) at 16:30 and add the 4 wizard
intros after the playtest; then drop P1 hills (flat citadel); never ship a broken render.

## Rules for every track
- Project `C:\Users\elzzo\Documents\four-wizards-rts`; read CLAUDE.md, the tool READMEs you use, `docs/plan/art-lab.md`.
- Write only in your track's folders. Never run git, no downloads, don't call mcp__hearthbot__ tools. Godot through
  `tools\godot_run.ps1` (quote `'--'`), at most 2 runs at once. 0 lights (fake glows), budgets per World Forge.
- Other agents are changing game units (bowmen) at the same time: if an import shows parse errors outside your
  folders, wait and re-run.
- Report at the end: files, what works, stills you looked at, what is missing.
