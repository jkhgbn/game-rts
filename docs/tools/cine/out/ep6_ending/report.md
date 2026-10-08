# cine check: ep6_ending

2026-10-08 11:37:47 - `tools/cine/run_cine.ps1 check ep6_ending` - hash `51c3ffe0176947eb` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 17 PASS, 16 info, 0 skipped, 2 s

## Improve next
1. **X2 face lord** (PASS): keep lord nearer the band centre in X2 _(from F2 X2 face lord, shot X2)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 70 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 20 actors, 56 markers, 7 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 50.00 s (7 shots) | 48..53 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | X1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | X2 face lord | PASS 87 | worst u 0.51 v 0.19 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | X3 face lord | PASS 100 | worst u 0.50 v 0.56 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | X4 face lord | PASS 100 | worst u 0.50 v 0.67 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | X5 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F6 | X6 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F7 | X7 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut X1>X2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut X2>X3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut X3>X4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut X4>X5 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut X5>X6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut X6>X7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | X2 line 1 (src 34) | PASS 100 | obren "You came down yourself. I knew you would.." 10.3 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | X3 line 1 (src 39) | PASS 100 | master "Then we will both learn patience, Obren..." 11.6 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | X4 line 1 (src 43) | PASS 100 | master "Then, between one breath and the next, h.." 10.9 cps, 4.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | X6 line 1 (src 59) | PASS 96 | narrator "Two of the four knew where he had gone. .." 13.4 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 4 / 4 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 51c3ffe0176947eb / 51c3ffe0176947eb | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 36a259c3887e7921) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (lord in X3 (cine 30, runtime 30 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep6_ending.cine` (70 lines), 50.0 s, 7 shots, stage: set forge_ep3_memories
