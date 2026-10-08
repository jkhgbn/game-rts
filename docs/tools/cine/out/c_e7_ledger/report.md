# cine build: c_e7_ledger

2026-10-08 14:02:39 - `tools/cine/run_cine.ps1 build c_e7_ledger` - hash `8208500de47d35f1` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 97, +2)

0 FAIL, 0 WARN, 31 PASS, 18 info, 0 skipped, 3 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 85 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 18 actors, 64 markers, 10 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 70.00 s (10 shots) | 67..73 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | G1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | G2 face aldra | PASS 100 | worst u 0.67 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | G2 face torvald | PASS 100 | worst u 0.31 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | G3 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | G4 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | G5 face aldra | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | G6 face aldra | PASS 100 | worst u 0.65 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | G6 face torvald | PASS 100 | worst u 0.33 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | G7 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F10 | G8 face aldra | PASS 100 | worst u 0.65 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | G8 face torvald | PASS 100 | worst u 0.33 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | G9 face torvald | PASS 98 | worst u 0.50 v 0.71 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | G10 face aldra | PASS 100 | worst u 0.50 v 0.68 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut G1>G2 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C2 | cut G2>G3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut G3>G4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut G4>G5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut G5>G6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut G6>G7 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C7 | cut G7>G8 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut G8>G9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut G9>G10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | G1 line 1 (src 29) | PASS 100 | ossavar "Night in Adamarch. Everyone was counting.." 12.0 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | G2 line 1 (src 47) | PASS 96 | aldra "Two hundred. I counted them twice. Ten t.." 13.3 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | G3 line 1 (src 51) | PASS 97 | aldra "Every one carries the anchor. The Outwal.." 13.2 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | G4 line 1 (src 55) | PASS 100 | torvald "Two hundred dockers' wages, given as a g.." 11.6 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | G5 line 1 (src 58) | PASS 100 | aldra "Coin remembers where it was taken." 11.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | G6 line 1 (src 63) | PASS 100 | torvald "So does Malrik. He has simply never mind.." 11.9 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | G7 line 1 (src 70) | PASS 100 | ossavar "Tomorrow, ask the herald where the knive.." 10.4 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | G8 line 1 (src 75) | PASS 100 | aldra "You heard him." 7.8 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | G8 line 2 (src 76) | PASS 100 | torvald "I heard." 5.0 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | G9 line 1 (src 79) | PASS 100 | torvald "Tomorrow, then." 7.5 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 10 / 10 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 8208500de47d35f1 / 8208500de47d35f1 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 29aab04a687e45ff) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e7_ledger.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (ossavar in G1 (cine 230, runtime -130 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e7_ledger.cine` (85 lines), 70.0 s, 10 shots, stage: set forge_intro_malrik
- the .cine has 85 lines (demo budget <= 80)
