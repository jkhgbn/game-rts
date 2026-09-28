# cine record: ep2_opening

2026-09-27 21:30:24 - `tools/cine/run_cine.ps1 record ep2_opening`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 2 PASS, 1 info, 0 skipped, 15 s

## Improve next

## Playback
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | frames | PASS 100 | 36 frames, 3.5 s cinematic time, wall 11.8 s, worst frame 407.5 ms | plays to the end |  |
| P2 | movie | PASS 100 | C:\Users\elzzo\Videos\four-wizards-rec\ep2_opening\ep2_opening.png | Movie Maker PNG sequence + WAV outside res:// |  |
| P3 | size / fps | INFO | Movie Maker frame 1600x900 (project viewport size), 10 fps; reframed to 1920x804 by the reframe pass (2.39 band crop, no bars drawn) | res= and fps= honoured |  |

## Notes
- Movie Maker writes <name>00000000.png ... + <name>.wav; convert to video only with the user's OK (no ffmpeg here)
- player: cine preview (CinePreview); tool 1 CinematicPlayer present
