# cine build: c3_parley

2026-10-08 01:32:48 - `tools/cine/run_cine.ps1 build c3_parley` - hash `ae2721a8e643a0fc` (2 runs identical)

## Result: **PASS** - quality **97 / 100** (previous run 96, +1)

0 FAIL, 0 WARN, 43 PASS, 15 info, 0 skipped, 2 s

## Improve next
1. **P8 face torvald** (PASS): keep torvald nearer the band centre in P8 _(from F10 P8 face torvald, shot P8)_
2. **P2 face malrik** (PASS): keep malrik nearer the band centre in P2 _(from F2 P2 face malrik, shot P2)_
3. **P9 face vessa** (PASS): keep vessa nearer the band centre in P9 _(from F13 P9 face vessa, shot P9)_
4. **P6 face torvald** (PASS): keep torvald nearer the band centre in P6 _(from F6 P6 face torvald, shot P6)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 106 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 11 actors, 16 markers, 10 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 105.00 s (10 shots) | 96..112 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | P1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | P2 face malrik | PASS 89 | worst u 0.11 v 0.26 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | P3 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | P4 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | P5 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | P6 face torvald | PASS 94 | worst u 0.48 v 0.75 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | P6 face malrik | PASS 100 | worst u 0.48 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | P7 face malrik | PASS 100 | worst u 0.32 v 0.50 at 12.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | P8 face vessa | PASS 100 | worst u 0.48 v 0.48 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | P8 face torvald | PASS 89 | worst u 0.89 v 0.55 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | P8 face ysolde | PASS 100 | worst u 0.36 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | P9 face malrik | PASS 99 | worst u 0.24 v 0.65 at 8.75 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | P9 face vessa | PASS 92 | worst u 0.68 v 0.23 at 12.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | P10 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut P1>P2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut P2>P3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut P3>P4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut P4>P5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut P5>P6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut P6>P7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut P7>P8 axis | PASS 100 | same side: malrik-vessa, malrik-ysolde, vessa-ysolde (on the axis) | 180-degree rule |  |
| C8 | cut P8>P9 axis | PASS 100 | same side: malrik-torvald, malrik-vessa, malrik-ysolde (on the axis), torvald-vessa, torvald-ysolde, vessa-ysolde | 180-degree rule |  |
| C9 | cut P9>P10 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | P1 line 1 (src 35) | PASS 92 | narrator "For the first time since the Master left.." 14.6 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | P2 line 1 (src 42) | PASS 88 | malrik "Look at us. The Master would weep. Mostl.." 16.1 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | P3 line 1 (src 49) | PASS 93 | vessa "The relics aren't a prize. They're a loc.." 14.5 cps, 2.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | P3 line 2 (src 50) | PASS 93 | vessa "Someone is under Crown Hollow, and he's .." 14.4 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | P4 line 1 (src 53) | PASS 92 | ysolde "Obren. The first apprentice. Every battl.." 14.8 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | P4 line 2 (src 54) | PASS 92 | ysolde "And something down there is still fighti.." 14.6 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | P5 line 1 (src 58) | PASS 96 | malrik "A secret apprentice under the lake." 13.5 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | P5 line 2 (src 59) | PASS 96 | malrik "And the cure is that I stop the war I'm .." 13.3 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | P6 line 1 (src 65) | PASS 91 | torvald "She is not lying, Bishop. I have felt it.." 15.0 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | P6 line 2 (src 66) | PASS 89 | malrik "Then let it count. Whoever holds the Hol.." 15.7 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | P7 line 1 (src 72) | PASS 93 | vessa "You sent knives in the night. You took V.." 14.5 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | P7 line 2 (src 74) | PASS 97 | malrik "That was always the plan, little ember." 13.0 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | P8 line 1 (src 78) | PASS 100 | vessa "Help me stop him." 8.9 cps, 1.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | P8 line 2 (src 79) | PASS 100 | torvald "Ice stays out of this war." 11.3 cps, 2.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | P8 line 3 (src 80) | PASS 98 | ysolde "Nature too. Win it or lose it without us.." 12.8 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | P9 line 1 (src 86) | PASS 100 | malrik "Crown Hollow. At dawn." 9.2 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | P9 line 2 (src 87) | PASS 100 | vessa "Bring your army. I'll bring mine." 11.8 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S18 | P10 line 1 (src 105) | PASS 94 | narrator "At dawn, the war would come home to wher.." 13.9 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 18 / 18 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | ae2721a8e643a0fc / ae2721a8e643a0fc | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was c7d867c2830886db) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c3_parley.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (b_shadow in P1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c3_parley.cine` (106 lines), 105.0 s, 10 shots, stage: set forge_watch_keep
- the .cine has 106 lines (demo budget <= 80)
