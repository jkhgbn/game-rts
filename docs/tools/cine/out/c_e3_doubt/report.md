# cine build: c_e3_doubt

2026-10-08 13:44:16 - `tools/cine/run_cine.ps1 build c_e3_doubt` - hash `b632032b1d59efe3` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 29 PASS, 14 info, 0 skipped, 3 s

## Improve next
1. **D3 face torvald** (PASS): keep torvald nearer the band centre in D3 _(from F3 D3 face torvald, shot D3)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 70 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 35 actors, 68 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 65.00 s (9 shots) | 59..71 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | B01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | D2 face torvald | PASS 100 | worst u 0.50 v 0.63 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | D3 face torvald | PASS 93 | worst u 0.50 v 0.76 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | D4 face malrik | PASS 100 | worst u 0.33 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | D4 face hush | PASS 100 | worst u 0.57 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | D5 face stone | PASS 100 | worst u 0.50 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | D6 face torvald | PASS 100 | worst u 0.29 v 0.52 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | D6 face malrik | PASS 100 | worst u 0.74 v 0.48 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | D7 face malrik | PASS 100 | worst u 0.50 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | D8 face torvald | PASS 100 | worst u 0.50 v 0.65 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | N12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut B01>D2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut D2>D3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut D3>D4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut D4>D5 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut D5>D6 axis | PASS 100 | same side: malrik-stone | 180-degree rule |  |
| C6 | cut D6>D7 axis | PASS 100 | same side: malrik-torvald | 180-degree rule |  |
| C7 | cut D7>D8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut D8>N12 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | D2 line 1 (src 30) | PASS 94 | aldra "The old storm-sword crossed the river tw.." 13.9 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | D2 line 2 (src 31) | PASS 96 | aldra "He only looked at the ridge. Then he wen.." 13.5 cps, 3.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | D3 line 1 (src 34) | PASS 100 | torvald "He is counting us." 7.2 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | D6 line 1 (src 50) | PASS 96 | torvald "What did it cost you, Malrik? In Duskbar.." 13.3 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | D7 line 1 (src 54) | PASS 99 | malrik "A little. Less than you would think." 12.5 cps, 2.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | D8 line 1 (src 62) | PASS 100 | aldra "It glowed when he lied." 9.2 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | D8 line 2 (src 64) | PASS 100 | torvald "I know. I saw." 5.6 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 7 / 7 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | b632032b1d59efe3 / b632032b1d59efe3 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was a31127166345472e) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e3_doubt.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (hush in D4 (cine 10, runtime 10 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e3_doubt.cine` (70 lines), 65.0 s, 9 shots, stage: set forge_evenmead
