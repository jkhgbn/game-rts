# cine check: c_e6_lake

2026-10-08 11:37:25 - `tools/cine/run_cine.ps1 check c_e6_lake` - hash `e8b07d1fcf483142` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 23 PASS, 10 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 53 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 13 actors, 28 markers, 5 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 40.00 s (5 shots) | 38..43 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | K1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | K2 face torvald | PASS 98 | worst u 0.22 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | K2 face aldra | PASS 98 | worst u 0.78 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | K3 face aldra | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | K4 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | K5 face torvald | PASS 99 | worst u 0.37 v 0.70 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut K1>K2 axis | PASS 100 | same side: aldra-torvald | 180-degree rule |  |
| C2 | cut K2>K3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut K3>K4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut K4>K5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | K1 line 1 (src 35) | PASS 100 | aldra "The ice has stopped singing." 9.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | K2 line 1 (src 39) | PASS 96 | torvald "There is nothing under it left to sing a.." 13.2 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | K2 line 2 (src 40) | PASS 100 | torvald "A hundred winters I kept it for him." 11.2 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | K3 line 1 (src 43) | PASS 97 | aldra "And a girl with a fire took it in an aft.." 13.1 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | K4 line 1 (src 47) | PASS 100 | torvald "She did. I have worse things to remember.." 10.3 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | K4 line 2 (src 48) | PASS 100 | aldra "The gate." 6.4 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | K5 line 1 (src 52) | PASS 100 | torvald "The gate." 5.6 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 7 / 7 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | e8b07d1fcf483142 / e8b07d1fcf483142 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 401b5790159888ef) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (torvald in K5 (cine 170, runtime 170 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e6_lake.cine` (53 lines), 40.0 s, 5 shots, stage: set forge_intro_torvald
