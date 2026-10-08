# cine build: m3_plea

2026-10-08 00:26:27 - `tools/cine/run_cine.ps1 build m3_plea` - hash `0cc2f1f7f67799ec` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 96, +2)

0 FAIL, 0 WARN, 23 PASS, 10 info, 0 skipped, 1 s

## Improve next
1. **Y4 face ysolde** (PASS): keep ysolde nearer the band centre in Y4 _(from F5 Y4 face ysolde, shot Y4)_
2. **Y1 face ysolde** (PASS): keep ysolde nearer the band centre in Y1 _(from F1 Y1 face ysolde, shot Y1)_
3. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 36 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 2 actors, 0 markers, 5 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 40.50 s (5 shots) | 38..44 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Y1 face ysolde | PASS 93 | worst u 0.50 v 0.25 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | Y2 face vessa | PASS 100 | worst u 0.50 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | Y3 face ysolde | PASS 100 | worst u 0.50 v 0.44 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | Y4 face vessa | PASS 100 | worst u 0.30 v 0.41 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | Y4 face ysolde | PASS 88 | worst u 0.91 v 0.41 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | Y5 face vessa | PASS 100 | worst u 0.50 v 0.50 at 5.75 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut Y1>Y2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut Y2>Y3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut Y3>Y4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut Y4>Y5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | Y1 line 1 (src 18) | PASS 100 | ysolde "Vessa. Stop. Please." 8.0 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | Y2 line 1 (src 21) | PASS 95 | vessa "NOW you want to talk? Your wood tried to.." 13.6 cps, 3.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | Y2 line 2 (src 22) | PASS 96 | ysolde "My wood tries to eat everyone. It's very.." 13.4 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | Y3 line 1 (src 25) | PASS 96 | ysolde "Those relics aren't a prize. They're a l.." 13.3 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | Y3 line 2 (src 26) | PASS 94 | ysolde "Put three together near the Hollow and t.." 14.0 cps, 3.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | Y4 line 1 (src 29) | PASS 98 | vessa "Everyone says that about the things I wa.." 12.7 cps, 6.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 6 / 6 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 0cc2f1f7f67799ec / 0cc2f1f7f67799ec | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was d038ae70dd7acc31) |  |  |
| B1 | bake | PASS 100 | data/cinematics/m3_plea.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (ysolde in Y1 (cine -30, runtime -30 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/m3_plea.cine` (36 lines), 40.5 s, 5 shots, stage: cine-built (props / cast)
