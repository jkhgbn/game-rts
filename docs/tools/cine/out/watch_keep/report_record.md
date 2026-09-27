# cine record: watch_keep

2026-09-27 08:33:45 - `tools/cine/run_cine.ps1 record watch_keep`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 2 PASS, 1 info, 0 skipped, 89 s

## Improve next

## Playback
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | frames | PASS 100 | 317 frames, 10.5 s cinematic time, wall 87.6 s, worst frame 365.1 ms | plays to the end |  |
| P2 | movie | PASS 100 | C:\Users\elzzo\Videos\four-wizards-rec\watch_keep\watch_keep.png | Movie Maker PNG sequence + WAV outside res:// |  |
| P3 | size / fps | INFO | Movie Maker frame 1600x900 (project viewport size), 30 fps; reframed to 1280x536 by the reframe pass (2.39 band crop, no bars drawn) | res= and fps= honoured |  |

## Notes
- Movie Maker writes <name>00000000.png ... + <name>.wav; convert to video only with the user's OK (no ffmpeg here)
- player: cine preview (CinePreview); tool 1 CinematicPlayer present
