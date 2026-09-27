# cine check: two_wizards

2026-09-27 07:48:24 - `tools/cine/run_cine.ps1 check two_wizards` - hash `0f2e1d0433ed88b8` (2 runs identical)

## Result: **PASS** - quality **98 / 100**

0 FAIL, 0 WARN, 12 PASS, 6 info, 0 skipped, 1 s

## Improve next
1. **S1 face vessa** (PASS): keep vessa nearer the band centre in S1 _(from F1 S1 face vessa, shot S1)_
2. **S1 face shade** (PASS): keep shade nearer the band centre in S1 _(from F2 S1 face shade, shot S1)_
3. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 12 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 2 actors, 0 markers, 2 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 7.00 s (2 shots) | 6..12 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S1 face vessa | PASS 91 | worst u 0.12 v 0.38 at 4.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | S1 face shade | PASS 91 | worst u 0.87 v 0.44 at 4.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | S2 face vessa | PASS 100 | worst u 0.50 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S1>S2 axis | PASS 100 | same side: shade-vessa | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S1 line 1 (src 8) | PASS 100 | vessa "Who walks the wall at this hour?" 12.0 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 0f2e1d0433ed88b8 / 0f2e1d0433ed88b8 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | first run |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |

## Notes
- source `data/cinematics/src/two_wizards.cine` (12 lines), 7.0 s, 2 shots, stage: cine-built (props / cast)
