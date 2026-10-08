# cine build: c_e3_price

2026-10-08 00:10:37 - `tools/cine/run_cine.ps1 build c_e3_price` - hash `e71a8e170ae3efff` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 99, +1)

0 FAIL, 0 WARN, 27 PASS, 15 info, 0 skipped, 3 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 61 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 35 actors, 68 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 64.00 s (9 shots) | 58..70 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | B01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | P2 face malrik | PASS 100 | worst u 0.50 v 0.36 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | P3 face shade | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | P4 face malrik | PASS 100 | worst u 0.50 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | P5 face shade | PASS 100 | worst u 0.50 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | P6 face stone | PASS 100 | worst u 0.50 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | P7 face malrik | PASS 100 | worst u 0.33 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | P7 face hush | PASS 100 | worst u 0.57 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | P8 face torvald | PASS 100 | worst u 0.50 v 0.35 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | B14R faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut B01>P2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut P2>P3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut P3>P4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut P4>P5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut P5>P6 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut P6>P7 axis | PASS 100 | same side: malrik-stone | 180-degree rule |  |
| C7 | cut P7>P8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut P8>B14R | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | P2 line 1 (src 31) | PASS 100 | malrik "I did not ask you anything." 10.8 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | P3 line 1 (src 35) | PASS 97 | shade "Duskbarrow, Bishop. The barrow candles h.." 12.9 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | P4 line 1 (src 37) | PASS 100 | malrik "Whose dead?" 4.4 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | P5 line 1 (src 39) | PASS 100 | shade "Yours." 2.4 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | P7 line 1 (src 49) | PASS 100 | hush "Shall I come?" 5.2 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | P7 line 2 (src 50) | PASS 100 | malrik "Always." 2.8 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | P8 line 1 (src 55) | PASS 100 | torvald "Go. I will keep your ridge cold." 12.0 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 7 / 7 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | e71a8e170ae3efff / e71a8e170ae3efff | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 3ac7d5d98eb70640) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e3_price.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (shade in B01 (cine 232, runtime -128 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e3_price.cine` (61 lines), 64.0 s, 9 shots, stage: set forge_evenmead
