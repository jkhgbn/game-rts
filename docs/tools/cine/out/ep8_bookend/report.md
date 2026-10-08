# cine check: ep8_bookend

2026-10-08 12:37:54 - `tools/cine/run_cine.ps1 check ep8_bookend` - hash `ad19ea2ba7de3238` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 21 PASS, 10 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 45 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 4 actors, 40 markers, 4 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 35.00 s (4 shots) | 33..37 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | E23 face oldman | PASS 100 | worst u 0.46 v 0.48 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | E23 face child | PASS 100 | worst u 0.58 v 0.61 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | E24 face oldman | PASS 100 | worst u 0.44 v 0.54 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | E24 face child | PASS 100 | worst u 0.65 v 0.67 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | E25 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F6 | E25B faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut E23>E24 axis | PASS 100 | same side: child-oldman | 180-degree rule |  |
| C2 | cut E24>E25 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut E25>E25B axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | E23 line 1 (src 28) | PASS 100 | master "...and that, child, is the end of the ta.." 11.9 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | E23 line 2 (src 29) | PASS 99 | child "Is it true? Were you really him?" 12.3 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | E23 line 3 (src 30) | PASS 100 | master "I know this tale well, child. I was that.." 9.2 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | E24 line 1 (src 33) | PASS 92 | child "Were you sad, when they stopped needing .." 14.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | E24 line 2 (src 34) | PASS 100 | master "No. That was the whole point." 11.6 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | E25 line 1 (src 40) | PASS 100 | master "...Well. So that is where it went." 12.1 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 6 / 6 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | ad19ea2ba7de3238 / ad19ea2ba7de3238 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was d08ff9c59b74b069) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (oldman in E23 (cine 40, runtime 40 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep8_bookend.cine` (45 lines), 35.0 s, 4 shots, stage: set forge_citadel
