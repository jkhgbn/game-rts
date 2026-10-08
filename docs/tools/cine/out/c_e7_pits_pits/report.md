# cine build: c_e7_pits_pits

2026-10-08 14:01:55 - `tools/cine/run_cine.ps1 build c_e7_pits_pits` - hash `0a575486c1485bcc` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +1)

0 FAIL, 0 WARN, 36 PASS, 14 info, 0 skipped, 3 s

## Improve next
1. **P1 face diamond_archon** (PASS): keep diamond_archon nearer the band centre in P1 _(from F1 P1 face diamond_archon, shot P1)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 86 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 13 actors, 56 markers, 10 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 70.00 s (10 shots) | 67..73 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | P1 face diamond_archon | PASS 91 | worst u 0.49 v 0.22 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | P2 face diamond_archon | PASS 100 | worst u 0.27 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | P2 face malrik | PASS 100 | worst u 0.73 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | P3 face diamond_archon | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | P4 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | P5 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F7 | P6 face torvald | PASS 100 | worst u 0.53 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | P6 face aldra | PASS 100 | worst u 0.42 v 0.39 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | P7 face torvald | PASS 100 | worst u 0.43 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | P7 face aldra | PASS 100 | worst u 0.33 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | P8 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | P9 face torvald | PASS 100 | worst u 0.45 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | P9 face aldra | PASS 100 | worst u 0.38 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | P10 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut P1>P2 axis | PASS 100 | same side: diamond_archon-malrik | 180-degree rule |  |
| C2 | cut P2>P3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut P3>P4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut P4>P5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut P5>P6 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut P6>P7 axis | PASS 100 | same side: aldra-torvald | 180-degree rule |  |
| C7 | cut P7>P8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut P8>P9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut P9>P10 axis | PASS 100 | same side: aldra-torvald | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | P1 line 1 (src 38) | PASS 99 | ossavar "The Hall of Silence, where they teach on.." 12.3 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | P2 line 1 (src 43) | PASS 96 | malrik "Empty the pits, Your Radiance. All of th.." 13.4 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | P2 line 2 (src 44) | PASS 93 | malrik "By morning every dragon on the Coinwater.." 14.4 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | P3 line 1 (src 47) | PASS 100 | diamond_archon "An Archon before me did that once. The Y.." 11.9 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | P4 line 1 (src 51) | PASS 99 | malrik "Then let us call it a tradition." 12.3 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | P5 line 1 (src 56) | PASS 100 | diamond_archon "Yes." 2.9 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | P6 line 1 (src 66) | PASS 90 | aldra "The Hall's lamps are still lit, my lord..." 15.2 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | P7 line 1 (src 70) | PASS 100 | ossavar "You guarded stones. Everyone guards ston.." 10.8 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | P9 line 1 (src 79) | PASS 100 | aldra "Will you ask him, my lord?" 11.8 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | P9 line 2 (src 81) | PASS 100 | torvald "Tomorrow." 5.6 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 10 / 10 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 0a575486c1485bcc / 0a575486c1485bcc | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was e5b1cf121a315f9e) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e7_pits_pits.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (torvald in P1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e7_pits_pits.cine` (86 lines), 70.0 s, 10 shots, stage: set forge_citadel
- the .cine has 86 lines (demo budget <= 80)
