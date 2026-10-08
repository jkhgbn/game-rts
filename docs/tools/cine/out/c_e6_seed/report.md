# cine check: c_e6_seed

2026-10-08 11:35:42 - `tools/cine/run_cine.ps1 check c_e6_seed` - hash `1f754fe407fbbe90` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 100, -1)

0 FAIL, 0 WARN, 21 PASS, 10 info, 0 skipped, 3 s

## Improve next
1. **D3 face ysolde** (PASS): keep ysolde nearer the band centre in D3 _(from F4 D3 face ysolde, shot D3)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 56 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 35 actors, 68 markers, 5 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 40.00 s (5 shots) | 38..43 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | D1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | D2 face ysolde | PASS 100 | worst u 0.61 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | D2 face maelis | PASS 100 | worst u 0.38 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | D3 face ysolde | PASS 92 | worst u 0.15 v 0.34 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | D4 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 3.25 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | D5 face maelis | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut D1>D2 axis | PASS 100 | same side: maelis-ysolde | 180-degree rule |  |
| C2 | cut D2>D3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut D3>D4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut D4>D5 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | D2 line 1 (src 37) | PASS 99 | maelis "You never told the village you were righ.." 12.4 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | D2 line 2 (src 38) | PASS 100 | ysolde "I didn't need to. It came up green." 11.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | D3 line 1 (src 43) | PASS 100 | maelis "That branch won't come back, you know." 10.6 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | D3 line 2 (src 46) | PASS 100 | ysolde "Give it a spring." 7.7 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | D4 line 1 (src 51) | PASS 100 | ysolde "Twelve years ago he sent for me one last.." 11.3 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 5 / 5 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 1f754fe407fbbe90 / 1f754fe407fbbe90 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was d7bed8c68a34d644) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (ysolde in D1 (cine 170, runtime 170 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e6_seed.cine` (56 lines), 40.0 s, 5 shots, stage: set forge_evenmead
