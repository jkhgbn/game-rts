# cine record: two_wizards

2026-09-27 07:56:27 - `tools/cine/run_cine.ps1 record two_wizards`

## Result: **PASS** - quality **100 / 100**

0 FAIL, 0 WARN, 2 PASS, 0 info, 0 skipped, 15 s

## Improve next

## Playback
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | frames | PASS 100 | 47 frames, 1.5 s cinematic time, wall 13.5 s, worst frame 345.8 ms | plays to the end |  |
| P2 | movie | PASS 100 | C:\Users\elzzo\Videos\four-wizards-rec\two_wizards\two_wizards.png | Movie Maker PNG sequence + WAV outside res:// |  |

## Notes
- Movie Maker writes <name>00000000.png ... + <name>.wav; convert to video only with the user's OK (no ffmpeg here)
- player: cine preview (CinePreview); tool 1 CinematicPlayer present
