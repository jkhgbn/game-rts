# cine check: ep7_ending

2026-10-08 12:06:06 - `tools/cine/run_cine.ps1 check ep7_ending` - hash `5dbf62515a60cb2b` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 26 PASS, 17 info, 0 skipped, 4 s

## Improve next
1. **N4 face torvald** (PASS): keep torvald nearer the band centre in N4 _(from F4 N4 face torvald, shot N4)_
2. **N9 face torvald** (PASS): keep torvald nearer the band centre in N9 _(from F10 N9 face torvald, shot N9)_
3. **N9 face aldra** (PASS): keep aldra nearer the band centre in N9 _(from F11 N9 face aldra, shot N9)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 119 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 35 actors, 52 markers, 10 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 70.00 s (10 shots) | 67..73 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | N1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | N2 face torvald | PASS 100 | worst u 0.27 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | N3 face malrik | PASS 100 | worst u 0.50 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | N4 face torvald | PASS 92 | worst u 0.50 v 0.76 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | N5 face malrik | PASS 100 | worst u 0.50 v 0.50 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | N6 face dacian | PASS 100 | worst u 0.60 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | N6 face seraphine | PASS 100 | worst u 0.39 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | N7 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F9 | N8 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F10 | N9 face torvald | PASS 96 | worst u 0.44 v 0.72 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | N9 face aldra | PASS 96 | worst u 0.41 v 0.72 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | N10 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut N1>N2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut N2>N3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut N3>N4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut N4>N5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut N5>N6 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut N6>N7 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C7 | cut N7>N8 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut N8>N9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut N9>N10 axis | PASS 100 | same side: aldra-torvald | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | N1 line 1 (src 50) | PASS 100 | ossavar "Dawn came up on a sea that did not move..." 11.8 cps, 6.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | N3 line 1 (src 61) | PASS 100 | malrik "So. No." 3.9 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | N4 line 1 (src 66) | PASS 100 | torvald "No. Not for now. Not ever." 8.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | N5 line 1 (src 70) | PASS 100 | malrik "We will see who waits longer, Torvald." 11.9 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | N8 line 1 (src 105) | PASS 100 | ossavar "The one price I ever gave back." 10.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | N9 line 1 (src 112) | PASS 100 | ossavar "Gold for fire, they say. He paid in neit.." 10.0 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 6 / 6 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 5dbf62515a60cb2b / 5dbf62515a60cb2b | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was e66f67efbad94166) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (frostd in N1 (cine 170, runtime 170 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep7_ending.cine` (119 lines), 70.0 s, 10 shots, stage: set forge_intro_torvald
- the .cine has 119 lines (demo budget <= 80)
