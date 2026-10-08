# cine check: c_e7_mask

2026-10-08 11:59:43 - `tools/cine/run_cine.ps1 check c_e7_mask` - hash `f8e42e5bc4aaebcc` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 26 PASS, 18 info, 0 skipped, 5 s

## Improve next
1. **M2 face malrik** (PASS): keep malrik nearer the band centre in M2 _(from F2 M2 face malrik, shot M2)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 106 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 53 actors, 92 markers, 10 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 70.00 s (10 shots) | 67..73 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | M1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | M2 face malrik | PASS 95 | worst u 0.65 v 0.26 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | M3 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F4 | M4 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | M5 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | M6 face malrik | PASS 100 | worst u 0.50 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | M7 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | M8 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | M9 face aldra | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | M10 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut M1>M2 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C2 | cut M2>M3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut M3>M4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut M4>M5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut M5>M6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut M6>M7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut M7>M8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut M8>M9 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C9 | cut M9>M10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | M1 line 1 (src 44) | PASS 98 | ossavar "The Admiralty, that night. Malrik was in.." 12.6 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | M2 line 1 (src 63) | PASS 98 | malrik "Torvald. Come in. I was just mourning." 12.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | M3 line 1 (src 68) | PASS 100 | torvald "She left this on the sand." 10.0 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | M4 line 1 (src 72) | PASS 100 | malrik "Wars need a first blow. I only provided .." 11.6 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | M5 line 1 (src 76) | PASS 100 | torvald "You broke a truce older than both of us." 11.8 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | M6 line 1 (src 83) | PASS 97 | malrik "Truces are what weak men sign to sleep. .." 12.9 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | M7 line 1 (src 86) | PASS 100 | torvald "For now, I sail with you." 9.6 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | M8 line 1 (src 90) | PASS 99 | malrik "For now. Always your favourite words." 12.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | M9 line 1 (src 100) | PASS 100 | ossavar "He knew the truth, and he waited anyway..." 12.0 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 9 / 9 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | f8e42e5bc4aaebcc / f8e42e5bc4aaebcc | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 86985970812c6267) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (torvald in M1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e7_mask.cine` (106 lines), 70.0 s, 10 shots, stage: set forge_intro_malrik
- the .cine has 106 lines (demo budget <= 80)
