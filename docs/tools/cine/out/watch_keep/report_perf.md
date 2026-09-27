# cine perf: watch_keep

2026-09-27 08:12:12 - `tools/cine/run_cine.ps1 perf watch_keep`

## Result: **PASS** - quality **100 / 100**

0 FAIL, 0 WARN, 8 PASS, 1 info, 0 skipped, 8 s

## Improve next

## Frame cost per shot (60 fps = 16.7 ms)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| PF1 | shot S1 | PASS 100 | 2.6 ms avg (GPU 1.0), worst 11.4 ms at 0.1 s, draws avg 102 max 109, 419 frames | avg <= 16.7 ms (60 fps) |  |
| PF2 | shot S2 | PASS 100 | 2.5 ms avg (GPU 0.9), worst 5.1 ms at 7.8 s, draws avg 83 max 87, 360 frames | avg <= 16.7 ms (60 fps) |  |
| PF3 | shot S3 | PASS 100 | 2.4 ms avg (GPU 0.9), worst 4.7 ms at 14.4 s, draws avg 72 max 77, 360 frames | avg <= 16.7 ms (60 fps) |  |
| PF4 | shot S4 | PASS 100 | 2.5 ms avg (GPU 1.0), worst 4.2 ms at 20.8 s, draws avg 135 max 136, 300 frames | avg <= 16.7 ms (60 fps) |  |
| PF5 | shot S5 | PASS 100 | 2.4 ms avg (GPU 0.8), worst 4.1 ms at 24.4 s, draws avg 105 max 116, 360 frames | avg <= 16.7 ms (60 fps) |  |
| PF6 | shot S6 | PASS 100 | 2.0 ms avg (GPU 0.7), worst 3.9 ms at 31.3 s, draws avg 31 max 32, 300 frames | avg <= 16.7 ms (60 fps) |  |
| PF7 | shot S7 | PASS 100 | 2.3 ms avg (GPU 0.9), worst 3.0 ms at 36.2 s, draws avg 88 max 89, 300 frames | avg <= 16.7 ms (60 fps) |  |
| PF8 | shot S8 | PASS 100 | 2.6 ms avg (GPU 0.9), worst 5.0 ms at 41.8 s, draws avg 140 max 140, 362 frames | avg <= 16.7 ms (60 fps) |  |
| PF0 | worst frame | INFO | 11.4 ms in S1 | noisy: other Godot runs share the PC |  |

## Notes
- window (1600, 900), vsync off, --fixed-fps pacing; GPU = viewport measured render time
