# cine build: c_e8_muster

2026-10-08 14:02:05 - `tools/cine/run_cine.ps1 build c_e8_muster` - hash `f8454cedde35860f` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 99, -1)

0 FAIL, 0 WARN, 26 PASS, 15 info, 0 skipped, 4 s

## Improve next
1. **M3 face ysolde** (PASS): keep ysolde nearer the band centre in M3 _(from F4 M3 face ysolde, shot M3)_
2. **M2 face vessa** (PASS): keep vessa nearer the band centre in M2 _(from F2 M2 face vessa, shot M2)_
3. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 109 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 38 actors, 68 markers, 8 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 80.00 s (8 shots) | 77..83 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | M1 face vessa | PASS 100 | worst u 0.44 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | M2 face vessa | PASS 96 | worst u 0.80 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | M2 face torvald | PASS 99 | worst u 0.23 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | M3 face ysolde | PASS 90 | worst u 0.89 v 0.43 at 7.25 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | M4 face vey | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | M5 face malrik | PASS 100 | worst u 0.51 v 0.38 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | M6 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | M7 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F9 | M8 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut M1>M2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut M2>M3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut M3>M4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut M4>M5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut M5>M6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut M6>M7 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C7 | cut M7>M8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | M1 line 1 (src 45) | PASS 94 | vessa "Two days on this rock. I've counted ever.." 14.0 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | M2 line 1 (src 53) | PASS 100 | torvald "We came as fast as ice comes." 12.1 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | M2 line 2 (src 55) | PASS 99 | vessa "So, slowly. Welcome anyway." 12.3 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | M3 line 1 (src 68) | PASS 95 | ysolde "Every road behind me is open. I didn't c.." 13.8 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | M4 line 1 (src 73) | PASS 96 | vey "Three. And the one who's always late on .." 13.3 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | M5 line 1 (src 82) | PASS 96 | vey "He asked for all four of you. Especially.." 13.3 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | M6 line 1 (src 90) | PASS 96 | malrik "I heard. I came. Don't make it a speech." 13.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | M7 line 1 (src 105) | PASS 96 | vey "Four keys, four keyholes. Each to your o.." 13.3 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 8 / 8 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | f8454cedde35860f / f8454cedde35860f | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 56043cc0cb0b7993) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e8_muster.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (ysolde in M7 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e8_muster.cine` (109 lines), 80.0 s, 8 shots, stage: set forge_evenmead
- the .cine has 109 lines (demo budget <= 80)
