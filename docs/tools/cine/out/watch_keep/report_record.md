# cine record: watch_keep

2026-09-27 07:50:40 - `tools/cine/run_cine.ps1 record watch_keep`

## Result: **PASS** - quality **100 / 100** (previous run 50, +50)

0 FAIL, 0 WARN, 2 PASS, 0 info, 0 skipped, 160 s

## Improve next

## Playback
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | frames | PASS 100 | 317 frames, 10.5 s cinematic time, wall 158.6 s, worst frame 614.9 ms | plays to the end |  |
| P2 | movie | PASS 100 | C:\Users\elzzo\Videos\four-wizards-rec\watch_keep\watch_keep.png | Movie Maker PNG sequence + WAV outside res:// |  |

## Notes
- Movie Maker writes <name>00000000.png ... + <name>.wav; convert to video only with the user's OK (no ffmpeg here)
- player: cine preview (CinePreview); tool 1 CinematicPlayer present
